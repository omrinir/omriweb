extends "res://levels/stage_base.gd"
# ============================================================
#  STAGE 55 - "WIND STEPPE" (אזור שביעי - פטגוניה, שלב 1) - "THEY LEARNED THE WIND"
#  (הסיפור: THE ARCHITECT מת בגשר (54) - וזה לא שינה כלום. אין יותר מנהיג: הכוורת חושבת כאחד. הגיבור בערבה הפטגונית
#   הריקה, תחת שמיים ענקיים, ברוח שלא נגמרת. המתים למדו שהגיבור לא מסתכל למעלה, ושהרוח יכולה לשאת אותם -
#   עכשיו הם באים מהשמיים ומתגלגלים על הקרקע. כאן ה-STRANGER מספר לו את האמת על הנבגים: "כל אחד שאתה הורג... מלמד את השאר".)
#  (effects/s55_decor.gd): שמיים כחולים עמוקים עם עננים עדשתיים, האנדים (פיץ רוי) עם נוצות שלג, אסטנסיה, חוות טורבינות,
#  גואנקו, גדרות, עשב קוירון שנוטה ברוח. בעולם: שער האסטנסיה, מחסן הגז"ז, מגדל מים, בקתת רועים, טורבינות, מכלאה.
#  הרוח (המכונאי של השלב): wind() (-1..1, שלילי = נושבת שמאלה, מול הגיבור). בסיס BREEZE, ובכל CALM_T שניות:
#    WARN (WARN_T: העשב והאבק נוטים חזק, וווש, שרוול הרוח + "GUST") -> GUST (GUST_T, |wind| = 1) -> LULL (LULL_T, הרוח נופלת).
#    הרוח מזיזה חלקיקים, עשב, דגלים, כבשים, DRIFTER ו-TUMBLER, ודוחפת את השחקן רק באוויר (AIR_PUSH) - אף פעם לא על הקרקע.
#    gust_k() / warn_k() לסוגי הזומבים ולמלכודות.
#  קומה שנייה: עליית הגג של מחסן הגז"ז (SHED_X), מגדל המים (TOWER_X), במת התחזוקה בטורבינה (TURBINES[1]), מכבש הצמר בזירה -
#    סולמות בכל אחד ואספקה למעלה.
#  מלכודות: SheetTrap (לוחות פח על גג המחסן, נתלשים במשב), BladeDrop (להב שבור בטורבינה הראשונה), GasBottle (GAS_X),
#    BarbedWire (WIRES), Corral (CORRAL_X: מכלאה - עדר דוהר + SHEARER חבוי).
#  קטע סיפור (STORY_X): 2000 פיקסלים נקיים (בלי מכשולים / מלכודות / זומבים של השלב). עדר קישוט (STORY_FLOCK) ל-"flock_scatter".
#  זומבים: SHEARER (מתחבא בעדרים - FLOCKS), DRIFTER (גלי מצנחים מכיוון הרוח - DRIFT_WAVES, ועל הבמות - PERCHES),
#    TUMBLER (כדורי קוצים - TUMBLERS, להקה - PACK), רגילים, רצים.
#  בוס: THE ESTANCIERO (enemies/types/shearer.gd, מצב בוס) - מול מחסן הגז"ז הגדול (ShearingYard).
#  לשנות: BREEZE, CALM_T, WARN_T, GUST_T, LULL_T, AIR_PUSH, SHED_X, TOWER_X, TURBINES, PUESTO_X, GAS_X, WIRES, CORRAL_X,
#    BALES, STORY_X, FLOCKS, PERCHES, DRIFT_WAVES, TUMBLERS, PACK, PUMPS, FENCES, zombie_weights().
# ============================================================

const Decor := preload("res://effects/s55_decor.gd")
const ShearerT := preload("res://enemies/types/shearer.gd")
const DrifterT := preload("res://enemies/types/drifter.gd")
const PickupScript := preload("res://pickup.gd")
const Sfx := preload("res://sfx.gd")

