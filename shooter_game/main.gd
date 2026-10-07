extends Node2D
const Sfx := preload("res://sfx.gd")   # אפקטים קוליים
# ============================================================
#  הסצנה הראשית: בונה רמה ארוכה ואקראית עם רקעים, לבנים, זומבים ושחקן.
#  מקשים:  A/D הליכה | SHIFT ריצה | W/רווח קפיצה | S/CTRL כריעה
#          עכבר = כיוון | לחצן שמאלי = ירי / זריקה | T = החלפה בין רובה לרימון
#          K = מוות (בדיקה) | R = התחלה מחדש (ורמה חדשה)
# ============================================================

const BrickScene := preload("res://brick.tscn")
const PlayerScript := preload("res://player.gd")
const BackgroundScript := preload("res://background.gd")
const LeavesScript := preload("res://leaves.gd")
const ZombieScene := preload("res://zombie.tscn")
const HudScript := preload("res://hud.gd")
const CameraScript := preload("res://shake_camera.gd")
const PropScript := preload("res://prop.gd")
const StreetPropScript := preload("res://street_prop.gd")
const RoadDecorScript := preload("res://road_decor.gd")
const ManholeScript := preload("res://manhole.gd")
const LampScript := preload("res://street_lamp.gd")
const SubwayScript := preload("res://subway.gd")
const FactoryScript := preload("res://factory.gd")
const RainScript := preload("res://rain.gd")
# לילה (שלב 4): [רגיל, רץ, ענק, יורק, צורח, בוס, נפוח, מוליך, זוחל, שוטר, חולדות, יד, רובוט, זורק, קטן, כלב, שיכור, מקלען, ג'טפאק, בוס-כלב]
const NIGHT_WEIGHTS := [0.18, 0.1, 0.05, 0.04, 0.04, 0.0, 0.05, 0.0, 0.0, 0.05, 0.04, 0.0, 0.0, 0.0, 0.0, 0.14, 0.12, 0.07, 0.08, 0.0]
# מפעל: [רגיל, רץ, ענק, יורק, צורח, בוס, נפוח, מוליך, זוחל, שוטר, חולדות, יד, רובוט, זורק, קטן]
const FACTORY_WEIGHTS := [0.2, 0.12, 0.05, 0.06, 0.05, 0.0, 0.06, 0.0, 0.0, 0.08, 0.0, 0.0, 0.14, 0.1, 0.12]
const FACTORY_GENS := [["container", 3.0], ["crates", 2.0], ["barrels", 2.0], ["rubble", 1.5], ["barrier", 1.0], ["block", 1.0], ["wall", 1.0]]
const WheelScript := preload("res://weapon_wheel.gd")
const CEIL_Y := 250.0   # רכבת תחתית: גובה התקרה
# רכבת תחתית: [רגיל, רץ, ענק, יורק, צורח, בוס, נפוח, מוליך, זוחל, שוטר, חולדות, יד]
const SUBWAY_WEIGHTS := [0.25, 0.14, 0.08, 0.08, 0.05, 0.0, 0.07, 0.0, 0.1, 0.1, 0.12, 0.07]
const SUBWAY_GENS := [["train", 3.0], ["crates", 1.5], ["barrels", 1.5], ["barrier", 1.0], ["rubble", 1.0], ["block", 1.0], ["sandbags", 1.0]]
const FogScript := preload("res://fog.gd")
const PauseScript := preload("res://pause_menu.gd")
const SurvivorScript := preload("res://survivor.gd")
const WeaponDB := preload("res://weapons/weapon_db.gd")
const Arsenal := preload("res://progression/arsenal.gd")
const CheckpointScript := preload("res://environment/checkpoint.gd")
const CHECKPOINT_AT := 0.5     # נקודת הביקורת: באמצע השלב
var _checkpoint: Node2D = null
const PickupScript := preload("res://pickup.gd")
const ExitScript := preload("res://exit.gd")
const ResultsScript := preload("res://results.gd")
const SquadScript := preload("res://ai/squad_director.gd")
const StageRegistry := preload("res://levels/stage_registry.gd")   # שלבים 5-9: levels/stage_N.gd
var _stage: Node = null

@export_group("Level")
## אורך הרמה במסכים (רוחב מסך = 1280). המינימום הוא 8 מסכים
@export var level_screens := 8
## 0 = רמה אחרת בכל הפעלה. מספר אחר = אותה רמה בדיוק כל פעם (טוב לבדיקות)
@export var level_seed := 0
## עובי הריצפה בפיקסלים
@export var floor_thickness := 90.0
## אזור ריק בתחילת הרמה (בלי לבנים וזומבים)
@export var safe_zone := 700.0
## אזור ריק בסוף הרמה
@export var end_margin := 750.0   # בסוף השלב יש מקום לבוס וליציאה
## מרחק מינימלי / מקסימלי בין מבנים
@export var gap_min := 260.0
@export var gap_max := 560.0

## זום של המצלמה (גדול יותר = הדמויות נראות גדולות יותר)
@export var camera_zoom := 1.25

@export_group("Obstacles")
## איזה חלק מגובה הקפיצה של הדמות מותר שיהיה גובה מכשול (0.7 = 70%).
## כך הדמות תמיד מסוגלת לעבור כל לבנה. אם תגדיל - הלבנות יהיו גבוהות יותר
@export_range(0.3, 0.95) var obstacle_safety := 0.7

