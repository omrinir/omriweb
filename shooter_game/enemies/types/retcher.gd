extends "res://enemies/zombie_type.gd"
# ============================================================
#  RETCHER (שלב 14, צפון-מזרח) - טבח ענק ונפוח של מפעל השימורים. הקיא שלו = הנשק.
#  צללית: ענק, בטן עגולה ענקית בגופייה מוכתמת וסינר גומי, ראש קטן, ידיים עבות, רגליים דקות.
#  מחזור:
#    WALK    - מתקרב לאט (המוח מזיז אותו).
#    HEAVE   - הבטן מתנפחת ופועמת, הראש נזרק לאחור, קולות הקאה (HEAVE_T) = אזהרה.
#              ירייה בבטן הנפוחה = נזק x1.6. 3 פגיעות בבטן = נחנק (הקיא נשפך עליו) ומתנודד.
#    PUKE    - זרם קיא בקשת לכיוונך (גושים אמיתיים עם כבידה): פגיעה = לב, ועל הריצפה = שלוליות
#              צורבות (environment/acid_pool.gd בצבע צהוב-ירוק) שנשארות כמה שניות.
#    RECOVER - מתכופף ומנגב את הפה (חלון לירות בו).
#  בוס: "THE BILGE KING" - ענק יותר, שני זרמים, שלוליות רחבות.
#  צלילים: "ret_gag" (הקאה), "ret_puke" (זרם רטוב), "ret_splat".
#  לשנות: RANGE, HEAVE_T, PUKE_T, BLOB_EVERY, CD.
# ============================================================

const SOUNDS := {
	"ret_gag": {"drive": 2.0, "layers": [["V", 140, 95, 0.0, 0.55, 0.05, 3.0, 0.7, 1.0, 0.08, 0, [400, 700, 50]], ["N", 0, 0, 0.1, 0.4, 0.05, 6.0, 0.35, 0.25, 0]]},
	"ret_puke": [["N", 0, 0, 0.0, 1.1, 0.05, 1.2, 0.8, 0.3, 0, 0.4], ["V", 110, 80, 0.0, 0.9, 0.05, 2.0, 0.45, 1.0, 0.1, 0, [350, 600, 40]]],
	"ret_splat": [["N", 0, 0, 0.0, 0.12, 0.0, 22.0, 0.6, 0.35, 0]],
}

const RANGE := Vector2(70.0, 300.0)
const HEAVE_T := 0.8
const PUKE_T := 1.3
const RECOVER_T := 1.0
const BLOB_EVERY := 0.045
const CD := Vector2(2.6, 4.0)
const CHOKE_HITS := 3

enum { WALK, HEAVE, PUKE, RECOVER }
var state := WALK
var pukes := 0               # לבדיקות
var chokes := 0
var hits := 0                # כמה פעמים הקיא פגע בשחקן
var _st := 0.0
var _cd := 1.5
var _blob_t := 0.0
var _belly_hits := 0
var _hit_cd := 0.0
var _aim_x := 200.0
var _mist: CPUParticles2D


func _boss() -> bool:
	return z != null and float(z.chase_range) > 600.0


func stats() -> Dictionary:
	if _boss():
		return {"name": "RETCHER", "hp": 220, "walk": 26.0, "chase": 50.0, "damage": 2, "bite_delay": 1.2, "scale": 1.9, "width": 1.55,
			"duck": 0.0, "cover": 0.0, "skin": Color("a8b088"), "shirt": Color("d8d0b8"), "pants": Color("3a3a40"), "shoe": Color("201c18"),
			"points": 900, "boss": true, "boss_name": "THE BILGE KING", "ragdoll": false}
	return {"name": "RETCHER", "hp": 80, "walk": 30.0, "chase": 56.0, "damage": 2, "bite_delay": 1.1, "scale": 1.45, "width": 1.5,
		"duck": 0.0, "cover": 0.0, "skin": Color("a3ac84"), "shirt": Color("d8d0b8"), "pants": Color("3a3a40"), "shoe": Color("201c18"),
		"points": 450, "ragdoll": false}


func brain_overrides() -> Dictionary:
	return {"aggression": 0.3, "keep_range": 170.0}


