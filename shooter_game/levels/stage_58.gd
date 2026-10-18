extends "res://levels/stage_base.gd"
# ============================================================
#  STAGE 58 - "WHALE GRAVEYARD" (אזור שביעי - פטגוניה, שלב 4) - "THEY LEARNED TO WEAR THE DEAD"
#  (הסיפור: אחרי המקהלה בחוף הפינגווינים (57) הגיבור ממשיך דרומה-מזרחה לאורך החוף, אל PUERTO HUESO - תחנת ציד לווייתנים
#   נטושה מ-1911. הנבגים נשאו אלפי מיתות של ירייה בראש - והמתים למדו שגולגולת נשברת ועצם לווייתן לא. אז הם לובשים את המתים.
#   ויותר מזה: ECHO למד שהוא יכול לגדול בכל דבר מת. התחנה הפכה לחווה - הפגרים מתנשמים, והכוורת כותבת לו על המיכלים.
#   במערב, מעבר להרים, עמוד עשן: היער השחור בוער (שלב 59).)
#  (effects/s58_decor.gd): שמיים אפורים וכבדים, שמש נמוכה, הרים עם קרחונים ועמוד עשן, המפרץ עם סככות, כנסייה וספינה טבועה,
#  סוללת חלוקים עם קשתות צלעות, צלבים וגידולי ECHO. בעולם: שער הלסתות (ARCH_X), מיכלי שמן עם כתובות הכוורת (TANKS),
#  משטח ההפשטה (PLAN_X), ספינת הציד TORMENTA על המסילה (BOAT_X), כס העצמות של הבוס (ARENA_X).
#  קומה שנייה: גגות המיכלים (TANK_TIER), במת ההפשטה (PLAN_TIER), סיפון הספינה + גג תא ההגה (BOAT_DECK / BOAT_CAB) -
#    סולמות בכל אחד ואספקה למעלה. קן העורב בתורן (סקואה יושבת שם).
#  מלכודות: EchoCarcass (CARCASSES) - פגר מתנשם שיולד BONECRAWLER (לפוצץ את השלפוחיות קודם = STILLBORN).
#           HarpoonGun (GUNS) - תותח צלצל עם תותחן מת: מכוון, ננעל, יורה (משפד גם זומבים). לירות בתותחן.
#           TryPot (POTS) - סירי שמן רותח: ירייה -> שמן בוער על הקרקע.
#  זומבים: FLENSER (מגן עצם, FLENSERS + על הבמות), SKUA (גלים מהשמיים - SKUA_WAVES, עד SKUA_MAX באוויר; ויושבות על המיכלים / בקן העורב),
#          BONECRAWLER (נולד מהפגרים + CRAWLERS), רגילים, רצים.
#  בוס: THE BONE KING (enemies/types/flenser.gd, מצב בוס) - מול כס העצמות (BoneThrone), חביות שהוא נתקע בהן (ARENA_CASKS).
#  "הם לומדים" (חוק הסיפור 3): הנבגים בהריגה מגיעים מ-effects/spore_lesson.gd (zombie.gd, משלב 55).
#  סיפור סביבתי (בלי סצנה): שורות של הגיבור ב-LINES (המיכלים, הפגר, העשן במערב). intro לכל סוג חדש ב-_hints.
#  לשנות: ARCH_X, TANKS, PLAN_X, CARCASSES, BOAT_X, GUNS, POTS, FLENSERS, CRAWLERS, SKUA_WAVES, SKUA_MAX, LINES, ARENA_X,
#         zombie_weights().
# ============================================================

const Decor := preload("res://effects/s58_decor.gd")
const SkuaT := preload("res://enemies/types/skua.gd")
const PickupScript := preload("res://pickup.gd")
const Sfx := preload("res://sfx.gd")

