extends "res://levels/stage_base.gd"
# ============================================================
#  STAGE 22 - "THE DAM" (אזור שלישי, שלב 4) - "THEY LEARNED TO SET TRAPS"
#  בוקר אפור וגשום ליד סכר בטון ענק (effects/s22_decor.gd): מפלים מהשערים, עמודי חשמל, יער, מגרש בולי עץ.
#  קומה שנייה: מסלולי פלדה (CATWALKS) - משם ה-HARPOONER יורה.
#  מלכודת: LogTrap - חוט מתיחה על הקרקע מתחת למסגרת עם בול עץ. נוגעים -> הבול נופל ומתגלגל אליך.
#  זומבים: GOLIATH (ענק שמתפרק: ידיים -> רגליים -> ראש, ומשנה טקטיקה), HARPOONER (רובה צלצל שמושך אותך),
#          CRUMBLER, LEAPER, רגילים ורצים.
#  בוס: THE BUTCHER - GOLIATH ענק (enemies/types/goliath.gd, מצב בוס).
#  לשנות: CATWALKS, TIER, LOG_TRAPS, zombie_weights().
# ============================================================

const Decor := preload("res://effects/s22_decor.gd")
const PickupScript := preload("res://pickup.gd")

const CATWALKS := [[0.14, 380.0], [0.36, 440.0], [0.58, 400.0], [0.8, 420.0]]   # [מיקום יחסי, רוחב]
const TIER := 140.0
const LOG_TRAPS := [0.08, 0.23, 0.3, 0.46, 0.52, 0.68, 0.74, 0.9]   # איפה מלכודות בולי עץ (יחסי)
const HARDER := [1.0, 1.15, 1.3]

var _spans := []


func zombie_weights() -> Dictionary:
	return {Registry.GOLIATH: 0.07, Registry.HARPOONER: 0.2, Registry.CRUMBLER: 0.08, Registry.LEAPER: 0.1, 0: 0.28, 1: 0.22}


func zombie_density() -> float:
	return 1.0 * float(HARDER[clampi(Settings.difficulty, 0, 2)])


func generators() -> Array:
	return [["jersey", 1.4], ["drums", 1.0], ["timber", 0.8]]


func custom_gen(gname: String, x: float) -> float:
	if not gname in ["jersey", "drums", "timber"]:
		return 0.0
	if _near_trap(x - 40.0, x + 160.0):
		return 140.0
	var o := Decor.Obstacle.new()
	o.kind = gname
	o.seed_v = rng.randi()
	match gname:
		"jersey":
			o.size = Vector2(rng.randf_range(70.0, 100.0), rng.randf_range(38.0, 46.0))
		"drums":
			o.size = Vector2(rng.randf_range(44.0, 54.0), rng.randf_range(34.0, 40.0))
		_:   # ערימת בולים - גבוהה, מחסה
			o.size = Vector2(rng.randf_range(80.0, 100.0), rng.randf_range(70.0, 86.0))
	o.position = Vector2(x, floor_y)
	main.add_child(o)
	reserve(Rect2(x, floor_y - o.size.y, o.size.x, o.size.y))
	return o.size.x


func _near_trap(x0: float, x1: float) -> bool:
	for f in LOG_TRAPS:
		var tx := level_w * float(f)
		if x1 > tx - 110.0 and x0 < tx + 400.0:   # החוט + המגדל שקדימה (LogTrap.AHEAD)
			return true
	return false


func boss_kind() -> int:
	return Registry.GOLIATH


func music() -> String:
	return "res://music/level2_suspense.mp3"


func world_tint() -> Color:
	return Color(0.93, 0.96, 1.0)


func fog() -> bool:
	return false


func pits() -> int:
	return 0


func build_background(layer: CanvasLayer) -> Node:
	var bg = Backdrop.new()
	bg.level_w = level_w
	bg.sky = func(ci: CanvasItem, v: Vector2, t: float):
		Decor.overcast_sky(ci, v, t)
	bg.add_layer(0.08, func(ci: CanvasItem, sc: float, v: Vector2, t: float):
		Decor.far_dam(ci, sc, v, 520.0, t))
	bg.add_layer(0.3, func(ci: CanvasItem, sc: float, v: Vector2, t: float):
		Decor.mid_pylons(ci, sc, v, 600.0, t))
	bg.add_layer(0.62, func(ci: CanvasItem, sc: float, v: Vector2, t: float):
		Decor.near_bank(ci, sc, v, 628.0, t))
	layer.add_child(bg)
	return bg


func build_world() -> void:
	var x := 0.0
	while x < level_w:
		var g := Decor.DamGround.new()
		g.w = minf(1024.0, level_w - x)
		g.depth = main.floor_thickness
		g.seed_v = rng.randi()
		add_world(g, Vector2(x, floor_y))
		x += 1024.0
	for cw in CATWALKS:
		var ox := level_w * float(cw[0])
		var w: float = cw[1]
		add_floor(ox, floor_y - TIER, w, "steel", true, true)
		add_ladder(ox + 12.0, floor_y - TIER)
		reserve(Rect2(ox - 20.0, floor_y - TIER, w + 40.0, TIER))
		_spans.append([ox, ox + w])
		_pickup(PickupScript.AMMO if cw[0] < 0.6 else PickupScript.HEALTH, Vector2(ox + w * 0.6, floor_y - TIER - 30.0))
	for f in LOG_TRAPS:   # מלכודות בולי עץ
		var tx := level_w * float(f)
		var lt := Decor.LogTrap.new()
		add_world(lt, Vector2(tx, floor_y))
		reserve(Rect2(tx - 60.0, floor_y - 40.0, 420.0, 40.0))   # החוט + המגדל שקדימה


func _pickup(kind: int, pos: Vector2) -> void:
	var p = PickupScript.new()
	p.kind = kind
	p.life = 100000.0
	main.add_child(p)
	p.setup(pos, Vector2.ZERO)


func build_effects() -> void:
	var fx := Decor.DamFX.new()
	fx.vp = vp
	screen_layer.add_child(fx)


# HARPOONER על המסלולים, GOLIATH באמצע השלב
func extra_spawns() -> void:
	for i in _spans.size():
		var s: Array = _spans[i]
		spawn(Registry.HARPOONER, lerpf(float(s[0]), float(s[1]), 0.6), floor_y - TIER)
	spawn(Registry.GOLIATH, level_w * 0.42)
	spawn(Registry.GOLIATH, level_w * 0.7)
