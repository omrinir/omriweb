extends Node2D
# ============================================================
#  גלגל נשקים (מחזיקים TAB). הזמן מאט.
#  חצי עליון = 5 מקומות לנשקים, חצי תחתון = 5 מקומות ליכולות (בקרוב).
#  מכוונים עם העכבר, משחררים TAB = בוחרים. G = לזרוק את הנשק שמסומן.
# ============================================================

var player: Node
var r_out := 200.0
var r_in := 72.0
var slow := 0.25                  # מהירות הזמן כשהגלגל פתוח

var _open := false
var _k := 0.0                     # אנימציית פתיחה 0..1
var _hover := -1                  # 0-4 נשקים, 5-9 יכולות
var _g_was := false
var _t := 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func _process(delta: float) -> void:
	var rd := delta / maxf(Engine.time_scale, 0.05)   # זמן אמיתי (לא מושפע מההאטה)
	_t += rd
	var want: bool = player != null and not player.dead and player.controllable and not get_tree().paused \
		and Input.is_physical_key_pressed(KEY_TAB)
	if want and not _open:
		_open = true
		Engine.time_scale = slow
	elif not want and _open:
		_open = false
		if _hover >= 0 and _hover < 5 and player != null:
			player.select_slot(_hover)
		if player == null or not player.boosts.has(player.PickupScript.BULLET_TIME):
			Engine.time_scale = 1.0
	if player != null:
		player.wheel_open = _open
	_k = move_toward(_k, 1.0 if _open else 0.0, rd * 7.0)
	if _open:
		var c := get_viewport().get_visible_rect().size * 0.5
		var m := get_viewport().get_mouse_position() - c
		_hover = -1
		if m.length() > r_in * 0.6:
			var ang := rad_to_deg(m.angle())   # -180..180, למעלה = שלילי
			_hover = clampi(int(floor((ang + 180.0) / 36.0)), 0, 9)
		var g := Input.is_physical_key_pressed(KEY_G)
		if g and not _g_was and _hover >= 0 and _hover < 5:
			player.drop_weapon(_hover)
		_g_was = g
	if _k > 0.0:
		queue_redraw()


