# Controller Subsystem Plan

**Owner:** [User's name] - UI / web controller
**Embedded counterpart:** [Teammate's name] - Metro M0 firmware
**Status:** Draft v0.1 - to be reviewed by the team
**Last updated:** 2026-05-13

This document defines the operator UI, the HTTP API between the UI and the rover, and the working agreement between the **UI lead (me)** and the **embedded lead** (teammate writing the Metro M0 firmware).

It is deliberately written *before* any code so that both sides can develop in parallel against the same contract. Once it's agreed, neither side should change the contract unilaterally.

---

## 1. Goals

The controller subsystem must let an operator:

1. **Drive** the rover around the arena with low enough latency that it feels responsive.
2. **See live sensor data** from every subsystem (radio age, IR pulse rate, ultrasound, magnet).
3. **See the classification** of the rock currently in front of the rover (Basaltoid / Gravion / Regolix / Lunarite).
4. **Recover gracefully** when WiFi drops, the rover is rebooting, or a sensor isn't ready.

Non-goals (out of scope for the project):

- Multi-user operation (one operator at a time).
- Persistent storage of past runs (a CSV download is nice-to-have, not required).
- Offline mode.

---

## 2. Architecture

```text
+----------------------+       WiFi (HTTP)        +-----------------------------+
|  Operator browser    | <----------------------> |  Metro M0 firmware          |
|  (laptop or phone)   |   GET /status, /drive,   |  WiFiWebServer @ 192.168... |
|  Static HTML/JS/CSS  |   /scan, /stop           |                             |
+----------------------+                          +-----------------------------+
                                                       |        |        |
                                                  motors   sensor MCU pins
```

**Decision:** the UI is a **static HTML/JS/CSS page hosted on the operator's laptop** (or served by the Metro for fallback). It talks to the Metro via HTTP. This means:

- The UI can be developed and tested against a **mock server on the laptop** without needing a real rover. Critical for parallel work.
- The Metro firmware only has to serve a small JSON API, not a webpage with embedded HTML/JS. Shorter firmware, less re-flashing.
- At demo time the laptop runs a browser pointed at `http://192.168.0.<groupNumber+1>/`.

**Fallback:** if the laptop's WiFi can't reach the rover, the firmware also serves a minimal HTML page at `GET /` so the operator can drive from a phone on the lab WiFi.

---

## 3. HTTP API Contract (v0.1)

All endpoints return `Content-Type: application/json` unless noted. All responses include a `t` field with the rover's uptime in milliseconds (`millis()`).

Errors return HTTP 4xx/5xx with `{"error": "<message>"}`.

### 3.1 Status & telemetry

#### `GET /status`

Polled by the UI at ~5 Hz. Returns the latest snapshot of everything.

```json
{
  "t": 12345,
  "drive": { "left": 128, "right": -64 },
  "sensors": {
    "age": "#317",
    "age_valid": true,
    "ir_rate_hz": 547,
    "ir_valid": true,
    "ultrasound_present": true,
    "ultrasound_valid": true,
    "magnet": "up",
    "magnet_valid": true
  },
  "battery_mv": 7200,
  "state": "idle"
}
```

- `age` is the 4-character string received over radio (`#NNN`), or `null` if not yet decoded.
- `*_valid` flags let the UI grey out stale readings instead of showing rubbish.
- `state` is `idle | driving | scanning | error`.

#### `GET /info`

Returns once at UI startup.

```json
{ "group": 7, "ip": "192.168.0.8", "fw_version": "0.1.0" }
```

### 3.2 Driving

#### `GET /drive?l=<int>&r=<int>`

Sets the left and right motor commands. Both are signed integers in `[-255, 255]`. `0` = stop. Sign = direction. Magnitude maps to PWM duty.

Response: `200 OK` with `{ "t": ..., "drive": { "left": l, "right": r } }`.

**Watchdog:** if the firmware doesn't receive a `/drive` call for **500 ms**, it must automatically set both motors to 0. This prevents runaway if WiFi drops while a button is held.

#### `GET /stop`

Hard stop - sets both motors to 0 immediately, returns `{ "t": ..., "stopped": true }`.

### 3.3 Scanning

#### `GET /scan`

Triggers a measurement cycle. The firmware:

1. Reads each sensor for up to ~1 second.
2. Decodes the age from the radio buffer.
3. Returns a result snapshot.

```json
{
  "t": 12500,
  "age": "#317",
  "ir_rate_hz": 547,
  "ultrasound_present": true,
  "magnet": "up",
  "classification": null
}
```

`classification` is left `null` here - **classification is done on the UI side** (see the next section), so the UI does the table lookup using the four raw values.

---

## 4. What lives where

Two parallel "where does this logic run" decisions.

### 4.1 Classification logic, UI side

**Decision:** classification (mapping {IR rate, ultrasound, magnet} to rock type) lives **in the JS on the UI side**, not in the firmware.

**Why:**

- The rules can change without re-flashing the Metro.
- The UI can show *why* a rock was classified the way it was ("547 Hz IR + ultrasound + up = Regolix").
- Firmware stays simpler, it returns raw measurements.

**Trade-off:** if we ever wanted a "lights-only" UI (no JS) it wouldn't work. Acceptable, we always have JS at demo time.

### 4.2 State machine, firmware side

**Decision:** the rover state machine (`idle | driving | scanning | error`) lives **in the firmware**. The UI mirrors it by rendering whatever `/status.state` reports.

**Why:**

- Every state transition is triggered by something only the firmware can observe: a `/drive` request arrived, the 500 ms watchdog fired, a scan finished, a sensor faulted.
- One source of truth. If the UI also tracked state, a WiFi blip or a page refresh would put UI and rover out of sync and recovery would be subtle.
- Recovery is automatic, the UI just renders whatever the next `/status` reports.

The UI keeps its own **view state**, which is presentation-only and never round-trips to the firmware:

- `connecting...` (no `/status` response yet)
- `stale` (last `/status` older than 1 s)
- modal open/closed, speed slider position, saved-readings panel state.

**Rule of thumb when in doubt:** if the value would need to survive an unplug-and-reboot of the rover, it is rover state and lives in the firmware. If not (slider position, modal open/closed), it is view state and lives in the UI.

---

## 5. UI scope (this is mine)

### 5.1 Screen layout (rough)

Drive controls are the focal point - large D-pad style buttons, big central STOP, prominent speed slider. Sensors and classification sit in a slimmer right-hand column so the operator's eye and thumb both default to the drive panel during a run.

```text
+------------------------------------------------------------------------------+
|  EEELunarRover Operator                                     [ status dot ]   |
+------------------------------------------------------------------------------+
|                                                                              |
|   +----- DRIVE -----------------------+    +--- Sensors -----------------+   |
|   |                                   |    | Age:         #317           |   |
|   |              +-----------+        |    | IR rate:     547 Hz         |   |
|   |              |    /\     |        |    | Ultrasound:  present        |   |
|   |              |  FORWARD  |        |    | Magnet:      up             |   |
|   |              +-----------+        |    +-----------------------------+   |
|   |                                   |                                      |
|   |  +-------+  +----------+ +------+ |    +--- Classification ----------+   |
|   |  |  <-   |  |          | |  ->  | |    |  ROCK TYPE:  Regolix        |   |
|   |  | LEFT  |  |   STOP   | | RIGHT| |    |  Age:        3.17 Gyr       |   |
|   |  +-------+  |   [ X ]  | +------+ |    +-----------------------------+   |
|   |             |          |          |                                      |
|   |             +----------+          |    +--- Actions -----------------+   |
|   |                                   |    |  [   Scan rock   ]          |   |
|   |              +-----------+        |    |  [   Save reading ]         |   |
|   |              |   \/      |        |    +-----------------------------+   |
|   |              |  REVERSE  |        |                                      |
|   |              +-----------+        |                                      |
|   |                                   |                                      |
|   |   Speed  [============O=========] |                                      |
|   |          slow              fast   |                                      |
|   |                                   |                                      |
|   |   Keys: W / A / S / D or arrows   |                                      |
|   +-----------------------------------+                                      |
|                                                                              |
+------------------------------------------------------------------------------+
```

Notes on the layout:

- Drive panel occupies ~60% of the page width and stays fixed in place - the operator never has to scroll to reach a control.
- **STOP** is the only red button on the page and is the biggest target. It triggers `GET /stop` and overrides any held drive button.
- Directional buttons use both an arrow glyph **and** a word so the meaning is unambiguous on a phone or to someone new to the UI.
- Speed slider labels the extremes (`slow` / `fast`) and shows a live numeric readout above the bar (not drawn).
- Keyboard hint is rendered inside the drive panel so it's discoverable.

### 5.2 Controls

- **Driving:** on-screen buttons + WASD/arrow-key fallback. Hold = drive, release = stop (relies on the firmware watchdog defined in the Driving endpoint above).
- **Speed slider** caps max PWM so testing isn't terrifying.
- **STOP** is a hard stop - calls `GET /stop`, cancels any held direction.
- **Scan button** calls `/scan` and renders the result + classification.
- **Save reading** appends the current scan to a local CSV-like list in `localStorage` (nice-to-have).

### 5.3 Tech choices

- Plain **HTML + CSS + vanilla JS**. No build step. One `index.html`, one `app.js`, one `styles.css`.
- A `MOCK = true` flag in `app.js` that swaps `fetch('/status')` for a local fake-data function - so I can develop with no rover at all.

---

## 6. Liaison plan with the embedded lead

This is the part that has to actually work.

### 6.1 Division of labour

| Area | Owner |
| --- | --- |
| WiFi setup, HTTP server, JSON serialisation | Embedded |
| Motor PWM (using H-bridge module, DIR/PWM pins) | Embedded |
| `/drive` watchdog (500 ms timeout) | Embedded |
| Sensor reading code per subsystem | **Each sensor owner** writes a function (`readIR()`, `readMagnet()`, etc.) that the embedded lead calls from `/status` and `/scan` |
| `/status` JSON shape | **Both**: locked by the API contract above |
| HTML page (`GET /`) fallback for phone driving | Embedded (minimal - just buttons calling `/drive`) |
| Full UI (rich JS app) | Me |
| Classification table-lookup | Me (in JS) |
| Mock server for local UI development | Me |

### 6.2 Working agreement

1. **The API contract (§3) is the source of truth.** Any change is a 2-minute conversation between me and the embedded lead, then both sides update.
2. **Shared git repo** for the firmware *and* the UI - branches per feature, PRs for review (and so the rest of the team can see progress).
3. **Weekly 15-minute sync** between me and the embedded lead. Just us, separate from the team standup.
4. **One Slack/Teams channel** for the two of us so quick API questions don't get buried in the group chat.
5. **Both sides keep a stub of the other.** Firmware ships with a hardcoded fake `/status` from day one. UI ships with a `MOCK = true` mode from day one. Neither subsystem is allowed to block the other.

### 6.3 Integration milestones

| Date | Embedded ships | I ship | Joint test |
| --- | --- | --- | --- |
| **2026-05-16** | Starter sketch flashed, web server reachable on the lab WiFi, `GET /info` returns hardcoded JSON | UI loads in mock mode, drive buttons + sensor panels render with fake data | Browser on the lab WiFi can reach `/info` on the Metro |
| **2026-05-20** | `/status` returns hardcoded JSON matching the contract above; `/drive` toggles a debug LED | UI driving buttons hit `/drive`; UI polls `/status` at 5 Hz and shows the fake values | End-to-end click → LED, with sensor panel updating from hardcoded JSON |
| **2026-05-25** | `/drive` actually drives the motors with watchdog; one real sensor (say magnet) wired into `/status` | Classification logic in JS, scan flow works end-to-end with mock + real magnet | Drive the rover on a bench, scan a real magnet, see "up/down" in the UI |
| **2026-05-27** | Whatever sensors are working integrated into `/status` and `/scan` | Polished UI for interim demo | Dress rehearsal for **interim 2026-05-28** |

### 6.4 Things I need from the embedded lead

- Group number (so I know the static IP).
- Confirmation of the API contract in §3 - or proposed changes.
- A debug pin/LED I can toggle via `/drive` before motors are wired.
- Their preferred git workflow (single repo with `rover_firmware/` + `UI/` folders? two repos?).

### 6.5 Things they need from me

- A working **mock server** (`mock_server.py`) so they can test their UI HTML fallback against the same JSON shapes I'm consuming.
- A short list of HTTP behaviours the firmware must implement (the watchdog, the error JSON shape, the auto-stop on missing `/drive` heartbeats). Already captured above.

---

## 7. Open questions for the team

Decisions that affect more than just the controller subsystem. To be resolved at the next team meeting.

1. **What device does the operator use at demo time**: laptop or phone? Affects screen sizing and whether keyboard controls are realistic.
2. **Auto-scan or manual scan?** Should the rover continuously stream sensor data, or only when the operator presses "Scan"? Cheaper firmware + clearer demo if manual; more "wow factor" if continuous.
3. **One rock per session, or a list?** Does the UI need to remember the rocks classified so far?
4. **Single git repo or separate repos** for firmware and UI? Single repo is easier; separate is cleaner.
5. **Who owns the `localStorage` history feature?** Nice-to-have, but if no one owns it, it won't ship.

---

## 8. My actions this week (2026-05-13 → 2026-05-20)

- [ ] Walk this doc through the embedded lead in person. Lock §3 (the API contract).
- [ ] Get the starter code flashed and reachable on my own laptop. I have to be able to flash a Metro before I can claim my subsystem works.
- [ ] Scaffold `UI/` under this folder: `index.html`, `app.js`, `styles.css`, `mock_server.py`.
- [ ] Write the mock server first (Python, ~30 lines, returns the §3 JSON shapes).
- [ ] Build the driving panel + WASD keys against the mock server.
- [ ] Bring the mocked, working UI to the team meeting so people can see the contract running, not just read it.
