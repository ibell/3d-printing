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
    ap.add_argument("--min-z", type=float, default=None,
                    help="assert the mesh's minimum Z equals this value (within --tol)")
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
    if a.min_z is not None:
        got = m.bounds[0][2]
        if abs(got - a.min_z) > a.tol:
            print(f"FAIL: min z {got:.3f} != {a.min_z} (+/-{a.tol})")
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
