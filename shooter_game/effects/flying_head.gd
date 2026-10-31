extends Node2D
const DrawBatch := preload("res://effects/draw_batch.gd")
# ============================================================
#  ראש של זומבי שעף מהכתפיים (מוות "הולך בלי ראש", zombie.gd _start_headless_walk).
#  * עף, מסתובב, משאיר שובל דם, ניתז על הריצפה / לבנים ומתגלגל עד שעוצר.
#  * נשאר על הריצפה LIFE שניות ונעלם.
#  לשנות: GRAVITY, BOUNCE, ROLL_FRICTION, LIFE, TRAIL_EVERY.
# ============================================================

const Art := preload("res://art.gd")
const Ragdoll := preload("res://effects/ragdoll.gd")   # כיפת השיער (HAIR_CAP) כמו בגופה
const Sfx := preload("res://sfx.gd")

const GRAVITY := 1150.0
const BOUNCE := 0.35
const ROLL_FRICTION := 260.0      # האטה בגלגול על הריצפה (פיקסלים לשנייה בשנייה)
const LIFE := 7.0
const TRAIL_EVERY := 0.04
const MAX_ALIVE := 12
static var alive := 0

var velocity := Vector2.ZERO
var zombie: Node = null           # רק בשביל _spray_blood (יכול להימחק לפני הראש)
var skin := Color("86a06a")
var hair := Color("3a3026")
var bald := false
var kind := 0
var sc := 1.0
var cust = null                   # דמות מ-CHARACTER MAKER: השיער / הכובע שלה (characters/custom_character.gd)
var _spin := 0.0
var _life := LIFE
var _trail := 0.0
var _rest := false
var _bounces := 0


func setup(pos: Vector2, vel: Vector2, z: Node) -> void:
	alive += 1
	global_position = pos
	velocity = vel
	zombie = z
	skin = z.skin
	hair = z.hair
	bald = z._bald
	kind = z.kind
	sc = z.sc
	cust = z.cust
	_spin = randf_range(9.0, 15.0) * signf(vel.x if vel.x != 0.0 else 1.0)
	z_index = 6


func _exit_tree() -> void:
	alive -= 1


func _physics_process(delta: float) -> void:
	_life -= delta
	modulate.a = clampf(_life, 0.0, 1.0)
	if _life <= 0.0:
		queue_free()
		return
	if _rest:
		return
	velocity.y += GRAVITY * delta
	var to := global_position + velocity * delta
	var space := get_world_2d().direct_space_state
	var hit := space.intersect_ray(PhysicsRayQueryParameters2D.create(global_position, to + velocity.normalized() * 6.0 * sc, 1 | 16))
	var on_ground := false
	if not hit.is_empty() and hit.normal != Vector2.ZERO and (hit.normal.y < -0.5 or (hit.collider as CollisionObject2D).collision_layer & 1 != 0):
		var n: Vector2 = hit.normal
		var speed := velocity.length()
		global_position = hit.position + n * 6.0 * sc
		if speed > 200.0:   # ניתז: כתם דם על המשטח + צליל
			if hit.collider != null and hit.collider.has_method("add_blood"):
				hit.collider.add_blood(hit.position, n, clampf(speed / 250.0, 1.0, 2.5))
			if _bounces < 3 and Art.on_screen(self, global_position):
				Sfx.play("corpse_splat", global_position, -4.0, 0.15, 3, 1.3)
			_bounces += 1
		velocity = velocity.bounce(n) * BOUNCE
		on_ground = n.y < -0.5
		if on_ground and absf(velocity.y) < 70.0:
			velocity.y = 0.0
	else:
		global_position = to
	if on_ground or (absf(velocity.y) < 1.0 and _bounces > 0):
		velocity.x = move_toward(velocity.x, 0.0, ROLL_FRICTION * delta)
		_spin = velocity.x / (6.5 * sc)   # מתגלגל (לא מחליק)
		if absf(velocity.x) < 8.0 and absf(velocity.y) < 8.0:
			_rest = true
	rotation += _spin * delta
	# שובל דם מהצוואר בזמן שהוא עף
	_trail -= delta
	if _trail <= 0.0 and velocity.length() > 120.0 and _life > LIFE - 1.2 and is_instance_valid(zombie):
		_trail = TRAIL_EVERY
		zombie._spray_blood(global_position, -velocity.normalized(), 1, 90.0)
	if Art.on_screen(self, global_position, 40.0):
		queue_redraw()


