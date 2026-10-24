extends "res://levels/stage_base.gd"
# ============================================================
#  STAGE 56 - "ICE FJORD" (אזור שביעי - פטגוניה, שלב 2) - "THEY LEARNED THE COLD"
#  (הסיפור: THE ARCHITECT מת בשלב 54 וזה לא שינה כלום - אין להם יותר מנהיג, הכוורת חושבת כאחד. בפיורד הקפוא
#   הם למדו שתי תורות: ראשים נשברים - אז הם משריינים אותם בקרח (THAWED). והקור שומר עליהם מריקבון.
#   הנבגים של כל מת עוברים לחבר הכי קרוב (effects/spore_lesson.gd, משותף משלב 55) - והוא "לומד".)
#  (effects/s56_decor.gd): דמדומי קוטב בהירים עם זוהר צפוני, צריחי גרניט, חזית קרחון שמתנתקת למים, גושי קרח.
#  מבנה: רציף + מפעל השימורים על כלונסאות (CANNERY) -> קרח ים עם פסי מים, סירות קפואות, מדפי קרח -> זירת הקרחון.
#  קומה שנייה: מסלול המפעל + הגג שלו (קומה שלישית), סיפוני הסירות + גגות תאי ההגה, מדפי הקרח - סולמות ואספקה למעלה.
#  מים: פסי מים פתוחים (LEADS) - הולכים לאט, ואחרי FREEZE_T במים הקפואים - נזק ("FREEZING WATER"). אין בורות מוות.
#  מלכודות: ThinIce (THIN) - נסדק ונשבר מתחתיך (וגם נהיה חור ש-SEALER יוצא ממנו), Calving (CALVING) - מדף קרח נופל,
#           HookLine (בחזית המפעל) - וו דגים רץ בגובה החזה, FuelDrum (DRUMS) - חבית קפואה שמתפוצצת ומפשירה THAWED.
#  זומבים: THAWED (קפוא בשריון קרח שנשבר בשכבות), BUOY (עף על מצופים ובלונים), SEALER (שוחה מתחת לקרח ופורץ מחורים).
#  בוס: THE GLACIER (enemies/types/thawed.gd, מצב בוס) בזירה בסוף - עם מדף מסתור (ARENA_LEDGE) ושתי חביות.
#  on_story_beat("calve"): הקרחון מתנתק עכשיו (ברקע + המדף הקרוב לשחקן). אין סצנת סיפור בשלב הזה.
#  לשנות: DOCK_END, CANNERY, BOATS, LEDGES, LEADS, HOLES, THIN, CALVING, DRUMS, THAWED_AT, BUOYS, SEALERS,
#         FREEZE_T, zombie_weights().
# ============================================================

const Decor := preload("res://effects/s56_decor.gd")
const PickupScript := preload("res://pickup.gd")
const Sfx := preload("res://sfx.gd")

