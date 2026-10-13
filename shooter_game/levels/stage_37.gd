extends "res://levels/stage_base.gd"
# ============================================================
#  STAGE 37 - "FAVELA HEIGHTS" (אזור חמישי - דרום-מזרח, שלב 1) - "THEY LEARNED OUR STREETS"
#  פאבלה בריו בשקיעה (effects/s37_decor.gd): ישו הגואל, הר הסוכר, בתים צבעוניים מוערמים, עפיפונים, חוטי חשמל.
#  (המשך הסיפור: אחרי האנדים הגיבור יורד לחוף - הערים הענקיות.)
#  קומה שנייה: גגות הלאז'ה (LAJES) עם סולמות. על כל גג מכל מים (WaterTank).
#  מלכודות: LiveWire - חוט חשמל גנוב: ניצוצות (אזהרה) ואז קשת לקרקע. ירייה בקופסה על העמוד מנתקת אותו (וקצר לזומבים).
#           WaterTank - יורים במכל -> מים שוטפים את הזומבים ושלולית. חוט מעל שלולית = שלולית מחושמלת! (TANK_WIRE)
#  זומבים: KITE (עפיפון עם חוט חותך), CAPOEIRA (מתחמק מיריות), GRAFFITI (מחכה שתטען ומרסס בעיניים), REVIVER, רגילים, רצים.
#  בוס נייח: O DONO DO MORRO (enemies/types/dono.gd) על גג הבית הגבוה בסוף (BOSS_TIER) - צרורות, זיקוקים, מתכופף.
#  לשנות: LAJES, TIER, WIRES, TANK_WIRE, BOSS_TIER, CREWS, zombie_weights().
# ============================================================

const Decor := preload("res://effects/s37_decor.gd")
const PickupScript := preload("res://pickup.gd")

const SOUNDS := {
	"fv_buzz": [["Q", 120, 120, 0.0, 0.9, 0.05, 1.0, 0.18, 1.0, 0], ["N", 0, 0, 0.0, 0.9, 0.05, 1.0, 0.15, 0.9, 0, 0.3]],
	"fv_zap": [["N", 0, 0, 0.0, 0.5, 0.0, 6.0, 0.7, 0.9, 0, 0.2], ["Q", 90, 60, 0.0, 0.5, 0.0, 6.0, 0.3, 1.0, 0]],
	"fv_short": [["N", 0, 0, 0.0, 0.4, 0.0, 8.0, 0.9, 0.8, 0, 0.3], ["S", 2000, 200, 0.0, 0.3, 0.0, 10.0, 0.3, 1.0, 0]],
	"fv_splash": [["N", 0, 0, 0.0, 1.0, 0.05, 2.0, 0.8, 0.3, 0], ["S", 200, 80, 0.0, 0.5, 0.0, 5.0, 0.3, 1.0, 0]],
}

const LAJES := [[0.13, 240.0], [0.34, 280.0], [0.55, 240.0], [0.77, 260.0]]
const TIER := 130.0
const TANK_WIRE := [1, 2]           # באילו גגות יש חוט חשמל בדיוק מתחת לשפך של המכל
const WIRES := [0.22, 0.45, 0.66, 0.88]
const CREWS := [0.25, 0.48, 0.7]
const BOSS_TIER := 150.0
const HARDER := [1.0, 1.15, 1.3]

var _lajes := []


func zombie_weights() -> Dictionary:
	return {Registry.KITE: 0.04, Registry.CAPOEIRA: 0.05, Registry.GRAFFITI: 0.04, Registry.REVIVER: 0.03, 0: 0.5, 1: 0.34}


func zombie_density() -> float:
	return 1.0 * float(HARDER[clampi(Settings.difficulty, 0, 2)])


func generators() -> Array:
	return [["moto", 1.0], ["trash_bags", 1.0], ["bar_table", 0.7]]


func custom_gen(gname: String, x: float) -> float:
	if not gname in ["moto", "trash_bags", "bar_table"]:
		return 0.0
	var o := Decor.Obstacle.new()
	o.kind = gname
	o.seed_v = rng.randi()
	match gname:
		"moto":
			o.size = Vector2(rng.randf_range(78.0, 88.0), rng.randf_range(36.0, 42.0))
		"trash_bags":
			o.size = Vector2(rng.randf_range(60.0, 76.0), rng.randf_range(30.0, 38.0))
		_:
			o.size = Vector2(rng.randf_range(84.0, 96.0), rng.randf_range(34.0, 40.0))
	o.position = Vector2(x, floor_y)
	main.add_child(o)
	reserve(Rect2(x, floor_y - o.size.y, o.size.x, o.size.y))
	return o.size.x


