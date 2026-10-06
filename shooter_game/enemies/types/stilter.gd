extends "res://enemies/zombie_type.gd"
# ============================================================
#  STILTER (שלב 15, צפון-מזרח, קרנבל) - הולך-על-קביים של הקרנבל שהפך לזומבי: רגליים ארוכות ומכופפות
#  (ברך הפוכה, כמו של חגב), גוף צר, ז'קט פסים של ליצן, כובע צילינדר מעוך.
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
		"duck": 0.0, "cover": 0.1, "skin": Color("98a880"), "shirt": Color("2a8ac0"), "pants": Color("e8d8b0"), "shoe": Color("3a2a1a"),
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
#  ציור: רגליים ארוכות עם ברך הפוכה (בקואורדינטות מקומיות, x פונה ימינה; הכל מוכפל ב-sc)
# ============================================================
func draw() -> bool:
	begin_draw()
	var sk := col(z.skin)
	var jacket := col(z.shirt)
	var pole := col(z.pants)
	var p: float = z._walk_phase
	var bend := 0.0   # 0 = עומד, 1 = מקופל עד הסוף
	match state:
		CROUCH:
			bend = 1.0 - clampf(_st / CROUCH_T, 0.0, 1.0)
		LAND:
			bend = clampf(_st / 0.55, 0.0, 1.0) * 0.8
		LEAP:
			bend = 0.25
	var hip_y := lerpf(-24.0, -15.0, bend) + absf(sin(p)) * 0.6
	var hip := Vector2(-1.0, hip_y)
	var sh := hip + Vector2(1.0, -14.0)
	var head := sh + Vector2(2.0, -6.0)
	# שתי רגליים-קביים: ירך קדימה, ברך הפוכה אחורה, שוק ארוכה לרצפה
	for i in 2:
		var ph := p + float(i) * PI
		var foot := Vector2(sin(ph) * 5.0 + (1.0 if i == 0 else -1.0), -maxf(0.0, cos(ph)) * 2.0)
		if not z.is_on_floor() and not z.dead:
			foot = Vector2(3.0 - float(i) * 6.0, -3.0)
		var knee := hip + Vector2(5.0 + 4.0 * bend, (foot.y - hip.y) * 0.4)
		var hock := knee + Vector2(-6.0 - 3.0 * bend, (foot.y - knee.y) * 0.55)
		var c := pole if i == 0 else col(Art.shade(z.pants, 0.3))
		Art.limb(z, PackedVector2Array([hip + Vector2(0, 0), knee]), 2.6, c)
		Art.limb(z, PackedVector2Array([knee, hock]), 2.0, c)
		Art.limb(z, PackedVector2Array([hock, foot]), 1.6, c)
		z.draw_line(foot + Vector2(-2.5, 0), foot + Vector2(3.0, 0), col(z.shoe), 1.6)   # רגלית
		z.draw_circle(knee, 1.4, col(Color("b0a080")))   # מפרק
	# גוף צר עם ז'קט פסים
	var body := PackedVector2Array([sh + Vector2(-4, -1), sh + Vector2(4, 0), hip + Vector2(3.5, 1), hip + Vector2(-3.5, 1)])
	Art.fill_shaded(z, body, jacket, 0.15, 0.4)
	for i in 3:
		z.draw_line(sh + Vector2(-3.5 + float(i) * 3.2, 0), hip + Vector2(-3.0 + float(i) * 3.0, 0), col(Color("f0e8d0")), 0.8)
	# ידיים ארוכות ודקות
	z._arm(sh + Vector2(-1, 1), sh + Vector2(9, 9 + sin(p) * 2.0), col(Art.shade(z.skin, 0.25)), Art.shade(jacket, 0.3))
	z._arm(sh + Vector2(2, 1), sh + Vector2(11, 6 - sin(p) * 2.0), sk, jacket)
	if _boss():   # בובת אולינדה: ראש ענק של עיסת נייר
		var bh := head + Vector2(1, -5)
		Art.oval_shaded(z, bh, 9.0, 10.0, sk, 0.0)
		Art.fill(z, PackedVector2Array([bh + Vector2(-9, -3), bh + Vector2(-4, -12), bh + Vector2(5, -12), bh + Vector2(10, -2), bh + Vector2(2, -8)]), col(Color("2a1a10")), Art.OUTLINE, 1.0)   # שיער צבוע
		z.draw_circle(bh + Vector2(-3, -1), 2.0, Color.WHITE)
		z.draw_circle(bh + Vector2(4, -1), 2.0, Color.WHITE)
		z.draw_circle(bh + Vector2(-2.5, -1), 1.0, Color(0.8, 0.1, 0.1))
		z.draw_circle(bh + Vector2(4.5, -1), 1.0, Color(0.8, 0.1, 0.1))
		z.draw_arc(bh + Vector2(1, 4), 4.0, 0.2, PI - 0.2, 8, col(Color("a01818")), 1.6)   # חיוך מצויר
		Art.oval(z, bh + Vector2(-5, 3), 2.0, 1.2, Color(0.95, 0.4, 0.4, 0.6), 0.0, Art.NONE)
		Art.oval(z, bh + Vector2(6, 3), 2.0, 1.2, Color(0.95, 0.4, 0.4, 0.6), 0.0, Art.NONE)
	else:
		Art.oval_shaded(z, head, 4.5, 5.0, sk, 0.0)
		z.draw_circle(head + Vector2(2.2, -0.5), 1.0, Color(1.0, 0.85, 0.3))
		z.draw_line(head + Vector2(0.5, 2.5), head + Vector2(4.2, 2.2), col(Color("2a0a0a")), 1.0)
		# כובע צילינדר מעוך
		Art.fill(z, PackedVector2Array([head + Vector2(-4, -4), head + Vector2(4, -4.5), head + Vector2(3.5, -11), head + Vector2(-2, -12)]), col(Color("1a1a22")), Art.OUTLINE, 0.8)
		z.draw_line(head + Vector2(-5, -4), head + Vector2(5, -4.5), col(Color("1a1a22")), 1.4)
		z.draw_line(head + Vector2(-3.5, -6), head + Vector2(3.5, -6.5), col(Color("e83a3a")), 1.0)
	end_draw()
	return true
