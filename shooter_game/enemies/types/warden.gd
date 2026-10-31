extends "res://enemies/zombie_type.gd"
# ============================================================
#  WARDEN (שלב 60, "GLACIER LAB") - שומר האבטחה של המעבדה: שריון מהומות שחור, קסדה עם מגן פנים סדוק (ערפל ECHO ירוק
#    בפנים, עיניים אדומות), פנס על הכתף (אלומה שסורקת), אלה חשמלית, וכרטיס מפתח על שרוך בחזה.
#  מה הוא למד, וממה: הכוורת למדה את המערכות של המעבדה. ה-WARDEN יודע איפה לוחות האזעקה, ושדלת הדף סוגרת אותך בפנים.
#    PATROL   - מסייר ליד הבית. רואה אותך (SEE_R) / נפגע -> ALERT.
#    RUN      - "THEY LOCK THE DOORS NOW": כשאתה בתוך האגף שלו (wing, stage_60 WINGS) רץ ללוח האזעקה הקרוב (SPRINT) - לא
#               תוקף בדרך. מגיע -> SLAP (SLAP_T, יד על הלוח) -> stage_60.lockdown(): שתי דלתות האגף נטרקות (גם זו מאחוריך),
#               המיכלים באגף מפשירים. להרוג אותו לפני שהוא מגיע ללוח (הגב שלו פתוח x BACK_MULT).
#    FIGHT    - אלה חשמלית: מניף (SWING_WIND, ניצוצות כחולים) -> מכה + הלם (SLOW_T).
#  שריון: מגן הפנים x VISOR_MULT עד VISOR_HITS פגיעות בראש (נסדק - הראש פתוח), חזית x FRONT_MULT, גב x BACK_MULT.
#  מת -> כרטיס המפתח נופל (stage_60.drop_card). עוברים עליו -> האגף הנעול נפתח ("ACCESS GRANTED").
#  לומד (main meta "wn_cards" >= LEARN_CARDS - כרטיסים שאיבדו): "IT LOCKS THE DOOR AHEAD NOW" - כשהוא רואה אותך מתקרב
#    לאגף מבחוץ (AHEAD_R), רץ קודם ללוח של הדלת הרחוקה, נועל אותה מראש (early) ושומר עליה (GUARD). כשאתה נכנס לאגף -
#    גם הדלת מאחוריך נטרקת. הכרטיס שלו עדיין פותח - צריך להגיע אליו.
#  לשנות: SEE_R, AHEAD_R, SPRINT, SLAP_T, SWING_*, SLOW_T, VISOR_*, FRONT_MULT, BACK_MULT, LEARN_CARDS.
# ============================================================

const SOUNDS := {
	"wn_radio": [["N", 0, 0, 0.0, 0.35, 0.0, 4.0, 0.35, 1.0, 0, 0.55], ["Q", 1100, 1100, 0.0, 0.06, 0.0, 20.0, 0.1, 0.4, 0], ["Q", 900, 900, 0.18, 0.06, 0.0, 20.0, 0.08, 0.4, 0]],
	"wn_zap": {"drive": 2.4, "layers": [["N", 0, 0, 0.0, 0.25, 0.0, 9.0, 0.6, 1.0, 0, 0.45], ["Q", 120, 110, 0.0, 0.25, 0.0, 8.0, 0.3, 0.5, 0.2], ["S", 3400, 2600, 0.0, 0.2, 0.0, 12.0, 0.12, 1.0, 0.2]]},
	"wn_slap": [["N", 0, 0, 0.0, 0.08, 0.0, 30.0, 0.6, 0.25, 0], ["S", 1500, 1500, 0.1, 0.06, 0.0, 30.0, 0.25, 1.0, 0], ["S", 1100, 1100, 0.2, 0.08, 0.0, 30.0, 0.25, 1.0, 0]],
	"wn_visor": [["N", 0, 0, 0.0, 0.15, 0.0, 16.0, 0.5, 1.0, 0, 0.5], ["S", 4200, 3800, 0.0, 0.15, 0.0, 14.0, 0.15, 1.0, 0]],
}

