extends Node2D
const Arsenal := preload("res://progression/arsenal.gd")
const Sfx := preload("res://sfx.gd")   # אפקטים קוליים
const AbilityDB := preload("res://abilities/ability_db.gd")
const Upgrades := preload("res://progression/upgrade_db.gd")
# ============================================================
#  גלגל נשקים / יכולות (מחזיקים Q). הזמן מאט.
#  שני עמודים נפרדים: WEAPONS / ABILITIES (5 מקומות בכל אחד).
#  מחליפים עמוד: TAB, גלגלת העכבר, או לחיצה על הלשונית.
#  מכוונים עם העכבר, משחררים Q = בוחרים. קליק ימני / G = לזרוק נשק.
#  בנוסף: בר הנשקים בפינה (עם אנימציה כשמחליפים נשק).
# ============================================================

var player: Node
var r_out := 190.0
var r_in := 70.0
var slow := 0.25                  # מהירות הזמן כשהגלגל פתוח

var _open := false
var _k := 0.0                     # אנימציית פתיחה 0..1
var _page := 0                    # 0 = נשקים, 1 = יכולות
var _page_k := 0.0                # אנימציית החלפת עמוד
var _hover := -1                  # 0-4
var _g_was := false
var _tab_was := false
var _t := 0.0
# בר הנשקים
var _bar_x := 0.0                 # מיקום הסימון (זז בהחלקה)
var _last_slot := -1
var _last_weapon := -1
var _pop := 0.0                   # "קפיצה" של הנשק שנבחר
var _shine := 1.0                 # פס אור שעובר על הנשק שנבחר
var _name_t := 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func _process(delta: float) -> void:
	var rd := delta / maxf(Engine.time_scale, 0.05)   # זמן אמיתי (לא מושפע מההאטה)
	_t += rd
	var want: bool = player != null and not player.dead and player.controllable and not get_tree().paused \
		and Input.is_physical_key_pressed(KEY_Q)
	if want and not _open:
		_open = true
		Engine.time_scale = slow
		Sfx.play("whoosh", null, -4.0)
	elif not want and _open:
		_open = false
		if _page == 0 and _hover >= 0 and player != null:
			player.select_slot(_hover)
		elif _page == 1 and _hover >= 0 and player != null and player.abilities != null:
			player.abilities.select(_hover)
		if player == null or not player.boosts.has(player.PickupScript.BULLET_TIME):
			Engine.time_scale = 1.0
	if player != null:
		player.wheel_open = _open
	_k = move_toward(_k, 1.0 if _open else 0.0, rd * 7.0)
	_page_k = move_toward(_page_k, float(_page), rd * 8.0)
	if _open:
		var c := get_viewport().get_visible_rect().size * 0.5
		var m := get_viewport().get_mouse_position() - c
		_hover = -1
		if m.length() > r_in * 0.6 and m.length() < r_out + 60.0:
			_hover = int(floor(fposmod(rad_to_deg(m.angle()) + 126.0, 360.0) / 72.0)) % 5
		var tab := Input.is_physical_key_pressed(KEY_TAB)
		if tab and not _tab_was:
			_page = 1 - _page
			Sfx.play("ui", null)
		_tab_was = tab
		var g := Input.is_physical_key_pressed(KEY_G)
		if g and not _g_was:
			_drop_hovered()
		_g_was = g
	# בר הנשקים
	if player != null:
		if player.cur_slot != _last_slot or player.weapon != _last_weapon:
			if _last_slot >= 0:
				_pop = 1.0
				_shine = 0.0
				_name_t = 1.4
			_last_slot = player.cur_slot
			_last_weapon = player.weapon
		_bar_x = lerpf(_bar_x, float(player.cur_slot), minf(rd * 14.0, 1.0))
		_pop = move_toward(_pop, 0.0, rd * 3.0)
		_shine = move_toward(_shine, 1.0, rd * 1.8)
		_name_t -= rd
	queue_redraw()   # תמיד מציירים מחדש (כך הגלגל נעלם לגמרי כשסוגרים)


func _input(event: InputEvent) -> void:
	if not _open or not (event is InputEventMouseButton) or not event.pressed:
		return
	match event.button_index:
		MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN:
			_page = 1 - _page
			Sfx.play("ui", null)
		MOUSE_BUTTON_RIGHT:
			_drop_hovered()
		MOUSE_BUTTON_LEFT:
			var c := get_viewport().get_visible_rect().size * 0.5
			if _page == 1:   # מיני-תפריט: יכולת מהמאגר -> למקום הנבחר
				var res := _reserve()
				for k in mini(res.size(), RES_MAX):
					if _res_rect(c, k, mini(res.size(), RES_MAX)).has_point(event.position):
						_swap_in(str(res[_res_page * RES_MAX + k]) if _res_page * RES_MAX + k < res.size() else "")
						get_viewport().set_input_as_handled()
						return
				if res.size() > RES_MAX:
					var n := mini(res.size(), RES_MAX)
					if _res_rect(c, -1, n).has_point(event.position) or _res_rect(c, n, n).has_point(event.position):
						_res_page = (_res_page + 1) % int(ceil(float(res.size()) / float(RES_MAX)))
						get_viewport().set_input_as_handled()
						return
			for i in 2:   # לחיצה על לשונית
				if _tab_rect(c, i).has_point(event.position):
					_page = i
					return
			if _page == 0 and _hover >= 0:
				player.select_slot(_hover)
			elif _page == 1 and _hover >= 0 and player.abilities != null:
				player.abilities.select(_hover)
	get_viewport().set_input_as_handled()


