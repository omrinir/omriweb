extends "res://levels/stage_base.gd"
# ============================================================
#  STAGE 33 - "SULFUR CRATER" (אזור רביעי - האנדים, שלב 6) - "THEY LEARNED THE FIRE"
#  מכרה גופרית על הר געש פעיל (effects/s33_decor.gd): לילה, ענן אפר אדום עם ברקים, להבות גופרית כחולות,
#  נחלי לבה, מחנה כורים נטוש ורכבל עם דליים. לכאן ברח SUPAY מהקרנבל (שלב 32).
#  ההר (Volcano): כל ~20-26 שניות "שואג" (אזהרה 4 שניות) ושולח גל אפר לוהט - מי שלא בתוך REFUGIO (Shelter) נפגע.
#    הזומבים "למדו": בזמן האזהרה גם הם רצים למחסים - צריך להילחם עליהם.
#  מלכודות: LavaPit (בורות לבה, pits()), Vent (פומרולות: להבה כחולה במחזור, VENTS).
#  קומה שנייה: מגדלי מיון גופרית מעץ (HOPPERS).
#  זומבים: AZUFRERO (סל גופרית: יורים מעל הראש -> לפיד כחול שמתפוצץ), CINDER (מתפורר לאפר וקם שוב - לכבות את הגחלת),
#          SMOKER (מסכי עשן שמסתירים את ההתקפה), רגילים, רצים.
#  בוס: SUPAY - הקרב האחרון (enemies/types/supay.gd, Game.level != 32): לא בורח. בחצי חיים - אש גופרית כחולה.
#  לשנות: SHELTERS, VENTS, HOPPERS, TIER, LAVA_PITS, zombie_weights().
# ============================================================

const Decor := preload("res://effects/s33_decor.gd")
const PickupScript := preload("res://pickup.gd")

const SOUNDS := {
	"v33_rumble": {"drive": 2.0, "layers": [["N", 0, 0, 0.0, 4.0, 1.0, 0.0, 0.9, 0.03, 0], ["S", 38, 30, 0.0, 4.0, 1.0, 0.0, 0.6, 1.0, 0.05]]},
	"v33_surge": {"drive": 1.8, "layers": [["N", 0, 0, 0.0, 3.0, 0.1, 0.0, 1.0, 0.12, 0], ["S", 55, 35, 0.0, 3.0, 0.1, 0.0, 0.5, 1.0, 0.04]]},
	"v33_whoosh": [["N", 0, 0, 0.0, 0.6, 0.05, 4.0, 0.6, 0.35, 0, 0.2], ["S", 200, 500, 0.0, 0.4, 0.05, 5.0, 0.12, 1.0, 0.1]],
}

const SHELTERS := [0.08, 0.21, 0.34, 0.47, 0.6, 0.73, 0.86]
const VENTS := 9
const HOPPERS := [[0.15, 260.0], [0.42, 300.0], [0.69, 260.0]]
const TIER := 140.0
const LAVA_PITS := 4
const HARDER := [1.0, 1.15, 1.3]

var _hoppers := []


func zombie_weights() -> Dictionary:
	return {Registry.AZUFRERO: 0.09, Registry.CINDER: 0.1, Registry.SMOKER: 0.05, 0: 0.44, 1: 0.32}


func zombie_density() -> float:
	return 1.0 * float(HARDER[clampi(Settings.difficulty, 0, 2)])


func generators() -> Array:
	return [["sulfur_sacks", 1.2], ["slag_cart", 0.8], ["lava_rocks", 1.0]]


func custom_gen(gname: String, x: float) -> float:
	if not gname in ["sulfur_sacks", "slag_cart", "lava_rocks"]:
		return 0.0
	var o := Decor.Obstacle.new()
	o.kind = gname
	o.seed_v = rng.randi()
	match gname:
		"sulfur_sacks":
			o.size = Vector2(rng.randf_range(70.0, 86.0), rng.randf_range(36.0, 42.0))
		"slag_cart":
			o.size = Vector2(rng.randf_range(70.0, 84.0), rng.randf_range(34.0, 40.0))
		_:
			o.size = Vector2(rng.randf_range(80.0, 100.0), rng.randf_range(38.0, 50.0))
	o.position = Vector2(x, floor_y)
	main.add_child(o)
	reserve(Rect2(x, floor_y - o.size.y, o.size.x, o.size.y))
	return o.size.x


func boss_kind() -> int:
	return Registry.SUPAY


func music() -> String:
	return "res://music/level1_total_war.mp3"


