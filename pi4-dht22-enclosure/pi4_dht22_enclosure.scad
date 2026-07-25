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
snap_ridge_w = 20.0;  // ridge length along the wall
snap_ridge_z = floor + tray_wall_h - 3.0;  // z of ridge centre (near wall top)
lid_clear   = 20.0;    // internal clear height above board top
lid_wall    = 2.0;
lid_lip     = 4.0;     // lip overlap depth
lid_fit     = 0.3;     // lid-over-tray clearance

/* ---------- standoffs ---------- */
standoff_h  = 5.0;
standoff_od = 6.0;

/* ---------- lid fixing (M3) ---------- */
lid_screw_d = 3.2;     // clearance hole in lid
boss_d      = 7.0;     // tray corner boss OD
boss_pilot  = 2.5;     // M3 self-tap pilot in boss

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
arm_foot     = true;
foot_len     = 16.0;
foot_h       = 3.0;

/* ---------- arm socket (tray, GPIO side) ---------- */
socket_depth = 10.0;   // tenon length
socket_fit   = 0.4;
setscrew_d   = 3.2;

/* ---------- DHT22 module pocket (drop-in cavity) ---------- */
sensor_pcb_w    = 37.0;   // module width  -> cavity X
sensor_pcb_h    = 10.0;   // drop-in depth -> cavity Z
sensor_pcb_t    = 10.0;   // module thick  -> cavity Y (into front face)
sensor_slot_fit = 0.2;
pocket_wall     = 2.0;
sensor_grille_w = 30.0;   // front airflow window
sensor_grille_h = 7.0;
cable_hole_w    = 8.0;
cable_hole_h    = 4.0;
lip_proud       = 0.8;    // retention lip overhang at mouth

/* ---------- optional ---------- */
wall_mount_tabs = false;

/* ---------- global sanity asserts ---------- */
assert(wall > 0 && floor > 0 && pocket_wall > 0, "thicknesses must be positive");
assert(board_fit >= 0 && sensor_slot_fit >= 0, "fits must be non-negative");

/* ---------- dispatcher ---------- */
if      (part == "_smoke")       cube(10);
else if (part == "sensor_gauge") sensor_gauge();
else if (part == "arm")          arm();
else if (part == "tray")         tray();
else if (part == "lid")          lid();
else if (part == "fit_coupon")   fit_coupon();
else if (part == "assembly")     assembly();
else echo(str("unknown part: ", part));

module sensor_pocket() {
    cav_x = sensor_pcb_w + sensor_slot_fit;   // width
    cav_y = sensor_pcb_t + sensor_slot_fit;   // thickness (into +Y face)
    cav_z = sensor_pcb_h + sensor_slot_fit;   // drop-in depth
    out_x = cav_x + 2 * pocket_wall;
    out_y = cav_y + 2 * pocket_wall;
    out_z = cav_z + pocket_wall;              // floor only; mouth open at top

    assert(pocket_wall > 0, "pocket_wall must be positive");
    assert(sensor_grille_w <= cav_x, "grille wider than cavity");
    assert(sensor_grille_h <= cav_z, "grille taller than cavity");

    difference() {
        // outer block
        cube([out_x, out_y, out_z]);
        // cavity (open top = mouth for drop-in)
        translate([pocket_wall, pocket_wall, pocket_wall])
            cube([cav_x, cav_y, cav_z + 0.1]);
        // grille window in +Y face
        translate([(out_x - sensor_grille_w) / 2, out_y - pocket_wall - 0.1,
                   pocket_wall + (cav_z - sensor_grille_h) / 2])
            cube([sensor_grille_w, pocket_wall + 0.2, sensor_grille_h]);
        // cable hole in -Y face
        translate([(out_x - cable_hole_w) / 2, -0.1,
                   pocket_wall + (cav_z - cable_hole_h) / 2])
            cube([cable_hole_w, pocket_wall + 0.2, cable_hole_h]);
    }
    // two retention lips, rooted in the X-end walls (x in [0,pocket_wall] and
    // x in [out_x-pocket_wall,out_x]). Each lip is the convex hull of a "back"
    // sliver flush against the wall's inner face (a full shared face with the
    // solid wall, from z=out_z-lip_proud to z=out_z) and a "tip" sliver
    // protruding inward by lip_proud right at the mouth (z=out_z). The hull
    // between them gives a ~45 deg chamfered underside, so the lip overhangs
    // the cavity mouth (catching the top edge of the dropped-in module)
    // without needing print support. Neither sliver rises above out_z, so the
    // block's overall height is unchanged.
    lip_len = cav_y * 0.6;                       // span along Y, centred in cavity
    lip_y0  = pocket_wall + (cav_y - lip_len) / 2;
    lip_eps = 0.01;                               // sliver thickness, for hull()

