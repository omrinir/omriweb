extends "res://enemies/zombie_type.gd"
# ============================================================
#  LIVEWIRE (שלב 10, צפון-מזרח) - טכנאי חוות רוח מת: קסדה צהובה סדוקה, אפוד כתום זוהר
#    עם פסים מחזירי אור, סרבל כחול, כפפות גומי ארוכות, לסת שנפתחה עם אלקטרודות.
#    כבל חי עבה מחובר לשקע בגב שלו - מעמוד חשמל עם שנאי שעומד לידו.
#  הכבל:
#    * הוא "רצועה": הזומבי לא יכול להתרחק מהעמוד יותר מ-LEASH (נמתח ונעצר).
#    * הקטע שעל הריצפה חי - דורכים עליו = מכת חשמל. צריך לקפוץ מעליו כדי להגיע אליו.
#    * פולסים כחולים זורמים בכבל אל הזומבי כל הזמן, ומואצים כשהוא טוען = אזהרה.
#    * הזומבי מת -> הכבל מת (אפור, לא פוגע).
#  התקפה: טוען (CHARGE_T: הפה זוהר, פצפוץ, הכבל מתמלא) -> פריקת חשמל זיגזג מהפה
#    אל המקום שבו אתה נמצא ברגע הירייה (אפשר לקפוץ / להתגלגל / להתכופף מאחורי מחסה).
#  שומר מרחק (KEEP_NEAR..KEEP_FAR), לא תופס "תור התקפה".
#  צלילים: "lw_charge" (טעינה עולה), "lw_fire" (פריקה), "lw_hit" (פגיעה). + "zap" הקיים.
#  לשנות: LEASH, SHOT_CD, CHARGE_T, BOLT_SPEED.
# ============================================================

const Hz := preload("res://environment/s10_hazards.gd")
const Brain := preload("res://ai/zombie_brain.gd")

const SOUNDS := {
	"lw_charge": [["S", 200, 1400, 0.0, 0.75, 0.05, 0.0, 0.3, 1.0, 0.15], ["C", 0, 0, 0.0, 0.75, 0.05, 0.0, 0.35, 0.8, 0], ["Q", 100, 400, 0.0, 0.75, 0.05, 0.0, 0.12, 0.4, 0]],
	"lw_fire": [["N", 0, 0, 0.0, 0.3, 0.0, 10.0, 0.7, 0.9, 0], ["Q", 1600, 300, 0.0, 0.25, 0.0, 10.0, 0.3, 0.6, 0], ["C", 0, 0, 0.0, 0.3, 0.0, 8.0, 0.5, 1.0, 0]],
	"lw_hit": [["C", 0, 0, 0.0, 0.35, 0.0, 8.0, 0.7, 1.0, 0], ["Q", 120, 80, 0.0, 0.3, 0.0, 8.0, 0.35, 0.5, 0], ["N", 0, 0, 0.0, 0.2, 0.0, 14.0, 0.4, 0.7, 0]],
}

const LEASH := 380.0
const KEEP_NEAR := 200.0
const KEEP_FAR := 380.0
const SHOT_CD := Vector2(2.6, 3.6)
const CHARGE_T := 0.75
const RECOVER_T := 0.4
const BOLT_SPEED := 500.0

enum { MOVE, CHARGE, RECOVER }
var state := MOVE
var shots := 0             # לבדיקות
var cable: Node2D = null
var _st := 0.0
var _cd := 1.5
var _strain := 0.0         # נמתח על הכבל (ציור)


func stats() -> Dictionary:
	return {"name": "LIVEWIRE", "hp": 36, "walk": 38.0, "chase": 72.0, "damage": 1, "bite_delay": 1.0, "scale": 1.0, "width": 1.05,
		"duck": 0.15, "cover": 0.3, "skin": Color("8a9488"), "shirt": Color("e86a1a"), "pants": Color("2a3a5a"), "shoe": Color("1a1a1a"), "points": 380}


func brain_overrides() -> Dictionary:
	return {"keep_range": 300.0, "aggression": -0.3}


func use_brain_movement() -> bool:
	return false


func setup() -> void:
	cable = Hz.LiveCable.new()
	cable.owner_z = z
	var side := -1.0 if randf() < 0.5 else 1.0
	cable.position = z.position + Vector2(side * randf_range(50.0, 90.0), 0.0)
	z.get_parent().add_child.call_deferred(cable)
	_cd = randf_range(1.0, 2.0)


func _anchor_x() -> float:
	return cable.global_position.x if cable != null and is_instance_valid(cable) and cable.is_inside_tree() else z.global_position.x


