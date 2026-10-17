extends "res://levels/stage_base.gd"
# ============================================================
#  STAGE 53 - "CAPITAL SIEGE" (אזור שישי - החרוט הדרומי, שלב 8) - "THEY LEARNED TO BESIEGE"
#  (הסיפור: המתים נוסעים דרומה ברכבות, ובדרך הם עוצרים במונטווידאו - הבירה החופשית האחרונה. החיים מחזיקים את
#   העיר העתיקה מאחורי מחסומים של אוטובוסים ושקי חול, והעדר עולה עליהם: הם בונים מגדלים מהגופות של עצמם,
#   הם מפיצים מילה שמרקיבה את המוח - ו-THE ARCHITECT שלח אחד מהם במיוחד בשבילך. בשמך.)
#  (effects/s53_decor.gd): בוקר קר ומעונן, עמודי עשן, ה-Rio de la Plata עם אוניות בוערות, Palacio Salvo, העדר מחוץ לחומה.
#  קומה שנייה: הגג של שער הסיטדלה (GATE), מרפסות הברזל של החזיתות (FACADES), גגות האוטובוסים השרופים (BUSES).
#  מלכודות: OilDrum (DRUMS) - חבית שמן מעל הכביש: יורים בה -> שמן בוער על הכביש. נגד מגדלי STACKER.
#           BreachWall (BREACHES) - מחסום גרוטאות בצד: מתקרבים -> רועד -> קורס על הכביש והעדר פורץ.
#  זומבים: STACKER (בונים מגדלים מגופות), BABBLER (מגפון - מילה שמחליאה), PURSUER (נשלח בשבילך, קם 3 פעמים),
#          רגילים, רצים. PURSUER לא בתוך zombie_weights - רק אחד, דרך Pursuer.Director.
#  בוס: THE SIEGE TOWER (enemies/types/stacker.gd, מצב בוס) - ליד המחסום האחרון ברמבלה: איל ניגוח, משיר גופות.
#  לשנות: GATE, TIER, FACADES, FACADE_TIER, BUSES, DRUMS, BREACHES, ARENA_BARRICADES, zombie_weights().
# ============================================================

const Decor := preload("res://effects/s53_decor.gd")
const Pursuer := preload("res://enemies/types/pursuer.gd")
const PickupScript := preload("res://pickup.gd")

const SOUNDS := {
	"sg_clank": [["S", 620, 560, 0.0, 0.3, 0.0, 9.0, 0.45, 1.0, 0.02], ["S", 1480, 1400, 0.0, 0.2, 0.0, 14.0, 0.2, 1.0, 0], ["N", 0, 0, 0.0, 0.06, 0.0, 60.0, 0.4, 0.5, 0]],
	"sg_pour": {"rev": 0.25, "layers": [["N", 0, 0, 0.0, 1.1, 0.05, 2.2, 0.8, 0.3, 0], ["N", 0, 0, 0.1, 1.0, 0.1, 2.0, 0.5, 0.9, 0, 0.4], ["S", 90, 60, 0.0, 0.8, 0.05, 3.0, 0.4, 1.0, 0]]},
	"sg_creak": [["S", 180, 140, 0.0, 0.9, 0.08, 2.0, 0.4, 1.0, 0.35], ["N", 0, 0, 0.0, 0.8, 0.05, 3.0, 0.3, 0.25, 0], ["S", 95, 80, 0.3, 0.6, 0.05, 3.0, 0.35, 1.0, 0.2]],
	"sg_crash": {"rev": 0.3, "drive": 2.2, "layers": [["N", 0, 0, 0.0, 0.9, 0.0, 4.0, 1.2, 0.3, 0], ["S", 70, 30, 0.0, 0.6, 0.0, 6.0, 1.0, 1.0, 0], ["S", 900, 850, 0.05, 0.3, 0.0, 12.0, 0.3, 1.0, 0.02], ["N", 0, 0, 0.25, 0.5, 0.0, 6.0, 0.6, 0.6, 0, 0.3]]},
}

const GATE := 0.07                       # שער הסיטדלה (הגג = קומה)
const TIER := 170.0
const FACADES := [0.17, 0.37, 0.55, 0.75]   # חזיתות עם מרפסת ברזל
const FACADE_TIER := 160.0
const BUSES := [0.25, 0.46, 0.65, 0.84]  # אוטובוסים שרופים (מוצקים, עומדים על הגג)
const BREACHES := [0.3, 0.59, 0.8]      # מחסומי גרוטאות שקורסים
const ARENA_BARRICADES := [1080.0, 850.0, 640.0]   # מרחק מסוף השלב
const HARDER := [1.0, 1.15, 1.3]

