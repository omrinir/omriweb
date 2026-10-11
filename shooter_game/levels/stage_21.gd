extends "res://levels/stage_base.gd"
# ============================================================
#  STAGE 21 - "CLIFFSIDE" (אזור שלישי, שלב 3) - "THEY LEARNED TO FLY"
#  כפר צוקים בהרים בשקיעה (effects/s21_decor.gd): פסגות מושלגות, פגודה על צוק, מפל, גשרי חבלים, אורנים.
#  קומה שנייה: שבילי עץ גבוהים (WALKWAYS, TIER) עם דגלי תפילה - משם ה-GLIDER קופץ ודואה עליך.
#  מלכודת: בורות יתדות (SpikePit) - נופלים פנימה = נפגעים ונזרקים החוצה. זומבים שנופלים - מתים.
#  זומבים: GLIDER (חליפת כנפיים: עולה לקומה השנייה, דואה אליך וקופץ עליך), REVOLVER (אקדח תופי ענק:
#          ירייה אחת חזקה ואז בורח קצת), LEAPER, STALKER, רגילים ורצים.
#  בוס: THE SHERIFF - REVOLVER ענק שיורה פעמיים (enemies/types/revolver.gd, מצב בוס).
#  לשנות: WALKWAYS, TIER, SPIKE_PITS, zombie_weights().
# ============================================================

const Decor := preload("res://effects/s21_decor.gd")
const PickupScript := preload("res://pickup.gd")

const WALKWAYS := [[0.1, 420.0], [0.24, 520.0], [0.38, 460.0], [0.53, 560.0], [0.68, 480.0], [0.82, 520.0]]   # [מיקום יחסי, רוחב]
const TIER := 150.0              # גובה הקומה השנייה מעל הקרקע
const SPIKE_PITS := 6
const HARDER := [1.0, 1.15, 1.3]

var _spans := []


func zombie_weights() -> Dictionary:
	return {Registry.GLIDER: 0.22, Registry.REVOLVER: 0.16, Registry.LEAPER: 0.08, Registry.STALKER: 0.08, 0: 0.24, 1: 0.22}


func zombie_density() -> float:
	return 1.0 * float(HARDER[clampi(Settings.difficulty, 0, 2)])


func generators() -> Array:
	return [["rock", 1.5], ["lantern", 0.9], ["crate", 1.0]]


func custom_gen(gname: String, x: float) -> float:
	if not gname in ["rock", "lantern", "crate"]:
		return 0.0
	var o := Decor.Obstacle.new()
	o.kind = gname
	o.seed_v = rng.randi()
	match gname:
		"rock":
			o.size = Vector2(rng.randf_range(70.0, 110.0), rng.randf_range(36.0, 56.0))
		"lantern":   # גבוה - מחסה, אפשר לטפס עליו
			o.size = Vector2(rng.randf_range(40.0, 50.0), rng.randf_range(78.0, 92.0))
		_:
			o.size = Vector2(rng.randf_range(44.0, 60.0), rng.randf_range(36.0, 48.0))
	o.position = Vector2(x, floor_y)
	main.add_child(o)
	reserve(Rect2(x, floor_y - o.size.y, o.size.x, o.size.y))
	return o.size.x


func boss_kind() -> int:
	return Registry.REVOLVER


func music() -> String:
	return "res://music/level1_total_war.mp3"


func world_tint() -> Color:
	return Color(1.0, 0.95, 0.93)


func fog() -> bool:
	return false


func pits() -> int:
	return SPIKE_PITS


# ---- רקע: שקיעה, פסגות, צוקים, אורנים ----
func build_background(layer: CanvasLayer) -> Node:
	var bg = Backdrop.new()
	bg.level_w = level_w
	bg.sky = func(ci: CanvasItem, v: Vector2, t: float):
		Decor.dusk_sky(ci, v, t)
	bg.add_layer(0.08, func(ci: CanvasItem, sc: float, v: Vector2, t: float):
		Decor.far_peaks(ci, sc, v, 500.0, t))
	bg.add_layer(0.3, func(ci: CanvasItem, sc: float, v: Vector2, t: float):
		Decor.mid_cliffs(ci, sc, v, 590.0, t))
	bg.add_layer(0.6, func(ci: CanvasItem, sc: float, v: Vector2, t: float):
		Decor.near_pines(ci, sc, v, 626.0, t))
	layer.add_child(bg)
	return bg


# ---- העולם: קרקע סלעית בין בורות היתדות, שבילי עץ בקומה שנייה ----
func build_world() -> void:
	var pits_list: Array = main._pits.filter(func(p): return p.size() < 3)
	var x := 0.0
	for p in pits_list + [[level_w, 0.0]]:
		_ground(x, float(p[0]))
		if float(p[1]) > 0.0:
			var sp := Decor.SpikePit.new()
			sp.w = float(p[1])
			sp.depth = main.PIT_DEPTH
			sp._seed = rng.randi()
			add_world(sp, Vector2(float(p[0]), floor_y))
		x = float(p[0]) + float(p[1])
	for wk in WALKWAYS:
		var ox := level_w * float(wk[0])
		var w: float = wk[1]
		add_floor(ox, floor_y - TIER, w, "wood", true, true)
		add_ladder(ox + 12.0, floor_y - TIER)
		var fl := Decor.Flags.new()
		fl.w = w
		fl.seed_v = rng.randi()
		add_world(fl, Vector2(ox, floor_y - TIER))
		_spans.append([ox, ox + w])
		_pickup(PickupScript.AMMO if wk[0] < 0.6 else PickupScript.HEALTH, Vector2(ox + w * 0.6, floor_y - TIER - 30.0))


func _ground(x0: float, x1: float) -> void:
	var x := x0
	while x < x1 - 1.0:
		var g := Decor.CliffGround.new()
		g.w = minf(1024.0, x1 - x)
		g.depth = main.floor_thickness
		g.seed_v = rng.randi()
		add_world(g, Vector2(x, floor_y))
		x += 1024.0


func _pickup(kind: int, pos: Vector2) -> void:
	var p = PickupScript.new()
	p.kind = kind
	p.life = 100000.0
	main.add_child(p)
	p.setup(pos, Vector2.ZERO)


func build_effects() -> void:
	var fx := Decor.CliffFX.new()
	fx.vp = vp
	screen_layer.add_child(fx)


# GLIDER על כל שביל (מחכים למעלה), REVOLVER אחרי חלק מהשבילים
func extra_spawns() -> void:
	for i in _spans.size():
		var s: Array = _spans[i]
		spawn(Registry.GLIDER, lerpf(float(s[0]), float(s[1]), 0.65), floor_y - TIER)
		if i % 2 == 1:
			spawn(Registry.REVOLVER, float(s[1]) + 320.0)
