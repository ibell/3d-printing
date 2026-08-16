#!/usr/bin/env python3
"""Assembly-fit checks: do parts actually go together?

Bounding boxes and watertightness cannot catch a part that passes through
another one. On 2026-08-15 the arm socket shipped as a fully enclosed cavity --
capped outboard and closed by the tray wall -- so the arm could not be inserted
and its bar intersected the tray by 100 mm^3. Every per-part check passed, and
the assembly *render* looked correct, because overlapping solids simply merge
in a render. Only an explicit solid intersection finds this class of bug.

Also checks that nothing overhangs unsupported, which is how the same socket
came to float a 10 x 12 mm slab 2 mm above the bed in a support-free design.
"""

import subprocess
import sys
import tempfile
from pathlib import Path

import numpy as np
import trimesh

ROOT = Path(__file__).resolve().parent.parent
SCAD = ROOT / "pi4_dht22_enclosure.scad"
# Adafruit's own model of the SHT40 breakout, vendored in docs/reference. Used
# as ground truth for the cradle and clip so those are checked against the
# manufacturer's geometry rather than numbers retyped from a drawing.
SHT40 = ROOT / "docs" / "reference" / "adafruit-4885-sht40.stl"
BOARD = f'translate([0, -sht_wid/2, cradle_gauge_t + board_lift]) import("{SHT40}")'
CLIP  = ('translate([clip_x, 0, cradle_gauge_t + btop_rel]) '
         'sensor_clip_body()')

