extends Node2D
# ============================================================
#  פנס רחוב שעובד.
#  * דמות (שחקן / זומבי / ניצולה) שעוברת מתחתיו מוארת - והצד שלה
#    שפונה אל הנורה מואר הרבה יותר מהצד השני (shader על הדמות).
#  * קונוס אור באוויר ועיגול אור על הכביש.
#  * לפעמים הנורה מהבהבת.
#  * יורים על הנורה = זיקוק קטן והפנס כבה.
#  (0,0) = בסיס העמוד על הכביש.
# ============================================================

var height := 200.0                      # גובה הנורה
var light_color := Color(1.0, 0.82, 0.5)
var strength := 1.0                      # עוצמת האור על הדמויות
var cone_w := 120.0                      # חצי רוחב הקונוס בריצפה
var reach := 150.0                       # עד כמה רחוק (לצדדים) הדמויות עוד מקבלות אור
var ceiling := false                     # מנורת תקרה (רכבת תחתית): תלויה על כבל, בלי עמוד

const SHADER_CODE := """
shader_type canvas_item;
uniform vec2 light_pos;      // מיקום הנורה (בפיקסלים על המסך)
uniform vec2 center;         // מרכז הגוף של הדמות (בפיקסלים על המסך)
uniform vec2 vp_size = vec2(1280.0, 720.0);
uniform float px = 1.0;      // זום המצלמה
uniform float amount = 0.0;  // כמה אור מגיע לדמות
uniform vec4 light_col : source_color = vec4(1.0, 0.82, 0.5, 1.0);
void fragment() {
	vec4 c = COLOR;
	if (amount > 0.001) {
		vec2 d = light_pos - center;
		vec2 to_l = normalize(vec2(d.x * 2.5, d.y));   // מדגישים את הצד (לא רק למעלה)
		vec2 off = (SCREEN_UV * vp_size - center) / px;
		// הצד שפונה אל הנורה: 1, הצד השני: 0
		float side = clamp(dot(off, to_l) / 16.0 * 0.5 + 0.5, 0.0, 1.0);
		side = side * side * (3.0 - 2.0 * side);
		float k = amount * (0.08 + 0.92 * side);
		c.rgb += (c.rgb * 1.8 + vec3(0.16)) * light_col.rgb * k;
	}
	COLOR = c;
}
"""
static var _shader: Shader

var _time := 0.0
var _flicker := 0.0                      # > 0 = מהבהב עכשיו
var _next_flicker := 0.0
var _on := 1.0
var _arm := 1.0                          # לאיזה צד הזרוע (1 / -1)
var _broken := false
var _sparks := []                        # [מיקום, מהירות, חיים]
var _lit := {}                           # דמויות שהארנו בפריים הקודם
var _cone: Node2D


func _ready() -> void:
	add_to_group("lamps")
	z_index = -1
	_arm = 1.0 if randf() < 0.5 else -1.0
	if ceiling:
		_arm = 0.0
	_next_flicker = randf_range(3.0, 10.0)
	_cone = ConeFx.new()
	_cone.lamp = self
	_cone.position = head()
	_cone.z_index = 11
	_cone.z_as_relative = false
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	_cone.material = mat
	add_child(_cone)


func head() -> Vector2:
	return Vector2(_arm * 26.0, -height)


# נקרא מ-bullet.gd: האם הקליע פגע בנורה
func hit_test(from: Vector2, to: Vector2) -> bool:
	if _broken:
		return false
	var c := global_position + head()
	var p := Geometry2D.get_closest_point_to_segment(c, from, to)
	return absf(p.x - c.x) < 13.0 and absf(p.y - c.y) < 8.0


func shatter(dir: Vector2) -> void:
	_broken = true
	_on = 0.0
	for i in 26:   # ניצוצות וזכוכית
		var a := randf_range(0.0, TAU)
		var v := Vector2.from_angle(a) * randf_range(60.0, 260.0) + dir * 80.0 + Vector2(0.0, -60.0)
		_sparks.append([head() + Vector2(randf_range(-6, 6), 0.0), v, randf_range(0.4, 1.1), randf() < 0.75])
	_set_lights(false)


static func _get_shader() -> Shader:
	if _shader == null:
		_shader = Shader.new()
		_shader.code = SHADER_CODE
	return _shader


func _set_lights(vis: bool) -> void:
	var now := {}
	if vis and _on > 0.0:
		var hp := global_position + head()
		var ct := get_viewport().get_canvas_transform()
		var vsize := get_viewport().get_visible_rect().size
		var tree := get_tree()
		for b in tree.get_nodes_in_group("player") + tree.get_nodes_in_group("zombies") + tree.get_nodes_in_group("survivors"):
			var dx: float = absf(b.global_position.x - hp.x)
			if dx > reach or absf(b.global_position.y - global_position.y) > 160.0:
				continue
			if not (b.material is ShaderMaterial):
				var m := ShaderMaterial.new()
				m.shader = _get_shader()
				b.material = m
			var sc: float = b.get("sc") if b.get("sc") != null else 1.0
			var amt := strength * _on * (1.0 - dx / reach)
			b.material.set_shader_parameter("light_pos", ct * hp)
			b.material.set_shader_parameter("center", ct * (b.global_position + Vector2(0.0, -30.0 * sc)))
			b.material.set_shader_parameter("vp_size", vsize)
			b.material.set_shader_parameter("px", ct.get_scale().x)
			b.material.set_shader_parameter("amount", amt)
			b.material.set_shader_parameter("light_col", light_color)
			now[b] = true
	for b in _lit:   # דמויות שיצאו מהאור
		if not now.has(b) and is_instance_valid(b) and b.material is ShaderMaterial:
			b.material.set_shader_parameter("amount", 0.0)
	_lit = now


