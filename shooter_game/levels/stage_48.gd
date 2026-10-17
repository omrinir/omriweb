extends "res://levels/stage_base.gd"
# ============================================================
#  STAGE 48 - "OLD QUARTER" (אזור שישי - החרוט הדרומי, שלב 3) - "THEY LEARNED STEEL"
#  (הסיפור: מהפמפס הגיבור מגיע לבואנוס איירס. בלה בוקה ובסן טלמו הטנגו לא נפסק אף פעם - והמתים כבר עובדים בנמל:
#   מישהו בריג' לפועלים זרועות רובוטיות עם תותחים. בסוף, על במת קמיניטו, מחכה מי שבנה אותם - THE MACHINIST.)
#  (effects/s48_decor.gd): לילה, ירח, האובליסק, גשר המעבורת ומנופי הנמל, בתי הפח הצבעוניים עם כביסה, פנסי ברזל,
#  שלטי פילטאדו, זוגות טנגו ונגן בנדוניאון. הרחוב מרוצף אבנים עם פסי חשמלית.
#  קומה שנייה: מרפסות הברזל של בתי הקונבנטיו (WALKWAYS) + סולמות. במת קמיניטו (STAGE_W) לפני רחבת הבוס.
#  מלכודות: Tram - חשמלית שועטת לאורך קטע רחוב (TRAMS) אחרי פעמון: לטפס למרפסת או קפיצה כפולה.
#           SparkWire - כבל חשמלית קרוע בשלולית (WIRES): מתפצפץ ואז פורק - פוגע גם בזומבים.
#  זומבים: IRONARMS (זרועות רובוטיות שיורות), TANGO (זוג רקדנים שמסתובבים מהקליעים), CLOCKWORK (בובת קפיץ), רגילים, רצים.
#  בוס: THE MACHINIST (enemies/types/ironarms.gd בגרסת בוס - ארבע זרועות, רקטות, REBUILD).
#  לשנות: WALKWAYS, TIER, TRAMS, WIRES, TANGOS, STAGE_W, zombie_weights().
# ============================================================

const Decor := preload("res://effects/s48_decor.gd")
const PickupScript := preload("res://pickup.gd")

const SOUNDS := {
	"oq_bell": [["S", 1320, 1318, 0.0, 0.6, 0.0, 5.0, 0.3, 1.0, 0], ["S", 1980, 1975, 0.0, 0.5, 0.0, 6.0, 0.18, 1.0, 0], ["S", 2640, 2635, 0.0, 0.3, 0.0, 9.0, 0.08, 1.0, 0]],
	"oq_crackle": [["C", 0, 0, 0.0, 0.8, 0.0, 3.0, 0.4, 1.0, 0], ["N", 0, 0, 0.0, 0.8, 0.0, 4.0, 0.15, 0.9, 0, 0.3]],
}

const WALKWAYS := [[0.14, 340.0], [0.33, 300.0], [0.52, 360.0], [0.7, 320.0], [0.84, 300.0]]
const TIER := 150.0
const TRAMS := [[0.3, 1000.0, 1.0], [0.68, 1000.0, -1.0]]   # [התחלה, אורך, כיוון]
const WIRES := [0.08, 0.24, 0.46, 0.6, 0.78]
const TANGOS := [0.2, 0.42, 0.62, 0.8]
const STAGE_W := 560.0
const STAGE_TIER := 70.0
const HARDER := [1.0, 1.15, 1.3]

var _walks := []


func zombie_weights() -> Dictionary:
	return {Registry.IRONARMS: 0.03, Registry.TANGO: 0.02, Registry.CLOCKWORK: 0.05, 0: 0.5, 1: 0.35}


func zombie_density() -> float:
	return 1.0 * float(HARDER[clampi(Settings.difficulty, 0, 2)])


func generators() -> Array:
	return [["kiosk", 0.8], ["cart", 1.0], ["planter", 1.0]]


func custom_gen(gname: String, x: float) -> float:
	if not gname in ["kiosk", "cart", "planter"]:
		return 0.0
	var o := Decor.Obstacle.new()
	o.kind = gname
	o.seed_v = rng.randi()
	match gname:
		"kiosk":
			o.size = Vector2(rng.randf_range(54.0, 62.0), rng.randf_range(70.0, 78.0))
		"cart":
			o.size = Vector2(rng.randf_range(62.0, 72.0), rng.randf_range(44.0, 50.0))
		_:
			o.size = Vector2(rng.randf_range(44.0, 52.0), rng.randf_range(40.0, 46.0))
	o.position = Vector2(x, floor_y)
	main.add_child(o)
	reserve(Rect2(x, floor_y - o.size.y, o.size.x, o.size.y))
	return o.size.x


func boss_kind() -> int:
	return Registry.IRONARMS


func music() -> String:
	return "res://music/level2_suspense.mp3"


