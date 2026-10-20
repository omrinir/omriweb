extends Node2D
const DrawBatch := preload("res://effects/draw_batch.gd")
# ============================================================
#  חלק גוף שעף (מוות "מתפוצץ לחתיכות", zombie.gd _burst_into_chunks; גם הרגליים של "פלג גוף זוחל").
#  סוגים: ARM (יד עם שרוול), LEG (מכנס + נעל), TORSO (בית חזה עם צלעות), MEAT (גוש בשר עם עצם).
#  * עף ומסתובב, ניתז על הריצפה / לבנים (כתם דם), מתגלגל ונעצר. נשאר LIFE שניות ונעלם.
#  * ביצועים: קרן אחת לפריים רק עד שנעצר. לכל היותר MAX_ALIVE חלקים בבת אחת.
#  לשנות: GRAVITY, BOUNCE, LIFE, MAX_ALIVE.
# ============================================================

const Art := preload("res://art.gd")
const Sfx := preload("res://sfx.gd")

enum { ARM, LEG, TORSO, MEAT }
const GRAVITY := 1150.0
const BOUNCE := 0.3
const LIFE := 6.0
const MAX_ALIVE := 48
const BONE := Color("e8dcc4")
const RED := Color("8a0d0d")
static var alive := 0

var kind := MEAT
var velocity := Vector2.ZERO
var skin := Color("86a06a")
var cloth := Color("3d3a4c")      # שרוול / מכנס / חולצה
var shoe := Color("2c241e")
var sc := 1.0
var zombie: Node = null            # בשביל _spray_blood (יכול להימחק לפני החלק)
var _spin := 0.0
var _life := LIFE
var _rest := false
var _bounces := 0
var _trail := 0.0
var _seed := 0.0


static func can_spawn() -> bool:
	return alive < MAX_ALIVE


func setup(k: int, pos: Vector2, vel: Vector2, z: Node, col: Color) -> void:
	alive += 1
	kind = k
	global_position = pos
	velocity = vel
	zombie = z
	skin = z.skin
	cloth = col
	shoe = z.shoe if z.shoe.a > 0.0 else z.skin
	sc = z.sc
	_spin = randf_range(8.0, 16.0) * (1.0 if randf() < 0.5 else -1.0)
	_seed = randf() * 10.0
	rotation = randf() * TAU
	z_index = 6


func _exit_tree() -> void:
	alive -= 1


func _radius() -> float:
	return [3.0, 3.5, 6.0, 2.5][kind] * sc


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
	var rr := _radius()
	var hit := get_world_2d().direct_space_state.intersect_ray(PhysicsRayQueryParameters2D.create(global_position, to + velocity.normalized() * rr, 1 | 16))
	var on_ground := false
	if not hit.is_empty() and hit.normal != Vector2.ZERO and (hit.normal.y < -0.5 or (hit.collider as CollisionObject2D).collision_layer & 1 != 0):
		var n: Vector2 = hit.normal
		var speed := velocity.length()
		global_position = hit.position + n * rr
		if speed > 220.0:
			if hit.collider != null and hit.collider.has_method("add_blood"):
				hit.collider.add_blood(hit.position, n, clampf(speed / 260.0, 1.0, 2.2))
			if _bounces == 0 and Art.on_screen(self, global_position):
				Sfx.play("corpse_splat", global_position, -8.0, 0.2, 4, 1.15)
			_bounces += 1
		velocity = velocity.bounce(n) * BOUNCE
		velocity.x *= 0.7
		on_ground = n.y < -0.5
		if on_ground and absf(velocity.y) < 60.0:
			velocity.y = 0.0
	else:
		global_position = to
	if on_ground:
		velocity.x = move_toward(velocity.x, 0.0, 420.0 * delta)
		_spin = move_toward(_spin, 0.0, 30.0 * delta)
		if absf(velocity.x) < 10.0:
			_rest = true
	rotation += _spin * delta
	_trail -= delta
	if _trail <= 0.0 and velocity.length() > 160.0 and _life > LIFE - 0.8 and is_instance_valid(zombie) and kind != MEAT and alive < 24:   # שובל דם
		_trail = 0.06
		zombie._spray_blood(global_position, -velocity.normalized(), 1, 80.0)
	if Art.on_screen(self, global_position, 40.0):
		queue_redraw()


