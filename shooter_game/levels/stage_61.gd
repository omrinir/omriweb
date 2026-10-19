extends "res://levels/stage_base.gd"
# ============================================================
#  STAGE 61 - "END OF THE WORLD" (אזור שמיני - אושוואיה, שלב 1) - "THEY LEARNED TO MOVE AS ONE"
#  (הסיפור: המעבדה (60) נגמרה ב-"Welcome home". אבל ה-ROOT כבר לא שם: הוא ירד מהקרחון עם מי ההפשרה אל תעלת ביגל, וגדל
#   מתחת לאושוואיה - מתחת לכלא הישן (PRESIDIO). כל האזור צועד לעיר כגוף אחד, בצעד אחד: הם לא תוקפים את העיר - הם הולכים
#   הביתה. הגיבור הולך איתם ברחובות, ליד רכבת האסירים, בנמל עם ספינת התענוגות החלודה, עד שער הכלא שיורד למטה (שלב 62).)
#  (effects/s61_decor.gd): שמיים של דמדומים עם זוהר ורוד והרי מרסיאל, העיר על המדרון עם תהלוכה בצעד אחד, עצי לנגה,
#  ובעולם: השלט FIN DEL MUNDO (SIGN_X), בתי פח (HOUSES, מרפסת = קומה), רכבת קצה העולם (TRAIN_X, גגות הקרונות = קומה),
#  הנמל (PIER) עם ספינת התענוגות (SHIP_X, סיפון = קומה), מדורות ברחוב (UPDRAFTS - הזרמים העולים של הקונדורים),
#  והכלא בסוף (ARENA_X) עם השער שיורד למטה (היציאה).
#  מלכודות: SteamValve - שסתום הקיטור של הקטר: לירות בו כשהם צועדים מול הקטר -> סילון קיטור רותח לאורך הקרקע.
#           Lifeboat (LIFEBOATS) - סירות הצלה תלויות מעל המזח: לירות בחבל -> הסירה נופלת ומועכת את מה שמתחת.
#  זומבים: BONESIDE (חצי עצם חצי בשר - BONESIDES + על הקומות), THRONG (להקות בצעד אחד - SCHOOLS), CONDOR (גלים מהשמיים
#          שנושאים זומבים - CONDOR_WAVES, עד CONDOR_MAX באוויר), רגילים, רצים.
#  בוס: THE FERRYMAN (enemies/types/boneside.gd, מצב בוס) - בחצר הכלא, מול השער. מצלצל בפנס ("ALL ABOARD") וקורא ללהקות.
#  "הם לומדים" (חוק הסיפור 3): הנבגים בהריגה מגיעים מ-effects/spore_lesson.gd (zombie.gd, משלב 55).
#  סיפור סביבתי (בלי סצנה): שורות של הגיבור ב-LINES (העיר, הצעד האחד, רכבת האסירים, מי ההפשרה, "הם הולכים הביתה",
#  ה-ROOT מתחת לעיר), כתובות הכוורת על הקירות, ובסוף מול השער - "Down there...". intro לכל סוג חדש ב-_hints.
#  לשנות: SIGN_X, HOUSES, TRAIN_X, PIER, SHIP_X, LIFEBOATS, UPDRAFTS, BONESIDES, SCHOOLS, CONDOR_WAVES, CONDOR_MAX, LINES,
#         ARENA_X, ARENA_COVER, zombie_weights().
# ============================================================

const Decor := preload("res://effects/s61_decor.gd")
const ThrongT := preload("res://enemies/types/throng.gd")
const CondorT := preload("res://enemies/types/condor.gd")
const PickupScript := preload("res://pickup.gd")
const Sfx := preload("res://sfx.gd")

