# Raspberry Pi 4 enclosure with a plug-in sensor arm

A desk enclosure for a Pi 4 Model B temperature node — a tray, a snap-fit lid,
and a plug-in arm that holds the sensor board in free air off the Pi's warm
plume. Prints flat, no supports; PETG recommended.

The arm currently carries an **Adafruit SHT40 (4885)**. It originally carried a
DHT22, which is why the directory is named `pi4-dht22-enclosure`; the tray, lid
and coupons were untouched by the swap, because the cradle at the arm's end is
the only sensor-specific geometry in the model.

Model: `pi4_dht22_enclosure.scad`. Design record: `docs/design/`. Renders:
`docs/renders/`.

## The sensor board — Adafruit SHT40 (4885)

Dimensions come from Adafruit's own 3D model, vendored to `docs/reference/`:
**25.4 × 17.78 × 1.6 mm**, four Ø2.5 mounting holes on a **20.32 × 12.70**
pattern, STEMMA QT connectors on both short ends occupying only the central
5.94 mm of the width.

Two things about that shape shaped the cradle. Four holes means **rotation is
already solved** by the pair at one end. And because the connectors sit in the
central band, the **outer ~4 mm of each long edge is clear end to end**, so the
cradle supports and clamps those strips while the connectors and the sensor
breathe through an open channel.

The board drops onto two locating pips and is held by a **separate slide-on
clip**. Nothing in the cradle flexes. For a different board, set the `sht_*`
parameters at the top of the SCAD.

## Parts

| Part | Role |
|---|---|
| **Tray** | Holds the Pi on four locating posts — no screws; the lid's pads press it down. Carries the SD notch, DHT22 cable exit, floor vents, snap ridges, and the keyed arm socket. |
| **Lid** | Vented top with the LED window and open port channels. Snaps onto the tray — no lid screws. Four underside pads clamp the Pi onto its standoffs. |
| **Arm** | Plugs into the tray socket as a keyed friction fit — no set screw, nothing sprung. Routes the sensor cable in a groove and ends in a passive cradle: two locating pips and support rails, with the board's far end cantilevered into free air. |
| **Clip** | Separate part. Slides onto the cradle walls from the outboard end and clamps the board down. Printed lying flat, so its legs bend within the layer plane. |

**Fasteners, in total: none.** The Pi sits on four locating posts and is clamped
by pads under the lid, the lid snaps onto the tray, the arm is a keyed friction
fit in its socket, and the sensor board is held by the slide-on clip.

Note the Pi is only held down **with the lid fitted** — with the lid off it is
located but free to lift.

## The snap-fit lid

The lid was designed with M3 screws and corner bosses, but the Pi fills the
tray tightly enough that the bosses collided with the standoffs and fouled the
board, so the lid was switched to a snap-fit during implementation — see
`docs/plan/` for the amendment note and `docs/design/` for the reconciled
description.

The lid snaps on via ridge/groove segments on the two **walled** sides only —
the x-min (SD) wall and the +Y (GPIO) wall — in segments that flank the SD
notch and the arm socket. The two open port-channel sides (the AV edge and the
Ethernet/USB edge) don't latch, so the lid can lift slightly at that free
corner. That's expected and fine for a stationary desk unit; it is not
airtight or rattle-proof at that corner.

To remove the lid, pull up from the open-channel corner and work around; there
is nothing to unscrew.

The snap as modeled is firm/stiff (a 2.8 mm engaging skirt). If it's too tight
in plastic:

- **Loosen it:** thin the engaging skirt (`snap_ridge_h` down, or widen
  `lid_fit`) or deepen the ridge/groove a touch.
- **Too loose / rattles:** the reverse — a taller `snap_ridge_h` or a shallower
  groove.

## Fit-test ladder (cheap prints, print in this order)

