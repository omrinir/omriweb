extends "res://enemies/zombie_type.gd"
# ============================================================
#  TUMBLER (שלב 55, "WIND STEPPE") - פועל חווה מת (פונצ'ו קרוע, ממחטה על הצוואר) מכורבל בתוך כדור של שיח קוצני
#  של הערבה (mata negra / כדור קוצים). הענפים ננעצו בו וגדלו דרכו. בפנים: עין אדומה, יד אפורה שבולטת בין הענפים.
#  מה הוא למד: "הגיבור יורה במה שהולך אליו". כדור קוצים מתגלגל ברוח הוא חלק מהנוף - אף אחד לא יורה בו.
#    אז הם לא הולכים אליך: הרוח מגלגלת אותם.
#  מחזור:
#    REST   - כדור קוצים שוכב בצד הדרך (מתנדנד ברוח; הסימן: עין אדומה + יד). אתה במורד הרוח בטווח ROLL_R -> ROLL.
#    ROLL   - מתגלגל אליך מהר במורד הרוח (ROLL_V + משב x ROLL_GUST), מקפץ על בליטות (HOP) ומעל מכשולים (WALL_HOP).
#             נגד הרוח הוא לא מתגלגל: אתה מאחוריו -> נפתח והולך.
#    UNROLL - קרוב אליך (GRAB_R): הכדור נפתח לרווחה, ידיים קוצניות פרושות (UNROLL_T - האזהרה) -> GRAB.
#    GRAB   - חיבוק קוצני: player.grab(z), לוחץ כל SQUEEZE_EVERY (נזק 1). משתחררים ב-A/D, עוזב לבד אחרי HOLD_MAX,
#             או כשהוא סופג HEAVY_HIT. אחרי שחרור - STUN (חלון לירות בו).
#    WALK   - זומבי רגלי (המוח) עם הכדור על הגב כמו גלימה. משב + אתה במורד הרוח -> CURL: מתכרבל ומתגלגל שוב.
#  נגד: לירות בכדור: כל פגיעה תולשת ענפים (BALL_HP; רק BALL_LEAK מהנזק עובר לגוף). נגמרו הענפים -> STRIPPED: נחשף ומסוחרר.
#    אש (להביור / דרקון) שורפת את הכדור מיד (והוא בוער). פיצוץ מפרק את הכדור. לקפוץ מעליו - נפתח מאחוריך.
#    גדר תיל (s55_decor BarbedWire) לוכדת כדור מתגלגל (SNAG) - תקוע וקל להרוג.
#  "THEY WAIT FOR THE WIND" (main meta "tb_lessons" >= LEARN): אחרי ש-LEARN כדורים בודדים נעצרו לפני שהגיעו אליך,
#    הבאים לא מתגלגלים לבד: הם מחכים למשב (stage.gust_k) ומתגלגלים כולם יחד, להקה (PACK_R), מהר יותר (PACK_BOOST).
#  צלילים: "tb_roll" (רשרוש ענפים), "tb_snap" (ענפים נשברים), "tb_open" (נפתח + גרגור), "tb_squeeze", "tb_burn".
#  לשנות: ROLL_R, ROLL_V, ROLL_GUST, HOP, WALL_HOP, GRAB_R, UNROLL_T, HOLD_MAX, SQUEEZE_EVERY, HEAVY_HIT, BALL_HP,
#    BALL_LEAK, SNAG_T, LEARN, PACK_R, PACK_BOOST, WAIT_MAX, CURL_CD.
# ============================================================

const SOUNDS := {
	"tb_roll": {"drive": 1.4, "layers": [["N", 0, 0, 0.0, 0.5, 0.05, 2.5, 0.35, 0.55, 0.5, 0.3], ["C", 0, 0, 0.0, 0.5, 0.0, 2.0, 0.25, 0.9, 0]]},
	"tb_snap": [["C", 0, 0, 0.0, 0.08, 0.0, 30.0, 0.7, 1.0, 0], ["N", 0, 0, 0.0, 0.1, 0.0, 30.0, 0.5, 0.7, 0, 0.4], ["C", 0, 0, 0.05, 0.06, 0.0, 30.0, 0.5, 1.0, 0]],
	"tb_open": {"drive": 2.4, "layers": [["N", 0, 0, 0.0, 0.3, 0.0, 7.0, 0.6, 0.6, 0.5, 0.3], ["V", 150, 110, 0.05, 0.45, 0.02, 4.0, 0.7, 1.0, 0.08, 0, [520, 1100, 40]]]},
	"tb_squeeze": {"drive": 2.4, "layers": [["C", 0, 0, 0.0, 0.2, 0.0, 10.0, 0.7, 1.0, 0], ["N", 0, 0, 0.0, 0.2, 0.0, 14.0, 0.5, 0.5, 0, 0.3], ["V", 110, 80, 0.04, 0.35, 0.02, 5.0, 0.5, 1.0, 0.05, 0, [480, 900, 40]]]},
	"tb_burn": {"drive": 1.8, "layers": [["N", 0, 0, 0.0, 0.9, 0.02, 2.0, 0.7, 0.35, 0, 0.1], ["C", 0, 0, 0.0, 0.9, 0.0, 2.5, 0.4, 1.0, 0]]},
}

