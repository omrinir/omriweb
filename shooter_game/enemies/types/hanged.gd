extends "res://enemies/zombie_type.gd"
# ============================================================
#  HANGED (שלב 20, "GREEN HELL") - זומבי תלוי בחבל תלייה מענף עץ, מתנדנד באוויר, עם אקדח.
#  הוא לא הולך ולא נושך - רק תלוי ויורה למטה.
#  מחזור:
#    IDLE  - מתנדנד לאט (חורק). השחקן בטווח (RANGE) -> AIM.
#    AIM   - מרים את האקדח, קו כוונה אדום דק + ניצוץ על הקנה (AIM_T) = אזהרה.
#    FIRE  - SHOTS יריות. חכם: מכוון לאן שאתה *הולך להיות* (LEAD - לפי המהירות שלך),
#            אז מי שממשיך ישר נפגע - משנים כיוון / עוצרים / קופצים.
#    COOL  - הפסקה (CD).
#  פגיעה = הוא מתנדנד מהמכה (וקשה לו לכוון). מת = החבל נקרע והגופה נופלת, נשאר קצה חבל על הענף.
#  הענף עצמו (Bough) נוצר ע"י הזומבי ונשאר בעולם (סטטי - זול).
#  לשנות: HANG, ROPE, RANGE, AIM_T, SHOTS, GAP, LEAD, CD.
# ============================================================

const ZScript := preload("res://zombie.gd")

const SOUNDS := {
	"hg_cock": [["C", 0, 0, 0.0, 0.04, 0.0, 30.0, 0.4, 1.0, 0], ["C", 0, 0, 0.09, 0.05, 0.0, 30.0, 0.5, 1.0, 0]],
	"hg_creak": {"drive": 1.3, "layers": [["V", 140, 110, 0.0, 0.6, 0.15, 3.0, 0.25, 1.0, 0.04, 0, [500, 1400, 12]]]},
}

const HANG := 125.0          # כמה מעל הקרקע כפות הרגליים
const ROPE := 70.0           # אורך החבל מהענף לצוואר
const NECK := 46.0           # מכפות הרגליים לצוואר
const RANGE := 640.0
const AIM_T := 0.65
const SHOTS := 3
const GAP := 0.3
const LEAD := 0.8            # כמה הוא מקדים אותך (0 = יורה לאן שאתה עכשיו)
const SHOT_V := 820.0
const CD := Vector2(1.5, 2.4)

enum { IDLE, AIM, FIRE, COOL }
var state := IDLE
var shots := 0               # לבדיקות
var anchor := Vector2.ZERO
var bough: Node2D = null
var _built := false
var _th := 0.0               # זווית הנדנוד
var _w := 0.0                # מהירות זוויתית
var _st := 0.0
var _cd := 1.0
var _left := 0
var _aim := PI * 0.5         # זווית האקדח בעולם
var _flash := 0.0
var _creak_t := 2.0


func stats() -> Dictionary:
	return {"name": "HANGED", "hp": 24, "walk": 0.0, "chase": 0.0, "damage": 1, "bite_delay": 9.0, "scale": 1.1, "width": 0.9,
		"duck": 0.0, "cover": 0.0, "skin": Color("8c8ea6"), "shirt": Color("b4ac98"), "pants": Color("3a3228"), "shoe": Color("1e1a16"), "points": 360}


func can_bite() -> bool:
	return false


func can_groan() -> bool:
	return false


func setup() -> void:
	z._noticed = true
	z._close_yell = true
	z.cover_chance = 0.0
	z.collision_mask = 0     # תלוי באוויר - לא מתנגש בכלום


func _rot() -> float:
	return -_th


# נקודה בציור (מקומית, לפני היפוך) -> עולם
func _to_world(lp: Vector2) -> Vector2:
	var s := Vector2(z._dir * z.wf * z.sc, z.sc)
	return z.global_position + Vector2(lp.x * s.x, lp.y * s.y + NECK * z.sc).rotated(_rot()) + Vector2(0.0, -NECK * z.sc)


