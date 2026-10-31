extends "res://environment/hazard.gd"
const DrawBatch := preload("res://effects/draw_batch.gd")
# ============================================================
#  שטח בוער (מבקבוק תבערה / חבית / זומבי TORCH / SUPAY...)
#  מצית זומבים שנכנסים אליו ופוגע בשחקן שעומד בתוכו.
#  width = רוחב, life = כמה שניות בוער. modulate כחול (b > 1) = אש כחולה.
#  מראה (effects/flame_fx.gd): שלולית דלק חרוכה על הקרקע, לשונות אש בצורת טיפה שעולות ומתנדנדות,
#    פיסות אש שניתקות ועולות, גחלים, עשן רך, הילת אור רכה (ציור "הוספה" בילד _Light).
#  מחזור: הצתה (התלקחות גדולה) -> בעירה -> דעיכה (הלהבות נמוכות, נשארות גחלים).
#  האש נצמדת לקרקע: בזמן הנחיתה בודקים איפה יש רצפה מתחת, והשטח מתקצר כדי לא לבעור באוויר מעל בור / קצה במה.
#  לשנות: IGNITE_T, FADE_T, FLAME_H, הצבעים ב-flame_fx.gd.
# ============================================================

const F := preload("res://effects/flame_fx.gd")
const Art := preload("res://art.gd")

const IGNITE_T := 0.25          # התלקחות ראשונה
const FADE_T := 1.2             # דעיכה בסוף
const FLAME_H := 46.0           # גובה לשון ממוצע (באמצע הבעירה)

var width := 110.0
var total := 4.0
var _t := 0.0
var _seed := 0.0
var _licks := []                # [x, חצי-רוחב, גובה יחסי, פאזה, מהירות]
var _pal: Array = F.PALETTE
var _light: Node2D = null
var _fitted := false
var _left := 0.0
var _right := 0.0


func setup(w: float, seconds: float) -> void:
	story_kind = "fire"
	width = w
	life = seconds
	total = seconds
	_left = -w * 0.5
	_right = w * 0.5
	rect = Rect2(-w * 0.5, -34.0, w, 36.0)
	zombie_burn = 3.0
	player_damage = 1
	tick = 0.6


func _ready() -> void:
	super._ready()
	z_index = 6
	_seed = randf() * 100.0
	_check_blue()
	_light = _Light.new()
	_light.fz = self
	_light.material = F.additive()
	add_child(_light)
	_make_licks()


func _check_blue() -> void:
	if modulate.b > 1.0:   # אש כחולה (SUPAY / AZUFRERO שמים modulate כחול - לפעמים אחרי add_child)
		_pal = F.BLUE
		modulate = Color.WHITE


func _make_licks() -> void:
	_licks.clear()
	var span := _right - _left
	var n := clampi(int(span / 11.0), 3, 16)
	for i in n:
		var x := _left + (float(i) + 0.5 + randf_range(-0.3, 0.3)) * span / float(n)
		var edge := 1.0 - pow(absf(x - (_left + _right) * 0.5) / (span * 0.5 + 1.0), 2.0)   # בקצוות נמוך יותר
		_licks.append([x, maxf(6.5, span / float(n) * 0.8) * randf_range(0.9, 1.2), (0.45 + 0.55 * edge) * randf_range(0.8, 1.15), randf() * TAU, randf_range(0.8, 1.3)])


