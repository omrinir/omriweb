extends "res://levels/stage_base.gd"
# ============================================================
#  STAGE 50 - "TANGO CEMETERY" (אזור שישי - החרוט הדרומי) - "THEY LEARNED TO PULL THE STRINGS"
#  (הסיפור: בואנוס איירס בלילה. בית הקברות רקולטה - עיר של מאוזוליאומים משיש - והמתים כבר לא שוכבים בשקט.
#   מכשף במגבעת מושך בחוטים, בן שביעי מיילל לירח, וארונות שנפתחים מבפנים.)
#  (effects/s50_decor.gd): שמיים כחולים-כהים עם ירח מלא שמתחבא בעננים, קו הרקיע של רקולטה וכנסיית הפילאר,
#  שורות מאוזוליאומים עם מלאכים ונרות, ברושים, גדר ברזל וחתולים עם עיניים זוהרות.
#  הירח (MoonCycle): עננים -> "THE CLOUDS ARE PARTING..." (אזהרה WARN_T) -> "FULL MOON" (FULL_T) -> עננים.
#    בירח מלא הלוביזונים נהיים זאבים. המסך מואר בכסף.
#  קומה שנייה: גגות מאוזוליאומים (MAUSOLEUMS) עם סולמות. מלמעלה: תחמושת וחיים.
#  מלכודות: AngelStatue - פסל מלאך נסדק ונופל לכיוונך (אזהרה: סדקים + חריקה; ירייה בכן מפילה אותו על זומבים),
#           CryptDoor - דלת קריפטה רועדת ונפרצת, מתים יוצאים ממנה.
#  זומבים: PUPPETEER (חוטים על זומבים), LOBIZON (זאב בירח מלא), COFFIN_BREAKER (פורץ מארון), רגילים, רצים.
#  בוס: THE BOKOR (PUPPETEER ענק, enemies/types/puppeteer.gd) - מול שער רקולטה בסוף.
#  לשנות: MAUSOLEUMS, TIER, ANGELS, CRYPTS, COFFINS, SQUADS, zombie_weights().
# ============================================================

const Decor := preload("res://effects/s50_decor.gd")
const PickupScript := preload("res://pickup.gd")

const SOUNDS := {
	"rc_crack": [["N", 0, 0, 0.0, 0.25, 0.0, 14.0, 0.5, 0.7, 0, 0.8], ["S", 300, 120, 0.0, 0.2, 0.0, 16.0, 0.25, 1.0, 0.1]],
	"rc_creak": [["S", 140, 110, 0.0, 0.7, 0.05, 2.5, 0.3, 1.0, 0.12], ["N", 0, 0, 0.0, 0.5, 0.05, 4.0, 0.12, 0.3, 0, 0.5]],
	"rc_smash": [["N", 0, 0, 0.0, 0.8, 0.0, 5.0, 0.9, 0.5, 0, 0.9], ["S", 80, 40, 0.0, 0.5, 0.0, 7.0, 0.7, 1.0, 0.1], ["N", 0, 0, 0.05, 0.6, 0.0, 8.0, 0.3, 0.9, 0, 0.5]],
	"rc_rattle": [["N", 0, 0, 0.0, 0.5, 0.0, 6.0, 0.4, 0.5, 0, 0.7, [1800, 2600, 22]], ["S", 90, 70, 0.0, 0.4, 0.0, 9.0, 0.3, 1.0, 0.2]],
	"rc_burst": [["N", 0, 0, 0.0, 0.7, 0.0, 5.0, 0.9, 0.4, 0, 0.9], ["S", 60, 35, 0.0, 0.6, 0.0, 6.0, 0.7, 1.0, 0.1]],
	"rc_howl": [["S", 300, 520, 0.0, 0.8, 0.25, 1.6, 0.25, 1.0, 0.08], ["S", 520, 360, 0.8, 1.6, 0.0, 1.4, 0.22, 1.0, 0.06], ["N", 0, 0, 0.0, 2.0, 0.4, 1.2, 0.05, 0.4, 0, 0.3]],
}

const MAUSOLEUMS := [[0.17, 330.0], [0.44, 360.0], [0.7, 330.0]]
const TIER := 150.0
const ANGELS := [0.24, 0.52, 0.78, 0.9]
const CRYPTS := [0.13, 0.35, 0.6, 0.83]
const COFFINS := [0.08, 0.29, 0.48, 0.57, 0.74, 0.88]
const SQUADS := [0.11, 0.32, 0.5, 0.66, 0.85]
const HARDER := [1.0, 1.1, 1.25]

var _maus := []


func zombie_weights() -> Dictionary:
	return {Registry.PUPPETEER: 0.02, Registry.LOBIZON: 0.035, Registry.COFFIN_BREAKER: 0.04, 0: 0.55, 1: 0.3}


func zombie_density() -> float:
	return 1.0 * float(HARDER[clampi(Settings.difficulty, 0, 2)])


func generators() -> Array:
	return [["grave", 1.3], ["sarcophagus", 0.7], ["urn", 0.6]]


func custom_gen(gname: String, x: float) -> float:
	if not gname in ["grave", "sarcophagus", "urn"]:
		return 0.0
	if not free_x(x, 20.0) or not free_x(x + 100.0, 20.0):   # לא בתוך מלכודת / סולם / זירת הבוס
		return 80.0
	var o := Decor.Obstacle.new()
	o.kind = gname
	o.seed_v = rng.randi()
	match gname:
		"grave":
			o.size = Vector2(rng.randf_range(40.0, 52.0), rng.randf_range(50.0, 62.0))
		"sarcophagus":
			o.size = Vector2(rng.randf_range(90.0, 110.0), rng.randf_range(38.0, 46.0))
		_:
			o.size = Vector2(rng.randf_range(34.0, 40.0), rng.randf_range(54.0, 64.0))
	o.position = Vector2(x, floor_y)
	main.add_child(o)
	reserve(Rect2(x, floor_y - o.size.y, o.size.x, o.size.y))
	return o.size.x


