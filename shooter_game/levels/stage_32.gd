extends "res://levels/stage_base.gd"
# ============================================================
#  STAGE 32 - "DEVIL'S CARNIVAL" (אזור רביעי - האנדים, שלב 5) - "THEY LEARNED TO DANCE"
#  הקרנבל של אורורו בלילה (effects/s32_decor.gd): ריקוד הדיאבלדה. כיכר קולוניאלית, הכנסייה, פסל הבתולה על הגבעה,
#  שרשראות נורות שמהבהבות בקצב, קשתות כסף, זיקוקים, קונפטי, קהל זומבים ביציעים.
#  המוזיקה = התזמורת (Band): תוף ותובה בקצב BPM. הרקדנים קופצים על הפעמות.
#  קומה שנייה: מרפסות עץ של הבתים (FACADES).
#  מלכודות / כלים: Castillo - מגדל זיקוקים: יורים בגלגלים -> ניצוצות שורפות את כל מי שמסביב (גם אותך).
#                  Firecrackers - שרשראות נפצים על הרצפה (FIRECRACKERS).
#  זומבים: DIABLO (קופץ בקצב, מסכה חוסמת), MORENADA (מסתובב ומעיף יריות, אחר כך מסוחרר),
#          BANDLEADER (טובה: הדף, ומחזיק את הרקדנים בקצב - להרוג ראשון), רגילים, רצים.
#  להקות (TROUPES): מנצח + 4 רקדנים.
#  בוס: SUPAY (enemies/types/supay.gd) - מלך השדים. בורח בסוף להר הגעש -> שלב 33.
#  לשנות: FACADES, TIER, ARCH_EVERY, CASTILLOS, FIRECRACKERS, TROUPES, zombie_weights().
# ============================================================

const Decor := preload("res://effects/s32_decor.gd")
const PickupScript := preload("res://pickup.gd")

const SOUNDS := {
	"c32_kick": [["S", 120, 45, 0.0, 0.28, 0.0, 12.0, 1.0, 1.0, 0], ["N", 0, 0, 0.0, 0.02, 0.0, 200.0, 0.3, 0.6, 0]],
	"c32_snare": [["N", 0, 0, 0.0, 0.2, 0.0, 20.0, 0.6, 0.7, 0], ["S", 210, 170, 0.0, 0.09, 0.0, 40.0, 0.35, 1.0, 0]],
	"c32_cym": [["N", 0, 0, 0.0, 0.9, 0.0, 4.0, 0.25, 1.0, 0, 0.6]],
	"c32_tuba": {"drive": 1.6, "layers": [["W", 58, 58, 0.0, 0.36, 0.02, 4.0, 0.6, 0.1, 0.01], ["S", 116, 116, 0.0, 0.3, 0.02, 5.0, 0.25, 1.0, 0]]},
	"c32_brass": [["W", 233, 233, 0.0, 0.3, 0.015, 5.0, 0.22, 0.25, 0.01], ["W", 294, 294, 0.0, 0.3, 0.015, 5.0, 0.2, 0.25, 0.01], ["W", 349, 349, 0.0, 0.3, 0.015, 5.0, 0.2, 0.25, 0.01]],
	"c32_brass2": [["W", 262, 262, 0.0, 0.3, 0.015, 5.0, 0.22, 0.25, 0.01], ["W", 311, 311, 0.0, 0.3, 0.015, 5.0, 0.2, 0.25, 0.01], ["W", 392, 392, 0.0, 0.3, 0.015, 5.0, 0.2, 0.25, 0.01]],
	"c32_fuse": [["N", 0, 0, 0.0, 0.6, 0.05, 2.0, 0.5, 0.6, 0, 0.4], ["S", 900, 1400, 0.0, 0.5, 0.05, 2.0, 0.08, 1.0, 0.1]],
	"c32_crackle": [["C", 0, 0, 0.0, 0.3, 0.0, 6.0, 1.0, 1.0, 0], ["N", 0, 0, 0.0, 0.2, 0.0, 12.0, 0.25, 0.5, 0, 0.4]],
	"c32_pop": [["N", 0, 0, 0.0, 0.05, 0.0, 70.0, 1.0, 0.8, 0], ["S", 300, 120, 0.0, 0.04, 0.0, 70.0, 0.4, 1.0, 0]],
}

const FACADES := [[0.1, 340.0], [0.27, 380.0], [0.45, 320.0], [0.62, 400.0], [0.8, 340.0]]   # [מיקום יחסי, רוחב]
const TIER := 140.0
const ARCH_EVERY := 1100.0
const CASTILLOS := [0.16, 0.34, 0.53, 0.72, 0.9]
const FIRECRACKERS := 9
const TROUPES := [0.2, 0.42, 0.66, 0.84]
const HARDER := [1.0, 1.15, 1.3]

var _balconies := []


func zombie_weights() -> Dictionary:
	return {Registry.DIABLO: 0.14, Registry.MORENADA: 0.07, Registry.BANDLEADER: 0.03, 0: 0.44, 1: 0.32}


func zombie_density() -> float:
	return 0.9 * float(HARDER[clampi(Settings.difficulty, 0, 2)])


func generators() -> Array:
	return [["food_cart", 1.0], ["bleachers", 1.0], ["brass_drums", 0.8]]


