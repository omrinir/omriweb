extends "res://enemies/zombie_type.gd"
# ============================================================
#  UZI (שלב 18, "THE QUARRY") - זומבי גנגסטר עם עוזי ביד אחת, כובע הפוך ושרשרת זהב.
#  מחזור:
#    WALK   - מתקרב (המוח), שומר מרחק.
#    AIM    - מרים את העוזי אליך, ניצוץ אדום על הקנה (AIM_T) = אזהרה.
#    BURST  - צרור של SHOTS כדורים. הראשון מכוון לחזה (AIM_H - מעל שחקן כפוף), וכל כדור שאחריו עולה למעלה
#             בגלל ההדף (CLIMB לכל ירייה) - הצרור "מטפס". מתכופפים (S) = כל הצרור עובר מעליך.
#    RELOAD - מחליף מחסנית (RELOAD_T): החלון שלך.
#  צליל: "smg" (הירייה האמיתית מ-sounds/guns), "uz_clip" (מחסנית).
#  לשנות: RANGE, AIM_T, SHOTS, RATE, CLIMB, SPREAD, RELOAD_T.
# ============================================================

const ZScript := preload("res://zombie.gd")

const SOUNDS := {
	"uz_clip": [["C", 0, 0, 0.0, 0.05, 0.0, 30.0, 0.4, 1.0, 0], ["C", 0, 0, 0.22, 0.06, 0.0, 30.0, 0.5, 1.0, 0]],
}

const RANGE := 540.0
const AIM_T := 0.45
const SHOTS := 11
const RATE := 13.0          # כדורים בשנייה
const CLIMB := 0.065        # כמה הקנה עולה בכל ירייה (רדיאנים)
const SPREAD := 0.035
const AIM_H := -38.0         # גובה הכיוון: חזה עליון של שחקן עומד - מעל שחקן כפוף (34), כך שהתכופפות = לא נפגעים
const RELOAD_T := 1.4
const CD := Vector2(0.8, 1.6)

enum { WALK, AIM, BURST, RELOAD }
var state := WALK
var shots := 0              # לבדיקות
var bursts := 0
var _st := 0.0
var _cd := 1.0
var _shot_t := 0.0
var _left := 0
var _base := 0.0            # הכיוון אליך בתחילת הצרור
var _climb := 0.0           # כמה הקנה כבר עלה
var _flash := 0.0


func stats() -> Dictionary:
	return {"name": "UZI", "hp": 26, "walk": 50.0, "chase": 96.0, "damage": 1, "bite_delay": 0.8, "scale": 0.98, "width": 0.9,
		"duck": 0.25, "cover": 0.35, "skin": Color("93a382"), "shirt": Color("1e1e22"), "pants": Color("2c3a5a"), "shoe": Color("e8e8e0"), "points": 380}


func brain_overrides() -> Dictionary:
	return {"aggression": 0.3, "keep_range": 280.0}


func can_bite() -> bool:
	return state == WALK


func _pivot() -> Vector2:
	return z.global_position + Vector2(z._dir * 6.0, -36.0) * z.sc


func _aim_angle() -> float:   # הזווית של הקנה עכשיו: הבסיס + הטיפוס למעלה (לכיוון שהוא פונה)
	return _base - _climb * z._dir


func physics(pl: Node, delta: float) -> bool:
	_cd -= delta
	_st -= delta
	_flash -= delta
	if z.dead:
		return false
	var has_pl: bool = pl != null and not pl.dead
	match state:
		WALK:
			_climb = move_toward(_climb, 0.0, delta * 2.0)
			if _cd <= 0.0 and has_pl and z.is_on_floor():
				var d: Vector2 = pl.global_position - z.global_position
				var sees: bool = z.brain == null or z.brain.sees
				if sees and absf(d.x) < RANGE and absf(d.y) < 220.0:
					state = AIM
					_st = AIM_T
					z._dir = signf(d.x) if d.x != 0.0 else z._dir
					_climb = 0.0
					_base = ((pl.global_position + Vector2(0, AIM_H)) - _pivot()).angle()
					return _stay(delta)
			return false
		AIM:
			if has_pl:   # עוקב אחריך בזמן שהוא מכוון
				z._dir = signf(pl.global_position.x - z.global_position.x) if pl.global_position.x != z.global_position.x else z._dir
				_base = lerp_angle(_base, ((pl.global_position + Vector2(0, AIM_H)) - _pivot()).angle(), delta * 8.0)
			if _st <= 0.0:
				state = BURST
				bursts += 1
				_left = SHOTS
				_shot_t = 0.0
		BURST:
			_shot_t -= delta
			while _shot_t <= 0.0 and _left > 0:
				_shot_t += 1.0 / RATE
				_fire()
			if _left <= 0:
				state = RELOAD
				_st = RELOAD_T
				Sfx.play("uz_clip", z.global_position, -2.0, 0.1, 2)
		RELOAD:
			_climb = move_toward(_climb, 0.0, delta * 1.5)
			if _st <= 0.0:
				state = WALK
				_cd = randf_range(CD.x, CD.y)
	return _stay(delta)


func _stay(delta: float) -> bool:
	z.velocity.x = move_toward(z.velocity.x, 0.0, 800.0 * delta)
	if not z.is_on_floor():
		z.velocity.y += z.gravity * delta
	z.move_and_slide()
	return true


func _muzzle() -> Vector2:
	return _pivot() + Vector2.from_angle(_aim_angle()) * 16.0 * z.sc


