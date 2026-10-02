extends Node2D
# ============================================================
#  אש קטנה (על מכונית הרוסה, בפח וכו'). להבות מהבהבות + עשן.
#  width = רוחב האש, life = כמה שניות היא בוערת (-1 = לתמיד)
# ============================================================

var width := 20.0
var height := 26.0
var life := -1.0
var smoke := true
var t := 0.0
var _seed := 0.0


func _ready() -> void:
	_seed = randf() * 100.0
	z_index = 2


func _process(delta: float) -> void:
	t += delta
	if life > 0.0:
		life -= delta
		if life <= 0.0:
			queue_free()
			return
	var vp := get_viewport()
	var r := vp.get_canvas_transform().affine_inverse() * vp.get_visible_rect()
	if r.grow(150.0).has_point(global_position):   # מציירים רק כשרואים
		queue_redraw()


func _draw() -> void:
	var fade := 1.0 if life < 0.0 else clampf(life / 1.5, 0.0, 1.0)
	var tt := t + _seed
	# הילה של אור
	draw_circle(Vector2(0, -height * 0.3), width * 1.6, Color(1.0, 0.45, 0.15, 0.08 * fade))
	draw_circle(Vector2(0, -height * 0.3), width, Color(1.0, 0.5, 0.15, 0.1 * fade))
	# עשן שעולה
	if smoke:
		for i in 7:
			var k := fmod(float(i) / 7.0 + tt * 0.35, 1.0)
			var p := Vector2(sin(k * 5.0 + tt) * 4.0 + k * 14.0, -height * 0.8 - k * 70.0)
			draw_circle(p, 5.0 + k * 14.0, Color(0.15, 0.13, 0.13, 0.35 * (1.0 - k) * fade))
	# להבות: לשונות אש מהבהבות (אדום -> כתום -> צהוב)
	var n := maxi(3, int(width / 6.0))
	var layers := [[Color(0.85, 0.2, 0.05), 1.0], [Color(1.0, 0.55, 0.1), 0.72], [Color(1.0, 0.88, 0.4), 0.42]]
	for L in layers:
		var col: Color = L[0]
		var k: float = L[1]
		for i in n:
			var fx := (float(i) / float(n - 1) - 0.5) * width * k
			var h := height * k * (0.6 + 0.4 * sin(tt * 9.0 + float(i) * 1.7)) * (1.0 - absf(fx) / (width * 0.8))
			var sway := sin(tt * 6.0 + float(i)) * 3.0 * k
			var w := width / float(n) * 1.4 * k
			draw_colored_polygon(PackedVector2Array([
				Vector2(fx - w, 0.0), Vector2(fx - w * 0.5, -h * 0.5), Vector2(fx + sway, -h),
				Vector2(fx + w * 0.5, -h * 0.5), Vector2(fx + w, 0.0),
			]), Color(col, fade))
	# ניצוצות
	for i in 4:
		var k := fmod(float(i) / 4.0 + tt * 0.8, 1.0)
		draw_circle(Vector2(sin(tt * 3.0 + float(i) * 2.0) * width * 0.5, -height * (0.6 + k * 1.5)), 1.2, Color(1.0, 0.7, 0.3, (1.0 - k) * fade))