func boss_kind() -> int:
	return Registry.DONO


func music() -> String:
	return "res://music/level1_zombie_joyride.ogg"


func world_tint() -> Color:
	return Color(1.0, 0.93, 0.86)


func fog() -> bool:
	return false


func pits() -> int:
	return 0


func build_background(layer: CanvasLayer) -> Node:
	var bg = Backdrop.new()
	bg.level_w = level_w
	bg.sky = func(ci: CanvasItem, v: Vector2, t: float):
		Decor.rio_sky(ci, v, t)
	bg.add_layer(0.05, func(ci: CanvasItem, sc: float, v: Vector2, t: float):
		Decor.far_rio(ci, sc, v, 560.0, t))
	bg.add_layer(0.25, func(ci: CanvasItem, sc: float, v: Vector2, t: float):
		Decor.mid_favela(ci, sc, v, 620.0, t))
	bg.add_layer(0.6, func(ci: CanvasItem, sc: float, v: Vector2, t: float):
		Decor.near_houses(ci, sc, v, 645.0, t))
	layer.add_child(bg)
	return bg


func build_world() -> void:
	var x := 0.0
	while x < level_w:
		var g := Decor.FavelaGround.new()
		g.w = minf(1024.0, level_w - x)
		g.depth = main.floor_thickness
		g.seed_v = rng.randi()
		add_world(g, Vector2(x, floor_y))
		x += 1024.0
	for i in LAJES.size():   # בתים עם גג שטוח + מכל מים
		var l: Array = LAJES[i]
		var w: float = l[1]
		var dx := level_w * float(l[0])
		_laje(dx, w, TIER)
		if i % 2 == 0:
			_pickup(PickupScript.AMMO, Vector2(dx + w * 0.4, floor_y - TIER - 30.0))
		var tank := Decor.WaterTank.new()
		tank.floor_y = floor_y
		var tx := dx + w * 0.72
		add_world(tank, Vector2(tx, floor_y - TIER - 4.0))
		if i in TANK_WIRE:   # חוט חשמל בדיוק מתחת לשפך - שילוב: מים + חשמל
			_wire(tx - 130.0)
		_lajes.append([dx, dx + w])
	for f in WIRES:
		var wx := level_w * float(f)
		var ok := true
		for l in _lajes:
			if wx + 260.0 > float(l[0]) - 40.0 and wx < float(l[1]) + 40.0:
				ok = false
		if ok:
			_wire(wx)
	# הבית הגבוה של הבוס
	var bx := level_w - 720.0
	_laje(bx - 150.0, 300.0, BOSS_TIER)
	main.set_meta("boss_x", bx)
	main.set_meta("boss_y", floor_y - BOSS_TIER)


func _laje(dx: float, w: float, tier: float) -> void:
	var lj := Decor.Laje.new()
	lj.w = w
	lj.tier = tier
	lj.seed_v = rng.randi()
	add_world(lj, Vector2(dx, floor_y))
	var pf = add_floor(dx - 4.0, floor_y - tier, w + 8.0, "concrete", false, false)
	pf.visible = false
	add_ladder(dx + 10.0, floor_y - tier)
	reserve(Rect2(dx - 10.0, floor_y - tier, 50.0, tier))


func _wire(wx: float) -> void:
	var lw := Decor.LiveWire.new()
	lw.w = 260.0
	add_world(lw, Vector2(wx, floor_y))


func _pickup(kind: int, pos: Vector2) -> void:
	var p = PickupScript.new()
	p.kind = kind
	p.life = 100000.0
	main.add_child(p)
	p.setup(pos, Vector2.ZERO)


func build_effects() -> void:
	var fx := Decor.FavelaFX.new()
	fx.vp = vp
	screen_layer.add_child(fx)


# חבורות: CAPOEIRA מלפנים, GRAFFITI באמצע, KITE מאחור (על גג אם יש)
func extra_spawns() -> void:
	for f in CREWS:
		var cx := level_w * float(f)
		spawn(Registry.CAPOEIRA, cx)
		spawn(1, cx + 40.0)
		spawn(Registry.GRAFFITI, cx + 200.0)
		spawn(Registry.KITE, cx + 380.0)
	for i in _lajes.size():
		if i % 2 == 1:
			var s: Array = _lajes[i]
			spawn(Registry.KITE, lerpf(float(s[0]), float(s[1]), 0.4), floor_y - TIER)
