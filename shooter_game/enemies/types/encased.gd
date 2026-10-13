extends "res://enemies/zombie_type.gd"
# ============================================================
#  ENCASED (שלב 35, "SKULL GLACIER") - מטפס שקפא בתוך גוש קרח. נראה כמו עוד גוש קרח עם משהו בפנים.
#  "THEY LEARNED TO HIDE": לא זז ולא נושם. מחכה שתעבור אותו (פורץ מאחוריך) או שתעמוד צמוד אליו (BURST_R, NEAR_T) ->
#    CRACK  - הקרח נסדק (אזהרה CRACK_T: חריקה, רסיסים)
#    BURST  - פורץ החוצה ברסיסי קרח (נזק אם אתה צמוד) ומסתער עליך מאחור
#  הקרח בולע יריות (ICE_HP). שוברים את הקרח מרחוק -> הוא יוצא המום (DAZED_T, x1.5). אש / פיצוץ ממיסים מיד.
#  לשנות: ICE_HP, BURST_R, BEHIND_R, CRACK_T, DAZED_T.
# ============================================================

const SOUNDS := {
	"en_crack": [["N", 0, 0, 0.0, 0.25, 0.0, 14.0, 0.5, 0.7, 0, 0.6], ["S", 1800, 900, 0.0, 0.12, 0.0, 30.0, 0.2, 1.0, 0]],
	"en_burst": [["N", 0, 0, 0.0, 0.5, 0.0, 6.0, 0.9, 0.6, 0, 0.5], ["S", 2600, 700, 0.0, 0.35, 0.0, 9.0, 0.3, 1.0, 0], ["S", 90, 50, 0.0, 0.3, 0.0, 10.0, 0.5, 1.0, 0]],
}

const ICE_HP := 50
const BURST_R := 70.0
const BEHIND_R := 260.0
const CRACK_T := 0.55
const DAZED_T := 1.4
const NEAR_T := 0.8

enum { FROZEN, CRACK, DAZED, WALK }
var state := FROZEN
var ice := ICE_HP
var bursts := 0              # לבדיקות
var shattered := 0
var _st := 0.0
var _rush := 0.0
var _side := 0.0
var _near_t := 0.0
var _shape := 0


func stats() -> Dictionary:
	return {"name": "ENCASED", "hp": 32, "walk": 44.0, "chase": 96.0, "damage": 1, "bite_delay": 0.7, "scale": 1.0, "width": 1.05,
		"duck": 0.0, "cover": 0.0, "skin": Color("8aa0a8"), "shirt": Color("2a5a8a"), "pants": Color("3a3a48"), "shoe": Color("2a2a30"), "points": 440}


func setup() -> void:
	_shape = randi() % 3
	z._dir = -1.0 if randf() < 0.5 else 1.0


func brain_overrides() -> Dictionary:
	return {"aggression": 0.9}


func can_bite() -> bool:
	return state == WALK


func can_groan() -> bool:
	return state == WALK


func frozen() -> bool:
	return state == FROZEN or state == CRACK


func on_damage(amount: int, hit_pos: Vector2, _dir: Vector2, src: Dictionary) -> bool:
	if not frozen():
		return true
	var s := str(src.get("source", "bullet"))
	if s in ["fire", "flame", "molotov", "grenade", "explosion", "dynamite", "mine", "barrel", "artillery", "boss_lob"]:
		_shatter.call_deferred()
		return false
	ice -= maxi(hit_damage(amount, hit_pos, src), 1)
	Particles.burst(z.get_parent(), hit_pos, "snow", Vector2.UP, 3)
	if ice <= 0:
		_shatter.call_deferred()
	return false


func _shatter() -> void:   # הקרח נשבר מבחוץ: יוצא המום
	if z == null or not is_instance_valid(z) or z.dead or not frozen():
		return
	shattered += 1
	_break_fx(false)
	state = DAZED
	_st = DAZED_T
	z._popup("ICE SHATTERED", Color("c0e8ff"), 13, -80.0)


