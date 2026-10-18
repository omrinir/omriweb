extends RefCounted
const DrawBatch := preload("res://effects/draw_batch.gd")
# ============================================================
#  קישוטים לשלב 21 ("CLIFFSIDE") - כפר צוקים בהרים בשקיעה: ערפל בין הפסגות, גשרי חבלים,
#  מקדש פגודה על צוק, מפל, אורנים, דגלי תפילה על הקומה השנייה.
#    dusk_sky     - (רקע) שמיים סגולים-כתומים, שמש גדולה נמוכה, פסי עננים
#    far_peaks    - (רקע) פסגות מושלגות רחוקות באובך
#    mid_cliffs   - (רקע) צוקים עם פגודה, מפל וגשר חבלים
#    near_pines   - (רקע) אורנים כהים וסלעים קרובים
#    CliffGround  - (עולם) קרקע סלעית עם עשב (מדלגת על הבורות)
#    SpikePit     - (עולם, סכנה) בור עם יתדות בתחתית: פוגע ומקפיץ את השחקן החוצה, הורג זומבים (רובם קופצים מעליו - SMART_HOP)
#    Flags        - (עולם) עמודים ודגלי תפילה לאורך הקומה השנייה
#    Obstacle     - (מוצק + מחסה) "rock" סלע / "lantern" פנס אבן / "crate" ארגז
#    CliffFX      - (מסך) ערפל שזורם, עלים ברוח
#  רקע = מעט מצולעים (מצויר בכל פריים). כל השאר סטטי.
# ============================================================

const Art := preload("res://art.gd")

const ROCK := Color("5e544c")
const ROCK_D := Color("3e3834")
const ROCK_L := Color("7a6e62")
const GRASS := Color("5e6e3a")
const WOOD := Color("6a4a2e")
const SPIKE := Color("9a9aa2")


static func _rng(s: int) -> RandomNumberGenerator:
	var r := RandomNumberGenerator.new()
	r.seed = s
	return r


# ---- שמיים בשקיעה ----
static func dusk_sky(ci: CanvasItem, v: Vector2, t: float) -> void:
	var bands := [Color("2a2240"), Color("4a2e4e"), Color("7a3e52"), Color("b85a50"), Color("e8905a")]
	var h := v.y * 0.72 / float(bands.size())
	for i in bands.size():
		DrawBatch.rect(ci, Rect2(0, float(i) * h, v.x, h + 1.0), bands[i])
	DrawBatch.rect(ci, Rect2(0, h * bands.size(), v.x, v.y), Color("e8905a"))
	var sun := Vector2(v.x * 0.68, v.y * 0.5)
	DrawBatch.circle(ci, sun, 120.0, Color(1.0, 0.75, 0.45, 0.12))
	DrawBatch.circle(ci, sun, 62.0, Color(1.0, 0.82, 0.55, 0.9))
	for i in 3:   # פסי עננים שזזים לאט
		var y := v.y * (0.18 + 0.12 * float(i))
		var x := fposmod(t * (6.0 + float(i) * 3.0) + float(i) * 400.0, v.x + 600.0) - 300.0
		DrawBatch.colored_polygon(ci, PackedVector2Array([Vector2(x, y), Vector2(x + 260, y - 8), Vector2(x + 520, y), Vector2(x + 300, y + 6)]), Color(0.95, 0.6, 0.55, 0.25))


# ---- פסגות רחוקות ----
static func far_peaks(ci: CanvasItem, sc: float, v: Vector2, y: float, _t: float) -> void:
	var period := 1100.0
	var start := int(floor(sc / period)) - 1
	for k in range(start, start + int(ceil(v.x / period)) + 3):
		var x := float(k) * period - sc
		var r := _rng(k * 131 + 7)
		for i in 3:
			var px := x + r.randf_range(0.0, period)
			var w := r.randf_range(260.0, 420.0)
			var h := r.randf_range(220.0, 330.0)
			var top := Vector2(px, y - h)
			DrawBatch.colored_polygon(ci, PackedVector2Array([Vector2(px - w * 0.5, y), top, Vector2(px + w * 0.5, y)]), Color("5a4a66"))
			DrawBatch.colored_polygon(ci, PackedVector2Array([top, top + Vector2(-w * 0.12, h * 0.2), top + Vector2(-w * 0.03, h * 0.15), top + Vector2(w * 0.06, h * 0.24), top + Vector2(w * 0.13, h * 0.2)]), Color("d8c8d0"))   # שלג
	DrawBatch.rect(ci, Rect2(0, y - 40.0, v.x, v.y - y + 40.0), Color(0.75, 0.5, 0.55, 0.35))   # אובך
	DrawBatch.rect(ci, Rect2(0, y, v.x, v.y - y), Color("5a4a66"))


