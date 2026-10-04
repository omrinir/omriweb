extends "res://enemies/zombie_type.gd"
# ============================================================
#  SHIELD ELITE (שלב 9) - משתמש בחפצים מהסביבה כמגן: דלת מכונית שמרותך אליה
#    תמרור STOP וגרוטאות. מתקדם לאט עם המגן למעלה.
#  צללית: רחב וכבד, מסכת ריתוך עם חריץ כתום זוהר, מגן ענק מלפנים (מהראש עד השוקיים),
#    על הגב: שריון גרוטאות על הכתף, רצועות, וגב רקוב עם סדקים כתומים (נקודת תורפה).
#  תנועה: מתקדם לאט (המוח מזיז אותו - כך שה-COMMANDER יכול לפקד עליו). המגן כבד:
#    הוא מסתובב לאט (~0.65 שנ') - אפשר לעקוף אותו ולירות בגב. נסוג אחורה בלי להוריד את המגן.
#  התקפה: SHIELD BASH - כשהשחקן קרוב: מושך את המגן לאחור (0.5 שנ' - פתוח לפגיעה!),
#    ואז דוחף קדימה: נזק + הדיפה חזקה. אחרי המכה הוא מתנדנד רגע (STAGGER) - עוד חלון.
#  הגנה: קליעים / מכות מלפנים נחסמים (on_damage -> false) עם צלצול מתכת וניצוצות,
#    והמגן מתמלא שקעים. מאחור: נזק x1.6. טייזר עובר דרך המתכת. רימונים: חצי נזק.
#  צלילים: "shield_clang" (חסימה), "shield_bash" (מכה + נהמה), "shield_drag" (גרירת מתכת).
#  איך משנים: TURN_TIME, WINDUP, BASH_SPEED, REAR_MULT.
# ============================================================

const SOUNDS := {
	"shield_clang": [["S", 780, 760, 0.0, 0.5, 0.0, 7.0, 0.45, 1.0, 0], ["S", 1930, 1900, 0.0, 0.35, 0.0, 9.0, 0.3, 1.0, 0], ["S", 3100, 3050, 0.0, 0.2, 0.0, 14.0, 0.18, 1.0, 0],
		["N", 0, 0, 0.0, 0.04, 0.0, 90.0, 0.6, 1.0, 0]],
	"shield_bash": {"drive": 2.8, "layers": [["S", 90, 40, 0.0, 0.3, 0.0, 12.0, 1.2, 1.0, 0], ["N", 0, 0, 0.0, 0.15, 0.0, 25.0, 0.8, 0.25, 0], ["V", 120, 88, 0.0, 0.38, 0.01, 6.0, 0.8, 1.0, 0.03, 0, [550, 900, 60]]]},
	"shield_drag": [["N", 0, 0, 0.0, 0.35, 0.05, 6.0, 0.3, 0.5, 0, 0.3], ["S", 1700, 1500, 0.0, 0.35, 0.05, 8.0, 0.05, 1.0, 0.02]],
}

enum { WALK, WINDUP, BASH, STAGGER }
const TURN_TIME := 0.65
const WINDUP_T := 0.5
const BASH_SPEED := 430.0
const REAR_MULT := 1.6

var state := WALK
var blocked := 0            # כמה פגיעות נחסמו (לבדיקות)
var rear_hits := 0
var _facing := 1.0
var _turn_t := 0.0
var _t := 0.0
var _bash_cd := 1.0
var _hit := false
var _rear := false
var _dents := []
var _drag_t := 0.0
var _pop_cd := 0.0


func stats() -> Dictionary:
	return {"name": "SHIELD ELITE", "hp": 55, "walk": 38.0, "chase": 72.0, "damage": 1, "bite_delay": 1.0, "scale": 1.05, "width": 1.15,
		"duck": 0.0, "cover": 0.0, "skin": Color("7c8a74"), "shirt": Color("4a4038"), "pants": Color("2e2a26"), "shoe": Color("1a1612"), "points": 360}


