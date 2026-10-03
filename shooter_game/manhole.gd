extends Node2D
# ============================================================
#  מכסה ביוב (תפאורה בלבד). יוצאים ממנו אדים.
#  קליע שפוגע בו מקפיץ את המכסה באוויר והוא נופל חזרה למקום.
#  (0,0) = מרכז המכסה על פני הכביש.
# ============================================================

var lid_r := 17.0             # חצי רוחב המכסה
var gravity := 1200.0

var _lid := Vector2.ZERO      # מיקום המכסה יחסית לחור
var _vel := Vector2.ZERO
var _rot := 0.0
var _spin := 0.0
var _flying := false
var _puffs := []              # [מיקום, מהירות, גיל, חיים, גודל]
var _emit := 0.0
var _time := 0.0


func _ready() -> void:
	add_to_group("manholes")
	z_index = 2
	_time = randf() * 10.0


# נקרא מ-bullet.gd: האם הקליע עבר דרך המכסה
func hit_test(from: Vector2, to: Vector2) -> bool:
	var c := global_position + _lid + Vector2(0.0, -1.0)
	var p := Geometry2D.get_closest_point_to_segment(c, from, to)
	return absf(p.x - c.x) < lid_r + 2.0 and absf(p.y - c.y) < 7.0


func pop(dir: Vector2) -> void:
	_flying = true
	_vel = Vector2(dir.x * randf_range(20.0, 70.0), -randf_range(300.0, 420.0))
	_spin = randf_range(9.0, 15.0) * (1.0 if randf() < 0.5 else -1.0)
	for i in 10:   # פרץ אדים מהחור
		_add_puff(Vector2(randf_range(-lid_r, lid_r), -2.0), Vector2(randf_range(-40.0, 40.0), -randf_range(90.0, 170.0)), 1.4)


func _add_puff(pos: Vector2, vel: Vector2, life: float) -> void:
	_puffs.append([pos, vel, 0.0, life, randf_range(3.0, 5.0)])


func _process(delta: float) -> void:
	# לא על המסך? לא עושים כלום
	var vp := get_viewport()
	var view := (vp.get_canvas_transform().affine_inverse() * vp.get_visible_rect()).grow(120.0)
	if not view.has_point(global_position):
		return
	_time += delta
	if _flying:
		_vel.y += gravity * delta
		_lid += _vel * delta
		_rot += _spin * delta
		if _lid.y >= 0.0 and _vel.y > 0.0:   # נחת חזרה על החור
			_lid.y = 0.0
			if _vel.y > 120.0:
				_vel = Vector2(-_lid.x * 4.0, -_vel.y * 0.35)
				_spin *= -0.4
			else:
				_flying = false
				_lid = Vector2.ZERO
				_vel = Vector2.ZERO
		_lid.x = move_toward(_lid.x, 0.0, 60.0 * delta)   # מתיישר חזרה אל החור
		if not _flying:
			_rot = 0.0
	# אדים: כל הזמן קצת, הרבה כשהמכסה באוויר
	_emit -= delta
	if _emit <= 0.0:
		_emit = 0.06 if _flying else randf_range(0.18, 0.32)
		var px := randf_range(-lid_r, lid_r) if _flying else (lid_r + 1.0) * (1.0 if randf() < 0.5 else -1.0) * randf_range(0.5, 1.0)
		_add_puff(Vector2(px, -1.0), Vector2(randf_range(-10.0, 10.0), -randf_range(30.0, 60.0) * (2.0 if _flying else 1.0)), randf_range(1.6, 2.4))
	for p in _puffs:
		p[2] += delta
		p[1].x += sin(_time * 1.3 + p[4]) * 12.0 * delta   # רוח קלה
		p[0] += p[1] * delta
		p[1] *= 1.0 - 0.6 * delta
	_puffs = _puffs.filter(func(p): return p[2] < p[3])
	queue_redraw()


func _draw() -> void:
	# החור (רואים אותו כשהמכסה למעלה) + אור ירקרק מבפנים
	draw_set_transform(Vector2(0.0, 1.0), 0.0, Vector2(1.0, 0.22))
	draw_circle(Vector2.ZERO, lid_r + 2.0, Color("141416"))
	draw_circle(Vector2.ZERO, lid_r - 2.0, Color(0.15, 0.3, 0.12, 0.6))
	draw_set_transform_matrix(Transform2D.IDENTITY)
	# המכסה (פרספקטיבה: אליפסה שטוחה). מסתובב כשהוא עף
	var sq := absf(cos(_rot)) * 0.22 + 0.06
	draw_set_transform(_lid + Vector2(0.0, -1.0), 0.0, Vector2(1.0, sq))
	draw_circle(Vector2(0.0, 4.0 / sq * 0.25), lid_r, Color("1c1c20"))   # עובי
	draw_circle(Vector2.ZERO, lid_r, Color("4a4a52"))
	draw_arc(Vector2.ZERO, lid_r - 3.0, 0.0, TAU, 20, Color("2e2e34"), 2.0)
	for i in 3:   # חריצים
		var yy := -6.0 + 6.0 * float(i)
		draw_line(Vector2(-lid_r + 6.0, yy), Vector2(lid_r - 6.0, yy), Color("2e2e34"), 2.0)
	draw_arc(Vector2.ZERO, lid_r, PI, TAU, 16, Color(1, 1, 1, 0.18), 1.5)   # ברק
	draw_set_transform_matrix(Transform2D.IDENTITY)
	# אדים
	for p in _puffs:
		var k: float = p[2] / p[3]
		var a := 0.28 * minf(k * 6.0, 1.0) * (1.0 - k)
		draw_circle(p[0], p[4] + k * 14.0, Color(0.85, 0.88, 0.85, a))
