extends "res://levels/stage_base.gd"
# ============================================================
#  STAGE 63 - "THE HEART" (אזור שביעי - פטגוניה, שלב 9, השלב האחרון במשחק) - "THEY LEARNED YOU"
#  (הסיפור: מתחת לפרסידיו של אושואיה, בסוף הפיר שבסוף שלב 62 - הלב של ה-ROOT. כל שיעור שהכוורת למדה מהגיבור
#   - מכל אזור, מכל הריגה - הגיע לכאן. הכוורת בנתה כאן מוזיאון שלו: פסלים של הגיבור בכל תנוחה, העתקים מגודלים
#   של המקומות שעבר, ושקי רחם שבהם גדלים HOLLOW - עותקים שלו. ובסוף, ה-ROOT שואל אותו לחזור הביתה.)
#  (effects/s63_decor.gd): תקרת המערה והלב, טרסות של פסלים, קיר הזיכרון, וילונות שורשים, רצפת בשר.
#  המבנה: הכניסה (שערי הכלא) -> גלריית הזיכרון (פסלים, שקים, מדפי שורש, פיות עורקים) -> אולם המראות (HALL: שני
#    קרומים נסגרים, בוס האמצע SUBJECT ZERO = HOLLOW בוס) -> דרך העצבים (נקודת ביקורת, גלי PILGRIM, מלכודות) ->
#    חדר הלב (ARENA_X0: קרום נסגר מאחוריך, ה-ROOT = הבוס האחרון) -> הסוף (effects/s63_ending.gd: DESTROY / JOIN).
#  הלב פועם (U.beat): ככל שמתקדמים - מהר וחזק יותר. השסתומים (HeartValve) מתפרצים בקצב שלו.
#  מלכודות: HeartValve (שסתום ברצפה - מתנפח בפעימה אחת ומתפרץ בבאה), RootSnare (שורש חבוי - לופת את הרגליים).
#  זומבים: HOLLOW (enemies/types/hollow.gd: עותקים של הגיבור - כפסלים (STATUES), בשקים (PODS), ובפיזור), PILGRIM
#    (enemies/types/pilgrim.gd: נושאי שיעורים - יוצאים מפיות העורקים (MOUTHS) בגלים, ומגופות של HOLLOW), רגילים, רצים.
#    בוס אמצע: SUBJECT ZERO (HOLLOW בוס, באולם המראות). בוס: ROOT (enemies/types/root.gd).
#  "הם לומדים" (חוק הסיפור 3): השלב סופר באיזה נשק אתה יורה (shots / fav_cat) - ה-HOLLOW לומדים להשתמש בו.
#    כל PILGRIM שמגיע הביתה = שיעור (U.lessons) - ה-ROOT עמיד יותר לנשק הזה (root.gd -> RESIST).
#  היציאה: ה-ROOT שומר עליה (קיר שחוסם רק את השחקן - שכבה 512). השער לא נפתח ממוות של בוס (לא ב-level_exit) -
#    הסוף (s63_ending.gd) קורא בעצמו ל-main._level_complete().
#  לשנות: STATUES, PODS, HALL_PODS, ARENA_PODS, SHELVES, MOUTHS, VALVES, SNARES, ARENA_*, HALL, WAVE_T, MAX_PILGRIMS,
#         BEAT_T, zombie_weights().
# ============================================================

const Decor := preload("res://effects/s63_decor.gd")
const PickupScript := preload("res://pickup.gd")
const Sfx := preload("res://sfx.gd")
const ZScript := preload("res://zombie.gd")
const ZScene := preload("res://zombie.tscn")
const EndingScript := preload("res://effects/s63_ending.gd")

