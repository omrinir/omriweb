extends "res://levels/stage_base.gd"
# ============================================================
#  STAGE 6 - "NO SAFE FLOOR"
#  בניין דירות/משרדים הרוס בלילה גשום. השלב הראשון עם משחק אנכי אמיתי:
#    * קומת קרקע: לובי בגובה כפול (נברשת, מעליות שבורות), משרדים, מסדרונות,
#      חדרי תחזוקה ומחסומים של ניצולים (רהיטים מוצקים = מחסות - environment/s6_furniture.gd).
#    * קומה שנייה (add_floor, floor_y - 160): דירות ומשרדים, עם חורים ברצפה (נופלים / יורדים),
#      מרפסות פתוחות לגשם, וקטעים סדוקים שמתמוטטים (environment/s6_collapse_floor.gd).
#    * מעברים בין הקומות: סולם בכל קטע, מדרגות ארגזים, וחורים לרדת דרכם.
#    * תקרה מוצקה (Roof, קבוצה "s6_roof") - ה-WALL CRAWLER זוחל עליה ועל תחתית הקומה השנייה.
#  זומבים: STALKER (מחסות), WALL CRAWLER (תקרות), SPITTER, GRABBER (תפיסה), PACK LEADER (היררכיה)
#  נושא ה-AI: מחסות והתקפות מגבהים - זומבים מוצבים בקומה השנייה ועל התקרות (extra_spawns).
#  סכנות: שלוליות מחושמלות (s6_live_wire.gd), פרצי אדים מצינורות (Ambient.SteamVent hazard),
#         רצפה מתמוטטת.
#  אפקטים: גשם, ברקים + רעם, טפטופים ושלוליות, נורות פלורסנט מהבהבות, אדים, ניצוצות,
#          טיפות על החלונות, נברשת מתנדנדת, מעלית תקועה, שלט ניאון, מסוק עם זרקור.
#  בוס: HOUND (19) בחצר הגשומה שאחרי הבניין.
#  לשנות: LOBBY_W / EXT_W (גדלים), _layout() (קומה שנייה), zombie_weights(), extra_spawns().
#  קישוטים: effects/s6_building.gd
# ============================================================

const WeaponDB := preload("res://weapons/weapon_db.gd")
const Sfx := preload("res://sfx.gd")
const B := preload("res://effects/s6_building.gd")
const Furniture := preload("res://environment/s6_furniture.gd")
const LiveWire := preload("res://environment/s6_live_wire.gd")
const CollapseFloor := preload("res://environment/s6_collapse_floor.gd")

const SOUNDS := {
	"s6_shock": {"drive": 2.6, "layers": [["N", 0, 0, 0.0, 0.01, 0.0, 300.0, 1.2, 1.0, 0], ["Q", 100, 92, 0.0, 0.9, 0.0, 3.0, 0.35, 0.5, 0.02], ["C", 0, 0, 0.0, 0.9, 0.0, 2.5, 1.0, 1.0, 0], ["S", 3800, 3500, 0.0, 0.8, 0.0, 4.0, 0.1, 1.0, 0]]},
	"s6_creak": {"drive": 1.8, "layers": [["W", 62, 78, 0.0, 0.32, 0.03, 6.0, 0.6, 0.12, 0.08], ["C", 0, 0, 0.0, 0.3, 0.0, 8.0, 0.5, 1.0, 0], ["N", 0, 0, 0.0, 0.3, 0.02, 9.0, 0.2, 0.08, 0]]},
	"s6_crumble": {"rev": 0.3, "drive": 2.4, "layers": [["N", 0, 0, 0.0, 1.4, 0.02, 2.2, 1.2, 0.05, 0], ["C", 0, 0, 0.0, 1.2, 0.0, 2.5, 0.9, 1.0, 0], ["S", 55, 30, 0.0, 0.9, 0.0, 3.5, 0.8, 1.0, 0], ["N", 0, 0, 0.1, 0.4, 0.0, 9.0, 0.5, 0.4, 0]]},
}

const LOBBY_W := 1000.0       # לובי בגובה כפול בהתחלה
const EXT_W := 820.0          # החצר שאחרי הבניין (בוס + יציאה)

var bx1 := 0.0                # סוף הבניין
var segs := []                # קטעי הקומה השנייה [x0, x1]
var gaps := []                # חורים בקומה השנייה [x0, x1]
var balconies := []           # [x0, x1]
var collapses := []           # [x0, x1]
var ladders := []             # x של סולמות
var rooms1 := []              # [x0, w, kind] קומת קרקע
var rooms2 := []              # [x0, w, kind] קומה שנייה
var _occupied2 := []          # [x0, x1] בקומה השנייה (סולמות, חורים, סכנות) - לא שמים שם רהיטים
var _thunder_idx := -1
var _f2 := 0.0
var _roof := 0.0


