extends "res://levels/stage_base.gd"
# ============================================================
#  STAGE 57 - "PENGUIN COAST" (אזור שביעי - פטגוניה, שלב 3) - "THEY LEARNED TO BE MANY"
#  (הסיפור: THE ARCHITECT מת בשלב 54 וזה לא שינה כלום - אין יותר מנהיג, הכוורת חושבת כאחד. בחוף הקר שבסוף העולם
#   המתים למדו שגוף אפשר לירות - אז הם הפסיקו להזדקק לגוף אחד. להקת ציפורים בצורת אדם, מתים שמתחבאים בתוך
#   מושבת פינגווינים כי למדו שאתה לא יורה לתוך קהל. וכאן, ליד המגדלור, הכוורת מדברת בפעם הראשונה (THE CHORUS).)
#  (effects/s57_decor.gd): שמיים מעוננים וקרני שמש, הרי טיירה דל פואגו וקרחונים, המפרץ עם גלים וסלעים מלאי חיות,
#  סוללת חלוקים עם טוסוק ומחילות פינגווינים. בעולם: מושבות פינגווינים חיות (Colony), המגדלור, תחנת ציד לווייתנים.
#  קומה שנייה: שלד הלווייתן (SKELETONS), גגות מיכלי השמן (TANKS), עגורן ההפשטה (GANTRY), גג בית השומר + מרפסת
#    המגדלור (LIGHTHOUSE_X) - סולמות בכל אחד, אספקה למעלה.
#  מלכודות: OilBurst (OIL_BURSTS) - מיכל שמן: יורים בו -> כתם שמן שנדלק. GantryHook (בעגורן) - וו ענק שמתנדנד לרוחב הדרך.
#           WaveSurge (WAVES) - הים שוטף את החוף, דוחף אותך ומפיל זומבים. SlickRocks (ROCKS) - סלעים חלקים.
#  זומבים: WADDLER (מתחבא בתוך מושבת הפינגווינים, COLONIES), MURMUR (להקה בצורת אדם, MURMURS), BLUBBER (עור פיל ים,
#          מסתער על הבטן, BLUBBERS), רגילים, רצים.
#  בוס: THE BEACHMASTER (enemies/types/waddler.gd, מצב בוס) - בחוף בסוף (BossBeach).
#  "הם לומדים" (חוק הסיפור 3): הנבגים בהריגה מגיעים מ-effects/spore_lesson.gd (zombie.gd, משלב 55).
#  קטע סיפור (STORY_X): חוף נקי אחרי המגדלור, עם מושבה בלי זומבים (STORY_COLONY) בשביל השחקן של הסצנה.
#    on_story_beat(): "flock_form" (פנים ענקיות של ציפורים מעל הים), "flock_break" (מתפרקות ועפות), "penguins_flee",
#    "talk_on" / "talk_off" (הפה של הפנים זז), "wind" (משב), "beam" (אלומת המגדלור מתחזקת).
#  לשנות: COLONIES, STORY_COLONY, SKELETONS, TANKS, GANTRY, LIGHTHOUSE_X, OIL_BURSTS, WAVES, ROCKS, MURMURS, BLUBBERS,
#         STORY_X, zombie_weights().
# ============================================================

const Decor := preload("res://effects/s57_decor.gd")
const PickupScript := preload("res://pickup.gd")
const Sfx := preload("res://sfx.gd")

