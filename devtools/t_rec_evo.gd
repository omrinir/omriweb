extends SceneTree
# PROMO CLIP (test only): "LEVEL 1 vs LEVEL 63" - one zombie kind staged on its own level with real game mechanics, for
# --write-movie. The player stands his ground, tracks the zombie with a human-like aim (a little lag, close to level, flips
# when he turns) and fires on a plan (EVO_MODE):
#   shoot - fires every EVO_GAP frames once the zombie is within EVO_RANGE, starting at frame EVO_HOLD
#   hold  - aims but holds fire until frame EVO_FIRE_AT (lets the zombie show what it learned), then shoots like "shoot"
#   none  - never fires (the zombie shows off, e.g. a copy of the hero shooting at you)
# Other zombies near the player are removed, the pace director is switched off. HUD + pop-ups hidden.
# env: EVO_LEVEL, EVO_KIND (kind number or zombie_registry name, e.g. MIMIC; a list "0,1,2" = a mixed horde), EVO_N (count, default 1), EVO_AT (player x),
#      EVO_DX (spawn distance, negative = left of the player), EVO_SPREAD (gap between several, default 70),
#      EVO_SPAWN_F (frame of the spawn, default 30), EVO_WEAPON (weapon_db id, default 0), EVO_MODE, EVO_HOLD, EVO_FIRE_AT,
#      EVO_GAP (default 24), EVO_RANGE (default 520), EVO_END (frames, default 600), EVO_AFTER (frames after the last kill, default 70),
#      EVO_META=<key=int,...> (main meta set before the spawn, e.g. sep_beaten=3 = the SEEPER already learned to rise behind you),
#      EVO_ADOPT=1 (no spawn: adopt the level's own boss of EVO_KIND near the player, e.g. HOLLOW = SUBJECT ZERO in the hall),
#      EVO_BOSS_DX=<px> (with EVO_ADOPT: the player starts this far left of the level's own boss, wherever the level put it),
#      EVO_BOSS_HP=<int> + EVO_HP_AT=<frame> (at that frame a staged boss has at most this much life left: the fight fits a clip;
#      EVO_BOSS_MAX=1 = that is also his full life, so life-fraction stages such as GOLIATH's limbs restart from there),
#      EVO_TM_CALL=<method>:<int>@<frame>[;...] (calls the staged zombie's type_mod method with that int at that frame (EVO_SPAWN_F or later),
#      e.g. _begin_phase:4@200 = the ROOT jumps to its last phase),
#      EVO_TM_SET=<field>=<float>@<frame>[;...] (sets a field of the staged zombie's type_mod (EVO_SPAWN_F or later): what it already learned, e.g.
#      run_bias=180@30 = the RED ZEPPELIN already knows you run right, so its carpet lands there),
#      EVO_RUN=<frame>:<dir>:<frames>[;...] (the player runs left (-1) / right (1) for that many frames: dodging like a person),
#      EVO_CAM_ZOOM=<float> (the game camera's zoom, e.g. 0.75 = a giant boss and the player both fit a portrait crop),
#      EVO_LIQUID_AIM=0 (the player loses a zombie that turned into a puddle: no tracking, no shots until it rises),
#      EVO_AIM_Y2 (aim height once it has risen again, e.g. -30 = the SEEPER's core after headshots melted it),
#      EVO_MEM=<key=float,...> (PlayerMemory at the start: a weapon_use category such as precision=0 = the zombies have not
#      learned yet that you snipe, so no zigzag hops in front of a railgun; or a field such as avg_distance=300),
#      EVO_SEED=<int> (the level layout seed, Game.attempt_seed: previews and recordings get the same pits / crates / rails),
#      EVO_RSEED=<int> (seeds the global random numbers: another seed = another street layout and boss timing, pick the best take),
#      EVO_CALM=1 (the subway's electrified rail strips are switched off: no random ZAP kills in the clip),
#      EVO_SLOTS=<int> (the squad director's attack slots, 99 = every zombie charges at once instead of 3 attacking and the rest holding back),
#      EVO_TEXT_ONCE=1 (one pop-up per spot, the newest, e.g. one MULTI KILL for a railgun line, not ten stacked),
#      EVO_HOLD_FIRE=1 (holds the trigger every frame while the zombie is in range: automatic guns at their real rate,
#      the MINIGUN spins up, the FLAMETHROWER streams), EVO_REAL_MAG=1 (the magazine empties and reloads as in the game,
#      e.g. DOUBLE BARREL = two shots, then a reload),
#      EVO_AIM_UP / EVO_AIM_DOWN (aim limits in radians, default 0.45 / 0.35), EVO_AIM_Y (aim height on the zombie, default -30,
#      -50 = the head), EVO_SURVIVORS=1 (keep the level's survivors), EVO_HELPERS=0 (also clear zombies that walk up next to ours), EVO_TEXT_MAX (longer floating texts are hidden, default 24), EVO_STAY=1 (never steps back), EVO_GOD=1 (GOD MODE),
#      REC_POS=<csv>: t, player x, y, target x, y (screen, 1280 space), fired (0/1), fresh corpses "id/age/x/y|..." (as t_rec_god.gd)
#      SNAP=<dir>: save a png every SNAP_EVERY (default 20) frames (previews; run with a 1280x720 window), SNAP_FULL=1 = the whole screen
# usage: EVO_LEVEL=12 EVO_KIND=MIMIC REC_POS=/tmp/m.csv xvfb-run -a -s "-screen 0 2560x1440x24" godot --path . --rendering-driver opengl3 \
#        --resolution 2560x1440 --write-movie /tmp/m.avi --fixed-fps 60 -s res://t_rec_evo.gd
var f := 0
var main_node: Node = null
var pl = null
var keys := {}
var pos_file: FileAccess = null
var ours := []                   # the staged zombies (+ anything they spawn near them)
var _alive := {}
var _died := {}
var _aim := Vector2.RIGHT
var _next_fire := 0
var _fired := false
var _done_f := -1
var _move := 0
var _move_left := 0
var _was_lost := false
var _kills := 0
var _rng := RandomNumberGenerator.new()
var at_x := 2000.0
var spawn_f := 30


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
	g.level = _env("EVO_LEVEL", 1)
	if _env("EVO_SEED", 0) != 0:   # the level's layout (pits, crates, rails) - the same in the preview and in the recording
		g.attempt_seed = _env("EVO_SEED", 0)
	if _env("EVO_RSEED", 0) != 0:
		seed(_env("EVO_RSEED", 0))
	main_node = load("res://main.tscn").instantiate()
	root.add_child(main_node)
	current_scene = main_node
	at_x = _env("EVO_AT", 2000.0)
	spawn_f = _env("EVO_SPAWN_F", 30)
	if OS.get_environment("REC_POS") != "":
		pos_file = FileAccess.open(OS.get_environment("REC_POS"), FileAccess.WRITE)
	_rng.seed = 7


