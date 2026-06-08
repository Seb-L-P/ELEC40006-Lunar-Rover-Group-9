// ============================================================================
// deck.scad - a rectangular deck plate matching the EEEBug board (same holes)
// ----------------------------------------------------------------------------
// Rounded rectangle 204 x 95 mm carrying the EXACT hole + slot pattern from the
// acrylic chassis, plus 4 corner holes for the stacking pillars. Two identical
// decks stack on the pillars, so either board can be the top one.
//
// 204 mm is longer than the printer, so it prints in TWO halves that OVERLAP
// (a half-lap joint): the front half ends in a thin bottom ledge, the rear half
// in a thin top ledge; they overlap and 2 M3 screws clamp them into one flush
// deck - no separate splice part.
//   openscad -o deck_full.stl  deck.scad                 (whole deck, for viewing)
//   openscad -o deck_half_A.stl -D 'part="A"' deck.scad  (front half + bottom ledge)
//   openscad -o deck_half_B.stl -D 'part="B"' deck.scad  (rear half + top ledge)
//   -> print half B upside-down so its ledge is on the bed (it's a flat plate
//      with through-holes, so flipping changes nothing else).
// ============================================================================

include <../print/common.scad>

DECK_L = 204;   // length (Y)
DECK_W = 95;    // width  (X)
DECK_T = 4;     // plate thickness
CORNER = 6;
CUT_Y  = 112;   // seam centre
LAP    = 20;    // overlap length of the half-lap

// Front pillars at y=24 to clear the motor-slot cut-outs (y 3.5-16.5); rear at y=192.
PILLAR_HOLES     = [[12,24],[83,24],[12,192],[83,192]];
COIL_MOUNT_HOLES = [[40,179],[55,179],[40,197],[55,197]];
LAP_HOLES        = [[30,CUT_Y],[65,CUT_Y]];   // 2 screws clamp the overlap

HOLES = [[47.5,200,4],[22,189.8,7.8],[79.3,160,3.1],[79.3,187.9,3.1],
         [28.5,144.8,3.1],[17,151.8,4],[26.9,193.3,3.1],[11.8,29.8,3.1],
         [83.3,66.3,3.1],[10.5,95,3.1],[84.5,95,3.1],[84.5,129,3.1],
         [10.5,129,3.1],[17,163.8,4],[47.5,138.7,2.6],[47.5,81.3,2.6],
         [10,85,3.1],[85,85,3.1],[4.8,140.8,5.3]];
CUTS = [[7.7,3.5,29.6,13],[57.7,3.5,29.6,13],[8.5,99.5,6,10],
        [80.5,99.5,6,10],[8.5,114.5,6,10],[17.5,123,30,8]];

part = "full";

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
module box(y0, y1, z0 = -1, z1 = DECK_T+1) { translate([-1, y0, z0]) cube([DECK_W+2, y1-y0, z1-z0]); }

module deck_half(side) {
    o0 = CUT_Y - LAP/2; o1 = CUT_Y + LAP/2;
    difference() {
        if (side == "A")
            union() {
                intersection() { deck_full(); box(-1, o0); }                       // full front
                intersection() { deck_full(); box(o0, o1, -1, DECK_T/2); }         // bottom ledge
            }
        else
            union() {
                intersection() { deck_full(); box(o1, DECK_L+1); }                 // full rear
                intersection() { deck_full(); box(o0, o1, DECK_T/2, DECK_T+1); }   // top ledge
            }
        for (p = LAP_HOLES) translate([p[0],p[1],-eps]) cylinder(d = M3_CLEAR, h = DECK_T+2*eps, $fn = 24);
    }
}

if      (part == "A") deck_half("A");
else if (part == "B") deck_half("B");
else                  deck_full();