const SOUNDS := {
	"s63_beat": {"rev": 0.35, "drive": 1.8, "layers": [["S", 62, 38, 0.0, 0.2, 0.004, 12.0, 1.1, 1.0, 0], ["N", 0, 0, 0.0, 0.08, 0.0, 30.0, 0.4, 0.08, 0], ["S", 56, 34, 0.24, 0.24, 0.004, 10.0, 0.85, 1.0, 0], ["N", 0, 0, 0.24, 0.08, 0.0, 30.0, 0.3, 0.08, 0]]},
	"s63_squelch": [["N", 0, 0, 0.0, 0.3, 0.02, 9.0, 0.6, 0.3, 0, 0.2], ["S", 240, 90, 0.0, 0.25, 0.0, 10.0, 0.35, 1.0, 0.08]],
	"s63_burst": {"rev": 0.3, "drive": 2.2, "layers": [["N", 0, 0, 0.0, 0.45, 0.0, 7.0, 1.0, 0.35, 0, 0.3], ["S", 180, 50, 0.0, 0.4, 0.0, 8.0, 0.8, 1.0, 0.05], ["N", 0, 0, 0.1, 0.5, 0.05, 5.0, 0.4, 0.15, 0, 0.6]]},
	"s63_membrane": {"rev": 0.4, "layers": [["N", 0, 0, 0.0, 0.8, 0.1, 2.5, 0.6, 0.2, 0, 0.3], ["S", 90, 55, 0.0, 0.8, 0.1, 2.0, 0.6, 1.0, 0.04], ["S", 140, 80, 0.1, 0.6, 0.1, 3.0, 0.3, 1.0, 0.06]]},
	"s63_gurgle": [["N", 0, 0, 0.0, 0.5, 0.05, 4.0, 0.5, 0.15, 0, 0.5], ["S", 110, 160, 0.0, 0.5, 0.05, 4.0, 0.35, 1.0, 0.15]],
	"s63_geyser": {"rev": 0.3, "drive": 2.0, "layers": [["N", 0, 0, 0.0, 0.7, 0.0, 4.0, 1.1, 0.5, 0, 0.4], ["S", 90, 40, 0.0, 0.5, 0.0, 6.0, 0.8, 1.0, 0.05]]},
	"s63_creak": [["S", 140, 120, 0.0, 0.35, 0.05, 4.0, 0.4, 0.4, 0.12], ["N", 0, 0, 0.0, 0.3, 0.05, 6.0, 0.3, 0.1, 0]],
	"s63_grip": {"drive": 2.0, "layers": [["N", 0, 0, 0.0, 0.2, 0.0, 14.0, 0.8, 0.3, 0, 0.3], ["S", 200, 70, 0.0, 0.2, 0.0, 12.0, 0.6, 1.0, 0.1]]},
	"s63_home": {"rev": 0.7, "layers": [["S", 440, 220, 0.0, 1.1, 0.05, 2.2, 0.22, 1.0, 0.02], ["S", 660, 330, 0.05, 1.0, 0.05, 2.4, 0.16, 1.0, 0.02], ["N", 0, 0, 0.0, 0.8, 0.2, 2.0, 0.25, 0.1, 0, 0.1]]},
	"s63_lost": {"rev": 0.4, "layers": [["S", 1320, 2640, 0.0, 0.3, 0.0, 8.0, 0.2, 1.0, 0], ["N", 0, 0, 0.0, 0.25, 0.0, 12.0, 0.5, 0.6, 0, 0.3]]},
}

const HALL := Vector2(3500.0, 4400.0)              # אולם המראות (שני קרומים)
const HALL_BOSS_X := 4160.0
const ARENA_X0 := 8300.0                           # הקרום של חדר הלב
const ROOT_X := 9480.0                             # הפנים של ה-ROOT (root.gd זז לכאן מ-level_w - 480 של main.gd)
const STATUES := [[760.0, 0, false], [1060.0, 1, true], [1520.0, 2, false], [1940.0, 0, true], [2480.0, 3, false],
	[2840.0, 1, true], [3260.0, 0, false], [4740.0, 0, true], [5640.0, 2, false], [6330.0, 1, true], [7120.0, 0, true],
	[7820.0, 3, false], [8120.0, 0, false]]        # [x, תנוחה, HOLLOW ישן?]
const PODS := [1260.0, 2180.0, 3080.0, 5020.0, 5930.0, 6720.0, 7520.0, 8060.0]
const HALL_PODS := [3720.0, 4270.0]                # מתפקעים כש-SUBJECT ZERO בשלב השני
const ARENA_PODS := [8660.0, 9270.0]               # ה-ROOT קורא להם (שלב III)
const SHELVES := [[1640.0, 260.0, 160.0, false, 0], [2580.0, 300.0, 170.0, true, 1], [5280.0, 280.0, 165.0, false, 2],
	[6880.0, 300.0, 175.0, true, 0], [7640.0, 260.0, 160.0, false, 1]]   # [x, רוחב, גובה, עצם?, שלל]
