extends RefCounted
# ============================================================
#  שלב 14 (צפון-מזרח, "FISHERMEN'S GRAVE") - נמל דייגים בלילה סוער.
#  * רקע (static): ים שחור עם קצף, מכמורתן בוער באופק, שלד מפעל שימורים עם ארובות ועגורנים,
#    תרנים של סירות, בית קברות של דייגים (צלבים עם רשתות, עוגנים, סירות הפוכות).
#  * StormOverlay - חושך (shader) עם אורות, "אזורים חשוכים" (בתוך המפעל - כמעט שחור),
#    ברקים שמאירים הכל לרגע (בחוץ בלבד) + רעם + Game.story("thunder").
#  * StormRain    - גשם כבד באלכסון על המסך (קווים).
#  * CanneryHall  - אולם מפעל השימורים הנטוש (קישוט עולם מאחור): קיר פח חלוד, מסועים, ווים עם
#    דגים מתנדנדים, מדפי קופסאות. נורות מהבהבות (Bulb). DarkZone = הטווח שבו חשוך מאוד.
#  * Cemetery     - בית הקברות של הדייגים מאחורי הכביש.
#  * Obstacle     - "hull" (סירה הפוכה), "traps" (ערימת מלכודות לובסטרים).
# ============================================================

const Art := preload("res://art.gd")
const Kit := preload("res://effects/backdrop_kit.gd")
const Sfx := preload("res://sfx.gd")


static func _rng(s: int) -> RandomNumberGenerator:
	var r := RandomNumberGenerator.new()
	r.seed = s
	return r


# ---- רקע ----
static func storm_sky(ci: CanvasItem, v: Vector2, t: float) -> void:
	Kit.gradient_sky(ci, v, [Color("03060c"), Color("08101a"), Color("0e1a24"), Color("16242c"), Color("1c2a2e")])
	var moon := Vector2(v.x * 0.72, 120.0)   # ירח חבוי בעננים
	for i in 3:
		ci.draw_circle(moon, 70.0 - float(i) * 18.0, Color(0.6, 0.7, 0.75, 0.04 + float(i) * 0.02))
	ci.draw_circle(moon, 22.0, Color(0.7, 0.78, 0.8, 0.35))
	Kit.clouds(ci, t * 14.0, v, t, 90.0, Color(0.04, 0.06, 0.08, 0.85), 5, 16.0)
	Kit.clouds(ci, t * 22.0, v, t, 170.0, Color(0.06, 0.08, 0.1, 0.8), 9, 26.0)


static func sea(ci: CanvasItem, sc: float, v: Vector2, y: float, t: float) -> void:
	ci.draw_rect(Rect2(0, y, v.x, v.y - y), Color("060c10"))
	for i in 7:   # קצף על הגלים
		var yy := y + 6.0 + float(i) * 9.0
		var pts := PackedVector2Array()
		for k in 33:
			var x := float(k) * v.x / 32.0
			pts.append(Vector2(x, yy + sin((x + sc * (0.6 + float(i) * 0.1)) * 0.03 + t * (1.0 + float(i) * 0.2)) * (1.5 + float(i) * 0.4)))
		ci.draw_polyline(pts, Color(0.5, 0.6, 0.65, 0.07 + float(i) * 0.015), 1.0)


static func burning_trawler(ci: CanvasItem, p: Vector2, t: float) -> void:
	Kit.smoke_column(ci, p + Vector2(10, -40), t, 220.0, Color(0.05, 0.05, 0.06, 0.5), 80.0)
	Kit.fire_glow(ci, p + Vector2(10, -24), t, 90.0, 3)
	var hull := PackedVector2Array([p + Vector2(-60, -8), p + Vector2(70, -10), p + Vector2(55, 6), p + Vector2(-50, 6)])
	ci.draw_colored_polygon(hull, Color("0a0808"))
	ci.draw_rect(Rect2(p + Vector2(-10, -30), Vector2(30, 22)), Color("0c0a0a"))   # גשר הפיקוד
	ci.draw_line(p + Vector2(-40, -8), p + Vector2(-48, -70), Color("0c0a0a"), 2.5)   # תורן
	ci.draw_line(p + Vector2(-48, -70), p + Vector2(40, -10), Color(0.05, 0.05, 0.05, 0.8), 1.0)
	for i in 5:   # להבות
		var fx := p.x - 6.0 + float(i) * 7.0
		var fh := 16.0 + 10.0 * sin(t * 9.0 + float(i) * 1.7)
		ci.draw_colored_polygon(PackedVector2Array([Vector2(fx - 5, p.y - 28), Vector2(fx + 5, p.y - 28), Vector2(fx + sin(t * 7.0 + float(i)) * 3.0, p.y - 28 - fh)]), Color(1.0, 0.55, 0.15, 0.85))
	ci.draw_line(p + Vector2(-60, 7), p + Vector2(70, 7), Color(1.0, 0.5, 0.2, 0.25), 3.0)   # השתקפות