const SOUNDS := {
	"pg_squawk": {"drive": 2.2, "layers": [["V", 520, 430, 0.0, 0.18, 0.01, 6.0, 0.6, 1.0, 0.04, 0, [900, 2100, 30]], ["V", 480, 400, 0.22, 0.32, 0.01, 4.0, 0.7, 1.0, 0.05, 0, [850, 2000, 34]], ["V", 560, 470, 0.58, 0.22, 0.01, 6.0, 0.5, 1.0, 0.04, 0, [950, 2200, 30]]]},
	"pg_flee": [["N", 0, 0, 0.0, 0.7, 0.02, 3.5, 0.35, 0.5, 0, 0.3], ["V", 600, 500, 0.0, 0.25, 0.01, 6.0, 0.4, 1.0, 0.05, 0, [1000, 2300, 30]], ["V", 540, 430, 0.18, 0.25, 0.01, 6.0, 0.35, 1.0, 0.05, 0, [900, 2100, 30]], ["B", 1.6, 1.6, 0.0, 0.6, 0.0, 4.0, 0.15, 1.0, 0, 0, 60.0]],
	"s57_burst": {"rev": 0.25, "layers": [["S", 220, 90, 0.0, 0.4, 0.0, 6.0, 0.6, 1.0, 0.02], ["N", 0, 0, 0.0, 0.5, 0.0, 6.0, 0.6, 0.4, 0], ["B", 0.6, 0.6, 0.05, 0.9, 0.0, 2.5, 0.4, 1.0, 0, 0, 90.0], ["S", 1300, 900, 0.0, 0.25, 0.0, 9.0, 0.15, 1.0, 0.03]]},
	"s57_whoosh": {"rev": 0.2, "drive": 2.0, "layers": [["N", 0, 0, 0.0, 1.2, 0.08, 2.2, 0.9, 0.12, 0, 0.02], ["C", 0, 0, 0.1, 1.2, 0.1, 2.0, 0.5, 1.0, 0]]},
	"s57_chain": [["C", 0, 0, 0.0, 0.7, 0.0, 2.0, 0.8, 1.0, 0], ["S", 1900, 1700, 0.0, 0.05, 0.0, 60.0, 0.2, 1.0, 0], ["S", 2300, 2100, 0.2, 0.05, 0.0, 60.0, 0.2, 1.0, 0], ["S", 1700, 1600, 0.4, 0.05, 0.0, 60.0, 0.2, 1.0, 0], ["S", 2100, 2000, 0.55, 0.05, 0.0, 60.0, 0.2, 1.0, 0]],
	"s57_swoosh": [["N", 0, 0, 0.0, 0.7, 0.2, 2.5, 0.7, 0.18, 0, 0.05], ["S", 90, 60, 0.0, 0.7, 0.2, 2.5, 0.3, 1.0, 0.0]],
	"s57_wave_roar": {"rev": 0.3, "layers": [["N", 0, 0, 0.0, 1.4, 0.6, 0.6, 0.7, 0.08, 0, 0.02], ["N", 0, 0, 0.3, 1.1, 0.4, 1.2, 0.35, 0.35, 0, 0.2]]},
	"s57_wave_crash": {"rev": 0.35, "drive": 1.8, "layers": [["N", 0, 0, 0.0, 1.8, 0.02, 1.6, 1.0, 0.3, 0, 0.05], ["N", 0, 0, 0.0, 0.3, 0.0, 9.0, 0.7, 0.8, 0, 0.3], ["B", 0.8, 0.8, 0.2, 1.4, 0.0, 1.6, 0.3, 1.0, 0, 0, 140.0], ["S", 70, 40, 0.0, 0.8, 0.0, 4.0, 0.5, 1.0, 0.0]]},
	"s57_wind": {"rev": 0.3, "layers": [["N", 0, 0, 0.0, 3.0, 1.0, 0.6, 0.35, 0.12, 0, 0.2], ["N", 0, 0, 0.3, 2.4, 0.8, 0.8, 0.2, 0.5, 0, 0.6]]},
	"s57_chorus": {"rev": 0.45, "drive": 1.6, "layers": [["V", 160, 150, 0.0, 2.5, 0.6, 0.8, 0.5, 1.0, 0.03, 0, [500, 900, 6]], ["V", 240, 226, 0.1, 2.4, 0.6, 0.8, 0.4, 1.0, 0.03, 0, [650, 1300, 5]], ["V", 330, 318, 0.2, 2.3, 0.6, 0.8, 0.3, 1.0, 0.03, 0, [800, 1800, 7]], ["N", 0, 0, 0.0, 2.6, 0.8, 0.6, 0.25, 0.3, 0, 0.3]]},
}

const COLONIES := [[1150.0, 16, 1], [2350.0, 18, 1], [4150.0, 18, 2], [8450.0, 20, 2]]   # [x, פינגווינים, כמה WADDLER בפנים]
const STORY_COLONY := [6240.0, 20]
const BOSS_COLONY := [9620.0, 22]
const SKELETONS := [2700.0]                # שלד לווייתן (x שמאלי, הגולגולת עוד 170 שמאלה)
const SKEL_W := 440.0
const SKEL_TIER := 170.0
const TANKS := [3330.0, 4640.0]
const TANK_W := 170.0
const TANK_TIER := 165.0
const GANTRY := 3820.0
const GANTRY_W := 260.0
const GANTRY_TIER := 205.0
const LIGHTHOUSE_X := 5350.0              # מרכז המגדל
const HOUSE_TIER := 150.0
const GALLERY_TIER := 300.0
const OIL_BURSTS := [3640.0, 5000.0, 8900.0]
const WAVES := [[1620.0, 480.0], [7760.0, 420.0]]   # [x, רוחב]
const ROCKS := [880.0, 3150.0, 8180.0]
const MURMURS := [1900.0, 3700.0, 4900.0, 8000.0, 8900.0]
const BLUBBERS := [1700.0, 3050.0, 4420.0, 7900.0, 9050.0]
const STORY_X := Vector2(5600.0, 7600.0)  # קטע ישר ונקי לסצנה
const ARENA_X := 9240.0
const HARDER := [1.0, 1.15, 1.3]

