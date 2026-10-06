extends RefCounted
# ============================================================
#  שלב 11 (צפון-מזרח, "SUN-BLEACHED TOWN") - עיירת סרטאו בלילה.
#  השראה: הסרטאו של צפון-מזרח ברזיל - בתי אדובי מסוידים ודהויים מהשמש, כנסייה לבנה
#  עם שני מגדלים, שולחנות-הרים (שפאדה), קקטוסים (מנדקרו, שיקה-שיקה), משאבות-רוח
#  (קטה-וונטו) מעל בורות מים, וחג סאו ז'ואאו (ז'ונינה): דגלוני צבע ומדורות.
#  * static draw: רקע (כוכבים, ירח, שפאדה, כנסייה, משאבות-רוח, בתים).
#  * Town          - קישוט עולם מאחורי הכביש (חלקים של 1024).
#  * RoofHouse     - חזית בית שהגג שלו הוא קומה שנייה (הקומה עצמה = add_floor בשלב).
#  * Bunting       - חוטי דגלונים צבעוניים מעל הרחוב (מתנופפים).
#  * Bonfire       - מדורת סאו ז'ואאו (מקור אור + סכנת אש).
#  * CactusPatch   - שיחי קקטוס קוצניים על הכביש (סכנה).
#  * NightOverlay  - חושך עם אור רק ליד פנסים ומדורות. פנס שבור = חושך = הזומבים רואים אותך פחות.
# ============================================================

const Art := preload("res://art.gd")


static func _rng(s: int) -> RandomNumberGenerator:
	var r := RandomNumberGenerator.new()
	r.seed = s
	return r


# ---------------- שמיים ----------------
static func stars(ci: CanvasItem, v: Vector2, t: float, scroll: float) -> void:
	var r := _rng(1101)
	for i in 140:
		var x := fposmod(r.randf_range(0.0, 2400.0) - scroll, v.x + 40.0) - 20.0
		var y := r.randf_range(0.0, 430.0)
		var tw := 0.55 + 0.45 * sin(t * r.randf_range(1.0, 3.5) + float(i))
		var s := r.randf_range(0.6, 1.6)
		ci.draw_circle(Vector2(x, y), s, Color(0.9, 0.92, 1.0, 0.35 + 0.5 * tw * (1.0 - y / 520.0)))
	for i in 220:   # שביל החלב: רצועה אלכסונית של כוכבים זעירים
		var u := r.randf()
		var off := r.randfn(0.0, 38.0)
		var c := Vector2(u * v.x * 1.2 - 60.0 + off * 0.5, 40.0 + u * 300.0 + off)
		ci.draw_circle(c, r.randf_range(0.4, 0.9), Color(0.75, 0.8, 1.0, r.randf_range(0.1, 0.35)))


static func moon(ci: CanvasItem, c: Vector2) -> void:
	for i in 5:
		ci.draw_circle(c, 110.0 - float(i) * 18.0, Color(0.75, 0.82, 1.0, 0.03 + float(i) * 0.015))
	ci.draw_circle(c, 32.0, Color("e8ecf4"))
	for q in [[Vector2(-9, -6), 6.0], [Vector2(8, 5), 8.0], [Vector2(-3, 12), 4.0], [Vector2(11, -11), 3.5]]:
		ci.draw_circle(c + (q[0] as Vector2), float(q[1]), Color("c8d0dc"))


static func mesa(ci: CanvasItem, x: float, base_y: float, w: float, h: float, c: Color) -> void:
	ci.draw_colored_polygon(PackedVector2Array([Vector2(x, base_y), Vector2(x + w * 0.12, base_y - h * 0.8), Vector2(x + w * 0.2, base_y - h), Vector2(x + w * 0.82, base_y - h), Vector2(x + w * 0.9, base_y - h * 0.75), Vector2(x + w, base_y)]), c)


