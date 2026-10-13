extends "res://enemies/stationary_boss.gd"
# ============================================================
#  PROTOTYPE (הבוס של שלב 43, "WAR FACTORY") - בוס נייח: אב-טיפוס של טנק-על שעוד לא גמרו לבנות בסוף פס הייצור.
#  תותח כפול, שריון עבה, פיגומים, וו של עגורן. המנוע בסיפון האחורי עדיין פתוח וזוהר = נקודת התורפה.
#  "IT CAN'T TURN YET": מוברג לפס הייצור ופונה שמאלה תמיד (can_turn = false). המנוע נפגע מלמעלה (מגשר השירות) או מאחור.
#  מאחוריו התותחים לא מגיעים אליך - אבל הוא פולט קיטור קירור מהמנוע (steam). weak_on_face = false.
#  התקפות (stationary_boss.gd):
#    twin  - שני פגזים: הראשון אליך, השני לצד שאליו אתה מתחמק. "THEY LEARN YOUR DODGE": סופר לאיזה צד אתה בורח
#            אחרי פגז (DODGE_LEARN פעמים יותר לאותו צד) -> הפגז השני נוחת בדיוק שם.
#    mg    - צרור מהמקלע המשני
#    pound - צמוד אליו: דריסה בזחל
#  "SEND THE WELDERS!": כל WELD_CD קורא לרתכים (WELDER) אם יש פחות מ-WELDERS_MAX - והם מתקנים אותו. תהרוג את הרתכים!
#  לשנות: TWIN_CD, SECOND_DELAY, DODGE_OFF, DODGE_LEARN, MG_CD, MG_N, WELD_CD, WELDERS_MAX.
# ============================================================

const E := preload("res://enemies/empire_kit.gd")

const SOUNDS := {
	"pt_cannon": {"drive": 1.9, "layers": [["N", 0, 0, 0.0, 0.7, 0.0, 4.0, 1.0, 0.1, 0], ["S", 60, 30, 0.0, 0.5, 0.0, 6.0, 0.8, 1.0, 0]]},
	"pt_hydraulic": [["S", 200, 260, 0.0, 0.6, 0.05, 2.0, 0.15, 1.0, 0.02], ["N", 0, 0, 0.0, 0.5, 0.05, 2.0, 0.1, 0.4, 0, 0.6]],
	"pt_klaxon": [["S", 440, 440, 0.0, 0.35, 0.02, 4.0, 0.3, 1.0, 0.0], ["S", 330, 330, 0.4, 0.35, 0.02, 4.0, 0.3, 1.0, 0.0]],
}

const TWIN_CD := 3.6
const SECOND_DELAY := 0.3
const DODGE_OFF := 120.0
const DODGE_LEARN := 2
const BLAST := 80.0
const MG_CD := 2.6
const MG_N := 6
const MG_V := 700.0
const WELD_CD := 18.0
const WELDERS_MAX := 2
const STEAM_CD := 2.6
const STEAM_R := 230.0

var twins := 0               # לבדיקות
var dodge_l := 0
var dodge_r := 0
var predicted := 0
var welders_called := 0
var last_second_x := 0.0
var _twin_cd := 2.0
var _mg_cd := 1.0
var _weld_cd := 6.0
var _left := 0
var _rate := 0.0
var _second := -1.0
var _measure := -1.0
var _fire_x := 0.0
var _recoil := 0.0
var _steam_cd := 1.0
var steams := 0


func stats() -> Dictionary:
	return {"name": "PROTOTYPE", "hp": 380, "walk": 0.0, "chase": 0.0, "damage": 2, "bite_delay": 1.0, "scale": 2.6, "width": 1.8,
		"duck": 0.0, "cover": 0.0, "skin": Color("7a8670"), "shirt": E.UNIFORM, "pants": E.UNIFORM, "shoe": Color("1a1816"),
		"points": 3000, "boss": true, "boss_name": "THE PROTOTYPE - IT CAN'T TURN: HIT THE ENGINE FROM BEHIND OR ABOVE"}