func physics(pl: Node, delta: float) -> bool:
	if z.dead:
		return false
	if not _built:
		_built = true
		anchor = z.global_position - Vector2(0.0, HANG + NECK * z.sc + ROPE)
		_th = randf_range(-0.15, 0.15)
		bough = Bough.new()
		bough.position = anchor
		bough.side = -1.0 if randf() < 0.5 else 1.0
		z.get_parent().add_child(bough)
	if pl != null and absf(pl.global_position.x - z.global_position.x) > 1500.0:   # רחוק: ישן (חוסך ביצועים)
		return true
	_cd -= delta
	_st -= delta
	_flash -= delta
	# מטוטלת: חוזר למרכז, נדנוד קל מהרוח
	var g := 9.0
	_w += (-g * sin(_th) + sin(z._time * 1.1) * 0.25) * delta
	_w *= 1.0 - 0.6 * delta
	_th = clampf(_th + _w * delta, -0.7, 0.7)
	var ropev := Vector2(sin(_th), cos(_th))
	z.global_position = anchor + ropev * (ROPE + NECK * z.sc)
	z.velocity = Vector2.ZERO
	_creak_t -= delta
	if _creak_t <= 0.0:
		_creak_t = randf_range(2.5, 4.5)
		if Art.on_screen(z, z.global_position, 0.0):
			Sfx.play("hg_creak", z.global_position, -10.0, 0.15, 2)
	var has_pl: bool = pl != null and not pl.dead
	if has_pl:
		z._dir = signf(pl.global_position.x - z.global_position.x) if absf(pl.global_position.x - z.global_position.x) > 4.0 else z._dir
	match state:
		IDLE:
			_aim = lerp_angle(_aim, PI * 0.5, delta * 3.0)
			if _cd <= 0.0 and has_pl and absf(pl.global_position.x - z.global_position.x) < RANGE and Art.on_screen(z, z.global_position, 40.0):
				state = AIM
				_st = AIM_T
				Sfx.play("hg_cock", z.global_position, -2.0, 0.08, 2)
		AIM:
			if has_pl:
				_aim = lerp_angle(_aim, _aim_at(pl), delta * 7.0)
			if _st <= 0.0:
				state = FIRE
				_left = SHOTS
				_st = 0.0
		FIRE:
			if has_pl:
				_aim = lerp_angle(_aim, _aim_at(pl), delta * 10.0)
			if _st <= 0.0 and _left > 0:
				_st = GAP
				_fire()
			if _left <= 0 and _st <= 0.0:
				state = COOL
				_cd = randf_range(CD.x, CD.y)
		COOL:
			_aim = lerp_angle(_aim, PI * 0.5, delta * 2.0)
			if _cd <= 0.0:
				state = IDLE
	return true


# מקדים את השחקן לפי המהירות שלו
func _aim_at(pl: Node) -> float:
	var m := _muzzle()
	var tgt: Vector2 = pl.global_position + Vector2(0.0, -30.0)
	var tt := m.distance_to(tgt) / SHOT_V
	var v: Vector2 = pl.velocity if pl.get("velocity") != null else Vector2.ZERO
	tgt += Vector2(clampf(v.x, -420.0, 420.0), clampf(v.y, -300.0, 300.0) * 0.4) * tt * LEAD
	return (tgt - m).angle()


func _gun_local() -> Vector2:   # כיוון האקדח בקואורדינטות הציור
	var w := Vector2.from_angle(_aim).rotated(-_rot())
	return Vector2(w.x * z._dir, w.y).normalized()


func _shoulder() -> Vector2:
	return Vector2(2.0, -37.0)


func _muzzle() -> Vector2:
	return _to_world(_shoulder() + _gun_local() * 21.0)


func _fire() -> void:
	shots += 1
	_left -= 1
	var b = ZScript.EnemyShot.new()
	z.get_parent().add_child(b)
	var m := _muzzle()
	b.global_position = m
	var wobble := clampf(absf(_w) * 0.12, 0.0, 0.2)   # מתנדנד חזק = מפספס יותר
	b.velocity = Vector2.from_angle(_aim + randf_range(-0.03 - wobble, 0.03 + wobble)) * SHOT_V
	b.life = 1.2
	_flash = 0.05
	_w -= Vector2.from_angle(_aim).x * 0.35   # רתע קטן מנדנד אותו
	Sfx.play("pistol", m, -4.0, 0.1, 3)


