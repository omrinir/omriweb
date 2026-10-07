extends "res://levels/stage_base.gd"
# ============================================================
#  STAGE 10 - "SALT FLATS" (אזור צפון-מזרח, שלב 1) - "THEY BLEED WITH PURPOSE"
#  חוף צפון-מזרח ברזיל בשעת אחר צהריים לוהטת: מישורי מלח, בריכות אידוי ורודות,
#  ערימות מלח לבנות, דיונות עם לגונות, טורבינות רוח, מגדלור, ספינות ז'נגדה בים,
#  דקלי קוקוס וקרנאובה, קקטוס מנדקרו, בתים קולוניאליים צבעוניים.
#  מבנה: כביש חוף עם 2 טיילות עץ על כלונסאות (פלאפיטות) + רציף העמסת מלח מפלדה.
#  זומבים: JETPACK (18), BLOODGATE (פורטל דם), KRAKEN (זרועות דיונון), LIVEWIRE (חשמל + כבל חי),
#    ומעט WALKER / RUNNER. בוס: KRAKEN ענק - "THE DROWNED FISHERMAN".
#  נשקים: ASSAULT RIFLE, SNIPER (נגד הג'טפאקים), ASSAULT SHOTGUN (נגד הקראקן).
#  סכנות: קווי מתח שנפלו על הכביש (מחזוריים), הכבלים החיים של LIVEWIRE.
#  אפקטים: טורבינות מסתובבות, דקלים מתנדנדים, אלומת מגדלור, ספינות מתנדנדות, בוהק בים,
#    עופות דורסים, אבק מלח באוויר, גלי חום.
#  לשנות: zombie_weights(), DOWNED_LINES, מיקומי הטיילות ב-build_world().
# ============================================================

const WeaponDB := preload("res://weapons/weapon_db.gd")
const Hz := preload("res://environment/s10_hazards.gd")
const Decor := preload("res://effects/s10_decor.gd")

const DOWNED_LINES := 4


func zombie_weights() -> Dictionary:
	return {0: 0.14, 1: 0.12, 18: 0.1, Registry.BLOODGATE: 0.22, Registry.KRAKEN: 0.2, Registry.LIVEWIRE: 0.14}


func generators() -> Array:
	return [["car", 2.0], ["barrels", 1.2], ["sacks", 2.0], ["jangada", 1.2], ["cart", 1.2], ["tires", 0.8], ["crates", 1.0]]


func custom_gen(gname: String, x: float) -> float:
	if not gname in ["sacks", "jangada", "cart"]:
		return 0.0
	var o := Decor.Obstacle.new()
	o.kind = gname
	o.seed_v = rng.randi()
	match gname:
		"sacks":
			o.size = Vector2(rng.randf_range(3.0, 4.0) * 22.0, 14.0 * float(rng.randi_range(2, 4)))
		"jangada":
			o.size = Vector2(rng.randf_range(110.0, 140.0), 24.0)
		_:
			o.size = Vector2(rng.randf_range(70.0, 90.0), 40.0)
	o.position = Vector2(x, floor_y)
	main.add_child(o)
	reserve(Rect2(x, floor_y - o.size.y, o.size.x, o.size.y))
	return o.size.x + (30.0 if gname == "cart" else 0.0)


func boss_kind() -> int:
	return Registry.KRAKEN


func music() -> String:
	return "res://music/level1_total_war.mp3"


func world_tint() -> Color:
	return Color(1.0, 0.97, 0.9)


func fog() -> bool:
	return false


func street_props() -> bool:
	return false


func street_lamps() -> bool:
	return false


func pits() -> int:
	return 1


