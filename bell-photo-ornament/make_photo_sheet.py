#!/usr/bin/env python3
"""Lay out three photo outlines on a 6 x 4 inch (landscape) sheet, at 1:1.

Takes the outline from bell_photo_ornament.scad (part="template"), so it follows
any change to the bell, and writes:

  docs/photo_sheet_4x6.svg   vector, exactly 152.4 x 101.6 mm
  docs/photo_sheet_4x6.png   1800 x 1200 px at 300 dpi, for a photo lab or editor
  docs/photo_sheet_4x6.pdf   the PNG as a 6 x 4 in page

Run from this folder:  python3 make_photo_sheet.py
"""
import re
import subprocess
import tempfile
from pathlib import Path

from PIL import Image, ImageDraw

HERE = Path(__file__).resolve().parent
DOCS = HERE / "docs"

IN = 25.4
PAGE_W, PAGE_H = 152.4, 101.6   # mm: 6 x 4 in, landscape
DPI = 300
N = 3                             # outlines on the sheet
LINE = 0.25                       # mm, cut line width
BAR = 40.0                        # mm, scale-check bar


def outline():
    """Template polygon in mm, y up, from OpenSCAD's SVG export."""
    with tempfile.TemporaryDirectory() as d:
        svg = Path(d) / "t.svg"
        subprocess.run(["openscad", "-q", "-o", str(svg), "-D", 'part="template"',
                        str(HERE / "bell_photo_ornament.scad")],
                       check=True, stderr=subprocess.DEVNULL)
        text = svg.read_text()
    d = re.search(r'<path d="(.*?)"', text, re.S).group(1)
    pts = [(float(x), -float(y)) for x, y in re.findall(r"(-?[\d.]+),(-?[\d.]+)", d)]
    return pts


def layout(pts):
    xs = [p[0] for p in pts]
    ys = [p[1] for p in pts]
    w, h = max(xs) - min(xs), max(ys) - min(ys)
    cx0 = (max(xs) + min(xs)) / 2
    top = (PAGE_H - h) / 2 - 4          # leave room under the outlines for the bar
    shapes = []
    for i in range(N):
        cx = PAGE_W * (i + 0.5) / N
        # page coords: mm from the top-left corner, y down
        shapes.append([(cx + x - cx0, top + (max(ys) - y)) for x, y in pts])
    return shapes, w, h, top + h


def bar_geom(below):
    y = below + 8
    x0 = (PAGE_W - BAR) / 2
    return x0, y


def write_svg(shapes, below):
    x0, y = bar_geom(below)
    paths = "\n".join(
        '  <path d="M ' + " L ".join(f"{x:.3f},{yy:.3f}" for x, yy in s) +
        f' Z" fill="none" stroke="#000" stroke-width="{LINE}"/>' for s in shapes)
    svg = f'''<?xml version="1.0" encoding="UTF-8"?>
<svg xmlns="http://www.w3.org/2000/svg" width="{PAGE_W}mm" height="{PAGE_H}mm" viewBox="0 0 {PAGE_W} {PAGE_H}">
  <rect width="{PAGE_W}" height="{PAGE_H}" fill="#fff"/>
{paths}
  <path d="M {x0},{y-1.5} V {y+1.5} M {x0},{y} H {x0+BAR} M {x0+BAR},{y-1.5} V {y+1.5}" stroke="#000" stroke-width="{LINE}" fill="none"/>
  <text x="{PAGE_W/2}" y="{y+5}" font-family="Helvetica, Arial, sans-serif" font-size="3" text-anchor="middle">40 mm if printed at 100%</text>
</svg>
'''
    (DOCS / "photo_sheet_4x6.svg").write_text(svg)


def write_png_pdf(shapes, below):
    k = DPI / IN                        # px per mm
    W, H = round(PAGE_W * k), round(PAGE_H * k)
    img = Image.new("RGB", (W, H), "white")
    dr = ImageDraw.Draw(img)
    lw = max(1, round(LINE * k))
    for s in shapes:
        px = [(x * k, y * k) for x, y in s]
        dr.line(px + [px[0]], fill="black", width=lw, joint="curve")
    x0, y = bar_geom(below)
    dr.line([(x0 * k, y * k), ((x0 + BAR) * k, y * k)], fill="black", width=lw)
    for x in (x0, x0 + BAR):
        dr.line([(x * k, (y - 1.5) * k), (x * k, (y + 1.5) * k)], fill="black", width=lw)
    label = "40 mm if printed at 100%"
    try:
        from PIL import ImageFont
        font = ImageFont.truetype("Helvetica", round(3 * k))
    except Exception:
        font = None
    tw = dr.textlength(label, font=font)
    dr.text(((W - tw) / 2, (y + 2.5) * k), label, fill="black", font=font)
    img.save(DOCS / "photo_sheet_4x6.png", dpi=(DPI, DPI))
    img.save(DOCS / "photo_sheet_4x6.pdf", resolution=DPI)
    return W, H


if __name__ == "__main__":
    pts = outline()
    shapes, w, h, below = layout(pts)
    write_svg(shapes, below)
    W, H = write_png_pdf(shapes, below)
    print(f"outline {w:.1f} x {h:.1f} mm, x{N} on {PAGE_W:.1f} x {PAGE_H:.1f} mm; PNG {W}x{H} px")