static func church(ci: CanvasItem, base: Vector2, s: float, c: Color, lit: Color) -> void:
	var w := 120.0 * s
	ci.draw_rect(Rect2(base.x - w * 0.5, base.y - 70.0 * s, w, 70.0 * s), c)
	ci.draw_colored_polygon(PackedVector2Array([base + Vector2(-w * 0.3, -70 * s), base + Vector2(w * 0.3, -70 * s), base + Vector2(0, -100 * s)]), c)
	for side: float in [-1.0, 1.0]:   # שני מגדלי פעמונים
		var tx := base.x + side * w * 0.5 - (22.0 * s if side > 0.0 else 0.0)
		ci.draw_rect(Rect2(tx, base.y - 130.0 * s, 22.0 * s, 130.0 * s), c)
		ci.draw_colored_polygon(PackedVector2Array([Vector2(tx - 2.0 * s, base.y - 130.0 * s), Vector2(tx + 24.0 * s, base.y - 130.0 * s), Vector2(tx + 11.0 * s, base.y - 150.0 * s)]), c)
		ci.draw_line(Vector2(tx + 11.0 * s, base.y - 150.0 * s), Vector2(tx + 11.0 * s, base.y - 162.0 * s), c, 2.0 * s)
		ci.draw_line(Vector2(tx + 7.0 * s, base.y - 158.0 * s), Vector2(tx + 15.0 * s, base.y - 158.0 * s), c, 2.0 * s)
		ci.draw_rect(Rect2(tx + 7.0 * s, base.y - 118.0 * s, 8.0 * s, 12.0 * s), lit)
	ci.draw_rect(Rect2(base.x - 10.0 * s, base.y - 34.0 * s, 20.0 * s, 34.0 * s), lit.darkened(0.3))
	ci.draw_circle(Vector2(base.x, base.y - 52.0 * s), 6.0 * s, lit)


static func windpump(ci: CanvasItem, base: Vector2, h: float, t: float, phase: float, c: Color) -> void:
	ci.draw_line(base + Vector2(-10, 0), base + Vector2(-2, -h), c, 2.0)
	ci.draw_line(base + Vector2(10, 0), base + Vector2(2, -h), c, 2.0)
	for i in 4:   # סריג
		var y := -h * float(i + 1) / 5.0
		var k := 1.0 - float(i + 1) / 5.0
		ci.draw_line(base + Vector2(-2.0 - 8.0 * k, y), base + Vector2(2.0 + 8.0 * k, y), c, 1.2)
	var hub := base + Vector2(0, -h - 3.0)
	for i in 12:   # גלגל להבים
		var a := t * 2.2 + phase + float(i) * TAU / 12.0
		ci.draw_line(hub, hub + Vector2(cos(a) * 14.0, sin(a) * 14.0), c, 2.0)
	ci.draw_arc(hub, 14.0, 0.0, TAU, 16, c, 1.0)
	ci.draw_colored_polygon(PackedVector2Array([hub + Vector2(2, -1), hub + Vector2(22, -6), hub + Vector2(22, 4)]), c)   # זנב


static func adobe_silhouette(ci: CanvasItem, x: float, base_y: float, w: float, h: float, c: Color, r: RandomNumberGenerator, lit: Color) -> void:
	ci.draw_rect(Rect2(x, base_y - h, w, h), c)
	if r.randf() < 0.5:   # גג רעפים משופע
		ci.draw_colored_polygon(PackedVector2Array([Vector2(x - 3, base_y - h), Vector2(x + w + 3, base_y - h), Vector2(x + w * 0.5, base_y - h - 12.0)]), c)
	var n := maxi(1, int(w / 28.0))
	for i in n:
		if r.randf() < 0.35:
			ci.draw_rect(Rect2(x + 6.0 + float(i) * (w - 12.0) / float(n), base_y - h * 0.6, 7.0, 9.0), lit)


static func bunting_line(ci: CanvasItem, a: Vector2, b: Vector2, t: float, sag: float, seed_v: int, alpha := 1.0) -> void:
	var cols := [Color("e83a3a"), Color("f0c030"), Color("3aa0e8"), Color("4ac06a"), Color("e86ac0"), Color("f08a30")]
	var n := maxi(4, int(a.distance_to(b) / 16.0))
	var prev := a
	for i in range(1, n + 1):
		var u := float(i) / float(n)
		var p := a.lerp(b, u) + Vector2(0.0, sin(u * PI) * sag)
		ci.draw_line(prev, p, Color(0.15, 0.12, 0.1, 0.9 * alpha), 1.0)
		if i < n:
			var fl := sin(t * 3.0 + float(i) * 0.9 + float(seed_v)) * 2.0
			ci.draw_colored_polygon(PackedVector2Array([p + Vector2(-4, 0), p + Vector2(4, 0), p + Vector2(fl, 9.0)]), Color(cols[(i + seed_v) % cols.size()], alpha))
		prev = p


