extends SceneTree
# PROMO CLIPS (test only): staged moments for Shorts, HUD hidden. Record with --write-movie (see devtools/README.md).
# usage: godot ... -s res://t_promo.gd -- <mode> [level] [x]
#   deaths: 5 zombies walk up one at a time and the player shoots each; each dies a different special death
#           (torn in half, headless walk, burst into chunks, crawling torso, burned to bones). Prints "CUE t=.. name".
#   booms:  3 rounds of 4 zombies, each round ends in a different explosion style (fireball, shrapnel, fire pillar).
# PROMO_SHOT=<png prefix> saves a frame at every cue + 0.5 s (for checking the framing headless-free).
var mode := "deaths"
var lv := 5
var px := 2200.0
var f := 0
var main_node: Node = null
var pl: Node = null
var cur: Array = []          # zombies of the current round
var plan := []               # [frame, callable]
var aim_at = null            # zombie the player keeps aiming at

const DEATHS := [["TORN IN HALF", "force_tear", "body"], ["HEADLESS WALK", "force_hw", "head"], ["BURST INTO CHUNKS", "force_burst", "boom"],
	["CRAWLING TORSO", "force_crawl", "leg"], ["BURNED TO BONES", "force_char", "fire"]]

func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	mode = a[0] if a.size() > 0 else mode
	lv = int(a[1]) if a.size() > 1 else lv
	px = float(a[2]) if a.size() > 2 else px
	var g = root.get_node("Game")
	g.new_run()
	g.level = lv
	main_node = load("res://main.tscn").instantiate()
	root.add_child(main_node)
	current_scene = main_node

func _cue(name: String) -> void:
	print("CUE t=%.2f %s" % [f / 60.0, name])

func _spawn(dx: float, kind: int, meta: String) -> Node:
	var z = main_node._spawn_zombie(pl.global_position.x + dx, pl.global_position.y, kind, null)
	z.dormant = false
	if meta != "":
		z.set_meta(meta, true)
	return z

func _shoot(z: Node, how: String) -> void:
	if not is_instance_valid(z) or z.dead:
		return
	var hy: float = {"head": -52.0, "leg": -8.0, "body": -30.0, "fire": -30.0, "boom": -30.0}[how] * float(z.sc)
	var at: Vector2 = z.global_position + Vector2(0, hy)
	var sh: Vector2 = pl.global_position + pl._front_shoulder()
	pl._aim = (at - sh).normalized()
	pl._fire_test = true   # muzzle flash + gun sound
	var heavy := how == "boom"
	if heavy:
		z.heavy_kill = true
		z.global_position.x = minf(z.global_position.x, pl.global_position.x + 150.0)
	z.take_damage(999, at, Vector2(1, -0.2), heavy, {"source": "fire" if how == "fire" else "bullet", "fixed": 999})

func _physics_process(_d: float) -> bool:
	f += 1
	pl = main_node.get_tree().get_first_node_in_group("player")
	if pl == null:
		return false
	pl.health = pl.max_health
	for s in main_node.get_tree().get_nodes_in_group("story_scene"):
		if s.has_method("_finish"):
			s._finish()
	if f % 20 == 1:   # HUD and streak meter off: the Short's captions carry the text
		for n in main_node.find_children("*", "CanvasLayer", true, false):
			if n.layer >= 2:
				n.visible = false
	var cam := main_node.get_viewport().get_camera_2d()
	var zm := float(OS.get_environment("PROMO_ZOOM")) if OS.get_environment("PROMO_ZOOM") != "" else 1.0
	if cam != null and zm != 1.0 and "_base_zoom" in cam:   # closer camera = crisper characters in a vertical crop
		cam._base_zoom = Vector2(zm, zm)
		if f % 2 == 0 and cam.zoom.x < zm * 0.99:
			cam.zoom = cam._base_zoom
	if f % 3 == 0 and OS.get_environment("PROMO_POS") != "":
		print("POS t=%.3f %s" % [f / 60.0, str(pl.get_global_transform_with_canvas().origin)])
	if f == 5:
		pl.global_position.x = px
	if f % 10 == 8 and f < 60:
		for z in main_node.get_tree().get_nodes_in_group("zombies"):
			if absf(z.global_position.x - px) < 1600.0 and not z.is_boss() and not z in cur:
				z.queue_free()
	if f == 60:
		_make_plan()
	if aim_at != null and is_instance_valid(aim_at) and not aim_at.dead:   # gun follows the zombie
		var sh: Vector2 = pl.global_position + pl._front_shoulder()
		pl._aim = (aim_at.global_position + Vector2(0, -34.0 * aim_at.sc) - sh).normalized()
		pl._fire_test = true
		pl._cooldown = maxf(pl._cooldown, 0.05)   # aim without firing
	for p in plan:
		if p[0] == f:
			p[1].call()
	var shot := OS.get_environment("PROMO_SHOT")
	if shot != "" and f in _shot_frames:
		root.get_viewport().get_texture().get_image().save_png("%s_%d.png" % [shot, f])
	if f >= _end_f:
		quit()
	return false

var _shot_frames := []
var _end_f := 99999

func _at(frame: int, c: Callable) -> void:
	plan.append([frame, c])

func _make_plan() -> void:
	var t := 70
	if mode == "deaths":
		for i in DEATHS.size():
			var d: Array = DEATHS[i]
			var kind: int = [0, 0, 1, 0, 0][i]
			_at(t, func():
				var z := _spawn(250.0, kind, d[1])
				aim_at = z
				cur = [z]
				_cue("spawn " + d[0]))
			_at(t + 48, func():
				_cue("kill " + d[0])
				_shoot(cur[0], d[2])
				aim_at = null)
			_shot_frames.append(t + 48 + 30)
			if d[2] == "leg":   # the crawler keeps coming: finish it with a headshot
				_at(t + 48 + 110, func():
					if is_instance_valid(cur[0]) and not cur[0].dead:
						_cue("finish crawler")
						_shoot(cur[0], "head"))
				t += 110
			t += 48 + 100
		_end_f = t + 60
	else:
		for i in 3:
			var style := i
			_at(t, func():
				cur = []
				for k in 4:
					cur.append(_spawn(230.0 + 30.0 * k, [0, 1, 0, 2][k], "force_burst" if k % 2 == 0 else ""))
				_cue("round %d" % (style + 1)))
			_at(t + 55, func():
				OS.set_environment("BOOM_STYLE", str(style))
				var c := Vector2.ZERO
				var n := 0
				for z in cur:
					if is_instance_valid(z) and not z.dead:
						c += z.global_position
						n += 1
				c = c / maxf(1.0, float(n)) + Vector2(0, -6)
				_cue("boom %d" % (style + 1))
				load("res://explosion.gd").blast(main_node, c, 130.0, 60.0, 999, 0, "grenade"))
			_shot_frames.append(t + 55 + 12)
			t += 55 + 110
		_end_f = t + 60
