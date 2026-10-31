extends Node2D
const DrawBatch := preload("res://effects/draw_batch.gd")
# ============================================================
#  שברים + זיקוקים מפיצוץ (נוצר ע"י effects/boom_fx.gd, ילד של הפיצוץ, קואורדינטות מקומיות).
#   שברים: חתיכות בטון/מתכת/אדמה בצורות שבורות שעפות, מסתובבות, נוחתות וקופצות על הריצפה
#          (קרן קצרה לכל חתיכה שזזה - נוחתות גם על גגות ומדרגות), נחות רגע ונעלמות. חלקן לוהטות ומתקררות.
#   זיקוקים: 3-4 גחלים בוערים שנורים בקשת עם זנב אש ושובל עשן אפור שנשאר באוויר.
#  * הכל בצומת אחד שמצייר משולשים ב-DrawBatch (קריאת ציור אחת) + ילד אחד עם אור מצטבר (_glow) לראשי הזיקוקים.
#  * כמות לפי Quality.particles() (וחצי כשיש הרבה פיצוצים, BUSY), אין קרניים לחתיכה שנחה.
#  לשנות: DEBRIS_N, FLARES, GRAV, BOUNCE, REST_T.  בדיקה: devtools/t_boom.gd (perf / shot).
# ============================================================

const DEBRIS_N := [11, 14, 9]     # שברים לכל סגנון (כדור אש, רסיסים, עמוד אש)
const FLARES := [3, 4, 3]         # זיקוקים לכל סגנון
const GRAV := 1500.0
const BOUNCE := 0.32              # כמה מהמהירות נשאר בקפיצה מהריצפה
const REST_T := 1.6               # כמה זמן שבר נח על הריצפה לפני שנעלם
const FADE_T := 0.5
const TRAIL_N := 6                # נקודות בזנב האש של זיקוק
const TRAIL_STEP := 0.05          # כל כמה זמן נקודה חדשה בשובל (פחות נקודות = פחות ציור)
const SMOKE_T := 0.8              # כמה זמן העשן של השובל נשאר
const COLS := [Color("6a655e"), Color("4a423b"), Color("7d7468"), Color("2f2a27"), Color("5e4f3f")]

var style := 0
var k := 1.0                      # גודל ביחס לפיצוץ רגיל
var on_ground := false
var q := 1.0
var t := 0.0
var _pcs := []                    # [pos, vel, rot, spin, tris(PackedVector2Array, מקומי), col, hot(0..1), rest_t, alive]
var _fl := []                     # [pos, vel, life, age, trail(Array [pos, time]), dead, next_trail_t]
var _glow: Node2D
var _space: PhysicsDirectSpaceState2D
var _done := false
static var alive := 0              # כמה שברים-זיקוקים חיים עכשיו (boom_fx מקטין/מדלג כשיש הרבה)
const MANY := 4                   # מעל זה: חצי שברים ו-2 זיקוקים
const TOO_MANY := 8               # מעל זה: בלי שברים בכלל


func _ready() -> void:
	alive += 1
	if alive > MANY:
		q *= 0.5
	_space = get_world_2d().direct_space_state
	var n := maxi(3, int(round(float(DEBRIS_N[style]) * q)))
	for i in n:
		var a: float
		if on_ground:
			a = -PI * 0.5 + randf_range(-1.25, 1.25)
		else:
			a = randf() * TAU
		var sp := randf_range(260.0, 720.0) * k * (1.25 if style == 1 else 1.0)
		var sz := randf_range(5.0, 12.0) * k * (0.55 if randf() < 0.5 else 1.0)
		var poly := PackedVector2Array()
		var m := 3 + randi() % 3
		for j in m:   # צורה שבורה: מצולע לא סדיר
			var ang := TAU * float(j) / float(m) + randf_range(-0.35, 0.35)
			poly.append(Vector2(cos(ang), sin(ang)) * sz * randf_range(0.55, 1.15))
		var pts := PackedVector2Array()   # משולשים מוכנים (מניפה מהמרכז) + צד מואר - בכל פריים רק מזיזים/מסובבים
		for j in m:
			pts.append_array([Vector2.ZERO, poly[j], poly[(j + 1) % m]])
		var e := (poly[1] - poly[0]).orthogonal().normalized() * 0.6
		pts.append_array([poly[0] + e, poly[1] + e, poly[1] - e, poly[0] + e, poly[1] - e, poly[0] - e])
		var col: Color = COLS[randi() % COLS.size()]
		var hot := 1.0 if randf() < (0.45 if style != 1 else 0.3) else 0.0
		_pcs.append([Vector2(randf_range(-8, 8), randf_range(-14, -2)) * k, Vector2(cos(a), sin(a)) * sp,
			randf() * TAU, randf_range(-14.0, 14.0), pts, col, hot, 0.0, true])
	var nf := maxi(1, int(round(float(FLARES[style]) * minf(q, 1.0))))
	if alive > MANY:
		nf = mini(nf, 2)
	for i in nf:
		var a := -PI * 0.5 + randf_range(-1.15, 1.15) if on_ground or randf() < 0.75 else randf() * TAU
		var sp := randf_range(420.0, 680.0) * k
		_fl.append([Vector2(0, -10.0 * k), Vector2(cos(a), sin(a)) * sp, randf_range(0.8, 1.35), 0.0, [], false, 0.0])
	_glow = Node2D.new()
	_glow.material = preload("res://effects/boom_fx.gd").res()["add"]
	_glow.draw.connect(_draw_glow)
	add_child(_glow)


