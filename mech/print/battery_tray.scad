// ============================================================================
// battery_tray.scad - 4xAA holder cradle, mounted over the drive axle
// ----------------------------------------------------------------------------
// Bolts to all four central anchor holes (74 x 34 mm rectangle) on M3 nylon
// standoffs, raising the battery pack above the existing Metro / motor-driver
// PCB. Keeping the heaviest item (~100 g of AA cells) directly over the axle
// (y = 105 mm) balances the centre-pivot rover so both end skids stay light.
//
// The AA holder drops into the walled pocket and is held by a zip-tie through
// the two slots (no glue - lab rules forbid ordering adhesives, and a zip-tie
// lets you swap cells). Default pocket fits a 2x2 AA holder; measure yours and
// override bat=[L,W].
//
// Bolts to the chassis y = 85 and y = 129 hole pairs (the boom takes y = 95).
// Their midpoint y = 107 sits over the drive axle (105). Holes are Ø3.6 to
// absorb the ~1 mm pitch / 0.5 mm x variation between those two hole rows.
//
// Print FLAT, no supports. Footprint ~86 x 56 mm.
// ============================================================================

include <common.scad>

bat       = [58, 32];   // [L, W] of your 4xAA holder footprint - MEASURE and adjust
WALL_H    = 8;          // retaining wall height
FLOOR_T   = 2.5;
BAT_Y_PITCH = 44;       // chassis y = 85 <-> 129
BAT_HOLE  = 3.6;        // oversized clearance for the inter-row tolerance

module battery_tray() {
    L = bat[0] + 2*WALL; W = bat[1] + 2*WALL;
    // floor must reach the 74 x 44 anchor rectangle + margin
    FL = max(L, ANCHOR_PITCH_X + 12);
    FW = max(W, BAT_Y_PITCH + 12);
    difference() {
        union() {
            translate([-FL/2, -FW/2, 0]) cube([FL, FW, FLOOR_T]);          // floor
            // pocket walls
            difference() {
                translate([-L/2, -W/2, 0]) cube([L, W, FLOOR_T + WALL_H]);
                translate([-bat[0]/2, -bat[1]/2, FLOOR_T])
                    cube([bat[0], bat[1], WALL_H + eps]);
            }
        }
        // 4 anchor mounting holes (74 x 44)
        for (sx = [-1,1], sy = [-1,1])
            translate([sx*ANCHOR_PITCH_X/2, sy*BAT_Y_PITCH/2, -eps])
                cylinder(d = BAT_HOLE, h = FLOOR_T + 2*eps);
        // floor lightening + wiring pass-through
        translate([0,0,-eps]) cylinder(d = 16, h = FLOOR_T + 2*eps);
        // zip-tie slots across the pocket floor
        for (sx = [-1,1]) translate([sx*bat[0]/4, 0, -eps])
            translate([-2, -bat[1]/2 - 1, 0]) cube([4, bat[1] + 2, FLOOR_T + 2*eps]);
    }
}

battery_tray();
