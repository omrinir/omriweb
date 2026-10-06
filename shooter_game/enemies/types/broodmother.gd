extends "res://enemies/zombie_type.gd"
# ============================================================
#  BROODMOTHER (בוס שלב 16) - "THE BROODMOTHER". ענקית כפופה על ארבע, עם שק בטן שקוף ונפוח
#  שבתוכו מתפתלים זומבים קטנים. הנשק שלה: יולדת SWARMERS ויורה אותם עליך.
#  מחזור:
#    WALK   - מתקדמת לאט, נושכת מקרוב (2 לבבות).
#    LABOR  - עוצרת, השק מתנפח, זוהר ורועד, צרחה (LABOR_T שניות) = אזהרה.
#    BIRTH  - השק נפתח: LITTER זומבים קטנים נזרקים באוויר לכיוונך (newborn), ואז מנוחה קצרה.
#  פחות מחצי חיים: כועסת - יולדת יותר ומהר יותר. לא יותר מ-MAX_KIDS ילדים חיים בבת אחת.
#  לשנות: LABOR_T, LITTER, CD, MAX_KIDS.
# ============================================================

const Registry := preload("res://enemies/zombie_registry.gd")

const SOUNDS := {
	"bm_labor": [["W", 220, 520, 0.0, 1.0, 0.1, 1.2, 0.4, 0.35, 0.09], ["N", 0, 0, 0.0, 1.0, 0.1, 1.5, 0.25, 0.3, 0]],
	"bm_birth": [["N", 0, 0, 0.0, 0.35, 0.0, 8.0, 0.8, 0.25, 0], ["S", 140, 60, 0.0, 0.3, 0.0, 9.0, 0.7, 1.0, 0], ["W", 700, 300, 0.05, 0.4, 0.0, 6.0, 0.2, 0.4, 0.05]],
}

const LABOR_T := 1.1
const LITTER := Vector2i(2, 3)          # כמה בכל לידה (כועסת: +1)
const CD := Vector2(6.0, 8.5)
const MAX_KIDS := 8

enum { WALK, LABOR, REST }
var state := WALK
var births := 0                          # לבדיקות
var kids_born := 0
var _st := 0.0
var _cd := 2.5
var _kids: Array = []


func stats() -> Dictionary:
	return {"name": "BROODMOTHER", "hp": 320, "walk": 32.0, "chase": 52.0, "damage": 2, "bite_delay": 1.1, "scale": 1.9, "width": 1.5,
		"duck": 0.0, "cover": 0.0, "skin": Color("b4a69c"), "shirt": Color("c8828c"), "pants": Color("4a3a3a"), "shoe": Color("2a2020"),
		"points": 1500, "boss": true, "boss_name": "THE BROODMOTHER", "ragdoll": false}


func can_groan() -> bool:
	return state == WALK


func _rage() -> bool:
	return z.hp < z.max_hp / 2


func _belly() -> Vector2:
	return z.global_position + Vector2(z._dir * 2.0, -18.0) * z.sc


func physics(pl: Node, delta: float) -> bool:
	if z.dead:
		return false
	_cd -= delta
	_st -= delta
	var has_pl: bool = pl != null and not pl.dead
	var d: Vector2 = (pl.global_position - z.global_position) if has_pl else Vector2.ZERO
	match state:
		WALK:
			if has_pl and absf(d.x) > 8.0:
				z._dir = signf(d.x)
			var want: float = z._dir * float(z.chase_speed) * (1.35 if _rage() else 1.0) if has_pl and absf(d.x) > 50.0 * z.sc else 0.0
			z.velocity.x = move_toward(z.velocity.x, want, 400.0 * delta)
			z._walk_phase += delta * absf(z.velocity.x) * 0.06 / z.sc
			_kids = _kids.filter(func(k): return is_instance_valid(k) and not k.dead)
			if has_pl and _cd <= 0.0 and absf(d.x) < 820.0 and _kids.size() < MAX_KIDS and z.is_on_floor():
				state = LABOR
				_st = LABOR_T * (0.75 if _rage() else 1.0)
				Sfx.play("bm_labor", z.global_position, 2.0, 0.05, 2)
			# נשיכה
			if has_pl and absf(d.x) < 34.0 * z.sc and absf(d.y) < 70.0 and z._attack_t <= 0.0:
				z._attack_t = z.bite_delay
				z._bite_anim = 0.3
				pl.hurt(z.damage, Vector2(z._dir * 1.5, -0.4))
		LABOR:
			z.velocity.x = move_toward(z.velocity.x, 0.0, 600.0 * delta)
			if randf() < delta * 10.0:
				Particles.burst(z.get_parent(), _belly() + Vector2(randf_range(-14.0, 14.0), 14.0 * z.sc), "hit", Vector2.DOWN, 2)
			if _st <= 0.0:
				_give_birth(pl)
				state = REST
				_st = 0.7
		REST:
			z.velocity.x = move_toward(z.velocity.x, 0.0, 600.0 * delta)
			if _st <= 0.0:
				state = WALK
				_cd = randf_range(CD.x, CD.y) * (0.65 if _rage() else 1.0)
	if not z.is_on_floor():
		z.velocity.y += z.gravity * delta
	z.move_and_slide()
	return true