const SOUNDS := {
	"w55_whoosh": {"rev": 0.3, "layers": [["N", 0, 0, 0.0, 1.4, 0.7, 1.4, 0.45, 0.18, 0, 0.1], ["N", 0, 0, 0.2, 1.1, 0.6, 1.8, 0.25, 0.45, 0, 0.5]]},
	"w55_gust": {"rev": 0.4, "layers": [["N", 0, 0, 0.0, 3.0, 0.3, 0.7, 0.6, 0.12, 0, 0.05], ["N", 0, 0, 0.1, 2.6, 0.5, 0.9, 0.3, 0.4, 0.3, 0.4], ["S", 420, 300, 0.2, 2.2, 0.6, 1.0, 0.04, 1.0, 0.2]]},
	"w55_sheet": [["N", 0, 0, 0.0, 0.5, 0.0, 4.0, 0.6, 0.7, 0, 0.3], ["S", 820, 600, 0.0, 0.4, 0.0, 5.0, 0.2, 1.0, 0.2], ["C", 0, 0, 0.0, 0.1, 0.0, 30.0, 0.6, 1.0, 0]],
	"w55_rattle": [["C", 0, 0, 0.0, 0.05, 0.0, 50.0, 0.5, 1.0, 0], ["S", 700, 650, 0.0, 0.08, 0.0, 30.0, 0.15, 1.0, 0.3], ["C", 0, 0, 0.07, 0.05, 0.0, 50.0, 0.4, 1.0, 0], ["C", 0, 0, 0.13, 0.05, 0.0, 50.0, 0.35, 1.0, 0]],
	"w55_creak": [["S", 140, 110, 0.0, 0.9, 0.05, 2.0, 0.4, 1.0, 0.4], ["N", 0, 0, 0.0, 0.8, 0.05, 2.6, 0.25, 0.25, 0], ["S", 90, 75, 0.35, 0.6, 0.05, 3.0, 0.3, 1.0, 0.5]],
	"w55_blade": {"drive": 1.8, "layers": [["N", 0, 0, 0.0, 0.8, 0.1, 2.0, 0.5, 0.3, 0, 0.2], ["S", 300, 120, 0.0, 0.8, 0.05, 2.0, 0.25, 1.0, 0.1]]},
	"w55_crash": {"rev": 0.3, "drive": 2.4, "layers": [["N", 0, 0, 0.0, 1.0, 0.0, 2.6, 1.0, 0.08, 0], ["C", 0, 0, 0.0, 0.8, 0.0, 3.0, 0.9, 1.0, 0], ["S", 70, 34, 0.0, 0.7, 0.0, 4.0, 0.8, 1.0, 0], ["S", 900, 640, 0.0, 0.5, 0.0, 6.0, 0.18, 1.0, 0.06]]},
	"w55_hiss": [["N", 0, 0, 0.0, 1.2, 0.05, 1.2, 0.35, 0.95, 0, 0.7]],
	"w55_beep": [["Q", 1240, 1240, 0.0, 0.06, 0.0, 40.0, 0.14, 1.0, 0]],
	"w55_wire": [["S", 2200, 1700, 0.0, 0.25, 0.0, 9.0, 0.2, 1.0, 0.1], ["N", 0, 0, 0.0, 0.2, 0.0, 12.0, 0.4, 0.7, 0, 0.4], ["C", 0, 0, 0.0, 0.05, 0.0, 50.0, 0.4, 1.0, 0]],
	"w55_gate": {"drive": 2.0, "layers": [["C", 0, 0, 0.0, 0.3, 0.0, 9.0, 0.9, 1.0, 0], ["N", 0, 0, 0.0, 0.35, 0.0, 8.0, 0.6, 0.3, 0], ["S", 160, 90, 0.0, 0.4, 0.0, 6.0, 0.4, 1.0, 0.2]]},
	"w55_stampede": {"rev": 0.2, "layers": [["N", 0, 0, 0.0, 2.6, 0.2, 1.0, 0.55, 0.1, 0.6, 0], ["C", 0, 0, 0.0, 2.6, 0.1, 1.0, 0.5, 0.5, 0], ["V", 320, 280, 0.3, 0.5, 0.03, 2.4, 0.3, 1.0, 0.3, 0, [760, 1500, 4]], ["V", 360, 300, 0.9, 0.5, 0.03, 2.4, 0.25, 1.0, 0.3, 0, [760, 1500, 4]]]},
	"w55_baa": [["V", 340, 300, 0.0, 0.5, 0.03, 2.6, 0.45, 1.0, 0.3, 0, [760, 1500, 4]], ["V", 300, 270, 0.4, 0.45, 0.03, 2.6, 0.35, 1.0, 0.3, 0, [740, 1450, 4]]],
}

