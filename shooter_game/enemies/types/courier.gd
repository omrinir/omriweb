extends "res://enemies/zombie_type.gd"
# ============================================================
#  COURIER (שלב 38, "MEGACITY CORE") - "מוטובוי" זומבי: מעיל רוח, קסדה פתוחה, ארגז משלוחים ענק על הגב.
#  "THEY LEARNED TO DELIVER": מהיר. רץ לנקודה שבה אתה תהיה (לפי הכיוון שלך) ומניח שם חבילה (Package) - ואז בורח.
#    החבילה מצפצפת (FUSE) ומתפוצצת, או מיד כשאתה מתקרב אליה (PROX). ירייה בחבילה מפוצצת אותה (טוב ליד זומבים).
#    יש לו PACKAGES חבילות. בלי חבילות - זומבי רץ רגיל.
#  לשנות: PACKAGES, LEAD_T, FUSE, PROX, BLAST_R.
# ============================================================

const SOUNDS := {
	"cr_drop": [["C", 0, 0, 0.0, 0.06, 0.0, 40.0, 0.5, 1.0, 0], ["S", 400, 300, 0.0, 0.1, 0.0, 20.0, 0.2, 1.0, 0]],
	"cr_beep": [["Q", 2200, 2200, 0.0, 0.06, 0.0, 40.0, 0.18, 1.0, 0]],
}

const PACKAGES := 3
const LEAD_T := 1.4
const FUSE := 3.0
const PROX := 46.0
const BLAST_R := 80.0

enum { RUN, PLACE, FLEE }
var state := RUN
var left := PACKAGES
var placed := 0              # לבדיקות
var _st := 0.0
var _cd := 1.5
var _target := Vector2.ZERO


func stats() -> Dictionary:
	return {"name": "COURIER", "hp": 26, "walk": 70.0, "chase": 150.0, "damage": 1, "bite_delay": 0.7, "scale": 1.0, "width": 1.0,
		"duck": 0.2, "cover": 0.0, "skin": Color("7a8a70"), "shirt": Color("2a8a4a"), "pants": Color("2a2a34"), "shoe": Color("e0e0e0"), "points": 470}


func brain_overrides() -> Dictionary:
	return {"aggression": 0.3}


func can_bite() -> bool:
	return left <= 0 or state == RUN


func physics(pl: Node, delta: float) -> bool:
	_st -= delta
	_cd -= delta
	if z.dead or pl == null or pl.dead or left <= 0:
		return false
	var dpl: Vector2 = pl.global_position - z.global_position
	match state:
		RUN:
			if _cd > 0.0 or absf(dpl.x) > 700.0 or absf(dpl.y) > 120.0:
				return false
			# לאן אתה הולך? לשם הוא רץ
			var vx: float = pl.velocity.x
			var ahead: float = pl.global_position.x + clampf(vx * LEAD_T, -320.0, 320.0)
			if absf(vx) < 30.0:   # עומד - שם את החבילה בין שניכם
				ahead = pl.global_position.x - signf(dpl.x) * 120.0
			_target = Vector2(ahead, pl.global_position.y)
			var dx: float = _target.x - z.global_position.x
			if absf(dx) < 16.0:
				state = PLACE
				_st = 0.35
				return _run(0.0, delta)
			z._dir = signf(dx)
			return _run(z._dir * float(z.chase_speed) * 1.3, delta)
		PLACE:
			if _st <= 0.0:
				_place()
				state = FLEE
				_st = 0.9
			return _run(0.0, delta)
		FLEE:
			z._dir = -signf(dpl.x) if absf(dpl.x) > 4.0 else z._dir
			if _st <= 0.0:
				state = RUN
				_cd = 0.8
			return _run(z._dir * float(z.chase_speed), delta)
	return false


func _run(vx: float, delta: float) -> bool:
	z.velocity.x = move_toward(z.velocity.x, vx, 900.0 * delta)
	if not z.is_on_floor():
		z.velocity.y += z.gravity * delta
	elif z.is_on_wall() and vx != 0.0:
		z.velocity.y = -400.0
	z.move_and_slide()
	return true


func _place() -> void:
	left -= 1
	placed += 1
	Sfx.play("cr_drop", z.global_position, -2.0, 0.1, 2)
	var pk := Package.new()
	z.get_parent().add_child(pk)
	pk.global_position = z.global_position


