extends Node
# ============================================================
#  STORY SCENE - סצנת סיפור בתוך השלב (חלק מהמשחק, לא סרטון): השחקן הולך בשלב בעצמו, רואה דמות עומדת מולו
#  (story/story_trigger.gd), וכשהוא מספיק קרוב - המשחק לוקח שליטה: עוצר, מרים נשק, מתקרב לאט, ושיחה.
#  מצלמה משלה (שוטים: שני-שוט, תקריבים, מבט אחורה), תמיד עם הרצפה בפריים. פסים שחורים, כתוביות עם קול.
#  בסוף (ending): "vanish" = חיתוך לשחור + בום, הדמות נעלמת, והמשחק ממשיך מאותו מקום.
#  ENTER / SPACE = דילוג. הכל קפוא בזמן הסצנה.
#  הסצנות עצמן (טקסט, קולות, שוטים) = קבצים ב-story/scenes/, רשומים ב-story/story_db.gd.
# ============================================================

const Art := preload("res://art.gd")
const Sfx := preload("res://sfx.gd")
const FONT_PATH := "res://fonts/Bangers-Regular.ttf"
const BAR_H := 78.0            # גובה הפסים השחורים (במסך)
const LOW_READY := Vector2(1.0, 0.8)   # השחקן מחזיק את הנשק למטה באלכסון (מכסה את היד השנייה שבספרייט)

var data: Dictionary = {}      # הסצנה (story/scenes/*.gd -> SCENE)
var main: Node = null
var player: Node2D = null
var hud_layer: CanvasLayer = null
var actor: Node2D = null       # הדמות שמדברים איתה (נוצרה ע"י הטריגר)
var done := false
var _cam: Camera2D
var _ui: CanvasLayer
var _draw: Node2D
var _voice: AudioStreamPlayer
var _frozen: Array = []
var _hidden: Array = []
var _cam_tw: Tween = null   # תנועת המצלמה הנוכחית (נעצרת בשוט הבא)
var _floor := 0.0
var _follow := ""           # המצלמה עוקבת: "two" (התקרבות) / "" (שוטים)
var _bars := 0.0            # פסים שחורים 0..1
var _black := 0.0           # מסך שחור
var _who := ""
var _line := ""
var _shown := 0.0           # כמה אותיות מוצגות
var _skip_t := 0.0
var _clock := 0.0           # זמן הסצנה (נעצר ב-PAUSE)
static var _font: Font = null


func _dist() -> float:
	return float(data.get("dist", 300.0))


func _ready() -> void:
	Game.story_seen[data.id] = true
	_ui = CanvasLayer.new()
	_ui.layer = 8
	add_child(_ui)
	_draw = Node2D.new()
	_ui.add_child(_draw)
	_draw.draw.connect(_on_draw)
	_voice = AudioStreamPlayer.new()
	_voice.bus = "SFX" if AudioServer.get_bus_index("SFX") >= 0 else "Master"
	add_child(_voice)
	_floor = player.global_position.y
	player.controllable = false
	player.auto_walk = 0.0
	player.calm = true
	player.unarmed = true   # בלי נשק בסצנה (רק הספרייט)
	main.clock_paused = true   # השעון של השלב עוצר בזמן השיחה
	player.idle_aim = LOW_READY.normalized()
	for zz in get_tree().get_nodes_in_group("zombies"):   # כולם קופאים בזמן הסצנה
		if zz.is_physics_processing():
			zz.set_physics_process(false)
			_frozen.append(zz)
	var x0: float = player.global_position.x - 200.0
	var x1: float = actor.global_position.x + 520.0
	for n in get_tree().get_nodes_in_group("zombies") + get_tree().get_nodes_in_group("pickups"):   # לא באמצע השיחה
		if n is Node2D and n.visible and n.global_position.x > x0 and n.global_position.x < x1:
			n.visible = false
			_hidden.append(n)
	if hud_layer != null:
		hud_layer.visible = false
	_cam = Camera2D.new()
	main.add_child(_cam)
	var cur := get_viewport().get_camera_2d()
	_cam.global_position = cur.get_screen_center_position() if cur != null else player.global_position
	_cam.zoom = cur.zoom if cur != null else Vector2.ONE
	_cam.make_current()
	_run()


