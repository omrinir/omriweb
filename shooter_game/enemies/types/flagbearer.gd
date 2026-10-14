extends "res://enemies/zombie_type.gd"
# ============================================================
#  FLAGBEARER (משלב 40, "HARBOR OF WAR") - נושא הדגל של אימפריית המתים: דגל אדום ענק עם הסמל על תורן גבוה.
#  "THEY LEARNED TO BELIEVE": כל חייל של האימפריה בטווח AURA_R מהדגל לא נשבר - מקבל רק x0.6 נזק (zombie.gd, meta "morale_t").
#    ירייה בתורן / בדגל (מעל הראש) -> הדגל נופל: ההגנה נעלמת והחיילים סביבו נשברים ("broken"). גם כשהוא מת - הדגל נופל.
#  מכה עם הדגל (כל עוד הדגל מורם):
#    CHOP   - מניף את התורן אחורה (אזהרה) ומנחית אותו מלמעלה לפניו (CHOP_REACH). מתחמקים: צעד אחורה, מחוץ לטווח.
#    THRUST - מוריד את התורן כמו חנית ודוקר בגובה החזה עם זינוק קדימה (THRUST_REACH). מתחמקים: קפיצה / התכופפות.
#    "THEY LEARN YOUR DODGE": נסוגת מה-CHOP -> המכה הבאה THRUST (ארוכה). קפצת / התכופפת מה-THRUST -> חוזר ל-CHOP (תופס קופצים).
#    פגע בך -> ממשיך עם אותה מכה.
#  לשנות: AURA_R, POLE_H, FLAG_HP, CHOP_REACH, THRUST_REACH, WIND_T, STRIKE_T, RECOVER_T, ATTACK_CD.
# ============================================================

const E := preload("res://enemies/empire_kit.gd")

const SOUNDS := {
	"fb_snap": [["C", 0, 0, 0.0, 0.06, 0.0, 50.0, 0.6, 1.0, 0], ["N", 0, 0, 0.0, 0.3, 0.0, 8.0, 0.3, 0.4, 0, 0.6]],
	"fb_swish": [["N", 0, 0, 0.0, 0.22, 0.02, 9.0, 0.55, 0.5, 0, 0.45], ["S", 500, 180, 0.0, 0.2, 0.0, 10.0, 0.12, 1.0, 0]],
	"fb_thud": [["S", 130, 55, 0.0, 0.16, 0.0, 22.0, 0.8, 1.0, 0], ["N", 0, 0, 0.0, 0.08, 0.0, 35.0, 0.45, 0.3, 0, 0.6]],
	"fb_horn": {"drive": 1.3, "layers": [["S", 220, 230, 0.0, 0.8, 0.1, 1.5, 0.3, 1.0, 0.03], ["S", 330, 340, 0.0, 0.8, 0.1, 1.5, 0.15, 1.0, 0.03]]},
}

const AURA_R := 260.0
const POLE_H := 96.0
const FLAG_HP := 2
const CHOP_REACH := 108.0       # מכמה רחוק (מהרגליים) מתחיל CHOP
const THRUST_REACH := 150.0     # ... ו-THRUST (עם הזינוק)
const WIND_T := 0.5             # אזהרה (התורן נמשך אחורה / יורד לחנית)
const STRIKE_T := 0.16
const RECOVER_T := 0.42
const ATTACK_CD := 1.5
const LUNGE_V := 300.0
const CHOP_PIVOT := Vector2(6, -40)     # הידיים על התורן (מקומי, לפני היפוך)
const THRUST_PIVOT := Vector2(8, -44)   # גובה חזה: עובר מעל שחקן מתכופף (34) ופוגע בעומד (52)
const POLE_LEN := 92.0

enum { IDLE, WIND, STRIKE, RECOVER }
var standing := true         # הדגל מורם
var flag_hp := FLAG_HP
var state := IDLE
var move := "chop"           # המכה הנוכחית / הבאה
var chops := 0               # לבדיקות
var thrusts := 0
var flag_hits := 0
var learned_back := 0
var learned_jump := 0
var _tick := 0.0
var _fall := 0.0
var _st := 0.0
var _cd := 1.0
var _hit := false


func stats() -> Dictionary:
	return {"name": "FLAGBEARER", "hp": 36, "walk": 36.0, "chase": 58.0, "damage": 1, "bite_delay": 1.0, "scale": 1.05, "width": 1.0,
		"duck": 0.0, "cover": 0.1, "skin": Color("7a8670"), "shirt": E.UNIFORM, "pants": E.UNIFORM, "shoe": Color("1a1816"), "points": 520}


func setup() -> void:
	z.add_to_group("empire")


func brain_overrides() -> Dictionary:
	return {"aggression": 0.45}


func can_bite() -> bool:
	return not standing


func flag_top() -> Vector2:
	return z.global_position + Vector2(z._dir * 8.0, -POLE_H) * z.sc


func on_damage(amount: int, hit_pos: Vector2, _dir: Vector2, src: Dictionary) -> bool:
	if standing and (hit_pos.y - z.global_position.y) / z.sc < -58.0:   # התורן / הדגל
		flag_hp -= 1
		Particles.burst(z.get_parent(), hit_pos, "leaf", Vector2.UP, 3)
		if flag_hp <= 0:
			_drop_flag()
		return false
	return true