func _break_fx(hurt: bool) -> void:
	Sfx.play("en_burst", z.global_position, 1.0, 0.1, 3)
	Particles.burst(z.get_parent(), z.global_position + Vector2(0, -26), "spark", Vector2.UP, 14)
	Particles.burst(z.get_parent(), z.global_position + Vector2(0, -20), "snow", Vector2.ZERO, 12)
	var pl := player()
	if hurt and pl != null and not pl.dead and pl.global_position.distance_to(z.global_position) < BURST_R:
		pl.hurt(1, Vector2(signf(pl.global_position.x - z.global_position.x) * 1.5, -0.8))


func damage_mult(_zone: String, _src: Dictionary) -> float:
	return 1.5 if state == DAZED else 1.0


func physics(pl: Node, delta: float) -> bool:
	_st -= delta
	if z.dead:
		return false
	var has_pl: bool = pl != null and not pl.dead
	match state:
		FROZEN:
			if has_pl:
				var dx: float = pl.global_position.x - z.global_position.x
				var dy: float = absf(pl.global_position.y - z.global_position.y)
				if absf(dx) < 520.0 and dy < 80.0:
					if _side == 0.0 and absf(dx) > 60.0:
						_side = signf(dx)   # מאיזה צד הגעת
					# עברת אותו (אתה בצד השני) -> פורץ מאחוריך. עומד צמוד אליו יותר מ-NEAR_T -> פורץ עליך
					var passed: bool = _side != 0.0 and signf(dx) != _side and absf(dx) > 24.0 and absf(dx) < BEHIND_R
					_near_t = _near_t + delta if absf(dx) < BURST_R else 0.0
					if passed or _near_t > NEAR_T:
						state = CRACK
						_st = CRACK_T
						Sfx.play("en_crack", z.global_position, 0.0, 0.1, 3)
				elif absf(dx) > 700.0:
					_side = 0.0
			return _stay(delta)
		CRACK:
			if Engine.get_physics_frames() % 4 == 0:
				Particles.burst(z.get_parent(), z.global_position + Vector2(randf_range(-14, 14), -50.0), "snow", Vector2.DOWN, 1)
			if _st <= 0.0:
				bursts += 1
				_break_fx(true)
				state = WALK
				_rush = 2.0
				z._alert_t = 8.0
				z._rush_t = 2.0
				if has_pl:
					z._dir = signf(pl.global_position.x - z.global_position.x)
					z.velocity = Vector2(z._dir * 260.0, -220.0)
			return _stay(delta)
		DAZED:
			if _st <= 0.0:
				state = WALK
				z._alert_t = 6.0
			return _stay(delta)
	return false


func _stay(delta: float) -> bool:
	z.velocity.x = move_toward(z.velocity.x, 0.0, 900.0 * delta)
	if not z.is_on_floor():
		z.velocity.y += z.gravity * delta
	z.move_and_slide()
	return true


