extends "res://enemies/zombie_type.gd"
# ============================================================
#  PRAETORIAN (משלב 45, "THE RED PALACE") - משמר הקיסר: שריון קשקשים אדום, קסדה עם ציצת שיער, מגן מגדל עם הסמל, רומח.
#  המגן חוסם כדורים מהכיוון שהוא מכוון אליו: "front" (יריות ישרות מלפנים) או "high" (יריות מלמעלה - קפיצה / מרפסת).
#  "THEY LEARN YOUR ANGLE - TOGETHER": כל ירייה במשמר נרשמת (main meta "pr_shots", ANGLE_MEMORY אחרונות).
#    רוב היריות מלמעלה? כל המשמר מרים מגנים למעלה - ואז יריות ישרות עוברות. תחליף זוויות!
#  דקירת רומח (THRUST) קרוב: המגן זז הצידה לרגע - חלון לפגוע בו מכל כיוון. פיצוצים עוקפים את המגן.
#  לשנות: ANGLE_MEMORY, HIGH_DY, THRUST_R, THRUST_WIND, THRUST_CD.
# ============================================================

const E := preload("res://enemies/empire_kit.gd")

const SOUNDS := {
	"pr_block": [["S", 900, 700, 0.0, 0.12, 0.0, 25.0, 0.35, 1.0, 0.03], ["N", 0, 0, 0.0, 0.06, 0.0, 40.0, 0.2, 0.3, 0, 0.4]],
	"pr_thrust": [["N", 0, 0, 0.0, 0.15, 0.0, 15.0, 0.3, 0.8, 0, 0.6]],
}

const ANGLE_MEMORY := 8
const HIGH_DY := 0.35
const THRUST_R := 80.0
const THRUST_WIND := 0.35
const THRUST_CD := 1.6

var blocks := 0              # לבדיקות
var thrusts := 0
var _wind := 0.0
var _cd := 1.0
var _open := 0.0
var _flash := 0.0


func stats() -> Dictionary:
	return {"name": "PRAETORIAN", "hp": 50, "walk": 34.0, "chase": 62.0, "damage": 1, "bite_delay": 1.0, "scale": 1.1, "width": 1.15,
		"duck": 0.0, "cover": 0.0, "skin": Color("7a8670"), "shirt": E.RED_D, "pants": Color("2a1a1a"), "shoe": Color("1a1010"), "points": 620}


func setup() -> void:
	z.add_to_group("empire")
	z.add_to_group("praetorians")


func brain_overrides() -> Dictionary:
	return {"aggression": 0.7}


func can_bite() -> bool:
	return false


static func mode(main: Node) -> String:
	var arr: Array = main.get_meta("pr_shots") if main.has_meta("pr_shots") else []
	var hi := 0
	for a in arr:
		if a == "high":
			hi += 1
	return "high" if arr.size() >= 3 and hi * 2 > arr.size() else "front"


func on_damage(_amount: int, hit_pos: Vector2, dir: Vector2, src: Dictionary) -> bool:
	var s := str(src.get("source", "bullet"))
	if not (s == "bullet" or s == "melee") or src.has("blast"):
		return true
	var main: Node = z.get_parent()
	var angle := "high" if dir.y > HIGH_DY else "front"
	var arr: Array = main.get_meta("pr_shots") if main.has_meta("pr_shots") else []
	var before := mode(main)
	arr.append(angle)
	while arr.size() > ANGLE_MEMORY:
		arr.pop_front()
	main.set_meta("pr_shots", arr)
	if mode(main) != before:
		z._popup("SHIELDS UP!" if mode(main) == "high" else "SHIELDS FORWARD!", Color("ff8060"), 13, -95.0)
	if _open > 0.0:
		return true
	var from_front: bool = dir.x * z._dir < 0.0
	if (before == "front" and angle == "front" and from_front) or (before == "high" and angle == "high"):
		blocks += 1
		_flash = 0.1
		Sfx.play("pr_block", hit_pos, -3.0, 0.1, 3)
		Particles.burst(z.get_parent(), hit_pos, "spark", -dir, 3)
		return false
	return true