const DebrisScript := preload("res://debris.gd")

const ROLL_R := 900.0
const ROLL_V := 215.0
const ROLL_GUST := 170.0
const HOP := Vector2(170.0, 290.0)     # קפיצות קטנות בגלגול
const WALL_HOP := 470.0
const GRAB_R := 58.0
const UNROLL_T := 0.28
const HOLD_MAX := 2.2
const SQUEEZE_EVERY := 0.9
const HEAVY_HIT := 22
const BALL_HP := 30
const BALL_LEAK := 0.35
const SNAG_T := 1.6
const LEARN := 3
const PACK_R := 650.0
const PACK_BOOST := 1.2
const WAIT_MAX := 9.0
const CURL_CD := 4.0
const BALL_R := 25.0

enum { REST, ROLL, UNROLL, GRAB, WALK, STUN, SNAG, CURL }

# לבדיקות
var rolls := 0
var packs := 0
var waited := 0
var hops := 0
var unrolls := 0
var grabs := 0
var squeezes := 0
var releases := 0
var strips := 0
var burns := 0
var snags := 0
var curls := 0
var ball_hits := 0

var state := REST
var _t := 0.0
var _cd := 0.0
var _ball := BALL_HP
var _has_ball := true
var _roll_a := 0.0
var _hop_t := 0.5
var _squeeze := 0.0
var _taken := 0
var _leak := false
var _wait := 0.0
var _pack_delay := -1.0
var _boost := 1.0
var _snd_t := 0.0
var _stuck_t := 0.0
var _open := 0.0                 # 0 כדור .. 1 פתוח
var _def_size := Vector2(36, 62)
var _def_pos := Vector2(0, -31)
var _twigs: Array = []           # [זווית1, רדיוס1, זווית2, רדיוס2, עובי, גוון]
var _thorns: Array = []          # [זווית, רדיוס, אורך]
var _dark := false
var _poncho := Color("8a4a2a")
var _scarf := Color("c83a2a")
var _was_alone := true


func stats() -> Dictionary:
	return {"name": "TUMBLER", "hp": 34, "walk": 46.0, "chase": 116.0, "damage": 1, "bite_delay": 0.9, "scale": 0.92, "width": 1.0,
		"duck": 0.0, "cover": 0.0, "skin": Color("a0a07e"), "shirt": _poncho, "pants": Color("5a5040"), "shoe": Color("2a2018"), "points": 360}


func brain_overrides() -> Dictionary:
	return {"aggression": 0.6}


func use_brain_movement() -> bool:
	return state == WALK


func can_bite() -> bool:
	return state == WALK


func can_groan() -> bool:
	return state != REST and state != ROLL


func _main() -> Node:
	return z.get_parent()


func _stage() -> Node:
	var m := _main()
	return m.get("_stage") if m != null else null


func _wind() -> float:
	var st := _stage()
	if st != null and st.has_method("wind"):
		return float(st.wind())
	return -0.4


func _gust() -> float:
	var st := _stage()
	if st != null and st.has_method("gust_k"):
		return float(st.gust_k())
	return 0.0


func _wd() -> float:
	var w := _wind()
	return -1.0 if w < 0.0 else 1.0


static func is_learned(m: Node) -> bool:
	return m != null and int(m.get_meta("tb_lessons", 0)) >= LEARN


func learned() -> bool:
	return is_learned(_main())


