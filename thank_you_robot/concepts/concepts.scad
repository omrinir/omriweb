// =====================================================================
//  4 DESIGN CONCEPTS for the Thank-You robot - outer shapes only.
//  All four keep the same inside layout as v4: base 100 mm wide with the
//  18650 + charger + Nano + LED ring + sensor, body >= 64 x 48 x 40 mm for the
//  3 servos (arm pivots at x = +-32, z = 59), head with room for the OLED and
//  the servo horn, the wooden sign in front of the body.
//  openscad -D 'design=1' -D 'role="light"' -o d1_light.stl concepts.scad
//  designs: 1 Pebble, 2 Kitty, 3 Retro, 4 Astro
//  roles:   light, accent, dark, glow, pink, metal
// =====================================================================
design = 1;
role   = "light";
$fn = 72;

module rrect(w, d, r) offset(r) square([w-2*r, d-2*r], center=true);
module rbox(s, r) hull() for (x=[-1,1], y=[-1,1], z=[-1,1])
    translate([x*(s[0]/2-r), y*(s[1]/2-r), s[2]/2 + z*(s[2]/2-r)]) sphere(r, $fn=40);
module pillow(r, h, ft, fb) hull() {
    translate([0,0,fb]) rotate_extrude() translate([r-fb,0]) circle(fb);
    translate([0,0,h-ft]) rotate_extrude() translate([r-ft,0]) circle(ft);
}
module ell(c, rr) translate(c) scale(rr) sphere(1, $fn=96);
module yprism(w, h, r, z, y0=-80, y1=0) translate([0, y1, z]) rotate([90,0,0]) linear_extrude(y1-y0) rrect(w, h, r);
module ycyl(d, x, z, y0=-80, y1=0) translate([x, y1, z]) rotate([90,0,0]) cylinder(d=d, h=y1-y0);
module capsule(a, b, r) hull() { translate(a) sphere(r, $fn=36); translate(b) sphere(r, $fn=36); }
module floor_glow() translate([0,0,3]) cylinder(r=43.5, h=1.2);
module feet() for (a=[45,135,225,315]) rotate(a) translate([34,0,0]) cylinder(d1=7, d2=9, h=3);
module mitten_arms(hand_r=8.5) for (s=[-1,1]) {
    capsule([s*38, -5.5, 59], [s*39, -16, 44], 7);
    translate([s*39, -16, 44]) sphere(hand_r, $fn=40);
    translate([s*36, -5.5, 59]) rotate([0,90,0]) cylinder(r=9.5, h=8, center=true);
}
HZ = 76;     // head bottom

// ---------------------------------------------------------------- 1 PEBBLE
module pebble(r) {
    hc = [0, 0, HZ+40]; hr = [47, 40, 42];
    if (r == "light") {
        translate([0,0,3]) pillow(50, 32, 13, 6);
        intersection() { ell(hc, hr); translate([-60,-60,HZ]) cube([120,120,100]); }
        mitten_arms();
    }
    if (r == "accent") {
        intersection() { ell([0,0,56], [34, 26, 27]); translate([-60,-60,35]) cube([120,120,40]); }   // pear body
        translate([0,0,HZ+82]) cylinder(d=6, h=9);
        for (s=[-1,1]) translate([s*46, 0, HZ+40]) rotate([0, s*90, 0]) cylinder(r=8, h=6);
    }
    if (r == "dark") intersection() { ell(hc, hr*1.012); yprism(66, 46, 21, HZ+42, -80, -18); }
    if (r == "pink") for (s=[-1,1]) intersection() { ell(hc, hr*1.02); ycyl(10, s*22, HZ+30, -80, -20); }
    if (r == "glow") {
        floor_glow(); feet();
        translate([0,0,HZ+97]) sphere(7.5, $fn=48);
        for (s=[-1,1]) translate([s*47, 0, HZ+40]) rotate([0, s*90, 0]) difference() { cylinder(r=12, h=4); translate([0,0,-1]) cylinder(r=8.2, h=6); }
    }
}

// ---------------------------------------------------------------- 2 KITTY
module kitty(r) {
    hs = [92, 72, 72]; hr = 30;
    module ear(s, k=1) hull() {
        translate([s*27, 0, HZ+64]) scale([1,0.55,1]) sphere(15*k, $fn=40);
        translate([s*31, 0, HZ+92-(1-k)*14]) sphere(3.5*k, $fn=24);
    }
    if (r == "light") {
        translate([0,0,3]) pillow(48, 26, 10, 6);
        translate([0,0,HZ]) rbox(hs, hr);
        for (s=[-1,1]) ear(s);
        for (s=[-1,1]) translate([s*39, -16, 44]) sphere(9, $fn=40);     // paws
    }
    if (r == "accent") {
        translate([0,0,30]) rotate_extrude() translate([44,0]) circle(8);           // cushion rim of the cat bed
        translate([0,0,35]) rbox([66, 50, 41], 16);                                   // body
        for (s=[-1,1]) capsule([s*37, -5.5, 59], [s*39, -16, 46], 7);              // arms
        translate([0, 27, 48]) rotate([0,90,0]) rotate_extrude(angle=220) translate([13,0]) circle(4);   // tail
    }
    if (r == "dark") translate([0,0,HZ]) yprism(66, 44, 20, 36, -37.2, -35);
    if (r == "pink") {
        for (s=[-1,1]) translate([s*20, -37.3, HZ+24]) rotate([90,0,0]) cylinder(d=9, h=0.6);
        translate([0, -37.3, HZ+27]) rotate([90,0,0]) scale([1,0.7,1]) cylinder(d=6, h=0.8);   // nose
    }
    if (r == "glow") { floor_glow(); feet(); for (s=[-1,1]) translate([0,-4,0]) ear(s, 0.62); }
}
// whiskers drawn as thin bars
module whiskers() for (s=[-1,1], k=[-1,0,1])
    translate([s*27, -37.4, HZ+25+k*4]) rotate([0, s*k*10, 0]) cube([12, 0.6, 1], center=true);

