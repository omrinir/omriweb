extends "res://enemies/zombie_type.gd"
# ============================================================
#  DRUMMER (משלב 41, "THE PARADE") - מתופף המצעד של אימפריית המתים: תוף מלחמה אדום עם הסמל על הבטן, כובע קסדה עם נוצה אדומה.
#  "THEY LEARNED TO MARCH": מכה בתוף כל BEAT שניות - כל חייל אימפריה בטווח DRUM_R צועד מהר יותר (x1.3, zombie.gd meta "drum_t").
#    כשאתה טוען - מכה "תיפוף הסתערות" (ROLL): כל היחידה מסתערת עליך. נשאר באמצע היחידה (KEEP).
#    התוף מגן עליו מלפנים (כדורים בבטן פוגעים בתוף) - DRUM_HP פגיעות והתוף נשבר: אין יותר קצב, והוא כועס ורץ.
#    הורגים אותו כשהתוף שלם -> "broken": החיילים סביבו מאבדים את הקצב.
#  לשנות: BEAT, DRUM_R, DRUM_HP, ROLL_CD, KEEP.
# ============================================================

const E := preload("res://enemies/empire_kit.gd")

const SOUNDS := {
	"dr_beat": [["S", 90, 55, 0.0, 0.16, 0.0, 18.0, 0.55, 1.0, 0], ["N", 0, 0, 0.0, 0.05, 0.0, 50.0, 0.25, 0.3, 0, 0.5]],
	"dr_roll": [["N", 0, 0, 0.0, 0.7, 0.05, 3.0, 0.35, 0.5, 0, 0.6], ["S", 110, 90, 0.0, 0.7, 0.05, 3.0, 0.3, 1.0, 0.2]],
	"dr_break": [["N", 0, 0, 0.0, 0.25, 0.0, 14.0, 0.7, 0.6, 0, 0.5], ["S", 200, 60, 0.0, 0.2, 0.0, 14.0, 0.4, 1.0, 0]],
}

const BEAT := 0.5
const DRUM_R := 380.0
const DRUM_HP := 3
const ROLL_CD := 6.0
const KEEP := 200.0

var intact := true
var drum_hp := DRUM_HP
var beats := 0               # לבדיקות
var boosted := 0             # כמה חיילים קיבלו קצב (במכה האחרונה)
var rolls := 0
var _beat := 0.0
var _roll_cd := 2.0
var _hit_t := 0.0
var _arm := 0.0


func stats() -> Dictionary:
	return {"name": "DRUMMER", "hp": 30, "walk": 38.0, "chase": 60.0, "damage": 1, "bite_delay": 0.9, "scale": 1.0, "width": 1.05,
		"duck": 0.0, "cover": 0.3, "skin": Color("7a8670"), "shirt": E.UNIFORM, "pants": E.UNIFORM, "shoe": Color("1a1816"), "points": 480}


func setup() -> void:
	z.add_to_group("empire")
	_beat = randf_range(0.0, BEAT)


func brain_overrides() -> Dictionary:
	return {"aggression": 0.25 if intact else 0.9}


func can_bite() -> bool:
	return not intact


# התוף: לפני הבטן (מקומי, כיוון ימינה)
func _in_drum(p: Vector2) -> bool:
	var l: Vector2 = (p - z.global_position) / z.sc
	l.x *= z._dir
	return Rect2(-4, -34, 30, 22).has_point(l)   # (עד שפת אזור הפגיעה מלפנים)


func on_damage(_amount: int, hit_pos: Vector2, dir: Vector2, src: Dictionary) -> bool:
	var s := str(src.get("source", "bullet"))
	if intact and (s == "bullet" or s == "melee") and _in_drum(hit_pos):
		drum_hp -= 1
		_hit_t = 0.15
		Sfx.play("dr_beat", hit_pos, -2.0, 0.3, 3)
		Particles.burst(z.get_parent(), hit_pos, "spark", -dir, 3)
		if drum_hp <= 0:
			_break_drum()
		return false
	return true


func _break_drum() -> void:
	intact = false
	Sfx.play("dr_break", z.global_position, 0.0, 0.1, 2)
	Particles.burst(z.get_parent(), z.global_position + Vector2(0, -24), "leaf", Vector2.UP, 6)
	z._popup("THE DRUM IS BROKEN", Color("ffe0a0"), 14, -80.0)
	z._alert_t = maxf(float(z._alert_t), 8.0)
	z._rush_t = 4.0


func on_death() -> void:
	E.leader_down(z.get_parent())
	if intact:
		E.order(z, "broken", DRUM_R)


