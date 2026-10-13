extends "res://enemies/zombie_type.gd"
# ============================================================
#  STORMTROOPER (משלב 44, "THE DAM") - חייל סער מובחר של אימפריית המתים: מסכת גז, מעיל עור, תת-מקלע, רימונים.
#  "THEY LEARNED TO ASSAULT": מסתער מכיסוי לכיסוי ויורה צרורות (SMG_N).
#    רואה שאתה יורה עליו (zombie.gd on_player_fired -> on_shot) -> מתגלגל הצידה (ROLL_T, בלתי פגיע) - פעם ב-ROLL_CD.
#    "THEY LEARN YOUR RHYTHM": כל גלגול מקצר את ה-ROLL_CD של כל חיילי הסער (main meta "storm_seen") - עד ROLL_MIN.
#    אתה מתחבא מאחורי מחסה? "FLUSH HIM OUT!" - רימון בקשת שנוחת מאחורי המחסה (GREN_CD).
#  לשנות: SMG_N, SMG_CD, ROLL_T, ROLL_CD0, ROLL_MIN, GREN_CD, GREN_R.
# ============================================================

const E := preload("res://enemies/empire_kit.gd")
const SB := preload("res://enemies/stationary_boss.gd")
const MO := preload("res://enemies/types/mortarman.gd")

const SOUNDS := {
	"st_roll": [["N", 0, 0, 0.0, 0.25, 0.0, 12.0, 0.3, 0.4, 0, 0.7]],
	"st_pin": [["S", 2200, 2000, 0.0, 0.05, 0.0, 40.0, 0.15, 1.0, 0], ["C", 0, 0, 0.06, 0.03, 0.0, 60.0, 0.2, 1.0, 0]],
}

const SMG_N := 5
const SMG_CD := 2.0
const SMG_R := 420.0
const ROLL_T := 0.4
const ROLL_V := 360.0
const ROLL_CD0 := 3.0
const ROLL_MIN := 1.2
const GREN_CD := 6.0
const GREN_R := 520.0

var rolls := 0               # לבדיקות
var grenades := 0
var bursts := 0
var _roll := 0.0
var _rcd := 0.5
var _gcd := 2.0
var _cd := 1.0
var _left := 0
var _rate := 0.0


func stats() -> Dictionary:
	return {"name": "STORMTROOPER", "hp": 42, "walk": 50.0, "chase": 104.0, "damage": 1, "bite_delay": 0.7, "scale": 1.05, "width": 1.0,
		"duck": 0.2, "cover": 0.6, "skin": Color("7a8670"), "shirt": Color("2a2624"), "pants": Color("2a2a2a"), "shoe": Color("101010"), "points": 640}


func setup() -> void:
	z.add_to_group("empire")


func brain_overrides() -> Dictionary:
	return {"aggression": 0.95}


func can_bite() -> bool:
	return _roll <= 0.0


static func roll_cd(main: Node) -> float:
	var n := int(main.get_meta("storm_seen")) if main.has_meta("storm_seen") else 0
	return maxf(ROLL_MIN, ROLL_CD0 - 0.3 * float(n))


func on_shot(from: Vector2, dir: Vector2) -> void:
	if z == null or z.dead or _roll > 0.0 or _rcd > 0.0:
		return
	var c: Vector2 = z.global_position + Vector2(0, -28.0 * z.sc)
	var rel := c - from
	var along := rel.dot(dir)
	if along < 0.0 or along > 1000.0 or absf(rel.cross(dir)) > 46.0:
		return
	var main: Node = z.get_parent()
	_roll = ROLL_T
	_rcd = roll_cd(main)
	rolls += 1
	main.set_meta("storm_seen", (int(main.get_meta("storm_seen")) if main.has_meta("storm_seen") else 0) + 1)
	var side := signf(rel.x) if absf(rel.x) > 1.0 else 1.0   # מתגלגל קדימה אליך (לסגור מרחק) או הצידה
	z.velocity.x = -side * ROLL_V * (1.0 if randf() < 0.6 else -1.0)
	Sfx.play("st_roll", z.global_position, -4.0, 0.1, 2)


func on_damage(_amount: int, _hit_pos: Vector2, _dir: Vector2, src: Dictionary) -> bool:
	if _roll > 0.0 and not src.has("blast"):
		return false   # מתגלגל - הכדור מפספס
	return true


