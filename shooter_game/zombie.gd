extends CharacterBody2D
# ============================================================
#  זומבי. הולך לאט, ורודף אחרי השחקן כשהוא קרוב.
#  נקודת ה-(0,0) של הזומבי היא כפות הרגליים.
#  כשהוא מת הוא עף לכיוון הקליע, מתרסק על לבנים ומשאיר דם.
# ============================================================

const BloodScript := preload("res://blood_drop.gd")

# ---- אפשר לשנות ----
var max_hp := 3                  # כמה קליעים צריך כדי להרוג
var walk_speed := 45.0
var chase_speed := 95.0
var chase_range := 520.0         # מאיזה מרחק הוא מתחיל לרדוף
var attack_damage := 1
var attack_delay := 0.8          # שניות בין נשיכות
var jump_velocity := -560.0
var gravity := 1500.0
var corpse_time := 6.0           # כמה שניות הגופה נשארת

var world_w := 100000.0          # רוחב העולם (main.gd קובע)
var hp := 3
var dead := false

const W := 20.0
const H := 50.0

var _shape: CollisionShape2D
var _dir := 1.0
var _wander_t := 0.0
var _attack_t := 0.0
var _flash := 0.0
var _walk_phase := 0.0
var _speed_mul := 1.0
var _tint := Color("6f9a5a")
# אחרי המוות
var _spin := 0.0
var _angle := 0.0
var _dead_t := 0.0
var _bled_on: Dictionary = {}


func _ready() -> void:
	add_to_group("zombies")
	collision_layer = 4   # שכבה 3 (ערך 4) = זומבים. הקליעים פוגעים בה
	collision_mask = 1    # מתנגש רק בעולם
	_shape = CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = Vector2(W, H)
	_shape.shape = r
	_shape.position = Vector2(0.0, -H / 2.0)
	add_child(_shape)
	hp = max_hp
	_dir = -1.0 if randf() < 0.5 else 1.0
	_speed_mul = randf_range(0.8, 1.25)
	_tint = Color("6f9a5a").lerp(Color("8a9a6a"), randf())
	_walk_phase = randf() * TAU
	z_index = 3


func _physics_process(delta: float) -> void:
	_flash -= delta
	_attack_t -= delta
	if dead:
		_dead_process(delta)
		return

	if not is_on_floor():
		velocity.y += gravity * delta

	var player := get_tree().get_first_node_in_group("player")
	var target_speed := walk_speed
	if player != null and not player.dead and global_position.distance_to(player.global_position) < chase_range:
		_dir = signf(player.global_position.x - global_position.x)
		if _dir == 0.0:
			_dir = 1.0
		target_speed = chase_speed
		# נשיכה
		var d: Vector2 = player.global_position - global_position
		if absf(d.x) < 26.0 and absf(d.y) < 50.0 and _attack_t <= 0.0:
			_attack_t = attack_delay
			player.hurt(attack_damage, Vector2(_dir, 0.0))
	else:
		_wander_t -= delta
		if _wander_t <= 0.0:
			_wander_t = randf_range(1.5, 4.0)
			_dir = -_dir if randf() < 0.5 else _dir

	velocity.x = move_toward(velocity.x, _dir * target_speed * _speed_mul, 600.0 * delta)
	move_and_slide()

	# נתקע בקיר: קופץ (או מסתובב אם הוא סתם מטייל)
	if is_on_wall() and is_on_floor():
		if target_speed == chase_speed:
			velocity.y = jump_velocity
		else:
			_dir = -_dir

	if global_position.x < W:
		global_position.x = W
		_dir = 1.0
	elif global_position.x > world_w - W:
		global_position.x = world_w - W
		_dir = -1.0

	_walk_phase += delta * absf(velocity.x) * 0.08
	queue_redraw()


# נקרא מ-bullet.gd ומ-grenade.gd
func take_damage(amount: int, hit_pos: Vector2, dir: Vector2) -> void:
	if dead:
		return
	hp -= amount
	_flash = 0.1
	_spray_blood(hit_pos, dir, 6, 260.0)
	if hp <= 0:
		_die(dir)
	else:
		velocity.x += dir.x * 120.0


