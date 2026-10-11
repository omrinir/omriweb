extends "res://levels/stage_base.gd"
# ============================================================
#  STAGE 24 - "BURNING FIELDS" (אזור שלישי, שלב 6) - "THEY LEARNED TO PLAY DEAD... AGAIN"
#  שדות חיטה בוערים בלילה (effects/s24_decor.gd): אסם אדום, ממגורות, טחנת רוח, קו אש באופק, שיבולים.
#  קומה שנייה: מתבני קש מעץ (HAYLOFTS) עם סולמות - משם ה-TORCH זורק.
#  שדות דחלילים (SCARECROW_FIELDS): כמה דחלילים על עמודים - חלקם זומבים (SCARECROW). לאמיתיים יש עורב.
#  מלכודת: BearTrap - מלכודות דובים חבויות בעשב (BEAR_TRAPS). שיניים מנצנצות. נתפסים -> A/D מהר. זומבים נתקעים בהן.
#  זומבים: SCARECROW (מתחזה לדחליל, קופץ אחרי שעברת, מגל), TORCH (בוער, בקבוקי תבערה, מתפוצץ באש), רגילים, רצים, LEAPER.
#  בוס: THE PYRE - TORCH ענק (enemies/types/torch.gd, מצב בוס).
#  לשנות: HAYLOFTS, TIER, SCARECROW_FIELDS, BEAR_TRAPS, zombie_weights().
# ============================================================

const Decor := preload("res://effects/s24_decor.gd")
const PickupScript := preload("res://pickup.gd")

const SOUNDS := {
	"s24_snap": [["N", 0, 0, 0.0, 0.03, 0.0, 200.0, 1.4, 1.0, 0], ["S", 900, 500, 0.0, 0.12, 0.0, 30.0, 0.5, 1.0, 0], ["C", 0, 0, 0.0, 0.15, 0.0, 20.0, 0.7, 1.0, 0]],
}

const HAYLOFTS := [[0.15, 380.0], [0.37, 420.0], [0.6, 380.0], [0.82, 420.0]]   # [מיקום יחסי, רוחב]
const TIER := 140.0
const SCARECROW_FIELDS := [0.1, 0.27, 0.47, 0.69, 0.9]    # בכל שדה 4 עמודים, 1-2 מהם זומבים
const BEAR_TRAPS := [0.07, 0.19, 0.33, 0.42, 0.53, 0.64, 0.75, 0.86, 0.95]
const HARDER := [1.0, 1.15, 1.3]

var _spans := []
var _fields := []            # [x, [זומבי?...]]


func zombie_weights() -> Dictionary:
	return {Registry.TORCH: 0.13, Registry.SCARECROW: 0.06, Registry.LEAPER: 0.08, 0: 0.4, 1: 0.3}


func zombie_density() -> float:
	return 1.0 * float(HARDER[clampi(Settings.difficulty, 0, 2)])


func generators() -> Array:
	return [["bale", 1.6], ["fence", 1.0], ["cart", 0.6]]


func custom_gen(gname: String, x: float) -> float:
	if not gname in ["bale", "fence", "cart"]:
		return 0.0
	var o := Decor.Obstacle.new()
	o.kind = gname
	o.seed_v = rng.randi()
	match gname:
		"bale":
			var h := rng.randf_range(40.0, 50.0)
			o.size = Vector2(h if rng.randf() < 0.5 else h * 1.9, h)
		"fence":
			o.size = Vector2(rng.randf_range(80.0, 110.0), rng.randf_range(34.0, 40.0))
		_:
			o.size = Vector2(rng.randf_range(90.0, 110.0), rng.randf_range(56.0, 66.0))
	o.position = Vector2(x, floor_y)
	main.add_child(o)
	reserve(Rect2(x, floor_y - o.size.y, o.size.x, o.size.y))
	return o.size.x


func boss_kind() -> int:
	return Registry.TORCH


func music() -> String:
	return "res://music/level1_total_war.mp3"


func world_tint() -> Color:
	return Color(1.0, 0.9, 0.84)


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
		Decor.night_sky(ci, v, t)
	bg.add_layer(0.08, func(ci: CanvasItem, sc: float, v: Vector2, t: float):
		Decor.far_fire(ci, sc, v, 540.0, t))
	bg.add_layer(0.3, func(ci: CanvasItem, sc: float, v: Vector2, t: float):
		Decor.mid_farm(ci, sc, v, 605.0, t))
	bg.add_layer(0.62, func(ci: CanvasItem, sc: float, v: Vector2, t: float):
		Decor.near_wheat(ci, sc, v, 630.0, t))
	layer.add_child(bg)
	return bg


func build_world() -> void:
	var x := 0.0
	while x < level_w:
		var g := Decor.FieldGround.new()
		g.w = minf(1024.0, level_w - x)
		g.depth = main.floor_thickness
		g.seed_v = rng.randi()
		add_world(g, Vector2(x, floor_y))
		x += 1024.0
	for hl in HAYLOFTS:   # מתבני קש
		var ox := level_w * float(hl[0])
		var w: float = hl[1]
		add_floor(ox, floor_y - TIER, w, "wood", true, true)
		add_ladder(ox + 12.0, floor_y - TIER)
		reserve(Rect2(ox - 20.0, floor_y - TIER, w + 40.0, TIER))
		_spans.append([ox, ox + w])
		_pickup(PickupScript.AMMO if hl[0] < 0.5 else PickupScript.HEALTH, Vector2(ox + w * 0.6, floor_y - TIER - 30.0))
	for f in SCARECROW_FIELDS:   # שדות דחלילים: חלקם זומבים
		var fx := level_w * float(f)
		var real := [false, false, false, false]
		real[rng.randi() % 4] = true
		if rng.randf() < 0.5:
			real[rng.randi() % 4] = true
		for i in 4:
			var px := fx + float(i) * 95.0
			if not real[i]:
				var sc := Decor.Scarecrow.new()
				sc.seed_v = rng.randi()
				sc.crow = rng.randf() < 0.85
				add_world(sc, Vector2(px, floor_y))
		_fields.append([fx, real])
		reserve(Rect2(fx - 40.0, floor_y - 100.0, 4.0 * 95.0 + 40.0, 100.0))
	for f in BEAR_TRAPS:   # מלכודות דובים
		var tx := level_w * float(f)
		while not free_x(tx, 30.0) and tx < level_w - 200.0:
			tx += 40.0
		var bt := Decor.BearTrap.new()
		add_world(bt, Vector2(tx, floor_y))
		reserve(Rect2(tx - 30.0, floor_y - 30.0, 60.0, 30.0))


func _pickup(kind: int, pos: Vector2) -> void:
	var p = PickupScript.new()
	p.kind = kind
	p.life = 100000.0
	main.add_child(p)
	p.setup(pos, Vector2.ZERO)


func build_effects() -> void:
	var fx := Decor.FieldFX.new()
	fx.vp = vp
	screen_layer.add_child(fx)


# SCARECROW בשדות הדחלילים, TORCH על המתבנים
func extra_spawns() -> void:
	for fl in _fields:
		for i in 4:
			if fl[1][i]:
				var z := spawn(Registry.SCARECROW, float(fl[0]) + float(i) * 95.0)
				if z != null:
					z._dir = -1.0 if rng.randf() < 0.5 else 1.0
	for i in _spans.size():
		var s: Array = _spans[i]
		if i % 2 == 0:
			spawn(Registry.TORCH, lerpf(float(s[0]), float(s[1]), 0.6), floor_y - TIER)
