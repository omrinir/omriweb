extends SceneTree
# CHARACTER MAKER test (characters/maker.gd): opens the maker (the first saved character must open), presses NEW
# (so the saved characters are not touched) and then its buttons like a person would: STAND / WALK / RUN / ATTACK,
# the 3 non-killing shots, all 7 KILL buttons, RANDOM, every tab, CROWD, NIGHT, SAVE (res://characters/saved/zz_maker_test.tres)
# -> the file loads back the same -> TRY IN LEVEL (level 3) -> the level has him -> pause BACK TO MAKER -> still editing him
# -> DELETE -> the file is gone -> NEW -> BACK TO MENU asks first -> the menu.
# Screenshots <out>_<step>.png. Ends with "MAKER OK" or "MAKER FAILED" (+ "FAIL ..." lines).
# usage: xvfb-run -a -s "-screen 0 1280x720x24" godot --fixed-fps 60 --path . --rendering-driver opengl3 -s res://t_maker.gd -- <png_prefix>
#        headless (errors only): godot --headless --fixed-fps 60 --path . -s res://t_maker.gd -- none
const TEST_ID := "zz_maker_test"
const TEST_NAME := "ZZ MAKER TEST"
const TRY_LV := 3
var CustomChars = null   # (loaded in _initialize: its scripts use autoloads)
var M = null             # the maker
var f := 0
var out := "none"
var fails := []
var plan := []           # [frames to wait before, Callable]
var _wait := 0
var _kind := 0


func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	out = a[0] if a.size() > 0 else "none"
	CustomChars = load("res://enemies/zombie_registry.gd").custom()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(CustomChars.DIR + TEST_ID + ".tres"))   # (left over from a failed run)
	root.get_node("Game").new_run()
	_open_maker()
	_plan()


func _open_maker() -> void:
	M = load("res://characters/maker.tscn").instantiate()
	root.add_child(M)
	current_scene = M


func _fail(t: String) -> void:
	fails.append(t)
	print("FAIL ", t)


func _shot(name: String) -> void:
	if out != "none":
		root.get_viewport().get_texture().get_image().save_png("%s_%s.png" % [out, name])
		print("saved %s_%s.png" % [out, name])


func step(wait: int, c: Callable) -> void:
	plan.append([wait, c])