func _kind() -> int:
	return _kind_at(0)


# EVO_KIND can be a list ("0,1,0,2"): zombie i gets entry i (cycling) - a mixed horde
func _kind_at(i: int) -> int:
	var ks: PackedStringArray = str(_env("EVO_KIND", "0")).split(",", false)
	var k: String = ks[i % ks.size()].strip_edges()
	if k.is_valid_int():
		return int(k)
	var rs: Script = load("res://enemies/zombie_registry.gd")
	return int(rs.get_script_constant_map()[k])


# the level's own boss of EVO_KIND (EVO_ADOPT=1)
func _adoptable(o) -> bool:
	return _env("EVO_ADOPT", 0) == 1 and is_instance_valid(o) and not o.dead and int(o.kind) == _kind() and float(o.chase_range) > 600.0 \
		and absf(o.global_position.x - at_x) < 1700.0


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


# aim stays close to level (EVO_AIM_UP / EVO_AIM_DOWN)
func _level_aim(v: Vector2) -> Vector2:
	var sx := signf(v.x) if v.x != 0.0 else 1.0
	var e := clampf(atan2(-v.y, absf(v.x)), -float(_env("EVO_AIM_DOWN", 0.35)), float(_env("EVO_AIM_UP", 0.45)))
	return Vector2(sx, 0.0).rotated(-e * sx)


