# Firmware Test Log

Hardware testing record for the EEELunarRover firmware.

**Hardware under test:** Adafruit Metro M0 Express + WINC1500 WiFi shield
**Toolchain:** PlatformIO 6.1.19, framework-arduino-samd-adafruit 1.7.16, gcc-arm-none-eabi 9.3.1
**Firmware:** `rover_firmware/src/main.cpp` (v0.2.0)

---

## 2026-05-18 - Session 1: compile and bench flash

### Build verification

| Step | Result |
| --- | --- |
| Install PlatformIO | OK (6.1.19) |
| `pio run` attempt 1 | FAILED. Bundled `Adafruit_TinyUSB_Arduino` would not compile because no USB stack was selected. |
| Fix attempt: `lib_ignore` | Ineffective. The library is bundled in the core, not LDF-discovered. |
| Fix: `build_flags = -DUSE_TINYUSB` in `platformio.ini` | Resolved the TinyUSB error. |
| `pio run` attempt 2 | FAILED. `WiFi.localIP().toString()` - WiFi101's `localIP()` returns a raw `uint32_t`, not an `IPAddress`. |
| Fix attempt: `IPAddress(WiFi.localIP()).toString()` | FAILED. This SAMD core's `IPAddress` has no `toString()`. |
| Fix: format the dotted-quad manually with `snprintf` from `IPAddress` octets | Resolved. |
| `pio run` attempt 3 | SUCCESS. RAM 22.2%, Flash 32.3%. |

Firmware was then improved (bounded WiFi connect with reconnect, JSON serialised into a fixed stack buffer, LED status feedback, larger JSON document sizes) and recompiled: SUCCESS, RAM 22.2%, Flash 32.4%.

### Flash to hardware

| Step | Result |
| --- | --- |
| Metro M0 detected | `/dev/cu.usbmodem21201`, USB ID 239A:8013 |
| `pio run -t upload` attempt 1 | FAILED at ~4%, "SAM-BA operation failed". |
| Observation | Board left in bootloader mode (USB ID changed to 239A:0013). |
| `pio run -t upload` retry | SUCCESS. 1326/1326 pages written, verify successful. |

Note: the SAM-BA upload failing on the first attempt and succeeding on retry was repeatable across both flash sessions. The retry works because the board is already sitting in the bootloader after the failed write.

### First boot - lab WiFi (EEERover)

| Check | Result |
| --- | --- |
| Serial boot output | `Connecting to EEERover` / `IP: 192.168.0.112` / `HTTP server running` |
| WiFi association | OK. DHCP address 192.168.0.112. |
| HTTP API from the laptop | NOT TESTED. The laptop was not on the EEERover network. |

### Issue: laptop / rover network mismatch

The rover joined `EEERover`. The laptop was not on a matching network (its Wi-Fi interface `en0` reported `192.0.0.2`, not associated with EEERover). The laptop and rover must share one network to communicate.

Resolution chosen: move both devices onto a phone hotspot, so the hotspot's cellular link also keeps the development laptop online during testing.

### Re-flash - hotspot

| Step | Result |
| --- | --- |
| `ssid` / `pass` changed to the hotspot (local change, must NOT be committed) | Done |
| `pio run -t upload` | FAILED first attempt, SUCCESS on retry (same SAM-BA pattern). |
| Rover IP on the hotspot | `172.20.10.6`. Serial: `Connecting to Josh (2)` / `IP: 172.20.10.6` / `HTTP server running`. |

### HTTP API test - hotspot

Laptop joined `Josh (2)` (address `172.20.10.5`); rover at `172.20.10.6`. All endpoints exercised with `curl` from the laptop:

| Endpoint | Request | Response | Result |
| --- | --- | --- | --- |
| `/info` | GET | `{"group":0,"ip":"172.20.10.6","fw_version":"0.2.0"}` | PASS |
| `/status` | GET | full JSON: `drive`, `sensors`, `state":"idle"` | PASS |
| `/drive` | `?l=200&r=200` | `{"drive":{"left":200,"right":200}}` | PASS |
| `/stop` | GET | `{"stopped":true}` | PASS |
| `/scan` | GET | `{"age":"#317","ir_rate_hz":547,"ultrasound_present":true,"magnet":"up","classification":null}` | PASS |

Sensor values are the firmware stub defaults (age `#317`, IR 547 Hz, ultrasound present, magnet up), as expected with no analogue hardware connected.

Watchdog observed: a single `/drive` request with no follow-up heartbeat caused the motors to auto-stop roughly 500 ms later (LED solid briefly, then off), confirming the 500 ms drive watchdog. The operator UI sends heartbeats every 150 ms, so under normal driving the LED stays solid.

### Motor wiring and drive test

Motor driver: dual H-bridge module, wired to the Metro as below. Firmware pin constants updated to match and re-flashed.

| Signal | Metro pin |
| --- | --- |
| Right motor direction | D4 |
| Right motor enable (PWM) | D9 |
| Left motor direction | D12 |
| Left motor enable (PWM) | D6 |

USB issue during this re-flash: after a failed SAM-BA upload the board stopped enumerating on USB entirely (no serial port, nothing in the USB registry) even though the bootloader LED was breathing. Recovered by **double-tapping the RESET button**, which re-initialised the bootloader USB and brought the port back. Worth knowing: if the board vanishes from USB during flashing, double-tap reset.

Drive test: rover on the hotspot, operator console pointed at it, holding the drive controls spun the motors. **The full control path is verified end to end: console -> WiFi -> firmware -> H-bridge -> motors.**

---

## Outstanding

- [x] Capture the rover's IP on the hotspot - `172.20.10.6`
- [x] HTTP API test from the laptop - all five endpoints PASS
- [x] Onboard LED - watchdog auto-stop observed (solid then off); full WiFi-down blink not yet checked
- [x] Point the operator UI at the real rover
- [x] Test `/drive` with motors physically wired - motors spin, full control path verified
- [ ] Confirm each motor's direction is correct (forward = forward); flip `DIR` logic for any reversed motor
- [ ] Replace sensor stubs with real subsystem code as each comes online
- [ ] Revert `ssid` / `pass` to `EEERover` / `exhibition` before committing

## Notes for the report

- The SAM-BA first-attempt failure is a known PlatformIO + SAMD bootloader quirk, worth a sentence in the evaluation section as a build-process observation.
- Compiling cleanly is necessary but not sufficient; two genuine API bugs (`USE_TINYUSB`, `localIP()`) only surfaced at compile time, and runtime behaviour (WiFi, motors, sensors) still needs separate verification on hardware.
