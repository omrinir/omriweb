extends "res://levels/stage_base.gd"
# ============================================================
#  STAGE 7 - "THEY WATCH"
#  מפעל תעשייתי חשוך. שתי קומות: הריצפה + גשרי מתכת (catwalks) עם פערים,
#  סולמות, מעלית שזזה, מסועים, מכבשים, צינורות קיטור, כבלים חשמליים ודלתות.
#  זומבי ENGINEER רץ ללוחות בקרה ומפעיל את המכונות / סוגר דלתות עליך.
#  זומבים: AMBUSHER, TACTICIAN, SHIELDED, LEAPER, ENGINEER (+ מעט רגילים)
#  נשקים: SNIPER + רימונים נוספים
#  אפקטים: ניצוצות, קיטור, מכונות זזות, אורות אזהרה מהבהבים, גצים
#  רקע: effects/s7_backdrop.gd (3 שכבות פרלקסה), קישוטים: effects/s7_decor.gd
#  איך משנים: אורך קטע = SECTION, מה יש בכל קטע = _section()
# ============================================================

const WeaponDB := preload("res://weapons/weapon_db.gd")
const Back := preload("res://effects/s7_backdrop.gd")
const Decor := preload("res://effects/s7_decor.gd")
const Conveyor := preload("res://environment/s7_conveyor.gd")
const Press := preload("res://environment/s7_press.gd")
const SteamPipe := preload("res://environment/s7_steam_pipe.gd")
const LiveWire := preload("res://environment/s7_live_wire.gd")
const Door := preload("res://environment/s7_door.gd")
const Gate := preload("res://environment/s7_gate.gd")
const Lift := preload("res://environment/s7_lift.gd")
const Console := preload("res://environment/s7_console.gd")
const PickupScript := preload("res://pickup.gd")

const SECTION := 1400.0


func zombie_weights() -> Dictionary:
	return {0: 0.2, 1: 0.12, Registry.AMBUSHER: 0.14, Registry.TACTICIAN: 0.06, Registry.SHIELDED: 0.14,
		Registry.LEAPER: 0.16, Registry.ENGINEER: 0.06, 12: 0.04}


func generators() -> Array:
	return [["container", 2.0], ["crates", 2.0], ["barrels", 1.5], ["machine", 2.0], ["rubble", 1.0]]


# מכונה שבורה / גנרטור (מחסה)
func custom_gen(gname: String, x: float) -> float:
	if gname != "machine":
		return 0.0
	var m = Decor.Machine.new()
	m.size = Vector2(rng.randf_range(80, 120), rng.randf_range(44, 64))
	m.kind = rng.randi_range(0, 1)
	m.position = Vector2(x, floor_y)
	main.add_child(m)
	reserve(Rect2(x, floor_y - m.size.y, m.size.x, m.size.y))
	return m.size.x


func boss_kind() -> int:
	return 5   # שומר היציאה: הענק עם הדלת (המפעל שייך לו)


func music() -> String:
	return "res://music/level2_suspense.mp3"


func world_tint() -> Color:
	return Color(0.82, 0.78, 0.72)


func pits() -> int:
	return 1


func fog() -> bool:
	return true


func build_background(layer: CanvasLayer) -> Node:
	var bg = Backdrop.new()
	bg.level_w = level_w
	bg.sky = func(ci: CanvasItem, v: Vector2, t: float): Back.sky(ci, v, t)
	bg.add_layer(0.10, func(ci: CanvasItem, sc: float, v: Vector2, t: float): Back.far(ci, sc, v, t))
	bg.add_layer(0.30, func(ci: CanvasItem, sc: float, v: Vector2, t: float): Back.mid(ci, sc, v, t))
	bg.add_layer(0.60, func(ci: CanvasItem, sc: float, v: Vector2, t: float): Back.near(ci, sc, v, t))
	layer.add_child(bg)
	return bg


func build_world() -> void:
	# קיר המפעל מאחור (בחתיכות של 1024)
	var x := 0.0
	while x < level_w:
		var w = Decor.WallChunk.new()
		w.seed_v = rng.randi()
		w.position = Vector2(x, floor_y)
		main.add_child(w)
		x += 1024.0
	# עגורנים ומאווררים על הקיר
	var cx := 500.0
	while cx < level_w - 600.0:
		var cr = Decor.Crane.new()
		cr.position = Vector2(cx, floor_y - 470.0)
		main.add_child(cr)
		cx += rng.randf_range(1800.0, 2600.0)
	# קטעים: כל קטע = גשר עליון + מכונות + סכנות
	var sx := 700.0
	var i := 0
	while sx < level_w - 900.0:
		_section(sx, i)
		sx += SECTION
		i += 1
	_link_consoles()


