// Three-sided bell ornament with a recessed photo panel on each side.
//
// The cross-section is a rounded equilateral triangle whose size follows a bell
// profile r(z) (r = inradius: axis to the middle of a face). Each face is flat
// side to side and curves only top to bottom, so a paper photo bends onto it
// cleanly. A shallow bell-shaped pocket on each face takes the photo.
//
// Axes: Z is the bell axis, z = 0 is the mouth. Face centres point along +X,
// rotated by 120° for the other two.
//
// Prints mouth down, as exported, no supports: r(z) only shrinks going up, so the
// outside never overhangs, and the inside is a rounded-triangle cavity that
// never narrows faster than 45°.
//
// part = "bell"     the ornament (default)
// part = "template" 2D outline of one photo, unrolled to its true length on the
//                   curved face, for export as SVG / DXF and printing at 100%.

part = "bell";

/* ---------- bell profile ---------- */
H        = 70;     // body height, mouth to top of the dome
r_lip    = 20;     // inradius at the mouth
r_waist  = 16;     // inradius the flare settles to
waist_taper = 0.04;// how much the waist narrows per mm going up
flare_k  = 8;      // flare length: bigger = longer, softer flare
dome_z   = 50;     // the dome (rounded crown) starts here
corner   = 5;      // corner rounding of the triangle

/* ---------- walls ---------- */
wall     = 1.6;    // minimum wall under the pockets
lip_band = 5;      // plain band above the mouth, below the photos

/* ---------- photo pockets ---------- */
pocket_d     = 0.8;  // depth: photo paper (~0.25) plus glue, with paint
pocket_edge  = 2.2;  // frame left between pocket and the corners
pocket_top   = 57;   // top of the pocket's arch
arch_h       = 15;   // height of the rounded arch at the top of the pocket
template_fit = 0.3;  // template is this much smaller per side than the pocket

/* ---------- hanger ---------- */
tab_t    = 3.2;
tab_w    = 11;
tab_h    = 10;     // height above the dome top
hole_d   = 4.5;    // takes ribbon or an ornament hook

/* ---------- resolution ---------- */
N        = 90;     // slices along Z
$fn      = 64;

// ---------------------------------------------------------------------------

function r_body(z) = r_waist - waist_taper*z + (r_lip - r_waist)*exp(-z/flare_k);
function r(z) = z <= dome_z ? r_body(z)
              : r_body(z) * sqrt(max(0, 1 - pow((z - dome_z)/(H - dome_z), 2)));

function zs(i) = H * i / N;

function cr(z) = min(corner, 0.85*r(z));   // corner radius, shrinks into the dome

// rounded equilateral triangle with inradius ri, one face normal along +X
module tri2d(ri, c) {
    k = ri - c;    // inradius of the sharp triangle before rounding
    if (k > 0.01)
        offset(r = c) polygon([for (a = [0, 120, 240]) 2*k*[cos(a+180), sin(a+180)]]);
    else
        circle(r = max(ri, 0.01));
}

module slice(z) {
    translate([0, 0, z]) linear_extrude(0.01) tri2d(r(z), cr(z));
}

module outer() {
    for (i = [0 : N-1]) hull() { slice(zs(i)); slice(zs(i+1)); }
}

// --- cavity: a rounded triangle parallel to the outside, at least pocket_d + wall
// in from every face. Its corners recede twice as fast as its faces, so it may
// narrow at most 0.5 mm per mm going up (45° at the corners). Built from the top
// down: ci(z) = min(g(z), ci(z+dz) + dz/2).
function g(z) = r(z) - pocket_d - wall;
function ci_list(i, above) =
    i < 0 ? [] :
    let(c = min(g(zs(i)), above + 0.5*H/N))
    concat(ci_list(i-1, c), [c]);
CI = ci_list(N, -1);
function cc(ci) = min(corner, 0.85*ci);

module cavity_slice(i, z) {
    translate([0, 0, z]) linear_extrude(0.01) tri2d(max(CI[i], 0.02), cc(max(CI[i], 0.02)));
}

module cavity() {
    for (i = [0 : N-1]) if (CI[i] > 0.3)
        hull() { cavity_slice(i, zs(i) - (i == 0 ? 1 : 0)); cavity_slice(i+1, zs(i+1)); }
}

// --- pocket half-width at height z: flat-face width minus the edge, closed by an arch
function face_hw(z) = sqrt(3) * (r(z) - cr(z)) - pocket_edge;
arch_z0 = pocket_top - arch_h;
function arch_hw(z) = z <= arch_z0 ? 1e3
                    : z >= pocket_top ? 0
                    : face_hw(arch_z0) * sqrt(1 - pow((z - arch_z0)/arch_h, 2));
function pocket_hw(z) = (z < lip_band || z > pocket_top) ? 0 : max(0, min(face_hw(z), arch_hw(z)));

PN = 80;
function pz(i) = lip_band + (pocket_top - lip_band) * i / PN;

module pocket_slab(z) {
    w = pocket_hw(z);
    if (w > 0.05)
        translate([r(z) - pocket_d, -w, z]) cube([pocket_d + 3, 2*w, 0.01]);
}

module pockets() {
    for (a = [0, 120, 240]) rotate(a)
        for (i = [0 : PN-1]) hull() { pocket_slab(pz(i)); pocket_slab(pz(i+1)); }
}

module hanger() {
    // a flat tab rising out of the dome; teardrop hole (point up) prints without support
    hc = H + tab_h - tab_w/2;
    rotate([90, 0, 90]) translate([0, 0, -tab_t/2]) linear_extrude(tab_t)
        difference() {
            hull() {
                translate([-tab_w/2, H - 6]) square([tab_w, 0.01]);
                translate([0, hc]) circle(d = tab_w);
            }
            translate([0, hc]) {
                circle(d = hole_d);
                rotate(45) square(hole_d/2);
            }
        }
}

module bell() {
    difference() {
        union() { outer(); hanger(); }
        cavity();
        pockets();
    }
}

// --- template: (half-width, arc length along the face) unrolled
function seg(i) = let(z0 = pz(i), z1 = pz(i+1)) norm([r(z1) - r(z0), z1 - z0]);
function s_list(i, acc) = i > PN ? [] : concat([acc], s_list(i+1, acc + (i < PN ? seg(i) : 0)));
S = s_list(0, 0);

module template() {
    offset(delta = -template_fit) polygon(concat(
        [for (i = [0 : PN]) [ pocket_hw(pz(i)), S[i]]],
        [for (i = [PN : -1 : 0]) [-pocket_hw(pz(i)), S[i]]]));
}

if (part == "bell") bell();
else if (part == "template") template();