func zombie_weights() -> Dictionary:
	return {0: 0.22, 1: 0.17, 2: 0.05, 3: 0.12, Registry.STALKER: 0.15, Registry.WALL_CRAWLER: 0.12, Registry.GRABBER: 0.11, Registry.PACK_LEADER: 0.03}


func zombie_density() -> float:
	return 0.75


func generators() -> Array:
	return [["s6_desk", 2.4], ["s6_cabinet", 1.3], ["s6_barricade", 1.4], ["s6_crates", 1.0], ["s6_sofa", 0.7], ["s6_vending", 0.6], ["s6_copier", 0.6], ["s6_rubble", 0.9]]


# רהיטים מוצקים בקומת הקרקע (מחסות לזומבים ולשחקן)
func custom_gen(gname: String, x: float) -> float:
	if x < LOBBY_W + 40.0 or x > bx1 - 160.0:
		return 90.0   # לובי / יציאה: בלי מכשולים
	match gname:
		"s6_crates":   # מדרגות ארגזים
			if not free_x(x + 48.0, 70.0):
				return 60.0
			add_block(x, floor_y - 48.0, 48.0, 48.0, Color("7a5a36"), true, 1)
			add_block(x + 48.0, floor_y - 48.0, 48.0, 48.0, Color("6e5232"), true, 1)
			add_block(x + 48.0, floor_y - 96.0, 48.0, 48.0, Color("7a5a36"), true, 1)
			return 96.0
		"s6_rubble":
			if not free_x(x + 36.0, 56.0):
				return 60.0
			add_block(x, floor_y - 30.0, 72.0, 30.0, Color("5a5650"), true, 2)
			return 72.0
	if not gname.begins_with("s6_"):
		return 0.0
	var kind := gname.substr(3)
	if not Furniture.SIZES.has(kind):
		return 60.0
	var sz: Vector2 = Furniture.SIZES[kind]
	if not free_x(x + sz.x * 0.5, sz.x * 0.5 + 24.0):
		return 60.0
	_furniture(kind, x, floor_y)
	reserve(Rect2(x, floor_y - sz.y, sz.x, sz.y))
	return sz.x


func _furniture(kind: String, x: float, y: float) -> Node:
	var f = Furniture.new()
	f.kind = kind
	f.seed_v = rng.randi()
	f.position = Vector2(x, y)
	main.add_child(f)
	return f


func boss_kind() -> int:
	return 19   # HOUND - כלב הענק, בחצר הגשומה


func music() -> String:
	return "res://music/level2_suspense.mp3"


func world_tint() -> Color:
	return Color(0.7, 0.78, 0.95)


func pits() -> int:
	return 0


func fog() -> bool:
	return false


