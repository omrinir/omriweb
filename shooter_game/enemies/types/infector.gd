extends "res://enemies/zombie_type.gd"
# ============================================================
#  INFECTOR (שלב 9) - יוצר אזורי הדבקה זמניים איפה שהשחקן נמצא / לאן שהוא הולך.
#  צללית: שפוף, עם שק מוגלה ענק ושקוף על הגב (סגול, עם גושים ירוקים זוהרים שפועמים),
#    חליפת מגן צהובה קרועה, גבעולי נבגים על הכתפיים שפולטים ענני אבק, לסת עם זיפים.
#  תנועה: שומר מרחק (280-440). מתקרבים אליו - נסוג. לא נכנס לקרב צמוד.
#  התקפה:
#    * זורק גוש הדבקה בקשת למקום שאליו השחקן הולך (מיקום + מהירות) -> שלולית הדבקה (6 שנ').
#    * כל כמה שניות: ענן רעיל על "צוואר בקבוק" שהשחקן מתקרב אליו (חור / סולם),
#      או ישר עליו אם הוא "מחנה" במקום אחד.
#    * מת -> השק מתפוצץ ומשאיר ענן קטן.
#  תקרה: לכל היותר 3 אזורים פעילים לכל אינפקטור (ו-8 בכל השלב, environment/s9_hazards.gd).
#  צלילים: "infect_gurgle" (בעבוע), "infect_spit" (שיגור רטוב), "infect_hiss" (שחרור גז), "infect_splat".
#  איך משנים: LOB_CD, CLOUD_CD, KEEP_NEAR / KEEP_FAR, MAX_OWN.
# ============================================================

const Hz := preload("res://environment/s9_hazards.gd")
const Brain := preload("res://ai/zombie_brain.gd")

const SOUNDS := {
	"infect_gurgle": [["B", 0.7, 0.7, 0.0, 0.7, 0.05, 2.5, 0.5, 1.0, 0, 0, 40.0], ["V", 85, 70, 0.0, 0.7, 0.05, 2.5, 0.35, 1.0, 0.04, 0, [380, 760, 14]]],
	"infect_spit": {"drive": 2.4, "layers": [["N", 0, 0, 0.0, 0.25, 0.01, 12.0, 0.6, 0.35, 0, 0.1], ["B", 1.1, 1.1, 0.0, 0.3, 0.0, 6.0, 0.45, 1.0, 0, 0, 90.0], ["S", 320, 140, 0.0, 0.15, 0.0, 18.0, 0.3, 1.0, 0]]},
	"infect_hiss": [["N", 0, 0, 0.0, 0.9, 0.08, 2.5, 0.45, 0.8, 0, 0.5], ["N", 0, 0, 0.0, 0.9, 0.1, 3.0, 0.2, 0.15, 0]],
	"infect_splat": [["N", 0, 0, 0.0, 0.35, 0.0, 9.0, 0.7, 0.3, 0], ["B", 0.9, 0.9, 0.0, 0.4, 0.0, 5.0, 0.4, 1.0, 0, 0, 120.0], ["S", 90, 45, 0.0, 0.2, 0.0, 12.0, 0.5, 1.0, 0]],
}

const LOB_CD := Vector2(3.0, 4.4)
const CLOUD_CD := Vector2(8.0, 11.0)
const KEEP_NEAR := 260.0
const KEEP_FAR := 440.0
const MAX_OWN := 3
const GRAV := 900.0

var zones_made := 0        # לבדיקות
var clouds_made := 0
var _lob_cd := 1.5
var _cloud_cd := 4.0
var _anim := 0.0
var _gurgle_t := 2.0
var _puffs := []


func stats() -> Dictionary:
	return {"name": "INFECTOR", "hp": 34, "walk": 42.0, "chase": 92.0, "damage": 1, "bite_delay": 1.0, "scale": 1.0, "width": 1.0,
		"duck": 0.2, "cover": 0.3, "skin": Color("8c9a6a"), "shirt": Color("b8a030"), "pants": Color("4a4428"), "shoe": Color("1e1c14"), "points": 340}


func brain_overrides() -> Dictionary:
	return {"keep_range": 340.0, "aggression": -0.4, "retreat_probability": 0.4, "hazard_awareness": 0.1}


func use_brain_movement() -> bool:
	return false


