// ---------------------------------------------------------------------------
// Holder for a folding 4x6 dual-photo frame
//
// Three planar parts, all printed flat, no supports:
//   plate x2  - side profile; its top edge IS the cradle
//   brace x1  - vertical web, snaps between the plates and stays in
//
// Set `part` below (or -D part=... on the command line).
// ---------------------------------------------------------------------------

part = "assembly";   // "assembly" | "plate" | "brace" | "plate_test" | "snap_test"

IN = 25.4;
$fn = 64;

// --- the frame being held --------------------------------------------------
frame_w  = 6.75 * IN;    // 171.45  panel width  (landscape)
frame_h  = 4.75 * IN;    // 120.65  nominal panel height (fold to outer edge)
frame_t  = 0.60 * IN;    //  15.24  panel thickness (each panel, not folded)

// Per-panel lengths along the incline. The bottom panel is treated as 2 mm
// longer, so the fold sits 2 mm further from the front and everything above it
// rises with it.
frame_h_bot = frame_h + 2;
frame_h_top = frame_h;

// Which face the hinge runs along. "front" = the photo faces are contiguous at
// the fold and the frame closes photo-to-photo; the two BACK faces then splay
// apart, leaving a V-notch at the fold roughly frame_t deep. "back" = the back
// faces meet at a ridge.
//
// This matters more than it looks. With a front hinge the back-face planes
// still intersect, but at a virtual vertex `fold_d` beyond where the panel
// material actually stops - so the cradle and the backrest both have to be
// that much longer to reach real material.
hinge_face  = "front";
hinge_gap   = 0.125 * IN + 1;  // 4.175  measured 1/8" gap between the two panel
                           // edges at the fold, plus 1 mm. Assumed symmetric
                           // about the hinge axis, so each panel's material
                           // stops hinge_gap/2 early.
fold_relief = 0;           // any further slop to add at the vertex

// --- display posture -------------------------------------------------------
ang_bot  = 30;           // bottom panel, degrees from horizontal
ang_top  = 82;           // top panel, degrees from horizontal, leaning back

// --- placement -------------------------------------------------------------
front_x      = 14;       // x of the frame's front-bottom corner (back face)
front_lift   = 10;       // how far that corner sits above the table; also sets
                         // the material depth under the lip, which is the
                         // thinnest section in the plate
backrest_reach = 75;     // how far up the top panel's real material the backrest
                         // runs; the crown fillet trims ~5.7 mm off the end of
                         // the contact line, so effective reach is ~69 mm
plate_rear_x = 146;      // rear extent of the plate footprint
plate_gap    = 5.5 * IN; // plate centre-to-centre spacing

// --- plate -----------------------------------------------------------------
plate_th   = 5;
rim_w      = 12;         // rim left around the interior cutout
toe_h      = 12;         // height of the vertical front face
lip_proud  = 3;          // how far the front stop stands above the photo face
relief_r   = 6;          // hinge-knuckle relief at the fold vertex
notch_r    = 1.2;        // root relief in the lip notch

// --- brace -----------------------------------------------------------------
brace_th = 5;
brace_x  = plate_rear_x - 7;   // sits in the plate's rear rim - no strut needed
brace_z0 = 14;
brace_z1 = 74;
brace_rim = 14;          // rim left around the brace's own cutout

// --- snap joint (local: u out from plate inner face, v vertical) ------------
tongue_h    = 12;        // central locating tongue
tongue_len  = 6;
finger_gap  = 2;         // clear space between tongue level and finger
finger_h    = 2.2;       // cantilever thickness -> sets stiffness
finger_root = -9;        // root recessed INTO the body: buys free length
finger_tip  = 8;
barb_h      = 0.8;
barb_crest  = 5.2;       // just past the plate's outer face at u = plate_th
fit         = 0.15;      // per-side clearance in the plate holes

// --- test parts ------------------------------------------------------------
test_th    = 2;
test_rim_w = 10;

// Profile gauge: just the silhouette, a couple of layers thick. Solid rather
// than skeletal so it holds its shape while you lay it against the frame.
gauge_layer_h = 0.2;
gauge_layers  = 2;
gauge_th      = gauge_layer_h * gauge_layers;

// --- print layout, Bambu A1 mini (180 x 180) --------------------------------
// The two plates interlock: one rotated 180 deg drops into the other's empty
// upper-left region. Found by exhaustive search over 48 orientations with a
// 3 mm part gap; the brace does not fit alongside them in any arrangement, so
// it stays a separate job.
bed_size = 180;
lay_dx   = -11.00;       // offset of plate B's min corner from plate A's
lay_dy   =   2.00;       // gives 3.14 mm min clearance, 157.0 x 156.9 footprint
// MEASURED max y of plate_profile(). Change any frame or plate parameter and
// this goes stale - re-solve the nest rather than trusting it.
plate_prof_h = 154.941;

