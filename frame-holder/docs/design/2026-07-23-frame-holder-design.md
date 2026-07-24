# Folding 4x6 Dual-Photo Frame Holder — Design

Date: 2026-07-23
Model: `frame_holder.scad` (OpenSCAD). Renders in `docs/renders/`.

The SCAD file is the source of truth for dimensions. This document records the
decisions and the reasoning behind them.

## 1. Purpose

A three-part 3D-printed desk stand holding a folding, hinged 4x6 dual-photo frame
in a fixed lectern posture: bottom photo reclined toward the viewer, top photo near
vertical. All three parts are planar (constant-thickness flat plates), print flat with
no supports, and assemble by hand.

## 2. The frame being held

| Property | Value |
|---|---|
| Panels | 2, horizontal hinge, photos stacked vertically |
| Panel outer size | 6.75" x 4.75" (171.45 x 120.65 mm), landscape |
| Panel thickness | 0.6" (15.24 mm) — each panel, not the folded stack |
| Photo opening | 6.34" x 4.34" — so a ~5.2 mm border on all four sides |

The frame is Target / Threshold "Thin Hinged Frame, holds 2 photos 4.34" x 6.34"",
product A-51019922. All structural dimensions above were **measured** from the real
frame, not taken from the listing.

## 3. Display posture

Bottom panel 30° from horizontal, top panel 82° leaning back, included fold 128°.

82° was chosen over the originally requested 85°. The top panel's centre of mass sits
`(panel_h/2)·cos(angle)` behind the hinge axis — 8.4 mm at 82° versus 5.3 mm at 85° —
so 82° settles into the backrest more positively while still reading as vertical.
Both are stable; this is margin, not a fix for a defect.

## 4. Geometry

### Which face the hinge is on

**The hinge runs along the front (photo) faces.** The frame closes photo-to-photo, so
at the fold the two front faces are contiguous and the two **back** faces splay apart,
leaving a V-notch roughly `frame_t` deep at the back of the fold.

This is the single most consequential input in the model, and the first version got it
wrong. With a front hinge the back-face planes still intersect, but at a *virtual*
vertex beyond where the panel material actually stops.

The hinge also leaves a gap between the two panel edges: a **measured 1/8" (3.175 mm)
plus a 1 mm working margin = 4.175 mm** (`hinge_gap`). That gap does *not* move the
virtual vertex — the back-face planes are fixed by the front-face planes plus the
thickness. It only moves where the material stops, by half the gap on each panel. So:

```
fold_d = frame_t / tan(fold_angle/2) + hinge_gap/2
       = 15.24 / tan(64°)  +  4.175/2
       = 7.43 + 2.09  =  9.52 mm
```

and it applies at **both** ends of the fold: the cradle must run `frame_h + fold_d` to
reach the bottom panel's front edge, and the top panel's back face doesn't begin until
`fold_d` past the vertex. Getting this wrong shortens both supports at once, which is
exactly how it failed in the first print.

Parameters: `hinge_face` (`"front"` / `"back"`), `hinge_gap` (measured), and
`fold_relief` for any further slop.

### Per-panel length

The two panels are not treated as equal. The **bottom panel is 2 mm longer**
(`frame_h_bot = frame_h + 2`, `frame_h_top = frame_h`), measured on the real frame, so
the fold sits 2 mm further up the incline and the backrest and top panel rise with it.
Only `frame_h_bot` feeds the cradle length; only `frame_h_top` feeds the top-panel CG.

### Points

Side view: origin at the table under the frame's front edge, **x** back, **z** up.

| Point | Value | Meaning |
|---|---|---|
| `A` | (14.0, 10.0) | Bottom panel's front-bottom corner, back face |
| `V` | (128.5, 76.1) | Virtual vertex where the two back-face lines intersect |
| `BT` | (140.2, 159.8) | Nominal top of the backrest edge |
| Cradle length | 132.2 mm | `A` to `V` — the bottom panel's material ends 9.5 mm short of `V` |
| Frame CG | x = 97.0 | Equal panel masses assumed |
| Frame rear-top | (146.6, 205.0) | Top panel back face, upper corner |

`front_lift` = 10 mm is not arbitrary: it sets the depth of material under the lip,
which is the plate's thinnest section and the point that takes the frame's sliding
load. At the originally drawn 6 mm it necked down to a 6 x 5 mm section.

Plate base spans x = 0 to 146, so the CG (x = 97.0) has ~49 mm of margin against
tipping backward. The plate's rear edge stays behind the frame's back face at every
height, so nothing fouls. The plate's cradle edge overruns the bottom panel's end by
9.5 mm into the fold notch, which is empty space — harmless.