func _drop_flag() -> void:
	if not standing:
		return
	standing = false
	_fall = 0.0
	Sfx.play("fb_snap", z.global_position, 0.0, 0.1, 2)
	z._popup("THE FLAG IS DOWN!", Color("ffe0a0"), 15, -80.0)
	for o in z.get_tree().get_nodes_in_group("empire"):   # ההגנה נעלמת מיד
		if o.has_meta("morale_t"):
			o.remove_meta("morale_t")
	E.order(z, "broken", AURA_R)


func on_death() -> void:
	E.leader_down(z.get_parent())
	_drop_flag()


func physics(pl: Node, delta: float) -> bool:
	_tick -= delta
	_fall += delta
	_st -= delta
	_cd -= delta
	if standing and not z.dead and _tick <= 0.0:
		_tick = 0.25
		for o in z.get_tree().get_nodes_in_group("empire"):
			if not o.dead and o.global_position.distance_to(z.global_position) < AURA_R:
				o.set_meta("morale_t", float(o._time) + 0.4)
	if z.dead or not standing or pl == null or pl.dead or z.goal_x < INF:
		state = IDLE
		return false
	if state != IDLE:   # התנופה צריכה להיראות חלקה (לא לפי קצב הציור המופחת של ההמון)
		z.queue_redraw()
	var d: Vector2 = pl.global_position - z.global_position
	match state:
		WIND:
			if _st <= 0.0:
				state = STRIKE
				_st = STRIKE_T
				_hit = false
				Sfx.play("fb_swish", z.global_position, 0.0, 0.1, 3)
			return _stay(delta)
		STRIKE:
			if move == "thrust":   # זינוק קדימה עם החנית
				z.velocity.x = z._dir * LUNGE_V
				if not z.is_on_floor():
					z.velocity.y += z.gravity * delta
				z.move_and_slide()
			else:
				_stay(delta)
			if not _hit and _pole_hits(pl):
				_hit = true
				flag_hits += 1
				pl.hurt(1, Vector2(z._dir * 1.6, -0.7))
				Sfx.play("fb_thud", pl.global_position, 0.0, 0.1, 3)
			if _st <= 0.0:
				state = RECOVER
				_st = RECOVER_T
				if not _hit:
					_learn(pl, d)
			return true
		RECOVER:
			if _st <= 0.0:
				state = IDLE
				_cd = ATTACK_CD
			return _stay(delta)
	var reach := CHOP_REACH if move == "chop" else THRUST_REACH
	if _cd <= 0.0 and absf(d.x) < reach * z.sc and absf(d.y) < 70.0:
		z._dir = signf(d.x) if absf(d.x) > 4.0 else z._dir
		state = WIND
		_st = WIND_T * (0.85 if move == "thrust" else 1.0)
		if move == "chop":
			chops += 1
		else:
			thrusts += 1
		return _stay(delta)
	return false


func _stay(delta: float) -> bool:
	z.velocity.x = move_toward(z.velocity.x, 0.0, 1200.0 * delta)
	if not z.is_on_floor():
		z.velocity.y += z.gravity * delta
	z.move_and_slide()
	return true


# איך התחמקת -> מה הוא יעשה בפעם הבאה
func _learn(pl: Node, d: Vector2) -> void:
	if move == "chop" and absf(d.x) > CHOP_REACH * 0.75 * z.sc:   # נסוגה מהמכה מלמעלה -> דקירה ארוכה
		move = "thrust"
		learned_back += 1
		if learned_back == 1:
			z._popup("HE LEARNED YOUR STEP BACK", Color("ffe0a0"), 12, -100.0)
	elif move == "thrust" and (not pl.is_on_floor() or pl._crouching):   # קפצת / התכופפת -> מכה מלמעלה
		move = "chop"
		learned_jump += 1
		if learned_jump == 1:
			z._popup("HE LEARNED YOUR DODGE", Color("ffe0a0"), 12, -100.0)


# זווית התורן (0 = זקוף, PI/2 = אופקי קדימה) ונקודת האחיזה - מקומי, לפני היפוך הכיוון
func pole_pose() -> Array:
	var k := 0.0
	match state:
		WIND:
			k = clampf(1.0 - _st / (WIND_T * (0.85 if move == "thrust" else 1.0)), 0.0, 1.0)
			k = k * k * (3.0 - 2.0 * k)
			if move == "chop":
				return [lerpf(0.0, -0.6, k), CHOP_PIVOT + Vector2(-3.0 * k, -4.0 * k)]
			return [lerpf(0.0, PI * 0.5, k), THRUST_PIVOT + Vector2(-12.0 * k, 0)]
		STRIKE:
			k = clampf(1.0 - _st / STRIKE_T, 0.0, 1.0)
			if move == "chop":
				return [lerpf(-0.6, 1.95, sqrt(k)), CHOP_PIVOT + Vector2(6.0 * k, 0)]
			return [PI * 0.5, THRUST_PIVOT + Vector2(lerpf(-12.0, 16.0, sqrt(k)), 0)]
		RECOVER:
			k = clampf(1.0 - _st / RECOVER_T, 0.0, 1.0)
			k = k * k * (3.0 - 2.0 * k)
			var a0 := 1.95 if move == "chop" else PI * 0.5
			var p0: Vector2 = CHOP_PIVOT + Vector2(6, 0) if move == "chop" else THRUST_PIVOT + Vector2(16, 0)
			return [lerpf(a0, 0.0, k), p0.lerp(CHOP_PIVOT, k)]
	return [0.0, CHOP_PIVOT]