func physics(pl: Node, delta: float) -> bool:
	_beat -= delta
	_roll_cd -= delta
	_hit_t -= delta
	_arm = maxf(_arm - delta * 6.0, 0.0)
	if z.dead or not intact:
		return false
	if _beat <= 0.0:
		_beat = BEAT
		beats += 1
		_arm = 1.0
		boosted = 0
		for o in z.get_tree().get_nodes_in_group("empire"):
			if not o.dead and not o.is_boss() and o.global_position.distance_to(z.global_position) < DRUM_R:
				o.set_meta("drum_t", float(o._time) + BEAT + 0.1)
				boosted += 1
		if Art.on_screen(z, z.global_position, 200.0):
			Sfx.play("dr_beat", z.global_position, -10.0 if beats % 2 == 0 else -7.0, 0.05, 3)
	if pl == null or pl.dead:
		return false
	if z.goal_x < INF:   # פקודת תנועה (למשל לצאת מנתיב הטנקים בשלב 41) - קודם מצייתים
		return false
	var d: Vector2 = pl.global_position - z.global_position
	if absf(d.x) < 800.0 and absf(d.y) < 200.0:
		z._dir = signf(d.x) if absf(d.x) > 4.0 else z._dir
		if _roll_cd <= 0.0 and pl.is_reloading():   # טוען? תיפוף הסתערות
			_roll_cd = ROLL_CD
			rolls += 1
			Sfx.play("dr_roll", z.global_position, 2.0, 0.05, 2)
			z._popup("DRUM ROLL!", Color("ff5040"), 14, -85.0)
			E.order(z, "charge", DRUM_R)
	if absf(d.x) < KEEP and absf(d.y) < 90.0:   # נשאר מאחורי החיילים
		z.velocity.x = move_toward(z.velocity.x, -z._dir * float(z.walk_speed) * 1.3, 600.0 * delta)
		if not z.is_on_floor():
			z.velocity.y += z.gravity * delta
		z.move_and_slide()
		return true
	return false


# ============================================================
#  ציור: חייל עם תוף אדום גדול (חישוקי פליז, חבלים בזיגזג, הסמל), שני מקלות שעולים ויורדים בקצב, נוצה אדומה על הקסדה.
#  מעגל קצב דק סביב היחידה בכל מכה.
# ============================================================
func draw() -> bool:
	begin_draw()
	var up := _arm
	var o: Dictionary = E.soldier(self, z, Vector2(10, -6.0 - 8.0 * up), "helmet", E.UNIFORM, Vector2(7, -6.0 - 8.0 * (1.0 - up)))
	var head: Vector2 = o.head
	var sh: Vector2 = o.sh
	var hf: Vector2 = o.hf
	z.draw_line(head + Vector2(-2, -7), head + Vector2(-6, -15), col(E.RED), 2.4)   # נוצה
	z.draw_line(sh + Vector2(-6, -1), sh + Vector2(8, 16), col(Color("e8e0d0")), 1.6)   # רצועת התוף
	if intact:
		var c := Vector2(9, -23)
		var dc := col(E.RED.lightened(0.3)) if _hit_t > 0.0 else col(E.RED)
		z.draw_rect(Rect2(c + Vector2(-8, -9), Vector2(16, 18)), dc)
		z.draw_rect(Rect2(c + Vector2(-9, -10), Vector2(18, 2.5)), col(E.BRASS))
		z.draw_rect(Rect2(c + Vector2(-9, 7.5), Vector2(18, 2.5)), col(E.BRASS))
		for q in 4:   # חבלים
			var x0 := -8.0 + float(q) * 4.0
			z.draw_line(c + Vector2(x0, -7.5), c + Vector2(x0 + 4.0, 7.5), col(Color("e8e0d0")), 0.8)
		E.emblem(z, c + Vector2(0, 0), 3.4)
		if drum_hp < DRUM_HP:   # סדקים
			z.draw_line(c + Vector2(-3, -6), c + Vector2(2, 1), col(Color("1a0a08")), 1.0)
	else:   # שברי תוף תלויים
		z.draw_line(Vector2(3, -14), Vector2(12, -18), col(E.BRASS), 2.0)
		z.draw_line(Vector2(5, -30), Vector2(14, -27), col(E.RED_D), 3.0)
	z.draw_line(hf, hf + Vector2(6, 5), col(Color("d8c8a0")), 1.4)   # מקלות
	var hb: Vector2 = sh + Vector2(7, -6.0 - 8.0 * (1.0 - up))
	z.draw_line(hb, hb + Vector2(6, 5), col(Color("d8c8a0")), 1.4)
	end_draw()
	if intact and not z.dead and _arm > 0.7:
		z.draw_arc(Vector2(0, -20), 30.0 + 20.0 * (1.0 - _arm), 0.0, TAU, 24, Color(1.0, 0.3, 0.2, 0.25), 1.5)
	return true
