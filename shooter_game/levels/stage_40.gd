extends "res://levels/stage_base.gd"
# ============================================================
#  STAGE 40 - "HARBOR OF WAR" (אזור חמישי - דרום-מזרח, שלב 4) - "THEY LEARNED TO OBEY"
#  (הסיפור: אחרי המרקנה הגיבור עוקב אחרי הזומבים לנמל סנטוס - והם כבר לא עדר. הם צבא. אימפריית המתים
#   לובשת מדים, מניפה דגלים אדומים עם הנחש העתיק, ומעמיסה טנקים על אוניות כדי לכבוש את העולם.)
#  נמל סנטוס עם שחר (effects/s40_decor.gd): עגורנים עם כרזות, מכולות, אוניות מלחמה, הבניינים הנטויים.
#  קומה שנייה: ערמות המכולות (STACKS).
#  מלכודות: SwingBox - מכולה מתנדנדת על כבל (מטוטלת בגובה הגוף, מכה גם זומבים). BarbWire - גלילי תיל (קופצים מעל).
#  זומבים: CONSCRIPT (רובאי - יורה, לומד כקבוצה), OFFICER (פקודות: VOLLEY / CHARGE), FLAGBEARER (דגל = לא נשברים),
#          REVIVER, רגילים, רצים. מחלקות (SQUADS): קצין מאחור, רובאים מלפנים, נושא דגל באמצע.
#  בוס נייח: BEHEMOTH (enemies/types/behemoth.gd) - טנק: פגזים שמתקנים את עצמם (bracketing), מקלע, מפקד בצוהר.
#  לשנות: STACKS, TIER, SWINGS, WIRES, SQUADS, zombie_weights().
# ============================================================

const Decor := preload("res://effects/s40_decor.gd")
const PickupScript := preload("res://pickup.gd")

const SOUNDS := {
	"hb_clang": [["S", 300, 260, 0.0, 0.5, 0.0, 5.0, 0.6, 1.0, 0.02], ["N", 0, 0, 0.0, 0.3, 0.0, 10.0, 0.6, 0.3, 0, 0.5]],
	"hb_wire": [["N", 0, 0, 0.0, 0.12, 0.0, 30.0, 0.3, 0.9, 0, 0.7], ["S", 3000, 2600, 0.0, 0.06, 0.0, 40.0, 0.1, 1.0, 0]],
}

const STACKS := [[0.14, 260.0], [0.38, 300.0], [0.62, 260.0], [0.84, 280.0]]
const TIER := 120.0
const SWINGS := [0.27, 0.51, 0.75]
const WIRES := [0.09, 0.32, 0.57, 0.8]
const SQUADS := [0.2, 0.44, 0.68, 0.9]
const HARDER := [1.0, 1.15, 1.3]

var _stacks := []


func zombie_weights() -> Dictionary:
	return {Registry.CONSCRIPT: 0.12, Registry.OFFICER: 0.02, Registry.FLAGBEARER: 0.02, Registry.REVIVER: 0.02, 0: 0.48, 1: 0.34}


func zombie_density() -> float:
	return 1.0 * float(HARDER[clampi(Settings.difficulty, 0, 2)])


func generators() -> Array:
	return [["drum_pile", 1.0], ["cargo_crate", 1.0], ["bollard", 0.6]]


func custom_gen(gname: String, x: float) -> float:
	if not gname in ["drum_pile", "cargo_crate", "bollard"]:
		return 0.0
	var o := Decor.Obstacle.new()
	o.kind = gname
	o.seed_v = rng.randi()
	match gname:
		"drum_pile":
			o.size = Vector2(rng.randf_range(60.0, 80.0), rng.randf_range(38.0, 44.0))
		"cargo_crate":
			o.size = Vector2(rng.randf_range(56.0, 66.0), rng.randf_range(46.0, 54.0))
		_:
			o.size = Vector2(rng.randf_range(34.0, 40.0), rng.randf_range(30.0, 34.0))
	o.position = Vector2(x, floor_y)
	main.add_child(o)
	reserve(Rect2(x, floor_y - o.size.y, o.size.x, o.size.y))
	return o.size.x