# ============================================================
#  רקע: לילה גשום, קו רקיע ב-3 שכבות, מסוק, ברקים
# ============================================================
func build_background(layer: CanvasLayer) -> Node:
	var bg = Backdrop.new()
	bg.level_w = level_w
	bg.sky = func(ci: CanvasItem, v: Vector2, t: float):
		Kit.gradient_sky(ci, v, [Color("080c14"), Color("101826"), Color("1a2436"), Color("243048"), Color("161e2c")])
		ci.draw_circle(Vector2(v.x * 0.22, 110), 70.0, Color(0.6, 0.7, 0.95, 0.05))   # ירח מאחורי העננים
		Kit.clouds(ci, 0.0, v, t, 60.0, Color(0.08, 0.1, 0.15, 0.8), 4, 9.0)
		Kit.clouds(ci, 0.0, v, t, 150.0, Color(0.12, 0.15, 0.21, 0.55), 8, 15.0)
		# ברקים רחוקים בתוך העננים (הבזק רך)
		var k := fmod(t, 5.3)
		if k < 0.25:
			var cx := fposmod(float(int(t / 5.3)) * 397.0, v.x)
			ci.draw_circle(Vector2(cx, 90), 120.0, Color(0.6, 0.65, 0.9, 0.12 * (1.0 - k / 0.25)))
	# שכבה 1 (רחוקה): גורדי שחקים + מגדלי רדיו מהבהבים + מסוק עם זרקור
	bg.add_layer(0.10, func(ci: CanvasItem, sc: float, v: Vector2, t: float):
		Kit.skyline(ci, sc, v, 520.0, Color("161e2c"), 61, Vector2(60, 120), Vector2(220, 400), 0.05, Color(0.85, 0.9, 1.0, 0.45), t, 0.15)
		for i in 3:
			var tx := fposmod(float(i) * 610.0 + 180.0 - sc, v.x + 400.0) - 200.0
			ci.draw_line(Vector2(tx, 520), Vector2(tx, 150.0 + float(i) * 30.0), Color("141a26"), 3.0)
			for q in 6:
				var yy := 520.0 - float(q) * 60.0
				ci.draw_line(Vector2(tx - 8, yy), Vector2(tx + 8, yy - 30), Color("141a26"), 1.0)
			if fmod(t + float(i) * 0.7, 1.8) < 0.6:
				ci.draw_circle(Vector2(tx, 150.0 + float(i) * 30.0), 3.0, Color(1.0, 0.15, 0.1, 0.9))
				ci.draw_circle(Vector2(tx, 150.0 + float(i) * 30.0), 9.0, Color(1.0, 0.15, 0.1, 0.2))
		Kit.helicopter(ci, v, t, 46.0, 130.0, Color(0.03, 0.04, 0.06, 0.9), true))
	# שכבה 2 (אמצע): בניינים עם חלונות קרים, נורות אדומות על הגגות
	bg.add_layer(0.30, func(ci: CanvasItem, sc: float, v: Vector2, t: float):
		Kit.skyline(ci, sc, v, 600.0, Color("111722"), 83, Vector2(90, 170), Vector2(180, 330), 0.1, Color(0.95, 0.85, 0.6, 0.55), t, 0.25)
		for i in 4:
			var lx := fposmod(float(i) * 470.0 + 90.0 - sc, v.x + 300.0) - 150.0
			if fmod(t * 0.8 + float(i) * 0.45, 2.0) < 0.5:
				ci.draw_circle(Vector2(lx, 300.0 + float(i % 2) * 40.0), 2.5, Color(1.0, 0.2, 0.15, 0.85))
		# וילונות גשם שעוברים
		for i in 5:
			var rx := fposmod(float(i) * 300.0 - t * 40.0 - sc * 0.2, v.x + 400.0) - 200.0
			for q in 12:
				var xx := rx + float(q) * 9.0
				ci.draw_line(Vector2(xx, 120), Vector2(xx - 40.0, 620), Color(0.6, 0.7, 0.85, 0.03), 6.0))
	# שכבה 3 (קרובה): בנייני דירות מעבר לרחוב - מדרגות חירום, מיכלי מים, שלט ניאון מהבהב
	bg.add_layer(0.60, func(ci: CanvasItem, sc: float, v: Vector2, t: float):
		var period := 640.0
		var start := int(floor(sc / period)) - 1
		for k in range(start, start + int(v.x / period) + 3):
			var r := RandomNumberGenerator.new()
			r.seed = k * 7919 + 17
			var x := float(k) * period - sc + r.randf_range(0.0, 120.0)
			var bw := r.randf_range(300.0, 440.0)
			var top := r.randf_range(190.0, 300.0)
			var body := Color("0e131c").lerp(Color("141a24"), r.randf())
			ci.draw_rect(Rect2(x, top, bw, v.y - top), body)
			ci.draw_rect(Rect2(x - 4, top - 8, bw + 8, 8), body.darkened(0.3))
			# חלונות (חלק דולקים, חלק עם צללית שזזה)
			var wy := top + 22.0
			var row := 0
			while wy < v.y - 40.0:
				var wx := x + 18.0
				var col_i := 0
				while wx < x + bw - 36.0:
					var lit := r.randf()
					var wc := Color("0a0d14")
					if lit < 0.16:
						wc = Color(1.0, 0.78, 0.45, 0.55) if r.randf() < 0.7 else Color(0.6, 0.8, 1.0, 0.45)
						if fmod(t * 0.3 + float(row * 7 + col_i), 23.0) < 0.4:
							wc = Color("0a0d14")
					ci.draw_rect(Rect2(wx, wy, 20, 26), wc)
					if lit < 0.04:   # מישהו (או משהו) עובר בחלון
						var sxp := wx + 10.0 + sin(t * 0.6 + float(k)) * 8.0
						ci.draw_rect(Rect2(sxp - 3, wy + 8, 6, 18), Color(0.02, 0.02, 0.03, 0.85))
						ci.draw_circle(Vector2(sxp, wy + 7), 3.5, Color(0.02, 0.02, 0.03, 0.85))
					wx += 38.0
					col_i += 1
				wy += 48.0
				row += 1
			# מדרגות חירום (זיגזג)
			var fx := x + bw * 0.62
			var fy := top + 40.0
			while fy < v.y - 60.0:
				ci.draw_line(Vector2(fx - 30, fy + 44), Vector2(fx + 50, fy + 44), Color("05070a"), 2.0)
				ci.draw_line(Vector2(fx - 26, fy + 44), Vector2(fx + 40, fy + 4), Color("05070a"), 1.5)
				ci.draw_line(Vector2(fx - 30, fy + 34), Vector2(fx + 50, fy + 34), Color("05070a"), 1.0)
				fy += 48.0
			# מיכל מים על הגג
			if r.randf() < 0.6:
				var tx := x + r.randf_range(30.0, bw - 80.0)
				ci.draw_rect(Rect2(tx + 6, top - 30, 3, 22), Color("080a0e"))
				ci.draw_rect(Rect2(tx + 40, top - 30, 3, 22), Color("080a0e"))
				ci.draw_colored_polygon(PackedVector2Array([Vector2(tx, top - 30), Vector2(tx + 50, top - 30), Vector2(tx + 48, top - 80), Vector2(tx + 2, top - 80)]), Color("080a0e"))
				ci.draw_colored_polygon(PackedVector2Array([Vector2(tx - 2, top - 80), Vector2(tx + 52, top - 80), Vector2(tx + 25, top - 96)]), Color("080a0e"))
			# שלט ניאון אנכי מהבהב
			if k % 3 == 0:
				var nx := x + 10.0
				var on := fmod(t * 1.3 + float(k), 6.0) > 0.35 and not (fmod(t * 9.0, 7.0) < 0.5 and fmod(t, 4.0) < 1.0)
				ci.draw_rect(Rect2(nx, top + 30, 26, 120), Color("06080c"))
				var nc := Color(0.3, 0.9, 1.0) if k % 2 == 0 else Color(1.0, 0.3, 0.5)
				var word := "HOTEL" if k % 2 == 0 else "24H"
				for i in word.length():
					ci.draw_string(ThemeDB.fallback_font, Vector2(nx + 6, top + 52 + i * 22), word[i], HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(nc, 0.9 if on else 0.15))
				if on:
					ci.draw_rect(Rect2(nx - 10, top + 20, 46, 140), Color(nc, 0.05))
		Kit.ground_fade(ci, v, 600.0))
	# ברק על כל הרקע + רעם (נראה גם דרך החלונות)
	bg.overlay = func(ci: CanvasItem, v: Vector2, t: float):
		if Kit.lightning(ci, v, t, 12.0, 21):
			var idx := int(t / 12.0)
			if idx != _thunder_idx:
				_thunder_idx = idx
				Sfx.play("thunder", null, -3.0, 0.15)
	layer.add_child(bg)
	return bg


