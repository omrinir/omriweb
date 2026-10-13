extends "res://levels/stage_base.gd"
# ============================================================
#  STAGE 42 - "METRO BARRACKS" (אזור חמישי - דרום-מזרח, שלב 6) - "THEY LEARNED TO DIG IN"
#  (הסיפור: אחרי המצעד הגיבור יורד אחרי טורי החיילים אל המטרו של ברזיליה. מתחת לבירה האימפריה בנתה קסרקטין:
#   מיטות קומתיים על הרציפים, קני מקלעים, חוטי מעידה בין הפסים - ובסוף הרציף מחכה הקטר המשוריין שייקח אותם צפונה.)
#  תחנת מטרו (effects/s42_decor.gd): קיר אריחים גאומטריים כחול-לבן (בסגנון אתוס בולקאו), פלורסנט מהבהב, פתחי מנהרות,
#  מיטות, מתלי רובים, פוסטרים "OBEY". קומה שנייה: גשרי הולכי רגל (MEZZ).
#  מלכודות: MGNest - קני מקלע (מאוישים ע"י חיילי האימפריה - הורגים את התותחן, אחר בא במקומו; LOADER ממלא תחמושת).
#           Tripwire - חוטי מעידה עם רימון (קופצים / מתכופפים לפרק / יורים ברימון מרחוק).
#  זומבים: LOADER (תחמושת לקנים ולרובאים), FLAMER (להביור, לומד לחסום לך את הבריחה), PIONEER (בונה קירות שקי חול),
#          CONSCRIPT, OFFICER, REVIVER, רגילים, רצים.
#  בוס נייח: ARMORED TRAIN (enemies/types/armored_train.gd) - פנס, מקלע, צריח, זיקוקי תאורה, "ALL OUT!".
#  לשנות: MEZZ, TIER, NESTS, WIRES, SQUADS, zombie_weights().
# ============================================================

const Decor := preload("res://effects/s42_decor.gd")
const PickupScript := preload("res://pickup.gd")

const SOUNDS := {
	"mb_mg": [["N", 0, 0, 0.0, 0.06, 0.0, 45.0, 0.6, 0.7, 0, 0.4], ["S", 150, 80, 0.0, 0.05, 0.0, 45.0, 0.3, 1.0, 0]],
	"mb_click": [["C", 0, 0, 0.0, 0.03, 0.0, 60.0, 0.4, 1.0, 0], ["S", 2400, 2200, 0.0, 0.05, 0.0, 40.0, 0.08, 1.0, 0]],
}

const MEZZ := [[0.2, 420.0], [0.5, 440.0], [0.77, 400.0]]
const TIER := 140.0
const NESTS := [0.29, 0.59, 0.87]
const WIRES := [0.1, 0.24, 0.4, 0.47, 0.67, 0.73, 0.94]
const SQUADS := [0.14, 0.36, 0.63, 0.9]
const HARDER := [1.0, 1.15, 1.3]

var _mezz := []


func zombie_weights() -> Dictionary:
	return {Registry.CONSCRIPT: 0.08, Registry.FLAMER: 0.03, Registry.PIONEER: 0.02, Registry.LOADER: 0.02, Registry.OFFICER: 0.01,
		Registry.REVIVER: 0.01, 0: 0.48, 1: 0.35}


func zombie_density() -> float:
	return 1.0 * float(HARDER[clampi(Settings.difficulty, 0, 2)])


func generators() -> Array:
	return [["bunk", 1.0], ["footlocker", 1.0], ["rack", 0.6]]


func custom_gen(gname: String, x: float) -> float:
	if not gname in ["bunk", "footlocker", "rack"]:
		return 0.0
	var o := Decor.Obstacle.new()
	o.kind = gname
	o.seed_v = rng.randi()
	match gname:
		"bunk":
			o.size = Vector2(rng.randf_range(84.0, 96.0), rng.randf_range(44.0, 50.0))
		"footlocker":
			o.size = Vector2(rng.randf_range(50.0, 60.0), rng.randf_range(32.0, 36.0))
		_:
			o.size = Vector2(rng.randf_range(54.0, 64.0), rng.randf_range(40.0, 46.0))
	o.position = Vector2(x, floor_y)
	main.add_child(o)
	reserve(Rect2(x, floor_y - o.size.y, o.size.x, o.size.y))
	return o.size.x


