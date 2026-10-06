extends Node2D
# ============================================================
#  ROCKET - טיל של ה-ROCKET LAUNCHER (weapons/weapon_db.gd: "projectile": "rocket").
#  טיל אחד עף ישר (עשן + להבה), ואחרי SPLIT_DIST פיקסלים מתפצל ל-3 טילים קטנים במניפה.
#  כל טיל קטן מתפוצץ כשהוא פוגע בזומבי / קיר / רצפה (או אחרי MINI_RANGE) - פיצוץ קטן
#  (MINI_RADIUS, בערך חצי מפיצוץ רגיל) שעשוי כולו מחלקיקים: כדור אש, ניצוצות, עשן, שברים והבזק.
#  פגע במשהו לפני הפיצול? 3 פיצוצים קטנים מסביב לנקודת הפגיעה.
#  לשנות: SPEED, SPLIT_DIST, SPREAD, MINI_SPEED, MINI_RANGE, MINI_RADIUS, MINI_DAMAGE.
# ============================================================

const Sfx := preload("res://sfx.gd")
const Art := preload("res://art.gd")

const SPEED := 640.0
const SPLIT_DIST := 230.0
const SPREAD := 0.24            # זווית בין הטילים הקטנים (רדיאנים)
const MINI_SPEED := 820.0
const MINI_RANGE := 640.0
const MINI_RADIUS := 62.0       # פיצוץ רגיל ~110-120
const MINI_DAMAGE := 26
const BREAK_RADIUS := 40.0
const HOMING := 2.2             # טיל קטן מתעקם קצת לעבר זומבי שמולו (רדיאנים/שנייה). 0 = ישר
const HOMING_CONE := 0.55       # רק זומבים בתוך הזווית הזו מהכיוון שלו
const HOMING_RANGE := 520.0

static var _blast_id := 100000
static var _soft: Texture2D      # עיגול רך לחלקיקים (במקום ריבועים)


static func soft_tex() -> Texture2D:
	if _soft == null:
		var g := Gradient.new()
		g.set_color(0, Color(1, 1, 1, 1))
		g.add_point(0.45, Color(1, 1, 1, 0.75))
		g.set_color(g.get_point_count() - 1, Color(1, 1, 1, 0))
		var t := GradientTexture2D.new()
		t.gradient = g
		t.width = 32
		t.height = 32
		t.fill = GradientTexture2D.FILL_RADIAL
		t.fill_from = Vector2(0.5, 0.5)
		t.fill_to = Vector2(1.0, 0.5)
		_soft = t
	return _soft

var velocity := Vector2.ZERO
var damage_mult := 1.0
var mini := false               # טיל קטן (אחרי הפיצול)
var _dist := 0.0
var _t := 0.0
var _trail: CPUParticles2D
var _done := false


func setup(pos: Vector2, vel: Vector2) -> void:
	global_position = pos
	velocity = vel
	rotation = vel.angle()


func _ready() -> void:
	z_index = 7
	_trail = CPUParticles2D.new()   # שובל עשן
	_trail.local_coords = false
	_trail.amount = 40 if not mini else 22
	_trail.lifetime = 0.7
	_trail.direction = Vector2(-1, 0)
	_trail.spread = 14.0
	_trail.gravity = Vector2(0, -30)
	_trail.initial_velocity_min = 20.0
	_trail.initial_velocity_max = 60.0
	_trail.texture = soft_tex()
	_trail.scale_amount_min = 0.3 if not mini else 0.22
	_trail.scale_amount_max = 0.55 if not mini else 0.38
	var sc := Curve.new()
	sc.add_point(Vector2(0, 0.6))
	sc.add_point(Vector2(1, 1.8))
	_trail.scale_amount_curve = sc
	var g := Gradient.new()
	g.set_color(0, Color(1.0, 0.85, 0.45, 0.9))
	g.add_point(0.15, Color(0.75, 0.72, 0.7, 0.6))
	g.set_color(g.get_point_count() - 1, Color(0.4, 0.4, 0.42, 0.0))
	_trail.color_ramp = g
	add_child(_trail)
	_trail.position = Vector2(-8 if not mini else -5, 0)


