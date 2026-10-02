extends Node2D
# ============================================================
#  קישוטים על הכביש (חתיכה של 1024 פיקסלים):
#  פסים לבנים מקווקווים, סדקים, בורות, עשבים שצומחים מהסדקים,
#  כתמי דם ישנים, מכסה ביוב, פחיות ועיתונים.
#  pits = רשימת הבורות בכביש [x, רוחב] - מציירים סביבם שוליים שבורים.
# ============================================================

var width := 1024.0
var floor_y := 630.0
var pits := []
var seed_value := 0
var pit_depth := 60.0


func _ready() -> void:
	z_index = 1


func _in_pit(x: float, margin := 10.0) -> bool:
	for p in pits:
		if x > float(p[0]) - margin and x < float(p[0]) + float(p[1]) + margin:
			return true
	return false


func _draw() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var gx := global_position.x
	var y := floor_y - global_position.y
	# פסים מקווקווים (חלקם מחוקים)
	var x := fposmod(-gx, 90.0)
	while x < width:
		if rng.randf() < 0.75 and not _in_pit(gx + x, 40.0):
			var w := rng.randf_range(20.0, 40.0)
			draw_rect(Rect2(x, y + 5.0, w, 2.5), Color(0.85, 0.82, 0.7, rng.randf_range(0.25, 0.55)))
		x += 90.0
	# סדקים + עשבים
	for i in 9:
		var cx := rng.randf_range(0.0, width)
		if _in_pit(gx + cx, 20.0):
			continue
		var pts := PackedVector2Array([Vector2(cx, y + 1.0)])
		var px := cx
		for j in rng.randi_range(3, 5):
			px += rng.randf_range(4.0, 12.0) * (1.0 if rng.randf() < 0.5 else -1.0)
			pts.append(Vector2(px, y + rng.randf_range(1.0, 12.0)))
		draw_polyline(pts, Color(0.05, 0.05, 0.06, 0.8), 1.2, true)
		if rng.randf() < 0.6:   # עשב
			for j in rng.randi_range(3, 6):
				var bx := cx + rng.randf_range(-4.0, 4.0)
				var tip := Vector2(bx + rng.randf_range(-4.0, 4.0), y - rng.randf_range(4.0, 11.0))
				draw_line(Vector2(bx, y + 1.0), tip, Color(0.28, 0.42, 0.18).darkened(rng.randf_range(0.0, 0.3)), 1.3, true)
	# בורות (פותהולים) - שקע כהה בשכבה העליונה
	for i in 2:
		var hx := rng.randf_range(20.0, width - 40.0)
		if _in_pit(gx + hx, 40.0):
			continue
		var hw := rng.randf_range(14.0, 30.0)
		draw_colored_polygon(PackedVector2Array([Vector2(hx, y), Vector2(hx + hw, y), Vector2(hx + hw - 3.0, y + 5.0), Vector2(hx + 3.0, y + 6.0)]), Color(0.08, 0.07, 0.07))
		draw_line(Vector2(hx, y), Vector2(hx + hw, y), Color(0.5, 0.5, 0.5, 0.4), 1.0, true)
	# כתמי דם ישנים
	for i in 2:
		if rng.randf() < 0.6:
			var bx := rng.randf_range(0.0, width - 40.0)
			if not _in_pit(gx + bx, 40.0):
				draw_rect(Rect2(bx, y - 1.0, rng.randf_range(16.0, 40.0), 3.0), Color(0.3, 0.04, 0.04, 0.75))
				draw_rect(Rect2(bx + 5.0, y + 2.0, rng.randf_range(6.0, 18.0), 3.0), Color(0.25, 0.03, 0.03, 0.55))
	# מכסה ביוב
	if rng.randf() < 0.4:
		var mx := rng.randf_range(20.0, width - 40.0)
		if not _in_pit(gx + mx, 40.0):
			draw_rect(Rect2(mx, y + 2.0, 26.0, 3.0), Color("24242a"))
			draw_rect(Rect2(mx, y + 2.0, 26.0, 3.0), Color(0.6, 0.6, 0.6, 0.3), false, 1.0)
	# פחיות ועיתונים זרוקים
	for i in 4:
		var lx := rng.randf_range(0.0, width)
		if _in_pit(gx + lx, 10.0):
			continue
		if rng.randf() < 0.5:
			draw_rect(Rect2(lx, y - 3.0, 5.0, 3.0), Color(0.6, 0.62, 0.65) if rng.randf() < 0.5 else Color(0.65, 0.15, 0.12))
		else:
			draw_colored_polygon(PackedVector2Array([Vector2(lx, y), Vector2(lx + 10.0, y - 1.0), Vector2(lx + 12.0, y), Vector2(lx + 1.0, y + 1.0)]), Color(0.78, 0.76, 0.7))
	# שוליים שבורים של בורות בכביש
	for p in pits:
		var px0 := float(p[0]) - gx
		var px1 := px0 + float(p[1])
		if px1 < -20.0 or px0 > width + 20.0:
			continue
		# הקירות והאדמה בתוך הבור (כהה יותר למטה)
		var top := Color(0.2, 0.16, 0.13)
		var bot := Color(0.07, 0.05, 0.05)
		draw_polygon(PackedVector2Array([Vector2(px0, y), Vector2(px1, y), Vector2(px1, y + pit_depth), Vector2(px0, y + pit_depth)]),
			PackedColorArray([top, top, bot, bot]))
		for j in 10:
			var sp := Vector2(rng.randf_range(px0 + 2.0, px1 - 6.0), rng.randf_range(y + 4.0, y + pit_depth - 4.0))
			draw_rect(Rect2(sp, Vector2(rng.randf_range(3.0, 7.0), rng.randf_range(2.0, 3.0))), Color(0, 0, 0, 0.3))
		# צינור שבור בתוך הבור
		draw_line(Vector2(px0, y + 22.0), Vector2(px0 + float(p[1]) * 0.35, y + 26.0), Color("4a4440"), 5.0, true)
		draw_line(Vector2(px1, y + 30.0), Vector2(px1 - float(p[1]) * 0.25, y + 33.0), Color("4a4440"), 5.0, true)
		for side in [px0, px1]:
			var dir := -1.0 if side == px0 else 1.0
			for j in 4:
				var bx: float = side + dir * rng.randf_range(0.0, 14.0)
				draw_colored_polygon(PackedVector2Array([Vector2(bx, y - 1.0), Vector2(bx + dir * 7.0, y - 3.0), Vector2(bx + dir * 9.0, y + 2.0), Vector2(bx + dir * 2.0, y + 4.0)]), Color(0.2, 0.2, 0.22))
			draw_line(Vector2(side, y), Vector2(side + dir * 18.0, y - 1.0), Color(0, 0, 0, 0.6), 2.0, true)
			# ברזל חלוד שבולט מהקצה
			draw_polyline(PackedVector2Array([Vector2(side, y + 8.0), Vector2(side - dir * 8.0, y + 6.0), Vector2(side - dir * 14.0, y + 10.0)]), Color("6a3a20"), 1.4, true)
