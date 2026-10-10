// =====================================================================
//  THANK-YOU ROBOT  -  3D-printable enclosure for the NFC review robot
//  OpenSCAD 2021.01+   (all dimensions in mm)
//
//  Preview the whole robot:   open this file in OpenSCAD (part="assembly")
//  Export one part:           openscad -D 'part="head_front"' -o head_front.stl robot.scad
//  Parts: base_floor, base_band, base_deck, base_shell, body, head_front,
//         head_back, face_plate, ear_ring, ear_cap, antenna_stem,
//         antenna_ball, arm_right, arm_left, sign
//  Previews: assembly, exploded, cutaway (half section with the electronics shown)
//  Every printable part is exported already rotated to its print orientation.
//
//  Electronics it is laid out for:
//    Arduino Nano V3 (on the deck in the base, USB reachable from the back)
//    3x SG90  - 1 turns the head, 1 per arm (arms bolt straight onto the horns)
//    WS2812B 16-LED ring (under the deck, shining down onto a cone reflector,
//                         light leaves through the translucent band)
//    VL53L0X  (under a window in the base top, in front of the sign)
//    NTAG213  (pocket on the back of the sign)
//    0.96" SSD1306 OLED 128x64 I2C (behind the face plate)
//    5V USB power input (USB-C breakout), KCD11 mini rocker switch,
//    1000uF capacitor cradle, Dupont wiring
// =====================================================================

part = "assembly";

$fn    = 64;
sph_fn = 40;
eps    = 0.01;
fit    = 0.2;                 // general sliding clearance

// ---------------- BASE ----------------------------------------------
base_r       = 60;            // 120 mm diameter
floor_t      = 3;
band_h       = 12;            // translucent glow band = light chamber height
band_t       = 1.8;
shell_h      = 34;
shell_wall   = 2.4;
shell_top_t  = 3;
shell_fillet = 5;
shell_z0     = floor_t + band_h;               // 15  (deck sits here)
base_h       = shell_z0 + shell_h;             // 49
ceil_z       = base_h - shell_top_t;           // 46  (underside of the base top)
lip_t        = 1.4;
lip_h        = 2;
band_ri      = base_r - band_t;
lip_ro       = band_ri - fit;
lip_ri       = lip_ro - lip_t;
deck_t       = 2.5;
deck_r       = base_r - shell_wall - 0.3;
deck_top     = shell_z0 + deck_t;              // 17.5
boss_pos_r   = 46;
boss_angles  = [20, 160, 235, 305];
ring16       = [44.5, 31.7, 3.4];              // WS2812B 16 ring: OD, ID, thickness incl. LEDs
nano         = [18.4, 43.6];                   // Nano PCB
nano_lift    = 2.5;                            // PCB underside above the deck
nano_hw      = nano[0]/2;
sensor_y     = -50;                            // VL53L0X window
sensor_pcb   = [26, 11.5];                     // GY-530 / GY-VL53L0XV2 board pocket
sign_y       = -41;                            // centre of the sign slot
sign_tab_x   = 12;
// openings in the back wall (angle around the base, 90 = straight back)
nano_usb_a   = 90;   nano_usb_hole = [12, 9];
pwr_a        = 130;  pwr_hole      = [9.8, 4.2];   // USB-C 5V breakout
sw_a         = 50;   sw_hole       = [19.2, 13];   // KCD11 mini rocker

// ---------------- BODY ----------------------------------------------
body_w      = 70;
body_d      = 56;
body_h      = 46;
body_r      = 16;
body_wall   = 2.4;
body_top_t  = 6;               // head servo tabs screw to the underside of this plate
body_fillet = 6;
body_tt     = body_h - body_top_t;              // 40
body_pillars= [[26,20],[-26,20],[26,-20],[-26,-20]];
shoulder_z  = 28;              // arm servo shaft height (body coords)
pad_t       = 7;               // side wall thickness where the arm servos mount

// SG90 micro servo
sv_l        = 22.8;            // length
sv_w        = 12.4;            // width
sv_up       = 4.2;             // body height above the tabs
sv_tab_z    = 18.5;            // bottom of servo -> top of tabs
sv_shaft_off= 5.5;             // shaft distance from servo body centre (along length)
sv_screw_sp = 27.8;
sv_boss_d   = 12.4;

