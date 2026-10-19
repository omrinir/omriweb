extends "res://levels/stage_base.gd"
# ============================================================
#  STAGE 62 - "THE HIVE MIND" (אזור שביעי - פטגוניה, שלב 8) - "THEY LEARNED TO THINK AS ONE"
#  (הסיפור: מתחת לכלא הישן של אושואיה (ה-Presidio, "סוף העולם") ה-ROOT גדל למערה חיה. הקירות רקמת מוח ופטרייה,
#   חוטי עצב נושאים פולסים של אור אל הלב, ובריכות זיכרון זוהרות משחזרות את הקרבות הישנים של הגיבור. כאן הכוורת
#   מדברת אליו בפעם הראשונה בקול אחד ומספרת לו למה: "We were made to learn you... You are our teacher.")
#  (effects/s62_decor.gd): חושך המערה, הכיפה, קיר רקמת המוח עם כתובות פטרייה, שורשים ווילונות פטרייה.
#  המבנה: מרתף הכלא (Cellar) -> המערה הראשונה (בריכת זיכרון, סוגר בשר, פטריות מדף) -> אולם העצבים (עמודי בשר, קשרי
#    עצב GANGLIA, SYNAPSE) -> חדר הקול האחד (STORY, סצנת הסיפור) -> גלריית הזיכרונות (עוד בריכות) -> זירת THE FLOOD
#    (FloodArena) -> הפיר שיורד אל הלב (היציאה).
#  "THEY THINK AS ONE": Ganglion (קשר עצב על עמוד) רואה אותך -> פולס רץ אליו בחוט -> כל הזומבים ב-RANGE מסתערים
#    יחד. יורים בקשר לפני שהפולס מגיע. Maw - סוגר בשר ברצפה שנושך מי שעומד עליו (גם זומבים).
#  בריכות זיכרון (POOLS): כשמתקרבים - REMNANT של הזיכרון שבבריכה עולה ממנה (אחרי שלמדו: זוג).
#  זומבים: SEEPER (הולכים ושלוליות שמחכות - SEEPERS), SYNAPSE (קבוצות - SYN_GROUPS, נוצרות כשמתקרבים, אז קבוצה
#    מאוחרת כבר "למדה"), REMNANT (מהבריכות), רגילים, רצים. בוס: THE FLOOD (enemies/types/seeper.gd, מצב בוס).
#  "הם לומדים" (חוק הסיפור 3): הנבגים בהריגה; כאן גם רואים את זה: הבריכות משחזרות את הקרבות שלך, והכוורת כותבת לך.
#  קטע סיפור (story/scenes/l62_hive.gd): חדר הקול האחד, נקי (STORY). SEEPER עומד בבריכה הגדולה (STORY_ACTOR).
#    on_story_beat(): "speak" (הקירות והחוטים פועמים - הכוורת מדברת), "replay" (כל הבריכות מבזיקות), "mirror" (הפנים
#    בקיר נהיים הפנים שלך), "melt" (הדובר נמס לבריכה). אחרי הסצנה: הבריכה הגדולה משחררת שני זיכרונות.
#  לשנות: POOLS, MAWS, GANGLIA, PILLARS, SHELVES, SEEPERS, SYN_GROUPS, OBST, LINES, STORY, STORY_ACTOR, ARENA_X,
#         ARENA_SHELVES, zombie_weights().
# ============================================================

const Decor := preload("res://effects/s62_decor.gd")
const SynT := preload("res://enemies/types/synapse.gd")
const PickupScript := preload("res://pickup.gd")
const Sfx := preload("res://sfx.gd")
const ZScript := preload("res://zombie.gd")

