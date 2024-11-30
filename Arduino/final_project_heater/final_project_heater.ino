#include <WiFi.h>
#include <FirebaseClient.h>
#include <FirebaseJson.h>
#include "DHT.h"

#define HEATER_RELAY 12
#define TEMP_SENSOR 17
#define FLAME_SENSOR 35
#define FLAME_SENSOR_ANALOG A0
#define BUZZER 21
#define MOVEMENT_SENSOR 13

#define WIFI_SSID "[REDACTED] FILL ME IN"
#define WIFI_PASSWD "[REDACTED] FILL ME IN"

#define REFERENCE_URL "https://concordia-heater-default-rtdb.firebaseio.com/"
#define MY_PATH "H968/"

#define SERVER_TIMESTAMP "{\".sv\": \"timestamp\"}"

DefaultNetwork firebaseNetwork;
NoAuth firebaseAuth;
FirebaseApp firebaseApp;

WiFiClient fbBasicClient, fbBasicPushClient;
ESP_SSLClient fbSSLClient, fbSSLPushClient;
using AsyncClient = AsyncClientClass;
AsyncClient fbAClient(fbSSLClient, getNetwork(firebaseNetwork)), fbPushClient(fbSSLPushClient, getNetwork(firebaseNetwork));
RealtimeDatabase database;

DHT dht(TEMP_SENSOR, DHT11);

/// The mode of the device
enum Mode {
  /// The device is disabled
  MODE_DISABLED,
  /// The device is enabled when movement is detected
  MODE_ENABLED,
  /// The device is enabled unconditionally
  MODE_HEAT
} mode;
/// The current (from sensor) and target (from settings) temperature
double currentTemp = 0.0/0.0, setTemp;
/// If we should enabled the heater (device is enabled and current
//// temperature is less than target)
bool heating;
/// If a movement happened since the last server update
bool pushMovement;
/// If a fire was detected
bool fireDetected;
/// The millis() of the last movement
/// Different to the lastMovement stored on firebase, as firebase
/// will have a timestamp of the last pushMovement (which can be up to
/// 15 seconds late), while this is based on the uptime
unsigned long lastMovement;
/// The millis() of the last server update
unsigned long lastUpdate;
/// The millis() of the current tick
unsigned long tick;
/// The millis() of the next time to read the temperature
unsigned long nextTempRead;
/// The millis() of the last call to tone() in case of a fire
unsigned long lastAlarmBuzz;
/// The phase of the 3-tone alarm (0-1-2 buzzes, 3 for pause)
unsigned char alarmPhase;

/// The mode of the buzzer
enum BuzzerSetting {
  /// The buzzer is silent / disabled
  BUZZER_SILENT,
  /// The buzzer signals mode changes
  BUZZER_MODE,
  /// The buzzer signals mode changes, and when heating changes for any reason
  BUZZER_HEATING,
} buzzer;
/// The buzz to make at the current tick
BuzzerSetting doBuzz = BUZZER_SILENT;

void firebaseCallback(AsyncResult &aResult);

void setup() {
  pinMode(MOVEMENT_SENSOR, INPUT);
  pinMode(FLAME_SENSOR, INPUT);
  pinMode(HEATER_RELAY, OUTPUT);
  Serial.begin(115200);
  dht.begin();

  WiFi.begin(WIFI_SSID, WIFI_PASSWD);
  Serial.print("Connecting");
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(WiFi.status());
  }
  Serial.println("");
  Serial.print("Connected to WiFi network with IP Address: ");
  Serial.println(WiFi.localIP());
  nextTempRead = millis() + 5000;

  Serial.println("Connecting to Firebase app...");

  fbSSLClient.setClient(&fbBasicClient);
  fbSSLClient.setInsecure();
  fbSSLClient.setBufferSizes(2048, 1024);
  fbSSLClient.setDebugLevel(1);

  fbSSLPushClient.setClient(&fbBasicPushClient);
  fbSSLPushClient.setInsecure();
  fbSSLPushClient.setBufferSizes(2048, 1024);
  fbSSLPushClient.setDebugLevel(1);

  initializeApp(fbAClient, firebaseApp, getAuth(firebaseAuth), firebaseCallback, "init");
  firebaseApp.getApp<RealtimeDatabase>(database);
  database.url(REFERENCE_URL);
  database.get(fbAClient, MY_PATH, firebaseCallback, true, "stream");
}

