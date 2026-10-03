extends Node2D
# ============================================================
#  מפת היבשת (אחרי התפריט הראשי).
#  7 אזורים, לכל אזור צבע משלו. עוברים עם העכבר = האזור נדלק.
#  לוחצים על אזור פתוח = מסך השלבים שלו (9 שלבים).
#  אזור נפתח רק אחרי שמסיימים את כל השלבים של האזור הקודם.
#  SAVE / LOAD = שמירה לקובץ במחשב וטעינה ממנו.
# ============================================================

const ButtonScript := preload("res://menu_button.gd")
const Sfx := preload("res://sfx.gd")
const GAME_SCENE := "res://main.tscn"
const MENU_SCENE := "res://menu.tscn"
const MAP_TEX := preload("res://map/continent.png")
const MASK_TEX := preload("res://map/regions_mask.png")
# מיקום התווית של כל אזור בתמונה המקורית (1024x1536)
const LABELS := [Vector2(355, 245), Vector2(700, 450), Vector2(455, 540), Vector2(250, 527), Vector2(655, 735), Vector2(445, 910), Vector2(400, 1130)]

const SHADER := """
shader_type canvas_item;
uniform sampler2D mask : filter_nearest;
uniform int hovered = 0;
uniform float t = 0.0;
uniform float intro = 10.0;
uniform vec4 colors[8];
uniform float state[8];   // 0 = נעול, 1 = פתוח, 2 = הושלם
int rid(vec2 uv) { return int(round(texture(mask, uv).r * 255.0 / 36.0)); }
void fragment() {
	vec4 c = texture(TEXTURE, UV);
	int id = rid(UV);
	if (id > 0) {
		float st = state[id];
		if (st < 0.5) {   // נעול: אפור וכהה
			float g = dot(c.rgb, vec3(0.3, 0.59, 0.11));
			c.rgb = mix(c.rgb, vec3(g) * 0.62, 0.75);
		}
		float iw = intro - float(id - 1) * 0.16;   // אנימציית פתיחה: האזורים נדלקים בזה אחר זה
		float glow = (iw > 0.0 && iw < 0.55) ? sin(iw / 0.55 * 3.14159) * 0.7 : 0.0;
		if (id == hovered) {
			glow += 0.3 + 0.16 * (0.5 + 0.5 * sin(t * 5.0));
			float band = fract((UV.x * 0.8 + UV.y) * 1.4 - t * 0.55);   // פס אור שעובר
			glow += smoothstep(0.07, 0.0, abs(band - 0.5)) * 0.45;
		}
		c.rgb = mix(c.rgb, colors[id].rgb, glow * 0.5) + colors[id].rgb * glow * 0.22;
	}
	if (hovered > 0 && id != hovered) {   // קו זוהר סביב האזור
		vec2 px = vec2(1.0 / 256.0, 1.0 / 384.0) * 1.3;
		float e = 0.0;
		for (int k = 0; k < 8; k++) {
			vec2 o = vec2(cos(float(k) * 0.785), sin(float(k) * 0.785)) * px;
			if (rid(UV + o) == hovered) { e = 1.0; }
		}
		c.rgb = mix(c.rgb, colors[hovered].rgb * 1.25, e * (0.75 + 0.25 * sin(t * 5.0)));
	}
	COLOR = c;
}
"""

var _map: TextureRect
var _mask_img: Image
var _rect := Rect2()
var _hover := 0                  # 1-7 (0 = כלום)
var _t := 0.0
var _intro := 0.0
var _ui: CanvasLayer
var _root: Control
var _fade: ColorRect
var _overlay: MapOverlay
var _select: Control = null
var _leaving := false
var _msg := ""
var _msg_t := 0.0
var _shake := {}                 # אזור נעול שלחצו עליו -> רעידה


