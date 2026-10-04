extends "res://enemies/zombie_type.gd"
# ============================================================
#  AMBUSHER (שלב 7) - מתחבא בחושך ותוקף מאחור.
#  צללית: מכווץ על ארבע כמו עכביש כשהוא מחכה (ברזנט שמנוני על הראש והגב),
#         כשהוא קופץ - גבוה ורזה, ידיים ארוכות עם ציפורני וו, הברזנט מתנופף מאחוריו.
#  צבעים: עור שחור-שמנוני עם ברק כחלחל, ברזנט ירוק-כהה, עיניים לבנות-קרות זעירות.
#  התנהגות (ai/zombie_brain.gd -> AMBUSH): לא תוקף מיד. כורע ומחכה בשקט
#    (כמעט בלתי נראה - מעומעם, ולרוב בתוך "כיס חושך" של השלב). כשהשחקן עובר אותו
#    הוא מזנק עליו מאחור (קפיצה + צווחה), שורט, ואז נסוג חזרה לחושך ומחכה שוב.
#  הוגנות: נשימה שקטה ("amb_breath") ושתי נקודות עיניים חלשות מסגירות אותו.
#  צלילים: "amb_breath" (נשימה לחה ואיטית), "amb_spring" (צווחה עולה כשהוא קופץ).
# ============================================================

const SOUNDS := {
	"amb_breath": {"drive": 1.6, "layers": [["N", 0, 0, 0.0, 0.9, 0.35, 2.5, 0.35, 0.08, 0, 0.02], ["V", 70, 62, 0.0, 0.9, 0.3, 2.8, 0.25, 1.0, 0.02, 0, [300, 700, 9]], ["N", 0, 0, 1.0, 0.7, 0.25, 3.2, 0.25, 0.06, 0, 0.02]]},
	"amb_spring": {"drive": 2.8, "layers": [["V", 260, 720, 0.0, 0.45, 0.01, 4.0, 0.9, 1.0, 0.07, 0, [900, 2300, 60]], ["N", 0, 0, 0.0, 0.3, 0.0, 9.0, 0.5, 0.6, 0, 0.25], ["S", 3100, 2600, 0.02, 0.2, 0.0, 14.0, 0.12, 1.0, 0]]},
}

const Brain := preload("res://ai/zombie_brain.gd")

var _hide := 1.0          # 1 = מוסתר (מעומעם), 0 = חשוף
var _was_hidden := true
var _breath_t := 2.0
var _rehide_t := -1.0
var _lunge := 0.0
var _close_t := 0.0       # כמה זמן השחקן עומד ממש לידו (בלי לעבור אותו)
var _forced := false      # נפגע -> מזנק מיד
var springs := 0          # לבדיקות: כמה פעמים זינק


func stats() -> Dictionary:
	return {"name": "AMBUSHER", "hp": 26, "walk": 40.0, "chase": 165.0, "damage": 1, "bite_delay": 0.65, "scale": 0.95, "width": 0.85,
		"duck": 0.0, "cover": 0.0, "skin": Color("2a2c30"), "shirt": Color("1e2a26"), "pants": Color("141618"), "shoe": Color(0, 0, 0, 0), "points": 260}


func brain_overrides() -> Dictionary:
	return {"ambusher": true, "flank_probability": -0.4, "retreat_probability": 0.2}


func setup() -> void:
	# שקט: לא צורח כשהוא רואה אותך ולא נאנק (זה כל העניין במארב)
	z._noticed = true
	z._close_yell = true
	z._groan_t = 9999.0
	z.cover_chance = 0.0
	# אם יש כיס חושך קרוב - מתמקם בו
	var best_x := INF
	for d in z.get_tree().get_nodes_in_group("s7_dark"):
		var dx: float = d.global_position.x - z.global_position.x
		if absf(dx) < 360.0 and absf(dx) < absf(best_x) and absf(d.global_position.y - z.global_position.y) < 30.0:
			best_x = dx
	if best_x < INF:
		z.position.x += best_x + randf_range(-14.0, 14.0)


func _hidden() -> bool:
	return z.brain != null and z.brain.role == Brain.AMBUSH


