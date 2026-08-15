# Build log

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

Next: reprint `stl/sensor_gauge.stl` and confirm the board seats without wobble or
rotation. Then `stl/fit_coupon.stl` against the real Pi, then the production set.

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