func setup() -> void:
	var r := RandomNumberGenerator.new()
	r.seed = z.get_instance_id() * 13 + 5
	_dark = r.randf() < 0.45
	_poncho = [Color("8a4a2a"), Color("6a5a3a"), Color("4a3a5a"), Color("7a2a2a"), Color("5a6a4a")][r.randi() % 5]
	_scarf = [Color("c83a2a"), Color("e0c040"), Color("2a6ab0"), Color("e8e0d0")][r.randi() % 4]
	z.shirt = _poncho
	for i in 64:   # ענפים: קשתות בין נקודות על הכדור
		var a1 := r.randf() * TAU
		var a2 := a1 + r.randf_range(0.6, 2.2) * (1.0 if r.randf() < 0.5 else -1.0)
		var inner := i % 3 == 0   # שליש מהענפים חוצים את הפנים (כדור מלא, לא זר)
		_twigs.append([a1, r.randf_range(0.15, 0.6) if inner else r.randf_range(0.6, 1.0), a2, r.randf_range(0.6, 1.0), r.randf_range(1.1, 2.0), r.randf_range(-0.14, 0.14)])
	for i in 34:
		_thorns.append([r.randf() * TAU, r.randf_range(0.85, 1.05), r.randf_range(3.0, 6.0)])
	var rs := z._shape.shape as RectangleShape2D
	_def_size = rs.size
	_def_pos = z._shape.position
	_ball_shape(true)
	_wait = WAIT_MAX * r.randf_range(0.8, 1.2)


func _ball_shape(on: bool) -> void:
	var rs := z._shape.shape as RectangleShape2D
	if on:
		rs.size = Vector2(BALL_R * 2.0, BALL_R * 2.0) * z.sc
		z._shape.position = Vector2(0.0, -BALL_R * z.sc)
	else:
		rs.size = _def_size
		z._shape.position = _def_pos


func _balled() -> bool:
	return state == REST or state == ROLL or state == SNAG or state == CURL


# ============================================================
#  תנועה
# ============================================================
func physics(pl: Node, delta: float) -> bool:
	if z.dead:
		return false
	_t -= delta
	_cd -= delta
	var has: bool = pl != null and not pl.dead
	var d: Vector2 = (pl.global_position - z.global_position) if has else Vector2(9999, 0)
	var wd := _wd()
	_open = move_toward(_open, 0.0 if _balled() else 1.0, delta * (8.0 if _balled() else 5.0))
	if state == WALK:
		if _has_ball and has and _cd <= 0.0 and z.is_on_floor() and signf(d.x) == wd and absf(d.x) > 260.0 and absf(d.x) < 700.0 \
				and absf(d.y) < 60.0 and (_gust() > 0.4 or (not learned() and randf() < delta * 0.3)):
			state = CURL
			_t = 0.35
			curls += 1
			Sfx.play("tb_snap", z.global_position, -4.0, 0.1, 2)
			return true
		return false
	if not z.is_on_floor():
		z.velocity.y += z.gravity * delta
	match state:
		REST:
			z.velocity.x = move_toward(z.velocity.x, 0.0, 500.0 * delta)
			_roll_a += sin(z._time * 3.0) * 0.4 * delta * absf(_wind()) * 6.0   # מתנדנד ברוח
			if _pack_delay >= 0.0:   # נקרא ע"י הלהקה
				_pack_delay -= delta
				if _pack_delay < 0.0:
					_start_roll(true)
			elif has:
				_rest_think(pl, d, wd, delta)
		CURL:
			z.velocity.x = move_toward(z.velocity.x, 0.0, 600.0 * delta)
			if _t <= 0.0:
				_ball_shape(true)
				_start_roll(false)
		ROLL:
			_roll(pl, has, d, wd, delta)
		UNROLL:
			z.velocity.x = move_toward(z.velocity.x, 0.0, 900.0 * delta)
			if has:
				z._dir = signf(d.x) if absf(d.x) > 4.0 else z._dir
			if _t <= 0.0:
				if has and absf(d.x) < GRAB_R + 14.0 and absf(d.y) < 46.0 and _grabbable(pl):
					_grab(pl)
				else:
					state = WALK
					_cd = CURL_CD
		GRAB:
			z.velocity.x = 0.0
			if pl == null or pl.dead or pl.grabbed_by != z:
				_let_go(false)
			else:
				var hx: float = z.global_position.x + z._dir * 18.0
				pl.global_position.x = move_toward(pl.global_position.x, hx, 300.0 * delta)
				pl.velocity.x = 0.0
				_squeeze -= delta
				if _squeeze <= 0.0:
					_squeeze = SQUEEZE_EVERY
					squeezes += 1
					pl.hurt(1, Vector2.ZERO)
					Sfx.play("tb_squeeze", z.global_position, -2.0, 0.1, 2)
					if Art.on_screen(z, z.global_position):
						Particles.burst(_main(), pl.global_position + Vector2(0, -30), "hit", Vector2.UP, 5)
				if _t <= 0.0:
					_let_go(true)
		STUN:
			z.velocity.x = move_toward(z.velocity.x, 0.0, 500.0 * delta)
			if _t <= 0.0:
				state = WALK
				_cd = CURL_CD
		SNAG:
			z.velocity.x = move_toward(z.velocity.x, 0.0, 1200.0 * delta)
			_roll_a += sin(z._time * 30.0) * 0.02
			if _t <= 0.0:
				_unroll_now(false)
				state = STUN
				_t = 0.4
	z.move_and_slide()
	return true


