// Full-size test pieces cut from the real v4 parts. Print these first.
// openscad -D 'part="none"' -D 'test="arm_servo_pad"' -o arm_servo_pad.stl fit_tests.scad
include <../robot_cute.scad>
test = "arm_servo_pad";
module cut(lo, hi) intersection() { children(); translate(lo) cube(hi - lo); }
// arm servo pocket in the side of the body (servo lies flat, shaft through the wall)
if (test == "arm_servo_pad")    rotate([0,90,0]) translate([-body_w/2, 0, 0]) cut([body_w/2-pad_t-0.01, -22, shoulder_z-11], [body_w/2+0.01, 22, shoulder_z+11]) body();
// top plate of the body: the head servo pushes up into the cutout
if (test == "head_servo_plate") translate([0,0,body_h]) rotate([180,0,0]) cut([-11, -26, body_tt-2], [11, 16, body_h]) body();
// Nano end blocks on the floor
if (test == "nano_blocks")      translate([0,0,-base_z0]) cut([-26, nano_y-14, base_z0-0.01], [26, nano_y+14, floor_top+12]) base_floor();
// hand of the arm: try your 3 mm plywood in the slot and the M2 screw
if (test == "hand_slot")        translate([0,0,arm_t]) rotate([0,90,0]) cut([-1, arm_H[0]-10, arm_H[1]-10], [arm_t+1, arm_H[0]+10, arm_H[1]+10]) arm_shape();
// arm shoulder: the single-arm horn presses into the pocket
if (test == "arm_horn")         translate([0,0,arm_t]) rotate([0,90,0]) cut([-1, arm_shaft_y-13, shoulder_z-13], [arm_t+1, arm_shaft_y+13, shoulder_z+13]) arm_shape();
// head neck: the head servo horn presses into the slot under the head
if (test == "head_horn")        cut([-22, -16, -1], [22, head_split, 11]) head_front();
// charger USB-C opening + switch hole in the back wall
if (test == "back_wall")        rotate([-90,0,0]) translate([0,-base_r,0]) cut([-14, base_r-8, base_z0-0.01], [14, base_r+0.01, base_h-6]) base_shell();
