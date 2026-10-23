extends SceneTree
# PROMO CLIP (test only): GOD MODE rampage, staged with real game mechanics, for --write-movie.
# The player stands his ground with an ASSAULT SHOTGUN, drinks the GOD MODE potion at GOD_F and waves of zombies come from both
# sides. He plays like a person: aims at the closest zombie, turns around, steps back, sometimes jumps, short pauses.
# After GOD MODE ends a big final wave comes in (the "...then it ran out" ending). HUD hidden.
# env: GOD_LEVEL (default 3), GOD_AT (player x, default 2400), GOD_WEAPON (weapon_db id, default 10 = ASSAULT SHOTGUN),
#      REC_POS=<csv>: t, player position on screen (follow-cam), kills, GOD MODE seconds left, fired (0/1), fresh corpses
#      ("id/age/x/y" joined by |, screen space, for 1.2 s after each kill: lets the edit swing the camera to the zombie that got shot),
#      PREVIEW=<png>: save one frame at f=50 and quit.
# He fires ONE shot about every second (FIRE_GAP), so the camera has time to swing to the zombie that got hit and back.
# usage: REC_POS=/tmp/g.csv xvfb-run -a -s "-screen 0 2560x1440x24" godot --path . --rendering-driver opengl3 --resolution 2560x1440 \
#        --write-movie /tmp/g.avi --fixed-fps 60 -s res://t_rec_god.gd
const GOD_F := 150               # drinks the potion (2.5 s in)
const WAVES := [[90, 1, 3], [170, -1, 3], [240, 1, 4], [320, -1, 4], [400, 1, 4], [480, -1, 4], [560, 1, 5], [640, -1, 4],
	[720, 1, 5], [800, -1, 4], [880, 1, 5], [950, -1, 4]]   # [frame, side, count]
const FINAL_F := 1010            # the big wave after GOD MODE ends (god ends ~f 978)
const END_F := 1260
const FIRE_GAP := [40, 52]       # frames between shots (camera swing rhythm)
var f := 0
var main_node: Node = null
var pl = null
var keys := {}
var pos_file: FileAccess = null
var at_x := 2400.0
var weapon := 10
var _rng := RandomNumberGenerator.new()
var _pause := 0
var _move := 0                   # -1 / 0 / 1
var _move_left := 0
var _aim := Vector2.RIGHT
var _next_fire := 0
var _fired := false
var _alive := {}                 # instance id -> zombie (alive last frame)
var _died := {}                  # instance id -> [zombie, death frame]

func _initialize() -> void:
	var g = root.get_node("Game")
	g.new_run()
	g.level = int(OS.get_environment("GOD_LEVEL")) if OS.get_environment("GOD_LEVEL") != "" else 3
	main_node = load("res://main.tscn").instantiate()
	root.add_child(main_node)
	current_scene = main_node
	at_x = float(OS.get_environment("GOD_AT")) if OS.get_environment("GOD_AT") != "" else at_x
	weapon = int(OS.get_environment("GOD_WEAPON")) if OS.get_environment("GOD_WEAPON") != "" else weapon
	if OS.get_environment("REC_POS") != "":
		pos_file = FileAccess.open(OS.get_environment("REC_POS"), FileAccess.WRITE)
	_rng.seed = 31

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

