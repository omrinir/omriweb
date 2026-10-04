extends "res://levels/stage_base.gd"
# ============================================================
#  STAGE 9 - "THEY LEARN" (השיא)
#  "At first I was fighting zombies. Now the zombies are fighting ME."
#  עיר הרוסה ענקית בשליטת הזומבים, שמחברת את כל הסביבות הקודמות - משמאל לימין:
#    1. רחובות (0-20%)       - בנייני דירות שרופים, מרפסת בקומה 2, שריפות, תקרה מתמוטטת
#    2. מפעל (20-40%)        - מסלול גשרי פלדה בקומה 2 (בטוח אבל איטי), מסוע, אדים,
#                              ומתחת לכביש: מנהרה A (מסוכנת - אבל עם נשק ותחמושת)
#    3. גגות (40-57%)        - בניינים פתוחים: קומה 2 + גגות (320 מעל הכביש) עם קפיצות
#                              בין הגגות; למטה ברחוב: חוליית COMMANDER עם מגנים
#    4. חורבות מעבדה (57-75%) - קומת מעבדה עליונה, ומתחת: מנהרה B (מעבדה תת-קרקעית,
#                              בריכות הדבקה, מיכלי דגימה, EVOLVED "בורח", ותחמושת)
#    5. אזור הזומבים (75-100%) - מתרסים, טוטמים, עמדת תצפית, חוליית פיקוד ליד היציאה,
#                              והבוס: THE EVOLVED
#  מסלולים: למעלה (בטוח יותר, איטי - צריך לטפס) / ברחוב (ישיר, מלא אויבים) /
#    מתחת (חורים בכביש -> המצלמה יורדת; מסוכן אבל מלא תחמושת; סולמות חזרה למעלה).
#  רקע: 4 שכבות + שמיים (קו רקיע רחוק עם זרקורים ומסוק, מגדלים בוערים ושלדים,
#    עיר הרוסה עם מנוף / כיפת מעבדה / המון זומבים שצועד על גשר, מבנים קרובים עם שלט מהבהב).
#  אפקטים: אפר, גצים, גשם קל, שריפות, עשן, פסולת נופלת, פיצוצים רחוקים, ניצוצות, אדים.
#  סכנות: אש, תקרות מתמוטטות (environment/s9_hazards.gd -> CollapseZone), אזורי הדבקה
#    (INFECTOR + בריכות קבועות), אדים רותחים, חורים בכביש.
#  זומבים: COMMANDER, HUNTER ELITE, SHIELD ELITE, INFECTOR, EVOLVED (+ רגילים, CLIMBER, SCOUT)
#  התקדמות ה-AI: תיאום מתקדם (פקודות, תגבורת) וזיהוי הרגלים של השחקן (EVOLVED).
#  איך משנים: מיקומי הקטעים = שברים של level_w (HOLE_F, ובפונקציות build_*),
#    עומק המנהרה = DEPTH, אילו זומבים = zombie_weights + extra_spawns.
# ============================================================

const FireZone := preload("res://environment/fire_zone.gd")
const AcidPool := preload("res://environment/acid_pool.gd")
const WeaponDB := preload("res://weapons/weapon_db.gd")
const PickupScript := preload("res://pickup.gd")
const Hz := preload("res://environment/s9_hazards.gd")
const Decor := preload("res://environment/s9_decor.gd")
const S9Fx := preload("res://effects/s9_fx.gd")

const SOUNDS := {
	"s9_creak": [["W", 90, 70, 0.0, 0.9, 0.1, 2.0, 0.35, 0.2, 0.05], ["N", 0, 0, 0.0, 0.9, 0.1, 3.0, 0.25, 0.3, 0, 0.2], ["S", 420, 380, 0.1, 0.6, 0.1, 3.0, 0.08, 1.0, 0.04]],
	"s9_crash": {"rev": 0.3, "drive": 2.4, "layers": [["N", 0, 0, 0.0, 0.9, 0.0, 4.0, 1.2, 0.15, 0], ["S", 70, 30, 0.0, 0.6, 0.0, 5.0, 1.0, 1.0, 0], ["C", 0, 0, 0.0, 0.8, 0.0, 3.0, 0.6, 1.0, 0]]},
}

