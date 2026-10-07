extends "res://levels/stage_base.gd"
# ============================================================
#  STAGE 5 - "THE CITY REMEMBERS"
#  רובע עירוני הרוס. רוב השלב אופקי, עם קטע מוגבה אחד (גשר עילי שקרס)
#  שאפשר לעלות אליו בסולם או בקפיצה ממכונית, ולירות מלמעלה.
#  זומבים: RUNNER, CLIMBER (מטפס על קירות), SCOUT (מזעיק חברים - תקשורת!), BRUTE
#  נשקים: PISTOL, SMG, SHOTGUN
#  אפקטים: אפר נופל, גצים, עמודי עשן, שריפות, חלונות מהבהבים, מסוק ברקע
#  סכנה: הריסות בוערות על הכביש (זומבים חכמים עוקפים אותן)
# ============================================================

const FireZone := preload("res://environment/fire_zone.gd")
const WeaponDB := preload("res://weapons/weapon_db.gd")


func zombie_weights() -> Dictionary:
	return {0: 0.25, 1: 0.3, 2: 0.12, Registry.CLIMBER: 0.18, Registry.SCOUT: 0.1, 6: 0.05}


func generators() -> Array:
	return [["car", 3.5], ["barrels", 1.5], ["barrier", 2.0], ["sandbags", 1.0], ["rubble", 1.5], ["bus", 1.0], ["crates", 1.0], ["trash", 1.5]]


# ערימת זבל (שקיות + פח הפוך) - מכשול נמוך
func custom_gen(gname: String, x: float) -> float:
	if gname != "trash":
		return 0.0
	var t := TrashPile.new()
	t.position = Vector2(x, floor_y)
	t.seed_v = rng.randi()
	main.add_child(t)
	add_block(x + 6.0, floor_y - 14.0, 44.0, 14.0, Color("2a2a26"), true, 1)
	return 60.0


func boss_kind() -> int:
	return 5


func music() -> String:
	return "res://music/level1_total_war.mp3"


func world_tint() -> Color:
	return Color(1.0, 0.93, 0.86)


func street_props() -> bool:
	return true


func street_lamps() -> bool:
	return true


func pits() -> int:
	return 1


