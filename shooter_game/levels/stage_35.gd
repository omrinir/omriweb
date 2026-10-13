extends "res://levels/stage_base.gd"
# ============================================================
#  STAGE 35 - "SKULL GLACIER" (אזור רביעי - האנדים, שלב 8) - "THEY LEARNED TO HIDE"
#  קרחון אנדי גבוה ביום קר ובהיר (effects/s35_decor.gd): שמש עם הילת קרח וכלבי שמש, פסגות מושלגות, חומת סרקים כחולה
#  עם מערות קרח וגולגלת ענק כלואה, שדה פניטנטס. משלחת טיפוס שנעלמה - והם עדיין כאן.
#  קומה שנייה: מדפי קרח תלויים (SHELVES) עם סולמות חבלים.
#  מלכודות: Icicles - נטיפים ענקיים מתחת למדפים (עוברים מתחת -> נופלים. ירייה בנטיף מפילה אותו על זומבים).
#           GlareIce - משטחי קרח חלקים (מחליקים).
#  זומבים: ENCASED (קפואים בגושי קרח - בין גושי קרח "ריקים"), AXEMAN (גרזן קרח בומרנג), AVALANCHER (מפולות שלג),
#          REVIVER, רגילים, רצים.
#  בוס נייח: ICE TITAN (enemies/types/ice_titan.gd) - נשיפת נטיפים, גל קוצי קרח, גושי קרח, מגן על הלב.
#  לשנות: SHELVES, TIER, GLARE, FROZEN_GROUPS, TEAMS, zombie_weights().
# ============================================================

const Decor := preload("res://effects/s35_decor.gd")
const PickupScript := preload("res://pickup.gd")

const SOUNDS := {
	"ic_crack": [["N", 0, 0, 0.0, 0.3, 0.0, 10.0, 0.5, 0.8, 0, 0.6], ["S", 2000, 1600, 0.0, 0.2, 0.0, 15.0, 0.2, 1.0, 0.05]],
	"ic_shatter": [["N", 0, 0, 0.0, 0.4, 0.0, 8.0, 0.8, 0.9, 0, 0.4], ["S", 3200, 1500, 0.0, 0.3, 0.0, 12.0, 0.3, 1.0, 0], ["S", 4100, 2600, 0.05, 0.2, 0.0, 15.0, 0.2, 1.0, 0]],
}

const SHELVES := [[0.15, 260.0], [0.41, 300.0], [0.66, 260.0]]
const TIER := 140.0
const GLARE := [[0.07, 220.0], [0.29, 240.0], [0.53, 200.0], [0.79, 260.0]]
const FROZEN_GROUPS := [0.11, 0.34, 0.49, 0.73, 0.88]
const TEAMS := [0.24, 0.58, 0.82]
const HARDER := [1.0, 1.15, 1.3]

var _shelves := []


func zombie_weights() -> Dictionary:
	return {Registry.ENCASED: 0.04, Registry.AXEMAN: 0.07, Registry.AVALANCHER: 0.03, Registry.REVIVER: 0.04, 0: 0.5, 1: 0.32}


func zombie_density() -> float:
	return 1.0 * float(HARDER[clampi(Settings.difficulty, 0, 2)])


func generators() -> Array:
	return [["ice_cube", 1.1], ["sled", 0.8], ["old_tent", 0.7]]


func custom_gen(gname: String, x: float) -> float:
	if not gname in ["ice_cube", "sled", "old_tent"]:
		return 0.0
	var sz := Vector2(rng.randf_range(60.0, 74.0), rng.randf_range(44.0, 54.0))
	if gname == "sled":
		sz = Vector2(rng.randf_range(90.0, 104.0), rng.randf_range(32.0, 38.0))
	elif gname == "old_tent":
		sz = Vector2(rng.randf_range(84.0, 96.0), rng.randf_range(40.0, 48.0))
	_obstacle(gname, x, sz)
	return sz.x


func _obstacle(kind: String, x: float, sz: Vector2) -> void:
	var o := Decor.Obstacle.new()
	o.kind = kind
	o.seed_v = rng.randi()
	o.size = sz
	o.position = Vector2(x, floor_y)
	main.add_child(o)
	reserve(Rect2(x, floor_y - sz.y, sz.x, sz.y))


func boss_kind() -> int:
	return Registry.ICE_TITAN


func music() -> String:
	return "res://music/level2_suspense.mp3"


func world_tint() -> Color:
	return Color(0.94, 0.97, 1.0)


func fog() -> bool:
	return false


