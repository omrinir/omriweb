extends "res://enemies/zombie_type.gd"
# ============================================================
#  GRABBER (שלב 6) - איש תחזוקה של הבניין. איטי, אבל אם הוא תופס אותך - כולם באים.
#  צללית: כתפיים רחבות וכפופות, ראש קטן, ידיים ארוכות מאוד שנגררות עד הברכיים
#         עם כפות ענקיות. סרבל כחול-אפור עם פסי זוהר כתומים, צרור מפתחות שמתנדנד.
#  תנועה: מדשדש לאט ומתנדנד מצד לצד. כשהוא קרוב (~120) - "מזנק" שני צעדים מהירים.
#  התקפה: לא נושך. מרים ידיים לרגע (אזהרה + גרגור), ואז תופס: player.grab(z).
#         השחקן לא יכול לזוז ונחשב "פגיע" -> ה-SquadDirector פותח תור התקפה נוסף,
#         והגראבר "קורא" לחברים (broadcast) - זומבים אחרים באים לתקוף.
#         לוחץ כל ~1.4 שניות (נזק 1).
#  הוגנות: משתחרר לבד אחרי HOLD_MAX שניות, כשהשחקן מנער אותו (A/D לסירוגין ->
#          z.release_grab() -> on_release), כשהוא סופג נזק כבד, וכשהוא מת.
#          אחרי שחרור הוא מתנדנד אחורה (חלון לירות בו) ולא תופס שוב כמה שניות.
#  צלילים: "grab_gurgle" (גרגור עמוק לפני תפיסה), "grab_crush" (לחיצה + חריקת עצמות)
# ============================================================

const SOUNDS := {
	"grab_gurgle": {"drive": 2.8, "layers": [["V", 82, 64, 0.0, 0.6, 0.05, 3.0, 0.9, 1.0, 0.06, 0, [380, 760, 34]], ["B", 0.5, 0.5, 0.0, 0.6, 0.0, 3.0, 0.35, 1.0, 0, 0, 40.0], ["N", 0, 0, 0.0, 0.5, 0.05, 4.0, 0.15, 0.2, 0]]},
	"grab_crush": {"drive": 2.4, "layers": [["C", 0, 0, 0.0, 0.25, 0.0, 9.0, 0.9, 1.0, 0], ["N", 0, 0, 0.0, 0.18, 0.0, 16.0, 0.5, 0.35, 0], ["S", 140, 60, 0.0, 0.2, 0.0, 14.0, 0.6, 1.0, 0], ["V", 120, 90, 0.05, 0.4, 0.02, 5.0, 0.5, 1.0, 0.05, 0, [500, 900, 40]]]},
}

const GRAB_RANGE := 44.0
const HOLD_MAX := 2.8           # שניות עד שחרור אוטומטי (הוגנות)
const SQUEEZE_EVERY := 1.4
const HEAVY_HIT := 24           # נזק מצטבר בזמן התפיסה שגורם לו לעזוב

enum { WALK, WINDUP, HOLD, RECOVER }
var state := WALK
var _t := 0.0
var _cd := 1.0
var _squeeze := 0.0
var _taken := 0
var _lurch := 0.0
var grabs := 0                  # לבדיקות
var releases := 0


func stats() -> Dictionary:
	return {"name": "GRABBER", "hp": 42, "walk": 30.0, "chase": 58.0, "damage": 1, "bite_delay": 1.0, "scale": 1.06, "width": 1.15,
		"duck": 0.0, "cover": 0.1, "skin": Color("b4ac84"), "shirt": Color("3e5260"), "pants": Color("34444e"), "shoe": Color("1e1a16"), "points": 260}


func brain_overrides() -> Dictionary:
	return {"aggression": 0.15, "flank_probability": -0.3, "retreat_probability": -0.2}


func can_bite() -> bool:
	return false   # ההתקפה שלו היא תפיסה


func _grabbable(pl: Node) -> bool:
	return pl != null and not pl.dead and pl.grabbed_by == null and pl._roll_t <= 0.0 and not pl._climbing


# בזמן הליכה: המוח מזיז אותו. כאן רק "זינוק" קצר כשהוא קרוב
func logic(pl: Node, d: Vector2, delta: float, speed: float) -> float:
	_lurch -= delta
	if state != WALK:
		return speed
	var dist := absf(d.x)
	if _cd <= 0.0 and dist < GRAB_RANGE and absf(d.y) < 40.0 and _grabbable(pl):
		state = WINDUP
		_t = 0.42
		z._dir = signf(d.x) if d.x != 0.0 else z._dir
		Sfx.play("grab_gurgle", z.global_position, 1.0)
		return 0.0
	if _cd <= 0.0 and dist < 125.0 and dist > 50.0 and absf(d.y) < 40.0 and _lurch <= -1.5:
		_lurch = 0.5   # שני צעדים מהירים קדימה
	if _lurch > 0.0:
		z._dir = signf(d.x) if d.x != 0.0 else z._dir
		return z.chase_speed * 2.6
	return speed


