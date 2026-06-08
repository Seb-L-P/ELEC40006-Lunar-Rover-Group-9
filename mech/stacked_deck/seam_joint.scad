// seam_joint.scad - how the two deck halves join (diagram)
//   -D mode="exploded"  -> parts pulled apart
//   -D mode="assembled" -> together
// The two halves butt at the seam; a splice bar screws underneath bridging them.
include <../print/common.scad>

DT = 4;
mode = "exploded";
EX  = (mode == "exploded") ? 16 : 0;
SLAB_X = 64; HALF = 22;
GAP = (mode == "exploded") ? 6 : 0.6;
HX = 17.5; HY = 6;

module half(y0) {                         // a slab from y0, length HALF, 2 seam holes
    difference() {
        translate([-SLAB_X/2, y0, 0]) cube([SLAB_X, HALF, DT]);
        for (sx=[-1,1]) translate([sx*HX, (y0<0?-HY:HY), -eps]) cylinder(d=M3_CLEAR, h=DT+2*eps, $fn=24);
    }
}
module splice() {
    difference() {
        translate([-25,-14,0]) cube([50,28,DT]);
        for (sx=[-1,1], sy=[-1,1]) translate([sx*HX, sy*HY, -eps]) cylinder(d=2.5, h=DT+2*eps, $fn=24);
    }
}
module screw(len) { color("FireBrick") { cylinder(d=5.6,h=2.4,$fn=24); translate([0,0,-len]) cylinder(d=3,h=len,$fn=20); } }

color("Silver")    half(-(HALF+GAP/2));                       // half A (front)
color("Gainsboro") half(GAP/2);                              // half B (rear)
color("SteelBlue") translate([0,0,-DT-EX]) splice();         // splice underneath
for (sx=[-1,1], sy=[-1,1])                                    // 4 screws from the top
    translate([sx*HX, sy*HY, DT + 2*EX]) screw(DT + 2*EX + DT + 3);
