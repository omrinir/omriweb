extends Node
# ============================================================
#  סצנת הפתיחה של שלב 1 - "FIRST ENCOUNTER". סינמטיקה בתוך המשחק עם הדמויות של המשחק:
#  השחקן פוגש זומבי שמדבר (STRANGER - enemies/types/stranger.gd: שרירי, חצי גולגולת מתכת, יד רובוטית).
#  מצלמה משלה (שוטים: רחב, תקריבים, שני-שוט, תנועה מאחורי השחקן), פסים שחורים, כתוביות עם קול,
#  ובסוף: חיתוך לשחור -> THEY LEARN -> משחק. הזומבי נעלם בחושך (דמות חוזרת).
#  מתנגן פעם אחת (Game.intro_seen נשמר). ENTER / SPACE = דילוג.
#  קולות: sounds/intro/p01..p05 (השחקן), z01..z08 (הזומבי).
#  לשנות: BEATS (סדר המשפטים, השוטים והפעולות), DIST.
# ============================================================

const Art := preload("res://art.gd")
const Sfx := preload("res://sfx.gd")
const Registry := preload("res://enemies/zombie_registry.gd")
const FONT_PATH := "res://fonts/Bangers-Regular.ttf"
const VOICE_DIR := "res://sounds/intro/"
const DIST := 330.0            # מרחק בין השחקן לזומבי

# [מי, קול, טקסט, שוט, פעולה, הפסקה אחרי]
# שוטים: wide / cu_p / cu_z / cu_z2 / two / behind / xcu_z.  פעולות: lower / raise / tilt / look_back / turn_back / smile
const BEATS := [
	["Z", "z01", "Hello, friend.", "wide", "", 0.5],
	["P", "p01", "...Friend? You're a fucking zombie.", "cu_p", "lower", 0.3],
	["Z", "z02", "That's true.", "cu_z", "tilt", 0.25],
	["P", "p02", "You're dead meat, waiting to be ground up.", "cu_p", "raise", 0.2],
	["Z", "z03", "Technically... I already am.", "cu_z2", "tilt", 0.9],
	["P", "p03", "Then why are you talking to me?", "two", "", 0.2],
	["Z", "z04", "Because I know what's coming.", "two", "", 0.3],
	["Z", "z05", "When they come... you'll need a friend.", "behind", "look_back", 0.4],
	["P", "p04", "There's nothing behind me.", "behind", "turn_back", 0.3],
	["Z", "z06", "I didn't say there was.", "two", "", 1.8],
	["Z", "z07", "I'm trying to save you.", "cu_z2", "smile", 0.3],
	["P", "p05", "From what?", "cu_p", "", 0.35],
	["Z", "z08", "From us.", "xcu_z", "smile", 0.6],
]

var main: Node = null
var player: Node2D = null
var hud_layer: CanvasLayer = null
var hud_bar: Node = null
var stranger: Node2D = null
var done := false
var _cam: Camera2D
var _ui: CanvasLayer
var _draw: Node2D
var _voice: AudioStreamPlayer
var _frozen: Array = []
var _hidden: Array = []
var _cam_tw: Tween = null   # תנועת המצלמה הנוכחית (נעצרת בשוט הבא)     # מכוניות / ארגזים בין השחקן לזומבי - מוסתרים בזמן הסצנה
var _bars := 0.0            # פסים שחורים 0..1
var _black := 0.0           # מסך שחור
var _title := 0.0           # THEY LEARN
var _who := ""
var _line := ""
var _shown := 0.0           # כמה אותיות מוצגות
var _skip_t := 0.0
var _clock := 0.0           # זמן הסצנה (נעצר ב-PAUSE)
static var _font: Font = null


func _ready() -> void:
	Game.intro_seen = true
	Game._save()
	_ui = CanvasLayer.new()
	_ui.layer = 8
	add_child(_ui)
	_draw = Node2D.new()
	_ui.add_child(_draw)
	_draw.draw.connect(_on_draw)
	_voice = AudioStreamPlayer.new()
	_voice.bus = "SFX" if AudioServer.get_bus_index("SFX") >= 0 else "Master"
	add_child(_voice)
	# הבמה: השחקן קצת פנימה, הזומבי מולו
	var floor_y: float = player.global_position.y
	player.global_position.x = maxf(player.global_position.x, 520.0)
	player.controllable = false
	player.idle_aim = Vector2.RIGHT
	for zz in get_tree().get_nodes_in_group("zombies"):   # כולם קופאים בזמן הסצנה
		if zz.is_physics_processing():
			zz.set_physics_process(false)
			_frozen.append(zz)
	stranger = main._spawn_zombie(player.global_position.x + DIST, floor_y, Registry.STRANGER)
	stranger.dormant = false
	stranger._dir = -1.0
	stranger.remove_from_group("zombies")   # לא מטרה, לא נספר
	stranger.collision_layer = 0
	var x0: float = player.global_position.x - 40.0
	var x1: float = stranger.global_position.x + 60.0
	for n in main.get_children():   # מפנים את הבמה (חוזרים בסוף, מתחת למסך השחור)
		var scr: String = n.get_script().resource_path if n.get_script() != null else ""
		var clutter: bool = n.is_in_group("blastable") or n.is_in_group("pickups") or n.is_in_group("zombies") or n.is_in_group("cover") \
			or scr.ends_with("prop.gd") or scr.ends_with("fire.gd") or scr.ends_with("street_prop.gd")
		if n is Node2D and n.visible and n != player and n != stranger and clutter:
			var nx: float = (n as Node2D).global_position.x
			if nx > x0 - 260.0 and nx < x1 + 420.0:
				n.visible = false
				_hidden.append(n)
	if hud_layer != null:
		hud_layer.visible = false
	_cam = Camera2D.new()
	main.add_child(_cam)
	_cam.make_current()
	_run()


