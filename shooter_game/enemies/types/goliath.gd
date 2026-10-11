extends "res://enemies/zombie_type.gd"
# ============================================================
#  GOLIATH (שלב 22, "THE DAM") - זומבי ענק (קצב בסינר עור). יורים בו - והוא מתפרק לפי הסדר:
#    קודם הידיים (יד קדמית, אחר כך אחורית), אחר כך הרגליים (אחת = קופץ, שתיים = זוחל), ובסוף הראש.
#    (לפי כמה חיים נשארו: LOSE_AT). כל חלק עף באמת (Limb) עם דם.
#  הוא משנה טקטיקה לפי מה שנשאר לו (חכם, לא סתם ספוג):
#    2 ידיים - SMASH: מרים את שתי הידיים (WINDUP) ומטיח בקרקע - נזק 2 + הדף + גל אבק. התרחק / קפוץ.
#    יד אחת - SWIPE: מכה מהירה יותר ביד שנשארה.
#    בלי ידיים - CHARGE: מוריד את הראש ומסתער עליך (גוף כמו איל ניגוח), ואז מסוחרר רגע.
#    רגל אחת - קופץ (לאט). בלי רגליים - זוחל אליך על הבטן ונושך.
#  מת = הראש עף.
#  בוס: THE BUTCHER - ענק יותר, הרבה חיים, אותו סדר.
#  לשנות: LOSE_AT, SMASH_*, CHARGE_*.
# ============================================================

const SOUNDS := {
	"gl_rip": [["N", 0, 0, 0.0, 0.22, 0.0, 12.0, 0.85, 0.4, 0], ["S", 120, 50, 0.0, 0.2, 0.0, 14.0, 0.6, 1.0, 0]],
	"gl_slam": {"drive": 2.4, "layers": [["S", 70, 35, 0.0, 0.45, 0.0, 6.0, 1.0, 1.0, 0], ["N", 0, 0, 0.0, 0.35, 0.0, 8.0, 0.7, 0.3, 0]]},
	"gl_roar": {"drive": 2.2, "layers": [["V", 90, 70, 0.0, 0.8, 0.05, 3.0, 0.9, 1.0, 0.08, 0, [300, 900, 25]], ["N", 0, 0, 0.0, 0.6, 0.05, 4.0, 0.4, 0.2, 0]]},
}

const LOSE_AT := [0.8, 0.64, 0.46, 0.3]   # חלק החיים שבו נתלש: יד קדמית, יד אחורית, רגל אחורית, רגל קדמית
const ORDER := ["arm_f", "arm_b", "leg_b", "leg_f"]
const SMASH_RANGE := 74.0
const SMASH_WINDUP := 0.55
const SMASH_CD := 1.6
const CHARGE_RANGE := Vector2(110.0, 420.0)
const CHARGE_T := 0.9
const CHARGE_SPEED := 300.0
const CRAWL_SPEED := 55.0

enum { WALK, WINDUP, SMASH, CHARGE, STUN }
var state := WALK
var parts := {"arm_f": true, "arm_b": true, "leg_b": true, "leg_f": true}
var lost := 0              # לבדיקות
var smashes := 0
var charges := 0
var crawling := false
var _st := 0.0
var _cd := 1.0
var _hit_done := false


func _boss() -> bool:
	return z != null and float(z.chase_range) > 600.0


func stats() -> Dictionary:
	if _boss():
		return {"name": "GOLIATH", "hp": 420, "walk": 34.0, "chase": 64.0, "damage": 2, "bite_delay": 1.0, "scale": 2.4, "width": 1.3,
			"duck": 0.0, "cover": 0.0, "skin": Color("8a9a7e"), "shirt": Color("6a4a32"), "pants": Color("3a3430"), "shoe": Color("2a2420"),
			"points": 1200, "boss": true, "boss_name": "THE BUTCHER - TAKE HIM APART", "ragdoll": false}
	return {"name": "GOLIATH", "hp": 150, "walk": 34.0, "chase": 62.0, "damage": 2, "bite_delay": 1.1, "scale": 1.85, "width": 1.25,
		"duck": 0.0, "cover": 0.0, "skin": Color("8a9a7e"), "shirt": Color("6a4a32"), "pants": Color("3a3430"), "shoe": Color("2a2420"), "points": 700, "ragdoll": false}


