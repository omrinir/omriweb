extends "res://enemies/zombie_type.gd"
# ============================================================
#  EVOLVED (שלב 9) - נדיר מאוד. מהיר, חכם, וקורא את ההרגלים שלך (PlayerMemory).
#    הבוס של השלב (stats "boss": true) - ועוד אחד "בורח" במעבדה התת-קרקעית.
#  צללית: גבוה ודק, רגליים הפוכות (כמו של חיה), ידיים ארוכות עם 3 טפרים,
#    גולגולת מוארכת עם מוח חשוף שפועם, כתר של קוצי עצם, 3 עיניים תכלת,
#    מערכת עצבים זוהרת לאורך הגוף. כשהוא מהיר - משאיר "רוחות" מאחוריו.
#  תנועה: רץ מהר, קפיצות-קיר (נוגע בקיר באוויר -> בועט ממנו למעלה), התחמקויות
#    (כשמכוונים אליו / יורים עליו - קופץ הצידה), הטעיות (מסתער פנימה, ונסוג רגע לפני הנשיכה).
#  התקפה: טפרים (נזק 1). מלמעלה: צלילה (2 נזק) עם צווחה כאזהרה.
#  קורא אותך (כל 1.2 שנ', מראה "READ: ..." מעל הראש):
#    "מחנה" במקום אחד            -> ABOVE: קפיצת-על מעליך וצלילה מלמעלה
#    תמיד בורח לאותו צד            -> CUTOFF: קופץ מעליך ונעמד בצד שאליו אתה בורח
#    משתמש כמעט רק בשוטגאן         -> שומר מרחק וזורק עליך גושי בטון
#    מרסס (SMG / רובה סער)          -> מחכה מחוץ לטווח, מתחמק, ומסתער כשאתה טוען
#    צלף / אקדח                     -> מסתער בקפיצות זיגזג (קשה לפגוע בראש)
#    רימונים / משגר                -> נצמד אליך (אי אפשר לירות רימון מטווח אפס)
#  חיים: 110 (הבוס: 300). הקושי מהתנועה ומהחוכמה, לא מחיים ענקיים.
#  צלילים: "evo_chitter" (קליקים + קול גבוה), "evo_shriek" (צלילה), "evo_learn" (צליל "למידה"),
#    "evo_kick" (בעיטה בקיר), "evo_rock" (גוש בטון).
#  איך משנים: DODGE_CHANCE, הסדר ב-analyze(), GUARD_HP / BASE_HP.
# ============================================================

const Hz := preload("res://environment/s9_hazards.gd")
const Brain := preload("res://ai/zombie_brain.gd")

const SOUNDS := {
	"evo_chitter": [["C", 0, 0, 0.0, 0.4, 0.0, 4.0, 0.8, 1.0, 0], ["V", 520, 720, 0.0, 0.32, 0.01, 6.0, 0.55, 1.0, 0.1, 0, [1200, 2600, 120]]],
	"evo_shriek": {"drive": 2.6, "layers": [["V", 700, 1150, 0.0, 0.6, 0.02, 3.0, 0.9, 1.0, 0.06, 0, [1400, 3000, 30]], ["S", 2200, 3400, 0.0, 0.5, 0.0, 4.0, 0.12, 1.0, 0.02]]},
	"evo_learn": {"rev": 0.4, "layers": [["S", 1320, 660, 0.0, 0.9, 0.02, 2.5, 0.22, 1.0, 0.01], ["S", 1980, 990, 0.05, 0.9, 0.02, 2.5, 0.13, 1.0, 0.01], ["S", 440, 220, 0.0, 1.0, 0.1, 2.0, 0.2, 1.0, 0.03]]},
	"evo_kick": [["N", 0, 0, 0.0, 0.08, 0.0, 60.0, 0.6, 0.5, 0], ["S", 210, 90, 0.0, 0.08, 0.0, 40.0, 0.45, 1.0, 0]],
	"evo_rock": [["N", 0, 0, 0.0, 0.2, 0.0, 18.0, 0.8, 0.3, 0], ["S", 140, 60, 0.0, 0.15, 0.0, 20.0, 0.6, 1.0, 0]],
}