func custom_gen(gname: String, x: float) -> float:
	if not gname in ["food_cart", "bleachers", "brass_drums"]:
		return 0.0
	var o := Decor.Obstacle.new()
	o.kind = gname
	o.seed_v = rng.randi()
	match gname:
		"food_cart":
			o.size = Vector2(rng.randf_range(76.0, 90.0), rng.randf_range(44.0, 50.0))
		"bleachers":
			o.size = Vector2(rng.randf_range(90.0, 110.0), rng.randf_range(40.0, 48.0))
		_:
			o.size = Vector2(rng.randf_range(64.0, 74.0), rng.randf_range(34.0, 40.0))
	o.position = Vector2(x, floor_y)
	main.add_child(o)
	reserve(Rect2(x, floor_y - o.size.y, o.size.x, o.size.y))
	return o.size.x


func boss_kind() -> int:
	return Registry.SUPAY


func music() -> String:
	return ""   # התזמורת (Band) היא המוזיקה


func world_tint() -> Color:
	return Color(0.95, 0.9, 1.0)


func fog() -> bool:
	return false


func pits() -> int:
	return 0


func dark_level() -> bool:
	return false


func build_background(layer: CanvasLayer) -> Node:
	var bg = Backdrop.new()
	bg.level_w = level_w
	bg.sky = func(ci: CanvasItem, v: Vector2, t: float):
		Decor.carnival_sky(ci, v, t)
	bg.add_layer(0.06, func(ci: CanvasItem, sc: float, v: Vector2, t: float):
		Decor.far_hills(ci, sc, v, 520.0, t))
	bg.add_layer(0.3, func(ci: CanvasItem, sc: float, v: Vector2, t: float):
		Decor.mid_town(ci, sc, v, 600.0, t))
	bg.add_layer(0.62, func(ci: CanvasItem, sc: float, v: Vector2, t: float):
		Decor.near_crowd(ci, sc, v, 640.0, t))
	layer.add_child(bg)
	return bg


func build_world() -> void:
	main.add_child(Decor.Band.new())
	var x := 0.0
	while x < level_w:
		var g := Decor.PlazaGround.new()
		g.w = minf(1024.0, level_w - x)
		g.depth = main.floor_thickness
		g.seed_v = rng.randi()
		add_world(g, Vector2(x, floor_y))
		x += 1024.0
	for f in FACADES:   # בתים עם מרפסות
		var w: float = f[1]
		var fx := level_w * float(f[0])
		var fa := Decor.Facade.new()
		fa.w = w
		fa.tier = TIER
		fa.seed_v = rng.randi()
		add_world(fa, Vector2(fx, floor_y))
		var pf = add_floor(fx - 12.0, floor_y - TIER, w + 24.0, "wood", false, false)
		pf.visible = false   # (המרפסת מצוירת ב-Facade)
		add_ladder(fx + 14.0, floor_y - TIER)
		reserve(Rect2(fx - 10.0, floor_y - TIER, 50.0, TIER))
		_balconies.append([fx, fx + w])
		_pickup(PickupScript.AMMO if f[0] < 0.5 else PickupScript.HEALTH, Vector2(fx + w * 0.6, floor_y - TIER - 30.0))
	var ax := ARCH_EVERY * 0.6   # קשתות כסף מעל הרחוב
	while ax < level_w - 400.0:
		var ar := Decor.Arch.new()
		ar.seed_v = rng.randi()
		add_world(ar, Vector2(ax, floor_y))
		ax += ARCH_EVERY
	for f in CASTILLOS:   # מגדלי זיקוקים
		var cx := level_w * float(f)
		while not free_x(cx, 40.0) and cx < level_w - 300.0:
			cx += 50.0
		add_world(Decor.Castillo.new(), Vector2(cx, floor_y))
		reserve(Rect2(cx - 30.0, floor_y - 40.0, 60.0, 40.0))
	for i in FIRECRACKERS:   # שרשראות נפצים
		var fx := rng.randf_range(level_w * 0.08, level_w - 700.0)
		if not free_x(fx, 20.0):
			continue
		var fc := Decor.Firecrackers.new()
		fc.w = rng.randf_range(54.0, 84.0)
		add_world(fc, Vector2(fx, floor_y))
		reserve(Rect2(fx - 10.0, floor_y - 10.0, fc.w + 20.0, 10.0))


func _pickup(kind: int, pos: Vector2) -> void:
	var p = PickupScript.new()
	p.kind = kind
	p.life = 100000.0
	main.add_child(p)
	p.setup(pos, Vector2.ZERO)


func build_effects() -> void:
	var fx := Decor.CarnivalFX.new()
	fx.vp = vp
	screen_layer.add_child(fx)


# להקות: מנצח עם 4 רקדנים לפניו. מורנדה על חלק מהמרפסות
func extra_spawns() -> void:
	for f in TROUPES:
		var bx := level_w * float(f)
		spawn(Registry.BANDLEADER, bx)
		for k in 4:
			spawn(Registry.DIABLO, bx - 110.0 - float(k) * 55.0)
	for i in _balconies.size():
		var s: Array = _balconies[i]
		if i % 2 == 0:
			spawn(Registry.MORENADA, lerpf(float(s[0]), float(s[1]), 0.6), floor_y - TIER)
		else:
			spawn(Registry.DIABLO, lerpf(float(s[0]), float(s[1]), 0.6), floor_y - TIER)
