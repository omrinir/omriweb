extends RefCounted
# ============================================================
#  קישוטים לשלב 17 ("THE DRY RIVER") - נהר מת בצהרי היום, חום לבן, אוויר רועד.
#    noon_sky      - שמיים דהויים-לבנים, שמש גבוהה וחזקה, סנוור
#    mesas         - רכסי מסה רחוקים באובך + סכר שבור רחוק
#    banks         - גדות הנהר: קירות עפר סדוקים, עצים מתים, עמודי טלגרף, סירות על הגדה
#    reeds         - קני סוף יבשים ושלדי סירות קרובים
#    Riverbed      - (עולם) קרקעית בוץ סדוקה מעל הכביש: משושים של סדקים, מלח, עצמות דגים
#    RiverJunk     - (עולם, מאחורי הדמויות) סירות משיטה הפוכות, צמיגים, שלדי דגים, קני סוף
#    Obstacle      - (מוצק) "boat" סירת דייגים תקועה / "rock" סלע נהר / "log" גזע סחף
#    HeatHaze      - (מסך) שיידר: האוויר רועד מעל הקרקע (חזק יותר למטה), קצת סנוור
# ============================================================

const Art := preload("res://art.gd")
const Kit := preload("res://effects/backdrop_kit.gd")
const S13 := preload("res://effects/s13_decor.gd")

const MUD := Color("b89a72")        # בוץ יבש
const MUD_D := Color("8e7454")
const MUD_L := Color("d6c09a")
const CRACK := Color("5e4a34")
const BONE := Color("ece4d0")
const WOOD := Color("7a5a3a")
const WOOD_D := Color("4e3a26")


static func _rng(s: int) -> RandomNumberGenerator:
	var r := RandomNumberGenerator.new()
	r.seed = s
	return r


static func noon_sky(ci: CanvasItem, v: Vector2, t: float) -> void:
	Kit.gradient_sky(ci, v, [Color("7fa6c4"), Color("a8c4d6"), Color("d4e0e2"), Color("f2ece0"), Color("fbf4e4")])
	var sun := Vector2(v.x * 0.62, 70.0)
	for i in 6:   # סנוור גדול
		ci.draw_circle(sun, 260.0 - float(i) * 40.0, Color(1.0, 0.99, 0.9, 0.035 + float(i) * 0.02))
	ci.draw_circle(sun, 30.0, Color(1.0, 1.0, 0.97))
	for i in 8:   # קרניים דקות
		var a := float(i) * TAU / 8.0 + t * 0.03
		ci.draw_line(sun + Vector2.from_angle(a) * 40.0, sun + Vector2.from_angle(a) * 110.0, Color(1.0, 1.0, 0.92, 0.12), 2.0)
	Kit.clouds(ci, t * 4.0, v, t, 130.0, Color(1.0, 1.0, 1.0, 0.35), 3, 3.0)
	for i in 3:   # נשרים חגים
		var c := Vector2(v.x * (0.25 + 0.25 * float(i)), 150.0 + float(i) * 22.0)
		var a := t * (0.25 + 0.07 * float(i)) + float(i) * 2.0
		var p := c + Vector2(cos(a) * 90.0, sin(a) * 18.0)
		var fl := sin(t * 2.2 + float(i)) * 3.0
		ci.draw_polyline(PackedVector2Array([p + Vector2(-12, -2 + fl), p + Vector2(-4, 1), p, p + Vector2(4, 1), p + Vector2(12, -2 + fl)]), Color(0.18, 0.14, 0.1, 0.7), 2.0)


