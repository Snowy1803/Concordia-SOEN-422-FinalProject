#include <WiFi.h>
#include <Firebase.h>

#define BUZZER 21
#define MOVEMENT_SENSOR 13

#define WIFI_SSID "[REDACTED] FILL ME IN"
#define WIFI_PASSWD "[REDACTED] FILL ME IN"

#define REFERENCE_URL "https://concordia-heater-default-rtdb.firebaseio.com/"
#define MY_PATH "H968/"

#define SERVER_TIMESTAMP "{\".sv\": \"timestamp\"}"

Firebase fb(REFERENCE_URL);

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
double currentTemp, setTemp;
/// If we should enabled the heater (device is enabled and current
//// temperature is less than target)
bool heating;
/// If a movement happened since the last server update
bool pushMovement;
/// The millis() of the last movement
/// Different to the lastMovement stored on firebase, as firebase
/// will have a timestamp of the last pushMovement (which can be up to
/// 15 seconds late), while this is based on the uptime
unsigned long lastMovement;
/// The millis() of the last server update
unsigned long lastUpdate;
/// The millis() of the current tick
unsigned long tick;

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

void setup() {
  pinMode(MOVEMENT_SENSOR, INPUT);
  Serial.begin(115200);

  WiFi.begin(WIFI_SSID, WIFI_PASSWD);
  Serial.print("Connecting");
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(WiFi.status());
  }
  Serial.println("");
  Serial.print("Connected to WiFi network with IP Address: ");
  Serial.println(WiFi.localIP());
}

/// Download settings (mode, setTemp) from firebase
void downloadServerSettings() {
  Mode newMode = static_cast<Mode>(fb.getInt(MY_PATH "mode"));
  if (mode != newMode) {
    mode = newMode;
    doBuzz = BUZZER_MODE;
  }
  setTemp = fb.getFloat(MY_PATH "setTemp");
  // WHILE WAITING FOR TEMP SENSOR:
  currentTemp = fb.getFloat(MY_PATH "currentTemp");
  buzzer = static_cast<BuzzerSetting>(fb.getInt(MY_PATH "buzzer"));
}

/// Update `lastMovement` if a movement is detected
void updateLastMovement() {
  // int value = analogRead(12);
  int value = digitalRead(MOVEMENT_SENSOR);
  Serial.println(value);
  if (value) { // > 1500
    pushMovement = true;
    lastMovement = tick;
  }
}

/// Update `currentTemp` from the sensor
void updateCurrentTemp() {
  // TODO: implement
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
  if (lastHeating != heating) {
    doBuzz = BUZZER_HEATING;
  }
  // TODO: set real heat
}

/// Print the current state, for debugging
void printState() {
  Serial.println(String("Tick: ") + tick);
  Serial.println(String("Mode: ") + mode);
  Serial.println(String("Temp: ") + currentTemp + "; target: " + setTemp);
  Serial.println(String("Heating: ") + heating);
  Serial.println(String("Movement: ") + lastMovement + (pushMovement ? " PUSH" : ""));
}

/// Upload the state of the device to firebase
void uploadState() {
  fb.setBool(MY_PATH "heating", heating);
  // TODO: fb.setFloat(MY_PATH "currentTemp", currentTemp);
  if (pushMovement)
    fb.setJson(MY_PATH "lastMovement", SERVER_TIMESTAMP);
  fb.setJson(MY_PATH "lastUpdate", SERVER_TIMESTAMP);
  lastUpdate = tick;
  pushMovement = false;
}

void loop() {
  /// The number of milliseconds since the start, of when the tick started.
  /// Nonzero. May overflow.
  tick = millis();
  if (tick == 0) tick = 1;
  bool serverUpdateNow = tick - lastUpdate > 15000;

  if (serverUpdateNow) {
    Serial.print("Server Update!");
    downloadServerSettings();
    Serial.println(" OK");
  }

  updateLastMovement();
  updateCurrentTemp();
  updateHeating();

  if (serverUpdateNow) {
    printState();
    uploadState();
  }

  if (doBuzz >= buzzer && doBuzz) {
    tone(BUZZER, 118, 90);
  }

  delay(100);

  if (doBuzz >= buzzer && doBuzz) {
    noTone(BUZZER);
    doBuzz = BUZZER_SILENT;
  }
}