# מתאים את השטח לקרקע שמתחת (נקרא פעם אחת, אחרי שהמיקום נקבע)
func _fit_ground() -> void:
	_fitted = true
	var space := get_world_2d().direct_space_state
	var step := 10.0
	var xs := []
	var x := -width * 0.5
	while x <= width * 0.5 + 0.1:
		var from := global_position + Vector2(x, -18.0)
		var hit := space.intersect_ray(PhysicsRayQueryParameters2D.create(from, from + Vector2(0, 32.0), 1 | 16))
		xs.append([x, not hit.is_empty()])
		x += step
	# הרצף הכי ארוך עם קרקע (מעדיפים את זה שבמרכז)
	var best := [0.0, 0.0]
	var best_len := -1.0
	var run_start := INF
	for i in xs.size():
		var ok: bool = xs[i][1]
		if ok and run_start == INF:
			run_start = xs[i][0]
		if (not ok or i == xs.size() - 1) and run_start != INF:
			var run_end: float = xs[i][0] if ok else xs[i - 1][0]
			var run_len := run_end - run_start + (100.0 if run_start <= 0.0 and run_end >= 0.0 else 0.0)
			if run_len > best_len:
				best_len = run_len
				best = [run_start, run_end]
			run_start = INF
	if best_len < 0.0:   # אין קרקע בכלל (למשל על משהו שזז) - משאירים כמו שזה
		return
	_left = float(best[0]) - step * 0.4
	_right = float(best[1]) + step * 0.4
	if _right - _left < 24.0:   # קצה צר: לפחות להבה קטנה אחת
		var c := (_left + _right) * 0.5
		_left = c - 12.0
		_right = c + 12.0
	rect = Rect2(_left, -34.0, _right - _left, 36.0)
	_make_licks()


# עוצמה לפי הזמן: התלקחות -> בעירה -> דעיכה
func intensity() -> float:
	var flare := 1.0 + 0.35 * clampf(1.0 - (_t - IGNITE_T) / 0.6, 0.0, 1.0) if _t > IGNITE_T else _t / IGNITE_T * 1.35
	var fade := clampf(life / FADE_T, 0.0, 1.0) if life > 0.0 else 1.0
	return flare * fade


func _hazard_tick(delta: float) -> void:
	_t += delta
	_check_blue()
	if not _fitted and is_inside_tree():
		_fit_ground()
	# ביצועים: אש מתעדכנת 30 פעם בשנייה (20 כשהמשחק איטי - quality.gd) - נראה אותו דבר, חצי מחיר
	var every := 2 if Quality.level < 2 else 3
	if (Engine.get_physics_frames() + int(_seed)) % every == 0 and Art.on_screen(self, global_position + Vector2(0, -30), width * 0.5 + 120.0):
		queue_redraw()
		_light.queue_redraw()


func _draw() -> void:
	DrawBatch.begin(self)
	_draw_b()
	DrawBatch.end(self)

