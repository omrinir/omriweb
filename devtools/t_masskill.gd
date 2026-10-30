extends SceneTree
# MASS KILL perf (test only): spawns N zombies around the player, then kills them (all in one frame, or in a stream)
# and prints frame times for the next seconds. args: level n mode(all|stream) [quality_level -1 = auto]
# MK_HIT env: (empty) explosive kills, "leg" leg shots, "fire" fire kills.
# run headless for CPU cost, or under xvfb with --rendering-driver opengl3 to include drawing.
var lv := 46
var n := 40
var mode := "all"
var qforce := -1
var main_node: Node
var f := 0
var t_prev := 0
var kill_f := 120
var times := []
var zs := []
var peak := 0

func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	lv = int(a[0]) if a.size() > 0 else lv
	n = int(a[1]) if a.size() > 1 else n
	mode = a[2] if a.size() > 2 else mode
	qforce = int(a[3]) if a.size() > 3 else -1
	var g = root.get_node("Game")
	g.new_run()
	g.level = lv
	g.story_seen = {}
	for s in root.get_node("Game").get("story_seen") if false else []:
		pass
	main_node = load("res://main.tscn").instantiate()
	root.add_child(main_node)
	current_scene = main_node

func _process(_d: float) -> bool:
	f += 1
	var now := Time.get_ticks_usec()
	var dt := float(now - t_prev) / 1000.0 if t_prev > 0 else 0.0
	t_prev = now
	var pl = main_node.get_tree().get_first_node_in_group("player")
	if qforce >= 0:
		root.get_node("Quality").level = qforce
	if f == 30 and pl != null:
		for z in main_node.get_tree().get_nodes_in_group("zombies"):   # clear the level's own zombies
			z.queue_free()
		var kinds := [0, 1, 0, 3, 0, 4, 0, 16, 0, 1]
		for i in n:
			var x: float = pl.global_position.x + 120.0 + float(i % 20) * 28.0
			var z = main_node._spawn_zombie(x, pl.global_position.y, kinds[i % kinds.size()])
			z.dormant = false
			zs.append(z)
	if f > 30 and f < kill_f and pl != null:
		pl.health = 99
	if f >= kill_f and pl != null:
		pl.health = 99
		var k: int = n if mode == "all" else 2
		var done := 0
		for z in zs:
			if done >= k:
				break
			if is_instance_valid(z) and not z.dead:
				var hit := OS.get_environment("MK_HIT")   # (empty) explosive, "leg" leg shots, "fire" fire kills
				var hy: float = -8.0 * z.sc if hit == "leg" else -50.0
				z.take_damage(999, z.global_position + Vector2(0, hy), Vector2(1, -0.2), hit == "", {"source": "fire" if hit == "fire" else "bullet", "shot": f, "fixed": 999})
				done += 1
		times.append(dt)
		peak = maxi(peak, _count_particles())
	if f >= kill_f + 240:
		times.sort()
		var s := 0.0
		for t in times:
			s += t
		var over := 0
		for t in times:
			if t > 20.0:
				over += 1
		print("MASSKILL lv=%d n=%d mode=%s q=%d avg=%.1fms p95=%.1fms max=%.1fms over20=%d peak_particles=%d nodes=%d" % [lv, n, mode, root.get_node("Quality").level, s / times.size(), times[int(times.size() * 0.95)], times[-1], over, peak, main_node.get_child_count()])
		quit()
	return false

func _count_particles() -> int:
	var c := 0
	var l = main_node.get_meta("_particle_layer") if main_node.has_meta("_particle_layer") else null
	if l != null and is_instance_valid(l):
		c = l._p.size()
	return c
