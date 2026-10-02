extends Node2D
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
@export var end_margin := 300.0
## מרחק מינימלי / מקסימלי בין מבנים
@export var gap_min := 260.0
@export var gap_max := 560.0

@export_group("Obstacles")
## איזה חלק מגובה הקפיצה של הדמות מותר שיהיה גובה מכשול (0.7 = 70%).
## כך הדמות תמיד מסוגלת לעבור כל לבנה. אם תגדיל - הלבנות יהיו גבוהות יותר
@export_range(0.3, 0.95) var obstacle_safety := 0.7

@export_group("Zombies")
## כמה זומבים בממוצע בכל מסך
@export var zombies_per_screen := 1.6
## הסיכוי שזומבי יופיע בקבוצה של 2-3
@export_range(0.0, 1.0) var zombie_cluster_chance := 0.25

const UNIT := 16.0   # גובה "שורת לבנים"
const BRICK_COLORS := [Color("9a4f3a"), Color("8a5a40"), Color("7a4a4a"), Color("a0603f")]

var level_w := 10240.0
var max_h := 48.0
var _rects: Array[Rect2] = []


func _ready() -> void:
	var vp := get_viewport_rect().size
	level_w = vp.x * float(maxi(level_screens, 8))

	# רקעים (פרלקסה) ועלים
	var bg_layer := CanvasLayer.new()
	bg_layer.layer = -10
	add_child(bg_layer)
	bg_layer.add_child(BackgroundScript.new())
	var leaf_layer := CanvasLayer.new()
	leaf_layer.layer = -5
	add_child(leaf_layer)
	leaf_layer.add_child(LeavesScript.new())

	# ריצפה לכל אורך הרמה
	var floor_y := vp.y - floor_thickness
	_make_brick(Vector2(0, floor_y), Vector2(level_w, floor_thickness), false, true, Color("6b4a35"), false)

	# שחקן (נוצר קודם כדי לחשב מה גובה הלבנה המקסימלי שהוא מסוגל לעבור)
	var player = PlayerScript.new()
	var apex: float = (player.jump_velocity * player.jump_velocity) / (2.0 * player.gravity)
	max_h = maxf(floorf(apex * obstacle_safety / UNIT) * UNIT, 2.0 * UNIT)

	var rng := RandomNumberGenerator.new()
	if level_seed == 0:
		rng.randomize()
	else:
		rng.seed = level_seed
	_generate_level(rng, floor_y)
	_spawn_zombies(rng, floor_y)

	player.position = Vector2(vp.x * 0.12, floor_y)   # (0,0) של השחקן = כפות הרגליים
	add_child(player)
	player.world_w = level_w

	# מצלמה שעוקבת אחרי השחקן ונעצרת בקצוות הרמה
	var cam = CameraScript.new()
	cam.limit_left = 0
	cam.limit_right = int(level_w)
	cam.limit_top = 0
	cam.limit_bottom = int(vp.y)
	cam.position_smoothing_enabled = true
	cam.position_smoothing_speed = 8.0
	player.add_child(cam)
	cam.make_current()
	cam.reset_smoothing()

	# טקסט עזרה + בר חיים
	var hud := CanvasLayer.new()
	add_child(hud)
	var label := Label.new()
	label.text = "A/D move   SHIFT run   W/SPACE jump   S/CTRL crouch   MOUSE aim   LMB fire   T gun/grenade   K die   R restart"
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


# ============================================================
#  יצירת רמה אקראית
#  כל מכשול בגובה של עד max_h כדי שהדמות תמיד תוכל לקפוץ מעליו.
# ============================================================
func _generate_level(rng: RandomNumberGenerator, floor_y: float) -> void:
	var x := safe_zone
	while x < level_w - end_margin:
		var used := 0.0
		match rng.randi_range(0, 3):
			0: used = _gen_block(rng, x, floor_y)
			1: used = _gen_low_wall(rng, x, floor_y)
			2: used = _gen_pyramid(rng, x, floor_y)
			3: used = _gen_crates(rng, x, floor_y)
		x += used + rng.randf_range(gap_min, gap_max)


# לבנה בודדת / קופסה
func _gen_block(rng: RandomNumberGenerator, x: float, floor_y: float) -> float:
	var ws := [32.0, 48.0, 64.0]
	var w: float = ws[rng.randi() % ws.size()]
	var rows := rng.randi_range(2, maxi(2, int(max_h / UNIT)))
	_place(rng, x, floor_y, w, float(rows) * UNIT)
	return w


# קיר נמוך וארוך
func _gen_low_wall(rng: RandomNumberGenerator, x: float, floor_y: float) -> float:
	var w := float(rng.randi_range(3, 6)) * 32.0
	var rows := rng.randi_range(1, mini(2, maxi(1, int(max_h / UNIT))))
	_place(rng, x, floor_y, w, float(rows) * UNIT)
	return w


# פירמידה: מדרגות עולות ויורדות (כל מדרגה נמוכה מספיק כדי לקפוץ עליה)
func _gen_pyramid(rng: RandomNumberGenerator, x: float, floor_y: float) -> float:
	var n := rng.randi_range(2, 3)
	var step := minf(2.0 * UNIT, max_h)
	var step_w := 48.0
	var total := float(2 * n - 1)
	for i in 2 * n - 1:
		var level := mini(i, 2 * n - 2 - i) + 1
		_place(rng, x + float(i) * step_w, floor_y, step_w, float(level) * step)
	return total * step_w


# כמה קופסאות עם רווחים ביניהן
func _gen_crates(rng: RandomNumberGenerator, x: float, floor_y: float) -> float:
	var n := rng.randi_range(2, 4)
	var cx := x
	for i in n:
		var rows := rng.randi_range(2, maxi(2, mini(3, int(max_h / UNIT))))
		_place(rng, cx, floor_y, 32.0, float(rows) * UNIT)
		cx += 32.0 + rng.randf_range(24.0, 72.0)
	return cx - x


func _place(rng: RandomNumberGenerator, x: float, floor_y: float, w: float, h: float) -> void:
	h = minf(h, max_h * 2.5)   # הגנה: גם מדרגות לא יעלו על הגובה הכולל
	var col: Color = BRICK_COLORS[rng.randi() % BRICK_COLORS.size()]
	_make_brick(Vector2(x, floor_y - h), Vector2(w, h), true, false, col, true)
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
		if rng.randf() < zombie_cluster_chance:
			group = rng.randi_range(2, 3)
		for g in group:
			var gx := zx + float(g) * rng.randf_range(34.0, 60.0)
			if gx < level_w - 80.0 and not _near_brick(gx):
				_spawn_zombie(gx, floor_y)
				spawned += 1


func _near_brick(x: float) -> bool:
	for r in _rects:
		if x > r.position.x - 40.0 and x < r.end.x + 40.0:
			return true
	return false


func _spawn_zombie(x: float, floor_y: float) -> void:
	var z = ZombieScene.instantiate()
	z.position = Vector2(x, floor_y)   # (0,0) של הזומבי = כפות הרגליים
	add_child(z)
	z.world_w = level_w


func _make_brick(pos: Vector2, sz: Vector2, bricks := true, grass := false, col := Color("9a4f3a"), is_breakable := true) -> void:
	var b = BrickScene.instantiate()
	b.position = pos
	b.size = sz
	b.show_bricks = bricks
	b.grass = grass
	b.color = col
	b.breakable = is_breakable
	add_child(b)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_R:
		get_tree().reload_current_scene()