1. `stl/sensor_gauge.stl` — the sensor cradle alone. **Print this first**, with
   `stl/sht40_dummy.stl` and `stl/sensor_clip.stl`, and confirm the board drops
   onto the pips and the clip slides on, before committing to the full arm.
2. `stl/fit_coupon.stl` — one standoff plus an open-channel edge. Confirms the
   locating pip enters the Pi's hole at the right spacing and that its ports
   clear the open channel.
3. `stl/socket_gauge.stl` — the arm socket alone. Confirms the arm's tenon slides
   in before you commit to the long tray print. **Print it as exported** — do not
   rotate it onto another face, or it stops predicting how the tray prints.
4. `stl/tray.stl` — the tray. Its own risks (bridging over the bore and vents)
   are things no coupon predicts better than the tray itself, so it goes next.
5. `stl/lid_gauge.stl` — one segment of the lid's snap skirt, cut straight out
   of the real lid geometry. Press it onto the **printed tray's** ridge to judge
   the snap force before committing to the 22 cm³ lid. **Print as exported** —
   it is flipped the way the lid is, so the groove's overhang matches.
6. `stl/lid.stl` — the lid.

## Printing

PETG, 0.2 mm layers, 3 perimeters, ~20% infill, no supports. All seven parts
render as single watertight bodies and pass `tests/check_all.sh`, which also
checks that the parts actually assemble (no solid overlap) and that nothing
overhangs unsupported. STLs in `stl/` are pre-oriented (min Z = 0) — drop them
straight into the slicer.

**Status: printed and working.** Every part has been printed and every interface
confirmed in plastic — DHT22 in the cradle, arm in the socket, Pi on the
standoffs, microSD through the notch, jumpers clearing the lid, and the lid
snapping to the tray. `BUILD_LOG.md` records what failed on the way and why.

## Re-export

```
openscad -o stl/sensor_gauge.stl -D 'part="sensor_gauge"' pi4_dht22_enclosure.scad
openscad -o stl/arm.stl          -D 'part="arm"'          pi4_dht22_enclosure.scad
openscad -o stl/tray.stl         -D 'part="tray"'         pi4_dht22_enclosure.scad
openscad -o stl/lid.stl          -D 'part="lid"'          pi4_dht22_enclosure.scad
openscad -o stl/fit_coupon.stl   -D 'part="fit_coupon"'   pi4_dht22_enclosure.scad
openscad -o stl/socket_gauge.stl -D 'part="socket_gauge"' pi4_dht22_enclosure.scad
openscad -o stl/lid_gauge.stl    -D 'part="lid_gauge"'    pi4_dht22_enclosure.scad
```

## Test prints for the SHT40 cradle

`stl/sht40_dummy.stl` is a printable stand-in for the Adafruit 4885 board —
correct outline, hole pattern and connector blocks — so the cradle and clip can
be exercised before the real sensor arrives. It shares its parameters with the
cradle, so it proves the joint works; it cannot prove the parameters are right.
Re-check with the real board.

`clip_fit` (slack over the cradle walls) is the one number that only plastic can
settle. **Settled 2026-08-16 at 0.20** — 0.20 / 0.30 / 0.40 were printed and the
tightest slid on snugly without forcing.

To run another sweep, export a variant set with `clip_mark` set to a different
count per variant. The dimples are cut into the face that lands up on the bed,
so the prints are tellable apart by touch — three unmarked clips 0.2 mm apart
in span could not be distinguished after printing:

```
i=1; for f in 0.15 0.20 0.25; do
  openscad -o "stl/variants/sensor_clip_fit${f/./}.stl" \
    -D 'part="sensor_clip"' -D "clip_fit=$f" -D "clip_mark=$i" \
    pi4_dht22_enclosure.scad
  i=$((i+1))
done
```

Then set `clip_fit` in the SCAD to the winner and re-export `stl/sensor_clip.stl`
(the production clip carries no dimples).

`part` also accepts `"assembly"` — tray + ghosted Pi + lid + arm, a visual
check only, no STL.
