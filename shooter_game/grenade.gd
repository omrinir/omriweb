extends Node2D
# ============================================================
#  רימון. נזרק ע"י player.gd, קופץ על הריצפה ומתפוצץ אחרי fuse שניות.
#  הפיצוץ: שובר לבנים קרובות, סודק רחוקות יותר, הורג זומבים
#  ומרעיד את המצלמה.
# ============================================================

const Art := preload("res://art.gd")

var fuse := 1.6            # שניות עד הפיצוץ
var radius := 120.0        # טווח הפיצוץ
var break_radius := 70.0   # לבנים במרחק הזה נשברות מיד
var damage := 10           # נזק לזומבים
var gravity := 1300.0
var bounce := 0.45

var velocity := Vector2.ZERO
var _spin := 0.0


func setup(pos: Vector2, vel: Vector2) -> void:
	global_position = pos
	velocity = vel
	_spin = randf_range(-10.0, 10.0)
	z_index = 9


func _physics_process(delta: float) -> void:
	fuse -= delta
	if fuse <= 0.0:
		_explode()
		return
	velocity.y += gravity * delta
	var to := global_position + velocity * delta
	var query := PhysicsRayQueryParameters2D.create(global_position, to, 1)   # שכבה 1 = ריצפה ולבנים
	var hit := get_world_2d().direct_space_state.intersect_ray(query)
	if hit and hit.normal != Vector2.ZERO:   # normal = 0 כשמתחילים בתוך לבנה
		global_position = hit.position + hit.normal * 4.0
		velocity = velocity.bounce(hit.normal) * bounce
		velocity.x *= 0.8
		_spin *= 0.6
		if velocity.length() < 30.0:
			velocity = Vector2.ZERO
	else:
		global_position = to
	rotation += _spin * delta
	queue_redraw()


func _explode() -> void:
	var c := global_position
	for b in get_tree().get_nodes_in_group("bricks"):
		if b.has_method("hit_by_blast"):
			var tl: Vector2 = b.global_position
			var sz: Vector2 = b.size
			var cp := Vector2(clampf(c.x, tl.x, tl.x + sz.x), clampf(c.y, tl.y, tl.y + sz.y))
			if c.distance_to(cp) <= radius:
				b.hit_by_blast(c, break_radius)
	for z in get_tree().get_nodes_in_group("zombies"):
		var zc: Vector2 = z.global_position + Vector2(0, -32)
		if c.distance_to(zc) <= radius:
			z.take_damage(damage, zc, (zc - c).normalized())
	var p := get_tree().get_first_node_in_group("player")
	if p != null:
		var pc: Vector2 = p.global_position + Vector2(0, -26)
		if c.distance_to(pc) <= radius * 0.6:
			p.hurt(2, Vector2(signf(pc.x - c.x), 0.0))
	var cam := get_viewport().get_camera_2d()
	if cam != null and cam.has_method("shake"):
		cam.shake(12.0, 0.35)
	var fx := Explosion.new()
	fx.radius = radius
	get_parent().add_child(fx)
	fx.global_position = c
	queue_free()


func _draw() -> void:
	var blink := fmod(fuse, 0.3) < 0.15
	if blink:   # הילה אדומה מהבהבת - כדי שיהיה קל לראות את הרימון
		Art.glow(self, Vector2.ZERO, 16.0, Color(1.0, 0.2, 0.1, 0.7))
	Art.oval_shaded(self, Vector2.ZERO, 6.5, 7.5, Color("6d8236"), 0.0, Art.OUTLINE, 1.6)
	draw_line(Vector2(-6.0, -1.0), Vector2(6.0, -1.0), Color(0, 0, 0, 0.4), 1.0, true)
	draw_line(Vector2(-6.0, 2.5), Vector2(6.0, 2.5), Color(0, 0, 0, 0.4), 1.0, true)
	Art.fill(self, PackedVector2Array([Vector2(-2.5, -7.0), Vector2(2.5, -7.0), Vector2(2.5, -10.0), Vector2(-2.5, -10.0)]), Color("9a9aa2"), Art.OUTLINE, 1.0)
	draw_line(Vector2(2.0, -9.5), Vector2(6.0, -4.0), Color("c0c0c8"), 1.5, true)   # ידית
	Art.disc(self, Vector2(0.0, -11.0), 1.8, Color(1, 0.3, 0.1) if blink else Color("551010"), Art.NONE)
	Art.oval(self, Vector2(-2.5, -3.5), 1.8, 1.2, Color(1, 1, 1, 0.35), -0.5, Art.NONE)


# ---- אפקט הפיצוץ ----
class Explosion extends Node2D:
	var t := 0.0
	var duration := 0.4
	var radius := 120.0

	func _ready() -> void:
		z_index = 20

	func _process(delta: float) -> void:
		t += delta
		queue_redraw()
		if t >= duration:
			queue_free()

	func _draw() -> void:
		var k := t / duration
		draw_circle(Vector2.ZERO, radius * (0.3 + 0.7 * k), Color(1.0, 0.6, 0.2, 0.5 * (1.0 - k)))
		draw_circle(Vector2.ZERO, radius * 0.5 * (1.0 - k), Color(1.0, 0.95, 0.7, 1.0 - k))