var _decks := []        # [x0, x1, y]
var _facades := []      # x של כל חזית
var _buses := []
var _director: Node = null


func zombie_weights() -> Dictionary:
	return {Registry.STACKER: 0.09, Registry.BABBLER: 0.04, 0: 0.54, 1: 0.33}


func zombie_density() -> float:
	return 1.0 * float(HARDER[clampi(Settings.difficulty, 0, 2)])


func generators() -> Array:
	return [["sandbags", 1.4], ["stalls", 0.8], ["tram", 0.4]]


func custom_gen(gname: String, x: float) -> float:
	if not gname in ["sandbags", "stalls", "tram"]:
		return 0.0
	for k in 7:   # כל הרוחב פנוי (לא מכסה סולם של השער / מרפסת)
		if not free_x(x + float(k) * 25.0, 20.0):
			return 80.0
	var o := Decor.Obstacle.new()
	o.kind = gname
	o.seed_v = rng.randi()
	match gname:
		"sandbags":
			o.size = Vector2(rng.randf_range(86.0, 110.0), rng.randf_range(44.0, 50.0))
		"stalls":
			o.size = Vector2(rng.randf_range(84.0, 96.0), rng.randf_range(54.0, 60.0))
		_:
			o.size = Vector2(rng.randf_range(118.0, 132.0), rng.randf_range(56.0, 62.0))
	o.position = Vector2(x, floor_y)
	main.add_child(o)
	reserve(Rect2(x, floor_y - o.size.y, o.size.x, o.size.y))
	return o.size.x


func boss_kind() -> int:
	return Registry.STACKER


func music() -> String:
	return "res://music/level1_total_war.mp3"


func world_tint() -> Color:
	return Color(0.92, 0.95, 1.0)


func fog() -> bool:
	return false


func pits() -> int:
	return 0


func build_background(layer: CanvasLayer) -> Node:
	var bg = Backdrop.new()
	bg.level_w = level_w
	bg.sky = func(ci: CanvasItem, v: Vector2, t: float):
		Decor.siege_sky(ci, v, t)
	bg.add_layer(0.06, func(ci: CanvasItem, sc: float, v: Vector2, t: float):
		Decor.far_river(ci, sc, v, 552.0, t))
	bg.add_layer(0.28, func(ci: CanvasItem, sc: float, v: Vector2, t: float):
		Decor.mid_oldcity(ci, sc, v, 612.0, t))
	bg.add_layer(0.6, func(ci: CanvasItem, sc: float, v: Vector2, t: float):
		Decor.near_barricade(ci, sc, v, 636.0, t))
	bg.overlay = func(ci: CanvasItem, v: Vector2, t: float):
		Decor.haze(ci, v, t)
	layer.add_child(bg)
	return bg


