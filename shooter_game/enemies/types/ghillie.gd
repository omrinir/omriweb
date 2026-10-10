extends "res://enemies/zombie_type.gd"
# ============================================================
#  GHILLIE (שלב 20, "GREEN HELL") - זומבי בחליפת הסוואה של עלים. כשהוא כורע הוא נראה בדיוק כמו
#  השיחים של השלב (אותם צבעים, אותם עלים) ולרוב הוא יושב בתוך שיח קדמי (effects/s20_decor.gd, "s20_bush").
#  מחזור (חכם - לא עוד חיים):
#    HIDE    - כורע בתוך שיח, נראה כמו שיח. השחקן מתקרב (STALK_R) -> STALK.
#    STALK   - זוחל אליך לאט, אבל רק כשאתה לא מסתכל עליו: כשהכוונת קרובה אליו או מכוונת לכיוונו
#              הוא קופא (FREEZE) והופך שוב ל"שיח". משאירים לו את הגב = הוא מתקרב.
#    ATTACK  - קרוב (LUNGE_R) / קפא יותר מדי זמן / נורה = מזנק עליך ונושך.
#    RETREAT - אחרי נשיכה בורח לשיח אחר ומתחבא שוב.
#  הוגנות: רשרוש עלים ("gh_rustle") + עלים שנושרים כשהוא זז, וניצוץ עיניים קטן מדי פעם כשהוא מתחבא.
#  בוס (מצב בוס: z.chase_range > 600): THE THICKET - ענק, קופא פחות זמן, נושך 2.
#  לשנות: STALK_R, LUNGE_R, CREEP, WATCH_R, WATCH_DOT, FREEZE_MAX.
# ============================================================

const Brain := preload("res://ai/zombie_brain.gd")

const SOUNDS := {
	"gh_rustle": {"drive": 1.4, "layers": [["N", 0, 0, 0.0, 0.22, 0.02, 9.0, 0.45, 0.7, 0, 0.3], ["N", 0, 0, 0.12, 0.2, 0.02, 10.0, 0.35, 0.8, 0, 0.3]]},
	"gh_hiss": {"drive": 2.4, "layers": [["N", 0, 0, 0.0, 0.4, 0.01, 5.0, 0.7, 0.5, 0, 0.2], ["V", 180, 420, 0.0, 0.35, 0.01, 5.0, 0.6, 1.0, 0.05, 0, [700, 1800, 40]]]},
}

# אותם צבעים כמו השיחים הקדמיים (effects/s20_decor.gd BUSH)
const SUIT := [Color("1d3a20"), Color("27482a"), Color("335a30"), Color("3f6a36")]

const STALK_R := 520.0      # מאיזה מרחק הוא מתחיל לזחול אליך
const LUNGE_R := 105.0      # מאיזה מרחק הוא מזנק
const CREEP := 62.0         # מהירות זחילה
const WATCH_R := 120.0      # כוונת בטווח הזה ממנו = "מסתכלים עליו"
const WATCH_DOT := 0.985    # או: הכוונת מכוונת לכיוונו (~10 מעלות)
const FREEZE_MAX := 4.0     # קפא יותר מזה כשאתה קרוב = מאבד סבלנות ומזנק
const RETREAT_T := 3.0

enum { HIDE, STALK, ATTACK, RETREAT }
var state := HIDE
var frozen := false         # לבדיקות
var lunges := 0
var _k := 1.0               # 1 = שיח (כורע), 0 = עומד
var _freeze_t := 0.0
var _st := 0.0
var _rustle_t := 0.0
var _eye_t := 3.0
var _target_x := 0.0
var _drawn_eyes := false


func _boss() -> bool:
	return z != null and float(z.chase_range) > 600.0