func _process(delta: float) -> void:
	_clock += delta
	_skip_t += delta
	player._invuln = maxf(player._invuln, 0.5)
	if _line != "":
		_shown += delta * 40.0
	if _follow != "" and _cam != null:
		var k := 1.0 - exp(-delta * 3.0)
		_cam.global_position = _cam.global_position.lerp(_follow_target(), k)
		_cam.zoom = _cam.zoom.lerp(Vector2(2.3, 2.3), k)
	_draw.queue_redraw()


func _follow_target() -> Vector2:
	var px: float = player.global_position.x + 170.0
	if actor != null and is_instance_valid(actor):
		px = (player.global_position.x + actor.global_position.x) * 0.5
	return _frame(px, 2.3)


# מרכז מצלמה לזום z כך שהרצפה תמיד בפריים: low = כמה מתחת למרכז התמונה (בין הפסים) נמצאות כפות הרגליים
# (0.3 = ב-80% מהגובה) - תמיד רואים רצועת אדמה מתחת לדמויות, כמו מצלמה שמסתכלת קצת מלמעלה
func _frame(x: float, z: float, low := 0.25) -> Vector2:
	var vs: Vector2 = get_viewport().get_visible_rect().size
	var h: float = (vs.y - BAR_H * 2.0) / z
	x = maxf(x, vs.x * 0.5 / z + 4.0)   # לא מראים את קצה העולם (שמאל לתחילת השלב)
	return Vector2(x, _floor - h * low)


func _unhandled_input(event: InputEvent) -> void:
	if done or _skip_t < 0.6:
		return
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode in [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE]:
		get_viewport().set_input_as_handled()
		_finish()


# ============================================================
#  הסצנה
# ============================================================
func _run() -> void:
	var tw := create_tween()
	tw.tween_property(self, "_bars", 1.0, 0.8)
	_follow = "two"
	await _wait(1.1)
	if done:
		return
	# מתקרב לאט, הרובה עליו
	player.auto_walk = 0.42 * signf(actor.global_position.x - player.global_position.x)
	await _walk_to(actor.global_position.x - _dist(), 6.0)
	player.auto_walk = 0.0
	if done:
		return
	await _wait(0.5)
	_follow = ""
	for b in data.beats:
		if done:
			return
		_shot(b[3], b[3] != "behind")
		_act(b[4])
		await _say(b[0], b[1], b[2])
		if done:
			return
		await _wait(float(b[5]))
	if done:
		return
	match String(data.get("ending", "vanish")):
		"leap":   # מתכופף, וקופץ גבוה החוצה מהמסך (דמות חוזרת)
			_line = ""
			await _leap()
			await _wait(0.8)
		_:   # vanish: חיתוך לשחור + בום, הדמות נעלמת בחושך (דמות חוזרת)
			_black = 1.0
			_line = ""
			Sfx.play("explosion", null, 0.0, 0.0, 1, 0.55)
			if actor != null and is_instance_valid(actor):
				actor.queue_free()
				actor = null
			await _wait(1.1)
	_finish()


