# Build log

## 2026-08-16 — clip_fit settled at 0.20; variants now self-identifying

Printed all three clips plus the dummy. **The tightest, `clip_fit` = 0.20, slides on snugly
without forcing** — set as the production value and `stl/sensor_clip.stl` re-exported.

The trial also exposed a flaw in how it was run: **three clips 0.2 mm apart in span are not
tellable apart once printed.** Marking them afterwards is guesswork, which nearly wasted the
print. Added `clip_mark`, cutting that many Ø1.4 x 0.5 mm dimples into the face that ends up
UP on the bed (the body's +X maps to print +Z), so a variant set is identifiable by touch.
Verified each dimple removes 0.76 mm³ against a predicted 0.77.

The production clip carries no dimples; `clip_mark` is set only when exporting a sweep.

General lesson for any future parameter sweep here: **if variants differ by less than about
a millimetre, mark them in the model.** Not on the bed afterwards.

## 2026-08-16 — clip friction trial + printable SHT40 dummy

`clip_fit` (slack over the cradle walls) is the one number geometry cannot settle, so three
clips are exported to `stl/variants/` at 0.20 / 0.30 / 0.40. Each 0.1 mm widens the U's span
by 0.2 mm — measured at 27.18 / 27.38 / 27.58 mm, confirming the parameter does what it
says. All three are single watertight bodies at min z = 0.

Verified the two ends of that range rather than assuming the middle is representative:

| | |
|---|---|
| clip @ 0.20, seated on cradle | 0.00 mm³ — the tightest still seats |
| clip @ 0.20, mid-slide at x=10 | 0.00 mm³ — the tightest still slides |
| clip @ 0.20, gripping the board | 10.0 mm³ |
| clip @ 0.40, lifted 1 mm | 1.53 mm³ — the loosest still retains |

Added `sht40_dummy`: a printable stand-in with the correct outline, hole pattern and
connector blocks, so the joint can be exercised before the sensor arrives. It measures
25.4 × 17.78 × 4.5 against Adafruit's model at 25.4 × 17.78 × 4.53.

**Its limit is worth stating plainly:** the dummy is built from the same `sht_*` parameters
as the cradle, so it can confirm the clip slides, grips and clears the connectors — it
cannot confirm those parameters match the real board. That check only happens when the
SHT40 lands.

## 2026-08-16 — the clip slides on; it was never going to snap on from above

Second catch off the render, again before printing. The clip was drawn as a top-entry snap,
but its legs are ~5.6 mm long and 2.2 mm thick, so spreading them the 0.4 mm needed to clear
the walls takes **about 12 kg**. They would break before they spread — the same lesson as
the cradle barb and the socket tabs, this time reached by arithmetic instead of by breaking
a print.

So it is now an explicit **slide-on**, which suits the design better anyway: the wall grooves
were already full-length rails, so the joint needs **no flex at all**. The clip enters at the
walls' open outboard end and slides inboard until it butts the groove's closed end. The
groove now starts at `clip_x`, so the stop and the clip's seated position are derived from
one number and cannot disagree. A lead-in chamfer on each rail finds the groove mouth.

Retention is now: rails in grooves hold it down and sideways, the stop halts insertion, and
friction from the pads' 0.25 mm preload resists sliding back out. If that proves too free in
plastic, a light taper on the groove is the fix — and the clip is 0.7 cm³ to reprint.

**New check class: the slide path.** A clear seated position is not sufficient for a part
that arrives by sliding, so `sht40-clip-slide-path-*` verifies clearance at three points
along the travel, not just at the end of it. That is the same blind spot as checking a
seated lid without checking it can enter the groove.

## 2026-08-16 — clip could not seat: bar landed on the cradle walls

Caught by eye off the render, before printing. The clip's bar underside was derived from the
CONNECTOR height (`sht_conn_h + 0.8` = 3.7 mm above the board top) while the cradle walls
rise `wall_up` = 4.5 mm. **The bar landed on the wall tops 0.8 mm before the pads reached
the board** — the clip could not seat at all.

`clip_bar_gap` now derives the bar from `wall_up`, and an assert fails the render if it is
not positive.

### The check hid it, for the third time

`sht40-clip-engages-cradle` **read 14.2 mm³ and passed a 0.5–60 range — and that 14.2 was
the collision.** Same failure as the socket detent (60 mm³ tolerance, 28.9 mm³ reading, joint
physically impossible) and the lid snap (60 mm³ tolerance, 3.4 mm³ reading, ridge wedged on
the flanks). Three for three: **a tolerance widened to accommodate an intended interference
is wide enough to hide an unintended one.**

Replaced with the pair that has worked everywhere else:

- `sht40-clip-seated-on-cradle` (tol 1.0, reads 0.0) — seated, the clip touches the cradle
  almost nowhere; its bumps sit inside the grooves with clearance
- `sht40-clip-retains-when-lifted` (reads 2.0 mm³) — lift it and the bumps run into the
  groove's top edge

Retention is modest by design: the pads' 0.25 mm preload pushes the clip up until the bumps
bear on the groove edges. `clip_bump` is the knob, and the clip is 0.7 cm³ to reprint.

## 2026-08-16 — arm redesigned for the Adafruit SHT40 (4885)

Dimensions come from **Adafruit's own 3D model**, not a drawing or a photo:
`Adafruit_CAD_Parts/"4885 SHT40 Sensor"`. Vendored to `docs/reference/` so the fit checks
run against the manufacturer's actual geometry. It is the standard 1.0 × 0.7 inch STEMMA QT
outline, so every figure lands on an imperial value:

| | |
|---|---|
| Board | 25.4 × 17.78 mm, PCB 1.6 mm |
| Mounting holes | **four**, Ø2.5, inset 2.54 from each edge → 20.32 × 12.70 pattern |
| STEMMA QT | both short ends, central band y ±2.97 only, 2.9 mm above the PCB |

Two properties of this board drove the design:

- **Four holes means rotation is already solved.** The pair at one end, 12.70 mm apart,
  fixes the angle by itself, so the DHT22's anti-rotation rails are gone.
- **The outer ~4 mm of each long edge is clear end to end**, because the connectors sit in
  the central band. The cradle supports and clamps those strips while the connectors and
  the sensor breathe through an open central channel.

### Retention: a separate clip, which is the important change

The cradle is now **entirely passive** — pips locate, rails support, nothing flexes. All
retention lives in a **separate clip**. Two reasons, and the second is the one that matters:

1. It is a few minutes to reprint, so tuning it is cheap.
2. **A separate part can be printed in its own orientation.** The clip is a flat U, printed
   lying down, so its legs flex *within* the layer plane. Every sprung feature that failed
   on the DHT22 build failed because it was printed standing in Z and bent across its layer
   lines. This one cannot.

The clip sits **outboard of the inboard connector** rather than over the pips. Clamping over
the pips is marginally better mechanically, but it buries the STEMMA QT socket under the
clip's bar with 0.8 mm of headroom — the cable could then only be fitted before the clip.
The support rails run the full grip length, so the clamp path is still clip → board → rail.
Caught by looking at the render with the real board in place, and now held by a check.

### Checks, against the manufacturer's model

- `sht40-board-clears-cradle` — 0.0 mm³; the board drops on without fouling
- `sht40-clip-grips-board` — 8.9 mm³; the clip actually grips rather than merely touching
- `sht40-clip-clears-connectors` — 0.0 mm³; neither connector is buried
- `sht40-clip-engages-cradle` — 14.2 mm³; the bumps seat in the wall grooves

Parts: `arm` 7.5 cm³ (was 7.0), `sensor_gauge` 2.0 cm³, `sensor_clip` 0.6 cm³. The tray, lid
and their coupons are untouched — the cradle end really was the only sensor-specific
geometry in the model.

## 2026-08-16 — the DHT22 build works; baseline complete

Reprinted tray and lid with the derived groove and the taller ridge. **The lid snaps, and
the whole assembly works.** Every interface is now confirmed in plastic rather than only in
the model:

| Interface | Confirmed |
|---|---|
| DHT22 board → cradle | yes (barb broken on the first print, taped; rails + post still locate it) |
| Arm tenon → tray socket | yes, `socket_fit` 0.4 mm |
| Pi → locating pips | yes |
| Pi held down by lid pads | yes |
| microSD through the notch | yes, after the z fix |
| GPIO jumpers under the lid | yes, `jump_stack` 24 mm measured |
| Lid snap → tray ridge | yes, after the groove was derived from the ridge |

This is the **DHT22 baseline**. Worth stating plainly what the exercise cost and taught,
because the pattern repeated:

- **Three sprung features failed in plastic, all for print-direction reasons.** The cradle
  barb broke across its layer lines; the socket's cantilever tabs fused because freeing them
  needed horizontal slots in a part that prints bore-horizontal; the lid snap could not
  enter its own groove. Only the third survived, once its groove was derived from its ridge.
- **Every one of those passed a check first.** In each case the tolerance had been widened
  to accommodate an intended interference, which left it wide enough to hide an unintended
  one. The fix each time was a *pair* of checks — must seat freely AND must resist coming
  apart — rather than a single looser one.
- **Renders never found any of it.** Overlapping solids merge in a render; only explicit
  solid intersections and measured stack-ups caught these.

### Next: SHT40 replacing the DHT22

The DHT22 was destroyed in wiring; an **SHT40** is on order. That is an accuracy upgrade as
well as a replacement — ±0.2 °C typical against the DHT22's ±0.5 °C.

The enclosure is unaffected: the tray, lid, coupons and the arm's tenon/groove all stay as
they are. Only `sensor_cradle()` and the `board_*` / `mnt_*` parameters need revisiting,
since the SHT40 breakout is a different outline with a different mounting-hole pattern. The
arm's cradle end is deliberately the only sensor-specific geometry in the model, which is
what makes this a small change rather than a redesign.

Do **not** carry over the split snap-post: it is the feature that broke, and a new sensor
board is the moment to replace it with something that does not flex across layer lines.

## 2026-08-15 (night) — tray + lid printed: they fit, but the lid would not snap

Root cause, and it was not "a bit loose" — **the ridge could not enter the groove at all.**

The ridge tapers at 45°, so where it crosses the lid's lip plane its cross-section was
`2 × (ridge_base_half − lid_fit)` = **2.4 mm tall**, while the groove opening was hardcoded
at **2.0 mm**. The lid rode up on the ridge flanks and never dropped in. Compounding it,
engagement was only `snap_ridge_h − lid_fit` = 0.5 mm, of which print tolerance on two
mating surfaces can eat most.

Fixes:

- **The groove is now DERIVED from the ridge** (`groove_half = ridge_base_half − lid_fit +
  groove_clear`) instead of hardcoded, so the two cannot disagree again. A global `assert`
  fails the render if the ridge is ever taller than the groove.
- `snap_ridge_h` 0.8 → **1.2**, so engagement is **0.9 mm** rather than 0.5.
- `lid_wall` 2.0 → **2.5**: the deeper groove left only 0.8 mm of skirt behind it.

Also fixed a variable-ordering bug introduced by the above: `groove_half` referenced
`lid_fit` eleven lines before it was defined, so it silently evaluated to undefined and the
lid rendered empty. `lid_wall`/`lid_fit` now sit above the snap block.

### The check that should have caught this, and why it didn't

`lid-on-tray` had a **60 mm³** tolerance and read 3.4 mm³ — the signature of a lid *wedged*
on the ridge flanks — and passed. That is the same failure mode as the socket detent: a
tolerance loose enough for an intended interference is loose enough to hide an unintended
one.

Replaced with a pair that pins the joint down, because neither alone is sufficient:

- **`lid-on-tray-seated`** (tol 2.0, reads 0.0) — a seated lid must touch almost nothing.
  The old jammed geometry would fail this.
- **`lid-snap-retains-when-lifted`** (reads 54.3 mm³) — lift the lid 1.5 mm and the lip must
  collide with the ridge. That collision *is* the snap; zero would mean the lid falls off.

Parts grew slightly: tray 14.2 cm³, lid 31.6 cm³ (taller skirt + thicker wall), lid_gauge
3.7 cm³.

## 2026-08-15 (night) — lid_gauge was measuring the wrong thing; rebuilt

Caught before it misled anyone: the first `lid_gauge` cut the skirt off ~7 mm above the
groove and stood it on a foot. But on the real lid the skirt hangs from the **top plate**,
putting the groove ~28 mm from its root. Cantilever stiffness goes as 1/L³, so that gauge
was **~67× stiffer** than the part it was meant to predict — it would have reported "far too
tight" on a snap that is fine, and prompted a pointless loosening of `lid_fit`.

Rebuilt as a full-height slice: skirt free edge up through a 24 mm strip of top plate, so it
is rooted the way the real skirt is. No foot needed — the flip puts the plate on the bed,
which is how `lid()` prints anyway. 2.91 cm³.

Residual limit, recorded rather than hidden: it is still a straight slice with no corners,
and the real top plate is a large diaphragm, not a 24 mm strip. It will read somewhat
stiffer than the real lid. "Firm but it clicks" is a pass.

Added `docs/renders/full-assembly-{apart,seated}.png` — tray, Pi with its GPIO jumpers,
microSD through the notch, arm with the DHT22, and the lid.

## 2026-08-15 (night) — printed tray finds two real errors: SD notch and lid height

### microSD notch was at the wrong height (my error)

The card fouled the wall. The notch ran from the board **underside upwards** — but the
microSD holder is on the Pi's **underside**, so an inserted card sits *below* the PCB, not
level with it. Notch was at z 7.0–11.0; the card is at z ≈ 5.1–6.1, so it hit solid wall
about 1 mm below the opening. Now anchored below the board underside (`sd_below` 2.8,
`sd_above` 0.8 → z 4.2–7.8) and centred on the **board's** centreline rather than the
tray's — they differ by `board_fit`, and an 11 mm card in a 14 mm notch has little to spare.

### Lid was too short for the GPIO jumpers

`lid_clear` was 20.0, a guess. Measured on the real leads: **24 mm from the PCB top surface
to the top of the jumper**. Now `lid_clear = jump_stack + wire_bend` = 29.0, so there is
5 mm above the jumpers for the wire to turn over. Lid grows from 25.4 to 34.4 mm tall.

### And a knock-on the jumper check caught

Raising the lid was not enough on its own: the hold-down pads **flare to Ø8 near the
ceiling**, and that flare leaned out over the GPIO header, which sits only ~3.5 mm from the
mounting holes. The flare exists purely for bed adhesion (the lid prints closed-top-down, so
that wide end stands on the bed), so it now starts **above** `jump_stack` and the pad is
straight Ø6 for the whole height the jumpers occupy.

Two new assembly checks, both of which would have caught these before printing:
`sd-card-clears-notch` (a card solid must pass the tray) and `lid-clears-gpio-jumpers`
(the header footprint extruded to `jump_stack` must not touch the lid). Suite passes.

**The printed tray is superseded** — it has the old SD notch and needs a reprint.

## 2026-08-15 (night, later) — fit_coupon passes: the Pi-side interface is confirmed

Printed `fit_coupon` and checked it against the real Pi 4. **Go.** The locating pip enters
the mounting hole with the intended play, the board sits flat on the Ø6 collar, and the
board edge clears the SD-side wall.

Worth recording *which* corner this tests: the coupon represents the corner where the
**microSD short edge (walled)** meets the **A/V long edge (open channel)** — the only corner
where a walled edge meets an open one, and so the only one with anything to check. The other
three are either fully open or repeat the same wall clearance.

Note the coupon on the bench is the pre-`board_fit` version, whose standoff sits 0.4 mm
closer to the wall than the tray's. It therefore tested a *zero-clearance* board edge and
still passed, which makes the tray's 0.4 mm strictly easier.

Added `docs/renders/pi4-on-coupon-{apart,seated}.png` and
`docs/renders/cradle-board-{apart,seated}.png`. Connector positions in the Pi model are
**schematic** — only the 85 × 56 outline and the 58 × 49 hole pattern are to spec, and those
are the only things the coupon tests.

Still open: the lid snap. `lid_gauge` needs pressing onto the printed tray's ridge.

## 2026-08-15 (night) — lid_gauge added; tray goes without a coupon

Decided to skip further coupon work before the **tray**: its remaining unknowns are
bridging over the socket bore and the vent slots, which no coupon predicts better than the
tray itself, and the `fit_coupon` checks left (a plain tapered pip with 0.2 mm clearance,
a hole pattern straight off the Pi drawing) are low risk.

The **lid** is a different matter. Its snap is the **last sprung feature in the design, and
sprung features are 0-for-2 here** — the cradle barb broke across its layer lines, the
socket tabs fused — and the snap was flagged as firm (2.8 mm engaging skirt) when written
but has never been tested in plastic.

Useful sequencing: **the tray carries the ridges**, so it can be printed first and then used
as the test fixture. Added `lid_gauge`: one segment of the +Y snap skirt, produced as an
`intersection()` of `lid_assembled()` rather than re-modelled, so it cannot drift from the
real lid. Verified — the band cut from the real lid and the gauge minus its foot are both
584.00 mm³, difference 0.00. It is flipped exactly as `lid()` is, so the groove's overhang
faces the way it will on the real part; printed in any other orientation it would predict
nothing.

0.78 cm³. Order is now: tray → lid_gauge (against the printed tray) → lid.

## 2026-08-15 (evening) — socket detent abandoned; back to a plain keyed fit

Printed `socket_gauge`. **The arm would not enter at all.** Two independent causes:

1. **Sign error in the bump placement (mine).** The detent bumps were positioned at
   `wall + bump_d/2 - bump_proud` when the correct expression is
   `wall + bump_proud - bump_d/2`. They protruded **1.95 mm into the bore instead of
   0.45 mm**, leaving a 6.5 mm clear gap for a 10 mm tenon — 3.5 mm of interference. No
   print orientation could have fixed that.
2. **The cantilever tabs fused in the print.** Freeing a tab needs ~1 mm slots above and
   below it, and the socket necessarily prints with its bore *horizontal* because it is
   part of the tray and the tray prints floor-down. Those slots are horizontal gaps and
   they closed up.

Rotating the gauge onto another face does fix the slots — and simultaneously destroys the
point of the gauge, which is to reproduce how the socket prints **as part of the tray**.
A gauge printed in an orientation the tray can never use predicts nothing. Noted in the
model and the README.

**Decision: no third attempt at a sprung joint.** The socket is now a plain keyed friction
fit — close bore plus the key rib, nothing that flexes. That is two sprung features
abandoned on print evidence (the cradle barb broke across its layer lines; these tabs
fused), and the arm carries nothing but its own weight. If the fit is loose, the honest fix
is a fastener, not more geometry.

**Consequence, in the good direction:** removing the tenon's detent grooves returns the arm
to exactly the solid already printed. Verified by sampling — 0 of 40,000 points disagree,
with identical bounding box and volume, for both `arm` and `sensor_gauge`. **Nothing needs
reprinting.**

Two test-harness lessons, both applied:

- `arm-in-socket` had a **60 mm³ tolerance to "allow the detent press", and that masked the
  bug** — it passed at 28.9 mm³ while the joint was physically impossible. With a plain
  socket the seated arm should touch nothing, so the tolerance is now 2 mm³ and the check
  reports 0.0. A tolerance loose enough to accommodate an intended interference is loose
  enough to hide an unintended one.
- The gauge's back stop sat *inside* the bore, eating its first 2 mm, so it would have
  reported a shallower fit than the tray gives. Moved behind the socket.

**Confirmed.** Reprinted `socket_gauge` as exported; the arm's tenon slides in and seats
snugly. `socket_fit` = 0.4 mm is the right clearance for this printer, and the plain keyed
friction fit is enough to hold the arm — no fastener needed after all. **The arm joint is
done**, using the arm already printed.

Next: `fit_coupon`, then tray + lid.

## 2026-08-15 (later still) — zero fasteners; two socket bugs caught before printing

### Field evidence: the cradle's barb snapped off after ONE insertion

The DHT22 cradle fits perfectly but its snap-post barb broke on the first insertion.
Cause is **print orientation, not force**: the post stands in Z, so its 0.875 mm prongs are
stacks of layers, and flexing them sideways loads the bond *between* layers — the weakest
direction in an FDM part. Taped for now; the rails still fix the board's angle and the post
still locates it, so the cradle remains usable and is left **unchanged** (`sensor_gauge` is
byte-identical to the printed part).

This arrived just before four of the same barbs were committed to the Pi mount, and killed
that plan: four posts must flex simultaneously against a rigid PCB, so force per post is
higher, and one broken barb of four leaves the board loose.

### Pi mount: locating posts + lid hold-down pads (no screws, nothing flexes)

Standoffs keep their Ø6 × 5 mm collar and gain a short **locating pip** (Ø2.5), shorter than
the PCB is thick so it never stands proud. Retention moved to **four tapered pads on the
lid's underside**, concentric with the standoffs, reaching 0.3 mm below the board top. Clamp
path is pad → board → collar: no bending moment, no flexing feature anywhere. Each pad is
bored so it bears on the PCB, not the pip. Cost: the Pi is only held with the lid fitted.

### Two socket bugs, both found by measurement, both invisible in renders

1. **The bore was a fully enclosed cavity** — capped outboard by `wall`, closed inboard by
   the tray wall. The arm could not be inserted at all, and its bar intersected solid tray
   by 100 mm³. Renders never showed it because overlapping solids simply merge.
2. **The socket's underside was an unsupported overhang** — nothing below z=2.0, then a full
   10 × 12 mm slab at z=2.4, in a design that claims support-free.

Fixed: the bore now runs through to the outboard face (blind inboard, closed by the tray
wall, which also gives the tenon a positive depth stop), and the socket is built from z=0 so
it prints off the bed.

### Arm socket: M3 set screw → rounded detent

Each socket side wall is freed into a cantilever tab carrying a round bump that drops into a
matching vertical groove in the tenon. The tenon stays full-section and keeps its key rib,
so lateral and roll stiffness are unchanged — only the axial lock became a click. Round
bumps keep the arm hand-removable.

**The printed arm predates the detent grooves.** It still inserts and is held by friction
(the tabs ride the flat tenon sides), but it will not click until the arm is reprinted.

### Test harness now checks assembly, not just parts

Added `tests/check_fit.py`, run by `check_all.sh`: solid-intersection checks for pairs that
must not overlap, engagement checks for joints that must, and an unsupported-overhang scan.
**The overhang check was itself validated against the old buggy socket** — first attempt
reported zero because the reconstruction accidentally grounded the slab; corrected, it finds
208 unsupported columns on the old geometry and none on the new. Also added `socket_gauge`,
a few-gram print of the socket alone, so the detent can be proven before the 8-hour tray.

All six parts render single, watertight, min z = 0; suite passes.

Next: print `socket_gauge` and check the detent against the arm, then `fit_coupon`, then
tray + lid. Reprint the arm when convenient to get the detent grooves.

## 2026-08-15 (later) — first gauge printed; single-hole board, wobble fixed

**Printed `sensor_gauge` — and it caught two things, which is the whole point of it.**

1. **Wrong board.** Not the SEN0137 assumed below. The board in hand measures
   **29.52 × 13.0 × 1.6 mm with ONE Ø2.85 mm hole, 7.2 mm from the cable end**. A single
   hole can't fix the board's angle, so the two-post cradle is replaced by **one snap-post
   plus two anti-rotation side rails** that capture the board's width. Rails stop flush
   with the seated board's top face so it still drops in from above onto the barb.
2. **Post wobbled laterally.** A 2.6 mm shaft in a 2.85 mm hole, minus print shrinkage on
   the post, left real slop. `post_shaft_d` 2.6 → **2.75** (0.10 under the hole). Barb
   left at 3.4 — retention was never the complaint.

Layout confirmed visually against `docs/renders/sensor-cradle-fit.png` before reprinting.
`arm` is now ~106 × 17.3 mm (was ~106 × 26). All five parts still render single,
watertight, min z = 0; `tests/check_all.sh` passes.

**Both printed and confirmed.** Reprinted `sensor_gauge` — board seats firm, no lateral
play, no rotation, so 2.75 mm shaft + 0.3 mm rail clearance are the right numbers. Then
printed the full `arm`: the post reproduced identically at the end of the longer print and
the board snaps on the same way. Cradle and arm are **done**.

Next: `stl/fit_coupon.stl` against the real Pi, then the production `tray` and `lid`.

Still unmeasured: the white sensor body's footprint and height, and the cable bundle
width. Neither is load-bearing — the sensor cantilevers into open air and the cable is
unconstrained at that end — but they'd let the arm groove be sized properly.

## 2026-08-15 — sensor holder redesigned for the DFRobot SEN0137 (superseded, see above)

The DHT22 in hand is a **DFRobot Gravity DHT22 (SEN0137)** — a flat 41.52 × 22.0 mm
board with the sensor on its face and a 3-pin Gravity cable off its end, not the
chunky drop-in strip the original pocket assumed. Replaced the drop-in `sensor_pocket`
with a **snap-post cradle**: a pad at the arm end carrying two split snap-posts on the
board's own mounting-hole pattern (15.0 mm apart, 10.91 mm from the connector edge,
Ø3.0/M3 assumed). The board clicks on tool-free; its sensor end cantilevers off the pad
into free air and the cable exits back down the arm groove. Dimensions are from the
official DFRobot drawing.