const MOUTHS := [900.0, 2300.0, 3300.0, 5200.0, 6100.0, 7000.0, 7900.0]
const ARENA_MOUTHS := [8560.0, 9150.0]
const MOUTH_H := 470.0                             # גובה פה העורק מעל הרצפה
const VALVES := [[1380.0, 0], [2380.0, 1], [3180.0, 2], [4920.0, 0], [5760.0, 1], [6560.0, 2], [7360.0, 0]]
const SNARES := [1820.0, 2720.0, 5480.0, 6200.0, 7220.0, 7980.0]
const ARENA_SHELVES := [[8470.0, 200.0, 150.0], [9000.0, 220.0, 235.0]]
const HALL_COVER := [[3820.0, "bones", Vector2(90, 44)], [4040.0, "barrels", Vector2(76, 52)]]   # מחסה של SUBJECT ZERO
const ARENA_COVER := [[8760.0, "bones", Vector2(96, 46)], [9040.0, "car", Vector2(150, 56)]]
const WAVE_T := Vector2(8.5, 12.5)                 # כל כמה זמן פה עורק שולח PILGRIM
const MAX_PILGRIMS := 3
const BEAT_T := Vector2(1.25, 0.62)                # זמן בין פעימות: בכניסה / ליד הלב
const HARDER := [1.0, 1.15, 1.3]

var fx: Node = null
var mouths := []
var pods := []
var hall_pods := []
var arena_pods := []
var valves := []
var membranes := []        # [שמאל האולם, ימין האולם, חדר הלב]
var shots := {"auto": 0, "shotgun": 0, "precision": 0, "explosive": 0}
var lessons_home := 0      # לבדיקות
var lessons_lost := 0
var waves := 0
var ending: Node = null
var zero: Node = null      # SUBJECT ZERO
var root: Node = null
var _hall := 0             # 0 = מחכה, 1 = נעול (קרב), 2 = נגמר
var _arena := 0            # 0 = פתוח, 1 = נעול, 2 = ה-ROOT מת (הסוף מתחיל), 3 = הסוף רץ
var _end_t := 0.0
var _beat_t := 0.5
var _wave_t := 6.0
var _last_shot := -1
var _first := true
var _seen := {}
var _said := {}
var _held := {}            # zombie id -> x (RootSnare מחזיק)


func zombie_weights() -> Dictionary:
	return {Registry.HOLLOW: 0.07, 0: 0.56, 1: 0.37}


func zombie_density() -> float:
	return 1.0 * float(HARDER[clampi(Settings.difficulty, 0, 2)])


func generators() -> Array:
	# שמות משלנו: "car" / "barrels" / "sandbags" רגילים של main.gd היו שמים מכוניות וחביות אמיתיות (גם באולם ובחדר הלב)
	return [["s63_car", 0.8], ["s63_barrels", 0.9], ["s63_sandbags", 1.0], ["s63_bones", 1.2]]


func custom_gen(gname: String, x: float) -> float:
	if not gname.begins_with("s63_"):
		return 0.0
	gname = gname.trim_prefix("s63_")
	if (x > HALL.x - 160.0 and x < HALL.y + 60.0) or x > ARENA_X0 - 200.0:
		return 140.0
	var sz := Vector2(110.0, 50.0)
	match gname:
		"car":
			sz = Vector2(rng.randf_range(140.0, 160.0), rng.randf_range(52.0, 58.0))
		"barrels":
			sz = Vector2(rng.randf_range(70.0, 90.0), rng.randf_range(48.0, 56.0))
		"sandbags":
			sz = Vector2(rng.randf_range(96.0, 120.0), rng.randf_range(40.0, 46.0))
		_:
			sz = Vector2(rng.randf_range(84.0, 110.0), rng.randf_range(40.0, 50.0))
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
	return Registry.ROOT


func music() -> String:
	return "res://music/level2_suspense.mp3"


func world_tint() -> Color:
	return Color(1.0, 0.95, 0.95)


func fog() -> bool:
	return false


func pits() -> int:
	return 0


func build_background(layer: CanvasLayer) -> Node:
	Decor.U.reset()   # (סטטי - נשאר מריצה קודמת)
	var bg = Backdrop.new()
	bg.level_w = level_w
	bg.sky = func(ci: CanvasItem, v: Vector2, t: float):
		Decor.heart_sky(ci, v, t)
	bg.add_layer(0.06, func(ci: CanvasItem, sc: float, v: Vector2, t: float):
		Decor.far_vault(ci, sc, v, 556.0, t))
	bg.add_layer(0.28, func(ci: CanvasItem, sc: float, v: Vector2, t: float):
		Decor.mid_memory(ci, sc, v, 612.0, t))
	bg.add_layer(0.6, func(ci: CanvasItem, sc: float, v: Vector2, t: float):
		Decor.near_flesh(ci, sc, v, 636.0, t))
	bg.overlay = func(ci: CanvasItem, v: Vector2, t: float):
		Decor.heart_overlay(ci, v, t)
	layer.add_child(bg)
	return bg


