extends "res://levels/stage_base.gd"
# ============================================================
#  STAGE 60 - "GLACIER LAB" (אזור שביעי - פטגוניה, שלב 6) - "THEY LEARNED WHERE THEY CAME FROM"
#  (הסיפור: כאן נבנה ECHO - פרויקט צבאי שנועד לתת לחיילים לחלוק זיכרון קרב. הכוורת למדה מאיפה היא באה ושומרת על
#   העריסה שלה. היא למדה את המערכות של המעבדה (דלתות הדף, LOCKDOWN), ומהתיקים - את דפוס הקרב של הגיבור עצמו.
#   במסוף הארכיון הגיבור מוצא את התיק שלו: SUBJECT ZERO. והכוורת עונה ברמקולים: "Welcome home.")
#  (effects/s60_decor.gd): עומק הקרחון, קיר מערת קרח, הקיר האחורי של המעבדה עם חלונות, צינורות ותעלות בתקרה.
#  המבנה: כניסה מהקרחון -> 3 אגפים שננעלים (WINGS: A קריוגניקה, B מעבדת דגימות, D אולם שרתים) ביניהם דלתות הדף
#    (DOORS), ארכיון התיקים (סצנת הסיפור) בין B ל-D, מסדרון ה-ROOT (פטרייה עבה), וחדר הכליאה של SUBJECT FOUR (הבוס).
#  LOCKDOWN: WARDEN (enemies/types/warden.gd) מגיע ללוח האזעקה -> שתי הדלתות של האגף נטרקות (גם זו שמאחוריך), המיכלים
#    באגף מפשירים. הורגים את ה-WARDEN -> כרטיס מפתח (Keycard) -> עוברים עליו -> "ACCESS GRANTED", האגף נפתח.
#    כרטיס עודף נשמר (U.cards) ופותח את הנעילה הבאה מיד כשנוגעים בדלת. אגף נעול בלי WARDEN ובלי כרטיס -> שחרור חירום.
#  קומה שנייה: גשרי הליכה (CATWALKS) עם סולמות ואספקה למעלה.
#  מלכודות: CoolantVent (COOLANT) - עמוד חנקן נוזלי (מקפיא זומבים, מאט אותך; יורים בשסתום). דלתות ההדף מועכות זומבים.
#  זומבים: SPECIMEN (במיכלי הקפאה - TANKS, מפשירים כשעוברים), BLOOM (מושבת ECHO מרחפת שמלמדת, BLOOMS),
#          WARDEN (WARDENS: [x, אגף]), רגילים, רצים. בוס: SUBJECT FOUR (enemies/types/specimen.gd, מצב בוס).
#  "הם לומדים" (חוק הסיפור 3): הנבגים בהריגה (effects/spore_lesson.gd), ו-BLOOM מראה את זה בגלוי (טבעות "למד").
#  קטע סיפור (STORY): הארכיון, נקי. המסוף ב-TERMINAL_X, ה-SPECIMEN של הסצנה עומד במיכל ב-STORY_ACTOR.
#    on_story_beat(): "file_open" (התיק על המסך), "welcome" (הפטרייה בולעת את המסך, האורות מהבהבים, המיכל נסדק),
#    "alarm" (אזעקה קצרה). אחרי הסצנה: המיכל מתנפץ ושני מיכלים בארכיון מפשירים ("הכוורת ענתה").
#  לשנות: DOORS, WINGS, TANKS, CATWALKS, COOLANT, JARS, RACKS, FUNGUS, BLOOMS, WARDENS, ARENA_COVER, STORY, TERMINAL_X,
#         STORY_ACTOR, RELEASE_T, RELEASE_MAX, zombie_weights().
# ============================================================

const Decor := preload("res://effects/s60_decor.gd")
const PickupScript := preload("res://pickup.gd")
const Sfx := preload("res://sfx.gd")
const ZScript := preload("res://zombie.gd")

