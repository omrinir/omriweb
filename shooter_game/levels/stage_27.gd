extends "res://levels/stage_base.gd"
# ============================================================
#  STAGE 27 - "PLATEAU GATE" (אזור שלישי, שלב 9 - סוף האזור) - "THEY LEARNED TO HOLD THE LINE"
#  ההמשך של שלב 26: יוצאים מהמנהרה של הבונקר (TunnelExit) אל מחסום הגבול בשחר (effects/s27_decor.gd).
#  חומת גבול, מגדלי שמירה עם זרקורים, קיפודים ותיל, הרי האנדים באופק (האזור הבא). בסוף - השער הענק.
#  מגדלי שמירה (TOWERS): קומה בגובה TIER עם סולם, צלף עליה, וזרקור.
#  מלכודת: Searchlight - אלומה שסורקת את הקרקע. נתפסת באור -> "SPOTTED!" -> פגז ארטילריה עליך.
#  זומבים: SNIPER (לייזר, מתכופף כשמכוונים אליו), SAPPER (מוקשים בדרך שלך), HANDLER (משחרר כלבים), רגילים, רצים.
#  בוס: THE GENERAL - הקרב האחרון בשער (enemies/types/general.gd: ארטילריה, ואז חרב "NO MORE RETREAT").
#  לשנות: TOWERS, TIER, zombie_weights().
# ============================================================

const Decor := preload("res://effects/s27_decor.gd")
const PickupScript := preload("res://pickup.gd")

const SOUNDS := {
	"s27_siren": [["S", 500, 900, 0.0, 0.6, 0.05, 1.0, 0.3, 0.7, 0], ["S", 900, 500, 0.6, 0.6, 0.0, 1.5, 0.3, 0.7, 0]],
}

const TOWERS := [0.14, 0.3, 0.46, 0.62, 0.78]   # מגדלי שמירה (יחסי)
const TOWER_W := 120.0
const TIER := 180.0
const HARDER := [1.0, 1.15, 1.3]

var _towers := []


func zombie_weights() -> Dictionary:
	return {Registry.SAPPER: 0.1, Registry.HANDLER: 0.07, Registry.SNIPER: 0.04, Registry.SHOVER: 0.04, Registry.LEAPER: 0.05, 0: 0.38, 1: 0.32}


func zombie_density() -> float:
	return 1.0 * float(HARDER[clampi(Settings.difficulty, 0, 2)])


func generators() -> Array:
	return [["bags", 1.6], ["hedgehog", 1.0], ["jeep", 0.6]]


func custom_gen(gname: String, x: float) -> float:
	if not gname in ["bags", "hedgehog", "jeep"]:
		return 0.0
	var o := Decor.Obstacle.new()
	o.kind = gname
	o.seed_v = rng.randi()
	match gname:
		"bags":
			o.size = Vector2(rng.randf_range(90.0, 120.0), rng.randf_range(38.0, 46.0))
		"hedgehog":
			o.size = Vector2(rng.randf_range(46.0, 54.0), rng.randf_range(44.0, 50.0))
		_:
			o.size = Vector2(rng.randf_range(110.0, 130.0), rng.randf_range(48.0, 56.0))
	o.position = Vector2(x, floor_y)
	main.add_child(o)
	reserve(Rect2(x, floor_y - o.size.y, o.size.x, o.size.y))
	return o.size.x


func boss_kind() -> int:
	return Registry.GENERAL


func music() -> String:
	return "res://music/level1_total_war.mp3"


func world_tint() -> Color:
	return Color(1.0, 0.95, 0.92)


func fog() -> bool:
	return false


func pits() -> int:
	return 0


func build_background(layer: CanvasLayer) -> Node:
	var bg = Backdrop.new()
	bg.level_w = level_w
	bg.sky = func(ci: CanvasItem, v: Vector2, t: float):
		Decor.dawn_sky(ci, v, t)
	bg.add_layer(0.05, func(ci: CanvasItem, sc: float, v: Vector2, t: float):
		Decor.far_andes(ci, sc, v, 520.0, t))
	bg.add_layer(0.3, func(ci: CanvasItem, sc: float, v: Vector2, t: float):
		Decor.mid_wall(ci, sc, v, 605.0, t))
	bg.add_layer(0.62, func(ci: CanvasItem, sc: float, v: Vector2, t: float):
		Decor.near_wire(ci, sc, v, 630.0, t))
	layer.add_child(bg)
	return bg


func build_world() -> void:
	var x := 0.0
	while x < level_w:
		var g := Decor.GateGround.new()
		g.w = minf(1024.0, level_w - x)
		g.depth = main.floor_thickness
		g.seed_v = rng.randi()
		add_world(g, Vector2(x, floor_y))
		x += 1024.0
	add_world(Decor.TunnelExit.new(), Vector2(40.0, floor_y))   # יוצאים מהמנהרה של הבונקר
	reserve(Rect2(-160.0, floor_y - 200.0, 520.0, 200.0))
	for f in TOWERS:   # מגדלי שמירה + זרקור
		var tx := level_w * float(f)
		var wt := Decor.Watchtower.new()
		wt.h = TIER
		wt.w = TOWER_W
		add_world(wt, Vector2(tx, floor_y))
		add_floor(tx, floor_y - TIER, TOWER_W, "wood", false, false)
		add_ladder(tx + TOWER_W * 0.5 - 8.0, floor_y - TIER)
		reserve(Rect2(tx - 30.0, floor_y - TIER, TOWER_W + 60.0, TIER))
		var sl := Decor.Searchlight.new()
		sl.ground_y = TIER + 62.0
		add_world(sl, Vector2(tx + TOWER_W * 0.5, floor_y - TIER - 62.0))
		_towers.append(tx)
		_pickup(PickupScript.AMMO if f < 0.5 else PickupScript.HEALTH, Vector2(tx + TOWER_W * 0.3, floor_y - TIER - 30.0))
	add_world(Decor.GreatGate.new(), Vector2(level_w - 230.0, floor_y))   # השער הענק (מאחורי היציאה)


func _pickup(kind: int, pos: Vector2) -> void:
	var p = PickupScript.new()
	p.kind = kind
	p.life = 100000.0
	main.add_child(p)
	p.setup(pos, Vector2.ZERO)


func build_effects() -> void:
	var fx := Decor.GateFX.new()
	fx.vp = vp
	screen_layer.add_child(fx)


# SNIPER על המגדלים, HANDLER ו-SAPPER בין המגדלים
func extra_spawns() -> void:
	for i in _towers.size():
		var tx: float = _towers[i]
		spawn(Registry.SNIPER, tx + TOWER_W * 0.75, floor_y - TIER)
		var mx: float = tx + TOWER_W + 300.0
		if free_x(mx, 40.0):
			spawn(Registry.HANDLER if i % 2 == 0 else Registry.SAPPER, mx)
