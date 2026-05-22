# IR Sensor Build Guide (MVP)

Step-by-step assembly for the EEELunarRover infrared pulse detector. The circuit
turns 50 us infrared light pulses (~950 nm, arriving as a Poisson stream at
312 or 547 pulses/second) into clean digital pulses the Metro counts.

Build it on a solderless breadboard first. The same wiring transfers to
stripboard once it works.

Signal flow:

```
SFH 300  -->  load resistor  -->  high-pass  -->  x48 amplifier  -->  comparator  -->  Metro D2
(light)       (current->V)        (kill ambient)   (op-amp A)         (op-amp B)        (counts edges)
```

One chip does the work: the MCP6292 is a dual op-amp, so half is the amplifier
(A) and half is the comparator (B).

---

## 1. Parts checklist

Resistors (1/4 W, any tolerance is fine):

- [ ] 1 kohm  x3   (Rc, Rg, Rs)
- [ ] 10 kohm x2   (R4, R5)
- [ ] 47 kohm x1   (Rf)
- [ ] 100 kohm x3  (R1, R2, Rt1)
- [ ] 120 kohm x1  (Rt2)
- [ ] 1 Mohm x1    (Rhys)

Capacitors:

- [ ] 1 uF x1      (C1, Vref bypass; electrolytic is fine, watch polarity)
- [ ] 10 nF x1     (C2, AC coupling)
- [ ] 100 nF x1    (C_dec, supply decoupling)

Active parts:

- [ ] SFH 300 phototransistor x1
- [ ] MCP6292 dual op-amp x1 (8-pin DIP for breadboard)

Other:

- [ ] Breadboard + jumper wires
- [ ] 3 male-to-male jumpers to the Metro (3V3, GND, D2)

Tools:

- [ ] Multimeter (essential for the checks below)
- [ ] An IR remote control (TV remote) as a test light source
- [ ] Oscilloscope (helpful, not required)

---

## 2. Know your two chips before wiring

### SFH 300 phototransistor leads

It looks like a clear LED with two legs. It is NOT symmetric, so get this right:

- **Collector = the SHORTER lead** (the datasheet marks the collector side).
- **Emitter = the LONGER lead.**

Sanity check with a multimeter in diode mode in the dark: it should read open
both ways (a phototransistor has no simple diode drop like an LED). If unsure,
the circuit below fails safe: a swapped device just will not respond to light,
it will not be damaged at 3.3 V.

### MCP6292 pinout (looking down, notch to the left)

```
        +--\/--+
 OUTA  1|      |8  V+  (3V3)
 INA-  2|      |7  OUTB
 INA+  3|      |6  INB-
 GND   4|      |5  INB+
        +------+
```

- Op-amp A = pins 1 (out), 2 (in-), 3 (in+)
- Op-amp B = pins 7 (out), 6 (in-), 5 (in+)
- Power = pin 8 (3V3), pin 4 (GND)

---

## 3. Build it in five stages

Do the checks. Each stage builds on the last, so a 2-minute measurement now
saves an hour of hunting later.

### Stage 1: Power and reference voltage

1. Connect the breadboard top rail to Metro **3V3** and the bottom rail to
   Metro **GND**. Leave the Metro USB unplugged for now, or use its 3V3 with
   the rover off.
2. Place the MCP6292 across the centre gap. Wire **pin 8 to 3V3** and
   **pin 4 to GND**.
3. Put the **100 nF (C_dec)** straight across pin 8 and pin 4, as close to the
   chip as possible.
4. Build the Vref divider: **R1 (100k) from 3V3 to a spare row**, then
   **R2 (100k) from that row to GND**. Call that row **VREF**.
5. Add **C1 (1 uF) from VREF to GND** (if electrolytic, the negative stripe
   goes to GND).

**Check:** power on. Measure VREF. You want **1.5 to 1.8 V** (nominally 1.65).
If it reads 0 or 3.3, one of R1/R2 is in the wrong place.

### Stage 2: Phototransistor front end

1. **Collector (short lead) to 3V3.**
2. **Emitter (long lead) to a spare row.** Call that row **EMIT**.
3. **Rc (1k) from EMIT to GND.**

**Check:** measure EMIT in normal room light. It should sit near **0 V in the
dark** and rise a little under bright light or sunlight. Now point a TV remote
at the SFH 300 and hold a button: EMIT should twitch upward. A multimeter is
too slow to see single pulses, so even a small wobble confirms it senses IR.
(Tip: phone cameras can see IR. Point the remote at your phone camera to
confirm the remote actually emits.)

