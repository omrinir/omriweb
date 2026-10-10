// =====================================================================
//  THANK-YOU ROBOT CUTE (v4)  -  big round head, short body, about 175 mm tall, ~150 g
//  OpenSCAD 2021.01+   (all dimensions in mm)
//
//  Export one part:  openscad -D 'part="head_front"' -o head_front.stl robot_cute.scad
//  Parts: base_floor, base_shell, body, head_front, head_back, face_plate, cheek (x2),
//         ear_ring, ear_cap, antenna_stem, antenna_ball, arm_right, arm_left, sign
//  Previews: assembly, exploded, cutaway
//
//  What changed from v2: 1.2 mm walls, 2-part base (wood shell + translucent
//  floor, the LED ring shines down through the floor onto the table),
//  smaller overall (about 155 mm tall), plus room for one 18650 battery.
//
//  Electronics inside:
//    base:  Arduino Nano, 18650 in a single-cell holder, USB-C charge + 5V boost
//           board, WS2812B 16-LED ring, VL53L0X, rocker switch, 1000uF cap, 330R
//    body:  3x SG90 (head + both arms)
//    head:  0.96" SSD1306 OLED
//    sign:  NTAG213 sticker
// =====================================================================

part = "assembly";

$fn    = 64;
sph_fn = 36;
eps    = 0.01;
fit    = 0.2;
wall   = 1.2;                 // 3 perimeters with a 0.4 mm nozzle

// ---------------- BASE ----------------------------------------------
base_r      = 50;
foot_h      = 3;              // printed feet: the ring light spills out under the base
floor_t     = 1.2;            // translucent
shell_h     = 32;
top_t       = 1.2;
shell_f     = 10;             // big round top edge
shell_fb    = 6;              // round bottom edge
base_z0     = foot_h;                       // shell bottom = floor bottom
floor_top   = base_z0 + floor_t;            // 4.2
base_h      = base_z0 + shell_h;            // 35
ceil_z      = base_h - top_t;               // 33.4
inner_r     = base_r - wall;
boss_r_pos  = 40;
boss_angles = [60, 120, 190, 345];
floor_r     = base_r - shell_fb - 0.5;   // floor fills the flat part of the bottom
ring16      = [44.5, 31.7, 3.4];
// battery: single 18650 holder (about 77 x 21 x 19) on two rails above the ring
bat         = [77, 21, 19];
bat_y       = 16;
bat_lift    = 6;
// Nano on two grooved end blocks, also lifted over the ring
nano        = [43.6, 18.4];
nano_y      = -25;
nano_lift   = 6;
// USB-C charge + 5V boost board (IP5306 / "18650 boost charger" type)
chg         = [25, 20];
chg_y       = 32.6;              // tucked under the battery holder edge
usb_port    = [9.8, 4.2];
// switch (KCD11 mini rocker) in the side wall
sw_a        = 90;    // back wall, above the USB-C port
sw_hole     = [19.2, 13];
// sensor + sign
sensor_y    = -34;
sensor_pcb  = [26, 11.5];
sign_tab_x  = 22;
sign_y      = -27.7;          // centre of the sign slot

// ---------------- BODY ----------------------------------------------
body_w      = 64;
body_d      = 48;
body_h      = 40;
body_r      = 14;
body_top_t  = 1.6;
body_f      = 5;
srv_plate_t = 5;              // local thick plate where the head servo screws in
body_tt     = body_h - srv_plate_t;         // 39 = top of the head servo tabs
body_pillars= [[23,19.5],[-23,19.5],[23,-19.5],[-23,-19.5]];
shoulder_z  = 24;                // arm servos lie flat: shaft height
pad_t       = 5.6;            // 4.4 pocket + 1.2 outer wall
arm_shaft_y = -5.5;            // arm pivot, a little forward of the body centre

// SG90
sv_l = 22.8; sv_w = 12.4; sv_up = 4.2; sv_tab_z = 18.5;
sv_shaft_off = 5.5; sv_screw_sp = 27.8; sv_boss_d = 12.4;

// ---------------- HEAD ----------------------------------------------
head_w      = 90;
head_d      = 64;
head_h      = 76;
head_r      = 26;             // soft "TV" corners seen from the front
head_f      = 6;
head_gap    = 1;
head_split  = 6;
oled_z      = 34;
visor       = [64, 44, 18];   // black face screen: w, h, corner r
visor_z     = 36;
cheek_d     = 9;
cheek_x     = 21;
cheek_z     = 25;
oled_win    = [23, 12];
oled_glass  = [27.2, 19.8, 1.4];
ear_z       = 38;

