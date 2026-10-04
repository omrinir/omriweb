extends "res://levels/stage_base.gd"
# ============================================================
#  STAGE 8 - "THEY ADAPT"
#  מעבדת מחקר תת-קרקעית נטושה: תאורה קרה, אורות חירום אדומים, מסדרונות חשוכים,
#  חדרי זכוכית, מיכלי כליאה, מסופי מחשב, דם, כבלים, כימיקלים דולפים ואדים.
#  נושא ה-AI: הסתגלות לנשק של השחקן (adaptation_level = 0.7). ה-ADAPTOR הוא התצוגה.
#
#  מבנה (שיעור מתוך level_w):
#   A  0.11-0.29  מסדרון מפוצל: למעלה מסדרון מעבדה (בטוח מסכנות, אבל HUNTER + ADAPTOR שומרים),
#                  למטה מסדרון עם דליפות חומצה ולוחות מחושמלים - מסוכן, אבל יש בו תחמושת ורימונים.
#   B  0.33-0.45  אטריום כליאה אנכי: קיר אטום באמצע (דלת חסימה) - עולים בסולם, קופצים מעל הקיר.
#                  פלטפורמה עליונה אופציונלית עם בוסט, ו-SIREN ששרה מלמעלה.
#   C  0.48-0.62  אולם צינורות כליאה: צינורות שמתפוצצים כשמתקרבים (ולפעמים נבדק בורח),
#                  לוחות מחושמלים, ומעבר מתכת עליון שעוקף הכל. TANK (רגיל) מסתובב כאן.
#   D  0.65-0.79  חדר שרתים: למעלה לוחות מחושמלים + פרסים, למטה אדים רותחים + SIREN.
#   E  סוף        ארנה של הבוס: TANK ("SUBJECT ZERO") עם מכולות להסתתר מאחוריהן.
#  רקע: אולם מכונות ענק (3 שכבות): כורים, מנוף שנע לבד, מיכלי נוזל עם בועות,
#        מסכים מהבהבים, נורות אזהרה מסתובבות, ניצוצות ואדים.
#  אפקטים: ניצוצות חשמל, אדים ירוקים (spores), מסכים מהבהבים, אור חירום אדום פועם, נורות ניאון מהבהבות.
#  סכנות: שלוליות חומצה (דליפות), לוחות רצפה מחושמלים, צינורות כליאה מתפוצצים, אדים רותחים.
#  לשנות: zombie_weights, המספרים בכל קטע ב-build_world, SPECIMEN_CAP.
# ============================================================

const WeaponDB := preload("res://weapons/weapon_db.gd")
const Decor := preload("res://effects/s8_decor.gd")
const ElectroFloor := preload("res://environment/s8_electro_floor.gd")
const BurstTube := preload("res://environment/s8_burst_tube.gd")
const AcidPool := preload("res://environment/acid_pool.gd")
const PickupScript := preload("res://pickup.gd")
const Sfx := preload("res://sfx.gd")

const SOUNDS := {
	"s8_zap": {"drive": 2.4, "layers": [["Q", 58, 62, 0.0, 0.6, 0.0, 3.0, 0.35, 0.5, 0], ["C", 0, 0, 0.0, 0.6, 0.0, 2.5, 1.0, 1.0, 0], ["N", 0, 0, 0.0, 0.08, 0.0, 40.0, 0.5, 1.0, 0, 0.3]]},
	"s8_hum": [["Q", 120, 120, 0.0, 0.5, 0.05, 2.0, 0.12, 0.3, 0], ["S", 240, 240, 0.0, 0.5, 0.05, 2.0, 0.1, 1.0, 0]],
	"s8_hiss": [["N", 0, 0, 0.0, 0.9, 0.05, 2.5, 0.5, 0.8, 0, 0.4]],
	"s8_klaxon": {"rev": 0.5, "layers": [["W", 440, 330, 0.0, 0.7, 0.05, 1.0, 0.18, 0.35, 0], ["W", 440, 330, 0.9, 0.7, 0.05, 1.0, 0.18, 0.35, 0]]},
}

