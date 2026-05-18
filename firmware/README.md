# EEELunarRover Firmware

Metro M0 Express + WINC1500 WiFi shield. Implements the HTTP API contract in `../CONTROLLER_PLAN.md`, drives the H-bridge motor module, and exposes stubs that each sensor subsystem owner replaces with real hardware code.

## Build and flash

Two routes, both target the same `src/main.cpp`.

### PlatformIO (recommended)

1. Install [VS Code](https://code.visualstudio.com/) and the [PlatformIO extension](https://platformio.org/install/ide?install=vscode).
2. Open this `firmware/` folder.
3. Plug the Metro M0 into the laptop via USB.
4. Click the **Build** (✓) and then **Upload** (→) buttons in the bottom toolbar, or run from the integrated terminal:

   ```bash
   pio run                 # build
   pio run -t upload       # flash
   pio device monitor      # serial monitor at 9600 baud
   ```

PlatformIO will download the SAMD platform, ArduinoJson, and WiFiWebServer on the first build.

### Arduino IDE

Copy the contents of `src/main.cpp` into a sketch called `EEELunarRover.ino` and install:

- Board support: follow [Adafruit's Metro M0 setup guide](https://learn.adafruit.com/adafruit-metro-m0-express/arduino-ide-setup).
- Libraries (via Library Manager): **WiFiWebServer** (Khoi Hoang) and **ArduinoJson** (Benoit Blanchon, v6.x).

## What to change before first flash

Open `src/main.cpp` and review the **Configuration** block near the top:

| Constant | Default | Set to |
| --- | --- | --- |
| `ssid` / `pass` | `EEERover` / `exhibition` | Lab WiFi credentials. Override if testing on a hotspot. |
| `groupNumber` | `0` | Your group number. This sets a static IP of `192.168.0.<groupNumber+1>` on the lab network. |
| `LEFT_DIR_PIN`, `LEFT_PWM_PIN`, `RIGHT_DIR_PIN`, `RIGHT_PWM_PIN` | `4`, `3`, `12`, `11` | Whichever pins you wired to the H-bridge module. **Avoid 5, 7, 10** (reserved by the WiFi shield). |
| `DRIVE_WATCHDOG_MS` | `500` | Time without a `/drive` heartbeat before motors auto-stop. Don't reduce below the UI heartbeat interval (150 ms) plus margin. |
| `SCAN_DURATION_MS` | `600` | Window over which `/scan` integrates measurements. Increase to count more IR pulses for better Poisson rate discrimination. |

## Verifying it works

After flashing, open the serial monitor at 9600 baud. You should see:

```text
EEELunarRover firmware starting
Connecting to EEERover
.....
IP: 192.168.0.<your_ip>
HTTP server running
```

Then on a laptop or phone on the **same WiFi network**:

```bash
# Replace the IP with whatever the serial monitor reported
curl http://192.168.0.1/info
curl http://192.168.0.1/status
curl "http://192.168.0.1/drive?l=128&r=-64"
curl http://192.168.0.1/stop
curl http://192.168.0.1/scan
```

Each should return a JSON document. The onboard LED reports status: **fast blink** while WiFi is down, **solid** when `/drive` is driving the motors, **off** when idle and connected. So even with no serial cable attached, a fast-blinking LED means "not on WiFi" and a solid LED means "receiving drive commands".

To connect the operator UI, open it with the rover's IP in the API query string:

```
http://localhost:8080/?api=http://192.168.0.<groupNumber+1>
```

(The mock server at `../ui/mock_server.py` is no longer needed once real firmware is running, but you can still serve the UI files with it if you prefer.)

## Plugging in real sensors

Inside `src/main.cpp`, find the section labelled **Sensor stubs (to be replaced)**. Each function returns fake but plausible data so the UI runs end-to-end before any analogue hardware exists.

When a sensor subsystem is ready, replace the body of the corresponding function while keeping its return shape identical:

| Function | Owner | Returns |
| --- | --- | --- |
| `readAge()` | Radio subsystem | `{ "#NNN", valid }` |
| `readIR()` | IR subsystem | `{ pulses-per-second, valid }` |
| `readUltrasound()` | Ultrasound subsystem | `{ present (bool), valid }` |
| `readMagnet()` | Magnet subsystem | `{ "up" \| "down", valid }` |
| `readBatteryMv()` | Anyone | int millivolts |

Each sensor owner should be able to develop their function in isolation, hand it over, and have it Just Work without touching the routing or JSON code.

## Architecture notes

- **Why a 500 ms watchdog.** If WiFi drops while a drive key is held, the motors would keep running until the laptop reconnected. The watchdog auto-stops the rover instead. The UI sends `/drive` heartbeats every 150 ms while a key is pressed, which is well inside the watchdog window.
- **Why JSON for `/status`.** Slightly fatter on the wire than a delimited string but trivially parsed in the browser and self-describing for debugging.
- **Why `/scan` blocks.** Single-threaded server, simplest implementation. The UI shows a "Scanning..." button state during the ~600 ms scan and resumes polling afterwards. A more advanced version could integrate IR pulse counts asynchronously.
- **Why classification is not on the rover.** The UI does the table lookup. Keeps the firmware simpler and lets us tweak rules without re-flashing. See section 4.1 of `../CONTROLLER_PLAN.md`.
- **Why CORS headers.** The UI is hosted on the operator's laptop during development, which is a different origin from the rover's IP. The `Access-Control-Allow-Origin: *` header on every JSON response lets the browser accept the response.
- **Why the WiFi connect is bounded and retried.** The starter sketch loops on `WiFi.begin()` forever; a bad password or absent network hangs the board silently. This firmware tries a bounded number of times, then starts anyway and keeps retrying from `loop()`. If the link drops mid-demo it stops the motors and reconnects on its own.
- **Why JSON serialises into a fixed buffer.** Building a heap `String` per request would fragment the 32 KB RAM over a long run. A fixed stack buffer avoids that.

## Files

```
firmware/
├── platformio.ini       PlatformIO project config + library deps
├── README.md            this file
└── src/
    └── main.cpp         all the firmware in one file, sectioned by purpose
```

The single-file structure is intentional. The codebase is small enough that splitting into headers would add navigation overhead without saving lines. As each sensor owner adds non-trivial logic, they may choose to factor their code into `src/sensor_<name>.cpp` and an `include/sensor_<name>.h` - PlatformIO will pick those up automatically.
