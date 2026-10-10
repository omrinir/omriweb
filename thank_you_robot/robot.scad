// =====================================================================
//  THANK-YOU ROBOT  -  3D-printable enclosure for the NFC review robot
//  OpenSCAD 2021.01+   (all dimensions in mm)
//
//  Preview the whole robot:   open this file in OpenSCAD (part="assembly")
//  Export one part:           openscad -D 'part="head_front"' -o head_front.stl robot.scad
//  Parts: base_floor, base_band, base_shell, body, head_front, head_back,
//         face_plate, ear_ring, ear_cap, antenna_stem, antenna_ball,
//         arm_right, arm_left, sign, assembly, exploded
//  Every printable part is exported already rotated to its print orientation.
// =====================================================================

part = "assembly";

$fn    = 64;
sph_fn = 48;
eps    = 0.01;
fit    = 0.2;                 // general sliding clearance

// ---------------- BASE ----------------------------------------------
base_r       = 60;            // outer radius (120 mm diameter)
floor_t      = 4;
band_h       = 10;            // translucent glow ring height
band_t       = 1.8;
shell_h      = 25;
shell_wall   = 2.4;
shell_top_t  = 3;
shell_fillet = 5;
base_h       = floor_t + band_h + shell_h;     // 39
shell_z0     = floor_t + band_h;               // 14
lip_t        = 1.4;
lip_h        = 2;
band_ri      = base_r - band_t;                // 58.2
lip_ro       = band_ri - fit;                  // 58.0
lip_ri       = lip_ro - lip_t;                 // 56.6
facet_y      = -(base_r - 2);                  // flat front face for the NFC logo
drum_r       = 51.6;                           // LED strip is stuck on the outside of this drum
drum_t       = 1.6;
boss_pos_r   = 44;
boss_angles  = [0, 120, 240];
sensor_tilt  = 35;                             // proximity sensor looks up & forward
usb_pcb      = [18.4, 29, 1.8];                // pocket for charger / power module (w, length, depth)
usb_block_z  = 23;                             // underside of the module pocket block
usb_port     = [9.8, 4.2];                     // USB-C opening

// ---------------- BODY ----------------------------------------------
body_w      = 64;
body_d      = 52;
body_h      = 34;
body_r      = 20;
body_wall   = 2.4;
body_top_t  = 6;               // thick top plate - SG90 tabs screw to its underside
body_fillet = 6;
body_pillars = [[24,16],[-24,16],[24,-16],[-24,-16]];
shoulder_z  = 24;

// SG90 micro servo (output shaft sits on the robot's vertical axis)
sv_l        = 22.8;
sv_w        = 12.4;
sv_shaft_off= 5.5;             // shaft distance from servo body centre
sv_screw_sp = 27.8;

// ---------------- HEAD ----------------------------------------------
head_w      = 100;
head_d      = 80;
head_h      = 66;
head_r      = 14;
head_wall   = 2.4;
head_gap    = 1;               // gap between body top and head bottom
head_split  = 16;              // y of the front/back split plane
head_zc     = head_h/2;
visor       = [66, 34, 8];     // face opening  (w, h, corner r)
oled_win    = [57, 29];        // 2.42" 128x64 OLED active area is 55 x 27.5
ear_z       = head_zc;
pillar_pts  = [[30, 6.4], [-30, 6.4], [30, head_h-6.4], [-30, head_h-6.4]];   // (x, z)

// ---------------- SIGN / ARMS ---------------------------------------
sign_w      = 72;
sign_h      = 31;
sign_t      = 4;
sign_y      = -27.5;           // back face of the sign
sign_z0     = 0.5;
arm_x       = 37;              // centre plane of the arms
arm_S       = [0, shoulder_z]; // (y, z) shoulder
arm_E       = [5, 8];          // elbow
arm_H       = [-29.5, 16];     // hand (grips the sign edge)
font_b      = "DejaVu Sans:style=Bold";

// =====================================================================
//  helpers
// =====================================================================
module rrect(w, d, r) offset(r) square([w-2*r, d-2*r], center=true);

module ring(ro, ri, h) difference() { cylinder(r=ro, h=h); translate([0,0,-eps]) cylinder(r=ri, h=h+2*eps); }

module rbox(s, r)   // rounded box, centred in x/y, z from 0
    hull() for (x=[-1,1], y=[-1,1], z=[-1,1])
        translate([x*(s[0]/2-r), y*(s[1]/2-r), s[2]/2 + z*(s[2]/2-r)]) sphere(r, $fn=sph_fn);

