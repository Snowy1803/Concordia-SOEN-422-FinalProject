#include <WiFi.h>
#include <Firebase.h>

#define BUZZER 21

#define WIFI_SSID "[REDACTED] FILL ME IN"
#define WIFI_PASSWD "[REDACTED] FILL ME IN"

#define REFERENCE_URL "https://concordia-heater-default-rtdb.firebaseio.com/"
#define MY_PATH "H968/"

Firebase fb(REFERENCE_URL);


enum Mode {
  MODE_DISABLED, MODE_ENABLED, MODE_HEAT
} mode;
double currentTemp, setTemp;
bool heating;
bool pushMovement; // a movement happened without updating firestore
unsigned long lastMovement; // millis() since start, ≠ what's on firestore
unsigned long lastUpdate;

void setup() {
  pinMode(13, INPUT);
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

void loop() {
  unsigned long tick = millis();
  if (tick == 0) tick = 1;
  bool serverUpdateNow = tick - lastUpdate > 15000;
  // update setTemp and mode
  if (serverUpdateNow) {
    Serial.print("Server Update!");
    mode = static_cast<Mode>(fb.getInt(MY_PATH "mode"));
    setTemp = fb.getFloat(MY_PATH "setTemp");
    // WHILE WAITING FOR TEMP SENSOR:
    currentTemp = fb.getFloat(MY_PATH "currentTemp");
    Serial.println(" OK");
  }

  // compute lastMovement
  // int value = analogRead(12);
  int value = digitalRead(13);
  Serial.println(value);
  if (value) { // > 1500
    pushMovement = true;
    lastMovement = tick;
  }

  // TODO compute currentTemp

  // compute heating
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
  // TODO do heat

  // send info
  if (serverUpdateNow) {
    // print (debug)
    Serial.println(String("Tick: ") + tick);
    Serial.println(String("Mode: ") + mode);
    Serial.println(String("Temp: ") + currentTemp + "; target: " + setTemp);
    Serial.println(String("Heating: ") + heating);
    Serial.println(String("Movement: ") + lastMovement + (pushMovement ? " PUSH" : ""));

    fb.setBool(MY_PATH "heating", heating);
    // TODO send currentTemp
    if (pushMovement)
      fb.setJson(MY_PATH "lastMovement", "{\".sv\": \"timestamp\"}");
    fb.setJson(MY_PATH "lastUpdate", "{\".sv\": \"timestamp\"}");
    lastUpdate = tick;
    pushMovement = false;
  }

  delay(100);
}
