extends "res://enemies/zombie_type.gd"
# ============================================================
#  PROPAGANDIST (משלב 41, "THE PARADE") - תעמולן של אימפריית המתים: מגפון ביד, תרמיל רמקול עם צופר על מוט מעל הראש.
#  "THEY LEARNED TO SPEAK": שומר מרחק (KEEP) ומשדר:
#    "SURRENDER!" - אתה בקונוס שלפניו (SHOUT_R): גל קול שמסחרר אותך (DAZE_T) ומזעיק את כל הזומבים בטווח CALL_R.
#    "THERE HE IS!" - אתה מתחבא (מתכופף מאחורי מחסה) יותר מ-HIDE_T: מסגיר את המיקום שלך - חיילי האימפריה בטווח CALL_R מסתערים.
#    ירייה בצופר (מעל הראש) HORN_HP פעמים -> צפצוף משוב: החיילים סביבו מבולבלים ("broken") והוא משתתק.
#  לשנות: SHOUT_CD, SHOUT_R, DAZE_T, CALL_R, HIDE_T, HORN_HP, KEEP.
# ============================================================

const E := preload("res://enemies/empire_kit.gd")

const SOUNDS := {
	"pp_shout": {"drive": 2.2, "layers": [["V", 160, 120, 0.0, 0.7, 0.03, 3.0, 0.6, 1.0, 0.06, 0, [700, 1600, 3]], ["N", 0, 0, 0.0, 0.7, 0.03, 3.0, 0.15, 0.6, 0, 0.5]]},
	"pp_squeal": [["S", 2400, 3600, 0.0, 0.9, 0.02, 2.0, 0.25, 1.0, 0.04], ["S", 1200, 1800, 0.0, 0.9, 0.02, 2.0, 0.15, 1.0, 0.03]],
	"pp_click": [["C", 0, 0, 0.0, 0.03, 0.0, 60.0, 0.3, 1.0, 0]],
}

const SHOUT_CD := 6.0
const SHOUT_WIND := 0.6
const SHOUT_R := 300.0
const DAZE_T := 1.0
const CALL_R := 450.0
const HIDE_T := 1.5
const HORN_HP := 2
const KEEP := 260.0

var working := true
var horn_hp := HORN_HP
var shouts := 0              # לבדיקות
var dazes := 0
var reveals := 0
var _cd := 2.5
var _wind := 0.0
var _hide := 0.0
var _ring := 0.0


func stats() -> Dictionary:
	return {"name": "PROPAGANDIST", "hp": 30, "walk": 36.0, "chase": 60.0, "damage": 1, "bite_delay": 1.0, "scale": 1.0, "width": 1.0,
		"duck": 0.2, "cover": 0.5, "skin": Color("7e8a74"), "shirt": E.UNIFORM_D, "pants": E.UNIFORM, "shoe": Color("1a1816"), "points": 500}


func setup() -> void:
	z.add_to_group("empire")
	_cd = randf_range(1.5, 3.5)


func brain_overrides() -> Dictionary:
	return {"aggression": 0.15, "retreat_probability": 0.3}


func can_bite() -> bool:
	return not working


func on_damage(_amount: int, hit_pos: Vector2, dir: Vector2, _src: Dictionary) -> bool:
	if working and (hit_pos.y - z.global_position.y) / z.sc < -54.0:   # הצופר על המוט
		horn_hp -= 1
		Particles.burst(z.get_parent(), hit_pos, "spark", -dir, 4)
		if horn_hp <= 0:
			_feedback()
		return false
	return true


func _feedback() -> void:
	working = false
	_wind = 0.0
	Sfx.play("pp_squeal", z.global_position, 2.0, 0.05, 2)
	z._popup("FEEDBACK!", Color("a0e0ff"), 15, -90.0)
	E.order(z, "broken", CALL_R * 0.6)


func physics(pl: Node, delta: float) -> bool:
	_cd -= delta
	_ring = maxf(_ring - delta, 0.0)
	if z.dead or not working or pl == null or pl.dead:
		return false
	if z.goal_x < INF:   # פקודת תנועה (למשל לצאת מנתיב הטנקים בשלב 41) - קודם מצייתים
		_wind = 0.0
		return false
	var d: Vector2 = pl.global_position - z.global_position
	var near := absf(d.x) < 900.0 and absf(d.y) < 220.0
	# מתחבא? מסגיר אותך
	if near and pl._crouching and absf(d.x) < CALL_R + 200.0:
		_hide += delta
		if _hide > HIDE_T:
			_hide = -2.0
			reveals += 1
			Sfx.play("pp_shout", z.global_position, 0.0, 0.05, 2)
			z._popup("THERE HE IS!", Color("ff6040"), 15, -95.0)
			for o in z.get_tree().get_nodes_in_group("empire"):
				if o != z and not o.dead and not o.is_boss() and o.global_position.distance_to(z.global_position) < CALL_R:
					o._alert_t = maxf(float(o._alert_t), 6.0)
					o._rush_t = 2.5
	else:
		_hide = maxf(_hide - delta, 0.0)
	if _wind > 0.0:
		_wind -= delta
		if _wind <= 0.0:
			_shout(pl)
		return _move(0.0, delta)
	if near:
		z._dir = signf(d.x) if absf(d.x) > 4.0 else z._dir
		if _cd <= 0.0 and absf(d.x) < SHOUT_R - 20.0:
			_wind = SHOUT_WIND
			Sfx.play("pp_click", z.global_position, -2.0, 0.1, 2)
			return _move(0.0, delta)
	if near and absf(d.x) < KEEP and absf(d.y) < 90.0:   # שומר מרחק
		return _move(-z._dir * float(z.walk_speed) * 1.4, delta)
	return false