module rcyl(r, h, f)    // cylinder with filleted top edge
    hull() { cylinder(r=r, h=h-f); translate([0,0,h-f]) rotate_extrude() translate([r-f,0]) circle(f); }

module arc2d(r, t, a0, a1)
    intersection() {
        difference() { circle(r+t/2); circle(r-t/2); }
        polygon(concat([[0,0]], [for (a=[a0:5:a1]) 40*[cos(a), sin(a)]]));
    }

// =====================================================================
//  BASE
// =====================================================================
module base_floor() {
    difference() {
        union() {
            cylinder(r=base_r, h=floor_t);
            translate([0,0,floor_t-eps]) ring(lip_ro, lip_ri, lip_h+eps);       // locates the glow band
            translate([0,0,floor_t-eps]) difference() {                         // LED strip drum
                ring(drum_r, drum_r-drum_t, drum_h+eps);
                translate([-3, 0, drum_h/2]) cube([6, drum_r+5, drum_h]);       // wire notch (back)
            }
            // 18650 holder rails (y = 14) and Arduino Nano rails (y = -20)
            for (y=[14-11.3, 14+11.3]) translate([-38, y-0.8, floor_t-eps]) cube([76, 1.6, 2]);
            for (y=[-20-9.6, -20+9.6]) translate([-23, y-0.8, floor_t-eps]) cube([46, 1.6, 2]);
        }
        for (a=boss_angles) rotate(a) translate([boss_pos_r,0,0]) {
            translate([0,0,-eps]) cylinder(d=3.4, h=floor_t+1);
            translate([0,0,-eps]) cylinder(d=6.6, h=2);                          // screw head recess
        }
        for (a=[60,180,300]) rotate(a) translate([52,0,-eps]) cylinder(d=10.4, h=1);   // rubber feet
        for (x=[-25,25], y=[14-13, 14+13]) translate([x-2.25, y-1.25, -eps]) cube([4.5, 2.5, floor_t+1]); // zip ties
    }
}

module base_band() {
    translate([0,0,floor_t]) ring(base_r, band_ri, band_h);
}

module nfc_logo_2d() {
    translate([0, shell_z0 + 9.5]) {
        circle(1.5);
        for (r=[4.5, 7, 9.5]) arc2d(r, 1.5, 45, 135);
    }
    translate([0, shell_z0 + 4.5]) text("NFC", size=5.5, font=font_b, halign="center", valign="center");
}

module sensor_frame() {        // origin of the tilted proximity-sensor seat
    translate([0, -45, base_h - shell_top_t - 5]) rotate([sensor_tilt,0,0]) children();
}

