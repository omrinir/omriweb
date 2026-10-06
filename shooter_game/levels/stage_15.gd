extends "res://levels/stage_base.gd"
# ============================================================
#  STAGE 15 - "CARNIVAL OF THE DEAD" (אזור צפון-מזרח, שלב 6) - "THEY DANCE WITH DEATH"
#  בוקר אחרי קרנבל שלא נגמר באולינדה: שמש זהובה נמוכה, שמיים תכולים, הים ומגדלי רסיפה באובך,
#  גבעה עם בתים קולוניאליים בצבעי פסטל וכנסיות לבנות. ברחוב: "סוברדוס" צבעוניים עם מרפסות,
#  דגלוני קרנבל מעל הרחוב, בובות הענק של אולינדה (חלקן נפלו), עגלות מצעד נטושות, קונפטי בכל מקום.
#  עגלות המצעד (FLOATS) = קומה שנייה בחלק מהשלב (עולים בסולם, יורדים: S פעמיים).
#  זומבים: BOMBHEAD (זורק את הראש ואז רץ בלי ראש ומתפוצץ), MINIGUNNER (מרסס במיניגאן, לא מדויק),
#    STILTER (רגליים ארוכות ומכופפות, זינוקים ענקיים), CRUMBLER (כל קליע תולש חלק), WALKER, RUNNER.
#  בוס: STILTER ענק - "THE BONECO" (בובת אולינדה ענקית, נחיתה עם גל הדף).
#  לשנות: FLOATS, PUPPET_GAP, zombie_weights().
# ============================================================

const WeaponDB := preload("res://weapons/weapon_db.gd")
const Decor := preload("res://effects/s15_decor.gd")
const S11 := preload("res://effects/s11_decor.gd")

const FLOATS := [[0.22, 380.0], [0.5, 440.0], [0.78, 400.0]]   # [מיקום יחסי, אורך] עגלות המצעד
const FLOAT_H := 130.0
const PUPPET_GAP := Vector2(700.0, 1200.0)

var _float_spans := []


func zombie_weights() -> Dictionary:
	return {0: 0.12, 1: 0.1, Registry.BOMBHEAD: 0.22, Registry.MINIGUNNER: 0.12, Registry.STILTER: 0.22, Registry.CRUMBLER: 0.18}


func generators() -> Array:
	return [["drums", 1.6], ["stall", 1.3], ["crates", 0.8], ["barrels", 0.8]]


func custom_gen(gname: String, x: float) -> float:
	if not gname in ["drums", "stall"]:
		return 0.0
	if _in_float(x - 30.0) or _in_float(x + 120.0):
		return 120.0
	var o := Decor.Obstacle.new()
	o.kind = gname
	o.seed_v = rng.randi()
	o.size = Vector2(rng.randf_range(75.0, 105.0), 40.0) if gname == "drums" else Vector2(rng.randf_range(60.0, 80.0), rng.randf_range(34.0, 44.0))
	o.position = Vector2(x, floor_y)
	main.add_child(o)
	reserve(Rect2(x, floor_y - o.size.y, o.size.x, o.size.y))
	return o.size.x


func weapon_offers() -> Array:
	return [WeaponDB.ASSAULT_RIFLE, WeaponDB.ASSAULT_SHOTGUN, WeaponDB.GRENADE_LAUNCHER]


func boss_kind() -> int:
	return Registry.STILTER


func music() -> String:
	return "res://music/level1_total_war.mp3"


func world_tint() -> Color:
	return Color(1.0, 0.97, 0.92)


func fog() -> bool:
	return false


func pits() -> int:
	return 1


func _in_float(x: float) -> bool:
	for s in _float_spans:
		if x > float(s[0]) - 30.0 and x < float(s[1]) + 30.0:
			return true
	return false