const SOUNDS := {
	"s62_squish": [["N", 0, 0, 0.0, 0.16, 0.0, 16.0, 0.5, 0.3, 0, 0.1], ["S", 180, 80, 0.0, 0.12, 0.0, 20.0, 0.3, 1.0, 0]],
	"s62_sever": {"rev": 0.3, "drive": 2.0, "layers": [["N", 0, 0, 0.0, 0.35, 0.0, 8.0, 0.8, 0.4, 0, 0.1], ["C", 0, 0, 0.0, 0.3, 0.0, 8.0, 0.6, 1.0, 0], ["S", 1200, 150, 0.0, 0.4, 0.0, 6.0, 0.3, 1.0, 0]]},
	"s62_charge": {"rev": 0.4, "layers": [["S", 110, 440, 0.0, 2.1, 0.1, 0.5, 0.25, 1.0, 0.02], ["S", 165, 660, 0.0, 2.1, 0.1, 0.5, 0.15, 1.0, 0.02], ["N", 0, 0, 0.0, 2.0, 0.4, 0.8, 0.12, 1.0, 0, 0.6]]},
	"s62_sync": {"rev": 0.6, "drive": 2.2, "layers": [["V", 98, 98, 0.0, 1.2, 0.02, 2.0, 0.7, 1.0, 0.03, 0, [400, 900, 20]], ["V", 147, 147, 0.0, 1.2, 0.02, 2.0, 0.5, 1.0, 0.03, 0, [520, 1100, 18]], ["V", 196, 196, 0.0, 1.2, 0.02, 2.0, 0.35, 1.0, 0.03, 0, [700, 1400, 16]], ["C", 0, 0, 0.0, 0.3, 0.0, 8.0, 0.4, 1.0, 0]]},
	"s62_gurgle": [["B", 1.2, 1.6, 0.0, 0.6, 0.05, 4.0, 0.45, 1.0, 0, 0, 90.0], ["N", 0, 0, 0.0, 0.6, 0.1, 4.0, 0.2, 0.2, 0]],
	"s62_chomp": {"drive": 2.4, "layers": [["C", 0, 0, 0.0, 0.25, 0.0, 10.0, 0.9, 1.0, 0], ["N", 0, 0, 0.0, 0.3, 0.0, 9.0, 0.6, 0.3, 0, 0.1], ["S", 90, 40, 0.0, 0.3, 0.0, 9.0, 0.7, 1.0, 0]]},
	"s62_maw_die": {"rev": 0.4, "drive": 2.0, "layers": [["V", 140, 60, 0.0, 0.9, 0.02, 2.5, 0.7, 1.0, 0.06, 0, [400, 800, 20]], ["B", 0.8, 0.4, 0.0, 0.9, 0.0, 3.0, 0.4, 1.0, 0, 0, 70.0]]},
	"s62_rise": {"rev": 0.5, "layers": [["S", 330, 990, 0.0, 0.9, 0.1, 2.0, 0.15, 1.0, 0.01], ["B", 0.6, 1.4, 0.0, 0.9, 0.1, 2.0, 0.3, 1.0, 0, 0, 80.0], ["N", 0, 0, 0.0, 0.8, 0.2, 2.0, 0.15, 1.0, 0, 0.7]]},
	"s62_heart": {"rev": 0.3, "drive": 1.8, "layers": [["S", 52, 38, 0.0, 0.22, 0.0, 9.0, 1.0, 1.0, 0], ["S", 48, 34, 0.26, 0.26, 0.0, 8.0, 0.8, 1.0, 0]]},
	"s62_drone": {"rev": 0.7, "layers": [["V", 55, 55, 0.0, 3.0, 0.8, 0.5, 0.35, 1.0, 0.04, 0, [300, 650, 6]], ["V", 82, 83, 0.0, 3.0, 0.8, 0.5, 0.25, 1.0, 0.04, 0, [420, 900, 5]], ["N", 0, 0, 0.0, 3.0, 1.0, 0.5, 0.12, 0.15, 0]]},
	"s62_replay": {"rev": 0.7, "layers": [["S", 660, 1320, 0.0, 0.8, 0.05, 2.0, 0.15, 1.0, 0.02], ["N", 0, 0, 0.0, 0.8, 0.0, 2.5, 0.2, 1.0, 0, 0.8], ["Q", 120, 120, 0.0, 0.4, 0.0, 4.0, 0.06, 0.5, 0]]},
}