func _process(delta: float) -> void:
	var vp := get_viewport()
	var view := (vp.get_canvas_transform().affine_inverse() * vp.get_visible_rect()).grow(300.0)
	var vis := view.has_point(global_position)
	if not vis:
		if not _lit.is_empty():
			_set_lights(false)
		return
	_time += delta
	if not _broken:
		_next_flicker -= delta
		if _next_flicker <= 0.0:
			_flicker = randf_range(0.3, 0.9)
			_next_flicker = randf_range(5.0, 14.0)
		if _flicker > 0.0:
			_flicker -= delta
			_on = 0.15 if sin(_time * 55.0) + sin(_time * 23.0) > 0.4 else 1.0
		else:
			_on = 0.96 + 0.04 * sin(_time * 3.0)
		_set_lights(true)
	for s in _sparks:
		s[1].y += 700.0 * delta
		s[0] += s[1] * delta
		s[2] -= delta
		if s[0].y > -2.0:   # נחת על הכביש
			s[0].y = -2.0
			s[1] = Vector2(s[1].x * 0.4, -absf(s[1].y) * 0.25)
	_sparks = _sparks.filter(func(s): return s[2] > 0.0)
	queue_redraw()
	_cone.queue_redraw()


func _draw() -> void:
	var hd := head()
	var metal := Color("2a2a30")
	if ceiling:   # כבל מהתקרה + מנורת פלורסנט
		draw_line(hd + Vector2(-8.0, -36.0), hd + Vector2(-8.0, -7.0), Color("2a2a30"), 1.2)
		draw_line(hd + Vector2(8.0, -36.0), hd + Vector2(8.0, -7.0), Color("2a2a30"), 1.2)
		draw_rect(Rect2(hd + Vector2(-16.0, -8.0), Vector2(32.0, 6.0)), Color("34343a"))
	else:
		_draw_pole(hd, metal)
	if _broken:   # נורה שבורה: שאריות זכוכית
		draw_colored_polygon(PackedVector2Array([hd + Vector2(-8.0, -2.0), hd + Vector2(-5.0, 2.0), hd + Vector2(-2.0, -1.0), hd + Vector2(2.0, 1.5), hd + Vector2(5.0, -1.0), hd + Vector2(8.0, -2.0)]), Color("3a3830"))
	else:
		var bulb := light_color.lerp(Color.WHITE, 0.5) if _on > 0.5 else Color("4a4436")
		draw_rect(Rect2(hd + Vector2(-8.0, -2.0), Vector2(16.0, 3.0)), bulb)
	# ניצוצות (צהוב-לבן) ושברי זכוכית (תכלת)
	for s in _sparks:
		var a: float = clampf(s[2] * 2.0, 0.0, 1.0)
		if s[3]:
			draw_line(s[0], s[0] - s[1] * 0.025, Color(1.0, 0.85, 0.4, a), 1.5, true)
		else:
			draw_rect(Rect2(s[0], Vector2(2, 2)), Color(0.75, 0.85, 0.9, a))


func _draw_pole(hd: Vector2, metal: Color) -> void:
	# עמוד + זרוע
	draw_rect(Rect2(-5.0, -10.0, 10.0, 10.0), Color("1e1e22"))
	draw_line(Vector2(0.0, -4.0), Vector2(0.0, -height + 12.0), metal, 4.0)
	draw_line(Vector2(1.2, -4.0), Vector2(1.2, -height + 12.0), Color(1, 1, 1, 0.08), 1.0)
	draw_polyline(PackedVector2Array([Vector2(0.0, -height + 12.0), Vector2(_arm * 6.0, -height - 2.0), hd + Vector2(-_arm * 6.0, -6.0), hd + Vector2(0.0, -6.0)]), metal, 3.0, true)
	# ראש הפנס
	draw_colored_polygon(PackedVector2Array([hd + Vector2(-11.0, -2.0), hd + Vector2(-7.0, -8.0), hd + Vector2(7.0, -8.0), hd + Vector2(11.0, -2.0)]), Color("34343a"))


# קונוס אור באוויר + עיגול אור על הריצפה (מצויר חיבורי, מעל הכל)
class ConeFx extends Node2D:
	var lamp: Node2D

	func _draw() -> void:
		var k: float = lamp._on
		if lamp._broken:
			# הבזק קצר ברגע השבירה
			if not lamp._sparks.is_empty():
				draw_circle(Vector2.ZERO, 18.0, Color(1.0, 0.9, 0.6, 0.25 * clampf(lamp._sparks[0][2], 0.0, 1.0)))
			return
		var h: float = lamp.height
		var w: float = lamp.cone_w
		var c: Color = lamp.light_color
		var top := Color(c.r, c.g, c.b, 0.16 * k)
		var bot := Color(c.r, c.g, c.b, 0.0)
		draw_polygon(PackedVector2Array([Vector2(-7.0, 1.0), Vector2(7.0, 1.0), Vector2(w, h), Vector2(-w, h)]),
			PackedColorArray([top, top, bot, bot]))
		# עיגול אור על הכביש
		draw_set_transform(Vector2(0.0, h + 2.0), 0.0, Vector2(1.0, 0.12))
		for i in 4:
			var r := w * (1.0 - float(i) * 0.22)
			draw_circle(Vector2.ZERO, r, Color(c.r, c.g, c.b, 0.07 * k))
		draw_set_transform_matrix(Transform2D.IDENTITY)
		# הילה סביב הנורה
		for i in 3:
			draw_circle(Vector2.ZERO, 6.0 + float(i) * 6.0, Color(c.r, c.g, c.b, 0.12 * k / float(i + 1)))
