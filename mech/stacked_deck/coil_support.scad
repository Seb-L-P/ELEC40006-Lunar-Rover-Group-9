// ============================================================================
// coil_support.scad - coil ring + sensor-perfboard tray, screws to a deck (x1)
// ----------------------------------------------------------------------------
// One printed part:
//   * a FOOT that bolts flat onto a deck with 4x M3 (into the deck's
//     coil-support holes - see deck.scad COIL_MOUNT_HOLES),
//   * a RING that cradles the ~75 mm coil (drops in, retained by a lip),
//   * a TRAY at the far end holding a ~60 x 20 mm perfboard for the ultrasound
//     + phototransistor, with a central cut-out so those sensors face down.
//   openscad -o coil_support.stl coil_support.scad
// ============================================================================

include <../print/common.scad>

// --- coil ring ---
COIL_D  = 75;             // coil outer diameter (set to your real coil: 70-75)
RING_ID = COIL_D + 2;     // 77 slip fit
RING_W  = 7;              // ring radial width
RING_OD = RING_ID + 2*RING_W;
RING_T  = 5;
LIP     = 2.5; LIP_W = 2.5;

// --- foot (deck mount) ---
FOOT_W  = 24; FOOT_L = 28; FOOT_T = 5;
MOUNT_X = 15; MOUNT_Y = 18;   // 4 holes at (+/-7.5, +/-9)

// --- sensor perfboard tray ---
PB_L = 60; PB_W = 20; MARG = 3; LIPB = 2;
TRAY_W = PB_L + 2*MARG; TRAY_D = PB_W + 2*MARG; TRAY_T = 4;

// --- brace: deepens the part so the cantilever doesn't droop ---
H_BRACE = 9;   // height of the stiffening spine + ring rim wall

ring_cy  = FOOT_L/2 + RING_OD/2;        // ring centre (local Y)
ring_far = ring_cy + RING_OD/2;
tray_cy  = ring_far + TRAY_D/2 - 4;     // overlap the ring rim by 4 mm

module coil_support() {
    difference() {
        union() {
            translate([-FOOT_W/2, -FOOT_L/2, 0]) cube([FOOT_W, FOOT_L, FOOT_T]);   // foot
            translate([-9, FOOT_L/2-3, 0]) cube([18, 6, FOOT_T]);                  // foot->ring neck
            translate([0, ring_cy, 0]) cylinder(d = RING_OD, h = RING_T, $fn = 96);          // ring
            translate([0, ring_cy, 0]) cylinder(d = RING_ID+2*LIP_W, h = RING_T+LIP, $fn=96);// lip
            translate([-TRAY_W/2, tray_cy-TRAY_D/2, 0]) cube([TRAY_W, TRAY_D, TRAY_T+LIPB]); // tray
            // --- brace ---
            translate([-3, -FOOT_L/2, 0]) cube([6, FOOT_L, H_BRACE]);          // spine along the foot
            translate([-7, 8, 0]) cube([14, 8, H_BRACE]);                      // foot -> ring bridge
            translate([0, ring_cy, 0]) difference() {                          // raised wall on the ring rim
                cylinder(d = RING_OD, h = H_BRACE, $fn = 96);
                translate([0,0,-eps]) cylinder(d = RING_OD-3, h = H_BRACE+2*eps, $fn = 96);
            }
        }
        translate([0, ring_cy, -eps]) cylinder(d = RING_ID, h = RING_T+LIP+2*eps, $fn = 96); // coil bore
        for (sx=[-1,1], sy=[-1,1])                                                            // 4 foot screws
            translate([sx*MOUNT_X/2, sy*MOUNT_Y/2, -eps]) cylinder(d = M3_CLEAR, h = FOOT_T+2*eps, $fn=24);
        translate([-PB_L/2, tray_cy-PB_W/2, TRAY_T])                                          // board pocket
            cube([PB_L, PB_W, LIPB+eps]);
        translate([-PB_L/2+8, tray_cy-PB_W/2+5, -eps])                                        // sensor see-down cut-out
            cube([PB_L-16, PB_W-10, TRAY_T+LIPB+2*eps]);
        for (s=[-1,1]) translate([s*(PB_L/2-3), tray_cy, -eps]) cylinder(d=M3_CLEAR, h=TRAY_T+2*eps, $fn=24); // board retention
    }
}

coil_support();