func _drop_hovered() -> void:
	if _page == 0 and _hover >= 0 and player != null:
		player.drop_weapon(_hover)


func _tab_rect(c: Vector2, i: int) -> Rect2:
	return Rect2(c + Vector2(-150.0 + 154.0 * float(i), -r_out - 78.0), Vector2(146.0, 34.0))


func _sector(c: Vector2, a0: float, a1: float, r0: float, r1: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	var n := 14
	for i in n + 1:
		pts.append(c + Vector2.from_angle(lerpf(a0, a1, float(i) / n)) * r1)
	for i in n + 1:
		pts.append(c + Vector2.from_angle(lerpf(a1, a0, float(i) / n)) * r0)
	return pts


func _draw() -> void:
	_draw_bar()
	if _k <= 0.001:
		return
	var vs := get_viewport().get_visible_rect().size
	var c := vs * 0.5
	var e := 1.0 - pow(1.0 - _k, 3.0)          # ease-out
	var a := e
	var sc := 0.7 + 0.3 * e
	var f := ThemeDB.fallback_font
	draw_rect(Rect2(Vector2.ZERO, vs), Color(0, 0, 0, 0.4 * a))
	# לשוניות
	var names := ["WEAPONS", "ABILITIES"]
	var tab_cols := [Color(1.0, 0.75, 0.35), Color(0.45, 0.75, 1.0)]
	for i in 2:
		var r := _tab_rect(c, i)
		var on := i == _page
		var sb := StyleBoxFlat.new()
		sb.set_corner_radius_all(17)
		sb.bg_color = Color(tab_cols[i], 0.85 * a) if on else Color(0.1, 0.1, 0.12, 0.85 * a)
		sb.border_color = Color(tab_cols[i], a)
		sb.set_border_width_all(2)
		draw_style_box(sb, r)
		draw_string(f, r.position + Vector2(0, 23), names[i], HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 16, Color(0.05, 0.05, 0.07, a) if on else Color(tab_cols[i], 0.8 * a))
	draw_string(f, c + Vector2(-150, -r_out - 88.0), "TAB / WHEEL", HORIZONTAL_ALIGNMENT_CENTER, 300, 11, Color(1, 1, 1, 0.4 * a))
	# הגלגל (מסתובב קצת כשמחליפים עמוד)
	var spin := (_page_k - float(_page)) * 1.2
	var acc_page: Color = tab_cols[_page]
	for i in 6:
		draw_circle(c, (r_out + 28.0 - float(i) * 4.0) * sc, Color(acc_page, 0.035 * a))
	draw_circle(c, (r_out + 8.0) * sc, Color(0.05, 0.05, 0.07, 0.9 * a))
	var gap := deg_to_rad(1.8)
	for i in 5:
		var a0 := deg_to_rad(-126.0 + 72.0 * float(i)) + gap + spin
		var a1 := deg_to_rad(-126.0 + 72.0 * float(i + 1)) - gap + spin
		var mid := (a0 + a1) * 0.5
		var hov := i == _hover
		var pop := 12.0 if hov else 0.0
		var s = player.slots[i] if _page == 0 and player != null and i < player.slots.size() else null
		var acc := Color(0.45, 0.45, 0.5)
		var col := Color(0.14, 0.14, 0.17)
		if s != null:
			acc = Game.WEAPON_COLORS[s.id]
			col = Color(0.17, 0.17, 0.2).lerp(acc, 0.1)
		if hov:
			col = col.lerp(acc if s != null else acc_page, 0.35)
		var off := Vector2.from_angle(mid) * pop * 0.5
		var seg := _sector(c + off, a0, a1, r_in * sc, (r_out + pop) * sc)
		draw_colored_polygon(seg, Color(col, 0.93 * a))
		seg.append(seg[0])
		draw_polyline(seg, Color(acc, (0.95 if hov else 0.3) * a), 2.0 if hov else 1.0, true)
		if _page == 0 and player != null and i == player.cur_slot and player.weapon == player.GUN:
			draw_arc(c + off, (r_out + pop + 6.0) * sc, a0, a1, 16, Color(1, 1, 1, 0.95 * a), 3.0, true)
		var ic := c + off + Vector2.from_angle(mid) * ((r_in + r_out) * 0.52 + pop * 0.4) * sc
		draw_string(f, c + off + Vector2.from_angle(mid) * (r_in + 13.0) * sc + Vector2(-4, 5), str(i + 1), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(1, 1, 1, 0.45 * a))
		if _page == 0:
			if s != null:
				draw_weapon(self, ic + Vector2(0, -6), s.id, sc * (1.25 if hov else 1.05), a)
				var low: bool = s.ammo <= Upgrades.ammo_max(s.id) / 5
				draw_string(f, ic + Vector2(-30, 24), str(s.ammo), HORIZONTAL_ALIGNMENT_CENTER, 60, 15, Color(1.0, 0.4, 0.3, a) if low else Color(1, 1, 1, 0.85 * a))
				if hov:   # כפתור זריקה
					draw_string(f, ic + Vector2(-40, 40), "RMB/G: DROP", HORIZONTAL_ALIGNMENT_CENTER, 80, 10, Color(1.0, 0.5, 0.4, 0.9 * a))
			else:
				draw_string(f, ic + Vector2(-30, 5), "EMPTY", HORIZONTAL_ALIGNMENT_CENTER, 60, 12, Color(1, 1, 1, 0.25 * a))
		else:   # יכולות
			var ab: String = player.abilities.slot(i) if player != null and player.abilities != null else ""
			if ab != "":
				AbilityDB.draw_icon(self, ic + Vector2(0, -4), ab, sc * (1.35 if hov else 1.1), a)
				var ck: float = player.abilities.cooldown_k(ab)
				if ck > 0.0:
					draw_arc(ic + Vector2(0, -4), 17.0 * sc, -PI / 2.0, -PI / 2.0 + TAU * ck, 20, Color(1, 1, 1, 0.5 * a), 3.0, true)
				if i == player.abilities.cur:
					draw_arc(c + off, (r_out + pop + 6.0) * sc, a0, a1, 16, Color(1, 1, 1, 0.95 * a), 3.0, true)
			else:
				draw_string(f, ic + Vector2(-30, 5), "EMPTY", HORIZONTAL_ALIGNMENT_CENTER, 60, 12, Color(1, 1, 1, 0.25 * a))
	# מרכז
	draw_circle(c, (r_in - 6.0) * sc, Color(0.03, 0.03, 0.04, 0.96 * a))
	draw_arc(c, (r_in - 6.0) * sc, 0.0, TAU, 40, Color(acc_page, 0.35 * a), 1.5, true)
	var title: String = names[_page]
	var sub := "HOLD Q"
	var tcol := Color(1, 1, 1, a)
	if _hover >= 0 and _page == 0 and player != null:
		var s = player.slots[_hover]
		if s != null:
			title = Game.WEAPON_NAMES[s.id]
			sub = "%d / %d" % [s.ammo, Upgrades.ammo_max(s.id)]
			tcol = Color(Game.WEAPON_COLORS[s.id], a)
		else:
			title = "EMPTY"
			sub = "SLOT %d" % (_hover + 1)
	elif _hover >= 0 and player != null and player.abilities != null:
		var ab: String = player.abilities.slot(_hover)
		if ab != "":
			title = str(AbilityDB.val(ab, "name", ""))
			sub = "PASSIVE" if AbilityDB.val(ab, "passive", false) else ("READY  [C]" if player.abilities.cooldown_left(ab) <= 0.0 else "%.1fs" % player.abilities.cooldown_left(ab))
			tcol = Color(AbilityDB.val(ab, "color", Color.WHITE), a)
		else:
			title = "EMPTY"
			sub = "UNLOCK IN LATER STAGES"
	draw_string(f, c + Vector2(-60, -2), title, HORIZONTAL_ALIGNMENT_CENTER, 120, 16, tcol)
	draw_string(f, c + Vector2(-60, 17), sub, HORIZONTAL_ALIGNMENT_CENTER, 120, 12, Color(1, 1, 1, 0.6 * a))
	if _page == 1:
		_draw_reserve(c, a)
	draw_string(f, c + Vector2(-200, (r_out + 42.0) * sc), ("RELEASE Q = SELECT      CLICK BELOW = SWAP IN" if _page == 1 else "RELEASE Q = EQUIP      RMB / G = DROP"), HORIZONTAL_ALIGNMENT_CENTER, 400, 13, Color(1, 1, 1, 0.5 * a))


# ---- בר הנשקים בפינה: 5 קופסאות, הנבחר מורם וזוהר ----
func _draw_bar() -> void:
	if player == null or player.slots.is_empty():
		return
	var f := ThemeDB.fallback_font
	var org := Vector2(14.0, 66.0)
	var bw := 58.0
	var bh := 36.0
	var sp := 6.0
	# רקע
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0, 0, 0, 0.35)
	bg.set_corner_radius_all(10)
	draw_style_box(bg, Rect2(org - Vector2(6, 6), Vector2(5.0 * (bw + sp) + 6.0 + 52.0, bh + 20.0)))
	# סימון זז (מחליק לנשק הנבחר)
	var gun_on: bool = player.weapon == player.GUN
	if gun_on:
		var hx := org.x + _bar_x * (bw + sp)
		var s = player.slots[player.cur_slot]
		var hc: Color = Game.WEAPON_COLORS[s.id] if s != null else Color.WHITE
		for i in 3:
			draw_rect(Rect2(hx - 3.0 - float(i) * 2.0, org.y - 3.0 - float(i) * 2.0, bw + 6.0 + float(i) * 4.0, bh + 6.0 + float(i) * 4.0), Color(hc, 0.12 - float(i) * 0.03), false, 2.0)
		draw_rect(Rect2(hx, org.y + bh + 4.0, bw, 3.0), hc)
	for i in 5:
		var s = player.slots[i] if i < player.slots.size() else null
		var cur: bool = i == player.cur_slot and gun_on
		var lift := (4.0 + 5.0 * sin(_pop * PI)) if cur else 0.0
		var r := Rect2(org + Vector2(float(i) * (bw + sp), -lift), Vector2(bw, bh))
		var sb := StyleBoxFlat.new()
		sb.set_corner_radius_all(7)
		if s == null:
			sb.bg_color = Color(1, 1, 1, 0.04)
			sb.border_color = Color(1, 1, 1, 0.12)
			sb.set_border_width_all(1)
		else:
			var wc: Color = Game.WEAPON_COLORS[s.id]
			sb.bg_color = Color(0.1, 0.1, 0.12, 0.9).lerp(wc, 0.18 if cur else 0.05)
			sb.border_color = Color(wc, 0.95 if cur else 0.35)
			sb.set_border_width_all(2 if cur else 1)
		draw_style_box(sb, r)
		draw_string(f, r.position + Vector2(4, 11), str(i + 1), HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(1, 1, 1, 0.45))
		if s != null:
			var wob := sin(_pop * TAU * 2.0) * 0.12 * _pop if cur else 0.0
			draw_set_transform(r.get_center() + Vector2(0, -3), wob, Vector2.ONE)
			draw_weapon(self, Vector2.ZERO, s.id, (0.62 + 0.12 * _pop) if cur else 0.55, 1.0 if cur else 0.6)
			draw_set_transform_matrix(Transform2D.IDENTITY)
			# פס תחמושת
			var k := float(s.ammo) / float(Upgrades.ammo_max(s.id))
			draw_rect(Rect2(r.position + Vector2(5, bh - 6), Vector2(bw - 10, 3)), Color(0, 0, 0, 0.5))
			draw_rect(Rect2(r.position + Vector2(5, bh - 6), Vector2((bw - 10) * k, 3)), Color(1.0, 0.35, 0.3) if k < 0.2 else Color(Game.WEAPON_COLORS[s.id], 0.9))
			draw_string(f, r.position + Vector2(0, 11), str(s.ammo), HORIZONTAL_ALIGNMENT_RIGHT, bw - 4, 10, Color(1, 1, 1, 0.8 if cur else 0.45))
			# פס אור שעובר אחרי החלפה
			if cur and _shine < 1.0:
				var sx := r.position.x + (bw + 30.0) * _shine - 15.0
				draw_colored_polygon(PackedVector2Array([Vector2(sx, r.position.y), Vector2(sx + 10, r.position.y), Vector2(sx - 2, r.end.y), Vector2(sx - 12, r.end.y)]), Color(1, 1, 1, 0.35 * (1.0 - _shine)))
	# רימונים
	var gr := Rect2(org + Vector2(5.0 * (bw + sp), 0.0), Vector2(44.0, bh))
	var gsb := StyleBoxFlat.new()
	gsb.set_corner_radius_all(7)
	gsb.bg_color = Color(0.1, 0.12, 0.08, 0.9)
	gsb.border_color = Color(0.55, 0.65, 0.3, 0.95 if not gun_on else 0.35)
	gsb.set_border_width_all(2 if not gun_on else 1)
	draw_style_box(gsb, gr)
	# פריט נפץ (SPECIAL): רימון / מולוטוב / משגר. ריק = מקום אפור
	if player.special == "":
		draw_string(f, gr.position + Vector2(0, 24), "-", HORIZONTAL_ALIGNMENT_CENTER, 44, 14, Color(1, 1, 1, 0.3))
	else:
		var swid: int = int(Arsenal.SPECIALS[player.special].weapon)
		if swid < 0:
			draw_circle(gr.get_center() + Vector2(-6, 0), 6.0, Color("5d7030"))
			draw_rect(Rect2(gr.get_center() + Vector2(-8, -9), Vector2(4, 4)), Color("9a9aa2"))
		else:
			draw_weapon(self, gr.get_center() + Vector2(-2, 0), swid, 0.42)
		draw_string(f, gr.position + Vector2(0, 24), "x%d" % player.special_uses, HORIZONTAL_ALIGNMENT_RIGHT, 40, 13, Color.WHITE)
	draw_string(f, gr.position + Vector2(3, 11), "E", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(1, 1, 1, 0.45))
	_draw_ability_bar(Vector2(org.x, org.y + bh + 30.0))
	# שם הנשק קופץ אחרי החלפה
	if _name_t > 0.0 and gun_on and player.slots[player.cur_slot] != null:
		var id: int = player.slots[player.cur_slot].id
		var al := clampf(_name_t, 0.0, 1.0)
		var px := org.x + _bar_x * (bw + sp) + bw * 0.5
		draw_string_outline(f, Vector2(px - 60.0, org.y + bh + 24.0 - 4.0 * _pop), Game.WEAPON_NAMES[id], HORIZONTAL_ALIGNMENT_CENTER, 120, 15, 4, Color(0, 0, 0, 0.7 * al))
		draw_string(f, Vector2(px - 60.0, org.y + bh + 24.0 - 4.0 * _pop), Game.WEAPON_NAMES[id], HORIZONTAL_ALIGNMENT_CENTER, 120, 15, Color(Game.WEAPON_COLORS[id], al))