# ============================================================
#  תכנון הבניין
# ============================================================
func _layout() -> void:
	bx1 = level_w - EXT_W
	_f2 = floor_y - FLOOR2
	_roof = floor_y - ROOF
	# קומה שנייה: קטעים עם חורים ביניהם
	var x := LOBBY_W
	while x < bx1 - 300.0:
		var w := minf(rng.randf_range(560.0, 1100.0), bx1 - 40.0 - x)
		if w < 260.0:
			break
		segs.append([x, x + w])
		x += w
		var g := rng.randf_range(120.0, 185.0)
		gaps.append([x, minf(x + g, bx1)])
		x += g
	if x < bx1:   # סוף הבניין בלי קומה שנייה
		gaps.append([x, bx1])
	# מרפסות + קטעים מתמוטטים + סולמות
	var n_collapse := 0
	for i in segs.size():
		var s0: float = segs[i][0]
		var s1: float = segs[i][1]
		var lx := s0 + 46.0 if i % 2 == 0 else s1 - 46.0
		ladders.append(lx)
		_occupied2.append([lx - 60.0, lx + 60.0])
		if s1 - s0 > 720.0 and rng.randf() < 0.55:
			var bx := rng.randf_range(s0 + 140.0, s1 - 380.0)
			if absf(bx - lx) > 120.0 and absf(bx + 220.0 - lx) > 120.0:
				balconies.append([bx, bx + 220.0])
		if s1 - s0 > 620.0 and n_collapse < 3 and i % 2 == 1:
			var cx := rng.randf_range(s0 + 160.0, s1 - 320.0)
			var ok := absf(cx + 75.0 - lx) > 160.0
			for bal in balconies:
				if cx + 150.0 > float(bal[0]) - 20.0 and cx < float(bal[1]) + 20.0:
					ok = false
			if ok:
				collapses.append([cx, cx + 150.0])
				_occupied2.append([cx - 30.0, cx + 180.0])
				n_collapse += 1
	# חדרים
	var kinds1 := ["office", "corridor", "office", "utility", "barricade", "corridor", "office", "barricade"]
	x = LOBBY_W
	var ki := rng.randi() % kinds1.size()
	while x < bx1 - 1.0:
		var w := minf(rng.randf_range(480.0, 860.0), bx1 - x)
		if bx1 - x - w < 220.0:
			w = bx1 - x
		rooms1.append([x, w, kinds1[ki % kinds1.size()]])
		ki += 1 + rng.randi() % 2
		x += w
	var kinds2 := ["apartment", "office2", "apartment", "bathroom", "apartment", "office2"]
	x = LOBBY_W
	ki = rng.randi() % kinds2.size()
	while x < bx1 - 1.0:
		var k2: String = kinds2[ki % kinds2.size()]
		var w := minf(rng.randf_range(260.0, 360.0) if k2 == "bathroom" else rng.randf_range(420.0, 760.0), bx1 - x)
		if bx1 - x - w < 200.0:
			w = bx1 - x
		rooms2.append([x, w, k2])
		ki += 1
		x += w


