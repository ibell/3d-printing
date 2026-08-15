# Raspberry Pi 4 Enclosure with DHT22 Sensor Arm — Design

Date: 2026-07-25
Model: `pi4_dht22_enclosure.scad` (OpenSCAD). Renders in `docs/renders/`.

The SCAD file is the source of truth for dimensions. This document records the
decisions and the reasoning behind them.

## 1. Purpose

A three-part 3D-printed desk enclosure for a Raspberry Pi 4 Model B running as a
temperature-monitoring node, plus a plug-in arm that holds a DHT22 temperature/humidity
module out in free air, away from the Pi's own heat. All three parts print flat with no
supports and assemble by hand with four M2.5 screws (Pi to standoffs), one M3 set screw
(arm in socket), and a snap-fit lid.

The reason the sensor is on an arm at all is thermal: a DHT22 sitting on or inside a
warm enclosure reads the box, not the room. The arm exists to move the sensor out of
the Pi's convective plume so the reading is ambient air. Everything else in the design
serves either that goal or basic protection/serviceability of the Pi.

## 2. The hardware being enclosed

### Raspberry Pi 4 Model B

| Property | Value | Source |
|---|---|---|
| Board outline | 85.0 × 56.0 mm | Pi 4 mechanical drawing |
| PCB thickness | ~1.4 mm | measured / datasheet |
| Mounting holes | 4 × Ø2.7 mm, on a **58 × 49 mm** rectangle, 3.5 mm from each edge | mechanical drawing |
| Tallest components | USB-A double stack ~17 mm, Ethernet ~13.5 mm above PCB | mechanical drawing |
| microSD | underside, short edge **opposite** Ethernet; card protrudes past the edge | — |
| Status LEDs | green ACT + red PWR, at the corner near the USB-C power jack | — |
| GPIO | 40-pin header along one long edge; the DHT22 plugs onto pins here | — |

**Only the mounting-hole rectangle (58 × 49 mm) and the board outline (85 × 56 mm) are
tight-tolerance interfaces.** The individual port positions along the two port edges are
deliberately *not* load-bearing on this design — see §4, open port channels — so their
exact millimetre positions do not have to be trusted from a drawing. This is a
deliberate robustness choice: Pi port cutouts are the classic source of misfit, and this
design routes around that failure mode rather than chasing tolerances into it.

### DHT22 module (the sensor)

A 3-pin breakout module: the AM2302/DHT22 sensor on a small PCB with a pull-up resistor
and a 3-pin header. **These vary between sellers**, so every pocket dimension is a
parameter with a measured default:

| Parameter | Default | Meaning |
|---|---|---|
| `sensor_pcb_w` | 37.0 mm | module width (cavity width) |
| `sensor_pcb_h` | 10.0 mm | module height / drop-in depth of the cavity |
| `sensor_pcb_t` | 10.0 mm | module thickness (cavity depth into the arm face) |
| `sensor_slot_fit` | 0.2 mm | added on each cavity dimension so the module drops in |
| `sensor_grille_w/h` | sized to clear the white sensor body | front opening for airflow |

**The pocket is a drop-in cavity, not an edge slot.** At 10 mm thick the module is a
chunky strip, so the pocket is a rectangular box of `sensor_pcb_w × sensor_pcb_h ×
sensor_pcb_t` (plus `sensor_slot_fit`) that the whole module drops into — grille facing
out through the front `sensor_grille` opening, cable exiting the back into the arm
groove. A pair of small retention lips at the mouth hold it seated. Measure your module
with calipers and set `sensor_pcb_w/h/t`; nothing else needs to change.

## 3. Architecture — three parts

| Part | Role |
|---|---|
| **Base tray** | Holds the Pi on four printed standoffs. Carries the SD-card notch, the DHT22 cable-exit slot, floor vents, the lid snap ridges, and the keyed arm socket. |
| **Lid** | Vented top with the LED window and open port channels. Snaps onto the tray. |
| **Sensor arm** | Plugs into the tray socket, routes the DHT22 cable in a groove, ends in a vented sensor pocket. Includes an optional desk foot. |

The arm is a **separate part**, not integral to the box, for three reasons: it prints
flat and strong along its length; the thin plug joint is a poor heat conductor, so the
box's warmth does not travel up the arm; and it is independently replaceable and
re-orientable.

## 4. Geometry and decisions

Coordinates: origin at a tray floor corner, **x** along the 85 mm board edge, **y**
along the 56 mm edge, **z** up.

### Standoffs