const SOUNDS := {
	"ti_crack": [["C", 0, 0, 0.0, 0.25, 0.0, 9.0, 0.9, 1.0, 0], ["S", 2400, 1800, 0.0, 0.08, 0.0, 40.0, 0.15, 1.0, 0], ["N", 0, 0, 0.0, 0.05, 0.0, 80.0, 0.5, 0.8, 0, 0.5]],
	"ti_break": {"rev": 0.2, "layers": [["N", 0, 0, 0.0, 0.4, 0.0, 9.0, 0.9, 0.6, 0], ["C", 0, 0, 0.0, 0.4, 0.0, 6.0, 0.9, 1.0, 0], ["S", 3100, 2900, 0.0, 0.3, 0.0, 12.0, 0.15, 1.0, 0], ["S", 90, 50, 0.0, 0.3, 0.0, 10.0, 0.6, 1.0, 0]]},
	"cv_groan": [["S", 70, 48, 0.0, 1.1, 0.1, 1.6, 0.6, 1.0, 0.3], ["N", 0, 0, 0.0, 1.0, 0.1, 2.0, 0.3, 0.15, 0], ["C", 0, 0, 0.2, 0.8, 0.0, 2.0, 0.5, 1.0, 0]],
	"cv_crash": {"rev": 0.35, "drive": 2.2, "layers": [["N", 0, 0, 0.0, 1.0, 0.0, 3.5, 1.0, 0.3, 0], ["C", 0, 0, 0.0, 0.8, 0.0, 3.0, 0.9, 1.0, 0], ["S", 55, 30, 0.0, 0.8, 0.0, 4.0, 0.9, 1.0, 0], ["S", 2800, 2500, 0.0, 0.5, 0.0, 8.0, 0.12, 1.0, 0]]},
	"hk_rattle": [["C", 0, 0, 0.0, 0.6, 0.0, 3.0, 0.9, 1.0, 0], ["Q", 900, 880, 0.0, 0.5, 0.0, 8.0, 0.05, 0.6, 0]],
	"hk_run": [["N", 0, 0, 0.0, 1.2, 0.05, 1.5, 0.4, 0.15, 0], ["W", 80, 95, 0.0, 1.2, 0.05, 1.5, 0.2, 0.2, 0], ["C", 0, 0, 0.0, 1.2, 0.0, 1.5, 0.5, 1.0, 0]],
	"fd_hiss": [["N", 0, 0, 0.0, 0.7, 0.02, 2.5, 0.5, 1.0, 0, 0.5]],
	"fj_rumble": {"rev": 0.4, "drive": 2.0, "layers": [["N", 0, 0, 0.0, 3.0, 0.3, 1.0, 0.9, 0.04, 0], ["S", 38, 26, 0.0, 3.0, 0.3, 1.0, 0.7, 1.0, 0.1], ["C", 0, 0, 0.3, 2.0, 0.2, 1.5, 0.5, 0.5, 0]]},
}

const DOCK_END := 2150.0                 # עד כאן רציף עץ, משם קרח ים
const CANNERY := Vector2(1250.0, 600.0)  # [x, רוחב]
const CANNERY_TIER := 150.0
const CANNERY_ROOF := 290.0
const BOATS := [[2720.0, "SAN JUAN", Color("b0402e")], [5250.0, "MARIA AUXILIADORA", Color("2e6a8a")], [7620.0, "DON PEDRO", Color("2e7a4a")]]
const BOAT_W := 340.0
const BOAT_DECK := 110.0
const BOAT_CAB := 210.0
const LEDGES := [[3820.0, 300.0], [6380.0, 320.0], [8560.0, 280.0]]
const LEDGE_TIER := 170.0
const LEADS := [[2330.0, 130.0], [4540.0, 150.0], [5880.0, 120.0], [7180.0, 140.0], [8170.0, 120.0]]   # [x, רוחב] מים פתוחים
const HOLES := [2580.0, 3360.0, 4280.0, 5640.0, 6820.0, 7440.0, 8000.0, 8930.0]   # חורי דיג
const THIN := [3110.0, 4140.0, 6030.0, 7320.0, 8360.0]
const CALVING := [3640.0, 4980.0, 6200.0, 8380.0]
const DRUMS := [2930.0, 4380.0, 5530.0, 6640.0, 7900.0]
const THAWED_AT := 170.0                 # THAWED עומד אחרי כל חבית (החבית = הנגד שלו)
const BUOYS := [1650.0, 2420.0, 3950.0, 4620.0, 5350.0, 6500.0, 7250.0, 8650.0]
const SEALERS := [3360.0, 4280.0, 5640.0, 6820.0, 7440.0, 8930.0]
const ARENA_LEDGE := Vector2(40.0, 230.0)
const ARENA_TIER := 170.0
const FREEZE_T := 2.6                    # שניות במים הקפואים עד נזק
const HARDER := [1.0, 1.15, 1.3]

var _decks := []        # [x0, x1, y]
var _leads := []        # Decor.WaterLead
var _thin := []         # Decor.ThinIce
var _cold := 0.0
var _arena_x := 0.0
var freezes := 0        # לבדיקות