# ---- הרוח ----
const BREEZE := 0.42                     # רוח בסיס (תמיד שמאלה)
const CALM_T := Vector2(6.5, 10.0)       # כמה זמן בין משבים
const WARN_T := 1.3
const GUST_T := 3.0
const LULL_T := 2.2
const AIR_PUSH := 75.0                   # פיקסלים לשנייה ברוח מלאה (רק באוויר)
# ---- מבנה ----
const ARCH_X := 360.0
const SHED_X := 1100.0                   # מחסן הגז"ז (עליית גג = קומה)
const SHED_W := 560.0
const SHED_TIER := 150.0
const TOWER_X := 2600.0                  # מגדל המים
const TOWER_W := 150.0
const TOWER_TIER := 190.0
const PUESTO_X := 3060.0
const GAS_X := 3330.0
const WIRES := [2060.0, 3470.0, 7090.0, 8440.0]
const STORY_X := Vector2(3700.0, 5700.0) # קטע ישר ונקי לסצנת סיפור (STRANGER ב-4500)
const STORY_FLOCK := Vector2(4900.0, 5250.0)
const TURBINES := [6780.0, 8130.0]       # [0] = שבורה (BladeDrop), [1] = במת תחזוקה (קומה)
const TURBINE_TIER := 170.0
const CORRAL_X := 7330.0
const YARD_X := 9140.0                   # זירת הבוס
const PRESS_X := 9330.0                  # מכבש הצמר (קומה)
const PRESS_TIER := 130.0
const BALES := [9570.0]                  # חבילות צמר בזירה (מחסה + הבוס נתקע בהן)
const PUMPS := [[760.0, 0], [2380.0, 1], [6150.0, 2], [8700.0, 3]]
const FENCES := [[1750.0, 260.0], [5900.0, 520.0], [7700.0, 380.0]]
# ---- זומבים ----
const FLOCKS := [[780.0, 1], [2330.0, 1], [6470.0, 1], [7760.0, 1], [8620.0, 2]]   # [x, כמה SHEARER בעדר]
const PERCHES := ["shed", "tower", "turbine"]
const DRIFT_WAVES := [1850.0, 2950.0, 6050.0, 7450.0, 8750.0]
const TUMBLERS := [1520.0, 2760.0, 3240.0, 7980.0, 8960.0]
const PACK := [6200.0, 6290.0, 6380.0]
const HARDER := [1.0, 1.15, 1.3]

var _w := -BREEZE                        # הרוח עכשיו
var _phase := 0                          # 0 רגוע, 1 אזהרה, 2 משב, 3 שקט
var _pt := 6.0
var _gk := 0.0
var _wk := 0.0
var _gusts := 0                          # לבדיקות
var _pushed := 0.0                       # לבדיקות: כמה פיקסלים השחקן נדחף באוויר
var _waves_done := {}
var _seen := {}
var _hud: Node = null
var _fx: Node = null
var _corral: Node = null
var _story_sheep: Array = []


func zombie_weights() -> Dictionary:
	return {Registry.SHEARER: 0.03, Registry.DRIFTER: 0.035, Registry.TUMBLER: 0.05, 0: 0.56, 1: 0.32}


func zombie_density() -> float:
	return 1.0 * float(HARDER[clampi(Settings.difficulty, 0, 2)])


func generators() -> Array:
	return [["wool", 1.0], ["posts", 0.8], ["rusty", 0.45], ["trough", 0.6]]   # (לא "crates" - השם הזה תפוס ב-main.gd)


func custom_gen(gname: String, x: float) -> float:
	if not gname in ["wool", "posts", "rusty", "trough"]:
		return 0.0
	var sz := Vector2(78.0, 50.0)
	match gname:
		"posts":
			sz = Vector2(rng.randf_range(108.0, 120.0), rng.randf_range(30.0, 36.0))
		"rusty":
			sz = Vector2(rng.randf_range(150.0, 162.0), rng.randf_range(64.0, 70.0))
		"trough":
			sz = Vector2(rng.randf_range(88.0, 100.0), rng.randf_range(34.0, 38.0))
		_:
			sz = Vector2(rng.randf_range(72.0, 82.0), rng.randf_range(46.0, 52.0))
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
	return Registry.SHEARER


