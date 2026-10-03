extends StaticBody2D
# ============================================================
#  חפצים בעולם ההרוס. נקודת ה-(0,0) = הפינה השמאלית התחתונה (על הריצפה).
#    CAR      - מכונית הרוסה. אפשר לעמוד עליה. אחרי 6 קליעים היא נדלקת ומתפוצצת.
#    BUS      - אוטובוס שרוף וארוך. אפשר לקפוץ עליו.
#    BARRIER  - מחסום בטון.
#    BARREL   - חבית דלק אדומה. קליע אחד = פיצוץ! (גם פיצוץ ליד מפוצץ אותה)
#    TIRES    - ערימת צמיגים.
#    SANDBAGS - קיר שקי חול.
# ============================================================

const Art := preload("res://art.gd")
const Boom := preload("res://explosion.gd")
const FireScript := preload("res://fire.gd")
const DebrisScript := preload("res://debris.gd")
const PickupScript := preload("res://pickup.gd")

enum { CAR, BUS, BARRIER, BARREL, TIRES, SANDBAGS, TRAIN }

@export_enum("Car", "Bus", "Barrier", "Barrel", "Tires", "Sandbags") var kind := 0
## מכונית הפוכה (על הגג)
@export var upside_down := false
## מכונית שכבר נשרפה (לא מתפוצצת, יש עליה אש)
@export var wrecked := false
@export var color := Color("7a3a32")
## כמה קליעים עד שמכונית נדלקת
@export var car_hits := 6
## גובה מקסימלי (main.gd קובע כך שתמיד אפשר לקפוץ מעל)
var max_height := 80.0
var count := 2   # כמה צמיגים בערימה

var size := Vector2.ZERO
var _hits := 0
var _burning := false
var _fuse := -1.0
var _seed := 0
var _trunk_open := false


func _ready() -> void:
	collision_layer = 1
	collision_mask = 0
	_seed = int(absf(global_position.x)) * 7 + kind
	match kind:
		CAR:
			size = Vector2(128, 50)
			if upside_down:
				_box(Rect2(0, -44, 128, 25))
				_box(Rect2(36, -19, 66, 19))
				size.y = 44
			else:
				_box(Rect2(0, -31, 128, 25))
				_box(Rect2(36, -50, 66, 19))
				_box(Rect2(2, -8, 124, 8))
			if wrecked:
				_add_fire(Vector2(70, -size.y + 2), 26.0, 30.0)
			else:
				add_to_group("blastable")
		BUS:
			size = Vector2(250, minf(70.0, max_height))
			_box(Rect2(0, -size.y, size.x, size.y))
			if randf() < 0.5:
				_add_fire(Vector2(size.x * 0.65, -size.y + 2), 30.0, 34.0)
		BARRIER:
			size = Vector2(64, 32)
			_box(Rect2(8, -32, 48, 24))
			_box(Rect2(0, -8, 64, 8))
		BARREL:
			size = Vector2(22, 30)
			_box(Rect2(0, -30, 22, 30))
			add_to_group("blastable")
		TIRES:
			size = Vector2(34, 12.0 * float(count))
			_box(Rect2(0, -size.y, 34, size.y))
		SANDBAGS:
			size = Vector2(72, 26)
			_box(Rect2(0, -26, 72, 26))
		TRAIN:   # קרון רכבת תחתית תקוע (אפשר לעלות עליו)
			size = Vector2(300, minf(76.0, max_height))
			_box(Rect2(0, -size.y, size.x, size.y))
	z_index = 1
	set_process(false)
	if kind in [CAR, BUS, BARRIER, SANDBAGS, TIRES, TRAIN]:
		add_to_group("cover")   # זומבים יכולים להתחבא מאחוריו   # מופעל רק כשיש פתיל דולק (חוסך ביצועים)


func _box(r: Rect2) -> void:
	var cs := CollisionShape2D.new()
	var rs := RectangleShape2D.new()
	rs.size = r.size
	cs.shape = rs
	cs.position = r.position + r.size / 2.0
	add_child(cs)


func _add_fire(pos: Vector2, w: float, h: float, life := -1.0) -> void:
	var f = FireScript.new()
	f.width = w
	f.height = h
	f.life = life
	f.position = pos
	add_child(f)


func blast_rect() -> Rect2:
	return Rect2(global_position + Vector2(0.0, -size.y), size)


func cover_rect() -> Rect2:
	return blast_rect()