func _leap() -> void:
	if actor == null or not is_instance_valid(actor):
		return
	actor.set_physics_process(false)
	var p0: Vector2 = actor.position
	var away := signf(actor.global_position.x - player.global_position.x)
	var tw := create_tween()
	tw.tween_property(actor, "scale", Vector2(1.08, 0.82), 0.22).set_trans(Tween.TRANS_SINE)   # מתכופף
	tw.parallel().tween_property(actor, "position:y", p0.y + 3.0, 0.22)
	tw.tween_callback(func(): Sfx.play("jump", actor.global_position, 2.0, 0.0, 1, 0.7))
	tw.tween_callback(func(): Sfx.play("whoosh", actor.global_position, 0.0, 0.0, 1, 0.8))
	tw.tween_property(actor, "scale", Vector2(0.9, 1.15), 0.08)   # נמתח בזינוק
	tw.tween_property(actor, "position:y", p0.y - 520.0, 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(actor, "position:x", p0.x + away * 160.0, 0.5)
	tw.parallel().tween_property(actor, "rotation", away * 0.35, 0.5)
	await _wait(0.85)
	if actor != null and is_instance_valid(actor):
		actor.queue_free()
		actor = null


# הליכה אוטומטית עד x (אם משהו חוסם - אחרי max_t שניות ממשיכים מאיפה שהוא)
func _walk_to(x: float, max_t: float) -> void:
	var end := _clock + max_t
	while not done and player.global_position.x < x and _clock < end:
		await get_tree().process_frame


func _wait(sec: float) -> void:
	var end := _clock + sec
	while _clock < end and not done:
		await get_tree().process_frame


func _say(who: String, voice: String, text: String) -> void:
	_who = who
	_line = text
	_shown = 0.0
	_set_actor("talking", who != "P")
	var st := _stream(String(data.voices) + voice + ".mp3")
	var dur := 0.6 + float(text.length()) * 0.055
	if st != null:
		_voice.stream = st
		_voice.play()
		dur = st.get_length() + 0.15
	await _wait(dur)
	_set_actor("talking", false)


func _set_actor(prop: String, v) -> void:
	if actor != null and is_instance_valid(actor) and actor.type_mod != null and prop in actor.type_mod:
		actor.type_mod.set(prop, v)


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


# שוטים: איפה המצלמה ובאיזה זום. cut = חיתוך מיידי, אחרת תנועה איטית.
# כל השוטים דרך _frame: הרצפה ורצועת אדמה תמיד בתמונה, הדמויות מלאות מכף רגל ועד ראש
func _shot(name: String, cut: bool) -> void:
	var px: float = player.global_position.x
	var zx: float = actor.global_position.x if actor != null and is_instance_valid(actor) else px + _dist()
	var x := (px + zx) * 0.5
	var zoom := 2.4
	var low := 0.25
	var dur := 0.0
	if _cam_tw != null and _cam_tw.is_valid():
		_cam_tw.kill()
	match name:
		"cu_p":
			x = px + 22.0
			zoom = 4.6
			low = 0.3
		"cu_z":
			x = zx - 22.0
			zoom = 4.6
			low = 0.3
		"cu_z2":
			x = zx - 8.0
			zoom = 5.3
			low = 0.32
		"xcu_z":   # חיתוך חד, ואז זחילה איטית פנימה
			_cam.global_position = _frame(zx - 6.0, 5.3, 0.32)
			_cam.zoom = Vector2(5.3, 5.3)
			_cam_tw = create_tween().set_trans(Tween.TRANS_SINE)
			_cam_tw.tween_property(_cam, "zoom", Vector2(5.9, 5.9), 1.4)
			_cam_tw.parallel().tween_property(_cam, "global_position", _frame(zx - 4.0, 5.9, 0.34), 1.4)
			return
		"behind":   # המצלמה זזה מאחורי השחקן - הרחוב הריק שממנו הגיע
			x = px - 230.0
			zoom = 2.6
			dur = 2.4
	var target := _frame(x, zoom, low)
	if cut and dur == 0.0:
		_cam.global_position = target
		_cam.zoom = Vector2(zoom, zoom)
	else:
		var tw := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		_cam_tw = tw
		tw.tween_property(_cam, "global_position", target, maxf(dur, 0.8))
		tw.parallel().tween_property(_cam, "zoom", Vector2(zoom, zoom), maxf(dur, 0.8))


func _act(a: String) -> void:
	var tm = actor.type_mod if actor != null and is_instance_valid(actor) else null
	match a:
		"aim":   # מכוון לראש
			player.idle_aim = Vector2(1.0, -0.12).normalized()
		"lower":   # מוריד את הרובה (מצב ברירת המחדל בסצנה)
			player.idle_aim = LOW_READY.normalized()
		"tilt":
			if tm != null:
				create_tween().tween_property(tm, "tilt", 0.22, 0.4)
		"untilt":
			if tm != null:
				create_tween().tween_property(tm, "tilt", 0.0, 0.4)
		"grin":
			if tm != null:
				create_tween().tween_property(tm, "tilt", 0.0, 0.3)
				create_tween().tween_property(tm, "smile", 0.5, 0.5)
		"look_back":   # הזומבי מסתכל מאחורי השחקן
			if tm != null:
				create_tween().tween_property(tm, "look_back", 1.0, 0.6)
		"turn_back":   # השחקן מסתובב להסתכל אחורה
			await _wait(0.9)
			player.idle_aim = Vector2.LEFT
		"face":   # חוזר לזומבי
			player.idle_aim = Vector2.RIGHT
			if tm != null:
				tm.look_back = 0.0
				create_tween().tween_property(tm, "smile", 0.7, 0.4)
		"smile":
			if tm != null:
				tm.tilt = 0.0
				create_tween().tween_property(tm, "smile", 1.0, 0.6)


func _finish() -> void:
	if done:
		return
	done = true
	_voice.stop()
	_line = ""
	if actor != null and is_instance_valid(actor):
		actor.queue_free()   # גם בדילוג - נעלם
		actor = null
	for zz in _frozen:
		if is_instance_valid(zz):
			zz.set_physics_process(true)
	for n in _hidden:
		if is_instance_valid(n):
			n.visible = true
	player.auto_walk = 0.0
	player.calm = false
	player.unarmed = false
	main.clock_paused = false
	player.controllable = true
	player.idle_aim = Vector2.RIGHT
	var main_cam: Camera2D = null
	for c in player.get_children():
		if c is Camera2D:
			main_cam = c
	if main_cam != null:
		main_cam.make_current()
		main_cam.reset_smoothing()
	_cam.queue_free()
	if hud_layer != null:
		hud_layer.visible = true
	_black = 1.0
	var tw := create_tween()
	tw.tween_property(self, "_bars", 0.0, 0.5)
	tw.parallel().tween_property(self, "_black", 0.0, 0.9)
	tw.tween_callback(queue_free)


# ============================================================
#  ציור: פסים שחורים, כתוביות, שחור, THEY LEARN
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


func _on_draw() -> void:
	var vs := _draw.get_viewport_rect().size
	var f := _f()
	var bh := BAR_H * _bars
	_draw.draw_rect(Rect2(0, 0, vs.x, bh), Color.BLACK)
	_draw.draw_rect(Rect2(0, vs.y - bh, vs.x, bh), Color.BLACK)
	if _black > 0.0:
		_draw.draw_rect(Rect2(Vector2.ZERO, vs), Color(0, 0, 0, _black))
	if _line != "" and _black < 0.5:
		var name: String = data.get("names", {}).get(_who, "YOU" if _who == "P" else "")
		var col := Color(0.75, 0.88, 1.0) if _who == "P" else Color(1.0, 0.35, 0.28)
		if name == "":   # בלי שם: רק הטקסט, באמצע
			var tw0 := f.get_string_size(_line, HORIZONTAL_ALIGNMENT_LEFT, -1, 30).x
			var p0 := Vector2((vs.x - tw0) * 0.5, vs.y - 30.0)
			_draw.draw_string_outline(f, p0, _line.substr(0, int(_shown)), HORIZONTAL_ALIGNMENT_LEFT, -1, 30, 6, Color.BLACK)
			_draw.draw_string(f, p0, _line.substr(0, int(_shown)), HORIZONTAL_ALIGNMENT_LEFT, -1, 30, Color(0.96, 0.95, 0.9))
		else:
			var txt := _line.substr(0, int(_shown))
			var y := vs.y - 30.0
			var w := f.get_string_size(name + "   " + _line, HORIZONTAL_ALIGNMENT_LEFT, -1, 30).x
			var x := (vs.x - w) * 0.5
			_draw.draw_string_outline(f, Vector2(x, y), name, HORIZONTAL_ALIGNMENT_LEFT, -1, 30, 6, Color.BLACK)
			_draw.draw_string(f, Vector2(x, y), name, HORIZONTAL_ALIGNMENT_LEFT, -1, 30, col)
			var nx := x + f.get_string_size(name + "   ", HORIZONTAL_ALIGNMENT_LEFT, -1, 30).x
			_draw.draw_string_outline(f, Vector2(nx, y), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 30, 6, Color.BLACK)
			_draw.draw_string(f, Vector2(nx, y), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 30, Color(0.96, 0.95, 0.9))
	if not done and _bars > 0.5:
		_draw.draw_string(f, Vector2(vs.x - 150.0, 50.0), "ENTER  -  SKIP", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(1, 1, 1, 0.45))
