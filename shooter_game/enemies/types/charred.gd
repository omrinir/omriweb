extends "res://enemies/zombie_type.gd"
# ============================================================
#  CHARRED (שלב 59, "BLACK FOREST") - מת שנשרף ונהיה פחם: קליפה שחורה של "עור תנין" עם סדקים לוחשים בכתום,
#    עיניים של גחלים, עשן עולה מהכתפיים. חלק עם קסדה צהובה חרוכה של כבאי יער (brigadista). הולך כפוף ונוקשה.
#  מה הם למדו: "האש לא עובדת עכשיו" (FIRE DOESN'T WORK NOW). הגיבור שרף אלפים - להביור, בקבוקי תבערה, חביות.
#    הנבגים של מי שנשרף נשאו את הלקח: האש אוכלת בשר, לא פחם. אז הם התגלגלו באפר הלוחש עד שנהיו פחם בעצמם.
#  קליפה (crust): שני צדדים - פנים (FRONT) וגב (BACK), CRUST_HP כל אחד. כדור שפוגע בצד עם קליפה - רק סודק אותה
#    (רסיסי פחם וגצים עפים, הגוף לא נפגע). הצד נשבר ("CRACKED") = הבשר הלוחש חשוף, x CRACK_MULT (גם לראש!).
#    פיצוץ סודק את שני הצדדים (BLAST_CRUST). במים (בריכות הבונים) הקליפה רכה: x WATER_MULT לקליפה, והאש נכבית.
#  אש: לא פוגעת - מאכילה אותו. בעירה (קו אש / בקבוק / קליעי אש / להביור) = מרפא (FIRE_HEAL), הקליפה גדלה מחדש (REGROW),
#    ו-STOKED: מהיר יותר (STOKE_SPEED) לכמה שניות. "IT DRINKS THE FIRE".
#  התקפה: SWIPE - מרים את הטפרים הלוחשים (WIND_T) ומכה (DMG).
#  בעשן (stage_59.smoke_k): כשהוא רחוק ממך הוא נבלע - רואים רק את הסדקים והעיניים (_vis). הבזק של ירייה קרובה מאיר אותו.
#  "THEY LEARN" (main meta "ch_cracks" - כמה צדדים שברת):
#    >= HIDE_LEARN: "IT HIDES ITS CRACKS NOW" - צד שבור מסתובב ממך: הולך אליך עם הגב השלם (אחורה, לאט יותר),
#       ומסתובב רק כדי להכות. נגד: לחכות למכה / לעבור לצד השני / רימון.
#    >= ROLL_LEARN: "IT ROLLS IN THE ASH NOW" - כשצד שבור והוא לא צמוד אליך: נופל ומתגלגל באפר (ROLL_T) ומתכסה
#       בקליפה דקה (ASHED_HP), עד ROLL_MAX פעמים. בזמן הגלגול חשוף (x ROLL_MULT). נגד: לירות בו כשהוא מתגלגל.
#  מוות: מתפורר לערימת פחם (Cinders - כל הרסיסים בקריאת ציור אחת), ענן אפר, גושי דם (Quality.gore()).
#  בוס (chase_range > 600): "THE PYRE" - מדורה מהלכת: עשרות גופות חרוכות שהתמזגו עם בולי עץ בוערים, ראשים וידיים יוצאים
#    מהערימה, להבות למעלה. קליפה עבה מלפנים (BOSS_CRUST) - מאחוריה הליבה הלוחשת (CORE_MULT). הגב דק (BOSS_BACK).
#    הקליפה גדלה מחדש אחרי BOSS_QUIET שניות בלי פגיעה. אש מרפאת אותו.
#    SWEEP - מקרוב (SWEEP_WIND): זרוע של גופות ובולים סוחפת (SWEEP_DMG).
#    HURL  - תולש בול בוער וזורק בקשת (BurningLog - אפשר לירות בו באוויר). נוחת = גחלים על הקרקע (EmberPatch). מתחת ל-50%: שניים.
#    RING  - מתחת ל-75%, כל RING_EVERY: רוקע - שני גלי אש רצים על הרצפה לשני הצדדים (FireWave) - לקפוץ.
#            למד ("IT READS YOUR JUMP"): אחרי JUMP_LEARN קפיצות מעל הגל - שולח גל שני (RING_GAP) שנוחת איפה שאתה נוחת.
#    SHED  - ב-66% וב-33%: שואג, נשל של גופות נופל ממנו - הליבה חשופה לרגע, שני CHARRED בוערים קמים מהנשל, ואז נשל חדש מכסה את הליבה.
#  צלילים: "ch_chip", "ch_crack", "ch_hiss", "ch_crumble", "ch_swipe", "ch_roll", "ch_step", "py_roar", "py_stomp", "py_wave", "py_log".
#  לשנות: CRUST_HP, CRACK_MULT, BLAST_CRUST, WATER_MULT, FIRE_HEAL, REGROW, STOKE_T, STOKE_SPEED, SWIPE_R, WIND_T, DMG,
#    HIDE_LEARN, ROLL_LEARN, ROLL_T, ROLL_MAX, ROLL_MULT, ASHED_HP; בוס: BOSS_CRUST, BOSS_BACK, BOSS_QUIET, BOSS_REGROW, CORE_MULT,
#    SWEEP_*, HURL_*, RING_EVERY, RING_GAP, WAVE_V, JUMP_LEARN, SHED_AT.
# ============================================================

const SOUNDS := {
	"ch_chip": [["C", 0, 0, 0.0, 0.08, 0.0, 40.0, 0.8, 1.0, 0], ["N", 0, 0, 0.0, 0.06, 0.0, 50.0, 0.45, 0.45, 0, 0.4], ["S", 900, 600, 0.0, 0.05, 0.0, 60.0, 0.12, 1.0, 0]],
	"ch_crack": {"rev": 0.15, "drive": 1.8, "layers": [["C", 0, 0, 0.0, 0.3, 0.0, 10.0, 1.0, 1.0, 0], ["N", 0, 0, 0.0, 0.25, 0.0, 12.0, 0.75, 0.55, 0, 0.3], ["S", 160, 70, 0.0, 0.2, 0.0, 14.0, 0.45, 1.0, 0]]},
	"ch_hiss": [["N", 0, 0, 0.0, 0.6, 0.02, 3.5, 0.5, 0.85, 0, 0.6], ["C", 0, 0, 0.0, 0.5, 0.0, 5.0, 0.5, 1.0, 0]],
	"ch_crumble": {"rev": 0.25, "drive": 1.6, "layers": [["C", 0, 0, 0.0, 0.7, 0.0, 4.0, 1.0, 1.0, 0], ["N", 0, 0, 0.0, 0.8, 0.0, 4.0, 0.7, 0.3, 0, 0.2], ["S", 110, 50, 0.0, 0.4, 0.0, 8.0, 0.45, 1.0, 0]]},
	"ch_swipe": [["N", 0, 0, 0.0, 0.22, 0.02, 10.0, 0.6, 0.5, 0.4, 0.2], ["C", 0, 0, 0.0, 0.15, 0.0, 14.0, 0.45, 1.0, 0]],
	"ch_roll": [["N", 0, 0, 0.0, 1.0, 0.1, 2.2, 0.5, 0.25, 0.5, 0.1], ["C", 0, 0, 0.0, 1.0, 0.1, 2.2, 0.45, 1.0, 0]],
	"ch_step": [["C", 0, 0, 0.0, 0.08, 0.0, 30.0, 0.5, 1.0, 0], ["N", 0, 0, 0.0, 0.08, 0.0, 30.0, 0.35, 0.3, 0]],
	"py_roar": {"rev": 0.4, "drive": 2.8, "layers": [["V", 62, 40, 0.0, 1.8, 0.1, 1.3, 1.0, 1.0, 0.07, 0, [420, 760, 24]], ["C", 0, 0, 0.0, 1.6, 0.05, 1.6, 0.9, 1.0, 0], ["N", 0, 0, 0.0, 1.6, 0.1, 1.6, 0.5, 0.15, 0]]},
	"py_stomp": {"rev": 0.3, "drive": 2.4, "layers": [["N", 0, 0, 0.0, 0.5, 0.0, 8.0, 1.0, 0.2, 0], ["S", 55, 26, 0.0, 0.5, 0.0, 7.0, 1.0, 1.0, 0], ["C", 0, 0, 0.0, 0.5, 0.0, 6.0, 0.9, 1.0, 0]]},
	"py_wave": {"rev": 0.3, "layers": [["N", 0, 0, 0.0, 1.2, 0.05, 2.0, 0.8, 0.25, 0, 0.1], ["C", 0, 0, 0.0, 1.2, 0.0, 2.0, 0.9, 1.0, 0], ["S", 120, 60, 0.0, 0.8, 0.05, 3.0, 0.3, 1.0, 0.3]]},
	"py_log": [["N", 0, 0, 0.0, 0.4, 0.02, 5.0, 0.6, 0.3, 0.3, 0.1], ["C", 0, 0, 0.0, 0.5, 0.0, 5.0, 0.6, 1.0, 0]],
}

const Decor := preload("res://effects/s59_decor.gd")
const Hazard := preload("res://environment/hazard.gd")
const Registry := preload("res://enemies/zombie_registry.gd")
const DebrisScript := preload("res://debris.gd")

enum { FRONT, BACK }
const CRUST_HP := 30.0
const CRACK_MULT := 1.6           # צד שבור: הבשר הלוחש
const BLAST_CRUST := 40.0         # פיצוץ: מכל צד
const WATER_MULT := 2.0           # במים: הקליפה רכה
const INC_CHIP := 0.5             # קליעי אש: רק חצי סדק, והגוף לא נפגע (מאכיל אותו)
const FIRE_HEAL := 7.0            # חיים לשנייה בזמן בעירה
const REGROW := 12.0              # קליפה לשנייה בזמן בעירה
const STOKE_T := 2.5
const STOKE_SPEED := 1.35
const SWIPE_R := 46.0
const WIND_T := 0.45
const STRIKE_T := 0.16
const RECOVER_T := 0.5
const DMG := 1
const CD := Vector2(0.9, 1.5)
const HIDE_LEARN := 2
const ROLL_LEARN := 4
const ROLL_T := 1.3
const ROLL_MAX := 2
const ROLL_MULT := 1.4
const ASHED_HP := 18.0
const SMOKE_R := 230.0            # בעשן: מעבר לזה הוא נבלע
# בוס
const BOSS_CRUST := 160.0
const BOSS_BACK := 36.0
const BOSS_QUIET := 3.5
const BOSS_REGROW := 9.0
const CORE_MULT := 1.2
const SWEEP_R := 140.0
const SWEEP_WIND := 0.65
const SWEEP_DMG := 2
const HURL_WIND := 0.6
const HURL_R := Vector2(230.0, 900.0)
const HURL_DMG := 1
const RING_EVERY := 9.0
const RING_GAP := 0.42
const RING_DMG := 2
const WAVE_V := 360.0
const JUMP_LEARN := 2
const SHED_AT := [0.66, 0.33]
const BOSS_CD := Vector2(1.0, 1.7)

