extends "res://levels/stage_base.gd"
# ============================================================
#  STAGE 59 - "BLACK FOREST" (אזור שביעי - פטגוניה, שלב 5) - "THEY LEARNED TO BURN"
#  (הסיפור: יער הלנגה של טיירה דל פואגו נשרף. הגיבור שרף כאן אלפים - להביור, בקבוקי תבערה, חביות. כל מי שמת באש נשף
#   את מה שהאש לימדה אותו: האש אוכלת בשר - לא פחם. אז הם התגלגלו באפר עד שנהיו פחם בעצמם, הולכים דרך הלהבות,
#   מתחבאים בעשן - ומוצאים את הגיבור לפי הבזק הקנה שלו. כאן ה-STRANGER מגיע בפעם האחרונה ומודה: "אני לקחתי לך את הזיכרון".)
#  (effects/s59_decor.gd): שמיים של שריפה עם שמש אדומה, הרי מרסיאל ותעלת ביגל, גבעות של גזעים שרופים, שריפות על המדרונות,
#  גזעים שחורים עם סדקים לוחשים. בעולם: שלט הפארק ושעון סכנת אש, בקתת השומרים, מגדל התצפית, בריכות בונים עם סכרים,
#  הטנדר השרוף, קווי אש זוחלים, עצים שעומדים ליפול, גדמים מעלים עשן, והמנסרה הבוערת (זירת הבוס).
#  העשן (המכונאי של השלב): smoke_k() 0..1. CLEAR (CLEAR_T) -> ROLL (ROLL_T: העשן מתגלגל פנימה, "s59_whoosh") ->
#    THICK (THICK_T: רואים רק סביבך - CHARRED רחוקים נעלמים חוץ מהסדקים הלוחשים) -> THIN (THIN_T) -> CLEAR.
#    בעשן ה-ASHMOTH מוצא אותך רק לפי ההבזק (Decor.U.flash - הירייה מאירה את העשן), וגלי העשים באים בזוגות.
#  ההבזק: כל ירייה (Game.shot_id + player._muzzle_flash) -> Decor.U.flash / flash_pos (מסך), last_flash() (עולם) ל-ASHMOTH.
#  מים: בריכות הבונים (PONDS) - הליכה איטית (player.in_water), אש נכבית (CHARRED נכבה - in_water_at()). הסכר = קומה נמוכה.
#  קומה שנייה: גג בקתת השומרים (HUT_X), מגדל התצפית (TOWER_X), ארגז הטנדר (TRUCK_X), הסכרים, במת הבולים במנסרה - אספקה למעלה.
#  מלכודות: FireLine (FIRES: פס אש LOW -> WARN -> FLARE), Snag (SNAGS: עץ שרוף נופל לרוחב הדרך, ירייה בבסיס = נופל עכשיו).
#  קטע סיפור (STORY_X): נקי (בלי מכשולים / מלכודות / זומבים של השלב). ה-STRANGER ב-5450.
#  זומבים: CHARRED (CHARREDS, אחד בתוך כל קו אש), DAMBUILDER (BUILDERS - ליד הבריכות), ASHMOTH (ROOSTS על הגגות + MOTH_WAVES),
#    רגילים, רצים.
#  בוס: THE PYRE (enemies/types/charred.gd, מצב בוס) - מדורה מהלכת במנסרה הבוערת (SAW_X).
#  לשנות: CLEAR_T, ROLL_T, THICK_T, THIN_T, HUT_X, TOWER_X, TRUCK_X, PONDS, FIRES, SNAGS, STORY_X, SAW_X, CHARREDS, BUILDERS,
#    ROOSTS, MOTH_WAVES, STUMPS, zombie_weights().
# ============================================================

const Decor := preload("res://effects/s59_decor.gd")
const AshmothT := preload("res://enemies/types/ashmoth.gd")
const PickupScript := preload("res://pickup.gd")
const Sfx := preload("res://sfx.gd")