func boss_kind() -> int:
	return Registry.BEHEMOTH


func music() -> String:
	return "res://music/level1_total_war.mp3"


func world_tint() -> Color:
	return Color(1.0, 0.93, 0.88)


func fog() -> bool:
	return false


func pits() -> int:
	return 0


func build_background(layer: CanvasLayer) -> Node:
	var bg = Backdrop.new()
	bg.level_w = level_w
	bg.sky = func(ci: CanvasItem, v: Vector2, t: float):
		Decor.harbor_sky(ci, v, t)
	bg.add_layer(0.05, func(ci: CanvasItem, sc: float, v: Vector2, t: float):
		Decor.far_coast(ci, sc, v, 560.0, t))
	bg.add_layer(0.25, func(ci: CanvasItem, sc: float, v: Vector2, t: float):
		Decor.mid_cranes(ci, sc, v, 622.0, t))
	bg.add_layer(0.6, func(ci: CanvasItem, sc: float, v: Vector2, t: float):
		Decor.near_quay(ci, sc, v, 645.0, t))
	layer.add_child(bg)
	return bg


func build_world() -> void:
	var x := 0.0
	while x < level_w:
		var g := Decor.QuayGround.new()
		g.w = minf(1024.0, level_w - x)
		g.depth = main.floor_thickness
		g.seed_v = rng.randi()
		add_world(g, Vector2(x, floor_y))
		x += 1024.0
	for s in STACKS:   # ערמות מכולות: קומה + סולם
		var w: float = s[1]
		var dx := level_w * float(s[0])
		var cs := Decor.ContainerStack.new()
		cs.w = w
		cs.tier = TIER
		cs.seed_v = rng.randi()
		add_world(cs, Vector2(dx, floor_y))
		var pf = add_floor(dx - 4.0, floor_y - TIER, w + 8.0, "steel", false, false)
		pf.visible = false
		add_ladder(dx + 6.0, floor_y - TIER)
		reserve(Rect2(dx - 10.0, floor_y - TIER, 50.0, TIER))
		_stacks.append([dx, dx + w])
		_pickup(PickupScript.AMMO if s[0] < 0.5 else PickupScript.HEALTH, Vector2(dx + w * 0.6, floor_y - TIER - 30.0))
	for f in SWINGS:   # מכולות מתנדנדות
		var sb := Decor.SwingBox.new()
		add_world(sb, Vector2(level_w * float(f), floor_y))
		reserve(Rect2(level_w * float(f) - 60.0, floor_y - 60.0, 120.0, 60.0))
	for f in WIRES:   # תיל
		var bw := Decor.BarbWire.new()
		bw.w = 120.0
		add_world(bw, Vector2(level_w * float(f), floor_y))
		reserve(Rect2(level_w * float(f), floor_y - 30.0, 120.0, 30.0))


func _pickup(kind: int, pos: Vector2) -> void:
	var p = PickupScript.new()
	p.kind = kind
	p.life = 100000.0
	main.add_child(p)
	p.setup(pos, Vector2.ZERO)


func build_effects() -> void:
	var fx := Decor.HarborFX.new()
	fx.vp = vp
	screen_layer.add_child(fx)


# מחלקות: 3 רובאים מלפנים, נושא דגל באמצע, קצין מאחור. רובאים על ערמות המכולות
func extra_spawns() -> void:
	for i in SQUADS.size():
		var sx := level_w * float(SQUADS[i])
		for k in 3:
			spawn(Registry.CONSCRIPT, sx + float(k) * 45.0)
		if i % 2 == 0:
			spawn(Registry.FLAGBEARER, sx + 170.0)
		spawn(Registry.OFFICER, sx + 330.0)
	for s in _stacks:
		spawn(Registry.CONSCRIPT, lerpf(float(s[0]), float(s[1]), 0.5), floor_y - TIER)
