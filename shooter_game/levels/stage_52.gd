extends "res://levels/stage_base.gd"
# ============================================================
#  STAGE 52 - "RAIL YARD" (אזור שישי - החרוט הדרומי, שלב 7) - "THEY LEARNED THE TIMETABLE"
#  (הסיפור: מהחווה הגיבור מגיע למגרש רכבות המשא הענק בקצה בואנוס איירס. המתים עולים על הרכבות דרומה - כולם,
#   בסדר, לפי לוח זמנים. וחלק מהמתים... נושמים: בוגדים חיים (QUISLING) שלובשים עור של מתים והולכים בתוך העדר.
#   מישהו חושב בשבילם עכשיו - THE ARCHITECT. והוא מחכה בסוף הקו.)
#  (effects/s52_decor.gd): דמדומי סמוג כתומים שהופכים לערב של נתרן, העיר הרחוקה, רוטונדה, רכבת זומבים שנוסעת דרומה.
#  קומה שנייה: גגות הקרונות (BOXCARS), גשרי האיתות (GANTRIES) ובמות מגדלי הפחם (HOPPERS) - סולמות בכל אחד.
#  מלכודות: Switch - מנוף העתקה (SWITCHES): עוברים לידו -> פעמון -> קרון שטוח בורח מתגלגל מקדימה (לקפוץ!). לירות במנוף
#             = הקרון יוצא מהמנוף ברגע שתבחר - ודורס את הזומבים שבדרך.
#           LiveWire - חוט חשמל עילי קרוע (WIRES): מזמזם ואז מכה בקרקע בקשת חשמל (פוגע בך, מטגן זומבים).
#  פנסי נתרן (LAMPS) לאורך כל השלב - כדי שהדמויות ייקראו בערב.
#  זומבים: HAULER (גופה בתוך מכונה הולכת על 4 רגלי ברזל - "גיו" של ג'וני איטו - מיכל גז בגב שמתפוצץ),
#          QUISLING (בוגד חי בתחפושת של עור מת, בתוך קבוצות זומבים), STRAGGLER (מת קפוא בשגרה - זז רק כשאתה לא מסתכל),
#          רגילים, רצים.
#  בוס: THE ENGINE (enemies/types/hauler.gd, מצב בוס) - בגלגלת של בית הקטרים בסוף. בתא הבקרה המוגבה אפשר להתחבא מההסתערות.
#  לשנות: BOXCARS, CAR_TIER, GANTRIES, GANTRY_TIER, HOPPERS, HOPPER_TIER, SWITCHES, WIRES, LAMPS, QUISLING_GROUPS,
#         STRAGGLERS, HAULERS, zombie_weights().
# ============================================================

const Decor := preload("res://effects/s52_decor.gd")
const PickupScript := preload("res://pickup.gd")

const SOUNDS := {
	"sw_bell": [["S", 1320, 1310, 0.0, 0.5, 0.0, 6.0, 0.4, 1.0, 0], ["S", 2650, 2640, 0.0, 0.35, 0.0, 9.0, 0.18, 1.0, 0], ["S", 1320, 1310, 0.22, 0.4, 0.0, 6.0, 0.3, 1.0, 0]],
	"sw_roll": {"rev": 0.2, "layers": [["N", 0, 0, 0.0, 1.4, 0.2, 1.2, 0.5, 0.12, 0], ["S", 60, 50, 0.0, 1.4, 0.2, 1.2, 0.5, 1.0, 0.05], ["S", 1900, 1700, 0.0, 1.2, 0.1, 2.0, 0.05, 1.0, 0.02]]},
	"lw_buzz": [["Q", 100, 100, 0.0, 0.75, 0.05, 1.0, 0.18, 0.5, 0.02], ["N", 0, 0, 0.0, 0.75, 0.1, 1.5, 0.15, 0.9, 0, 0.5], ["C", 0, 0, 0.0, 0.75, 0.0, 1.0, 0.6, 1.0, 0]],
}

const BOXCARS := [0.09, 0.3, 0.51, 0.72]   # קרונות (הגג = קומה)
const CAR_TIER := 134.0
const GANTRIES := [0.19, 0.62]            # גשרי איתות
const GANTRY_TIER := 196.0
const HOPPERS := [0.41, 0.84]             # מגדלי פחם
const HOPPER_TIER := 176.0
const SWITCHES := [0.24, 0.47, 0.78]      # מנופי העתקה (קרון בורח)
const WIRES := [0.14, 0.36, 0.57, 0.67, 0.9]   # חוטי חשמל קרועים
const LAMPS := 0.075                     # פנס נתרן כל ...
const QUISLING_GROUPS := [0.16, 0.33, 0.55, 0.7, 0.88]   # קבוצת רגילים + בוגד בתוכה
const STRAGGLERS := [0.2, 0.27, 0.38, 0.53, 0.65, 0.8, 0.92]
const HAULERS := [0.35, 0.6, 0.86]
const HARDER := [1.0, 1.15, 1.3]