func stats() -> Dictionary:
	if _boss():
		return {"name": "GHILLIE", "hp": 300, "walk": 40.0, "chase": 150.0, "damage": 2, "bite_delay": 0.7, "scale": 1.65, "width": 1.1,
			"duck": 0.0, "cover": 0.0, "skin": Color("5a6a4a"), "shirt": SUIT[1], "pants": Color("1a2418"), "shoe": Color("141a12"),
			"points": 1000, "boss": true, "boss_name": "THE THICKET - IT MOVES WHEN YOU LOOK AWAY"}
	return {"name": "GHILLIE", "hp": 32, "walk": 40.0, "chase": 158.0, "damage": 1, "bite_delay": 0.6, "scale": 1.0, "width": 0.95,
		"duck": 0.0, "cover": 0.0, "skin": Color("5a6a4a"), "shirt": SUIT[1], "pants": Color("1a2418"), "shoe": Color("141a12"), "points": 420}


func brain_overrides() -> Dictionary:
	return {"aggression": 1.0, "flank_probability": -0.5, "retreat_probability": 0.0}


func can_groan() -> bool:
	return state == ATTACK


func setup() -> void:
	z._noticed = true      # לא צורח כשהוא רואה אותך
	z._close_yell = true
	z._groan_t = 9999.0
	z.cover_chance = 0.0
	var b := _bush_near(z.global_position.x, 380.0, -INF)
	if b != null:
		z.position.x = b.global_position.x + randf_range(-10.0, 10.0)
	_mound(true)


# שיח קדמי קרוב (אופציונלי: רחוק מהשחקן לפחות away)
func _bush_near(x: float, max_d: float, pl_x: float, away := 0.0) -> Node2D:
	var best: Node2D = null
	var bd := max_d
	for b in z.get_tree().get_nodes_in_group("s20_bush"):
		var bx: float = b.global_position.x
		if absf(bx - pl_x) < away:
			continue
		if absf(bx - x) < bd:
			bd = absf(bx - x)
			best = b
	return best


# אזור פגיעה נמוך כשהוא שיח
func _mound(on: bool) -> void:
	var r := z._shape.shape as RectangleShape2D
	if on:
		r.size.y = 38.0 * z.sc
		z._crouched_shape = true
	else:
		r.size.y = 66.0 * z.sc
		z._crouched_shape = false
	z._shape.position.y = -r.size.y / 2.0


# השחקן מסתכל עליו? (הכוונת קרובה אליו, או מכוונת לכיוונו)
func _watched(pl: Node) -> bool:
	if pl == null or pl.dead or not Art.on_screen(z, z.global_position):
		return false
	var c: Vector2 = z.global_position + Vector2(0.0, -20.0 * z.sc)
	var m: Vector2 = pl.get_global_mouse_position()
	if m.distance_to(c) < WATCH_R * z.sc:
		return true
	var sh: Vector2 = pl.global_position + Vector2(0.0, -40.0)
	var to_z := c - sh
	return to_z.length() < 760.0 and (m - sh).normalized().dot(to_z.normalized()) > WATCH_DOT


func physics(pl: Node, delta: float) -> bool:
	if z.dead:
		return false
	_st -= delta
	z._groan_t = 9999.0 if state != ATTACK else z._groan_t
	var has_pl: bool = pl != null and not pl.dead
	var d := Vector2.ZERO
	if has_pl:
		d = pl.global_position - z.global_position
	frozen = false
	match state:
		HIDE:
			_k = move_toward(_k, 1.0, delta * 3.0)
			z._voice_cd = 1.0
			_eye_t -= delta
			if _eye_t < -0.15:
				_eye_t = randf_range(3.0, 5.5)
			if has_pl and absf(d.x) < STALK_R * (1.4 if _boss() else 1.0) and absf(d.y) < 160.0:
				state = STALK
				_freeze_t = 0.0
			return _move(0.0, delta)
		STALK:
			z._voice_cd = 1.0
			if not has_pl:
				state = HIDE
				return _move(0.0, delta)
			z._dir = signf(d.x) if d.x != 0.0 else z._dir
			if absf(d.x) < LUNGE_R * z.sc and absf(d.y) < 80.0:
				_lunge()
				return false
			if _watched(pl):
				frozen = true
				_freeze_t += delta
				_k = move_toward(_k, 1.0, delta * 8.0)
				_mound(true)
				if _freeze_t > (2.2 if _boss() else FREEZE_MAX) and absf(d.x) < 300.0:
					_lunge()
					return false
				return _move(0.0, delta)
			_freeze_t = maxf(_freeze_t - delta * 0.5, 0.0)
			_k = move_toward(_k, 0.55, delta * 3.0)
			_mound(false)
			_rustle(delta)
			return _move(z._dir * CREEP * (1.3 if _boss() else 1.0), delta)
		ATTACK:
			_k = move_toward(_k, 0.0, delta * 6.0)
			if _st <= 0.0 and has_pl and absf(d.x) > 260.0:   # התרחקת: חוזר לזחול
				state = STALK
			return false
		RETREAT:
			_k = move_toward(_k, 0.4, delta * 3.0)
			var dx: float = _target_x - z.global_position.x
			_rustle(delta)
			if absf(dx) < 12.0 or _st <= 0.0:
				state = HIDE
				_mound(true)
				_eye_t = randf_range(2.0, 4.0)
				return _move(0.0, delta)
			z._dir = signf(dx)
			return _move(signf(dx) * 150.0, delta)
	return false


