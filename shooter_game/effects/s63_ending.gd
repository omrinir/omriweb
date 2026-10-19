extends Node2D
const DrawBatch := preload("res://effects/draw_batch.gd")
# ============================================================
#  הסוף של המשחק (שלב 63): ה-ROOT נפל ומדבר. הגיבור בוחר: [DESTROY] או [JOIN]. לכל בחירה סצנה קצרה עם קולות,
#  ואז "THE END" -> main._level_complete() (מסך התוצאות -> המפה).
#  stage_63.root_dead() יוצר אותו (2.6 שניות אחרי שה-ROOT מת). הטקסט והקולות: story/scenes/l63_ending.gd (ENDING).
#  כמו story/story_scene.gd: פסים שחורים, מצלמה משלו, כתוביות מוקלדות (Bangers), השחקן לא בשליטה, ה-HUD מוסתר.
#  הבחירה: שני כפתורים (menu_button.gd) - עכבר / מגע, מקלדת (חיצים / A D / 1 2 + ENTER), גיימפד (ui_left / ui_right /
#    ui_accept). ENTER / SPACE / נגיעה מדלגים על השיחה (עד הבחירה) ועל הסיום (עד THE END).
#  DESTROY: יורה בליבה -> הבזק לבן, הליבה מתנפצת (root.shattered), כל הזוהר בעולם כבה (Decor.U.life -> 0),
#    נבגים אפורים נופלים, ואור יום יורד מלמעלה.
#  JOIN: הולך אל הליבה -> השורשים עוטפים אותו (root.embrace), העיניים שלו ירוקות, הוא נמשך פנימה,
#    הכל פורח (Decor.U.life -> 2), נבגים עולים לשמיים. הקול שלו והכוורת - קול אחד ("U").
#  נשמר: Game.set_meta("ending_63", "destroy" / "join") (ראה NOTES_63.md - איך לשמור את זה לתמיד).
#  ביצועים: הכל ב-_process, כל ציור ב-draw call אחד (העולם: self, המסך: _ui_draw), הנבגים - מערך קבוע.
#  לשנות: BAR_H, SPORES, טקסטים ב-story/scenes/l63_ending.gd.
# ============================================================

const Sfx := preload("res://sfx.gd")
const Art := preload("res://art.gd")
const Particles := preload("res://particles.gd")
const Decor := preload("res://effects/s63_decor.gd")
const U := Decor.U
const Data := preload("res://story/scenes/l63_ending.gd")
const ButtonScript := preload("res://menu_button.gd")
const TouchAPI := preload("res://ui/touch_api.gd")
const FONT_PATH := "res://fonts/Bangers-Regular.ttf"
const BAR_H := 78.0
const SPORES := 48

var stage: Node = null
var main: Node = null
var root: Node = null
var player: Node2D = null
var choice := ""
var step := "talk"                 # talk / choose / outro / end / done
var lines_said := 0                # לבדיקות
var _ui: CanvasLayer
var _ui_draw: Node2D
var _cam: Camera2D
var _voice: AudioStreamPlayer
var _hidden: Array = []
var _btns: Array = []
var _cont: Control = null
var _bars := 0.0
var _black := 0.0
var _white := 0.0
var _end_k := 0.0
var _ask_k := 0.0
var _ask_tw: Tween = null
var _who := ""
var _line := ""
var _shown := 0.0
var _skip := false
var _skip_t := 0.0
var _clock := 0.0
var _cam_to := Vector2.ZERO
var _zoom_to := 1.3
var _tracer := -1.0
var _tracer_from := Vector2.ZERO
var _shaft := 0.0
var _tendril := 0.0
var _pull := -1.0                  # JOIN: הגוף נמשך אל הליבה (0..1)
var _spores := PackedVector3Array()
var _spore_dir := 0.0              # -1 נופלים (DESTROY), 1 עולים (JOIN)
var _life_to := -1.0               # Decor.U.life: לאן (0 = כבה, 2 = פורח)
var _life_v := 0.25
static var _font: Font = null