# ============================================================
#  פגיעות ופיצוצים
# ============================================================
# נקרא מ-bullet.gd
func hit_by_bullet(world_pos: Vector2, normal: Vector2, dir: Vector2) -> void:
	match kind:
		BARREL:
			_arm(0.05)
		CAR:
			if not _trunk_open:
				_open_trunk()
			if wrecked:
				return
			_hits += 1
			_chips(world_pos, normal, 3)
			if _hits >= car_hits and not _burning:
				_ignite()


# נקרא מ-explosion.gd כשיש פיצוץ קרוב
func hit_by_blast(_center: Vector2, _break_radius: float) -> void:
	match kind:
		BARREL:
			_arm(0.15)   # תגובת שרשרת: חבית ליד חבית
		CAR:
			if wrecked:
				return
			if _burning:
				_arm(0.2)
			else:
				_ignite(0.8)


# תא המטען נפתח בפעם הראשונה שיורים במכונית: יוצא שלל
func _open_trunk() -> void:
	_trunk_open = true
	var r := randf()
	var p = PickupScript.new()
	if r < 0.6:
		p.kind = PickupScript.AMMO
	elif r < 0.85:
		p.kind = PickupScript.GRENADE
	else:
		p.kind = PickupScript.BOOST
		p.boost = randi() % 5
	get_parent().add_child(p)
	var back := global_position + (Vector2(6, -size.y + 4) if not upside_down else Vector2(6, -size.y + 4))
	p.setup(back, Vector2(randf_range(-90, -30), -260))
	queue_redraw()


func _ignite(fuse := 2.5) -> void:
	_burning = true
	_add_fire(Vector2(size.x * 0.7, -size.y * 0.55), 22.0, 26.0)
	_arm(fuse)


func _arm(t: float) -> void:
	if _fuse < 0.0 or t < _fuse:
		_fuse = t
	set_process(true)


func _process(delta: float) -> void:
	if _fuse < 0.0:
		return
	_fuse -= delta
	if _fuse <= 0.0:
		_fuse = -1.0
		set_process(false)
		_explode()


func _explode() -> void:
	var c := global_position + Vector2(size.x / 2.0, -size.y / 2.0)
	remove_from_group("blastable")
	if kind == BARREL:
		_chips(c, Vector2.UP, 10, Color("8a2018"))
		Boom.blast(get_parent(), c, 110.0, 60.0, 40, 2, "barrel")
		queue_free()
		return
	# מכונית: מתפוצצת ונשארת שרופה עם אש
	_chips(c, Vector2.UP, 14)
	Boom.blast(get_parent(), c, 140.0, 70.0, 40, 2, "car")
	wrecked = true
	_burning = false
	for ch in get_children():
		if ch is Node2D and not ch is CollisionShape2D:
			ch.queue_free()
	_add_fire(Vector2(70, -size.y + 2), 30.0, 34.0)
	queue_redraw()


func _chips(pos: Vector2, normal: Vector2, n: int, col := Color.BLACK) -> void:
	for i in n:
		var d = DebrisScript.new()
		get_parent().add_child(d)
		var v := Vector2.from_angle(normal.angle() + randf_range(-1.2, 1.2)) * randf_range(120.0, 320.0)
		var c := col if col != Color.BLACK else (color.darkened(randf_range(0.0, 0.4)) if randf() < 0.6 else Color("4a4a50"))
		d.setup(pos, Vector2(randf_range(3.0, 6.0), randf_range(2.0, 4.0)), c, v)


# ============================================================
#  ציור
# ============================================================
func _draw() -> void:
	match kind:
		CAR:
			if upside_down:
				draw_set_transform(Vector2(0, -50), 0.0, Vector2(1, -1))
				_draw_car()
				draw_set_transform_matrix(Transform2D.IDENTITY)
			else:
				_draw_car()
		BUS:
			_draw_bus()
		BARRIER:
			_draw_barrier()
		BARREL:
			_draw_barrel()
		TIRES:
			_draw_tires()
		SANDBAGS:
			_draw_sandbags()
		TRAIN:
			_draw_train()