const SOUNDS := {
	"s59_crackle": [["C", 0, 0, 0.0, 0.5, 0.0, 4.0, 1.0, 1.0, 0], ["N", 0, 0, 0.0, 0.4, 0.05, 5.0, 0.3, 0.45, 0, 0.4]],
	"s59_flare": {"rev": 0.25, "drive": 1.6, "layers": [["N", 0, 0, 0.0, 1.0, 0.08, 2.4, 0.8, 0.22, 0, 0.1], ["C", 0, 0, 0.0, 1.0, 0.0, 2.6, 0.9, 1.0, 0], ["S", 90, 60, 0.0, 0.7, 0.05, 3.0, 0.35, 1.0, 0.2]]},
	"s59_creak": [["S", 120, 95, 0.0, 0.9, 0.05, 2.0, 0.45, 1.0, 0.25], ["N", 0, 0, 0.0, 0.8, 0.05, 2.6, 0.2, 0.25, 0], ["S", 80, 66, 0.35, 0.7, 0.05, 2.6, 0.35, 1.0, 0.4], ["C", 0, 0, 0.1, 0.6, 0.0, 4.0, 0.5, 1.0, 0]],
	"s59_crack": {"rev": 0.2, "drive": 2.2, "layers": [["C", 0, 0, 0.0, 0.3, 0.0, 9.0, 1.0, 1.0, 0], ["N", 0, 0, 0.0, 0.35, 0.0, 8.0, 0.8, 0.5, 0, 0.3], ["S", 180, 70, 0.0, 0.3, 0.0, 9.0, 0.5, 1.0, 0]]},
	"s59_thud": {"rev": 0.3, "drive": 2.4, "layers": [["N", 0, 0, 0.0, 0.8, 0.0, 4.0, 1.0, 0.1, 0], ["S", 60, 30, 0.0, 0.7, 0.0, 5.0, 1.0, 1.0, 0], ["C", 0, 0, 0.0, 0.6, 0.0, 5.0, 0.8, 1.0, 0]]},
	"s59_whoosh": {"rev": 0.4, "layers": [["N", 0, 0, 0.0, 2.2, 0.8, 1.0, 0.5, 0.15, 0, 0.1], ["C", 0, 0, 0.3, 1.6, 0.4, 1.6, 0.5, 1.0, 0], ["N", 0, 0, 0.4, 1.6, 0.6, 1.4, 0.2, 0.5, 0.3, 0.5]]},
	"s59_hiss": [["N", 0, 0, 0.0, 0.7, 0.0, 3.0, 0.6, 0.9, 0, 0.7], ["B", 22.0, 12.0, 0.0, 0.5, 0.0, 5.0, 0.2, 1.0, 0, 0, 40.0]],
	"s59_splash": [["N", 0, 0, 0.0, 0.3, 0.0, 9.0, 0.6, 0.6, 0, 0.5], ["B", 18.0, 9.0, 0.0, 0.3, 0.0, 8.0, 0.3, 1.0, 0, 0, 30.0]],
}

