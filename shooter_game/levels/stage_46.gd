extends "res://levels/stage_base.gd"
# ============================================================
#  STAGE 46 - "WINE VALLEY" (אזור שישי - החרוט הדרומי, שלב 1) - "THEY LEARNED THE BLADE"
#  (הסיפור: האימפריה נפלה, והגיבור יורד דרומה אל ארגנטינה. במנדוסה, בזמן הבציר, הכרמים מלאים בעובדים מתים -
#   והם הרימו את הכלים: מגלי בציר, חביות, וחרב התליין הישנה מהמוזיאון של היקב.)
#  (effects/s46_decor.gd): שקיעה ורודה, האנדים המושלגים והאקונקגואה, יקבי אדובי עם שדרות צפצפות, שורות גפנים בסתיו.
#  קומה שנייה: פרגולות גפן (PERGOLAS).
#  מלכודות: BarrelStack - ערימות חביות על רמפה שמגלגלות חבית לכיוונך (לקפוץ; ירייה בטריז = משחרר על זומבים),
#           FermentVat - מיכלי תסיסה שפולטים ענן CO2 (מסחרר); ירייה במיכל מעלה לחץ עד שהוא מתפוצץ על הזומבים.
#  זומבים: EXECUTIONER (חרב ענקית: SLAM מלמעלה / SWEEP נמוך, לומד איך התחמקת), HARVESTER (מגל על שרשרת שמושך אותך),
#          CASK (בתוך חבית יין - שריון, ומתגלגל אליך), REVIVER, רגילים, רצים.
#  בוס: THE HEADSMAN (EXECUTIONER ענק, enemies/types/executioner.gd) - מול שער היקב בסוף.
#  לשנות: PERGOLAS, TIER, STACKS, VATS, SQUADS, zombie_weights().
# ============================================================

const Decor := preload("res://effects/s46_decor.gd")
const PickupScript := preload("res://pickup.gd")

const SOUNDS := {
	"wv_creak": [["S", 120, 95, 0.0, 0.5, 0.0, 3.5, 0.3, 1.0, 0.15], ["N", 0, 0, 0.0, 0.4, 0.0, 5.0, 0.12, 0.3, 0, 0.6]],
	"wv_hiss": [["N", 0, 0, 0.0, 1.0, 0.1, 1.5, 0.35, 0.9, 0, 0.3]],
	"wv_burst": [["N", 0, 0, 0.0, 0.7, 0.0, 5.0, 0.8, 0.4, 0, 0.8], ["S", 70, 40, 0.0, 0.4, 0.0, 7.0, 0.6, 1.0, 0]],
}

const PERGOLAS := [[0.18, 320.0], [0.45, 360.0], [0.71, 320.0]]
const TIER := 150.0
const STACKS := [0.27, 0.55, 0.8]
const VATS := [0.12, 0.38, 0.63, 0.86]
const SQUADS := [0.1, 0.3, 0.5, 0.66, 0.84]
const HARDER := [1.0, 1.1, 1.25]

var _perg := []


func zombie_weights() -> Dictionary:
	return {Registry.EXECUTIONER: 0.03, Registry.HARVESTER: 0.05, Registry.CASK: 0.04, Registry.REVIVER: 0.012, 0: 0.55, 1: 0.32}


func zombie_density() -> float:
	return 1.0 * float(HARDER[clampi(Settings.difficulty, 0, 2)])


func generators() -> Array:
	return [["casks", 1.0], ["bins", 1.2], ["press", 0.6]]


func custom_gen(gname: String, x: float) -> float:
	if not gname in ["casks", "bins", "press"]:
		return 0.0
	if not free_x(x, 20.0) or not free_x(x + 100.0, 20.0):   # לא בתוך מלכודת / סולם / זירת הבוס
		return 80.0
	var o := Decor.Obstacle.new()
	o.kind = gname
	o.seed_v = rng.randi()
	match gname:
		"casks":
			o.size = Vector2(rng.randf_range(84.0, 100.0), rng.randf_range(50.0, 56.0))
		"bins":
			o.size = Vector2(rng.randf_range(54.0, 66.0), rng.randf_range(34.0, 40.0))
		_:
			o.size = Vector2(rng.randf_range(54.0, 60.0), rng.randf_range(60.0, 68.0))
	o.position = Vector2(x, floor_y)
	main.add_child(o)
	reserve(Rect2(x, floor_y - o.size.y, o.size.x, o.size.y))
	return o.size.x


func boss_kind() -> int:
	return Registry.EXECUTIONER