func _draw_train() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = _seed
	var w := size.x
	var h := size.y
	var body := PackedVector2Array([Vector2(0, -4), Vector2(0, -h + 8), Vector2(8, -h), Vector2(w - 8, -h), Vector2(w, -h + 8), Vector2(w, -4)])
	Art.fill_shaded(self, body, Color("8a8e94"), 0.15, 0.35, Art.OUTLINE, 1.8)
	draw_rect(Rect2(2, -h * 0.42, w - 4, 7), Color("2a5aa0"))   # פס כחול
	var x := 18.0
	while x < w - 30.0:   # חלונות חשוכים, חלקם עם אור עמום
		var lit := rng.randf() < 0.25
		Art.fill(self, PackedVector2Array([Vector2(x, -h + 10), Vector2(x + 30, -h + 10), Vector2(x + 30, -h + 30), Vector2(x, -h + 30)]), Color(0.7, 0.85, 0.6, 0.5) if lit else Color("101214"), Art.OUTLINE, 1.0)
		x += 42.0
	for dx in [w * 0.33, w * 0.66]:   # דלתות
		draw_rect(Rect2(dx - 12, -h + 8, 24, h - 12), Color("6a6e74"))
		draw_line(Vector2(dx, -h + 8), Vector2(dx, -4), Color(0, 0, 0, 0.6), 1.5)
	for i in 3:   # גרפיטי
		var gx := rng.randf_range(10.0, w - 60.0)
		draw_line(Vector2(gx, -14), Vector2(gx + rng.randf_range(20, 50), -h * 0.3), Color.from_hsv(rng.randf(), 0.7, 0.8, 0.6), 3.0, true)
	draw_rect(Rect2(0, -4, w, 4), Color("1a1a1c"))


func _draw_car() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = _seed
	var body := Color("2a2422") if wrecked else color
	var body_pts := PackedVector2Array([
		Vector2(0, -8), Vector2(0, -24), Vector2(4, -30), Vector2(32, -31), Vector2(44, -50), Vector2(88, -50),
		Vector2(102, -33), Vector2(124, -30), Vector2(128, -24), Vector2(128, -8), Vector2(118, -6), Vector2(10, -6),
	])
	Art.fill_shaded(self, body_pts, body, 0.15, 0.35, Art.OUTLINE, 1.6)
	# פסי חלודה / פחם
	for i in 6:
		var p := Vector2(rng.randf_range(6.0, 122.0), rng.randf_range(-28.0, -10.0))
		Art.oval(self, p, rng.randf_range(4.0, 10.0), rng.randf_range(2.0, 4.0), Color(0.42, 0.2, 0.08, 0.55) if not wrecked else Color(0.05, 0.04, 0.04, 0.6), rng.randf_range(-0.4, 0.4), Art.NONE)
	if wrecked:   # גחלים
		for i in 5:
			draw_circle(Vector2(rng.randf_range(10.0, 120.0), rng.randf_range(-28.0, -10.0)), 1.3, Color(1.0, 0.45, 0.1, 0.8))
	# חלונות שבורים
	var glass := Color("14181e")
	Art.fill(self, PackedVector2Array([Vector2(47, -47), Vector2(64, -47), Vector2(64, -34), Vector2(38, -34)]), glass, Art.OUTLINE, 1.0)
	Art.fill(self, PackedVector2Array([Vector2(68, -47), Vector2(86, -47), Vector2(98, -34), Vector2(68, -34)]), glass, Art.OUTLINE, 1.0)
	for i in 4:   # סדקים בזכוכית
		var c := Vector2(rng.randf_range(44.0, 92.0), rng.randf_range(-45.0, -36.0))
		for j in 3:
			draw_line(c, c + Vector2.from_angle(rng.randf() * TAU) * rng.randf_range(3.0, 7.0), Color(0.8, 0.85, 0.9, 0.35), 0.7, true)
	# דלתות, ידיות, פגושים, פנסים
	draw_line(Vector2(66, -31), Vector2(66, -10), Color(0, 0, 0, 0.5), 1.0, true)
	draw_line(Vector2(36, -31), Vector2(38, -10), Color(0, 0, 0, 0.5), 1.0, true)
	draw_line(Vector2(56, -26), Vector2(61, -26), Color(0.7, 0.7, 0.7, 0.6), 1.5, true)
	draw_line(Vector2(84, -26), Vector2(89, -26), Color(0.7, 0.7, 0.7, 0.6), 1.5, true)
	Art.fill(self, PackedVector2Array([Vector2(122, -14), Vector2(130, -14), Vector2(130, -8), Vector2(120, -8)]), Color("55555a"), Art.OUTLINE, 1.0)
	Art.fill(self, PackedVector2Array([Vector2(-2, -14), Vector2(6, -14), Vector2(8, -8), Vector2(-2, -8)]), Color("55555a"), Art.OUTLINE, 1.0)
	Art.fill(self, PackedVector2Array([Vector2(122, -27), Vector2(127, -26), Vector2(127, -21), Vector2(121, -21)]), Color("6a6a50"), Art.OUTLINE, 0.8)
	Art.fill(self, PackedVector2Array([Vector2(1, -26), Vector2(5, -27), Vector2(5, -21), Vector2(1, -21)]), Color("6a1a14"), Art.OUTLINE, 0.8)
	# בתי גלגלים בלי גלגלים (גלגל אחד שטוח)
	for wx in [24.0, 104.0]:
		var arc := PackedVector2Array()
		for i in 9:
			var a := PI + PI * float(i) / 8.0
			arc.append(Vector2(wx, -6.0) + Vector2(cos(a), sin(a)) * 12.0)
		Art.fill(self, arc, Color("0c0a0a"), Art.NONE)
	Art.oval(self, Vector2(24, -4), 11.0, 4.0, Color("1a1a1c"), 0.0, Art.OUTLINE, 1.0)   # צמיג שטוח
	# הארה על הגג
	draw_line(Vector2(46, -49), Vector2(86, -49), Color(1, 1, 1, 0.12), 1.2, true)
	if _trunk_open:   # מכסה תא המטען פתוח
		Art.fill(self, PackedVector2Array([Vector2(4, -30), Vector2(-6, -46), Vector2(-2, -48), Vector2(10, -31)]), body.darkened(0.15), Art.OUTLINE, 1.2)
		Art.fill(self, PackedVector2Array([Vector2(4, -30), Vector2(30, -31), Vector2(30, -27), Vector2(4, -26)]), Color("0c0a0a"), Art.NONE)