// ---------------- ARMS / SIGN ---------------------------------------
arm_t   = 10;
arm_gap = 1;
arm_S   = [arm_shaft_y, shoulder_z];
arm_H   = [-16, 9];
sign_w  = 70;
sign_h  = 38;
sign_t  = 3;                  // 3 mm laser-cut plywood

// =====================================================================
module rrect(w, d, r) offset(r) square([w-2*r, d-2*r], center=true);
module ring(ro, ri, h) difference() { cylinder(r=ro, h=h); translate([0,0,-eps]) cylinder(r=ri, h=h+2*eps); }
module rcyl(r, h, f) hull() { cylinder(r=r, h=h-f); translate([0,0,h-f]) rotate_extrude() translate([r-f,0]) circle(f); }
module pillow(r, h, ft, fb, o=0) hull() {      // cylinder with round top and bottom edges, shrunk by o
    translate([0,0,fb]) rotate_extrude() translate([r-fb,0]) circle(fb-o);
    translate([0,0,h-ft]) rotate_extrude() translate([r-ft,0]) circle(ft-o);
}
module arc2d(r, t, a0, a1)
    intersection() { difference() { circle(r+t/2); circle(r-t/2); }
                     polygon(concat([[0,0]], [for (a=[a0:5:a1]) 40*[cos(a), sin(a)]])); }
module at_wall(a, z) rotate(a) translate([inner_r-1, 0, z]) rotate([0,90,0]) children();

// =====================================================================
//  BASE
// =====================================================================
module base_floor() {    // translucent; LED ring glued on top, LEDs facing down
    difference() {
        union() {
            translate([0,0,base_z0]) cylinder(r=floor_r, h=floor_t);
            for (a=[45,135,225,315]) rotate(a) translate([34,0,0]) cylinder(d1=7, d2=9, h=foot_h+eps);   // feet
            // ring locator
            for (a=[210, 270, 330]) rotate(a) translate([ring16[0]/2+0.3, -3, floor_top-eps]) cube([1.4, 6, 1.5]);   // 3 tabs, the back stays free for the charger
            // battery rails
            for (s=[-1,1]) translate([s>0 ? 29 : -35, bat_y-bat[1]/2, floor_top-eps]) cube([6, bat[1]-3, bat_lift+eps]);
            // Nano end blocks with grooves
            for (s=[-1,1]) translate([s>0 ? nano[0]/2-2 : -nano[0]/2-2, nano_y-nano[1]/2-1.5, floor_top-eps]) difference() {
                cube([4, nano[1]+3, nano_lift+3]);
                translate([s>0 ? -1 : 2, 1.3, nano_lift]) cube([3, nano[1]+0.4, 1.8]);
            }
            // charger board guides
            for (x=[-chg[0]/2-1.2, chg[0]/2]) translate([x, chg_y-chg[1]/2, floor_top-eps]) cube([1.2, chg[1]-4, 2.5]);
        }
        for (a=boss_angles) rotate(a) translate([boss_r_pos,0,-1]) {
            cylinder(d=3.4, h=20);
            cylinder(d=6.6, h=1+foot_h+0.4);
        }
    }
}

module base_shell() {
    difference() {
        union() {
            difference() {
                translate([0,0,base_z0]) pillow(base_r, shell_h, shell_f, shell_fb);
                translate([0,0,base_z0]) pillow(base_r, shell_h, shell_f, shell_fb, wall);
                translate([0,0,base_z0-1]) cylinder(r=base_r-shell_fb-0.3, h=1+wall+0.3);      // bottom opening for the floor
            }
            for (a=boss_angles) rotate(a) translate([boss_r_pos,0,floor_top]) cylinder(d=7, h=ceil_z-floor_top+0.3);
            for (p=body_pillars) translate([p[0],p[1],ceil_z-2]) cylinder(d=7, h=2+0.3);           // screw pads
            for (x=[-sign_tab_x, sign_tab_x]) translate([x-6, sign_y-3.2, ceil_z-4]) cube([12, 6.4, 4+0.3]);   // sign sockets
            translate([-sensor_pcb[0]/2-1.2, sensor_y-sensor_pcb[1]/2-1.2, ceil_z-2]) cube([sensor_pcb[0]+2.4, sensor_pcb[1]+2.4, 2+0.3]);
        }
        for (a=boss_angles) rotate(a) translate([boss_r_pos,0,floor_top-eps]) cylinder(d=2.6, h=10);
        for (p=body_pillars) translate([p[0],p[1],ceil_z-3]) cylinder(d=3.4, h=10);
        translate([0,0,ceil_z-1]) cylinder(d=16, h=10);
        for (x=[-sign_tab_x, sign_tab_x]) translate([x-5.2, sign_y-(sign_t+0.4)/2, ceil_z-5]) cube([10.4, sign_t+0.4, 10]);
        translate([-5, sensor_y-3, ceil_z-3]) cube([10, 6, 10]);
        translate([-sensor_pcb[0]/2, sensor_y-sensor_pcb[1]/2, ceil_z-2-eps]) cube([sensor_pcb[0], sensor_pcb[1], 1.2]);
        // USB-C of the charger at the back, switch in the side wall
        at_wall(90, floor_top+1.6+1.6) linear_extrude(5) rrect(7.5, 13, 3.7);       // room for the plug body
        at_wall(sw_a, base_z0+16) linear_extrude(5) square([sw_hole[1], sw_hole[0]], center=true);
    }
}