var _decks := []        # [x0, x1, y]


func zombie_weights() -> Dictionary:
	return {Registry.STRAGGLER: 0.05, Registry.HAULER: 0.035, Registry.QUISLING: 0.02, 0: 0.55, 1: 0.32}


func zombie_density() -> float:
	return 1.0 * float(HARDER[clampi(Settings.difficulty, 0, 2)])


func generators() -> Array:
	return [["buffer", 0.7], ["sleepers", 1.2], ["crates", 1.0], ["wheels", 0.6]]


func custom_gen(gname: String, x: float) -> float:
	if not gname in ["buffer", "sleepers", "crates", "wheels"]:
		return 0.0
	if not free_x(x, 30.0) or not free_x(x + 130.0, 30.0):   # לא בתוך מלכודת / סולם / זירת הבוס
		return 80.0
	var o := Decor.Obstacle.new()
	o.kind = gname
	o.seed_v = rng.randi()
	match gname:
		"buffer":
			o.size = Vector2(rng.randf_range(80.0, 92.0), rng.randf_range(58.0, 66.0))
		"sleepers":
			o.size = Vector2(rng.randf_range(100.0, 128.0), rng.randf_range(36.0, 54.0))
		"crates":
			o.size = Vector2(rng.randf_range(80.0, 96.0), rng.randf_range(62.0, 72.0))
		_:
			o.size = Vector2(rng.randf_range(96.0, 110.0), rng.randf_range(52.0, 58.0))
	o.position = Vector2(x, floor_y)
	main.add_child(o)
	reserve(Rect2(x, floor_y - o.size.y, o.size.x, o.size.y))
	return o.size.x


func boss_kind() -> int:
	return Registry.HAULER


func music() -> String:
	return "res://music/level1_total_war.mp3"


func world_tint() -> Color:
	return Color(1.0, 0.93, 0.86)


func fog() -> bool:
	return false


func pits() -> int:
	return 0


func build_background(layer: CanvasLayer) -> Node:
	var bg = Backdrop.new()
	bg.level_w = level_w
	bg.sky = func(ci: CanvasItem, v: Vector2, t: float):
		Decor.yard_sky(ci, v, t)
	bg.add_layer(0.06, func(ci: CanvasItem, sc: float, v: Vector2, t: float):
		Decor.far_city(ci, sc, v, 556.0, t))
	bg.add_layer(0.28, func(ci: CanvasItem, sc: float, v: Vector2, t: float):
		Decor.mid_yard(ci, sc, v, 610.0, t))
	bg.add_layer(0.6, func(ci: CanvasItem, sc: float, v: Vector2, t: float):
		Decor.near_rails(ci, sc, v, 636.0, t))
	bg.overlay = func(ci: CanvasItem, v: Vector2, t: float):
		Decor.yard_overlay(ci, v, t)
	layer.add_child(bg)
	return bg


