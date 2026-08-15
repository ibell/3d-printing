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
| **Tray** | Holds the Pi on four standoffs, secured with four M2.5 self-tapping screws. Carries the SD notch, DHT22 cable exit, floor vents, snap ridges, and the keyed arm socket. |
| **Lid** | Vented top with the LED window and open port channels. Snaps onto the tray — no lid screws. |
| **Arm** | Plugs into the tray socket (held by one M3 set screw), routes the DHT22 cable in a groove, and ends in a two-post snap cradle that the DHT22 board clicks onto — sensor cantilevered into free air. |

Fasteners, in total: four M2.5 self-tapping screws (Pi-to-standoffs) and one
M3 set screw (arm-in-socket). The lid takes none.

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
2. `stl/fit_coupon.stl` — one standoff corner plus an open-channel edge.
   Confirms the M2.5 pilot fit and that the Pi's ports clear the open channel.
3. `stl/tray.stl`, `stl/lid.stl`, `stl/arm.stl` — the production set.

## Printing

PETG, 0.2 mm layers, 3 perimeters, ~20% infill, no supports. All five parts
render as single watertight bodies and pass `tests/check_geom.py`. STLs in
`stl/` are pre-oriented (min Z = 0) — drop them straight into the slicer.
Nothing has been printed in plastic yet; see `BUILD_LOG.md`.

## Re-export

```
openscad -o stl/sensor_gauge.stl -D 'part="sensor_gauge"' pi4_dht22_enclosure.scad
openscad -o stl/arm.stl          -D 'part="arm"'          pi4_dht22_enclosure.scad
openscad -o stl/tray.stl         -D 'part="tray"'         pi4_dht22_enclosure.scad
openscad -o stl/lid.stl          -D 'part="lid"'          pi4_dht22_enclosure.scad
openscad -o stl/fit_coupon.stl   -D 'part="fit_coupon"'   pi4_dht22_enclosure.scad
```

`part` also accepts `"assembly"` — tray + ghosted Pi + lid + arm, a visual
check only, no STL.
