extends SceneTree
# CORPSES (test only): kills a row of zombies next to the player, then saves a zoomed crop. args: out.png [kinds] [zoom]
var out := "/tmp/c.png"
var kinds := [0, 1, 0, 4, 0, 16, 3, 0]
var zoom := 2.5
var main_node: Node
var pl: Node
var f := 0
var zs := []

func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	out = a[0]
	if a.size() > 1:
		kinds = []
		for s in a[1].split(","):
			kinds.append(int(s))
	zoom = float(a[2]) if a.size() > 2 else 2.5
	var g = root.get_node("Game")
	g.new_run()
	g.start_practice(1)
	g.level = 1
	g.attempt_seed = 77
	seed(3)
	main_node = load("res://main.tscn").instantiate()
	root.add_child(main_node)
	current_scene = main_node

func _process(_d: float) -> bool:
	f += 1
	if pl == null:
		pl = main_node.get_tree().get_first_node_in_group("player")
		return false
	for s in main_node.get_tree().get_nodes_in_group("story_scene"):
		if s.has_method("_finish"):
			s._finish()
	pl._invuln = 99.0
	if f == 20:
		for z in main_node.get_tree().get_nodes_in_group("zombies"):
			z.queue_free()
		pl.global_position.x = 2600.0
	if f == 30:
		for i in kinds.size():
			zs.append(main_node._spawn_zombie(pl.global_position.x + 140.0 + i * 26.0, pl.global_position.y, kinds[i], null))
	if f >= 28 and f < 120 and f % 4 == 0:
		var nv := 0
		var nd := 0
		for z in zs:
			if is_instance_valid(z):
				nv += 1
				nd += 1 if z.dead else 0
		print("f=", f, " valid=", nv, " dead=", nd, " of ", zs.size())
	if f >= 50 and f % 3 == 0 and f < 120:
		for z in zs:
			if is_instance_valid(z) and z.dead:
				print("  f=", f, " k=", z.kind, " pos=", z.global_position.round(), " dt=", snappedf(z._dead_t, 0.01), " rag=", z._rag != null, " ct=", z.corpse_time)
	if f > 30 and f < 50:
		for z in zs:
			z.walk_speed = 0.0
			z.chase_speed = 0.0
			z.velocity = Vector2.ZERO
	if f >= 50 and f < 50 + zs.size() * 20 and (f - 50) % 20 == 0:
		for i in [(f - 50) / 20]:
			var z = zs[i]
			if is_instance_valid(z) and not z.dead:
				var hy := -50.0 if i % 2 == 0 else -30.0
				z.take_damage(int(z.hp), z.global_position + Vector2(0, hy * z.sc), Vector2(0.0, 1.0), false, {"source": "bullet", "knockback": 0.0, "fixed": int(z.hp)})
	if f == 50 + zs.size() * 20 + 57:
		var i := 0
		for z in zs:
			if is_instance_valid(z):
				z.scale = Vector2(3.0, 3.0)
				z.global_position = Vector2(pl.global_position.x + 120.0 + i * 70.0, pl.global_position.y - 70.0)
				z.z_index = 50
				i += 1
	if f == 50 + zs.size() * 20 + 60:
		var img := root.get_viewport().get_texture().get_image()
		var cx := 0.0
		var cy := 0.0
		var nn := 0
		for z in zs:
			if is_instance_valid(z):
				nn += 1
				cx += z.global_position.x
				cy += z.global_position.y
				print(" z ", z.kind, " ", z.global_position, " dead=", z.dead, " vis=", z.visible)
		cx /= maxf(nn, 1)
		cy /= maxf(nn, 1)
		print("corpses at ", cx, " ", cy, " player ", pl.global_position)
		var sp: Vector2 = root.get_viewport().get_canvas_transform() * Vector2(cx, cy)
		var vs := Vector2(img.get_width(), img.get_height()) / root.get_viewport().get_visible_rect().size
		sp *= vs
		var w := int(620.0 * vs.x)
		var h := int(120.0 * vs.y)
		var x0 := clampi(int(sp.x) - w / 2, 0, img.get_width() - w)
		var y0 := clampi(int(sp.y) - int(h * 0.5), 0, img.get_height() - h)
		var crop := img.get_region(Rect2i(x0, y0, w, h))
		crop.resize(int(w * 1.5), int(h * 1.5), Image.INTERPOLATE_BILINEAR)
		crop.save_png(out)
		print("saved ", out)
		quit()
	return false