func physics(pl: Node, delta: float) -> bool:
	_cd -= delta
	_open -= delta
	_flash -= delta
	if z.dead or pl == null or pl.dead or z.goal_x < INF:
		return false
	var d: Vector2 = pl.global_position - z.global_position
	if _wind > 0.0:
		_wind -= delta
		if _wind <= 0.0:   # דקירה
			thrusts += 1
			_open = 0.5
			Sfx.play("pr_thrust", z.global_position, -2.0, 0.1, 2)
			if absf(d.x) < THRUST_R + 20.0 and absf(d.y) < 60.0 and signf(d.x) == z._dir:
				pl.hurt(1, Vector2(z._dir * 2.0, -0.6))
				pl.velocity.x = z._dir * 380.0
		z.velocity.x = move_toward(z.velocity.x, 0.0, 900.0 * delta)
		if not z.is_on_floor():
			z.velocity.y += z.gravity * delta
		z.move_and_slide()
		return true
	if _cd <= 0.0 and absf(d.x) < THRUST_R and absf(d.y) < 60.0:
		_cd = THRUST_CD
		_wind = THRUST_WIND
		z._dir = signf(d.x) if absf(d.x) > 4.0 else z._dir
		return true
	return false


# ============================================================
#  ציור: שריון קשקשים אדום, קסדה עם ציצה, רומח, מגן מגדל גבוה (מלפנים או מורם מעל הראש לפי מה שלמדו)
# ============================================================
func draw() -> bool:
	begin_draw()
	var hi := mode(z.get_parent()) == "high"
	var thrusting := _open > 0.0 or _wind > 0.0
	var o: Dictionary = E.soldier(self, z, Vector2(14 + (8.0 if _open > 0.3 else 0.0), -2), "none", E.RED_D, Vector2(6, -16) if hi else Vector2(10, 4))
	var head: Vector2 = o.head
	var sh: Vector2 = o.sh
	var hf: Vector2 = o.hf
	for q in 3:   # קשקשים
		z.draw_line(sh + Vector2(-7, 4.0 + float(q) * 5.0), sh + Vector2(7, 4.0 + float(q) * 5.0), col(Color("c8a040")), 0.8)
	z.draw_colored_polygon(PackedVector2Array([head + Vector2(-6, -2), head + Vector2(-5, -8), head + Vector2(6, -8), head + Vector2(7, -2)]), col(Color("c8a040")))   # קסדה
	z.draw_colored_polygon(PackedVector2Array([head + Vector2(-6, -8), head + Vector2(-2, -15), head + Vector2(5, -14), head + Vector2(4, -8)]), col(E.RED))   # ציצה
	z.draw_line(hf + Vector2(-14, 0), hf + Vector2(16, 0), col(Color("5a4026")), 1.8)   # רומח
	z.draw_colored_polygon(PackedVector2Array([hf + Vector2(16, -2), hf + Vector2(23, 0), hf + Vector2(16, 2)]), col(Color("c8ccd4")))
	# המגן
	var scol := col(E.RED.lightened(0.3)) if _flash > 0.0 else col(E.RED)
	if thrusting:   # מוזז הצידה
		z.draw_rect(Rect2(Vector2(-4, -44), Vector2(6, 34)), scol)
	elif hi:   # מורם מעל הראש
		z.draw_rect(Rect2(head + Vector2(-12, -18), Vector2(26, 6)), scol)
		z.draw_rect(Rect2(head + Vector2(-12, -18), Vector2(26, 1.5)), col(Color("c8a040")))
		E.emblem(z, head + Vector2(1, -15), 2.6)
	else:   # מלפנים
		z.draw_rect(Rect2(Vector2(8, -48), Vector2(8, 44)), scol)
		z.draw_rect(Rect2(Vector2(8, -48), Vector2(8, 2)), col(Color("c8a040")))
		z.draw_rect(Rect2(Vector2(8, -6), Vector2(8, 2)), col(Color("c8a040")))
		E.emblem(z, Vector2(12, -26), 3.6)
	end_draw()
	return true
