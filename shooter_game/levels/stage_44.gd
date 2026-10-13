extends "res://levels/stage_base.gd"
# ============================================================
#  STAGE 44 - "THE DAM" (אזור חמישי - דרום-מזרח, שלב 8) - "THEY LEARNED THE SKY"
#  (הסיפור: הטנקים יצאו ממפעל המלחמה מערבה - לסכר איטאיפו על נהר הפרנה. תחנת הכוח הגדולה ביבשת מזינה עכשיו את מכונת
#   המלחמה של האימפריה. מטוסי תובלה מצניחים חיילים, ומעל סוף הסכר מרחפת ספינת האוויר האדומה.)
#  (effects/s44_decor.gd): עמק הפרנה עם קווי מתח, חזית הסכר עם תומכות וצינורות לחץ, ערוץ שפך עם מים לבנים, דרך הכתר.
#  קומה שנייה: עגורני שער (GANTRIES). עגורן ליד הבוס - משם יורים בגונדולה.
#  מלכודות: Surge - שערי השפך נפתחים וגל שוטף קטע של הכתר (עלו על העגורן!), Transformer - שנאים שפורקים קשת חשמל.
#  DropZone - מטוס עובר: PARATROOPER נוחתים מאחוריך.
#  זומבים: PARATROOPER, MORTARMAN, STORMTROOPER, CONSCRIPT, OFFICER, REVIVER, רגילים, רצים.
#  בוס מרחף: RED ZEPPELIN (enemies/types/red_zeppelin.gd) - שטיחי פצצות שלומדים לאן אתה בורח, מקלע, צנחנים.
#  לשנות: GANTRIES, TIER, SURGE_W, POWER, DROPS, SQUADS, BOSS_ALT, zombie_weights().
# ============================================================

const Decor := preload("res://effects/s44_decor.gd")
const PickupScript := preload("res://pickup.gd")

const SOUNDS := {
	"dm_siren": {"drive": 1.4, "layers": [["S", 500, 800, 0.0, 1.0, 0.1, 1.0, 0.3, 1.0, 0.02], ["S", 800, 500, 1.0, 1.0, 0.1, 1.0, 0.3, 1.0, 0.02]]},
	"dm_wave": [["N", 0, 0, 0.0, 1.6, 0.1, 1.0, 0.8, 0.25, 0, 0.8]],
	"dm_hum": [["S", 100, 100, 0.0, 1.3, 0.2, 1.0, 0.2, 1.0, 0.0], ["S", 200, 200, 0.0, 1.3, 0.2, 1.0, 0.1, 1.0, 0.0]],
	"dm_zap": [["N", 0, 0, 0.0, 0.25, 0.0, 15.0, 0.7, 0.95, 0, 0.9], ["S", 1800, 400, 0.0, 0.2, 0.0, 15.0, 0.2, 1.0, 0.3]],
	"dm_plane": [["S", 90, 80, 0.0, 2.5, 0.5, 0.6, 0.3, 1.0, 0.05], ["N", 0, 0, 0.0, 2.5, 0.5, 0.6, 0.15, 0.2, 0, 0.6]],
}

const GANTRIES := [[0.2, 300.0], [0.47, 320.0], [0.73, 300.0]]
const TIER := 160.0
const SURGE_W := 640.0
const POWER := [0.1, 0.36, 0.6, 0.86]
const DROPS := [0.27, 0.55, 0.8]
const SQUADS := [0.14, 0.4, 0.66, 0.9]
const BOSS_ALT := 250.0
const HARDER := [1.0, 1.15, 1.3]

var _gants := []


func zombie_weights() -> Dictionary:
	return {Registry.CONSCRIPT: 0.08, Registry.STORMTROOPER: 0.03, Registry.MORTARMAN: 0.015, Registry.PARATROOPER: 0.02,
		Registry.OFFICER: 0.01, Registry.REVIVER: 0.01, 0: 0.5, 1: 0.33}


func zombie_density() -> float:
	return 1.0 * float(HARDER[clampi(Settings.difficulty, 0, 2)])


func generators() -> Array:
	return [["jersey", 1.0], ["cable_drum", 0.8], ["valve", 0.5]]


func custom_gen(gname: String, x: float) -> float:
	if not gname in ["jersey", "cable_drum", "valve"]:
		return 0.0
	var o := Decor.Obstacle.new()
	o.kind = gname
	o.seed_v = rng.randi()
	match gname:
		"jersey":
			o.size = Vector2(rng.randf_range(76.0, 90.0), rng.randf_range(34.0, 38.0))
		"cable_drum":
			o.size = Vector2(rng.randf_range(48.0, 56.0), rng.randf_range(48.0, 56.0))
		_:
			o.size = Vector2(rng.randf_range(44.0, 50.0), rng.randf_range(40.0, 46.0))
	o.position = Vector2(x, floor_y)
	main.add_child(o)
	reserve(Rect2(x, floor_y - o.size.y, o.size.x, o.size.y))
	return o.size.x