func _draw() -> void:
	DrawBatch.begin(self)
	_draw_b()
	DrawBatch.end(self)

func _draw_b() -> void:
	# כמו הראש של הגופה (effects/ragdoll.gd): x קדימה, y למטה, הצוואר למטה
	var hs: float = cust.head_k if cust != null else 1.0
	var k := Ragdoll.HEAD_K * sc * hs
	var L := func(x: float, y: float) -> Vector2: return Vector2(x * k, y * k)
	var hx := Transform2D(0.0, Vector2(k, k), 0.0, Vector2.ZERO)
	# צוואר קרוע: בשר אדום + חוליה
	Art.fill(self, PackedVector2Array([L.call(-3.5, 5.5), L.call(-1.0, 9.5), L.call(1.0, 7.0), L.call(3.0, 10.0), L.call(4.0, 5.5)]), Color("8a0d0d"), Art.OUTLINE, 1.0)
	Art.limb(self, PackedVector2Array([L.call(0.3, 6.0), L.call(0.6, 10.5)]), 1.8 * sc, Color("e8dcc4"), Art.NONE)
	if cust != null:
		DrawBatch.set_transform_matrix(self, hx)
		cust.draw_dead_head(self, true)
		DrawBatch.set_transform_matrix(self, Transform2D.IDENTITY)
	elif kind == 1:   # RUNNER: שיער ארוך פרוע
		for i in 5:
			var a: Vector2 = L.call(-4.0 + float(i) * 1.2, -6.5 + float(i) * 0.4)
			DrawBatch.line(self, a, a + Vector2(-8.0 - float(i), 4.0 + float(i)) * sc, hair, 2.0 * sc, true)
	elif kind != 2 and not bald:
		Art.oval(self, L.call(-2.5, -2.5), 6.0 * k, 5.5 * k, hair, 0.0, Art.OUTLINE, 1.0)
	Art.oval_shaded(self, Vector2.ZERO, 6.0 * sc * hs, 6.6 * sc * hs, skin, 0.0)
	if cust == null and kind != 2 and kind != 5 and kind != 7 and kind != 9:
		if not bald:
			var cap := PackedVector2Array()
			for v: Vector2 in Ragdoll.HAIR_CAP:
				cap.append(L.call(v.x, v.y))
			DrawBatch.colored_polygon(self, cap, hair)
		else:
			Art.oval(self, L.call(-2.0, -5.0), 2.2 * k, 1.4 * k, Color(0.42, 0.06, 0.05, 0.75), 0.0, Art.NONE)
	var eye := Vector2(2.6, -0.5) * sc
	DrawBatch.line(self, eye + Vector2(-1.4, -1.4) * sc, eye + Vector2(1.4, 1.4) * sc, Color(0.1, 0.05, 0.05), 1.2)   # עין X
	DrawBatch.line(self, eye + Vector2(-1.4, 1.4) * sc, eye + Vector2(1.4, -1.4) * sc, Color(0.1, 0.05, 0.05), 1.2)
	DrawBatch.line(self, Vector2(3.5, 2.5) * sc, Vector2(1.0, 3.0) * sc, Color(0.25, 0.05, 0.05), 1.4)   # פה פעור
	Art.oval(self, Vector2(2.4, 3.2) * sc, 1.6 * sc, 1.0 * sc, Color(0.2, 0.02, 0.03), 0.0, Art.NONE)
	if cust != null:
		DrawBatch.set_transform_matrix(self, hx)
		cust.draw_dead_head(self, false)
		DrawBatch.set_transform_matrix(self, Transform2D.IDENTITY)