func _process(delta: float) -> void:
	_clock += delta
	_skip_t += delta
	if _line != "":
		_shown += delta * 34.0
	if stranger != null and is_instance_valid(stranger):
		stranger.type_mod.t += delta
		stranger._time += delta
		stranger.queue_redraw()
	_draw.queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if done or _skip_t < 0.6:
		return
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode in [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE]:
		get_viewport().set_input_as_handled()
		_finish(true)


# ============================================================
#  הסצנה
# ============================================================
func _run() -> void:
	var tw := create_tween()
	tw.tween_property(self, "_bars", 1.0, 0.8)
	_shot("wide", true)
	await _wait(1.0)
	for b in BEATS:
		if done:
			return
		_shot(b[3], b[3] != "behind" and b[3] != "wide")
		_act(b[4])
		await _say(b[0], b[1], b[2])
		if done:
			return
		await _wait(float(b[5]))
	if done:
		return
	# חיתוך לשחור + בום + THEY LEARN
	_black = 1.0
	_line = ""
	Sfx.play("explosion", null, 2.0, 0.0, 1, 0.55)
	if stranger != null and is_instance_valid(stranger):
		stranger.queue_free()   # נעלם בחושך
		stranger = null
	await _wait(0.6)
	var t2 := create_tween()
	t2.tween_property(self, "_title", 1.0, 0.5)
	await _wait(2.6)
	if done:
		return
	var t3 := create_tween()
	t3.tween_property(self, "_title", 0.0, 0.5)
	await _wait(0.5)
	_finish(false)


func _wait(sec: float) -> void:
	var end := _clock + sec
	while _clock < end and not done:
		await get_tree().process_frame


func _say(who: String, voice: String, text: String) -> void:
	_who = who
	_line = text
	_shown = 0.0
	if stranger != null and is_instance_valid(stranger):
		stranger.type_mod.talking = who == "Z"
	var st := _stream(VOICE_DIR + voice + ".mp3")
	var dur := 0.6 + float(text.length()) * 0.055
	if st != null:
		_voice.stream = st
		_voice.play()
		dur = st.get_length() + 0.15
	await _wait(dur)
	if stranger != null and is_instance_valid(stranger):
		stranger.type_mod.talking = false


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


# שוטים: איפה המצלמה ובאיזה זום. cut = חיתוך מיידי, אחרת תנועה איטית
func _shot(name: String, cut: bool) -> void:
	var pp: Vector2 = player.global_position + Vector2(0, -42)
	var zp: Vector2 = stranger.global_position + Vector2(0, -52) if stranger != null and is_instance_valid(stranger) else pp
	var mid := (pp + zp) * 0.5
	var target := mid
	var zoom := 1.0
	var dur := 0.0
	if _cam_tw != null and _cam_tw.is_valid():
		_cam_tw.kill()
	match name:
		"wide":
			var vs0: Vector2 = _cam.get_viewport_rect().size
			_cam.global_position = Vector2(maxf(mid.x, vs0.x * 0.5 + 4.0), mid.y - 60.0)
			_cam.zoom = Vector2.ONE
			var tw := create_tween().set_trans(Tween.TRANS_SINE)
			_cam_tw = tw
			tw.tween_property(_cam, "zoom", Vector2(1.25, 1.25), 5.0)
			tw.parallel().tween_property(_cam, "global_position", Vector2(maxf(mid.x, vs0.x * 0.5 / 1.25 + 4.0), mid.y - 30.0), 5.0)
			return
		"cu_p":
			target = pp + Vector2(16, -8)
			zoom = 4.2
		"cu_z":
			target = zp + Vector2(-12, 10)
			zoom = 4.2
		"cu_z2":
			target = zp + Vector2(-6, 6)
			zoom = 5.6
		"xcu_z":
			# חיתוך חד לפנים, ואז זחילה איטית פנימה
			var t0 := zp + Vector2(-2, -2)
			_cam.global_position = t0
			_cam.zoom = Vector2(6.0, 6.0)
			_cam_tw = create_tween().set_trans(Tween.TRANS_SINE)
			_cam_tw.tween_property(_cam, "zoom", Vector2(8.0, 8.0), 1.6)
			return
		"two":
			target = mid + Vector2(0, -12)
			zoom = 1.6
		"behind":   # המצלמה זזה מאחורי השחקן - הרחוב הריק
			target = pp + Vector2(-280, -10)
			zoom = 1.7
			dur = 2.6
	var vs: Vector2 = _cam.get_viewport_rect().size
	target.x = maxf(target.x, vs.x * 0.5 / zoom + 4.0)   # לא מראים את קצה העולם (שמאל לתחילת השלב)
	if cut and dur == 0.0:
		_cam.global_position = target
		_cam.zoom = Vector2(zoom, zoom)
	else:
		var tw := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		_cam_tw = tw
		tw.tween_property(_cam, "global_position", target, maxf(dur, 0.8))
		tw.parallel().tween_property(_cam, "zoom", Vector2(zoom, zoom), maxf(dur, 0.8))