enum { GROUND, AIR, DIVE, PLUNGE }
const DODGE_CHANCE := 0.55
const BASE_HP := 110
const GUARD_HP := 300
const LABELS := {"ABOVE": "READ: YOU CAMP", "COUNTER_SHOTGUN": "READ: SHOTGUN", "COUNTER_AUTO": "READ: SPRAY",
	"COUNTER_PRECISION": "READ: AIMING", "COUNTER_EXPLOSIVE": "READ: EXPLOSIVES"}

var tactic := "PRESS"
var reads := []            # כל מה ש"למד" (לבדיקות)
var guardian := false      # הבוס שליד היציאה
var dives := 0
var throws := 0
var dodges := 0
var wall_kicks := 0
var feints := 0
var vaults := 0
var _air := GROUND
var _air_t := 0.0
var _analyze_t := 0.4
var _hold := 0.0
var _dodge_cd := 0.0
var _wj_cd := 0.0
var _feint_t := 0.0
var _feint_phase := 0
var _feint_cd := 2.0
var _throw_cd := 1.2
var _throw_anim := 0.0
var _dive_cd := 1.5
var _prep := 0.0
var _vault_cd := 0.0
var _hop_t := 0.0
var _shots_seen := 0
var _aim_t := 0.0
var _fire_recent := 0.0
var _learn_fx := 0.0
var _chitter_t := 2.0


func stats() -> Dictionary:
	return {"name": "EVOLVED", "boss": true, "boss_name": "THE EVOLVED", "hp": BASE_HP, "walk": 95.0, "chase": 205.0, "damage": 1, "bite_delay": 0.6,
		"scale": 1.12, "width": 0.85, "duck": 0.0, "cover": 0.0, "skin": Color("98a2ae"), "shirt": Color("2a3440"), "pants": Color("1e242c"),
		"shoe": Color(0, 0, 0, 0), "points": 1500}


func brain_overrides() -> Dictionary:
	return {"awareness": 0.3, "aggression": 0.2, "hazard_awareness": 0.3}


func use_brain_movement() -> bool:
	return false


func setup() -> void:
	var m: Node = z.get_parent()
	if m != null and "level_w" in m:
		guardian = float(z.position.x) > float(m.level_w) - 800.0
	var hp := GUARD_HP if guardian else BASE_HP
	z.hp = hp
	z.max_hp = hp
	_shots_seen = PlayerMemory.shots_total


# ---- קריאת השחקן: מה ההרגל הכי בולט? ----
func analyze() -> String:
	if PlayerMemory.is_camping() or PlayerMemory.camping > 0.4:
		return "ABOVE"
	if absf(PlayerMemory.retreat_dir) > 0.3:
		return "CUTOFF"
	var best := ""
	var bv := 0.5
	for k in PlayerMemory.weapon_use:
		var v: float = PlayerMemory.weapon_use[k]
		if v > bv and k != "other":
			bv = v
			best = k
	if best != "":
		return "COUNTER_" + str(best).to_upper()
	return "PRESS"


func _learn(t: String) -> void:
	reads.append(t)
	_learn_fx = 1.2
	var label: String = LABELS.get(t, "")
	if t == "CUTOFF":
		label = "READ: YOU RUN " + ("LEFT" if PlayerMemory.retreat_dir < 0.0 else "RIGHT")
	if label != "":
		z._popup(label, Color(0.5, 0.95, 1.0), 15, -112.0)
	Sfx.play("evo_learn", z.global_position, 0.0, 0.05, 2)


