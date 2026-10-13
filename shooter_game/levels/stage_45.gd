extends "res://levels/stage_base.gd"
# ============================================================
#  STAGE 45 - "THE RED PALACE" (אזור חמישי - דרום-מזרח, שלב 9 - הסוף של אימפריית המתים) - "THEY LEARNED YOU"
#  (הסיפור: מאיטאיפו הגיבור עוקב אחרי ספינת האוויר שנמלטה מזרחה - אל פטרופוליס, עיר הקיסרים של ברזיל בהרים מעל ריו.
#   קיסר המתים יושב בארמון הקיסרי הישן, שנצבע אדום. כל צבא האימפריה כבר מכיר את הטריקים שלך. זה הסוף.)
#  (effects/s45_decor.gd): שקיעה אדומה, רכס סרה דוס אורגאוס עם "אצבע האלוהים", הקתדרלה הגותית, חזית הארמון עם דקלים קיסריים,
#  גן הורטנזיות. קומה שנייה: מרפסות (BALCONIES).
#  מלכודות: Brazier - מדורות טקס שמתלקחות, HangingBanner - כרזות ענק שנופלות כשאתה מתחתן (או כשיורים בחבל - על זומבים!).
#  זומבים: PRAETORIAN (מגן שלומד את זווית היריות), COMMISSAR (לוקח פיקוד, מחזיר מבולבלים), HERALD (צו הקיסר נגד אש כבדה),
#          CONSCRIPT, OFFICER, REVIVER, רגילים, רצים. כל הטריקים מהשלבים הקודמים (להרוג קצין, להפיל דגל) - הם כבר מוכנים להם.
#  בוס נייח: THE EMPEROR (enemies/types/emperor.gd) - על במת הכס בסוף.
#  לשנות: BALCONIES, TIER, BRAZIERS, BANNERS, SQUADS, DAIS, zombie_weights().
# ============================================================

const Decor := preload("res://effects/s45_decor.gd")
const PickupScript := preload("res://pickup.gd")

const SOUNDS := {
	"rp_whoosh": [["N", 0, 0, 0.0, 0.7, 0.0, 5.0, 0.6, 0.4, 0, 0.7], ["S", 80, 50, 0.0, 0.5, 0.0, 6.0, 0.3, 1.0, 0.05]],
	"rp_creak": [["S", 140, 110, 0.0, 0.6, 0.0, 3.0, 0.25, 1.0, 0.15], ["N", 0, 0, 0.0, 0.5, 0.0, 4.0, 0.1, 0.3, 0, 0.6]],
	"rp_snap": [["C", 0, 0, 0.0, 0.04, 0.0, 60.0, 0.5, 1.0, 0], ["N", 0, 0, 0.02, 0.3, 0.0, 10.0, 0.3, 0.5, 0, 0.6]],
}

const BALCONIES := [[0.2, 320.0], [0.46, 340.0], [0.72, 320.0]]
const TIER := 150.0
const BRAZIERS := [0.1, 0.3, 0.41, 0.6, 0.85]
const BANNERS := [0.16, 0.35, 0.53, 0.66, 0.8, 0.9]
const SQUADS := [0.12, 0.36, 0.6, 0.84]
const DAIS := 90.0
const HARDER := [1.0, 1.15, 1.3]

var _balc := []


func zombie_weights() -> Dictionary:
	return {Registry.CONSCRIPT: 0.08, Registry.PRAETORIAN: 0.03, Registry.COMMISSAR: 0.015, Registry.HERALD: 0.015, Registry.OFFICER: 0.01,
		Registry.REVIVER: 0.02, 0: 0.5, 1: 0.33}


func zombie_density() -> float:
	return 1.0 * float(HARDER[clampi(Settings.difficulty, 0, 2)])


func generators() -> Array:
	return [["statue", 0.8], ["urn", 1.0], ["hedge", 1.0]]


func custom_gen(gname: String, x: float) -> float:
	if not gname in ["statue", "urn", "hedge"]:
		return 0.0
	var o := Decor.Obstacle.new()
	o.kind = gname
	o.seed_v = rng.randi()
	match gname:
		"statue":
			o.size = Vector2(rng.randf_range(40.0, 46.0), rng.randf_range(70.0, 80.0))
		"urn":
			o.size = Vector2(rng.randf_range(44.0, 52.0), rng.randf_range(44.0, 50.0))
		_:
			o.size = Vector2(rng.randf_range(70.0, 90.0), rng.randf_range(36.0, 42.0))
	o.position = Vector2(x, floor_y)
	main.add_child(o)
	reserve(Rect2(x, floor_y - o.size.y, o.size.x, o.size.y))
	return o.size.x