func music() -> String:
	return "res://music/level1_total_war.mp3"


func world_tint() -> Color:
	return Color(1.02, 0.99, 0.95)


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
		Decor.steppe_sky(ci, v, t)
	bg.add_layer(0.06, func(ci: CanvasItem, sc: float, v: Vector2, t: float):
		Decor.far_andes(ci, sc, v, 556.0, t))
	bg.add_layer(0.28, func(ci: CanvasItem, sc: float, v: Vector2, t: float):
		Decor.mid_estancia(ci, sc, v, 612.0, t))
	bg.add_layer(0.6, func(ci: CanvasItem, sc: float, v: Vector2, t: float):
		Decor.near_steppe(ci, sc, v, 636.0, t))
	bg.overlay = func(ci: CanvasItem, v: Vector2, t: float):
		Decor.steppe_overlay(ci, v, t)
	layer.add_child(bg)
	return bg


func build_world() -> void:
	Decor.W.wind = -BREEZE
	Decor.W.drift = 0.0
	# קרקע: כביש חצץ + אדמה
	var x := 0.0
	while x < level_w:
		var g := Decor.SteppeGround.new()
		g.w = minf(1024.0, level_w - x)
		g.depth = main.floor_thickness
		g.seed_v = rng.randi()
		add_world(g, Vector2(x, floor_y))
		x += g.w
	# קישוטים מאחור: משאבות רוח, גדרות
	for p in PUMPS:
		var pm := Decor.WindPump.new()
		pm.k = int(p[1])
		pm.h = 170.0 + 30.0 * float(int(p[1]) % 2)
		add_world(pm, Vector2(float(p[0]), floor_y))
	for f in FENCES:
		var fe := Decor.WireFence.new()
		fe.w = float(f[1])
		fe.seed_v = rng.randi()
		add_world(fe, Vector2(float(f[0]), floor_y))
	# שער האסטנסיה
	add_world(Decor.EstanciaArch.new(), Vector2(ARCH_X, floor_y))
	reserve(Rect2(ARCH_X - 30.0, floor_y - 40.0, 380.0, 40.0))
	# מחסן הגז"ז: עליית גג + 2 סולמות + אספקה + לוחות פח על הגג
	var shed := Decor.WoolShed.new()
	shed.w = SHED_W
	shed.tier = SHED_TIER
	shed.seed_v = rng.randi()
	add_world(shed, Vector2(SHED_X, floor_y))
	_deck(SHED_X - 6.0, SHED_X + SHED_W + 6.0, SHED_TIER, [SHED_X + 26.0, SHED_X + SHED_W - 50.0])
	_pickup(PickupScript.AMMO, Vector2(SHED_X + SHED_W * 0.5, floor_y - SHED_TIER - 30.0))
	_pickup(PickupScript.HEALTH, Vector2(SHED_X + SHED_W * 0.78, floor_y - SHED_TIER - 30.0))
	var sheet := Decor.SheetTrap.new()
	sheet.floor_y = floor_y
	add_world(sheet, Vector2(SHED_X + 150.0, floor_y - 214.0))
	# מגדל המים
	var tw := Decor.WaterTower.new()
	tw.w = TOWER_W
	tw.tier = TOWER_TIER
	add_world(tw, Vector2(TOWER_X, floor_y))
	_deck(TOWER_X - 8.0, TOWER_X + TOWER_W + 8.0, TOWER_TIER, [TOWER_X + 18.0])
	_pickup(PickupScript.GRENADE, Vector2(TOWER_X + TOWER_W * 0.62, floor_y - TOWER_TIER - 30.0))
	# בקתת הרועים + בלון הגז
	add_world(Decor.Puesto.new(), Vector2(PUESTO_X, floor_y))
	reserve(Rect2(PUESTO_X - 10.0, floor_y - 40.0, 200.0, 40.0))
	var gas := Decor.GasBottle.new()
	gas.floor_y = floor_y
	add_world(gas, Vector2(GAS_X, floor_y))
	reserve(Rect2(GAS_X - 40.0, floor_y - 40.0, 80.0, 40.0))
	# גדרות תיל דוקרני על הכביש
	for wx in WIRES:
		add_world(Decor.BarbedWire.new(), Vector2(float(wx), floor_y))
		reserve(Rect2(float(wx) - 70.0, floor_y - 40.0, Decor.BarbedWire.W_ + 140.0, 40.0))
	# מקומות הזומבים המוצבים (שהמכשולים לא ייווצרו עליהם)
	for tx in TUMBLERS + PACK:
		reserve(Rect2(float(tx) - 40.0, floor_y - 40.0, 80.0, 40.0))
	for fl in FLOCKS:
		reserve(Rect2(float(fl[0]) - 150.0, floor_y - 40.0, 300.0, 40.0))
	# קטע הסיפור: נקי לגמרי (רק עדר קישוט בלי גוזזים)
	reserve(Rect2(STORY_X.x - 30.0, floor_y - 60.0, STORY_X.y - STORY_X.x + 60.0, 60.0))
	for i in 9:
		var s = ShearerT.Sheep.new()
		s.home_x = lerpf(STORY_FLOCK.x, STORY_FLOCK.y, float(i) / 8.0) + rng.randf_range(-20.0, 20.0)
		s.position = Vector2(s.home_x, floor_y)
		s.ground_y = floor_y
		s.roam = 60.0
		main.add_child(s)
		_story_sheep.append(s)
	# טורבינות: הראשונה שבורה (להב נופל), השנייה עם במת תחזוקה (קומה)
	for i in TURBINES.size():
		var tx: float = TURBINES[i]
		var tb := Decor.Turbine.new()
		tb.tier = TURBINE_TIER
		tb.broken = i == 0
		add_world(tb, Vector2(tx, floor_y))
		if i == 0:
			var bd := Decor.BladeDrop.new()
			bd.turbine = tb
			bd.floor_y = floor_y
			add_world(bd, Vector2(tx, floor_y))
			reserve(Rect2(tx - 240.0, floor_y - 40.0, 300.0, 40.0))
		else:
			_deck(tx - tb.plat_w * 0.5, tx + tb.plat_w * 0.5, TURBINE_TIER, [tx - tb.plat_w * 0.5 + 14.0])
			_pickup(PickupScript.HEALTH, Vector2(tx + 40.0, floor_y - TURBINE_TIER - 30.0))
			_pickup(PickupScript.AMMO, Vector2(tx - 20.0, floor_y - TURBINE_TIER - 30.0))
	# המכלאה (עדר דוהר + גוזז חבוי)
	_corral = Decor.Corral.new()
	add_world(_corral, Vector2(CORRAL_X, floor_y))
	reserve(Rect2(CORRAL_X - 20.0, floor_y - 40.0, Decor.Corral.W_ + 40.0, 40.0))
	# הזירה: מחסן הגז"ז הגדול + מכבש הצמר (קומה)
	var yard := Decor.ShearingYard.new()
	yard.w = level_w - YARD_X
	add_world(yard, Vector2(YARD_X, floor_y))
	var pr := Decor.WoolPress.new()
	pr.tier = PRESS_TIER
	add_world(pr, Vector2(PRESS_X, floor_y))
	_deck(PRESS_X - 4.0, PRESS_X + pr.w + 4.0, PRESS_TIER, [PRESS_X + 12.0])
	_pickup(PickupScript.AMMO, Vector2(PRESS_X + pr.w * 0.7, floor_y - PRESS_TIER - 30.0))
	reserve(Rect2(YARD_X, floor_y - 40.0, level_w - YARD_X, 40.0))
	_pickup(PickupScript.HEALTH, Vector2(YARD_X - 120.0, floor_y - 30.0))
	# חבילות צמר בזירה: מחסה, והבוס שמסתער לתוכן נתקע (STUCK - המנוע חשוף)
	for bx in BALES:
		var o := Decor.Obstacle.new()
		o.kind = "wool"
		o.size = Vector2(84.0, 52.0)
		o.seed_v = rng.randi()
		add_world(o, Vector2(float(bx), floor_y))


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
	_fx = Decor.WindFX.new()
	_fx.vp = vp
	screen_layer.add_child(_fx)
	_hud = Decor.WindHud.new()
	_hud.vp = vp
	screen_layer.add_child(_hud)