// ---------------------------------------------------------------------------
// derived geometry, side view: x = depth (back +), z = height
// ---------------------------------------------------------------------------
dir_bot = [cos(ang_bot), sin(ang_bot)];    // up the bottom panel, toward hinge
n_bot   = [-sin(ang_bot), cos(ang_bot)];   // out of the bottom panel's face
dir_top = [cos(ang_top), sin(ang_top)];    // up the top panel

// Shortfall between the virtual back-face vertex and where the panel material
// actually ends, for a front hinge. Applies at BOTH ends of the fold.
fold_angle = 180 - (ang_top - ang_bot);
// The gap does NOT move the virtual vertex - the back-face planes are fixed by
// the front-face planes plus the thickness. It only moves where the material
// stops, by half the gap on each panel.
fold_d = (hinge_face == "front" ? frame_t / tan(fold_angle / 2) : 0)
         + hinge_gap / 2 + fold_relief;

A  = [front_x, front_lift];                // bottom panel, front corner, back face
V  = A + (frame_h_bot + fold_d) * dir_bot; // where the back-face lines intersect
BT = V + (fold_d + backrest_reach) * dir_top;   // top of the backrest contact line
LT = A + (frame_t + lip_proud) * n_bot;    // tip of the front stop

brace_zc = (brace_z0 + brace_z1) / 2;
brace_hh = (brace_z1 - brace_z0) / 2;
plate_in = plate_gap / 2 - plate_th / 2;   // y of a plate's inner face

// hinge axis = intersection of the two panel mid-planes; used for the balance
// report only, nothing is dimensioned from it
hinge_s = let (p = A + (frame_t/2) * n_bot,
               q = V + (frame_t/2) * [-sin(ang_top), cos(ang_top)],
               d = q - p)
          (d[0]*dir_top[1] - d[1]*dir_top[0]) /
          (dir_bot[0]*dir_top[1] - dir_bot[1]*dir_top[0]);
hinge   = A + (frame_t/2) * n_bot + hinge_s * dir_bot;

// ---------------------------------------------------------------------------
// rounded polygon helper
// ---------------------------------------------------------------------------
function _u(v) = v / norm(v);

module rounded_polygon(pts, radii) {
    n = len(pts);
    polygon([ for (i = [0:n-1])
        let (p  = pts[i],
             v1 = _u(pts[(i+n-1) % n] - p),
             v2 = _u(pts[(i+1) % n] - p),
             r  = radii[i],
             th = acos(max(-1, min(1, v1 * v2))) / 2,
             d  = r / tan(th),
             c  = p + _u(v1 + v2) * (r / sin(th)),
             a1 = atan2((p + v1*d - c)[1], (p + v1*d - c)[0]),
             a2 = atan2((p + v2*d - c)[1], (p + v2*d - c)[0]),
             da = ((a2 - a1 + 540) % 360) - 180)
        each (r <= 0
              ? [p]
              : [for (j = [0:8]) c + r * [cos(a1 + da*j/8), sin(a1 + da*j/8)]])
    ]);
}

// ---------------------------------------------------------------------------
// plate profile
// ---------------------------------------------------------------------------
plate_pts = [
    [0, 0],                      // front toe on the table
    [0, toe_h],                  // vertical front face
    LT,                          // tip of the front stop
    A,                           // down the frame's front edge face
    V,                           // cradle: straight A -> V under the bottom panel
    BT,                          // backrest: straight V -> BT behind the top panel
    [plate_rear_x, BT[1] - 12],  // crown
    [plate_rear_x, 0],           // rear foot
];
plate_rad = [2, 2, 1.0, 0, 0, 2, 6, 2];

module plate_solid() {
    difference() {
        rounded_polygon(plate_pts, plate_rad);
        translate(V) circle(r = relief_r);   // hinge knuckle clearance
        translate(A) circle(r = notch_r);    // root relief in the lip notch
    }
}

// Three separate holes: the tongue locates, the fingers only latch. The finger
// holes are taller than the fingers by barb_h on the inner side, so the finger
// can flex clear of the barb while it crosses the plate (see fhole_* above).
module brace_holes() {
    translate([brace_x, brace_zc])
        square([brace_th + 2*fit, tongue_h + 2*fit], center = true);
    for (s = [1, -1])
        translate([brace_x, brace_zc + s * fhole_c])
            square([brace_th + 2*fit, fhole_h], center = true);
}

