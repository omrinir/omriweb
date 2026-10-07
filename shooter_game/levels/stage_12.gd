extends "res://levels/stage_base.gd"
# ============================================================
#  STAGE 12 - "THE LIGHTHOUSE" (אזור צפון-מזרח, שלב 3) - "THEY WEAR OUR FACES"
#  הכפר הקבור: כפר דייגים בחוף סיארה שהדיונות בלעו (השראה: טטז'ובה). שקיעה אדומה-דם,
#  ערפל ים כבד, מגדלור על הכף שהאלומה שלו עוברת בערפל, ספינה טרופה, כנסייה שרק המגדל
#  שלה מבצבץ מהחול, בית קברות של צלבי עץ על הדיונה, רשתות דייגים, עיניים בחלונות החשוכים.
#  שתי קומות - רק בחלק מהשלב: גגות של בתים קבורים (BURIED). יורדים: S פעמיים.
#  זומבים: MIMIC (נראית בדיוק כמו הניצולה ומשתנה באמצע הדרך אליך!), IRONWING (כנפיים רובוטיות),
#    SPARE PARTS (זורק את היד, תולש וזורק את הרגליים, זוחל ותופס), SPLITJAW, WALKER, RUNNER.
#  ניצולות אמיתיות (3) + מתחזות במקומות דומים - צריך להחליט את מי להציל.
#  בוס: IRONWING ענק - "THE IRON ANGEL".
#  סכנה: חול טובעני (מאט מאוד, שוקעים אם נשארים).
#  לשנות: BURIED, MIMICS, zombie_weights().
# ============================================================

const WeaponDB := preload("res://weapons/weapon_db.gd")
const Decor := preload("res://effects/s12_decor.gd")
const Hz := preload("res://environment/s12_hazards.gd")
const S10Decor := preload("res://effects/s10_decor.gd")

const BURIED := [[0.3, 420.0], [0.66, 520.0]]   # [מיקום יחסי, אורך] גגות הבתים הקבורים
const ROOF_H := 130.0
const MIMICS := [0.18, 0.42, 0.58, 0.83]       # מתחזות שעומדות כמו ניצולות


func zombie_weights() -> Dictionary:
	return {0: 0.16, 1: 0.12, Registry.MIMIC: 0.08, Registry.IRONWING: 0.16, Registry.SPARE_PARTS: 0.2, Registry.SPLITJAW: 0.1}


func generators() -> Array:
	return [["jangada", 2.0], ["barrels", 1.0], ["crates", 1.2], ["sacks", 1.0], ["tires", 0.8]]


func custom_gen(gname: String, x: float) -> float:
	if not gname in ["jangada", "sacks"]:
		return 0.0
	var o := S10Decor.Obstacle.new()   # רפסודות שננטשו על החול, שקי דגים מלוחים
	o.kind = gname
	o.label = "PEIXE"
	o.seed_v = rng.randi()
	o.size = Vector2(rng.randf_range(110.0, 140.0), 24.0) if gname == "jangada" else Vector2(rng.randf_range(3.0, 4.0) * 22.0, 28.0)
	o.position = Vector2(x, floor_y)
	main.add_child(o)
	reserve(Rect2(x, floor_y - o.size.y, o.size.x, o.size.y))
	return o.size.x


func boss_kind() -> int:
	return Registry.IRONWING


func music() -> String:
	return "res://music/level2_suspense.mp3"


func world_tint() -> Color:
	return Color(0.92, 0.74, 0.7)   # אור שקיעה אדום


func fog() -> bool:
	return true


func pits() -> int:
	return 1


