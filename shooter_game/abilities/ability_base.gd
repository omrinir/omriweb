extends RefCounted
# ============================================================
#  ABILITY BASE - בסיס לכל יכולת (abilities/types/*.gd).
#  player = הדמות (player.gd), power = רמת השדרוג POWER (0..5).
#  לממש:
#    activate() -> bool      - הפעלה (מחזיר false אם אי אפשר עכשיו - ואז אין cooldown)
#    process(delta)          - כל פריים (אפקטים שנמשכים)
#    on_lethal_hit() -> bool - ליכולות פסיביות: מכה קטלנית (true = הצלתי את השחקן)
#    active() -> bool        - האם האפקט פועל עכשיו (לממשק)
# ============================================================
const Art := preload("res://art.gd")
const Sfx := preload("res://sfx.gd")
const Particles := preload("res://particles.gd")
const AbilityDB := preload("res://abilities/ability_db.gd")

var id := ""
var player: Node = null
var power := 0


func activate() -> bool:
	return false


func process(_delta: float) -> void:
	pass


func on_lethal_hit() -> bool:
	return false


func on_level_start() -> void:
	pass


func active() -> bool:
	return false


# משך לפי רמת השדרוג
func duration() -> float:
	return float(AbilityDB.val(id, "duration", 0.0)) * (1.0 + 0.2 * float(power))


func zombies_near(pos: Vector2, radius: float) -> Array:
	var out := []
	for z in player.get_tree().get_nodes_in_group("zombies"):
		if not z.dead and z.global_position.distance_to(pos) < radius:
			out.append(z)
	return out


# אפקט "טבעת" חולפת בעולם
func ring(pos: Vector2, radius: float, col: Color, life := 0.45) -> void:
	var r := RingFx.new()
	r.radius = radius
	r.color = col
	r.life = life
	player.get_parent().add_child(r)
	r.global_position = pos


class RingFx extends Node2D:
	var radius := 100.0
	var color := Color.WHITE
	var life := 0.45
	var _t := 0.0

	func _ready() -> void:
		z_index = 15

	func _process(delta: float) -> void:
		_t += delta
		if _t > life:
			queue_free()
		queue_redraw()

	func _draw() -> void:
		var k := _t / life
		draw_arc(Vector2.ZERO, radius * (0.3 + 0.7 * k), 0.0, TAU, 40, Color(color, 0.8 * (1.0 - k)), 4.0 * (1.0 - k) + 1.0, true)
		draw_circle(Vector2.ZERO, radius * (0.3 + 0.7 * k), Color(color, 0.08 * (1.0 - k)))
