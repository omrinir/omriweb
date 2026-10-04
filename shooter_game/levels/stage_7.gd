extends "res://levels/stage_base.gd"
# ============================================================
#  STAGE 7 - "THEY WATCH"
#  מפעל תעשייתי חשוך. שתי קומות: ריצפת המפעל + גשרי מתכת (steel) ~160 פיקסלים למעלה,
#  ושני "גשרי עגורן" גבוהים (~300) שמגיעים אליהם במעלית נעה (או בסולם / בקפיצה של LEAPER).
#  נושא ה-AI: איגוף ושימוש בסביבה - TACTICIAN שולח זומבים לעקוף אותך כשאתה "מתבצר",
#  ו-ENGINEER רץ ללוחות בקרה ומפעיל נגדך מכבשים, קיטור, חשמל, דלתות ותריסים.
#
#  חלקי השלב (משמאל לימין, x לפי level_w = 10240):
#    A ~1200-2500  פס ייצור: מסוע ריצפה + מכבש, גשר, צינור קיטור, לוח בקרה K1, כיס חושך
#    B ~2700-4100  דלת פלדה DR1 מתחת לגשר, לוח K2, מעלית L1 אל גשר עגורן H1 (TACTICIAN), כבל חשמל
#    C ~4300-5700  חדר דוודים: תעלה עם כבל חשמל, שני גשרים עם רווח, קיטור מלמעלה, חדר תחזוקה
#                  נעול (תריס G1 + זומבים בפנים) שנפתח מלוח K3 / ביריות במנעול
#    D ~6000-7700  קו מכבשים: מסוע שנוסע שמאלה + 2 מכבשים, דלת DR2, לוח K4 על הגשר
#    E ~7800-9300  חדר בקרה: תעלה, גשר, מעלית L2 אל גשר עגורן H2, מכבש, קיטור, לוח K5
#    סוף: הבוס CONDUCTOR (7) - צריך לאגף אותו ולירות בשנאי בגב (מתאים לנושא האיגוף)
#  זומבים: AMBUSHER, TACTICIAN, SHIELDED, LEAPER, ENGINEER (+ רגיל / רץ / ענק)
#  נשקים: SNIPER (+ רימונים נוספים לאורך השלב)
#  אפקטים: ניצוצות, קיטור, אורות אזהרה פועמים, נורות פלורסנט מהבהבות, עגורנים נעים,
#          מאווררים, מצלמות אבטחה שעוקבות אחרי השחקן, אבק וגצים באוויר
#  איך משנים: מיקומים בקבועים CONVEYORS / TRENCHES ובפונקציות _section_*; משקלי זומבים ב-zombie_weights.
# ============================================================

const WeaponDB := preload("res://weapons/weapon_db.gd")
const PickupScript := preload("res://pickup.gd")
const PropScript := preload("res://prop.gd")
const PressScript := preload("res://environment/s7_press.gd")
const SteamScript := preload("res://environment/s7_steam_pipe.gd")
const WireScript := preload("res://environment/s7_live_wire.gd")
const DoorScript := preload("res://environment/s7_door.gd")
const GateScript := preload("res://environment/s7_gate.gd")
const ConveyorScript := preload("res://environment/s7_conveyor.gd")
const LiftScript := preload("res://environment/s7_lift.gd")
const ConsoleScript := preload("res://environment/s7_console.gd")
const Decor := preload("res://effects/s7_decor.gd")
const BG := preload("res://effects/s7_backdrop.gd")

