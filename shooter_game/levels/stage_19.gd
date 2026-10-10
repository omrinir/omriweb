extends "res://levels/stage_base.gd"
# ============================================================
#  STAGE 19 - "THE GREEN WALL" (אזור שלישי, שלב 1) - "THEY LEARNED THE TREES"
#  ג'ונגל עבות: צמרת סגורה למעלה, קרני אור מסתננות, ערפל נמוך, חורבות מקדש וראשי אבן,
#  עצי ענק עם ליאנות, גזעים שנפלו, סלעי טחב, עמודי מקדש שבורים, במות עץ על העצים (קומה).
#  זומבים: SWINGER (מתנדנד על ליאנה כמו ספיידרמן ונוחת לידך), BLADES (להבים במקום ידיים,
#          מסתובב כמו מערבולת קדימה - קפוץ מעליו, ואז הוא מסוחרר), LEAPER, AMBUSHER (בשיחים),
#          רגילים ורצים.
#  בוס: THE THRESHER - BLADES ענק שמסתובב פעמיים ברצף (enemies/types/blades.gd, מצב בוס).
#  לשנות: TREEHOUSES, TREE_H, zombie_weights().
# ============================================================

const Decor := preload("res://effects/s19_decor.gd")
const PickupScript := preload("res://pickup.gd")

const TREEHOUSES := [[0.16, 300.0], [0.32, 340.0], [0.49, 280.0], [0.66, 360.0], [0.83, 300.0]]   # [מיקום יחסי, רוחב]
const TREE_H := 125.0
const HARDER := [1.0, 1.15, 1.3]

var _spans := []


func zombie_weights() -> Dictionary:
	return {Registry.SWINGER: 0.2, Registry.BLADES: 0.16, Registry.LEAPER: 0.1, Registry.AMBUSHER: 0.08, 0: 0.24, 1: 0.22}


func zombie_density() -> float:
	return 1.05 * float(HARDER[clampi(Settings.difficulty, 0, 2)])


func generators() -> Array:
	return [["log", 1.6], ["boulder", 1.4], ["ruin", 0.8], ["stump", 1.0]]


func custom_gen(gname: String, x: float) -> float:
	if not gname in ["log", "boulder", "ruin", "stump"]:
		return 0.0
	if _in_tree(x - 20.0) or _in_tree(x + 200.0):
		return 140.0
	var o := Decor.Obstacle.new()
	o.kind = gname
	o.seed_v = rng.randi()
	match gname:
		"log":
			o.size = Vector2(rng.randf_range(110.0, 170.0), rng.randf_range(28.0, 36.0))
		"boulder":
			o.size = Vector2(rng.randf_range(70.0, 110.0), rng.randf_range(40.0, 60.0))
		"ruin":   # גבוה - מחסה, אפשר לטפס עליו
			o.size = Vector2(rng.randf_range(54.0, 70.0), rng.randf_range(84.0, 100.0))
		_:
			o.size = Vector2(rng.randf_range(40.0, 56.0), rng.randf_range(26.0, 40.0))
	o.position = Vector2(x, floor_y)
	main.add_child(o)
	reserve(Rect2(x, floor_y - o.size.y, o.size.x, o.size.y))
	return o.size.x


func boss_kind() -> int:
	return Registry.BLADES


func music() -> String:
	return "res://music/level2_suspense.mp3"


func world_tint() -> Color:
	return Color(0.96, 1.0, 0.95)


func fog() -> bool:
	return false


func pits() -> int:
	return 0


func _in_tree(x: float) -> bool:
	for s in _spans:
		if x > float(s[0]) - 30.0 and x < float(s[1]) + 30.0:
			return true
	return false


# ---- רקע: אור מבעד לצמרת, ג'ונגל רחוק, עצי ענק, צמחייה קרובה ----
func build_background(layer: CanvasLayer) -> Node:
	var bg = Backdrop.new()
	bg.level_w = level_w
	bg.sky = func(ci: CanvasItem, v: Vector2, t: float):
		Decor.jungle_sky(ci, v, t)
	bg.add_layer(0.1, func(ci: CanvasItem, sc: float, v: Vector2, t: float):
		Decor.far_jungle(ci, sc, v, 520.0, t))
	bg.add_layer(0.35, func(ci: CanvasItem, sc: float, v: Vector2, t: float):
		Decor.mid_trees(ci, sc, v, 600.0, t))
	bg.add_layer(0.65, func(ci: CanvasItem, sc: float, v: Vector2, t: float):
		Decor.near_plants(ci, sc, v, 628.0, t))
	layer.add_child(bg)
	return bg


# ---- העולם: קרקע ג'ונגל, במות עץ על העצים ----
func build_world() -> void:
	var x := 0.0
	while x < level_w:
		var g := Decor.JungleGround.new()
		g.w = minf(1024.0, level_w - x)
		g.depth = main.floor_thickness
		g.seed_v = rng.randi()
		add_world(g, Vector2(x, floor_y))
		x += 1024.0
	for th in TREEHOUSES:
		var ox := level_w * float(th[0])
		var w: float = th[1]
		add_floor(ox, floor_y - TREE_H, w, "wood", true, true)
		add_ladder(ox + 12.0, floor_y - TREE_H)
		reserve(Rect2(ox - 20.0, floor_y - TREE_H, w + 40.0, TREE_H))
		_spans.append([ox, ox + w])
		_pickup(PickupScript.AMMO if th[0] < 0.6 else PickupScript.HEALTH, Vector2(ox + w * 0.6, floor_y - TREE_H - 30.0))


func _pickup(kind: int, pos: Vector2) -> void:
	var p = PickupScript.new()
	p.kind = kind
	p.life = 100000.0
	main.add_child(p)
	p.setup(pos, Vector2.ZERO)


func build_effects() -> void:
	var fx := Decor.JungleFX.new()
	fx.vp = vp
	screen_layer.add_child(fx)


# SWINGER על הבמות (מתנדנדים משם), BLADES בין הבמות
func extra_spawns() -> void:
	for i in _spans.size():
		var s: Array = _spans[i]
		if i % 2 == 0:
			spawn(Registry.SWINGER, lerpf(float(s[0]), float(s[1]), 0.5), floor_y - TREE_H)
		elif i < _spans.size() - 1:
			spawn(Registry.BLADES, float(s[1]) + 280.0)