const POOLS := [[1500.0, 0], [3420.0, 2], [6350.0, 1], [7150.0, 3], [8180.0, 0]]   # [x, זיכרון] (Decor.MEMORIES)
const POOL_R := 430.0                     # כמה קרוב - והזיכרון עולה
const MAWS := [1960.0, 4060.0, 7600.0]
const GANGLIA := [2950.0, 3780.0, 6820.0, 8560.0]
const PILLARS := [2620.0, 4260.0, 7920.0]
const SHELVES := [[2160.0, 230.0, 120.0], [3130.0, 210.0, 120.0], [6480.0, 230.0, 120.0], [8240.0, 210.0, 120.0]]   # [x, רוחב, גובה]
const SEEPERS := [[1180.0, false], [1820.0, true], [2720.0, false], [3560.0, true], [3980.0, false], [6120.0, false],
	[6920.0, true], [7330.0, false], [8020.0, true], [8720.0, false]]   # [x, lurk = שלולית שמחכה]
const SYN_GROUPS := [[2420.0, 2], [3300.0, 2], [6660.0, 3], [7760.0, 2], [8420.0, 3]]   # [x, כמה מקושרים]
const OBST := [[1320.0, "pod", Vector2(96, 54)], [2520.0, "bones", Vector2(110, 50)], [3660.0, "root", Vector2(120, 62)],
	[6250.0, "stalk", Vector2(90, 70)], [7020.0, "pod", Vector2(100, 56)], [8380.0, "bones", Vector2(110, 50)]]
const LINES := [[560.0, "The prison goes down further than any map said.", "d8d0c0"],
	[1020.0, "That's me... in the water. They're replaying my fights.", "a8f0ff"],
	[2860.0, "The whole cave is thinking. I can feel it.", "c8ffb0"],
	[6240.0, "Every fight I ever had... they kept all of it.", "a8f0ff"],
	[8950.0, "Something big is moving in the water.", "b8ff7a"]]
const STORY := Vector2(4500.0, 5940.0)    # חדר הקול האחד: נקי לסצנה
const STORY_ACTOR := 5300.0
const ARENA_X := 9050.0
const ARENA_SHELVES := [[9300.0, 200.0, 120.0], [9760.0, 200.0, 120.0]]
const HARDER := [1.0, 1.15, 1.3]
const SAY_GAP := 2.4

var fx: Node = null
var pools := []
var story_pool: Node = null
var _pools_done := {}
var _syn_done := {}
var _lines_done := {}
var _seen := {}
var _post_story := 0
var _boss: Node = null
var _boss_said := 0
var _drone_t := 3.0
var _heart_t := 0.0
var _remnant_n := 0       # לבדיקות
var _syn_n := 0
var _say_q := []
var _say_cd := 0.0


func zombie_weights() -> Dictionary:
	return {Registry.SEEPER: 0.04, Registry.REMNANT: 0.012, 0: 0.58, 1: 0.35}


func zombie_density() -> float:
	return 0.95 * float(HARDER[clampi(Settings.difficulty, 0, 2)])


func generators() -> Array:
	return [["pod", 1.0], ["bones", 0.9], ["stalk", 0.7], ["root", 0.6]]


func custom_gen(gname: String, x: float) -> float:
	if not gname in ["pod", "bones", "stalk", "root"]:
		return 0.0
	var sz := Vector2(96.0, 54.0)
	match gname:
		"pod":
			sz = Vector2(rng.randf_range(88.0, 108.0), rng.randf_range(50.0, 58.0))
		"bones":
			sz = Vector2(rng.randf_range(96.0, 120.0), rng.randf_range(44.0, 52.0))
		"stalk":
			sz = Vector2(rng.randf_range(80.0, 96.0), rng.randf_range(60.0, 74.0))
		_:
			sz = Vector2(rng.randf_range(110.0, 130.0), rng.randf_range(56.0, 66.0))
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
	return Registry.SEEPER


