extends Node2D
# ============================================================
#  ערפל אפור-בהיר חי (שלבים 2 ו-4) - במקום הערפל הרגיל (main.gd, MIST_LEVELS קובע גם את העובי בכל שלב).
#  * שחקן וזומבים שזזים "חותכים" את הערפל: הוא נדחף קדימה בכיוון התנועה, מסתחרר בצדדים,
#    נפתח שובל מאחוריהם, ואחרי ~3 שניות הערפל חוזר וסוגר אותו. פיצוץ דוחף את הערפל החוצה בטבעת,
#    יריות מעיפות אותו מהקנה, ונחיתה מקפיצה מרימה אותו מהריצפה.
#  * הכל בשיידר אחד על מלבן אחד, שמצויר בחצי רזולוציה (SubViewport) ומתוח למסך - הערפל רך, אז לא רואים
#    הבדל, ועבודת הציור יורדת פי 4. המעבד רק מעדכן רשימה של עד MAX_PTS נקודות
#    (מיקום, מהירות, עוצמה) - שובל של נקודות שנזרקות מאחורי מי שזז ודועכות.
#  * המשחק איטי (Quality.level >= 2): חצי נקודות ושכבת רעש אחת פחות.
#  לשנות: COLOR / COLOR2 / STRENGTH (מראה), HEIGHT (גובה), LIFE (כמה זמן השובל נשאר),
#         PLAYER_EVERY / ZOMBIE_EVERY (כל כמה שניות נזרקת נקודה), RADIUS (רוחב השובל).
#  בדיקה: devtools/t_mist.gd (מהירות עם/בלי, וצילומי מסך).
# ============================================================

const MAX_PTS := 48
const LIFE := 3.0               # שניות עד שהשובל נסגר
const PLAYER_EVERY := 0.05
const ZOMBIE_EVERY := 0.12
const SHOT_EVERY := 0.1          # פאף מהקנה, לא יותר מפעם ב-0.1 שנייה (מקלע)
const MIN_SPEED := 18.0         # פיקסלי עולם לשנייה: מתחת לזה לא נחשב תנועה
const RADIUS := 42.0            # רוחב השובל (פיקסלי עולם)
const HEIGHT := 260.0           # גובה הערפל מעל הריצפה (פיקסלי מסך)
const COLOR := Color(0.88, 0.90, 0.92)
const COLOR2 := Color(0.70, 0.73, 0.77)
const STRENGTH := 0.42