const SPECIMEN_CAP := 3
var specimens_left := SPECIMEN_CAP    # כמה נבדקים יכולים לברוח מצינורות (environment/s8_burst_tube.gd)
var _klaxon_t := 12.0


func zombie_weights() -> Dictionary:
	return {0: 0.16, 1: 0.12, 3: 0.05, Registry.ADAPTOR: 0.24, Registry.DODGER: 0.18, Registry.HUNTER: 0.12, Registry.SIREN: 0.03, Registry.TANK: 0.025}


func generators() -> Array:
	return [["lab_bench", 3.0], ["specimen_crate", 2.0], ["server_rack", 1.2], ["drums", 0.8]]


func weapon_offers() -> Array:
	return [WeaponDB.ASSAULT_SHOTGUN, WeaponDB.GRENADE_LAUNCHER]


func boss_kind() -> int:
	return Registry.TANK


func music() -> String:
	return "res://music/level2_suspense.mp3"


func world_tint() -> Color:
	return Color(0.78, 0.88, 0.95)


func pits() -> int:
	return 0


func fog() -> bool:
	return false


# ---- רהיטי מעבדה (מכשולים): בלוק מוצק + ציור מעליו ----
func custom_gen(gname: String, x: float) -> float:
	var w := 0.0
	var h := 0.0
	var kind := ""
	match gname:
		"lab_bench":
			w = rng.randf_range(80.0, 110.0)
			h = 34.0
			kind = "bench"
		"specimen_crate":
			w = rng.randf_range(48.0, 60.0)
			h = rng.randf_range(42.0, 56.0)
			kind = "crate"
		"server_rack":
			w = 40.0
			h = rng.randf_range(70.0, 88.0)
			kind = "server"
		"drums":   # חביות כימיקלים נפיצות (של main.gd)
			if not _free_span(x, 90.0):
				return 60.0
			return main._gen_barrels(rng, x, floor_y)
		_:
			return 0.0
	if not _free_span(x, w):
		return 60.0   # אזור שמור (סולמות / סכנות / אטריום): מדלגים
	lab_prop(kind, x, w, h)
	return w


func _free_span(x: float, w: float) -> bool:
	return free_x(x, 30.0) and free_x(x + w, 30.0) and free_x(x + w * 0.5, 30.0)


# רהיט מעבדה במקום מסוים (משמש גם למחסות בארנת הבוס)
func lab_prop(kind: String, x: float, w: float, h: float) -> void:
	var cols := {"bench": Color("56626c"), "crate": Color("5a6670"), "server": Color("23292f")}
	main._make_brick(Vector2(x, floor_y - h), Vector2(w, h), 2, cols.get(kind, Color("56626c")), true)
	var brick: Node = main.get_child(main.get_child_count() - 1)
	brick.hp = 7 if kind != "server" else 10   # מחזיק יותר מבלוק רגיל (מחסה למחצה)
	reserve(Rect2(x, floor_y - h, w, h))
	var ov := Decor.PropOverlay.new()
	ov.kind = kind
	ov.size = Vector2(w, h)
	ov.brick = brick
	ov.seed_v = rng.randi()
	ov.position = Vector2(x, floor_y - h)
	main.add_child(ov)