func logic(pl: Node, d: Vector2, delta: float, speed: float) -> float:
	_lob_cd -= delta
	_cloud_cd -= delta
	_anim -= delta
	_gurgle_t -= delta
	_tick_puffs(delta)
	if z.brain != null and z.brain.role == Brain.ATTACK:   # לא מחזיק "תור התקפה"
		var dr := director()
		if dr != null:
			dr.release_slot(z)
		z.brain.role = Brain.HOLD
	if _gurgle_t <= 0.0:
		_gurgle_t = randf_range(3.0, 5.5)
		Sfx.play("infect_gurgle", z.global_position, -6.0, 0.15, 2)
	var dist := absf(d.x)
	var face: float = signf(d.x) if d.x != 0.0 else z._dir
	var spd := 0.0
	z._dir = face
	if dist < KEEP_NEAR:
		z._dir = -face
		spd = speed * 1.05
	elif dist > KEEP_FAR:
		spd = speed * 0.8
	if _anim > 0.0:   # בזמן זריקה עומד במקום (ופונה לשחקן)
		z._dir = face
		return 0.0
	var sees: bool = z.brain != null and z.brain.sees
	if _lob_cd <= 0.0 and sees and dist < 560.0 and dist > 90.0 and absf(d.y) < 260.0:
		_lob_cd = randf_range(LOB_CD.x, LOB_CD.y)
		if _own_zones() < MAX_OWN:
			var lead: float = clampf(float(pl.velocity.x) * 0.75, -220.0, 220.0)
			lob(Vector2(pl.global_position.x + lead, pl.global_position.y), false)
			z._dir = face
			return 0.0
	if _cloud_cd <= 0.0 and z.brain != null and z.brain.tracking() and dist < 620.0:
		_cloud_cd = randf_range(CLOUD_CD.x, CLOUD_CD.y)
		if _own_zones() < MAX_OWN:
			lob(_cloud_target(pl), true)
			z._dir = face
			return 0.0
	return spd


# זורק גוש בקשת אל target. cloud = ענן רעיל במקום שלולית
func lob(target: Vector2, cloud: bool) -> void:
	var from: Vector2 = z.global_position + Vector2(z._dir * 8.0, -50.0 * z.sc)
	var t := clampf(absf(target.x - from.x) / 430.0, 0.55, 1.1)
	var v := Vector2((target.x - from.x) / t, (target.y - from.y - 0.5 * GRAV * t * t) / t)
	var g := Hz.InfectGlob.new()
	g.velocity = v
	g.gravity = GRAV
	g.cloud = cloud
	g.owner_z = z
	z.get_parent().add_child(g)
	g.global_position = from
	_anim = 0.55
	zones_made += 1
	if cloud:
		clouds_made += 1
		Sfx.play("infect_hiss", z.global_position, -2.0, 0.1, 2)
	Sfx.play("infect_spit", z.global_position, 0.0, 0.12, 3)
	for i in 4:
		_puffs.append([Vector2(-6.0 + randf_range(-4, 4), -48.0), Vector2(randf_range(-10, 10), randf_range(-30, -14)), 0.0])


# לאן לשלוח ענן: "מחנה" -> עליו. אחרת: צוואר בקבוק שהוא הולך אליו (חור, סולם), או לפניו
func _cloud_target(pl: Node) -> Vector2:
	var pp: Vector2 = pl.global_position
	if PlayerMemory.is_camping():
		return pp
	var vx: float = pl.velocity.x
	var heading: float = signf(vx) if absf(vx) > 40.0 else float(pl._face())
	var best := INF
	var tgt := pp + Vector2(heading * 120.0, 0.0)
	for c in z.get_tree().get_nodes_in_group("s9_choke"):
		var cp: Vector2 = (c as Node2D).global_position
		var ahead: float = (cp.x - pp.x) * heading
		if ahead > 30.0 and ahead < 360.0 and absf(cp.y - pp.y) < 60.0 and ahead < best:
			best = ahead
			tgt = cp
	return tgt


func _own_zones() -> int:
	var n := 0
	for zn in z.get_tree().get_nodes_in_group("s9_infection"):
		if zn.owner_z == z:
			n += 1
	return n


func on_death() -> void:
	Sfx.play("infect_splat", z.global_position, 2.0, 0.1, 2)
	Particles.burst(z.get_parent(), z.global_position + Vector2(0, -40), "smoke", Vector2.UP, 10)
	Hz.InfectionZone.spawn(z.get_parent(), z.global_position, 90.0, 3.0, true, null)


func _tick_puffs(delta: float) -> void:
	if randf() < delta * 2.0:   # הגבעולים פולטים נבגים כל הזמן
		_puffs.append([Vector2(randf_range(-9.0, -3.0), -46.0), Vector2(randf_range(-6, 6), randf_range(-18, -8)), 0.0])
	for q in _puffs:
		q[2] += delta
		q[0] += q[1] * delta
	_puffs = _puffs.filter(func(q): return q[2] < 1.2)


