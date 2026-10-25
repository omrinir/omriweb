extends Node2D
# ============================================================
#  CHARACTER MAKER - בונים זומבי מחלקים (characters/parts.gd): מבנה גוף, גדלים, צבעים, שיער, כובע, פנים,
#  בגדים, תוספות, חפץ ביד וגור. משמאל הוא חי: עומד, הולך, רץ, תוקף את הגיבור, נפגע ומת עם כל הגור של המשחק
#  (נקרע לשניים, הראש עף, מתפוצץ, נשרף עד העצמות, זוחל בלי רגליים).
#  SAVE = קובץ טקסט אחד: characters/saved/<id>.tres (characters/character_preset.gd), והמשחק טוען אותו לבד.
#  LEVELS = באילו שלבים הוא מופיע (SHARE = אחוז מהזומבים שם). TRY IN LEVEL = משחקים שלב איתו (תרגול, לא נשמר).
#  רק מתוך העורך של Godot: משחק מיוצא לא יכול לכתוב קבצים לתוך התיקייה שלו (הכפתור בתפריט מוסתר שם).
#  חלקים חדשים: characters/parts.gd (הוראות בראש הקובץ) - הכפתורים כאן נבנים מהרשימות שם.
# ============================================================

const Preset := preload("res://characters/character_preset.gd")
const Parts := preload("res://characters/parts.gd")
const CustomChars := preload("res://characters/custom_characters.gd")
const BackgroundScript := preload("res://background.gd")
const BrickScene := preload("res://brick.tscn")
const PlayerScript := preload("res://player.gd")
const ZombieScene := preload("res://zombie.tscn")
const RoadDecorScript := preload("res://road_decor.gd")
const StreetPropScript := preload("res://street_prop.gd")
const Sfx := preload("res://sfx.gd")
const FONT := preload("res://fonts/Bangers-Regular.ttf")

const MENU_SCENE := "res://menu.tscn"
const GAME_SCENE := "res://main.tscn"
const FLOOR_Y := 300.0
const WORLD_W := 2400.0
const HERO_X := 600.0             # הגיבור (בשביל הגודל) עומד כאן
const HOME_X := 672.0             # הדמות עומדת כאן מולו
const WALK_MIN := 380.0           # WALK / RUN: הולך הלוך ושוב בין שני אלה (CROWD: _lo() / _hi())
const WALK_MAX := 1300.0
const ZOOM := 3.0
const ZOOM_CROWD := 1.45
const VIEW_W := 780.0             # רוחב אזור התצוגה (מסך); מימין הלוח
const FLOOR_SCREEN := 575.0       # גובה הכביש על המסך
const RESPAWN_T := 2.6            # מת: אחרי כמה שניות מגיע חדש
const CROWD_N := 6
const ACCENT := Color("b3121a")
const PANEL_BG := Color(0.07, 0.06, 0.06, 0.93)
const TEXT := Color(0.93, 0.9, 0.86)
const DIM := Color(0.62, 0.58, 0.55)
const GOOD := Color(0.55, 0.95, 0.55)
const WARN := Color(1.0, 0.78, 0.3)

# צבעים מהירים לכל צבע (לחיצה = הצבע). אפשר גם לבחור כל צבע בכפתור הגדול
const SWATCHES := {
	"skin_color": ["86a06a", "aab7a6", "6c8450", "a8b04a", "c8c2bc", "8a9ea4", "b8b47a", "74945a", "a08a8a", "7a6a5a"],
	"shirt_color": ["4f6688", "7a4a3a", "6e3036", "5a6448", "8a7646", "3e6a6a", "6a6a74", "9a8c74", "4a3a5a", "d8d4c8"],
	"pants_color": ["3d3a4c", "34466a", "4e4638", "2e3a2e", "4a4a50", "5a5040", "1e1e24", "6a5a48", "8a7a5a", "5a2a2a"],
	"shoe_color": ["2c241e", "1a1a1a", "4a3220", "6a6a70", "8a2a20", "d8d8d0", "2a3a5a", "5a4a2a"],
	"hair_color": ["5a4630", "3a3026", "6e5638", "8a8880", "94582c", "a8986a", "1a1616", "c8c4b8", "6a2a8a", "2a8a4a"],
	"eye_color": ["ffd940", "ff3020", "60ff40", "40c0ff", "ff60ff", "ffffff", "ff9020", "a040ff"],
	"hat_color": ["3a3e46", "c8a020", "d83020", "2a4a8a", "e8e4dc", "2e5a2e", "6a3a8a", "1a1a1e", "8a6a3a", "e87aa0"],
	"gear_color": ["8a6a3a", "e8e4dc", "c8a020", "3a5a3a", "6a2a2a", "2a3a5a", "d86a20", "1a1a1e", "5a5a62", "a8c8d8"],
}
const COLOR_NAMES := [["skin_color", "SKIN"], ["shirt_color", "SHIRT / COAT"], ["pants_color", "PANTS"], ["shoe_color", "SHOES"],
	["hair_color", "HAIR"], ["eye_color", "GLOWING EYE"], ["hat_color", "HAT"], ["gear_color", "EXTRAS (APRON, VEST...)"]]
const NAME_A := ["ROTTEN", "HUNGRY", "ANGRY", "SAD", "LOST", "BIG", "LITTLE", "OLD", "MAD", "SLOW", "LOUD", "SMELLY", "SLEEPY", "GRUMPY"]
const NAME_B := ["BUTCHER", "CHEF", "DOCTOR", "CLERK", "BIKER", "FARMER", "TOURIST", "BANKER", "JANITOR", "MINER", "MAILMAN", "DJ", "COACH", "PLUMBER", "DENTIST"]

var cur = null                    # הדמות שעורכים (עותק עבודה - נכתב לקובץ רק ב-SAVE)
var _path := ""                   # הקובץ שלה ("" = עוד לא נשמרה)
var _dirty := false
var z = null                      # הדמות החיה בתצוגה
var crowd := []
var _crowd_on := false
var _corpses := []
var hero = null
var cam: Camera2D
var mode := "stand"               # stand / walk / run / attack
var _rebuild_t := 0.0
var _respawn_t := -1.0
var _try_level := 1
var _syncing := false             # מעדכנים את הכפתורים מהדמות (לא שינוי של המשתמש)
var _bg: Node2D
var _night: CanvasModulate
# ---- ממשק ----
var _ui_root: Control
var _list: OptionButton
var _name: LineEdit
var _info: Label
var _toast: Label
var _confirm: ConfirmationDialog
var _groups := {}                 # שדה -> {ערך: כפתור}
var _sliders := {}                # שדה -> [HSlider, Label, פורמט]
var _colors := {}                 # שדה -> ColorPickerButton
var _flags := {}                  # שדה -> כפתור
var _level_btns := {}             # שלב -> כפתור
var _mode_btns := {}
var _try_lbl: Label
var _crowd_btn: Button
var _night_btn: Button