# עדרים עם גוזזים, מצנחים על הבמות, כדורי קוצים (בודדים + להקה), גוזז במכלאה, שניים שומרים בזירה
func extra_spawns() -> void:
	for f in FLOCKS:
		var fx: float = f[0]
		for i in 6:
			var s = ShearerT.Sheep.new()
			s.home_x = fx + rng.randf_range(-120.0, 120.0)
			s.position = Vector2(s.home_x, floor_y)
			s.ground_y = floor_y
			main.add_child(s)
		for i in int(f[1]):
			spawn(Registry.SHEARER, fx + rng.randf_range(-70.0, 70.0))
	var pc = spawn(Registry.SHEARER, CORRAL_X + 160.0)
	if pc != null:
		pc.type_mod.pen_mode(_corral)
		_corral.hidden_z.append(pc)
	for p in PERCHES:
		match p:
			"shed":
				spawn(Registry.DRIFTER, SHED_X + SHED_W - 120.0, floor_y - SHED_TIER)
			"tower":
				spawn(Registry.DRIFTER, TOWER_X + TOWER_W * 0.5, floor_y - TOWER_TIER)
			"turbine":
				spawn(Registry.DRIFTER, float(TURBINES[1]) + 50.0, floor_y - TURBINE_TIER)
	for tx in TUMBLERS:
		spawn(Registry.TUMBLER, float(tx))
	for tx in PACK:
		spawn(Registry.TUMBLER, float(tx))
	spawn(0, YARD_X + 120.0)
	spawn(1, YARD_X + 260.0)