# ---- העשן ----
const CLEAR_T := Vector2(9.0, 13.0)
const ROLL_T := 2.0
const THICK_T := 6.0
const THIN_T := 2.5
const FIRST_CLEAR := 14.0                # כמה זמן עד העשן הראשון
# ---- מבנה ----
const SIGN_X := 300.0
const HUT_X := 1050.0                    # בקתת השומרים (גג = קומה)
const HUT_W := 300.0
const HUT_TIER := 150.0
const FIRES := [[1760.0, 200.0], [3300.0, 180.0], [6900.0, 210.0], [8380.0, 190.0]]   # [x, רוחב]
const SNAGS := [[2200.0, 250.0], [3800.0, 270.0], [7380.0, 260.0], [8720.0, 240.0]]   # [x, גובה]
const PONDS := [[2420.0, 520.0], [7640.0, 480.0]]   # [x, רוחב] - הסכר בצד ימין (קומה נמוכה)
const POND_DAM := 0.55
const DAM_TIER := 56.0
const TOWER_X := 4130.0                  # מגדל התצפית
const TOWER_W := 140.0
const TOWER_TIER := 220.0
const STORY_X := Vector2(4500.0, 6400.0) # קטע ישר ונקי לסצנת סיפור (STRANGER ב-5450)
const TRUCK_X := 6500.0                  # הטנדר השרוף (ארגז = קומה נמוכה)
const TRUCK_W := 230.0
const TRUCK_TIER := 70.0
const SAW_X := 9000.0                    # זירת הבוס: המנסרה
const SAW_DECK := Vector2(220.0, 180.0)  # [x יחסי, רוחב]
const SAW_TIER := 130.0
const STUMPS := [620.0, 1460.0, 3120.0, 4020.0, 6660.0, 7240.0, 8260.0]
# ---- זומבים ----
const CHARREDS := [1850.0, 2760.0, 3560.0, 7270.0, 8470.0, 8900.0]   # (1850 / 8470 = בתוך קו האש)
const BUILDERS := [2020.0, 3020.0, 7060.0, 8180.0]
const ROOSTS := ["hut", "tower", "truck"]
const MOTH_WAVES := [1550.0, 3150.0, 6700.0, 7900.0, 8820.0]
const HARDER := [1.0, 1.15, 1.3]

var _sph := 0                            # 0 נקי, 1 מתגלגל, 2 סמיך, 3 מתפזר
var _spt := FIRST_CLEAR
var _sk := 0.0
var _last_shot := -1
var _flash_w := Vector2.ZERO             # איפה ההבזק האחרון (עולם)
var _flash_ms := -100000
var _waves_done := {}
var _seen := {}
var _ponds: Array = []
var _fx: Node = null
# לבדיקות
var smokes := 0
var flashes := 0
var thick_shots := 0


func zombie_weights() -> Dictionary:
	return {Registry.CHARRED: 0.045, Registry.ASHMOTH: 0.015, Registry.DAMBUILDER: 0.025, 0: 0.56, 1: 0.33}


func zombie_density() -> float:
	return 1.0 * float(HARDER[clampi(Settings.difficulty, 0, 2)])


func generators() -> Array:
	return [["logs", 1.0], ["stump", 0.7], ["boulder", 0.45], ["rootball", 0.5]]   # (לא "crates" - השם הזה תפוס ב-main.gd)


func custom_gen(gname: String, x: float) -> float:
	if not gname in ["logs", "stump", "boulder", "rootball"]:
		return 0.0
	var sz := Vector2(86.0, 46.0)
	match gname:
		"stump":
			sz = Vector2(rng.randf_range(58.0, 66.0), rng.randf_range(40.0, 48.0))
		"boulder":
			sz = Vector2(rng.randf_range(96.0, 110.0), rng.randf_range(56.0, 64.0))
		"rootball":
			sz = Vector2(rng.randf_range(104.0, 118.0), rng.randf_range(50.0, 58.0))
		_:
			sz = Vector2(rng.randf_range(110.0, 126.0), rng.randf_range(42.0, 50.0))
	if not free_x(x, 30.0) or not free_x(x + sz.x, 30.0):
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
	return Registry.CHARRED


func music() -> String:
	return "res://music/level1_total_war.mp3"


func world_tint() -> Color:
	return Color(1.04, 0.95, 0.88)


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
		Decor.forest_sky(ci, v, t)
	bg.add_layer(0.06, func(ci: CanvasItem, sc: float, v: Vector2, t: float):
		Decor.far_range(ci, sc, v, 556.0, t))
	bg.add_layer(0.28, func(ci: CanvasItem, sc: float, v: Vector2, t: float):
		Decor.mid_burn(ci, sc, v, 612.0, t))
	bg.add_layer(0.6, func(ci: CanvasItem, sc: float, v: Vector2, t: float):
		Decor.near_forest(ci, sc, v, 636.0, t))
	bg.overlay = func(ci: CanvasItem, v: Vector2, t: float):
		Decor.forest_overlay(ci, v, t)
	layer.add_child(bg)
	return bg


