// ============================================================================
// common.scad - shared parameters and helpers for EEELunarRover printed parts
// ----------------------------------------------------------------------------
// Units: millimetres. Every dimension below is taken either from the EEEBug
// V3.1 laser-cut CAD (mech/chassis.svg, measured) or from a verified component
// datasheet (see mech/rover_layout.md section "Verified part dimensions").
//
// Printer envelope: 200 x 200 x 200 mm PLA. We deliberately keep every part
// under 180 mm in its longest axis (lab guidance: do not use the full bed).
// ============================================================================

$fn = 60;
eps = 0.05;

// ---------- Fasteners (verified: M3 nylon hex A/F measured 5.4-5.6 mm) -------
M3_CLEAR  = 3.4;   // clearance for an M3 screw / standoff thread
M3_TAP    = 2.9;   // pilot for self-tapping an M3 into PLA
M3_HEAD   = 6.2;   // M3 pan-head clearance diameter
M3_HEXAF  = 5.8;   // nylon M3 hex standoff/nut across-flats + fit clearance
WALL      = 2.0;   // default wall (5 perimeters @ 0.4 mm nozzle)

// ---------- Chassis: EEEBug V3.1 (from mech/chassis.svg) ---------------------
CH_W   = 95.0;     // chassis width  (X)
CH_L   = 205.0;    // chassis length (Y)
CH_T   = 3.0;      // 3 mm acrylic
AXLE_Y = 105.0;    // drive-wheel centreline (waist pinches 95->85 mm, y 96-114)

// Central M3 anchor rectangle straddling the axle (chassis coords, Ø3.1 holes):
//   (10.5, 95) (84.5, 95) (10.5, 129) (84.5, 129)  ->  74 mm (X) x 34 mm (Y)
ANCHOR_PITCH_X = 74.0;
ANCHOR_PITCH_Y = 34.0;

// Standard modular interface: every small sensor mount bolts on with
// 2x M3 at this pitch.
DOCK_PITCH = 12.0;

// ---------- Verified component dimensions ------------------------------------
// OSRAM SFH 300 phototransistor: 5 mm T-1 3/4 radial, body Ø5.1, ~8.6 tall,
//   leads 2.54 mm pitch.
SFH300_DIA = 5.1;
// Murata MA40S4R 40 kHz ultrasonic Rx: body Ø9.9, 7.1 tall, leads 5.0 mm pitch.
US_DIA   = 9.9;
US_H     = 7.1;
US_PITCH = 5.0;
// Honeywell SS49E linear Hall: flat package 4.1 (W) x 1.7 (thk) x 3.0 (H),
//   3 leads at 1.27 mm pitch.
HALL_W = 4.1;
HALL_T = 1.7;
HALL_H = 3.0;
// Roth perfboards (FR4, 1.5 mm): RE015 = 40.5 x 40.0 ; RE016 = 68.58 x 67.94.
PB_SMALL = [40.5, 40.0, 1.5];
PB_LARGE = [68.58, 67.94, 1.5];

// ---------- helpers ----------------------------------------------------------
module m3_clear(h = 30) { translate([0,0,-eps]) cylinder(d = M3_CLEAR, h = h + 2*eps); }
module m3_tap(h = 30)   { translate([0,0,-eps]) cylinder(d = M3_TAP,   h = h + 2*eps); }
module hexAF(af, h)     { cylinder(r = af/sqrt(3), h = h, $fn = 6); }

// 2x M3 clearance holes at DOCK_PITCH, centred on the origin along X.
module dock_holes(h = 30) {
    for (s = [-1, 1]) translate([s*DOCK_PITCH/2, 0, 0]) m3_clear(h);
}