const SEE_R := 620.0
const AHEAD_R := 1250.0
const SPRINT := 185.0
const SLAP_T := 0.7
const SWING_R := 72.0
const SWING_WIND := 0.4
const SWING_CD := 1.1
const SWING_DMG := 1
const SLOW_T := 0.8
const VISOR_HITS := 2
const VISOR_MULT := 0.4
const FRONT_MULT := 0.65
const BACK_MULT := 1.1
const FIRE_MULT := 1.3
const PATROL_R := 120.0
const GUARD_R := 260.0
const LEARN_CARDS := 2
const W_OPEN := 0                  # (stage_60: W_OPEN, W_HALF, W_SEALED, W_CLEAR)

enum {PATROL, ALERT, RUN, SLAP, FIGHT, SWING, GUARD}
var state := PATROL
# לבדיקות
var runs := 0
var slaps := 0
var locks := 0
var early_locks := 0
var swings := 0
var swing_hits := 0
var visor_hits := 0
var front_hits := 0
var back_hits := 0

var wing := -1                     # האגף שלו (stage_60 WINGS), -1 = בלי
var learned := false
var _home := 0.0
var _st := 0.0
var _cd := 0.6
var _goal := 0.0
var _early := false
var _tried := false
var _front := false
var _hit := false
var _light := 0.0                  # זווית האלומה
var _var := []
var _alert_said := false


func stats() -> Dictionary:
	return {"name": "WARDEN", "hp": 70, "walk": 46.0, "chase": 116.0, "damage": 1, "bite_delay": 0.9, "scale": 1.08, "width": 1.05,
		"duck": 0.0, "cover": 0.2, "skin": Color("7e8e86"), "shirt": Color("2a3240"), "pants": Color("222832"), "shoe": Color("121418"), "points": 560}


func brain_overrides() -> Dictionary:
	return {"aggression": 0.7}


func use_brain_movement() -> bool:
	return false


func can_bite() -> bool:
	return false


func _main() -> Node:
	return z.get_parent()


func _stage() -> Node:
	var m := _main()
	return m.get("_stage") if m != null else null


func setup() -> void:
	var m := _main()
	learned = m != null and int(m.get_meta("wn_cards", 0)) >= LEARN_CARDS
	_home = z.global_position.x
	z.add_to_group("s60_wardens")
	var r := RandomNumberGenerator.new()
	r.seed = z.get_instance_id()
	_var = [r.randf() < 0.5, r.randf_range(0.0, TAU), r.randi() % 3]
	z._dir = -1.0 if r.randf() < 0.5 else 1.0
	_resize(Vector2(30.0, 56.0))


func _resize(b: Vector2) -> void:
	var rs := z._shape.shape as RectangleShape2D
	rs.size = Vector2(b.x * z.wf * z.sc, b.y * z.sc)
	z._shape.position = Vector2(0.0, -b.y * 0.5 * z.sc)


func _wing_open() -> bool:
	var st := _stage()
	return wing >= 0 and st != null and st.has_method("wing_state") and int(st.wing_state(wing)) == W_OPEN


func _wing_of(x: float) -> int:
	var st := _stage()
	return int(st.wing_of(x)) if st != null and st.has_method("wing_of") else -1