func _sector(c: Vector2, a0: float, a1: float, r0: float, r1: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	var n := 10
	for i in n + 1:
		pts.append(c + Vector2.from_angle(lerpf(a0, a1, float(i) / n)) * r1)
	for i in n + 1:
		pts.append(c + Vector2.from_angle(lerpf(a1, a0, float(i) / n)) * r0)
	return pts


func _draw() -> void:
	if _k <= 0.0:
		return
	var vs := get_viewport().get_visible_rect().size
	var c := vs * 0.5
	var e := 1.0 - pow(1.0 - _k, 3.0)          # ease-out
	var a := e
	var sc := 0.7 + 0.3 * e
	var f := ThemeDB.fallback_font
	draw_rect(Rect2(Vector2.ZERO, vs), Color(0, 0, 0, 0.35 * a))
	# רקע עגול עם הילה
	for i in 6:
		draw_circle(c, (r_out + 26.0 - float(i) * 4.0) * sc, Color(0.0, 0.0, 0.0, 0.08 * a))
	draw_circle(c, (r_out + 8.0) * sc, Color(0.06, 0.06, 0.08, 0.85 * a))
	var gap := deg_to_rad(1.6)
	for i in 10:
		var a0 := deg_to_rad(-180.0 + 36.0 * float(i)) + gap
		var a1 := deg_to_rad(-180.0 + 36.0 * float(i + 1)) - gap
		var mid := (a0 + a1) * 0.5
		var hov := i == _hover
		var pop := 10.0 if hov else 0.0
		var is_w := i < 5
		var s = player.slots[i] if is_w and player != null and i < player.slots.size() else null
		var col := Color(0.16, 0.16, 0.19)
		var acc := Color(0.5, 0.5, 0.55)
		if is_w and s != null:
			acc = Game.WEAPON_COLORS[s.id]
			col = Color(0.2, 0.2, 0.24).lerp(acc, 0.12)
		if hov:
			col = col.lerp(acc, 0.45)
		if not is_w:
			col = Color(0.12, 0.12, 0.14)
		var off := Vector2.from_angle(mid) * pop * 0.5
		draw_colored_polygon(_sector(c + off, a0, a1, r_in * sc, (r_out + pop) * sc), Color(col, 0.92 * a))
		draw_polyline(_sector(c + off, a0, a1, r_in * sc, (r_out + pop) * sc), Color(acc, (0.9 if hov else 0.35) * a), 2.0 if hov else 1.0, true)
		# המקום שביד: קשת בהירה בקצה
		if is_w and player != null and i == player.cur_slot and player.weapon == player.GUN:
			draw_arc(c + off, (r_out + pop + 5.0) * sc, a0, a1, 12, Color(1, 1, 1, 0.9 * a), 3.0, true)
		var ic := c + off + Vector2.from_angle(mid) * ((r_in + r_out) * 0.5 + pop * 0.5) * sc
		if is_w:
			draw_string(f, c + off + Vector2.from_angle(mid) * (r_in + 14.0) * sc + Vector2(-4, 5), str(i + 1), HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(1, 1, 1, 0.5 * a))
			if s != null:
				_icon(ic + Vector2(0, -8), s.id, Color(acc, a), sc * (1.15 if hov else 1.0))
				var low: bool = s.ammo <= Game.AMMO_MAX[s.id] / 5
				draw_string(f, ic + Vector2(-30, 20), str(s.ammo), HORIZONTAL_ALIGNMENT_CENTER, 60, 15, Color(1.0, 0.4, 0.3, a) if low else Color(1, 1, 1, 0.85 * a))
			else:
				draw_string(f, ic + Vector2(-30, 5), "EMPTY", HORIZONTAL_ALIGNMENT_CENTER, 60, 12, Color(1, 1, 1, 0.25 * a))
		else:   # יכולות: נעול
			draw_arc(ic + Vector2(0, -6), 4.5, PI, TAU, 8, Color(1, 1, 1, 0.3 * a), 1.5, true)
			draw_rect(Rect2(ic + Vector2(-6, -6), Vector2(12, 9)), Color(1, 1, 1, 0.3 * a))
			draw_string(f, ic + Vector2(-30, 16), "LOCKED", HORIZONTAL_ALIGNMENT_CENTER, 60, 11, Color(1, 1, 1, 0.25 * a))
	# מרכז
	draw_circle(c, (r_in - 6.0) * sc, Color(0.04, 0.04, 0.05, 0.95 * a))
	draw_arc(c, (r_in - 6.0) * sc, 0.0, TAU, 40, Color(1, 1, 1, 0.15 * a), 1.0, true)
	var title := "WEAPONS"
	var sub := "TAB"
	var tcol := Color(1, 1, 1, a)
	if _hover >= 0 and _hover < 5 and player != null:
		var s = player.slots[_hover]
		if s != null:
			title = Game.WEAPON_NAMES[s.id]
			sub = "%d / %d" % [s.ammo, Game.AMMO_MAX[s.id]]
			tcol = Color(Game.WEAPON_COLORS[s.id], a)
		else:
			title = "EMPTY"
			sub = "SLOT %d" % (_hover + 1)
	elif _hover >= 5:
		title = "ABILITY"
		sub = "COMING SOON"
	draw_string(f, c + Vector2(-60, -2), title, HORIZONTAL_ALIGNMENT_CENTER, 120, 17, tcol)
	draw_string(f, c + Vector2(-60, 18), sub, HORIZONTAL_ALIGNMENT_CENTER, 120, 13, Color(1, 1, 1, 0.6 * a))
	# כותרות + עזרה
	draw_string(f, c + Vector2(-100, -(r_out + 34.0) * sc), "WEAPONS", HORIZONTAL_ALIGNMENT_CENTER, 200, 16, Color(1, 0.85, 0.5, 0.9 * a))
	draw_string(f, c + Vector2(-100, (r_out + 46.0) * sc), "ABILITIES", HORIZONTAL_ALIGNMENT_CENTER, 200, 16, Color(0.6, 0.8, 1.0, 0.7 * a))
	draw_string(f, c + Vector2(-200, (r_out + 70.0) * sc), "RELEASE TAB = EQUIP      G = DROP WEAPON", HORIZONTAL_ALIGNMENT_CENTER, 400, 13, Color(1, 1, 1, 0.5 * a))


# סמלים פשוטים לכל נשק
func _icon(p: Vector2, id: int, col: Color, s: float) -> void:
	var w := Color(0.85, 0.85, 0.9, col.a)
	match id:
		0:   # רובה
			draw_line(p + Vector2(-18, 0) * s, p + Vector2(18, 0) * s, w, 3.0 * s)
			draw_line(p + Vector2(-18, 0) * s, p + Vector2(-22, 5) * s, col, 4.0 * s)
			draw_line(p + Vector2(-2, 1) * s, p + Vector2(-3, 7) * s, w, 2.5 * s)
		1:   # שוטגאן
			draw_line(p + Vector2(-16, 0) * s, p + Vector2(14, 0) * s, w, 4.5 * s)
			draw_line(p + Vector2(-16, 0) * s, p + Vector2(-21, 5) * s, col, 5.0 * s)
			draw_line(p + Vector2(3, 3) * s, p + Vector2(10, 3) * s, col, 3.0 * s)
		2:   # קשת
			var pts := PackedVector2Array()
			for k in 9:
				var an := -1.2 + 2.4 * float(k) / 8.0
				pts.append(p + Vector2(cos(an) * 8.0 - 4.0, sin(an) * 15.0) * s)
			draw_polyline(pts, col, 2.5 * s, true)
			draw_line(pts[0], pts[8], w, 1.0)
			draw_line(p + Vector2(-6, 0) * s, p + Vector2(16, 0) * s, w, 1.5 * s)
		3:   # צלף
			draw_line(p + Vector2(-20, 0) * s, p + Vector2(22, 0) * s, w, 2.5 * s)
			draw_line(p + Vector2(-4, -4) * s, p + Vector2(8, -4) * s, col, 3.5 * s)
			draw_line(p + Vector2(-20, 0) * s, p + Vector2(-23, 5) * s, col, 4.0 * s)
		4:   # טייזר
			draw_line(p + Vector2(-12, 0) * s, p + Vector2(10, 0) * s, w, 4.0 * s)
			for k in 3:
				draw_circle(p + Vector2(12 + k * 3, 0) * s, 2.5 * s, col)
			draw_line(p + Vector2(-6, 1) * s, p + Vector2(-8, 7) * s, w, 2.5 * s)