# רכסי מסה רחוקים (שטוחים מלמעלה) + סכר שבור באופק
static func mesas(ci: CanvasItem, sc: float, v: Vector2, y: float, t: float) -> void:
	var period := 1600.0
	var start := int(floor(sc / period)) - 1
	var col := Color(0.78, 0.66, 0.56, 0.75)
	for k in range(start, start + 3):
		var x := float(k) * period - sc
		var r := _rng(k * 53 + 7)
		var px := x
		while px < x + period:
			var w := r.randf_range(160.0, 380.0)
			var h := r.randf_range(50.0, 130.0)
			var poly := PackedVector2Array([Vector2(px, y), Vector2(px + w * 0.12, y - h), Vector2(px + w * 0.88, y - h), Vector2(px + w, y)])
			ci.draw_colored_polygon(poly, col)
			ci.draw_line(Vector2(px + w * 0.12, y - h), Vector2(px + w * 0.88, y - h), Color(0.88, 0.78, 0.68, 0.6), 2.0)
			px += w + r.randf_range(40.0, 160.0)
		if k % 2 == 0:   # הסכר השבור (משם הגיע השיטפון של שלב 16)
			var dx := x + 700.0
			ci.draw_rect(Rect2(dx, y - 120.0, 230.0, 120.0), Color(0.7, 0.68, 0.64, 0.8))
			ci.draw_colored_polygon(PackedVector2Array([Vector2(dx + 90.0, y - 120.0), Vector2(dx + 140.0, y - 120.0), Vector2(dx + 125.0, y - 40.0), Vector2(dx + 100.0, y - 60.0)]), Color(0.86, 0.82, 0.74, 1.0))
			for q in 6:
				ci.draw_line(Vector2(dx + 10.0 + float(q) * 36.0, y - 116.0), Vector2(dx + 10.0 + float(q) * 36.0, y - 4.0), Color(0.6, 0.58, 0.55, 0.6), 2.0)
	ci.draw_rect(Rect2(0, y, v.x, 220.0), Color(0.8, 0.7, 0.58, 0.7))
	for i in 4:   # פס מיראז' רועד באופק
		var yy := y - 6.0 + float(i) * 5.0
		ci.draw_line(Vector2(0, yy + sin(t * 3.0 + float(i)) * 1.5), Vector2(v.x, yy + sin(t * 2.4 + float(i) * 2.0) * 1.5), Color(0.9, 0.95, 1.0, 0.16), 3.0)


# גדות הנהר: קיר עפר סדוק משני הצדדים (הנהר זורם "לתוך" המסך), עצים מתים, עמודי טלגרף
static func banks(ci: CanvasItem, sc: float, v: Vector2, y: float, t: float) -> void:
	var period := 1200.0
	var start := int(floor(sc / period)) - 1
	for k in range(start, start + 3):
		var x := float(k) * period - sc
		var r := _rng(k * 191 + 3)
		var pts := PackedVector2Array([Vector2(x, y + 60.0)])
		var px := x
		while px < x + period + 1.0:
			pts.append(Vector2(px, y - r.randf_range(20.0, 70.0)))
			px += r.randf_range(60.0, 140.0)
		pts.append(Vector2(x + period + 140.0, y - 30.0))
		pts.append(Vector2(x + period + 140.0, y + 60.0))
		ci.draw_colored_polygon(pts, Color("b49a78"))
		for i in range(1, pts.size() - 2):   # שכבות אדמה + סדקים
			ci.draw_line(pts[i], pts[i] + Vector2(r.randf_range(-6.0, 6.0), r.randf_range(18.0, 40.0)), Color("8e7454"), 1.5)
		ci.draw_polyline(pts.slice(1, pts.size() - 2), Color("d8c4a0"), 2.0)
		for q in 2:   # עצים מתים על הגדה
			var tx := x + r.randf_range(80.0, period - 80.0)
			S13.dead_tree(ci, Vector2(tx, y - 40.0), r.randf_range(70.0, 120.0), Color("9a8a74"), k * 5 + q)
		var pole := x + r.randf_range(100.0, 1000.0)   # עמוד טלגרף נוטה
		ci.draw_line(Vector2(pole, y - 30.0), Vector2(pole + 8.0, y - 150.0), Color("5a4634"), 4.0)
		ci.draw_line(Vector2(pole - 16.0, y - 138.0), Vector2(pole + 30.0, y - 142.0), Color("5a4634"), 3.0)
		ci.draw_line(Vector2(pole + 30.0, y - 140.0), Vector2(pole + 230.0, y - 120.0 + sin(t * 0.7) * 2.0), Color(0.2, 0.16, 0.12, 0.5), 1.0)
		if r.randf() < 0.7:   # סירה הפוכה על הגדה
			var bx := x + r.randf_range(200.0, 1000.0)
			ci.draw_colored_polygon(PackedVector2Array([Vector2(bx, y - 40.0), Vector2(bx + 70.0, y - 40.0), Vector2(bx + 58.0, y - 62.0), Vector2(bx + 10.0, y - 60.0)]), Color("6a5a48"))
	Kit.ground_fade(ci, v, y + 20.0)


