extends SceneTree
# CLIMBER spider test (enemies/types/climber.gd, level 5): one CLIMBER walks up, gets shot once (not killed),
# grows spider legs and starts its high jumps. Prints its state every 10 frames, then "SPIDER transforms=.. leaps=.. hurt=..".
# usage: godot --headless --path . -s res://t_spider.gd
#        xvfb-run -a -s "-screen 0 1280x720x24" godot --fixed-fps 60 --path . --rendering-driver opengl3 -s res://t_spider.gd -- <png_prefix> [zoom] [frames...]
const X := 2200.0
var f := 0
var main_node: Node = null
var z = null
var prefix := ""
var zoom := 2.4
var shots := [70, 85, 100, 140, 180, 220, 260]
var hp0 := 0
var max_f := 600

func _initialize() -> void:
	var g = root.get_node("Game")
	g.new_run()
	g.level = 5
	main_node = load("res://main.tscn").instantiate()
	root.add_child(main_node)
	current_scene = main_node
	var a := OS.get_cmdline_user_args()
	if a.size() > 0:
		prefix = a[0]
	if a.size() > 1:
		zoom = float(a[1])
	if a.size() > 2:
		shots = []
		for i in range(2, a.size()):
			shots.append(int(a[i]))
		max_f = shots.max() + 1

func _physics_process(_d: float) -> bool:
	f += 1
	var pl = main_node.get_tree().get_first_node_in_group("player")
	if pl == null:
		return false
	if f == 5:
		pl.global_position.x = X
	for s in main_node.get_tree().get_nodes_in_group("story_scene"):
		if s.has_method("_finish"):
			s._finish()
	if f % 20 == 1:
		for n in main_node.find_children("*", "CanvasLayer", true, false):
			if n.layer >= 2:
				n.visible = false
	if f % 10 == 8 and f < 60:
		for o in main_node.get_tree().get_nodes_in_group("zombies"):
			if absf(o.global_position.x - X) < 1600.0 and o != z:
				o.queue_free()
	if prefix != "":
		var cam := main_node.get_viewport().get_camera_2d()
		if cam != null and "_base_zoom" in cam:
			cam._base_zoom = Vector2(zoom, zoom)
			cam.zoom = cam._base_zoom
			if z != null and is_instance_valid(z) and OS.get_environment("SPIDER_FOCUS") != "":   # camera on the zombie
				cam.base_offset = z.global_position - pl.global_position + Vector2(0, -60)
	if f == 30:
		z = main_node._spawn_zombie(X + 260.0, pl.global_position.y, 20, null)
		z.dormant = false
		hp0 = pl.health
	if z != null and is_instance_valid(z) and not z.dead:
		var sh: Vector2 = pl.global_position + pl._front_shoulder()
		pl._aim = (z.global_position + Vector2(0, -24) - sh).normalized()
		if f == 75:   # one light hit: not lethal
			print("hit: hp before ", z.hp)
			z.take_damage(6, z.global_position + Vector2(0, -26), Vector2(1, 0), false, {"source": "bullet", "fixed": 6})
		if f % 10 == 0:
			var tm = z.type_mod
			print("f=%d state=%d grow=%.2f hp=%d pos=%s vel=%s" % [f, tm.state, tm.grow, z.hp, str(z.global_position.round()), str(z.velocity.round())])
	if f % 2 == 0:
		pl.health = maxi(pl.health, 1)
	if prefix != "" and f in shots:
		root.get_viewport().get_texture().get_image().save_png("%s_%d.png" % [prefix, f])
	if z != null and not is_instance_valid(z):
		print("f=%d zombie gone" % f)
		z = null
	elif z != null and z.dead and f % 10 == 0:
		print("f=%d zombie dead" % f)
	if f >= max_f:
		var tm = z.type_mod if z != null and is_instance_valid(z) else null
		print("SPIDER transforms=%d leaps=%d hurt=%d" % [tm.transforms if tm else -1, tm.leaps if tm else -1, hp0 - pl.health])
		quit()
	return false