const SOUNDS := {
	"s60_door": {"rev": 0.3, "layers": [["N", 0, 0, 0.0, 0.6, 0.05, 2.0, 0.6, 0.15, 0], ["S", 90, 60, 0.0, 0.6, 0.05, 2.0, 0.5, 1.0, 0.02], ["W", 55, 40, 0.0, 0.55, 0.02, 1.5, 0.25, 0.3, 0]]},
	"s60_slam": {"rev": 0.4, "drive": 2.6, "layers": [["N", 0, 0, 0.0, 0.02, 0.0, 300.0, 1.4, 1.0, 0], ["S", 70, 30, 0.0, 0.7, 0.0, 4.0, 1.2, 1.0, 0], ["N", 0, 0, 0.0, 0.8, 0.0, 3.0, 0.6, 0.1, 0], ["S", 420, 410, 0.0, 0.6, 0.0, 6.0, 0.2, 1.0, 0]]},
	"s60_door_open": {"rev": 0.3, "layers": [["N", 0, 0, 0.0, 0.9, 0.1, 1.5, 0.4, 0.5, 0, 0.3], ["S", 60, 95, 0.0, 1.0, 0.1, 1.2, 0.4, 1.0, 0.02]]},
	"s60_alarm": [["Q", 880, 880, 0.0, 0.32, 0.01, 0.0, 0.16, 0.35, 0], ["Q", 660, 660, 0.36, 0.32, 0.01, 0.0, 0.16, 0.35, 0]],
	"s60_hiss": [["N", 0, 0, 0.0, 0.9, 0.05, 1.5, 0.5, 1.0, 0, 0.6]],
	"s60_vent": {"rev": 0.2, "layers": [["N", 0, 0, 0.0, 1.2, 0.02, 1.2, 0.9, 0.8, 0, 0.3], ["N", 0, 0, 0.0, 0.3, 0.0, 8.0, 0.6, 0.2, 0]]},
	"s60_shatter": [["N", 0, 0, 0.0, 0.25, 0.0, 12.0, 0.6, 1.0, 0, 0.5], ["S", 5200, 5100, 0.0, 0.3, 0.0, 10.0, 0.15, 1.0, 0], ["S", 3700, 3650, 0.05, 0.25, 0.0, 12.0, 0.12, 1.0, 0]],
	"s60_card": [["S", 1320, 1320, 0.0, 0.08, 0.0, 20.0, 0.35, 1.0, 0], ["S", 1760, 1760, 0.1, 0.12, 0.0, 15.0, 0.35, 1.0, 0]],
	"s60_granted": [["S", 880, 880, 0.0, 0.12, 0.0, 10.0, 0.3, 1.0, 0], ["S", 1320, 1320, 0.13, 0.12, 0.0, 10.0, 0.3, 1.0, 0], ["S", 1760, 1760, 0.26, 0.25, 0.0, 6.0, 0.3, 1.0, 0]],
	"s60_beep": [["S", 1500, 1500, 0.0, 0.06, 0.0, 30.0, 0.25, 1.0, 0], ["S", 1500, 1500, 0.1, 0.06, 0.0, 30.0, 0.25, 1.0, 0]],
	"s60_drone": {"rev": 0.5, "drive": 1.6, "layers": [["V", 90, 85, 0.0, 2.5, 0.5, 0.8, 0.5, 1.0, 0.03, 0, [400, 800, 5]], ["V", 135, 128, 0.05, 2.4, 0.5, 0.8, 0.4, 1.0, 0.03, 0, [500, 1100, 4]], ["N", 0, 0, 0.0, 2.5, 0.6, 0.8, 0.25, 0.2, 0]]},
	"s60_powerdown": [["W", 220, 40, 0.0, 1.0, 0.0, 1.5, 0.35, 0.4, 0], ["N", 0, 0, 0.0, 0.3, 0.0, 8.0, 0.4, 0.3, 0]],
}

const DOORS := [1500.0, 3200.0, 4900.0, 6800.0, 8500.0, 9150.0]   # דלתות ההדף (x מרכז)
const DOOR_LABELS := ["A", "B", "C", "D", "E", "F"]
const WINGS := [[0, 1, "A"], [1, 2, "B"], [3, 4, "D"]]            # [דלת שמאל, דלת ימין, שם]: אגפים שננעלים
const ARENA_DOOR := 5
const TANKS := [[1720.0, 0], [1840.0, 0], [1960.0, 2], [2080.0, 0], [2700.0, 0], [2820.0, 1], [2940.0, 0],
	[3650.0, 0], [3770.0, 0], [3890.0, 2], [4560.0, 0], [4680.0, 0],
	[5300.0, 2], [6300.0, 0], [6420.0, 0],
	[7080.0, 0], [7200.0, 0], [7320.0, 2], [8150.0, 0], [8270.0, 0],
	[8700.0, 2], [9330.0, 0], [9450.0, 0]]                          # [x, 0 = SPECIMEN בפנים / 1 = ריק / 2 = שבור]
