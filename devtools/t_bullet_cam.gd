extends SceneTree
# TEST: the sniper BULLET CAM (effects/bullet_cam.gd). The player stands at BC_AT with a sniper, a zombie walks up from BC_DX,
# the player scopes (right mouse button held from frame BC_SCOPE_F) and fires at frame BC_FIRE_F (head: BC_AIM_Y=-50).
# BC_FORCE=1 (default): every shot that will kill gets the cam (no dice, no 1-2 per level limit). BC_FORCE=0 = the real odds.
# Prints the cam's phases and checks the motion: camera centre / zoom / bullet on screen per frame (BC_CSV=<file>), and
# "BULLET CAM OK" when the cam ran, the zombie died, time and camera came back to normal, nothing jumped and the target
# is not left frozen. With BC_SHOTS > 1 a new zombie walks up after each kill; then OK = at least one cam, every cam ended
# with a kill, no more cams than the level allows (1 or 2) and at least GAP game seconds between them.
# env: BC_LEVEL (default 12), BC_WEAPON (weapon_db id: 3 SNIPER, 19 ANTI-MATERIEL, 22 RAILGUN), BC_KIND (default 0 = walker),
#      BC_DX (default 460, negative = left), BC_AT (default 2000), BC_SCOPE_F (default 60), BC_FIRE_F (default 100),
#      BC_AIM_Y (default -50), BC_END (frames, default 420), BC_SEED (layout, default 1, 0 = random), BC_RSEED (random numbers, default 7),
#      BC_SHOTS (default 1), BC_GAP (frames between shots, default 90), BC_LEARNED=1 (the zombies already know you snipe:
#      they hop when you aim at them, so some shots get no cam - jumping zombies are never predicted), BC_DEBUG=1 (why no
#      cam), BC_DUCK (the zombie's chance to duck when shot at, default 0: a ducking zombie gets no cam)
# usage: BC_CSV=/tmp/bc.csv xvfb-run -a -s "-screen 0 1280x720x24" godot --path . --rendering-driver opengl3 \
#        --resolution 1280x720 --write-movie /tmp/bc.avi --fixed-fps 60 -s res://t_bullet_cam.gd
var f := 0
var main_node: Node = null
var pl = null
var ours := []
var csv: FileAccess = null
var BC: Script = null
var _aim := Vector2.RIGHT
var _rmb := false
var _rmb_off_f := -1
var _shots := 0
var _next_fire := 0
var _phase_was := -1
var _started := -1
var _ended := -1
var _killed_f := -1
var _cams := 0
var _cam_t := []        # game time at each cam start
var _cam_kill := []     # did each cam end with its zombie dead
var _gt := 0.0
var _dead_f := -1
var _jumps := 0
var _prev := []   # [centre, zoom] of the last frame
var _prev_v := Vector2.ZERO
var _max_acc := 0.0
var _ts_bad := false
var _dbg_f := -1


func _env(k: String, d):
	var v := OS.get_environment(k)
	if v == "":
		return d
	if d is int:
		return int(v)
	if d is float:
		return float(v)
	return v


func _initialize() -> void:
	var g = root.get_node("Game")
	g.new_run()
	g.level = _env("BC_LEVEL", 12)
	if _env("BC_SEED", 1) != 0:   # (0 = a random layout)
		g.attempt_seed = _env("BC_SEED", 1)
	seed(_env("BC_RSEED", 7))
	main_node = load("res://main.tscn").instantiate()
	root.add_child(main_node)
	current_scene = main_node
	BC = load("res://effects/bullet_cam.gd")
	BC.test_force = _env("BC_FORCE", 1) == 1
	_next_fire = _env("BC_FIRE_F", 100)
	if OS.get_environment("BC_CSV") != "":
		csv = FileAccess.open(OS.get_environment("BC_CSV"), FileAccess.WRITE)
		csv.store_line("f,ts,phase,cx,cy,zoom,bx,by,zx,zy,px,py,kx,ky")


func _rmb_set(on: bool) -> void:
	if on == _rmb:
		return
	_rmb = on
	if not on:
		_rmb_off_f = f
	var e := InputEventMouseButton.new()
	e.button_index = MOUSE_BUTTON_RIGHT
	e.pressed = on
	e.button_mask = MOUSE_BUTTON_MASK_RIGHT if on else 0
	Input.parse_input_event(e)
	Input.flush_buffered_events()


func _spawn() -> void:
	var z = main_node._spawn_zombie(pl.global_position.x + float(_env("BC_DX", 460.0)), pl.global_position.y - 4.0, _env("BC_KIND", 0), null)
	if z != null:
		z.dormant = false
		z.duck_chance = float(_env("BC_DUCK", 0.0))   # (a zombie that ducks under the shot gets no cam)
		ours.append(z)
	root.get_node("Game").make_noise(pl.global_position, 1200.0)


