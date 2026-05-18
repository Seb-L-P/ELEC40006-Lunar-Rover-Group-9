/*
 * EEELunarRover firmware
 * Target: Adafruit Metro M0 Express + WINC1500 WiFi shield
 *
 * Implements the HTTP API contract from ../../CONTROLLER_PLAN.md:
 *   GET /info                  -> { t, group, ip, fw_version }
 *   GET /status                -> { t, drive, sensors, battery_mv, state }
 *   GET /drive?l=<int>&r=<int> -> set motor PWMs in [-255, 255]; refreshes watchdog
 *   GET /stop                  -> immediately zero both motors
 *   GET /scan                  -> blocking measurement cycle (~600 ms), returns snapshot
 *
 * Robustness:
 *   - 500 ms drive watchdog auto-stops the motors if /drive heartbeats stop.
 *   - WiFi connection is bounded (it never hangs forever) and is re-attempted
 *     from loop() if it drops. Motors are stopped whenever WiFi is down.
 *   - JSON responses serialise into a fixed stack buffer, so there is no
 *     per-request heap allocation to fragment memory over a long demo.
 *   - The onboard LED reports status when no serial cable is attached:
 *       fast blink = WiFi down,  solid = driving,  off = idle.
 *
 * Sensor stubs (readAge / readIR / readUltrasound / readMagnet) currently
 * return plausible fake data so the UI can be tested end-to-end. Each sensor
 * subsystem owner replaces the body of their function with real hardware logic.
 *
 * IMPORTANT: pins 5, 7, 10 are reserved by the WiFi shield. Do NOT use them
 * for any other purpose.
 */

#define USE_WIFI_NINA  false
#define USE_WIFI101    true
#include <WiFiWebServer.h>
#include <ArduinoJson.h>

// ===================== Configuration =====================

const char ssid[]      = "EEERover";
const char pass[]      = "exhibition";
const int  groupNumber = 0;        // CHANGE ME: sets static IP to 192.168.0.<groupNumber+1>
const char fwVersion[] = "0.2.0";

// Motor driver pins, set to match the dual H-bridge wiring.
// Each motor has a direction line and an enable line; the enable line
// takes the PWM signal for speed control.
// Pins 5, 7, 10 are reserved by the WiFi shield.
const int LEFT_DIR_PIN   = 12;   // left motor direction
const int LEFT_PWM_PIN   = 6;    // left motor enable (PWM)
const int RIGHT_DIR_PIN  = 4;    // right motor direction
const int RIGHT_PWM_PIN  = 9;    // right motor enable (PWM)
const int DEBUG_LED_PIN  = LED_BUILTIN;

// Drive watchdog: if no /drive heartbeat for this long, motors auto-stop.
const unsigned long DRIVE_WATCHDOG_MS = 500;

// Approximate length of a scan cycle. Real IR pulse counting will want
// at least a few hundred ms to integrate enough events to discriminate
// the two Poisson rates (312 vs 547 s^-1).
const unsigned long SCAN_DURATION_MS = 600;

// How often loop() checks the WiFi link is still up.
const unsigned long WIFI_CHECK_MS = 3000;

// ===================== State =====================

enum RoverState { ST_IDLE, ST_DRIVING, ST_SCANNING, ST_ERROR };

int  driveLeft  = 0;
int  driveRight = 0;
unsigned long lastDriveMs = 0;
bool scanRunning = false;
bool wifiUp = false;

WiFiWebServer server(80);

// ===================== Motor control =====================

static void applyMotor(int pwmPin, int dirPin, int command)
{
  command = constrain(command, -255, 255);
  if (command >= 0) {
    digitalWrite(dirPin, HIGH);
    analogWrite(pwmPin, command);
  } else {
    digitalWrite(dirPin, LOW);
    analogWrite(pwmPin, -command);
  }
}

static void applyDrive()
{
  applyMotor(LEFT_PWM_PIN,  LEFT_DIR_PIN,  driveLeft);
  applyMotor(RIGHT_PWM_PIN, RIGHT_DIR_PIN, driveRight);
}

static void stopMotors()
{
  driveLeft = 0;
  driveRight = 0;
  applyDrive();
}

static RoverState currentRoverState()
{
  if (!wifiUp)     return ST_ERROR;
  if (scanRunning) return ST_SCANNING;
  if (driveLeft != 0 || driveRight != 0) return ST_DRIVING;
  return ST_IDLE;
}

static const char* stateName(RoverState s)
{
  switch (s) {
    case ST_IDLE:     return "idle";
    case ST_DRIVING:  return "driving";
    case ST_SCANNING: return "scanning";
    case ST_ERROR:    return "error";
  }
  return "unknown";
}

// ===================== Status LED =====================
//
// The onboard LED is the only feedback available when the board runs without
// a USB cable attached:
//   fast blink = WiFi down,  solid = driving,  off = idle and connected.

