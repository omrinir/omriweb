extends SceneTree
# Spawn analysis. usage: godot --headless --path . -s res://t_spawn.gd -- level seed [dyn_seconds]
# Prints one "STATIC" line (placement at build time) and one "DYN" line (player walks + kills).
var lv := 5
var seed_v := 1
var dyn_s := 90.0
var M: Node = null
var pl: Node = null
var frames := 0
var cp_x := 0.0
var start_x := 0.0
var fy := 630.0
const HALF_W := 512.0   # 1280 / 1.25 / 2
var px := 0.0
var t := 0.0
var kill_cd := 0.0
var samples := 0
var empty := 0
var crowded := 0
var sum_on := 0
var cur_empty := 0.0
var max_empty := 0.0
var first_seen := -1.0
var kills := 0
var unkillable := {}
var hist := {}     # zombie id -> [x, t]
var stuck := {}
var done := false
var finished_t := -1.0
var static_line := ""
const SPEED := 260.0
const KILL_DT := 0.6

var queue := []

func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	dyn_s = float(a[2]) if a.size() > 2 else 90.0
	for l in a[0].split(","):
		for sd in a[1].split(","):
			queue.append([int(l), int(sd)])
	_next()

func _next() -> void:
	if M != null:
		M.queue_free()
		M = null
	if queue.is_empty():
		quit()
		return
	var it = queue.pop_front()
	lv = it[0]
	seed_v = it[1]
	pl = null
	frames = 0
	t = 0.0
	kill_cd = 0.0
	samples = 0
	empty = 0
	crowded = 0
	sum_on = 0
	cur_empty = 0.0
	max_empty = 0.0
	first_seen = -1.0
	kills = 0
	unkillable = {}
	hist = {}
	stuck = {}
	finished_t = -1.0
	Engine.time_scale = 1.0
	paused = false
	var g = root.get_node("Game")
	g.new_run()
	g.start_practice(lv)
	g.level = lv
	g.attempt_seed = seed_v
	for sc in load("res://story/story_db.gd").for_level(lv):
		g.story_seen[sc.id] = true
	M = load("res://main.tscn").instantiate()
	root.add_child(M)

func _zs() -> Array:
	var out := []
	for z in M.get_tree().get_nodes_in_group("zombies"):
		if is_instance_valid(z) and not z.dead and not z.is_boss():
			out.append(z)
	return out

func _in_solid(z: Node) -> bool:
	var ss: PhysicsDirectSpaceState2D = M.get_world_2d().direct_space_state
	var q := PhysicsShapeQueryParameters2D.new()
	var r := RectangleShape2D.new()
	r.size = Vector2(14, 30)
	q.shape = r
	q.transform = Transform2D(0.0, z.global_position + Vector2(0, -22))
	q.collision_mask = 1
	q.collide_with_areas = false
	q.exclude = [z.get_rid()]
	return ss.intersect_shape(q, 1).size() > 0

func _floating(z: Node) -> bool:
	if z.is_on_floor():
		return false
	var ss: PhysicsDirectSpaceState2D = M.get_world_2d().direct_space_state
	var q := PhysicsRayQueryParameters2D.create(z.global_position + Vector2(0, -4), z.global_position + Vector2(0, 40), 1 | 16)
	q.exclude = [z.get_rid()]
	return ss.intersect_ray(q).is_empty()

func _static() -> void:
	var zs := _zs()
	var xs := []
	var n_solid := 0
	var n_haz := 0
	var hz := []
	for h in M.get_tree().get_nodes_in_group("hazards"):
		if h.get("rect") is Rect2:
			hz.append(Rect2(h.global_position + h.rect.position, h.rect.size).grow(8.0))
	var bad := []
	var n_float := 0
	var n_overlap := 0
	var n_start := 0
	var n_cp := 0
	var n_upper := 0
	var skip := 0
	for z in zs:
		xs.append(z.global_position.x)
		if z.global_position.x < start_x + 750.0:
			n_start += 1
		for r in hz:
			if r.has_point(z.global_position + Vector2(0, -4)):
				n_haz += 1
				bad.append("H%d@%d,%d" % [z.kind, int(z.global_position.x), int(z.global_position.y)])
				break
		if absf(z.global_position.x - cp_x) < 220.0:
			n_cp += 1
		if z.global_position.y < fy - 40.0:
			n_upper += 1
		var special: bool = z.on_ceiling or z.kind == 18 or z.kind == 11 or z.kind == 23
		if not special:
			if _in_solid(z):
				n_solid += 1
				bad.append("S%d@%d,%d" % [z.kind, int(z.global_position.x), int(z.global_position.y)])
			if _floating(z):
				n_float += 1
				bad.append("F%d@%d,%d" % [z.kind, int(z.global_position.x), int(z.global_position.y)])
		else:
			skip += 1
	for i in zs.size():
		for j in range(i + 1, zs.size()):
			var d: Vector2 = zs[i].global_position - zs[j].global_position
			if absf(d.x) < 16.0 and absf(d.y) < 30.0:
				n_overlap += 1
	xs.sort()
	var gap := 0.0
	var prev := start_x + 500.0
	for x in xs:
		if x > prev:
			gap = maxf(gap, x - prev)
			prev = x
	gap = maxf(gap, M.level_w - 700.0 - prev)
	# screen windows along the level
	var w_n := 0
	var w_empty := 0
	var w_low := 0
	var w_max := 0
	var w_sum := 0
	var wx := start_x + 600.0
	while wx < M.level_w - 700.0:
		var c := 0
		for x in xs:
			if absf(x - wx) < HALF_W:
				c += 1
		w_n += 1
		w_sum += c
		w_max = maxi(w_max, c)
		if c == 0:
			w_empty += 1
		if c <= 1:
			w_low += 1
		wx += 128.0
	static_line = "STATIC lv %d seed %d n %d | screen mean %.1f max %d empty %.0f%% <=1 %.0f%% | maxgap %d | solid %d float %d overlap %d | start %d cp %d upper %d haz %d" % [
		lv, seed_v, zs.size(), float(w_sum) / maxf(w_n, 1), w_max, 100.0 * w_empty / maxf(w_n, 1), 100.0 * w_low / maxf(w_n, 1), int(gap), n_solid, n_float, n_overlap, n_start, n_cp, n_upper, n_haz]
	print(static_line)
	if not bad.is_empty():
		print("  BAD lv %d: %s" % [lv, str(bad.slice(0, 8))])