# ============================================================
#  תנועה
# ============================================================
func physics(pl: Node, delta: float) -> bool:
	_st -= delta
	_cd -= delta
	if z.dead:
		return false
	if not z.is_in_group("zombies"):   # (שחקן בסצנה - לא בשימוש)
		return _end(delta)
	if not learned and Engine.get_physics_frames() % 30 == 0:
		var m := _main()
		learned = m != null and int(m.get_meta("wn_cards", 0)) >= LEARN_CARDS
	var has: bool = pl != null and not pl.dead
	var d: Vector2 = (pl.global_position - z.global_position) if has else Vector2.ZERO
	var px: float = pl.global_position.x if has else 0.0
	match state:
		PATROL:
			_light = sin(z._time * 0.9 + float(_var[1])) * 0.25
			var tx: float = _home + sin(z._time * 0.35 + float(_var[1])) * PATROL_R
			var dx: float = tx - z.global_position.x
			z._dir = signf(dx) if absf(dx) > 8.0 else z._dir
			z.velocity.x = move_toward(z.velocity.x, signf(dx) * z.walk_speed if absf(dx) > 8.0 else 0.0, 400.0 * delta)
			z._walk_phase += delta * 6.0 * minf(absf(z.velocity.x) / 40.0, 1.0)
			if has:
				var sees: bool = absf(d.x) < SEE_R and absf(d.y) < 160.0 and (signf(d.x) == z._dir or absf(d.x) < 200.0)
				if sees or z._alert_t > 0.0:
					_alert(pl)
				elif learned and _wing_open() and absf(d.x) < AHEAD_R and absf(d.y) < 200.0 and _wing_of(px) != wing:
					_alert(pl)
		ALERT:
			z.velocity.x = move_toward(z.velocity.x, 0.0, 900.0 * delta)
			if has:
				z._dir = signf(d.x) if absf(d.x) > 6.0 else z._dir
			if _st <= 0.0:
				_decide(pl, has)
		RUN:
			var gx: float = _goal - z.global_position.x
			z._dir = signf(gx) if absf(gx) > 4.0 else z._dir
			z.velocity.x = move_toward(z.velocity.x, signf(gx) * SPRINT, 1000.0 * delta)
			z._walk_phase += delta * 15.0
			_light = 0.15
			if z.is_on_floor() and z.is_on_wall() and absf(z.velocity.x) < 30.0:
				z.velocity.y = -480.0
			if not _wing_open():
				state = FIGHT
			elif absf(gx) < 10.0:
				_start_slap()
		SLAP:
			z.velocity.x = move_toward(z.velocity.x, 0.0, 1200.0 * delta)
			if _st <= 0.0:
				_slap_done()
		FIGHT:
			_fight(pl, has, d, px, delta)
		SWING:
			z.velocity.x = move_toward(z.velocity.x, 0.0, 1200.0 * delta)
			if _st <= 0.0 and not _hit:
				_hit = true
				Sfx.play("wn_zap", z.global_position + Vector2(z._dir * 24.0, -36), -2.0, 0.1, 3)
				if has and absf(d.x) < SWING_R + 16.0 and absf(d.y) < 64.0 and signf(d.x) == z._dir:
					if pl._roll_t <= 0.0:
						swing_hits += 1
					pl.hurt(SWING_DMG, Vector2(z._dir * 1.2, -0.4))
					if pl._roll_t <= 0.0:
						pl.slow_t = maxf(float(pl.slow_t), SLOW_T)
			if _st <= -0.25:
				state = FIGHT
				_cd = SWING_CD
		GUARD:   # (למד) שומר על הדלת שנעל
			z.velocity.x = move_toward(z.velocity.x, 0.0, 600.0 * delta)
			if has:
				z._dir = signf(d.x) if absf(d.x) > 6.0 else z._dir
				_light = sin(z._time * 1.6) * 0.15
				if absf(d.x) < GUARD_R and absf(d.y) < 100.0:
					state = FIGHT
	return _end(delta)


func _start_slap() -> void:
	state = SLAP
	_st = SLAP_T
	slaps += 1
	z.velocity.x = 0.0
	z._dir = _door_dir()
	Sfx.play("wn_slap", z.global_position + Vector2(0, -40), 0.0, 0.05, 2)


func _slap_done() -> void:
	var st := _stage()
	var ok := false
	if st != null and st.has_method("lockdown"):
		ok = st.lockdown(wing, _early)
	if ok:
		locks += 1
		if _early:
			early_locks += 1
	state = GUARD if (_early and ok) else FIGHT
	_cd = 0.3


# רחוק מהגיבור (zombie.gd לא מריץ זומבים רחוקים מ-1400): stage_60 ממשיך את הריצה ללוח ואת ה-SLAP
func remote(delta: float) -> void:
	if z.dead:
		return
	_st -= delta
	if state == RUN:
		if not _wing_open():
			state = FIGHT
			return
		var gx: float = _goal - z.global_position.x
		z._dir = signf(gx) if absf(gx) > 4.0 else z._dir
		z.global_position.x = move_toward(z.global_position.x, _goal, SPRINT * delta)
		z._walk_phase += delta * 15.0
		if absf(gx) < 10.0:
			_start_slap()
	elif state == SLAP and _st <= 0.0:
		_slap_done()