func on_damage(_amount: int, _hit_pos: Vector2, dir: Vector2, _src: Dictionary) -> bool:
	_w += signf(dir.x) * 1.4 / z.sc
	return true


func on_death() -> void:
	z.collision_mask = 1 | 16   # החבל נקרע: הגופה נופלת לקרקע
	if bough != null and is_instance_valid(bough):
		bough.cut = true
		bough.swing = _th
		bough.queue_redraw()


# ============================================================
#  ציור: חבל מהענף לצוואר, גוף רפוי, ראש שמוט הצידה, אקדח ביד אחת
# ============================================================
func draw() -> bool:
	if z.dead:
		begin_draw()
	else:
		var neck: Vector2 = _to_world(Vector2(-1.0, -44.0)) - z.global_position
		var top: Vector2 = anchor - z.global_position
		z.draw_line(top, neck, Color("3a2e1e"), 3.0, true)
		z.draw_line(top, neck, Color("8a7450"), 1.6, true)
		for i in 4:   # סיבי החבל
			var q: Vector2 = top.lerp(neck, 0.2 + 0.2 * float(i))
			z.draw_line(q + Vector2(-1.2, -1.0), q + Vector2(1.2, 1.0), Color("5a4a30"), 1.0)
		var s := Vector2(z._dir * z.wf * z.sc, z.sc)
		z.draw_set_transform_matrix(Transform2D(_rot(), Vector2(0.0, -NECK * z.sc)) * Transform2D(0.0, s, 0.0, Vector2(0.0, NECK * z.sc)))
	var sk := col(z.skin)
	var skd := col(Art.shade(z.skin, 0.25))
	var shirt := col(z.shirt)
	var dang := sin(z._time * 1.7) * 1.5
	var hip := Vector2(0.0, -22.0)
	var sh := Vector2(0.0, -37.0)
	var head := Vector2(4.0, -45.0)
	# רגליים תלויות, כפות מכוונות למטה (אחת יחפה)
	z._leg(hip + Vector2(-2, 0), Vector2(-3.0 + dang * 0.5, 0.0), col(Art.shade(z.pants, 0.25)), skd, col(Color(0, 0, 0, 0)))
	z._leg(hip + Vector2(2, 0), Vector2(2.5 - dang * 0.5, -1.0), col(z.pants), sk, col(z.shoe))
	# יד אחורית רפויה
	Art.limb(z, PackedVector2Array([sh + Vector2(-3, 1), sh + Vector2(-4, 8), sh + Vector2(-4.0 + dang * 0.3, 15.0)]), 3.0, skd)
	# גופייה קרועה ומוכתמת
	Art.fill_shaded(z, PackedVector2Array([sh + Vector2(-6, -1), sh + Vector2(6, -1), hip + Vector2(5, 2), hip + Vector2(-5, 2)]), shirt, 0.15, 0.45)
	z.draw_colored_polygon(PackedVector2Array([sh + Vector2(-2, 5), sh + Vector2(3, 7), sh + Vector2(1, 12), sh + Vector2(-3, 10)]), Color(0.4, 0.15, 0.1, 0.6))
	z.draw_line(hip + Vector2(-5, 2), hip + Vector2(-2, -3), Color(0.2, 0.18, 0.15), 1.0)
	# ראש שמוט, לולאת החבל סביב הצוואר עם קשר מאחור
	Art.oval_shaded(z, head, 5.6, 6.0, sk, 0.35)
	z.draw_arc(Vector2(0.0, -40.5), 4.0, -0.3, PI + 0.3, 10, Color("6a5636"), 2.2)
	Art.oval(z, Vector2(-3.5, -44.0), 2.2, 2.6, col(Color("7a6442")), 0.0, Color("3a2e1e"), 1.0)
	if not z.dead:
		for e in [Vector2(2.5, -46.0), Vector2(6.0, -45.5)]:
			z.draw_circle(e, 1.1, Color("e8e0d0"))
			z.draw_circle(e + Vector2(0.3, 0.2), 0.55, Color(0.9, 0.1, 0.05))
	z.draw_colored_polygon(PackedVector2Array([Vector2(5, -41), Vector2(8, -40.5), Vector2(7.5, -37.5), Vector2(5.5, -38.5)]), col(Color("6a3a5a")))   # לשון
	z.draw_line(Vector2(0, -50.5), Vector2(7, -51), col(Color("2a2420")), 1.8)   # שיער דליל
	# יד עם אקדח
	var la := _gun_local() if not z.dead else Vector2(0.2, 1.0).normalized()
	var kick := 1.5 if _flash > 0.0 else 0.0
	var hand := _shoulder() + la * (12.0 - kick)
	var tr := Transform2D(la.angle(), hand)
	Art.fill(z, tr * PackedVector2Array([Vector2(-2, -2.2), Vector2(8, -2.2), Vector2(8, 1.2), Vector2(-2, 1.2)]), col(Color("2a2c30")), Art.OUTLINE, 1.0)
	Art.fill(z, tr * PackedVector2Array([Vector2(-1, 1.2), Vector2(2, 1.2), Vector2(1, 6), Vector2(-2, 6)]), col(Color("3a2a1e")), Art.OUTLINE, 0.8)
	Art.limb(z, PackedVector2Array([_shoulder(), _shoulder().lerp(hand, 0.5) + Vector2(0, 1), hand]), 3.1, sk)
	if state == AIM and not z.dead:
		var m := tr * Vector2(9, -0.5)
		z.draw_line(m, m + la * 90.0, Color(1.0, 0.15, 0.1, 0.35), 1.0)   # קו כוונה דק
		if int(z._time * 14.0) % 2 == 0:
			Art.glow(z, m, 5.0, Color(1.0, 0.2, 0.1, 0.8))
	if _flash > 0.0:
		var m2 := tr * Vector2(10, -0.5)
		Art.glow(z, m2, 7.0, Color(1.0, 0.8, 0.3, 0.9))
		z.draw_colored_polygon(PackedVector2Array([m2 + la.orthogonal() * 2.5, m2 + la * 8.0, m2 - la.orthogonal() * 2.5]), Color(1.0, 0.92, 0.55))
	end_draw()
	return true