# ============================================================
#  רקע: אולם מכונות ענק מתחת לאדמה (3 שכבות + דברים שזזים לבד)
# ============================================================
func build_background(layer: CanvasLayer) -> Node:
	var bg = Backdrop.new()
	bg.level_w = level_w
	bg.sky = func(ci: CanvasItem, v: Vector2, t: float):
		Kit.gradient_sky(ci, v, [Color("06080b"), Color("0c1116"), Color("121a21"), Color("0e1419")])
		var pulse := pow(absf(sin(t * 1.1)), 4.0)   # אור חירום רחוק (מסונכרן עם AlarmPulse)
		ci.draw_circle(Vector2(v.x * 0.5, 40), 380.0, Color(0.6, 0.05, 0.03, 0.08 * pulse))
	# שכבה 1 (רחוקה): כורים ענקיים, גשר מנוף שנע לבד, מיכל נוזל ענק
	bg.add_layer(0.10, func(ci: CanvasItem, sc: float, v: Vector2, t: float):
		var period := 760.0
		var start := int(floor(sc / period)) - 1
		ci.draw_rect(Rect2(0, 96, v.x, 10), Color("10161b"))   # מסילת המנוף
		for k in range(start, start + int(v.x / period) + 3):
			var x := float(k) * period - sc
			var r := RandomNumberGenerator.new()
			r.seed = k * 7919 + 17
			# כור
			var rx := x + 120.0
			var rw := r.randf_range(130.0, 170.0)
			ci.draw_rect(Rect2(rx, 140, rw, 440), Color("121920"))
			for i in 6:
				ci.draw_rect(Rect2(rx - 6, 160 + i * 70, rw + 12, 10), Color("19222a"))
			var core := 0.5 + 0.5 * sin(t * 1.6 + float(k))
			ci.draw_rect(Rect2(rx + rw * 0.35, 260, rw * 0.3, 180), Color(0.25, 0.75, 0.85, 0.18 + 0.15 * core))
			ci.draw_circle(Vector2(rx + rw * 0.5, 350), 70.0, Color(0.3, 0.8, 0.9, 0.05 + 0.04 * core))
			ci.draw_colored_polygon(PackedVector2Array([Vector2(rx - 10, 140), Vector2(rx + rw + 10, 140), Vector2(rx + rw * 0.7, 100), Vector2(rx + rw * 0.3, 100)]), Color("141c22"))
			# מיכל נוזל ענק עם בועות
			var tx := x + 470.0
			ci.draw_rect(Rect2(tx, 230, 120, 330), Color("0f171c"))
			ci.draw_rect(Rect2(tx + 8, 260, 104, 300), Color(0.2, 0.6, 0.35, 0.22))
			for i in 6:
				var q := fmod(t * 0.12 + float(i) * 0.17 + float(k) * 0.3, 1.0)
				ci.draw_circle(Vector2(tx + 20 + float(i) * 15.0 + sin(t + float(i)) * 4.0, lerpf(550.0, 270.0, q)), 2.0 + 2.0 * q, Color(0.6, 1.0, 0.7, 0.25 * (1.0 - q)))
			# צינורות אנכיים ענקיים
			ci.draw_rect(Rect2(x + 640.0, 60, 26, 520), Color("0f151a"))
			ci.draw_rect(Rect2(x + 676.0, 60, 14, 520), Color("131a20"))
		# עגלת המנוף נוסעת לאורך המסילה (זזה לבד)
		var cx := fposmod(t * 38.0, v.x + 400.0) - 200.0
		ci.draw_rect(Rect2(cx - 40, 92, 80, 22), Color("1a2228"))
		var sway := sin(t * 0.9) * 6.0
		ci.draw_line(Vector2(cx, 114), Vector2(cx + sway, 240), Color("0c1014"), 2.0)
		ci.draw_rect(Rect2(cx + sway - 26, 240, 52, 40), Color("1c242a"))
		if int(t * 2.0) % 2 == 0:
			ci.draw_circle(Vector2(cx + 36, 103), 3.0, Color(1.0, 0.6, 0.1, 0.9)))
	# שכבה 2 (אמצע): קיר חדרי בקרה - חלונות מוארים, מסכים מהבהבים, נורות אזהרה מסתובבות, אדים
	bg.add_layer(0.30, func(ci: CanvasItem, sc: float, v: Vector2, t: float):
		var period := 900.0
		var start := int(floor(sc / period)) - 1
		for k in range(start, start + int(v.x / period) + 3):
			var x := float(k) * period - sc
			var r := RandomNumberGenerator.new()
			r.seed = k * 104729 + 5
			ci.draw_rect(Rect2(x, 300, period, 300), Color("0d1317"))
			ci.draw_rect(Rect2(x, 296, period, 6), Color("19232a"))
			# חלונות של חדרי בקרה
			for i in 4:
				var wx := x + 40.0 + float(i) * 210.0
				var lit := r.randf() < 0.7
				ci.draw_rect(Rect2(wx, 330, 150, 60), Color(0.25, 0.7, 0.8, 0.25) if lit else Color("0a0f12"))
				ci.draw_rect(Rect2(wx, 330, 150, 60), Color("1c262c"), false, 3.0)
				if lit:   # מסכים מהבהבים בתוך החלון
					for j in 3:
						var on := fmod(t * (1.3 + float(j) * 0.4) + float(i + k), 3.0) > 0.25
						ci.draw_rect(Rect2(wx + 12 + j * 46, 352, 30, 22), Color(0.4, 1.0, 0.7, 0.45) if on else Color(0.1, 0.2, 0.2, 0.5))
						var sl := fmod(t * 20.0 + float(j) * 7.0, 22.0)
						ci.draw_rect(Rect2(wx + 12 + j * 46, 352 + sl, 30, 2), Color(0.8, 1.0, 0.9, 0.3))
			# נורת אזהרה מסתובבת (אלומה אדומה)
			var bx := x + 460.0
			var ang := t * 3.0 + float(k)
			ci.draw_circle(Vector2(bx, 310), 6.0, Color(0.9, 0.1, 0.05, 0.8))
			var dir := Vector2(cos(ang), absf(sin(ang)) * 0.4 + 0.1)
			if cos(ang) > -0.2:
				ci.draw_colored_polygon(PackedVector2Array([Vector2(bx, 310), Vector2(bx, 310) + dir.rotated(-0.25) * 260.0, Vector2(bx, 310) + dir.rotated(0.25) * 260.0]), Color(1.0, 0.1, 0.05, 0.07))
			Kit.smoke_column(ci, Vector2(x + 720.0, 300), t * 1.5 + float(k), 180.0, Color(0.7, 0.8, 0.85, 0.08), 30.0)
			# צרור כבלים
			var pts := PackedVector2Array()
			for q in 9:
				var u := float(q) / 8.0
				pts.append(Vector2(x + 100.0 + u * 600.0, 200.0 + sin(u * PI) * 50.0 + sin(t * 0.7 + float(k)) * 3.0))
			ci.draw_polyline(pts, Color(0.04, 0.05, 0.06, 0.9), 3.0))
	# שכבה 3 (קרובה): עמודים וצינורות כהים, כבלים מתנדנדים, ניצוצות, נורות חירום
	bg.add_layer(0.60, func(ci: CanvasItem, sc: float, v: Vector2, t: float):
		var period := 1150.0
		var start := int(floor(sc / period)) - 1
		for k in range(start, start + int(v.x / period) + 3):
			var x := float(k) * period - sc
			for j in 2:
				var px := x + 180.0 + float(j) * 560.0
				ci.draw_rect(Rect2(px, 0, 34, v.y), Color("080b0e"))
				ci.draw_rect(Rect2(px + 4, 0, 4, v.y), Color(1, 1, 1, 0.03))
				for q in 5:   # ברגים / טבעות
					ci.draw_rect(Rect2(px - 3, 80 + q * 110, 40, 6), Color("0c1013"))
				# כבל מתנדנד
				var sw := sin(t * 1.2 + float(j) + float(k)) * 10.0
				ci.draw_polyline(PackedVector2Array([Vector2(px + 34, 70), Vector2(px + 60 + sw * 0.5, 150), Vector2(px + 70 + sw, 220)]), Color("05070a"), 2.5, true)
				# ניצוץ מקצה הכבל מדי פעם
				var cyc := fmod(t + float(j * 3 + k), 4.0)
				if cyc < 0.15:
					var sp := Vector2(px + 70 + sw, 222)
					ci.draw_circle(sp, 10.0, Color(0.6, 0.8, 1.0, 0.35))
					for q in 4:
						ci.draw_line(sp, sp + Vector2(randf_range(-14, 14), randf_range(0, 20)), Color(0.8, 0.9, 1.0, 0.8), 1.2)
			# צינור אופקי עבה למעלה
			ci.draw_rect(Rect2(x, 40, period, 22), Color("0a0d10"))
			# נורת חירום אדומה פועמת
			var pa := 0.5 + 0.5 * sin(t * 4.0 + float(k))
			ci.draw_circle(Vector2(x + 450.0, 70), 7.0, Color(1.0, 0.15, 0.08, 0.5 + 0.5 * pa))
			ci.draw_circle(Vector2(x + 450.0, 70), 40.0, Color(1.0, 0.1, 0.05, 0.08 * pa))
		Kit.ground_fade(ci, v, 560.0))
	layer.add_child(bg)
	return bg


