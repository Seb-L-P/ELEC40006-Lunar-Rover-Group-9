// ============================================================================
// stack_assembly.scad - the whole stacked-deck design (VISUALISATION)
// ----------------------------------------------------------------------------
// Two identical decks on 4 pillars; the coil support screws onto the lower deck
// and carries the coil ring + the sensor perfboard tray out front. Decks shown
// whole (they print as deck_half_A + deck_half_B).
//   open in OpenSCAD and press F5  (drag = rotate, scroll = zoom)
// ============================================================================

include <../print/common.scad>
use <deck.scad>
use <pillar.scad>
use <coil_support.scad>

DECK_T = 4;
GAP    = 50;                   // ~5 cm between the decks (matches pillar.scad PILLAR_H)
PILLARS = [[12,24],[83,24],[12,192],[83,192]];   // front pillars clear the motor slots
top_z   = DECK_T + GAP;

FOOT_Y  = 188;                 // coil-support foot centre on the deck
RING_CY = FOOT_Y + 59.5;       // ring centre  (matches coil_support.scad)
TRAY_CY = FOOT_Y + 114;        // tray centre
sup_z   = top_z + DECK_T;      // support sits on the UPPER deck (sensors up top)

// --- decks ---
color("WhiteSmoke")            deck_full();                          // lower deck
color("Gainsboro") translate([0,0,top_z]) deck_full();              // upper deck

// --- pillars ---
color("DimGray") for (p = PILLARS) translate([p[0],p[1],DECK_T]) pillar();

// --- coil support screwed onto the lower deck ---
color("Khaki") translate([47.5, FOOT_Y, sup_z]) coil_support();
color("DarkSlateGray") for (sx=[-1,1], sy=[-1,1])                   // 4 mount screws
    translate([47.5+sx*7.5, FOOT_Y+sy*9, sup_z-1]) cylinder(d=5.5, h=3, $fn=24);

// --- coil (~75 mm) in the ring ---
color("Goldenrod") translate([47.5, RING_CY, sup_z+2.5])
    rotate_extrude($fn=64) translate([75/2,0]) circle(d=4, $fn=16);

// --- representative perfboard (60 x 20) + the two down-facing sensors ---
color("SteelBlue") translate([47.5-30, TRAY_CY-10, sup_z+4]) cube([60,20,1.5]);
color("Tomato")      translate([47.5-12, TRAY_CY, sup_z-5]) cylinder(d=9.9, h=9,  $fn=32); // ultrasound (faces down)
color("MediumPurple")translate([47.5+12, TRAY_CY, sup_z-7]) cylinder(d=5,   h=11, $fn=24); // phototransistor (faces down)