# ============================================================
#  ציורי נשקים "מציאותיים" (פונים ימינה, רוחב ~64 ביחידות s=1)
# ============================================================
static func draw_weapon(ci: CanvasItem, p: Vector2, id: int, s: float, alpha := 1.0) -> void:
	var metal := Color(0.16, 0.16, 0.19, alpha)
	var steel := Color(0.36, 0.37, 0.41, alpha)
	var hi := Color(0.75, 0.77, 0.82, 0.55 * alpha)
	var wood := Color(0.42, 0.25, 0.13, alpha)
	var wood_hi := Color(0.62, 0.4, 0.22, alpha)
	var poly := func(pts: Array, col: Color) -> void:
		var arr := PackedVector2Array()
		for q in pts:
			arr.append(p + q * s)
		ci.draw_colored_polygon(arr, col)
		arr.append(arr[0])
		ci.draw_polyline(arr, Color(0, 0, 0, 0.7 * alpha), 1.0, true)
	var ln := func(a: Vector2, b: Vector2, col: Color, w: float) -> void:
		ci.draw_line(p + a * s, p + b * s, col, maxf(w * s, 1.0), true)
	match id:
		0:   # רובה סער: קת עץ, מחסנית מעוקלת, קנה עם כוונת
			poly.call([Vector2(-32, -2), Vector2(-14, -4), Vector2(-14, 3), Vector2(-30, 8)], wood)
			poly.call([Vector2(-14, -5), Vector2(10, -5), Vector2(10, 2), Vector2(-14, 3)], metal)
			poly.call([Vector2(10, -4), Vector2(22, -4), Vector2(22, 1), Vector2(10, 1)], wood)
			poly.call([Vector2(-4, 2), Vector2(2, 2), Vector2(6, 13), Vector2(1, 14)], metal)          # מחסנית
			poly.call([Vector2(-11, 2), Vector2(-7, 2), Vector2(-9, 9), Vector2(-13, 8)], metal)      # ידית
			ln.call(Vector2(22, -2.5), Vector2(34, -2.5), steel, 2.2)
			ln.call(Vector2(30, -2.5), Vector2(30, -6.5), steel, 1.5)
			ln.call(Vector2(-12, -3.5), Vector2(8, -3.5), hi, 0.8)
			ln.call(Vector2(-28, 0), Vector2(-16, -2), Color(wood_hi, 0.6 * alpha), 0.8)
		1:   # שוטגאן: קת עץ, קנה כפול ומשאבה
			poly.call([Vector2(-32, -1), Vector2(-12, -4), Vector2(-12, 3), Vector2(-30, 9)], wood)
			poly.call([Vector2(-12, -5), Vector2(4, -5), Vector2(4, 3), Vector2(-12, 3)], metal)
			ln.call(Vector2(4, -3), Vector2(34, -3), steel, 3.4)
			ln.call(Vector2(4, 1.5), Vector2(28, 1.5), metal, 3.0)
			poly.call([Vector2(10, -1), Vector2(22, -1), Vector2(22, 5), Vector2(10, 5)], wood)        # משאבה
			for k in 3:
				ln.call(Vector2(12 + k * 4, -1), Vector2(12 + k * 4, 5), Color(0, 0, 0, 0.4 * alpha), 0.8)
			poly.call([Vector2(-9, 3), Vector2(-5, 3), Vector2(-7, 9), Vector2(-11, 8)], metal)
			ln.call(Vector2(4, -4.5), Vector2(32, -4.5), hi, 0.8)
		2:   # קשת רקורב + חץ
			var arc := []
			for k in 13:
				var an := -1.25 + 2.5 * float(k) / 12.0
				arc.append(Vector2(-8.0 + cos(an) * 10.0 - absf(sin(an)) * 3.0, sin(an) * 20.0))
			for k in 12:
				ln.call(arc[k], arc[k + 1], wood, 3.0 - absf(float(k) - 6.0) * 0.25)
			ln.call(arc[0], arc[0] + Vector2(-3, -2), wood_hi, 1.6)
			ln.call(arc[12], arc[12] + Vector2(-3, 2), wood_hi, 1.6)
			ln.call(arc[0], arc[12], Color(0.9, 0.9, 0.85, 0.8 * alpha), 0.8)                       # מיתר
			ln.call(Vector2(-10, 0), Vector2(26, 0), Color(0.55, 0.42, 0.26, alpha), 1.6)            # חץ
			poly.call([Vector2(26, -2.5), Vector2(32, 0), Vector2(26, 2.5)], steel)
			poly.call([Vector2(-12, 0), Vector2(-7, -3), Vector2(-4, -3), Vector2(-8, 0)], Color(0.8, 0.25, 0.2, alpha))
			poly.call([Vector2(-12, 0), Vector2(-7, 3), Vector2(-4, 3), Vector2(-8, 0)], Color(0.8, 0.25, 0.2, alpha))
		3:   # צלף: קנה ארוך, כוונת טלסקופית, דו-רגל
			poly.call([Vector2(-34, -2), Vector2(-14, -3), Vector2(-14, 3), Vector2(-20, 3), Vector2(-24, 8), Vector2(-33, 7)], Color(0.24, 0.27, 0.2, alpha))
			poly.call([Vector2(-14, -4), Vector2(6, -4), Vector2(6, 2), Vector2(-14, 3)], metal)
			ln.call(Vector2(6, -2), Vector2(40, -2), steel, 2.2)
			poly.call([Vector2(-10, -11), Vector2(6, -11), Vector2(8, -9), Vector2(8, -6), Vector2(-12, -6), Vector2(-12, -9)], metal)   # כוונת
			ci.draw_circle(p + Vector2(8.5, -8.5) * s, 2.0 * s, Color(0.45, 0.8, 1.0, 0.9 * alpha))
			ln.call(Vector2(-4, -6), Vector2(-4, -4), metal, 2.0)
			ln.call(Vector2(-10, -2), Vector2(-6, -6), steel, 1.4)                                    # בריח
			ln.call(Vector2(18, 0), Vector2(14, 9), steel, 1.2)                                       # דו-רגל
			ln.call(Vector2(18, 0), Vector2(22, 9), steel, 1.2)
			ln.call(Vector2(-12, -10), Vector2(5, -10), hi, 0.8)
		4:   # טייזר: אקדח צהוב-שחור עם מחסנית חשמל
			poly.call([Vector2(-16, -6), Vector2(14, -6), Vector2(16, -3), Vector2(16, 3), Vector2(-16, 3)], Color(0.92, 0.78, 0.15, alpha))
			poly.call([Vector2(-14, 3), Vector2(-4, 3), Vector2(-7, 15), Vector2(-16, 14)], metal)    # ידית
			poly.call([Vector2(16, -5), Vector2(24, -5), Vector2(24, 3), Vector2(16, 3)], metal)      # מחסנית
			ln.call(Vector2(-12, -5), Vector2(12, -5), Color(1, 1, 1, 0.4 * alpha), 0.8)
			ln.call(Vector2(-3, 3), Vector2(-1, 8), metal, 1.4)                                       # הדק
			for k in 2:
				ci.draw_circle(p + Vector2(25, -3 + k * 4) * s, 1.4 * s, Color(0.75, 0.6, 1.0, alpha))
			ci.draw_circle(p + Vector2(10, -1.5) * s, 1.6 * s, Color(1.0, 0.25, 0.2, alpha))           # נורית
		5:   # אקדח: מחליק, ידית וקנה קצר
			poly.call([Vector2(-12, -6), Vector2(14, -6), Vector2(14, 0), Vector2(-12, 0)], metal)
			poly.call([Vector2(-11, 0), Vector2(-2, 0), Vector2(-5, 14), Vector2(-14, 13)], Color(0.22, 0.18, 0.16, alpha))   # ידית
			ln.call(Vector2(-2, 0), Vector2(1, 5), metal, 1.4)
			for k in 4:
				ln.call(Vector2(-8 + k * 3, -6), Vector2(-8 + k * 3, -2), Color(0, 0, 0, 0.45 * alpha), 0.7)
			ln.call(Vector2(-10, -5), Vector2(12, -5), hi, 0.8)
		6:   # SMG: גוף קצר, מחסנית ישרה ארוכה, קת מתקפלת
			poly.call([Vector2(-14, -5), Vector2(14, -5), Vector2(14, 2), Vector2(-14, 2)], metal)
			ln.call(Vector2(14, -2), Vector2(24, -2), steel, 2.4)
			poly.call([Vector2(2, 2), Vector2(7, 2), Vector2(7, 18), Vector2(2, 18)], metal)       # מחסנית
			poly.call([Vector2(-9, 2), Vector2(-4, 2), Vector2(-6, 10), Vector2(-11, 9)], metal)   # ידית
			ln.call(Vector2(-14, -3), Vector2(-28, -3), steel, 1.4)                                  # קת
			ln.call(Vector2(-28, -3), Vector2(-28, 4), steel, 1.4)
			ln.call(Vector2(-12, -4), Vector2(12, -4), hi, 0.8)
		7:   # רובה סער: גוף ארוך, מחסנית מעוקלת, ידית נשיאה, קת סינתטית
			poly.call([Vector2(-34, -3), Vector2(-14, -4), Vector2(-14, 3), Vector2(-33, 7)], Color(0.2, 0.22, 0.18, alpha))
			poly.call([Vector2(-14, -5), Vector2(12, -5), Vector2(12, 2), Vector2(-14, 3)], metal)
			poly.call([Vector2(12, -4), Vector2(24, -4), Vector2(24, 1), Vector2(12, 1)], Color(0.2, 0.22, 0.18, alpha))
			ln.call(Vector2(24, -2.5), Vector2(36, -2.5), steel, 2.0)
			poly.call([Vector2(-2, 2), Vector2(4, 2), Vector2(9, 14), Vector2(3, 15)], metal)         # מחסנית
			poly.call([Vector2(-10, -5), Vector2(4, -5), Vector2(4, -9), Vector2(-10, -9)], metal)   # ידית נשיאה
			poly.call([Vector2(-10, 2), Vector2(-6, 2), Vector2(-8, 9), Vector2(-12, 8)], metal)
			ln.call(Vector2(-12, -4), Vector2(10, -4), hi, 0.8)
		8:   # בקבוק תבערה: בקבוק ירוק, נוזל כתום, סמרטוט בוער
			poly.call([Vector2(-8, -12), Vector2(8, -12), Vector2(9, 14), Vector2(-9, 14)], Color(0.3, 0.5, 0.28, 0.85 * alpha))
			poly.call([Vector2(-8, 0), Vector2(8, 0), Vector2(9, 14), Vector2(-9, 14)], Color(0.95, 0.55, 0.12, 0.8 * alpha))
			poly.call([Vector2(-3, -20), Vector2(3, -20), Vector2(3, -12), Vector2(-3, -12)], Color(0.3, 0.5, 0.28, 0.85 * alpha))
			ln.call(Vector2(0, -20), Vector2(4, -27), Color(0.85, 0.78, 0.6, alpha), 2.0)
			ci.draw_circle(p + Vector2(5, -29) * s, 4.0 * s, Color(1.0, 0.55, 0.15, 0.85 * alpha))
			ci.draw_circle(p + Vector2(5, -30) * s, 2.0 * s, Color(1.0, 0.9, 0.5, alpha))
		9:   # משגר רימונים: קנה עבה, תוף מסתובב, קת
			poly.call([Vector2(-30, -2), Vector2(-14, -4), Vector2(-14, 4), Vector2(-28, 8)], Color(0.24, 0.27, 0.2, alpha))
			poly.call([Vector2(-14, -7), Vector2(30, -7), Vector2(30, 3), Vector2(-14, 3)], Color(0.3, 0.36, 0.24, alpha))
			ci.draw_circle(p + Vector2(-4, 4) * s, 8.0 * s, metal)
			for k in 6:
				var an := TAU * float(k) / 6.0
				ci.draw_circle(p + (Vector2(-4, 4) + Vector2.from_angle(an) * 5.0) * s, 1.6 * s, Color(0.5, 0.55, 0.4, alpha))
			ci.draw_circle(p + Vector2(30, -2) * s, 3.0 * s, Color(0, 0, 0, 0.8 * alpha))
			ln.call(Vector2(-12, -6), Vector2(28, -6), hi, 0.8)
		10:   # שוטגאן אוטומטי: גוף מרובע, מחסנית תוף, קנה עבה
			poly.call([Vector2(-32, -2), Vector2(-14, -5), Vector2(-14, 3), Vector2(-30, 8)], Color(0.2, 0.2, 0.22, alpha))
			poly.call([Vector2(-14, -6), Vector2(10, -6), Vector2(10, 4), Vector2(-14, 4)], metal)
			ln.call(Vector2(10, -3), Vector2(36, -3), steel, 3.6)
			ln.call(Vector2(10, 2), Vector2(28, 2), metal, 2.6)
			ci.draw_circle(p + Vector2(-2, 10) * s, 7.0 * s, metal)                                    # תוף
			ci.draw_circle(p + Vector2(-2, 10) * s, 2.5 * s, steel)
			poly.call([Vector2(-11, 4), Vector2(-7, 4), Vector2(-9, 11), Vector2(-13, 10)], metal)
			ln.call(Vector2(10, -4.5), Vector2(34, -4.5), Color(1.0, 0.35, 0.2, 0.7 * alpha), 0.8)
		11:   # משגר טילים: צינור ירוק, ידיות, כוונת, ראש נפץ אדום
			var tube := Color(0.29, 0.35, 0.23, alpha)
			poly.call([Vector2(-34, -6), Vector2(28, -6), Vector2(28, 3), Vector2(-34, 3)], tube)
			ln.call(Vector2(-32, -4.5), Vector2(26, -4.5), hi, 1.0)
			poly.call([Vector2(-38, -8), Vector2(-33, -8), Vector2(-33, 5), Vector2(-38, 5)], metal)
			poly.call([Vector2(24, -7.5), Vector2(30, -7.5), Vector2(30, 4.5), Vector2(24, 4.5)], metal)
			poly.call([Vector2(-10, 3), Vector2(-5, 3), Vector2(-6, 12), Vector2(-11, 12)], metal)
			poly.call([Vector2(6, 3), Vector2(10, 3), Vector2(9.5, 9), Vector2(5.5, 9)], metal)
			poly.call([Vector2(-4, -6), Vector2(4, -6), Vector2(4, -11), Vector2(-4, -11)], metal)
			poly.call([Vector2(30, -5), Vector2(38, -1.5), Vector2(30, 2)], Color(0.75, 0.23, 0.16, alpha))


