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
hole_pilot_d = 2.2;    // M2.5 self-tap pilot

/* ---------- shell ---------- */
wall        = 2.0;
floor       = 2.0;
board_fit   = 0.4;
tray_wall_h = 10.0;    // tray wall height above floor
snap_ridge_h = 0.8;   // how far the ridge protrudes out from the wall
snap_ridge_z = floor + tray_wall_h - 3.0;  // z of ridge centre (near wall top)
lid_clear   = 20.0;    // internal clear height above board top
lid_wall    = 2.0;
lid_fit     = 0.3;     // lid-over-tray clearance

/* ---------- snap-fit ridge/groove segments (shared by tray + lid) ----------
   Each wall carries TWO ridge segments that FLANK its obstruction; the lid's
   grooves reuse the same lists so the mate is guaranteed. Entries are
   [start, length] along the wall.
   x-min (SD) wall: y-segments flank the SD notch (y[22.4,36.4]).
   +Y  (GPIO) wall: x-segments flank the arm socket (x[36.7,51.1]) & cable slot. */
snap_seg_x = [[4, 16], [39, 16]];   // x-min wall, along y -> y[4,20] & y[39,55]
snap_seg_y = [[6, 24], [56, 24]];   // +Y  wall, along x -> x[6,30] & x[56,80]

/* ---------- standoffs ---------- */
standoff_h  = 5.0;
standoff_od = 6.0;

/* ---------- ventilation ---------- */
vent_slot_w   = 3.0;
vent_slot_len = 24.0;
vent_gap      = 3.0;

/* ---------- microSD notch (SD short edge = x-min) ---------- */
sd_slot_w = 14.0;
sd_slot_h = 4.0;

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

/* ---------- arm socket (tray, GPIO side) ---------- */
socket_depth = 10.0;   // tenon length
socket_fit   = 0.4;
setscrew_d   = 3.2;
key_w        = 2.0;    // socket ceiling notch width (X); mates the tenon key rib
key_h        = 1.5;    // notch depth up into the bore ceiling (Z)
key_fit      = 0.4;    // rib-in-notch lateral clearance

/* ---------- DHT22 sensor board + snap-post cradle ---------- */
// Measured off the board in hand (2026-08-15): 29.52 x 13.0 mm, ONE mounting
// hole of 2.85 mm. A single hole cannot stop the board rotating about the post,
// so the cradle adds side rails that capture the board's width; the post then
// only has to retain it vertically. See sensor_cradle().
board_len      = 29.52;  // PCB length along the arm axis (cable end -> sensor end)
board_wid      = 13.0;   // PCB width
board_thk      = 1.6;    // measured PCB thickness
mnt_from_end   = 7.2;    // measured hole centre, from the cable/near end
mnt_hole_d     = 2.85;   // measured board mounting-hole diameter
grip_len       = 16.0;   // cradle pad + rail length under the board's near end
rail_t         = 2.0;    // anti-rotation side rail thickness
rail_fit       = 0.3;    // total width clearance between the rails
board_lift     = 3.0;    // airflow gap: board sits this far above the pad
cradle_gauge_t = 3.0;    // pad thickness for the standalone sensor_gauge test print
post_shaft_d   = 2.75;   // snap-post shaft dia; 0.10 under the hole (was 2.6 -> wobbled)
post_barb_d    = 3.4;    // barb outer dia (> hole -> retains the board)
post_barb_h    = 1.4;    // barb height (chamfered lead-in cone)
post_slot_w    = 1.0;    // central flex slot: splits the post into two prongs
post_fit       = 0.15;   // vertical clearance so the board seats under the barb

/* ---------- global sanity asserts ---------- */
assert(wall > 0 && floor > 0, "thicknesses must be positive");
assert(board_fit >= 0 && post_fit >= 0, "fits must be non-negative");
assert(post_barb_d > mnt_hole_d && post_shaft_d < mnt_hole_d,
       "snap post must clear the board hole yet retain it");
assert(mnt_from_end > post_barb_d / 2 && mnt_from_end < grip_len,
       "mounting hole must land on the cradle pad");
assert(board_len > grip_len, "board must cantilever past the pad into free air");

/* ---------- dispatcher ---------- */
if      (part == "_smoke")       cube(10);
else if (part == "sensor_gauge") sensor_gauge();
else if (part == "arm")          arm();
else if (part == "tray")         tray();
else if (part == "lid")          lid();
else if (part == "fit_coupon")   fit_coupon();
else if (part == "assembly")     assembly();
else echo(str("unknown part: ", part));

