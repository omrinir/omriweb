extends SceneTree
var n := 0
var m
var p
var lv := 4
func _initialize():
	var a := OS.get_cmdline_user_args()
	if a.size() > 0: lv = int(a[0])
	root.get_node("Game").level = lv
	m = load("res://main.tscn").instantiate()
	root.add_child(m)
func _process(_d):
	n += 1
	if n == 10:
		p = get_first_node_in_group("player")
		for z in get_nodes_in_group("zombies"): z.queue_free()
		for i in 8:
			var z = load("res://zombie.tscn").instantiate()
			z.kind = [0, 1, 2, 0, 1, 0, 9, 0][i]
			z.position = p.global_position + Vector2((-1 if i % 3 == 0 else 1) * (200 + i * 60), -10)
			m.add_child(z)
	if n > 10 and p != null:
		p._invuln = 1.0
		p.health = p.max_health
	if n % 60 == 0 and n > 10:
		var roles := {}
		for z in get_nodes_in_group("zombies"):
			if z.brain != null and not z.dead:
				var r: String = z.brain.ROLE_NAMES[z.brain.role]
				roles[r] = roles.get(r, 0) + 1
		var sd = get_first_node_in_group("squad_director")
		print("t=", n / 60, " attackers=", sd.attackers(), "/", sd.max_slots, " roles=", roles, " calls=", sd.calls_made)
	if n == 300:
		quit()
