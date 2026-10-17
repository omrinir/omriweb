extends "res://enemies/zombie_type.gd"
# ============================================================
#  STRAGGLER (שלב 52, "RAIL YARD") - "המתעכב". בהשראת ה-stragglers של "Zone One" (קולסון וייטהד) - מתים שקפאו
#  באמצע השגרה של החיים הקודמים שלהם - ושל "המלאכים הבוכים" מדוקטור הו.
#  עובד רכבת / נוסע קפוא באמצע תנועה (POSES): פנס מורם, מסתכל בשעון כיס, מחזיק מזוודה, קורא עיתון, מטאטא. נוקשה כמו פסל,
#  עור אפור-אבן עם סדקים.
#  החוק: הוא זז רק כשאתה מסתכל לכיוון השני (הגב שלך אליו - player._face()). כשאתה מסתכל עליו - הוא קופא (אבק + חריקה),
#    בכל פעם בתנוחה חדשה ומאיימת יותר (ידיים מושטות, פה פתוח). כשלא רואים אותו הוא מהיר מאוד (chase) ומכה חזק (DMG).
#  אפשר לירות בו תמיד: הגוף נוקשה כמו אבן (x BODY_MULT), הראש = ראש רגיל. פיצוצים - נזק מלא.
#  רמזים: "קראק" + עין קטנה (BehindEye) מאחורי השחקן כשאחד מתחיל לזוז מאחוריך, ובפעם הראשונה: "THEY MOVE WHEN YOU LOOK AWAY".
#  "THEY LEARN": כשהסתכלת עליהם הרבה (main meta "st_stare" >= LEARN_STARE שניות) - הם מפסיקים להסתער לבד:
#    מתאספים מאחוריך (GATHER_D) ומחכים - וזזים רק כשאתה טוען (גם אם אתה מסתכל!) ("THEY WAIT FOR YOUR RELOAD").
#  לשנות: WAKE_R, SIGHT_R, REACH, STRIKE_T, DMG, CD, BODY_MULT, LEARN_STARE, GATHER_D.
# ============================================================

const SOUNDS := {
	"st_crack": [["N", 0, 0, 0.0, 0.08, 0.0, 40.0, 0.7, 0.6, 0, 0.3], ["S", 180, 90, 0.0, 0.07, 0.0, 40.0, 0.4, 1.0, 0], ["N", 0, 0, 0.06, 0.05, 0.0, 60.0, 0.4, 0.8, 0, 0.5]],
	"st_creak": [["S", 160, 120, 0.0, 0.3, 0.02, 6.0, 0.25, 0.7, 0.04], ["N", 0, 0, 0.0, 0.25, 0.02, 12.0, 0.25, 0.3, 0, 0.2]],
	"st_strike": [["N", 0, 0, 0.0, 0.14, 0.0, 26.0, 0.8, 0.4, 0], ["S", 120, 50, 0.0, 0.12, 0.0, 26.0, 0.6, 1.0, 0]],
}

const WAKE_R := 640.0           # השחקן קרוב מזה -> מתעורר מהשגרה (אם לא רואים אותו / ירו בו)
const SIGHT_R := 1100.0         # רחוק מזה - "לא רואים" אותו (גם אם פונים אליו)
const REACH := 44.0
const STRIKE_T := 0.2
const DMG := 2
const CD := 1.0
const BODY_MULT := 0.7
const LEARN_STARE := 14.0
const GATHER_D := 230.0
const POSES := ["lantern", "watch", "suitcase", "paper", "broom"]

enum { DORMANT, FROZEN, MOVING, STRIKE }
var state := DORMANT
var pose := "lantern"
var reach_pose := 0             # התנוחה המאיימת שבה הוא קפא (מתחלפת בכל קפיאה)
# לבדיקות
var moves := 0
var freezes := 0
var strikes := 0
var hits := 0
var learned_waits := 0
var _st := 0.0
var _cd := 0.0
var _hunting := false
var _stare := 0.0               # כמה זמן הסתכלו עליו (שלו)
var _dust := 0.0
var _creak_cd := 0.0
var _coat := Color("3a3a40")
var _hat := 0                   # 0 בלי, 1 כובע עובד, 2 מגבעת, 3 מטפחת