# ============================================================
#  קישוט עולם: בתי אדובי, בורות מים, עציצי חרס, ערסלים, קקטוסים
# ============================================================
class Town extends Node2D:
	var seed_v := 0
	var skip := []      # [x0, x1] מקומיים שבהם יש בית עם גג (RoofHouse) - לא מציירים שם

	func _ready() -> void:
		z_index = -3

	func _free(x0: float, x1: float) -> bool:
		for s in skip:
			if x1 > float(s[0]) - 10.0 and x0 < float(s[1]) + 10.0:
				return false
		return true

	func _draw() -> void:
		var r := S11._rng(seed_v)
		var walls := [Color("d8d0c0"), Color("d8b880"), Color("a8c0c8"), Color("d8a8a0"), Color("e0dcc8"), Color("b8c8a0")]
		var x := 0.0
		while x < 1024.0:
			var pick := r.randf()
			var w := r.randf_range(90.0, 160.0)
			if not _free(x, x + w):
				x += 40.0
				continue
			if pick < 0.6:   # בית אדובי
				var h := r.randf_range(70.0, 105.0)
				S11.house(self, Vector2(x, 0.0), w, h, walls[r.randi() % walls.size()], r)
				x += w + r.randf_range(4.0, 30.0)
			elif pick < 0.75:   # בור מים על רגליים
				draw_rect(Rect2(x + 10.0, -60.0, 4.0, 60.0), Color("6a6460"))
				draw_rect(Rect2(x + 46.0, -60.0, 4.0, 60.0), Color("6a6460"))
				Art.fill_shaded(self, PackedVector2Array([Vector2(x + 4, -96), Vector2(x + 56, -96), Vector2(x + 56, -60), Vector2(x + 4, -60)]), Color("a8a4a0"), 0.2, 0.3)
				draw_rect(Rect2(x + 4.0, -82.0, 52.0, 3.0), Color("8a8480"))
				x += 80.0
			elif pick < 0.88:   # עציצי חרס + כיסא + ערסל
				for i in 3:
					Art.oval_shaded(self, Vector2(x + 12.0 + float(i) * 16.0, -9.0), 7.0, 9.0, Color("a85a34"))
				draw_line(Vector2(x + 70, 0), Vector2(x + 70, -60), Color("5a3e24"), 3.0)
				draw_line(Vector2(x + 140, 0), Vector2(x + 140, -60), Color("5a3e24"), 3.0)
				var pts := PackedVector2Array()
				for q in 9:
					var u := float(q) / 8.0
					pts.append(Vector2(lerpf(x + 70.0, x + 140.0, u), -52.0 + sin(u * PI) * 18.0))
				draw_polyline(pts, Color("c84a3a"), 5.0)
				draw_polyline(pts, Color("f0c040"), 1.5)
				x += 160.0
			else:   # קקטוסים
				S10.mandacaru(self, Vector2(x + 20.0, 0.0), r.randf_range(60.0, 100.0), Color("3a5a34"))
				S10.mandacaru(self, Vector2(x + 52.0, 0.0), r.randf_range(35.0, 55.0), Color("466a3a"))
				x += 80.0

	const S11 := preload("res://effects/s11_decor.gd")
	const S10 := preload("res://effects/s10_decor.gd")


# בית אדובי בחזית: קירות מסוידים שהשמש הלבינה, פס צבע תחתון, דלת עץ, חלונות עם תריסים
static func house(ci: CanvasItem, base: Vector2, w: float, h: float, wall: Color, r: RandomNumberGenerator) -> void:
	ci.draw_rect(Rect2(base.x, base.y - h, w, h), wall)
	ci.draw_rect(Rect2(base.x, base.y - 16.0, w, 16.0), wall.darkened(0.25))   # פס לכלוך / צבע תחתון
	for i in 5:   # טיח מתקלף
		var px := base.x + r.randf_range(4.0, w - 14.0)
		var py := base.y - r.randf_range(20.0, h - 10.0)
		ci.draw_rect(Rect2(px, py, r.randf_range(5.0, 12.0), r.randf_range(3.0, 7.0)), Color("a87a5a").darkened(0.1))
	ci.draw_rect(Rect2(base.x - 2.0, base.y - h - 4.0, w + 4.0, 5.0), wall.lightened(0.15))   # כרכוב
	var dx := base.x + w * r.randf_range(0.2, 0.6)
	var door := Color("3a5a7a") if r.randf() < 0.5 else Color("7a3a2a")
	Art.fill(ci, PackedVector2Array([Vector2(dx, base.y), Vector2(dx, base.y - 44.0), Vector2(dx + 22.0, base.y - 44.0), Vector2(dx + 22.0, base.y)]), door, Art.OUTLINE, 1.2)
	ci.draw_line(Vector2(dx + 11.0, base.y - 44.0), Vector2(dx + 11.0, base.y), door.darkened(0.3), 1.0)
	var wx := base.x + 8.0
	while wx < base.x + w - 20.0:
		if absf(wx - dx) > 26.0:
			var lit := r.randf() < 0.35
			ci.draw_rect(Rect2(wx, base.y - h * 0.62, 14.0, 16.0), Color(1.0, 0.7, 0.35, 0.95) if lit else Color("1e2028"))
			ci.draw_rect(Rect2(wx - 4.0, base.y - h * 0.62, 4.0, 16.0), door)   # תריסים פתוחים
			ci.draw_rect(Rect2(wx + 14.0, base.y - h * 0.62, 4.0, 16.0), door)
			if lit:
				Art.glow(ci, Vector2(wx + 7.0, base.y - h * 0.62 + 8.0), 16.0, Color(1.0, 0.7, 0.3, 0.25))
		wx += 34.0


