extends Node2D
const DrawBatch := preload("res://effects/draw_batch.gd")
const Debris := preload("res://effects/boom_debris.gd")
# ============================================================
#  אפקט הפיצוץ (explosion.gd -> Boom.Explosion): 3 סגנונות שמתחלפים באקראי (אף פעם לא אותו סגנון פעמיים ברצף).
#   0 כדור אש  - כדור אש גדול ומתגלגל, ניצוצות, גחלים ועמוד עשן שעולה.
#   1 רסיסים   - הבזק חד וגל הדף, מטר ניצוצות מהירים, גושי אדמה שעפים וענן אבק שמתפשט על הריצפה.
#   2 עמוד אש  - עמוד אש שעולה למעלה עם "כובע" פטרייה, טבעת אבק על הריצפה וגחלים שנופלים.
#  * כל החלקיקים הם CPUParticles2D (מחושבים ב-C++, ציור אחד לכל שכבה) - כמעט לא עולה זמן מעבד.
#    המשאבים (טקסטורות, צבעים, עקומות) נבנים פעם אחת ומשותפים לכל הפיצוצים.
#  * המשחק איטי (Quality.particles) או יותר מ-BUSY פיצוצים בבת אחת: פחות חלקיקים.
#  * הבזק, גל הדף, אור (בשלבים חשוכים, dyn_lights) וכתם חריכה מצוירים כאן.
#  * שברים שעפים וקופצים + זיקוקים עם שובל עשן: effects/boom_debris.gd (ילד של הפיצוץ).
#  לשנות: STYLE_* (המפרטים של כל סגנון), BUSY, SCORCH_T.  בדיקה: devtools/t_boom.gd (BOOM_STYLE=0/1/2).
# ============================================================

const BUSY := 4                  # מעל כמה פיצוצים חיים בבת אחת - חצי חלקיקים
const SCORCH_T := 5.0            # כמה זמן כתם החריכה נשאר
static var alive := 0
static var _last_style := -1
static var _res := {}            # משאבים משותפים (נבנים פעם אחת)

var radius := 120.0
var on_ground := false
var style := -1                  # -1 = אקראי
var t := 0.0
var _k := 1.0                    # גודל ביחס לפיצוץ רגיל (רדיוס 120)
var _pending := []               # [זמן התחלה, CPUParticles2D] - שכבות שמתחילות באיחור
var _end := 2.0
var _scorch := false


