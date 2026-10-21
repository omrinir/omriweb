extends Node2D
# ============================================================
#  ערפל ירוק רעיל (שלב 2, המטרו) - במקום הערפל האפור הרגיל (main.gd, MIST_LEVELS).
#  * שחקן וזומבים שזזים "חותכים" את הערפל: הוא נדחף קדימה בכיוון התנועה, מסתחרר בצדדים,
#    נפתח שובל מאחוריהם, ואחרי ~2 שניות הערפל חוזר וסוגר אותו. פיצוץ דוחף את הערפל החוצה בטבעת.
#  * הכל בשיידר אחד על מלבן אחד (ציור אחד בפריים). המעבד רק מעדכן רשימה של עד MAX_PTS נקודות
#    (מיקום, מהירות, עוצמה) - שובל של נקודות שנזרקות מאחורי מי שזז ודועכות.
#  * המשחק איטי (Quality.level >= 2): חצי נקודות ושכבת רעש אחת פחות.
#  לשנות: COLOR / COLOR2 / STRENGTH (מראה), HEIGHT (גובה), LIFE (כמה זמן השובל נשאר),
#         PLAYER_EVERY / ZOMBIE_EVERY (כל כמה שניות נזרקת נקודה), RADIUS (רוחב השובל).
#  בדיקה: devtools/t_mist.gd (מהירות עם/בלי, וצילומי מסך).
# ============================================================

const MAX_PTS := 48
const LIFE := 2.2               # שניות עד שהשובל נסגר
const PLAYER_EVERY := 0.05
const ZOMBIE_EVERY := 0.16
const MIN_SPEED := 18.0         # פיקסלי עולם לשנייה: מתחת לזה לא נחשב תנועה
const RADIUS := 34.0            # רוחב השובל (פיקסלי עולם)
const HEIGHT := 230.0           # גובה הערפל מעל הריצפה (פיקסלי מסך)
const COLOR := Color(0.42, 0.95, 0.30)
const COLOR2 := Color(0.70, 0.95, 0.18)
const STRENGTH := 0.36

var y_screen := 600.0           # הריצפה על המסך (main.gd קובע)
var zoom := 1.0                 # זום המצלמה (main.gd קובע)
var _t := 0.0
var _rect: ColorRect
var _pts := []                  # [world_pos, world_vel, life, amp]
var _last := {}                 # instance_id -> [world_pos, time_since_drop]
var _n := MAX_PTS
var _pos := PackedVector2Array()
var _vel := PackedVector2Array()
var _amt := PackedFloat32Array()
static var cpu_us := 0          # זמן מעבד מצטבר של _process (לבדיקות: devtools/t_mist.gd)

const SHADER := """
shader_type canvas_item;
const int N = 48;
uniform float t;
uniform float cam_x;
uniform float zoom = 1.0;
uniform vec2 rect_size = vec2(1280.0, 260.0);
uniform vec4 col : source_color;
uniform vec4 col2 : source_color;
uniform float strength = 0.36;
uniform float radius = 34.0;
uniform int count = 0;
uniform int octaves = 4;
uniform vec2 pos[N];
uniform vec2 vel[N];
uniform float amt[N];
float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float noise(vec2 p) {
	vec2 i = floor(p); vec2 f = fract(p); f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x), f.y);
}
float fbm(vec2 p) {
	float v = 0.0; float a = 0.5;
	for (int i = 0; i < 4; i++) { if (i >= octaves) break; v += a * noise(p); p *= 2.03; a *= 0.5; }
	return v;
}
void fragment() {
	vec2 px = UV * rect_size;
	vec2 disp = vec2(0.0);
	float clear = 0.0;
	float pile = 0.0;
	float r = radius * zoom;
	for (int i = 0; i < N; i++) {
		if (i >= count) break;
		vec2 d = px - pos[i];
		float q = dot(d, d) / (r * r);
		if (q > 9.0) continue;
		float f = amt[i] * exp(-q);
		disp -= vel[i] * f * 0.32;                       // נדחף בכיוון התנועה
		disp += vec2(-d.y, d.x) * f * 0.55;              // מסתחרר סביב הגוף
		clear = max(clear, f);
		float ring = sqrt(q) - 1.7;
		pile += amt[i] * exp(-ring * ring * 1.5) * 0.18; // נערם בשולי השובל
	}
	// קואורדינטות עולם, כדי שהערפל יישאר במקום כשהמצלמה זזה
	vec2 w = vec2(cam_x + (px.x - rect_size.x * 0.5) / zoom, px.y / zoom) + disp / zoom;
	vec2 p = vec2(w.x / 170.0 + t * 0.05, w.y / 48.0 - t * 0.02);
	float n = fbm(p + vec2(fbm(p * 0.55 + vec2(t * 0.035, t * 0.01)) * 1.6, 0.0));
	float h = 1.0 - UV.y;                                // 0 בריצפה, 1 למעלה
	float prof = (1.0 - smoothstep(0.0, 0.62, h)) + 0.35 * (1.0 - smoothstep(0.35, 1.0, h)) * smoothstep(0.55, 0.85, n);
	prof *= smoothstep(0.0, 0.07, UV.y) * (1.0 - smoothstep(0.93, 1.0, UV.y));
	float dens = smoothstep(0.28, 0.82, n) * prof;
	dens = dens * (1.0 - 0.85 * clamp(clear, 0.0, 1.0)) + pile * prof;
	float glow = smoothstep(0.55, 0.95, n);
	vec3 c = mix(col.rgb, col2.rgb, smoothstep(0.35, 0.75, fbm(p * 0.4 + 7.0)));
	COLOR = vec4(c * (0.8 + 0.5 * glow), clamp(strength * dens, 0.0, 0.85));
}
"""