func physics(pl: Node, delta: float) -> bool:
	_cd -= delta
	_t -= delta
	if state == WALK:
		return false
	z.velocity.y += z.gravity * delta
	match state:
		WINDUP:   # ידיים למעלה (אזהרה)
			z.velocity.x = move_toward(z.velocity.x, 0.0, 800.0 * delta)
			if _t <= 0.0:
				var d: Vector2 = pl.global_position - z.global_position if pl != null else Vector2(999, 0)
				if absf(d.x) < GRAB_RANGE + 8.0 and absf(d.y) < 44.0 and _grabbable(pl):
					_grab(pl)
				else:   # פספס: מועד קדימה (חלון לירות בו)
					state = RECOVER
					_t = 0.8
					_cd = 1.5
					z.velocity.x = z._dir * 120.0
		HOLD:
			z.velocity.x = 0.0
			if pl == null or pl.dead or pl.grabbed_by != z:
				_let_go(false)
			else:
				# מחזיק את השחקן צמוד אליו
				var hx: float = z.global_position.x + z._dir * 20.0 * z.wf
				pl.global_position.x = move_toward(pl.global_position.x, hx, 300.0 * delta)
				pl.velocity.x = 0.0
				_squeeze -= delta
				if _squeeze <= 0.0:
					_squeeze = SQUEEZE_EVERY
					pl.hurt(z.damage, Vector2.ZERO)
					Sfx.play("grab_crush", z.global_position, -2.0, 0.1, 2)
				if _t <= 0.0:   # הוגנות: עוזב לבד
					_let_go(true)
		RECOVER:   # מתנדנד אחורה / מועד
			z.velocity.x = move_toward(z.velocity.x, 0.0, 300.0 * delta)
			if _t <= 0.0:
				state = WALK
	z.move_and_slide()
	return true


func _grab(pl: Node) -> void:
	state = HOLD
	grabs += 1
	_t = HOLD_MAX
	_squeeze = 0.6
	_taken = 0
	pl.grab(z)
	Sfx.play("grab_crush", z.global_position, 0.0)
	var dr := director()
	if dr != null:   # קורא לחברים: "תפסתי אותו!" (התור הנוסף נפתח כי השחקן פגיע)
		dr.broadcast(z, pl.global_position)
		dr._signal(z.global_position + Vector2(0.0, -78.0 * z.sc), "GRAB", Color(1.0, 0.55, 0.2))


# עוזב את השחקן (push = הודף אותו קצת)
func _let_go(push: bool) -> void:
	var pl := player()
	if pl != null and pl.grabbed_by == z:
		pl.grabbed_by = null
		if push:
			pl.velocity.x = z._dir * 220.0
	if state == HOLD:
		releases += 1
	state = RECOVER
	_t = 1.1
	_cd = 3.5
	z.velocity.x = -z._dir * 110.0


# השחקן השתחרר (A/D לסירוגין)
func on_release() -> void:
	if state == HOLD:
		releases += 1
	state = RECOVER
	_t = 1.3
	_cd = 3.5
	z.velocity.x = -z._dir * 150.0
	z._popup("SHAKEN OFF", Color(1.0, 0.75, 0.4), 13, -76.0)


func on_damage(amount: int, _hit_pos: Vector2, _dir: Vector2, _src: Dictionary) -> bool:
	if state == HOLD:
		_taken += amount
		if amount >= 20 or _taken >= HEAVY_HIT:
			_let_go(true)
			z._popup("LET GO!", Color(1.0, 0.75, 0.4), 13, -76.0)
	return true


func on_death() -> void:
	var pl := player()
	if pl != null and pl.grabbed_by == z:
		pl.grabbed_by = null


