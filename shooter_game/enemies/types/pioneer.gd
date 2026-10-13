extends "res://enemies/zombie_type.gd"
# ============================================================
#  PIONEER (משלב 42, "METRO BARRACKS") - חבלן-בונה של אימפריית המתים: מפתח ברגים, שק שקי-חול על הגב, כומתה.
#  "THEY LEARNED TO DIG IN": אתה יורה על היחידה שלו בשטח פתוח (BUILD_RANGE)? רץ קדימה ובונה קיר שקי חול (Sandbags)
#    בינך לבין החיילים ("DIG IN!") - BUILD_T שניות על הברכיים. עד MAX_WALLS קירות. קיר פגוע בקרבת מקום -> מתקן אותו.
#  "THEY LEARN TOGETHER": שברת WALLS_LEARN קירות בירי? כל החלוצים (PIONEER) בשלב מוסיפים לוחות פלדה (פי 2 חיים, "STEEL PLATES").
#  לשנות: BUILD_RANGE, BUILD_T, MAX_WALLS, REPAIR_R, WALLS_LEARN.
# ============================================================

const E := preload("res://enemies/empire_kit.gd")
const D42 := preload("res://effects/s42_decor.gd")

const SOUNDS := {
	"en_dig": [["N", 0, 0, 0.0, 0.12, 0.0, 25.0, 0.35, 0.3, 0, 0.6]],
	"en_clank": [["S", 900, 700, 0.0, 0.12, 0.0, 25.0, 0.25, 1.0, 0.02], ["C", 0, 0, 0.0, 0.03, 0.0, 60.0, 0.3, 1.0, 0]],
}

const BUILD_RANGE := Vector2(220.0, 760.0)
const BUILD_T := 2.0
const MAX_WALLS := 3
const REPAIR_R := 300.0
const WALLS_LEARN := 2
const AHEAD := 70.0

enum { IDLE, GO, BUILD, REPAIR }
var state := IDLE
var walls := 0               # לבדיקות
var repairs := 0
var _wall: Node = null
var _scan := 0.6
var _hit := 0.0


func stats() -> Dictionary:
	return {"name": "PIONEER", "hp": 36, "walk": 40.0, "chase": 66.0, "damage": 1, "bite_delay": 0.9, "scale": 1.0, "width": 1.05,
		"duck": 0.3, "cover": 0.6, "skin": Color("7a8670"), "shirt": E.UNIFORM, "pants": E.UNIFORM, "shoe": Color("1a1816"), "points": 480}


func setup() -> void:
	z.add_to_group("empire")


func brain_overrides() -> Dictionary:
	return {"aggression": 0.3}


func can_bite() -> bool:
	return state == IDLE


static func steel(main: Node) -> bool:
	return main.has_meta("walls_lost") and int(main.get_meta("walls_lost")) >= WALLS_LEARN


func on_death() -> void:
	if is_instance_valid(_wall) and not _wall.done():   # קיר שלא נגמר נעלם
		_wall.queue_free()


