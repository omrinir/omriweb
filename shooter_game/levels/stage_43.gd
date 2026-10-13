extends "res://levels/stage_base.gd"
# ============================================================
#  STAGE 43 - "WAR FACTORY" (אזור חמישי - דרום-מזרח, שלב 7) - "THEY LEARNED TO BUILD"
#  (הסיפור: הקטר המשוריין הוביל לוולטה רדונדה - עיר הפלדה של ברזיל. אימפריית המתים השתלטה על מפעל הפלדה:
#   תנורי ההתכה לא נכבים, ובאולם ההרכבה פס ייצור של טנקים. בסוף הפס מחכה אב-הטיפוס.)
#  (effects/s43_decor.gd): תנורי התכה, ארובות, אולם הרכבה עם גג משונן וגופי טנקים תלויים, קורות ושרשראות.
#  קומה שנייה: גשרי שירות (CATWALKS). גשר מעל הבוס - משם יורים במנוע.
#  מלכודות: Conveyor - מסועים שמזיזים אותך, Press - מכבשי הטבעה על המסועים (FOREMAN מפעיל אותם מוקדם).
#  זומבים: WELDER (מרתך פצועים), TANKETTE (שריון קדמי, לומדים לשמור מרחק), FOREMAN (מייצר חיילים, מפעיל מכבשים),
#          CONSCRIPT, OFFICER, REVIVER, רגילים, רצים.
#  בוס נייח: PROTOTYPE (enemies/types/prototype.gd) - טנק-על לא גמור: תותח כפול שקורא את ההתחמקות, רתכים מתקנים אותו.
#  לשנות: CATWALKS, TIER, LINES, SQUADS, BOSS_TIER, zombie_weights().
# ============================================================

const Decor := preload("res://effects/s43_decor.gd")
const PickupScript := preload("res://pickup.gd")

const SOUNDS := {
	"wf_hiss": [["N", 0, 0, 0.0, 0.8, 0.05, 2.0, 0.4, 0.95, 0, 0.9]],
	"wf_slam": {"drive": 1.8, "layers": [["N", 0, 0, 0.0, 0.4, 0.0, 9.0, 1.0, 0.15, 0], ["S", 90, 40, 0.0, 0.3, 0.0, 10.0, 0.8, 1.0, 0]]},
}

const CATWALKS := [[0.2, 380.0], [0.46, 400.0], [0.7, 380.0]]
const TIER := 150.0
const LINES := [[0.09, 320.0, 1.0], [0.32, 360.0, -1.0], [0.56, 320.0, 1.0], [0.8, 340.0, -1.0]]   # מסועים: [מקום, רוחב, כיוון]
const SQUADS := [0.15, 0.38, 0.62, 0.86]
const BOSS_TIER := 175.0
const HARDER := [1.0, 1.15, 1.3]

var _cats := []


func zombie_weights() -> Dictionary:
	return {Registry.CONSCRIPT: 0.08, Registry.WELDER: 0.03, Registry.TANKETTE: 0.02, Registry.FOREMAN: 0.01, Registry.REVIVER: 0.01,
		0: 0.5, 1: 0.35}


func zombie_density() -> float:
	return 1.0 * float(HARDER[clampi(Settings.difficulty, 0, 2)])


func generators() -> Array:
	return [["steel_coil", 1.0], ["parts_bin", 1.0], ["road_wheel", 0.6]]


func custom_gen(gname: String, x: float) -> float:
	if not gname in ["steel_coil", "parts_bin", "road_wheel"]:
		return 0.0
	var o := Decor.Obstacle.new()
	o.kind = gname
	o.seed_v = rng.randi()
	match gname:
		"steel_coil":
			o.size = Vector2(rng.randf_range(52.0, 60.0), rng.randf_range(44.0, 50.0))
		"parts_bin":
			o.size = Vector2(rng.randf_range(60.0, 70.0), rng.randf_range(36.0, 42.0))
		_:
			o.size = Vector2(rng.randf_range(54.0, 62.0), rng.randf_range(40.0, 46.0))
	o.position = Vector2(x, floor_y)
	main.add_child(o)
	reserve(Rect2(x, floor_y - o.size.y, o.size.x, o.size.y))
	return o.size.x


func boss_kind() -> int:
	return Registry.PROTOTYPE


func music() -> String:
	return "res://music/level1_total_war.mp3"