func _plan() -> void:
	step(40, func():
		_shot("stand")
		var first = CustomChars.all()[0] if not CustomChars.all().is_empty() else null
		if first != null and M._path != first.resource_path:
			_fail("OPEN: the maker did not open the first saved character (%s)" % M._path)
		M._new())   # (the test edits a new character, so the saved ones are not touched)
	step(0, func(): M._set_mode("walk"))
	step(90, func(): _shot("walk"))
	step(0, func(): M._set_mode("run"))
	step(70, func(): _shot("run"))
	step(0, func():
		M._respawn(true)
		M._set_mode("attack"))
	step(150, func():
		_shot("attack")
		if absf(M.z.global_position.x - M.HERO_X) > 60.0:
			_fail("ATTACK: he did not come to the hero (x=%.0f)" % M.z.global_position.x))
	step(0, func():
		M._set_mode("stand")
		M._respawn(true))
	for zone in ["head", "body", "legs"]:
		step(30, func(): M._hit(zone))
		step(5, func():
			_shot("hit_" + zone)
			if not M._alive():
				_fail("SHOOT %s killed him" % zone))
	for how in ["shot", "headshot", "nohead", "tear", "burst", "burn", "crawl"]:
		step(0, func(): M._respawn(true))
		step(25, func():   # (checked right away: a torn / burst body is removed later, a headless one falls when it walks into the hero)
			M._kill(how)
			var z = M.z
			var ok: bool = z._legless and not z.dead if how == "crawl" else z.dead
			match how:
				"nohead":
					ok = ok and z._hw_t > 0.0
				"tear":
					ok = ok and z._rag != null and z._rag.split
				"burst":
					ok = ok and z._gibbed
				"burn":
					ok = ok and z._char != null
			print("kill %s: dead=%s legless=%s hw_t=%.2f gibbed=%s char=%s" % [how, str(z.dead), str(z._legless), z._hw_t, str(z._gibbed), str(z._char != null)])
			if not ok:
				_fail("KILL %s did not happen" % how))
		step(24, func(): _shot("kill_" + how))
	step(0, func(): M._respawn(true))
	for i in 3:
		step(20, func(): M._random())
		step(20, func(): _shot("random%d" % i))
	step(0, func(): M._set_mode("walk"))
	for i in 7:
		step(4, func(): _tabs().current_tab = i)
		step(4, func(): _shot("tab%d" % i))
	step(0, func():
		M._toggle_crowd()
		M._toggle_night())
	step(100, func():
		_shot("crowd_night")
		if M.crowd.size() != M.CROWD_N:
			_fail("CROWD: %d" % M.crowd.size()))
	step(0, func():
		M._toggle_crowd()
		M._toggle_night()
		M._set_mode("stand")
		_tabs().current_tab = 0)
	# ---- SAVE ----
	step(10, func():
		M._name.text = TEST_NAME
		M._on_name(TEST_NAME)
		M.cur.levels = PackedInt32Array([TRY_LV])
		M.cur.share = 30
		M._save()
		_kind = int(M.cur.kind)
		var path: String = CustomChars.DIR + TEST_ID + ".tres"
		if not FileAccess.file_exists(path):
			_fail("SAVE: no file " + path)
			return
		print("---- ", path, " ----\n", FileAccess.get_file_as_string(path), "----")
		var p = ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE)
		for prop in p.get_property_list():
			if not prop.usage & PROPERTY_USAGE_SCRIPT_VARIABLE:
				continue
			var a = p.get(prop.name)
			var b = M.cur.get(prop.name)
			if (absf(a - b) > 0.0001) if typeof(a) == TYPE_FLOAT else (str(a) != str(b)):
				_fail("SAVE: %s is %s in the file, %s in the maker" % [prop.name, str(p.get(prop.name)), str(M.cur.get(prop.name))])
		if CustomChars.get_preset_by_id(TEST_ID) == null:
			_fail("SAVE: CustomChars does not list it")
		if M._dirty:
			_fail("SAVE: still dirty")
		_shot("saved"))
	# ---- TRY IN LEVEL ----
	step(10, func():
		M._try_level = TRY_LV
		M._try())
	step(150, func():
		var main = current_scene
		if main == null or main.scene_file_path != "res://main.tscn":
			_fail("TRY IN LEVEL: not in the level")
			return
		var n := 0
		var all := 0
		for zz in main.get_tree().get_nodes_in_group("zombies"):
			all += 1
			if int(zz.kind) == _kind:
				n += 1
		print("TRY IN LEVEL: %d of %d zombies are him (level %d)" % [n, all, root.get_node("Game").level])
		if n == 0:
			_fail("TRY IN LEVEL: none of him in the level")
		var pl = main.get_tree().get_first_node_in_group("player")
		var z = main._spawn_zombie(pl.global_position.x + 140.0, pl.global_position.y, _kind, null)
		z.chase_range = 0.0)
	step(30, func(): _shot("try_level"))
	step(0, func():
		var pm = _find_script(current_scene, "res://pause_menu.gd")
		if pm == null:
			_fail("no pause menu")
			return
		if pm._menu_text() != "BACK TO MAKER":
			_fail("pause button says " + pm._menu_text())
		pm._open_pause())
	step(30, func():
		_shot("pause")
		_find_script(current_scene, "res://pause_menu.gd")._to_menu())
	step(90, func():
		M = current_scene
		if M == null or M.scene_file_path != "res://characters/maker.tscn":
			_fail("BACK TO MAKER: not in the maker")
			return
		if str(M.cur.name) != TEST_NAME or M._path != CustomChars.DIR + TEST_ID + ".tres":
			_fail("BACK TO MAKER: editing %s (%s)" % [str(M.cur.name), M._path])
		if not root.get_node("Game").custom_test.is_empty():
			_fail("BACK TO MAKER: custom_test not cleared")
		_shot("back_in_maker"))
	# ---- DELETE ----
	step(5, func():
		M._delete()
		M._confirm.confirmed.emit())
	step(5, func():
		if FileAccess.file_exists(CustomChars.DIR + TEST_ID + ".tres"):
			_fail("DELETE: the file is still there")
		if CustomChars.get_preset_by_id(TEST_ID) != null:
			_fail("DELETE: still listed"))
	# ---- NEW (not saved) -> BACK TO MENU asks first ----
	step(5, func():
		M._new()
		if M._path != "" or not M._dirty:
			_fail("NEW: should be unsaved")
		M._back())
	step(5, func():
		if not M._confirm.visible:
			_fail("BACK with unsaved changes did not ask")
		M._confirm.confirmed.emit())
	step(60, func():
		if current_scene == null or current_scene.scene_file_path != "res://menu.tscn":
			_fail("BACK TO MENU: not in the menu")
		if not CustomChars.live.is_empty():
			_fail("BACK TO MENU: live presets left")
		if root.get_node("Game").practice:
			_fail("BACK TO MENU: still in practice")
		_shot("menu"))
	step(0, func():
		print("MAKER OK" if fails.is_empty() else "MAKER FAILED (%d)" % fails.size())
		quit())


func _tabs() -> TabContainer:
	return _find_class(M, "TabContainer")


func _find_class(n: Node, cls: String) -> Node:
	if n.get_class() == cls:
		return n
	for c in n.get_children():
		var r := _find_class(c, cls)
		if r != null:
			return r
	return null


func _find_script(n: Node, path: String) -> Node:
	if n == null:
		return null
	if n.get_script() != null and n.get_script().resource_path == path:
		return n
	for c in n.get_children():
		var r := _find_script(c, path)
		if r != null:
			return r
	return null


func _physics_process(_d: float) -> bool:
	f += 1
	if plan.is_empty():
		return false
	if _wait < int(plan[0][0]):
		_wait += 1
		return false
	_wait = 0
	var c: Callable = plan.pop_front()[1]
	c.call()
	return false
