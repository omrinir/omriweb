extends "res://enemies/types/mirage.gd"
# ============================================================
#  FATA MORGANA (בוס שלב 17, "THE DRY RIVER") - MIRAGE ענק, מלך החום.
#  אותו כלל: רק לאמיתי יש צל ואבק. יש לו 3 העתקים (4 בקשה) שחוזרים מהר.
#  SHUFFLE: כל SHUFFLE_T שניות (או אחרי כמה פגיעות) - הבהוב חזק, והאמיתי מתחלף במקום עם אחד ההעתקים.
#    צריך למצוא את הצל מחדש. (THEY LEARN: אחרי שפגעת בו, הוא מתחלף מהר יותר)
#  לשנות: SHUFFLE_T, HITS_TO_SHUFFLE, COPIES_K.
# ============================================================

const COPIES_K := [3, 3, 4]
const SHUFFLE_T := Vector2(8.0, 11.0)
const HITS_TO_SHUFFLE := 5

var _shuffle_t := 9.0
var _hits := 0


func stats() -> Dictionary:
	return {"name": "FATA MORGANA", "boss_name": "FATA MORGANA  -  ONLY THE REAL ONE CASTS A SHADOW", "boss": true, "hp": 180, "walk": 50.0, "chase": 115.0, "damage": 2, "bite_delay": 0.9,
		"scale": 1.65, "width": 1.0, "duck": 0.0, "cover": 0.0, "skin": Color("c2ae90"), "shirt": Color("e4d8bc"), "pants": Color("7a6a54"),
		"shoe": Color("4a3a2a"), "points": 3200}


func _want_copies() -> int:
	return int(COPIES_K[clampi(Settings.difficulty, 0, 2)])


func _regen_time() -> float:
	return 4.5


func on_damage(amount: int, hit_pos: Vector2, dir: Vector2, src: Dictionary) -> bool:
	if not is_copy:
		_hits += 1
		if _hits >= HITS_TO_SHUFFLE:
			_shuffle_t = minf(_shuffle_t, 0.25)
	return super.on_damage(amount, hit_pos, dir, src)


func logic(pl: Node, d: Vector2, delta: float, speed: float) -> float:
	if not is_copy:
		_shuffle_t -= delta
		if _shuffle_t <= 0.0:
			_shuffle()
	return super.logic(pl, d, delta, speed)


# מתחלף במקום עם אחד ההעתקים (הבהוב בשניהם)
func _shuffle() -> void:
	_shuffle_t = randf_range(SHUFFLE_T.x, SHUFFLE_T.y)
	_hits = 0
	var alive := _alive_copies()
	if alive.is_empty():
		return
	var c = alive[randi() % alive.size()]
	var a: Vector2 = z.global_position
	var b: Vector2 = c.global_position
	for p in [a, b]:
		var fx := Shimmer.new()
		fx.position = p
		fx.sc = z.sc
		fx.col = z.shirt
		z.get_parent().add_child(fx)
	z.global_position = b
	c.global_position = a
	var dd: float = c._dir
	c._dir = z._dir
	z._dir = dd
	Sfx.play("mr_hum", z.global_position, 0.0, 0.1, 2, 0.7)
	Sfx.play("mr_pop", a, 0.0, 0.1, 2, 0.6)


# כתר של גולגולת אייל + גלימה ארוכה
func _extras() -> void:
	var p: float = z._walk_phase
	var sh := Vector2(3.0, -43.0 + absf(sin(p)) * 0.8)
	var head := sh + Vector2(3.5, -9.0)
	var bone := col(Color("ece4d0"))
	var dark := col(Color("3a2a1a"))
	Art.oval(z, head + Vector2(0.5, -7.0), 5.5, 3.2, bone, 0.0, Art.OUTLINE, 1.0)   # גולגולת
	z.draw_circle(head + Vector2(2.5, -7.0), 1.0, dark)
	for side in [0, 1]:   # קרני איל מסולסלות אחורה ולמטה (הרחוקה כהה יותר)
		var c := head + Vector2(-4.0 + float(side) * 1.5, -4.0)
		var pts := PackedVector2Array()
		for i in 9:
			var a := -PI * 0.35 - float(i) / 8.0 * PI * 1.55   # מלמעלה, אחורה, למטה וקדימה
			var rr := 5.6 - float(i) * 0.38
			pts.append(c + Vector2(cos(a) * rr, sin(a) * rr * 1.1))
		Art.limb(z, pts, 2.2 - float(side) * 0.4, bone if side == 0 else col(Color("b8ae98")))
	for i in 3:   # עצמות תלויות על חוט
		var bp := sh + Vector2(-5.0 + float(i) * 4.0, 6.0 + float(i % 2) * 2.0)
		z.draw_line(bp, bp + Vector2(0.0, 4.0), bone, 1.4)
