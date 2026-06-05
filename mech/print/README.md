# 3D-printed parts — EEELunarRover

Parametric PLA parts for mounting the four sensor subsystems, the battery, and
the analogue perfboards onto the existing EEEBug V3.1 chassis. Source is
OpenSCAD (`.scad`); STLs are generated with `./render.sh`.

> The design intent, placement, weight budget and the physics behind every
> mounting decision live in [`../rover_layout.md`](../rover_layout.md). Read
> that first. This file is just the print/build mechanics.

## Why 3D-printed and modular

- **Modular** — each sensor subsystem is owned by a different team member. Every
  small mount shares one interface (2× M3 at 12 mm pitch), so a subsystem can be
  built, swapped or re-tuned without touching the others or re-cutting acrylic.
- **Bolts to real holes** — the boom and battery tray bolt to the chassis's
  existing M3 holes (measured from `../chassis.svg`): the four central anchors at
  x = 10.5 / 84.5 mm, y = 95 / 129 mm, which straddle the drive axle (y ≈ 105 mm).
- **Bed margin** — printer envelope is 200 × 200 × 200 mm PLA, but lab guidance
  is *don't use the full bed*. The largest part (the boom) is **86 × 127 mm**,
  comfortably inside a self-imposed 180 mm limit. Everything else is < 60 mm.

## Parts

| File / STL | What it is | Footprint | Key fit dimension |
|---|---|---|---|
| `boom.scad` → `boom.stl` | Front cantilever beam carrying the 3 down-facing sensors | 86 × 127 × 4 mm | anchors 74 mm; docks 12/20/12 mm |
| `sensor_mounts.scad` → `ir_shroud.stl` | Light-tight tube for the SFH 300 | Ø9 × 17 mm | bore **Ø6.0** (clears the 5 mm T-1¾ rim) |
| `sensor_mounts.scad` → `ultrasound_clamp.stl` | Clamp for the Murata MA40S4R | Ø13.3 × 9 mm | bore **Ø10.1** (MA40S4R = Ø9.9) |
| `sensor_mounts.scad` → `hall_pod.stl` | Pod holding the SS49E; reaches to the floor (front skid) | 18 × 12 × 33 mm | slot **4.5 × 2.1**; `postH` = Hall air-gap knob |
| `sensor_mounts.scad` → `antenna_bobbin.stl` | Former for the hand-wound 89 kHz coil (low profile) | Ø36 × 11 mm | core Ø22, 7 mm wind width, ears 42 mm |
| `perfboard_carrier.scad` → `perfboard_carrier_small.stl` | Sled for a Roth RE015 board | 40.5 × 40 mm | board 40.5 × 40, raised 5 mm |
| `perfboard_carrier.scad` → `perfboard_carrier_large.stl` | Sled for a Roth RE016 board | 68.6 × 68 mm | board 68.6 × 68 |
| `battery_tray.scad` → `battery_tray.stl` | Cradle for the 4×AA holder, over the axle | 86 × 46 mm | pocket 58 × 32 (**measure yours**) |

All sensor housings print **base-down, feature pointing up** (no supports). In
use the IR / ultrasound / Hall parts are flipped so the optics / transducer /
Hall face **down** toward the rock.

**Visualisation (not printed):** `chassis.scad` is the exact EEEBug outline
(auto-generated from `../chassis.svg`) and `rover_assembly.scad` combines it
with all the printed parts and representative blocks for the whole rover — open
either and press F5, or see `preview/rover_assembly*.png`.

## Rendering

```bash
cd mech/print
./render.sh            # writes stl/*.stl
```

`render.sh` uses headless `openscad -o`. (Note: it will not run inside a
restricted/sandboxed shell — the macOS OpenSCAD app needs a normal terminal —
but a plain Terminal session renders all eight STLs in a few seconds.)

To change a dimension, edit the variable at the top of the relevant `.scad`
(everything is parametric) or override on the command line, e.g. a bigger
battery pocket:

```bash
openscad -o stl/battery_tray.stl -D 'bat=[62,58]' battery_tray.scad
```

## Suggested print settings (PLA)

| Setting | Value | Why |
|---|---|---|
| Layer height | 0.2 mm | fast, strong enough |
| Perimeters | 4 | the boom is a cantilever — walls carry the load |
| Infill | 25 % | mass matters (750 g rover limit) |
| Supports | none | every part is designed support-free |
| Orientation | as modelled (flat) | best layer adhesion for the boom |

## Before you commit a print

1. **Measure your actual battery holder** and set `bat=[L,W]` in
   `battery_tray.scad`. The 58 × 32 default is a 2×2 AA box guess.
2. **Confirm the SFH 300 body height** with callipers (datasheet drawing was
   ambiguous at ~8.6 mm); lengthen the IR shroud tube if needed.
3. **Verify the chassis anchor holes** on the physical board — laser kerf makes
   internal holes ~0.1–0.2 mm larger than drawn; the Ø3.4 clearances allow for it.
4. **Print one `ir_shroud` first** as a fit test for the M3 clearances and the
   sensor bore before committing the long boom print.