func _ready() -> void:
	get_tree().paused = false
	Engine.time_scale = 1.0
	Sfx.warm_up()
	var vs := get_viewport_rect().size
	var bg := Backdrop.new()
	add_child(bg)
	# המפה: גובה כמעט כל המסך
	var h := vs.y - 20.0
	var w := h * float(MAP_TEX.get_width()) / float(MAP_TEX.get_height())
	_rect = Rect2(Vector2(40.0, 10.0), Vector2(w, h))
	_map = TextureRect.new()
	_map.texture = MAP_TEX
	_map.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_map.stretch_mode = TextureRect.STRETCH_SCALE
	_map.position = _rect.position
	_map.size = _rect.size
	_map.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var m := ShaderMaterial.new()
	m.shader = Shader.new()
	m.shader.code = SHADER
	m.set_shader_parameter("mask", MASK_TEX)
	var cols := [Color.BLACK]
	for r in Game.REGIONS:
		cols.append(r.color)
	m.set_shader_parameter("colors", cols)
	_map.material = m
	add_child(_map)
	_mask_img = MASK_TEX.get_image()
	if _mask_img.is_compressed():
		_mask_img.decompress()
	_overlay = MapOverlay.new()
	_overlay.map = self
	add_child(_overlay)
	_update_states()
	# כפתורים
	_ui = CanvasLayer.new()
	_ui.layer = 3
	add_child(_ui)
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ui.add_child(_root)
	var px := _rect.end.x + 50.0
	_button("SAVE GAME", Vector2(px, vs.y - 150.0), Vector2(220, 50), Color("3a8acc"), 0.4).pressed.connect(_save_game)
	_button("LOAD GAME", Vector2(px + 236.0, vs.y - 150.0), Vector2(220, 50), Color("d8a033"), 0.5).pressed.connect(_load_game)
	_button("MAIN MENU", Vector2(px, vs.y - 86.0), Vector2(456, 50), Color("5a5a62"), 0.6).pressed.connect(_to_menu)
	_fade = ColorRect.new()
	_fade.color = Color(0, 0, 0, 1)
	_fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ui.add_child(_fade)
	create_tween().tween_property(_fade, "color:a", 0.0, 0.7)


func _button(text: String, pos: Vector2, sz: Vector2, accent: Color, delay: float) -> Control:
	var b := ButtonScript.new()
	b.text = text
	b.font_size = 22
	b.accent = accent
	b.position = pos
	b.size = sz
	b.appear_delay = delay
	_root.add_child(b)
	return b


func _update_states() -> void:
	var st := [0.0]
	for r in Game.REGIONS.size():
		st.append(0.0 if not Game.region_unlocked(r) else (2.0 if Game.region_done(r) >= Game.LEVELS_PER_REGION else 1.0))
	(_map.material as ShaderMaterial).set_shader_parameter("state", st)


func region_at(p: Vector2) -> int:
	if not _rect.has_point(p):
		return 0
	var uv := (p - _rect.position) / _rect.size
	var c := _mask_img.get_pixel(int(uv.x * (_mask_img.get_width() - 1)), int(uv.y * (_mask_img.get_height() - 1)))
	return int(round(c.r * 255.0 / 36.0))


func label_pos(r: int) -> Vector2:
	return _rect.position + LABELS[r] * (_rect.size / Vector2(MAP_TEX.get_width(), MAP_TEX.get_height()))


func _process(delta: float) -> void:
	_t += delta
	_intro += delta
	_msg_t -= delta
	for k in _shake.keys():
		_shake[k] -= delta
		if _shake[k] <= 0.0:
			_shake.erase(k)
	var h := 0 if _select != null else region_at(get_viewport().get_mouse_position())
	if h != _hover:
		_hover = h
		if h > 0:
			Sfx.play("ui", null, -4.0)
	var m: ShaderMaterial = _map.material
	m.set_shader_parameter("hovered", _hover)
	m.set_shader_parameter("t", _t)
	m.set_shader_parameter("intro", _intro)
	_overlay.queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if _select != null or _leaving:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT and _hover > 0:
		var r := _hover - 1
		if Game.region_unlocked(r):
			Sfx.play("weapon", null)
			_open_region(r)
		else:
			_shake[r] = 0.4
			Sfx.play("empty", null, 4.0)
			_say("LOCKED  -  FINISH %s FIRST" % Game.REGIONS[r - 1].name)
	elif event is InputEventKey and event.pressed and event.physical_keycode == KEY_ESCAPE:
		_to_menu()


