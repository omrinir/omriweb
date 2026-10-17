extends SceneTree
# AUTOPLAY BOT (test only, not part of the game)
# usage: godot --headless --fixed-fps 60 --path . -s res://t_bot.gd -- <level> <god 1/0> <max_sec> [shot_prefix]
var UpgradesS = null
var slow_list := []
var lv := 1
var god := true
var max_frames := 21600
var shot := ""
var start_x := 0.0
var shot_done := false
var dumped := 0
var main_node: Node
var pl: Node
var f := 0
var keys := {}
var key_queue := []          # [[code, on], ...] one op per frame
var run_cool := 0
var jump_hold := 0
var want_jump2 := false
# measurements
var t_prev := 0
var slow := 0
var worst := 0.0
var sum_ms := 0.0
var nms := 0
var best_x := 0.0
var best_x_f := 0
var stuck_eps := []          # dicts
var cur_stuck = null
var teleports := 0
var story_frames := 0
var story_max := 0
var story_cur := 0
var refills := 0
var dmg_taken := 0
var max_hp := 10
const BIG_HP := 100000
var deaths_at := []
var hp_acc := 0
var zflags := {}             # "kind:flag" -> count
var zseen := {}              # instance_id -> {flag: frames}
var boss: Node = null
var boss_name := ""
var boss_seen_f := -1
var boss_dead_f := -1
var exit_node: Node = null
var near_exit_f := -1
var kills0 := 0
var spec_cd := 0
var spec_used := 0
var spec_back := false
var barrier_f := 0
var barrier_eps := 0
var barrier_was := false
var ev := []                 # misc events
var back_off := 0
var ladder_go = null
var climb_hold := 0
var drop_try := 0
var floor_y := 0.0
var under := 0.0
var finished_f := -1
var pick_checked := false
var last_x := 0.0
var shots := 0
var specials_seen := {}
var boss_hp_last := -1
var boss_hp_f := 0
var gate_passed := false
var cur_t := [null, Vector2.ZERO, 0.0, 0]
var no_t_f := 0

func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	lv = int(a[0]) if a.size() > 0 else 1
	god = (a[1] != "0") if a.size() > 1 else true
	max_frames = int(float(a[2]) * 60.0) if a.size() > 2 else 21600
	start_x = float(a[3]) if a.size() > 3 else 0.0
	shot = a[4] if a.size() > 4 else ""
	var g = root.get_node("Game")
	g.new_run()
	g.start_practice(lv)
	g.level = lv
	var sd := OS.get_environment("BOT_SEED")
	g.attempt_seed = int(sd) if sd != "" else 1000 + lv * 7
	seed(g.attempt_seed)
	main_node = load("res://main.tscn").instantiate()
	root.add_child(main_node)
	current_scene = main_node
	t_prev = Time.get_ticks_usec()
	UpgradesS = load("res://progression/upgrade_db.gd")

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

func _release_all() -> void:
	for k in keys.keys():
		_key(k, false)
	key_queue.clear()

func _ray(a: Vector2, b: Vector2, mask: int) -> Dictionary:
	var q := PhysicsRayQueryParameters2D.create(a, b, mask)
	q.collide_with_areas = false
	return pl.get_world_2d().direct_space_state.intersect_ray(q)

func _desc(c: Object) -> String:
	if c == null:
		return "none"
	var s := str(c.get_class())
	var n = c
	# StaticBody child of a scripted node: describe the owner
	if c is Node and c.get_script() == null and c.get_parent() != null and c.get_parent().get_script() != null:
		n = c.get_parent()
	if n.get_script() != null:
		s += "<" + str(n.get_script().resource_path.get_file()) + ">"
	if n is Node:
		s += "@" + str(Vector2(n.global_position).round()) if n is Node2D else ""
		if "size" in n:
			s += " size=" + str(n.size)
	return s