func zombie_weights() -> Dictionary:
	return {Registry.THAWED: 0.045, Registry.BUOY: 0.03, Registry.SEALER: 0.03, 0: 0.55, 1: 0.33}


func zombie_density() -> float:
	return 1.0 * float(HARDER[clampi(Settings.difficulty, 0, 2)])


func generators() -> Array:
	return [["ice_block", 1.0], ["fish_box", 0.8], ["net_pile", 0.6]]   # (לא "crates" - השם הזה תפוס ב-main.gd)


func custom_gen(gname: String, x: float) -> float:
	if not gname in ["ice_block", "fish_box", "net_pile"]:
		return 0.0
	var sz := Vector2(70.0, 54.0)
	match gname:
		"ice_block":
			sz = Vector2(rng.randf_range(62.0, 78.0), rng.randf_range(52.0, 64.0))
		"fish_box":
			sz = Vector2(rng.randf_range(78.0, 90.0), rng.randf_range(56.0, 64.0))
		_:
			sz = Vector2(rng.randf_range(96.0, 116.0), rng.randf_range(40.0, 48.0))
	if not free_x(x, 30.0) or not free_x(x + sz.x, 30.0):   # לא על מים / חור / מלכודת / סולם / הזירה
		return 80.0
	var o := Decor.Obstacle.new()
	o.kind = gname
	o.size = sz
	o.seed_v = rng.randi()
	o.position = Vector2(x, floor_y)
	main.add_child(o)
	reserve(Rect2(x, floor_y - sz.y, sz.x, sz.y))
	return sz.x


func boss_kind() -> int:
	return Registry.THAWED


func music() -> String:
	return "res://music/level1_total_war.mp3"


func world_tint() -> Color:
	return Color(0.97, 0.99, 1.0)


func fog() -> bool:
	return false


func pits() -> int:
	return 0


func build_background(layer: CanvasLayer) -> Node:
	Decor.calve_ms = -1
	var bg = Backdrop.new()
	bg.level_w = level_w
	bg.sky = func(ci: CanvasItem, v: Vector2, t: float):
		Decor.fjord_sky(ci, v, t)
	bg.add_layer(0.06, func(ci: CanvasItem, sc: float, v: Vector2, t: float):
		Decor.far_peaks(ci, sc, v, 548.0, t))
	bg.add_layer(0.28, func(ci: CanvasItem, sc: float, v: Vector2, t: float):
		Decor.mid_fjord(ci, sc, v, 612.0, t))
	bg.add_layer(0.6, func(ci: CanvasItem, sc: float, v: Vector2, t: float):
		Decor.near_floes(ci, sc, v, 636.0, t))
	bg.overlay = func(ci: CanvasItem, v: Vector2, t: float):
		Decor.fjord_overlay(ci, v, t)
	layer.add_child(bg)
	return bg