# מצלמה שיודעת לרעוד (פיצוצים) כמו במשחק
class PreviewCam extends Camera2D:
	var _s := 0.0
	var _t := 0.0

	func shake(strength: float, dur: float) -> void:
		_s = maxf(_s, strength * 0.4)
		_t = maxf(_t, dur)

	func _process(delta: float) -> void:
		_t -= delta
		offset = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * _s / zoom.x if _t > 0.0 else Vector2.ZERO
		if _t <= 0.0:
			_s = 0.0


# קו של כדור מהרובה של הגיבור (SHOOT / KILL)
class Tracer extends Node2D:
	var a := Vector2.ZERO
	var b := Vector2.ZERO
	var t := 0.09

	func _process(delta: float) -> void:
		t -= delta
		if t <= 0.0:
			queue_free()
		queue_redraw()

	func _draw() -> void:
		var k := clampf(t / 0.09, 0.0, 1.0)
		draw_line(a, b, Color(1.0, 0.9, 0.55, 0.85 * k), 1.2, true)


func _ready() -> void:
	var back: Dictionary = Game.custom_test   # חזרה מ-TRY IN LEVEL: ממשיכים לערוך את אותה דמות (גם אם לא נשמרה)
	Game.end_practice()
	Game.start_practice(1)   # הגיבור נפגע כאן בהדגמת ATTACK - כלום לא נשמר
	get_tree().paused = false
	Settings.menu_music(true)
	Sfx.warm_up()
	CustomChars.reload()
	_build_world()
	_build_ui()
	if not back.is_empty() and back.get("preset") != null:
		_try_level = int(back.get("level", 1))
		_edit(back.preset, str(back.get("path", "")), bool(back.get("dirty", false)))
	else:
		var all := CustomChars.all()
		if all.is_empty():
			_new()
		else:
			_open(all[0])


# ============================================================
#  העולם: רחוב, הגיבור, מצלמה
# ============================================================
func _build_world() -> void:
	var bg_layer := CanvasLayer.new()
	bg_layer.layer = -10
	add_child(bg_layer)
	_bg = BackgroundScript.new()
	_bg.level_w = WORLD_W * 2.0
	bg_layer.add_child(_bg)
	var x := 0.0
	while x < WORLD_W - 0.5:   # כביש כמו ב-main.gd (_road_segment + סימוני כביש)
		var road = BrickScene.instantiate()
		road.position = Vector2(x, FLOOR_Y)
		road.size = Vector2(minf(1024.0, WORLD_W - x), 90.0)
		road.style = 3
		road.color = Color("38383d")
		road.grass = false
		road.breakable = false
		add_child(road)
		var decor = RoadDecorScript.new()
		decor.position = Vector2(x, 0.0)
		decor.width = 1024.0
		decor.floor_y = FLOOR_Y
		decor.seed_value = 5 + int(x)
		add_child(decor)
		x += 1024.0
	for spec in [[0, 430.0], [3, 1180.0]]:   # רמזור + פח בוער
		var sp = StreetPropScript.new()
		sp.kind = spec[0]
		sp.position = Vector2(spec[1], FLOOR_Y)
		add_child(sp)
	hero = PlayerScript.new()
	hero.controllable = false
	hero.position = Vector2(HERO_X, FLOOR_Y)
	add_child(hero)
	hero.world_w = WORLD_W
	cam = PreviewCam.new()
	cam.zoom = Vector2(ZOOM, ZOOM)
	cam.position = _cam_target(HOME_X, ZOOM)
	add_child(cam)
	cam.make_current()
	_night = CanvasModulate.new()
	_night.color = Color(0.3, 0.32, 0.45)
	_night.visible = false
	add_child(_night)


func _cam_target(fx: float, zm: float) -> Vector2:
	return Vector2(fx + (640.0 - VIEW_W / 2.0) / zm, FLOOR_Y - (FLOOR_SCREEN - 360.0) / zm)


func _physics_process(delta: float) -> void:
	if _rebuild_t > 0.0:
		_rebuild_t -= delta
		if _rebuild_t <= 0.0:
			_respawn(false)
	hero.health = hero.max_health
	hero.global_position.x = HERO_X
	hero.velocity.x = 0.0
	if _alive():
		_drive(z, true)
		if hero._muzzle_flash <= 0.0:
			_aim_at(z.global_position + Vector2(0.0, -38.0 * z.sc))
	else:   # מת (נקרע / התפוצץ: הגוף כבר לא קיים) -> חדש בעוד רגע
		if _respawn_t < 0.0:
			_respawn_t = RESPAWN_T
		_respawn_t -= delta
		if _respawn_t <= 0.0:
			_respawn(true)
	for c in crowd:
		if is_instance_valid(c) and not c.dead:
			_drive(c, false)
	var zm := ZOOM if not _crowd_on else ZOOM_CROWD
	var fx := HOME_X
	if _crowd_on:
		fx = HERO_X + 240.0
	elif mode == "attack":   # הגיבור והדמות ביחד בתמונה
		fx = HOME_X
	elif z != null and is_instance_valid(z):
		fx = z.global_position.x
	var k := 1.0 - exp(-5.0 * delta)
	cam.zoom = cam.zoom.lerp(Vector2(zm, zm), k)
	cam.position = cam.position.lerp(_cam_target(fx, cam.zoom.x), k)


func _alive() -> bool:
	return z != null and is_instance_valid(z) and not z.dead


# איפה הולכים הלוך ושוב (CROWD: קרוב לגיבור, שכולם ייכנסו לתמונה)
func _lo() -> float:
	return HERO_X + 70.0 if _crowd_on else WALK_MIN


func _hi() -> float:
	return HERO_X + 460.0 if _crowd_on else WALK_MAX


# הדמות זזה לפי הכפתורים: STAND / WALK / RUN / ATTACK
func _drive(zz, main: bool) -> void:
	if main or mode != "walk":
		zz._wander_t = 1.0e9   # (בלי להסתובב סתם; הקהל ב-WALK מסתובב כמו במשחק)
	match mode:
		"walk":
			if zz.global_position.x > _hi():
				zz._dir = -1.0
			elif zz.global_position.x < _lo():
				zz._dir = 1.0
		"run":
			if zz.goal_x == INF or absf(zz.goal_x - zz.global_position.x) < 16.0:
				zz.goal_x = _lo() if zz.global_position.x > (_lo() + _hi()) / 2.0 else _hi()