func _local(ranges: Array, x0: float, x1: float) -> Array:
	var out := []
	for rg in ranges:
		var a := maxf(float(rg[0]), x0)
		var b := minf(float(rg[1]), x1)
		if b > a:
			out.append([a - x0, b - x0])
	return out


func _in_seg(x: float, margin := 0.0) -> bool:
	for s in segs:
		if x > float(s[0]) + margin and x < float(s[1]) - margin:
			return true
	return false


func _free2(x0: float, x1: float) -> bool:
	if not (_in_seg(x0, 30.0) and _in_seg(x1, 30.0)):
		return false
	for rg in _occupied2 + balconies:
		if x1 > float(rg[0]) and x0 < float(rg[1]):
			return false
	for s in segs:   # לא חוצה חור
		if x0 > float(s[0]) and x0 < float(s[1]) and x1 > float(s[1]):
			return false
	return true


# ============================================================
#  העולם
# ============================================================
func build_world() -> void:
	_layout()
	var fy := floor_y
	# ---- חדרים (קיר אחורי, חלונות, רהיטים ברקע) ----
	var lobby = B.Room.new()
	lobby.w = LOBBY_W
	lobby.kind = "lobby"
	lobby.band = 0
	lobby.seed_v = rng.randi()
	lobby.busy = [[520.0, 820.0]]
	lobby.position = Vector2(0, fy)
	lobby.plan()
	main.add_child(lobby)
	_room_extras(lobby)
	for rm in rooms1:
		var r = B.Room.new()
		r.w = float(rm[1])
		r.kind = rm[2]
		r.band = 1
		r.seed_v = rng.randi()
		r.gaps = _local(gaps, float(rm[0]), float(rm[0]) + float(rm[1]))
		r.position = Vector2(float(rm[0]), fy)
		r.plan()
		main.add_child(r)
		_room_extras(r)
	for rm in rooms2:
		var r = B.Room.new()
		r.w = float(rm[1])
		r.kind = rm[2]
		r.band = 2
		r.variant = ["apartment", "apartment_b", "apartment_c"][rng.randi() % 3]
		r.seed_v = rng.randi()
		r.gaps = _local(gaps, float(rm[0]), float(rm[0]) + float(rm[1]))
		r.open = _local(balconies, float(rm[0]), float(rm[0]) + float(rm[1]))
		r.position = Vector2(float(rm[0]), fy)
		r.plan()
		main.add_child(r)
		_room_extras(r)
	# פני הריצפה
	var trims := [[0.0, LOBBY_W, "lobby"]] + rooms1
	for rm in trims:
		var ft = B.FloorTrim.new()
		ft.w = float(rm[1])
		ft.kind = rm[2]
		ft.seed_v = rng.randi()
		ft.position = Vector2(float(rm[0]), fy)
		main.add_child(ft)
	# ---- תקרה מוצקה + הגג ----
	var roof := Roof.new()
	roof.x1 = bx1
	roof.y = _roof
	main.add_child(roof)
	var cx := 0.0
	while cx < bx1:
		var rc = B.RoofChunk.new()
		rc.w = minf(1024.0, bx1 - cx)
		rc.seed_v = rng.randi()
		rc.is_end = cx + 1024.0 >= bx1
		rc.position = Vector2(cx, fy)
		main.add_child(rc)
		cx += 1024.0
	var neon = B.NeonSign.new()
	add_world(neon, Vector2(160.0, _roof - 40.0))
	for i in 4:
		var bcn = B.Beacon.new()
		add_world(bcn, Vector2(level_w * (0.12 + 0.22 * float(i)) + rng.randf_range(-80.0, 80.0), _roof - 12.0))
	# קיר חיצוני בסוף הבניין (מהגג עד הקומה השנייה) + החצר
	add_block(bx1 - 24.0, _roof - 12.0, 40.0, (_f2 + 14.0) - (_roof - 12.0), Color("4a3430"), false, 2)
	var ext = B.Exterior.new()
	ext.w = EXT_W
	add_world(ext, Vector2(bx1, fy))
	# ---- לובי: מעליות + נברשת ----
	var el = B.Elevator.new()
	add_world(el, Vector2(540.0, fy))
	var ch = B.Chandelier.new()
	ch.length = 100.0
	add_world(ch, Vector2(300.0, _roof + 18.0))
	# ---- הקומה השנייה ----
	for s in segs:
		_build_floor(float(s[0]), float(s[1]))
	for lx in ladders:
		add_ladder(float(lx), _f2)
		reserve(Rect2(float(lx) - 30.0, fy - 30.0, 60.0, 30.0))
	# מדרגות ארגזים מתחת לקצה של חלק מהקטעים
	for i in segs.size():
		if i % 3 != 1:
			continue
		var s1: float = segs[i][1]
		var sx := s1 - 130.0
		if absf(sx - float(ladders[i])) > 100.0 and free_x(sx + 30.0, 40.0):
			add_block(sx, fy - 56.0, 56.0, 56.0, Color("7a5a36"), true, 1)
	# רהיטים מוצקים בקומה השנייה (מחסות ל-STALKER למעלה)
	for s in segs:
		var s0: float = s[0]
		var s1: float = s[1]
		var n := 1 + (1 if s1 - s0 > 800.0 else 0)
		for k in n:
			var kinds := ["desk", "sofa", "cabinet", "copier"]
			var kind: String = kinds[rng.randi() % kinds.size()]
			var sz: Vector2 = Furniture.SIZES[kind]
			for tries in 6:
				var fx := rng.randf_range(s0 + 90.0, s1 - 90.0 - sz.x)
				if _free2(fx - 20.0, fx + sz.x + 20.0):
					_furniture(kind, fx, _f2)
					_occupied2.append([fx - 20.0, fx + sz.x + 20.0])
					break
	# ---- סכנות ----
	_build_hazards()


