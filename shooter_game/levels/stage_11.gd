extends "res://levels/stage_base.gd"
# ============================================================
#  STAGE 11 - "SUN-BLEACHED TOWN" (אזור צפון-מזרח, שלב 2) - "THEY HUNGER TOGETHER"
#  עיירת סרטאו (המדבר-למחצה של צפון-מזרח ברזיל) בלילה של חג סאו ז'ואאו:
#  בתי אדובי מסוידים ודהויים, כנסייה לבנה, שפאדה (הרים שטוחים) באופק, קקטוסים, משאבות-רוח,
#  דגלוני ז'ונינה צבעוניים מעל הרחוב ומדורות.
#  לילה: חושך אמיתי (effects/s11_decor.gd -> NightOverlay). אור רק ליד פנסי רחוב ומדורות.
#    יורים בנורה של פנס = הפנס כבה -> חושך -> הזומבים רואים אותך פחות (וגם אתה אותם).
#  שתי קומות - רק בחלק מהשלב: שלושה קטעים של גגות שטוחים (ROOFS), עולים בסולם,
#    יורדים: S פעמיים מהר.
#  זומבים: DEVOURER (בולע זומבים וגדל), SPLITJAW (מתחזה לגופה, הראש נפתח, מזנק),
#    SCOUT (מזעיק את כולם כשהוא רואה אותך - יושב על הגגות), WALKER, RUNNER.
#  בוס: DEVOURER ענק - "THE GLUTTON" (סביבו זומבים שהוא בולע וגדל).
#  סכנות: מדורות (אש), שיחי קקטוס קוצניים על הכביש.
#  לשנות: ROOFS, LAMP_GAP, zombie_weights().
# ============================================================

const WeaponDB := preload("res://weapons/weapon_db.gd")
const Decor := preload("res://effects/s11_decor.gd")
const LampScript := preload("res://street_lamp.gd")

const ROOFS := [[0.2, 520.0], [0.47, 640.0], [0.74, 460.0]]   # [מיקום יחסי, אורך] של הגגות
const ROOF_H := 150.0
const LAMP_GAP := Vector2(380.0, 620.0)


func zombie_weights() -> Dictionary:
	return {0: 0.18, 1: 0.12, Registry.SCOUT: 0.12, Registry.DEVOURER: 0.18, Registry.SPLITJAW: 0.2, 16: 0.06}


func generators() -> Array:
	return [["barrels", 1.2], ["crates", 1.2], ["cart", 1.5], ["sacks", 1.5], ["tires", 0.8], ["car", 1.0]]


func custom_gen(gname: String, x: float) -> float:
	if not gname in ["sacks", "cart"]:
		return 0.0
	var o := S10Decor.Obstacle.new()   # עגלת חמור / שקי קמח מהשלב הקודם
	o.kind = gname
	o.label = "MILHO"   # תירס של חג סאו ז'ואאו
	o.seed_v = rng.randi()
	o.size = Vector2(rng.randf_range(70.0, 90.0), 40.0) if gname == "cart" else Vector2(rng.randf_range(3.0, 4.0) * 22.0, 28.0)
	o.position = Vector2(x, floor_y)
	main.add_child(o)
	reserve(Rect2(x, floor_y - o.size.y, o.size.x, o.size.y))
	return o.size.x + (30.0 if gname == "cart" else 0.0)

const S10Decor := preload("res://effects/s10_decor.gd")


func weapon_offers() -> Array:
	return [WeaponDB.SMG, WeaponDB.ASSAULT_SHOTGUN, WeaponDB.MOLOTOV]


func boss_kind() -> int:
	return Registry.DEVOURER


func music() -> String:
	return "res://music/level2_suspense.mp3"


func world_tint() -> Color:
	return Color(0.62, 0.66, 0.86)   # אור ירח כחלחל


func dark_level() -> bool:
	return true


func fog() -> bool:
	return false


func street_lamps() -> bool:
	return false   # הפנסים מוצבים כאן (לא מתחת לגגות)


func pits() -> int:
	return 1


