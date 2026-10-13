extends "res://levels/stage_base.gd"
# ============================================================
#  STAGE 41 - "THE PARADE" (אזור חמישי - דרום-מזרח, שלב 5) - "THEY LEARNED TO MARCH"
#  (הסיפור: מנמל סנטוס הגיבור עוקב אחרי טורי הטנקים צפונה - עד ברזיליה. הבירה כבר שלהם: כל הצבא צועד במצעד ניצחון
#   מול המרשל של אימפריית המתים, על יציע הכבוד בשדרה המרכזית. הקונגרס עטוף בדגלים אדומים עם הנחש העתיק.)
#  ברזיליה בדמדומים (effects/s41_decor.gd): הקונגרס עם הכרזות, הקתדרלה, זרקורים, זיקוקי הצדעה, טורי חיילים.
#  קומה שנייה: יציעי כבוד (STANDS).
#  מלכודות: TankColumn - טור טנקים חוצה את השדרה (אזהרה: אורות אדומים + רעם). עלו על היציע! חיילי האימפריה יוצאים מהנתיב.
#           SaluteGun - תותח הצדעה: פתיל בוער -> גל הדף שזורק ומסחרר.
#  זומבים: DRUMMER (קצב = מהירות, תיפוף הסתערות כשאתה טוען), GUARDSMAN (מתחלפים כשנפצעים, לומדים את ההתחמקות מהכידון),
#          PROPAGANDIST (SURRENDER! מסחרר, מסגיר אותך כשאתה מתחבא), CONSCRIPT, OFFICER, REVIVER, רגילים, רצים.
#  בוס נייח: THE MARSHAL (enemies/types/marshal.gd) - על יציע הכבוד מאחורי זכוכית משוריינת: מטחי ארטילריה שלומדים.
#  לשנות: STANDS, TIER, TANKS, GUNS, SQUADS, BOSS_TIER, zombie_weights().
# ============================================================

const Decor := preload("res://effects/s41_decor.gd")
const PickupScript := preload("res://pickup.gd")

const SOUNDS := {
	"pa_rumble": {"drive": 1.6, "layers": [["S", 45, 38, 0.0, 2.0, 0.4, 0.8, 0.9, 1.0, 0.04], ["N", 0, 0, 0.0, 2.0, 0.4, 0.8, 0.5, 0.08, 0]]},
	"pa_fuse": [["N", 0, 0, 0.0, 1.1, 0.0, 1.0, 0.25, 0.9, 0, 0.8]],
	"pa_salute": {"drive": 1.8, "layers": [["N", 0, 0, 0.0, 0.8, 0.0, 5.0, 1.0, 0.15, 0], ["S", 60, 30, 0.0, 0.5, 0.0, 6.0, 0.8, 1.0, 0]]},
}

const STANDS := [[0.2, 300.0], [0.47, 320.0], [0.73, 300.0]]
const TIER := 130.0
const TANK_W := 900.0
const GUNS := [0.1, 0.36, 0.62, 0.87]
const SQUADS := [0.12, 0.3, 0.55, 0.8]
const BOSS_TIER := 130.0
const HARDER := [1.0, 1.15, 1.3]

var _stands := []


func zombie_weights() -> Dictionary:
	return {Registry.CONSCRIPT: 0.1, Registry.GUARDSMAN: 0.05, Registry.DRUMMER: 0.02, Registry.PROPAGANDIST: 0.02, Registry.OFFICER: 0.01,
		Registry.REVIVER: 0.02, 0: 0.45, 1: 0.33}


func zombie_density() -> float:
	return 1.0 * float(HARDER[clampi(Settings.difficulty, 0, 2)])


func generators() -> Array:
	return [["crowd_barrier", 1.0], ["planter", 0.8], ["drum_stack", 0.6]]


func custom_gen(gname: String, x: float) -> float:
	if not gname in ["crowd_barrier", "planter", "drum_stack"]:
		return 0.0
	var o := Decor.Obstacle.new()
	o.kind = gname
	o.seed_v = rng.randi()
	match gname:
		"crowd_barrier":
			o.size = Vector2(rng.randf_range(80.0, 100.0), rng.randf_range(32.0, 36.0))
		"planter":
			o.size = Vector2(rng.randf_range(60.0, 76.0), rng.randf_range(40.0, 46.0))
		_:
			o.size = Vector2(rng.randf_range(50.0, 60.0), rng.randf_range(34.0, 40.0))
	o.position = Vector2(x, floor_y)
	main.add_child(o)
	reserve(Rect2(x, floor_y - o.size.y, o.size.x, o.size.y))
	return o.size.x


func boss_kind() -> int:
	return Registry.MARSHAL


func music() -> String:
	return "res://music/level1_total_war.mp3"


func world_tint() -> Color:
	return Color(1.0, 0.92, 0.9)


func fog() -> bool:
	return false


func pits() -> int:
	return 0


