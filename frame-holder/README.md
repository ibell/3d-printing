# Folding 4x6 frame holder

Three planar parts that hold a folding, hinged two-photo frame in a lectern
posture — bottom photo reclined 30°, top photo at 82°.

Designed around the Target / Threshold **Thin Hinged Frame** (holds two
4.34″ × 6.34″ photos), product
[A-51019922](https://www.target.com/p/-/A-51019922). All dimensions were measured
from the real frame, so re-fitting to a different frame is a few edits to the
parameter block in `frame_holder.scad` — see *Re-fitting to your frame* below.

Model: `frame_holder.scad`. Design record: `docs/design/`. Renders:
`docs/renders/`.

Everything prints flat, no supports. All STLs in `stl/` are already in print
orientation (Z = thickness) and positioned on the bed, so drop them straight into the
slicer.

## Print plan — Bambu A1 mini (180 x 180)

**Two jobs, not three.** The two plates interlock: rotate one 180° and it drops into
the other's empty upper-left region, since the plate only fills about a quarter of its
own bounding box.

| Job | File | Bed used | Mass |
|---|---|---|---|
| 1 | `stl/job1_two_plates.stl` | 157.0 x 156.9 mm | ~68 g |
| 2 | `stl/job2_brace.stl` | 150.7 x 60 mm | ~30 g |

The nest was solved by exhaustive search (48 orientations, FFT cross-correlation over
every offset), then refined at 0.25 mm. Minimum part-to-part clearance is **3.14 mm**,
with 23.0 mm of bed margin on each axis. The exported union measures exactly twice one
plate's volume, which proves the two are disjoint.

### Why the brace can't join them

Not for want of trying. Three independent checks:

- **Alongside:** 400 candidate plate arrangements tested against 48 brace orientations
  at every position — no fit.
- **Inside the nest:** searched at 2° rotation steps and every 1 mm position, with the
  brace's own central hole treated as free space so a plate may poke through it. No
  placement exists at any angle. The two interior voids are 1,611 mm² each; the brace
  needs 4,793 mm² as a closed 150.7 x 60 loop.
- **Any band at all:** the thinnest strip two plates can be squeezed into, over all
  orientations and offsets, is 176 x 159 mm. That leaves 17 mm, so the brace would have
  to be **≤ 14 mm tall** to share the bed. It is 60 mm, and its snap tab cluster alone
  is 22.4 mm, so no amount of shrinking gets there.

Printing the brace on edge would fit the leftover strip (150.7 x 5 mm footprint) but
would stand the snap fingers' bending stress across the layer lines instead of along
them — the exact failure the flat orientation exists to prevent.

Both plates come off the bed identical. One gets flipped over during assembly — that's
what makes the mirrored nesting free.

## Fit test — for re-fitting to your own frame

The production parts above are printed and confirmed on the frame they were designed
for. If you're adapting the design to a **different** frame, this ladder de-risks the
new geometry cheaply — each step is a small print that rules out a different failure
before you commit to the full ~96 g set.

### 1. `stl/profile_gauge.stl` — ~4 g, 0.4 mm thick

The bare silhouette, 2 layers at 0.2 mm. Lay it against the side of the frame with the
frame folded to its display angle. Solid rather than lightened so it holds its shape.
`profile_gauge_pair.stl` gives you two nested if you want one for each side.

Check the cradle line runs the full length of the bottom panel with the lip landing
just past its front edge, the backrest line sits flat on the top panel's back, and the
corner clears the fold. It will be floppy and may curl slightly off the bed — expect to
hold it flat rather than lay it down.

Change `gauge_layer_h` / `gauge_layers` if your layer height isn't 0.2.

### 2. `stl/fit_test_snap.stl` — ~21 g

A 44 mm plate coupon at full 5 mm thickness plus a brace end stub with one complete
tab. Full thickness matters: the barb catches on the plate's *outer* face, so a thinned
coupon would tell you nothing.

Push the tab in. You want a firm click that holds without slop.

- **Too stiff, fingers creak or whiten** → raise `finger_h` toward 2.0, or drop
  `barb_h` to 0.6
- **Loose, pulls out under a light tug** → raise `barb_h` toward 1.0
- **Won't seat fully** → raise `fit` from 0.15

Calculated target is ~19 N to insert at 1.35% peak strain; PLA yields around 2–3%.

### 3. `stl/link_test.stl` — ~28 g, one job

The whole snap linkage in miniature: a short brace carrying **both** complete tabs,
flanked by two full-thickness plate coupons with the three-hole cluster. The joint
geometry is identical to the real brace (both build from the same canonical tab) — only
the web between the two tabs is shortened, so it prints compact.

Assemble it the way you'll assemble the real thing: **snap the brace into one coupon,
then bring the second coupon onto the free end.** Check for a firm click at each end,
that the barbs hold under a tug, and that the two coupons end up parallel and don't rock
against each other. That last part is what a single-joint coupon can't show you — it's
the linkage doing its actual job of holding two plates square.

Tuning is the same as the snap coupon below (`finger_h`, `barb_h`, `fit`). This
supersedes `fit_test_snap` for most purposes; the single coupon is still there if you
only want to tune one barb's force in the smallest possible print.

### 4. `stl/fit_test_two_plates.stl` — ~33 g, one job

Both test plates nested, 2 mm sheet. The hole cluster sits on a local 5 mm boss so the
brace still latches properly — without it the barb would clear a 2 mm sheet by 3.2 mm
and the joint would be loose rather than latched.

Add `stl/job2_brace.stl` (the production brace, ~30 g — print it once and keep it) and
you have a working rig.

**Assemble in this order:** snap the brace into one plate, then bring the second plate
onto the free end. Pushing a rigid brace into two already-placed plates would need 8 mm
of spread.

The plate's cradle edge deliberately overruns the panel's end by 9.5 mm into the
V-notch at the back of the fold. That gap is expected, not a misfit.

## Re-fitting to your frame

Measure, then edit the block at the top of `frame_holder.scad`:

```
frame_w, frame_h, frame_t     panel outer size and thickness
frame_h_bot, frame_h_top      per-panel length; bottom is treated 2 mm longer
hinge_face                    "front" or "back" - see below, it matters a lot
hinge_gap                     measured gap between the panel edges at the fold
fold_relief                   any further slop at the vertex
ang_bot, ang_top              display posture, degrees from horizontal
lip_proud                     how far the front stop rises above the photo face
```

`hinge_face` is the one that bites. With the hinge on the **front** (photo) faces the
frame closes photo-to-photo, and the two **back** faces splay apart at the fold,
leaving a V-notch about `frame_t` deep. Their planes still intersect, but at a virtual
vertex

```
fold_d = frame_t / tan(fold_angle/2) + hinge_gap/2 = 7.43 + 2.09 = 9.52 mm
```

beyond where the panel material actually stops. The cradle and the backrest both have
to be that much longer to reach anything. Set it wrong and **both** supports come up
short at once — which is exactly how the first print failed.

### If you change anything

`plate_prof_h = 154.941` in the layout block is a **measured** value, not a derived
one, and the nest offsets were solved against the current outline. Change any frame or
plate parameter and both go stale — re-export a single `plate`, measure its height, and
re-solve the nest before trusting `job1_two_plates.stl`.

Re-export:

```sh
openscad -o stl/job1_two_plates.stl -D 'part="job_plates"' frame_holder.scad
openscad -o stl/job2_brace.stl      -D 'part="job_brace"'  frame_holder.scad
```

`part` also accepts `"assembly"` (all parts plus a ghosted frame, for visual checking),
`"plate"`, `"brace"`, `"plate_test"`, `"snap_test"`, `"link_test"`, `"profile_test"`,
`"job_test_plates"` and `"job_gauges"`.
