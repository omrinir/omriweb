extends "res://levels/stage_base.gd"
# ============================================================
#  STAGE 30 - "FROZEN VILLAGE" (אזור רביעי - האנדים, שלב 3) - "THEY LEARNED THE COLD"
#  כפר אנדי גבוה בסופת שלג (effects/s30_decor.gd): בתי אדובי עם ארובות מעשנות, כנסייה קולוניאלית, אלפקות,
#  כביסה קפואה, חביות אש (מחממות), שלג כבד.
#  קומה שנייה: גגות הבתים (HOUSES, "roof") עם סולמות. מגדל הפעמון (TOWER) - שם ה-BELLRINGER.
#  מלכודת: ThinIce - שלוליות קפואות על הדרך (ICE). עומדים עליהן יותר מדי - נשברות: נזק + קפוא.
#  זומבים: FROSTBITE (שריון קרח, נשיכה מקפיאה), BELLRINGER (פעמון = whiteout + הסתערות), רגילים, רצים, LEAPER.
#  בוס: THE FROZEN ONE - FROSTBITE ענק (enemies/types/frostbite.gd, מצב בוס): קרח עבה שצומח מחדש. אש שוברת קרח!
#  לשנות: HOUSES, TOWER, ICE, BRAZIERS, zombie_weights().
# ============================================================

const Decor := preload("res://effects/s30_decor.gd")
const PickupScript := preload("res://pickup.gd")

const SOUNDS := {
	"s30_crack": [["C", 0, 0, 0.0, 0.12, 0.0, 30.0, 0.7, 1.0, 0], ["S", 2400, 900, 0.0, 0.12, 0.0, 30.0, 0.12, 1.0, 0]],
}

const HOUSES := [[0.12, 360.0], [0.3, 400.0], [0.58, 380.0], [0.8, 420.0]]   # [מיקום יחסי, רוחב]
const TIER := 150.0
const TOWER := 0.45
const TOWER_H := 280.0
const ICE := [0.08, 0.2, 0.26, 0.38, 0.52, 0.66, 0.74, 0.9]
const BRAZIERS := [0.05, 0.24, 0.42, 0.62, 0.86]
const HARDER := [1.0, 1.15, 1.3]

var _spans := []
var _tower_x := 0.0


func zombie_weights() -> Dictionary:
	return {Registry.FROSTBITE: 0.14, Registry.BELLRINGER: 0.05, Registry.LEAPER: 0.07, 0: 0.42, 1: 0.32}


func zombie_density() -> float:
	return 1.0 * float(HARDER[clampi(Settings.difficulty, 0, 2)])


func generators() -> Array:
	return [["stonewall", 1.4], ["woodpile", 1.0], ["haycart", 0.7]]


func custom_gen(gname: String, x: float) -> float:
	if not gname in ["stonewall", "woodpile", "haycart"]:
		return 0.0
	var o := Decor.Obstacle.new()
	o.kind = gname
	o.seed_v = rng.randi()
	match gname:
		"stonewall":
			o.size = Vector2(rng.randf_range(80.0, 110.0), rng.randf_range(40.0, 50.0))
		"woodpile":
			o.size = Vector2(rng.randf_range(60.0, 80.0), rng.randf_range(36.0, 44.0))
		_:
			o.size = Vector2(rng.randf_range(90.0, 110.0), rng.randf_range(52.0, 62.0))
	o.position = Vector2(x, floor_y)
	main.add_child(o)
	reserve(Rect2(x, floor_y - o.size.y, o.size.x, o.size.y))
	return o.size.x


func boss_kind() -> int:
	return Registry.FROSTBITE


func music() -> String:
	return "res://music/level2_suspense.mp3"


func world_tint() -> Color:
	return Color(0.93, 0.96, 1.0)


func fog() -> bool:
	return false


func pits() -> int:
	return 0


