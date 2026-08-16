// Raspberry Pi 4 enclosure + DHT22 sensor arm — parametric source.
// Select a body with -D 'part="..."'. See docs/design for rationale.

part = "assembly";   // "sensor_gauge" | "arm" | "tray" | "lid" | "fit_coupon" | "assembly" | "_smoke"
$fn  = 48;

/* ---------- Pi 4 board ---------- */
board_w      = 85.0;   // long edge (X)
board_l      = 56.0;   // short edge (Y)
pcb_t        = 1.4;
hole_dx      = 58.0;   // mount rectangle along X
hole_dy      = 49.0;   // mount rectangle along Y
hole_edge    = 3.5;    // hole-centre inset from board edge
pi_hole_d    = 2.7;    // Pi 4 mounting-hole diameter (board side)

/* ---------- shell ---------- */
wall        = 2.0;
floor       = 2.0;
board_fit   = 0.4;
tray_wall_h = 10.0;    // tray wall height above floor
lid_wall    = 2.5;     // 2.0 left only 0.8 mm of skirt behind the groove
lid_fit     = 0.3;     // lid-over-tray clearance. Defined BEFORE the snap block
                       // below, which derives the groove from it -- OpenSCAD
                       // resolves these in file order.
/* Lid snap. The first printed pair FITTED BUT DID NOT SNAP (2026-08-15), for
   two reasons that compounded:

   1. The ridge could not physically enter the groove. The ridge tapers at 45
      deg, so at the lid's lip plane it was 2*(ridge_base_half - lid_fit) =
      2.4 mm tall, while the groove opening was hardcoded at 2.0 mm. The lid
      rode up on the ridge flanks and never dropped in.
   2. Even had it entered, engagement was only snap_ridge_h - lid_fit = 0.5 mm,
      and print tolerance on two mating surfaces can eat most of that.

   The groove is now DERIVED from the ridge instead of hardcoded, so the two
   cannot disagree again, and the ridge is taller for a real grip. */
snap_ridge_h    = 1.2;   // how far the ridge protrudes (was 0.8 -> too shallow)
snap_ridge_z    = floor + tray_wall_h - 3.0;  // z of ridge centre (near wall top)
ridge_base_half = snap_ridge_h + 0.6;  // half-height at the wall; tip keeps 0.6
groove_clear    = 0.3;   // slack so the ridge drops in rather than wedging
// half-height of the lid groove: must clear the ridge's cross-section where it
// crosses the lip plane, which is (ridge_base_half - lid_fit) by the 45 deg taper
groove_half     = ridge_base_half - lid_fit + groove_clear;
/* Internal clear height above the board top. NOT a round number picked for
   looks -- it is the GPIO jumper stack-up, which is the tallest thing in the
   box. The DHT22's female jumper housings slide down over the header pins, and
   the wire then has to turn over above them. The original 20.0 was a guess and
   was too low. jump_stack is measured on the real leads; re-measure it if you
   change jumpers, since housings vary by a couple of mm. */
jump_stack  = 24.0;    // MEASURED 2026-08-15: PCB top surface -> top of jumper
wire_bend   = 5.0;     // room above the jumper for the wire to turn over
lid_clear   = jump_stack + wire_bend;   // 29.0

/* ---------- snap-fit ridge/groove segments (shared by tray + lid) ----------
   Each wall carries TWO ridge segments that FLANK its obstruction; the lid's
   grooves reuse the same lists so the mate is guaranteed. Entries are
   [start, length] along the wall.
   x-min (SD) wall: y-segments flank the SD notch (y[22.4,36.4]).
   +Y  (GPIO) wall: x-segments flank the arm socket (x[36.7,51.1]) & cable slot. */
snap_seg_x = [[4, 16], [39, 16]];   // x-min wall, along y -> y[4,20] & y[39,55]
snap_seg_y = [[6, 24], [56, 24]];   // +Y  wall, along x -> x[6,30] & x[56,80]

/* ---------- standoffs (locating posts + lid hold-down -- no screws) ----------
   NOT snap posts. A split-post barb was tried and broke off the DHT22 cradle
   after ONE insertion (2026-08-15): the post prints standing in Z, so its
   0.875 mm prongs are stacks of layers and flexing them sideways loads the
   bond BETWEEN layers -- the weakest direction in an FDM part. Four of them
   on a rigid PCB, all flexing at once, would be worse than one.
   So nothing flexes here. A pip locates the board in X/Y, the collar carries
   it in -Z, and pads under the lid press it in +Z. The lid already snaps, so
   this still costs no fasteners. */
standoff_h  = 5.0;     // collar height: board sits this far above the floor
standoff_od = 6.0;     // collar diameter (the old screw-standoff footprint)
pip_d       = 2.5;     // locating pip, 0.2 under pi_hole_d
pip_h       = 1.2;     // stops just BELOW flush so a flat pad can bear on the PCB
hold_d      = 6.0;     // lid pad contact Ø -- concentric with the standoff, so
                       // the clamp is pad -> board -> collar with no bending
hold_base_d = 8.0;     // pad Ø at the lid ceiling; tapers down for print stability.
                       // Capped so the pads over the y=3.9 holes stay inside the
                       // lid's open -Y edge instead of jutting past it.
hold_preload = 0.3;    // pad reaches this far below board top, to guarantee contact
hold_bore_d = 3.4;     // clearance bore in the pad face, so it bears on the PCB
hold_bore_h = 1.5;     // and not on the locating pip poking up through the hole

/* ---------- ventilation ---------- */
vent_slot_w   = 3.0;
vent_slot_len = 24.0;
vent_gap      = 3.0;