# קני סוף יבשים + שלדי סירות קרובים
static func reeds(ci: CanvasItem, sc: float, v: Vector2, y: float, t: float) -> void:
	var period := 900.0
	var start := int(floor(sc / period)) - 1
	for k in range(start, start + 3):
		var x := float(k) * period - sc
		var r := _rng(k * 311 + 19)
		for c in 4:
			var cx := x + r.randf_range(0.0, period)
			for i in 9:
				var bx := cx + float(i) * 4.0
				var h := r.randf_range(30.0, 70.0)
				var bend := sin(t * 1.3 + float(i) + cx * 0.01) * 3.0
				ci.draw_line(Vector2(bx, y), Vector2(bx + 6.0 + bend, y - h), Color("a8946a"), 1.5)
				if i % 3 == 0:
					ci.draw_line(Vector2(bx + 6.0 + bend, y - h), Vector2(bx + 7.0 + bend, y - h - 9.0), Color("7a6644"), 3.0)
		if r.randf() < 0.6:   # שלד סירה (צלעות עץ)
			var bx2 := x + r.randf_range(100.0, 800.0)
			for i in 7:
				ci.draw_arc(Vector2(bx2 + float(i) * 18.0, y + 6.0), 26.0, PI + 0.5, TAU - 0.5, 8, Color("6a5038"), 3.0)
			ci.draw_line(Vector2(bx2 - 18.0, y - 8.0), Vector2(bx2 + 128.0, y - 10.0), Color("6a5038"), 4.0)
	Kit.ground_fade(ci, v, y - 10.0)


# ============================================================
#  קרקעית הנהר: בוץ יבש סדוק מעל הכביש (z מעל הכביש, מתחת לדמויות)
# ============================================================
class Riverbed extends Node2D:
	var w := 1024.0
	var depth := 90.0
	var seed_v := 0

	func _ready() -> void:
		z_index = 1

	func _draw() -> void:
		var r := RandomNumberGenerator.new()
		r.seed = seed_v
		var S := preload("res://effects/s17_decor.gd")
		draw_rect(Rect2(0, 0, w, depth), S.MUD_D)
		draw_rect(Rect2(0, 0, w, 10.0), S.MUD)
		draw_rect(Rect2(0, 0, w, 2.5), S.MUD_L)
		# אריחי בוץ סדוקים על הפס העליון (פרספקטיבה: שורות שמצטמצמות)
		var rows := [[0.0, 10.0, 46.0], [10.0, 30.0, 70.0], [30.0, 62.0, 110.0]]
		for row in rows:
			var y0: float = row[0]
			var y1: float = row[1]
			var cell: float = row[2]
			var x := -r.randf_range(0.0, cell)
			while x < w:
				var cw := cell * r.randf_range(0.7, 1.3)
				var a := Vector2(x, y0)
				var b := Vector2(x + cw * r.randf_range(0.1, 0.3), y1)
				draw_line(a, b, S.CRACK, 1.4 if y0 > 0.0 else 1.0)
				if r.randf() < 0.5:   # סדק משני
					var m := a.lerp(b, 0.5)
					draw_line(m, m + Vector2(cw * 0.35, r.randf_range(-3.0, 3.0)), Color(S.CRACK, 0.7), 1.0)
				x += cw
			draw_line(Vector2(0, y1), Vector2(w, y1), Color(S.CRACK, 0.55), 1.2)
		for i in 26:   # כתמי מלח / חלוקי נחל
			var p := Vector2(r.randf_range(0.0, w), r.randf_range(4.0, depth - 6.0))
			if r.randf() < 0.4:
				Art.oval(self, p, r.randf_range(8.0, 22.0), r.randf_range(1.5, 3.0), Color(1.0, 0.98, 0.92, 0.35), 0.0, Art.NONE)
			else:
				Art.oval(self, p, r.randf_range(1.5, 3.5), r.randf_range(1.0, 2.2), Color("a08a6a"), 0.0, Art.NONE)
		for i in 3:   # שלד דג
			var fx := r.randf_range(20.0, w - 40.0)
			var fy := r.randf_range(14.0, 40.0)
			draw_line(Vector2(fx, fy), Vector2(fx + 18.0, fy), S.BONE, 1.2)
			for q in 5:
				var qx := fx + 3.0 + float(q) * 3.0
				draw_line(Vector2(qx, fy - 3.0), Vector2(qx, fy + 3.0), S.BONE, 0.8)
			draw_colored_polygon(PackedVector2Array([Vector2(fx + 18.0, fy - 3.5), Vector2(fx + 24.0, fy), Vector2(fx + 18.0, fy + 3.5)]), S.BONE)