func build_world() -> void:
	var x := 0.0
	while x < level_w:
		var g := Decor.FleshGround.new()
		g.w = minf(1024.0, level_w - x)
		g.depth = main.floor_thickness
		g.seed_v = rng.randi()
		g.wx = x
		g.prison = 1.0 if x < 1000.0 else 0.0
		add_world(g, Vector2(x, floor_y))
		x += 1024.0
	add_world(Decor.Threshold.new(), Vector2(0.0, floor_y))
	# אולם המראות + חדר הלב: נקיים (קודם, כדי ששום מכשול לא ייכנס)
	reserve(Rect2(HALL.x - 60.0, floor_y - 60.0, HALL.y - HALL.x + 120.0, 60.0))
	reserve(Rect2(ARENA_X0 - 140.0, floor_y - 60.0, level_w - ARENA_X0 + 140.0, 60.0))
	main._spawn_avoid.append([HALL.x - 80.0, HALL.y + 80.0])
	main._spawn_avoid.append([ARENA_X0 - 160.0, level_w])
	# פסלים
	for s in STATUES:
		if bool(s[2]):
			reserve(Rect2(float(s[0]) - 30.0, floor_y - 40.0, 60.0, 40.0))
			continue   # HOLLOW ישן: הוא עצמו הפסל (hollow.gd -> STATUE)
		var st := Decor.Statue.new()
		st.pose = int(s[1])
		st.face = -1.0 if rng.randf() < 0.4 else 1.0
		st.size = rng.randf_range(1.0, 1.25)
		st.seed_v = rng.randi() % 1000
		add_world(st, Vector2(float(s[0]), floor_y))
		reserve(Rect2(float(s[0]) - 30.0, floor_y - 40.0, 60.0, 40.0))
	# שקי רחם
	for px in PODS + HALL_PODS + ARENA_PODS:
		var p := Decor.HollowPod.new()
		add_world(p, Vector2(float(px), floor_y))
		reserve(Rect2(float(px) - 40.0, floor_y - 40.0, 80.0, 40.0))
		if px in HALL_PODS:
			hall_pods.append(p)
		elif px in ARENA_PODS:
			arena_pods.append(p)
		else:
			pods.append(p)
	# מדפי שורש (קומה) + סולמות + אספקה
	var loot := [PickupScript.AMMO, PickupScript.HEALTH, PickupScript.GRENADE]
	for s in SHELVES:
		_shelf(float(s[0]), float(s[1]), float(s[2]), bool(s[3]))
		_pickup(loot[int(s[4]) % loot.size()], Vector2(float(s[0]) + float(s[1]) * 0.5, floor_y - float(s[2]) - 30.0))
	# פיות עורקים בתקרה
	for mx in MOUTHS + ARENA_MOUTHS:
		var m := Decor.VeinMouth.new()
		add_world(m, Vector2(float(mx), floor_y - MOUTH_H))
		mouths.append(m)
	# מלכודות
	for v in VALVES:
		var hv := Decor.HeartValve.new()
		hv.phase = int(v[1])
		add_world(hv, Vector2(float(v[0]), floor_y))
		valves.append(hv)
		reserve(Rect2(float(v[0]) - 70.0, floor_y - 40.0, 140.0, 40.0))
	for sx in SNARES:
		add_world(Decor.RootSnare.new(), Vector2(float(sx), floor_y))
		reserve(Rect2(float(sx) - 50.0, floor_y - 40.0, 100.0, 40.0))
	# אולם המראות
	var mh := Decor.MirrorHall.new()
	mh.w = HALL.y - HALL.x
	add_world(mh, Vector2(HALL.x, floor_y))
	for i in 2:
		var mb := Decor.Membrane.new()
		mb.inside = 1.0 if i == 0 else -1.0
		add_world(mb, Vector2(HALL.x if i == 0 else HALL.y, floor_y))
		membranes.append(mb)
	for c in HALL_COVER:
		var o := Decor.Obstacle.new()
		o.kind = String(c[1])
		o.size = c[2]
		o.seed_v = rng.randi()
		add_world(o, Vector2(float(c[0]), floor_y))
	# חדר הלב
	var hc := Decor.HeartChamber.new()
	hc.w = level_w - ARENA_X0
	add_world(hc, Vector2(ARENA_X0, floor_y))
	var am := Decor.Membrane.new()
	am.inside = 1.0
	add_world(am, Vector2(ARENA_X0, floor_y))
	membranes.append(am)
	for s in ARENA_SHELVES:
		_shelf(float(s[0]), float(s[1]), float(s[2]), false)
	for c in ARENA_COVER:
		var o := Decor.Obstacle.new()
		o.kind = String(c[1])
		o.size = c[2]
		o.seed_v = rng.randi()
		add_world(o, Vector2(float(c[0]), floor_y))
	_pickup(PickupScript.HEALTH, Vector2(ARENA_X0 - 150.0, floor_y - 30.0))
	_pickup(PickupScript.AMMO, Vector2(ARENA_X0 - 90.0, floor_y - 30.0))
	# ה-ROOT חוסם את היציאה: קיר שרק השחקן מתנגש בו (קליעים עוברים - pass_barrier.gd)
	var wall := StaticBody2D.new()
	wall.collision_layer = 512
	wall.collision_mask = 0
	var cs := CollisionShape2D.new()
	var rs := RectangleShape2D.new()
	rs.size = Vector2(30.0, 1600.0)
	cs.shape = rs
	cs.position = Vector2(0.0, -800.0)
	wall.add_child(cs)
	wall.position = Vector2(ROOT_X - 30.0, floor_y)
	main.add_child(wall)


