extends SceneTree
# args: outdir lv1 lv2 ...   -> outdir/NNs.png (התחלה) + outdir/NNm.png (אמצע)
var frames := 0
var lv := 1
var outdir := ""
var queue := []
var M: Node = null
var pl: Node = null
const SHOT1 := 100
const MOVE := 102
const SHOT2 := 180
var t0 := 0

func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	outdir = a[0]
	for i in range(1, a.size()):
		queue.append(int(a[i]))
	Engine.max_fps = 0
	_next()

func _next() -> void:
	if M != null:
		M.queue_free()
		M = null
	pl = null
	frames = 0
	if queue.is_empty():
		quit()
		return
	lv = queue.pop_front()
	if FileAccess.file_exists(outdir + "/%02dm.png" % lv):   # כבר צולם
		_next()
		return
	t0 = Time.get_ticks_msec()
	var g = root.get_node("Game")
	g.new_run()
	g.level = lv
	g.start_practice(lv)
	g.level = lv
	g.attempt_seed = 7000 + lv
	for sc in load("res://story/story_db.gd").for_level(lv):
		g.story_seen[sc.id] = true
	M = load("res://main.tscn").instantiate()
	root.add_child(M)
	current_scene = M

func _bring(px: float) -> void:
	var zs := []
	for z in M.get_tree().get_nodes_in_group("zombies"):
		if not z.is_boss() and not z.dead:
			zs.append(z)
	zs.sort_custom(func(a, b): return absf(a.global_position.x - px) < absf(b.global_position.x - px))
	var offs := [260.0, 420.0, -320.0]
	for i in mini(3, zs.size()):
		var z = zs[i]
		z.global_position = Vector2(pl.global_position.x + offs[i], z.global_position.y - 120.0)
		z.dormant = false

func _process(_d: float) -> bool:
	if M == null:
		return false
	frames += 1
	if pl == null:
		pl = M.get_tree().get_first_node_in_group("player")
		if pl == null and frames > 300:
			print("FAIL no player ", lv)
			_next()
		return false
	pl._invuln = 99.0
	pl.health = maxi(pl.health, 3)
	if frames == 4:
		_bring(pl.global_position.x + 400.0)
	if frames == SHOT1:
		root.get_viewport().get_texture().get_image().save_png(outdir + "/%02ds.png" % lv)
	if frames == MOVE:
		pl.global_position = Vector2(M.level_w * 0.5, pl.global_position.y - 200.0)
		pl.velocity = Vector2.ZERO
		var cam := root.get_viewport().get_camera_2d()
		if cam: cam.reset_smoothing()
		_bring(pl.global_position.x)
	if frames == SHOT2:
		root.get_viewport().get_texture().get_image().save_png(outdir + "/%02dm.png" % lv)
		print("saved ", lv, " ms ", Time.get_ticks_msec() - t0)
		_next()
	return false