func logic(pl: Node, d: Vector2, delta: float, speed: float) -> float:
	_dodge_cd -= delta
	_feint_cd -= delta
	_throw_cd -= delta
	_throw_anim -= delta
	_dive_cd -= delta
	_vault_cd -= delta
	_hop_t -= delta
	_hold -= delta
	_fire_recent -= delta
	_learn_fx -= delta
	_chitter_t -= delta
	if _chitter_t <= 0.0:
		_chitter_t = randf_range(3.0, 6.0)
		Sfx.play("evo_chitter", z.global_position, -6.0, 0.15, 2)
	_analyze_t -= delta
	if _analyze_t <= 0.0:
		_analyze_t = 1.2
		var t2 := analyze()
		if t2 != tactic and (_hold <= 0.0 or t2 != "PRESS"):
			tactic = t2
			_hold = 4.0
			if t2 != "PRESS":
				_learn(t2)
	var dist := absf(d.x)
	var toward: float = signf(d.x) if d.x != 0.0 else z._dir
	z._dir = toward
	if _check_dodge(pl, delta, toward):
		return 0.0
	if _prep > 0.0:   # מתכופף לפני קפיצת-על (אזהרה)
		_prep -= delta
		if _prep <= 0.0:
			_start_dive(pl)
		return 0.0
	var vul: bool = pl.is_vulnerable()
	match tactic:
		"ABOVE":
			if dist < 300.0 and _dive_cd <= 0.0 and z.is_on_floor():
				_prep = 0.3
				Sfx.play("evo_chitter", z.global_position, 0.0, 0.1, 2)
				return 0.0
			return speed * 1.1
		"CUTOFF":
			var escape := signf(PlayerMemory.retreat_dir)
			if signf(z.global_position.x - pl.global_position.x) != escape:
				if dist < 170.0 and z.is_on_floor() and _vault_cd <= 0.0:
					_vault(dist, toward)
					return 0.0
				return speed * 1.25
			return _approach(dist, speed, delta, toward)
		"COUNTER_SHOTGUN":
			if vul:
				return speed * 1.4
			if dist < 230.0:
				z._dir = -toward
				return speed
			if dist > 380.0:
				return speed * 0.9
			if _throw_cd <= 0.0 and z.is_on_floor():
				_throw(pl)
			return 0.0
		"COUNTER_AUTO":
			if vul:
				return speed * 1.5
			if dist < 280.0 and _fire_recent > 0.0:   # מחכה מחוץ לטווח עד שהמחסנית נגמרת
				z._dir = -toward
				return speed * 0.8
			return speed * (0.5 + 0.8 * absf(sin(z._time * 4.0)))
		"COUNTER_PRECISION":
			if z.is_on_floor() and _hop_t <= 0.0 and dist > 70.0:
				_hop_t = randf_range(0.45, 0.7)
				z.velocity.y = -380.0
			return speed * 1.2
		"COUNTER_EXPLOSIVE":
			return speed * 1.35
	return _approach(dist, speed, delta, toward)


# התקרבות עם הטעיות: מסתער פנימה ונסוג רגע לפני הנשיכה
func _approach(dist: float, speed: float, delta: float, toward: float) -> float:
	if _feint_t > 0.0:
		_feint_t -= delta
		if _feint_phase == 0:
			if _feint_t <= 0.0:
				_feint_phase = 1
				_feint_t = 0.35
			return speed * 1.7
		z._dir = -toward
		if _feint_t <= 0.0:
			_feint_cd = randf_range(3.0, 4.5)
		return speed * 1.3
	if dist < 210.0 and dist > 120.0 and _feint_cd <= 0.0 and z.is_on_floor():
		_feint_t = 0.25
		_feint_phase = 0
		feints += 1
		return speed * 1.7
	return speed


# מתחמק: כשיורים עליו / מכוונים אליו הרבה זמן
func _check_dodge(pl: Node, delta: float, toward: float) -> bool:
	var fired := PlayerMemory.shots_total != _shots_seen
	_shots_seen = PlayerMemory.shots_total
	if fired:
		_fire_recent = 0.8
	var to: Vector2 = z.global_position - pl.global_position
	var aim: Vector2 = pl._aim
	var aimed: bool = to.length() < 700.0 and aim.dot(to.normalized()) > 0.95
	_aim_t = _aim_t + delta if aimed else 0.0
	if _dodge_cd > 0.0 or not z.is_on_floor():
		return false
	if (fired and aimed) or _aim_t > 0.7:
		_aim_t = 0.0
		var ch := DODGE_CHANCE + (0.3 if tactic == "COUNTER_AUTO" or tactic == "COUNTER_PRECISION" else 0.0)
		if randf() < ch:
			_dodge_cd = 1.1
			dodges += 1
			var side := -toward if randf() < 0.5 else toward
			_jump(Vector2(side * 280.0, -440.0))
			Sfx.play("evo_kick", z.global_position, -4.0, 0.2, 2)
			return true
		_dodge_cd = 0.5
	return false


func _jump(v: Vector2) -> void:
	_air = AIR
	_air_t = 0.0
	z.velocity = v
	if v.x != 0.0:
		z._dir = signf(v.x)


func _vault(dist: float, toward: float) -> void:
	vaults += 1
	_vault_cd = 2.0
	var air: float = 2.0 * 700.0 / z.gravity
	_jump(Vector2(toward * clampf((dist + 150.0) / air, 200.0, 440.0), -700.0))
	Sfx.play("evo_chitter", z.global_position, -2.0, 0.1, 2)