func _ready() -> void:
	add_to_group("toxic_mist")
	var s := get_viewport_rect().size
	_rect = ColorRect.new()
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rect.position = Vector2(0.0, y_screen - HEIGHT * zoom + 14.0)
	_rect.size = Vector2(s.x, HEIGHT * zoom)
	var m := ShaderMaterial.new()
	m.shader = Shader.new()
	m.shader.code = SHADER
	m.set_shader_parameter("col", COLOR)
	m.set_shader_parameter("col2", COLOR2)
	m.set_shader_parameter("strength", STRENGTH)
	m.set_shader_parameter("rect_size", _rect.size)
	m.set_shader_parameter("zoom", zoom)
	m.set_shader_parameter("radius", RADIUS)
	_rect.material = m
	add_child(_rect)
	_pos.resize(MAX_PTS)
	_vel.resize(MAX_PTS)
	_amt.resize(MAX_PTS)


# פיצוץ (explosion.gd): טבעת נקודות שדוחפות את הערפל החוצה
static func poke(tree: SceneTree, world: Vector2, radius: float) -> void:
	for m in tree.get_nodes_in_group("toxic_mist"):
		for i in 8:
			var a := TAU * float(i) / 8.0
			var dir := Vector2(cos(a), sin(a) * 0.4)
			m._add(world + dir * radius * 0.35, dir * radius * 3.5, 1.6)


func _add(world: Vector2, vel: Vector2, amp: float) -> void:
	_pts.append([world, vel, LIFE, amp])
	while _pts.size() > _n:
		_pts.pop_front()


func _track(node: Node2D, every: float, amp: float, delta: float) -> void:
	var id := node.get_instance_id()
	var gp := node.global_position + Vector2(0.0, -18.0)
	var rec = _last.get(id)
	if rec == null:
		_last[id] = [gp, 0.0, gp]
		return
	rec[1] += delta
	if rec[1] < every:
		return
	var v: Vector2 = (gp - rec[2]) / rec[1]
	rec[1] = 0.0
	rec[2] = gp
	if v.length() >= MIN_SPEED:
		_add(gp, v.limit_length(700.0), amp)


func _process(delta: float) -> void:
	var t0 := Time.get_ticks_usec()
	_t += delta
	_n = MAX_PTS if Quality.level < 2 else 24
	var tree := get_tree()
	var cam := get_viewport().get_camera_2d()
	var cx: float = cam.get_screen_center_position().x if cam != null else 0.0
	var half: float = get_viewport_rect().size.x * 0.5 / zoom + 120.0
	var pl = tree.get_first_node_in_group("player")
	if pl != null:
		_track(pl, PLAYER_EVERY, 1.0, delta)
	for z in tree.get_nodes_in_group("zombies"):
		if absf(z.global_position.x - cx) < half and not z.get("dead"):
			_track(z, ZOMBIE_EVERY, 0.8, delta)
	if _last.size() > 200:   # זומבים שמתו / נמחקו
		_last.clear()
	# דעיכה + המרה לקואורדינטות של המלבן
	var xf := get_viewport().get_canvas_transform()
	var cnt := 0
	var i := 0
	while i < _pts.size():
		var p: Array = _pts[i]
		p[2] -= delta
		if p[2] <= 0.0:
			_pts.remove_at(i)
			continue
		p[1] *= 1.0 - minf(1.0, 1.4 * delta)
		if cnt < _n:
			var k: float = p[2] / LIFE
			_pos[cnt] = xf * p[0] - _rect.position
			_vel[cnt] = p[1] * zoom
			_amt[cnt] = p[3] * k * k * (3.0 - 2.0 * k)
			cnt += 1
		i += 1
	var m: ShaderMaterial = _rect.material
	m.set_shader_parameter("t", _t)
	m.set_shader_parameter("cam_x", cx)
	m.set_shader_parameter("count", cnt)
	m.set_shader_parameter("octaves", 4 if Quality.level < 2 else 3)
	m.set_shader_parameter("pos", _pos)
	m.set_shader_parameter("vel", _vel)
	m.set_shader_parameter("amt", _amt)
	cpu_us += Time.get_ticks_usec() - t0