func _apply_mode(zz) -> void:
	zz.walk_speed = 0.0 if mode == "stand" else float(cur.walk_speed)
	zz.chase_range = 4000.0 if mode == "attack" else 0.0
	zz.goal_x = INF
	zz._wander_t = 1.0e9


func _set_mode(m: String) -> void:
	mode = m
	for k in _mode_btns:
		_mode_btns[k].set_pressed_no_signal(k == m)
	for zz in [z] + crowd:
		if zz != null and is_instance_valid(zz) and not zz.dead:
			_apply_mode(zz)
			if m == "walk" and zz.velocity.x == 0.0:
				zz._dir = 1.0 if zz.global_position.x < (_lo() + _hi()) / 2.0 else -1.0


# ============================================================
#  הדמות החיה
# ============================================================
func _spawn(x: float, dir: float, exact: bool) -> Node:
	CustomChars.live[int(cur.kind)] = cur
	var nz = ZombieScene.instantiate()
	nz.kind = int(cur.kind)
	nz.position = Vector2(x, FLOOR_Y)
	add_child(nz)
	nz.world_w = WORLD_W
	nz.dormant = false
	nz._dir = dir
	if exact and nz.cust != null:   # זה שמקדימה: בדיוק הצבעים שבחרת (הקהל מראה את ה-VARIETY)
		nz.skin = cur.skin_color
		nz.shirt = cur.skin_color if cur.top == "bare" else cur.shirt_color
		nz.pants = cur.pants_color
		nz.hair = cur.hair_color
		nz.cust.hair_col = cur.hair_color
	_apply_mode(nz)
	return nz


# חדש במקום הקיים (fresh = מול הגיבור. אחרת: אותו מקום, כיוון וצעד - כשמשנים משהו בלוח)
func _respawn(fresh: bool) -> void:
	_rebuild_t = 0.0
	_respawn_t = -1.0
	var x := HOME_X
	var dir := -1.0
	var keep: bool = not fresh and _alive() and not z._legless
	var ph := 0.0
	var t := 0.0
	if keep:
		x = z.global_position.x
		dir = z._dir
		ph = z._walk_phase
		t = z._time
	if z != null and is_instance_valid(z):
		if z.dead:
			_corpses.append(z)
		else:
			z.queue_free()
	while _corpses.size() > 2:
		var c = _corpses.pop_front()
		if is_instance_valid(c):
			c.queue_free()
	z = _spawn(x, dir, true)
	if keep:
		z._walk_phase = ph
		z._time = t
	_rebuild_crowd()


func _rebuild_crowd() -> void:
	for c in crowd:
		if is_instance_valid(c) and not c.dead:
			c.queue_free()
	crowd.clear()
	if not _crowd_on:
		return
	for i in CROWD_N:
		var x := lerpf(_lo() + 20.0, _hi() - 20.0, (float(i) + 0.5) / float(CROWD_N)) + randf_range(-20.0, 20.0)
		var c = _spawn(x, -1.0 if randf() < 0.5 else 1.0, false)
		if mode == "walk":
			c._wander_t = randf_range(0.5, 3.0)
		crowd.append(c)


func _toggle_crowd() -> void:
	_crowd_on = not _crowd_on
	_crowd_btn.set_pressed_no_signal(_crowd_on)
	_rebuild_crowd()


func _toggle_night() -> void:
	_night.visible = not _night.visible
	_bg.modulate = Color(0.3, 0.32, 0.45) if _night.visible else Color.WHITE
	_night_btn.set_pressed_no_signal(_night.visible)


func _turn() -> void:
	if _alive():
		z._dir = -z._dir
		if mode == "run":
			z.goal_x = _lo() if z._dir < 0.0 else _hi()


# ---- יורים בו ----
func _zone_pos(zz, zone: String) -> Vector2:
	match zone:
		"head":
			return zz.global_position + Vector2(zz._dir * 3.0 * zz.wf * zz.sc, -50.0 * zz.sc)
		"legs":
			return zz.global_position + Vector2(0.0, -9.0 * zz.sc)
	return zz.global_position + Vector2(0.0, -31.0 * zz.sc)


func _gun() -> Vector2:
	return hero.global_position + Vector2(0.0, -36.0)


func _aim_at(p: Vector2) -> void:
	var d := p - _gun()
	if d.length() > 4.0:
		hero.idle_aim = d.normalized()


func _shoot(at: Vector2) -> Vector2:
	_aim_at(at)
	var dir := (at - _gun()).normalized()
	var tr := Tracer.new()
	tr.a = _gun() + dir * 24.0
	tr.b = at
	tr.z_index = 20
	add_child(tr)
	hero._muzzle_flash = hero.MUZZLE_T
	Sfx.play("rifle", hero.global_position, -6.0, 0.08, 5)
	return Vector2(signf(dir.x) if dir.x != 0.0 else 1.0, dir.y * 0.4).normalized()


# פגיעה בלי מוות (רואים את התגובה: הראש נזרק, מתקפל מכדור בבטן, צולע מכדור ברגל)
func _hit(zone: String) -> void:
	if not _alive():
		return
	z.hp = maxi(z.hp, 100000)
	var at := _zone_pos(z, zone)
	z.take_damage(0, at, _shoot(at), false, {"source": "bullet"})


# מוות: כל אחד מהמיתות המיוחדות של המשחק (zombie.gd force_*)
func _kill(how: String) -> void:
	if not _alive():
		return
	var meta: String = {"tear": "force_tear", "nohead": "force_hw", "burst": "force_burst", "crawl": "force_crawl", "burn": "force_char"}.get(how, "")
	if meta != "":
		z.set_meta(meta, true)
	var zone := "head" if how == "nohead" or how == "headshot" else ("legs" if how == "crawl" else "body")
	var at := _zone_pos(z, zone)
	var dir := _shoot(at)
	z.hp = 1
	if how == "burst":   # פיצוץ מקרוב
		Sfx.play("explosion", at, -4.0, 0.1, 3)
		if cam.has_method("shake"):
			cam.shake(8.0, 0.3)
	z.take_damage(999, at, dir, how == "burst", {"source": "fire" if how == "burn" else "bullet", "fixed": 999})
	if how == "crawl" and _alive():
		z.chase_range = 0.0


# ============================================================
#  הדמות שעורכים: חדשה / פתיחה / שמירה / מחיקה
# ============================================================
func _edit(p: Resource, path: String, dirty := false) -> void:
	cur = p
	_path = path
	_dirty = dirty
	CustomChars.live.clear()
	CustomChars.live[int(cur.kind)] = cur
	_sync_ui()
	_respawn(true)
	_refresh_list()
	_update_info()