const SOUNDS := {
	"s61_valve": [["C", 0, 0, 0.0, 0.08, 0.0, 30.0, 0.7, 1.0, 0], ["S", 900, 1400, 0.0, 0.45, 0.05, 4.0, 0.25, 1.0, 0.05], ["N", 0, 0, 0.05, 0.4, 0.05, 5.0, 0.3, 0.8, 0, 0.6]],
	"s61_steam": {"rev": 0.25, "drive": 1.8, "layers": [["N", 0, 0, 0.0, 1.5, 0.02, 1.4, 0.9, 0.85, 0, 0.7], ["N", 0, 0, 0.0, 1.3, 0.01, 1.8, 0.45, 0.4, 0, 0.3], ["S", 2200, 1800, 0.0, 1.2, 0.05, 2.0, 0.08, 1.0, 0.05]]},
	"s61_snap": [["C", 0, 0, 0.0, 0.06, 0.0, 40.0, 0.8, 1.0, 0], ["N", 0, 0, 0.0, 0.12, 0.0, 22.0, 0.45, 0.6, 0, 0.5], ["S", 600, 200, 0.0, 0.1, 0.0, 30.0, 0.3, 1.0, 0]],
	"s61_creak": [["W", 90, 70, 0.0, 0.5, 0.05, 2.5, 0.35, 0.4, 0.06], ["C", 0, 0, 0.0, 0.07, 0.0, 40.0, 0.4, 1.0, 0], ["C", 0, 0, 0.18, 0.07, 0.0, 40.0, 0.35, 1.0, 0]],
	"s61_crash": {"rev": 0.3, "drive": 2.6, "layers": [["N", 0, 0, 0.0, 0.7, 0.0, 5.0, 1.0, 0.25, 0], ["C", 0, 0, 0.0, 0.3, 0.0, 10.0, 0.9, 1.0, 0], ["B", 0.8, 0.5, 0.0, 0.6, 0.0, 5.0, 0.7, 1.0, 0, 0, 70.0], ["C", 0, 0, 0.12, 0.2, 0.0, 18.0, 0.5, 1.0, 0]]},
	"s61_wind": {"rev": 0.3, "layers": [["N", 0, 0, 0.0, 3.0, 1.0, 0.6, 0.35, 0.12, 0, 0.2], ["N", 0, 0, 0.3, 2.4, 0.8, 0.8, 0.2, 0.5, 0, 0.6], ["S", 380, 520, 0.4, 2.0, 0.8, 0.8, 0.03, 1.0, 0.1]]},
	"s61_march": {"rev": 0.45, "layers": [["B", 0.9, 0.7, 0.0, 0.25, 0.0, 9.0, 0.5, 1.0, 0, 0, 55.0], ["B", 0.9, 0.7, 0.5, 0.25, 0.0, 9.0, 0.45, 1.0, 0, 0, 55.0], ["B", 0.9, 0.7, 1.0, 0.25, 0.0, 9.0, 0.4, 1.0, 0, 0, 55.0], ["B", 0.9, 0.7, 1.5, 0.25, 0.0, 9.0, 0.35, 1.0, 0, 0, 55.0], ["N", 0, 0, 0.0, 2.0, 0.2, 1.2, 0.12, 0.15, 0, 0.2]]},
	"s61_bell": {"rev": 0.6, "layers": [["S", 520, 518, 0.0, 2.6, 0.0, 1.0, 0.3, 1.0, 0], ["S", 1250, 1246, 0.0, 1.8, 0.0, 1.6, 0.16, 1.0, 0], ["C", 0, 0, 0.0, 0.05, 0.0, 60.0, 0.3, 1.0, 0]]},
}

const SIGN_X := 360.0
const HOUSES := [[860.0, 220.0, 130.0, 0, ""], [1190.0, 200.0, 150.0, 1, "WALK|WITH US"], [3720.0, 240.0, 140.0, 2, "ONE STEP|ONE BODY"],
	[6720.0, 220.0, 130.0, 3, "ZERO|COME HOME"], [7640.0, 200.0, 150.0, 4, ""], [8000.0, 220.0, 130.0, 5, "UNO"]]   # [x, רוחב, גובה המרפסת, צבע, כתובת]
