@tool
extends StaticBody2D
# ============================================================
#  לבנה / קיר / פלטפורמה. הדמות לא יכולה לעבור דרכה.
#  * נשברת אחרי hit_points קליעים (מופיעים סדקים), או מפיצוץ רימון.
#  * מתכסה בדם כשזומבים מתרסקים עליה / טיפות דם פוגעות בה.
#
#  להוספת לבנה ידנית: גוררים את brick.tscn ל-main.tscn ומשנים Size.
#  נקודת ה-(0,0) של הלבנה היא הפינה השמאלית העליונה שלה.
# ============================================================

const DebrisScript := preload("res://debris.gd")

## גודל הלבנה (רוחב, גובה) בפיקסלים
@export var size := Vector2(64, 64):
	set(v):
		size = v
		if is_node_ready():
			_rebuild()
		queue_redraw()
## צבע הלבנים
@export var color := Color("9a4f3a"):
	set(v):
		color = v
		queue_redraw()
## צבע המישק (הרווחים בין הלבנים)
@export var mortar_color := Color("4a2a22"):
	set(v):
		mortar_color = v
		queue_redraw()
## גודל כל "לבנה קטנה" בתוך הציור
@export var brick_cell := Vector2(32, 16)
## true = ציור של לבנים. false = משטח חלק (כמו אדמה)
@export var show_bricks := true
## סגנון: לבנים / ארגז עץ / בטון הרוס / כביש (הריצפה)
@export_enum("Bricks", "Crate", "Concrete", "Road") var style := 0:
	set(v):
		style = v
		queue_redraw()
## true = פס דשא למעלה
@export var grass := false
@export var grass_color := Color("58a840")
## האם אפשר לשבור את הלבנה (הריצפה לא)
@export var breakable := true
## כמה קליעים צריך כדי לשבור אותה
@export var hit_points := 3
## מקסימום כתמי דם על הלבנה (הישנים נמחקים)
@export var max_blood_rects := 700

var hp := 3
var _broken := false
var _shape: CollisionShape2D
var _blood_rects: Array[Rect2] = []
var _blood_cols: Array[Color] = []
var _cracks: Array[PackedVector2Array] = []


func _ready() -> void:
	collision_layer = 1   # שכבה 1 = עולם. השחקן והקליעים מתנגשים בה
	collision_mask = 0
	add_to_group("bricks")
	add_to_group("blastable")
	hp = hit_points
	_rebuild()


func _rebuild() -> void:
	if _shape == null:
		_shape = CollisionShape2D.new()
		_shape.shape = RectangleShape2D.new()
		add_child(_shape)
	(_shape.shape as RectangleShape2D).size = size
	_shape.position = size / 2.0


# ============================================================
#  שבירה
# ============================================================
# נקרא מ-bullet.gd כשקליע פוגע
func hit_by_bullet(world_pos: Vector2, normal: Vector2, dir: Vector2) -> void:
	if not breakable or _broken:
		return
	hp -= 1
	if hp <= 0:
		break_apart(world_pos, dir)
		return
	_add_crack(to_local(world_pos))
	for i in 3:   # שבבים קטנים
		var v := Vector2.from_angle(normal.angle() + randf_range(-1.0, 1.0)) * randf_range(80.0, 220.0)
		_spawn_chunk(world_pos, Vector2(randf_range(3.0, 5.0), randf_range(3.0, 5.0)), v)
	queue_redraw()


# המלבן של הלבנה בעולם (משמש את הפיצוץ)
func blast_rect() -> Rect2:
	return Rect2(global_position, size)


# נקרא מ-explosion.gd כשיש פיצוץ בקרבת הלבנה
func hit_by_blast(center: Vector2, break_radius: float) -> void:
	if not breakable or _broken:
		return
	var tl := global_position
	var cp := Vector2(clampf(center.x, tl.x, tl.x + size.x), clampf(center.y, tl.y, tl.y + size.y))
	var d := center.distance_to(cp)
	var away := (cp - center).normalized()
	if d <= break_radius:
		break_apart(center, away)
	else:
		hp -= 1
		if hp <= 0:
			break_apart(center, away)
		else:
			_add_crack(to_local(cp))
			queue_redraw()


func break_apart(from_world: Vector2, dir := Vector2.ZERO) -> void:
	if _broken:
		return
	_broken = true
	collision_layer = 0
	if _shape != null:
		_shape.set_deferred("disabled", true)
	var cx := clampi(int(round(size.x / 16.0)), 1, 6)
	var cy := clampi(int(round(size.y / 16.0)), 1, 6)
	var cell := Vector2(size.x / float(cx), size.y / float(cy))
	for ix in cx:
		for iy in cy:
			var wpos := to_global(Vector2((float(ix) + 0.5) * cell.x, (float(iy) + 0.5) * cell.y))
			var away := wpos - from_world
			away = away.normalized() if away.length() > 1.0 else Vector2.UP
			var v := away * randf_range(60.0, 240.0) + dir * 90.0 + Vector2(0.0, -randf_range(40.0, 220.0))
			_spawn_chunk(wpos, cell - Vector2(1.0, 1.0), v)
	queue_free()