func _physics_process(delta: float) -> void:
	if _done:
		return
	_t += delta
	if mini and HOMING > 0.0:
		_home(delta)
	var to := global_position + velocity * delta
	# פגיעה בזומבי
	for z in get_tree().get_nodes_in_group("zombies"):
		if z.dead or z.collision_layer == 0:
			continue
		var zr := Rect2(z.global_position + Vector2(-14.0 * z.wf * z.sc, -62.0 * z.sc), Vector2(28.0 * z.wf * z.sc, 62.0 * z.sc))
		if zr.has_point(to) or zr.has_point(global_position.lerp(to, 0.5)):
			_impact(to)
			return
	# קיר / רצפה / קומה
	var hit := get_world_2d().direct_space_state.intersect_ray(PhysicsRayQueryParameters2D.create(global_position, to, 1 | 16))
	if hit:
		_impact(hit.position - velocity.normalized() * 4.0)
		return
	global_position = to
	_dist += velocity.length() * delta
	if not mini and _dist >= SPLIT_DIST:
		_split()
		return
	if mini and _dist >= MINI_RANGE:
		_impact(global_position)
		return
	queue_redraw()


func _home(delta: float) -> void:
	var best: Vector2 = Vector2.ZERO
	var best_d := HOMING_RANGE
	var dir := velocity.normalized()
	for z in get_tree().get_nodes_in_group("zombies"):
		if z.dead or z.collision_layer == 0:
			continue
		var tp: Vector2 = z.global_position + Vector2(0, -30.0 * z.sc)
		var d := global_position.distance_to(tp)
		if d < best_d and absf(dir.angle_to(tp - global_position)) < HOMING_CONE:
			best_d = d
			best = tp
	if best_d < HOMING_RANGE:
		var turn := clampf(dir.angle_to(best - global_position), -HOMING * delta, HOMING * delta)
		velocity = velocity.rotated(turn)
		rotation = velocity.angle()


func _split() -> void:
	Sfx.play("rocket_split", global_position, -2.0, 0.1, 3)
	Particles.burst(get_parent(), global_position, "fire", velocity.normalized(), 8)
	for i in 3:
		var r = get_script().new()
		r.mini = true
		r.damage_mult = damage_mult
		get_parent().add_child(r)
		r.setup(global_position, velocity.normalized().rotated(SPREAD * float(i - 1)) * MINI_SPEED)
	_finish()


func _impact(at: Vector2) -> void:
	if mini:
		mini_boom(get_parent(), at, damage_mult)
	else:   # פגע לפני הפיצול: 3 פיצוצים קטנים מסביב לנקודה
		var back := -velocity.normalized()
		for i in 3:
			var off := back.rotated(float(i - 1) * 1.1) * (14.0 if i != 1 else 4.0)
			mini_boom.call_deferred(get_parent(), at + off, damage_mult, float(i) * 0.07)
	_finish()


func _finish() -> void:
	_done = true
	velocity = Vector2.ZERO
	# שובל העשן נשאר לרגע ונעלם
	_trail.emitting = false
	visible = true
	queue_redraw()
	await get_tree().create_timer(0.8).timeout
	queue_free()


func _draw() -> void:
	if _done:
		return
	var s := 1.3 if not mini else 0.85
	# להבה מאחור
	var fl := (8.0 + sin(_t * 70.0) * 3.0) * s
	draw_colored_polygon(PackedVector2Array([Vector2(-7, -2.5) * s, Vector2(-7, 2.5) * s, Vector2(-7.0 * s - fl, 0)]), Color(1.0, 0.6, 0.2, 0.9))
	draw_colored_polygon(PackedVector2Array([Vector2(-7, -1.2) * s, Vector2(-7, 1.2) * s, Vector2(-7.0 * s - fl * 0.55, 0)]), Color(1.0, 0.95, 0.6))
	Art.glow(self, Vector2(-8, 0) * s, 9.0 * s, Color(1.0, 0.6, 0.2, 0.5))
	# גוף הטיל
	draw_rect(Rect2(Vector2(-7, -2.5) * s, Vector2(13, 5) * s), Color("4a5a3a"))
	draw_colored_polygon(PackedVector2Array([Vector2(6, -2.5) * s, Vector2(11, 0) * s, Vector2(6, 2.5) * s]), Color("c03a2a"))   # ראש נפץ
	draw_colored_polygon(PackedVector2Array([Vector2(-7, -2.5) * s, Vector2(-4, -2.5) * s, Vector2(-8, -5.5) * s]), Color("3a3a3a"))   # כנפיים
	draw_colored_polygon(PackedVector2Array([Vector2(-7, 2.5) * s, Vector2(-4, 2.5) * s, Vector2(-8, 5.5) * s]), Color("3a3a3a"))
	draw_rect(Rect2(Vector2(-7, -2.5) * s, Vector2(13, 5) * s), Art.OUTLINE, false, 1.0)