func world_tint() -> Color:
	return Color(1.0, 0.92, 0.88)


func fog() -> bool:
	return false


func pits() -> int:
	return LAVA_PITS


func build_background(layer: CanvasLayer) -> Node:
	var bg = Backdrop.new()
	bg.level_w = level_w
	bg.sky = func(ci: CanvasItem, v: Vector2, t: float):
		Decor.volcano_sky(ci, v, t)
	bg.add_layer(0.06, func(ci: CanvasItem, sc: float, v: Vector2, t: float):
		Decor.far_cones(ci, sc, v, 520.0, t))
	bg.add_layer(0.3, func(ci: CanvasItem, sc: float, v: Vector2, t: float):
		Decor.mid_camp(ci, sc, v, 610.0, t))
	bg.add_layer(0.62, func(ci: CanvasItem, sc: float, v: Vector2, t: float):
		Decor.near_rocks(ci, sc, v, 636.0, t))
	layer.add_child(bg)
	return bg


func build_world() -> void:
	main.add_child(Decor.Volcano.new())
	var pits_list: Array = main._pits.filter(func(p): return p.size() < 3)
	var x := 0.0
	for p in pits_list + [[level_w, 0.0]]:   # סלע + בורות לבה
		_ground(x, float(p[0]))
		if float(p[1]) > 0.0:
			var lp := Decor.LavaPit.new()
			lp.w = float(p[1])
			lp.depth = main.PIT_DEPTH
			lp._seed = rng.randi()
			add_world(lp, Vector2(float(p[0]), floor_y))
		x = float(p[0]) + float(p[1])
	var shelters := SHELTERS.duplicate()
	shelters.append((level_w - 760.0) / level_w)   # מחסה בזירת הבוס
	for f in shelters:   # מחסים (REFUGIO)
		var sx := level_w * float(f)
		while (not free_x(sx, 20.0) or main._in_pit(sx - 30.0, sx + 140.0, 10.0)) and sx < level_w - 400.0:
			sx += 40.0
		var sh := Decor.Shelter.new()
		sh.seed_v = rng.randi()
		add_world(sh, Vector2(sx, floor_y))
		reserve(Rect2(sx - 10.0, floor_y - 30.0, sh.w + 20.0, 30.0))
	for hp in HOPPERS:   # מגדלי מיון עם רציף
		var w: float = hp[1]
		var hx := level_w * float(hp[0])
		while main._in_pit(hx - 30.0, hx + w + 30.0, 10.0) and hx < level_w - 600.0:
			hx += 40.0
		var ho := Decor.Hopper.new()
		ho.w = w
		ho.tier = TIER
		add_world(ho, Vector2(hx, floor_y))
		var pf = add_floor(hx - 6.0, floor_y - TIER, w + 12.0, "wood", false, false)
		pf.visible = false
		add_ladder(hx + 14.0, floor_y - TIER)
		reserve(Rect2(hx - 10.0, floor_y - TIER, 50.0, TIER))
		_hoppers.append([hx, hx + w])
		_pickup(PickupScript.AMMO if hp[0] < 0.5 else PickupScript.HEALTH, Vector2(hx + w * 0.6, floor_y - TIER - 30.0))
	for i in VENTS:   # פומרולות
		var vx := rng.randf_range(level_w * 0.06, level_w - 600.0)
		if not free_x(vx, 30.0) or main._in_pit(vx - 40.0, vx + 40.0, 10.0):
			continue
		var vn := Decor.Vent.new()
		vn.phase = rng.randf_range(0.0, 5.0)
		add_world(vn, Vector2(vx, floor_y))
		reserve(Rect2(vx - 30.0, floor_y - 20.0, 60.0, 20.0))


func _ground(x0: float, x1: float) -> void:
	var x := x0
	while x < x1:
		var g := Decor.VolcGround.new()
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
	var fx := Decor.AshFX.new()
	fx.vp = vp
	fx.floor_y = floor_y
	screen_layer.add_child(fx)


# SMOKER עם חוליה מאחורי מסך העשן, AZUFRERO על המגדלים
func extra_spawns() -> void:
	for f in [0.28, 0.55, 0.8]:
		var sx := level_w * float(f)
		spawn(Registry.SMOKER, sx + 160.0)
		for k in 3:
			spawn(Registry.CINDER if k == 1 else 1, sx - float(k) * 50.0)
	for s in _hoppers:
		spawn(Registry.AZUFRERO, lerpf(float(s[0]), float(s[1]), 0.6), floor_y - TIER)
