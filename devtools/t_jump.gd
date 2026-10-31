extends SceneTree
# JUMP FEEL (test only): coyote time + jump buffer (player.gd COYOTE / JUMP_BUFFER).
# 1) walks off a pit edge and presses jump N physics frames after the feet left the floor:
#    inside COYOTE (frames 1-5) = full ground jump (v = jump_velocity) and the double jump is kept; later = double jump.
# 2) jumps, double-jumps, and presses jump again a few frames before landing: jumps again as soon as the feet touch.
# usage: godot --headless --fixed-fps 60 --path . -s res://t_jump.gd -- [level 1]
var lv := 1
var main_node: Node
var pl: Node
var f := 0
var phase := "boot"
var pf := 0
var tests := [1, 4, 7]   # השהיה (פריימים) אחרי שהרגליים עזבו את הקרקע
var ti := 0
var left := -1
var pit := []
var floor_y := 0.0
var landed := -1


func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	lv = int(a[0]) if a.size() > 0 else lv
	Input.use_accumulated_input = false
	var g = root.get_node("Game")
	g.new_run()
	g.level = lv
	main_node = load("res://main.tscn").instantiate()
	root.add_child(main_node)
	current_scene = main_node


func _key(k: Key, on: bool) -> void:
	var e := InputEventKey.new()
	e.physical_keycode = k
	e.keycode = k
	e.pressed = on
	Input.parse_input_event(e)


func _physics_process(_d: float) -> bool:
	f += 1
	pf += 1
	pl = main_node.get_tree().get_first_node_in_group("player")
	if pl == null:
		return false
	pl.health = pl.max_health
	pl.controllable = true
	for s in main_node.get_tree().get_nodes_in_group("story_scene"):
		if s.has_method("_finish"):
			s._finish()
	if f % 20 == 0:
		for z in main_node.get_tree().get_nodes_in_group("zombies"):
			z.queue_free()
	match phase:
		"boot":
			if f == 200:
				floor_y = main_node.get_viewport_rect().size.y - float(main_node.floor_thickness)
				for p in main_node._pits:
					if p.size() < 3:
						pit = p
						break
				if pit.is_empty():
					print("JUMP no pit on level ", lv)
					quit()
					return false
				_place(float(pit[0]) - 90.0)
		"settle":
			if pf == 25:
				_key(KEY_D, true)
				phase = "walk"
				pf = 0
				left = -1
		"walk":
			if left < 0 and not pl.is_on_floor():
				left = f
			if left >= 0 and f - left == tests[ti]:
				_key(KEY_SPACE, true)
			if left >= 0 and f - left == tests[ti] + 1:
				_key(KEY_SPACE, false)
				_key(KEY_D, false)
				var ground: bool = pl.velocity.y < -600.0
				print("JUMP coyote: pressed %d frames after leaving the floor -> %s (vy %.0f, air jumps left %d)" % [tests[ti],
					"GROUND JUMP (coyote)" if ground else ("double jump" if pl._djump else "nothing"), pl.velocity.y, pl._air_jumps])
				ti += 1
				if ti < tests.size():
					_place(float(pit[0]) - 90.0)
				else:
					_place(float(pit[0]) - 420.0)
					phase = "buf_settle"
				pf = 0
			if pf > 200:
				print("JUMP stuck walking")
				quit()
		"buf_settle":
			if pf == 25:
				_key(KEY_SPACE, true)
			if pf == 26:
				_key(KEY_SPACE, false)
			if pf > 26 and pl.velocity.y > -40.0 and not pl.is_on_floor() and pl._air_jumps > 0:
				_key(KEY_SPACE, true)   # קפיצה כפולה בשיא
				phase = "buf_dj"
				pf = 0
		"buf_dj":
			if pf == 1:
				_key(KEY_SPACE, false)
			if pf > 2 and pl.velocity.y > 0.0 and floor_y - pl.global_position.y < pl.velocity.y / 60.0 * 4.0:
				_key(KEY_SPACE, true)   # ~4 פריימים לפני הנחיתה
				phase = "buf_wait"
				pf = 0
				landed = -1
		"buf_wait":
			if pf == 1:
				_key(KEY_SPACE, false)
			if landed < 0 and pl.is_on_floor():
				landed = f
			if pl.velocity.y < -600.0 and landed >= 0:
				print("JUMP buffer: pressed ~4 frames before landing -> JUMPED on touchdown (%d frames after landing)" % (f - landed))
				print("JUMP done")
				quit()
			elif landed >= 0 and f - landed > 12:
				print("JUMP buffer: pressed ~4 frames before landing -> no jump (press lost)")
				print("JUMP done")
				quit()
	return false


func _place(x: float) -> void:
	pl.global_position = Vector2(x, floor_y - 2.0)
	pl.velocity = Vector2.ZERO
	pl.reset_physics_interpolation()
	phase = "settle" if phase in ["boot", "walk"] else phase
	pf = 0
