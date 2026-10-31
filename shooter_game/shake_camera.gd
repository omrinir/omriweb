extends Camera2D
# ============================================================
#  מצלמה שעוקבת אחרי השחקן ויודעת לרעוד (למשל בפיצוץ רימון).
#  נוצרת ע"י main.gd. כדי לרעוד מכל מקום במשחק:
#      get_viewport().get_camera_2d().shake(10.0, 0.3)
#  "זום קטן" (למשל בקפיצה):  ...get_camera_2d().punch_zoom(0.03)
#  "בעיטת ירייה":  ...get_camera_2d().fire_kick(כיוון הירייה, פיקסלים) - המסך נדחף קצת הפוך לכיוון הקנה
#  וחוזר מהר כמו קפיץ (לא רעידה אקראית - כל ירייה מרגישה כמו מכה). player.gd -> _screen_kick.
#  "עצירת פגיעה" (hit-stop):  ...get_camera_2d().hit_stop(0.045) - העולם כמעט עוצר לרגע (הריגה בראש / שוטגאן / צלף / בוס).
#  השחקן ממשיך כרגיל (player.gd מפצה על Engine.time_scale), אז ירי מהיר לא מואט. לא פועל בזמן BULLET TIME / כוונת צלף.
#  (0.03 = 3% זום פנימה, נכנס בעדינות ודועך חזרה לזום הרגיל)
#  "מצלמה קולנועית" (effects/bullet_cam.gd - מצלמת קליע):  cine_begin() / cine_set(מרכז בעולם, זום) / cine_end()
#  בזמן הזה המצלמה לא עוקבת אחרי השחקן (בלי החלקה ובלי גבולות) - מה שנקבע מבחוץ זה מה שרואים. home_center() = איפה
#  המצלמה הרגילה הייתה עכשיו (כדי לחזור אליה חלק). רעידות / בעיטות / זום קטן לא פועלים בזמן הזה.
#  הזום עובר דרך שני שלבי החלקה ברצף -> עקומת S: מתחיל לאט, מאיץ, ונרגע (בלי "קפיצה" בהתחלה).
#  שיא אחרי ~0.33 שנ' (כ-80% מהכמות), מחזיק רגע (punch_hold) ודועך חזרה תוך ~שנייה.
# ============================================================

## כמה מהר הזום הקטן נכנס (החלקה) / כמה זמן מחזיק בשיא / כמה מהר דועך חזרה
@export var punch_in_speed := 10.0
@export var punch_hold := 0.18
@export var punch_out_speed := 2.2
# ============================================================

## כמה מהר הרעידה נחלשת
@export var decay := 1.0

## בעיטת ירייה: קשיחות הקפיץ / ריסון (גבוה = חוזר מהר יותר) / מקסימום פיקסלים
@export var kick_stiffness := 650.0
@export var kick_damping := 30.0
@export var kick_max := 10.0

## עצירת פגיעה: לכמה העולם מאט / מינימום שניות בין שתי עצירות (שלא ירגיש מגמגם במולטי-קיל)
@export var hitstop_scale := 0.08
@export var hitstop_gap := 0.5

var _strength := 0.0
var _time_left := 0.0
var _duration := 0.0
var _base_zoom := Vector2.ONE
var _punch_target := 0.0
var _punch := 0.0
var _punch_mid := 0.0       # שלב ההחלקה הראשון (השני = _punch)
var _punch_hold_t := 0.0
var _anchor_off := Vector2.ZERO   # הזזה שמשאירה את השחקן במקום על המסך בזמן הזום
var base_offset := Vector2.ZERO   # הזזה קבועה (טלפון: השחקן ברבע השמאלי של המסך במקום באמצע)
var frame_target: Node2D = null   # בוס נייח ענק: המצלמה זזה כדי שגם הוא וגם השחקן ייראו (stationary_boss.gd)
var frame_half := 180.0           # חצי הרוחב של המטרה (בעולם)
var _frame_off := 0.0
var _kick := Vector2.ZERO         # בעיטת ירייה: הזזה נוכחית + מהירות (קפיץ מרוסן)
var _kick_v := Vector2.ZERO
var _hs_until := 0                # עצירת פגיעה: עד מתי (ms, זמן אמיתי)
var _hs_next := 0                 # לא לפני (ms)
var _base_pos := Vector2.ZERO      # המיקום הקבוע ביחס לשחקן (main.gd), בלי תיקון התנועה החלקה
var _cine := false                 # מצלמה קולנועית (effects/bullet_cam.gd)
var _cine_c := Vector2.ZERO        # מרכז המסך בעולם
var _cine_z := 1.0
var _lims := [0, 0, 0, 0]          # הגבולות הרגילים (נשמרים בזמן מצלמה קולנועית)


