extends SceneTree
# שימוש: -s res://t_stage.gd -- <level> <x fraction> <tag>
var n := 0
var m
var p
var lv := 5
var xf := 0.0
var tag := "a"
const D := "/tmp/claude-0/-home-user-omriweb/4c84a69a-95cf-51ee-b2a6-c44008e8609a/scratchpad/"
func _initialize():
	var a := OS.get_cmdline_user_args()
	if a.size() > 0: lv = int(a[0])
	if a.size() > 1: xf = float(a[1])
	if a.size() > 2: tag = a[2]
	root.get_node("Game").level = lv
	m = load("res://main.tscn").instantiate()
	root.add_child(m)
func _process(_d):
	n += 1
	if n == 5:
		p = get_first_node_in_group("player")
		if xf > 0.0:
			p.global_position.x = m.level_w * xf
	if n > 5 and p != null:
		p._invuln = 1.0
		p.health = p.max_health
	if n == 240:
		var roles := {}
		var kinds := {}
		for z in get_nodes_in_group("zombies"):
			kinds[z.kind] = kinds.get(z.kind, 0) + 1
			if z.brain != null and not z.dead and absf(z.global_position.x - p.global_position.x) < 900:
				var r: String = z.brain.ROLE_NAMES[z.brain.role]
				roles[r] = roles.get(r, 0) + 1
		var sd = get_first_node_in_group("squad_director")
		print("L", lv, " zombies=", get_nodes_in_group("zombies").size(), " kinds=", kinds)
		print("near roles=", roles, " attackers=", sd.attackers(), " calls=", sd.calls_made, " cmds=", sd.commands_issued, " platforms=", get_nodes_in_group("platforms").size(), " hazards=", get_nodes_in_group("hazards").size())
		root.get_viewport().get_texture().get_image().save_png(D + "st%d_%s.png" % [lv, tag])
		quit()
