extends SceneTree
# Green mist test (effects/toxic_mist.gd, level 2): the player walks back and forth and shoots while 16 zombies walk in.
# mode "perf [off]": 10 s of frame times (MIST line) + the mist script's own CPU time per frame. "off" removes the mist.
# mode "render [off]": same, but the game is paused at 1.5 s (only the mist keeps moving): pure drawing cost, ON vs OFF.
# mode "shot <png_prefix> [frames...]": saves PNGs (frames counted from the start).
# usage: godot --headless --path . -s res://t_mist.gd -- perf [off]
#        xvfb-run -a -s "-screen 0 1280x720x24" godot --fixed-fps 60 --path . --rendering-driver opengl3 -s res://t_mist.gd -- shot /tmp/mist 150 200
const X := 1500.0
var f := 0
var main_node: Node = null
var mode := "perf"
var off := false
var prefix := ""
var shots := [150, 200, 250]
var keys := {}
var t_prev := 0
var times := []
var cpu0 := 0

func _initialize() -> void:
	var g = root.get_node("Game")
	g.new_run()
	g.level = 2
	main_node = load("res://main.tscn").instantiate()
	root.add_child(main_node)
	current_scene = main_node
	var a := OS.get_cmdline_user_args()
	mode = a[0] if a.size() > 0 else mode
	if mode == "perf" or mode == "render":
		off = a.size() > 1 and a[1] == "off"
	else:
		prefix = a[1] if a.size() > 1 else "/tmp/mist"
		if a.size() > 2:
			shots = []
			for i in range(2, a.size()):
				shots.append(int(a[i]))

func _key(code: int, on: bool) -> void:
	if bool(keys.get(code, false)) == on:
		return
	keys[code] = on
	var e := InputEventKey.new()
	e.physical_keycode = code
	e.keycode = code
	e.pressed = on
	Input.parse_input_event(e)
	Input.flush_buffered_events()

func _process(_d: float) -> bool:
	f += 1
	var now := Time.get_ticks_usec()
	var dt := float(now - t_prev) / 1000.0 if t_prev > 0 else 0.0
	t_prev = now
	var pl = main_node.get_tree().get_first_node_in_group("player")
	if pl == null:
		return false
	pl.health = pl.max_health
	for s in main_node.get_tree().get_nodes_in_group("story_scene"):
		if s.has_method("_finish"):
			s._finish()
	if f == 5:
		pl.global_position.x = X
	if f == 8:
		for z in main_node.get_tree().get_nodes_in_group("zombies"):
			if absf(z.global_position.x - X) < 1600.0 and not z.is_boss():
				z.queue_free()
		if off:
			for m in main_node.get_tree().get_nodes_in_group("toxic_mist"):
				m.queue_free()
	if f == 30:
		for i in 16:
			var side := -1.0 if i % 2 == 0 else 1.0
			var z = main_node._spawn_zombie(X + side * (260.0 + 40.0 * float(i)), pl.global_position.y, [0, 1, 2, 0][i % 4], null)
			z.dormant = false
	if f > 40:   # walk right 1.5 s, left 1.5 s, stop 0.5 s; shoot the whole time
		var ph := (f / 30) % 7
		_key(KEY_D, ph < 3)
		_key(KEY_A, ph >= 3 and ph < 6)
		pl._fire_test = true
	if mode == "shot":
		if f in shots:
			var path := "%s_%d.png" % [prefix, f]
			root.get_viewport().get_texture().get_image().save_png(path)
			print("saved ", path)
		if f >= shots.max():
			quit()
		return false
	if f == 90 and mode == "render":
		paused = true
		for m in main_node.get_tree().get_nodes_in_group("toxic_mist"):
			m.process_mode = Node.PROCESS_MODE_ALWAYS
	if f == 90:
		cpu0 = load("res://effects/toxic_mist.gd").cpu_us
	if f > 90:
		times.append(dt)
	if f >= 90 + 600:
		var cpu: float = float(load("res://effects/toxic_mist.gd").cpu_us - cpu0) / 1000.0 / 600.0
		times.sort()
		var s := 0.0
		for t in times:
			s += t
		print("MIST %s frames=%d avg=%.2fms p95=%.2fms max=%.1fms mist_cpu=%.3fms/frame zombies=%d" % ["OFF" if off else "ON", times.size(), s / times.size(), times[int(times.size() * 0.95)], times[-1], cpu, main_node.get_tree().get_nodes_in_group("zombies").size()])
		quit()
	return false