# צלילי הסביבה של השלב (נרשמים אוטומטית ב-sfx.gd)
const SOUNDS := {
	"s7_press_hiss": [["N", 0, 0, 0.0, 0.8, 0.05, 1.5, 0.45, 0.9, 0, 0.4], ["S", 300, 900, 0.0, 0.8, 0.1, 1.0, 0.08, 1.0, 0]],
	"s7_press_slam": {"rev": 0.3, "drive": 2.6, "layers": [["N", 0, 0, 0.0, 0.01, 0.0, 300.0, 1.5, 1.0, 0], ["S", 70, 30, 0.0, 0.4, 0.0, 9.0, 1.4, 1.0, 0], ["N", 0, 0, 0.0, 0.3, 0.0, 14.0, 0.9, 0.15, 0], ["S", 420, 400, 0.0, 0.5, 0.0, 8.0, 0.25, 1.0, 0], ["S", 1130, 1120, 0.0, 0.35, 0.0, 10.0, 0.15, 1.0, 0]]},
	"s7_valve": [["C", 0, 0, 0.0, 0.6, 0.0, 2.0, 0.8, 1.0, 0], ["N", 0, 0, 0.0, 0.6, 0.3, 1.0, 0.3, 0.8, 0, 0.5], ["S", 1500, 3200, 0.0, 0.6, 0.2, 1.0, 0.08, 1.0, 0]],
	"s7_steam": {"drive": 1.5, "layers": [["N", 0, 0, 0.0, 1.4, 0.03, 1.4, 1.0, 0.9, 0, 0.25], ["N", 0, 0, 0.0, 1.4, 0.05, 1.8, 0.5, 0.3, 0]]},
	"s7_buzz": [["Q", 60, 60, 0.0, 0.75, 0.05, 1.5, 0.35, 0.5, 0], ["Q", 120, 120, 0.0, 0.75, 0.05, 1.5, 0.2, 0.7, 0], ["C", 0, 0, 0.0, 0.75, 0.2, 1.0, 0.6, 1.0, 0]],
	"s7_klaxon": [["W", 440, 440, 0.0, 0.35, 0.01, 1.5, 0.35, 0.4, 0], ["W", 330, 330, 0.4, 0.35, 0.01, 1.5, 0.35, 0.4, 0]],
	"s7_door": {"rev": 0.3, "layers": [["S", 60, 35, 0.0, 0.5, 0.0, 7.0, 1.3, 1.0, 0], ["N", 0, 0, 0.0, 0.25, 0.0, 16.0, 0.9, 0.2, 0], ["S", 380, 370, 0.0, 0.6, 0.0, 6.0, 0.2, 1.0, 0]]},
	"s7_lift": [["W", 90, 110, 0.0, 0.9, 0.1, 1.5, 0.25, 0.15, 0.01], ["N", 0, 0, 0.0, 0.9, 0.1, 2.0, 0.1, 0.3, 0]],
	"s7_gate": [["C", 0, 0, 0.0, 0.8, 0.0, 1.5, 1.0, 1.0, 0], ["S", 200, 500, 0.0, 0.8, 0.05, 1.5, 0.2, 1.0, 0], ["N", 0, 0, 0.0, 0.8, 0.05, 2.0, 0.3, 0.4, 0]],
	"s7_alarm": [["Q", 880, 880, 0.0, 0.12, 0.0, 10.0, 0.25, 0.6, 0], ["Q", 880, 880, 0.2, 0.12, 0.0, 10.0, 0.25, 0.6, 0], ["Q", 1175, 1175, 0.4, 0.2, 0.0, 8.0, 0.28, 0.6, 0]],
	"s7_lever": [["N", 0, 0, 0.0, 0.04, 0.0, 100.0, 0.8, 1.0, 0], ["S", 200, 90, 0.0, 0.2, 0.0, 18.0, 0.9, 1.0, 0], ["S", 1400, 1300, 0.0, 0.1, 0.0, 40.0, 0.2, 1.0, 0]],
}

# מסועים בריצפה: [x, רוחב, מהירות]  (x לפי שלב באורך 10240)
const CONVEYORS := [[1250.0, 360.0, 70.0], [6100.0, 420.0, -80.0]]
# תעלות תחזוקה (רווחים בריצפה): [x, רוחב]
const TRENCHES := [[4400.0, 84.0], [7850.0, 90.0]]
const PIT_DEPTH := 60.0

var _darks := []      # כיסי חושך (ל-AMBUSHER)
var _consoles := []


