extends SceneTree
var n := 0
var m
var p
var last := 0
var before := []
var after := []
func _initialize():
	root.get_node("Game").level = 15
	m = load("res://main.tscn").instantiate()
	root.add_child(m)
func _process(_d):
	var now := Time.get_ticks_usec()
	var dt := (now - last) / 1000.0
	last = now
	if n > 80 and n <= 120: before.append(dt)
	if n > 120 and n <= 160: after.append(dt)
func _physics_process(_d):
	n += 1
	if n == 10:
		p = get_first_node_in_group("player")
		p.global_position.x = 3000.0
		for z in get_nodes_in_group("zombies"):
			if absf(z.global_position.x - p.global_position.x) < 1600: z.queue_free()
	if n > 10:
		p._invuln = 1.0
	if n == 60:
		for i in 6:
			var z = m._spawn_zombie(p.global_position.x + 180 + i * 50, m._stage.floor_y, 0)
			z.dormant = false
			z.set_meta("t", 1)
	if n == 120:
		for z in get_nodes_in_group("zombies"):
			if z.has_meta("t"):
				z.hp = 1
				z.take_damage(10, z.global_position + Vector2(0, -50), Vector2.RIGHT, false, {"source": "bullet"})
	if n == 220:
		var a := 0.0
		for d in before: a += d
		var b := 0.0
		for d in after: b += d
		print("RESULT before-kill avg=", snapped(a / before.size(), 0.1), " ms | after-kill avg (100 frames)=", snapped(b / after.size(), 0.1), " ms worst=", snapped(after.max(), 0.1))
		quit()