func _section(sx: float, i: int) -> void:
	var cy := floor_y - FLOOR2
	# גשר מתכת עם פער באמצע
	var w1 := rng.randf_range(380.0, 520.0)
	add_floor(sx, cy, w1, "steel", true, true)
	var gap := rng.randf_range(110.0, 170.0)
	var w2 := rng.randf_range(300.0, 460.0)
	add_floor(sx + w1 + gap, cy, w2, "steel", true, true)
	add_ladder(sx + 24.0, cy)
	if i % 2 == 0:
		add_ladder(sx + w1 + gap + w2 - 24.0, cy)
	# מצלמת אבטחה (THEY WATCH)
	var cam = Decor.Cctv.new()
	cam.position = Vector2(sx + w1 * 0.5, cy - 70.0)
	main.add_child(cam)
	match i % 4:
		0:   # מסוע + מכבש מעליו
			var cv = Conveyor.new()
			cv.size = Vector2(320.0, 18.0)
			cv.speed = 70.0 if rng.randf() < 0.5 else -70.0
			cv.position = Vector2(sx + 120.0, floor_y - 18.0)
			main.add_child(cv)
			reserve(Rect2(sx + 100.0, floor_y - 200.0, 360.0, 200.0))
			var pr = Press.new()
			pr.anvil = false
			pr.position = Vector2(sx + 280.0, floor_y - 18.0)
			main.add_child(pr)
		1:   # צינור קיטור + כבל חשמלי + דלת מתחת לגשר
			var sp = SteamPipe.new()
			sp.dir = Vector2.DOWN
			sp.position = Vector2(sx + 200.0, cy + 10.0)
			main.add_child(sp)
			var lw = LiveWire.new()
			lw.position = Vector2(sx + w1 + gap * 0.5, floor_y)
			main.add_child(lw)
			var d = Door.new()
			d.height = FLOOR2 - 4.0
			d.position = Vector2(sx + w1 - 30.0, floor_y)
			main.add_child(d)
			reserve(Rect2(sx + 150.0, floor_y - 160.0, w1 + gap, 160.0))
		2:   # מעלית לקומה העליונה + מכבש על סדן
			var lf = Lift.new()
			lf.width = 100.0
			lf.low_y = floor_y
			lf.high_y = cy
			lf.position = Vector2(sx - 120.0, floor_y)
			main.add_child(lf)
			var pr2 = Press.new()
			pr2.position = Vector2(sx + w1 * 0.6, floor_y)
			main.add_child(pr2)
			reserve(Rect2(sx - 140.0, floor_y - 200.0, 140.0 + w1, 200.0))
		3:   # תריס נעול (דרך חלופית) + צינור קיטור אופקי
			var g = Gate.new()
			g.height = FLOOR2 - 42.0
			g.position = Vector2(sx + w1 * 0.5, floor_y)
			main.add_child(g)
			var sp2 = SteamPipe.new()
			sp2.dir = Vector2.LEFT
			sp2.position = Vector2(sx + w1 + gap + 200.0, floor_y - 26.0)
			main.add_child(sp2)
			reserve(Rect2(sx + w1 * 0.5 - 40.0, floor_y - 160.0, 80.0 + w1 + gap, 160.0))
	# לוח בקרה (ENGINEER) על הגשר
	var con = Console.new()
	con.position = Vector2(sx + w1 - 70.0, cy)
	main.add_child(con)
	# כיס חושך למארב
	var dp = Decor.DarkPocket.new()
	dp.position = Vector2(sx + w1 + gap + w2 * 0.5, floor_y)
	main.add_child(dp)
	# מאוורר + אור אזהרה
	var fan = Decor.WallFan.new()
	fan.position = Vector2(sx + w1 * 0.3, floor_y - 240.0)
	main.add_child(fan)
	var wl = Ambient.FlickerLight.new()
	wl.mode = "pulse"
	wl.color = Color(1.0, 0.45, 0.15)
	wl.radius = 70.0
	add_world(wl, Vector2(sx + w1 + gap * 0.5, cy - 40.0))


# מחבר כל לוח בקרה למכונות (triggerable) בטווח 700 פיקסלים
func _link_consoles() -> void:
	for c in main.get_tree().get_nodes_in_group("s7_consoles"):
		c.links.clear()
	for c in get_children_of_group("s7_consoles"):
		for h in get_children_of_group("hazards"):
			if h.get("triggerable") == true and absf(h.global_position.x - c.global_position.x) < 700.0:
				c.links.append(h)


# (הצמתים עדיין לא בעץ בזמן build_world - מחפשים בילדים של main)
func get_children_of_group(g: String) -> Array:
	var out := []
	for n in main.get_children():
		if n.is_in_group(g):
			out.append(n)
	return out


func build_effects() -> void:
	screen_layer.add_child(Ambient.screen_particles("embers", vp))
	screen_layer.add_child(Ambient.screen_particles("dust", vp))
	var fg = Decor.FgChains.new()
	main.add_child(fg)
	fg.position = Vector2(0, floor_y)
	var x := 400.0
	while x < level_w:
		var se = Ambient.SparkEmitter.new()
		add_world(se, Vector2(x, floor_y - FLOOR2 + 12.0))
		var sv = Ambient.SteamVent.new()
		add_world(sv, Vector2(x + 420.0, floor_y))
		x += rng.randf_range(700.0, 1100.0)


func extra_spawns() -> void:
	var sx := 700.0
	var i := 0
	while sx < level_w - 900.0:
		var cy := floor_y - FLOOR2
		if i % 2 == 0:
			spawn(Registry.LEAPER, sx + 200.0, cy)
		if i % 3 == 1:
			spawn(Registry.ENGINEER, sx + 120.0, cy)
		if i % 3 == 2:
			spawn(Registry.TACTICIAN, sx + 300.0, cy)
		sx += SECTION
		i += 1
	# רימונים נוספים לאורך המפעל
	for k in 3:
		var p = PickupScript.new()
		p.kind = PickupScript.AMMO   # רימונים = SPECIAL (1-2 בשלב)
		p.life = 100000.0
		main.add_child(p)
		p.setup(Vector2(level_w * (0.25 + 0.25 * float(k)), floor_y - FLOOR2 - 30.0), Vector2.ZERO)
