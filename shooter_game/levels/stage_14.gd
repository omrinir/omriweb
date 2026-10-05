extends "res://levels/stage_base.gd"
# ============================================================
#  STAGE 14 - "FISHERMEN'S GRAVE" (אזור צפון-מזרח, שלב 5) - "THEY KNOW YOUR VOICE"
#  נמל דייגים בלילה סוער: גשם כבד באלכסון, ברקים שמאירים הכל לשנייה (ורעם), ים שחור עם קצף,
#  מכמורתן בוער באופק, מפעל שימורים נטוש עם ארובות ועגורנים, סירות מתנדנדות,
#  ובית הקברות של הדייגים: צלבים עם רשתות, עוגנים כמצבות, סירות הפוכות כקברים, נרות.
#  שני אולמות של מפעל השימורים (CANNERIES): בפנים כמעט חושך מוחלט - רק נורות מהבהבות (חלקן מתות).
#    יש בהם קומה עליונה (מסלול הליכה) עם סולמות. בחוץ: פנסי נמל קרים וחביות בוערות.
#  מזחי עץ (PIERS) = קומה שנייה בחלקים מהשלב. יורדים: S פעמיים.
#  זומבים: CRUMBLER (כל קליע תולש ממנו חלק), RETCHER (ענק שמקיא עליך), SCOUT (מזעיק את כולם),
#    IRONWING (כנפיים רובוטיות), WALKER, RUNNER.
#  בוס: RETCHER ענק - "THE BILGE KING".
#  לשנות: HALLS, PIERS, LAMP_GAP, zombie_weights().
# ============================================================

const WeaponDB := preload("res://weapons/weapon_db.gd")
const Decor := preload("res://effects/s14_decor.gd")
const LampScript := preload("res://street_lamp.gd")

const HALLS := [[0.27, 900.0], [0.6, 1100.0]]    # [מיקום יחסי, רוחב] אולמות המפעל
const HALL_H := 300.0
const CATWALK := 150.0
const PIERS := [[0.13, 420.0], [0.45, 480.0], [0.8, 520.0]]   # מזחים (קומה שנייה)
const PIER_H := 130.0
const LAMP_GAP := Vector2(420.0, 700.0)

var _hall_spans := []
var storm_overlay = null
var storm_rain = null


func zombie_weights() -> Dictionary:
	return {0: 0.14, 1: 0.1, Registry.CRUMBLER: 0.26, Registry.RETCHER: 0.12, Registry.SCOUT: 0.12, Registry.IRONWING: 0.12}


func generators() -> Array:
	return [["hull", 1.6], ["traps", 1.6], ["crates", 1.0], ["barrels", 0.8]]


func custom_gen(gname: String, x: float) -> float:
	if not gname in ["hull", "traps"]:
		return 0.0
	if _in_hall(x - 40.0) or _in_hall(x + 160.0):
		return 120.0
	var o := Decor.Obstacle.new()
	o.kind = gname
	o.seed_v = rng.randi()
	o.size = Vector2(rng.randf_range(100.0, 140.0), rng.randf_range(32.0, 40.0)) if gname == "hull" else Vector2(rng.randf_range(70.0, 104.0), 40.0)
	o.position = Vector2(x, floor_y)
	main.add_child(o)
	reserve(Rect2(x, floor_y - o.size.y, o.size.x, o.size.y))
	return o.size.x


func weapon_offers() -> Array:
	return [WeaponDB.ASSAULT_SHOTGUN, WeaponDB.ASSAULT_RIFLE, WeaponDB.SNIPER]


func boss_kind() -> int:
	return Registry.RETCHER


func music() -> String:
	return "res://music/level2_suspense.mp3"


func world_tint() -> Color:
	return Color(0.82, 0.88, 0.95)


func fog() -> bool:
	return false


func street_lamps() -> bool:
	return false


func pits() -> int:
	return 1


func _in_hall(x: float) -> bool:
	for s in _hall_spans:
		if x > float(s[0]) - 30.0 and x < float(s[1]) + 30.0:
			return true
	return false


# ---- רקע ----
func build_background(layer: CanvasLayer) -> Node:
	var bg = Backdrop.new()
	bg.level_w = level_w
	bg.sky = func(ci: CanvasItem, v: Vector2, t: float):
		Decor.storm_sky(ci, v, t)
	# שכבה 1: הים, מכמורתן בוער
	bg.add_layer(0.06, func(ci: CanvasItem, sc: float, v: Vector2, t: float):
		Decor.sea(ci, sc, v, 455.0, t)
		var period := 2600.0
		var start := int(floor(sc / period)) - 1
		for k in range(start, start + 2):
			Decor.burning_trawler(ci, Vector2(float(k) * period - sc + 900.0, 462.0), t))
	# שכבה 2: מפעל השימורים, ארובות, עגורנים
	bg.add_layer(0.22, func(ci: CanvasItem, sc: float, v: Vector2, t: float):
		Decor.cannery_skyline(ci, sc, v, 540.0, t))
	# שכבה 3: סירות בנמל + גדר בית הקברות
	bg.add_layer(0.5, func(ci: CanvasItem, sc: float, v: Vector2, t: float):
		Decor.masts(ci, sc, v, 590.0, t)
		var period := 600.0
		var start := int(floor(sc / period)) - 1
		for k in range(start, start + 4):
			var x := float(k) * period - sc
			var r := RandomNumberGenerator.new()
			r.seed = k * 59 + 2
			for q in 3:
				Decor.cross(ci, Vector2(x + r.randf_range(0.0, period), 600.0), r.randf_range(34.0, 50.0), Color("141a1c"), r.randf() < 0.5, r.randf_range(-0.2, 0.2))
		Kit.ground_fade(ci, v, 595.0))
	layer.add_child(bg)
	return bg


