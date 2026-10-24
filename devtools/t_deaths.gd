extends SceneTree
# Death animation test (zombie.gd): DOG (15) / HOUND (19) / GUNNER (17) on level 4. Spawns one, lets it run at the player,
# kills it on frame KILL_F and prints its state. DT_KIND env = kind (default 15). DT_PERF=1: 12 dogs die at once, prints frame times.
# usage: xvfb-run -a -s "-screen 0 1280x720x24" godot --fixed-fps 60 --path . --rendering-driver opengl3 -s res://t_deaths.gd -- <png_prefix> [zoom] [frames...]
#        godot --headless --fixed-fps 60 --path . -s res://t_deaths.gd   (no pictures, prints the death states)
const X := 2400.0
const KILL_F := 110
var f := 0
var main_node: Node = null
var zs := []
var prefix := ""
var zoom := 2.4
var shots := []
var max_f := 330
var kind := 15
var perf := false
var t_prev := 0
var times := []

func _initialize() -> void:
	var g = root.get_node("Game")
	g.new_run()
	g.level = 4
	main_node = load("res://main.tscn").instantiate()
	root.add_child(main_node)
	current_scene = main_node
	kind = int(OS.get_environment("DT_KIND")) if OS.get_environment("DT_KIND") != "" else 15
	perf = OS.get_environment("DT_PERF") != ""
	var a := OS.get_cmdline_user_args()
	if a.size() > 0:
		prefix = a[0]
	if a.size() > 1:
		zoom = float(a[1])
	for i in range(2, a.size()):
		shots.append(int(a[i]))
	if not shots.is_empty():
		max_f = shots.max() + 1

func _process(_d: float) -> bool:
	var now := Time.get_ticks_usec()
	if f > KILL_F and f < KILL_F + 180:
		times.append(float(now - t_prev) / 1000.0)
	t_prev = now
	return false

func _physics_process(_d: float) -> bool:
	f += 1
	var pl = main_node.get_tree().get_first_node_in_group("player")
	if pl == null:
		return false
	pl.health = pl.max_health
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
			if absf(o.global_position.x - X) < 1800.0 and not o in zs:
				o.queue_free()
	if f == 30:
		for i in (12 if perf else 1):
			var z = main_node._spawn_zombie(X + 420.0 + 40.0 * i, pl.global_position.y, kind, null)
			z.dormant = false
			zs.append(z)
		root.get_node("Game").make_noise(pl.global_position, 900.0)   # wake them up: they run at the player
	var z0 = zs[0] if not zs.is_empty() and is_instance_valid(zs[0]) else null
	if prefix != "":
		var cam := main_node.get_viewport().get_camera_2d()
		if cam != null and "_base_zoom" in cam:
			cam._base_zoom = Vector2(zoom, zoom)
			cam.zoom = cam._base_zoom
			if z0 != null:
				cam.base_offset = z0.global_position - pl.global_position + Vector2(0, -50)
	if f == KILL_F:
		for z in zs:
			if is_instance_valid(z) and not z.dead:
				z.take_damage(999, z.global_position + Vector2(0, -30), Vector2(z._dir, 0), false, {"source": "bullet", "fixed": 999})
	if z0 != null and f % 15 == 0:
		print("f=%d dead=%s pos=%s vel=%s angle=%.2f land_t=%.2f dead_t=%.2f" % [f, z0.dead, str(z0.global_position.round()), str(z0.velocity.round()), z0._angle, z0._land_t, z0._dead_t])
	if prefix != "" and f in shots:
		root.get_viewport().get_texture().get_image().save_png("%s_%d.png" % [prefix, f])
	if f >= max_f:
		if perf:
			times.sort()
			var s := 0.0
			for t in times:
				s += t
			print("DEATHS kind=%d frames=%d avg=%.2fms p95=%.2fms max=%.1fms" % [kind, times.size(), s / maxf(1, times.size()), times[int(times.size() * 0.95)] if times.size() > 0 else 0.0, times[-1] if times.size() > 0 else 0.0])
		quit()
	return false
