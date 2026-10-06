extends "res://enemies/zombie_type.gd"
# ============================================================
#  STILTER (שלב 15, צפון-מזרח, קרנבל) - זומבי עם רגלי קנגורו: ירכיים עבות, שוקיים ארוכות וכפות רגליים
#  ארוכות. הולך עם רגליים מקופלות, ובזינוק הרגליים נמתחות עד הסוף. גוף צר, ז'קט פסים, כובע צילינדר מעוך.
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
		"duck": 0.0, "cover": 0.1, "skin": Color("98a880"), "shirt": Color("2a8ac0"), "pants": Color("6a4a8a"), "shoe": Color("3a2a1a"),
		"points": 360, "ragdoll": false}


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


func draw() -> bool:
	begin_draw()
	var sk := col(z.skin)
	var jacket := col(z.shirt)
	var shorts := col(z.pants)
	var p: float = z._walk_phase
	var e := _ext()
	var legs := [_leg_pts(e, p, true), _leg_pts(e, p, false)]
	var hip: Vector2 = legs[1][0]
	var lean := 3.0 if e <= 0.0 else -1.0   # הולך שפוף קדימה, באוויר הגוף זקוף
	var sh := hip + Vector2(3.0 + lean, -13.0)
	var head := sh + Vector2(3.0, -6.0)
	# רגליים: אחורית כהה יותר
	for i in 2:
		var lp: Array = legs[i]
		var dark := i == 0
		var thigh_c := col(Art.shade(z.pants, 0.3)) if dark else shorts
		var skin_c := col(Art.shade(z.skin, 0.25)) if dark else sk
		var th: Vector2 = lp[1] - lp[0]
		Art.limb(z, PackedVector2Array([lp[1], lp[2]]), 3.2, skin_c)               # שוק ארוכה
		Art.limb(z, PackedVector2Array([lp[2], lp[3]]), 2.6, skin_c)               # כף רגל ארוכה
		Art.oval(z, lp[0] + th * 0.5, th.length() * 0.62 + 2.0, 4.6, thigh_c, th.angle(), Art.OUTLINE, 1.2)   # ירך שרירית עבה (קנגורו)
		z.draw_circle(lp[1], 2.0, skin_c)                                         # ברך
		z.draw_line(lp[3], lp[3] + Vector2(2.5, 0.0), col(z.shoe), 2.0)           # בהונות
	# גוף צר עם ז'קט פסים
	var body := PackedVector2Array([sh + Vector2(-4, -1), sh + Vector2(4, 0), hip + Vector2(4.5, 1), hip + Vector2(-4, 1)])
	Art.fill_shaded(z, body, jacket, 0.15, 0.4)
	for i in 3:
		z.draw_line(sh + Vector2(-3.5 + float(i) * 3.2, 0), hip + Vector2(-3.0 + float(i) * 3.2, 0), col(Color("f0e8d0")), 0.8)
	# ידיים: באוויר מתוחות לאחור, בהליכה מושטות קדימה
	var hand_a := sh + (Vector2(-9, 6) if e > 0.0 else Vector2(9, 8 + sin(p) * 2.0))
	var hand_b := sh + (Vector2(-6, 9) if e > 0.0 else Vector2(11, 5 - sin(p) * 2.0))
	z._arm(sh + Vector2(-1, 1), hand_a, col(Art.shade(z.skin, 0.25)), Art.shade(jacket, 0.3))
	z._arm(sh + Vector2(2, 1), hand_b, sk, jacket)
	if _boss():   # בובת אולינדה: ראש ענק של עיסת נייר
		var bh := head + Vector2(1, -5)
		Art.oval_shaded(z, bh, 9.0, 10.0, sk, 0.0)
		Art.fill(z, PackedVector2Array([bh + Vector2(-9, -3), bh + Vector2(-4, -12), bh + Vector2(5, -12), bh + Vector2(10, -2), bh + Vector2(2, -8)]), col(Color("2a1a10")), Art.OUTLINE, 1.0)
		z.draw_circle(bh + Vector2(-3, -1), 2.0, Color.WHITE)
		z.draw_circle(bh + Vector2(4, -1), 2.0, Color.WHITE)
		z.draw_circle(bh + Vector2(-2.5, -1), 1.0, Color(0.8, 0.1, 0.1))
		z.draw_circle(bh + Vector2(4.5, -1), 1.0, Color(0.8, 0.1, 0.1))
		z.draw_arc(bh + Vector2(1, 4), 4.0, 0.2, PI - 0.2, 8, col(Color("a01818")), 1.6)
		Art.oval(z, bh + Vector2(-5, 3), 2.0, 1.2, Color(0.95, 0.4, 0.4, 0.6), 0.0, Art.NONE)
		Art.oval(z, bh + Vector2(6, 3), 2.0, 1.2, Color(0.95, 0.4, 0.4, 0.6), 0.0, Art.NONE)
	else:
		Art.oval_shaded(z, head, 4.8, 5.2, sk, 0.0)
		z.draw_circle(head + Vector2(2.4, -0.5), 1.0, Color(1.0, 0.85, 0.3))
		z.draw_line(head + Vector2(0.5, 2.6), head + Vector2(4.4, 2.3), col(Color("2a0a0a")), 1.0)
		# כובע צילינדר מעוך
		Art.fill(z, PackedVector2Array([head + Vector2(-4, -4), head + Vector2(4, -4.5), head + Vector2(3.5, -11), head + Vector2(-2, -12)]), col(Color("1a1a22")), Art.OUTLINE, 0.8)
		z.draw_line(head + Vector2(-5, -4), head + Vector2(5, -4.5), col(Color("1a1a22")), 1.4)
		z.draw_line(head + Vector2(-3.5, -6), head + Vector2(3.5, -6.5), col(Color("e83a3a")), 1.0)
	end_draw()
	return true