const SOUNDS := {
	"s58_pop": [["B", 1.2, 0.8, 0.0, 0.25, 0.0, 9.0, 0.5, 1.0, 0, 0, 220.0], ["N", 0, 0, 0.0, 0.18, 0.0, 14.0, 0.4, 0.5, 0, 0.3], ["S", 160, 70, 0.0, 0.15, 0.0, 14.0, 0.4, 1.0, 0]],
	"s58_gurgle": {"rev": 0.3, "layers": [["B", 0.7, 0.5, 0.0, 1.2, 0.1, 1.8, 0.5, 1.0, 0, 0, 70.0], ["V", 70, 55, 0.0, 1.1, 0.2, 1.5, 0.5, 1.0, 0.08, 0, [300, 700, 14]], ["N", 0, 0, 0.0, 1.0, 0.2, 2.0, 0.25, 0.12, 0]]},
	"s58_burst": {"rev": 0.3, "drive": 2.4, "layers": [["N", 0, 0, 0.0, 0.6, 0.0, 5.0, 0.9, 0.3, 0, 0.1], ["B", 0.5, 0.4, 0.0, 0.9, 0.0, 3.0, 0.5, 1.0, 0, 0, 110.0], ["C", 0, 0, 0.0, 0.3, 0.0, 9.0, 0.7, 1.0, 0], ["V", 90, 60, 0.05, 0.8, 0.05, 2.5, 0.5, 1.0, 0.08, 0, [360, 800, 20]]]},
	"s58_crank": [["C", 0, 0, 0.0, 0.07, 0.0, 40.0, 0.4, 1.0, 0], ["C", 0, 0, 0.14, 0.07, 0.0, 40.0, 0.4, 1.0, 0], ["C", 0, 0, 0.28, 0.07, 0.0, 40.0, 0.4, 1.0, 0], ["S", 240, 200, 0.0, 0.45, 0.05, 4.0, 0.15, 1.0, 0.02]],
	"s58_click": [["C", 0, 0, 0.0, 0.08, 0.0, 30.0, 0.8, 1.0, 0], ["S", 2400, 2200, 0.0, 0.06, 0.0, 40.0, 0.25, 1.0, 0]],
	"s58_harpoon": {"rev": 0.3, "drive": 2.6, "layers": [["N", 0, 0, 0.0, 0.5, 0.0, 6.0, 1.0, 0.25, 0], ["S", 70, 35, 0.0, 0.45, 0.0, 6.0, 0.9, 1.0, 0], ["N", 0, 0, 0.05, 0.6, 0.05, 3.0, 0.35, 0.6, 0, 0.6]]},
	"s58_thunk": [["C", 0, 0, 0.0, 0.2, 0.0, 14.0, 0.8, 1.0, 0], ["S", 140, 90, 0.0, 0.25, 0.0, 12.0, 0.5, 1.0, 0], ["S", 900, 860, 0.02, 0.4, 0.0, 6.0, 0.15, 1.0, 0.05]],
	"s58_hiss": {"rev": 0.25, "layers": [["N", 0, 0, 0.0, 1.4, 0.02, 1.6, 0.7, 0.8, 0, 0.6], ["B", 1.4, 1.0, 0.0, 1.2, 0.0, 2.0, 0.35, 1.0, 0, 0, 160.0]]},
	"s58_wind": {"rev": 0.3, "layers": [["N", 0, 0, 0.0, 3.0, 1.0, 0.6, 0.35, 0.12, 0, 0.2], ["N", 0, 0, 0.3, 2.4, 0.8, 0.8, 0.2, 0.5, 0, 0.6], ["S", 400, 520, 0.4, 2.0, 0.8, 0.8, 0.03, 1.0, 0.1]]},
	"s58_gulls": {"rev": 0.35, "layers": [["V", 900, 1300, 0.0, 0.3, 0.01, 4.0, 0.35, 1.0, 0.12, 0, [1300, 2900, 40]], ["V", 1000, 1400, 0.35, 0.25, 0.01, 4.0, 0.3, 1.0, 0.12, 0, [1400, 3000, 40]], ["V", 850, 1250, 0.7, 0.3, 0.01, 4.0, 0.25, 1.0, 0.1, 0, [1200, 2800, 40]]]},
}

