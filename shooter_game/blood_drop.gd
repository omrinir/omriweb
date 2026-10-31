extends Node2D
const DrawBatch := preload("res://effects/draw_batch.gd")
# ============================================================
#  טיפת דם. עפה, נופלת בכבידה, וכשהיא פוגעת בלבנה / ריצפה
#  היא משאירה שם כתם (brick.gd -> add_blood).
# ============================================================

var gravity := 1100.0      # כבידה של הטיפות
var life := 3.0            # כמה שניות הטיפה חיה לפני שנעלמת
var radius := 2.0
var color := Color("a31616")
var velocity := Vector2.ZERO
static var alive := 0      # כמה טיפות קיימות (zombie.gd מגביל ל-MAX_BLOOD)
var _len := -1.0           # אורך השובל בציור האחרון (פיקסלים שלמים). הכיוון = הסיבוב של הצומת, בלי לצייר מחדש


func _enter_tree() -> void:
	alive += 1


func _exit_tree() -> void:
	alive -= 1


func setup(pos: Vector2, vel: Vector2) -> void:
	global_position = pos
	velocity = vel
	radius = randf_range(1.2, 2.8)
	color = Color("a31616").darkened(randf_range(0.0, 0.35))
	z_index = 8
	_aim()


func _physics_process(delta: float) -> void:
	life -= delta
	if life <= 0.0:
		queue_free()
		return
	velocity.y += gravity * delta
	var to := global_position + velocity * delta
	var query := PhysicsRayQueryParameters2D.create(global_position, to, 1 | 16)   # 1 = ריצפה ולבנים, 16 = קומות
	var hit := get_world_2d().direct_space_state.intersect_ray(query)
	if hit:
		if hit.collider.has_method("add_blood"):
			hit.collider.add_blood(hit.position, hit.normal, radius / 2.0)
		queue_free()
		return
	global_position = to
	_aim()


# הטיפה מסתובבת לכיוון התנועה; מציירים מחדש רק כשאורך השובל משתנה בפיקסל שלם (מאות טיפות בהריגה המונית)
func _aim() -> void:
	rotation += angle_difference(rotation, velocity.angle())   # (רציף, בלי קפיצה מ-PI ל--PI באמצע ההחלקה)
	var l := roundf(velocity.length() * 0.012)
	if l != _len:
		_len = l
		queue_redraw()


func _draw() -> void:
	DrawBatch.begin(self)
	_draw_b()
	DrawBatch.end(self)

func _draw_b() -> void:
	DrawBatch.line(self, Vector2(-_len, 0.0), Vector2.ZERO, color, radius * 2.0, true)
	DrawBatch.circle(self, Vector2.ZERO, radius, color)