// ---------------- HEAD ("half round": flat bottom, semicircular top) --
head_w      = 80;
head_d      = 66;
head_rect   = 26;              // straight part before the dome starts
head_h      = head_rect + head_w/2;             // 66
head_f      = 6;               // edge rounding
head_wall   = 2.4;
head_gap    = 1;
head_split  = 8;               // y of the front / back split plane
oled_z      = 34;              // centre of the eyes
oled_win    = [23, 12];        // 0.96" OLED active area is ~21.7 x 10.9
oled_glass  = [27.2, 19.8, 1.5];
ear_z       = 17;

// ---------------- ARMS / SIGN ---------------------------------------
arm_t       = 12;              // arm thickness
arm_gap     = 1;
arm_S       = [0, shoulder_z];          // (y, z) shoulder = servo shaft
arm_E       = [-3, shoulder_z-19];      // elbow
arm_H       = [-25, shoulder_z-16];     // hand
sign_w      = 84;
sign_h      = 46;
sign_t      = 4;

// =====================================================================
//  helpers
// =====================================================================
module rrect(w, d, r) offset(r) square([w-2*r, d-2*r], center=true);
module ring(ro, ri, h) difference() { cylinder(r=ro, h=h); translate([0,0,-eps]) cylinder(r=ri, h=h+2*eps); }
module rcyl(r, h, f)
    hull() { cylinder(r=r, h=h-f); translate([0,0,h-f]) rotate_extrude() translate([r-f,0]) circle(f); }
module arc2d(r, t, a0, a1)
    intersection() {
        difference() { circle(r+t/2); circle(r-t/2); }
        polygon(concat([[0,0]], [for (a=[a0:5:a1]) 40*[cos(a), sin(a)]]));
    }
module at_wall(a, z) rotate(a) translate([base_r-shell_wall-2, 0, z]) rotate([0,90,0]) children();   // local z = outward

// =====================================================================
//  BASE
// =====================================================================
module base_floor() {     // print in white: it is the reflector
    difference() {
        union() {
            cylinder(r=base_r, h=floor_t);
            translate([0,0,floor_t-eps]) ring(lip_ro, lip_ri, lip_h+eps);
            // cone that throws the downward ring light out sideways
            rotate_extrude() polygon([[0,floor_t-eps],[19.5,floor_t-eps],[12,10.5],[0,10.5]]);
            // spacer tubes that carry the deck
            for (a=boss_angles) rotate(a) translate([boss_pos_r,0,floor_t-eps]) ring(5, 3.8, shell_z0-floor_t+eps);
        }
        for (a=boss_angles) rotate(a) translate([boss_pos_r,0,-eps]) {
            cylinder(d=3.4, h=floor_t+1);
            cylinder(d=6.6, h=1.8);
        }
        for (a=[0,90,180,270]) rotate(a+45) translate([52,0,-eps]) cylinder(d=10.4, h=1);   // rubber feet
    }
}

module base_band() { translate([0,0,floor_t]) ring(base_r, band_ri, band_h); }

module base_deck() {      // electronics tray; the LED ring is glued centred underneath
    difference() {
        union() {
            translate([0,0,shell_z0]) cylinder(r=deck_r, h=deck_t);
            // Nano slides into these grooved rails, USB end at the back wall
            for (s=[-1,1]) translate([s>0 ? nano_hw-0.8 : -nano_hw-2.2, 14, deck_top-eps]) cube([3, 40, nano_lift+4]);
            // 1000uF capacitor saddle (10 mm can, lying down)
            translate([-38, -16, deck_top-eps]) difference() {
                cube([14, 18, 7]);
                translate([7, -1, 7.2]) rotate([-90,0,0]) cylinder(d=10.6, h=20);
            }
        }
        // rail grooves for the Nano PCB (1.6 mm)
        for (s=[-1,1]) translate([s>0 ? nano_hw-1 : -nano_hw-0.3, 13, deck_top+nano_lift]) cube([1.3, 42, 1.9]);
        for (a=boss_angles) rotate(a) translate([boss_pos_r,0,shell_z0-1]) cylinder(d=7.4, h=deck_t+2);
        translate([0,0,shell_z0-1]) cylinder(d=12, h=deck_t+2);                  // LED ring wires
        translate([0,-30,shell_z0-1]) hull() for (x=[-6,6]) translate([x,0,0]) cylinder(d=6, h=deck_t+2);  // sensor wires
    }
}