func music() -> String:
	return "res://music/level2_suspense.mp3"


func world_tint() -> Color:
	return Color(0.96, 0.92, 0.98)


func fog() -> bool:
	return false


func pits() -> int:
	return 0


func dark_level() -> bool:
	return false


func build_background(layer: CanvasLayer) -> Node:
	Decor.U.voice_ms = -1   # (סטטי - נשאר מריצה קודמת)
	Decor.U.replay_ms = -1
	Decor.U.face_ms = -1
	Decor.U.sync_ms = -1
	Decor.U.heart = 0.0
	var bg = Backdrop.new()
	bg.level_w = level_w
	bg.sky = func(ci: CanvasItem, v: Vector2, t: float):
		Decor.hive_sky(ci, v, t)
	bg.add_layer(0.06, func(ci: CanvasItem, sc: float, v: Vector2, t: float):
		Decor.far_cavern(ci, sc, v, 556.0, t))
	bg.add_layer(0.28, func(ci: CanvasItem, sc: float, v: Vector2, t: float):
		Decor.mid_wall(ci, sc, v, 612.0, t))
	bg.add_layer(0.6, func(ci: CanvasItem, sc: float, v: Vector2, t: float):
		Decor.near_roots(ci, sc, v, 636.0, t))
	bg.overlay = func(ci: CanvasItem, v: Vector2, t: float):
		Decor.hive_overlay(ci, v, t)
	layer.add_child(bg)
	return bg


func build_world() -> void:
	var x := 0.0
	while x < level_w:
		var g := Decor.HiveGround.new()
		g.w = minf(1024.0, level_w - x)
		g.depth = main.floor_thickness
		g.seed_v = rng.randi()
		g.stone = 1.0 if x < 1000.0 else (0.25 if x < 2000.0 else 0.0)
		g.wx = x
		add_world(g, Vector2(x, floor_y))
		x += 1024.0
	add_world(Decor.Cellar.new(), Vector2(0.0, floor_y))
	reserve(Rect2(0.0, floor_y - 60.0, 760.0, 60.0))
	# חדר הקול האחד: נקי לגמרי (קודם, כדי שאף דבר לא ייכנס אליו)
	reserve(Rect2(STORY.x - 30.0, floor_y - 60.0, STORY.y - STORY.x + 60.0, 60.0))
	var ch := Decor.HiveChamber.new()
	ch.w = STORY.y - STORY.x
	ch.cx = STORY_ACTOR - STORY.x
	add_world(ch, Vector2(STORY.x, floor_y))
	story_pool = Decor.MemoryPool.new()
	story_pool.big = true
	add_world(story_pool, Vector2(STORY_ACTOR, floor_y))
	# בריכות זיכרון
	for p in POOLS:
		var mp := Decor.MemoryPool.new()
		mp.memory = int(p[1])
		add_world(mp, Vector2(float(p[0]), floor_y))
		pools.append(mp)
		reserve(Rect2(float(p[0]) - 100.0, floor_y - 40.0, 200.0, 40.0))
	# עמודי בשר
	for i in PILLARS.size():
		var pl := Decor.Pillar.new()
		pl.seed_v = i * 7 + 3
		add_world(pl, Vector2(float(PILLARS[i]), floor_y))
	# מלכודות: קשרי עצב וסוגרי בשר
	for i in GANGLIA.size():
		var gg := Decor.Ganglion.new()
		gg.seed_v = i * 11 + 5
		add_world(gg, Vector2(float(GANGLIA[i]), floor_y))
		reserve(Rect2(float(GANGLIA[i]) - 50.0, floor_y - 40.0, 100.0, 40.0))
	for mx in MAWS:
		add_world(Decor.Maw.new(), Vector2(float(mx), floor_y))
		reserve(Rect2(float(mx) - 70.0, floor_y - 40.0, 170.0, 40.0))
	# פטריות מדף (קומה) + אספקה למעלה
	var loot := [PickupScript.AMMO, PickupScript.HEALTH, PickupScript.GRENADE, PickupScript.AMMO]
	for i in SHELVES.size():
		_shelf(SHELVES[i])
		var s: Array = SHELVES[i]
		_pickup(loot[i % loot.size()], Vector2(float(s[0]) + float(s[1]) * 0.5, floor_y - float(s[2]) - 30.0))
	# מכשולים קבועים (מחסה)
	for o in OBST:
		var ob := Decor.Obstacle.new()
		ob.kind = String(o[1])
		ob.size = o[2]
		ob.seed_v = rng.randi()
		add_world(ob, Vector2(float(o[0]), floor_y))
		reserve(Rect2(float(o[0]), floor_y - (o[2] as Vector2).y, (o[2] as Vector2).x, (o[2] as Vector2).y))
	# זירת THE FLOOD: אגן + קיר הלב + הפיר. שתי פטריות מדף לברוח מהגל
	var ar := Decor.FloodArena.new()
	ar.w = level_w - ARENA_X
	add_world(ar, Vector2(ARENA_X, floor_y))
	reserve(Rect2(ARENA_X, floor_y - 40.0, level_w - ARENA_X, 40.0))
	for s in ARENA_SHELVES:
		_shelf(s)
	_pickup(PickupScript.HEALTH, Vector2(ARENA_X - 130.0, floor_y - 30.0))
	_pickup(PickupScript.AMMO, Vector2(ARENA_X - 70.0, floor_y - 30.0))