func _build_floor(s0: float, s1: float) -> void:
	# מפרקים את הקטע לחלקים: רגיל / מרפסת (מעקה) / מתמוטט
	var cuts := []
	for b in balconies:
		if float(b[0]) >= s0 and float(b[1]) <= s1:
			cuts.append([float(b[0]), float(b[1]), "balcony"])
	for c in collapses:
		if float(c[0]) >= s0 and float(c[1]) <= s1:
			cuts.append([float(c[0]), float(c[1]), "collapse"])
	cuts.sort_custom(func(a: Array, b: Array): return float(a[0]) < float(b[0]))
	var x := s0
	for c in cuts:
		var c0: float = c[0]
		var c1: float = c[1]
		if c0 > x + 1.0:
			add_floor(x, _f2, c0 - x, "concrete", false, false)
		if c[2] == "balcony":
			add_floor(c0, _f2, c1 - c0, "concrete", false, true)
		else:
			var cf = CollapseFloor.new()
			cf.position = Vector2(c0, _f2)
			cf.size = Vector2(c1 - c0, 14.0)
			cf.style = "concrete"
			cf.supports = false
			cf.ground_y = floor_y
			main.add_child(cf)
		x = c1
	if s1 > x + 1.0:
		add_floor(x, _f2, s1 - x, "concrete", false, false)
	# עמודי תמך בקצוות הקטע (בתוך הבניין)
	for px in [s0 + 8.0, s1 - 22.0]:
		var col := Column.new()
		col.h = FLOOR2 - 14.0
		add_world(col, Vector2(float(px), floor_y))


func _build_hazards() -> void:
	var fy := floor_y
	# שלוליות מחושמלות בקומת הקרקע
	for i in 4:
		var hx := level_w * (0.2 + 0.18 * float(i)) + rng.randf_range(-150.0, 150.0)
		for tries in 8:
			if free_x(hx, 80.0) and hx > LOBBY_W + 100.0 and hx < bx1 - 200.0:
				break
			hx += 97.0
		if not free_x(hx, 80.0) or hx > bx1 - 200.0:
			continue
		var lw = LiveWire.new()
		lw.width = rng.randf_range(96.0, 130.0)
		lw.cable_h = FLOOR2 - 14.0 if _in_seg(hx, 10.0) else ROOF - 18.0
		add_hazard(lw, Vector2(hx, fy))
		reserve(Rect2(hx - 75.0, fy - 40.0, 150.0, 40.0))
	# שלולית מחושמלת בקומה השנייה (מים שדולפים מהגג)
	var placed := 0
	for s in segs:
		if placed >= 2:
			break
		var s0: float = s[0]
		var s1: float = s[1]
		if s1 - s0 < 600.0:
			continue
		var hx2 := rng.randf_range(s0 + 150.0, s1 - 150.0)
		if _free2(hx2 - 70.0, hx2 + 70.0):
			var lw2 = LiveWire.new()
			lw2.width = 100.0
			lw2.cable_h = FLOOR2 - 18.0
			add_hazard(lw2, Vector2(hx2, _f2))
			_occupied2.append([hx2 - 70.0, hx2 + 70.0])
			placed += 1
	# צינורות שמתפוצצים באדים (פרץ כל כמה שניות - לעבור בין הפרצים)
	for i in 4:
		var vx := level_w * (0.27 + 0.17 * float(i)) + rng.randf_range(-120.0, 120.0)
		for tries in 8:
			if free_x(vx, 60.0):
				break
			vx += 83.0
		if not free_x(vx, 60.0) or vx < LOBBY_W + 100.0 or vx > bx1 - 200.0:
			continue
		var d := Vector2.LEFT if rng.randf() < 0.5 else Vector2.RIGHT
		var pipe = B.PipeOutlet.new()
		pipe.dir = d
		pipe.up_len = 90.0
		add_world(pipe, Vector2(vx, fy - 20.0))
		var sv = Ambient.SteamVent.new()
		sv.dir = d
		sv.hazard = true
		sv.period = rng.randf_range(3.5, 5.0)
		add_world(sv, Vector2(vx + d.x * 4.0, fy - 20.0))
		reserve(Rect2(vx - 80.0, fy - 40.0, 160.0, 40.0))