const TRAIN_X := 2300.0
const TRAIN_COACHES := 2
const PIER := Vector2(4720.0, 6460.0)       # המזח (קרשים)
const SHIP_X := 4980.0
const SHIP_W := 1080.0
const SHIP_DECK := 170.0
const LIFEBOATS := [5260.0, 5720.0]
const UPDRAFTS := [1950.0, 3520.0, 4500.0, 6560.0, 7380.0, 8420.0]   # מדורות = זרמים עולים לקונדורים
const BONESIDES := [1560.0, 2120.0, 3440.0, 4380.0, 6300.0, 7150.0, 7900.0, 8640.0]
const SCHOOLS := [[2020.0, 5], [4060.0, 7], [5480.0, 6], [6940.0, 6], [8320.0, 7]]   # [x, כמה]
const CONDOR_WAVES := [1750.0, 3300.0, 4700.0, 5900.0, 7000.0, 8050.0]
const CONDOR_MAX := 2
const LINES := [[160.0, "Ushuaia. The end of the world... and every one of them is walking here.", "e8dcc0"],
	[1420.0, "They're walking in step. All of them... like one body.", "c8ffb0"],
	[2240.0, "The prisoners' train. It carried them to the prison... now they walk there by themselves.", "e8dcc0"],
	[2700.0, "The engine's still got steam. Shoot the valve when they march in front of it.", "ffd0b0"],
	[4760.0, "The meltwater from the lab runs into this bay. The fungus came down the glacier with it.", "bfe8ff"],
	[5150.0, "Lifeboats over the pier... cut the ropes when they walk under.", "ffd0b0"],
	[6620.0, "They're not attacking the city... they're walking home.", "c8ffb0"],
	[8480.0, "The roots... all of them go to the old prison.", "c8ffb0"],
	[8900.0, "The ROOT isn't in the lab any more. It grew down here - under the whole city.", "c8ffb0"]]
const ARENA_X := 9000.0
const ARENA_COVER := [[9300.0, "drums", Vector2(96, 56)]]
const HARDER := [1.0, 1.15, 1.3]

var fx: Node = null
var valve: Node = null
var boats := []
var _decks := []        # [x0, x1, y]
var _waves_done := {}
var _lines_done := {}
var _seen := {}
var _march_t := 6.0
var _end_said := false


func zombie_weights() -> Dictionary:
	return {Registry.BONESIDE: 0.035, Registry.THRONG: 0.03, Registry.CONDOR: 0.006, 0: 0.58, 1: 0.35}


func zombie_density() -> float:   # (הלהקות של SCHOOLS באות בנוסף לפיזור הרגיל)
	return 0.85 * float(HARDER[clampi(Settings.difficulty, 0, 2)])


func generators() -> Array:
	return [["s61_car", 1.0], ["s61_traps", 0.7], ["s61_drums", 0.7], ["s61_fish", 0.8], ["s61_box", 0.35]]