/* ---------- microSD notch (SD short edge = x-min) ----------
   The card lives BELOW the board: its holder is on the Pi's underside, so an
   inserted card sits roughly 1-2 mm under the PCB, not level with it. The
   first version put the notch from the board underside UPWARDS, which is
   exactly backwards -- the card fouled solid wall about 1 mm below the notch
   (found on the printed tray, 2026-08-15). The notch is now anchored BELOW the
   board underside and reaches only slightly above it. */
sd_slot_w    = 14.0;   // notch width (card is ~11 mm)
sd_below     = 2.8;    // notch reaches this far BELOW the board underside
sd_above     = 0.8;    // ...and only this far above it
sd_slot_h    = sd_below + sd_above;
sd_slot_z    = floor + standoff_h - sd_below;   // notch bottom
// Centre the notch on the BOARD's centreline, not the tray's -- they differ by
// board_fit, and the card only has ~1.5 mm of margin in a 14 mm notch.
sd_slot_y    = board_fit + board_l / 2 - sd_slot_w / 2;

/* ---------- LED window (USB-C corner) ---------- */
led_win_w = 10.0;
led_win_h = 4.0;

/* ---------- DHT22 cable exit (GPIO long edge = +Y) ---------- */
cable_slot_w = 8.0;
cable_slot_h = 5.0;

/* ---------- sensor arm ---------- */
arm_len      = 80.0;   // clear reach, socket mouth to pocket back
arm_w        = 10.0;
arm_h        = 6.0;
arm_groove_w = 4.0;
arm_groove_d = 2.5;

/* ---------- arm socket (tray, GPIO side) ----------
   A PLAIN keyed friction socket: close sliding bore + key rib, nothing that
   flexes. Two attempts at a sprung joint were abandoned on print evidence
   (2026-08-15):
     - the split snap-post barb on the DHT22 cradle broke after ONE insertion,
       because a post standing in Z flexes ACROSS its layer lines;
     - the socket's cantilever tabs FUSED in the print, because freeing them
       needs 1.0 mm horizontal slots and the socket necessarily prints with its
       bore horizontal (it is part of the tray, which prints floor-down).
   The tenon's own friction plus the key rib is what holds the arm, which
   carries nothing but its own weight. If it ends up too loose, the honest fix
   is a fastener, not a third sprung feature: drill the socket's outer wall and
   run a screw into the tenon. */
socket_depth = 10.0;   // tenon length
socket_fit   = 0.4;    // bore-over-tenon clearance; the friction fit lives here
key_w        = 2.0;    // socket ceiling notch width (X); mates the tenon key rib
key_h        = 1.5;    // notch depth up into the bore ceiling (Z)
key_fit      = 0.4;    // rib-in-notch lateral clearance

/* ---------- SHT40 sensor board (Adafruit 4885) + cradle & clip ----------
   Dimensions are taken from Adafruit's own 3D model, not from a photo or a
   guess: Adafruit_CAD_Parts/"4885 SHT40 Sensor". It is the standard 1.0 x 0.7
   inch STEMMA QT outline, so every figure below lands on an imperial value.

   Two facts about this board shape drive the design:
     - FOUR mounting holes. Two of them, 12.70 mm apart across the width, fix
       the board's angle by themselves, so the DHT22 cradle's anti-rotation
       rails are no longer needed.
     - The STEMMA QT connectors occupy only the CENTRAL 5.94 mm of the width,
       on both short ends. The outer ~4 mm of each long edge is clear for the
       board's whole length, so the cradle can support and clamp those strips
       while the connectors and the sensor breathe through an open channel. */
sht_len       = 25.4;    // board length (X)  -- 1.0"
sht_wid       = 17.78;   // board width  (Y)  -- 0.7"
sht_thk       = 1.6;     // PCB thickness
sht_hole_d    = 2.5;     // mounting hole diameter
sht_hole_x0   = 2.54;    // inboard hole pair, from the leading edge (0.1")
sht_hole_dy   = 12.70;   // hole pitch across the width (0.5") -> y = +/-6.35
sht_conn_half = 2.97;    // connector band half-width, about the centreline
sht_conn_h    = 2.9;     // connector height above the PCB

/* ---------- cradle (on the arm) ----------
   NOTHING HERE FLEXES. Three sprung features failed in plastic on the DHT22
   build, all because a feature printed standing in Z bends across its layer
   lines. The cradle is now purely passive: pips locate, rails support. All the
   retention -- and therefore all the tuning -- lives in a separate clip, which
   is a few minutes to reprint and can be printed in its OWN orientation. */
grip_len      = 12.0;    // cradle support length under the board's inboard end
pad_back      = 6.0;     // pad reach behind the board's leading edge
board_lift    = 3.0;     // airflow gap: board sits this far above the pad
support_w     = 5.0;     // width of each support rail, centred on the hole line
sens_pip_d    = 2.3;     // locating pip, 0.2 under sht_hole_d
sens_pip_h    = 1.2;     // BELOW flush in a 1.6 mm PCB, so the clip bears on
                         // the board rather than on the pip -- same reasoning
                         // as the Pi standoffs
wall_fit      = 0.3;     // side-wall clearance either side of the board
wall_t        = 2.0;     // side-wall thickness
wall_up       = 4.5;     // wall height above the board top
cradle_gauge_t = 3.0;    // pad thickness for the standalone sensor_gauge print

