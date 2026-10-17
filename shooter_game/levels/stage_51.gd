extends "res://levels/stage_base.gd"
# ============================================================
#  STAGE 51 - "THE RANCH" (אזור שישי - החרוט הדרומי, שלב 6) - "THEY LEARNED TO HERD"
#  (הסיפור: מבית הקברות של הטנגו הגיבור יוצא למישור. אסטנסיה "לה פטרונה" בצהרי קיץ לוהטים - שמש לבנה, אבק ושקט מת.
#   הבוקרים המתים עוד עובדים את האדמה: רוכבים על סוסים מתים, מגדלים דבורים ומסמנים - ועכשיו הם מסמנים אותך.
#   מי שמסומן - כל העדר יודע איפה הוא. רק המים בשוקת שוטפים את הסימן.)
#  (effects/s51_decor.gd): שמיים לבנים עם נשרים, אופק רועד, בית האחוזה + טחנות + ממגורות, גדר תיל וגלגלי קוצים.
#  קומה שנייה: במות מגדלי המים (TOWERS) ומסלולי ההליכה של הממגורות (SILOS) - הרוכבים לא מגיעים לשם.
#  מלכודות: GrainChute - צינור התבואה ליד כל ממגורה: עוברים מתחת -> חריקה -> שופך תבואה (נזק + האטה, קובר זומבים).
#           Chute - מכלאות הובלה (CHUTES): השער נפתח ושור מת דוהר על הכביש - לקפוץ מעליו (דורס גם זומבים).
#  שוקות מים (TROUGHS) - לעמוד בתוכן = שוטף את הסימון של BRANDER. מדורות אסאדו (ASADO) - העשן מפזר דבורים.
#  זומבים: RIDER (גאוצ'ו על סוס מת - הסתערות ודריסה), BEEKEEPER (כוורת חיה, נחיל דבורים), BRANDER (ברזל סימון לוהט),
#          רגילים, רצים.
#  בוס: EL PATRON (enemies/types/rider.gd, מצב בוס) - בזירת האילוף בסוף: לאסו, קורא לרוכבים, הסתערות עדר.
#  לשנות: TOWERS, TIER, SILOS, SILO_TIER, CHUTES, TROUGHS, ASADO, BEES, zombie_weights().
# ============================================================

const Decor := preload("res://effects/s51_decor.gd")
const S17 := preload("res://effects/s17_decor.gd")
const PickupScript := preload("res://pickup.gd")

const SOUNDS := {
	"rn_creak": [["S", 210, 170, 0.0, 0.7, 0.05, 2.6, 0.35, 1.0, 0.3], ["N", 0, 0, 0.0, 0.6, 0.05, 3.5, 0.25, 0.3, 0]],
	"rn_pour": {"rev": 0.2, "layers": [["N", 0, 0, 0.0, 1.6, 0.1, 1.4, 0.8, 0.45, 0], ["N", 0, 0, 0.0, 1.4, 0.05, 2.0, 0.4, 0.15, 0]]},
	"rn_bellow": {"drive": 2.0, "layers": [["V", 82, 60, 0.0, 1.0, 0.06, 2.4, 1.0, 1.0, 0.08, 0, [240, 640, 20]], ["N", 0, 0, 0.0, 0.7, 0.05, 3.0, 0.35, 0.15, 0]]},
}

const TOWERS := [0.15, 0.58]            # מגדלי מים (במה = קומה)
const TIER := 150.0
const SILOS := [0.34, 0.8]              # ממגורות (מסלול הליכה = קומה) + צינור תבואה לידן
const SILO_TIER := 170.0
const CHUTES := [0.25, 0.47, 0.69]      # מכלאות הובלה עם שור מת
const TROUGHS := [0.1, 0.21, 0.3, 0.42, 0.53, 0.64, 0.75, 0.87]
const ASADO := [0.19, 0.5, 0.72]
const BEES := [0.39, 0.62]              # תיבות כוורת (ושם הכוורנים)
const COOPS := [0.06, 0.45]
const HARDER := [1.0, 1.15, 1.3]

var _decks := []        # [x0, x1, y] - קומות
var _troughs := []
var _bees := []


func zombie_weights() -> Dictionary:
	return {Registry.BRANDER: 0.07, Registry.BEEKEEPER: 0.05, Registry.RIDER: 0.03, 0: 0.52, 1: 0.33}