func can_bite() -> bool:
	return state == WALK


func _mouth() -> Vector2:
	return z.global_position + Vector2(z._dir * 9.0 * z.wf, -52.0) * z.sc


func physics(pl: Node, delta: float) -> bool:
	_cd -= delta
	_st -= delta
	_hit_cd -= delta
	if _mist == null:
		_make_mist()
	_mist.emitting = state == PUKE and not z.dead
	if _mist.emitting:
		_mist.global_position = _mouth()
		_mist.direction = Vector2(z._dir, 0.35)
	if state == WALK:
		if _cd <= 0.0 and pl != null and not pl.dead and z.is_on_floor():
			var d: Vector2 = pl.global_position - z.global_position
			var sees: bool = z.brain == null or z.brain.sees
			if sees and absf(d.x) > RANGE.x * z.sc * 0.7 and absf(d.x) < RANGE.y * (1.4 if _boss() else 1.0) and absf(d.y) < 130.0:
				state = HEAVE
				_st = HEAVE_T
				_belly_hits = 0
				z._dir = signf(d.x) if d.x != 0.0 else z._dir
				Sfx.play("ret_gag", z.global_position, 1.0, 0.1, 2)
				return _stay(delta)
		return false
	match state:
		HEAVE:
			if _st <= 0.0:
				state = PUKE
				_st = PUKE_T * (1.3 if _boss() else 1.0)
				pukes += 1
				_aim_x = clampf(absf(pl.global_position.x - z.global_position.x), 90.0, RANGE.y * 1.3) if pl != null else 200.0
				Sfx.play("ret_puke", z.global_position, 2.0, 0.05, 2)
				Game.story.emit("puke", {"z": z})
		PUKE:
			_blob_t -= delta
			while _blob_t <= 0.0:
				_blob_t += BLOB_EVERY * (0.7 if _boss() else 1.0)
				_spit(1.0)
				if _boss():
					_spit(0.55)   # זרם שני קצר
			if _st <= 0.0:
				state = RECOVER
				_st = RECOVER_T
		RECOVER:
			if _st <= 0.0:
				state = WALK
				_cd = randf_range(CD.x, CD.y)
	return _stay(delta)


func _stay(delta: float) -> bool:
	z.velocity.x = move_toward(z.velocity.x, 0.0, 700.0 * delta)
	if not z.is_on_floor():
		z.velocity.y += z.gravity * delta
	z.move_and_slide()
	return true


# גוש קיא אחד בקשת
func _spit(reach: float) -> void:
	var b := Bile.new()
	b.owner_z = self
	var k := (1.0 - _st / (PUKE_T * (1.3 if _boss() else 1.0)))   # הזרם "מטאטא" קצת קדימה
	var vx := _aim_x * reach * randf_range(1.2, 1.7) * (0.85 + 0.3 * k)
	b.velocity = Vector2(z._dir * vx, -randf_range(140.0, 230.0))
	b.big = _boss()
	z.get_parent().add_child(b)
	b.global_position = _mouth() + Vector2(z._dir * 4.0, 0)


func blob_hit(pl: Node, dirx: float) -> void:
	if _hit_cd > 0.0:
		return
	_hit_cd = 0.9
	hits += 1
	pl.hurt(z.damage if _boss() else 1, Vector2(dirx, 0.0))
	Game.story.emit("puked", {"z": z})


func _make_mist() -> void:
	_mist = CPUParticles2D.new()
	_mist.local_coords = false
	_mist.amount = 60
	_mist.lifetime = 0.45
	_mist.spread = 22.0
	_mist.gravity = Vector2(0, 500)
	_mist.initial_velocity_min = 120.0
	_mist.initial_velocity_max = 260.0
	_mist.scale_amount_min = 1.5
	_mist.scale_amount_max = 3.5
	var g := Gradient.new()
	g.set_color(0, Color(0.85, 0.9, 0.35, 0.95))
	g.set_color(1, Color(0.55, 0.6, 0.2, 0.0))
	_mist.color_ramp = g
	_mist.emitting = false
	z.add_child(_mist)


# נקודת תורפה: הבטן הנפוחה בזמן ההקאה
func damage_mult(zone: String, _src: Dictionary) -> float:
	if state == HEAVE and zone == "body":
		return 1.6
	return 1.0


