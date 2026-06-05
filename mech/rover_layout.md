# EEELunarRover — mechanical layout & sensor placement

Master mechanical design for mounting the four sensor subsystems, the battery,
the controller and the analogue perfboards onto the existing **EEEBug V3.1**
chassis. The printable parts that implement this are in
[`print/`](print/README.md); the parts to order are in
[`../hardware/BOM.md`](../hardware/BOM.md).

> **See it in 3D:** `print/rover_assembly.scad` combines all the printed parts
> with representative blocks for the chassis, wheels, battery and Metro. Open it
> in OpenSCAD (F5) or look at `print/preview/rover_assembly*.png`.

**Constraints driving every decision:** ≤ **750 g** total, ≤ **£60** budget
(~£55 left), **3.3 V** logic, four analogue front-ends that must not pick up
motor/PWM/mains noise, and a **20 × 20 × 20 cm PLA printer** that we are told
*not* to use to its full extent.

---

## 1. The problem in one line

Place a radio coil, an IR detector, a 40 kHz ultrasonic receiver and a Hall
sensor so they all read a rock on the floor, while keeping the heavy battery
over the drive axle for balance and keeping every weak analogue signal away
from the motors — without breaching 750 g or £55.

---

## 2. Chassis facts (measured from `chassis.svg`)

| Property | Value | Source |
|---|---|---|
| Overall size | **95.0 mm (X) × 205.0 mm (Y)** | SVG bounding box ÷ 96 dpi |
| Material | 3 mm acrylic | `CHASSIS_CAD.md` |
| Drive axle / wheel line | **y ≈ 105 mm (centre)** | width pinches 95→85 mm at y 96–114 (wheel wells) |
| Motor-driver PCB | central, **y ≈ 81–139** | Ø2.6 mm holes on the centreline at y 81.3 & 138.7 |
| Front slots (keep clear) | two 29.6 × 13 mm at y ≈ 3.5 | SVG |
| Mounting holes | M3 (Ø3.1) | SVG (Ø5.86 px) |

**Central M3 anchor holes** (chassis coordinates, the ones we bolt to):

| Row | Left (x) | Right (x) | X-pitch | Used for |
|---|---|---|---|---|
| y = 85  | 10.0 | 85.0 | 75 mm | battery tray (front) |
| y = 95  | 10.5 | 84.5 | 74 mm | **sensor boom** |
| y = 129 | 10.5 | 84.5 | 74 mm | battery tray (rear) |

> **Why a centre axle changes the layout:** the brief says the motor-driver PCB
> is *central* and the Metro mounts at the *rear*; the wheel wells confirm the
> axle is at the middle (y ≈ 105). So the rover **pivots about its centre**.
> Keep the centre of gravity over the axle (both end-skids then carry equal,
> light loads) and put the sensitive sensors on the end **farthest from the
> motor magnets** — the front.

---

## 3. Coordinate system

- **X** = 0…95 mm, left→right across the chassis.
- **Y** = 0 mm at the **front (leading) edge**, 205 mm at the **rear (Metro) edge**.
- The rover drives **front-first** toward the rocks. (Differential drive: which
  way is "forward" is just firmware sign — see `rover_firmware`.)

---

## 4. Top view

```
                      FRONT  (leading edge, y = 0)
        x=0                                            x=95
         +--------------------------------------------+  y=0
         |  [ slot ]                        [ slot ]   |   existing front slots
         |                                            |
         |        .------ SENSOR BOOM ------.         |   boom cantilevers
         |        |  IR | US | HALL (tip)   |>>>>     |   FORWARD past y=0,
         |        |  (down-facing, in line) |         |   skid at the tip
         |   ####################################     |
         |   #   ANTENNA COIL  (Ø50, low)      #      |   y≈20-60, short stand-offs
         |   ####################################     |
         |                                            |
         |  o (10.5, 85)                  (85.0, 85) o |   <- tray anchors
         |  O (10.5, 95)  boom anchors    (84.5, 95) O |   <- BOOM anchors
         | ====================  DRIVE AXLE  ======== |   y=105  wheels L & R
         |        [   MOTOR-DRIVER PCB  (central)  ]  |   y=81-139
         |  o (10.5,129)                 (84.5,129) o |   <- tray anchors
         |   +======= 4xAA BATTERY on tray =======+   |   raised OVER the axle
         |   |     (heaviest item, over y=105)    |   |
         |   +====================================+   |
         |                                            |
         |        [  METRO M0  +  WiFi shield  ]      |   y≈150-205 (rear mount)
         |                                            |
         +--------------------------------------------+  y=205
                      REAR  (Metro end)

   O = boom standoff   o = battery-tray standoff
```

The three sensor housings sit **in a line on the centre line at the boom tip**,
all facing **down** at the rock the rover noses up to. The big radio coil sits
low and flat just behind them. The battery is the only heavy item and it sits
**directly over the axle**.

## 5. Side view (heights, not to scale)