func _process(delta: float) -> void:
	t += delta
	var gp := global_position
	var any := false
	for p in _pcs:
		if not p[8]:
			continue
		any = true
		if p[7] > 0.0:   # נח על הריצפה
			p[7] += delta
			if p[7] > REST_T + FADE_T:
				p[8] = false
			continue
		var v: Vector2 = p[1]
		v.y += GRAV * delta
		var to: Vector2 = p[0] + v * delta
		var hit := _ray(gp + p[0], gp + to) if v.y > -60.0 else {}   # עולה למעלה: בלי קרן (חוסך חצי מהקרניים)
		if not hit.is_empty():
			var nrm: Vector2 = hit["normal"]
			to = hit["position"] - gp + nrm * 0.5
			v = v.bounce(nrm) * BOUNCE
			v.x *= 0.7
			p[3] *= 0.5
			if nrm.y < -0.6 and v.length() < 70.0:   # נחת
				v = Vector2.ZERO
				p[7] = 0.001
		elif t > 4.0:   # נפל למקום בלי ריצפה
			p[8] = false
		p[0] = to
		p[1] = v
		p[2] += p[3] * delta
		p[6] = maxf(0.0, p[6] - delta * 0.7)
	for f in _fl:
		var tr: Array = f[4]
		while not tr.is_empty() and t - float(tr[0][1]) > SMOKE_T:
			tr.pop_front()
		if f[5]:
			if not tr.is_empty():
				any = true
			continue
		any = true
		f[3] += delta
		var v: Vector2 = f[1]
		v.y += GRAV * 0.45 * delta
		v *= 1.0 - 0.6 * delta
		var to: Vector2 = f[0] + v * delta
		var hit := _ray(gp + f[0], gp + to)
		if not hit.is_empty() or f[3] >= f[2]:
			f[5] = true
		f[0] = to
		f[1] = v
		if t >= f[6] or f[5]:
			tr.append([to, t])
			f[6] = t + TRAIL_STEP
		elif not tr.is_empty():
			tr[-1] = [to, t]   # הנקודה האחרונה עוקבת אחרי הראש
	if not any:
		_done = true
		alive -= 1
		set_process(false)
		visible = false
		return
	queue_redraw()
	_glow.queue_redraw()


func _exit_tree() -> void:
	if not _done:
		_done = true
		alive -= 1


func _ray(a: Vector2, b: Vector2) -> Dictionary:
	if a.distance_squared_to(b) < 0.01:
		return {}
	var qp := PhysicsRayQueryParameters2D.create(a, b, 1)
	return _space.intersect_ray(qp)


func _draw() -> void:
	DrawBatch.begin(self)
	_draw_b()
	DrawBatch.end(self)

func _draw_b() -> void:
	# שובלי עשן של הזיקוקים (מאחור): קו שמתרחב ודוהה
	for f in _fl:
		var tr: Array = f[4]
		for i in range(1, tr.size()):
			var age: float = t - float(tr[i][1])
			var a := clampf(1.0 - age / SMOKE_T, 0.0, 1.0)
			if a <= 0.02:
				continue
			DrawBatch.line(self, tr[i - 1][0], tr[i][0], Color(0.4, 0.38, 0.36, 0.5 * a * a), (3.0 + age * 12.0) * k)
	# שברים
	for p in _pcs:
		if not p[8]:
			continue
		var a := 1.0
		if p[7] > REST_T:
			a = clampf(1.0 - (p[7] - REST_T) / FADE_T, 0.0, 1.0)
		var c: Color = p[5]
		var hot: float = p[6]
		if hot > 0.0:
			c = c.lerp(Color(1.0, 0.45, 0.12), clampf(hot, 0.0, 1.0) * 0.85)
		c.a = a
		var g: PackedVector2Array = Transform2D(float(p[2]), p[0]) * (p[4] as PackedVector2Array)
		var nm := g.size() - 6
		DrawBatch.tris(self, g.slice(0, nm), PackedColorArray([c]))
		DrawBatch.tris(self, g.slice(nm), PackedColorArray([Color(minf(c.r + 0.25, 1.0), minf(c.g + 0.22, 1.0), minf(c.b + 0.2, 1.0), a * 0.8)]))   # צד מואר


func _draw_glow() -> void:
	DrawBatch.begin(_glow)
	# זנב אש של הזיקוק: קצר, צהוב-כתום, דועך
	for f in _fl:
		var tr: Array = f[4]
		var n := tr.size()
		var from := maxi(1, n - TRAIL_N)
		for i in range(from, n):
			var u := float(i - from + 1) / float(n - from + 1)
			var age: float = t - float(tr[i][1])
			var a := u * clampf(1.0 - age / 0.35, 0.0, 1.0)
			if a <= 0.02:
				continue
			DrawBatch.line(_glow, tr[i - 1][0], tr[i][0], Color(1.0, 0.55 + 0.35 * u, 0.15 + 0.3 * u, 0.85 * a), (1.0 + 3.2 * u) * k)
		if not f[5]:   # ראש בוער
			var fl := 0.8 + 0.2 * sin(t * 47.0 + float(n))
			DrawBatch.circle(_glow, f[0], 7.0 * k * fl, Color(1.0, 0.5, 0.12, 0.35))
			DrawBatch.circle(_glow, f[0], 3.0 * k * fl, Color(1.0, 0.95, 0.75, 0.95))
	# שברים לוהטים זוהרים
	for p in _pcs:
		if p[8] and float(p[6]) > 0.05:
			DrawBatch.circle(_glow, p[0], 5.0 * k, Color(1.0, 0.4, 0.08, 0.35 * float(p[6])))
	DrawBatch.end(_glow)
