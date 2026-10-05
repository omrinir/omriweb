extends "res://levels/stage_base.gd"
# ============================================================
#  STAGE 13 - "DUNES OF BONE" (אזור צפון-מזרח, שלב 4) - "THEY RISE FROM THE SAND"
#  ים של דיונות לבנות עם לגונות טורקיז (השראה: לנסואיס מרניינסס), מלא עצמות: שלד לווייתן
#  ענק, גולגולות שוורים מהסרטאו, כלובי צלעות, עצים מתים מולבנים. צהריים לבנים ולוהטים.
#  השטח: דיונות אמיתיות שהולכים עליהן (environment/s13_dunes.gd -> Dune) - עולים ויורדים,
#    והן חוסמות קליעים (מחסה) וגם את זרם החול של ה-SANDBLASTER.
#  סופות חול מחזוריות (SandStorm): המסך מתערפל, הזומבים רואים אותך פחות.
#  זומבים: GRAVEBORN (מגיע מתוך האדמה: תל חול שזז אליך, סדקים, התפרצות), SANDBLASTER
#    (מכשיר שיורה זרם חול), MIMIC (הילדה שמשתנה), WALKER, RUNNER.
#  בוס: GRAVEBORN ענק - "THE OSSUARY".
#  לשנות: DUNE_W, DUNE_GAP, zombie_weights().
# ============================================================

const WeaponDB := preload("res://weapons/weapon_db.gd")
const Decor := preload("res://effects/s13_decor.gd")
const Dunes := preload("res://environment/s13_dunes.gd")

const DUNE_W := Vector2(520.0, 900.0)
const DUNE_GAP := Vector2(260.0, 620.0)
var _dunes := []


func zombie_weights() -> Dictionary:
	return {0: 0.16, 1: 0.12, Registry.GRAVEBORN: 0.22, Registry.SANDBLASTER: 0.2, Registry.MIMIC: 0.08}


func generators() -> Array:
	return [["ribcage", 2.0], ["rock", 2.0]]


# מכשולים - רק מחוץ לדיונות (אחרת מחזירים רוחב כדי לדלג)
func custom_gen(gname: String, x: float) -> float:
	var o := Decor.Obstacle.new()
	o.kind = gname
	o.seed_v = rng.randi()
	o.size = Vector2(rng.randf_range(80.0, 110.0), 32.0) if gname == "ribcage" else Vector2(rng.randf_range(60.0, 90.0), rng.randf_range(34.0, 48.0))
	if not free_x(x, 10.0) or not free_x(x + o.size.x, 10.0):
		o.free()
		return 80.0
	o.position = Vector2(x, floor_y)
	main.add_child(o)
	reserve(Rect2(x, floor_y - o.size.y, o.size.x, o.size.y))
	return o.size.x


func weapon_offers() -> Array:
	return [WeaponDB.ASSAULT_SHOTGUN, WeaponDB.SMG, WeaponDB.SNIPER]


func boss_kind() -> int:
	return Registry.GRAVEBORN


func music() -> String:
	return "res://music/level2_suspense.mp3"


func world_tint() -> Color:
	return Color(1.0, 0.98, 0.93)


func fog() -> bool:
	return false


func pits() -> int:
	return 1


# גובה פני הקרקע (דיונה או כביש) בנקודה x
func surface_y(x: float) -> float:
	for d in _dunes:
		var y: float = d.surface_y(x)
		if y != INF:
			return y
	return floor_y


