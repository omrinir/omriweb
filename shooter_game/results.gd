extends CanvasLayer
# ============================================================
#  מסך סיום שלב: כוכבים, סטטיסטיקות, ניקוד, ו"חנות" שדרוגים
#  שקונים בנקודות SCRAP. משם ממשיכים לשלב הבא.
# ============================================================

const ButtonScript := preload("res://menu_button.gd")
const MENU_SCENE := "res://menu.tscn"
const MAP_SCENE := "res://map.tscn"

var _r: Dictionary
var _root: Control
var _panel: Node2D
var _fade: ColorRect
var _leaving := false


func _ready() -> void:
	layer = 6
	process_mode = Node.PROCESS_MODE_ALWAYS


func show_results(r: Dictionary) -> void:
	_r = r
	get_tree().paused = true
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.7)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)
	_panel = ResultsPanel.new()
	_panel.r = r
	add_child(_panel)
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)
	_fade = ColorRect.new()
	_fade.color = Color(0, 0, 0, 0)
	_fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_fade)
	_results_buttons(true)


func _clear() -> void:
	for c in _root.get_children():
		c.queue_free()


func _btn(text: String, pos: Vector2, sz: Vector2, accent: Color, fs := 26, delay := 0.0) -> Control:
	var b := ButtonScript.new()
	b.text = text
	b.font_size = fs
	b.accent = accent
	b.position = pos
	b.size = sz
	b.appear_delay = delay
	_root.add_child(b)
	return b


func _results_buttons(first := false) -> void:
	_clear()
	_panel.mode = 0
	var vp := get_viewport().get_visible_rect().size
	var y := 560.0
	var d := 1.6 if first else 0.0   # בפעם הראשונה מחכים שהכוכבים יופיעו
	var next := _btn("NEXT LEVEL", Vector2(vp.x / 2.0 - 330.0, y), Vector2(220, 56), Color("b3121a"), 26, d)
	next.pressed.connect(_next)
	_btn("UPGRADES", Vector2(vp.x / 2.0 - 100.0, y), Vector2(200, 56), Color("d8a033"), 26, d + 0.1).pressed.connect(_shop)
	_btn("MAP", Vector2(vp.x / 2.0 + 120.0, y), Vector2(210, 56), Color("5a5a62"), 26, d + 0.2).pressed.connect(_map)
	next.call_deferred("grab_focus")


func _shop() -> void:
	_clear()
	_panel.mode = 1
	var vp := get_viewport().get_visible_rect().size
	for i in Game.UPGRADES.size():
		var u: Dictionary = Game.UPGRADES[i]
		var lvl := Game.upgrade_level(u.id)
		var maxed: bool = lvl >= u.costs.size()
		var cost: int = 0 if maxed else int(u.costs[lvl])
		var label := "MAX" if maxed else "BUY %d" % cost
		var accent := Color("5a5a62") if maxed or Game.scrap < cost else Color("d8a033")
		var b := _btn(label, Vector2(vp.x / 2.0 + 150.0, 176.0 + float(i) * 58.0), Vector2(130, 42), accent, 18, 0.05 * float(i))
		if not maxed:
			b.pressed.connect(_buy.bind(u.id))
	_btn("BACK", Vector2(vp.x / 2.0 - 100.0, 560.0), Vector2(200, 56), Color("b3121a"), 26, 0.3).pressed.connect(_results_buttons)


func _buy(id: String) -> void:
	if Game.buy(id):
		_panel.flash()
	_shop()


func _next() -> void:
	if Game.level_playable(Game.level):   # השלב הבא כבר בנוי ופתוח
		Game.start_level(Game.level)
		_leave(func(): get_tree().reload_current_scene())
	else:
		_map()


func _map() -> void:
	_leave(func(): get_tree().change_scene_to_file(MAP_SCENE))


func _menu() -> void:
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