func _x(px: float) -> float:
	return px * level_w / 10240.0


func zombie_weights() -> Dictionary:
	return {0: 0.16, 1: 0.14, 2: 0.04, Registry.AMBUSHER: 0.12, Registry.TACTICIAN: 0.06, Registry.SHIELDED: 0.16, Registry.LEAPER: 0.16, Registry.ENGINEER: 0.02}


func zombie_density() -> float:
	return 0.8


# מכשולים על הריצפה - כולם עוברים דרך custom_gen כדי לא לחסום מכונות / דלתות / מעליות
func generators() -> Array:
	return [["s7_container", 2.0], ["s7_crates", 1.5], ["s7_barrels", 1.2], ["machine", 2.0], ["generator", 1.5]]


func custom_gen(gname: String, x: float) -> float:
	var widths := {"s7_container": 170.0, "s7_crates": 100.0, "s7_barrels": 70.0, "machine": 110.0, "generator": 130.0}
	if not widths.has(gname):
		return 0.0
	var w: float = widths[gname]
	if not _free_span(x - 40.0, x + w + 40.0):
		return 30.0   # המקום תפוס (מכונה / דלת / מסוע) - מדלגים
	match gname:
		"s7_container":
			return main._gen_prop_simple(rng, x, floor_y, PropScript.CONTAINER)
		"s7_crates":
			return main._gen_crates(rng, x, floor_y)
		"s7_barrels":
			return main._gen_barrels(rng, x, floor_y)
		_:
			var m = Decor.Machine.new()
			m.kind = 1 if gname == "generator" else 0
			m.size = Vector2(w, 64.0 if gname == "generator" else rng.randf_range(44.0, 60.0))
			m.position = Vector2(x, floor_y)
			main.add_child(m)
			reserve(Rect2(x, floor_y - m.size.y, w, m.size.y))
			return w


func _free_span(x0: float, x1: float) -> bool:
	for r in main._rects:
		if r.end.y >= floor_y - 4.0 and x1 > r.position.x and x0 < r.end.x:
			return false
	return true


func weapon_offers() -> Array:
	return [WeaponDB.SNIPER]


# CONDUCTOR: שריון מלפנים, שנאי פגיע בגב - צריך לאגף אותו
func boss_kind() -> int:
	return 7


func music() -> String:
	return "res://music/level2_suspense.mp3"


func world_tint() -> Color:
	return Color(0.82, 0.78, 0.72)


func pits() -> int:
	return 0   # הרווחים בריצפה הם התעלות שלנו (TRENCHES)


func road_holes() -> Array:
	var out := []
	for c in CONVEYORS:
		out.append([_x(c[0]), c[1]])
	for tr in TRENCHES:
		out.append([_x(tr[0]), tr[1]])
	return out


# ---- רקע: 3 שכבות פרלקסה (effects/s7_backdrop.gd) ----
func build_background(layer: CanvasLayer) -> Node:
	var bg = Backdrop.new()
	bg.level_w = level_w
	bg.sky = func(ci: CanvasItem, v: Vector2, t: float): BG.sky(ci, v, t)
	bg.add_layer(0.10, func(ci: CanvasItem, sc: float, v: Vector2, t: float): BG.far(ci, sc, v, t))
	bg.add_layer(0.30, func(ci: CanvasItem, sc: float, v: Vector2, t: float): BG.mid(ci, sc, v, t))
	bg.add_layer(0.60, func(ci: CanvasItem, sc: float, v: Vector2, t: float): BG.near(ci, sc, v, t))
	layer.add_child(bg)
	return bg


