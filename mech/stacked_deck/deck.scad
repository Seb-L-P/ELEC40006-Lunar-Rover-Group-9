// ============================================================================
// deck.scad - a rectangular deck plate matching the EEEBug board (same holes)
// ----------------------------------------------------------------------------
// Rounded rectangle 204 x 95 mm carrying the EXACT hole + slot pattern from the
// acrylic chassis (so existing boards/components bolt straight on), plus 4
// corner holes for the stacking pillars. Two identical decks stack on the
// pillars, so either board can be the top one.
//
// 204 mm is longer than the printer's safe zone, so it prints in TWO halves:
//   openscad -o deck_full.stl  deck.scad                 (whole deck, for viewing)
//   openscad -o deck_half_A.stl -D 'part="A"' deck.scad  (front half, ~112 mm)
//   openscad -o deck_half_B.stl -D 'part="B"' deck.scad  (rear half,  ~92 mm)
// The halves butt at y = 112 and are joined by the splice bar (splice.scad).
// ============================================================================

include <../print/common.scad>

DECK_L = 204;   // length (Y) - matches the ~20 cm board
DECK_W = 95;    // width  (X) - matches the 9.5 cm board
DECK_T = 4;     // plate thickness
CORNER = 6;     // corner radius
CUT_Y  = 112;   // where the two print-halves split

// Pillar holes near the 4 corners (added; not on the original board).
PILLAR_HOLES = [[12,12],[83,12],[12,192],[83,192]];
// Coil-support foot holes near the rear edge (added) - 4x M3 at +/-7.5, +/-9
// about (47.5, 188), matching coil_support.scad's foot.
COIL_MOUNT_HOLES = [[40,179],[55,179],[40,197],[55,197]];

// Exact holes from chassis.svg  [x, y, dia]
HOLES = [[47.5,200,4],[22,189.8,7.8],[79.3,160,3.1],[79.3,187.9,3.1],
         [28.5,144.8,3.1],[17,151.8,4],[26.9,193.3,3.1],[11.8,29.8,3.1],
         [83.3,66.3,3.1],[10.5,95,3.1],[84.5,95,3.1],[84.5,129,3.1],
         [10.5,129,3.1],[17,163.8,4],[47.5,138.7,2.6],[47.5,81.3,2.6],
         [10,85,3.1],[85,85,3.1],[4.8,140.8,5.3]];
// Exact rectangular cut-outs  [x, y, w, h]
CUTS = [[7.7,3.5,29.6,13],[57.7,3.5,29.6,13],[8.5,99.5,6,10],
        [80.5,99.5,6,10],[8.5,114.5,6,10],[17.5,123,30,8]];

part = "full";   // overridden with -D: "full" | "A" | "B"

module rrect(w, l, r, t) {
    linear_extrude(t) hull()
        for (x = [r, w-r], y = [r, l-r]) translate([x, y]) circle(r = r, $fn = 32);
}

module deck_full() {
    difference() {
        rrect(DECK_W, DECK_L, CORNER, DECK_T);
        for (h = HOLES) translate([h[0],h[1],-eps]) cylinder(d = h[2]+0.3, h = DECK_T+2*eps, $fn = 24);
        for (c = CUTS)  translate([c[0],c[1],-eps]) cube([c[2], c[3], DECK_T+2*eps]);
        for (p = PILLAR_HOLES)     translate([p[0],p[1],-eps]) cylinder(d = M3_CLEAR, h = DECK_T+2*eps, $fn = 24);
        for (p = COIL_MOUNT_HOLES) translate([p[0],p[1],-eps]) cylinder(d = M3_CLEAR, h = DECK_T+2*eps, $fn = 24);
    }
}

if (part == "A")
    intersection() { deck_full(); translate([-1,-1,-1]) cube([DECK_W+2, CUT_Y+1, DECK_T+2]); }
else if (part == "B")
    intersection() { deck_full(); translate([-1,CUT_Y,-1]) cube([DECK_W+2, DECK_L-CUT_Y+1, DECK_T+2]); }
else
    deck_full();