```
        battery tray  ____________________
                      |  4xAA on tray     |  ~25 mm standoffs (clears PCB)
   motor-driver PCB ..|...................|..
         deck  _______|___________________|________  Metro+WiFi
   ____________|__________ chassis (3mm acrylic) ___________
   boom  ____ /                                    \____ skids
        /  IR US HALL  <- low, near floor             wheels Ø~65
   ====O========================(o)=====================O====  FLOOR
        ^ front skid (=Hall pod)   ^ drive wheel
```

The boom drops the sensors **low and forward** (small air-gap to the rock); the
battery rises **high and central** (over the axle). The Hall pod at the boom tip
is the lowest point and **doubles as the front skid**.

---

## 6. Where each subsystem goes, and why

### 6.1 Radio / age (89 kHz coil)
- **Where:** front-**left**, low and flat (coil axis vertical), on the Ø36
  low-profile bobbin, ~20–60 mm from the front edge. Off the boom centre-line so
  the boom can sit low (see the assembly model). Its demodulator perfboard
  mounts right next to it (short antenna leads).
- **Why:** the rock radiates from a coil in the plane of its PCB on the floor,
  so a horizontal pickup coil held low and close couples best. The signal is
  tiny and needs a precision rectifier, so the antenna→amp wire must be short
  and **far from the motors (PWM brush noise) and the battery/DC rail**. Front
  is ~105 mm from the central motors. Decoded UART goes to **Metro D0**.

### 6.2 Infrared / type (SFH 300)
- **Where:** boom tip, down-facing, inside the **IR shroud** (light-tight tube).
- **Why:** the rock's 50 µs IR pulses are weak and easily swamped by the lab's
  100 Hz lighting harmonic. The shroud blocks side/ambient light; the existing
  trans-impedance + high-pass + comparator chain (`../hardware/ir_sensor_build.md`)
  rejects the rest. Keep the SFH 300 leads short to its amp → its perfboard
  rides on the boom. Comparator output → **Metro D2** (edge counting).

### 6.3 Ultrasound / type (Murata MA40S4R)
- **Where:** boom tip, down-facing, in the **ultrasound clamp**, next to the IR.
- **Why:** presence/absence of 40 kHz only — point the receiver at the rock and
  band-pass + rectify. Robust digital "present/absent" output, so its routing is
  not noise-critical. → an unused Metro pin (assign in `pin_map.md`).

### 6.4 Magnetic / type (Honeywell SS49E)
- **Where:** the **lowest** point of the boom tip (Hall pod), front-most, facing
  down. **This is the placement that matters most.**
- **Why:** two competing pulls — it must get *close* to the magnet inside the
  rock (field falls as ~1/distance³; aim for a ≥ 5 mT air-gap, i.e. as low as
  possible) **and** stay *far* from the rover's own DC-motor magnets, which
  would bias the reading. Centre-axle motors sit ~105–125 mm behind the pod —
  far enough. Ratiometric output (≈ V/2 at zero field, above for one polarity,
  below for the other) → a Metro analogue input; **up vs down = above/below
  mid-rail.** Take a *motors-off* baseline in firmware and threshold around it.

### 6.5 Battery (4 × AA)
- **Where:** on the printed tray, raised over the axle (y 85–129), above the
  central motor-driver PCB.
- **Why:** heaviest single item (~100 g). Over the axle it balances the
  centre-pivot rover and loads the drive wheels for traction, while its
  switching noise stays well away from the front analogue front-ends.
  **Do not order cells** — they are in the kit and batteries are a forbidden
  order line.

### 6.6 Controller (Metro M0 + WiFi shield)
- **Where:** rear (y 150–205), on the chassis's existing rear Metro mount.
- **Why:** keeps the WiFi shield and its digital switching away from the front
  analogue section, and balances some weight behind the axle against the
  forward boom. Pins 5/7/10 reserved for WiFi (do not reuse).

---

## 7. Mounting-hole assignment

| Printed part | Bolts to chassis holes | Fastener |
|---|---|---|
| Sensor boom | (10.5, 95) & (84.5, 95) | 2× M3 nylon standoff, short (sensors low) |
| Battery tray | (10.0, 85) & (85.0, 85) & (10.5, 129) & (84.5, 129) | 4× M3 nylon standoff, ~25 mm (clear the PCB) |
| Antenna bobbin | front holes / zip-tie through chassis | 2× M3 or cable tie |
| Perfboard carriers | onto boom or central deck (2× M3 @ 12 mm) | M3 nylon |
| Sensor housings | onto the boom docks (2× M3 @ 12 / 20 mm) | M3 nylon |

The boom (y = 95) and tray (y = 85/129) never share a hole. The ≤ 1 mm pitch
difference between the y = 85 row (75 mm) and the y = 95/129 rows (74 mm) is
absorbed by Ø3.4–3.6 mm clearance holes. **Verify all holes on the physical
board** — laser kerf widens internal holes ~0.1–0.2 mm.

---

## 8. Verified part dimensions (used in the 3D models)