func _ready() -> void:
	add_to_group("story_scene")   # ui/monologue.gd שותק
	z_index = 20
	player = get_tree().get_first_node_in_group("player") as Node2D
	_ui = CanvasLayer.new()
	_ui.layer = 8
	add_child(_ui)
	_ui_draw = Node2D.new()
	_ui.add_child(_ui_draw)
	_ui_draw.draw.connect(_on_ui_draw)
	_voice = AudioStreamPlayer.new()
	_voice.bus = "SFX" if AudioServer.get_bus_index("SFX") >= 0 else "Master"
	add_child(_voice)
	if player != null:
		player.controllable = false
		player.auto_walk = 0.0
		player.calm = true
		player.unarmed = true
		player.idle_aim = Vector2(1.0, 0.8).normalized()
	if main != null:
		main.clock_paused = true
		for c in main.get_children():   # ה-HUD (CanvasLayer 2)
			if c is CanvasLayer and (c as CanvasLayer).layer == 2 and c.visible:
				c.visible = false
				_hidden.append(c)
	for zz in get_tree().get_nodes_in_group("zombies"):
		if zz != root and zz.is_physics_processing():
			zz.set_physics_process(false)
	_spores.resize(SPORES)
	for i in SPORES:
		_spores[i] = Vector3(randf(), randf(), randf_range(0.4, 1.0))
	_cam = Camera2D.new()
	main.add_child(_cam)
	var cur := get_viewport().get_camera_2d()
	_cam.global_position = cur.get_screen_center_position() if cur != null else player.global_position
	_cam.zoom = cur.zoom if cur != null else Vector2.ONE
	_cam.make_current()
	_frame_two(1.3)
	_run()


func _core() -> Vector2:
	if root != null and is_instance_valid(root) and root.type_mod != null:
		return root.type_mod.core_world()
	return Vector2(9750.0, 380.0)


func _rt():
	return root.type_mod if root != null and is_instance_valid(root) else null


func _frame_two(z: float) -> void:
	var c := _core()
	var px: float = player.global_position.x if player != null else c.x - 300.0
	_cam_to = Vector2((px + c.x) * 0.5, (player.global_position.y + c.y) * 0.5 - 10.0 if player != null else 480.0)
	_zoom_to = z


func _process(delta: float) -> void:
	_clock += delta
	_skip_t += delta
	if player != null:
		player._invuln = maxf(player._invuln, 0.5)
	if _line != "":
		_shown += delta * 40.0
	if _cam != null:
		var k := 1.0 - exp(-delta * 2.2)
		_cam.global_position = _cam.global_position.lerp(_cam_to, k)
		_cam.zoom = _cam.zoom.lerp(Vector2(_zoom_to, _zoom_to), k)
	if _life_to >= 0.0:
		Decor.U.life = move_toward(Decor.U.life, _life_to, delta * _life_v)
	if _tracer >= 0.0:
		_tracer += delta
		if _tracer > 0.18:
			_tracer = -1.0
	# הנבגים: נופלים (DESTROY) / עולים (JOIN)
	if _spore_dir != 0.0:
		for i in SPORES:
			var s := _spores[i]
			s.y = fposmod(s.y + _spore_dir * delta * 0.05 * s.z, 1.0)
			_spores[i] = s
	var rt = _rt()
	if rt != null:
		rt.speak = move_toward(rt.speak, 1.0 if _who == "H" and _line != "" and _voice.playing else (0.6 if _who == "H" and _line != "" else 0.0), delta * 4.0)
		rt.face_k = move_toward(rt.face_k, 0.0, delta * 0.5)
	queue_redraw()
	_ui_draw.queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if step == "done":
		return
	var accept: bool = (event is InputEventKey and event.pressed and not event.echo and event.physical_keycode in [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE]) \
		or (event is InputEventJoypadButton and event.pressed and event.is_action_pressed("ui_accept")) \
		or (TouchAPI.on() and event is InputEventScreenTouch and event.pressed)
	if step == "choose":
		var i := -1
		if event.is_action_pressed("ui_left") or (event is InputEventKey and event.pressed and event.physical_keycode in [KEY_A, KEY_1, KEY_LEFT]):
			i = 0
		elif event.is_action_pressed("ui_right") or (event is InputEventKey and event.pressed and event.physical_keycode in [KEY_D, KEY_2, KEY_RIGHT]):
			i = 1
		if i >= 0 and i < _btns.size():
			_btns[i].grab_focus()
			get_viewport().set_input_as_handled()
		return
	if step == "end":
		if accept and _cont != null and _end_k > 0.9:
			get_viewport().set_input_as_handled()
			_complete()
		return
	if accept and _skip_t > 0.5:
		get_viewport().set_input_as_handled()
		_skip = true
		_voice.stop()