func _to_world(local: Vector2) -> Vector2:
	return z.global_position + Vector2(local.x * z._dir, local.y) * z.sc


# התורן (מהידיים עד הקצה) חותך את הגוף של השחקן?
func _pole_hits(pl: Node) -> bool:
	var pose := pole_pose()
	var a: float = pose[0]
	if move == "chop" and a < 0.7:   # עוד לא ירד מספיק קדימה
		return false
	var piv: Vector2 = pose[1]
	var u := Vector2(sin(a), -cos(a))
	var r: Rect2 = pl.body_rect().grow(4.0)
	for i in 9:
		if r.has_point(_to_world(piv + u * POLE_LEN * float(i) / 8.0)):
			return true
	return false


# ============================================================
#  ציור: חייל עם חגורת נשיאה, תורן מוחזק בשתי ידיים, הדגל מתנופף למעלה (בעולם). הילה אדומה עדינה סביב היחידה
# ============================================================
func draw() -> bool:
	begin_draw()
	var attacking: bool = state != IDLE and standing and not z.dead
	var pose := pole_pose()
	var a: float = pose[0]
	var piv: Vector2 = pose[1]
	var u := Vector2(sin(a), -cos(a))
	var sh0 := Vector2(1, -37)
	var o: Dictionary
	if attacking:   # שתי הידיים על התורן
		o = E.soldier(self, z, piv - sh0 + u * 6.0, "helmet", E.UNIFORM, piv - sh0 - u * 4.0)
	else:
		o = E.soldier(self, z, Vector2(9, -6), "helmet", E.UNIFORM, Vector2(5, -2))
	var sh: Vector2 = o.sh
	z.draw_line(sh + Vector2(-6, -1), sh + Vector2(6, 18), col(Color("2a2018")), 2.0)   # חגורת נשיאה
	if attacking:   # התורן והדגל בתנועה (מקומי - מתהפך עם הכיוון)
		var tip := piv + u * POLE_LEN
		var butt := piv - u * 10.0
		var nn := Vector2(cos(a), sin(a))   # הצד שהבד נמשך אליו
		var wave := sin(z._time * 9.0) * 3.0
		var c0 := tip - u * 2.0
		var c1 := tip - u * 30.0
		var cloth := PackedVector2Array([c0, c0 + nn * 44.0 + u * wave, c1 + nn * 44.0 + u * (wave * 0.6), c1])
		z.draw_colored_polygon(cloth, col(E.RED))
		z.draw_line(c0, c1, col(E.RED_D), 2.0)
		E.emblem(z, (c0 + c1) * 0.5 + nn * 20.0, 8.0)
		z.draw_line(butt, tip, col(Color("5a4026")), 2.6)
		z.draw_colored_polygon(PackedVector2Array([tip + u * 7.0, tip + Vector2(-u.y, u.x) * 2.5, tip - Vector2(-u.y, u.x) * 2.5]), col(E.BRASS))   # ראש חנית
		if state == STRIKE:   # קו תנועה
			var ub := Vector2(sin(a - 0.5), -cos(a - 0.5)) if move == "chop" else u
			z.draw_line(piv + ub * POLE_LEN * 0.6, piv + ub * POLE_LEN, Color(1, 1, 1, 0.35), 3.0)
		if state == WIND:   # ברק על ראש החנית - אזהרה
			z.draw_circle(tip + u * 4.0, 2.5 + sin(z._time * 30.0), Color(1.0, 0.95, 0.7, 0.9))
	elif standing:
		z.draw_line(Vector2(8, -4), Vector2(8, -POLE_H), col(Color("5a4026")), 2.2)   # התורן
		z.draw_circle(Vector2(8, -POLE_H - 1.5), 2.0, col(E.BRASS))
	end_draw()
	if standing and not z.dead and not attacking:   # הדגל (בעולם, לא מתהפך)
		var top: Vector2 = flag_top() - z.global_position
		E.flag(z, top + Vector2(0, 3), 46.0, 30.0, z._time, int(z.global_position.x) % 7)
		Art.glow(z, Vector2(0, -30), AURA_R * 0.25, Color(1.0, 0.2, 0.15, 0.06))
	elif not standing and _fall < 1.0:   # הדגל נופל
		var k := clampf(_fall / 0.6, 0.0, 1.0)
		var tip2: Vector2 = Vector2(z._dir * (8.0 + 60.0 * k), -POLE_H * (1.0 - k)) * z.sc
		z.draw_line(Vector2(z._dir * 8.0, -4.0), tip2, Color("5a4026"), 2.2)
	return true