func on_damage(_amount: int, hit_pos: Vector2, _dir: Vector2, _src: Dictionary) -> bool:
	if state == HEAVE:
		var ly: float = (hit_pos.y - z.global_position.y) / z.sc
		if ly > -42.0 and ly < -14.0:   # בבטן
			_belly_hits += 1
			if _belly_hits >= CHOKE_HITS:   # נחנק: הקיא נשפך עליו
				chokes += 1
				state = RECOVER
				_st = RECOVER_T * 1.6
				z._popup("CHOKED!", Color("c8e050"), 18, -100.0)
				Sfx.play("ret_splat", z.global_position, 2.0, 0.1, 2)
				_puddle(z.global_position, 70.0 * z.sc)
				z.stagger(1.4)
	return true


func on_death() -> void:
	if _mist != null:
		_mist.emitting = false
	_puddle(z.global_position + Vector2(z._dir * 20.0, 0), 80.0 * z.sc)   # הבטן מתפוצצת


func _puddle(at: Vector2, w: float) -> void:
	var pool = load("res://environment/acid_pool.gd").new()
	pool.setup(w, 5.0)
	pool.tint = Color(0.78, 0.82, 0.25)
	pool.story_kind = "puke"
	z.get_parent().add_child(pool)
	pool.global_position = at


# ============================================================
#  ציור
# ============================================================
func draw() -> bool:
	begin_draw()
	var sk := col(z.skin)
	var vest := col(z.shirt)
	var p: float = z._walk_phase
	var f: Array = feet(4.0, 2.0)
	var swell := 1.0
	var tilt := 0.0
	match state:
		HEAVE:
			var k := 1.0 - _st / HEAVE_T
			swell = 1.0 + 0.22 * k + 0.06 * sin(z._time * 26.0) * k
			tilt = -0.35 * k
		PUKE:
			swell = 1.15 - 0.15 * (1.0 - _st / PUKE_T)
			tilt = 0.25
		RECOVER:
			swell = 0.95
			tilt = 0.35
	var hip := Vector2(0.0, -16.0 + absf(sin(p)) * 1.0)
	var sh := Vector2(1.0, -42.0)
	var head := sh + Vector2(5.0, -7.0) + Vector2(4.0, 2.0) * tilt
	# רגליים דקות
	z._leg(hip + Vector2(-4, 0), f[1], col(Art.shade(z.pants, 0.25)), col(Art.shade(z.skin, 0.2)), col(z.shoe))
	z._leg(hip + Vector2(4, 0), f[0], col(z.pants), sk, col(z.shoe))
	# יד אחורית עבה
	Art.limb(z, PackedVector2Array([sh + Vector2(-6, 2), sh + Vector2(-4, 14), sh + Vector2(4, 20)]), 6.0, Art.shade(sk, 0.25))
	# בטן ענקית: גופייה מוכתמת + סינר גומי
	var bc := Vector2(4.0, -28.0)
	Art.oval_shaded(z, bc, 15.0 * swell, 15.0 * swell, vest, 0.0)
	for q in [Vector2(6, -30), Vector2(-2, -24), Vector2(10, -22)]:   # כתמים
		Art.oval(z, q, 3.5, 2.5, col(Color(0.6, 0.62, 0.25, 0.6)), 0.4, Art.NONE)
	Art.fill(z, PackedVector2Array([bc + Vector2(-6, -12) * swell, bc + Vector2(12, -10) * swell, bc + Vector2(14, 12) * swell, bc + Vector2(-4, 15) * swell]), col(Color(0.25, 0.3, 0.32, 0.55)), Art.NONE)
	if state == HEAVE:   # הבטן פועמת - ורידים
		z.draw_polyline(PackedVector2Array([bc + Vector2(-4, 6), bc + Vector2(2, 2), bc + Vector2(8, 5)]), Color(0.45, 0.6, 0.2, 0.8), 1.2)
	# כתפיים וצוואר עבה
	Art.oval_shaded(z, sh + Vector2(0, 2), 10.0, 6.0, sk, 0.0)
	# ראש קטן
	Art.oval_shaded(z, head, 6.5, 6.5, sk, 0.0)
	z.draw_circle(head + Vector2(3.0, -2.0), 1.3, Color(0.9, 0.85, 0.3))
	z.draw_circle(head + Vector2(-1.0, -2.0), 1.1, Color(0.9, 0.85, 0.3))
	if state == PUKE:   # פה פעור + הזרם יוצא
		Art.oval(z, head + Vector2(4, 4), 3.5, 3.0, col(Color("2a1a08")), 0.0, Art.OUTLINE, 1.0)
		var w := sin(z._time * 30.0) * 1.5
		z.draw_colored_polygon(PackedVector2Array([head + Vector2(5, 2), head + Vector2(22, 3 + w), head + Vector2(22, 9 + w), head + Vector2(5, 6)]), Color(0.78, 0.8, 0.28, 0.9))
	elif state == HEAVE:
		Art.oval(z, head + Vector2(4, 4), 2.2, 1.6, col(Color("2a1a08")), 0.0, Art.NONE)
		if fmod(z._time, 0.3) < 0.15:
			z.draw_circle(head + Vector2(6, 6), 1.2, Color(0.8, 0.85, 0.3))   # טיפות
	else:
		z.draw_line(head + Vector2(1, 4), head + Vector2(6, 4.5), col(Color("2a0a0a")), 1.2)
		z.draw_line(head + Vector2(5, 5), head + Vector2(5.5, 9 + sin(z._time * 3.0)), Color(0.8, 0.85, 0.3, 0.8), 1.0)   # ריר
	# כובע טבח מלוכלך
	Art.fill(z, PackedVector2Array([head + Vector2(-6, -4), head + Vector2(6, -5), head + Vector2(5, -10), head + Vector2(-5, -9)]), col(Color("c8c0a8")), Art.OUTLINE, 0.9)
	# יד קדמית: על הבטן בזמן ההקאה, אחרת מושטת
	var hand := sh + Vector2(16, 14) if state == WALK else (bc + Vector2(12, -2) if state != RECOVER else head + Vector2(8, 6))
	Art.limb(z, PackedVector2Array([sh + Vector2(6, 2), sh.lerp(hand, 0.5) + Vector2(3, 3), hand]), 6.4, sk)
	Art.disc(z, hand + Vector2(1, 0), 3.4, sk)
	end_draw()
	return true


