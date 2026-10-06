extends "res://levels/stage_base.gd"
# ============================================================
#  STAGE 16 - "THE FLOOD" (אזור צפון-מזרח, שלב 7) - "THEY COME IN WAVES"
#  אחר הצהריים, גשם קל. אתר בנייה ענק בשולי העיר: שלדי בטון, עגורנים, גדרות עם ברזנט.
#  סוג זומבי אחד בלבד: SWARMER (כפוף, מהיר, קליע אחד) - אבל המון. הם מגיעים בגלים (HordeDirector)
#    מקדימה ולפעמים מאחורה, מטפסים אחד על השני מעל מכשולים ואל הקומות.
#  פיגומים (SCAFFOLDS) עם שתי קומות: TIER1 / TIER2 פיקסלים מעל הכביש - גם השחקן וגם הזומבים קופצים אליהן.
#  הרבה תחמושת: קופסה כל AMMO_GAP פיקסלים + הצנחת תחמושת ליד השחקן כל גל שני.
#  בוס: BROODMOTHER - "THE BROODMOTHER" (יולדת SWARMERS ויורה אותם עליך).
#  לשנות: SCAFFOLDS, TIER1/TIER2, AMMO_GAP, HordeDirector (WAVE_GAP, WAVE_SIZE, MAX_ALIVE).
# ============================================================

const WeaponDB := preload("res://weapons/weapon_db.gd")
const Decor := preload("res://effects/s16_decor.gd")
const PickupScript := preload("res://pickup.gd")

const SCAFFOLDS := [[0.09, 760.0], [0.25, 900.0], [0.43, 820.0], [0.6, 980.0], [0.77, 800.0]]   # [מיקום יחסי, רוחב]
const TIER1 := 120.0          # קומה ראשונה מעל הכביש (קפיצה רגילה)
const TIER2 := 240.0          # קומה שנייה
const T2_SPAN := Vector2(0.15, 0.85)
const AMMO_GAP := Vector2(380.0, 520.0)
const MEDKIT_GAP := 1400.0     # ערכת עזרה ראשונה (+1 לב) בערך כל כמה פיקסלים

var _spans := []
var director: Node = null


func zombie_weights() -> Dictionary:
	return {Registry.SWARMER: 1.0}


func zombie_density() -> float:
	return 0.75


func generators() -> Array:
	return [["pipes", 1.4], ["jersey", 1.6], ["pallet", 1.0], ["container", 0.5]]


func custom_gen(gname: String, x: float) -> float:
	if not gname in ["pipes", "jersey", "pallet"]:
		return 0.0
	if _in_scaffold(x - 30.0) or _in_scaffold(x + 140.0):
		return 140.0
	var o := Decor.Obstacle.new()
	o.kind = gname
	o.seed_v = rng.randi()
	match gname:
		"pipes":
			o.size = Vector2(44.0 * float(rng.randi_range(2, 3)), 44.0)
		"jersey":
			o.size = Vector2(56.0 * float(rng.randi_range(1, 3)), 48.0)
		_:
			o.size = Vector2(rng.randf_range(70.0, 100.0), rng.randf_range(38.0, 50.0))
	o.position = Vector2(x, floor_y)
	main.add_child(o)
	reserve(Rect2(x, floor_y - o.size.y, o.size.x, o.size.y))
	return o.size.x


func weapon_offers() -> Array:
	return [WeaponDB.SMG, WeaponDB.ASSAULT_SHOTGUN, WeaponDB.ASSAULT_RIFLE]


func boss_kind() -> int:
	return Registry.BROODMOTHER


func music() -> String:
	return "res://music/level1_total_war.mp3"


func world_tint() -> Color:
	return Color(0.98, 0.93, 0.88)


func fog() -> bool:
	return false


func pits() -> int:
	return 0


func _in_scaffold(x: float) -> bool:
	for s in _spans:
		if x > float(s[0]) - 40.0 and x < float(s[1]) + 40.0:
			return true
	return false


# ---- רקע ----
func build_background(layer: CanvasLayer) -> Node:
	var bg = Backdrop.new()
	bg.level_w = level_w
	bg.sky = func(ci: CanvasItem, v: Vector2, t: float):
		Decor.afternoon_sky(ci, v, t)
	bg.add_layer(0.08, func(ci: CanvasItem, sc: float, v: Vector2, t: float):
		Decor.far_city(ci, sc, v, 470.0, t))
	bg.add_layer(0.25, func(ci: CanvasItem, sc: float, v: Vector2, t: float):
		Decor.skeletons(ci, sc, v, 560.0, t))
	bg.add_layer(0.55, func(ci: CanvasItem, sc: float, v: Vector2, t: float):
		Decor.fence_layer(ci, sc, v, 600.0, t))
	layer.add_child(bg)
	return bg


