extends "res://enemies/zombie_type.gd"
# ============================================================
#  BOMBHEAD (שלב 15, צפון-מזרח, קרנבל) - חוגג קרנבל מת עם חגורת זיקוקים ("בומבינייאס").
#  צללית: חולצת פרבו מפוספסת וצבעונית, כובע ליצן קטן, חגורה של זיקוקים אדומים סביב המותניים.
#  מחזור:
#    WALK  - מתקרב רגיל (המוח מזיז אותו).
#    PULL  - תולש את הראש שלו בשתי ידיים (PULL_T שניות = אזהרה).
#    THROW - זורק את הראש בקשת אליך (HeadShot: פוגע = לב, נוחת ומקשקש בשיניים עוד קצת).
#    RUN   - בלי ראש: הפתיל של הזיקוקים בוער (ניצוצות) והגוף רץ אליך מהר - קמיקזה.
#            מגיע אליך / הפתיל נגמר (FUSE) = מתפוצץ (פוגע גם בזומבים מסביב!).
#            יורים בו בזמן הריצה = מתפוצץ במקום (טוב להפיל אותו ליד זומבים אחרים).
#  צלילים: "bh_rip" (תלישה), "bh_fuse" (פתיל), "bh_chatter" (שיניים).
#  לשנות: RANGE, PULL_T, RUN_SPEED, FUSE, BLAST_R.
# ============================================================

const Boom := preload("res://explosion.gd")

const SOUNDS := {
	"bh_rip": [["N", 0, 0, 0.0, 0.25, 0.0, 9.0, 0.8, 0.4, 0], ["S", 180, 70, 0.0, 0.2, 0.0, 12.0, 0.6, 1.0, 0]],
	"bh_fuse": [["N", 0, 0, 0.0, 0.5, 0.02, 2.0, 0.35, 0.9, 0, 0.6]],
	"bh_chatter": [["C", 0, 0, 0.0, 0.3, 0.0, 8.0, 0.5, 1.0, 0], ["N", 0, 0, 0.0, 0.05, 0.0, 40.0, 0.3, 1.0, 0]],
}

const RANGE := Vector2(110.0, 380.0)
const PULL_T := 0.55
const RUN_SPEED := 235.0
const FUSE := 3.2
const BLAST_R := 95.0

enum { WALK, PULL, THROW, RUN }
var state := WALK
var throws := 0             # לבדיקות
var exploded := false
var _st := 0.0
var _cd := 1.2
var _fuse := 0.0
var _hiss := 0.0


func stats() -> Dictionary:
	return {"name": "BOMBHEAD", "hp": 34, "walk": 46.0, "chase": 100.0, "damage": 1, "bite_delay": 0.8, "scale": 1.0, "width": 0.95,
		"duck": 0.1, "cover": 0.2, "skin": Color("8aa070"), "shirt": Color("e8483a"), "pants": Color("2a3a6a"), "shoe": Color("1e1a16"),
		"points": 340, "ragdoll": false}


func brain_overrides() -> Dictionary:
	return {"aggression": 0.3, "keep_range": 200.0}


func can_bite() -> bool:
	return state == WALK


func can_groan() -> bool:
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
				if sees and absf(d.x) > RANGE.x and absf(d.x) < RANGE.y and absf(d.y) < 140.0:
					state = PULL
					_st = PULL_T
					z._dir = signf(d.x) if d.x != 0.0 else z._dir
					Sfx.play("bh_rip", z.global_position, 0.0, 0.1, 2)
					return _stay(delta)
			return false
		PULL:
			if _st <= 0.0:
				_throw(pl)
			return _stay(delta)
		THROW:
			if _st <= 0.0:
				state = RUN
				_fuse = FUSE
				Sfx.play("bh_fuse", z.global_position, 0.0, 0.1, 2)
			return _stay(delta)
		RUN:   # קמיקזה בלי ראש
			_fuse -= delta
			_hiss -= delta
			if _hiss <= 0.0:
				_hiss = 0.45
				Sfx.play("bh_fuse", z.global_position, -6.0, 0.15, 3)
			if randf() < delta * 30.0:
				Particles.burst(z.get_parent(), _belt(), "fire", Vector2(0, -1), 1)
			if pl != null and not pl.dead:
				var dx: float = pl.global_position.x - z.global_position.x
				z._dir = signf(dx) if dx != 0.0 else z._dir
				if absf(dx) < 30.0 and absf(pl.global_position.y - z.global_position.y) < 60.0:
					explode()
					return true
			if _fuse <= 0.0:
				explode()
				return true
			z.velocity.x = move_toward(z.velocity.x, z._dir * RUN_SPEED, 900.0 * delta)
			if not z.is_on_floor():
				z.velocity.y += z.gravity * delta
			elif z.is_on_wall():
				z.velocity.y = -380.0   # קופץ מעל מכשולים
			z.move_and_slide()
			z._walk_phase += absf(z.velocity.x) * delta * 0.09
			return true
	return false