module base_shell() {
    difference() {
        union() {
            difference() {
                translate([0,0,shell_z0]) rcyl(base_r, shell_h, shell_fillet);
                translate([0,0,shell_z0-eps]) cylinder(r=base_r-shell_wall, h=shell_h-shell_top_t+eps);
            }
            // lip into the band + ledge that the deck rests on
            translate([0,0,shell_z0-lip_h]) ring(lip_ro, lip_ri, lip_h+eps);
            // bosses: wide above the deck, narrow through it down to the floor
            for (a=boss_angles) rotate(a) translate([boss_pos_r,0,0]) {
                translate([0,0,deck_top]) cylinder(d=10, h=ceil_z-deck_top+eps);
                translate([0,0,floor_t]) cylinder(d=7, h=deck_top-floor_t+eps);
            }
            // sockets for the sign tabs
            for (x=[-sign_tab_x, sign_tab_x]) translate([x-8, sign_y-4.2, ceil_z-8]) cube([16, 8.4, 8+eps]);
        }
        // floor screws
        for (a=boss_angles) rotate(a) translate([boss_pos_r,0,floor_t-eps]) cylinder(d=2.6, h=12);
        // body screws (M3 from inside), wire pass-through
        for (p=body_pillars) translate([p[0], p[1], ceil_z-1]) cylinder(d=3.4, h=10);
        translate([0,0,ceil_z-1]) cylinder(d=20, h=10);
        // sign slots
        for (x=[-sign_tab_x, sign_tab_x]) translate([x-6.2, sign_y-2.2, ceil_z-9]) cube([12.4, 4.4, 20]);
        // VL53L0X: window + locating pocket under the top
        translate([-5, sensor_y-3, ceil_z-1]) cube([10, 6, 10]);
        translate([-sensor_pcb[0]/2, sensor_y-sensor_pcb[1]/2, ceil_z-1]) cube([sensor_pcb[0], sensor_pcb[1], 1+1]);
        // back openings
        at_wall(nano_usb_a, shell_z0+2.5+nano_lift+3.5) linear_extrude(10) rrect(nano_usb_hole[1], nano_usb_hole[0], 2);
        at_wall(pwr_a,      shell_z0+15)  linear_extrude(10) rrect(pwr_hole[1], pwr_hole[0], pwr_hole[1]/2-0.01);
        at_wall(sw_a,       shell_z0+15)  linear_extrude(10) square([sw_hole[1], sw_hole[0]], center=true);
    }
}

// =====================================================================
//  BODY
// =====================================================================
module body_solid(w=body_w, d=body_d, h=body_h, r=body_r, f=body_fillet)
    hull() for (x=[-1,1], y=[-1,1]) translate([x*(w/2-r), y*(d/2-r), 0]) {
        cylinder(r=r, h=h-f);
        translate([0,0,h-f]) rotate_extrude() translate([r-f,0]) circle(f);
    }

sv_cz = shoulder_z - sv_shaft_off;          // arm servo body centre height

