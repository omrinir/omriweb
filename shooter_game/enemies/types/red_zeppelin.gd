extends "res://enemies/stationary_boss.gd"
# ============================================================
#  RED ZEPPELIN (הבוס של שלב 44, "THE DAM") - בוס מרחף: ספינת אוויר אדומה של אימפריית המתים מעל סוף הסכר.
#  מעטפת אדומה ענקית עם הסמל, סנפירי זנב, שני מנועי פרופלור, גונדולה מתחת = נקודת התורפה (תירה מלמטה / מהעגורן).
#  floats() = true (לא נופל), boss_y של השלב קובע את הגובה.
#  התקפות (stationary_boss.gd):
#    bombs - "BOMBS AWAY!": שטיח של BOMB_N פצצות לאורך הכתר סביבך. "THEY LEARN WHERE YOU RUN": זוכר לאן ברחת מהשטיח הקודם,
#            והשטיח הבא מוזז לשם (RUN_LEARN).
#    mg    - צרור MG_N מהגונדולה
#    jump  - "JUMP! JUMP!": JUMP_N צנחנים (PARATROOPER) קופצים מהדלת - כל JUMP_CD כשנשארו מעט חיילים
#  לשנות: BOMB_N, BOMB_GAP, BOMB_CD, RUN_LEARN, MG_CD, MG_N, JUMP_CD, JUMP_N.
# ============================================================

const E := preload("res://enemies/empire_kit.gd")

const SOUNDS := {
	"rz_engine": [["S", 55, 60, 0.0, 1.2, 0.1, 1.0, 0.25, 1.0, 0.08], ["N", 0, 0, 0.0, 1.2, 0.1, 1.0, 0.1, 0.15, 0, 0.6]],
	"rz_bay": [["S", 180, 120, 0.0, 0.5, 0.0, 4.0, 0.3, 1.0, 0.02], ["C", 0, 0, 0.45, 0.04, 0.0, 60.0, 0.3, 1.0, 0]],
	"rz_bell": [["S", 1000, 990, 0.0, 0.25, 0.0, 8.0, 0.25, 1.0, 0.0], ["S", 1000, 990, 0.3, 0.25, 0.0, 8.0, 0.25, 1.0, 0.0]],
}

const BOMB_N := 5
const BOMB_GAP := 95.0
const BOMB_CD := 4.6
const BLAST := 70.0
const RUN_LEARN := 0.8
const MG_CD := 2.2
const MG_N := 6
const MG_V := 680.0
const JUMP_CD := 15.0
const JUMP_N := 2

var carpets := 0             # לבדיקות
var centers := []            # מרכז כל שטיח ביחס אליך
var jumps := 0
var run_bias := 0.0
var _bomb_cd := 2.0
var _mg_cd := 1.2
var _jump_cd := 7.0
var _left := 0
var _rate := 0.0
var _carpet_x := INF
var _measure := -1.0
var _door := 0.0


func stats() -> Dictionary:
	return {"name": "RED ZEPPELIN", "hp": 380, "walk": 0.0, "chase": 0.0, "damage": 2, "bite_delay": 1.0, "scale": 2.4, "width": 1.6,
		"duck": 0.0, "cover": 0.0, "skin": Color("7a8670"), "shirt": E.UNIFORM, "pants": E.UNIFORM, "shoe": Color("1a1816"),
		"points": 3000, "boss": true, "boss_name": "THE RED ZEPPELIN - SHOOT THE GONDOLA FROM BELOW"}


func setup() -> void:
	super.setup()
	z.add_to_group("empire")


func floats() -> bool:
	return true


func hit_size() -> Vector2:   # כל המעטפת + הגונדולה
	return Vector2(100.0 * z.wf * z.sc, 56.0 * z.sc)


func weak_rect() -> Rect2:   # הגונדולה (למטה, במרכז)
	return Rect2(-14, -14, 28, 14)