func _open(p: Resource) -> void:
	_edit(p.duplicate(), p.resource_path)


func _new() -> void:
	var p = Preset.new()
	CustomChars.live.clear()
	p.kind = CustomChars.next_kind()
	p.name = "NEW ZOMBIE"
	_edit(p, "", true)


func _copy() -> void:
	var p = cur.duplicate()
	CustomChars.live.clear()
	CustomChars.live[int(cur.kind)] = cur
	p.kind = CustomChars.next_kind()
	p.id = ""
	p.name = (str(cur.name) + " 2").substr(0, 28)
	p.levels = PackedInt32Array()
	_edit(p, "", true)
	_flash_msg("COPY: SAME LOOK, NEW CHARACTER (NOT SAVED YET)", WARN)


func _random() -> void:
	var p = cur
	var r := randf()
	p.build = "normal" if r < 0.5 else ("skinny" if r < 0.75 else "big")
	p.height = snappedf(randf_range(0.92, 1.12), 0.01)
	p.width = snappedf(randf_range(0.9, 1.15), 0.01)
	p.head_size = snappedf(randf_range(0.9, 1.25), 0.01)
	p.hunch = snappedf(randf_range(1.0, 7.0), 0.5)
	p.hair = Parts.HAIRS.pick_random()
	p.hat = "none" if randf() < 0.4 else Parts.HATS.pick_random()
	p.face = "none" if randf() < 0.55 else Parts.FACES.pick_random()
	p.top = Parts.TOPS.pick_random()
	p.item = "none" if randf() < 0.3 else Parts.ITEMS.pick_random()
	var ex := PackedStringArray()
	for e in Parts.EXTRAS:
		if randf() < 0.18:
			ex.append(e)
	p.extras = ex
	var g := PackedStringArray()
	for e in Parts.GORE:
		if randf() < 0.35:
			g.append(e)
	p.gore = g
	p.barefoot = randf() < 0.15
	for key in SWATCHES:
		if key != "eye_color" or randf() < 0.3:
			p.set(key, Color(SWATCHES[key].pick_random()))
	p.name = "%s %s" % [NAME_A.pick_random(), NAME_B.pick_random()]
	_sync_ui()
	_changed()


func _save() -> void:
	var nm := _name.text.strip_edges().to_upper()
	cur.name = nm if nm != "" else "ZOMBIE"
	if cur.id == "":
		cur.id = _free_id(Preset.make_id(cur.name))
	var path: String = CustomChars.DIR + str(cur.id) + ".tres"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(CustomChars.DIR))
	var err := ResourceSaver.save(cur, path)
	if err != OK:
		_flash_msg("COULD NOT SAVE: %s" % error_string(err), Color(1.0, 0.4, 0.35))
		return
	_path = path
	_dirty = false
	CustomChars.reload()
	CustomChars.live[int(cur.kind)] = cur
	_refresh_list()
	_update_info()
	Sfx.play("ui", null, -4.0)
	_flash_msg("SAVED  ·  " + path.trim_prefix("res://"), GOOD)


# שם קובץ פנוי (דמות אחרת עם אותו שם -> butcher_2)
func _free_id(base: String) -> String:
	var id := base
	var n := 2
	while true:
		var other = CustomChars.get_preset_by_id(id)
		if other == null or int(other.kind) == int(cur.kind):
			return id
		id = "%s_%d" % [base, n]
		n += 1
	return id


func _delete() -> void:
	if _path == "":   # עוד לא נשמרה: פשוט זורקים
		_after_delete()
		return
	_ask("DELETE %s?\nThe file %s is removed." % [cur.name, _path.trim_prefix("res://")], func():
		DirAccess.remove_absolute(ProjectSettings.globalize_path(_path))
		CustomChars.reload()
		_flash_msg("DELETED", WARN)
		_after_delete())


func _after_delete() -> void:
	var all := CustomChars.all()
	if all.is_empty():
		_new()
	else:
		_open(all[0])


# לפני שעוזבים דמות עם שינויים שלא נשמרו
func _guard(then: Callable) -> void:
	if not _dirty:
		then.call()
		return
	_ask("%s HAS CHANGES THAT ARE NOT SAVED.\nLeave without saving?" % cur.name, then)


func _try() -> void:
	Game.custom_test = {"preset": cur, "kind": int(cur.kind), "share": 0.4, "level": _try_level, "path": _path, "dirty": _dirty}
	Game.start_practice(_try_level)
	get_tree().change_scene_to_file(GAME_SCENE)


func _back() -> void:
	_guard(func():
		CustomChars.live.clear()
		Game.end_practice()
		get_tree().change_scene_to_file(MENU_SCENE))


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.ctrl_pressed and event.physical_keycode == KEY_S:
		_save()
		get_viewport().set_input_as_handled()


# ============================================================
#  שינויים מהלוח
# ============================================================
func _changed() -> void:
	if _syncing:
		return
	_dirty = true
	_rebuild_t = 0.06   # בונים מחדש בעוד רגע (סרגל שגוררים שולח הרבה שינויים)
	_update_info()


func _pick(key: String, v: String) -> void:
	cur.set(key, v)
	_sync_group(key)
	_changed()


func _toggle_multi(key: String, v: String) -> void:
	var arr: PackedStringArray = cur.get(key)
	if arr.has(v):
		arr.remove_at(arr.find(v))
	else:
		arr.append(v)
	cur.set(key, arr)
	_sync_group(key)
	_changed()


func _on_slider(x: float, key: String) -> void:
	if _syncing:
		return
	cur.set(key, int(round(x)) if typeof(cur.get(key)) == TYPE_INT else x)
	_slider_text(key)
	_changed()


func _on_color(c: Color, key: String) -> void:
	if _syncing:
		return
	cur.set(key, Color(c, 1.0))
	_changed()


func _on_swatch(key: String, c: Color) -> void:
	cur.set(key, c)
	_syncing = true
	_colors[key].color = c
	_syncing = false
	_changed()


func _on_flag(on: bool, key: String) -> void:
	if _syncing:
		return
	cur.set(key, on)
	_changed()


func _on_level(on: bool, lv: int) -> void:
	if _syncing:
		return
	var arr: PackedInt32Array = cur.levels
	if on and not arr.has(lv):
		arr.append(lv)
		arr.sort()
	elif not on and arr.has(lv):
		arr.remove_at(arr.find(lv))
	cur.levels = arr
	_dirty = true
	_update_info()


func _clear_levels() -> void:
	cur.levels = PackedInt32Array()
	_sync_ui()
	_dirty = true
	_update_info()


func _on_name(t: String) -> void:
	if _syncing:
		return
	cur.name = t.strip_edges().to_upper()
	_dirty = true
	_update_info()


