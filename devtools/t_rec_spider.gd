extends SceneTree
# PROMO CLIP (test only): the level 5 CLIMBER spider moment, staged with real game mechanics, for --write-movie.
# The player shoots a CLIMBER once (it survives and grows spider legs), holds fire while it leaps (SPIDER_LEAPS leaps),
# then shoots it down. HUD hidden. REC_POS=<csv> writes the midpoint between player and spider on screen (follow-cam).
# env: SPIDER_LEAPS (default 1), SPIDER_X (spawn distance, default 470), SPIDER_AT (player x), REC_CAM=1 + REC_ZOOM: move the game camera too.
# usage: REC_POS=/tmp/s.csv xvfb-run -a -s "-screen 0 2560x1440x24" godot --path . --rendering-driver opengl3 --resolution 2560x1440 \
#        --write-movie /tmp/s.avi --fixed-fps 60 -s res://t_rec_spider.gd
var f := 0
var main_node: Node = null
var pl = null
var z = null
var leaps_wanted := 1
var killing := false
var end_f := -1
var pos_file: FileAccess = null
var zoom := 1.4
var at_x := 2200.0
var spawn_dx := 470.0
var mid := Vector2.ZERO

func _initialize() -> void:
	var g = root.get_node("Game")
	g.new_run()
	g.level = 5
	main_node = load("res://main.tscn").instantiate()
	root.add_child(main_node)
	current_scene = main_node
	leaps_wanted = int(OS.get_environment("SPIDER_LEAPS")) if OS.get_environment("SPIDER_LEAPS") != "" else 1
	zoom = float(OS.get_environment("REC_ZOOM")) if OS.get_environment("REC_ZOOM") != "" else zoom
	at_x = float(OS.get_environment("SPIDER_AT")) if OS.get_environment("SPIDER_AT") != "" else at_x
	spawn_dx = float(OS.get_environment("SPIDER_X")) if OS.get_environment("SPIDER_X") != "" else spawn_dx
	if OS.get_environment("REC_POS") != "":
		pos_file = FileAccess.open(OS.get_environment("REC_POS"), FileAccess.WRITE)

func _aim_at(p: Vector2, fire: bool) -> void:
	var sh: Vector2 = pl.global_position + pl._front_shoulder()
	pl._aim = (p - sh).normalized()
	pl._fire_test = true
	if not fire:
		pl._cooldown = maxf(pl._cooldown, 0.05)
	elif not killing:
		pl._cooldown = minf(pl._cooldown, 0.0)   # the single opening shot

func _physics_process(_d: float) -> bool:
	f += 1
	pl = main_node.get_tree().get_first_node_in_group("player")
	if pl == null:
		return false
	pl.health = pl.max_health
	var mb := AudioServer.get_bus_index("Music")
	if mb >= 0:
		AudioServer.set_bus_mute(mb, true)
	if f == 3:
		pl.global_position.x = at_x
	for s in main_node.get_tree().get_nodes_in_group("story_scene"):
		if s.has_method("_finish"):
			s._finish()
	if f % 10 == 1:
		for n in main_node.find_children("*", "CanvasLayer", true, false):
			if n.layer >= 2:
				n.visible = false
	if f % 10 == 8 and f < 70:
		for o in main_node.get_tree().get_nodes_in_group("zombies"):
			if absf(o.global_position.x - at_x) < 1500.0 and o != z:
				o.queue_free()
	if f == 30:
		z = main_node._spawn_zombie(at_x + spawn_dx, pl.global_position.y - 4.0, 20, null)
		z.dormant = false
		root.get_node("Game").make_noise(pl.global_position, 900.0)
		print("spawn")
	var alive: bool = z != null and is_instance_valid(z) and not z.dead
	if alive:
		var tm = z.type_mod
		var tgt: Vector2 = z.global_position + Vector2(0, -24.0 * z.sc)
		if f >= 40 and tm.transforms == 0:
			_aim_at(tgt, f >= 70 and f % 30 == 10 and absf(z.global_position.x - pl.global_position.x) < 330.0)   # one shot when it is close (it survives one)
		elif tm.transforms > 0:
			if not killing and tm.leaps >= leaps_wanted and tm.state == 4 and z.velocity.y > 0.0:
				killing = true
				print("f=%d kill starts (leaps=%d)" % [f, tm.leaps])
			if not killing and tm.leaps >= leaps_wanted and tm.state == 2 and f % 1 == 0:
				killing = true
			_aim_at(tgt, killing)
	elif z != null and end_f < 0 and f > 40:
		end_f = f + 70
		print("f=%d spider dead" % f)
	# camera: both in frame (midpoint), zoomed in
	var cam := main_node.get_viewport().get_camera_2d()
	var m: Vector2 = pl.global_position
	if alive:
		m = pl.global_position.lerp(z.global_position, 0.5)
	mid = m if mid == Vector2.ZERO else mid.lerp(m, 0.08)
	if cam != null and "_base_zoom" in cam and OS.get_environment("REC_CAM") != "":   # optional: game camera on the midpoint (default: normal camera, the edit follows REC_POS)
		cam._base_zoom = Vector2(zoom, zoom)
		cam.base_offset = mid - pl.global_position + Vector2(0, -70)
	if pos_file != null:
		var xf: Transform2D = main_node.get_viewport().get_canvas_transform()
		var sp: Vector2 = xf * mid
		pos_file.store_line("%.4f,%d,%d" % [f / 60.0, sp.x, sp.y])
	if alive and f % 10 == 0:
		print("f=%d state=%d leaps=%d hp=%d zx=%d px=%d" % [f, z.type_mod.state, z.type_mod.leaps, z.hp, z.global_position.x, pl.global_position.x])
	if (end_f > 0 and f >= end_f) or f > 900:
		if pos_file != null:
			pos_file.flush()
		quit()
	return false