static func cannery_skyline(ci: CanvasItem, sc: float, v: Vector2, base_y: float, t: float) -> void:
	var period := 1500.0
	var start := int(floor(sc / period)) - 1
	var c := Color("0a1014")
	for k in range(start, start + 3):
		var x := float(k) * period - sc
		var r := _rng(k * 977 + 3)
		# אולמות עם גגות משוננים
		var hx := x + r.randf_range(0.0, 200.0)
		var hw := r.randf_range(500.0, 700.0)
		var hh := r.randf_range(90.0, 130.0)
		var pts := PackedVector2Array([Vector2(hx, base_y)])
		var n := int(hw / 60.0)
		for i in n:
			pts.append(Vector2(hx + float(i) * hw / float(n), base_y - hh))
			pts.append(Vector2(hx + (float(i) + 0.7) * hw / float(n), base_y - hh - 26.0))
		pts.append(Vector2(hx + hw, base_y - hh))
		pts.append(Vector2(hx + hw, base_y))
		ci.draw_colored_polygon(pts, c)
		for i in 2:   # ארובות
			var cx := hx + hw * (0.3 + 0.35 * float(i))
			ci.draw_rect(Rect2(cx, base_y - hh - 110.0, 16.0, 110.0), c)
			Kit.smoke_column(ci, Vector2(cx + 8.0, base_y - hh - 110.0), t + float(i), 140.0, Color(0.08, 0.1, 0.12, 0.25), 50.0)
		for i in 6:   # חלונות מהבהבים
			var wx := hx + 30.0 + float(i) * (hw - 60.0) / 5.0
			var on := sin(t * (1.0 + float(i) * 0.37) + float(k)) > 0.6 and r.randf() < 0.7
			ci.draw_rect(Rect2(wx, base_y - hh * 0.6, 14.0, 10.0), Color(0.85, 0.7, 0.35, 0.55) if on else Color(0.1, 0.12, 0.13))
		# עגורן נמל
		var gx := x + r.randf_range(900.0, 1300.0)
		ci.draw_line(Vector2(gx, base_y), Vector2(gx, base_y - 230.0), c, 7.0)
		ci.draw_line(Vector2(gx - 40.0, base_y - 220.0), Vector2(gx + 170.0, base_y - 230.0), c, 5.0)
		ci.draw_line(Vector2(gx + 150.0, base_y - 228.0), Vector2(gx + 150.0 + sin(t * 0.8) * 6.0, base_y - 140.0), Color(0.05, 0.07, 0.08), 1.5)
		ci.draw_rect(Rect2(gx + 142.0 + sin(t * 0.8) * 6.0, base_y - 142.0, 16.0, 12.0), c)