func _physics_process(_d: float) -> bool:
	f += 1
	if pl == null:
		pl = main_node.get_tree().get_first_node_in_group("player")
		if pl == null:
			return false
		max_hp = pl.max_health
		floor_y = float(pl.get_meta("ground_y", 600.0))
		if main_node._stage != null:
			under = main_node._stage.underground_depth()
		exit_node = main_node.get_tree().get_first_node_in_group("level_exit")
		best_x = pl.global_position.x
		if start_x > 0.0:
			pl.global_position.x = start_x
			best_x = start_x
		kills0 = int(root.get_node("Game").get("kills")) if "kills" in root.get_node("Game") else 0
	if main_node._finished:
		if finished_f < 0:
			finished_f = f
			_release_all()
		return false
	# ---- HP / cheats ----
	if god:
		pl._invuln = 99.0
		if pl.health < pl.max_health:
			pl.health = pl.max_health
	else:
		if f == 2:
			pl.health = BIG_HP
		if pl.health < BIG_HP and f > 2:
			var lost: int = BIG_HP - pl.health
			if lost <= 20:   # a real hit (a bigger drop = something reset health to max: heal / drain)
				hp_acc += lost
				dmg_taken += lost
			pl.health = BIG_HP
			while hp_acc >= max_hp:
				hp_acc -= max_hp
				deaths_at.append(int(pl.global_position.x))
	if pl.dead:
		ev.append("player DEAD at x=%d f=%d" % [pl.global_position.x, f])
		pl.dead = false
		pl.health = pl.max_health if god else BIG_HP
	# ---- boss ----
	if boss == null or not is_instance_valid(boss):
		if boss_seen_f >= 0 and boss_dead_f < 0 and (exit_node == null or exit_node.locked):
			pass
		if f % 30 == 0 and boss_dead_f < 0:
			for z in main_node.get_tree().get_nodes_in_group("zombies"):
				if not z.dead and z.is_boss():
					boss = z
					if boss_seen_f < 0:
						boss_seen_f = f
						boss_name = str(z.type_mod.stats().name) if z.type_mod != null else "kind" + str(z.kind)
					break
	if exit_node != null and is_instance_valid(exit_node) and not exit_node.locked and boss_dead_f < 0:
		boss_dead_f = f
	# ---- story scene ----
	var in_story: bool = not pl.controllable or not main_node.get_tree().get_nodes_in_group("story_scene").is_empty()
	if in_story:
		story_frames += 1
		story_cur += 1
		story_max = maxi(story_max, story_cur)
		_release_all()
		if story_cur == 60 * 90:
			ev.append("STORY HANG >90s at x=%d - forcing finish" % pl.global_position.x)
			for s in main_node.get_tree().get_nodes_in_group("story_scene"):
				if s.has_method("_finish"):
					s._finish()
		return false
	story_cur = 0
	_zombie_checks()
	if f == 90 and not pick_checked:
		pick_checked = true
		_pickup_checks()
	if not god:
		pass
	cur_t = _target()
	if cur_t[0] != null:
		no_t_f = f
	_fight()
	_move()
	if f >= max_frames:
		_report_and_quit("TIMEOUT")
	return false

func _process(_d: float) -> bool:
	var now := Time.get_ticks_usec()
	var ms := float(now - t_prev) / 1000.0
	t_prev = now
	if f > 120 and not main_node._finished:
		sum_ms += ms
		nms += 1
		worst = maxf(worst, ms)
		if ms > 25.0:
			slow += 1
			if slow_list.size() < 12 and pl != null:
				slow_list.append("f%d x%d %.0fms z%d" % [f, pl.global_position.x, ms, main_node.get_tree().get_nodes_in_group("zombies").size()])
	if finished_f > 0 and f > finished_f + 30:
		_report_and_quit("FINISHED")
	return false