func _physics_process(_d: float) -> bool:
	f += 1
	pl = main_node.get_tree().get_first_node_in_group("player")
	if pl == null:
		return false
	pl.health = pl.max_health
	var mb := AudioServer.get_bus_index("Music")
	if mb >= 0:
		AudioServer.set_bus_mute(mb, true)
	if f == 2:
		for kv in str(_env("EVO_META", "")).split(",", false):
			main_node.set_meta(kv.get_slice("=", 0), int(kv.get_slice("=", 1)))
		var mem = root.get_node("PlayerMemory")
		for kv in str(_env("EVO_MEM", "")).split(",", false):   # what the zombies "know" about the player at the start
			var mk := kv.get_slice("=", 0)
			if mem.weapon_use.has(mk):
				mem.weapon_use[mk] = float(kv.get_slice("=", 1))
			else:
				mem.set(mk, float(kv.get_slice("=", 1)))
		for c in main_node.get_children():
			var sc = c.get_script()
			if sc != null and (str(sc.resource_path).ends_with("pace_director.gd") or str(sc.resource_path).ends_with("flank_director.gd")):
				c.queue_free()
		if _env("EVO_SLOTS", 0) > 0:   # attack slots: 99 = the whole horde charges (no one waits at a distance for a turn)
			for sq in main_node.get_tree().get_nodes_in_group("squad_director"):
				sq.max_slots = _env("EVO_SLOTS", 0)
	if f == 3:
		if _env("EVO_CAM_ZOOM", 0.0) > 0.0:
			var cam = main_node.get_viewport().get_camera_2d()
			if cam != null:
				cam.zoom = Vector2.ONE * float(_env("EVO_CAM_ZOOM", 1.0))
				if "_base_zoom" in cam:
					cam._base_zoom = cam.zoom
		if _env("EVO_BOSS_DX", 0.0) != 0.0:   # next to the level's own boss (stationary bosses stand where their stage put them)
			for o in main_node.get_tree().get_nodes_in_group("zombies"):
				if int(o.kind) == _kind() and float(o.chase_range) > 600.0:
					at_x = o.global_position.x - float(_env("EVO_BOSS_DX", 0.0))
					print("boss at x=%d y=%d -> player x=%d" % [o.global_position.x, o.global_position.y, at_x])
					break
		pl.global_position.x = at_x
		var w: int = _env("EVO_WEAPON", 0)
		if w > 0:
			var full: int = load("res://weapons/weapon_db.gd").val(w, "magazine_size", 99) if _env("EVO_REAL_MAG", 0) == 1 else 99
			pl.slots[0] = {"id": w, "ammo": 999, "mag": full}
			pl.select_slot(0)
	if f == 50 and OS.get_environment("PREVIEW") != "":
		root.get_viewport().get_texture().get_image().save_png(OS.get_environment("PREVIEW"))
	for s in main_node.get_tree().get_nodes_in_group("story_scene"):
		if s.has_method("_finish"):
			s._finish()
	for n in main_node.find_children("*", "CanvasLayer", true, false):
		if n.layer >= 2:
			n.visible = false
	var game = root.get_node("Game")
	if game._banner != null:
		game._banner.visible = false   # no "TROPHY UNLOCKED" pop-ups in the clip
	# long floating lines (hints, the hero talking) would fight the Short's own subtitles: hide them, keep the short pop-ups
	var max_len: int = _env("EVO_TEXT_MAX", 24)
	var shown := []
	var kids := main_node.get_children()
	kids.reverse()   # newest first: it wins a spot (MULTI KILL over the DOUBLE KILL under it)
	for c in kids:
		if c is Node2D and "life" in c and "text" in c and "pop" in c:
			if String(c.text).length() > max_len:
				c.visible = false
			elif _env("EVO_TEXT_ONCE", 0) == 1:   # a multi-kill stacks 10 pop-ups on top of each other: keep one per spot
				var free := true
				for q in shown:
					if absf(q.x - c.global_position.x) < 110.0 and absf(q.y - c.global_position.y) < 26.0:
						free = false
				c.visible = free
				if free:
					shown.append(c.global_position)
	# ---- spawn ----
	if f == spawn_f:
		var n: int = _env("EVO_N", 1)
		var dx: float = _env("EVO_DX", 480.0)
		if _env("EVO_ADOPT", 0) == 1:
			n = 0
			for o in main_node.get_tree().get_nodes_in_group("zombies"):
				if _adoptable(o):
					o.dormant = false
					ours.append(o)
		for i in n:
			var x: float = pl.global_position.x + dx + signf(dx) * float(_env("EVO_SPREAD", 70.0)) * i
			var z = main_node._spawn_zombie(x, pl.global_position.y - 4.0, _kind_at(i), null)
			if z != null:
				z.dormant = false
				ours.append(z)
		game.make_noise(pl.global_position, 1200.0)
		if _env("EVO_GOD", 0) == 1:
			pl._drink_god()
		print("f=%d spawned %d of kind %d" % [f, ours.size(), _kind()])
	if f == int(_env("EVO_HP_AT", spawn_f + 1)) and _env("EVO_BOSS_HP", 0) > 0:
		for z in ours:
			if is_instance_valid(z) and not z.dead and z.is_boss():
				z.hp = mini(int(z.hp), int(_env("EVO_BOSS_HP", 0)))
				if _env("EVO_BOSS_MAX", 0) == 1:   # ...and that is his full life (GOLIATH loses a limb per fraction of it)
					z.max_hp = z.hp
				print("f=%d boss hp -> %d" % [f, z.hp])
	for spec in str(_env("EVO_TM_SET", "")).split(";", false):
		if f == int(spec.get_slice("@", 1)):
			var kv := spec.get_slice("@", 0)
			for z in ours:
				if is_instance_valid(z) and not z.dead and z.type_mod != null and kv.get_slice("=", 0) in z.type_mod:
					z.type_mod.set(kv.get_slice("=", 0), float(kv.get_slice("=", 1)))
					print("f=%d set %s" % [f, kv])
	for spec in str(_env("EVO_TM_CALL", "")).split(";", false):
		if f == int(spec.get_slice("@", 1)):
			var call := spec.get_slice("@", 0)
			for z in ours:
				if is_instance_valid(z) and not z.dead and z.type_mod != null and z.type_mod.has_method(call.get_slice(":", 0)):
					z.type_mod.call(call.get_slice(":", 0), int(call.get_slice(":", 1)))
					print("f=%d %s" % [f, call])
	# ---- keep the stage to ourselves (no survivors either: firing next to one drains her, which needs its own story) ----
	if f % 5 == 0 and _env("EVO_CALM", 0) == 1:
		for n in main_node.find_children("*", "Node2D", true, false):
			if "rails" in n and n.rails is Array:
				n.rails.clear()
	if f % 5 == 0 and _env("EVO_SURVIVORS", 0) == 0:
		for o in main_node.get_tree().get_nodes_in_group("survivors"):
			o.queue_free()
	if f % 5 == 0:
		for o in main_node.get_tree().get_nodes_in_group("zombies"):
			if o in ours or o.dead or absf(o.global_position.x - pl.global_position.x) > 1700.0 or _adoptable(o):
				continue
			var helper := false
			if f > spawn_f and _env("EVO_HELPERS", 1) == 1:
				for m in ours:
					if is_instance_valid(m) and o.global_position.distance_to(m.global_position) < 320.0:
						helper = true
			if helper:
				ours.append(o)
			else:
				o.queue_free()
	if pl.slots[0] != null:
		pl.slots[0].ammo = 999
		if _env("EVO_REAL_MAG", 0) == 0:
			pl.slots[0]["mag"] = maxi(int(pl.slots[0].get("mag", 0)), 6)
	# ---- the player ----
	var tgt = null
	var bd := INF
	for z in ours:
		if not is_instance_valid(z) or z.dead:
			continue
		var d: float = absf(z.global_position.x - pl.global_position.x)
		if d < bd:
			bd = d
			tgt = z
	if tgt == null and f > spawn_f and _done_f < 0:
		_done_f = f
		print("f=%d all dead" % f)
	var mode: String = _env("EVO_MODE", "shoot")
	var tm0 = tgt.type_mod if tgt != null else null
	var lost: bool = _env("EVO_LIQUID_AIM", 1) == 0 and tm0 != null and tm0.has_method("is_liquid") and tm0.is_liquid()
	if lost:
		_was_lost = true
	if tgt != null and lost:
		_move = 0
		pl._aim = _aim
	elif tgt != null:
		var ay: float = _env("EVO_AIM_Y2", 0.0) if _was_lost and OS.get_environment("EVO_AIM_Y2") != "" else _env("EVO_AIM_Y", -30.0)
		var aim_p: Vector2 = tgt.global_position + Vector2(0.0, ay * float(tgt.sc))   # -50 = headshots
		var want: Vector2 = _level_aim((aim_p - (pl.global_position + pl._front_shoulder())).normalized())
		if signf(want.x) != signf(_aim.x):
			_aim = Vector2(-_aim.x, _aim.y)
		_aim = _aim.slerp(want, 0.22)
		pl._aim = _aim
		var may := mode == "shoot" and f >= int(_env("EVO_HOLD", 0))
		may = may or (mode == "hold" and f >= int(_env("EVO_FIRE_AT", 240)))
		if may and bd < float(_env("EVO_RANGE", 520.0)) and absf(_aim.angle_to(want)) < 0.2:
			if _env("EVO_HOLD_FIRE", 0) == 1:
				pl._fire_test = true
				_fired = true
			elif f >= _next_fire:
				pl._fire_test = true
				_fired = true
				_next_fire = f + int(_env("EVO_GAP", 24)) + _rng.randi_range(0, 6)
		# step back when it gets close (a person would)
		var dx2: float = tgt.global_position.x - pl.global_position.x
		if _move_left <= 0:
			_move = 0
			if absf(dx2) < 110.0 and OS.get_environment("EVO_STAY") == "":
				_move = -int(signf(dx2))
				_move_left = _rng.randi_range(12, 20)
		_move_left -= 1
	else:
		_move = 0
		_aim = _aim.slerp(Vector2(pl._face(), -0.04).normalized(), 0.1)
		pl._aim = _aim
	for spec in str(_env("EVO_RUN", "")).split(";", false):   # a scripted dodge wins over the step back
		var r0 := int(spec.get_slice(":", 0))
		if f >= r0 and f < r0 + int(spec.get_slice(":", 2)):
			_move = int(spec.get_slice(":", 1))
	_key(KEY_A, _move < 0)
	_key(KEY_D, _move > 0)
	# between shots the game aims at the mouse: keep it on the aim line
	var aim_w: Vector2 = pl.global_position + pl._front_shoulder() + _aim * 320.0
	var vp: Viewport = main_node.get_viewport()
	vp.warp_mouse(vp.get_canvas_transform() * aim_w)
	var mm := InputEventMouseMotion.new()
	mm.position = vp.get_final_transform() * (vp.get_canvas_transform() * aim_w)   # window pixels (2x in a 2560 window)
	mm.global_position = mm.position
	Input.parse_input_event(mm)
	if OS.get_environment("EVO_DBG") != "" and f % 30 == 0:
		print("mouse f=%d off=%s" % [f, str(pl.get_global_mouse_position() - aim_w)])
	# ---- log ----
	for id in _alive:
		var z = _alive[id]
		if is_instance_valid(z) and z.dead and not _died.has(id):
			_died[id] = [z, f]
			_kills += 1
			print("f=%d kill %d" % [f, _kills])
	_alive.clear()
	for z in main_node.get_tree().get_nodes_in_group("zombies"):
		if not z.dead:
			_alive[z.get_instance_id()] = z
	if pos_file != null:
		var xf: Transform2D = vp.get_canvas_transform()
		var sp: Vector2 = xf * pl.global_position
		var tp: Vector2 = sp
		if tgt != null:
			tp = xf * (tgt.global_position + Vector2(0.0, -30.0 * float(tgt.sc)))
		var fresh := PackedStringArray()
		for id in _died.keys():
			var dd: Array = _died[id]
			if f - int(dd[1]) > 72 or not is_instance_valid(dd[0]):
				_died.erase(id)
				continue
			var zp: Vector2 = xf * (dd[0].global_position + Vector2(0.0, -30.0 * float(dd[0].sc)))
			fresh.append("%d/%d/%d/%d" % [id % 1000000, f - int(dd[1]), zp.x, zp.y])
		pos_file.store_line("%.4f,%d,%d,%d,%d,%d,%s" % [f / 60.0, sp.x, sp.y, tp.x, tp.y, int(_fired), "|".join(fresh)])
	_fired = false
	if OS.get_environment("SNAP") != "" and f % int(_env("SNAP_EVERY", 20)) == 0:
		var img := root.get_viewport().get_texture().get_image()
		var xf2: Transform2D = vp.get_canvas_transform()
		var mid: Vector2 = xf2 * pl.global_position
		if tgt != null:
			mid = mid.lerp(xf2 * tgt.global_position, 0.5)
		var sx: float = float(img.get_width()) / 1280.0
		var cw := int(640 * sx)
		var ch := int(360 * sx)
		var cx := clampi(int(mid.x * sx) - cw / 2, 0, img.get_width() - cw)
		var cy := clampi(int((mid.y - 60.0) * sx) - ch / 2, 0, img.get_height() - ch)
		if OS.get_environment("SNAP_FULL") == "":   # (SNAP_FULL=1: the whole screen, e.g. a boss bigger than the crop)
			img = img.get_region(Rect2i(cx, cy, cw, ch))
		img.resize(640, 360)
		img.save_png("%s/s_%04d.png" % [OS.get_environment("SNAP"), f])
	if tgt != null and f % 15 == 0:
		var tm = tgt.type_mod
		print("f=%d tgt x=%d hp=%s px=%d state=%s" % [f, tgt.global_position.x, str(tgt.hp), pl.global_position.x, str(tm.get("state")) if tm != null else "-"])
	if f >= int(_env("EVO_END", 600)) or (_done_f > 0 and f >= _done_f + int(_env("EVO_AFTER", 70))):
		if pos_file != null:
			pos_file.flush()
		quit()
	return false