Four posts on the 58 × 49 mm pattern, **`standoff_h` = 5 mm** tall, **Ø6 mm**, with
**Ø2.2 mm pilot holes** for M2.5 self-tapping screws. 5 mm lifts the board clear of its
own through-hole solder tails and opens a floor-vent plenum under the SoC side of the
board. Pilot (not clearance) holes let the screws self-tap into plastic — no nuts or
heat-set inserts required, matching the "assemble by hand" goal.

### Open port channels, not cutouts

The two port edges — the AV long edge (USB-C power, 2× micro-HDMI, A/V) and the
Ethernet/USB short edge — have **no wall above board level**. The lid's side over each of
these edges is an open channel, so every port on those edges is simply exposed. This is
the single most consequential decision in the enclosure:

- It makes the fit **immune to port-position tolerance**. There is no per-port hole to
  misalign, and no drawing figure that has to be correct to the millimetre.
- It doubles as ventilation: the two open sides plus the top vents give cross-flow.
- The cost is dust ingress and a less "sealed" look — accepted, because this is an
  indoor desktop appliance, not a field-sealed box (§8).

The other two edges are walled: the GPIO long edge (carrying the cable-exit slot) and
the SD short edge (carrying the SD notch).

### SD-card access

The microSD sits on the **underside** of the short edge opposite Ethernet and protrudes
past the board edge. A **notch** in that short wall, aligned to the card and sitting at
the standoff-lifted card height, lets the card be pushed/pulled without opening the lid.
Parameters `sd_slot_w`, `sd_slot_h` size it; its z is computed from `standoff_h`.

### LED window

The PWR/ACT LEDs sit at the USB-C corner. That corner is on an open port channel, so the
LEDs are likely visible already; a small **window slot** on the lid lip at that corner is
added as belt-and-suspenders (`led_win_*`). No light pipe — the window is a direct
opening, which cannot mis-register the way a printed pipe can.

### Cable routing and the arm socket

The DHT22 plugs onto the GPIO header on the walled long edge. A **cable-exit slot** in
that wall passes the three wires out to a **keyed rectangular socket** in the tray corner
nearest the GPIO exit. The socket takes the arm's plug tenon and is secured by one M3 set
screw. Keying fixes the arm's orientation so the sensor always points the intended way.
The path is deliberately short: GPIO → exit slot → arm cable groove → pocket.

### Sensor placement — off the plume, not just off the box

The socket aims the arm **out to the side**, in the tray plane, not upward over the top
vents. Warm air leaves the lid vents rising; putting the sensor beside the box rather
than above it keeps it out of that rising column. `arm_len` = **80 mm** default reach
(≈ 3 in) balances thermal isolation against cantilever stiffness. The arm cross-section
is **10 × 6 mm**, printed flat so its length runs along the bed for bending strength.

### Optional desk foot

`arm_foot = true` adds a base pad at the sensor end so the arm can alternatively stand
on the desk beside the box, fully mechanically and thermally decoupled from it. The pad
broadens the footprint past `arm_w` for stability; its underside is coplanar with the arm
bar's bottom (z = 0), so the whole part rests flat on the bed and prints with no supports.

## 5. Parts (intended)

Dimensions are the design intent; the SCAD is authoritative once modeled.

| Part | Footprint | Notes | Qty |
|---|---|---|---|
| Base tray | ~89 × 60 mm | walls 2 mm, floor 2 mm, standoffs 5 mm | 1 |
| Lid | ~89 × 60 mm | ~20 mm internal clear height over the board | 1 |
| Sensor arm | ~90 × 10 mm | 80 mm reach + plug tenon, groove, pocket, optional foot | 1 |

Fit clearance around the board is `board_fit` = 0.4 mm. Lid-to-tray is a snap-fit joint:
ridge/groove segments on the two walled sides (x-min/SD and +Y/GPIO), flanking the SD
notch and the arm socket, rather than screws into corner bosses.

## 6. Test parts (fit-check ladder)

Cheap prints that each rule out one failure before committing to the ~full set. Selected
via `part=`. **Ordered by uncertainty: the sensor pocket goes first**, because its
dimensions were just measured off the actual module and are the values most likely to
need a tweak — cheapest thing to get wrong, so prove it first.

1. **`sensor_gauge`** — just the arm's pocket (the "breakout box"), to check the DHT22
   module seats with a firm grip after you have set `sensor_pcb_*`. Print this **before
   anything else**; it validates the freshest, least-certain interface for a few grams.