func physics(pl: Node, delta: float) -> bool:
	_roll -= delta
	_rcd -= delta
	_gcd -= delta
	_cd -= delta
	_rate -= delta
	if z.dead:
		return false
	if _roll > 0.0:
		z.velocity.x = move_toward(z.velocity.x, 0.0, 300.0 * delta)
		if not z.is_on_floor():
			z.velocity.y += z.gravity * delta
		z.move_and_slide()
		return true
	if pl == null or pl.dead or z.goal_x < INF:
		return false
	var d: Vector2 = pl.global_position - z.global_position
	if _left > 0:
		if _rate <= 0.0:
			_left -= 1
			_rate = 0.08
			var m: Vector2 = z.global_position + Vector2(z._dir * 16.0, -30.0) * z.sc
			E.fire(z, m, pl.global_position + Vector2(0, E.squad_aim_y(z.get_parent())) + Vector2(0, randf_range(-8, 8)), 640.0)
			Sfx.play("pa_smg", m, -5.0, 0.1, 4)
		z.velocity.x = move_toward(z.velocity.x, 0.0, 800.0 * delta)
		if not z.is_on_floor():
			z.velocity.y += z.gravity * delta
		z.move_and_slide()
		return true
	# רימון: אתה מתחבא מאחורי מחסה
	if _gcd <= 0.0 and absf(d.x) < GREN_R and absf(d.y) < 120.0 and pl._crouching and MO.cover_near(z.get_tree(), pl) != null:
		_gcd = GREN_CD
		grenades += 1
		_throw(pl)
		return false
	if _cd <= 0.0 and absf(d.x) < SMG_R and absf(d.y) < 100.0 and E.clear_shot(z, z.global_position + Vector2(0, -30), pl.global_position + Vector2(0, -24)):
		_cd = SMG_CD
		_left = SMG_N
		bursts += 1
		z._dir = signf(d.x)
	return false


func _throw(pl: Node) -> void:
	var from: Vector2 = z.global_position + Vector2(z._dir * 6.0, -44.0) * z.sc
	var tgt: Vector2 = pl.global_position
	var flight := 1.0
	var l = SB.Lob.new()
	var tr := MO.MTracker.new()
	tr.z = z
	l.owner_t = tr
	l.damage = 2
	l.kind = "rock"
	l.r = 4.0
	l.blast_r = 70.0
	l.velocity = Vector2((tgt.x - from.x) / flight, (tgt.y - from.y) / flight - 0.5 * l.gravity * flight)
	z.get_parent().add_child(l)
	l.global_position = from
	Sfx.play("st_pin", from, -2.0, 0.1, 2)
	z._popup("FLUSH HIM OUT!", Color("ff6040"), 13, -85.0)


# ============================================================
#  ציור: מסכת גז עם קסדה, מעיל עור שחור ארוך, חגורת רימונים, תת-מקלע. בגלגול - גוף מכווץ מסתובב
# ============================================================
func draw() -> bool:
	if _roll > 0.0 and not z.dead:
		begin_draw()
		var a := (1.0 - _roll / ROLL_T) * TAU
		z.draw_colored_polygon(Art.ellipse(Vector2(0, -14), 13.0, 11.0, a, 12), col(Color("2a2624")))
		z.draw_circle(Vector2(0, -14) + Vector2.from_angle(a) * 8.0, 5.0, col(Color("3a3a3a")))
		end_draw()
		return true
	begin_draw()
	var o: Dictionary = E.soldier(self, z, Vector2(12, 1), "gasmask", Color("2a2624"))
	var hip: Vector2 = o.hip
	var hf: Vector2 = o.hf
	z.draw_colored_polygon(PackedVector2Array([hip + Vector2(-8, 4), hip + Vector2(8, 4), hip + Vector2(10, 14), hip + Vector2(-10, 14)]), col(Color("2a2624")))   # שולי המעיל
	for q in 3:   # רימונים על החגורה
		z.draw_circle(hip + Vector2(-6.0 + float(q) * 5.0, 1), 1.8, col(Color("3a4a2a")))
	z.draw_rect(Rect2(hf + Vector2(-2, -2), Vector2(11, 3)), col(Color("1a1a1a")))
	z.draw_rect(Rect2(hf + Vector2(2, 0), Vector2(2, 5)), col(Color("1a1a1a")))
	end_draw()
	return true