// =====================================================================
//  BODY
// =====================================================================
module body_solid(w=body_w, d=body_d, h=body_h, r=body_r, f=body_f)
    hull() for (x=[-1,1], y=[-1,1]) translate([x*(w/2-r), y*(d/2-r), 0]) {
        cylinder(r=r, h=h-f);
        translate([0,0,h-f]) rotate_extrude() translate([r-f,0]) circle(f);
    }



module body() {
    difference() {
        union() {
            difference() {
                body_solid();
                translate([0,0,-eps]) linear_extrude(body_h-body_top_t+eps) rrect(body_w-2*wall, body_d-2*wall, body_r-wall);
            }
            intersection() {
                body_solid();
                union() {
                    for (p=body_pillars) translate([p[0], p[1], 0]) cylinder(d=5.6, h=body_h);
                    for (s=[-1,1]) translate([s>0 ? body_w/2-pad_t : -body_w/2, -19, shoulder_z-9]) cube([pad_t, 38, 18]);
                    translate([-9.5, -24, body_tt]) cube([19, 38, srv_plate_t]);         // head servo plate
                }
            }
        }
        translate([0, -sv_shaft_off, body_tt-eps]) linear_extrude(srv_plate_t+1) square([sv_w+0.6, sv_l+0.6], center=true);
        for (y=[-1,1]) translate([0, -sv_shaft_off + y*sv_screw_sp/2, body_tt-eps]) cylinder(d=1.8, h=4.5);
        for (s=[-1,1]) mirror([s<0 ? 1 : 0, 0, 0]) {
            x0 = body_w/2 - pad_t;
            ac = arm_shaft_y + sv_shaft_off;          // servo body centre (y)
            translate([x0-eps, ac-(sv_l+0.6)/2, shoulder_z-(sv_w+0.6)/2]) cube([sv_up+0.2, sv_l+0.6, sv_w+0.6]);
            translate([x0, 0, shoulder_z]) rotate([0,90,0]) linear_extrude(pad_t+1) hull() {
                translate([0, arm_shaft_y]) circle(d=sv_boss_d+0.6);
                translate([0, arm_shaft_y+7]) circle(d=6.5);
            }
            for (y=[-1,1]) translate([x0-eps, ac + y*sv_screw_sp/2, shoulder_z]) rotate([0,90,0]) cylinder(d=1.8, h=4.4);
        }
        translate([0, 16, body_tt-1]) cylinder(d=5.5, h=10);
        for (p=body_pillars) translate([p[0], p[1], -eps]) cylinder(d=2.6, h=8);
    }
}

// =====================================================================
//  HEAD
// =====================================================================
module head_profile() translate([0, head_h/2]) rrect(head_w, head_h, head_r);
module head_core(o=0)
    minkowski() {
        rotate([90,0,0]) linear_extrude(head_d-2*head_f, center=true) offset(delta=-head_f) head_profile();
        sphere(head_f-o, $fn=20);
    }
module visor_2d() translate([0, visor_z]) rrect(visor[0], visor[1], visor[2]);
module head_lip()
    intersection() {
        difference() { head_core(wall+fit); head_core(wall+fit+1.2); }
        translate([-100, head_split-eps, -1]) cube([200, 2+eps, 100]);
    }
module head_wire_slot() translate([0,0,-1]) linear_extrude(12) arc2d(16.5, 6, 55, 125);

