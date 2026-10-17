extends SceneTree
# car pin test for level 23: scenarios where a sliding car meets the player
var f := 0
var main_node: Node = null
var pl: Node = null
var car: Node = null
var car2: Node = null
var sc := int(OS.get_environment("SC")) if OS.get_environment("SC") != "" else 0
var sf := 0
var maxvy := 0.0
var stuck_f := 0
var log_lines := []
var key := 0

func _initialize() -> void:
	var g = root.get_node("Game")
	g.new_run()
	g.level = 23
	g.start_practice(23) if g.has_method("start_practice") else null
	g.level = 23
	main_node = load("res://main.tscn").instantiate()
	root.add_child(main_node)
	current_scene = main_node

func _press(k: int, on: bool) -> void:
	var e := InputEventKey.new()
	e.physical_keycode = k
	e.keycode = k
	e.pressed = on
	Input.parse_input_event(e)

func _setup(n: int) -> void:
	sf = 0
	maxvy = 0.0
	stuck_f = 0
	if key != 0:
		_press(key, false)
		key = 0
	for z in main_node.get_tree().get_nodes_in_group("zombies"):
		z.queue_free()
	var cars = main_node.get_tree().get_nodes_in_group("cars")
	car = cars[1 + (n * 5) % 6]
	car._vx = 0.0
	var cx: float = car.global_position.x
	var w: float = car.size.x
	var h: float = car.size.y
	pl.velocity = Vector2.ZERO
	match (n % 8) if n < 8 else 99:
		0: pl.global_position = Vector2(cx + w + 9, car.floor_y); car.push(1.0, 300, 1.0)            # side, car comes at him
		1: pl.global_position = Vector2(cx + w * 0.5, car.floor_y - h - 2); car.push(1.0, 300, 1.0)  # on the roof
		2: pl.global_position = Vector2(cx + w + 2, car.floor_y - h - 30); car.push(1.0, 360, 1.0)  # falling on the front corner
		3: pl.global_position = Vector2(cx - 4, car.floor_y - h - 10); car.push(1.0, 360, 1.0)      # falling on back corner
		4: pl.global_position = Vector2(cx + w + 9, car.floor_y); car.push(1.0, 300, 1.0); key = KEY_A; _press(KEY_A, true)  # walking into it
		5: pl.global_position = Vector2(cx + w + 30, car.floor_y - 20); pl.velocity = Vector2(-200, -300); car.push(1.0, 300, 1.0); key = KEY_A; _press(KEY_A, true)  # jumping at it
		6: pl.global_position = Vector2(cx + w + 9, car.floor_y); car.push(1.0, 300, 1.0); pl._crouch_k = 1.0  # crouched
		7: pl.global_position = Vector2(cx - 30, car.floor_y); car.push(-1.0, 300, 1.0); key = KEY_D; _press(KEY_D, true)
		_: 
			seed(1000 + n); var r := randf()
			pl.global_position = Vector2(cx - randf_range(14, 200) if r < 0.5 else cx + w + randf_range(14, 200), car.floor_y)
			car.push(-1.0 if r < 0.5 else 1.0, randf_range(150, 420), randf_range(0.3, 1.2))
			key = [KEY_D, KEY_A, 0][randi() % 3] if r < 0.5 else [KEY_A, KEY_D, 0][randi() % 3]
			if key != 0: _press(key, true)
			if randf() < 0.3: pl.velocity.y = -400
	print("scenario ", n, " car x ", cx, " size ", car.size, " pl ", pl.global_position)

func _process(_d: float) -> bool:
	f += 1
	if f == 30:
		pl = main_node.get_tree().get_first_node_in_group("player")
		_setup(sc)
	if f > 30:
		pl._invuln = 99
		pl.health = pl.max_health if "max_health" in pl else pl.health
		sf += 1
		maxvy = maxf(maxvy, absf(pl.velocity.y))
		if sf % 20 == 0:
			print("  sf ", sf, " pos ", pl.global_position, " vel ", pl.velocity.round(), " floor ", pl.is_on_floor(), " car x ", car.global_position.x, " vx ", round(car._vx))
			for i in pl.get_slide_collision_count():
				var c = pl.get_slide_collision(i)
				print("     col ", c.get_collider(), " par ", c.get_collider().get_parent().name, " ", c.get_collider().get_parent().get_script().resource_path if c.get_collider().get_parent().get_script() else "", " n ", c.get_normal(), " pos ", c.get_position(), " depth ", c.get_depth(), " rem ", c.get_remainder())
		if sf >= 120:
			print("RESULT scenario ", sc, " maxvy ", round(maxvy), " final vel ", pl.velocity.round(), " floor ", pl.is_on_floor())
			sc += 1
			if sc >= int(OS.get_environment("NSC")):
				quit()
				return false
			_setup(sc)
	return false
