extends "res://enemies/zombie_type.gd"
# ============================================================
#  TANK (שלב 8, וגם הבוס של השלב) - נבדק ענק שנמלט מתא הכליאה וסוחב דלת פלדה של מעבדה.
#  צללית: ענק כפוף, כתפיים רחבות מאוד, ראש קטן שקוע עם צווארון כליאה ממתכת (נורה מהבהבת),
#         2 מיכלי כימיקלים ירוקים על הגב עם צינורות, ודלת מעבדה עם פסי אזהרה וחלון קטן.
#  תנועה: איטי מאוד, מסתובב לאט (TURN_TIME) - מי שעוקף אותו מקבל כמה שניות על הגב.
#  מחסה (הקושי מההתנהגות, לא מהחיים):
#    * הדלת חוסמת קליעים מלפנים (חוץ מהרגליים!). PANEL_HP פגיעות והיא נשברת.
#    * כשיורים עליו מרחוק - "נוטע" את הדלת ומתכופף מאחוריה, ואז מתקדם שוב (קפיצות צפרדע).
#    * לפעמים (ותמיד כשהדלת נשברה) הוא רץ להתחבא מאחורי שולחנות / מכולות במעבדה (z._try_cover).
#  התקפה: מקרוב - מניח את הדלת, מרים את שתי הידיים (0.85 שנ' אזהרה - חלון לירות בו!)
#         ומכה ברצפה: גל הדף שפוגע בשחקן שעל הרצפה (קפיצה = מתחמקים). מקרוב מאוד: דחיפה עם הדלת.
#  צליל: "tank_stomp" (צעדים כבדים), "tank_bellow" (שאגה עמוקה לפני מכה), "tank_slam" (מכה ברצפה).
#  בוס: stats()["boss"] = true רק לזומבי שעומד ליד היציאה (main.gd נותן לו chase_range = 650).
# ============================================================

const SOUNDS := {
	"tank_stomp": [["S", 70, 38, 0.0, 0.22, 0.0, 16.0, 0.9, 1.0, 0], ["N", 0, 0, 0.0, 0.1, 0.0, 30.0, 0.35, 0.08, 0]],
	"tank_bellow": {"drive": 3.0, "layers": [["V", 62, 48, 0.0, 1.1, 0.08, 2.0, 1.0, 1.0, 0.05, 0, [330, 700, 22]], ["N", 0, 0, 0.0, 1.0, 0.1, 2.5, 0.2, 0.1, 0]]},
	"tank_slam": {"rev": 0.3, "drive": 2.6, "layers": [["N", 0, 0, 0.0, 0.01, 0.0, 300.0, 1.4, 1.0, 0], ["S", 58, 26, 0.0, 0.7, 0.0, 5.0, 1.4, 1.0, 0], ["N", 0, 0, 0.0, 0.5, 0.0, 6.0, 0.8, 0.07, 0], ["C", 0, 0, 0.05, 0.6, 0.0, 4.0, 0.5, 1.0, 0]]},
}

enum { WALK, BRACE, WINDUP, RECOVER }
const PANEL_HP := 36
const TURN_TIME := 0.75
const SLAM_RANGE := 150.0

var state := WALK
var panel := true
var panel_hp := PANEL_HP
var blocked := 0             # לבדיקות: כמה קליעים הדלת עצרה
var _face := 1.0
var _turn_t := 0.0
var _st_t := 0.0
var _slam_cd := 1.5
var _bash_cd := 0.0
var _brace_cd := 2.0
var _cover_cd := 2.0
var _step_t := 0.0
var _blk_pop := 0.0
var _recent_shots := 0.0
var _last_shots := 0


func _boss() -> bool:
	return z != null and float(z.chase_range) > 600.0


func stats() -> Dictionary:
	return {"name": "TANK", "hp": 150, "walk": 26.0, "chase": 50.0, "damage": 2, "bite_delay": 1.4, "scale": 1.7, "width": 1.55,
		"duck": 0.0, "cover": 0.0, "skin": Color("7c8a86"), "shirt": Color("3a4652"), "pants": Color("262c34"), "shoe": Color("17171a"),
		"points": 600, "boss": _boss(), "boss_name": "SUBJECT ZERO - THE TANK"}


func brain_overrides() -> Dictionary:
	return {"aggression": -0.2, "cover_usage": 0.4}


func use_brain_movement() -> bool:
	return false


func setup() -> void:
	_face = z._dir
	_last_shots = PlayerMemory.shots_total


func can_bite() -> bool:
	return false   # ההתקפות שלו: מכה ברצפה + דחיפה עם הדלת


func panel_up() -> bool:
	return panel and (state == WALK or state == BRACE)