const HOLD_TANKS := [6300.0, 6420.0, 9330.0, 9450.0]               # מפשירים רק כשהשלב מחליט (אחרי הסצנה / הבוס)
const CATWALKS := [[1760.0, 300.0, 170.0], [4060.0, 300.0, 165.0], [7380.0, 330.0, 180.0]]   # [x, רוחב, גובה]
const COOLANT := [2450.0, 3480.0, 7900.0, 8800.0]
const JARS := [3300.0, 4230.0, 5120.0]
const RACKS := [5450.0, 6560.0, 6950.0, 7600.0, 8330.0]   # זוגות ארונות שרתים (ServerRack.count = 2)
const FUNGUS := [[2300.0, 0.6, false], [3330.0, 0.7, true], [4420.0, 0.8, false], [6200.0, 0.8, true], [7520.0, 1.0, false],
	[8210.0, 1.1, true], [8600.0, 1.3, false], [8760.0, 1.4, true], [8960.0, 1.5, false], [9060.0, 1.5, true]]
const BLOOMS := [3950.0, 7450.0, 8100.0, 8880.0]
const WARDENS := [[2350.0, 0], [4100.0, 1], [7700.0, 2], [8060.0, 2], [8820.0, -1]]   # [x, אגף (-1 = בלי)]
const ARENA_COVER := [[9420.0, "bench", Vector2(120, 54)], [9850.0, "dewar", Vector2(84, 60)]]
const STORY := Vector2(5000.0, 6750.0)    # הארכיון: נקי לסצנה
const TERMINAL_X := 5790.0
const STORY_ACTOR := 6000.0
const RELEASE_T := 4.0                     # אגף נעול בלי WARDEN חי ובלי כרטיס -> שחרור חירום
const RELEASE_MAX := 75.0                  # ...ובכל מקרה אחרי זה (רשת ביטחון)
const HARDER := [1.0, 1.15, 1.3]

enum {W_OPEN, W_HALF, W_SEALED, W_CLEAR}
var doors := []
var wings := []           # {"x0", "x1", "dl", "dr", "state", "name", "t"}
var tanks := []
var fx: Node = null
var terminal: Node = null
var story_tank: Node = null
var cards := 0
var lockdowns := 0        # לבדיקות
var opened := 0
var releases := 0
var _arena := 0           # 0 = פתוח, 1 = נעול (הבוס חי), 2 = נגמר
var _boss: Node = null
var _alarm_t := 0.0
var _seen := {}
var _post_story := 0      # 1 = "welcome" נאמר, מחכים לסוף הסצנה
var _said := {}


func zombie_weights() -> Dictionary:
	return {Registry.SPECIMEN: 0.035, Registry.BLOOM: 0.015, Registry.WARDEN: 0.01, 0: 0.58, 1: 0.33}


func zombie_density() -> float:
	return 1.0 * float(HARDER[clampi(Settings.difficulty, 0, 2)])


func generators() -> Array:
	return [["bench", 1.0], ["dewar", 0.8], ["gurney", 0.7], ["rack", 0.5]]


func custom_gen(gname: String, x: float) -> float:
	if not gname in ["bench", "dewar", "gurney", "rack"]:
		return 0.0
	var sz := Vector2(110.0, 54.0)
	match gname:
		"bench":
			sz = Vector2(rng.randf_range(110.0, 130.0), rng.randf_range(50.0, 56.0))
		"dewar":
			sz = Vector2(rng.randf_range(76.0, 88.0), rng.randf_range(56.0, 64.0))
		"gurney":
			sz = Vector2(rng.randf_range(100.0, 116.0), rng.randf_range(44.0, 50.0))
		_:
			sz = Vector2(rng.randf_range(120.0, 140.0), rng.randf_range(42.0, 48.0))
	if not free_x(x, 30.0) or not free_x(x + sz.x, 30.0):   # לא על מיכל / דלת / מלכודת / סולם / הארכיון / הזירה
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
	return Registry.SPECIMEN


func music() -> String:
	return "res://music/level2_suspense.mp3"