# מחכה במקום גם כשהשחקן רחוק (לא מסתובב סתם)
func physics(pl: Node, delta: float) -> bool:
	var hid := _hidden()
	_hide = move_toward(_hide, 1.0 if hid else 0.0, delta * (1.2 if hid else 5.0))
	z._groan_t = 9999.0
	if hid:
		z._voice_cd = 1.0   # בלי צרחות שמסגירות אותו (יש לו צליל זינוק משלו)
		_breath_t -= delta
		if _breath_t <= 0.0:
			_breath_t = randf_range(4.0, 6.5)
			if Art.on_screen(z, z.global_position, 0.0):
				Sfx.play("amb_breath", z.global_position, -9.0, 0.1, 2)
	# חוזר לחושך אחרי מכה
	if _rehide_t > 0.0:
		_rehide_t -= delta
		if _rehide_t <= 0.0 and z.brain != null and not hid:
			var far: bool = pl == null or absf(pl.global_position.x - z.global_position.x) > 150.0
			if far:
				z.brain.role = Brain.AMBUSH
				z.brain._ambush_side = 0.0
				var dr := director()
				if dr != null:
					dr.release_slot(z)
			else:
				_rehide_t = 0.5
	if hid and not z._chasing and z.is_on_floor():
		z.velocity.x = 0.0
		z.velocity.y += z.gravity * delta
		z.move_and_slide()
		z._duck_t = 0.3
		return true
	return false


func logic(pl: Node, d: Vector2, delta: float, speed: float) -> float:
	_lunge -= delta
	var hid := _hidden()
	var dist := absf(d.x)
	_close_t = _close_t + delta if (_was_hidden and dist < 44.0 and absf(d.y) < 60.0) else 0.0
	if _was_hidden and not hid and z.brain.role == Brain.ATTACK:
		# המוח רצה לזנק כי השחקן קרוב - אבל הוא עוד לא עבר אותו: ממשיך לחכות בשקט
		var side := signf(pl.global_position.x - z.global_position.x)
		var amb_side: float = z.brain._ambush_side
		var passed: bool = amb_side != 0.0 and side != amb_side
		if not passed and not _forced and _close_t < 1.0:
			z.brain.role = Brain.AMBUSH
			hid = true
	if _was_hidden and not hid and z.brain.role == Brain.ATTACK:
		# זינוק מהחושך אל גב השחקן
		_forced = false
		springs += 1
		_lunge = 0.5
		z._dir = signf(d.x) if d.x != 0.0 else z._dir
		if z.is_on_floor():
			z.velocity = Vector2(z._dir * 360.0, -330.0)
		Sfx.play("amb_spring", z.global_position, 3.0, 0.08, 2)
		if Art.on_screen(z, z.global_position):
			Particles.burst(z.get_parent(), z.global_position + Vector2(0, -10), "smoke", Vector2.UP, 5)
	_was_hidden = hid
	if hid:
		return 0.0
	return speed


func on_bite(_pl: Node) -> void:
	# שורט ונסוג בחזרה לחושך
	if z.brain != null:
		z.brain._set_role(z, Brain.RETREAT, 1.4)
	_rehide_t = 1.6


func on_damage(_amount: int, _hit_pos: Vector2, _dir: Vector2, _src: Dictionary) -> bool:
	# נפגע בזמן שהוא מחכה: נחשף ותוקף מיד
	if _hidden() and z.brain != null:
		_forced = true
		z.brain._set_role(z, Brain.ATTACK, 0.0)
		z.brain._burst_t = 1.2
	_rehide_t = -1.0
	return true