## כמה בורות יש בכביש
@export var pits := 3

@export_group("Zombies")
## כמה זומבים בממוצע בכל מסך
@export var zombies_per_screen := 1.6
## איזה חלק מהזומבים שוכבים על הריצפה וקמים כשמתקרבים
@export_range(0.0, 1.0) var dormant_chance := 0.25
## הסיכוי שזומבי יופיע בקבוצה של 2-3
@export_range(0.0, 1.0) var zombie_cluster_chance := 0.25
## כמה נפוץ כל סוג זומבי: רגיל / רץ / ענק
## כמה נפוץ כל סוג: רגיל, רץ, ענק, יורק, צורח (בשלבים מתקדמים יש יותר ענקים)
var zombie_weights := [0.42, 0.2, 0.12, 0.12, 0.1, 0.0, 0.09]   # אינדקס 5 = בוס (לא נבחר), 6 = נפוח

const UNIT := 16.0   # גובה "שורת לבנים"
const BRICK_COLORS := [Color("9a4f3a"), Color("8a5a40"), Color("7a4a4a"), Color("a0603f")]
const CONCRETE_COLORS := [Color("7d7a74"), Color("6e6c68"), Color("85807a")]
const CAR_COLORS := [Color("7a3a32"), Color("3d5670"), Color("b8b2a2"), Color("4d5e48"), Color("6a5a3a")]
## בורות בכביש: [x, רוחב]
const PIT_DEPTH := 60.0

var level_w := 10240.0
var max_h := 48.0
var _rects: Array[Rect2] = []
var _pits := []
var _time := 0.0
var _player: Node
var _pause: Node
var _finished := false
var _gens: Array = GENERATORS


