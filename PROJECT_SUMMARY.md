# EEELunarRover Project Summary & Objectives

**Module:** ELEC40006 Electronics Design Project (Year 1 EEE/EIE)
**Team size:** 6 members
**Source materials:** `~/Downloads/EEELunarRover2526-main/`

---

## 1. Project Summary

Design, build, and demonstrate a **remotely-controlled lunar rover (EEELunarRover)** that surveys an artificial lunar surface and classifies rocks placed on it. The rover must work in a lab arena alongside other teams' rovers and compete head-to-head on classification speed.

Each rock is characterised by a combination of four signals: a **radio-transmitted age**, **infrared pulse rate**, **ultrasound presence**, and **static magnetic field direction**. The rover identifies the age and resolves one of four rock types from those measurements.

The build is constrained by a **£60 component budget**, a **750g rover weight limit** (for the arena's weight-sensitive zone), and a **3.3V logic level** on the Adafruit Metro M0 microcontroller.

---

## 2. Rock Characterisation Targets

### 2.1 Age (Radio)

- Carrier: **89 kHz**, two-level **amplitude-shift keying** (ASK, on/off).
- Encoding: **UART, 600 baud, 1 start bit, 1 stop bit, 8 data bits, LSB first**.
- Format: **4 ASCII characters** starting with `#` (e.g. `#123` → 1.23 billion years).

### 2.2 Type (Infrared + Ultrasound + Magnetic)

| Type      | IR pulse rate (Poisson) | Ultrasound 40 kHz | Magnet |
|-----------|-------------------------|-------------------|--------|
| Basaltoid | λ = 547 s⁻¹             | Present           | Down   |
| Gravion   | λ = 312 s⁻¹             | Absent            | Down   |
| Regolix   | λ = 312 s⁻¹             | Present           | Up     |
| Lunarite  | λ = 547 s⁻¹             | Absent            | Up     |

IR pulse width is **50 µs**. Expect small deviations in λ.

### 2.3 Magnetism

Static field, so a stationary coil will not detect it. Need a Hall sensor (or equivalent) capable of resolving **field direction** (up vs. down). Magnets are placed inside each rock during the demo.

---

## 3. Objectives

### 3.1 Functional Objectives

1. **Drive** the rover via a remote interface (WiFi web UI from the starter code as the baseline).
2. **Detect and decode** the 89 kHz ASK/UART radio signal into the 4-character age string.
3. **Measure IR pulse rate** accurately enough to distinguish λ = 312 vs. λ = 547 s⁻¹.
4. **Detect** the 40 kHz ultrasound signal (present/absent).
5. **Detect magnetic field direction** (up vs. down).
6. **Classify each rock** by combining IR + ultrasound + magnet readings, and report age + type back to the operator.
7. **Navigate the arena** reliably between rocks spaced ≥ 500 mm apart, without crossing into uncrossable obstacles.

### 3.2 Non-Functional Objectives

- **Mass:** total rover ≤ 750 g (mandatory for the weight-sensitive zone).
- **Budget:** total component spend ≤ £60.
- **Robustness:** survives repeated demo runs without re-soldering or re-flashing.
- **Usable UI:** operator can drive, take readings, and read classifications without retraining between rocks.
- **3.3 V logic discipline:** every signal entering the Metro M0 is clamped or divided to 0–3.3 V.

### 3.3 Assessment-Driven Objectives

- **Interim presentation (28 May 2026):** high-level design, evidence of progress on each subsystem, plan for remaining work.
- **Final report (11 Jun 2026, 10,000 words):** logical design progression, quantitative justifications, test results, individual contributions.
- **Professional Reflection Forms (11 Jun 2026):** must-pass; cover EDI, teamwork, lifelong learning.
- **Demo (16 Jun 2026):** integrated demonstration on lab bench + competitive arena run.

---

## 4. System Architecture (Initial Cut)

Subsystems to deliver and integrate:

1. **Power**: 5 V from EEEBug batteries; 3.3 V from Metro on-board regulator; clean rails to analogue front-ends.
2. **Drivetrain**: 2× DC motors driven by the supplied H-bridge module (DIR + PWM per channel) on the EEEBug chassis.
3. **Radio front-end**: tuned LC antenna at 89 kHz → amplifier → envelope detector (precision rectifier) → comparator → Metro UART RX (pin 0).
4. **IR front-end**: 950 nm-sensitive photodiode/transistor → trans-impedance amp → high-pass filter to reject 50/100 Hz mains → pulse-counting input.
5. **Ultrasound front-end**: 40 kHz transducer → narrow-band amp/filter → envelope or rectified DC level → comparator.
6. **Magnetic sensor**: Hall-effect sensor capable of distinguishing field polarity.
7. **Controller**: Adafruit Metro M0 Express + WINC1500 WiFi shield, running Arduino framework.
8. **Operator UI**: browser-based UI served by the Metro over WiFi (extends the supplied starter sketch).

Reserved pins on the Metro: **5 (CS), 7 (IRQ), 10 (RST)**: used by the WiFi shield, do not reuse. UART on pin 0 is independent of the USB serial, so radio bytes can be decoded while debug printing continues over USB.

---

## 5. Constraints & Risks

- **Voltage limit:** any input > 3.3 V damages the Metro. Potential dividers + measurement before connection are mandatory.
- **Weight budget:** chassis + electronics + battery must stay under 750 g; track weight every time a component is added.
- **Stock & lead time:** stores orders can take a week; out-of-stock items can take months. Order early, verify stock, avoid surface-mount where possible.
- **Mains interference:** strong 100 Hz harmonic in lab lighting can swamp the IR detector. Filter and/or use 950 nm optical filtering.
- **Diode drop in radio rectifier:** signal may be too small for a plain diode; budget for a precision rectifier with a high-slew opamp.
- **Static magnet detection:** stationary coil won't work; need an actual magnetic sensor selected to detect polarity.
- **Schedule:** with the interim only ~2 weeks away (today is 2026-05-13), at least one end-to-end "any reading at all" path per subsystem is the realistic interim target.

---

## 6. Deliverables Checklist

- [ ] Requirements document (subsystem-level, quantitative)
- [ ] System block diagram with interfaces defined
- [ ] Working drivetrain + remote driving via WiFi UI
- [ ] Radio receive chain decoding `#NNN` strings from the rock simulator
- [ ] IR pulse-rate measurement with discrimination between 312/547 s⁻¹
- [ ] 40 kHz ultrasound presence/absence detection
- [ ] Magnet up/down detection
- [ ] Integrated classification logic on the rover, reporting via the web UI
- [ ] Chassis revision (if needed) within mass and budget limits
- [ ] Test data for every subsystem (for the report's evaluation section)
- [ ] Interim presentation slides (28 May 2026)
- [ ] Final report ≤ 10,000 words (11 Jun 2026)
- [ ] Individual Professional Reflection Forms (11 Jun 2026)
- [ ] Demo build ready (16 Jun 2026)

---

## 7. Reference Materials

All source documents are in `~/Downloads/EEELunarRover2526-main/`:

- `doc/brief.md` - full project brief
- `doc/README.md` - technical guide (hardware kit, hints per subsystem, opamp guidance)
- `doc/deliverables-and-mark-scheme.md` - assessment criteria
- `metro-starter-arduino/` and `metro-starter-pio/` - Metro M0 starter sketch with WiFi web server
- `mech/` - EEEBug chassis design files (DXF, SVG, PDF) for laser cutting
