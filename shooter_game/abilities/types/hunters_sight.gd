extends "res://abilities/ability_base.gd"
# ============================================================
#  HUNTER'S SIGHT - לכמה שניות רואים את כל הזומבים דרך קירות, חושך ומחסות
#  (מסומנים באדום), כולל מארבים וצידים שהתחבאו. POWER: משך.
#  הציור עצמו: SightOverlay (z_index גבוה, מעל הכל).
# ============================================================
var _left := 0.0
var _ov: Node2D = null


func activate() -> bool:
	_left = duration()
	if _ov == null or not is_instance_valid(_ov):
		_ov = SightOverlay.new()
		player.get_parent().add_child(_ov)
	Sfx.play("boost", null, -2.0)
	return true


func active() -> bool:
	return _left > 0.0


func process(delta: float) -> void:
	_left -= delta
	if _ov != null and is_instance_valid(_ov):
		_ov.on = _left > 0.0
		_ov.fade = clampf(_left, 0.0, 1.0)


class SightOverlay extends Node2D:
	var on := false
	var fade := 1.0
	var _t := 0.0

	func _ready() -> void:
		z_index = 60

	func _process(delta: float) -> void:
		_t += delta
		queue_redraw()

	func _draw() -> void:
		if not on:
			return
		for z in get_tree().get_nodes_in_group("zombies"):
			if z.dead or not Art.on_screen(self, z.global_position):
				continue
			var h: float = 60.0 * z.sc
			var c: Vector2 = z.global_position + Vector2(0, -h * 0.5) - global_position
			var a := (0.55 + 0.25 * sin(_t * 8.0)) * fade
			draw_rect(Rect2(c - Vector2(14.0 * z.wf, h * 0.5), Vector2(28.0 * z.wf, h)), Color(1.0, 0.2, 0.15, a), false, 2.0)
			Art.glow(self, c, 22.0, Color(1.0, 0.15, 0.1, 0.25 * fade))
			if z.brain != null and z.brain.role == z.brain.AMBUSH:
				draw_string(ThemeDB.fallback_font, c + Vector2(-30, -h * 0.5 - 6), "AMBUSH", HORIZONTAL_ALIGNMENT_CENTER, 60, 11, Color(1, 0.4, 0.3, fade))