// Pad around the hole cluster. It merges into the rear rim, so the barbs bear
// on real material rather than on the edge of the lightening window.
module hole_pad() {
    translate([brace_x, brace_zc]) offset(r = 6) square([22, 38], center = true);
}

module plate_profile(rim = rim_w) {
    difference() {
        plate_solid();
        difference() {
            offset(r = 3) offset(r = -3) offset(r = -rim) plate_solid();
            hole_pad();
        }
        brace_holes();
    }
}

// Flat on the bed, ready to slice.
module plate_print(th = plate_th, rim = rim_w) {
    linear_extrude(th) plate_profile(rim);
    // A thinned test plate still has to latch: the barb catches on the plate's
    // OUTER face, so at 2 mm the crest would clear it by 3.2 mm and the joint
    // would be loose. Carry the hole cluster at full thickness. Prints flat.
    if (th < plate_th)
        linear_extrude(plate_th) difference() {
            intersection() { hole_pad(); plate_solid(); }
            brace_holes();
        }
}

// Positioned in the assembly.
module plate(th = plate_th, rim = rim_w) {
    rotate([90, 0, 0]) plate_print(th, rim);
}

// ---------------------------------------------------------------------------
// brace profile   (u = span, v = vertical, about the part centre)
// ---------------------------------------------------------------------------
finger_v0 = tongue_h/2 + finger_gap;   // inner edge of a finger
finger_v1 = finger_v0 + finger_h;      // outer edge

// Finger hole geometry. The hole must give the finger room to flex INWARD by
// barb_h as the barb crosses the plate - the finger_gap in the brace is useless
// here because at the plate crossing the finger is confined by THIS hole, not by
// the brace. Enlarging only the inner edge leaves the outer catch, and so the
// retention, unchanged.
fhole_in  = finger_v0 - barb_h - fit;  // inner edge, offset from brace centre
fhole_out = finger_v1 + fit;           // outer edge
fhole_c   = (fhole_in + fhole_out) / 2;
fhole_h   = fhole_out - fhole_in;      // = finger_h + barb_h + 2*fit

// Canonical tab: shoulder at u = 0, tab extends toward +u. The real brace and
// the linkage test both build from this, so their joints cannot drift apart.
module ctab_add() {
    ch = 1.5;                                        // lead-in chamfer
    polygon([
        [0, -tongue_h/2], [tongue_len - ch, -tongue_h/2],
        [tongue_len, -tongue_h/2 + ch], [tongue_len, tongue_h/2 - ch],
        [tongue_len - ch, tongue_h/2], [0, tongue_h/2],
    ]);
    for (s = [1, -1]) scale([1, s]) {
        translate([finger_root, finger_v0])
            square([finger_tip - finger_root, finger_h]);
        polygon([                                    // 16 deg lead-in, 90 deg catch
            [finger_tip, finger_v1],
            [barb_crest, finger_v1 + barb_h],
            [barb_crest, finger_v1],
        ]);
    }
}

// The two cuts that free each finger. They only need to run where the body is,
// i.e. inboard of the shoulder - running them the full tab length would slice
// the barbs off.
module ctab_cut() {
    for (s = [1, -1]) scale([1, s])
        for (v = [finger_v0 - finger_gap, finger_v1])
            translate([finger_root, v]) square([-finger_root, finger_gap]);
}

module tab_add() { translate([plate_in, 0]) ctab_add(); }
module tab_cut() { translate([plate_in, 0]) ctab_cut(); }

// one end of the brace, solid-backed - used for the snap test coupon
module brace_end(depth = 24) {
    difference() {
        union() {
            translate([plate_in - depth, -brace_hh]) square([depth, 2 * brace_hh]);
            tab_add();
        }
        tab_cut();
    }
}

module brace_profile() {
    difference() {
        union() {
            difference() {
                square([2 * plate_in, 2 * brace_hh], center = true);
                offset(r = 8) offset(r = -8)
                    square([2 * plate_in - 2*brace_rim, 2 * brace_hh - 2*brace_rim],
                           center = true);
            }
            for (s = [1, -1]) scale([s, 1]) tab_add();
        }
        for (s = [1, -1]) scale([s, 1]) tab_cut();
    }
}

module brace_print() {
    linear_extrude(brace_th) brace_profile();
}

module brace() {
    translate([brace_x - brace_th/2, 0, brace_zc])
        rotate([90, 0, 90]) brace_print();
}