pillars = [ [26, wall+3.5, 0, -1], [-26, wall+3.5, 0, -1], [18, head_h-wall-3.5, 0, 1], [-18, head_h-wall-3.5, 0, 1] ];

module head_all() {
    y0 = head_split - 12;
    difference() {
        union() {
            difference() { head_core(0); head_core(wall); }
            intersection() {
                head_core(0);
                union() {
                    linear_extrude(9) union() { circle(14.5); hull() for (x=[-13,13]) translate([x,0]) circle(6.5); }
                    for (p=pillars) hull() {
                        translate([p[0], y0, p[1]]) rotate([-90,0,0]) cylinder(d=7, h=head_d);
                        translate([p[0]+p[2]*2.5, y0-7, p[1]+p[3]*2.5]) rotate([-90,0,0]) cylinder(d=2, h=0.1);
                    }
                    intersection() {
                        translate([0,0,head_h-wall-7]) cylinder(r=8, h=7);
                        translate([-20,-20,0]) cube([40, 20+head_split-0.5, 100]);
                    }
                }
            }
        }
        translate([0, -head_d/2-1, 0]) rotate([-90,0,0]) mirror([0,1,0]) linear_extrude(wall+2) visor_2d();
        for (s=[-1,1]) translate([s*(head_w/2-wall-1), 0, ear_z]) rotate([0, s*90, 0]) cylinder(d=14.4, h=4);
        translate([0,0,-1]) cylinder(r=12.5, h=4);
        translate([0,0,-1]) linear_extrude(8.2) union() { circle(4.1); hull() for (x=[-16,16]) translate([x,0]) circle(3.2); }
        translate([0,0,-1]) cylinder(d=5, h=12);
        translate([0,0,head_h-wall-8]) cylinder(d=6.4, h=12);
        translate([0,0,head_h-3.5]) cylinder(d1=6.4, d2=13.4, h=3.5+eps);
        for (p=pillars) translate([p[0], 0, p[1]]) rotate([-90,0,0]) {
            translate([0,0,head_split-10]) cylinder(d=2.6, h=10+eps);
            translate([0,0,head_split]) cylinder(d=3.4, h=40);
            translate([0,0,head_split+6]) cylinder(d=6.2, h=40);
        }
    }
}
module head_front() difference() {
    union() { intersection() { head_all(); translate([-100,-100,-1]) cube([200, 100+head_split, 100]); } head_lip(); }
    head_wire_slot();
}
module head_back() difference() {
    intersection() { head_all(); translate([-100, head_split, -1]) cube([200, 100, 100]); }
    intersection() { difference() { head_core(wall-0.3); head_core(wall+fit+1.2+fit); }
                     translate([-100, head_split-eps, -1]) cube([200, 2.4, 100]); }
    head_wire_slot();
}
module face_plate() {
    y0 = -head_d/2;
    difference() {
        union() {
            translate([0, y0+0.05, 0]) rotate([-90,0,0]) mirror([0,1,0]) linear_extrude(wall-0.05) offset(delta=-0.2) visor_2d();
            translate([0, y0+wall, 0]) rotate([-90,0,0]) mirror([0,1,0]) linear_extrude(1.2) offset(delta=2.5) visor_2d();
        }
        translate([0, y0-1, oled_z]) rotate([-90,0,0]) linear_extrude(10) rrect(oled_win[0], oled_win[1], 1);
        translate([0, y0+wall+1.2-oled_glass[2], oled_z]) rotate([-90,0,0]) linear_extrude(5) square([oled_glass[0], oled_glass[1]], center=true);
        for (x=[-cheek_x, cheek_x]) translate([x, y0-1, cheek_z]) rotate([-90,0,0]) cylinder(d=cheek_d+0.3, h=1+0.8);   // cheek pockets
    }
}
module cheek() cylinder(d=cheek_d, h=1.2);     // print 2 in pink, press into the face plate
module ear_ring() difference() {
    union() { rotate_extrude() polygon([[7,0],[15,0],[15,4],[13.5,5.5],[7,5.5]]); translate([0,0,-2.5]) ring(7, 5.4, 2.5+eps); }
    translate([0,0,2]) cylinder(d=17, h=10);
    translate([0,0,-3]) cylinder(d=10.8, h=10);
}
module ear_cap() { cylinder(d=16.6, h=3.5); translate([0,0,3.5]) scale([1,1,0.3]) sphere(d=16.6, $fn=sph_fn); }
module antenna_stem() difference() {
    union() {
        translate([0,0,-7]) cylinder(d=6, h=7-3.5+eps);
        translate([0,0,-3.5]) cylinder(d1=6, d2=13, h=3.5);
        hull() { cylinder(d=13, h=1); cylinder(d=11, h=2); }
        cylinder(d=6, h=9);
    }
    translate([0,0,-8]) cylinder(d=3, h=30);            // LED wires
}
module antenna_ball() difference() {
    intersection() { translate([0,0,6.3]) sphere(r=8.5, $fn=sph_fn); translate([0,0,50]) cube(100, center=true); }
    translate([0,0,-eps]) cylinder(d=6.3, h=3.5);
    translate([0,0,3]) cylinder(d=5.4, h=7.5);          // pocket for a 5 mm addressable LED (PL9823 / WS2812D)
}

