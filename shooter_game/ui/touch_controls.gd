extends CanvasLayer
# ============================================================
#  TOUCH CONTROLS (Autoload "Touch") - שליטה במגע לטלפון (אנדרואיד).
#  פעיל רק בטלפון (OS "mobile") או עם הפרמטר "-- --touch" (בדיקה במחשב).
#  במשחק:
#    ג'ויסטיק שמאלי (צף - מופיע איפה שנוגעים בחצי השמאלי): A/D הליכה, דחיפה עד הסוף = ריצה,
#        למטה = כריעה (S), למעלה = טיפוס בסולם (W).
#    ג'ויסטיק ימני (צף, בחצי הימני): כיוון + ירי אוטומטי כל עוד מחזיקים. עזרת כיוון קטנה (ASSIST)
#        אל הזומבי הקרוב לכיוון הירי.
#    כפתורים: JUMP (W) מימין; RELOAD (R), SWAP (נשק הבא), GREN (E), HOOK (F), SKILL (C) למעלה משמאל; II = הפסקה (ESC).
#  מצלמה בטלפון (main.gd): זום MOBILE_ZOOM, והשחקן ברבע השמאלי של המסך (shake_camera.base_offset).
#  איך זה עובד: הכפתורים "לוחצים" על המקשים האמיתיים (Input.parse_input_event), כך שכל הקוד של
#  המקלדת עובד בלי שינוי. רק הכיוון והירי נקראים ישירות: player.gd -> Touch.aim_point() / Touch.fire.
#  תפריטים: נגיעה = לחיצת עכבר (emulate_mouse_from_touch של Godot) - עובד לבד.
# ============================================================

const STICK_R := 95.0
const DEAD := 0.22
const RUN_AT := 0.85
const ASSIST := 0.22        # רדיאנים: זומבי בזווית הזו מכיוון הירי = הכדור הולך אליו
const ASSIST_RANGE := 820.0
const AIM_DIST := 260.0

var on := false
var fire := false
var run := false
var aim_dir := Vector2.RIGHT
var aiming := false

# [id, מרכז, רדיוס, מקש (0 = פעולה מיוחדת), תווית]
# ימין: רק ג'ויסטיק הירי + JUMP. שאר הכפתורים בשורה למעלה משמאל (מתחת ל-HUD). בלי ROLL.
var buttons := [
	["jump", Vector2(1196, 620), 60.0, KEY_W, "JUMP"],
	["reload", Vector2(44, 212), 32.0, KEY_R, "RELOAD"],
	["swap", Vector2(122, 212), 32.0, 0, "SWAP"],
	["grenade", Vector2(200, 212), 32.0, KEY_E, "GREN"],
	["hook", Vector2(278, 212), 32.0, KEY_F, "HOOK"],
	["skill", Vector2(356, 212), 32.0, KEY_C, "SKILL"],
	["pause", Vector2(905, 52), 26.0, KEY_ESCAPE, "II"],
]

var _touch := {}            # אינדקס אצבע -> "move" / "aim" / id של כפתור
var _move_c := Vector2(120, 615)
var _move := Vector2.ZERO
var _aim_c := Vector2(1010, 560)
var _aim := Vector2.ZERO
var _held := {}             # מקש -> true (כרגע "לחוץ")
var _shown := false
var _draw: Node2D


func _ready() -> void:
	on = OS.has_feature("mobile") or "--touch" in OS.get_cmdline_user_args()
	layer = 95
	process_mode = Node.PROCESS_MODE_ALWAYS
	_draw = Node2D.new()
	_draw.draw.connect(_on_draw)
	add_child(_draw)
	set_process(on)
	set_process_input(on)


# כפתור "אחורה" של אנדרואיד: במשחק = הפסקה (ESC), בתפריט = יציאה
func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		if _player() != null:
			_tap(KEY_ESCAPE)
		else:
			get_tree().quit()


func _player() -> Node:
	return get_tree().get_first_node_in_group("player")


func _active() -> bool:
	var p := _player()
	return on and p != null and not p.dead and p.controllable and not get_tree().paused


func _process(_delta: float) -> void:
	var a := _active()
	if a != _shown:
		_shown = a
		if not a:
			_reset()
	if a:
		_apply()
	_draw.visible = a
	_draw.queue_redraw()


func _reset() -> void:
	_touch.clear()
	_move = Vector2.ZERO
	_aim = Vector2.ZERO
	fire = false
	run = false
	aiming = false
	for k in _held.keys():
		_key(k, false)


func _key(k: int, down: bool) -> void:
	if down == _held.has(k):
		return
	if down:
		_held[k] = true
	else:
		_held.erase(k)
	var e := InputEventKey.new()
	e.physical_keycode = k
	e.keycode = k
	e.pressed = down
	Input.parse_input_event(e)


func _tap(k: int) -> void:
	_key(k, true)
	_key(k, false)