# ============================================================
#  העולם
# ============================================================
func build_world() -> void:
	var fy := floor_y
	var W := level_w
	# קירות, תקרה ורצפה לאורך כל השלב (חתיכות של 1024)
	var x := 0.0
	while x < W:
		var wall := Decor.LabWall.new()
		wall.position = Vector2(x, fy)
		wall.floor_y = fy
		wall.seed_v = rng.randi()
		main.add_child(wall)
		var ft := Decor.FloorTiles.new()
		ft.position = Vector2(x, fy)
		ft.seed_v = rng.randi()
		main.add_child(ft)
		x += 1024.0
	var entry := SignBoard.new()
	entry.text = "SECTOR 8 - BIOLAB  B4"
	entry.position = Vector2(260.0, fy - 250.0)
	main.add_child(entry)

	# ---- A: מסדרון מפוצל (למעלה בטוח מסכנות / למטה מסוכן עם פרסים) ----
	var ax := W * 0.11
	var aw := W * 0.18
	add_floor(ax, fy - FLOOR2, aw, "lab", true, true)
	add_ladder(ax + 30.0, fy - FLOOR2)
	add_ladder(ax + aw - 30.0, fy - FLOOR2)
	reserve(Rect2(ax - 40.0, fy - FLOOR2, aw + 80.0, FLOOR2))
	var lower_route := [[0.18, "acid", 90.0], [0.33, "electro", 130.0], [0.55, "acid", 110.0], [0.78, "electro", 120.0]]
	for lr in lower_route:
		var hx: float = ax + aw * float(lr[0])
		if lr[1] == "acid":
			_leak(hx, fy, float(lr[2]), fy - FLOOR2 + 18.0)
		else:
			_electro(hx, fy, float(lr[2]), float(lr[0]) * 3.0)
	_pickup(PickupScript.AMMO, ax + aw * 0.26)
	_pickup(PickupScript.GRENADE, ax + aw * 0.66)
	_pickup(PickupScript.AMMO, ax + aw * 0.9)
	lab_prop("bench", ax + aw * 0.43, 90.0, 34.0)
	var sign_a := SignBoard.new()
	sign_a.text = "UPPER LAB  ->"
	sign_a.position = Vector2(ax - 120.0, fy - FLOOR2 - 60.0)
	main.add_child(sign_a)
	var sign_b := SignBoard.new()
	sign_b.text = "!! CHEMICAL LEAK"
	sign_b.color = Color(0.5, 1.0, 0.3)
	sign_b.position = Vector2(ax - 120.0, fy - 70.0)
	main.add_child(sign_b)

	# ---- B: אטריום כליאה אנכי ----
	var bx := W * 0.34
	add_floor(bx, fy - FLOOR2, 520.0, "lab", true, true)
	add_ladder(bx + 30.0, fy - FLOOR2)
	var wall_x := bx + 520.0
	add_block(wall_x, fy - 270.0, 70.0, 270.0, Color("3e464e"), false, 2)
	var bw := BlastWall.new()
	bw.size = Vector2(70.0, 270.0)
	bw.position = Vector2(wall_x, fy - 270.0)
	main.add_child(bw)
	add_floor(wall_x + 70.0, fy - FLOOR2, 460.0, "lab", true, true)
	add_ladder(wall_x + 70.0 + 430.0, fy - FLOOR2)
	add_floor(bx + 110.0, fy - 330.0, 340.0, "steel", false, true)
	add_ladder(bx + 150.0, fy - 330.0, fy - FLOOR2)
	reserve(Rect2(bx - 60.0, fy - 340.0, 520.0 + 70.0 + 460.0 + 120.0, 340.0))
	_pickup(PickupScript.BOOST, bx + 300.0, fy - 330.0)
	_pickup(PickupScript.AMMO, wall_x + 250.0, fy - FLOOR2)
	for i in 2:   # מיכלים ענקיים באטריום (קישוט מונפש)
		var lt := Decor.LiquidTank.new()
		lt.position = Vector2(bx + 140.0 + float(i) * 230.0, fy)
		lt.height = 150.0
		lt.radius = 34.0
		lt.seed_v = rng.randi()
		main.add_child(lt)
	_electro(wall_x + 240.0, fy, 120.0, 1.0)

	# ---- C: אולם צינורות כליאה ----
	var cx := W * 0.48
	var tubes := [[0.05, Registry.DODGER], [0.42, -1], [0.78, Registry.ADAPTOR]]
	for tb in tubes:
		var tx: float = cx + W * 0.14 * float(tb[0])
		var t = BurstTube.new()
		t.release_kind = int(tb[1])
		t.stage = self
		add_hazard(t, Vector2(tx, fy))
		reserve(Rect2(tx - 50.0, fy - 120.0, 100.0, 120.0))
	_electro(cx + W * 0.14 * 0.24, fy, 110.0, 0.5)
	_electro(cx + W * 0.14 * 0.6, fy, 110.0, 2.2)
	var catw := cx + W * 0.14 * 0.12
	add_floor(catw, fy - 150.0, W * 0.14 * 0.66, "steel", true, true)
	add_ladder(catw + 20.0, fy - 150.0)
	reserve(Rect2(catw - 30.0, fy - 150.0, 60.0, 150.0))
	_pickup(PickupScript.AMMO, catw + 300.0, fy - 150.0)

	# ---- D: חדר שרתים (למעלה חשמל + פרסים / למטה אדים) ----
	var dx := W * 0.65
	var dw := W * 0.14
	add_floor(dx, fy - FLOOR2, dw, "lab", true, true)
	add_ladder(dx + 30.0, fy - FLOOR2)
	add_ladder(dx + dw - 30.0, fy - FLOOR2)
	reserve(Rect2(dx - 40.0, fy - FLOOR2, 80.0, FLOOR2))
	reserve(Rect2(dx + dw - 40.0, fy - FLOOR2, 80.0, FLOOR2))
	_electro(dx + dw * 0.3, fy - FLOOR2, 120.0, 0.0)
	_electro(dx + dw * 0.62, fy - FLOOR2, 120.0, 1.7)
	_pickup(PickupScript.GRENADE, dx + dw * 0.45, fy - FLOOR2)
	_pickup(PickupScript.AMMO, dx + dw * 0.8, fy - FLOOR2)
	for i in 3:   # אדים רותחים בקומה התחתונה
		var vx := dx + dw * (0.2 + 0.3 * float(i))
		var sv = Ambient.SteamVent.new()
		sv.hazard = true
		sv.period = 3.6 + float(i) * 0.5
		add_world(sv, Vector2(vx, fy))
		reserve(Rect2(vx - 30.0, fy - 70.0, 60.0, 70.0))
	for i in 6:   # מסופים על הקומה העליונה
		var s = Ambient.Screen.new()
		s.size = Vector2(26, 18)
		s.color = Color(0.3, 0.9, 0.8) if i % 2 == 0 else Color(1.0, 0.4, 0.3)
		add_world(s, Vector2(dx + 60.0 + float(i) * dw / 6.5, fy - FLOOR2 - 70.0))

	# ---- E: ארנת הבוס - מכולות להסתתר מאחוריהן ----
	lab_prop("crate", W - 760.0, 56.0, 50.0)
	lab_prop("crate", W - 640.0, 50.0, 44.0)
	lab_prop("bench", W - 395.0, 80.0, 34.0)
	var sign_e := SignBoard.new()
	sign_e.text = "CONTAINMENT CORE - SUBJECT 0"
	sign_e.position = Vector2(W - 900.0, fy - 280.0)
	main.add_child(sign_e)