# ============================================================
#  בית שהגג שלו הוא קומה שנייה (הקומה = add_floor בשלב; כאן רק החזית)
# ============================================================
class RoofHouse extends Node2D:
	var w := 400.0
	var h := 150.0
	var seed_v := 0

	func _ready() -> void:
		z_index = -2

	func _draw() -> void:
		var r := S11._rng(seed_v)
		var walls := [Color("e0d8c8"), Color("d8b880"), Color("b0c4c8"), Color("e0b0a0")]
		var x := 0.0
		while x < w - 10.0:
			var seg := minf(r.randf_range(110.0, 170.0), w - x)
			S11.house(self, Vector2(x, 0.0), seg, h, walls[r.randi() % walls.size()], r)
			x += seg
		draw_rect(Rect2(0.0, -h, w, h), Color(0, 0, 0, 0.12))   # צל מתחת לגג

	const S11 := preload("res://effects/s11_decor.gd")


# ============================================================
#  דגלוני ז'ונינה מעל הרחוב (בין שני עמודים)
# ============================================================
class Bunting extends Node2D:
	var w := 500.0
	var h := 190.0
	var seed_v := 0
	var _t := 0.0

	func _ready() -> void:
		z_index = -1

	func _process(delta: float) -> void:
		_t += delta
		if Art.on_screen(self, global_position + Vector2(w * 0.5, -h), w * 0.5 + 100.0):
			queue_redraw()

	func _draw() -> void:
		for px: float in [0.0, w]:
			draw_rect(Rect2(px - 2.0, -h - 10.0, 4.0, h + 10.0), Color("4a3424"))
		for k in 2:
			S11.bunting_line(self, Vector2(0.0, -h + float(k) * 16.0), Vector2(w, -h + 6.0 + float(k) * 16.0), _t, 26.0 + float(k) * 6.0, seed_v + k * 3)

	const S11 := preload("res://effects/s11_decor.gd")


# ============================================================
#  מדורת סאו ז'ואאו: בולי עץ בצורת פירמידה + אש (סכנה) + מקור אור
# ============================================================
class Bonfire extends Node2D:
	const FireZone := preload("res://environment/fire_zone.gd")
	var t := 0.0

	func _ready() -> void:
		z_index = 2
		add_to_group("s11_lights")
		var fz = FireZone.new()
		fz.setup(46.0, -1.0)
		add_child(fz)

	func _process(delta: float) -> void:
		t += delta
		if Art.on_screen(self, global_position):
			queue_redraw()

	func light() -> float:
		return 0.85 + 0.15 * sin(t * 9.0) * sin(t * 5.3)

	func _draw() -> void:
		for i in 5:   # בולי עץ
			var a := -PI * 0.5 + (float(i) - 2.0) * 0.35
			draw_line(Vector2(0, -2), Vector2(cos(a), sin(a)) * 30.0 + Vector2(0, -2), Color("3a2414"), 5.0)
		Art.glow(self, Vector2(0, -26), 46.0 * light(), Color(1.0, 0.55, 0.2, 0.35))


