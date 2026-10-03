extends Node2D
# ============================================================
#  תפריט ראשי. ברקע: העיר ההרוסה זזה לאט, הדמות הראשית עומדת ונושמת,
#  וזומבים מסתובבים ברחוב. בצד שמאל: כותרת, כפתור PLAY, רמת קושי ו-QUIT.
# ============================================================

const BackgroundScript := preload("res://background.gd")
const LeavesScript := preload("res://leaves.gd")
const FogScript := preload("res://fog.gd")
const BrickScene := preload("res://brick.tscn")
const PlayerScript := preload("res://player.gd")
const ZombieScene := preload("res://zombie.tscn")
const PropScript := preload("res://prop.gd")
const StreetPropScript := preload("res://street_prop.gd")
const RoadDecorScript := preload("res://road_decor.gd")
const ButtonScript := preload("res://menu_button.gd")

const GAME_SCENE := "res://main.tscn"
const ZOOM := 2.0
const FLOOR_Y := 300.0

var _bg: Node2D
var _scroll := 0.0
var _diff_buttons: Array = []
var _desc: Caption
var _fade: ColorRect
var _leaving := false
var _ui: CanvasLayer
var _root_ctrl: Control
var _trophy_layer: CanvasLayer


func _desc_text() -> String:
	return "%s      BEST: %d" % [Settings.preset().desc, Game.high_scores[Settings.difficulty]]


# חדר הגביעים: גביעים שנפתחו בזהב, נעולים כצללית כהה
func _show_trophies() -> void:
	if _trophy_layer != null:
		return
	_trophy_layer = CanvasLayer.new()
	_trophy_layer.layer = 4
	add_child(_trophy_layer)
	var room := TrophyRoom.new()
	_trophy_layer.add_child(room)
	var ctrl := Control.new()
	ctrl.set_anchors_preset(Control.PRESET_FULL_RECT)
	ctrl.mouse_filter = Control.MOUSE_FILTER_STOP
	_trophy_layer.add_child(ctrl)
	var back := _button(ctrl, "BACK", Vector2(540, 600), Vector2(200, 54), 28, 0.1)
	back.pressed.connect(func():
		_trophy_layer.queue_free()
		_trophy_layer = null)
	back.call_deferred("grab_focus")


func _ready() -> void:
	get_tree().paused = false
	var vp := get_viewport_rect().size
	var world_w := vp.x / ZOOM

	# רקע העיר
	var bg_layer := CanvasLayer.new()
	bg_layer.layer = -10
	add_child(bg_layer)
	_bg = BackgroundScript.new()
	_bg.level_w = 4000.0
	_bg.scroll_override = 0.0
	bg_layer.add_child(_bg)
	var leaf_layer := CanvasLayer.new()
	leaf_layer.layer = -5
	add_child(leaf_layer)
	leaf_layer.add_child(LeavesScript.new())

	# הרחוב: כביש, קישוטים, מכונית בוערת
	var road = BrickScene.instantiate()
	road.position = Vector2(-50.0, FLOOR_Y)
	road.size = Vector2(world_w + 100.0, 80.0)
	road.style = 3
	road.breakable = false
	add_child(road)
	var decor = RoadDecorScript.new()
	decor.position = Vector2(-50.0, 0.0)
	decor.width = world_w + 100.0
	decor.floor_y = FLOOR_Y
	decor.seed_value = 3
	add_child(decor)
	for spec in [[0, 560.0], [3, 395.0]]:   # רמזור + פח בוער
		var sp = StreetPropScript.new()
		sp.kind = spec[0]
		sp.position = Vector2(spec[1], FLOOR_Y)
		add_child(sp)
	var car = PropScript.new()
	car.kind = PropScript.CAR
	car.wrecked = true
	car.color = Color("3d5670")
	car.position = Vector2(220.0, FLOOR_Y)
	add_child(car)

	# הדמות הראשית (לא נשלטת) - עומדת, נושמת ומכוונת לזומבים
	var hero = PlayerScript.new()
	hero.controllable = false
	hero.position = Vector2(world_w * 0.78, FLOOR_Y)
	add_child(hero)
	hero.world_w = world_w

	# זומבים שמסתובבים ברחוב
	for i in 3:
		var z = ZombieScene.instantiate()
		z.kind = i
		z.position = Vector2(40.0 + float(i) * 70.0, FLOOR_Y)
		z.chase_range = 0.0
		add_child(z)
		z.world_w = world_w * 0.62

	var cam := Camera2D.new()
	cam.zoom = Vector2(ZOOM, ZOOM)
	cam.position = Vector2(world_w / 2.0, FLOOR_Y + 40.0 - vp.y / ZOOM / 2.0)
	add_child(cam)
	cam.make_current()

	var fog_layer := CanvasLayer.new()
	fog_layer.layer = 1
	add_child(fog_layer)
	var fog = FogScript.new()
	fog.y_screen = (FLOOR_Y - cam.position.y) * ZOOM + vp.y / 2.0 - 6.0
	fog_layer.add_child(fog)

	_build_ui(vp)