func brain_overrides() -> Dictionary:
	return {"aggression": 0.9, "flank_probability": -0.5}


func arms() -> int:
	return int(parts.arm_f) + int(parts.arm_b)


func legs() -> int:
	return int(parts.leg_f) + int(parts.leg_b)


func can_bite() -> bool:
	return crawling and state == WALK   # על הרגליים הוא תוקף בהתקפות שלו


func on_damage(_amount: int, _hit_pos: Vector2, dir: Vector2, _src: Dictionary) -> bool:
	_check_parts.call_deferred(dir)   # אחרי שהחיים ירדו
	return true


func _check_parts(dir: Vector2) -> void:
	if z == null or not is_instance_valid(z) or z.dead:
		return
	var k: float = float(z.hp) / float(z.max_hp)
	for i in ORDER.size():
		if k <= LOSE_AT[i] and parts[ORDER[i]]:
			_rip(ORDER[i], dir)


func _rip(p: String, dir: Vector2) -> void:
	parts[p] = false
	lost += 1
	var lp: Vector2 = {"arm_f": Vector2(10, -38), "arm_b": Vector2(-8, -38), "leg_b": Vector2(-4, -12), "leg_f": Vector2(4, -12), "head": Vector2(3, -56)}[p]
	if crawling:
		lp.y = -10.0
	var gp: Vector2 = z.global_position + Vector2(lp.x * z._dir * z.wf, lp.y) * z.sc
	var l := Limb.new()
	l.kind = "arm" if p.begins_with("arm") else ("leg" if p.begins_with("leg") else "head")
	l.skin = z.skin
	l.cloth = z.shirt if l.kind == "arm" else z.pants
	l.shoe = z.shoe
	l.sc = z.sc
	l.face = z._dir
	z.get_parent().add_child(l)
	l.global_position = gp
	l.velocity = Vector2(signf(dir.x if dir.x != 0.0 else -z._dir) * randf_range(160.0, 280.0), -randf_range(220.0, 380.0))
	z._spray_blood(gp, Vector2(dir.x, -0.5), 12, 300.0)
	Sfx.play("gl_rip", gp, 2.0, 0.12, 3)
	if Art.on_screen(z, z.global_position) and p != "head":
		z._popup({"arm_f": "ARM OFF!", "arm_b": "NO ARMS!", "leg_b": "LEG OFF!", "leg_f": "CRAWLING!"}[p], Color("ffb070"), 15, -110.0)
	if state == WINDUP and arms() == 0:
		state = WALK
	if p.begins_with("leg"):
		if legs() == 1:
			z._one_leg = true
			z._hop_t = 0.4
		elif legs() == 0:
			_start_crawl()


func _start_crawl() -> void:
	crawling = true
	z._one_leg = false
	state = WALK
	var r := z._shape.shape as RectangleShape2D
	r.size = Vector2(56.0, 24.0) * z.sc
	z._shape.position = Vector2(0.0, -12.0 * z.sc)


func on_death() -> void:
	_rip("head", Vector2(-z._dir, -1.0))   # הראש עף
	for k in parts.keys():
		if parts[k]:
			_rip(k, Vector2(randf_range(-1.0, 1.0), -0.5))