func _start_dive(pl: Node) -> void:
	dives += 1
	_air = DIVE
	_air_t = 0.0
	var dx: float = pl.global_position.x - z.global_position.x
	z.velocity = Vector2(clampf(dx * 1.4, -360.0, 360.0), -900.0)
	Sfx.play("evo_kick", z.global_position, 0.0, 0.1, 2)


func _throw(pl: Node) -> void:
	throws += 1
	_throw_cd = randf_range(1.8, 2.4)
	_throw_anim = 0.4
	var from: Vector2 = z.global_position + Vector2(z._dir * 10.0, -50.0 * z.sc)
	var target: Vector2 = pl.global_position + Vector2(0, -26)
	var t := clampf(absf(target.x - from.x) / 520.0, 0.45, 0.9)
	var r := Hz.RubbleShot.new()
	r.gravity = 1000.0
	r.velocity = Vector2((target.x - from.x) / t, (target.y - from.y - 0.5 * 1000.0 * t * t) / t)
	z.get_parent().add_child(r)
	r.global_position = from
	Sfx.play("evo_chitter", z.global_position, -3.0, 0.1, 2)


# ---- תנועה באוויר: קפיצות, בעיטות-קיר, צלילה ----
func physics(pl: Node, delta: float) -> bool:
	_wj_cd -= delta
	if _air == GROUND:
		# קפץ מעל מכשול (zombie.gd) ונתקע בקיר: בועט למעלה
		if not z.is_on_floor() and z.is_on_wall() and _wj_cd <= 0.0 and z._chasing:
			_wall_kick(true)
			return true
		return false
	_air_t += delta
	if pl == null or pl.dead:
		_air = AIR
	match _air:
		AIR:
			z.velocity.y += z.gravity * delta
		DIVE:
			z.velocity.y += z.gravity * delta
			var dx: float = pl.global_position.x - z.global_position.x
			z.velocity.x = move_toward(z.velocity.x, clampf(dx * 3.0, -340.0, 340.0), 900.0 * delta)
			z._dir = signf(dx) if dx != 0.0 else z._dir
			var above: bool = z.global_position.y < pl.global_position.y - 90.0
			if (absf(dx) < 40.0 and above and z.velocity.y > -250.0) or (z.velocity.y > 0.0 and _air_t > 0.35):
				_air = PLUNGE
				z.velocity = Vector2(0.0, 980.0)
				Sfx.play("evo_shriek", z.global_position, 2.0, 0.08, 2)
		PLUNGE:
			z.velocity = Vector2(0.0, 980.0)
	z.move_and_slide()
	z._walk_phase += delta * 6.0
	if _air != PLUNGE and z.is_on_wall() and not z.is_on_floor() and _wj_cd <= 0.0:
		_wall_kick(false)
	if z.is_on_floor() and _air_t > 0.08:
		if _air == PLUNGE:
			_dive_cd = 3.5
			Particles.burst(z.get_parent(), z.global_position, "smoke", Vector2.UP, 10)
			Sfx.play("evo_rock", z.global_position, 2.0, 0.1, 2)
			var dd: Vector2 = pl.global_position - z.global_position
			if absf(dd.x) < 52.0 and absf(dd.y) < 70.0:
				z._attack_t = z.bite_delay
				z._bite_anim = 0.3
				pl.hurt(2, Vector2(signf(dd.x) if dd.x != 0.0 else 1.0, 0.0))
			var cam: Camera2D = z.get_viewport().get_camera_2d()
			if cam != null and cam.has_method("shake"):
				cam.shake(8.0, 0.25)
		_air = GROUND
	return true


# בעיטה בקיר: למעלה (מטפס מעל מכשול) או החוצה מהקיר (בזמן קפיצה)
func _wall_kick(up: bool) -> void:
	_wj_cd = 0.4
	wall_kicks += 1
	var n: Vector2 = z.get_wall_normal()
	_air = AIR
	_air_t = 0.0
	if up:
		z.velocity = Vector2(-n.x * 150.0, -640.0)
	else:
		z.velocity = Vector2(n.x * 300.0, -620.0)
		z._dir = signf(n.x) if n.x != 0.0 else z._dir
	Particles.burst(z.get_parent(), z.global_position + Vector2(-n.x * 8.0, -30.0), "smoke", n, 4)
	Sfx.play("evo_kick", z.global_position, -2.0, 0.15, 2)


