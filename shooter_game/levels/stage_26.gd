extends "res://levels/stage_base.gd"
# ============================================================
#  STAGE 26 - "THE BUNKER" (אזור שלישי, שלב 8) - "THEY LEARNED TO GIVE ORDERS"
#  ההמשך של שלב 25: האות של התורנים הגיע מכאן - בונקר הפיקוד מתחת לרמה (effects/s26_decor.gd).
#  בטון, תקרה עם תעלות אוורור, פלורסנטים מהבהבים, נורות חירום, דלתות כספת. חשוך קצת (BunkerDark).
#  קטעים (SECTION_W): בכל קטע לוח חשמל (FuseBox). BLACKOUT מנתק -> הקטע חשוך. נגיעה בלוח מחזירה.
#  קומה שנייה: מסלולי פלדה (CATWALKS).
#  מלכודת: LaserGate - מסכי לייזר מהתקרה לרצפה שנדלקים ונכבים (LASERS). לעבור כשהם כבויים.
#  זומבים: HAZMAT (גז, מיכל בגב), BLACKOUT (מכבה את האור), VENT (בתעלות התקרה, נופל מאחוריך), רגילים, רצים, LEAPER.
#  בוס: THE GENERAL (enemies/types/general.gd) - שורק לזומבים להסתער, יורה צרורות. בחיים נמוכים בורח במנהרה לשער -> שלב 27.
#  לשנות: SECTION_W, CATWALKS, TIER, LASERS, zombie_weights().
# ============================================================

const Decor := preload("res://effects/s26_decor.gd")
const PickupScript := preload("res://pickup.gd")

const SOUNDS := {
	"s26_powerdown": [["S", 220, 40, 0.0, 0.9, 0.0, 2.0, 0.5, 0.6, 0], ["Q", 120, 30, 0.0, 0.7, 0.0, 3.0, 0.15, 0.4, 0], ["C", 0, 0, 0.0, 0.15, 0.0, 20.0, 0.6, 1.0, 0]],
	"s26_powerup": [["S", 60, 240, 0.0, 0.6, 0.05, 2.0, 0.4, 0.6, 0], ["Q", 120, 120, 0.4, 0.3, 0.0, 6.0, 0.08, 0.5, 0]],
	"s26_laser": [["S", 1400, 2200, 0.0, 0.15, 0.0, 12.0, 0.15, 1.0, 0], ["Q", 90, 90, 0.0, 0.2, 0.0, 8.0, 0.06, 0.5, 0]],
}

const SECTION_W := 1280.0
const CATWALKS := [[0.17, 400.0], [0.41, 420.0], [0.64, 380.0], [0.85, 400.0]]   # [מיקום יחסי, רוחב]
const TIER := 150.0
const LASERS := [0.11, 0.25, 0.36, 0.5, 0.6, 0.74, 0.92]
const HARDER := [1.0, 1.15, 1.3]

var _spans := []
var _boxes := []


func zombie_weights() -> Dictionary:
	return {Registry.HAZMAT: 0.1, Registry.BLACKOUT: 0.07, Registry.VENT: 0.09, Registry.LEAPER: 0.06, 0: 0.38, 1: 0.3}


func zombie_density() -> float:
	return 1.0 * float(HARDER[clampi(Settings.difficulty, 0, 2)])


func generators() -> Array:
	return [["crates", 1.5], ["drums", 1.0], ["locker", 0.8]]


func custom_gen(gname: String, x: float) -> float:
	if not gname in ["crates", "drums", "locker"]:
		return 0.0
	var o := Decor.Obstacle.new()
	o.kind = gname
	o.seed_v = rng.randi()
	match gname:
		"crates":
			o.size = Vector2(rng.randf_range(70.0, 90.0), rng.randf_range(54.0, 64.0))
		"drums":
			o.size = Vector2(rng.randf_range(44.0, 54.0), rng.randf_range(36.0, 42.0))
		_:
			o.size = Vector2(rng.randf_range(52.0, 78.0), rng.randf_range(70.0, 82.0))
	o.position = Vector2(x, floor_y)
	main.add_child(o)
	reserve(Rect2(x, floor_y - o.size.y, o.size.x, o.size.y))
	return o.size.x


func boss_kind() -> int:
	return Registry.GENERAL


func music() -> String:
	return "res://music/level2_suspense.mp3"