func _draw_bus() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = _seed
	var w := size.x
	var h := size.y
	var body := PackedVector2Array([Vector2(0, -6), Vector2(0, -h + 6), Vector2(6, -h), Vector2(w - 10, -h), Vector2(w, -h + 10), Vector2(w, -6)])
	Art.fill_shaded(self, body, Color("3a322a"), 0.1, 0.35, Art.OUTLINE, 1.8)
	# שאריות צבע צהוב
	for i in 8:
		var p := Vector2(rng.randf_range(10.0, w - 10.0), rng.randf_range(-h * 0.45, -12.0))
		Art.oval(self, p, rng.randf_range(8.0, 22.0), rng.randf_range(4.0, 9.0), Color(0.72, 0.56, 0.16, 0.75), rng.randf_range(-0.3, 0.3), Art.NONE)
	# שורת חלונות - שבורים ושחורים
	var x := 14.0
	while x < w - 40.0:
		var dark := Color("0e0c0c") if rng.randf() < 0.7 else Color(0.9, 0.4, 0.15, 0.7)
		Art.fill(self, PackedVector2Array([Vector2(x, -h + 10), Vector2(x + 22, -h + 10), Vector2(x + 22, -h + 30), Vector2(x, -h + 30)]), dark, Art.OUTLINE, 1.0)
		if rng.randf() < 0.5:
			draw_line(Vector2(x + 3, -h + 12), Vector2(x + 18, -h + 27), Color(0.7, 0.7, 0.75, 0.3), 0.8, true)
		x += 28.0
	# דלת וחזית
	Art.fill(self, PackedVector2Array([Vector2(w - 30, -h + 10), Vector2(w - 6, -h + 12), Vector2(w - 6, -8), Vector2(w - 30, -8)]), Color("141010"), Art.OUTLINE, 1.0)
	# סימני שריפה שחורים
	for i in 5:
		var p := Vector2(rng.randf_range(10.0, w - 10.0), -h + rng.randf_range(6.0, 20.0))
		Art.oval(self, p, rng.randf_range(12.0, 30.0), rng.randf_range(5.0, 10.0), Color(0.04, 0.03, 0.03, 0.6), 0.0, Art.NONE)
	draw_line(Vector2(0, -h * 0.45), Vector2(w, -h * 0.45), Color(0, 0, 0, 0.5), 1.5, true)
	for wx in [36.0, w - 50.0]:
		var arc := PackedVector2Array()
		for i in 9:
			var a := PI + PI * float(i) / 8.0
			arc.append(Vector2(wx, -6.0) + Vector2(cos(a), sin(a)) * 14.0)
		Art.fill(self, arc, Color("0a0808"), Art.NONE)
		Art.oval(self, Vector2(wx, -6), 12.0, 6.0, Color("18181a"), 0.0, Art.OUTLINE, 1.0)