# ============ fighting ============
func _target() -> Array:
	var sh: Vector2 = pl.global_position + pl._front_shoulder()
	var best = null
	var bd := 1e9
	var bp := Vector2.ZERO
	var near := 0
	for z in main_node.get_tree().get_nodes_in_group("zombies"):
		if z.dead or not is_instance_valid(z):
			continue
		if (z.collision_layer & 4) == 0:
			continue
		if z.type_mod != null and z.type_mod.get("scripted") == true:
			continue
		var d: Vector2 = z.global_position - pl.global_position
		if absf(d.x) > 680.0 or absf(d.y) > 420.0:
			continue
		var sc: float = z.sc
		var aimp: Vector2 = z.global_position + Vector2(0, -54.0 * sc)
		if z.dormant or z._lying():
			aimp = z.global_position + Vector2(0, -8.0 * sc)
		elif z.on_ceiling:
			aimp = z.global_position + Vector2(0, 50.0 * sc)
		var hit := _ray(sh, aimp, 1)
		if not hit.is_empty():
			# head blocked: try the body
			aimp = z.global_position + Vector2(0, -30.0 * sc)
			hit = _ray(sh, aimp, 1)
			if not hit.is_empty():
				continue
		var dist := sh.distance_to(aimp)
		if dist < 480.0:
			near += 1
		if z.is_boss():
			dist *= 0.7
		if dist < bd:
			bd = dist
			best = z
			bp = aimp
	return [best, bp, bd, near]

func _fight() -> void:
	if spec_back:
		spec_back = false
		if pl.weapon != 0:
			pl.weapon = 0
			pl.weapon_changed.emit(0)
	spec_cd -= 1
	var t: Array = cur_t
	var z = t[0]
	if pl.special != "":
		specials_seen[pl.special] = true
	# ammo
	if pl.weapon == 0 and pl.ammo <= 0:
		var found := false
		for i in pl.slots.size():
			var s = pl.slots[i]
			if s != null and int(s.ammo) > 0:
				pl.select_slot(i)
				found = true
				break
		if not found:
			if god:
				pl._ammo_box(2)
				refills += 1
			elif f % 600 == 0:
				ev.append("OUT OF AMMO x=%d" % pl.global_position.x)
	if z == null:
		var w: Dictionary = UpgradesS.weapon_def(pl.gun)
		var ms: int = int(w.get("magazine_size", 0))
		if ms > 0 and pl.mag < ms / 2 and pl.ammo > pl.mag:
			pl.reload()
		return
	var sh: Vector2 = pl.global_position + pl._front_shoulder()
	var dir: Vector2 = (t[1] - sh).normalized()
	# special: crowd or boss
	if pl.special in ["grenade", "gravity", "molotov", "launcher", "rocket"] and spec_cd <= 0 and (t[3] >= 3 or z.is_boss()) and float(t[2]) > 150.0:
		spec_cd = 240
		spec_used += 1
		pl._aim = (dir + Vector2(0, -0.25)).normalized()
		pl.use_item()   # C on the item in the POWERS bar
		return
	if pl.special == "laser" and spec_cd <= 0 and (t[3] >= 3 or z.is_boss()):
		pl._aim = dir
		if pl.use_item():
			spec_cd = 300
		return
	pl._aim = dir
	pl._fire_test = true
	shots += 1

