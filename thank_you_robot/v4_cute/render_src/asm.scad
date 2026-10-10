include </home/user/omriweb/thank_you_robot/v4_cute/robot_cute.scad>
which = "";
hz = base_h + body_h + head_gap;
if (which == "base_floor") base_floor();
if (which == "base_shell") base_shell();
if (which == "body") translate([0,0,base_h]) body();
if (which == "arm_r") translate([0,0,base_h]) translate([body_w/2+arm_gap,0,0]) arm_shape();
if (which == "arm_l") translate([0,0,base_h]) mirror([1,0,0]) translate([body_w/2+arm_gap,0,0]) arm_shape();
if (which == "sign") translate([0,0,base_h]) translate([0, sign_y-sign_t/2, 0]) rotate([90,0,0]) mirror([0,0,1]) sign_flat();
if (which == "head") translate([0,0,hz]) { head_front(); head_back(); }
if (which == "face") translate([0,0,hz]) face_plate();
if (which == "cheeks") translate([0,0,hz]) for (x=[-cheek_x, cheek_x]) translate([x, -head_d/2+0.2, cheek_z]) rotate([90,0,0]) cheek();
if (which == "ear_rings") translate([0,0,hz]) for (s=[-1,1]) translate([s*head_w/2, 0, ear_z]) rotate([0, s*90, 0]) ear_ring();
if (which == "ear_caps") translate([0,0,hz]) for (s=[-1,1]) translate([s*head_w/2, 0, ear_z]) rotate([0, s*90, 0]) translate([0,0,2]) ear_cap();
if (which == "ant_stem") translate([0,0,hz+head_h]) antenna_stem();
if (which == "ant_ball") translate([0,0,hz+head_h+5.5]) antenna_ball();