func brain_overrides() -> Dictionary:
	return {"aggression": 0.1, "flank_probability": -0.4, "cover_usage": -0.5, "use_heights": -0.5, "keep_range": 120.0}


func setup() -> void:
	_facing = z._dir


func can_bite() -> bool:
	return false   # רק מכת מגן


func is_guarding() -> bool:
	return state == WALK and not z.dead


func logic(pl: Node, d: Vector2, delta: float, speed: float) -> float:
	_t -= delta
	_bash_cd -= delta
	_drag_t -= delta
	_pop_cd -= delta
	var want_dir: float = z._dir          # לאן המוח רוצה ללכת
	var target: float = signf(d.x) if d.x != 0.0 else _facing
	var dist := absf(d.x)
	# המגן כבד: מסתובב לאט
	if target != _facing and state == WALK:
		_turn_t += delta
		if _turn_t >= TURN_TIME:
			_facing = target
			_turn_t = 0.0
			Sfx.play("shield_drag", z.global_position, -6.0, 0.15, 2)
	else:
		_turn_t = 0.0
	z._dir = _facing
	match state:
		WALK:
			if dist < 78.0 and absf(d.y) < 40.0 and _bash_cd <= 0.0 and target == _facing and z.is_on_floor():
				state = WINDUP
				_t = WINDUP_T
				return 0.0
			var s := minf(speed, 75.0)
			if s > 1.0 and _drag_t <= 0.0 and Art.on_screen(z, z.global_position):
				_drag_t = 0.7
				Sfx.play("shield_drag", z.global_position, -12.0, 0.2, 2)
			if want_dir != _facing:   # נסוג אחורה עם המגן למעלה
				return -s * 0.55
			if _turn_t > 0.0:
				return 0.0
			return s
		WINDUP:
			if _t <= 0.0:
				state = BASH
				_t = 0.28
				_hit = false
				z.velocity.x = _facing * BASH_SPEED
				Sfx.play("shield_bash", z.global_position, 2.0, 0.1, 2)
			return 0.0
		BASH:
			if not _hit and dist < 42.0 and absf(d.y) < 50.0:
				_hit = true
				pl.hurt(z.damage, Vector2(_facing * 2.5, 0.0))
				pl.velocity.x += _facing * 380.0
				var cam: Camera2D = z.get_viewport().get_camera_2d()
				if cam != null and cam.has_method("shake"):
					cam.shake(7.0, 0.2)
			if _t <= 0.0:
				state = STAGGER
				_t = 0.65
				_bash_cd = 2.8
			return BASH_SPEED / z._speed_mul
		STAGGER:
			if _t <= 0.0:
				state = WALK
			return 0.0
	return speed


func on_damage(_amount: int, hit_pos: Vector2, dir: Vector2, src: Dictionary) -> bool:
	var source: String = src.get("source", "bullet")
	_rear = dir.x * _facing > 0.0
	if _rear:
		rear_hits += 1
	var frontal := dir.x * _facing < 0.0
	if frontal and is_guarding() and (source == "bullet" or source == "melee"):
		blocked += 1
		_block_fx(hit_pos, dir)
		return false
	return true


func damage_mult(_zone: String, src: Dictionary) -> float:
	var source: String = src.get("source", "bullet")
	if _rear and (source == "bullet" or source == "melee"):
		return REAR_MULT
	if source != "bullet" and source != "melee" and source != "taser" and source != "fire" and source != "hazard":
		return 0.5   # פיצוץ: המגן סופג חצי
	return 1.0


func _block_fx(hit_pos: Vector2, dir: Vector2) -> void:
	Sfx.play("shield_clang", hit_pos, -2.0, 0.2, 3)
	Particles.burst(z.get_parent(), hit_pos, "fire", Vector2(-dir.x, -0.4), 6)
	Game.on_zombie_hit({"source": "bullet", "zone": "shield"})
	if _pop_cd <= 0.0:
		_pop_cd = 0.5
		z._popup("BLOCKED", Color(1.0, 0.75, 0.4), 14, -90.0)
	# שקע במגן (בקואורדינטות הציור)
	var lx: float = (hit_pos.x - z.global_position.x) * _facing / (z.sc * z.wf)
	var ly: float = (hit_pos.y - z.global_position.y) / z.sc
	_dents.append(Vector2(clampf(lx, 7.0, 18.0), clampf(ly, -50.0, -7.0)))
	if _dents.size() > 12:
		_dents.pop_front()