/* ---------- retention clip (separate part) ----------
   A flat U that straddles the cradle walls and presses on the board's edge
   strips. Printed LYING FLAT, so the U profile is in the bed plane.

   IT SLIDES ON FROM THE OUTBOARD END -- it does not push on from above. The
   inward rails on its legs enter the wall grooves at the walls' open outboard
   end and slide inboard until they butt the groove's closed end. Nothing
   flexes, at all.

   Snapping it on from the top was the first attempt and is not possible: the
   legs are only ~5.6 mm long and 2.2 mm thick, so spreading them the 0.4 mm
   needed to clear the walls takes about 12 kg. They would break first. That is
   the same lesson as the cradle barb and the socket tabs, arrived at by
   arithmetic this time rather than by breaking a print. */
clip_w        = 5.0;     // clip extent along the arm axis
// Clip sits OUTBOARD of the inboard connector (which ends at x=4.41), not over
// the pips. Clamping over the pips would be marginally better mechanically, but
// it buries the STEMMA QT socket under the clip's bar with 0.8 mm of headroom,
// so the cable could only be fitted before the clip. The support rails run the
// full grip length, so the clamp path is still clip -> board -> rail here.
clip_x        = 6.5;
clip_fit      = 0.2;     // slack over the cradle walls. CHOSEN BY PRINT
                         // 2026-08-16: 0.20 / 0.30 / 0.40 were printed and the
                         // tightest slid on snugly without forcing.
clip_mark     = 0;       // dimples cut into the printed top face, so variant
                         // prints are tellable apart by touch. Set on the
                         // command line when exporting a variant set; the
                         // production clip carries none.
clip_leg_t    = 2.2;
clip_bar_t    = 2.5;
// The bar must clear the TOP OF THE CRADLE WALLS, not just the connectors.
// First version set it from sht_conn_h alone, putting the bar underside 0.8 mm
// BELOW the wall tops: the clip landed on the walls and its pads never reached
// the board. Derived from wall_up now so the two cannot disagree.
clip_bar_gap  = 0.6;     // bar underside, above the cradle wall top
// Pad placement is set by what is CLEAR on the board, not by the pip line.
// Measured off Adafruit's model: within the clip's x span the tallest thing on
// the +y edge strip reaches board-y 13.45 and stands 0.97 mm proud. Pads
// centred on the pips (|y| 6.35, 4 mm wide) reached board-y 13.24 and would
// have landed on it. Moved outboard and narrowed; still inside the support
// rails, so the clamp path is unchanged.
clip_pad_ctr  = 6.7;     // pad centreline, from the board's centreline
clip_pad_w    = 3.5;     // width of the pads that touch the board
clip_preload  = 0.25;    // pads reach this far below the board top, so the clip
                         // actually grips rather than merely touching
clip_bump     = 0.7;     // inward bump on each leg
clip_groove_z = 1.5;     // groove centre, above the board top
clip_groove_h = 2.4;     // groove height; > bump so it seats rather than wedges
clip_groove_d = clip_bump + 0.2;   // groove depth, derived from the bump

/* ---------- global sanity asserts ---------- */
assert(wall > 0 && floor > 0, "thicknesses must be positive");
assert(2 * (ridge_base_half - lid_fit) < 2 * groove_half,
       "snap ridge is taller than the lid groove -- it cannot enter and will not snap");
assert(ridge_base_half > snap_ridge_h, "ridge taper would invert");
assert(board_fit >= 0 && wall_fit >= 0 && clip_fit >= 0, "fits must be non-negative");
assert(sens_pip_d < sht_hole_d, "locating pip must enter the board's mounting hole");
assert(sens_pip_h < sht_thk,
       "pip must stay below flush so the clip bears on the PCB, not the pip");
assert(sht_hole_x0 < grip_len, "inboard holes must land on the cradle");
assert(sht_len > grip_len, "board must cantilever past the cradle into free air");
assert(clip_pad_ctr - clip_pad_w / 2 > sht_conn_half,
       "clip pads would foul the STEMMA QT connector band");
assert(clip_pad_ctr + clip_pad_w / 2 < sht_wid / 2,
       "clip pads would overhang the board edge");
assert(abs(clip_pad_ctr - hole_y) < support_w / 2,
       "clip pads must stay over the support rails, or the clamp bends the board");
assert(clip_groove_h > clip_bump,
       "clip bump is taller than its groove -- it would wedge instead of seating");
assert(clip_bar_gap > 0,
       "clip bar would land on the cradle walls before its pads reach the board");
assert(clip_x + clip_w <= grip_len,
       "clip would overhang the cradle walls and lose its groove engagement");
assert(clip_x > 0, "groove needs wall material inboard of it to act as a stop");

/* ---------- dispatcher ---------- */
if      (part == "_smoke")       cube(10);
else if (part == "sensor_gauge") sensor_gauge();
else if (part == "arm")          arm();
else if (part == "tray")         tray();
else if (part == "lid")          lid();
else if (part == "fit_coupon")   fit_coupon();
else if (part == "socket_gauge") socket_gauge();
else if (part == "lid_gauge")    lid_gauge();
else if (part == "sensor_clip")  sensor_clip();
else if (part == "sht40_dummy")  sht40_dummy();
else if (part == "assembly")     assembly();
else echo(str("unknown part: ", part));

// One split snap-post at the local origin, rising in +Z from z=0.
// A support collar lifts the board for airflow; a slotted shaft passes through
// the board's mounting hole and a chamfered barb snaps over the top to retain
// it. The central slot splits the post into two prongs that flex together as
// the board is pushed on, then spring back under the barb.
// Half-widths and heights shared by the cradle and the clip, so the two are
// derived from one set of numbers and cannot drift apart.
w_out    = sht_wid / 2 + wall_fit + wall_t;   // outer face of a cradle wall
hole_y   = sht_hole_dy / 2;                   // 6.35, the pip / clamp line
btop_rel = board_lift + sht_thk;              // board top, above the pad top