func _shout(pl: Node) -> void:
	_cd = SHOUT_CD
	shouts += 1
	_ring = 0.6
	Sfx.play("pp_shout", z.global_position, 3.0, 0.05, 2)
	z._popup("SURRENDER!", Color("ffd040"), 16, -95.0)
	var d: Vector2 = pl.global_position - z.global_position
	if signf(d.x) == z._dir and absf(d.x) < SHOUT_R and absf(d.y) < 110.0:   # בקונוס שלפניו
		dazes += 1
		pl.daze(DAZE_T, "SO LOUD... CAN'T THINK")
		pl.velocity.x += z._dir * 160.0
	for o in z.get_tree().get_nodes_in_group("zombies"):
		if o != z and not o.dead and not o.is_boss() and o.global_position.distance_to(z.global_position) < CALL_R:
			o._alert_t = maxf(float(o._alert_t), 5.0)


func _move(vx: float, delta: float) -> bool:
	z.velocity.x = move_toward(z.velocity.x, vx, 800.0 * delta)
	if not z.is_on_floor():
		z.velocity.y += z.gravity * delta
	z.move_and_slide()
	return true


# ============================================================
#  ציור: כובע מצחייה, תרמיל רמקול, מוט עם צופר מעל הראש, מגפון ביד (מורם בצעקה), גלי קול.
# ============================================================
func draw() -> bool:
	begin_draw()
	var up := _wind > 0.0 or _ring > 0.3
	var o: Dictionary = E.soldier(self, z, Vector2(12, -8) if up else Vector2(9, 5), "cap", E.UNIFORM_D)
	var sh: Vector2 = o.sh
	var hf: Vector2 = o.hf
	# תרמיל
	DrawBatch.rect(z, Rect2(sh + Vector2(-14, -2), Vector2(8, 18)), col(Color("3a3a32")))
	DrawBatch.rect(z, Rect2(sh + Vector2(-13, 2), Vector2(6, 4)), col(Color("1a1a1a")))
	DrawBatch.circle(z, sh + Vector2(-10, 11), 1.2, Color(0.3, 1.0, 0.4) if working else Color(0.3, 0.1, 0.1))
	# מוט + צופר
	var top := Vector2(-10, -64)
	DrawBatch.line(z, sh + Vector2(-10, -2), top, col(Color("2a2a2a")), 1.6)
	if working:
		DrawBatch.colored_polygon(z, PackedVector2Array([top + Vector2(-2, -3), top + Vector2(2, -3), top + Vector2(12, -8), top + Vector2(12, 4), top + Vector2(2, 2), top + Vector2(-2, 2)]), col(Color("c8c4b8")))
		DrawBatch.line(z, top + Vector2(12, -8), top + Vector2(12, 4), col(Color("5a5850")), 1.4)
		if horn_hp < HORN_HP:
			DrawBatch.line(z, top + Vector2(5, -4), top + Vector2(9, 1), col(Color("1a1a1a")), 1.0)
	else:   # צופר שבור תלוי
		DrawBatch.colored_polygon(z, PackedVector2Array([top + Vector2(-2, 0), top + Vector2(2, 0), top + Vector2(5, 10), top + Vector2(-4, 10)]), col(Color("8a867a")))
	# מגפון
	var mg := hf + Vector2(1, -1)
	DrawBatch.colored_polygon(z, PackedVector2Array([mg + Vector2(0, -1.5), mg + Vector2(0, 1.5), mg + Vector2(9, 4.5), mg + Vector2(9, -4.5)]), col(E.RED))
	DrawBatch.line(z, mg + Vector2(9, -4.5), mg + Vector2(9, 4.5), col(Color("e8e0d0")), 1.2)
	end_draw()
	if _wind > 0.0 and not z.dead:   # שאיפה לפני צעקה
		var k := 1.0 - clampf(_wind / SHOUT_WIND, 0.0, 1.0)
		DrawBatch.string(z, ThemeDB.fallback_font, Vector2(-6, -100), "!", HORIZONTAL_ALIGNMENT_LEFT, -1, int(12.0 + 8.0 * k), Color(1.0, 0.8, 0.2, 0.6 + 0.4 * k))
	if _ring > 0.0:   # גלי קול בקונוס
		var k2 := 1.0 - _ring / 0.6
		for q in 3:
			var rr := 30.0 + (SHOUT_R - 30.0) * clampf(k2 + float(q) * 0.12, 0.0, 1.0)
			var a0 := 0.0 if z._dir > 0.0 else PI
			DrawBatch.arc(z, Vector2(0, -36), rr, a0 - 0.35, a0 + 0.35, 10, Color(1.0, 0.85, 0.3, 0.45 * (1.0 - k2)), 3.0)
	return true
