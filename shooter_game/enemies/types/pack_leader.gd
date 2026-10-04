extends "res://enemies/zombie_type.gd"
# ============================================================
#  PACK LEADER (שלב 6) - "המנהל". לא חזק במיוחד - הכוח שלו הוא התיאום.
#  צללית: גבוה וזקוף (כולם כפופים - הוא לא), חליפה קרועה עם עניבה אדומה,
#         "כתר" של קוצי עצם שבוקעים מהגולגולת, יד מורמת כשהוא נותן פקודה.
#  צבעים: חליפת פחם, עניבה אדומה, פסי "צבע מלחמה" כתומים על הפנים והיד, עיניים כתומות.
#  תנועה: לא מסתער. נשאר מאחורי הלהקה (~300 מהשחקן), צועד זקוף, נסוג כשמתקרבים אליו.
#  התנהגות (היררכיה):
#    * setup: director().register_leader(z, RADIUS, BONUS) - כל זומבי בטווח מקבל בונוס
#      תיאום/תוקפנות (ai/zombie_brain.gd -> leader_boost).
#    * כל COMMAND_EVERY שניות: מרים יד, מיילל ונותן פקודה (director.command -> טקסט מעליו):
#        השחקן פגיע (טוען / נתפס) -> "ATTACK" מיד
#        יש 3+ חברים -> "FLANK" ואחריו "ATTACK" (מכמה כיוונים)
#        אחרת -> "HOLD" (מתאספים) ואחריו "ATTACK" (כולם ביחד)
#      בזמן הפקודה נמתחים "חוטים" כתומים ממנו לכל מי שקיבל אותה.
#    * כשהוא מת - ה-director מבלבל את כל מי שהיה בטווח ("?") לכמה שניות.
#  צלילים: "leader_howl" (יללה מהדהדת), "leader_death" (יבבה יורדת)
# ============================================================

const SOUNDS := {
	"leader_howl": {"rev": 0.3, "drive": 2.5, "layers": [["V", 150, 260, 0.0, 0.45, 0.05, 1.5, 0.85, 1.0, 0.04, 0, [600, 1150, 22]], ["V", 260, 170, 0.45, 0.55, 0.0, 3.0, 0.8, 1.0, 0.05, 0, [650, 1200, 26]], ["S", 75, 70, 0.0, 0.9, 0.1, 2.5, 0.3, 1.0, 0]]},
	"leader_death": {"drive": 2.4, "layers": [["V", 240, 70, 0.0, 1.2, 0.02, 1.8, 0.85, 1.0, 0.07, 0, [700, 1100, 30]], ["N", 0, 0, 0.0, 0.8, 0.05, 3.0, 0.2, 0.3, 0]]},
}

const RADIUS := 440.0
const BONUS := 0.35
const COMMAND_EVERY := Vector2(5.5, 7.5)
const KEEP := 300.0

var _cmd_t := 3.0
var _follow_cmd := ""        # הפקודה השנייה ברצף (ATTACK אחרי HOLD/FLANK)
var _follow_t := 0.0
var _arm := 0.0
var _since := 0.0            # כמה זמן עבר מהפקודה האחרונה
var _threads := []           # [zombie] שקיבלו את הפקודה האחרונה (לציור)
var _thread_t := 0.0
var commands := []           # לבדיקות: רשימת הפקודות שנתן


func stats() -> Dictionary:
	return {"name": "PACK LEADER", "hp": 40, "walk": 42.0, "chase": 92.0, "damage": 1, "bite_delay": 0.9, "scale": 1.1, "width": 0.95,
		"duck": 0.2, "cover": 0.3, "skin": Color("8e9a7e"), "shirt": Color("2e3034"), "pants": Color("26282c"), "shoe": Color("101012"), "points": 400}


func brain_overrides() -> Dictionary:
	return {"keep_range": KEEP, "aggression": -0.25, "communication": 1}


func use_brain_movement() -> bool:
	return false


func setup() -> void:
	var dr := director()
	if dr != null:
		dr.register_leader(z, RADIUS, BONUS)