func pits() -> int:
	return 0


func build_background(layer: CanvasLayer) -> Node:
	var bg = Backdrop.new()
	bg.level_w = level_w
	bg.sky = func(ci: CanvasItem, v: Vector2, t: float):
		Decor.glacier_sky(ci, v, t)
	bg.add_layer(0.05, func(ci: CanvasItem, sc: float, v: Vector2, t: float):
		Decor.far_peaks(ci, sc, v, 520.0, t))
	bg.add_layer(0.25, func(ci: CanvasItem, sc: float, v: Vector2, t: float):
		Decor.mid_seracs(ci, sc, v, 610.0, t))
	bg.add_layer(0.6, func(ci: CanvasItem, sc: float, v: Vector2, t: float):
		Decor.near_penitents(ci, sc, v, 640.0, t))
	layer.add_child(bg)
	return bg


func build_world() -> void:
	var x := 0.0
	while x < level_w:
		var g := Decor.GlacierGround.new()
		g.w = minf(1024.0, level_w - x)
		g.depth = main.floor_thickness
		g.seed_v = rng.randi()
		add_world(g, Vector2(x, floor_y))
		x += 1024.0
	var shelves := SHELVES.duplicate()
	shelves.append([(level_w - 1180.0) / level_w, 220.0])   # מדף בזירת הבוס (מקום לברוח מגל הקוצים)
	for s in shelves:   # מדפי קרח: קומה + סולם + נטיפים מתחת
		var w: float = s[1]
		var dx := level_w * float(s[0])
		var sh := Decor.IceShelf.new()
		sh.w = w
		sh.tier = TIER
		sh.seed_v = rng.randi()
		add_world(sh, Vector2(dx, floor_y))
		var pf = add_floor(dx - 14.0, floor_y - TIER, w + 28.0, "steel", false, false)
		pf.visible = false
		add_ladder(dx + 4.0, floor_y - TIER)
		reserve(Rect2(dx - 14.0, floor_y - TIER, 50.0, TIER))
		reserve(Rect2(dx + w - 60.0, floor_y - TIER, 50.0, TIER))   # עמוד הקרח
		_shelves.append([dx, dx + w])
		var ic := Decor.Icicles.new()
		ic.w = w - 70.0
		ic.drop = TIER - 20.0
		add_world(ic, Vector2(dx + 24.0, floor_y - TIER + 20.0))
		if float(s[0]) < 0.8:
			_pickup(PickupScript.AMMO if float(s[0]) < 0.3 else PickupScript.HEALTH, Vector2(dx + w * 0.55, floor_y - TIER - 30.0))
	for gl in GLARE:   # משטחי קרח חלקים
		var gx := level_w * float(gl[0])
		var ge := Decor.GlareIce.new()
		ge.w = gl[1]
		add_world(ge, Vector2(gx, floor_y))
		reserve(Rect2(gx, floor_y - 40.0, float(gl[1]), 40.0))
	for f in FROZEN_GROUPS:   # גושי קרח "ריקים" ליד הקפואים (שלא תדע מי חי)
		var fx := level_w * float(f)
		for q in 2:
			var ox := fx - 140.0 + float(q) * 260.0
			if free_x(ox, 60.0):
				_obstacle("ice_cube", ox, Vector2(rng.randf_range(58.0, 70.0), rng.randf_range(46.0, 54.0)))


func _pickup(kind: int, pos: Vector2) -> void:
	var p = PickupScript.new()
	p.kind = kind
	p.life = 100000.0
	main.add_child(p)
	p.setup(pos, Vector2.ZERO)


func build_effects() -> void:
	var fx := Decor.GlacierFX.new()
	fx.vp = vp
	screen_layer.add_child(fx)


# קפואים בקבוצות (בין גושי קרח ריקים), AVALANCHER מאחורי קבוצה, AXEMAN על המדפים
func extra_spawns() -> void:
	for f in FROZEN_GROUPS:
		var fx := level_w * float(f)
		spawn(Registry.ENCASED, fx - 40.0)
		spawn(Registry.ENCASED, fx + 60.0)
	for f in TEAMS:
		var tx := level_w * float(f)
		spawn(0, tx - 40.0)
		spawn(1, tx)
		spawn(Registry.AVALANCHER, tx + 260.0)
	for i in _shelves.size():
		var s: Array = _shelves[i]
		spawn(Registry.AXEMAN if i % 2 == 0 else Registry.REVIVER, lerpf(float(s[0]), float(s[1]), 0.5), floor_y - TIER)