func zombie_density() -> float:
	return 1.0 * float(HARDER[clampi(Settings.difficulty, 0, 2)])


func generators() -> Array:
	return [["bales", 1.3], ["drums", 0.8], ["tractor", 0.35]]


func custom_gen(gname: String, x: float) -> float:
	if not gname in ["bales", "drums", "tractor"]:
		return 0.0
	if not free_x(x, 20.0) or not free_x(x + 120.0, 20.0):   # לא בתוך מלכודת / סולם / שוקת / זירת הבוס
		return 80.0
	var o := Decor.Obstacle.new()
	o.kind = gname
	o.seed_v = rng.randi()
	match gname:
		"bales":
			o.size = Vector2(rng.randf_range(76.0, 92.0), rng.randf_range(56.0, 64.0))
		"drums":
			o.size = Vector2(rng.randf_range(54.0, 62.0), rng.randf_range(44.0, 50.0))
		_:
			o.size = Vector2(rng.randf_range(120.0, 136.0), rng.randf_range(70.0, 78.0))
	o.position = Vector2(x, floor_y)
	main.add_child(o)
	reserve(Rect2(x, floor_y - o.size.y, o.size.x, o.size.y))
	return o.size.x


func boss_kind() -> int:
	return Registry.RIDER


func music() -> String:
	return "res://music/level1_total_war.mp3"


func world_tint() -> Color:
	return Color(1.0, 0.96, 0.88)


func fog() -> bool:
	return false


func pits() -> int:
	return 0


func build_background(layer: CanvasLayer) -> Node:
	var bg = Backdrop.new()
	bg.level_w = level_w
	bg.sky = func(ci: CanvasItem, v: Vector2, t: float):
		Decor.ranch_sky(ci, v, t)
	bg.add_layer(0.06, func(ci: CanvasItem, sc: float, v: Vector2, t: float):
		Decor.far_plain(ci, sc, v, 552.0, t))
	bg.add_layer(0.28, func(ci: CanvasItem, sc: float, v: Vector2, t: float):
		Decor.mid_casco(ci, sc, v, 612.0, t))
	bg.add_layer(0.6, func(ci: CanvasItem, sc: float, v: Vector2, t: float):
		Decor.near_fence(ci, sc, v, 636.0, t))
	layer.add_child(bg)
	return bg