module base_shell() {
    ceil_z = base_h - shell_top_t;
    difference() {
        union() {
            difference() {
                translate([0,0,shell_z0]) rcyl(base_r, shell_h, shell_fillet);
                // hollow, with a flat inner face behind the NFC facet
                intersection() {
                    translate([0,0,shell_z0-eps]) cylinder(r=base_r-shell_wall, h=shell_h-shell_top_t+eps);
                    translate([-100, facet_y+shell_wall, 0]) cube([200, 200, 100]);
                }
            }
            // lip that drops into the glow band
            translate([0,0,shell_z0-lip_h]) ring(lip_ro, lip_ri, lip_h+eps);
            // screw bosses for the floor
            for (a=boss_angles) rotate(a) translate([boss_pos_r,0,floor_t]) cylinder(d=8, h=ceil_z-floor_t+eps);
            // charger / power module block (module is pressed in components-down, USB-C at the wall)
            intersection() {
                translate([-12, 26, usb_block_z]) cube([24, 40, ceil_z-usb_block_z+eps]);
                cylinder(r=base_r-1, h=base_h);
            }
            // tilted seat for a VL53L0X proximity sensor
            intersection() {
                translate([-14, -58, ceil_z-14]) cube([28, 24, 14+eps]);
                sensor_frame() translate([-50,-50,0]) cube(100);
                cylinder(r=base_r-shell_wall+eps, h=base_h);
            }
        }
        // flat front facet
        translate([-100, facet_y-200, 0]) cube([200, 200, 100]);
        // NFC logo engraved 0.6 mm into the facet
        translate([0, facet_y+0.6, 0]) rotate([90,0,0]) linear_extrude(2) nfc_logo_2d();
        // floor screw pilots
        for (a=boss_angles) rotate(a) translate([boss_pos_r,0,floor_t-eps]) cylinder(d=2.6, h=12);
        // body screws, wire pass-through
        for (p=body_pillars) translate([p[0], p[1], ceil_z-1]) cylinder(d=3.4, h=10);
        translate([0,0,ceil_z-1]) cylinder(d=18, h=10);
        // sensor window
        sensor_frame() translate([-4, -2.5, -2]) cube([8, 5, 30]);
        // module pocket + USB-C opening
        translate([-usb_pcb[0]/2, base_r-shell_wall-usb_pcb[1], usb_block_z-eps]) cube([usb_pcb[0], usb_pcb[1]+1, usb_pcb[2]+eps]);
        translate([0, base_r-shell_wall-3, usb_block_z+usb_pcb[2]-1.6-1.6]) rotate([-90,0,0])
            hull() for (x=[-1,1]) translate([x*(usb_port[0]-usb_port[1])/2, 0, 0]) cylinder(d=usb_port[1], h=10);
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

module body() {
    tt = body_h - body_top_t;     // underside of the top plate = top of the servo tabs
    difference() {
        union() {
            difference() {
                body_solid();
                translate([0,0,-eps]) linear_extrude(tt+eps) rrect(body_w-2*body_wall, body_d-2*body_wall, body_r-body_wall);
            }
            intersection() {
                body_solid();
                union() {
                    for (p=body_pillars) translate([p[0], p[1], 0]) cylinder(d=7, h=tt+eps);
                    for (s=[-1,1]) hull() {          // shoulder bosses (grow from the plate - no overhang)
                        translate([s*26.5, 0, shoulder_z]) rotate([0,90,0]) cylinder(d=11, h=7, center=true);
                        translate([s*26.5, 0, tt]) cube([7, 11, 0.6], center=true);
                    }
                }
            }
        }
        // SG90 through the top plate (inserted from below, tabs screwed up into the plate)
        translate([-sv_shaft_off, 0, tt-eps]) linear_extrude(body_top_t+1) square([sv_l+0.6, sv_w+0.6], center=true);
        for (x=[-1,1]) translate([-sv_shaft_off + x*sv_screw_sp/2, 0, tt-eps]) cylinder(d=1.8, h=5);
        // head wires
        translate([0, 17.5, tt-1]) cylinder(d=5.5, h=10);
        // base screws (M3 self-tapping from inside the base)
        for (p=body_pillars) translate([p[0], p[1], -eps]) cylinder(d=2.6, h=10);
        // arm sockets
        for (s=[-1,1]) translate([s*(body_w/2+1), 0, shoulder_z]) rotate([0, s*-90, 0]) cylinder(d=5.3, h=9);
        // 1.75 mm filament pins that locate the sign
        for (x=[-10,10]) translate([x, -body_d/2-1, sign_z0+sign_h/2]) rotate([-90,0,0]) cylinder(d=1.9, h=body_wall+2);
    }
}

// =====================================================================
//  HEAD
// =====================================================================
module head_outer() rbox([head_w, head_d, head_h], head_r);
module head_inner(o=0)
    translate([0,0,head_wall+o]) rbox([head_w-2*(head_wall+o), head_d-2*(head_wall+o), head_h-2*(head_wall+o)], head_r-head_wall-o);

module head_lip() {           // alignment lip on the front half, slides into the back cover
    intersection() {
        difference() { head_inner(fit); head_inner(fit+lip_t); }
        translate([-100, head_split-eps, -1]) cube([200, lip_h+eps, 100]);
    }
}

module head_wire_slot()
    translate([0,0,-1]) linear_extrude(14) arc2d(17.5, 6, 55, 125);

module head_all() {
    difference() {
        union() {
            difference() { head_outer(); head_inner(); }
            intersection() {
                head_outer();
                union() {
                    // neck boss that holds the servo horn
                    linear_extrude(10) union() {
                        circle(15);
                        hull() for (x=[-14,14]) translate([x,0]) circle(8);
                    }
                    // screw pillars joining front and back
                    for (p=pillar_pts) translate([p[0], -head_d/2, p[1]]) rotate([-90,0,0]) cylinder(d=8, h=head_d);
                    // antenna boss
                    translate([0,0,head_h-head_wall-8]) cylinder(r=10, h=8+eps);
                }
            }
        }
        // face opening
        translate([0, -head_d/2-1, head_zc]) rotate([-90,0,0]) linear_extrude(head_wall+2) rrect(visor[0], visor[1], visor[2]);
        // ear holes
        for (s=[-1,1]) translate([s*(head_w/2-head_wall-1), 0, ear_z]) rotate([0, s*90, 0]) cylinder(d=24.4, h=5);
        // servo clearance, horn pocket, screw access
        translate([0,0,-1]) cylinder(r=12.5, h=1+3);
        translate([0,0,-1]) linear_extrude(1+6.2) union() {
            circle(4.1);
            hull() for (x=[-18,18]) translate([x,0]) circle(3.2);
        }
        translate([0,0,-1]) cylinder(d=5, h=14);
        // antenna hole with countersink
        translate([0,0,head_h-head_wall-9]) cylinder(d=7.4, h=12);
        translate([0,0,head_h-4.5]) cylinder(d1=7.4, d2=16.4, h=4.5+eps);
        // screw holes: pilots in front pillars, clearance + counterbore in the back cover
        for (p=pillar_pts) translate([p[0], 0, p[1]]) rotate([-90,0,0]) {
            translate([0,0,head_split-14]) cylinder(d=2.6, h=14+eps);
            translate([0,0,head_split]) cylinder(d=3.4, h=30);
            translate([0,0,head_split+8]) cylinder(d=6.4, h=30);
        }
    }
}

module head_front() {
    difference() {
        union() {
            intersection() { head_all(); translate([-100, -100, -1]) cube([200, 100+head_split, 100]); }
            head_lip();
        }
        head_wire_slot();
    }
}

module head_back() {
    difference() {
        intersection() { head_all(); translate([-100, head_split, -1]) cube([200, 100, 100]); }
        intersection() {        // room for the lip
            difference() { head_inner(0); head_inner(fit+lip_t+fit); }
            translate([-100, head_split-eps, -1]) cube([200, lip_h+0.4, 100]);
        }
        head_wire_slot();
    }
}

module face_plate() {   // print in black PLA; glue a 2.42" OLED behind the window
    y0 = -head_d/2;
    difference() {
        union() {
            translate([0, y0+0.05, head_zc]) rotate([-90,0,0]) linear_extrude(head_wall-0.05) rrect(visor[0]-0.4, visor[1]-0.4, visor[2]-0.2);
            translate([0, y0+head_wall, head_zc]) rotate([-90,0,0]) linear_extrude(1.6) rrect(visor[0]+6, visor[1]+6, visor[2]+2);
        }
        translate([0, y0-1, head_zc]) rotate([-90,0,0]) linear_extrude(10) rrect(oled_win[0], oled_win[1], 1.5);
    }
}

// ear: local z = 0 is the face against the head, +z points outward
module ear_ring() {   // translucent
    difference() {
        union() {
            rotate_extrude() polygon([[9,0],[17,0],[17,4.8],[15.8,6],[9,6]]);
            translate([0,0,-4]) ring(12, 10, 4+eps);
        }
        translate([0,0,2.5]) cylinder(d=22, h=10);
    }
}
module ear_cap() {    // dark grey / wood
    cylinder(d=21.6, h=3.5);
    translate([0,0,3.5]) scale([1,1,0.18]) sphere(d=21.6, $fn=sph_fn);
}

// antenna: local z = 0 is the head top surface
module antenna_stem() {
    difference() {
        union() {
            translate([0,0,-10]) cylinder(d=7, h=10-4.5+eps);
            translate([0,0,-4.5]) cylinder(d1=7, d2=16, h=4.5);
            hull() { cylinder(d=16, h=1.2); cylinder(d=13.6, h=2.4); }
            cylinder(d=7, h=12);
        }
        translate([0,0,-11]) cylinder(d=3.5, h=30);     // LED legs / wires
    }
}
module antenna_ball() {   // translucent, a 5 mm LED sits inside
    difference() {
        intersection() {
            translate([0,0,5]) sphere(r=7.5, $fn=sph_fn);
            translate([0,0,50]) cube(100, center=true);
        }
        translate([0,0,-eps]) cylinder(d=7.3, h=4);
        translate([0,0,-eps]) cylinder(d=5.4, h=10.5);
    }
}

// =====================================================================
//  ARMS + SIGN
// =====================================================================
module arm_ball(p, r) translate([0, p[0], p[1]]) sphere(r, $fn=sph_fn);

module arm_shape() {   // right arm, local x = 0 is its centre plane, inner face at x = -4.5
    difference() {
        union() {
            intersection() {
                union() {
                    hull() { arm_ball(arm_S, 5.5); arm_ball(arm_E, 5); }
                    hull() { arm_ball(arm_E, 5); arm_ball(arm_H, 4.5); }
                    arm_ball(arm_H, 7);
                }
                translate([-4.5, -100, -100]) cube([9, 200, 200]);
            }
            translate([-4.5+eps, arm_S[0], arm_S[1]]) rotate([0,-90,0]) cylinder(d1=5, d2=4.6, h=7.5);
        }
        translate([-4.5-eps, arm_H[0]-(sign_t+0.4)/2, arm_H[1]-8]) cube([4.5+eps, sign_t+0.4, 16]);   // grips the sign edge
    }
}

module sign_2d() offset(r=4) offset(delta=-4) translate([-sign_w/2, 0]) square([sign_w, sign_h]);

module sign() {
    translate([0, sign_y, sign_z0]) difference() {
        union() {
            rotate([90,0,0]) linear_extrude(sign_t) sign_2d();
            translate([0, -sign_t+eps, 0]) rotate([90,0,0]) linear_extrude(0.8) {
                difference() { offset(-1.6) sign_2d(); offset(-2.8) sign_2d(); }
                translate([0, 23.5]) text("Tap & Share", size=5.6, font=font_b, halign="center", valign="center");
                translate([0, 14.5]) text("Google Review", size=5.4, font=font_b, halign="center", valign="center");
                translate([0, 6.5])  text("★★★★★", size=5.6, font=font_b, halign="center", valign="center");
            }
        }
        for (x=[-10,10]) translate([x, 1, sign_h/2]) rotate([90,0,0]) cylinder(d=1.9, h=1+2.5);
    }
}

// =====================================================================
//  ASSEMBLY
// =====================================================================
c_wood  = [0.83, 0.66, 0.45];
c_dark  = [0.25, 0.26, 0.28];
c_glow  = [0.35, 0.65, 1.0, 0.75];
c_black = [0.05, 0.05, 0.07];

module head_assembly(ex=0) {
    color(c_wood) head_front();
    color(c_wood) translate([0, ex, 0]) head_back();
    color(c_black) translate([0, -ex*0.6, 0]) face_plate();
    if (ex == 0) oled_dummy();
    for (s=[-1,1]) translate([s*(head_w/2 + ex*0.5), 0, ear_z]) rotate([0, s*90, 0]) {
        color(c_glow) ear_ring();
        color(c_dark) translate([0,0,2.5]) ear_cap();
    }
    translate([0,0,head_h + ex*0.5]) {
        color(c_dark) antenna_stem();
        color(c_glow) translate([0,0,12-4 + ex*0.3]) antenna_ball();
    }
}

module oled_dummy() {   // preview only: 2.42" OLED showing the happy eyes
    translate([0, -head_d/2+head_wall+1.6, head_zc]) {
        color([0.02,0.02,0.03]) rotate([-90,0,0]) linear_extrude(3) square([60.5, 37], center=true);
        color([0.3,0.7,1]) for (x=[-14,14]) translate([x, -0.3, -3]) rotate([90,0,0]) linear_extrude(0.4) arc2d(9, 3.4, 25, 155);
    }
}

module robot(ex=0) {
    color(c_dark) translate([0,0,-ex]) base_floor();
    color(c_glow) translate([0,0,-ex*0.5]) base_band();
    color(c_wood) base_shell();
    translate([0,0,base_h + ex*0.6]) {
        color(c_dark) body();
        color(c_wood) translate([ex*0.4,0,0]) translate([arm_x,0,0]) arm_shape();
        color(c_wood) translate([-ex*0.4,0,0]) mirror([1,0,0]) translate([arm_x,0,0]) arm_shape();
        color(c_wood) translate([0,-ex*0.6,0]) sign();
        translate([0,0,body_h + head_gap + ex*1.2]) head_assembly(ex);
    }
}

// =====================================================================
//  PART SELECTOR (print orientation)
// =====================================================================
if      (part == "assembly")     robot();
else if (part == "exploded")     robot(40);
else if (part == "base_floor")   base_floor();
else if (part == "base_band")    translate([0,0,-floor_t]) base_band();
else if (part == "base_shell")   translate([0,0,base_h]) rotate([180,0,0]) base_shell();
else if (part == "body")         translate([0,0,body_h]) rotate([180,0,0]) body();
else if (part == "head_front")   translate([0,0,head_d/2]) rotate([90,0,0]) head_front();
else if (part == "head_back")    translate([0,0,head_d/2]) rotate([-90,0,0]) head_back();
else if (part == "face_plate")   translate([0,0,-(head_d/2-head_wall-1.6)]) rotate([-90,0,0]) face_plate();
else if (part == "ear_ring")     translate([0,0,6]) rotate([180,0,0]) ear_ring();
else if (part == "ear_cap")      ear_cap();
else if (part == "antenna_stem") translate([0,0,10]) antenna_stem();
else if (part == "antenna_ball") antenna_ball();
else if (part == "arm_right")    translate([0,0,4.5]) rotate([0,90,0]) arm_shape();
else if (part == "arm_left")     mirror([1,0,0]) translate([0,0,4.5]) rotate([0,90,0]) arm_shape();
else if (part == "sign")         translate([0,0,sign_y]) rotate([-90,0,0]) sign();
