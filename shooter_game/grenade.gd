extends Node2D
const Sfx := preload("res://sfx.gd")   # אפקטים קוליים
# ============================================================
#  רימון. נזרק ע"י player.gd, קופץ על הריצפה ומתפוצץ אחרי fuse שניות.
#  הפיצוץ: שובר לבנים קרובות, סודק רחוקות יותר, הורג זומבים
#  ומרעיד את המצלמה.
# ============================================================

const Art := preload("res://art.gd")
const Boom := preload("res://explosion.gd")

var fuse := 1.6            # שניות עד הפיצוץ
var radius := 120.0        # טווח הפיצוץ
var break_radius := 70.0   # לבנים במרחק הזה נשברות מיד
var damage := 40           # נזק לזומבים (לכל זומבי יש 30)
var gravity := 1300.0
var bounce := 0.45

var velocity := Vector2.ZERO
var source := "grenade"   # "boss_grenade" = נזרק ע"י הבוס (לא פוגע בו)
var impact := false       # משגר רימונים: מתפוצץ ברגע שהוא נוגע במשהו
var _spin := 0.0


func setup(pos: Vector2, vel: Vector2) -> void:
	global_position = pos
	velocity = vel
	add_to_group("grenades")   # זומבים חכמים בורחים מרימונים שנחתו לידם
	_spin = randf_range(-10.0, 10.0)
	z_index = 9


func _physics_process(delta: float) -> void:
	fuse -= delta
	if fuse <= 0.0:
		_explode()
		return
	velocity.y += gravity * delta
	var to := global_position + velocity * delta
	if impact:   # פוגע בזומבי = בום
		for z in get_tree().get_nodes_in_group("zombies"):
			if not z.dead and (z.global_position + Vector2(0, -28)).distance_to(to) < 26.0:
				global_position = to
				_explode()
				return
	var query := PhysicsRayQueryParameters2D.create(global_position, to, 1 | 16)   # 1 = ריצפה ולבנים, 16 = קומות
	var hit := get_world_2d().direct_space_state.intersect_ray(query)
	if hit and impact:
		global_position = hit.position
		_explode()
		return
	if hit and hit.normal != Vector2.ZERO:   # normal = 0 כשמתחילים בתוך לבנה
		global_position = hit.position + hit.normal * 4.0
		velocity = velocity.bounce(hit.normal) * bounce
		if velocity.length() > 80.0:
			Sfx.play("clink", global_position, -6.0, 0.15, 3)
		velocity.x *= 0.8
		_spin *= 0.6
		if velocity.length() < 30.0:
			velocity = Vector2.ZERO
	else:
		global_position = to
	rotation += _spin * delta
	queue_redraw()


func _explode() -> void:
	Boom.blast(get_parent(), global_position, radius, break_radius, damage, 2, source)
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
