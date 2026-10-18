extends "res://enemies/zombie_type.gd"
# ============================================================
#  VENT (שלב 26, "THE BUNKER") - זומבי רזה וארוך שזוחל בתעלות האוורור שבתקרה (effects/s26_decor.gd DUCT_Y).
#    DUCT  - זוחל בתוך התעלה: רואים רק עיניים אדומות דרך החריצים, אבק נושר והתעלה מקרקשת = הרמז.
#            קליעים פוגעים במתכת (לא בו). הוא זוחל למקום שמאחוריך (BEHIND) - הצד שאתה לא מסתכל אליו.
#    DROP  - כשהוא מעליך מאחור ואתה על הרצפה: קורע את הרשת ונופל.
#    אחרי זה - זומבי מהיר ורגיל (FOOT), מסתער מיד.
#  התחמקות: להסתכל אחורה (לכוון אליו) - הוא לא נופל כשאתה מסתכל. לעקוב אחרי האבק.
#  לשנות: DUCT_V, BEHIND, WAKE_R.
# ============================================================

const Decor := preload("res://effects/s26_decor.gd")

const SOUNDS := {
	"vt_rattle": [["C", 0, 0, 0.0, 0.35, 0.0, 6.0, 0.5, 0.6, 0], ["S", 420, 380, 0.0, 0.08, 0.0, 30.0, 0.12, 1.0, 0], ["S", 520, 500, 0.15, 0.08, 0.0, 30.0, 0.1, 1.0, 0]],
	"vt_break": [["N", 0, 0, 0.0, 0.05, 0.0, 120.0, 1.2, 1.0, 0], ["S", 700, 300, 0.0, 0.25, 0.0, 14.0, 0.4, 1.0, 0], ["C", 0, 0, 0.0, 0.4, 0.0, 8.0, 0.6, 1.0, 0]],
}

const DUCT_V := 125.0
const BEHIND := 90.0         # כמה מאחוריך הוא נופל
const WAKE_R := 900.0

enum { DUCT, DROP, FOOT }
var state := FOOT
var drops := 0               # לבדיקות
var _floor := 0.0
var _rattle := 0.0
var _z0 := 0


func stats() -> Dictionary:
	return {"name": "VENT", "hp": 28, "walk": 52.0, "chase": 126.0, "damage": 1, "bite_delay": 0.65, "scale": 1.0, "width": 0.82,
		"duck": 0.2, "cover": 0.0, "skin": Color("9aa098"), "shirt": Color("4a4a44"), "pants": Color("33332e"), "shoe": Color("1a1a1a"), "points": 400}


func setup() -> void:
	if z.chase_range > 600.0:
		return
	enter_duct()


func enter_duct() -> void:
	state = DUCT
	z.dormant = false
	_floor = z.global_position.y
	z.global_position.y = _floor + Decor.DUCT_Y
	z.velocity = Vector2.ZERO
	_z0 = z.z_index
	z.z_index = 5   # מעל התקרה (רק העיניים מצוירות)


func can_groan() -> bool:
	return state != DUCT


func can_bite() -> bool:
	return state == FOOT


func on_damage(_amount: int, hit_pos: Vector2, _dir: Vector2, _src: Dictionary) -> bool:
	if state == DUCT:   # הקליע פוגע בתעלה
		Particles.burst(z.get_parent(), hit_pos, "spark", Vector2.DOWN, 3)
		if randf() < 0.4:
			Sfx.play("ricochet", hit_pos, -8.0, 0.2, 2)
		return false
	return true


func _player_facing(pl: Node) -> float:
	var aim: Vector2 = pl.aim_world() if pl.has_method("aim_world") else pl.global_position + Vector2(1, 0)
	var d: float = aim.x - pl.global_position.x
	return signf(d) if absf(d) > 4.0 else 1.0


func physics(pl: Node, delta: float) -> bool:
	if z.dead:
		return false
	var has_pl: bool = pl != null and not pl.dead
	match state:
		DUCT:
			z.velocity = Vector2.ZERO
			if not has_pl or absf(pl.global_position.x - z.global_position.x) > WAKE_R:
				return true
			var face := _player_facing(pl)
			var tx: float = pl.global_position.x - face * BEHIND   # מאחוריך
			var dx: float = tx - z.global_position.x
			var step := clampf(dx, -DUCT_V * delta, DUCT_V * delta)
			z.global_position.x += step
			if absf(step) > 0.1:
				z._dir = signf(step)
				z._walk_phase += delta * 9.0
				_rattle -= delta
				if _rattle <= 0.0:
					_rattle = 0.35
					if Art.on_screen(z, z.global_position):
						Particles.burst(z.get_parent(), z.global_position + Vector2(randf_range(-8, 8), 4.0), "smoke", Vector2.DOWN, 1)
						Sfx.play("vt_rattle", z.global_position, -6.0, 0.15, 2)
			var on_floor_pl: bool = pl.is_on_floor() and absf(pl.global_position.y - _floor) < 30.0
			var behind: bool = signf(z.global_position.x - pl.global_position.x) == -face
			if absf(dx) < 16.0 and on_floor_pl and behind:
				_drop()
			return true
		DROP:
			if z.is_on_floor():
				state = FOOT
				z._rush_t = 3.0
				z._alert_t = 6.0
				return false
			z.velocity.y += z.gravity * delta
			z.velocity.x = move_toward(z.velocity.x, 0.0, 300.0 * delta)
			z.move_and_slide()
			return true
	return false


