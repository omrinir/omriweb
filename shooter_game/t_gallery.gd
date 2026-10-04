extends SceneTree
# שימוש: -s res://t_gallery.gd -- <out.png> <kind> <kind> ...   (מצייר כל סוג בגודל x3)
var n := 0
var zs := []
var out := "gallery.png"
func _initialize():
	RenderingServer.set_default_clear_color(Color(0.42, 0.45, 0.5))
	var a := OS.get_cmdline_user_args()
	out = a[0]
	var f := StaticBody2D.new()
	var cs := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = Vector2(4000, 40)
	cs.shape = r
	f.add_child(cs)
	f.position = Vector2(600, 660)
	root.add_child(f)
	var kinds := a.slice(1)
	for i in kinds.size():
		var z = load("res://zombie.tscn").instantiate()
		z.kind = int(kinds[i])
		z.position = Vector2(140 + i * (1100.0 / maxf(kinds.size(), 1)), 630)
		z.scale = Vector2(2.6, 2.6)
		root.add_child(z)
		zs.append(z)
func _process(_d):
	n += 1
	if n == 20:
		for z in zs:
			z.set_physics_process(false)
			z._dir = 1
			z.queue_redraw()
	if n == 23:
		root.get_viewport().get_texture().get_image().get_region(Rect2i(0, 360, 1280, 330)).save_png(out)
		quit()
