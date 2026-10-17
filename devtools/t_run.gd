extends SceneTree
# usage: godot --path . -s res://t_run.gd -- level frames shot.png [px_offset]
var frames := 0
var total := 300
var shot := ""
var lv := 45
var px := 0.0
var main_node: Node = null

func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	lv = int(a[0]) if a.size() > 0 else 45
	total = int(a[1]) if a.size() > 1 else 300
	shot = a[2] if a.size() > 2 else ""
	px = float(a[3]) if a.size() > 3 else 0.0
	var g = root.get_node("Game")
	g.new_run()
	g.level = lv
	g.start_practice(lv) if g.has_method("start_practice") else null
	g.level = lv
	main_node = load("res://main.tscn").instantiate()
	root.add_child(main_node)
	current_scene = main_node

func _process(_d: float) -> bool:
	frames += 1
	if frames == 5 and px > 0.0:
		var pl = root.get_tree().get_first_node_in_group("player") if false else main_node.get_tree().get_first_node_in_group("player")
		if pl != null:
			pl.global_position.x = px
	if frames % 60 == 0:
		var zs = main_node.get_tree().get_nodes_in_group("zombies")
		var kinds := {}
		for z in zs:
			kinds[z.kind] = int(kinds.get(z.kind, 0)) + 1
		var pl = main_node.get_tree().get_first_node_in_group("player")
		print("frame ", frames, " zombies ", zs.size(), " player ", pl.global_position if pl else null, " hp ", pl.health if pl else -1, " kinds ", kinds)
	if frames >= total:
		if shot != "":
			var img := root.get_viewport().get_texture().get_image()
			img.save_png(shot)
			print("saved ", shot)
		quit()
	return false
