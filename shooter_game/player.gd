extends CharacterBody2D
# ============================================================
#  השחקן. נוצר ע"י main.gd.
#  נקודת ה-(0,0) של השחקן היא כפות הרגליים.
#  מקשים:  A/D הליכה | SHIFT ריצה | W/רווח קפיצה | S/CTRL כריעה
#          עכבר = כיוון | לחצן שמאלי = ירי / זריקה | T = רובה/רימון | K = מוות
# ============================================================

signal health_changed(health: int, max_health: int)
signal weapon_changed(weapon: int)
signal died

const BulletScript := preload("res://bullet.gd")
const GrenadeScript := preload("res://grenade.gd")

enum { GUN, GRENADE }

# ---- תנועה (אפשר לשנות) ----
var walk_speed := 190.0
var run_speed := 320.0
var crouch_speed := 90.0
var jump_velocity := -620.0      # כמה חזק קופצים (שלילי = למעלה)
var gravity := 1500.0
var accel := 1800.0

# ---- נשק ----
var bullet_speed := 1300.0
var fire_delay := 0.12           # שניות בין יריות
var grenade_speed := 620.0
var grenade_delay := 0.7

# ---- חיים ----
var max_health := 10
var health := 10
var invuln_time := 0.6           # שניות שבהן אי אפשר להיפגע שוב

var world_w := 100000.0          # רוחב העולם (main.gd קובע)
var weapon := GUN
var dead := false

const W := 22.0
const H_STAND := 52.0
const H_CROUCH := 34.0

var _shape: CollisionShape2D
var _crouching := false
var _cooldown := 0.0
var _invuln := 0.0
var _walk_phase := 0.0
var _aim := Vector2.RIGHT
var _muzzle_flash := 0.0


func _ready() -> void:
	add_to_group("player")
	collision_layer = 2   # שכבה 2 = שחקן
	collision_mask = 1    # מתנגש רק בעולם (ריצפה ולבנים)
	_shape = CollisionShape2D.new()
	_shape.shape = RectangleShape2D.new()
	add_child(_shape)
	_set_height(H_STAND)
	z_index = 4


func _set_height(h: float) -> void:
	(_shape.shape as RectangleShape2D).size = Vector2(W, h)
	_shape.position = Vector2(0.0, -h / 2.0)


func _height() -> float:
	return H_CROUCH if _crouching else H_STAND


func _shoulder() -> Vector2:
	return Vector2(0.0, -_height() * 0.72)


func _physics_process(delta: float) -> void:
	_cooldown -= delta
	_invuln -= delta
	_muzzle_flash -= delta

	if not is_on_floor():
		velocity.y += gravity * delta

	if dead:
		velocity.x = move_toward(velocity.x, 0.0, accel * delta)
		move_and_slide()
		queue_redraw()
		return

	# כריעה
	var want_crouch := Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_CTRL)
	if want_crouch and not _crouching:
		_crouching = true
		_set_height(H_CROUCH)
	elif not want_crouch and _crouching and _can_stand():
		_crouching = false
		_set_height(H_STAND)

	# הליכה / ריצה
	var dir := 0.0
	if Input.is_physical_key_pressed(KEY_A):
		dir -= 1.0
	if Input.is_physical_key_pressed(KEY_D):
		dir += 1.0
	var speed := walk_speed
	if _crouching:
		speed = crouch_speed
	elif Input.is_physical_key_pressed(KEY_SHIFT):
		speed = run_speed
	velocity.x = move_toward(velocity.x, dir * speed, accel * delta)

	# קפיצה
	var jump := Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_SPACE)
	if jump and is_on_floor() and not _crouching:
		velocity.y = jump_velocity

	move_and_slide()
	global_position.x = clampf(global_position.x, W, world_w - W)

	if is_on_floor() and absf(velocity.x) > 10.0:
		_walk_phase += delta * absf(velocity.x) * 0.06
	else:
		_walk_phase = 0.0

	# כיוון ויריה
	var sh := global_position + _shoulder()
	_aim = (get_global_mouse_position() - sh).normalized()
	if _aim == Vector2.ZERO:
		_aim = Vector2.RIGHT
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and _cooldown <= 0.0:
		_fire(sh)

	queue_redraw()