    // left lip, on the x=0..pocket_wall wall, overhanging in +x
    hull() {
        translate([pocket_wall, lip_y0, out_z - lip_proud])
            cube([lip_eps, lip_len, lip_proud]);
        translate([pocket_wall + lip_proud - lip_eps, lip_y0, out_z - lip_eps])
            cube([lip_eps, lip_len, lip_eps]);
    }
    // right lip, on the out_x-pocket_wall..out_x wall, overhanging in -x
    hull() {
        translate([out_x - pocket_wall - lip_eps, lip_y0, out_z - lip_proud])
            cube([lip_eps, lip_len, lip_proud]);
        translate([out_x - pocket_wall - lip_proud, lip_y0, out_z - lip_eps])
            cube([lip_eps, lip_len, lip_eps]);
    }
}

module sensor_gauge() { sensor_pocket(); }

module arm() {
    pocket_x = sensor_pcb_t + sensor_slot_fit + 2 * pocket_wall; // depth once rotated
    pocket_y = sensor_pcb_w + sensor_slot_fit + 2 * pocket_wall; // width once rotated
    span_end = socket_depth + arm_len;                          // where pocket begins

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

    // pocket at the end, rotated so its +Y grille faces +X (outboard)
    translate([span_end, 0, 0])
        rotate([0, 0, -90])
            translate([-pocket_y / 2, 0, 0])   // recentre width on the arm axis
                sensor_pocket();

    // optional desk foot under the pocket end
    if (arm_foot)
        translate([span_end - foot_len, -arm_w / 2, -foot_h])
            cube([foot_len + pocket_x, arm_w, foot_h + 0.01]);
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
    // keyed rectangular socket protruding +Y on the GPIO wall; keyed by a notch
    sx = arm_w + socket_fit;
    sz = arm_h + socket_fit;
    difference() {
        translate([0, 0, 0]) cube([sx + 2 * wall, socket_depth + wall, sz + 2 * wall]);
        translate([wall, -0.1, wall]) cube([sx, socket_depth + 0.1, sz]);      // tenon bore
        translate([wall + sx / 2, socket_depth / 2, sz + wall])                 // set screw
            cylinder(h = wall + 0.2, d = setscrew_d);
        translate([wall + sx / 2 - 1, -0.1, wall]) cube([2, socket_depth, 1.5]); // key notch
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
            // snap ridge on the outer (x=0, facing -X) face of the x-min wall
            hull() {
                translate([-0.01, out_y / 2 - snap_ridge_w / 2,
                           snap_ridge_z - ridge_base_half])
                    cube([ridge_slab, snap_ridge_w, 2 * ridge_base_half]);
                translate([-snap_ridge_h, out_y / 2 - snap_ridge_w / 2,
                           snap_ridge_z - ridge_tip_half])
                    cube([ridge_slab, snap_ridge_w, 2 * ridge_tip_half]);
            }
            // snap ridge on the outer (y=out_y, facing +Y) face of the +Y wall
            hull() {
                translate([out_x / 2 - snap_ridge_w / 2, out_y - ridge_slab + 0.01,
                           snap_ridge_z - ridge_base_half])
                    cube([snap_ridge_w, ridge_slab, 2 * ridge_base_half]);
                translate([out_x / 2 - snap_ridge_w / 2, out_y + snap_ridge_h - ridge_slab,
                           snap_ridge_z - ridge_tip_half])
                    cube([snap_ridge_w, ridge_slab, 2 * ridge_tip_half]);
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

/* modules added in later tasks */
module lid()          {}
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
module assembly()     {}