func logic(pl: Node, d: Vector2, delta: float, speed: float) -> float:
	_cmd_t -= delta
	_follow_t -= delta
	_arm -= delta
	_thread_t -= delta
	_since += delta
	var dist := absf(d.x)
	var face: float = signf(d.x) if d.x != 0.0 else z._dir
	var br = z.brain
	# פקודה שנייה ברצף
	if _follow_cmd != "" and _follow_t <= 0.0:
		_issue(_follow_cmd, 2.5)
		_follow_cmd = ""
	# פקודה חדשה כשהוא יודע איפה השחקן
	if _cmd_t <= 0.0 and br != null and br.tracking() and dist < 700.0:
		_cmd_t = randf_range(COMMAND_EVERY.x, COMMAND_EVERY.y)
		var n := _followers().size()
		if n > 0:
			if pl.is_vulnerable():
				_issue("ATTACK", 2.5)
			elif n >= 3 and randf() < 0.6:
				_issue("FLANK", 3.0)
				_follow_cmd = "ATTACK"
				_follow_t = 2.2
			else:
				_issue("HOLD", 1.8)
				_follow_cmd = "ATTACK"
				_follow_t = 1.8
		else:
			_cmd_t = 1.5
	# השחקן טוען ממש עכשיו: מנצל את הרגע (פעם ב-2.5 שניות לכל היותר)
	if pl.is_reloading() and _since > 2.5 and _follow_cmd == "" and _followers().size() > 0:
		_cmd_t = randf_range(COMMAND_EVERY.x, COMMAND_EVERY.y)
		_follow_cmd = ""
		_issue("ATTACK", 2.5)
	# תנועה: נשאר מאחורי הלהקה
	z._dir = face
	if br != null and br.confused_t > 0.0:
		return speed * 0.3
	if absf(d.y) > 90.0 and br != null:   # השחקן בקומה אחרת: עולה / יורד אליו
		br._heights(z, pl, d)
	if dist < KEEP - 110.0:
		z._dir = -face   # נסוג
		return speed * 0.9
	if dist > KEEP + 90.0:
		return speed * 0.75
	return 0.0


func _followers() -> Array:
	var out := []
	for o in z.get_tree().get_nodes_in_group("zombies"):
		if o != z and not o.dead and o.brain != null and o.brain.steer_movement and o.global_position.distance_to(z.global_position) < RADIUS:
			out.append(o)
	return out


func _issue(cmd: String, secs: float) -> void:
	var dr := director()
	if dr == null:
		return
	_threads = _followers()
	dr.command(z, cmd, RADIUS, secs)
	commands.append(cmd)
	_since = 0.0
	_arm = 0.9
	_thread_t = 0.8
	Sfx.play("leader_howl", z.global_position, 1.0, 0.06, 2)


func on_damage(_amount: int, _hit_pos: Vector2, _dir: Vector2, _src: Dictionary) -> bool:
	# נפגע: מסמן ללהקה לתקוף מיד (אם לא נתן פקודה הרגע)
	if _since > 2.0 and _cmd_t > 1.0 and z.hp > 12:
		_cmd_t = randf_range(COMMAND_EVERY.x, COMMAND_EVERY.y)
		_follow_cmd = ""
		_issue("ATTACK", 2.0)
	return true


func on_death() -> void:
	Sfx.play("leader_death", z.global_position, 2.0)