func _ready() -> void:
	add_to_group("camera")
	_base_zoom = zoom
	_base_pos = position


# תנועה חלקה: player.gd קורא לזה כל פריים עם ההפרש בין המיקום המוחלק של השחקן (בין שני צעדי פיזיקה) למיקום האמיתי.
# כך המצלמה זזה רציף גם במסך 144Hz, ולא בקפיצות של 60 פעם בשנייה (effects/smooth_motion.gd)
func follow_smooth(off: Vector2) -> void:
	position = _base_pos + off


# ---- מצלמה קולנועית (effects/bullet_cam.gd): מרכז + זום מבחוץ ----
func cine_begin() -> void:
	if _cine:
		return
	_cine_c = get_screen_center_position()
	_cine_z = zoom.x
	_cine = true
	_punch_target = 0.0
	_punch_mid = 0.0
	_punch = 0.0
	_punch_hold_t = 0.0
	_anchor_off = Vector2.ZERO
	_kick = Vector2.ZERO
	_kick_v = Vector2.ZERO
	_time_left = 0.0
	_lims = [limit_left, limit_top, limit_right, limit_bottom]
	position_smoothing_enabled = false
	limit_left = -10000000
	limit_top = -10000000
	limit_right = 10000000
	limit_bottom = 10000000
	_cine_apply()


func cine_set(center: Vector2, z: float) -> void:
	_cine_c = center
	_cine_z = z
	if _cine:
		_cine_apply()


func cine_end() -> void:
	if not _cine:
		return
	_cine = false
	limit_left = _lims[0]
	limit_top = _lims[1]
	limit_right = _lims[2]
	limit_bottom = _lims[3]
	zoom = _base_zoom
	position_smoothing_enabled = true
	reset_smoothing()
	offset = base_offset + Vector2(_frame_off, 0.0)


# בלי החלקה ובלי גבולות: מרכז המסך = המיקום של המצלמה + offset
func _cine_apply() -> void:
	zoom = Vector2(_cine_z, _cine_z)
	offset = _cine_c - global_position


# המרכז של המצלמה הרגילה עכשיו (בלי ההחלקה): המיקום, בתוך הגבולות, + ההזזות הקבועות. כמו Camera2D
func home_center() -> Vector2:
	var half := get_viewport_rect().size * 0.5 / _base_zoom
	var l: Array = _lims if _cine else [limit_left, limit_top, limit_right, limit_bottom]
	var p := global_position
	var x := p.x - half.x
	if x < float(l[0]):
		x = float(l[0])
	if x + half.x * 2.0 > float(l[2]):
		x = float(l[2]) - half.x * 2.0
	var y := p.y - half.y
	if y + half.y * 2.0 > float(l[3]):
		y = float(l[3]) - half.y * 2.0
	if y < float(l[1]):
		y = float(l[1])
	return Vector2(x, y) + half + base_offset + Vector2(_frame_off, 0.0)


# המסך של המצלמה הרגילה (בעולם)
func home_view() -> Rect2:
	var sz := get_viewport_rect().size / _base_zoom
	return Rect2(home_center() - sz * 0.5, sz)


# הגבולות הרגילים: מרכז מסך בזום z שלא יוצא מהשלב
func clamp_center(c: Vector2, z: float) -> Vector2:
	var half := get_viewport_rect().size * 0.5 / maxf(z, 0.01)
	var l: Array = _lims if _cine else [limit_left, limit_top, limit_right, limit_bottom]
	c.x = clampf(c.x, float(l[0]) + half.x, maxf(float(l[2]) - half.x, float(l[0]) + half.x))
	c.y = clampf(c.y, float(l[1]) + half.y, maxf(float(l[3]) - half.y, float(l[1]) + half.y))
	return c


# amount = כמה זום להוסיף (0.03 = 3%). זום חזק יותר דורס חלש יותר
func punch_zoom(amount: float) -> void:
	if _cine:
		return
	if amount >= _punch_target:
		_punch_target = amount
		_punch_hold_t = punch_hold


# בעיטת ירייה: dir = כיוון הירייה, px = כמה פיקסלים בערך (השיא). המסך זז הפוך לקנה וחוזר
func fire_kick(dir: Vector2, px: float) -> void:
	if dir == Vector2.ZERO or _cine:
		return
	var d := dir.normalized()
	var side := Vector2(-d.y, d.x) * randf_range(-0.3, 0.3)   # קצת הצידה - שלא ירגיש מכני
	_kick_v += (-d + side) * px * 90.0


