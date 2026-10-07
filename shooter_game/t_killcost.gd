extends SceneTree
var n := 0
var m
var p
var res := []
func _initialize():
	root.get_node("Game").level = 15
	m = load("res://main.tscn").instantiate()
	root.add_child(m)
func _physics_process(_d):
	n += 1
	if n == 10:
		p = get_first_node_in_group("player")
		p.global_position.x = 3000.0
		for z in get_nodes_in_group("zombies"):
			if absf(z.global_position.x - p.global_position.x) < 1600: z.queue_free()
	if n > 10:
		p._invuln = 1.0
	if n % 60 == 0 and n >= 60 and n <= 600:
		var zs := []
		for i in 6:
			var z = m._spawn_zombie(p.global_position.x + 180 + i * 50, m._stage.floor_y, 0)
			z.dormant = false
			zs.append(z)
	if n % 60 == 30 and n >= 90 and n <= 630:
		var zs := []
		for z in get_nodes_in_group("zombies"):
			if absf(z.global_position.x - p.global_position.x) < 600: zs.append(z)
		var t := Time.get_ticks_usec()
		for z in zs:
			z.hp = 1
			z.take_damage(10, z.global_position + Vector2(0, -50), Vector2.RIGHT, false, {"source": "bullet"})
		res.append((Time.get_ticks_usec() - t) / 1000.0)
	if n == 640:
		res.sort()
		print("6-kill frame cost ms (10 batches): median=", snapped(res[res.size() / 2], 0.01), " all=", res.map(func(x): return snapped(x, 0.1)))
		quit()