# ============================================================
#  הסצנה
# ============================================================
func _run() -> void:
	create_tween().tween_property(self, "_bars", 1.0, 0.8)
	Sfx.play("root_learn", _core(), 0.0, 0.0, 1, 0.7)
	await _wait(0.9)
	# הגיבור ניגש
	if player != null and player.global_position.x < _core().x - 300.0:
		player.auto_walk = 0.45
		var end := _clock + 3.0
		while player.global_position.x < _core().x - 300.0 and _clock < end and not _skip:
			await get_tree().process_frame
		player.auto_walk = 0.0
	_frame_two(1.3)
	await _lines(Data.ENDING.intro)
	_skip = false
	await _ask()


func _lines(arr: Array) -> void:
	for l in arr:
		if _skip:
			break
		await _say(String(l[0]), String(l[1]), String(l[2]))
		await _wait(float(l[3]))
	_line = ""


func _say(who: String, voice: String, text: String) -> void:
	_who = who
	_line = text
	_shown = 0.0
	lines_said += 1
	var st := _stream(String(Data.ENDING.voices) + voice + ".mp3")
	var dur := 0.8 + float(text.length()) * 0.055
	if st != null:
		_voice.stream = st
		_voice.play()
		dur = st.get_length() + 0.15
	await _wait(dur)


func _wait(sec: float) -> void:
	var end := _clock + sec
	while _clock < end and not _skip and is_inside_tree():
		await get_tree().process_frame


func _stream(path: String) -> AudioStream:
	if ResourceLoader.exists(path):
		var s := load(path) as AudioStream
		if s != null:
			return s
	if FileAccess.file_exists(path):
		var mp3 := AudioStreamMP3.new()
		mp3.data = FileAccess.get_file_as_bytes(path)
		return mp3
	return null


# ---- הבחירה ----
func _ask() -> void:
	step = "choose"
	_line = ""
	_who = "H"
	_frame_two(1.15)
	_ask_tw = create_tween()
	_ask_tw.tween_property(self, "_ask_k", 1.0, 0.8)
	var vs := get_viewport().get_visible_rect().size
	var names := ["DESTROY", "JOIN"]
	var accents := [Color("d01818"), Color("6ac83a")]
	for i in 2:
		var b := ButtonScript.new()
		b.text = names[i]
		b.font_size = 40
		b.accent = accents[i]
		b.size = Vector2(300.0, 76.0)
		b.position = Vector2(vs.x * 0.5 + (-340.0 if i == 0 else 40.0), vs.y * 0.5 + 20.0)
		b.appear_delay = 0.3 + 0.2 * float(i)
		_ui.add_child(b)
		b.pressed.connect(_choose.bind(i))
		_btns.append(b)
	_btns[0].focus_neighbor_right = _btns[1].get_path()
	_btns[1].focus_neighbor_left = _btns[0].get_path()
	_btns[0].focus_neighbor_left = _btns[0].get_path()
	_btns[1].focus_neighbor_right = _btns[1].get_path()


func _choose(i: int) -> void:
	if step != "choose":
		return
	choice = "destroy" if i == 0 else "join"
	Game.set_meta("ending_63", choice)
	step = "outro"
	_skip = false
	_skip_t = 0.0
	for b in _btns:
		b.queue_free()
	_btns.clear()
	if _ask_tw != null and _ask_tw.is_valid():   # בחירה מהירה: ההופעה עוד רצה - שלא תחזיר את השאלה אחרי הדעיכה
		_ask_tw.kill()
	create_tween().tween_property(self, "_ask_k", 0.0, 0.4)
	if choice == "destroy":
		await _destroy()
	else:
		await _join()
	_the_end()