func physics(_pl: Node, delta: float) -> bool:
	var shots: int = PlayerMemory.shots_total
	_recent_shots = maxf(_recent_shots - delta * 1.5, 0.0) + float(shots - _last_shots)
	_last_shots = shots
	return false


func logic(pl: Node, d: Vector2, delta: float, speed: float) -> float:
	_st_t -= delta
	_slam_cd -= delta
	_bash_cd -= delta
	_brace_cd -= delta
	_cover_cd -= delta
	_blk_pop -= delta
	var dist := absf(d.x)
	var want: float = signf(d.x) if d.x != 0.0 else _face
	# מסתובב לאט: מי שעוקף אותו מקבל זמן לירות בגב
	if want != _face and state != WINDUP:
		if _turn_t <= 0.0:
			_turn_t = TURN_TIME
			Sfx.play("tank_stomp", z.global_position, -2.0, 0.1, 2)
		_turn_t -= delta
		if _turn_t <= 0.0:
			_face = want
		z._dir = _face
		return 0.0
	_turn_t = 0.0
	z._dir = _face
	match state:
		WINDUP:   # ידיים למעלה - חלון לירות בו
			if _st_t <= 0.0:
				_slam(pl)
			return 0.0
		RECOVER:
			if _st_t <= 0.0:
				state = WALK
			return 0.0
		BRACE:   # מתכופף מאחורי הדלת
			if _st_t <= 0.0 or dist < 200.0:
				state = WALK
				_brace_cd = randf_range(1.6, 2.6)
			return 0.0
	# WALK
	if dist < SLAM_RANGE * 0.75 and absf(d.y) < 80.0 and _slam_cd <= 0.0 and z.is_on_floor():
		state = WINDUP
		_st_t = 0.85
		Sfx.play("tank_bellow", z.global_position, 2.0, 0.1, 2)
		z._popup("!!", Color(1.0, 0.4, 0.2), 20, -100.0)
		return 0.0
	if dist < 46.0 and panel and _bash_cd <= 0.0 and absf(d.y) < 60.0:   # דחיפה עם הדלת
		_bash_cd = 1.6
		pl.hurt(1, Vector2(_face, 0.0))
		pl.velocity += Vector2(_face * 380.0, -160.0)
		Sfx.play("clang", z.global_position, -2.0, 0.1, 2)
	# יורים עליו מרחוק: מחסה (חפץ בסביבה) או נוטע את הדלת
	if dist > 260.0 and _recent_shots > 1.5:
		if _cover_cd <= 0.0 and (not panel or randf() < 0.45):
			_cover_cd = randf_range(3.0, 5.0)
			if z._try_cover(pl):
				return 0.0
		if panel and _brace_cd <= 0.0:
			state = BRACE
			_st_t = randf_range(1.3, 2.1)
			Sfx.play("clang", z.global_position, -6.0, 0.1, 2)
			return 0.0
	_step_t -= delta
	if _step_t <= 0.0:
		_step_t = 0.55
		if Art.on_screen(z, z.global_position):
			Sfx.play("tank_stomp", z.global_position, -6.0, 0.15, 2)
	return speed


func _slam(pl: Node) -> void:
	state = RECOVER
	_st_t = 1.1
	_slam_cd = randf_range(2.6, 3.4)
	var at: Vector2 = z.global_position + Vector2(_face * 26.0 * z.sc, 0.0)
	Sfx.play("tank_slam", at, 3.0)
	var cam: Camera2D = z.get_viewport().get_camera_2d()
	if cam != null and cam.has_method("shake"):
		cam.shake(9.0, 0.4)
	var fx := Shock.new()
	z.get_parent().add_child(fx)
	fx.global_position = at
	Particles.burst(z.get_parent(), at, "smoke", Vector2.UP, 8)
	var pp: Vector2 = pl.global_position
	if absf(pp.x - at.x) < SLAM_RANGE and absf(pp.y - at.y) < 50.0 and pl.is_on_floor():
		pl.hurt(z.damage, Vector2(signf(pp.x - at.x), 0.0))
		pl.velocity += Vector2(signf(pp.x - at.x) * 300.0, -300.0)


