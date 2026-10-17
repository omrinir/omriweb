extends "res://abilities/ability_base.gd"
# ============================================================
#  SHOCK BLAST (id "dark_pulse" נשמר בשביל שמירות ישנות) - המכשיר שלך משתחרר בגל חשמלי:
#  הודף, משתק ופוגע בכל הזומבים בטווח, ומשחרר מתפיסה. ברק לכל זומבי שנפגע.
#  שובר גם את ההגנה של זומבים עם מגן (ההדף עובר מסביב). POWER: רדיוס, הדף, נזק.
# ============================================================


func activate() -> bool:
	var c: Vector2 = player.global_position + Vector2(0, -26)
	var r := 150.0 + 20.0 * float(power)
	if player.grabbed_by != null and is_instance_valid(player.grabbed_by):
		player.grabbed_by.release_grab()
		player.grabbed_by = null
	var zs := zombies_near(c, r)
	if not zs.is_empty():
		var zap := Zap.new()
		zap.from = c
		for z in zs:
			zap.to.append(z.global_position + Vector2(0, -26))
		player.get_parent().add_child(zap)
	for z in zs:
		var dir: Vector2 = (z.global_position + Vector2(0, -26) - c).normalized()
		z.velocity = Vector2(signf(dir.x) * (420.0 + 60.0 * float(power)), -220.0) * (0.4 if z.is_boss() else 1.0)
		z.stagger(0.9 + 0.15 * float(power))
		z.take_damage(5 + 3 * power, z.global_position + Vector2(0, -26), dir, true, {"source": "ability"})
	ring(c, r, Color("5ac8ff"), 0.5)
	ring(c, r * 0.6, Color(1, 1, 1), 0.3)
	Particles.burst(player.get_parent(), c, "smoke", Vector2.ZERO, 10)
	Sfx.play("zap", c, 4.0)
	Sfx.play("explosion", c, -8.0, 0.1, 4, 1.4)
	var cam := player.get_viewport().get_camera_2d()
	if cam != null and cam.has_method("shake"):
		cam.shake(8.0, 0.25)
	return true


# ברקים קצרים מהשחקן לכל זומבי שנפגע
class Zap extends Node2D:
	var from := Vector2.ZERO
	var to := []
	var _t := 0.22

	func _ready() -> void:
		z_index = 15

	func _process(delta: float) -> void:
		_t -= delta
		if _t <= 0.0:
			queue_free()
		queue_redraw()

	func _draw() -> void:
		var a := clampf(_t / 0.22, 0.0, 1.0)
		for p in to:
			var pts := PackedVector2Array([from])
			for i in range(1, 6):
				pts.append(from.lerp(p, float(i) / 6.0) + Vector2(randf_range(-9, 9), randf_range(-9, 9)))
			pts.append(p)
			draw_polyline(pts, Color(0.35, 0.8, 1.0, 0.5 * a), 4.0, true)
			draw_polyline(pts, Color(0.9, 0.97, 1.0, a), 1.4, true)