func boss_kind() -> int:
	return Registry.EMPEROR


func music() -> String:
	return "res://music/level1_total_war.mp3"


func world_tint() -> Color:
	return Color(1.0, 0.9, 0.9)


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
		Decor.palace_sky(ci, v, t)
	bg.add_layer(0.05, func(ci: CanvasItem, sc: float, v: Vector2, t: float):
		Decor.far_mountains(ci, sc, v, 560.0, t))
	bg.add_layer(0.25, func(ci: CanvasItem, sc: float, v: Vector2, t: float):
		Decor.mid_palace(ci, sc, v, 622.0, t))
	bg.add_layer(0.6, func(ci: CanvasItem, sc: float, v: Vector2, t: float):
		Decor.near_garden(ci, sc, v, 645.0, t))
	layer.add_child(bg)
	return bg


func build_world() -> void:
	var x := 0.0
	while x < level_w:
		var g := Decor.PalaceGround.new()
		g.w = minf(1024.0, level_w - x)
		g.depth = main.floor_thickness
		add_world(g, Vector2(x, floor_y))
		x += 1024.0
	for b in BALCONIES:   # מרפסות
		var w: float = b[1]
		var dx := level_w * float(b[0])
		var bc := Decor.Balcony.new()
		bc.w = w
		bc.tier = TIER
		add_world(bc, Vector2(dx, floor_y))
		var pf = add_floor(dx - 4.0, floor_y - TIER, w + 8.0, "concrete", false, false)
		pf.visible = false
		add_ladder(dx + 34.0, floor_y - TIER)
		add_ladder(dx + w - 58.0, floor_y - TIER)
		reserve(Rect2(dx, floor_y - 40.0, w, 40.0))
		_balc.append([dx, dx + w])
		_pickup(PickupScript.AMMO if b[0] < 0.6 else PickupScript.HEALTH, Vector2(dx + w * 0.5, floor_y - TIER - 30.0))
	for f in BRAZIERS:
		var bx := level_w * float(f)
		var br := Decor.Brazier.new()
		add_world(br, Vector2(bx, floor_y))
		reserve(Rect2(bx - 30.0, floor_y - 50.0, 60.0, 50.0))
	for f in BANNERS:
		var hx := level_w * float(f)
		var hb := Decor.HangingBanner.new()
		add_world(hb, Vector2(hx, floor_y))
	# במת הכס
	var bx2 := level_w - 720.0
	var th := Decor.Throne.new()
	th.w = 520.0
	th.tier = DAIS
	add_world(th, Vector2(bx2 - 260.0, floor_y))
	var df = add_floor(bx2 - 260.0, floor_y - DAIS, 520.0, "concrete", false, false)
	df.visible = false
	add_ladder(bx2 - 250.0, floor_y - DAIS)
	add_ladder(bx2 + 230.0, floor_y - DAIS)
	reserve(Rect2(bx2 - 300.0, floor_y - DAIS, 600.0, DAIS))
	_pickup(PickupScript.HEALTH, Vector2(bx2 - 420.0, floor_y - 30.0))
	main.set_meta("boss_x", bx2)
	main.set_meta("boss_y", floor_y - DAIS)
	main.set_meta("boss_ground_y", floor_y)


func _pickup(kind: int, pos: Vector2) -> void:
	var p = PickupScript.new()
	p.kind = kind
	p.life = 100000.0
	main.add_child(p)
	p.setup(pos, Vector2.ZERO)


func build_effects() -> void:
	var fx := Decor.PalaceFX.new()
	fx.vp = vp
	screen_layer.add_child(fx)


# יחידות: 2 משמר מלפנים (חומת מגנים), 2 רובאים, קצין, קומיסר / כרוז מאחור. על המרפסות - רובאי + כרוז
func extra_spawns() -> void:
	for i in SQUADS.size():
		var sx := level_w * float(SQUADS[i])
		spawn(Registry.PRAETORIAN, sx)
		spawn(Registry.PRAETORIAN, sx + 40.0)
		spawn(Registry.CONSCRIPT, sx + 110.0)
		spawn(Registry.CONSCRIPT, sx + 150.0)
		spawn(Registry.OFFICER, sx + 260.0)
		spawn(Registry.COMMISSAR if i % 2 == 0 else Registry.HERALD, sx + 420.0)
	for b in _balc:
		spawn(Registry.CONSCRIPT, lerpf(float(b[0]), float(b[1]), 0.4), floor_y - TIER)
		spawn(Registry.HERALD, lerpf(float(b[0]), float(b[1]), 0.7), floor_y - TIER)
