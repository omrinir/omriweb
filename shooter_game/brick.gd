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


# נקרא מ-grenade.gd כשיש פיצוץ בקרבת הלבנה
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
	for c in _cracks:   # סדקים
		draw_polyline(c, Color(0, 0, 0, 0.6), 1.5)
	for i in _blood_rects.size():   # כתמי דם (מעל הכל)
		draw_rect(_blood_rects[i], _blood_cols[i])