module body() {
    difference() {
        union() {
            difference() {
                body_solid();
                translate([0,0,-eps]) linear_extrude(body_tt+eps) rrect(body_w-2*body_wall, body_d-2*body_wall, body_r-body_wall);
            }
            intersection() {
                body_solid();
                union() {
                    for (p=body_pillars) translate([p[0], p[1], 0]) cylinder(d=7, h=body_tt+eps);
                    // thick side pads for the arm servos
                    for (s=[-1,1]) translate([s>0 ? body_w/2-pad_t : -body_w/2, -10, 4]) cube([pad_t, 20, body_tt-4+eps]);
                }
            }
        }
        // HEAD SERVO through the top plate, shaft on the vertical axis, inserted from below
        translate([0, -sv_shaft_off, body_tt-eps]) linear_extrude(body_top_t+1) square([sv_w+0.6, sv_l+0.6], center=true);
        for (y=[-1,1]) translate([0, -sv_shaft_off + y*sv_screw_sp/2, body_tt-eps]) cylinder(d=1.8, h=5);
        // ARM SERVOS: upper body sits in a pocket in the side pad, boss goes through the wall
        for (s=[-1,1]) mirror([s<0 ? 1 : 0, 0, 0]) {
            x0 = body_w/2 - pad_t;
            translate([x0-eps, -(sv_w+0.6)/2, sv_cz-(sv_l+0.6)/2]) cube([sv_up+0.3, sv_w+0.6, sv_l+0.6]);
            translate([x0, 0, 0]) rotate([0,90,0]) linear_extrude(pad_t+1) hull() {
                translate([-shoulder_z, 0]) circle(d=sv_boss_d+0.6);
                translate([-(shoulder_z-7), 0]) circle(d=6.5);
            }
            for (z=[-1,1]) translate([x0-eps, 0, sv_cz + z*sv_screw_sp/2]) rotate([0,90,0]) cylinder(d=1.8, h=6);
        }
        // head wires
        translate([0, 17.5, body_tt-1]) cylinder(d=6, h=10);
        // base screws (M3 self-tapping from inside the base)
        for (p=body_pillars) translate([p[0], p[1], -eps]) cylinder(d=2.6, h=10);
    }
}

// =====================================================================
//  HEAD
// =====================================================================
module head_profile()
    intersection() {
        hull() { translate([-head_w/2, 0]) square([head_w, head_rect]); translate([0, head_rect]) circle(head_w/2, $fn=96); }
        translate([-head_w, 0]) square(2*head_w);
    }

module head_core(o=0)      // outer shape shrunk by o (o = head_wall gives the inner surface)
    minkowski() {
        rotate([90,0,0]) linear_extrude(head_d-2*head_f, center=true) offset(delta=-head_f) head_profile();
        sphere(head_f-o, $fn=24);
    }

module visor_2d()
    offset(r=3) offset(delta=-3) intersection() { offset(delta=-8) head_profile(); translate([-50, 12]) square(100); }

module head_lip()
    intersection() {
        difference() { head_core(head_wall+fit); head_core(head_wall+fit+lip_t); }
        translate([-100, head_split-eps, -1]) cube([200, lip_h+eps, 100]);
    }

module head_wire_slot() translate([0,0,-1]) linear_extrude(14) arc2d(17.5, 6.5, 55, 125);

top_pz = head_rect + sqrt(pow(head_w/2-head_wall,2) - 22*22) - 4;
pillars = [ [28, head_wall+4, 0, -1], [-28, head_wall+4, 0, -1],
            [22, top_pz, 0.64, 0.77], [-22, top_pz, -0.64, 0.77] ];     // x, z, toward-wall direction