# ============================================================
#  חבילה ממולכדת: קרטון עם סרט דביק ונורה אדומה. מצפצפת יותר מהר ככל שמתקרב הפיצוץ
# ============================================================
class Package extends StaticBody2D:
	const FUSE_T := 3.0      # = FUSE
	const PROX_R := 46.0     # = PROX
	const R := 80.0          # = BLAST_R
	var exploded := false    # לבדיקות
	var _t := 0.0
	var _beep := 0.0

	func _ready() -> void:
		z_index = 3
		collision_layer = 4
		collision_mask = 0
		add_to_group("hazards")
		var cs := CollisionShape2D.new()
		var sh := RectangleShape2D.new()
		sh.size = Vector2(18, 14)
		cs.shape = sh
		cs.position = Vector2(0, -7)
		add_child(cs)

	func world_rect() -> Rect2:
		return Rect2(global_position - Vector2(R, R * 0.6), Vector2(R * 2.0, R * 0.8))

	func danger_at(p: Vector2, margin := 0.0) -> bool:
		return not exploded and world_rect().grow(margin).has_point(p)

	func take_damage(_amount: int, _hit_pos: Vector2, _dir: Vector2, _explosive := false, _src := {}) -> void:
		_boom()

	func _physics_process(delta: float) -> void:
		if exploded:
			return
		_t += delta
		_beep -= delta
		if _beep <= 0.0:
			_beep = lerpf(0.5, 0.08, clampf(_t / FUSE_T, 0.0, 1.0))
			preload("res://sfx.gd").play("cr_beep", global_position, -10.0, 0.0, 4)
		var pl := get_tree().get_first_node_in_group("player")
		if _t > 0.5 and pl != null and not pl.dead and pl.global_position.distance_to(global_position) < PROX_R:
			_boom()
			return
		if _t >= FUSE_T:
			_boom()
			return
		queue_redraw()

	func _boom() -> void:
		if exploded:
			return
		exploded = true
		preload("res://explosion.gd").blast(get_parent(), global_position + Vector2(0, -8), R, R * 0.4, 30, 1, "package")
		queue_free()

	func _draw() -> void:
		draw_rect(Rect2(-9, -14, 18, 14), Color("b08a5a"))
		draw_rect(Rect2(-9, -14, 18, 14), Color("5a4026"), false, 1.0)
		draw_rect(Rect2(-9, -9, 18, 3), Color("d8c8a0"))   # סרט דביק
		var on := _beep > 0.0 and fposmod(_t * 8.0, 1.0) < 0.4
		draw_circle(Vector2(5, -15), 2.0, Color(1.0, 0.15, 0.1) if on else Color(0.4, 0.1, 0.1))
		if on:
			draw_circle(Vector2(5, -15), 6.0, Color(1.0, 0.2, 0.1, 0.25))


# ============================================================
#  ציור: מעיל רוח ירוק, קסדה פתוחה עם משקף, ארגז משלוחים אדום ענק על הגב (חבילות מבצבצות)
# ============================================================
func draw() -> bool:
	begin_draw()
	var sk := col(z.skin)
	var coat := col(z.shirt)
	var p: float = z._walk_phase
	var f: Array = feet(6.0, 3.0)
	var hip := Vector2(0, -22)
	var sh := Vector2(2, -37)
	var head := sh + Vector2(4, -8)
	z._leg(hip + Vector2(-2, 0), f[1], col(Art.shade(z.pants, 0.25)), sk, col(z.shoe))
	z._leg(hip + Vector2(2, 0), f[0], col(z.pants), sk, col(z.shoe))
	if left > 0:   # ארגז משלוחים
		Art.fill_shaded(z, PackedVector2Array([sh + Vector2(-20, -8), sh + Vector2(-6, -8), sh + Vector2(-6, 14), sh + Vector2(-20, 14)]), col(Color("d02a2a")), 0.12, 0.4, Art.OUTLINE, 1.0)
		z.draw_rect(Rect2(sh + Vector2(-19, -2), Vector2(12, 3)), col(Color("f0f0f0")))
		for q in left:
			z.draw_rect(Rect2(sh + Vector2(-18.0 + float(q) * 4.0, -12), Vector2(4, 4)), col(Color("b08a5a")))
	z._arm(sh + Vector2(-3, 1), sh + Vector2(-5.0 - sin(p) * 3.0, 15.0), Art.shade(sk, 0.25), Art.shade(coat, 0.3))
	Art.fill_shaded(z, PackedVector2Array([sh + Vector2(-8, -1), sh + Vector2(8, 0), hip + Vector2(7, 3), hip + Vector2(-7, 3)]), coat, 0.12, 0.4)
	z.draw_line(sh + Vector2(-7, 8), sh + Vector2(7, 8), col(Color("e0e060")), 1.5)   # פס מחזיר אור
	Art.oval_shaded(z, head, 5.2, 5.8, sk, 0.0)
	face(head, Vector2(3.0, -0.5))
	z.draw_colored_polygon(PackedVector2Array([head + Vector2(-6, 2), head + Vector2(-6, -5), head + Vector2(0, -8), head + Vector2(6, -5), head + Vector2(6, -2), head + Vector2(-2, -2), head + Vector2(-3, 3)]), col(Color("1a1a1a")))   # קסדה פתוחה
	z.draw_line(head + Vector2(-1, -2), head + Vector2(7, -3), Color(0.6, 0.8, 1.0, 0.6), 1.2)   # משקף
	if not z.dead:
		z.draw_circle(head + Vector2(3.0, 0.0), 1.1, Color(1.0, 0.85, 0.4))
	var hf := sh + Vector2(6, 16) if state == PLACE else sh + Vector2(12, 4 + sin(p) * 2.0)
	z._arm(sh + Vector2(3, 1), hf, sk, coat)
	if state == PLACE:
		z.draw_rect(Rect2(hf + Vector2(-4, -2), Vector2(8, 6)), col(Color("b08a5a")))
	end_draw()
	return true