func build_world() -> void:
	var x := 0.0
	while x < level_w:
		var g := Decor.RanchGround.new()
		g.w = minf(1024.0, level_w - x)
		g.depth = main.floor_thickness
		g.seed_v = rng.randi()
		add_world(g, Vector2(x, floor_y))
		x += 1024.0
	for i in TOWERS.size():   # מגדלי מים
		var tx := level_w * float(TOWERS[i])
		var wt := Decor.WaterTower.new()
		wt.tier = TIER
		add_world(wt, Vector2(tx, floor_y))
		var pf = add_floor(tx - 6.0, floor_y - TIER, wt.w + 12.0, "concrete", false, false)
		pf.visible = false
		add_ladder(tx + 30.0, floor_y - TIER)
		add_ladder(tx + wt.w - 54.0, floor_y - TIER)
		reserve(Rect2(tx - 10.0, floor_y - 40.0, wt.w + 20.0, 40.0))
		_decks.append([tx, tx + wt.w, floor_y - TIER])
		_pickup(PickupScript.AMMO if i == 0 else PickupScript.HEALTH, Vector2(tx + wt.w * 0.5, floor_y - TIER - 30.0))
	for f in SILOS:   # ממגורות + צינור התבואה
		var sx := level_w * float(f)
		var si := Decor.Silo.new()
		si.tier = SILO_TIER
		add_world(si, Vector2(sx, floor_y))
		var sf = add_floor(sx - 30.0, floor_y - SILO_TIER, si.w + 60.0, "concrete", false, false)
		sf.visible = false
		add_ladder(sx - 20.0, floor_y - SILO_TIER)
		reserve(Rect2(sx - 40.0, floor_y - 40.0, si.w + 80.0, 40.0))
		_decks.append([sx - 30.0, sx + si.w + 30.0, floor_y - SILO_TIER])
		_pickup(PickupScript.AMMO, Vector2(sx + si.w * 0.5, floor_y - SILO_TIER - 30.0))
		var gc := Decor.GrainChute.new()
		var cx := sx + si.w + 84.0
		add_world(gc, Vector2(cx, floor_y))
		reserve(Rect2(cx - 60.0, floor_y - 40.0, 120.0, 40.0))
	for f in CHUTES:   # מכלאות הובלה
		var hx := level_w * float(f)
		while not free_x(hx, 130.0) and hx < level_w - 1400.0:
			hx += 60.0
		var ch := Decor.Chute.new()
		add_world(ch, Vector2(hx, floor_y))
		reserve(Rect2(hx - 100.0, floor_y - 40.0, 200.0, 40.0))
	for f in ASADO:
		var ax := level_w * float(f)
		while not free_x(ax, 80.0) and ax < level_w - 1400.0:
			ax += 50.0
		add_world(Decor.AsadoPit.new(), Vector2(ax, floor_y))
		reserve(Rect2(ax - 60.0, floor_y - 30.0, 120.0, 30.0))
	for f in TROUGHS:   # שוקות מים
		var wx := level_w * float(f)
		while not free_x(wx, 70.0) and wx < level_w - 1300.0:
			wx += 40.0
		var tr := Decor.Trough.new()
		add_world(tr, Vector2(wx, floor_y))
		reserve(Rect2(wx - 60.0, floor_y - 30.0, 120.0, 30.0))
		_troughs.append(wx)
	for f in BEES:
		var bx := level_w * float(f)
		while not free_x(bx, 30.0) or not free_x(bx + 130.0, 30.0):
			bx += 50.0
		add_world(Decor.BeeBoxes.new(), Vector2(bx, floor_y))
		reserve(Rect2(bx, floor_y - 30.0, 130.0, 30.0))
		_bees.append(bx)
	for f in COOPS:
		var cx2 := level_w * float(f)
		if free_x(cx2, 20.0) and free_x(cx2 + 170.0, 20.0):
			add_world(Decor.Coop.new(), Vector2(cx2, floor_y))
			reserve(Rect2(cx2, floor_y - 30.0, 175.0, 30.0))
	# זירת האילוף של EL PATRON
	var dx := level_w - 1100.0
	var ar := Decor.DomaArena.new()
	ar.w = 900.0
	add_world(ar, Vector2(dx, floor_y))
	reserve(Rect2(dx - 100.0, floor_y - 40.0, 1100.0, 40.0))
	var t2 := Decor.Trough.new()   # שוקת אחת בתוך הזירה
	add_world(t2, Vector2(dx + 160.0, floor_y))
	_pickup(PickupScript.HEALTH, Vector2(dx - 140.0, floor_y - 30.0))
	_pickup(PickupScript.AMMO, Vector2(dx - 60.0, floor_y - 30.0))


func _pickup(kind: int, pos: Vector2) -> void:
	var p = PickupScript.new()
	p.kind = kind
	p.life = 100000.0
	main.add_child(p)
	p.setup(pos, Vector2.ZERO)


func build_effects() -> void:
	screen_layer.add_child(S17.HeatHaze.new())
	var dust := Ambient.screen_particles("dust", vp)
	dust.color = Color(0.96, 0.86, 0.66, 0.24)
	dust.direction = Vector2(-1, 0.04)
	dust.initial_velocity_min = 24.0
	dust.initial_velocity_max = 60.0
	screen_layer.add_child(dust)
	var fx := Decor.RanchFX.new()
	fx.vp = vp
	screen_layer.add_child(fx)


# על הבמות - רגילים (יורדים בסולם). ליד הכוורות - כוורנים. ליד השוקות - מסמנים ששומרים עליהן. בשטח הפתוח - רוכבים.
func extra_spawns() -> void:
	for d in _decks:
		spawn(0, lerpf(float(d[0]), float(d[1]), 0.5), float(d[2]))
	for bx in _bees:
		spawn(Registry.BEEKEEPER, float(bx) + 200.0)
	for i in _troughs.size():
		if i % 2 == 1:
			spawn(Registry.BRANDER, float(_troughs[i]) + 140.0)
	for f in [0.27, 0.56, 0.84]:
		spawn(Registry.RIDER, level_w * f)
