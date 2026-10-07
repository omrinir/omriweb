extends "res://levels/stage_base.gd"
# ============================================================
#  STAGE 17 - "THE DRY RIVER" (אזור צפון-מזרח, שלב 8) - "THEY LEARNED TO LIE"
#  צהרי היום. נהר שהתייבש (אחרי השיטפון של שלב 16 הסכר נשבר והמים נעלמו): קרקעית בוץ סדוקה,
#  סירות דייגים תקועות, סלעים וגזעי סחף, מזחי עץ ישנים שעומדים גבוה מעל הקרקעית (קומה שאפשר לקפוץ אליה).
#  החום: האוויר רועד (HeatHaze על המסך), ובתוך החום - MIRAGE: זומבי שהולך עם העתקים שלו.
#    רק לאמיתי יש צל ואבק -> מסתכלים למטה, לא על הפרצוף. (enemies/types/mirage.gd)
#  עוד: GRAVEBORN (עולים מהבוץ), זומבים רגילים ורצים, DODGER.
#  בוס: FATA MORGANA (enemies/types/mirage_king.gd) - מתחלף במקום עם ההעתקים שלו.
#  סצנת סיפור: story/scenes/l17_stranger.gd (החבר חוזר - ומלמד את כלל הצל).
#  לשנות: PIERS, PIER_H, zombie_weights().
# ============================================================

const Decor := preload("res://effects/s17_decor.gd")
const PickupScript := preload("res://pickup.gd")

const PIERS := [[0.17, 360.0], [0.34, 300.0], [0.52, 420.0], [0.7, 340.0], [0.84, 300.0]]   # [מיקום יחסי, רוחב]
const PIER_H := 115.0         # גובה המזח מעל הקרקעית (קפיצה רגילה)

var _spans := []


func zombie_weights() -> Dictionary:
	return {Registry.MIRAGE: 0.27, 0: 0.28, 1: 0.16, Registry.GRAVEBORN: 0.15, Registry.DODGER: 0.14}


func zombie_density() -> float:   # MIRAGE מביא איתו העתקים -> פחות זומבים "אמיתיים"
	return 0.85


func generators() -> Array:
	return [["boat", 1.1], ["rock", 1.6], ["log", 1.2], ["barrels", 0.4]]


func custom_gen(gname: String, x: float) -> float:
	if not gname in ["boat", "rock", "log"]:
		return 0.0
	if _in_pier(x - 20.0) or _in_pier(x + 170.0):
		return 140.0
	var o := Decor.Obstacle.new()
	o.kind = gname
	o.seed_v = rng.randi()
	match gname:
		"boat":
			o.size = Vector2(rng.randf_range(140.0, 180.0), rng.randf_range(50.0, 62.0))
		"log":
			o.size = Vector2(rng.randf_range(90.0, 130.0), rng.randf_range(22.0, 28.0))
		_:
			o.size = Vector2(rng.randf_range(56.0, 90.0), rng.randf_range(34.0, 52.0))
	o.position = Vector2(x, floor_y)
	main.add_child(o)
	reserve(Rect2(x, floor_y - o.size.y, o.size.x, o.size.y))
	return o.size.x


func boss_kind() -> int:
	return Registry.MIRAGE_KING


func music() -> String:
	return "res://music/level2_suspense.mp3"


func world_tint() -> Color:
	return Color(1.0, 0.97, 0.9)


func fog() -> bool:
	return false


func pits() -> int:
	return 0


func _in_pier(x: float) -> bool:
	for s in _spans:
		if x > float(s[0]) - 30.0 and x < float(s[1]) + 30.0:
			return true
	return false


# ---- רקע: שמיים לבנים, מסות, גדות, קני סוף ----
func build_background(layer: CanvasLayer) -> Node:
	var bg = Backdrop.new()
	bg.level_w = level_w
	bg.sky = func(ci: CanvasItem, v: Vector2, t: float):
		Decor.noon_sky(ci, v, t)
	bg.add_layer(0.08, func(ci: CanvasItem, sc: float, v: Vector2, t: float):
		Decor.mesas(ci, sc, v, 480.0, t))
	bg.add_layer(0.3, func(ci: CanvasItem, sc: float, v: Vector2, t: float):
		Decor.banks(ci, sc, v, 560.0, t))
	bg.add_layer(0.6, func(ci: CanvasItem, sc: float, v: Vector2, t: float):
		Decor.reeds(ci, sc, v, 615.0, t))
	layer.add_child(bg)
	return bg


# ---- העולם: קרקעית סדוקה מעל הכביש, זבל נהר, מזחי עץ ----
func build_world() -> void:
	var x := 0.0
	while x < level_w:
		var rb := Decor.Riverbed.new()
		rb.w = minf(1024.0, level_w - x)
		rb.depth = main.floor_thickness
		rb.seed_v = rng.randi()
		add_world(rb, Vector2(x, floor_y))
		var junk := Decor.RiverJunk.new()
		junk.seed_v = rng.randi()
		add_world(junk, Vector2(x, floor_y))
		x += 1024.0
	for pr in PIERS:
		var ox := level_w * float(pr[0])
		var w: float = pr[1]
		add_floor(ox, floor_y - PIER_H, w, "wood", true, true)
		add_ladder(ox + 12.0, floor_y - PIER_H)
		reserve(Rect2(ox - 20.0, floor_y - PIER_H, w + 40.0, PIER_H))
		_spans.append([ox, ox + w])
		_pickup(PickupScript.AMMO if pr[0] < 0.6 else PickupScript.HEALTH, Vector2(ox + w * 0.6, floor_y - PIER_H - 30.0))


func _pickup(kind: int, pos: Vector2) -> void:
	var p = PickupScript.new()
	p.kind = kind
	p.life = 100000.0
	main.add_child(p)
	p.setup(pos, Vector2.ZERO)


func build_effects() -> void:
	var haze := Decor.HeatHaze.new()
	screen_layer.add_child(haze)
	var dust := Ambient.screen_particles("dust", vp)
	dust.color = Color(0.95, 0.88, 0.72, 0.22)
	dust.direction = Vector2(-1, 0.02)
	dust.initial_velocity_min = 20.0
	dust.initial_velocity_max = 50.0
	screen_layer.add_child(dust)


# MIRAGE על המזחים (מחכים למעלה עם ההעתקים)
func extra_spawns() -> void:
	for i in _spans.size():
		if i % 2 == 1:
			var s: Array = _spans[i]
			spawn(Registry.MIRAGE, lerpf(float(s[0]), float(s[1]), 0.6), floor_y - PIER_H)