func logic(pl: Node, d: Vector2, delta: float, speed: float) -> float:
	_cd -= delta
	_strain = move_toward(_strain, 0.0, delta * 2.0)
	if z.brain != null and z.brain.role == Brain.ATTACK:   # לא מחזיק "תור התקפה"
		var dr := director()
		if dr != null:
			dr.release_slot(z)
		z.brain.role = Brain.HOLD
	var face: float = signf(d.x) if d.x != 0.0 else z._dir
	if cable != null and is_instance_valid(cable):
		cable.charge = clampf(1.0 - _st / CHARGE_T, 0.0, 1.0) if state == CHARGE else move_toward(float(cable.charge), 0.0, delta * 3.0)
	if state == CHARGE:
		z._dir = face
		_st -= delta
		if _st <= 0.0:
			_fire(pl)
			state = RECOVER
			_st = RECOVER_T
		return 0.0
	if state == RECOVER:
		_st -= delta
		if _st <= 0.0:
			state = MOVE
		return 0.0
	var dist := absf(d.x)
	var sees: bool = z.brain == null or z.brain.sees
	if _cd <= 0.0 and sees and dist < 620.0 and absf(d.y) < 200.0 and not pl.dead:
		state = CHARGE
		_st = CHARGE_T
		_cd = randf_range(SHOT_CD.x, SHOT_CD.y)
		z._dir = face
		Sfx.play("lw_charge", z.global_position, -2.0, 0.08, 3)
		return 0.0
	var want := 0.0
	if dist < KEEP_NEAR:
		want = -face
	elif dist > KEEP_FAR:
		want = face
	z._dir = face if want == 0.0 else want
	if want == 0.0:
		z._dir = face
		return 0.0
	# הרצועה: לא מתרחק מהעמוד יותר מ-LEASH
	var ax := _anchor_x()
	var nx: float = z.global_position.x + want * 20.0
	if absf(nx - ax) > LEASH and absf(nx - ax) > absf(z.global_position.x - ax):
		_strain = 1.0
		z._dir = face
		return 0.0
	return speed * (1.0 if want == face else 0.9)


func _mouth() -> Vector2:
	return z.global_position + Vector2(z._dir * 9.0 * z.wf * z.sc, -45.0 * z.sc)


func _fire(pl: Node) -> void:
	if pl == null or pl.dead:
		return
	var m := _mouth()
	var aim: Vector2 = pl.global_position + Vector2(0.0, -30.0)
	var b := Hz.ShockBolt.new()
	b.velocity = (aim - m).normalized() * BOLT_SPEED
	z.get_parent().add_child(b)
	b.global_position = m
	shots += 1
	Sfx.play("lw_fire", m, 0.0, 0.1, 3)
	Particles.burst(z.get_parent(), m, "spark", b.velocity.normalized(), 6)


func on_bite(pl: Node) -> void:
	Sfx.play("lw_hit", pl.global_position, -4.0, 0.1, 3)
	Particles.burst(z.get_parent(), pl.global_position + Vector2(0, -30), "spark", Vector2.UP, 6)


func on_death() -> void:
	Particles.burst(z.get_parent(), z.global_position + Vector2(0, -40), "spark", Vector2.UP, 14)
	Sfx.play("lw_hit", z.global_position, 0.0, 0.1, 3)