const DEPTH := 300.0                              # עומק המנהרה מתחת לכביש
const HOLE_W := 170.0
const HOLE_F := [0.23, 0.36, 0.60, 0.715]         # חורים בכביש: מנהרה A = 0-1, מנהרה B = 2-3


func _holes() -> Array:
	var out := []
	for f in HOLE_F:
		out.append([roundf(level_w * float(f)), HOLE_W])
	return out


func road_holes() -> Array:
	return _holes()


func underground_depth() -> float:
	return DEPTH


func zombie_weights() -> Dictionary:
	return {0: 0.12, 1: 0.14, 2: 0.05, 4: 0.03, Registry.CLIMBER: 0.05, Registry.SCOUT: 0.04, Registry.COMMANDER: 0.05,
		Registry.HUNTER_ELITE: 0.14, Registry.SHIELD_ELITE: 0.12, Registry.INFECTOR: 0.1, Registry.EVOLVED: 0.0}


func generators() -> Array:
	return [["car", 2.5], ["barrels", 1.5], ["barrier", 1.5], ["sandbags", 1.0], ["rubble", 1.5], ["bus", 0.8], ["crates", 1.0], ["s9_junk", 2.2]]


# ערימת גרוטאות לפי הקטע (חביות במפעל, ארון במעבדה, מתרס עם יתדות באזור הזומבים)
func custom_gen(gname: String, x: float) -> float:
	if gname != "s9_junk":
		return 0.0
	var j := Decor.JunkPile.new()
	j.theme = Decor.theme_at(x, level_w)
	j.seed_v = rng.randi()
	j.width = rng.randf_range(52.0, 70.0)
	j.height = 40.0 if j.theme != 0 else 30.0
	j.position = Vector2(x, floor_y)
	main.add_child(j)
	add_block(x + 4.0, floor_y - j.height, j.width - 8.0, j.height, Color("2a2a26"), true, 1)
	return j.width


func weapon_offers() -> Array:
	return [WeaponDB.ASSAULT_RIFLE, WeaponDB.SNIPER, WeaponDB.GRENADE_LAUNCHER]


func boss_kind() -> int:
	return Registry.EVOLVED


func music() -> String:
	return "res://music/level1_total_war.mp3"


func world_tint() -> Color:
	return Color(0.95, 0.85, 0.8)


func street_props() -> bool:
	return true


func street_lamps() -> bool:
	return false


func pits() -> int:
	return 0


# ============================================================
#  מצלמה: על הכביש - כמו בשלב רגיל (תחתית המסך = תחתית הכביש). נופלים לחור ->
#  המצלמה יורדת בהדרגה ומראה את המנהרה. (main.gd מגדיל את limit_bottom ומפעיל drag אנכי,
#  אבל ה-offset שלו לא נכנס לתוקף עם ה-drag, אז מתקנים כאן בזמן ריצה בלי לגעת ב-main.gd)
# ============================================================
var _cam: Camera2D = null
var cam_under := false     # לבדיקות: המצלמה במצב "מתחת לאדמה"


func _process(delta: float) -> void:
	var pl: Node2D = main._player if main != null else null
	if pl == null or not is_instance_valid(pl):
		return
	if _cam == null or not is_instance_valid(_cam):
		_cam = pl.get_viewport().get_camera_2d()
		if _cam == null:
			return
		_cam.drag_vertical_enabled = false
		_cam.offset.y = _target_offset(pl.global_position.y)
	var py: float = pl.global_position.y
	_cam.offset.y = lerpf(_cam.offset.y, _target_offset(py), 1.0 - exp(-7.0 * delta))


func _target_offset(py: float) -> float:
	var half: float = vp.y * 0.5 / maxf(_cam.zoom.y, 0.01)
	cam_under = py > floor_y + 40.0
	var bottom := floor_y + 90.0 + (DEPTH if cam_under else 0.0)
	var center := minf(py - 40.0, bottom - half)
	return center - py