# ---- רקע: לילה מדברי ----
func build_background(layer: CanvasLayer) -> Node:
	var bg = Backdrop.new()
	bg.level_w = level_w
	bg.sky = func(ci: CanvasItem, v: Vector2, t: float):
		Kit.gradient_sky(ci, v, [Color("060a1c"), Color("0e1634"), Color("1c2648"), Color("34365a"), Color("4a3e5a")])
		Decor.stars(ci, v, t, 0.0)
		Decor.moon(ci, Vector2(v.x * 0.24, 130.0))
		var sh := fmod(t, 11.0)   # כוכב נופל
		if sh < 0.6:
			var a := Vector2(v.x * 0.7 - sh * 500.0, 60.0 + sh * 160.0)
			ci.draw_line(a, a + Vector2(60, -20), Color(1, 1, 1, 0.6 * (1.0 - sh / 0.6)), 1.5)
	# שכבה 1: שפאדה (הרים שטוחים) + משאבות-רוח רחוקות
	bg.add_layer(0.10, func(ci: CanvasItem, sc: float, v: Vector2, t: float):
		var period := 1400.0
		var start := int(floor(sc / period)) - 1
		for k in range(start, start + 3):
			var x := float(k) * period - sc
			var r := RandomNumberGenerator.new()
			r.seed = k * 71 + 9
			Decor.mesa(ci, x - 50.0, 520.0, r.randf_range(500.0, 700.0), r.randf_range(90.0, 140.0), Color("1a1c34"))
			Decor.mesa(ci, x + 650.0, 520.0, r.randf_range(400.0, 600.0), r.randf_range(60.0, 100.0), Color("1e2038"))
			for q in 3:
				Decor.windpump(ci, Vector2(x + 200.0 + float(q) * 420.0, 530.0), 70.0, t, float(q + k), Color(0.12, 0.12, 0.2, 0.9))
		ci.draw_rect(Rect2(0, 520, v.x, 60), Color("1a1a2e")))
	# שכבה 2: הכנסייה, שורת בתים עם חלונות מוארים, עצי ז'ואזיירו
	bg.add_layer(0.30, func(ci: CanvasItem, sc: float, v: Vector2, t: float):
		var period := 1200.0
		var start := int(floor(sc / period)) - 1
		for k in range(start, start + 3):
			var x := float(k) * period - sc
			var r := RandomNumberGenerator.new()
			r.seed = k * 313 + 5
			var lit := Color(1.0, 0.72, 0.35, 0.85)
			if k % 2 == 0:
				Decor.church(ci, Vector2(x + 600.0, 575.0), 1.0, Color("2a2a40"), lit)
			var hx := x
			while hx < x + period:
				var w := r.randf_range(60.0, 110.0)
				if k % 2 != 0 or absf(hx + w * 0.5 - (x + 600.0)) > 120.0:
					Decor.adobe_silhouette(ci, hx, 585.0, w, r.randf_range(40.0, 70.0), Color("24243a"), r, lit)
				hx += w + r.randf_range(10.0, 60.0)
			for q in 3:   # עץ ז'ואזיירו (צמרת עגולה)
				var tx := x + r.randf_range(0.0, period)
				ci.draw_line(Vector2(tx, 590), Vector2(tx, 545), Color("1c1c2c"), 4.0)
				for c in 4:
					ci.draw_circle(Vector2(tx - 14.0 + float(c) * 9.0, 535.0 - float(c % 2) * 8.0), 14.0, Color("1c2230"))
		Kit.ground_fade(ci, v, 585.0))
	# שכבה 3: קקטוסים, גדרות מקלות, עמודי חשמל עם דגלונים רחוקים
	bg.add_layer(0.60, func(ci: CanvasItem, sc: float, v: Vector2, t: float):
		var period := 900.0
		var start := int(floor(sc / period)) - 1
		var dark := Color("10121e")
		for k in range(start, start + 3):
			var x := float(k) * period - sc
			var r := RandomNumberGenerator.new()
			r.seed = k * 919 + 1
			for q in 3:
				S10Decor.mandacaru(ci, Vector2(x + r.randf_range(0.0, period), 640.0), r.randf_range(90.0, 160.0), dark)
			for q in 14:   # גדר מקלות
				var fx := x + 300.0 + float(q) * 14.0
				ci.draw_line(Vector2(fx, 640), Vector2(fx + r.randf_range(-2, 2), 600.0 + r.randf_range(-6, 4)), dark, 2.5)
			ci.draw_line(Vector2(x + 300, 615), Vector2(x + 496, 618), dark, 1.5)
			var px := x + 700.0
			ci.draw_rect(Rect2(px, 420, 5, 220), dark)
			Decor.bunting_line(ci, Vector2(px + 2, 430), Vector2(px + 380, 440), t, 30.0, k, 0.55)
		Kit.ground_fade(ci, v, 580.0))
	layer.add_child(bg)
	return bg


