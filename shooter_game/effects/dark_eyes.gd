extends Node2D
const DrawBatch := preload("res://effects/draw_batch.gd")
const Sfx := preload("res://sfx.gd")
# ============================================================
#  EYES IN THE DARK - בשלבים חשוכים, מדי פעם, רק כשרגוע ובלי אור: זוג עיניים זוהרות בחושך קדימה,
#  ממצמצות ונעלמות כשמתקרבים, כשאור (פנס / פיצוץ) נוגע בהן או אחרי כמה שניות.
#  "להראות פחות": רק קישוט - לא פוגעות ואי אפשר לירות בהן. לפעמים זוג שני לידן, לפעמים נהמה חלשה.
#  יושב ב-CanvasLayer בשכבה 1 עם follow_viewport (main.gd), אחרון בין הילדים = מעל שכבות החושך, כדי שיזהרו.
# ============================================================

const FIRST := Vector2(16.0, 28.0)   # שניות של רוגע עד הפעם הראשונה בשלב
const EVERY := Vector2(26.0, 50.0)   # ואחר כך
const MAX_SHOWS := 5
const CALM_NEED := 3.0               # כמה שניות בלי זומבי ער קרוב / יריות לפני שהן מופיעות
const NEAR_X := 700.0
const FLEE_DIST := 260.0             # השחקן קרוב מזה: נעלמות
const COLORS := [Color(1.0, 0.78, 0.25), Color(1.0, 0.78, 0.25), Color(0.72, 1.0, 0.35), Color(1.0, 0.32, 0.22)]

var main: Node
var _next := 0.0
var _shows := 0
var _calm := 0.0
var _scan := 0.0
var _pairs := []   # [מיקום, גודל, צבע, גיל, אורך חיים, זמני מצמוץ, נסגרות מאז (-1 = לא), הטיה, השהיה]


func _ready() -> void:
	_next = randf_range(FIRST.x, FIRST.y)


func _process(delta: float) -> void:
	var p = main._player if main != null else null
	if p == null or not is_instance_valid(p) or p.dead or main._finished:
		_calm = 0.0
	else:
		if p._recoil > 0.5 or p._hurt_t > 0.0:
			_calm = 0.0
		_scan -= delta
		if _scan <= 0.0:
			_scan = 0.3
			if _awake_near(p.global_position, NEAR_X):
				_calm = 0.0
		_calm += delta
		if _calm > CALM_NEED and _shows < MAX_SHOWS and _pairs.is_empty() and get_tree().get_nodes_in_group("story_scene").is_empty():
			_next -= delta
			if _next <= 0.0:
				_next = randf_range(EVERY.x, EVERY.y)
				_try_show(p)
	if _pairs.is_empty():
		return
	for e in _pairs:
		e[3] += delta
		if e[3] < 0.0:
			continue
		var gone: bool = e[3] > e[4] or p == null or not is_instance_valid(p) or p.dead
		if not gone:
			gone = (e[0] as Vector2).distance_to(p.global_position + Vector2(0.0, -40.0)) < FLEE_DIST or _lit(e[0]) or _awake_near(e[0], 70.0)
		if gone and e[6] < 0.0:
			e[6] = 0.0
		if e[6] >= 0.0:
			e[6] += delta
	_pairs = _pairs.filter(func(e): return e[6] < 0.25)
	queue_redraw()


func _try_show(p: Node2D) -> void:
	if _lit(p.global_position + Vector2(0.0, -40.0)):   # פנס דולק: אור = ביטחון
		return
	var vp := get_viewport()
	var view: Rect2 = vp.get_canvas_transform().affine_inverse() * vp.get_visible_rect()
	var face: float = p._face()
	for attempt in 8:   # מקום בחושך קדימה: לא ליד זומבי, לא ליד אור
		var x: float = p.global_position.x + face * randf_range(330.0, 600.0)
		var y: float = p.global_position.y - (randf_range(18.0, 40.0) if randf() < 0.25 else randf_range(65.0, 145.0))   # לפעמים נמוך (משהו זוחל / מתחת למכונית)
		var at := Vector2(x, y)
		if not view.grow(-50.0).has_point(at) or _lit(at) or _awake_near(at, 170.0, true):
			continue
		_shows += 1
		var col: Color = COLORS[randi() % COLORS.size()]
		_add(at, col, 0.0)
		if randf() < 0.25:   # להקה: עוד זוג לידן, קצת אחרי
			_add(at + Vector2(randf_range(-70.0, 70.0), randf_range(-35.0, 25.0)), col, -randf_range(0.3, 0.8))
		if randf() < 0.35:
			Sfx.play("growl", at, -14.0, 0.1, 1, 0.75)
		return


func _add(at: Vector2, col: Color, delay: float) -> void:
	var life := randf_range(1.8, 3.0)
	var blinks := [randf_range(0.6, life - 0.6)]
	if randf() < 0.5:
		blinks.append(blinks[0] + randf_range(0.25, 0.5))
	_pairs.append([at, randf_range(0.85, 1.25), col, delay, life, blinks, -1.0, randf_range(-0.12, 0.12), randf() * TAU])


# אור קרוב (פנס / פיצוץ / effects/dyn_lights.gd)
func _lit(at: Vector2) -> bool:
	for n in get_tree().get_nodes_in_group("dyn_lights"):
		if not n.has_method("lights"):
			continue
		for l in n.lights():
			if float(l[2]) > 0.2 and at.distance_to(l[0]) < float(l[1]) + 40.0:
				return true
	return false


# זומבי ער (any = גם שוכב) קרוב לנקודה (מרכז הגוף, בערך)
func _awake_near(at: Vector2, r: float, any := false) -> bool:
	for z in get_tree().get_nodes_in_group("zombies"):
		if z.dead or (z.dormant and not any) or not z.visible:
			continue
		var d: Vector2 = z.global_position + Vector2(0.0, -50.0) - at
		if absf(d.x) < r and absf(d.y) < maxf(r, 140.0):
			return true
	return false


func _draw() -> void:
	DrawBatch.begin(self)
	_draw_b()
	DrawBatch.end(self)


func _draw_b() -> void:
	for e in _pairs:
		var age: float = e[3]
		if age < 0.0:
			continue
		var open := clampf(age / 0.45, 0.0, 1.0)   # נפתחות לאט
		for b in e[5]:   # מצמוץ
			var d: float = absf(age - float(b))
			if d < 0.09:
				open = minf(open, d / 0.09)
		if e[6] >= 0.0:   # נסגרות ונעלמות
			open = minf(open, 1.0 - clampf(e[6] / 0.2, 0.0, 1.0))
		if open <= 0.02:
			continue
		var s: float = e[1]
		var col: Color = e[2]
		var c: Vector2 = e[0] + Vector2(sin(age * 1.3 + e[8]) * 2.0, 0.0)
		var tilt: float = e[7]
		for side in [-1.0, 1.0]:
			var ec := c + Vector2(side * 5.5 * s, side * tilt * 4.0)
			DrawBatch.circle(self, ec, 8.0 * s, Color(col, 0.05 * open))   # הילה רכה
			DrawBatch.circle(self, ec, 5.0 * s, Color(col, 0.08 * open))
			DrawBatch.ellipse(self, ec, 3.6 * s, 1.8 * s * open, Color(col, 0.95), -side * 0.22)   # שקד מלוכסן פנימה = "כועסות"
			DrawBatch.ellipse(self, ec, 1.4 * s, 0.9 * s * open, Color(1.0, 1.0, 0.85, 0.9), -side * 0.22)