func physics(pl: Node, delta: float) -> bool:
	if z.dead:
		return false
	_cd -= delta
	_st -= delta
	var has_pl: bool = pl != null and not pl.dead
	if crawling:
		if not has_pl:
			return _stop(delta)
		var dx: float = pl.global_position.x - z.global_position.x
		z._dir = signf(dx) if dx != 0.0 else z._dir
		z.velocity.x = move_toward(z.velocity.x, z._dir * CRAWL_SPEED * (0.0 if absf(dx) < 26.0 else 1.0), 600.0 * delta)
		if not z.is_on_floor():
			z.velocity.y += z.gravity * delta
		z.move_and_slide()
		z._walk_phase += delta * 6.0
		if absf(dx) < 34.0 * z.sc and absf(pl.global_position.y - z.global_position.y) < 40.0 and z._attack_t <= 0.0:
			z._attack_t = 1.0
			z._bite_anim = 0.25
			pl.hurt(1, Vector2(z._dir, 0.0))
		return true
	match state:
		WALK:
			if _cd <= 0.0 and has_pl and z.is_on_floor():
				var d: Vector2 = pl.global_position - z.global_position
				if absf(d.y) < 80.0:
					if arms() > 0 and absf(d.x) < SMASH_RANGE * z.sc:
						state = WINDUP
						_st = SMASH_WINDUP * (0.7 if arms() == 1 else 1.0)
						z._dir = signf(d.x) if d.x != 0.0 else z._dir
						Sfx.play("gl_roar", z.global_position, 0.0, 0.1, 2)
						return _stop(delta)
					if arms() == 0 and legs() == 2 and absf(d.x) > CHARGE_RANGE.x and absf(d.x) < CHARGE_RANGE.y:
						state = CHARGE
						charges += 1
						_st = CHARGE_T
						_hit_done = false
						z._dir = signf(d.x)
						Sfx.play("gl_roar", z.global_position, 3.0, 0.1, 2)
						return true
			return false
		WINDUP:
			if _st <= 0.0:
				_smash(pl)
			return _stop(delta)
		SMASH:
			if _st <= 0.0:
				state = WALK
				_cd = SMASH_CD * (0.7 if arms() == 1 else 1.0)
			return _stop(delta)
		CHARGE:
			z.velocity.x = z._dir * CHARGE_SPEED
			if not z.is_on_floor():
				z.velocity.y += z.gravity * delta
			z.move_and_slide()
			z._walk_phase += delta * absf(z.velocity.x) * 0.075 / z.sc
			if has_pl and not _hit_done:
				var r: Rect2 = pl.body_rect().grow(6.0)
				if r.intersects(Rect2(z.global_position + Vector2(-14.0, -50.0) * z.sc, Vector2(28.0, 50.0) * z.sc)):
					_hit_done = true
					pl.hurt(2, Vector2(z._dir * 2.0, -0.6))
			if _st <= 0.0 or z.is_on_wall():
				state = STUN
				_st = 0.9
				if z.is_on_wall():
					_shake(5.0)
			return true
		STUN:
			if _st <= 0.0:
				state = WALK
				_cd = 1.2
			return _stop(delta)
	return false


func _stop(delta: float) -> bool:
	z.velocity.x = move_toward(z.velocity.x, 0.0, 900.0 * delta)
	if not z.is_on_floor():
		z.velocity.y += z.gravity * delta
	z.move_and_slide()
	return true


func _smash(pl: Node) -> void:
	state = SMASH
	_st = 0.35
	smashes += 1
	var reach: float = (SMASH_RANGE + 10.0) * float(z.sc)
	var c: Vector2 = z.global_position + Vector2(z._dir * reach * 0.6, 0.0)
	Sfx.play("gl_slam", c, 4.0, 0.08, 2)
	if Art.on_screen(z, z.global_position):
		Particles.burst(z.get_parent(), c, "smoke", Vector2.UP, 10)
		_shake(7.0 if arms() == 2 else 4.0)
	if pl != null and not pl.dead:
		var dx: float = pl.global_position.x - z.global_position.x
		if signf(dx) == z._dir and absf(dx) < reach and absf(pl.global_position.y - z.global_position.y) < 60.0 and pl.is_on_floor():
			pl.hurt(2 if arms() == 2 else 1, Vector2(z._dir * 2.2, -1.0))


func _shake(s: float) -> void:
	var cam: Camera2D = z.get_viewport().get_camera_2d()
	if cam != null and cam.has_method("shake"):
		cam.shake(s, 0.3)


