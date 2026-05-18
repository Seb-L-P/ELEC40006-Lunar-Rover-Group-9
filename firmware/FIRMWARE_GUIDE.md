# Firmware Walkthrough

For the embedded lead. This document walks through `src/main.cpp` section by section so you can read, modify, and defend the firmware at the interim interview and demo.

The demo examiner will ask you questions like "why a 500 ms watchdog?", "why JSON?", "what happens if the WiFi drops mid-drive?". You'll be expected to answer those without notes. This guide is so you can.

---

## 1. What the firmware does, in one paragraph

It connects the Metro M0 to the lab WiFi at a fixed IP, runs a small HTTP server on port 80, and answers five endpoints. Two of them are state-changing (`/drive`, `/stop`) and write to motor PWM pins via the H-bridge module. Three are read-only (`/info`, `/status`, `/scan`) and return JSON describing the rover's current state or a snapshot of sensor readings. A watchdog in `loop()` zeros the motors if no drive heartbeat arrives within 500 ms, so the rover stops when WiFi drops or the operator releases a key.

---

## 2. Walk through `src/main.cpp`

The file is organised as labelled sections separated by `// =====...` banners. Read top-to-bottom.

### 2.1 Includes and macros

```cpp
#define USE_WIFI_NINA  false
#define USE_WIFI101    true
#include <WiFiWebServer.h>
#include <ArduinoJson.h>
```

The two `#define`s tell `WiFiWebServer.h` which underlying WiFi driver to compile against. The Metro M0 uses the WINC1500 shield, which is driven by the `WiFi101` library, so we set `USE_WIFI101 = true`.

`ArduinoJson` is used to build the JSON responses. We use v6.x (see `platformio.ini`), which uses `StaticJsonDocument<N>` where `N` is the buffer capacity in bytes.

### 2.2 Configuration block

```cpp
const char ssid[]      = "EEERover";
const char pass[]      = "exhibition";
const int  groupNumber = 0;
```

Set `groupNumber` to your team number. `WiFi.config(IPAddress(192,168,0,groupNumber+1))` in `setup()` reserves that static IP on the lab WiFi.

```cpp
const int LEFT_DIR_PIN = 4;
const int LEFT_PWM_PIN = 3;
...
```

These are the digital pins wired to the H-bridge module. Verify them against your actual wiring **before flashing with motors connected**. Pins 5, 7, and 10 must not be reused because the WiFi shield uses them for CS, IRQ, and RST respectively.

```cpp
const unsigned long DRIVE_WATCHDOG_MS = 500;
```

The watchdog window. The UI re-sends `/drive` every 150 ms while a direction key is held, so 500 ms gives roughly 3x headroom for jitter.

### 2.3 Motor control helpers

```cpp
static void applyMotor(int pwmPin, int dirPin, int command);
```

Takes a signed integer in `[-255, 255]`. Sets `dirPin` HIGH for forward, LOW for reverse, and writes the absolute value to `pwmPin` via `analogWrite()`. This matches the H-bridge module's logic: DIR picks direction, PWM picks magnitude.

```cpp
static void applyDrive();
```

Applies the current `driveLeft` and `driveRight` to both motors. Also drives the onboard LED so you can sanity-check that drive commands arrived without needing a multimeter.

```cpp
static void stopMotors();
```

Convenience: zero both motors and call `applyDrive()`.

### 2.4 State machine

```cpp
enum RoverState { ST_IDLE, ST_DRIVING, ST_SCANNING, ST_ERROR };
```

The state machine lives in the firmware (see section 4.2 of `../CONTROLLER_PLAN.md`). The UI just renders whatever string we publish. The current state is *derived* on every `/status` call from three facts:

- Is a scan currently in progress? Then `scanning`.
- Are either motor PWMs non-zero? Then `driving`.
- Otherwise: `idle`.

This means we don't need to track transitions explicitly. Less state to keep consistent equals fewer bugs.

`ST_ERROR` is reported whenever the WiFi link is down (`wifiUp == false`). In practice the UI cannot fetch `/status` while WiFi is down, so this state is mostly observed in the brief window if the link recovers between a drop and the next poll.

### 2.5 Sensor stubs