func _rest_think(pl: Node, d: Vector2, wd: float, delta: float) -> void:
	var adx := absf(d.x)
	if adx < 120.0 and absf(d.y) < 60.0:   # התגנבת אליו
		_unroll_now(true)
		return
	var downwind := signf(d.x) == wd
	if not downwind:
		if adx < 420.0 and absf(d.y) < 80.0:   # אתה מאחוריו (נגד הרוח): נפתח והולך
			_unroll_now(false)
			state = WALK
			_cd = CURL_CD
		return
	if adx > ROLL_R or absf(d.y) > 160.0:
		return
	if learned():   # מחכה למשב - ואז כולם יחד
		_wait -= delta
		if _gust() > 0.5 or _wait <= 0.0:
			_start_roll(true)
			_call_pack()
		return
	_start_roll(false)


func _call_pack() -> void:
	var n := 0
	var i := 0
	for o in z.get_tree().get_nodes_in_group("zombies"):
		if o == z or o.dead or o.type_mod == null or not (o.type_mod is Object) or o.type_mod.get_script() != get_script():
			continue
		var t = o.type_mod
		if t.state == REST and t._pack_delay < 0.0 and absf(o.global_position.x - z.global_position.x) < PACK_R:
			i += 1
			t._pack_delay = 0.12 * float(i) + randf() * 0.15
			t._boost = PACK_BOOST
			n += 1
	if n > 0:
		packs += 1
		_boost = PACK_BOOST
		var m := _main()
		if m != null and not m.has_meta("tb_said"):
			m.set_meta("tb_said", true)
			z._popup("THEY WAIT FOR THE WIND", Color("ffb070"), 15, -70.0)
			var pl := player()
			if pl != null and pl.has_method("_say"):
				pl._say("They're riding the gust together...", Color("ffb070"))
	else:
		waited += 1


func _start_roll(pack: bool) -> void:
	state = ROLL
	rolls += 1
	if pack:
		_boost = maxf(_boost, PACK_BOOST)
		waited += 1
	_hop_t = randf_range(0.2, 0.5)
	_was_alone = not pack
	Sfx.play("tb_roll", z.global_position, -2.0, 0.15, 2)


func _roll(pl: Node, has: bool, d: Vector2, wd: float, delta: float) -> void:
	var v := (ROLL_V + _gust() * ROLL_GUST) * _boost
	z.velocity.x = move_toward(z.velocity.x, wd * v, 500.0 * delta)
	z._dir = wd
	_roll_a += z.velocity.x / (BALL_R * z.sc) * delta
	_hop_t -= delta
	if z.is_on_floor():
		if z.is_on_wall():   # מכשול: קפיצה גבוהה מעליו
			z.velocity.y = -WALL_HOP
			hops += 1
			_stuck_t += delta
		elif _hop_t <= 0.0:
			_hop_t = randf_range(0.35, 0.9)
			z.velocity.y = -randf_range(HOP.x, HOP.y)
			hops += 1
			if Art.on_screen(z, z.global_position):
				Particles.burst(_main(), z.global_position, "smoke", Vector2(-wd, -0.3), 2)
		else:
			_stuck_t = maxf(0.0, _stuck_t - delta)
	_snd_t -= delta
	if _snd_t <= 0.0:
		_snd_t = 0.5
		if Art.on_screen(z, z.global_position):
			Sfx.play("tb_roll", z.global_position, -8.0, 0.2, 3)
	if Engine.get_physics_frames() % 5 == 0 and z.is_on_floor() and Art.on_screen(z, z.global_position):
		Particles.burst(_main(), z.global_position + Vector2(-wd * 10.0, -2), "smoke", Vector2(-wd, -0.5), 1)
	if _stuck_t > 0.6 or z.global_position.x < 30.0:   # תקוע לגמרי: נפתח
		_stuck_t = 0.0
		_unroll_now(false)
		state = WALK
		_cd = CURL_CD
		return
	if not has:
		return
	if absf(d.x) < GRAB_R and absf(d.y) < 50.0:
		_unroll_now(true)
		return
	if signf(d.x) != wd and absf(d.x) > 40.0:   # עבר אותך (קפצת מעליו): נפתח מאחוריך
		_unroll_now(false)
		state = WALK
		_cd = CURL_CD