# מצב הג'ויסטיקים -> מקשים
func _apply() -> void:
	var m := _move
	_key(KEY_A, m.x < -DEAD)
	_key(KEY_D, m.x > DEAD)
	_key(KEY_S, m.y > 0.65 and absf(m.x) < 0.6)
	var climb := m.y < -0.75 and absf(m.x) < 0.5
	var jump_btn := _touch.values().has("jump")
	_key(KEY_W, climb or jump_btn)
	run = absf(m.x) > RUN_AT
	aiming = _aim.length() > DEAD
	if aiming:
		aim_dir = _aim.normalized()
	elif absf(m.x) > DEAD:   # לא מכוונים: מסתכלים לכיוון ההליכה
		aim_dir = Vector2(signf(m.x), 0.0)
	fire = aiming


# נקודת הכיוון בעולם (player.gd משתמש בה במקום העכבר)
func aim_point(from: Vector2) -> Vector2:
	var d := aim_dir
	if fire:
		var best := ASSIST
		for z in get_tree().get_nodes_in_group("zombies"):
			if z.dead:
				continue
			var to: Vector2 = z.global_position + Vector2(0.0, -30.0 * float(z.sc)) - from
			if to.length() > ASSIST_RANGE or to.length() < 1.0:
				continue
			var ang := absf(d.angle_to(to))
			if ang < best:
				best = ang
				d = to.normalized()
	return from + d * AIM_DIST


func _input(event: InputEvent) -> void:
	if not _shown:
		return
	if event is InputEventScreenTouch:
		var p: Vector2 = event.position
		if event.pressed:
			var role := _button_at(p)
			if role != "":
				_touch[event.index] = role
				_press(role)
			elif p.x < 560.0 and p.y > 260.0:
				_touch[event.index] = "move"
				_move_c = p
				_move = Vector2.ZERO
			elif p.x >= 560.0 and p.y > 200.0:
				_touch[event.index] = "aim"
				_aim_c = p
				_aim = Vector2.ZERO
		else:
			var r: String = _touch.get(event.index, "")
			_touch.erase(event.index)
			if r == "move":
				_move = Vector2.ZERO
			elif r == "aim":
				_aim = Vector2.ZERO
			elif r != "":
				_release(r)
	elif event is InputEventScreenDrag:
		var r2: String = _touch.get(event.index, "")
		if r2 == "move":
			_move = ((event.position - _move_c) / STICK_R).limit_length(1.0)
		elif r2 == "aim":
			var v: Vector2 = (event.position - _aim_c) / STICK_R
			if v.length() > 1.0:   # הבסיס נגרר אחרי האצבע
				_aim_c = event.position - v.normalized() * STICK_R
			_aim = v.limit_length(1.0)


func _button_at(p: Vector2) -> String:
	for b in buttons:
		if p.distance_to(b[1]) < float(b[2]) * 1.2:
			return b[0]
	return ""


func _btn(id: String) -> Array:
	for b in buttons:
		if b[0] == id:
			return b
	return []


func _press(id: String) -> void:
	var b := _btn(id)
	var k: int = b[3]
	if id == "swap":
		_swap()
	elif id == "jump":
		pass   # W מוחזק ב-_apply
	elif k == KEY_R or k == KEY_E or k == KEY_ESCAPE:
		_tap(k)
	else:
		_key(k, true)


func _release(id: String) -> void:
	var b := _btn(id)
	var k: int = b[3]
	if k != 0 and k != KEY_W:
		_key(k, false)


func _swap() -> void:
	var p := _player()
	if p == null:
		return
	var n: int = p.slots.size()
	for i in range(1, n + 1):
		var s: int = (int(p.cur_slot) + i) % n
		if p.slots[s] != null:
			p.select_slot(s)
			return


# ============================================================
#  ציור
# ============================================================
func _on_draw() -> void:
	var font := ThemeDB.fallback_font
	var base := Color(1, 1, 1, 0.16)
	var ring := Color(1, 1, 1, 0.45)
	var held := _touch.values()
	# ג'ויסטיקים
	var mv: bool = held.has("move")
	_stick(_move_c if mv else Vector2(120, 615), _move, mv, Color(0.6, 0.85, 1.0))
	var am: bool = held.has("aim")
	_stick(_aim_c if am else Vector2(1010, 560), _aim, am, Color(1.0, 0.45, 0.35))
	# כפתורים
	for b in buttons:
		var c: Vector2 = b[1]
		var r: float = b[2]
		var down: bool = held.has(b[0])
		_draw.draw_circle(c, r, Color(1, 1, 1, 0.32) if down else base)
		_draw.draw_arc(c, r, 0.0, TAU, 32, ring, 2.0, true)
		var label: String = b[4]
		var fs := 12 if label.length() > 5 else (15 if label.length() > 2 else 20)
		var w := font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		_draw.draw_string(font, c + Vector2(-w * 0.5, fs * 0.35), label, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(1, 1, 1, 0.8))


func _stick(c: Vector2, v: Vector2, active: bool, tint: Color) -> void:
	_draw.draw_circle(c, STICK_R, Color(1, 1, 1, 0.1 if active else 0.06))
	_draw.draw_arc(c, STICK_R, 0.0, TAU, 40, Color(1, 1, 1, 0.35 if active else 0.18), 2.0, true)
	_draw.draw_circle(c + v * STICK_R, 34.0, Color(tint, 0.55 if active else 0.25))
