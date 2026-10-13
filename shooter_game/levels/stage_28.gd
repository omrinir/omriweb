extends "res://levels/stage_base.gd"
# ============================================================
#  STAGE 28 - "DEATH ROAD" (אזור רביעי - האנדים, שלב 1) - "THEY LEARNED TO WAIT"
#  "דרך המוות" של היונגס בבוליביה (effects/s28_decor.gd): כביש עפר צר חצוב בצוק בתוך יער עננים,
#  ערפל עולה מהעמק, מפלים על הכביש, אוטובוסים ומשאיות שהתרסקו, צלבים ומקדשונים בצד הדרך.
#  קומה שנייה: קטעי כביש עליונים חצובים בצוק (LEDGES) עם סולם.
#  מלכודות: Washout - הכביש נשבר (pits()): בור עם ברזלים חלודים, וערפל שמסתיר מה שתלוי בפנים.
#           WreckBus - אוטובוס שהתרסק (BUSES): דופקים בחלונות כשמתקרבים, ואז נוסעים זומבים יוצאים (PASSENGERS).
#  זומבים: CLINGER (תלוי על שפת הבור / הכביש העליון, תופס ומושך), BOULDER (סלעים מהכביש העליון), LEAPER, רגילים, רצים.
#  בוס: EL CAMIONERO (enemies/types/trucker.gd) - מסתער כמו משאית. לעמוד מול מכשול ולהתחמק = הוא מתרסק.
#  לשנות: LEDGES, BUSES, PASSENGERS, SHRINES, WATERFALLS, zombie_weights().
# ============================================================

const Decor := preload("res://effects/s28_decor.gd")
const PickupScript := preload("res://pickup.gd")
const Particles := preload("res://particles.gd")

const SOUNDS := {
	"w28_bang": [["C", 0, 0, 0.0, 0.1, 0.0, 30.0, 0.8, 1.0, 0], ["S", 120, 70, 0.0, 0.15, 0.0, 20.0, 0.6, 1.0, 0], ["C", 0, 0, 0.17, 0.1, 0.0, 30.0, 0.7, 1.0, 0], ["S", 110, 65, 0.17, 0.15, 0.0, 20.0, 0.5, 1.0, 0], ["C", 0, 0, 0.3, 0.08, 0.0, 34.0, 0.5, 1.0, 0]],
}

const WASHOUTS := 5
const LEDGES := [[0.16, 380.0], [0.39, 440.0], [0.62, 400.0], [0.84, 360.0]]   # [מיקום יחסי, רוחב]
const TIER := 150.0
const WATERFALLS := [1, 3]                 # באילו קטעי כביש עליון יש מפל
const BUSES := [0.29, 0.53, 0.76]
const PASSENGERS := 3
const TRUCKS := [0.46]
const SHRINES := [0.06, 0.21, 0.35, 0.5, 0.68, 0.9]
const HARDER := [1.0, 1.15, 1.3]

var _ledges := []          # [x0, x1]


func zombie_weights() -> Dictionary:
	return {Registry.CLINGER: 0.08, Registry.BOULDER: 0.08, Registry.LEAPER: 0.07, 0: 0.43, 1: 0.34}


func zombie_density() -> float:
	return 1.0 * float(HARDER[clampi(Settings.difficulty, 0, 2)])


func generators() -> Array:
	return [["slide_rocks", 1.3], ["fuel_drums", 0.9], ["luggage", 0.8]]


func custom_gen(gname: String, x: float) -> float:
	if not gname in ["slide_rocks", "fuel_drums", "luggage"]:
		return 0.0
	var o := Decor.Obstacle.new()
	o.kind = gname
	o.seed_v = rng.randi()
	match gname:
		"slide_rocks":
			o.size = Vector2(rng.randf_range(84.0, 110.0), rng.randf_range(40.0, 54.0))
		"fuel_drums":
			o.size = Vector2(rng.randf_range(50.0, 58.0), rng.randf_range(32.0, 36.0))
		_:
			o.size = Vector2(rng.randf_range(64.0, 78.0), rng.randf_range(28.0, 34.0))
	o.position = Vector2(x, floor_y)
	main.add_child(o)
	reserve(Rect2(x, floor_y - o.size.y, o.size.x, o.size.y))
	return o.size.x