# נפתח: grab = מנסה לתפוס אחרי האזהרה
func _unroll_now(grab: bool) -> void:
	unrolls += 1
	_ball_shape(false)
	if grab:
		state = UNROLL
		_t = UNROLL_T
	else:
		state = STUN
		_t = 0.35
	z.velocity.y = -120.0
	Sfx.play("tb_open", z.global_position, 0.0, 0.1, 2)
	if Art.on_screen(z, z.global_position):
		_twig_burst(z.global_position + Vector2(0, -BALL_R), 4, Vector2.UP)


func _grabbable(pl: Node) -> bool:
	return pl != null and not pl.dead and pl.grabbed_by == null and pl._roll_t <= 0.0 and not pl._climbing


func _grab(pl: Node) -> void:
	state = GRAB
	grabs += 1
	_t = HOLD_MAX
	_squeeze = 0.5
	_taken = 0
	pl.grab(z)
	Sfx.play("tb_squeeze", z.global_position, 0.0, 0.1, 2)


func _let_go(push: bool) -> void:
	var pl := player()
	if pl != null and pl.grabbed_by == z:
		pl.grabbed_by = null
		if push:
			pl.velocity.x = z._dir * 200.0
	if state == GRAB:
		releases += 1
	state = STUN
	_t = 1.0
	_cd = CURL_CD
	z.velocity.x = -z._dir * 110.0


func on_release() -> void:
	if state == GRAB:
		releases += 1
	state = STUN
	_t = 1.2
	_cd = CURL_CD
	z.velocity.x = -z._dir * 150.0
	z._popup("SHAKEN OFF", Color(1.0, 0.75, 0.4), 13, -70.0)


# BarbedWire (s55_decor): כדור מתגלגל נתפס בתיל. true = טיפלנו (בלי נזק רגיל)
func snag_wire(_wire: Node) -> bool:
	if state != ROLL:
		return false
	state = SNAG
	snags += 1
	_t = SNAG_T
	z.velocity = Vector2(0.0, -60.0)
	Sfx.play("tb_snap", z.global_position, 0.0, 0.1, 2)
	z._popup("SNAGGED", Color("e0b080"), 14, -50.0)
	return true


# ============================================================
#  נזק: הכדור סופג, אש שורפת אותו
# ============================================================
func on_damage(amount: int, hit_pos: Vector2, dir: Vector2, src: Dictionary) -> bool:
	_leak = false
	if z.dead or not _has_ball or not _balled():
		return true
	if src.get("incendiary", false) or str(src.get("source", "")) == "fire":
		_burn_ball()
		return true
	if src.has("blast"):
		_strip(dir, true)
		return true
	var dmg := hit_damage(amount, hit_pos, src)
	ball_hits += 1
	_ball -= dmg
	_leak = true
	Sfx.play("tb_snap", hit_pos, -6.0, 0.2, 3)
	if Art.on_screen(z, hit_pos):
		_twig_burst(hit_pos, 3, -dir)
	z.velocity.x += dir.x * 40.0
	if _ball <= 0:
		_strip(dir, false)
	return true


func damage_mult(_zone: String, _src: Dictionary) -> float:
	return BALL_LEAK if _leak else 1.0


func _lesson() -> void:   # כדור שנעצר לפני שהגיע אליך = שיעור
	if state == ROLL and _was_alone:
		var m := _main()
		if m != null:
			m.set_meta("tb_lessons", int(m.get_meta("tb_lessons", 0)) + 1)


func _strip(dir: Vector2, blast: bool) -> void:
	if not _has_ball:
		return
	_lesson()
	_has_ball = false
	strips += 1
	_ball = 0
	if Art.on_screen(z, z.global_position):
		_twig_burst(z.global_position + Vector2(0, -BALL_R), 12 if not blast else 16, Vector2(dir.x, -1.0))
	Sfx.play("tb_snap", z.global_position, 2.0, 0.0, 2)
	var m := _main()
	if int(m.get_meta("tb_strip_pop", 0)) < 3:
		m.set_meta("tb_strip_pop", int(m.get_meta("tb_strip_pop", 0)) + 1)
		z._popup("STRIPPED!", Color("ffd34a"), 15, -60.0)
	_unroll_now(false)
	_t = 0.7


