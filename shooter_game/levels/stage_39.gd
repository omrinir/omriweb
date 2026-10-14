extends "res://levels/stage_base.gd"
# ============================================================
#  STAGE 39 - "THE STADIUM" (אזור חמישי - דרום-מזרח, שלב 3) - "THEY LEARNED THE GAME"
#  המרקנה בלילה של משחק (effects/s39_decor.gd): קערת יציעים מלאה בקהל זומבים קופץ, גג טבעת עם זרקורים, סינליזדורים, דגלים,
#  שלטי לד. הולכים על מסלול הריצה - ובסוף נכנסים לדשא, אל השער. (הסיפור: המשחק האחרון שלא נגמר.)
#  קומה שנייה: המעבר העליון של היציעים הקרובים (STANDS).
#  הקהל: CrowdHype ("THE 12TH MAN") - בכל יציע קאפו עם מגפון ותוף ומד CROWD HYPE. נלחם ליד היציע / הורג שם זומבים -> ההיפ עולה.
#           100% = PITCH INVASION: אוהדים קופצים מעל המעקה למסלול + זיקוקים בוערים. לירות בקאפו = היציע משתתק.
#           הם לומדים: אחרי קאפו אחד, האחרים מתכופפים מאחורי התוף כשמכוונים עליהם (לשבור את התוף / לעלות מהצד).
#  מלכודת: Floodlight - מגדלי זרקור שסורקים את המסלול: נכנסת לאור -> כל הזומבים יודעים איפה אתה ומסתערים.
#  זומבים: HOOLIGAN (סינליזדור מאחוריך, שירה = הסתערות), STRIKER (בועט כדור, לוב מעל מחסה), REFEREE (כרטיסים = נשק תקוע),
#          CAPOEIRA, COURIER, REVIVER, רגילים, רצים.
#  בוס נייח: GOALKEEPER (enemies/types/goalkeeper.gd) בשער בסוף הדשא - קורא את הכוונת שלך.
#  לשנות: STANDS, TIER, LIGHTS, GRASS_FROM, MOBS, zombie_weights().
# ============================================================

const Decor := preload("res://effects/s39_decor.gd")
const PickupScript := preload("res://pickup.gd")

const SOUNDS := {
	"st_boo": {"drive": 1.4, "layers": [["N", 0, 0, 0.0, 1.0, 0.2, 1.5, 0.6, 0.15, 0], ["V", 140, 110, 0.0, 1.0, 0.2, 1.5, 0.4, 1.0, 0.05, 0, [400, 900, 4]]]},
	"st_drum": [["S", 130, 55, 0.0, 0.2, 0.0, 16.0, 0.85, 1.0, 0], ["N", 0, 0, 0.0, 0.06, 0.0, 40.0, 0.35, 0.4, 0, 0.5]],
	"st_roar": {"drive": 1.6, "layers": [["N", 0, 0, 0.0, 1.8, 0.25, 1.1, 0.8, 0.2, 0], ["V", 170, 240, 0.0, 1.8, 0.25, 1.1, 0.55, 1.0, 0.05, 0, [500, 1200, 4]]]},
	"st_spot": [["S", 400, 800, 0.0, 0.3, 0.0, 6.0, 0.25, 1.0, 0], ["N", 0, 0, 0.0, 0.3, 0.0, 6.0, 0.15, 0.6, 0, 0.5]],
}

const STANDS := [[0.1, 420.0], [0.34, 460.0], [0.58, 420.0]]
const TIER := 130.0
const LIGHTS := [0.23, 0.47, 0.71, 0.86]
const GRASS_FROM := 2400.0          # כמה פיקסלים לפני הסוף מתחיל הדשא
const MOBS := [0.2, 0.44, 0.66, 0.8]
const HARDER := [1.0, 1.15, 1.3]

var _stands := []


func zombie_weights() -> Dictionary:
	return {Registry.HOOLIGAN: 0.06, Registry.STRIKER: 0.04, Registry.REFEREE: 0.02, Registry.CAPOEIRA: 0.02, Registry.COURIER: 0.02,
		Registry.REVIVER: 0.02, 0: 0.48, 1: 0.34}


func zombie_density() -> float:
	return 1.0 * float(HARDER[clampi(Settings.difficulty, 0, 2)])


func generators() -> Array:
	return [["ad_board", 1.0], ["bench", 0.6], ["cooler", 0.8]]