# ============ movement ============
func _move() -> void:
	if not key_queue.is_empty():
		var op = key_queue.pop_front()
		_key(op[0], op[1])
		return
	var x: float = pl.global_position.x
	var on_floor: bool = pl.is_on_floor()
	if x > best_x + 40.0:
		best_x = x
		best_x_f = f
		if cur_stuck != null:
			cur_stuck.dur = float(f - cur_stuck.f0) / 60.0
			stuck_eps.append(cur_stuck)
			cur_stuck = null
		back_off = 0
		ladder_go = null
		drop_try = 0
	var bar = _barrier()
	var bar_on: bool = bar != null
	if bar_on and not barrier_was:
		barrier_eps += 1
	barrier_was = bar_on
	if bar_on:
		barrier_f += 1
		if bar._age > 15.0 and not bar.has_meta("bot_logged"):
			bar.set_meta("bot_logged", true)
			var info := []
			for lz in bar._locked:
				if is_instance_valid(lz) and not lz.dead:
					var nm: String = str(lz.type_mod.stats().name) if lz.type_mod != null else "k" + str(lz.kind)
					var vis := _ray(pl.global_position + Vector2(0, -40), lz.global_position + Vector2(0, -30.0 * lz.sc), 1).is_empty()
					info.append("%s@%s d=%d vis=%s lay=%d dorm=%s v=%s" % [nm, str(lz.global_position.round()), lz.global_position.distance_to(pl.global_position), str(vis), lz.collision_layer, str(lz.dormant), str(lz.velocity.round())])
			ev.append("BARRIER >15s at x=%d locked=%d: %s" % [x, info.size(), str(info)])
	var exit_wait: bool = exit_node != null and is_instance_valid(exit_node) and exit_node.locked and x > exit_node.global_position.x - 400.0
	if exit_wait and near_exit_f < 0:
		near_exit_f = f
	var stall := float(f - best_x_f) / 60.0
	if bar_on or exit_wait:
		best_x_f = f   # waiting on purpose (fight), not stuck
		stall = 0.0
	# --- stuck episode bookkeeping ---
	if stall > 3.0 and cur_stuck == null:
		var blk := _ray(pl.global_position + Vector2(0, -30), pl.global_position + Vector2(90, -30), 1 | 512)
		var blk2 := _ray(pl.global_position + Vector2(0, -150), pl.global_position + Vector2(90, -150), 1 | 512)
		if shot != "" and not shot_done:
			shot_done = true
			root.get_viewport().get_texture().get_image().save_png(shot)
			print("SHOT saved ", shot, " at x=", x)
		cur_stuck = {"x": int(x), "y": int(pl.global_position.y), "f0": f - 180, "blk": _desc(blk.get("collider")), "blk_hi": _desc(blk2.get("collider")), "dur": 0.0, "tp": false, "floor": on_floor, "climb": pl._climbing}
	var want := 1.0
	var no_ammo := true
	for sl in pl.slots:
		if sl != null and int(sl.ammo) > 0:
			no_ammo = false
	if not god and not no_ammo:
		var z = cur_t[0]
		if z != null:
			var dx: float = z.global_position.x - x
			if dx > 0.0 and dx < 170.0:
				want = -1.0
			elif dx > 0.0 and dx < 360.0:
				want = 0.0
	if bar_on:
		want = 0.0
		if cur_t[0] == null:   # nothing visible: go back to the zombies the wall waits for
			var nd := 1e9
			for lz in bar._locked:
				if is_instance_valid(lz) and not lz.dead and absf(lz.global_position.x - x) < nd:
					nd = absf(lz.global_position.x - x)
					want = signf(lz.global_position.x - x)
			if nd < 120.0:
				want = 0.0
	# exit locked, nothing to shoot: go find the boss
	if exit_wait and f - no_t_f > 240 and boss != null and is_instance_valid(boss) and not boss.dead and absf(boss.global_position.x - x) > 300.0:
		want = signf(boss.global_position.x - x)
		best_x_f = f
	# gate cheese check
	if exit_node != null and is_instance_valid(exit_node) and exit_node.locked and x > exit_node.global_position.x + 20.0 and not gate_passed:
		gate_passed = true
		ev.append("PASSED LOCKED GATE x=%d y=%d" % [x, pl.global_position.y])
	# boss we can't hurt from here: flank it (jump over)
	if boss != null and is_instance_valid(boss) and not boss.dead:
		var bdx: float = boss.global_position.x - x
		if boss.hp != boss_hp_last or absf(bdx) > 500.0:
			boss_hp_last = boss.hp
			boss_hp_f = f
		elif f - boss_hp_f > 480:
			var charging: bool = boss._charge_t > 0.0 or boss._windup_t > 0.0
			if charging:
				want = signf(bdx) if absf(bdx) > 20.0 else 1.0
			elif absf(bdx) < 320.0:
				want = -1.0   # step back so it charges / turns
			else:
				want = 0.0
			if charging and absf(bdx) < 170.0 and on_floor and not keys.get(KEY_W, false):
				_key(KEY_W, true)
				jump_hold = 4
				want_jump2 = true
			if f - boss_hp_f > 1800:
				boss_hp_f = f
	if stall > 5.0 and dumped < 3 and f % 20 == 0:
		dumped += 1
		print("DUMP f=%d pos=%s vel=%s floor=%s crouch=%s climb=%s keys=%s run=%s daze=%s slow=%s grab=%s hook=%s roll=%s want=%s" % [f, str(pl.global_position), str(pl.velocity), str(on_floor), str(pl._crouching), str(pl._climbing), str(keys), str(pl._running), str(pl._daze_t), str(pl.slow_t), str(pl.grabbed_by), "-", str(pl._roll_t), str(want)])
		var qq := PhysicsShapeQueryParameters2D.new()
		var rs := RectangleShape2D.new()
		rs.size = Vector2(400, 400)
		qq.shape = rs
		qq.transform = Transform2D(0.0, pl.global_position + Vector2(0, -150))
		qq.collision_mask = 1 | 16 | 512
		for h in pl.get_world_2d().direct_space_state.intersect_shape(qq, 32):
			var c = h.collider
			var o = c.shape_owner_get_owner(h.shape) if c is CollisionObject2D else null
			var sh2 = c.shape_owner_get_shape(h.shape, 0) if c is CollisionObject2D else null
			print("   body ", _desc(c), " layer=", c.collision_layer, " shape=", sh2, " size=", sh2.size if sh2 is RectangleShape2D else (sh2.segments if sh2 is ConcavePolygonShape2D else "?"), " at ", o.global_position if o is Node2D else "?", " oneway=", o.one_way_collision if o is CollisionShape2D else "-")
	if stall > 25.0:   # (before the ladder logic: a ladder it can't reach used to return every frame and block this)
		var tx := x + 260.0
		ev.append("TELEPORT from x=%d y=%d (stuck %.0fs, blk=%s / %s)" % [x, pl.global_position.y, stall, cur_stuck.blk if cur_stuck else "?", cur_stuck.blk_hi if cur_stuck else "?"])
		if cur_stuck != null:
			cur_stuck.tp = true
		teleports += 1
		pl.global_position = Vector2(tx, pl.global_position.y - 260.0)
		pl.velocity = Vector2.ZERO
		best_x_f = f
		return
	# escape strategies when stuck
	if stall > 1.5:
		var lad = _near_ladder(320.0)
		if lad != null and stall < 9.0:
			ladder_go = lad
		if ladder_go != null and is_instance_valid(ladder_go):
			var lx: float = ladder_go.global_position.x
			if pl._climbing:
				_key(KEY_A, false)
				_key(KEY_D, false)
				_key(KEY_W, true)
				climb_hold += 1
				if climb_hold > 240:
					_key(KEY_W, false)
					ladder_go = null
					climb_hold = 0
				return
			if absf(lx - x) > 6.0:
				_key(KEY_W, false)
				_key(KEY_D, lx > x)
				_key(KEY_A, lx < x)
				return
			_key(KEY_A, false)
			_key(KEY_D, false)
			_key(KEY_W, true)
			climb_hold += 1
			if climb_hold > 90:
				ladder_go = null
				climb_hold = 0
			return
		if stall > 5.0 and stall < 7.0 and on_floor and pl._on_platform() and drop_try < 2:
			drop_try += 1
			key_queue = [[KEY_S, true], [KEY_S, false], [KEY_S, true], [KEY_S, false]]
			return
		# back off then run-jump
		var cyc := int(stall * 60.0) % 150
		if cyc < 40:
			want = -1.0
	if pl.grabbed_by != null:   # mash A/D
		var m := (f / 3) % 2 == 0
		_key(KEY_A, m)
		_key(KEY_D, not m)
		return
	# horizontal keys + run (double tap)
	if want > 0.0:
		_key(KEY_A, false)
		if not keys.get(KEY_D, false):
			_key(KEY_D, true)
		elif not pl._running and on_floor and run_cool <= 0 and not pl._crouching:
			key_queue = [[KEY_D, false], [KEY_D, true], [KEY_D, false], [KEY_D, true]]
			_key(KEY_D, false)
			key_queue.pop_front()
			run_cool = 40
	elif want < 0.0:
		_key(KEY_D, false)
		_key(KEY_A, true)
	else:
		_key(KEY_D, false)
		_key(KEY_A, false)
	run_cool -= 1
	# jumping
	var face := 1.0 if want >= 0.0 else -1.0
	var p: Vector2 = pl.global_position
	if keys.get(KEY_W, false):
		jump_hold -= 1
		if jump_hold <= 0:
			_key(KEY_W, false)
		return
	if want == 0.0:
		return
	if on_floor:
		var wall := _ray(p + Vector2(0, -12), p + Vector2(face * 75.0, -12), 1)
		var wall2 := _ray(p + Vector2(0, -44), p + Vector2(face * 75.0, -44), 1)
		var gnd := _ray(p + Vector2(face * 70.0, -4), p + Vector2(face * 70.0, 90), 1 | 16)
		var stalled := absf(pl.velocity.x) < 30.0 and stall > 0.15
		if not wall.is_empty() or not wall2.is_empty() or gnd.is_empty() or stalled:
			_key(KEY_W, true)
			jump_hold = 4
			want_jump2 = true
	elif want_jump2 and pl.velocity.y > -90.0:
		var wall := _ray(p + Vector2(0, -10), p + Vector2(face * 60.0, -10), 1)
		var gnd := _ray(p + Vector2(face * 40.0, -4), p + Vector2(face * 40.0, 300), 1 | 16)
		if not wall.is_empty() or gnd.is_empty() or stall > 0.5:
			_key(KEY_W, true)
			jump_hold = 4
		want_jump2 = false