var colonies := []
var fx: Node = null
var lighthouse: Node = null
var _decks := []        # [x0, x1, y]


func zombie_weights() -> Dictionary:
	return {Registry.WADDLER: 0.03, Registry.MURMUR: 0.025, Registry.BLUBBER: 0.03, 0: 0.56, 1: 0.33}


func zombie_density() -> float:
	return 1.0 * float(HARDER[clampi(Settings.difficulty, 0, 2)])


func generators() -> Array:
	return [["drums", 1.0], ["boat", 0.6], ["boulders", 0.9], ["vertebra", 0.5]]


func custom_gen(gname: String, x: float) -> float:
	if not gname in ["drums", "boat", "boulders", "vertebra"]:
		return 0.0
	var sz := Vector2(80.0, 56.0)
	match gname:
		"drums":
			sz = Vector2(rng.randf_range(70.0, 80.0), rng.randf_range(58.0, 66.0))
		"boat":
			sz = Vector2(rng.randf_range(130.0, 150.0), rng.randf_range(44.0, 52.0))
		"boulders":
			sz = Vector2(rng.randf_range(90.0, 120.0), rng.randf_range(48.0, 64.0))
		_:
			sz = Vector2(rng.randf_range(96.0, 110.0), rng.randf_range(46.0, 54.0))
	if not free_x(x, 30.0) or not free_x(x + sz.x, 30.0):   # לא על מושבה / מלכודת / סולם / קטע הסיפור / הזירה
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
	return Registry.WADDLER


func music() -> String:
	return "res://music/level1_total_war.mp3"


func world_tint() -> Color:
	return Color(0.97, 0.99, 1.0)


func fog() -> bool:
	return false


func pits() -> int:
	return 0


func build_background(layer: CanvasLayer) -> Node:
	Decor.U.face_ms = -1   # (סטטי - נשאר מריצה קודמת)
	Decor.U.break_ms = -1
	Decor.U.talk = 0.0
	var bg = Backdrop.new()
	bg.level_w = level_w
	bg.sky = func(ci: CanvasItem, v: Vector2, t: float):
		Decor.coast_sky(ci, v, t)
	bg.add_layer(0.06, func(ci: CanvasItem, sc: float, v: Vector2, t: float):
		Decor.far_coast(ci, sc, v, 556.0, t))
	bg.add_layer(0.28, func(ci: CanvasItem, sc: float, v: Vector2, t: float):
		Decor.mid_bay(ci, sc, v, 612.0, t))
	bg.add_layer(0.6, func(ci: CanvasItem, sc: float, v: Vector2, t: float):
		Decor.near_shore(ci, sc, v, 636.0, t))
	bg.overlay = func(ci: CanvasItem, v: Vector2, t: float):
		Decor.coast_overlay(ci, v, t)
	layer.add_child(bg)
	return bg