func _act(a: String) -> void:
	var tm = stranger.type_mod if stranger != null and is_instance_valid(stranger) else null
	match a:
		"lower":   # מוריד קצת את הרובה
			player.idle_aim = Vector2(1.0, 0.45).normalized()
		"raise":
			player.idle_aim = Vector2.RIGHT
		"tilt":
			if tm != null:
				create_tween().tween_property(tm, "tilt", 0.22 if tm.tilt < 0.1 else 0.0, 0.5)
		"look_back":   # הזומבי מסתכל מאחורי השחקן
			if tm != null:
				create_tween().tween_property(tm, "look_back", 1.0, 0.8)
		"turn_back":   # השחקן מסתובב להסתכל אחורה... ואז חוזר
			player.idle_aim = Vector2.LEFT
			await _wait(1.6)
			player.idle_aim = Vector2.RIGHT
			if tm != null:
				tm.look_back = 0.0
		"smile":
			if tm != null:
				tm.tilt = 0.0
				create_tween().tween_property(tm, "smile", 1.0, 0.7)


func _finish(skipped: bool) -> void:
	if done:
		return
	done = true
	_voice.stop()
	_line = ""
	if stranger != null and is_instance_valid(stranger):
		stranger.queue_free()
		stranger = null
	for zz in _frozen:
		if is_instance_valid(zz):
			zz.set_physics_process(true)
	for n in _hidden:
		if is_instance_valid(n):
			n.visible = true
	player.controllable = true
	player.idle_aim = Vector2.RIGHT
	var main_cam := player.get_node_or_null("Camera2D") as Camera2D
	for c in player.get_children():
		if c is Camera2D:
			main_cam = c
	if main_cam != null:
		main_cam.make_current()
		main_cam.reset_smoothing()
	_cam.queue_free()
	if hud_layer != null:
		hud_layer.visible = true
	if hud_bar != null:
		hud_bar._intro_t = 0.0   # כותרת השלב מתחילה עכשיו
	_black = 1.0
	_title = 0.0 if not skipped else _title
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
	var bh := 78.0 * _bars
	_draw.draw_rect(Rect2(0, 0, vs.x, bh), Color.BLACK)
	_draw.draw_rect(Rect2(0, vs.y - bh, vs.x, bh), Color.BLACK)
	if _black > 0.0:
		_draw.draw_rect(Rect2(Vector2.ZERO, vs), Color(0, 0, 0, _black))
	if _line != "" and _black < 0.5:
		var name := "???" if _who == "Z" else "YOU"
		var col := Color(1.0, 0.35, 0.28) if _who == "Z" else Color(0.75, 0.88, 1.0)
		var txt := _line.substr(0, int(_shown))
		var y := vs.y - 30.0
		var w := f.get_string_size(name + "   " + _line, HORIZONTAL_ALIGNMENT_LEFT, -1, 30).x
		var x := (vs.x - w) * 0.5
		_draw.draw_string_outline(f, Vector2(x, y), name, HORIZONTAL_ALIGNMENT_LEFT, -1, 30, 6, Color.BLACK)
		_draw.draw_string(f, Vector2(x, y), name, HORIZONTAL_ALIGNMENT_LEFT, -1, 30, col)
		var nx := x + f.get_string_size(name + "   ", HORIZONTAL_ALIGNMENT_LEFT, -1, 30).x
		_draw.draw_string_outline(f, Vector2(nx, y), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 30, 6, Color.BLACK)
		_draw.draw_string(f, Vector2(nx, y), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 30, Color(0.96, 0.95, 0.9))
	if _title > 0.0:   # THEY LEARN
		var tsz := 110
		var tw := f.get_string_size("THEY LEARN", HORIZONTAL_ALIGNMENT_LEFT, -1, tsz).x
		var tp := Vector2((vs.x - tw) * 0.5, vs.y * 0.5 + 36.0)
		_draw.draw_string_outline(f, tp, "THEY LEARN", HORIZONTAL_ALIGNMENT_LEFT, -1, tsz, 12, Color(0, 0, 0, _title))
		_draw.draw_string(f, tp, "THEY LEARN", HORIZONTAL_ALIGNMENT_LEFT, -1, tsz, Color(0.85, 0.08, 0.06, _title))
	if not done and _bars > 0.5:
		_draw.draw_string(f, Vector2(vs.x - 150.0, 50.0), "ENTER  -  SKIP", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(1, 1, 1, 0.45))
