extends "res://enemies/zombie_type.gd"
# ============================================================
#  STILTER (שלב 15, צפון-מזרח, קרנבל) - יצור שפוף וכחוש עם רגלי קנגורו: ירכיים שריריות, שוקיים גידיות,
#  כפות רגליים ארוכות עם טפרים. עור אפור-חיוור, צלעות ועמוד שדרה בולטים, גולגולת מוארכת בלי שיער,
#  עיניים שקועות זוהרות, לסת שמוטה עם שיניים ארוכות, ידיים ארוכות עם טפרים, סמרטוטי קרנבל במותניים.
#  הולך עם רגליים מקופלות, ובזינוק הרגליים נמתחות עד הסוף. מת = גופה רכה (ragdoll) בדמות היצור.
#  מחזור:
#    WALK   - פוסע בצעדים גדולים (המוח מזיז אותו).
#    CROUCH - מקפל את הרגליים הארוכות (CROUCH_T) = אזהרה.
#    LEAP   - זינוק ענק (עד LEAP_MAX פיקסלים) למקום שבו אתה עומד (או מעליך). יכול לעלות על קומות.
#    LAND   - נוחת בחבטה: מי שמתחתיו נפגע (STOMP_R). אחרי זה רגע של התאוששות = חלון לירות.
#  בוס: "THE BONECO" - בובת קרנבל ענקית של אולינדה (ראש עיסת נייר ענק). הנחיתה שלו = גל הדף רחב.
#  צלילים: "st_creak" (קפיצים / עץ חורק), "st_land" (חבטה).
#  לשנות: LEAP_RANGE, LEAP_MAX, CROUCH_T, STOMP_R.
# ============================================================

const SOUNDS := {
	"st_creak": [["S", 420, 300, 0.0, 0.3, 0.02, 6.0, 0.25, 1.0, 0.08], ["N", 0, 0, 0.0, 0.2, 0.0, 12.0, 0.2, 0.6, 0]],
	"st_land": [["S", 90, 40, 0.0, 0.3, 0.0, 10.0, 1.0, 1.0, 0], ["N", 0, 0, 0.0, 0.2, 0.0, 14.0, 0.6, 0.3, 0]],
}

const LEAP_RANGE := Vector2(110.0, 520.0)
const LEAP_MAX := 560.0
const CROUCH_T := 0.45
const STOMP_R := 36.0

enum { WALK, CROUCH, LEAP, LAND }
var state := WALK
var leaps := 0              # לבדיקות
var stomps := 0
var _st := 0.0
var _cd := 1.5
var _target_x := 0.0


func _boss() -> bool:
	return z != null and float(z.chase_range) > 600.0


func stats() -> Dictionary:
	if _boss():
		return {"name": "STILTER", "hp": 200, "walk": 50.0, "chase": 90.0, "damage": 2, "bite_delay": 1.0, "scale": 2.3, "width": 0.9,
			"duck": 0.0, "cover": 0.0, "skin": Color("e8c8a0"), "shirt": Color("e83a8a"), "pants": Color("3a2a6a"), "shoe": Color("2a1a10"),
			"points": 900, "boss": true, "boss_name": "THE BONECO", "ragdoll": false}
	return {"name": "STILTER", "hp": 32, "walk": 55.0, "chase": 110.0, "damage": 1, "bite_delay": 0.8, "scale": 1.55, "width": 0.75,
		"duck": 0.0, "cover": 0.1, "skin": Color("a4aab0"), "shirt": Color("2a8ac0"), "pants": Color("6a4a8a"), "shoe": Color("3a2a1a"),
		"points": 360}


func brain_overrides() -> Dictionary:
	return {"aggression": 0.4}


func can_bite() -> bool:
	return state == WALK


func physics(pl: Node, delta: float) -> bool:
	_cd -= delta
	_st -= delta
	if z.dead:
		return false
	match state:
		WALK:
			if _cd <= 0.0 and pl != null and not pl.dead and z.is_on_floor():
				var d: Vector2 = pl.global_position - z.global_position
				var sees: bool = z.brain == null or z.brain.sees
				var r := LEAP_RANGE * (1.4 if _boss() else 1.0)
				if sees and absf(d.x) > r.x and absf(d.x) < r.y and absf(d.y) < 260.0:
					state = CROUCH
					_st = CROUCH_T
					z._dir = signf(d.x) if d.x != 0.0 else z._dir
					_target_x = pl.global_position.x + pl.velocity.x * 0.35 + randf_range(-30.0, 30.0)   # מנחש לאן תזוז
					Sfx.play("st_creak", z.global_position, 0.0, 0.1, 2)
					return _stay(delta)
			return false
		CROUCH:
			if _st <= 0.0:
				_leap(pl)
			return _stay(delta)
		LEAP:
			z.velocity.y += z.gravity * delta
			z.move_and_slide()
			if z.is_on_floor() and z.velocity.y >= 0.0 and _st <= 0.0:
				_land(pl)
			return true
		LAND:
			if _st <= 0.0:
				state = WALK
				_cd = randf_range(1.4, 2.6) * (0.8 if _boss() else 1.0)
			return _stay(delta)
	return false


