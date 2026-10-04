extends "res://abilities/ability_base.gd"
# ============================================================
#  BLOOD HOOK - שרשרת דם שתופסת את הזומבי הכי קרוב לכיוון הכוונה
#  ומושכת אותו אליך (גם מאחורי מחסה). POWER: טווח, נזק, ומושך עוד זומבי (רמה 3+).
# ============================================================


func activate() -> bool:
	var sh: Vector2 = player.global_position + player._front_shoulder()
	var rng_len := 360.0 + 45.0 * float(power)
	var targets := []
	for z in player.get_tree().get_nodes_in_group("zombies"):
		if z.dead or z.is_boss():
			continue
		var d: Vector2 = z.global_position + Vector2(0, -28) - sh
		if d.length() < rng_len and absf(d.angle_to(player._aim)) < 0.5:
			targets.append([d.length(), z])
	if targets.is_empty():
		return false
	targets.sort_custom(func(a, b): return a[0] < b[0])
	var n := 2 if power >= 3 else 1
	for i in mini(n, targets.size()):
		var z = targets[i][1]
		var dir: Vector2 = (sh - z.global_position).normalized()
		z._cover_state = 0
		z._duck_t = 0.0
		z.velocity = Vector2(dir.x * 620.0, -260.0)
		z.take_damage(4 + 2 * power, z.global_position + Vector2(0, -28), -dir, true, {"source": "ability"})
		var ln := HookLine.new()
		ln.a = sh
		ln.b = z.global_position + Vector2(0, -28)
		player.get_parent().add_child(ln)
	Sfx.play("hook", player.global_position, 0.0)
	return true


class HookLine extends Node2D:
	var a := Vector2.ZERO
	var b := Vector2.ZERO
	var _t := 0.3

	func _ready() -> void:
		z_index = 14

	func _process(delta: float) -> void:
		_t -= delta
		if _t <= 0.0:
			queue_free()
		queue_redraw()

	func _draw() -> void:
		draw_line(a, b, Color(0.85, 0.12, 0.12, _t * 3.0), 3.0, true)
		for i in 6:
			draw_circle(a.lerp(b, float(i) / 5.0), 2.5, Color(0.6, 0.05, 0.05, _t * 3.0))
