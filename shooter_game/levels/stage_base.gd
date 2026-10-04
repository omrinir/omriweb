extends Node2D
# ============================================================
#  STAGE BASE - בסיס לשלבים 5-9 (levels/stage_N.gd).
#  main.gd יוצר את השלב (levels/stage_registry.gd), ושואל אותו:
#    איזה רקע, אילו זומבים, אילו מכשולים, קומות, סכנות, נשקים ובוס.
#
#  ****  איך מוסיפים שלב חדש  ****
#   1. יוצרים levels/stage_10.gd שמתחיל ב:  extends "res://levels/stage_base.gd"
#   2. מממשים את הפונקציות שמסומנות "לדרוס" למטה.
#   3. רושמים אותו ב-levels/stage_registry.gd, ומוסיפים כותרת ב-game_state.gd -> LEVEL_TITLES
#
#  קואורדינטות: floor_y = גובה הכביש הראשי (בערך 630). קומה שנייה ~ floor_y - 160,
#  גגות ~ floor_y - 320. קפיצה רגילה ~ 128 פיקסלים, כפולה ~ 220.
# ============================================================

const Art := preload("res://art.gd")
const Kit := preload("res://effects/backdrop_kit.gd")
const Ambient := preload("res://effects/ambient.gd")
const Backdrop := preload("res://effects/parallax_backdrop.gd")
const PlatformScript := preload("res://environment/platform.gd")
const LadderScript := preload("res://environment/ladder.gd")
const HazardScript := preload("res://environment/hazard.gd")
const Registry := preload("res://enemies/zombie_registry.gd")
const FireScript := preload("res://fire.gd")
const RainScript := preload("res://rain.gd")

const FLOOR2 := 160.0     # כמה מעל הכביש הקומה השנייה
const ROOF := 320.0       # גגות

var main: Node = null     # main.gd
var floor_y := 630.0
var level_w := 10240.0
var rng: RandomNumberGenerator
var vp := Vector2(1280, 720)
var screen_layer: CanvasLayer = null   # שכבה מעל המשחק (גשם, אפר, ברקים)


# ============ לדרוס (override) ============
# משקל לכל סוג זומבי: {kind: weight}. 0-19 = זומבים קיימים, 20+ = enemies/zombie_registry.gd
func zombie_weights() -> Dictionary:
	return {0: 1.0}


# מכשולים על הכביש: [[שם, משקל], ...]. שמות קיימים ב-main.gd:
# car, barrels, barrier, crates, rubble, bus, tires, sandbags, block, wall, container, train
# או שם משלך שמטופל ב-custom_gen()
func generators() -> Array:
	return [["car", 3.0], ["barrels", 2.0], ["barrier", 2.0], ["crates", 1.5], ["rubble", 1.5]]


# מכשול מותאם: מחזיר כמה רוחב הוא תפס (0 = לא טיפלתי)
func custom_gen(_name: String, _x: float) -> float:
	return 0.0


# הרקע (פרלקסה). מוסיפים ל-layer ומחזירים את הצומת
func build_background(layer: CanvasLayer) -> Node:
	var bg = Backdrop.new()
	bg.level_w = level_w
	bg.sky = func(ci: CanvasItem, v: Vector2, _t: float): Kit.gradient_sky(ci, v, [Color("101018"), Color("2a2030")])
	layer.add_child(bg)
	return bg


# קומות, סולמות, סכנות, קישוטים בעולם (נקרא אחרי שהכביש נבנה, לפני המכשולים)
func build_world() -> void:
	pass


# אפקטים על המסך (screen_layer): אפר, גשם, ברקים...
func build_effects() -> void:
	pass


# זומבים מיוחדים במקומות מיוחדים (קומות עליונות, מארבים...). נקרא אחרי הפיזור הרגיל
func extra_spawns() -> void:
	pass


# נשקים שמופיעים בשלב (מ-weapons/weapon_db.gd)
func weapon_offers() -> Array:
	return []


# הבוס שליד היציאה (-1 = בלי בוס)
func boss_kind() -> int:
	return 5


func music() -> String:
	return "res://music/level2_suspense.mp3"


# גוון לכל העולם (CanvasModulate). WHITE = בלי
func world_tint() -> Color:
	return Color.WHITE


# כמה עמוק "מתחת לאדמה" יש מקום (מצלמה זזה למטה). 0 = אין
func underground_depth() -> float:
	return 0.0


# חורים בכביש שנופלים דרכם למטה (לא בורות רגילים): [[x, w], ...]
func road_holes() -> Array:
	return []


func pits() -> int:
	return 1


func street_props() -> bool:    # רמזורים, עמודי חשמל, סימוני כביש, מכסי ביוב
	return false


func street_lamps() -> bool:
	return false


func fog() -> bool:
	return true


func zombie_density() -> float:   # מכפיל על כמות הזומבים
	return 1.0


# ============ עזרים ============
# קומה (one-way). x, y = פינה שמאלית-עליונה
func add_floor(x: float, y: float, w: float, style := "concrete", supports := true, railing := false) -> Node:
	var p = PlatformScript.new()
	p.position = Vector2(x, y)
	p.size = Vector2(w, 14.0 if style != "steel" and style != "scaffold" else 9.0)
	p.style = style
	p.supports = supports
	p.railing = railing
	p.ground_y = floor_y
	main.add_child(p)
	return p


func add_ladder(x: float, top_y: float, bottom_y := -1.0) -> Node:
	var l = LadderScript.new()
	var by := floor_y if bottom_y < 0.0 else bottom_y
	l.position = Vector2(x, by)
	l.height = by - top_y
	main.add_child(l)
	return l


# בלוק מוצק (קיר / בניין) דרך main.gd (לבנים שאפשר לשבור או לא)
func add_block(x: float, y_top: float, w: float, h: float, col := Color("5a5650"), breakable := false, style := 2) -> void:
	main._make_brick(Vector2(x, y_top), Vector2(w, h), style, col, breakable)
	reserve(Rect2(x, y_top, w, h))


# מסמן אזור שבו לא יופיעו מכשולים / זומבים על הכביש
func reserve(r: Rect2) -> void:
	main._rects.append(r)


func free_x(x: float, margin := 40.0) -> bool:
	for r in main._rects:
		if x > r.position.x - margin and x < r.end.x + margin and r.end.y >= floor_y - 4.0:
			return false
	return true


# זומבי במקום מסוים (y = כפות הרגליים)
func spawn(kind: int, x: float, y := -1.0) -> Node:
	var z: Node = main._spawn_zombie(x, floor_y, kind, rng)
	if z != null and y >= 0.0:
		z.position.y = y
	return z


func add_world(node: Node2D, pos: Vector2) -> Node2D:
	node.position = pos
	main.add_child(node)
	return node


func add_fire(pos: Vector2, w := 22.0, h := 28.0) -> void:
	var f = FireScript.new()
	f.width = w
	f.height = h
	f.position = pos
	main.add_child(f)


# סכנה (environment/hazard.gd או יורש)
func add_hazard(h: Node2D, pos: Vector2) -> Node2D:
	h.position = pos
	main.add_child(h)
	return h