func _stay(delta: float) -> bool:
	z.velocity.x = move_toward(z.velocity.x, 0.0, 900.0 * delta)
	if not z.is_on_floor():
		z.velocity.y += z.gravity * delta
	z.move_and_slide()
	return true


func _leap(pl: Node) -> void:
	state = LEAP
	_st = 0.15
	leaps += 1
	var dx := clampf(_target_x - z.global_position.x, -LEAP_MAX * (1.3 if _boss() else 1.0), LEAP_MAX * (1.3 if _boss() else 1.0))
	var t := clampf(absf(dx) / 420.0, 0.55, 1.15)   # זמן באוויר
	var up := 0.0
	if pl != null:   # אם השחקן גבוה (על קומה) - קופץ יותר גבוה
		up = clampf(z.global_position.y - pl.global_position.y, 0.0, 220.0)
	z.velocity.x = dx / t
	z.velocity.y = -(0.5 * z.gravity * t + up / t)
	Sfx.play("st_creak", z.global_position, 2.0, 0.1, 2)
	Particles.burst(z.get_parent(), z.global_position, "smoke", Vector2.UP, 6)


func _land(pl: Node) -> void:
	state = LAND
	_st = 0.55
	Sfx.play("st_land", z.global_position, 2.0 if _boss() else -2.0, 0.1, 2)
	Particles.burst(z.get_parent(), z.global_position, "smoke", Vector2.UP, 10 if _boss() else 5)
	var r := STOMP_R * (3.5 if _boss() else 1.0)
	var cam: Node = z.get_viewport().get_camera_2d()
	if cam != null and cam.has_method("shake"):
		cam.shake(8.0 if _boss() else 3.0, 0.25)
	if pl != null and not pl.dead and absf(pl.global_position.x - z.global_position.x) < r and absf(pl.global_position.y - z.global_position.y) < 50.0:
		stomps += 1
		pl.hurt(z.damage, Vector2(signf(pl.global_position.x - z.global_position.x), -0.8))
		pl.velocity.y = minf(pl.velocity.y, -260.0)


# ============================================================
#  ציור: רגלי קנגורו (בקואורדינטות מקומיות, x פונה ימינה; הכל מוכפל ב-sc)
#  ירך עבה קדימה, שוק ארוכה אחורה, כף רגל ארוכה שטוחה על הרצפה.
#  הולך עם רגליים מקופלות (קפיצות קטנות), מתכופף עוד לפני זינוק, ובאוויר הרגליים נמתחות עד הסוף.
# ============================================================
func _ext() -> float:   # 0 = מקופל (הליכה), 1 = מתוח לגמרי (באוויר), שלילי = מתכופף
	match state:
		CROUCH:
			return -(1.0 - clampf(_st / CROUCH_T, 0.0, 1.0))
		LEAP:
			return 1.0 if z.velocity.y < 120.0 else 0.6   # עולה = מתוח, נוחת = מתחיל להתקפל
		LAND:
			return -clampf(_st / 0.55, 0.0, 1.0) * 0.7
	return 0.0


func _leg_pts(e: float, ph: float, back: bool) -> Array:
	# e: -1 מתכופף ... 0 הליכה ... 1 מתוח. ph = שלב ההליכה
	var air: bool = not z.is_on_floor() and not z.dead
	var hop := absf(sin(ph)) * 2.5 if (z.is_on_floor() and absf(z.velocity.x) > 8.0 and e == 0.0) else 0.0
	var hip_y: float = lerpf(-19.0, -10.0, -e) if e <= 0.0 else lerpf(-19.0, -38.0, e)
	hip_y -= hop
	var hip := Vector2(-2.0 + (1.5 if back else 0.0), hip_y)
	var step := sin(ph + (PI if back else 0.0)) * 3.0 if not air else 0.0
	var toe := Vector2(11.0 + step, 0.0)
	var ankle := Vector2(-3.0 + step, -3.5)
	var knee := hip + Vector2(7.5, 6.5)
	if e > 0.0:   # מתוח: הירך, השוק וכף הרגל כמעט בקו ישר מטה-אחורה
		var k := e
		knee = knee.lerp(hip + Vector2(2.0, 11.0), k)
		ankle = ankle.lerp(knee + Vector2(-3.0, 13.0), k)
		toe = toe.lerp(ankle + Vector2(4.0, 9.0), k)
	elif e < 0.0:   # מתכופף: ברך קדימה, עקב כמעט נוגע ברצפה
		var k := -e
		knee = knee.lerp(hip + Vector2(11.0, 3.0), k)
		ankle = ankle.lerp(Vector2(-6.0, -1.0), k)
	return [hip, knee, ankle, toe]


