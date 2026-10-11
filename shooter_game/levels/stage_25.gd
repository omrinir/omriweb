extends "res://levels/stage_base.gd"
# ============================================================
#  STAGE 25 - "RADIO TOWER" (אזור שלישי, שלב 7) - "THEY LEARNED TO CALL FOR HELP"
#  לילה סוער על גבעה (effects/s25_decor.gd): תורן רדיו ענק עם אורות אדומים, צלחות לוויין, גשם וברקים.
#  קומה שנייה: מסלולי פלדה (CATWALKS) עם סולמות - משם ה-ROD מזמן ברקים.
#  מלכודת: שלוליות מחושמלות (PUDDLES) עם כבל חשמל קרוע. הסערה (StormFX) קובעת מתי יש ברק:
#          WARN שניות לפני - השלוליות זוהרות ומנצנצות, ובזמן הברק - מחשמלות את מי שעומד בהן.
#  זומבים: SIGNALER (משדר וקורא לתגבורת - לירות בו בזמן השידור!), ROD (מזמן ברק על המקום שלך), רגילים, רצים, LEAPER.
#  בוס: THE STORMBRINGER - ROD ענק (enemies/types/rod.gd, מצב בוס), 3 ברקים ברצף.
#  לשנות: CATWALKS, TIER, PUDDLES, zombie_weights().
# ============================================================

const Decor := preload("res://effects/s25_decor.gd")
const PickupScript := preload("res://pickup.gd")

const SOUNDS := {
	"s25_zap": [["Q", 70, 60, 0.0, 0.3, 0.0, 7.0, 0.3, 0.6, 0], ["C", 0, 0, 0.0, 0.3, 0.0, 6.0, 0.9, 1.0, 0], ["S", 3600, 3000, 0.0, 0.18, 0.0, 14.0, 0.1, 1.0, 0]],
}

const CATWALKS := [[0.13, 400.0], [0.35, 420.0], [0.57, 380.0], [0.79, 440.0]]   # [מיקום יחסי, רוחב]
const TIER := 150.0
const PUDDLES := [0.08, 0.2, 0.29, 0.44, 0.51, 0.66, 0.73, 0.88, 0.95]
const HARDER := [1.0, 1.15, 1.3]

var _spans := []


func zombie_weights() -> Dictionary:
	return {Registry.SIGNALER: 0.1, Registry.ROD: 0.1, Registry.LEAPER: 0.08, Registry.SHOVER: 0.04, 0: 0.38, 1: 0.3}


func zombie_density() -> float:
	return 1.0 * float(HARDER[clampi(Settings.difficulty, 0, 2)])


func generators() -> Array:
	return [["cabinet", 1.4], ["spool", 1.0], ["generator", 0.7]]


func custom_gen(gname: String, x: float) -> float:
	if not gname in ["cabinet", "spool", "generator"]:
		return 0.0
	var o := Decor.Obstacle.new()
	o.kind = gname
	o.seed_v = rng.randi()
	match gname:
		"cabinet":
			o.size = Vector2(rng.randf_range(46.0, 60.0), rng.randf_range(66.0, 80.0))
		"spool":
			var h := rng.randf_range(40.0, 52.0)
			o.size = Vector2(h, h)
		_:
			o.size = Vector2(rng.randf_range(70.0, 86.0), rng.randf_range(40.0, 48.0))
	o.position = Vector2(x, floor_y)
	main.add_child(o)
	reserve(Rect2(x, floor_y - o.size.y, o.size.x, o.size.y))
	return o.size.x


func boss_kind() -> int:
	return Registry.ROD


func music() -> String:
	return "res://music/level2_suspense.mp3"


func world_tint() -> Color:
	return Color(0.84, 0.9, 1.0)


func dark_level() -> bool:
	return false


func fog() -> bool:
	return false


func pits() -> int:
	return 0


func build_background(layer: CanvasLayer) -> Node:
	var bg = Backdrop.new()
	bg.level_w = level_w
	bg.sky = func(ci: CanvasItem, v: Vector2, t: float):
		Decor.storm_sky(ci, v, t)
	bg.add_layer(0.08, func(ci: CanvasItem, sc: float, v: Vector2, t: float):
		Decor.far_mast(ci, sc, v, 560.0, t))
	bg.add_layer(0.3, func(ci: CanvasItem, sc: float, v: Vector2, t: float):
		Decor.mid_station(ci, sc, v, 608.0, t))
	bg.add_layer(0.62, func(ci: CanvasItem, sc: float, v: Vector2, t: float):
		Decor.near_grass(ci, sc, v, 630.0, t))
	layer.add_child(bg)
	return bg


func build_world() -> void:
	var x := 0.0
	while x < level_w:
		var g := Decor.HillGround.new()
		g.w = minf(1024.0, level_w - x)
		g.depth = main.floor_thickness
		g.seed_v = rng.randi()
		add_world(g, Vector2(x, floor_y))
		x += 1024.0
	for cw in CATWALKS:
		var ox := level_w * float(cw[0])
		var w: float = cw[1]
		add_floor(ox, floor_y - TIER, w, "steel", true, true)
		add_ladder(ox + 12.0, floor_y - TIER)
		reserve(Rect2(ox - 20.0, floor_y - TIER, w + 40.0, TIER))
		_spans.append([ox, ox + w])
		_pickup(PickupScript.AMMO if cw[0] < 0.5 else PickupScript.HEALTH, Vector2(ox + w * 0.6, floor_y - TIER - 30.0))
	for f in PUDDLES:   # שלוליות מחושמלות (עם עמוד וכבל)
		var px := level_w * float(f)
		while not free_x(px, 40.0) and px < level_w - 200.0:
			px += 50.0
		var pd := Decor.Puddle.new()
		pd.w = rng.randf_range(80.0, 120.0)
		add_world(pd, Vector2(px, floor_y))
		reserve(Rect2(px - pd.w * 0.5 - 10.0, floor_y - 70.0, pd.w + 50.0, 70.0))


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


# ROD על המסלולים, SIGNALER מאחור
func extra_spawns() -> void:
	for i in _spans.size():
		var s: Array = _spans[i]
		spawn(Registry.ROD if i % 2 == 0 else Registry.SIGNALER, lerpf(float(s[0]), float(s[1]), 0.6), floor_y - TIER)
