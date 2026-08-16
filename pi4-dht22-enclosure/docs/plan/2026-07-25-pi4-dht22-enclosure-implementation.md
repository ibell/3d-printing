# Pi 4 DHT22 Enclosure — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a single parametric OpenSCAD model that produces a three-part Raspberry Pi 4 desk enclosure (tray + lid) plus a plug-in DHT22 sensor arm, with the sensor pocket ("breakout box") deliverable first.

**Architecture:** One file `pi4_dht22_enclosure.scad` with a `part="…"` dispatcher selecting each printable body. Geometry is built from reusable modules (`standoff`, `sensor_pocket`, `arm`, `tray`, `lid`, plus test parts `sensor_gauge`, `fit_coupon`, and a visual `assembly`). "Tests" are a render-and-check harness: each part is rendered to STL via the OpenSCAD CLI, then checked with trimesh for watertightness / positive volume / bounding box, while precise parametric invariants are enforced by in-model `assert()`s that abort the render on violation.

**Tech Stack:** OpenSCAD 2026.06 (manifold backend), Python 3 + trimesh, bash. PETG print target.

> **Amendment (2026-07-25):** During execution the lid changed from 4 × M3 screws into
> tray corner bosses to a **snap-fit lid** (bosses removed) — the bosses collided with
> the standoffs and fouled the Pi board. Tasks 6-7's screw/boss details below are
> superseded by this change; `pi4_dht22_enclosure.scad` is authoritative.

## Global Constraints

- All work happens in `pi4-dht22-enclosure/` within the repo; paths below are relative to it.
- Single source file: `pi4_dht22_enclosure.scad`. No second `.scad`.
- Every printable part must render **support-free** (vertical walls, chamfered overhangs, bridgeable slots) and be **watertight** with **positive volume**.
- The DHT22 pocket is a **drop-in cavity**, sized `sensor_pcb_w × sensor_pcb_h × sensor_pcb_t` (+ `sensor_slot_fit`), grille facing out, cable exiting the back. Defaults: `sensor_pcb_w=37.0`, `sensor_pcb_h=10.0`, `sensor_pcb_t=10.0`, `sensor_slot_fit=0.2` (verbatim from the spec).
- Only tight-tolerance Pi interface is the **58 × 49 mm** mounting rectangle with **Ø2.2 mm** pilot holes for M2.5; board outline **85 × 56 mm**. Port sides are **open channels** — no per-port cutouts.
- STLs are exported to `stl/` in print orientation (Z up, resting on the bed).
- Task order is fixed by print priority: **sensor pocket first**, then arm, then Pi-side parts.
- Commit after every task. Commit trailer: `Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>`.
- Design record: `docs/design/2026-07-25-pi4-dht22-enclosure-design.md` — the authority on intent.

---

### Task 1: Verification harness + parameter block + part dispatcher

Scaffolding the later tasks depend on: the render helper, the trimesh checker, and the full parameter block with a dispatcher that can render a smoke cube.

**Files:**
- Create: `pi4_dht22_enclosure.scad`
- Create: `tests/render.sh`
- Create: `tests/check_geom.py`

**Interfaces:**
- Produces: CLI `bash tests/render.sh <part>` → writes `stl/<part>.stl`. CLI `python3 tests/check_geom.py <stl> [--bbox X Y Z] [--tol T] [--min-vol V] [--watertight]` → exit 0 pass / 1 fail. SCAD global `part` (string) dispatches to a module per part; unknown parts `echo` a warning. All parameters (below) are top-level SCAD variables consumed by later tasks.

- [ ] **Step 1: Write the render helper**

Create `tests/render.sh`:

```bash
#!/usr/bin/env bash
# Render one part to stl/<part>.stl using the OpenSCAD CLI.
set -euo pipefail
part="${1:?usage: render.sh <part>}"
mkdir -p stl
openscad -o "stl/${part}.stl" -D "part=\"${part}\"" pi4_dht22_enclosure.scad
echo "rendered stl/${part}.stl"
```

- [ ] **Step 2: Write the geometry checker**

Create `tests/check_geom.py`:

```python
#!/usr/bin/env python3
"""Geometry checks for exported STLs (trimesh-based)."""
import argparse
import sys
import trimesh


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("stl")
    ap.add_argument("--bbox", nargs=3, type=float, metavar=("X", "Y", "Z"))
    ap.add_argument("--tol", type=float, default=1.0)
    ap.add_argument("--min-vol", type=float, default=0.0)
    ap.add_argument("--watertight", action="store_true")
    a = ap.parse_args()

    m = trimesh.load(a.stl, force="mesh")
    if m.is_empty or len(m.faces) == 0:
        print(f"FAIL: {a.stl} is empty")
        sys.exit(1)

    ok = True
    vol = m.volume
    if vol <= a.min_vol:
        print(f"FAIL: volume {vol:.1f} <= min {a.min_vol}")
        ok = False
    if a.watertight and not m.is_watertight:
        print("FAIL: not watertight")
        ok = False
    if a.bbox:
        for name, got, exp in zip("XYZ", m.extents, a.bbox):
            if abs(got - exp) > a.tol:
                print(f"FAIL: bbox {name} {got:.2f} != {exp:.2f} (+/-{a.tol})")
                ok = False

    if ok:
        ext = tuple(round(e, 2) for e in m.extents)
        print(f"PASS: {a.stl} vol={vol:.1f} extents={ext}")
        sys.exit(0)
    sys.exit(1)


if __name__ == "__main__":
    main()
```