# ---- רקע: 3 שכבות פרלקסה ----
func build_background(layer: CanvasLayer) -> Node:
	var bg = Backdrop.new()
	bg.level_w = level_w
	bg.sky = func(ci: CanvasItem, v: Vector2, t: float):
		Kit.gradient_sky(ci, v, [Color("2a2230"), Color("4a3038"), Color("8a4a32"), Color("b8693a"), Color("5a3a30")])
		ci.draw_circle(Vector2(v.x * 0.72, 250), 70, Color(1.0, 0.55, 0.25, 0.18))   # שמש חולה מאחורי העשן
		Kit.clouds(ci, 0.0, v, t, 90.0, Color(0.2, 0.15, 0.15, 0.35), 4, 6.0)
		Kit.birds(ci, v, t, 11)
	# שכבה 1 (רחוקה): גורדי שחקים
	bg.add_layer(0.10, func(ci: CanvasItem, sc: float, v: Vector2, t: float):
		Kit.skyline(ci, sc, v, 470.0, Color("2a2430"), 51, Vector2(70, 130), Vector2(220, 380), 0.05, Color(1.0, 0.8, 0.5, 0.6), t, 0.4)
		for i in 3:   # עמודי עשן רחוקים
			var bx := fposmod(float(i) * 470.0 + 200.0 - sc, v.x + 300.0) - 150.0
			Kit.smoke_column(ci, Vector2(bx, 430), t + float(i) * 3.0, 300.0, Color(0.15, 0.12, 0.12, 0.35))
		Kit.helicopter(ci, v, t, 42.0, 150.0))
	# שכבה 2 (אמצע): בניינים פגועים עם חלונות מהבהבים ושריפות
	bg.add_layer(0.30, func(ci: CanvasItem, sc: float, v: Vector2, t: float):
		Kit.skyline(ci, sc, v, 560.0, Color("1e1a20"), 77, Vector2(90, 170), Vector2(150, 280), 0.12, Color(1.0, 0.7, 0.35, 0.8), t, 0.5)
		for i in 2:
			var fx := fposmod(float(i) * 830.0 + 400.0 - sc, v.x + 400.0) - 200.0
			Kit.fire_glow(ci, Vector2(fx, 420.0 + float(i) * 40.0), t, 60.0, i)
			Kit.smoke_column(ci, Vector2(fx, 400.0), t, 220.0, Color(0.1, 0.08, 0.08, 0.4)))
	# שכבה 3 (קרובה): גשר שבור, שלטי חוצות, עמודי חשמל עם כבלים תלויים
	bg.add_layer(0.60, func(ci: CanvasItem, sc: float, v: Vector2, t: float):
		var period := 1100.0
		var start := int(floor(sc / period)) - 1
		for k in range(start, start + 3):
			var x := float(k) * period - sc
			var r := RandomNumberGenerator.new()
			r.seed = k * 977 + 3
			# עמודי חשמל + כבלים
			for j in 3:
				var px := x + float(j) * 380.0
				ci.draw_rect(Rect2(px, 330, 6, 260), Color("161216"))
				ci.draw_line(Vector2(px - 18, 342), Vector2(px + 24, 342), Color("161216"), 3.0)
				var sag := 30.0 + sin(t * 0.8 + float(j)) * 3.0
				var pts := PackedVector2Array()
				for q in 9:
					var u := float(q) / 8.0
					pts.append(Vector2(px + 3.0 + u * 380.0, 342.0 + sin(u * PI) * sag))
				ci.draw_polyline(pts, Color(0.05, 0.05, 0.06, 0.9), 1.5)
				if r.randf() < 0.5:   # כבל קרוע תלוי
					ci.draw_line(Vector2(px + 120, 360), Vector2(px + 120 + sin(t * 1.5 + float(j)) * 6.0, 450), Color(0.05, 0.05, 0.06, 0.9), 1.5)
			# שלט חוצות שבור
			var bx := x + 560.0
			ci.draw_rect(Rect2(bx, 360, 8, 200), Color("1a161a"))
			ci.draw_colored_polygon(PackedVector2Array([Vector2(bx - 70, 300), Vector2(bx + 80, 290), Vector2(bx + 76, 370), Vector2(bx - 66, 380)]), Color("2a2228"))
			ci.draw_colored_polygon(PackedVector2Array([Vector2(bx - 60, 310), Vector2(bx + 20, 302), Vector2(bx + 10, 360), Vector2(bx - 58, 368)]), Color(0.55, 0.25, 0.15, 0.6))
			# גשר עילי שבור ברקע
			ci.draw_rect(Rect2(x + 800, 420, 260, 22), Color("1c181c"))
			ci.draw_rect(Rect2(x + 830, 442, 18, 150), Color("1c181c"))
			ci.draw_colored_polygon(PackedVector2Array([Vector2(x + 1060, 420), Vector2(x + 1100, 452), Vector2(x + 1060, 442)]), Color("1c181c"))
		Kit.ground_fade(ci, v, 570.0))
	layer.add_child(bg)
	return bg


# ---- העולם: חזיתות חנויות, קטע מוגבה, הריסות בוערות ----
func build_world() -> void:
	# חזיתות חנויות הרוסות לאורך כל הרחוב (מאחורי הכביש)
	var x := 0.0
	while x < level_w:
		var row := Storefronts.new()
		row.position = Vector2(x, floor_y)
		row.seed_v = rng.randi()
		main.add_child(row)
		x += 1024.0
	# הקטע המוגבה: גשר עילי שקרס (סולם משמאל, מכונית מתחת לקפיצה)
	var ox := level_w * 0.42
	add_floor(ox, floor_y - 150.0, 560.0, "concrete", true, true)
	add_ladder(ox + 30.0, floor_y - 150.0)
	reserve(Rect2(ox - 40.0, floor_y - 150.0, 640.0, 150.0))
	# במה קטנה נוספת: גג של קיוסק
	var kx := level_w * 0.68
	add_floor(kx, floor_y - 110.0, 200.0, "roof", true, false)
	reserve(Rect2(kx - 20.0, floor_y - 110.0, 240.0, 110.0))
	# הריסות בוערות על הכביש: סכנה קבועה
	for i in 4:
		var fx := level_w * (0.18 + 0.2 * float(i)) + rng.randf_range(-150.0, 150.0)
		if free_x(fx, 60.0):
			var fz = FireZone.new()
			fz.setup(rng.randf_range(50.0, 80.0), -1.0)
			add_hazard(fz, Vector2(fx, floor_y))
			reserve(Rect2(fx - 50.0, floor_y - 40.0, 100.0, 40.0))


func build_effects() -> void:
	screen_layer.add_child(Ambient.screen_particles("ash", vp))
	screen_layer.add_child(Ambient.screen_particles("embers", vp))
	# פסי אור ממגדלים בוערים + פנסים שבורים מהבהבים לאורך הרחוב
	var x := 600.0
	while x < level_w:
		if rng.randf() < 0.5:
			var fl = Ambient.FlickerLight.new()
			fl.color = Color(1.0, 0.75, 0.45)
			fl.radius = 70.0
			add_world(fl, Vector2(x, floor_y - 170.0))
		x += rng.randf_range(500.0, 900.0)


