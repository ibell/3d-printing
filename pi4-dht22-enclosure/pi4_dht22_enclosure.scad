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

/* modules added in later tasks */
module tray()         {}
module lid()          {}
module fit_coupon()   {}
module assembly()     {}