- [ ] **Step 3: Write the parameter block + dispatcher (smoke part only)**

Create `pi4_dht22_enclosure.scad`:

```openscad
// Raspberry Pi 4 enclosure + DHT22 sensor arm — parametric source.
// Select a body with -D 'part="..."'. See docs/design for rationale.

part = "assembly";   // "sensor_gauge" | "arm" | "tray" | "lid" | "fit_coupon" | "assembly" | "_smoke"
$fn  = 48;

/* ---------- Pi 4 board ---------- */
board_w      = 85.0;   // long edge (X)
board_l      = 56.0;   // short edge (Y)
pcb_t        = 1.4;
hole_dx      = 58.0;   // mount rectangle along X
hole_dy      = 49.0;   // mount rectangle along Y
hole_edge    = 3.5;    // hole-centre inset from board edge
hole_pilot_d = 2.2;    // M2.5 self-tap pilot

/* ---------- shell ---------- */
wall        = 2.0;
floor       = 2.0;
board_fit   = 0.4;
tray_wall_h = 10.0;    // tray wall height above floor
lid_clear   = 20.0;    // internal clear height above board top
lid_wall    = 2.0;
lid_lip     = 4.0;     // lip overlap depth
lid_fit     = 0.3;     // lid-over-tray clearance

/* ---------- standoffs ---------- */
standoff_h  = 5.0;
standoff_od = 6.0;

/* ---------- lid fixing (M3) ---------- */
lid_screw_d = 3.2;     // clearance hole in lid
boss_d      = 7.0;     // tray corner boss OD
boss_pilot  = 2.5;     // M3 self-tap pilot in boss

/* ---------- ventilation ---------- */
vent_slot_w   = 3.0;
vent_slot_len = 24.0;
vent_gap      = 3.0;

/* ---------- microSD notch (SD short edge = x-min) ---------- */
sd_slot_w = 14.0;
sd_slot_h = 4.0;

/* ---------- LED window (USB-C corner) ---------- */
led_win_w = 10.0;
led_win_h = 4.0;

/* ---------- DHT22 cable exit (GPIO long edge = +Y) ---------- */
cable_slot_w = 8.0;
cable_slot_h = 5.0;

/* ---------- sensor arm ---------- */
arm_len      = 80.0;   // clear reach, socket mouth to pocket back
arm_w        = 10.0;
arm_h        = 6.0;
arm_groove_w = 4.0;
arm_groove_d = 2.5;
arm_foot     = true;
foot_len     = 16.0;
foot_h       = 3.0;

/* ---------- arm socket (tray, GPIO side) ---------- */
socket_depth = 10.0;   // tenon length
socket_fit   = 0.4;
setscrew_d   = 3.2;

/* ---------- DHT22 module pocket (drop-in cavity) ---------- */
sensor_pcb_w    = 37.0;   // module width  -> cavity X
sensor_pcb_h    = 10.0;   // drop-in depth -> cavity Z
sensor_pcb_t    = 10.0;   // module thick  -> cavity Y (into front face)
sensor_slot_fit = 0.2;
pocket_wall     = 2.0;
sensor_grille_w = 30.0;   // front airflow window
sensor_grille_h = 7.0;
cable_hole_w    = 8.0;
cable_hole_h    = 4.0;
lip_proud       = 0.8;    // retention lip overhang at mouth

/* ---------- optional ---------- */
wall_mount_tabs = false;

/* ---------- global sanity asserts ---------- */
assert(wall > 0 && floor > 0 && pocket_wall > 0, "thicknesses must be positive");
assert(board_fit >= 0 && sensor_slot_fit >= 0, "fits must be non-negative");

/* ---------- dispatcher ---------- */
if      (part == "_smoke")       cube(10);
else if (part == "sensor_gauge") sensor_gauge();
else if (part == "arm")          arm();
else if (part == "tray")         tray();
else if (part == "lid")          lid();
else if (part == "fit_coupon")   fit_coupon();
else if (part == "assembly")     assembly();
else echo(str("unknown part: ", part));

/* modules added in later tasks */
module sensor_gauge() {}
module arm()          {}
module tray()         {}
module lid()          {}
module fit_coupon()   {}
module assembly()     {}
```

- [ ] **Step 4: Run the smoke render + check (expect PASS)**

Run:
```bash
chmod +x tests/render.sh
bash tests/render.sh _smoke
python3 tests/check_geom.py stl/_smoke.stl --bbox 10 10 10 --tol 0.1 --watertight --min-vol 900
```
Expected: `rendered stl/_smoke.stl` then `PASS: stl/_smoke.stl vol=1000.0 extents=(10.0, 10.0, 10.0)`.