func build_world() -> void:
	var x := 0.0
	while x < level_w:
		var g := Decor.SiegeGround.new()
		g.w = minf(1024.0, level_w - x)
		g.depth = main.floor_thickness
		g.seed_v = rng.randi() % 1000
		add_world(g, Vector2(x, floor_y))
		x += 1024.0
	# שער הסיטדלה: הגג = קומה
	var gx := level_w * GATE
	var gate := Decor.CitadelGate.new()
	gate.tier = TIER
	add_world(gate, Vector2(gx, floor_y))
	var gf = add_floor(gx - 4.0, floor_y - TIER, gate.w + 8.0, "concrete", false, false)
	gf.visible = false
	add_ladder(gx + 26.0, floor_y - TIER)
	add_ladder(gx + gate.w - 50.0, floor_y - TIER)
	reserve(Rect2(gx + 10.0, floor_y - 40.0, 50.0, 40.0))
	reserve(Rect2(gx + gate.w - 60.0, floor_y - 40.0, 50.0, 40.0))
	_decks.append([gx, gx + gate.w, floor_y - TIER])
	_pickup(PickupScript.AMMO, Vector2(gx + gate.w * 0.5, floor_y - TIER - 30.0))
	# חזיתות עם מרפסת ברזל (קומה) + חבית שמן מעל הכביש מולן
	for i in FACADES.size():
		var fx := level_w * float(FACADES[i])
		while not free_x(fx, 40.0) and fx < level_w - 1500.0:
			fx += 60.0
		var fa := Decor.Facade.new()
		fa.tier = FACADE_TIER
		fa.col = Decor.HOUSES[i % Decor.HOUSES.size()]
		fa.seed_v = i
		add_world(fa, Vector2(fx, floor_y))
		var ff = add_floor(fx + fa.w * 0.06, floor_y - FACADE_TIER, fa.w * 0.88, "concrete", false, false)
		ff.visible = false
		add_ladder(fx + fa.w * 0.06 + 6.0, floor_y - FACADE_TIER)
		reserve(Rect2(fx, floor_y - 40.0, 50.0, 40.0))
		_decks.append([fx + fa.w * 0.06, fx + fa.w * 0.94, floor_y - FACADE_TIER])
		_facades.append(fx)
		_pickup(PickupScript.HEALTH if i % 2 == 1 else PickupScript.AMMO, Vector2(fx + fa.w * 0.6, floor_y - FACADE_TIER - 30.0))
		var dr := Decor.OilDrum.new()
		add_world(dr, Vector2(fx + fa.w * 0.62, floor_y))
	# אוטובוסים שרופים שחוסמים את הרחוב (עומדים על הגג)
	for f in BUSES:
		var bx := level_w * float(f)
		while (not free_x(bx, 40.0) or not free_x(bx + 240.0, 40.0)) and bx < level_w - 1500.0:
			bx += 60.0
		var bus := Decor.BusBarricade.new()
		bus.seed_v = rng.randi() % 1000
		add_world(bus, Vector2(bx, floor_y))
		reserve(Rect2(bx - 20.0, floor_y - bus.size.y, bus.size.x + 40.0, bus.size.y))
		_buses.append(bx)
	# מחסומי גרוטאות שהעדר דוחף (קורסים)
	for f in BREACHES:
		var rx := level_w * float(f)
		while (not free_x(rx, 30.0) or not free_x(rx + 200.0, 30.0)) and rx < level_w - 1500.0:
			rx += 60.0
		var bw := Decor.BreachWall.new()
		bw.main = main
		add_world(bw, Vector2(rx, floor_y))
		reserve(Rect2(rx - 20.0, floor_y - 40.0, 240.0, 40.0))
	# הרמבלה בסוף + המחסומים בזירת הבוס
	var sw := Decor.SeaWall.new()
	sw.w = 1300.0
	add_world(sw, Vector2(level_w - 1300.0, floor_y))
	for d in ARENA_BARRICADES:
		var ax := level_w - float(d)
		add_world(Decor.ArenaBarricade.new(), Vector2(ax, floor_y))
		reserve(Rect2(ax - 20.0, floor_y - 66.0, 112.0, 66.0))
	reserve(Rect2(level_w - 1150.0, floor_y - 40.0, 1150.0, 40.0))
	_pickup(PickupScript.HEALTH, Vector2(level_w - 1220.0, floor_y - 30.0))
	_pickup(PickupScript.AMMO, Vector2(level_w - 1160.0, floor_y - 30.0))


func _pickup(kind: int, pos: Vector2) -> void:
	var p = PickupScript.new()
	p.kind = kind
	p.life = 100000.0
	main.add_child(p)
	p.setup(pos, Vector2.ZERO)


func build_effects() -> void:
	var ash := Ambient.screen_particles("ash", vp)
	ash.color = Color(0.72, 0.72, 0.74, 0.45)
	screen_layer.add_child(ash)
	var fx := Decor.SiegeFX.new()
	fx.vp = vp
	screen_layer.add_child(fx)
	# PURSUER: אחד בשלב, נכנס אחרי השער ורודף אחריך עד הסוף
	_director = Pursuer.Director.new()
	_director.main = main
	_director.floor_y = floor_y
	_director.start_x = level_w * 0.11
	_director.end_x = level_w - 1500.0
	_director.screen_layer = screen_layer
	main.add_child(_director)


# על הגג של השער - BABBLER שצועק למטה. מתחת לכל מרפסת - זוג STACKER (בונים מגדל כשאתה עולה). מאחורי כל אוטובוס - BABBLER.
func extra_spawns() -> void:
	for d in _decks:
		spawn(0, lerpf(float(d[0]), float(d[1]), 0.7), float(d[2]))
	var gd: Array = _decks[0]
	spawn(Registry.BABBLER, lerpf(float(gd[0]), float(gd[1]), 0.3), float(gd[2]))
	for fx in _facades:
		spawn(Registry.STACKER, float(fx) + 120.0)
		spawn(Registry.STACKER, float(fx) + 175.0)
	for i in _buses.size():
		if i % 2 == 0:
			spawn(Registry.BABBLER, float(_buses[i]) + 330.0)
		else:
			spawn(Registry.STACKER, float(_buses[i]) + 300.0)
			spawn(Registry.STACKER, float(_buses[i]) + 350.0)
			spawn(Registry.STACKER, float(_buses[i]) + 400.0)
