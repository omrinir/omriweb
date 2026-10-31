extends SceneTree
# THREAT ARROWS (test only): ui/threat_arrows.gd. The level's zombies are removed, then a few zombies of one kind are
# spawned off screen behind the player (left) and told where the player is. Prints the arrows while they come in,
# and when each one enters the screen. A slow walker far away should get no arrow until it is close.
# usage: godot --headless --fixed-fps 60 --path . -s res://t_arrows.gd -- [level 55] [kind 1] [count 2] [distance 950]
# picture (window under xvfb): env ARROW_SHOT=/tmp/arrows.png -> saved when an arrow is stronger than ARROW_K (default 0.55)
var lv := 55
var kind := 1
var count := 2
var dist := 950.0
var main_node: Node
var pl: Node
var arrows: Node = null
var f := 0
var zs := []
var t0 := -1
var best := 0.0
var shot_done := false
var entered := {}


func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	lv = int(a[0]) if a.size() > 0 else lv
	kind = int(a[1]) if a.size() > 1 else kind
	count = int(a[2]) if a.size() > 2 else count
	dist = float(a[3]) if a.size() > 3 else dist
	var g = root.get_node("Game")
	g.new_run()
	g.level = lv
	main_node = load("res://main.tscn").instantiate()
	root.add_child(main_node)
	current_scene = main_node


func _process(_d: float) -> bool:
	f += 1
	pl = main_node.get_tree().get_first_node_in_group("player")
	if pl == null:
		return false
	pl.health = pl.max_health
	if "_invuln" in pl:
		pl._invuln = 1.0
	for s in main_node.get_tree().get_nodes_in_group("story_scene"):
		if s.has_method("_finish"):
			s._finish()
	if arrows == null:
		for n in main_node.get_children():
			if n.get_script() == load("res://ui/threat_arrows.gd"):
				arrows = n
	if f < 300 and f % 10 == 0:
		for z in main_node.get_tree().get_nodes_in_group("zombies"):
			z.queue_free()
	if f == 300:
		pl.global_position.x += 1200.0   # שיהיה מקום מאחור
		pl.reset_physics_interpolation()
	if f == 330:
		for i in count:
			var z = main_node._spawn_zombie(pl.global_position.x - dist - 90.0 * float(i), pl.global_position.y, kind)
			if z != null:
				z.dormant = false
				z._alert_t = 30.0
				zs.append(z)
		t0 = f
		print("ARROWS spawned %d x kind %d at %.0f px behind the player (screen half width %.0f)" % [zs.size(), kind, dist,
			main_node.get_viewport_rect().size.x * 0.5 / float(main_node.camera_zoom)])
	if t0 > 0:
		var ct := root.get_viewport().get_canvas_transform()
		var vp: Vector2 = main_node.get_viewport_rect().size
		for z in zs:
			if not is_instance_valid(z) or entered.has(z.get_instance_id()):
				continue
			var sp: Vector2 = ct * (z.global_position + Vector2(0.0, -40.0))
			if sp.x > -6.0 and sp.x < vp.x + 6.0:
				entered[z.get_instance_id()] = f
				print("ARROWS   zombie entered the screen at t=%.2f s" % (float(f - t0) / 60.0))
		if (f - t0) % 15 == 0:
			var desc := []
			for m in arrows._marks.values():
				desc.append("at=%s k=%.2f a=%.2f" % [(m[0] as Vector2).round(), m[2], m[3]])
				if m[2] * m[3] > best:
					best = m[2] * m[3]
			var d := -1.0
			if zs.size() > 0 and is_instance_valid(zs[0]):
				d = absf(zs[0].global_position.x - pl.global_position.x)
			print("ARROWS t=%.2f s  first zombie %.0f px away  arrows %d %s" % [float(f - t0) / 60.0, d, arrows._marks.size(), " | ".join(desc)])
		if OS.get_environment("ARROW_SHOT") != "" and not shot_done:
			for m in arrows._marks.values():
				if m[2] > float(OS.get_environment("ARROW_K") if OS.get_environment("ARROW_K") != "" else "0.55") and m[3] > 0.95:
					root.get_viewport().get_texture().get_image().save_png(OS.get_environment("ARROW_SHOT"))
					print("ARROWS saved ", OS.get_environment("ARROW_SHOT"))
					shot_done = true
					break
		if f - t0 > 60 * 12 or entered.size() >= zs.size() and f - t0 > 30 and arrows._marks.is_empty():
			print("ARROWS done (strongest k*alpha %.2f)" % best)
			quit()
	return false