func world_tint() -> Color:
	return Color(0.94, 0.98, 1.0)


func fog() -> bool:
	return false


func pits() -> int:
	return 0


func build_background(layer: CanvasLayer) -> Node:
	Decor.U.alarm = 0.0   # (סטטי - נשאר מריצה קודמת)
	Decor.U.file_ms = -1
	Decor.U.welcome_ms = -1
	Decor.U.cards = 0
	var bg = Backdrop.new()
	bg.level_w = level_w
	bg.sky = func(ci: CanvasItem, v: Vector2, t: float):
		Decor.lab_sky(ci, v, t)
	bg.add_layer(0.06, func(ci: CanvasItem, sc: float, v: Vector2, t: float):
		Decor.far_ice(ci, sc, v, 556.0, t))
	bg.add_layer(0.28, func(ci: CanvasItem, sc: float, v: Vector2, t: float):
		Decor.mid_lab(ci, sc, v, 612.0, t))
	bg.add_layer(0.6, func(ci: CanvasItem, sc: float, v: Vector2, t: float):
		Decor.near_rig(ci, sc, v, 636.0, t))
	bg.overlay = func(ci: CanvasItem, v: Vector2, t: float):
		Decor.lab_overlay(ci, v, t)
	layer.add_child(bg)
	return bg


func build_world() -> void:
	var x := 0.0
	while x < level_w:
		var g := Decor.LabGround.new()
		g.w = minf(1024.0, level_w - x)
		g.depth = main.floor_thickness
		g.seed_v = rng.randi()
		g.snow = 1.0 if x < 1000.0 else (0.3 if x < 2000.0 else 0.0)
		g.wx = x
		add_world(g, Vector2(x, floor_y))
		x += 1024.0
	add_world(Decor.Entrance.new(), Vector2(0.0, floor_y))
	# הארכיון: נקי לגמרי (קודם, כדי שאף דבר לא ייכנס אליו)
	reserve(Rect2(STORY.x - 30.0, floor_y - 60.0, STORY.y - STORY.x + 60.0, 60.0))
	# דלתות ההדף
	for i in DOORS.size():
		var d := Decor.BlastDoor.new()
		d.label = DOOR_LABELS[i]
		d.inside = -1.0 if i in [2, 4] else 1.0
		d.inside_l = i in [1, 3]
		add_world(d, Vector2(float(DOORS[i]), floor_y))
		doors.append(d)
		reserve(Rect2(float(DOORS[i]) - 90.0, floor_y - 60.0, 180.0, 60.0))
	for w in WINGS:
		wings.append({"x0": float(DOORS[int(w[0])]), "x1": float(DOORS[int(w[1])]), "dl": doors[int(w[0])], "dr": doors[int(w[1])],
			"state": W_OPEN, "name": String(w[2]), "t": 0.0})
	# מיכלי הקפאה
	for tk in TANKS:
		var t := Decor.CryoTank.new()
		t.variant = int(tk[1])
		t.tag = 100 + rng.randi() % 400
		add_world(t, Vector2(float(tk[0]), floor_y))
		tanks.append(t)
		reserve(Rect2(float(tk[0]) - 36.0, floor_y - 40.0, 72.0, 40.0))
	# המיכל של הסצנה + המסוף
	story_tank = Decor.CryoTank.new()
	story_tank.variant = 0
	story_tank.tag = 0
	story_tank.hold_burst = true
	add_world(story_tank, Vector2(STORY_ACTOR, floor_y))
	terminal = Decor.Terminal.new()
	add_world(terminal, Vector2(TERMINAL_X, floor_y))
	# גשרי הליכה (קומה) + סולמות + אספקה
	var loot := [PickupScript.AMMO, PickupScript.HEALTH, PickupScript.GRENADE]
	for i in CATWALKS.size():
		var c: Array = CATWALKS[i]
		var cx: float = c[0]
		var cw: float = c[1]
		var ct: float = c[2]
		var cwk := Decor.Catwalk.new()
		cwk.w = cw
		cwk.tier = ct
		add_world(cwk, Vector2(cx, floor_y))
		var pf = add_floor(cx, floor_y - ct, cw, "steel", false, false)
		pf.visible = false
		add_ladder(cx + 10.0, floor_y - ct)
		add_ladder(cx + cw - 34.0, floor_y - ct)
		reserve(Rect2(cx - 10.0, floor_y - 40.0, 60.0, 40.0))
		reserve(Rect2(cx + cw - 50.0, floor_y - 40.0, 60.0, 40.0))
		_pickup(loot[i % loot.size()], Vector2(cx + cw * 0.5, floor_y - ct - 30.0))
	# מלכודות: פתחי חנקן
	for vx in COOLANT:
		add_world(Decor.CoolantVent.new(), Vector2(float(vx), floor_y))
		reserve(Rect2(float(vx) - 80.0, floor_y - 40.0, 200.0, 40.0))
	# קישוטים: צנצנות, שרתים, פטרייה
	for jx in JARS:
		var js := Decor.JarShelf.new()
		js.seed_v = rng.randi() % 100000
		add_world(js, Vector2(float(jx), floor_y))
	for rx in RACKS:
		var sr := Decor.ServerRack.new()
		sr.count = 2
		sr.seed_v = rng.randi() % 1000
		sr.hgt = 210.0 + rng.randf_range(0.0, 40.0)
		add_world(sr, Vector2(float(rx), floor_y))
	for f in FUNGUS:
		var fp := Decor.FungusPatch.new()
		fp.size = float(f[1])
		fp.wall = bool(f[2])
		fp.seed_v = rng.randi() % 1000
		add_world(fp, Vector2(float(f[0]), floor_y - (40.0 if fp.wall else 0.0)))
	# חדר הכליאה של SUBJECT FOUR
	var ar := Decor.ContainmentArena.new()
	ar.w = level_w - float(DOORS[ARENA_DOOR]) - 30.0
	add_world(ar, Vector2(float(DOORS[ARENA_DOOR]) + 30.0, floor_y))
	reserve(Rect2(float(DOORS[ARENA_DOOR]), floor_y - 40.0, level_w - float(DOORS[ARENA_DOOR]), 40.0))
	for c in ARENA_COVER:
		var o := Decor.Obstacle.new()
		o.kind = String(c[1])
		o.size = c[2]
		o.seed_v = rng.randi()
		add_world(o, Vector2(float(c[0]), floor_y))
	_pickup(PickupScript.HEALTH, Vector2(float(DOORS[ARENA_DOOR]) - 130.0, floor_y - 30.0))
	_pickup(PickupScript.AMMO, Vector2(float(DOORS[ARENA_DOOR]) - 70.0, floor_y - 30.0))