func build_background(layer: CanvasLayer) -> Node:
	var bg = Backdrop.new()
	bg.level_w = level_w
	bg.sky = func(ci: CanvasItem, v: Vector2, t: float):
		Decor.blizzard_sky(ci, v, t)
	bg.add_layer(0.06, func(ci: CanvasItem, sc: float, v: Vector2, t: float):
		Decor.far_ridges(ci, sc, v, 540.0, t))
	bg.add_layer(0.3, func(ci: CanvasItem, sc: float, v: Vector2, t: float):
		Decor.mid_village(ci, sc, v, 612.0, t))
	bg.add_layer(0.62, func(ci: CanvasItem, sc: float, v: Vector2, t: float):
		Decor.near_drifts(ci, sc, v, 632.0, t))
	layer.add_child(bg)
	return bg


func build_world() -> void:
	var x := 0.0
	while x < level_w:
		var g := Decor.SnowGround.new()
		g.w = minf(1024.0, level_w - x)
		g.depth = main.floor_thickness
		g.seed_v = rng.randi()
		add_world(g, Vector2(x, floor_y))
		x += 1024.0
	for hs in HOUSES:   # בתים: הקירות מאחור, הגג = קומה
		var ox := level_w * float(hs[0])
		var w: float = hs[1]
		var hse := Decor.House.new()
		hse.w = w
		hse.h = TIER
		hse.seed_v = rng.randi()
		add_world(hse, Vector2(ox, floor_y))
		add_floor(ox - 10.0, floor_y - TIER, w + 20.0, "roof", false, false)
		add_ladder(ox + 12.0, floor_y - TIER)
		reserve(Rect2(ox - 30.0, floor_y - TIER, w + 60.0, TIER))
		_spans.append([ox, ox + w])
		_pickup(PickupScript.AMMO if hs[0] < 0.5 else PickupScript.HEALTH, Vector2(ox + w * 0.6, floor_y - TIER - 30.0))
	_tower_x = level_w * TOWER   # מגדל הפעמון
	var tw := Decor.BellTower.new()
	tw.h = TOWER_H
	add_world(tw, Vector2(_tower_x, floor_y))
	add_floor(_tower_x - 8.0, floor_y - TOWER_H, tw.w + 16.0, "wood", false, false)
	add_ladder(_tower_x + 8.0, floor_y - TOWER_H)
	reserve(Rect2(_tower_x - 30.0, floor_y - TOWER_H, tw.w + 60.0, TOWER_H))
	for f in ICE:   # קרח דק
		var ix := level_w * float(f)
		while not free_x(ix, 30.0) and ix < level_w - 300.0:
			ix += 50.0
		var ti := Decor.ThinIce.new()
		ti.w = rng.randf_range(90.0, 140.0)
		add_world(ti, Vector2(ix, floor_y))
		reserve(Rect2(ix - 20.0, floor_y - 30.0, ti.w + 40.0, 30.0))
	for f in BRAZIERS:   # חביות אש
		var bx := level_w * float(f)
		while not free_x(bx, 30.0) and bx < level_w - 300.0:
			bx += 50.0
		add_world(Decor.Brazier.new(), Vector2(bx, floor_y))
		reserve(Rect2(bx - 30.0, floor_y - 50.0, 60.0, 50.0))


func _pickup(kind: int, pos: Vector2) -> void:
	var p = PickupScript.new()
	p.kind = kind
	p.life = 100000.0
	main.add_child(p)
	p.setup(pos, Vector2.ZERO)


func build_effects() -> void:
	var fx := Decor.BlizzardFX.new()
	fx.vp = vp
	screen_layer.add_child(fx)


# BELLRINGER במגדל + אחד על גג, FROSTBITE ברחובות
func extra_spawns() -> void:
	spawn(Registry.BELLRINGER, _tower_x + 55.0, floor_y - TOWER_H)
	var s: Array = _spans[3]
	spawn(Registry.BELLRINGER, lerpf(float(s[0]), float(s[1]), 0.5), floor_y - TIER)
	for f in [0.17, 0.35, 0.55, 0.7]:
		var fx := level_w * float(f)
		if free_x(fx, 30.0):
			spawn(Registry.FROSTBITE, fx)