# Solid pairs that must NOT overlap, expressed as an OpenSCAD intersection()
# in assembled coordinates. Tolerance is in mm^3.
PAIRS = [
    (
        "arm-in-socket",
        """
        out_x = board_w + 2*board_fit + wall;
        out_y = board_l + 2*board_fit + wall;
        intersection() {
            tray();
            translate([out_x/2, out_y, floor + wall]) rotate([0,0,90]) arm();
        }
        """,
        # Was 60.0 to "allow the detent press" -- which masked a real bug: the
        # detent bumps were positioned with an inverted sign and protruded
        # 1.95 mm into the bore instead of 0.45 mm, leaving a 6.5 mm gap for a
        # 10 mm tenon. The arm could not be inserted, and the check passed at
        # 28.9 mm^3. With a plain friction socket the seated arm should touch
        # essentially nothing, so the tolerance is tight enough to notice.
        2.0,
    ),
    (
        # A SEATED lid should touch the tray almost nowhere: the ridge sits
        # inside the groove with clearance. The old geometry read 3.4 mm^3 here
        # because the ridge was too tall to enter and the lid was wedged on the
        # ridge flanks -- which is exactly why it "fitted but would not snap".
        # The 60.0 tolerance let that through. Paired with
        # lid-snap-retains-when-lifted, these two now pin the joint down: seats
        # freely AND resists lifting.
        "lid-on-tray-seated",
        """
        intersection() { tray(); lid_assembled(); }
        """,
        2.0,
    ),
    (
        # An inserted microSD must pass through the notch. The card lives BELOW
        # the board (its holder is on the Pi's underside), which the first
        # version got backwards -- the notch ran upward from the board underside
        # and the card fouled solid wall ~1 mm below it.
        "sd-card-clears-notch",
        """
        card_z = floor + standoff_h - 1.9;   // card sits under the PCB
        intersection() {
            tray();
            translate([-2, board_fit + board_l/2 - 5.5, card_z])
                cube([15, 11, 1.0]);
        }
        """,
        0.5,
    ),
    (
        # The GPIO jumper stack is the tallest thing in the box; the lid must
        # not sit on it. Modelled as the header footprint extended up by
        # the measured jump_stack from the board top.
        "lid-clears-gpio-jumpers",
        """
        btop = floor + standoff_h + pcb_t;
        intersection() {
            lid_assembled();
            translate([wall + board_fit + 7, board_fit + 49.5, btop])
                cube([50.8, 5.1, jump_stack]);
        }
        """,
        0.5,
    ),
    (
        # The SHT40 must drop onto the cradle without fouling it: pips are
        # 0.2 mm under the mounting holes, and the walls clear the board edges.
        # Checked against Adafruit's own model of the board.
        "sht40-board-clears-cradle",
        f"""
        intersection() {{ sensor_gauge(); {BOARD}; }}
        """,
        2.0,
    ),
    (
        # A SEATED clip must touch the cradle almost nowhere -- its bumps sit
        # inside the grooves with clearance and its legs clear the walls by
        # clip_fit. This read 14.2 mm^3 in the first version and PASSED a
        # 0.5-60 range: that number was the clip's bar resting on the wall tops,
        # 0.8 mm before its pads reached the board. Third time a tolerance
        # widened for an intended interference hid an unintended one, so this is
        # now a no-overlap check paired with a lifted-retention check below.
        "sht40-clip-seated-on-cradle",
        f"""
        intersection() {{ {CLIP}; sensor_gauge(); }}
        """,
        1.0,
    ),
    (
        # The printable stand-in must fit the cradle exactly as the real board
        # does -- it is the only way to exercise the joint before the SHT40
        # arrives. Note it shares the sht_* parameters with the cradle, so it
        # cannot tell you whether those parameters are RIGHT.
        "sht40-dummy-clears-cradle",
        """
        intersection() {
            sensor_gauge();
            translate([0, -sht_wid/2, cradle_gauge_t + board_lift]) sht40_dummy();
        }
        """,
        1.0,
    ),
    (
        # Slide path: the clip goes on axially, so a clear SEATED position is
        # not enough -- it has to be clear at every point along the travel too.
        "sht40-clip-slide-path-x8p0",
        f"""
        intersection() {{
            translate([8.0, 0, cradle_gauge_t + btop_rel]) sensor_clip_body();
            sensor_gauge();
        }}
        """,
        1.0,
    ),
    (
        # The printable stand-in must fit the cradle exactly as the real board
        # does -- it is the only way to exercise the joint before the SHT40
        # arrives. Note it shares the sht_* parameters with the cradle, so it
        # cannot tell you whether those parameters are RIGHT.
        "sht40-dummy-clears-cradle",
        """
        intersection() {
            sensor_gauge();
            translate([0, -sht_wid/2, cradle_gauge_t + board_lift]) sht40_dummy();
        }
        """,
        1.0,
    ),
    (
        # Slide path: the clip goes on axially, so a clear SEATED position is
        # not enough -- it has to be clear at every point along the travel too.
        "sht40-clip-slide-path-x10p0",
        f"""
        intersection() {{
            translate([10.0, 0, cradle_gauge_t + btop_rel]) sensor_clip_body();
            sensor_gauge();
        }}
        """,
        1.0,
    ),
    (
        # The printable stand-in must fit the cradle exactly as the real board
        # does -- it is the only way to exercise the joint before the SHT40
        # arrives. Note it shares the sht_* parameters with the cradle, so it
        # cannot tell you whether those parameters are RIGHT.
        "sht40-dummy-clears-cradle",
        """
        intersection() {
            sensor_gauge();
            translate([0, -sht_wid/2, cradle_gauge_t + board_lift]) sht40_dummy();
        }
        """,
        1.0,
    ),
    (
        # Slide path: the clip goes on axially, so a clear SEATED position is
        # not enough -- it has to be clear at every point along the travel too.
        "sht40-clip-slide-path-x12p0",
        f"""
        intersection() {{
            translate([12.0, 0, cradle_gauge_t + btop_rel]) sensor_clip_body();
            sensor_gauge();
        }}
        """,
        1.0,
    ),
    (
        # The clip must not sit over either STEMMA QT connector, or the cable
        # could only be fitted before the clip. Connectors occupy the central
        # band on both short ends, standing sht_conn_h above the PCB.
        "sht40-clip-clears-connectors",
        f"""
        bt = cradle_gauge_t + btop_rel;
        intersection() {{
            {CLIP};
            union() {{
                translate([0.23, -sht_conn_half, bt]) cube([4.18, 2*sht_conn_half, sht_conn_h]);
                translate([20.99, -sht_conn_half, bt]) cube([4.18, 2*sht_conn_half, sht_conn_h]);
            }}
        }}
        """,
        0.5,
    ),
    (
        # The lid pads must NOT be resting on the locating pips -- if their
        # clearance bores were too shallow or too narrow the pads would bear on
        # the pip tips instead of the PCB, and the Pi would never be clamped.
        "lid-pads-vs-pips",
        """
        intersection() {
            translate([wall + board_fit, board_fit, floor]) standoff_field();
            lid_assembled();
        }
        """,
        0.5,
    ),
]

# Solid pairs that MUST overlap, by roughly a known amount: these are the
# interference fits the design relies on. A zero here means a joint that looks
# fine but never actually engages.
CLAMPS = [
    (
        # Retention: with the lid SEATED the ridge sits inside the groove with
        # clearance, so a seated check reads 0 and proves nothing. Lift the lid
        # and the lip must run into the ridge -- that collision IS the snap. A
        # zero here means the lid would simply fall off.
        "lid-snap-retains-when-lifted",
        """
        intersection() {
            tray();
            translate([0, 0, 1.5]) lid_assembled();
        }
        """,
        5.0,
        400.0,
    ),
    (
        # The clip must actually grip the board -- pads reach clip_preload below
        # the board top. If this were 0 the clip would merely rest on it. If it
        # were large, the clip would be fouling the STEMMA QT connectors, which
        # is the other way this can go wrong.
        "sht40-clip-grips-board",
        f"""
        intersection() {{ {CLIP}; {BOARD}; }}
        """,
        3.0,
        40.0,
    ),
    (
        # Retention: seated, the bump sits inside its groove and touches
        # nothing. Lift the clip and the bump must run into the groove's top
        # edge. Zero here would mean the clip simply lifts off.
        "sht40-clip-retains-when-lifted",
        f"""
        intersection() {{
            translate([0, 0, 1.0]) {{ {CLIP}; }}
            sensor_gauge();
        }}
        """,
        1.0,
        60.0,
    ),
    (
        # pads pressing the Pi down onto the standoffs: four annular contacts,
        # ~hold_preload deep. Zero would mean the lid never touches the board.
        "lid-pads-clamp-board",
        """
        board_top = floor + standoff_h;
        intersection() {
            lid_assembled();
            difference() {
                translate([wall + board_fit, board_fit, board_top])
                    cube([board_w, board_l, pcb_t]);
                for (hx = [hole_edge, hole_edge + hole_dx])
                    for (hy = [hole_edge, hole_edge + hole_dy])
                        translate([wall + board_fit + hx, board_fit + hy,
                                   board_top - 0.1])
                            cylinder(d = pi_hole_d, h = pcb_t + 0.2, $fn = 32);
            }
        }
        """,
        8.0,
        60.0,
    ),
]