// Cradle: pad, two support rails under the board's clear edge strips, two
// locating pips, and two side walls carrying the clip grooves. Passive only.
// Local frame: board's leading (inboard) edge at x=0, board runs +X, width
// centred on Y. The board's outboard end cantilevers past grip_len into free
// air, and the open central channel clears the STEMMA QT connectors.
module sensor_cradle(pad_h) {
    difference() {
        union() {
            translate([-pad_back, -w_out, 0])
                cube([grip_len + pad_back, 2 * w_out, pad_h]);
            for (mir = [0, 1]) mirror([0, mir, 0]) {
                // support rail the board rests on
                translate([0, hole_y - support_w / 2, pad_h])
                    cube([grip_len, support_w, board_lift]);
                // side wall
                translate([0, sht_wid / 2 + wall_fit, pad_h])
                    cube([grip_len, wall_t, btop_rel + wall_up]);
            }
        }
        // clip grooves, cut into the OUTER face of each wall
        // Groove runs from clip_x to the walls' OUTBOARD end, so the wall
        // material inboard of clip_x is a positive stop: the clip slides in
        // until it butts there and cannot go further. Derived from clip_x so
        // the stop and the clip's seated position cannot disagree.
        for (mir = [0, 1]) mirror([0, mir, 0])
            translate([clip_x, w_out - clip_groove_d, pad_h + btop_rel + clip_groove_z])
                cube([grip_len - clip_x + 0.1, clip_groove_d + 0.1, clip_groove_h]);
    }
    // locating pips, stopping below flush
    for (mir = [0, 1]) mirror([0, mir, 0])
        translate([sht_hole_x0, hole_y, pad_h + board_lift - 0.01])
            cylinder(d1 = sens_pip_d, d2 = sens_pip_d - 0.4, h = sens_pip_h + 0.01);
}

// Retention clip. Modelled in its IN-USE orientation (straddling the board,
// z=0 at the board's top face) and rotated onto its side by sensor_clip() for
// printing, so its legs flex within the layer plane.
module sensor_clip_body() {
    leg_in   = w_out + clip_fit;
    leg_out  = leg_in + clip_leg_t;
    bar_z    = wall_up + clip_bar_gap;        // bar underside clears the WALL TOPS
    leg_bot  = -(0.5);                        // legs run just past the board top
    bump_z   = clip_groove_z;

    difference() {
        union() {
            // bar across the top
            translate([0, -leg_out, bar_z]) cube([clip_w, 2 * leg_out, clip_bar_t]);
            for (mir = [0, 1]) mirror([0, mir, 0]) {
                // leg
                translate([0, leg_in, leg_bot])
                    cube([clip_w, clip_leg_t, bar_z - leg_bot]);
                // pad pressing the board, directly over the pip
                translate([0, clip_pad_ctr - clip_pad_w / 2, -clip_preload])
                    cube([clip_w, clip_pad_w, bar_z + clip_preload]);
                // inward bump that seats in the cradle wall's groove
                translate([0, leg_in - clip_bump, bump_z])
                    cube([clip_w, clip_bump + 0.01, clip_groove_h - 0.4]);
            }
        }
        // variant marker dimples. Cut into the face that ends up UP on the bed
        // (body +X maps to print +Z), so they print crisply and touch nothing
        // that mates. Three near-identical clips came off the bed on 2026-08-16
        // and could not be told apart -- count the dimples instead.
        for (i = [0 : clip_mark - 1])
            translate([clip_w - 0.5, (i - (clip_mark - 1) / 2) * 2.4,
                       bar_z + clip_bar_t / 2])
                rotate([0, 90, 0]) cylinder(d = 1.4, h = 1.5, $fn = 24);

        // lead-in chamfer on the rail's inboard end, so it finds the groove
        // mouth when sliding on rather than catching on the wall's end face
        for (mir = [0, 1]) mirror([0, mir, 0])
            translate([-0.01, leg_in - clip_bump - 0.01, bump_z - 0.01])
                rotate([0, -35, 0])
                    cube([1.6, clip_bump + 0.02, clip_groove_h]);
    }
}

// Print orientation: laid on its side so the U profile is in the bed plane.
module sensor_clip() {
    leg_out = w_out + clip_fit + clip_leg_t;
    rotate([0, -90, 0]) translate([0, 0, 0]) sensor_clip_body();
}

module sensor_gauge() { sensor_cradle(cradle_gauge_t); }

// Printable stand-in for the SHT40 board, so the cradle and clip can be
// exercised before the real part arrives. Outline, hole pattern and connector
// blocks all come from the same sht_* parameters the cradle is built from.
//
// CAVEAT worth stating: because it shares those parameters, this dummy cannot
// tell you whether the parameters are RIGHT. It tests the cradle against my
// reading of Adafruit's model, not against the board. It will confirm the clip
// slides, grips and clears the connectors; it will not catch a mis-measured
// board. Re-check with the real SHT40 when it lands.
module sht40_dummy() {
    r = 1.65;                       // corner radius, measured off the model
    difference() {
        union() {
            linear_extrude(sht_thk)
                hull()
                    for (x = [r, sht_len - r], y = [r, sht_wid - r])
                        translate([x, y]) circle(r = r);
            // STEMMA QT connector stand-ins on both short ends
            for (x0 = [0.23, 20.99])
                translate([x0, sht_wid / 2 - sht_conn_half, sht_thk])
                    cube([4.18, 2 * sht_conn_half, sht_conn_h]);
            // Surface-mount components, [x0, x1, y0, y1, height], measured off
            // Adafruit's model. Without these the dummy cannot answer the only
            // question it is really being asked -- does the clip clear the
            // board? The 5.14-9.00 x 12.05-13.45 part is the one the pads
            // originally fouled.
            for (c = [[ 5.14,  9.00, 12.05, 13.45, 0.97],
                      [ 6.20,  7.00, 10.20, 10.60, 1.37],
                      [ 6.20,  9.20,  8.20,  8.60, 1.37],
                      [ 8.40,  9.20, 10.20, 10.60, 1.37],
                      [11.80, 13.40,  8.00,  9.60, 0.56],
                      [16.00, 16.40,  5.00,  7.00, 1.07],
                      [17.60, 18.00,  5.00,  7.00, 1.07],
                      [16.00, 19.00, 11.80, 12.20, 0.47]])
                translate([c[0], c[2], sht_thk])
                    cube([c[1] - c[0], c[3] - c[2], c[4]]);
        }
        for (hx = [sht_hole_x0, sht_len - sht_hole_x0])
            for (hy = [sht_wid / 2 - sht_hole_dy / 2, sht_wid / 2 + sht_hole_dy / 2])
                translate([hx, hy, -0.5])
                    cylinder(d = sht_hole_d, h = sht_thk + 1);
    }
}