func setup() -> void:
	super.setup()
	z.add_to_group("empire")
	z._dir = -1.0


func can_turn() -> bool:
	return false


func behind(pl: Node) -> bool:
	return signf(pl.global_position.x - z.global_position.x) != z._dir


func hit_size() -> Vector2:   # כל הטנק כולל הצריח
	return Vector2(80.0 * z.wf * z.sc, 58.0 * z.sc)


# אזור הפגיעה מלבני: מעל המנוע יש רק אוויר ופיגום - קליע שנכנס מלמעלה מעל הסיפון האחורי פוגע במנוע
func in_weak(p: Vector2) -> bool:
	if super.in_weak(p):
		return true
	var l: Vector2 = (p - z.global_position) / z.sc
	l.x *= z._dir / maxf(float(z.wf), 0.1)
	return l.y < -44.0 and l.x > -43.0 and l.x < -15.0


func weak_rect() -> Rect2:   # המנוע הפתוח בסיפון האחורי
	return Rect2(-40, -42, 22, 14)


func weak_on_face() -> bool:
	return false


func eye() -> Vector2:   # מקלע משני
	return z.global_position + Vector2(z._dir * 34.0 * z.wf, -22.0) * z.sc


func muzzle(i: int) -> Vector2:
	return z.global_position + Vector2(z._dir * 46.0 * z.wf, -50.0 + float(i) * 4.0) * z.sc


func pref_side() -> float:   # לאיזה צד אתה נוטה להתחמק (0 = עוד לא ידוע)
	if dodge_l - dodge_r >= DODGE_LEARN:
		return -1.0
	if dodge_r - dodge_l >= DODGE_LEARN:
		return 1.0
	return 0.0


func think(pl: Node, delta: float) -> void:
	_twin_cd -= delta
	_mg_cd -= delta
	_weld_cd -= delta
	_rate -= delta
	_recoil = maxf(_recoil - delta * 2.5, 0.0)
	_steam_cd -= delta
	z._dir = -1.0
	# מאחוריו: התותחים לא מגיעים - קיטור מהמנוע
	if behind(pl):
		_left = 0
		if _steam_cd <= 0.0 and absf(pl.global_position.x - z.global_position.x) < STEAM_R + 40.0 * z.wf * z.sc:
			wind("steam", 0.6)
			Sfx.play("pt_hydraulic", z.global_position, 0.0, 0.05, 2)
		return
	# הפגז השני
	if _second >= 0.0:
		_second -= delta
		if _second < 0.0:
			var side := pref_side()
			var tx: float
			if side != 0.0:
				predicted += 1
				tx = _fire_x + side * DODGE_OFF
				if predicted == 1:
					z._popup("IT READS YOUR DODGE", Color("ff8060"), 15, -60.0 - 70.0 * z.sc)
			else:
				tx = _fire_x + (DODGE_OFF if randf() < 0.5 else -DODGE_OFF)
			last_second_x = tx
			_shell(1, Vector2(tx, pl.global_position.y))
	# מדידת ההתחמקות: לאן זזת מאז הירייה
	if _measure >= 0.0:
		_measure -= delta
		if _measure < 0.0:
			var dx: float = pl.global_position.x - _fire_x
			if dx < -50.0:
				dodge_l += 1
			elif dx > 50.0:
				dodge_r += 1
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
	if _weld_cd <= 0.0:
		_weld_cd = WELD_CD
		var n := 0
		for o in z.get_tree().get_nodes_in_group("empire"):
			if not o.dead and o.type_mod != null and o.type_mod.get("healed") != null and absf(o.global_position.x - z.global_position.x) < 900.0:
				n += 1
		if n < WELDERS_MAX and z.hp < z.max_hp:
			wind("welders", 0.6)
			Sfx.play("pt_klaxon", z.global_position, 2.0, 0.02, 2)
			return
	if _twin_cd <= 0.0 and dx2 > 160.0:
		wind("twin", 1.0)
		Sfx.play("pt_hydraulic", z.global_position, 0.0, 0.05, 2)
		return
	if _mg_cd <= 0.0:
		wind("mg", 0.35)