# ============================================================
#  העולם
# ============================================================
func build_world() -> void:
	# קיר המפעל לאורך כל השלב
	var x := 0.0
	while x < level_w:
		var wc := Decor.WallChunk.new()
		wc.position = Vector2(x, floor_y)
		wc.seed_v = rng.randi()
		main.add_child(wc)
		x += 1024.0
	# מסועים בתוך החורים בריצפה
	var convs := []
	for c in CONVEYORS:
		var cv = ConveyorScript.new()
		cv.size = Vector2(c[1], 90.0)
		cv.speed = c[2]
		cv.position = Vector2(_x(c[0]), floor_y)
		main.add_child(cv)
		convs.append(cv)
	# תעלות: תחתית + שוליים + אדים
	for tr in TRENCHES:
		var tx := _x(tr[0])
		var tw: float = tr[1]
		main._make_brick(Vector2(tx, floor_y + PIT_DEPTH), Vector2(tw, 90.0 - PIT_DEPTH), 3, Color("2a2a2e"), false)
		var te := Decor.TrenchEdge.new()
		te.width = tw
		add_world(te, Vector2(tx, floor_y))
	_section_a()
	_section_b()
	_section_c()
	_section_d()
	_section_e()
	_decor()


# A: פס ייצור
func _section_a() -> void:
	var cx := _x(1250.0) + 180.0
	var p1 := _press(cx, floor_y, true, false)
	add_floor(_x(1700.0), floor_y - FLOOR2, 550.0, "steel", true, true)
	add_ladder(_x(1720.0), floor_y - FLOOR2)
	var s1 := _steam(_x(1900.0), floor_y - 34.0, Vector2.LEFT, true)
	_console(_x(2050.0), floor_y, [p1, s1])
	_dark(_x(2420.0), floor_y, Vector2(140, 150))
	_grenade(_x(2600.0), floor_y - 30.0)


# B: דלת + מעלית + גשר עגורן
func _section_b() -> void:
	add_floor(_x(2750.0), floor_y - FLOOR2, 550.0, "steel", true, true)
	add_ladder(_x(2770.0), floor_y - FLOOR2)
	var dr1 := _door(_x(3150.0))
	add_floor(_x(3380.0), floor_y - FLOOR2, 170.0, "steel", true, false)
	var lx := _x(3550.0)
	_lift(lx)
	add_floor(lx + 110.0, floor_y - 300.0, 390.0, "steel", true, true)
	add_ladder(lx + 470.0, floor_y - 300.0)
	var w1 := _wire(lx + 300.0, floor_y, 290.0, true)
	_console(_x(3420.0), floor_y, [dr1, w1])
	_grenade(lx + 250.0, floor_y - 330.0)


# C: חדר הדוודים + חדר תחזוקה נעול
func _section_c() -> void:
	var t1 := _x(4400.0)
	var w2 := _wire(t1 + 42.0, floor_y + PIT_DEPTH, 250.0, true)
	w2.width = 70.0
	w2.rect = Rect2(-35.0, -26.0, 70.0, 28.0)
	add_floor(_x(4600.0), floor_y - FLOOR2, 400.0, "steel", true, true)
	add_ladder(_x(4620.0), floor_y - FLOOR2)
	var c5x := _x(5110.0)
	add_floor(c5x, floor_y - FLOOR2, 340.0, "steel", true, true)
	var s2 := _steam(_x(4850.0), floor_y - FLOOR2 + 12.0, Vector2.DOWN, false)
	s2.length = FLOOR2 - 12.0
	var s3 := _steam(_x(5250.0), floor_y - 34.0, Vector2.RIGHT, true)
	_dark(_x(4720.0), floor_y, Vector2(120, 120))
	# חדר תחזוקה נעול: ריצפה מוצקה + קיר אחורי + תריס
	var px := c5x + 340.0
	add_block(px, floor_y - FLOOR2, 220.0, 16.0, Color("34373c"), false, 2)
	add_block(px + 204.0, floor_y - FLOOR2 - 140.0, 16.0, 140.0, Color("34373c"), false, 2)
	var room := MaintRoom.new()
	room.size = Vector2(220.0, 140.0)
	add_world(room, Vector2(px, floor_y - FLOOR2))
	var g1 = GateScript.new()
	add_hazard(g1, Vector2(px + 8.0, floor_y - FLOOR2))
	_console(_x(5050.0), floor_y, [s2, s3, w2, g1])
	_grenade(px + 120.0, floor_y - FLOOR2 - 30.0)