func build_world() -> void:
	var x := 0.0
	while x < level_w:
		var g := Decor.BeachGround.new()
		g.w = minf(1024.0, level_w - x)
		g.depth = main.floor_thickness
		g.seed_v = rng.randi()
		add_world(g, Vector2(x, floor_y))
		x += 1024.0
	# קטע הסיפור: נקי לגמרי (קודם, כדי שאף דבר לא ייכנס אליו)
	reserve(Rect2(STORY_X.x - 30.0, floor_y - 60.0, STORY_X.y - STORY_X.x + 60.0, 60.0))
	# מושבות פינגווינים
	var all_c := COLONIES.duplicate()
	all_c.append([STORY_COLONY[0], STORY_COLONY[1], 0])
	all_c.append([BOSS_COLONY[0], BOSS_COLONY[1], 0])
	for c in all_c:
		var col := Decor.Colony.new()
		col.n = int(c[1])
		col.seed_v = rng.randi() % 100000
		add_world(col, Vector2(float(c[0]), floor_y))
		colonies.append(col)
		if float(c[0]) < ARENA_X and absf(float(c[0]) - STORY_COLONY[0]) > 1.0:
			reserve(Rect2(float(c[0]) - 90.0, floor_y - 40.0, 180.0, 40.0))
	# שלד לווייתן: קרש על עמוד השדרה = קומה
	for sx in SKELETONS:
		var sk := Decor.WhaleSkeleton.new()
		sk.w = SKEL_W
		sk.tier = SKEL_TIER
		add_world(sk, Vector2(sx, floor_y))
		var pf = add_floor(sx, floor_y - SKEL_TIER, SKEL_W, "steel", false, false)
		pf.visible = false
		add_ladder(sx + 12.0, floor_y - SKEL_TIER)
		add_ladder(sx + SKEL_W - 36.0, floor_y - SKEL_TIER)
		reserve(Rect2(sx - 200.0, floor_y - 40.0, 240.0, 40.0))
		reserve(Rect2(sx + SKEL_W - 50.0, floor_y - 40.0, 60.0, 40.0))
		_decks.append([sx, sx + SKEL_W, floor_y - SKEL_TIER])
		_pickup(PickupScript.AMMO, Vector2(sx + SKEL_W * 0.5, floor_y - SKEL_TIER - 30.0))
	# מיכלי שמן (הגג = קומה)
	for i in TANKS.size():
		var tx: float = TANKS[i]
		var tk := Decor.Tank.new()
		tk.w = TANK_W
		tk.tier = TANK_TIER
		tk.seed_v = rng.randi() % 100000
		add_world(tk, Vector2(tx, floor_y))
		var tf = add_floor(tx - 4.0, floor_y - TANK_TIER, TANK_W + 8.0, "steel", false, false)
		tf.visible = false
		add_ladder(tx - 26.0, floor_y - TANK_TIER)
		reserve(Rect2(tx - 40.0, floor_y - 40.0, TANK_W + 90.0, 40.0))
		_decks.append([tx, tx + TANK_W, floor_y - TANK_TIER])
		_pickup(PickupScript.HEALTH if i == 0 else PickupScript.AMMO, Vector2(tx + TANK_W * 0.5, floor_y - TANK_TIER - 30.0))
	# עגורן ההפשטה + הוו
	var gn := Decor.Gantry.new()
	gn.w = GANTRY_W
	gn.tier = GANTRY_TIER
	add_world(gn, Vector2(GANTRY, floor_y))
	var gf = add_floor(GANTRY - 8.0, floor_y - GANTRY_TIER - 8.0, GANTRY_W + 16.0, "steel", false, false)
	gf.visible = false
	add_ladder(GANTRY + 30.0, floor_y - GANTRY_TIER - 8.0)
	add_ladder(GANTRY + GANTRY_W - 54.0, floor_y - GANTRY_TIER - 8.0)
	reserve(Rect2(GANTRY - 40.0, floor_y - 40.0, GANTRY_W + 80.0, 40.0))
	_decks.append([GANTRY, GANTRY + GANTRY_W, floor_y - GANTRY_TIER - 8.0])
	_pickup(PickupScript.GRENADE, Vector2(GANTRY + GANTRY_W * 0.5 - 40.0, floor_y - GANTRY_TIER - 38.0))
	var hk := Decor.GantryHook.new()
	hk.tier = GANTRY_TIER
	add_world(hk, Vector2(GANTRY + GANTRY_W * 0.5, floor_y))
	# המגדלור: גג בית השומר + המרפסת למעלה
	lighthouse = Decor.Lighthouse.new()
	lighthouse.house_tier = HOUSE_TIER
	lighthouse.gallery_tier = GALLERY_TIER
	add_world(lighthouse, Vector2(LIGHTHOUSE_X, floor_y))
	var hx0: float = LIGHTHOUSE_X + lighthouse.house.x
	var hx1: float = LIGHTHOUSE_X + lighthouse.house.y
	var hf = add_floor(hx0 - 6.0, floor_y - HOUSE_TIER - 8.0, hx1 - hx0 + 12.0, "steel", false, false)
	hf.visible = false
	add_ladder(hx0 + 8.0, floor_y - HOUSE_TIER - 8.0)
	var gal = add_floor(LIGHTHOUSE_X - 62.0, floor_y - GALLERY_TIER, 124.0, "steel", false, false)
	gal.visible = false
	add_ladder(hx1 - 36.0, floor_y - GALLERY_TIER, floor_y - HOUSE_TIER - 8.0)
	reserve(Rect2(hx0 - 20.0, floor_y - 40.0, LIGHTHOUSE_X + 60.0 - hx0, 40.0))
	_decks.append([hx0, hx1, floor_y - HOUSE_TIER - 8.0])
	_pickup(PickupScript.HEALTH, Vector2(LIGHTHOUSE_X, floor_y - GALLERY_TIER - 30.0))
	# מלכודות
	for ox in OIL_BURSTS:
		var bx: float = ox
		while not free_x(bx, 40.0) and bx < level_w - 1500.0:
			bx += 50.0
		add_world(Decor.OilBurst.new(), Vector2(bx, floor_y))
		reserve(Rect2(bx - 40.0, floor_y - 40.0, 80.0, 40.0))
	for wv in WAVES:
		var ws := Decor.WaveSurge.new()
		ws.w = float(wv[1])
		add_world(ws, Vector2(float(wv[0]), floor_y))
		reserve(Rect2(float(wv[0]), floor_y - 30.0, float(wv[1]), 30.0))
	for rx in ROCKS:
		var rk := Decor.SlickRocks.new()
		rk.seed_v = rng.randi() % 100000
		add_world(rk, Vector2(float(rx), floor_y))
		reserve(Rect2(float(rx) - rk.w * 0.5, floor_y - 30.0, rk.w, 30.0))
	# חוף ה-BEACHMASTER
	var bb := Decor.BossBeach.new()
	add_world(bb, Vector2(ARENA_X, floor_y))
	reserve(Rect2(ARENA_X, floor_y - 40.0, level_w - ARENA_X, 40.0))
	_pickup(PickupScript.HEALTH, Vector2(ARENA_X + 60.0, floor_y - 30.0))
	_pickup(PickupScript.AMMO, Vector2(ARENA_X + 130.0, floor_y - 30.0))