# מסכים / ניצוצות שהחדר תכנן
func _room_extras(r: Node) -> void:
	for sp in r.screens:
		var s = Ambient.Screen.new()
		s.size = Vector2(26, 18)
		s.color = [Color(0.3, 0.9, 0.8), Color(0.5, 0.7, 1.0), Color(0.85, 0.85, 0.9), Color(0.4, 1.0, 0.5)][rng.randi() % 4]
		var lp: Vector2 = sp
		add_world(s, r.position + lp + Vector2(-2, 0))
	for sp in r.sparks:
		var e = Ambient.SparkEmitter.new()
		e.period = rng.randf_range(1.8, 3.5)
		var lp2: Vector2 = sp
		add_world(e, r.position + lp2)


func build_effects() -> void:
	var fy := floor_y
	var rn = RainScript.new()
	rn.modulate = Color(1, 1, 1, 0.6)
	screen_layer.add_child(rn)
	screen_layer.add_child(Ambient.screen_particles("dust", vp))
	# נורות פלורסנט (חלקן מהבהבות, חלקן נורות חירום אדומות)
	var x := 380.0
	while x < bx1 - 60.0:
		var fl = Ambient.FlickerLight.new()
		var low := _in_seg(x, 20.0)
		fl.radius = rng.randf_range(70.0, 90.0)
		var rr := rng.randf()
		if rr < 0.15:
			fl.mode = "pulse"
			fl.color = Color(1.0, 0.25, 0.2)
		elif rr < 0.6:
			fl.mode = "flicker"
		else:
			fl.mode = "steady"
		add_world(fl, Vector2(x, (_f2 + 16.0) if low else (_roof + 20.0)))
		x += rng.randf_range(260.0, 420.0)
	x = LOBBY_W + 120.0
	while x < bx1 - 60.0:   # קומה שנייה
		if _in_seg(x, 20.0):
			var fl2 = Ambient.FlickerLight.new()
			fl2.radius = 70.0
			fl2.mode = "flicker" if rng.randf() < 0.5 else "steady"
			fl2.color = Color(1.0, 0.9, 0.7) if rng.randf() < 0.5 else Color(0.85, 0.95, 1.0)
			add_world(fl2, Vector2(x, _roof + 20.0))
		x += rng.randf_range(300.0, 480.0)
	# טפטופים מהתקרה
	x = 260.0
	while x < bx1 - 40.0:
		var dp = Ambient.Drip.new()
		dp.period = rng.randf_range(1.2, 2.6)
		if _in_seg(x, 10.0):
			if rng.randf() < 0.5:
				dp.fall = FLOOR2 - 14.0
				add_world(dp, Vector2(x, _f2 + 14.0))
			else:
				dp.fall = _f2 - (_roof + 18.0)
				add_world(dp, Vector2(x, _roof + 18.0))
		else:
			dp.fall = fy - (_roof + 18.0)
			add_world(dp, Vector2(x, _roof + 18.0))
		x += rng.randf_range(260.0, 520.0)
	# שלוליות בקומת הקרקע ובחצר
	for i in 9:
		var px := rng.randf_range(300.0, bx1 - 100.0)
		if free_x(px, 40.0):
			var pd = B.Puddle.new()
			pd.width = rng.randf_range(60.0, 120.0)
			add_world(pd, Vector2(px, fy - 1.0))
	for i in 4:
		var pd2 = B.Puddle.new()
		pd2.width = rng.randf_range(80.0, 150.0)
		add_world(pd2, Vector2(bx1 + 80.0 + float(i) * 170.0 + rng.randf_range(-30.0, 30.0), fy - 1.0))
	# ניצוצות מהמעלית התקועה + מכבלים קרועים בקצות החורים
	var es = Ambient.SparkEmitter.new()
	es.period = 2.0
	add_world(es, Vector2(540.0 + 165.0, _roof + 18.0 + 120.0))
	for g in gaps:
		if rng.randf() < 0.5 and float(g[1]) < bx1:
			var e2 = Ambient.SparkEmitter.new()
			e2.period = rng.randf_range(2.5, 4.5)
			e2.color = Color(0.7, 0.85, 1.0)
			add_world(e2, Vector2(float(g[0]) + 8.0, _f2 + 14.0))
	# אדים על הגג (קישוט)
	for i in 5:
		var sv = Ambient.SteamVent.new()
		sv.dir = Vector2.UP
		add_world(sv, Vector2(rng.randf_range(200.0, bx1 - 200.0), _roof - 12.0))
	# פנס בחצר
	var lamp = Ambient.FlickerLight.new()
	lamp.color = Color(1.0, 0.75, 0.45)
	lamp.radius = 110.0
	lamp.tube = false
	add_world(lamp, Vector2(bx1 + 362.0, fy - 176.0))


