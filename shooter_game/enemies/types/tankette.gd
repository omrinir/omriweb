extends "res://enemies/zombie_type.gd"
# ============================================================
#  TANKETTE (משלב 43, "WAR FACTORY") - טנקט: טנק זעיר לאדם אחד שיוצא מפס הייצור. זומבי בצוהר, מקלע בחזית.
#  שריון קדמי: כדורים מלפנים עושים FRONT_MULT בלבד. מאחור - REAR_MULT. פיצוצים - נזק מלא.
#  מסתובב לאט (TURN_T - עוצר ומסתובב): קפוץ מעליו ותירה בגב.
#  "THEY LEARN YOUR FLANK - TOGETHER": פגעת בגב של טנקטים FLANK_LEARN פעמים? כל הטנקטים בשלב שומרים מרחק (KEEP_LEARNED)
#    כדי שלא תקפוץ מעליהם, ומסתובבים מהר יותר (TURN_LEARNED).
#  יורה צרורות קצרים (MG_N) כשהוא פונה אליך, דורס כשהוא צמוד.
#  לשנות: FRONT_MULT, REAR_MULT, TURN_T, TURN_LEARNED, KEEP, KEEP_LEARNED, FLANK_LEARN, MG_N, MG_CD.
# ============================================================

const E := preload("res://enemies/empire_kit.gd")

const SOUNDS := {
	"tk_clang": [["S", 1200, 900, 0.0, 0.1, 0.0, 30.0, 0.3, 1.0, 0.02], ["N", 0, 0, 0.0, 0.05, 0.0, 50.0, 0.2, 0.4, 0, 0.4]],
	"tk_engine": [["S", 70, 75, 0.0, 0.6, 0.05, 2.0, 0.2, 1.0, 0.05], ["N", 0, 0, 0.0, 0.6, 0.05, 2.0, 0.1, 0.2, 0, 0.6]],
}

const FRONT_MULT := 0.25
const REAR_MULT := 1.5
const TURN_T := 0.9
const TURN_LEARNED := 0.35
const KEEP := 40.0
const KEEP_LEARNED := 230.0
const FLANK_LEARN := 2
const MG_N := 3
const MG_CD := 2.2
const RAM_CD := 0.8

var rear_hits := 0           # לבדיקות
var front_hits := 0
var turns := 0
var bursts := 0
var _turn := 0.0
var _mg := 1.5
var _left := 0
var _rate := 0.0
var _ram := 0.0
var _mult := 1.0


func stats() -> Dictionary:
	return {"name": "TANKETTE", "hp": 60, "walk": 50.0, "chase": 84.0, "damage": 1, "bite_delay": 1.0, "scale": 1.15, "width": 1.5,
		"duck": 0.0, "cover": 0.0, "skin": Color("7a8670"), "shirt": E.UNIFORM, "pants": E.UNIFORM, "shoe": Color("1a1816"), "points": 620}


func setup() -> void:
	z.add_to_group("empire")
	z.set_meta("pit_hop", false)


func can_bite() -> bool:
	return false


static func learned(main: Node) -> bool:
	return main.has_meta("tankette_flank") and int(main.get_meta("tankette_flank")) >= FLANK_LEARN


func on_damage(_amount: int, hit_pos: Vector2, dir: Vector2, src: Dictionary) -> bool:
	_mult = 1.0
	var s := str(src.get("source", "bullet"))
	if src.has("blast") or not (s == "bullet" or s == "melee"):
		return true
	if dir.x * z._dir < 0.0:   # הקליע נע נגד הכיוון שהוא פונה = פגיעה בחזית
		_mult = FRONT_MULT
		front_hits += 1
		if front_hits % 4 == 1:
			Sfx.play("tk_clang", hit_pos, -2.0, 0.1, 3)
			Particles.burst(z.get_parent(), hit_pos, "spark", -dir, 3)
	else:
		_mult = REAR_MULT
		rear_hits += 1
		var main: Node = z.get_parent()
		if rear_hits == 1:   # נספר פעם אחת לכל טנקט
			var n := (int(main.get_meta("tankette_flank")) if main.has_meta("tankette_flank") else 0) + 1
			main.set_meta("tankette_flank", n)
			if n == FLANK_LEARN:
				z._popup("THEY LEARNED - KEEP DISTANCE", Color("ff8060"), 13, -70.0)
	return true


func damage_mult(_zone: String, _src: Dictionary) -> float:
	return _mult