# ============================================================
#  ציור: מטפס במעיל פוך כחול, משקפי קרח, כפור על הגוף. קפוא = בתוך גוש קרח שקוף (נסדק)
# ============================================================
func draw() -> bool:
	begin_draw()
	var sk := col(z.skin)
	var coat := col(z.shirt)
	var p: float = z._walk_phase
	var f: Array = feet(4.5, 2.5)
	var hip := Vector2(0, -22)
	var sh := Vector2(1, -37)
	var head := sh + Vector2(3.5, -8)
	var arm_r := sh + Vector2(13, 2)
	var arm_l := sh + Vector2(-5.0 - sin(p) * 2.0, 15.0)
	if frozen():   # תנוחת קפיאה: יד אחת מושטת קדימה, אחת על הפנים
		f = [Vector2(5, 0), Vector2(-4, 0)]
		arm_r = sh + Vector2(14, -6)
		arm_l = head + Vector2(3, 3)
	z._leg(hip + Vector2(-2, 0), f[1], col(Art.shade(z.pants, 0.25)), sk, col(z.shoe))
	z._leg(hip + Vector2(2, 0), f[0], col(z.pants), sk, col(z.shoe))
	z._arm(sh + Vector2(-3, 1), arm_l, Art.shade(sk, 0.25), Art.shade(coat, 0.3))
	Art.fill_shaded(z, PackedVector2Array([sh + Vector2(-9, -1), sh + Vector2(9, 0), hip + Vector2(8, 3), hip + Vector2(-8, 3)]), coat, 0.15, 0.4)
	for q in 3:   # תפרי פוך
		z.draw_line(sh + Vector2(-8, 4.0 + float(q) * 5.0), sh + Vector2(8, 4.0 + float(q) * 5.0), col(Art.shade(z.shirt, 0.3)), 1.0)
	Art.oval_shaded(z, head, 5.2, 5.8, sk, 0.0)
	z.draw_rect(Rect2(head + Vector2(-5.5, -6.5), Vector2(11, 4)), col(Color("c03a2a")))   # כובע צמר אדום
	z.draw_rect(Rect2(head + Vector2(0, -2.5), Vector2(6, 3)), col(Color("1a2a3a")))   # משקפי קרח
	z.draw_line(head + Vector2(-5, -1), head + Vector2(0, -1), col(Color("1a1a1a")), 1.0)
	for q in 4:   # כפור על הגוף
		z.draw_circle(sh + Vector2(-6.0 + float(q) * 4.0, 2.0 + float(q % 2) * 8.0), 1.2, Color(0.9, 0.97, 1.0, 0.8))
	z._arm(sh + Vector2(3, 1), arm_r, sk, coat)
	if frozen() and not z.dead:   # גוש הקרח
		var k := 1.0 - float(ice) / float(ICE_HP)
		var shk := sin(z._time * 60.0) * 1.2 if state == CRACK else 0.0
		var blk := PackedVector2Array()
		var pts := [Vector2(-15, 1), Vector2(-17, -30), Vector2(-12, -56), Vector2(4, -60), Vector2(17, -52), Vector2(19, -18), Vector2(15, 1)]
		if _shape == 1:
			pts = [Vector2(-16, 1), Vector2(-14, -40), Vector2(-16, -58), Vector2(10, -62), Vector2(18, -40), Vector2(16, 1)]
		elif _shape == 2:
			pts = [Vector2(-18, 1), Vector2(-15, -48), Vector2(-4, -61), Vector2(14, -58), Vector2(20, -30), Vector2(17, 1)]
		for v in pts:
			blk.append(v + Vector2(shk, 0))
		z.draw_colored_polygon(blk, Color(0.62, 0.84, 0.98, 0.62))
		z.draw_colored_polygon(PackedVector2Array([blk[1] + Vector2(4, 0), blk[2] + Vector2(4, 4), blk[2] + Vector2(10, 4), blk[1] + Vector2(9, 8)]), Color(1, 1, 1, 0.35))
		z.draw_polyline(blk + PackedVector2Array([blk[0]]), Color(0.25, 0.45, 0.7, 0.9), 1.4)
		z.draw_rect(Rect2(blk[2].x, blk[2].y - 3.0, blk[3].x - blk[2].x + 4.0, 4.0), Color("eef4fa"))   # שלג על הראש
		if k > 0.3 or state == CRACK:   # סדקים
			z.draw_polyline(PackedVector2Array([Vector2(-6, -50), Vector2(-1, -38), Vector2(-7, -26), Vector2(-2, -14)]), Color(0.95, 1.0, 1.0, 0.9), 1.2)
		if k > 0.6 or state == CRACK:
			z.draw_polyline(PackedVector2Array([Vector2(12, -48), Vector2(6, -34), Vector2(12, -20), Vector2(8, -6)]), Color(0.95, 1.0, 1.0, 0.9), 1.2)
	end_draw()
	return true
