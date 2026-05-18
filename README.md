# EEELunarRover - Controller and Firmware

Operator control system for the EEELunarRover, ELEC40006 Electronics Design Project, Group 9.

This part of the project is the rover's **brain and remote control**: the microcontroller firmware that runs on the rover, and the web-based operator console used to drive it and read its sensors. The four analogue sensor subsystems (radio, infrared, ultrasound, magnetic) are owned by other group members and plug in through the interfaces defined here.

## Repository layout

| Path | What it is |
| --- | --- |
| `firmware/` | Metro M0 firmware: WiFi HTTP server, motor control, sensor hooks |
| `ui/` | Browser-based operator console (HTML/CSS/JS) plus a mock rover server |
| `PROJECT_SUMMARY.md` | Project brief, objectives, constraints, rock classification |
| `CONTROLLER_PLAN.md` | The HTTP API contract and controller subsystem design |
| `firmware/FIRMWARE_GUIDE.md` | Section-by-section walkthrough of the firmware |
| `firmware/TEST_LOG.md` | Hardware test record |

## How it works

The operator runs the console in a browser. It talks to the rover over WiFi using a small HTTP API:

```text
Operator browser  <--- WiFi / HTTP --->  Metro M0 firmware
   (ui/)                                   (firmware/)
                                               |
                                       motors and sensors
```

The firmware exposes five endpoints (`/info`, `/status`, `/drive`, `/stop`, `/scan`). The UI polls `/status` for telemetry, sends `/drive` to move the rover, and `/scan` to classify a rock. The full contract is in `CONTROLLER_PLAN.md`.

## Quick start

### Operator console (no hardware needed)

```bash
cd ui
python3 mock_server.py
```

Open <http://localhost:8080/>. The mock server simulates a rover so the UI can be developed and tested without any hardware.

### Firmware

Open `firmware/` in VS Code with the PlatformIO extension, or from the command line:

```bash
cd firmware
pio run            # build
pio run -t upload  # flash a connected Metro M0
```

## Status

| Part | State |
| --- | --- |
| Firmware build | Compiles; runs on real Metro M0 hardware |
| HTTP API | All five endpoints verified over WiFi |
| Drive control | Verified end to end, operator console to motors |
| Operator UI | Working; gamepad, keyboard and on-screen control |
| Sensors | Stubbed; awaiting the four analogue subsystems |

See `firmware/TEST_LOG.md` for the detailed hardware test record.

## Rock classification

The rover identifies one of four rock types from three measurements:

| Type | Infrared rate | Ultrasound | Magnet |
| --- | --- | --- | --- |
| Basaltoid | high (~547/s) | present | down |
| Gravion | low (~312/s) | absent | down |
| Regolix | low (~312/s) | present | up |
| Lunarite | high (~547/s) | absent | up |

It also reads the rock's age, transmitted by radio. Full detail in `PROJECT_SUMMARY.md`.
