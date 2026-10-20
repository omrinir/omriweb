extends SceneTree
# Torn-in-half test: level 3 (LV), kills 4 zombies next to the player with force_tear and saves PNGs.
# usage: xvfb-run -a -s "-screen 0 1280x720x24" godot --fixed-fps 60 --path . --rendering-driver opengl3 -s res://t_tear.gd -- <png_prefix> [frames...]
#        headless (no PNGs): godot --headless --fixed-fps 60 --path . -s res://t_tear.gd -- none
const LV := 3
var f := 0
var main_node: Node = null
var zs := []
var shots := [12, 24, 40, 70]

func _initialize() -> void:
	var g = root.get_node("Game")
	g.new_run()
	g.level = LV
	g.start_practice(LV) if g.has_method("start_practice") else null
	g.level = LV
	main_node = load("res://main.tscn").instantiate()
	root.add_child(main_node)
	current_scene = main_node
	var a := OS.get_cmdline_user_args()
	if a.size() > 1:
		shots = []
		for i in range(1, a.size()):
			shots.append(int(a[i]))

func _physics_process(_d: float) -> bool:
	f += 1
	var a := OS.get_cmdline_user_args()
	var pl = main_node.get_tree().get_first_node_in_group("player")
	if pl == null:
		return false
	pl.health = pl.max_health
	for s in main_node.get_tree().get_nodes_in_group("story_scene"):   # skip story scenes
		if s.has_method("_finish"):
			s._finish()
	if f == 5:
		pl.global_position.x = 5600.0
		for z in main_node.get_tree().get_nodes_in_group("zombies"):   # clear the area
			if absf(z.global_position.x - 5600.0) < 900.0 and not z.is_boss():
				z.queue_free()
	if f == 60:
		for i in 4:
			var z = main_node._spawn_zombie(5600.0 + 140.0 + 70.0 * i, pl.global_position.y, [0, 1, 2, 0][i], null)
			z.set_meta("force_tear", true)
			zs.append(z)
	if f == 64:
		for z in zs:
			z.take_damage(999, z.global_position + Vector2(0, -30), Vector2(1, -0.2), false, {"source": "bullet", "fixed": 999})
			print("killed kind=%d dead=%s rag=%s split=%s" % [z.kind, str(z.dead), str(z._rag), str(z._rag != null and z._rag.split)])
	if f > 64 and (f - 64) in shots and a.size() > 0 and a[0] != "none":
		var path := "%s_%d.png" % [a[0], f - 64]
		root.get_viewport().get_texture().get_image().save_png(path)
		print("saved ", path)
	if f % 30 == 0 and f > 64:
		for z in zs:
			if is_instance_valid(z) and z._rag != null:
				var r = z._rag
				print("f+%d kind=%d waist=%s pelvis=%s asleep=%s" % [f - 64, z.kind, str(r.p[r.WAIST].round()), str(r.p[r.PELVIS].round()), str(r.asleep)])
	if f >= 64 + 240:
		quit()
	return false