func _stay(delta: float) -> bool:
	z.velocity.x = move_toward(z.velocity.x, 0.0, 900.0 * delta)
	if not z.is_on_floor():
		z.velocity.y += z.gravity * delta
	z.move_and_slide()
	return true


func _belt() -> Vector2:
	return z.global_position + Vector2(z._dir * 2.0, -22.0 * z.sc)


func _throw(pl: Node) -> void:
	state = THROW
	_st = 0.35
	throws += 1
	var from: Vector2 = z.global_position + Vector2(z._dir * 6.0, -56.0 * z.sc)
	var to: Vector2 = pl.global_position + Vector2(0, -20) if pl != null else from + Vector2(z._dir * 200.0, 0)
	var t := clampf(absf(to.x - from.x) / 330.0, 0.45, 1.1)   # זמן טיסה לפי המרחק
	var h := HeadShot.new()
	h.velocity = Vector2((to.x - from.x) / t, (to.y - from.y - 0.5 * 900.0 * t * t) / t)
	h.skin = z.skin
	h.face = z._dir
	z.get_parent().add_child(h)
	h.global_position = from
	z._spray_blood(from + Vector2(0, 6), Vector2(0, -1), 8, 200.0)
	Sfx.play("bh_rip", from, 2.0, 0.1, 2)
	Game.story.emit("head_throw", {"z": z})


# בום: פוגע בשחקן ובזומבים מסביב, והגוף נעלם
func explode() -> void:
	if exploded:
		return
	exploded = true
	var at: Vector2 = z.global_position + Vector2(0, -24.0)
	Boom.blast.call_deferred(z.get_parent(), at, BLAST_R, 60.0, 40, 1, "bombhead")
	for i in 14:   # קונפטי של קרנבל מהפיצוץ
		Particles.burst(z.get_parent(), at, "fire", Vector2.from_angle(randf() * TAU), 1)
	if not z.dead:
		z.hp = 0
		z._die(Vector2(z._dir, -0.5))
	z.hide()


func on_damage(_amount: int, _hit_pos: Vector2, _dir: Vector2, _src: Dictionary) -> bool:
	if state == RUN and not exploded:   # יורים בו בזמן הריצה = מתפוצץ במקום
		explode.call_deferred()
		return false
	return true


func on_death() -> void:
	if state == RUN and not exploded:
		explode.call_deferred()


# ============================================================
#  ציור
# ============================================================
func draw() -> bool:
	if exploded:
		return true
	begin_draw()
	var sk := col(z.skin)
	var shirt := col(z.shirt)
	var p: float = z._walk_phase
	var f: Array = feet(5.0 if state == RUN else 4.0, 3.0 if state == RUN else 2.5)
	var lean := 5.0 if state == RUN else 0.0
	var hip := Vector2(-1.0, -22.0 + absf(sin(p)) * 1.2)
	var sh := Vector2(1.0 + lean, -38.0)
	var head := sh + Vector2(3.0, -9.0)
	z._leg(hip + Vector2(-2, 0), f[1], col(Art.shade(z.pants, 0.25)), col(Art.shade(z.skin, 0.2)), col(z.shoe))
	z._leg(hip + Vector2(2, 0), f[0], col(z.pants), sk, col(z.shoe))
	# חולצת פרבו מפוספסת
	var body := PackedVector2Array([sh + Vector2(-7, -1), sh + Vector2(7, 0), hip + Vector2(7, 3), hip + Vector2(-7, 3)])
	Art.fill_shaded(z, body, shirt, 0.15, 0.4)
	for i in 3:
		var y := -1.0 + float(i) * 5.5
		z.draw_line(sh.lerp(hip, 0.0) + Vector2(-6.5, y + 2.0), sh + Vector2(6.5, y + 3.0), col(Color("f8d040")), 1.6)
	# חגורת זיקוקים (פתיל בוער בריצה)
	for i in 5:
		var bx := -6.0 + float(i) * 3.0
		z.draw_rect(Rect2(hip + Vector2(bx, -4), Vector2(2.2, 6)), col(Color("c0201c")))
		z.draw_line(hip + Vector2(bx + 1.1, -4), hip + Vector2(bx + 1.1, -6), Color("2a2a2a"), 0.8)
	if state == RUN:
		var spark := hip + Vector2(6, -6)
		z.draw_circle(spark, 1.8 + sin(z._time * 40.0), Color(1.0, 0.85, 0.3))
		Art.glow(z, spark, 7.0, Color(1.0, 0.6, 0.2, 0.7))
	# ראש: על הכתפיים / בידיים (תולש) / אין (זרק)
	if state == WALK or state == PULL:
		var hp: Vector2 = head
		if state == PULL:
			var k := 1.0 - clampf(_st / PULL_T, 0.0, 1.0)
			hp = head + Vector2(-2.0 * k, -6.0 * k + sin(z._time * 40.0) * 1.2 * k)   # נקרע למעלה
			z.draw_line(sh + Vector2(2, -1), hp + Vector2(0, 5), col(Color("8a1010")), 2.0)   # גידים נמתחים
		_draw_head(hp, sk)
	else:
		z.draw_circle(sh + Vector2(2, -2), 3.2, col(Color("6a0c0c")))   # צוואר קרוע
		if randf() < 0.4:
			z.draw_circle(sh + Vector2(2 + randf_range(-2, 2), -5 - randf() * 4.0), 1.2, Color(0.6, 0.05, 0.05))
	# ידיים
	var ha := sh + Vector2(12, 6)
	var hb := sh + Vector2(10, 9)
	if state == PULL:
		ha = head + Vector2(-4, 0) + Vector2(-2, -6) * (1.0 - clampf(_st / PULL_T, 0.0, 1.0))
		hb = head + Vector2(5, 1)
	elif state == THROW:
		ha = sh + Vector2(14, -12)
		hb = sh + Vector2(12, -8)
	elif state == RUN:
		ha = sh + Vector2(-8, 8 + sin(p) * 4.0)
		hb = sh + Vector2(10, 6 - sin(p) * 4.0)
	z._arm(sh + Vector2(-3, 1), ha, col(Art.shade(z.skin, 0.25)), Art.shade(shirt, 0.3))
	z._arm(sh + Vector2(3, 2), hb, sk, shirt)
	end_draw()
	return true


