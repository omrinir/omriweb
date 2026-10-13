extends "res://levels/stage_base.gd"
# ============================================================
#  STAGE 29 - "MINE OF ECHOES" (אזור רביעי - האנדים, שלב 2) - "THEY LEARNED TO LISTEN"
#  מכרה כסף עמוק (effects/s29_decor.gd, בהשראת צ'רו ריקו בפוטוסי): מנהרות סלע, מסגרות עץ, מסילות, פנסי שמן,
#  פסלי "אל טיו" עם נרות ועשן, צינורות אוויר דולפים, טיפות מים, אבק. חשוך (MineDark) - הפנסים והפנס שלך מאירים.
#  קומה שנייה: פיגומי עץ (SCAFFOLDS).
#  מלכודת: CaveIn - קטעי תקרה סדוקים (CAVE_INS). הרבה יריות קרובות / פיצוץ -> אבק נושר -> סלעים נופלים.
#  זומבים: ECHO (עיוור, צד לפי צליל - להתכופף ולא לירות), DYNAMITER (זורק דינמיט), רגילים, רצים, LEAPER.
#  בוס: THE FOREMAN - DYNAMITER ענק (enemies/types/dynamiter.gd, מצב בוס).
#  לשנות: SCAFFOLDS, TIER, CAVE_INS, LANTERN_GAP, zombie_weights().
# ============================================================

const Decor := preload("res://effects/s29_decor.gd")
const PickupScript := preload("res://pickup.gd")

const SOUNDS := {
	"m29_rumble": [["N", 0, 0, 0.0, 0.9, 0.2, 1.5, 0.8, 0.06, 0], ["S", 45, 35, 0.0, 0.9, 0.2, 1.5, 0.6, 1.0, 0.05], ["C", 0, 0, 0.0, 0.9, 0.1, 2.0, 0.3, 0.6, 0]],
	"m29_hiss": [["N", 0, 0, 0.0, 0.7, 0.03, 3.0, 0.4, 0.9, 0, 0.5]],
}

const SCAFFOLDS := [[0.16, 380.0], [0.4, 420.0], [0.63, 380.0], [0.85, 400.0]]
const TIER := 150.0
const CAVE_INS := [0.1, 0.23, 0.35, 0.5, 0.58, 0.72, 0.9]
const LANTERN_GAP := 520.0
const HARDER := [1.0, 1.15, 1.3]

var _spans := []


func zombie_weights() -> Dictionary:
	return {Registry.ECHO: 0.13, Registry.DYNAMITER: 0.1, Registry.LEAPER: 0.06, 0: 0.4, 1: 0.31}


func zombie_density() -> float:
	return 1.0 * float(HARDER[clampi(Settings.difficulty, 0, 2)])


func generators() -> Array:
	return [["minecart", 1.4], ["ore", 1.0], ["timber", 0.8]]


func custom_gen(gname: String, x: float) -> float:
	if not gname in ["minecart", "ore", "timber"]:
		return 0.0
	var o := Decor.Obstacle.new()
	o.kind = gname
	o.seed_v = rng.randi()
	match gname:
		"minecart":
			o.size = Vector2(rng.randf_range(76.0, 90.0), rng.randf_range(42.0, 50.0))
		"ore":
			o.size = Vector2(rng.randf_range(70.0, 100.0), rng.randf_range(30.0, 40.0))
		_:
			o.size = Vector2(rng.randf_range(70.0, 90.0), rng.randf_range(54.0, 66.0))
	o.position = Vector2(x, floor_y)
	main.add_child(o)
	reserve(Rect2(x, floor_y - o.size.y, o.size.x, o.size.y))
	return o.size.x


func boss_kind() -> int:
	return Registry.DYNAMITER


func music() -> String:
	return "res://music/level2_suspense.mp3"


func world_tint() -> Color:
	return Color(1.0, 0.94, 0.86)


func dark_level() -> bool:
	return true


func fog() -> bool:
	return false


func pits() -> int:
	return 0