- [ ] **Step 5: Remove the smoke STL and commit**

```bash
rm -f stl/_smoke.stl
git add pi4_dht22_enclosure.scad tests/render.sh tests/check_geom.py
git commit -m "pi4-dht22-enclosure: harness, params, part dispatcher

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

### Task 2: Sensor pocket + `sensor_gauge` (the breakout box — PRINT FIRST)

The first printable deliverable. A drop-in cavity for the DHT22 module; the gauge is the pocket alone so it can be printed and fit-checked before anything else.

**Files:**
- Modify: `pi4_dht22_enclosure.scad` (replace the empty `sensor_gauge()` stub; add `sensor_pocket()`)

**Interfaces:**
- Consumes: parameters `sensor_pcb_*`, `sensor_slot_fit`, `pocket_wall`, `sensor_grille_*`, `cable_hole_*`, `lip_proud`, `floor`.
- Produces: `module sensor_pocket()` — canonical orientation: cavity width along **X**, module thickness along **Y** (grille window in the **+Y** face), drop-in depth along **Z** (mouth open at **+Z**), floor at Z=0, cable hole in the **−Y** face. Outer bbox `= [sensor_pcb_w+sensor_slot_fit+2·pocket_wall, sensor_pcb_t+sensor_slot_fit+2·pocket_wall, sensor_pcb_h+sensor_slot_fit+pocket_wall]`. `module sensor_gauge()` renders `sensor_pocket()` unmodified.

- [ ] **Step 1: Write the failing check (no geometry yet)**

Run:
```bash
bash tests/render.sh sensor_gauge
python3 tests/check_geom.py stl/sensor_gauge.stl --min-vol 100
```
Expected: FAIL — the STL is empty because `sensor_gauge()` is still a stub (`is empty` or non-zero exit).

- [ ] **Step 2: Implement `sensor_pocket()` and `sensor_gauge()`**

Replace the `module sensor_gauge() {}` stub with:

```openscad
module sensor_pocket() {
    cav_x = sensor_pcb_w + sensor_slot_fit;   // width
    cav_y = sensor_pcb_t + sensor_slot_fit;   // thickness (into +Y face)
    cav_z = sensor_pcb_h + sensor_slot_fit;   // drop-in depth
    out_x = cav_x + 2 * pocket_wall;
    out_y = cav_y + 2 * pocket_wall;
    out_z = cav_z + pocket_wall;              // floor only; mouth open at top

    assert(pocket_wall > 0, "pocket_wall must be positive");
    assert(sensor_grille_w <= cav_x, "grille wider than cavity");
    assert(sensor_grille_h <= cav_z, "grille taller than cavity");

    difference() {
        // outer block
        cube([out_x, out_y, out_z]);
        // cavity (open top = mouth for drop-in)
        translate([pocket_wall, pocket_wall, pocket_wall])
            cube([cav_x, cav_y, cav_z + 0.1]);
        // grille window in +Y face
        translate([(out_x - sensor_grille_w) / 2, out_y - pocket_wall - 0.1,
                   pocket_wall + (cav_z - sensor_grille_h) / 2])
            cube([sensor_grille_w, pocket_wall + 0.2, sensor_grille_h]);
        // cable hole in -Y face
        translate([(out_x - cable_hole_w) / 2, -0.1,
                   pocket_wall + (cav_z - cable_hole_h) / 2])
            cube([cable_hole_w, pocket_wall + 0.2, cable_hole_h]);
    }
    // two retention lips at the mouth (chamfered so they print without support)
    for (sx = [pocket_wall + 2, out_x - pocket_wall - 2 - lip_proud * 2])
        translate([sx, pocket_wall, out_z])
            rotate([0, -45, 0])
                cube([lip_proud * 1.414, cav_y, lip_proud * 1.414]);
}

module sensor_gauge() { sensor_pocket(); }
```

- [ ] **Step 3: Render and check bounding box (expect PASS)**

Run:
```bash
bash tests/render.sh sensor_gauge
python3 tests/check_geom.py stl/sensor_gauge.stl --bbox 41.2 14.2 12.2 --tol 1.5 --watertight --min-vol 500
```
Expected: `PASS` with extents near `(41.2, 14.2, 12.2)`.

- [ ] **Step 4: Visual render for review**

Run:
```bash
openscad -o docs/renders/sensor-gauge.png -D 'part="sensor_gauge"' \
  --imgsize=1000,750 --colorscheme=Tomorrow --autocenter --viewall \
  --render pi4_dht22_enclosure.scad
```
Inspect `docs/renders/sensor-gauge.png`: confirm an open-top cavity, a grille window on one long face, a cable slot opposite, and two lips at the mouth.

- [ ] **Step 5: Commit**

```bash
git add pi4_dht22_enclosure.scad stl/sensor_gauge.stl docs/renders/sensor-gauge.png
git commit -m "pi4-dht22-enclosure: sensor pocket + gauge (print-first breakout box)

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

### Task 3: Sensor arm

The plug-in arm: keyed tenon → straight span with a cable groove → `sensor_pocket()` at the end (rotated so the grille faces outboard) → optional desk foot.