func _ready() -> void:
	get_tree().paused = false
	Sfx.warm_up()   # מייצר את כל הצלילים פעם אחת
	# רמת הקושי מהתפריט
	var diff: Dictionary = Settings.preset()
	zombies_per_screen = diff.zombies_per_screen
	dormant_chance = diff.dormant
	# כל שלב קשה יותר: יותר זומבים ויותר ענקים
	Game.reset_level()
	if Game.is_factory():   # שלב מפעל (THEY BUILD)
		zombie_weights = FACTORY_WEIGHTS.duplicate()
		_gens = FACTORY_GENS
	if Game.is_night():   # שלב 4: לילה וגשם
		zombie_weights = NIGHT_WEIGHTS.duplicate()
	if Game.is_subway():   # שלב רכבת תחתית
		zombie_weights = SUBWAY_WEIGHTS.duplicate()
		_gens = SUBWAY_GENS
		pits = 2
	# שלבים 5-9: השלב עצמו מחליט (levels/stage_N.gd). הם לא "יותר חזקים" - הם חכמים יותר (ai/)
	_stage = StageRegistry.make(Game.level)
	if _stage != null:
		_stage.main = self
		zombie_weights = _weights_array(_stage.zombie_weights())
		_gens = _stage.generators()
		pits = _stage.pits()
		zombies_per_screen *= _stage.zombie_density()
	_start_music()
	zombies_per_screen *= 1.0 + 0.15 * float(mini(Game.level, 5) - 1)
	if _stage == null:
		zombie_weights[2] += 0.04 * float(Game.level - 1)
	var vp := get_viewport_rect().size
	level_w = vp.x * float(maxi(level_screens, 8))
	if _stage != null:
		_stage.level_w = level_w
		_stage.vp = vp
		_stage.floor_y = vp.y - floor_thickness

	# רקע: עיר הרוסה (פרלקסה), ועיתונים ואפר באוויר
	var bg_layer := CanvasLayer.new()
	bg_layer.layer = -10
	add_child(bg_layer)
	var bg
	if _stage != null:
		bg = _stage.build_background(bg_layer)
	else:
		bg = SubwayScript.TunnelBg.new() if Game.is_subway() else (FactoryScript.FactoryBg.new() if Game.is_factory() else BackgroundScript.new())
		bg.level_w = level_w
		bg_layer.add_child(bg)
	if Game.world() == 0:   # עיתונים ואפר רק ברחוב ביום
		var leaf_layer := CanvasLayer.new()
		leaf_layer.layer = -5
		add_child(leaf_layer)
		leaf_layer.add_child(LeavesScript.new())

	var rng := RandomNumberGenerator.new()
	if level_seed != 0:
		rng.seed = level_seed
	elif Game.attempt_seed != 0:   # אותו ניסיון בשלב = אותו מבנה (חזרה מנקודת ביקורת)
		rng.seed = Game.attempt_seed
	else:
		rng.randomize()
	if _stage != null:
		_stage.rng = rng

	# כביש לכל אורך הרמה, עם בורות
	var floor_y := vp.y - floor_thickness
	_make_road(rng, floor_y)
	if _stage != null:   # שלבים 5-9: גוון, קומות, סולמות, סכנות ואפקטים
		var tint: Color = _stage.world_tint()
		if tint != Color.WHITE:
			var stm := CanvasModulate.new()
			stm.color = tint
			add_child(stm)
		var sl := CanvasLayer.new()
		sl.layer = 1
		add_child(sl)
		_stage.screen_layer = sl
		add_child(_stage)
		_stage.build_world()
		_stage.build_effects()
	if Game.is_night():   # לילה: חושך, גשם וברקים
		var cm := CanvasModulate.new()
		cm.color = Color(0.5, 0.56, 0.75)
		add_child(cm)
		bg.modulate = Color(0.42, 0.48, 0.66)
		var rl := CanvasLayer.new()
		rl.layer = 1
		add_child(rl)
		rl.add_child(RainScript.new())
	if Game.is_factory():
		var fac = FactoryScript.new()
		fac.floor_y = floor_y
		fac.level_w = level_w
		add_child(fac)
	if Game.is_subway():
		var sub = SubwayScript.new()
		sub.floor_y = floor_y
		sub.ceil_y = CEIL_Y
		sub.level_w = level_w
		sub.make_rails(rng, _pits, safe_zone)
		add_child(sub)

	# מסגרת כהה סביב כל מה שהשחקן מתנגש בו (effects/collision_outlines.gd)
	add_child(preload("res://effects/collision_outlines.gd").new())
	# השחקן מדבר לעצמו - 1 עד 4 משפטים בשלב, רק כשקורה משהו (ui/monologue.gd)
	add_child(preload("res://ui/monologue.gd").new())
	# מד רצף הריגות מהיר מעל השחקן (ui/kill_streak.gd)
	add_child(preload("res://ui/kill_streak.gd").new())
	# שלב חשוך: טיפ לפנס (4 שניות, אחרי כותרת השלב)
	if Game.is_night() or Game.is_subway() or (_stage != null and _stage.dark_level()):
		var tip = preload("res://ui/tip_banner.gd").new()
		tip.seconds = 4.0
		var fi: int = Game.ability_slots.find("flashlight")
		tip.sub = ("Press %d to pick it, then C to turn it on" % ((fi + 6) % 10)) if fi >= 0 else "Equip FLASHLIGHT in UPGRADES -> ABILITIES"
		add_child(tip)

	# "המפקד הנסתר": תורות התקפה, תקשורת, פקודות (ai/squad_director.gd)
	var squad = SquadScript.new()
	squad.setup(Game.level, float(diff.smart))
	add_child(squad)

	# שחקן (נוצר קודם כדי לחשב מה גובה המכשול המקסימלי שהוא מסוגל לעבור)
	var player = PlayerScript.new()
	var apex: float = (player.jump_velocity * player.jump_velocity) / (2.0 * player.gravity)
	max_h = maxf(floorf(apex * obstacle_safety / UNIT) * UNIT, 2.0 * UNIT)

	_place_street_props(rng, floor_y)
	_generate_level(rng, floor_y)
	_spawn_zombies(rng, floor_y)
	if _stage != null:
		_stage.extra_spawns()
	_spawn_survivors(rng, floor_y)
	_spawn_supplies(rng, floor_y)
	_checkpoint = CheckpointScript.new()   # נקודת ביקורת באמצע השלב (שמירה אוטומטית)
	_checkpoint.position = Vector2(_free_spot(level_w * CHECKPOINT_AT), floor_y)
	add_child(_checkpoint)
	_make_exit(floor_y)

	var hp: int = int(diff.player_hp) + preload("res://progression/upgrade_db.gd").perk("vitality")   # PERK: VITALITY
	player.max_health = hp
	player.health = hp
	player.position = Vector2(vp.x * 0.12, floor_y)   # (0,0) של השחקן = כפות הרגליים
	player.set_meta("ground_y", floor_y)   # PlayerMemory: מתי השחקן "גבוה"
	add_child(player)
	player.world_w = level_w
	if Game.use_checkpoint and int(Game.checkpoint.get("level", -1)) == Game.level:   # TRY AGAIN / CONTINUE מנקודת הביקורת
		_start_at_checkpoint(player)

	# מצלמה שעוקבת אחרי השחקן ונעצרת בקצוות הרמה
	var cam = CameraScript.new()
	cam.limit_left = 0
	cam.limit_right = int(level_w)
	cam.limit_top = 0
	cam.limit_bottom = int(vp.y)
	cam.position_smoothing_enabled = true
	cam.position_smoothing_speed = 8.0
	cam.zoom = Vector2(camera_zoom, camera_zoom)
	if _stage != null and _stage.underground_depth() > 0.0:   # שלב עם תת-קרקע: המצלמה יורדת אחרי השחקן
		cam.limit_bottom = int(vp.y + _stage.underground_depth())
		cam.position = Vector2(0.0, -(floor_y - (vp.y - vp.y * 0.5 / camera_zoom)))   # על הכביש: אותה תמונה כמו תמיד. במנהרה: יורדת
	player.add_child(cam)
	cam.make_current()
	cam.reset_smoothing()

	# ערפל נמוך מעל הכביש
	var fog_layer := CanvasLayer.new()
	fog_layer.visible = _stage == null or (_stage.fog() and _stage.underground_depth() <= 0.0)
	fog_layer.layer = 1
	add_child(fog_layer)
	var fog = FogScript.new()
	fog.y_screen = vp.y - (vp.y - floor_y) * camera_zoom - 6.0
	fog_layer.add_child(fog)

	# טקסט עזרה + לבבות
	var hud := CanvasLayer.new()
	hud.layer = 2
	add_child(hud)
	var label := Label.new()
	label.text = "A/D move (x2 run)  W jump/climb  S crouch (SxS drop)  LMB fire  R reload  Q wheel  1-5  C ability (6-0)  G drop  E special  SHIFT roll  F hook  RMB scope"
	label.position = Vector2(12, 8)
	label.add_theme_color_override("font_color", Color.WHITE)
	label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.7))
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 1)
	hud.add_child(label)
	var bar = HudScript.new()
	hud.add_child(bar)
	bar.set_health(player.health, player.max_health)
	bar.set_weapon(player.weapon)
	player.health_changed.connect(bar.set_health)
	player.weapon_changed.connect(bar.set_weapon)
	player.died.connect(bar.show_game_over)
	bar.difficulty = Settings.difficulty_name()
	bar.difficulty_color = Settings.COLORS[Settings.difficulty]

	# תפריט השהיה (ESC) + כפתורים במסך GAME OVER
	var pause = PauseScript.new()
	add_child(pause)
	player.died.connect(pause.show_game_over)
	_player = player
	_pause = pause
	bar.player = player
	var wheel = WheelScript.new()   # גלגל נשקים (TAB)
	wheel.player = player
	hud.add_child(wheel)
	# סצנות סיפור בתוך השלב (story/story_db.gd): דמות עומדת בשלב, מגיעים אליה -> שיחה. פעם אחת בכל משחק של השלב
	for sc in preload("res://story/story_db.gd").for_level(Game.level):
		if not Game.story_seen.has(sc.id):
			var trig = preload("res://story/story_trigger.gd").new()
			trig.data = sc
			trig.main = self
			trig.hud_layer = hud
			add_child(trig)