func world_tint() -> Color:
	return Color(1.0, 0.92, 0.85)


func fog() -> bool:
	return false


func pits() -> int:
	return 0


func street_props() -> bool:
	return false


func street_lamps() -> bool:
	return false


func build_background(layer: CanvasLayer) -> Node:
	var bg = Backdrop.new()
	bg.level_w = level_w
	bg.sky = func(ci: CanvasItem, v: Vector2, t: float):
		Decor.furnace_sky(ci, v, t)
	bg.add_layer(0.05, func(ci: CanvasItem, sc: float, v: Vector2, t: float):
		Decor.far_steelworks(ci, sc, v, 560.0, t))
	bg.add_layer(0.25, func(ci: CanvasItem, sc: float, v: Vector2, t: float):
		Decor.mid_hall(ci, sc, v, 622.0, t))
	bg.add_layer(0.6, func(ci: CanvasItem, sc: float, v: Vector2, t: float):
		Decor.near_girders(ci, sc, v, 645.0, t))
	layer.add_child(bg)
	return bg


func _catwalk(dx: float, w: float, tier: float, ladders: Array) -> void:
	var cw := Decor.Catwalk.new()
	cw.w = w
	cw.tier = tier
	add_world(cw, Vector2(dx, floor_y))
	var pf = add_floor(dx, floor_y - tier, w, "steel", false, false)
	pf.visible = false
	for lx in ladders:
		add_ladder(dx + float(lx), floor_y - tier)
		reserve(Rect2(dx + float(lx) - 10.0, floor_y - 40.0, 50.0, 40.0))


func build_world() -> void:
	var x := 0.0
	while x < level_w:
		var g := Decor.FactoryGround.new()
		g.w = minf(1024.0, level_w - x)
		g.depth = main.floor_thickness
		add_world(g, Vector2(x, floor_y))
		x += 1024.0
	for c in CATWALKS:
		var w: float = c[1]
		var dx := level_w * float(c[0])
		_catwalk(dx, w, TIER, [24.0, w - 50.0])
		_cats.append([dx, dx + w])
		_pickup(PickupScript.AMMO if c[0] < 0.6 else PickupScript.HEALTH, Vector2(dx + w * 0.5, floor_y - TIER - 30.0))
	for ln in LINES:   # מסוע + מכבש באמצע
		var lx := level_w * float(ln[0])
		var w2: float = ln[1]
		var cv := Decor.Conveyor.new()
		cv.w = w2
		cv.dir = float(ln[2])
		add_world(cv, Vector2(lx, floor_y))
		var pr := Decor.Press.new()
		add_world(pr, Vector2(lx + w2 * 0.5, floor_y))
		reserve(Rect2(lx - 20.0, floor_y - 200.0, w2 + 40.0, 200.0))
	# גשר שירות מעל הבוס (משם רואים את המנוע)
	var bx := level_w - 720.0
	_catwalk(bx - 380.0, 560.0, BOSS_TIER, [10.0])
	reserve(Rect2(bx - 420.0, floor_y - 160.0, 900.0, 160.0))   # הטנק רחב - שום מכשול מתחתיו
	_pickup(PickupScript.AMMO, Vector2(bx - 300.0, floor_y - BOSS_TIER - 30.0))
	main.set_meta("boss_x", bx)


func _pickup(kind: int, pos: Vector2) -> void:
	var p = PickupScript.new()
	p.kind = kind
	p.life = 100000.0
	main.add_child(p)
	p.setup(pos, Vector2.ZERO)


func build_effects() -> void:
	var fx := Decor.FactoryFX.new()
	fx.vp = vp
	screen_layer.add_child(fx)


# יחידות: טנקט מלפנים, 2 רובאים, רתך, מנהל עבודה / קצין מאחור. על הגשרים - רובאי
func extra_spawns() -> void:
	for i in SQUADS.size():
		var sx := level_w * float(SQUADS[i])
		spawn(Registry.TANKETTE, sx)
		spawn(Registry.CONSCRIPT, sx + 80.0)
		spawn(Registry.CONSCRIPT, sx + 120.0)
		spawn(Registry.WELDER, sx + 190.0)
		spawn(Registry.FOREMAN if i % 2 == 0 else Registry.OFFICER, sx + 340.0)
	for c in _cats:
		spawn(Registry.CONSCRIPT, lerpf(float(c[0]), float(c[1]), 0.5), floor_y - TIER)