func build_world() -> void:
	_arena_x = level_w - 1100.0
	# הקרקע: רציף עץ ואז קרח ים
	var x := 0.0
	while x < level_w:
		var w := minf(1024.0, level_w - x)
		var dock := x < DOCK_END
		if dock:
			w = minf(w, DOCK_END - x)
		var g := Decor.IceGround.new()
		g.w = w
		g.dock = dock
		g.depth = main.floor_thickness
		g.seed_v = rng.randi()
		add_world(g, Vector2(x, floor_y))
		x += w
	# מפעל השימורים: מסלול (קומה) + גג (קומה שלישית) + מסילת הוו בחזית
	var cn := Decor.Cannery.new()
	cn.w = CANNERY.y
	cn.tier = CANNERY_TIER
	cn.roof_tier = CANNERY_ROOF
	add_world(cn, Vector2(CANNERY.x, floor_y))
	var cf = add_floor(CANNERY.x - 6.0, floor_y - CANNERY_TIER, CANNERY.y + 12.0, "steel", false, false)
	cf.visible = false
	var rf = add_floor(CANNERY.x + cn.roof_x.x - 10.0, floor_y - CANNERY_ROOF, cn.roof_x.y - cn.roof_x.x + 20.0, "steel", false, false)
	rf.visible = false
	add_ladder(CANNERY.x + 14.0, floor_y - CANNERY_TIER)
	add_ladder(CANNERY.x + CANNERY.y - 30.0, floor_y - CANNERY_TIER)
	add_ladder(CANNERY.x + cn.roof_x.y - 24.0, floor_y - CANNERY_ROOF, floor_y - CANNERY_TIER)
	reserve(Rect2(CANNERY.x - 20.0, floor_y - 40.0, CANNERY.y + 40.0, 40.0))
	_decks.append([CANNERY.x, CANNERY.x + CANNERY.y, floor_y - CANNERY_TIER])
	_pickup(PickupScript.AMMO, Vector2(CANNERY.x + 160.0, floor_y - CANNERY_TIER - 30.0))
	_pickup(PickupScript.HEALTH, Vector2(CANNERY.x + cn.roof_x.x + 60.0, floor_y - CANNERY_ROOF - 30.0))
	var hk := Decor.HookLine.new()
	hk.w = CANNERY.y - 80.0
	add_world(hk, Vector2(CANNERY.x + 40.0, floor_y))
	# סירות קפואות: סיפון (קומה) + גג תא ההגה (קומה שנייה)
	for i in BOATS.size():
		var bx: float = BOATS[i][0]
		var bt := Decor.FrozenBoat.new()
		bt.w = BOAT_W
		bt.deck = BOAT_DECK
		bt.cab_tier = BOAT_CAB
		bt.col = BOATS[i][2]
		bt.name_s = BOATS[i][1]
		bt.seed_v = i * 13 + 5
		add_world(bt, Vector2(bx, floor_y))
		var df = add_floor(bx - 10.0, floor_y - BOAT_DECK, BOAT_W + 30.0, "steel", false, false)
		df.visible = false
		var cf2 = add_floor(bx + bt.cab_x.x - 4.0, floor_y - BOAT_CAB, bt.cab_x.y - bt.cab_x.x + 8.0, "steel", false, false)
		cf2.visible = false
		add_ladder(bx + 12.0, floor_y - BOAT_DECK)
		add_ladder(bx + bt.cab_x.x - 18.0, floor_y - BOAT_CAB, floor_y - BOAT_DECK)
		reserve(Rect2(bx - 40.0, floor_y - 40.0, BOAT_W + 80.0, 40.0))
		_decks.append([bx, bx + BOAT_W, floor_y - BOAT_DECK])
		_pickup(PickupScript.AMMO, Vector2(bx + 90.0, floor_y - BOAT_DECK - 30.0))
		_pickup(PickupScript.GRENADE if i == 1 else PickupScript.HEALTH, Vector2(bx + (bt.cab_x.x + bt.cab_x.y) * 0.5, floor_y - BOAT_CAB - 30.0))
	# מדפי קרח בקיר הקרחון
	for i in LEDGES.size():
		var lx: float = LEDGES[i][0]
		var lw: float = LEDGES[i][1]
		var ld := Decor.IceLedge.new()
		ld.w = lw
		ld.tier = LEDGE_TIER
		add_world(ld, Vector2(lx, floor_y))
		var lf = add_floor(lx - 8.0, floor_y - LEDGE_TIER, lw + 16.0, "steel", false, false)
		lf.visible = false
		add_ladder(lx + 20.0, floor_y - LEDGE_TIER)
		add_ladder(lx + lw - 40.0, floor_y - LEDGE_TIER)
		reserve(Rect2(lx - 10.0, floor_y - 40.0, 60.0, 40.0))
		reserve(Rect2(lx + lw - 60.0, floor_y - 40.0, 60.0, 40.0))
		_decks.append([lx, lx + lw, floor_y - LEDGE_TIER])
		_pickup(PickupScript.HEALTH if i % 2 == 1 else PickupScript.AMMO, Vector2(lx + lw * 0.5, floor_y - LEDGE_TIER - 30.0))
	# מים פתוחים
	for l in LEADS:
		var wl := Decor.WaterLead.new()
		wl.w = l[1]
		add_world(wl, Vector2(float(l[0]), floor_y))
		_leads.append(wl)
		reserve(Rect2(float(l[0]) - 20.0, floor_y - 40.0, float(l[1]) + 40.0, 40.0))
		main._spawn_avoid.append([float(l[0]), float(l[0]) + float(l[1])])
	# חורי דיג (SEALER יוצא מהם)
	for hx in HOLES:
		var hh := Decor.FishingHole.new()
		add_world(hh, Vector2(float(hx), floor_y))
		reserve(Rect2(float(hx) - 50.0, floor_y - 30.0, 100.0, 30.0))
	# מלכודות
	for tx in THIN:
		var ti := Decor.ThinIce.new()
		add_world(ti, Vector2(float(tx), floor_y))
		_thin.append(ti)
		reserve(Rect2(float(tx) - 95.0, floor_y - 40.0, 190.0, 40.0))
	for cx in CALVING:
		add_world(Decor.Calving.new(), Vector2(float(cx), floor_y))
		reserve(Rect2(float(cx) - 100.0, floor_y - 40.0, 200.0, 40.0))
	for dx in DRUMS:
		_drum(float(dx))
	# זירת הקרחון (THE GLACIER) + מדף מסתור + שתי חביות + מדפים שמתנתקים
	var ar := Decor.GlacierArena.new()
	ar.w = 1100.0
	ar.ledge = ARENA_LEDGE
	ar.tier = ARENA_TIER
	add_world(ar, Vector2(_arena_x, floor_y))
	var af = add_floor(_arena_x + ARENA_LEDGE.x - 6.0, floor_y - ARENA_TIER, ARENA_LEDGE.y - ARENA_LEDGE.x + 12.0, "steel", false, false)
	af.visible = false
	add_ladder(_arena_x + ARENA_LEDGE.x + 30.0, floor_y - ARENA_TIER)
	_pickup(PickupScript.AMMO, Vector2(_arena_x + (ARENA_LEDGE.x + ARENA_LEDGE.y) * 0.5, floor_y - ARENA_TIER - 30.0))
	_pickup(PickupScript.HEALTH, Vector2(_arena_x - 120.0, floor_y - 30.0))
	_pickup(PickupScript.AMMO, Vector2(_arena_x - 60.0, floor_y - 30.0))
	add_world(Decor.Calving.new(), Vector2(_arena_x + 430.0, floor_y))
	add_world(Decor.Calving.new(), Vector2(_arena_x + 900.0, floor_y))
	_drum(_arena_x + 330.0, false)
	_drum(_arena_x + 760.0, false)
	reserve(Rect2(_arena_x - 160.0, floor_y - 40.0, level_w - _arena_x + 160.0, 40.0))


