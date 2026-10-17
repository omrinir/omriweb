extends "res://abilities/ability_base.gd"
# ============================================================
#  MORTAR STRIKE - מסמנים את הנקודה שמכוונים אליה (על הרצפה): עשן אדום + "!" ,
#  ואחרי DELAY נופלים SHELLS פגזים מסביב (weapons/rocket.gd -> mini_boom: אותו פיצוץ חלקיקים
#  של מיני-טילים). גם אתה נפגע אם אתה מתחת. POWER: יותר פגזים + נזק.
# ============================================================
const Rocket := preload("res://weapons/rocket.gd")
const DELAY := 1.1
const SHELLS := 4
const SPREAD := 120.0


func activate() -> bool:
	var aim: Vector2 = player.aim_world()
	var space: PhysicsDirectSpaceState2D = player.get_world_2d().direct_space_state
	var q := PhysicsRayQueryParameters2D.create(aim + Vector2(0, -40), aim + Vector2(0, 900), 1 | 16)
	var hit := space.intersect_ray(q)
	var spot: Vector2 = hit.position if hit else aim
	var m := Marker.new()
	m.shells = SHELLS + (1 if power >= 2 else 0) + (1 if power >= 4 else 0)
	m.dmg = 1.0 + 0.12 * float(power)
	player.get_parent().add_child(m)
	m.global_position = spot
	Sfx.play("beep", spot, 0.0)
	Sfx.play("rocket_split", null, -6.0, 0.05, 2, 0.6)   # שריקה רחוקה
	return true


class Marker extends Node2D:
	const Rocket := preload("res://weapons/rocket.gd")
	const Sfx := preload("res://sfx.gd")
	var shells := 4
	var dmg := 1.0
	var _t := 0.0
	var _hits := []   # [x, זמן נפילה]
	var _done := 0

	func _ready() -> void:
		z_index = 13
		for i in shells:
			_hits.append([randf_range(-SPREAD, SPREAD) * (0.3 if i == 0 else 1.0), DELAY + float(i) * 0.22 + randf_range(0.0, 0.08)])

	func _process(delta: float) -> void:
		_t += delta
		for h in _hits:
			if h[1] > 0.0 and _t >= h[1]:
				h[1] = -1.0
				_done += 1
				var at := global_position + Vector2(float(h[0]), -14.0)
				var q := PhysicsRayQueryParameters2D.create(at + Vector2(0, -200), at + Vector2(0, 300), 1 | 16)
				var hit := get_world_2d().direct_space_state.intersect_ray(q)
				if hit:
					at = hit.position + Vector2(0, -14)
				Rocket.mini_boom(get_parent(), at, dmg)
		if _done >= _hits.size() and _t > DELAY + 1.5:
			queue_free()
		queue_redraw()

	func _draw() -> void:
		var a := clampf(1.0 - (_t - DELAY - 0.8), 0.0, 1.0)
		var p := 0.5 + 0.5 * sin(_t * 18.0)
		draw_arc(Vector2(0, -2), SPREAD, PI, TAU, 32, Color(1.0, 0.25, 0.15, 0.35 * a), 2.0, true)
		draw_line(Vector2(-SPREAD, -2), Vector2(SPREAD, -2), Color(1.0, 0.25, 0.15, 0.5 * a * p), 2.0)
		draw_circle(Vector2(0, -6), 6.0, Color(1.0, 0.2, 0.1, 0.8 * a))
		for i in 4:   # עשן סימון אדום
			var sy := -10.0 - fposmod(_t * 50.0 + float(i) * 15.0, 60.0)
			draw_circle(Vector2(sin(_t * 3.0 + float(i)) * 5.0, sy), 6.0 + (-sy) * 0.15, Color(1.0, 0.3, 0.25, 0.18 * a))
		for h in _hits:   # פגזים שנופלים (שובל לבן מלמעלה)
			if float(h[1]) > 0.0 and _t > float(h[1]) - 0.45:
				var k := 1.0 - (float(h[1]) - _t) / 0.45
				var y := lerpf(-620.0, -14.0, k)
				draw_line(Vector2(float(h[0]), y - 60.0), Vector2(float(h[0]), y), Color(1, 1, 1, 0.3), 2.0, true)
				draw_circle(Vector2(float(h[0]), y), 3.5, Color("4a4a40"))