func boss_kind() -> int:
	return Registry.PUPPETEER


func music() -> String:
	return "res://music/level2_suspense.mp3"


func world_tint() -> Color:
	return Color(0.85, 0.88, 1.0)


func fog() -> bool:
	return false


func pits() -> int:
	return 0


func build_background(layer: CanvasLayer) -> Node:
	var bg = Backdrop.new()
	bg.level_w = level_w
	bg.sky = func(ci: CanvasItem, v: Vector2, t: float):
		Decor.cem_sky(ci, v, t)
	bg.add_layer(0.06, func(ci: CanvasItem, sc: float, v: Vector2, t: float):
		Decor.far_city(ci, sc, v, 560.0, t))
	bg.add_layer(0.28, func(ci: CanvasItem, sc: float, v: Vector2, t: float):
		Decor.mid_tombs(ci, sc, v, 640.0, t))
	bg.add_layer(0.6, func(ci: CanvasItem, sc: float, v: Vector2, t: float):
		Decor.near_cypress(ci, sc, v, 648.0, t))
	layer.add_child(bg)
	return bg


func build_world() -> void:
	main.add_child(Decor.MoonCycle.new())   # הירח: עננים / אזהרה / ירח מלא (משותף לכל השלב)
	var x := 0.0
	while x < level_w:
		var g := Decor.CemeteryGround.new()
		g.w = minf(1024.0, level_w - x)
		g.depth = main.floor_thickness
		add_world(g, Vector2(x, floor_y))
		x += 1024.0
	for i in MAUSOLEUMS.size():   # גגות מאוזוליאומים = קומה שנייה
		var m: Array = MAUSOLEUMS[i]
		var w: float = m[1]
		var dx := level_w * float(m[0])
		var mz := Decor.Mausoleum.new()
		mz.w = w
		mz.tier = TIER
		mz.seed_v = i * 7 + 3
		add_world(mz, Vector2(dx, floor_y))
		var pf = add_floor(dx - 4.0, floor_y - TIER, w + 8.0, "concrete", false, false)
		pf.visible = false
		add_ladder(dx + 30.0, floor_y - TIER)
		add_ladder(dx + w - 52.0, floor_y - TIER)
		reserve(Rect2(dx, floor_y - 40.0, w, 40.0))
		_maus.append([dx, dx + w])
		_pickup(PickupScript.AMMO if m[0] < 0.6 else PickupScript.HEALTH, Vector2(dx + w * 0.5, floor_y - TIER - 30.0))
		if i == 1:
			_pickup(PickupScript.AMMO, Vector2(dx + w * 0.3, floor_y - TIER - 30.0))
	for f in ANGELS:   # פסלי מלאכים שנופלים לכיוון שממנו אתה מגיע
		var ax := level_w * float(f)
		if not free_x(ax, 60.0):
			ax += 160.0
		var a := Decor.AngelStatue.new()
		a.dir = -1.0
		add_world(a, Vector2(ax, floor_y))
		reserve(Rect2(ax - 30.0, floor_y - 120.0, 60.0, 120.0))
	for f in CRYPTS:
		var cx := level_w * float(f)
		if not free_x(cx, 50.0):
			cx += 150.0
		var cd := Decor.CryptDoor.new()
		add_world(cd, Vector2(cx, floor_y))
		reserve(Rect2(cx - 50.0, floor_y - 130.0, 100.0, 130.0))
	# שער רקולטה מאחורי הבוס
	var gx := level_w - 520.0
	add_world(Decor.RecoletaGate.new(), Vector2(gx, floor_y))
	reserve(Rect2(gx - 700.0, floor_y - 60.0, 600.0, 60.0))   # זירת הבוס פנויה
	_pickup(PickupScript.HEALTH, Vector2(gx - 760.0, floor_y - 30.0))
	_pickup(PickupScript.AMMO, Vector2(gx - 820.0, floor_y - 30.0))


func _pickup(kind: int, pos: Vector2) -> void:
	var p = PickupScript.new()
	p.kind = kind
	p.life = 100000.0
	main.add_child(p)
	p.setup(pos, Vector2.ZERO)


func build_effects() -> void:
	var fx := Decor.MoonFX.new()
	fx.vp = vp
	screen_layer.add_child(fx)


# ארונות לאורך השביל (אחד על גג), ובכל קבוצה: מכשף עם 2-3 בובות פוטנציאליות לידו / לוביזון
func extra_spawns() -> void:
	for f in COFFINS:
		var cx := level_w * float(f)
		if not free_x(cx, 30.0):
			cx += 120.0
		spawn(Registry.COFFIN_BREAKER, cx)
	if _maus.size() > 2:
		spawn(Registry.COFFIN_BREAKER, lerpf(float(_maus[2][0]), float(_maus[2][1]), 0.6), floor_y - TIER)
	for i in SQUADS.size():
		var sx := level_w * float(SQUADS[i])
		if i % 2 == 0:
			spawn(Registry.PUPPETEER, sx + 220.0)
			spawn(0, sx)
			spawn(0, sx + 60.0)
			spawn(1, sx + 120.0)
		else:
			spawn(Registry.LOBIZON, sx)
			spawn(0, sx + 140.0)
	for b in _maus:   # על הגגות: לוביזון אחד שמחכה
		if rng.randf() < 0.5:
			spawn(Registry.LOBIZON, lerpf(float(b[0]), float(b[1]), 0.4), floor_y - TIER)