func _drop() -> void:
	state = DROP
	drops += 1
	z.z_index = _z0
	var pl := player()
	if pl != null:
		z._dir = signf(pl.global_position.x - z.global_position.x) if pl.global_position.x != z.global_position.x else z._dir
	z.velocity = Vector2(z._dir * 40.0, 60.0)
	z.global_position.y += 6.0
	Sfx.play("vt_break", z.global_position, 4.0, 0.1, 2)
	Particles.burst(z.get_parent(), z.global_position, "smoke", Vector2.DOWN, 10)
	Particles.burst(z.get_parent(), z.global_position, "spark", Vector2.DOWN, 6)
	var g := Grate.new()
	z.get_parent().add_child(g)
	g.global_position = z.global_position + Vector2(0, -8)


# ============================================================
#  ציור: בתעלה - רק שתי עיניים אדומות שזזות. בחוץ - זומבי רזה, ארוך-ידיים, ציפורניים
# ============================================================
func draw() -> bool:
	if state == DUCT and not z.dead:
		var s := Vector2(z._dir, 1.0)
		DrawBatch.set_transform(z, Vector2.ZERO, 0.0, s)
		var bob := sin(z._walk_phase) * 1.0
		for ex in [3.0, 8.0]:
			DrawBatch.circle(z, Vector2(ex, -12.0 + bob), 3.0, Color(1.0, 0.15, 0.1, 0.25))
			DrawBatch.circle(z, Vector2(ex, -12.0 + bob), 1.2, Color(1.0, 0.35, 0.2))
		end_draw()
		return true
	begin_draw()
	var sk := col(z.skin)
	var shirt := col(z.shirt)
	var p: float = z._walk_phase
	var f: Array = feet(6.5, 3.0)
	var hip := Vector2(0, -24)
	var sh := Vector2(3, -40)
	var head := sh + Vector2(5, -6)
	z._leg(hip + Vector2(-2, 0), f[1], col(Art.shade(z.pants, 0.25)), sk, col(z.shoe))
	z._leg(hip + Vector2(2, 0), f[0], col(z.pants), sk, col(z.shoe))
	z._arm(sh + Vector2(-2, 1), sh + Vector2(-2.0 - sin(p) * 5.0, 20.0), Art.shade(sk, 0.25), Art.shade(shirt, 0.3))
	Art.fill_shaded(z, PackedVector2Array([sh + Vector2(-5, -1), sh + Vector2(5, 0), hip + Vector2(4, 2), hip + Vector2(-4, 2)]), shirt, 0.12, 0.4)
	for q in 3:   # קרעים
		DrawBatch.line(z, sh + Vector2(-3.0 + float(q) * 3.0, 6), sh + Vector2(-2.0 + float(q) * 3.0, 11), col(Color(0.1, 0.1, 0.1, 0.5)), 1.0)
	Art.oval_shaded(z, head, 4.8, 5.6, sk, 0.0)
	if not z.dead:
		DrawBatch.circle(z, head + Vector2(2.5, -1.0), 1.1, Color(1.0, 0.3, 0.2))
	DrawBatch.line(z, head + Vector2(-1, 3), head + Vector2(4, 3.5), col(Color("2a1a1a")), 1.0)
	var hand := sh + Vector2(14.0 + sin(p) * 3.0, 10.0)
	z._arm(sh + Vector2(3, 1), hand, sk, shirt)
	for q in 3:   # ציפורניים
		DrawBatch.line(z, hand, hand + Vector2(4, -2.0 + float(q) * 2.0), col(Color("d8d0b0")), 1.0)
	end_draw()
	return true


# ---- רשת שנפלה מהתעלה ----
class Grate extends Node2D:
	var _v := Vector2(randf_range(-60.0, 60.0), -80.0)
	var _rot := 0.0
	var _life := 5.0

	func _ready() -> void:
		z_index = 4

	func _physics_process(delta: float) -> void:
		_life -= delta
		if _life <= 0.0:
			queue_free()
			return
		_v.y += 1200.0 * delta
		var to := global_position + _v * delta
		if not get_world_2d().direct_space_state.intersect_ray(PhysicsRayQueryParameters2D.create(global_position, to + Vector2(0, 3), 1)).is_empty():
			_v = Vector2.ZERO
			_rot = move_toward(_rot, 0.0, 10.0 * delta)
		else:
			global_position = to
			_rot += 8.0 * delta
		queue_redraw()

	func _draw() -> void:
		var a := clampf(_life, 0.0, 1.0)
		DrawBatch.set_transform(self, Vector2.ZERO, _rot, Vector2.ONE)
		DrawBatch.rect(self, Rect2(-17, -3, 34, 6), Color(0.16, 0.18, 0.19, a))
		for q in 5:
			DrawBatch.line(self, Vector2(-14.0 + float(q) * 7.0, -3), Vector2(-14.0 + float(q) * 7.0, 3), Color(0.42, 0.44, 0.46, a), 1.2)