# ---- רקע: שמיים לוהטים + 3 שכבות פרלקסה ----
func build_background(layer: CanvasLayer) -> Node:
	var bg = Backdrop.new()
	bg.level_w = level_w
	bg.sky = func(ci: CanvasItem, v: Vector2, t: float):
		Kit.gradient_sky(ci, v, [Color("2c5888"), Color("4e86b2"), Color("94b8c8"), Color("e8d4a0"), Color("f2a868")])
		var sun := Vector2(v.x * 0.78, 190.0)
		for i in 5:
			ci.draw_circle(sun, 150.0 - float(i) * 24.0, Color(1.0, 0.85, 0.5, 0.06 + float(i) * 0.03))
		ci.draw_circle(sun, 44.0, Color(1.0, 0.97, 0.85))
		Kit.clouds(ci, 0.0, v, t, 120.0, Color(1.0, 0.97, 0.92, 0.35), 21, 5.0)
		for i in 3:   # אורובו (נשרים) חגים
			var c := Vector2(v.x * (0.25 + 0.25 * float(i)), 150.0 + float(i) * 30.0)
			var a := t * (0.35 + 0.1 * float(i)) + float(i) * 2.0
			var p := c + Vector2(cos(a) * 70.0, sin(a) * 22.0)
			var flap := sin(t * 3.0 + float(i)) * 3.0
			ci.draw_polyline(PackedVector2Array([p + Vector2(-11, -2 + flap), p + Vector2(-4, 1), p, p + Vector2(4, 1), p + Vector2(11, -2 + flap)]), Color(0.08, 0.06, 0.06, 0.8), 2.0)
	# שכבה 1 (רחוקה): ים עם ז'נגדות, דיונות לבנות עם לגונות, טורבינות רוח, מגדלור
	bg.add_layer(0.10, func(ci: CanvasItem, sc: float, v: Vector2, t: float):
		ci.draw_rect(Rect2(0, 452, v.x, 70), Color("3a7aa8"))
		ci.draw_rect(Rect2(0, 452, v.x, 6), Color("6aa0c0"))
		var r0 := RandomNumberGenerator.new()
		r0.seed = 77
		for i in 26:   # בוהק שמש על הים
			var gx := fposmod(r0.randf_range(0.0, 1800.0) - sc * 0.5, v.x + 100.0) - 50.0
			var gy := r0.randf_range(458.0, 500.0)
			var on := sin(t * 2.5 + float(i) * 1.7) > 0.3
			if on:
				ci.draw_line(Vector2(gx, gy), Vector2(gx + r0.randf_range(6.0, 16.0), gy), Color(1.0, 0.95, 0.8, 0.7), 1.5)
		for i in 4:   # ז'נגדות
			var jx := fposmod(float(i) * 520.0 + 150.0 - sc - t * 4.0, v.x + 300.0) - 150.0
			Decor.jangada(ci, Vector2(jx, 470.0 + float(i % 2) * 14.0), 0.8 + 0.2 * float(i % 2), t, Color("3a2a1e"), Color("f0e6d0"))
		var period := 1300.0
		var start := int(floor(sc / period)) - 1
		for k in range(start, start + 3):
			var x := float(k) * period - sc
			var r := RandomNumberGenerator.new()
			r.seed = k * 131 + 7
			var pts := PackedVector2Array([Vector2(x, 560)])
			for q in 27:   # דיונות לבנות
				var u := float(q) / 26.0
				pts.append(Vector2(x + u * period, 506.0 - absf(sin(u * 7.0 + float(k))) * 40.0 - sin(u * 3.0) * 8.0))
			pts.append(Vector2(x + period, 560))
			ci.draw_colored_polygon(pts, Color("e8e2d4"))
			for q in 4:   # לגונות כחולות-ירקרקות בין הדיונות
				var lx := x + r.randf_range(80.0, period - 80.0)
				Art.oval(ci, Vector2(lx, 520.0), r.randf_range(30.0, 60.0), 5.0, Color("5ab0b8"), 0.0, Art.NONE)
			for q in 4:   # טורבינות רוח
				var tx := x + 100.0 + float(q) * 300.0 + r.randf_range(-40.0, 40.0)
				Decor.turbine(ci, Vector2(tx, 500.0), r.randf_range(110.0, 160.0), t, float(q) * 1.3 + float(k), Color(0.92, 0.93, 0.95, 0.85))
			if k % 2 == 0:
				Decor.lighthouse(ci, Vector2(x + 700.0, 490.0), 120.0, t))
	# שכבה 2 (אמצע): ערימות מלח ענקיות, דקלי קרנאובה, שורת בתים קולוניאליים
	bg.add_layer(0.30, func(ci: CanvasItem, sc: float, v: Vector2, t: float):
		var period := 1100.0
		var start := int(floor(sc / period)) - 1
		for k in range(start, start + 3):
			var x := float(k) * period - sc
			var r := RandomNumberGenerator.new()
			r.seed = k * 577 + 11
			for q in 3:
				Decor.salt_mound(ci, Vector2(x + 120.0 + float(q) * 330.0 + r.randf_range(-50.0, 50.0), 585.0), r.randf_range(180.0, 260.0), r.randf_range(90.0, 140.0), Color("e4dcd2"), Color("bab0a8"))
			for q in 5:
				Decor.carnauba(ci, Vector2(x + r.randf_range(0.0, period), 590.0), r.randf_range(70.0, 110.0), t, Color("4a5a3a"))
			var hx := x + r.randf_range(600.0, 800.0)
			var cols := [Color("e8b84a"), Color("4aa0b8"), Color("e87a6a"), Color("7ac08a"), Color("c890c8")]
			for q in 4:
				var w := r.randf_range(60.0, 90.0)
				Decor.house(ci, Vector2(hx, 592.0), w, r.randf_range(50.0, 75.0), cols[(q + k) % cols.size()], r, 0.35)
				hx += w + 2.0)
	# שכבה 3 (קרובה): דקלי קוקוס מתנדנדים, קקטוסים, עמודי חשמל עם כבלים
	bg.add_layer(0.60, func(ci: CanvasItem, sc: float, v: Vector2, t: float):
		var period := 1000.0
		var start := int(floor(sc / period)) - 1
		var dark := Color("2a2a1e")
		for k in range(start, start + 3):
			var x := float(k) * period - sc
			var r := RandomNumberGenerator.new()
			r.seed = k * 913 + 5
			for q in 3:
				Decor.coconut_palm(ci, Vector2(x + r.randf_range(0.0, period), 640.0), r.randf_range(200.0, 280.0), r.randf_range(-0.5, 0.5), t, k * 3 + q, dark)
			for q in 2:
				Decor.mandacaru(ci, Vector2(x + r.randf_range(0.0, period), 640.0), r.randf_range(70.0, 120.0), Color("26341e"))
			for j in 3:   # עמודי חשמל + כבלים (אחד שבור)
				var px := x + float(j) * 340.0 + 60.0
				ci.draw_rect(Rect2(px, 380, 6, 260), dark)
				ci.draw_line(Vector2(px - 18, 392), Vector2(px + 24, 392), dark, 3.0)
				if j == 2 and k % 2 == 0:
					ci.draw_line(Vector2(px + 3, 392), Vector2(px + 40 + sin(t * 1.3) * 6.0, 500), Color(0.05, 0.05, 0.06, 0.9), 1.5)
					if fmod(t, 2.3) < 0.15:
						Art.glow(ci, Vector2(px + 40 + sin(t * 1.3) * 6.0, 500), 10.0, Color(0.5, 0.8, 1.0, 0.8))
					continue
				var pts := PackedVector2Array()
				for q in 9:
					var u := float(q) / 8.0
					pts.append(Vector2(px + 3.0 + u * 340.0, 392.0 + sin(u * PI) * (26.0 + sin(t * 0.7 + float(j)) * 2.0)))
				ci.draw_polyline(pts, Color(0.05, 0.05, 0.06, 0.85), 1.5)
		Kit.ground_fade(ci, v, 575.0))
	layer.add_child(bg)
	return bg


