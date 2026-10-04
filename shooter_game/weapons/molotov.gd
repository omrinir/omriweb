extends Node2D
# ============================================================
#  בקבוק תבערה (MOLOTOV) - עף בקשת, נשבר במגע ומשאיר שטח בוער.
#  השטח הבוער = environment/fire_zone.gd (מצית זומבים, פוגע גם בך!)
# ============================================================
const Sfx := preload("res://sfx.gd")
const FireZone := preload("res://environment/fire_zone.gd")
const Particles := preload("res://particles.gd")

var velocity := Vector2.ZERO
var gravity := 1100.0
var burn_time := 5.0      # כמה שניות האש בוערת
var burn_width := 120.0
var _spin := 0.0
var _t := 0.0


func setup(pos: Vector2, vel: Vector2) -> void:
	global_position = pos
	velocity = vel
	_spin = randf_range(8.0, 14.0) * signf(vel.x)
	z_index = 9
	add_to_group("grenades")
	PlayerMemory.on_explosive()


func _physics_process(delta: float) -> void:
	_t += delta
	velocity.y += gravity * delta
	var to := global_position + velocity * delta
	for z in get_tree().get_nodes_in_group("zombies"):
		if not z.dead and (z.global_position + Vector2(0, -28)).distance_to(to) < 24.0:
			_shatter(Vector2(to.x, z.global_position.y))
			return
	var q := PhysicsRayQueryParameters2D.create(global_position, to, 1 | 16)
	var hit := get_world_2d().direct_space_state.intersect_ray(q)
	if hit or _t > 4.0:
		_shatter(hit.position if hit else to)
		return
	global_position = to
	rotation += _spin * delta
	queue_redraw()


func _shatter(at: Vector2) -> void:
	Sfx.play("bottle_break", at, 0.0)
	Sfx.play("fire_whoosh", at, -2.0)
	Particles.burst(get_parent(), at, "fire", Vector2.UP, 18)
	# השטח הבוער נוחת על הריצפה שמתחת לנקודת הפגיעה
	var q := PhysicsRayQueryParameters2D.create(at + Vector2(0, -6), at + Vector2(0, 400), 1 | 16)
	var hit := get_world_2d().direct_space_state.intersect_ray(q)
	var fz = FireZone.new()
	fz.setup(burn_width, burn_time)
	get_parent().add_child(fz)
	fz.global_position = hit.position if hit else at
	queue_free()


func _draw() -> void:
	draw_colored_polygon(PackedVector2Array([Vector2(-6, -3), Vector2(3, -3), Vector2(5, -1.5), Vector2(10, -1.2), Vector2(10, 1.2), Vector2(5, 1.5), Vector2(3, 3), Vector2(-6, 3)]), Color(0.35, 0.55, 0.3, 0.9))
	draw_line(Vector2(10, 0), Vector2(13, -1.5), Color("d8c8a0"), 1.6)
	draw_circle(Vector2(14, -2), 3.0 + sin(_t * 30.0), Color(1.0, 0.6, 0.15, 0.9))