**Files:**
- Modify: `pi4_dht22_enclosure.scad` (replace `arm()` stub)

**Interfaces:**
- Consumes: `sensor_pocket()`; parameters `arm_*`, `socket_depth`, `socket_fit`, `foot_*`.
- Produces: `module arm()` laid along **X**: tenon at x-min (cross-section `arm_w × arm_h`, length `socket_depth`), straight arm length `arm_len`, pocket at x-max rotated +90° about Z (grille faces **+X**). Resting on the bed at Z=0. Total length `≈ socket_depth + arm_len + (sensor_pcb_t+sensor_slot_fit+2·pocket_wall)`.

- [ ] **Step 1: Write the failing check**

Run:
```bash
bash tests/render.sh arm
python3 tests/check_geom.py stl/arm.stl --min-vol 100
```
Expected: FAIL (empty — `arm()` is a stub).

- [ ] **Step 2: Implement `arm()`**

Replace `module arm() {}` with:

```openscad
module arm() {
    pocket_x = sensor_pcb_t + sensor_slot_fit + 2 * pocket_wall; // depth once rotated
    pocket_y = sensor_pcb_w + sensor_slot_fit + 2 * pocket_wall; // width once rotated
    span_end = socket_depth + arm_len;                          // where pocket begins

    assert(arm_len >= 50, "arm_len below 50 mm defeats thermal isolation");

    // tenon + straight arm as one flat bar, centred on Y=0
    translate([0, -arm_w / 2, 0])
        cube([span_end, arm_w, arm_h]);

    // cable groove along the top of the arm
    translate([socket_depth, -arm_groove_w / 2, arm_h - arm_groove_d + 0.01])
        cube([arm_len, arm_groove_w, arm_groove_d + 0.1]);

    // pocket at the end, rotated so its +Y grille faces +X (outboard)
    translate([span_end, 0, 0])
        rotate([0, 0, -90])
            translate([-pocket_y / 2, 0, 0])   // recentre width on the arm axis
                sensor_pocket();

    // optional desk foot under the pocket end
    if (arm_foot)
        translate([span_end - foot_len, -arm_w / 2, -foot_h])
            cube([foot_len + pocket_x, arm_w, foot_h]);
}
```

Note: the groove is subtracted-as-added here (a raised bar minus a channel). If the render shows the channel not cutting, wrap the bar + groove in a `difference()`; re-render and confirm the groove is a recess, not a rib.

- [ ] **Step 3: Render and check (expect PASS)**

Run:
```bash
bash tests/render.sh arm
python3 tests/check_geom.py stl/arm.stl --bbox 104.2 41.2 15.2 --tol 2.5 --watertight --min-vol 3000
```
Expected: `PASS` (X≈104, Y≈41 governed by the pocket width, Z≈12–15 with the foot).

- [ ] **Step 4: Visual render**

Run:
```bash
openscad -o docs/renders/arm.png -D 'part="arm"' \
  --imgsize=1200,600 --colorscheme=Tomorrow --autocenter --viewall \
  --render pi4_dht22_enclosure.scad
```
Confirm: tenon at one end, a groove running the span, the pocket at the far end grille-out, and (if enabled) the foot underneath.

- [ ] **Step 5: Commit**

```bash
git add pi4_dht22_enclosure.scad stl/arm.stl docs/renders/arm.png
git commit -m "pi4-dht22-enclosure: plug-in sensor arm

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

### Task 4: Standoffs + base tray

The Pi-side base: floor, standoff field on the 58×49 pattern, two walled sides (SD short edge, GPIO long edge) with cable-exit and SD notch, two open port-channel sides, four lid-screw bosses, floor vents, and the keyed arm socket.

**Files:**
- Modify: `pi4_dht22_enclosure.scad` (add `standoff()`, `standoff_field()`, `tray_socket()`; replace `tray()` stub)

**Interfaces:**
- Consumes: all board, shell, standoff, boss, vent, sd, cable, socket parameters.
- Produces: `module standoff()` (Ø`standoff_od`, height `standoff_h`, Ø`hole_pilot_d` pilot). `module standoff_field()` — four standoffs at the 58×49 pattern, board origin at tray inner corner. `module tray()` — footprint origin at (0,0,0), board seated at `[wall+? , wall+?, floor]`; +Y long edge walled (GPIO, cable slot), x-min short edge walled (SD notch), −Y and x-max open. Arm socket protrudes +Y on the GPIO side.

- [ ] **Step 1: Write the failing check**

Run:
```bash
bash tests/render.sh tray
python3 tests/check_geom.py stl/tray.stl --min-vol 100
```
Expected: FAIL (empty stub).

- [ ] **Step 2: Implement standoffs and the tray shell**

Add near the other modules:

```openscad
module standoff() {
    difference() {
        cylinder(h = standoff_h, d = standoff_od);
        translate([0, 0, -0.1])
            cylinder(h = standoff_h + 0.2, d = hole_pilot_d);
    }
}