func _barrier():
	for c in main_node.get_children():
		if c.get_script() != null and str(c.get_script().resource_path).ends_with("pass_barrier.gd"):
			if c._wall != null and not c._fade:
				return c
			return null
	return null

func _near_ladder(r: float):
	var best = null
	var bd := r
	for l in main_node.get_tree().get_nodes_in_group("ladders"):
		var d: float = absf(l.global_position.x - pl.global_position.x)
		if d < bd and l.top_y() < pl.global_position.y - 40.0 and absf(l.global_position.y - pl.global_position.y) < 60.0:
			bd = d
			best = l
	return best

# ============ checks ============
func _zombie_checks() -> void:
	if f % 30 != 0:
		return
	var ss = pl.get_world_2d().direct_space_state
	for z in main_node.get_tree().get_nodes_in_group("zombies"):
		if z.dead or not is_instance_valid(z):
			continue
		if absf(z.global_position.x - pl.global_position.x) > 1400.0:
			continue
		var nm: String = str(z.type_mod.stats().name) if z.type_mod != null else "k" + str(z.kind)
		var id := z.get_instance_id()
		var st: Dictionary = zseen.get(id, {})
		zseen[id] = st
		if z.global_position.y > floor_y + under + 400.0 and not st.has("fell"):
			st["fell"] = true
			_zf(nm, "fell_out_of_world")
		if z.collision_layer == 0 and not z.dormant:
			pass
		# inside a solid body (layer 1)?
		var q := PhysicsPointQueryParameters2D.new()
		q.position = z.global_position + Vector2(0, -24.0 * z.sc)
		q.collision_mask = 1
		q.collide_with_areas = false
		var hits: Array = ss.intersect_point(q, 4)
		var inside := false
		for h in hits:
			if h.collider != z and not (h.collider is CharacterBody2D):
				inside = true
		st["in"] = int(st.get("in", 0)) + 1 if inside else 0
		if int(st["in"]) == 6:
			_zf(nm, "inside_solid")
			if not st.has("in_logged"):
				st["in_logged"] = true
				var hd = hits[0].collider if hits.size() > 0 else null
				ev.append("zombie %s inside solid at %s (%s)" % [nm, str(z.global_position.round()), _desc(hd)])
		# floating: not on floor, not moving vertically, above the floor
		var fl: bool = (not z.is_on_floor()) and absf(z.velocity.y) < 2.0 and z.global_position.y < floor_y - 30.0 and not z.on_ceiling
		st["fl"] = int(st.get("fl", 0)) + 1 if fl else 0
		if int(st["fl"]) == 8:
			_zf(nm, "floating4s")
			if not st.has("fl_logged"):
				st["fl_logged"] = true
				ev.append("zombie %s floating at %s" % [nm, str(z.global_position.round())])