func _spawn(side: int, n: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = f
	for i in n:
		var k: int = main_node._pick_kind(rng)
		var x: float = pl.global_position.x + float(side) * (470.0 + 55.0 * i + rng.randf_range(0.0, 40.0))
		var z = main_node._spawn_zombie(x, pl.global_position.y - 4.0, k, null)
		if z != null:
			z.dormant = false
			if z.is_boss():
				z.queue_free()
	root.get_node("Game").make_noise(pl.global_position, 1400.0)

func _physics_process(_d: float) -> bool:
	f += 1
	pl = main_node.get_tree().get_first_node_in_group("player")
	if pl == null:
		return false
	pl.health = pl.max_health
	pl._invuln = maxf(pl._invuln, 0.5)
	var mb := AudioServer.get_bus_index("Music")
	if mb >= 0:
		AudioServer.set_bus_mute(mb, true)
	if f == 3:
		pl.global_position.x = at_x
		pl.slots[0] = {"id": weapon, "ammo": 999, "mag": 8}
		pl.select_slot(0)
	if f == (int(OS.get_environment("PREVIEW_F")) if OS.get_environment("PREVIEW_F") != "" else 50) and OS.get_environment("PREVIEW") != "":
		root.get_viewport().get_texture().get_image().save_png(OS.get_environment("PREVIEW"))
		quit()
	for s in main_node.get_tree().get_nodes_in_group("story_scene"):
		if s.has_method("_finish"):
			s._finish()
	if f % 10 == 1:
		for n in main_node.find_children("*", "CanvasLayer", true, false):
			if n.layer >= 2:
				n.visible = false
	if f % 10 == 8 and f < 80:
		for o in main_node.get_tree().get_nodes_in_group("zombies"):
			if absf(o.global_position.x - at_x) < 2200.0:
				o.queue_free()
	for w in WAVES:
		if f == int(w[0]):
			_spawn(int(w[1]), int(w[2]))
	if f == FINAL_F:
		_spawn(1, 9)
		_spawn(-1, 5)
	if f == GOD_F:
		pl._drink_god()
		print("f=%d GOD MODE" % f)
	if pl.slots[0] != null:   # no reloads in the clip (pace)
		pl.slots[0].ammo = 999
		pl.slots[0].mag = 8
	# ---- the "player": nearest zombie, turn, aim with a little lag, shoot; small steps and pauses ----
	var tgt = null
	var bd := INF
	for z in main_node.get_tree().get_nodes_in_group("zombies"):
		if z.dead or not is_instance_valid(z):
			continue
		var dx: float = z.global_position.x - pl.global_position.x
		if absf(dx) > 900.0:
			continue
		var s := absf(dx) + (60.0 if signf(dx) != pl._face() else 0.0)
		if s < bd:
			bd = s
			tgt = z
	if _pause > 0:
		_pause -= 1
	elif f > 60 and _rng.randf() < 0.004:
		_pause = _rng.randi_range(12, 25)   # a short breath
	if tgt != null:
		var aim_p: Vector2 = tgt.global_position + Vector2(0.0, -30.0 * float(tgt.sc))
		var want: Vector2 = (aim_p - (pl.global_position + pl._front_shoulder())).normalized()
		_aim = _aim.slerp(want, 0.25)
		pl._aim = _aim
		if _pause <= 0 and f >= _next_fire and absf(_aim.angle_to(want)) < 0.25 and absf(tgt.global_position.x - pl.global_position.x) < 620.0:
			pl._fire_test = true
			_fired = true
			_next_fire = f + _rng.randi_range(FIRE_GAP[0], FIRE_GAP[1])
		var dx: float = tgt.global_position.x - pl.global_position.x
		# step back when they get close, step in when it is quiet
		if _move_left <= 0:
			_move = 0
			if absf(dx) < 150.0:
				_move = -int(signf(dx))
				_move_left = _rng.randi_range(14, 26)
			elif absf(dx) > 520.0 and _rng.randf() < 0.02:
				_move = int(signf(dx))
				_move_left = _rng.randi_range(10, 20)
			elif _rng.randf() < 0.01:
				_move = -int(signf(dx))
				_move_left = _rng.randi_range(8, 14)
	else:
		_aim = _aim.slerp(Vector2(pl._face(), -0.05).normalized(), 0.1)
		pl._aim = _aim
	_move_left -= 1
	_key(KEY_A, _move < 0)
	_key(KEY_D, _move > 0)
	_key(KEY_W, f > 200 and f % 211 < 6)   # a jump now and then
	# who died this frame (alive last frame, dead or gone now)
	for id in _alive:
		var z = _alive[id]
		if is_instance_valid(z) and z.dead and not _died.has(id):
			_died[id] = [z, f]
	_alive.clear()
	for z in main_node.get_tree().get_nodes_in_group("zombies"):
		if not z.dead:
			_alive[z.get_instance_id()] = z
	if pos_file != null:
		var xf: Transform2D = main_node.get_viewport().get_canvas_transform()
		var sp: Vector2 = xf * pl.global_position
		var fresh := PackedStringArray()
		for id in _died.keys():
			var d: Array = _died[id]
			if f - int(d[1]) > 72 or not is_instance_valid(d[0]):
				_died.erase(id)
				continue
			var zp: Vector2 = xf * (d[0].global_position + Vector2(0.0, -30.0 * float(d[0].sc)))
			fresh.append("%d/%d/%d/%d" % [id % 1000000, f - int(d[1]), zp.x, zp.y])
		pos_file.store_line("%.4f,%d,%d,%d,%.2f,%d,%s" % [f / 60.0, sp.x, sp.y, int(root.get_node("Game").stats.kills),
			float(pl.boosts.get(preload("res://pickup.gd").GOD, 0.0)), int(_fired), "|".join(fresh)])   # + kills, GOD MODE time left, fired, fresh corpses
	_fired = false
	if f % 60 == 0:
		var n := 0
		for z in main_node.get_tree().get_nodes_in_group("zombies"):
			if not z.dead:
				n += 1
		var near := 0
		for z in main_node.get_tree().get_nodes_in_group("zombies"):
			if not z.dead and absf(z.global_position.x - pl.global_position.x) < 700.0:
				near += 1
		print("f=%d x=%d god=%s alive=%d near=%d kills=%d" % [f, pl.global_position.x, str(pl.god_mode()), n, near, int(root.get_node("Game").stats.kills)])
	if f >= END_F:
		if pos_file != null:
			pos_file.flush()
		quit()
	return false