module standoff_field() {
    // board sits with its lower-left mount hole at (hole_edge, hole_edge)
    for (x = [hole_edge, hole_edge + hole_dx])
        for (y = [hole_edge, hole_edge + hole_dy])
            translate([x, y, 0]) standoff();
    assert(hole_dx == 58 && hole_dy == 49, "Pi 4 mount pattern must stay 58x49");
}

module tray_socket() {
    // keyed rectangular socket protruding +Y on the GPIO wall; keyed by a notch
    sx = arm_w + socket_fit;
    sz = arm_h + socket_fit;
    difference() {
        translate([0, 0, 0]) cube([sx + 2 * wall, socket_depth + wall, sz + 2 * wall]);
        translate([wall, -0.1, wall]) cube([sx, socket_depth + 0.1, sz]);      // tenon bore
        translate([wall + sx / 2, socket_depth / 2, sz + wall])                 // set screw
            cylinder(h = wall + 0.2, d = setscrew_d);
        translate([wall + sx / 2 - 1, -0.1, wall]) cube([2, socket_depth, 1.5]); // key notch
    }
}

module tray() {
    // inner cavity spans the board + fit
    in_x = board_w + 2 * board_fit;
    in_y = board_l + 2 * board_fit;
    out_x = in_x + wall;      // wall only on x-min (SD side); x-max open
    out_y = in_y + wall;      // wall only on +Y (GPIO side); -Y open

    difference() {
        union() {
            // floor
            cube([out_x, out_y, floor]);
            // x-min wall (SD short edge)
            cube([wall, out_y, floor + tray_wall_h]);
            // +Y wall (GPIO long edge)
            translate([0, in_y, 0]) cube([out_x, wall, floor + tray_wall_h]);
            // four corner bosses for the lid screws
            for (cx = [wall + 3, out_x - 3])
                for (cy = [3, in_y - 3])
                    translate([cx, cy, floor]) cylinder(h = tray_wall_h, d = boss_d);
        }
        // boss pilots
        for (cx = [wall + 3, out_x - 3])
            for (cy = [3, in_y - 3])
                translate([cx, cy, floor + tray_wall_h - 6])
                    cylinder(h = 6.1, d = boss_pilot);
        // SD notch in the x-min wall
        translate([-0.1, (out_y - sd_slot_w) / 2, floor + standoff_h])
            cube([wall + 0.2, sd_slot_w, sd_slot_h]);
        // DHT22 cable exit in the +Y wall
        translate([(out_x - cable_slot_w) / 2, in_y - 0.1, floor + standoff_h])
            cube([cable_slot_w, wall + 0.2, cable_slot_h]);
        // floor vents under the board
        for (i = [-2 : 2])
            translate([out_x / 2 + i * (vent_slot_w + vent_gap) - vent_slot_w / 2,
                       (out_y - vent_slot_len) / 2, -0.1])
                cube([vent_slot_w, vent_slot_len, floor + 0.2]);
    }
    // standoffs, seated so the board's holes land on the 58x49 pattern
    translate([wall + board_fit, board_fit, floor]) standoff_field();
    // arm socket on the GPIO wall, protruding +Y
    translate([(out_x - (arm_w + socket_fit + 2 * wall)) / 2, out_y, floor])
        tray_socket();
}
```

- [ ] **Step 3: Render, then verify the mount pattern in-model**

Run:
```bash
bash tests/render.sh tray
python3 tests/check_geom.py stl/tray.stl --bbox 87.8 68.8 15 --tol 3.0 --watertight --min-vol 8000
```
Expected: `PASS`. (Y includes the ~10 mm socket protrusion; tolerance is generous because the socket and bosses shift the extents.) If watertight fails, the usual cause is a boss or the socket coinciding exactly with a wall face — nudge by 0.01 and re-render.

- [ ] **Step 4: Visual render (top-down + iso)**

Run:
```bash
openscad -o docs/renders/tray.png -D 'part="tray"' \
  --imgsize=1200,900 --colorscheme=Tomorrow --autocenter --viewall \
  --render pi4_dht22_enclosure.scad
```
Confirm: four standoffs in a rectangle, two walled sides with the SD notch and cable slot, two open sides, four bosses, floor vents, and the socket on the GPIO wall. **Measure the standoff rectangle in the render or with a follow-up `--camera` top view; centres must be 58 mm × 49 mm apart.**

- [ ] **Step 5: Commit**

```bash
git add pi4_dht22_enclosure.scad stl/tray.stl docs/renders/tray.png
git commit -m "pi4-dht22-enclosure: base tray + standoffs

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

### Task 5: `fit_coupon` (Pi-side test print)

A small tile carrying one corner of the standoff pattern plus one adjacent open-channel edge — validates the M2.5 pilot fit, the hole-to-edge inset, and that a real Pi's port stack clears the open channel, for a few grams.

**Files:**
- Modify: `pi4_dht22_enclosure.scad` (replace `fit_coupon()` stub)

**Interfaces:**
- Consumes: `standoff()`; parameters `hole_edge`, `wall`, `floor`, `standoff_h`.
- Produces: `module fit_coupon()` — a `32 × 28 × floor` tile with one standoff at `(hole_edge+wall, hole_edge)` from a walled corner (x-min wall present, adjacent edge open). Rests on the bed at Z=0.

