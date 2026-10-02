extends Node2D
# ============================================================
#  רגל של זומבי שנתלשה (אחרי 2 קליעים ברגליים).
#  * נופלת לריצפה ונשארת שם.
#  * זומבי אחר שעובר עליה מרים אותה וזורק אותה על השחקן.
#  * פגיעה בשחקן מורידה לו damage חיים.
# ============================================================

const Art := preload("res://art.gd")

enum { GROUND, CARRIED, THROWN }

var damage := 1            # כמה חיים יורדים לשחקן מפגיעה
var gravity := 1100.0
var life := 40.0           # כמה שניות הרגל נשארת על הריצפה
var bounce := 0.3

var state := GROUND
var velocity := Vector2.ZERO
var carrier: Node = null
var _spin := 0.0
var _pick_delay := 0.8
var _pants := Color("3d3a4c")
var _skin := Color("86a06a")
var _shoe := Color("2c241e")
var _sc := 1.0


func setup(pos: Vector2, vel: Vector2, pants: Color, skin: Color, shoe: Color, sc: float) -> void:
	add_to_group("severed_legs")
	global_position = pos
	velocity = vel
	_pants = pants
	_skin = skin
	_shoe = shoe
	_sc = sc
	_spin = randf_range(-9.0, 9.0)
	rotation = PI / 2.0
	z_index = 6


func can_pickup() -> bool:
	return state == GROUND and _pick_delay <= 0.0


func pick(by: Node) -> void:
	state = CARRIED
	carrier = by
	velocity = Vector2.ZERO


func throw_at(from: Vector2, vel: Vector2) -> void:
	state = THROWN
	carrier = null
	global_position = from
	velocity = vel
	_spin = randf_range(12.0, 18.0) * signf(vel.x)


func drop(vel: Vector2) -> void:
	state = GROUND
	carrier = null
	velocity = vel
	_pick_delay = 0.8


func _physics_process(delta: float) -> void:
	if state == CARRIED:
		if not is_instance_valid(carrier) or carrier.dead:
			drop(Vector2(0.0, -100.0))
		return
	_pick_delay -= delta
	if state == GROUND:
		life -= delta
		modulate.a = clampf(life, 0.0, 1.0)
		if life <= 0.0:
			queue_free()
			return
	velocity.y += gravity * delta
	var to := global_position + velocity * delta

	if state == THROWN:
		var p := get_tree().get_first_node_in_group("player")
		if p != null and not p.dead:
			var r: Rect2 = p.body_rect().grow(6.0)
			for i in 4:
				if r.has_point(global_position.lerp(to, float(i) / 3.0)):
					p.hurt(damage, Vector2(signf(velocity.x), 0.0))
					velocity = Vector2(-velocity.x * 0.25, -180.0)
					_spin *= -0.5
					drop(velocity)
					return

	var query := PhysicsRayQueryParameters2D.create(global_position, to, 1)   # שכבה 1 = ריצפה ולבנים
	var hit := get_world_2d().direct_space_state.intersect_ray(query)
	if hit and hit.normal != Vector2.ZERO:   # normal = 0 כשמתחילים בתוך לבנה
		global_position = hit.position + hit.normal * 3.5 * _sc
		velocity = velocity.bounce(hit.normal) * bounce
		velocity.x *= 0.6
		_spin *= 0.4
		if state == THROWN:
			drop(velocity)
		if velocity.length() < 40.0:
			velocity = Vector2.ZERO
			_spin = 0.0
	else:
		global_position = to
	if velocity == Vector2.ZERO:   # שוכבת על הצד
		var rest := 0.0 if absf(wrapf(rotation, -PI, PI)) < PI / 2.0 else PI
		rotation = lerp_angle(rotation, rest, 10.0 * delta)
	else:
		rotation += _spin * delta
	queue_redraw()


# הרגל מצוירת לאורך ציר X: ירך משמאל, כף רגל מימין
func _draw() -> void:
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(_sc, _sc))
	var hip := Vector2(-11.0, 0.0)
	var knee := Vector2(0.5, 0.6)
	var mid := Vector2(5.0, 0.3)
	var ankle := Vector2(10.5, 0.0)
	Art.limb(self, PackedVector2Array([hip, knee, mid]), 7.0, _pants)
	Art.limb(self, PackedVector2Array([mid, ankle]), 5.2, _skin)
	if _shoe.a > 0.0:
		Art.fill(self, PackedVector2Array([ankle + Vector2(-1.0, -3.0), ankle + Vector2(3.0, -3.0), ankle + Vector2(4.0, -9.5), ankle + Vector2(2.0, -10.0), ankle + Vector2(-1.5, -6.5)]), _shoe, Art.OUTLINE, 1.0)
		Art.fill(self, PackedVector2Array([ankle + Vector2(-1.0, -3.0), ankle + Vector2(3.0, -3.0), ankle + Vector2(3.0, 3.0), ankle + Vector2(-1.0, 3.0)]), _shoe, Art.OUTLINE, 1.0)
	else:
		Art.fill(self, PackedVector2Array([ankle + Vector2(-1.0, -2.6), ankle + Vector2(2.5, -2.6), ankle + Vector2(3.5, -8.5), ankle + Vector2(1.5, -9.0), ankle + Vector2(-1.5, -5.5)]), _skin, Art.OUTLINE, 1.0)
	# הקצה הקרוע: דם ועצם
	Art.fill(self, PackedVector2Array([hip + Vector2(0.5, -4.0), hip + Vector2(-2.5, -2.5), hip + Vector2(-1.0, -0.5),
		hip + Vector2(-3.0, 1.5), hip + Vector2(-0.5, 2.5), hip + Vector2(0.5, 4.0)]), Color("8a0d0d"), Art.OUTLINE, 1.0)
	Art.limb(self, PackedVector2Array([hip + Vector2(0.0, -0.8), hip + Vector2(-3.5, -0.8)]), 1.6, Color("e8dcc4"), Art.NONE)   # עצם
	Art.oval(self, hip + Vector2(2.5, 0.5), 2.0, 1.2, Color(0.5, 0.03, 0.03, 0.7), 0.0, Art.NONE)
	draw_set_transform_matrix(Transform2D.IDENTITY)