func boss_kind() -> int:
	return Registry.TRUCKER


func music() -> String:
	return "res://music/level1_zombie_joyride.ogg"


func world_tint() -> Color:
	return Color(0.96, 0.95, 0.94)


func fog() -> bool:
	return false


func pits() -> int:
	return WASHOUTS


func build_background(layer: CanvasLayer) -> Node:
	var bg = Backdrop.new()
	bg.level_w = level_w
	bg.sky = func(ci: CanvasItem, v: Vector2, t: float):
		Decor.yungas_sky(ci, v, t)
	bg.add_layer(0.06, func(ci: CanvasItem, sc: float, v: Vector2, t: float):
		Decor.far_ranges(ci, sc, v, 520.0, t))
	bg.add_layer(0.28, func(ci: CanvasItem, sc: float, v: Vector2, t: float):
		Decor.mid_slope(ci, sc, v, 600.0, t))
	bg.add_layer(0.6, func(ci: CanvasItem, sc: float, v: Vector2, t: float):
		Decor.near_canopy(ci, sc, v, 640.0, t))
	layer.add_child(bg)
	return bg


func build_world() -> void:
	var pits_list: Array = main._pits.filter(func(p): return p.size() < 3)
	var x := 0.0
	for p in pits_list + [[level_w, 0.0]]:
		_ground(x, float(p[0]))
		if float(p[1]) > 0.0:
			var wo := Decor.Washout.new()
			wo.w = float(p[1])
			wo.depth = main.PIT_DEPTH
			wo._seed = rng.randi()
			add_world(wo, Vector2(float(p[0]), floor_y))
		x = float(p[0]) + float(p[1])
	for i in LEDGES.size():   # כביש עליון חצוב בצוק
		var w: float = LEDGES[i][1]
		var ox := level_w * float(LEDGES[i][0])
		while main._in_pit(ox - 30.0, ox + 60.0, 10.0) and ox < level_w - 600.0:   # הסולם לא בתוך בור
			ox += 40.0
		var cl := Decor.CliffLedge.new()
		cl.w = w
		cl.h = TIER
		cl.seed_v = rng.randi()
		cl.cross = i % 2 == 0
		add_world(cl, Vector2(ox, floor_y))
		var pf = add_floor(ox - 10.0, floor_y - TIER, w + 20.0, "wood", false, false)
		pf.visible = false   # (הציור של הקטע ב-CliffLedge)
		add_ladder(ox + 12.0, floor_y - TIER)
		reserve(Rect2(ox - 10.0, floor_y - TIER, 50.0, TIER))
		_ledges.append([ox, ox + w])
		_pickup(PickupScript.AMMO if LEDGES[i][0] < 0.5 else PickupScript.HEALTH, Vector2(ox + w * 0.55, floor_y - TIER - 30.0))
		if i in WATERFALLS:   # מפל מראש הצוק
			var wf := Decor.Waterfall.new()
			wf.height = TIER + Decor.CliffLedge.TOP_EXTRA - 20.0
			add_world(wf, Vector2(ox + w - 60.0, floor_y))
	for f in BUSES:   # אוטובוסים שהתרסקו (נוסעים בפנים)
		var bx := _free_spot(level_w * float(f), Decor.WreckBus.SIZE.x)
		var bus := Decor.WreckBus.new()
		bus.seed_v = rng.randi()
		bus.on_open = _open_bus
		add_world(bus, Vector2(bx, floor_y))
		reserve(Rect2(bx - 20.0, floor_y - Decor.WreckBus.SIZE.y, Decor.WreckBus.SIZE.x + 40.0, Decor.WreckBus.SIZE.y))
	for f in TRUCKS + [(level_w - 1050.0) / level_w]:   # משאית בוערת (אחת גם לפני זירת הבוס - להתרסק בה)
		var tx := _free_spot(level_w * float(f), Decor.WreckTruck.SIZE.x)
		add_world(Decor.WreckTruck.new(), Vector2(tx, floor_y))
		reserve(Rect2(tx - 20.0, floor_y - Decor.WreckTruck.SIZE.y, Decor.WreckTruck.SIZE.x + 40.0, Decor.WreckTruck.SIZE.y))
	for f in SHRINES:   # אנימיטות
		var sx := level_w * float(f)
		while main._in_pit(sx - 30.0, sx + 30.0, 10.0) and sx < level_w - 300.0:
			sx += 40.0
		var sh := Decor.Shrine.new()
		sh.seed_v = rng.randi()
		add_world(sh, Vector2(sx, floor_y))