# ============================================================
#  רקע: שמיים + 4 שכבות פרלקסה
# ============================================================
func build_background(layer: CanvasLayer) -> Node:
	var bg = Backdrop.new()
	bg.level_w = level_w
	bg.sky = func(ci: CanvasItem, v: Vector2, t: float):
		Kit.gradient_sky(ci, v, [Color("160e1c"), Color("341826"), Color("6e2622"), Color("b44a28"), Color("5e2c26")])
		ci.draw_circle(Vector2(v.x * 0.28, 300), 90, Color(1.0, 0.35, 0.15, 0.10))   # שמש אדומה ענקית מאחורי העשן
		ci.draw_circle(Vector2(v.x * 0.28, 300), 55, Color(1.0, 0.45, 0.2, 0.22))
		Kit.clouds(ci, 0.0, v, t, 70.0, Color(0.12, 0.07, 0.08, 0.45), 11, 5.0)
		Kit.clouds(ci, 0.0, v, t, 170.0, Color(0.25, 0.12, 0.1, 0.3), 12, 11.0)
		Kit.birds(ci, v, t, 19)
		Kit.birds(ci, v, t + 9.0, 23, Color(0.05, 0.04, 0.05, 0.7), 5)
	# שכבה 1 (הכי רחוקה): קו רקיע, עמודי עשן ענקיים, זרקורים, מסוק
	bg.add_layer(0.06, func(ci: CanvasItem, sc: float, v: Vector2, t: float):
		for i in 2:
			S9Fx.searchlight(ci, Vector2(fposmod(float(i) * 900.0 + 300.0 - sc, v.x + 400.0) - 200.0, 470.0), t, float(i) * 2.0)
		Kit.skyline(ci, sc, v, 480.0, Color("231a26"), 91, Vector2(60, 120), Vector2(180, 360), 0.04, Color(1.0, 0.6, 0.35, 0.6), t, 0.5)
		for i in 3:
			var bx := fposmod(float(i) * 520.0 + 120.0 - sc, v.x + 400.0) - 200.0
			Kit.smoke_column(ci, Vector2(bx, 440), t + float(i) * 4.0, 380.0, Color(0.1, 0.07, 0.07, 0.45), 90.0)
		Kit.distant_explosions(ci, sc, v, t, 470.0, 6.0, 7)
		Kit.helicopter(ci, v, t, 46.0, 130.0))
	# שכבה 2: מגדלים בוערים ושלדי גורדי שחקים
	bg.add_layer(0.14, func(ci: CanvasItem, sc: float, v: Vector2, t: float):
		var period := 640.0
		var start := int(floor(sc / period)) - 1
		for k in range(start, start + int(v.x / period) + 3):
			var x := float(k) * period - sc
			var r := RandomNumberGenerator.new()
			r.seed = k * 733 + 41
			var c := Color("1d1520")
			if r.randf() < 0.55:
				S9Fx.burning_tower(ci, x + r.randf_range(0, 200), 520.0, r.randf_range(90, 140), r.randf_range(240, 360), c, t, k)
			else:
				S9Fx.skeleton_tower(ci, x + r.randf_range(0, 200), 520.0, r.randf_range(110, 160), r.randf_range(220, 340), c, k)
			if r.randf() < 0.6:
				Kit.smoke_column(ci, Vector2(x + 300, 300), t + float(k), 260.0, Color(0.12, 0.09, 0.09, 0.35), 70.0)
		Kit.distant_explosions(ci, sc, v, t + 3.0, 500.0, 9.0, 13)
		Kit.helicopter(ci, v, t + 20.0, 61.0, 210.0, Color(0.06, 0.05, 0.07, 0.85), false))
	# שכבה 3 (אמצע): עיר הרוסה, מנוף, כיפת מעבדה, המון זומבים שצועד על גשר
	bg.add_layer(0.30, func(ci: CanvasItem, sc: float, v: Vector2, t: float):
		Kit.skyline(ci, sc, v, 565.0, Color("17121a"), 57, Vector2(80, 160), Vector2(120, 250), 0.1, Color(1.0, 0.55, 0.3, 0.75), t, 0.6)
		var period := 1500.0
		var start := int(floor(sc / period)) - 1
		for k in range(start, start + 3):
			var x := float(k) * period - sc
			S9Fx.crane(ci, x + 200.0, 560.0, 230.0, Color("120e14"), t + float(k))
			S9Fx.lab_dome(ci, x + 880.0, 560.0, 80.0, Color("16161c"), t)
			Kit.fire_glow(ci, Vector2(x + 560.0, 520.0), t, 60.0, k)
			Kit.smoke_column(ci, Vector2(x + 560.0, 500.0), t + float(k) * 2.0, 220.0, Color(0.1, 0.08, 0.08, 0.4))
		# גשר עילי ארוך עם המון זומבים שצועד עליו (זז לבד)
		ci.draw_rect(Rect2(0, 462, v.x, 9), Color("130f14"))
		var px := fposmod(-sc, 260.0)
		while px < v.x:
			ci.draw_rect(Rect2(px, 471, 10, 100), Color("130f14"))
			px += 260.0
		S9Fx.horde(ci, sc, v, t, 462.0, Color(0.08, 0.05, 0.07, 0.95), 5, 16.0))
	# שכבה 4 (קרובה): קורות, כבלים, שלט "THEY LEARN" מהבהב, טנק הרוס, דגלים
	bg.add_layer(0.60, func(ci: CanvasItem, sc: float, v: Vector2, t: float):
		var period := 1200.0
		var start := int(floor(sc / period)) - 1
		var f := ThemeDB.fallback_font
		for k in range(start, start + 3):
			var x := float(k) * period - sc
			var r := RandomNumberGenerator.new()
			r.seed = k * 389 + 7
			# קורות פלדה עקומות
			ci.draw_line(Vector2(x + 40, 600), Vector2(x + 120, 300), Color("120e10"), 9.0)
			ci.draw_line(Vector2(x + 120, 300), Vector2(x + 260, 340), Color("120e10"), 7.0)
			ci.draw_line(Vector2(x + 260, 340), Vector2(x + 262 + sin(t * 1.2 + float(k)) * 4.0, 420), Color("120e10"), 2.0)   # כבל מתנדנד
			# שלט חוצות "THEY LEARN" מהבהב
			var bx := x + 520.0
			ci.draw_rect(Rect2(bx + 60, 370, 8, 230), Color("141012"))
			ci.draw_rect(Rect2(bx, 300, 190, 78), Color("1e181a"))
			var on := 1.0 if fmod(t * 1.7 + float(k), 5.0) > 0.4 else 0.2
			ci.draw_string(f, Vector2(bx + 14, 350), "THEY LEARN", HORIZONTAL_ALIGNMENT_LEFT, -1, 26, Color(1.0, 0.2, 0.15, 0.85 * on))
			ci.draw_circle(Vector2(bx + 95, 340), 70.0, Color(1.0, 0.2, 0.1, 0.05 * on))
			# טנק הרוס
			var tx := x + 900.0
			ci.draw_colored_polygon(PackedVector2Array([Vector2(tx, 600), Vector2(tx + 10, 560), Vector2(tx + 150, 556), Vector2(tx + 165, 600)]), Color("141214"))
			ci.draw_rect(Rect2(tx + 40, 530, 70, 28), Color("141214"))
			ci.draw_line(Vector2(tx + 110, 542), Vector2(tx + 190, 520 + r.randf_range(0, 20)), Color("141214"), 6.0)
			# דגל קרוע מתנופף
			var fx := x + 1080.0
			ci.draw_line(Vector2(fx, 600), Vector2(fx, 420), Color("161214"), 3.0)
			var wv := sin(t * 3.0 + float(k)) * 6.0
			ci.draw_colored_polygon(PackedVector2Array([Vector2(fx, 422), Vector2(fx + 50, 426 + wv), Vector2(fx + 44, 446 + wv), Vector2(fx + 20, 440 + wv * 0.5), Vector2(fx, 452)]), Color(0.35, 0.06, 0.05, 0.9))
		Kit.ground_fade(ci, v, 565.0))
	layer.add_child(bg)
	return bg