# ירך שרירית: טיפה מחודדת מהאגן לברך (רחבה למעלה)
func _thigh(a: Vector2, b: Vector2, w0: float, w1: float, c: Color) -> void:
	var d := (b - a).normalized()
	var n := Vector2(-d.y, d.x)
	var pts := PackedVector2Array([a + n * w0, a.lerp(b, 0.45) + n * w0 * 1.08, b + n * w1, b - n * w1, a.lerp(b, 0.5) - n * w0 * 0.8, a - n * w0])
	Art.fill_shaded(z, pts, c, 0.18, 0.42, Art.OUTLINE, 1.2)
	z.draw_line(a.lerp(b, 0.2) + n * w0 * 0.3, a.lerp(b, 0.75) + n * w1 * 0.4, Color(1, 1, 1, 0.12), 1.0)   # הדגשת שריר


# כף רגל ארוכה עם 3 טפרים
func _foot(ankle: Vector2, toe: Vector2, c: Color) -> void:
	Art.limb(z, PackedVector2Array([ankle, ankle.lerp(toe, 0.6), toe]), 2.4, c)
	var d := (toe - ankle).normalized()
	for i in 3:
		var a := d.rotated(-0.35 + float(i) * 0.35)
		z.draw_line(toe, toe + a * 3.2, col(Color("2a2420")), 1.2)


func draw() -> bool:
	begin_draw()
	var sk := col(z.skin)
	var dark := col(Art.shade(z.skin, 0.3))
	var p: float = z._walk_phase
	var e := _ext()
	var legs := [_leg_pts(e, p, true), _leg_pts(e, p, false)]
	var hip: Vector2 = legs[1][0]
	var hunch := 4.0 if e <= 0.0 else 1.0   # שפוף קדימה, באוויר נמתח
	var sh := hip + Vector2(4.0 + hunch, -13.0 + hunch * 0.4)
	var head := sh + Vector2(5.0 + hunch * 0.5, -4.0)
	# רגל אחורית
	_draw_leg(legs[0], dark, col(Art.shade(z.skin, 0.4)))
	# יד אחורית ארוכה עם טפרים
	_claw_arm(sh + Vector2(-1, 1), sh + Vector2(9, 12 + sin(p) * 2.0) if e <= 0.0 else sh + Vector2(-9, 8), dark)
	# גוף: צלעות בולטות, עמוד שדרה מזדקר, סמרטוטי קרנבל במותניים
	var body := PackedVector2Array([sh + Vector2(-4, -2), sh + Vector2(4, 0), hip + Vector2(4, 1), hip + Vector2(-4, 1)])
	Art.fill_shaded(z, body, sk, 0.18, 0.45, Art.OUTLINE, 1.2)
	for i in 4:   # צלעות
		var y := 2.0 + float(i) * 2.6
		z.draw_line(sh.lerp(hip, y / 13.0) + Vector2(-3.5, 0), sh.lerp(hip, y / 13.0) + Vector2(3.0, 1.0), col(Art.shade(z.skin, 0.35)), 0.8)
	for i in 4:   # חוליות שדרה בולטות על הגב
		z.draw_circle(sh.lerp(hip, float(i) / 4.0) + Vector2(-4.2, 0), 1.1, col(Color("c8c4b8")))
	for i in 4:   # סמרטוטים צבעוניים מתנופפים
		var rx := -3.0 + float(i) * 2.2
		var flap := sin(z._time * 6.0 + float(i)) * 1.5
		z.draw_line(hip + Vector2(rx, 0), hip + Vector2(rx - 2.0 + flap, 6.0 + float(i % 2) * 2.0), col([Color("c02040"), Color("e0b030"), Color("3080c0"), Color("a02080")][i]), 1.4)
	# רגל קדמית
	_draw_leg(legs[1], sk, col(Art.shade(z.skin, 0.15)))
	# צוואר + ראש
	Art.limb(z, PackedVector2Array([sh + Vector2(1, -1), head + Vector2(-2, 2)]), 2.4, dark)
	if _boss():   # בובת אולינדה מעוותת: ראש עיסת נייר ענק וסדוק
		var bh := head + Vector2(1, -5)
		Art.oval_shaded(z, bh, 9.0, 10.0, col(Color("e8c8a0")), 0.0)
		Art.fill(z, PackedVector2Array([bh + Vector2(-9, -3), bh + Vector2(-4, -12), bh + Vector2(5, -12), bh + Vector2(10, -2), bh + Vector2(2, -8)]), col(Color("2a1a10")), Art.OUTLINE, 1.0)
		z.draw_circle(bh + Vector2(-3, -1), 2.2, Color("1a0a0a"))
		z.draw_circle(bh + Vector2(4, -1), 2.2, Color("1a0a0a"))
		z.draw_circle(bh + Vector2(-3, -1), 0.9, Color(1.0, 0.85, 0.4))
		z.draw_circle(bh + Vector2(4, -1), 0.9, Color(1.0, 0.85, 0.4))
		z.draw_arc(bh + Vector2(1, 4), 4.5, 0.15, PI - 0.15, 8, col(Color("6a0808")), 2.0)
		z.draw_polyline(PackedVector2Array([bh + Vector2(-2, -10), bh + Vector2(1, -4), bh + Vector2(-1, 2)]), col(Color("3a2a1a")), 1.0)
	else:
		_skull(head)
	# יד קדמית
	_claw_arm(sh + Vector2(2, 1), sh + Vector2(12, 8 - sin(p) * 2.0) if e <= 0.0 else sh + Vector2(-6, 10), sk)
	end_draw()
	return true