# ---- רקע ----
func build_background(layer: CanvasLayer) -> Node:
	var bg = Backdrop.new()
	bg.level_w = level_w
	bg.sky = func(ci: CanvasItem, v: Vector2, t: float):
		Kit.gradient_sky(ci, v, [Color("8ab0c8"), Color("b0cad6"), Color("d8e2e0"), Color("f0ead8"), Color("f4e8c8")])
		var sun := Vector2(v.x * 0.5, 90.0)
		for i in 4:
			ci.draw_circle(sun, 120.0 - float(i) * 25.0, Color(1.0, 1.0, 0.95, 0.08 + float(i) * 0.04))
		ci.draw_circle(sun, 34.0, Color(1.0, 1.0, 0.97))
		for i in 3:   # נשרים חגים
			var c := Vector2(v.x * (0.3 + 0.2 * float(i)), 160.0 + float(i) * 25.0)
			var a := t * (0.3 + 0.08 * float(i)) + float(i) * 2.2
			var p := c + Vector2(cos(a) * 80.0, sin(a) * 20.0)
			var fl := sin(t * 2.5 + float(i)) * 3.0
			ci.draw_polyline(PackedVector2Array([p + Vector2(-12, -2 + fl), p + Vector2(-4, 1), p, p + Vector2(4, 1), p + Vector2(12, -2 + fl)]), Color(0.15, 0.12, 0.1, 0.75), 2.0)
		for i in 4:   # מיראז' - פס רועד באופק
			var y := 470.0 + float(i) * 4.0
			ci.draw_line(Vector2(0, y + sin(t * 3.0 + float(i)) * 1.5), Vector2(v.x, y + sin(t * 2.6 + float(i) * 2.0) * 1.5), Color(0.75, 0.85, 0.9, 0.12), 3.0)
	# שכבה 1: דיונות לבנות רחוקות עם לגונות, שלד לווייתן ענק
	bg.add_layer(0.10, func(ci: CanvasItem, sc: float, v: Vector2, t: float):
		Decor.dune_band(ci, sc, v, 500.0, 60.0, Color("d6ccb4"), Color("5ac0c8"), 3)
		var period := 1800.0
		var start := int(floor(sc / period)) - 1
		for k in range(start, start + 3):
			var x := float(k) * period - sc
			Decor.whale(ci, Vector2(x + 600.0, 470.0), 1.1, Color("b8b0a0")))
	# שכבה 2: דיונות קרובות יותר, גולגולות על הרכסים, עצים מתים
	bg.add_layer(0.30, func(ci: CanvasItem, sc: float, v: Vector2, t: float):
		Decor.dune_band(ci, sc, v, 560.0, 80.0, Color("ddd2b8"), Color("48b0b8"), 7)
		var period := 1100.0
		var start := int(floor(sc / period)) - 1
		for k in range(start, start + 3):
			var x := float(k) * period - sc
			var r := RandomNumberGenerator.new()
			r.seed = k * 401 + 9
			for q in 3:
				Decor.dead_tree(ci, Vector2(x + r.randf_range(0.0, period), 560.0), r.randf_range(60.0, 100.0), Color("a89c88"), k * 3 + q)
			Decor.ox_skull(ci, Vector2(x + r.randf_range(200.0, 900.0), 520.0), 1.6, Color("e8e0cc"), Color("6a5a48"))
		Kit.ground_fade(ci, v, 600.0))
	# שכבה 3: רכסי דיונות קרובים עם עצמות
	bg.add_layer(0.60, func(ci: CanvasItem, sc: float, v: Vector2, t: float):
		Decor.dune_band(ci, sc, v, 625.0, 50.0, Color("cfc0a0"), Color(0, 0, 0, 0), 11)
		var period := 900.0
		var start := int(floor(sc / period)) - 1
		for k in range(start, start + 3):
			var x := float(k) * period - sc
			for i in 5:
				ci.draw_arc(Vector2(x + 300.0 + float(i) * 14.0, 610.0), 22.0, PI + 0.3, TAU - 0.6, 8, Color("e0d8c4"), 3.0)
		Kit.ground_fade(ci, v, 600.0))
	layer.add_child(bg)
	return bg


# ---- העולם: דיונות אמיתיות ----
func build_world() -> void:
	var x := 900.0
	while x < level_w - 1300.0:
		var w := rng.randf_range(DUNE_W.x, DUNE_W.y)
		var h := minf(w * rng.randf_range(0.12, 0.19), 150.0)
		if main._in_pit(x - 60.0, x + w + 60.0, 20.0):
			x += 200.0
			continue
		var d := Dunes.Dune.new()
		d.w = w
		d.h = h
		d.seed_v = rng.randi()
		d.position = Vector2(x, floor_y)
		main.add_child(d)
		_dunes.append(d)
		reserve(Rect2(x, floor_y - h, w, h))
		x += w + rng.randf_range(DUNE_GAP.x, DUNE_GAP.y)
	var sinker := Dunes.DuneSinker.new()   # דמויות על הדיונות שוקעות קצת בחול (לא מרחפות)
	sinker.dunes = _dunes
	main.add_child(sinker)
	var bx := 0.0
	while bx < level_w:
		var f := Decor.BoneField.new()
		f.position = Vector2(bx, floor_y)
		f.seed_v = rng.randi()
		main.add_child(f)
		bx += 1024.0


func build_effects() -> void:
	var sand := Ambient.screen_particles("dust", vp)
	sand.color = Color(0.95, 0.88, 0.7, 0.3)
	sand.direction = Vector2(-1, 0.05)
	sand.initial_velocity_min = 30.0
	sand.initial_velocity_max = 70.0
	screen_layer.add_child(sand)
	var storm := Dunes.SandStorm.new()
	storm.vp = vp
	screen_layer.add_child(storm)


# על הדיונות: GRAVEBORN קבורים ו-SANDBLASTER על הרכס. בעמקים: מתחזות
func extra_spawns() -> void:
	for d in _dunes:
		var dx: float = d.position.x
		var dw: float = d.w
		var top_x := dx + dw * 0.5
		spawn(Registry.SANDBLASTER if rng.randf() < 0.5 else Registry.GRAVEBORN, top_x, surface_y(top_x) - 2.0)
		if rng.randf() < 0.6:
			var sx := dx + dw * rng.randf_range(0.2, 0.35)
			spawn(Registry.GRAVEBORN, sx, surface_y(sx) - 2.0)
	for i in 3:
		var mx := level_w * (0.2 + 0.28 * float(i)) + rng.randf_range(-100.0, 100.0)
		if free_x(mx, 20.0) and not main._in_pit(mx - 30.0, mx + 30.0, 10.0):
			spawn(Registry.MIMIC, mx)