func build_background(layer: CanvasLayer) -> Node:
	var bg = Backdrop.new()
	bg.level_w = level_w
	bg.sky = func(ci: CanvasItem, v: Vector2, t: float):
		Decor.mine_rock(ci, v, t)
	bg.add_layer(0.12, func(ci: CanvasItem, sc: float, v: Vector2, t: float):
		Decor.far_cavern(ci, sc, v, 600.0, t))
	bg.add_layer(0.35, func(ci: CanvasItem, sc: float, v: Vector2, t: float):
		Decor.mid_timbers(ci, sc, v, 618.0, t))
	bg.add_layer(0.62, func(ci: CanvasItem, sc: float, v: Vector2, t: float):
		Decor.near_rocks(ci, sc, v, 630.0, t))
	layer.add_child(bg)
	return bg


func build_world() -> void:
	var x := 0.0
	while x < level_w:
		var g := Decor.MineGround.new()
		g.w = minf(1024.0, level_w - x)
		g.depth = main.floor_thickness
		g.seed_v = rng.randi()
		add_world(g, Vector2(x, floor_y))
		var c := Decor.CaveCeiling.new()
		c.w = g.w
		c.seed_v = rng.randi()
		add_world(c, Vector2(x, floor_y))
		x += 1024.0
	var lx := 300.0   # פנסים תלויים מהתקרה
	while lx < level_w - 200.0:
		var ln := Decor.Lantern.new()
		ln.cord = rng.randf_range(40.0, 80.0)
		add_world(ln, Vector2(lx, floor_y + Decor.CEIL_Y + 6.0))
		lx += LANTERN_GAP + rng.randf_range(-80.0, 80.0)
	for sc in SCAFFOLDS:   # פיגומים
		var ox := level_w * float(sc[0])
		var w: float = sc[1]
		add_floor(ox, floor_y - TIER, w, "scaffold", true, true)
		add_ladder(ox + 12.0, floor_y - TIER)
		reserve(Rect2(ox - 20.0, floor_y - TIER, w + 40.0, TIER))
		_spans.append([ox, ox + w])
		_pickup(PickupScript.AMMO if sc[0] < 0.5 else PickupScript.HEALTH, Vector2(ox + w * 0.6, floor_y - TIER - 30.0))
	for f in CAVE_INS:   # תקרה סדוקה
		var cv := Decor.CaveIn.new()
		cv.w = rng.randf_range(200.0, 260.0)
		add_world(cv, Vector2(level_w * float(f), floor_y))
	for f in [0.07, 0.45, 0.78]:   # פסלי אל טיו
		var ex := level_w * float(f)
		while not free_x(ex, 40.0) and ex < level_w - 300.0:
			ex += 50.0
		add_world(Decor.ElTio.new(), Vector2(ex, floor_y))
		reserve(Rect2(ex - 40.0, floor_y - 90.0, 80.0, 90.0))
	for f in [0.19, 0.31, 0.55, 0.68, 0.93]:   # צינורות דולפים
		var sx := level_w * float(f)
		add_world(Decor.SteamLeak.new(), Vector2(sx, floor_y))


func _pickup(kind: int, pos: Vector2) -> void:
	var p = PickupScript.new()
	p.kind = kind
	p.life = 100000.0
	main.add_child(p)
	p.setup(pos, Vector2.ZERO)


func build_effects() -> void:
	main.add_child(Decor.MineDark.new())
	var fx := Decor.MineFX.new()
	fx.vp = vp
	screen_layer.add_child(fx)


# DYNAMITER על הפיגומים, ECHO במנהרות
func extra_spawns() -> void:
	for i in _spans.size():
		var s: Array = _spans[i]
		if i % 2 == 0:
			spawn(Registry.DYNAMITER, lerpf(float(s[0]), float(s[1]), 0.6), floor_y - TIER)
	for f in [0.27, 0.47, 0.66, 0.82]:
		var ex := level_w * float(f)
		if free_x(ex, 30.0):
			spawn(Registry.ECHO, ex)
