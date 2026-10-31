extends SceneTree
# CHARACTER MAKER test (characters/maker.gd): opens the maker (the first saved character must open), presses NEW
# (so the saved characters are not touched) and then its buttons like a person would: STAND / WALK / RUN / ATTACK,
# the 3 non-killing shots, all 7 KILL buttons, RANDOM, every tab, CROWD, NIGHT, DRAW (a drawing on white paper on his hat:
# the paper is cut away but the white inside stays; a "photo" of paper that gets darker to one side, dropped on the window
# onto his hand, moved to his body; CUT BACKGROUND off / on; sliders, mouse drag, wheel; LOOK turns the hat like a round head;
# WARP: the 9 dots show, a dot pressed and dragged with the mouse follows the mouse, a press away from the dots moves the
# whole picture, STRAIGHTEN; headshot / corpse with the pictures), ATTACK = HAND (he swings his arm with a bat and the hits
# land, he never bites), SAVE (res://characters/saved/zz_maker_test.tres) -> the file loads back the same, old picture files cleaned -> TRY IN LEVEL
# (level 3) -> the level has him, wearing the pictures -> pause BACK TO MAKER -> still editing him -> DELETE -> the file and
# its pictures are gone -> NEW + a picture -> BACK TO MENU asks first -> the menu, the unsaved picture is gone.
# Screenshots <out>_<step>.png. Ends with "MAKER OK" or "MAKER FAILED" (+ "FAIL ..." lines).
# usage: xvfb-run -a -s "-screen 0 1280x720x24" godot --fixed-fps 60 --path . --rendering-driver opengl3 -s res://t_maker.gd -- <png_prefix>
#        headless (errors only): godot --headless --fixed-fps 60 --path . -s res://t_maker.gd -- none
const TEST_ID := "zz_maker_test"
const TEST_NAME := "ZZ MAKER TEST"
const TRY_LV := 3
const TABS := 8           # BODY HEAD CLOTHES COLORS GORE STATS LEVELS DRAW
const PIC_A := "user://zz_test_helmet.png"
const PIC_B := "user://zz_test_photo.jpg"
var Drawings = null
var CustomChars = null   # (loaded in _initialize: its scripts use autoloads)
var M = null             # the maker
var f := 0
var out := "none"
var fails := []
var plan := []           # [frames to wait before, Callable]
var _wait := 0
var _kind := 0
var _old_pic := ""
var _pics := []
var _unsaved_pic := ""
var _test_z = null


func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	out = a[0] if a.size() > 0 else "none"
	CustomChars = load("res://enemies/zombie_registry.gd").custom()
	Drawings = load("res://characters/drawings.gd")
	_make_pictures()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(CustomChars.DIR + TEST_ID + ".tres"))   # (left over from a failed run)
	root.get_node("Game").new_run()
	_open_maker()
	_plan()


func _open_maker() -> void:
	M = load("res://characters/maker.tscn").instantiate()
	root.add_child(M)
	current_scene = M


# A: a red helmet with a black outline and a white eye inside, on white paper. B: a "photo" of a sword on paper
# that gets darker to the right, with grain, saved as JPG
func _make_pictures() -> void:
	var a := Image.create(220, 180, false, Image.FORMAT_RGBA8)
	a.fill(Color.WHITE)
	for y in 180:
		for x in 220:
			var dd := Vector2(x - 110, y - 90).length()
			if dd < 70.0:
				a.set_pixel(x, y, Color.BLACK if dd > 64.0 else Color("c02020"))
			if Vector2(x - 130, y - 80).length() < 10.0:
				a.set_pixel(x, y, Color.WHITE)
	a.save_png(ProjectSettings.globalize_path(PIC_A))
	var b := Image.create(300, 200, false, Image.FORMAT_RGB8)
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for y in 200:
		for x in 300:
			var v := lerpf(0.93, 0.66, float(x) / 299.0) + rng.randf_range(-0.012, 0.012)
			b.set_pixel(x, y, Color(v, v, v * 0.97))
	b.fill_rect(Rect2i(140, 30, 20, 140), Color(0.15, 0.15, 0.18))
	b.fill_rect(Rect2i(110, 130, 80, 12), Color(0.2, 0.12, 0.08))
	b.save_jpg(ProjectSettings.globalize_path(PIC_B), 0.85)


