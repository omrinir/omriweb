extends SceneTree
# MINIGUN / MASS-KILL perf (test only): the player holds the trigger of a gun into a steady crowd on a level and the
# script prints frame times (avg, p95, worst, frames over 16.7 / 33 ms) and kills. Run headless for the CPU cost.
# usage: godot --headless --fixed-fps 60 --path . -s res://devtools/t_minigun.gd -- [level 55] [weapon_db id 21 = MINIGUN] [seconds 10] [zombies per wave 4]
# env: MG_KINDS=0,0,1,176 (zombie kinds to spawn, picked at random; default = roughly the level 55 mix),
#      MG_Q=<quality level forced, default -1 = the game's own governor>, MG_NOFIRE=1 (crowd only, nobody shoots = baseline),
#      MG_AIR=1 (with 0 zombies per wave: shoots into the air = what the gun itself costs),
#      MG_PROF=1 (with -d --profiling < /dev/null: busy-waits 1.05 s in frames 300/450/600 so the profiler prints exactly those frames)
#      MG_SHOT=300,/tmp/mg.png (with a window, not --headless: saves a picture of that frame - blood, HUD, bodies)
var lv := 55
var weapon := 21
var secs := 10.0
var per_wave := 4
var kinds := [0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 176, 177, 178]
var main_node: Node
var pl: Node
var f := 0
var t_prev := 0
var times := []
var kills := 0
var rng := RandomNumberGenerator.new()
const START := 90          # the shooting starts (frames)
const WAVE_EVERY := 30


func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	lv = int(a[0]) if a.size() > 0 else lv
	weapon = int(a[1]) if a.size() > 1 else weapon
	secs = float(a[2]) if a.size() > 2 else secs
	per_wave = int(a[3]) if a.size() > 3 else per_wave
	if OS.get_environment("MG_KINDS") != "":
		kinds.clear()
		for s in OS.get_environment("MG_KINDS").split(","):
			kinds.append(int(s))
	rng.seed = 7
	var g = root.get_node("Game")
	g.new_run()
	g.level = lv
	main_node = load("res://main.tscn").instantiate()
	root.add_child(main_node)
	current_scene = main_node


func _process(_d: float) -> bool:
	var now := Time.get_ticks_usec()
	var ms := float(now - t_prev) / 1000.0 if t_prev > 0 else 0.0
	t_prev = now
	f += 1
	if OS.get_environment("MG_Q") != "":
		root.get_node("Quality").level = int(OS.get_environment("MG_Q"))
	pl = main_node.get_tree().get_first_node_in_group("player")
	if pl == null:
		return false
	pl.health = pl.max_health
	for s in main_node.get_tree().get_nodes_in_group("story_scene"):
		if s.has_method("_finish"):
			s._finish()
	if f == 3:
		pl.slots[0] = {"id": weapon, "ammo": 999, "mag": 999}
		pl.select_slot(0)
	if f == 60:   # the level's own zombies away: only the test crowd
		for z in main_node.get_tree().get_nodes_in_group("zombies"):
			z.queue_free()
	if f >= START and (f - START) % WAVE_EVERY == 0 and f < START + int(secs * 60.0):
		var fy: float = pl.global_position.y
		for i in per_wave:
			var z = main_node._spawn_zombie(pl.global_position.x + 480.0 + float(i) * 34.0 + rng.randf_range(0.0, 20.0), fy, kinds[rng.randi() % kinds.size()])
			if z != null:
				z.dormant = false
	if f > START:
		if pl.slots.size() > 0 and pl.slots[0] is Dictionary:
			pl.slots[0]["mag"] = 999
			pl.slots[0]["ammo"] = 999
		var tgt = null
		var best := INF
		for z in main_node.get_tree().get_nodes_in_group("zombies"):
			if z.dead:
				continue
			var d: float = absf(z.global_position.x - pl.global_position.x)
			if d < best:
				best = d
				tgt = z
		if tgt == null and OS.get_environment("MG_AIR") != "":   # nobody there: shoots straight ahead (the gun's own cost)
			pl._aim = Vector2(1.0, 0.0).rotated(pl._face() * pl._kick)
			pl._fire_test = true
		if tgt != null:
			var sh: Vector2 = pl.global_position + pl._front_shoulder()
			var want: Vector2 = (tgt.global_position + Vector2(0.0, -30.0 * float(tgt.sc)) - sh).normalized()
			pl._aim = want.rotated(pl._face() * pl._kick)   # like a player: pulls the climbing barrel back down
			if OS.get_environment("MG_NOFIRE") == "" and best < 700.0:
				pl._fire_test = true
		if OS.get_environment("MG_PROF") != "" and f in [300, 450, 600]:
			print("MG SAMPLE f=%d (next FRAME block = this frame)" % f)
			var tw := Time.get_ticks_usec()
			while Time.get_ticks_usec() - tw < 1050000:
				pass
			ms = 0.0
		if OS.get_environment("MG_SHOT") != "" and f == int(OS.get_environment("MG_SHOT").split(",")[0]):
			root.get_viewport().get_texture().get_image().save_png(OS.get_environment("MG_SHOT").split(",")[1])
		if f > START + 30 and ms > 0.0:
			times.append(ms)
		if ms > 60.0 and OS.get_environment("MG_SPIKE") != "":
			print("MG spike f=%d %.1f ms" % [f, ms])
	if f == START + int(secs * 60.0) + 30:
		times.sort()
		var s := 0.0
		var o16 := 0
		var o33 := 0
		for t in times:
			s += t
			if t > 16.7:
				o16 += 1
			if t > 33.3:
				o33 += 1
		var alive := 0
		for z in main_node.get_tree().get_nodes_in_group("zombies"):
			if not z.dead:
				alive += 1
		kills = int(root.get_node("Game").stats.kills)
		print("MG lv=%d weapon=%d %s q=%d | avg %.1f ms p50 %.1f p95 %.1f p99 %.1f worst %.1f | over16.7 %d over33 %d of %d | kills %d alive %d nodes %d" % [lv, weapon,
			"NOFIRE" if OS.get_environment("MG_NOFIRE") != "" else "fire", root.get_node("Quality").level, s / times.size(), times[times.size() / 2],
			times[int(times.size() * 0.95)], times[int(times.size() * 0.99)], times[-1], o16, o33, times.size(), kills, alive, main_node.get_child_count()])
		quit()
	return false