# D: קו מכבשים + דלת + לוח על הגשר
func _section_d() -> void:
	var cvx := _x(6100.0)
	var p2 := _press(cvx + 100.0, floor_y, true, false)
	var p3 := _press(cvx + 320.0, floor_y, true, false)
	add_floor(_x(6560.0), floor_y - FLOOR2, 690.0, "steel", true, true)
	add_ladder(_x(6580.0), floor_y - FLOOR2)
	var dr2 := _door(_x(6950.0))
	_console(_x(7150.0), floor_y - FLOOR2, [dr2, p2, p3])
	var w3 := _wire(_x(7450.0), floor_y, 280.0, false)
	w3.auto = false
	_dark(_x(7640.0), floor_y, Vector2(140, 150))
	_grenade(_x(7760.0), floor_y - 30.0)


# E: חדר בקרה לפני הבוס
func _section_e() -> void:
	add_floor(_x(8000.0), floor_y - FLOOR2, 550.0, "steel", true, true)
	add_ladder(_x(8020.0), floor_y - FLOOR2)
	var lx := _x(8600.0)
	_lift(lx)
	add_floor(lx + 110.0, floor_y - 300.0, 390.0, "steel", true, true)
	add_ladder(lx + 480.0, floor_y - 300.0)
	var s4 := _steam(_x(8950.0), floor_y - 34.0, Vector2.LEFT, false)
	var p4 := _press(_x(9260.0), floor_y, false, true)
	_console(_x(9130.0), floor_y, [p4, s4])
	_grenade(lx + 300.0, floor_y - 330.0)


# ---- בוני מכונות ----
func _press(x: float, y: float, auto: bool, anvil: bool) -> Node:
	var p = PressScript.new()
	p.auto = auto
	p.anvil = anvil
	add_hazard(p, Vector2(x, y))
	if y >= floor_y - 1.0:
		reserve(Rect2(x - 60.0, y - 60.0, 120.0, 60.0))
	var wl = Ambient.FlickerLight.new()
	wl.mode = "pulse"
	wl.color = Color(1.0, 0.55, 0.15)
	wl.radius = 40.0
	wl.tube = false
	add_world(wl, Vector2(x + 60.0, y - 210.0))
	return p


func _steam(x: float, y: float, dir: Vector2, auto: bool) -> Node:
	var s = SteamScript.new()
	s.dir = dir
	s.auto = auto
	s.height = floor_y - y if dir != Vector2.DOWN else 0.0
	add_hazard(s, Vector2(x, y))
	if dir != Vector2.DOWN:
		reserve(Rect2(x - 40.0 + (0.0 if dir.x > 0.0 else -100.0), floor_y - 60.0, 180.0, 60.0))
	return s


func _wire(x: float, y: float, drop: float, auto: bool) -> Node:
	var w = WireScript.new()
	w.drop = drop
	w.auto = auto
	add_hazard(w, Vector2(x, y))
	if y <= floor_y + 1.0:
		reserve(Rect2(x - 60.0, floor_y - 40.0, 120.0, 40.0))
	return w


func _door(x: float) -> Node:
	var d = DoorScript.new()
	d.height = FLOOR2 - 10.0
	add_hazard(d, Vector2(x, floor_y))
	reserve(Rect2(x - 70.0, floor_y - 150.0, 140.0, 150.0))
	var wl = Ambient.FlickerLight.new()
	wl.mode = "pulse"
	wl.color = Color(1.0, 0.2, 0.12)
	wl.radius = 45.0
	wl.tube = false
	add_world(wl, Vector2(x - 40.0, floor_y - FLOOR2 - 50.0))
	return d


