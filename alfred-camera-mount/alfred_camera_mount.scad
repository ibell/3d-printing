// Alfred camera mount: one small printed piece that slips over the USB-A plug
// body in a wall wart and holds the camera directly above it, looking straight
// out from the wall. Select a body with -D 'part="..."'.
//
// Axes: XY is the vertical plane of the camera's front face, X horizontal,
// Y up. Z points away from the wall. z = 0 is the outer end of the USB-A
// plastic body, and the frame's front face sits in that same plane.
//
// Prints front-face down, no supports: every feature rises straight off the bed.

part = "assembly";   // "frame" | "screw" | "screw_thin" | "assembly"
$fn  = 96;

/* ---------- camera (measured) ---------- */
cam_w     = 56.05;   // front face is a square, left-right = top-bottom
cam_diag  = 63.5;    // corner-to-corner across the rounded corners
// corner radius that turns a cam_w square into one with cam_diag diagonal:
// diag = w*sqrt2 - 2r(sqrt2 - 1)
cam_r     = (cam_w*sqrt(2) - cam_diag) / (2*(sqrt(2) - 1));   // ~19.0
cam_d     = 30;      // ASSUMED depth, only used for the ghost in the assembly

/* ---------- USB-A plug body (measured) ---------- */
usb_w     = 15.72;   // horizontal
usb_t     = 7.81;    // vertical
usb_len   = 17.66;

/* ---------- fit ---------- */
usb_fit   = 0.15;    // per-side clearance on the plug body
rib_h     = 0.35;    // retention ribs stand this far off the sleeve's wide
                     // inner faces -> rib_h - usb_fit = 0.20 mm grip.
                     // First print at 0.15 with no ribs: a bit too loose.
cam_fit   = 0.25;    // per-side clearance on the camera sides

/* ---------- frame ---------- */
ring_wall = 2.0;     // ring thickness around the camera's sides
ring_d    = 8.0;     // how far the ring reaches back along the camera
bezel     = 1.5;     // front lip overlapping the camera face; the camera is
                     // pushed in from behind and stops against it
bezel_t   = 1.2;     // lip thickness (camera face ends up this far back)
sl_wall   = 2.0;     // sleeve wall around the plug body
sl_len    = 14.0;    // sleeve length; shorter than usb_len so the sleeve can
                     // never butt on the wart face and hold the plug out
lift      = 20.0;    // extra height of the camera ring above the sleeve.
                     // First print (lift 0) put the camera into the wall wart.

/* ---------- set screw (printed) ---------- */
// single-start thread made by twisting an off-centre circle: crude but it
// prints vertically on any FDM printer and mates with its own nut.
scr_d     = 6.0;     // major diameter
scr_ecc   = 0.6;     // thread depth = 2*ecc
scr_pitch = 2.0;
scr_clear = 0.40;    // radial clearance in the frame's threaded hole. 0.25
                     // bound on the first print: the hole prints on its side,
                     // its roof sags, and it comes out undersized.
scr_thin  = 0.15;    // extra radial undersize for the "screw_thin" variant
scr_len   = 10.0;    // threaded length
boss_d    = 12.0;
boss_h    = 5.0;     // boss height above the ring top -> engaged threads

sl_in_w = usb_w + 2*usb_fit;
sl_in_t = usb_t + 2*usb_fit;
sl_out_w = sl_in_w + 2*sl_wall;
sl_out_t = sl_in_t + 2*sl_wall;

ring_in_w  = cam_w + 2*cam_fit;
ring_in_r  = cam_r + cam_fit;
ring_out_w = ring_in_w + 2*ring_wall;
ring_out_r = ring_in_r + ring_wall;

// with lift = 0 the sleeve's top wall doubles as the ring's bottom wall
ring_bot = sl_out_t/2 - ring_wall + lift;          // ring's outer bottom edge
cam_cy  = ring_bot + ring_out_w/2;                 // camera centre height
ring_top = cam_cy + ring_out_w/2;

module rsq2d(w, r) offset(r) square(w - 2*r, center = true);

module thread(d, len, ecc, pitch) {
    linear_extrude(len, twist = -360*len/pitch, slices = ceil(24*len/pitch), convexity = 4)
        translate([ecc, 0]) circle(d = d - 2*ecc, $fn = 48);
}

// the web's top must stay on the flat part of the ring's bottom edge
web_top_w = min(sl_out_w, ring_out_w - 2*ring_out_r);

// Retention ribs along the plug axis on both wide faces of the sleeve. Each is
// a half-round bar tapered to nothing at the wall-side end, where the plug
// enters, so it lifts the plug body on rather than catching it.
module ribs() {
    rib_r = 0.6;
    for (sy = [-1, 1], x = [-usb_w/4, usb_w/4])
        hull() {   // the back half of each bar is buried in the sleeve wall
            translate([x, sy*(sl_in_t/2 + rib_r - rib_h), -sl_len + 2.5]) cylinder(r = rib_r, h = sl_len - 2.5, $fn = 24);
            translate([x, sy*(sl_in_t/2 + rib_r), -sl_len]) cylinder(r = rib_r, h = 0.01, $fn = 24);
        }
}