static func masts(ci: CanvasItem, sc: float, v: Vector2, base_y: float, t: float) -> void:
	var period := 700.0
	var start := int(floor(sc / period)) - 1
	for k in range(start, start + 4):
		var x := float(k) * period - sc
		var r := _rng(k * 211 + 7)
		for i in 2:
			var bx := x + r.randf_range(0.0, period - 160.0)
			var rock := sin(t * 1.3 + float(k * 3 + i)) * 0.05   # הסירות מתנדנדות בסערה
			var tip := Vector2(bx + 60.0, base_y - r.randf_range(120.0, 170.0)).rotated(0.0)
			var hull := PackedVector2Array([Vector2(bx, base_y - 14.0), Vector2(bx + 130.0, base_y - 16.0), Vector2(bx + 112.0, base_y), Vector2(bx + 14.0, base_y)])
			ci.draw_colored_polygon(hull, Color("101a20"))
			var top := Vector2(bx + 60.0, base_y - 14.0) + (tip - Vector2(bx + 60.0, base_y - 14.0)).rotated(rock)
			ci.draw_line(Vector2(bx + 60.0, base_y - 14.0), top, Color("141e24"), 2.5)
			ci.draw_line(top, Vector2(bx + 2.0, base_y - 14.0), Color(0.08, 0.12, 0.14, 0.8), 1.0)
			ci.draw_line(top, Vector2(bx + 128.0, base_y - 16.0), Color(0.08, 0.12, 0.14, 0.8), 1.0)
			if r.randf() < 0.5:   # פנס ירוק/אדום על התורן
				ci.draw_circle(top + Vector2(0, 8), 2.0, Color(0.3, 1.0, 0.5, 0.8) if i == 0 else Color(1.0, 0.3, 0.3, 0.8))


static func cross(ci: CanvasItem, p: Vector2, h: float, c: Color, net: bool, tilt := 0.0) -> void:
	var up := Vector2(sin(tilt), -cos(tilt))
	var rt := Vector2(cos(tilt), sin(tilt))
	ci.draw_line(p, p + up * h, c, 4.0)
	ci.draw_line(p + up * h * 0.72 - rt * h * 0.3, p + up * h * 0.72 + rt * h * 0.3, c, 3.5)
	if net:   # רשת דייגים תלויה על הצלב
		var a := p + up * h * 0.72 - rt * h * 0.3
		var b := p + up * h * 0.72 + rt * h * 0.3
		for i in 5:
			var u := float(i) / 4.0
			ci.draw_line(a.lerp(b, u), a.lerp(b, u) + Vector2(0, h * 0.35 + sin(u * PI) * 6.0), Color(0.55, 0.5, 0.4, 0.5), 1.0)
		ci.draw_polyline(PackedVector2Array([a + Vector2(0, h * 0.18), a.lerp(b, 0.5) + Vector2(0, h * 0.24), b + Vector2(0, h * 0.18)]), Color(0.55, 0.5, 0.4, 0.5), 1.0)


static func anchor(ci: CanvasItem, p: Vector2, s: float, c: Color) -> void:
	ci.draw_line(p, p + Vector2(0, -34) * s, c, 3.5 * s)
	ci.draw_arc(p + Vector2(0, -36) * s, 4.0 * s, 0.0, TAU, 8, c, 2.0 * s)
	ci.draw_line(p + Vector2(-10, -26) * s, p + Vector2(10, -26) * s, c, 3.0 * s)
	ci.draw_arc(p + Vector2(0, -12) * s, 13.0 * s, 0.3, PI - 0.3, 10, c, 3.5 * s)


static func upturned_hull(ci: CanvasItem, p: Vector2, w: float, h: float, c: Color, dark: Color) -> void:
	var pts := PackedVector2Array()
	for i in 13:
		var u := float(i) / 12.0
		pts.append(p + Vector2(u * w, -sin(u * PI) * h - (h * 0.15 if u > 0.15 and u < 0.85 else 0.0)))
	pts.append(p + Vector2(w, 0))
	pts.append(p)
	ci.draw_colored_polygon(pts, c)
	for i in 3:   # קרשים
		ci.draw_line(p + Vector2(w * 0.08, -h * (0.3 + 0.25 * float(i))), p + Vector2(w * 0.92, -h * (0.3 + 0.25 * float(i))), dark, 1.0)