# הלידה: הקטנים נזרקים מהשק לכיוון השחקן, כל אחד בקשת אחרת
func _give_birth(pl: Node) -> void:
	births += 1
	var n := randi_range(LITTER.x, LITTER.y) + (1 if _rage() else 0)
	n = mini(n, MAX_KIDS - _kids.size())
	var main: Node = z.get_parent()
	var at := _belly()
	var dir: float = z._dir
	if pl != null and not pl.dead:
		dir = signf(pl.global_position.x - z.global_position.x) if pl.global_position.x != z.global_position.x else z._dir
	Sfx.play("bm_birth", at, 3.0, 0.08, 2)
	Particles.burst(main, at, "hit", Vector2(dir, -0.5), 18)
	var cam: Node = z.get_viewport().get_camera_2d()
	if cam != null and cam.has_method("shake"):
		cam.shake(7.0, 0.3)
	for i in n:
		if not main.has_method("_spawn_zombie"):
			break
		var k = main._spawn_zombie(at.x, at.y, Registry.SWARMER)
		if k == null:
			continue
		k.global_position = at + Vector2(randf_range(-8.0, 8.0), randf_range(-6.0, 6.0))
		k._dir = dir
		k.velocity = Vector2(dir * randf_range(170.0, 560.0), -randf_range(240.0, 560.0))
		if k.type_mod != null:
			k.type_mod.newborn = true
		_kids.append(k)
		kids_born += 1