enum { WALK, WIND, STRIKE, RECOVER, ROLL, SWEEP_W, SWEEP, HURL_W, HURL, STOMP_W, STOMP, SHED }
var state := WALK
# לבדיקות
var chips := 0
var cracks := 0
var fire_fed := 0.0
var healed := 0
var regrown := 0.0
var swipes := 0
var swipe_hits := 0
var hides := 0.0
var rolls := 0
var doused := 0
var blasts := 0
var sweeps := 0
var sweep_hits := 0
var hurls := 0
var hurl_hits := 0
var logs_shot := 0
var rings := 0
var ring_hits := 0
var jumped := 0
var sheds := 0
var hiding := false

var crust := [CRUST_HP, CRUST_HP]
var crust_max := [CRUST_HP, CRUST_HP]
var _ashed := [false, false]
var _hit_kind := "crust"
var _st := 0.0
var _cd := 1.0
var _since_hit := 0.0
var _met := false
var _hit_done := false
var _stoke := 0.0
var _heal_acc := 0.0
var _step := 0.0
var _vis := 1.0
var _wet := false
var _wet_t := 0.0
var _rolls_left := ROLL_MAX
var _roll_a := 0.0
var _ring_cd := 5.0
var _hurl_n := 0
var _shed_i := 0
var _rage := 0.0
var _seed := 0
var _helmet := false
var _crack_fx := 0.0
var _learn_h := false
var _learn_r := false
var _told := false


func _boss() -> bool:
	return z != null and float(z.chase_range) > 600.0


func stats() -> Dictionary:
	if _boss():
		return {"name": "CHARRED", "hp": 340, "walk": 30.0, "chase": 48.0, "damage": 2, "bite_delay": 1.2, "scale": 2.4, "width": 1.25,
			"duck": 0.0, "cover": 0.0, "skin": Color("2a2422"), "shirt": Color("1a1716"), "pants": Color("1a1716"), "shoe": Color("100e0d"),
			"points": 3000, "boss": true, "boss_name": "THE PYRE", "ragdoll": false, "flesh": _hit_kind == "cracked"}
	return {"name": "CHARRED", "hp": 44, "walk": 34.0, "chase": 66.0, "damage": 1, "bite_delay": 1.0, "scale": 1.08, "width": 1.1,
		"duck": 0.0, "cover": 0.0, "skin": Color("2a2422"), "shirt": Color("1c1a19"), "pants": Color("181615"), "shoe": Color("100e0d"),
		"points": 480, "ragdoll": false, "flesh": _hit_kind == "cracked" or _hit_kind == "roll"}


func use_brain_movement() -> bool:
	return false


func can_bite() -> bool:
	return false


func death_sound() -> String:
	return "ch_crumble"


func setup() -> void:
	var r := RandomNumberGenerator.new()
	r.seed = z.get_instance_id()
	_seed = r.randi()
	_helmet = r.randf() < 0.4
	var m := _main()
	_learn_h = not _boss() and m != null and int(m.get_meta("ch_cracks", 0)) >= HIDE_LEARN
	_learn_r = not _boss() and m != null and int(m.get_meta("ch_cracks", 0)) >= ROLL_LEARN
	if _boss():
		crust = [BOSS_CRUST, BOSS_BACK]
		crust_max = [BOSS_CRUST, BOSS_BACK]
		var rs := z._shape.shape as RectangleShape2D
		rs.size = Vector2(50.0 * z.wf * z.sc, 66.0 * z.sc)
		z._shape.position = Vector2(0.0, -33.0 * z.sc)
	if z.has_meta("ch_stoked"):   # קם מהנשל של THE PYRE - בוער
		_stoke = STOKE_T * 1.6
		z.ignite(3.0)
	_step = randf() * 0.5


func _main() -> Node:
	return z.get_parent()


func _stage() -> Node:
	var m := _main()
	return m.get("_stage") if m != null else null


func cracked(side: int) -> bool:
	return crust[side] <= 0.0


func stoked() -> bool:
	return _stoke > 0.0


func rolling() -> bool:
	return state == ROLL


# ============================================================
#  תנועה
# ============================================================
func physics(pl: Node, delta: float) -> bool:
	_st -= delta
	_cd -= delta
	_since_hit += delta
	_step -= delta
	_crack_fx = maxf(0.0, _crack_fx - delta * 2.0)
	if not z.is_on_floor():
		z.velocity.y += z.gravity * delta
	var has: bool = pl != null and not pl.dead
	var d: Vector2 = (pl.global_position - z.global_position) if has else Vector2.ZERO
	_fire_tick(delta)
	_vis_tick(has, d, delta)
	if not _met and has and (absf(d.x) < z.chase_range or z._alert_t > 0.0):
		_met = true
		z._noticed = true
		if _boss():
			Game.story.emit("boss", {"z": z})
			Sfx.play("py_roar", z.global_position, 3.0, 0.0, 1)
			z._popup("THE PYRE", Color("ff9a4a"), 22, -175.0)
	if _boss():
		_boss_physics(pl, has, d, delta)
		z.move_and_slide()
		return true
	match state:
		WALK:
			_walk(pl, has, d, delta)
		WIND:
			z.velocity.x = move_toward(z.velocity.x, 0.0, 1200.0 * delta)
			if has and _st > WIND_T * 0.4:   # מסתובב אליך כדי להכות (גם כשהוא הסתיר את הסדק)
				z._dir = signf(d.x) if absf(d.x) > 4.0 else z._dir
			if _st <= 0.0:
				state = STRIKE
				_st = STRIKE_T
				_hit_done = false
				swipes += 1
				Sfx.play("ch_swipe", z.global_position, -2.0, 0.15, 3)
		STRIKE:
			z.velocity.x = move_toward(z.velocity.x, z._dir * 60.0, 1500.0 * delta)
			if has and not _hit_done and absf(d.x) < (SWIPE_R + 12.0) * z.sc and d.x * z._dir > -10.0 and absf(d.y + 10.0) < 50.0:
				_hit_done = true
				if pl._roll_t <= 0.0:
					swipe_hits += 1
				pl.hurt(DMG, Vector2(z._dir * 1.2, -0.4))
				if Art.on_screen(z, z.global_position):
					Particles.burst(_main(), pl.global_position + Vector2(0, -30), "spark", Vector2(z._dir, -0.5), 5)
			if _st <= 0.0:
				state = RECOVER
				_st = RECOVER_T
		RECOVER:
			z.velocity.x = move_toward(z.velocity.x, 0.0, 1200.0 * delta)
			if _st <= 0.0:
				state = WALK
				_cd = randf_range(CD.x, CD.y)
		ROLL:
			_roll_tick(delta)
	z.move_and_slide()
	return true


func _walk(pl: Node, has: bool, d: Vector2, delta: float) -> void:
	var v := 0.0
	hiding = false
	if has and _met:
		var toward: float = signf(d.x) if absf(d.x) > 4.0 else z._dir
		var spd: float = float(z.chase_speed) * (STOKE_SPEED if stoked() else 1.0) * (0.75 if _wet else 1.0)
		# למד: צד שבור מסתובב ממך - הולך אליך עם הגב השלם
		if _learn_h and absf(d.x) < 520.0 and absf(d.x) > SWIPE_R * z.sc and cracked(FRONT) and not cracked(BACK):
			hiding = true
			hides += delta
			z._dir = -toward
			v = toward * spd * 0.7
			_tell_hide(pl)
		else:
			z._dir = toward
			if absf(d.x) > SWIPE_R * z.sc * 0.8:
				v = z._dir * spd
		# למד: מתגלגל באפר כשצד שבור ואתה לא צמוד
		if _learn_r and _rolls_left > 0 and (cracked(FRONT) or cracked(BACK)) and absf(d.x) > 150.0 and absf(d.x) < 600.0 and z.is_on_floor() and not _wet:
			_start_roll()
			return
		if _cd <= 0.0 and absf(d.x) < SWIPE_R * z.sc and absf(d.y) < 50.0 and z.is_on_floor():
			state = WIND
			_st = WIND_T * (0.75 if stoked() else 1.0)
			Sfx.play("ch_hiss", z.global_position, -10.0, 0.2, 2)
	z.velocity.x = move_toward(z.velocity.x, v, 700.0 * delta)
	z._walk_phase += delta * absf(z.velocity.x) / 14.0 * (-1.0 if hiding else 1.0)
	if absf(z.velocity.x) > 15.0 and _step <= 0.0 and Art.on_screen(z, z.global_position):
		_step = 0.42
		Sfx.play("ch_step", z.global_position, -14.0, 0.2, 2)
		if randf() < 0.4:
			Particles.burst(_main(), z.global_position + Vector2(-z._dir * 4.0, -2.0), "smoke", Vector2.UP, 1)
	if z.is_on_floor() and z.is_on_wall() and absf(z.velocity.x) < 20.0 and absf(d.x) > 60.0:
		z.velocity.y = -520.0


func _tell_hide(pl: Node) -> void:
	var m := _main()
	if m == null or m.has_meta("ch_told_hide"):
		return
	m.set_meta("ch_told_hide", true)
	z._popup("IT HIDES ITS CRACKS NOW", Color("ff9a4a"), 14, -96.0)
	if pl != null and pl.has_method("_say"):
		pl._say("It turns its cracked side away from me... wait for the swing.", Color("f0c890"))


func _start_roll() -> void:
	state = ROLL
	_st = ROLL_T
	_rolls_left -= 1
	rolls += 1
	_roll_a = 0.0
	Sfx.play("ch_roll", z.global_position, -2.0, 0.1, 2)
	var m := _main()
	if m != null and not m.has_meta("ch_told_roll"):
		m.set_meta("ch_told_roll", true)
		z._popup("IT ROLLS IN THE ASH NOW", Color("ff9a4a"), 14, -70.0)
		var pl := player()
		if pl != null and pl.has_method("_say"):
			pl._say("It's re-crusting itself in the ash! Shoot it while it rolls!", Color("f0c890"))


