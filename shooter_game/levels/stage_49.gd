extends "res://levels/stage_base.gd"
# ============================================================
#  STAGE 49 - "RIVER DELTA" (אזור שישי - החרוט הדרומי, שלב 4) - "THEY LEARNED TO BREATHE WATER"
#  (הסיפור: מבואנוס איירס הגיבור עולה צפונה בנהר, אל הדלתא של טיגרה. אלפי איים, ערוצים ובתים על כלונסאות - והמתים
#   כבר לא צריכים לנשום. הם מחכים מתחת למים, צפים כמו גופות נפוחות, ומשהו ירוק צומח עליהם.)
#  (effects/s49_decor.gd): בוקר ערפילי, הנהר הרחב עם איים וערבות בוכיות, בתים על כלונסאות, מועדוני חתירה בסגנון טיודור,
#  קנים ופרחי סייבו. טיילת קרשים שחוצים אותה ערוצי מים (CHANNELS). קומה שנייה: מרפסות של בתים על כלונסאות (STILTS).
#  מלכודות: SinkingDock - קרשים רקובים שנשברים מתחתיך (נזק + בוץ), TideDirector - "THE RIVER RISES": הנהר מציף את הטיילת
#           כל חצי דקה בערך -> לעלות למרפסות / על מכשולים.
#  זומבים: FLOATER (גופה נפוחה מגז נהר - מתפוצצת לענן רעיל), ANGLER (פנס "לוס מאלה" על מוט - מתחבא במים וזונק),
#          SPOREWALKER (פטריות - ענן נבגים, ואחרי המוות צומח גבעול שמקים את המתים), רגילים, רצים.
#  בוס: THE RIVER MOTHER (FLOATER ענקית, enemies/types/floater.gd) - מול מועדון החתירה בסוף.
#  לשנות: STILTS, TIER, CHANNELS, CHANNEL_W, DOCKS, SQUADS, zombie_weights().
# ============================================================

const Decor := preload("res://effects/s49_decor.gd")
const PickupScript := preload("res://pickup.gd")

const SOUNDS := {
	"rd_creak": [["S", 110, 85, 0.0, 0.5, 0.0, 3.5, 0.3, 1.0, 0.18], ["N", 0, 0, 0.0, 0.45, 0.0, 5.0, 0.12, 0.3, 0, 0.6]],
	"rd_snap": [["C", 0, 0, 0.0, 0.06, 0.0, 40.0, 0.6, 1.0, 0], ["N", 0, 0, 0.0, 0.35, 0.0, 9.0, 0.4, 0.5, 0, 0.7], ["S", 140, 80, 0.0, 0.2, 0.0, 14.0, 0.3, 1.0, 0.1]],
	"rd_tide": [["N", 0, 0, 0.0, 2.6, 0.6, 0.8, 0.35, 0.2, 0, 0.3], ["S", 60, 50, 0.0, 2.5, 0.5, 0.8, 0.3, 1.0, 0.1]],
}

const STILTS := [[0.17, 320.0], [0.44, 360.0], [0.7, 320.0]]
const TIER := 150.0
const CHANNELS := [0.08, 0.24, 0.36, 0.53, 0.62, 0.79, 0.9]
const CHANNEL_W := 140.0
const DOCKS := [0.13, 0.29, 0.41, 0.57, 0.66, 0.74, 0.84]
const SQUADS := [0.11, 0.3, 0.48, 0.65, 0.82]
const HARDER := [1.0, 1.1, 1.25]

var _decks := []
var _tide = null


func zombie_weights() -> Dictionary:
	return {Registry.FLOATER: 0.04, Registry.ANGLER: 0.03, Registry.SPOREWALKER: 0.05, 0: 0.55, 1: 0.33}


func zombie_density() -> float:
	return 1.0 * float(HARDER[clampi(Settings.difficulty, 0, 2)])


func generators() -> Array:
	return [["wreck", 0.8], ["crates", 1.2], ["nets", 1.0]]


func custom_gen(gname: String, x: float) -> float:
	if not gname in ["wreck", "crates", "nets"]:
		return 0.0
	if not free_x(x, 20.0) or not free_x(x + 110.0, 20.0):   # לא בתוך ערוץ / מלכודת / סולם / זירת הבוס
		return 80.0
	var o := Decor.Obstacle.new()
	o.kind = gname
	o.seed_v = rng.randi()
	match gname:
		"wreck":
			o.size = Vector2(rng.randf_range(100.0, 120.0), rng.randf_range(46.0, 54.0))
		"crates":
			o.size = Vector2(rng.randf_range(70.0, 84.0), rng.randf_range(48.0, 56.0))
		_:
			o.size = Vector2(rng.randf_range(60.0, 72.0), rng.randf_range(40.0, 48.0))
	o.position = Vector2(x, floor_y)
	main.add_child(o)
	reserve(Rect2(x, floor_y - o.size.y, o.size.x, o.size.y))
	return o.size.x


func boss_kind() -> int:
	return Registry.FLOATER


func music() -> String:
	return "res://music/level2_suspense.mp3"


func world_tint() -> Color:
	return Color(0.94, 0.98, 0.94)


