extends Node2D
# ============================================================
#  ערפל נמוך שזז לאט על הכביש (מצויר מעל העולם, מתחת ל-HUD).
# ============================================================

@export var color := Color(0.75, 0.68, 0.62)
@export var strength := 0.09
var y_screen := 600.0   # גובה הערפל על המסך (main.gd קובע)
var _t := 0.0
var _blobs := []


# ערפל רך: רעש (noise) שזז לאט, בלי צורות עם קצוות
const FOG_SHADER := """
shader_type canvas_item;
uniform float t;
uniform float cam_x;
uniform vec2 rect_size = vec2(1280.0, 200.0);
uniform vec4 col : source_color;
uniform float strength = 0.3;
float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float noise(vec2 p) {
	vec2 i = floor(p); vec2 f = fract(p); f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x), f.y);
}
float fbm(vec2 p) {
	float v = 0.0; float a = 0.5;
	for (int i = 0; i < 4; i++) { v += a * noise(p); p *= 2.03; a *= 0.5; }
	return v;
}
void fragment() {
	vec2 w = vec2(UV.x * rect_size.x + cam_x * 1.15, UV.y * rect_size.y);
	vec2 p = vec2(w.x / 240.0 + t * 0.04, w.y / 60.0);
	float n = fbm(p + vec2(fbm(p * 0.6 + vec2(t * 0.03, 0.0)) * 1.5, 0.0));
	float prof = smoothstep(0.0, 0.7, UV.y) * (1.0 - smoothstep(0.88, 1.0, UV.y));
	COLOR = vec4(col.rgb, strength * prof * smoothstep(0.3, 0.85, n));
}
"""
var _rect: ColorRect


func _ready() -> void:
	var s := get_viewport_rect().size
	_rect = ColorRect.new()
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rect.position = Vector2(0.0, y_screen - 130.0)
	_rect.size = Vector2(s.x, 170.0)
	var m := ShaderMaterial.new()
	m.shader = Shader.new()
	m.shader.code = FOG_SHADER
	m.set_shader_parameter("col", color)
	m.set_shader_parameter("strength", strength * 3.2)
	m.set_shader_parameter("rect_size", _rect.size)
	_rect.material = m
	add_child(_rect)


func _process(delta: float) -> void:
	_t += delta
	var cam := get_viewport().get_camera_2d()
	var m: ShaderMaterial = _rect.material
	m.set_shader_parameter("t", _t)
	m.set_shader_parameter("cam_x", cam.get_screen_center_position().x if cam != null else 0.0)