### Stage 3: Amplifier (op-amp A, gain x48)

1. **C2 (10 nF) from EMIT to a new row.** Call it **NA** (node A input).
2. **R4 (10k) from NA to VREF.** (C2 and R4 together block DC ambient and mains,
   passing only the fast pulse.)
3. **NA to pin 3** (INA+).
4. **Rg (1k) from pin 2 (INA-) to VREF.**
5. **Rf (47k) from pin 2 (INA-) to pin 1 (OUTA).**

**Check:** measure **pin 1 (OUTA)**. With no IR it should rest at **about VREF
(~1.65 V)**. If it is slammed to 0 or 3.3 V, recheck Rf/Rg and that pin 3 goes
to NA not VREF.

### Stage 4: Comparator (op-amp B)

1. Build the threshold divider: **Rt1 (100k) from 3V3 to a spare row**, then
   **Rt2 (120k) from that row to GND**. Call it **VTH**.
2. **VTH to pin 6** (INB-).
3. **R5 (10k) from pin 1 (OUTA) to pin 5** (INB+).
4. **Rhys (1M) from pin 7 (OUTB) to pin 5** (INB+). This gives the comparator
   hysteresis so it clicks once per pulse, not many times.

**Check:** measure **VTH**, you want about **1.8 V**. Then measure **pin 7
(OUTB)** with no IR: it should sit **LOW (near 0 V)**, because OUTA (1.65) is
below VTH (1.8). Point the remote at the sensor: OUTB should jump toward 3.3 V
on each burst (on a meter you will see the average lift off 0; on a scope you
will see clean pulses).

### Stage 5: Output to the Metro

1. **Rs (1k) from pin 7 (OUTB) to Metro pin D2.** The series resistor protects
   the GPIO.

That is the whole circuit.

---

## 4. Expected voltages (no IR, normal light)

| Node | Expected |
| --- | --- |
| 3V3 rail | 3.3 V |
| VREF | ~1.65 V |
| EMIT | ~0 V dark, a bit higher in light |
| OUTA (pin 1) | ~1.65 V |
| VTH | ~1.8 V |
| OUTB (pin 7) | ~0 V (LOW) |

If every row matches, the circuit is ready.

---

## 5. First real test

1. Wire the Metro: breadboard 3V3/GND to Metro 3V3/GND, OUTB through Rs to D2.
2. Flash the firmware with the IR counter on D2 (see `../rover_firmware`).
   Quick version:

   ```cpp
   volatile unsigned long irCount = 0;
   void setup() { pinMode(2, INPUT); attachInterrupt(digitalPinToInterrupt(2),
                  []{ irCount++; }, RISING); }
   ```
3. Point an IR remote at the sensor and hold a button. `irCount` should climb.
   No remote handy? Any 950 nm IR LED pulsed by a signal generator works.

When the real rock IR source is available, the count over a 600 ms window
divided by 0.6 gives the rate. 312 vs 547 sit far apart, so you do not need
precise calibration, only a reliable count.

---

## 6. Two tuning knobs

You only ever touch these two things:

| Symptom | Fix |
| --- | --- |
| No counts at all | Move the IR source closer. If still nothing, raise **Rf** from 47k to 100k for more gain. |
| Counts on noise, or several counts per pulse | Raise the threshold: lower **Rt2** (try 100k) so VTH climbs. Or lower **R5** (try 4.7k) for more hysteresis. |

---

## 7. Troubleshooting

| Problem | Likely cause |
| --- | --- |
| VREF not ~1.65 V | R1 or R2 misplaced, or C1 shorted/backwards |
| OUTA stuck at 0 or 3.3 V | Rf/Rg wrong, or pin 3 wired to VREF instead of NA |
| OUTB always HIGH | VTH too low (check Rt1/Rt2), or OUTA offset too high |
| OUTB always LOW even with remote | sensor leads swapped (collector/emitter), or C2 open |
| Triggers off room lights | high-pass not working: check C2 (10 nF) and R4 (10k) are present |
| Random counts with no IR | add the 100 nF decoupling cap if missing; keep wires short |

---

## Notes

- Run the whole circuit from **3.3 V** so the comparator output never exceeds
  the Metro's 3.3 V logic. Do not power it from 5 V.
- Pin **D2** is the suggested counter input. It is interrupt-capable and does
  not clash with the WiFi shield (pins 5, 7, 10) or the radio UART (pin 0).
  Update `pin_map.md` once confirmed.
- Total added weight is a few grams, negligible against the 750 g limit.
</content>
