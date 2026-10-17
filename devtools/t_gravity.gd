extends SceneTree
# Gravity grenade test: godot --path . -s res://t_gravity.gd -- [level] [shot_prefix]
# Puts 6 zombies around a point, opens a gravity grenade there and checks they get pulled in and killed.
var f := 0
var lv := 12
var shot := ""
var main_node: Node = null
var pl: Node = null
var center := Vector2.ZERO
var zs := []
var d0 := []
var open_frames := 0
var checked := false

func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	lv = int(a[0]) if a.size() > 0 else 12
	shot = a[1] if a.size() > 1 else ""
	var g = root.get_node("Game")
	g.new_run()
	g.level = lv
	g.start_practice(lv)
	g.level = lv
	main_node = load("res://main.tscn").instantiate()
	root.add_child(main_node)
	current_scene = main_node

func _process(_d: float) -> bool:
	f += 1
	if pl == null:
		pl = main_node.get_tree().get_first_node_in_group("player")
		return false
	pl._invuln = 99.0
	if f == 40:
		var all = main_node.get_tree().get_nodes_in_group("zombies").filter(func(z): return not z.dead and not z.is_boss())
		center = pl.global_position + Vector2(330, 0)
		for i in mini(6, all.size()):
			var z = all[i]
			z.global_position = center + Vector2((-1 if i % 2 == 0 else 1) * (110 + 35 * i), -4)
			zs.append(z)
		var gg = load("res://weapons/gravity_grenade.gd").new()
		pl.get_parent().add_child(gg)
		gg.setup(center + Vector2(0, -10), Vector2.ZERO)
		print("zombies placed ", zs.size())
	if f == 41:
		for z in zs:
			d0.append(absf(z.global_position.x - center.x))
	for n in pl.get_parent().get_children():
		if n.has_method("_collapse"):
			open_frames += 1
			if open_frames == 1:
				print("singularity open at frame ", f)
			if n._t >= 1.2 and d0.size() > 0 and not checked:
				checked = true
				if shot != "":
					root.get_viewport().get_texture().get_image().save_png(shot + "_pull.png")
				_check_pull()
	if f == 700:
		var dead := 0
		for z in zs:
			if not is_instance_valid(z) or z.dead:
				dead += 1
		print("KILLED ", dead, "/", zs.size())
		quit()
	return false

func _check_pull() -> void:
	var closer := 0
	for i in zs.size():
		var z = zs[i]
		if not is_instance_valid(z):
			continue
		var d1 := absf(z.global_position.x - center.x)
		print("zombie ", i, " dist ", int(d0[i]), " -> ", int(d1), " dead ", z.dead)
		if d1 < d0[i] - 20.0 or z.dead:
			closer += 1
	print("PULLED ", closer, "/", zs.size())