# זומבים על הקטע המוגבה: מטפס + סקאוט שצופה מלמעלה
func extra_spawns() -> void:
	var ox := level_w * 0.42
	spawn(Registry.SCOUT, ox + 420.0, floor_y - 150.0)
	spawn(Registry.CLIMBER, ox + 250.0, floor_y - 150.0)
	spawn(1, ox + 330.0, floor_y - 150.0)
	spawn(Registry.SCOUT, level_w * 0.68 + 100.0, floor_y - 110.0)


# ---- קישוטים ----
class Storefronts extends Node2D:
	var seed_v := 0

	func _ready() -> void:
		z_index = -3

	func _draw() -> void:
		var r := RandomNumberGenerator.new()
		r.seed = seed_v
		var x := 0.0
		var tags := ["THEY LEARN", "RUN", "NO SAFE", "WE REMEMBER", "EAT", "HELP", "X", "SECTOR 5"]
		while x < 1024.0:
			var w := r.randf_range(150.0, 230.0)
			var h := r.randf_range(150.0, 240.0)
			var wall := Color("3a3230").lerp(Color("4a3a34"), r.randf())
			draw_rect(Rect2(x, -h, w, h), wall)
			draw_rect(Rect2(x, -h, w, 6), Color("2a2422"))
			# חלון ראווה שבור
			var gw := w - 40.0
			draw_rect(Rect2(x + 20, -96, gw, 70), Color("141218"))
			for k in 6:   # שברי זכוכית
				var sx := x + 20 + r.randf_range(0, gw)
				draw_colored_polygon(PackedVector2Array([Vector2(sx, -96), Vector2(sx + r.randf_range(6, 18), -96), Vector2(sx + r.randf_range(-4, 8), -96 + r.randf_range(14, 40))]), Color(0.6, 0.7, 0.75, 0.35))
			if r.randf() < 0.5:   # תריס חצי סגור
				var sh := r.randf_range(20, 60)
				draw_rect(Rect2(x + 20, -96, gw, sh), Color("4a4a4c"))
				for q in int(sh / 5.0):
					draw_line(Vector2(x + 20, -96 + q * 5), Vector2(x + 20 + gw, -96 + q * 5), Color("383838"), 1.0)
			# סוכך קרוע
			var aw := Color(0.5 + r.randf() * 0.3, 0.15, 0.12)
			draw_colored_polygon(PackedVector2Array([Vector2(x + 10, -112), Vector2(x + w - 10, -112), Vector2(x + w - 2, -98), Vector2(x + w * 0.6, -100), Vector2(x + w * 0.5, -92), Vector2(x + 2, -98)]), aw)
			# שלט
			draw_rect(Rect2(x + 26, -140, w - 52, 20), Color("1e1a1a"))
			draw_rect(Rect2(x + 30, -136, (w - 60) * r.randf_range(0.3, 0.9), 12), Color(0.8, 0.7, 0.4, 0.4))
			# חלונות דירות למעלה
			var wy := -h + 20.0
			while wy < -150.0:
				for q in 3:
					var lit := r.randf() < 0.12
					draw_rect(Rect2(x + 22 + q * (w - 50) / 3.0, wy, 22, 18), Color(1.0, 0.75, 0.4, 0.7) if lit else Color("181418"))
				wy += 34.0
			# גרפיטי
			if r.randf() < 0.6:
				var f := ThemeDB.fallback_font
				var tag: String = tags[r.randi() % tags.size()]
				draw_string(f, Vector2(x + 24, -30 + r.randf_range(-6, 0)), tag, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color(r.randf_range(0.6, 1.0), r.randf_range(0.1, 0.4), r.randf_range(0.1, 0.5), 0.75))
			x += w + r.randf_range(0, 20)


class TrashPile extends Node2D:
	var seed_v := 0

	func _draw() -> void:
		var r := RandomNumberGenerator.new()
		r.seed = seed_v
		for i in 6:
			var c := Color(0.08, 0.08, 0.1) if r.randf() < 0.6 else Color(0.25, 0.3, 0.25)
			Art.oval_shaded(self, Vector2(10 + i * 8, -6 - (i % 2) * 5), 8.0, 6.0, c, r.randf(), Art.OUTLINE, 1.0)
		Art.fill_shaded(self, PackedVector2Array([Vector2(36, -2), Vector2(58, -4), Vector2(56, -18), Vector2(38, -16)]), Color("4a5a4a"), 0.2, 0.3)