# ---- בר היכולות (מתחת לבר הנשקים): 5 קופסאות קטנות, טעינה מסתובבת, C = הפעלה ----
func _draw_ability_bar(org: Vector2) -> void:
	if player == null or player.abilities == null:
		return
	var ab = player.abilities
	var any := false
	for i in 5:
		if ab.slot(i) != "":
			any = true
	if not any:
		return
	var f := ThemeDB.fallback_font
	var bs := 30.0
	for i in 5:
		var id: String = ab.slot(i)
		var r := Rect2(org + Vector2(float(i) * (bs + 5.0), 0.0), Vector2(bs, bs))
		var sb := StyleBoxFlat.new()
		sb.set_corner_radius_all(6)
		var cur: bool = i == ab.cur
		if id == "":
			sb.bg_color = Color(1, 1, 1, 0.03)
			sb.border_color = Color(1, 1, 1, 0.08)
			sb.set_border_width_all(1)
			draw_style_box(sb, r)
			continue
		var col: Color = AbilityDB.val(id, "color", Color.WHITE)
		sb.bg_color = Color(0.08, 0.08, 0.1, 0.9).lerp(col, 0.15 if cur else 0.04)
		sb.border_color = Color(col, 0.95 if cur else 0.35)
		sb.set_border_width_all(2 if cur else 1)
		draw_style_box(sb, r)
		var ck: float = ab.cooldown_k(id)
		AbilityDB.draw_icon(self, r.get_center(), id, 0.75, 1.0 if ck <= 0.0 else 0.35)
		if ck > 0.0:   # טעינה: חלק כהה שיורד
			draw_rect(Rect2(r.position, Vector2(bs, bs * ck)), Color(0, 0, 0, 0.55))
		if ab.is_active(id):
			draw_rect(r.grow(2.0), Color(col, 0.6 + 0.3 * sin(_t * 10.0)), false, 2.0)
		draw_string(f, r.position + Vector2(2, 9), str((i + 6) % 10), HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color(1, 1, 1, 0.4))
	draw_string(f, org + Vector2(5.0 * (bs + 5.0) + 4.0, 20.0), "C", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(1, 1, 1, 0.6))