# ============================================================
#  ציור
# ============================================================
func draw() -> bool:
	begin_draw()
	var sk := col(z.skin)
	var cloth := col(z.shirt)
	var dark := col(Art.shade(z.shirt, 0.35))
	var p: float = z._walk_phase
	var f: Array = feet(4.5, 2.0)
	var hip := Vector2(-2.0, -23.0 + absf(sin(p)) * 0.8)
	var sh := Vector2(-1.0, -40.0)
	var head := sh + Vector2(2.0, -9.0)
	z._leg(hip + Vector2(-3, 0), f[1], col(Art.shade(z.pants, 0.25)), col(Art.shade(z.skin, 0.2)), col(z.shoe))
	z._leg(hip + Vector2(3, 0), f[0], col(z.pants), sk, col(z.shoe))
	# גוף רחב, גב רקוב עם סדקים כתומים (נקודת התורפה)
	var body := PackedVector2Array([sh + Vector2(-11, -1), sh + Vector2(9, -1), hip + Vector2(9, -1), hip + Vector2(7, 4), hip + Vector2(-9, 4), hip + Vector2(-12, -2), sh + Vector2(-13, 8)])
	Art.fill_shaded(z, body, cloth, 0.12, 0.4, Art.OUTLINE, 1.5)
	var glow_a := 0.45 + 0.25 * sin(z._time * 4.0)
	for i in 3:
		var c0 := sh + Vector2(-11.0, 6.0 + float(i) * 6.0)
		z.draw_polyline(PackedVector2Array([c0, c0 + Vector2(3, 2), c0 + Vector2(2, 5)]), Color(1.0, 0.5, 0.15, glow_a) if not z.dead else dark, 1.2, true)
	z.draw_line(sh + Vector2(-9, 0), hip + Vector2(7, -2), col(Color("2a2016")), 2.0, true)   # רצועות
	z.draw_line(sh + Vector2(6, 0), hip + Vector2(-8, -1), col(Color("2a2016")), 2.0, true)
	# שריון גרוטאות על הכתף האחורית
	Art.fill_shaded(z, PackedVector2Array([sh + Vector2(-14, -3), sh + Vector2(-4, -6), sh + Vector2(-2, 2), sh + Vector2(-12, 5)]), col(Color("6a6460")), 0.2, 0.4, Art.OUTLINE, 1.1)
	z.draw_circle(sh + Vector2(-9, -2), 0.9, col(Color("2a2828")))
	z.draw_circle(sh + Vector2(-5, 0), 0.9, col(Color("2a2828")))
	# ראש: מסכת ריתוך עם חריץ זוהר
	Art.limb(z, PackedVector2Array([sh + Vector2(1, 0), sh + Vector2(2, -4)]), 6.5, Art.shade(sk, 0.1))
	Art.oval_shaded(z, head + Vector2(-1, 0), 7.0, 7.5, sk, 0.0)
	var mask := PackedVector2Array([head + Vector2(-3, -8), head + Vector2(6, -7), head + Vector2(8, -1), head + Vector2(7, 6), head + Vector2(-2, 7), head + Vector2(-4, 0)])
	Art.fill_shaded(z, mask, col(Color("2a2c2e")), 0.2, 0.4, Art.OUTLINE, 1.2)
	var slit := Color(1.0, 0.55, 0.15) if not z.dead else Color(0.25, 0.15, 0.1)
	z.draw_line(head + Vector2(0, -1.5), head + Vector2(7.2, -1.2), slit, 1.8)
	if not z.dead:
		Art.glow(z, head + Vector2(5, -1.4), 5.0, Color(1.0, 0.5, 0.1, 0.6))
	# ידיים (מאחורי המגן): אוחזות בידיות
	var off := Vector2.ZERO
	var rot := 0.0
	match state:
		WINDUP:
			off = Vector2(-7.0, -3.0)
			rot = -0.45
		BASH:
			off = Vector2(7.0, 0.0)
		STAGGER:
			off = Vector2(-2.0, 6.0)
			rot = 0.35
	if z.dead:
		off = Vector2(6.0, 4.0)
		rot = 0.6
	var piv := Vector2(10, -28) + off
	var xf := Transform2D(rot, piv)
	z._arm(sh + Vector2(-4, 1), xf * Vector2(-3, -14), dark, dark)
	z._arm(sh + Vector2(4, 1), xf * Vector2(-2, 4), sk, cloth)
	_shield(xf)
	end_draw()
	return true