# מפרט שכבה: n כמות, life חיים, tex טקסטורה ("soft"/"puff"/"streak"/"" = ריבוע), add אור מצטבר,
# ramp צבעים, curve גודל לאורך החיים, vel מהירות (מינ', מקס'), dir כיוון, spread פיזור (מעלות; gspread על הריצפה),
# grav כבידה, damp האטה, scale גודל, er רדיוס יציאה, at מיקום, delay איחור, align מסתובב לכיוון התנועה, spin
const STYLE_FIREBALL := [
	{"n": 30, "life": 1.0, "tex": "soft", "ramp": "body", "curve": "grow", "vel": Vector2(60, 260), "spread": 180, "gspread": 85,
		"grav": Vector2(0, -90), "damp": Vector2(110, 200), "scale": Vector2(1.7, 2.8), "er": 18, "at": Vector2(0, -12)},
	{"n": 20, "life": 0.55, "tex": "soft", "add": true, "ramp": "hot", "curve": "grow", "vel": Vector2(20, 160), "spread": 180, "gspread": 80,
		"grav": Vector2(0, -60), "damp": Vector2(120, 220), "scale": Vector2(0.8, 1.4), "er": 12, "at": Vector2(0, -12)},
	{"n": 34, "life": 0.6, "tex": "streak", "add": true, "align": true, "ramp": "spark", "curve": "shrink", "vel": Vector2(280, 620), "spread": 180, "gspread": 80,
		"grav": Vector2(0, 700), "damp": Vector2(60, 140), "scale": Vector2(0.5, 0.9), "er": 6},
	{"n": 20, "life": 2.2, "tex": "puff", "ramp": "smoke", "curve": "smoke", "vel": Vector2(20, 80), "spread": 60, "gspread": 50,
		"grav": Vector2(0, -55), "damp": Vector2(15, 30), "scale": Vector2(1.9, 3.0), "er": 24, "at": Vector2(0, -30), "delay": 0.22},
	{"n": 14, "life": 1.6, "tex": "soft", "add": true, "ramp": "ember", "curve": "shrink", "vel": Vector2(60, 220), "spread": 180, "gspread": 70,
		"grav": Vector2(0, 160), "damp": Vector2(40, 90), "scale": Vector2(0.18, 0.32), "er": 20, "at": Vector2(0, -20), "delay": 0.1},
]
const STYLE_SHRAPNEL := [
	{"n": 56, "life": 0.38, "tex": "streak", "add": true, "align": true, "ramp": "spark", "curve": "shrink", "vel": Vector2(450, 1000), "spread": 180, "gspread": 82,
		"grav": Vector2(0, 500), "damp": Vector2(200, 500), "scale": Vector2(0.6, 1.1), "er": 4},
	{"n": 16, "life": 0.4, "tex": "soft", "add": true, "ramp": "hot", "curve": "grow", "vel": Vector2(20, 160), "spread": 180, "gspread": 75,
		"grav": Vector2(0, -40), "damp": Vector2(250, 400), "scale": Vector2(0.9, 1.6), "er": 8, "at": Vector2(0, -6)},
	{"n": 12, "life": 0.6, "tex": "soft", "ramp": "body", "curve": "grow", "vel": Vector2(40, 200), "spread": 180, "gspread": 75,
		"grav": Vector2(0, -50), "damp": Vector2(250, 400), "scale": Vector2(1.0, 1.7), "er": 10, "at": Vector2(0, -8)},
	{"n": 22, "life": 1.1, "tex": "", "ramp": "dirt", "curve": "const", "vel": Vector2(220, 560), "spread": 180, "gspread": 55,
		"grav": Vector2(0, 1100), "damp": Vector2(10, 40), "scale": Vector2(2.5, 5.0), "er": 8, "spin": 8.0},
	{"n": 18, "life": 1.8, "tex": "puff", "ramp": "dust", "curve": "smoke", "vel": Vector2(90, 260), "spread": 180, "gspread": 88, "dir": Vector2(0, -1),
		"grav": Vector2(0, -12), "damp": Vector2(120, 200), "scale": Vector2(1.4, 2.3), "er": 12, "at": Vector2(0, -4), "delay": 0.05},
]
const STYLE_PILLAR := [
	{"n": 30, "life": 0.75, "tex": "soft", "ramp": "body", "curve": "grow", "vel": Vector2(160, 420), "spread": 14, "gspread": 14, "dir": Vector2(0, -1),
		"grav": Vector2(0, -60), "damp": Vector2(220, 380), "scale": Vector2(1.2, 2.0), "er": 10},
	{"n": 20, "life": 0.5, "tex": "soft", "add": true, "ramp": "hot", "curve": "grow", "vel": Vector2(120, 360), "spread": 10, "gspread": 10, "dir": Vector2(0, -1),
		"grav": Vector2(0, -40), "damp": Vector2(260, 420), "scale": Vector2(0.7, 1.2), "er": 6},
	{"n": 22, "life": 1.0, "tex": "soft", "ramp": "body", "curve": "grow", "vel": Vector2(60, 170), "spread": 180, "gspread": 180,
		"grav": Vector2(0, -70), "damp": Vector2(140, 220), "scale": Vector2(1.4, 2.4), "er": 16, "at": Vector2(0, -95), "delay": 0.12},
	{"n": 16, "life": 2.4, "tex": "puff", "ramp": "smoke", "curve": "smoke", "vel": Vector2(20, 70), "spread": 70, "gspread": 70, "dir": Vector2(0, -1),
		"grav": Vector2(0, -40), "damp": Vector2(10, 25), "scale": Vector2(1.7, 2.7), "er": 22, "at": Vector2(0, -105), "delay": 0.3},
	{"n": 14, "life": 1.2, "tex": "puff", "ramp": "dust", "curve": "smoke", "vel": Vector2(160, 300), "spread": 12, "gspread": 12, "dir": Vector2(1, -0.08),
		"grav": Vector2.ZERO, "damp": Vector2(200, 300), "scale": Vector2(1.0, 1.7), "er": 6, "at": Vector2(0, -4), "mirror": true},
	{"n": 18, "life": 1.8, "tex": "soft", "add": true, "ramp": "ember", "curve": "shrink", "vel": Vector2(40, 180), "spread": 180, "gspread": 180,
		"grav": Vector2(0, 200), "damp": Vector2(30, 70), "scale": Vector2(0.18, 0.32), "er": 30, "at": Vector2(0, -90), "delay": 0.25},
]