# ============================================================
#  העולם
# ============================================================
func build_world() -> void:
	# חזיתות מאחורי הכביש
	var x := 0.0
	while x < level_w:
		var row := Decor.CityChunk.new()
		row.position = Vector2(x, floor_y)
		row.seed_v = rng.randi()
		row.level_w = level_w
		main.add_child(row)
		x += 1024.0
	var h := _holes()
	_tunnel(h[0], h[1], false)
	_tunnel(h[2], h[3], true)
	_streets()
	_factory()
	_rooftops()
	_lab()
	_zombie_zone()


# ---- מנהרה מתחת לכביש: ריצפה, קירות קצה, סולמות דרך החורים ----
func _tunnel(ha: Array, hb: Array, lab: bool) -> void:
	var x0: float = float(ha[0]) - 260.0
	var x1: float = float(hb[0]) + float(hb[1]) + 260.0
	var ty := floor_y + DEPTH
	var x := x0 - 40.0
	while x < x1 + 40.0:
		var w := minf(1024.0, x1 + 40.0 - x)
		main._make_brick(Vector2(x, ty), Vector2(w, 90.0), 2, Color("2e2c2a") if not lab else Color("4a5054"), false)
		x += w
	var ceil_y := floor_y + 90.0
	main._make_brick(Vector2(x0 - 40.0, ceil_y), Vector2(40.0, ty - ceil_y), 2, Color("3a3634"), false)
	main._make_brick(Vector2(x1, ceil_y), Vector2(40.0, ty - ceil_y), 2, Color("3a3634"), false)
	var dec := Decor.TunnelDecor.new()
	dec.x0 = x0
	dec.x1 = x1
	dec.top = ceil_y
	dec.bottom = ty
	dec.lab = lab
	dec.seed_v = rng.randi()
	main.add_child(dec)
	# מדף + סולם בכל חור (חזרה למעלה), וסימון "צוואר בקבוק"
	for hole in [ha, hb]:
		var hx: float = hole[0]
		add_floor(hx, floor_y, 46.0, "steel", false, false)
		add_ladder(hx + 23.0, floor_y, ty)
		_choke(Vector2(hx + float(hole[1]) * 0.5, floor_y))
		_choke(Vector2(hx + 23.0, ty))
	# אורות חירום, טפטופים, ניצוצות
	var lx := x0 + 120.0
	while lx < x1 - 60.0:
		var fl = Ambient.FlickerLight.new()
		fl.color = Color(1.0, 0.25, 0.2) if not lab else Color(0.6, 1.0, 0.7)
		fl.mode = "pulse" if not lab else "flicker"
		fl.radius = 60.0
		add_world(fl, Vector2(lx, ceil_y + 36.0))
		if rng.randf() < 0.6:
			var dr = Ambient.Drip.new()
			dr.fall = DEPTH - 90.0 - 34.0
			add_world(dr, Vector2(lx + 90.0, ceil_y + 34.0))
		lx += rng.randf_range(260.0, 360.0)
	var mid := (x0 + x1) * 0.5
	for sx in [x0 + 300.0, x1 - 340.0]:
		add_world(Ambient.SparkEmitter.new(), Vector2(sx, ceil_y + 32.0))
	# סכנות + פרסים (מסלול מסוכן = תחמושת ונשקים)
	if lab:
		for px in [mid - 380.0, mid + 160.0]:
			var ap = AcidPool.new()
			ap.setup(90.0, -1.0)
			add_hazard(ap, Vector2(px, ty))
		var vent = Ambient.SteamVent.new()
		vent.hazard = true
		vent.period = 4.5
		add_world(vent, Vector2(mid - 60.0, ty))
		for tx in [x0 + 200.0, mid - 240.0, mid + 330.0, x1 - 200.0]:
			var tk := Decor.SpecimenTank.new()
			tk.broken = rng.randf() < 0.4
			add_world(tk, Vector2(tx, ty))
		for i in 3:
			var scr = Ambient.Screen.new()
			add_world(scr, Vector2(x0 + 420.0 + float(i) * 380.0, ceil_y + 70.0))
		_pickup(PickupScript.GRENADE, Vector2(mid - 470.0, ty))
		_pickup(PickupScript.GRENADE, Vector2(mid + 40.0, ty))
		_pickup(PickupScript.SUPPLY, Vector2(mid + 260.0, ty))
		_pickup(PickupScript.AMMO, Vector2(x1 - 300.0, ty))
		var bp = _pickup(PickupScript.BOOST, Vector2(mid - 160.0, ty))
		bp.boost = PickupScript.SHIELD
	else:
		var ap = AcidPool.new()
		ap.setup(80.0, -1.0)
		add_hazard(ap, Vector2(mid - 300.0, ty))
		var fz = FireZone.new()
		fz.setup(70.0, -1.0)
		add_hazard(fz, Vector2(mid + 250.0, ty))
		var wp = _pickup(PickupScript.WEAPON, Vector2(mid - 40.0, ty))
		wp.weapon_id = WeaponDB.ASSAULT_SHOTGUN
		_pickup(PickupScript.AMMO, Vector2(mid - 520.0, ty))
		_pickup(PickupScript.AMMO, Vector2(mid + 420.0, ty))
		_pickup(PickupScript.GRENADE, Vector2(mid + 100.0, ty))
		_pickup(PickupScript.SUPPLY, Vector2(x1 - 220.0, ty))


