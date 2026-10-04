extends "res://abilities/ability_base.gd"
# ============================================================
#  SILENCE - שדה שקט סביבך: זומבים בתוכו לא יכולים לקרוא אחד לשני, לקבל פקודות
#  או להצטרף להתקפה משולבת - חוזרים להתנהגות בסיסית. השדה זז איתך.
#  ai/squad_director.gd -> is_silenced(pos) בודק את זה. POWER: רדיוס + משך.
# ============================================================
var _left := 0.0
var _fx: Node2D = null


func radius() -> float:
	return 300.0 + 40.0 * float(power)


func activate() -> bool:
	_left = duration()
	var sd := player.get_tree().get_first_node_in_group("squad_director")
	if sd != null:
		sd.silence(player, radius(), _left)
	if _fx == null or not is_instance_valid(_fx):
		_fx = Field.new()
		player.add_child(_fx)
	Sfx.play("boost", player.global_position, -4.0)
	return true


func active() -> bool:
	return _left > 0.0


func process(delta: float) -> void:
	_left -= delta
	if _fx != null and is_instance_valid(_fx):
		_fx.r = radius()
		_fx.k = clampf(_left, 0.0, 1.0) if _left > 0.0 else 0.0


class Field extends Node2D:
	var r := 300.0
	var k := 0.0
	var _t := 0.0

	func _process(delta: float) -> void:
		_t += delta
		queue_redraw()

	func _draw() -> void:
		if k <= 0.0:
			return
		var c := Vector2(0, -26)
		draw_arc(c, r, 0.0, TAU, 64, Color(0.6, 0.85, 0.8, 0.35 * k), 2.0, true)
		for i in 6:   # גלים שקטים פנימה
			var rr := r * fmod(1.0 - _t * 0.3 - float(i) / 6.0, 1.0)
			draw_arc(c, rr, 0.0, TAU, 48, Color(0.6, 0.85, 0.8, 0.08 * k), 1.0, true)