func _shelf(sx: float, sw: float, tier: float, bone: bool) -> void:
	var sh := Decor.RootShelf.new()
	sh.w = sw
	sh.tier = tier
	sh.bone = bone
	add_world(sh, Vector2(sx, floor_y))
	var pf = add_floor(sx, floor_y - tier, sw, "steel", false, false)
	pf.visible = false
	add_ladder(sx + 10.0, floor_y - tier)
	add_ladder(sx + sw - 34.0, floor_y - tier)
	reserve(Rect2(sx - 10.0, floor_y - 40.0, 60.0, 40.0))
	reserve(Rect2(sx + sw - 50.0, floor_y - 40.0, 60.0, 40.0))


func _pickup(kind: int, pos: Vector2) -> void:
	var p = PickupScript.new()
	p.kind = kind
	p.life = 100000.0
	main.add_child(p)
	p.setup(pos, Vector2.ZERO)


func build_effects() -> void:
	fx = Decor.HeartFX.new()
	fx.vp = vp
	screen_layer.add_child(fx)


# HOLLOW בפסלים ובשקים, SUBJECT ZERO באולם, רגילים על המדפים.
func extra_spawns() -> void:
	for s in STATUES:
		if not bool(s[2]):
			continue
		var z = spawn(Registry.HOLLOW, float(s[0]))
		if z != null and z.type_mod != null:
			z.type_mod.as_statue(int(s[1]))
	for p in pods + hall_pods + arena_pods:
		var z = spawn(Registry.HOLLOW, p.global_position.x)
		if z != null and z.type_mod != null:
			p.z = z
			z.type_mod.enter_pod(p, p in hall_pods or p in arena_pods)
	# SUBJECT ZERO (HOLLOW בוס): chase_range > 600 = מצב בוס (כמו הבוס של main.gd)
	zero = ZScene.instantiate()
	zero.kind = Registry.HOLLOW
	zero.chase_range = 650.0
	zero.speed_mult = Settings.preset().zombie_speed
	zero.position = Vector2(HALL_BOSS_X, floor_y)
	main.add_child(zero)
	zero.world_w = level_w
	zero._dir = -1.0
	for s in SHELVES:
		spawn(0, float(s[0]) + float(s[1]) * 0.6, floor_y - float(s[2]))


# ============================================================
#  "הם לומדים": באיזה נשק אתה יורה
# ============================================================
func _track_shots(pl: Node) -> void:
	if Game.shot_id == _last_shot:
		return
	_last_shot = Game.shot_id
	var c := Decor.cat_of_weapon(int(pl.gun))
	if shots.has(c):
		shots[c] = int(shots[c]) + 1


# הנשק שאתה הכי משתמש בו (rank 1 = השני). מעט יריות - לפי PlayerMemory (מהשלבים הקודמים)
func fav_cat(rank := 0) -> String:
	var arr := []
	var tot := 0
	for c in Decor.CATS:
		tot += int(shots[c])
	for c in Decor.CATS:
		var v := float(shots[c]) if tot >= 12 else float(PlayerMemory.weapon_use.get(c, 0.0)) * 100.0 + float(shots[c])
		arr.append([v, c])
	arr.sort_custom(func(a, b): return float(a[0]) > float(b[0]))
	return String(arr[clampi(rank, 0, 3)][1])


# ============================================================
#  שיעורים: PILGRIM
# ============================================================
func pilgrims_alive() -> int:
	var n := 0
	for z in get_tree().get_nodes_in_group("s63_pilgrims"):
		if not z.dead:
			n += 1
	return n