def render(body: str, out: Path) -> None:
    """Render an intersection to STL.

    An EMPTY intersection is the desired result for the no-overlap checks, but
    OpenSCAD exits non-zero rather than writing an empty file. Treat that as
    "no overlap" and let overlap_volume() report 0; anything else is a real
    failure and is raised.
    """
    src = f"include <{SCAD}>\n{body}\n"
    with tempfile.NamedTemporaryFile("w", suffix=".scad", delete=False) as fh:
        fh.write(src)
        tmp = fh.name
    proc = subprocess.run(
        ["openscad", "-o", str(out), "-D", 'part="_none"', tmp],
        capture_output=True,
        text=True,
    )
    if proc.returncode != 0:
        err = (proc.stderr or "") + (proc.stdout or "")
        if "empty" in err.lower():
            out.unlink(missing_ok=True)
            return
        raise RuntimeError(f"openscad failed:\n{err}")


def overlap_volume(out: Path) -> float:
    if not out.exists() or out.stat().st_size < 100:
        return 0.0
    return float(trimesh.load(out).volume)


def overhang_report(mesh, reach: float = 3.0, ground: float = 0.35, n: int = 44):
    """Find material that starts high above the bed and is far from anything
    that reaches the bed.

    A column is "grounded" if its lowest solid z is on the bed. An ungrounded
    column is only a problem if it is further than `reach` from the nearest
    grounded column -- a short protrusion like the 0.8 mm snap ridge bridges
    off the wall beside it and prints fine, whereas the socket's 10 x 12 mm
    slab sat ~6 mm from anything solid and would have drooped.
    """
    lo, hi = mesh.bounds
    xs = np.linspace(lo[0] + 0.3, hi[0] - 0.3, n)
    ys = np.linspace(lo[1] + 0.3, hi[1] - 0.3, n)
    zs = np.linspace(0.2, hi[2] - 0.2, 28)

    grounded, floating = [], []
    for x in xs:
        for y in ys:
            pts = np.column_stack([np.full_like(zs, x), np.full_like(zs, y), zs])
            ins = mesh.contains(pts)
            if not ins.any():
                continue
            first = zs[np.argmax(ins)]
            (grounded if first <= ground + 0.4 else floating).append((x, y, first))

    if not floating:
        return []
    if not grounded:
        return floating

    g = np.array([[p[0], p[1]] for p in grounded])
    bad = []
    for x, y, z in floating:
        if np.min(np.hypot(g[:, 0] - x, g[:, 1] - y)) > reach:
            bad.append((x, y, z))
    return bad


def check_supported(name: str, part: str) -> bool:
    stl = ROOT / "stl" / f"{part}.stl"
    if not stl.exists():
        return True
    bad = overhang_report(trimesh.load(stl))
    if bad:
        print(
            f"FAIL {name}: {len(bad)} sample columns of material start high "
            f"with no support within 3 mm -- unsupported overhang"
        )
        for b in bad[:5]:
            print(f"     x={b[0]:.1f} y={b[1]:.1f} first solid z={b[2]:.2f}")
        return False
    print(f"PASS {name}: no unsupported overhangs")
    return True


def main() -> int:
    ok = True
    with tempfile.TemporaryDirectory() as td:
        for name, body, tol in PAIRS:
            out = Path(td) / f"{name}.stl"
            render(body, out)
            vol = overlap_volume(out)
            if vol > tol:
                print(f"FAIL {name}: {vol:.1f} mm^3 of solid overlap (tol {tol})")
                ok = False
            else:
                print(f"PASS {name}: overlap {vol:.1f} mm^3 (tol {tol})")

        for name, body, lo, hi in CLAMPS:
            out = Path(td) / f"{name}.stl"
            render(body, out)
            vol = overlap_volume(out)
            if not (lo <= vol <= hi):
                print(
                    f"FAIL {name}: engagement {vol:.1f} mm^3, expected "
                    f"{lo}-{hi} (0 means the joint never touches)"
                )
                ok = False
            else:
                print(f"PASS {name}: engagement {vol:.1f} mm^3 (want {lo}-{hi})")

    ok &= check_supported("tray-overhang", "tray")
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