func _shelf(s: Array) -> void:
	var sh := Decor.Shelf.new()
	sh.w = float(s[1])
	sh.tier = float(s[2])
	sh.seed_v = rng.randi() % 1000
	add_world(sh, Vector2(float(s[0]), floor_y))
	var pf = add_floor(float(s[0]), floor_y - float(s[2]), float(s[1]), "concrete", false, false)
	pf.visible = false
	reserve(Rect2(float(s[0]) + float(s[1]) * 0.3, floor_y - 40.0, float(s[1]) * 0.4, 40.0))


func _pickup(kind: int, pos: Vector2) -> void:
	var p = PickupScript.new()
	p.kind = kind
	p.life = 100000.0
	main.add_child(p)
	p.setup(pos, Vector2.ZERO)


func build_effects() -> void:
	fx = Decor.HiveFX.new()
	fx.vp = vp
	screen_layer.add_child(fx)


# SEEPER הולכים + שלוליות שמחכות. SYNAPSE ו-REMNANT נוצרים כשמתקרבים (_physics_process).
func extra_spawns() -> void:
	for s in SEEPERS:
		var z = spawn(Registry.SEEPER, float(s[0]))
		if z != null and z.type_mod != null and bool(s[1]):
			z.type_mod.start_puddle(true)
	for sh in SHELVES:   # אחד על כל פטריית מדף שנייה
		if int(float(sh[0])) % 2 == 0:
			spawn(0, float(sh[0]) + float(sh[1]) * 0.6, floor_y - float(sh[2]))
	spawn(0, ARENA_X + 240.0)
	spawn(1, ARENA_X + 330.0)


# שורות הגיבור בתור (לא אחת על השנייה): לפחות SAY_GAP שניות בין שורה לשורה
func _say(_pl: Node2D, text: String, c: Color) -> void:
	_say_q.append([text, c])


func _say_tick(pl: Node2D) -> void:
	if _say_q.is_empty() or _say_cd > 0.0:
		return
	var e: Array = _say_q.pop_front()
	_say_cd = SAY_GAP
	pl._say(String(e[0]), e[1])