func running() -> bool:
	return state == RUN or state == SLAP


func _end(delta: float) -> bool:
	if not z.is_on_floor():
		z.velocity.y += z.gravity * delta
	z.move_and_slide()
	return true


func _alert(pl: Node) -> void:
	state = ALERT
	_st = 0.35
	Sfx.play("wn_radio", z.global_position + Vector2(0, -50), -4.0, 0.1, 2)
	if pl != null:
		z._dir = signf(pl.global_position.x - z.global_position.x + 0.01)


func _decide(pl: Node, has: bool) -> void:
	if not has:
		state = PATROL
		return
	var px: float = pl.global_position.x
	if _wing_open() and not _tried:
		var inside := _wing_of(px) == wing
		if inside:   # אתה בתוך האגף: רץ ללוח הקרוב (לו)
			_run(false, pl)
			return
		if learned:   # (למד) אתה עוד בחוץ: נועל מראש את הדלת הרחוקה ממך
			_run(true, pl)
			return
	state = FIGHT


func _run(early: bool, pl: Node) -> void:
	var st := _stage()
	if st == null or not st.has_method("panel_x"):
		state = FIGHT
		return
	var px: float = pl.global_position.x
	var a: float = st.panel_x(wing, -1.0)
	var b: float = st.panel_x(wing, 1.0)
	if early:   # הלוח של הדלת הרחוקה ממך
		_goal = b if absf(b - px) > absf(a - px) else a
	else:   # הלוח הקרוב אליו
		_goal = a if absf(a - z.global_position.x) < absf(b - z.global_position.x) else b
	_early = early
	_tried = true
	state = RUN
	runs += 1
	if early:
		var m := _main()
		if m != null and not m.has_meta("wn_ahead_said"):
			m.set_meta("wn_ahead_said", true)
			z._popup("IT LOCKS THE DOOR AHEAD NOW", Color("ff8a7a"), 13, -110.0)
			pl._say("He's running ahead to lock the next door!", Color("ffd080"))
	elif not _alert_said:
		_alert_said = true
		z._popup("ALARM!", Color("ff6a5a"), 14, -100.0)


# לאיזה צד הדלת הקרובה (לסיבוב אל הלוח)
func _door_dir() -> float:
	var best := INF
	var dd: float = z._dir
	for dn in z.get_tree().get_nodes_in_group("s60_doors"):
		var dx: float = dn.global_position.x - z.global_position.x
		if absf(dx) < best:
			best = absf(dx)
			dd = signf(dx) if absf(dx) > 1.0 else dd
	return dd


func _fight(pl: Node, has: bool, d: Vector2, px: float, delta: float) -> void:
	if not has:
		z.velocity.x = move_toward(z.velocity.x, 0.0, 600.0 * delta)
		return
	# נכנסת לאגף אחרי שכבר נלחם בך בחוץ: רץ ללוח
	if not _tried and _wing_open() and _wing_of(px) == wing:
		_run(false, pl)
		return
	z._dir = signf(d.x) if absf(d.x) > 6.0 else z._dir
	_light = clampf(atan2(d.y + 30.0, absf(d.x) + 1.0), -0.5, 0.5)
	z.velocity.x = move_toward(z.velocity.x, z._dir * z.chase_speed if absf(d.x) > SWING_R * 0.7 else 0.0, 700.0 * delta)
	z._walk_phase += delta * 10.0 * minf(absf(z.velocity.x) / 80.0, 1.0)
	if z.is_on_floor() and z.is_on_wall() and absf(z.velocity.x) < 30.0:
		z.velocity.y = -470.0
	if absf(d.x) < SWING_R and absf(d.y) < 60.0 and _cd <= 0.0 and z.is_on_floor():
		state = SWING
		swings += 1
		_st = SWING_WIND
		_hit = false


func on_damage(_amount: int, _hit_pos: Vector2, dir: Vector2, _src: Dictionary) -> bool:
	if z.dead:
		return true
	_front = dir.x * z._dir < 0.0
	if state == PATROL or state == GUARD:
		z._alert_t = 2.0
	return true


