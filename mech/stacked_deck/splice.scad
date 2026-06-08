// ============================================================================
// splice.scad - joins the two deck halves into one rigid deck (print x2/deck)
// ----------------------------------------------------------------------------
// Butt the two halves together, then screw this bar UNDER the seam. Its 4 holes
// line up with the deck's SEAM_HOLES (2 in half A, 2 in half B). Short M3 screws
// go down through the deck's Ø3.4 seam holes and self-tap into this bar's Ø2.5
// holes, clamping both halves to the bar. Use 1-2 bars per deck.
//   openscad -o splice.stl splice.scad
// ============================================================================

include <../print/common.scad>

BAR_X = 50;   // across the deck width
BAR_Y = 28;   // along the deck length, spanning the seam
BAR_T = 4;
HX = 17.5;    // hole pitch matching deck SEAM_HOLES (x = 30 & 65, centre 47.5)
HY = 12;      // hole pitch across the seam (y = 106 & 118, centre 112)

module splice() {
    difference() {
        translate([-BAR_X/2, -BAR_Y/2, 0]) cube([BAR_X, BAR_Y, BAR_T]);
        for (sx = [-1,1], sy = [-1,1])
            translate([sx*HX, sy*HY/2, -eps]) cylinder(d = 2.5, h = BAR_T+2*eps, $fn = 24); // self-tap
    }
}

splice();