static void updateLed()
{
  bool on;
  if (!wifiUp) {
    on = (millis() / 150) % 2;            // fast blink while disconnected
  } else {
    on = (driveLeft != 0 || driveRight != 0);
  }
  digitalWrite(DEBUG_LED_PIN, on ? HIGH : LOW);
}

// ===================== Sensor stubs (to be replaced) =====================
//
// Each sensor subsystem owner replaces the body of their function with the
// real hardware read. Keep the return shape the same so the JSON contract
// does not change.
//
// While stubs are in place, /status returns the placeholder values defined
// here. This lets the UI lead develop and test their side end-to-end before
// any analogue hardware is built.

struct AgeResult { String value; bool valid; };
static AgeResult readAge() {
  // TODO (radio owner): return the most recently decoded 4-char age string
  // from the UART buffer. Set valid=false until a complete "#NNN" arrives.
  return { String("#317"), true };
}

struct IRResult { int rateHz; bool valid; };
static IRResult readIR() {
  // TODO (IR owner): return pulses per second over the latest measurement
  // window. The rates to distinguish are ~312 and ~547 s^-1.
  return { 547, true };
}

struct UltrasoundResult { bool present; bool valid; };
static UltrasoundResult readUltrasound() {
  // TODO (ultrasound owner): return true if the 40 kHz tone is detected
  // above the threshold; false otherwise.
  return { true, true };
}

struct MagnetResult { const char* direction; bool valid; };
static MagnetResult readMagnet() {
  // TODO (magnet owner): return "up" or "down" depending on the polarity
  // of the static magnetic field at the sensor.
  return { "up", true };
}

static int readBatteryMv() {
  // TODO: read battery voltage via a divider on an analogue pin.
  // Leave constant for now so the UI battery indicator is at least defined.
  return 7200;
}

// ===================== HTTP helpers =====================

static void sendJson(int code, JsonDocument& doc)
{
  // Serialise into a fixed stack buffer. This avoids allocating a String on
  // the heap for every request, which would fragment memory over a long run.
  // 512 bytes comfortably holds the largest response (/status, ~250 bytes).
  char buf[512];
  serializeJson(doc, buf, sizeof(buf));
  // CORS: allow the UI to be served from a different origin (e.g. laptop).
  server.sendHeader(F("Access-Control-Allow-Origin"), F("*"));
  server.sendHeader(F("Cache-Control"),               F("no-store"));
  server.send(code, F("application/json"), buf);
}

// ===================== Route handlers =====================

static void handleInfo()
{
  StaticJsonDocument<256> doc;
  doc[F("t")]     = millis();
  doc[F("group")] = groupNumber;

  // WiFi101's localIP() returns a raw uint32_t and this core's IPAddress
  // has no toString(), so format the dotted-quad manually.
  IPAddress ip(WiFi.localIP());
  char ipbuf[16];
  snprintf(ipbuf, sizeof(ipbuf), "%d.%d.%d.%d", ip[0], ip[1], ip[2], ip[3]);
  doc[F("ip")] = ipbuf;

  doc[F("fw_version")] = fwVersion;
  sendJson(200, doc);
}

static void handleStatus()
{
  StaticJsonDocument<512> doc;
  doc[F("t")] = millis();

  JsonObject drive = doc.createNestedObject(F("drive"));
  drive[F("left")]  = driveLeft;
  drive[F("right")] = driveRight;

  JsonObject sensors = doc.createNestedObject(F("sensors"));

  AgeResult age = readAge();
  if (age.valid) sensors[F("age")] = age.value;
  else           sensors[F("age")] = nullptr;
  sensors[F("age_valid")] = age.valid;

  IRResult ir = readIR();
  sensors[F("ir_rate_hz")] = ir.rateHz;
  sensors[F("ir_valid")]   = ir.valid;

  UltrasoundResult us = readUltrasound();
  sensors[F("ultrasound_present")] = us.present;
  sensors[F("ultrasound_valid")]   = us.valid;

  MagnetResult m = readMagnet();
  sensors[F("magnet")]       = m.direction;
  sensors[F("magnet_valid")] = m.valid;

  doc[F("battery_mv")] = readBatteryMv();
  doc[F("state")]      = stateName(currentRoverState());

  sendJson(200, doc);
}

static void handleDrive()
{
  if (!server.hasArg(F("l")) || !server.hasArg(F("r"))) {
    StaticJsonDocument<96> err;
    err[F("error")] = F("missing l or r");
    sendJson(400, err);
    return;
  }
  int l = server.arg(F("l")).toInt();
  int r = server.arg(F("r")).toInt();
  driveLeft   = constrain(l, -255, 255);
  driveRight  = constrain(r, -255, 255);
  lastDriveMs = millis();
  applyDrive();

  StaticJsonDocument<128> doc;
  doc[F("t")] = millis();
  JsonObject d = doc.createNestedObject(F("drive"));
  d[F("left")]  = driveLeft;
  d[F("right")] = driveRight;
  sendJson(200, doc);
}