func _zf(nm: String, flag: String) -> void:
	var k := nm + ":" + flag
	zflags[k] = int(zflags.get(k, 0)) + 1

func _pickup_checks() -> void:
	var ss = pl.get_world_2d().direct_space_state
	for p in main_node.get_tree().get_nodes_in_group("pickups"):
		var q := PhysicsPointQueryParameters2D.new()
		q.position = p.global_position + Vector2(0, -6)
		q.collision_mask = 1
		var hits: Array = ss.intersect_point(q, 2)
		if not hits.is_empty():
			ev.append("pickup kind=%s inside solid at %s (%s)" % [str(p.get("kind")), str(p.global_position.round()), _desc(hits[0].collider)])
		if p.global_position.y > floor_y + under + 30.0:
			ev.append("pickup kind=%s below floor at %s" % [str(p.get("kind")), str(p.global_position.round())])

func _report_and_quit(why: String) -> void:
	if cur_stuck != null:
		cur_stuck.dur = float(f - cur_stuck.f0) / 60.0
		stuck_eps.append(cur_stuck)
		cur_stuck = null
	var lw: float = main_node.level_w
	var G = root.get_node("Game")
	var line := "BOT lv=%d god=%d result=%s time=%.1fs x=%d/%d prog=%d%% " % [lv, 1 if god else 0, why, float(finished_f if finished_f > 0 else f) / 60.0, pl.global_position.x, lw, int(100.0 * pl.global_position.x / lw)]
	line += "boss=%s seen=%.0f dead=%s near_exit=%s " % [boss_name, float(boss_seen_f) / 60.0, ("%.0f" % (float(boss_dead_f) / 60.0)) if boss_dead_f > 0 else "NO", ("%.0f" % (float(near_exit_f) / 60.0)) if near_exit_f > 0 else "-"]
	if boss != null and is_instance_valid(boss) and not boss.dead:
		line += "boss_hp=%d/%d boss_pos=%s " % [boss.hp, boss.max_hp, str(boss.global_position.round())]
	line += "stuck=%d tp=%d barrier=%d(%.0fs) story=%.0fs slow25=%d worst=%.0fms avg=%.1fms refills=%d spec=%d deaths=%d dmg=%d maxhp=%d" % [stuck_eps.size(), teleports, barrier_eps, barrier_f / 60.0, story_frames / 60.0, slow, worst, sum_ms / maxf(nms, 1), refills, spec_used, deaths_at.size(), dmg_taken, max_hp]
	print(line)
	for s in stuck_eps:
		print("  STUCK x=%d y=%d %.1fs floor=%s tp=%s blk=%s hi=%s" % [s.x, s.y, s.dur, str(s.floor), str(s.tp), s.blk, s.blk_hi])
	for e in ev:
		print("  EV ", e)
	if not zflags.is_empty():
		print("  ZFLAGS ", zflags)
	if not deaths_at.is_empty():
		print("  DEATHS_AT ", deaths_at)
	if not slow_list.is_empty():
		print("  SLOW ", slow_list)
	print("  specials_seen ", specials_seen.keys(), " shots ", shots)
	quit()
