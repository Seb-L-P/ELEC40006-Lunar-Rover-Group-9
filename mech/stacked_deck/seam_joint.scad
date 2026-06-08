// seam_joint.scad - how the two deck halves join (OVERLAP / half-lap) diagram
//   -D mode="exploded"  -> pulled apart so you see the two ledges
//   -D mode="assembled" -> overlapped, with the 2 screws through
include <../print/common.scad>

DT = 4;
mode = "exploded";
EX  = (mode == "exploded") ? 16 : 0;
SLAB_X = 64; BODY = 20; LAP = 20;
HX = 17.5;

module halfA() {   // front: full body + thin BOTTOM ledge into the overlap
    union() {
        translate([-SLAB_X/2, -(BODY+LAP/2), 0]) cube([SLAB_X, BODY, DT]);
        translate([-SLAB_X/2, -LAP/2, 0])        cube([SLAB_X, LAP, DT/2]);
    }
}
module halfB() {   // rear: full body + thin TOP ledge into the overlap
    union() {
        translate([-SLAB_X/2, LAP/2, 0])         cube([SLAB_X, BODY, DT]);
        translate([-SLAB_X/2, -LAP/2, DT/2])     cube([SLAB_X, LAP, DT/2]);
    }
}
module screw(len) { color("FireBrick") { cylinder(d=5.6,h=2.4,$fn=24); translate([0,0,-len]) cylinder(d=3,h=len,$fn=20); } }

color("Silver")    translate([0, -EX, 0])    halfA();   // slides forward when exploded
color("Gainsboro") translate([0,  EX, EX])   halfB();   // slides back + lifts when exploded
for (sx = [-1,1]) translate([sx*HX, 0, DT + 2*EX]) screw(DT + 2*EX + 3);  // 2 screws clamp the overlap