func _burn_ball() -> void:
	if not _has_ball:
		return
	_lesson()
	_has_ball = false
	burns += 1
	Sfx.play("tb_burn", z.global_position, 2.0, 0.0, 2)
	var m := _main()
	if Art.on_screen(z, z.global_position):
		Particles.burst(m, z.global_position + Vector2(0, -BALL_R), "fire", Vector2.UP, Quality.scaled(18, 1.0))
		Particles.burst(m, z.global_position + Vector2(0, -BALL_R), "smoke", Vector2(_wind(), -1.0), 8)
		_twig_burst(z.global_position + Vector2(0, -BALL_R), 6, Vector2.UP, true)
	if int(m.get_meta("tb_burn_pop", 0)) < 3:
		m.set_meta("tb_burn_pop", int(m.get_meta("tb_burn_pop", 0)) + 1)
		z._popup("BURNED!", Color("ff9a3a"), 15, -60.0)
	z.ignite(3.0)
	_unroll_now(false)
	_t = 0.8


func _twig_burst(p: Vector2, n: int, dir: Vector2, burnt := false) -> void:
	var m := _main()
	for i in Quality.scaled(n, 1.0):
		var dbr = DebrisScript.new()
		m.add_child(dbr)
		var c := Color("2a2018") if burnt else (Color("8a7048") if _dark else Color("c8a868"))
		dbr.setup(p + Vector2(randf_range(-10, 10), randf_range(-10, 10)), Vector2(randf_range(5, 10), 1.6), c.lightened(randf() * 0.15), Vector2(dir.x * randf_range(60, 220) + _wind() * 140.0, dir.y * randf_range(80, 240) - 60.0))


func on_death() -> void:
	var pl := player()
	if pl != null and pl.grabbed_by == z:
		pl.grabbed_by = null
	if _has_ball and _balled():
		_lesson()
		if Art.on_screen(z, z.global_position):
			_twig_burst(z.global_position + Vector2(0, -BALL_R), 10, Vector2.UP)
		_has_ball = false
	_ball_shape(false)


# ============================================================
#  ציור
# ============================================================
func wants_redraw() -> bool:
	return true


static func _seg(pts: PackedVector2Array, cols: PackedColorArray, a: Vector2, b: Vector2, w: float, c: Color) -> void:
	var n := (b - a).orthogonal().normalized() * w * 0.5
	pts.append_array([a - n, a + n, b + n, a - n, b + n, b - n])
	cols.append_array([c, c, c, c, c, c])


func draw() -> bool:
	if not z.dead and _balled() and _open < 0.5:
		return _draw_ball()
	begin_draw()
	_draw_body()
	end_draw()
	return true


# הכדור: ענפים מסובכים שמסתובבים, קוצים, ובפנים צללית מכורבלת + עין אדומה + יד
func _draw_ball() -> bool:
	var s := Vector2(z.sc, z.sc)
	var c := Vector2(0, -BALL_R)
	var squash := 1.0
	if z.is_on_floor() and state == ROLL:
		squash = 0.94
	z.draw_set_transform_matrix(Transform2D(0.0, s, 0.0, Vector2.ZERO))
	Art.ground_shadow(z, Vector2.ZERO, BALL_R * 0.9)
	var R := BALL_R
	var k := clampf(float(_ball) / float(BALL_HP), 0.0, 1.0) if _has_ball else 0.0
	# בפנים: הגוף המכורבל (נראה יותר ככל שהענפים נתלשים)
	var inner := col(Color("3a2e22").lerp(_poncho, 0.25))
	z.draw_colored_polygon(Art.ellipse(c + Vector2(0, 2), R * 0.62, R * 0.55 * squash, _roll_a * 0.15, 14), inner)
	z.draw_colored_polygon(Art.ellipse(c + Vector2.from_angle(_roll_a * 0.5 + 2.0) * R * 0.25, R * 0.3, R * 0.22, _roll_a * 0.5, 10), col(_poncho.darkened(0.25)))   # גב הפונצ'ו
	var sk := col(z.skin)
	var ra := _roll_a
	var hand := c + Vector2.from_angle(ra * 0.5 + 0.8) * R * 0.7
	z.draw_line(c + Vector2.from_angle(ra * 0.5 + 0.8) * R * 0.2, hand, sk, 3.0)
	for q in 3:   # אצבעות
		z.draw_line(hand, hand + Vector2.from_angle(ra * 0.5 + 0.8 + (float(q) - 1.0) * 0.4) * 4.0, sk, 1.2)
	var eye := c + Vector2.from_angle(ra * 0.5 + 2.6) * R * 0.32
	z.draw_circle(eye, 2.6, col(Art.shade(z.skin, 0.3)))
	z.draw_circle(eye, 1.2, Color(1.0, 0.25, 0.15))
	Art.glow(z, eye, 4.0, Color(1.0, 0.3, 0.15, 0.35))
	# ענפים (מערך משולשים אחד)
	var pts := PackedVector2Array()
	var cols := PackedColorArray()
	var base := Color("8a7048") if _dark else Color("c8a868")
	if z._flash > 0.0:
		base = Color.WHITE
	var nt := int(round(float(_twigs.size()) * (0.25 + 0.75 * k)))
	for i in nt:
		var tw: Array = _twigs[i]
		var a1: float = float(tw[0]) + ra
		var a2: float = float(tw[2]) + ra
		var p1 := c + Vector2(cos(a1) * R * float(tw[1]), sin(a1) * R * float(tw[1]) * squash)
		var p2 := c + Vector2(cos(a2) * R * float(tw[3]), sin(a2) * R * float(tw[3]) * squash)
		var mid := (p1 + p2) * 0.5
		mid = c + (mid - c) * 1.25   # קשת החוצה (כדור)
		var cc := base.lightened(float(tw[5])) if float(tw[5]) > 0.0 else base.darkened(-float(tw[5]))
		_seg(pts, cols, p1, mid, float(tw[4]), cc)
		_seg(pts, cols, mid, p2, float(tw[4]) * 0.8, cc)
	var thc := base.darkened(0.35)
	for i in int(round(float(_thorns.size()) * (0.2 + 0.8 * k))):
		var th: Array = _thorns[i]
		var a: float = float(th[0]) + ra
		var p := c + Vector2(cos(a), sin(a) * squash) * R * float(th[1])
		_seg(pts, cols, p, p + Vector2(cos(a), sin(a)) * float(th[2]), 0.9, thc)
	if not pts.is_empty():
		RenderingServer.canvas_item_add_triangle_array(z.get_canvas_item(), PackedInt32Array(), pts, cols)
	if state == SNAG:   # נתקע בתיל
		z.draw_line(c + Vector2(-R - 4, -4), c + Vector2(R + 4, 2), Color("3a3634"), 1.4)
	z.draw_set_transform_matrix(Transform2D.IDENTITY)
	return true