func _spawn_chunk(pos: Vector2, sz: Vector2, vel: Vector2) -> void:
	var d = DebrisScript.new()
	get_parent().add_child(d)
	var shade := randf_range(0.8, 1.1)
	d.setup(pos, sz, Color(color.r * shade, color.g * shade, color.b * shade), vel)


func _add_crack(lp: Vector2) -> void:
	var pts := PackedVector2Array()
	var p := lp.clamp(Vector2.ZERO, size)
	pts.append(p)
	var ang := randf() * TAU
	for i in randi_range(3, 5):
		ang += randf_range(-0.9, 0.9)
		p = (p + Vector2.from_angle(ang) * randf_range(5.0, 11.0)).clamp(Vector2.ZERO, size)
		pts.append(p)
	_cracks.append(pts)


# ============================================================
#  דם
# ============================================================
# מוסיף כתם דם. world_pos = נקודת הפגיעה, normal = לאן פונה המשטח,
# strength = גודל הכתם (טיפה ~0.7, התרסקות ~3)
func add_blood(world_pos: Vector2, normal: Vector2, strength := 1.0) -> void:
	var lp := to_local(world_pos)
	var area := Rect2(Vector2.ZERO, size)
	var flat := absf(normal.y) > absf(normal.x)   # ריצפה/גג = כתם שטוח, קיר = כתם עם נזילות
	var tangent := Vector2(-normal.y, normal.x)
	var n := int(3.0 + 4.0 * strength)
	var s := 0.6 + 0.5 * strength
	for i in n:
		var c := lp + tangent * randf_range(-1.0, 1.0) * (4.0 + 8.0 * strength) - normal * randf_range(0.0, 3.0)
		var sz := Vector2(randf_range(2.0, 5.0), randf_range(2.0, 5.0)) * s
		if flat:
			sz = Vector2(sz.x * 1.6, maxf(sz.y * 0.5, 1.5))
		_add_blood_rect(Rect2(c - sz / 2.0, sz).intersection(area))
	if not flat:   # נזילה מטה על הקיר
		for i in 1 + int(strength):
			var x := lp.x + randf_range(-6.0, 6.0) * s
			var drip_len := randf_range(6.0, 22.0) * s
			_add_blood_rect(Rect2(x, lp.y, 2.0, drip_len).intersection(area))
	while _blood_rects.size() > max_blood_rects:
		_blood_rects.pop_front()
		_blood_cols.pop_front()
	queue_redraw()


func _add_blood_rect(r: Rect2) -> void:
	if r.has_area():
		_blood_rects.append(r)
		_blood_cols.append(Color("a31616").darkened(randf_range(0.0, 0.45)))


# ============================================================
#  ציור
# ============================================================
func _draw() -> void:
	match style:
		1:
			_draw_crate()
		2:
			_draw_concrete()
		3:
			_draw_road()
		_:
			_draw_bricks()
	for c in _cracks:   # סדקים
		draw_polyline(c, Color(0, 0, 0, 0.6), 1.5)
	for i in _blood_rects.size():   # כתמי דם (מעל הכל)
		draw_rect(_blood_rects[i], _blood_cols[i])


func _draw_bricks() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), mortar_color)
	if show_bricks:
		var rows := int(ceil(size.y / brick_cell.y))
		for r in rows:
			var y := r * brick_cell.y
			var h := minf(brick_cell.y, size.y - y)
			var x := -(brick_cell.x * 0.5 if r % 2 == 1 else 0.0)
			while x < size.x:
				var x0 := maxf(x, 0.0)
				var x1 := minf(x + brick_cell.x, size.x)
				if x1 - x0 > 2.0:
					var shade := 0.9 + 0.2 * fposmod(sin(float(r) * 12.9898 + x * 0.37) * 43758.5453, 1.0)
					draw_rect(Rect2(x0 + 1.0, y + 1.0, x1 - x0 - 2.0, h - 2.0),
						Color(color.r * shade, color.g * shade, color.b * shade))
				x += brick_cell.x
		draw_rect(Rect2(0, 0, size.x, 2), Color(1, 1, 1, 0.18))   # הארה עליונה
	else:
		draw_rect(Rect2(Vector2.ZERO, size), color)
		for i in int(size.x / 18.0):
			var sx := float(i) * 18.0 + 6.0
			var sy := 14.0 + fposmod(float(i) * 37.0, maxf(size.y - 20.0, 1.0))
			draw_rect(Rect2(sx, sy, 6, 3), Color(0, 0, 0, 0.12))
	if grass:
		draw_rect(Rect2(0, 0, size.x, 8), grass_color)
		draw_rect(Rect2(0, 6, size.x, 3), grass_color.darkened(0.25))