func _pickup(kind: int, pos: Vector2) -> void:
	var p = PickupScript.new()
	p.kind = kind
	p.life = 100000.0
	main.add_child(p)
	p.setup(pos, Vector2.ZERO)


func build_effects() -> void:
	fx = Decor.LabFX.new()
	fx.vp = vp
	screen_layer.add_child(fx)


# SPECIMEN במיכלים, WARDEN באגפים, BLOOM באוויר, רגילים על גשרי ההליכה.
func extra_spawns() -> void:
	# מיכלי הארכיון מחכים לסצנה רק אם היא עוד תתנגן (לא אחרי TRY AGAIN / בלי שורה ב-story_db)
	var story_due := false
	for s in load("res://story/story_db.gd").for_level(60):
		if not Game.story_seen.has(s.id):
			story_due = true
	for t in tanks:
		if t.variant != 0:
			continue
		var z = spawn(Registry.SPECIMEN, t.global_position.x, floor_y - Decor.CryoTank.BASE_H)
		if z == null or z.type_mod == null:
			continue
		t.z = z
		var tx: float = t.global_position.x
		var held: bool = tx in HOLD_TANKS and (tx > float(DOORS[ARENA_DOOR]) or story_due)
		z.type_mod.enter_tank(t, held)
	for w in WARDENS:
		var z = spawn(Registry.WARDEN, float(w[0]))
		if z != null and z.type_mod != null:
			z.type_mod.wing = int(w[1])
	for bx in BLOOMS:
		spawn(Registry.BLOOM, float(bx))
	for c in CATWALKS:
		spawn(0, float(c[0]) + float(c[1]) * 0.6, floor_y - float(c[2]))


# ============================================================
#  LOCKDOWN: אגפים, דלתות, כרטיסי מפתח
# ============================================================
func wing_of(x: float) -> int:
	for i in wings.size():
		if x > float(wings[i].x0) and x < float(wings[i].x1):
			return i
	return -1