// One split snap-post at the local origin, rising in +Z from z=0.
// A support collar lifts the board for airflow; a slotted shaft passes through
// the board's mounting hole and a chamfered barb snaps over the top to retain
// it. The central slot splits the post into two prongs that flex together as
// the board is pushed on, then spring back under the barb.
module snap_post() {
    // support collar (board rests on this -> airflow gap underneath)
    cylinder(d = post_shaft_d + 2.4, h = board_lift);
    difference() {
        union() {
            translate([0, 0, board_lift])
                cylinder(d = post_shaft_d, h = board_thk + post_fit);
            // barb: cone from full width (flat retaining underside) to a point
            translate([0, 0, board_lift + board_thk + post_fit])
                cylinder(d1 = post_barb_d, d2 = 1.0, h = post_barb_h);
        }
        // flex slot across the shaft + barb (not the collar)
        translate([-post_slot_w / 2, -(post_barb_d / 2 + 0.5), board_lift - 0.01])
            cube([post_slot_w, post_barb_d + 1,
                  board_thk + post_fit + post_barb_h + 0.1]);
    }
}

// Snap-post cradle: a pad under the board's near (cable) end carrying ONE snap
// post plus two anti-rotation side rails. The board drops in from above between
// the rails -- which hug its width and so fix its angle, the job the second post
// used to do -- and the post's prongs flex through the single mounting hole and
// spring back to retain it vertically. The rails stop flush with the seated
// board's top face, so it drops straight down rather than sliding in end-on.
// The sensor end cantilevers off the +X end into free air; the cable exits the
// near end and drops into the arm's groove. `pad_h` sets the pad height so the
// same cradle serves the low standalone gauge and the arm-height version.
// Local frame: board near edge at x=0, board runs +X, width centred on Y.
module sensor_cradle(pad_h) {
    gap    = board_wid + rail_fit;            // clear span between the rails
    pad_w  = gap + 2 * rail_t;
    back   = 6;                               // pad reach behind the board's near edge
    rail_h = board_lift + board_thk;          // flush with the seated board top

    translate([-back, -pad_w / 2, 0])
        cube([grip_len + back, pad_w, pad_h]);
    for (sy = [-(gap + rail_t) / 2, (gap + rail_t) / 2])
        translate([0, sy - rail_t / 2, pad_h])
            cube([grip_len, rail_t, rail_h]);
    translate([mnt_from_end, 0, pad_h]) snap_post();
}

module sensor_gauge() { sensor_cradle(cradle_gauge_t); }

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

module standoff() {
    difference() {
        cylinder(h = standoff_h, d = standoff_od);
        translate([0, 0, -0.1])
            cylinder(h = standoff_h + 0.2, d = hole_pilot_d);
    }
}

module standoff_field() {
    // board sits with its lower-left mount hole at (hole_edge, hole_edge)
    for (x = [hole_edge, hole_edge + hole_dx])
        for (y = [hole_edge, hole_edge + hole_dy])
            translate([x, y, 0]) standoff();
    assert(hole_dx == 58 && hole_dy == 49, "Pi 4 mount pattern must stay 58x49");
}

module tray_socket() {
    // keyed rectangular socket protruding +Y on the GPIO wall. The key is a
    // notch cut UP into the bore ceiling; the arm tenon's top rib seats in it,
    // so the tenon can only enter right-side-up (a 180 deg roll puts the rib on
    // the notch-less floor and blocks insertion).
    sx = arm_w + socket_fit;
    sz = arm_h + socket_fit;
    difference() {
        translate([0, 0, 0]) cube([sx + 2 * wall, socket_depth + wall, sz + 2 * wall]);
        translate([wall, -0.1, wall]) cube([sx, socket_depth + 0.1, sz]);      // tenon bore
        translate([wall + sx / 2, socket_depth / 2, sz + wall])                 // set screw
            cylinder(h = wall + 0.2, d = setscrew_d);
        // key notch: channel up into the bore ceiling, centred on the bore,
        // running the full tenon depth; mates the arm tenon's top key rib.
        translate([wall + sx / 2 - key_w / 2, -0.1, wall + sz - 0.01])
            cube([key_w, socket_depth + 0.1, key_h + 0.01]);
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
    ridge_base_half = 1.5;                    // half-height at the wall face
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
        translate([-(snap_ridge_h + 0.1), (out_y - sd_slot_w) / 2, floor + standoff_h])
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
    // arm socket on the GPIO wall, protruding +Y
    translate([(out_x - (arm_w + socket_fit + 2 * wall)) / 2, out_y, floor])
        tray_socket();
}

module lid_assembled() {
    // ---- derived geometry (ASSEMBLED coords, z up from tray floor bottom) ----
    board_top = floor + standoff_h + pcb_t;          // 8.4  board top surface
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
    gz0 = snap_ridge_z - 1.0;                         //  8.0 groove z-bottom (mates ridge z=9)
    gz1 = snap_ridge_z + 1.0;                         // 10.0 groove z-top
    eps = 0.01;

    assert(gz0 < snap_ridge_z && snap_ridge_z < gz1, "groove must straddle ridge centre");

    difference() {
        union() {
            // top plate
            translate([px0, py0, top_z0])
                cube([px1 - px0, py1 - py0, top_z1 - top_z0]);

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
        translate([wall + hole_edge, hole_edge, floor]) standoff();   // one standoff corner
        // stub of the open-channel edge: a 2 mm-tall lip only, so a port stack clears above it
        translate([0, cy - wall, 0]) cube([cx, wall, floor + 2]);
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