`sensor_gauge` is now the cradle alone (pad + posts), still the first thing to print.
`arm` is now ~106 × 26 mm (was ~104 × 41). All five parts still render single, watertight,
min z = 0; `tests/check_all.sh` passes. The snap-post fit (`post_barb_d` / `post_slot_w` /
`post_fit`, and the assumed Ø3.0 hole / 1.6 mm PCB) is new and unprinted — the reason to
print the gauge first.

Next: print `stl/sensor_gauge.stl`, snap the SEN0137 on, confirm a firm click; then
`stl/fit_coupon.stl` against the real Pi; then the production `tray`, `lid`, `arm`.

## 2026-07-25 — model complete, unprinted

Tray + snap-fit lid + DHT22 sensor arm modeled in `pi4_dht22_enclosure.scad`.
All five printable parts (`sensor_gauge`, `arm`, `tray`, `lid`, `fit_coupon`)
render as single watertight bodies with positive volume and pass
`tests/check_geom.py`. Nothing printed in plastic yet.

**Design change during implementation: lid screws → snap-fit.** The plan
called for a lid closed with 4 × M3 screws into corner bosses on the tray. Once
modeled, the bosses collided with the standoffs and fouled the Pi board — the
board fills the tray too tightly to leave room for both. Switched the lid to a
snap-fit instead: ridge/groove segments on the two walled sides (x-min/SD and
+Y/GPIO), flanking the SD notch and the arm socket. No lid screws or bosses in
the current model. The Pi-to-standoff fasteners (four M2.5 self-tapping
screws) and the arm-in-socket set screw (one M3) are unaffected.

Two things worth flagging for anyone printing this before further tuning:

- **The snap is stiff as modeled** (2.8 mm engaging skirt). Expect a firm push
  to seat the lid on first fit. If it's tighter than wanted, thin the skirt
  (`snap_ridge_h`) or deepen the ridge/groove.
- **Only two of four sides latch.** The two open port-channel sides don't
  snap, so the lid can lift slightly at that free corner. Acceptable for a
  stationary desk unit, not for anything that gets carried around or shipped.

(Superseded 2026-08-15 — the drop-in pocket assumed here was replaced by the
SEN0137 snap-post cradle; see the entry above.)