func _roll_tick(delta: float) -> void:
	z.velocity.x = move_toward(z.velocity.x, -z._dir * 40.0, 600.0 * delta)
	_roll_a += delta * 7.0
	if Engine.get_physics_frames() % 5 == 0 and Art.on_screen(z, z.global_position):
		Particles.burst(_main(), z.global_position + Vector2(randf_range(-10, 10), -4.0), "smoke", Vector2.UP, 2)
	if _st <= 0.0:   # קם עם קליפת אפר דקה
		for i in 2:
			if crust[i] < ASHED_HP:
				crust[i] = ASHED_HP
				_ashed[i] = true
		state = WALK
		_cd = 0.4
		_crack_fx = 1.0
		z._popup("ASHED", Color("b2aca4"), 13, -80.0)
		Sfx.play("ch_crack", z.global_position, -6.0, 0.2, 2)


# בעירה = מרפא + קליפה גדלה + STOKED. מים = כבוי, קליפה רכה
func _fire_tick(delta: float) -> void:
	_wet_t -= delta
	if _wet_t <= 0.0:
		_wet_t = 0.2
		var st := _stage()
		_wet = st != null and st.has_method("in_water_at") and bool(st.in_water_at(z.global_position))
	if _wet and (z._burn_t > 0.0 or _stoke > 0.0):
		z._burn_t = 0.0
		_stoke = 0.0
		doused += 1
		Sfx.play("ch_hiss", z.global_position, 0.0, 0.1, 2)
		Particles.burst(_main(), z.global_position + Vector2(0, -30.0 * z.sc), "mist", Vector2.UP, 6)
		if doused == 1:
			z._popup("DOUSED", Color("a0c8e0"), 13, -80.0 if not _boss() else -170.0)
	_stoke = maxf(0.0, _stoke - delta)
	if z._burn_t <= 0.0 or z.dead:
		return
	if _stoke <= 0.0 and not _boss():
		Sfx.play("ch_hiss", z.global_position, -4.0, 0.15, 2)
	_stoke = STOKE_T
	fire_fed += delta
	_heal_acc += FIRE_HEAL * delta * (2.0 if _boss() else 1.0)
	if _heal_acc >= 1.0:
		var a := int(_heal_acc)
		_heal_acc -= float(a)
		if z.hp < z.max_hp:
			z.hp = mini(z.max_hp, z.hp + a)
			healed += a
	for i in 2:
		if crust[i] < crust_max[i]:
			var g: float = minf(crust_max[i] - crust[i], (BOSS_REGROW * 2.0 if _boss() else REGROW) * delta)
			crust[i] += g
			regrown += g
	var m := _main()
	if m != null and not m.has_meta("ch_told_fire") and Art.on_screen(z, z.global_position):
		m.set_meta("ch_told_fire", true)
		z._popup("IT DRINKS THE FIRE", Color("ffb050"), 14, -96.0 if not _boss() else -175.0)
		var pl := player()
		if pl != null and pl.has_method("_say"):
			pl._say("Fire makes them stronger! Keep them out of the flames.", Color("f0c890"))


# בעשן: רחוק ממך = נבלע (רק הסדקים והעיניים). הבזק קרוב מאיר אותו לרגע
func _vis_tick(has: bool, d: Vector2, delta: float) -> void:
	var target := 1.0
	var st := _stage()
	if has and st != null and st.has_method("smoke_k") and not _boss():
		var s: float = st.smoke_k()
		if s > 0.02:
			var far := clampf((absf(d.x) - SMOKE_R) / 260.0, 0.0, 1.0)
			target = 1.0 - s * far * 0.88
			if st.has_method("flash_age") and float(st.flash_age()) < 0.12:
				target = maxf(target, 0.85)
	_vis = move_toward(_vis, target, delta * 3.0)


# ============================================================
#  נזק: קליפה / בשר לוחש
# ============================================================
func on_damage(amount: int, hit_pos: Vector2, dir: Vector2, src: Dictionary) -> bool:
	if z.dead:
		return true
	var s := str(src.get("source", "bullet"))
	_since_hit = 0.0
	if s == "fire" or s == "s59_ember":   # האש מאכילה אותו (בעירה מטופלת ב-_fire_tick)
		return false
	if s == "bullet" or s == "melee":
		var side := FRONT if dir.x * z._dir < 0.0 or dir.x == 0.0 else BACK
		if state == ROLL:
			_hit_kind = "roll"
			return true
		var dmg := float(hit_damage(amount, hit_pos, src))
		if src.get("incendiary", false):   # קליעי אש: סדק חלש, והגוף לא נפגע - הוא בולע את האש
			z.ignite(2.5)
			if crust[side] > 0.0:
				_crust_damage(side, dmg * INC_CHIP, hit_pos, -dir)
			z._flash = 0.03
			return false
		if crust[side] > 0.0:
			_crust_damage(side, dmg * (WATER_MULT if _wet else 1.0), hit_pos, -dir)
			z._flash = 0.04
			Game.on_zombie_hit({"source": "bullet", "zone": "crust", "shot": src.get("shot", 0)})
			return false
		_hit_kind = "cracked"
		if Art.on_screen(z, hit_pos):
			Particles.burst(_main(), hit_pos, "spark", -dir, 3)
		return true
	# פיצוץ / מלכודת: סודק את שני הצדדים, הגוף נפגע
	if src.has("blast") or s in ["grenade", "barrel", "rocket", "launcher", "molotov", "s59_snag", "crash"]:
		blasts += 1
		for i in 2:
			_crust_damage(i, BLAST_CRUST * (0.6 if _boss() else 1.0), z.global_position + Vector2(0, -34.0 * z.sc), -dir if dir != Vector2.ZERO else Vector2.UP)
	_hit_kind = "blast"
	return true


func damage_mult(_zone: String, _src: Dictionary) -> float:
	match _hit_kind:
		"cracked":
			return CORE_MULT if _boss() else CRACK_MULT
		"roll":
			return ROLL_MULT
	return 1.0


func _crust_damage(side: int, dmg: float, pos: Vector2, out: Vector2) -> void:
	if crust[side] <= 0.0 or dmg <= 0.0:
		return
	chips += 1
	crust[side] -= dmg
	var on := Art.on_screen(z, pos, 80.0)
	if on:
		Cinders.spray(_main(), pos, out if out != Vector2.ZERO else Vector2.UP, 2 + int(dmg / 10.0), z.global_position.y, 0.6 * z.sc)
		Sfx.play("ch_chip", pos, -4.0, 0.2, 4)
		if randf() < 0.4:
			Particles.burst(_main(), pos, "spark", out, 2)
	if crust[side] > 0.0:
		return
	crust[side] = 0.0
	_ashed[side] = false
	cracks += 1
	_crack_fx = 1.0
	Sfx.play("ch_crack", pos, 2.0, 0.1, 3)
	if on:
		Cinders.spray(_main(), pos, out if out != Vector2.ZERO else Vector2.UP, 12, z.global_position.y, 0.9 * z.sc)
		Particles.burst(_main(), pos, "fire", out, 6)
	if _boss():
		z._popup("CORE EXPOSED" if side == FRONT else "BACK CRACKED", Color("ffd34a"), 18, -175.0)
		return
	z._popup("CRACKED", Color("ffd34a"), 15, -88.0)
	var m := _main()
	if m != null:
		m.set_meta("ch_cracks", int(m.get_meta("ch_cracks", 0)) + 1)


func on_death() -> void:
	var par: Node = z.get_parent()
	var y0: float = z.global_position.y
	var k := 1.0 if not _boss() else 3.0
	Cinders.spray(par, z.global_position + Vector2(0, -30.0 * z.sc), Vector2(0, -1), int(26.0 * k), y0, 1.0 * z.sc * 0.8)
	Cinders.spray(par, z.global_position + Vector2(0, -14.0 * z.sc), Vector2(0, -1), int(12.0 * k), y0, 1.2 * z.sc * 0.8)
	if Quality.gore() > 0.0:   # בשר לוחש מבפנים
		Cinders.spray(par, z.global_position + Vector2(0, -30.0 * z.sc), Vector2(0, -1), int(8.0 * k * Quality.gore()), y0, 0.7 * z.sc, Color(0.62, 0.1, 0.06))
		z._spray_blood(z.global_position + Vector2(0, -30.0 * z.sc), Vector2(0, -1), int(6.0 * k), 260.0)
	if Art.on_screen(z, z.global_position):
		Particles.burst(par, z.global_position + Vector2(0, -24.0 * z.sc), "smoke", Vector2.UP, int(8.0 * k))
		Particles.burst(par, z.global_position + Vector2(0, -24.0 * z.sc), "fire", Vector2.UP, int(5.0 * k))
	if _boss():
		Sfx.play("py_roar", z.global_position, 2.0, 0.0, 1, 0.7)
		var cam: Camera2D = z.get_viewport().get_camera_2d()
		if cam != null and cam.has_method("shake"):
			cam.shake(22.0, 1.0)
		var fl := PyreFlash.new()
		par.add_child(fl)
		fl.global_position = z.global_position + Vector2(0, -80.0)
		for i in 6:   # בולי עץ בוערים עפים
			var dbr = DebrisScript.new()
			par.add_child(dbr)
			dbr.setup(z.global_position + Vector2(randf_range(-40, 40), -randf_range(40, 120)), Vector2(randf_range(18, 30), randf_range(6, 9)), Color("3a2a1c"), Vector2(randf_range(-320, 320), -randf_range(200, 480)))
		for b in z.get_tree().get_nodes_in_group("py_logs"):
			b.shatter()
		for w in z.get_tree().get_nodes_in_group("py_waves"):
			w.queue_free()
	elif int(z.get_meta("ch_pop", 0)) == 0 and randf() < 0.35:
		z._popup("CRUMBLED", Color("b2aca4"), 13, -70.0)