# דליפת כימיקלים: צינור סדוק + שלולית חומצה קבועה
func _leak(x: float, fy: float, w: float, pipe_y: float) -> void:
	var pool = AcidPool.new()
	pool.setup(w, -1.0)
	add_hazard(pool, Vector2(x, fy))
	var lp := Decor.LeakPipe.new()
	lp.fall = fy - pipe_y - 6.0
	add_world(lp, Vector2(x, pipe_y))
	reserve(Rect2(x - w * 0.5 - 20.0, fy - 30.0, w + 40.0, 30.0))


func _electro(x: float, y: float, w: float, phase: float) -> void:
	var e = ElectroFloor.new()
	e.setup(w, phase)
	add_hazard(e, Vector2(x, y))
	reserve(Rect2(x - w * 0.5 - 10.0, y - 20.0, w + 20.0, 20.0))
	var sp = Ambient.SparkEmitter.new()   # כבל קרוע מעל הלוח
	sp.period = 3.0
	add_world(sp, Vector2(x + w * 0.3, y - 120.0))


func _pickup(kind: int, x: float, y := -1.0) -> void:
	var p = PickupScript.new()
	p.kind = kind
	p.boost = rng.randi() % 5
	p.life = 100000.0
	main.add_child(p)
	p.setup(Vector2(x, (floor_y if y < 0.0 else y) - 30.0), Vector2.ZERO)