module arm() {
    span_end = socket_depth + arm_len;      // where the cradle joins the bar

    assert(arm_len >= 50, "arm_len below 50 mm defeats thermal isolation");

    // tenon + straight arm as one flat bar, centred on Y=0, with the cable
    // groove cut into the top face (recess, not a rib — see task-3 brief note).
    difference() {
        translate([0, -arm_w / 2, 0])
            cube([span_end, arm_w, arm_h]);

        // cable groove along the top of the arm
        translate([socket_depth, -arm_groove_w / 2, arm_h - arm_groove_d])
            cube([arm_len, arm_groove_w, arm_groove_d + 0.1]);

    }

    // key rib on the TOP of the tenon, centred on the arm axis and running the
    // full tenon length. It fills the socket's ceiling notch (tray_socket) so
    // the tenon only inserts right-side-up; rolled 180 deg the rib points down,
    // hits the (notch-less) bore floor, and the tenon won't seat. Rib is on the
    // top face (positive Z) so the arm still prints flat with min z = 0.
    translate([0, -(key_w - key_fit) / 2, arm_h - 0.01])
        cube([socket_depth, key_w - key_fit, key_h + 0.01]);

    // snap-post cradle at the end. The cradle's local +X (board length) already
    // aligns with the arm axis, so no rotation: the board's bottom (connector)
    // end sits over the bar end and the sensor end cantilevers +X into free air.
    // pad_h = arm_h so the pad fuses flush with the bar top and prints flat.
    translate([span_end, 0, 0]) sensor_cradle(arm_h);
}

// Ø standoff_od collar (the seat, unchanged from the screw version) topped by a
// short locating pip that enters the Pi's mounting hole. The pip is deliberately
// SHORTER than the PCB is thick, so it never protrudes above the board and the
// lid's hold-down pad can bear on a flat surface. Nothing here flexes -- see the
// standoff parameter block for why the snap-post version was abandoned.
module standoff() {
    cylinder(d = standoff_od, h = standoff_h);
    // slight taper on the pip so a board dropped in roughly still finds the hole
    translate([0, 0, standoff_h - 0.01])
        cylinder(d1 = pip_d, d2 = pip_d - 0.4, h = pip_h + 0.01);
    assert(pip_d < pi_hole_d, "locating pip must enter the Pi's mounting hole");
    assert(pip_h < pcb_t, "pip must stay below flush so the lid pad can bear flat");
}

module standoff_field() {
    // board sits with its lower-left mount hole at (hole_edge, hole_edge)
    for (x = [hole_edge, hole_edge + hole_dx])
        for (y = [hole_edge, hole_edge + hole_dy])
            translate([x, y, 0]) standoff();
    assert(hole_dx == 58 && hole_dy == 49, "Pi 4 mount pattern must stay 58x49");
}

// Keyed socket protruding +Y on the GPIO wall. Built in GLOBAL tray z (placed
// at z=0, not at z=floor) so its underside sits on the bed -- the previous
// version floated a 10 x 12 mm slab 2 mm above the bed with nothing beneath
// it, an unsupported overhang in a design that claims to print support-free.
//
// The bore is open at the OUTBOARD (+Y) face and blind at the inboard end,
// where the tray wall closes it. The previous version had it capped outboard
// AND closed by the tray wall, i.e. a sealed cavity: the arm could not be
// inserted and its bar intersected the cap by 100 mm^3.
//
// The key is a notch cut UP into the bore ceiling; the tenon's top rib seats in
// it, so the tenon only enters right-side-up (a 180 deg roll puts the rib on
// the notch-less floor and blocks insertion).
module tray_socket() {
    sx    = arm_w + socket_fit;
    sz    = arm_h + socket_fit;
    bore_z = floor + wall - socket_fit / 2;    // centres the bore on the tenon
    top_z  = bore_z + sz;

    assert(bore_z > 0, "socket bore must clear the bed");

    difference() {
        cube([sx + 2 * wall, socket_depth, top_z + wall]);

        // tenon bore: through to the outboard face, blind inboard (tray wall)
        translate([wall, -0.1, bore_z]) cube([sx, socket_depth + 0.2, sz]);

        // key notch up into the bore ceiling, full depth
        translate([wall + sx / 2 - key_w / 2, -0.1, top_z - 0.01])
            cube([key_w, socket_depth + 0.2, key_h + 0.01]);
    }
}

module tray() {
    // inner cavity spans the board + fit
    in_x = board_w + 2 * board_fit;
    in_y = board_l + 2 * board_fit;
    out_x = in_x + wall;      // wall only on x-min (SD side); x-max open
    out_y = in_y + wall;      // wall only on +Y (GPIO side); -Y open