func _say(t: String) -> void:
	_msg = t
	_msg_t = 2.5


# ---- מסך השלבים של אזור ----
func _open_region(r: int) -> void:
	_select = LevelSelect.new()
	_select.map = self
	_select.region = r
	_ui.add_child(_select)
	_ui.move_child(_fade, -1)


func close_select() -> void:
	if _select != null:
		_select.queue_free()
		_select = null


func start_level(lv: int) -> void:
	if _leaving:
		return
	_leaving = true
	Game.start_level(lv)
	var tw := create_tween()
	tw.tween_property(_fade, "color:a", 1.0, 0.5)
	tw.tween_callback(func(): get_tree().change_scene_to_file(GAME_SCENE))


func _to_menu() -> void:
	if _leaving:
		return
	_leaving = true
	var tw := create_tween()
	tw.tween_property(_fade, "color:a", 1.0, 0.4)
	tw.tween_callback(func(): get_tree().change_scene_to_file(MENU_SCENE))


# ---- שמירה / טעינה לקובץ במחשב ----
func _file_dialog(save: bool) -> void:
	var fd := FileDialog.new()
	fd.access = FileDialog.ACCESS_FILESYSTEM
	fd.file_mode = FileDialog.FILE_MODE_SAVE_FILE if save else FileDialog.FILE_MODE_OPEN_FILE
	fd.filters = PackedStringArray(["*.tlsave ; THEY LEARN save"])
	fd.use_native_dialog = true
	fd.title = "Save game" if save else "Load game"
	fd.current_dir = OS.get_system_dir(OS.SYSTEM_DIR_DOCUMENTS)
	fd.current_file = "TheyLearn.tlsave"
	fd.size = Vector2i(800, 500)
	_ui.add_child(fd)
	fd.file_selected.connect(func(path: String):
		if save:
			_say("GAME SAVED: " + path.get_file() if Game.export_save(path) else "COULD NOT SAVE")
		else:
			if Game.import_save(path):
				_say("GAME LOADED")
				_update_states()
				_intro = 0.0
			else:
				_say("NOT A THEY LEARN SAVE FILE")
		fd.queue_free())
	fd.canceled.connect(fd.queue_free)
	fd.popup_centered()


func _save_game() -> void:
	_file_dialog(true)


func _load_game() -> void:
	_file_dialog(false)


# ============================================================
#  רקע: שולחן עץ כהה + אבק שמרחף
# ============================================================
class Backdrop extends Node2D:
	var _t := 0.0
	var _dust := []

	func _ready() -> void:
		z_index = -10
		for i in 50:
			_dust.append([randf() * 1280.0, randf() * 720.0, randf_range(4.0, 14.0), randf() * TAU])

	func _process(d: float) -> void:
		_t += d
		for p in _dust:
			p[1] -= p[2] * d
			p[0] += sin(_t + p[3]) * 6.0 * d
			if p[1] < -5.0:
				p[1] = 725.0
		queue_redraw()

	func _draw() -> void:
		var vs := get_viewport_rect().size
		draw_rect(Rect2(Vector2.ZERO, vs), Color("120c0a"))
		for i in 12:   # קורות עץ
			var y := float(i) * 62.0
			draw_rect(Rect2(0, y, vs.x, 60.0), Color("1c1410").lerp(Color("241a14"), float(i % 3) / 3.0))
			draw_line(Vector2(0, y + 60.0), Vector2(vs.x, y + 60.0), Color(0, 0, 0, 0.5), 2.0)
		for i in 14:   # וינייטה
			draw_rect(Rect2(Vector2.ZERO, vs).grow(-float(i) * 6.0), Color(0, 0, 0, 0.05), false, 12.0)
		for p in _dust:
			draw_circle(Vector2(p[0], p[1]), 1.2, Color(1.0, 0.85, 0.6, 0.25))


