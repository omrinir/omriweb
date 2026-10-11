extends "res://levels/stage_base.gd"
# ============================================================
#  STAGE 23 - "HIGHWAY 7" (אזור שלישי, שלב 5) - "THEY LEARNED TO DRIVE"
#  כביש מהיר פקוק בשקיעה (effects/s23_decor.gd): מכוניות נטושות, גשרים עיליים שבורים, שלטים, עיר בוערת.
#  קומה שנייה: קטעי גשר שבורים (OVERPASSES) עם סולמות.
#  מלכודת: מכוניות עם אזעקה (נורה אדומה מהבהבת על השמשה). נגיעה / ירייה / דחיפה -> אזעקה,
#          כל הזומבים באזור שומעים ועוד זומבים רצים אליך משני הצדדים.
#  זומבים: BIKER (אופנוען שמסתער ועף מהאופנוע), SHOVER (דוחף מכוניות עליך), LEAPER, REVOLVER, רגילים ורצים.
#  מכסי ביוב עם אדים (manhole.gd) לאורך הכביש - קליע מקפיץ את המכסה.
#  בוס: ROAD KING - BIKER ענק (enemies/types/biker.gd, מצב בוס), מסתער פעמיים ברצף.
#  לשנות: OVERPASSES, TIER, ALARM_CHANCE, zombie_weights().
# ============================================================

const Decor := preload("res://effects/s23_decor.gd")
const PickupScript := preload("res://pickup.gd")
const ManholeScript := preload("res://manhole.gd")

const SOUNDS := {
	"s23_alarm": [["Q", 650, 1350, 0.0, 0.38, 0.01, 1.0, 0.3, 0.45, 0], ["Q", 1350, 650, 0.38, 0.38, 0.0, 1.0, 0.3, 0.45, 0], ["Q", 650, 1350, 0.76, 0.38, 0.0, 1.0, 0.3, 0.45, 0], ["Q", 1350, 650, 1.14, 0.38, 0.0, 2.0, 0.3, 0.45, 0]],
	"s23_scrape": [["N", 0, 0, 0.0, 0.7, 0.04, 3.0, 0.7, 0.3, 0, 0.2], ["S", 230, 150, 0.0, 0.7, 0.05, 3.0, 0.18, 1.0, 0.03], ["C", 0, 0, 0.0, 0.6, 0.0, 4.0, 0.5, 1.0, 0]],
}

const OVERPASSES := [[0.16, 420.0], [0.4, 380.0], [0.63, 440.0], [0.84, 400.0]]   # [מיקום יחסי, רוחב]
const TIER := 150.0
const ALARM_CHANCE := 0.3
const MANHOLES := [0.06, 0.19, 0.34, 0.47, 0.6, 0.71, 0.88]   # מכסי ביוב (יחסי)
const HARDER := [1.0, 1.15, 1.3]

var _spans := []
var _gen := 0


func zombie_weights() -> Dictionary:
	return {Registry.BIKER: 0.12, Registry.SHOVER: 0.12, Registry.LEAPER: 0.08, Registry.REVOLVER: 0.05, 0: 0.33, 1: 0.3}


func zombie_density() -> float:
	return 1.0 * float(HARDER[clampi(Settings.difficulty, 0, 2)])


func generators() -> Array:
	return [["wreck", 3.0], ["barrier", 1.0], ["tires", 0.5]]


func custom_gen(gname: String, x: float) -> float:
	if gname != "wreck":
		return 0.0
	var c := Decor.Car.new()
	c.model = rng.randi() % 3
	c.size = [Vector2(128, 44), Vector2(112, 46), Vector2(140, 48)][c.model]
	c.tint = Decor.CAR_COLS[rng.randi() % Decor.CAR_COLS.size()]
	c.face = 1.0 if rng.randf() < 0.5 else -1.0
	_gen += 1
	c.alarm = rng.randf() < ALARM_CHANCE or _gen == 2   # תמיד יש אחת מוקדם (לראות איך זה עובד)
	c.floor_y = floor_y
	c.seed_v = rng.randi()
	c.position = Vector2(x, floor_y)
	main.add_child(c)
	reserve(Rect2(x, floor_y - c.size.y, c.size.x, c.size.y))
	return c.size.x


func boss_kind() -> int:
	return Registry.BIKER


func music() -> String:
	return "res://music/level1_zombie_joyride.ogg"


func world_tint() -> Color:
	return Color(1.0, 0.94, 0.9)


func fog() -> bool:
	return false


func pits() -> int:
	return 0


func build_background(layer: CanvasLayer) -> Node:
	var bg = Backdrop.new()
	bg.level_w = level_w
	bg.sky = func(ci: CanvasItem, v: Vector2, t: float):
		Decor.dusk_sky(ci, v, t)
	bg.add_layer(0.08, func(ci: CanvasItem, sc: float, v: Vector2, t: float):
		Decor.far_city(ci, sc, v, 540.0, t))
	bg.add_layer(0.3, func(ci: CanvasItem, sc: float, v: Vector2, t: float):
		Decor.mid_overpass(ci, sc, v, 610.0, t))
	bg.add_layer(0.62, func(ci: CanvasItem, sc: float, v: Vector2, t: float):
		Decor.near_rail(ci, sc, v, 630.0, t))
	layer.add_child(bg)
	return bg


func build_world() -> void:
	var x := 0.0
	while x < level_w:
		var g := Decor.RoadGround.new()
		g.w = minf(1024.0, level_w - x)
		g.depth = main.floor_thickness
		g.seed_v = rng.randi()
		add_world(g, Vector2(x, floor_y))
		x += 1024.0
	for ov in OVERPASSES:   # קטעי גשר שבורים
		var ox := level_w * float(ov[0])
		var w: float = ov[1]
		add_floor(ox, floor_y - TIER, w, "concrete", true, true)
		add_ladder(ox + 12.0, floor_y - TIER)
		reserve(Rect2(ox - 20.0, floor_y - TIER, w + 40.0, TIER))
		_spans.append([ox, ox + w])
		_pickup(PickupScript.AMMO if ov[0] < 0.5 else PickupScript.HEALTH, Vector2(ox + w * 0.6, floor_y - TIER - 30.0))
	for f in MANHOLES:   # מכסי ביוב עם אדים
		var mx := level_w * float(f)
		var mh = ManholeScript.new()
		mh.position = Vector2(mx, floor_y)
		main.add_child(mh)
		reserve(Rect2(mx - 30.0, floor_y - 60.0, 60.0, 60.0))   # שלא יהיה מכשול מעליו
	for f in [0.1, 0.3, 0.52, 0.74, 0.93]:   # גשרי שלטים (קישוט)
		var gt := Decor.Gantry.new()
		add_world(gt, Vector2(level_w * float(f), floor_y))


func _pickup(kind: int, pos: Vector2) -> void:
	var p = PickupScript.new()
	p.kind = kind
	p.life = 100000.0
	main.add_child(p)
	p.setup(pos, Vector2.ZERO)


func build_effects() -> void:
	var fx := Decor.RoadFX.new()
	fx.vp = vp
	screen_layer.add_child(fx)


# REVOLVER על הגשרים, BIKER בקטעים פתוחים
func extra_spawns() -> void:
	for i in _spans.size():
		var s: Array = _spans[i]
		if i % 2 == 1:
			spawn(Registry.REVOLVER, lerpf(float(s[0]), float(s[1]), 0.6), floor_y - TIER)
	for f in [0.27, 0.5, 0.78]:
		var bx := level_w * float(f)
		if free_x(bx, 60.0):
			spawn(Registry.BIKER, bx)