func build_world() -> void:
	Decor.U.smoke = 0.0
	Decor.U.flash = 0.0
	Decor.U.sparks_ms = -1
	# קרקע: אפר על אדמה שרופה
	var x := 0.0
	while x < level_w:
		var g := Decor.AshGround.new()
		g.w = minf(1024.0, level_w - x)
		g.depth = main.floor_thickness
		g.seed_v = rng.randi()
		add_world(g, Vector2(x, floor_y))
		x += g.w
	# גדמים מעלים עשן (קישוט)
	for sx in STUMPS:
		var st := Decor.Stump.new()
		st.seed_v = rng.randi()
		add_world(st, Vector2(float(sx), floor_y))
	# שלט הפארק + שעון סכנת האש
	add_world(Decor.ParkSign.new(), Vector2(SIGN_X, floor_y))
	reserve(Rect2(SIGN_X - 30.0, floor_y - 40.0, 480.0, 40.0))
	# בקתת השומרים: גג המרפסת = קומה + 2 סולמות + אספקה
	var hut := Decor.RangerHut.new()
	hut.w = HUT_W
	hut.tier = HUT_TIER
	add_world(hut, Vector2(HUT_X, floor_y))
	_deck(HUT_X - 6.0, HUT_X + HUT_W + 6.0, HUT_TIER + 8.0, [HUT_X + 14.0, HUT_X + HUT_W - 34.0])
	_pickup(PickupScript.AMMO, Vector2(HUT_X + HUT_W * 0.45, floor_y - HUT_TIER - 40.0))
	_pickup(PickupScript.HEALTH, Vector2(HUT_X + HUT_W * 0.72, floor_y - HUT_TIER - 40.0))
	reserve(Rect2(HUT_X - 20.0, floor_y - 40.0, HUT_W + 40.0, 40.0))
	# קווי אש זוחלים
	for f in FIRES:
		var fl := Decor.FireLine.new()
		fl.w = float(f[1])
		add_world(fl, Vector2(float(f[0]), floor_y))
		reserve(Rect2(float(f[0]) - 60.0, floor_y - 40.0, float(f[1]) + 120.0, 40.0))
	# עצים שעומדים ליפול (כל הדרך שהם נופלים עליה שמורה)
	for s in SNAGS:
		var sn := Decor.Snag.new()
		sn.h = float(s[1])
		add_world(sn, Vector2(float(s[0]), floor_y))
		reserve(Rect2(float(s[0]) - float(s[1]) - 20.0, floor_y - 40.0, float(s[1]) * 2.0 + 40.0, 40.0))
	# בריכות הבונים: מים (איטי) + סכר = קומה נמוכה
	for p in PONDS:
		var pd := Decor.BeaverPond.new()
		pd.w = float(p[1])
		pd.dam_from = POND_DAM
		pd.dam_tier = DAM_TIER
		pd.seed_v = rng.randi()
		add_world(pd, Vector2(float(p[0]), floor_y))
		_ponds.append(pd)
		var d0: float = float(p[0]) + float(p[1]) * POND_DAM
		var pf = add_floor(d0, floor_y - DAM_TIER - 4.0, float(p[0]) + float(p[1]) + 10.0 - d0, "steel", false, false)
		pf.visible = false
		reserve(Rect2(float(p[0]) - 40.0, floor_y - 40.0, float(p[1]) + 80.0, 40.0))
		main._spawn_avoid.append([float(p[0]), float(p[0]) + float(p[1]) * POND_DAM])
	_pickup(PickupScript.HEALTH, Vector2(float(PONDS[1][0]) + float(PONDS[1][1]) * 0.8, floor_y - DAM_TIER - 34.0))
	# מגדל התצפית
	var tw := Decor.LookoutTower.new()
	tw.w = TOWER_W
	tw.tier = TOWER_TIER
	add_world(tw, Vector2(TOWER_X, floor_y))
	_deck(TOWER_X - 10.0, TOWER_X + TOWER_W + 10.0, TOWER_TIER + 8.0, [TOWER_X + 30.0])
	_pickup(PickupScript.GRENADE, Vector2(TOWER_X + TOWER_W * 0.62, floor_y - TOWER_TIER - 40.0))
	_pickup(PickupScript.AMMO, Vector2(TOWER_X + TOWER_W * 0.3, floor_y - TOWER_TIER - 40.0))
	reserve(Rect2(TOWER_X - 30.0, floor_y - 40.0, TOWER_W + 60.0, 40.0))
	# קטע הסיפור: נקי לגמרי
	reserve(Rect2(STORY_X.x - 30.0, floor_y - 60.0, STORY_X.y - STORY_X.x + 60.0, 60.0))
	# הטנדר השרוף: הארגז = קומה נמוכה
	var tr := Decor.BurntTruck.new()
	tr.w = TRUCK_W
	tr.tier = TRUCK_TIER
	add_world(tr, Vector2(TRUCK_X, floor_y))
	var pf2 = add_floor(TRUCK_X + 4.0, floor_y - TRUCK_TIER - 4.0, TRUCK_W * 0.56, "steel", false, false)
	pf2.visible = false
	_pickup(PickupScript.AMMO, Vector2(TRUCK_X + TRUCK_W * 0.3, floor_y - TRUCK_TIER - 34.0))
	reserve(Rect2(TRUCK_X - 20.0, floor_y - 40.0, TRUCK_W + 40.0, 40.0))
	# מקומות הזומבים המוצבים
	for cx in CHARREDS + BUILDERS:
		reserve(Rect2(float(cx) - 40.0, floor_y - 40.0, 80.0, 40.0))
	# הזירה: המנסרה הבוערת + במת הבולים
	var saw := Decor.Sawmill.new()
	saw.w = level_w - SAW_X
	saw.deck_x = SAW_DECK.x
	saw.deck_w = SAW_DECK.y
	saw.deck_tier = SAW_TIER
	add_world(saw, Vector2(SAW_X, floor_y))
	_deck(SAW_X + SAW_DECK.x - 8.0, SAW_X + SAW_DECK.x + SAW_DECK.y + 8.0, SAW_TIER + 6.0, [SAW_X + SAW_DECK.x + 6.0])
	_pickup(PickupScript.AMMO, Vector2(SAW_X + SAW_DECK.x + SAW_DECK.y * 0.6, floor_y - SAW_TIER - 36.0))
	reserve(Rect2(SAW_X, floor_y - 40.0, level_w - SAW_X, 40.0))
	_pickup(PickupScript.HEALTH, Vector2(SAW_X - 110.0, floor_y - 30.0))