func stats() -> Dictionary:
	return {"name": "STRAGGLER", "hp": 48, "walk": 0.0, "chase": 300.0, "damage": DMG, "bite_delay": 0.7, "scale": 1.02, "width": 1.0,
		"duck": 0.0, "cover": 0.0, "skin": Color("9a9a90"), "shirt": Color("4a4a52"), "pants": Color("2e2e34"), "shoe": Color("1a1a1a"),
		"points": 420}


func use_brain_movement() -> bool:
	return false


func can_bite() -> bool:
	return false


func can_groan() -> bool:
	return false


func setup() -> void:
	var r := RandomNumberGenerator.new()
	r.seed = z.get_instance_id()
	pose = POSES[r.randi() % POSES.size()]
	reach_pose = r.randi() % 3
	match pose:
		"lantern":   # עובד רכבת: סרבל כחול, כובע
			_coat = Color("34486a")
			z.pants = Color("2a3450")
			_hat = 1
		"watch":     # נוסע בחליפה ומגבעת
			_coat = Color("3a3436")
			z.pants = Color("2a2628")
			_hat = 2
		"suitcase":  # אישה במעיל ומטפחת
			_coat = Color("6a3a3a")
			z.pants = Color("3a2a2a")
			_hat = 3
		"paper":
			_coat = Color("5a5444")
			z.pants = Color("3a362e")
			_hat = 2 if r.randf() < 0.5 else 0
		_:
			_coat = Color("4a5a3e")
			z.pants = Color("2e3428")
			_hat = 1
	_coat = Art.shade(_coat, r.randf_range(-0.12, 0.12))
	z.skin = Art.shade(Color("9a9a90"), r.randf_range(-0.1, 0.06))


func damage_mult(zone: String, src: Dictionary) -> float:
	var s := str(src.get("source", "bullet"))
	if zone == "head" or not (s == "bullet" or s == "melee"):
		return 1.0
	return BODY_MULT


func on_damage(_amount: int, hit_pos: Vector2, _dir: Vector2, _src: Dictionary) -> bool:
	if not _hunting:
		_hunting = true
	if state == FROZEN and Art.on_screen(z, z.global_position):   # אבק אבן מהפגיעה
		Particles.burst(z.get_parent(), hit_pos, "smoke", Vector2.UP, 1)
	return true


# האם השחקן "רואה" אותו: פונה אליו, לא רחוק מדי
func _seen(pl: Node) -> bool:
	var dx: float = z.global_position.x - pl.global_position.x
	if absf(dx) > SIGHT_R or absf(z.global_position.y - pl.global_position.y) > 320.0:
		return false
	if absf(dx) < 10.0:
		return true
	return signf(dx) == float(pl._face())


func _main() -> Node:
	return z.get_parent()


func _learned() -> bool:
	var m := _main()
	return m != null and float(m.get_meta("st_stare", 0.0)) >= LEARN_STARE