# ============================================================
#  ציור
# ============================================================
func draw() -> bool:
	begin_draw()
	var sk := col(z.skin)
	var vest := col(z.shirt)
	var suit := col(Color("2a3a5a"))
	var p: float = z._walk_phase
	var f: Array = feet(4.5, 2.0)
	var t: float = z._time
	var lean := -3.0 * _strain   # נמשך אחורה ע"י הכבל
	var hip := Vector2(0.0, -21.0 + absf(sin(p)) * 1.0)
	var sh := Vector2(2.0 + lean, -37.0)
	var head := sh + Vector2(5.0, -7.0)
	var ck: float = clampf(1.0 - _st / CHARGE_T, 0.0, 1.0) if state == CHARGE else 0.0
	z._leg(hip + Vector2(-1.5, 0), f[1], col(Art.shade(z.pants, 0.25)), col(Art.shade(z.skin, 0.2)), col(z.shoe))
	z._leg(hip + Vector2(1.5, 0), f[0], col(z.pants), sk, col(z.shoe))
	z._arm(sh + Vector2(-3, 2), sh + Vector2(-2.0 - sin(p) * 3.0, 15.0), col(Color("1a1a1a")), Art.shade(suit, 0.3))
	# סרבל + אפוד כתום עם פסים מחזירי אור
	var body := PackedVector2Array([sh + Vector2(-7, -2), sh + Vector2(7, -1), hip + Vector2(7, -1), hip + Vector2(5, 3), hip + Vector2(-6, 3), sh + Vector2(-8, 5)])
	Art.fill_shaded(z, body, suit, 0.15, 0.35)
	Art.fill_shaded(z, PackedVector2Array([sh + Vector2(-7, -1), sh + Vector2(6, 0), hip + Vector2(6, -4), hip + Vector2(-6, -3)]), vest, 0.2, 0.3)
	for y in [sh.y + 8.0, sh.y + 12.0]:
		z.draw_line(Vector2(sh.x - 7.0, y), Vector2(sh.x + 6.0, y - 0.5), col(Color("e8e8d0")), 1.6)
	z.draw_line(hip + Vector2(-7, -1), hip + Vector2(7, -2), col(Color("2a2a20")), 2.6, true)   # חגורת כלים
	z.draw_rect(Rect2(hip.x - 6.0, hip.y - 2.0, 3.0, 5.0), col(Color("4a3a20")))
	# שקע בגב (כאן הכבל מתחבר)
	var sock := sh + Vector2(-9.0, 4.0)
	Art.disc(z, sock, 3.2, col(Color("3a3a40")))
	if not z.dead:
		Art.glow(z, sock, 6.0 + ck * 6.0, Color(0.4, 0.75, 1.0, 0.5 + ck * 0.4))
	# ראש: לסת פתוחה עם אלקטרודות
	Art.oval_shaded(z, head, 6.0, 6.4, sk, 0.1)
	var jaw := 2.0 + ck * 4.0 + (2.0 if state == RECOVER else 0.0)
	Art.fill(z, PackedVector2Array([head + Vector2(1.5, 2), head + Vector2(7, 1.5), head + Vector2(6.5, 4 + jaw), head + Vector2(2, 4.5 + jaw * 0.6)]), col(Color("101418")), Art.OUTLINE, 0.8)
	z.draw_line(head + Vector2(2.5, 2), head + Vector2(2.5, -1), col(Color("b0b0b8")), 1.0)
	z.draw_line(head + Vector2(6.0, 2), head + Vector2(6.5, -0.5), col(Color("b0b0b8")), 1.0)
	if not z.dead and (ck > 0.0 or state == RECOVER or fmod(t, 1.3) < 0.1):
		var mc := head + Vector2(5.0, 3.5 + jaw * 0.4)
		Art.glow(z, mc, 5.0 + ck * 10.0, Color(0.45, 0.8, 1.0, 0.45 + ck * 0.5))
		for i in int(1.0 + ck * 4.0):
			z.draw_line(mc, mc + Vector2(randf_range(-2, 8), randf_range(-6, 6)), Color(0.85, 0.95, 1.0), 1.0)
	var eye := head + Vector2(3.0, -1.5)
	z.draw_circle(eye, 1.3, Color(0.6, 0.9, 1.0) if not z.dead else Color("2a2a2a"))
	# קסדה צהובה סדוקה
	var helm := PackedVector2Array()
	for i in 11:
		var a := lerpf(PI, TAU, float(i) / 10.0)
		helm.append(head + Vector2(cos(a) * 7.5, -2.0 + sin(a) * 7.0))
	Art.fill_shaded(z, helm, col(Color("e8c020")), 0.25, 0.3)
	z.draw_line(head + Vector2(-9, -2), head + Vector2(10, -2.5), col(Color("c8a010")), 2.0)
	z.draw_polyline(PackedVector2Array([head + Vector2(-2, -8.5), head + Vector2(0, -6), head + Vector2(-1, -4)]), Color("3a3010"), 0.8)
	# יד קדמית בכפפת גומי - בטעינה מורמת אל הפה, עם קשת חשמל בין האצבעות
	var hand := sh + Vector2(11.0, 8.0 + sin(p) * 2.0)
	if ck > 0.0:
		hand = sh + Vector2(lerpf(11.0, 13.0, ck), lerpf(8.0, -2.0, ck))
	z._arm(sh + Vector2(2, 2), hand, col(Color("1a1a1a")), suit)
	if ck > 0.3 and not z.dead:
		z.draw_line(hand, hand + Vector2(randf_range(2, 6), randf_range(-5, 5)), Color(0.8, 0.95, 1.0), 1.0)
	end_draw()
	return true