func _fail(t: String) -> void:
	fails.append(t)
	print("FAIL ", t)


func _shot(name: String) -> void:
	if out != "none":
		root.get_viewport().get_texture().get_image().save_png("%s_%s.png" % [out, name])
		print("saved %s_%s.png" % [out, name])


func step(wait: int, c: Callable) -> void:
	plan.append([wait, c])


# waits until cond() (at most max_frames), then then()
func step_until(cond: Callable, then: Callable, max_frames := 300) -> void:
	plan.append([0, func(): _poll(cond, then, max_frames)])


func _poll(cond: Callable, then: Callable, left: int) -> void:
	if left <= 0 or cond.call():
		then.call()
	else:
		plan.push_front([0, func(): _poll(cond, then, left - 1)])


# the real mouse (the maker's _unhandled_input)
func _mouse_button(at: Vector2, down: bool) -> void:
	var e := InputEventMouseButton.new()
	e.button_index = MOUSE_BUTTON_LEFT
	e.pressed = down
	e.button_mask = MOUSE_BUTTON_MASK_LEFT if down else 0
	e.position = at
	e.global_position = at
	root.push_input(e, true)   # (viewport coordinates, like the maker's screen)


func _mouse_move(at: Vector2, rel: Vector2) -> void:
	var e := InputEventMouseMotion.new()
	e.button_mask = MOUSE_BUTTON_MASK_LEFT
	e.position = at
	e.global_position = at
	e.relative = rel
	root.push_input(e, true)   # (viewport coordinates, like the maker's screen)


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
	step(0, func():
		if _tabs().get_tab_count() != TABS:
			_fail("TABS: %d (the test knows %d)" % [_tabs().get_tab_count(), TABS]))
	for i in TABS:
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
	# ---- DRAW ----
	step(10, func():
		_tabs().current_tab = M._draw_tab
		M._pick_picture("hat")
		if M._file_dlg == null or M._file_dlg.file_mode != FileDialog.FILE_MODE_OPEN_FILES or M._pic_slot != "hat":
			_fail("DRAW: + HAT did not make the file window")
			return
		M._file_dlg.use_native_dialog = false   # (no native file window here: Godot's own one, for the picture)
		M._file_dlg.popup_centered(Vector2i(900, 560)))
	step(10, func():
		_shot("draw_dialog")
		if M._file_dlg == null or not M._file_dlg.visible:
			_fail("DRAW: the file window did not open")
			return
		M._file_dlg.hide()
		M._on_pictures_picked(PackedStringArray([ProjectSettings.globalize_path(PIC_A)]))
		var arr: Array = M.cur.drawings
		if arr.size() != 1 or str(arr[0].slot) != "hat" or M._pic_i != 0:
			_fail("DRAW: the picture is not on his hat (%s)" % str(arr))
			return
		var d: Dictionary = arr[0]
		if not FileAccess.file_exists(d.file) or not FileAccess.file_exists(d.original) or not FileAccess.file_exists(Drawings.ORIG + ".gdignore"):
			_fail("DRAW: files missing (%s)" % str(d))
		var img: Image = load(str(d.file))
		print("DRAW helmet: %dx%d  %s" % [img.get_width(), img.get_height(), str(d)])
		if absi(img.get_width() - 139) > 3 or absi(img.get_height() - 139) > 3:
			_fail("DRAW: the helmet was cut to %dx%d (want 139x139)" % [img.get_width(), img.get_height()])
		if img.get_pixel(2, 2).a > 0.1:
			_fail("DRAW: the paper around the helmet is still there")
		if img.get_pixel(69, 69).a < 0.99:
			_fail("DRAW: the helmet itself was cut away")
		var eye := img.get_pixel(89, 59)
		if eye.a < 0.99 or eye.r < 0.9:
			_fail("DRAW: the white eye inside the drawing was cut away (%s)" % str(eye))
		if str(d.name) != "ZZ TEST HELMET":
			_fail("DRAW: name %s" % str(d.name))
		if M.mode != "stand" or _tabs().get_tab_title(M._draw_tab) != "DRAW (1)":
			_fail("DRAW: mode %s, tab %s" % [M.mode, _tabs().get_tab_title(M._draw_tab)]))
	step(40, func(): _shot("draw_hat"))
	step(0, func():
		M._on_pic_slider(14.0, "size")
		M._on_pic_slider(9.0, "up")
		M._on_pic_slider(-15.0, "rot")
		var d = M._pic()
		if absf(d["size"] - 14.0) > 0.01 or absf(d.y + 9.0) > 0.01 or absf(d.rot + 15.0) > 0.01:
			_fail("DRAW: sliders %s" % str(d))
		var x0: float = d.x
		M._drag_pic(Vector2(12.0, 0.0))
		print("DRAW drag 12 px: x %.2f -> %.2f" % [x0, d.x])
		if absf(d.x - x0) < 0.5 or absf(d.x - x0) > 6.0:   # (12 px on the screen at zoom 6 = 2 of his pixels, more for a small head)
			_fail("DRAW: dragging moved it %.2f" % (d.x - x0))
		M._drag_pic(Vector2(-12.0, 0.0))
		M._wheel_pic(true, false)
		if absf(d["size"] - 14.0 * 1.08) > 0.01:
			_fail("DRAW: wheel size %.2f" % d["size"])
		if absf((M._pic_sliders["size"][0] as Range).value - d["size"]) > 0.26:   # (the slider moves in 0.5 steps)
			_fail("DRAW: the SIZE slider did not follow")
		if not M._dirty:
			_fail("DRAW: not dirty"))
	# ---- LOOK + WARP: bend the picture ----
	step(0, func():
		M._on_pic_slider(45.0, "look")
		var d = M._pic()
		if absf(float(d.get("look", 0.0)) - 45.0) > 0.01 or not Drawings.bent(d):
			_fail("LOOK: slider %s" % str(d.get("look")))
		var s: Vector2 = Drawings.pic_size(d)   # (a cylinder turn: the middle moves forward, the edges stay)
		var mid: Vector2 = Drawings.bend_point(d, s.x, s.y, 0.5, 0.5)
		var lft: Vector2 = Drawings.bend_point(d, s.x, s.y, 0.0, 0.5)
		var rgt: Vector2 = Drawings.bend_point(d, s.x, s.y, 1.0, 0.5)
		print("LOOK 45: middle x %.2f (width %.2f), edges %.2f / %.2f" % [mid.x, s.x, lft.x, rgt.x])
		if mid.x < s.x * 0.15 or absf(lft.x + s.x / 2.0) > 0.01 or absf(rgt.x - s.x / 2.0) > 0.01:
			_fail("LOOK: the middle did not turn forward (%.2f)" % mid.x))
	step(20, func():
		_shot("draw_look")
		M._toggle_warp())
	step(6, func():
		if not M._handles.visible or M._handle_points().size() != 9:
			_fail("WARP: no dots on the picture (visible=%s, %d dots)" % [str(M._handles.visible), M._handle_points().size()])
			return
		var p0: Vector2 = M._handle_points()[2]   # the top right dot, with the real mouse: press, drag, let go
		var to := p0 + Vector2(18.0, -24.0)
		_mouse_button(p0 + Vector2(3.0, 2.0), true)
		if M._handle != 2 or M._dragging:
			_fail("WARP: pressing near the top right dot did not grab it (%d)" % M._handle)
		_mouse_move(to + Vector2(3.0, 2.0), Vector2(18.0, -24.0))
		var p1: Vector2 = M._handle_points()[2]
		var wp: Array = M._pic().get("warp", [])
		print("WARP: dot %s -> %s (want %s)  warp %s" % [str(p0), str(p1), str(to), str(wp)])
		if p1.distance_to(to) > 0.6:
			_fail("WARP: the dot did not follow the mouse (%s, want %s)" % [str(p1), str(to)])
		for i in wp.size():
			if i != 4 and i != 5 and absf(float(wp[i])) > 0.0:
				_fail("WARP: another dot moved (%s)" % str(wp))
				break
		_mouse_button(to, false)
		if M._handle != -1:
			_fail("WARP: letting go did not drop the dot")
		var x0: float = M._pic().x   # a press away from the dots moves the whole picture
		var away: Vector2 = M._handle_points()[4] + Vector2(0.0, 300.0)
		_mouse_button(away, true)
		_mouse_move(away + Vector2(12.0, 0.0), Vector2(12.0, 0.0))
		_mouse_button(away + Vector2(12.0, 0.0), false)
		if absf(M._pic().x - x0) < 0.5:
			_fail("WARP: a press away from the dots did not move the picture")
		M._drag_pic(Vector2(-12.0, 0.0)))
	step(10, func():
		_shot("draw_warp")
		var d = M._pic()
		var keep_w: Array = d.warp.duplicate()
		M._straighten()
		if Drawings.bent(d) or float(d.look) != 0.0:
			_fail("STRAIGHTEN: still bent %s" % str(d))
		d.look = 45.0   # (back, for SAVE)
		d.warp = keep_w
		M._toggle_warp())
	step(4, func():
		if M._handles.visible:
			_fail("WARP off: the dots are still there"))
	step(20, func():
		_shot("draw_hat_moved")
		M._pic_slot = "hand"
		M._on_files_dropped(PackedStringArray([ProjectSettings.globalize_path(PIC_B), "/tmp/not_a_picture.txt"]))
		var arr: Array = M.cur.drawings
		if arr.size() != 2 or str(arr[1].slot) != "hand" or M._pic_i != 1:
			_fail("DRAW: the dropped picture is not in his hand (%s)" % str(arr))
			return
		var img: Image = load(str(arr[1].file))
		print("DRAW photo: %dx%d" % [img.get_width(), img.get_height()])
		if img.get_width() > 90 or img.get_height() > 150:
			_fail("DRAW: the paper in the photo was not cut away (%dx%d)" % [img.get_width(), img.get_height()])
		if img.get_pixel(0, 0).a > 0.2 or img.get_pixel(img.get_width() - 1, 0).a > 0.2:
			_fail("DRAW: paper left in the photo corners"))
	step(30, func(): _shot("draw_hand"))
	step(0, func():
		M._on_pic_part("body")
		var d = M._pic()
		if str(d.slot) != "body" or absf(d["size"] - Drawings.START.body["size"]) > 0.01:
			_fail("DRAW: moving it to his body %s" % str(d))
		_old_pic = d.file
		M._on_pic_flag(false, "cut")
		var img: Image = load(str(d.file))
		if str(d.file) == _old_pic or img.get_pixel(0, 0).a < 0.99:
			_fail("DRAW: CUT BACKGROUND off did not bring the paper back")
		M._on_pic_flag(true, "cut")
		M._on_pic_slider(30.0, "size")
		M._on_pic_slider(-2.0, "up"))
	step(30, func(): _shot("draw_body"))
	step(0, func(): M._kill("headshot"))
	step(14, func(): _shot("draw_headshot"))
	step(0, func(): M._respawn(true))
	step(25, func(): M._kill("nohead"))
	step(10, func():   # the flying head wears the hat picture (effects/flying_head.gd -> draw_dead_head)
		_shot("draw_nohead")
		if not M.z._hw_t > 0.0:
			_fail("DRAW: NO HEAD did not happen"))
	step(0, func(): M._respawn(true))
	step(25, func():
		M.z.set_meta("force_hw", true)   # (a body shot can't walk on headless: a plain body on the ground, no random special death)
		M._kill("shot"))
	step(30, func(): _shot("draw_corpse"))
	step(0, func():
		M._respawn(true)
		M._set_mode("walk"))
	step(70, func(): _shot("draw_walk"))
	step(0, func():
		M._set_mode("stand")
		_tabs().current_tab = 0)
	# ---- ATTACK = HAND ----
	step(0, func():
		_tabs().current_tab = 5   # STATS
		M._groups.attack.hand.pressed.emit()   # (like a click)
		M._pick("item", "bat")
		if str(M.cur.attack) != "hand" or not M._groups.attack.hand.button_pressed:
			_fail("ATTACK: the HAND button did not pick it (%s)" % str(M.cur.attack)))
	step(10, func():
		M._respawn(true)
		M._set_mode("attack"))
	step_until(func(): return M._alive() and M.z.cust.swing_t > 0.18, func():
		_shot("attack_hand_up")
		if not M._alive() or M.z.cust.swing_t <= 0.0:
			_fail("ATTACK = HAND: he never swung"), 400)
	step_until(func(): return M._alive() and M.z.cust.swing_t > M.z.cust.SWING_WIND + 0.05, func(): _shot("attack_hand_hit"), 60)
	step(150, func():
		print("ATTACK = HAND: %d hits, bite anim %.2f" % [M.z.cust.hits, M.z._bite_anim])
		if M.z.cust.hits < 2:
			_fail("ATTACK = HAND: %d hits landed" % M.z.cust.hits)
		if M.z.cust.can_bite():
			_fail("ATTACK = HAND: he can still bite")
		M._set_mode("stand"))
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
			if not _same(a, b):
				_fail("SAVE: %s is %s in the file, %s in the maker" % [prop.name, str(p.get(prop.name)), str(M.cur.get(prop.name))])
		if CustomChars.get_preset_by_id(TEST_ID) == null:
			_fail("SAVE: CustomChars does not list it")
		if (p.drawings as Array).size() != 2:
			_fail("SAVE: %d pictures in the file" % (p.drawings as Array).size())
		for d in M.cur.drawings:
			_pics.append(d.file)
			_pics.append(d.original)
			if not FileAccess.file_exists(d.file) or not FileAccess.file_exists(d.original):
				_fail("SAVE: a picture file is gone (%s)" % str(d))
		if _old_pic == "" or FileAccess.file_exists(_old_pic):
			_fail("SAVE: the old picture (before CUT BACKGROUND) was not cleaned (%s)" % _old_pic)
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
		z.chase_range = 0.0
		_test_z = z)
	step(30, func():
		_shot("try_level")
		if _test_z == null or not is_instance_valid(_test_z) or not _test_z.cust.pic_ang.has("body"):
			_fail("TRY IN LEVEL: he is not wearing the pictures"))
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
			_fail("DELETE: still listed")
		for f in _pics:
			if FileAccess.file_exists(f):
				_fail("DELETE: picture file left: " + f))
	# ---- NEW (not saved) -> BACK TO MENU asks first ----
	step(5, func():
		M._new()
		if M._path != "" or not M._dirty:
			_fail("NEW: should be unsaved")
		if M._pic_box.visible or M._pic_list.get_child_count() != 0:
			_fail("NEW: the DRAW tab still shows pictures")
		M._add_picture(ProjectSettings.globalize_path(PIC_A), "face")
		_unsaved_pic = M.cur.drawings[0].file
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
		if _unsaved_pic == "" or FileAccess.file_exists(_unsaved_pic):
			_fail("BACK TO MENU: the picture of the unsaved character is still there")
		_shot("menu"))
	step(0, func():
		for f in [PIC_A, PIC_B]:
			DirAccess.remove_absolute(ProjectSettings.globalize_path(f))
		print("MAKER OK" if fails.is_empty() else "MAKER FAILED (%d)" % fails.size())
		quit())


# the same, floats within 0.0001 (the .tres keeps 6 digits; dictionary keys come back sorted)
func _same(a, b) -> bool:
	if typeof(a) == TYPE_FLOAT or typeof(b) == TYPE_FLOAT:
		return absf(float(a) - float(b)) < 0.0001
	if a is Array and b is Array:
		if a.size() != b.size():
			return false
		for i in a.size():
			if not _same(a[i], b[i]):
				return false
		return true
	if a is Dictionary and b is Dictionary:
		if a.size() != b.size():
			return false
		for k in a:
			if not b.has(k) or not _same(a[k], b[k]):
				return false
		return true
	return str(a) == str(b)


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
