extends "res://levels/stage_base.gd"
# ============================================================
#  STAGE 38 - "MEGACITY CORE" (אזור חמישי - דרום-מזרח, שלב 2) - "THEY LEARNED OUR MACHINES"
#  סאו פאולו בלילה בטפטוף (effects/s38_decor.gd): גורדי שחקים, מסוקים, הקופאן, MASP, פקק בפאוליסטה, עמודי המינוקאו.
#  קומה שנייה: גשרי בטון מוגבהים (OVERPASSES).
#  מלכודות: GlassTower - פאנל זכוכית נסדק מעליך -> גשם רסיסים (ירייה בפאנל = על הזומבים). רסיסים על הקרקע = רעש שמעיר זומבים.
#           Billboard - שלט דיגיטלי פרוץ: "LOOK" -> הבזק מסנוור אם אתה מסתכל אליו.
#  זומבים: OFFICE (מזמין תגבורת בטלפון), WASHER (שוטף חלונות - נוחת מלמעלה, סבון חלק), COURIER (חבילות נפץ במקום שתגיע אליו),
#          CAPOEIRA, GRAFFITI, REVIVER, רגילים, רצים.
#  בוס נייח: THE TOWER (enemies/types/tower.gd) על פיגום (BOSS_TIER) - מסמרים, קורות מעגורן, לומד את המקום האהוב שלך.
#  לשנות: OVERPASSES, TIER, GLASS, BOARDS, SQUADS, BOSS_TIER, zombie_weights().
# ============================================================

const Decor := preload("res://effects/s38_decor.gd")
const PickupScript := preload("res://pickup.gd")

const SOUNDS := {
	"sp_crack": [["N", 0, 0, 0.0, 0.3, 0.0, 10.0, 0.5, 0.8, 0, 0.5], ["S", 2600, 2000, 0.0, 0.2, 0.0, 15.0, 0.2, 1.0, 0.05]],
	"sp_shatter": [["N", 0, 0, 0.0, 0.9, 0.0, 4.0, 0.9, 0.9, 0, 0.3], ["S", 3600, 1800, 0.0, 0.6, 0.0, 6.0, 0.3, 1.0, 0], ["S", 4800, 3000, 0.1, 0.5, 0.0, 7.0, 0.2, 1.0, 0]],
	"sp_crunch": [["N", 0, 0, 0.0, 0.12, 0.0, 25.0, 0.5, 0.9, 0, 0.5], ["S", 3000, 2500, 0.0, 0.06, 0.0, 40.0, 0.15, 1.0, 0]],
	"sp_beep": [["Q", 880, 880, 0.0, 0.1, 0.0, 30.0, 0.2, 1.0, 0], ["Q", 880, 880, 0.3, 0.1, 0.0, 30.0, 0.2, 1.0, 0], ["Q", 1320, 1320, 0.6, 0.15, 0.0, 30.0, 0.2, 1.0, 0]],
	"sp_flash": [["N", 0, 0, 0.0, 0.25, 0.0, 10.0, 0.5, 0.95, 0, 0.3], ["S", 4000, 1000, 0.0, 0.25, 0.0, 10.0, 0.2, 1.0, 0]],
}

const OVERPASSES := [[0.16, 320.0], [0.44, 360.0], [0.7, 320.0]]
const TIER := 140.0
const GLASS := [0.08, 0.3, 0.57, 0.85]
const BOARDS := [0.23, 0.5, 0.78]
const SQUADS := [0.26, 0.52, 0.76]
const BOSS_TIER := 170.0
const HARDER := [1.0, 1.15, 1.3]

var _passes := []
var _towers := []


func zombie_weights() -> Dictionary:
	return {Registry.OFFICE: 0.05, Registry.WASHER: 0.03, Registry.COURIER: 0.04, Registry.CAPOEIRA: 0.02, Registry.GRAFFITI: 0.02,
		Registry.REVIVER: 0.02, 0: 0.48, 1: 0.34}


func zombie_density() -> float:
	return 1.0 * float(HARDER[clampi(Settings.difficulty, 0, 2)])


func generators() -> Array:
	return [["taxi", 1.0], ["barrier_jersey", 1.0], ["kiosk", 0.6]]


func custom_gen(gname: String, x: float) -> float:
	if not gname in ["taxi", "barrier_jersey", "kiosk"]:
		return 0.0
	var o := Decor.Obstacle.new()
	o.kind = gname
	o.seed_v = rng.randi()
	match gname:
		"taxi":
			o.size = Vector2(rng.randf_range(104.0, 116.0), rng.randf_range(42.0, 48.0))
		"barrier_jersey":
			o.size = Vector2(rng.randf_range(70.0, 90.0), rng.randf_range(34.0, 40.0))
		_:
			o.size = Vector2(rng.randf_range(64.0, 74.0), rng.randf_range(52.0, 58.0))
	o.position = Vector2(x, floor_y)
	main.add_child(o)
	reserve(Rect2(x, floor_y - o.size.y, o.size.x, o.size.y))
	return o.size.x