# ============================================================
#  הרוח
# ============================================================
func wind() -> float:
	return _w


func gust_k() -> float:
	return _gk


func warn_k() -> float:
	return _wk


func _physics_process(delta: float) -> void:
	if main == null:
		return
	_wind_tick(delta)
	var pl = get_tree().get_first_node_in_group("player")
	if pl == null or pl.dead:
		return
	# דחיפה עדינה באוויר בלבד (לא על הקרקע, לא בסולם, לא כשתפוס)
	if not pl.is_on_floor() and not pl._climbing and pl.grabbed_by == null:
		var dx := _w * AIR_PUSH * delta
		var before: float = pl.global_position.x
		pl.move_and_collide(Vector2(dx, 0.0))
		_pushed += absf(pl.global_position.x - before)
	if Engine.get_physics_frames() % 10 == 0:
		_waves(pl)
		_hints(pl)


func _wind_tick(delta: float) -> void:
	_pt -= delta
	var base := -(BREEZE + 0.06 * sin(Time.get_ticks_msec() * 0.0004) + 0.04 * sin(Time.get_ticks_msec() * 0.0013))
	var target := base
	match _phase:
		0:
			if _pt <= 0.0:
				_start_warn(WARN_T)
		1:
			_wk = minf(1.0, _wk + delta / WARN_T * 1.4)
			target = base * 1.25
			if _pt <= 0.0:
				_phase = 2
				_pt = GUST_T
				_gusts += 1
				Sfx.play("w55_gust", null, 0.0, 0.05, 1)
				var pl := get_tree().get_first_node_in_group("player")
				if _gusts == 1 and pl != null and pl.has_method("_say"):
					pl._say("GUST! THE WIND CARRIES THEM", Color("f0d8a0"))
		2:
			_wk = move_toward(_wk, 0.0, delta * 3.0)
			target = -1.0
			if _pt <= 0.0:
				_phase = 3
				_pt = LULL_T
		3:
			target = -0.05
			if _pt <= 0.0:
				_phase = 0
				_pt = randf_range(CALM_T.x, CALM_T.y)
	if _phase != 1:
		_wk = move_toward(_wk, 0.0, delta * 2.0)
	var rate := 2.2 if _phase == 2 else (1.6 if _phase == 3 else 0.8)
	_w = move_toward(_w, target, rate * delta)
	_gk = move_toward(_gk, 1.0 if _phase == 2 else 0.0, delta * (2.5 if _phase == 2 else 1.2))
	Decor.W.wind = _w
	Decor.W.mag = absf(_w)
	Decor.W.gust = _gk
	Decor.W.warn = _wk
	Decor.W.lean = clampf(absf(_w) * 0.9 + _wk * 0.55, 0.0, 1.3)
	Decor.W.drift += _w * 250.0 * delta
	Decor.W.spin += (0.6 + 2.6 * absf(_w)) * delta
	Decor.W.t += delta