    // snap-ridge chamfer profile: a wedge that tapers from a taller
    // cross-section flush with the wall face down to a shorter cross-section
    // at the tip, giving ~45 deg chamfers top and bottom (rise ~= run ==
    // snap_ridge_h) so it prints support-free and a lid groove can ride over it.
    ridge_tip_half  = ridge_base_half - snap_ridge_h;  // half-height at the tip
    ridge_slab      = 0.03;                   // thin slab thickness for hull()

    difference() {
        union() {
            // floor
            cube([out_x, out_y, floor]);
            // x-min wall (SD short edge)
            cube([wall, out_y, floor + tray_wall_h]);
            // +Y wall (GPIO long edge)
            translate([0, in_y, 0]) cube([out_x, wall, floor + tray_wall_h]);
            // snap ridges on the outer (x=0, facing -X) face of the x-min wall.
            // TWO segments flanking the SD notch (snap_seg_x = [y0,len] along y).
            for (seg = snap_seg_x)
                hull() {
                    translate([-0.01, seg[0], snap_ridge_z - ridge_base_half])
                        cube([ridge_slab, seg[1], 2 * ridge_base_half]);
                    translate([-snap_ridge_h, seg[0], snap_ridge_z - ridge_tip_half])
                        cube([ridge_slab, seg[1], 2 * ridge_tip_half]);
                }
            // snap ridges on the outer (y=out_y, facing +Y) face of the +Y wall.
            // TWO segments flanking the arm socket (snap_seg_y = [x0,len] along x).
            for (seg = snap_seg_y)
                hull() {
                    translate([seg[0], out_y - ridge_slab + 0.01,
                               snap_ridge_z - ridge_base_half])
                        cube([seg[1], ridge_slab, 2 * ridge_base_half]);
                    translate([seg[0], out_y + snap_ridge_h - ridge_slab,
                               snap_ridge_z - ridge_tip_half])
                        cube([seg[1], ridge_slab, 2 * ridge_tip_half]);
                }
        }
        // SD notch in the x-min wall. Cut reaches past x=0 by snap_ridge_h+0.1
        // (not just the wall face) so it also punches cleanly through the new
        // snap ridge, which is centred on the same wall and would otherwise
        // leave a thin unsupported rib bridging the SD-card opening.
        translate([-(snap_ridge_h + 0.1), sd_slot_y, sd_slot_z])
            cube([wall + snap_ridge_h + 0.2, sd_slot_w, sd_slot_h]);
        // DHT22 cable exit in the +Y wall. Same reasoning: extend past
        // y=out_y by snap_ridge_h+0.1 so the cut also clears the snap ridge
        // on this wall instead of leaving a rib across the cable exit.
        translate([(out_x - cable_slot_w) / 2, in_y - 0.1, floor + standoff_h])
            cube([cable_slot_w, wall + snap_ridge_h + 0.2, cable_slot_h]);
        // floor vents under the board
        for (i = [-2 : 2])
            translate([out_x / 2 + i * (vent_slot_w + vent_gap) - vent_slot_w / 2,
                       (out_y - vent_slot_len) / 2, -0.1])
                cube([vent_slot_w, vent_slot_len, floor + 0.2]);
    }
    // standoffs, seated so the board's holes land on the 58x49 pattern
    translate([wall + board_fit, board_fit, floor]) standoff_field();
    // arm socket on the GPIO wall, protruding +Y. Placed at z=0 (not z=floor)
    // so it prints off the bed instead of overhanging; tray_socket() builds its
    // bore at the right height internally.
    translate([(out_x - (arm_w + socket_fit + 2 * wall)) / 2, out_y, 0])
        tray_socket();
}

module lid_assembled() {
    // ---- derived geometry (ASSEMBLED coords, z up from tray floor bottom) ----
    board_top = floor + standoff_h + pcb_t;          // 8.4  board top surface
    jump_top  = board_top + jump_stack;              // top of the GPIO jumpers
    out_x     = board_w + 2 * board_fit + wall;       // 87.8 tray outer (x-min wall @ x=0)
    out_y     = board_l + 2 * board_fit + wall;       // 58.8 tray outer (+Y wall face)
    top_z0    = board_top + lid_clear;                // 28.4 top-plate underside
    top_z1    = top_z0 + lid_wall;                    // 30.4 top-plate top
    skirt_z0  = 5.0;                                  // skirt bottom (below the z=9 ridge)

    // top-plate footprint. x-min & +Y edges align with the skirt outers; the
    // -Y (AV) and x-max (Ethernet) edges only overhang the tray by lid_fit and
    // carry NO skirt -> those two sides are open port channels.
    px0 = -(snap_ridge_h + lid_fit) - lid_wall;       // -3.1 x-min skirt outer
    px1 = out_x + lid_fit;                            //  88.1 x-max open overhang
    py0 = -lid_fit;                                   //  -0.3 -Y open overhang
    py1 = out_y + snap_ridge_h + lid_fit + lid_wall;  //  61.9 +Y skirt outer

