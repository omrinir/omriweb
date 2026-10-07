extends "res://levels/stage_base.gd"
# ============================================================
#  STAGE 9 - "THEY LEARN" (השיא)
#  עיר הרוסה ענקית בשליטת הזומבים, שמחברת את כל הסביבות: רחובות -> מפעל -> גגות ->
#  חורבות מעבדה -> אזור הזומבים (environment/s9_decor.gd -> theme_at).
#  4 גבהים: ריצפה, קומה שנייה, גגות, ומנהרות מתחת לכביש (נופלים דרך חור, עולים בסולם).
#  מסלולים: הגגות = בטוח יותר ואיטי (טיפוס). המנהרות = מסוכן, אבל שם התחמושת והנשקים.
#  זומבים: COMMANDER, HUNTER ELITE, SHIELD, INFECTOR, EVOLVED (הבוס) + זומבים קודמים
#  אפקטים: אפר, אש, עשן, הריסות נופלות, גשם קל, פיצוצים רחוקים, המון זומבים באופק
#  איך משנים: מיקום המנהרות = TUNNELS, הבניינים = _buildings(), עומק המנהרה = DEPTH
# ============================================================

const WeaponDB := preload("res://weapons/weapon_db.gd")
const Decor := preload("res://environment/s9_decor.gd")
const Haz := preload("res://environment/s9_hazards.gd")
const Fx := preload("res://effects/s9_fx.gd")
const PickupScript := preload("res://pickup.gd")

const DEPTH := 300.0
const TUNNELS := [[0.27, 0.37], [0.61, 0.71]]   # מנהרות: [התחלה, סוף] כחלק מאורך השלב
const HOLE_W := 96.0


func zombie_weights() -> Dictionary:
	return {0: 0.14, 1: 0.12, 3: 0.05, 20: 0.05, 22: 0.05, Registry.HUNTER_ELITE: 0.14, Registry.SHIELD_ELITE: 0.14,
		Registry.INFECTOR: 0.1, Registry.COMMANDER: 0.06, 29: 0.06, 32: 0.05}


func generators() -> Array:
	return [["car", 2.0], ["barrier", 1.5], ["junk", 2.5], ["barrels", 1.5], ["container", 1.0], ["sandbags", 1.0]]


# מתרס גרוטאות: מכשול + "צוואר בקבוק" שהמפקד מכין בו מארב
func custom_gen(gname: String, x: float) -> float:
	if gname != "junk":
		return 0.0
	var j = Decor.JunkPile.new()
	j.seed_v = rng.randi()
	j.theme = Decor.theme_at(x, level_w)
	j.width = rng.randf_range(56.0, 80.0)
	j.height = rng.randf_range(30.0, 44.0)
	j.position = Vector2(x, floor_y)
	main.add_child(j)
	add_block(x + 4.0, floor_y - j.height + 6.0, j.width - 8.0, j.height - 6.0, Color("2a2622"), true, 2)
	var ch := Node2D.new()
	ch.add_to_group("s9_choke")
	ch.position = Vector2(x + j.width * 0.5, floor_y)
	main.add_child(ch)
	return j.width


func boss_kind() -> int:
	return Registry.EVOLVED


func music() -> String:
	return "res://music/level1_total_war.mp3"


func world_tint() -> Color:
	return Color(0.95, 0.85, 0.8)


func pits() -> int:
	return 0


func street_props() -> bool:
	return false


func underground_depth() -> float:
	return DEPTH


func road_holes() -> Array:
	var out := []
	for tn in TUNNELS:
		out.append([level_w * float(tn[0]), HOLE_W])
		out.append([level_w * float(tn[1]) - HOLE_W, HOLE_W])
	return out


func zombie_density() -> float:
	return 1.05