static func styles() -> Array:
	return [STYLE_FIREBALL, STYLE_SHRAPNEL, STYLE_PILLAR]


# אקראי, אבל אף פעם לא אותו סגנון פעמיים ברצף
static func pick_style() -> int:
	var s := randi() % 3
	if s == _last_style:
		s = (s + 1 + randi() % 2) % 3
	_last_style = s
	return s


func _ready() -> void:
	alive += 1
	z_index = 20
	_k = clampf(radius / 120.0, 0.55, 1.5)
	if style < 0:
		var forced := OS.get_environment("BOOM_STYLE")   # בדיקות בלבד (devtools/t_boom.gd)
		style = int(forced) if forced != "" else pick_style()
	_scorch = on_ground
	var q: float = Quality.particles() * (0.5 if alive > BUSY else 1.0)
	for spec in styles()[style]:
		_layer(spec, q)
		if spec.get("mirror", false):   # שכבה כפולה לשני הצדדים (טבעת אבק)
			var m: Dictionary = spec.duplicate()
			m["dir"] = Vector2(-(spec["dir"] as Vector2).x, (spec["dir"] as Vector2).y)
			_layer(m, q)
	if Debris.alive < Debris.TOO_MANY:   # שברים + זיקוקים (effects/boom_debris.gd); המון פיצוצים בבת אחת - בלי
		var d := Debris.new()
		d.style = style
		d.k = _k
		d.on_ground = on_ground
		d.q = q
		add_child(d)
		_end = maxf(_end, 4.4)
	add_to_group("dyn_lights")
	if _scorch:
		_end = maxf(_end, SCORCH_T)


func _exit_tree() -> void:
	alive -= 1


func _layer(spec: Dictionary, q: float) -> void:
	var n := maxi(1, int(round(float(spec["n"]) * q)))
	var r := res()
	var p := CPUParticles2D.new()
	p.one_shot = true
	p.explosiveness = 0.92
	p.local_coords = true
	p.amount = n
	p.lifetime = float(spec["life"])
	p.lifetime_randomness = 0.35
	var tx: String = spec.get("tex", "")
	if tx != "":
		p.texture = r[tx]
	if spec.get("add", false):
		p.material = r["add"]
	if spec.get("align", false):
		p.particle_flag_align_y = true
	var dir: Vector2 = spec.get("dir", Vector2(0, -1))
	p.direction = dir
	p.spread = float(spec["gspread"] if on_ground else spec["spread"])
	p.gravity = spec["grav"] * _k
	var vel: Vector2 = spec["vel"] * _k
	p.initial_velocity_min = vel.x
	p.initial_velocity_max = vel.y
	var damp: Vector2 = spec["damp"] * _k
	p.damping_min = damp.x
	p.damping_max = damp.y
	var sc: Vector2 = spec["scale"] * _k
	p.scale_amount_min = sc.x
	p.scale_amount_max = sc.y
	p.scale_amount_curve = r["c_" + str(spec["curve"])]
	p.color_ramp = r["g_" + str(spec["ramp"])]
	p.angle_min = 0.0
	p.angle_max = 360.0 if tx == "puff" or tx == "" else 0.0
	var spin: float = spec.get("spin", 0.0)
	if spin > 0.0:
		p.angular_velocity_min = -spin * 57.3
		p.angular_velocity_max = spin * 57.3
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	p.emission_sphere_radius = float(spec["er"]) * _k
	p.position = spec.get("at", Vector2.ZERO) * _k
	var delay: float = spec.get("delay", 0.0)
	p.emitting = delay <= 0.0
	add_child(p)
	if delay > 0.0:
		_pending.append([delay, p])
	_end = maxf(_end, delay + p.lifetime + 0.15)