# ============================================================
#  ציור
# ============================================================
func draw() -> bool:
	begin_draw()
	var sk := col(z.skin)
	var suit := col(z.shirt)
	var suit_d := col(Art.shade(z.shirt, 0.35))
	var p: float = z._walk_phase
	var f: Array = feet(4.0, 2.0)
	var hip := Vector2(-1.0, -21.0 + absf(sin(p)) * 1.0)
	var sh := Vector2(5.0, -35.0)
	var head := sh + Vector2(6.0, -4.0)
	var throw_k: float = clampf(_anim / 0.55, 0.0, 1.0) if not z.dead else 0.0
	z._leg(hip + Vector2(-1.5, 0), f[1], col(Art.shade(z.pants, 0.25)), col(Art.shade(z.skin, 0.2)), col(z.shoe))
	z._leg(hip + Vector2(1.5, 0), f[0], col(z.pants), sk, col(z.shoe))
	# חליפת מגן צהובה קרועה
	var body := PackedVector2Array([sh + Vector2(-8, -3), sh + Vector2(6, -1), hip + Vector2(8, -1), hip + Vector2(6, 4), hip + Vector2(1, 2), hip + Vector2(-3, 5), hip + Vector2(-8, 2), sh + Vector2(-10, 6)])
	Art.fill_shaded(z, body, suit, 0.15, 0.4, Art.OUTLINE, 1.3)
	Art.fill(z, PackedVector2Array([sh + Vector2(0, 6), sh + Vector2(5, 5), sh + Vector2(4, 12), sh + Vector2(1, 10)]), Art.shade(sk, 0.1), Art.NONE)   # קרע
	z.draw_line(hip + Vector2(-8, -2), hip + Vector2(8, -3), suit_d, 2.0, true)
	for i in 3:   # פסים מחזירי אור
		var y := sh.y + 7.0 + float(i) * 4.0
		z.draw_line(Vector2(sh.x - 7.0 + float(i), y), Vector2(sh.x - 3.0 + float(i), y + 1.0), col(Color("d8d8c8")), 1.0)
	# שק המוגלה על הגב (פועם, מתכווץ בזריקה)
	var pulse := 1.0 + 0.06 * sin(z._time * 3.2) - 0.12 * throw_k
	var sac_c := sh + Vector2(-11.0, 4.0)
	Art.oval(z, sac_c, 10.5 * pulse, 13.0 * pulse, Color(0.5, 0.2, 0.6, 0.85) if not z.dead else Color(0.3, 0.15, 0.3), -0.25, Art.OUTLINE, 1.3)
	Art.oval(z, sac_c + Vector2(-2, -3), 6.0 * pulse, 7.0 * pulse, Color(0.65, 0.3, 0.75, 0.5), -0.25, Art.NONE)
	if not z.dead:
		for i in 4:   # גושים ירוקים זוהרים בתוך השק
			var bp := sac_c + Vector2(sin(z._time * 1.3 + float(i) * 1.7) * 4.0, cos(z._time * 1.1 + float(i) * 2.3) * 6.0)
			Art.glow(z, bp, 4.5, Color(0.55, 1.0, 0.3, 0.55))
			z.draw_circle(bp, 1.4, Color(0.75, 1.0, 0.5))
	z.draw_line(sac_c + Vector2(2, -12), sh + Vector2(-2, -1), col(Color("3a2a1a")), 1.6, true)   # רצועה
	# גבעולי נבגים על הכתף
	for i in 3:
		var base := sh + Vector2(-5.0 + float(i) * 3.0, -3.0)
		var tip := base + Vector2(-2.0 + float(i) + sin(z._time * 2.0 + float(i)) * 1.2, -7.0 - float(i % 2) * 2.0)
		z.draw_line(base, tip, col(Color("5a6a3a")), 1.3, true)
		z.draw_circle(tip, 1.6, col(Color("9ac040")))
	for q in _puffs:
		var k: float = q[2] / 1.2
		z.draw_circle(q[0], 1.5 + k * 3.0, Color(0.6, 0.9, 0.35, 0.45 * (1.0 - k)))
	# יד אחורית
	z._arm(sh + Vector2(-2, 1), sh + Vector2(2.0, 15.0 + sin(p) * 2.0), col(Art.shade(z.skin, 0.25)), suit_d)
	# ראש: מכוסה בגידולים, לסת עם זיפים, עיניים ירוקות
	Art.oval_shaded(z, head, 6.2, 6.8, sk, 0.15)
	for gp in [Vector2(-3, -5), Vector2(-5, -1), Vector2(-1, -6.5)]:
		Art.disc(z, head + gp, 1.8, col(Color("a0b060")), Art.OUTLINE, 0.7)
	Art.fill(z, PackedVector2Array([head + Vector2(2, 2), head + Vector2(7, 1.5), head + Vector2(6.5, 5 + throw_k * 3.0), head + Vector2(2.5, 5.5 + throw_k * 3.0)]), col(Color("2a0c1a")), Art.OUTLINE, 0.8)
	for i in 4:   # זיפים / זרועות קטנות סביב הפה
		var mp := head + Vector2(3.0 + float(i) * 1.2, 5.0 + throw_k * 3.0)
		z.draw_line(mp, mp + Vector2(sin(z._time * 6.0 + float(i)) * 1.0, 3.0), col(Color("6a2a4a")), 0.8, true)
	var eye := head + Vector2(3.8, -1.5)
	Art.glow(z, eye, 4.0, Color(0.55, 1.0, 0.3, 0.7))
	z.draw_circle(eye, 1.0, Color(0.8, 1.0, 0.6))
	# יד קדמית: מניפה מעל הראש כשזורק
	var hand := sh + Vector2(10.0, 8.0 - sin(p) * 2.0)
	if throw_k > 0.0:
		hand = sh + Vector2(lerpf(12.0, -2.0, throw_k), lerpf(-6.0, -16.0, throw_k))
	z._arm(sh + Vector2(2, 1), hand, sk, suit)
	if throw_k > 0.5:
		Art.glow(z, hand, 6.0, Color(0.6, 1.0, 0.3, 0.6))
	end_draw()
	return true