# ---- רקע ענק: 4 שכבות ----
func build_background(layer: CanvasLayer) -> Node:
	var bg = Backdrop.new()
	bg.level_w = level_w
	bg.sky = func(ci: CanvasItem, v: Vector2, t: float):
		Kit.gradient_sky(ci, v, [Color("1a1018"), Color("3a1a1a"), Color("7a2a18"), Color("b04a1c"), Color("4a2418")])
		Kit.clouds(ci, 0.0, v, t, 70.0, Color(0.12, 0.08, 0.08, 0.5), 21, 9.0)
		Kit.clouds(ci, 0.0, v, t * 0.6, 150.0, Color(0.2, 0.1, 0.08, 0.35), 22, 5.0)
		Kit.birds(ci, v, t, 31)
		Kit.helicopter(ci, v, t, 33.0, 120.0)
		Kit.helicopter(ci, v, t + 17.0, 47.0, 170.0)
	# 0.06: קו רקיע רחוק עם מגדלים בוערים
	bg.add_layer(0.06, func(ci: CanvasItem, sc: float, v: Vector2, t: float):
		Kit.skyline(ci, sc, v, 430.0, Color("2a1418"), 91, Vector2(60, 120), Vector2(240, 400), 0.03, Color(1.0, 0.6, 0.3, 0.6), t, 0.6)
		for i in 3:
			var bx := fposmod(float(i) * 600.0 + 150.0 - sc, v.x + 400.0) - 200.0
			Fx.burning_tower(ci, bx, 430.0, 70.0, 300.0, Color("231216"), t, i)
		Kit.distant_explosions(ci, sc, v, t, 420.0, 6.0, 9))
	# 0.18: עיר הרוסה - שלדי גורדי שחקים, מנופים, כיפת מעבדה, המון זומבים
	bg.add_layer(0.18, func(ci: CanvasItem, sc: float, v: Vector2, t: float):
		var period := 1300.0
		var start := int(floor(sc / period)) - 1
		for k in range(start, start + int(v.x / period) + 3):
			var x := float(k) * period - sc
			Fx.skeleton_tower(ci, x + 100.0, 520.0, 110.0, 300.0, Color("1c1014"), k)
			Fx.crane(ci, x + 520.0, 520.0, 260.0, Color("1a0f12"), t)
			Fx.lab_dome(ci, x + 900.0, 520.0, 90.0, Color("1e1418"), t)
		Fx.horde(ci, sc, v, t, 515.0, Color(0.08, 0.04, 0.05, 0.85), 4))
	# 0.32: בניינים שרופים עם שריפות ועשן
	bg.add_layer(0.32, func(ci: CanvasItem, sc: float, v: Vector2, t: float):
		Kit.skyline(ci, sc, v, 570.0, Color("160c10"), 57, Vector2(100, 180), Vector2(140, 260), 0.06, Color(1.0, 0.5, 0.2, 0.8), t, 0.7)
		for i in 3:
			var fx := fposmod(float(i) * 740.0 + 300.0 - sc, v.x + 400.0) - 200.0
			Kit.fire_glow(ci, Vector2(fx, 440.0 + float(i) * 30.0), t, 70.0, i + 3)
			Kit.smoke_column(ci, Vector2(fx, 420.0), t + float(i), 280.0, Color(0.08, 0.06, 0.06, 0.45)))
	# 0.60: מבנים קרובים - זרקורים, עמודים שבורים
	bg.add_layer(0.60, func(ci: CanvasItem, sc: float, v: Vector2, t: float):
		var period := 1000.0
		var start := int(floor(sc / period)) - 1
		for k in range(start, start + 3):
			var x := float(k) * period - sc
			ci.draw_rect(Rect2(x + 200, 380, 16, 220), Color("100a0c"))
			ci.draw_colored_polygon(PackedVector2Array([Vector2(x + 190, 380), Vector2(x + 240, 360), Vector2(x + 226, 392)]), Color("100a0c"))
			Fx.searchlight(ci, Vector2(x + 640.0, 600.0), t, float(k))
		Kit.ground_fade(ci, v, 570.0))
	layer.add_child(bg)
	return bg