- [ ] **Step 1: Write the failing check**

Run:
```bash
bash tests/render.sh fit_coupon
python3 tests/check_geom.py stl/fit_coupon.stl --min-vol 100
```
Expected: FAIL (empty stub).

- [ ] **Step 2: Implement `fit_coupon()`**

Replace `module fit_coupon() {}` with:

```openscad
module fit_coupon() {
    cx = 32; cy = 28;
    union() {
        cube([cx, cy, floor]);                                  // tile
        cube([wall, cy, floor + tray_wall_h]);                  // one walled edge (SD/GPIO-like)
        translate([wall + hole_edge, hole_edge, floor]) standoff();   // one standoff corner
        // stub of the open-channel edge: a 2 mm-tall lip only, so a port stack clears above it
        translate([0, cy - wall, 0]) cube([cx, wall, floor + 2]);
    }
}
```

- [ ] **Step 3: Render and check (expect PASS)**

Run:
```bash
bash tests/render.sh fit_coupon
python3 tests/check_geom.py stl/fit_coupon.stl --bbox 32 28 7.0 --tol 1.5 --watertight --min-vol 500
```
Expected: `PASS`.

- [ ] **Step 4: Visual render**

Run:
```bash
openscad -o docs/renders/fit-coupon.png -D 'part="fit_coupon"' \
  --imgsize=1000,750 --colorscheme=Tomorrow --autocenter --viewall \
  --render pi4_dht22_enclosure.scad
```
Confirm one standoff, one full-height walled edge, and one low open-channel lip.

- [ ] **Step 5: Commit**

```bash
git add pi4_dht22_enclosure.scad stl/fit_coupon.stl docs/renders/fit-coupon.png
git commit -m "pi4-dht22-enclosure: fit-check coupon

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

### Task 6: Lid

A vented top shell that drops over the tray: top vent grid, LED window at the USB-C corner, open cutouts on the two port sides, corner screw holes, and a lip that overlaps the tray walls.

**Files:**
- Modify: `pi4_dht22_enclosure.scad` (replace `lid()` stub)

**Interfaces:**
- Consumes: tray footprint math (mirror the `in_x/in_y/out_x/out_y` derivation), `lid_*`, `vent_*`, `led_win_*`, `boss` positions.
- Produces: `module lid()` — an inverted shell covering the board region, resting mouth-up on the bed for printing (top face on the bed, walls rising in +Z). Inner clearance `lid_clear` above the board; drops over the tray with `lid_fit` clearance. Screw holes align with the tray bosses.

- [ ] **Step 1: Write the failing check**

Run:
```bash
bash tests/render.sh lid
python3 tests/check_geom.py stl/lid.stl --min-vol 100
```
Expected: FAIL (empty stub).

- [ ] **Step 2: Implement `lid()`**

Replace `module lid() {}` with (printed top-down: the closed top sits at Z=0, walls rise):

```openscad
module lid() {
    in_x  = board_w + 2 * board_fit;
    in_y  = board_l + 2 * board_fit;
    tout_x = in_x + wall;
    tout_y = in_y + wall;
    lx = tout_x + 2 * (lid_wall + lid_fit);
    ly = tout_y + 2 * (lid_wall + lid_fit);
    lz = lid_clear + lid_wall;

    difference() {
        cube([lx, ly, lz]);                                  // solid block
        translate([lid_wall + lid_fit, lid_wall + lid_fit, lid_wall])
            cube([tout_x, tout_y, lz]);                      // hollow (mouth down = +Z here)
        // top vent grid (through the closed top at Z=0)
        for (i = [-3 : 3])
            translate([lx / 2 + i * (vent_slot_w + vent_gap) - vent_slot_w / 2,
                       (ly - vent_slot_len) / 2, -0.1])
                cube([vent_slot_w, vent_slot_len, lid_wall + 0.2]);
        // open port channel — remove the -Y wall (AV side) and x-max wall (Ethernet side)
        translate([lid_wall + lid_fit, -0.1, lid_wall])
            cube([tout_x, lid_wall + lid_fit + 0.2, lz]);            // -Y open
        translate([lx - lid_wall - lid_fit - 0.1, lid_wall + lid_fit, lid_wall])
            cube([lid_wall + lid_fit + 0.2, tout_y, lz]);           // x-max open
        // LED window at the USB-C corner (-Y / x-min corner), through the lip
        translate([lid_wall + lid_fit + 4, -0.1, lz - led_win_h - 2])
            cube([led_win_w, lid_wall + lid_fit + 0.2, led_win_h]);
        // four lid screw clearance holes over the tray bosses
        for (cx = [lid_wall + lid_fit + wall + 3, lx - lid_wall - lid_fit - 3])
            for (cy = [lid_wall + lid_fit + 3, ly - lid_wall - lid_fit - 3])
                translate([cx, cy, -0.1]) cylinder(h = lz + 0.2, d = lid_screw_d);
    }
    assert(lx > tout_x && ly > tout_y, "lid must clear the tray outer");
}
```

Note: the boss/screw X-Y positions must match Task 4's bosses once the tray's `out_x` (open x-max, so no +wall there) is accounted for. After rendering, overlay lid and tray (Task 7 assembly) and confirm the four holes sit on the four bosses; adjust the `cx/cy` expressions if they are off.

- [ ] **Step 3: Render and check (expect PASS)**

Run:
```bash
bash tests/render.sh lid
python3 tests/check_geom.py stl/lid.stl --bbox 92.4 62.8 22 --tol 3.0 --watertight --min-vol 6000
```
Expected: `PASS`.

- [ ] **Step 4: Visual render**

Run:
```bash
openscad -o docs/renders/lid.png -D 'part="lid"' \
  --imgsize=1200,900 --colorscheme=Tomorrow --autocenter --viewall \
  --render pi4_dht22_enclosure.scad