# ============================================================
#  פיצוץ קטן: נזק באזור קטן + אפקט שכולו חלקיקים
# ============================================================
static func mini_boom(parent: Node2D, center: Vector2, dmg_mult := 1.0, delay := 0.0) -> void:
	if parent == null or not is_instance_valid(parent):
		return
	if delay > 0.0:
		await parent.get_tree().create_timer(delay).timeout
		if not is_instance_valid(parent):
			return
	var tree := parent.get_tree()
	_blast_id += 1
	var src := {"source": "rocket", "blast": _blast_id}
	Game.make_noise(center, 500.0)
	Sfx.play("explosion", center, -3.0, 0.12, 6, 1.35)   # אותו צליל, גבוה וקצר יותר = פיצוץ קטן
	for b in tree.get_nodes_in_group("blastable"):
		if b.has_method("hit_by_blast") and b.has_method("blast_rect"):
			var r: Rect2 = b.blast_rect()
			var cp := Vector2(clampf(center.x, r.position.x, r.end.x), clampf(center.y, r.position.y, r.end.y))
			if center.distance_to(cp) <= MINI_RADIUS:
				b.hit_by_blast(center, BREAK_RADIUS)
	for z in tree.get_nodes_in_group("zombies"):
		var zc: Vector2 = z.global_position + Vector2(0, -30)
		var d := center.distance_to(zc)
		if d <= MINI_RADIUS + 14.0 * float(z.wf) * float(z.sc):
			var k := 1.0 - clampf(d / (MINI_RADIUS + 20.0), 0.0, 0.6)   # במרכז = יותר נזק
			z.take_damage(int(float(MINI_DAMAGE) * dmg_mult * k), zc, (zc - center).normalized(), true, src)
	for sv in tree.get_nodes_in_group("survivors"):
		var sc: Vector2 = sv.global_position + Vector2(0, -24)
		if center.distance_to(sc) <= MINI_RADIUS * 0.8:
			sv.take_damage(10, sc, (sc - center).normalized(), true)
	var p := tree.get_first_node_in_group("player")
	if p != null and not p.dead:
		var pc: Vector2 = p.global_position + Vector2(0, -26)
		if center.distance_to(pc) <= MINI_RADIUS * 0.55:   # קרוב מדי לפיצוץ שלך
			p.hurt(1, Vector2(signf(pc.x - center.x), 0.0))
	var cam := parent.get_viewport().get_camera_2d()
	if cam != null and cam.has_method("shake"):
		cam.shake(6.0, 0.22)
	var fx := MiniBoomFx.new()
	fx.soft = soft_tex()
	parent.add_child(fx)
	fx.global_position = center