module head_all() {
    y0 = head_split - 14;
    difference() {
        union() {
            difference() { head_core(0); head_core(head_wall); }
            intersection() {
                head_core(0);
                union() {
                    linear_extrude(10) union() {                   // neck boss holding the servo horn
                        circle(15);
                        hull() for (x=[-14,14]) translate([x,0]) circle(7.5);
                    }
                    for (p=pillars) hull() {                        // screw pillars with a 45 deg lead-in
                        translate([p[0], y0, p[1]]) rotate([-90,0,0]) cylinder(d=8, h=head_d);
                        translate([p[0]+p[2]*3, y0-8, p[1]+p[3]*3]) rotate([-90,0,0]) cylinder(d=2, h=0.1);
                    }
                    intersection() {                                         // antenna boss (front half only)
                        translate([0,0,head_h-head_wall-8]) cylinder(r=10, h=8);
                        translate([-20,-20,0]) cube([40, 20+head_split-0.5, 100]);
                    }
                }
            }
        }
        // face opening
        translate([0, -head_d/2-1, 0]) rotate([-90,0,0]) mirror([0,1,0]) linear_extrude(head_wall+2) visor_2d();
        // ear holes
        for (s=[-1,1]) translate([s*(head_w/2-head_wall-1), 0, ear_z]) rotate([0, s*90, 0]) cylinder(d=16.4, h=5);
        // servo clearance, single-arm horn pocket, horn screw access (through the antenna hole)
        translate([0,0,-1]) cylinder(r=12.5, h=4);
        translate([0,0,-1]) linear_extrude(7.2) union() {
            circle(4.1);
            hull() for (x=[-18,18]) translate([x,0]) circle(3.2);
        }
        translate([0,0,-1]) cylinder(d=5, h=14);
        // antenna hole with countersink
        translate([0,0,head_h-head_wall-9]) cylinder(d=7.4, h=12);
        translate([0,0,head_h-4.5]) cylinder(d1=7.4, d2=16.4, h=4.5+eps);
        // M3 screws: pilots in front, clearance + counterbore in back
        for (p=pillars) translate([p[0], 0, p[1]]) rotate([-90,0,0]) {
            translate([0,0,head_split-12]) cylinder(d=2.6, h=12+eps);
            translate([0,0,head_split]) cylinder(d=3.4, h=40);
            translate([0,0,head_split+8]) cylinder(d=6.4, h=40);
        }
    }
}

module head_front() {
    difference() {
        union() {
            intersection() { head_all(); translate([-100,-100,-1]) cube([200, 100+head_split, 100]); }
            head_lip();
        }
        head_wire_slot();
    }
}

module head_back() {
    difference() {
        intersection() { head_all(); translate([-100, head_split, -1]) cube([200, 100, 100]); }
        intersection() {
            difference() { head_core(head_wall-0.4); head_core(head_wall+fit+lip_t+fit); }
            translate([-100, head_split-eps, -1]) cube([200, lip_h+0.4, 100]);
        }
        head_wire_slot();
    }
}

module face_plate() {    // print in black; the OLED glass drops into the pocket at the back
    y0 = -head_d/2;
    difference() {
        union() {
            translate([0, y0+0.05, 0]) rotate([-90,0,0]) mirror([0,1,0]) linear_extrude(head_wall-0.05) offset(delta=-0.2) visor_2d();
            translate([0, y0+head_wall, 0]) rotate([-90,0,0]) mirror([0,1,0]) linear_extrude(1.6) offset(delta=3) visor_2d();
        }
        translate([0, y0-1, oled_z]) rotate([-90,0,0]) linear_extrude(10) rrect(oled_win[0], oled_win[1], 1);
        translate([0, y0+head_wall+1.6-oled_glass[2], oled_z]) rotate([-90,0,0]) linear_extrude(5) square([oled_glass[0], oled_glass[1]], center=true);
    }
}

// ear: local z = 0 against the head side, +z outward
module ear_ring() {
    difference() {
        union() {
            rotate_extrude() polygon([[6,0],[13,0],[13,4],[12,5],[6,5]]);
            translate([0,0,-3]) ring(8, 6, 3+eps);
        }
        translate([0,0,2]) cylinder(d=14, h=10);
    }
}
module ear_cap() { cylinder(d=13.6, h=3); translate([0,0,3]) scale([1,1,0.2]) sphere(d=13.6, $fn=sph_fn); }

// antenna: local z = 0 is the head top
module antenna_stem() {
    difference() {
        union() {
            translate([0,0,-10]) cylinder(d=7, h=10-4.5+eps);
            translate([0,0,-4.5]) cylinder(d1=7, d2=16, h=4.5);
            hull() { cylinder(d=16, h=1.2); cylinder(d=13.6, h=2.4); }
            cylinder(d=7, h=12);
        }
        translate([0,0,-11]) cylinder(d=3.5, h=30);
    }
}
module antenna_ball() {
    difference() {
        intersection() { translate([0,0,5]) sphere(r=7.5, $fn=sph_fn); translate([0,0,50]) cube(100, center=true); }
        translate([0,0,-eps]) cylinder(d=7.3, h=4);
        translate([0,0,-eps]) cylinder(d=5.4, h=10.5);
    }
}

