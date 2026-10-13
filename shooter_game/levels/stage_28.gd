extends "res://levels/stage_base.gd"
# ============================================================
#  STAGE 28 - "CLOUD PASS" (אזור רביעי - האנדים, שלב 1) - "THEY LEARNED THE HEIGHTS"
#  מעבר הרים באנדים (effects/s28_decor.gd): פסגות מושלגות, עננים שעוברים, טרסות אינקה, חומות אבן, קונדורים, לאמות.
#  קומה שנייה: גשרי חבלים אינקאיים (BRIDGES) מעל הסדקים.
#  מלכודות: Crevasse - סדקי קרח עם יתדות (CREVASSES). Wind - משבי רוח (אזהרה: דגלים, אבק, יללה) שדוחפים לכיוון הסדקים.
#  מדורות רועים עם עשן (CAMPFIRES).
#  זומבים: CONDOR (חג, מסמן צל, צולל), BOULDER (מגלגל סלעים), LEAPER, רגילים, רצים.
#  בוס: APU KUNTUR - CONDOR ענק (enemies/types/condor.gd, מצב בוס), צולל פעמיים.
#  לשנות: CREVASSES, BRIDGES, TIER, CAMPFIRES, zombie_weights().
# ============================================================

const Decor := preload("res://effects/s28_decor.gd")
const PickupScript := preload("res://pickup.gd")

const SOUNDS := {
	"w28_howl": [["N", 0, 0, 0.0, 1.3, 0.5, 0.0, 0.35, 0.1, 0, 0.05], ["S", 300, 420, 0.0, 1.3, 0.5, 0.0, 0.06, 1.0, 0.08]],
	"w28_gust": [["N", 0, 0, 0.0, 2.0, 0.15, 1.0, 0.6, 0.18, 0, 0.1], ["S", 380, 260, 0.0, 2.0, 0.2, 1.0, 0.06, 1.0, 0.1]],
}

const CREVASSES := 5
const BRIDGES := [[0.2, 380.0], [0.44, 420.0], [0.68, 400.0], [0.88, 380.0]]   # [מיקום יחסי, רוחב]
const TIER := 150.0
const CAMPFIRES := [0.08, 0.33, 0.57, 0.8]
const HARDER := [1.0, 1.15, 1.3]

var _spans := []


func zombie_weights() -> Dictionary:
	return {Registry.CONDOR: 0.1, Registry.BOULDER: 0.09, Registry.LEAPER: 0.08, 0: 0.4, 1: 0.33}


func zombie_density() -> float:
	return 1.0 * float(HARDER[clampi(Settings.difficulty, 0, 2)])


func generators() -> Array:
	return [["inka_wall", 1.4], ["apacheta", 1.0], ["bale", 0.8]]


func custom_gen(gname: String, x: float) -> float:
	if not gname in ["inka_wall", "apacheta", "bale"]:
		return 0.0
	var o := Decor.Obstacle.new()
	o.kind = gname
	o.seed_v = rng.randi()
	match gname:
		"inka_wall":
			o.size = Vector2(rng.randf_range(80.0, 110.0), rng.randf_range(44.0, 60.0))
		"apacheta":
			o.size = Vector2(rng.randf_range(44.0, 56.0), rng.randf_range(44.0, 54.0))
		_:
			o.size = Vector2(rng.randf_range(70.0, 86.0), rng.randf_range(32.0, 38.0))
	o.position = Vector2(x, floor_y)
	main.add_child(o)
	reserve(Rect2(x, floor_y - o.size.y, o.size.x, o.size.y))
	return o.size.x


func boss_kind() -> int:
	return Registry.CONDOR


func music() -> String:
	return "res://music/level1_total_war.mp3"


func world_tint() -> Color:
	return Color(0.97, 0.98, 1.0)


func fog() -> bool:
	return false


func pits() -> int:
	return CREVASSES


func build_background(layer: CanvasLayer) -> Node:
	var bg = Backdrop.new()
	bg.level_w = level_w
	bg.sky = func(ci: CanvasItem, v: Vector2, t: float):
		Decor.andes_sky(ci, v, t)
	bg.add_layer(0.06, func(ci: CanvasItem, sc: float, v: Vector2, t: float):
		Decor.far_peaks(ci, sc, v, 520.0, t))
	bg.add_layer(0.3, func(ci: CanvasItem, sc: float, v: Vector2, t: float):
		Decor.mid_terraces(ci, sc, v, 610.0, t))
	bg.add_layer(0.62, func(ci: CanvasItem, sc: float, v: Vector2, t: float):
		Decor.near_ichu(ci, sc, v, 630.0, t))
	layer.add_child(bg)
	return bg


func build_world() -> void:
	main.add_child(Decor.Wind.new())
	var pits_list: Array = main._pits.filter(func(p): return p.size() < 3)
	var x := 0.0
	for p in pits_list + [[level_w, 0.0]]:
		_ground(x, float(p[0]))
		if float(p[1]) > 0.0:
			var cv := Decor.Crevasse.new()
			cv.w = float(p[1])
			cv.depth = main.PIT_DEPTH
			cv._seed = rng.randi()
			add_world(cv, Vector2(float(p[0]), floor_y))
		x = float(p[0]) + float(p[1])
	for br in BRIDGES:   # גשרי חבלים
		var ox := level_w * float(br[0])
		var w: float = br[1]
		add_floor(ox, floor_y - TIER, w, "wood", false, false)
		add_ladder(ox + 12.0, floor_y - TIER)
		var rb := Decor.RopeBridge.new()
		rb.w = w
		add_world(rb, Vector2(ox, floor_y - TIER))
		reserve(Rect2(ox - 20.0, floor_y - TIER, w + 40.0, TIER))
		_spans.append([ox, ox + w])
		_pickup(PickupScript.AMMO if br[0] < 0.5 else PickupScript.HEALTH, Vector2(ox + w * 0.6, floor_y - TIER - 30.0))
	for f in CAMPFIRES:   # מדורות רועים
		var cx := level_w * float(f)
		while not free_x(cx, 30.0) and cx < level_w - 300.0:
			cx += 40.0
		add_world(Decor.Campfire.new(), Vector2(cx, floor_y))
		reserve(Rect2(cx - 40.0, floor_y - 40.0, 80.0, 40.0))


func _ground(x0: float, x1: float) -> void:
	var x := x0
	while x < x1:
		var g := Decor.PassGround.new()
		g.w = minf(1024.0, x1 - x)
		g.depth = main.floor_thickness
		g.seed_v = rng.randi()
		add_world(g, Vector2(x, floor_y))
		x += 1024.0


func _pickup(kind: int, pos: Vector2) -> void:
	var p = PickupScript.new()
	p.kind = kind
	p.life = 100000.0
	main.add_child(p)
	p.setup(pos, Vector2.ZERO)


func build_effects() -> void:
	var fx := Decor.PassFX.new()
	fx.vp = vp
	screen_layer.add_child(fx)


# BOULDER על הגשרים, CONDOR בשמיים
func extra_spawns() -> void:
	for i in _spans.size():
		var s: Array = _spans[i]
		if i % 2 == 1:
			spawn(Registry.BOULDER, lerpf(float(s[0]), float(s[1]), 0.6), floor_y - TIER)
	for f in [0.25, 0.5, 0.75]:
		spawn(Registry.CONDOR, level_w * float(f))