# קומה בלתי נראית (הציור בא מהבניין) + סולמות
func _deck(x0: float, x1: float, tier: float, ladders: Array) -> void:
	var pf = add_floor(x0, floor_y - tier, x1 - x0, "steel", false, false)
	pf.visible = false
	for lx in ladders:
		add_ladder(float(lx), floor_y - tier)
		reserve(Rect2(float(lx) - 30.0, floor_y - 40.0, 84.0, 40.0))


func _pickup(kind: int, pos: Vector2) -> void:
	var p = PickupScript.new()
	p.kind = kind
	p.life = 100000.0
	main.add_child(p)
	p.setup(pos, Vector2.ZERO)


func build_effects() -> void:
	var ash := Ambient.screen_particles("ash", vp)   # אפר נופל
	ash.amount = int(46.0 * clampf(Quality.ambient(), 0.3, 1.0))
	screen_layer.add_child(ash)
	_fx = Decor.SmokeFX.new()
	_fx.vp = vp
	screen_layer.add_child(_fx)


# CHARRED (אחד בתוך כל קו אש ראשון/אחרון), DAMBUILDER ליד הבריכות, ASHMOTH ישנים על הגגות, שניים שומרים בזירה
func extra_spawns() -> void:
	for cx in CHARREDS:
		spawn(Registry.CHARRED, float(cx))
	for bx in BUILDERS:
		spawn(Registry.DAMBUILDER, float(bx))
	for r in ROOSTS:
		match r:
			"hut":
				spawn(Registry.ASHMOTH, HUT_X + HUT_W * 0.25, floor_y - HUT_TIER - 8.0)
			"tower":
				spawn(Registry.ASHMOTH, TOWER_X + TOWER_W * 0.5, floor_y - TOWER_TIER - 8.0)
			"truck":
				spawn(Registry.ASHMOTH, TRUCK_X + TRUCK_W * 0.2, floor_y - TRUCK_TIER - 4.0)
	spawn(0, SAW_X + 120.0)
	spawn(1, SAW_X + 300.0)