func _draw_leg(lp: Array, c: Color, c2: Color) -> void:
	_thigh(lp[0], lp[1], 3.6, 1.8, c)
	Art.limb(z, PackedVector2Array([lp[1], lp[1].lerp(lp[2], 0.5) + Vector2(-0.5, 0), lp[2]]), 2.2, c2)   # שוק דקה וגידית
	z.draw_line(lp[1] + Vector2(-1, 1), lp[2] + Vector2(-1, -1), Color(0, 0, 0, 0.25), 0.8)   # גיד אכילס
	_foot(lp[2], lp[3], c2)


# גולגולת מוארכת, בלי שיער, עיניים שקועות זוהרות, לסת שמוטה עם שיניים ארוכות
func _skull(h: Vector2) -> void:
	var sk := col(z.skin)
	var skull := PackedVector2Array([h + Vector2(-4, -3), h + Vector2(-1, -6.5), h + Vector2(5, -6), h + Vector2(8, -2), h + Vector2(7.5, 1.5), h + Vector2(2, 2.5), h + Vector2(-3, 1)])
	Art.fill_shaded(z, skull, sk, 0.15, 0.45, Art.OUTLINE, 1.2)
	z.draw_circle(h + Vector2(4.2, -2.0), 1.8, Color("120808"))   # ארובת עין
	z.draw_circle(h + Vector2(4.4, -2.0), 0.8, Color(0.95, 0.95, 0.7))
	Art.glow(z, h + Vector2(4.4, -2.0), 4.0, Color(0.9, 0.95, 0.6, 0.5))
	var open := 2.5 + (2.5 if state == CROUCH or state == LEAP else absf(sin(z._time * 3.0)) * 1.0)
	var jaw := PackedVector2Array([h + Vector2(0, 2), h + Vector2(7, 1.5), h + Vector2(6, 2.5 + open), h + Vector2(1, 3 + open)])
	Art.fill(z, jaw, col(Art.shade(z.skin, 0.2)), Art.OUTLINE, 1.0)
	z.draw_rect(Rect2(h + Vector2(1.5, 1.6), Vector2(5.2, open * 0.7)), Color("2a0606"))   # פה פעור
	for i in 4:   # שיניים ארוכות
		var tx := 2.0 + float(i) * 1.4
		z.draw_line(h + Vector2(tx, 1.8), h + Vector2(tx, 3.2), Color("e8e0c0"), 0.8)
		z.draw_line(h + Vector2(tx + 0.5, 2.0 + open), h + Vector2(tx + 0.5, 0.8 + open), Color("e8e0c0"), 0.8)
	z.draw_line(h + Vector2(-1, -5.5), h + Vector2(-3, -9), col(Color("2a2420")), 0.6)   # שערות דלילות
	z.draw_line(h + Vector2(1, -6.2), h + Vector2(0, -9.5), col(Color("2a2420")), 0.6)