# ---- העולם ----
func build_world() -> void:
	var roof_spans := []   # [x0, x1] גלובליים
	for rf in ROOFS:
		var ox := level_w * float(rf[0])
		var w: float = rf[1]
		var house := Decor.RoofHouse.new()
		house.w = w
		house.h = ROOF_H
		house.seed_v = rng.randi()
		add_world(house, Vector2(ox, floor_y))
		add_floor(ox, floor_y - ROOF_H, w, "roof", false, true)
		add_ladder(ox + 18.0, floor_y - ROOF_H)
		add_ladder(ox + w - 18.0, floor_y - ROOF_H)
		reserve(Rect2(ox - 40.0, floor_y - ROOF_H, w + 80.0, ROOF_H))
		roof_spans.append([ox, ox + w])
	var x := 0.0
	while x < level_w:   # רחוב הבתים מאחורי הכביש (לא מאחורי בתי-הגג)
		var row := Decor.Town.new()
		row.position = Vector2(x, floor_y)
		row.seed_v = rng.randi()
		for s in roof_spans:
			row.skip.append([float(s[0]) - x, float(s[1]) - x])
		main.add_child(row)
		x += 1024.0
	# פנסי רחוב (אפשר לירות בנורה) - לא מתחת לגגות
	var lx := rng.randf_range(300.0, 500.0)
	while lx < level_w - 300.0:
		var under := false
		for s in roof_spans:
			if lx > float(s[0]) - 60.0 and lx < float(s[1]) + 60.0:
				under = true
		if not under and not main._in_pit(lx - 40.0, lx + 40.0, 20.0):
			var lamp = LampScript.new()
			lamp.light_color = Color(1.0, 0.74, 0.4)
			lamp.position = Vector2(lx, floor_y)
			main.add_child(lamp)
		lx += rng.randf_range(LAMP_GAP.x, LAMP_GAP.y)
	# דגלוני ז'ונינה מעל הרחוב
	var bx := 600.0
	while bx < level_w - 800.0:
		var b := Decor.Bunting.new()
		b.w = rng.randf_range(380.0, 560.0)
		b.h = 215.0
		b.seed_v = rng.randi() % 50
		add_world(b, Vector2(bx, floor_y))
		bx += b.w + rng.randf_range(500.0, 1100.0)
	# מדורות סאו ז'ואאו + שיחי קקטוס על הכביש
	for i in 7:
		var hx := level_w * rng.randf_range(0.1, 0.9)
		if not free_x(hx, 70.0) or main._in_pit(hx - 60.0, hx + 60.0, 20.0):
			continue
		if i % 2 == 0:
			add_world(Decor.Bonfire.new(), Vector2(hx, floor_y))
			reserve(Rect2(hx - 40.0, floor_y - 40.0, 80.0, 40.0))
		else:
			var c := Decor.CactusPatch.new()
			c.width = rng.randf_range(48.0, 72.0)
			c.seed_v = rng.randi()
			add_hazard(c, Vector2(hx, floor_y))
			reserve(Rect2(hx - 45.0, floor_y - 30.0, 90.0, 30.0))


func build_effects() -> void:
	var dust := Ambient.screen_particles("dust", vp)   # אבק מדבר קריר
	dust.color = Color(0.8, 0.82, 1.0, 0.18)
	screen_layer.add_child(dust)
	main.add_child(Decor.NightOverlay.new())


# סקאוטים על הגגות (רואים רחוק ומזעיקים), גופות-פיתיון ליד מדורות, ארוחה לבוס
func extra_spawns() -> void:
	for rf in ROOFS:
		var ox := level_w * float(rf[0])
		spawn(Registry.SCOUT, ox + float(rf[1]) * 0.6, floor_y - ROOF_H)
	spawn(Registry.SPLITJAW, level_w * 0.47 + 300.0, floor_y - ROOF_H)
	for i in 3:   # הבוס בולע את אלה ומתחזק - כדאי להרוג אותם קודם
		spawn(0, level_w - 620.0 - float(i) * 70.0)