func _physics_process(d: float) -> bool:
	f += 1
	_gt += d
	pl = main_node.get_tree().get_first_node_in_group("player")
	if pl == null:
		return false
	pl.health = pl.max_health
	var shots_max: int = _env("BC_SHOTS", 1)
	if _env("BC_LEARNED", 0) == 0 and f >= 2:   # the zombies have not learned yet that you snipe (no hops in front of the scope)
		root.get_node("PlayerMemory").weapon_use["precision"] = 0.0
	if f == 2:
		for c in main_node.get_children():
			var sc = c.get_script()
			if sc != null and (str(sc.resource_path).ends_with("pace_director.gd") or str(sc.resource_path).ends_with("flank_director.gd")):
				c.queue_free()
	if f == 3:
		pl.global_position.x = _env("BC_AT", 2000.0)
		pl.slots[0] = {"id": _env("BC_WEAPON", 3), "ammo": 99, "mag": 5}
		pl.select_slot(0)
	if pl.slots[0].get("ammo", 0) < 20:
		pl.slots[0]["ammo"] = 99
	for s in main_node.get_tree().get_nodes_in_group("story_scene"):
		if s.has_method("_finish"):
			s._finish()
	if f == 30:
		_spawn()
	if f % 5 == 0:
		for o in main_node.get_tree().get_nodes_in_group("zombies"):
			if not o in ours and not o.dead and absf(o.global_position.x - pl.global_position.x) < 1700.0:
				o.queue_free()
		for o in main_node.get_tree().get_nodes_in_group("survivors"):
			o.queue_free()
	var tgt = null
	for z in ours:
		if is_instance_valid(z) and not z.dead:
			tgt = z
	var holding: bool = BC.holding()
	var cam = BC.inst
	var ph: int = cam._phase if cam != null else -1
	# more shots: a new zombie walks up after each kill (once the cam is over)
	if tgt == null and shots_max > 1 and _shots < shots_max and ph <= 0 and ours.size() > 0:
		if _dead_f < 0:
			_dead_f = f
		elif f > _dead_f + 40:
			_dead_f = -1
			_spawn()
			_next_fire = maxi(_next_fire, f + 70)
	if tgt != null and not holding:
		var aim_p: Vector2 = tgt.global_position + Vector2(0.0, float(_env("BC_AIM_Y", -50.0)) * float(tgt.sc))
		var want: Vector2 = (aim_p - (pl.global_position + pl._front_shoulder())).normalized()
		_aim = _aim.slerp(want, 0.3)
		pl._aim = _aim
	_rmb_set(f >= int(_env("BC_SCOPE_F", 60)) and (_shots < shots_max or ph > 0) and (shots_max > 1 or _ended < 0))
	if tgt != null and f >= _next_fire and _shots < shots_max and not holding and ph <= 0 and absf(tgt.global_position.x - pl.global_position.x) < 900.0:
		pl._fire_test = true
		_shots += 1
		_next_fire = f + int(_env("BC_GAP", 90))
		print("f=%d FIRE #%d (scope=%s, ts=%.2f, dist=%d)" % [f, _shots, str(pl._scoping), Engine.time_scale, absf(tgt.global_position.x - pl.global_position.x)])
		_dbg_f = f + 1
	if f == _dbg_f and _env("BC_DEBUG", 0) == 1:   # why no cam? the newest bullet, asked again (no side effects)
		for b in main_node.get_children():
			if b.get_script() != null and str(b.get_script().resource_path).ends_with("bullet.gd") and b.sniper:
				var r: Dictionary = BC.inst._predict(pl, b) if BC.inst != null else {}
				print("f=%d bullet at %s vel %s -> predict %s" % [f, str(b.global_position.round()), str(b.velocity.round()), str(r.keys())])
				if tgt != null:
					print("   target %s rect %s hp %d on_floor %s vel %s" % [str(tgt.global_position.round()), str(tgt.hit_rect()), tgt.hp, str(tgt.is_on_floor()), str(tgt.velocity.round())])
	# keep the mouse on the aim line (the game aims at the mouse)
	var vp: Viewport = main_node.get_viewport()
	if not holding:
		var aim_w: Vector2 = pl.global_position + pl._front_shoulder() + _aim * 320.0
		var mm := InputEventMouseMotion.new()
		mm.position = vp.get_final_transform() * (vp.get_canvas_transform() * aim_w)
		mm.global_position = mm.position
		Input.parse_input_event(mm)
		vp.warp_mouse(vp.get_canvas_transform() * aim_w)
	# ---- watch the cam ----
	if ph != _phase_was:
		print("f=%d phase %d -> %d  ts=%.3f" % [f, _phase_was, ph, Engine.time_scale])
		if ph == 1:
			_cams += 1
			_cam_t.append(_gt)
			if _started < 0:
				_started = f
		if ph == 0 and _phase_was > 0:
			var k := false
			if cam != null and ours.size() > 0:
				for z in ours:
					if is_instance_valid(z) and z.dead and z.global_position.distance_to(cam._hit) < 200.0:
						k = true
			_cam_kill.append(k)
			if _ended < 0:
				_ended = f
		_phase_was = ph
	for z in ours:
		if is_instance_valid(z) and z.dead and not z.has_meta("t_dead_seen"):
			z.set_meta("t_dead_seen", true)
			if _killed_f < 0:
				_killed_f = f
			print("f=%d zombie dead (zone %s)" % [f, str(z._last_info.get("zone", "?"))])
	var c2d: Camera2D = vp.get_camera_2d()
	var cen: Vector2 = c2d.get_screen_center_position()
	var zm: float = c2d.zoom.x
	if ph > 0 and _prev.size() == 3 and int(_prev[2]) > 0:
		var v: Vector2 = (cen - _prev[0]) * zm * 60.0   # screen px per real second
		var a: float = (v - _prev_v).length() * 60.0
		_max_acc = maxf(_max_acc, a)
		if a > 60000.0:   # a jolt: >1000 px/s change of on-screen speed in one frame
			_jumps += 1
			print("f=%d JOLT acc=%d v=%s" % [f, a, str(v)])
		_prev_v = v
	else:
		_prev_v = Vector2.ZERO
	_prev = [cen, zm, ph]
	if csv != null:
		var xf: Transform2D = vp.get_canvas_transform()
		var bp := Vector2(-1, -1)
		if cam != null and cam._b != null and is_instance_valid(cam._b):
			bp = xf * cam._b.interp_pos()
		var zp := Vector2(-1, -1)
		if ours.size() > 0 and is_instance_valid(ours[-1]):
			zp = xf * (ours[-1].global_position + Vector2(0.0, -30.0 * float(ours[-1].sc)))
		var pp: Vector2 = xf * pl.global_position
		var kp := Vector2(-1, -1)   # the body on screen (also the flying ragdoll)
		if ours.size() > 0 and is_instance_valid(ours[-1]):
			kp = xf * ours[-1].body_center()
		csv.store_line("%d,%.4f,%d,%.2f,%.2f,%.4f,%.1f,%.1f,%.1f,%.1f,%.1f,%.1f,%.1f,%.1f" % [f, Engine.time_scale, ph, cen.x, cen.y, zm, bp.x, bp.y, zp.x, zp.y, pp.x, pp.y, kp.x, kp.y])
	if ph <= 0 and _ended > 0 and not _rmb and Engine.time_scale < 0.99 and f > _rmb_off_f + 10 and f > _ended + 30:
		_ts_bad = true
	if f >= int(_env("BC_END", 420)) and (ph <= 0 or f >= int(_env("BC_END", 420)) + 600):   # (a running cam finishes first)
		if csv != null:
			csv.flush()
		var frozen := false   # the target must not stay frozen (zombie.gd cam_hold)
		for z in ours:
			if is_instance_valid(z) and z.cam_hold:
				frozen = true
		var clean: bool = _jumps == 0 and not _ts_bad and not frozen and not Engine.has_meta("bullet_cam") and not Engine.has_meta("logic_view") \
			and absf(zm - float(c2d._base_zoom.x)) < 0.001 and ph <= 0
		var ok: bool = clean and _started > 0 and _ended > 0 and not _cam_kill.has(false)
		if shots_max > 1 and cam != null and not BC.test_force:
			var gap_ok := true
			for i in range(1, _cam_t.size()):
				if float(_cam_t[i]) - float(_cam_t[i - 1]) < float(BC.GAP) - 0.01:
					gap_ok = false
			print("cams %d (level allows %d, shown %d), game seconds at each: %s, shots %d" % [_cams, cam.count_max, cam.shown, str(_cam_t), _shots])
			ok = ok and _cams <= int(cam.count_max) and gap_ok
		else:
			ok = ok and _killed_f > 0
		if frozen:
			print("target still frozen (cam_hold)")
		print("cam %d..%d (%.2f s), kill f=%d, max screen acc %d, jolts %d, time after %.2f, zoom after %.3f" % [_started, _ended,
			float(_ended - _started) / 60.0, _killed_f, _max_acc, _jumps, Engine.time_scale, zm])
		print("BULLET CAM OK" if ok else "BULLET CAM FAILED")
		quit()
	return false