const ARCH_X := 380.0
const TANKS := [[1250.0, "WE REMEMBER"], [1560.0, "COME HOME|ZERO"], [6250.0, "ANY DEAD|WILL DO"]]   # [x, כתובת]
const TANK_W := 180.0
const TANK_TIER := 170.0
const PLAN_X := 2900.0
const PLAN_W := 520.0
const PLAN_TIER := 140.0
const CARCASSES := [3880.0, 6950.0]
const CARCASS_W := 420.0
const BOAT_X := 4900.0
const BOAT_W := 380.0
const BOAT_DECK := 120.0
const BOAT_CAB := 215.0
const GUNS := [[4880.0, -1.0, BOAT_DECK], [7900.0, -1.0, 56.0]]   # [x, כיוון, גובה הבסיס]
const POTS := [2150.0, 5850.0]
const FLENSERS := [1000.0, 2050.0, 4560.0, 5560.0, 6620.0, 7600.0, 8700.0]
const CRAWLERS := [5300.0, 8350.0]
const SKUA_WAVES := [1850.0, 3500.0, 5450.0, 7350.0, 8550.0]
const SKUA_MAX := 3                # סקואות באוויר בבת אחת (גלים)
const LINES := [[1120.0, "Writing on the tanks... they're writing to me.", "c8ffb0"],
	[3700.0, "They grow in the whales now. Anything dead will do.", "c8ffb0"],
	[8050.0, "Smoke over the mountains... the forest is burning.", "ffb070"]]
const ARENA_X := 9240.0
const ARENA_CASKS := [9420.0, 10120.0]
const HARDER := [1.0, 1.15, 1.3]

var fx: Node = null
var _decks := []        # [x0, x1, y]
var _waves_done := {}
var _lines_done := {}
var _seen := {}
var _gulls_t := 4.0


func zombie_weights() -> Dictionary:
	return {Registry.FLENSER: 0.04, Registry.SKUA: 0.02, Registry.BONECRAWLER: 0.02, 0: 0.57, 1: 0.35}


func zombie_density() -> float:
	return 1.0 * float(HARDER[clampi(Settings.difficulty, 0, 2)])


func generators() -> Array:
	return [["casks", 1.0], ["boiler", 0.5], ["bones", 0.9], ["winch", 0.4]]


func custom_gen(gname: String, x: float) -> float:
	if not gname in ["casks", "boiler", "bones", "winch"]:
		return 0.0
	var sz := Vector2(80.0, 56.0)
	match gname:
		"casks":
			sz = Vector2(rng.randf_range(76.0, 92.0), rng.randf_range(54.0, 62.0))
		"boiler":
			sz = Vector2(rng.randf_range(124.0, 140.0), rng.randf_range(56.0, 64.0))
		"bones":
			sz = Vector2(rng.randf_range(96.0, 116.0), rng.randf_range(40.0, 50.0))
		_:
			sz = Vector2(rng.randf_range(84.0, 96.0), rng.randf_range(54.0, 60.0))
	if not free_x(x, 30.0) or not free_x(x + sz.x, 30.0):   # לא על מלכודת / סולם / פגר / הזירה
		return 80.0
	var o := Decor.Obstacle.new()
	o.kind = gname
	o.size = sz
	o.seed_v = rng.randi()
	o.position = Vector2(x, floor_y)
	main.add_child(o)
	reserve(Rect2(x, floor_y - sz.y, sz.x, sz.y))
	return sz.x


func boss_kind() -> int:
	return Registry.FLENSER


func music() -> String:
	return "res://music/level1_total_war.mp3"


func world_tint() -> Color:
	return Color(0.95, 0.96, 0.98)


func fog() -> bool:
	return false


func pits() -> int:
	return 0


func street_props() -> bool:
	return false


func street_lamps() -> bool:
	return false