# PILGRIM חדש: מפה של עורק / מגופה של HOLLOW. core = עף אל הלב של ה-ROOT (בזירה)
func spawn_pilgrim(pos: Vector2, cat: String, core := false) -> Node:
	if pilgrims_alive() >= MAX_PILGRIMS + (1 if core else 0):
		return null
	var z = spawn(Registry.PILGRIM, pos.x, pos.y)
	if z == null or z.type_mod == null:
		return null
	z.type_mod.launch(pos, cat, core)
	return z


# HOLLOW מת: השיעור עולה מהגופה (מה שהרג אותו)
func hollow_dead(pos: Vector2, cat: String, boss := false) -> void:
	main.set_meta("ho_kills", int(main.get_meta("ho_kills", 0)) + 1)
	if boss or not (cat in Decor.CATS) or _arena >= 2:
		return
	if randf() < 0.6:
		get_tree().create_timer(0.7).timeout.connect(func():
			if is_instance_valid(self) and _arena < 2:
				spawn_pilgrim(pos + Vector2(0, -40), cat))


# PILGRIM הגיע הביתה: עוד שיעור ל-ROOT
func lesson_home(cat: String, pos: Vector2) -> void:
	lessons_home += 1
	Decor.U.lessons[cat] = int(Decor.U.lessons.get(cat, 0)) + 1
	Decor.U.seen_lesson = true
	main.set_meta("pg_home_" + cat, int(main.get_meta("pg_home_" + cat, 0)) + 1)
	Decor.U.notify("A LESSON REACHED THE ROOT:  " + String(Decor.CAT_NAME.get(cat, "TRICKS")), Decor.CAT_COL.get(cat, Decor.ECHO))
	Sfx.play("s63_home", null, -4.0, 0.0, 1)
	for m in mouths:
		if absf(m.global_position.x - pos.x) < 500.0:
			m.pulse()
	if root != null and is_instance_valid(root) and not root.dead and root.type_mod != null:
		root.type_mod.learn(cat)
	var pl := _player()
	if pl != null and not _said.has("home"):
		_said["home"] = true
		Decor.U.say(pl, "One got through. The heart just learned my " + String(Decor.CAT_NAME.get(cat, "moves")).to_lower() + ".", Color("ffb0a0"))


func lesson_lost(cat: String) -> void:
	lessons_lost += 1
	Decor.U.seen_lesson = true
	main.set_meta("pg_lost", int(main.get_meta("pg_lost", 0)) + 1)


# ============================================================
#  לולאה
# ============================================================
func _player() -> Node2D:
	return get_tree().get_first_node_in_group("player") as Node2D


func _text(t: String, c: Color, pos: Vector2, size := 18) -> void:
	var p = ZScript.HitText.new()
	p.text = t
	p.color = c
	p.size = size
	main.add_child(p)
	p.global_position = pos


func _process(delta: float) -> void:
	# הלב פועם (ויזואלי + השסתומים)
	Decor.U.t += delta
	Decor.U.beat = maxf(0.0, Decor.U.beat - delta * 2.6)
	if main == null or _arena >= 2:   # ה-ROOT מת: הלב עצר
		return
	var pl := _player()
	if pl != null:
		Decor.U.heart_k = move_toward(Decor.U.heart_k, clampf((pl.global_position.x - 900.0) / (ARENA_X0 - 900.0), 0.0, 1.0), delta * 0.2)
	_beat_t -= delta
	if _beat_t <= 0.0:
		var k: float = Decor.U.heart_k
		if _arena == 1 and root != null and is_instance_valid(root) and not root.dead:
			k = 1.0 + 0.25 * (1.0 - float(root.hp) / float(maxi(root.max_hp, 1)))
		_beat_t = lerpf(BEAT_T.x, BEAT_T.y, clampf(k, 0.0, 1.25))
		Decor.U.beat = 1.0
		Decor.U.beats += 1
		Sfx.play("s63_beat", null, lerpf(-16.0, -5.0, clampf(k, 0.0, 1.0)), 0.0, 1)
		for v in valves:
			v.beat(Decor.U.beats)


func _physics_process(delta: float) -> void:
	if main == null:
		return
	var pl := _player()
	if pl == null:
		return
	if _first:
		_first = false
		_first_tick(pl)
	if pl.dead:
		return
	_track_shots(pl)
	var px: float = pl.global_position.x
	_hold_snared()
	if Engine.get_physics_frames() % 10 == 0:
		_hall_tick(pl)
		_arena_tick(pl)
		_hints(pl)
		_pods(pl)
	if _arena >= 2:
		_end_tick(delta)
		return
	# גלי PILGRIM מפיות העורקים (לא באולם הנעול)
	_wave_t -= delta
	if _wave_t <= 0.0:
		_wave_t = randf_range(WAVE_T.x, WAVE_T.y) * (0.8 if Decor.U.heart_k > 0.5 else 1.0)
		if _hall != 1 and px > 600.0:
			_wave(pl)