# האפקט: כמה CPUParticles2D חד-פעמיים + הבזק קצר
class MiniBoomFx extends Node2D:
	var _t := 0.0
	var soft: Texture2D

	func _ready() -> void:
		z_index = 9
		var on_ground := not get_world_2d().direct_space_state.intersect_ray(PhysicsRayQueryParameters2D.create(global_position, global_position + Vector2(0, 22), 1)).is_empty()
		var up := Vector2(0, -1)
		# כדור אש
		_emit(40, 0.5, Vector2(60.0, 200.0), 180.0 if not on_ground else 80.0, up, Vector2(0, -60), Vector2(0.45, 0.95),
			[[0.0, Color(1.0, 0.98, 0.8, 1.0)], [0.2, Color(1.0, 0.75, 0.25, 1.0)], [0.55, Color(0.9, 0.3, 0.08, 0.9)], [1.0, Color(0.25, 0.1, 0.06, 0.0)]], Vector2(1.0, 0.35), 8.0, true)
		# ניצוצות
		_emit(28, 0.45, Vector2(240.0, 460.0), 180.0 if not on_ground else 75.0, up, Vector2(0, 700), Vector2(1.0, 2.0),
			[[0.0, Color(1.0, 0.95, 0.6, 1.0)], [1.0, Color(1.0, 0.5, 0.1, 0.0)]], Vector2(1.0, 0.5), 2.0)
		# עשן
		_emit(16, 1.3, Vector2(20.0, 70.0), 120.0 if not on_ground else 60.0, up, Vector2(0, -50), Vector2(0.7, 1.2),
			[[0.0, Color(0.35, 0.33, 0.32, 0.0)], [0.15, Color(0.3, 0.29, 0.28, 0.65)], [1.0, Color(0.5, 0.5, 0.5, 0.0)]], Vector2(0.6, 1.8), 10.0, true)
		# שברים כהים
		_emit(10, 0.8, Vector2(150.0, 300.0), 70.0, up, Vector2(0, 900), Vector2(1.5, 2.6),
			[[0.0, Color(0.15, 0.12, 0.1, 1.0)], [1.0, Color(0.15, 0.12, 0.1, 0.0)]], Vector2(1.0, 1.0), 3.0)
		if on_ground:   # כתם שחור על הרצפה
			var scorch := Scorch.new()
			get_parent().add_child.call_deferred(scorch)
			scorch.position = global_position + Vector2(0, 4)

	func _emit(n: int, life: float, vel: Vector2, spread: float, dir: Vector2, grav: Vector2, scale: Vector2, ramp: Array, scale_curve: Vector2, radius: float, soft_tx := false) -> void:
		var p := CPUParticles2D.new()
		if soft_tx:
			p.texture = soft
		p.one_shot = true
		p.explosiveness = 0.95
		p.amount = n
		p.lifetime = life
		p.direction = dir
		p.spread = spread
		p.gravity = grav
		p.initial_velocity_min = vel.x
		p.initial_velocity_max = vel.y
		p.damping_min = vel.x * 0.8
		p.damping_max = vel.y * 0.9
		p.scale_amount_min = scale.x
		p.scale_amount_max = scale.y
		p.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
		p.emission_sphere_radius = radius
		var c := Curve.new()
		c.add_point(Vector2(0, scale_curve.x))
		c.add_point(Vector2(1, scale_curve.y))
		p.scale_amount_curve = c
		var g := Gradient.new()
		g.offsets = PackedFloat32Array()
		g.colors = PackedColorArray()
		for st in ramp:
			g.add_point(float(st[0]), st[1])
		p.color_ramp = g
		p.emitting = true
		add_child(p)

	func _process(delta: float) -> void:
		_t += delta
		if _t > 1.6:
			queue_free()
			return
		if _t < 0.15:
			queue_redraw()
		elif _t < 0.2:
			queue_redraw()

	func _draw() -> void:
		if _t < 0.12:   # הבזק
			var k := 1.0 - _t / 0.12
			draw_circle(Vector2.ZERO, 36.0 * (0.6 + 0.4 * k), Color(1.0, 0.95, 0.75, 0.55 * k))
			draw_circle(Vector2.ZERO, 16.0, Color(1.0, 1.0, 0.95, 0.9 * k))


# כתם חריכה קטן שנעלם לאט
class Scorch extends Node2D:
	var _life := 6.0

	func _ready() -> void:
		z_index = 1

	func _process(delta: float) -> void:
		_life -= delta
		if _life <= 0.0:
			queue_free()
		elif _life < 1.0:
			queue_redraw()

	func _draw() -> void:
		var a := clampf(_life, 0.0, 1.0)
		draw_colored_polygon(Art.ellipse(Vector2.ZERO, 26.0, 4.0, 0.0, 14), Color(0.08, 0.06, 0.05, 0.55 * a))

	const Art := preload("res://art.gd")


const Particles := preload("res://particles.gd")