func _on_list(i: int) -> void:
	var path := str(_list.get_item_metadata(i))
	if path == _path and path != "":
		return
	if path == "":   # השורה של הדמות החדשה (לא שמורה) - היא כבר פתוחה
		return
	_guard(func():
		var p = ResourceLoader.load(path)
		if p != null:
			_open(p))
	_refresh_list()   # (אם ביטלו: חוזרים לשורה הנוכחית)


func _try_step(d: int) -> void:
	_try_level = clampi(_try_level + d, 1, Game.IMPLEMENTED)
	_try_lbl.text = "LEVEL %d" % _try_level


# ============================================================
#  מעדכנים את הלוח מהדמות
# ============================================================
func _sync_ui() -> void:
	_syncing = true
	_name.text = str(cur.name)
	for key in _groups:
		_sync_group(key)
	for key in _sliders:
		(_sliders[key][0] as Range).set_value_no_signal(float(cur.get(key)))
		_slider_text(key)
	for key in _colors:
		_colors[key].color = cur.get(key)
	for key in _flags:
		_flags[key].set_pressed_no_signal(bool(cur.get(key)))
	for lv in _level_btns:
		_level_btns[lv].set_pressed_no_signal((cur.levels as PackedInt32Array).has(lv))
	if not (cur.levels as PackedInt32Array).is_empty():
		_try_level = int(cur.levels[0])
	_try_lbl.text = "LEVEL %d" % _try_level
	_syncing = false


func _sync_group(key: String) -> void:
	var val = cur.get(key)
	for v in _groups[key]:
		var on: bool = (val as PackedStringArray).has(v) if val is PackedStringArray else str(val) == v
		_groups[key][v].set_pressed_no_signal(on)


func _slider_text(key: String) -> void:
	var s: Array = _sliders[key]
	(s[1] as Label).text = str(s[2]) % cur.get(key)


func _update_info() -> void:
	if _info == null or cur == null:
		return
	var file := _path.trim_prefix("res://") if _path != "" else "NOT SAVED YET"
	var where := "IN NO LEVEL"
	var lv: PackedInt32Array = cur.levels
	if not lv.is_empty():
		var parts := []
		for l in lv:
			parts.append(str(l))
		where = "LEVELS %s  (%d%%)" % [", ".join(parts), int(cur.share)]
	_info.text = "KIND %d   ·   %s   ·   %s%s" % [int(cur.kind), file, where, "   ·   UNSAVED CHANGES" if _dirty else ""]
	_info.add_theme_color_override("font_color", WARN if _dirty else DIM)


func _refresh_list() -> void:
	if _list == null:
		return
	_list.clear()
	var sel := -1
	if _path == "":
		_list.add_item("NEW: %s  (NOT SAVED)" % str(cur.name))
		_list.set_item_metadata(0, "")
		sel = 0
	for p in CustomChars.all():
		var i := _list.item_count
		_list.add_item("%d  %s" % [int(p.kind), str(p.name)])
		_list.set_item_metadata(i, p.resource_path)
		if p.resource_path == _path and _path != "":
			sel = i
	if sel >= 0:
		_list.select(sel)


func _flash_msg(t: String, col := TEXT) -> void:
	_toast.text = t
	_toast.add_theme_color_override("font_color", col)
	_toast.modulate.a = 1.0
	var tw := create_tween()
	tw.tween_interval(1.6)
	tw.tween_property(_toast, "modulate:a", 0.0, 0.6)


func _ask(text: String, then: Callable) -> void:
	_confirm.dialog_text = text
	for c in _confirm.confirmed.get_connections():
		_confirm.confirmed.disconnect(c.callable)
	_confirm.confirmed.connect(then, CONNECT_ONE_SHOT)
	_confirm.popup_centered()


# ============================================================
#  בניית הלוח
# ============================================================
func _sb(bg: Color, border: Color, radius := 6, bw := 1) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(bw)
	s.set_corner_radius_all(radius)
	s.content_margin_left = 8.0
	s.content_margin_right = 8.0
	s.content_margin_top = 3.0
	s.content_margin_bottom = 3.0
	return s


func _make_theme() -> Theme:
	var th := Theme.new()
	th.default_font = FONT
	th.default_font_size = 17
	var n := _sb(Color(0.13, 0.11, 0.11, 0.96), Color(1, 1, 1, 0.12))
	var h := _sb(Color(0.22, 0.16, 0.15, 0.98), Color(1, 1, 1, 0.35))
	var p := _sb(Color(0.6, 0.07, 0.1, 1.0), Color(1.0, 0.45, 0.45, 0.9))
	for t in ["Button", "OptionButton", "ColorPickerButton"]:
		th.set_stylebox("normal", t, n)
		th.set_stylebox("hover", t, h)
		th.set_stylebox("pressed", t, p)
		th.set_stylebox("hover_pressed", t, p)
		th.set_stylebox("focus", t, StyleBoxEmpty.new())
		th.set_stylebox("disabled", t, _sb(Color(0.1, 0.1, 0.1, 0.6), Color(1, 1, 1, 0.05)))
		th.set_color("font_color", t, TEXT)
		th.set_color("font_hover_color", t, Color.WHITE)
		th.set_color("font_pressed_color", t, Color.WHITE)
		th.set_color("font_hover_pressed_color", t, Color.WHITE)
		th.set_color("font_focus_color", t, TEXT)
	th.set_stylebox("normal", "LineEdit", _sb(Color(0.05, 0.04, 0.04, 0.96), Color(1, 1, 1, 0.25)))
	th.set_stylebox("focus", "LineEdit", _sb(Color(0.05, 0.04, 0.04, 0.96), Color(0.95, 0.35, 0.35, 0.9)))
	th.set_color("font_color", "LineEdit", Color.WHITE)
	th.set_stylebox("panel", "TabContainer", _sb(PANEL_BG, Color(1, 1, 1, 0.1), 8))
	th.set_stylebox("tab_selected", "TabContainer", _sb(Color(0.6, 0.07, 0.1, 1.0), Color(1.0, 0.45, 0.45, 0.9), 5))
	th.set_stylebox("tab_unselected", "TabContainer", _sb(Color(0.13, 0.11, 0.11, 0.96), Color(1, 1, 1, 0.1), 5))
	th.set_stylebox("tab_hovered", "TabContainer", _sb(Color(0.22, 0.16, 0.15, 0.98), Color(1, 1, 1, 0.35), 5))
	th.set_stylebox("tab_focus", "TabContainer", StyleBoxEmpty.new())
	th.set_font_size("font_size", "TabContainer", 16)
	th.set_color("font_selected_color", "TabContainer", Color.WHITE)
	th.set_color("font_unselected_color", "TabContainer", TEXT)
	th.set_color("font_hovered_color", "TabContainer", Color.WHITE)
	th.set_color("font_color", "Label", TEXT)
	th.set_color("font_shadow_color", "Label", Color(0, 0, 0, 0.75))
	th.set_constant("shadow_offset_x", "Label", 1)
	th.set_constant("shadow_offset_y", "Label", 1)
	th.set_stylebox("panel", "PopupMenu", _sb(Color(0.08, 0.07, 0.07, 0.98), Color(1, 1, 1, 0.25)))
	th.set_stylebox("hover", "PopupMenu", _sb(Color(0.6, 0.07, 0.1, 1.0), Color(0, 0, 0, 0), 4, 0))
	th.set_color("font_color", "PopupMenu", TEXT)
	th.set_color("font_hover_color", "PopupMenu", Color.WHITE)
	th.set_font_size("font_size", "PopupMenu", 17)
	th.set_stylebox("slider", "HSlider", _sb(Color(0.2, 0.18, 0.18, 1.0), Color(0, 0, 0, 0), 3, 0))
	th.set_stylebox("grabber_area", "HSlider", _sb(Color(0.65, 0.12, 0.13, 1.0), Color(0, 0, 0, 0), 3, 0))
	th.set_stylebox("grabber_area_highlight", "HSlider", _sb(Color(0.85, 0.2, 0.2, 1.0), Color(0, 0, 0, 0), 3, 0))
	th.set_stylebox("panel", "TooltipPanel", _sb(Color(0.05, 0.04, 0.04, 0.96), Color(1, 1, 1, 0.3)))
	th.set_color("font_color", "TooltipLabel", TEXT)
	th.set_font_size("font_size", "TooltipLabel", 16)
	th.set_stylebox("panel", "AcceptDialog", _sb(Color(0.08, 0.07, 0.07, 0.98), Color(1, 1, 1, 0.25), 8))
	return th


