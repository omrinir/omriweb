extends Node
# ============================================================
#  QUALITY GOVERNOR (Autoload בשם Quality) - מוריד אפקטים לבד כשהמשחק נהיה איטי.
#  מודד את קצב הפריימים האמיתי. מתחת ל-DROP_FPS (בערך 52) לשנייה -> יורד רמה אחת (עד MAX_LEVEL).
#  חלק מעל RAISE_FPS במשך RAISE_WAIT שניות -> עולה רמה בחזרה. ירד שוב מהר אחרי עלייה? מחכה כפול לפני הניסיון הבא.
#  רמה 0 = הכל מלא. 1 = פחות עשן / ניצוצות, זומבים ורקע מתעדכנים לאט יותר. 2 = מספרי נזק רק לראש, ציור זומבים מפושט תמיד.
#  3 = מינימום: כמעט בלי עשן / ניצוצות / אבק, בלי מספרי נזק.
#  ** דם וגור לא נוגעים בהם אף פעם ** (טיפות דם, חתיכות בשר, ריסוסים, חלקיקי "hit", רגדולים) - זה חלק מהמשחק.
#  רק מראה - לא משנה את המוח של הזומבים, את המהירות או את הנזק.
#  Settings.quality_mode: AUTO (ברירת מחדל) / HIGH (תמיד 0) / LOW (תמיד MAX_LEVEL). בתפריט ההשהיה (ESC).
#  F3 = מונה FPS + רמה נוכחית בפינה.
#  לשנות: DROP_FPS, RAISE_FPS, RAISE_WAIT, הטבלאות למטה (אינדקס = רמה).
# ============================================================

const MAX_LEVEL := 3
const DROP_FPS := 52.0          # ממוצע שנייה מתחת לזה -> יורדים רמה
const RAISE_FPS := 58.0         # ממוצע מעל זה לאורך זמן -> עולים רמה
const RAISE_WAIT := 8.0         # שניות חלקות לפני שמנסים לעלות
const RAISE_WAIT_MAX := 120.0
const SETTLE := 1.0             # אחרי שינוי רמה - מחכים שהמדידה תתייצב
const WARMUP := 2.5             # אחרי טעינת סצנה - לא מודדים (קפיצות טעינה)

# טבלאות לפי רמה (0..3)
const PARTICLES := [1.0, 0.6, 0.35, 0.18]       # כמות חלקיקים בכל פרץ (עשן, ניצוצות, אבק - לא דם)
const PARTICLE_CAP := [1400, 800, 450, 220]     # מקסימום חלקיקים חיים
const REDRAW_EXTRA := [0, 1, 2, 3]              # כמה פריימים נוספים בין ציורים של זומבי
const CROWDED_AT := [14, 8, 0, 0]               # מעל כמה זומבים על המסך - ציור מפושט
const BG_EVERY := [1, 2, 3, 4]                  # הרקע מצויר כל N פריימים (בינתיים השכבות רק זזות)
const AMBIENT := [1.0, 0.7, 0.45, 0.3]          # גשם / אפר / עיתונים

var level := 0
var fps := 60.0                 # ממוצע השנייה האחרונה (גם ל-F3)
var drops := 0                  # כמה פעמים ירדנו (לבדיקות)
var show_fps := false

var _last_us := 0
var _win_t := 0.0
var _win_frames := 0
var _good_t := 0.0
var _settle := WARMUP
var _raise_wait := RAISE_WAIT
var _since_raise := 999.0
var _scene: Node = null
var _label: Label = null


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_apply_mode()


func _apply_mode() -> void:
	match int(Settings.quality_mode):
		Settings.Q_HIGH:
			level = 0
		Settings.Q_LOW:
			level = MAX_LEVEL


func set_mode(m: int) -> void:
	Settings.set_quality_mode(m)
	if m == Settings.Q_AUTO:
		level = 0
		_reset_measure(SETTLE)
	_apply_mode()