```cpp
static AgeResult readAge() {
  return { String("#317"), true };
}
```

Each `readX()` returns a small struct that includes both a value and a `valid` flag. The valid flag lets the UI grey out stale or never-acquired readings instead of showing rubbish.

**These are stubs.** Each subsystem owner replaces the body of their function with real hardware logic when their analogue front-end is ready. The function signatures must not change, or the JSON shape breaks and the UI breaks with it.

### 2.6 JSON helpers

```cpp
static void sendJson(int code, JsonDocument& doc);
```

Serialises the document into a **fixed 512-byte stack buffer**, adds CORS and cache-control headers, and sends the response. Used by every route handler.

It deliberately does not build a heap `String`. A new `String` allocation on every request, several times a second for hours, would fragment the small (32 KB) heap. A fixed stack buffer has no such cost and is freed automatically when the function returns. 512 bytes comfortably holds the largest response (`/status`, around 250 bytes).

The CORS header (`Access-Control-Allow-Origin: *`) is what lets the UI hosted on the operator's laptop talk to the rover's IP. Without it the browser would refuse to read responses from a different origin.

### 2.7 Route handlers

Each handler is named `handleX` and registered in `setup()` with `server.on("/x", handleX)`. They follow the same pattern:

1. Parse query args if any.
2. Read state or sensor data.
3. Build a `StaticJsonDocument`.
4. Call `sendJson(200, doc)`.

`handleDrive` is the one that mutates state: it updates `driveLeft`, `driveRight`, `lastDriveMs`, and calls `applyDrive()`.

`handleScan` is special because it blocks for ~600 ms. During that time we still need the HTTP server to be responsive to keep the connection alive, so the wait loop calls `delay(10)` in increments rather than `delay(600)` in one go. We also call `stopMotors()` at the start because shaking the rover during a measurement makes the readings worse.

### 2.8 Status LED and WiFi helper

`updateLed()` drives the onboard LED as the only diagnostic when no USB cable is attached: **fast blink** when WiFi is down, **solid** while driving, **off** when idle and connected. It is called once per `loop()`.

`connectWiFi(maxAttempts)` tries to join the network up to `maxAttempts` times, returning `true` on success. It is **bounded** on purpose. The starter sketch loops on `WiFi.begin()` forever, so a wrong password or an absent network hangs the board silently with no clue why. Bounding it means `setup()` can move on and `loop()` can keep retrying.

### 2.9 `setup()`

Standard Arduino flow:

1. Configure pin modes.
2. Open the serial port at 9600 baud (with a 5 s timeout in case there's no USB attached).
3. Check the WiFi shield is present; if absent, halt while blinking the LED fast so the failure is visible.
4. Set the static IP if `groupNumber` is non-zero.
5. Call `connectWiFi(20)` - up to twenty attempts, then continue regardless.
6. Register all the route handlers.
7. Start the server.

If WiFi fails here, the board still starts the server and `loop()` keeps retrying. It never hangs.

### 2.10 `loop()`

Three pieces of work:

1. **WiFi health check** (every 3 s). If the link has dropped, stop the motors immediately (the rover must not move while it cannot be controlled), then attempt a few quick reconnects. On success, re-`begin()` the server so it listens again.
2. **`server.handleClient()`** services any pending HTTP request.
3. **The watchdog check**. If motors are commanded non-zero and the last `/drive` was more than 500 ms ago, stop the motors. Combined with the WiFi check, this is the rover's safety story: a dropped connection stops it within at most 500 ms via the watchdog, and the health check stops it again and keeps it stopped until control is restored.

Then `updateLed()` refreshes the status LED.

---

## 3. Likely demo questions and how to answer them

**Why 500 ms for the watchdog?**
The UI re-sends `/drive` every 150 ms while a direction key is held. 500 ms gives roughly 3x margin for network jitter and lost packets. Smaller would risk false stops, larger would let the rover keep running too long after a real fault.

**Why is the state machine on the firmware, not the UI?**
Because every event that triggers a state transition is something only the firmware can observe directly: a drive command arrived, the watchdog fired, a scan finished. If the UI tracked state independently, a page refresh would lose it.

**Why classification on the UI, not the firmware?**
Classification rules might change. Putting them in JS means we can edit them without re-flashing the Metro. Firmware just publishes raw sensor readings.

**Why JSON for `/status`?**
Self-describing, trivially parsed in JavaScript, easy to debug with `curl`. The overhead vs. a delimited string is acceptable on a `WiFi101` link.

**What happens if WiFi drops while I'm holding W?**
Two layers catch it. First, the next `/drive` heartbeat fails to reach the rover, so 500 ms later the drive watchdog fires and `stopMotors()` runs. Second, within 3 s the WiFi health check in `loop()` notices the link is down, stops the motors again, and starts re-attempting the connection. The rover stays stopped until the link is back and the UI resumes heartbeats.

**Why serialise JSON into a buffer instead of a String?**
A `String` allocates on the heap. Building one per response, several times a second, fragments the 32 KB heap over a long demo and can eventually cause allocation failures. A fixed stack buffer has no allocation cost and is reclaimed when the function returns.

**Why bound the WiFi connection attempts?**
The starter sketch loops on `WiFi.begin()` forever. If the password is wrong or the network is down, the board hangs in `setup()` with no indication. Bounding the attempts lets the board start anyway, blink the LED to show WiFi is down, and keep retrying from `loop()`.

**Why is `/scan` blocking?**
Single-threaded server. The simpler architecture is worth the brief blocking. The UI handles it by disabling the Scan button and showing "Scanning..." during the call. We could make it async by starting a measurement in `/scan`, returning an ID, and polling `/scan/<id>` for completion, but that's overkill for one rock-at-a-time operation.

**How would you add another sensor?**
Add a `readX()` stub in the sensor section, add the corresponding field to the JSON shape in `handleStatus()` and `handleScan()`, update the API contract in `CONTROLLER_PLAN.md`, and tell the UI lead. Then implement the analogue front-end and replace the stub body.

**What if the H-bridge module needs more than 3.3 V on its inputs?**
Most H-bridge logic-level inputs accept 3.3 V as a valid HIGH because they have CMOS inputs with thresholds around 1.5 V. Check the module datasheet. If not, use a level shifter or a transistor-based interface.

**What's the worst case current draw on the digital outputs?**
The H-bridge inputs are high-impedance, so almost zero. The motors themselves are driven from the EEEBug battery rail through the H-bridge, not through the Metro pins.

---

## 4. Tasks to do before the interim

In rough order:

1. **Read the code end-to-end.** Open `src/main.cpp`, follow the section banners. If anything is unclear, ask before flashing.
2. **Pick correct motor pins** for your physical wiring. Update the constants in `src/main.cpp`. Verify with a multimeter that the WiFi shield's pins (5, 7, 10) aren't being reused.
3. **First flash, no motors.** Power the Metro via USB only, flash, watch the serial monitor for the IP address. Run `curl http://<ip>/info` from a laptop on the same WiFi and confirm you get JSON back.
4. **Smoke-test driving.** With motors still disconnected, call `curl "http://<ip>/drive?l=128&r=128"` and verify the onboard LED comes on. Wait 500 ms and verify it goes off (watchdog). Call `curl http://<ip>/stop` and verify it goes off immediately.
5. **Wire one motor.** Hook just the left motor up to the H-bridge channel for `LEFT_*_PIN`. Power the EEEBug battery rail. Run a drive command and observe the wheel turning at the commanded direction and speed. Repeat for the right motor.
6. **Open the UI** at `http://localhost:8080/?api=http://<ip>` and verify the drive D-pad now spins your wheels.
7. **Hand the file to each sensor owner.** Show them their `readX()` function. They replace the body, you re-flash. The UI lights up sensor by sensor as they come online.

---

## 5. Files you own as the embedded lead

- `firmware/src/main.cpp` - all the firmware
- `firmware/platformio.ini` - build config and library deps
- `firmware/README.md` - build/flash instructions
- `firmware/FIRMWARE_GUIDE.md` - this file

The UI side (`../ui/`) and the project-level docs (`../CONTROLLER_PLAN.md`, `../PROJECT_SUMMARY.md`) belong to the UI lead. If you propose changes to the HTTP contract, take it up with them - both files have to move in lockstep.