# ============================================================
#  בוס: THE PYRE
# ============================================================
func _boss_physics(pl: Node, has: bool, d: Vector2, delta: float) -> void:
	_rage = move_toward(_rage, 1.0 - float(z.hp) / float(z.max_hp), delta)
	if not has or not _met:
		z.velocity.x = move_toward(z.velocity.x, 0.0, 600.0 * delta)
		return
	_ring_cd -= delta
	# קליפה גדלה מחדש כשלא פוגעים בו
	if _since_hit > BOSS_QUIET:
		for i in 2:
			if crust[i] < crust_max[i]:
				crust[i] = minf(crust_max[i], crust[i] + BOSS_REGROW * delta)
				regrown += BOSS_REGROW * delta
	# נשל: ב-66% / 33%
	if _shed_i < SHED_AT.size() and float(z.hp) < float(z.max_hp) * float(SHED_AT[_shed_i]) and state != SHED:
		_shed_i += 1
		state = SHED
		_st = 1.3
		Sfx.play("py_roar", z.global_position, 4.0, 0.0, 1)
		z._popup("IT SHEDS ITS DEAD", Color("ff9a4a"), 18, -175.0)
	match state:
		WALK:
			var want: float = signf(d.x) if absf(d.x) > 8.0 else z._dir
			z._dir = want
			var v := 0.0
			if absf(d.x) > 120.0:
				v = z._dir * float(z.chase_speed) * (1.3 if float(z.hp) < float(z.max_hp) * 0.5 else 1.0)
			z.velocity.x = move_toward(z.velocity.x, v, 400.0 * delta)
			z._walk_phase += delta * absf(z.velocity.x) / 20.0
			if absf(z.velocity.x) > 10.0 and _step <= 0.0:
				_step = 0.6
				Sfx.play("py_stomp", z.global_position, -8.0, 0.1, 2)
				if Art.on_screen(z, z.global_position):
					Particles.burst(_main(), z.global_position + Vector2(z._dir * 20.0, -4.0), "spark", Vector2.UP, 3)
			if _cd > 0.0:
				return
			var high: bool = d.y < -60.0
			if _ring_cd <= 0.0 and float(z.hp) < float(z.max_hp) * 0.75 and z.is_on_floor():
				state = STOMP_W
				_st = 0.8
				_ring_cd = RING_EVERY
				Sfx.play("py_roar", z.global_position, 0.0, 0.1, 1)
			elif absf(d.x) < SWEEP_R and not high and z.is_on_floor():
				state = SWEEP_W
				_st = SWEEP_WIND
				Sfx.play("ch_hiss", z.global_position, 2.0, 0.1, 2)
			elif absf(d.x) > HURL_R.x or high:
				state = HURL_W
				_st = HURL_WIND
				_hurl_n = 2 if float(z.hp) < float(z.max_hp) * 0.5 else 1
				Sfx.play("py_log", z.global_position, 0.0, 0.1, 2)
		SWEEP_W:
			z.velocity.x = move_toward(z.velocity.x, 0.0, 900.0 * delta)
			if _st > SWEEP_WIND * 0.4:
				z._dir = signf(d.x) if absf(d.x) > 8.0 else z._dir
			if _st <= 0.0:
				state = SWEEP
				_st = 0.4
				sweeps += 1
				_hit_done = false
				Sfx.play("ch_swipe", z.global_position, 6.0, 0.0, 1, 0.6)
				if Art.on_screen(z, z.global_position):
					Particles.burst(_main(), z.global_position + Vector2(z._dir * 60.0, -60.0), "fire", Vector2(z._dir, 0.2), 10)
		SWEEP:
			z.velocity.x = move_toward(z.velocity.x, z._dir * 80.0, 900.0 * delta)
			if not _hit_done and absf(d.x) < SWEEP_R + 20.0 and d.x * z._dir > -20.0 and d.y > -150.0 and absf(d.y) < 160.0:
				_hit_done = true
				if pl._roll_t <= 0.0:
					sweep_hits += 1
				pl.hurt(SWEEP_DMG, Vector2(z._dir * 1.8, -0.7))
			if _st <= 0.0:
				state = WALK
				_cd = randf_range(BOSS_CD.x, BOSS_CD.y)
		HURL_W:
			z.velocity.x = move_toward(z.velocity.x, 0.0, 900.0 * delta)
			z._dir = signf(d.x) if absf(d.x) > 8.0 else z._dir
			if _st <= 0.0:
				_hurl(pl)
				_hurl_n -= 1
				if _hurl_n > 0:
					_st = 0.45
				else:
					state = HURL
					_st = 0.5
		HURL:
			if _st <= 0.0:
				state = WALK
				_cd = randf_range(BOSS_CD.x, BOSS_CD.y)
		STOMP_W:
			z.velocity.x = move_toward(z.velocity.x, 0.0, 900.0 * delta)
			if _st <= 0.0:
				state = STOMP
				_st = 0.6
				_ring()
		STOMP:
			if _st <= 0.0:
				state = WALK
				_cd = randf_range(BOSS_CD.x, BOSS_CD.y) * 0.7
		SHED:
			z.velocity.x = move_toward(z.velocity.x, 0.0, 900.0 * delta)
			if _st <= 0.65 and _st + delta > 0.65:
				_shed()
			if _st <= 0.0:   # נשל חדש של גופות מכסה את הליבה
				crust[FRONT] = maxf(crust[FRONT], BOSS_CRUST * 0.75)
				_crack_fx = 1.0
				state = WALK
				_cd = 0.8


func _hand_pos() -> Vector2:
	return z.global_position + Vector2(z._dir * 8.0 * z.wf * z.sc, -76.0 * z.sc)


func _hurl(pl: Node) -> void:
	hurls += 1
	var b := BurningLog.new()
	b.owner_z = z
	z.get_parent().add_child(b)
	var from := _hand_pos()
	b.global_position = from
	var lead: Vector2 = pl.velocity * 0.3 if pl.is_on_floor() else Vector2.ZERO
	var to: Vector2 = pl.global_position + lead + Vector2(randf_range(-24, 24), -10.0)
	var tt := clampf(absf(to.x - from.x) / 520.0, 0.65, 1.3)
	b.vel = Vector2((to.x - from.x) / tt, (to.y - from.y - 0.5 * BurningLog.G * tt * tt) / tt)
	b.ground_y = pl.global_position.y if absf(pl.global_position.y - z.global_position.y) > 60.0 else z.global_position.y
	Sfx.play("whoosh", from, 2.0, 0.1, 2)


func _ring() -> void:
	rings += 1
	Sfx.play("py_stomp", z.global_position, 6.0, 0.0, 1)
	Sfx.play("py_wave", z.global_position, 2.0, 0.05, 1)
	var cam: Camera2D = z.get_viewport().get_camera_2d()
	if cam != null and cam.has_method("shake"):
		cam.shake(12.0, 0.4)
	_spawn_waves(0.0)
	var m := _main()
	if m != null and int(m.get_meta("py_jumps", 0)) >= JUMP_LEARN:   # למד: גל שני נוחת איפה שאתה נוחת
		_spawn_waves(RING_GAP)
		if not m.has_meta("py_told_jump"):
			m.set_meta("py_told_jump", true)
			z._popup("IT READS YOUR JUMP", Color("ff9a4a"), 18, -175.0)
			var pl := player()
			if pl != null and pl.has_method("_say"):
				pl._say("Two waves now... it learned I jump.", Color("f0c890"))


func _spawn_waves(delay: float) -> void:
	for s in [-1.0, 1.0]:
		var w := FireWave.new()
		w.owner_z = z
		w.dir = s
		w.delay = delay
		w.ground_y = z.global_position.y
		z.get_parent().add_child(w)
		w.global_position = z.global_position + Vector2(s * 40.0 * z.sc * 0.5, 0.0)


func _shed() -> void:
	sheds += 1
	crust[FRONT] = 0.0   # הליבה חשופה לרגע
	_crack_fx = 1.0
	var par := _main()
	Cinders.spray(par, z.global_position + Vector2(0, -60.0), Vector2.UP, 40, z.global_position.y, 2.0)
	Particles.burst(par, z.global_position + Vector2(0, -60.0), "fire", Vector2.UP, 14)
	Sfx.play("ch_crumble", z.global_position, 4.0, 0.0, 1)
	var cam: Camera2D = z.get_viewport().get_camera_2d()
	if cam != null and cam.has_method("shake"):
		cam.shake(10.0, 0.4)
	var st := _stage()
	if st == null or not st.has_method("spawn"):
		return
	for s in [-1.0, 1.0]:
		var x: float = clampf(z.global_position.x + s * 110.0, 40.0, float(st.level_w) - 60.0)
		var c = st.spawn(Registry.CHARRED, x)
		if c != null:
			c.set_meta("ch_stoked", true)
			c.chase_range = 520.0
			c._alert_t = 3.0


# הגל עבר מתחתיך (קפצת)
func on_wave_jumped() -> void:
	jumped += 1
	var m := _main()
	if m != null:
		m.set_meta("py_jumps", int(m.get_meta("py_jumps", 0)) + 1)


func wants_redraw() -> bool:
	return true


# ============================================================
#  ציור
# ============================================================
const CH := Color("1c1a19")
const CH_L := Color("3a3532")
const ASH := Color("6e6862")
const RAW := Color("8a2410")
const EMB := Color(1.0, 0.45, 0.1)
const EMB_L := Color(1.0, 0.78, 0.3)


# צבע של הגוף: לבן כשנפגע, שקוף בעשן
func _c(c: Color) -> Color:
	var r := col(c)
	r.a *= _vis
	return r


# צבע של הסדקים הלוחשים: נשארים גם בעשן
func _e(a: float) -> Color:
	var g := 0.55 + 0.25 * sin(z._time * 3.0 + float(_seed % 7)) + (0.35 if stoked() else 0.0) + _crack_fx * 0.5
	var c := EMB.lerp(EMB_L, clampf(g - 0.5, 0.0, 1.0))
	c.a = clampf(a * g, 0.0, 1.0) * maxf(_vis, 0.75)
	return c


