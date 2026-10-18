extends "res://enemies/zombie_type.gd"
# ============================================================
#  FROSTBITE (שלב 30, "FROZEN VILLAGE") - זומבי שקפא בתוך שריון קרח: גושי קרח על הכתפיים והראש, נטיפים, נשימה קפואה.
#  שריון קרח (ICE) בולע את הנזק עד שהוא מתנפץ. אש / פיצוץ / לייזר שוברים אותו מהר (ICE_FIRE).
#  אחרי שהקרח נשבר - חלש (HP קטן) ומהיר יותר.
#  נשיכה = "ידיים קפואות" (CHILL): איטי והכוונת רועדת. מתחממים ליד חבית אש (effects/s30_decor.gd Brazier).
#  בוס: THE FROZEN ONE - קרח עבה, והקרח צומח מחדש (REGROW) אם לא פוגעים בו.
#  לשנות: ICE, ICE_FIRE, CHILL, REGROW.
# ============================================================

const SOUNDS := {
	"fb_shatter": [["N", 0, 0, 0.0, 0.05, 0.0, 120.0, 1.0, 1.0, 0], ["S", 3200, 2400, 0.0, 0.25, 0.0, 14.0, 0.25, 1.0, 0], ["C", 0, 0, 0.0, 0.3, 0.0, 10.0, 0.7, 1.0, 0]],
	"fb_chip": [["S", 2600, 2200, 0.0, 0.06, 0.0, 50.0, 0.25, 1.0, 0], ["C", 0, 0, 0.0, 0.06, 0.0, 60.0, 0.4, 1.0, 0]],
}

const ICE := 45
const ICE_FIRE := 3.0        # כמה מהר אש / פיצוץ שוברים את הקרח
const CHILL := 2.2
const REGROW := 5.0          # בוס: אחרי כמה שניות בלי פגיעה הקרח צומח

var ice := 0.0
var ice_max := 0.0
var shattered := 0           # לבדיקות
var chills := 0
var _since_hit := 0.0
var _breath := 0.0


func _boss() -> bool:
	return z != null and float(z.chase_range) > 600.0


func stats() -> Dictionary:
	if _boss():
		return {"name": "FROSTBITE", "hp": 300, "walk": 40.0, "chase": 78.0, "damage": 2, "bite_delay": 0.9, "scale": 1.75, "width": 1.15,
			"duck": 0.0, "cover": 0.0, "skin": Color("8aa8c0"), "shirt": Color("4a5a6a"), "pants": Color("3a4450"), "shoe": Color("2a3038"),
			"points": 1300, "boss": true, "boss_name": "THE FROZEN ONE - FIRE BREAKS ICE"}
	return {"name": "FROSTBITE", "hp": 24, "walk": 38.0, "chase": 74.0, "damage": 1, "bite_delay": 0.9, "scale": 1.08, "width": 1.05,
		"duck": 0.0, "cover": 0.0, "skin": Color("8aa8c0"), "shirt": Color("4a5a6a"), "pants": Color("3a4450"), "shoe": Color("2a3038"), "points": 450}


func setup() -> void:
	ice_max = float(ICE) * (6.0 if _boss() else 1.0)
	ice = ice_max


func on_damage(amount: int, hit_pos: Vector2, _dir: Vector2, src: Dictionary) -> bool:
	_since_hit = 0.0
	if ice <= 0.0:
		return true
	var s := str(src.get("source", ""))
	var k := 1.0
	if s in ["fire", "grenade", "explosion", "dynamite", "mine", "artillery", "laser", "mech", "barrel"]:
		k = ICE_FIRE
	var dmg := float(hit_damage(amount, hit_pos, src))
	ice -= dmg * k
	Particles.burst(z.get_parent(), hit_pos, "spark", Vector2.UP, 4)
	if ice <= 0.0:
		ice = 0.0
		shattered += 1
		Sfx.play("fb_shatter", z.global_position, 4.0, 0.1, 2)
		Particles.burst(z.get_parent(), z.global_position + Vector2(0, -30) * z.sc, "spark", Vector2.UP, 16)
		z._popup("SHATTERED!", Color("a0e0ff"), 15, -80.0)
	else:
		Sfx.play("fb_chip", hit_pos, -4.0, 0.15, 3)
	return false   # הקרח בלע את הפגיעה


func damage_mult(_zone: String, _src: Dictionary) -> float:
	return 1.0


func logic(_pl: Node, _d: Vector2, _delta: float, speed: float) -> float:
	return speed * (1.0 if ice > 0.0 else 1.35)   # בלי קרח - מהיר יותר