# ---- צוקים עם פגודה, מפל וגשר ----
static func mid_cliffs(ci: CanvasItem, sc: float, v: Vector2, y: float, t: float) -> void:
	var period := 1500.0
	var start := int(floor(sc / period)) - 1
	for k in range(start, start + int(ceil(v.x / period)) + 3):
		var x := float(k) * period - sc
		var r := _rng(k * 977 + 3)
		var c1 := Color("3e3446")
		# שני צוקים עם פסי שכבות
		var a := x + r.randf_range(100.0, 400.0)
		var aw := r.randf_range(220.0, 300.0)
		var ah := r.randf_range(260.0, 340.0)
		DrawBatch.colored_polygon(ci, PackedVector2Array([Vector2(a, y), Vector2(a + 20, y - ah), Vector2(a + aw * 0.5, y - ah - 16), Vector2(a + aw - 10, y - ah + 6), Vector2(a + aw, y)]), c1)
		for s in 3:
			var sy := y - ah * (0.3 + 0.2 * float(s))
			DrawBatch.line(ci, Vector2(a + 10, sy), Vector2(a + aw - 6, sy + 6), Color(1, 1, 1, 0.05), 2.0)
		var b := a + aw + r.randf_range(160.0, 260.0)
		var bw := r.randf_range(240.0, 320.0)
		var bh := r.randf_range(200.0, 280.0)
		DrawBatch.colored_polygon(ci, PackedVector2Array([Vector2(b, y), Vector2(b + 14, y - bh), Vector2(b + bw - 12, y - bh - 10), Vector2(b + bw, y)]), c1)
		# גשר חבלים בין הצוקים
		var p0 := Vector2(a + aw - 8, y - ah + 20)
		var p1 := Vector2(b + 16, y - bh + 6)
		var mid := (p0 + p1) * 0.5 + Vector2(0, 26)
		DrawBatch.polyline(ci, PackedVector2Array([p0, mid, p1]), Color("2a2230"), 2.0)
		DrawBatch.polyline(ci, PackedVector2Array([p0 + Vector2(0, -10), mid + Vector2(0, -8), p1 + Vector2(0, -10)]), Color("2a2230"), 1.0)
		# פגודה על הצוק השני
		var pc := Vector2(b + bw * 0.5, y - bh - 10)
		for f in 3:
			var fw := 70.0 - float(f) * 18.0
			var fy := pc.y - float(f) * 26.0
			DrawBatch.rect(ci, Rect2(pc.x - fw * 0.32, fy - 18.0, fw * 0.64, 18.0), Color("2e2634"))
			DrawBatch.colored_polygon(ci, PackedVector2Array([Vector2(pc.x - fw * 0.6, fy - 16), Vector2(pc.x, fy - 30), Vector2(pc.x + fw * 0.6, fy - 16), Vector2(pc.x + fw * 0.4, fy - 20), Vector2(pc.x - fw * 0.4, fy - 20)]), Color("2a2030"))
		DrawBatch.circle(ci, pc + Vector2(0, -8), 3.0, Color(1.0, 0.75, 0.4, 0.8 + 0.2 * sin(t * 3.0 + float(k))))   # חלון מואר
		# מפל מהצוק הראשון
		var wx := a + aw * 0.3
		var fall_y := y - ah + 4.0
		DrawBatch.rect(ci, Rect2(wx, fall_y, 10.0, ah - 4.0), Color(0.8, 0.85, 0.95, 0.35))
		var off := fposmod(t * 90.0, 40.0)
		for q in 3:
			DrawBatch.line(ci, Vector2(wx + 3.0 + float(q) * 2.0, fall_y + off + float(q) * 13.0), Vector2(wx + 3.0 + float(q) * 2.0, fall_y + off + float(q) * 13.0 + 18.0), Color(1, 1, 1, 0.35), 1.5)
	DrawBatch.rect(ci, Rect2(0, y - 30.0, v.x, 40.0), Color(0.85, 0.6, 0.6, 0.18))   # ערפל בעמק