func wing_state(wi: int) -> int:
	return int(wings[wi].state) if wi >= 0 and wi < wings.size() else W_CLEAR


# x של לוח האזעקה ליד הדלת (בתוך האגף). side -1 = הדלת השמאלית, 1 = הימנית
func panel_x(wi: int, side: float) -> float:
	var w: Dictionary = wings[wi]
	return (w.dl as Node).panel_x(1.0) if side < 0.0 else (w.dr as Node).panel_x(-1.0)


func _player() -> Node2D:
	return get_tree().get_first_node_in_group("player") as Node2D


func _inside(wi: int, px: float, margin := 60.0) -> bool:
	return px > float(wings[wi].x0) + margin and px < float(wings[wi].x1) - margin


# WARDEN לחץ על לוח האזעקה. early (למד) = נועל עכשיו את הדלת הרחוקה ממך, והשנייה נטרקת כשאתה נכנס.
# מחזיר true אם משהו ננעל
func lockdown(wi: int, early := false) -> bool:
	if wi < 0 or wi >= wings.size():
		return false
	var w: Dictionary = wings[wi]
	if int(w.state) != W_OPEN:
		return false
	var pl := _player()
	if pl == null:
		return false
	var px: float = pl.global_position.x
	if _inside(wi, px):
		_seal_wing(wi)
		return true
	if not early:
		return false
	var far: Node = w.dr if px < (float(w.x0) + float(w.x1)) * 0.5 else w.dl
	far.inside = -1.0 if far == w.dr else 1.0
	far.seal()
	w.state = W_HALF
	w.t = 0.0
	return true


func _seal_wing(wi: int) -> void:
	var w: Dictionary = wings[wi]
	w.dl.inside = 1.0
	w.dr.inside = -1.0
	w.dl.seal()
	w.dr.seal()
	w.state = W_SEALED
	w.t = 0.0
	lockdowns += 1
	_alarm_t = 0.0
	var d := 0.25
	for t in tanks:   # המיכלים באגף מפשירים (מדורג)
		if t.frozen() and t.global_position.x > float(w.x0) and t.global_position.x < float(w.x1):
			get_tree().create_timer(d).timeout.connect(t.thaw.bind(true))
			d += 0.35
	var pl := _player()
	if pl != null:
		_text("LOCKDOWN - ALA " + String(w.name), Color("ff5a4a"), pl.global_position + Vector2(0, -150), 22)
		if not _said.has("lock"):
			_said["lock"] = true
			pl._say("LOCKDOWN - THEY SEALED ME IN. GET HIS KEYCARD!", Color("ff8a7a"))
		elif cards > 0 and not _said.has("spare"):
			_said["spare"] = true
			pl._say("I've got a spare keycard - touch the door.", Color("c8f0c8"))
	if not main.has_meta("wn_lock_said"):
		main.set_meta("wn_lock_said", true)
		var wd := _warden_of(wi)
		if wd != null:
			wd._popup("THEY LOCK THE DOORS NOW", Color("ff8a7a"), 13, -130.0)


func open_wing(wi: int, why := "ACCESS GRANTED") -> void:
	var w: Dictionary = wings[wi]
	if int(w.state) == W_CLEAR:
		return
	w.dl.unseal()
	w.dr.unseal()
	w.state = W_CLEAR
	opened += 1
	Sfx.play("s60_granted", null, 0.0, 0.0, 1)
	var pl := _player()
	if pl != null:
		_text(why, Color("8aff9a") if why == "ACCESS GRANTED" else Color("ffd060"), pl.global_position + Vector2(0, -150), 22)


func _warden_of(wi: int) -> Node:
	for z in get_tree().get_nodes_in_group("zombies"):
		if not z.dead and z.kind == Registry.WARDEN and z.type_mod != null and int(z.type_mod.wing) == wi:
			return z
	return null


# WARDEN מת: הכרטיס שלו נופל (בתוך האגף, שלא ייפול מאחורי דלת)
func drop_card(pos: Vector2, wi := -1) -> void:
	var c := Decor.Keycard.new()
	c.stage = self
	c.ground = floor_y
	var x := pos.x
	if wi < 0:
		wi = wing_of(x)
	if wi >= 0:
		x = clampf(x, float(wings[wi].x0) + 50.0, float(wings[wi].x1) - 50.0)
	main.add_child(c)
	c.global_position = Vector2(x, minf(pos.y - 30.0, floor_y - 14.0))
	c.vel = Vector2(randf_range(-60.0, 60.0), -260.0)