func build_background(layer: CanvasLayer) -> Node:
	var bg = Backdrop.new()
	bg.level_w = level_w
	bg.sky = func(ci: CanvasItem, v: Vector2, t: float):
		Decor.grey_sky(ci, v, t)
	bg.add_layer(0.06, func(ci: CanvasItem, sc: float, v: Vector2, t: float):
		Decor.far_isle(ci, sc, v, 552.0, t))
	bg.add_layer(0.28, func(ci: CanvasItem, sc: float, v: Vector2, t: float):
		Decor.mid_harbor(ci, sc, v, 610.0, t))
	bg.add_layer(0.6, func(ci: CanvasItem, sc: float, v: Vector2, t: float):
		Decor.near_bones(ci, sc, v, 636.0, t))
	bg.overlay = func(ci: CanvasItem, v: Vector2, t: float):
		Decor.grey_overlay(ci, v, t)
	layer.add_child(bg)
	return bg


func build_world() -> void:
	var x := 0.0
	while x < level_w:
		var g := Decor.GraveGround.new()
		g.w = minf(1024.0, level_w - x)
		g.depth = main.floor_thickness
		g.seed_v = rng.randi()
		add_world(g, Vector2(x, floor_y))
		x += 1024.0
	# שער הלסתות
	add_world(Decor.BoneArch.new(), Vector2(ARCH_X, floor_y))
	reserve(Rect2(ARCH_X - 20.0, floor_y - 40.0, 270.0, 40.0))
	# מיכלי שמן (הגג = קומה) עם כתובות הכוורת
	for i in TANKS.size():
		var tx: float = TANKS[i][0]
		var tk := Decor.OilTank.new()
		tk.w = TANK_W
		tk.tier = TANK_TIER
		tk.seed_v = rng.randi() % 100000
		tk.words = str(TANKS[i][1])
		add_world(tk, Vector2(tx, floor_y))
		var tf = add_floor(tx - 4.0, floor_y - TANK_TIER, TANK_W + 8.0, "steel", false, false)
		tf.visible = false
		add_ladder(tx - 26.0, floor_y - TANK_TIER)
		reserve(Rect2(tx - 40.0, floor_y - 40.0, TANK_W + 90.0, 40.0))
		_decks.append([tx, tx + TANK_W, floor_y - TANK_TIER])
		_pickup(PickupScript.AMMO if i != 1 else PickupScript.HEALTH, Vector2(tx + TANK_W * 0.5, floor_y - TANK_TIER - 30.0))
	# משטח ההפשטה
	var pl := Decor.FlensingPlan.new()
	pl.w = PLAN_W
	pl.tier = PLAN_TIER
	add_world(pl, Vector2(PLAN_X, floor_y))
	var pf = add_floor(PLAN_X, floor_y - PLAN_TIER, PLAN_W, "steel", false, false)
	pf.visible = false
	add_ladder(PLAN_X + 14.0, floor_y - PLAN_TIER)
	add_ladder(PLAN_X + PLAN_W - 38.0, floor_y - PLAN_TIER)
	reserve(Rect2(PLAN_X - 20.0, floor_y - 40.0, PLAN_W + 40.0, 40.0))
	_decks.append([PLAN_X, PLAN_X + PLAN_W, floor_y - PLAN_TIER])
	_pickup(PickupScript.GRENADE, Vector2(PLAN_X + PLAN_W * 0.35, floor_y - PLAN_TIER - 30.0))
	_pickup(PickupScript.AMMO, Vector2(PLAN_X + PLAN_W * 0.7, floor_y - PLAN_TIER - 30.0))
	# פגרי ECHO (יולדים BONECRAWLER)
	for cx in CARCASSES:
		var ec := Decor.EchoCarcass.new()
		ec.w = CARCASS_W
		ec.spawn_kind = Registry.BONECRAWLER
		add_world(ec, Vector2(float(cx), floor_y))
		reserve(Rect2(float(cx) - 40.0, floor_y - 60.0, CARCASS_W + 80.0, 60.0))
	# ספינת הציד על המסילה: סיפון + גג תא ההגה + קן העורב
	var bt := Decor.CatcherBoat.new()
	bt.w = BOAT_W
	bt.deck = BOAT_DECK
	bt.cab = BOAT_CAB
	add_world(bt, Vector2(BOAT_X, floor_y))
	var df = add_floor(BOAT_X - 40.0, floor_y - BOAT_DECK, BOAT_W + 46.0, "steel", false, false)
	df.visible = false
	var cf = add_floor(BOAT_X + bt.cab_x.x, floor_y - BOAT_CAB, bt.cab_x.y - bt.cab_x.x, "steel", false, false)
	cf.visible = false
	var nest = add_floor(BOAT_X + 88.0, floor_y - BOAT_DECK - 196.0, 32.0, "steel", false, false)
	nest.visible = false
	add_ladder(BOAT_X + 30.0, floor_y - BOAT_DECK)
	add_ladder(BOAT_X + BOAT_W - 30.0, floor_y - BOAT_DECK)
	add_ladder(BOAT_X + bt.cab_x.x + 10.0, floor_y - BOAT_CAB, floor_y - BOAT_DECK)
	reserve(Rect2(BOAT_X - 70.0, floor_y - 40.0, BOAT_W + 120.0, 40.0))
	_decks.append([BOAT_X + 20.0, BOAT_X + bt.cab_x.x - 10.0, floor_y - BOAT_DECK])
	_pickup(PickupScript.HEALTH, Vector2(BOAT_X + (bt.cab_x.x + bt.cab_x.y) * 0.5, floor_y - BOAT_CAB - 30.0))
	# תותחי צלצל
	for gd in GUNS:
		var hg := Decor.HarpoonGun.new()
		hg.face = float(gd[1])
		hg.pedestal = float(gd[2])
		add_world(hg, Vector2(float(gd[0]), floor_y))
		if float(gd[2]) < 100.0:
			reserve(Rect2(float(gd[0]) - 50.0, floor_y - 40.0, 100.0, 40.0))
	# תנורי שמן
	for px in POTS:
		var tp := Decor.TryPot.new()
		add_world(tp, Vector2(float(px), floor_y))
		reserve(Rect2(float(px) - 30.0, floor_y - 40.0, Decor.TryPot.W + 60.0, 40.0))
	# זירת THE BONE KING: כס העצמות, חביות (הוא נתקע בהן בהסתערות), קרש מוגבה
	var th := Decor.BoneThrone.new()
	th.w = level_w - ARENA_X
	add_world(th, Vector2(ARENA_X, floor_y))
	reserve(Rect2(ARENA_X, floor_y - 40.0, level_w - ARENA_X, 40.0))
	for ax in ARENA_CASKS:
		var o := Decor.Obstacle.new()
		o.kind = "casks"
		o.size = Vector2(84.0, 58.0)
		o.seed_v = int(ax)
		add_world(o, Vector2(float(ax), floor_y))
	var ap = add_floor(ARENA_X + 420.0, floor_y - 130.0, 170.0, "steel", false, false)
	ap.visible = false
	add_ladder(ARENA_X + 430.0, floor_y - 130.0)
	_pickup(PickupScript.HEALTH, Vector2(ARENA_X + 60.0, floor_y - 30.0))
	_pickup(PickupScript.AMMO, Vector2(ARENA_X + 140.0, floor_y - 30.0))
	_pickup(PickupScript.GRENADE, Vector2(ARENA_X + 505.0, floor_y - 160.0))