# ---- אורנים וסלעים קרובים (צלליות כהות, מעט מצולעים) ----
const PINE := [Color("1e2028"), Color("24262e"), Color("2a2a32")]


static func near_pines(ci: CanvasItem, sc: float, v: Vector2, y: float, t: float) -> void:
	var period := 900.0
	var start := int(floor(sc / period)) - 1
	for k in range(start, start + int(ceil(v.x / period)) + 3):
		var x := float(k) * period - sc
		var r := _rng(k * 389 + 11)
		for i in 5:
			var px := x + r.randf_range(0.0, period)
			var col: Color = PINE[r.randi() % 3]
			if r.randf() < 0.7:   # אורן: 3 משולשים
				var h := r.randf_range(110.0, 190.0)
				var w := h * 0.42
				var sway := sin(t * 0.8 + px * 0.01) * 3.0
				DrawBatch.rect(ci, Rect2(px - 3.0, y - h * 0.25, 6.0, h * 0.25), col)
				for l in 3:
					var ly := y - h * 0.18 - float(l) * h * 0.26
					var lw := w * (1.0 - float(l) * 0.25)
					DrawBatch.colored_polygon(ci, PackedVector2Array([Vector2(px - lw * 0.5, ly), Vector2(px + sway * float(l), ly - h * 0.4), Vector2(px + lw * 0.5, ly)]), col)
			else:   # סלע
				var rw := r.randf_range(60.0, 120.0)
				DrawBatch.colored_polygon(ci, PackedVector2Array([Vector2(px, y), Vector2(px + rw * 0.15, y - rw * 0.5), Vector2(px + rw * 0.6, y - rw * 0.6), Vector2(px + rw, y)]), col)
	DrawBatch.rect(ci, Rect2(0, y - 4.0, v.x, v.y - y + 4.0), PINE[0])


# ---- קרקע סלעית (חתיכה, בלי בורות) ----
class CliffGround extends Node2D:
	var w := 1024.0
	var depth := 90.0
	var seed_v := 0

	func _ready() -> void:
		z_index = 1

	func _draw() -> void:
		DrawBatch.begin(self)
		_draw_b()
		DrawBatch.end(self)

	func _draw_b() -> void:
		var r := RandomNumberGenerator.new()
		r.seed = seed_v
		var S := preload("res://effects/s21_decor.gd")
		DrawBatch.rect(self, Rect2(0, 0, w, depth), S.ROCK_D)
		DrawBatch.rect(self, Rect2(0, 0, w, 12.0), S.ROCK)
		DrawBatch.line(self, Vector2(0, 0), Vector2(w, 0), S.GRASS, 4.0)
		for i in int(w / 70.0):   # סדקים וגושי אבן
			var x := r.randf_range(0.0, w)
			var yy := r.randf_range(14.0, depth - 10.0)
			DrawBatch.line(self, Vector2(x, yy), Vector2(x + r.randf_range(-14.0, 14.0), yy + r.randf_range(6.0, 14.0)), Color(0, 0, 0, 0.25), 1.5)
			if r.randf() < 0.5:
				DrawBatch.rect(self, Rect2(x, yy, r.randf_range(10.0, 24.0), r.randf_range(6.0, 10.0)), S.ROCK_L.darkened(0.3))
		for i in int(w / 22.0):   # גבעולי עשב
			var gx := r.randf_range(0.0, w)
			DrawBatch.line(self, Vector2(gx, 1), Vector2(gx + r.randf_range(-3.0, 3.0), -r.randf_range(4.0, 10.0)), S.GRASS.lightened(0.1), 1.4)