func draw() -> bool:
	if _boss():
		return _draw_boss()
	if z.dead:
		return _draw_heap()
	if state == ROLL:
		return _draw_roll()
	begin_draw()
	var t: float = z._time
	var f: Array = feet(4.5, 2.0)
	var wind := 0.0
	if state == WIND:
		wind = clampf(1.0 - _st / (WIND_T * (0.75 if stoked() else 1.0)), 0.0, 1.0)
	elif state == STRIKE:
		wind = -1.0
	var lean := 3.0 if state == STRIKE else (-2.0 * wind if wind > 0.0 else 1.5)
	var hip := Vector2(0, -24)
	var sh := Vector2(2.0 + lean, -43)
	var head := sh + Vector2(2.5 + lean * 0.3, -7.0)
	var sk := _c(CH_L)
	# רגליים חרוכות
	z._leg(hip + Vector2(-2, 0), f[1], _c(Color("141211")), sk, _c(Color("0e0c0b")))
	z._leg(hip + Vector2(2, 0), f[0], _c(CH), sk, _c(Color("0e0c0b")))
	DrawBatch.line(z, hip + Vector2(2, 4), f[0] + Vector2(0, -6), _e(0.7), 0.9)
	# יד אחורית
	var hb := sh + Vector2(-3.0 + sin(t * 1.3), 14.0)
	if wind > 0.0:
		hb = sh + Vector2(-1.0, -15.0 * wind)
	elif state == STRIKE:
		hb = sh + Vector2(14.0, 6.0)
	_claw(sh + Vector2(-3, 1), hb, true)
	# גוף: קליפת פחם "עור תנין"
	var torso := PackedVector2Array([sh + Vector2(-7, -1), sh + Vector2(7, 1), hip + Vector2(6, 0), hip + Vector2(-7, -1)])
	Art.fill_shaded(z, torso, _c(CH), 0.1, 0.3)
	_crust_plates(sh, hip)
	# ראש
	_draw_head(head)
	# יד קדמית
	var hf := sh + Vector2(6.0 + sin(t * 1.5), 13.0)
	if wind > 0.0:
		hf = sh + Vector2(3.0, -17.0 * wind)
	elif state == STRIKE:
		hf = sh + Vector2(18.0, 4.0)
	_claw(sh + Vector2(4, 1), hf, false)
	if state == STRIKE:   # שובל גחלים של המכה
		for q in 3:
			DrawBatch.line(z, hf + Vector2(-12.0 + float(q) * 3.0, -10.0 + float(q) * 6.0), hf + Vector2(2.0, -4.0 + float(q) * 5.0), _e(0.8), 1.4)
	# עשן מהכתפיים
	if _vis > 0.3:
		for q in 2:
			var k := fmod(t * 0.5 + float(q) * 0.5 + float(_seed % 5) * 0.1, 1.0)
			DrawBatch.colored_polygon(z, Art.ellipse(sh + Vector2(-4.0 + float(q) * 6.0 - k * 6.0, -6.0 - k * 22.0), 2.0 + k * 5.0, 1.5 + k * 3.5, 0.0, 8), Color(0.25, 0.22, 0.21, 0.35 * (1.0 - k) * _vis))
	if _crack_fx > 0.0:
		Art.glow(z, Vector2(0, -32), 16.0, Color(1.0, 0.55, 0.15, 0.5 * _crack_fx))
	end_draw()
	return true


func _claw(s: Vector2, h: Vector2, back: bool) -> void:
	var el := Art.joint(s, h, 10.0, 10.5, -1.0 if back else 1.0)
	Art.limb(z, PackedVector2Array([s, el, h]), 3.4 if back else 3.8, _c(Color("161413") if back else CH))
	DrawBatch.line(z, s.lerp(el, 0.3), el, _e(0.55), 0.8)
	var d := (h - el).normalized()
	for q in 3:   # טפרים
		var a := d.rotated(-0.5 + float(q) * 0.5)
		DrawBatch.line(z, h, h + a * 4.0, _c(Color("2a2420")), 1.0)
	DrawBatch.circle(z, h, 1.0, _e(0.8))


# קליפת פחם: לוחות + סדקים לוחשים. צד שבור = בשר אדום-לוהט
func _crust_plates(sh: Vector2, hip: Vector2) -> void:
	var r := RandomNumberGenerator.new()
	r.seed = _seed
	# קדימה = ימין (x חיובי), אחורה = שמאל
	for side in 2:
		var sx := 1.0 if side == FRONT else -1.0
		if cracked(side):
			var raw := PackedVector2Array([sh + Vector2(0.5 * sx, 0), sh + Vector2(6.5 * sx, 1), hip + Vector2(6.0 * sx, -1), hip + Vector2(0.5 * sx, -1)])
			DrawBatch.colored_polygon(z, raw, _c(RAW))
			for q in 3:
				var y0 := lerpf(sh.y + 3.0, hip.y - 3.0, float(q) / 2.0)
				DrawBatch.line(z, Vector2(1.0 * sx, y0), Vector2(5.5 * sx, y0 + 2.0), _e(1.0), 1.3)
			DrawBatch.colored_polygon(z, Art.ellipse(Vector2(3.0 * sx, (sh.y + hip.y) * 0.5), 2.4, 4.0, 0.0, 8), _e(0.8))
			continue
		var full: float = crust_max[side]
		var dmg := clampf(1.0 - crust[side] / full, 0.0, 1.0)
		var ashed: bool = _ashed[side]
		for q in 4:   # לוחות אפורים-פחם
			var p := Vector2(sx * r.randf_range(1.0, 5.5), lerpf(sh.y + 3.0, hip.y - 2.0, r.randf()))
			DrawBatch.colored_polygon(z, Art.ellipse(p, r.randf_range(1.6, 2.6), r.randf_range(1.2, 2.0), r.randf() * 2.0, 6), _c(ASH if ashed else CH_L))
		var n := 2 + int(dmg * 4.0)
		for q in n:   # סדקים לוחשים, מתרבים לפי הנזק
			var a := Vector2(sx * r.randf_range(0.5, 5.5), lerpf(sh.y + 2.0, hip.y - 2.0, r.randf()))
			var b := a + Vector2(sx * r.randf_range(-2.5, 2.5), r.randf_range(2.0, 5.0))
			var c := b + Vector2(sx * r.randf_range(-2.0, 2.0), r.randf_range(1.5, 4.0))
			DrawBatch.polyline(z, PackedVector2Array([a, b, c]), _e(0.6 + 0.4 * dmg), 0.8 + dmg * 0.6)


func _draw_head(c: Vector2) -> void:
	Art.oval_shaded(z, c, 5.4, 6.0, _c(CH), 0.0)
	if cracked(FRONT):   # הפנים הלוחשות
		Art.oval(z, c + Vector2(2.5, 0.5), 3.0, 4.0, _c(RAW), 0.0, Art.NONE)
		DrawBatch.line(z, c + Vector2(1.0, -3.0), c + Vector2(4.0, 2.0), _e(1.0), 1.0)
	else:
		DrawBatch.polyline(z, PackedVector2Array([c + Vector2(-3, -4), c + Vector2(-1, -1), c + Vector2(-3, 2)]), _e(0.6), 0.7)
		DrawBatch.line(z, c + Vector2(1, -5), c + Vector2(3, -2), _e(0.5), 0.7)
	if cracked(BACK):
		Art.oval(z, c + Vector2(-3.0, 0.0), 2.0, 3.5, _c(RAW), 0.0, Art.NONE)
	# עיניים של גחלים + פה לוחש
	if not z.dead:
		DrawBatch.circle(z, c + Vector2(3.0, -1.0), 1.0, _e(1.2))
		DrawBatch.circle(z, c + Vector2(-0.8, -1.0), 0.8, _e(1.0))
		Art.glow(z, c + Vector2(3.0, -1.0), 3.5, Color(1.0, 0.5, 0.15, 0.45 * maxf(_vis, 0.7)))
	DrawBatch.colored_polygon(z, PackedVector2Array([c + Vector2(1.2, 2.4), c + Vector2(5.2, 1.9), c + Vector2(4.8, 4.4), c + Vector2(1.6, 4.2)]), _e(0.7))
	DrawBatch.line(z, c + Vector2(1.6, 2.6), c + Vector2(4.8, 2.2), _c(Color("2a2420")), 0.7)
	if _helmet:   # קסדת כבאי יער חרוכה
		var hc := _c(Color("7a6420"))
		Art.fill(z, PackedVector2Array([c + Vector2(-6, -1), c + Vector2(-5, -6), c + Vector2(0, -8.5), c + Vector2(5, -6), c + Vector2(7.5, -1.5)]), hc, Art.OUTLINE, 0.9)
		DrawBatch.line(z, c + Vector2(-6.5, -1.2), c + Vector2(8.5, -1.6), _c(Color("4a3a14")), 1.4)
		DrawBatch.colored_polygon(z, Art.ellipse(c + Vector2(1.0, -5.0), 2.5, 1.4, 0.0, 6), _c(Color("1c1a19")))


# מתגלגל באפר: כדור מכווץ שמסתובב
func _draw_roll() -> bool:
	var s := Vector2(z._dir * z.wf * z.sc, z.sc)
	DrawBatch.set_transform_matrix(z, Transform2D(0.0, Vector2(0.0, -12.0 * z.sc)) * Transform2D(-_roll_a * z._dir, s, 0.0, Vector2.ZERO))
	Art.oval_shaded(z, Vector2.ZERO, 14.0, 12.0, _c(CH), 0.0)
	for q in 5:
		var a := float(q) * 1.26
		DrawBatch.line(z, Vector2.from_angle(a) * 4.0, Vector2.from_angle(a + 0.3) * 11.0, _e(0.9), 1.0)
	DrawBatch.colored_polygon(z, Art.ellipse(Vector2(6, -6), 4.5, 5.0, 0.0, 8), _c(CH_L))
	DrawBatch.circle(z, Vector2(8, -6), 0.9, _e(1.2))
	for q in 3:   # אפר נדבק
		DrawBatch.colored_polygon(z, Art.ellipse(Vector2.from_angle(float(q) * 2.1) * 9.0, 3.0, 2.0, 0.0, 6), _c(ASH))
	end_draw()
	# ענן אפר סביבו (בלי סיבוב)
	var k := fmod(z._time * 1.5, 1.0)
	DrawBatch.colored_polygon(z, Art.ellipse(Vector2(0, -6.0 * z.sc), (16.0 + k * 10.0) * z.sc, (6.0 + k * 4.0) * z.sc, 0.0, 12), Color(0.55, 0.52, 0.5, 0.3 * (1.0 - k) * _vis))
	return true


# מת: ערימת פחם עם גחלים שדועכות
func _draw_heap() -> bool:
	var s := Vector2(z._dir * z.wf * z.sc * (2.2 if _boss() else 1.0), z.sc * (2.2 if _boss() else 1.0))
	DrawBatch.set_transform_matrix(z, Transform2D(0.0, s, 0.0, Vector2.ZERO))
	var fade := clampf(1.0 - z._time * 0.0, 0.0, 1.0)
	DrawBatch.colored_polygon(z, PackedVector2Array([Vector2(-14, 0), Vector2(-9, -6), Vector2(-2, -9), Vector2(6, -7), Vector2(13, -3), Vector2(15, 0)]), CH)
	DrawBatch.colored_polygon(z, PackedVector2Array([Vector2(-8, -5), Vector2(-3, -8), Vector2(3, -7), Vector2(0, -4)]), CH_L)
	DrawBatch.colored_polygon(z, Art.ellipse(Vector2(8, -4), 3.0, 2.6, 0.0, 8), Color("2a2422"))   # גולגולת
	DrawBatch.circle(z, Vector2(9, -4.5), 0.8, Color(1.0, 0.5, 0.15, 0.6 * fade))
	for q in 4:
		var g := 0.4 + 0.3 * sin(z._time * 2.0 + float(q) * 1.7)
		DrawBatch.line(z, Vector2(-10.0 + float(q) * 5.0, -2.0), Vector2(-8.0 + float(q) * 5.0, -5.0), Color(1.0, 0.45, 0.1, g * fade), 1.0)
	end_draw()
	return true