var y_screen := 600.0           # הריצפה על המסך (main.gd קובע)
var zoom := 1.0                 # זום המצלמה (main.gd קובע)
var thick := 1.0                # עובי (main.gd, MIST_LEVELS): 1 = שלב 2, פחות בשלב 4
var _t := 0.0
var _rect: ColorRect
var _vp: SubViewport
var _origin := Vector2.ZERO     # הפינה של הערפל על המסך
var _pts := []                  # [world_pos, world_vel, life, amp]
var _last := {}                 # instance_id -> [world_pos, time_since_drop]
var _n := MAX_PTS
var _shot_t := 0.0
var _flash_was := 0.0
var _fall_v := 0.0
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
float fbm2(vec2 p) { return 0.5 * noise(p) + 0.25 * noise(p * 2.03) + 0.125; }
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
		disp -= vel[i] * f * 0.5;                        // נדחף בכיוון התנועה
		disp += vec2(-d.y, d.x) * f * 0.7;               // מסתחרר סביב הגוף
		clear = max(clear, f);
		float ring = sqrt(q) - 1.6;
		pile += amt[i] * exp(-ring * ring * 1.5) * 0.18; // נערם בשולי השובל
	}
	// קואורדינטות עולם, כדי שהערפל יישאר במקום כשהמצלמה זזה
	vec2 w = vec2(cam_x + (px.x - rect_size.x * 0.5) / zoom, px.y / zoom) + disp / zoom;
	// רצועות ארוכות ורכות שזזות לאט (ערפל, לא עשן)
	vec2 p = vec2(w.x / 230.0 + t * 0.045, w.y / 38.0 - t * 0.015);
	float n = fbm(p + vec2(fbm2(p * 0.5 + vec2(t * 0.03, t * 0.012)) * 1.8, 0.0));
	float wisp = fbm2(vec2(w.x / 90.0 - t * 0.08, w.y / 22.0));
	float h = 1.0 - UV.y;                                // 0 בריצפה, 1 למעלה
	float prof = (1.0 - smoothstep(0.0, 0.55, h)) + 0.45 * (1.0 - smoothstep(0.3, 1.0, h)) * smoothstep(0.5, 0.8, wisp);
	prof *= smoothstep(0.0, 0.07, UV.y) * (1.0 - smoothstep(0.92, 1.0, UV.y));
	float dens = smoothstep(0.2, 0.85, n * 0.75 + wisp * 0.35) * prof;
	dens = dens * (1.0 - 0.9 * clamp(clear, 0.0, 1.0)) + pile * prof;
	vec3 c = mix(col2.rgb, col.rgb, smoothstep(0.3, 0.8, n));
	COLOR = vec4(c, clamp(strength * dens, 0.0, 0.8));
}
"""


func _ready() -> void:
	add_to_group("toxic_mist")
	var s := get_viewport_rect().size
	_rect = ColorRect.new()
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var hh := HEIGHT * zoom * lerpf(0.7, 1.0, thick)   # ערפל דק = גם נמוך יותר
	_origin = Vector2(0.0, y_screen - hh + 14.0)
	_vp = SubViewport.new()   # חצי רזולוציה
	_vp.size = Vector2i(int(ceil(s.x * 0.5)), int(ceil(hh * 0.5)))
	_vp.transparent_bg = true
	_vp.disable_3d = true
	_vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_rect.size = Vector2(_vp.size)
	var m := ShaderMaterial.new()
	m.shader = Shader.new()
	m.shader.code = SHADER
	m.set_shader_parameter("col", COLOR)
	m.set_shader_parameter("col2", COLOR2)
	m.set_shader_parameter("strength", STRENGTH * thick)
	m.set_shader_parameter("rect_size", Vector2(s.x, hh))   # החישובים בפיקסלים של המסך
	m.set_shader_parameter("zoom", zoom)
	m.set_shader_parameter("radius", RADIUS)
	_rect.material = m
	_vp.add_child(_rect)
	add_child(_vp)
	var tr := TextureRect.new()
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tr.texture = _vp.get_texture()
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_SCALE
	tr.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	tr.position = _origin
	tr.size = Vector2(s.x, hh)
	var pm := CanvasItemMaterial.new()
	pm.blend_mode = CanvasItemMaterial.BLEND_MODE_PREMULT_ALPHA   # הצבע בטקסטורה כבר מוכפל באלפא
	tr.material = pm
	add_child(tr)
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


# יריות (פאף מהקנה בכיוון הכוונה) ונחיתה מקפיצה (טבעת על הריצפה)
func _player_fx(pl: Node2D, delta: float) -> void:
	_shot_t -= delta
	var fl: float = pl.get("_muzzle_flash") if pl.get("_muzzle_flash") != null else 0.0
	if fl > _flash_was and _shot_t <= 0.0:
		_shot_t = SHOT_EVERY
		var aim: Vector2 = pl.get("_aim") if pl.get("_aim") != null else Vector2.RIGHT
		var sh: Vector2 = pl.global_position + pl._front_shoulder()
		_add(sh + aim * 46.0, aim * 520.0, 0.9)
	_flash_was = fl
	var vy: float = pl.velocity.y
	if pl.is_on_floor():
		if _fall_v > 380.0:
			for i in 6:
				var a := PI + PI * float(i) / 5.0
				var dir := Vector2(cos(a), sin(a) * 0.3)
				_add(pl.global_position + Vector2(dir.x * 18.0, -8.0), dir * minf(_fall_v, 900.0) * 0.6, 1.0)
		_fall_v = 0.0
	else:
		_fall_v = maxf(_fall_v, vy)


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
		_player_fx(pl, delta)
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
			_pos[cnt] = xf * p[0] - _origin
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