func _reset_measure(wait: float) -> void:
	_win_t = 0.0
	_win_frames = 0
	_good_t = 0.0
	_settle = wait


func _process(_delta: float) -> void:
	var now := Time.get_ticks_usec()
	var dt := float(now - _last_us) / 1000000.0 if _last_us > 0 else 0.0
	_last_us = now
	var sc := get_tree().current_scene
	if sc != _scene:   # סצנה חדשה (שלב / תפריט): קפיצות טעינה לא נחשבות
		_scene = sc
		_reset_measure(WARMUP)
	if get_tree().paused or dt <= 0.0 or dt > 0.5:   # עצירה / חלון נגרר / טעינה
		_update_label()
		return
	_since_raise += dt
	if _settle > 0.0:
		_settle -= dt
		return
	_win_t += dt
	_win_frames += 1
	if _win_t < 1.0:
		return
	fps = float(_win_frames) / _win_t
	_win_t = 0.0
	_win_frames = 0
	_update_label()
	if int(Settings.quality_mode) != Settings.Q_AUTO:
		return
	var hz := minf(60.0, _refresh())   # מסך 50Hz למשל: המטרה היא קצב המסך, לא 60
	if fps < DROP_FPS * hz / 60.0 and level < MAX_LEVEL:
		level = mini(level + (2 if fps < DROP_FPS * 0.75 * hz / 60.0 else 1), MAX_LEVEL)   # איטי מאוד -> שתי רמות בבת אחת
		drops += 1
		if _since_raise < 12.0:   # עלינו ומיד נהיה איטי -> מחכים יותר לפני הניסיון הבא
			_raise_wait = minf(_raise_wait * 2.0, RAISE_WAIT_MAX)
		_reset_measure(SETTLE)
	elif fps > RAISE_FPS * hz / 60.0 and level > 0:
		_good_t += 1.0
		if _good_t >= _raise_wait:
			level -= 1
			_since_raise = 0.0
			_reset_measure(SETTLE)
	else:
		_good_t = 0.0


var _hz := 0.0


func _refresh() -> float:
	if _hz <= 0.0:
		var r := DisplayServer.screen_get_refresh_rate()
		_hz = r if r >= 30.0 else 60.0
	return _hz


# ---- F3: מונה FPS ----
func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_F3:
		show_fps = not show_fps
		if show_fps and _label == null:
			var cl := CanvasLayer.new()
			cl.layer = 120
			add_child(cl)
			_label = Label.new()
			_label.position = Vector2(12, 690)
			_label.add_theme_color_override("font_color", Color(0.6, 1.0, 0.6))
			_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
			_label.add_theme_constant_override("shadow_offset_x", 1)
			_label.add_theme_constant_override("shadow_offset_y", 1)
			cl.add_child(_label)
		if _label != null:
			_label.visible = show_fps
		_update_label()


func _update_label() -> void:
	if _label == null or not show_fps:
		return
	_label.text = "FPS %d   EFFECTS %s (level %d)" % [roundi(fps), Settings.QUALITY_NAMES[int(Settings.quality_mode)], level]


# ---- מה כל מערכת שואלת ----
func particles() -> float:
	return PARTICLES[level]


func particle_cap() -> int:
	return PARTICLE_CAP[level]


func damage_numbers(zone: String) -> bool:
	return level < 2 or (level == 2 and zone == "head")


func redraw_extra() -> int:
	return REDRAW_EXTRA[level]


func crowded_at() -> int:
	return CROWDED_AT[level]


func bg_every() -> int:
	return BG_EVERY[level]


func ambient() -> float:
	return AMBIENT[level]


# מספר שלם אקראי לפי מכפיל: 3 * 0.35 = 1.05 -> בדרך כלל 1, לפעמים 2 (הממוצע נשמר)
static func scaled(n: int, mult: float) -> int:
	var f := float(n) * mult
	var k := int(f)
	return k + (1 if randf() < f - float(k) else 0)
