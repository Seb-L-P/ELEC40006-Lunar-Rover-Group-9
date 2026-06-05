// ============================================================================
// boom.scad - front sensor boom for the EEELunarRover
// ----------------------------------------------------------------------------
// A flat PLA beam that bolts to the two central chassis anchor holes on the
// y = 95 mm line (x = 10.5 / 84.5) via M3 nylon standoffs, and cantilevers
// forward over the chassis leading edge. It carries three DOWN-FACING sensor
// modules in a line on the centre line at the leading tip:
//     IR shroud  ->  ultrasound clamp  ->  Hall pod (lowest, doubles as skid)
//
// Local frame: origin at the anchor centre. +Y = rover forward (toward the
// rocks). Printed FLAT on the bed (this part is a plain plate with holes);
// the sensor housings are separate parts that bolt to it pointing down.
//
// Print: flat, 0.2 mm layers, 4 perimeters, 25 % infill. No supports.
// Footprint ~86 x 127 mm  ->  fits the 200 mm bed with margin.
// ============================================================================

include <common.scad>

BOOM_T = 4;   // plate thickness (stiff cantilever)

// Down-facing sensor docks on the centre line: [x, y, bolt_pitch].
// The ultrasound clamp body is Ø13.3 mm, so its bolts must straddle wider.
DOCKS = [[0,  96, 12],    // IR shroud
         [0, 106, 20],    // ultrasound clamp (wide pitch clears the Ø13.3 tube)
         [0, 116, 12]];   // Hall pod (front tip, also the skid)

module boom() {
    // outline: 86 mm anchor crossbar -> 24 mm spine -> 64 mm sensor head
    pts = [[-43,-9], [43,-9], [43,9], [12,9], [12,88],
           [32,88],  [32,120], [-32,120], [-32,88], [-12,88],
           [-12,9],  [-43,9]];
    difference() {
        linear_extrude(BOOM_T) polygon(pts);

        // two anchor holes -> chassis (10.5,95) and (84.5,95), 74 mm apart
        for (s = [-1,1]) translate([s*ANCHOR_PITCH_X/2, 0, -eps])
            cylinder(d = M3_CLEAR, h = BOOM_T + 2*eps);

        // sensor dock hole pairs (per-dock pitch) + central wire pass-through
        for (d = DOCKS) {
            for (s = [-1,1]) translate([d[0] + s*d[2]/2, d[1], -eps])
                cylinder(d = M3_CLEAR, h = BOOM_T + 2*eps);
            translate([d[0], d[1], -eps]) cylinder(d = 6, h = BOOM_T + 2*eps);
        }

        // lightening holes (mass matters: 750 g rover limit)
        for (p = [[-28,0],[28,0],[0,30],[0,62]])
            translate([p[0], p[1], -eps]) cylinder(d = 9, h = BOOM_T + 2*eps);
    }
}

boom();