func physics(pl: Node, delta: float) -> bool:
	_st -= delta
	_cd -= delta
	_creak_cd -= delta
	_dust -= delta
	if not z.is_on_floor():
		z.velocity.y += z.gravity * delta
	if pl == null or pl.dead:
		_stop()
		return true
	var d: Vector2 = pl.global_position - z.global_position
	var seen := _seen(pl)
	var reloading: bool = pl.has_method("is_reloading") and pl.is_reloading()
	if state == DORMANT:
		# מתעורר: השחקן קרוב והוא לא מסתכל, או שירו בו
		if _hunting or (absf(d.x) < WAKE_R and absf(d.y) < 200.0 and not seen):
			_hunting = true
			state = FROZEN
		else:
			_stop()
			return true
	# מסתכלים עליו -> קפוא (חוץ מכשלמד והשחקן טוען)
	var learned := _learned()
	var may_move := not seen or (learned and reloading)
	if state == STRIKE:
		if seen and not (learned and reloading) and _st > STRIKE_T * 0.5:   # תפסת אותו באמצע - קופא
			_freeze()
			return true
		if _st <= STRIKE_T * 0.4 and _st + delta > STRIKE_T * 0.4:   # רגע הפגיעה
			if absf(d.x) < REACH * z.sc + 18.0 and absf(d.y) < 60.0 and pl._roll_t <= 0.0:
				hits += 1
				pl.hurt(DMG, Vector2(signf(d.x) * 1.4, -0.4))
		if _st <= 0.0:
			state = MOVING
			_cd = CD
		_stop()
		return true
	if not may_move:
		if state != FROZEN:
			_freeze()
		_stare += delta
		var m := _main()
		if m != null and absf(d.x) < 700.0:
			var was := float(m.get_meta("st_stare", 0.0))
			m.set_meta("st_stare", was + delta)
			if was < LEARN_STARE and was + delta >= LEARN_STARE and pl.has_method("_say"):
				pl._say("THEY WAIT FOR YOUR RELOAD", Color("c8d0e0"))
		_stop()
		return true
	# לא רואים אותו: זז
	if state != MOVING:
		state = MOVING
		moves += 1
		_on_unfreeze(pl, d)
	z._dir = signf(d.x) if absf(d.x) > 2.0 else z._dir
	var target_v := float(z.chase_speed) * signf(d.x)
	if learned and not reloading:
		# למד: מתאסף מאחוריך ומחכה לטעינה
		var gx: float = pl.global_position.x - float(pl._face()) * (GATHER_D + float(z.get_instance_id() % 5) * 26.0)
		var gd: float = gx - z.global_position.x
		if absf(d.x) < 110.0:   # כבר צמוד אליך - מכה בכל זאת
			pass
		elif absf(gd) < 14.0:
			learned_waits += 1
			_stop()
			return true
		else:
			target_v = float(z.chase_speed) * 0.8 * signf(gd)
	if absf(d.x) < REACH * z.sc and absf(d.y) < 50.0 and _cd <= 0.0:
		state = STRIKE
		_st = STRIKE_T
		strikes += 1
		Sfx.play("st_strike", z.global_position, -2.0, 0.1, 3)
		_stop()
		return true
	z.velocity.x = move_toward(z.velocity.x, target_v, 2600.0 * delta)
	if z.is_on_floor() and z.is_on_wall() and absf(z.velocity.x) < 30.0:   # מכשול: קופץ
		z.velocity.y = -520.0
	z._walk_phase += delta * 16.0
	z.move_and_slide()
	return true


func _stop() -> void:
	z.velocity.x = 0.0
	z.move_and_slide()


func _freeze() -> void:
	state = FROZEN
	freezes += 1
	reach_pose = (reach_pose + 1 + randi() % 2) % 3
	if Art.on_screen(z, z.global_position):
		if _dust <= 0.0:
			_dust = 0.25
			Particles.burst(z.get_parent(), z.global_position + Vector2(0, -4), "smoke", Vector2.UP, 2)
		if _creak_cd <= 0.0:
			_creak_cd = 0.6
			Sfx.play("st_creak", z.global_position, -6.0, 0.15, 2)


func _on_unfreeze(pl: Node, d: Vector2) -> void:
	# מאחוריך ולא רחוק: קראק + עין קטנה בצד הזה של השחקן
	if absf(d.x) < 760.0 and signf(-d.x) != float(pl._face()):
		Sfx.play("st_crack", z.global_position, 0.0, 0.15, 2)
		var e := BehindEye.new()
		e.side = signf(-d.x)
		pl.add_child(e)
		var m := _main()
		if m != null and not m.has_meta("st_told"):
			m.set_meta("st_told", true)
			if pl.has_method("_say"):
				pl._say("THEY MOVE WHEN YOU LOOK AWAY", Color("c8d0e0"))
			z._popup("DON'T TURN AWAY", Color("c8d0e0"), 14, -86.0)