func _player() -> Node2D:
	return get_tree().get_first_node_in_group("player") as Node2D


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
	_say_cd -= delta
	# הלב: הולם חזק יותר ככל שמתקרבים לזירה
	Decor.U.heart = clampf((px - 7600.0) / 1600.0, 0.0, 1.0)
	if Decor.U.heart > 0.05:
		_heart_t -= delta
		if _heart_t <= 0.0:
			_heart_t = 60.0 / 52.0
			Sfx.play("s62_heart", null, -18.0 + 10.0 * Decor.U.heart, 0.0, 1)
	if Engine.get_physics_frames() % 10 != 0:
		return
	_drone_t -= 10.0 / 60.0
	if _drone_t <= 0.0:
		_drone_t = randf_range(10.0, 18.0)
		Sfx.play("s62_drone", null, -12.0, 0.1, 1)
	_pools_tick(pl)
	_syn_tick(pl)
	_hints(pl)
	_lines(pl)
	_boss_tick(pl)
	_say_tick(pl)
	if _post_story == 1 and get_tree().get_first_node_in_group("story_scene") == null:
		_after_story(pl)


# בריכות זיכרון: מתקרבים -> הזיכרון עולה (אחרי שלמדו - זוג)
func _pools_tick(pl: Node2D) -> void:
	var px: float = pl.global_position.x
	for i in pools.size():
		if _pools_done.has(i):
			continue
		var p: Node2D = pools[i]
		if absf(p.global_position.x - px) > POOL_R:
			continue
		_pools_done[i] = true
		var n := 2 if int(main.get_meta("rmn_kills", 0)) >= 4 else 1
		_release(p, int(p.memory), n)


func _release(p: Node2D, mem: int, n: int) -> void:
	p.rise()
	for k in n:
		var x: float = p.global_position.x + (0.0 if k == 0 else 44.0)
		var z = spawn(Registry.REMNANT, x)
		if z == null or z.type_mod == null:
			continue
		z.type_mod.set_memory(mem if k == 0 else (mem + 2) % 4, true)
		_remnant_n += 1


# קבוצות SYNAPSE נוצרות כשמתקרבים (כך שקבוצה מאוחרת כבר יודעת מה למדו)
func _syn_tick(pl: Node2D) -> void:
	var px: float = pl.global_position.x
	for i in SYN_GROUPS.size():
		if _syn_done.has(i):
			continue
		var gx: float = SYN_GROUPS[i][0]
		if px < gx - 1000.0:
			continue
		_syn_done[i] = true
		if px > gx + 500.0:   # (התחיל מנקודת ביקורת) - לא מאחור
			continue
		SynT.make_group(main, gx, floor_y, int(SYN_GROUPS[i][1]))
		_syn_n += 1


# intro: פעם אחת לכל סוג חדש, כשהוא על המסך - מה הם למדו, ומאיפה
func _hints(pl: Node2D) -> void:
	if _seen.size() >= 3:
		return
	for z in get_tree().get_nodes_in_group("zombies"):
		if z.dead or z.type_mod == null or z.is_boss():
			continue
		var k: int = z.kind
		if _seen.has(k) or not (k == Registry.SEEPER or k == Registry.SYNAPSE or k == Registry.REMNANT):
			continue
		if absf(z.global_position.x - pl.global_position.x) > 600.0 or not Art.on_screen(z, z.global_position, -40.0):
			continue
		if k == Registry.SEEPER and z.type_mod.lurk:
			continue
		_seen[k] = true
		if k == Registry.SEEPER:
			z._popup("THEY MELT NOW", Color("b8ff7a"), 15, -80.0)
			_say(pl, "They learned a body can be shot... a puddle can't. Hit the glowing CORE!", Color("c8ff9a"))
		elif k == Registry.SYNAPSE:
			z._popup("THEY LINK NOW", Color("a8f0ff"), 15, -60.0)
			_say(pl, "They learned I dodge. So they made a wall. Shoot ONE knot - the link breaks!", Color("a8f0ff"))
		else:
			z._popup("THEY REMEMBER YOUR FIGHTS NOW", Color("a8f0ff"), 15, -90.0)
			_say(pl, "I killed that one years ago. They kept the memory - and the trick.", Color("a8f0ff"))
		return