# ---- THE PYRE: מדורה מהלכת - בולים בצורת "טיפי" של מדורה, וגופות חרוכות שהתמזגו ביניהם ----
func _draw_boss() -> bool:
	if z.dead:
		return _draw_heap()
	begin_draw()
	var t: float = z._time
	var p: float = z._walk_phase
	var moving: bool = absf(z.velocity.x) > 8.0
	var raise := 0.0
	if state == SWEEP_W:
		raise = clampf(1.0 - _st / SWEEP_WIND, 0.0, 1.0)
	elif state == HURL_W:
		raise = clampf(1.0 - _st / HURL_WIND, 0.0, 1.0)
	elif state == STOMP_W:
		raise = clampf(1.0 - _st / 0.8, 0.0, 1.0)
	var sweep := state == SWEEP
	var roar := state == SHED or state == STOMP_W
	var r := RandomNumberGenerator.new()
	r.seed = _seed
	var pts := PackedVector2Array()
	var cols := PackedColorArray()
	var bob := sin(p * 2.0) * 1.2 if moving else 0.0
	# רגליים: שני גזעים חרוכים
	var f0 := Vector2(sin(p) * 6.0 + 8.0, -maxf(0.0, cos(p)) * 4.0) if moving else Vector2(8, 0)
	var f1 := Vector2(sin(p + PI) * 6.0 - 8.0, -maxf(0.0, cos(p + PI)) * 4.0) if moving else Vector2(-8, 0)
	if state == STOMP_W:
		f0 = Vector2(10, -12.0 * raise)
	for fp in [f1, f0]:
		var ft: Vector2 = fp
		Art.limb(z, PackedVector2Array([Vector2(ft.x * 0.5, -20), ft + Vector2(0, -7), ft]), 8.0, col(Color("2a221c")))
		DrawBatch.line(z, Vector2(ft.x * 0.5 - 1.5, -18), ft + Vector2(-1, -8), _e(0.7), 1.0)
		DrawBatch.colored_polygon(z, PackedVector2Array([ft + Vector2(-5, 0), ft + Vector2(7, 0), ft + Vector2(6, -3), ft + Vector2(-4, -3)]), col(Color("1a1614")))
	var up := Vector2(0, bob)
	# בולים מאחור (טיפי של מדורה, נשענים פנימה)
	for q in 3:
		var bx := -24.0 + float(q) * 9.0
		_log_quad(Vector2(bx, -8) + up, Vector2(bx * 0.2 - 2.0, -78.0 - float(q) * 3.0) + up, 3.2, Color("2e2418"))
	# הערימה: גופות מותכות
	var body := PackedVector2Array([Vector2(-23, -10), Vector2(-26, -26), Vector2(-21, -42), Vector2(-12, -56), Vector2(-2, -63), Vector2(9, -61), Vector2(19, -50), Vector2(25, -32), Vector2(23, -10)])
	for i in body.size():
		body[i] += up
	Art.fill_shaded(z, body, col(CH), 0.1, 0.3)
	# בולים בצדדים (בוערים בקצה העליון) - המרכז נשאר לגופות ולליבה
	for q in 2:
		var bx := -21.0 + float(q) * 38.0
		var top := Vector2(bx * 0.3, -72.0 + float(q) * 3.0) + up
		_log_quad(Vector2(bx, -6) + up, top, 3.4, Color("3a2a1c"))
		DrawBatch.circle(z, top, 2.6, _e(1.1))
	# גופות בתוך הערימה: גו, ראש (עיני גחלים, פה לוחש), יד שמושטת החוצה
	for q in 5:
		var c := Vector2(r.randf_range(-17.0, 14.0), r.randf_range(-52.0, -18.0)) + up
		var a := r.randf_range(-0.7, 0.7)
		var tdir := Vector2.from_angle(a - PI * 0.5)
		var tn := Vector2(-tdir.y, tdir.x)
		DrawBatch.colored_polygon(z, PackedVector2Array([c - tn * 4.0, c + tdir * 10.0 - tn * 3.0, c + tdir * 10.0 + tn * 3.0, c + tn * 4.0]), col(Color("2c2622")))
		var hc := c + tdir * 13.0
		Art.oval(z, hc, 3.6, 4.0, col(Color("5a504a")), a, Art.OUTLINE, 0.8)
		DrawBatch.colored_polygon(z, Art.ellipse(hc - tdir * 0.5, 2.6, 1.2, a, 6), col(Color("1a1412")))
		DrawBatch.circle(z, hc + tn * 1.3 - tdir * 0.5, 0.8, _e(1.3))
		DrawBatch.circle(z, hc - tn * 1.3 - tdir * 0.5, 0.8, _e(1.3))
		DrawBatch.colored_polygon(z, PackedVector2Array([hc - tdir * 1.6 - tn, hc - tdir * 1.6 + tn, hc - tdir * 3.0]), _e(0.9))
		var side := -1.0 if c.x < 0.0 else 1.0
		var ae := c + Vector2(side * r.randf_range(9.0, 14.0), r.randf_range(-6.0, 4.0) + sin(t * 1.7 + float(q)) * 1.5)
		Art.limb(z, PackedVector2Array([c + tdir * 6.0, c.lerp(ae, 0.5) + Vector2(0, -2), ae]), 2.2, col(Color("221d1a")))
		for k in 3:
			DrawBatch.line(z, ae, ae + (ae - c).normalized().rotated(-0.5 + float(k) * 0.5) * 2.4, col(Color("3a322c")), 0.7)
	# סדקים לוחשים בכל הערימה
	for q in 10:
		var a := Vector2(r.randf_range(-20.0, 20.0), r.randf_range(-56.0, -14.0)) + up
		var b := a + Vector2(r.randf_range(-5.0, 5.0), r.randf_range(3.0, 7.0))
		DrawBatch.polyline(z, PackedVector2Array([a, b, b + Vector2(r.randf_range(-3.0, 3.0), r.randf_range(2.0, 5.0))]), _e(0.85), 1.1)
	# הקליפה מלפנים / הליבה
	var core := Vector2(10, -34) + up
	if not cracked(FRONT):
		var dmg := clampf(1.0 - crust[FRONT] / crust_max[FRONT], 0.0, 1.0)
		for q in 6:   # לוחות אפר עבים
			var pc := Vector2(r.randf_range(5.0, 20.0), r.randf_range(-52.0, -16.0)) + up
			DrawBatch.colored_polygon(z, Art.ellipse(pc, r.randf_range(3.5, 5.5), r.randf_range(2.8, 4.0), r.randf(), 7), col(ASH if q % 2 == 0 else Color("4e4844")))
		for q in 2 + int(dmg * 6.0):
			var a := Vector2(r.randf_range(6.0, 21.0), r.randf_range(-52.0, -18.0)) + up
			DrawBatch.polyline(z, PackedVector2Array([a, a + Vector2(r.randf_range(-4.0, 4.0), 5.0), a + Vector2(r.randf_range(-4.0, 4.0), 9.0)]), _e(1.0), 1.0 + dmg)
		Art.glow(z, core, 6.0 + 8.0 * dmg, Color(1.0, 0.5, 0.15, 0.2 + 0.4 * dmg))
	else:   # הלב הלוחש חשוף
		var pulse := 1.0 + 0.12 * sin(t * 8.0)
		DrawBatch.colored_polygon(z, Art.ellipse(core, 10.0 * pulse, 13.0 * pulse, 0.0, 14), col(RAW))
		DrawBatch.colored_polygon(z, Art.ellipse(core, 7.0 * pulse, 9.5 * pulse, 0.0, 12), _e(1.3))
		DrawBatch.colored_polygon(z, Art.ellipse(core, 3.5, 5.0, 0.0, 10), Color(1.0, 0.95, 0.7, 0.95))
		for q in 6:   # עורקים לוחשים מהלב
			var a := float(q) / 6.0 * TAU + 0.3
			DrawBatch.line(z, core + Vector2.from_angle(a) * 9.0, core + Vector2.from_angle(a + 0.2) * 17.0, _e(1.0), 1.2)
		Art.glow(z, core, 20.0, Color(1.0, 0.55, 0.15, 0.6))
	if cracked(BACK):
		DrawBatch.colored_polygon(z, Art.ellipse(Vector2(-17, -34) + up, 4.0, 10.0, 0.0, 10), col(RAW))
		DrawBatch.line(z, Vector2(-18, -42) + up, Vector2(-16, -26) + up, _e(1.2), 1.4)
	# הראש הראשי: גולגולת גדולה למעלה מלפנים
	var head := Vector2(11, -63) + up + (Vector2(0, -2) if roar else Vector2.ZERO)
	Art.oval_shaded(z, head, 7.5, 8.0, col(Color("3e3632")), 0.0)
	DrawBatch.colored_polygon(z, Art.ellipse(head + Vector2(3.5, -1.5), 2.2, 2.0, 0.0, 8), col(Color("120e0c")))
	DrawBatch.colored_polygon(z, Art.ellipse(head + Vector2(-1.5, -1.5), 1.8, 1.8, 0.0, 8), col(Color("120e0c")))
	DrawBatch.circle(z, head + Vector2(3.5, -1.5), 1.3, _e(1.4))
	DrawBatch.circle(z, head + Vector2(-1.5, -1.5), 1.0, _e(1.2))
	Art.glow(z, head + Vector2(3.5, -1.5), 6.0, Color(1.0, 0.5, 0.15, 0.7))
	var jaw := 4.0 if roar or sweep else 1.5
	DrawBatch.colored_polygon(z, PackedVector2Array([head + Vector2(-1, 3), head + Vector2(7, 2.5), head + Vector2(6.5, 3.5 + jaw), head + Vector2(-0.5, 3.5 + jaw)]), _e(1.0))
	for q in 4:   # שיניים
		DrawBatch.line(z, head + Vector2(0.5 + float(q) * 1.7, 2.8), head + Vector2(0.8 + float(q) * 1.7, 4.2), col(Color("d8c8a8")), 0.8)
	# הזרועות: גופות ובולים שהתמזגו, טפרים
	var sh_b := Vector2(-15, -48) + up
	var sh_f := Vector2(17, -48) + up
	var hb := Vector2(-24, -22) + up
	var hf := Vector2(27, -22) + up
	if raise > 0.0:
		hb = hb.lerp(Vector2(-6, -86), raise)
		hf = hf.lerp(Vector2(14, -90), raise)
	elif sweep:
		hb = Vector2(22, -18)
		hf = Vector2(40, -14)
	var eb := Art.joint(sh_b, hb, 17.0, 17.0, -1.0)
	var ef := Art.joint(sh_f, hf, 17.0, 17.0, 1.0)
	Art.limb(z, PackedVector2Array([sh_b, eb, hb]), 6.5, col(Color("221d1a")))
	Art.limb(z, PackedVector2Array([sh_f, ef, hf]), 7.0, col(Color("2a2420")))
	DrawBatch.line(z, sh_f, ef, _e(0.7), 1.0)
	DrawBatch.line(z, ef, hf, _e(0.6), 0.9)
	for hh in [[hb, eb], [hf, ef]]:
		var hv: Vector2 = hh[0]
		var ev: Vector2 = hh[1]
		var d := (hv - ev).normalized()
		DrawBatch.circle(z, hv, 3.6, col(Color("1e1a18")))
		for k in 4:
			DrawBatch.line(z, hv, hv + d.rotated(-0.7 + float(k) * 0.45) * 5.5, col(Color("3a322c")), 1.2)
		DrawBatch.circle(z, hv, 1.4, _e(1.0))
	# HURL: בול בוער מעל הראש
	if state == HURL_W and raise > 0.3:
		var bc := Vector2(6, -96)
		_log_quad(bc + Vector2(-16, 3), bc + Vector2(16, -4), 4.5, Color("3a2a1c"))
		DrawBatch.circle(z, bc + Vector2(16, -4), 3.4, _e(1.2))
		Decor.U.flame(pts, cols, bc + Vector2(0, -3), 8.0, 16.0 + 6.0 * sin(t * 9.0), sin(t * 4.0) * 3.0, 0.9)
	# להבות: מהקודקוד ומהרווחים בין הבולים (גדלות כשהוא נפגע)
	var fl_h := 20.0 + 16.0 * _rage + (10.0 if roar else 0.0)
	for q in 5:
		var bx := -10.0 + float(q) * 5.5
		var ph := float(q) * 1.7
		var hgt := fl_h * (0.7 + 0.3 * sin(t * 6.0 + ph)) * (1.25 if q == 2 else (1.0 if q == 1 or q == 3 else 0.7))
		Decor.U.flame(pts, cols, Vector2(bx, -64.0 + absf(bx) * 0.3) + up, 6.5, hgt, sin(t * 3.0 + ph) * 4.0, 0.92)
	for q in 3:   # להבות קטנות מהרווחים
		var gp := Vector2(-18.0 + float(q) * 14.0, -30.0 - float(q % 2) * 12.0) + up
		Decor.U.flame(pts, cols, gp, 4.0, 9.0 + 4.0 * sin(t * 7.0 + float(q) * 2.0), sin(t * 4.0 + float(q)) * 2.0, 0.85)
	for q in 6:   # גצים עולים
		var k := fmod(t * 0.7 + float(q) / 6.0, 1.0)
		Decor.U.dia(pts, cols, Vector2(-12.0 + float(q) * 5.0 + sin(t * 2.0 + float(q)) * 4.0, -70.0 - k * 50.0) + up, 1.0 * (1.0 - k) + 0.4, Color(1.0, 0.7, 0.3, 1.0 - k))
	if sweep:   # שובל אש של המכה
		Decor.U.flame(pts, cols, hf + Vector2(-6, 4), 10.0, 22.0, -10.0, 0.9)
	if not pts.is_empty():
		DrawBatch.tris(z, pts, cols)
	if roar:
		for q in 3:
			var k := fmod(t * 2.0 + float(q) / 3.0, 1.0)
			DrawBatch.arc(z, head + Vector2(8, 3), 6.0 + k * 22.0, -0.8, 0.8, 8, Color(1.0, 0.7, 0.3, 0.5 * (1.0 - k)), 1.2)
	end_draw()
	return true