func _kill(z: Node) -> void:
	z.take_damage(9999, z.global_position + Vector2(0, -30), Vector2.RIGHT, false, {"source": "bullet", "fixed": 9999})

func _process(delta: float) -> bool:
	if M == null:
		return false
	frames += 1
	if pl == null:
		pl = M.get_tree().get_first_node_in_group("player")
		if pl == null:
			return false
		start_x = pl.global_position.x
		px = start_x
		fy = M._stage.floor_y if M._stage != null else pl.global_position.y
		cp_x = M._checkpoint.position.x
	if frames == 3:
		_static()
		if dyn_s <= 0.0:
			_next()
			return false
	if frames < 4:
		return false
	var dt := 1.0 / 60.0
	t += dt
	pl._invuln = 99.0
	pl.health = pl.max_health
	var zs := _zs()
	var on := []
	for z in zs:
		var p: Vector2 = z.global_position
		if absf(p.x - px) < HALF_W and p.y > fy - 560.0 and p.y < fy + 200.0:
			on.append(z)
	samples += 1
	sum_on += on.size()
	if on.size() == 0:
		empty += 1
		cur_empty += dt
		max_empty = maxf(max_empty, cur_empty)
	else:
		cur_empty = 0.0
		if first_seen < 0.0:
			first_seen = t
	if on.size() > 10:
		crowded += 1
	# stuck: awake, chasing, far-ish from player, not moving for 4 s
	if frames % 30 == 0:
		for z in zs:
			if absf(z.global_position.x - px) > 1300.0 or z.dormant:
				continue
			var id: int = z.get_instance_id()
			var h = hist.get(id)
			if h == null or absf(z.global_position.x - float(h[0])) > 12.0 or absf(z.global_position.y - float(h[2])) > 12.0:
				hist[id] = [z.global_position.x, t, z.global_position.y]
			elif t - float(h[1]) > 4.0 and absf(z.global_position.x - px) > 160.0 and z.get("_chasing"):
				stuck[id] = "%d@%d,%d" % [z.kind, int(z.global_position.x), int(z.global_position.y)]
	# player: shoots the nearest visible zombie; walks when nothing close is awake in front
	kill_cd -= dt
	var near_awake := false
	var best: Node = null
	var bd := 1e9
	for z in on:
		if z.dormant or unkillable.has(z.get_instance_id()):
			continue
		var d: float = absf(z.global_position.x - px)
		if d < bd:
			bd = d
			best = z
		if d < 420.0:
			near_awake = true
	if best != null and kill_cd <= 0.0 and bd < 470.0:
		kill_cd = KILL_DT
		_kill(best)
		if best.dead:
			kills += 1
		else:
			unkillable[best.get_instance_id()] = true
	if not near_awake:
		px += SPEED * dt
	if px > M.level_w - 900.0 and finished_t < 0.0:
		finished_t = t
	pl.global_position = Vector2(px, fy)
	pl.velocity = Vector2.ZERO
	if t >= dyn_s or finished_t > 0.0:
		var sk := []
		for k in stuck:
			sk.append(stuck[k])
		var pace_s := ""
		for c in M.get_children():
			if c.get_script() != null and str(c.get_script().resource_path).ends_with("pace_director.gd"):
				pace_s = " pace_left %d" % c.budget
		print(pace_s)
		print("DYN lv %d seed %d | t %.0fs %s | onscreen mean %.1f empty %.0f%% longest-empty %.1fs >10 %.0f%% | first %.1fs | kills %d | stuck %d %s" % [
			lv, seed_v, t, "DONE" if finished_t > 0.0 else "notdone", float(sum_on) / samples, 100.0 * empty / samples, max_empty,
			100.0 * crowded / samples, first_seen, kills, stuck.size(), str(sk.slice(0, 5))])
		_next()
	return false