func build_world() -> void:
	var x := 0.0
	while x < level_w:
		var c = Decor.CityChunk.new()
		c.seed_v = rng.randi()
		c.level_w = level_w
		c.position = Vector2(x, floor_y)
		main.add_child(c)
		x += 1024.0
	var ef := EarthFill.new()
	ef.top = vp.y
	ef.depth = DEPTH + 80.0
	main.add_child(ef)
	_tunnels()
	_buildings()
	# מפעל: מסועים
	for f in [0.44, 0.5]:
		var cx: float = level_w * f
		if free_x(cx, 120.0):
			var cv = Decor.Conveyor.new()
			cv.width = 220.0
			cv.speed = -110.0 if rng.randf() < 0.5 else 110.0
			cv.position = Vector2(cx, floor_y)
			main.add_child(cv)
			reserve(Rect2(cx, floor_y - 30.0, 220.0, 30.0))
	# חורבות מעבדה: מיכלי דגימה + אזור הדבקה קבוע
	for f in [0.78, 0.84]:
		var st = Decor.SpecimenTank.new()
		st.broken = rng.randf() < 0.5
		add_world(st, Vector2(level_w * f, floor_y))
		var iz = Haz.InfectionZone.new()
		iz.setup(80.0, 100000.0, false)
		add_hazard(iz, Vector2(level_w * f + 140.0, floor_y))
	# רחובות: חזיתות שמתמוטטות מדי פעם
	for f in [0.1, 0.17, 0.55]:
		var cz = Haz.CollapseZone.new()
		cz.setup(130.0, rng.randf_range(8.0, 12.0), -250.0)
		add_hazard(cz, Vector2(level_w * f, floor_y))
		reserve(Rect2(level_w * f - 70.0, floor_y - 60.0, 140.0, 60.0))


# מנהרות מתחת לכביש: חור בכניסה, חור ביציאה, סולמות למעלה, תחמושת בפנים
func _tunnels() -> void:
	var by := floor_y + DEPTH
	for i in TUNNELS.size():
		var x0: float = level_w * float(TUNNELS[i][0])
		var x1: float = level_w * float(TUNNELS[i][1])
		var td = Decor.TunnelDecor.new()
		td.x0 = x0 - 30.0
		td.x1 = x1 + 30.0
		td.top = vp.y
		td.bottom = by
		td.lab = i == 1
		td.seed_v = rng.randi()
		main.add_child(td)
		main._make_brick(Vector2(x0 - 40.0, by), Vector2(x1 - x0 + 80.0, 60.0), 3, Color("2a2622"), false)   # ריצפת המנהרה
		main._make_brick(Vector2(x0 - 40.0, vp.y), Vector2(40.0, DEPTH), 3, Color("2a2622"), false)          # קירות קצה
		main._make_brick(Vector2(x1, vp.y), Vector2(40.0, DEPTH), 3, Color("2a2622"), false)
		add_ladder(x0 + HOLE_W * 0.5, floor_y, by)
		add_ladder(x1 - HOLE_W * 0.5, floor_y, by)
		reserve(Rect2(x0 - 60.0, floor_y - 60.0, x1 - x0 + 120.0, 60.0))
		# הפרס במסלול המסוכן
		for k in 3:
			var p = PickupScript.new()
			p.kind = [PickupScript.AMMO, PickupScript.GRENADE, PickupScript.AMMO][k]
			p.life = 100000.0
			main.add_child(p)
			p.setup(Vector2(lerpf(x0, x1, 0.3 + 0.2 * float(k)), by - 30.0), Vector2.ZERO)
		var fl = Ambient.FlickerLight.new()
		fl.color = Color(0.5, 1.0, 0.6) if i == 1 else Color(1.0, 0.8, 0.5)
		add_world(fl, Vector2((x0 + x1) * 0.5, vp.y + 6.0))