// =====================================================================
//  ARMS + SIGN
// =====================================================================
module arm_ball(p, r) translate([0, p[0], p[1]]) sphere(r, $fn=sph_fn);
module arm_shape() {
    dir = [arm_H[0]-arm_S[0], arm_H[1]-arm_S[1]] / norm([arm_H[0]-arm_S[0], arm_H[1]-arm_S[1]]);
    difference() {
        intersection() {
            translate([arm_t/2,0,0]) union() {
                hull() { arm_ball(arm_S, 9.5); arm_ball(arm_H, 7); }
                arm_ball(arm_H, 8.5);
            }
            translate([0, -100, -100]) cube([arm_t, 200, 200]);
        }
        translate([-1, arm_S[0], arm_S[1]]) rotate([0,90,0]) cylinder(r=8, h=1+2.5);
        translate([-1, arm_S[0], arm_S[1]]) rotate([0,90,0]) rotate([0,0,90]) linear_extrude(1+6.5)
            hull() { circle(4.1); translate([dir[0]*15, dir[1]*15]) circle(3.2); }
        translate([-1, arm_S[0], arm_S[1]]) rotate([0,90,0]) cylinder(d=5, h=arm_t+2);
    }
}
module sign_2d() {
    translate([-sign_w/2, 0]) offset(r=8) offset(delta=-8) square([sign_w, sign_h]);
    for (x=[-sign_tab_x, sign_tab_x]) translate([x-5, -5]) square([10, 5.5]);
}
module sign_flat() difference() {     // wooden sign: laser-cut the outline (part="sign_outline" -> DXF/SVG)
    linear_extrude(sign_t) sign_2d();
    translate([0, sign_h/2, sign_t-1.2]) cylinder(d=26, h=2);       // only used if you 3D print the sign
}

// =====================================================================
//  ASSEMBLY + ELECTRONICS DUMMIES
// =====================================================================
c_wood  = [0.83, 0.66, 0.45];
c_dark  = [0.25, 0.26, 0.28];
c_glow  = [0.35, 0.65, 1.0, 0.85];
c_black = [0.05, 0.05, 0.07];

module sg90_dummy() {
    color([0.15,0.35,0.85]) { translate([-sv_l/2,-sv_w/2,0]) cube([sv_l, sv_w, 22.7]);
        translate([-16.2,-sv_w/2,sv_tab_z-2.5]) cube([32.4, sv_w, 2.5]);
        translate([sv_shaft_off,0,22.7]) cylinder(d=11.8, h=4); }
    color("white") translate([sv_shaft_off,0,26.7]) cylinder(d=4.8, h=3.2);
}
module electronics_dummy() {
    translate([0,0,base_h]) {
        translate([0,0,body_tt - sv_tab_z]) rotate([0,0,90]) translate([-sv_shaft_off,0,0]) sg90_dummy();
        for (s=[-1,1]) mirror([s<0?1:0,0,0]) translate([body_w/2-pad_t-sv_tab_z, arm_shaft_y+sv_shaft_off, shoulder_z]) rotate([0,90,0]) rotate([0,0,-90]) sg90_dummy();
    }
    color([0.1,0.1,0.1]) translate([0,0,floor_top]) ring(ring16[0]/2, ring16[1]/2, ring16[2]);
    color([0.1,0.4,0.7]) translate([-nano[0]/2, nano_y-nano[1]/2, floor_top+nano_lift]) cube([nano[0], nano[1], 1.6]);
    color([0.2,0.7,0.3]) translate([-bat[0]/2, bat_y-bat[1]/2, floor_top+bat_lift]) {
        cube([bat[0], bat[1], 3]);
        translate([6, bat[1]/2, 3+9.3]) rotate([0,90,0]) cylinder(d=18.6, h=65);
    }
    color([0.85,0.2,0.2]) translate([-chg[0]/2, chg_y-chg[1]/2, floor_top]) cube([chg[0], chg[1], 1.6]);
    color([0.6,0.1,0.6]) translate([-sensor_pcb[0]/2+0.5, sensor_y-sensor_pcb[1]/2+0.5, ceil_z-2.8]) cube([sensor_pcb[0]-1, sensor_pcb[1]-1, 1.6]);
    color([0.9,0.1,0.1]) at_wall(sw_a, base_z0+16) translate([0,0,-15]) linear_extrude(16.5) square([sw_hole[1]-0.4, sw_hole[0]-0.4], center=true);
    color([0.1,0.3,0.6]) translate([0, -head_d/2+wall+1.2, base_h+body_h+head_gap+oled_z]) rotate([90,0,0]) translate([-13.6,-14,-1.6]) cube([27.2, 28, 1.6]);
}