func build_effects() -> void:
	screen_layer.add_child(Ambient.screen_particles("spores", vp))
	screen_layer.add_child(Ambient.screen_particles("dust", vp))
	var ap := Decor.AlarmPulse.new()
	ap.vp = vp
	screen_layer.add_child(ap)
	# נורות ניאון קרות מהבהבות מתחת לתקרה
	var x := 380.0
	while x < level_w:
		var fl = Ambient.FlickerLight.new()
		fl.color = Color(0.75, 0.92, 1.0)
		fl.radius = 85.0
		fl.mode = "flicker" if rng.randf() < 0.45 else "steady"
		add_world(fl, Vector2(x, 64.0))
		x += rng.randf_range(300.0, 480.0)
	# נורות חירום אדומות פועמות על הקירות
	x = 900.0
	while x < level_w:
		var al = Ambient.FlickerLight.new()
		al.color = Color(1.0, 0.15, 0.08)
		al.radius = 60.0
		al.mode = "pulse"
		add_world(al, Vector2(x, floor_y - 300.0))
		x += rng.randf_range(800.0, 1100.0)
	# ניצוצות מכבלים קרועים + אדים מצינורות (קישוט)
	x = 600.0
	while x < level_w:
		var sp = Ambient.SparkEmitter.new()
		sp.period = rng.randf_range(2.0, 4.0)
		add_world(sp, Vector2(x, rng.randf_range(80.0, 140.0)))
		if rng.randf() < 0.6:
			var sv = Ambient.SteamVent.new()
			sv.dir = Vector2(1.0 if rng.randf() < 0.5 else -1.0, 0.0)
			add_world(sv, Vector2(x + 200.0, floor_y - rng.randf_range(220.0, 320.0)))
		x += rng.randf_range(700.0, 1000.0)