func eye() -> Vector2:   # המקלע בגונדולה
	return z.global_position + Vector2(z._dir * 12.0 * z.wf, -4.0) * z.sc


func bay() -> Vector2:
	return z.global_position + Vector2(0, -2.0) * z.sc


func think(pl: Node, delta: float) -> void:
	_bomb_cd -= delta
	_mg_cd -= delta
	_jump_cd -= delta
	_rate -= delta
	_door = maxf(_door - delta, 0.0)
	# לאן ברחת מהשטיח
	if _measure >= 0.0:
		_measure -= delta
		if _measure < 0.0 and _carpet_x != INF:
			var dx: float = pl.global_position.x - _carpet_x
			var old := run_bias
			run_bias = clampf(dx * RUN_LEARN, -220.0, 220.0) if absf(dx) > 60.0 else run_bias * 0.5
			if absf(run_bias) > 80.0 and absf(old) <= 80.0:
				z._popup("IT LEARNED WHERE YOU RUN", Color("ff8060"), 15, 60.0)
	if _left > 0:
		if _rate <= 0.0:
			_left -= 1
			_rate = 0.1
			fire_shot(eye(), aim_point(pl, MG_V) + Vector2(randf_range(-8, 8), randf_range(-8, 8)), MG_V, 1, "bolt", Color(1.0, 0.85, 0.4), 4.0)
			Sfx.play("mb_mg", eye(), -3.0, 0.1, 4)
		return
	var dx2: float = absf(pl.global_position.x - z.global_position.x)
	if dx2 > 1300.0:
		return
	if _jump_cd <= 0.0:
		var near := 0
		for o in z.get_tree().get_nodes_in_group("empire"):
			if o != z and not o.dead and absf(o.global_position.x - z.global_position.x) < 900.0:
				near += 1
		_jump_cd = JUMP_CD if near < 3 else 5.0
		if near < 3:
			wind("jump", 0.8)
			Sfx.play("rz_bell", z.global_position, 0.0, 0.02, 2)
			return
	if _bomb_cd <= 0.0:
		wind("bombs", 0.9)
		Sfx.play("rz_bay", bay(), 0.0, 0.05, 2)
		return
	if _mg_cd <= 0.0:
		wind("mg", 0.35)


func attack(name: String, pl: Node) -> void:
	match name:
		"mg":
			_mg_cd = MG_CD
			_left = MG_N
			_rate = 0.0
		"bombs":
			_bomb_cd = BOMB_CD
			carpets += 1
			var cx: float = pl.global_position.x + run_bias
			centers.append(int(cx - pl.global_position.x))
			_carpet_x = pl.global_position.x
			_measure = 1.4
			z._popup("BOMBS AWAY!", Color("ff6040"), 15, 60.0)
			for i in BOMB_N:
				var tx: float = cx + (float(i) - float(BOMB_N - 1) * 0.5) * BOMB_GAP
				var flight := 0.9 + 0.08 * float(i)
				fire_lob(bay(), Vector2(tx, pl.global_position.y), flight, 2, "shell", BLAST, Color(1.0, 0.6, 0.2), 6.0)
		"jump":
			_door = 1.2
			z._popup("JUMP! JUMP!", Color("ff6040"), 15, 60.0)
			var R := preload("res://enemies/zombie_registry.gd")
			var main: Node = z.get_parent()
			var gy: float = float(main.get_meta("boss_ground_y")) if main.has_meta("boss_ground_y") else 630.0
			for i in JUMP_N:
				# נוחתים על הכתר, אבל מתחילים מהדלת (paratrooper.gd מעלה אותם DROP_H)
				var c: Node = main._spawn_zombie(z.global_position.x + (float(i) - 0.5) * 120.0, gy, R.PARATROOPER)
				if c != null:
					c.set_meta("drop", true)
					jumps += 1