func _build_ui() -> void:
	var ui := CanvasLayer.new()
	ui.layer = 3
	add_child(ui)
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.theme = _make_theme()
	ui.add_child(root)
	_ui_root = root

	# ---- למעלה: הדמויות השמורות + פעולות ----
	var top := _panel(root, Rect2(8, 8, VIEW_W - 16, 84))
	var row1 := HBoxContainer.new()
	row1.position = Vector2(10, 8)
	row1.size = Vector2(VIEW_W - 36, 36)
	row1.add_theme_constant_override("separation", 6)
	top.add_child(row1)
	_list = OptionButton.new()
	_list.custom_minimum_size = Vector2(250, 34)
	_list.clip_text = true
	_list.focus_mode = Control.FOCUS_NONE
	_list.tooltip_text = "Your saved characters (characters/saved/)"
	_list.item_selected.connect(_on_list)
	row1.add_child(_list)
	_button(row1, "NEW", func(): _guard(_new), 0.0, "Start a new character")
	_button(row1, "COPY", _copy, 0.0, "A new character that starts as a copy of this one")
	_button(row1, "RANDOM", _random, 0.0, "Random parts and colors (keeps the stats and levels)")
	var save := _button(row1, "SAVE", _save, 90.0, "Write characters/saved/<name>.tres  (Ctrl+S)")
	save.add_theme_stylebox_override("normal", _sb(Color(0.12, 0.3, 0.14, 0.98), Color(0.5, 1.0, 0.5, 0.5)))
	save.add_theme_stylebox_override("hover", _sb(Color(0.16, 0.42, 0.18, 1.0), Color(0.6, 1.0, 0.6, 0.8)))
	_button(row1, "DELETE", _delete, 0.0, "Delete this character's file")
	var row2 := HBoxContainer.new()
	row2.position = Vector2(10, 48)
	row2.size = Vector2(VIEW_W - 36, 30)
	row2.add_theme_constant_override("separation", 10)
	top.add_child(row2)
	var nl := Label.new()
	nl.text = "NAME"
	row2.add_child(nl)
	_name = LineEdit.new()
	_name.custom_minimum_size = Vector2(230, 30)
	_name.max_length = 28
	_name.placeholder_text = "NAME"
	_name.tooltip_text = "Shown in the game (boss bar, kill text)"
	_name.text_changed.connect(_on_name)
	row2.add_child(_name)
	_info = Label.new()
	_info.add_theme_font_size_override("font_size", 15)
	_info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_info.clip_text = true
	_info.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row2.add_child(_info)

	# ---- למטה: מה הוא עושה + פגיעות ומיתות ----
	var bot := _panel(root, Rect2(8, 598, VIEW_W - 16, 114))
	var m := HBoxContainer.new()
	m.position = Vector2(10, 8)
	m.add_theme_constant_override("separation", 5)
	bot.add_child(m)
	_tag(m, "MOVE")
	for spec in [["stand", "STAND"], ["walk", "WALK"], ["run", "RUN"], ["attack", "ATTACK"]]:
		var b := _button(m, spec[1], _set_mode.bind(spec[0]), 74.0, {"stand": "Stands in place", "walk": "Walks at his walk speed",
			"run": "Runs at his run speed", "attack": "Goes for the hero and bites (the hero can't die here)"}[spec[0]])
		b.toggle_mode = true
		_mode_btns[spec[0]] = b
	_button(m, "TURN", _turn, 62.0, "Turn around")
	_crowd_btn = _button(m, "CROWD", _toggle_crowd, 72.0, "6 more of him, each a bit different (VARIETY)")
	_crowd_btn.toggle_mode = true
	_night_btn = _button(m, "NIGHT", _toggle_night, 66.0, "How he looks in a dark level")
	_night_btn.toggle_mode = true
	_button(m, "NEW ONE", func(): _respawn(true), 80.0, "A fresh one in front of the hero")
	var h := HBoxContainer.new()
	h.position = Vector2(10, 46)
	h.add_theme_constant_override("separation", 4)
	bot.add_child(h)
	_tag(h, "SHOOT")
	_button(h, "HEAD", _hit.bind("head"), 0.0, "A shot to the head that doesn't kill (see the reaction)")
	_button(h, "BODY", _hit.bind("body"), 0.0, "A shot to the belly that doesn't kill")
	_button(h, "LEGS", _hit.bind("legs"), 0.0, "A shot to the leg that doesn't kill")
	_tag(h, "  KILL")
	_button(h, "SHOT", _kill.bind("shot"), 0.0, "Normal death (sometimes a special one, like in the game)")
	_button(h, "HEADSHOT", _kill.bind("headshot"), 0.0, "Killed by a headshot")
	_button(h, "NO HEAD", _kill.bind("nohead"), 0.0, "The head flies off and the body walks on")
	_button(h, "TORN", _kill.bind("tear"), 0.0, "Torn in half")
	_button(h, "EXPLODE", _kill.bind("burst"), 0.0, "Bursts into chunks")
	_button(h, "BURN", _kill.bind("burn"), 0.0, "Burned to the bones")
	_button(h, "LEGS OFF", _kill.bind("crawl"), 0.0, "Loses his legs and crawls")
	for b in h.get_children():
		if b is Button:
			b.add_theme_font_size_override("font_size", 15)

	# ---- מימין: הלשוניות ----
	var tabs := TabContainer.new()
	tabs.position = Vector2(VIEW_W + 4, 8)
	tabs.size = Vector2(1280 - VIEW_W - 12, 628)
	tabs.focus_mode = Control.FOCUS_NONE
	root.add_child(tabs)
	_tab_body(_tab(tabs, "BODY"))
	_tab_head(_tab(tabs, "HEAD"))
	_tab_clothes(_tab(tabs, "CLOTHES"))
	_tab_colors(_tab(tabs, "COLORS"))
	_tab_gore(_tab(tabs, "GORE"))
	_tab_stats(_tab(tabs, "STATS"))
	_tab_levels(_tab(tabs, "LEVELS"))

	# ---- מימין למטה: לנסות בשלב / חזרה ----
	var br := HBoxContainer.new()
	br.position = Vector2(VIEW_W + 4, 644)
	br.size = Vector2(1280 - VIEW_W - 12, 68)
	br.add_theme_constant_override("separation", 6)
	root.add_child(br)
	var tv := VBoxContainer.new()
	tv.add_theme_constant_override("separation", 2)
	br.add_child(tv)
	var try := _button(tv, "TRY IN LEVEL", _try, 190.0, "Play a level with him in it (practice, nothing is saved).\nESC > BACK TO MAKER brings you back here.")
	try.custom_minimum_size = Vector2(190, 36)
	try.add_theme_font_size_override("font_size", 20)
	try.add_theme_stylebox_override("normal", _sb(Color(0.55, 0.07, 0.1, 1.0), Color(1.0, 0.45, 0.45, 0.7)))
	var ts := HBoxContainer.new()
	ts.add_theme_constant_override("separation", 4)
	tv.add_child(ts)
	_button(ts, "<", _try_step.bind(-1), 40.0)
	_try_lbl = Label.new()
	_try_lbl.custom_minimum_size = Vector2(98, 26)
	_try_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ts.add_child(_try_lbl)
	_button(ts, ">", _try_step.bind(1), 40.0)
	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	br.add_child(sp)
	var back := _button(br, "BACK TO MENU", _back, 150.0)
	back.custom_minimum_size = Vector2(150, 66)

	# הודעה קצרה (נשמר / נמחק)
	_toast = Label.new()
	_toast.position = Vector2(8, 98)
	_toast.size = Vector2(VIEW_W - 16, 30)
	_toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast.add_theme_font_size_override("font_size", 22)
	_toast.modulate.a = 0.0
	_toast.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_toast)
	_confirm = ConfirmationDialog.new()
	_confirm.title = "CHARACTER MAKER"
	_confirm.ok_button_text = "YES"
	_confirm.cancel_button_text = "NO"
	root.add_child(_confirm)
	_set_mode("stand")