func boss_kind() -> int:
	return Registry.RED_ZEPPELIN


func music() -> String:
	return "res://music/level1_total_war.mp3"


func world_tint() -> Color:
	return Color(0.95, 0.98, 1.0)


func fog() -> bool:
	return false


func pits() -> int:
	return 0


func street_props() -> bool:
	return false


func build_background(layer: CanvasLayer) -> Node:
	var bg = Backdrop.new()
	bg.level_w = level_w
	bg.sky = func(ci: CanvasItem, v: Vector2, t: float):
		Decor.dam_sky(ci, v, t)
	bg.add_layer(0.05, func(ci: CanvasItem, sc: float, v: Vector2, t: float):
		Decor.far_river(ci, sc, v, 560.0, t))
	bg.add_layer(0.25, func(ci: CanvasItem, sc: float, v: Vector2, t: float):
		Decor.mid_dam(ci, sc, v, 622.0, t))
	bg.add_layer(0.6, func(ci: CanvasItem, sc: float, v: Vector2, t: float):
		Decor.near_parapet(ci, sc, v, 645.0, t))
	layer.add_child(bg)
	return bg


func _gantry(dx: float, w: float) -> void:
	var g := Decor.Gantry.new()
	g.w = w
	g.tier = TIER
	add_world(g, Vector2(dx, floor_y))
	var pf = add_floor(dx - 10.0, floor_y - TIER, w + 20.0, "steel", false, false)
	pf.visible = false
	add_ladder(dx + 20.0, floor_y - TIER)
	add_ladder(dx + w - 44.0, floor_y - TIER)
	reserve(Rect2(dx - 10.0, floor_y - 40.0, w + 20.0, 40.0))


func build_world() -> void:
	var x := 0.0
	while x < level_w:
		var g := Decor.CrestGround.new()
		g.w = minf(1024.0, level_w - x)
		g.depth = main.floor_thickness
		add_world(g, Vector2(x, floor_y))
		x += 1024.0
	for i in GANTRIES.size():   # עגורני שער + קטע שפך סביב כל אחד
		var gw: float = GANTRIES[i][1]
		var dx := level_w * float(GANTRIES[i][0])
		_gantry(dx, gw)
		_gants.append([dx, dx + gw])
		_pickup(PickupScript.AMMO if i < 2 else PickupScript.HEALTH, Vector2(dx + gw * 0.5, floor_y - TIER - 30.0))
		var sg := Decor.Surge.new()
		sg.w = SURGE_W
		sg.dir = 1.0 if i % 2 == 0 else -1.0
		add_world(sg, Vector2(dx + gw * 0.5 - SURGE_W * 0.5, floor_y))
	for f in POWER:   # שנאים
		var px := level_w * float(f)
		var tr := Decor.Transformer.new()
		add_world(tr, Vector2(px, floor_y))
		reserve(Rect2(px - 40.0, floor_y - 60.0, 80.0, 60.0))
	for f in DROPS:   # נקודות הצנחה
		var dz := Decor.DropZone.new()
		add_world(dz, Vector2(level_w * float(f), floor_y))
	# עגורן ליד ספינת האוויר - משם יורים בגונדולה
	var bx := level_w - 720.0
	_gantry(bx - 420.0, 300.0)
	reserve(Rect2(bx - 450.0, floor_y - 60.0, 700.0, 60.0))
	main.set_meta("boss_x", bx)
	main.set_meta("boss_y", floor_y - BOSS_ALT)
	main.set_meta("boss_ground_y", floor_y)


func _pickup(kind: int, pos: Vector2) -> void:
	var p = PickupScript.new()
	p.kind = kind
	p.life = 100000.0
	main.add_child(p)
	p.setup(pos, Vector2.ZERO)


func build_effects() -> void:
	var fx := Decor.DamFX.new()
	fx.vp = vp
	screen_layer.add_child(fx)


# יחידות: חייל סער מלפנים, 2 רובאים, צנחן, צוות מרגמה מאחור (או קצין). על העגורנים - רובאי
func extra_spawns() -> void:
	for i in SQUADS.size():
		var sx := level_w * float(SQUADS[i])
		spawn(Registry.STORMTROOPER, sx)
		spawn(Registry.CONSCRIPT, sx + 70.0)
		spawn(Registry.CONSCRIPT, sx + 110.0)
		spawn(Registry.PARATROOPER, sx + 160.0)
		spawn(Registry.MORTARMAN if i % 2 == 0 else Registry.OFFICER, sx + 480.0)
	for g in _gants:
		spawn(Registry.CONSCRIPT, lerpf(float(g[0]), float(g[1]), 0.5), floor_y - TIER)