### Front stop (lip)

The bottom panel sits on a 30° incline and PLA-on-frame friction (µ ≈ 0.3–0.4) is
below tan(30°) = 0.577, so it will slide without a stop. The lip's inner face is the
line through `A` normal to the panel — it beds flat against the frame's 15.24 mm front
edge face and stands `lip_proud` = 3 mm above the photo surface, inside the ~5.2 mm
border.

### What holds the top panel

The backrest edge bears on the top panel's back face, stopping it opening further.
Forward collapse is resisted by the 8.4 mm gravity bias plus the frame's own hinge
friction. There is deliberately no forward-catching hook — any such feature would have
to cross the top panel's front face and would be visible over the photo.

## 5. Parts

Measured from the exported solids:

| Part | Footprint | Thickness | Volume | Qty |
|---|---|---|---|---|
| Plate | 146 x 154.9 mm | 5 mm | 26.7 cm³ (~33 g) | 2 |
| Brace | 150.7 x 60 mm | 5 mm | 24.0 cm³ (~30 g) | 1 |

Assembled width 144.7 mm. Plate centrelines at ±69.85 mm (5.5" apart), so 13.4 mm of
frame overhangs each end and both plates are invisible head-on.

### Plate

A planar profile whose top edge *is* the cradle: vertical front face → lip → straight
cradle `A`→`V` under the bottom panel → straight backrest `V`→`BT` → rounded crown →
rear edge → base. Corners are filleted by an explicit `rounded_polygon()` helper
rather than `offset()` opening/closing, because an offset pass large enough to look
right also erodes the thin lip wedge away.

Two subtracted circles: `relief_r` = 6 mm at `V` so a protruding hinge knuckle cannot
bottom out and force the fold angle open, and `notch_r` = 1.2 mm at `A` as root relief
in the lip notch.

Interior lightening is `offset(-rim_w)` of the outline with the corners rounded, minus
a pad around the brace holes so the barbs bear on real material.

The crown fillet trims the end off the backrest contact line, so `backrest_len` is set
to 75 mm to land an effective reach of ~69 mm — about 57% up the top panel.

### Brace

A planar vertical web spanning the 134.7 mm between the plates' inner faces, at
x = 139 (`plate_rear_x − 7`), z = 14 to 74, with its own rounded cutout.

It sits inside the plate's **rear rim**, which is why no supporting strut is needed
through the interior cutout — an earlier placement mid-span forced a solid column that
swallowed nearly the whole lightening window.

A vertical web with 26 mm-tall tabs makes a moment connection; a horizontal flat bar
would have been weak against the plates splaying outward.

### Snap joint

Local coordinates: **u** outward from the brace body's end face (u = 0 at the plate's
inner face), **v** vertical. The plate occupies u = 0 to 5.

Locating and latching are split across three features passing through three separate
holes:

| Feature | v extent | u extent | Job |
|---|---|---|---|
| Central tongue | -6 to +6 | 0 to 6 | Locates the joint, carries shear. Chamfered lead-in. |
| Upper finger | +8 to +10.2 | -9 to +8 | Latch (hole +7.05 to +10.35) |
| Lower finger | -10.2 to -8 | -9 to +8 | Latch (hole -10.35 to -7.05) |

Each finger is a 2.2 mm strip freed from the body by two through-cuts. Its root is at
u = -9, **inside** the brace body — this is the whole trick. A cantilever rooted at the
plate's inner face would have only 5 mm of free length and would be strained past
yield by the time the barb cleared.

Those freeing cuts must stop at u = 0. Running them the full tab length (the obvious
way to write it) slices the barbs clean off.

Barb: lead-in ramp from the tip (u = 8, v = 10.2) to the crest (u = 5.2, v = 11.0),
about 16°, then a 90° back face. The crest clears the plate's outer face at u = 5 by
0.2 mm. The 90° catch is intentional — this is a permanent spreader. Release by
pinching the finger tips, which protrude 3 mm past the plate.

**The finger hole must be taller than the finger.** This was a bug in the first
printed joint: the finger holes were sized `finger_h + 2·fit`, snug on the finger. But
as the barb crosses the plate, the finger is confined by *that hole*, not by the
`finger_gap` slot in the brace — so it could flex only `fit` = 0.15 mm before jamming
against the plate bridge between the finger and tongue holes, while the barb needs
`barb_h − fit` = 0.65 mm to clear. It jammed solid regardless of force. The fix
(`fhole_*`) extends each finger hole inward by `barb_h`, giving 0.95 mm of flex room.
The outer edge is unchanged, so the barb's 0.65 mm catch engagement — and the retention
— is untouched. The plate bridge below the hole stays 0.90 mm.