| Part | Used for | Dimensions driving the model | Source |
|---|---|---|---|
| OSRAM **SFH 300** | IR shroud bore | 5 mm T-1¾ radial, body **Ø5.1 mm**, ~8.6 mm tall, 2.54 mm leads | ams-OSRAM datasheet |
| Murata **MA40S4R** | ultrasound clamp bore | body **Ø9.9 mm**, **7.1 mm** tall, **5.0 mm** lead pitch | Murata DM-U16-483 |
| Honeywell **SS49E** | Hall pod slot | flat pkg **4.1 × 1.7 × 3.0 mm**, 1.27 mm leads, 2.7–6.5 V | Honeywell datasheet |
| Microchip **MCP6292-E/P** | on perfboards | **PDIP-8** (through-hole), RRIO, 10 MHz/7 V/µs | Microchip DS20001812G |
| Roth **RE015 / RE016** | perfboard carriers | **40.5 × 40** / **68.58 × 67.94 × 1.5 mm** | RS product pages |
| M3 nylon hex | print clearances | across-flats **5.4–5.6 mm** | Rapid R-TECH pages |

> **Flags carried from research:** the SFH 300 *height* (~8.6 mm) was not crisp
> on the datasheet drawing — callipers before finalising the shroud length. The
> SS49E reads polarity but at ~14 mV/mT; if the air-gap to the rock magnet is
> large, switch to the **SS495A** (31 mV/mT) — same body, but it needs the 5 V
> rail, not 3.3 V.

---

## 9. Weight budget (target ≤ 750 g)

| Item | Est. mass (g) | Notes |
|---|---|---|
| Acrylic chassis | 60 | 95 × 205 × 3 mm, less cut-outs |
| 2× gear motors | 60 | existing |
| 2× wheels + tyres | 60 | existing |
| End skids / caster | 10 | existing + printed Hall-pod skid |
| 4× AA + holder | 107 | **kit** (do not order) |
| Metro M0 + WiFi shield | 40 | existing |
| Motor-driver module | 10 | kit |
| Wiring / headers / connectors | 35 | |
| 3× populated sensor perfboards | 36 | IR, radio, ultrasound front-ends |
| Sensor elements (SFH300, MA40S4R, SS49E) | 5 | |
| Antenna coil (enamelled wire) | 15 | hand-wound |
| **3D-printed PLA mounts** (boom, 4 housings, tray, 3 carriers) | **~50** | 25 % infill — see below |
| Nylon fasteners / standoffs | 15 | |
| **Total** | **≈ 503 g** | **~247 g margin** |

Comfortable margin, **but track it on a kitchen scale every time a part is
added** — the estimate has ±15 % in it. The printed PLA total is the easiest
lever: 25 % infill and the lightening holes already modelled keep it near 50 g.

---

## 10. Keep-out / interference zones

- **Motor magnet zone** (centre, under the chassis): keep the **Hall sensor**
  out of it — hence the front boom tip. Re-check by reading the Hall with motors
  running and no rock: it must stay near mid-rail.
- **Wheel sweep** (sides at y 96–114): nothing may protrude into the wheel wells
  below deck height.
- **PWM / brush noise** (motors + driver PCB, centre): route the radio and IR
  analogue lines away from it; do their analogue processing on the boom and send
  only clean digital/low-impedance signals back.
- **WiFi shield** (rear): the 89 kHz coil won't disturb 2.4 GHz, but keep the
  coil and its high-gain amp physically away from the digital boards anyway.

---

## 11. Assembly order

1. Bolt the **antenna bobbin** low at the front-centre; wind & tune the coil
   (LCR bridge) before anything blocks access.
2. Bolt the **sensor boom** to the y = 95 holes on short standoffs.
3. Clip the **IR shroud**, **ultrasound clamp** and **Hall pod** onto the boom
   docks; the Hall pod sets the front skid height (lowest point).
4. Mount each sensor's **perfboard carrier** (boom or central deck), keeping
   weak-signal leads short.
5. Fit the **battery tray** on ~25 mm standoffs at y = 85 / 129, over the axle;
   zip-tie the AA holder in.
6. Confirm the **Metro + WiFi** at the rear is undisturbed; run wiring looms
   down the sides (chassis cable slots), not across the motors.
7. Weigh the rover. Read every sensor with motors **off**, then **on**, and
   confirm none of them drifts past its decision threshold.

---

## 12. To verify on the physical rover (do not skip)

- [ ] Drive axle really is central (wheel wells at y ≈ 105) — if the motors are
  actually at one end, **swap the boom and Metro ends** (the principle holds:
  sensors farthest from motors).
- [ ] Exact battery-holder footprint → set `bat=[L,W]` in `battery_tray.scad`.
- [ ] SFH 300 body height → IR shroud tube length.
- [ ] Hall air-gap vs SS49E sensitivity → SS49E (3.3 V) or SS495A (5 V).
- [ ] All M3 holes accept M3 after kerf.
- [x] **Boom vs antenna clearance** (found and fixed in the 3D assembly): the
  antenna was moved front-LEFT off the boom centre-line and shrunk to a low
  Ø36 × 11 mm former, so the boom now sits low (~12 mm) and the Hall pod (now
  ~30 mm, parametric) reaches near the floor. Confirm the real air-gap on the
  bench and tune `postH` / boom standoff length.