# ============================================================
#  הכביש: חתיכות ריצפה עם בורות ביניהן + קישוטים
# ============================================================
func _make_road(rng: RandomNumberGenerator, floor_y: float) -> void:
	# בוחרים איפה יהיו הבורות (לא באזור ההתחלה ולא בסוף)
	_pits.clear()
	for i in pits:
		var px := (level_w - safe_zone - end_margin) * float(i + 1) / float(pits + 1) + safe_zone + rng.randf_range(-250.0, 250.0)
		var pw := rng.randf_range(64.0, 90.0)
		_pits.append([px, pw])
		_rects.append(Rect2(px - 40.0, floor_y - PIT_DEPTH, pw + 80.0, PIT_DEPTH))   # שלא יופיעו זומבים/מכשולים בבור
	if _stage != null:   # חורים בכביש לתת-קרקע (בלי תחתית)
		for h in _stage.road_holes():
			_pits.append([float(h[0]), float(h[1]), true])
			_rects.append(Rect2(float(h[0]) - 40.0, floor_y - PIT_DEPTH, float(h[1]) + 80.0, PIT_DEPTH))
	_pits.sort_custom(func(a, b): return a[0] < b[0])
	var x := 0.0
	for p in _pits:
		_road_segment(x, float(p[0]), floor_y)
		if p.size() < 3:   # תחתית הבור
			_make_brick(Vector2(p[0], floor_y + PIT_DEPTH), Vector2(p[1], floor_thickness - PIT_DEPTH), 3, Color("38383d"), false)
		x = float(p[0]) + float(p[1])
	_road_segment(x, level_w, floor_y)
	# קישוטים על הכביש
	var cx := 0.0
	while cx < level_w and _streety():   # סימוני כביש רק ברחוב
		var d = RoadDecorScript.new()
		d.position = Vector2(cx, 0.0)
		d.width = 1024.0
		d.floor_y = floor_y
		d.pits = _pits
		d.pit_depth = PIT_DEPTH
		d.seed_value = rng.randi()
		add_child(d)
		cx += 1024.0
	# מכסי ביוב עם אדים (לפעמים)
	var mx := rng.randf_range(500.0, 1200.0)
	while mx < level_w - 300.0 and _streety():
		if rng.randf() < 0.55 and not _in_pit(mx - 30.0, mx + 30.0, 30.0):
			var mh = ManholeScript.new()
			mh.position = Vector2(mx, floor_y)
			add_child(mh)
			_rects.append(Rect2(mx - 30.0, floor_y - 60.0, 60.0, 60.0))   # שלא יהיה מכשול מעליו
		mx += rng.randf_range(900.0, 1700.0)
	# פנסי רחוב שעובדים (מדי פעם)
	var sub := Game.is_subway()   # רכבת תחתית: מנורות תקרה, צפופות יותר
	var lx := rng.randf_range(400.0, 700.0) if sub else rng.randf_range(700.0, 1400.0)
	while lx < level_w - 300.0 and (_stage == null or _stage.street_lamps()):
		if rng.randf() < (0.85 if sub else 0.6) and not _in_pit(lx - 40.0, lx + 40.0, 20.0):
			var lamp = LampScript.new()
			if sub:
				lamp.ceiling = true
				lamp.height = floor_y - CEIL_Y - 34.0
				lamp.light_color = Color(0.8, 0.95, 0.85)
			lamp.position = Vector2(lx, floor_y)
			add_child(lamp)
		lx += rng.randf_range(450.0, 750.0) if sub else rng.randf_range(800.0, 1500.0)


