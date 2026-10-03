extends Node2D
# ============================================================
#  כדור חומצה ירוק שזומבי SPITTER יורק בקשת.
#  פגיעה בשחקן = מינוס לב אחד. פגיעה בריצפה = שלולית קטנה שנעלמת.
# ============================================================

var velocity := Vector2.ZERO
var gravity := 900.0
var damage := 1
var _t := 0.0
var _splash := -1.0


func setup(pos: Vector2, vel: Vector2) -> void:
	global_position = pos
	velocity = vel
	z_index = 9


func _physics_process(delta: float) -> void:
	_t += delta
	if _splash >= 0.0:
		_splash += delta
		queue_redraw()
		if _splash > 1.2:
			queue_free()
		return
	velocity.y += gravity * delta
	var to := global_position + velocity * delta
	var p := get_tree().get_first_node_in_group("player")
	if p != null and not p.dead:
		var r: Rect2 = p.body_rect().grow(4.0)
		for i in 3:
			if r.has_point(global_position.lerp(to, float(i) / 2.0)):
				p.hurt(damage, Vector2(signf(velocity.x), 0.0))
				_splash = 0.0
				return
	var q := PhysicsRayQueryParameters2D.create(global_position, to, 1)
	var hit := get_world_2d().direct_space_state.intersect_ray(q)
	if hit:
		global_position = hit.position
		_splash = 0.0
		return
	global_position = to
	if _t > 4.0:
		queue_free()
	queue_redraw()


func _draw() -> void:
	var g := Color(0.55, 0.95, 0.2)
	if _splash >= 0.0:
		var a := 1.0 - _splash / 1.2
		draw_colored_polygon(PackedVector2Array([Vector2(-10, 0), Vector2(-6, -3), Vector2(4, -3), Vector2(10, 0), Vector2(4, 2), Vector2(-6, 2)]), Color(g, 0.7 * a))
		for i in 3:
			var k := fmod(_splash * 2.0 + float(i) * 0.3, 1.0)
			draw_circle(Vector2(-5 + i * 5, -k * 14.0), 1.5 * (1.0 - k), Color(0.7, 1.0, 0.4, a * (1.0 - k)))
		return
	draw_circle(Vector2.ZERO, 7.0, Color(g, 0.25))
	draw_circle(Vector2.ZERO, 4.0, g)
	draw_circle(Vector2(-1.2, -1.2), 1.4, Color(0.9, 1.0, 0.7))
	var tail := -velocity.normalized() * 8.0
	draw_line(Vector2.ZERO, tail, Color(g, 0.5), 3.0, true)