func _draw_b() -> void:
	var tt := _t + _seed
	var I := intensity()
	var span := _right - _left
	var cx := (_left + _right) * 0.5
	# שלולית דלק חרוכה
	DrawBatch.colored_polygon(self, Art.ellipse(Vector2(cx, 0.5), span * 0.55, 4.5, 0.0, 18), Color(0.06, 0.04, 0.03, 0.55 * clampf(_t * 4.0, 0.0, 1.0)))
	# עשן רך (מאחורי הלהבות)
	var ns := 2 + int(span / 40.0)
	for i in ns:
		var k := fmod(float(i) / float(ns) + tt * 0.32, 1.0)
		var sx := cx + (float(i) / float(maxi(ns - 1, 1)) - 0.5) * span * 0.7 + sin(tt * 0.9 + float(i) * 2.1) * 8.0 + k * 22.0
		var r := 10.0 + k * 28.0
		F.glow(self, Vector2(sx, -FLAME_H * 0.8 * I - k * 90.0), Vector2(r, r * 0.85), Color(0.12, 0.1, 0.1, 0.3 * (1.0 - k) * minf(I, 1.0)))
	# מצע בוער רציף לאורך השלולית (שהלהבות לא ייראו כמו גדר)
	var bed := PackedVector2Array([Vector2(_left, 1.0)])
	var inner := PackedVector2Array([Vector2(_left + 4.0, 1.0)])
	var nb := maxi(4, int(span / 8.0))
	for i in nb + 1:
		var bx := _left + span * float(i) / float(nb)
		var e := sin(PI * float(i) / float(nb))   # נמוך בקצוות
		var bh := (6.0 + 9.0 * F.wobble(tt * 0.9, float(i) * 1.3)) * (0.35 + 0.65 * e) * I
		bed.append(Vector2(bx, -bh))
		inner.append(Vector2(clampf(bx, _left + 4.0, _right - 4.0), -bh * 0.55))
	bed.append(Vector2(_right, 1.0))
	inner.append(Vector2(_right - 4.0, 1.0))
	var c0: Color = _pal[1]
	var c1: Color = _pal[2]
	DrawBatch.colored_polygon(self, bed, Color(c0, 0.92 * minf(I * 1.3, 1.0)))
	DrawBatch.colored_polygon(self, inner, Color(c1, 0.9 * minf(I * 1.3, 1.0)))
	# לשונות האש
	for L in _licks:
		var x: float = L[0]
		var ph: float = L[3]
		var sp: float = L[4]
		var wv := F.wobble(tt * sp, ph)
		var h: float = FLAME_H * float(L[2]) * (0.55 + 0.75 * wv) * I
		var sway := (sin(tt * 3.1 * sp + ph) * 5.0 + sin(tt * 1.3 + ph) * 3.0) * clampf(h / FLAME_H, 0.3, 1.2)
		F.tongue(self, Vector2(x, 1.0), float(L[1]) * (0.75 + 0.35 * I), h, sway, _pal, minf(I * 1.3, 1.0))
		# פיסות אש שניתקות ועולות
		var k := fmod(tt * 1.6 * sp + ph, 1.0)
		F.puff(self, Vector2(x + sway + sin(tt * 4.0 + ph) * 3.0, -h * (0.75 + k * 0.9)), 4.5 * minf(I, 1.0), k, _pal, 0.9)


# הילה + ליבה בוהקת + גחלים (ציור "הוספה" - אור)
class _Light extends Node2D:
	var fz: Node2D

	func _draw() -> void:
		DrawBatch.begin(self)
		_draw_b()
		DrawBatch.end(self)

	func _draw_b() -> void:
		var I: float = fz.intensity()
		var tt: float = fz._t + fz._seed
		var span: float = fz._right - fz._left
		var cx: float = (fz._left + fz._right) * 0.5
		var pal: Array = fz._pal
		var flick := 0.85 + 0.15 * sin(tt * 17.0) * sin(tt * 7.0)
		var gc: Color = pal[1]
		F.glow(self, Vector2(cx, -18.0), Vector2(span * 0.75 + 40.0, 60.0) * (0.8 + 0.25 * I), Color(gc, 0.32 * minf(I, 1.2) * flick))
		var lc: Color = pal[2]
		F.glow(self, Vector2(cx, 0.0), Vector2(span * 0.6 + 20.0, 10.0), Color(lc, 0.45 * minf(I, 1.0)))   # אור על הקרקע
		for L in fz._licks:   # ליבה לבנה-חמה בבסיס כל לשון
			var x: float = L[0]
			var cc: Color = pal[3]
			F.glow(self, Vector2(x, -6.0), Vector2(9.0, 12.0) * (0.7 + 0.4 * I), Color(cc, 0.35 * minf(I, 1.0) * flick))
		var ne := 4 + int(span / 18.0)
		for i in ne:   # גחלים / ניצוצות שעולים
			var k := fmod(float(i) * 0.37 + tt * (0.5 + float(i % 3) * 0.15), 1.0)
			var ex: float = fz._left + fmod(float(i) * 37.0, maxf(span, 1.0)) + sin(tt * 3.0 + float(i)) * 6.0
			var ey := -10.0 - k * (60.0 + 40.0 * I)
			var ec: Color = pal[2]
			DrawBatch.circle(self, Vector2(ex, ey), 1.3 * (1.0 - k) + 0.4, Color(ec, (1.0 - k) * minf(I, 1.0)))