# ---- העולם: פיגומים עם שתי קומות + המון תחמושת ----
func build_world() -> void:
	for sf in SCAFFOLDS:
		var ox := level_w * float(sf[0])
		var w: float = sf[1]
		var sc := Decor.Scaffold.new()
		sc.w = w
		sc.tiers = [TIER1, TIER2]
		sc.t2_span = T2_SPAN
		sc.seed_v = rng.randi()
		add_world(sc, Vector2(ox, floor_y))
		add_floor(ox, floor_y - TIER1, w, "scaffold", false, false)
		add_floor(ox + w * T2_SPAN.x, floor_y - TIER2, w * (T2_SPAN.y - T2_SPAN.x), "scaffold", false, true)
		add_ladder(ox + 14.0, floor_y - TIER1)
		add_ladder(ox + w * T2_SPAN.x + 16.0, floor_y - TIER2, floor_y - TIER1)
		reserve(Rect2(ox - 30.0, floor_y - TIER2, w + 60.0, TIER2))
		_spans.append([ox, ox + w])
		# ארגז ציוד + ערכת עזרה ראשונה על הקומה העליונה
		_pickup(PickupScript.SUPPLY, Vector2(ox + w * 0.42, floor_y - TIER2 - 30.0))
		_pickup(PickupScript.HEALTH, Vector2(ox + w * 0.58, floor_y - TIER2 - 30.0))
	# קופסת תחמושת כל AMMO_GAP פיקסלים (על הכביש או על הפיגום)
	var x: float = main.safe_zone * 0.6
	var i := 0
	while x < level_w - 700.0:
		var y := floor_y - 30.0
		if _in_scaffold(x) and i % 2 == 1:
			y = floor_y - TIER1 - 30.0
		_pickup(PickupScript.GRENADE if i % 6 == 5 else PickupScript.AMMO, Vector2(x, y))
		x += rng.randf_range(AMMO_GAP.x, AMMO_GAP.y)
		i += 1
	_medkits()


func _medkits() -> void:   # על הכביש בין הפיגומים + 2 לפני הבוס
	var x := MEDKIT_GAP * 0.8
	while x < level_w - 1300.0:
		if not _in_scaffold(x) and free_x(x, 20.0):
			_pickup(PickupScript.HEALTH, Vector2(x, floor_y - 30.0))
		x += MEDKIT_GAP * rng.randf_range(0.85, 1.15)
	_pickup(PickupScript.HEALTH, Vector2(level_w - 1150.0, floor_y - 30.0))
	_pickup(PickupScript.HEALTH, Vector2(level_w - 1050.0, floor_y - 30.0))


func _pickup(kind: int, pos: Vector2) -> void:
	var p = PickupScript.new()
	p.kind = kind
	p.life = 100000.0
	main.add_child(p)
	p.setup(pos, Vector2.ZERO)


func build_effects() -> void:
	var rain := Decor.LightRain.new()
	rain.floor_y = floor_y
	screen_layer.add_child(rain)
	director = HordeDirector.new()
	director.stage = self
	main.add_child(director)


# זומבים שמחכים על הפיגומים
func extra_spawns() -> void:
	for s in _spans:
		var x0: float = s[0]
		var x1: float = s[1]
		for k in 2:
			spawn(Registry.SWARMER, lerpf(x0, x1, 0.3 + 0.4 * float(k)), floor_y - TIER1)
		spawn(Registry.SWARMER, lerpf(x0, x1, 0.5), floor_y - TIER2)


