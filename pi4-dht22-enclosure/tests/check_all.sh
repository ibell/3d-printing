#!/usr/bin/env bash
# Render every printable part and gate it on geometry: watertight, bottom face
# on the bed (min z = 0, tight tol) and the expected bounding box (loose tol).
# Exits non-zero if any part fails, so a below-bed / wrong-size regression is
# caught in CI. Run from the project root.
set -uo pipefail
cd "$(dirname "$0")/.."

here="$(dirname "$0")"

# part            bbox_x  bbox_y  bbox_z  bbox_tol
parts=(
  "sensor_gauge   22.0    17.3    9.15    2.0"
  "arm            106.0   17.3    12.15   2.0"
  "tray           88.6    68.8    12.2    2.0"
  "lid            91.2    62.2    25.4    3.0"
  "fit_coupon     32.0    28.0    12.0    2.0"
  "socket_gauge   22.4    10.0    12.4    2.0"
)

fail=0
for row in "${parts[@]}"; do
  read -r part bx by bz btol <<<"$row"
  echo "== $part =="
  bash "$here/render.sh" "$part" >/dev/null 2>&1 || { echo "FAIL: render $part"; fail=1; continue; }
  # gate 1: watertight + bottom face on the bed (min z = 0, tight tol)
  python3 "$here/check_geom.py" "stl/${part}.stl" --watertight --min-z 0 --tol 0.05 \
    || fail=1
  # gate 2: expected bounding box (loose tol)
  python3 "$here/check_geom.py" "stl/${part}.stl" --bbox "$bx" "$by" "$bz" --tol "$btol" \
    || fail=1
done

# gate 3: assembly fit. Per-part geometry can be perfect while the parts still
# cannot go together -- see tests/check_fit.py for the socket bug that motivated
# this. Also catches unsupported overhangs.
echo "== assembly fit =="
python3 "$here/check_fit.py" || fail=1

if [ "$fail" -ne 0 ]; then
  echo "SUITE FAIL"
  exit 1
fi
echo "SUITE PASS"