func _shell(i: int, tgt: Vector2) -> void:
	var m := muzzle(i)
	_recoil = 1.0
	Sfx.play("pt_cannon", m, 4.0, 0.05, 2)
	Particles.burst(z.get_parent(), m, "smoke", Vector2(z._dir, -0.2), 8)
	var cam: Camera2D = z.get_viewport().get_camera_2d()
	if cam != null and cam.has_method("shake"):
		cam.shake(6.0, 0.25)
	var flight := clampf(absf(tgt.x - m.x) / 650.0, 0.6, 1.5)
	fire_lob(m, tgt, flight, 2, "shell", BLAST, Color(1.0, 0.6, 0.2), 7.0)


func attack(name: String, pl: Node) -> void:
	match name:
		"pound":
			do_pound(pl)
		"mg":
			_mg_cd = MG_CD
			_left = MG_N
			_rate = 0.0
		"twin":
			_twin_cd = TWIN_CD
			twins += 1
			_fire_x = pl.global_position.x
			_shell(0, Vector2(_fire_x, pl.global_position.y))
			_second = SECOND_DELAY
			_measure = 1.1
		"steam":
			_steam_cd = STEAM_CD
			steams += 1
			var rear: Vector2 = z.global_position + Vector2(-z._dir * 40.0 * z.wf, -36.0) * z.sc
			Sfx.play("tr_steam", rear, 2.0, 0.05, 2)
			Particles.burst(z.get_parent(), rear, "smoke", Vector2(-z._dir, -0.6), 16)
			z._popup("COOLANT!", Color("c0e0ff"), 14, -60.0 - 70.0 * z.sc)
			if behind(pl) and absf(pl.global_position.x - rear.x) < STEAM_R and absf(pl.global_position.y - z.global_position.y) < 180.0:
				pl.hurt(1, Vector2(-z._dir * 2.0, -1.0))
				pl.velocity = Vector2(-z._dir * 420.0, -300.0)
		"welders":
			welders_called += 1
			z._popup("SEND THE WELDERS!", Color("a0d0ff"), 15, -60.0 - 70.0 * z.sc)
			var c: Node = z.get_parent()._spawn_zombie(z.global_position.x - z._dir * 70.0 * z.sc, z.global_position.y, preload("res://enemies/zombie_registry.gd").WELDER)
			if c != null:
				c._alert_t = 6.0