func draw() -> bool:
	begin_draw()
	var hk := _hide if not z.dead else 0.0
	var dark := Color(0.02, 0.02, 0.03)
	var sk := col(z.skin.lerp(dark, 0.7 * hk))
	var skd := col(Art.shade(z.skin, 0.3).lerp(dark, 0.7 * hk))
	var tarp := col(z.shirt.lerp(dark, 0.7 * hk))
	var claw := col(Color("b8b4a8").lerp(dark, 0.75 * hk))
	var p: float = z._walk_phase
	var t: float = z._time
	var sheen := Color(0.45, 0.6, 0.75, 0.3 * (1.0 - hk))
	# כמה הוא מכווץ: 1 = על ארבע (מחבוא), 0 = עומד
	var crouch := clampf(hk * 1.2, 0.0, 1.0)
	if not z.is_on_floor() and not z.dead:
		crouch = 0.15
	var f: Array = feet(7.0, 3.0)
	var hip := Vector2(-3.0, lerpf(-24.0, -12.0, crouch))
	var sh := Vector2(lerpf(6.0, 12.0, crouch), lerpf(-40.0, -18.0, crouch))
	var head := sh + Vector2(lerpf(6.0, 9.0, crouch), lerpf(-7.0, -2.0, crouch))
	# ברזנט שמתנופף מאחור
	var flap := sin(t * 6.0) * 3.0 * (1.0 - hk) + sin(t * 1.2) * 1.0
	var cape := PackedVector2Array([head + Vector2(-6, -6), sh + Vector2(-2, -4), hip + Vector2(-6, -2), hip + Vector2(-16 - flap, 6), hip + Vector2(-10, 10), hip + Vector2(-4, 4)])
	Art.fill_shaded(z, cape, tarp, 0.1, 0.4)
	# רגליים (מקופלות כשהוא כורע)
	var bf: Vector2 = f[1]
	var ff: Vector2 = f[0]
	if crouch > 0.5:
		bf = Vector2(-10, 0)
		ff = Vector2(2, 0)
	z._leg(hip + Vector2(-1, 0), bf, skd, skd, Color(0, 0, 0, 0))
	# יד אחורית
	var reach := 1.0 if z._bite_anim > 0.0 or _lunge > 0.0 else 0.0
	var bh := sh + Vector2(lerpf(10.0, 6.0, crouch) + reach * 8.0, lerpf(14.0, 18.0, crouch) + sin(p) * 3.0)
	if crouch > 0.5:
		bh = Vector2(sh.x + 8.0, -1.0)
	Art.limb(z, PackedVector2Array([sh, sh.lerp(bh, 0.5) + Vector2(-3, 3), bh]), 3.2, skd)
	_hooks(bh, claw)
	z._leg(hip + Vector2(1, 0), ff, sk, sk, Color(0, 0, 0, 0))
	# גוף צנום
	Art.fill_shaded(z, PackedVector2Array([hip + Vector2(-5, 3), hip + Vector2(5, 2), sh + Vector2(5, 3), sh + Vector2(-4, -3)]), sk, 0.15, 0.4)
	z.draw_line(hip + Vector2(-2, -1), sh + Vector2(-1, 0), sheen, 1.2)   # ברק שמן
	# ראש מכוסה בברזנט, רק העיניים בולטות
	Art.oval_shaded(z, head, 6.0, 6.0, sk, 0.0)
	var hood := PackedVector2Array([head + Vector2(-8, 3), head + Vector2(-7, -6), head + Vector2(0, -9), head + Vector2(7, -5), head + Vector2(6, -2), head + Vector2(-1, -3), head + Vector2(-2, 6)])
	Art.fill_shaded(z, hood, tarp, 0.15, 0.4)
	var eye := Color(0.85, 0.92, 1.0)
	var ea := 0.55 if hk > 0.5 else 1.0
	for e in [Vector2(3.0, 0.0), Vector2(5.5, 0.5)]:
		var ep: Vector2 = head + e
		Art.glow(z, ep, 2.5 + 2.5 * (1.0 - hk), Color(eye, 0.5 * ea))
		z.draw_circle(ep, 0.8, Color(eye, ea))
	if hk < 0.5:   # פה פעור כשהוא תוקף
		Art.fill(z, PackedVector2Array([head + Vector2(2, 3), head + Vector2(7, 2.5), head + Vector2(6, 6 + reach * 2.0), head + Vector2(2.5, 5)]), Color("1a0606"), Art.OUTLINE, 0.8)
	# יד קדמית ארוכה עם ווים
	var fh := sh + Vector2(lerpf(16.0, 10.0, crouch) + reach * 10.0, lerpf(8.0, 18.0, crouch) - sin(p) * 3.0)
	if crouch > 0.5:
		fh = Vector2(sh.x + 16.0, -1.0)
	if reach > 0.0 and crouch < 0.5:
		fh = sh + Vector2(22, -4)
	Art.limb(z, PackedVector2Array([sh + Vector2(2, 1), sh.lerp(fh, 0.5) + Vector2(1, 4), fh]), 3.4, sk)
	_hooks(fh, claw)
	end_draw()
	return true


func _hooks(at: Vector2, c: Color) -> void:
	for i in 3:
		var a := -0.6 + float(i) * 0.5
		var tip := at + Vector2.from_angle(a) * 6.0
		z.draw_line(at, tip, c, 1.1, true)
		z.draw_line(tip, tip + Vector2.from_angle(a + 1.9) * 2.5, c, 1.0, true)
