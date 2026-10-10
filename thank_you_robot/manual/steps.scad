// Renders the pictures for the assembly manual.
// openscad -D 'part="none"' -D step=2 -o step2.png steps.scad
include <../robot.scad>
step = 0;
c_new   = [1.0, 0.55, 0.1];          // the parts added in this step
c_ghost = [0.6, 0.6, 0.65, 0.25];    // parts already in place, see-through

module body_cut() intersection() { body(); translate([-100,-1,-1]) cube([200,200,200]); }   // front half removed so you can see inside
module servos_in_body(ex=0) {
    head_servo_dummy();
    translate([ex,0,0]) arm_servo_dummy(1);
    translate([-ex,0,0]) arm_servo_dummy(-1);
}
module head_in_place() translate([0,0,body_h+head_gap]) head_assembly(0);

if (step == 2) {           // arm servos slide sideways into the pads
    color(c_dark) body_cut();
    translate([-6,0,0]) arm_servo_dummy(1);
    translate([6,0,0])  arm_servo_dummy(-1);
}
if (step == 3) {           // head servo pushes up into the top plate
    color(c_dark) body_cut();
    arm_servo_dummy(1); arm_servo_dummy(-1);
    translate([0,0,-22]) head_servo_dummy();
}
if (step == 4) {           // head build, exploded
    color(c_wood) head_front();
    color(c_wood) translate([0, 45, 0]) head_back();
    color(c_new) translate([0, -35, 0]) face_plate();
    color([0.1,0.3,0.6]) translate([0, -55, oled_z]) rotate([90,0,0]) translate([-13.6,-14,0]) cube([27.2, 28, 1.6]);
    for (s=[-1,1]) translate([s*(head_w/2 + 25), 0, ear_z]) rotate([0, s*90, 0]) {
        color(c_glow) ear_ring();
        color(c_dark) translate([0,0,8]) ear_cap();
    }
}
if (step == 5) {           // head drops onto the servo, antenna on top
    color(c_dark) body();
    servos_in_body();
    translate([0,0,body_h+head_gap+35]) {
        color(c_new) head_front(); color(c_new) head_back();
        color(c_black) face_plate();
        translate([0,0,head_h+25]) { color(c_dark) antenna_stem(); color(c_glow) translate([0,0,8]) antenna_ball(); }
    }
}
if (step == 6) {           // robot top onto the base shell
    color(c_wood) base_shell();
    translate([0,0,base_h+30]) { color(c_new) body(); head_in_place(); }
    for (p=body_pillars) color("red") translate([p[0],p[1],ceil_z-14]) cylinder(d=3, h=14);
}
module switch_dummy() at_wall(sw_a, shell_z0+15) color([0.85,0.1,0.1]) translate([0,0,-16]) linear_extrude(18.5) square([sw_hole[1]-0.4, sw_hole[0]-0.4], center=true);
module usbc_dummy()   at_wall(pwr_a, shell_z0+15) color([0.1,0.5,0.2]) translate([0,0,-11]) linear_extrude(13) square([4, 11], center=true);
if (step == 7) {           // deck: Nano on top, capacitor in its saddle, LED ring glued underneath
    color(c_white) base_deck();
    color([0.1,0.4,0.7]) translate([-nano_hw+0.3, 11.5, deck_top+nano_lift]) cube([nano[0]-0.6, nano[1], 1.6]);
    color([0.2,0.2,0.6]) translate([-31, -15, deck_top+7.2]) rotate([-90,0,0]) cylinder(d=10, h=16);
    color(c_new) translate([0,0,shell_z0-ring16[2]-25]) ring(ring16[0]/2, ring16[1]/2, ring16[2]);
}
if (step == 71) {          // deck flipped over: the LED ring is glued centred on its underside
    rotate([180,0,0]) translate([0,0,-shell_z0-deck_t]) {
        color(c_white) base_deck();
        color(c_new) translate([0,0,shell_z0-ring16[2]-20]) ring(ring16[0]/2, ring16[1]/2, ring16[2]);
    }
}
if (step == 8) {           // shell upside down: sensor, switch and USB-C board in place
    rotate([180,0,0]) {
        color(c_wood) base_shell();
        color(c_new) translate([-sensor_pcb[0]/2+0.5, sensor_y-sensor_pcb[1]/2+0.5, ceil_z-2.6]) cube([sensor_pcb[0]-1, sensor_pcb[1]-1, 1.6]);
        color(c_new) switch_dummy();
        color(c_new) usbc_dummy();
    }
}
if (step == 9) {           // close the base
    color(c_wood) base_shell();
    color(c_white) translate([0,0,-15]) base_deck();
    color(c_glow)  translate([0,0,-35]) base_band();
    color(c_new)   translate([0,0,-55]) base_floor();
    for (a=boss_angles) color("red") rotate(a) translate([boss_pos_r,0,-75]) cylinder(d=3, h=14);
}
if (step == 10) {          // arms onto the horns, sign into the slots
    color(c_wood) base_shell();
    translate([0,0,base_h]) {
        color(c_dark) body();
        head_in_place();
        color(c_new) translate([body_w/2+arm_gap+25, 0, 0]) arm_shape();
        color(c_new) mirror([1,0,0]) translate([body_w/2+arm_gap+25, 0, 0]) arm_shape();
        color(c_new) translate([0, sign_y-sign_t/2-10, 35]) rotate([90,0,0]) mirror([0,0,1]) sign_flat();
    }
}