# ---- רקע ----
func build_background(layer: CanvasLayer) -> Node:
	var bg = Backdrop.new()
	bg.level_w = level_w
	bg.sky = func(ci: CanvasItem, v: Vector2, t: float):
		Kit.gradient_sky(ci, v, [Color("1a0a14"), Color("3a1020"), Color("7a1e1e"), Color("b8401e"), Color("d8702a")])
		var sun := Vector2(v.x * 0.62, 452.0)
		for i in 5:
			ci.draw_circle(sun, 160.0 - float(i) * 26.0, Color(1.0, 0.35, 0.15, 0.05 + float(i) * 0.03))
		ci.draw_circle(sun, 52.0, Color("ff6a3a"))
		Kit.clouds(ci, 0.0, v, t, 150.0, Color(0.16, 0.05, 0.08, 0.55), 31, 4.0)
		Kit.birds(ci, v, t, 17, Color(0.05, 0.02, 0.02, 0.85), 9)   # עורבים
	# שכבה 1: ים בוער, השמש שוקעת, ספינה טרופה, המגדלור על הכף
	bg.add_layer(0.10, func(ci: CanvasItem, sc: float, v: Vector2, t: float):
		ci.draw_rect(Rect2(0, 452, v.x, 80), Color("3a1418"))
		var r0 := RandomNumberGenerator.new()
		r0.seed = 12
		for i in 30:   # השתקפות השמש בגלים
			var gx := v.x * 0.62 + r0.randf_range(-120.0, 120.0) * (1.0 + float(i) * 0.03)
			var gy := 456.0 + float(i) * 2.4
			if sin(t * 2.0 + float(i)) > -0.2:
				ci.draw_line(Vector2(gx, gy), Vector2(gx + r0.randf_range(8.0, 24.0), gy), Color(1.0, 0.45, 0.2, 0.55), 1.5)
		var period := 1600.0
		var start := int(floor(sc / period)) - 1
		for k in range(start, start + 3):
			var x := float(k) * period - sc
			Decor.shipwreck(ci, Vector2(x + 300.0, 478.0), 0.9, Color("1a0a0e"))
			ci.draw_colored_polygon(PackedVector2Array([Vector2(x + 1000, 532), Vector2(x + 1080, 470), Vector2(x + 1200, 455), Vector2(x + 1320, 470), Vector2(x + 1400, 532)]), Color("24101a"))   # הכף
			var lit := maxf(0.0, sin(t * 0.55)) ** 6.0
			Decor.lighthouse(ci, Vector2(x + 1200.0, 460.0), 120.0, t, lit))
	# שכבה 2: דיונות ענק שבולעות את הכפר, הכנסייה הקבורה, בית הקברות
	bg.add_layer(0.30, func(ci: CanvasItem, sc: float, v: Vector2, t: float):
		var period := 1300.0
		var start := int(floor(sc / period)) - 1
		for k in range(start, start + 3):
			var x := float(k) * period - sc
			var r := RandomNumberGenerator.new()
			r.seed = k * 211 + 3
			if k % 2 == 0:
				Decor.buried_church(ci, Vector2(x + 650.0, 560.0), 1.0, Color("2a1418"))
			for q in 3:
				var hx := x + r.randf_range(0.0, period)
				ci.draw_rect(Rect2(hx, 535.0, r.randf_range(40.0, 70.0), 30.0), Color("301a1c"))   # גגות מבצבצים
				ci.draw_colored_polygon(PackedVector2Array([Vector2(hx - 4, 535), Vector2(hx + 64, 535), Vector2(hx + 30, 520)]), Color("301a1c"))
			Decor.dune(ci, x - 100.0, 600.0, 760.0, 90.0, Color("6a3a2a"))
			Decor.dune(ci, x + 520.0, 600.0, 900.0, 70.0, Color("5a3024"))
			for q in 5:   # צלבים על הדיונה
				var cx := x + 150.0 + float(q) * 40.0
				Decor.cross(ci, Vector2(cx, 560.0 - sin(float(q) * 0.7) * 10.0), 20.0, Color("1e0e10"), sin(float(q + k) * 1.3) * 0.25)
		Kit.ground_fade(ci, v, 580.0))
	# שכבה 3: עמודי עץ שבורים, רשתות, עצים מתים (קרוב)
	bg.add_layer(0.60, func(ci: CanvasItem, sc: float, v: Vector2, t: float):
		var period := 950.0
		var start := int(floor(sc / period)) - 1
		var dark := Color("140808")
		for k in range(start, start + 3):
			var x := float(k) * period - sc
			var r := RandomNumberGenerator.new()
			r.seed = k * 733 + 2
			for q in 2:   # עץ קרנאובה מת (בלי כתר)
				var tx := x + r.randf_range(0.0, period)
				ci.draw_line(Vector2(tx, 640), Vector2(tx + r.randf_range(-20, 20), 420), dark, 5.0)
				for b in 3:
					var by := 440.0 + float(b) * 12.0
					ci.draw_line(Vector2(tx, by), Vector2(tx + (16.0 if b % 2 == 0 else -16.0), by - 10.0 + sin(t + float(b)) * 2.0), dark, 2.0)
			for q in 6:   # עמודי גדר שבורים
				var fx := x + 500.0 + float(q) * 30.0
				ci.draw_line(Vector2(fx, 640), Vector2(fx + r.randf_range(-6, 6), 590.0 + r.randf_range(-10, 10)), dark, 3.0)
		Kit.ground_fade(ci, v, 575.0))
	layer.add_child(bg)
	return bg


