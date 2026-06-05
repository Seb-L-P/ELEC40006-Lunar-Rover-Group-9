# Bill of materials — EEELunarRover sensor build

Parts to order for the sensor subsystems and the printed-mount hardware, mapped
to the **allowed EEE Stores suppliers** (RS, OneCall/Farnell, CPC, Rapid).
Ordering goes through one nominated approver on the
[EEE Stores order form](https://www.imperial.ac.uk/electrical-engineering/internal/stores/).

> **Prices are estimates.** Every RS/Farnell/CPC/Rapid product page blocks
> automated price scraping, so the figures below are indicative — **the approver
> must read the live price on the order form before submitting.** Order codes
> and dimensions are datasheet/catalogue-verified.

## Ordering rules honoured (from `doc/README.md`)
- ❌ **No batteries** — the 4×AA cells are in the kit; batteries are a forbidden order line.
- ❌ **No glue / chemicals** — parts are retained by **screws and zip-ties**, not adhesive.
- ❌ **No tools / mains equipment.**
- ✅ **Through-hole only** — every active part below is leaded/DIP, no surface-mount.
- ✅ **Check stock** before ordering (avoid months-long back-orders).
- The **magnet** is in the kit. The **Metro, WiFi shield, motor driver, breadboard** are in the kit.

---

## Group A — specialist parts (order from RS / Farnell / CPC / Rapid)

These are the budget-critical sensor parts. Buy a spare of the small/cheap ones.

| # | Part | For | Supplier | Order code | Qty | Unit (est) | Line (est) | Key dims |
|---|---|---|---|---|---|---|---|---|
| 1 | Murata **MA40S4R** 40 kHz Rx | ultrasound | CPC (or Farnell 1777668) | **SN36522** | 2 | £2.50 | £5.00 | Ø9.9 × 7.1 mm, 5.0 mm leads |
| 2 | Honeywell **SS49E** Hall | magnetic | RS (or Farnell 1225624) | **236-2760** | 2 | £1.50 | £3.00 | 4.1 × 1.7 × 3.0 mm, 2.7–6.5 V |
| 3 | OSRAM **SFH 300** phototransistor | infrared | Farnell (or RS 654-8031) | **2981724** | 2 | £0.60 | £1.20 | 5 mm T-1¾, Ø5.1 mm |
| 4 | Microchip **MCP6292-E/P** dual op-amp | IR/radio/US front-ends | Farnell | **1439466** | 3 | £1.00 | £3.00 | **PDIP-8**, RRIO, 10 MHz/7 V/µs |
| 5 | Roth **RE016-LF** perfboard | large sensor board (cut in 2) | RS | **897-1402** | 1 | £3.39 | £3.39 | 68.58 × 67.94 × 1.5 mm |
| 6 | Roth **RE015-LF** perfboard | small sensor boards | RS | **897-1408** | 2 | £1.63 | £3.26 | 40.5 × 40 × 1.5 mm |
| | | | | | | **Subtotal A** | **≈ £18.85** | |

Notes:
- **MCP6292 in DIP is real** — the through-hole part is the **-E/P** suffix
  (the SOIC/MSOP variants are -E/SN, -E/MS; do **not** order those). The team's
  "8-pin DIP" assumption is correct. One part covers the 547 Hz IR stage and the
  89 kHz radio precision-rectifier/comparator stage (10 MHz, 7 V/µs).
- **Hall choice:** SS49E runs natively at 3.3 V (~14 mV/mT). If the air-gap to
  the rock magnet turns out large, switch to **SS495A** (RS 216-6231, ~31 mV/mT)
  — same body, but it needs the **5 V** rail.
- Ultrasound is presence-only, so a **receiver alone** is enough (no Tx). If you
  later want an active ping, add MA40S4S (CPC SN36521).
- Four sensor circuits need 4 board areas: one RE016 cut in half + two RE015 = 4.

## Group B — commodity parts (try EED Stores dept stock FIRST, then order)

Fasteners, passives, headers and magnet wire are usually held as **EED Stores
department stock** (collect same-day, little/no budget hit). Only place a
supplier order for whatever the department doesn't stock.

| # | Part | For | Supplier | Order code | Qty | Unit (est) | Line (est) |
|---|---|---|---|---|---|---|---|
| 7 | M3 nylon hex standoff, M-F, 15 mm (pk 100) | mount boom/tray (light) | Rapid | **52-4352** | 1 | £7.63 | £7.63 |
| 8 | M3 steel pan screw, 6 mm (pk 100) | board & module screws | Rapid | **33-7089** | 1 | £4.59 | £4.59 |
| 9 | M3 steel hex nut (pk 100) | lock standoffs to chassis | Rapid | **33-7173** | 1 | £3.89 | £3.89 |
| 10 | Enamelled copper wire 0.28 mm, solderable | 89 kHz antenna coil | RS | **779-0700** | 1 | £8–12 | £10.00 |
| 11 | 0.1″ pin headers + M-M jumper leads | inter-board wiring | CPC / dept stock | — | — | £3.00 | £3.00 |
| 12 | Resistors + capacitors (IR/radio/US front-ends) | front-ends | dept stock / lab kit | — | — | £3.00 | £3.00 |
| | | | | | | **Subtotal B** | **≈ £32.11** |

Notes:
- **Magnet wire** (item 10) is the biggest single line — check EED Stores dept
  stock first; 0.28 mm enamelled wire is a common stock item and would free ~£10.
- Nylon standoffs save weight vs steel (750 g limit). Confirmed M3 nylon hex
  across-flats = **5.4–5.6 mm** (the printed parts clear 5.8 mm). A confirmed
  pan-head **nylon** M3 screw wasn't found at an allowed supplier — steel M3×6
  (item 8) is the safe choice; the few grams are negligible.
- Zip-ties retain the battery holder and Hall sensor (no glue). Add a small pack
  if not in dept stock.

---

## Budget summary

| Scenario | Spend | vs £55 |
|---|---|---|
| Everything ordered from suppliers (A + B) | **≈ £51** | under, ~£4 headroom |
| Group B mostly from EED Stores dept stock | **≈ £20–25** | comfortable |

**Stay under £55 by drawing fasteners, passives, headers and (ideally) the
magnet wire from EED Stores department stock**, and reserving the supplier
budget for the specialist sensor parts in Group A. Re-confirm every price on the
order form — the figures here are estimates pending the bot-blocked live pages.

## Already in the kit (do **not** order)
4×AA cells · 2× magnet · Metro M0 · WINC1500 WiFi shield · H-bridge motor driver
· breadboard · USB cables · rock simulator.