void firebaseCallback(AsyncResult &result) {
  if (result.available()) {
    RealtimeDatabaseResult &RTDB = result.to<RealtimeDatabaseResult>();
    if (RTDB.isStream()) {
      if (RTDB.event() != "put" && RTDB.event() != "patch")
        return;
      Firebase.printf("Received event: %s / data: %s\n", RTDB.dataPath().c_str(), RTDB.to<const char *>());
      if (RTDB.dataPath() == "/mode") {
        mode = static_cast<Mode>(RTDB.to<int>());
        doBuzz = BUZZER_MODE;
      } else if (RTDB.dataPath() == "/setTemp") {
        setTemp = RTDB.to<double>();
      } else if (RTDB.dataPath() == "/buzzer") {
        buzzer = static_cast<BuzzerSetting>(RTDB.to<int>());
      } else if (RTDB.dataPath() == "/") {
        // full update, parse json
        FirebaseJson json;
        json.setJsonData(RTDB.to<const char *>());
        FirebaseJsonData jsonData;
        if (json.get(jsonData, "mode")) {
          mode = static_cast<Mode>(jsonData.intValue);
          doBuzz = BUZZER_MODE;
        }
        if (json.get(jsonData, "setTemp")) {
          setTemp = jsonData.doubleValue;
        }
        if (json.get(jsonData, "buzzer")) {
          buzzer = static_cast<BuzzerSetting>(jsonData.intValue);
        }
      }
    }
  }

}

/// Update `lastMovement` if a movement is detected
void updateLastMovement() {
  int value = digitalRead(MOVEMENT_SENSOR);
//  Serial.println(value);
  if (value) {
    pushMovement = true;
    lastMovement = tick;
  }
}

/// Update `fireDetected` if a flame is detected
void updateFireDetected() {
  // int value = digitalRead(FLAME_SENSOR);
  int value = analogRead(FLAME_SENSOR_ANALOG);
  // Serial.println(String("fire detected = ") + value);
  fireDetected = value > 800;
}

/// Update `currentTemp` from the sensor
/// Will only read every 2 seconds.
void updateCurrentTemp() {
  if (nextTempRead >= tick)
    return;
  float h = dht.readHumidity();
  float temp = dht.readTemperature();
  if (isnan(temp)) {
    Serial.println("Failed to read from DHT sensor!");
    return;
  }
  currentTemp = temp;
  nextTempRead = tick + 2000;
}

void updateHeating() {
  bool lastHeating = heating;
  switch (mode) {
  case MODE_DISABLED:
    heating = false;
    break;
  case MODE_HEAT:
    heating = true;
    break;
  case MODE_ENABLED:
    heating = lastMovement && tick - lastMovement < 30000;
    break;
  }
  if (heating && currentTemp >= setTemp) {
    heating = false;
  }
  if (fireDetected) {
    heating = false;
  }
  if (lastHeating != heating) {
    doBuzz = BUZZER_HEATING;
    digitalWrite(HEATER_RELAY, heating);
  }
}

/// Print the current state, for debugging
void printState() {
  Serial.println(String("Tick: ") + tick);
  Serial.println(String("Mode: ") + mode);
  Serial.println(String("Temp: ") + currentTemp + "; target: " + setTemp);
  Serial.println(String("Heating: ") + heating);
  Serial.println(String("Movement: ") + lastMovement + (pushMovement ? " PUSH" : ""));
  Serial.println(String("Buzzer: ") + buzzer);
  Serial.println(String("Fire: ") + fireDetected);
}

/// Upload the state of the device to firebase
void uploadState() {
  FirebaseJson json;
  json.set("heating", heating);
  if (!isnan(currentTemp))
    json.set("currentTemp", currentTemp);
  if (pushMovement)
    json.set("lastMovement/.sv", "timestamp");
  json.set("lastUpdate/.sv", "timestamp");
  json.set("fire", fireDetected);
  String jsonStr;
  json.toString(jsonStr);
  database.update(fbPushClient, MY_PATH, object_t(jsonStr), firebaseCallback, "update");
  lastUpdate = tick;
  pushMovement = false;
}

void loop() {
  firebaseApp.loop();
  database.loop();
  /// The number of milliseconds since the start, of when the tick started.
  /// Nonzero. May overflow.
  unsigned long currentTime = millis();
  bool tickNow = currentTime - tick >= 500;
  if (!tickNow)
    return;
  tick = currentTime;
  if (tick == 0) tick = 1;
  bool serverUpdateNow = tick - lastUpdate > 15000;

  if (fireDetected) {
    // T3: 4x1s cycle, 0.5s buzz 3 times, then a pause
    if (tick - lastAlarmBuzz >= 1000) {
      if (alarmPhase < 3) {
        tone(BUZZER, 520, 500);
        alarmPhase++;
      } else {
        alarmPhase = 0;
      }
      lastAlarmBuzz = tick;
    }
  }

  updateLastMovement();
  updateFireDetected();
  updateCurrentTemp();
  updateHeating();

  if (serverUpdateNow) {
    printState();
    Serial.print("Server Update!");
    uploadState();
    Serial.println(" OK");
  }

  if (!fireDetected && doBuzz >= buzzer && buzzer) {
    tone(BUZZER, 118, 90);
    doBuzz = BUZZER_SILENT;
  }
}
