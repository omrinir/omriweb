extends SceneTree
# placement check: for levels x seeds, after 40 frames: pickups inside solids, zombies inside solid bodies (layer 1)
# usage: -- 1,2,3 1,2,3
var levels := []
var seeds := []
var li := 0
var si := 0
var f := 0
var main_node: Node = null
var tot_p := 0
var tot_z := 0

func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	for s in a[0].split(","):
		levels.append(int(s))
	for s in a[1].split(","):
		seeds.append(int(s))
	_build()

func _build() -> void:
	if main_node != null:
		main_node.queue_free()
		main_node = null
	var g = root.get_node("Game")
	g.new_run()
	g.start_practice(levels[li])
	g.level = levels[li]
	g.attempt_seed = seeds[si]
	seed(seeds[si])
	main_node = load("res://main.tscn").instantiate()
	root.add_child(main_node)
	current_scene = main_node
	f = 0

func _desc(c) -> String:
	if c == null:
		return "?"
	var s: String = c.get_script().resource_path.get_file() if c.get_script() != null else c.get_class()
	return "%s@%s" % [s, str(c.global_position.round())]

func _process(_d: float) -> bool:
	f += 1
	if main_node == null:
		return false
	var pl = main_node.get_tree().get_first_node_in_group("player")
	if pl != null:
		pl._invuln = 99
		pl.set_physics_process(false)
	if f == 40:
		var ss = main_node.get_world_2d().direct_space_state
		var lv: int = levels[li]
		for p in main_node.get_tree().get_nodes_in_group("pickups"):
			var q := PhysicsPointQueryParameters2D.new()
			q.position = p.global_position + Vector2(0, -6)
			q.collision_mask = 1
			var hits: Array = ss.intersect_point(q, 2)
			if not hits.is_empty():
				tot_p += 1
				print("PICK lv=%d seed=%d kind=%s at %s in %s" % [lv, seeds[si], str(p.get("kind")), str(p.global_position.round()), _desc(hits[0].collider)])
		for z in main_node.get_tree().get_nodes_in_group("zombies"):
			if z.dead:
				continue
			var q := PhysicsPointQueryParameters2D.new()
			q.position = z.global_position + Vector2(0, -24.0 * z.sc)
			q.collision_mask = 1
			for h in ss.intersect_point(q, 4):
				if h.collider != z and not (h.collider is CharacterBody2D):
					tot_z += 1
					var nm: String = str(z.type_mod.stats().name) if z.type_mod != null else "k" + str(z.kind)
					print("ZIN lv=%d seed=%d %s at %s in %s" % [lv, seeds[si], nm, str(z.global_position.round()), _desc(h.collider)])
					break
		si += 1
		if si >= seeds.size():
			si = 0
			li += 1
		if li >= levels.size():
			print("TOTAL pickups_in=%d zombies_in=%d" % [tot_p, tot_z])
			quit()
			return false
		_build()
	return false