# (שמות עם s61_ - main.gd מטפל בעצמו ב-"car" / "crates" / "container" הרגילים)
func custom_gen(gname: String, x: float) -> float:
	if not gname in ["s61_car", "s61_traps", "s61_drums", "s61_fish", "s61_box"]:
		return 0.0
	var kind := "car"
	var sz := Vector2(110.0, 52.0)
	var port := x > PIER.x and x < PIER.y
	match gname:
		"s61_car":
			if port:   # אין מכוניות על המזח - ארגזי דגים במקום
				kind = "crates"
				sz = Vector2(rng.randf_range(90.0, 104.0), rng.randf_range(52.0, 58.0))
			else:
				sz = Vector2(rng.randf_range(112.0, 128.0), rng.randf_range(50.0, 56.0))
		"s61_traps":
			kind = "traps"
			sz = Vector2(rng.randf_range(96.0, 108.0), rng.randf_range(54.0, 60.0))
		"s61_drums":
			kind = "drums"
			sz = Vector2(rng.randf_range(84.0, 96.0), rng.randf_range(52.0, 58.0))
		"s61_fish":
			kind = "crates"
			sz = Vector2(rng.randf_range(90.0, 104.0), rng.randf_range(52.0, 58.0))
		_:
			if port:   # מכולות רק בנמל
				kind = "container"
				sz = Vector2(rng.randf_range(150.0, 170.0), rng.randf_range(82.0, 92.0))
			else:
				kind = "drums"
				sz = Vector2(rng.randf_range(84.0, 96.0), rng.randf_range(52.0, 58.0))
	if not free_x(x, 30.0) or not free_x(x + sz.x, 30.0):   # לא על מלכודת / סולם / מדורה / הזירה
		return 80.0
	var o := Decor.Obstacle.new()
	o.kind = kind
	o.size = sz
	o.seed_v = rng.randi()
	o.position = Vector2(x, floor_y)
	main.add_child(o)
	reserve(Rect2(x, floor_y - sz.y, sz.x, sz.y))
	return sz.x


func boss_kind() -> int:
	return Registry.BONESIDE


func music() -> String:
	return "res://music/level1_total_war.mp3"


func world_tint() -> Color:
	return Color(0.96, 0.94, 1.0)


func fog() -> bool:
	return false


func pits() -> int:
	return 0


func street_props() -> bool:
	return false


func street_lamps() -> bool:
	return false


# זרמים עולים (x) - הקונדורים מטפסים בהם (enemies/types/condor.gd)
func updrafts() -> Array:
	return UPDRAFTS


func build_background(layer: CanvasLayer) -> Node:
	var bg = Backdrop.new()
	bg.level_w = level_w
	bg.sky = func(ci: CanvasItem, v: Vector2, t: float):
		Decor.end_sky(ci, v, t)
	bg.add_layer(0.06, func(ci: CanvasItem, sc: float, v: Vector2, t: float):
		Decor.far_peaks(ci, sc, v, 556.0, t))
	bg.add_layer(0.28, func(ci: CanvasItem, sc: float, v: Vector2, t: float):
		Decor.mid_city(ci, sc, v, 612.0, t))
	bg.add_layer(0.6, func(ci: CanvasItem, sc: float, v: Vector2, t: float):
		Decor.near_street(ci, sc, v, 640.0, t))
	bg.overlay = func(ci: CanvasItem, v: Vector2, t: float):
		Decor.end_overlay(ci, v, t)
	layer.add_child(bg)
	return bg