# ביצועים: הכביש בנוי מחתיכות של עד 1024 פיקסלים - כתם דם מצייר מחדש רק חתיכה אחת,
# וחתיכות שלא על המסך לא מצוירות
func _road_segment(x0: float, x1: float, floor_y: float) -> void:
	var x := x0
	while x < x1 - 0.5:
		var w := minf(1024.0, x1 - x)
		_make_brick(Vector2(x, floor_y), Vector2(w, floor_thickness), 3, Color("38383d"), false)
		x += w


func _in_pit(x0: float, x1: float, margin := 60.0) -> bool:
	for p in _pits:
		if x1 > float(p[0]) - margin and x0 < float(p[0]) + float(p[1]) + margin:
			return true
	return false


# קישוטי רחוב ברקע: רמזורים, עמודי תאורה, גדרות, פחים בוערים
func _place_street_props(rng: RandomNumberGenerator, floor_y: float) -> void:
	if not _streety():
		return
	var x := 300.0
	while x < level_w - 200.0:
		var kind := rng.randi_range(0, 3)
		var w := 150.0 if kind == 2 else 50.0
		if not _in_pit(x - 20.0, x + w + 20.0, 20.0):
			var sp = StreetPropScript.new()
			sp.kind = kind
			sp.position = Vector2(x, floor_y)
			add_child(sp)
		x += rng.randf_range(380.0, 820.0)


# ============================================================
#  יצירת רמה אקראית
#  כל מכשול בגובה של עד max_h כדי שהדמות תמיד תוכל לקפוץ מעליו.
# ============================================================
# [סוג, משקל] - משקל גבוה = מופיע יותר
const GENERATORS := [["car", 3.0], ["barrels", 2.0], ["barrier", 2.0], ["crates", 1.5], ["rubble", 1.5],
	["bus", 1.0], ["tires", 1.0], ["sandbags", 1.0], ["block", 1.0], ["wall", 1.0]]


func _generate_level(rng: RandomNumberGenerator, floor_y: float) -> void:
	var total := 0.0
	for g in _gens:
		total += float(g[1])
	var x := safe_zone
	while x < level_w - end_margin:
		if _in_pit(x, x + 280.0):   # לא שמים מכשולים ליד בור
			x += 60.0
			continue
		var r := rng.randf() * total
		var pick := ""
		for g in _gens:
			r -= float(g[1])
			if r <= 0.0:
				pick = g[0]
				break
		var used := 0.0
		match pick:
			"car": used = _gen_car(rng, x, floor_y)
			"barrels": used = _gen_barrels(rng, x, floor_y)
			"barrier": used = _gen_barrier(rng, x, floor_y)
			"crates": used = _gen_crates(rng, x, floor_y)
			"rubble": used = _gen_pyramid(rng, x, floor_y)
			"bus": used = _gen_bus(rng, x, floor_y)
			"train": used = _gen_prop_simple(rng, x, floor_y, PropScript.TRAIN)
			"container": used = _gen_prop_simple(rng, x, floor_y, PropScript.CONTAINER)
			"tires": used = _gen_prop_simple(rng, x, floor_y, PropScript.TIRES)
			"sandbags": used = _gen_prop_simple(rng, x, floor_y, PropScript.SANDBAGS)
			"block": used = _gen_block(rng, x, floor_y)
			"wall": used = _gen_low_wall(rng, x, floor_y)
			_:
				used = _stage.custom_gen(pick, x) if _stage != null else 0.0
				if used <= 0.0:
					used = _gen_low_wall(rng, x, floor_y)
		x += used + rng.randf_range(gap_min, gap_max)


func _prop(kind: int, x: float, floor_y: float) -> Node:
	var p = PropScript.new()
	p.kind = kind
	p.max_height = max_h
	p.position = Vector2(x, floor_y)
	return p


func _add_prop(p: Node, floor_y: float) -> void:
	add_child(p)
	_rects.append(Rect2(p.position.x, floor_y - p.size.y, p.size.x, p.size.y))


# מכונית הרוסה (לפעמים הפוכה, לפעמים שרופה עם אש, לפעמים עם חבית לידה)
func _gen_car(rng: RandomNumberGenerator, x: float, floor_y: float) -> float:
	var p = _prop(PropScript.CAR, x, floor_y)
	p.color = CAR_COLORS[rng.randi() % CAR_COLORS.size()]
	p.upside_down = rng.randf() < 0.25
	p.wrecked = rng.randf() < 0.3
	_add_prop(p, floor_y)
	var used := 128.0
	if rng.randf() < 0.35:
		var b = _prop(PropScript.BARREL, x + 140.0, floor_y)
		_add_prop(b, floor_y)
		used += 34.0
	return used


func _gen_bus(rng: RandomNumberGenerator, x: float, floor_y: float) -> float:
	var p = _prop(PropScript.BUS, x, floor_y)
	_add_prop(p, floor_y)
	return p.size.x


# 1-3 חביות נפץ (טוב לפוצץ קבוצת זומבים)
func _gen_barrels(rng: RandomNumberGenerator, x: float, floor_y: float) -> float:
	var n := rng.randi_range(1, 3)
	var cx := x
	for i in n:
		_add_prop(_prop(PropScript.BARREL, cx, floor_y), floor_y)
		cx += 24.0 + rng.randf_range(0.0, 10.0)
	return cx - x