func boss_kind() -> int:
	return Registry.TOWER


func music() -> String:
	return "res://music/level2_suspense.mp3"


func world_tint() -> Color:
	return Color(0.92, 0.88, 1.0)


func fog() -> bool:
	return false


func pits() -> int:
	return 0


func build_background(layer: CanvasLayer) -> Node:
	var bg = Backdrop.new()
	bg.level_w = level_w
	bg.sky = func(ci: CanvasItem, v: Vector2, t: float):
		Decor.sp_sky(ci, v, t)
	bg.add_layer(0.05, func(ci: CanvasItem, sc: float, v: Vector2, t: float):
		Decor.far_towers(ci, sc, v, 560.0, t))
	bg.add_layer(0.25, func(ci: CanvasItem, sc: float, v: Vector2, t: float):
		Decor.mid_avenue(ci, sc, v, 625.0, t))
	bg.add_layer(0.6, func(ci: CanvasItem, sc: float, v: Vector2, t: float):
		Decor.near_overpass(ci, sc, v, 645.0, t))
	layer.add_child(bg)
	return bg


func build_world() -> void:
	var x := 0.0
	while x < level_w:
		var g := Decor.CityGround.new()
		g.w = minf(1024.0, level_w - x)
		g.depth = main.floor_thickness
		g.seed_v = rng.randi()
		add_world(g, Vector2(x, floor_y))
		x += 1024.0
	for o in OVERPASSES:   # גשרים מוגבהים
		var w: float = o[1]
		var dx := level_w * float(o[0])
		var op := Decor.Overpass.new()
		op.w = w
		op.tier = TIER
		add_world(op, Vector2(dx, floor_y))
		var pf = add_floor(dx - 6.0, floor_y - TIER, w + 12.0, "concrete", false, false)
		pf.visible = false
		add_ladder(dx + 4.0, floor_y - TIER)
		reserve(Rect2(dx - 10.0, floor_y - TIER, 50.0, TIER))
		_passes.append([dx, dx + w])
		_pickup(PickupScript.AMMO if o[0] < 0.5 else PickupScript.HEALTH, Vector2(dx + w * 0.6, floor_y - TIER - 30.0))
	for f in GLASS:   # מגדלי זכוכית
		var gx := level_w * float(f)
		var gt := Decor.GlassTower.new()
		gt.w = 200.0
		add_world(gt, Vector2(gx, floor_y))
		_towers.append(gx)
	for f in BOARDS:   # שלטים דיגיטליים
		var bb := Decor.Billboard.new()
		add_world(bb, Vector2(level_w * float(f), floor_y))
	# פיגום הבוס
	var bx := level_w - 720.0
	var sc := Decor.Scaffold.new()
	sc.w = 300.0
	sc.tier = BOSS_TIER
	add_world(sc, Vector2(bx - 150.0, floor_y))
	var bf = add_floor(bx - 154.0, floor_y - BOSS_TIER, 308.0, "steel", false, false)
	bf.visible = false
	add_ladder(bx - 140.0, floor_y - BOSS_TIER)
	reserve(Rect2(bx - 160.0, floor_y - BOSS_TIER, 320.0, BOSS_TIER))
	main.set_meta("boss_x", bx)
	main.set_meta("boss_y", floor_y - BOSS_TIER)


func _pickup(kind: int, pos: Vector2) -> void:
	var p = PickupScript.new()
	p.kind = kind
	p.life = 100000.0
	main.add_child(p)
	p.setup(pos, Vector2.ZERO)


func build_effects() -> void:
	var fx := Decor.RainFX.new()
	fx.vp = vp
	screen_layer.add_child(fx)


# שוטפי חלונות על המגדלים, חוליות: COURIER מלפנים, OFFICE מאחור
func extra_spawns() -> void:
	for gx in _towers:
		spawn(Registry.WASHER, float(gx) + 100.0)
	for f in SQUADS:
		var sx := level_w * float(f)
		spawn(Registry.COURIER, sx)
		spawn(0, sx + 40.0)
		spawn(1, sx + 80.0)
		spawn(Registry.OFFICE, sx + 300.0)
	for i in _passes.size():
		var s: Array = _passes[i]
		spawn(Registry.OFFICE if i % 2 == 0 else Registry.GRAFFITI, lerpf(float(s[0]), float(s[1]), 0.6), floor_y - TIER)