# ---- הענף שממנו הוא תלוי (סטטי, מצויר פעם אחת; אחרי המוות - קצה חבל קרוע) ----
class Bough extends Node2D:
	var side := 1.0
	var cut := false
	var swing := 0.0

	func _ready() -> void:
		z_index = 2

	func _draw() -> void:
		var pts := PackedVector2Array()
		for p in [Vector2(-300, -420), Vector2(-190, -200), Vector2(-80, -40), Vector2(0, -4), Vector2(70, 2), Vector2(120, -6)]:
			pts.append(Vector2(p.x * side, p.y))
		draw_polyline(pts, Color("1e1810"), 20.0, true)
		draw_polyline(pts, Color("4a3a28"), 15.0, true)
		draw_polyline(pts.slice(2), Color("5e4a32"), 5.0, true)
		draw_line(Vector2(70 * side, 2), Vector2(130 * side, -10), Color("4a3a28"), 6.0, true)
		var leaves := [Color("1d3a20"), Color("27482a"), Color("335a30")]
		for i in 9:   # עלים בקצה
			var base := Vector2((100.0 + float(i % 3) * 14.0) * side, -8.0 + float(i / 3) * 4.0)
			var a := -PI * 0.5 + (float(i) - 4.0) * 0.38
			var d := Vector2.from_angle(a)
			var n := d.orthogonal() * 5.0
			draw_colored_polygon(PackedVector2Array([base, base + d * 10.0 + n, base + d * 20.0, base + d * 10.0 - n]), leaves[i % 3])
		# החבל כרוך סביב הענף
		for i in 3:
			draw_line(Vector2(-5.0 + float(i) * 4.0, -8.0), Vector2(-3.0 + float(i) * 4.0, 7.0), Color("8a7450"), 2.0)
		if cut:   # קצה חבל קרוע תלוי
			var e := Vector2(sin(swing) * 26.0, 26.0)
			draw_line(Vector2(0, 6), e, Color("3a2e1e"), 3.0, true)
			draw_line(Vector2(0, 6), e, Color("8a7450"), 1.6, true)
			for k in 3:
				draw_line(e, e + Vector2(-3.0 + float(k) * 3.0, 5.0), Color("8a7450"), 1.0)
