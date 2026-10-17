extends SceneTree
# POWERS bar test: godot --path . -s res://t_powers.gd -- [level] [shot_prefix]
# Checks abilities + special items share one bar: cycling, C on an item, laser auto-charge, abilities still fire.
var f := 0
var lv := 46
var shot := ""
var main_node: Node = null
var pl: Node = null
var fails := 0

func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	lv = int(a[0]) if a.size() > 0 else 46
	shot = a[1] if a.size() > 1 else ""
	var g = root.get_node("Game")
	g.new_run()
	g.level = lv
	g.start_practice(lv)
	g.level = lv
	main_node = load("res://main.tscn").instantiate()
	root.add_child(main_node)
	current_scene = main_node

func check(ok: bool, what: String) -> void:
	print(("OK   " if ok else "FAIL ") + what)
	if not ok:
		fails += 1

func key(k: int, down: bool) -> void:
	var e := InputEventKey.new()
	e.physical_keycode = k
	e.keycode = k
	e.pressed = down
	Input.parse_input_event(e)

func _process(_d: float) -> bool:
	f += 1
	if pl == null:
		pl = main_node.get_tree().get_first_node_in_group("player")
	if pl == null:
		return false
	pl._invuln = 99.0
	var ab = pl.abilities
	match f:
		10:
			print("powers ", ab.powers(), " cur ", ab.cur_id)
			check(ab.powers().size() == 8, "8 abilities in the bar at level 46")
			var c0: String = ab.cur_id
			ab.cycle(1)
			check(ab.cur_id != c0, "cycle moves to next power")
			ab.cycle(-1)
			check(ab.cur_id == c0, "cycle back")
		20:
			pl.take_special("grenade")
			check(ab.cur_id == "item", "picking up grenades selects the item")
			check("item" in ab.powers(), "item is in the bar")
			var u: int = pl.special_uses
			check(ab.use_current(), "C throws a grenade")
			check(pl.special_uses == u - 1, "grenade use consumed")
			check(pl.weapon == pl.GRENADE, "grenade shown in hand")
		150:
			check(pl.weapon == pl.GUN, "back to the gun after the throw")
			pl.take_special("launcher")
			var u: int = pl.special_uses
			ab.use_current()
			check(pl.special_uses == u - 1, "launcher fired with C")
			check(not ab.use_current(), "launcher C spam blocked by fire rate")
		250:
			pl.special_uses = 1
			pl._item_cd = 0.0
			ab.use_current()
		330:
			check(pl.special == "", "launcher empty -> item gone")
			check(ab.cur_id != "item" and ab.cur_id != "", "selection returns to an ability: " + ab.cur_id)
			pl.take_special("laser")
			check(ab.use_current(), "C starts the laser")
		700:
			check(pl.special_uses == 7, "laser fired on its own (uses %d)" % pl.special_uses)
		900:
			check(pl.weapon == pl.GUN, "back to the gun after the beam")
			pl.take_special("god")
			check(ab.use_current(), "C drinks the potion")
			check(pl.god_mode(), "god mode on")
		950:
			ab.select_id("sentry")
			check(ab.cur_id == "sentry", "select sentry")
			check(ab.use_current(), "sentry deployed")
			ab.select_id("flashlight")
			check(ab.use_current(), "flashlight on")
			pl.take_special("molotov")
		1000:
			if shot != "":
				root.get_viewport().get_texture().get_image().save_png(shot + "_bar.png")
			key(KEY_Q, true)
		1030:
			var ww = main_node.get_tree().get_first_node_in_group("weapon_wheel")
			for n in main_node.find_children("*", "Node2D", true, false):
				if n.get_script() != null and str(n.get_script().resource_path).ends_with("weapon_wheel.gd"):
					ww = n
			if ww != null:
				ww._page = 1
		1080:
			if shot != "":
				root.get_viewport().get_texture().get_image().save_png(shot + "_wheel.png")
			key(KEY_Q, false)
		1100:
			print("RESULT fails=", fails)
			quit()
	return false