    // Skirt engagement. The LIP face rides the tray wall with lid_fit clearance
    // and INTERFERES with the ridge tip (which protrudes snap_ridge_h outward),
    // so the skirt flexes out over the ridge on the way down. The GROOVE is a
    // pocket at the ridge z-band; when it aligns the skirt springs back and the
    // solid lip above/below the groove hooks the ridge -> snap retention.
    // (The tray ridge only reaches x=-snap_ridge_h=-0.8, so a lip parked at the
    // spec's -1.1 could never touch it; the lip is placed at -lid_fit to engage,
    // and -1.1 / 59.9 are kept as the groove FLOORS.)
    xlip   = -lid_fit;                                // -0.3 x-min lip face
    xfloor = -(snap_ridge_h + lid_fit);              // -1.1 x-min groove floor
    ylip   = out_y + lid_fit;                         // 59.1 +Y lip face
    yfloor = out_y + snap_ridge_h + lid_fit;         // 59.9 +Y groove floor
    gz0 = snap_ridge_z - groove_half;                 // groove z-bottom
    gz1 = snap_ridge_z + groove_half;                 // groove z-top
    eps = 0.01;

    assert(gz0 < snap_ridge_z && snap_ridge_z < gz1, "groove must straddle ridge centre");

    difference() {
        union() {
            // top plate
            translate([px0, py0, top_z0])
                cube([px1 - px0, py1 - py0, top_z1 - top_z0]);

            // hold-down pads: four tapered pillars descending from the top
            // plate to just below the board's top face, concentric with the
            // tray standoffs. They are what actually retains the Pi -- the
            // clamp path is pad -> board -> standoff collar, so the board is
            // pinched at four points with no bending moment and nothing that
            // has to flex. Tapered (wider at the plate) because the lid prints
            // closed-top-down: in print orientation these are upright pillars
            // standing on their wide end.
            for (hx = [hole_edge, hole_edge + hole_dx])
                for (hy = [hole_edge, hole_edge + hole_dy])
                    translate([wall + board_fit + hx, board_fit + hy,
                               board_top - hold_preload])
                        difference() {
                            union() {
                                // Straight Ø hold_d for the whole height the
                                // GPIO jumpers occupy. The flare below would
                                // otherwise lean out over the header, which
                                // sits only ~3.5 mm from these holes.
                                cylinder(d = hold_d,
                                         h = jump_top - board_top + hold_preload);
                                // Flare only ABOVE the jumpers. Its only job is
                                // bed adhesion: the lid prints closed-top-down,
                                // so this wide end is what stands on the bed.
                                translate([0, 0, jump_top - board_top + hold_preload])
                                    cylinder(d1 = hold_d, d2 = hold_base_d,
                                             h = top_z0 - jump_top + 0.01);
                            }
                            // clear the locating pip standing in the board's hole
                            translate([0, 0, -0.05])
                                cylinder(d = hold_bore_d, h = hold_bore_h + 0.05);
                        }

            // x-min skirt (SD side), grooved over the ridge segments (snap_seg_x).
            // Skirt top runs up to top_z1 so it overlaps the plate volume (a
            // merged union -> single body; a coplanar touch at top_z0 would not).
            difference() {
                translate([px0, py0, skirt_z0])
                    cube([xlip - px0, py1 - py0, top_z1 - skirt_z0]);
                for (seg = snap_seg_x)                      // groove breaks past lip face (+eps)
                    translate([xfloor, seg[0], gz0])
                        cube([xlip - xfloor + eps, seg[1], gz1 - gz0]);
            }

            // +Y skirt (GPIO side): grooved over snap_seg_y, and cut fully open
            // over the arm socket (x[32,56], protrudes to y=70.8). That gap sits
            // between the two ridge segments, so it removes no groove.
            difference() {
                translate([px0, ylip, skirt_z0])
                    cube([px1 - px0, py1 - ylip, top_z1 - skirt_z0]);
                for (seg = snap_seg_y)                      // groove breaks past lip face (-eps)
                    translate([seg[0], ylip - eps, gz0])
                        cube([seg[1], yfloor - ylip + eps, gz1 - gz0]);
                translate([32, ylip - eps, skirt_z0 - eps])       // socket/cable gap
                    cube([56 - 32, (py1 - ylip) + 2 * eps, (top_z0 - skirt_z0) + eps]);
            }
        }
        // top vent grid: bridge-printable slots through the plate
        for (i = [-3 : 3])
            translate([(px0 + px1) / 2 + i * (vent_slot_w + vent_gap) - vent_slot_w / 2,
                       (py0 + py1) / 2 - vent_slot_len / 2, top_z0 - eps])
                cube([vent_slot_w, vent_slot_len, (top_z1 - top_z0) + 2 * eps]);
        // LED window through the plate, near the USB-C corner (-Y / x-min)
        translate([8 - led_win_w / 2, 4 - led_win_h / 2, top_z0 - eps])
            cube([led_win_w, led_win_h, (top_z1 - top_z0) + 2 * eps]);
    }
}

module lid() {
    // Print orientation only: flip the assembled-coords lid closed-top-down
    // onto the bed (rotate 180 about X, translate so min z = 0, skirts
    // pointing up) so it prints support-free. Geometry itself lives in
    // lid_assembled(); this wrapper just recomputes the two placement values
    // (py1, top_z1) needed for the flip transform.
    board_top = floor + standoff_h + pcb_t;
    out_y     = board_l + 2 * board_fit + wall;
    top_z0    = board_top + lid_clear;
    top_z1    = top_z0 + lid_wall;
    py1       = out_y + snap_ridge_h + lid_fit + lid_wall;

    translate([0, py1, top_z1]) rotate([180, 0, 0])
        lid_assembled();
}

module pi_ghost() {
    // Visual-only stand-in for the Pi 4 board: 85x56x1.4 slab with the four
    // Ø2.7 mount holes on the 58x49 pattern, same corner scheme as
    // standoff_field() (hole_edge inset from each edge).
    pi_hole_d = 2.7;
    difference() {
        cube([board_w, board_l, pcb_t]);
        for (x = [hole_edge, hole_edge + hole_dx])
            for (y = [hole_edge, hole_edge + hole_dy])
                translate([x, y, -0.1])
                    cylinder(h = pcb_t + 0.2, d = pi_hole_d);
    }
}