# ============================================================
#  מיני-תפריט יכולות (עמוד ABILITIES): כל היכולות שנפתחו ולא נמצאות ב-5 המקומות.
#  לחיצה על יכולת = נכנסת למקום הנבחר (המסומן בגלגל), והיכולת שהייתה שם חוזרת למאגר.
#  יותר מ-8 יכולות? החיצים בצדדים מחליפים דף (מוכן ל-24 יכולות).
# ============================================================
const RES_MAX := 8
var _res_page := 0


func _reserve() -> Array:
	var out := []
	for id in AbilityDB.unlocked(Game.reached_level()):
		if not id in Game.ability_slots:
			out.append(id)
	return out


# k = מקום בשורה (-1 / n = חיצי דפים)
func _res_rect(c: Vector2, k: int, n: int) -> Rect2:
	var w := 46.0
	var gap := 8.0
	var total := float(n) * (w + gap) - gap
	return Rect2(Vector2(c.x - total * 0.5 + float(k) * (w + gap), c.y + r_out + 82.0), Vector2(w, w))


func _swap_in(id: String) -> void:
	if id == "" or player == null or player.abilities == null:
		return
	var ab = player.abilities
	while Game.ability_slots.size() < 5:
		Game.ability_slots.append(null)
	var slot_i: int = ab.cur
	if Game.ability_slots[slot_i] != null:   # המקום הנבחר תפוס -> אם יש מקום ריק, משתמשים בו
		for i in 5:
			if Game.ability_slots[i] == null:
				slot_i = i
				break
	Game.ability_slots[slot_i] = id
	ab.cur = slot_i
	Sfx.play("weapon", null, -4.0)
	player._say(str(AbilityDB.val(id, "name", "")), AbilityDB.val(id, "color", Color.WHITE))


