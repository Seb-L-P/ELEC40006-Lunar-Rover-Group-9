// ============================================================================
// rover_assembly.scad - full EEELunarRover, assembled (VISUALISATION ONLY)
// ----------------------------------------------------------------------------
// Combines the actual printed parts (boom, sensor housings, battery tray) with
// simple representative blocks for the non-printed items (chassis, wheels,
// motors, battery, motor-driver PCB, Metro + WiFi) so you can see the whole
// layout in 3D. Colours are cosmetic. This is NOT a printable part.
//
//   open in OpenSCAD and press F5      (rotate: drag, zoom: scroll)
//   or: openscad -o rover_assembly.stl rover_assembly.scad
//
// Chassis coordinate frame: x = 0..95 (left-right), y = 0 front .. 205 rear,
// z = 0 floor, up. Matches mech/rover_layout.md.
// ============================================================================

include <common.scad>
use <boom.scad>
use <sensor_mounts.scad>
use <battery_tray.scad>
use <chassis.scad>           // EXACT EEEBug outline, holes & cut-outs from chassis.svg

WHEEL_D = 65; WHEEL_W = 26;
AXLE_Z  = WHEEL_D/2;            // wheel centre height above floor
chZ     = AXLE_Z - CH_T/2;      // chassis bottom z (axle ~ mid-thickness)
deck    = chZ + CH_T;           // chassis top surface

module wheel() { rotate([0,90,0]) cylinder(d = WHEEL_D, h = WHEEL_W, center = true, $fn = 48); }

// ===========================================================================
// chassis (real outline)
color("LightSteelBlue") translate([0,0,chZ]) real_chassis();

// drive wheels at the central axle (y = 105), protruding at the waist
color("DimGray") {
    translate([-2,    105, AXLE_Z]) wheel();
    translate([CH_W+2,105, AXLE_Z]) wheel();
}

// gear motors under the centre
color("Gold") for (x = [20, 75]) translate([x-9, 105-11, chZ-19]) cube([18, 22, 19]);

// motor-driver PCB on the centreline
color("ForestGreen") translate([47.5-25, 81, deck]) cube([50, 58, 1.6]);

// battery tray (printed) over the axle + AA pack block
STAND_BAT = 22;
translate([47.5, 107, deck + STAND_BAT]) color("Khaki") battery_tray();
translate([47.5-29, 107-16, deck + STAND_BAT + 2.5]) color("DarkSlateGray") cube([58, 32, 17]);

// front sensor boom (printed), rotated so its +Y points to the rover front.
// Now LOW (12 mm) - the antenna was moved off the centre line so the boom no
// longer has to bridge over it, which lets the Hall pod reach near the floor.
STAND_BOOM = 12;
boomZ = deck + STAND_BOOM;
translate([47.5, 95, boomZ]) rotate([0,0,180]) color("Orange") boom();

// the three down-facing sensor housings hung under the boom tip
translate([47.5,  -1, boomZ]) rotate([180,0,0]) color("Tomato")       ir_shroud();
translate([47.5, -11, boomZ]) rotate([180,0,0]) color("SteelBlue")    ultrasound_clamp();
translate([47.5, -21, boomZ]) rotate([180,0,0]) color("MediumPurple") hall_pod();

// antenna coil bobbin (printed), front-LEFT, off the boom centre-line, low
translate([17, 42, deck + 2]) color("Sienna") antenna_bobbin();

// Metro M0 + WiFi shield at the rear
color("MidnightBlue") translate([47.5-34, 150, deck]) cube([68, 54, 15]);