func physics(pl: Node, delta: float) -> bool:
	_scan -= delta
	_hit -= delta
	if z.dead or pl == null or pl.dead:
		return false
	if not is_instance_valid(_wall):   # (אובייקט שנמחק לא תמיד שווה null - בודקים ישירות)
		_wall = null
		if state != IDLE:
			state = IDLE
			z.goal_x = INF
	match state:
		GO:
			if _wall == null:
				state = IDLE
				z.goal_x = INF
				return false
			var spot: float = _wall.global_position.x - z._dir * 30.0
			z.goal_x = spot
			if absf(z.global_position.x - spot) < 14.0:
				z.goal_x = INF
				state = BUILD if not _wall.done() else REPAIR
			return false
		BUILD:
			_wall.build(delta / BUILD_T)
			_work(delta)
			if _wall.done():
				state = IDLE
				_wall = null
			return _stay(delta)
		REPAIR:
			_work(delta)
			if _hit <= -0.4:
				_hit = 0.0
				_wall.repair(1)
			if _wall.hp >= _wall.max_hp:
				repairs += 1
				state = IDLE
				_wall = null
			return _stay(delta)
	if z.goal_x < INF or _scan > 0.0:
		return false
	_scan = 0.5
	var d: Vector2 = pl.global_position - z.global_position
	# קיר פגוע בקרבת מקום? מתקן
	for w in z.get_tree().get_nodes_in_group("sandbags"):
		if w.done() and w.hp < int(float(w.max_hp) * 0.6) and absf(w.global_position.x - z.global_position.x) < REPAIR_R and absf(w.global_position.y - z.global_position.y) < 40.0:
			_wall = w
			z._dir = signf(w.global_position.x - z.global_position.x + 0.01)
			state = GO
			return false
	# בונים קיר: אתה בטווח, בקו ראייה, ואין כבר מחסה בינך לבינו
	if walls >= MAX_WALLS or absf(d.x) < BUILD_RANGE.x or absf(d.x) > BUILD_RANGE.y or absf(d.y) > 80.0:
		return false
	if not E.clear_shot(z, z.global_position + Vector2(0, -20), pl.global_position + Vector2(0, -20)):
		return false
	var wx: float = z.global_position.x + signf(d.x) * AHEAD
	for w in z.get_tree().get_nodes_in_group("sandbags"):
		if absf(w.global_position.x - wx) < 120.0 and absf(w.global_position.y - z.global_position.y) < 40.0:
			return false
	var sb := D42.Sandbags.new()
	if steel(z.get_parent()):
		sb.steel = true
		sb.max_hp = D42.Sandbags.HP * 2
		sb.hp = sb.max_hp
	z.get_parent().add_child(sb)
	sb.global_position = Vector2(wx, z.global_position.y)
	_wall = sb
	walls += 1
	z._dir = signf(d.x)
	state = GO
	z._popup("STEEL PLATES!" if sb.steel else "DIG IN!", Color("ffd080"), 13, -85.0)
	return false


func _work(delta: float) -> void:
	_hit -= delta
	if Engine.get_physics_frames() % 20 == 0:
		Sfx.play("en_dig" if state == BUILD else "en_clank", z.global_position, -6.0, 0.15, 3)
		Particles.burst(z.get_parent(), z.global_position + Vector2(z._dir * 26.0, -6.0), "smoke", Vector2.UP, 1)


func _stay(delta: float) -> bool:
	z.velocity.x = move_toward(z.velocity.x, 0.0, 800.0 * delta)
	if not z.is_on_floor():
		z.velocity.y += z.gravity * delta
	z.move_and_slide()
	return true


# ============================================================
#  ציור: כומתה עם הסמל, שק על הגב, מפתח ברגים. בבנייה / תיקון - כורע, היד עולה ויורדת
# ============================================================
func draw() -> bool:
	begin_draw()
	var working := state == BUILD or state == REPAIR
	var swing := sin(float(Engine.get_physics_frames()) * 0.35) if working else 0.0
	var o: Dictionary = E.soldier(self, z, Vector2(12, 8.0 + swing * 8.0) if working else Vector2(9, 6), "none", E.UNIFORM, Vector2(6, 10) if working else Vector2(999, 0))
	var head: Vector2 = o.head
	var sh: Vector2 = o.sh
	var hf: Vector2 = o.hf
	z.draw_colored_polygon(PackedVector2Array([head + Vector2(-6, -2), head + Vector2(-4, -7), head + Vector2(5, -7), head + Vector2(7, -3)]), col(E.RED_D))   # כומתה
	E.emblem(z, head + Vector2(3.5, -4.5), 1.6)
	z.draw_colored_polygon(Art.ellipse(sh + Vector2(-10, 9), 6.0, 10.0, 0.0, 10), col(Color("8a7a58")))   # שק
	z.draw_line(sh + Vector2(-12, 0), sh + Vector2(-8, 0), col(Color("5a4a30")), 1.2)
	z.draw_line(hf, hf + Vector2(4, -9), col(Color("8a8e96")), 2.2)   # מפתח
	z.draw_circle(hf + Vector2(4.5, -10), 2.2, col(Color("8a8e96")))
	end_draw()
	return true