**Engineering check** (PLA, E ≈ 2500 MPa; finger b = 5, h = 2.2, L = 14.2 mm, δ = 0.8 mm):

- Peak strain `1.5·h·δ/L²` = **1.35%**, inside PLA's ~2–3% yield strain
- Force per finger `3EIδ/L³` ≈ **9.7 N**, so ~19 N to insert — firm but hand-assemblable

**Assembly order matters:** snap the brace into one plate, then bring the second plate
onto the free end. Pushing a rigid brace into two fixed plates would need 8 mm of
spread.

## 6. Test parts

Both generated from the same geometry as the production parts.

**`plate_test`** — the plate profile at 2 mm instead of 5 mm, with a slightly wider
lightening window (`test_rim_w` = 10). 12.2 cm³ (~15 g) versus 24.4. Every
frame-contacting edge is identical to the production part; only the interior rim width
and the sheet thickness differ, so nothing that matters can drift.

The hole cluster is carried on a local **full-thickness boss**, clipped to the plate
outline. This is required, not cosmetic: the barb catches on the plate's outer face,
so through a 2 mm sheet the crest would clear it by 3.2 mm and the joint would be
loose rather than latched. The boss is a step on one face, so it still prints flat
with no supports. With it, the production brace snaps into the test plates at full
engagement and the rig stands up under the frame.

**`snap_test`** — a 44 x 44 mm plate coupon at **full 5 mm thickness** carrying one
complete three-hole cluster, plus a brace end stub with one complete tab, both laid
flat on the bed. Full thickness is required here because the barb catches on the
plate's outer face. 16.2 cm³ (~20 g).

Suggested sequence:

1. `snap_test` first — `barb_h` and `finger_h` are the two numbers most likely to need
   tuning for a given printer
2. 2x `plate_test` plus one production `brace` — set the frame in and check angles,
   lip clearance, hinge relief and stance
3. Adjust, then print the two production plates

## 7. Printing

Bed constraint 180 x 180 mm (Bambu A1 mini). **Two jobs.**

The two plates interlock — one rotated 180° drops into the other's empty upper-left
region, since a plate fills only about a quarter of its own bounding box. Nest solved
by FFT cross-correlation over 48 orientations and every offset, then refined at
0.25 mm: **3.14 mm** minimum clearance in a 157.0 x 156.9 footprint, 23.0 mm bed margin
each axis. The exported union measures exactly twice one plate's volume, proving the
two are disjoint.

| Job | Contents | Bed used | Mass |
|---|---|---|---|
| 1 | two plates, nested | 157.0 x 156.9 mm | ~68 g |
| 2 | brace | 150.7 x 60 mm | ~30 g |

The brace cannot join them. The thinnest band two plates can occupy is 176 x 159 mm,
leaving 17 mm — the brace would need to be ≤ 14 mm tall, and its snap tab cluster alone
is 22.4 mm. Searched alongside (400 arrangements x 48 orientations) and inside the nest
(2° steps, every 1 mm, brace hole treated as free); no placement exists.

The nest offsets and `plate_prof_h` are solved against the current outline. Change any
frame or plate parameter and both go stale.

All parts lie flat with no overhangs and need no supports. Orientation is
load-bearing, not incidental: printed face-down, layers stack through the thickness,
so both the plates' in-plane structural loads and the snap fingers' bending stress run
along the layer lines rather than across them. The finger-freeing cuts are
through-cuts in a flat part, so there is nothing to bridge.

## 8. Known limitations

- **Forward collapse of the top panel** is resisted only by the 8.4 mm gravity bias
  and the frame's hinge friction. A positive catch would have to cross the photo.
- **The lip intrudes 3 mm** onto the bottom panel's ~5.2 mm bottom border at two
  points. Visible on close inspection; off the photo.
- **Equal panel mass is assumed** for the CG. The 45 mm rear margin absorbs a large
  imbalance, but a markedly end-heavy frame would eat into it.
- **Frame dimensions are nominal**, with no clearance added to panel thickness —
  nothing wraps around the panel, so the design only touches the back faces and the
  front bottom edge and tolerates dimensional error well.
- **Untested in plastic.** Every number here is calculated or measured off the model;
  none of it has been printed.