module fit_coupon() {
    cx = 32; cy = 28;
    union() {
        cube([cx, cy, floor]);                                  // tile
        cube([wall, cy, floor + tray_wall_h]);                  // one walled edge (SD/GPIO-like)
        // one standoff corner, at the SAME offset the tray uses. Omitting
        // board_fit here (as an earlier version did) put the standoff 0.4 mm
        // closer to the wall than the tray does, so the coupon tested a
        // zero-clearance board edge -- conservative, but not what gets printed.
        translate([wall + board_fit + hole_edge, board_fit + hole_edge, floor])
            standoff();
        // stub of the open-channel edge: a 2 mm-tall lip only, so a port stack clears above it
        translate([0, cy - wall, 0]) cube([cx, wall, floor + 2]);
    }
}

// Cheap test print for the arm joint: the socket exactly as the tray carries
// it, on a small base pad. Lets the fit be checked against the already-printed
// arm for a few grams, rather than discovering it after an 8-hour tray.
//
// PRINT IT AS EXPORTED -- do not rotate it onto another face. The whole point
// is that it reproduces how the socket prints as part of the TRAY, which prints
// floor-down and therefore always has this bore horizontal. Standing the gauge
// on end gives a nicer bore and a meaningless result.
module socket_gauge() {
    sw  = arm_w + socket_fit + 2 * wall;
    pad = 4;
    h   = floor + wall + arm_h + socket_fit + wall;
    // Back stop stands in for the tray wall that closes the bore. It sits
    // BEHIND the socket (y < wall), not inside it -- placed inside, it would
    // eat the first 2 mm of bore and bottom the tenon out early, so the gauge
    // would report a shallower fit than the tray actually gives.
    cube([sw + 2 * pad, wall, h]);
    translate([pad, wall, 0]) tray_socket();
    // base pad, so the gauge stands up the way the tray floor holds the socket
    cube([sw + 2 * pad, socket_depth + wall, floor]);
}
// Cheap test print for the LAST untested sprung feature: the lid snap. Cut
// straight out of lid_assembled() -- an intersection, not a re-model -- so the
// skirt, lip and groove are bit-identical to the real lid and cannot drift.
//
// Covers one segment of the +Y (GPIO) wall snap. Press it onto the real printed
// tray's ridge to judge the snap force before committing to the 22 cm^3 lid.
//
// Print AS EXPORTED. It is flipped the same way lid() is, so the skirt points
// up and the groove's overhang faces the same way it will on the real lid; a
// coupon printed in some other orientation would not predict the real one.
// The FIRST version of this gauge was wrong in a way worth recording: it cut
// the skirt off ~7 mm above the groove and stood it on a foot. But on the real
// lid the skirt hangs from the TOP PLATE, putting the groove ~28 mm from its
// root. Cantilever stiffness goes as 1/L^3, so that gauge was about 67x stiffer
// than the thing it was meant to predict -- it would have read "far too tight"
// on a snap that is actually fine. A gauge that misreports force is worse than
// no gauge.
//
// So the slice now runs the FULL height, from the skirt's free bottom edge up
// through a strip of top plate, and is rooted the way the real skirt is. No
// foot: the flip puts the top plate on the bed, which is also how lid() prints.
//
// Residual limit, stated honestly: this is still a straight slice with no
// corners, and the real plate is a large stiff diaphragm rather than a 24 mm
// strip. It will read somewhat STIFFER than the real lid. Treat "firm but it
// clicks" as good; only act on an extreme result.
module lid_gauge() {
    out_y  = board_l + 2 * board_fit + wall;
    top_z1 = floor + standoff_h + pcb_t + lid_clear + lid_wall;
    py1    = out_y + snap_ridge_h + lid_fit + lid_wall;
    seg    = snap_seg_y[0];                        // [x0, len] of one +Y segment
    x0     = seg[0] + 2;
    xw     = min(seg[1] - 4, 20);
    yback  = out_y - 24;                           // top plate kept as the root

    translate([0, py1, top_z1]) rotate([180, 0, 0])
        intersection() {
            lid_assembled();
            translate([x0, yback, 0])
                cube([xw, py1 - yback + 1, top_z1 + 1]);
        }
}

module assembly() {
    // Visual-only view (not printed): tray + Pi ghost + snap-fit lid + plugged
    // sensor arm, all in ASSEMBLED coords (tray at origin, z up from floor).
    out_x = board_w + 2 * board_fit + wall;   // 87.8 tray outer, x-min wall @ x=0
    out_y = board_l + 2 * board_fit + wall;   // 58.8 tray outer, +Y wall face

    // Lid is lifted a small, purely-cosmetic amount so the snap grooves/ridges
    // are visible in the render instead of being hidden flush against the
    // tray wall. This is a visual explode ONLY -- the lid's true seated
    // position (no offset) is what lid_assembled() returns.
    lid_explode = 8;

    tray();

    // Pi board ghost, seated on the standoffs (board bottom at z = floor+standoff_h)
    % translate([wall + board_fit, board_fit, floor + standoff_h])
        pi_ghost();

    // Lid, in its true assembled position, lifted by lid_explode for visibility.
    translate([0, 0, lid_explode])
        lid_assembled();

    // Sensor arm plugged into the +Y (GPIO) socket: tenon nested in the bore
    // (centred on the socket, x = out_x/2, y = out_y, z = floor+wall), arm
    // body + sensor pocket extending further +Y, away from the tray.
    translate([out_x / 2, out_y, floor + wall])
        rotate([0, 0, 90])
            arm();
}
