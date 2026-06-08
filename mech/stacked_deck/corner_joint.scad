// corner_joint.scad - explains how a pillar attaches the two decks (diagram)
//   -D mode="exploded"  -> parts pulled apart, screws shown
//   -D mode="section"   -> assembled and cut in half, screws visible inside
include <../print/common.scad>

DT = 4;        // deck thickness
PH = 30;       // pillar height (short, for the diagram)
SLAB = 28;     // a small square of deck around the corner hole
mode = "exploded";
EX = (mode == "exploded") ? 16 : 0;    // explosion gap

module deck_slab() {
    difference() {
        translate([-SLAB/2,-SLAB/2,0]) cube([SLAB, SLAB, DT]);
        translate([0,0,-eps]) cylinder(d = M3_CLEAR, h = DT+2*eps, $fn = 24);   // Ø3.4 corner hole
    }
}
module pil() {
    difference() {
        cylinder(d = 10/cos(30), h = PH, $fn = 6);
        translate([0,0,-eps]) cylinder(d = 2.5, h = PH+2*eps, $fn = 24);        // Ø2.5 self-tap pilot
    }
}
module screw_down(len) { color("FireBrick") { cylinder(d=5.6,h=2.4,$fn=24); translate([0,0,-len]) cylinder(d=3,h=len,$fn=20); } }
module screw_up(len)   { color("FireBrick") { translate([0,0,-2.4]) cylinder(d=5.6,h=2.4,$fn=24); cylinder(d=3,h=len,$fn=20); } }

zb = 0;                 // bottom deck base
zp = DT + EX;           // pillar base
ztop = DT + PH + 2*EX;  // top deck base

module build() {
    color("Silver")    translate([0,0,zb])   deck_slab();   // bottom deck
    color("Goldenrod") translate([0,0,zp])   pil();         // pillar
    color("Silver")    translate([0,0,ztop]) deck_slab();   // top deck
    translate([0,0, ztop+DT + EX]) screw_down(DT+12);       // top screw -> down into pillar
    translate([0,0, zb - EX])      screw_up(DT+12);         // bottom screw -> up into pillar
}

if (mode == "section")
    intersection() { build(); translate([-50,-50,-20]) cube([100,50,200]); }   // cut at y=0
else
    build();