# ---- בור יתדות ----
class SpikePit extends "res://environment/hazard.gd":
	var w := 80.0
	var depth := 60.0
	var bounce := 560.0
	var _seed := 0
	var hits := 0           # לבדיקות
	const SMART_HOP := 0.75  # כמה מהזומבים קופצים מעל הבור (השאר נופלים ומתים)

	func _ready() -> void:
		super._ready()
		z_index = 2
		rect = Rect2(0.0, depth - 26.0, w, 26.0)
		player_damage = 1
		zombie_damage = 60
		tick = 0.15   # (בודק הרבה - זומבי שנופל פנימה לא מספיק לברוח)
		story_kind = ""

	func _hazard_tick(_delta: float) -> void:
		# זומבים "למדו": רובם קופצים מעל הבור כשהם מגיעים לשפה (SMART_HOP), השאר נופלים פנימה
		for z in get_tree().get_nodes_in_group("zombies"):
			if z.dead or not z.is_on_floor() or absf(z.global_position.y - global_position.y) > 8.0:
				continue
			var gx: float = z.global_position.x
			var vx: float = z.velocity.x
			var l := global_position.x
			var near_edge: bool = (vx > 20.0 and gx > l - 36.0 and gx < l) or (vx < -20.0 and gx < l + w + 36.0 and gx > l + w)
			if near_edge:
				if not z.has_meta("pit_hop"):
					z.set_meta("pit_hop", randf() < SMART_HOP)
				if z.get_meta("pit_hop"):
					z.velocity.y = -540.0
					z.velocity.x = signf(vx) * maxf(absf(vx), 150.0)
		var p := get_tree().get_first_node_in_group("player")
		if p != null and not p.dead and world_rect().intersects(p.body_rect()) and p.velocity.y >= -50.0:
			if p.velocity.y >= 0.0:
				hits += 1
			p.velocity.y = -bounce   # היתדות זורקות אותך החוצה
			p.velocity.x = signf(p.velocity.x if p.velocity.x != 0.0 else 1.0) * maxf(absf(p.velocity.x), 140.0)

	func _draw() -> void:
		DrawBatch.begin(self)
		_draw_b()
		DrawBatch.end(self)

	func _draw_b() -> void:
		var r := RandomNumberGenerator.new()
		r.seed = _seed
		var S := preload("res://effects/s21_decor.gd")
		# קירות ותחתית הבור
		DrawBatch.rect(self, Rect2(0, 0, w, depth + 30.0), Color("1e1a18"))
		DrawBatch.rect(self, Rect2(0, 0, 6.0, depth), S.ROCK_D)
		DrawBatch.rect(self, Rect2(w - 6.0, 0, 6.0, depth), S.ROCK_D)
		DrawBatch.rect(self, Rect2(0, depth - 4.0, w, 34.0), Color("2a2420"))
		# עצמות
		for i in 2:
			var bx := r.randf_range(10.0, w - 20.0)
			DrawBatch.line(self, Vector2(bx, depth - 3), Vector2(bx + 10, depth - 6), Color("c8c0a8"), 2.0)
		DrawBatch.circle(self, Vector2(r.randf_range(14.0, w - 14.0), depth - 5.0), 3.5, Color("c8c0a8"))
		# יתדות
		var n := int(w / 9.0)
		for i in n:
			var x := 4.0 + float(i) * (w - 8.0) / float(n - 1)
			var h := r.randf_range(18.0, 26.0)
			var tip := Vector2(x + r.randf_range(-2.0, 2.0), depth - h)
			DrawBatch.colored_polygon(self, PackedVector2Array([Vector2(x - 3.5, depth), tip, Vector2(x + 3.5, depth)]), S.SPIKE.darkened(r.randf_range(0.0, 0.35)))
			DrawBatch.line(self, tip, tip + Vector2(0, 2), Color(1, 1, 1, 0.6), 1.0)
			if r.randf() < 0.35:
				DrawBatch.colored_polygon(self, PackedVector2Array([tip, tip + Vector2(-1.5, 6), tip + Vector2(1.5, 6)]), Color("8a1a1a"))
		# שלט אזהרה: גולגולת על יתד בקצה
		var sx := -12.0
		DrawBatch.line(self, Vector2(sx, 0), Vector2(sx, -26), S.WOOD, 3.0)
		DrawBatch.circle(self, Vector2(sx, -29), 5.0, Color("d8d0b8"))
		DrawBatch.circle(self, Vector2(sx - 2, -30), 1.2, Color("1a1410"))
		DrawBatch.circle(self, Vector2(sx + 2, -30), 1.2, Color("1a1410"))