# ---- DESTROY ----
func _destroy() -> void:
	_frame_two(1.3)
	await _lines(Data.ENDING.destroy)
	# יורה
	if player != null:
		player.unarmed = false
		player.idle_aim = (_core() - (player.global_position + Vector2(0, -36))).normalized()
	await _wait(0.5)
	_skip = false
	if player != null:
		player._muzzle_flash = 0.08
		_tracer_from = player.global_position + Vector2(18.0, -38.0)
	_tracer = 0.0
	Sfx.play("sniper", null, 2.0, 0.0, 1)
	Sfx.play("explosion", _core(), 4.0, 0.0, 1, 0.7)
	Sfx.play("root_roar", _core(), 2.0, 0.0, 1, 1.3)
	_white = 1.0
	create_tween().tween_property(self, "_white", 0.0, 1.6)
	var cam := _cam
	if cam != null:
		create_tween().tween_property(cam, "offset", Vector2(0, 0), 0.6).from(Vector2(14, -10))
	var rt = _rt()
	if rt != null:
		create_tween().tween_property(rt, "shattered", 1.0, 0.7)
	if main != null:
		Particles.burst(main, _core(), "hit", Vector2.LEFT, int(30.0 * Quality.gore()) + 6)
		Particles.burst(main, _core(), "mist", Vector2.UP, 12)
		Particles.burst(main, _core(), "spark", Vector2.LEFT, 12)
	await _wait(1.2)
	_skip = false
	# הכל כבה, נבגים אפורים, אור יום
	_life_to = 0.0
	_life_v = 0.25
	create_tween().tween_property(self, "_shaft", 1.0, 4.0)
	_spore_dir = 1.0
	if player != null:
		player.unarmed = true
		player.idle_aim = Vector2(1.0, 0.8).normalized()
	_cam_to = Vector2(_core().x - 260.0, 360.0)
	_zoom_to = 1.0
	await _wait(1.5)
	await _lines(Data.ENDING.destroy_after)


# ---- JOIN ----
func _join() -> void:
	_frame_two(1.3)
	await _lines(Data.ENDING.join)
	_skip = false
	# הולך אל הליבה
	if player != null:
		player.unarmed = true
		player.auto_walk = 0.35
		var end := _clock + 3.0
		while player.global_position.x < _core().x - 80.0 and _clock < end and not _skip:
			await get_tree().process_frame
		player.auto_walk = 0.0
		player.eye_color = Color(0.6, 1.0, 0.45)
	_cam_to = Vector2(_core().x - 120.0, 470.0)
	_zoom_to = 1.6
	Sfx.play("root_learn", _core(), 2.0, 0.0, 1, 0.8)
	create_tween().tween_property(self, "_tendril", 1.0, 1.4)
	var rt = _rt()
	if rt != null:
		create_tween().tween_property(rt, "embrace", 1.0, 1.4)
	await _wait(1.6)
	_skip = false
	# נמשך פנימה
	_pull = 0.0
	create_tween().tween_property(self, "_pull", 1.0, 1.8).set_trans(Tween.TRANS_SINE)
	if player != null:
		create_tween().tween_property(player, "modulate", Color(0.6, 1.0, 0.5, 0.0), 1.2)
	await _wait(1.9)
	_skip = false
	_white = 0.8
	create_tween().tween_property(self, "_white", 0.0, 1.8)
	Sfx.play("root_open", _core(), 4.0, 0.0, 1, 0.8)
	_life_to = 2.0
	_life_v = 0.3
	_spore_dir = -1.0
	_cam_to = Vector2(_core().x - 260.0, 360.0)
	_zoom_to = 1.0
	await _wait(1.2)
	await _lines(Data.ENDING.join_after)


# ---- THE END ----
func _the_end() -> void:
	step = "end"
	_line = ""
	_skip = false
	create_tween().tween_property(self, "_black", 0.88, 1.6)
	create_tween().tween_property(self, "_end_k", 1.0, 2.2)
	await _wait(2.4)
	var vs := get_viewport().get_visible_rect().size
	var b := ButtonScript.new()
	b.text = "CONTINUE"
	b.font_size = 32
	b.accent = Color("d01818") if choice == "destroy" else Color("6ac83a")
	b.size = Vector2(260.0, 64.0)
	b.position = Vector2((vs.x - 260.0) * 0.5, vs.y * 0.5 + 120.0)
	b.appear_delay = 0.2
	_ui.add_child(b)
	b.pressed.connect(_complete)
	_cont = b
	b.grab_focus()