# ---- העולם ----
func build_world() -> void:
	# אולמות מפעל השימורים: חושך, נורות, מסלול הליכה עליון
	for hl in HALLS:
		var ox := level_w * float(hl[0])
		var w: float = hl[1]
		var hall := Decor.CanneryHall.new()
		hall.w = w
		hall.h = HALL_H
		hall.catwalk = CATWALK
		hall.seed_v = rng.randi()
		add_world(hall, Vector2(ox, floor_y))
		add_floor(ox + 40.0, floor_y - CATWALK, w - 80.0, "steel", true, true)
		add_ladder(ox + 70.0, floor_y - CATWALK)
		add_ladder(ox + w - 70.0, floor_y - CATWALK)
		var dz := Decor.DarkZone.new()
		dz.x0 = ox
		dz.x1 = ox + w
		dz.top = floor_y - HALL_H
		main.add_child(dz)
		var bx := ox + 90.0
		var i := 0
		while bx < ox + w - 60.0:
			var b := Decor.Bulb.new()
			b.cord = rng.randf_range(40.0, 70.0)
			b.dead_bulb = i % 3 == 2   # כל נורה שלישית מתה
			add_world(b, Vector2(bx, floor_y - HALL_H + 10.0))
			bx += rng.randf_range(200.0, 280.0)
			i += 1
		reserve(Rect2(ox - 40.0, floor_y - CATWALK, w + 80.0, CATWALK))
		_hall_spans.append([ox, ox + w])
	# מזחי עץ (קומה שנייה בחלק מהשלב)
	for pr in PIERS:
		var px := level_w * float(pr[0])
		if _in_hall(px) or _in_hall(px + float(pr[1])):
			continue
		add_floor(px, floor_y - PIER_H, float(pr[1]), "wood", true, true)
		add_ladder(px + 16.0, floor_y - PIER_H)
		add_ladder(px + float(pr[1]) - 16.0, floor_y - PIER_H)
		reserve(Rect2(px - 30.0, floor_y - PIER_H, float(pr[1]) + 60.0, PIER_H))
	# בית הקברות של הדייגים מאחורי הכביש
	var x := 0.0
	while x < level_w:
		var row := Decor.Cemetery.new()
		row.position = Vector2(x, floor_y)
		row.seed_v = rng.randi()
		for s in _hall_spans:
			row.skip.append([float(s[0]) - x, float(s[1]) - x])
		main.add_child(row)
		x += 1024.0
	# פנסי נמל (אור קר) - לא בתוך המפעל
	var lx := rng.randf_range(300.0, 500.0)
	while lx < level_w - 300.0:
		if not _in_hall(lx) and not main._in_pit(lx - 40.0, lx + 40.0, 20.0):
			var lamp = LampScript.new()
			lamp.light_color = Color(0.7, 0.85, 1.0)
			lamp.position = Vector2(lx, floor_y)
			main.add_child(lamp)
		lx += rng.randf_range(LAMP_GAP.x, LAMP_GAP.y)
	# חביות בוערות
	for k in 6:
		var fx := level_w * rng.randf_range(0.08, 0.92)
		if _in_hall(fx) or not free_x(fx, 50.0) or main._in_pit(fx - 40.0, fx + 40.0, 20.0):
			continue
		add_world(Decor.FireBarrel.new(), Vector2(fx, floor_y))
		reserve(Rect2(fx - 20.0, floor_y - 40.0, 40.0, 40.0))


func build_effects() -> void:
	storm_overlay = Decor.StormOverlay.new()
	main.add_child(storm_overlay)
	storm_rain = Decor.StormRain.new()
	storm_rain.overlay = storm_overlay
	screen_layer.add_child(storm_rain)


# במפעל: CRUMBLER שוכבים (קמים כשמתקרבים) ו-RETCHER. על המזחים: SCOUT. מעל בית הקברות: IRONWING
func extra_spawns() -> void:
	for hl in HALLS:
		var ox := level_w * float(hl[0])
		var w: float = hl[1]
		for i in 3:
			var z = spawn(Registry.CRUMBLER, ox + w * (0.2 + 0.3 * float(i)) + rng.randf_range(-40.0, 40.0))
			if z != null:
				z.lie_down()
		spawn(Registry.RETCHER, ox + w * 0.75)
		spawn(Registry.SCOUT, ox + w * 0.5, floor_y - CATWALK)
	for pr in PIERS:
		var px := level_w * float(pr[0])
		if not _in_hall(px) and not _in_hall(px + float(pr[1])):
			spawn(Registry.SCOUT, px + float(pr[1]) * 0.6, floor_y - PIER_H)
	for i in 2:
		spawn(Registry.IRONWING, level_w * (0.38 + 0.36 * float(i)), floor_y - 200.0)
