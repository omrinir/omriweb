extends Node2D
# ============================================================
#  פנס רחוב שעובד. אור אמיתי (PointLight2D) שמאיר את הדמויות
#  והכביש מתחתיו, קונוס אור באוויר ועיגול אור על הריצפה.
#  לפעמים הנורה מהבהבת.
#  (0,0) = בסיס העמוד על הכביש.
# ============================================================

var height := 200.0                      # גובה הנורה
var light_color := Color(1.0, 0.82, 0.5)
var energy := 1.7                        # עוצמת האור על הדמויות
var cone_w := 120.0                      # חצי רוחב הקונוס בריצפה

static var _tex: Texture2D               # טקסטורת האור (נבנית פעם אחת)

var _light: PointLight2D
var _cone: Node2D
var _time := 0.0
var _flicker := 0.0                      # > 0 = מהבהב עכשיו
var _next_flicker := 0.0
var _on := 1.0
var _arm := 1.0                          # לאיזה צד הזרוע (1 / -1)


func _ready() -> void:
	z_index = -1
	_arm = 1.0 if randf() < 0.5 else -1.0
	_next_flicker = randf_range(3.0, 10.0)
	var head := Vector2(_arm * 26.0, -height)
	_light = PointLight2D.new()
	_light.texture = _light_texture()
	_light.texture_scale = (height + 60.0) / 128.0
	_light.offset = Vector2(0.0, 64.0)       # קודקוד הקונוס על הנורה
	_light.position = head
	_light.color = light_color
	_light.energy = energy
	_light.blend_mode = Light2D.BLEND_MODE_ADD
	add_child(_light)
	# קונוס אור באוויר (מעל הדמויות, חיבורי)
	_cone = ConeFx.new()
	_cone.lamp = self
	_cone.position = head
	_cone.z_index = 11
	_cone.z_as_relative = false
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	mat.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	_cone.material = mat
	add_child(_cone)


# טקסטורה של קונוס: בהיר למעלה במרכז, נחלש למטה ולצדדים
static func _light_texture() -> Texture2D:
	if _tex != null:
		return _tex
	var n := 128
	var img := Image.create(n, n, false, Image.FORMAT_RGBA8)
	for y in n:
		var fy := float(y) / float(n - 1)
		var half := 0.06 + 0.44 * fy                     # רוחב הקונוס בשורה הזו
		for x in n:
			var fx := absf(float(x) / float(n - 1) - 0.5)
			var side := clampf(1.0 - (fx - half * 0.55) / (half * 0.45), 0.0, 1.0)
			var v := side * side * (1.0 - fy * 0.55) * clampf(fy * 12.0, 0.0, 1.0)
			img.set_pixel(x, y, Color(v, v, v, 1.0))
	_tex = ImageTexture.create_from_image(img)
	return _tex


func _process(delta: float) -> void:
	var vp := get_viewport()
	var view := (vp.get_canvas_transform().affine_inverse() * vp.get_visible_rect()).grow(300.0)
	var vis := view.has_point(global_position)
	_light.enabled = vis
	if not vis:
		return
	_time += delta
	_next_flicker -= delta
	if _next_flicker <= 0.0:
		_flicker = randf_range(0.3, 0.9)
		_next_flicker = randf_range(5.0, 14.0)
	if _flicker > 0.0:
		_flicker -= delta
		_on = 0.15 if sin(_time * 55.0) + sin(_time * 23.0) > 0.4 else 1.0
	else:
		_on = 1.0
	_light.energy = energy * _on * (0.96 + 0.04 * sin(_time * 3.0))
	queue_redraw()
	_cone.queue_redraw()


func _draw() -> void:
	var head := Vector2(_arm * 26.0, -height)
	var metal := Color("2a2a30")
	# עמוד + זרוע
	draw_rect(Rect2(-5.0, -10.0, 10.0, 10.0), Color("1e1e22"))
	draw_line(Vector2(0.0, -4.0), Vector2(0.0, -height + 12.0), metal, 4.0)
	draw_line(Vector2(1.2, -4.0), Vector2(1.2, -height + 12.0), Color(1, 1, 1, 0.08), 1.0)
	draw_polyline(PackedVector2Array([Vector2(0.0, -height + 12.0), Vector2(_arm * 6.0, -height - 2.0), head + Vector2(-_arm * 6.0, -6.0), head + Vector2(0.0, -6.0)]), metal, 3.0, true)
	# ראש הפנס
	draw_colored_polygon(PackedVector2Array([head + Vector2(-11.0, -2.0), head + Vector2(-7.0, -8.0), head + Vector2(7.0, -8.0), head + Vector2(11.0, -2.0)]), Color("34343a"))
	var bulb := light_color.lerp(Color.WHITE, 0.5) if _on > 0.5 else Color("4a4436")
	draw_rect(Rect2(head + Vector2(-8.0, -2.0), Vector2(16.0, 3.0)), bulb)


# קונוס אור באוויר + עיגול אור על הריצפה (מצויר חיבורי, מעל הכל)
class ConeFx extends Node2D:
	var lamp: Node2D

	func _draw() -> void:
		var k: float = lamp._on
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
			draw_circle(Vector2.ZERO, r, Color(c.r, c.g, c.b, 0.06 * k))
		draw_set_transform_matrix(Transform2D.IDENTITY)
		# הילה סביב הנורה
		for i in 3:
			draw_circle(Vector2(0.0, 0.0), 6.0 + float(i) * 6.0, Color(c.r, c.g, c.b, 0.12 * k / float(i + 1)))