# ============================================================
#  שיחי שיקה-שיקה קוצניים על הכביש: דוקרים (1 נזק), זומבים חכמים עוקפים
# ============================================================
class CactusPatch extends "res://environment/hazard.gd":
	var width := 60.0
	var seed_v := 0

	func _ready() -> void:
		super._ready()
		rect = Rect2(-width * 0.5, -24.0, width, 25.0)
		player_damage = 1
		zombie_damage = 3
		tick = 0.8
		z_index = 3

	func _draw() -> void:
		var r := S11._rng(seed_v)
		var n := int(width / 12.0)
		for i in n:
			var x := -width * 0.5 + (float(i) + 0.5) * width / float(n)
			var hh := r.randf_range(14.0, 26.0)
			var c := Color("3a6a3a").lerp(Color("5a8a4a"), r.randf())
			Art.fill_shaded(self, PackedVector2Array([Vector2(x - 4, 0), Vector2(x + 4, 0), Vector2(x + 3, -hh), Vector2(x - 3, -hh)]), c, 0.2, 0.3)
			draw_circle(Vector2(x, -hh), 3.0, c)
			for k in 4:   # קוצים
				var y := -hh * float(k + 1) / 5.0
				draw_line(Vector2(x - 4, y), Vector2(x - 8, y - 2), Color("e8e0c0"), 0.8)
				draw_line(Vector2(x + 4, y), Vector2(x + 8, y - 2), Color("e8e0c0"), 0.8)
			if r.randf() < 0.3:   # פרח
				draw_circle(Vector2(x, -hh - 2.0), 2.2, Color("f080b0"))

	const S11 := preload("res://effects/s11_decor.gd")


# ============================================================
#  חושך הלילה: אור רק ליד פנסים שעובדים, מדורות, והשחקן (קצת).
#  השחקן רחוק מכל אור -> Game.player_dark = הזומבים רואים אותו פחות (לירות בפנסים!)
# ============================================================
class NightOverlay extends CanvasLayer:
	var darkness := 0.5
	var _rect: ColorRect
	const SHADER := """
shader_type canvas_item;
uniform float darkness = 0.5;
uniform vec4 lights[14];
uniform vec2 vp_size = vec2(1280.0, 720.0);
void fragment() {
	vec2 p = SCREEN_UV * vp_size;
	float lit = 0.0;
	for (int i = 0; i < 14; i++) {
		vec4 l = lights[i];
		if (l.w <= 0.0) continue;
		vec2 d = (p - l.xy) / vec2(l.z, l.z * 1.4);
		lit = max(lit, l.w * (1.0 - smoothstep(0.3, 1.0, length(d))));
	}
	COLOR = vec4(0.0, 0.01, 0.05, darkness * (1.0 - lit));
}
"""

	func _ready() -> void:
		layer = 1
		_rect = ColorRect.new()
		_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
		_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var mat := ShaderMaterial.new()
		mat.shader = Shader.new()
		mat.shader.code = SHADER
		_rect.material = mat
		add_child(_rect)

	func _exit_tree() -> void:
		Game.player_dark = false

	func _process(_delta: float) -> void:
		var vp := get_viewport()
		var ct := vp.get_canvas_transform()
		var view := ct.affine_inverse() * vp.get_visible_rect()
		var zoom := ct.get_scale().x
		var player := get_tree().get_first_node_in_group("player") as Node2D
		var lights := []
		var dark := true
		for lp in get_tree().get_nodes_in_group("lamps"):
			if lp._broken or absf(lp.global_position.x - view.get_center().x) > view.size.x * 0.75:
				continue
			var hp: Vector2 = lp.global_position + lp.head()
			var mid := Vector2(hp.x, hp.y + 110.0)
			if lights.size() < 12:
				lights.append(Vector4((ct * mid).x, (ct * mid).y, 190.0 * zoom, 0.95 * float(lp._on)))
			if player != null and absf(player.global_position.x - hp.x) < 170.0 and float(lp._on) > 0.5:
				dark = false
		for bf in get_tree().get_nodes_in_group("s11_lights"):
			var b := bf as Node2D
			if absf(b.global_position.x - view.get_center().x) > view.size.x * 0.75 or lights.size() >= 12:
				continue
			var c: Vector2 = ct * (b.global_position + Vector2(0.0, -30.0))
			lights.append(Vector4(c.x, c.y, 160.0 * zoom, bf.light()))
			if player != null and player.global_position.distance_to(b.global_position) < 150.0:
				dark = false
		if player != null:
			var pp: Vector2 = ct * (player.global_position + Vector2(0.0, -30.0))
			lights.append(Vector4(pp.x, pp.y, 75.0 * zoom, 0.5))
		var dyn: Array = preload("res://effects/dyn_lights.gd").gather(get_tree(), ct, zoom, player)   # פנס של השחקן
		lights = preload("res://effects/dyn_lights.gd").merge(dyn[0], lights, 14)
		Game.player_dark = dark and not dyn[1]
		var m := _rect.material as ShaderMaterial
		m.set_shader_parameter("lights", lights)
		m.set_shader_parameter("darkness", darkness)
		m.set_shader_parameter("vp_size", vp.get_visible_rect().size)