func boss_kind() -> int:
	return Registry.ARMORED_TRAIN


func music() -> String:
	return "res://music/level1_total_war.mp3"


func world_tint() -> Color:
	return Color(0.9, 0.93, 1.0)


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
		Decor.metro_ceiling(ci, v, t)
	bg.add_layer(0.05, func(ci: CanvasItem, sc: float, v: Vector2, t: float):
		Decor.far_tiles(ci, sc, v, 560.0, t))
	bg.add_layer(0.25, func(ci: CanvasItem, sc: float, v: Vector2, t: float):
		Decor.mid_barracks(ci, sc, v, 622.0, t))
	bg.add_layer(0.6, func(ci: CanvasItem, sc: float, v: Vector2, t: float):
		Decor.near_columns(ci, sc, v, 645.0, t))
	layer.add_child(bg)
	return bg


func build_world() -> void:
	var x := 0.0
	while x < level_w:
		var g := Decor.PlatformGround.new()
		g.w = minf(1024.0, level_w - x)
		g.depth = main.floor_thickness
		add_world(g, Vector2(x, floor_y))
		x += 1024.0
	for m in MEZZ:   # גשרי הולכי רגל: קומה + 2 סולמות
		var w: float = m[1]
		var dx := level_w * float(m[0])
		var mz := Decor.Mezzanine.new()
		mz.w = w
		mz.tier = TIER
		add_world(mz, Vector2(dx, floor_y))
		var pf = add_floor(dx, floor_y - TIER, w, "steel", false, false)
		pf.visible = false
		add_ladder(dx + 24.0, floor_y - TIER)
		add_ladder(dx + w - 50.0, floor_y - TIER)
		reserve(Rect2(dx, floor_y - 40.0, 60.0, 40.0))
		reserve(Rect2(dx + w - 70.0, floor_y - 40.0, 70.0, 40.0))
		_mezz.append([dx, dx + w])
		_pickup(PickupScript.AMMO if m[0] < 0.6 else PickupScript.HEALTH, Vector2(dx + w * 0.5, floor_y - TIER - 30.0))
	for f in NESTS:   # קני מקלע (פונים שמאלה - אל השחקן שמגיע)
		var nx := level_w * float(f)
		var nest := Decor.MGNest.new()
		add_world(nest, Vector2(nx, floor_y))
		reserve(Rect2(nx - 70.0, floor_y - 50.0, 360.0, 50.0))   # כולל מקום התותחן והדרך אליו מאחור
	for f in WIRES:   # חוטי מעידה
		var wx := level_w * float(f)
		var tries := 0
		while not free_x(wx, 60.0) and tries < 12:
			wx += 50.0
			tries += 1
		var tw := Decor.Tripwire.new()
		add_world(tw, Vector2(wx, floor_y))
		reserve(Rect2(wx - 20.0, floor_y - 20.0, Decor.Tripwire.W + 40.0, 20.0))


func _pickup(kind: int, pos: Vector2) -> void:
	var p = PickupScript.new()
	p.kind = kind
	p.life = 100000.0
	main.add_child(p)
	p.setup(pos, Vector2.ZERO)


func build_effects() -> void:
	var fx := Decor.MetroFX.new()
	fx.vp = vp
	screen_layer.add_child(fx)


# יחידות: 2 רובאים, להביור, חלוץ (PIONEER), נושא תחמושת / קצין. תותחן ליד כל קן. על הגשרים - רובאי
func extra_spawns() -> void:
	for i in SQUADS.size():
		var sx := level_w * float(SQUADS[i])
		spawn(Registry.CONSCRIPT, sx)
		spawn(Registry.CONSCRIPT, sx + 45.0)
		spawn(Registry.FLAMER, sx - 60.0)
		spawn(Registry.PIONEER, sx + 120.0)
		spawn(Registry.LOADER if i % 2 == 0 else Registry.OFFICER, sx + 320.0)
	for f in NESTS:
		var nx := level_w * float(f)
		spawn(Registry.CONSCRIPT, nx + 50.0)
		spawn(Registry.LOADER, nx + 260.0)
	for m in _mezz:
		spawn(Registry.CONSCRIPT, lerpf(float(m[0]), float(m[1]), 0.5), floor_y - TIER)