func fog() -> bool:
	return true


func pits() -> int:
	return 0


func build_background(layer: CanvasLayer) -> Node:
	var bg = Backdrop.new()
	bg.level_w = level_w
	bg.sky = func(ci: CanvasItem, v: Vector2, t: float):
		Decor.delta_sky(ci, v, t)
	bg.add_layer(0.06, func(ci: CanvasItem, sc: float, v: Vector2, t: float):
		Decor.far_islands(ci, sc, v, 560.0, t))
	bg.add_layer(0.28, func(ci: CanvasItem, sc: float, v: Vector2, t: float):
		Decor.mid_stilts(ci, sc, v, 640.0, t))
	bg.add_layer(0.6, func(ci: CanvasItem, sc: float, v: Vector2, t: float):
		Decor.near_reeds(ci, sc, v, 652.0, t))
	layer.add_child(bg)
	return bg


func build_world() -> void:
	var x := 0.0
	while x < level_w:
		var g := Decor.DeltaGround.new()
		g.w = minf(1024.0, level_w - x)
		g.depth = main.floor_thickness
		add_world(g, Vector2(x, floor_y))
		x += 1024.0
	_tide = Decor.TideDirector.new()
	_tide.floor_y = floor_y
	main.add_child(_tide)
	for i in STILTS.size():   # מרפסות של בתים על כלונסאות = קומה שנייה
		var s: Array = STILTS[i]
		var w: float = s[1]
		var dx := level_w * float(s[0])
		var dk := Decor.StiltDeck.new()
		dk.w = w
		dk.tier = TIER
		dk.col = Decor.HOUSE[(i * 2) % Decor.HOUSE.size()]
		add_world(dk, Vector2(dx, floor_y))
		var pf = add_floor(dx - 4.0, floor_y - TIER, w + 8.0, "concrete", false, false)
		pf.visible = false
		add_ladder(dx + 30.0, floor_y - TIER)
		add_ladder(dx + w - 52.0, floor_y - TIER)
		reserve(Rect2(dx, floor_y - 40.0, w, 40.0))
		_decks.append([dx, dx + w])
		_pickup(PickupScript.AMMO if s[0] < 0.6 else PickupScript.HEALTH, Vector2(dx + w * 0.5, floor_y - TIER - 30.0))
	for f in CHANNELS:   # ערוצי מים שחוצים את הטיילת
		var cx := level_w * float(f)
		if not free_x(cx, 10.0) or not free_x(cx + CHANNEL_W, 10.0):
			continue
		var ch := Decor.Channel.new()
		ch.w = CHANNEL_W
		add_world(ch, Vector2(cx, floor_y))
		_tide.spans.append([cx, cx + CHANNEL_W])
		reserve(Rect2(cx, floor_y - 30.0, CHANNEL_W, 30.0))
	for f in DOCKS:   # קרשים רקובים
		var kx := level_w * float(f)
		if not free_x(kx, 10.0) or not free_x(kx + Decor.SinkingDock.W, 10.0):
			kx += 160.0
			if not free_x(kx, 10.0) or not free_x(kx + Decor.SinkingDock.W, 10.0):
				continue
		var sd := Decor.SinkingDock.new()
		add_world(sd, Vector2(kx, floor_y))
		_tide.holes.append(sd)
		reserve(Rect2(kx, floor_y - 30.0, Decor.SinkingDock.W, 30.0))
	# מועדון החתירה מאחורי הבוס
	var gx := level_w - 470.0
	add_world(Decor.RowingClub.new(), Vector2(gx, floor_y))
	reserve(Rect2(gx - 760.0, floor_y - 60.0, 660.0, 60.0))   # זירת הבוס פנויה
	_pickup(PickupScript.HEALTH, Vector2(gx - 820.0, floor_y - 30.0))
	_pickup(PickupScript.AMMO, Vector2(gx - 880.0, floor_y - 30.0))


func _pickup(kind: int, pos: Vector2) -> void:
	var p = PickupScript.new()
	p.kind = kind
	p.life = 100000.0
	main.add_child(p)
	p.setup(pos, Vector2.ZERO)


func build_effects() -> void:
	var fx := Decor.DeltaFX.new()
	fx.vp = vp
	screen_layer.add_child(fx)


# קבוצות: גופה נפוחה מלפנים עם רגילים לידה, פטרייתי מאחור. בכל ערוץ - דייג (ANGLER) מחכה. על המרפסות - פטרייתי
func extra_spawns() -> void:
	for i in SQUADS.size():
		var sx := level_w * float(SQUADS[i])
		spawn(Registry.FLOATER, sx)
		spawn(0, sx + 60.0)
		spawn(Registry.SPOREWALKER, sx + 200.0)
		if i % 2 == 1:
			spawn(Registry.SPOREWALKER, sx + 250.0)
	if _tide != null:
		for s in _tide.spans:
			if float(s[0]) > 900.0:
				spawn(Registry.ANGLER, lerpf(float(s[0]), float(s[1]), 0.5))
	for b in _decks:
		spawn(Registry.SPOREWALKER, lerpf(float(b[0]), float(b[1]), 0.6), floor_y - TIER)