func _build_ui(vp: Vector2) -> void:
	var ui := CanvasLayer.new()
	ui.layer = 3
	add_child(ui)
	var shade := Shade.new()   # הצללה כהה משמאל, כדי שהכפתורים יבלטו
	ui.add_child(shade)
	var title := Title.new()
	title.position = Vector2(66.0, 150.0)
	ui.add_child(title)

	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(root)

	var play := _button(root, "PLAY", Vector2(70, 250), Vector2(310, 66), 40, 0.15)
	play.pressed.connect(_start_game)

	var lv2 := _button(root, "LEVEL 2", Vector2(394, 262), Vector2(130, 44), 20, 0.25)   # בדיקה מהירה של השלב השני
	lv2.accent = Color("3a8acc")
	lv2.pressed.connect(_start_game.bind(2))

	var lbl := Caption.new()
	lbl.text = "DIFFICULTY"
	lbl.position = Vector2(72, 360)
	ui.add_child(lbl)
	for i in 3:
		var b := _button(root, Settings.NAMES[i], Vector2(70 + i * 126, 372), Vector2(114, 46), 22, 0.3 + 0.08 * i)
		b.accent = Settings.COLORS[i]
		b.selected = i == Settings.difficulty
		b.pressed.connect(_set_difficulty.bind(i))
		_diff_buttons.append(b)
	_desc = Caption.new()
	_desc.size = 17
	_desc.color = Color(0.85, 0.82, 0.8)
	_desc.position = Vector2(72, 446)
	_desc.text = _desc_text()
	ui.add_child(_desc)
	_ui = ui
	_root_ctrl = root

	var tro := _button(root, "TROPHIES", Vector2(70, 482), Vector2(250, 50), 26, 0.5)
	tro.accent = Color("d8a033")
	tro.pressed.connect(_show_trophies)

	var quit := _button(root, "QUIT", Vector2(70, 546), Vector2(250, 50), 28, 0.6)
	quit.accent = Color("5a5a62")
	quit.pressed.connect(_quit)

	var hint := Caption.new()
	hint.size = 15
	hint.color = Color(1, 1, 1, 0.55)
	hint.text = "A/D move   W jump   S crouch   MOUSE aim   LMB fire   1-4 weapons   T grenade   E grapple   ESC pause"
	hint.position = Vector2(20, vp.y - 18.0)
	ui.add_child(hint)

	play.call_deferred("grab_focus")

	# מסך שחור שנעלם בכניסה (ומופיע ביציאה)
	_fade = ColorRect.new()
	_fade.color = Color(0, 0, 0, 1)
	_fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(_fade)
	create_tween().tween_property(_fade, "color:a", 0.0, 0.8)


func _button(parent: Control, text: String, pos: Vector2, sz: Vector2, fs: int, delay: float) -> Control:
	var b := ButtonScript.new()
	b.text = text
	b.font_size = fs
	b.position = pos
	b.size = sz
	b.appear_delay = delay
	parent.add_child(b)
	return b


func _set_difficulty(i: int) -> void:
	Settings.difficulty = i
	for j in _diff_buttons.size():
		_diff_buttons[j].selected = j == i
	_desc.text = _desc_text()
	_desc.flash()


func _start_game(start_level := 1) -> void:
	if _leaving:
		return
	_leaving = true
	Game.new_run()
	Game.level = start_level
	var tw := create_tween()
	tw.tween_interval(0.15)
	tw.tween_property(_fade, "color:a", 1.0, 0.6)
	tw.tween_callback(func(): get_tree().change_scene_to_file(GAME_SCENE))