# בול עץ חרוך (מרובע עם קליפה, טבעות וסדק לוחש)
func _log_quad(a: Vector2, b: Vector2, w: float, c: Color) -> void:
	var d := (b - a).normalized()
	var n := Vector2(-d.y, d.x) * w
	DrawBatch.colored_polygon(z, PackedVector2Array([a - n, b - n * 0.8, b + n * 0.8, a + n]), col(c))
	DrawBatch.line(z, a + n * 0.3, b + n * 0.2, col(c.lightened(0.15)), 0.9)
	DrawBatch.line(z, a.lerp(b, 0.3) - n * 0.4, a.lerp(b, 0.55) - n * 0.3, _e(0.8), 0.9)


# ============================================================
#  רסיסי פחם: כל הרסיסים בצומת אחד, ציור אחד (משולשים). חלק לוחשים (גחלים)
# ============================================================
class Cinders extends Node2D:
	const DrawBatch := preload("res://effects/draw_batch.gd")
	const MAX := 280
	var _s := []                  # [pos, vel, rot, spin, size, life, ground_y, col, glow]

	static func spray(parent: Node, pos: Vector2, dir: Vector2, n: int, ground_y: float, k := 1.0, c := Color(0, 0, 0, 0)) -> void:
		if parent == null or n <= 0 or not parent.is_inside_tree():
			return
		var node: Node = parent.get_tree().get_first_node_in_group("ch_cinders")
		if node == null:
			node = Cinders.new()
			parent.add_child(node)
		node.add(pos, dir, Quality.scaled(n, Quality.gore()), ground_y, k, c)

	func _ready() -> void:
		add_to_group("ch_cinders")
		z_index = 8

	func add(pos: Vector2, dir: Vector2, n: int, ground_y: float, k: float, c: Color) -> void:
		for i in n:
			if _s.size() >= MAX:
				_s.pop_front()
			var a := dir.angle() + randf_range(-1.2, 1.2)
			var sp := randf_range(100.0, 300.0) * (0.7 + 0.3 * minf(k, 1.5))
			var glow := c.a <= 0.0 and randf() < 0.3
			var cc := c if c.a > 0.0 else (Color(1.0, randf_range(0.35, 0.6), 0.1) if glow else Color(0.1, 0.09, 0.085).lerp(Color(0.35, 0.33, 0.31), randf() * 0.6))
			_s.append([pos + Vector2(randf_range(-4, 4), randf_range(-4, 4)), Vector2.from_angle(a) * sp + Vector2(0, -70.0), randf() * TAU, randf_range(-12.0, 12.0), randf_range(1.4, 3.4) * clampf(k, 0.5, 2.5), randf_range(1.4, 2.6), ground_y, cc, glow])

	func _process(delta: float) -> void:
		if _s.is_empty():
			return
		var keep := []
		for s in _s:
			s[5] -= delta
			if s[5] <= 0.0:
				continue
			var v: Vector2 = s[1]
			v.y += 1200.0 * delta
			var p: Vector2 = s[0] + v * delta
			if p.y >= s[6] - 1.0 and v.y > 0.0:
				p.y = s[6] - 1.0
				v = Vector2(v.x * 0.4, -v.y * 0.2)
				s[3] = float(s[3]) * 0.4
				if absf(v.y) < 40.0:
					v = Vector2(v.x * 0.5, 0.0)
			s[0] = p
			s[1] = v
			s[2] = float(s[2]) + float(s[3]) * delta
			keep.append(s)
		_s = keep
		queue_redraw()

	func _draw() -> void:
		DrawBatch.begin(self)
		_draw_b()
		DrawBatch.end(self)

	func _draw_b() -> void:
		if _s.is_empty():
			return
		var pts := PackedVector2Array()
		var cols := PackedColorArray()
		for s in _s:
			var p: Vector2 = s[0]
			var r: float = s[4]
			var a: float = s[2]
			var c: Color = s[7]
			if s[8]:   # גחלת: דועכת לאדום כהה
				c = c.lerp(Color(0.3, 0.05, 0.02), clampf(1.0 - float(s[5]) / 1.6, 0.0, 1.0))
			c.a *= clampf(float(s[5]) / 0.4, 0.0, 1.0)
			var p1 := p + Vector2.from_angle(a) * r * 1.3
			var p2 := p + Vector2.from_angle(a + 2.2) * r
			var p3 := p + Vector2.from_angle(a + 4.0) * r * 0.9
			pts.append_array([p1, p2, p3])
			cols.append_array([c, c.darkened(0.3), c])
		DrawBatch.tris(self, pts, cols)


# ============================================================
#  גחלים על הקרקע (בול שנחת / אש של DAMBUILDER): פוגע בך, מאכיל CHARRED
# ============================================================
class EmberPatch extends "res://environment/hazard.gd":
	const DrawBatch := preload("res://effects/draw_batch.gd")
	const Art := preload("res://art.gd")
	var w := 70.0
	var _t := 0.0
	var _life0 := 4.0
	var _seed := 0

	func _ready() -> void:
		super._ready()
		z_index = 3
		_seed = randi() % 1000
		if life <= 0.0:
			life = 4.0
		_life0 = life
		rect = Rect2(-w * 0.5, -16.0, w, 18.0)
		story_kind = "fire"
		tick = 0.6
		_tick_t = 0.3
		player_damage = 1
		zombie_burn = 2.0

	func _hazard_tick(delta: float) -> void:
		_t += delta
		if Engine.get_physics_frames() % 3 == 0 and Art.on_screen(self, global_position, w):
			queue_redraw()

	func _draw() -> void:
		DrawBatch.begin(self)
		_draw_b()
		DrawBatch.end(self)

	func _draw_b() -> void:
		var k := clampf(life / minf(_life0, 1.2), 0.0, 1.0)
		var pts := PackedVector2Array()
		var cols := PackedColorArray()
		Decor.U.blob(pts, cols, Vector2(0, -3), w * 0.6, 10.0, Color(1.0, 0.4, 0.1, 0.3 * k), 10)
		var n := int(w / 9.0)
		for i in n:
			var x := -w * 0.5 + (float(i) + 0.5) * w / float(n)
			var g := 0.5 + 0.5 * sin(_t * 5.0 + float(i * 7 + _seed))
			Decor.U.oval(pts, cols, Vector2(x, -1.5), 4.0, 2.0, Color(0.25, 0.08, 0.03, k).lerp(Color(1.0, 0.55, 0.12, k), g), 6)
			if i % 2 == 0:
				Decor.U.flame(pts, cols, Vector2(x, -1.0), 4.0, (6.0 + 8.0 * g) * k, sin(_t * 4.0 + float(i)) * 2.0, 0.8 * k)
		Decor.U.flush(self, pts, cols)