func _gen_barrier(rng: RandomNumberGenerator, x: float, floor_y: float) -> float:
	var n := rng.randi_range(1, 2)
	for i in n:
		_add_prop(_prop(PropScript.BARRIER, x + float(i) * 66.0, floor_y), floor_y)
	return float(n) * 66.0


func _gen_prop_simple(rng: RandomNumberGenerator, x: float, floor_y: float, kind: int) -> float:
	var p = _prop(kind, x, floor_y)
	if kind == PropScript.TIRES:
		p.count = rng.randi_range(2, 3)
	add_child(p)
	_rects.append(Rect2(x, floor_y - 40.0, p.size.x, 40.0))
	return p.size.x


# גוש בטון הרוס
func _gen_block(rng: RandomNumberGenerator, x: float, floor_y: float) -> float:
	var ws := [32.0, 48.0, 64.0]
	var w: float = ws[rng.randi() % ws.size()]
	var rows := rng.randi_range(2, maxi(2, int(max_h / UNIT)))
	_place(rng, x, floor_y, w, float(rows) * UNIT, 2)
	return w


# קיר בטון נמוך וארוך
func _gen_low_wall(rng: RandomNumberGenerator, x: float, floor_y: float) -> float:
	var w := float(rng.randi_range(3, 6)) * 32.0
	var rows := rng.randi_range(1, mini(2, maxi(1, int(max_h / UNIT))))
	_place(rng, x, floor_y, w, float(rows) * UNIT, rng.randi_range(0, 1) * 2)
	return w


# ערימת הריסות: מדרגות עולות ויורדות (כל מדרגה נמוכה מספיק כדי לקפוץ עליה)
func _gen_pyramid(rng: RandomNumberGenerator, x: float, floor_y: float) -> float:
	var n := rng.randi_range(2, 3)
	var step := minf(2.0 * UNIT, max_h)
	var step_w := 48.0
	var total := float(2 * n - 1)
	for i in 2 * n - 1:
		var level := mini(i, 2 * n - 2 - i) + 1
		_place(rng, x + float(i) * step_w, floor_y, step_w, float(level) * step, 2 if rng.randf() < 0.7 else 0)
	return total * step_w


# ארגזי עץ (נשברים מקליעים)
func _gen_crates(rng: RandomNumberGenerator, x: float, floor_y: float) -> float:
	var n := rng.randi_range(2, 4)
	var cx := x
	for i in n:
		var sz := 32.0 if rng.randf() < 0.6 else 40.0
		_place(rng, cx, floor_y, sz, sz, 1)
		if rng.randf() < 0.3 and sz * 2.0 <= max_h:   # ארגז על ארגז
			_place(rng, cx + 2.0, floor_y - sz, sz - 4.0, sz - 4.0, 1)
		cx += sz + rng.randf_range(10.0, 50.0)
	return cx - x


func _place(rng: RandomNumberGenerator, x: float, floor_y: float, w: float, h: float, style := 0) -> void:
	h = minf(h, max_h * 2.5)   # הגנה: גם מדרגות לא יעלו על הגובה הכולל
	var col: Color = BRICK_COLORS[rng.randi() % BRICK_COLORS.size()]
	if style == 1:
		col = Color("7a5a36").darkened(rng.randf_range(0.0, 0.2))
	elif style == 2:
		col = CONCRETE_COLORS[rng.randi() % CONCRETE_COLORS.size()]
	_make_brick(Vector2(x, floor_y - h), Vector2(w, h), style, col, true)
	_rects.append(Rect2(x, floor_y - h, w, h))


# ============================================================
#  זומבים אקראיים
# ============================================================
func _spawn_zombies(rng: RandomNumberGenerator, floor_y: float) -> void:
	var count := int(round(float(level_screens) * zombies_per_screen))
	var spawned := 0
	var tries := 0
	while spawned < count and tries < 600:
		tries += 1
		var zx := rng.randf_range(safe_zone + 200.0, level_w - 150.0)
		if _near_brick(zx):
			continue
		var group := 1
		var k0 := _pick_kind(rng)
		if k0 == 10:   # חולדות: להקה
			group = rng.randi_range(5, 7)
		elif k0 == 15:   # כלבים: תמיד זוג
			group = 2
		elif rng.randf() < zombie_cluster_chance:
			group = rng.randi_range(2, 3)
		for g in group:
			var gx := zx + float(g) * (rng.randf_range(16.0, 26.0) if k0 == 10 else rng.randf_range(34.0, 60.0))
			if gx < level_w - 80.0 and not _near_brick(gx):
				var kk := k0 if (g == 0 or k0 == 10 or k0 == 15) else _pick_kind(rng)
				if kk == 10 and k0 != 10:
					kk = 0
				_spawn_zombie(gx, floor_y, kk, rng)
				spawned += 1
				if kk == 13:   # זורק: מגיע עם 2 זומבים קטנים
					for q in 2:
						_spawn_zombie(gx + 34.0 + float(q) * 24.0, floor_y, 14, rng)
						spawned += 1


# 3 ניצולות לאורך השלב (במקומות פנויים)
func _spawn_survivors(rng: RandomNumberGenerator, floor_y: float) -> void:
	for i in 3:
		var x := level_w * (0.25 + 0.27 * float(i)) + rng.randf_range(-200.0, 200.0)
		var tries := 0
		while _near_brick(x) and tries < 80:
			x += 37.0
			tries += 1
		var s = SurvivorScript.new()
		s.variant = i
		s.position = Vector2(x, floor_y)
		add_child(s)
		s.world_w = level_w