# המגן: דלת מכונית + תמרור STOP + פסי אזהרה + שקעים מקליעים
func _shield(xf: Transform2D) -> void:
	# המגן מצויר סביב (10, -28); xf מזיז / מסובב אותו
	var o := Vector2(10, -28)
	var outline := PackedVector2Array([Vector2(5, -48), Vector2(19, -52), Vector2(21, -5), Vector2(6, -3)])
	var pts := PackedVector2Array()
	for q in outline:
		pts.append(xf * (q - o))
	Art.fill_shaded(z, pts, col(Color("8a4a2a")), 0.15, 0.4, Art.OUTLINE, 1.6)
	# חלון הדלת (כהה) + ידית
	Art.fill(z, PackedVector2Array([xf * (Vector2(8, -22) - o), xf * (Vector2(18, -24) - o), xf * (Vector2(18.5, -13) - o), xf * (Vector2(8.5, -12) - o)]), col(Color("1a1c20")), Art.OUTLINE, 0.8)
	z.draw_line(xf * (Vector2(10, -20) - o), xf * (Vector2(14, -15) - o), Color(0.8, 0.85, 0.9, 0.25), 0.8, true)
	z.draw_line(xf * (Vector2(14, -9) - o), xf * (Vector2(18, -9.5) - o), col(Color("b0b0a8")), 1.2, true)
	# פסי אזהרה על הקצה
	for i in 7:
		var y0 := -46.0 + float(i) * 6.0
		var a := xf * (Vector2(5.5, y0) - o)
		var b := xf * (Vector2(8.0, y0 + 3.0) - o)
		z.draw_line(a, b, col(Color("e0c020") if i % 2 == 0 else Color("1a1a1a")), 2.0, true)
	# תמרור STOP מרותך למעלה
	var sc0 := xf * (Vector2(13, -38) - o)
	var oct := PackedVector2Array()
	for i in 8:
		var ang := TAU * (float(i) + 0.5) / 8.0
		oct.append(sc0 + Vector2(cos(ang), sin(ang)).rotated(xf.get_rotation()) * Vector2(5.6, 6.2))
	Art.fill(z, oct, col(Color("c0201c")), Color(0.95, 0.95, 0.95), 1.0)
	z.draw_line(sc0 + Vector2(-3, 0).rotated(xf.get_rotation()), sc0 + Vector2(3, 0).rotated(xf.get_rotation()), col(Color("f0f0f0")), 1.4)
	# ריתוכים / ניטים
	for q in [Vector2(7, -30), Vector2(19, -32), Vector2(7, -44), Vector2(18, -6)]:
		z.draw_circle(xf * (q - o), 0.9, col(Color("3a3430")))
	z.draw_line(xf * (Vector2(6, -30) - o), xf * (Vector2(20, -31) - o), col(Color("6a3a20")), 1.2, true)
	# שקעים מקליעים (נשארים על המגן)
	for dnt in _dents:
		var dp: Vector2 = xf * (dnt - o)
		z.draw_circle(dp, 1.4, col(Color("4a2a18")))
		z.draw_circle(dp + Vector2(-0.4, -0.4), 0.6, col(Color("e8d8c0")))