# ---- העולם ----
func build_world() -> void:
	var x := 0.0
	while x < level_w:   # מישורי המלח מאחורי הכביש
		var row := Decor.SaltWorks.new()
		row.position = Vector2(x, floor_y)
		row.seed_v = rng.randi()
		main.add_child(row)
		x += 1024.0
	# טיילות עץ על כלונסאות (פלאפיטות) עם סולמות
	for fx: float in [0.27, 0.61]:
		var ox := level_w * fx
		add_floor(ox, floor_y - 140.0, 420.0, "wood", true, true)
		add_ladder(ox + 24.0, floor_y - 140.0)
		reserve(Rect2(ox - 40.0, floor_y - 140.0, 500.0, 140.0))
	# רציף העמסת מלח (פלדה) - גבוה יותר, עולים מהטיילת או בסולם
	var dx := level_w * 0.45
	add_floor(dx, floor_y - 170.0, 300.0, "steel", true, true)
	add_ladder(dx + 270.0, floor_y - 170.0)
	reserve(Rect2(dx - 30.0, floor_y - 170.0, 360.0, 170.0))
	# קווי מתח שנפלו על הכביש
	var placed := 0
	var tries := 0
	while placed < DOWNED_LINES and tries < 40:
		tries += 1
		var lx := level_w * rng.randf_range(0.12, 0.88)
		if not free_x(lx, 110.0):
			continue
		var dl := Hz.DownedLine.new()
		dl.width = rng.randf_range(100.0, 140.0)
		add_hazard(dl, Vector2(lx, floor_y))
		reserve(Rect2(lx - 80.0, floor_y - 70.0, 220.0, 70.0))
		placed += 1


func build_effects() -> void:
	var dust := Ambient.screen_particles("dust", vp)   # אבק מלח שנישא ברוח
	dust.color = Color(1.0, 0.98, 0.92, 0.35)
	dust.direction = Vector2(-1, 0.1)
	dust.initial_velocity_min = 20.0
	dust.initial_velocity_max = 60.0
	screen_layer.add_child(dust)
	var haze := Decor.HeatHaze.new()
	haze.vp = vp
	screen_layer.add_child(haze)


# מיקומים מיוחדים: ג'טפאקים מעל הרציף, קראקן על הטיילת, LIVEWIRE ליד העמוד בקצה הטיילת
func extra_spawns() -> void:
	var ox := level_w * 0.27
	spawn(Registry.KRAKEN, ox + 300.0, floor_y - 140.0)
	spawn(Registry.BLOODGATE, level_w * 0.61 + 320.0, floor_y - 140.0)
	spawn(Registry.LIVEWIRE, level_w * 0.45 + 120.0, floor_y - 170.0)
	spawn(18, level_w * 0.5)