func _can_stand() -> bool:
	var rect := RectangleShape2D.new()
	rect.size = Vector2(W - 2.0, H_STAND - 2.0)
	var q := PhysicsShapeQueryParameters2D.new()
	q.shape = rect
	q.transform = Transform2D(0.0, global_position + Vector2(0.0, -H_STAND / 2.0 - 1.0))
	q.collision_mask = 1
	q.exclude = [get_rid()]
	return get_world_2d().direct_space_state.intersect_shape(q, 1).is_empty()


func _fire(sh: Vector2) -> void:
	if weapon == GUN:
		_cooldown = fire_delay
		_muzzle_flash = 0.05
		var b = BulletScript.new()
		get_parent().add_child(b)
		var spread := randf_range(-0.03, 0.03)
		b.setup(sh + _aim * 30.0, _aim.rotated(spread) * bullet_speed, sh)
	else:
		_cooldown = grenade_delay
		var g = GrenadeScript.new()
		get_parent().add_child(g)
		g.setup(sh + _aim * 14.0, _aim * grenade_speed + velocity * 0.3)


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	if event.physical_keycode == KEY_T and not dead:
		weapon = GRENADE if weapon == GUN else GUN
		weapon_changed.emit(weapon)
	elif event.physical_keycode == KEY_K:
		hurt(health, Vector2.ZERO)


# נקרא ע"י זומבים ורימונים
func hurt(amount: int, knock_dir: Vector2) -> void:
	if dead or _invuln > 0.0:
		return
	_invuln = invuln_time
	health = maxi(health - amount, 0)
	health_changed.emit(health, max_health)
	velocity += Vector2(knock_dir.x * 260.0, -180.0)
	if health <= 0:
		dead = true
		died.emit()


# ============================================================
#  ציור הדמות
# ============================================================
func _draw() -> void:
	var face := 1.0 if _aim.x >= 0.0 else -1.0
	var h := _height()
	var skin := Color("f1c28f")
	var shirt := Color("3f6f3a")
	var pants := Color("2d3a55")
	if _invuln > 0.0 and int(_invuln * 20.0) % 2 == 0:
		skin = Color.WHITE
		shirt = Color.WHITE

	if dead:   # שוכב על הריצפה
		draw_rect(Rect2(-26, -10, 34, 10), shirt)
		draw_rect(Rect2(-26 + 34, -9, 14, 8), pants)
		draw_circle(Vector2(-32, -6), 7.0, skin)
		return

	# רגליים
	var leg_h := h * 0.36
	var swing := sin(_walk_phase) * 6.0
	draw_rect(Rect2(-8 + swing, -leg_h, 7, leg_h), pants)
	draw_rect(Rect2(1 - swing, -leg_h, 7, leg_h), pants.darkened(0.2))
	if not is_on_floor():
		draw_rect(Rect2(-8, -leg_h, 16, leg_h * 0.6), pants)
	# גוף
	var torso_top := -h * 0.8
	draw_rect(Rect2(-W / 2.0, torso_top, W, -leg_h - torso_top), shirt)
	draw_rect(Rect2(-W / 2.0, -leg_h - 4, W, 4), Color("3b2a1a"))   # חגורה
	# ראש
	var head := Vector2(face * 2.0, torso_top - 9.0)
	draw_circle(head, 9.0, skin)
	draw_rect(Rect2(head.x - 10, head.y - 11, 20, 7), Color("4c5a2a"))   # קסדה
	draw_rect(Rect2(head.x + face * 3.0 - 1.5, head.y - 2, 3, 3), Color.BLACK)   # עין

	# יד + נשק לכיוון העכבר
	var sh := _shoulder()
	var hand := sh + _aim * 14.0
	draw_line(sh, hand, skin, 5.0)
	if weapon == GUN:
		var tip := sh + _aim * 30.0
		draw_line(hand - _aim * 4.0, tip, Color("222222"), 5.0)
		draw_line(hand, hand + _aim.rotated(face * PI / 2.0) * 6.0, Color("222222"), 4.0)
		if _muzzle_flash > 0.0:
			draw_circle(tip + _aim * 4.0, 6.0, Color(1.0, 0.85, 0.3, 0.9))
	else:
		draw_circle(hand + _aim * 3.0, 5.0, Color("3a4a2a"))
		draw_rect(Rect2(hand + _aim * 3.0 + Vector2(-2, -8), Vector2(4, 3)), Color("888888"))
