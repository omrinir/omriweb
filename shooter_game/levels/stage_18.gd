extends "res://levels/stage_base.gd"
# ============================================================
#  STAGE 18 - "THE QUARRY" (אזור צפון-מזרח, שלב 9 - סוף האזור) - "THEY LEARNED TO DIG"
#  צהרי יום בהירים במחצבה פתוחה: קירות אבן במדרגות, מכונות כרייה ענקיות, משאיות מכרה,
#  ערמות אבני גיר, עגלות על מסילה, פיגומי מתכת (קומה שאפשר לקפוץ אליה). המסך מואר (SunGlare).
#  זומבים: DRILLER (במכונת קידוח: נקדח לאדמה ומגיח מתחתיך אחרי שנייה של אזהרה),
#          UZI (צרורות שמטפסים למעלה מההדף), BOMBHEAD חוזר (זורק את הראש), רגילים ורצים.
#  בוס: THE EXCAVATOR - DRILLER ענק (enemies/types/driller.gd, מצב בוס).
#  לשנות: SCAFFOLDS, SCAFF_H, zombie_weights().
# ============================================================

const Decor := preload("res://effects/s18_decor.gd")
const PickupScript := preload("res://pickup.gd")

const SCAFFOLDS := [[0.15, 300.0], [0.33, 360.0], [0.5, 280.0], [0.68, 380.0], [0.85, 300.0]]   # [מיקום יחסי, רוחב]
const SCAFF_H := 120.0
const HARDER := [1.0, 1.15, 1.3]

var _spans := []


func zombie_weights() -> Dictionary:
	return {Registry.DRILLER: 0.16, Registry.UZI: 0.2, Registry.BOMBHEAD: 0.18, 0: 0.22, 1: 0.18, Registry.CRUMBLER: 0.06}


func zombie_density() -> float:
	return 0.9 * float(HARDER[clampi(Settings.difficulty, 0, 2)])


func generators() -> Array:
	return [["blocks", 1.8], ["truck", 0.5], ["cart", 1.0], ["drill_rig", 0.5], ["barrels", 0.5]]


func custom_gen(gname: String, x: float) -> float:
	if not gname in ["blocks", "truck", "cart", "drill_rig"]:
		return 0.0
	if _in_scaffold(x - 20.0) or _in_scaffold(x + 280.0):
		return 140.0
	var o := Decor.Obstacle.new()
	o.kind = gname
	o.seed_v = rng.randi()
	match gname:
		"truck":   # גבוהה - מחסה, אפשר לקפוץ עליה
			o.size = Vector2(rng.randf_range(230.0, 270.0), rng.randf_range(96.0, 106.0))
		"cart":
			o.size = Vector2(rng.randf_range(70.0, 90.0), rng.randf_range(40.0, 48.0))
		"drill_rig":
			o.size = Vector2(rng.randf_range(60.0, 76.0), rng.randf_range(86.0, 100.0))
		_:
			o.size = Vector2(rng.randf_range(80.0, 140.0), [26.0, 52.0, 52.0, 78.0][rng.randi() % 4])
	o.position = Vector2(x, floor_y)
	main.add_child(o)
	reserve(Rect2(x, floor_y - o.size.y, o.size.x, o.size.y))
	return o.size.x


func boss_kind() -> int:
	return Registry.DRILLER


func music() -> String:
	return "res://music/level1_total_war.mp3"


func world_tint() -> Color:
	return Color.WHITE


func fog() -> bool:
	return false


func pits() -> int:
	return 0


func _in_scaffold(x: float) -> bool:
	for s in _spans:
		if x > float(s[0]) - 30.0 and x < float(s[1]) + 30.0:
			return true
	return false


# ---- רקע: שמיים כחולים, קירות מחצבה, מכונות, חצץ ----
func build_background(layer: CanvasLayer) -> Node:
	var bg = Backdrop.new()
	bg.level_w = level_w
	bg.sky = func(ci: CanvasItem, v: Vector2, t: float):
		Decor.quarry_sky(ci, v, t)
	bg.add_layer(0.08, func(ci: CanvasItem, sc: float, v: Vector2, t: float):
		Decor.terraces(ci, sc, v, 520.0, t))
	bg.add_layer(0.3, func(ci: CanvasItem, sc: float, v: Vector2, t: float):
		Decor.machines(ci, sc, v, 590.0, t))
	bg.add_layer(0.6, func(ci: CanvasItem, sc: float, v: Vector2, t: float):
		Decor.gravel(ci, sc, v, 625.0, t))
	layer.add_child(bg)
	return bg


# ---- העולם: רצפת חצץ, פיגומי מתכת עם סולמות ----
func build_world() -> void:
	var x := 0.0
	while x < level_w:
		var g := Decor.QuarryGround.new()
		g.w = minf(1024.0, level_w - x)
		g.depth = main.floor_thickness
		g.seed_v = rng.randi()
		add_world(g, Vector2(x, floor_y))
		x += 1024.0
	for sc in SCAFFOLDS:
		var ox := level_w * float(sc[0])
		var w: float = sc[1]
		add_floor(ox, floor_y - SCAFF_H, w, "scaffold", true, true)
		add_ladder(ox + 12.0, floor_y - SCAFF_H)
		reserve(Rect2(ox - 20.0, floor_y - SCAFF_H, w + 40.0, SCAFF_H))
		_spans.append([ox, ox + w])
		_pickup(PickupScript.AMMO if sc[0] < 0.6 else PickupScript.HEALTH, Vector2(ox + w * 0.6, floor_y - SCAFF_H - 30.0))


func _pickup(kind: int, pos: Vector2) -> void:
	var p = PickupScript.new()
	p.kind = kind
	p.life = 100000.0
	main.add_child(p)
	p.setup(pos, Vector2.ZERO)


func build_effects() -> void:
	var glare := Decor.SunGlare.new()
	glare.vp = vp
	screen_layer.add_child(glare)
	var dust := Ambient.screen_particles("dust", vp)
	dust.color = Color(1.0, 0.95, 0.82, 0.18)
	dust.direction = Vector2(-1, 0.02)
	dust.initial_velocity_min = 15.0
	dust.initial_velocity_max = 40.0
	screen_layer.add_child(dust)


# UZI על הפיגומים (יורים מלמעלה), DRILLER נוסף בין הפיגומים
func extra_spawns() -> void:
	for i in _spans.size():
		var s: Array = _spans[i]
		if i % 2 == 0:
			spawn(Registry.UZI, lerpf(float(s[0]), float(s[1]), 0.6), floor_y - SCAFF_H)
		elif i < _spans.size() - 1:
			spawn(Registry.DRILLER, float(s[1]) + 260.0)
