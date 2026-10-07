extends SceneTree
var n := 0
var m
var cs
var seed_i := 0
var miny := 9999.0
var t0 := 0
const SEEDS := [11, 222, 3333, 44444, 5555, 66, 777, 8888, 99, 1234]
func _start():
	var g = root.get_node("Game")
	g.level = 1; g.intro_seen = 0; g.use_checkpoint = false; g.practice = false
	g.attempt_seed = SEEDS[seed_i]
	m = load("res://main.tscn").instantiate()
	root.add_child(m)
	cs = null; miny = 9999.0; t0 = n
func _process(_d):
	n += 1
	if n == 4: _start(); return
	if m == null or n < t0 + 3: return
	if cs == null:
		for c in m.get_children():
			if c.get_script() != null and c.get_script().resource_path.ends_with("intro_cutscene.gd"): cs = c
		return
	var p = get_first_node_in_group("player")
	if is_instance_valid(cs) and cs._clock < 12.5:
		miny = minf(miny, p.global_position.y)
		return
	var info := []
	for b in m.get_children():
		if b is StaticBody2D and b.visible and absf(b.global_position.x - p.global_position.x) < 120: info.append([b.name, b.get_script().resource_path.get_file() if b.get_script() else "", int(b.global_position.x)])
	print("seed ", SEEDS[seed_i], " miny=", miny, " x=", int(p.global_position.x), " near=", info)
	m.queue_free(); m = null
	seed_i += 1
	if seed_i >= SEEDS.size(): quit(); return
	t0 = n + 3
	call_deferred("_start")