# ============================================================
#  ציור: גוף ענק ונפוח, ראש קטן, סינר עור מוכתם, אמות ענקיות. חלק שנתלש = גדם מדמם.
# ============================================================
func draw() -> bool:
	begin_draw()
	var sk := col(z.skin)
	var skd := col(Art.shade(z.skin, 0.25))
	var apron := col(z.shirt)
	var blood := Color(0.45, 0.05, 0.05)
	var p: float = z._walk_phase
	if crawling and not z.dead:
		_draw_crawl(sk, skd, apron, blood, p)
		end_draw()
		return true
	var f: Array = feet(4.0, 2.0)
	var raise := 0.0
	if state == WINDUP:
		raise = 1.0 - clampf(_st / SMASH_WINDUP, 0.0, 1.0)
	elif state == SMASH:
		raise = -0.6
	var lean := 6.0 if state == CHARGE else (3.0 if state == STUN else 0.0)
	var hip := Vector2(0.0, -21.0)
	var sh := Vector2(2.0 + lean, -38.0 + lean * 0.4)
	var head := sh + Vector2(5.0 + lean * 0.5, -7.0 + lean * 0.3)
	# רגליים (או גדם)
	if parts.leg_b:
		z._leg(hip + Vector2(-4, 0), f[1], col(Art.shade(z.pants, 0.25)), skd, col(z.shoe))
	else:
		_stump(hip + Vector2(-4, 2), blood)
	if parts.leg_f:
		z._leg(hip + Vector2(4, 0), f[0], col(z.pants), sk, col(z.shoe))
	else:
		_stump(hip + Vector2(4, 2), blood)
	# יד אחורית
	var bh := sh + Vector2(-8.0 - sin(p) * 2.0, 16.0).lerp(sh + Vector2(-2, -18), raise if raise > 0.0 else 0.0)
	if raise < 0.0:
		bh = sh + Vector2(14, 20)
	if parts.arm_b:
		_big_arm(sh + Vector2(-7, 2), bh, skd, Art.shade(apron, 0.3))
	else:
		_stump(sh + Vector2(-8, 3), blood)
	# גוף נפוח + סינר
	var torso := PackedVector2Array([sh + Vector2(-11, -3), sh + Vector2(10, -2), sh + Vector2(13, 8), hip + Vector2(10, 2), hip + Vector2(-9, 3), sh + Vector2(-13, 9)])
	Art.fill_shaded(z, torso, sk, 0.15, 0.4)
	Art.fill_shaded(z, PackedVector2Array([sh + Vector2(-6, 4), sh + Vector2(9, 4), hip + Vector2(9, 9), hip + Vector2(-7, 9)]), apron, 0.12, 0.4)
	z.draw_line(sh + Vector2(-6, 4), sh + Vector2(-3, -4), col(Color("3a2a1e")), 1.4)   # רצועת הסינר
	z.draw_circle(sh + Vector2(3, 12), 3.0, Color(blood, 0.7))
	z.draw_circle(hip + Vector2(-2, 5), 2.2, Color(blood, 0.6))
	z.draw_line(sh + Vector2(-9, 0), sh + Vector2(-4, 6), Color(0.3, 0.1, 0.1, 0.6), 1.2)   # תפרים
	# ראש קטן על צוואר עבה
	Art.oval_shaded(z, head, 5.0, 5.4, sk, 0.0)
	z.draw_line(head + Vector2(-5, -2), head + Vector2(4, -3), col(Color("2a2420")), 1.4)   # גבה
	if not z.dead:
		z.draw_circle(head + Vector2(3.0, -0.5), 1.0, Color(1.0, 0.85, 0.3))
	Art.fill(z, PackedVector2Array([head + Vector2(0, 2.5), head + Vector2(5.5, 2.0), head + Vector2(5, 4.6 + (1.5 if state == WINDUP else 0.0)), head + Vector2(0.5, 4.6)]), col(Color("2a0a0a")), Art.OUTLINE, 0.7)
	# יד קדמית ענקית
	var fh := sh + Vector2(12.0 + sin(p) * 2.0, 15.0).lerp(sh + Vector2(6, -20), raise if raise > 0.0 else 0.0)
	if raise < 0.0:
		fh = sh + Vector2(22, 22)
	if state == CHARGE:
		fh = sh + Vector2(4, 16)
	if parts.arm_f:
		_big_arm(sh + Vector2(8, 2), fh, sk, apron)
	else:
		_stump(sh + Vector2(9, 3), blood)
	end_draw()
	return true


func _big_arm(s: Vector2, hand: Vector2, sk: Color, _sleeve: Color) -> void:
	var el := s.lerp(hand, 0.5) + Vector2(-2, 3)
	Art.limb(z, PackedVector2Array([s, el]), 6.0, sk)
	Art.limb(z, PackedVector2Array([el, hand]), 7.5, sk)   # אמה עבה
	Art.oval_shaded(z, hand, 5.0, 4.4, sk, 0.0)


func _stump(at: Vector2, blood: Color) -> void:
	z.draw_circle(at, 3.6, Art.OUTLINE)
	z.draw_circle(at, 2.8, blood)
	if not z.dead and int(z._time * 6.0) % 3 == 0:   # טפטוף
		z.draw_circle(at + Vector2(0, 4 + fposmod(z._time * 20.0, 8.0)), 1.0, blood)