func build_world() -> void:
	var x := 0.0
	while x < level_w:   # רחוב, ובנמל - מזח עץ
		var g := Decor.StreetGround.new()
		var end := minf(x + 1024.0, level_w)
		if x < PIER.x and end > PIER.x:
			end = PIER.x
		elif x >= PIER.x and x < PIER.y:
			end = minf(end, PIER.y)
		g.w = end - x
		g.depth = main.floor_thickness
		g.seed_v = rng.randi()
		g.style = "pier" if x >= PIER.x and x < PIER.y else "street"
		add_world(g, Vector2(x, floor_y))
		x = end
	# השלט בכניסה לעיר
	var sg := Decor.FinSign.new()
	add_world(sg, Vector2(SIGN_X, floor_y))
	reserve(Rect2(SIGN_X - 10.0, floor_y - 40.0, sg.w + 20.0, 40.0))
	# בתי פח: מרפסת = קומה, סולם משמאל, אספקה למעלה
	for i in HOUSES.size():
		var hd: Array = HOUSES[i]
		var hx: float = hd[0]
		var hw: float = hd[1]
		var tier: float = hd[2]
		var hs := Decor.TinHouse.new()
		hs.w = hw
		hs.tier = tier
		hs.wall = Decor.TIN[int(hd[3]) % Decor.TIN.size()]
		hs.roof = Decor.ROOFS[int(hd[3]) % Decor.ROOFS.size()]
		hs.seed_v = rng.randi() % 100000
		hs.words = str(hd[4])
		add_world(hs, Vector2(hx, floor_y))
		var hf = add_floor(hx - 14.0, floor_y - tier, hw + 28.0, "steel", false, false)
		hf.visible = false
		add_ladder(hx - 40.0, floor_y - tier)
		reserve(Rect2(hx - 54.0, floor_y - 40.0, hw + 80.0, 40.0))
		_decks.append([hx, hx + hw, floor_y - tier])
		_pickup([PickupScript.AMMO, PickupScript.HEALTH, PickupScript.GRENADE][i % 3], Vector2(hx + hw * 0.6, floor_y - tier - 30.0))
	# רכבת קצה העולם: גגות הקרונות = קומה, ושסתום הקיטור בחזית הקטר
	var tr := Decor.EndTrain.new()
	tr.coaches = TRAIN_COACHES
	add_world(tr, Vector2(TRAIN_X, floor_y))
	for c in TRAIN_COACHES:
		var cx := TRAIN_X + float(c) * (Decor.EndTrain.COACH_W + Decor.EndTrain.GAP)
		var cf = add_floor(cx - 4.0, floor_y - tr.tier, Decor.EndTrain.COACH_W + 8.0, "steel", false, false)
		cf.visible = false
		_decks.append([cx, cx + Decor.EndTrain.COACH_W, floor_y - tr.tier])
	var cab = add_floor(TRAIN_X + tr.loco_x(), floor_y - tr.tier - 48.0, 76.0, "steel", false, false)
	cab.visible = false
	add_ladder(TRAIN_X - 30.0, floor_y - tr.tier)
	reserve(Rect2(TRAIN_X - 50.0, floor_y - 40.0, tr.total_w() + 60.0, 40.0))
	_pickup(PickupScript.AMMO, Vector2(TRAIN_X + 90.0, floor_y - tr.tier - 30.0))
	_pickup(PickupScript.HEALTH, Vector2(TRAIN_X + tr.loco_x() + 38.0, floor_y - tr.tier - 78.0))
	valve = Decor.SteamValve.new()
	valve.dir = 1.0
	add_world(valve, Vector2(TRAIN_X + tr.total_w(), floor_y))
	reserve(Rect2(TRAIN_X + tr.total_w(), floor_y - 40.0, Decor.SteamValve.JET_W, 40.0))   # המסלול של הסילון נקי ממכשולים
	# הנמל: ספינת התענוגות (סיפון = קומה), סולמות, סירות הצלה
	var sh := Decor.CruiseShip.new()
	sh.w = SHIP_W
	sh.deck = SHIP_DECK
	add_world(sh, Vector2(SHIP_X, floor_y))
	var df = add_floor(SHIP_X - 60.0, floor_y - SHIP_DECK, SHIP_W + 60.0, "steel", false, false)
	df.visible = false
	add_ladder(SHIP_X - 50.0, floor_y - SHIP_DECK)
	add_ladder(SHIP_X + SHIP_W - 30.0, floor_y - SHIP_DECK)
	reserve(Rect2(SHIP_X - 70.0, floor_y - 40.0, 50.0, 40.0))
	reserve(Rect2(SHIP_X + SHIP_W - 50.0, floor_y - 40.0, 50.0, 40.0))
	_decks.append([SHIP_X + 100.0, SHIP_X + SHIP_W - 100.0, floor_y - SHIP_DECK])
	_pickup(PickupScript.GRENADE, Vector2(SHIP_X + 200.0, floor_y - SHIP_DECK - 30.0))
	_pickup(PickupScript.AMMO, Vector2(SHIP_X + SHIP_W * 0.55, floor_y - SHIP_DECK - 30.0))
	_pickup(PickupScript.HEALTH, Vector2(SHIP_X + SHIP_W - 140.0, floor_y - SHIP_DECK - 30.0))
	for lx in LIFEBOATS:
		var lb := Decor.Lifeboat.new()
		add_world(lb, Vector2(float(lx), floor_y))
		boats.append(lb)
		reserve(Rect2(float(lx) - 10.0, floor_y - 40.0, Decor.Lifeboat.W + 20.0, 40.0))   # בלי מכשולים מתחת (שהזומבים יעברו שם)
	# מדורות ברחוב: הזרמים העולים של הקונדורים
	for i in UPDRAFTS.size():
		var py := Decor.Pyre.new()
		py.seed_v = i * 7 + 3
		add_world(py, Vector2(float(UPDRAFTS[i]), floor_y))
		reserve(Rect2(float(UPDRAFTS[i]) - 60.0, floor_y - 40.0, 120.0, 40.0))
	# חצר הכלא + השער שיורד למטה (היציאה ב-level_w - 230)
	var pr := Decor.Presidio.new()
	pr.w = level_w - ARENA_X
	pr.gate_x = level_w - 230.0 - ARENA_X
	add_world(pr, Vector2(ARENA_X, floor_y))
	reserve(Rect2(ARENA_X, floor_y - 40.0, level_w - ARENA_X, 40.0))
	for ac in ARENA_COVER:
		var o := Decor.Obstacle.new()
		o.kind = str(ac[1])
		o.size = ac[2]
		o.seed_v = int(ac[0])
		add_world(o, Vector2(float(ac[0]), floor_y))
	var ap = add_floor(ARENA_X + 140.0, floor_y - 130.0, 160.0, "steel", true, true)
	add_ladder(ARENA_X + 150.0, floor_y - 130.0)
	if ap != null:
		_pickup(PickupScript.GRENADE, Vector2(ARENA_X + 230.0, floor_y - 160.0))
	_pickup(PickupScript.HEALTH, Vector2(ARENA_X + 60.0, floor_y - 30.0))
	_pickup(PickupScript.AMMO, Vector2(ARENA_X + 420.0, floor_y - 30.0))


