extends "res://levels/stage_base.gd"
# ============================================================
#  STAGE 47 - "PAMPAS STORM" (אזור שישי - החרוט הדרומי, שלב 2) - "THEY LEARNED TO WRESTLE"
#  (הסיפור: מעמק היין הגיבור יורד לפמפס הארגנטינית. אסטנסיה ענקית בלב המישור, וסופת רעמים שלא נגמרת.
#   הבוקרים (גאוצ'וס) המתים עוד עובדים: מפילים בבולאדורס, מסתערים כמו פרים - וזורקים אותך.)
#  (effects/s47_decor.gd): שמיים ירוקים-אפורים, תאי סערה באופק השטוח, בית האסטנסיה, עצי אומבו, טחנות רוח, עשב פמפס.
#  קומה שנייה: עליית השחת במחסני הפח (GALPONS - בטוחה מברקים) ובמות טחנות הרוח (WINDMILLS - לא בטוחות בסערה!).
#  מלכודות: Windmill - בכל ברק גדול הברק פוגע בטחנה הקרובה: הבמה והעיגול סביב הבסיס מחושמלים (אזהרה: אש אלמו כחולה).
#           Stampede - עדר פרות מתות דוהר לרוחב הכביש (STAMPEDES) - לעלות על מכשול / קומה. Mud - בוץ מאט (MUD).
#  זומבים: TORO (מסתער, תופס וזורק אותך), BOLEADOR (בולאדורס שכורכות לך את הרגליים), STORMCALLER (נועץ מוטות ברק לידך),
#          רגילים, רצים.
#  בוס: EL TORO (enemies/types/toro.gd, מצב בוס) - במכלאה בסוף.
#  לשנות: GALPONS, WINDMILLS, TIER, MILL_TIER, STAMPEDES, MUD, zombie_weights().
# ============================================================

const Decor := preload("res://effects/s47_decor.gd")
const PickupScript := preload("res://pickup.gd")

const SOUNDS := {
	"pm_zap": [["Q", 70, 60, 0.0, 0.35, 0.0, 6.0, 0.35, 0.6, 0], ["C", 0, 0, 0.0, 0.35, 0.0, 5.0, 0.9, 1.0, 0], ["S", 3800, 3000, 0.0, 0.2, 0.0, 14.0, 0.12, 1.0, 0], ["N", 0, 0, 0.0, 0.05, 0.0, 70.0, 0.8, 0.8, 0]],
	"pm_rumble": {"rev": 0.3, "layers": [["N", 0, 0, 0.0, 2.2, 0.4, 1.0, 0.9, 0.05, 0], ["S", 48, 40, 0.0, 2.2, 0.4, 1.0, 0.6, 1.0, 0.1], ["C", 0, 0, 0.0, 2.0, 0.3, 1.2, 0.3, 0.2, 0]]},
}

const GALPONS := [[0.18, 360.0], [0.47, 380.0], [0.74, 360.0]]   # [מיקום יחסי, רוחב]
const TIER := 150.0
const WINDMILLS := [0.09, 0.32, 0.6, 0.86]
const MILL_TIER := 170.0
const STAMPEDES := [0.27, 0.55, 0.81]
const MUD := [0.13, 0.38, 0.52, 0.67, 0.92]
const HARDER := [1.0, 1.15, 1.3]

var _lofts := []
var _mills := []


func zombie_weights() -> Dictionary:
	return {Registry.BOLEADOR: 0.08, Registry.STORMCALLER: 0.05, Registry.TORO: 0.025, 0: 0.5, 1: 0.33}


func zombie_density() -> float:
	return 1.0 * float(HARDER[clampi(Settings.difficulty, 0, 2)])


func generators() -> Array:
	return [["bale", 1.4], ["trough", 0.9], ["carreta", 0.6]]


func custom_gen(gname: String, x: float) -> float:
	if not gname in ["bale", "trough", "carreta"]:
		return 0.0
	var o := Decor.Obstacle.new()
	o.kind = gname
	o.seed_v = rng.randi()
	match gname:
		"bale":
			var d := rng.randf_range(50.0, 62.0)
			o.size = Vector2(d, d)
		"trough":
			o.size = Vector2(rng.randf_range(80.0, 100.0), rng.randf_range(36.0, 42.0))
		_:
			o.size = Vector2(rng.randf_range(90.0, 110.0), rng.randf_range(72.0, 82.0))
	o.position = Vector2(x, floor_y)
	main.add_child(o)
	reserve(Rect2(x, floor_y - o.size.y, o.size.x, o.size.y))
	return o.size.x


func boss_kind() -> int:
	return Registry.TORO


func music() -> String:
	return "res://music/level1_total_war.mp3"


func world_tint() -> Color:
	return Color(0.82, 0.9, 0.92)