func _drum(dx: float, nudge := true) -> void:
	var x := dx
	while nudge and not free_x(x, 30.0) and x < level_w - 1500.0:
		x += 40.0
	var d := Decor.FuelDrum.new()
	d.position = Vector2(x, floor_y)
	main.add_child(d)
	reserve(Rect2(x - 20.0, floor_y - 46.0, 40.0, 46.0))


func _pickup(kind: int, pos: Vector2) -> void:
	var p = PickupScript.new()
	p.kind = kind
	p.life = 100000.0
	main.add_child(p)
	p.setup(pos, Vector2.ZERO)


func build_effects() -> void:
	var snow := Ambient.screen_particles("ash", vp)   # שלג
	snow.color = Color(0.96, 0.98, 1.0, 0.7)
	snow.amount = int(50.0 * clampf(Quality.ambient(), 0.3, 1.0))
	snow.direction = Vector2(-0.45, 1.0)
	snow.initial_velocity_min = 40.0
	snow.initial_velocity_max = 80.0
	screen_layer.add_child(snow)
	var fx := Decor.FjordFX.new()
	fx.vp = vp
	screen_layer.add_child(fx)


# על כל קומה רגיל. THAWED אחרי כל חבית (הנגד שלו). BUOY מעל המים והמזחים. SEALER בחורי הדיג. שניים שומרים בזירה.
func extra_spawns() -> void:
	for d in _decks:
		spawn(0, lerpf(float(d[0]), float(d[1]), 0.5), float(d[2]))
	for dx in DRUMS:
		var tx := float(dx) + THAWED_AT
		while not free_x(tx, 10.0) and tx < level_w - 1500.0:
			tx += 40.0
		spawn(Registry.THAWED, tx)
		spawn(0, tx + 70.0)
	for bx in BUOYS:
		spawn(Registry.BUOY, float(bx))
	for sx in SEALERS:
		spawn(Registry.SEALER, float(sx))
	for i in BOATS.size():   # קבוצה ליד כל סירה
		var gx: float = float(BOATS[i][0]) + BOAT_W + 120.0
		if free_x(gx, 10.0):
			spawn(0, gx)
			spawn(1, gx + 60.0)
	spawn(0, _arena_x + 240.0)
	spawn(1, _arena_x + 340.0)