func _process(delta: float) -> void:
	t += delta
	for i in range(_pending.size() - 1, -1, -1):
		if t >= float(_pending[i][0]):
			(_pending[i][1] as CPUParticles2D).emitting = true
			_pending.remove_at(i)
	if t >= _end:
		queue_free()
		return
	if t < 0.45 or (_scorch and t > _end - 1.2):   # הבזק וגל הדף / הכתם נעלם. באמצע - אין מה לצייר מחדש
		queue_redraw()
	elif t < 0.5:
		queue_redraw()


# אור קצר בשלבים חשוכים (effects/dyn_lights.gd)
func lights() -> Array:
	if t > 0.5:
		return []
	return [[global_position, 260.0 * _k, 0.9 * (1.0 - t / 0.5)]]


func _draw() -> void:
	DrawBatch.begin(self)
	_draw_b()
	DrawBatch.end(self)

func _draw_b() -> void:
	if _scorch:   # כתם חריכה על הריצפה
		var a := clampf((_end - t) / 1.2, 0.0, 1.0) * clampf(t / 0.2, 0.0, 1.0)
		DrawBatch.ellipse(self, Vector2(0, 3), 46.0 * _k, 6.0 * _k, Color(0.07, 0.05, 0.04, 0.5 * a))
		DrawBatch.ellipse(self, Vector2(0, 3), 26.0 * _k, 3.5 * _k, Color(0.04, 0.03, 0.02, 0.45 * a))
	var fl := 0.08 if style != 1 else 0.06
	if t < fl:   # הבזק: כמה עיגולים שקופים אחד בתוך השני = אור רך שדועך לשוליים
		var k := 1.0 - t / fl
		var fc := Vector2(0, -8 * _k)
		for i in 4:
			DrawBatch.circle(self, fc, radius * (1.0 - 0.2 * i) * (0.85 + 0.25 * (1.0 - k)), Color(1.0, 0.9, 0.65, 0.1 * k))
		DrawBatch.circle(self, fc, radius * 0.22, Color(1.0, 1.0, 0.92, 0.9 * k))
	var wt := 0.32 if style == 1 else 0.22
	if t < wt:   # גל הדף: טבעת שמתרחבת (רסיסים - חזקה יותר)
		var k := t / wt
		var rr := radius * (0.25 + 1.15 * (1.0 - pow(1.0 - k, 2.0)))
		var w := (5.0 if style == 1 else 3.0) * _k * (1.0 - k) + 1.0
		var c := Color(1.0, 0.95, 0.85, (0.55 if style == 1 else 0.3) * (1.0 - k))
		if on_ground:
			DrawBatch.arc(self, Vector2.ZERO, rr, PI, TAU, 24, c, w, true)
		else:
			DrawBatch.arc(self, Vector2.ZERO, rr, 0.0, TAU, 40, c, w, true)