func build_world() -> void:
	var x := 0.0
	while x < level_w:
		var g := Decor.YardGround.new()
		g.w = minf(1024.0, level_w - x)
		g.depth = main.floor_thickness
		g.seed_v = rng.randi()
		add_world(g, Vector2(x, floor_y))
		x += 1024.0
	var lx := level_w * LAMPS * 0.5   # פנסי נתרן (מאחור, לא תופסים מקום)
	while lx < level_w - 600.0:
		var lp := Decor.SodiumLamp.new()
		lp.h = rng.randf_range(280.0, 320.0)
		add_world(lp, Vector2(lx, floor_y))
		lx += level_w * LAMPS
	var cols := [Color("7a3a2a"), Color("5a4a3a"), Color("3a4a5a"), Color("6a3a3a"), Color("4a5a44")]
	for i in BOXCARS.size():   # קרונות: הגג = קומה
		var bx := level_w * float(BOXCARS[i])
		var bc := Decor.Boxcar.new()
		bc.tier = CAR_TIER
		bc.seed_v = rng.randi() % 100000
		bc.col = cols[i % cols.size()]
		add_world(bc, Vector2(bx, floor_y))
		var pf = add_floor(bx - 4.0, floor_y - CAR_TIER, bc.w + 8.0, "steel", false, false)
		pf.visible = false
		add_ladder(bx + 10.0, floor_y - CAR_TIER)
		add_ladder(bx + bc.w - 34.0, floor_y - CAR_TIER)
		reserve(Rect2(bx - 10.0, floor_y - 40.0, bc.w + 20.0, 40.0))
		_decks.append([bx, bx + bc.w, floor_y - CAR_TIER])
		_pickup(PickupScript.AMMO if i % 2 == 0 else PickupScript.HEALTH, Vector2(bx + bc.w * 0.5, floor_y - CAR_TIER - 30.0))
	for f in GANTRIES:   # גשרי איתות
		var gx := level_w * float(f)
		var gn := Decor.Gantry.new()
		gn.tier = GANTRY_TIER
		add_world(gn, Vector2(gx, floor_y))
		var gf = add_floor(gx - 8.0, floor_y - GANTRY_TIER, gn.w + 16.0, "steel", false, false)
		gf.visible = false
		add_ladder(gx + 6.0, floor_y - GANTRY_TIER)
		add_ladder(gx + gn.w - 30.0, floor_y - GANTRY_TIER)
		reserve(Rect2(gx - 10.0, floor_y - 40.0, 40.0, 40.0))
		reserve(Rect2(gx + gn.w - 34.0, floor_y - 40.0, 40.0, 40.0))
		_decks.append([gx, gx + gn.w, floor_y - GANTRY_TIER])
		_pickup(PickupScript.AMMO, Vector2(gx + gn.w * 0.5, floor_y - GANTRY_TIER - 30.0))
	for f in HOPPERS:   # מגדלי פחם
		var hx := level_w * float(f)
		while not free_x(hx, 40.0) and hx < level_w - 1500.0:
			hx += 60.0
		var hp := Decor.Hopper.new()
		hp.tier = HOPPER_TIER
		add_world(hp, Vector2(hx, floor_y))
		var hf = add_floor(hx - 14.0, floor_y - HOPPER_TIER, hp.w + 28.0, "steel", false, false)
		hf.visible = false
		add_ladder(hx - 6.0, floor_y - HOPPER_TIER)
		reserve(Rect2(hx - 20.0, floor_y - 40.0, hp.w + 40.0, 40.0))
		_decks.append([hx - 14.0, hx + hp.w + 14.0, floor_y - HOPPER_TIER])
		_pickup(PickupScript.HEALTH, Vector2(hx + hp.w * 0.5, floor_y - HOPPER_TIER - 30.0))
	for f in SWITCHES:   # מנופי העתקה
		var sx := level_w * float(f)
		while not free_x(sx, 60.0) and sx < level_w - 1400.0:
			sx += 50.0
		add_world(Decor.Switch.new(), Vector2(sx, floor_y))
		reserve(Rect2(sx - 30.0, floor_y - 40.0, 60.0, 40.0))
	for f in WIRES:   # חוטי חשמל קרועים
		var wx := level_w * float(f)
		while not free_x(wx, 70.0) and wx < level_w - 1400.0:
			wx += 50.0
		add_world(Decor.LiveWire.new(), Vector2(wx, floor_y))
		reserve(Rect2(wx - 70.0, floor_y - 30.0, 140.0, 30.0))
	# הגלגלת של בית הקטרים - הזירה של THE ENGINE, עם תא בקרה מוגבה
	var tx := level_w - 1100.0
	var tt := Decor.Turntable.new()
	tt.w = 900.0
	add_world(tt, Vector2(tx, floor_y))
	var bf = add_floor(tx + 30.0, floor_y - tt.booth_tier, 170.0, "steel", false, false)
	bf.visible = false
	add_ladder(tx + 60.0, floor_y - tt.booth_tier)
	reserve(Rect2(tx - 100.0, floor_y - 40.0, 1100.0, 40.0))
	_pickup(PickupScript.HEALTH, Vector2(tx - 140.0, floor_y - 30.0))
	_pickup(PickupScript.AMMO, Vector2(tx - 60.0, floor_y - 30.0))
	_pickup(PickupScript.AMMO, Vector2(tx + 115.0, floor_y - tt.booth_tier - 30.0))


func _pickup(kind: int, pos: Vector2) -> void:
	var p = PickupScript.new()
	p.kind = kind
	p.life = 100000.0
	main.add_child(p)
	p.setup(pos, Vector2.ZERO)


func build_effects() -> void:
	var ash := Ambient.screen_particles("ash", vp)
	ash.color = Color(0.3, 0.26, 0.26, 0.4)
	ash.amount = int(40.0 * clampf(Quality.ambient(), 0.3, 1.0))
	screen_layer.add_child(ash)
	var fx := Decor.YardFX.new()
	fx.vp = vp
	screen_layer.add_child(fx)


# על הקומות - רגילים. בתוך קבוצות רגילים - בוגדים (QUISLING). לאורך המגרש - מתים קפואים (STRAGGLER) ו-HAULER.
func extra_spawns() -> void:
	for d in _decks:
		spawn(0, lerpf(float(d[0]), float(d[1]), 0.5), float(d[2]))
	for i in QUISLING_GROUPS.size():   # הקבוצות גדלות לאורך השלב (3 -> 5): יש לבוגדים הלומדים איפה להתחבא עמוק
		var qx := level_w * float(QUISLING_GROUPS[i])
		if not free_x(qx, 10.0):
			qx += 160.0
		var n := 3 + i / 2
		for k in n:
			spawn(0, qx - 70.0 + float(k) * 60.0)
		spawn(Registry.QUISLING, qx + 35.0)
	for f in STRAGGLERS:
		spawn(Registry.STRAGGLER, level_w * float(f) + rng.randf_range(-60.0, 60.0))
	for f in HAULERS:
		spawn(Registry.HAULER, level_w * float(f))