// =====================================================================
//  ARMS + SIGN
// =====================================================================
module arm_ball(p, r) translate([0, p[0], p[1]]) sphere(r, $fn=sph_fn);

// right arm; local x = 0 is the inner face (against the servo), x = arm_t the outer face
module arm_shape() {
    dir = [arm_E[0]-arm_S[0], arm_E[1]-arm_S[1]] / norm([arm_E[0]-arm_S[0], arm_E[1]-arm_S[1]]);
    difference() {
        intersection() {
            translate([arm_t/2,0,0]) union() {
                arm_ball(arm_S, 11);
                hull() { arm_ball(arm_S, 8.5); arm_ball(arm_E, 7.5); }
                hull() { arm_ball(arm_E, 7.5); arm_ball(arm_H, 7); }
                arm_ball(arm_H, 9.5);
            }
            translate([0, -100, -100]) cube([arm_t, 200, 200]);
        }
        // servo boss clearance, horn pocket along the upper arm, screw access
        translate([-1, arm_S[0], arm_S[1]]) rotate([0,90,0]) cylinder(r=8.5, h=1+2.5);
        translate([-1, arm_S[0], arm_S[1]]) rotate([0,90,0]) rotate([0,0,90]) linear_extrude(1+6.5)
            hull() { circle(4.1); translate([dir[0]*17, dir[1]*17]) circle(3.2); }
        translate([-1, arm_S[0], arm_S[1]]) rotate([0,90,0]) cylinder(d=5, h=arm_t+2);
    }
}

module sign_2d() {
    translate([-sign_w/2, 0]) offset(r=6) offset(delta=-6) square([sign_w, sign_h]);
    for (x=[-sign_tab_x, sign_tab_x]) translate([x-6, -10]) square([12, 10.5]);
}
module sign_flat() {      // front face is z = 0 (print it face down), NFC sticker pocket on the back
    difference() {
        linear_extrude(sign_t) sign_2d();
        translate([0, sign_h/2, sign_t-1.2]) cylinder(d=26, h=2);
    }
}

// =====================================================================
//  ASSEMBLY
// =====================================================================
c_wood  = [0.83, 0.66, 0.45];
c_dark  = [0.25, 0.26, 0.28];
c_white = [0.92, 0.92, 0.9];
c_glow  = [0.35, 0.65, 1.0, 0.8];
c_black = [0.05, 0.05, 0.07];

module oled_dummy()    // preview only
    translate([0, -head_d/2+head_wall+1.6, oled_z]) {
        color([0.02,0.02,0.03]) translate([0,-oled_glass[2],0]) rotate([-90,0,0]) linear_extrude(oled_glass[2]) square([oled_glass[0], oled_glass[1]], center=true);
        color([0.3,0.75,1]) for (x=[-5.5,5.5]) translate([x, -oled_glass[2]-0.1, -2]) rotate([90,0,0]) linear_extrude(0.2) arc2d(4, 1.6, 25, 155);
    }

module head_assembly(ex=0) {
    color(c_wood) head_front();
    color(c_wood) translate([0, ex, 0]) head_back();
    color(c_black) translate([0, -ex*0.6, 0]) face_plate();
    if (ex == 0) oled_dummy();
    for (s=[-1,1]) translate([s*(head_w/2 + ex*0.4), 0, ear_z]) rotate([0, s*90, 0]) {
        color(c_glow) ear_ring();
        color(c_dark) translate([0,0,2]) ear_cap();
    }
    translate([0,0,head_h + ex*0.5]) {
        color(c_dark) antenna_stem();
        color(c_glow) translate([0,0,8 + ex*0.3]) antenna_ball();
    }
}