# ---- העולם ----
func build_world() -> void:
	var spans := []
	for b in BURIED:
		var ox := level_w * float(b[0])
		var w: float = b[1]
		var house := Decor.BuriedHouse.new()
		house.w = w
		house.h = ROOF_H
		house.seed_v = rng.randi()
		add_world(house, Vector2(ox, floor_y))
		add_floor(ox, floor_y - ROOF_H, w, "roof", false, false)
		add_ladder(ox + 20.0, floor_y - ROOF_H)
		add_ladder(ox + w - 20.0, floor_y - ROOF_H)
		reserve(Rect2(ox - 40.0, floor_y - ROOF_H, w + 80.0, ROOF_H))
		spans.append([ox, ox + w])
	var x := 0.0
	while x < level_w:
		var row := Decor.Village.new()
		row.position = Vector2(x, floor_y)
		row.seed_v = rng.randi()
		for s in spans:
			row.skip.append([float(s[0]) - x, float(s[1]) - x])
		main.add_child(row)
		x += 1024.0
	# חול טובעני
	var placed := 0
	var tries := 0
	while placed < 4 and tries < 40:
		tries += 1
		var qx := level_w * rng.randf_range(0.12, 0.88)
		if not free_x(qx, 90.0) or main._in_pit(qx - 80.0, qx + 80.0, 20.0):
			continue
		var q := Hz.QuickSand.new()
		q.width = rng.randf_range(100.0, 150.0)
		add_hazard(q, Vector2(qx, floor_y))
		reserve(Rect2(qx - 80.0, floor_y - 30.0, 160.0, 30.0))
		placed += 1


func build_effects() -> void:
	var sand := Ambient.screen_particles("dust", vp)   # חול שעף ברוח
	sand.color = Color(0.9, 0.7, 0.5, 0.3)
	sand.direction = Vector2(-1, 0.05)
	sand.initial_velocity_min = 40.0
	sand.initial_velocity_max = 90.0
	screen_layer.add_child(sand)
	var fog := Decor.FogBanks.new()
	fog.vp = vp
	screen_layer.add_child(fog)


# מתחזות שעומדות בדיוק כמו ניצולות, ספייר-פארטס על הגגות
func extra_spawns() -> void:
	for f: float in MIMICS:
		var mx := level_w * f + rng.randf_range(-120.0, 120.0)
		if not main._in_pit(mx - 30.0, mx + 30.0, 10.0):
			spawn(Registry.MIMIC, mx)
	for b in BURIED:
		spawn(Registry.SPARE_PARTS, level_w * float(b[0]) + float(b[1]) * 0.5, floor_y - ROOF_H)