func _lift(x: float) -> void:
	var sh = LiftScript.Shaft.new()
	sh.low_y = floor_y
	sh.high_y = floor_y - 300.0
	add_world(sh, Vector2(x, floor_y))
	var l = LiftScript.new()
	l.low_y = floor_y
	l.high_y = floor_y - 300.0
	l.position = Vector2(x, floor_y)
	main.add_child(l)
	reserve(Rect2(x - 40.0, floor_y - 300.0, 190.0, 300.0))


func _console(x: float, y: float, links: Array) -> Node:
	var c = ConsoleScript.new()
	c.links = links
	add_world(c, Vector2(x, y))
	if y >= floor_y - 1.0:
		reserve(Rect2(x - 40.0, floor_y - 60.0, 80.0, 60.0))
	_consoles.append(c)
	return c


func _dark(x: float, y: float, size: Vector2) -> void:
	var d = Decor.DarkPocket.new()
	d.size = size
	add_world(d, Vector2(x, y))
	reserve(Rect2(x - size.x * 0.5, y - size.y, size.x, size.y))
	_darks.append(Vector2(x, y))


func _grenade(x: float, y: float) -> void:
	var p = PickupScript.new()
	p.kind = PickupScript.GRENADE
	p.life = 100000.0
	main.add_child(p)
	p.setup(Vector2(x, y), Vector2.ZERO)


# ---- קישוטים מונפשים בעולם ----
func _decor() -> void:
	# עגורנים (מעל אזורים בלי גשרים)
	for cx in [600.0, 5700.0, 9350.0]:
		var cr = Decor.Crane.new()
		cr.span = 800.0
		cr.drop = 70.0
		add_world(cr, Vector2(_x(cx), floor_y - 340.0))
	var x := 900.0
	while x < level_w - 300.0:   # מצלמות אבטחה
		add_world(Decor.Cctv.new(), Vector2(x + rng.randf_range(-100.0, 100.0), floor_y - 214.0))
		x += rng.randf_range(900.0, 1300.0)
	x = 1500.0
	while x < level_w - 300.0:   # מאווררים בקיר
		add_world(Decor.WallFan.new(), Vector2(x + rng.randf_range(-80.0, 80.0), floor_y - 120.0))
		x += rng.randf_range(1100.0, 1600.0)
	x = 400.0
	while x < level_w - 200.0:   # שרשראות בחזית
		var fc = Decor.FgChains.new()
		fc.top_y = -(floor_y - 90.0)
		fc.length = rng.randf_range(250.0, 320.0)
		add_world(fc, Vector2(x + rng.randf_range(-120.0, 120.0), floor_y))
		x += rng.randf_range(850.0, 1300.0)


func build_effects() -> void:
	screen_layer.add_child(Ambient.screen_particles("dust", vp))
	var em := Ambient.screen_particles("embers", vp)
	em.amount = 18
	screen_layer.add_child(em)
	# נורות פלורסנט מהבהבות תלויות מהתקרה
	var x := 300.0
	while x < level_w - 200.0:
		var fl = Ambient.FlickerLight.new()
		fl.color = Color(0.78, 0.95, 0.85)
		fl.radius = 110.0
		fl.mode = "flicker" if rng.randf() < 0.45 else "steady"
		add_world(fl, Vector2(x, floor_y - 262.0))
		x += rng.randf_range(380.0, 640.0)
	# ניצוצות מתחת לגשרים ומכבלים בקיר
	x = 900.0
	while x < level_w - 400.0:
		var sp = Ambient.SparkEmitter.new()
		sp.period = rng.randf_range(1.8, 3.5)
		add_world(sp, Vector2(x, floor_y - rng.randf_range(150.0, 200.0)))
		x += rng.randf_range(450.0, 800.0)
	# אדים מסורגי ריצפה ומהתעלות
	x = 1000.0
	while x < level_w - 600.0:
		if _free_span(x - 20.0, x + 20.0):
			var sv = Ambient.SteamVent.new()
			sv.period = rng.randf_range(3.0, 6.0)
			add_world(sv, Vector2(x, floor_y))
		x += rng.randf_range(700.0, 1100.0)
	for tr in TRENCHES:
		var sv2 = Ambient.SteamVent.new()
		add_world(sv2, Vector2(_x(tr[0]) + float(tr[1]) * 0.7, floor_y + PIT_DEPTH))
	# אורות אזהרה פועמים לאורך הקיר
	x = 1100.0
	while x < level_w - 300.0:
		var wl = Ambient.FlickerLight.new()
		wl.mode = "pulse"
		wl.color = Color(1.0, 0.45, 0.1) if rng.randf() < 0.6 else Color(1.0, 0.15, 0.1)
		wl.radius = 34.0
		wl.tube = false
		add_world(wl, Vector2(x, floor_y - 160.0 - rng.randf_range(40.0, 80.0)))
		x += rng.randf_range(700.0, 1200.0)


