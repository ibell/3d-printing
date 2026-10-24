// 5/8" transfer punch for a shallow hole: a short body that drops into the
// hole, a lip that stops on the surface around it, and a point on the axis
// that marks the mating part pressed down onto it.
//
// Axes: Z is the punch axis. z = 0 is the bottom of the body.
//
// Prints body down, as exported, no supports. The lip's underside is a short
// flat overhang (lip_over per side), which prints fine on its perimeters.

$fn = 128;
in = 25.4;

/* ---------- hole ---------- */
hole_d    = 5/8 * in;   // 15.875
fit       = 0.10;       // per-side clearance on the body. Raise it if the
                        // punch won't go in; lower it if it rattles.
hole_dep  = 3/16 * in;  // 4.76, body length under the lip

/* ---------- body ---------- */
body_d    = hole_d - 2*fit;
lead_in   = 0.6;        // 45° chamfer on the bottom edge: eases entry and
                        // hides elephant's foot

/* ---------- lip ---------- */
lip_over  = 1.5;        // how far the lip stands out past the body, per side
lip_t     = 2.0;
lip_d     = hole_d + 2*lip_over;
lip_ch    = 0.5;        // chamfer on the lip's top edge

/* ---------- point ---------- */
pin_d     = 3.0;        // shank of the point
pin_h     = 2.0;        // straight shank above the lip
tip_ang   = 60;         // included angle of the point
tip_flat  = 0.3;        // tip is truncated to this diameter so it prints
tip_h     = (pin_d - tip_flat)/2 / tan(tip_ang/2);

module punch() {
    // body
    cylinder(d1 = body_d - 2*lead_in, d2 = body_d, h = lead_in);
    translate([0, 0, lead_in]) cylinder(d = body_d, h = hole_dep - lead_in);
    // lip
    translate([0, 0, hole_dep]) {
        cylinder(d = lip_d, h = lip_t - lip_ch);
        translate([0, 0, lip_t - lip_ch])
            cylinder(d1 = lip_d, d2 = lip_d - 2*lip_ch, h = lip_ch);
    }
    // point
    translate([0, 0, hole_dep + lip_t]) {
        cylinder(d = pin_d, h = pin_h);
        translate([0, 0, pin_h]) cylinder(d1 = pin_d, d2 = tip_flat, h = tip_h);
    }
}

punch();
