# Raspberry Pi 4 enclosure with DHT22 sensor arm

A desk enclosure for a Pi 4 Model B temperature node — a tray, a snap-fit lid,
and a plug-in arm that holds a DHT22 module in free air off the Pi's warm
plume. Prints flat, no supports; PETG recommended.

Model: `pi4_dht22_enclosure.scad`. Design record: `docs/design/`. Renders:
`docs/renders/`.

## The DHT22 module — measured, single-hole breakout

Sized to the board in hand (measured 2026-08-15): **29.52 × 13.0 × 1.6 mm**,
with a **single Ø2.85 mm mounting hole, 7.2 mm from the cable end**.

One hole can't stop the board rotating, so the cradle at the arm's end pairs the
snap-post with **two side rails** that capture the board's width. The board drops
in from above, the post's split prongs flex through the hole and spring back to
retain it, the sensor end cantilevers into free air, and the cable runs back down
the arm groove. For a different board, measure it and set `board_len` /
`board_wid` / `board_thk`, `mnt_from_end`, `mnt_hole_d` at the top of the SCAD.

## Parts

| Part | Role |
|---|---|
| **Tray** | Holds the Pi on four locating posts — no screws; the lid's pads press it down. Carries the SD notch, DHT22 cable exit, floor vents, snap ridges, and the keyed arm socket. |
| **Lid** | Vented top with the LED window and open port channels. Snaps onto the tray — no lid screws. Four underside pads clamp the Pi onto its standoffs. |
| **Arm** | Plugs into the tray socket as a keyed friction fit — no set screw, nothing sprung. Routes the DHT22 cable in a groove and ends in a snap cradle (one post + two rails) that the DHT22 board clicks onto — sensor cantilevered into free air. |

**Fasteners, in total: none.** The Pi sits on four locating posts and is clamped
by pads under the lid, the lid snaps onto the tray, the arm is a keyed friction
fit in its socket, and the DHT22 clips onto the arm.

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

1. `stl/sensor_gauge.stl` — the sensor cradle alone (pad + rails + the snap-post).
   **Print this first**, push your DHT22 board onto it, and confirm a firm click
   before committing to the full arm. Tune `post_barb_d` / `post_slot_w` /
   `post_fit` if the snap is too stiff or loose.
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
settle. Three variants are exported to `stl/variants/`; print all three at once
and keep whichever slides on snugly:

```
for f in 0.20 0.30 0.40; do
  openscad -o "stl/variants/sensor_clip_fit${f/./}.stl" \
    -D 'part="sensor_clip"' -D "clip_fit=$f" pi4_dht22_enclosure.scad
done
```

Then set `clip_fit` in the SCAD to the winner and re-export `stl/sensor_clip.stl`.

`part` also accepts `"assembly"` — tray + ghosted Pi + lid + arm, a visual
check only, no STL.