func _pickup(kind: int, pos: Vector2) -> Node:
	var p = PickupScript.new()
	p.kind = kind
	p.life = 100000.0
	main.add_child(p)
	p.setup(pos + Vector2(0, -30), Vector2.ZERO)
	return p


func _choke(pos: Vector2) -> void:
	var c := Node2D.new()
	c.add_to_group("s9_choke")
	add_world(c, pos)


func _collapse(x: float, w: float, period: float, top := -250.0) -> void:
	if not free_x(x, 20.0):
		x += 160.0
	var cz := Hz.CollapseZone.new()
	cz.setup(w, period, top)
	add_hazard(cz, Vector2(x, floor_y))
	reserve(Rect2(x - w * 0.5, floor_y - 60.0, w, 60.0))


func _fire(x: float, w: float) -> void:
	if not free_x(x, 40.0):
		return
	var fz = FireZone.new()
	fz.setup(w, -1.0)
	add_hazard(fz, Vector2(x, floor_y))
	reserve(Rect2(x - w * 0.5 - 10.0, floor_y - 40.0, w + 20.0, 40.0))


# ---- 1. רחובות ----
func _streets() -> void:
	var bx := level_w * 0.10
	add_floor(bx, floor_y - FLOOR2, 420.0, "concrete", true, true)
	add_ladder(bx + 20.0, floor_y - FLOOR2)
	_choke(Vector2(bx + 20.0, floor_y))
	reserve(Rect2(bx - 30.0, floor_y - FLOOR2, 480.0, FLOOR2))
	_fire(level_w * 0.135 + 60.0, 70.0)
	_collapse(level_w * 0.165, 130.0, 9.0)
	_fire(level_w * 0.19, 60.0)