# ============================================================
#  זבל הנהר מאחורי הדמויות (על הקרקעית): סירות משיטה, צמיגים, קני סוף, עצמות
# ============================================================
class RiverJunk extends Node2D:
	var seed_v := 0

	func _ready() -> void:
		z_index = -3

	func _draw() -> void:
		var r := RandomNumberGenerator.new()
		r.seed = seed_v
		var S := preload("res://effects/s17_decor.gd")
		var x := 0.0
		while x < 1024.0:
			var pick := r.randf()
			if pick < 0.25:   # סירת משיטה הפוכה חצי שקועה
				var bw := r.randf_range(60.0, 90.0)
				var hull := PackedVector2Array([Vector2(x, 0), Vector2(x + bw, 0), Vector2(x + bw - 8.0, -18.0), Vector2(x + 10.0, -20.0)])
				Art.fill(self, hull, S.WOOD, Art.OUTLINE, 1.2)
				for q in 4:
					draw_line(Vector2(x + 6.0, -4.0 - float(q) * 4.0), Vector2(x + bw - 4.0, -4.0 - float(q) * 4.0), S.WOOD_D, 1.0)
				x += bw + 30.0
			elif pick < 0.45:   # צמיג
				draw_circle(Vector2(x + 14.0, -10.0), 11.0, Color("1e1c1a"))
				draw_circle(Vector2(x + 14.0, -10.0), 5.0, S.MUD_D)
				x += 40.0
			elif pick < 0.7:   # קני סוף יבשים
				for i in 7:
					draw_line(Vector2(x + float(i) * 4.0, 0), Vector2(x + float(i) * 4.0 + 5.0, -r.randf_range(26.0, 48.0)), Color("a8946a"), 1.3)
				x += 36.0
			else:   # עצמות פזורות
				for i in 4:
					var bx := x + r.randf_range(0.0, 50.0)
					var d := Vector2.from_angle(r.randf_range(-0.4, 0.4)) * r.randf_range(5.0, 10.0)
					draw_line(Vector2(bx, -2) - d, Vector2(bx, -2) + d, S.BONE, 2.2)
					draw_circle(Vector2(bx, -2) - d, 1.8, S.BONE)
					draw_circle(Vector2(bx, -2) + d, 1.8, S.BONE)
				x += 70.0
			x += r.randf_range(40.0, 140.0)