# ============================================================
#  ציור: גוף כפוף על ארבע, שק בטן ענק ושקוף עם קטנים שמתפתלים בפנים, שיער שחור ארוך
# ============================================================
func draw() -> bool:
	begin_draw()
	var sk := col(z.skin)
	var sk_d := col(Art.shade(z.skin, 0.22))
	var sk_far := col(Art.shade(z.skin, 0.42))
	var p: float = z._walk_phase
	var t: float = z._time
	var lab := 0.0
	if state == LABOR:
		lab = 1.0 - clampf(_st / LABOR_T, 0.0, 1.0)
	var shake := Vector2(sin(t * 60.0), cos(t * 47.0)) * 1.2 * lab
	var breathe := sin(t * 2.4) * 0.8
	var hip := Vector2(-22.0, -38.0 + absf(sin(p)) * 1.2) + shake
	var sh := Vector2(17.0, -44.0 + absf(sin(p + 1.2)) * 1.0) + shake
	# גפיים רחוקות (כהות)
	_limb(hip + Vector2(3.0, 0.0), p + PI, sk_far, false)
	_limb(sh + Vector2(-3.0, 1.0), p, sk_far, true)
	# שק הבטן: תלוי בין הגפיים
	var pulse := 1.0 + 0.04 * sin(t * 3.0) + 0.16 * lab + 0.05 * sin(t * 25.0) * lab
	var sc0 := Vector2(-3.0, -23.0 + breathe * 0.5) + shake
	var rx := 16.0 * pulse
	var ry := 13.0 * pulse
	var sac_col := col(z.shirt).lerp(Color(1.0, 0.32, 0.25), 0.5 * lab)
	Art.glow(z, sc0, rx * 1.5, Color(1.0, 0.35, 0.3, 0.2 + 0.4 * lab))
	z.draw_colored_polygon(Art.ellipse(sc0 + Vector2(0.0, 1.5), rx + 1.5, ry + 1.5, 0.0, 24), Art.OUTLINE)
	z.draw_colored_polygon(Art.ellipse(sc0, rx, ry, 0.0, 24), Color(sac_col, 0.93))
	z.draw_colored_polygon(Art.ellipse(sc0 + Vector2(1.0, 4.0), rx * 0.8, ry * 0.6, 0.0, 18), Color(sac_col.darkened(0.25), 0.6))
	for i in 4:   # הקטנים בפנים: צלליות מכורבלות שזזות
		var a := t * (0.9 + 0.2 * float(i)) + float(i) * 1.7
		var kp := sc0 + Vector2(cos(a) * rx * 0.45, sin(a * 1.3) * ry * 0.4 + 2.0)
		var kr := Vector2.from_angle(a * 0.7)
		z.draw_colored_polygon(Art.ellipse(kp, 4.4, 2.7, kr.angle(), 10), Color(0.28, 0.07, 0.1, 0.55))
		z.draw_circle(kp + kr * 3.8, 1.9, Color(0.28, 0.07, 0.1, 0.6))
		z.draw_line(kp - kr * 2.0, kp - kr * 4.5 + kr.orthogonal() * 2.0 * sin(t * 8.0 + float(i)), Color(0.28, 0.07, 0.1, 0.5), 1.0)
	for v in 6:   # ורידים
		var va := -2.9 + float(v) * 0.55
		z.draw_polyline(PackedVector2Array([sc0 + Vector2.from_angle(va) * rx * 0.25, sc0 + Vector2.from_angle(va + 0.18) * rx * 0.62, sc0 + Vector2.from_angle(va - 0.05) * rx * 0.97]), Color(0.5, 0.1, 0.18, 0.55), 0.9)
	z.draw_arc(sc0 + Vector2(-4.0, -4.0), rx * 0.6, -2.7, -1.7, 8, Color(1, 1, 1, 0.4), 1.5)   # הברקה
	if lab > 0.0:   # טיפות נוזל
		for d in 3:
			var dp := sc0 + Vector2(-6.0 + float(d) * 6.0, ry - 1.0 + fmod(t * 30.0 + float(d) * 7.0, 9.0))
			z.draw_circle(dp, 1.0, Color(0.85, 0.95, 0.6, 0.7))
	# גו: גב מקומר עם דבשת, חזה רחב, מותניים צרים
	var spine := [hip + Vector2(-7.0, 2.0), hip + Vector2(-3.0, -10.0), hip.lerp(sh, 0.3) + Vector2(0.0, -17.0 - breathe),
		hip.lerp(sh, 0.6) + Vector2(0.0, -16.0 - breathe), sh + Vector2(-2.0, -10.0), sh + Vector2(7.0, -5.0)]
	var belly := [sh + Vector2(8.0, 4.0), sh + Vector2(0.0, 9.0), hip.lerp(sh, 0.55) + Vector2(0.0, 9.0), hip.lerp(sh, 0.25) + Vector2(0.0, 8.0), hip + Vector2(-4.0, 8.0)]
	var body := PackedVector2Array(spine + belly)
	Art.fill_shaded(z, body, sk, 0.16, 0.45)
	for i in 5:   # פצעים וכתמים
		var sp := hip.lerp(sh, 0.15 + float(i) * 0.17) + Vector2(sin(float(i) * 2.3) * 3.0, -8.0 + cos(float(i) * 1.7) * 4.0)
		z.draw_colored_polygon(Art.ellipse(sp, 2.2 + float(i % 2), 1.4, float(i), 8), col(Color(0.5, 0.18, 0.2, 0.75)))
	for i in 4:   # צלעות בולטות
		var rb := hip.lerp(sh, 0.45 + float(i) * 0.12) + Vector2(0.0, -4.0)
		z.draw_polyline(PackedVector2Array([rb + Vector2(-2.0, -5.0), rb + Vector2(0.0, 0.0), rb + Vector2(-1.0, 5.0)]), col(Art.shade(z.skin, 0.32)), 1.1)
	for i in 7:   # עמוד שדרה עם קוצים
		var k := float(i) / 6.0
		var a: Vector2 = spine[1].lerp(spine[2], k * 2.0) if k < 0.5 else spine[2].lerp(spine[4], (k - 0.5) * 2.0)
		Art.fill(z, PackedVector2Array([a + Vector2(-2.0, 1.5), a + Vector2(-0.5, -4.0 - 1.5 * sin(k * PI)), a + Vector2(2.0, 1.5)]), col(Art.shade(z.skin, -0.12)), Art.OUTLINE, 0.8)
	# גפיים קרובות
	_limb(hip + Vector2(6.0, 2.0), p, sk_d, false)
	_limb(sh + Vector2(1.0, 3.0), p + PI, sk_d, true)
	# צוואר + ראש: גולגולת מוארכת, שיער שחור ארוך שנופל, לסת שנפתחת למטה
	var bite := clampf(z._bite_anim / 0.3, 0.0, 1.0)
	var scream := maxf(lab, bite)
	var head := sh + Vector2(15.0, 3.0 + sin(t * 2.0) * 0.8 + scream * 2.0)
	Art.limb(z, PackedVector2Array([sh + Vector2(4.0, -3.0), head + Vector2(-5.0, -1.0)]), 5.0, sk)
	for h in 6:   # שיער מאחור
		var hb := head + Vector2(-6.0 + float(h) * 1.6, -5.5)
		var sway := sin(t * 2.2 + float(h) * 0.6) * 2.0
		z.draw_polyline(PackedVector2Array([hb, hb + Vector2(-4.0, 7.0), hb + Vector2(-5.0 + sway, 17.0 + float(h % 3) * 4.0)]), Color(0.05, 0.04, 0.05), 1.6)
	var skull := PackedVector2Array([head + Vector2(-6.0, -4.0), head + Vector2(-1.0, -7.5), head + Vector2(6.0, -5.0), head + Vector2(9.0, -1.0),
		head + Vector2(8.0, 3.0), head + Vector2(1.0, 4.0), head + Vector2(-5.0, 2.0)])
	Art.fill_shaded(z, skull, col(Art.shade(z.skin, -0.08)), 0.0, 0.35)
	var jaw := 2.0 + 7.0 * scream
	Art.fill(z, PackedVector2Array([head + Vector2(0.0, 2.5), head + Vector2(8.5, 1.0), head + Vector2(6.5, 3.0 + jaw), head + Vector2(0.5, 3.5 + jaw * 0.7)]), col(Art.shade(z.skin, 0.25)), Art.OUTLINE, 1.0)
	z.draw_colored_polygon(PackedVector2Array([head + Vector2(1.0, 2.8), head + Vector2(8.0, 1.6), head + Vector2(6.0, 2.5 + jaw * 0.85)]), Color(0.2, 0.02, 0.04))
	for tth in 4:
		var tx := 1.8 + float(tth) * 1.7
		z.draw_line(head + Vector2(tx, 2.2), head + Vector2(tx, 3.6), Color(0.92, 0.9, 0.78), 0.9)
	for e in 2:   # עיניים זוהרות
		var ep := head + Vector2(3.0 + float(e) * 3.2, -2.5)
		Art.glow(z, ep, 3.8, Color(1.0, 0.3, 0.2, 0.75))
		z.draw_circle(ep, 1.0, Color(1.0, 0.85, 0.5))
	z.draw_colored_polygon(Art.ellipse(head + Vector2(4.6, -2.4), 4.6, 2.2, 0.0, 12), Color(0.08, 0.04, 0.05))   # ארובות עיניים
	for h in 2:   # קווצות שיער בצדדים
		var hb := head + Vector2(-4.0 + float(h) * 2.0, -6.5)
		var sway := sin(t * 2.0 + float(h)) * 1.5
		z.draw_polyline(PackedVector2Array([hb, hb + Vector2(-0.5, 7.0), hb + Vector2(-1.0 + sway, 15.0 + float(h) * 5.0)]), Color(0.06, 0.05, 0.06), 1.4)
	for e in 2:
		var ep2 := head + Vector2(3.0 + float(e) * 3.2, -2.5)
		Art.glow(z, ep2, 3.8, Color(1.0, 0.3, 0.2, 0.75))
		z.draw_circle(ep2, 1.1, Color(1.0, 0.85, 0.5))
	end_draw()
	return true


# גף: ירך/כתף -> ברך (קדימה) או מרפק (אחורה) -> כף על הרצפה. ידיים קדמיות הולכות על פרקי אצבעות
func _limb(top: Vector2, ph: float, c: Color, front: bool) -> void:
	var sw := sin(ph)
	var foot := Vector2(top.x + sw * 8.0 + (5.0 if front else -5.0), -maxf(0.0, cos(ph)) * 4.0)
	var mid := top.lerp(foot, 0.48) + (Vector2(-7.0, 0.0) if front else Vector2(8.0, -1.0))
	Art.limb(z, PackedVector2Array([top, mid]), 5.2 if not front else 4.4, c)
	Art.limb(z, PackedVector2Array([mid, foot + Vector2(0.0, -2.0)]), 3.4 if not front else 3.0, c)
	z.draw_circle(mid, 2.4 if not front else 2.0, c.darkened(0.15))   # מפרק
	for f in 3:   # טפרים
		z.draw_line(foot + Vector2(-1.0, -1.0), foot + Vector2(2.5 + float(f) * 1.8, 0.2), col(Color("d8ccb0")), 1.1)
