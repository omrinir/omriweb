// Pictures for the v4 assembly manual.  openscad -D 'part="none"' -D step=2 -o step2.png steps.scad
include <../robot_cute.scad>
step = 0;
c_new = [1.0, 0.55, 0.1];
c_w   = [0.93, 0.91, 0.88];
c_acc = [1.0, 0.36, 0.27];
c_ply = [0.85, 0.7, 0.5];
module hs()  translate([0,0,body_tt - sv_tab_z]) rotate([0,0,90]) translate([-sv_shaft_off,0,0]) sg90_dummy();
module as(s) mirror([s<0?1:0,0,0]) translate([body_w/2-pad_t-sv_tab_z, arm_shaft_y+sv_shaft_off, shoulder_z]) rotate([0,90,0]) rotate([0,0,-90]) sg90_dummy();
module body_cut() intersection() { body(); translate([-100,-1,-1]) cube([200,200,200]); }
module led5() { color([0.9,0.95,1]) cylinder(d=5, h=6); color([0.6,0.6,0.6]) translate([0,0,-6]) cylinder(d=1, h=6); }
hz = base_h + body_h + head_gap;
if (step == 2) { color(c_acc) body_cut(); translate([-7,0,0]) as(1); translate([7,0,0]) as(-1); }
if (step == 3) { color(c_acc) body_cut(); as(1); as(-1); translate([0,0,-24]) hs(); }
if (step == 4) {
    color(c_w) head_front(); color(c_w) translate([0, 40, 0]) head_back();
    color([0.05,0.05,0.07]) translate([0, -30, 0]) face_plate();
    color([1,0.55,0.7]) for (x=[-cheek_x, cheek_x]) translate([x, -head_d/2-38, cheek_z]) rotate([90,0,0]) cheek();
    color([0.1,0.3,0.6]) translate([0, -head_d/2+wall+1.2-12, oled_z]) rotate([90,0,0]) translate([-13.6,-14,-1.6]) cube([27.2, 28, 1.6]);
    for (s=[-1,1]) translate([s*(head_w/2 + 22), 0, ear_z]) rotate([0, s*90, 0]) { color([0.6,0.85,1,0.9]) ear_ring(); color(c_acc) translate([0,0,8]) ear_cap(); }
    for (s=[-1,1]) translate([s*(head_w/2 - 8), 0, ear_z]) rotate([0, s*90, 0]) led5();
}
if (step == 5) {
    color(c_acc) body(); hs(); as(1); as(-1);
    translate([0,0,body_h+head_gap+35]) { color(c_new) head_front(); color(c_new) head_back(); color([0.05,0.05,0.07]) face_plate();
        translate([0,0,head_h+22]) { color(c_acc) antenna_stem(); translate([0,0,18]) led5(); color([0.6,0.85,1,0.8]) translate([0,0,30]) antenna_ball(); } }
}
if (step == 6) {
    color(c_w) base_shell();
    translate([0,0,base_h+30]) { color(c_new) body(); }
    for (p=body_pillars) color("red") translate([p[0],p[1],ceil_z-14]) cylinder(d=3, h=12);
}
if (step == 7) {     // floor with the electronics
    color([0.7,0.85,1,0.9]) base_floor();
    color([0.1,0.1,0.1]) translate([0,0,floor_top]) ring(ring16[0]/2, ring16[1]/2, ring16[2]);
    color([0.1,0.4,0.7]) translate([-nano[0]/2, nano_y-nano[1]/2, floor_top+nano_lift]) cube([nano[0], nano[1], 1.6]);
    color([0.2,0.7,0.3]) translate([-bat[0]/2, bat_y-bat[1]/2, floor_top+bat_lift]) { cube([bat[0], bat[1], 3]); translate([6, bat[1]/2, 12.3]) rotate([0,90,0]) cylinder(d=18.6, h=65); }
    color([0.85,0.2,0.2]) translate([-chg[0]/2, chg_y-chg[1]/2, floor_top]) cube([chg[0], chg[1], 1.6]);
}
if (step == 71) {    // shell upside down: sensor + switch
    rotate([180,0,0]) {
        color(c_w) base_shell();
        color(c_new) translate([-sensor_pcb[0]/2+0.5, sensor_y-sensor_pcb[1]/2+0.5, ceil_z-2.8]) cube([sensor_pcb[0]-1, sensor_pcb[1]-1, 1.6]);
        color(c_new) at_wall(sw_a, base_z0+16) translate([0,0,-15]) linear_extrude(16.5) square([sw_hole[1]-0.4, sw_hole[0]-0.4], center=true);
    }
}
if (step == 9) {
    rotate([180,0,0]) { color(c_w) base_shell(); color([0.7,0.85,1,0.9]) translate([0,0,-40]) base_floor();
        for (a=boss_angles) color("red") rotate(a) translate([boss_r_pos,0,-62]) cylinder(d=3, h=12); }
}
if (step == 10) {
    color(c_w) base_shell();
    translate([0,0,base_h]) {
        color(c_acc) body();
        translate([0,0,body_h+head_gap]) { color(c_w) head_front(); color(c_w) head_back(); color([0.05,0.05,0.07]) face_plate(); }
        color(c_new) translate([body_w/2+arm_gap+22, 0, 0]) arm_shape();
        color(c_new) mirror([1,0,0]) translate([body_w/2+arm_gap+22, 0, 0]) arm_shape();
        color(c_ply) translate([0, sign_y-sign_t/2-12, 30]) rotate([90,0,0]) mirror([0,0,1]) linear_extrude(sign_t) sign_2d();
    }
}