static void handleStop()
{
  stopMotors();
  StaticJsonDocument<96> doc;
  doc[F("t")]       = millis();
  doc[F("stopped")] = true;
  sendJson(200, doc);
}

static void handleScan()
{
  // While scanning, motors should be stopped so the antenna and sensors
  // aren't shaken about.
  stopMotors();

  scanRunning = true;

  // Blocking measurement window. The HTTP server does not service other
  // requests during this ~600 ms. That is acceptable here: the operator
  // scans one rock at a time and the UI shows a "Scanning" state meanwhile.
  // A more advanced version could count IR pulses across this window.
  delay(SCAN_DURATION_MS);

  AgeResult        age = readAge();
  IRResult         ir  = readIR();
  UltrasoundResult us  = readUltrasound();
  MagnetResult     m   = readMagnet();

  scanRunning = false;

  StaticJsonDocument<384> doc;
  doc[F("t")] = millis();
  if (age.valid) doc[F("age")] = age.value;
  else           doc[F("age")] = nullptr;
  doc[F("ir_rate_hz")]         = ir.rateHz;
  doc[F("ultrasound_present")] = us.present;
  doc[F("magnet")]             = m.direction;
  doc[F("classification")]     = nullptr;  // classification is done in the UI
  sendJson(200, doc);
}

static void handleNotFound()
{
  StaticJsonDocument<192> doc;
  doc[F("error")] = F("not found");
  doc[F("uri")]   = server.uri();
  sendJson(404, doc);
}

// ===================== WiFi =====================

// Attempt to join the network, up to maxAttempts tries. Returns true on
// success. Bounded so the rover never hangs forever on a bad connection.
static bool connectWiFi(uint8_t maxAttempts)
{
  for (uint8_t i = 0; i < maxAttempts; i++) {
    if (WiFi.begin(ssid, pass) == WL_CONNECTED) return true;
    Serial.print('.');
    delay(500);
  }
  return false;
}

// ===================== Setup / loop =====================

void setup()
{
  pinMode(DEBUG_LED_PIN,  OUTPUT);
  pinMode(LEFT_DIR_PIN,   OUTPUT);
  pinMode(LEFT_PWM_PIN,   OUTPUT);
  pinMode(RIGHT_DIR_PIN,  OUTPUT);
  pinMode(RIGHT_PWM_PIN,  OUTPUT);
  digitalWrite(DEBUG_LED_PIN, LOW);
  stopMotors();

  Serial.begin(9600);
  // Wait up to 5 s for USB serial so startup messages are visible if attached.
  while (!Serial && millis() < 5000) {}
  Serial.println(F("\nEEELunarRover firmware starting"));

  if (WiFi.status() == WL_NO_SHIELD) {
    Serial.println(F("WiFi shield not present - halting"));
    while (true) {                         // blink fast so the halt is visible
      digitalWrite(DEBUG_LED_PIN, (millis() / 100) % 2);
    }
  }

  if (groupNumber) {
    WiFi.config(IPAddress(192, 168, 0, groupNumber + 1));
  }

  Serial.print(F("Connecting to "));
  Serial.print(ssid);
  wifiUp = connectWiFi(20);
  Serial.println();
  if (wifiUp) {
    Serial.print(F("IP: "));
    Serial.println(static_cast<IPAddress>(WiFi.localIP()));
  } else {
    Serial.println(F("WiFi not connected - will keep retrying in loop()"));
  }

  server.on(F("/info"),   handleInfo);
  server.on(F("/status"), handleStatus);
  server.on(F("/drive"),  handleDrive);
  server.on(F("/stop"),   handleStop);
  server.on(F("/scan"),   handleScan);
  server.onNotFound(handleNotFound);

  server.begin();
  Serial.println(F("HTTP server running"));
}

void loop()
{
  // --- WiFi health: re-attempt if dropped; never drive while uncontrolled ---
  static unsigned long lastWifiCheck = 0;
  if (millis() - lastWifiCheck > WIFI_CHECK_MS) {
    lastWifiCheck = millis();
    if (WiFi.status() != WL_CONNECTED) {
      if (wifiUp) Serial.println(F("WiFi lost - stopping motors, reconnecting"));
      wifiUp = false;
      stopMotors();
      if (connectWiFi(4)) {
        wifiUp = true;
        server.begin();   // best-effort: re-listen after the link returns
        Serial.println(F("WiFi reconnected"));
      }
    } else {
      wifiUp = true;
    }
  }

  server.handleClient();

  // --- 500 ms drive watchdog ---
  if ((driveLeft != 0 || driveRight != 0)
      && (millis() - lastDriveMs > DRIVE_WATCHDOG_MS)) {
    stopMotors();
  }

  updateLed();
}
