extends "res://abilities/ability_base.gd"
# ============================================================
#  FLARE - זיקוק דרכים אדום שזורקים לכיוון הכוונה (במקום DECOY ECHO).
#  נוחת, בוער באור אדום חזק (גם מאיר שלבים חשוכים - קבוצה "dyn_lights") ומשמיע "רעש".
#  הזומבים חושבים שזה אתה: הוא בקבוצה "decoys" ויש לו מה שהמוח שואל על שחקן
#  (zombie.gd -> _target_for_brain). זומבים חכמים (adaptation_level) לפעמים מזהים את הטריק.
#  זומבי שמגיע אליו (BURN_R) - נדלק. POWER: משך, רדיוס הבעירה.
# ============================================================
const BURN_R := 60.0
const THROW := 700.0


func activate() -> bool:
	for d in player.get_tree().get_nodes_in_group("decoys"):
		d.queue_free()
	var f := Flare.new()
	f.life = duration()
	f.burn_r = BURN_R + 8.0 * float(power)
	f.burn_t = 1.6 + 0.3 * float(power)
	var dir: Vector2 = Vector2(player._aim.x, minf(player._aim.y, -0.35)).normalized()
	f.velocity = dir * THROW + Vector2(player.velocity.x * 0.4, 0.0)
	f.face = player._face()
	player.get_parent().add_child(f)
	f.global_position = player.global_position + player._front_shoulder()
	Sfx.play("throw", player.global_position, 2.0)
	return true


# הזיקוק = "השחקן המזויף" (יש לו מה שזומבים שואלים על שחקן)
class Flare extends Node2D:
	const Sfx := preload("res://sfx.gd")
	const Art := preload("res://art.gd")
	var life := 6.0
	var burn_r := 60.0
	var burn_t := 1.6
	var face := 1.0
	var dead := false
	var velocity := Vector2.ZERO
	var _crouching := false
	var _aim := Vector2.RIGHT
	var grabbed_by: Node = null
	var health := 1
	var gun := 0
	var _t := 0.0
	var _landed := false
	var _tick := 0.0
	var _noise := 0.0
	var _sparks := []   # [מיקום יחסי, מהירות, גיל]

	func _ready() -> void:
		add_to_group("decoys")
		add_to_group("dyn_lights")
		z_index = 9

	func _face() -> float:
		return face

	func is_vulnerable() -> bool:
		return false

	func is_reloading() -> bool:
		return false

	func body_rect() -> Rect2:
		return Rect2(global_position + Vector2(-11, -40), Vector2(22, 40))

	func hurt(_amount: int, _dir: Vector2) -> void:
		pass   # אי אפשר "להרוג" זיקוק - הוא נשרף עד הסוף

	func grab(_by: Node) -> void:
		pass

	func lights() -> Array:   # effects/dyn_lights.gd: מאיר את החושך
		return [[global_position + Vector2(0, -8), 230.0 * clampf(life, 0.0, 1.0), 0.9]]

	func _physics_process(delta: float) -> void:
		_t += delta
		if not _landed:
			velocity.y += 1300.0 * delta
			var to := global_position + velocity * delta
			var q := PhysicsRayQueryParameters2D.create(global_position, to + Vector2(0, 4), 1 | 16)
			var hit := get_world_2d().direct_space_state.intersect_ray(q)
			if hit:
				if hit.normal.y < -0.5:   # רצפה: נוחת
					global_position = hit.position
					_landed = true
					Sfx.play("fire_whoosh", global_position, -4.0)
				else:   # קיר: קופץ אחורה
					global_position = hit.position + hit.normal * 4.0
					velocity = velocity.bounce(hit.normal) * 0.35
			else:
				global_position = to
			queue_redraw()
			return
		life -= delta
		if life <= 0.0:
			dead = true
			queue_free()
			return
		_noise -= delta
		if _noise <= 0.0:   # שורק ומרעיש - מושך אותם
			_noise = 0.7
			Game.make_noise(global_position, 520.0)
		_tick -= delta
		if _tick <= 0.0:   # מי שהגיע אליו - נדלק
			_tick = 0.25
			for z in get_tree().get_nodes_in_group("zombies"):
				if not z.dead and z.global_position.distance_to(global_position) < burn_r:
					if z._burn_t <= 0.2:
						z.ignite(burn_t)
						z.take_damage(3, z.global_position + Vector2(0, -20), Vector2.UP, true, {"source": "ability", "incendiary": true})
		for i in 2:   # ניצוצות
			_sparks.append([Vector2(0, -6), Vector2(randf_range(-60, 60), randf_range(-150, -60)), 0.0])
		for s in _sparks:
			s[2] += delta
			s[1].y += 300.0 * delta
			s[0] += s[1] * delta
		_sparks = _sparks.filter(func(s): return s[2] < 0.45)
		if Art.on_screen(self, global_position):
			queue_redraw()

	func _draw() -> void:
		DrawBatch.begin(self)
		_draw_b()
		DrawBatch.end(self)

	func _draw_b() -> void:
		var k := clampf(life, 0.0, 1.0)
		var fl := 0.85 + 0.15 * sin(_t * 31.0) * sin(_t * 17.0)
		if _landed:
			Art.glow(self, Vector2(0, -8), 70.0 * k * fl, Color(1.0, 0.15, 0.08, 0.28))
			Art.glow(self, Vector2(0, -8), 26.0 * k * fl, Color(1.0, 0.55, 0.4, 0.7))
			DrawBatch.line(self, Vector2(-9, -1), Vector2(7, -4), Color("b01a14"), 4.0, true)   # הזיקוק שוכב
			DrawBatch.line(self, Vector2(-9, -1), Vector2(-5, -2), Color("2a2a2e"), 4.0, true)
			DrawBatch.circle(self, Vector2(8, -5), 3.4 * fl, Color(1.0, 0.92, 0.8, k))
			for s in _sparks:
				DrawBatch.circle(self, s[0], 1.3 * (1.0 - s[2] / 0.45), Color(1.0, 0.75, 0.4, 1.0 - s[2] / 0.45))
			for i in 3:   # עשן ורוד
				var sy := -14.0 - fposmod(_t * 30.0 + float(i) * 13.0, 40.0)
				DrawBatch.circle(self, Vector2(sin(_t * 2.0 + float(i)) * 4.0, sy), 5.0 + (-sy - 14.0) * 0.2, Color(1.0, 0.5, 0.5, 0.12 * k))
		else:
			DrawBatch.set_transform(self, Vector2.ZERO, _t * 12.0, Vector2.ONE)   # מסתובב באוויר
			DrawBatch.line(self, Vector2(-8, 0), Vector2(8, 0), Color("b01a14"), 4.0, true)
			DrawBatch.circle(self, Vector2(8, 0), 3.0, Color(1.0, 0.85, 0.7))
			DrawBatch.set_transform_matrix(self, Transform2D.IDENTITY)
			Art.glow(self, Vector2.ZERO, 22.0, Color(1.0, 0.3, 0.15, 0.5))
