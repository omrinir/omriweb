extends SceneTree
# SPIRIT TIGER test (effects/spirit_tiger.gd) on level 20: 6 zombies around the player, the player uses the item on frame USE_F.
# Prints the tiger's state changes, kills, and frame times while it is alive. TIGER_OFF=1: same scene without the tiger (frame-time baseline).
# usage: godot --headless --fixed-fps 60 --path . -s res://t_tiger.gd
#        xvfb-run -a -s "-screen 0 1280x720x24" godot --fixed-fps 60 --path . --rendering-driver opengl3 -s res://t_tiger.gd -- <png_prefix> [zoom] [frames...]
const X := 2600.0
const USE_F := 60
const OFFS := [260.0, 420.0, 600.0, 760.0, -380.0, -620.0]
var f := 0
var main_node: Node = null
var prefix := ""
var zoom := 1.7
var shots := []
var max_f := 900
var tiger: Node = null
var last_state := -1
var t_prev := 0
var times := []
var off := false

func _initialize() -> void:
	var g = root.get_node("Game")
	g.new_run()
	g.level = 20
	main_node = load("res://main.tscn").instantiate()
	root.add_child(main_node)
	current_scene = main_node
	off = OS.get_environment("TIGER_OFF") != ""
	var a := OS.get_cmdline_user_args()
	if a.size() > 0:
		prefix = a[0]
	if a.size() > 1:
		zoom = float(a[1])
	for i in range(2, a.size()):
		shots.append(int(a[i]))
	if not shots.is_empty():
		max_f = shots.max() + 1

func _process(_d: float) -> bool:
	var now := Time.get_ticks_usec()
	if f > USE_F and f < USE_F + 400:
		times.append(float(now - t_prev) / 1000.0)
	t_prev = now
	return false

func _physics_process(_d: float) -> bool:
	f += 1
	var pl = main_node.get_tree().get_first_node_in_group("player")
	if pl == null:
		return false
	pl.health = pl.max_health
	pl._invuln = 99.0
	if f == 5:
		pl.global_position.x = X
	for s in main_node.get_tree().get_nodes_in_group("story_scene"):
		if s.has_method("_finish"):
			s._finish()
	if f % 20 == 1:
		for n in main_node.find_children("*", "CanvasLayer", true, false):
			if n.layer >= 2:
				n.visible = false
	if f == 20:
		for o in main_node.get_tree().get_nodes_in_group("zombies"):
			if absf(o.global_position.x - X) < 2200.0:
				o.queue_free()
	if f == 30:
		for dx in OFFS:
			var z = main_node._spawn_zombie(X + dx, pl.global_position.y, 0, null)
			z.dormant = false
	if f == USE_F and not off:
		pl.take_special("tiger")
		pl.use_item()
		for c in main_node.get_children():
			if c.get_script() != null and str(c.get_script().resource_path).ends_with("spirit_tiger.gd"):
				tiger = c
		print("TIGER used: node=%s special_left='%s' uses=%d" % [str(tiger), pl.special, pl.special_uses])
	if tiger != null and is_instance_valid(tiger):
		if tiger.state != last_state:
			last_state = tiger.state
			print("TIGER f=%d state=%d pos=%s kills=%d flames=%d" % [f, tiger.state, str(tiger.pos.round()), tiger.kills, tiger._flames.size()])
	elif tiger != null and last_state != 99:
		last_state = 99
		print("TIGER gone f=%d" % f)
	if prefix != "":
		var cam := main_node.get_viewport().get_camera_2d()
		if cam != null and "_base_zoom" in cam:
			cam._base_zoom = Vector2(zoom, zoom)
			cam.zoom = cam._base_zoom
			if tiger != null and is_instance_valid(tiger):
				cam.base_offset = (tiger.pos - pl.global_position) * 0.5 + Vector2(0, -40)
		if f in shots:
			var img := root.get_viewport().get_texture().get_image()
			img.save_png("%s_%03d.png" % [prefix, f])
	if f >= max_f or (tiger != null and last_state == 99 and f > USE_F + 30 and prefix == ""):
		var alive := 0
		for o in main_node.get_tree().get_nodes_in_group("zombies"):
			if not o.dead and absf(o.global_position.x - X) < 1500.0:
				alive += 1
		times.sort()
		var avg := 0.0
		for t in times:
			avg += t
		avg /= maxf(times.size(), 1)
		print("TIGER RESULT kills=%s zombies_left_near=%d frames: avg=%.1fms p95=%.1fms worst=%.1fms" % [str(tiger.kills_log) if tiger != null and is_instance_valid(tiger) else "(freed)", alive, avg, times[int(times.size() * 0.95)] if times.size() > 0 else 0.0, times[-1] if times.size() > 0 else 0.0])
		quit()
	return false