func on_death() -> void:
	z._popup("IT STOPPED LEARNING", Color(0.5, 0.95, 1.0), 18, -120.0)
	if guardian:
		z._drop(3)   # BOOST
		z._drop(3)
		z._drop(2)   # SUPPLY
		z.get_tree().call_group("level_exit", "on_boss_dead")


# ============================================================
#  ציור
# ============================================================
func draw() -> bool:
	begin_draw()
	var sk := col(z.skin)
	var dark := col(Art.shade(z.skin, 0.3))
	var cyan := Color(0.45, 0.95, 1.0) if not z.dead else Color(0.3, 0.4, 0.45)
	var p: float = z._walk_phase
	var pulse := 0.6 + 0.4 * sin(z._time * 5.0)
	var air: bool = (_air != GROUND or not z.is_on_floor()) and not z.dead
	var hip := Vector2(-1.0, -29.0 + absf(sin(p)) * 1.2)
	var sh := Vector2(3.0, -47.0)
	if _prep > 0.0 and not z.dead:   # מתכופף לפני קפיצה
		hip.y += 5.0
		sh += Vector2(3.0, 7.0)
	var head := sh + Vector2(5.0, -7.0)
	# "רוחות" מאחור כשהוא מהיר
	var fast: bool = absf(float(z.velocity.x)) > 230.0 or air
	if fast:
		for k in 2:
			var o := Vector2(-9.0 * float(k + 1), 2.0 * float(k + 1) if air else 0.0)
			Art.fill(z, PackedVector2Array([sh + o + Vector2(-5, -1), sh + o + Vector2(5, 0), hip + o + Vector2(4, 0), hip + o + Vector2(-4, 0)]), Color(0.45, 0.9, 1.0, 0.16 - 0.06 * float(k)), Art.NONE)
			z.draw_circle(head + o, 6.0, Color(0.45, 0.9, 1.0, 0.12 - 0.05 * float(k)))
	# רגליים הפוכות (כמו של חיה)
	var stride := 7.0
	var f0 := Vector2(sin(p) * stride + 2.0, -maxf(0.0, cos(p)) * 4.0)
	var f1 := Vector2(sin(p + PI) * stride, -maxf(0.0, cos(p + PI)) * 4.0)
	if air:
		f0 = Vector2(6, -10)
		f1 = Vector2(-6, -6)
	_dleg(hip + Vector2(-1, 0), f1, dark)
	# יד אחורית ארוכה
	var bh := sh + Vector2(-2.0 + sin(p) * 4.0, 22.0)
	_claw_arm(sh + Vector2(-2, 1), bh, dark, Vector2(0.4, 1.0))
	_dleg(hip + Vector2(1, 0), f0, sk)
	# גוף דק עם צלעות ומערכת עצבים זוהרת
	var body := PackedVector2Array([sh + Vector2(-7, -2), sh + Vector2(7, -1), sh.lerp(hip, 0.35) + Vector2(8, 0), hip + Vector2(4, 0), hip + Vector2(-4, 1), sh.lerp(hip, 0.5) + Vector2(-7, 0)])
	Art.fill_shaded(z, body, sk, 0.2, 0.35, Art.OUTLINE, 1.3)
	for i in 4:
		var rp := sh.lerp(hip, 0.25 + float(i) * 0.15)
		z.draw_line(rp + Vector2(-1, 0), rp + Vector2(5, 1), col(Color(0.35, 0.38, 0.45, 0.8)), 0.8, true)
	z.draw_polyline(PackedVector2Array([head + Vector2(-3, 3), sh + Vector2(-3, 2), sh.lerp(hip, 0.5) + Vector2(-2.5, 0), hip + Vector2(-2, -1)]), Color(cyan, 0.5 + 0.4 * pulse), 1.2, true)
	z.draw_line(sh.lerp(hip, 0.3) + Vector2(-2, 0), sh.lerp(hip, 0.45) + Vector2(4, 1), Color(cyan, 0.4 * pulse), 0.8, true)
	z.draw_line(sh.lerp(hip, 0.6) + Vector2(-2, 0), sh.lerp(hip, 0.75) + Vector2(3, 2), Color(cyan, 0.4 * pulse), 0.8, true)
	# ראש: גולגולת מוארכת אחורה, מוח חשוף, כתר קוצים, 3 עיניים
	Art.limb(z, PackedVector2Array([sh + Vector2(1, 0), head + Vector2(-2, 4)]), 3.6, dark)
	for i in 4:   # קוצי עצם
		var sp := head + Vector2(-4.0 - float(i) * 2.0, -5.0 + float(i) * 1.6)
		Art.fill(z, PackedVector2Array([sp, sp + Vector2(-6.0 - float(i), -4.0 + float(i) * 1.2), sp + Vector2(1.5, 1.5)]), col(Color("dcd6c4")), Art.OUTLINE, 0.8)
	Art.oval_shaded(z, head + Vector2(-2, -2), 6.0, 8.5, sk, -0.7, Art.OUTLINE, 1.3)
	var brain_c := head + Vector2(-4, -6)
	Art.oval(z, brain_c, 4.5, 3.6, col(Color("c890b0")), -0.6, Art.OUTLINE, 1.0)
	z.draw_line(brain_c + Vector2(-3, 0), brain_c + Vector2(3, -1), col(Color("9a5a80")), 0.7, true)
	Art.glow(z, brain_c, 6.0 + 2.0 * pulse, Color(cyan, 0.35 * pulse))
	Art.fill(z, PackedVector2Array([head + Vector2(1.5, 3.5), head + Vector2(6.5, 2.5), head + Vector2(6.0, 5.5 + (2.0 if z._bite_anim > 0.0 else 0.0)), head + Vector2(2.0, 6.0)]), col(Color("1a0c14")), Art.OUTLINE, 0.8)
	for e in [Vector2(3.5, -3.5), Vector2(4.6, -1.2), Vector2(3.6, 1.0)]:
		Art.glow(z, head + e, 3.0, Color(cyan, 0.7))
		z.draw_circle(head + e, 0.9, cyan.lightened(0.4))
	# יד קדמית עם 3 טפרים ארוכים (מורמת בזריקה / צלילה)
	var fh := sh + Vector2(13.0, 12.0 - sin(p) * 3.0)
	if _throw_anim > 0.0 and not z.dead:
		fh = sh + Vector2(4.0, -16.0)
	elif _air == PLUNGE and not z.dead:
		fh = sh + Vector2(10.0, 18.0)
	elif z._bite_anim > 0.0:
		fh = sh + Vector2(19.0, 4.0)
	_claw_arm(sh + Vector2(2, 1), fh, sk, (fh - sh).normalized())
	# הילת "למידה"
	if _learn_fx > 0.0 and not z.dead:
		var k := 1.0 - _learn_fx / 1.2
		z.draw_arc(head + Vector2(-2, -3), 8.0 + k * 22.0, 0.0, TAU, 24, Color(cyan, 0.8 * (1.0 - k)), 1.5, true)
		z.draw_arc(head + Vector2(-2, -3), 4.0 + k * 12.0, 0.0, TAU, 18, Color(cyan, 0.5 * (1.0 - k)), 1.0, true)
	end_draw()
	return true