# ============================================================
#  ציור: זחלים ארוכים, גוף ענק משופע, צריח עם תותח כפול, מקלע משני, הסמל, סיפון אחורי פתוח עם מנוע זוהר,
#  פיגומים ווו עגורן מעל המנוע (לא גמור), ניצוצות
# ============================================================
func draw() -> bool:
	begin_draw()
	var armor := col(Color("50544a"))
	var dark := col(Color("2c2e28"))
	var k := wind_k()
	var tt: float = z._time
	# זחלים
	z.draw_colored_polygon(PackedVector2Array([Vector2(-44, -1), Vector2(42, -1), Vector2(47, -8), Vector2(42, -15), Vector2(-44, -15), Vector2(-48, -8)]), dark)
	for q in 9:
		var wx := -38.0 + float(q) * 10.0
		z.draw_circle(Vector2(wx, -7.5), 4.6, col(Color("1a1a18")))
		z.draw_circle(Vector2(wx, -7.5), 1.6, col(Color("5a5a50")))
	# גוף
	Art.fill_shaded(z, PackedVector2Array([Vector2(-46, -14), Vector2(40, -14), Vector2(48, -22), Vector2(36, -33), Vector2(-18, -33), Vector2(-20, -40), Vector2(-46, -40)]), armor, 0.14, 0.4)
	z.draw_line(Vector2(40, -14), Vector2(48, -22), col(Color("6e7266")), 3.0)
	z.draw_line(Vector2(48, -22), Vector2(36, -33), col(Color("6e7266")), 3.0)
	for q in 10:
		z.draw_circle(Vector2(-42.0 + float(q) * 8.5, -16.5), 0.8, col(Color("7a7e70")))
	E.emblem(z, Vector2(8, -23), 6.0, col(Color(0.9, 0.88, 0.82)))
	z.draw_rect(Rect2(Vector2(30, -24), Vector2(10, 3)), col(Color("1a1a1a")))   # מקלע משני
	if _left > 0 and not z.dead:
		Art.glow(z, Vector2(41, -22.5), 4.0, Color(1.0, 0.8, 0.3, 0.8))
	# המנוע הפתוח (סיפון אחורי) + פיגום
	z.draw_rect(Rect2(Vector2(-40, -42), Vector2(22, 9)), col(Color("1a1414")))
	if not z.dead:
		var g := 0.6 + 0.4 * sin(tt * 5.0)
		z.draw_rect(Rect2(Vector2(-38, -40), Vector2(18, 5)), Color(1.0, 0.45 * g + 0.2, 0.1, 0.95))
		Art.glow(z, Vector2(-29, -38), 9.0, Color(1.0, 0.5, 0.15, 0.5 * g))
		for q in 4:   # צינורות / חוטים חשופים
			z.draw_line(Vector2(-38.0 + float(q) * 5.0, -40), Vector2(-36.0 + float(q) * 5.0, -46.0 - float(q % 2) * 2.0), col(Color("6a5040")), 0.8)
	for px in [-46.0, -14.0]:   # פיגום
		z.draw_line(Vector2(px, -40), Vector2(px, -66), col(Color("8a7a40")), 1.0)
	z.draw_line(Vector2(-46, -66), Vector2(-14, -66), col(Color("8a7a40")), 1.0)
	z.draw_line(Vector2(-46, -53), Vector2(-14, -53), col(Color("8a7a40")), 0.8)
	z.draw_line(Vector2(-30, -66), Vector2(-30, -58), col(Color("1a1a1a")), 0.8)   # וו עגורן
	z.draw_arc(Vector2(-30, -56), 2.0, 0.0, PI * 1.3, 6, col(Color("1a1a1a")), 0.8)
	# צריח + תותח כפול
	var rc := 4.0 * _recoil
	for i in 2:
		z.draw_rect(Rect2(Vector2(10.0 - rc, -51.0 + float(i) * 4.0), Vector2(38, 2.6)), dark)
		z.draw_rect(Rect2(Vector2(44.0 - rc, -52.0 + float(i) * 4.0), Vector2(5, 4.4)), dark)
	if winding == "twin" and not z.dead:
		Art.glow(z, Vector2(50.0 - rc, -48.0), 4.0 + 6.0 * k, Color(1.0, 0.6, 0.2, 0.25 + 0.4 * k))
	Art.fill_shaded(z, PackedVector2Array([Vector2(-14, -33), Vector2(20, -33), Vector2(22, -44), Vector2(12, -54), Vector2(-8, -54), Vector2(-16, -44)]), armor.lightened(0.05), 0.15, 0.4)
	z.draw_rect(Rect2(Vector2(-6, -57), Vector2(10, 3)), dark)   # צוהר
	end_draw()
	if not z.dead and Engine.get_physics_frames() % 7 == 0:   # ניצוצות ריתוך על הפיגום
		Particles.burst(z.get_parent(), z.global_position + Vector2(z._dir * -30.0 * z.wf, -44.0) * z.sc, "spark", Vector2.UP, 1)
	return true
