extends SceneTree
# Explosion test (explosion.gd): level 3, clears the zombies around the player, then sets off explosions.
# mode "perf": 1 blast, then 4 at once, then one every 10 frames for 3 s; prints frame times (BOOM line).
# mode "shot": one blast (BOOM_STYLE env = 0/1/2 forces a style) and saves PNGs at the given frames after it.
# usage: godot --headless --path . -s res://t_boom.gd -- perf [quality_level]
#        xvfb-run -a -s "-screen 0 1280x720x24" godot --fixed-fps 60 --path . --rendering-driver opengl3 -s res://t_boom.gd -- shot <png_prefix> [frames...]
const LV := 3
var f := 0
var main_node: Node = null
var mode := "perf"
var prefix := ""
var shots := [4, 10, 20, 35, 60]
var qforce := 0
var t_prev := 0
var times := []
var air := false

func _initialize() -> void:
	var g = root.get_node("Game")
	g.new_run()
	g.level = LV
	main_node = load("res://main.tscn").instantiate()
	root.add_child(main_node)
	current_scene = main_node
	var a := OS.get_cmdline_user_args()
	mode = a[0] if a.size() > 0 else mode
	if mode == "perf":
		qforce = int(a[1]) if a.size() > 1 else 0
	else:
		prefix = a[1] if a.size() > 1 else "/tmp/boom"
		if a.size() > 2:
			shots = []
			for i in range(2, a.size()):
				shots.append(int(a[i]))
	air = OS.get_environment("BOOM_AIR") != ""

func _boom(dx: float) -> void:
	var pl = main_node.get_tree().get_first_node_in_group("player")
	var at: Vector2 = pl.global_position + Vector2(dx, -60.0 if air else -4.0)
	load("res://explosion.gd").blast(main_node, at, 130.0, 60.0, 0, 0, "test")

func _process(_d: float) -> bool:
	f += 1
	var now := Time.get_ticks_usec()
	var dt := float(now - t_prev) / 1000.0 if t_prev > 0 else 0.0
	t_prev = now
	var pl = main_node.get_tree().get_first_node_in_group("player")
	if pl == null:
		return false
	pl.health = pl.max_health
	root.get_node("Quality").level = qforce
	for s in main_node.get_tree().get_nodes_in_group("story_scene"):
		if s.has_method("_finish"):
			s._finish()
	if f == 5:
		pl.global_position.x = 5600.0
	if f == 8:
		for z in main_node.get_tree().get_nodes_in_group("zombies"):
			if absf(z.global_position.x - 5600.0) < 1400.0 and not z.is_boss():
				z.queue_free()
	if mode == "shot":
		if f == 60:
			_boom(160.0)
		if f > 60 and (f - 60) in shots:
			var path := "%s_%d.png" % [prefix, f - 60]
			root.get_viewport().get_texture().get_image().save_png(path)
			print("saved ", path)
		if f >= 60 + 130:
			quit()
		return false
	if f == 60:
		_boom(150.0)
	if f == 120:
		for i in 4:
			_boom(-260.0 + 170.0 * i)
	if f >= 180 and f < 360 and f % 10 == 0:
		_boom(randf_range(-300.0, 300.0))
	if f >= 60:
		times.append(dt)
		if dt > 90.0:
			print("slow frame f=%d %.1fms" % [f, dt])
	if f >= 480:
		times.sort()
		var s := 0.0
		for t in times:
			s += t
		print("BOOM q=%d frames=%d avg=%.2fms p95=%.2fms max=%.1fms nodes=%d" % [qforce, times.size(), s / times.size(), times[int(times.size() * 0.95)], times[-1], main_node.get_child_count()])
		quit()
	return false