# ---- רקע ----
func build_background(layer: CanvasLayer) -> Node:
	var bg = Backdrop.new()
	bg.level_w = level_w
	bg.sky = func(ci: CanvasItem, v: Vector2, t: float):
		Decor.morning_sky(ci, v, t)
	bg.add_layer(0.06, func(ci: CanvasItem, sc: float, v: Vector2, t: float):
		Decor.sea_and_recife(ci, sc, v, 470.0, t))
	bg.add_layer(0.22, func(ci: CanvasItem, sc: float, v: Vector2, t: float):
		Decor.olinda_hill(ci, sc, v, 560.0, t))
	# שכבה קרובה: גגות + דגלונים בין הבתים
	bg.add_layer(0.5, func(ci: CanvasItem, sc: float, v: Vector2, t: float):
		var period := 640.0
		var start := int(floor(sc / period)) - 1
		for k in range(start, start + 4):
			var x := float(k) * period - sc
			var r := RandomNumberGenerator.new()
			r.seed = k * 53 + 7
			for i in 4:
				var bw := r.randf_range(90.0, 150.0)
				var bh := r.randf_range(70.0, 120.0)
				var c: Color = Decor.PASTELS[r.randi() % Decor.PASTELS.size()]
				ci.draw_rect(Rect2(x + float(i) * 160.0, 600.0 - bh, bw, bh), c.lerp(Color(0.95, 0.9, 0.85), 0.4))
				ci.draw_rect(Rect2(x + float(i) * 160.0 - 3.0, 594.0 - bh, bw + 6.0, 7.0), Color("c87048"))
			Decor.bunting_line(ci, Vector2(x + 40.0, 470.0), Vector2(x + 600.0, 480.0), 40.0, t, k)
		Kit.ground_fade(ci, v, 595.0))
	layer.add_child(bg)
	return bg


# ---- העולם ----
func build_world() -> void:
	for fl in FLOATS:   # עגלות מצעד = קומה שנייה
		var ox := level_w * float(fl[0])
		var w: float = fl[1]
		if main._in_pit(ox - 40.0, ox + w + 40.0, 20.0):
			continue
		var f := Decor.ParadeFloat.new()
		f.w = w
		f.h = FLOAT_H
		f.seed_v = rng.randi()
		add_world(f, Vector2(ox, floor_y))
		add_floor(ox, floor_y - FLOAT_H, w, "wood", false, true)
		add_ladder(ox + 18.0, floor_y - FLOAT_H)
		add_ladder(ox + w - 18.0, floor_y - FLOAT_H)
		reserve(Rect2(ox - 40.0, floor_y - FLOAT_H, w + 80.0, FLOAT_H))
		_float_spans.append([ox, ox + w])
	var x := 0.0
	while x < level_w:   # שורת בתים קולוניאליים
		var row := Decor.ColonialRow.new()
		row.position = Vector2(x, floor_y)
		row.seed_v = rng.randi()
		for s in _float_spans:
			row.skip.append([float(s[0]) - x, float(s[1]) - x])
		main.add_child(row)
		x += 1024.0
	# בובות ענק של אולינדה (חלקן נפלו)
	var px := rng.randf_range(500.0, 900.0)
	while px < level_w - 600.0:
		if not _in_float(px) and free_x(px, 60.0):
			var gp := Decor.GiantPuppet.new()
			gp.seed_v = rng.randi()
			gp.fallen = rng.randf() < 0.3
			add_world(gp, Vector2(px, floor_y))
		px += rng.randf_range(PUPPET_GAP.x, PUPPET_GAP.y)
	# דגלונים מעל הרחוב (מ-s11)
	var bx := 400.0
	while bx < level_w - 700.0:
		var b := S11.Bunting.new()
		b.w = rng.randf_range(360.0, 540.0)
		b.h = 220.0
		b.seed_v = rng.randi() % 50
		add_world(b, Vector2(bx, floor_y))
		bx += b.w + rng.randf_range(400.0, 900.0)


func build_effects() -> void:
	var conf := Ambient.screen_particles("dust", vp)   # קונפטי עף ברוח
	conf.color = Color(1.0, 0.6, 0.6, 0.8)
	conf.hue_variation_min = -1.0
	conf.hue_variation_max = 1.0
	conf.amount = 40
	conf.scale_amount_min = 1.5
	conf.scale_amount_max = 3.0
	conf.direction = Vector2(-1, 0.4)
	conf.initial_velocity_min = 30.0
	conf.initial_velocity_max = 80.0
	screen_layer.add_child(conf)


# על העגלות: MINIGUNNER (מרסס מלמעלה). ברחוב: STILTER, וגם CRUMBLER שוכבים בקונפטי
func extra_spawns() -> void:
	for s in _float_spans:
		var x0: float = s[0]
		var x1: float = s[1]
		spawn(Registry.MINIGUNNER, (x0 + x1) * 0.5, floor_y - FLOAT_H)
		spawn(Registry.STILTER, x1 + 160.0)
	for i in 4:
		var cx := level_w * (0.15 + 0.2 * float(i)) + rng.randf_range(-120.0, 120.0)
		if free_x(cx, 20.0) and not _in_float(cx) and not main._in_pit(cx - 30.0, cx + 30.0, 10.0):
			var z = spawn(Registry.CRUMBLER, cx)
			if z != null:
				z.lie_down()