2. **`fit_coupon`** — a small tile carrying **one corner of the standoff pattern plus one
   adjacent port-channel edge**. Verifies the two Pi-side things that actually have to be
   right: the M2.5 pilot fit and hole-to-edge spacing, and that a real Pi's port stack
   clears the open channel.
3. Then the production `tray`, `lid`, and `arm`.

## 7. Printing

- **PETG** recommended over PLA: a temperature node may sit in warm air or sun, and PLA
  softens around 50–60 °C. Nothing in the design depends on the material.
- 0.2 mm layers, 3 perimeters, ~20 % infill, **no supports**. Overhangs are chamfered and
  vent slots are sized to bridge.
- Orientation is load-bearing, not incidental: the arm prints flat so bending stress runs
  along the layer lines, not across them.
- Bed: everything fits a 180 × 180 mm bed (Bambu A1 mini) individually. A combined
  layout is a nicety, not a necessity, given only three parts.

STLs in `stl/` will be exported in print orientation (Z = thickness / up) and positioned
on the bed, ready to drop into a slicer.

Re-export:

```sh
openscad -o stl/tray.stl -D 'part="tray"' pi4_dht22_enclosure.scad
openscad -o stl/lid.stl  -D 'part="lid"'  pi4_dht22_enclosure.scad
openscad -o stl/arm.stl  -D 'part="arm"'  pi4_dht22_enclosure.scad
```

`part` also accepts `"assembly"` (all parts plus a ghosted Pi, for visual checking),
`"fit_coupon"`, and `"sensor_gauge"`.

## 8. Known limitations

- **Sensor accuracy is the DHT22's, not the mount's.** The DHT22 is ±0.5 °C at best; the
  arm removes self-heating error but cannot make the sensor more accurate than its part
  spec. (A TMP117/SHT45 node would be the move if ±0.1 °C is wanted — but that is a
  different project.)
- **Open port channels admit dust** and are not a sealed enclosure. Accepted for an
  indoor desktop appliance; a closed-cutout variant is explicitly out of scope (§4).
- **Port positions are assumed, not measured.** This is safe *because* the channels are
  open — but it means a differently-portioned board (a Pi 5, say) is not covered without
  re-checking which edges carry which ports.
- **Standoff pilot holes self-tap into plastic.** Good for a few assembly cycles; not for
  repeated re-opening. Switch to heat-set inserts if the lid will come off often.
- **Untested in plastic.** Every dimension here is calculated or taken from the Pi 4
  mechanical drawing; none of it has been printed yet.
- **Lid snap is firm and only two-sided.** The engaging skirt is stiff (2.8 mm) as
  modeled — expect a firm push to seat. Only the two walled sides latch; the two open
  port-channel sides don't, so the lid can lift slightly at that free corner. Both are
  acceptable for a stationary desk unit; see the Amendments note below.

### Amendments

- **2026-07-25 — lid changed from screws to snap-fit.** The lid was originally specced
  with 4 × M3 screws into tray corner bosses (§3, §5 as first written). Once modeled, the
  Pi fills the tray tightly enough that the corner bosses collided with the standoffs and
  fouled the board, so the lid was switched to a snap-fit during implementation: ridge/
  groove segments on the two walled sides, flanking the SD notch and the arm socket. The
  M2.5 standoff screws and the M3 arm set screw are unaffected. This document has been
  updated in place to describe the snap-fit as built; the SCAD is authoritative.

## 9. Parameter block (top of the SCAD)

```
board_w, board_l, pcb_t          Pi 4 outline and thickness
hole_dx, hole_dy, hole_pilot_d   58 x 49 mount pattern; pilot Ø for M2.5
standoff_h, standoff_od          post height and diameter
wall, floor, board_fit           shell thicknesses and board clearance
snap_ridge_h, snap_ridge_z,      lid snap-fit ridge/groove
  snap_seg_x, snap_seg_y
vent_slot_w, vent_gap            top ventilation grid
sd_slot_w, sd_slot_h             microSD access notch (z computed from standoff_h)
led_win_w, led_win_h             LED window at the USB-C corner (x hardcoded)
cable_slot_w, cable_slot_h       DHT22 cable exit on the GPIO edge
arm_len, arm_w, arm_h            sensor arm reach and cross-section
socket_depth, socket_fit,        keyed plug socket + M3 set screw
  setscrew_d, key_w, key_h       socket ceiling notch keyed to the tenon rib
arm_foot (bool)                  optional desk-standing foot
sensor_pcb_w, sensor_pcb_h,      DHT22 module pocket — MEASURE yours
  sensor_pcb_t, sensor_slot_fit
sensor_grille_w, sensor_grille_h front airflow opening
```