func music() -> String:
	return "res://music/level1_total_war.mp3"


func world_tint() -> Color:
	return Color(1.0, 0.93, 0.9)


func fog() -> bool:
	return false


func pits() -> int:
	return 0


func build_background(layer: CanvasLayer) -> Node:
	var bg = Backdrop.new()
	bg.level_w = level_w
	bg.sky = func(ci: CanvasItem, v: Vector2, t: float):
		Decor.valley_sky(ci, v, t)
	bg.add_layer(0.06, func(ci: CanvasItem, sc: float, v: Vector2, t: float):
		Decor.far_andes(ci, sc, v, 560.0, t))
	bg.add_layer(0.28, func(ci: CanvasItem, sc: float, v: Vector2, t: float):
		Decor.mid_bodegas(ci, sc, v, 640.0, t))
	bg.add_layer(0.6, func(ci: CanvasItem, sc: float, v: Vector2, t: float):
		Decor.near_vines(ci, sc, v, 648.0, t))
	layer.add_child(bg)
	return bg


func build_world() -> void:
	var x := 0.0
	while x < level_w:
		var g := Decor.VineyardGround.new()
		g.w = minf(1024.0, level_w - x)
		g.depth = main.floor_thickness
		add_world(g, Vector2(x, floor_y))
		x += 1024.0
	for p in PERGOLAS:   # פרגולות גפן = קומה שנייה
		var w: float = p[1]
		var dx := level_w * float(p[0])
		var pg := Decor.Pergola.new()
		pg.w = w
		pg.tier = TIER
		add_world(pg, Vector2(dx, floor_y))
		var pf = add_floor(dx - 4.0, floor_y - TIER, w + 8.0, "concrete", false, false)
		pf.visible = false
		add_ladder(dx + 30.0, floor_y - TIER)
		add_ladder(dx + w - 52.0, floor_y - TIER)
		reserve(Rect2(dx, floor_y - 40.0, w, 40.0))
		_perg.append([dx, dx + w])
		_pickup(PickupScript.AMMO if p[0] < 0.6 else PickupScript.HEALTH, Vector2(dx + w * 0.5, floor_y - TIER - 30.0))
	for f in STACKS:   # ערימות חביות (מגלגלות אחורה - לכיוון שממנו אתה מגיע)
		var sx := level_w * float(f)
		var st := Decor.BarrelStack.new()
		st.dir = -1.0
		add_world(st, Vector2(sx, floor_y))
		reserve(Rect2(sx - 60.0, floor_y - 90.0, 120.0, 90.0))
	for f in VATS:
		var vx := level_w * float(f)
		if not free_x(vx, 50.0):
			vx += 140.0
		var vt := Decor.FermentVat.new()
		add_world(vt, Vector2(vx, floor_y))
		reserve(Rect2(vx - 50.0, floor_y - 120.0, 100.0, 120.0))
	# שער היקב מאחורי הבוס
	var gx := level_w - 520.0
	add_world(Decor.BodegaGate.new(), Vector2(gx, floor_y))
	reserve(Rect2(gx - 700.0, floor_y - 60.0, 600.0, 60.0))   # זירת הבוס פנויה
	_pickup(PickupScript.HEALTH, Vector2(gx - 760.0, floor_y - 30.0))
	_pickup(PickupScript.AMMO, Vector2(gx - 820.0, floor_y - 30.0))


func _pickup(kind: int, pos: Vector2) -> void:
	var p = PickupScript.new()
	p.kind = kind
	p.life = 100000.0
	main.add_child(p)
	p.setup(pos, Vector2.ZERO)


func build_effects() -> void:
	var fx := Decor.HarvestFX.new()
	fx.vp = vp
	screen_layer.add_child(fx)


# קבוצות: תליין מלפנים עם חבית לידו, בוצרים מאחור שזורקים מגלים. על הפרגולות - בוצרים
func extra_spawns() -> void:
	for i in SQUADS.size():
		var sx := level_w * float(SQUADS[i])
		if i % 2 == 0:
			spawn(Registry.EXECUTIONER, sx)
			spawn(Registry.CASK, sx + 70.0)
		else:
			spawn(Registry.CASK, sx)
			spawn(Registry.CASK, sx + 60.0)
		spawn(Registry.HARVESTER, sx + 260.0)
		spawn(0, sx + 140.0)
	for b in _perg:
		spawn(Registry.HARVESTER, lerpf(float(b[0]), float(b[1]), 0.65), floor_y - TIER)