# רחוב: שלבים 1, 4 ושלבים חדשים שמבקשים (stage.street_props)
func _streety() -> bool:
	return Game.is_street() or (_stage != null and _stage.street_props())


# {kind: weight} -> מערך לפי מספר סוג (כמו zombie_weights)
func _weights_array(d: Dictionary) -> Array:
	var mx := 0
	for k in d:
		mx = maxi(mx, int(k))
	var arr := []
	arr.resize(mx + 1)
	arr.fill(0.0)
	for k in d:
		arr[int(k)] = float(d[k])
	return arr


func _near_brick(x: float) -> bool:
	for r in _rects:
		if x > r.position.x - 40.0 and x < r.end.x + 40.0:
			return true
	return false


func _pick_kind(rng: RandomNumberGenerator) -> int:
	var total := 0.0
	for w in zombie_weights:
		total += float(w)
	var r := rng.randf() * total
	for i in zombie_weights.size():
		r -= float(zombie_weights[i])
		if r <= 0.0:
			return i
	return 0


func _start_at_checkpoint(player: Node2D) -> void:
	var cp: Dictionary = Game.checkpoint
	player.position.x = _checkpoint.position.x + 30.0
	player.slots = (cp.slots as Array).duplicate(true)
	player.special = str(cp.get("special", ""))
	player.special_uses = int(cp.get("special_uses", 0))
	for i in player.slots.size():
		if player.slots[i] != null:
			player.cur_slot = i
			break
	_checkpoint.set_reached()
	for z in get_tree().get_nodes_in_group("zombies"):   # זומבים שכבר עברת / ממש ליד - לא מחכים לך שם
		if not z.is_boss() and z.global_position.x < player.position.x + 260.0:
			z.queue_free()


# נקודות אספקה קבועות + נשקים לפי מבנה ההתקדמות (progression/arsenal.gd)
func _spawn_supplies(_rng: RandomNumberGenerator, floor_y: float) -> void:
	var points: Array = _stage.supply_points() if _stage != null else Arsenal.SUPPLY_POINTS
	for sp in points:
		var x := _free_spot(level_w * float(sp[0]))
		var kinds: Array = {"ammo": [PickupScript.AMMO], "supply": [PickupScript.SUPPLY], "health": [PickupScript.HEALTH, PickupScript.AMMO]}.get(sp[1], [PickupScript.AMMO])
		var mk = Arsenal.SupplyMarker.new()
		mk.kind = sp[1]
		mk.position = Vector2(x, floor_y)
		add_child(mk)
		for i in kinds.size():
			_place_pickup(kinds[i], Vector2(x + float(i) * 26.0 - float(kinds.size() - 1) * 13.0, floor_y - 30.0))
	# פריטי נפץ (SPECIAL): 1-2 בשלב, במקום אקראי (רימונים / מולוטוב / משגר רימונים / משגר טילים)
	var sp_list: Array = Arsenal.specials_for_level(Game.level, _rng)
	for si in sp_list.size():
		var k: String = sp_list[si]
		var lo: float = lerpf(Arsenal.SPECIAL_FINDS.x, Arsenal.SPECIAL_FINDS.y, float(si) / float(sp_list.size()))   # כל אחד בחלק אחר של השלב
		var hi: float = lerpf(Arsenal.SPECIAL_FINDS.x, Arsenal.SPECIAL_FINDS.y, float(si + 1) / float(sp_list.size()))
		var spc = PickupScript.new()
		spc.kind = PickupScript.SPECIAL
		spc.special = k
		spc.life = 100000.0
		add_child(spc)
		spc.setup(Vector2(_free_spot(level_w * _rng.randf_range(lo, hi)), floor_y - 30.0), Vector2.ZERO)
	# נשקים: החדש של השלב בהתחלה (NEW WEAPON), ומטמון של נשק ישן שאין לך באמצע השלב
	var owned := []
	for s in Game.weapon_slots:
		if s != null:
			owned.append(s.id)
	var off: Dictionary = Arsenal.offers(Game.level, owned)
	var n := 0
	for wid in off.new:
		_place_weapon(wid, _free_spot(safe_zone * 0.75 + float(n) * 90.0), floor_y)
		n += 1
	if int(off.cache) >= 0:
		var cx := _free_spot(level_w * Arsenal.CACHE_AT)
		var mk = Arsenal.SupplyMarker.new()
		mk.kind = "cache"
		mk.position = Vector2(cx, floor_y)
		add_child(mk)
		_place_weapon(int(off.cache), cx, floor_y)


func _free_spot(x: float) -> float:
	var tries := 0
	while _near_brick(x) and tries < 60:
		x += 41.0
		tries += 1
	return x


func _place_pickup(kind: int, pos: Vector2) -> void:
	var p = PickupScript.new()
	p.kind = kind
	p.life = 100000.0
	add_child(p)
	p.setup(pos, Vector2.ZERO)


func _place_weapon(wid: int, x: float, floor_y: float) -> void:
	var p = PickupScript.new()
	p.kind = PickupScript.WEAPON
	p.weapon_id = wid
	p.life = 100000.0
	add_child(p)
	p.setup(Vector2(x, floor_y - 30.0), Vector2.ZERO)


