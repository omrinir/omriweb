extends "res://enemies/zombie_type.gd"
# ============================================================
#  CONSCRIPT (משלב 40, "HARBOR OF WAR") - טוראי של אימפריית המתים: מדים, קסדה, סרט זרוע אדום, רובה.
#  "THEY LEARNED TO OBEY": מתקדם עם היחידה. יש קו ראייה ומרחק (RANGE)? עוצר, מכוון (AIM_T - נצנוץ על הקנה) ויורה.
#    "THEY LEARN TOGETHER": קפצת / התכופפת מעל כדור של רובאי כלשהו? כל הרובאים בשלב מכוונים גבוה / נמוך יותר (empire_kit squad_aim_y).
#    פקודות (empire_kit order): "volley" - כולם מכוונים ויורים ביחד, "charge" - הסתערות, "leaderless" - הקצין מת: מבולבלים.
#  לשנות: RANGE, AIM_T, SHOT_CD, BULLET_V.
# ============================================================

const E := preload("res://enemies/empire_kit.gd")

const SOUNDS := {
	"cs_shot": [["N", 0, 0, 0.0, 0.12, 0.0, 30.0, 0.7, 0.6, 0, 0.5], ["S", 220, 90, 0.0, 0.1, 0.0, 30.0, 0.4, 1.0, 0]],
	"cs_bolt": [["C", 0, 0, 0.0, 0.04, 0.0, 60.0, 0.4, 1.0, 0], ["C", 0, 0, 0.12, 0.04, 0.0, 60.0, 0.35, 1.0, 0]],
}

const RANGE := Vector2(140.0, 560.0)
const AIM_T := 0.55
const SHOT_CD := Vector2(2.4, 3.4)
const BULLET_V := 640.0

enum { ADVANCE, AIM, CONFUSED }
var state := ADVANCE
var shots := 0               # לבדיקות
var volleys := 0
var _st := 0.0
var _cd := 1.5


func stats() -> Dictionary:
	return {"name": "CONSCRIPT", "hp": 30, "walk": 40.0, "chase": 70.0, "damage": 1, "bite_delay": 0.8, "scale": 1.0, "width": 1.0,
		"duck": 0.35, "cover": 0.45, "skin": Color("7a8670"), "shirt": E.UNIFORM, "pants": E.UNIFORM, "shoe": Color("1a1816"), "points": 360}


func setup() -> void:
	z.add_to_group("empire")
	_cd = randf_range(0.8, 2.5)


func brain_overrides() -> Dictionary:
	return {"aggression": 0.45}


func can_bite() -> bool:
	return state == ADVANCE


func muzzle() -> Vector2:
	return z.global_position + Vector2(z._dir * 20.0, -33.0) * z.sc


func on_order(kind: String, _from: Node) -> void:
	if z.dead:
		return
	match kind:
		"volley":
			if state != CONFUSED:
				state = AIM
				_st = AIM_T + 0.1
				volleys += 1
		"charge":
			if state != CONFUSED:
				state = ADVANCE
				z._alert_t = maxf(float(z._alert_t), 6.0)
				z._rush_t = 3.0
		"leaderless":
			state = CONFUSED
			_st = 4.0
		"broken":
			if state != CONFUSED:
				state = CONFUSED
				_st = 2.0


func physics(pl: Node, delta: float) -> bool:
	_st -= delta
	_cd -= delta
	if z.dead or pl == null or pl.dead:
		return false
	var d: Vector2 = pl.global_position - z.global_position
	match state:
		CONFUSED:   # בלי קצין: מסתכל לצדדים, מסתובב במקום
			if _st <= 0.0:
				state = ADVANCE
			if Engine.get_physics_frames() % 50 == 0:
				z._dir = -z._dir
			return _stay(delta)
		AIM:
			z._dir = signf(d.x) if absf(d.x) > 4.0 else z._dir
			if _st <= 0.0:
				_fire(pl)
				state = ADVANCE
				_cd = randf_range(SHOT_CD.x, SHOT_CD.y)
			return _stay(delta)
	if _cd <= 0.0 and absf(d.x) > RANGE.x and absf(d.x) < RANGE.y and absf(d.y) < 160.0 and E.clear_shot(z, muzzle(), pl.global_position + Vector2(0, -24)):
		state = AIM
		_st = AIM_T
		z._dir = signf(d.x)
		return _stay(delta)
	return false


func _stay(delta: float) -> bool:
	z.velocity.x = move_toward(z.velocity.x, 0.0, 800.0 * delta)
	if not z.is_on_floor():
		z.velocity.y += z.gravity * delta
	z.move_and_slide()
	return true


func _fire(pl: Node) -> void:
	shots += 1
	var tgt: Vector2 = pl.global_position + Vector2(0, E.squad_aim_y(z.get_parent()))   # הגובה שהיחידה למדה
	tgt += Vector2(0.0, muzzle().distance_to(tgt) * randf_range(-0.1, 0.06))   # פיזור של רובה (זווית - גדל עם המרחק)
	E.fire(z, muzzle(), tgt, BULLET_V)
	Sfx.play("cs_shot", muzzle(), -4.0, 0.15, 4)
	Particles.burst(z.get_parent(), muzzle(), "smoke", Vector2(z._dir, -0.3), 2)


# ============================================================
#  ציור: מדים, קסדה, סרט זרוע, רובה (מורם בכיוון היריה בזמן כיוון), נצנוץ אזהרה על הקנה
# ============================================================
func draw() -> bool:
	begin_draw()
	var aiming := state == AIM
	var o: Dictionary = E.soldier(self, z, Vector2(12, -3) if aiming else Vector2(10, 6), "helmet")
	var hf: Vector2 = o.hf
	E.rifle(z, hf, Vector2(1, 0) if aiming else Vector2(1, -0.7))
	if aiming and not z.dead:
		var k := 1.0 - clampf(_st / AIM_T, 0.0, 1.0)
		Art.glow(z, hf + Vector2(17, 0), 4.0 + 6.0 * k, Color(1.0, 0.85, 0.4, 0.3 + 0.5 * k))
	if state == CONFUSED and not z.dead:
		var head: Vector2 = o.head
		z.draw_string(ThemeDB.fallback_font, head + Vector2(-3, -12), "?", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(1, 1, 1, 0.9))
	end_draw()
	return true