func _start_warn(t: float) -> void:
	_phase = 1
	_pt = t
	Sfx.play("w55_whoosh", null, -2.0, 0.05, 1)


# משב עכשיו (סצנת סיפור / בדיקות)
func force_gust() -> void:
	if _phase == 2:
		_pt = maxf(_pt, GUST_T)
		return
	_start_warn(0.35)
	_wk = 0.8


# ============================================================
#  גלי מצנחים מכיוון הרוח (בזוגות אחרי שלמדו)
# ============================================================
func _waves(pl: Node) -> void:
	var px: float = pl.global_position.x
	for i in DRIFT_WAVES.size():
		if _waves_done.has(i) or px < float(DRIFT_WAVES[i]):
			continue
		_waves_done[i] = true
		var up := -signf(_w) if absf(_w) > 0.02 else 1.0   # מכיוון הרוח
		var n := 2 if DrifterT.is_learned(main) else 1
		for k in n:
			var sx: float = px + up * (680.0 + float(k) * 130.0)
			if sx > STORY_X.x - 100.0 and sx < STORY_X.y + 100.0 and px < STORY_X.x:
				sx = STORY_X.x - 120.0 - float(k) * 60.0
			sx = clampf(sx, 80.0, level_w - 200.0)
			var z = spawn(Registry.DRIFTER, sx, floor_y - 300.0 - float(k) * 50.0)
			if z != null:
				z.set_meta("dr_fly", true)
		if n == 2 and not main.has_meta("dr_pair_said"):
			main.set_meta("dr_pair_said", true)
			pl._say("They come in pairs now...", Color("ffb070"))


# רמזים: פעם אחת לכל סוג, כשהוא על המסך
func _hints(pl: Node) -> void:
	if _seen.size() >= 3:
		return
	for z in get_tree().get_nodes_in_group("zombies"):
		if z.dead or z.type_mod == null or z.is_boss():
			continue
		var k: int = z.kind
		if _seen.has(k) or not (k == Registry.SHEARER or k == Registry.DRIFTER or k == Registry.TUMBLER):
			continue
		if absf(z.global_position.x - pl.global_position.x) > 560.0 or not Art.on_screen(z, z.global_position, -40.0):
			continue
		_seen[k] = true
		if k == Registry.SHEARER:
			pl._say("One of those sheep has boots...", Color("f0d8a0"))
		elif k == Registry.DRIFTER:
			pl._say("LOOK UP - SHOOT THE WING", Color("f0d8a0"))
		else:
			pl._say("That tumbleweed has eyes. Burn it.", Color("f0d8a0"))
		return


# ============================================================
#  קטע סיפור
# ============================================================
# x של הקטע הנקי: STORY_X (3700..5700). ה-STRANGER עומד ב-4500. העדר (STORY_FLOCK) רועה ב-4900..5250.
func story_stretch() -> Vector2:
	return STORY_X


# אירועים: "gust" (משב חזק עכשיו), "flock_scatter" (הכבשים מתפזרות + גוזזים מחופשים קמים),
# "calm" (הרוח נופלת לרגע), "stampede" (המכלאה נפרצת - לבדיקות)
func on_story_beat(id: String) -> void:
	match id:
		"gust":
			force_gust()
		"flock_scatter":
			var pl := get_tree().get_first_node_in_group("player") as Node2D
			var fx: float = pl.global_position.x if pl != null else STORY_X.x
			for s in get_tree().get_nodes_in_group("s55_sheep"):
				if absf(s.global_position.x - fx) < 1400.0:
					s.flee(fx, randf_range(2.5, 4.0))
			for z in get_tree().get_nodes_in_group("zombies"):
				if not z.dead and z.type_mod != null and z.type_mod.has_method("scare") and absf(z.global_position.x - fx) < 1400.0:
					z.type_mod.scare()
			Sfx.play("w55_baa", Vector2(fx + 400.0, floor_y - 20.0), 2.0, 0.1, 1)
		"calm":
			_phase = 3
			_pt = LULL_T
		"stampede":
			if _corral != null:
				_corral.burst()
