extends Node2D
# ============================================================
#  עולם המפעל (שלב 3: THEY BUILD). main.gd יוצר אותו.
#  הזומבים השתלטו על מפעל ובונים בו מכונות.
#  * רקע: ארובות עם עשן, עגורנים, מיכלים, תנורים זוהרים, גצים באוויר
#  * ריצפה: בטון עם פסי אזהרה צהוב-שחור וכתמי שמן
# ============================================================

var floor_y := 630.0
var level_w := 10240.0


func _ready() -> void:
	var x := 0.0
	while x < level_w:   # קישוטי ריצפה (מצוירים פעם אחת)
		var c := Chunk.new()
		c.floor_y = floor_y
		c.position = Vector2(x, 0.0)
		get_parent().add_child.call_deferred(c)
		x += 1024.0


class Chunk extends Node2D:
	var floor_y := 630.0

	func _ready() -> void:
		z_index = 1

	func _draw() -> void:
		var rng := RandomNumberGenerator.new()
		rng.seed = int(position.x) + 333
		var w := 1024.0
		var y := floor_y
		draw_rect(Rect2(0, y, w, 4), Color("4a4640"))   # שפת בטון
		var x := rng.randf_range(0.0, 200.0)
		while x < w - 120.0:   # פסי אזהרה
			var len := rng.randf_range(90.0, 180.0)
			draw_rect(Rect2(x, y + 1, len, 5), Color("c8a020"))
			var sx := x
			while sx < x + len - 6.0:
				draw_colored_polygon(PackedVector2Array([Vector2(sx, y + 6), Vector2(sx + 6, y + 1), Vector2(sx + 11, y + 1), Vector2(sx + 5, y + 6)]), Color("1a1a1a"))
				sx += 12.0
			x += len + rng.randf_range(250.0, 500.0)
		for i in 5:   # כתמי שמן
			var ox := rng.randf_range(0.0, w)
			draw_set_transform(Vector2(ox, y + 8), 0.0, Vector2(1.0, 0.25))
			draw_circle(Vector2.ZERO, rng.randf_range(10.0, 26.0), Color(0.05, 0.05, 0.06, 0.6))
			draw_set_transform_matrix(Transform2D.IDENTITY)
		for i in 10:   # ברגים וחלקים זרוקים
			var bx := rng.randf_range(0.0, w)
			draw_rect(Rect2(bx, y - 2, rng.randf_range(2.0, 6.0), 2), Color("6a6660"))


# רקע: אזור תעשייה הרוס (פרלקסה), מצויר על המסך
class FactoryBg extends Node2D:
	var level_w := 10240.0
	var _last_x := INF
	var _t := 0.0
	var _embers := []

	func _ready() -> void:
		for i in 40:
			_embers.append([randf() * 1280.0, randf() * 720.0, randf_range(10.0, 30.0), randf() * TAU])

	func _process(d: float) -> void:
		_t += d
		var cam := get_viewport().get_camera_2d()
		if cam != null:
			_last_x = cam.get_screen_center_position().x
		for e in _embers:   # גצים עולים
			e[1] -= e[2] * d
			e[0] += sin(_t * 1.5 + e[3]) * 8.0 * d
			if e[1] < 0.0:
				e[1] = 720.0
				e[0] = randf() * 1280.0
		queue_redraw()

	func _draw() -> void:
		var vs := get_viewport().get_visible_rect().size
		var cx := 0.0 if _last_x == INF else _last_x
		# שמיים: אדום-חום מעושן
		var bands := [Color("2a1612"), Color("3a1d14"), Color("4e2616"), Color("6a3418"), Color("5a3020")]
		for i in bands.size():
			draw_rect(Rect2(0, vs.y * float(i) / bands.size() * 0.8, vs.x, vs.y * 0.8 / bands.size() + 2), bands[i])
		draw_circle(Vector2(vs.x * 0.7 - fmod(cx * 0.02, 200.0), 230), 90, Color(1.0, 0.45, 0.15, 0.12))   # שמש חולה בעשן
		# שכבה רחוקה: מבני מפעל וארובות
		var off := fmod(cx * 0.2, 640.0)
		for i in 4:
			var bx := float(i) * 640.0 - off - 100.0
			draw_rect(Rect2(bx, 380, 260, 260), Color("23140f"))
			draw_rect(Rect2(bx + 270, 430, 200, 210), Color("1f120d"))
			for k in 3:   # ארובות + עשן
				var chx := bx + 40.0 + float(k) * 80.0
				var chh := 160.0 + float((i * 3 + k) % 3) * 40.0
				draw_rect(Rect2(chx, 380 - chh, 22, chh), Color("2a1812"))
				draw_rect(Rect2(chx - 2, 380 - chh, 26, 8), Color("3a2018"))
				for p in 6:
					var age := fmod(_t * 0.25 + float(p) / 6.0 + float(k) * 0.3, 1.0)
					var sp := Vector2(chx + 11.0 + age * 90.0 + sin(age * 6.0 + float(k)) * 10.0, 380.0 - chh - age * 160.0)
					draw_circle(sp, 10.0 + age * 34.0, Color(0.22, 0.17, 0.15, 0.35 * (1.0 - age)))
		# עגורן
		var coff := fmod(cx * 0.35, 1400.0)
		for i in 2:
			var gx := float(i) * 1400.0 - coff + 300.0
			draw_line(Vector2(gx, 600), Vector2(gx, 230), Color("3a2a20"), 6.0)
			draw_line(Vector2(gx - 60, 240), Vector2(gx + 320, 240), Color("3a2a20"), 5.0)
			for k in 8:
				draw_line(Vector2(gx - 60 + k * 47, 240), Vector2(gx - 37 + k * 47, 256), Color("3a2a20"), 2.0)
			var hook := gx + 200.0 + sin(_t * 0.4) * 30.0
			draw_line(Vector2(hook, 240), Vector2(hook, 330), Color("2a1e18"), 1.5)
			draw_rect(Rect2(hook - 30, 330, 60, 34), Color("4a2a1c"))
		# שכבה קרובה: מיכלים, צינורות ותנורים זוהרים
		var noff := fmod(cx * 0.55, 900.0)
		for i in 3:
			var nx := float(i) * 900.0 - noff - 50.0
			draw_rect(Rect2(nx, 440, 120, 170), Color("2e2420"))
			draw_circle(Vector2(nx + 60, 440), 60, Color("2e2420"))
			draw_line(Vector2(nx + 120, 480), Vector2(nx + 400, 480), Color("3a2c24"), 10.0)
			draw_line(Vector2(nx + 400, 480), Vector2(nx + 400, 610), Color("3a2c24"), 10.0)
			var glow := 0.55 + 0.25 * sin(_t * 3.0 + float(i)) + 0.1 * sin(_t * 11.0)
			draw_rect(Rect2(nx + 470, 500, 140, 110), Color("2a1c16"))
			draw_rect(Rect2(nx + 500, 540, 80, 50), Color(1.0, 0.45, 0.1, glow))
			for k in 5:
				draw_circle(Vector2(nx + 540, 565), 40.0 + float(k) * 22.0, Color(1.0, 0.4, 0.1, 0.05 * glow))
		# גצים
		for e in _embers:
			draw_circle(Vector2(e[0], e[1]), 1.4, Color(1.0, 0.6, 0.2, 0.7))
		# צל בתחתית
		for i in 6:
			draw_rect(Rect2(0, 560 + float(i) * 12.0, vs.x, 12.0), Color(0, 0, 0, 0.12 + float(i) * 0.08))
