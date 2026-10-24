extends SceneTree
# Level 2 train-roof rider + climbing test.
# usage: godot --headless --fixed-fps 60 --path . -s res://t_train.gd -- [player_x] [frames] [png_frame|climb png_path]
#   "climb" saves a PNG of the first zombie climbing near the player (run with xvfb + opengl3).
# Moves the player to player_x, calls the ghost train at frame 30, logs the rider until it lands and chases,
# and counts zombies that climb (climb_mode) during the run. Player health is refilled every frame.
var f := 0
var main_node: Node = null
var sub: Node = null
var rider: Node = null
var landed_f := -1
var climbs := 0
var climb_done := 0
var was_climbing := {}
var px := 2500.0
var total := 600
var shot_done := false

func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	px = float(a[0]) if a.size() > 0 else 2500.0
	total = int(a[1]) if a.size() > 1 else 600
	var g = root.get_node("Game")
	g.new_run()
	g.level = 2
	g.start_practice(2) if g.has_method("start_practice") else null
	g.level = 2
	main_node = load("res://main.tscn").instantiate()
	root.add_child(main_node)
	current_scene = main_node

func _physics_process(_d: float) -> bool:
	f += 1
	var a := OS.get_cmdline_user_args()
	var pl = main_node.get_tree().get_first_node_in_group("player")
	if pl == null:
		return false
	pl.health = pl.max_health
	if f == 5:
		pl.global_position.x = px
	if a.size() > 3 and a[2] == "climb" and f == 6:   # stand on a stuck subway car, zombies come from the left and must climb it
		for n in main_node.get_children():
			if n.get_script() != null and str(n.get_script().resource_path).ends_with("prop.gd") and n.kind == 6 and n.position.x > 1500.0:   # 6 = TRAIN
				pl.global_position = n.position + Vector2(220.0, -90.0)
				for i in 2:
					var z = main_node._spawn_zombie(n.position.x - 120.0 - 50.0 * i, n.position.y, 0, null)
					z._alert_t = 30.0
				print("car at ", n.position)
				break
	if sub == null:
		for n in main_node.get_children():
			if n.get_script() != null and str(n.get_script().resource_path).ends_with("subway.gd"):
				sub = n
	if f == 30 and sub != null:
		sub._train_t = 0.0
	if rider == null and sub != null and sub._rider != null:
		rider = sub._rider
		print("RIDER spawned f=%d kind=%d at %s release_x=%d player_x=%d" % [f, rider.kind, str(rider.global_position), sub._rider_release, pl.global_position.x])
	if rider != null and is_instance_valid(rider):
		if f % 6 == 0 and landed_f < 0:
			print("  f=%d pos=%s riding=%s fly=%s dead=%s" % [f, str(rider.global_position.round()), str(rider.riding), str(rider._crash_fly), str(rider.dead)])
		if landed_f < 0 and not rider.riding and not rider._crash_fly:
			landed_f = f
			print("RIDER landed f=%d x=%d player_x=%d gap=%d" % [f, rider.global_position.x, pl.global_position.x, rider.global_position.x - pl.global_position.x])
		if landed_f > 0 and (f - landed_f) in [30, 60, 90]:
			print("  +%d frames: gap=%d chasing=%s" % [f - landed_f, rider.global_position.x - pl.global_position.x, str(rider._chasing)])
	for z in main_node.get_tree().get_nodes_in_group("zombies"):
		var c: bool = z._climbing
		var w: bool = was_climbing.get(z, false)
		if c and not w:
			climbs += 1
		if w and not c:
			climb_done += 1
		was_climbing[z] = c
	if a.size() > 3 and a[2] == "climb" and not shot_done:   # first climber near the player -> PNG
		for z in main_node.get_tree().get_nodes_in_group("zombies"):
			if z._climbing and z._climb_time > 0.25 and absf(z.global_position.x - pl.global_position.x) < 620.0:
				root.get_viewport().get_texture().get_image().save_png(a[3])
				print("saved climb ", a[3], " f=", f, " z=", z.global_position)
				shot_done = true
				break
	elif a.size() > 3 and a[2] != "climb" and f == int(a[2]):
		root.get_viewport().get_texture().get_image().save_png(a[3])
		print("saved ", a[3])
	if f >= total:
		print("CLIMBS started=%d finished=%d" % [climbs, climb_done])
		quit()
	return false