# ---- 2. מפעל: גשרי פלדה למעלה (בטוח ואיטי), מסוע ואדים למטה ----
func _factory() -> void:
	var segs := [[level_w * 0.215, 600.0], [level_w * 0.215 + 670.0, 600.0], [level_w * 0.215 + 1340.0, 520.0]]
	for s in segs:
		add_floor(float(s[0]), floor_y - FLOOR2, float(s[1]), "steel", true, true)
	var x_end: float = float(segs[2][0]) + float(segs[2][1])
	add_ladder(float(segs[0][0]) + 16.0, floor_y - FLOOR2)
	add_ladder(x_end - 20.0, floor_y - FLOOR2)
	_choke(Vector2(float(segs[0][0]) + 16.0, floor_y))
	var cx := level_w * 0.268
	var cv := Decor.Conveyor.new()
	cv.width = 220.0
	cv.speed = -110.0
	add_world(cv, Vector2(cx, floor_y))
	reserve(Rect2(cx - 20.0, floor_y - 20.0, 260.0, 20.0))
	for vx in [level_w * 0.25, level_w * 0.325]:
		if free_x(vx, 30.0):
			var vent = Ambient.SteamVent.new()
			vent.hazard = true
			vent.period = 3.5
			add_world(vent, Vector2(vx, floor_y))
			reserve(Rect2(vx - 20.0, floor_y - 40.0, 40.0, 40.0))
	_fire(level_w * 0.295, 80.0)
	_collapse(level_w * 0.345, 120.0, 8.0, -150.0)   # גשר הפלדה מעליו מתפרק