module frame() {
    ribs();
    difference() {
        union() {
            // ring around the camera
            translate([0, cam_cy, -ring_d]) linear_extrude(ring_d)
                rsq2d(ring_out_w, ring_out_r);
            // sleeve around the plug
            translate([-sl_out_w/2, -sl_out_t/2, -sl_len]) cube([sl_out_w, sl_out_t, sl_len]);
            // web lifting the ring off the sleeve: full sleeve length at the
            // bottom, ring depth at the top. The sloped back faces away from the
            // bed when printed, so it needs no support.
            hull() {
                translate([-sl_out_w/2, sl_out_t/2 - 1, -sl_len]) cube([sl_out_w, 1, sl_len]);
                translate([-web_top_w/2, ring_bot, -ring_d]) cube([web_top_w, ring_wall/2, ring_d]);   // half the wall: stays clear of the pocket face
            }
            // set-screw boss on top of the ring, trimmed to the ring's depth so
            // the front face stays flat on the bed
            intersection() {
                translate([0, ring_top - 1, -ring_d/2]) rotate([-90, 0, 0])
                    cylinder(d = boss_d, h = boss_h + 1);
                translate([-boss_d, 0, -ring_d]) cube([2*boss_d, 2*ring_top, ring_d]);
            }
        }
        // camera pocket, open at the back
        translate([0, cam_cy, -ring_d - 1]) linear_extrude(ring_d + 1 - bezel_t)
            rsq2d(ring_in_w, ring_in_r);
        // window in the front lip
        translate([0, cam_cy, -bezel_t - 1]) linear_extrude(bezel_t + 2)
            rsq2d(ring_in_w - 2*cam_fit - 2*bezel, max(1, cam_r - bezel));
        // plug hole, straight through
        translate([-sl_in_w/2, -sl_in_t/2, -sl_len - 1]) cube([sl_in_w, sl_in_t, sl_len + 2]);
        // threaded hole for the set screw. The odd 1.037 start offset keeps
        // the twist's slice planes off the ring and boss faces; when they
        // coincide the boolean leaves sliver faces and a non-manifold mesh.
        translate([0, ring_top - ring_wall - 1.037, -ring_d/2]) rotate([-90, 0, 0])
            thread(scr_d + 2*scr_clear, boss_h + ring_wall + 2, scr_ecc, scr_pitch);
        // lead-in chamfer at the top of the boss
        translate([0, ring_top + boss_h - 0.8, -ring_d/2]) rotate([-90, 0, 0])
            cylinder(d1 = scr_d + 2*scr_clear - 2*scr_ecc, d2 = scr_d + 2*scr_clear + 1.6, h = 0.81);
    }
}

module screw(under = 0) {
    thread(scr_d - 2*under, scr_len, scr_ecc, scr_pitch);
    translate([0, 0, scr_len]) cylinder(d = 11, h = 3, $fn = 8);   // knurled-ish head
}

/* ---------- ghosts for the assembly view ---------- */
module ghosts() {
    // wall wart: a box behind the plug
    // (top drawn just under the lifted ring, the clearance the first print lacked)
    color("white", 0.9) translate([-22, -20, -usb_len - 35]) cube([44, 20 + ring_bot - 1, 35]);
    // USB-A plug body and cable stub
    color("dimgray") translate([-usb_w/2, -usb_t/2, -usb_len]) cube([usb_w, usb_t, usb_len]);
    color("black") cylinder(d = 3.5, h = 10, $fn = 24);
    // camera, face just behind the front lip
    color("SkyBlue", 0.9) translate([0, cam_cy, -bezel_t - cam_d])
        linear_extrude(cam_d) rsq2d(cam_w, cam_r);
    color("black") translate([0, cam_cy, -bezel_t]) cylinder(d = 14, h = 0.3);
    // set screw in place
    // (on the hole's helix: advancing a along the axis means turning +360*a/pitch)
    color("gold") translate([0, ring_top - ring_wall - 1.037, -ring_d/2]) rotate([-90, 0, 0])
        translate([0, 0, 0.5]) rotate([0, 0, 360*0.5/scr_pitch]) screw();
}

if (part == "frame") {
    translate([0, 0, 0]) rotate([180, 0, 0]) frame();   // front face on the bed
} else if (part == "screw") {
    translate([0, 0, scr_len + 3]) rotate([180, 0, 0]) screw();   // head on the bed
} else if (part == "screw_thin") {
    translate([0, 0, scr_len + 3]) rotate([180, 0, 0]) screw(scr_thin);
} else if (part == "assembly") {
    rotate([90, 0, 0]) { color("orange") frame(); ghosts(); }   // Y-up -> viewer Z-up
}

echo(cam_r = cam_r, cam_cy = cam_cy);
