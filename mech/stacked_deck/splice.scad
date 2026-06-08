// ============================================================================
// splice.scad - join bar for the two deck halves (print x2 per deck)
// ----------------------------------------------------------------------------
// A flat bar that bolts underneath the seam where deck_half_A meets
// deck_half_B, tying them into one rigid plate. Two per deck (one near each
// side). Drill matching M3 holes in the deck halves to suit, or use it as a
// template. Hole pitch spans the seam.
//   openscad -o splice.stl splice.scad
// ============================================================================

include <../print/common.scad>

BAR_L = 60;   // along the deck length (Y), spans the seam
BAR_W = 18;
BAR_T = 4;
HOLE_DY = 20; // hole pitch across the seam (2 into each half)

module splice() {
    difference() {
        translate([-BAR_W/2, -BAR_L/2, 0]) cube([BAR_W, BAR_L, BAR_T]);
        for (sx = [-1,1], sy = [-1,1])
            translate([sx*5, sy*HOLE_DY/2, -eps]) cylinder(d = M3_CLEAR, h = BAR_T+2*eps, $fn = 24);
    }
}

splice();
