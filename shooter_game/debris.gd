extends Node2D
# ============================================================
#  שבר של לבנה. נוצר ע"י brick.gd כשלבנה נסדקת או נשברת.
#  עף, נופל בכבידה, קופץ קצת על הריצפה ואז נעלם בהדרגה.
# ============================================================

var gravity := 1100.0     # כבידה של השברים
var life := 2.5           # כמה שניות השבר חי לפני שנעלם
var fade_time := 0.6      # כמה שניות בסוף החיים הוא דוהה
var bounce := 0.35        # כמה הוא קופץ כשהוא פוגע במשהו (0 = בכלל לא)
var size := Vector2(4, 4)
var color := Color("9a4f3a")
var velocity := Vector2.ZERO
var spin := 0.0


func setup(pos: Vector2, sz: Vector2, col: Color, vel: Vector2) -> void:
	global_position = pos
	size = sz
	color = col
	velocity = vel
	spin = randf_range(-8.0, 8.0)
	life = randf_range(1.8, 3.0)
	z_index = 5


func _physics_process(delta: float) -> void:
	life -= delta
	if life <= 0.0:
		queue_free()
		return
	velocity.y += gravity * delta
	var to := global_position + velocity * delta
	var query := PhysicsRayQueryParameters2D.create(global_position, to, 1)   # שכבה 1 = ריצפה ולבנים
	var hit := get_world_2d().direct_space_state.intersect_ray(query)
	if hit:
		global_position = hit.position + hit.normal * 0.5
		velocity = velocity.bounce(hit.normal) * bounce
		velocity.x *= 0.7
		spin *= 0.5
		if velocity.length() < 40.0:   # כמעט עצר - נשאר לשכב
			velocity = Vector2.ZERO
			spin = 0.0
	else:
		global_position = to
	rotation += spin * delta
	queue_redraw()


func _draw() -> void:
	var a := clampf(life / fade_time, 0.0, 1.0)
	draw_rect(Rect2(-size / 2.0, size), Color(color, a))