func _pickup(kind: int, pos: Vector2) -> void:
	var p = PickupScript.new()
	p.kind = kind
	p.life = 100000.0
	main.add_child(p)
	p.setup(pos, Vector2.ZERO)


func build_effects() -> void:
	fx = Decor.CoastFX.new()
	fx.vp = vp
	screen_layer.add_child(fx)


# WADDLER בתוך המושבות, BLUBBER על החוף, MURMUR באוויר, רגילים על הקומות, שניים בזירה.
func extra_spawns() -> void:
	for c in COLONIES:
		for k in int(c[2]):
			spawn(Registry.WADDLER, float(c[0]) + (float(k) - 0.5 * float(int(c[2]) - 1)) * 30.0)
	for bx in BLUBBERS:
		var x: float = bx
		if x > STORY_X.x - 100.0 and x < STORY_X.y + 100.0:
			continue
		spawn(Registry.BLUBBER, x)
	for mx in MURMURS:
		spawn(Registry.MURMUR, float(mx))
	for d in _decks:
		spawn(0, lerpf(float(d[0]), float(d[1]), 0.6), float(d[2]))
	spawn(0, ARENA_X + 260.0)
	spawn(1, ARENA_X + 340.0)


# ============ קטע סיפור ============
# x של הקטע הנקי: STORY_X (5600..7600), מיד אחרי המגדלור. מושבה בלי זומבים ב-STORY_COLONY (6240) לשחקן של הסצנה.
func story_stretch() -> Vector2:
	return STORY_X


func story_colony() -> Node:
	for c in colonies:
		if absf(c.global_position.x - STORY_COLONY[0]) < 1.0:
			return c
	return null


# "flock_form" - להקה ענקית יוצרת פנים מעל הים (בלי נזק), "flock_break" - הפנים מתפרקות ועפות,
# "penguins_flee" - כל המושבות הקרובות בורחות, "talk_on" / "talk_off" - הפה של הפנים זז, "wind" - משב, "beam" - אלומת המגדלור
func on_story_beat(id: String) -> void:
	var pl := get_tree().get_first_node_in_group("player") as Node2D
	match id:
		"flock_form":
			Decor.U.face_ms = Time.get_ticks_msec()
			Decor.U.break_ms = -1
			Decor.U.talk = 0.6
			Sfx.play("s57_chorus", null, 0.0)
			Sfx.play("pg_flee", null, -4.0)
		"flock_break":
			if Decor.U.face_ms < 0:
				Decor.U.face_ms = Time.get_ticks_msec() - 4000
			Decor.U.break_ms = Time.get_ticks_msec()
			Decor.U.talk = 0.0
			Sfx.play("s57_whoosh", null, 0.0)
			if fx != null:
				fx.gust()
		"talk_on":
			Decor.U.talk = 1.0
		"talk_off":
			Decor.U.talk = 0.0
		"penguins_flee":
			for c in colonies:
				if pl == null or absf(c.global_position.x - pl.global_position.x) < 1500.0:
					c.scatter(pl.global_position.x if pl != null else c.global_position.x - 200.0, true)
		"wind":
			if fx != null:
				fx.gust()
		"beam":
			if lighthouse != null:
				lighthouse.beams = 1.0