func build_background(layer: CanvasLayer) -> Node:
	var bg = Backdrop.new()
	bg.level_w = level_w
	bg.sky = func(ci: CanvasItem, v: Vector2, t: float):
		Decor.capital_sky(ci, v, t)
	bg.add_layer(0.05, func(ci: CanvasItem, sc: float, v: Vector2, t: float):
		Decor.far_capital(ci, sc, v, 560.0, t))
	bg.add_layer(0.25, func(ci: CanvasItem, sc: float, v: Vector2, t: float):
		Decor.mid_ministries(ci, sc, v, 622.0, t))
	bg.add_layer(0.6, func(ci: CanvasItem, sc: float, v: Vector2, t: float):
		Decor.near_posts(ci, sc, v, 645.0, t))
	layer.add_child(bg)
	return bg


func build_world() -> void:
	var x := 0.0
	while x < level_w:
		var g := Decor.AvenueGround.new()
		g.w = minf(1024.0, level_w - x)
		g.depth = main.floor_thickness
		add_world(g, Vector2(x, floor_y))
		x += 1024.0
	for s in STANDS:   # יציעי כבוד: קומה + סולם. טור טנקים חוצה את השדרה סביב כל יציע - עולים למעלה!
		var w: float = s[1]
		var dx := level_w * float(s[0])
		var st := Decor.ReviewStand.new()
		st.w = w
		st.tier = TIER
		add_world(st, Vector2(dx, floor_y))
		var pf = add_floor(dx - 8.0, floor_y - TIER, w + 16.0, "concrete", false, false)
		pf.visible = false
		add_ladder(dx + 6.0, floor_y - TIER)
		add_ladder(dx + w - 30.0, floor_y - TIER)
		reserve(Rect2(dx - 10.0, floor_y - TIER, w + 20.0, TIER))
		_stands.append([dx, dx + w])
		_pickup(PickupScript.AMMO if s[0] < 0.5 else PickupScript.HEALTH, Vector2(dx + w * 0.5, floor_y - TIER - 30.0))
		var tc := Decor.TankColumn.new()
		tc.w = TANK_W
		var lx := dx + w * 0.5 - TANK_W * 0.5
		add_world(tc, Vector2(lx, floor_y))
		reserve(Rect2(lx - 140.0, floor_y - 60.0, 200.0, 60.0))   # יציאות הנתיב פנויות (לשם החיילים בורחים)
		reserve(Rect2(lx + TANK_W - 60.0, floor_y - 60.0, 200.0, 60.0))
	for f in GUNS:   # תותחי הצדעה
		var gx := level_w * float(f)
		var sg := Decor.SaluteGun.new()
		add_world(sg, Vector2(gx, floor_y))
		reserve(Rect2(gx - 40.0, floor_y - 50.0, 100.0, 50.0))
	# יציע המרשל
	var bx := level_w - 720.0
	var rs := Decor.ReviewStand.new()
	rs.w = 420.0
	rs.tier = BOSS_TIER
	add_world(rs, Vector2(bx - 230.0, floor_y))
	var bf = add_floor(bx - 236.0, floor_y - BOSS_TIER, 432.0, "concrete", false, false)
	bf.visible = false
	add_ladder(bx - 222.0, floor_y - BOSS_TIER)
	add_ladder(bx + 160.0, floor_y - BOSS_TIER)
	reserve(Rect2(bx - 240.0, floor_y - BOSS_TIER, 440.0, BOSS_TIER))
	main.set_meta("boss_x", bx)
	main.set_meta("boss_y", floor_y - BOSS_TIER)
	main.set_meta("boss_ground_y", floor_y)


func _pickup(kind: int, pos: Vector2) -> void:
	var p = PickupScript.new()
	p.kind = kind
	p.life = 100000.0
	main.add_child(p)
	p.setup(pos, Vector2.ZERO)


func build_effects() -> void:
	var fx := Decor.ParadeFX.new()
	fx.vp = vp
	fx.floor_y = floor_y
	screen_layer.add_child(fx)


# פלוגות מצעד: 2 שומרים מלפנים, 2 רובאים, מתופף באמצע, תעמולן / קצין מאחור. על היציעים - רובאי + שומר
func extra_spawns() -> void:
	for i in SQUADS.size():
		var sx := level_w * float(SQUADS[i])
		spawn(Registry.GUARDSMAN, sx)
		spawn(Registry.GUARDSMAN, sx + 45.0)
		spawn(Registry.CONSCRIPT, sx + 110.0)
		spawn(Registry.CONSCRIPT, sx + 150.0)
		spawn(Registry.DRUMMER, sx + 230.0)
		spawn(Registry.PROPAGANDIST if i % 2 == 0 else Registry.OFFICER, sx + 360.0)
	for s in _stands:
		spawn(Registry.CONSCRIPT, lerpf(float(s[0]), float(s[1]), 0.4), floor_y - TIER)
		spawn(Registry.GUARDSMAN, lerpf(float(s[0]), float(s[1]), 0.7), floor_y - TIER)