func _first_tick(pl: Node2D) -> void:
	# השער לא נפתח ממוות של בוס (גם לא של SUBJECT ZERO) - רק הסוף מסיים את השלב
	for ex in get_tree().get_nodes_in_group("level_exit"):
		ex.remove_from_group("level_exit")
	for z in get_tree().get_nodes_in_group("zombies"):
		if z.kind == Registry.ROOT:
			root = z
	# התחלה מנקודת הביקורת (אחרי האולם): SUBJECT ZERO כבר מאחוריך
	if pl.global_position.x > HALL.y + 100.0:
		if zero != null and is_instance_valid(zero):
			zero.queue_free()
		zero = null
		_hall = 2
		for p in hall_pods:
			if p.z != null and is_instance_valid(p.z):
				p.z.queue_free()
	else:
		Decor.U.say(pl, "The heart. I can hear it from here... and it can hear me.", Color("ffb0a0"))


# PILGRIM מפה של עורק מאחוריך / מעליך (עף ימינה, מעל הראש שלך, הביתה)
func _wave(pl: Node2D) -> void:
	var px := pl.global_position.x
	var best: Node2D = null
	var bd := INF
	for m in mouths:
		var mx: float = m.global_position.x
		if mx > ARENA_X0 - 100.0:
			continue
		var dx := px - mx   # עדיף פה קצת מאחוריך (שתספיק לראות אותו עובר)
		if dx < -250.0 or dx > 900.0:
			continue
		var score := absf(dx - 350.0)
		if score < bd:
			bd = score
			best = m
	if best == null:
		return
	var cat := fav_cat() if randf() < 0.65 else fav_cat(1)
	if spawn_pilgrim(best.global_position + Vector2(0, 30), cat) != null:
		best.pulse()
		waves += 1


# SnareTrap מחזיק זומבים (meta s63_held = עד מתי)
func _hold_snared() -> void:
	if Engine.get_physics_frames() % 3 == 0:
		for z in get_tree().get_nodes_in_group("zombies"):
			if z.has_meta("s63_held") and not _held.has(z.get_instance_id()):
				_held[z.get_instance_id()] = [z, z.global_position.x]
	if _held.is_empty():
		return
	var now := Time.get_ticks_msec()
	for id in _held.keys():
		var e: Array = _held[id]
		var z = e[0]
		if not is_instance_valid(z) or z.dead or int(z.get_meta("s63_held", 0)) < now:
			if is_instance_valid(z):
				z.remove_meta("s63_held")
			_held.erase(id)
			continue
		z.global_position.x = float(e[1])
		z.velocity.x = 0.0


# שקי הרחם: מתבשלים כשאתה מתקרב
func _pods(pl: Node2D) -> void:
	var px := pl.global_position.x
	for p in pods:
		if p.state == Decor.HollowPod.GROW and absf(p.global_position.x - px) < 330.0 and absf(pl.global_position.y - floor_y) < 260.0:
			p.ripen()


func _hall_tick(pl: Node2D) -> void:
	if _hall == 2:
		return
	var px := pl.global_position.x
	if zero == null or not is_instance_valid(zero) or zero.dead:
		if _hall == 1 or zero == null or not is_instance_valid(zero) or zero.dead:
			_hall = 2
			for m in [membranes[0], membranes[1]]:
				m.unseal()
			for p in hall_pods:   # שקים שלא נפתחו נובלים
				if p.closed() and p.z != null and is_instance_valid(p.z) and not p.z.dead:
					p.burst()
			if not _said.has("zero_dead"):
				_said["zero_dead"] = true
				Decor.U.say(pl, "It had my face... but not my memories.", Color("ffb0a0"))
				_text("THE HALL OPENS", Color("b8ff9a"), pl.global_position + Vector2(0, -150), 22)
		return
	if _hall == 0 and px > HALL.x + 130.0 and px < HALL.y - 80.0:
		_hall = 1
		for m in [membranes[0], membranes[1]]:
			m.seal()
		_text("SEALED IN", Color("ff8a7a"), pl.global_position + Vector2(0, -150), 22)


# SUBJECT ZERO (שלב שני) מעיר את השקים של האולם
func wake_hall() -> int:
	var n := 0
	for p in hall_pods:
		if p.closed():
			p.ripen()
			n += 1
	return n