func _die(dir: Vector2) -> void:
	dead = true
	remove_from_group("zombies")
	collision_layer = 0   # קליעים כבר לא פוגעים בגופה
	var r := _shape.shape as RectangleShape2D
	r.size = Vector2(18, 18)   # גופה = ריבוע קטן שמתגלגל
	_shape.position = Vector2(0.0, -9.0)
	velocity = Vector2(dir.x, minf(dir.y, 0.0)).normalized() * randf_range(420.0, 620.0) + Vector2(0.0, -260.0)
	_spin = randf_range(8.0, 14.0) * signf(velocity.x if velocity.x != 0.0 else 1.0)
	_spray_blood(global_position + Vector2(0, -30), dir, 14, 380.0)


func _dead_process(delta: float) -> void:
	_dead_t += delta
	if _dead_t > corpse_time:
		queue_free()
		return
	velocity.y += gravity * delta
	var impact_speed := velocity.length()
	move_and_slide()
	for i in get_slide_collision_count():
		var c := get_slide_collision(i)
		var col := c.get_collider()
		# התרסקות: כתם דם גדול על הלבנה
		if impact_speed > 200.0 and col != null and col.has_method("add_blood"):
			var key := col.get_instance_id()
			if _bled_on.get(key, 0.0) < _dead_t:
				_bled_on[key] = _dead_t + 0.15
				col.add_blood(c.get_position(), c.get_normal(), clampf(impact_speed / 200.0, 1.0, 3.0))
				_spray_blood(c.get_position(), c.get_normal(), 5, 160.0)
	if is_on_floor():
		velocity.x = move_toward(velocity.x, 0.0, 900.0 * delta)
		_spin = move_toward(_spin, 0.0, 30.0 * delta)
		var rest := PI / 2.0 if fposmod(_angle, TAU) < PI else PI * 1.5
		_angle = lerp_angle(_angle, rest, 8.0 * delta)
	if is_on_wall():
		velocity.x *= -0.3
	_angle += _spin * delta
	queue_redraw()


func _spray_blood(pos: Vector2, dir: Vector2, n: int, power: float) -> void:
	for i in n:
		var b = BloodScript.new()
		get_parent().add_child(b)
		var v := Vector2.from_angle(dir.angle() + randf_range(-0.8, 0.8)) * randf_range(power * 0.4, power)
		b.setup(pos, v + Vector2(0.0, -randf_range(40.0, 160.0)))


# ============================================================
#  ציור
# ============================================================
func _draw() -> void:
	var skin := _tint
	var shirt := Color("5a4a6a")
	var pants := Color("3a3448")
	if _flash > 0.0:
		skin = Color.WHITE
		shirt = Color.WHITE
		pants = Color.WHITE
	var face := _dir
	if dead:
		# מסובבים את כל הציור סביב מרכז הגופה
		draw_set_transform(Vector2(0, -9), _angle, Vector2.ONE)
		var a := clampf((corpse_time - _dead_t) / 1.0, 0.0, 1.0)
		skin.a = a
		shirt.a = a
		pants.a = a
		draw_rect(Rect2(-6, -2, 12, 22), pants)
		draw_rect(Rect2(-9, -20, 18, 20), shirt)
		draw_circle(Vector2(0, -27), 8.0, skin)
		draw_rect(Rect2(-9, -14, 18, 4), Color(0.6, 0.05, 0.05, a))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		return
	var swing := sin(_walk_phase) * 5.0
	draw_rect(Rect2(-7 + swing, -18, 6, 18), pants)
	draw_rect(Rect2(1 - swing, -18, 6, 18), pants.darkened(0.2))
	draw_rect(Rect2(-W / 2.0, -40, W, 22), shirt)
	draw_rect(Rect2(-3, -32, 6, 5), Color(0.55, 0.05, 0.05))   # פצע
	# ידיים מושטות קדימה
	draw_line(Vector2(0, -36), Vector2(face * 22.0, -34 + swing * 0.4), skin, 5.0)
	draw_line(Vector2(0, -32), Vector2(face * 20.0, -29 - swing * 0.4), skin.darkened(0.15), 5.0)
	var head := Vector2(face * 2.0, -46)
	draw_circle(head, 8.0, skin)
	draw_rect(Rect2(head.x + face * 2.0 - 1.5, head.y - 3, 3, 3), Color("ff3030"))   # עין אדומה