# ---- 3. גגות: בניינים פתוחים, קפיצות בין גגות ----
func _rooftops() -> void:
	var b1 := level_w * 0.405
	var b2 := b1 + 650.0
	var b3 := b2 + 540.0
	var blist := [[b1, 560.0, floor_y - ROOF, [floor_y - FLOOR2]], [b2, 440.0, floor_y - ROOF, []], [b3, 520.0, floor_y - ROOF, [floor_y - FLOOR2]]]
	var bd := Decor.Buildings.new()
	bd.list = blist
	bd.floor_y = floor_y
	bd.seed_v = rng.randi()
	main.add_child(bd)
	for b in blist:
		add_floor(float(b[0]), float(b[2]), float(b[1]), "roof", false, true)
		for my in b[3]:
			add_floor(float(b[0]) + 14.0, float(my), float(b[1]) - 28.0, "concrete", false, false)
	add_ladder(b1 + 30.0, floor_y - FLOOR2)                   # רחוב -> קומה 2
	add_ladder(b1 + 530.0, floor_y - ROOF, floor_y - FLOOR2)  # קומה 2 -> גג
	add_ladder(b3 + 490.0, floor_y - ROOF)                    # גג אחרון -> רחוב
	add_ladder(b3 + 40.0, floor_y - FLOOR2)
	_choke(Vector2(b1 + 30.0, floor_y))
	_choke(Vector2(b3 + 490.0, floor_y))
	# פרסים על הגגות (מסלול מסוכן: CLIMBER / HUNTER, קפיצות)
	_pickup(PickupScript.SUPPLY, Vector2(b1 + 300.0, floor_y - ROOF))
	_pickup(PickupScript.AMMO, Vector2(b2 + 220.0, floor_y - ROOF))
	_pickup(PickupScript.GRENADE, Vector2(b3 + 260.0, floor_y - ROOF))
	_fire(level_w * 0.47, 70.0)
	_collapse(level_w * 0.53, 140.0, 10.0)


# ---- 4. חורבות מעבדה ----
func _lab() -> void:
	var lx := level_w * 0.627
	add_floor(lx, floor_y - FLOOR2, 540.0, "lab", true, true)
	add_ladder(lx + 20.0, floor_y - FLOOR2)
	add_ladder(lx + 520.0, floor_y - FLOOR2)
	_choke(Vector2(lx + 20.0, floor_y))
	reserve(Rect2(lx - 30.0, floor_y - FLOOR2, 600.0, FLOOR2))
	var ap = AcidPool.new()
	ap.setup(70.0, -1.0)
	var px := level_w * 0.585
	if free_x(px, 30.0):
		add_hazard(ap, Vector2(px, floor_y))
		reserve(Rect2(px - 45.0, floor_y - 20.0, 90.0, 20.0))
	for i in 3:
		add_world(Ambient.SparkEmitter.new(), Vector2(lx + 80.0 + float(i) * 180.0, floor_y - FLOOR2 + 14.0))
	var tk := Decor.SpecimenTank.new()
	tk.broken = true
	add_world(tk, Vector2(level_w * 0.68, floor_y))


# ---- 5. אזור הזומבים + היציאה ----
func _zombie_zone() -> void:
	var sx := level_w * 0.815
	add_floor(sx, floor_y - FLOOR2, 460.0, "scaffold", true, true)
	add_ladder(sx + 20.0, floor_y - FLOOR2)
	_choke(Vector2(sx + 20.0, floor_y))
	reserve(Rect2(sx - 30.0, floor_y - FLOOR2, 520.0, FLOOR2))
	_fire(level_w * 0.79, 60.0)
	_fire(level_w * 0.90, 60.0)
	_collapse(level_w * 0.86, 130.0, 8.0)
	_pickup(PickupScript.SUPPLY, Vector2(sx + 300.0, floor_y - FLOOR2))


