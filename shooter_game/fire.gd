extends Node2D
# ============================================================
#  אש קטנה (על מכונית הרוסה, בפח, מדורה וכו'). לשונות אש מהבהבות + עשן רך + הילת אור.
#  width = רוחב האש, life = כמה שניות היא בוערת (-1 = לתמיד)
#  הציור משותף עם השטח הבוער (effects/flame_fx.gd). האור / הליבה הבוהקת - בילד _Light (ציור "הוספה").
# ============================================================

const F := preload("res://effects/flame_fx.gd")

var width := 20.0
var height := 26.0
var life := -1.0
var smoke := true
var t := 0.0
var _seed := 0.0
var _licks := []
var _light: Node2D = null


func _ready() -> void:
	_seed = randf() * 100.0
	z_index = 2
	var n := clampi(int(width / 8.0), 1, 8)
	for i in n:
		var x := ((float(i) + 0.5) / float(n) - 0.5) * width * 0.8
		var edge := 1.0 - pow(absf(x) / (width * 0.5 + 1.0), 2.0)
		_licks.append([x, maxf(width / float(n) * 0.75, 3.5), 0.55 + 0.45 * edge, randf() * TAU, randf_range(0.85, 1.25)])
	_light = _Light.new()
	_light.f = self
	_light.material = F.additive()
	add_child(_light)


func fade() -> float:
	return 1.0 if life < 0.0 else clampf(life / 1.5, 0.0, 1.0)


func _process(delta: float) -> void:
	t += delta
	if life > 0.0:
		life -= delta
		if life <= 0.0:
			queue_free()
			return
	var vp := get_viewport()
	var r := vp.get_canvas_transform().affine_inverse() * vp.get_visible_rect()
	var every := 2 if Quality.level < 2 else 3   # 30 פעם בשנייה (20 כשהמשחק איטי)
	if (Engine.get_process_frames() + int(_seed)) % every == 0 and r.grow(150.0).has_point(global_position):   # מציירים רק כשרואים
		queue_redraw()
		_light.queue_redraw()


func _draw() -> void:
	var fd := fade()
	var tt := t + _seed
	if smoke:   # עשן רך שעולה
		for i in 4:
			var k := fmod(float(i) / 4.0 + tt * 0.3, 1.0)
			var r := 6.0 + k * 20.0
			F.glow(self, Vector2(sin(k * 5.0 + tt) * 4.0 + k * 14.0, -height * 0.9 - k * 70.0), Vector2(r, r * 0.85), Color(0.12, 0.1, 0.1, 0.32 * (1.0 - k) * fd))
	for L in _licks:
		var ph: float = L[3]
		var sp: float = L[4]
		var h: float = height * float(L[2]) * (0.6 + 0.65 * F.wobble(tt * sp, ph)) * fd
		var sway := sin(tt * 3.3 * sp + ph) * 3.5 * clampf(h / 26.0, 0.4, 1.3)
		F.tongue(self, Vector2(float(L[0]), 0.5), float(L[1]), h, sway, F.PALETTE, fd)
		var k := fmod(tt * 1.7 * sp + ph, 1.0)
		F.puff(self, Vector2(float(L[0]) + sway, -h * (0.75 + k * 0.8)), 3.5 * fd, k, F.PALETTE, 0.9)


class _Light extends Node2D:
	var f: Node2D

	func _draw() -> void:
		var fd: float = f.fade()
		var tt: float = f.t + f._seed
		var w: float = f.width
		var flick := 0.85 + 0.15 * sin(tt * 17.0) * sin(tt * 7.0)
		F.glow(self, Vector2(0, -f.height * 0.35), Vector2(w * 1.6 + 30.0, f.height * 1.4 + 20.0), Color(F.PALETTE[1], 0.3 * fd * flick))
		F.glow(self, Vector2(0, -5.0), Vector2(w * 0.5 + 6.0, 9.0), Color(F.PALETTE[3], 0.4 * fd * flick))
		for i in 4:   # ניצוצות
			var k := fmod(float(i) / 4.0 + tt * 0.8, 1.0)
			draw_circle(Vector2(sin(tt * 3.0 + float(i) * 2.0) * w * 0.5, -f.height * (0.6 + k * 1.5)), 1.2, Color(1.0, 0.7, 0.3, (1.0 - k) * fd))
