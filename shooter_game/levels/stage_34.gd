extends "res://levels/stage_base.gd"
# ============================================================
#  STAGE 34 - "OBSERVATORY" (אזור רביעי - האנדים, שלב 7) - "THEY LEARNED TO WATCH"
#  מדבר אטקמה בלילה (effects/s34_decor.gd): שביל החלב וענני מגלן, מערך צלחות רדיו, כיפות מצפה עם לייזרים צהובים,
#  קרום מלח סדוק, קקטוסים מנורתיים.
#  קומה שנייה: המרפסות של כיפות המצפה (DOMES).
#  מלכודת: GuideLaser - כל כיפה סורקת את הקרקע לפניה בקרן לייזר (קו אדום מקווקו = אזהרה).
#  זומבים: REVIVER (מחזיר זומבים מתים לחיים - עם הילה כחולה), SPOTTER (פנס: מסמן אותך לכולם), PANEL (מראה שמחזירה יריות),
#          רגילים, רצים. צוותים (TEAMS): REVIVER מאחורי קבוצה.
#  בוס נייח: THE DISH (enemies/types/dish.gd) - יורה כדורי אות, מניפות, ופצצות פלזמה מעל מחסות.
#  לשנות: DOMES, TIER, TEAMS, zombie_weights().
# ============================================================

const Decor := preload("res://effects/s34_decor.gd")
const PickupScript := preload("res://pickup.gd")

const SOUNDS := {
	"o34_laser": [["S", 900, 1100, 0.0, 1.3, 0.05, 0.5, 0.12, 1.0, 0.02], ["N", 0, 0, 0.0, 1.3, 0.05, 0.5, 0.25, 0.5, 0, 0.3]],
}

const DOMES := [[0.14, 220.0], [0.38, 240.0], [0.62, 220.0], [0.84, 240.0]]
const TIER := 130.0
const TEAMS := [0.25, 0.5, 0.74]
const HARDER := [1.0, 1.15, 1.3]

var _domes := []


func zombie_weights() -> Dictionary:
	return {Registry.REVIVER: 0.05, Registry.SPOTTER: 0.05, Registry.PANEL: 0.08, 0: 0.48, 1: 0.34}


func zombie_density() -> float:
	return 1.0 * float(HARDER[clampi(Settings.difficulty, 0, 2)])


func generators() -> Array:
	return [["flight_cases", 1.2], ["rover", 0.7], ["solar_rack", 0.9]]


func custom_gen(gname: String, x: float) -> float:
	if not gname in ["flight_cases", "rover", "solar_rack"]:
		return 0.0
	var o := Decor.Obstacle.new()
	o.kind = gname
	o.seed_v = rng.randi()
	match gname:
		"flight_cases":
			o.size = Vector2(rng.randf_range(70.0, 84.0), rng.randf_range(34.0, 42.0))
		"rover":
			o.size = Vector2(rng.randf_range(96.0, 110.0), rng.randf_range(44.0, 52.0))
		_:
			o.size = Vector2(rng.randf_range(84.0, 100.0), rng.randf_range(30.0, 36.0))
	o.position = Vector2(x, floor_y)
	main.add_child(o)
	reserve(Rect2(x, floor_y - o.size.y, o.size.x, o.size.y))
	return o.size.x


func boss_kind() -> int:
	return Registry.DISH


func music() -> String:
	return "res://music/level2_suspense.mp3"


func world_tint() -> Color:
	return Color(0.8, 0.84, 1.0)


func fog() -> bool:
	return false


func pits() -> int:
	return 0


func build_background(layer: CanvasLayer) -> Node:
	var bg = Backdrop.new()
	bg.level_w = level_w
	bg.sky = func(ci: CanvasItem, v: Vector2, t: float):
		Decor.atacama_sky(ci, v, t)
	bg.add_layer(0.05, func(ci: CanvasItem, sc: float, v: Vector2, t: float):
		Decor.far_andes(ci, sc, v, 520.0, t))
	bg.add_layer(0.25, func(ci: CanvasItem, sc: float, v: Vector2, t: float):
		Decor.mid_array(ci, sc, v, 600.0, t))
	bg.add_layer(0.6, func(ci: CanvasItem, sc: float, v: Vector2, t: float):
		Decor.near_desert(ci, sc, v, 638.0, t))
	layer.add_child(bg)
	return bg


func build_world() -> void:
	var x := 0.0
	while x < level_w:
		var g := Decor.SaltGround.new()
		g.w = minf(1024.0, level_w - x)
		g.depth = main.floor_thickness
		g.seed_v = rng.randi()
		add_world(g, Vector2(x, floor_y))
		x += 1024.0
	for d in DOMES:   # כיפות מצפה: מרפסת + לייזר שסורק לפניהן
		var w: float = d[1]
		var dx := level_w * float(d[0])
		var dm := Decor.Dome.new()
		dm.w = w
		dm.tier = TIER
		add_world(dm, Vector2(dx, floor_y))
		var pf = add_floor(dx - 10.0, floor_y - TIER, w + 20.0, "steel", false, false)
		pf.visible = false
		add_ladder(dx + 14.0, floor_y - TIER)
		reserve(Rect2(dx - 10.0, floor_y - TIER, 50.0, TIER))
		_domes.append([dx, dx + w])
		_pickup(PickupScript.AMMO if d[0] < 0.5 else PickupScript.HEALTH, Vector2(dx + w * 0.6, floor_y - TIER - 30.0))
		var gl := Decor.GuideLaser.new()
		gl.origin = dm.laser_origin()
		gl.x0 = dx + w + 40.0
		add_world(gl, Vector2(gl.x0, floor_y))


func _pickup(kind: int, pos: Vector2) -> void:
	var p = PickupScript.new()
	p.kind = kind
	p.life = 100000.0
	main.add_child(p)
	p.setup(pos, Vector2.ZERO)


func build_effects() -> void:
	var fx := Decor.NightFX.new()
	fx.vp = vp
	screen_layer.add_child(fx)


# צוותים: PANEL מלפנים, 2 זומבים, REVIVER מאחור. SPOTTER על המרפסות
func extra_spawns() -> void:
	for f in TEAMS:
		var tx := level_w * float(f)
		spawn(Registry.PANEL, tx - 60.0)
		spawn(0, tx)
		spawn(1, tx + 50.0)
		spawn(Registry.REVIVER, tx + 220.0)
	for i in _domes.size():
		if i % 2 == 1:
			var s: Array = _domes[i]
			spawn(Registry.SPOTTER, lerpf(float(s[0]), float(s[1]), 0.6), floor_y - TIER)