# ---- ארגז עץ ----
func _draw_crate() -> void:
	var dark := color.darkened(0.35)
	draw_rect(Rect2(Vector2.ZERO, size), dark)
	var y := 2.0
	var i := 0
	while y < size.y - 2.0:   # קרשים
		var h := minf(7.0, size.y - 2.0 - y)
		draw_rect(Rect2(2, y, size.x - 4, h - 1.0), color.darkened(0.08 * float(i % 3)))
		y += 7.0
		i += 1
	draw_line(Vector2(3, 3), Vector2(size.x - 3, size.y - 3), dark, 3.0, true)   # חיזוק באלכסון
	draw_rect(Rect2(Vector2.ZERO, size), dark, false, 3.0)                     # מסגרת
	draw_rect(Rect2(Vector2.ZERO, size), Color(0, 0, 0, 0.8), false, 1.0)
	for p in [Vector2(4, 4), Vector2(size.x - 4, 4), Vector2(4, size.y - 4), Vector2(size.x - 4, size.y - 4)]:
		draw_circle(p, 1.0, Color("2a2a2a"))
	draw_rect(Rect2(0, 0, size.x, 2), Color(1, 1, 1, 0.15))


# ---- בטון הרוס עם ברזלים ----
func _draw_concrete() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = int(absf(global_position.x * 3.0 + global_position.y))
	draw_rect(Rect2(Vector2.ZERO, size), color.darkened(0.3))
	var rows := int(ceil(size.y / 16.0))
	for r in rows:
		var y := float(r) * 16.0
		var h := minf(16.0, size.y - y)
		var x := -(24.0 if r % 2 == 1 else 0.0)
		while x < size.x:
			var x0 := maxf(x, 0.0)
			var x1 := minf(x + 48.0, size.x)
			if x1 - x0 > 2.0:
				draw_rect(Rect2(x0 + 1.0, y + 1.0, x1 - x0 - 2.0, h - 2.0), color.darkened(rng.randf_range(-0.05, 0.12)))
			x += 48.0
	# סדקים קבועים
	for i in int(size.x / 24.0) + 1:
		var p := Vector2(rng.randf_range(2.0, size.x - 2.0), rng.randf_range(2.0, size.y - 2.0))
		draw_polyline(PackedVector2Array([p, p + Vector2(rng.randf_range(-6, 6), rng.randf_range(4, 9)), p + Vector2(rng.randf_range(-8, 8), rng.randf_range(9, 15))]), Color(0, 0, 0, 0.35), 1.0, true)
	# ברזלים חלודים שבולטים מלמעלה
	for i in rng.randi_range(1, 3):
		var rx := rng.randf_range(4.0, size.x - 4.0)
		draw_polyline(PackedVector2Array([Vector2(rx, 4), Vector2(rx + rng.randf_range(-2, 2), -6), Vector2(rx + rng.randf_range(-6, 6), -rng.randf_range(10, 16))]), Color("6a3a20"), 1.6, true)
	# פינה שבורה למעלה
	var cx := rng.randf_range(0.0, size.x - 14.0)
	draw_colored_polygon(PackedVector2Array([Vector2(cx, 0), Vector2(cx + 14, 0), Vector2(cx + 7, 6)]), color.darkened(0.45))
	draw_rect(Rect2(0, 0, size.x, 2), Color(1, 1, 1, 0.12))


# ---- כביש: אספלט למעלה, אדמה והריסות למטה ----
func _draw_road() -> void:
	var asphalt := Color("38383d")
	draw_rect(Rect2(Vector2.ZERO, size), Color("3a3029"))
	draw_polygon(PackedVector2Array([Vector2(0, 0), Vector2(size.x, 0), Vector2(size.x, minf(14.0, size.y)), Vector2(0, minf(14.0, size.y))]),
		PackedColorArray([asphalt.lightened(0.08), asphalt.lightened(0.08), asphalt.darkened(0.15), asphalt.darkened(0.15)]))
	draw_line(Vector2(0, 14), Vector2(size.x, 14), Color(0, 0, 0, 0.5), 2.0)
	# אבנים וחצץ בשכבת האדמה
	var rng := RandomNumberGenerator.new()
	rng.seed = int(absf(global_position.x)) + 7
	for i in int(size.x / 22.0):
		var p := Vector2(rng.randf_range(0.0, size.x), rng.randf_range(20.0, maxf(size.y - 4.0, 21.0)))
		draw_rect(Rect2(p, Vector2(rng.randf_range(3.0, 8.0), rng.randf_range(2.0, 4.0))), Color(0, 0, 0, rng.randf_range(0.1, 0.25)))