func _complete() -> void:
	if step == "done":
		return
	step = "done"
	_voice.stop()
	var main_cam: Camera2D = null
	if player != null:
		for c in player.get_children():
			if c is Camera2D:
				main_cam = c
	if main_cam != null:
		main_cam.make_current()
	if _cam != null:
		_cam.queue_free()
	_ui.queue_free()
	hide()
	if main != null and main.has_method("_level_complete"):
		main._level_complete()


# ============================================================
#  ציור בעולם: הירייה, השורשים, הגוף שנמשך, אור היום, הנבגים
# ============================================================
func _draw() -> void:
	DrawBatch.begin(self)
	_draw_b()
	DrawBatch.end(self)


func _draw_b() -> void:
	var pts := PackedVector2Array()
	var cols := PackedColorArray()
	var c := _core() - global_position
	var t := _clock
	# אור יום מלמעלה (DESTROY)
	if _shaft > 0.01:
		var top := Vector2(c.x - 140.0, -700.0)
		U.quad(pts, cols, top + Vector2(-60, 0), top + Vector2(160, 0), Vector2(c.x + 140.0, 640.0), Vector2(c.x - 520.0, 640.0),
			Color(1.0, 0.95, 0.8, 0.22 * _shaft), Color(1.0, 0.95, 0.8, 0.22 * _shaft), Color(1.0, 0.9, 0.7, 0.0), Color(1.0, 0.9, 0.7, 0.0))
		U.quad(pts, cols, top + Vector2(10, 0), top + Vector2(90, 0), Vector2(c.x - 20.0, 640.0), Vector2(c.x - 300.0, 640.0),
			Color(1.0, 1.0, 0.9, 0.18 * _shaft), Color(1.0, 1.0, 0.9, 0.18 * _shaft), Color(1.0, 1.0, 0.9, 0.0), Color(1.0, 1.0, 0.9, 0.0))
		for i in 14:   # אבק באור
			var fx := c.x - 300.0 + U.h(i, 3) * 380.0 + sin(t * 0.4 + float(i)) * 20.0
			var fy := fposmod(U.h(i, 4) * 900.0 + t * 12.0, 900.0) - 300.0
			U.oval(pts, cols, Vector2(fx, fy), 1.6, 1.6, Color(1.0, 0.95, 0.8, 0.5 * _shaft), 6)
	# נבגים: אפורים נופלים / ירוקים עולים
	if _spore_dir != 0.0:
		var vs := get_viewport_rect().size / maxf(_cam.zoom.x if _cam != null else 1.0, 0.1)
		var org := (_cam.global_position if _cam != null else c) - vs * 0.5 - global_position
		for i in SPORES:
			var s := _spores[i]
			var y := s.y if _spore_dir > 0.0 else 1.0 - s.y
			var p := org + Vector2(s.x * vs.x + sin(t * 0.7 + float(i)) * 14.0, y * vs.y)
			var col := Color(0.62, 0.62, 0.58, 0.55 * s.z) if choice == "destroy" else Color(0.75, 1.0, 0.55, 0.75 * s.z)
			U.oval(pts, cols, p, 2.0 + 1.5 * s.z, 2.0 + 1.5 * s.z, col, 6)
	# השורשים עוטפים (JOIN)
	if _tendril > 0.01 and player != null:
		var pp: Vector2 = player.global_position - global_position
		if _pull > 0.0:
			pp = pp.lerp(c, _pull * _pull)
		for k in 7:   # שורשים מתעקלים מהליבה (בזייה, מתחדדים), כל אחד יוצא קצת אחרי הקודם, ובסוף נכרכים סביבו
			var a := c + Vector2(-34.0 - 8.0 * float(k % 2), -70.0 + float(k) * 24.0)
			var b := pp + Vector2(5.0 * sin(float(k) * 1.7), -6.0 - float(k) * 8.5)
			var ctrl := a.lerp(b, 0.5) + Vector2(0.0, -70.0 + 26.0 * float(k)) + Vector2(sin(t * 2.2 + float(k)), cos(t * 1.7 + float(k) * 0.7)) * 14.0
			var rk := clampf(_tendril * 1.5 - float(k) * 0.07, 0.0, 1.0)
			if rk <= 0.0:
				continue
			var prev := a
			var n := 14
			for q in n:
				var u := float(q + 1) / float(n) * rk
				var iu := 1.0 - u
				var pnt := a * iu * iu + ctrl * 2.0 * iu * u + b * u * u
				var w := lerpf(9.0, 2.5, u)
				U.seg(pts, cols, prev, pnt, w, Color("3a1c14").lerp(Color("5a3a1c"), u))
				if q % 4 == 3:
					U.oval(pts, cols, pnt, 2.4, 2.4, U.glow(Color(0.75, 1.0, 0.55, 0.65)), 6)
				prev = pnt
			if rk >= 1.0:   # נכרך סביבו: טבעת מסביב לגוף
				var wrap := clampf((_tendril - 0.75) * 4.0, 0.0, 1.0)
				var cy := b + Vector2(0.0, -4.0)
				var last := cy + Vector2(13.0, 0.0)
				for j in 9:
					var an := float(j + 1) / 9.0 * TAU * wrap
					var rp := cy + Vector2(cos(an) * 13.0, sin(an) * 4.5)
					U.seg(pts, cols, last, rp, 3.0 if sin(an) > 0.0 else 2.0, Color("5a3a1c") if sin(an) > 0.0 else Color("2a140e"))
					last = rp
				U.oval(pts, cols, b, 3.0, 3.0, Color(0.75, 1.0, 0.55, 0.8), 6)
	# הגוף שנמשך אל הליבה (צללית זוהרת)
	if _pull > 0.0 and player != null:
		var p0: Vector2 = player.global_position - global_position
		var p := p0.lerp(c + Vector2(0, 40), _pull * _pull)
		var sc := 1.0 - 0.4 * _pull
		U.hero(pts, cols, p, sc, 0, Color(0.75, 1.0, 0.55, 0.85 * (1.0 - _pull * 0.7)), 1.0)
	U.flush(self, pts, cols)
	# הירייה (DESTROY)
	if _tracer >= 0.0:
		var a := 1.0 - _tracer / 0.18
		DrawBatch.line(self, _tracer_from - global_position, c, Color(1.0, 0.9, 0.6, a), 4.0)
		DrawBatch.line(self, _tracer_from - global_position, c, Color(1, 1, 1, a), 1.5)