# ============================================================
#  אפקטים
# ============================================================
func build_effects() -> void:
	screen_layer.add_child(Ambient.screen_particles("ash", vp))
	screen_layer.add_child(Ambient.screen_particles("embers", vp))
	screen_layer.add_child(S9Fx.LightRain.new())
	var deb = Ambient.FallingDebris.new()
	deb.top_y = floor_y - 560.0
	deb.floor_y = floor_y
	deb.period = 4.0
	main.add_child(deb)
	# מכוניות / הריסות בוערות ברקע הקרוב + אורות מהבהבים
	var x := 500.0
	while x < level_w - 300.0:
		if rng.randf() < 0.45:
			add_fire(Vector2(x, floor_y - 120.0 - rng.randf_range(0.0, 80.0)), 18.0, 24.0)   # חלון בוער
		if rng.randf() < 0.4:
			var fl = Ambient.FlickerLight.new()
			fl.color = Color(1.0, 0.7, 0.4)
			fl.radius = 70.0
			add_world(fl, Vector2(x + 200.0, floor_y - 190.0))
		x += rng.randf_range(420.0, 760.0)


# ============================================================
#  זומבים במקומות מיוחדים
# ============================================================
func extra_spawns() -> void:
	var h := _holes()
	var ty := floor_y + DEPTH
	# רחובות: צייד על המרפסת
	spawn(Registry.HUNTER_ELITE, level_w * 0.10 + 300.0, floor_y - FLOOR2)
	spawn(Registry.SCOUT, level_w * 0.10 + 160.0, floor_y - FLOOR2)
	# מפעל: גשר הפלדה (מסלול בטוח) - רק אחד
	spawn(0, level_w * 0.215 + 900.0, floor_y - FLOOR2)
	# מנהרה A
	var ma: float = (float(h[0][0]) + float(h[1][0])) * 0.5
	spawn(Registry.HUNTER_ELITE, ma + 300.0, ty)
	spawn(Registry.INFECTOR, ma + 520.0, ty)
	spawn(1, ma - 200.0, ty)
	spawn(1, ma + 120.0, ty)
	spawn(0, ma - 420.0, ty)
	# גגות
	var b1 := level_w * 0.405
	spawn(Registry.CLIMBER, b1 + 760.0, floor_y - ROOF)
	spawn(Registry.HUNTER_ELITE, b1 + 1400.0, floor_y - ROOF)
	spawn(Registry.SCOUT, b1 + 1550.0, floor_y - ROOF)
	# חוליית פיקוד ברחוב שמתחת לגגות
	var sq := level_w * 0.50
	spawn(Registry.COMMANDER, sq + 160.0)
	spawn(Registry.SHIELD_ELITE, sq - 60.0)
	spawn(0, sq)
	spawn(1, sq + 40.0)
	spawn(0, sq + 90.0)
	# מעבדה: אינפקטור בקומה העליונה
	spawn(Registry.INFECTOR, level_w * 0.627 + 400.0, floor_y - FLOOR2)
	# מנהרה B (מעבדה תת-קרקעית) - כאן "נולד" ה-EVOLVED
	var mb: float = (float(h[2][0]) + float(h[3][0])) * 0.5
	spawn(Registry.SHIELD_ELITE, mb - 300.0, ty)
	spawn(Registry.INFECTOR, mb + 380.0, ty)
	spawn(Registry.HUNTER_ELITE, mb + 100.0, ty)
	spawn(Registry.EVOLVED, mb + 520.0, ty)
	# אזור הזומבים: אינפקטור בעמדת התצפית, וחוליית פיקוד ליד היציאה
	spawn(Registry.INFECTOR, level_w * 0.815 + 260.0, floor_y - FLOOR2)
	var ex := level_w - 760.0
	spawn(Registry.COMMANDER, ex + 120.0)
	spawn(Registry.SHIELD_ELITE, ex - 120.0)
	spawn(Registry.SHIELD_ELITE, ex - 60.0)
	spawn(Registry.HUNTER_ELITE, ex - 200.0)
	spawn(2, ex)
	spawn(0, ex + 40.0)
	spawn(1, ex - 160.0)