# ============================================================
#  גוש קיא: קשת עם כבידה. פוגע בשחקן או נוחת ויוצר שלולית צורבת (לפעמים)
# ============================================================
class Bile extends Node2D:
	var owner_z = null
	var velocity := Vector2.ZERO
	var big := false
	var _t := 0.0
	static var _n := 0

	func _ready() -> void:
		z_index = 8

	func _physics_process(delta: float) -> void:
		_t += delta
		velocity.y += 760.0 * delta
		var to := global_position + velocity * delta
		var p := get_tree().get_first_node_in_group("player")
		if p != null and not p.dead and p.body_rect().grow(3.0).has_point(to) and owner_z != null:
			owner_z.blob_hit(p, signf(velocity.x))
			queue_free()
			return
		var hit := get_world_2d().direct_space_state.intersect_ray(PhysicsRayQueryParameters2D.create(global_position, to, 1 | 16))
		if hit:
			_n += 1
			if _n % (3 if big else 4) == 0 and hit.normal.y < -0.5 and owner_z != null:
				owner_z._puddle(hit.position, randf_range(40.0, 60.0) * (1.5 if big else 1.0))
				Sfx.play("ret_splat", hit.position, -8.0, 0.2, 2)
			queue_free()
			return
		global_position = to
		if _t > 3.0:
			queue_free()
		queue_redraw()

	func _draw() -> void:
		var r := 3.6 if big else 2.8
		var tail := -velocity.normalized() * 7.0
		draw_line(Vector2.ZERO, tail, Color(0.72, 0.76, 0.24, 0.6), r * 1.3, true)
		draw_circle(Vector2.ZERO, r, Color(0.8, 0.84, 0.28))
		draw_circle(Vector2(-0.8, -0.8), r * 0.4, Color(0.95, 0.95, 0.6))
