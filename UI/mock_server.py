"""Mock EEELunarRover HTTP server for UI development.

Serves the static UI files in this folder AND implements the rover HTTP API
contract defined in CONTROLLER_PLAN.md. Lets the operator UI be developed
and tested without an actual rover plugged in.

Run:  python3 mock_server.py
Open: http://localhost:8080/

Press Ctrl+C to stop.
"""

import http.server
import json
import os
import random
import socketserver
import time
import urllib.parse

PORT = 8080
STATIC_DIR = os.path.dirname(os.path.abspath(__file__))
START_TIME = time.time()

ROCK_PROFILES = {
    "Basaltoid": {"ir_rate_hz": 547, "ultrasound_present": True,  "magnet": "down"},
    "Gravion":   {"ir_rate_hz": 312, "ultrasound_present": False, "magnet": "down"},
    "Regolix":   {"ir_rate_hz": 312, "ultrasound_present": True,  "magnet": "up"},
    "Lunarite":  {"ir_rate_hz": 547, "ultrasound_present": False, "magnet": "up"},
}

state = {
    "drive": {"left": 0, "right": 0},
    "last_drive_ms": 0,
    "scan_running": False,
    "sim_rock": random.choice(list(ROCK_PROFILES.keys())),
}


def uptime_ms() -> int:
    return int((time.time() - START_TIME) * 1000)


def rover_state() -> str:
    if state["scan_running"]:
        return "scanning"
    # 500 ms watchdog: if no /drive heartbeat, motors off
    if state["drive"]["left"] != 0 or state["drive"]["right"] != 0:
        if uptime_ms() - state["last_drive_ms"] > 500:
            state["drive"] = {"left": 0, "right": 0}
            return "idle"
        return "driving"
    return "idle"


def sensor_snapshot() -> dict:
    profile = ROCK_PROFILES[state["sim_rock"]]
    ir = profile["ir_rate_hz"] + random.randint(-15, 15)
    # The radio receiver only locks in when stationary (a plausible firmware behaviour)
    is_idle = rover_state() == "idle"
    age_valid = is_idle and random.random() > 0.05  # occasional dropout
    age = f"#{random.randint(100, 999):03d}" if age_valid else None
    return {
        "age": age, "age_valid": age_valid,
        "ir_rate_hz": ir, "ir_valid": True,
        "ultrasound_present": profile["ultrasound_present"], "ultrasound_valid": True,
        "magnet": profile["magnet"], "magnet_valid": True,
    }


class Handler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=STATIC_DIR, **kwargs)

    def log_message(self, fmt, *args):
        # Quieter log: only print interesting endpoints
        path = self.path.split("?", 1)[0]
        if path in ("/status",):
            return
        super().log_message(fmt, *args)

    def end_headers(self):
        # Permissive CORS so the UI can be served from anywhere during development
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Cache-Control", "no-store")
        super().end_headers()

    def _send_json(self, payload, status=200):
        body = json.dumps(payload).encode("utf-8")
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def do_GET(self):
        parsed = urllib.parse.urlparse(self.path)
        path = parsed.path
        qs = urllib.parse.parse_qs(parsed.query)

        if path == "/info":
            return self._send_json({
                "t": uptime_ms(),
                "group": 0,
                "ip": "localhost",
                "fw_version": "mock-0.1.0",
            })

        if path == "/status":
            return self._send_json({
                "t": uptime_ms(),
                "drive": state["drive"],
                "sensors": sensor_snapshot(),
                "battery_mv": 7200 + random.randint(-150, 0),
                "state": rover_state(),
            })

        if path == "/drive":
            try:
                l = int(qs.get("l", ["0"])[0])
                r = int(qs.get("r", ["0"])[0])
            except ValueError:
                return self._send_json({"error": "invalid l/r"}, 400)
            l = max(-255, min(255, l))
            r = max(-255, min(255, r))
            state["drive"] = {"left": l, "right": r}
            state["last_drive_ms"] = uptime_ms()
            return self._send_json({"t": uptime_ms(), "drive": state["drive"]})

        if path == "/stop":
            state["drive"] = {"left": 0, "right": 0}
            return self._send_json({"t": uptime_ms(), "stopped": True})

        if path == "/scan":
            state["scan_running"] = True
            time.sleep(0.6)  # simulate scan duration
            state["scan_running"] = False
            # Rotate the simulated rock so successive scans differ (helps demo)
            state["sim_rock"] = random.choice(list(ROCK_PROFILES.keys()))
            profile = ROCK_PROFILES[state["sim_rock"]]
            return self._send_json({
                "t": uptime_ms(),
                "age": f"#{random.randint(100, 999):03d}",
                "ir_rate_hz": profile["ir_rate_hz"] + random.randint(-15, 15),
                "ultrasound_present": profile["ultrasound_present"],
                "magnet": profile["magnet"],
                "classification": None,
                "_truth": state["sim_rock"],  # for debugging only; firmware would not send this
            })

        # Anything else: static files (index.html, app.js, styles.css)
        return super().do_GET()

    def do_OPTIONS(self):
        self.send_response(204)
        self.send_header("Access-Control-Allow-Methods", "GET, OPTIONS")
        self.send_header("Access-Control-Allow-Headers", "*")
        self.end_headers()


class ThreadedServer(socketserver.ThreadingMixIn, http.server.HTTPServer):
    daemon_threads = True
    allow_reuse_address = True


def main():
    with ThreadedServer(("", PORT), Handler) as httpd:
        print(f"Mock rover serving UI + API at http://localhost:{PORT}/")
        print(f"Simulated rock: {state['sim_rock']} (rotates on each /scan)")
        try:
            httpd.serve_forever()
        except KeyboardInterrupt:
            print("\nBye.")


if __name__ == "__main__":
    main()