// ---------------------------------------------------------------- 3 RETRO
module retro(r) {
    if (r == "light") {
        translate([0,0,HZ]) rbox([90, 70, 76], 7);
        for (s=[-1,1]) capsule([s*37, -5.5, 59], [s*38, -14, 45], 6.5);
    }
    if (r == "accent") {
        translate([0,0,3]) cylinder(r1=50, r2=44, h=32);
        translate([0,0,35]) rbox([66, 50, 41], 5);
        translate([0, -35.6, HZ+38]) rotate([90,0,0]) difference() { linear_extrude(1.6) rrect(74, 52, 9); translate([0,0,-1]) linear_extrude(4) rrect(64, 42, 6); }
        for (s=[-1,1]) translate([s*24, 0, HZ+76]) cylinder(d=4, h=14);
        for (s=[-1,1]) translate([s*39, -14, 45]) sphere(8.5, $fn=40);
    }
    if (r == "metal") {
        for (z=[10, 18, 26]) translate([0,0,z]) cylinder(r=50 - (z-3)*6/32 + 0.8, h=1.8);       // ribs
        for (x=[-33, 33], z=[HZ+16, HZ+60]) translate([x, -36.4, z]) sphere(1.8, $fn=20);         // rivets
        for (s=[-1,1]) translate([s*45, 0, HZ+38]) rotate([0, s*90, 0]) cylinder(r=7, h=4);
        for (s=[-1,1]) translate([s*33, -5.5, 59]) rotate([0,90,0]) cylinder(r=8, h=6, center=true);
    }
    if (r == "dark") translate([0,0,HZ]) yprism(64, 42, 6, 38, -35.6, -34.5);
    if (r == "glow") {
        floor_glow(); feet();
        for (s=[-1,1]) translate([s*24, 0, HZ+94]) sphere(5.5, $fn=40);
        for (s=[-1,1]) translate([s*45, 0, HZ+38]) rotate([0, s*90, 0]) difference() { cylinder(r=11, h=3); translate([0,0,-1]) cylinder(r=7.2, h=5); }
    }
}

// ---------------------------------------------------------------- 4 ASTRO
module astro(r) {
    hc = [0, 0, HZ+45]; R = 47;
    if (r == "light") {
        intersection() { translate(hc) sphere(R, $fn=110); translate([-60,-60,HZ]) cube([120,120,110]); }
        translate([0,0,35]) rbox([66, 50, 41], 16);
        for (s=[-1,1]) capsule([s*37, -5.5, 59], [s*39, -16, 46], 7);
    }
    if (r == "metal") difference() {          // moon base with craters
        translate([0,0,3]) pillow(50, 32, 12, 6);
        for (p=[[20,30,38], [-28,24,37], [36,-8,30], [-40,-18,24], [8,40,24], [-14,-44,26]]) translate(p) sphere(6, $fn=32);
    }
    if (r == "accent") {
        translate([0, -sqrt(R*R-31*31)+0.5, HZ+45]) rotate([90,0,0]) rotate_extrude() translate([31,0]) circle(3.6, $fn=24);   // visor ring
        translate([0, 29, 38]) rbox([42, 16, 32], 6);          // backpack
        for (s=[-1,1]) translate([s*39, -16, 46]) sphere(8.5, $fn=40);   // gloves
        translate([0,0,HZ+90]) cylinder(d=5, h=10);
    }
    if (r == "dark") intersection() { translate(hc) sphere(R*1.01, $fn=110); ycyl(62, 0, HZ+45, -80, -20); }
    if (r == "pink") for (s=[-1,1]) intersection() { translate(hc) sphere(R*1.02, $fn=110); ycyl(9, s*18, HZ+34, -80, -30); }
    if (r == "glow") {
        floor_glow(); feet();
        translate([0,0,HZ+104]) sphere(6.5, $fn=40);
        for (s=[-1,1]) translate([s*R-s*1.5, 0, HZ+45]) rotate([0, s*90, 0]) cylinder(r=8, h=4);
    }
}

if (design == 1) pebble(role);
if (design == 2) { kitty(role); if (role == "metal") whiskers(); }
if (design == 3) retro(role);
if (design == 4) astro(role);