func _draw_reserve(c: Vector2, a: float) -> void:
	var res := _reserve()
	var f := ThemeDB.fallback_font
	var y0 := c.y + r_out + 74.0
	if res.is_empty():
		draw_string(f, Vector2(c.x - 200, y0 + 30), "NO OTHER ABILITIES YET", HORIZONTAL_ALIGNMENT_CENTER, 400, 12, Color(1, 1, 1, 0.3 * a))
		return
	var pages := int(ceil(float(res.size()) / float(RES_MAX)))
	_res_page = clampi(_res_page, 0, pages - 1)
	var n := mini(res.size(), RES_MAX)
	draw_string(f, Vector2(c.x - 250, y0 - 2), "OTHER ABILITIES  -  CLICK TO PUT IN SLOT %d" % (player.abilities.cur + 1), HORIZONTAL_ALIGNMENT_CENTER, 500, 12, Color(0.75, 0.8, 1.0, 0.8 * a))
	var mouse := get_viewport().get_mouse_position()
	for k in n:
		var i := _res_page * RES_MAX + k
		if i >= res.size():
			break
		var id: String = res[i]
		var r := _res_rect(c, k, n)
		var hov := r.has_point(mouse)
		var col: Color = AbilityDB.val(id, "color", Color.WHITE)
		var sb := StyleBoxFlat.new()
		sb.set_corner_radius_all(8)
		sb.bg_color = Color(0.06, 0.06, 0.09, 0.92 * a).lerp(col, 0.2 if hov else 0.05)
		sb.border_color = Color(col, (0.95 if hov else 0.45) * a)
		sb.set_border_width_all(2 if hov else 1)
		draw_style_box(sb, r.grow(3.0 if hov else 0.0))
		AbilityDB.draw_icon(self, r.get_center(), id, 1.1 if hov else 0.95, a)
		if hov:
			draw_string(f, Vector2(r.get_center().x - 80, r.end.y + 16), str(AbilityDB.val(id, "name", "")), HORIZONTAL_ALIGNMENT_CENTER, 160, 12, Color(col, a))
	if pages > 1:   # חיצי דפים
		for side in [-1, n]:
			var r := _res_rect(c, side, n)
			draw_string(f, r.position + Vector2(0, 30), "<" if side < 0 else ">", HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 22, Color(1, 1, 1, 0.7 * a))
		draw_string(f, Vector2(c.x - 60, y0 + 78), "%d / %d" % [_res_page + 1, pages], HORIZONTAL_ALIGNMENT_CENTER, 120, 11, Color(1, 1, 1, 0.5 * a))