# בניינים פתוחים: קומה שנייה + גג, וגגות רצופים (המסלול הבטוח והאיטי)
func _buildings() -> void:
	var list := []
	var starts := [0.06, 0.15, 0.41, 0.5, 0.56, 0.75, 0.88]
	for f in starts:
		var bx: float = level_w * float(f)
		var w := rng.randf_range(300.0, 420.0)
		if not free_x(bx, 20.0) or not free_x(bx + w, 20.0):
			continue
		var y2 := floor_y - FLOOR2
		var yr := floor_y - ROOF
		add_floor(bx, y2, w, "concrete", false, false)
		add_floor(bx, yr, w, "roof", false, false)
		add_ladder(bx + 18.0, y2)
		add_ladder(bx + w - 18.0, yr, y2)
		list.append([bx, w, yr, [y2]])
		reserve(Rect2(bx - 10.0, yr, w + 20.0, ROOF))
	var b = Decor.Buildings.new()
	b.list = list
	b.floor_y = floor_y
	b.seed_v = rng.randi()
	main.add_child(b)
	# גגות רצופים מעל חלק מהרחובות: גשרים קצרים בין בניינים
	for i in range(list.size() - 1):
		var a: Array = list[i]
		var c: Array = list[i + 1]
		var gap: float = float(c[0]) - (float(a[0]) + float(a[1]))
		if gap > 60.0 and gap < 520.0:
			add_floor(float(a[0]) + float(a[1]) + 40.0, floor_y - ROOF + 10.0, gap - 80.0, "scaffold", false, true)


func build_effects() -> void:
	screen_layer.add_child(Ambient.screen_particles("ash", vp))
	screen_layer.add_child(Ambient.screen_particles("embers", vp))
	screen_layer.add_child(Fx.LightRain.new())
	var fd = Ambient.FallingDebris.new()
	fd.top_y = floor_y - 500.0
	fd.floor_y = floor_y
	main.add_child(fd)
	var x := 500.0
	while x < level_w:   # שריפות קטנות לאורך העיר
		if free_x(x, 30.0):
			add_fire(Vector2(x, floor_y), rng.randf_range(16.0, 26.0), rng.randf_range(20.0, 32.0))
		x += rng.randf_range(600.0, 1100.0)


func extra_spawns() -> void:
	var by := floor_y + DEPTH
	for tn in TUNNELS:   # מנהרות: מסוכן
		var x0: float = level_w * float(tn[0])
		var x1: float = level_w * float(tn[1])
		spawn(Registry.HUNTER_ELITE, lerpf(x0, x1, 0.45), by)
		spawn(Registry.INFECTOR, lerpf(x0, x1, 0.7), by)
		spawn(1, lerpf(x0, x1, 0.3), by)
	# מפקדים עם חוליות לאורך השלב
	for f in [0.22, 0.48, 0.8]:
		var cx: float = level_w * f
		spawn(Registry.COMMANDER, cx, floor_y)
		spawn(Registry.SHIELD_ELITE, cx - 80.0, floor_y)
		spawn(0, cx + 70.0, floor_y)
		spawn(1, cx + 120.0, floor_y)
	# זומבים על הגגות (מעטים - זה המסלול הבטוח)
	for p in main.get_children():
		if p.is_in_group("platforms") and p.style == "roof" and rng.randf() < 0.4:
			spawn(Registry.HUNTER_ELITE, p.position.x + p.size.x * 0.5, p.position.y)


# אדמה כהה מתחת לכביש (רואים אותה כשהמצלמה יורדת למנהרה)
class EarthFill extends Node2D:
	var top := 720.0
	var depth := 380.0

	func _ready() -> void:
		z_index = -6

	func _process(_d: float) -> void:
		queue_redraw()

	func _draw() -> void:
		var cam := get_viewport().get_camera_2d()
		if cam == null:
			return
		var cx := cam.get_screen_center_position().x
		draw_rect(Rect2(cx - 800.0, top, 1600.0, depth), Color("1a1512"))
		for i in 8:
			draw_rect(Rect2(cx - 800.0, top + float(i) * 40.0 + 10.0, 1600.0, 2.0), Color(0, 0, 0, 0.25))
