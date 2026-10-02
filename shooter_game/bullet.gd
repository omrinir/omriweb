extends Node2D
# ============================================================
#  קליע. נוצר ע"י player.gd בכל ירייה.
#  הקליע בודק התנגשות עם קרניים (Raycast) כדי שלא יעבור דרך
#  לבנים דקות גם כשהוא מהיר מאוד.
# ============================================================

# ---- אפשר לשנות ----
var life_time := 2.0                       # כמה שניות הקליע חי לפני שנעלם
var length := 18.0                         # אורך הקו של הקליע
var width := 3.0                           # עובי
var bullet_color := Color(1.0, 0.9, 0.4)   # צבע
var collision_mask := 5                    # 1 = ריצפה ולבנים, 4 = זומבים
var damage := 1                            # כמה נזק הקליע עושה לזומבי

var velocity := Vector2.ZERO
var _cast_from := Vector2.ZERO
var _first := true


func setup(muzzle_pos: Vector2, vel: Vector2, check_from: Vector2) -> void:
	global_position = muzzle_pos
	velocity = vel
	rotation = vel.angle()
	_cast_from = check_from   # בצעד הראשון בודקים מהכתף, למקרה שהלוע בתוך קיר
	z_index = 10


func _physics_process(delta: float) -> void:
	life_time -= delta
	if life_time <= 0.0:
		queue_free()
		return
	var from := _cast_from if _first else global_position
	_first = false
	var to := global_position + velocity * delta
	var query := PhysicsRayQueryParameters2D.create(from, to, collision_mask)
	var hit := get_world_2d().direct_space_state.intersect_ray(query)
	if hit:
		if hit.collider.has_method("take_damage"):
			# שולחים גם את כיוון הקליע - לפיו הזומבי עף כשהוא מת
			hit.collider.take_damage(damage, hit.position, velocity.normalized())
		else:
			if hit.collider.has_method("hit_by_bullet"):   # לבנה - נסדקת / נשברת
				hit.collider.hit_by_bullet(hit.position, hit.normal, velocity.normalized())
			var fx := Impact.new()   # ניצוצות רק על לבנים
			get_parent().add_child(fx)
			fx.global_position = hit.position
			fx.setup(hit.normal)
		queue_free()
		return
	global_position = to


func _draw() -> void:
	draw_line(Vector2(-length, 0.0), Vector2.ZERO, Color(bullet_color, 0.35), width * 2.0, true)
	draw_line(Vector2(-length, 0.0), Vector2.ZERO, bullet_color, width, true)


# ---- ניצוצות כשהקליע פוגע ----
class Impact extends Node2D:
	var t := 0.0
	var duration := 0.25
	var dirs: Array[Vector2] = []

	func setup(normal: Vector2) -> void:
		z_index = 10
		for i in 7:
			dirs.append(Vector2.from_angle(normal.angle() + randf_range(-1.2, 1.2)) * randf_range(40.0, 140.0))

	func _process(delta: float) -> void:
		t += delta
		queue_redraw()
		if t >= duration:
			queue_free()

	func _draw() -> void:
		var k := t / duration
		for d in dirs:
			draw_circle(d * t, 2.2 * (1.0 - k), Color(1.0, 0.8, 0.3, 1.0 - k))