func damage_mult(zone: String, src: Dictionary) -> float:
	var s := str(src.get("source", "bullet"))
	if s == "fire":
		return FIRE_MULT
	if s != "bullet" and s != "melee":
		return 1.0
	if zone == "head":
		if visor_hits < VISOR_HITS:
			visor_hits += 1
			Sfx.play("wn_visor", z.global_position + Vector2(0, -52.0 * z.sc), -2.0, 0.1, 2)
			if visor_hits == VISOR_HITS:
				z._popup("VISOR CRACKED", Color("c8e0ff"), 12, -90.0)
			return VISOR_MULT
		return 1.0
	if _front:
		front_hits += 1
		return FRONT_MULT if zone != "leg" else 0.9
	back_hits += 1
	return BACK_MULT


func on_death() -> void:
	var st := _stage()
	if st != null and st.has_method("drop_card"):
		st.drop_card(z.global_position, wing)


func wants_redraw() -> bool:
	return true


# ============================================================
#  ציור: שריון מהומות שחור, קסדה עם מגן פנים (סדוק אחרי פגיעות - ערפל ירוק), פנס כתף + אלומה, אלה חשמלית,
#  כרטיס מפתח על שרוך. רץ ללוח: יד מושטת קדימה. SLAP: יד על הלוח, נורה אדומה.
# ============================================================
func draw() -> bool:
	if _var.is_empty():
		return false
	begin_draw()
	var tt: float = z._time
	var sk := col(z.skin)
	var uni := col(z.shirt)
	var uni_d := col(Art.shade(z.shirt, 0.3))
	var arm := col(Color("1a1e26"))
	var arm_l := col(Color("2c323e"))
	var run := state == RUN
	var lean := 3.0 if run else 0.0
	var hip: Vector2 = Vector2(0.0, -23.0 + absf(sin(z._walk_phase)) * 0.8)
	var sh := Vector2(1.5 + lean, -40.0)
	var head := sh + Vector2(3.0 + lean * 0.3, -9.0)
	# אלומת הפנס (מאחורי הכל, שקופה)
	if not z.dead:
		var lp := sh + Vector2(-2.0, -2.0)
		var a := _light
		var l1 := lp + Vector2.from_angle(a - 0.22) * 130.0
		var l2 := lp + Vector2.from_angle(a + 0.22) * 130.0
		DrawBatch.polygon(z, PackedVector2Array([lp, l1, l2]), PackedColorArray([Color(1.0, 0.96, 0.8, 0.22), Color(1.0, 0.96, 0.8, 0.0), Color(1.0, 0.96, 0.8, 0.0)]))
	# רגליים: מכנסיים טקטיים + מגיני ברכיים + מגפיים
	var f: Array = feet(6.5 if run else 5.0, 2.5)
	z._leg(hip + Vector2(-2, 0), f[1], col(Art.shade(z.pants, 0.25)), uni_d, col(z.shoe))
	z._leg(hip + Vector2(2, 0), f[0], col(z.pants), uni, col(z.shoe))
	for i in 2:
		var ft: Vector2 = f[i]
		var kn := (hip + Vector2(-2.0 + float(i) * 4.0, 0.0)).lerp(ft, 0.5) + Vector2(2.0, 0.0)
		DrawBatch.rect(z, Rect2(kn + Vector2(-2.5, -2.5), Vector2(5.5, 5.0)), arm if i == 0 else arm_l)
	# יד אחורית
	var hb: Vector2 = sh + Vector2(-4.0 - sin(z._walk_phase) * 3.0, 15.0)
	if run:
		hb = sh + Vector2(-9.0, 10.0)
	Art.limb(z, PackedVector2Array([sh + Vector2(-3, 1), Art.joint(sh + Vector2(-3, 1), hb, 9.0, 9.5, -1.0), hb]), 5.0, uni_d, Art.OUTLINE, false, true)
	DrawBatch.circle(z, hb, 2.2, col(Color("101216")))   # כפפה
	# גוף: חולצה + אפוד שריון עם פסים מחזירי אור
	var body := PackedVector2Array([sh + Vector2(-7.5, -1), sh + Vector2(7.5, 0), hip + Vector2(6.5, 2), hip + Vector2(-6.5, 2)])
	Art.fill_shaded(z, body, uni, 0.12, 0.35)
	var vest := PackedVector2Array([sh + Vector2(-6.5, 1.5), sh + Vector2(7.5, 2.0), hip + Vector2(6.5, -3.0), hip + Vector2(-6.0, -3.0)])
	Art.fill_shaded(z, vest, arm_l, 0.15, 0.3, Art.OUTLINE, 1.0)
	DrawBatch.rect(z, Rect2(sh + Vector2(-6.0, 10.0), Vector2(13.0, 1.6)), col(Color(0.85, 0.85, 0.7, 0.8)))   # פס מחזיר אור
	DrawBatch.rect(z, Rect2(hip + Vector2(-6.5, -1.5), Vector2(13.0, 2.6)), col(Color("14161a")))   # חגורה
	DrawBatch.rect(z, Rect2(hip + Vector2(3.0, -1.0), Vector2(3.0, 4.0)), col(Color("2a2e36")))   # נרתיק
	# כתפיות
	Art.oval(z, sh + Vector2(-4.5, 1.0), 4.5, 3.4, arm, -0.2, Art.OUTLINE, 1.0)
	# פנס הכתף
	var fl := sh + Vector2(-3.0, -3.0)
	DrawBatch.rect(z, Rect2(fl + Vector2(-2.5, -1.8), Vector2(5.0, 3.6)), col(Color("3a3e44")))
	if not z.dead:
		DrawBatch.circle(z, fl + Vector2(2.6, 0.0), 1.4, Color(1.0, 0.97, 0.85))
		Art.glow(z, fl + Vector2(2.6, 0.0), 5.0, Color(1.0, 0.95, 0.75, 0.4))
	# כרטיס מפתח על שרוך (מתנדנד)
	var sw := sin(tt * 3.0 + float(_var[1])) * (2.5 if run else 1.0)
	var cp := sh + Vector2(3.0 + sw, 12.0)
	DrawBatch.line(z, sh + Vector2(0.0, 1.0), cp, col(Color("b02828")), 0.7)
	DrawBatch.line(z, sh + Vector2(5.5, 1.0), cp, col(Color("b02828")), 0.7)
	DrawBatch.rect(z, Rect2(cp + Vector2(-2.2, 0.0), Vector2(4.4, 5.6)), col(Color("eef0ea")))
	DrawBatch.rect(z, Rect2(cp + Vector2(-2.2, 3.6), Vector2(4.4, 1.2)), col(Color("38c860")))
	# ראש בקסדה עם מגן פנים
	Art.oval_shaded(z, head, 6.0, 6.4, sk, 0.0)
	var hel := PackedVector2Array()
	for q in 11:
		var a := PI * 0.95 + PI * 1.1 * float(q) / 10.0
		hel.append(head + Vector2(cos(a) * 7.4, sin(a) * 7.6 + 0.5))
	hel.append(head + Vector2(-7.0, 3.5))
	Art.fill_shaded(z, hel, arm, 0.2, 0.3, Art.OUTLINE, 1.1)
	DrawBatch.rect(z, Rect2(head + Vector2(-7.5, 2.5), Vector2(6.0, 4.5)), col(Color("14161a")))   # מגן עורף
	# עיניים מאחורי המגן
	var cracked := visor_hits >= VISOR_HITS
	if not z.dead:
		var ec := Color(1.0, 0.25, 0.18)
		DrawBatch.circle(z, head + Vector2(3.8, -0.6), 0.95, ec)
		DrawBatch.circle(z, head + Vector2(1.2, -0.6), 0.75, Color(ec, 0.7))
	DrawBatch.colored_polygon(z, PackedVector2Array([head + Vector2(0.5, 3.6), head + Vector2(5.2, 3.0), head + Vector2(4.6, 4.6), head + Vector2(0.8, 4.6)]), col(Color("2a0a0c")))
	# המגן: שקוף-כחלחל, עם ערפל ECHO ירוק בפנים. סדוק = קווים
	var vz := PackedVector2Array([head + Vector2(-0.5, -4.6), head + Vector2(7.6, -3.6), head + Vector2(8.2, 3.0), head + Vector2(6.2, 6.2), head + Vector2(0.0, 5.6)])
	DrawBatch.colored_polygon(z, vz, Color(0.55, 0.75, 0.9, 0.28) if _flash_ok() else Color.WHITE)
	var fog := 0.25 + (0.25 if cracked else 0.0) + 0.1 * sin(tt * 2.0)
	Art.oval(z, head + Vector2(3.5, 2.5), 3.6, 2.4, Color(0.75, 1.0, 0.55, fog), 0.0, Art.NONE)
	DrawBatch.line(z, head + Vector2(0.0, -4.4), head + Vector2(7.4, -3.4), col(Color(0.85, 0.95, 1.0, 0.7)), 0.8)
	if visor_hits >= 1 or bool(_var[0]):
		DrawBatch.polyline(z, PackedVector2Array([head + Vector2(5.5, -3.0), head + Vector2(4.0, 0.0), head + Vector2(6.0, 2.0), head + Vector2(4.5, 5.0)]), Color(0.9, 0.97, 1.0, 0.8), 0.6)
	if cracked:
		DrawBatch.polyline(z, PackedVector2Array([head + Vector2(1.0, -3.5), head + Vector2(3.0, -1.0), head + Vector2(1.5, 2.0)]), Color(0.9, 0.97, 1.0, 0.8), 0.6)
		DrawBatch.line(z, head + Vector2(4.0, 0.0), head + Vector2(7.5, 1.0), Color(0.9, 0.97, 1.0, 0.8), 0.6)
		Art.glow(z, head + Vector2(4.0, 1.0), 6.0, Color(0.75, 1.0, 0.55, 0.3))
	# יד קדמית + אלה חשמלית
	var hf: Vector2
	var ba := 0.6   # זווית האלה
	match state:
		SWING:
			var k := clampf(_st / SWING_WIND, 0.0, 1.0)
			if _st > 0.0:
				hf = sh + Vector2(-2.0, -10.0).lerp(Vector2(6.0, 8.0), k)
				ba = lerpf(-2.2, -0.4, k)
			else:
				hf = sh + Vector2(14.0, 6.0)
				ba = 0.5
		RUN:
			hf = sh + Vector2(13.0, 2.0)
			ba = 0.2
		SLAP:
			hf = sh + Vector2(15.0, -2.0)
			ba = 1.2
		ALERT:
			hf = sh + Vector2(6.0, -6.0)
			ba = -1.2
		_:
			hf = sh + Vector2(4.0 + sin(z._walk_phase + PI) * 3.0, 14.0)
			ba = 1.1
	Art.limb(z, PackedVector2Array([sh + Vector2(3, 1), Art.joint(sh + Vector2(3, 1), hf, 9.0, 9.5, -1.0), hf]), 5.2, uni, Art.OUTLINE, false, true)
	Art.oval(z, sh + Vector2(4.0, 1.5), 4.2, 3.2, arm_l, 0.2, Art.OUTLINE, 1.0)   # כתפייה קדמית
	if state == SLAP:   # יד על הלוח, נורה מהבהבת
		DrawBatch.circle(z, hf, 2.4, col(Color("101216")))
		if int(tt * 10.0) % 2 == 0:
			Art.glow(z, hf + Vector2(3.0, -3.0), 6.0, Color(1.0, 0.2, 0.1, 0.8))
	else:
		var bd := Vector2.from_angle(ba)
		var tip := hf + bd * 17.0
		DrawBatch.line(z, hf - bd * 3.0, tip, col(Color("101216")), 2.4)
		DrawBatch.line(z, tip - bd * 4.0, tip, col(Color("3a3e48")), 2.6)
		DrawBatch.circle(z, hf, 2.4, col(Color("101216")))
		if not z.dead:
			var live := state == SWING or state == ALERT or (state == FIGHT and int(tt * 6.0) % 3 == 0)
			Art.glow(z, tip, 4.0 + (4.0 if live else 0.0), Color(0.45, 0.7, 1.0, 0.5 if live else 0.25))
			if live:
				for q in 3:
					var a := tt * 40.0 + float(q) * 2.1
					DrawBatch.line(z, tip, tip + Vector2.from_angle(a) * (4.0 + float(q)), Color(0.75, 0.9, 1.0, 0.9), 0.7)
	end_draw()
	return true


func _flash_ok() -> bool:
	return z._flash <= 0.0