module oled_eyes()
    translate([0, -head_d/2+wall+1.2, oled_z]) {
        color([0.02,0.02,0.03]) translate([0,-oled_glass[2],0]) rotate([-90,0,0]) linear_extrude(oled_glass[2]) square([oled_glass[0], oled_glass[1]], center=true);
        color([0.3,0.75,1]) for (x=[-5.5,5.5]) translate([x, -oled_glass[2]-0.1, -2]) rotate([90,0,0]) linear_extrude(0.2) arc2d(4, 1.6, 25, 155);
    }

module head_assembly(ex=0) {
    color(c_wood) head_front();
    color(c_wood) translate([0, ex, 0]) head_back();
    color(c_black) translate([0, -ex*0.6, 0]) face_plate();
    if (ex == 0) oled_eyes();
    for (s=[-1,1]) translate([s*(head_w/2 + ex*0.4), 0, ear_z]) rotate([0, s*90, 0]) { color(c_glow) ear_ring(); color(c_dark) translate([0,0,2]) ear_cap(); }
    translate([0,0,head_h + ex*0.5]) { color(c_dark) antenna_stem(); color(c_glow) translate([0,0,5.5 + ex*0.3]) antenna_ball(); }
}

module robot(ex=0) {
    color(c_glow) translate([0,0,-ex]) base_floor();
    color(c_wood) base_shell();
    translate([0,0,base_h + ex*0.6]) {
        color(c_dark) body();
        color(c_wood) translate([body_w/2+arm_gap + ex*0.4, 0, 0]) arm_shape();
        color(c_wood) mirror([1,0,0]) translate([body_w/2+arm_gap + ex*0.4, 0, 0]) arm_shape();
        color(c_wood) translate([0, sign_y-sign_t/2 - ex*0.8, 0]) rotate([90,0,0]) mirror([0,0,1]) sign_flat();
        translate([0,0,body_h + head_gap + ex*1.2]) head_assembly(ex);
    }
}

if      (part == "assembly")     robot();
else if (part == "exploded")     robot(40);
else if (part == "cutaway")      { intersection() { robot(); translate([-200,-200,-1]) cube([200,400,400]); } electronics_dummy(); }
else if (part == "base_floor")   base_floor();
else if (part == "base_shell")   translate([0,0,base_h]) rotate([180,0,0]) base_shell();
else if (part == "body")         translate([0,0,body_h]) rotate([180,0,0]) body();
else if (part == "head_front")   translate([0,0,head_d/2]) rotate([90,0,0]) head_front();
else if (part == "head_back")    translate([0,0,head_d/2]) rotate([-90,0,0]) head_back();
else if (part == "face_plate")   translate([0,0,-(head_d/2-wall-1.2)]) rotate([-90,0,0]) face_plate();
else if (part == "ear_ring")     translate([0,0,4]) rotate([180,0,0]) ear_ring();
else if (part == "ear_cap")      ear_cap();
else if (part == "antenna_stem") translate([0,0,7]) antenna_stem();
else if (part == "antenna_ball") antenna_ball();
else if (part == "arm_right")    translate([0,0,arm_t]) rotate([0,90,0]) arm_shape();
else if (part == "arm_left")     mirror([1,0,0]) translate([0,0,arm_t]) rotate([0,90,0]) arm_shape();
else if (part == "sign")         sign_flat();
else if (part == "sign_outline") sign_2d();     // export as .dxf or .svg for the laser cutter
else if (part == "cheek")        cheek();
