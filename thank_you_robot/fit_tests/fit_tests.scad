// Full-size test pieces cut from the real parts: print these first to check
// that your servos, Nano, horns and sign fit before printing the whole robot.
// openscad -D 'part="none"' -D test="arm_servo_pad" -o arm_servo_pad.stl fit_tests.scad
include <../robot.scad>
test = "arm_servo_pad";

module cut(lo, hi) intersection() { children(); translate(lo) cube(hi - lo); }

// 1. side pad of the body: an arm servo slides into the pocket, the boss goes through the wall
if (test == "arm_servo_pad")   rotate([0,90,0]) translate([-body_w/2, 0, 0]) cut([body_w/2-pad_t-0.01, -15, 2], [body_w/2+0.01, 15, body_tt]) body();
// 2. top plate of the body: the head servo pushes up into the cutout, tabs screw underneath
if (test == "head_servo_plate") translate([0,0,body_h]) rotate([180,0,0]) cut([-12, -27, body_tt-3], [12, 14, body_h]) body();
// 3. deck rails: the Nano slides into the grooves
if (test == "nano_rails")       translate([0,0,-shell_z0]) cut([-16, 10, shell_z0-0.01], [16, 57, deck_top+10]) base_deck();
// 4. one sign slot in the base top, plus 5. the matching end of the sign
if (test == "sign_slot")        translate([0,0,base_h]) rotate([180,0,0]) cut([sign_tab_x-11, sign_y-9, ceil_z-9], [sign_tab_x+11, sign_y+9, base_h]) base_shell();
if (test == "sign_tab")         cut([sign_tab_x-14, -10.5, -1], [sign_tab_x+14, 14, sign_t+1]) sign_flat();
// 6. arm shoulder: the single-arm horn presses into the pocket
if (test == "arm_horn")         translate([0,0,arm_t]) rotate([0,90,0]) cut([-1, -14, shoulder_z-26], [arm_t+1, 14, shoulder_z+12]) arm_shape();
// 7. head neck: the head servo's horn presses into the slot under the head
if (test == "head_horn")        cut([-23, -17, -1], [23, head_split, 12]) head_front();
