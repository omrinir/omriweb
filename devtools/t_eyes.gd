extends SceneTree
# EYES IN THE DARK (test only): effects/dark_eyes.gd on a dark level (2, 4, 11, 14, 26, 29, 54).
# The level's zombies are removed, the eyes are forced to show, a picture is saved when they are fully open,
# then the player walks toward them and the script prints whether they closed and went away.
# usage (picture needs a window): xvfb-run -a godot --rendering-driver opengl3 --fixed-fps 60 --path . -s res://t_eyes.gd -- [level 11] [/tmp/eyes.png]
var lv := 11
var shot := ""
var main_node: Node
var pl: Node
var eyes: Node = null
var f := 0
var seen := -1


func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	lv = int(a[0]) if a.size() > 0 else lv
	shot = a[1] if a.size() > 1 else ""
	Input.use_accumulated_input = false
	var g = root.get_node("Game")
	g.new_run()
	g.level = lv
	main_node = load("res://main.tscn").instantiate()
	root.add_child(main_node)
	current_scene = main_node


func _process(_d: float) -> bool:
	f += 1
	pl = main_node.get_tree().get_first_node_in_group("player")
	if pl == null:
		return false
	pl.health = pl.max_health
	for s in main_node.get_tree().get_nodes_in_group("story_scene"):
		if s.has_method("_finish"):
			s._finish()
	if f % 10 == 0:
		for z in main_node.get_tree().get_nodes_in_group("zombies"):
			z.queue_free()
	if eyes == null:
		for n in main_node.get_children():
			if n is CanvasLayer and n.get_child_count() > 0 and n.get_child(0).get_script() == load("res://effects/dark_eyes.gd"):
				eyes = n.get_child(0)
		if f == 30 and eyes == null:
			print("EYES none on level ", lv, " (not a dark level?)")
			quit()
		return false
	if f == 300:
		pl.global_position.x += 400.0   # מהאזור הבטוח קצת קדימה
		pl.reset_physics_interpolation()
	if f > 330 and seen < 0:
		eyes._calm = 99.0
		eyes._next = 0.0
		if not eyes._pairs.is_empty():
			seen = f
			var e: Array = eyes._pairs[0]
			print("EYES showing at %s (player %s), %d pair(s), color %s" % [e[0].round(), pl.global_position.round(), eyes._pairs.size(), e[2]])
	if seen > 0 and f == seen + 40:
		if shot != "":
			root.get_viewport().get_texture().get_image().save_png(shot)
			print("EYES saved ", shot)
		var k := KEY_D if (eyes._pairs[0][0] as Vector2).x > pl.global_position.x else KEY_A
		var e := InputEventKey.new()
		e.physical_keycode = k
		e.pressed = true
		Input.parse_input_event(e)   # הולך לכיוונן
	if seen > 0 and f > seen + 40 and eyes._pairs.is_empty():
		print("EYES gone %.2f s after the walk started (player %s)" % [float(f - seen - 40) / 60.0, pl.global_position.round()])
		print("EYES done")
		quit()
	if seen > 0 and f > seen + 400:
		print("EYES still there after 6 s?")
		quit()
	if f > 1200:
		print("EYES never showed")
		quit()
	return false