# ---------------- משאבים משותפים ----------------
static func res() -> Dictionary:
	if not _res.is_empty():
		return _res
	_res["soft"] = _radial([[0.0, Color(1, 1, 1, 1)], [0.35, Color(1, 1, 1, 0.8)], [1.0, Color(1, 1, 1, 0)]], 32)
	_res["puff"] = _radial([[0.0, Color(1, 1, 1, 0.9)], [0.55, Color(1, 1, 1, 0.65)], [1.0, Color(1, 1, 1, 0)]], 32)
	var g := Gradient.new()   # פס צר וארוך לניצוצות (מסתובב לכיוון התנועה)
	g.set_color(0, Color(1, 1, 1, 1))
	g.set_color(1, Color(1, 1, 1, 0))
	var st := GradientTexture2D.new()
	st.gradient = g
	st.width = 4
	st.height = 22
	st.fill = GradientTexture2D.FILL_LINEAR
	st.fill_from = Vector2(0.5, 0.15)
	st.fill_to = Vector2(0.5, 1.0)
	_res["streak"] = st
	var add := CanvasItemMaterial.new()
	add.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	_res["add"] = add
	_res["g_hot"] = _ramp([[0.0, Color(1, 0.95, 0.75, 0.85)], [0.15, Color(1, 0.8, 0.35, 0.8)], [0.5, Color(1, 0.42, 0.08, 0.55)], [1.0, Color(0.6, 0.1, 0.02, 0)]])
	_res["g_body"] = _ramp([[0.0, Color(1, 0.93, 0.65, 1)], [0.18, Color(1, 0.62, 0.16, 1)], [0.45, Color(0.88, 0.3, 0.07, 0.95)], [0.72, Color(0.32, 0.13, 0.07, 0.8)], [1.0, Color(0.16, 0.13, 0.12, 0)]])
	_res["g_smoke"] = _ramp([[0.0, Color(0.35, 0.22, 0.14, 0)], [0.1, Color(0.3, 0.24, 0.2, 0.7)], [0.5, Color(0.25, 0.24, 0.24, 0.5)], [1.0, Color(0.4, 0.4, 0.4, 0)]])
	_res["g_spark"] = _ramp([[0.0, Color(1, 1, 0.85, 1)], [0.5, Color(1, 0.72, 0.25, 1)], [1.0, Color(1, 0.35, 0.05, 0)]])
	_res["g_ember"] = _ramp([[0.0, Color(1, 0.85, 0.35, 1)], [0.7, Color(1, 0.42, 0.1, 0.85)], [1.0, Color(0.6, 0.15, 0.05, 0)]])
	_res["g_dirt"] = _ramp([[0.0, Color(0.24, 0.18, 0.13, 1)], [0.8, Color(0.2, 0.15, 0.11, 1)], [1.0, Color(0.2, 0.15, 0.11, 0)]])
	_res["g_dust"] = _ramp([[0.0, Color(0.55, 0.47, 0.38, 0)], [0.1, Color(0.5, 0.43, 0.35, 0.55)], [1.0, Color(0.55, 0.5, 0.45, 0)]])
	_res["c_grow"] = _curve([Vector2(0, 0.45), Vector2(0.25, 1.0), Vector2(1, 1.3)])
	_res["c_shrink"] = _curve([Vector2(0, 1.0), Vector2(1, 0.2)])
	_res["c_smoke"] = _curve([Vector2(0, 0.5), Vector2(1, 1.0)])
	_res["c_const"] = _curve([Vector2(0, 1.0), Vector2(1, 1.0)])
	return _res


static func _radial(stops: Array, size: int) -> Texture2D:
	var t := GradientTexture2D.new()
	t.gradient = _ramp(stops)
	t.width = size
	t.height = size
	t.fill = GradientTexture2D.FILL_RADIAL
	t.fill_from = Vector2(0.5, 0.5)
	t.fill_to = Vector2(1.0, 0.5)
	return t


static func _ramp(stops: Array) -> Gradient:
	var g := Gradient.new()
	g.offsets = PackedFloat32Array()
	g.colors = PackedColorArray()
	for s in stops:
		g.add_point(float(s[0]), s[1])
	return g


static func _curve(pts: Array) -> Curve:
	var c := Curve.new()
	c.max_value = 2.0
	for p in pts:
		c.add_point(p)
	return c


# חימום: כל סוגי השכבות פעם אחת, שקופות כמעט לגמרי, באמצע המסך - כדי שהפיצוץ הראשון בשלב לא יקפא
# (קומפילציה של shader האור המצטבר). main.gd קורא לזה בתחילת השלב, כמו FleshFx.prewarm.
static func prewarm(parent: Node) -> void:
	parent.get_tree().create_timer(0.5, false).timeout.connect(func():
		if not is_instance_valid(parent) or not parent.is_inside_tree():
			return
		var cam := parent.get_viewport().get_camera_2d()
		if cam == null:
			return
		var r := res()
		for i in 4:
			var p := CPUParticles2D.new()
			p.one_shot = true
			p.amount = 2
			p.lifetime = 0.3
			p.texture = [r["soft"], r["streak"], r["puff"], null][i]
			if i < 2:
				p.material = r["add"]
			p.particle_flag_align_y = i == 1
			p.scale_amount_curve = r["c_grow"]
			p.color_ramp = r["g_hot"]
			p.modulate = Color(1, 1, 1, 0.01)
			parent.add_child(p)
			p.global_position = cam.get_screen_center_position()
			p.emitting = true
			p.finished.connect(p.queue_free))