func _panel(parent: Control, r: Rect2) -> Panel:
	var p := Panel.new()
	p.position = r.position
	p.size = r.size
	p.add_theme_stylebox_override("panel", _sb(PANEL_BG, Color(1, 1, 1, 0.08), 8))
	parent.add_child(p)
	return p


func _tag(parent: Control, t: String) -> void:
	var l := Label.new()
	l.text = t
	l.custom_minimum_size = Vector2(0, 32)
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.add_theme_color_override("font_color", Color(1.0, 0.45, 0.4))
	l.add_theme_font_size_override("font_size", 16)
	parent.add_child(l)


func _button(parent: Control, t: String, cb: Callable, w := 0.0, tip := "") -> Button:
	var b := Button.new()
	b.text = t
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(w, 32)
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	if tip != "":
		b.tooltip_text = tip
	b.pressed.connect(cb)
	parent.add_child(b)
	return b


# לשונית: גלילה + עמודה
func _tab(tabs: TabContainer, title: String) -> VBoxContainer:
	var sc := ScrollContainer.new()
	sc.name = title
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	tabs.add_child(sc)
	var mc := MarginContainer.new()
	mc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for side in ["left", "right", "top", "bottom"]:
		mc.add_theme_constant_override("margin_" + side, 8)
	sc.add_child(mc)
	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_theme_constant_override("separation", 6)
	mc.add_child(v)
	return v


func _section(parent: Control, t: String, hint := "") -> void:
	var l := Label.new()
	l.text = t
	l.add_theme_color_override("font_color", Color(1.0, 0.5, 0.42))
	l.add_theme_font_size_override("font_size", 19)
	parent.add_child(l)
	if hint != "":
		var hl := Label.new()
		hl.text = hint
		hl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		hl.add_theme_color_override("font_color", DIM)
		hl.add_theme_font_size_override("font_size", 14)
		parent.add_child(hl)


func _choices(parent: Control, title: String, key: String, values: Array, cols := 3, hint := "") -> void:
	_section(parent, title, hint)
	var g := GridContainer.new()
	g.columns = cols
	g.add_theme_constant_override("h_separation", 4)
	g.add_theme_constant_override("v_separation", 4)
	parent.add_child(g)
	var btns := {}
	for v in values:
		var b := Button.new()
		b.text = Parts.label(v)
		b.toggle_mode = true
		b.focus_mode = Control.FOCUS_NONE
		b.clip_text = true
		b.custom_minimum_size = Vector2(0, 30)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		b.add_theme_font_size_override("font_size", 15)
		if key == "extras" or key == "gore":
			b.pressed.connect(_toggle_multi.bind(key, v))
		else:
			b.pressed.connect(_pick.bind(key, v))
		g.add_child(b)
		btns[v] = b
	_groups[key] = btns


func _slider(parent: Control, title: String, key: String, mn: float, mx: float, step: float, fmt := "%.2f", tip := "") -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	parent.add_child(row)
	var l := Label.new()
	l.text = title
	l.custom_minimum_size = Vector2(124, 0)
	l.add_theme_font_size_override("font_size", 16)
	row.add_child(l)
	var s := HSlider.new()
	s.min_value = mn
	s.max_value = mx
	s.step = step
	s.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	s.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	s.custom_minimum_size = Vector2(0, 24)
	s.focus_mode = Control.FOCUS_NONE
	if tip != "":
		s.tooltip_text = tip
		l.tooltip_text = tip
		l.mouse_filter = Control.MOUSE_FILTER_PASS
	s.value_changed.connect(_on_slider.bind(key))
	row.add_child(s)
	var v := Label.new()
	v.custom_minimum_size = Vector2(56, 0)
	v.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	v.add_theme_font_size_override("font_size", 16)
	row.add_child(v)
	_sliders[key] = [s, v, fmt]