func fog() -> bool:
	return false


func pits() -> int:
	return 0


func build_background(layer: CanvasLayer) -> Node:
	var bg = Backdrop.new()
	bg.level_w = level_w
	bg.sky = func(ci: CanvasItem, v: Vector2, t: float):
		Decor.pampa_sky(ci, v, t)
	bg.add_layer(0.06, func(ci: CanvasItem, sc: float, v: Vector2, t: float):
		Decor.far_horizon(ci, sc, v, 548.0, t))
	bg.add_layer(0.28, func(ci: CanvasItem, sc: float, v: Vector2, t: float):
		Decor.mid_estancia(ci, sc, v, 616.0, t))
	bg.add_layer(0.62, func(ci: CanvasItem, sc: float, v: Vector2, t: float):
		Decor.near_grass(ci, sc, v, 640.0, t))
	layer.add_child(bg)
	return bg


func build_world() -> void:
	var x := 0.0
	while x < level_w:
		var g := Decor.PampaGround.new()
		g.w = minf(1024.0, level_w - x)
		g.depth = main.floor_thickness
		g.seed_v = rng.randi()
		add_world(g, Vector2(x, floor_y))
		x += 1024.0
	for gp in GALPONS:   # מחסני פח עם עליית שחת
		var gx := level_w * float(gp[0])
		var w: float = gp[1]
		var gl := Decor.Galpon.new()
		gl.w = w
		gl.tier = TIER
		add_world(gl, Vector2(gx, floor_y))
		var pf = add_floor(gx - 4.0, floor_y - TIER, w + 8.0, "concrete", false, false)
		pf.visible = false
		add_ladder(gx + 26.0, floor_y - TIER)
		add_ladder(gx + w - 50.0, floor_y - TIER)
		reserve(Rect2(gx, floor_y - 40.0, w, 40.0))
		_lofts.append([gx, gx + w])
		_pickup(PickupScript.AMMO if gp[0] < 0.6 else PickupScript.HEALTH, Vector2(gx + w * 0.5, floor_y - TIER - 30.0))
	for f in WINDMILLS:   # טחנות רוח (במה = קומה קטנה, מלכודת ברק)
		var mx := level_w * float(f)
		while not free_x(mx, 120.0) and mx < level_w - 400.0:
			mx += 60.0
		var wm := Decor.Windmill.new()
		wm.tier = MILL_TIER
		add_world(wm, Vector2(mx, floor_y))
		var mf = add_floor(mx - wm.plat_w * 0.5, floor_y - MILL_TIER, wm.plat_w, "concrete", false, false)
		mf.visible = false
		add_ladder(mx - 14.0, floor_y - MILL_TIER)
		reserve(Rect2(mx - 60.0, floor_y - 40.0, 160.0, 40.0))
		_mills.append(mx)
		_pickup(PickupScript.AMMO, Vector2(mx + 20.0, floor_y - MILL_TIER - 30.0))
	for f in STAMPEDES:
		var sp := Decor.Stampede.new()
		sp.floor_y = floor_y
		add_world(sp, Vector2(level_w * float(f), floor_y))
	for f in MUD:
		var mx2 := level_w * float(f)
		if not free_x(mx2, 90.0):
			continue
		var md := Decor.Mud.new()
		md.w = rng.randf_range(130.0, 190.0)
		add_world(md, Vector2(mx2, floor_y))
	# המכלאה של EL TORO
	var cx := level_w - 1100.0
	var co := Decor.Corral.new()
	co.w = 820.0
	add_world(co, Vector2(cx, floor_y))
	_pickup(PickupScript.HEALTH, Vector2(cx - 120.0, floor_y - 30.0))


func _pickup(kind: int, pos: Vector2) -> void:
	var p = PickupScript.new()
	p.kind = kind
	p.life = 100000.0
	main.add_child(p)
	p.setup(pos, Vector2.ZERO)


func build_effects() -> void:
	var fx := Decor.StormFX.new()
	fx.vp = vp
	screen_layer.add_child(fx)


# בעליות השחת - בולאדורים (זורקים מלמעלה). ליד הטחנות - קורא סערה. בדרך - טורו אחד בכל שליש.
func extra_spawns() -> void:
	for l in _lofts:
		spawn(Registry.BOLEADOR, lerpf(float(l[0]), float(l[1]), 0.35), floor_y - TIER)
		spawn(Registry.BOLEADOR, lerpf(float(l[0]), float(l[1]), 0.75), floor_y - TIER)
	for i in _mills.size():
		if i > 0:
			spawn(Registry.STORMCALLER, float(_mills[i]) + 260.0)
	for f in [0.24, 0.5, 0.7]:
		spawn(Registry.TORO, level_w * f)