# ============================================================
#  העשן + ההבזק
# ============================================================
func smoke_k() -> float:
	return _sk


func thick() -> bool:
	return _sk > 0.6


# ההבזק האחרון (עולם) וכמה זמן עבר (שניות)
func last_flash() -> Vector2:
	return _flash_w


func flash_age() -> float:
	return float(Time.get_ticks_msec() - _flash_ms) / 1000.0


func in_water_at(p: Vector2) -> bool:
	if absf(p.y - floor_y) > 12.0:
		return false
	for pd in _ponds:
		var x0: float = pd.global_position.x
		if p.x > x0 + 4.0 and p.x < x0 + float(pd.w) * POND_DAM - 6.0:
			return true
	return false


func _physics_process(delta: float) -> void:
	if main == null:
		return
	_smoke_tick(delta)
	var pl := get_tree().get_first_node_in_group("player") as Node2D
	if pl == null or pl.dead:
		return
	_flash_tick(pl)
	Decor.U.pocket = get_viewport().get_canvas_transform() * (pl.global_position + Vector2(0, -36))
	if Engine.get_physics_frames() % 4 == 0:
		pl.in_water = in_water_at(pl.global_position)
	if Engine.get_physics_frames() % 10 == 0:
		_waves(pl)
		_hints(pl)


func _smoke_tick(delta: float) -> void:
	_spt -= delta
	match _sph:
		0:
			_sk = move_toward(_sk, 0.0, delta * 0.6)
			if _spt <= 0.0:
				_roll_in()
		1:
			_sk = move_toward(_sk, 1.0, delta / ROLL_T)
			if _spt <= 0.0:
				_sph = 2
				_spt = THICK_T
		2:
			_sk = move_toward(_sk, 1.0, delta)
			if _spt <= 0.0:
				_sph = 3
				_spt = THIN_T
		3:
			_sk = move_toward(_sk, 0.0, delta / THIN_T)
			if _spt <= 0.0:
				_sph = 0
				_spt = randf_range(CLEAR_T.x, CLEAR_T.y)
	Decor.U.smoke = _sk


func _roll_in() -> void:
	_sph = 1
	_spt = ROLL_T
	smokes += 1
	Sfx.play("s59_whoosh", null, -1.0, 0.05, 1)
	var pl := get_tree().get_first_node_in_group("player")
	if smokes == 1 and pl != null and pl.has_method("_say"):
		pl._say("Smoke... I can't see them. Can they see me?", Color("f0c890"))


# עשן עכשיו (סצנת סיפור / בדיקות)
func force_smoke() -> void:
	if _sph == 2:
		_spt = maxf(_spt, THICK_T)
		return
	_roll_in()
	_spt = 0.6


func clear_smoke() -> void:
	_sph = 3
	_spt = THIN_T * 0.6


func _flash_tick(pl: Node2D) -> void:
	if Game.shot_id == _last_shot:
		return
	_last_shot = Game.shot_id
	if float(pl._muzzle_flash) <= 0.0:   # חץ / בקבוק / להביור: בלי הבזק
		return
	flashes += 1
	if _sk > 0.6:
		thick_shots += 1
	var a: Vector2 = pl._aim.normalized() if pl._aim != Vector2.ZERO else Vector2.RIGHT
	_flash_w = pl.global_position + Vector2(0, -36) + a * 38.0
	_flash_ms = Time.get_ticks_msec()
	Decor.U.flash = 1.0
	Decor.U.flash_pos = get_viewport().get_canvas_transform() * _flash_w