func _free_spot(x0: float, w: float) -> float:
	var x := x0
	while x < level_w - 500.0:
		if free_x(x, 30.0) and free_x(x + w, 30.0) and free_x(x + w * 0.5, 30.0) and not main._in_pit(x - 40.0, x + w + 40.0, 30.0):
			return x
		x += 50.0
	return x0


func _ground(x0: float, x1: float) -> void:
	var x := x0
	while x < x1:
		var g := Decor.RoadGround.new()
		g.w = minf(1024.0, x1 - x)
		g.depth = main.floor_thickness
		g.seed_v = rng.randi()
		add_world(g, Vector2(x, floor_y))
		x += 1024.0


func _pickup(kind: int, pos: Vector2) -> void:
	var p = PickupScript.new()
	p.kind = kind
	p.life = 100000.0
	main.add_child(p)
	p.setup(pos, Vector2.ZERO)


# נוסעים זומבים יוצאים מהאוטובוס - בצד שבו נמצא השחקן
func _open_bus(bus: Node) -> void:
	var pl := main.get_tree().get_first_node_in_group("player")
	var right: bool = pl != null and pl.global_position.x > bus.global_position.x + Decor.WreckBus.SIZE.x * 0.5
	for i in PASSENGERS:
		var sx: float = bus.global_position.x + (Decor.WreckBus.SIZE.x + 16.0 + float(i) * 30.0 if right else -16.0 - float(i) * 30.0)
		var k: int = [0, 1, 0][i % 3]
		var zz: Node = spawn(k, sx)
		if zz != null:
			zz._alert_t = 8.0
			zz.velocity = Vector2((1.0 if right else -1.0) * 120.0, -200.0)
	Particles.burst(main, bus.global_position + Vector2(Decor.WreckBus.SIZE.x * 0.5, -40.0), "spark", Vector2.UP, 14)
	var cam := main.get_viewport().get_camera_2d()
	if cam != null and cam.has_method("shake"):
		cam.shake(6.0, 0.3)


func _clinger(x: float, y: float) -> void:
	var zz: Node = spawn(Registry.CLINGER, x, y)
	if zz != null and zz.type_mod != null:
		zz.type_mod.attach()


func build_effects() -> void:
	var fx := Decor.RoadFX.new()
	fx.vp = vp
	screen_layer.add_child(fx)


# CLINGER על כל בור ומתחת לכל כביש עליון, BOULDER על הכבישים העליונים
func extra_spawns() -> void:
	for p in main._pits:
		if p.size() >= 3:
			continue
		var left := rng.randf() < 0.5
		_clinger(float(p[0]) - 10.0 if left else float(p[0]) + float(p[1]) + 10.0, floor_y)
	for i in _ledges.size():
		var s: Array = _ledges[i]
		_clinger(lerpf(float(s[0]), float(s[1]), 0.3 if i % 2 == 0 else 0.72), floor_y - TIER)
		if i % 2 == 1:
			spawn(Registry.BOULDER, lerpf(float(s[0]), float(s[1]), 0.5), floor_y - TIER)
