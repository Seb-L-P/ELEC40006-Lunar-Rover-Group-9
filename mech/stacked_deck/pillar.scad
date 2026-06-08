// ============================================================================
// pillar.scad - stacking pillar (print x4)
// ----------------------------------------------------------------------------
// One pillar between the two decks at each corner. Through-hole for an M3
// screw + nut, or self-tap an M3 into each end. Set PILLAR_H to the gap you
// want between the decks (room for the boards/components in between).
//   openscad -o pillar.stl pillar.scad
// ============================================================================

include <../print/common.scad>

PILLAR_D = 10;   // outer diameter
PILLAR_H = 45;   // height = gap between the two decks
FLAT     = true; // hex body (true) prints/grips better; round if false

module pillar() {
    difference() {
        if (FLAT) cylinder(d = PILLAR_D/cos(30), h = PILLAR_H, $fn = 6);
        else      cylinder(d = PILLAR_D, h = PILLAR_H, $fn = 48);
        translate([0,0,-eps]) cylinder(d = M3_CLEAR, h = PILLAR_H+2*eps, $fn = 24);
    }
}

pillar();