// ---- electronics dummies (preview only, never exported) ----
module sg90_dummy() {      // origin = bottom centre of the servo body, shaft offset along +x
    color([0.15,0.35,0.85]) {
        translate([-sv_l/2,-sv_w/2,0]) cube([sv_l, sv_w, 22.7]);
        translate([-16.2,-sv_w/2,sv_tab_z-2.5]) cube([32.4, sv_w, 2.5]);
        translate([sv_shaft_off,0,22.7]) cylinder(d=11.8, h=4);
    }
    color("white") translate([sv_shaft_off,0,26.7]) cylinder(d=4.8, h=3.2);
}
module head_servo_dummy() translate([0,0,body_tt - sv_tab_z]) rotate([0,0,90]) translate([-sv_shaft_off,0,0]) sg90_dummy();
module arm_servo_dummy(s) mirror([s<0?1:0,0,0]) translate([body_w/2-pad_t-sv_tab_z, 0, sv_cz]) multmatrix([[0,0,1,0],[0,-1,0,0],[1,0,0,0],[0,0,0,1]]) sg90_dummy();
module electronics_dummy() {
    color([0.1,0.4,0.7]) translate([-nano_hw+0.3, 11.5, deck_top+nano_lift]) cube([nano[0]-0.6, nano[1], 1.6]);   // Nano
    color([0.1,0.1,0.1]) translate([0,0,shell_z0-ring16[2]]) ring(ring16[0]/2, ring16[1]/2, ring16[2]);      // LED ring
    color([0.6,0.1,0.6]) translate([-sensor_pcb[0]/2+0.5, sensor_y-sensor_pcb[1]/2+0.5, ceil_z-2.6]) cube([sensor_pcb[0]-1, sensor_pcb[1]-1, 1.6]); // VL53L0X
    color([0.2,0.2,0.6]) translate([-31, -15, deck_top+7.2]) rotate([-90,0,0]) cylinder(d=10, h=16);           // capacitor
    translate([0,0,base_h]) { head_servo_dummy(); arm_servo_dummy(1); arm_servo_dummy(-1); }
}

module robot(ex=0) {
    color(c_white) translate([0,0,-ex*1.2]) base_floor();
    color(c_glow)  translate([0,0,-ex*0.8]) base_band();
    color(c_white) translate([0,0,-ex*0.4]) base_deck();
    color(c_wood)  base_shell();
    translate([0,0,base_h + ex*0.6]) {
        color(c_dark) body();
        color(c_wood) translate([body_w/2+arm_gap + ex*0.4, 0, 0]) arm_shape();
        color(c_wood) mirror([1,0,0]) translate([body_w/2+arm_gap + ex*0.4, 0, 0]) arm_shape();
        color(c_wood) translate([0, sign_y-sign_t/2 - ex*0.8, 0]) rotate([90,0,0]) mirror([0,0,1]) sign_flat();
        translate([0,0,body_h + head_gap + ex*1.2]) head_assembly(ex);
    }
}

// =====================================================================
//  PART SELECTOR (print orientation)
// =====================================================================
if      (part == "assembly")     robot();
else if (part == "exploded")     robot(45);
else if (part == "cutaway")      { intersection() { robot(); translate([-200,-200,-1]) cube([200,400,400]); } electronics_dummy(); }
else if (part == "base_floor")   base_floor();
else if (part == "base_band")    translate([0,0,-floor_t]) base_band();
else if (part == "base_deck")    translate([0,0,-shell_z0]) base_deck();
else if (part == "base_shell")   translate([0,0,base_h]) rotate([180,0,0]) base_shell();
else if (part == "body")         translate([0,0,body_h]) rotate([180,0,0]) body();
else if (part == "head_front")   translate([0,0,head_d/2]) rotate([90,0,0]) head_front();
else if (part == "head_back")    translate([0,0,head_d/2]) rotate([-90,0,0]) head_back();
else if (part == "face_plate")   translate([0,0,-(head_d/2-head_wall-1.6)]) rotate([-90,0,0]) face_plate();
else if (part == "ear_ring")     translate([0,0,5]) rotate([180,0,0]) ear_ring();
else if (part == "ear_cap")      ear_cap();
else if (part == "antenna_stem") translate([0,0,10]) antenna_stem();
else if (part == "antenna_ball") antenna_ball();
else if (part == "arm_right")    translate([0,0,arm_t]) rotate([0,90,0]) arm_shape();
else if (part == "arm_left")     mirror([1,0,0]) translate([0,0,arm_t]) rotate([0,90,0]) arm_shape();
else if (part == "sign")         sign_flat();
