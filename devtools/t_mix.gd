extends SceneTree
# usage: -- level   spawns every returning zombie (levels/zombie_mix.gd) near the player and checks it behaves
const Mix := preload("res://levels/zombie_mix.gd")
const R := preload("res://enemies/zombie_registry.gd")
var lv := 20
var main_node: Node
var f := 0
var zs := []   # [kind, node, x0, moved, mind]
var names := {}
func _initialize() -> void:
	lv = int(OS.get_cmdline_user_args()[0])
	var g = root.get_node("Game")
	g.new_run()
	g.level = lv
	g.start_practice(lv)
	g.level = lv
	main_node = load("res://main.tscn").instantiate()
	root.add_child(main_node)
	current_scene = main_node
func _process(_d: float) -> bool:
	f += 1
	var pl = main_node.get_tree().get_first_node_in_group("player")
	if pl != null:
		pl.health = 999
	if f == 30:
		var ex: Array = Mix.extras(lv)
		var fy: float = pl.global_position.y
		var i := 0
		for e in ex:
			var x: float = pl.global_position.x + 350.0 + 70.0 * i
			var z = main_node._spawn_zombie(x, fy, e[0], null)
			zs.append([e[0], z, x, 0.0, 99999.0])
			i += 1
		print("MIX L", lv, " extras ", ex.map(func(e): return "%d:%.2f" % [e[0], e[2]]))
	if f > 30 and pl != null:
		for s in zs:
			if is_instance_valid(s[1]):
				s[3] = maxf(s[3], absf(s[1].global_position.x - s[2]) + absf(s[1].global_position.y - pl.global_position.y) * 0.0)
				s[4] = minf(s[4], s[1].global_position.distance_to(pl.global_position))
	if f == 30 + 420:
		for s in zs:
			var z = s[1]
			if not is_instance_valid(z):
				print("K ", s[0], " GONE")
				continue
			var vis: bool = z.visible
			print("K ", s[0], " alive hp=", z.hp, " dx=", int(z.global_position.x - s[2]), " y=", int(z.global_position.y), " vis=", vis, " dormant=", z.get("dormant"), " moved=", int(s[3]), " mind=", int(s[4]))
		quit()
	return false