# ---- ציור: כתפיים רחבות, ידיים ארוכות שנגררות, סרבל עם פסים כתומים ----
func draw() -> bool:
	begin_draw()
	var sk := col(z.skin)
	var sk_d := col(Art.shade(z.skin, 0.3))
	var suit := col(z.shirt)
	var suit_d := col(Art.shade(z.shirt, 0.35))
	var stripe := col(Color("ff9a2a"))
	var p: float = z._walk_phase
	var f: Array = feet(4.0, 2.0)
	var sway := sin(p * 0.5) * 2.0   # מתנדנד מצד לצד
	var hip := Vector2(-1.0 + sway * 0.3, -22.0 + absf(sin(p)) * 1.0)
	var sh := Vector2(5.0 + sway * 0.5, -42.0)
	var head := sh + Vector2(6.0, -6.0)
	var up: bool = state == WINDUP and not z.dead
	var hold: bool = state == HOLD and not z.dead
	# ידיים: נגררות / מורמות (אזהרה) / סגורות קדימה (מחזיק)
	var hand_b := sh + Vector2(2.0 + sin(p) * 3.0, 32.0)
	var hand_f := sh + Vector2(8.0 - sin(p) * 3.0, 34.0)
	if up:
		hand_b = sh + Vector2(10, -18)
		hand_f = sh + Vector2(20, -14)
	elif hold:
		hand_b = sh + Vector2(20, 8)
		hand_f = sh + Vector2(22, 4)
	elif state == RECOVER and not z.dead:
		hand_b = sh + Vector2(-8, 26)
		hand_f = sh + Vector2(-2, 30)
	z._leg(hip + Vector2(-3, 0), f[1], col(Art.shade(z.pants, 0.3)), sk_d, col(z.shoe))
	_big_arm(sh + Vector2(-4, 1), hand_b, sk_d, suit_d)
	z._leg(hip + Vector2(3, 0), f[0], col(z.pants), sk, col(z.shoe))
	# גו רחב בסרבל + פסים זוהרים
	var torso := PackedVector2Array([hip + Vector2(-8, 3), hip + Vector2(8, 3), sh + Vector2(10, 2), sh + Vector2(6, -5), sh + Vector2(-8, -4), sh + Vector2(-10, 3)])
	Art.fill_shaded(z, torso, suit, 0.15, 0.35)
	z.draw_line(hip.lerp(sh, 0.35) + Vector2(-8, 0), hip.lerp(sh, 0.35) + Vector2(9, 0), stripe, 2.2)
	z.draw_line(hip.lerp(sh, 0.62) + Vector2(-9, 0), hip.lerp(sh, 0.62) + Vector2(10, 0), stripe, 2.2)
	z.draw_line(sh + Vector2(-6, -3), hip + Vector2(-5, 2), Color(1.0, 0.85, 0.5, 0.25), 1.0)   # כתפייה
	# צרור מפתחות שמתנדנד על החגורה
	var kp := hip + Vector2(6, 1)
	var ka := Vector2.from_angle(PI * 0.5 + sin(z._time * 5.0 + p) * 0.6) * 5.0
	z.draw_line(kp, kp + ka, col(Color("9a9a90")), 1.0)
	z.draw_circle(kp + ka, 1.6, col(Color("c8b860")))
	# ראש קטן ושקוע בין הכתפיים, לסת שמוטה
	Art.oval_shaded(z, head, 6.0, 6.5, sk, 0.15)
	Art.oval(z, head + Vector2(-1.5, -4.0), 5.0, 2.5, col(Color("2a2420")), 0.1)   # כובע צמר
	var jaw := 3.0 + (3.0 if up or hold else 0.0) + sin(z._time * 3.0)
	Art.fill(z, PackedVector2Array([head + Vector2(1, 2), head + Vector2(6, 1.5), head + Vector2(5.5, 3.0 + jaw), head + Vector2(1.5, 3.5 + jaw * 0.7)]), Color("2a0a0c"), Art.OUTLINE, 0.9)
	var eye := Color(1.0, 0.65, 0.2)
	Art.glow(z, head + Vector2(3.5, -1.0), 3.5, Color(eye, 0.5))
	z.draw_circle(head + Vector2(3.5, -1.0), 1.0, eye)
	_big_arm(sh + Vector2(3, 1), hand_f, sk, suit)
	end_draw()
	return true


func _big_arm(shoulder: Vector2, hand: Vector2, sk: Color, sleeve: Color) -> void:
	var elbow := Art.joint(shoulder, hand, 17.0, 18.0, -1.0)
	var cuff := shoulder.lerp(elbow, 0.7)
	Art.limb(z, PackedVector2Array([shoulder, cuff]), 7.0, sleeve)
	Art.limb(z, PackedVector2Array([cuff, elbow, hand]), 5.0, sk)
	# כף ענקית עם אצבעות עבות
	var dvec := (hand - elbow).normalized()
	Art.disc(z, hand, 4.2, sk)
	for i in 4:
		var a := dvec.rotated(-0.6 + float(i) * 0.4)
		Art.limb(z, PackedVector2Array([hand + a * 2.5, hand + a * 7.0]), 1.8, sk)