func extra_spawns() -> void:
	var fy := floor_y
	var W := level_w
	# A: שומרי המסדרון העליון
	spawn(Registry.HUNTER, W * 0.11 + W * 0.18 * 0.45, fy - FLOOR2)
	spawn(Registry.ADAPTOR, W * 0.11 + W * 0.18 * 0.75, fy - FLOOR2)
	spawn(Registry.ADAPTOR, W * 0.11 + W * 0.18 * 0.6)
	# B: סירנה למעלה באטריום + צייד בצד השני
	spawn(Registry.SIREN, W * 0.34 + 400.0, fy - 330.0)
	spawn(Registry.HUNTER, W * 0.34 + 520.0 + 70.0 + 200.0, fy - FLOOR2)
	spawn(Registry.DODGER, W * 0.34 + 260.0)
	# C: טנק (לא בוס) באולם הצינורות
	spawn(Registry.TANK, W * 0.48 + W * 0.14 * 0.95)
	spawn(Registry.DODGER, W * 0.48 + W * 0.14 * 0.5, fy - 150.0)
	# D: סירנה למטה, צייד + מסתגל למעלה
	spawn(Registry.SIREN, W * 0.65 + W * 0.14 * 0.85)
	spawn(Registry.HUNTER, W * 0.65 + W * 0.14 * 0.5, fy - FLOOR2)
	spawn(Registry.ADAPTOR, W * 0.65 + W * 0.14 * 0.25, fy - FLOOR2)