func custom_gen(gname: String, x: float) -> float:
	if not gname in ["ad_board", "bench", "cooler"]:
		return 0.0
	var o := Decor.Obstacle.new()
	o.kind = gname
	o.seed_v = rng.randi()
	match gname:
		"ad_board":
			o.size = Vector2(rng.randf_range(100.0, 120.0), rng.randf_range(36.0, 42.0))
		"bench":
			o.size = Vector2(rng.randf_range(110.0, 130.0), rng.randf_range(48.0, 54.0))
		_:
			o.size = Vector2(rng.randf_range(60.0, 70.0), rng.randf_range(34.0, 40.0))
	o.position = Vector2(x, floor_y)
	main.add_child(o)
	reserve(Rect2(x, floor_y - o.size.y, o.size.x, o.size.y))
	return o.size.x


func boss_kind() -> int:
	return Registry.GOALKEEPER


func music() -> String:
	return "res://music/level1_total_war.mp3"


func world_tint() -> Color:
	return Color(0.95, 0.97, 1.0)


func fog() -> bool:
	return false


func pits() -> int:
	return 0


func build_background(layer: CanvasLayer) -> Node:
	var bg = Backdrop.new()
	bg.level_w = level_w
	bg.sky = func(ci: CanvasItem, v: Vector2, t: float):
		Decor.stadium_sky(ci, v, t)
	bg.add_layer(0.08, func(ci: CanvasItem, sc: float, v: Vector2, t: float):
		Decor.far_stands(ci, sc, v, 580.0, t))
	bg.add_layer(0.4, func(ci: CanvasItem, sc: float, v: Vector2, t: float):
		Decor.mid_boards(ci, sc, v, 636.0, t))
	layer.add_child(bg)
	return bg


func build_world() -> void:
	var x := 0.0
	var gx := level_w - GRASS_FROM
	while x < level_w:   # מסלול ריצה, ובסוף דשא
		var g := Decor.TrackGround.new()
		var end := gx if x < gx else level_w
		g.w = minf(1024.0, end - x)
		g.depth = main.floor_thickness
		g.grass = x >= gx
		add_world(g, Vector2(x, floor_y))
		x += g.w
	for s in STANDS:   # יציעים קרובים: מעבר עליון + קהל שזורק
		var w: float = s[1]
		var dx := level_w * float(s[0])
		var st := Decor.Stand.new()
		st.w = w
		st.tier = TIER
		add_world(st, Vector2(dx, floor_y))
		var pf = add_floor(dx - 10.0, floor_y - TIER, w + 20.0, "concrete", false, false)
		pf.visible = false
		add_ladder(dx + 6.0, floor_y - TIER)
		reserve(Rect2(dx - 10.0, floor_y - TIER, 50.0, TIER))
		var ch := Decor.CrowdHype.new()   # הקאפו + מד ההיפ (PITCH INVASION)
		ch.stand = st
		ch.w = w
		ch.tier = TIER
		add_world(ch, Vector2(dx, floor_y))
		_stands.append([dx, dx + w])
		_pickup(PickupScript.AMMO if s[0] < 0.4 else PickupScript.HEALTH, Vector2(dx + w * 0.7, floor_y - TIER - 30.0))
	for f in LIGHTS:   # מגדלי זרקור
		var fl := Decor.Floodlight.new()
		add_world(fl, Vector2(level_w * float(f), floor_y))
	# השער מאחורי השוער
	var bx := level_w - 720.0
	var goal := Decor.Goal.new()
	add_world(goal, Vector2(bx - 90.0, floor_y))
	reserve(Rect2(bx - 200.0, floor_y - 160.0, 400.0, 160.0))
	main.set_meta("boss_x", bx)


func _pickup(kind: int, pos: Vector2) -> void:
	var p = PickupScript.new()
	p.kind = kind
	p.life = 100000.0
	main.add_child(p)
	p.setup(pos, Vector2.ZERO)


func build_effects() -> void:
	var fx := Decor.StadiumFX.new()
	fx.vp = vp
	fx.floor_y = floor_y
	screen_layer.add_child(fx)


# טורסידות: 2 HOOLIGAN עם זומבים, STRIKER מאחור, REFEREE ליד. על המעבר העליון - צופים
func extra_spawns() -> void:
	for i in MOBS.size():
		var mx := level_w * float(MOBS[i])
		spawn(Registry.HOOLIGAN, mx)
		spawn(Registry.HOOLIGAN, mx + 40.0)
		spawn(0, mx + 80.0)
		spawn(1, mx + 120.0)
		spawn(Registry.STRIKER, mx + 360.0)
		if i % 2 == 1:
			spawn(Registry.REFEREE, mx + 220.0)
	for s in _stands:
		spawn(0, lerpf(float(s[0]), float(s[1]), 0.5), floor_y - TIER)
		spawn(Registry.HOOLIGAN, lerpf(float(s[0]), float(s[1]), 0.8), floor_y - TIER)