# ---- הלוח עם התוצאות / החנות ----
class ResultsPanel extends Node2D:
	var r: Dictionary
	var mode := 0   # 0 = תוצאות, 1 = שדרוגים
	var _t := 0.0
	var _flash := 0.0

	func flash() -> void:
		_flash = 1.0

	func _process(delta: float) -> void:
		_t += delta
		_flash = maxf(_flash - delta * 2.0, 0.0)
		queue_redraw()

	func _txt(p: Vector2, t: String, size: int, col: Color, align := HORIZONTAL_ALIGNMENT_LEFT, w := -1.0) -> void:
		var f := ThemeDB.fallback_font
		draw_string_outline(f, p, t, align, w, size, 5, Color(0, 0, 0, 0.85))
		draw_string(f, p, t, align, w, size, col)

	func _draw() -> void:
		var vp := get_viewport_rect().size
		var pw := 640.0
		var px := (vp.x - pw) / 2.0
		draw_rect(Rect2(Vector2(px, 60), Vector2(pw, 480)), Color(0.07, 0.06, 0.07, 0.94))
		draw_rect(Rect2(Vector2(px, 60), Vector2(pw, 480)), Color("8a1a1a"), false, 2.0)
		if mode == 0:
			_results(vp, px, pw)
		else:
			_upgrades(vp, px, pw)

	func _results(vp: Vector2, px: float, pw: float) -> void:
		var st: Dictionary = r.stats
		_txt(Vector2(0, 112), "LEVEL %d CLEARED" % (Game.level - 1), 40, Color("e04030"), HORIZONTAL_ALIGNMENT_CENTER, vp.x)
		# כוכבים שקופצים אחד אחרי השני
		for i in 3:
			var appear := clampf((_t - 0.3 - float(i) * 0.3) / 0.25, 0.0, 1.0)
			var got: bool = i < int(r.stars)
			var s := 1.0 + 0.5 * sin(appear * PI) if got else 1.0
			var c := Vector2(vp.x / 2.0 + float(i - 1) * 62.0, 160)
			_star(c, 22.0 * s * (appear if got else 1.0), Color("f0c040") if got and appear > 0.0 else Color(0.25, 0.22, 0.2))
		var lines := [
			["KILLS", str(st.kills)],
			["HEADSHOTS", str(st.headshots)],
			["ACCURACY", "%d%%" % int(round(float(r.accuracy) * 100.0))],
			["HEARTS LOST", str(st.hearts_lost)],
			["DRAINED / SPARED", "%d / %d" % [st.drained, st.spared]],
			["TIME", "%d:%02d" % [int(st.time) / 60, int(st.time) % 60]],
			["STAR BONUS", "+%d" % r.bonus],
			["LEVEL SCORE", str(r.level_score)],
			["TOTAL SCORE", str(r.run_score)],
		]
		for i in lines.size():
			var a := clampf((_t - 0.9 - float(i) * 0.08) / 0.2, 0.0, 1.0)
			if a <= 0.0:
				continue
			var y := 214.0 + float(i) * 28.0
			var col := Color(0.85, 0.82, 0.78, a)
			if i >= 7:
				col = Color(1, 1, 1, a)
			_txt(Vector2(px + 90, y), lines[i][0], 18, col)
			_txt(Vector2(px + 90, y), lines[i][1], 18, col, HORIZONTAL_ALIGNMENT_RIGHT, pw - 180.0)
		if _t > 1.8:
			_txt(Vector2(0, 482), "+%d SCRAP" % r.scrap, 20, Color("d8a033"), HORIZONTAL_ALIGNMENT_CENTER, vp.x)
			if r.best:
				var pulse := 0.7 + 0.3 * sin(_t * 6.0)
				_txt(Vector2(0, 512), "NEW BEST SCORE!", 22, Color(1.0, 0.85, 0.3, pulse), HORIZONTAL_ALIGNMENT_CENTER, vp.x)

	func _upgrades(vp: Vector2, px: float, pw: float) -> void:
		_txt(Vector2(0, 112), "UPGRADES", 40, Color("d8a033"), HORIZONTAL_ALIGNMENT_CENTER, vp.x)
		_txt(Vector2(0, 146), "SCRAP: %d" % Game.scrap, 22, Color(1, 1, 1).lerp(Color("ffd34a"), _flash), HORIZONTAL_ALIGNMENT_CENTER, vp.x)
		for i in Game.UPGRADES.size():
			var u: Dictionary = Game.UPGRADES[i]
			var y := 192.0 + float(i) * 58.0
			_txt(Vector2(px + 40, y), u.name, 20, Color.WHITE)
			_txt(Vector2(px + 40, y + 20), u.desc, 14, Color(0.75, 0.72, 0.7))
			var lvl := Game.upgrade_level(u.id)
			for k in u.costs.size():   # נקודות שמראות כמה שדרגנו
				var c := Vector2(px + 300 + float(k) * 18.0, y - 5.0)
				draw_circle(c, 6.0, Color(0, 0, 0, 0.6))
				draw_circle(c, 4.5, Color("d8a033") if k < lvl else Color(0.25, 0.22, 0.2))

	func _star(c: Vector2, r_: float, col: Color) -> void:
		if r_ <= 0.5:
			return
		var pts := PackedVector2Array()
		for i in 10:
			var a := -PI / 2.0 + TAU * float(i) / 10.0
			var rr := r_ if i % 2 == 0 else r_ * 0.45
			pts.append(c + Vector2(cos(a), sin(a)) * rr)
		draw_colored_polygon(pts, col)
		var closed := PackedVector2Array(pts)
		closed.append(pts[0])
		draw_polyline(closed, Color(0, 0, 0, 0.8), 2.0, true)
