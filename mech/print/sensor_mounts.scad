// ============================================================================
// sensor_mounts.scad - the four bolt-on sensor housings for the boom / chassis
// ----------------------------------------------------------------------------
// Each module shares the standard interface: a flat base with 2x M3 clearance
// holes at DOCK_PITCH (12 mm). Render one at a time, e.g.:
//     openscad -D 'part="ir"'      -o ir_shroud.stl       sensor_mounts.scad
//     openscad -D 'part="us"'      -o ultrasound_clamp.stl sensor_mounts.scad
//     openscad -D 'part="hall"'    -o hall_pod.stl         sensor_mounts.scad
//     openscad -D 'part="antenna"' -o antenna_bobbin.stl   sensor_mounts.scad
//
// All print FLAT (base on the bed, feature pointing up); in use the IR/US/Hall
// parts are flipped so the optics/transducer/Hall face DOWN toward the rock.
// ============================================================================

include <common.scad>

part = "all";   // overridden on the command line with -D

// --- 2x M3 mounting holes through a base, centred on origin -------------------
module base_with_bolts(bx, by, bt, pitch = DOCK_PITCH) {
    difference() {
        translate([-bx/2, -by/2, 0]) cube([bx, by, bt]);
        for (s = [-1,1]) translate([s*pitch/2, 0, -eps])
            cylinder(d = M3_CLEAR, h = bt + 2*eps);
    }
}

// --- IR shroud: light-tight tube around the SFH 300 (5 mm T-1 3/4 body) ------
// Bore Ø6.0 clears the ~5.9 mm package RIM (not just the Ø5.1 lens). 1.5 mm
// wall, 14 mm tall to block side/ambient light. Insert the SFH 300 leads-first
// through the two Ø1.2 holes (2.54 mm pitch); the lens then faces out the open
// end. In use, flip so the open (lens) end faces DOWN at the rock.
module ir_shroud() {
    bx = 20; by = 12; bt = 3; tubeH = 14; boreD = 6.0; odD = boreD + 3.0;
    difference() {
        union() {
            base_with_bolts(bx, by, bt);
            cylinder(d = odD, h = bt + tubeH);
        }
        translate([0,0,bt]) cylinder(d = boreD, h = tubeH + 1);          // body bore (open top)
        for (s = [-1,1]) translate([s*1.27, 0, -eps])                    // 2 leads @ 2.54 mm
            cylinder(d = 1.2, h = bt + 2*eps);
    }
}

// --- Ultrasound clamp: holds the Murata MA40S4R (Ø9.9 body, 7.1 tall) --------
// Open-base tube: the transducer inserts FACE-first from the flange (base) end
// until the active face meets the Ø7 retaining lip; the 2 leads exit the open
// base to the perfboard. Bolt pitch 20 mm clears the Ø13.3 tube. In use, flip
// so the lip (face) end points DOWN at the rock.
module ultrasound_clamp() {
    bx = 28; by = 16; ft = 3; PITCH = 20;
    boreD = US_DIA + 0.2; odD = boreD + 3.2; lip = 7.0;
    boreH = US_H + 0.5; lipT = 1.5; totalH = boreH + lipT;   // ~9.1 mm
    difference() {
        union() {
            translate([-bx/2, -by/2, 0]) cube([bx, by, ft]);   // bolt flange (open centre)
            cylinder(d = odD, h = totalH);                      // tube
        }
        translate([0,0,-eps]) cylinder(d = boreD, h = boreH + eps);   // body bore (open base)
        translate([0,0,boreH]) cylinder(d = lip, h = lipT + eps);     // face aperture / lip
        for (s = [-1,1]) translate([s*PITCH/2, 0, -eps])              // bolt holes
            cylinder(d = M3_CLEAR, h = ft + 2*eps);
    }
}

// --- Hall pod: holds the flat SS49E at the boom tip and reaches toward the
// floor (also the front skid). The post length is THE knob that sets the Hall
// air-gap to the rock magnet - lengthen/shorten postH to suit the boom height.
// Slot 4.5 x 2.1 mm captures the flat package at the tip; flying leads run up
// the 3 lead holes (1.27 mm pitch) to the perfboard.
module hall_pod(postH = 30) {
    bx = 18; by = 12; bt = 3; px = 9; py = 7;
    difference() {
        union() {
            base_with_bolts(bx, by, bt);
            translate([0,0,bt]) linear_extrude(postH) square([px, py], center = true);
        }
        // capture slot, open at the far (tip) end
        translate([-(HALL_W+0.4)/2, -(HALL_T+0.4)/2, bt+postH-6])
            cube([HALL_W+0.4, HALL_T+0.4, 6.1]);
        for (i = [-1,0,1]) translate([i*1.27, 0, -eps])    // lead channels
            cylinder(d = 1.2, h = bt + postH);
    }
}

// --- Antenna bobbin: former for the hand-wound 89 kHz tuned coil -------------
// Low-profile Ø36 former (11 mm tall) so it tucks UNDER the boom and sits
// front-LEFT, off the boom centre-line. Air core (Ø16 bore). Wind enamelled
// copper on the Ø22 core, 7 mm wide (build the turns up radially - there's
// 7 mm of room to the flange). Mount via the 2 ears (~42 mm pitch) or zip-tie.
// Tune turns with the lab LCR bridge.
module antenna_bobbin() {
    coreOD = 22; coreID = 16; flangeOD = 36; flangeT = 2; windW = 7; earL = 12; earW = 12;
    earX = flangeOD/2 + earL/2 - 3;   // -> ~42 mm pitch
    difference() {
        union() {
            cylinder(d = flangeOD, h = flangeT);                              // bottom flange
            cylinder(d = coreOD,   h = flangeT + windW);                      // core
            translate([0,0,flangeT+windW]) cylinder(d = flangeOD, h = flangeT); // top flange
            for (s = [-1,1]) translate([s*earX, 0, 0])
                translate([-earL/2, -earW/2, 0]) cube([earL, earW, flangeT]);
        }
        translate([0,0,-eps]) cylinder(d = coreID, h = 2*flangeT + windW + 2*eps); // air bore
        for (s = [-1,1]) translate([s*earX, 0, -eps]) cylinder(d = M3_CLEAR, h = flangeT + 2*eps);
        // wire lead-out notches in both flanges
        for (z = [0, flangeT+windW])
            translate([coreOD/2 - 1, -1.5, z-eps]) cube([flangeOD/2, 3, flangeT + 2*eps]);
    }
}

// --- render selector ---------------------------------------------------------
if      (part == "ir")      ir_shroud();
else if (part == "us")      ultrasound_clamp();
else if (part == "hall")    hall_pod();
else if (part == "antenna") antenna_bobbin();
else {  // "all" - lay them out for a preview
    translate([-30,0,0]) ir_shroud();
    translate([  0,0,0]) ultrasound_clamp();
    translate([ 30,0,0]) hall_pod();
    translate([  0,50,0]) antenna_bobbin();
}