# ---- בול בוער שהבוס זורק: אפשר לירות בו באוויר. זז ב-_process ----
class BurningLog extends Node2D:
	const G := 1100.0
	const DrawBatch := preload("res://effects/draw_batch.gd")
	const Art := preload("res://art.gd")
	const Sfx := preload("res://sfx.gd")
	const Particles := preload("res://particles.gd")
	var vel := Vector2.ZERO
	var ground_y := 630.0
	var owner_z: Node = null
	var _rot := 0.0
	var _done := false
	var _t := 0.0

	class Hit extends StaticBody2D:
		var b = null
		func take_damage(_a, _p: Vector2, _d: Vector2, _e := false, _s := {}) -> void:
			if b != null:
				b.shot()

	func _ready() -> void:
		z_index = 7
		add_to_group("py_logs")
		add_to_group("blastable")
		var h := Hit.new()
		h.b = self
		h.collision_layer = 4
		h.collision_mask = 0
		h.add_to_group("no_outline")
		var cs := CollisionShape2D.new()
		var sh := RectangleShape2D.new()
		sh.size = Vector2(40, 22)
		cs.shape = sh
		h.add_child(cs)
		add_child(h)

	func blast_rect() -> Rect2:
		return Rect2(global_position - Vector2(20, 11), Vector2(40, 22))

	func hit_by_blast(_c: Vector2, _r: float) -> void:
		shot()

	func shot() -> void:
		if _done:
			return
		if owner_z != null and is_instance_valid(owner_z) and owner_z.type_mod != null:
			owner_z.type_mod.logs_shot += 1
		Sfx.play("ch_crack", global_position, 2.0, 0.1, 2)
		Cinders.spray(get_parent(), global_position, Vector2.UP, 14, ground_y, 1.0)
		Particles.burst(get_parent(), global_position, "fire", Vector2.UP, 6)
		_done = true
		queue_free()

	func shatter() -> void:
		shot()

	func _process(delta: float) -> void:
		if _done:
			return
		_t += delta
		vel.y += G * delta
		global_position += vel * delta
		_rot += delta * 5.0 * signf(vel.x)
		if Engine.get_process_frames() % 4 == 0:
			Particles.burst(get_parent(), global_position, "fire", -vel.normalized(), 1)
		var pl := get_tree().get_first_node_in_group("player")
		if pl != null and not pl.dead and Rect2(global_position - Vector2(18, 12), Vector2(36, 24)).intersects(pl.body_rect()):
			_impact(pl, true)
			return
		if global_position.y >= ground_y - 6.0 and vel.y > 0.0 or _t > 4.0:
			_impact(pl, false)
			return
		queue_redraw()

	func _impact(pl: Node, direct: bool) -> void:
		_done = true
		var hit: bool = direct or (pl != null and not pl.dead and pl.global_position.distance_to(global_position) < 56.0)
		if hit and pl != null:
			if pl._roll_t <= 0.0 and owner_z != null and is_instance_valid(owner_z) and owner_z.type_mod != null:
				owner_z.type_mod.hurl_hits += 1
			pl.hurt(HURL_DMG, Vector2(signf(vel.x) * 1.3, -0.5))
		Sfx.play("py_log", global_position, 2.0, 0.1, 2)
		Cinders.spray(get_parent(), global_position, Vector2.UP, 12, ground_y, 1.0)
		Particles.burst(get_parent(), global_position, "fire", Vector2.UP, 6)
		var ep := EmberPatch.new()
		ep.w = 80.0
		ep.life = 4.0
		get_parent().add_child(ep)
		ep.global_position = Vector2(global_position.x, ground_y)
		queue_free()

	func _draw() -> void:
		DrawBatch.begin(self)
		_draw_b()
		DrawBatch.end(self)

	func _draw_b() -> void:
		DrawBatch.set_transform(self, Vector2.ZERO, _rot, Vector2.ONE)
		DrawBatch.colored_polygon(self, PackedVector2Array([Vector2(-20, -6), Vector2(19, -7), Vector2(20, 6), Vector2(-19, 7)]), Color("3a2a1c"))
		DrawBatch.line(self, Vector2(-16, -2), Vector2(14, -3), Color(1.0, 0.5, 0.1, 0.8), 1.2)
		DrawBatch.circle(self, Vector2(19, 0), 5.0, Color("6a4a30"))
		DrawBatch.circle(self, Vector2(19, 0), 3.0, Color(1.0, 0.6, 0.15))
		DrawBatch.set_transform_matrix(self, Transform2D.IDENTITY)
		var pts := PackedVector2Array()
		var cols := PackedColorArray()
		Decor.U.flame(pts, cols, Vector2(0, 2), 10.0, 18.0, -vel.x * 0.02, 0.9)
		var gy := ground_y - global_position.y
		if gy > 20.0:   # צל על הרצפה
			var k := clampf(1.0 - gy / 500.0, 0.2, 1.0)
			Decor.U.oval(pts, cols, Vector2(vel.x * 0.05, gy - 1.0), 20.0 * k, 3.5 * k, Color(0.05, 0.02, 0.0, 0.35 * k), 10)
		Decor.U.flush(self, pts, cols)


# ---- גל אש שרץ על הרצפה (RING). זז ב-_process ----
class FireWave extends Node2D:
	const DrawBatch := preload("res://effects/draw_batch.gd")
	const Art := preload("res://art.gd")
	const Particles := preload("res://particles.gd")
	const RANGE := 760.0
	var owner_z: Node = null
	var dir := 1.0
	var delay := 0.0
	var ground_y := 630.0
	var _x0 := INF
	var _t := 0.0
	var _hit := false
	var _side := 0.0
	var _counted := false

	func _ready() -> void:
		z_index = 4
		add_to_group("py_waves")
		visible = delay <= 0.0

	func _process(delta: float) -> void:
		if delay > 0.0:
			delay -= delta
			if delay <= 0.0:
				visible = true
			return
		if _x0 == INF:
			_x0 = global_position.x
		_t += delta
		global_position.x += dir * WAVE_V * delta
		if absf(global_position.x - _x0) > RANGE or global_position.x < 20.0:
			queue_free()
			return
		var pl := get_tree().get_first_node_in_group("player") as Node2D
		if pl != null and not pl.dead:
			var rel: float = pl.global_position.x - global_position.x
			var s := signf(rel)
			var r := Rect2(global_position + Vector2(-16.0, -44.0), Vector2(32.0, 44.0))
			if not _hit and r.intersects(pl.body_rect()):
				_hit = true
				if owner_z != null and is_instance_valid(owner_z) and owner_z.type_mod != null and pl._roll_t <= 0.0:
					owner_z.type_mod.ring_hits += 1
				pl.hurt(RING_DMG, Vector2(dir * 1.2, -0.8))
			elif not _hit and not _counted and _side != 0.0 and s != _side and absf(pl.global_position.y - ground_y) < 260.0:
				_counted = true   # הגל עבר מתחתיו: קפץ
				if owner_z != null and is_instance_valid(owner_z) and owner_z.type_mod != null:
					owner_z.type_mod.on_wave_jumped()
			_side = s
		if Engine.get_process_frames() % 3 == 0:
			for z in get_tree().get_nodes_in_group("zombies"):   # מצית את מי שבדרך (CHARRED נהנה)
				if not z.dead and not z.is_boss() and absf(z.global_position.x - global_position.x) < 20.0 and absf(z.global_position.y - ground_y) < 30.0:
					z.ignite(2.0)
			if Art.on_screen(self, global_position):
				Particles.burst(get_parent(), global_position + Vector2(0, -10), "fire", Vector2(-dir * 0.3, -1.0), 2)
		queue_redraw()

	func _draw() -> void:
		DrawBatch.begin(self)
		_draw_b()
		DrawBatch.end(self)

	func _draw_b() -> void:
		var k := clampf(1.0 - absf(global_position.x - _x0) / RANGE, 0.0, 1.0)
		var pts := PackedVector2Array()
		var cols := PackedColorArray()
		Decor.U.blob(pts, cols, Vector2(0, -8), 34.0, 16.0, Color(1.0, 0.45, 0.1, 0.35), 10)
		for q in 5:
			var x := -dir * float(q) * 9.0
			var h := (46.0 - float(q) * 7.0) * (0.85 + 0.15 * sin(_t * 18.0 + float(q))) * (0.5 + 0.5 * k)
			Decor.U.flame(pts, cols, Vector2(x, 0), 9.0 - float(q), h, -dir * 6.0, 1.0)
		for q in 4:   # אדמה חרוכה מאחור
			Decor.U.oval(pts, cols, Vector2(-dir * (40.0 + float(q) * 22.0), -1.0), 12.0, 2.0, Color(0.3, 0.08, 0.02, 0.5 * (1.0 - float(q) / 4.0)), 6)
		Decor.U.flush(self, pts, cols)


# ---- הבזק כתום כשהמדורה קורסת ----
class PyreFlash extends Node2D:
	const DrawBatch := preload("res://effects/draw_batch.gd")
	const Art := preload("res://art.gd")
	var _t := 0.0

	func _ready() -> void:
		z_index = 9

	func _process(delta: float) -> void:
		_t += delta
		if _t > 1.0:
			queue_free()
			return
		queue_redraw()

	func _draw() -> void:
		DrawBatch.begin(self)
		_draw_b()
		DrawBatch.end(self)

	func _draw_b() -> void:
		var k := _t / 1.0
		Art.glow(self, Vector2.ZERO, 60.0 + k * 240.0, Color(1.0, 0.6, 0.25, 0.7 * (1.0 - k)))
		for q in 12:
			var a := float(q) * TAU / 12.0
			DrawBatch.line(self, Vector2.from_angle(a) * (20.0 + k * 90.0), Vector2.from_angle(a) * (40.0 + k * 220.0), Color(1.0, 0.8, 0.4, 0.6 * (1.0 - k)), 3.0)