func _quit() -> void:
	if _leaving:
		return
	_leaving = true
	var tw := create_tween()
	tw.tween_property(_fade, "color:a", 1.0, 0.4)
	tw.tween_callback(func(): get_tree().quit())


func _process(delta: float) -> void:
	_scroll += delta * 25.0   # הרקע זז לאט
	_bg.scroll_override = _scroll


# ---- הצללה כהה בצד שמאל ----
class Shade extends Node2D:
	func _draw() -> void:
		var s := get_viewport_rect().size
		var a := Color(0, 0, 0, 0.72)
		var b := Color(0, 0, 0, 0.0)
		draw_polygon(PackedVector2Array([Vector2(0, 0), Vector2(s.x * 0.55, 0), Vector2(s.x * 0.55, s.y), Vector2(0, s.y)]),
			PackedColorArray([a, b, b, a]))


# ---- טקסט קטן (כותרות משנה / תיאור) ----
class Caption extends Node2D:
	var text := "":
		set(v):
			text = v
			queue_redraw()
	var size := 20
	var color := Color(0.9, 0.85, 0.8)
	var _flash := 0.0

	func flash() -> void:
		_flash = 1.0

	func _process(delta: float) -> void:
		if _flash > 0.0:
			_flash = move_toward(_flash, 0.0, delta * 2.5)
			queue_redraw()

	func _draw() -> void:
		var f := ThemeDB.fallback_font
		var p := Vector2(_flash * 12.0, 0.0)
		draw_string_outline(f, p, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, 5, Color(0, 0, 0, 0.85))
		draw_string(f, p, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, Color(color, 1.0 - _flash * 0.7))


# ---- כותרת המשחק: אותיות עם דם שמטפטף ומהבהב ----
class Title extends Node2D:
	var text := "DEAD ZONE"
	var sub := "SURVIVE THE FALLEN CITY"
	var _t := 0.0
	var _drips := []

	func _ready() -> void:
		var rng := RandomNumberGenerator.new()
		rng.seed = 11
		for i in 9:
			_drips.append([rng.randf_range(10.0, 440.0), rng.randf_range(0.0, 3.0), rng.randf_range(10.0, 36.0), rng.randf_range(0.4, 0.9)])

	func _process(delta: float) -> void:
		_t += delta
		queue_redraw()

	func _draw() -> void:
		var f := ThemeDB.fallback_font
		var size := 92
		var appear := clampf(_t / 0.8, 0.0, 1.0)
		var flick := 1.0
		if fmod(_t, 4.7) < 0.12:   # הבהוב קטן מדי פעם, כמו נורה שבורה
			flick = 0.55
		var p := Vector2(0, -40.0 * (1.0 - appear))
		var red := Color(0.72, 0.05, 0.07, appear * flick)
		draw_string_outline(f, p + Vector2(5, 6), text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, 14, Color(0, 0, 0, 0.6 * appear))
		draw_string_outline(f, p, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, 10, Color(0.05, 0.0, 0.0, appear))
		draw_string(f, p, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, red)
		# הארה בהירה בחלק העליון של האותיות
		draw_string(f, p + Vector2(0, -2), text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, Color(1.0, 0.45, 0.4, 0.18 * appear))
		# טפטופי דם שגדלים ונופלים
		for d in _drips:
			var k := fmod(_t * float(d[3]) + float(d[1]), 3.0) / 3.0
			var dl: float = float(d[2]) * clampf(k * 1.6, 0.0, 1.0)
			var x: float = d[0]
			var y0 := p.y + 4.0
			if k < 0.8:
				draw_line(Vector2(x, y0), Vector2(x, y0 + dl), red.darkened(0.2), 4.0, true)
				draw_circle(Vector2(x, y0 + dl), 3.2, red.darkened(0.2))
			else:   # הטיפה נופלת
				var fall := (k - 0.8) / 0.2
				draw_circle(Vector2(x, y0 + dl + fall * 60.0), 2.6 * (1.0 - fall * 0.5), Color(red.darkened(0.2), 1.0 - fall))
		draw_string_outline(f, p + Vector2(4, 44), sub, HORIZONTAL_ALIGNMENT_LEFT, -1, 22, 6, Color(0, 0, 0, 0.9 * appear))
		draw_string(f, p + Vector2(4, 44), sub, HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color(0.85, 0.8, 0.75, appear))