func _fire() -> void:
	shots += 1
	_left -= 1
	var b = ZScript.EnemyShot.new()
	z.get_parent().add_child(b)
	b.global_position = _muzzle()
	b.velocity = Vector2.from_angle(_aim_angle() - randf_range(0.0, SPREAD) * z._dir) * randf_range(900.0, 1000.0)   # הפיזור רק למעלה
	b.life = 0.8
	_flash = 0.035
	_climb = minf(_climb + CLIMB, 1.0)   # ההדף מרים את הקנה
	Sfx.play("smg", _muzzle(), -5.0, 0.12, 3)
	if randf() < 0.5:   # תרמילים
		Particles.burst(z.get_parent(), _pivot(), "fire", Vector2(-z._dir, -1.0), 1)


# ============================================================
#  ציור
# ============================================================
func draw() -> bool:
	begin_draw()
	var sk := col(z.skin)
	var shirt := col(z.shirt)
	var p: float = z._walk_phase
	var f: Array = feet(5.0, 2.5)
	var hip := Vector2(0.0, -22.0 + absf(sin(p)) * 0.8)
	var sh := Vector2(1.0, -37.0)
	var head := sh + Vector2(3.0, -8.0)
	z._leg(hip + Vector2(-2, 0), f[1], col(Art.shade(z.pants, 0.25)), col(Art.shade(z.skin, 0.2)), col(z.shoe))
	z._leg(hip + Vector2(2, 0), f[0], col(z.pants), sk, col(z.shoe))
	# יד אחורית תלויה
	z._arm(sh + Vector2(-3, 1), sh + Vector2(-4.0 - sin(p) * 2.0, 15.0), Art.shade(sk, 0.25), Art.shade(shirt, 0.3))
	# גופייה שחורה עם קרעים + שרשרת זהב
	var body := PackedVector2Array([sh + Vector2(-6, -1), sh + Vector2(6, 0), hip + Vector2(5, 2), hip + Vector2(-5, 2)])
	Art.fill_shaded(z, body, shirt, 0.12, 0.4)
	z.draw_line(sh + Vector2(-2, 6), sh + Vector2(1, 10), col(Color("4a3a3a")), 1.2)
	z.draw_arc(sh + Vector2(1.5, 1.0), 4.0, 0.3, PI - 0.3, 8, col(Color("e8c040")), 1.4)
	z.draw_circle(sh + Vector2(1.5, 5.2), 1.3, col(Color("e8c040")))
	# ראש + כובע הפוך (המצחייה לאחור) + משקפי שמש
	Art.oval_shaded(z, head, 5.4, 5.8, sk, 0.0)
	Art.fill(z, PackedVector2Array([head + Vector2(-5.5, -2), head + Vector2(5, -3), head + Vector2(4, -7), head + Vector2(-4, -7.5)]), col(Color("c03030")), Art.OUTLINE, 1.0)
	Art.fill(z, PackedVector2Array([head + Vector2(-5, -3), head + Vector2(-11, -2), head + Vector2(-10, -0.5), head + Vector2(-5, -1.5)]), col(Color("a02020")), Art.OUTLINE, 0.8)
	z.draw_rect(Rect2(head + Vector2(0.5, -1.8), Vector2(5.5, 2.2)), col(Color("101014")))
	if not z.dead:
		z.draw_circle(head + Vector2(3.5, -0.8), 0.6, Color(1.0, 0.3, 0.2))
	Art.fill(z, PackedVector2Array([head + Vector2(1, 2.5), head + Vector2(5.5, 2.0), head + Vector2(5, 4.6), head + Vector2(1.5, 4.6)]), col(Color("2a0a0a")), Art.OUTLINE, 0.7)
	# העוזי ביד אחת (בקואורדינטות מקומיות)
	var a := _aim_angle() if state != WALK else (0.35 if z._dir > 0.0 else PI - 0.35)
	var la := Vector2(cos(a) * z._dir, sin(a)).normalized()
	var piv := Vector2(6.0, -36.0)
	var kick := 1.5 if _flash > 0.0 else 0.0
	var hand := piv + la * (9.0 - kick)
	var tr := Transform2D(la.angle(), hand)
	Art.fill(z, tr * PackedVector2Array([Vector2(-3, -2.5), Vector2(8, -2.5), Vector2(8, 1.5), Vector2(-3, 1.5)]), col(Color("2a2c30")), Art.OUTLINE, 1.0)   # גוף
	Art.fill(z, tr * PackedVector2Array([Vector2(0, 1.5), Vector2(3, 1.5), Vector2(3, 8), Vector2(0, 8)]), col(Color("1a1c20")), Art.OUTLINE, 0.8)   # מחסנית
	z.draw_line(tr * Vector2(8, -0.5), tr * Vector2(12, -0.5), Art.OUTLINE, 2.0)   # קנה
	if state == AIM and int(z._time * 14.0) % 2 == 0:   # ניצוץ אזהרה על הקנה
		Art.glow(z, tr * Vector2(12, -0.5), 5.0, Color(1.0, 0.2, 0.1, 0.8))
	if _flash > 0.0:
		var m := tr * Vector2(13, -0.5)
		Art.glow(z, m, 7.0, Color(1.0, 0.8, 0.3, 0.9))
		z.draw_colored_polygon(PackedVector2Array([m + la.orthogonal() * 2.5, m + la * 9.0, m - la.orthogonal() * 2.5]), Color(1.0, 0.92, 0.55))
	z._arm(sh + Vector2(3, 1), hand, sk, shirt)
	end_draw()
	return true
