extends "res://abilities/ability_base.gd"
# ============================================================
#  PHANTOM STEP - קפיצת צל לכיוון הכוונה (עוברת דרך זומבים, נעצרת בקירות).
#  זומבים קרובים מאבדים אותך (הזיכרון שלהם נשאר במקום הישן). POWER: מרחק.
# ============================================================


func activate() -> bool:
	var from: Vector2 = player.global_position
	var dir: Vector2 = Vector2(player._aim.x, minf(player._aim.y, 0.2)).normalized()
	var dist := 150.0 + 25.0 * float(power)
	var q := PhysicsRayQueryParameters2D.create(from + Vector2(0, -26), from + Vector2(0, -26) + dir * dist, 1)
	var hit: Dictionary = player.get_world_2d().direct_space_state.intersect_ray(q)
	var to: Vector2 = from + dir * dist
	if hit:
		to = hit.position - dir * 18.0 + Vector2(0, 26)
	if to.distance_to(from) < 30.0:
		return false
	ring(from + Vector2(0, -26), 50.0, Color("8a7aff"))
	Particles.burst(player.get_parent(), from + Vector2(0, -26), "smoke", Vector2.ZERO, 10)
	player.global_position = to
	player.velocity = Vector2(dir.x * 120.0, minf(player.velocity.y, 0.0))
	player._invuln = maxf(player._invuln, 0.35)
	ring(to + Vector2(0, -26), 60.0, Color("8a7aff"))
	Sfx.play("whoosh", to, 3.0)
	for z in zombies_near(from, 420.0):   # מאבדים אותך: זוכרים רק איפה היית
		if z.brain != null:
			z.brain.sees = false
			z.brain.last_seen = from
			z.brain.seen_t = float(z.brain.p.get("memory_duration", 3.0)) * 0.7
	return true