// ---------------------------------------------------------------------------
// the frame itself, for visual checking only
// ---------------------------------------------------------------------------
module frame_ghost() {
    color("SteelBlue", 0.35) {
        translate([A[0], -frame_w/2, A[1]])
            rotate([0, -ang_bot, 0]) cube([frame_h_bot, frame_w, frame_t]);
        // the top panel's back face starts fold_d ABOVE the virtual vertex
        let (TP = V + fold_d * dir_top)
            translate([TP[0], -frame_w/2, TP[1]])
                rotate([0, -ang_top, 0]) cube([frame_h_top, frame_w, frame_t]);
    }
}

// ---------------------------------------------------------------------------
module plate_pair(th = plate_th, rim = rim_w) {
    for (s = [0, 1]) mirror([0, s, 0])
        translate([0, plate_gap/2 + plate_th/2, 0]) plate(th, rim);
}

// Two copies of whatever plate variant you hand it, nested on one bed. The
// outline is identical across the production, test and gauge variants, so one
// solved nest serves all three.
module nest_pair() {
    translate([-min(0, lay_dx), -min(0, lay_dy), 0]) {
        children();
        translate([lay_dx + plate_rear_x, lay_dy + plate_prof_h, 0])
            rotate([0, 0, 180]) children();
    }
}

// Both coupons laid flat on the bed, ready to slice.
module snap_test() {
    // plate coupon: FULL thickness - the barb catches on the outer face, so
    // this one cannot be thinned
    linear_extrude(plate_th)
        translate([-brace_x, -brace_zc])
            difference() {
                translate([brace_x - 22, brace_zc - 22]) square([44, 44]);
                brace_holes();
            }
    // brace end stub carrying one complete tab
    translate([0, 22 + brace_hh + 6, 0]) linear_extrude(brace_th)
        translate([-plate_in - finger_tip, 0]) brace_end();
}

// --- linkage test: the whole snap joint, both ends, in a compact print -------
link_span = 50;          // inner-face to inner-face on the short test brace;
                         // the joint is identical to the real one, only the web
                         // between the two tabs is shortened

// A short brace: full-height web plus a complete tab at each end.
module link_brace_2d() {
    half = link_span / 2;
    difference() {
        union() {
            difference() {
                square([link_span, 2 * brace_hh], center = true);
                offset(r = 8) offset(r = -8)
                    square([link_span - 2*brace_rim, 2*brace_hh - 2*brace_rim],
                           center = true);
            }
            translate([ half, 0]) ctab_add();
            translate([-half, 0]) mirror([1, 0]) ctab_add();
        }
        translate([ half, 0]) ctab_cut();
        translate([-half, 0]) mirror([1, 0]) ctab_cut();
    }
}

// A plate coupon: full thickness, the three-hole cluster centred, so the barb
// catches on its far face exactly as it does on a real plate.
module link_coupon_2d() {
    difference() {
        square([32, tongue_h + 2*finger_gap + 2*finger_h + 16], center = true);
        square([brace_th + 2*fit, tongue_h + 2*fit], center = true);
        for (s = [1, -1])
            translate([0, s * fhole_c])
                square([brace_th + 2*fit, fhole_h], center = true);
    }
}

// Brace between the two coupons, all flat on the bed. Snap the brace into one
// coupon, then bring the second coupon onto the free end - the real assembly
// sequence in miniature.
module link_test() {
    linear_extrude(brace_th) link_brace_2d();
    for (s = [1, -1])
        translate([s * (link_span/2 + tongue_len + 20 + 6), 0, 0])
            linear_extrude(plate_th) link_coupon_2d();
}

// ---------------------------------------------------------------------------
echo(str("hinge on the ", hinge_face, " face -> fold_d = ", fold_d, " mm"));
echo(str("cradle length, lip to vertex = ", frame_h_bot + fold_d, " mm"));
echo(str("top panel CG behind hinge axis = ", (frame_h_top/2) * cos(ang_top), " mm"));
echo(str("material under the lip (thinnest section) = ", front_lift, " mm"));
echo(str("brace part length = ", 2 * (plate_in + finger_tip),
         " mm,  overall width = ", plate_gap + plate_th, " mm"));

if (part == "assembly") {
    plate_pair();
    brace();
    frame_ghost();
} else if (part == "plate") {
    plate_print();
} else if (part == "brace") {
    brace_print();
} else if (part == "plate_test") {
    plate_print(test_th, test_rim_w);
} else if (part == "snap_test") {
    snap_test();
} else if (part == "link_test") {
    link_test();
} else if (part == "profile_test") {
    linear_extrude(gauge_th) plate_solid();
} else if (part == "job_plates") {
    nest_pair() plate_print();
} else if (part == "job_test_plates") {
    nest_pair() plate_print(test_th, test_rim_w);
} else if (part == "job_gauges") {
    nest_pair() linear_extrude(gauge_th) plate_solid();
} else if (part == "job_brace") {
    brace_print();
}