func world_tint() -> Color:
	return Color(0.86, 0.86, 1.0)


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
		Decor.oq_sky(ci, v, t)
	bg.add_layer(0.06, func(ci: CanvasItem, sc: float, v: Vector2, t: float):
		Decor.far_city(ci, sc, v, 560.0, t))
	bg.add_layer(0.28, func(ci: CanvasItem, sc: float, v: Vector2, t: float):
		Decor.mid_houses(ci, sc, v, 618.0, t))
	bg.add_layer(0.6, func(ci: CanvasItem, sc: float, v: Vector2, t: float):
		Decor.near_street(ci, sc, v, 648.0, t))
	layer.add_child(bg)
	return bg


func build_world() -> void:
	var x := 0.0
	var i := 0
	while x < level_w:
		var g := Decor.CobbleGround.new()
		g.w = minf(1024.0, level_w - x)
		g.depth = main.floor_thickness
		g.seed_v = i * 31 + 7
		add_world(g, Vector2(x, floor_y))
		x += 1024.0
		i += 1
	for k in WALKWAYS.size():   # בתי קונבנטיו עם מרפסת ברזל
		var b: Array = WALKWAYS[k]
		var w: float = b[1]
		var dx := level_w * float(b[0])
		var cv := Decor.Conventillo.new()
		cv.w = w
		cv.tier = TIER
		cv.seed_v = k * 2 + 1
		add_world(cv, Vector2(dx, floor_y))
		var pf = add_floor(dx - 4.0, floor_y - TIER, w + 8.0, "concrete", false, false)
		pf.visible = false
		add_ladder(dx + 30.0, floor_y - TIER)
		add_ladder(dx + w - 54.0, floor_y - TIER)
		reserve(Rect2(dx, floor_y - 40.0, w, 40.0))
		_walks.append([dx, dx + w])
		_pickup(PickupScript.AMMO if k % 2 == 0 else PickupScript.HEALTH, Vector2(dx + w * 0.5, floor_y - TIER - 30.0))
	for t in TRAMS:   # חשמליות
		var tr := Decor.Tram.new()
		tr.span = float(t[1])
		tr.dir = float(t[2])
		add_world(tr, Vector2(level_w * float(t[0]), floor_y))
	for f in WIRES:   # כבלים קרועים
		var wx := level_w * float(f)
		var sw := Decor.SparkWire.new()
		add_world(sw, Vector2(wx, floor_y))
		reserve(Rect2(wx - 130.0, floor_y - 60.0, 240.0, 60.0))
	# במת קמיניטו לפני רחבת הבוס
	var sx := level_w - 1500.0
	var st := Decor.TangoStage.new()
	st.w = STAGE_W
	st.tier = STAGE_TIER
	add_world(st, Vector2(sx, floor_y))
	var sf = add_floor(sx, floor_y - STAGE_TIER, STAGE_W, "concrete", false, false)
	sf.visible = false
	reserve(Rect2(sx - 40.0, floor_y - STAGE_TIER, STAGE_W + 80.0, STAGE_TIER))
	_pickup(PickupScript.HEALTH, Vector2(sx + STAGE_W * 0.5, floor_y - STAGE_TIER - 30.0))
	_pickup(PickupScript.AMMO, Vector2(sx + STAGE_W * 0.8, floor_y - STAGE_TIER - 30.0))
	reserve(Rect2(level_w - 700.0, floor_y - 60.0, 500.0, 60.0))   # רחבת הבוס נקייה


func _pickup(kind: int, pos: Vector2) -> void:
	var p = PickupScript.new()
	p.kind = kind
	p.life = 100000.0
	main.add_child(p)
	p.setup(pos, Vector2.ZERO)


func build_effects() -> void:
	var fx := Decor.QuarterFX.new()
	fx.vp = vp
	screen_layer.add_child(fx)


# זוגות טנגו ברחוב, IRONARMS שומרים על המרפסות, בובות קפיץ בקבוצות
func extra_spawns() -> void:
	for f in TANGOS:
		var z := spawn(Registry.TANGO, level_w * float(f))
		if z != null:
			z.dormant = false
	for k in _walks.size():
		var w: Array = _walks[k]
		var y := floor_y - TIER
		spawn(Registry.IRONARMS if k % 2 == 0 else Registry.CLOCKWORK, lerpf(float(w[0]), float(w[1]), 0.6), y)
	for f in [0.27, 0.55, 0.75]:
		var cx: float = level_w * float(f)
		spawn(Registry.CLOCKWORK, cx)
		spawn(Registry.CLOCKWORK, cx + 50.0)
		spawn(Registry.IRONARMS, cx + 180.0)
	var sx := level_w - 1500.0   # על במת קמיניטו
	var z2 := spawn(Registry.TANGO, sx + STAGE_W * 0.4, floor_y - STAGE_TIER)
	if z2 != null and z2.type_mod != null and z2.type_mod.partner != null:
		z2.type_mod.partner.position.y = floor_y - STAGE_TIER