# אזעקה רחוקה מדי פעם (אווירה)
func _process(delta: float) -> void:
	_klaxon_t -= delta
	if _klaxon_t <= 0.0:
		_klaxon_t = rng.randf_range(25.0, 40.0) if rng != null else 30.0
		Sfx.play("s8_klaxon", null, -16.0, 0.0, 1)


# ---- קישוטים קטנים ----
# שלט מואר בעולם
class SignBoard extends Node2D:
	var text := "SECTOR 8"
	var color := Color(0.95, 0.8, 0.25)

	func _ready() -> void:
		z_index = -2

	func _draw() -> void:
		var f := ThemeDB.fallback_font
		var w := f.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 14).x
		draw_rect(Rect2(-6, -16, w + 12, 22), Color(0.06, 0.07, 0.08, 0.95))
		draw_rect(Rect2(-6, -16, w + 12, 22), Color(color, 0.7), false, 1.5)
		draw_string(f, Vector2(0, 0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, color)
		draw_line(Vector2(w * 0.2, -16), Vector2(w * 0.2, -40), Color("1a1e22"), 2.0)
		draw_line(Vector2(w * 0.8, -16), Vector2(w * 0.8, -40), Color("1a1e22"), 2.0)


# קיר החסימה באטריום (מעל הבלוק המוצק)
class BlastWall extends Node2D:
	const Art := preload("res://art.gd")
	var size := Vector2(70, 270)

	func _ready() -> void:
		z_index = 1

	func _draw() -> void:
		var w := size.x
		var h := size.y
		Art.fill_shaded(self, PackedVector2Array([Vector2(0, 0), Vector2(w, 0), Vector2(w, h), Vector2(0, h)]), Color("3e464e"), 0.15, 0.35)
		for i in 5:
			draw_rect(Rect2(4, 20 + i * 50, w - 8, 4), Color("2a3036"))
		var y := h - 30.0
		draw_rect(Rect2(0, y, w, 22), Color(0.85, 0.7, 0.1))
		var sx := 0.0
		while sx < w:
			draw_colored_polygon(PackedVector2Array([Vector2(sx, y + 22), Vector2(sx + 22, y), Vector2(sx + 30, y), Vector2(sx + 8, y + 22)]), Color(0.08, 0.08, 0.08))
			sx += 16.0
		draw_rect(Rect2(0, 0, w, 6), Color("5a646c"))
		draw_circle(Vector2(w * 0.5, 40), 6.0, Color(0.9, 0.1, 0.05))
		Art.glow(self, Vector2(w * 0.5, 40), 18.0, Color(1.0, 0.1, 0.05, 0.4))
		var f := ThemeDB.fallback_font
		for i in 6:   # "SEALED" אנכי
			draw_string(f, Vector2(w * 0.5 - 5, 80 + i * 16), "SEALED"[i], HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.9, 0.85, 0.75, 0.8))
		for i in 4:   # שקעים של אגרופים מבפנים
			var c := Vector2(14 + (i % 2) * 36, 150 + i * 18)
			draw_arc(c, 7.0, 0, TAU, 10, Color(0.2, 0.22, 0.25), 2.0)