func _flag(parent: Control, title: String, key: String, tip := "") -> void:
	var b := Button.new()
	b.text = title
	b.toggle_mode = true
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(0, 30)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	if tip != "":
		b.tooltip_text = tip
	b.toggled.connect(_on_flag.bind(key))
	parent.add_child(b)
	_flags[key] = b


func _tab_body(v: VBoxContainer) -> void:
	_choices(v, "BUILD", "build", Parts.BUILDS, 3, "Normal like a walker, skinny like a runner (long steps, waving arms), big like a brute.")
	_section(v, "SIZE")
	_slider(v, "HEIGHT", "height", 0.75, 1.5, 0.01, "%.2f")
	_slider(v, "WIDTH", "width", 0.75, 1.5, 0.01, "%.2f")
	_slider(v, "HEAD SIZE", "head_size", 0.8, 1.6, 0.01, "%.2f")
	_slider(v, "HUNCH", "hunch", 0.0, 10.0, 0.5, "%.1f", "How far he leans forward")
	_section(v, "FEET AND LOOK")
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	v.add_child(row)
	_flag(row, "BAREFOOT", "barefoot", "No shoes")
	_flag(row, "VARIETY", "variety", "In the game every one of him is a bit different (skin, shirt and hair shade)")
	_choices(v, "IN HIS HAND (LOOKS ONLY - HE STILL BITES)", "item", Parts.ITEMS, 3)


func _tab_head(v: VBoxContainer) -> void:
	_choices(v, "HAIR", "hair", Parts.HAIRS, 4)
	_choices(v, "HAT", "hat", Parts.HATS, 3)
	_choices(v, "FACE", "face", Parts.FACES, 3)


func _tab_clothes(v: VBoxContainer) -> void:
	_choices(v, "TOP", "top", Parts.TOPS, 3, "SHIRT / SUIT / COAT / HOODIE / PRISON have sleeves. The shirt color is in COLORS.")
	_choices(v, "EXTRAS (PICK ANY)", "extras", Parts.EXTRAS, 3, "Their color is EXTRAS in COLORS.")


func _tab_gore(v: VBoxContainer) -> void:
	_choices(v, "ON HIS BODY (PICK ANY)", "gore", Parts.GORE, 2,
		"How rotten he looks. The deaths (torn, no head, burned...) always work - try them with the KILL buttons.")


func _tab_colors(v: VBoxContainer) -> void:
	for spec in COLOR_NAMES:
		var key: String = spec[0]
		_section(v, spec[1])
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 3)
		v.add_child(row)
		var cp := ColorPickerButton.new()
		cp.edit_alpha = false
		cp.custom_minimum_size = Vector2(64, 28)
		cp.focus_mode = Control.FOCUS_NONE
		cp.tooltip_text = "Any color"
		cp.color_changed.connect(_on_color.bind(key))
		row.add_child(cp)
		_colors[key] = cp
		for hx in SWATCHES[key]:
			var c := Color(hx)
			var b := Button.new()
			b.custom_minimum_size = Vector2(28, 28)
			b.focus_mode = Control.FOCUS_NONE
			b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
			b.add_theme_stylebox_override("normal", _sb(c, Color(0, 0, 0, 0.6), 4))
			b.add_theme_stylebox_override("hover", _sb(c.lightened(0.15), Color(1, 1, 1, 0.9), 4, 2))
			b.add_theme_stylebox_override("pressed", _sb(c, Color(1, 1, 1, 1), 4, 2))
			b.pressed.connect(_on_swatch.bind(key, c))
			row.add_child(b)


func _tab_stats(v: VBoxContainer) -> void:
	_section(v, "HOW HE PLAYS", "A normal walker: 30 HP, walk 45, run 95, bites for 1 every 0.8 s.")
	_slider(v, "HP", "hp", 5, 400, 5, "%d", "A normal headshot does 30")
	_slider(v, "WALK SPEED", "walk_speed", 10, 120, 1, "%d")
	_slider(v, "RUN SPEED", "run_speed", 30, 260, 1, "%d", "Speed when he chases you")
	_slider(v, "BITE DAMAGE", "damage", 1, 4, 1, "%d", "Hearts per bite")
	_slider(v, "BITE EVERY", "bite_delay", 0.3, 2.0, 0.05, "%.2f s")
	_slider(v, "DUCKS", "duck", 0.0, 0.9, 0.05, "%.2f", "Chance to duck when you shoot at him")
	_slider(v, "TAKES COVER", "cover", 0.0, 0.9, 0.05, "%.2f", "Chance to run for cover when hit")
	_slider(v, "SEES YOU FROM", "notice", 150, 900, 10, "%d", "Distance where he starts chasing you")
	_slider(v, "POINTS", "points", 50, 2000, 10, "%d", "Score for killing him")
	_slider(v, "VOICE", "voice", 0.6, 1.5, 0.05, "%.2f", "Low = deep voice")
	var row := HBoxContainer.new()
	v.add_child(row)
	_flag(row, "BOSS (HEALTH BAR)", "boss", "Shows a boss health bar and gets extra HP in later levels")


func _tab_levels(v: VBoxContainer) -> void:
	_section(v, "WHERE HE SHOWS UP", "Pick levels. In those levels about SHARE % of the zombies are him. No level = he is only in the maker.")
	var g := GridContainer.new()
	g.columns = 9
	g.add_theme_constant_override("h_separation", 3)
	g.add_theme_constant_override("v_separation", 3)
	v.add_child(g)
	for lv in range(1, Game.IMPLEMENTED + 1):
		var b := Button.new()
		b.text = str(lv)
		b.toggle_mode = true
		b.focus_mode = Control.FOCUS_NONE
		b.custom_minimum_size = Vector2(46, 28)
		b.add_theme_font_size_override("font_size", 15)
		b.toggled.connect(_on_level.bind(lv))
		g.add_child(b)
		_level_btns[lv] = b
	_slider(v, "SHARE %", "share", 1, 50, 1, "%d%%", "About this % of the zombies in the chosen levels")
	var row := HBoxContainer.new()
	v.add_child(row)
	_button(row, "NO LEVELS", _clear_levels, 0.0, "Take him out of all levels")