func _draw() -> void:
	DrawBatch.begin(self)
	_draw_b()
	DrawBatch.end(self)

func _draw_b() -> void:
	DrawBatch.set_transform(self, Vector2.ZERO, 0.0, Vector2(sc, sc))
	match kind:
		ARM:   # לאורך X: כתף קרועה משמאל, יד מימין
			Art.limb(self, PackedVector2Array([Vector2(-9, 0), Vector2(-1, 0.5)]), 5.0, cloth)
			Art.limb(self, PackedVector2Array([Vector2(-1, 0.5), Vector2(8, -0.5)]), 3.8, skin)
			Art.disc(self, Vector2(9.5, -0.5), 2.4, skin)
			_stump(Vector2(-9, 0), 2.6)
		LEG:
			Art.limb(self, PackedVector2Array([Vector2(-11, 0), Vector2(0, 0.6), Vector2(4, 0.3)]), 6.6, cloth)
			Art.limb(self, PackedVector2Array([Vector2(4, 0.3), Vector2(10, 0)]), 5.0, skin)
			Art.fill(self, PackedVector2Array([Vector2(9.5, -3.0), Vector2(13.0, -3.0), Vector2(13.5, -9.0), Vector2(11.0, -9.5), Vector2(8.5, -6.0)]), shoe, Art.OUTLINE, 1.0)
			_stump(Vector2(-11, 0), 3.2)
		TORSO:   # בית חזה קרוע: חולצה, צלעות חשופות למטה, מעיים תלויים
			Art.fill_shaded(self, PackedVector2Array([Vector2(-6, -9), Vector2(6, -9), Vector2(7, 3), Vector2(-7, 3)]), cloth, 0.15, 0.35)
			Art.fill(self, PackedVector2Array([Vector2(-7, 3), Vector2(-4, 8), Vector2(-1, 5), Vector2(2, 9), Vector2(5, 5), Vector2(7, 3)]), RED, Art.OUTLINE, 1.0)
			for i in 4:   # צלעות
				var y := -2.0 + float(i) * 2.2
				DrawBatch.line(self, Vector2(-5.5, y), Vector2(5.5, y + 0.6), BONE, 1.2, true)
			DrawBatch.line(self, Vector2(0, -9), Vector2(0, 7), BONE.darkened(0.15), 1.6, true)   # עמוד שדרה
			var sw := sin(_seed + _life * 6.0) * 1.5
			DrawBatch.polyline(self, PackedVector2Array([Vector2(-2, 7), Vector2(-3 + sw, 11), Vector2(-1, 14)]), Color(0.72, 0.32, 0.36), 1.6, true)
		MEAT:
			Art.oval(self, Vector2.ZERO, 3.0, 2.2, RED, _seed, Art.OUTLINE, 1.0)
			Art.oval(self, Vector2(-0.6, -0.4), 1.6, 1.0, Color(0.55, 0.04, 0.05), _seed, Art.NONE)
			DrawBatch.line(self, Vector2(-1.5, 0.5), Vector2(2.5, -0.5), BONE, 1.0, true)
	DrawBatch.set_transform_matrix(self, Transform2D.IDENTITY)


func _stump(at: Vector2, r: float) -> void:
	Art.fill(self, PackedVector2Array([at + Vector2(0.5, -r), at + Vector2(-2.0, -r * 0.5), at + Vector2(-0.8, 0.0), at + Vector2(-2.4, r * 0.5), at + Vector2(0.5, r)]), RED, Art.OUTLINE, 1.0)
	Art.limb(self, PackedVector2Array([at, at + Vector2(-3.0, 0.0)]), 1.5, BONE, Art.NONE)