# ============================================================
#  חושך + ברקים
# ============================================================
class StormOverlay extends CanvasLayer:
	var darkness := 0.52
	var inside_dark := 0.86          # כמה חשוך בתוך המפעל
	var flash := 0.0                 # 0..1 ברק עכשיו
	var _rect: ColorRect
	const SHADER := """
shader_type canvas_item;
uniform float darkness = 0.5;
uniform float inside_dark = 0.9;
uniform float flash = 0.0;
uniform vec4 lights[16];
uniform vec4 zones[3];
uniform vec2 vp_size = vec2(1280.0, 720.0);
void fragment() {
	vec2 p = SCREEN_UV * vp_size;
	float lit = 0.0;
	for (int i = 0; i < 16; i++) {
		vec4 l = lights[i];
		if (l.w <= 0.0) continue;
		vec2 d = (p - l.xy) / vec2(l.z, l.z * 1.3);
		lit = max(lit, l.w * (1.0 - smoothstep(0.25, 1.0, length(d))));
	}
	float inside = 0.0;
	for (int i = 0; i < 3; i++) {
		vec4 z = zones[i];
		if (z.w <= 0.0) continue;
		inside = max(inside, smoothstep(z.x - 50.0, z.x + 30.0, p.x) * (1.0 - smoothstep(z.y - 30.0, z.y + 50.0, p.x)) * step(z.z, p.y));
	}
	float d = mix(darkness, inside_dark, inside);
	float fa = flash * (1.0 - inside);
	float a = d * (1.0 - lit) * (1.0 - fa);
	COLOR = vec4(mix(vec3(0.0, 0.015, 0.04), vec3(0.85, 0.9, 1.0), fa), max(a, fa * 0.32));
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

	func _process(delta: float) -> void:
		flash = maxf(flash - delta * 3.0, 0.0)
		var vp := get_viewport()
		var ct := vp.get_canvas_transform()
		var view := ct.affine_inverse() * vp.get_visible_rect()
		var zoom := ct.get_scale().x
		var player := get_tree().get_first_node_in_group("player") as Node2D
		var lights := []
		var dark := true
		for lp in get_tree().get_nodes_in_group("lamps"):
			if lp._broken or absf(lp.global_position.x - view.get_center().x) > view.size.x * 0.75 or lights.size() >= 13:
				continue
			var hp: Vector2 = lp.global_position + lp.head()
			var mid := Vector2(hp.x, hp.y + 110.0)
			lights.append(Vector4((ct * mid).x, (ct * mid).y, 190.0 * zoom, 0.95 * float(lp._on)))
			if player != null and absf(player.global_position.x - hp.x) < 170.0 and float(lp._on) > 0.5:
				dark = false
		for bf in get_tree().get_nodes_in_group("s14_lights"):
			var b := bf as Node2D
			if absf(b.global_position.x - view.get_center().x) > view.size.x * 0.75 or lights.size() >= 15:
				continue
			var lv: float = bf.light()
			var c: Vector2 = ct * (b.global_position + bf.light_offset())
			lights.append(Vector4(c.x, c.y, float(bf.radius) * zoom, lv))
			if player != null and player.global_position.distance_to(b.global_position + bf.light_offset()) < float(bf.radius) * 0.8 and lv > 0.4:
				dark = false
		if player != null:
			var pp: Vector2 = ct * (player.global_position + Vector2(0.0, -30.0))
			lights.append(Vector4(pp.x, pp.y, 70.0 * zoom, 0.45))
		while lights.size() < 16:
			lights.append(Vector4(0, 0, 1, 0))
		var zones := []
		for zn in get_tree().get_nodes_in_group("dark_zone"):
			if zones.size() >= 3:
				break
			var a: Vector2 = ct * Vector2(float(zn.x0), float(zn.top))
			var b2: Vector2 = ct * Vector2(float(zn.x1), float(zn.top))
			zones.append(Vector4(a.x, b2.x, a.y, 1.0))
		while zones.size() < 3:
			zones.append(Vector4(0, 0, 0, 0))
		Game.player_dark = dark and flash < 0.3
		var m := _rect.material as ShaderMaterial
		m.set_shader_parameter("lights", lights)
		m.set_shader_parameter("zones", zones)
		m.set_shader_parameter("darkness", darkness)
		m.set_shader_parameter("inside_dark", inside_dark)
		m.set_shader_parameter("flash", flash)
		m.set_shader_parameter("vp_size", vp.get_visible_rect().size)


# גשם כבד + מתזמן הברקים (שכבת מסך)
class StormRain extends Node2D:
	var overlay: StormOverlay = null
	var strikes := 0                 # לבדיקות
	var _drops := []
	var _next := 7.0
	var _thunder := -1.0
	var _bolt := PackedVector2Array()
	var _bolt_t := 0.0

	func _ready() -> void:
		for i in 240:
			_drops.append([randf() * 1400.0, randf() * 760.0, randf_range(900.0, 1300.0), randf_range(12.0, 24.0)])

	func strike() -> void:
		strikes += 1
		if overlay != null:
			overlay.flash = 1.0
		_bolt_t = 0.25
		var vs := get_viewport_rect().size
		var x := randf_range(vs.x * 0.1, vs.x * 0.9)
		_bolt = PackedVector2Array([Vector2(x, 0)])
		var y := 0.0
		while y < vs.y * 0.5:
			y += randf_range(20, 45)
			x += randf_range(-28, 28)
			_bolt.append(Vector2(x, y))
		_thunder = randf_range(0.25, 1.1)

	func _process(delta: float) -> void:
		for d in _drops:
			d[1] += d[2] * delta
			d[0] -= d[2] * 0.3 * delta
			if d[1] > 740.0:
				d[1] = -20.0
				d[0] = randf() * 1500.0
		_bolt_t -= delta
		_next -= delta
		if _next <= 0.0:
			_next = randf_range(9.0, 18.0)
			strike()
		if _thunder > 0.0:
			_thunder -= delta
			if _thunder <= 0.0:
				Sfx.play("thunder", null, 2.0, 0.15)
				Game.story.emit("thunder", {})
		queue_redraw()

	func _draw() -> void:
		for d in _drops:
			var p := Vector2(d[0], d[1])
			draw_line(p, p + Vector2(-d[3] * 0.3, d[3]), Color(0.65, 0.75, 0.85, 0.3), 1.0)
		if _bolt_t > 0.0 and _bolt.size() > 1:
			var a := clampf(_bolt_t / 0.25, 0.0, 1.0)
			draw_polyline(_bolt, Color(0.6, 0.7, 1.0, a * 0.5), 6.0)
			draw_polyline(_bolt, Color(0.95, 0.97, 1.0, a), 2.0)


# ============================================================
#  אזור חשוך (בתוך המפעל). StormOverlay קורא את x0..x1 ו-top
# ============================================================
class DarkZone extends Node2D:
	var x0 := 0.0
	var x1 := 100.0
	var top := 0.0

	func _ready() -> void:
		add_to_group("dark_zone")

	func has_point(p: Vector2) -> bool:
		return p.x > x0 and p.x < x1 and p.y > top


# נורה תלויה מהבהבת (מקור אור בתוך המפעל). חלקן מתות
class Bulb extends Node2D:
	var cord := 60.0
	var radius := 230.0
	var dead_bulb := false
	var _t := 0.0
	var _seed := 0.0

	func _ready() -> void:
		add_to_group("s14_lights")
		z_index = -2
		_seed = randf() * 10.0

	func light_offset() -> Vector2:
		return Vector2(sin(_t * 1.1 + _seed) * 4.0, cord + 110.0)   # מרכז האור: מתחת לנורה (בגובה הדמויות)

	func light() -> float:
		if dead_bulb:
			return 0.0
		var f := sin(_t * 13.0 + _seed) + sin(_t * 31.0 + _seed * 2.0)
		return 0.15 if f > 1.3 else 0.85

	func _process(delta: float) -> void:
		_t += delta
		queue_redraw()

	func _draw() -> void:
		var sw := sin(_t * 1.1 + _seed) * 4.0
		var b := Vector2(sw, cord)
		draw_line(Vector2.ZERO, b, Color("1a1a1a"), 1.2)
		draw_colored_polygon(PackedVector2Array([b + Vector2(-9, 2), b + Vector2(9, 2), b + Vector2(4, -3), b + Vector2(-4, -3)]), Color("2a3030"))   # אהיל
		var on := light()
		draw_circle(b + Vector2(0, 4), 3.0, Color(1.0, 0.9, 0.6, 0.35 + on * 0.65) if not dead_bulb else Color("3a3a36"))
		if on > 0.4:
			draw_colored_polygon(PackedVector2Array([b + Vector2(-8, 3), b + Vector2(8, 3), b + Vector2(60, 140), b + Vector2(-60, 140)]), Color(1.0, 0.85, 0.5, 0.05))


# חבית בוערת (אור + חום) - מקור אור בחוץ
class FireBarrel extends Node2D:
	var radius := 140.0
	var _t := 0.0

	func _ready() -> void:
		add_to_group("s14_lights")
		z_index = 1
		var body := StaticBody2D.new()
		body.collision_layer = 1
		var cs := CollisionShape2D.new()
		var sh := RectangleShape2D.new()
		sh.size = Vector2(26, 34)
		cs.shape = sh
		cs.position = Vector2(0, -17)
		body.add_child(cs)
		add_child(body)

	func light_offset() -> Vector2:
		return Vector2(0, -44)

	func light() -> float:
		return 0.8 + 0.15 * sin(_t * 9.0) * sin(_t * 4.3)

	func _process(delta: float) -> void:
		_t += delta
		if Art.on_screen(self, global_position):
			queue_redraw()

	func _draw() -> void:
		Art.fill_shaded(self, PackedVector2Array([Vector2(-13, -34), Vector2(13, -34), Vector2(12, 0), Vector2(-12, 0)]), Color("3a2a22"), 0.2, 0.4, Art.OUTLINE, 1.4)
		for y in [-26.0, -10.0]:
			draw_line(Vector2(-13, y), Vector2(13, y), Color("5a3a2a"), 2.0)
		Kit.fire_glow(self, Vector2(0, -40), _t, 50.0, 7)
		for i in 4:
			var fx := -8.0 + float(i) * 5.5
			var fh := 14.0 + 8.0 * sin(_t * 10.0 + float(i) * 1.9)
			draw_colored_polygon(PackedVector2Array([Vector2(fx - 4, -34), Vector2(fx + 4, -34), Vector2(fx + sin(_t * 8.0 + float(i)) * 3.0, -34 - fh)]), Color(1.0, 0.6, 0.15, 0.9))
			draw_colored_polygon(PackedVector2Array([Vector2(fx - 2, -34), Vector2(fx + 2, -34), Vector2(fx, -34 - fh * 0.6)]), Color(1.0, 0.9, 0.5))


# ============================================================
#  אולם מפעל השימורים (מאחורי הדמויות). הקומה העליונה = platform של השלב
# ============================================================
class CanneryHall extends Node2D:
	var w := 900.0
	var h := 300.0
	var catwalk := 150.0
	var seed_v := 0
	var _t := 0.0
	var _hooks := []

	func _ready() -> void:
		z_index = -4
		var r := S14._rng(seed_v)
		var x := 60.0
		while x < w - 60.0:
			_hooks.append([x, r.randf_range(30.0, 70.0), r.randf() * 6.0, r.randf() < 0.6])
			x += r.randf_range(70.0, 130.0)

	func _process(delta: float) -> void:
		_t += delta
		if Art.on_screen(self, global_position + Vector2(w * 0.5, -h * 0.5), w * 0.6):
			queue_redraw()

	func _draw() -> void:
		var r := S14._rng(seed_v)
		# קיר אחורי: פח גלי ירקרק-חלוד
		draw_rect(Rect2(0, -h, w, h), Color("1a2624"))
		var x := 0.0
		while x < w:
			draw_line(Vector2(x, -h), Vector2(x, 0), Color("223230"), 3.0)
			x += 14.0
		for i in 8:   # כתמי חלודה
			Art.oval(self, Vector2(r.randf_range(20.0, w - 20.0), -r.randf_range(20.0, h - 20.0)), r.randf_range(20.0, 50.0), r.randf_range(10.0, 30.0), Color(0.35, 0.18, 0.08, 0.25), 0.0, Art.NONE)
		# שלט שבור
		var sx := w * 0.5 - 110.0
		draw_rect(Rect2(sx, -h + 30.0, 220.0, 34.0), Color("2a3432"))
		draw_string(ThemeDB.fallback_font, Vector2(sx + 14.0, -h + 56.0), "CONSERVAS  N  RD STE", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(0.75, 0.68, 0.5, 0.6))
		# מדפים עם קופסאות שימורים
		for k in 3:
			var shx := 40.0 + float(k) * (w - 160.0) / 2.0
			for row in 3:
				var y := -40.0 - float(row) * 34.0
				draw_rect(Rect2(shx, y, 120.0, 3.0), Color("3a4240"))
				for c in 9:
					if r.randf() < 0.8:
						draw_rect(Rect2(shx + 4.0 + float(c) * 13.0, y - 12.0, 10.0, 12.0), Color(0.55, 0.55, 0.5) if r.randf() < 0.5 else Color(0.7, 0.3, 0.2))
		# מסוע עם דגים רקובים
		var cy := -catwalk - 40.0
		draw_rect(Rect2(20.0, cy, w - 40.0, 10.0), Color("2a2e2e"))
		var off := fmod(_t * 12.0, 40.0)
		var fx := 20.0 + off
		while fx < w - 40.0:
			Art.oval(self, Vector2(fx, cy - 3.0), 7.0, 2.6, Color("5a6a6a"), 0.0, Art.NONE)
			draw_colored_polygon(PackedVector2Array([Vector2(fx - 7, cy - 3), Vector2(fx - 12, cy - 6), Vector2(fx - 12, cy)]), Color("4a5858"))
			fx += 40.0
		# ווים עם דגים מתנדנדים מהתקרה
		draw_rect(Rect2(0, -h, w, 10.0), Color("101616"))   # קורת תקרה
		for hk in _hooks:
			var hx: float = hk[0]
			var ln: float = hk[1]
			var sw := sin(_t * 1.4 + float(hk[2])) * 0.12
			var end := Vector2(hx, -h + 10.0) + Vector2(0, ln).rotated(sw)
			draw_line(Vector2(hx, -h + 10.0), end, Color("4a4a48"), 1.2)
			draw_arc(end + Vector2(3, 0), 3.0, 0.0, PI, 6, Color("6a6a66"), 1.2)
			if bool(hk[3]):   # דג ענק תלוי
				var fp := end + Vector2(0, 16).rotated(sw)
				Art.oval(self, fp, 5.0, 14.0, Color("4a5a5c"), sw, Art.NONE)
				draw_colored_polygon(PackedVector2Array([fp + Vector2(0, 12).rotated(sw), fp + Vector2(-6, 22).rotated(sw), fp + Vector2(6, 22).rotated(sw)]), Color("3a4a4c"))
		# עמודי פלדה קדמיים
		for i in 3:
			var px := float(i) * (w - 20.0) / 2.0
			draw_rect(Rect2(px, -h, 20.0, h), Color("0e1414"))
			draw_rect(Rect2(px + 3.0, -h, 3.0, h), Color("1c2424"))

	const S14 := preload("res://effects/s14_decor.gd")


# ============================================================
#  בית הקברות של הדייגים (שורה מאחורי הכביש)
# ============================================================
class Cemetery extends Node2D:
	var seed_v := 0
	var skip := []
	var _t := 0.0

	func _ready() -> void:
		z_index = -3

	func _process(delta: float) -> void:
		_t += delta
		if Art.on_screen(self, global_position + Vector2(512, -40), 600.0):
			queue_redraw()

	func _skipped(x: float) -> bool:
		for s in skip:
			if x > float(s[0]) - 40.0 and x < float(s[1]) + 40.0:
				return true
		return false

	func _draw() -> void:
		var r := S14._rng(seed_v)
		var wood := Color("3a3028")
		var stone := Color("4a4c4a")
		# גדר עץ שבורה
		var fxp := 0.0
		while fxp < 1024.0:
			if not _skipped(fxp) and r.randf() < 0.8:
				draw_line(Vector2(fxp, 0), Vector2(fxp + r.randf_range(-2.0, 2.0), -28.0 - r.randf_range(0.0, 8.0)), Color("2a2420"), 3.0)
			fxp += 22.0
		var x := 20.0
		while x < 1004.0:
			if _skipped(x):
				x += 60.0
				continue
			var pick := r.randf()
			if pick < 0.4:
				S14.cross(self, Vector2(x, 0), r.randf_range(50.0, 80.0), wood, r.randf() < 0.6, r.randf_range(-0.15, 0.15))
				if r.randf() < 0.5:   # נר מהבהב
					var fl := 0.6 + 0.4 * sin(_t * 9.0 + x)
					draw_rect(Rect2(x + 6.0, -8.0, 4.0, 8.0), Color("c8c0a0"))
					draw_circle(Vector2(x + 8.0, -10.0), 2.0, Color(1.0, 0.75, 0.3, fl))
					draw_circle(Vector2(x + 8.0, -10.0), 8.0, Color(1.0, 0.6, 0.2, 0.08 * fl))
				x += r.randf_range(50.0, 80.0)
			elif pick < 0.62:
				S14.anchor(self, Vector2(x, 0), r.randf_range(1.0, 1.4), stone)
				x += 60.0
			elif pick < 0.82:
				var hw := r.randf_range(90.0, 130.0)
				S14.upturned_hull(self, Vector2(x, 0), hw, r.randf_range(26.0, 36.0), Color("2a3a40") if r.randf() < 0.5 else Color("4a2a24"), Color(0, 0, 0, 0.4))
				draw_string(ThemeDB.fallback_font, Vector2(x + hw * 0.3, -10.0), ["MARIA", "SAO PEDRO", "ESTRELA", "JANDAIA"][r.randi() % 4], HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.8, 0.78, 0.65, 0.5))
				x += hw + 30.0
			else:   # מצבה עם צדף
				draw_rect(Rect2(x, -34.0, 24.0, 34.0), stone)
				draw_arc(Vector2(x + 12.0, -34.0), 12.0, PI, TAU, 8, stone, 3.0)
				draw_arc(Vector2(x + 12.0, -18.0), 5.0, PI, TAU, 6, Color(0.7, 0.68, 0.6, 0.6), 1.2)
				x += 50.0
			x += r.randf_range(10.0, 40.0)

	const S14 := preload("res://effects/s14_decor.gd")


# ============================================================
#  מכשולים מוצקים על הכביש
# ============================================================
class Obstacle extends Node2D:
	var kind := "hull"
	var size := Vector2(110, 38)
	var seed_v := 0

	func _ready() -> void:
		var body := StaticBody2D.new()
		body.collision_layer = 1
		var cs := CollisionShape2D.new()
		var sh := RectangleShape2D.new()
		sh.size = size
		cs.shape = sh
		cs.position = Vector2(size.x * 0.5, -size.y * 0.5)
		body.add_child(cs)
		add_child(body)

	func _draw() -> void:
		var r := S14._rng(seed_v)
		if kind == "traps":   # ערימת מלכודות לובסטרים
			var n := int(size.x / 34.0)
			for row in 2:
				for i in n - row:
					var p := Vector2(4.0 + float(i) * 34.0 + float(row) * 17.0, -float(row) * (size.y * 0.5))
					var rc := Rect2(p + Vector2(0, -size.y * 0.5), Vector2(32, size.y * 0.5))
					draw_rect(rc, Color("4a3a28"))
					for k in 4:
						draw_line(rc.position + Vector2(float(k) * 8.0 + 4.0, 0), rc.position + Vector2(float(k) * 8.0 + 4.0, rc.size.y), Color("2a2018"), 1.2)
					draw_rect(rc, Art.OUTLINE, false, 1.4)
			if r.randf() < 0.7:   # מצוף כתום
				draw_circle(Vector2(size.x - 10.0, -size.y - 6.0), 7.0, Color("d86a2a"))
		else:   # סירה הפוכה (מוצקה)
			S14.upturned_hull(self, Vector2(0, 0), size.x, size.y, Color("3a4a52") if r.randf() < 0.5 else Color("5a2e26"), Color(0, 0, 0, 0.45))
			draw_polyline(PackedVector2Array([Vector2(0, 0), Vector2(size.x * 0.5, -size.y * 1.12), Vector2(size.x, 0)]), Color(0, 0, 0, 0), 1.0)
			draw_line(Vector2(size.x * 0.1, -2.0), Vector2(size.x * 0.9, -2.0), Art.OUTLINE, 2.0)

	const S14 := preload("res://effects/s14_decor.gd")