# עין קטנה ליד השחקן, בצד שממנו משהו זז מאחוריו
class BehindEye extends Node2D:
	var side := -1.0
	var _t := 0.0

	func _ready() -> void:
		z_index = 20
		position = Vector2(side * 34.0, -78.0)

	func _process(delta: float) -> void:
		_t += delta
		if _t > 0.9:
			queue_free()
			return
		queue_redraw()

	func _draw() -> void:
		var a := clampf(1.0 - _t / 0.9, 0.0, 1.0) * clampf(_t * 8.0, 0.0, 1.0)
		var open := clampf(_t * 6.0, 0.0, 1.0)
		var w := 9.0
		var h := 5.0 * open
		draw_colored_polygon(PackedVector2Array([Vector2(-w, 0), Vector2(0, -h), Vector2(w, 0), Vector2(0, h)]), Color(0.92, 0.94, 1.0, 0.85 * a))
		draw_circle(Vector2(side * 2.0, 0), 2.6 * open, Color(0.12, 0.1, 0.14, a))
		draw_line(Vector2(-w - 2.0, 0), Vector2(w + 2.0, 0), Color(0.1, 0.1, 0.12, 0.6 * a), 1.0)
		draw_string(ThemeDB.fallback_font, Vector2(side * 14.0 - (8.0 if side < 0.0 else 0.0), 4.0), "<" if side < 0.0 else ">", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.92, 0.94, 1.0, a))


func wants_redraw() -> bool:
	return state == MOVING or state == STRIKE or z._flash > 0.0 or z.dead or Engine.get_physics_frames() % 12 == 0