```
Confirm: a vented top, two open port sides, an LED window, four screw holes.

- [ ] **Step 5: Commit**

```bash
git add pi4_dht22_enclosure.scad stl/lid.stl docs/renders/lid.png
git commit -m "pi4-dht22-enclosure: vented lid

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

### Task 7: Assembly view + Pi ghost + fit verification

A visual-only `assembly` part that stacks tray + lid + arm with a ghosted Pi board, used to confirm the lid mates the tray, screw holes align with bosses, ports face the open sides, and the arm exits the GPIO wall.

**Files:**
- Modify: `pi4_dht22_enclosure.scad` (add `pi_ghost()`; replace `assembly()` stub)

**Interfaces:**
- Consumes: `tray()`, `lid()`, `arm()`; board parameters.
- Produces: `module pi_ghost()` — an 85×56×1.4 board at the seated position with Ø2.7 holes, rendered `%` (ghost). `module assembly()` — tray at origin, board ghost on the standoffs, lid translated up by `floor + tray_wall_h`, arm plugged into the socket. Not exported for print (visual only).

- [ ] **Step 1: Implement `pi_ghost()` and `assembly()`**

Replace `module assembly() {}` with:

```openscad
module pi_ghost() {
    difference() {
        cube([board_w, board_l, pcb_t]);
        for (x = [hole_edge, hole_edge + hole_dx])
            for (y = [hole_edge, hole_edge + hole_dy])
                translate([x, y, -0.1]) cylinder(h = pcb_t + 0.2, d = 2.7);
    }
}

module assembly() {
    tray();
    % translate([wall + board_fit, board_fit, floor + standoff_h]) pi_ghost();
    translate([0, 0, floor + tray_wall_h + 5]) lid();     // exploded up for clarity
    translate([/* socket mouth */ 0, 0, 0])
        translate([(board_w + 2 * board_fit + wall) / 2 - arm_w / 2,
                   board_l + 2 * board_fit + wall, floor + wall])
            rotate([0, 0, 90]) arm();
}
```

Note: the arm placement expression aims the arm out +Y from the socket. Adjust the translate so the tenon enters the socket bore; this is a visual aid, so eyeball alignment in the render is sufficient.

- [ ] **Step 2: Render the assembly (iso + rear)**

Run:
```bash
openscad -o docs/renders/assembly-iso.png -D 'part="assembly"' \
  --imgsize=1400,1000 --colorscheme=Tomorrow --autocenter --viewall \
  --render pi4_dht22_enclosure.scad
```
Confirm against the design: board on standoffs, lid clears the ports, the two open sides face the port edges, the arm exits the GPIO wall pointing away from the box, screw holes over bosses. Note any misalignment.

- [ ] **Step 3: Fix any alignment issues found**