# ---- ציור: זקוף, חליפה + עניבה אדומה, כתר עצמות, יד מורמת בפקודה ----
func draw() -> bool:
	# "חוטים" ממנו לכל מי שקיבל פקודה (לפני הטרנספורם - בקואורדינטות של הזומבי)
	if _thread_t > 0.0 and not z.dead:
		var a := clampf(_thread_t / 0.8, 0.0, 1.0)
		var from := Vector2(0.0, -70.0 * z.sc)
		for o in _threads:
			if is_instance_valid(o) and not o.dead:
				var to: Vector2 = z.to_local(o.global_position) + Vector2(0.0, -50.0 * o.sc)
				var mid := from.lerp(to, 0.5) + Vector2(0.0, -30.0)
				var pts := PackedVector2Array()
				for i in 9:
					var u := float(i) / 8.0
					pts.append(from.lerp(mid, u).lerp(mid.lerp(to, u), u))
				z.draw_polyline(pts, Color(1.0, 0.6, 0.2, 0.55 * a), 1.5, true)
				z.draw_circle(to, 3.0, Color(1.0, 0.7, 0.3, 0.7 * a))
	if not z.dead:   # הילה חלשה על הריצפה: טווח ההשפעה
		var pulse := 0.5 + 0.5 * sin(z._time * 2.0)
		var ring := Art.ellipse(Vector2.ZERO, 24.0 * z.sc, 5.0 * z.sc, 0.0, 22)
		ring.append(ring[0])
		z.draw_polyline(ring, Color(1.0, 0.55, 0.2, 0.2 + 0.15 * pulse), 1.6, true)
	begin_draw()
	var sk := col(z.skin)
	var sk_d := col(Art.shade(z.skin, 0.3))
	var suit := col(z.shirt)
	var suit_d := col(Art.shade(z.shirt, 0.35))
	var paint := col(Color("ff8a2a"))
	var p: float = z._walk_phase
	var f: Array = feet(6.0, 3.0)
	var hip := Vector2(0.0, -24.0 + absf(sin(p)) * 1.0)
	var sh := Vector2(1.0, -45.0)   # זקוף
	var head := sh + Vector2(2.0, -9.0)
	var cmd: bool = _arm > 0.0 and not z.dead
	z._leg(hip + Vector2(-2, 0), f[1], col(Art.shade(z.pants, 0.3)), sk_d, col(z.shoe))
	z._arm(sh + Vector2(-3, 1), sh + Vector2(-2 - sin(p) * 3.0, 20), sk_d, suit_d)
	z._leg(hip + Vector2(2, 0), f[0], col(z.pants), sk, col(z.shoe))
	# ז'קט קרוע + חולצה לבנה + עניבה אדומה
	var jacket := PackedVector2Array([hip + Vector2(-7, 3), hip + Vector2(7, 3), sh + Vector2(7, 0), sh + Vector2(4, -3), sh + Vector2(-6, -3), sh + Vector2(-8, 1)])
	Art.fill_shaded(z, jacket, suit, 0.15, 0.35)
	Art.fill(z, PackedVector2Array([sh + Vector2(0, -2), sh + Vector2(5, -2), hip + Vector2(4, -4), hip + Vector2(1, -6)]), col(Color("c8c4b4")), Art.NONE)
	Art.fill(z, PackedVector2Array([sh + Vector2(2, -2), sh + Vector2(4, -2), sh.lerp(hip, 0.55) + Vector2(4, 0), sh.lerp(hip, 0.62) + Vector2(2.5, 1), sh.lerp(hip, 0.55) + Vector2(1.5, 0)]), col(Color("b01818")), Art.OUTLINE, 0.8)
	for i in 3:   # קרעים בז'קט
		var tp: Vector2 = hip.lerp(sh, 0.15 + float(i) * 0.2) + Vector2(-6, 0)
		z.draw_line(tp, tp + Vector2(-2, 3), suit_d, 1.2)
	# ראש + כתר קוצי עצם
	Art.oval_shaded(z, head, 6.5, 7.5, sk, 0.0)
	for i in 4:
		var a := -2.45 + float(i) * 0.42
		var base := head + Vector2.from_angle(a) * 5.5
		var tip := head + Vector2.from_angle(a) * (11.0 + float(i % 2) * 3.5)
		Art.fill(z, PackedVector2Array([base + Vector2.from_angle(a + 1.57) * 2.0, tip, base - Vector2.from_angle(a + 1.57) * 2.0]), col(Color("ece4cc")), Color(0.15, 0.12, 0.1, 0.8), 0.6)
	# צבע מלחמה כתום על הפנים + עיניים כתומות
	z.draw_line(head + Vector2(-1, -1), head + Vector2(6, 0), paint, 1.4)
	z.draw_line(head + Vector2(0, 2), head + Vector2(5, 3), paint, 1.0)
	var eye := Color(1.0, 0.6, 0.15)
	Art.glow(z, head + Vector2(3.5, -2.0), 4.5 if cmd else 3.0, Color(eye, 0.75 if cmd else 0.5))
	z.draw_circle(head + Vector2(3.5, -2.0), 1.1, eye)
	var jaw := 2.0 + (5.0 if cmd else sin(z._time * 2.0))
	Art.fill(z, PackedVector2Array([head + Vector2(1, 3), head + Vector2(6.5, 2.5), head + Vector2(6, 4.0 + jaw), head + Vector2(1.5, 4.5 + jaw * 0.6)]), Color("2a0a0c"), Art.OUTLINE, 0.9)
	# יד קדמית: מורמת ומצביעה בזמן פקודה
	var hand := sh + (Vector2(10, -22) if cmd else Vector2(8, 18 + sin(p) * 2.0))
	z._arm(sh + Vector2(3, 1), hand, sk, suit)
	z.draw_line(hand + Vector2(-2, 1), hand + Vector2(3, -1), paint, 1.2)
	if cmd:
		Art.glow(z, hand, 8.0, Color(1.0, 0.6, 0.2, 0.5 * clampf(_arm / 0.9, 0.0, 1.0)))
	end_draw()
	return true