func on_damage(_amount: int, hit_pos: Vector2, dir: Vector2, src: Dictionary) -> bool:
	var source: String = src.get("source", "bullet")
	if not panel_up() or z._cover_state != 0:
		return true
	if source != "bullet" and source != "melee" and source != "taser":
		return true   # פיצוצים / אש עוברים
	if dir.x * z._dir >= 0.0:
		return true   # מאחור
	var ly: float = (hit_pos.y - z.global_position.y) / z.sc
	if ly > -14.0:
		return true   # הרגליים מתחת לדלת
	blocked += 1
	panel_hp -= 1
	Sfx.play("shield", hit_pos, -4.0, 0.15, 3)
	Particles.burst(z.get_parent(), hit_pos, "fire", -dir, 3)
	if panel_hp <= 0:
		panel = false
		z._popup("PANEL BROKEN!", Color(1.0, 0.8, 0.3), 16, -110.0)
		Sfx.play("clang", z.global_position, 2.0)
		var deb := preload("res://debris.gd")
		for i in 8:
			var c = deb.new()
			z.get_parent().add_child(c)
			c.setup(hit_pos, Vector2(randf_range(4, 9), randf_range(3, 6)), Color("8a9098") if i % 2 == 0 else Color("d8b020"), Vector2(-dir.x * randf_range(60, 220), -randf_range(80, 260)))
		_cover_cd = 0.0
	elif _blk_pop <= 0.0:
		_blk_pop = 0.8
		z._popup("BLOCKED", Color("c0c8d0"), 13, -105.0)
	Game.on_zombie_hit({"source": "bullet", "zone": "shield"})
	return false