# עצירת פגיעה: sec = כמה שניות אמיתיות. Engine meta "hitstop" = פעיל (hud.gd לא מצייר אז את גוון ה-BULLET TIME)
func hit_stop(sec: float) -> void:
	var now := Time.get_ticks_msec()
	if _cine or (Engine.time_scale < 0.99 and not Engine.has_meta("hitstop")):   # BULLET TIME / כוונת צלף / גלגל נשקים - לא נוגעים
		return
	if now < _hs_next and sec < 0.2:   # (בוס תמיד)
		return
	_hs_until = maxi(_hs_until, now + int(sec * 1000.0))
	_hs_next = now + int((sec + hitstop_gap) * 1000.0)
	Engine.time_scale = hitstop_scale
	Engine.set_meta("hitstop", true)


func _end_hitstop() -> void:
	Engine.remove_meta("hitstop")
	if absf(Engine.time_scale - hitstop_scale) < 0.001:   # מישהו אחר שינה בינתיים (כוונת / BULLET TIME) - לא דורסים
		Engine.time_scale = 1.0


func _exit_tree() -> void:
	if Engine.has_meta("hitstop"):
		_end_hitstop()


# strength = כמה פיקסלים המסך זז, duration = כמה שניות
func shake(strength := 8.0, duration := 0.25) -> void:
	if _cine:
		return
	if strength >= _strength * (_time_left / maxf(_duration, 0.001)):
		_strength = strength
		_duration = duration
		_time_left = duration


func _process(delta: float) -> void:
	if Engine.has_meta("hitstop") and Time.get_ticks_msec() >= _hs_until:
		_end_hitstop()
	if _cine:   # (השחקן הזיז את המצלמה ב-follow_smooth: המרכז נשאר איפה שנקבע)
		_cine_apply()
		return
	# זום קטן: היעד מחזיק רגע ואז דועך; הזום עצמו עוקב אחריו דרך שתי החלקות (עקומת S רכה)
	if _punch_hold_t > 0.0:
		_punch_hold_t -= delta
	else:
		_punch_target *= exp(-punch_out_speed * delta)
	if _punch_target < 0.0005:
		_punch_target = 0.0
	var kp := 1.0 - exp(-punch_in_speed * delta)
	_punch_mid = lerpf(_punch_mid, _punch_target, kp)
	_punch = lerpf(_punch, _punch_mid, kp)
	if _punch > 0.0005 or _punch_mid > 0.0005 or _punch_target > 0.0:
		zoom = _base_zoom * (1.0 + _punch)
		# הזום "נכנס" אל השחקן (לא אל מרכז המסך): מזיזים את המצלמה כך שהשחקן נשאר באותה נקודה במסך
		var p := get_parent() as Node2D
		if p != null:
			var center := get_screen_center_position() - (offset - base_offset)
			var focus := p.global_position + Vector2(0.0, -40.0)
			_anchor_off = (focus - center) * (1.0 - 1.0 / (1.0 + _punch))
	else:
		_anchor_off = Vector2.ZERO
		if zoom != _base_zoom:
			zoom = _base_zoom
	var shake_off := Vector2.ZERO
	if _time_left > 0.0:
		_time_left -= delta
		var k := pow(clampf(_time_left / _duration, 0.0, 1.0), decay)
		shake_off = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * _strength * k
	var want := 0.0
	var pl := get_parent() as Node2D
	if frame_target != null and is_instance_valid(frame_target) and pl != null:
		var half_w: float = get_viewport_rect().size.x * 0.5 / maxf(zoom.x, 0.01)
		var dx: float = frame_target.global_position.x - pl.global_position.x
		var need: float = absf(dx) + frame_half + 20.0 - half_w   # כמה חסר כדי שהבוס ייכנס למסך
		if need > 0.0:
			want = signf(dx) * minf(need, half_w - 110.0)   # (השחקן נשאר על המסך)
	_frame_off = lerpf(_frame_off, want, 1.0 - exp(-3.0 * delta))
	# בעיטת ירייה: קפיץ מרוסן שחוזר ל-0
	if _kick_v != Vector2.ZERO or _kick != Vector2.ZERO:
		var dt := minf(delta, 1.0 / 30.0)
		_kick_v += (-kick_stiffness * _kick - kick_damping * _kick_v) * dt
		_kick += _kick_v * dt
		if _kick.length() > kick_max:
			_kick = _kick.limit_length(kick_max)
		if _kick.length() < 0.05 and _kick_v.length() < 2.0:
			_kick = Vector2.ZERO
			_kick_v = Vector2.ZERO
	offset = base_offset + _anchor_off + shake_off + Vector2(_frame_off, 0.0) + _kick