# רגל הפוכה: ירך -> ברך קדימה -> קרסול גבוה מאחור -> כף עם טפרים
func _dleg(hip: Vector2, foot: Vector2, c: Color) -> void:
	var ankle := foot + Vector2(-5.0, -7.0)
	var knee := hip.lerp(ankle, 0.5) + Vector2(6.0, -1.0)
	Art.limb(z, PackedVector2Array([hip, knee]), 6.0, c)
	Art.limb(z, PackedVector2Array([knee, ankle]), 4.0, c)
	Art.limb(z, PackedVector2Array([ankle, foot + Vector2(2.0, 0.0)]), 2.8, c)
	for i in 2:
		z.draw_line(foot + Vector2(2, 0), foot + Vector2(6.0, -1.0 + float(i) * 1.5), col(Color("2a2a30")), 1.0, true)


func _claw_arm(shoulder: Vector2, hand: Vector2, c: Color, dirv: Vector2) -> void:
	var elbow := Art.joint(shoulder, hand, 11.0, 12.0, -1.0)
	Art.limb(z, PackedVector2Array([shoulder, elbow, hand]), 4.0, c)
	var dv := dirv.normalized() if dirv.length() > 0.01 else Vector2.RIGHT
	for i in 3:
		var a := dv.rotated(-0.35 + float(i) * 0.35)
		z.draw_line(hand, hand + a * 7.5, col(Color("e8e4d8")), 1.2, true)