func draw() -> bool:
	begin_draw()
	var sk := col(z.skin)
	var dark := col(Art.shade(z.skin, 0.3))
	var suit := col(z.shirt)
	var pa := col(z.pants)
	var p: float = z._walk_phase
	var crouch: float = 8.0 if state == BRACE and not z.dead else 0.0
	var up: bool = state == WINDUP and not z.dead
	var f: Array = feet(4.0, 2.0)
	var hip := Vector2(-2.0, -22.0 + crouch * 0.5 + absf(sin(p)) * 0.8)
	var sh := Vector2(4.0, -40.0 + crouch)
	var head := sh + Vector2(6.0, -7.0)
	# מיכלים על הגב
	for i in 2:
		var cp := sh + Vector2(-15.0 + float(i) * 5.0, 2.0 + float(i) * 2.0)
		Art.fill_shaded(z, PackedVector2Array([cp + Vector2(-3, -6), cp + Vector2(3, -6), cp + Vector2(3, 10), cp + Vector2(-3, 10)]), col(Color("3e4a3a")), 0.2, 0.3, Art.OUTLINE, 1.0)
		var lv := 0.5 + 0.3 * sin(z._time * 2.0 + float(i))
		z.draw_rect(Rect2(cp + Vector2(-2, 9.0 - 15.0 * lv), Vector2(4, 15.0 * lv)), Color(0.4, 1.0, 0.3, 0.75))
		z.draw_line(cp + Vector2(0, -6), head + Vector2(-5, 2), col(Color(0.12, 0.12, 0.12)), 1.2)
	# זרוע אחורית
	var bh := sh + Vector2(10.0, 10.0)
	if up:
		bh = sh + Vector2(2.0, -22.0)
	elif state == RECOVER:
		bh = sh + Vector2(18.0, 20.0)
	Art.limb(z, PackedVector2Array([sh + Vector2(-4, 2), sh.lerp(bh, 0.5) + Vector2(-2, 3), bh]), 8.0, dark)
	Art.disc(z, bh, 5.0, dark)
	# רגליים עבות
	z._leg(hip + Vector2(-4, 0), f[1], col(Art.shade(z.pants, 0.25)), dark, col(z.shoe))
	z._leg(hip + Vector2(4, 0), f[0], pa, sk, col(z.shoe))
	# גוף ענק כפוף
	var body := PackedVector2Array([hip + Vector2(-10, 4), hip + Vector2(9, 3), sh + Vector2(14, 6), sh + Vector2(10, -6), sh + Vector2(-4, -9), sh + Vector2(-13, -2)])
	Art.fill_shaded(z, body, sk, 0.15, 0.4)
	# שרידי חליפת כליאה + רצועות
	Art.fill(z, PackedVector2Array([hip + Vector2(-10, 4), hip + Vector2(9, 3), hip + Vector2(8, -6), hip + Vector2(-9, -5)]), suit, Art.OUTLINE, 1.0)
	z.draw_line(sh + Vector2(-10, -3), hip + Vector2(8, -4), col(Color("2a2a2a")), 2.0)
	z.draw_line(sh + Vector2(10, -4), hip + Vector2(-8, -4), col(Color("2a2a2a")), 2.0)
	for i in 3:   # צלקות ניתוח עם תפרים
		var sc0 := sh.lerp(hip, 0.3 + 0.2 * float(i)) + Vector2(4.0, 0.0)
		z.draw_line(sc0, sc0 + Vector2(6, 3), col(Color(0.45, 0.15, 0.15)), 1.0)
	# ראש קטן שקוע + צווארון
	Art.oval_shaded(z, head, 5.0, 5.5, sk, 0.0)
	Art.fill_shaded(z, PackedVector2Array([head + Vector2(-7, 3), head + Vector2(5, 2), head + Vector2(6, 7), head + Vector2(-7, 8)]), col(Color("6a7078")), 0.25, 0.3, Art.OUTLINE, 1.0)
	var blink := Color(1.0, 0.15, 0.1) if int(z._time * 2.0) % 2 == 0 else Color(0.35, 0.05, 0.05)
	z.draw_circle(head + Vector2(-2, 5), 1.2, blink)
	z.draw_circle(head + Vector2(2.5, -1.5), 1.0, Color(1.0, 0.85, 0.3))
	z.draw_line(head + Vector2(0.5, 2.0), head + Vector2(4.5, 2.0), Color(0.2, 0.0, 0.0), 1.2)
	# הדלת
	if panel and not z.dead:
		var dp := sh + Vector2(17.0, 12.0)    # מרכז הדלת כשהיא מורמת
		var rot := 0.05
		if state == BRACE:
			dp = Vector2(22.0, -22.0)
			rot = 0.0
		elif up or state == RECOVER:   # הדלת נעוצה מאחוריו
			dp = Vector2(-22.0, -24.0)
			rot = -0.15
		var door := Transform2D(rot, dp) * PackedVector2Array([Vector2(-5, -27), Vector2(5, -27), Vector2(5, 24), Vector2(-5, 24)])
		Art.fill_shaded(z, door, col(Color("8e969e")), 0.25, 0.35, Art.OUTLINE, 1.4)
		var win := Transform2D(rot, dp) * PackedVector2Array([Vector2(-3, -21), Vector2(3, -21), Vector2(3, -11), Vector2(-3, -11)])
		Art.fill(z, win, Color(0.25, 0.45, 0.5, 0.9), Art.OUTLINE, 0.8)
		z.draw_line(Transform2D(rot, dp) * Vector2(-3, -21), Transform2D(rot, dp) * Vector2(3, -11), Color(1, 1, 1, 0.3), 0.6)
		for i in 3:   # פסי אזהרה
			var a := Transform2D(rot, dp) * Vector2(-5.0 + float(i) * 3.5, 23.5)
			var b := Transform2D(rot, dp) * Vector2(-2.0 + float(i) * 3.5, 17.0)
			z.draw_line(a, b, col(Color("e0b020")), 1.8)
		z.draw_line(Transform2D(rot, dp) * Vector2(-5, 16), Transform2D(rot, dp) * Vector2(5, 16), Color(0.05, 0.05, 0.05), 1.0)
		var dmg := 1.0 - float(panel_hp) / float(PANEL_HP)
		for i in int(dmg * 8.0):   # שקעים מקליעים
			var hp := Transform2D(rot, dp) * Vector2(-3.0 + float((i * 5) % 7), -6.0 + float((i * 11) % 26))
			z.draw_circle(hp, 1.0, Color(0.2, 0.2, 0.22))
	# זרוע קדמית ענקית
	var fh := sh + Vector2(16.0, 12.0)
	if up:
		fh = sh + Vector2(8.0, -24.0)
	elif state == RECOVER:
		fh = sh + Vector2(24.0, 22.0)
	elif state == BRACE:
		fh = Vector2(18.0, -30.0)
	Art.limb(z, PackedVector2Array([sh + Vector2(6, 1), sh.lerp(fh, 0.5) + Vector2(3, 4), fh]), 9.0, sk)
	Art.disc(z, fh, 5.5, sk)
	for i in 3:
		z.draw_line(fh + Vector2(2, -3 + i * 3), fh + Vector2(6, -3 + i * 3), Art.OUTLINE, 1.6)
	end_draw()
	return true


# גל הדף מהמכה ברצפה (מתרחב ונעלם)
class Shock extends Node2D:
	var _t := 0.0

	func _ready() -> void:
		z_index = 8

	func _process(delta: float) -> void:
		_t += delta
		if _t > 0.45:
			queue_free()
			return
		queue_redraw()

	func _draw() -> void:
		var k := _t / 0.45
		for s in [-1.0, 1.0]:
			var x: float = s * k * 150.0
			draw_colored_polygon(PackedVector2Array([Vector2(x - 10.0 * s, 0), Vector2(x, -18.0 * (1.0 - k)), Vector2(x + 8.0 * s, 0)]), Color(0.75, 0.7, 0.6, 0.8 * (1.0 - k)))
		draw_arc(Vector2.ZERO, 20.0 + k * 140.0, PI, TAU, 24, Color(1.0, 0.9, 0.7, 0.6 * (1.0 - k)), 3.0)