func _pickup(kind: int, pos: Vector2) -> void:
	var p = PickupScript.new()
	p.kind = kind
	p.life = 100000.0
	main.add_child(p)
	p.setup(pos, Vector2.ZERO)


func build_effects() -> void:
	fx = Decor.GreyFX.new()
	fx.vp = vp
	screen_layer.add_child(fx)


# FLENSER על הקרקע ועל הבמות, סקואות על המיכלים ובתורן, BONECRAWLER משוטט, שניים שומרים בזירה
func extra_spawns() -> void:
	for fx0 in FLENSERS:
		spawn(Registry.FLENSER, float(fx0))
	spawn(Registry.FLENSER, PLAN_X + PLAN_W * 0.55, floor_y - PLAN_TIER)
	for cx in CRAWLERS:
		spawn(Registry.BONECRAWLER, float(cx))
	spawn(Registry.SKUA, TANKS[1][0] + TANK_W * 0.6, floor_y - TANK_TIER)
	spawn(Registry.SKUA, BOAT_X + 104.0, floor_y - BOAT_DECK - 196.0)
	spawn(Registry.SKUA, TANKS[2][0] + TANK_W * 0.5, floor_y - TANK_TIER)
	for d in _decks:
		spawn(0, lerpf(float(d[0]), float(d[1]), 0.6), float(d[2]))
	spawn(0, ARENA_X + 260.0)
	spawn(1, ARENA_X + 340.0)


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
	_gulls_t -= 10.0 / 60.0
	if _gulls_t <= 0.0:
		_gulls_t = randf_range(9.0, 16.0)
		Sfx.play("s58_gulls", null, -10.0, 0.15, 1)