func _move(vx: float, delta: float) -> bool:
	z.velocity.x = move_toward(z.velocity.x, vx, 900.0 * delta)
	if not z.is_on_floor():
		z.velocity.y += z.gravity * delta
	elif vx != 0.0 and z.is_on_wall():   # גזע / סלע בדרך: קופץ מעליו
		z.velocity.y = -340.0
	z.move_and_slide()
	return true


func _rustle(delta: float) -> void:
	_rustle_t -= delta
	if _rustle_t <= 0.0:
		_rustle_t = randf_range(0.55, 0.9)
		if Art.on_screen(z, z.global_position):
			Sfx.play("gh_rustle", z.global_position, -6.0, 0.15, 3)
			Particles.burst(z.get_parent(), z.global_position + Vector2(0, -16.0 * z.sc), "leaf", Vector2.UP, 2)


func _lunge() -> void:
	state = ATTACK
	lunges += 1
	_st = 1.6
	_mound(false)
	z._groan_t = randf_range(1.0, 2.0)
	if z.brain != null:
		z.brain._set_role(z, Brain.ATTACK, 0.0)
	if z.is_on_floor():
		z.velocity = Vector2(z._dir * 340.0, -280.0)
	Sfx.play("gh_hiss", z.global_position, 2.0, 0.1, 2)
	if Art.on_screen(z, z.global_position):
		Particles.burst(z.get_parent(), z.global_position + Vector2(0, -20.0 * z.sc), "leaf", Vector2.UP, 8)


# מתחבא בלי לזוז = שיח סטטי: מציירים רק כשהעיניים מהבהבות או כשהוא משנה צורה
func wants_redraw() -> bool:
	if state != HIDE or _k < 0.99:
		return true
	return (_eye_t < 0.0) != _drawn_eyes   # רק כשהניצוץ בעיניים נדלק / כבה


func on_bite(pl: Node) -> void:
	# נשך -> בורח לשיח אחר (רחוק ממך) ומתחבא שוב
	var b := _bush_near(z.global_position.x, 700.0, pl.global_position.x, 240.0)
	_target_x = b.global_position.x if b != null else z.global_position.x - signf(pl.global_position.x - z.global_position.x) * 300.0
	state = RETREAT
	_st = RETREAT_T


func on_damage(_amount: int, _hit_pos: Vector2, _dir: Vector2, _src: Dictionary) -> bool:
	if state == HIDE or state == STALK:   # נחשף -> מזנק מיד
		var pl := player()
		if pl != null:
			z._dir = signf(pl.global_position.x - z.global_position.x) if pl.global_position.x != z.global_position.x else z._dir
		_lunge()
	return true


func on_death() -> void:
	if Art.on_screen(z, z.global_position):
		Particles.burst(z.get_parent(), z.global_position + Vector2(0, -20.0 * z.sc), "leaf", Vector2.ZERO, 12)


