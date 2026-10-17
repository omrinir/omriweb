extends SceneTree
# GUN SHOWCASE (test only): args level guns(comma) out_prefix [zoom]
# holds each gun, fires to the right, saves a zoomed screenshot with the muzzle flash on
var lv := 3
var guns := []
var out := "/tmp/g"
var zoom := 3.0
var main_node: Node
var pl: Node
var f := 0
var gi := 0
var gf := 0
var saved := false
var waiting := false

func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	lv = int(a[0])
	for s in a[1].split(","):
		guns.append(int(s))
	out = a[2]
	zoom = float(a[3]) if a.size() > 3 else 3.0
	var g = root.get_node("Game")
	g.new_run()
	g.start_practice(lv)
	g.level = lv
	g.attempt_seed = 77
	g.weapon_slots = [{"id": guns[0], "ammo": 500}, null, null, null, null]
	main_node = load("res://main.tscn").instantiate()
	root.add_child(main_node)
	current_scene = main_node

func _physics_process(_d: float) -> bool:
	f += 1
	if pl == null:
		pl = main_node.get_tree().get_first_node_in_group("player")
		return false
	for s in main_node.get_tree().get_nodes_in_group("story_scene"):
		if s.has_method("_finish"):
			s._finish()
	pl._invuln = 99.0
	if f < 40:
		return false
	if f == 40:
		for z in main_node.get_tree().get_nodes_in_group("zombies"):
			if absf(z.global_position.x - pl.global_position.x) < 700.0:
				z.queue_free()
	gf += 1
	var id: int = guns[gi]
	if pl.slots[0] == null or int(pl.slots[0].id) != id:
		pl.slots[0] = {"id": id, "ammo": 500}
		pl.cur_slot = 0
		pl.weapon = 0
	if pl.ammo < 50:
		pl.slots[0].ammo = 500
	pl._aim = Vector2(1, -0.06).normalized()
	if gf > 20:
		pl._fire_test = true
	# minigun: wait until spun up; others: first frame with a flash after a few shots
	var ready := gf > (70 if int(load("res://weapons/weapon_db.gd").val(id, "spin_up", 0.0) * 100) > 0 else 45)
	if (ready and pl._muzzle_flash > 0.05 or gf > 160) and not waiting:
		waiting = true
		RenderingServer.frame_post_draw.connect(_grab, CONNECT_ONE_SHOT)
	return false

func _grab() -> void:
	var id: int = guns[gi]
	var img := root.get_viewport().get_texture().get_image()
	var sp: Vector2 = root.get_viewport().get_canvas_transform() * pl.global_position
	var vs := Vector2(img.get_width(), img.get_height()) / root.get_viewport().get_visible_rect().size
	sp *= vs
	var w := int(260.0 * vs.x)
	var h := int(130.0 * vs.y)
	var x0 := clampi(int(sp.x) - int(w * 0.3), 0, img.get_width() - w)
	var y0 := clampi(int(sp.y) - int(h * 0.75), 0, img.get_height() - h)
	var crop := img.get_region(Rect2i(x0, y0, w, h))
	crop.resize(int(w * zoom), int(h * zoom), Image.INTERPOLATE_BILINEAR)
	crop.save_png("%s_%d.png" % [out, id])
	print("saved %s_%d.png flash=%.3f" % [out, id, pl._muzzle_flash])
	gi += 1
	gf = 0
	waiting = false
	if gi >= guns.size():
		quit()