# ============================================================
#  שכבה מעל המפה: תגים לכל אזור, מנעולים, חץ "התחל כאן", פאנל מידע
# ============================================================
class MapOverlay extends Node2D:
	var map: Node

	func _draw() -> void:
		var f := ThemeDB.fallback_font
		var t: float = map._t
		# צל למפה
		var rr: Rect2 = map._rect
		for i in 6:
			draw_rect(rr.grow(4.0 + float(i) * 3.0), Color(0, 0, 0, 0.12), false, 3.0)
		# ---- תג לכל אזור ----
		for r in Game.REGIONS.size():
			var reg: Dictionary = Game.REGIONS[r]
			var c: Vector2 = map.label_pos(r) + Vector2(0, 30)
			if map._shake.has(r):
				c.x += sin(t * 60.0) * 4.0
			var col: Color = reg.color
			var open := Game.region_unlocked(r)
			var done := Game.region_done(r)
			var hov: bool = map._hover == r + 1
			var rad := 15.0 + (3.0 + sin(t * 6.0) * 1.0 if hov else 0.0)
			draw_circle(c, rad + 3.0, Color(0, 0, 0, 0.55))
			draw_circle(c, rad, Color(0.1, 0.08, 0.07, 0.92))
			if open:
				draw_arc(c, rad, -PI / 2.0, -PI / 2.0 + TAU, 32, Color(col, 0.25), 3.0, true)
				if done > 0:
					draw_arc(c, rad, -PI / 2.0, -PI / 2.0 + TAU * float(done) / 9.0, 32, col, 3.5, true)
				draw_string(f, c + Vector2(-20, 5), "%d/9" % done, HORIZONTAL_ALIGNMENT_CENTER, 40, 11, Color.WHITE)
			else:   # מנעול
				draw_arc(c + Vector2(0, -3), 5.0, PI, TAU, 10, Color(0.75, 0.7, 0.65), 2.0, true)
				draw_rect(Rect2(c + Vector2(-6.5, -3.0), Vector2(13, 10)), Color(0.75, 0.7, 0.65))
				draw_circle(c + Vector2(0, 1.5), 1.5, Color(0.1, 0.08, 0.07))
		# ---- "התחל כאן": חץ קופץ מעל האזור הבא שצריך לשחק ----
		var target := -1
		for r in Game.REGIONS.size():
			if Game.region_unlocked(r) and Game.region_done(r) < Game.LEVELS_PER_REGION:
				target = r
		if target >= 0:
			var p: Vector2 = map.label_pos(target) + Vector2(0, -6.0 - absf(sin(t * 3.0)) * 10.0)
			var col: Color = Game.REGIONS[target].color
			draw_colored_polygon(PackedVector2Array([p + Vector2(-9, -16), p + Vector2(9, -16), p]), col)
			draw_polyline(PackedVector2Array([p + Vector2(-9, -16), p + Vector2(9, -16), p, p + Vector2(-9, -16)]), Color(0, 0, 0, 0.8), 1.5, true)
		# ---- פאנל מידע מימין ----
		var px: float = rr.end.x + 50.0
		var pw := 456.0
		_txt(f, Vector2(px, 52), "THEY LEARN", 44, Color(0.85, 0.12, 0.1))
		_txt(f, Vector2(px, 82), "THE INFECTED CONTINENT", 16, Color(0.9, 0.82, 0.7, 0.8))
		var total := 0
		for r in Game.REGIONS.size():
			total += Game.region_done(r)
		var all: int = Game.REGIONS.size() * Game.LEVELS_PER_REGION
		draw_rect(Rect2(px, 100, pw, 10), Color(0, 0, 0, 0.6))
		draw_rect(Rect2(px, 100, pw * float(total) / float(all), 10), Color(0.85, 0.15, 0.1))
		_txt(f, Vector2(px, 130), "PROGRESS  %d / %d" % [total, all], 15, Color(1, 1, 1, 0.75))
		var show: int = map._hover - 1
		if show < 0:
			show = maxi(target, 0)
		var reg: Dictionary = Game.REGIONS[show]
		var col: Color = reg.color
		var y := 190.0
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(0.08, 0.06, 0.05, 0.85)
		sb.border_color = Color(col, 0.8)
		sb.set_border_width_all(2)
		sb.set_corner_radius_all(10)
		draw_style_box(sb, Rect2(px - 14, y - 34, pw + 28, 330))
		_txt(f, Vector2(px, y), "%d. %s" % [show + 1, reg.name], 28, col)
		var lines := _wrap(f, reg.desc, 16, pw)
		for i in lines.size():
			_txt(f, Vector2(px, y + 30 + float(i) * 20.0), lines[i], 16, Color(0.9, 0.85, 0.78))
		var open := Game.region_unlocked(show)
		var done := Game.region_done(show)
		var status := "LOCKED" if not open else ("COMPLETE" if done >= 9 else "OPEN")
		_txt(f, Vector2(px, y + 90), status, 18, Color(0.7, 0.7, 0.7) if not open else (Color(1.0, 0.85, 0.3) if done >= 9 else Color(0.5, 1.0, 0.5)))
		# 9 נקודות - שלבי האזור
		for i in 9:
			var lv: int = show * 9 + i + 1
			var cc := Vector2(px + 14.0 + float(i) * 50.0, y + 130.0)
			var st: int = Game.completed.get(lv, 0)
			draw_circle(cc, 15.0, Color(0, 0, 0, 0.6))
			if st > 0:
				draw_circle(cc, 13.0, col)
				draw_string(f, cc + Vector2(-20, 5), "★".repeat(st), HORIZONTAL_ALIGNMENT_CENTER, 40, 10, Color(0.1, 0.05, 0.02))
			elif Game.level_playable(lv):
				draw_circle(cc, 13.0, Color(col, 0.35 + 0.25 * sin(t * 4.0)))
				draw_string(f, cc + Vector2(-20, 5), str(i + 1), HORIZONTAL_ALIGNMENT_CENTER, 40, 13, Color.WHITE)
			else:
				draw_arc(cc, 13.0, 0.0, TAU, 20, Color(1, 1, 1, 0.2), 1.5, true)
				draw_string(f, cc + Vector2(-20, 5), str(i + 1), HORIZONTAL_ALIGNMENT_CENTER, 40, 12, Color(1, 1, 1, 0.3))
		var hint := "CLICK TO OPEN" if open else ("FINISH %s TO UNLOCK" % Game.REGIONS[show - 1].name if show > 0 else "")
		_txt(f, Vector2(px, y + 182), hint, 15, Color(1, 1, 1, 0.55 + 0.25 * sin(t * 3.0)))
		var nxt := ""
		for i in 9:
			var lv: int = show * 9 + i + 1
			if Game.level_playable(lv) and not Game.completed.has(lv):
				nxt = "NEXT:  %d-%d  %s" % [show + 1, i + 1, Game.level_name(lv)]
				break
		_txt(f, Vector2(px, y + 214), nxt, 17, Color(1, 1, 1, 0.85))
		_txt(f, Vector2(px, y + 268), "HOVER A REGION  ·  CLICK TO ENTER  ·  ESC = MENU", 12, Color(1, 1, 1, 0.4))
		# הודעה
		if map._msg_t > 0.0:
			var a := clampf(map._msg_t, 0.0, 1.0)
			var vs := get_viewport_rect().size
			draw_rect(Rect2(0, vs.y * 0.5 - 24, vs.x, 48), Color(0, 0, 0, 0.7 * a))
			draw_string(f, Vector2(0, vs.y * 0.5 + 8), map._msg, HORIZONTAL_ALIGNMENT_CENTER, vs.x, 22, Color(1.0, 0.9, 0.7, a))

	func _txt(f: Font, p: Vector2, s: String, size: int, col: Color) -> void:
		draw_string_outline(f, p, s, HORIZONTAL_ALIGNMENT_LEFT, -1, size, 4, Color(0, 0, 0, 0.7 * col.a))
		draw_string(f, p, s, HORIZONTAL_ALIGNMENT_LEFT, -1, size, col)

	func _wrap(f: Font, s: String, size: int, w: float) -> Array:
		var out := []
		var line := ""
		for word in s.split(" "):
			var tryl := word if line == "" else line + " " + word
			if f.get_string_size(tryl, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x > w:
				out.append(line)
				line = word
			else:
				line = tryl
		if line != "":
			out.append(line)
		return out


# ============================================================
#  מסך שלבים של אזור: 9 כרטיסים
# ============================================================
class LevelSelect extends Control:
	var map: Node
	var region := 0
	var _t := 0.0
	var _cards := []

	func _ready() -> void:
		set_anchors_preset(Control.PRESET_FULL_RECT)
		mouse_filter = Control.MOUSE_FILTER_STOP
		var vs := get_viewport_rect().size
		var cw := 300.0
		var ch := 128.0
		var gx := (vs.x - (cw * 3.0 + 40.0)) * 0.5
		for i in 9:
			var c := LevelCard.new()
			c.lv = region * 9 + i + 1
			c.idx = i
			c.col = Game.REGIONS[region].color
			c.position = Vector2(gx + float(i % 3) * (cw + 20.0), 150.0 + float(i / 3) * (ch + 18.0))
			c.size = Vector2(cw, ch)
			c.delay = 0.05 * float(i)
			c.chosen.connect(func(lv): map.start_level(lv))
			add_child(c)
			_cards.append(c)
		var back := ButtonScript.new()
		back.text = "BACK TO MAP"
		back.font_size = 22
		back.accent = Color("5a5a62")
		back.position = Vector2(vs.x * 0.5 - 140.0, vs.y - 78.0)
		back.size = Vector2(280, 52)
		back.pressed.connect(map.close_select)
		add_child(back)

	func _process(d: float) -> void:
		_t += d
		queue_redraw()

	func _gui_input(e: InputEvent) -> void:
		if e is InputEventKey and e.pressed and e.physical_keycode == KEY_ESCAPE:
			map.close_select()

	func _unhandled_input(e: InputEvent) -> void:
		if e is InputEventKey and e.pressed and e.physical_keycode == KEY_ESCAPE:
			map.close_select()
			get_viewport().set_input_as_handled()

	func _draw() -> void:
		var vs := get_viewport_rect().size
		var a := clampf(_t / 0.3, 0.0, 1.0)
		var col: Color = Game.REGIONS[region].color
		draw_rect(Rect2(Vector2.ZERO, vs), Color(0.03, 0.02, 0.02, 0.88 * a))
		for i in 8:
			draw_rect(Rect2(0, 0, vs.x, 120.0 - float(i) * 12.0), Color(col, 0.025 * a))
		var f := ThemeDB.fallback_font
		draw_string_outline(f, Vector2(0, 74), "%d. %s" % [region + 1, Game.REGIONS[region].name], HORIZONTAL_ALIGNMENT_CENTER, vs.x, 40, 6, Color(0, 0, 0, a))
		draw_string(f, Vector2(0, 74), "%d. %s" % [region + 1, Game.REGIONS[region].name], HORIZONTAL_ALIGNMENT_CENTER, vs.x, 40, Color(col, a))
		draw_string(f, Vector2(0, 108), Game.REGIONS[region].desc, HORIZONTAL_ALIGNMENT_CENTER, vs.x, 17, Color(0.9, 0.85, 0.78, a))


class LevelCard extends Control:
	signal chosen(lv: int)
	var lv := 1
	var idx := 0
	var col := Color.WHITE
	var delay := 0.0
	var _t := 0.0
	var _hov := 0.0
	var _in := false

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_STOP
		mouse_entered.connect(func():
			_in = true
			if Game.level_playable(lv):
				Sfx.play("ui", null, -6.0))
		mouse_exited.connect(func(): _in = false)
		pivot_offset = size * 0.5

	func _process(d: float) -> void:
		_t += d
		_hov = move_toward(_hov, 1.0 if _in else 0.0, d * 6.0)
		var k := clampf((_t - delay) / 0.35, 0.0, 1.0)
		k = 1.0 - pow(1.0 - k, 3.0)
		modulate.a = k
		scale = Vector2.ONE * (0.85 + 0.15 * k + 0.04 * _hov)
		queue_redraw()

	func _gui_input(e: InputEvent) -> void:
		if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
			if Game.level_playable(lv):
				Sfx.play("weapon", null)
				chosen.emit(lv)
			else:
				Sfx.play("empty", null, 3.0)

	func _draw() -> void:
		var f := ThemeDB.fallback_font
		var playable := Game.level_playable(lv)
		var unlocked := Game.level_unlocked(lv)
		var stars: int = Game.completed.get(lv, 0)
		var r := Rect2(Vector2.ZERO, size)
		var sb := StyleBoxFlat.new()
		sb.set_corner_radius_all(12)
		sb.bg_color = Color(0.1, 0.08, 0.07, 0.95).lerp(col, 0.12 + 0.12 * _hov if playable else 0.0)
		sb.border_color = Color(col, 0.9) if playable else Color(1, 1, 1, 0.15)
		sb.set_border_width_all(3 if _hov > 0.5 and playable else 2)
		sb.shadow_color = Color(col, 0.35 * _hov) if playable else Color(0, 0, 0, 0)
		sb.shadow_size = int(14.0 * _hov)
		draw_style_box(sb, r)
		var a := 1.0 if playable else 0.45
		draw_circle(Vector2(36, 36), 22.0, Color(col, 0.9 * a) if unlocked else Color(0.3, 0.3, 0.3))
		draw_string(f, Vector2(14, 44), str(idx + 1), HORIZONTAL_ALIGNMENT_CENTER, 44, 22, Color(0.08, 0.05, 0.04))
		draw_string(f, Vector2(70, 34), Game.level_name(lv).to_upper(), HORIZONTAL_ALIGNMENT_LEFT, size.x - 80.0, 18, Color(1, 1, 1, a))
		var sub := ""
		if lv <= Game.IMPLEMENTED:
			sub = Game.LEVEL_TITLES[(lv - 1) % Game.LEVEL_TITLES.size()][0]
		draw_string(f, Vector2(70, 56), sub, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.9, 0.2, 0.15, a))
		if not unlocked:   # מנעול
			var c := Vector2(size.x * 0.5, 92)
			draw_arc(c + Vector2(0, -6), 7.0, PI, TAU, 12, Color(1, 1, 1, 0.4), 2.5, true)
			draw_rect(Rect2(c + Vector2(-9, -6), Vector2(18, 14)), Color(1, 1, 1, 0.4))
		elif lv > Game.IMPLEMENTED:
			draw_string(f, Vector2(0, 98), "COMING SOON", HORIZONTAL_ALIGNMENT_CENTER, size.x, 16, Color(1, 1, 1, 0.45))
		else:
			for s in 3:   # כוכבים
				var sc := Vector2(size.x * 0.5 - 30.0 + float(s) * 30.0, 92)
				var on := s < stars
				var pts := PackedVector2Array()
				for k in 10:
					var ang := -PI / 2.0 + float(k) * PI / 5.0
					pts.append(sc + Vector2.from_angle(ang) * (11.0 if k % 2 == 0 else 4.6))
				draw_colored_polygon(pts, Color(1.0, 0.82, 0.25) if on else Color(1, 1, 1, 0.12))
			if stars == 0:
				draw_string(f, Vector2(0, 122), "PLAY", HORIZONTAL_ALIGNMENT_CENTER, size.x, 13, Color(col, 0.6 + 0.4 * sin(_t * 4.0)))
			elif Game.level_best.has(lv):
				draw_string(f, Vector2(0, 122), "BEST %d" % Game.level_best[lv], HORIZONTAL_ALIGNMENT_CENTER, size.x, 12, Color(1, 1, 1, 0.5))