# ============================================================
#  HORDE DIRECTOR - שולח גלים של SWARMERS על השחקן
#    כל WAVE_GAP שניות: גל של WAVE_SIZE (גדל ככל שמתקדמים בשלב), מחוץ למסך מקדימה (לפעמים מאחורה),
#    בזרם צפוף (אחד כל STREAM שניות). לא יותר מ-MAX_ALIVE בבת אחת.
#    כל גל שני: הצנחת תחמושת ליד השחקן.
# ============================================================
class HordeDirector extends Node:
	const WAVE_GAP := Vector2(10.0, 14.0)
	const WAVE_SIZE := Vector2i(5, 9)
	const MAX_ALIVE := 22
	const BEHIND := 0.12          # סיכוי לגל מאחור (אף פעם לא ב-30% הראשונים של השלב)
	const WARN_T := 1.4           # אזהרה "HORDE INCOMING" לפני שהגל מתחיל לרוץ
	const EASY_MULT := [0.65, 0.85, 1.0]   # גודל הגל לפי הקושי (EASY / NORMAL / HARD)
	const STREAM := 0.07
	const Registry := preload("res://enemies/zombie_registry.gd")
	const Sfx := preload("res://sfx.gd")
	const PickupScript := preload("res://pickup.gd")
	const SwarmerType := preload("res://enemies/types/swarmer.gd")

	var stage = null
	var waves := 0
	var spawned := 0
	var _t := 10.0
	var _queue := []          # [x] לזרם
	var _stream_t := 0.0
	var _side := 1.0
	var _freeze_t := 0.0
	const FREEZE_DIST := 1600.0   # זומבים רחוקים מזה מהשחקן מוקפאים לגמרי (חוסך ביצועים כשיש המון)

	func _physics_process(delta: float) -> void:
		var main: Node = get_parent()
		var pl := get_tree().get_first_node_in_group("player") as Node2D
		if pl == null or stage == null:
			return
		if main.get("level_done") == true:
			return
		_t -= delta
		var px := pl.global_position.x
		_freeze_t -= delta
		if _freeze_t <= 0.0:
			_freeze_t = 0.25
			for z in get_tree().get_nodes_in_group("zombies"):
				var awake: bool = absf(z.global_position.x - px) < FREEZE_DIST or z.is_boss()
				if z.is_physics_processing() != awake:
					z.set_physics_process(awake)
		var near_boss: bool = px > stage.level_w - 1500.0
		if _t <= 0.0:
			_t = randf_range(WAVE_GAP.x, WAVE_GAP.y) * (1.6 if near_boss else 1.0)
			_start_wave(pl)
		if not _queue.is_empty():
			_stream_t -= delta
			while _stream_t <= 0.0 and not _queue.is_empty():
				_stream_t += STREAM
				if SwarmerType.count_near(pl.global_position.x, 1500.0) >= MAX_ALIVE:
					_queue.clear()
					break
				var x: float = clampf(_queue.pop_front(), 40.0, stage.level_w - 40.0)
				var tries := 0
				while not stage.free_x(x, 24.0) and tries < 10:   # לא בתוך מכולה / מכשול
					x += 40.0 * _side
					tries += 1
				var z = main._spawn_zombie(x, stage.floor_y, Registry.SWARMER)
				if z != null:
					z._dir = -_side
					spawned += 1

	func _start_wave(pl: Node2D) -> void:
		waves += 1
		var prog := clampf(pl.global_position.x / stage.level_w, 0.0, 1.0)
		var n := int(lerpf(float(WAVE_SIZE.x), float(WAVE_SIZE.y), prog)) + randi_range(-1, 1)
		n = maxi(3, int(round(float(n) * float(EASY_MULT[clampi(Settings.difficulty, 0, 2)]))))
		var vs: Vector2 = get_viewport().get_visible_rect().size
		var half := vs.x * 0.5 / maxf(get_viewport().get_camera_2d().zoom.x if get_viewport().get_camera_2d() != null else 1.0, 0.1)
		_side = -1.0 if (randf() < BEHIND and prog > 0.3) else 1.0
		var x0 := pl.global_position.x + _side * (half + 120.0)
		if x0 > stage.level_w - 60.0 or x0 < 60.0:
			_side = -_side
			x0 = pl.global_position.x + _side * (half + 120.0)
		for i in n:
			_queue.append(x0 + _side * randf_range(0.0, 260.0))
		_stream_t = WARN_T   # קודם אזהרה, אז הם מגיעים
		if pl.has_method("_say"):
			pl._say("HORDE INCOMING  >>>" if _side > 0.0 else "<<<  BEHIND YOU!", Color(1.0, 0.45, 0.3))
		Sfx.play("sw_shriek", Vector2(x0, stage.floor_y - 40.0), 2.0, 0.25, 4, 0.8)
		Sfx.play("sw_shriek", Vector2(x0, stage.floor_y - 40.0), 0.0, 0.25, 4, 1.15)
		if waves % 2 == 0:   # הצנחת תחמושת (כל גל רביעי: עזרה ראשונה)
			var p = PickupScript.new()
			p.kind = PickupScript.HEALTH if waves % 4 == 0 else (PickupScript.SUPPLY if waves % 6 == 0 else PickupScript.AMMO)
			p.life = 30.0
			get_parent().add_child(p)
			p.setup(Vector2(pl.global_position.x + randf_range(-160.0, 220.0), pl.global_position.y - 420.0), Vector2(0.0, 40.0))
