extends "res://enemies/stationary_boss.gd"
# ============================================================
#  BEHEMOTH (הבוס של שלב 40, "HARBOR OF WAR") - בוס נייח: טנק כבד של אימפריית המתים על הרציף, ליד האונייה.
#  המפקד הזומבי מציץ מהצריח עם משקפת = נקודת התורפה. דגל אדום על האנטנה, הסמל על הצריח.
#  התקפות (stationary_boss.gd):
#    shell - פגז תותח בקשת שמתפוצץ (BLAST). "THEY LEARN - BRACKETING": הפגז הראשון נוחת רחוק ממך (קצר / ארוך),
#            וכל פגז הבא מתקן חצי מהטעות - כל עוד אתה נשאר באותו אזור. זזת יותר מ-MOVE_RESET? הוא מתחיל מחדש.
#    mg    - צרור MG_N כדורים ממקלע הגוף (מקדים אותך אחרי פספוסים)
#    pound - צמוד אליו: יריית תותח מטווח אפס (מכת קרקע)
#    כשהתותח יורה - המפקד מתכופף לרגע (DUCK_T).
#  לשנות: SHELL_CD, MG_CD, MG_N, BLAST, FIRST_ERR, MOVE_RESET.
# ============================================================

const E := preload("res://enemies/empire_kit.gd")

const SOUNDS := {
	"bh_cannon": {"drive": 1.8, "layers": [["N", 0, 0, 0.0, 0.7, 0.0, 4.0, 1.0, 0.12, 0], ["S", 70, 35, 0.0, 0.5, 0.0, 6.0, 0.8, 1.0, 0]]},
	"bh_turret": [["S", 90, 110, 0.0, 0.8, 0.1, 2.0, 0.15, 1.0, 0.02], ["N", 0, 0, 0.0, 0.8, 0.1, 2.0, 0.1, 0.3, 0, 0.6]],
	"bh_mg": [["N", 0, 0, 0.0, 0.06, 0.0, 45.0, 0.6, 0.7, 0, 0.4], ["S", 160, 80, 0.0, 0.05, 0.0, 45.0, 0.3, 1.0, 0]],
}

const SHELL_CD := 3.4
const MG_CD := 2.2
const MG_N := 6
const MG_V := 700.0
const BLAST := 90.0
const FIRST_ERR := 220.0
const MOVE_RESET := 160.0
const DUCK_T := 0.6

var shells := 0              # לבדיקות
var last_err := 0.0          # הטעות של הפגז האחרון (פיקסלים, + = ארוך)
var _shell_cd := 2.0
var _mg_cd := 1.0
var _left := 0
var _rate := 0.0
var _err := 0.0
var _last_x := INF
var _duck := 0.0
var _recoil := 0.0


func stats() -> Dictionary:
	return {"name": "BEHEMOTH", "hp": 380, "walk": 0.0, "chase": 0.0, "damage": 2, "bite_delay": 1.0, "scale": 2.4, "width": 1.8,
		"duck": 0.0, "cover": 0.0, "skin": Color("7a8670"), "shirt": E.UNIFORM, "pants": E.UNIFORM, "shoe": Color("1a1816"),
		"points": 2600, "boss": true, "boss_name": "THE BEHEMOTH - SHOOT THE COMMANDER IN THE HATCH"}


func setup() -> void:
	super.setup()
	z.add_to_group("empire")


func eye() -> Vector2:   # מקלע הגוף
	return z.global_position + Vector2(z._dir * 28.0 * z.wf, -16.0) * z.sc


func muzzle() -> Vector2:
	return z.global_position + Vector2(z._dir * 54.0 * z.wf, -31.0) * z.sc


func weak_rect() -> Rect2:
	return Rect2(-12, -58, 14, 14)


func on_damage(amount: int, hit_pos: Vector2, dir: Vector2, src: Dictionary) -> bool:
	if _duck > 0.0 and in_weak(hit_pos):   # המפקד בפנים
		Particles.burst(z.get_parent(), hit_pos, "spark", -dir, 3)
		return false
	return super.on_damage(amount, hit_pos, dir, src)


func think(pl: Node, delta: float) -> void:
	_shell_cd -= delta
	_mg_cd -= delta
	_rate -= delta
	_duck -= delta
	_recoil = maxf(_recoil - delta * 3.0, 0.0)
	if _left > 0:
		if _rate <= 0.0:
			_left -= 1
			_rate = 0.09
			fire_shot(eye(), aim_point(pl, MG_V) + Vector2(randf_range(-8, 8), randf_range(-8, 8)), MG_V, 1, "bolt", Color(1.0, 0.85, 0.4), 4.0)
			Sfx.play("bh_mg", eye(), -4.0, 0.1, 4)
		return
	var dx: float = absf(pl.global_position.x - z.global_position.x)
	if dx > 1250.0:
		return
	if _shell_cd <= 0.0 and dx > 180.0:
		wind("shell", 1.0)
		Sfx.play("bh_turret", z.global_position, 0.0, 0.05, 2)
		return
	if _mg_cd <= 0.0:
		wind("mg", 0.4)


