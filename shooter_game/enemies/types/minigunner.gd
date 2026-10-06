extends "res://enemies/zombie_type.gd"
# ============================================================
#  MINIGUNNER (שלב 15, צפון-מזרח, קרנבל) - זומבי ענק עם מיניגאן (6 קנים) מהמותן ותוף תחמושת על הגב.
#  מחזור:
#    WALK     - מתקרב לאט.
#    SPINUP   - הקנים מתחילים להסתובב, יילל מכני שעולה (SPIN_T) = אזהרה, תפוס מחסה!
#    FIRE     - מרסס כמו משוגע (FIRE_T שניות, RATE כדורים בשנייה) אבל לא מדויק: פיזור גדול
#               והכוונת "נגררת" אחריך באיטיות. קירות / מכשולים / מצופים עוצרים את הכדורים.
#    OVERHEAT - הקנים אדומים ומעלים אדים (HEAT_T): לא יכול לירות, ופגיעה בו = x1.5. החלון שלך.
#  צלילים: "mg_spin" (מנוע), "mg_fire" (יריה קצרה), "mg_steam" (אדים).
#  לשנות: RANGE, SPIN_T, FIRE_T, RATE, SPREAD, TRACK, HEAT_T.
# ============================================================

const ZScript := preload("res://zombie.gd")

const SOUNDS := {
	"mg_spin": [["Q", 80, 340, 0.0, 0.9, 0.05, 0.0, 0.3, 0.4, 0.05], ["N", 0, 0, 0.0, 0.9, 0.05, 0.0, 0.15, 0.6, 0]],
	"mg_fire": [["N", 0, 0, 0.0, 0.06, 0.0, 45.0, 0.7, 0.5, 0], ["S", 160, 90, 0.0, 0.05, 0.0, 50.0, 0.5, 1.0, 0]],
	"mg_steam": [["N", 0, 0, 0.0, 0.9, 0.02, 2.5, 0.35, 1.0, 0, 0.4]],
}

const RANGE := 620.0
const SPIN_T := 0.95
const FIRE_T := 2.0
const RATE := 9.0           # כדורים בשנייה
const SPREAD := 0.34         # רדיאנים לכל צד (לא מדויק!)
const TRACK := 1.6          # כמה מהר הכוונת עוקבת אחריך (רדיאנים/שנייה)
const HEAT_T := 1.6
const CD := Vector2(1.6, 2.6)

enum { WALK, SPINUP, FIRE, OVERHEAT }
var state := WALK
var shots := 0              # לבדיקות
var bursts := 0
var _st := 0.0
var _cd := 1.0
var _shot_t := 0.0
var _ang := 0.0
var _spin := 0.0            # זווית סיבוב הקנים
var _spin_v := 0.0
var _flash := 0.0
var _snd := 0.0


func stats() -> Dictionary:
	return {"name": "MINIGUNNER", "hp": 50, "walk": 30.0, "chase": 52.0, "damage": 1, "bite_delay": 1.0, "scale": 1.22, "width": 1.35,
		"duck": 0.0, "cover": 0.0, "skin": Color("8a9878"), "shirt": Color("4a5a3a"), "pants": Color("3a3a32"), "shoe": Color("1a1612"), "points": 460}


func brain_overrides() -> Dictionary:
	return {"aggression": 0.1, "keep_range": 300.0}


func can_bite() -> bool:
	return state == WALK


func _pivot() -> Vector2:
	return z.global_position + Vector2(z._dir * 12.0 * z.wf, -26.0) * z.sc


func physics(pl: Node, delta: float) -> bool:
	_cd -= delta
	_st -= delta
	_flash -= delta
	_spin += _spin_v * delta
	if z.dead:
		return false
	var tgt: Vector2 = (pl.global_position + Vector2(0, -26)) if pl != null else _pivot() + Vector2(z._dir * 100.0, 0)
	match state:
		WALK:
			_spin_v = move_toward(_spin_v, 0.0, 30.0 * delta)
			if _cd <= 0.0 and pl != null and not pl.dead and z.is_on_floor():
				var d: Vector2 = pl.global_position - z.global_position
				var sees: bool = z.brain == null or z.brain.sees
				if sees and absf(d.x) < RANGE and absf(d.y) < 200.0:
					state = SPINUP
					_st = SPIN_T
					z._dir = signf(d.x) if d.x != 0.0 else z._dir
					_ang = (tgt - _pivot()).angle()
					Sfx.play("mg_spin", z.global_position, 0.0, 0.05, 2)
					return _stay(delta)
			return false
		SPINUP:
			_spin_v = move_toward(_spin_v, 40.0, 60.0 * delta)
			_ang = lerp_angle(_ang, (tgt - _pivot()).angle(), delta * 3.0)
			if _st <= 0.0:
				state = FIRE
				_st = FIRE_T
				bursts += 1
				_shot_t = 0.0
		FIRE:
			_spin_v = 40.0
			var want := (tgt - _pivot()).angle()   # הכוונת נגררת אחריך באיטיות
			_ang = _ang + clampf(wrapf(want - _ang, -PI, PI), -TRACK * delta, TRACK * delta)
			var fwd := 0.0 if z._dir > 0.0 else PI   # לא יורה אחורה: הכי הרבה ~63 מעלות מהכיוון שהוא פונה
			_ang = fwd + clampf(wrapf(_ang - fwd, -PI, PI), -1.1, 1.1)
			_shot_t -= delta
			while _shot_t <= 0.0:
				_shot_t += 1.0 / RATE
				_fire()
			if _st <= 0.0:
				state = OVERHEAT
				_st = HEAT_T
				Sfx.play("mg_steam", z.global_position, -2.0, 0.1, 2)
		OVERHEAT:
			_spin_v = move_toward(_spin_v, 0.0, 30.0 * delta)
			if randf() < delta * 12.0:
				Particles.burst(z.get_parent(), _muzzle(), "smoke", Vector2.UP, 1)
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
	return _pivot() + Vector2.from_angle(_ang) * 30.0 * z.sc


