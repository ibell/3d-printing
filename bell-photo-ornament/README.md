# Bell photo ornament

A three-sided Christmas bell ornament. Each side has a shallow bell-shaped recess for a
photo. The cross-section is a rounded triangle, so each face is flat side to side and
curves only top to bottom. A paper photo bends onto it without wrinkling. Print it,
spray paint it red, and glue the photos in.

![bell](docs/renders/bell.png)

| File | Print | Notes |
|---|---|---|
| `stl/bell_photo_ornament.stl` | mouth down, as exported | no supports |
| `docs/photo_sheet_4x6.pdf` / `.png` / `.svg` | a 6 × 4" photo print or paper, at **100% / actual size** | all three photo outlines on one sheet |

Size: 55 × 62 × 80 mm (body 70 mm tall, plus the hanger tab). Each photo is about
39.5 mm wide at the bottom, about 29 mm at the waist, and 51.8 mm tall, with an arched top.

Why it prints without supports: the outside only gets narrower going up. The inside is
a rounded-triangle cavity that never narrows faster than 45°, and it closes in a pyramid
under the dome (see `docs/renders/section.png`). The hole in the hanger tab is a
teardrop, point up. It holds ribbon or a standard ornament hook.

## Finishing

1. Print it with 0.12–0.16 mm layers to keep the layer lines small on the curved faces.
   15% infill is plenty.
2. Optional: give it a coat of filler primer and sand lightly. Spray paint shows every
   layer line.
3. Spray paint red, in several light coats. Paint the pockets too. The photos go on top
   of the paint, and the pocket edges hide the paper's cut edge.
4. The photo sheet is an exact 6 × 4" landscape page with all three outlines on it.
   Either print it on paper at 100% and trace the outlines onto your photos, or drop
   your photos into the outlines of `photo_sheet_4x6.png` (1800 × 1200 px, 300 dpi) in
   a photo editor and order it as a regular 4×6 print. In both cases, check that the
   scale bar measures 40 mm. Photo labs sometimes crop or zoom a 4×6 slightly, so set
   them to "no crop" or "fit". Cut on the lines.
5. Glue the photos in with a thin layer of glue stick, Mod Podge, or spray adhesive.
   Wet glues cockle photo paper. Press each photo from the middle outward so it follows
   the face's curve.

## Fit parameters

In the top block of `bell_photo_ornament.scad`:

- `pocket_d` (0.8): pocket depth. Photo paper is about 0.25 mm thick, so the photo
  sits a little below the frame.
- `template_fit` (0.3): the template is this much smaller per side than the pocket.
  Raise it if the photos are tight. Lower it if they leave a gap.
- `H`, `r_lip`, `r_waist`, `flare_k`, `dome_z`, `corner`: the bell's shape and size.
  Rerun `make_photo_sheet.py` to update the photo sheet.
- `pocket_edge`, `pocket_top`, `arch_h`: the frame around each photo, and the photo's
  arch.
- `tab_*`, `hole_d`: the hanger.

## Rebuilding

```sh
openscad -o stl/bell_photo_ornament.stl bell_photo_ornament.scad
python3 make_photo_sheet.py   # photo_sheet_4x6.svg / .png / .pdf, from the .scad outline
```