# ============================================================
#  גלי עשים (בזוגות בעשן / אחרי שלמדו)
# ============================================================
func _waves(pl: Node2D) -> void:
	var px: float = pl.global_position.x
	for i in MOTH_WAVES.size():
		if _waves_done.has(i) or px < float(MOTH_WAVES[i]):
			continue
		_waves_done[i] = true
		var n := 2 if (AshmothT.is_learned(main) or _sk > 0.4) else 1
		for k in n:
			var side := 1.0 if (i + k) % 2 == 0 else -1.0
			var sx: float = px + side * (640.0 + float(k) * 110.0)
			if sx > STORY_X.x - 100.0 and sx < STORY_X.y + 100.0 and px < STORY_X.x:
				sx = STORY_X.x - 140.0 - float(k) * 60.0
			sx = clampf(sx, 80.0, level_w - 200.0)
			var z = spawn(Registry.ASHMOTH, sx, floor_y - 280.0 - float(k) * 40.0)
			if z != null:
				z.set_meta("am_fly", true)
		if n == 2 and not main.has_meta("am_pair_said"):
			main.set_meta("am_pair_said", true)
			pl._say("More wings in the smoke...", Color("f0c890"))


# רמזים + שורת הפתיחה: פעם אחת לכל סוג, כשהוא על המסך
func _hints(pl: Node2D) -> void:
	if _seen.size() >= 3:
		return
	for z in get_tree().get_nodes_in_group("zombies"):
		if z.dead or z.type_mod == null or z.is_boss():
			continue
		var k: int = z.kind
		if _seen.has(k) or not (k == Registry.CHARRED or k == Registry.ASHMOTH or k == Registry.DAMBUILDER):
			continue
		if absf(z.global_position.x - pl.global_position.x) > 560.0 or not Art.on_screen(z, z.global_position, -40.0):
			continue
		_seen[k] = true
		if k == Registry.CHARRED:
			z._popup("FIRE DOESN'T WORK NOW", Color("ff9a4a"), 15, -100.0)
			pl._say("They're burnt black... fire won't hurt them anymore. Crack the crust.", Color("f0c890"))
		elif k == Registry.ASHMOTH:
			z._popup("THEY FOLLOW YOUR GUNFIRE NOW", Color("ff9a4a"), 15, -60.0)
			pl._say("It came to the flash... stop shooting and it loses me.", Color("f0c890"))
		else:
			z._popup("THEY BUILD COVER NOW", Color("ff9a4a"), 15, -100.0)
			pl._say("It's building a wall... it learned cover from me.", Color("f0c890"))
		return


# ============================================================
#  קטע סיפור
# ============================================================
# x של הקטע הנקי: STORY_X (4500..6400). ה-STRANGER עומד ב-5450.
func story_stretch() -> Vector2:
	return STORY_X


# אירועים: "smoke_in" (העשן מתגלגל פנימה), "smoke_out" (מתפזר), "embers" (משב ניצוצות),
# "smoke_veil" (ענן עשן סמיך על ה-STRANGER - הוא נעלם בתוכו)
func on_story_beat(id: String) -> void:
	match id:
		"smoke_in":
			force_smoke()
		"smoke_out":
			clear_smoke()
		"embers":
			Decor.U.sparks_ms = 0
		"smoke_veil":
			var ax := 5450.0
			var sc := get_tree().get_first_node_in_group("story_scene")
			if sc != null and sc.get("actor") != null and is_instance_valid(sc.actor):
				ax = sc.actor.global_position.x
			var v := Decor.SmokeVeil.new()
			v.life = 5.5
			v.r = 170.0
			add_world(v, Vector2(ax, floor_y))
			Sfx.play("s59_whoosh", Vector2(ax, floor_y - 40.0), 0.0, 0.05, 1)