# ============================================================
#  ציור: מעטפת אדומה (אליפסה) עם קורות, הסמל, סנפירי זנב, 2 מנועים עם פרופלורים מסתובבים, גונדולה עם חלונות ומקלע,
#  דלת קפיצה שנפתחת, דלתות תא פצצות
# ============================================================
func draw() -> bool:
	begin_draw()
	var tt: float = z._time
	var red := col(Color("a8241c"))
	var k := wind_k()
	var bob := sin(tt * 0.8) * 1.2
	# סנפירי זנב (מאחור)
	z.draw_colored_polygon(PackedVector2Array([Vector2(-40, -34 + bob), Vector2(-56, -56 + bob), Vector2(-52, -34 + bob)]), col(Color("7a1a14")))
	z.draw_colored_polygon(PackedVector2Array([Vector2(-40, -34 + bob), Vector2(-56, -14 + bob), Vector2(-52, -34 + bob)]), col(Color("7a1a14")))
	# המעטפת
	Art.fill_shaded(z, Art.ellipse(Vector2(0, -34 + bob), 50.0, 19.0, 0.0, 28), red, 0.18, 0.45)
	for q in 7:   # קורות
		var x := -36.0 + float(q) * 12.0
		var hh := 19.0 * sqrt(maxf(0.0, 1.0 - pow(x / 50.0, 2.0)))
		z.draw_line(Vector2(x, -34 - hh + bob), Vector2(x, -34 + hh + bob), col(Color("8a1c16")), 0.8)
	z.draw_colored_polygon(Art.ellipse(Vector2(10, -38 + bob), 12.0, 10.0, 0.0, 16), col(Color(0.92, 0.9, 0.85)))
	E.emblem(z, Vector2(10, -38 + bob), 9.0, col(Color(0.92, 0.9, 0.85)))
	# מנועים
	for ex in [-24.0, 24.0]:
		var ep := Vector2(ex, -15 + bob)
		z.draw_line(ep + Vector2(0, -2), ep + Vector2(0, -8), col(Color("2a2a2a")), 1.2)
		z.draw_colored_polygon(Art.ellipse(ep, 6.0, 3.0, 0.0, 10), col(Color("3a3a36")))
		var pa := tt * 30.0
		z.draw_line(ep + Vector2(-6, 0) + Vector2(0, sin(pa) * 4.0), ep + Vector2(-6, 0) - Vector2(0, sin(pa) * 4.0), col(Color("1a1a1a")), 1.2)
	# הגונדולה
	Art.fill_shaded(z, PackedVector2Array([Vector2(-14, -14 + bob), Vector2(14, -14 + bob), Vector2(16, -6 + bob), Vector2(10, -1 + bob), Vector2(-12, -1 + bob), Vector2(-15, -6 + bob)]), col(Color("3a3a32")), 0.15, 0.4)
	for q in 4:   # חלונות
		z.draw_rect(Rect2(Vector2(-10.0 + float(q) * 6.0, -11 + bob), Vector2(4, 3)), Color(1.0, 0.85, 0.5, 0.8))
	z.draw_rect(Rect2(Vector2(12, -6 + bob), Vector2(6, 1.6)), col(Color("1a1a1a")))   # מקלע
	if _left > 0 and not z.dead:
		Art.glow(z, Vector2(19, -5 + bob), 3.0, Color(1.0, 0.8, 0.3, 0.8))
	z.draw_rect(Rect2(Vector2(-6, -1.5 + bob), Vector2(10, 1.5)), col(Color("1a1a1a")) if winding != "bombs" else Color(1.0, 0.4, 0.2, 0.4 + 0.5 * k))   # תא פצצות
	if _door > 0.0:
		z.draw_rect(Rect2(Vector2(-12, -10 + bob), Vector2(5, 8)), Color("0a0a0a"))
	end_draw()
	if not z.dead and Engine.get_physics_frames() % 120 == 0 and Art.on_screen(z, z.global_position):
		Sfx.play("rz_engine", z.global_position, -8.0, 0.05, 2)
	return true