# יד ארוכה ודקה עם שלושה טפרים
func _claw_arm(s0: Vector2, hand: Vector2, c: Color) -> void:
	var el := s0.lerp(hand, 0.5) + Vector2(-2, 3)
	Art.limb(z, PackedVector2Array([s0, el]), 2.2, c)
	Art.limb(z, PackedVector2Array([el, hand]), 1.8, c)
	var d := (hand - el).normalized()
	for i in 3:
		var a := d.rotated(-0.45 + float(i) * 0.45)
		z.draw_line(hand, hand + a * 4.0, col(Color("2a2420")), 1.0)


# ============================================================
#  גופה רכה (effects/ragdoll.gd): תנוחה עם רגלי קנגורו + ציור בדמות היצור
# ============================================================
func ragdoll_pose() -> Array:
	return [Vector2(9, -43), Vector2(6, -34), Vector2(-1, -19),
		Vector2(7, -13), Vector2(-4, -3), Vector2(8, -13), Vector2(-2, -3),
		Vector2(10, -26), Vector2(14, -19), Vector2(12, -27), Vector2(16, -20)]


func draw_ragdoll(ci: CanvasItem, rag) -> void:
	var p: PackedVector2Array = rag.p
	var sc: float = z.sc
	var sk: Color = z.skin
	var dark := Art.shade(z.skin, 0.3)
	ci.draw_colored_polygon(Art.ellipse((p[rag.PELVIS] + p[rag.NECK]) * 0.5 + Vector2(0, 8.0 * sc), 20.0 * sc, 3.0 * sc, 0.0, 12), Color(0, 0, 0, 0.25))
	for leg in [[rag.KNEE_B, rag.FOOT_B, dark], [rag.KNEE_F, rag.FOOT_F, sk]]:   # רגלי קנגורו
		var kn: Vector2 = p[leg[0]]
		var ft: Vector2 = p[leg[1]]
		var pv: Vector2 = p[rag.PELVIS]
		var d := (kn - pv).normalized()
		var n := Vector2(-d.y, d.x)
		Art.fill_shaded(ci, PackedVector2Array([pv + n * 3.6 * sc, pv.lerp(kn, 0.45) + n * 3.9 * sc, kn + n * 1.8 * sc, kn - n * 1.8 * sc, pv - n * 3.0 * sc]), leg[2], 0.18, 0.42, Art.OUTLINE, 1.2)
		Art.limb(ci, PackedVector2Array([kn, ft]), 2.2 * sc, leg[2])
		var fd := (ft - kn).normalized()
		var toe := ft + fd.rotated(-1.2 * float(z._dir)) * 9.0 * sc   # כף רגל ארוכה
		Art.limb(ci, PackedVector2Array([ft, toe]), 2.0 * sc, leg[2])
	var axis := (p[rag.PELVIS] - p[rag.NECK]).normalized()
	var nrm := Vector2(-axis.y, axis.x) * 4.0 * sc
	Art.fill_shaded(ci, PackedVector2Array([p[rag.NECK] + nrm, p[rag.NECK] - nrm, p[rag.PELVIS] - nrm * 0.9, p[rag.PELVIS] + nrm * 0.9]), sk, 0.18, 0.45, Art.OUTLINE, 1.2)
	for i in 4:   # צלעות
		var c := p[rag.NECK].lerp(p[rag.PELVIS], 0.15 + 0.18 * float(i))
		ci.draw_line(c - nrm * 0.8, c + nrm * 0.7, Art.shade(z.skin, 0.35), 0.8 * sc)
	for arm in [[rag.ELBOW_B, rag.HAND_B, dark], [rag.ELBOW_F, rag.HAND_F, sk]]:
		Art.limb(ci, PackedVector2Array([p[rag.NECK], p[arm[0]], p[arm[1]]]), 2.0 * sc, arm[2])
		var hd: Vector2 = (p[arm[1]] - p[arm[0]]).normalized()
		for i in 3:
			ci.draw_line(p[arm[1]], p[arm[1]] + hd.rotated(-0.45 + float(i) * 0.45) * 4.0 * sc, Color("2a2420"), 1.0)
	var hdir := (p[rag.HEAD] - p[rag.NECK]).normalized()
	Art.limb(ci, PackedVector2Array([p[rag.NECK], p[rag.HEAD]]), 2.4 * sc, dark)
	Art.oval_shaded(ci, p[rag.HEAD], 5.5 * sc, 4.5 * sc, sk, hdir.angle())
	ci.draw_circle(p[rag.HEAD] + hdir * 2.0 * sc, 1.6 * sc, Color("120808"))
	ci.draw_line(p[rag.HEAD] + hdir.rotated(0.8) * 3.0 * sc, p[rag.HEAD] + hdir.rotated(1.6) * 4.5 * sc, Color("2a0606"), 1.6 * sc)   # לסת שמוטה