# ============================================================
#  זומבים מיוחדים במקומות מיוחדים
# ============================================================
func extra_spawns() -> void:
	var f2 := floor_y - FLOOR2
	var hi := floor_y - 300.0
	# AMBUSHERS בכיסי החושך
	for d in _darks:
		var dp: Vector2 = d
		_spawn_at(Registry.AMBUSHER, dp.x, dp.y)
	# ENGINEERS ליד לוחות הבקרה (אחד על הגשר)
	_spawn_at(Registry.ENGINEER, _x(2230.0), floor_y)
	_spawn_at(Registry.ENGINEER, _x(3480.0), floor_y)
	_spawn_at(Registry.ENGINEER, _x(5300.0), floor_y)
	_spawn_at(Registry.ENGINEER, _x(7210.0), f2)
	# TACTICIANS על גשרי העגורן (תצפית)
	_spawn_at(Registry.TACTICIAN, _x(3550.0) + 330.0, hi)
	_spawn_at(Registry.TACTICIAN, _x(8600.0) + 330.0, hi)
	# SHIELDED ליד הדלתות
	_spawn_at(Registry.SHIELDED, _x(3330.0), floor_y)
	_spawn_at(Registry.SHIELDED, _x(6760.0), floor_y)
	_spawn_at(Registry.SHIELDED, _x(9050.0), floor_y)
	# LEAPERS על הגשרים
	_spawn_at(Registry.LEAPER, _x(2150.0), f2)
	_spawn_at(Registry.LEAPER, _x(3550.0) + 200.0, hi)
	_spawn_at(Registry.LEAPER, _x(4950.0), f2)
	_spawn_at(Registry.LEAPER, _x(8450.0), f2)
	# הזומבים הנעולים בחדר התחזוקה (פורצים כשהתריס נפתח)
	var px := _x(5110.0) + 340.0
	_spawn_at(1, px + 110.0, f2)
	_spawn_at(0, px + 170.0, f2)


# בלי "שכיבה" (dormant) - כדי שהזומבים יהיו מוכנים במקום
func _spawn_at(kind: int, x: float, y: float) -> Node:
	var z: Node = main._spawn_zombie(x, floor_y, kind, null)
	if z != null:
		z.position.y = y
	return z


# ---- חדר התחזוקה (קישוט: קירות, נורה, שלט) ----
class MaintRoom extends Node2D:
	var size := Vector2(220, 140)

	func _ready() -> void:
		z_index = -1

	func _draw() -> void:
		draw_rect(Rect2(0, -size.y, size.x, size.y), Color("17171a"))
		var y := -size.y + 10.0
		while y < -6.0:
			draw_line(Vector2(4, y), Vector2(size.x - 4, y), Color("202024"), 1.0)
			y += 14.0
		draw_rect(Rect2(0, -size.y - 6.0, size.x, 8.0), Color("2a2c30"))
		draw_string(ThemeDB.fallback_font, Vector2(40, -size.y + 26.0), "MAINTENANCE  B7", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.8, 0.65, 0.2, 0.55))
		draw_circle(Vector2(size.x * 0.5, -size.y + 6.0), 3.0, Color(1.0, 0.3, 0.2, 0.8))