# זוחל על הבטן: גוף שוכב, הראש קדימה, גדמים
func _draw_crawl(sk: Color, _skd: Color, apron: Color, blood: Color, p: float) -> void:
	var wig := sin(p) * 2.0
	var body := PackedVector2Array([Vector2(-20, -2), Vector2(-16, -16), Vector2(8, -18 + wig * 0.5), Vector2(16, -10), Vector2(14, 0)])
	Art.fill_shaded(z, body, sk, 0.15, 0.4)
	Art.fill_shaded(z, PackedVector2Array([Vector2(-14, -4), Vector2(6, -6), Vector2(8, 0), Vector2(-14, 0)]), apron, 0.12, 0.4)
	for s in [Vector2(-20, -4), Vector2(-18, -10), Vector2(12, -14), Vector2(6, -16)]:
		_stump(s, blood)
	var head := Vector2(22, -10 + wig)
	Art.oval_shaded(z, head, 5.0, 5.0, sk, 0.0)
	if not z.dead:
		z.draw_circle(head + Vector2(2, -1), 1.0, Color(1.0, 0.85, 0.3))
	Art.fill(z, PackedVector2Array([head + Vector2(1, 2), head + Vector2(5, 1.5), head + Vector2(4.5, 4.5 + (1.5 if z._bite_anim > 0.0 else 0.0)), head + Vector2(1.5, 4.5)]), Color("2a0a0a"), Art.OUTLINE, 0.7)


# ---- חלק שנתלש ועף (יד / רגל / ראש) ----
class Limb extends Node2D:
	var kind := "arm"
	var skin := Color.GRAY
	var cloth := Color.BROWN
	var shoe := Color.BLACK
	var sc := 1.0
	var face := 1.0
	var velocity := Vector2.ZERO
	var spin := 0.0
	var life := 10.0
	var _rest := false

	func _ready() -> void:
		z_index = 4
		spin = randf_range(-9.0, 9.0)

	func _physics_process(delta: float) -> void:
		life -= delta
		if life <= 0.0:
			queue_free()
			return
		if _rest:
			if life < 1.0:
				queue_redraw()
			return
		velocity.y += 1000.0 * delta
		var to := global_position + velocity * delta
		var hit := get_world_2d().direct_space_state.intersect_ray(PhysicsRayQueryParameters2D.create(global_position, to + Vector2(0, 4), 1 | 16))
		if hit and hit.normal != Vector2.ZERO:
			global_position = hit.position + hit.normal * 3.0
			velocity = velocity.bounce(hit.normal) * 0.3
			velocity.x *= 0.6
			spin *= 0.4
			if velocity.length() < 60.0:
				_rest = true
				rotation = snappedf(rotation, PI) + randf_range(-0.2, 0.2)
		else:
			global_position = to
			rotation += spin * delta
		queue_redraw()

	func _draw() -> void:
		var a := clampf(life, 0.0, 1.0)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(face * sc, sc))
		var sk := Color(skin, a)
		var blood := Color(0.45, 0.05, 0.05, a)
		var ol := Color(Art.OUTLINE, a)
		match kind:
			"arm":
				draw_line(Vector2(-9, 0), Vector2(0, 1), ol, 8.0)
				draw_line(Vector2(-9, 0), Vector2(0, 1), sk, 6.0)
				draw_line(Vector2(0, 1), Vector2(9, 0), ol, 9.5)
				draw_line(Vector2(0, 1), Vector2(9, 0), sk, 7.5)
				draw_circle(Vector2(11, 0), 4.6, sk)
				draw_circle(Vector2(-9, 0), 3.0, blood)
			"leg":
				draw_line(Vector2(0, -10), Vector2(0, 6), ol, 8.0)
				draw_line(Vector2(0, -10), Vector2(0, 6), Color(cloth, a), 6.0)
				draw_rect(Rect2(Vector2(-3, 6), Vector2(8, 4)), Color(shoe, a))
				draw_circle(Vector2(0, -10), 3.0, blood)
			_:   # ראש
				draw_circle(Vector2.ZERO, 6.2, ol)
				draw_circle(Vector2.ZERO, 5.2, sk)
				draw_circle(Vector2(2.5, -1), 1.0, Color(0.2, 0.2, 0.2, a))
				draw_circle(Vector2(0, 5), 2.6, blood)
