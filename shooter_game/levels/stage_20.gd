extends "res://levels/stage_base.gd"
# ============================================================
#  STAGE 20 - "GREEN HELL" (אזור שלישי, שלב 2) - "THEY LEARNED TO BLEND IN"
#  עמוק יותר בג'ונגל: צמחייה צפופה בכל מקום - שיחים קדמיים שמסתירים דמויות (effects/s20_decor.gd),
#  שרכים ועשב מאחור, אותו רקע / קרקע / מכשולים / אפקטים כמו שלב 19 (effects/s19_decor.gd).
#  זומבים: GHILLIE (חליפת עלים - נראה כמו שיח, זוחל כשאתה לא מסתכל, קופא כשמכוונים אליו),
#          HANGED (תלוי בחבל תלייה מענף, מתנדנד ויורה באקדח - מקדים אותך), ואקראיים מהג'ונגל:
#          SWINGER, BLADES, LEAPER, AMBUSHER, STALKER, רגילים ורצים.
#  בוס: THE THICKET - GHILLIE ענק (enemies/types/ghillie.gd, מצב בוס).
#  לשנות: BUSH_GAP, HANGED_AT, TREEHOUSES, zombie_weights().
# ============================================================

const Decor := preload("res://effects/s19_decor.gd")
const Green := preload("res://effects/s20_decor.gd")
const PickupScript := preload("res://pickup.gd")

const TREEHOUSES := [[0.22, 320.0], [0.5, 300.0], [0.78, 340.0]]   # [מיקום יחסי, רוחב]
const TREE_H := 125.0
const HANGED_AT := [0.1, 0.17, 0.3, 0.37, 0.44, 0.58, 0.65, 0.71, 0.86, 0.92]   # איפה תלויים זומבים (יחסי)
const BUSH_GAP := Vector2(105.0, 190.0)
const HARDER := [1.0, 1.15, 1.3]

var _spans := []
var _bushes := []


func zombie_weights() -> Dictionary:
	return {Registry.GHILLIE: 0.24, Registry.SWINGER: 0.1, Registry.BLADES: 0.08, Registry.LEAPER: 0.1, Registry.AMBUSHER: 0.08,
		Registry.STALKER: 0.08, 0: 0.18, 1: 0.14}


func zombie_density() -> float:
	return 1.0 * float(HARDER[clampi(Settings.difficulty, 0, 2)])


func generators() -> Array:
	return [["log", 1.4], ["boulder", 1.2], ["stump", 1.0], ["ruin", 0.5]]


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
		"ruin":
			o.size = Vector2(rng.randf_range(54.0, 70.0), rng.randf_range(84.0, 100.0))
		_:
			o.size = Vector2(rng.randf_range(40.0, 56.0), rng.randf_range(26.0, 40.0))
	o.position = Vector2(x, floor_y)
	main.add_child(o)
	reserve(Rect2(x, floor_y - o.size.y, o.size.x, o.size.y))
	return o.size.x


func boss_kind() -> int:
	return Registry.GHILLIE


func music() -> String:
	return "res://music/level2_suspense.mp3"


func world_tint() -> Color:
	return Color(0.9, 0.97, 0.9)   # קצת יותר חשוך - עמוק בג'ונגל


func fog() -> bool:
	return false


func pits() -> int:
	return 0


func _in_tree(x: float) -> bool:
	for s in _spans:
		if x > float(s[0]) - 30.0 and x < float(s[1]) + 30.0:
			return true
	return false


# ---- רקע: אותו ג'ונגל כמו שלב 19 ----
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


# ---- העולם: קרקע, שרכים מאחור, שיחים מלפנים, במות עץ ----
func build_world() -> void:
	var x := 0.0
	while x < level_w:
		var g := Decor.JungleGround.new()
		g.w = minf(1024.0, level_w - x)
		g.depth = main.floor_thickness
		g.seed_v = rng.randi()
		add_world(g, Vector2(x, floor_y))
		var u := Green.Undergrowth.new()
		u.w = g.w
		u.seed_v = rng.randi()
		add_world(u, Vector2(x, floor_y))
		x += 1024.0
	for th in TREEHOUSES:
		var ox := level_w * float(th[0])
		var w: float = th[1]
		add_floor(ox, floor_y - TREE_H, w, "wood", true, true)
		add_ladder(ox + 12.0, floor_y - TREE_H)
		reserve(Rect2(ox - 20.0, floor_y - TREE_H, w + 40.0, TREE_H))
		_spans.append([ox, ox + w])
		_pickup(PickupScript.AMMO if th[0] < 0.6 else PickupScript.HEALTH, Vector2(ox + w * 0.6, floor_y - TREE_H - 30.0))
	# שיחים קדמיים לאורך כל השלב
	var bx := 380.0
	while bx < level_w - 300.0:
		var b := Green.Bush.new()
		b.w = rng.randf_range(90.0, 170.0)
		b.h = rng.randf_range(70.0, 135.0)
		b.seed_v = rng.randi()
		add_world(b, Vector2(bx, floor_y + 2.0))
		_bushes.append(b)
		bx += rng.randf_range(BUSH_GAP.x, BUSH_GAP.y)
	# וילונות ליאנות מהצמרת
	var cx := rng.randf_range(100.0, 400.0)
	while cx < level_w:
		var c := Green.Curtain.new()
		c.w = rng.randf_range(160.0, 280.0)
		c.drop = rng.randf_range(170.0, 280.0)
		c.seed_v = rng.randi()
		add_world(c, Vector2(cx, floor_y - 515.0))
		cx += rng.randf_range(380.0, 640.0)
	var fader := Green.BushFader.new()
	fader.bushes = _bushes
	main.add_child(fader)


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


# תלויים מענפים לאורך השלב (לא מעל במות העץ), ו-GHILLIE בחלק מהשיחים
func extra_spawns() -> void:
	for f in HANGED_AT:
		var hx := level_w * float(f) + rng.randf_range(-60.0, 60.0)
		if _in_tree(hx):
			hx += 420.0
		spawn(Registry.HANGED, hx)
	for i in _bushes.size():
		if i % 8 == 3:
			spawn(Registry.GHILLIE, _bushes[i].position.x)
