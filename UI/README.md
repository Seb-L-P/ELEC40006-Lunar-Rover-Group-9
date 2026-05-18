# Operator UI

Static HTML/JS/CSS operator interface for the EEELunarRover. Talks to the rover over HTTP per the contract in `../CONTROLLER_PLAN.md`.

## Run it locally (mock mode)

The mock server hosts the UI and a fake rover API on the same port, so no CORS pain.

```bash
cd UI
python3 mock_server.py
```

Then open <http://localhost:8080/> in a browser. The simulated rock changes every time you press **Scan rock**.

Requires Python 3.7+. No pip install needed, only the standard library.

## Run against a real rover

Open the page against the rover's HTTP server. Two ways:

1. **UI served by the rover firmware** (if the embedded lead implements `GET /` to return this `index.html`): just visit `http://192.168.0.<groupNumber+1>/`.
2. **UI hosted on your laptop, API on the rover:** open `http://localhost:8080/?api=http://192.168.0.<groupNumber+1>` so the page fetches from the rover instead of localhost. Requires the firmware to send `Access-Control-Allow-Origin: *` headers, or visit the page directly from the rover.

## Controls

The console accepts three input methods, all live at once:

### Gamepad (primary)

Pair an Xbox (or any standard) controller with the laptop over USB or Bluetooth. The browser detects it automatically via the Gamepad API; the header shows "Gamepad connected".

| Control | Action |
| --- | --- |
| Left stick | Drive (proportional speed and turn) |
| Controller D-pad | Drive (digital) |
| A button | Scan rock |
| B button | Stop |

The left stick wins whenever it is moved; release it and keyboard/on-screen control takes over.

### Keyboard and on-screen D-pad (fallback)

Always available, including if the gamepad disconnects mid-run.

| Key | Action |
| --- | --- |
| `W` / `↑` | Forward (hold) |
| `S` / `↓` | Reverse (hold) |
| `A` / `←` | Turn left (hold) |
| `D` / `→` | Turn right (hold) |
| `Space` / `X` / `Esc` | Stop |

The on-screen mini D-pad in the Control panel does the same thing for touch/mouse.

Switching tab or backgrounding the page auto-sends `/stop` for safety.

## Files

| File | Purpose |
| --- | --- |
| `index.html` | Page structure |
| `styles.css` | Layout and theme |
| `app.js` | Input handling, polling, classification, scan, saved readings |
| `mock_server.py` | Local rover stand-in implementing the same HTTP API |

## Classification logic

Lives in `app.js` (`classify()`) as a four-row lookup against the table in the project brief:

| IR rate (Hz) | Ultrasound | Magnet | Type |
| --- | --- | --- | --- |
| ≥ 430 (≈547) | present | down | Basaltoid |
| < 430 (≈312) | absent | down | Gravion |
| < 430 (≈312) | present | up | Regolix |
| ≥ 430 (≈547) | absent | up | Lunarite |

The 430 Hz threshold is the midpoint between the two Poisson rates (312 and 547 s⁻¹). The brief warns to expect small deviations, hence the wide margin.

## What this UI assumes from the firmware

- `GET /info` returns JSON with `group`, `ip`, `fw_version`.
- `GET /status` returns the JSON shape used by `renderStatus()` in `app.js`.
- `GET /drive?l=<int>&r=<int>` accepts signed PWM values in `[-255, 255]`.
- `GET /stop` zeroes both motors immediately.
- `GET /scan` runs a measurement cycle (≤ ~1 s) and returns age + raw sensor readings.
- A **500 ms watchdog** auto-zeros motors if `/drive` stops being called. The UI re-sends the held command every 150 ms to stay inside the watchdog.

All of this is locked in `../CONTROLLER_PLAN.md` and must be agreed with the embedded lead before code on either side hardens.