func _pickup(kind: int, pos: Vector2) -> void:
	var p = PickupScript.new()
	p.kind = kind
	p.life = 100000.0
	main.add_child(p)
	p.setup(pos, Vector2.ZERO)


func build_effects() -> void:
	fx = Decor.EndFX.new()
	fx.vp = vp
	screen_layer.add_child(fx)


# BONESIDE על הקרקע ועל הקומות, להקות THRONG שצועדות אליך, שומרים בחצר הכלא. הקונדורים מגיעים בגלים (_waves)
func extra_spawns() -> void:
	for bx in BONESIDES:
		spawn(Registry.BONESIDE, float(bx))
	spawn(Registry.BONESIDE, SHIP_X + SHIP_W * 0.4, floor_y - SHIP_DECK)
	for s in SCHOOLS:
		ThrongT.spawn_school(self, float(s[0]), int(s[1]), -1.0, -1.0)
	for i in _decks.size():
		if i % 2 == 0:
			var d: Array = _decks[i]
			spawn(0, lerpf(float(d[0]), float(d[1]), 0.6), float(d[2]))
	spawn(0, ARENA_X + 300.0)
	spawn(1, ARENA_X + 380.0)


func _physics_process(_delta: float) -> void:
	if main == null:
		return
	if Engine.get_physics_frames() % 10 != 0:
		return
	var pl = get_tree().get_first_node_in_group("player")
	if pl == null or pl.dead:
		return
	_waves(pl)
	_hints(pl)
	_lines(pl)
	_march_t -= 10.0 / 60.0
	if _march_t <= 0.0:   # מרחוק: אלפי רגליים באותו צעד
		_march_t = randf_range(10.0, 16.0)
		Sfx.play("s61_march", null, -9.0, 0.05, 1)


