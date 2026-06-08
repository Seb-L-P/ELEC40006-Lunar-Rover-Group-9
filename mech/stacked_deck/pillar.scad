// ============================================================================
// pillar.scad - stacking pillar (print x4)
// ----------------------------------------------------------------------------
// One pillar between the two decks at each corner.
//
// HOW IT CONNECTS TO THE DECKS:
//   The pillar has a narrow Ø2.5 mm pilot hole down its centre. At each corner
//   you put a short M3 screw THROUGH the deck's Ø3.4 corner hole and drive it
//   into the pillar end - it self-taps into the Ø2.5 pilot and clamps the deck
//   to the pillar. Two screws per pillar (one through the top deck, one through
//   the bottom deck). Use M3 x 8-10 mm pan-head screws.
//
//   Sturdier alternative: open the pilot to Ø3.4 (set HOLE = M3_CLEAR) and run
//   one length of M3 threaded rod through deck+pillar+deck with a nut each end.
//
// Set PILLAR_H to the gap you want between the decks.
//   openscad -o pillar.stl pillar.scad
// ============================================================================

include <../print/common.scad>

PILLAR_D = 10;      // outer diameter (across flats if hex)
PILLAR_H = 45;      // height = gap between the two decks
HOLE     = 2.5;     // Ø2.5 self-tap pilot (use M3_CLEAR=3.4 for threaded rod)
FLAT     = true;    // hex body (grips better) vs round

module pillar() {
    difference() {
        if (FLAT) cylinder(d = PILLAR_D/cos(30), h = PILLAR_H, $fn = 6);
        else      cylinder(d = PILLAR_D, h = PILLAR_H, $fn = 48);
        translate([0,0,-eps]) cylinder(d = HOLE, h = PILLAR_H + 2*eps, $fn = 24);
        // lead-in chamfers so the screw starts easily at each end
        translate([0,0,-eps])          cylinder(d1 = HOLE+1.5, d2 = HOLE, h = 1.2, $fn = 24);
        translate([0,0,PILLAR_H-1.2])  cylinder(d1 = HOLE, d2 = HOLE+1.5, h = 1.2+eps, $fn = 24);
    }
}

pillar();