func _lines(pl: Node2D) -> void:
	var px: float = pl.global_position.x
	for i in LINES.size():
		if _lines_done.has(i) or px < float(LINES[i][0]):
			continue
		_lines_done[i] = true
		if px > float(LINES[i][0]) + 900.0:
			continue
		_say(pl, str(LINES[i][1]), Color(str(LINES[i][2])))


# הזירה: שורה כשהבוס מופיע, ושורה אחרי שהוא מת (הלב למטה)
func _boss_tick(pl: Node2D) -> void:
	if _boss_said >= 2:
		return
	if _boss == null or not is_instance_valid(_boss):
		_boss = null
		for z in get_tree().get_nodes_in_group("zombies"):
			if z.is_boss():
				_boss = z
				break
	if _boss_said == 0 and _boss != null and not _boss.dead and pl.global_position.x > ARENA_X + 120.0:
		_boss_said = 1
		_text("THE FLOOD", Color("b8ff7a"), pl.global_position + Vector2(0, -150), 24)
		_say(pl, "All of them... melted into ONE. Find the core!", Color("c8ff9a"))
	elif _boss_said == 1 and (_boss == null or _boss.dead):
		_boss_said = 2
		Decor.U.heart = 1.0
		_say(pl, "The heart is down there. I can hear it beating.", Color("ffb0a0"))


# ============================================================
#  קטע סיפור
# ============================================================
# x של הקטע הנקי: STORY (4500..5940) - חדר הקול האחד. ה-SEEPER של הסצנה בבריכה הגדולה (STORY_ACTOR).
func story_stretch() -> Vector2:
	return STORY


# "speak" - הכוורת מדברת (הקיר והחוטים פועמים), "replay" - כל הבריכות מבזיקות את הקרבות שלך,
# "mirror" - הפנים בקיר (וגם של הדובר) נהיים הפנים שלך, "melt" - הדובר נמס לבריכה
func on_story_beat(id: String) -> void:
	match id:
		"speak":
			Decor.U.voice_ms = Time.get_ticks_msec()
			_post_story = maxi(_post_story, 1)
		"replay":
			Decor.U.voice_ms = Time.get_ticks_msec()
			Decor.U.replay_ms = Time.get_ticks_msec()
			Sfx.play("s62_replay", null, -2.0, 0.0, 1)
		"mirror":
			Decor.U.voice_ms = Time.get_ticks_msec()
			Decor.U.face_ms = Time.get_ticks_msec()
			Sfx.play("s62_drone", null, -4.0, 0.0, 1)
		"melt":
			Decor.U.voice_ms = Time.get_ticks_msec()
			var a := _actor()
			if a != null and a.type_mod != null:
				create_tween().tween_property(a.type_mod, "scene_melt", 1.0, 2.2)
				Sfx.play("sep_melt", a.global_position, 0.0, 0.0, 1)
	_post_story = maxi(_post_story, 1)


# הדובר של הסצנה: SEEPER שלא בקבוצת zombies (story_trigger מוציא אותו)
func _actor() -> Node:
	for n in main.get_children():
		if n is CharacterBody2D and "type_mod" in n and n.type_mod != null and n.kind == Registry.SEEPER and not n.is_in_group("zombies") and not n.dead:
			return n
	return null


# אחרי הסצנה: הבריכה הגדולה עונה - שני זיכרונות עולים ממנה
func _after_story(pl: Node2D) -> void:
	_post_story = 2
	Decor.U.voice_ms = -1
	if story_pool != null:
		_release(story_pool, 0, 1)
		var z = spawn(Registry.REMNANT, STORY_ACTOR + 60.0)
		if z != null and z.type_mod != null:
			z.type_mod.set_memory(3, true)
			_remnant_n += 1
	_say(pl, "Teacher. That's what I am to them.", Color("c8ffb0"))
