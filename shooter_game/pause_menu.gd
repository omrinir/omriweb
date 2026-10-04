extends CanvasLayer
# ============================================================
#  תפריט השהיה (ESC) ומסך GAME OVER, עם אותם כפתורים מונפשים.
# ============================================================

const ButtonScript := preload("res://menu_button.gd")
const VolumeScript := preload("res://ui/volume_sliders.gd")
const MENU_SCENE := "res://menu.tscn"

var _root: Control
var _dim: ColorRect
var _title := ""
var _title_node: Node2D
var _game_over := false
var _fade: ColorRect
var _leaving := false


func _ready() -> void:
	layer = 5
	process_mode = Node.PROCESS_MODE_ALWAYS
	_dim = ColorRect.new()
	_dim.color = Color(0, 0, 0, 0.6)
	_dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_dim)
	_title_node = TitleText.new()
	add_child(_title_node)
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)
	_fade = ColorRect.new()
	_fade.color = Color(0, 0, 0, 1)
	_fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_fade)
	create_tween().tween_property(_fade, "color:a", 0.0, 0.7)   # כניסה למשחק מתוך שחור
	_hide()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_ESCAPE and not _game_over:
		if get_tree().paused:
			_resume()
		else:
			_open_pause()
		get_viewport().set_input_as_handled()


func _open_pause() -> void:
	get_tree().paused = true
	_show("PAUSED", [["RESUME", _resume, Color("b3121a")], ["RESTART", _restart, Color("b3121a")], ["MAIN MENU", _to_menu, Color("5a5a62")]])


# נקרא כשהשחקן מת
func show_game_over() -> void:
	_game_over = true
	Game.finish_run()
	await get_tree().create_timer(1.3).timeout
	_show("", [["TRY AGAIN", _restart, Color("b3121a")], ["MAIN MENU", _to_menu, Color("5a5a62")]], 470.0)
	_dim.visible = false   # ה-HUD כבר מחשיך את המסך ומציג GAME OVER


func _show(title: String, buttons: Array, y0 := 300.0) -> void:
	for c in _root.get_children():
		c.queue_free()
	_dim.visible = true
	_title_node.text = title
	_title_node.visible = title != ""
	var vp := get_viewport().get_visible_rect().size
	var first: Control = null
	for i in buttons.size():
		var b := ButtonScript.new()
		b.text = buttons[i][0]
		b.font_size = 30
		b.accent = buttons[i][2]
		b.size = Vector2(280, 58)
		b.position = Vector2((vp.x - 280.0) / 2.0, y0 + float(i) * 72.0)
		b.appear_delay = 0.05 * float(i)
		b.pressed.connect(buttons[i][1])
		_root.add_child(b)
		if first == null:
			first = b
	if title == "PAUSED":   # סרגלי עוצמה (מוזיקה / אפקטים)
		var vs = VolumeScript.new()
		vs.position = Vector2((vp.x - 280.0) / 2.0, y0 + float(buttons.size()) * 72.0 + 8.0)
		_root.add_child(vs)
	first.call_deferred("grab_focus")


func _hide() -> void:
	_dim.visible = false
	_title_node.visible = false
	for c in _root.get_children():
		c.queue_free()


func _resume() -> void:
	get_tree().paused = false
	_hide()


func _restart() -> void:
	Game.restart_level()   # חוזרים לתחילת השלב הנוכחי
	_leave(func(): get_tree().reload_current_scene())


func _to_menu() -> void:
	if not _game_over:
		Game.finish_run()
	_leave(func(): get_tree().change_scene_to_file(MENU_SCENE))


func _leave(then: Callable) -> void:
	if _leaving:
		return
	_leaving = true
	var tw := create_tween()
	tw.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tw.tween_property(_fade, "color:a", 1.0, 0.4)
	tw.tween_callback(func():
		get_tree().paused = false
		then.call())


class TitleText extends Node2D:
	var text := ""
	var _t := 0.0

	func _process(delta: float) -> void:
		_t += delta
		queue_redraw()

	func _draw() -> void:
		var f := ThemeDB.fallback_font
		var vp := get_viewport_rect().size
		var p := Vector2(0, 230.0 + sin(_t * 2.0) * 3.0)
		draw_string_outline(f, p, text, HORIZONTAL_ALIGNMENT_CENTER, vp.x, 64, 10, Color(0, 0, 0, 0.9))
		draw_string(f, p, text, HORIZONTAL_ALIGNMENT_CENTER, vp.x, 64, Color(0.75, 0.06, 0.08))
		var d := "DIFFICULTY: " + Settings.difficulty_name()
		draw_string_outline(f, p + Vector2(0, 40), d, HORIZONTAL_ALIGNMENT_CENTER, vp.x, 20, 5, Color(0, 0, 0, 0.9))
		draw_string(f, p + Vector2(0, 40), d, HORIZONTAL_ALIGNMENT_CENTER, vp.x, 20, Settings.COLORS[Settings.difficulty])