# היציאה + הבוס ששומר עליה
func _make_exit(floor_y: float) -> void:
	var ex = ExitScript.new()
	ex.position = Vector2(level_w - 230.0, floor_y)
	add_child(ex)
	ex.reached.connect(_level_complete)
	if _stage != null and _stage.boss_kind() < 0:
		return
	var boss = ZombieScene.instantiate()
	boss.kind = 7 if Game.is_subway() else (19 if Game.is_night() else 5)   # רכבת תחתית: המוליך, לילה: הכלב
	if _stage != null:
		boss.kind = _stage.boss_kind()
	boss.position = Vector2(level_w - 480.0, floor_y)
	boss.chase_range = 650.0
	var diff: Dictionary = Settings.preset()
	boss.speed_mult = diff.zombie_speed
	add_child(boss)
	boss.world_w = level_w
	boss._dir = -1.0


# מוזיקת רקע: שלב רחוב = TOTAL WAR, רכבת תחתית = מתח ואימה. מתנגנת בלופ ונכנסת בהדרגה
@export var music_volume_db := -7.0   # היה -14: המוזיקה נבלעה מתחת ליריות
func _start_music() -> void:
	var path := "res://music/level2_suspense.mp3" if Game.is_subway() or Game.is_night() else "res://music/level1_total_war.mp3"
	if Game.level == 1:
		path = "res://music/level1_zombie_joyride.ogg"   # "Zombie Joyride" (EDM). OGG = קובץ קטן בערך פי 2.5 מ-MP3 באותה איכות
	if _stage != null:
		path = _stage.music()
	var stream := _load_music(path)
	if stream == null:
		push_warning("[MUSIC] could not load " + path + " - copy the music folder into the game folder")
		return
	if Settings.music_volume <= 0.001:
		print("[MUSIC] music volume is 0 in the settings (pause menu) - you won't hear ", path)
	else:
		print("[MUSIC] playing ", path)
	var mp := AudioStreamPlayer.new()
	mp.bus = "Music"   # עוצמה: Settings.music_volume
	mp.stream = stream
	mp.volume_db = -40.0
	mp.process_mode = Node.PROCESS_MODE_ALWAYS   # ממשיכה גם בהשהיה
	add_child(mp)
	mp.play()
	create_tween().tween_property(mp, "volume_db", music_volume_db, 2.5)


# טוען מוזיקה. אם העורך עוד לא ייבא את הקובץ - קוראים אותו ישירות (OGG / MP3)
func _load_music(path: String) -> AudioStream:
	var stream: AudioStream = null
	if ResourceLoader.exists(path):
		stream = load(path) as AudioStream
	if stream == null and FileAccess.file_exists(path):
		if path.ends_with(".ogg"):
			stream = AudioStreamOggVorbis.load_from_file(path)
		elif path.ends_with(".mp3"):
			var mp3 := AudioStreamMP3.new()
			mp3.data = FileAccess.get_file_as_bytes(path)
			stream = mp3
	if stream is AudioStreamMP3:
		(stream as AudioStreamMP3).loop = true
	elif stream is AudioStreamOggVorbis:
		(stream as AudioStreamOggVorbis).loop = true
	return stream


func _process(delta: float) -> void:
	if not _finished and _player != null and not _player.dead:
		_time += delta


func _level_complete() -> void:
	if _finished:
		return
	_finished = true
	Engine.time_scale = 1.0
	Game.weapon_slots = _player.slots.duplicate(true)   # הנשקים והתחמושת עוברים לשלב הבא
	var result := Game.finish_level(_time)
	var r = ResultsScript.new()
	add_child(r)
	r.show_results(result)


func _exit_tree() -> void:
	Engine.time_scale = 1.0


func _spawn_zombie(x: float, floor_y: float, kind := 0, rng: RandomNumberGenerator = null) -> Node:
	var z = ZombieScene.instantiate()
	z.kind = kind   # 0 = רגיל, 1 = רץ, 2 = ענק, 3 = יורק, 4 = צורח ... (ראה zombie.gd)
	var diff: Dictionary = Settings.preset()
	z.speed_mult = diff.zombie_speed
	z.smart_mult = diff.smart * Game.intelligence()   # THEY LEARN: חכמים יותר בכל שלב
	if rng != null and rng.randf() < dormant_chance and kind < 7:
		z.dormant = true   # שוכב על הריצפה וקם כשמתקרבים
	z.position = Vector2(x, floor_y)   # (0,0) של הזומבי = כפות הרגליים
	if kind == 8:   # זוחל: מתחיל על התקרה
		z.on_ceiling = true
		z.position.y = CEIL_Y
	add_child(z)
	z.world_w = level_w
	return z


func _make_brick(pos: Vector2, sz: Vector2, style := 0, col := Color("9a4f3a"), is_breakable := true) -> void:
	var b = BrickScene.instantiate()
	b.position = pos
	b.size = sz
	b.style = style
	b.show_bricks = true
	b.grass = false
	b.color = col
	b.breakable = is_breakable
	if style == 1:
		b.hit_points = 2   # ארגז עץ נשבר מהר
	add_child(b)


func _unhandled_input(event: InputEvent) -> void:
	pass   # R = טעינה (player.gd). התחלה מחדש: ESC -> RESTART