# גלי קונדורים מהשמיים (מלפנים; אחרי שלמדו - גם מאחוריך). כל אחד מביא רוכב
func _waves(pl: Node) -> void:
	var px: float = pl.global_position.x
	for i in CONDOR_WAVES.size():
		if _waves_done.has(i) or px < float(CONDOR_WAVES[i]):
			continue
		_waves_done[i] = true
		if px > float(CONDOR_WAVES[i]) + 700.0:   # (עבר מהר / קפיצה) - לא שולחים גל מאחור
			continue
		var n := 2 if CondorT.is_learned(main) else 1
		n = mini(n, CONDOR_MAX - _condors_up(px))
		for k in n:
			var side := 1.0 if k == 0 else -1.0
			var sx: float = clampf(px + side * (640.0 + float(k) * 60.0), 80.0, ARENA_X - 100.0)
			var z = spawn(Registry.CONDOR, sx, floor_y - 380.0 - float(k) * 30.0)
			if z != null:
				z.set_meta("cd_fly", true)


# כמה קונדורים כבר באוויר לידך (לא יותר מ-CONDOR_MAX)
func _condors_up(px: float) -> int:
	var n := 0
	for z in get_tree().get_nodes_in_group("zombies"):
		if z.kind == Registry.CONDOR and not z.dead and absf(z.global_position.x - px) < 1400.0:
			n += 1
	return n


# intro: פעם אחת לכל סוג חדש, כשהוא על המסך - מה הם למדו, ומאיפה
func _hints(pl: Node) -> void:
	if _seen.size() >= 3:
		return
	for z in get_tree().get_nodes_in_group("zombies"):
		if z.dead or z.type_mod == null or z.is_boss():
			continue
		var k: int = z.kind
		if _seen.has(k) or not (k == Registry.BONESIDE or k == Registry.CONDOR or k == Registry.THRONG):
			continue
		if absf(z.global_position.x - pl.global_position.x) > 600.0 or not Art.on_screen(z, z.global_position, -40.0):
			continue
		_seen[k] = true
		if k == Registry.BONESIDE:
			z._popup("THEY TURN THE BONE TO YOU NOW", Color("ff8a7a"), 15, -100.0)
			pl._say("Every bullet I fired hit flesh... so the side that faces me rotted to bone. Get BEHIND it!", Color("e8e0c8"))
		elif k == Registry.CONDOR:
			main.set_meta("cd_pick_said", true)
			z._popup("THEY CARRY EACH OTHER NOW", Color("ff8a7a"), 15, -110.0)
			pl._say("I hold the line... so they fly OVER it. Shoot the one it's carrying - or the wing!", Color("e8e0c8"))
		else:
			z._popup("THEY MOVE AS ONE NOW", Color("ff8a7a"), 15, -100.0)
			pl._say("I picked them off one at a time... so now there is no 'one'. Break the school!", Color("c8ffb0"))
		return


# הסיפור הסביבתי: שורות של הגיבור במקומות קבועים. ובסוף, כשהבוס מת - מול השער
func _lines(pl: Node) -> void:
	var px: float = pl.global_position.x
	for i in LINES.size():
		if _lines_done.has(i) or px < float(LINES[i][0]):
			continue
		_lines_done[i] = true
		if px > float(LINES[i][0]) + 900.0:
			continue
		pl._say(str(LINES[i][1]), Color(str(LINES[i][2])))
		if i == 4 and fx != null:
			fx.gust()
		return
	if not _end_said and px > level_w - 760.0 and _boss_dead():
		_end_said = true
		Sfx.play("s61_bell", null, -4.0, 0.0, 1)
		pl._say("Down there. That's where they're all walking... home.", Color("c8ffb0"))


func _boss_dead() -> bool:
	for z in get_tree().get_nodes_in_group("zombies"):
		if not z.dead and z.is_boss():
			return false
	return true