# ============================================================
#  ציור: נוקשה כמו פסל. בשגרה (DORMANT) - תנוחת החיים הקודמים. בציד: קפוא בתנוחה מאיימת, או רץ קדימה בגוף נוקשה.
# ============================================================
func draw() -> bool:
	begin_draw()
	var sk := col(z.skin)
	var skd := col(Art.shade(z.skin, 0.25))
	var coat := col(_coat)
	var coat_d := col(Art.shade(_coat, 0.25))
	var pa := col(z.pants)
	var shoe := col(z.shoe)
	var hip := Vector2(0, -24)
	var sh := Vector2(1, -42)
	var fb := Vector2(-4, 0)
	var ff := Vector2(5, 0)
	var hb := sh + Vector2(-4, 18)     # יד אחורית
	var hf := sh + Vector2(5, 18)      # יד קדמית
	var head := sh + Vector2(2.5, -9.0)
	var lean := 0.0
	var prop := ""
	if state == DORMANT:
		prop = pose
		match pose:
			"lantern":
				hf = sh + Vector2(10, -12)
				head += Vector2(1, -1)
			"watch":
				hf = sh + Vector2(9, 8)
				hb = sh + Vector2(4, 10)
				head += Vector2(2, 2)
			"suitcase":
				hb = sh + Vector2(-5, 20)
				hf = sh + Vector2(6, 16)
			"paper":
				hf = sh + Vector2(11, 4)
				hb = sh + Vector2(8, 6)
				head += Vector2(1, 1)
			_:
				hf = sh + Vector2(9, 12)
				hb = sh + Vector2(3, 6)
				lean = 3.0
	elif state == MOVING or state == STRIKE:
		var p: float = z._walk_phase
		lean = 7.0
		ff = Vector2(sin(p) * 9.0 + 2.0, -maxf(0.0, cos(p)) * 4.0)
		fb = Vector2(sin(p + PI) * 9.0 - 1.0, -maxf(0.0, cos(p + PI)) * 4.0)
		hf = sh + Vector2(16 + lean, -2)
		hb = sh + Vector2(12 + lean, 2)
		if state == STRIKE:
			hf = sh + Vector2(22 + lean, -6)
			hb = sh + Vector2(18 + lean, 0)
		head += Vector2(lean, 2)
	else:   # קפוא בתנוחה מאיימת
		match reach_pose:
			0:   # שתי ידיים מושטות
				hf = sh + Vector2(17, -1)
				hb = sh + Vector2(14, 2)
				lean = 4.0
				ff = Vector2(10, 0)
				fb = Vector2(-7, 0)
			1:   # יד מורמת לתפוס, השנייה למטה
				hf = sh + Vector2(13, -14)
				hb = sh + Vector2(6, 16)
				lean = 2.0
				ff = Vector2(8, 0)
			_:   # מתכופף קדימה, ראש מוטה
				hf = sh + Vector2(15, 8)
				hb = sh + Vector2(10, 10)
				lean = 6.0
				head += Vector2(2, 3)
				fb = Vector2(-8, 0)
		head += Vector2(lean, 0)
	sh.x += lean
	hf.x += 0.0
	# רגל אחורית, יד אחורית
	z._leg(hip + Vector2(-3, 0), fb, col(Art.shade(z.pants, 0.25)), skd, shoe)
	if prop == "suitcase":   # המזוודה ביד האחורית
		Art.fill_shaded(z, PackedVector2Array([hb + Vector2(-9, 1), hb + Vector2(9, 1), hb + Vector2(9, 14), hb + Vector2(-9, 14)]), col(Color("6a4a2a")), 0.15, 0.3)
		z.draw_line(hb + Vector2(-9, 7), hb + Vector2(9, 7), col(Color("3a2a18")), 1.2)
	z._arm(sh + Vector2(-3, 2), hb, skd, coat_d)
	# גוף: מעיל / סרבל
	var body := PackedVector2Array([sh + Vector2(-8, -1), sh + Vector2(8, 0), hip + Vector2(8, 4), hip + Vector2(-8, 4)])
	Art.fill_shaded(z, body, coat, 0.14, 0.34)
	z.draw_line(sh + Vector2(0, 1), hip + Vector2(0.5, 3), col(Art.shade(_coat, 0.45)), 1.0)
	if pose == "lantern":   # כתפיות סרבל
		z.draw_line(sh + Vector2(-5, 0), hip + Vector2(-4, -6), col(Color("2a3a5a")), 1.6)
		z.draw_line(sh + Vector2(5, 0), hip + Vector2(4, -6), col(Color("2a3a5a")), 1.6)
	# סדקים באבן (על הגוף והעור)
	z.draw_polyline(PackedVector2Array([sh + Vector2(-4, 4), sh + Vector2(-2, 8), sh + Vector2(-5, 12)]), Color(0.1, 0.1, 0.1, 0.5), 0.8)
	z._leg(hip + Vector2(3, 0), ff, pa, sk, shoe)
	# ראש
	z._head(head, sk)
	face(head, Vector2(3.5, -0.5) if state != DORMANT else Vector2(INF, 0))
	z.draw_polyline(PackedVector2Array([head + Vector2(-5, -5), head + Vector2(-2, -1), head + Vector2(-4, 3)]), Color(0.08, 0.08, 0.08, 0.55), 0.8)
	match _hat:
		1:   # כובע עובד עם מצחייה
			Art.fill(z, PackedVector2Array([head + Vector2(-7, -4), head + Vector2(6, -5), head + Vector2(6, -9), head + Vector2(-6, -9)]), col(Color("2a3450")), Art.OUTLINE, 1.0)
			z.draw_line(head + Vector2(5, -5), head + Vector2(11, -4), col(Color("1a1e2a")), 2.0)
		2:   # מגבעת
			Art.fill(z, PackedVector2Array([head + Vector2(-5, -6), head + Vector2(5, -6), head + Vector2(4, -13), head + Vector2(-4, -13)]), col(Color("1e1c1e")), Art.OUTLINE, 1.0)
			z.draw_line(head + Vector2(-9, -6), head + Vector2(9, -6), col(Color("1e1c1e")), 2.0)
		3:   # מטפחת
			Art.fill(z, PackedVector2Array([head + Vector2(-7, 2), head + Vector2(-7, -6), head + Vector2(0, -9), head + Vector2(6, -6), head + Vector2(4, -3), head + Vector2(-3, -3), head + Vector2(-4, 4)]), col(Color("8a6a4a")), Art.OUTLINE, 1.0)
	# עיניים: בשגרה עצומות (קו). בציד - שתי נקודות לבנות-קרות
	if not z.dead:
		if state == DORMANT:
			z.draw_line(head + Vector2(2.5, -1.0), head + Vector2(5.5, -1.2), Color(0.1, 0.1, 0.1, 0.8), 1.0)
		else:
			z.draw_circle(head + Vector2(4.0, -1.2), 1.3, Color(0.85, 0.92, 1.0))
			Art.glow(z, head + Vector2(4.0, -1.2), 4.0, Color(0.7, 0.85, 1.0, 0.45))
	# יד קדמית + חפץ
	z._arm(sh + Vector2(3, 2), hf, sk, coat)
	match prop:
		"lantern":   # פנס רכבת עם אור עמום
			z.draw_line(hf, hf + Vector2(0, 5), col(Color("2a2a2a")), 1.2)
			Art.fill(z, PackedVector2Array([hf + Vector2(-3, 5), hf + Vector2(3, 5), hf + Vector2(3, 13), hf + Vector2(-3, 13)]), col(Color("3a3a3a")), Art.OUTLINE, 1.0)
			z.draw_rect(Rect2(hf + Vector2(-2, 7), Vector2(4, 4)), Color(1.0, 0.45, 0.2, 0.85))
			Art.glow(z, hf + Vector2(0, 9), 9.0, Color(1.0, 0.45, 0.2, 0.35))
		"watch":   # שעון כיס פתוח עם שרשרת
			z.draw_circle(hf + Vector2(2, -1), 2.6, col(Color("c8b060")))
			z.draw_circle(hf + Vector2(2, -1), 1.8, Color(0.95, 0.92, 0.8))
			z.draw_line(hf + Vector2(2, -1), hf + Vector2(2, -2.4), Color(0.1, 0.1, 0.1), 0.6)
			z.draw_polyline(PackedVector2Array([hf + Vector2(0, 0), hip + Vector2(4, -8), hip + Vector2(2, -6)]), col(Color("c8b060")), 0.8)
		"paper":   # עיתון פתוח
			var pp := PackedVector2Array([hf + Vector2(-8, -8), hf + Vector2(4, -10), hf + Vector2(5, 6), hf + Vector2(-7, 8)])
			Art.fill(z, pp, col(Color("d8d2c0")), Art.OUTLINE, 1.0)
			for q in 4:
				z.draw_line(hf + Vector2(-5, -6 + q * 3.5), hf + Vector2(2, -7 + q * 3.5), Color(0.3, 0.3, 0.3, 0.6), 0.8)
		"broom":   # מטאטא
			z.draw_line(hf + Vector2(-4, -10), hf + Vector2(10, 22), col(Color("6a4a2a")), 2.0)
			Art.fill(z, PackedVector2Array([hf + Vector2(6, 20), hf + Vector2(15, 18), hf + Vector2(18, 26), hf + Vector2(7, 27)]), col(Color("b89a5a")), Art.OUTLINE, 1.0)
	if state == MOVING and not z.dead:   # קווי מהירות (תנועה קופצנית)
		for q in 3:
			z.draw_line(Vector2(-14.0 - float(q) * 4.0, -50.0 + float(q) * 14.0), Vector2(-26.0 - float(q) * 6.0, -50.0 + float(q) * 14.0), Color(0.85, 0.9, 1.0, 0.35), 1.2)
	end_draw()
	return true