func collect_card(_c: Node) -> void:
	cards += 1
	main.set_meta("wn_cards", int(main.get_meta("wn_cards", 0)) + 1)   # WARDEN לומד: איבדו כרטיסים
	var pl := _player()
	if pl == null:
		return
	_text("KEYCARD", Color("c8ffc8"), pl.global_position + Vector2(0, -110), 18)
	if not _said.has("card"):
		_said["card"] = true
		pl._say("A keycard. That opens the doors.", Color("c8f0c8"))
	var wi := wing_of(pl.global_position.x)
	if wi >= 0 and int(wings[wi].state) in [W_HALF, W_SEALED]:
		cards -= 1
		open_wing(wi)
	Decor.U.cards = cards


func _text(t: String, c: Color, pos: Vector2, size := 18) -> void:
	var p = ZScript.HitText.new()
	p.text = t
	p.color = c
	p.size = size
	main.add_child(p)
	p.global_position = pos


func _physics_process(delta: float) -> void:
	if main == null:
		return
	var pl := _player()
	if pl == null or pl.dead:
		return
	var px: float = pl.global_position.x
	var locked := false
	for wi in wings.size():
		var w: Dictionary = wings[wi]
		var st: int = w.state
		if st == W_HALF or st == W_SEALED:
			w.t = float(w.t) + delta
			if st == W_HALF and _inside(wi, px, 120.0):   # (למד) נכנסת - גם הדלת מאחוריך נטרקת
				_seal_wing(wi)
				st = W_SEALED
			if st == W_SEALED:
				locked = locked or _inside(wi, px, -40.0)
			# כרטיס עודף: נוגעים בדלת הנעולה
			for dn in [w.dl, w.dr]:
				var d: Node2D = dn
				if d.is_closed() and absf(px - d.global_position.x) < 110.0 and absf(pl.global_position.y - floor_y) < 80.0:
					if cards > 0:
						d.card_glow = 1.0
						if absf(px - d.global_position.x) < 80.0:
							cards -= 1
							Decor.U.cards = cards
							open_wing(wi)
							break
			if Engine.get_physics_frames() % 30 == 0 and int(w.state) == W_SEALED:
				_check_release(wi)
	# WARDEN שרץ ללוח רחוק ממך (zombie.gd מקפיא זומבים רחוקים מ-1400) - ממשיכים אותו מכאן
	for wd in get_tree().get_nodes_in_group("s60_wardens"):
		if not wd.dead and wd.type_mod != null and wd.type_mod.running() and absf(wd.global_position.x - px) > 1380.0:
			wd.type_mod.remote(delta)
	# הזירה של SUBJECT FOUR
	if Engine.get_physics_frames() % 15 == 0:
		_arena_tick(pl)
		_hints(pl)
		if _post_story == 1 and get_tree().get_first_node_in_group("story_scene") == null:
			_after_story(pl)
	locked = locked or _arena == 1
	# אזעקה: אורות אדומים + צופר
	Decor.U.alarm = move_toward(Decor.U.alarm, 1.0 if locked else 0.0, delta * (2.0 if locked else 0.6))
	if locked:
		_alarm_t -= delta
		if _alarm_t <= 0.0:
			_alarm_t = 1.4
			Sfx.play("s60_alarm", null, -10.0, 0.0, 1)


# אגף נעול בלי WARDEN חי, בלי כרטיס על הרצפה ובלי כרטיס אצלך -> שחרור חירום (לא נתקעים)
func _check_release(wi: int) -> void:
	var w: Dictionary = wings[wi]
	if float(w.t) > RELEASE_MAX:
		releases += 1
		open_wing(wi, "EMERGENCY RELEASE")
		return
	if float(w.t) < RELEASE_T or cards > 0 or _warden_of(wi) != null:
		return
	for c in get_tree().get_nodes_in_group("s60_cards"):
		if c.global_position.x > float(w.x0) and c.global_position.x < float(w.x1):
			return
	releases += 1
	open_wing(wi, "EMERGENCY RELEASE")


