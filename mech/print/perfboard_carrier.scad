// ============================================================================
// perfboard_carrier.scad - universal sled for a Roth FR4 perfboard
// ----------------------------------------------------------------------------
// Holds one analogue-front-end perfboard 5 mm above its mount surface (lead /
// solder clearance) and bolts onto the central deck or the boom with 2x M3.
// Default size = Roth RE015 (40.5 x 40 mm); set board=PB_LARGE for RE016.
//
// The board is retained by 4 corner bosses tapped for M3 - drill Ø3.2 holes in
// the perfboard 5 mm in from each corner. A large central window saves weight
// and lets leads/solder protrude.
//
// Print FLAT, no supports. Footprint = board + 5 mm.
//   openscad -o perfboard_carrier_small.stl perfboard_carrier.scad
//   openscad -D 'board=PB_LARGE' -o perfboard_carrier_large.stl perfboard_carrier.scad
// ============================================================================

include <common.scad>

board   = PB_SMALL;   // [L, W, thickness]
BASE_T  = 2;          // sled floor thickness
STAND   = 5;          // board stand-off height (lead clearance)
INSET   = 5;          // boss / drill inset from board corner
BOSS_D  = 6.5;

module perfboard_carrier() {
    L = board[0]; W = board[1];
    fx = L/2 - INSET; fy = W/2 - INSET;
    difference() {
        union() {
            // floor
            translate([-L/2, -W/2, 0]) cube([L, W, BASE_T]);
            // corner bosses
            for (sx = [-1,1], sy = [-1,1])
                translate([sx*fx, sy*fy, 0]) cylinder(d = BOSS_D, h = BASE_T + STAND);
        }
        // lightening window
        translate([0,0,-eps])
            translate([-(L/2-INSET-BOSS_D/2-1), -(W/2-INSET-BOSS_D/2-1), 0])
            cube([2*(L/2-INSET-BOSS_D/2-1), 2*(W/2-INSET-BOSS_D/2-1), BASE_T+2*eps]);
        // M3 tap holes in bosses
        for (sx = [-1,1], sy = [-1,1])
            translate([sx*fx, sy*fy, 0]) m3_tap(BASE_T + STAND);
        // 2x M3 mounting holes through the floor, near one edge, DOCK_PITCH apart
        for (s = [-1,1]) translate([s*DOCK_PITCH/2, -(W/2 - INSET), -eps])
            cylinder(d = M3_CLEAR, h = BASE_T + 2*eps);
    }
}

perfboard_carrier();