If the render shows the lid holes off the bosses, the ports on a walled side, or the arm through a wall, adjust the offending parameter/translate in the relevant module and re-render until the assembly reads correctly. (No code shown — the fix depends on what the render reveals; keep changes minimal and re-run Steps 2 here plus the affected part's bbox check from its task.)

- [ ] **Step 4: Commit**

```bash
git add pi4_dht22_enclosure.scad docs/renders/assembly-iso.png
git commit -m "pi4-dht22-enclosure: assembly view + Pi ghost

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

### Task 8: Project README, BUILD_LOG, and root index

Documentation matching the repo house style, plus adding the project to the root README table.

**Files:**
- Create: `README.md`
- Create: `BUILD_LOG.md`
- Modify: `../README.md` (root project table)

**Interfaces:**
- Consumes: nothing (docs). References the parts, `part=` selector, the fit-check ladder (sensor gauge first), and the re-fit instructions (measure the DHT22, set `sensor_pcb_*`).

- [ ] **Step 1: Write the project README**

Create `README.md` following the frame-holder README's shape: one-paragraph what-it-is; the DHT22 module note (measure yours, set `sensor_pcb_w/h/t`); parts list; **fit-test ladder with `sensor_gauge` first**; print settings (PETG, 0.2 mm, no supports); and the re-export commands:

```markdown
# Raspberry Pi 4 enclosure with DHT22 sensor arm

A three-part desk enclosure for a Pi 4 Model B temperature node, plus a plug-in
arm that holds a DHT22 module in free air off the Pi's warm plume. Prints flat,
no supports; PETG recommended.

Model: `pi4_dht22_enclosure.scad`. Design record: `docs/design/`. Renders: `docs/renders/`.

## The DHT22 module — measure yours first

The sensor pocket is a drop-in cavity. Modules vary, so measure your board and set
`sensor_pcb_w` / `sensor_pcb_h` / `sensor_pcb_t` at the top of the SCAD. Defaults are
37 × 10 × 10 mm.

## Fit-test ladder (cheap prints, print in this order)

1. `stl/sensor_gauge.stl` — the sensor pocket alone ("breakout box"). **Print this
   first** and confirm the DHT22 module drops in with a firm grip before anything else.
2. `stl/fit_coupon.stl` — one standoff corner + an open-channel edge. Confirms the M2.5
   pilot and that the Pi's ports clear the open channel.
3. `stl/tray.stl`, `stl/lid.stl`, `stl/arm.stl` — the production set.

## Printing

PETG, 0.2 mm layers, 3 perimeters, ~20% infill, no supports. STLs are pre-oriented.

## Re-export

    openscad -o stl/sensor_gauge.stl -D 'part="sensor_gauge"' pi4_dht22_enclosure.scad
    openscad -o stl/arm.stl          -D 'part="arm"'          pi4_dht22_enclosure.scad
    openscad -o stl/tray.stl         -D 'part="tray"'         pi4_dht22_enclosure.scad
    openscad -o stl/lid.stl          -D 'part="lid"'          pi4_dht22_enclosure.scad
    openscad -o stl/fit_coupon.stl   -D 'part="fit_coupon"'   pi4_dht22_enclosure.scad

`part` also accepts `"assembly"` (all parts + a ghosted Pi, visual only).
```

- [ ] **Step 2: Write BUILD_LOG.md**

Create `BUILD_LOG.md` with a dated first entry recording: design + model authored, all parts render watertight and pass bbox checks, **not yet printed in plastic**, and the open first action (print `sensor_gauge`, verify the module fit, then the coupon).

```markdown
# Build log

## 2026-07-25 — model complete, unprinted

Three-part Pi 4 enclosure + DHT22 arm modeled in `pi4_dht22_enclosure.scad`. All
parts render watertight and pass bounding-box checks (`tests/check_geom.py`). Nothing
printed yet.

Next: print `stl/sensor_gauge.stl` and confirm the DHT22 module (measured 37×10×10 mm)
drops in with a firm grip; then `stl/fit_coupon.stl` against the real Pi; then the
production tray/lid/arm.
```

- [ ] **Step 3: Add the project to the root README table**

In `../README.md`, add a row to the Projects table:

```markdown
| [pi4-dht22-enclosure](pi4-dht22-enclosure/) | A Raspberry Pi 4 desk enclosure with a plug-in arm that holds a DHT22 temp/humidity module in free air, off the Pi's heat. Parametric, prints flat, no supports. |
```

- [ ] **Step 4: Commit**

```bash
git add README.md BUILD_LOG.md ../README.md
git commit -m "pi4-dht22-enclosure: project README, build log, root index

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

## Self-Review

**Spec coverage** (design doc → task):
- Three parts tray/lid/arm → Tasks 4, 6, 3. ✓
- Drop-in sensor pocket, measured 37×10×10 → Task 2 (`sensor_pocket`). ✓
- Sensor pocket printed first → Task 2 precedes Pi-side parts; README ladder lists it first. ✓
- Standoffs, 58×49 pattern, M2.5 pilots → Task 4 (`standoff_field`, in-model assert). ✓
- Open port channels (no cutouts) → Tasks 4 (open sides) + 6 (open lid sides). ✓
- SD notch, cable exit, LED window, floor + top vents → Tasks 4 & 6. ✓
- Keyed arm socket + set screw, cable groove, 80 mm reach, optional foot → Tasks 3 & 4. ✓
- Fit-check ladder (`sensor_gauge`, `fit_coupon`) → Tasks 2 & 5. ✓
- `part=` selector incl. `assembly` + ghost → Tasks 1 & 7. ✓
- PETG / support-free / pre-oriented STL → Global Constraints + README (Task 8). ✓
- House-style README/BUILD_LOG + root index → Task 8. ✓

**Placeholder scan:** No "TBD/TODO/handle edge cases" left; the two "Note:" blocks describe concrete render-inspect adjustments, not deferred work. Bbox numbers are computed from the parameter block with explicit tolerances.

**Type/name consistency:** `sensor_pocket()` defined in Task 2, reused in Tasks 3 & 7. `standoff()`/`standoff_field()` defined in Task 4, reused in Task 5. Parameter names match the SCAD block in Task 1 throughout. `part=` strings match the dispatcher.

**Known soft spots (flagged, not deferred):** exact lid-boss ↔ tray-boss X-Y alignment and the arm-into-socket transform are verified visually in Task 7 and adjusted there — inherent to CAD, where the render is the test. Bounding-box tolerances are deliberately generous (1.5–3 mm) for the parts whose bosses/socket shift the extents; watertightness + in-model asserts carry the precise checks.