# ============================================================
#  זומבים בקומה השנייה ועל התקרות (נושא השלב: מחסות + התקפות מגבהים)
# ============================================================
func extra_spawns() -> void:
	var up_kinds := [Registry.STALKER, 3, 0, Registry.STALKER, 1, 3, Registry.GRABBER]
	for i in segs.size():
		var s0: float = segs[i][0]
		var s1: float = segs[i][1]
		var n := 1 + (1 if s1 - s0 > 900.0 else 0)
		for k in n:
			var zx := rng.randf_range(s0 + 120.0, s1 - 120.0)
			spawn(up_kinds[rng.randi() % up_kinds.size()], zx, _f2)
		# זוחל תלוי מתחת לקומה השנייה (מחכה מעל מי שעובר בקומת הקרקע)
		if i % 2 == 0 and s1 - s0 > 400.0:
			_ceiling_crawler(rng.randf_range(s0 + 150.0, s1 - 150.0), _f2 + 14.0)
		# זוחל על תקרת הקומה השנייה
		if i % 3 == 2:
			var z = spawn(Registry.WALL_CRAWLER, rng.randf_range(s0 + 150.0, s1 - 150.0), _f2)
			if z != null and z.type_mod != null:
				z.type_mod.start_on_ceiling(_roof + 18.0)
	# שתי להקות עם מנהיג
	for f in [0.37, 0.7]:
		var lx: float = level_w * f
		spawn(Registry.PACK_LEADER, lx, floor_y)
		spawn(0, lx - 90.0, floor_y)
		spawn(1, lx - 140.0, floor_y)
		spawn(0, lx + 70.0, floor_y)


func _ceiling_crawler(x: float, cy: float) -> void:
	var z = spawn(Registry.WALL_CRAWLER, x, floor_y)
	if z != null and z.type_mod != null:
		z.type_mod.start_on_ceiling(cy)


# ============================================================
#  תקרה מוצקה של הבניין (שכבה 1). ה-WALL CRAWLER שואל אותה איפה התקרה
# ============================================================
class Roof extends StaticBody2D:
	var x1 := 9000.0
	var y := 310.0

	func _ready() -> void:
		add_to_group("s6_roof")
		collision_layer = 1
		collision_mask = 0
		var cs := CollisionShape2D.new()
		var r := RectangleShape2D.new()
		r.size = Vector2(x1, 18.0)
		cs.shape = r
		cs.position = Vector2(x1 * 0.5, y + 9.0)
		add_child(cs)

	# התחתית של התקרה ב-x (או -INF מחוץ לבניין)
	func ceiling_at(x: float) -> float:
		return y + 18.0 if x > 0.0 and x < x1 else -INF

	func span() -> Vector2:
		return Vector2(20.0, x1 - 30.0)


# עמוד בטון בקצה של קטע בקומה השנייה
class Column extends Node2D:
	var h := 146.0

	func _ready() -> void:
		z_index = -1

	func _draw() -> void:
		draw_rect(Rect2(0, -h, 14, h), Color("4a4844"))
		draw_rect(Rect2(0, -h, 3, h), Color(1, 1, 1, 0.06))
		draw_rect(Rect2(11, -h, 3, h), Color(0, 0, 0, 0.25))
		draw_line(Vector2(4, -h * 0.6), Vector2(10, -h * 0.45), Color(0, 0, 0, 0.4), 1.0)
		draw_line(Vector2(10, -h * 0.45), Vector2(6, -h * 0.3), Color(0, 0, 0, 0.4), 1.0)