func _fire() -> void:
	shots += 1
	var b = ZScript.EnemyShot.new()
	z.get_parent().add_child(b)
	b.global_position = _muzzle()
	var a := _ang + randf_range(-SPREAD, SPREAD) + sin(z._time * 23.0) * 0.08   # רועד ולא מדויק
	b.velocity = Vector2.from_angle(a) * randf_range(820.0, 980.0)
	b.life = 0.9
	_flash = 0.04
	_snd -= 1.0
	if _snd <= 0.0:   # לא כל כדור עושה צליל (אחרת רעש)
		_snd = 2.0
		Sfx.play("mg_fire", _muzzle(), -3.0, 0.15, 3)
	if randf() < 0.3:   # תרמילים
		Particles.burst(z.get_parent(), _pivot(), "fire", Vector2(-z._dir, -1.0), 1)


func damage_mult(_zone: String, _src: Dictionary) -> float:
	return 1.5 if state == OVERHEAT else 1.0


# ============================================================
#  ציור
# ============================================================
func draw() -> bool:
	begin_draw()
	var sk := col(z.skin)
	var vest := col(z.shirt)
	var p: float = z._walk_phase
	var f: Array = feet(4.0, 2.0)
	var hip := Vector2(-1.0, -21.0 + absf(sin(p)) * 0.8)
	var sh := Vector2(-1.0, -38.0)
	var head := sh + Vector2(3.0, -8.0)
	var recoil := sin(z._time * 60.0) * 1.2 if state == FIRE else 0.0
	z._leg(hip + Vector2(-3, 0), f[1], col(Art.shade(z.pants, 0.25)), col(Art.shade(z.skin, 0.2)), col(z.shoe))
	z._leg(hip + Vector2(3, 0), f[0], col(z.pants), sk, col(z.shoe))
	# תוף תחמושת על הגב + חגורת כדורים
	var drum := sh + Vector2(-12, 8)
	Art.disc(z, drum, 7.5, col(Color("4a4a44")), Art.OUTLINE, 1.2)
	z.draw_arc(drum, 4.5, 0.0, TAU, 10, col(Color("6a6a60")), 1.2)
	# גוף רחב, אפוד צבאי
	var body := PackedVector2Array([sh + Vector2(-9, -1), sh + Vector2(9, 0), hip + Vector2(8, 3), hip + Vector2(-8, 3)])
	Art.fill_shaded(z, body, vest, 0.15, 0.4)
	for i in 3:   # כיסים
		z.draw_rect(Rect2(sh + Vector2(-6 + float(i) * 4.5, 7), Vector2(3.5, 4)), col(Art.shade(z.shirt, 0.3)))
	# ראש עם בנדנה
	Art.oval_shaded(z, head, 6.5, 6.8, sk, 0.0)
	z.draw_line(head + Vector2(-6, -3), head + Vector2(6, -4), col(Color("c02020")), 3.0)
	z.draw_line(head + Vector2(-6, -3), head + Vector2(-10, 2), col(Color("c02020")), 1.6)
	z.draw_circle(head + Vector2(3.0, -0.5), 1.3, Color(1.0, 0.8, 0.3))
	Art.fill(z, PackedVector2Array([head + Vector2(1, 3), head + Vector2(6.5, 2.5), head + Vector2(6, 5.5), head + Vector2(1.5, 5.5)]), col(Color("2a0a0a")), Art.OUTLINE, 0.8)
	# המיניגאן (בקואורדינטות מקומיות: הזווית יחסית לכיוון)
	var la := Vector2(cos(_ang) * z._dir, sin(_ang)).normalized()
	var piv := Vector2(12.0, -26.0) - la * recoil
	var ang := la.angle()
	var tr := Transform2D(ang, piv)
	var hot := Color(1.0, 0.35, 0.15) if state == OVERHEAT else col(Color("5a5e66"))
	Art.fill_shaded(z, tr * PackedVector2Array([Vector2(-8, -5), Vector2(6, -5), Vector2(6, 5), Vector2(-8, 5)]), col(Color("3a3e44")), 0.2, 0.4, Art.OUTLINE, 1.2)   # גוף המנוע
	for i in 3:   # קנים מסתובבים
		var off := sin(_spin + float(i) * TAU / 3.0) * 3.0
		z.draw_line(tr * Vector2(6, off), tr * Vector2(30, off), Art.OUTLINE, 3.2)
		z.draw_line(tr * Vector2(6, off), tr * Vector2(30, off), hot, 1.8)
	z.draw_line(tr * Vector2(26, -4), tr * Vector2(26, 4), Art.OUTLINE, 2.0)
	if _flash > 0.0:   # להבת לוע
		var m := tr * Vector2(32, 0)
		Art.glow(z, m, 9.0, Color(1.0, 0.8, 0.3, 0.9))
		z.draw_colored_polygon(PackedVector2Array([m + la.orthogonal() * 3.0, m + la * 12.0, m - la.orthogonal() * 3.0]), Color(1.0, 0.9, 0.5))
	z.draw_line(drum + Vector2(4, 2), tr * Vector2(-4, 5), col(Color("b08a30")), 2.0)   # חגורת כדורים
	# ידיים על הנשק
	z._arm(sh + Vector2(-3, 1), tr * Vector2(-2, 4), col(Art.shade(z.skin, 0.25)), Art.shade(vest, 0.3))
	z._arm(sh + Vector2(4, 2), tr * Vector2(10, -4), sk, vest)
	end_draw()
	return true
