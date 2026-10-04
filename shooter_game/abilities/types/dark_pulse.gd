extends "res://abilities/ability_base.gd"
# ============================================================
#  DARK PULSE - גל הדף סביבך: הודף, מעכב ופוגע בכל הזומבים בטווח, ומשחרר מתפיסה.
#  שובר גם את ההגנה של זומבים עם מגן (ההדף עובר מסביב). POWER: רדיוס, הדף, נזק.
# ============================================================


func activate() -> bool:
	var c: Vector2 = player.global_position + Vector2(0, -26)
	var r := 150.0 + 20.0 * float(power)
	if player.grabbed_by != null and is_instance_valid(player.grabbed_by):
		player.grabbed_by.release_grab()
		player.grabbed_by = null
	for z in zombies_near(c, r):
		var dir: Vector2 = (z.global_position + Vector2(0, -26) - c).normalized()
		z.velocity = Vector2(signf(dir.x) * (420.0 + 60.0 * float(power)), -220.0) * (0.4 if z.is_boss() else 1.0)
		z.stagger(0.9 + 0.15 * float(power))
		z.take_damage(5 + 3 * power, z.global_position + Vector2(0, -26), dir, true, {"source": "ability"})
	ring(c, r, Color("b050ff"), 0.5)
	Particles.burst(player.get_parent(), c, "smoke", Vector2.ZERO, 14)
	Sfx.play("explosion", c, -6.0)
	var cam := player.get_viewport().get_camera_2d()
	if cam != null and cam.has_method("shake"):
		cam.shake(8.0, 0.25)
	return true