# ---- עמודים ודגלי תפילה לאורך קומה שנייה ----
class Flags extends Node2D:
	var w := 300.0
	var seed_v := 0

	func _ready() -> void:
		z_index = 0

	func _draw() -> void:
		DrawBatch.begin(self)
		_draw_b()
		DrawBatch.end(self)

	func _draw_b() -> void:
		var r := RandomNumberGenerator.new()
		r.seed = seed_v
		var S := preload("res://effects/s21_decor.gd")
		var cols := [Color("c84a3a"), Color("e0b040"), Color("3a8a5a"), Color("3a6aa8"), Color("e8e0d0")]
		DrawBatch.line(self, Vector2(6, 0), Vector2(6, -60), S.WOOD, 4.0)
		DrawBatch.line(self, Vector2(w - 6, 0), Vector2(w - 6, -60), S.WOOD, 4.0)
		var pts := PackedVector2Array()
		for i in 9:
			var u := float(i) / 8.0
			pts.append(Vector2(lerpf(6.0, w - 6.0, u), -58.0 + sin(u * PI) * 18.0))
		DrawBatch.polyline(self, pts, Color("2a2018"), 1.2)
		var n := int(w / 22.0)
		for i in n:
			var u := (float(i) + 0.5) / float(n)
			var p := Vector2(lerpf(6.0, w - 6.0, u), -58.0 + sin(u * PI) * 18.0)
			DrawBatch.colored_polygon(self, PackedVector2Array([p, p + Vector2(10, 0), p + Vector2(9, 12), p + Vector2(1, 11)]), Color(cols[i % 5], 0.85))


# ---- מכשולים (מוצקים + מחסה) ----
class Obstacle extends Node2D:
	var kind := "rock"
	var size := Vector2(80, 40)
	var seed_v := 0

	func _ready() -> void:
		var body := StaticBody2D.new()
		body.collision_layer = 1
		body.add_to_group("no_outline")
		if size.y >= 30.0:
			add_to_group("cover")
		var cs := CollisionShape2D.new()
		var sh := RectangleShape2D.new()
		sh.size = size
		cs.shape = sh
		cs.position = Vector2(size.x * 0.5, -size.y * 0.5)
		body.add_child(cs)
		add_child(body)

	func cover_rect() -> Rect2:
		return Rect2(global_position + Vector2(0.0, -size.y), size)

	func _draw() -> void:
		DrawBatch.begin(self)
		_draw_b()
		DrawBatch.end(self)

	func _draw_b() -> void:
		var r := RandomNumberGenerator.new()
		r.seed = seed_v
		var S := preload("res://effects/s21_decor.gd")
		var w := size.x
		var h := size.y
		match kind:
			"rock":
				var pts := PackedVector2Array()
				for i in 9:
					var a := PI + float(i) * PI / 8.0
					pts.append(Vector2(w * 0.5 + cos(a) * w * 0.5 * r.randf_range(0.9, 1.05), sin(a) * h * r.randf_range(0.85, 1.0)))
				Art.fill_shaded(self, pts, S.ROCK, 0.15, 0.45, Art.OUTLINE, 1.6)
				DrawBatch.line(self, Vector2(w * 0.3, -h * 0.7), Vector2(w * 0.45, -h * 0.3), Color(0, 0, 0, 0.3), 1.5)
				DrawBatch.colored_polygon(self, PackedVector2Array([Vector2(w * 0.2, -h * 0.85), Vector2(w * 0.5, -h * 0.98), Vector2(w * 0.7, -h * 0.8), Vector2(w * 0.45, -h * 0.82)]), S.GRASS)
			"lantern":   # פנס אבן יפני
				var cx := w * 0.5
				Art.fill_shaded(self, PackedVector2Array([Vector2(cx - w * 0.4, 0), Vector2(cx + w * 0.4, 0), Vector2(cx + w * 0.32, -h * 0.12), Vector2(cx - w * 0.32, -h * 0.12)]), S.ROCK, 0.15, 0.4, Art.OUTLINE, 1.4)
				Art.fill_shaded(self, PackedVector2Array([Vector2(cx - w * 0.14, -h * 0.12), Vector2(cx + w * 0.14, -h * 0.12), Vector2(cx + w * 0.14, -h * 0.55), Vector2(cx - w * 0.14, -h * 0.55)]), S.ROCK, 0.15, 0.4, Art.OUTLINE, 1.4)
				Art.fill_shaded(self, PackedVector2Array([Vector2(cx - w * 0.3, -h * 0.55), Vector2(cx + w * 0.3, -h * 0.55), Vector2(cx + w * 0.3, -h * 0.78), Vector2(cx - w * 0.3, -h * 0.78)]), S.ROCK_L, 0.15, 0.4, Art.OUTLINE, 1.4)
				DrawBatch.rect(self, Rect2(cx - w * 0.14, -h * 0.74, w * 0.28, h * 0.14), Color(1.0, 0.75, 0.35, 0.85))
				Art.fill_shaded(self, PackedVector2Array([Vector2(cx - w * 0.5, -h * 0.78), Vector2(cx + w * 0.5, -h * 0.78), Vector2(cx + w * 0.1, -h), Vector2(cx - w * 0.1, -h)]), S.ROCK, 0.15, 0.4, Art.OUTLINE, 1.4)
			_:   # ארגז עץ עם חבלים
				Art.fill_shaded(self, PackedVector2Array([Vector2(0, 0), Vector2(w, 0), Vector2(w, -h), Vector2(0, -h)]), S.WOOD, 0.15, 0.4, Art.OUTLINE, 1.5)
				for q in 3:
					DrawBatch.line(self, Vector2(0, -h * (0.25 + 0.25 * float(q))), Vector2(w, -h * (0.25 + 0.25 * float(q))), Color(0, 0, 0, 0.25), 1.0)
				DrawBatch.line(self, Vector2(w * 0.3, 0), Vector2(w * 0.3, -h), Color("b89a60"), 2.0)
				DrawBatch.line(self, Vector2(w * 0.7, 0), Vector2(w * 0.7, -h), Color("b89a60"), 2.0)