func _arena_tick(pl: Node2D) -> void:
	if _arena == 2:
		return
	if _boss == null or not is_instance_valid(_boss):
		_boss = null
		for z in get_tree().get_nodes_in_group("zombies"):
			if z.is_boss():
				_boss = z
				break
	var door: Node = doors[ARENA_DOOR]
	if _arena == 0:
		if _boss != null and not _boss.dead and pl.global_position.x > float(DOORS[ARENA_DOOR]) + 180.0:
			_arena = 1
			door.inside = 1.0
			door.seal()
			_text("CONTAINMENT 4 - SEALED", Color("ff5a4a"), pl.global_position + Vector2(0, -150), 22)
	elif _arena == 1 and (_boss == null or _boss.dead):
		_arena = 2
		door.unseal()


# SUBJECT FOUR (שלב שני) קורא לדגימות במיכלים של הזירה
func thaw_arena() -> int:
	var n := 0
	for t in tanks:
		if t.frozen() and t.global_position.x > float(DOORS[ARENA_DOOR]):
			t.z.type_mod.hold = false
			t.thaw(true)
			n += 1
	return n


# רמזים: פעם אחת לכל סוג, כשהוא על המסך
func _hints(pl: Node2D) -> void:
	if _seen.size() >= 3:
		return
	for z in get_tree().get_nodes_in_group("zombies"):
		if z.dead or z.type_mod == null or z.is_boss():
			continue
		var k: int = z.kind
		if _seen.has(k) or not (k == Registry.SPECIMEN or k == Registry.BLOOM or k == Registry.WARDEN):
			continue
		if absf(z.global_position.x - pl.global_position.x) > 560.0 or not Art.on_screen(z, z.global_position, -40.0):
			continue
		if k == Registry.SPECIMEN and z.type_mod.in_tank():
			continue
		_seen[k] = true
		if k == Registry.SPECIMEN:
			pl._say("Test subjects... they kept them in those tanks.", Color("bfe8ff"))
		elif k == Registry.BLOOM:
			pl._say("That thing is TEACHING them. Kill it first - shoot the lights!", Color("c8ffb0"))
		else:
			pl._say("Security. Drop him before he hits the alarm.", Color("ffd080"))
		return


# ============================================================
#  קטע סיפור
# ============================================================
# x של הקטע הנקי: STORY (5000..6750) - ארכיון התיקים. המסוף ב-TERMINAL_X, ה-SPECIMEN של הסצנה במיכל ב-STORY_ACTOR.
func story_stretch() -> Vector2:
	return STORY


# "file_open" - התיק של SUBJECT ZERO על המסך, "welcome" - הפטרייה בולעת את המסך, החשמל מהבהב, המיכל נסדק והדגימה
# פוקחת עיניים, "alarm" - צופר קצר
func on_story_beat(id: String) -> void:
	match id:
		"file_open":
			Decor.U.file_ms = Time.get_ticks_msec()
			Sfx.play("s60_beep", null, 0.0, 0.0, 1)
		"welcome":
			Decor.U.welcome_ms = Time.get_ticks_msec()
			Sfx.play("s60_drone", null, 0.0, 0.0, 1)
			Sfx.play("s60_powerdown", null, -2.0, 0.0, 1)
			if story_tank != null:
				story_tank.thaw()
			for s in get_tree().get_nodes_in_group("s60_specimens"):
				if not s.is_in_group("zombies") and s.type_mod != null:
					s.type_mod.wake_actor()
			_post_story = 1
		"alarm":
			Sfx.play("s60_alarm", null, -4.0, 0.0, 1)


# אחרי הסצנה: המיכל מתנפץ (הדגימה נעלמה בחושך), שני מיכלים בארכיון מפשירים - הכוורת ענתה
func _after_story(pl: Node2D) -> void:
	_post_story = 2
	if story_tank != null:
		story_tank.hold_burst = false
		story_tank.burst()
	var d := 0.6
	for t in tanks:
		if t.frozen() and t.global_position.x > STORY.x and t.global_position.x < STORY.y:
			t.z.type_mod.hold = false
			get_tree().create_timer(d).timeout.connect(t.thaw.bind(true))
			d += 0.5
	Sfx.play("s60_alarm", null, -6.0, 0.0, 1)
	pl._say("Home. That's what they call this place.", Color("bfe8ff"))