func physics(pl: Node, delta: float) -> bool:
	_mg -= delta
	_rate -= delta
	_ram -= delta
	if z.dead:
		return false
	if not z.is_on_floor():
		z.velocity.y += z.gravity * delta
	if pl == null or pl.dead:
		z.velocity.x = move_toward(z.velocity.x, 0.0, 400.0 * delta)
		z.move_and_slide()
		return true
	var d: Vector2 = pl.global_position - z.global_position
	var smart := learned(z.get_parent())
	var want: float = signf(d.x) if absf(d.x) > 6.0 else float(z._dir)
	var target_v := 0.0
	if z.goal_x < INF:   # פקודת תנועה
		var gd: float = z.goal_x - z.global_position.x
		want = signf(gd) if absf(gd) > 6.0 else z._dir
		target_v = want * float(z.chase_speed) if absf(gd) > 12.0 else 0.0
	if want != z._dir:   # מסתובב לאט: עוצר ומסתובב
		_turn += delta
		target_v = 0.0
		if _turn >= (TURN_LEARNED if smart else TURN_T):
			_turn = 0.0
			z._dir = want
			turns += 1
	else:
		_turn = 0.0
		if z.goal_x == INF:
			var keep := KEEP_LEARNED if smart else KEEP
			if absf(d.x) > keep + 20.0:
				target_v = z._dir * float(z.chase_speed)
			elif absf(d.x) < keep - 20.0 and smart:
				target_v = -z._dir * float(z.walk_speed)   # נסוג אחורה, ממשיך לפנות אליך
	# מקלע
	if _left > 0:
		if _rate <= 0.0:
			_left -= 1
			_rate = 0.11
			var mz: Vector2 = z.global_position + Vector2(z._dir * 24.0 * z.wf, -14.0) * z.sc
			E.fire(z, mz, pl.global_position + Vector2(0, E.squad_aim_y(z.get_parent())) + Vector2(0, randf_range(-6, 6)), 660.0)
			Sfx.play("mb_mg", mz, -5.0, 0.1, 4)
	elif _mg <= 0.0 and want == z._dir and absf(d.x) < 620.0 and absf(d.y) < 100.0:
		_mg = MG_CD
		_left = MG_N
		bursts += 1
	# דורס
	if _ram <= 0.0 and absf(d.x) < 26.0 * z.wf and absf(d.y) < 40.0:
		_ram = RAM_CD
		pl.hurt(1, Vector2(z._dir * 1.5, -0.6))
	z.velocity.x = move_toward(z.velocity.x, target_v, 300.0 * delta)
	z.move_and_slide()
	if z.is_on_wall() and z.is_on_floor() and target_v != 0.0:
		z.velocity.y = -380.0
	z._walk_phase += delta * absf(z.velocity.x) * 0.075
	if Engine.get_physics_frames() % 50 == 0 and Art.on_screen(z, z.global_position):
		Sfx.play("tk_engine", z.global_position, -14.0, 0.1, 2)
	return true


# ============================================================
#  ציור: זחל עם גלגלים, גוף משופע עם שריון קדמי עבה, הסמל, צוהר עם ראש הזומבי, מקלע בחזית. בסיבוב - חץ עשן
# ============================================================
func draw() -> bool:
	begin_draw()
	var armor := col(Color("4e5244"))
	var dark := col(Color("2c2e26"))
	var ph: float = z._walk_phase
	DrawBatch.colored_polygon(z, PackedVector2Array([Vector2(-20, -1), Vector2(20, -1), Vector2(24, -6), Vector2(20, -11), Vector2(-20, -11), Vector2(-24, -6)]), dark)
	for q in 5:
		var wx := -16.0 + float(q) * 8.0
		DrawBatch.circle(z, Vector2(wx, -5), 3.4, col(Color("1a1a18")))
		DrawBatch.line(z, Vector2(wx, -5), Vector2(wx, -5) + Vector2.from_angle(ph + float(q)) * 2.6, col(Color("5a5a50")), 1.0)
	Art.fill_shaded(z, PackedVector2Array([Vector2(-21, -10), Vector2(16, -10), Vector2(24, -16), Vector2(14, -26), Vector2(-18, -26), Vector2(-22, -18)]), armor, 0.14, 0.4)
	DrawBatch.line(z, Vector2(16, -10), Vector2(24, -16), col(Color("6a6e60")), 2.5)   # השריון הקדמי העבה
	DrawBatch.line(z, Vector2(24, -16), Vector2(14, -26), col(Color("6a6e60")), 2.5)
	E.emblem(z, Vector2(-6, -17), 4.2, col(Color(0.9, 0.88, 0.82)))
	DrawBatch.rect(z, Rect2(Vector2(18, -15), Vector2(10, 2.4)), col(Color("1a1a1a")))   # מקלע
	if _left > 0 and not z.dead:
		Art.glow(z, Vector2(29, -14), 4.0, Color(1.0, 0.8, 0.3, 0.8))
	# צוהר + הנהג
	DrawBatch.rect(z, Rect2(Vector2(-4, -29), Vector2(12, 3)), dark)
	if not z.dead:
		Art.oval_shaded(z, Vector2(2, -33), 4.2, 4.6, col(z.skin), 0.0)
		E.helmet(z, Vector2(2, -32), col(E.STEEL))
		DrawBatch.circle(z, Vector2(4.5, -33), 1.0, Color(1.0, 0.25, 0.2))
	end_draw()
	if _turn > 0.0 and not z.dead:   # מסתובב
		DrawBatch.arc(z, Vector2(0, -20), 26.0, -PI * 0.8, -PI * 0.8 + TAU * clampf(_turn / (TURN_LEARNED if learned(z.get_parent()) else TURN_T), 0.0, 1.0), 16, Color(1.0, 0.85, 0.4, 0.6), 2.0)
	return true