# ה-ROOT (שלב III) קורא ל-HOLLOW מהשקים של הזירה. מחזיר כמה
func wake_arena(max_n := 2) -> int:
	var n := 0
	var alive := 0
	for z in get_tree().get_nodes_in_group("s63_hollows"):
		if not z.dead and not z.type_mod.dormant() and z.global_position.x > ARENA_X0:
			alive += 1
	for p in arena_pods:
		if n >= max_n or alive + n >= 3:
			break
		if p.closed():
			p.ripen()
			n += 1
	if n < max_n and alive + n < 3:   # השקים ריקים: שק חדש גדל ומתפקע
		for p in arena_pods:
			if n >= max_n or alive + n >= 3:
				break
			if not p.closed():
				var z = spawn(Registry.HOLLOW, p.global_position.x)
				if z != null and z.type_mod != null:
					p.state = Decor.HollowPod.GROW
					p.z = z
					z.type_mod.enter_pod(p, false)
					p.ripen()
					n += 1
	return n


func _arena_tick(pl: Node2D) -> void:
	if root == null or not is_instance_valid(root):
		for z in get_tree().get_nodes_in_group("zombies"):
			if z.kind == Registry.ROOT:
				root = z
	if _arena == 0:
		if pl.global_position.x > ARENA_X0 + 160.0 and root != null and not root.dead:
			_arena = 1
			membranes[2].seal()
			for z in get_tree().get_nodes_in_group("zombies"):   # מה שנשאר בחוץ - נשאר בחוץ
				if not z.is_boss() and z.global_position.x < ARENA_X0 - 20.0 and absf(z.global_position.x - ARENA_X0) < 600.0:
					z._alert_t = 0.0
	elif _arena == 1 and (root == null or not is_instance_valid(root) or root.dead):
		root_dead()


# ה-ROOT מת: עוד רגע הוא מדבר (effects/s63_ending.gd)
func root_dead() -> void:
	if _arena >= 2:
		return
	_arena = 2
	_end_t = 0.0
	for z in get_tree().get_nodes_in_group("zombies"):   # כל הכוורת נעצרת (הלב מפסיק לפעום)
		if z != root and not z.dead and z.global_position.x > ARENA_X0 - 900.0:
			z.take_damage(9999, z.global_position + Vector2(0, -30), Vector2.UP, true, {"source": "trap"})


func _end_tick(delta: float) -> void:
	if root != null and is_instance_valid(root) and root.type_mod != null:
		root.type_mod.tick_dead(delta)
	if _arena != 2:
		return
	_end_t += delta
	if _end_t < 2.6:
		return
	_arena = 3
	ending = EndingScript.new()
	ending.stage = self
	ending.main = main
	ending.root = root
	main.add_child(ending)


# אספקה בזמן הקרב (ה-ROOT בין השלבים)
func drop_supply(kind_name := "ammo") -> void:
	var pl := _player()
	if pl == null:
		return
	var x := clampf(pl.global_position.x + randf_range(-160.0, 160.0), ARENA_X0 + 80.0, ROOT_X - 120.0)
	var p = PickupScript.new()
	p.kind = PickupScript.HEALTH if kind_name == "health" else PickupScript.AMMO
	p.life = 100000.0
	main.add_child(p)
	p.setup(Vector2(x, floor_y - 380.0), Vector2(0.0, 40.0))


# רמזים: פעם אחת לכל סוג, כשהוא על המסך
func _hints(pl: Node2D) -> void:
	if _seen.size() >= 3:
		return
	for z in get_tree().get_nodes_in_group("zombies"):
		if z.dead or z.type_mod == null or z.is_boss():
			continue
		var k: int = z.kind
		if _seen.has(k) or not (k == Registry.HOLLOW or k == Registry.PILGRIM):
			continue
		if absf(z.global_position.x - pl.global_position.x) > 620.0 or not Art.on_screen(z, z.global_position + Vector2(0, -30), -30.0):
			continue
		if k == Registry.HOLLOW and z.type_mod.dormant():
			if not _seen.has("statue") and z.type_mod.is_statue() and absf(z.global_position.x - pl.global_position.x) < 420.0:
				_seen["statue"] = true
				Decor.U.say(pl, "Statues of me. Every pose I ever fought in.", Color("ffb0a0"))
			continue
		_seen[k] = true
		if k == Registry.HOLLOW:
			z._popup("THEY FIGHT LIKE YOU NOW", Color("ff8a7a"), 14, -120.0)
			Decor.U.say(pl, "That's... me. My coat, my roll. They GREW me.", Color("ffb0a0"))
		else:
			z._popup("THEY CARRY YOUR LESSONS HOME NOW", Decor.ECHO, 13, -40.0)
			Decor.U.say(pl, "It's carrying something home. Shoot the sac before it gets there!", Color("c8ffb0"))
			Decor.U.seen_lesson = true
		return