func on_bite(pl: Node) -> void:   # ידיים קפואות
	chills += 1
	if float(pl._daze_t) <= 0.0:
		pl._say("FROZEN HANDS!", Color("a0d8ff"))
	pl._daze_t = maxf(float(pl._daze_t), CHILL * (1.4 if _boss() else 1.0))


func physics(_pl: Node, delta: float) -> bool:
	_since_hit += delta
	_breath -= delta
	if z.dead:
		return false
	if _boss() and ice < ice_max and _since_hit > REGROW:   # הקרח צומח מחדש
		ice = minf(ice_max, ice + ice_max * 0.25 * delta)
	if _breath <= 0.0 and Art.on_screen(z, z.global_position):
		_breath = randf_range(0.8, 1.4)
		Particles.burst(z.get_parent(), z.global_position + Vector2(z._dir * 9.0, -46.0) * z.sc, "smoke", Vector2(z._dir, -0.3), 1)
	return false


# ============================================================
#  ציור: גוף כחלחל, בגדים קפואים, גושי קרח שקופים (נעלמים כשהקרח נשבר), נטיפים
# ============================================================
func draw() -> bool:
	begin_draw()
	var sk := col(z.skin)
	var shirt := col(z.shirt)
	var p: float = z._walk_phase
	var f: Array = feet(4.5, 2.0)
	var hip := Vector2(0, -22)
	var sh := Vector2(1, -38)
	var head := sh + Vector2(3.5, -8)
	z._leg(hip + Vector2(-2, 0), f[1], col(Art.shade(z.pants, 0.25)), sk, col(z.shoe))
	z._leg(hip + Vector2(2, 0), f[0], col(z.pants), sk, col(z.shoe))
	z._arm(sh + Vector2(-3, 1), sh + Vector2(-5.0 - sin(p) * 2.0, 15.0), Art.shade(sk, 0.25), Art.shade(shirt, 0.3))
	Art.fill_shaded(z, PackedVector2Array([sh + Vector2(-7, -1), sh + Vector2(7, 0), hip + Vector2(6, 2), hip + Vector2(-6, 2)]), shirt, 0.12, 0.4)
	for q in 3:   # כפור על הבגדים
		DrawBatch.line(z, sh + Vector2(-5.0 + float(q) * 4.0, 2), sh + Vector2(-4.0 + float(q) * 4.0, 7), col(Color(0.9, 0.95, 1.0, 0.6)), 1.0)
	Art.oval_shaded(z, head, 5.6, 6.0, sk, 0.0)
	face(head, Vector2(3.0, -0.5))
	if not z.dead:
		DrawBatch.circle(z, head + Vector2(3.5, -1.0), 1.0, Color(0.6, 0.9, 1.0))
	DrawBatch.line(z, head + Vector2(0, 3), head + Vector2(5, 3), col(Color("2a3a4a")), 1.2)
	z._arm(sh + Vector2(3, 1), sh + Vector2(9.0 + sin(p) * 3.0, 14.0), sk, shirt)
	var k := clampf(ice / maxf(ice_max, 1.0), 0.0, 1.0)
	if k > 0.0 and not z.dead:   # שריון קרח
		var ic := Color(0.75, 0.9, 1.0, 0.45 + 0.25 * k)
		var edge := Color(0.95, 1.0, 1.0, 0.85)
		var chunks := [[sh + Vector2(-8, -2), 7.0], [sh + Vector2(8, -1), 6.5], [head + Vector2(-1, -5), 7.0], [hip + Vector2(0, -6), 8.0], [sh + Vector2(10, 12), 5.0]]
		for i in chunks.size():
			if float(i) / float(chunks.size()) > k + 0.1:
				continue
			var c: Vector2 = chunks[i][0]
			var r: float = chunks[i][1]
			var pts := PackedVector2Array()
			for a in 6:
				pts.append(c + Vector2.from_angle(float(a) * TAU / 6.0 + float(i)) * r * (0.8 + 0.25 * float((a + i) % 3)))
			DrawBatch.colored_polygon(z, pts, ic)
			DrawBatch.polyline(z, pts + PackedVector2Array([pts[0]]), edge, 1.0)
			DrawBatch.line(z, c + Vector2(-r * 0.3, -r * 0.3), c + Vector2(r * 0.1, -r * 0.5), Color(1, 1, 1, 0.8), 1.0)
		for q in 4:   # נטיפים מהזרועות
			var ip := sh + Vector2(-8.0 + float(q) * 5.0, 6.0)
			DrawBatch.colored_polygon(z, PackedVector2Array([ip + Vector2(-1.5, 0), ip + Vector2(0, 5), ip + Vector2(1.5, 0)]), edge)
	end_draw()
	return true