# ---- חדר הגביעים ----
class TrophyRoom extends Node2D:
	var _t := 0.0

	func _process(delta: float) -> void:
		_t += delta
		queue_redraw()

	func _txt(p: Vector2, t: String, size: int, col: Color, align := HORIZONTAL_ALIGNMENT_LEFT, w := -1.0) -> void:
		var f := ThemeDB.fallback_font
		draw_string_outline(f, p, t, align, w, size, 5, Color(0, 0, 0, 0.85))
		draw_string(f, p, t, align, w, size, col)

	func _draw() -> void:
		var vp := get_viewport_rect().size
		draw_rect(Rect2(Vector2.ZERO, vp), Color(0, 0, 0, 0.82))
		var got := 0
		for t in Game.TROPHIES:
			if Game.trophies.get(t.id, false):
				got += 1
		_txt(Vector2(0, 80), "TROPHIES", 48, Color("d8a033"), HORIZONTAL_ALIGNMENT_CENTER, vp.x)
		_txt(Vector2(0, 112), "%d / %d UNLOCKED" % [got, Game.TROPHIES.size()], 18, Color(0.85, 0.8, 0.75), HORIZONTAL_ALIGNMENT_CENTER, vp.x)
		var cw := 270.0
		var ch := 170.0
		var x0 := (vp.x - (cw * 4.0 + 18.0 * 3.0)) / 2.0
		for i in Game.TROPHIES.size():
			var t: Dictionary = Game.TROPHIES[i]
			var unlocked: bool = Game.trophies.get(t.id, false)
			var a := clampf((_t - float(i) * 0.06) / 0.25, 0.0, 1.0)
			var p := Vector2(x0 + float(i % 4) * (cw + 18.0), 140.0 + float(i / 4) * (ch + 18.0) + (1.0 - a) * 20.0)
			draw_rect(Rect2(p, Vector2(cw, ch)), Color(0.08, 0.07, 0.07, 0.95 * a))
			draw_rect(Rect2(p, Vector2(cw, ch)), Color("d8a033") if unlocked else Color(0.3, 0.28, 0.27), false, 2.0)
			var c := p + Vector2(cw / 2.0, 62)
			var gold := Color("e0b040") if unlocked else Color(0.18, 0.17, 0.17)
			if unlocked:
				draw_circle(c, 34.0 + 3.0 * sin(_t * 3.0 + float(i)), Color(1.0, 0.8, 0.3, 0.12))
			draw_colored_polygon(PackedVector2Array([c + Vector2(-20, -24), c + Vector2(20, -24), c + Vector2(14, 0), c + Vector2(4, 6), c + Vector2(-4, 6), c + Vector2(-14, 0)]), gold)
			draw_arc(c + Vector2(-20, -13), 9.0, PI * 0.5, PI * 1.5, 10, gold, 3.5, true)
			draw_arc(c + Vector2(20, -13), 9.0, -PI * 0.5, PI * 0.5, 10, gold, 3.5, true)
			draw_rect(Rect2(c + Vector2(-3, 6), Vector2(6, 10)), gold)
			draw_rect(Rect2(c + Vector2(-14, 16), Vector2(28, 6)), gold.darkened(0.2))
			if not unlocked:
				_txt(c + Vector2(-8, -2), "?", 22, Color(0.5, 0.48, 0.45))
			_txt(p + Vector2(0, 122), t.name if unlocked else "???", 18, Color.WHITE if unlocked else Color(0.6, 0.58, 0.55), HORIZONTAL_ALIGNMENT_CENTER, cw)
			_txt(p + Vector2(0, 146), t.desc, 13, Color(0.75, 0.72, 0.7), HORIZONTAL_ALIGNMENT_CENTER, cw)
		var lt := Game.lifetime
		_txt(Vector2(0, 560), "ALL TIME:   %d kills    %d headshots    %d legs severed" % [lt.kills, lt.headshots, lt.legs], 16, Color(0.8, 0.78, 0.75), HORIZONTAL_ALIGNMENT_CENTER, vp.x)
		var hs := Game.high_scores
		_txt(Vector2(0, 584), "BEST SCORES:   EASY %d    NORMAL %d    HARD %d" % [hs[0], hs[1], hs[2]], 16, Color("d8a033"), HORIZONTAL_ALIGNMENT_CENTER, vp.x)