func _draw_barrier() -> void:
	var pts := PackedVector2Array([Vector2(0, 0), Vector2(0, -8), Vector2(8, -12), Vector2(12, -32), Vector2(52, -32), Vector2(56, -12), Vector2(64, -8), Vector2(64, 0)])
	Art.fill_shaded(self, pts, Color("8c8a84"), 0.15, 0.35, Art.OUTLINE, 1.5)
	# פסים אדום-לבן דהויים
	for i in 4:
		var x := 14.0 + float(i) * 10.0
		Art.fill(self, PackedVector2Array([Vector2(x, -30), Vector2(x + 5, -30), Vector2(x + 1, -22), Vector2(x - 4, -22)]), Color(0.7, 0.15, 0.12, 0.7), Art.NONE)
	# סדקים וחתיכות חסרות
	draw_polyline(PackedVector2Array([Vector2(30, -32), Vector2(33, -24), Vector2(29, -17), Vector2(34, -9)]), Color(0, 0, 0, 0.5), 1.0, true)
	Art.fill(self, PackedVector2Array([Vector2(48, -32), Vector2(52, -32), Vector2(53, -27)]), Color("5a5853"), Art.NONE)
	draw_line(Vector2(12, -16), Vector2(52, -14), Color(0.2, 0.6, 0.3, 0.5), 1.5, true)   # גרפיטי


func _draw_barrel() -> void:
	var red := Color("a52a1e")
	var pts := PackedVector2Array([Vector2(1, 0), Vector2(0, -2), Vector2(0, -28), Vector2(1, -30), Vector2(21, -30), Vector2(22, -28), Vector2(22, -2), Vector2(21, 0)])
	Art.fill(self, pts, red, Art.OUTLINE, 1.4)
	# הצללה של גליל: כהה בצדדים, בהיר באמצע
	draw_rect(Rect2(1, -29, 4, 28), Color(0, 0, 0, 0.25))
	draw_rect(Rect2(17, -29, 4, 28), Color(0, 0, 0, 0.3))
	draw_rect(Rect2(7, -29, 3, 28), Color(1, 1, 1, 0.15))
	for y in [-22.0, -9.0]:   # טבעות
		draw_line(Vector2(0, y), Vector2(22, y), Color(0, 0, 0, 0.45), 1.5, true)
	# סמל אש צהוב
	Art.fill(self, PackedVector2Array([Vector2(11, -20), Vector2(15, -15.5), Vector2(11, -11), Vector2(7, -15.5)]), Color("e8c030"), Art.OUTLINE, 0.8)
	Art.fill(self, PackedVector2Array([Vector2(11, -18), Vector2(12.5, -15), Vector2(11, -13), Vector2(9.5, -15)]), Color("a52a1e"), Art.NONE)
	Art.oval(self, Vector2(11, -30), 10.0, 1.8, red.darkened(0.25), 0.0, Art.OUTLINE, 1.0)


func _draw_tires() -> void:
	for i in count:
		var y := -6.0 - float(i) * 12.0
		var x := 17.0 + (2.0 if i % 2 == 1 else -1.0)
		Art.oval(self, Vector2(x, y), 17.0, 6.2, Color("1c1c1f"), 0.0, Art.OUTLINE, 1.4)
		Art.oval(self, Vector2(x, y - 1.0), 8.0, 2.4, Color("0a0a0b"), 0.0, Art.NONE)
		for j in 6:   # חריצי צמיג
			var tx := x - 14.0 + float(j) * 5.6
			draw_line(Vector2(tx, y + 2.0), Vector2(tx + 2.0, y + 5.0), Color(0.3, 0.3, 0.32, 0.6), 1.0, true)


func _draw_sandbags() -> void:
	var col := Color("8a7a55")
	for row in 2:
		var y := -6.5 - float(row) * 13.0
		var off := 0.0 if row == 0 else 9.0
		var n := 4 if row == 0 else 3
		for i in n:
			var c := Vector2(off + 9.0 + float(i) * 18.0, y)
			Art.oval_shaded(self, c, 9.5, 6.5, col.darkened(0.05 * float((i + row) % 3)), 0.0, Art.OUTLINE, 1.2)
			draw_line(c + Vector2(-5, -1), c + Vector2(5, -2), Color(0, 0, 0, 0.2), 0.8, true)