func _draw_body() -> void:
	var sk := col(z.skin)
	var skd := col(Art.shade(z.skin, 0.22))
	var po := col(z.shirt)
	var pod := col(Art.shade(z.shirt, 0.3))
	var f: Array = feet(5.0, 2.4)
	var crouch := 0.0
	var hand_f := Vector2(12, -30)
	var hand_b := Vector2(-6, -24)
	var dead: bool = z.dead
	match state:
		UNROLL:   # נפתח: ידיים פרושות לצדדים (האזהרה)
			crouch = 6.0 * (1.0 - _open)
			hand_f = Vector2(18, -50)
			hand_b = Vector2(-12, -50)
		GRAB:
			hand_f = Vector2(20, -34)
			hand_b = Vector2(16, -40)
			f = [Vector2(6, 0), Vector2(-5, 0)]
		STUN:
			hand_f = Vector2(8, -18)
			hand_b = Vector2(-10, -20)
		CURL:
			crouch = 14.0
		WALK:
			hand_f = Vector2(14.0 + sin(z._walk_phase) * 3.0, -32.0)
			hand_b = Vector2(-2.0 - sin(z._walk_phase) * 3.0, -28.0)
	if dead:
		hand_f = Vector2(10, -26)
		hand_b = Vector2(-6, -22)
	var hip := Vector2(-1, -23.0 + crouch)
	var sh := Vector2(4, -41.0 + crouch * 1.4)
	# הכדור על הגב כמו גלימה (אם נשאר)
	if _has_ball and not dead:
		var pts := PackedVector2Array()
		var cols := PackedColorArray()
		var base := Color("8a7048") if _dark else Color("c8a868")
		var op := _open if state == UNROLL else 1.0
		if state == UNROLL or state == CURL:   # הכדור נפתח לשני חצאים סביבו
			var k := 1.0 - op * 0.6 if state == UNROLL else 0.6
			for half: float in [-1.0, 1.0]:
				var hc := Vector2(half * (8.0 + 16.0 * op), -24.0)
				for i in 26:
					var tw: Array = _twigs[i]
					var a1: float = float(tw[0]) * 0.5 + (0.0 if half > 0 else PI) - PI * 0.25
					var a2: float = float(tw[2]) * 0.5 + (0.0 if half > 0 else PI) - PI * 0.25
					_seg(pts, cols, hc + Vector2(cos(a1), sin(a1)) * BALL_R * float(tw[1]) * k, hc + Vector2(cos(a2), sin(a2)) * BALL_R * float(tw[3]) * k, float(tw[4]), col(base.lightened(float(tw[5]))))
		else:   # על הגב כמו גלימה
			var bc := sh + Vector2(-9, 9)
			for i in 30:
				var tw: Array = _twigs[i]
				var p1 := bc + Vector2(cos(float(tw[0])) * 15.0 * float(tw[1]), sin(float(tw[0])) * 19.0 * float(tw[1]))
				var p2 := bc + Vector2(cos(float(tw[2])) * 15.0 * float(tw[3]), sin(float(tw[2])) * 19.0 * float(tw[3]))
				_seg(pts, cols, p1, p2, float(tw[4]) * 1.1, col(base.lightened(float(tw[5]))))
		RenderingServer.canvas_item_add_triangle_array(z.get_canvas_item(), PackedInt32Array(), pts, cols)
	# רגליים + יד אחורית עם ענף קוצני כרוך
	z._leg(hip + Vector2(-3, 0), f[1], col(Art.shade(z.pants, 0.25)), skd, col(z.shoe))
	z._leg(hip + Vector2(3, 0), f[0], col(z.pants), sk, col(z.shoe))
	z._arm(sh + Vector2(-3, 2), sh + hand_b - Vector2(4, -41), skd, pod)
	_thorn_wrap(sh + Vector2(-3, 2), sh + hand_b - Vector2(4, -41))
	# פונצ'ו: משולש רחב עם פסים, קרוע בתחתית
	var wl: float = _wd() * z._dir
	var pon := PackedVector2Array([sh + Vector2(-10, 0), sh + Vector2(10, 1), hip + Vector2(11 + wl * 2.0, 4), hip + Vector2(5, 7), hip + Vector2(0, 3), hip + Vector2(-5, 8), hip + Vector2(-11 + wl * 3.0, 5)])
	Art.fill_shaded(z, pon, po, 0.15, 0.35)
	for q in 2:
		var yy := 10.0 + float(q) * 6.0
		z.draw_line(sh + Vector2(-9.0 + float(q) * 0.5, yy), sh + Vector2(10.0 - float(q) * 0.5, yy + 1.0), col(_scarf.darkened(0.2)), 1.3)
	for q in 4:   # ענפים קטנים שננעצו בגוף
		var bp := sh + Vector2(-6.0 + float(q) * 4.0, 4.0 + float(q % 2) * 8.0)
		z.draw_line(bp, bp + Vector2(-3.0 + float(q), -4.0), col(Color("6a5034")), 1.0)
	if not dead:
		Art.oval(z, sh + Vector2(2, 12), 3.0, 2.0, Color(0.45, 0.04, 0.04, 0.6), 0.3, Art.NONE)
	# ממחטה על הצוואר, מתנופפת ברוח
	z.draw_colored_polygon(PackedVector2Array([sh + Vector2(-4, -2), sh + Vector2(6, -2), sh + Vector2(1, 4)]), col(_scarf))
	z.draw_colored_polygon(PackedVector2Array([sh + Vector2(-4, -2), sh + Vector2(-3, 1), sh + Vector2(-4 + wl * 9.0, -3.0 + sin(z._time * 12.0) * 2.0)]), col(_scarf.darkened(0.15)))
	# ראש: שיער פרוע עם ענפים
	var head := sh + Vector2(4.0, -9.0)
	if state == UNROLL or state == GRAB:
		head += Vector2(2.0, 1.0)
	if not z._headless:
		z._head(head, sk)
		face(head)
		for q in 5:
			var a := -2.6 + float(q) * 0.45
			z.draw_line(head + Vector2.from_angle(a) * 5.0, head + Vector2.from_angle(a) * (9.0 + float(q % 2) * 3.0), col(Color("4a3a28")), 1.2)
		if not dead:
			z.draw_circle(head + Vector2(4.0, -1.0), 1.1, Color(1.0, 0.25, 0.15))
	# יד קדמית + ענף קוצני
	z._arm(sh + Vector2(2, 2), sh + hand_f - Vector2(4, -41), sk, po)
	_thorn_wrap(sh + Vector2(2, 2), sh + hand_f - Vector2(4, -41))


func _thorn_wrap(a: Vector2, b: Vector2) -> void:
	var c := col(Color("4a3a24"))
	var n := (b - a).orthogonal().normalized()
	for q in 4:
		var u := 0.2 + float(q) * 0.22
		var p := a.lerp(b, u)
		var s := 1.0 if q % 2 == 0 else -1.0
		z.draw_line(p - n * 2.5 * s, p + n * 2.5 * s + (b - a).normalized() * 2.0, c, 1.1)
		z.draw_line(p + n * 2.5 * s, p + n * 5.0 * s, c, 0.8)