# ============================================================
#  ציור: גוף כפוף עם רצועות עלים. כשהוא כורע (_k=1) הרצועות נפרשות למעלה = שיח.
# ============================================================
func draw() -> bool:
	begin_draw(_k < 0.6)
	var k := 0.0 if z.dead else _k
	var t: float = z._time
	var p: float = z._walk_phase
	var hip := Vector2(-2.0, -22.0).lerp(Vector2(-2.0, -9.0), k)
	var sh := Vector2(5.0, -37.0).lerp(Vector2(4.0, -17.0), k)
	var head := sh + Vector2(6.0, -6.0).lerp(Vector2(7.0, -2.0), k)
	var f: Array = feet(5.0, 2.0)
	var dark := col(z.pants)
	var sk := col(z.skin)
	# רגליים וידיים (כמעט לא רואים - מתחת לעלים)
	if k < 0.85:
		z._leg(hip + Vector2(-1, 0), f[1], dark, dark, col(z.shoe))
		z._leg(hip + Vector2(1, 0), f[0], dark, dark, col(z.shoe))
		var reach := 10.0 if z._bite_anim > 0.0 else 0.0
		Art.limb(z, PackedVector2Array([sh, sh + Vector2(7.0 + reach, 8.0 + sin(p) * 2.0), sh + Vector2(13.0 + reach, 12.0 - reach * 0.6)]), 3.0, sk)
	# גוש הגוף
	var body := PackedVector2Array([hip + Vector2(-8, 3), hip + Vector2(6, 3), sh + Vector2(6, 2), head + Vector2(3, -5), sh + Vector2(-6, -5)])
	z.draw_colored_polygon(body, col(SUIT[0]))
	# רצועות עלים: תלויות כשהוא עומד, נפרשות למעלה כשהוא שיח
	for i in 11:
		var u := float(i) / 10.0
		var root := hip.lerp(head + Vector2(0, -3), u) + Vector2(-3.0 + sin(float(i) * 2.3) * 3.0, 0.0)
		var hang := PI * 0.5 + 0.5 + sin(float(i) * 1.7) * 0.35        # תלוי למטה-אחורה
		var fan := -PI * 0.5 + (u - 0.45) * 2.4                          # נפרש כמו שיח
		var a := lerpf(hang, fan, k) + (sin(t * (1.4 + k) + float(i)) * 0.08 if state != HIDE else 0.0)
		var dirv := Vector2(cos(a), sin(a))
		var ln := lerpf(15.0, 22.0, k) + sin(float(i) * 3.1) * 4.0
		var n := dirv.orthogonal() * ln * 0.26
		var c: Color = SUIT[(i * 3) % 4]
		z.draw_colored_polygon(PackedVector2Array([root, root + dirv * ln * 0.5 + n, root + dirv * ln, root + dirv * ln * 0.5 - n]), col(c))
	# ברדס עלים על הראש + עיניים
	Art.oval(z, head, 5.5, 5.0, col(SUIT[1]), 0.0, SUIT[0], 1.0)
	z.draw_colored_polygon(PackedVector2Array([head + Vector2(-7, 2), head + Vector2(-3, -9), head + Vector2(5, -7), head + Vector2(7, -1), head + Vector2(1, -2)]), col(SUIT[2]))
	var eyes := k < 0.6 or (state == HIDE and _eye_t < 0.0)
	_drawn_eyes = state == HIDE and _eye_t < 0.0
	if eyes and not z.dead:
		for e in [Vector2(3.0, 0.5), Vector2(5.5, 1.0)]:
			z.draw_circle(head + e, 0.9, Color(0.85, 0.95, 0.35, 0.9))
	if k < 0.4 and not z.dead:   # פה פתוח כשהוא תוקף
		z.draw_colored_polygon(PackedVector2Array([head + Vector2(2, 3), head + Vector2(7, 2.5), head + Vector2(6, 5.5)]), Color("1a0606"))
	end_draw()
	return true
