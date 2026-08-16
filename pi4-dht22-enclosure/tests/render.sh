#!/usr/bin/env bash
# Render one part to stl/<part>.stl using the OpenSCAD CLI.
set -euo pipefail
part="${1:?usage: render.sh <part>}"
mkdir -p stl
openscad -o "stl/${part}.stl" -D "part=\"${part}\"" pi4_dht22_enclosure.scad
echo "rendered stl/${part}.stl"