# גלי סקואות מהשמיים (מהצד שלפניך; אחרי שלמדו - בזוגות, אחד מכל צד)
func _waves(pl: Node) -> void:
	var px: float = pl.global_position.x
	for i in SKUA_WAVES.size():
		if _waves_done.has(i) or px < float(SKUA_WAVES[i]):
			continue
		_waves_done[i] = true
		if px > float(SKUA_WAVES[i]) + 700.0:   # (עבר מהר / קפיצה) - לא שולחים גל מאחור
			continue
		var n := 2 if SkuaT.is_learned(main) else 1
		n = mini(n, SKUA_MAX - _skuas_up(px))
		for k in n:
			var side := 1.0 if k == 0 else -1.0
			var sx: float = clampf(px + side * (620.0 + float(k) * 80.0), 80.0, ARENA_X - 100.0)
			var z = spawn(Registry.SKUA, sx, floor_y - 330.0 - float(k) * 40.0)
			if z != null:
				z.set_meta("sk_fly", true)
		if n == 2 and not main.has_meta("sk_pair_said"):
			main.set_meta("sk_pair_said", true)
			pl._say("Two of them... from both sides.", Color("ffb070"))


# כמה סקואות כבר באוויר לידך (לא יותר מ-SKUA_MAX)
func _skuas_up(px: float) -> int:
	var n := 0
	for z in get_tree().get_nodes_in_group("zombies"):
		if z.kind == Registry.SKUA and not z.dead and absf(z.global_position.x - px) < 1400.0 and z.global_position.y < floor_y - 60.0:
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
		if _seen.has(k) or not (k == Registry.FLENSER or k == Registry.SKUA or k == Registry.BONECRAWLER):
			continue
		if absf(z.global_position.x - pl.global_position.x) > 600.0 or not Art.on_screen(z, z.global_position, -40.0):
			continue
		_seen[k] = true
		if k == Registry.FLENSER:
			z._popup("THEY WEAR BONE NOW", Color("ff8a7a"), 15, -90.0)
			pl._say("Skulls break... whale bone doesn't. Shoot UNDER the shield.", Color("e8dcc0"))
		elif k == Registry.SKUA:
			z._popup("THEY DIVE NOW", Color("ff8a7a"), 15, -100.0)
			pl._say("They learned it from the skuas... SHOOT THE WINGS.", Color("e8dcc0"))
		else:
			z._popup("THEY GROW IN ANY DEAD NOW", Color("ff8a7a"), 15, -80.0)
			pl._say("A whale's ribcage... with people inside. Break the ribs.", Color("b8ff9a"))
		return


# הסיפור הסביבתי: שורות של הגיבור במקומות קבועים
func _lines(pl: Node) -> void:
	var px: float = pl.global_position.x
	for i in LINES.size():
		if _lines_done.has(i) or px < float(LINES[i][0]):
			continue
		_lines_done[i] = true
		if px > float(LINES[i][0]) + 900.0:
			continue
		pl._say(str(LINES[i][1]), Color(str(LINES[i][2])))
		if i == LINES.size() - 1 and fx != null:
			fx.gust()