# ============================================================
#  מכשולים מוצקים: "boat" סירת דייגים תקועה על הצד, "rock" סלע נהר חלק, "log" גזע סחף
# ============================================================
class Obstacle extends Node2D:
	var kind := "rock"
	var size := Vector2(80, 44)
	var seed_v := 0

	func _ready() -> void:
		var body := StaticBody2D.new()
		body.collision_layer = 1
		body.add_to_group("no_outline")   # מצייר קו מתאר משלו (סלע עגול / סירה) - בלי מלבן של התנגשות
		var cs := CollisionShape2D.new()
		var sh := RectangleShape2D.new()
		sh.size = size
		cs.shape = sh
		cs.position = Vector2(size.x * 0.5, -size.y * 0.5)
		body.add_child(cs)
		add_child(body)

	func _draw() -> void:
		var r := RandomNumberGenerator.new()
		r.seed = seed_v
		var S := preload("res://effects/s17_decor.gd")
		var w := size.x
		var h := size.y
		match kind:
			"boat":   # סירת דייגים על הצד: גוף, פסי צבע דהויים, חלון קבינה, חבל
				var hull := PackedVector2Array([Vector2(0, -h * 0.25), Vector2(w * 0.08, 0), Vector2(w * 0.92, 0), Vector2(w, -h * 0.35),
					Vector2(w * 0.97, -h * 0.72), Vector2(w * 0.05, -h * 0.7)])
				var paint: Color = [Color("4a7a8a"), Color("a84a3a"), Color("d8c8a0")][r.randi() % 3]
				Art.fill_shaded(self, hull, paint.lerp(Color("c8b89a"), 0.35), 0.1, 0.3, Art.OUTLINE, 1.4)
				draw_line(Vector2(w * 0.05, -h * 0.55), Vector2(w * 0.97, -h * 0.57), Color(1, 1, 1, 0.35), 2.0)
				for i in 6:   # קרשים
					var px := w * (0.12 + 0.14 * float(i))
					draw_line(Vector2(px, -h * 0.68), Vector2(px + 4.0, -2.0), Color(0, 0, 0, 0.15), 1.0)
				var cab := Rect2(w * 0.55, -h, w * 0.28, h * 0.3)   # קבינה קטנה
				draw_rect(cab, Color("e0d4b8"))
				draw_rect(cab, Art.OUTLINE, false, 1.2)
				draw_rect(Rect2(cab.position + Vector2(5, 4), Vector2(cab.size.x * 0.4, cab.size.y * 0.45)), Color("3a4a52"))
				draw_line(Vector2(w * 0.2, -h * 0.7), Vector2(w * 0.12, -h * 1.15), S.WOOD_D, 3.0)   # תורן שבור
				for i in 8:   # כתמי חלודה / מלח
					Art.oval(self, Vector2(r.randf_range(8.0, w - 8.0), r.randf_range(-h * 0.6, -6.0)), r.randf_range(2.0, 5.0), r.randf_range(1.0, 2.5), Color(0.5, 0.3, 0.15, 0.35), 0.0, Art.NONE)
			"log":   # גזע סחף מולבן עם ענפים
				Art.limb(self, PackedVector2Array([Vector2(4, -h * 0.5), Vector2(w * 0.5, -h * 0.55), Vector2(w - 4.0, -h * 0.45)]), h * 0.8, Color("c8b8a0"))
				draw_circle(Vector2(w - 4.0, -h * 0.45), h * 0.32, Color("a89880"))
				for i in 3:
					draw_arc(Vector2(w - 4.0, -h * 0.45), h * 0.1 * float(i + 1), 0.0, TAU, 10, Color("8a7a64"), 1.0)
				draw_line(Vector2(w * 0.3, -h * 0.8), Vector2(w * 0.22, -h * 1.5), Color("b8a890"), 3.0)
				draw_line(Vector2(w * 0.65, -h * 0.85), Vector2(w * 0.78, -h * 1.4), Color("b8a890"), 2.5)
			_:   # סלע נהר חלק
				var pts := PackedVector2Array()
				for i in 10:
					var a := PI + 0.12 + float(i) / 9.0 * (PI - 0.24)
					pts.append(Vector2(w * 0.5 + cos(a) * w * 0.5 * r.randf_range(0.9, 1.05), sin(a) * h * r.randf_range(0.9, 1.05)))
				pts.append(Vector2(w, 0))
				pts.append(Vector2(0, 0))
				Art.fill_shaded(self, pts, Color("a89a88"), 0.12, 0.35, Art.OUTLINE, 1.4)
				draw_line(Vector2(w * 0.25, -h * 0.75), Vector2(w * 0.55, -h * 0.9), Color(1, 1, 1, 0.3), 2.0)
				draw_rect(Rect2(0, -h * 0.18, w, h * 0.18), Color(0.92, 0.9, 0.85, 0.25))   # קו מים ישן (מלח)


# ============================================================
#  אוויר רועד מהחום (שיידר על המסך): גלים אנכיים, חזקים יותר בחלק התחתון (מעל הקרקע)
# ============================================================
class HeatHaze extends ColorRect:
	var strength := 1.0

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		set_anchors_preset(Control.PRESET_FULL_RECT)
		var sh := Shader.new()
		sh.code = """
shader_type canvas_item;
uniform sampler2D screen_tex : hint_screen_texture, filter_linear;
uniform float strength = 1.0;
void fragment() {
	vec2 uv = SCREEN_UV;
	float band = smoothstep(0.35, 0.95, uv.y);           // למטה (ליד הקרקע) רועד יותר
	float w = sin(uv.y * 160.0 - TIME * 5.0) * 0.6 + sin(uv.y * 63.0 + uv.x * 9.0 - TIME * 3.1) * 0.4;
	uv.x += w * 0.0014 * band * strength;
	uv.y += cos(uv.x * 40.0 + TIME * 2.0) * 0.0006 * band * strength;
	vec4 c = texture(screen_tex, uv);
	c.rgb = mix(c.rgb, vec3(1.0, 0.98, 0.92), 0.045 * strength);   // סנוור קל
	COLOR = c;
}
"""
		var m := ShaderMaterial.new()
		m.shader = sh
		m.set_shader_parameter("strength", strength)
		material = m
