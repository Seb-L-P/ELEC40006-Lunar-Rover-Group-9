#!/usr/bin/env bash
# Render every printable part to STL. Run from this directory in a normal
# terminal (OpenSCAD's headless export works there):
#     ./render.sh
# Requires OpenSCAD on PATH (brew install --cask openscad).
set -euo pipefail
OS="${OPENSCAD:-openscad}"
mkdir -p stl

"$OS" -o stl/boom.stl                      boom.scad
"$OS" -o stl/perfboard_carrier_small.stl   perfboard_carrier.scad
"$OS" -o stl/perfboard_carrier_large.stl   -D 'board=PB_LARGE' perfboard_carrier.scad
"$OS" -o stl/battery_tray.stl              battery_tray.scad
"$OS" -o stl/ir_shroud.stl                 -D 'part="ir"'      sensor_mounts.scad
"$OS" -o stl/ultrasound_clamp.stl          -D 'part="us"'      sensor_mounts.scad
"$OS" -o stl/hall_pod.stl                  -D 'part="hall"'    sensor_mounts.scad
"$OS" -o stl/antenna_bobbin.stl            -D 'part="antenna"' sensor_mounts.scad

echo "Rendered STLs:"
ls -la stl/