func attack(name: String, pl: Node) -> void:
	match name:
		"pound":
			_duck = DUCK_T
			_recoil = 1.0
			Sfx.play("bh_cannon", muzzle(), 2.0, 0.05, 2)
			do_pound(pl)
		"mg":
			_mg_cd = MG_CD
			_left = MG_N
			_rate = 0.0
		"shell":
			_shell_cd = SHELL_CD
			shells += 1
			_duck = DUCK_T
			_recoil = 1.0
			# BRACKETING: טעות שמתחצה בכל פגז, כל עוד לא זזת הרבה
			var px: float = pl.global_position.x
			if _last_x == INF or absf(px - _last_x) > MOVE_RESET:
				_err = FIRST_ERR * (1.0 if randf() < 0.5 else -1.0)
				if _last_x != INF:
					z._popup("TARGET MOVED - NEW BRACKET", Color("ffd080"), 13, -60.0 - 70.0 * z.sc)
			else:
				_err = -_err * 0.5
				if absf(_err) < 40.0:
					z._popup("ON TARGET", Color("ff6040"), 15, -60.0 - 70.0 * z.sc)
			_last_x = px
			last_err = _err
			var tx: float = px + _err * z._dir
			Sfx.play("bh_cannon", muzzle(), 4.0, 0.05, 2)
			Particles.burst(z.get_parent(), muzzle(), "smoke", Vector2(z._dir, 0), 10)
			var cam: Camera2D = z.get_viewport().get_camera_2d()
			if cam != null and cam.has_method("shake"):
				cam.shake(7.0, 0.3)
			var flight := clampf(absf(tx - muzzle().x) / 700.0, 0.55, 1.5)
			fire_lob(muzzle(), Vector2(tx, pl.global_position.y), flight, 2, "shell", BLAST, Color(1.0, 0.6, 0.2), 7.0)


# ============================================================
#  ציור: זחלים עם גלגלים, גוף משופע, צריח עם הסמל, תותח ארוך (נרתע בירייה), מקלע גוף, צוהר עם מפקד ומשקפת,
#  אנטנה עם דגל אדום (בעולם)
# ============================================================
func draw() -> bool:
	begin_draw()
	var armor := col(Color("4a5040"))
	var dark := col(Color("2e3228"))
	var k := wind_k()
	# זחלים
	DrawBatch.colored_polygon(z, PackedVector2Array([Vector2(-36, -2), Vector2(36, -2), Vector2(40, -8), Vector2(36, -14), Vector2(-36, -14), Vector2(-40, -8)]), dark)
	for q in 7:
		var wx := -30.0 + float(q) * 10.0
		DrawBatch.circle(z, Vector2(wx, -7), 4.0, col(Color("1e201a")))
		DrawBatch.circle(z, Vector2(wx, -7), 1.5, col(Color("5a5e50")))
	for q in 18:   # חוליות הזחל
		var tx := -38.0 + fposmod(float(q) * 4.4 + z._time * 0.0, 78.0)
		DrawBatch.line(z, Vector2(tx, -2), Vector2(tx, -3.5), col(Color("0e0e0c")), 1.0)
	# גוף
	Art.fill_shaded(z, PackedVector2Array([Vector2(-38, -13), Vector2(34, -13), Vector2(42, -18), Vector2(30, -26), Vector2(-34, -26), Vector2(-40, -19)]), armor, 0.15, 0.4)
	DrawBatch.rect(z, Rect2(Vector2(24, -21), Vector2(6, 3)), col(Color("1a1a1a")))   # מקלע גוף
	DrawBatch.line(z, Vector2(30, -19.5), Vector2(36, -19.5), col(Color("1a1a1a")), 1.5)
	if _left > 0 and not z.dead:
		Art.glow(z, Vector2(37, -19.5), 4.0, Color(1.0, 0.8, 0.3, 0.8))
	for q in 4:   # ברגים / פלדות
		DrawBatch.circle(z, Vector2(-28.0 + float(q) * 16.0, -20), 0.9, col(Color("6a705e")))
	# צריח + תותח
	var rc := 4.0 * _recoil
	DrawBatch.rect(z, Rect2(Vector2(12.0 - rc, -33.5), Vector2(44, 4)), dark)   # הקנה
	DrawBatch.rect(z, Rect2(Vector2(52.0 - rc, -34.5), Vector2(6, 6)), dark)   # בולם לוע
	if winding == "shell" and not z.dead:
		Art.glow(z, Vector2(58.0 - rc, -31.5), 4.0 + 6.0 * k, Color(1.0, 0.6, 0.2, 0.25 + 0.4 * k))
	Art.fill_shaded(z, PackedVector2Array([Vector2(-20, -26), Vector2(16, -26), Vector2(18, -34), Vector2(8, -40), Vector2(-14, -40), Vector2(-22, -34)]), armor.lightened(0.04), 0.15, 0.4)
	E.emblem(z, Vector2(0, -32), 4.2, col(Color(0.9, 0.88, 0.82)))
	# צוהר + מפקד
	DrawBatch.rect(z, Rect2(Vector2(-11, -43), Vector2(10, 3)), dark)
	if _duck <= 0.0 and not z.dead:
		var head := Vector2(-6, -50)
		DrawBatch.rect(z, Rect2(head + Vector2(-4, 3), Vector2(8, 6)), col(E.UNIFORM_D))
		Art.oval_shaded(z, head, 4.0, 4.4, col(z.skin), 0.0)
		E.helmet(z, head + Vector2(0, 1.5), col(E.STEEL))
		DrawBatch.rect(z, Rect2(head + Vector2(1, -1), Vector2(5, 3)), col(Color("1a1a1a")))   # משקפת
		DrawBatch.circle(z, head + Vector2(6.5, 0.5), 1.2, Color(1.0, 0.3, 0.2))
	else:
		DrawBatch.rect(z, Rect2(Vector2(-12, -45), Vector2(12, 2)), dark)   # מכסה סגור
	# אנטנה
	DrawBatch.line(z, Vector2(-16, -40), Vector2(-20, -70), col(Color("2a2a2a")), 0.8)
	end_draw()
	if not z.dead:   # הדגל על האנטנה (בעולם)
		var tip: Vector2 = Vector2(z._dir * -20.0 * z.wf, -70.0) * z.sc
		E.flag(z, tip, 34.0, 22.0, z._time, 3)
	return true