# ============ מים קפואים ============
func _physics_process(delta: float) -> void:
	if main == null or Engine.get_physics_frames() % 4 != 0:
		return
	var pl := get_tree().get_first_node_in_group("player") as Node2D
	if pl == null or pl.dead:
		return
	var wet := in_water_at(pl.global_position)
	pl.in_water = wet
	if wet and pl.is_on_floor():
		_cold += delta * 4.0
		if _cold >= FREEZE_T:
			_cold = 0.0
			freezes += 1
			pl.hurt(1, Vector2(0, -0.3))
			pl._say("FREEZING WATER!", Color("9adcff"))
	else:
		_cold = maxf(0.0, _cold - delta * 4.0 * 0.5)


# SEALER (enemies/types/sealer.gd): אפשר לשבור כאן קרח ים? (לא על הרציף, לא בתוך גוף סירה, לא בפס מים)
func ice_at(x: float) -> bool:
	if x < DOCK_END + 40.0 or x > level_w - 60.0:
		return false
	for b in BOATS:
		if x > float(b[0]) - 20.0 and x < float(b[0]) + BOAT_W + 20.0:
			return false
	for l in _leads:
		if x > l.global_position.x - 30.0 and x < l.global_position.x + l.w + 30.0:
			return false
	return true


# האם הנקודה (כפות רגליים) במים: פסי מים פתוחים או קרח דק שנשבר
func in_water_at(p: Vector2) -> bool:
	if absf(p.y - floor_y) > 10.0:
		return false
	for l in _leads:
		if p.x > l.global_position.x + 4.0 and p.x < l.global_position.x + l.w - 4.0:
			return true
	for t in _thin:
		if t.state == 2 and t.on_ice(p):
			return true
	return false


# ============ אירועי סיפור ============
# "calve": הקרחון מתנתק עכשיו - ברקע (פיצוץ מים), והמדף התלוי הכי קרוב לשחקן נופל (עם אזהרה)
func on_story_beat(id: String) -> void:
	match id:
		"calve":
			calve_near(-1.0)


func calve_near(x: float, warn := -1.0) -> Node:
	Decor.calve_ms = Time.get_ticks_msec()
	Sfx.play("fj_rumble", null, 3.0)
	var cam := get_viewport().get_camera_2d()
	if cam != null and cam.has_method("shake"):
		cam.shake(8.0, 1.0)
	var px := x
	if px < 0.0:
		var pl := get_tree().get_first_node_in_group("player") as Node2D
		px = pl.global_position.x if pl != null else 0.0
	var best: Node = null
	var bd := 900.0
	for c in get_tree().get_nodes_in_group("calving"):
		var d := absf(c.global_position.x - px)
		if c.state == 0 and d < bd:
			bd = d
			best = c
	if best != null:
		best.trigger(warn if warn > 0.0 else best.WARN_T)
	return best