func _draw_head(c: Vector2, sk: Color) -> void:
	Art.oval_shaded(z, c, 6.5, 7.0, sk, 0.0)
	z.draw_circle(c + Vector2(3.0, -1.0), 1.3, Color(1.0, 0.85, 0.3))
	Art.fill(z, PackedVector2Array([c + Vector2(1, 3), c + Vector2(7, 2.5), c + Vector2(6, 6), c + Vector2(1.5, 6)]), col(Color("2a0a0a")), Art.OUTLINE, 0.8)
	# כובע ליצן קטן
	Art.fill(z, PackedVector2Array([c + Vector2(-5, -5), c + Vector2(4, -6), c + Vector2(-2, -15)]), col(Color("3a8ae0")), Art.OUTLINE, 0.9)
	z.draw_circle(c + Vector2(-2, -15), 1.8, col(Color("f8d040")))


# ============================================================
#  הראש שנזרק: עף בקשת, פוגע בשחקן (לב), קופץ ומקשקש בשיניים על הרצפה
# ============================================================
class HeadShot extends Node2D:
	var velocity := Vector2.ZERO
	var skin := Color.GRAY
	var face := 1.0
	var life := 4.0
	var _hit := false
	var _ground := false
	var _t := 0.0
	var _chat := 0.0

	func _ready() -> void:
		z_index = 8

	func _physics_process(delta: float) -> void:
		_t += delta
		life -= delta
		if life <= 0.0:
			queue_free()
			return
		var p := get_tree().get_first_node_in_group("player")
		if not _ground:
			velocity.y += 900.0 * delta
			var to := global_position + velocity * delta
			if p != null and not p.dead and not _hit and p.body_rect().grow(4.0).has_point(to):
				_hit = true
				p.hurt(1, Vector2(signf(velocity.x), -0.3))
				velocity = Vector2(-velocity.x * 0.3, -180.0)
			var hit := get_world_2d().direct_space_state.intersect_ray(PhysicsRayQueryParameters2D.create(global_position, to, 1 | 16))
			if hit:
				global_position = hit.position + hit.normal * 5.0
				if velocity.length() > 260.0:
					velocity = velocity.bounce(hit.normal) * 0.35
				else:
					_ground = true
					velocity = Vector2.ZERO
			else:
				global_position = to
			rotation += velocity.x * delta * 0.03
		else:
			_chat -= delta
			if _chat <= 0.0:   # מקשקש בשיניים ומקפץ קצת אליך
				_chat = 0.5
				Sfx.play("bh_chatter", global_position, -6.0, 0.2, 3)
				if p != null and not _hit and absf(p.global_position.x - global_position.x) < 26.0 and absf(p.global_position.y - global_position.y) < 30.0:
					_hit = true
					p.hurt(1, Vector2(signf(p.global_position.x - global_position.x), 0.0))
		queue_redraw()

	func _draw() -> void:
		var a := clampf(life / 0.5, 0.0, 1.0)
		var jaw := absf(sin(_t * 18.0)) * 2.0 if _ground else 1.0
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(face, 1.0))
		draw_circle(Vector2(0, 0), 7.5, Color(Art.OUTLINE, a))
		draw_circle(Vector2(0, 0), 6.5, Color(skin, a))
		draw_circle(Vector2(3, -1), 1.3, Color(1.0, 0.85, 0.3, a))
		draw_rect(Rect2(Vector2(1, 2.5), Vector2(6, 1.5 + jaw)), Color(0.16, 0.04, 0.04, a))
		draw_colored_polygon(PackedVector2Array([Vector2(-5, -5), Vector2(4, -6), Vector2(-2, -15)]), Color(0.23, 0.54, 0.88, a))
		draw_circle(Vector2(0, 7), 2.5, Color(0.42, 0.04, 0.04, a))   # צוואר קרוע
		draw_set_transform_matrix(Transform2D.IDENTITY)

	const Art := preload("res://art.gd")
	const Sfx := preload("res://sfx.gd")