# ============================================================
#  ציור על המסך: פסים, כתוביות, השאלה, THE END
# ============================================================
static func _f() -> Font:
	if _font != null:
		return _font
	if ResourceLoader.exists(FONT_PATH):
		_font = load(FONT_PATH) as Font
	if _font == null and FileAccess.file_exists(FONT_PATH):
		var ff := FontFile.new()
		if ff.load_dynamic_font(FONT_PATH) == OK:
			_font = ff
	if _font == null:
		_font = ThemeDB.fallback_font
	return _font


func _on_ui_draw() -> void:
	DrawBatch.begin(_ui_draw)
	_ui_b()
	DrawBatch.end(_ui_draw)


func _centered(f: Font, y: float, text: String, fs: int, col: Color, outline := 6) -> void:
	var vs := _ui_draw.get_viewport_rect().size
	var w := f.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	var p := Vector2((vs.x - w) * 0.5, y)
	DrawBatch.string_outline(_ui_draw, f, p, text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, outline, Color(0, 0, 0, col.a * 0.9))
	DrawBatch.string(_ui_draw, f, p, text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, col)


func _ui_b() -> void:
	var vs := _ui_draw.get_viewport_rect().size
	var f := _f()
	if _white > 0.0:
		DrawBatch.rect(_ui_draw, Rect2(Vector2.ZERO, vs), Color(1, 1, 1, _white))
	var bh := BAR_H * _bars
	DrawBatch.rect(_ui_draw, Rect2(0, 0, vs.x, bh), Color.BLACK)
	DrawBatch.rect(_ui_draw, Rect2(0, vs.y - bh, vs.x, bh), Color.BLACK)
	if _black > 0.0:
		DrawBatch.rect(_ui_draw, Rect2(Vector2.ZERO, vs), Color(0, 0, 0, _black))
	# כתובית
	if _line != "" and step != "end":
		var names: Dictionary = Data.ENDING.names
		var name: String = names.get(_who, "")
		var col := Color(0.75, 0.88, 1.0)
		if _who == "H":
			col = Color(0.75, 1.0, 0.55)
		elif _who == "U":
			col = Color(0.85, 1.0, 0.9)
		var txt := _line.substr(0, int(_shown))
		var y := vs.y - 30.0
		var w := f.get_string_size(name + "   " + _line, HORIZONTAL_ALIGNMENT_LEFT, -1, 28).x
		var x := maxf((vs.x - w) * 0.5, 20.0)
		DrawBatch.string_outline(_ui_draw, f, Vector2(x, y), name, HORIZONTAL_ALIGNMENT_LEFT, -1, 28, 6, Color.BLACK)
		DrawBatch.string(_ui_draw, f, Vector2(x, y), name, HORIZONTAL_ALIGNMENT_LEFT, -1, 28, col)
		var nx := x + f.get_string_size(name + "   ", HORIZONTAL_ALIGNMENT_LEFT, -1, 28).x
		DrawBatch.string_outline(_ui_draw, f, Vector2(nx, y), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 28, 6, Color.BLACK)
		DrawBatch.string(_ui_draw, f, Vector2(nx, y), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 28, Color(0.96, 0.95, 0.9))
	# השאלה
	if _ask_k > 0.01:
		DrawBatch.rect(_ui_draw, Rect2(0, vs.y * 0.5 - 110.0, vs.x, 230.0), Color(0, 0, 0, 0.45 * _ask_k))
		_centered(f, vs.y * 0.5 - 40.0, "WHAT DO YOU DO, ZERO?", 40, Color(1.0, 0.95, 0.9, _ask_k))
		var hint := "TAP A CHOICE" if TouchAPI.on() else "LEFT / RIGHT  +  ENTER    or    CLICK"
		_centered(f, vs.y * 0.5 + 140.0, hint, 18, Color(1, 1, 1, 0.5 * _ask_k), 4)
		DrawBatch.string(_ui_draw, f, Vector2(vs.x * 0.5 - 330.0, vs.y * 0.5 + 122.0), "End the hive. Forever.", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(1.0, 0.7, 0.65, 0.8 * _ask_k))
		DrawBatch.string(_ui_draw, f, Vector2(vs.x * 0.5 + 50.0, vs.y * 0.5 + 122.0), "Go home. Become one.", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(0.75, 1.0, 0.6, 0.8 * _ask_k))
	# THE END
	if _end_k > 0.01:
		var a := clampf(_end_k * 1.4, 0.0, 1.0)
		_centered(f, vs.y * 0.5 - 30.0, "THE END", 96, Color(1.0, 0.96, 0.9, a), 8)
		var sub := "ENDING:  DESTROY  -  THE HIVE IS SILENT" if choice == "destroy" else "ENDING:  JOIN  -  EVERY MIND IS ONE"
		var sc := Color(1.0, 0.6, 0.55, clampf(_end_k * 1.4 - 0.4, 0.0, 1.0)) if choice == "destroy" else Color(0.7, 1.0, 0.55, clampf(_end_k * 1.4 - 0.4, 0.0, 1.0))
		_centered(f, vs.y * 0.5 + 30.0, sub, 26, sc, 5)
		_centered(f, vs.y * 0.5 + 70.0, "THEY LEARNED YOU.", 20, Color(1, 1, 1, 0.55 * clampf(_end_k * 1.4 - 0.6, 0.0, 1.0)), 4)
	if step == "talk" or step == "outro":
		if _bars > 0.5:
			DrawBatch.string(_ui_draw, f, Vector2(vs.x - 150.0, 50.0), "ENTER  -  SKIP", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(1, 1, 1, 0.45))
