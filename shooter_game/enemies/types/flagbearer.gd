extends "res://enemies/zombie_type.gd"
# ============================================================
#  FLAGBEARER (משלב 40, "HARBOR OF WAR") - נושא הדגל של אימפריית המתים: דגל אדום ענק עם הסמל על תורן גבוה.
#  "THEY LEARNED TO BELIEVE": כל חייל של האימפריה בטווח AURA_R מהדגל לא נשבר - מקבל רק x0.6 נזק (zombie.gd, meta "morale_t").
#    הולך באמצע היחידה, לא תוקף. ירייה בתורן / בדגל (מעל הראש) -> הדגל נופל: ההגנה נעלמת והחיילים סביבו נשברים ("broken").
#    גם כשהוא מת - הדגל נופל.
#  לשנות: AURA_R, POLE_H, FLAG_HP.
# ============================================================

const E := preload("res://enemies/empire_kit.gd")

const SOUNDS := {
	"fb_snap": [["C", 0, 0, 0.0, 0.06, 0.0, 50.0, 0.6, 1.0, 0], ["N", 0, 0, 0.0, 0.3, 0.0, 8.0, 0.3, 0.4, 0, 0.6]],
	"fb_horn": {"drive": 1.3, "layers": [["S", 220, 230, 0.0, 0.8, 0.1, 1.5, 0.3, 1.0, 0.03], ["S", 330, 340, 0.0, 0.8, 0.1, 1.5, 0.15, 1.0, 0.03]]},
}

const AURA_R := 260.0
const POLE_H := 96.0
const FLAG_HP := 2

var standing := true         # הדגל מורם
var flag_hp := FLAG_HP
var _tick := 0.0
var _fall := 0.0


func stats() -> Dictionary:
	return {"name": "FLAGBEARER", "hp": 36, "walk": 36.0, "chase": 58.0, "damage": 1, "bite_delay": 1.0, "scale": 1.05, "width": 1.0,
		"duck": 0.0, "cover": 0.1, "skin": Color("7a8670"), "shirt": E.UNIFORM, "pants": E.UNIFORM, "shoe": Color("1a1816"), "points": 520}


func setup() -> void:
	z.add_to_group("empire")


func brain_overrides() -> Dictionary:
	return {"aggression": 0.2}


func can_bite() -> bool:
	return not standing


func flag_top() -> Vector2:
	return z.global_position + Vector2(z._dir * 8.0, -POLE_H) * z.sc


func on_damage(amount: int, hit_pos: Vector2, _dir: Vector2, src: Dictionary) -> bool:
	if standing and (hit_pos.y - z.global_position.y) / z.sc < -58.0:   # התורן / הדגל
		flag_hp -= 1
		Particles.burst(z.get_parent(), hit_pos, "leaf", Vector2.UP, 3)
		if flag_hp <= 0:
			_drop_flag()
		return false
	return true


func _drop_flag() -> void:
	if not standing:
		return
	standing = false
	_fall = 0.0
	Sfx.play("fb_snap", z.global_position, 0.0, 0.1, 2)
	z._popup("THE FLAG IS DOWN!", Color("ffe0a0"), 15, -80.0)
	for o in z.get_tree().get_nodes_in_group("empire"):   # ההגנה נעלמת מיד
		if o.has_meta("morale_t"):
			o.remove_meta("morale_t")
	E.order(z, "broken", AURA_R)


func on_death() -> void:
	_drop_flag()


func physics(_pl: Node, delta: float) -> bool:
	_tick -= delta
	_fall += delta
	if standing and not z.dead and _tick <= 0.0:
		_tick = 0.25
		for o in z.get_tree().get_nodes_in_group("empire"):
			if not o.dead and o.global_position.distance_to(z.global_position) < AURA_R:
				o.set_meta("morale_t", float(o._time) + 0.4)
	return false


# ============================================================
#  ציור: חייל עם חגורת נשיאה, תורן מוחזק בשתי ידיים, הדגל מתנופף למעלה (בעולם). הילה אדומה עדינה סביב היחידה
# ============================================================
func draw() -> bool:
	begin_draw()
	var o: Dictionary = E.soldier(self, z, Vector2(9, -6), "helmet", E.UNIFORM, Vector2(5, -2))
	var hf: Vector2 = o.hf
	var sh: Vector2 = o.sh
	z.draw_line(sh + Vector2(-6, -1), sh + Vector2(6, 18), col(Color("2a2018")), 2.0)   # חגורת נשיאה
	if standing:
		z.draw_line(Vector2(8, -4), Vector2(8, -POLE_H), col(Color("5a4026")), 2.2)   # התורן
		z.draw_circle(Vector2(8, -POLE_H - 1.5), 2.0, col(E.BRASS))
	end_draw()
	if standing and not z.dead:   # הדגל (בעולם, לא מתהפך)
		var top: Vector2 = flag_top() - z.global_position
		E.flag(z, top + Vector2(0, 3), 46.0, 30.0, z._time, int(z.global_position.x) % 7)
		Art.glow(z, Vector2(0, -30), AURA_R * 0.25, Color(1.0, 0.2, 0.15, 0.06))
	elif not standing and _fall < 1.0:   # הדגל נופל
		var k := clampf(_fall / 0.6, 0.0, 1.0)
		var tip: Vector2 = Vector2(z._dir * (8.0 + 60.0 * k), -POLE_H * (1.0 - k)) * z.sc
		z.draw_line(Vector2(z._dir * 8.0, -4.0), tip, Color("5a4026"), 2.2)
	return true