# ---- ערפל זורם + עלים ברוח (שכבת מסך) ----
class CliffFX extends Node2D:
	var vp := Vector2(1280, 720)
	var _t := 0.0
	var _leaves := []

	func _ready() -> void:
		var r := RandomNumberGenerator.new()
		r.seed = 21
		for i in 14:
			_leaves.append([Vector2(r.randf_range(0, vp.x), r.randf_range(0, vp.y)), r.randf_range(60.0, 140.0), r.randf_range(0.0, TAU)])

	func _process(delta: float) -> void:
		_t += delta
		for l in _leaves:
			l[0] += Vector2(-l[1], 18.0 + sin(_t * 2.0 + l[2]) * 30.0) * delta
			l[2] += delta * 4.0
			if l[0].x < -20.0 or l[0].y > vp.y + 20.0:
				l[0] = Vector2(vp.x + 20.0, randf_range(0.0, vp.y * 0.7))
		queue_redraw()

	func _draw() -> void:
		DrawBatch.begin(self)
		_draw_b()
		DrawBatch.end(self)

	func _draw_b() -> void:
		for i in 3:   # פסי ערפל נמוכים
			var y := vp.y - 150.0 + float(i) * 30.0
			var x := fposmod(-_t * (20.0 + float(i) * 8.0), vp.x)
			for j in 2:
				var xx := x + float(j) * vp.x - vp.x * 0.5
				DrawBatch.colored_polygon(self, PackedVector2Array([Vector2(xx, y), Vector2(xx + vp.x * 0.5, y - 14), Vector2(xx + vp.x, y), Vector2(xx + vp.x * 0.5, y + 16)]), Color(0.95, 0.85, 0.9, 0.07))
		for l in _leaves:
			var p: Vector2 = l[0]
			var d := Vector2.from_angle(l[2]) * 4.0
			DrawBatch.colored_polygon(self, PackedVector2Array([p - d, p + d.orthogonal() * 0.5, p + d]), Color(0.85, 0.45, 0.35, 0.8))