func world_tint() -> Color:
	return Color(0.9, 0.95, 0.9)


func dark_level() -> bool:
	return true


func fog() -> bool:
	return false


func pits() -> int:
	return 0


func build_background(layer: CanvasLayer) -> Node:
	var bg = Backdrop.new()
	bg.level_w = level_w
	bg.sky = func(ci: CanvasItem, v: Vector2, t: float):
		Decor.bunker_wall(ci, v, t)
	bg.add_layer(0.12, func(ci: CanvasItem, sc: float, v: Vector2, t: float):
		Decor.far_hall(ci, sc, v, 600.0, t))
	bg.add_layer(0.35, func(ci: CanvasItem, sc: float, v: Vector2, t: float):
		Decor.mid_pillars(ci, sc, v, 618.0, t))
	bg.add_layer(0.62, func(ci: CanvasItem, sc: float, v: Vector2, t: float):
		Decor.near_rail(ci, sc, v, 630.0, t))
	layer.add_child(bg)
	return bg


func build_world() -> void:
	var x := 0.0
	while x < level_w:
		var g := Decor.BunkerGround.new()
		g.w = minf(1024.0, level_w - x)
		g.depth = main.floor_thickness
		g.seed_v = rng.randi()
		add_world(g, Vector2(x, floor_y))
		var c := Decor.Ceiling.new()
		c.w = g.w
		c.seed_v = rng.randi()
		add_world(c, Vector2(x, floor_y))
		x += 1024.0
	var sx := 0.0   # קטעים + לוחות חשמל
	while sx < level_w - 200.0:
		var fb := Decor.FuseBox.new()
		fb.x0 = sx
		fb.x1 = minf(sx + SECTION_W, level_w)
		var bx := sx + 260.0
		while not free_x(bx, 20.0) and bx < fb.x1 - 100.0:
			bx += 40.0
		add_world(fb, Vector2(bx, floor_y))
		reserve(Rect2(bx - 30.0, floor_y - 110.0, 60.0, 110.0))
		_boxes.append(fb)
		sx += SECTION_W
	for cw in CATWALKS:
		var ox := level_w * float(cw[0])
		var w: float = cw[1]
		add_floor(ox, floor_y - TIER, w, "steel", true, true)
		add_ladder(ox + 12.0, floor_y - TIER)
		reserve(Rect2(ox - 20.0, floor_y - TIER, w + 40.0, TIER))
		_spans.append([ox, ox + w])
		_pickup(PickupScript.AMMO if cw[0] < 0.5 else PickupScript.HEALTH, Vector2(ox + w * 0.6, floor_y - TIER - 30.0))
	for f in LASERS:   # מסכי לייזר
		var lx := level_w * float(f)
		while not free_x(lx, 40.0) and lx < level_w - 300.0:
			lx += 50.0
		var lg := Decor.LaserGate.new()
		lg.h = -Decor.CEIL_Y - 10.0
		lg.phase_off = rng.randf_range(0.0, 3.0)
		add_world(lg, Vector2(lx, floor_y))
		reserve(Rect2(lx - 50.0, floor_y - 60.0, 100.0, 60.0))
	var et := Decor.ExitTunnel.new()   # המנהרה לשער (שלב 27)
	add_world(et, Vector2(level_w - 330.0, floor_y))


func _pickup(kind: int, pos: Vector2) -> void:
	var p = PickupScript.new()
	p.kind = kind
	p.life = 100000.0
	main.add_child(p)
	p.setup(pos, Vector2.ZERO)


func build_effects() -> void:
	main.add_child(Decor.BunkerDark.new())


# BLACKOUT ליד חלק מהלוחות, VENT בתעלות, HAZMAT על המסלולים
func extra_spawns() -> void:
	for i in _boxes.size():
		if i % 2 == 1 and i < _boxes.size() - 1:
			var fb: Node = _boxes[i]
			var bx: float = fb.global_position.x + 360.0
			if free_x(bx, 30.0):
				spawn(Registry.BLACKOUT, bx)
	for f in [0.2, 0.46, 0.7]:
		spawn(Registry.VENT, level_w * float(f))
	for i in _spans.size():
		var s: Array = _spans[i]
		if i % 2 == 1:
			spawn(Registry.HAZMAT, lerpf(float(s[0]), float(s[1]), 0.6), floor_y - TIER)
