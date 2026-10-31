extends "res://enemies/zombie_type.gd"
# ============================================================
#  SHEARER (שלב 55, "WIND STEPPE") - גוזז כבשים מת מהאסטנסיה: ברט (boina), שפם, שרוולים מופשלים עם אמות מדממות,
#  סינר עור ספוג דם מעל מכנסי bombachas, ומספרי גז"ז ענקיים (שני להבים משולשים עם קשת קפיץ).
#  מה הוא למד: "אתה יורה במה שנראה כמו זומבי". אז הוא לא נראה כמו זומבי - הוא נראה כמו כבשה.
#    הוא זוחל על ארבע מתחת לגיזה של כבשה שפשט, עם ראש כבשה פשוט על הראש, ורועה בתוך העדר (Sheep).
#    הסימן (TELL): לכבשה הזאת יש רגליים של בן אדם (מגפיים ו-bombachas מאחור), ידיים מדממות מקדימה,
#    עיניים אדומות שנוצצות מתוך ראש הכבשה, דם על הצמר, ולפעמים קצה המספריים מבצבץ ונוצץ.
#  DISGUISE - רועה, מתקרב אליך לאט כשאתה בטווח (CREEP_R).
#  BURST    - קרוב מדי (BURST_R), ירו בו, או שהעדר נבהל לידו: זורק את הגיזה (ענן צמר), נעמד וצורח.
#  LEAP     - קופץ עליך בקשת (LEAP_V). CHASE - רץ (chase).
#  SNIP     - קרוב (SNIP_R): המספריים נפתחים לרווחה ונוצצים (SNIP_WIND - האזהרה), ונסגרים (DMG + האטה).
#             לפעמים (COMBO) גזיזה שנייה מהירה. אחרי גזיזה - RECOVER (חלון לירות בו).
#  "FOUND ONE": ירייה בו כשהוא עוד מחופש ורחוק ממך (מעל FOUND_R) = מצאת אותו מוקדם. הוא קם מיד.
#  "THEY LET YOU PASS NOW" (main meta "shr_found" >= LEARN): אחרי שמצאת LEARN מוקדם, הבאים לא קמים כשאתה מתקרב -
#    הם מחכים שתעבור (PASS_DX מאחוריך) ואז קמים מאחור. העיניים שלהם כמעט לא נוצצות (הרגליים עדיין מסגירות).
#  כבשים (Sheep): לא מזיקות ולא מתות. כדור שפוגע בכבשה נבלע בצמר (ענן צמר + "באאא") והיא בורחת - והבהלה מתפשטת.
#    כך מפזרים עדר: יורים לידו, והכבשים מתפזרות וחושפות את הגוזז. המספריים לא נתקעים בכבשים - הן לא חוסמות אותו.
#  בוס (chase_range > 600): "THE ESTANCIERO" - גוזז ענק עם מכונת גז"ז על הגב: מנוע דו-פעימתי, גלגל תנופה,
#    זרוע הנעה מפרקית מעל הכתף, ובקצה - מספריים הידראוליים ענקיים במקום יד.
#    SNAP   - קרוב: המספריים נפתחים (B_SNAP_WIND, שריקה הידראולית) ונסגרים לפניו בגובה הגוף (B_SNAP_DMG).
#             למד: אחרי JUMP_LEARN פעמים שקפצת מעל - גוזז גבוה ("IT READS YOUR JUMP") - צריך להתגלגל / להתרחק.
#    CHARGE - המנוע מסתובב (B_CHARGE_WIND, עשן) ומסתער עם המספריים פתוחים (B_CHARGE_V). פגיעה בקיר / מכשול =
#             המספריים נתקעים (B_STUCK_T): הוא חשוף לגמרי (x OPEN_MULT לכל פגיעה, מכל כיוון).
#    CALL   - שורק לעדר: עדר כבשים דוהר דרך הזירה (חוסם יריות) ובתוכו CALL_SHEARERS גוזזים. עד CALLS פעמים.
#    המנוע על הגב = נקודת התורפה: מאחור / מלמעלה x ENGINE_MULT (ניצוצות). הסינר והמספריים מלפנים x FRONT_MULT.
#    מוות: המנוע מתפוצץ, המספריים עפים ונתקעים בקרקע, ענן צמר ודם, והענק קורס.
#  צלילים: "shr_baa", "shr_burst", "shr_open", "shr_snip", "shr_whistle", "shr_engine", "shr_rev", "shr_hyd" (מסונתזים).
#  לשנות: CREEP_R, BURST_R, FOUND_R, PASS_DX, LEAP_V, SNIP_R, SNIP_WIND, SNIP_DMG, COMBO, RECOVER_T, LEARN, FLOCK_N;
#    בוס: B_SNAP_R, B_SNAP_WIND, B_SNAP_DMG, JUMP_LEARN, B_CHARGE_WIND, B_CHARGE_V, B_CHARGE_T, B_STUCK_T, CALL_EVERY,
#    CALLS, CALL_SHEARERS, ENGINE_MULT, FRONT_MULT, OPEN_MULT.
# ============================================================

const SOUNDS := {
	"shr_baa": [["V", 330, 290, 0.0, 0.55, 0.03, 2.4, 0.5, 1.0, 0.3, 0, [760, 1500, 4]], ["N", 0, 0, 0.0, 0.4, 0.02, 4.0, 0.08, 0.4, 0]],
	"shr_burst": {"drive": 2.4, "layers": [["N", 0, 0, 0.0, 0.35, 0.0, 9.0, 0.7, 0.5, 0, 0.3], ["V", 300, 160, 0.0, 0.55, 0.02, 3.0, 0.7, 1.0, 0.25, 0, [700, 1300, 40]], ["V", 520, 380, 0.08, 0.5, 0.02, 3.5, 0.5, 1.0, 0.1, 0, [1100, 2100, 60]]]},
	"shr_open": [["N", 0, 0, 0.0, 0.3, 0.05, 6.0, 0.25, 0.8, 0, 0.6], ["S", 2600, 3400, 0.0, 0.25, 0.02, 7.0, 0.1, 1.0, 0.02]],
	"shr_snip": [["N", 0, 0, 0.0, 0.06, 0.0, 60.0, 0.9, 1.0, 0, 0.5], ["S", 3200, 2600, 0.0, 0.08, 0.0, 40.0, 0.35, 1.0, 0], ["S", 1700, 1500, 0.02, 0.1, 0.0, 30.0, 0.25, 1.0, 0]],
	"shr_whistle": [["S", 1500, 2300, 0.0, 0.35, 0.02, 2.0, 0.35, 1.0, 0.01], ["S", 2300, 1400, 0.38, 0.45, 0.02, 2.0, 0.35, 1.0, 0.01]],
	"shr_engine": {"drive": 2.0, "layers": [["Q", 46, 50, 0.0, 0.9, 0.05, 1.2, 0.35, 0.25, 0.08], ["N", 0, 0, 0.0, 0.9, 0.05, 1.2, 0.25, 0.15, 0], ["C", 0, 0, 0.0, 0.9, 0.0, 1.0, 0.3, 0.6, 0]]},
	"shr_rev": {"drive": 2.4, "layers": [["Q", 50, 130, 0.0, 0.8, 0.05, 1.0, 0.45, 0.3, 0.05], ["N", 0, 0, 0.0, 0.8, 0.05, 1.0, 0.3, 0.2, 0], ["C", 0, 0, 0.0, 0.8, 0.0, 1.2, 0.4, 0.7, 0]]},
	"shr_hyd": [["N", 0, 0, 0.0, 0.6, 0.04, 3.0, 0.5, 1.0, 0, 0.45], ["S", 120, 70, 0.0, 0.5, 0.02, 3.0, 0.3, 1.0, 0.02]],
}

const FleshFx := preload("res://effects/flesh_fx.gd")
const Boom := preload("res://explosion.gd")
const DebrisScript := preload("res://debris.gd")

const CREEP_R := 420.0
const BURST_R := 115.0
const FOUND_R := 150.0
const PASS_DX := 70.0
const LEAP_V := Vector2(330.0, -430.0)
const SNIP_R := 64.0
const SNIP_WIND := 0.32
const SNIP_DMG := 1
const COMBO := 0.4
const RECOVER_T := 0.5
const LEARN := 2
const FLOCK_N := 4
# בוס
const B_SNAP_R := 160.0
const B_SNAP_WIND := 0.6
const B_SNAP_DMG := 2
const JUMP_LEARN := 2
const B_CHARGE_WIND := 0.85
const B_CHARGE_V := 480.0
const B_CHARGE_T := 1.5
const B_CHARGE_R := Vector2(230.0, 680.0)
const B_STUCK_T := 1.5
const CALL_EVERY := 15.0
const CALLS := 3
const CALL_SHEARERS := 2
const ENGINE_MULT := 2.2
const FRONT_MULT := 0.65
const OPEN_MULT := 1.8

enum { DISGUISE, BURST, LEAP, CHASE, SNIP_W, SNIP, RECOVER, PEN, STAMPEDE,
	B_WALK, B_SNAP_W, B_SNAP, B_CHARGE_W, B_CHARGE, B_STUCK, B_CALL, B_RECOVER }

# לבדיקות
var bursts := 0
var leaps := 0
var snips := 0
var snip_hits := 0
var found := 0
var passed_ambush := 0
var b_snaps := 0
var b_snap_hits := 0
var b_high := 0
var b_jumped := 0
var b_charges := 0
var b_charge_hits := 0
var b_stuck := 0
var b_calls := 0
var engine_hits := 0
var front_hits := 0

var state := DISGUISE
var learned_pass := false
var _t := 0.0
var _cd := 0.6
var _home := 0.0
var _wander_x := 0.0
var _wander_t := 0.0
var _combo := false
var _hit_done := false
var _open := 0.0               # 0..1 המספריים פתוחים
var _glint := 0.0
var _peek_t := 2.0
var _met := false
var _run_v := 0.0
var _pen: Node = null
var _hit_kind := ""
var _var := 0                  # וריאציה לכל אחד (צבע ברט / חולצה)
var _beret := Color("1e2a44")
var _shirt2 := Color("7a2a24")
var _stache := Color("3a2a20")
# בוס
var _charge_cd := 2.5
var _call_cd := 9.0
var _calls := 0
var _jumps := 0
var _high := false
var _snap_rect := Rect2()
var _fly := 0.0                # סיבוב גלגל התנופה
var _smoke_t := 0.0
var _eng_snd := 0.0
var _charge_t := 0.0


func _boss() -> bool:
	return z != null and float(z.chase_range) > 600.0


func stats() -> Dictionary:
	if _boss():
		return {"name": "SHEARER", "hp": 380, "walk": 45.0, "chase": 78.0, "damage": 2, "bite_delay": 1.2, "scale": 2.25, "width": 1.0,
			"duck": 0.0, "cover": 0.0, "skin": Color("a8a08a"), "shirt": Color("5a3a2a"), "pants": Color("4a4a40"), "shoe": Color("2a1e16"),
			"points": 2600, "boss": true, "boss_name": "THE ESTANCIERO", "ragdoll": false, "metal": _hit_kind == "engine"}
	return {"name": "SHEARER", "hp": 40, "walk": 40.0, "chase": 132.0, "damage": 1, "bite_delay": 1.0, "scale": 1.05, "width": 1.0,
		"duck": 0.0, "cover": 0.0, "skin": Color("a4a88a"), "shirt": Color("7a2a24"), "pants": Color("6a6252"), "shoe": Color("2e2218"), "points": 430}


func use_brain_movement() -> bool:
	return false


func can_bite() -> bool:
	return false


func can_groan() -> bool:
	return state != DISGUISE and state != PEN and state != STAMPEDE


func death_sound() -> String:
	return "roar" if _boss() else "zdeath"


func _main() -> Node:
	return z.get_parent()


func _wind() -> float:
	var st = _main().get("_stage") if _main() != null else null
	if st != null and st.has_method("wind"):
		return float(st.wind())
	return -0.4


func learned() -> bool:
	var m := _main()
	return m != null and int(m.get_meta("shr_found", 0)) >= LEARN


func setup() -> void:
	var r := RandomNumberGenerator.new()
	r.seed = z.get_instance_id()
	_var = r.randi() % 4
	_beret = [Color("1e2a44"), Color("1a1a1e"), Color("5a2a22"), Color("2a3a2a")][_var]
	_shirt2 = [Color("7a2a24"), Color("2a4a6a"), Color("6a5a2a"), Color("4a2a4a")][r.randi() % 4]
	z.shirt = _shirt2
	_stache = [Color("3a2a20"), Color("6a6058"), Color("2a1e18")][r.randi() % 3]
	_home = z.global_position.x
	_wander_x = _home
	if _boss():
		state = B_WALK
		_resize(Vector2(34.0, 62.0))
		return
	learned_pass = learned()
	state = DISGUISE
	_resize(Vector2(46.0, 40.0))
	_flock_check.call_deferred()


func _resize(b: Vector2) -> void:
	var r := z._shape.shape as RectangleShape2D
	r.size = Vector2(b.x * z.wf * z.sc, b.y * z.sc)
	z._shape.position = Vector2(0.0, -b.y * 0.5 * z.sc)


# אין עדר לידו? מביא איתו עדר קטן (גם כשהפיזור הרגיל שם אותו בלי כבשים)
func _flock_check() -> void:
	if z == null or not is_instance_valid(z) or z.dead or state != DISGUISE:
		return
	var n := 0
	for s in z.get_tree().get_nodes_in_group("s55_sheep"):
		if absf(s.global_position.x - z.global_position.x) < 170.0:
			n += 1
	for i in maxi(0, FLOCK_N - n):
		var s := Sheep.new()
		s.home_x = z.global_position.x + randf_range(-110.0, 110.0)
		s.position = Vector2(s.home_x, z.global_position.y)
		s.ground_y = z.global_position.y
		_main().add_child(s)


# (stage_55: הגוזזים בתוך המכלאה)
func pen_mode(pen: Node) -> void:
	_pen = pen
	state = PEN


# (Corral / קריאת הבוס): דוהר מחופש בתוך העדר
func stampede(dir: float, v: float) -> void:
	if state == DISGUISE or state == PEN:
		state = STAMPEDE
		_run_v = v
		z._dir = dir


# ============================================================
#  תנועה
# ============================================================
func physics(pl: Node, delta: float) -> bool:
	_t -= delta
	_cd -= delta
	_glint = maxf(0.0, _glint - delta)
	if not z.is_on_floor():
		z.velocity.y += z.gravity * delta
	var has: bool = pl != null and not pl.dead
	var d: Vector2 = (pl.global_position - z.global_position) if has else Vector2(9999, 0)
	if _boss():
		_boss_physics(pl, has, d, delta)
		z.move_and_slide()
		return true
	_open = move_toward(_open, 1.0 if state == SNIP_W else (0.0 if state == SNIP else 0.25), delta * (5.0 if state == SNIP_W else 14.0))
	match state:
		DISGUISE:
			_disguise(pl, has, d, delta)
		PEN:
			z.velocity.x = move_toward(z.velocity.x, 0.0, 400.0 * delta)
			z._walk_phase += delta * 0.6
			if has and absf(d.x) < 60.0 and absf(d.y) < 60.0:
				_burst(pl)
		STAMPEDE:
			z.velocity.x = z._dir * _run_v
			z._walk_phase += delta * 14.0
			if has and absf(d.x) < 150.0 and absf(d.y) < 80.0:
				_burst(pl)
		BURST:
			z.velocity.x = move_toward(z.velocity.x, 0.0, 900.0 * delta)
			if _t <= 0.0:
				if has and absf(d.x) > 50.0 and absf(d.x) < 300.0 and absf(d.y) < 80.0 and z.is_on_floor():
					state = LEAP
					leaps += 1
					z._dir = signf(d.x)
					z.velocity = Vector2(z._dir * LEAP_V.x * clampf(absf(d.x) / 220.0, 0.5, 1.2), LEAP_V.y)
					_t = 1.2
				else:
					state = CHASE
		LEAP:
			if has and absf(d.x) < SNIP_R and absf(d.y) < 60.0 and _cd <= 0.0:
				_start_snip()
			elif z.is_on_floor() and _t < 1.05:
				state = CHASE
		CHASE:
			if not has:
				z.velocity.x = move_toward(z.velocity.x, 0.0, 600.0 * delta)
			else:
				var want: float = signf(d.x) if absf(d.x) > 6.0 else z._dir
				z._dir = want
				var v: float = z._dir * z.chase_speed if absf(d.x) > SNIP_R * 0.7 else 0.0
				z.velocity.x = move_toward(z.velocity.x, v, 1400.0 * delta)
				z._walk_phase += delta * absf(z.velocity.x) / 14.0
				if z.is_on_floor() and z.is_on_wall():
					z.velocity.y = -540.0
				if absf(d.x) < SNIP_R and absf(d.y) < 50.0 and _cd <= 0.0:
					_start_snip()
		SNIP_W:
			z.velocity.x = move_toward(z.velocity.x, 0.0, 1500.0 * delta)
			if has:
				z._dir = signf(d.x) if absf(d.x) > 4.0 else z._dir
			if _t <= 0.0:
				state = SNIP
				_t = 0.1
				_hit_done = false
				snips += 1
				Sfx.play("shr_snip", z.global_position, 2.0, 0.1, 3)
				z.velocity.x = z._dir * 160.0
		SNIP:
			if not _hit_done and has and pl._roll_t <= 0.0:
				var front := Rect2(z.global_position + Vector2(0.0 if z._dir > 0 else -SNIP_R - 12.0, -54.0 * z.sc), Vector2(SNIP_R + 12.0, 50.0 * z.sc))
				if front.intersects(pl.body_rect()):
					_hit_done = true
					snip_hits += 1
					pl.hurt(SNIP_DMG, Vector2(z._dir * 0.9, -0.3))
					pl.slow_t = maxf(pl.slow_t, 0.35)
					if snip_hits == 1:
						z._popup("SNIP", Color("e8e8f0"), 14, -86.0)
			if _t <= 0.0:
				if not _combo and randf() < COMBO and has and absf(d.x) < SNIP_R + 20.0:
					_combo = true
					state = SNIP_W
					_t = SNIP_WIND * 0.5
				else:
					_combo = false
					state = RECOVER
					_t = RECOVER_T
					_cd = 0.9
		RECOVER:
			z.velocity.x = move_toward(z.velocity.x, 0.0, 900.0 * delta)
			if _t <= 0.0:
				state = CHASE
	z.move_and_slide()
	return true


func _disguise(pl: Node, has: bool, d: Vector2, delta: float) -> void:
	_wander_t -= delta
	_peek_t -= delta
	if _peek_t <= 0.0:   # קצה המספריים מבצבץ ונוצץ (הסימן)
		_peek_t = randf_range(2.5, 4.5)
		_glint = 0.5 if not learned_pass else 0.25
	var near: bool = has and absf(d.x) < CREEP_R and absf(d.y) < 80.0
	var tx := _wander_x
	var spd := 22.0
	if near and not learned_pass:   # מתגנב אליך עם העדר
		tx = pl.global_position.x - signf(d.x) * 40.0
		spd = 34.0
	elif _wander_t <= 0.0:
		_wander_t = randf_range(1.5, 3.5)
		_wander_x = _home + randf_range(-70.0, 70.0)
	var dx: float = tx - z.global_position.x
	var v := signf(dx) * spd if absf(dx) > 8.0 else 0.0
	if v != 0.0:
		z._dir = signf(v)
	z.velocity.x = move_toward(z.velocity.x, v, 300.0 * delta)
	z._walk_phase += delta * absf(z.velocity.x) / 9.0
	if not has:
		return
	if learned_pass:
		# מחכה שתעבור: ראה אותך מצד אחד (BURST_R), ואתה כבר בצד השני (PASS_DX מאחוריו) - קם מאחורייך
		if absf(d.x) < BURST_R and absf(d.y) < 70.0 and not z.has_meta("seen_front"):
			z.set_meta("seen_front", signf(d.x))
		var passed: bool = z.has_meta("seen_front") and signf(d.x) != float(z.get_meta("seen_front")) and absf(d.x) > PASS_DX and absf(d.x) < 320.0 and absf(d.y) < 70.0
		if passed:
			passed_ambush += 1
			var m := _main()
			if m != null and not m.has_meta("shr_pass_said"):
				m.set_meta("shr_pass_said", true)
				z._popup("THEY LET YOU PASS NOW", Color("ffb070"), 15, -70.0)
				if pl.has_method("_say"):
					pl._say("It waited for me to walk past...", Color("ffb070"))
			_burst(pl)
	elif absf(d.x) < BURST_R and absf(d.y) < 70.0:
		_burst(pl)


func _burst(pl: Node) -> void:
	if state != DISGUISE and state != PEN and state != STAMPEDE:
		return
	state = BURST
	_t = 0.32
	bursts += 1
	_resize(Vector2(38.0, 64.0))
	if pl != null:
		z._dir = signf(pl.global_position.x - z.global_position.x + 0.01)
	z.velocity.y = -160.0
	Sfx.play("shr_burst", z.global_position, 3.0, 0.1, 3)
	var m := _main()
	if Art.on_screen(z, z.global_position):
		for i in Quality.scaled(10, Quality.gore()):   # ענן צמר
			var dbr = DebrisScript.new()
			m.add_child(dbr)
			dbr.setup(z.global_position + Vector2(randf_range(-16, 16), -randf_range(10, 34)), Vector2(randf_range(4, 8), randf_range(3, 6)), Color("eee8da").darkened(randf() * 0.15), Vector2(randf_range(-160, 160) + _wind() * 120.0, -randf_range(120, 320)))
	var fl := Fleece.new()
	fl.side = z._dir
	m.add_child(fl)
	fl.global_position = z.global_position + Vector2(0, -24)
	for s in z.get_tree().get_nodes_in_group("s55_sheep"):   # העדר נבהל
		if absf(s.global_position.x - z.global_position.x) < 200.0:
			s.flee(z.global_position.x, 2.0)


func _start_snip() -> void:
	state = SNIP_W
	_t = SNIP_WIND
	_glint = SNIP_WIND
	z.velocity.x *= 0.3
	Sfx.play("shr_open", z.global_position, 0.0, 0.1, 3)


# העדר התפזר לידו (stage / ירייה בכבשה)
func scare() -> void:
	if state == DISGUISE and not learned_pass:
		_burst(player())


# ============================================================
#  נזק
# ============================================================
func on_damage(amount: int, hit_pos: Vector2, dir: Vector2, src: Dictionary) -> bool:
	if z.dead:
		return true
	if _boss():
		return _boss_damage(amount, hit_pos, dir, src)
	if state == DISGUISE or state == PEN or state == STAMPEDE:
		var pl := player()
		var far: bool = pl != null and absf(pl.global_position.x - z.global_position.x) > FOUND_R
		if far and str(src.get("source", "bullet")) in ["bullet", "melee"]:
			found += 1
			var m := _main()
			if m != null:
				var n := int(m.get_meta("shr_found", 0)) + 1
				m.set_meta("shr_found", n)
				if n <= 3:
					z._popup("FOUND ONE!", Color("ffd34a"), 15, -60.0)
				if n == 1 and pl != null and pl.has_method("_say"):
					pl._say("That sheep has boots...", Color("ffd34a"))
		_burst(pl)
	return true


func on_death() -> void:
	if _boss():
		_boss_death()
		return
	if state == DISGUISE or state == PEN or state == STAMPEDE:
		var fl := Fleece.new()
		fl.side = z._dir
		_main().add_child(fl)
		fl.global_position = z.global_position + Vector2(0, -20)
	# המספריים נופלים ומסתובבים
	var sh := LooseShears.new()
	sh.k = z.sc
	sh.vel = Vector2(randf_range(-120, 120), -randf_range(220, 360))
	_main().add_child(sh)
	sh.global_position = z.global_position + Vector2(z._dir * 12.0, -30.0 * z.sc)
	sh.ground_y = z.global_position.y


# ============================================================
#  בוס: THE ESTANCIERO
# ============================================================
func _boss_physics(pl: Node, has: bool, d: Vector2, delta: float) -> void:
	_fly += delta * (24.0 if state == B_CHARGE or state == B_CHARGE_W else 9.0)
	var want_open := 0.25
	match state:
		B_SNAP_W, B_CHARGE_W, B_CHARGE:
			want_open = 1.0
		B_SNAP, B_STUCK:
			want_open = 0.0
	_open = move_toward(_open, want_open, delta * (3.0 if want_open > _open else 12.0))
	_smoke_t -= delta
	if _smoke_t <= 0.0 and Art.on_screen(z, z.global_position, 300.0):
		_smoke_t = 0.08 if state == B_CHARGE or state == B_CHARGE_W else 0.3
		Particles.burst(_main(), _exhaust(), "smoke", Vector2(_wind() * 0.8, -1.0), 1)
	_eng_snd -= delta
	if _met and _eng_snd <= 0.0 and Art.on_screen(z, z.global_position, 200.0):
		_eng_snd = 0.9
		Sfx.play("shr_engine", z.global_position, -6.0, 0.05, 2)
	if has and not _met and absf(d.x) < 900.0:
		_met = true
		z._noticed = true
		Game.story.emit("boss", {"z": z})
		Sfx.play("shr_rev", z.global_position, 4.0, 0.0, 1)
		z._popup("THE ESTANCIERO", Color("ffb050"), 22, -150.0)
	if not has or not _met:
		z.velocity.x = move_toward(z.velocity.x, 0.0, 800.0 * delta)
		return
	_charge_cd -= delta
	_call_cd -= delta
	var adx := absf(d.x)
	match state:
		B_WALK:
			z._dir = signf(d.x) if adx > 8.0 else z._dir
			var v: float = z._dir * z.chase_speed if adx > B_SNAP_R * 0.6 else 0.0
			z.velocity.x = move_toward(z.velocity.x, v, 600.0 * delta)
			z._walk_phase += delta * absf(z.velocity.x) / 18.0
			if z.is_on_floor() and z.is_on_wall() and absf(z.velocity.x) < 20.0:
				z.velocity.y = -620.0
			if _call_cd <= 0.0 and _calls < CALLS and (z.hp < z.max_hp * 0.75 or _calls == 0):
				state = B_CALL
				_t = 1.0
				Sfx.play("shr_whistle", z.global_position, 4.0, 0.0, 1)
				z._popup("THE FLOCK!", Color("f0e8d0"), 18, -150.0)
			elif _cd <= 0.0 and adx < B_SNAP_R and absf(d.y) < 160.0:
				state = B_SNAP_W
				_t = B_SNAP_WIND
				_high = _jumps >= JUMP_LEARN
				Sfx.play("shr_hyd", z.global_position, 2.0, 0.05, 2)
			elif _charge_cd <= 0.0 and adx > B_CHARGE_R.x and adx < B_CHARGE_R.y and absf(d.y) < 120.0:
				state = B_CHARGE_W
				_t = B_CHARGE_WIND
				Sfx.play("shr_rev", z.global_position, 4.0, 0.05, 2)
		B_SNAP_W:
			z.velocity.x = move_toward(z.velocity.x, 0.0, 1200.0 * delta)
			z._dir = signf(d.x) if adx > 8.0 else z._dir
			_glint = 0.2
			if _t <= 0.0:
				state = B_SNAP
				_t = 0.14
				_hit_done = false
				b_snaps += 1
				if _high:
					b_high += 1
					if b_high == 1:
						z._popup("IT READS YOUR JUMP", Color("ff8a6a"), 16, -150.0)
				Sfx.play("shr_snip", z.global_position, 6.0, 0.0, 2)
				var cam: Camera2D = z.get_viewport().get_camera_2d()
				if cam != null and cam.has_method("shake") and Art.on_screen(z, z.global_position):
					cam.shake(6.0, 0.2)
				var w := B_SNAP_R
				var y0 := (-120.0 if not _high else -230.0)
				var hh := (120.0 if not _high else 200.0)
				_snap_rect = Rect2(z.global_position + Vector2(0.0 if z._dir > 0 else -w, y0), Vector2(w, hh))
				if pl._roll_t <= 0.0 and _snap_rect.intersects(pl.body_rect()):
					_hit_done = true
					b_snap_hits += 1
					pl.hurt(B_SNAP_DMG, Vector2(z._dir * 1.6, -0.5))
				elif not _high and absf(d.x) < w + 20.0 and pl.global_position.y < _snap_rect.position.y + 10.0:
					_jumps += 1   # קפצת מעל הגזיזה
					b_jumped += 1
		B_SNAP:
			z.velocity.x = 0.0
			if _t <= 0.0:
				state = B_RECOVER
				_t = 0.6
				_cd = 1.0
		B_CHARGE_W:
			z.velocity.x = move_toward(z.velocity.x, -z._dir * 30.0, 900.0 * delta)
			z._dir = signf(d.x) if adx > 8.0 else z._dir
			if _t <= 0.0:
				state = B_CHARGE
				_charge_t = B_CHARGE_T
				_hit_done = false
				b_charges += 1
				Sfx.play("shr_hyd", z.global_position, 4.0, 0.0, 1)
		B_CHARGE:
			_charge_t -= delta
			z.velocity.x = z._dir * B_CHARGE_V
			z._walk_phase += delta * 18.0
			if Engine.get_physics_frames() % 4 == 0 and Art.on_screen(z, z.global_position):
				Particles.burst(_main(), z.global_position + Vector2(-z._dir * 20.0, -4.0), "smoke", Vector2(-z._dir, -0.4), 2)
			if not _hit_done and absf(d.x) < 60.0 * z.sc * 0.6 and absf(d.y + 40.0) < 110.0:
				_hit_done = true
				if pl._roll_t <= 0.0:
					b_charge_hits += 1
				pl.hurt(2, Vector2(z._dir * 2.2, -0.7))
				Sfx.play("shr_snip", z.global_position, 6.0, 0.0, 2)
			var wall: bool = z.is_on_wall() and _charge_t < B_CHARGE_T - 0.1
			var past: bool = signf(d.x) != z._dir and adx > 260.0
			if wall:
				state = B_STUCK
				_t = B_STUCK_T
				b_stuck += 1
				Sfx.play("metal_ping", z.global_position, 6.0, 0.0, 1)
				Particles.burst(_main(), z.global_position + Vector2(z._dir * 60.0, -60.0), "spark", Vector2(-z._dir, -0.4), 14)
				z._popup("STUCK - HIT THE ENGINE!", Color("ffd34a"), 16, -150.0)
				var cam2: Camera2D = z.get_viewport().get_camera_2d()
				if cam2 != null and cam2.has_method("shake"):
					cam2.shake(12.0, 0.4)
			elif _charge_t <= 0.0 or past:
				state = B_RECOVER
				_t = 0.7
				_charge_cd = randf_range(4.0, 6.0)
		B_STUCK:
			z.velocity.x = 0.0
			if Engine.get_physics_frames() % 6 == 0 and Art.on_screen(z, z.global_position):
				Particles.burst(_main(), _engine_pos(), "spark", Vector2.UP, 2)
			if _t <= 0.0:
				state = B_RECOVER
				_t = 0.4
				_charge_cd = randf_range(4.0, 6.0)
		B_CALL:
			z.velocity.x = move_toward(z.velocity.x, 0.0, 800.0 * delta)
			if _t <= 0.0:
				_call_flock(pl)
				state = B_RECOVER
				_t = 0.5
				_call_cd = CALL_EVERY
		B_RECOVER:
			z.velocity.x = move_toward(z.velocity.x, 0.0, 900.0 * delta)
			if _t <= 0.0:
				state = B_WALK


func _call_flock(pl: Node) -> void:
	_calls += 1
	b_calls += 1
	var m := _main()
	var st = m.get("_stage")
	var lw: float = float(st.level_w) if st != null else z.global_position.x + 800.0
	var dir := -1.0
	var x0 := minf(pl.global_position.x + 620.0, lw - 60.0)
	if x0 < pl.global_position.x + 300.0:   # אתה בקצה הימני: העדר בא משמאל
		dir = 1.0
		x0 = pl.global_position.x - 620.0
	for i in 10:
		var s := Sheep.new()
		s.home_x = x0 - dir * float(i) * 26.0 + randf_range(-10, 10)
		s.position = Vector2(s.home_x, pl.global_position.y if pl.is_on_floor() else z.global_position.y)
		s.ground_y = z.global_position.y
		m.add_child(s)
		s.stampede(dir, randf_range(260.0, 330.0), float(i) * 0.06)
	for i in CALL_SHEARERS:
		var sx := x0 - dir * (60.0 + float(i) * 110.0)
		var nz: Node = m._spawn_zombie(sx, z.global_position.y, z.kind, RandomNumberGenerator.new())
		if nz != null and nz.type_mod != null:
			nz.type_mod.state = DISGUISE
			nz.type_mod.stampede(dir, 300.0)
	Sfx.play("w55_stampede", Vector2(x0, z.global_position.y), 4.0, 0.0, 1)


func _engine_local() -> Vector2:   # מקומי (יחידות ציור)
	return Vector2(-14.0, -46.0)


func _engine_pos() -> Vector2:
	var e := _engine_local()
	return z.global_position + Vector2(e.x * z._dir * z.wf * z.sc, e.y * z.sc)


func _exhaust() -> Vector2:
	return z.global_position + Vector2(-20.0 * z._dir * z.sc, -66.0 * z.sc)


func _boss_damage(_amount: int, hit_pos: Vector2, dir: Vector2, src: Dictionary) -> bool:
	var s := str(src.get("source", "bullet"))
	if not (s == "bullet" or s == "melee"):
		_hit_kind = "blast"
		return true
	var lx: float = (hit_pos.x - z.global_position.x) * z._dir / (z.sc * z.wf)
	var ly: float = (hit_pos.y - z.global_position.y) / z.sc
	var behind: bool = dir.x * z._dir > 0.0
	var above: bool = dir.y > 0.45
	if state == B_STUCK:
		_hit_kind = "open"
	elif behind or above or (lx < -6.0 and ly < -34.0 and ly > -62.0):
		_hit_kind = "engine"
		engine_hits += 1
		if Art.on_screen(z, hit_pos):
			Particles.burst(_main(), hit_pos, "spark", Vector2(-dir.x, -0.6), 3)
		if engine_hits % 6 == 1:
			z._popup("ENGINE", Color("ffd34a"), 14, -120.0)
	elif lx > 4.0 and ly > -40.0:
		_hit_kind = "front"
		front_hits += 1
		if front_hits % 9 == 1 and engine_hits < 3:
			z._popup("SHOOT THE ENGINE ON HIS BACK", Color("ffd34a"), 14, -150.0)
	else:
		_hit_kind = "body"
	return true


func damage_mult(zone: String, _src: Dictionary) -> float:
	if not _boss():
		return 1.0
	# (zombie.gd כבר מכפיל ראש של בוס פי 2, והמנוע בגובה הראש: מכפילים לפי נזק גוף ולא לפי נזק ראש)
	var hk := 0.2 if zone == "head" else 1.0
	match _hit_kind:
		"engine":
			return ENGINE_MULT * hk
		"open":
			return OPEN_MULT * hk
		"front":
			return FRONT_MULT * (0.5 if zone == "head" else 1.0)
	return 0.5 if zone == "head" else 1.0


func _boss_death() -> void:
	var m := _main()
	var cam: Camera2D = z.get_viewport().get_camera_2d()
	if cam != null and cam.has_method("shake"):
		cam.shake(22.0, 0.9)
	Sfx.play("explosion", z.global_position, 6.0, 0.0, 1)
	Sfx.play("shr_hyd", z.global_position, 6.0, 0.0, 1)
	for i in 3:   # המנוע מתפוצץ (אפקט בלבד)
		var fx = Boom.Explosion.new()
		fx.radius = 70.0 + float(i) * 25.0
		fx.on_ground = i == 2
		m.add_child(fx)
		fx.global_position = _engine_pos() + Vector2((float(i) - 1.0) * 40.0, float(i) * 30.0)
	for i in Quality.scaled(24, Quality.gore()):   # צמר + חלקי מנוע
		var dbr = DebrisScript.new()
		m.add_child(dbr)
		var wool := i % 3 != 0
		dbr.setup(_engine_pos() + Vector2(randf_range(-30, 30), randf_range(-30, 30)), Vector2(randf_range(4, 10), randf_range(3, 8)), Color("eee8da") if wool else Color("4a4e52"), Vector2(randf_range(-380, 380), -randf_range(200, 560)))
	FleshFx.burst(m, z.global_position + Vector2(0, -80.0 * 0.5 * z.sc), Vector2(z._dir, -0.5), z.skin, "body", true, true, false)
	z._spray_blood(z.global_position + Vector2(0, -60.0 * z.sc * 0.5), Vector2(-z._dir, -0.8), 22, 520.0)
	var sh := LooseShears.new()
	sh.k = z.sc * 1.2
	sh.big = true
	sh.vel = Vector2(z._dir * 260.0, -520.0)
	m.add_child(sh)
	sh.global_position = z.global_position + Vector2(z._dir * 50.0, -60.0 * z.sc)
	sh.ground_y = z.global_position.y


# ============================================================
#  ציור
# ============================================================
func wants_redraw() -> bool:
	return true


func draw() -> bool:
	if _boss():
		return _draw_boss()
	if (state == DISGUISE or state == PEN or state == STAMPEDE) and not z.dead:
		return _draw_disguise()
	begin_draw()
	var sk := col(z.skin)
	var skd := col(Art.shade(z.skin, 0.22))
	var f: Array = feet(5.5, 2.6)
	var lean := 0.0
	match state:
		SNIP_W:
			lean = -2.0
		SNIP:
			lean = 5.0
			f = [Vector2(9, 0), Vector2(-6, 0)]
		CHASE:
			lean = 3.0
		BURST:
			lean = -3.0
	var hip := Vector2(0, -24)
	var sh := Vector2(3.0 + lean, -42)
	# bombachas: מכנסיים רחבים
	z._leg(hip + Vector2(-3, 0), f[1], col(Art.shade(z.pants, 0.25)), skd, col(z.shoe))
	z._leg(hip + Vector2(3, 0), f[0], col(z.pants), sk, col(z.shoe))
	Art.fill(z, PackedVector2Array([hip + Vector2(-7, -2), hip + Vector2(7, -2), hip + Vector2(8, 8), hip + Vector2(2, 12), hip + Vector2(-6, 11), hip + Vector2(-8, 6)]), col(z.pants), Art.OUTLINE, 1.0)
	# יד אחורית
	z._arm(sh + Vector2(-3, 2), sh + Vector2(-5.0 + sin(z._time * 2.5), 14.0), skd, col(Art.shade(z.shirt, 0.25)))
	# גוף: חולצת פלנל + סינר עור מדמם
	var body := PackedVector2Array([sh + Vector2(-8, -1), sh + Vector2(8, 0), hip + Vector2(7, -2), hip + Vector2(-7, -1), sh + Vector2(-9, 5)])
	Art.fill_shaded(z, body, col(z.shirt), 0.15, 0.35)
	for q in 3:   # משבצות
		DrawBatch.line(z, sh + Vector2(-7.0 + float(q) * 5.0, 0.5), hip + Vector2(-6.0 + float(q) * 5.0, -2.0), Color(0, 0, 0, 0.18), 1.0)
	var apron := PackedVector2Array([sh + Vector2(-4, 4), sh + Vector2(8, 4), hip + Vector2(9, 9), hip + Vector2(6, 15), hip + Vector2(-3, 14), hip + Vector2(-6, 9)])
	Art.fill_shaded(z, apron, col(Color("6a4a30")), 0.1, 0.35)
	if not z.dead or true:
		Art.oval(z, hip + Vector2(3, 2), 4.0, 6.0, Color(0.48, 0.04, 0.04, 0.75), 0.2, Art.NONE)   # דם
		Art.oval(z, sh + Vector2(4, 9), 2.6, 3.2, Color(0.45, 0.04, 0.04, 0.6), -0.3, Art.NONE)
		DrawBatch.line(z, hip + Vector2(1, 6), hip + Vector2(0.5, 13), Color(0.45, 0.04, 0.04, 0.7), 1.2)
	DrawBatch.line(z, sh + Vector2(-4, 4), sh + Vector2(-2, -2), col(Color("3a2414")), 1.4)
	# ראש: ברט, שפם עבות, עיניים אדומות
	var head := sh + Vector2(3.0, -9.0)
	z._head(head, sk)
	face(head)
	Art.fill(z, PackedVector2Array([head + Vector2(-8, -3), head + Vector2(-5, -9), head + Vector2(3, -10), head + Vector2(8, -6), head + Vector2(6, -4), head + Vector2(-6, -2)]), col(_beret), Art.OUTLINE, 1.0)
	DrawBatch.circle(z, head + Vector2(0, -10), 1.2, col(_beret))   # הזנב של הברט
	DrawBatch.polyline(z, PackedVector2Array([head + Vector2(1.5, 2.6), head + Vector2(4.5, 2.0), head + Vector2(7.5, 3.6)]), col(_stache), 2.0)
	if not z.dead:
		DrawBatch.circle(z, head + Vector2(4.0, -1.4), 1.1, Color(1.0, 0.25, 0.2))
	# יד קדמית + המספריים
	var hand := sh + Vector2(10.0, 9.0)
	if state == SNIP_W:
		hand = sh + Vector2(7.0, -2.0)
	elif state == SNIP or z._bite_anim > 0.0:
		hand = sh + Vector2(15.0, 3.0)
	elif state == LEAP:
		hand = sh + Vector2(9.0, -10.0)
	z._arm(sh + Vector2(2, 2), hand, sk, col(z.shirt))
	DrawBatch.line(z, sh + Vector2(4, 4), hand.lerp(sh + Vector2(4, 4), 0.4), Color(0.48, 0.05, 0.05, 0.6), 1.4)   # אמה מדממת
	_shears(hand, _open, 1.45)
	end_draw()
	return true


# מספרי גז"ז: קשת קפיץ בצד היד, שני להבים משולשים לכיוון הקצה (מקומי, פונה ימינה)
func _shears(hand: Vector2, open: float, k: float) -> void:
	var a := open * 0.55
	var base := hand + Vector2(2.0, 0) * k
	var steel := col(Color("c8ccd2"))
	var dark := col(Color("6a6e74"))
	DrawBatch.arc(z, hand + Vector2(-2.5, 0) * k, 3.5 * k, PI * 0.5, PI * 1.5, 8, col(Color("4a4a50")), 1.6 * k)   # קשת הקפיץ
	for s: float in [-1.0, 1.0]:
		var dv := Vector2.from_angle(s * a)
		var nv := dv.orthogonal() * s
		var tip := base + dv * 17.0 * k
		var bl := PackedVector2Array([base + nv * 1.6 * k, base + dv * 4.0 * k - nv * 1.4 * k, tip, base + dv * 6.0 * k + nv * 2.6 * k])
		DrawBatch.colored_polygon(z, bl, steel if s > 0 else dark)
		bl.append(bl[0])
		DrawBatch.polyline(z, bl, Art.OUTLINE, 0.8)
		DrawBatch.line(z, base + dv * 4.0 * k - nv * 1.4 * k, tip, Color(1, 1, 1, 0.8), 0.7)
		if not z.dead:
			DrawBatch.line(z, base + dv * 8.0 * k, tip - dv * 2.0 * k, Color(0.5, 0.05, 0.05, 0.6), 0.8)   # דם על הלהב
	if _glint > 0.0 and not z.dead:
		var gp := base + Vector2.from_angle(a) * 15.0 * k
		Art.glow(z, gp, 6.0 * k, Color(1, 1, 1, 0.8 * clampf(_glint * 3.0, 0.0, 1.0)))
		DrawBatch.line(z, gp + Vector2(-4, 0) * k, gp + Vector2(4, 0) * k, Color(1, 1, 1, 0.9), 0.8)
		DrawBatch.line(z, gp + Vector2(0, -4) * k, gp + Vector2(0, 4) * k, Color(1, 1, 1, 0.9), 0.8)


# מחופש לכבשה: על ארבע מתחת לגיזה, ראש כבשה פשוט, רגליים של בן אדם מאחור (הסימן)
func _draw_disguise() -> bool:
	begin_draw()
	var p: float = z._walk_phase
	var bob := absf(sin(p)) * 1.0
	var wool := col(Color("e6dfcf"))
	var wool_d := col(Color("c4baa2"))
	# רגליים אחוריות: ברכיים על הקרקע, מגפיים + bombachas (לא רגלי כבשה!)
	var kx := -12.0
	for s in 2:
		var sx := kx + float(s) * 5.0 + sin(p + float(s) * PI) * 2.0
		Art.limb(z, PackedVector2Array([Vector2(sx + 3, -16 - bob), Vector2(sx, -4), Vector2(sx - 9, -3)]), 5.0, col(Art.shade(z.pants, 0.15 * float(1 - s))))
		Art.fill(z, PackedVector2Array([Vector2(sx - 9, -6), Vector2(sx - 14, -5), Vector2(sx - 15, 0), Vector2(sx - 6, 0)]), col(z.shoe), Art.OUTLINE, 0.9)   # מגף
	# ידיים מקדימה (במקום רגלי כבשה), מדממות
	for s in 2:
		var hx := 10.0 + float(s) * 4.0 + sin(p + float(s) * PI + 1.0) * 2.5
		Art.limb(z, PackedVector2Array([Vector2(hx - 1, -16 - bob), Vector2(hx + 1, -1)]), 3.4, col(Art.shade(z.skin, 0.1 * float(s))))
		DrawBatch.circle(z, Vector2(hx + 1.5, -1.0), 2.0, col(Color(0.5, 0.08, 0.06)))
	# הגיזה: ענן צמר
	var cs := [Vector2(-10, -22), Vector2(-3, -26), Vector2(5, -25), Vector2(11, -21), Vector2(-12, -15), Vector2(0, -16), Vector2(10, -15)]
	for c: Vector2 in cs:
		Art.disc(z, c + Vector2(0, -bob), 7.5, wool_d)
	for c: Vector2 in cs:
		DrawBatch.circle(z, c + Vector2(-0.5, -1.2 - bob), 6.4, wool)
	for q in 5:   # תלתלים
		DrawBatch.arc(z, Vector2(-10.0 + float(q) * 5.0, -24.0 - bob + float(q % 2) * 4.0), 2.2, 0.0, PI * 1.6, 6, wool_d, 0.8)
	if not z.dead:
		Art.oval(z, Vector2(4, -18 - bob), 3.5, 2.5, Color(0.5, 0.06, 0.05, 0.65), 0.0, Art.NONE)   # דם על הצמר
		Art.oval(z, Vector2(-6, -12 - bob), 2.5, 1.8, Color(0.45, 0.06, 0.05, 0.5), 0.0, Art.NONE)
	# ראש כבשה פשוט (מסכה) - העיניים האדומות שלו נוצצות מבפנים
	var hc := Vector2(18.0, -23.0 - bob + sin(z._time * 1.3) * 0.8)
	Art.oval_shaded(z, hc, 5.2, 4.2, col(Color("d8cfc0")), 0.25)
	Art.fill(z, PackedVector2Array([hc + Vector2(-2, -3), hc + Vector2(-6, -6), hc + Vector2(-4, -1)]), col(Color("c8bca8")), Art.OUTLINE, 0.8)   # אוזן
	DrawBatch.line(z, hc + Vector2(1, 3), hc + Vector2(6, 2), col(Color("5a2a24")), 1.0)   # תפר / חתך
	var eye_a := 0.35 if learned_pass else 0.9
	if not z.dead:
		DrawBatch.circle(z, hc + Vector2(1.5, -1.2), 1.0, Color(1.0, 0.2, 0.15, eye_a))
		Art.glow(z, hc + Vector2(1.5, -1.2), 3.5, Color(1.0, 0.2, 0.15, 0.45 * eye_a))
	DrawBatch.line(z, hc + Vector2(-4, 3.5), hc + Vector2(-1, 6), Color(0.5, 0.05, 0.05, 0.8), 1.0)   # דם מטפטף מהצוואר
	# קצה המספריים מבצבץ מתחת לצמר
	if _glint > 0.0:
		_shears(Vector2(10, -10 - bob), 0.1, 0.8)
	end_draw()
	return true


func _draw_boss() -> bool:
	begin_draw()
	var sk := col(z.skin)
	var skd := col(Art.shade(z.skin, 0.22))
	var f: Array = feet(6.0, 2.6)
	var lean := 0.0
	match state:
		B_SNAP_W:
			lean = -3.0
		B_SNAP:
			lean = 6.0
			f = [Vector2(10, 0), Vector2(-7, 0)]
		B_CHARGE_W:
			lean = -4.0
		B_CHARGE:
			lean = 7.0
		B_STUCK:
			lean = 8.0
			f = [Vector2(11, 0), Vector2(-9, 0)]
		B_CALL:
			lean = -2.0
	var hip := Vector2(0, -24)
	var sh := Vector2(3.0 + lean, -43)
	# המכונה על הגב (מאחור): מסגרת, מנוע עם צלעות, גלגל תנופה, אגזוז
	var eng := Vector2(-15.0 + lean * 0.4, -46.0)
	var metal := col(Color("5a5e62"))
	var metal_d := col(Color("33363a"))
	Art.fill_shaded(z, PackedVector2Array([eng + Vector2(-9, -13), eng + Vector2(5, -13), eng + Vector2(6, 15), eng + Vector2(-9, 15)]), metal, 0.2, 0.35, Art.OUTLINE, 1.0)
	for q in 5:   # צלעות קירור
		DrawBatch.line(z, eng + Vector2(-10, -10.0 + float(q) * 4.0), eng + Vector2(-3, -10.0 + float(q) * 4.0), metal_d, 1.2)
	var fw := eng + Vector2(-5, 8)
	Art.disc(z, fw, 6.5, col(Color("7a3a2a")), Art.OUTLINE, 1.0)   # גלגל תנופה אדום
	for q in 3:
		var a := _fly + float(q) * TAU / 3.0
		DrawBatch.line(z, fw, fw + Vector2.from_angle(a) * 5.5, metal_d, 1.4)
	var hot: float = 1.0 if state == B_STUCK else (0.6 if state == B_CHARGE or state == B_CHARGE_W else 0.25)
	Art.glow(z, eng + Vector2(-2, -2), 8.0 + 5.0 * hot, Color(1.0, 0.45, 0.1, 0.3 * hot))
	DrawBatch.line(z, eng + Vector2(-6, -13), eng + Vector2(-8, -24), metal_d, 2.4)   # אגזוז
	DrawBatch.rect(z, Rect2(eng + Vector2(4, -6), Vector2(4, 9)), col(Color("b02a1e")))   # מיכל דלק
	# רגליים (מגפיים גבוהים)
	z._leg(hip + Vector2(-3, 0), f[1], col(Art.shade(z.pants, 0.25)), skd, col(z.shoe))
	z._leg(hip + Vector2(3, 0), f[0], col(z.pants), sk, col(z.shoe))
	# יד שמאל (אחורית): מחזיקה עור כבשה פשוט
	var bh := sh + Vector2(-6.0, 15.0)
	z._arm(sh + Vector2(-3, 2), bh, skd, col(Art.shade(z.shirt, 0.25)))
	Art.fill(z, PackedVector2Array([bh + Vector2(-3, 0), bh + Vector2(4, 0), bh + Vector2(6, 12), bh + Vector2(0, 16), bh + Vector2(-5, 11)]), col(Color("d8cfb8")), Art.OUTLINE, 0.9)
	# גוף: חולצה, וסט עור, רתמת המכונה, סינר
	var body := PackedVector2Array([sh + Vector2(-9, -1), sh + Vector2(9, 0), hip + Vector2(8, -2), hip + Vector2(-8, -1), sh + Vector2(-10, 6)])
	Art.fill_shaded(z, body, col(z.shirt), 0.15, 0.35)
	var apron := PackedVector2Array([sh + Vector2(-3, 5), sh + Vector2(9, 5), hip + Vector2(10, 10), hip + Vector2(6, 16), hip + Vector2(-3, 15), hip + Vector2(-6, 10)])
	Art.fill_shaded(z, apron, col(Color("5a3c26")), 0.1, 0.35)
	Art.oval(z, hip + Vector2(4, 3), 4.5, 7.0, Color(0.48, 0.04, 0.04, 0.8), 0.2, Art.NONE)
	Art.oval(z, sh + Vector2(4, 10), 3.2, 3.5, Color(0.45, 0.04, 0.04, 0.6), -0.3, Art.NONE)
	DrawBatch.line(z, sh + Vector2(-8, 0), hip + Vector2(-6, -4), col(Color("2a1e16")), 2.4)   # רצועות רתמה
	DrawBatch.line(z, sh + Vector2(4, -1), hip + Vector2(-8, -6), col(Color("2a1e16")), 2.4)
	# ראש: ברט גדול, שפם לבן, עין אחת עם מונוקל שבור
	var head := sh + Vector2(3.0, -9.0)
	z._head(head, sk)
	face(head)
	Art.fill(z, PackedVector2Array([head + Vector2(-9, -3), head + Vector2(-6, -10), head + Vector2(4, -11), head + Vector2(10, -6), head + Vector2(7, -4), head + Vector2(-7, -2)]), col(Color("141418")), Art.OUTLINE, 1.0)
	DrawBatch.polyline(z, PackedVector2Array([head + Vector2(1, 2.6), head + Vector2(4.5, 1.8), head + Vector2(8.5, 4.2)]), col(Color("d8d4cc")), 2.4)
	if not z.dead:
		DrawBatch.circle(z, head + Vector2(4.0, -1.4), 1.2, Color(1.0, 0.25, 0.2))
		Art.glow(z, head + Vector2(4.0, -1.4), 4.0, Color(1.0, 0.2, 0.15, 0.5))
	DrawBatch.arc(z, head + Vector2(4.0, -1.4), 2.6, 0.0, TAU, 10, col(Color("c8a840")), 0.7)
	# זרוע ההנעה המפרקית: מהמנוע מעל הכתף אל המספריים ההידראוליים (יד ימין)
	var j1 := eng + Vector2(2, -16)
	var j2 := sh + Vector2(2, -10)
	var tool := sh + Vector2(13.0, 6.0)
	match state:
		B_SNAP_W:
			tool = sh + Vector2(10.0, -4.0) if not _high else sh + Vector2(6.0, -14.0)
		B_SNAP:
			tool = sh + Vector2(19.0, 4.0) if not _high else sh + Vector2(16.0, -12.0)
		B_CHARGE_W, B_CHARGE:
			tool = sh + Vector2(17.0, 8.0)
		B_STUCK:
			tool = sh + Vector2(20.0, 18.0)
	Art.limb(z, PackedVector2Array([j1, j2]), 2.2, metal)
	Art.limb(z, PackedVector2Array([j2, tool + Vector2(-4, -2)]), 2.0, metal)
	Art.disc(z, j1, 1.8, metal_d, Art.OUTLINE, 0.6)
	Art.disc(z, j2, 1.8, metal_d, Art.OUTLINE, 0.6)
	z._arm(sh + Vector2(2, 2), tool + Vector2(-5, 0), sk, col(z.shirt))
	_hyd_shears(tool, _open)
	end_draw()
	return true


# מספריים הידראוליים: גוף צילינדר, בוכנה, שני להבים משוננים ארוכים (מקומי, פונה ימינה)
func _hyd_shears(p: Vector2, open: float) -> void:
	var a := open * 0.6
	var up := -0.25 if (_high and (state == B_SNAP_W or state == B_SNAP)) else 0.0
	Art.fill_shaded(z, PackedVector2Array([p + Vector2(-6, -3), p + Vector2(4, -3), p + Vector2(4, 3), p + Vector2(-6, 3)]), col(Color("d0a020")), 0.2, 0.35, Art.OUTLINE, 0.9)
	DrawBatch.line(z, p + Vector2(-4, -3.5), p + Vector2(2 + open * 3.0, -5.5), col(Color("c8ccd0")), 1.2)   # בוכנה
	for s: float in [-1.0, 1.0]:
		var dv := Vector2.from_angle(up + s * a)
		var nv := dv.orthogonal() * s
		var b0 := p + Vector2(4, 0)
		var tip := b0 + dv * 26.0
		var pts := PackedVector2Array([b0 + nv * 2.4, b0 - nv * 1.2])
		for q in 5:   # שיניים (מסרק)
			var u := (float(q) + 1.0) / 6.0
			pts.append(b0.lerp(tip, u) - nv * (1.2 + (1.6 if q % 2 == 0 else 0.4)))
		pts.append(tip)
		pts.append(b0 + dv * 18.0 + nv * 2.6)
		DrawBatch.colored_polygon(z, pts, col(Color("d4d8de")) if s > 0 else col(Color("8a8e94")))
		DrawBatch.polyline(z, pts, Art.OUTLINE, 0.8)
		if not z.dead:
			DrawBatch.line(z, b0 + dv * 10.0, tip - dv * 3.0, Color(0.5, 0.05, 0.05, 0.7), 1.0)
	if state == B_SNAP_W or state == B_CHARGE_W:
		var gp := p + Vector2(4, 0) + Vector2.from_angle(up + a) * 24.0
		Art.glow(z, gp, 7.0, Color(1, 1, 1, 0.6 + 0.4 * sin(z._time * 30.0)))


# ============================================================
#  כבשה: לא מזיקה, לא מתה. ירייה = ענן צמר + בורחת. חוסמת יריות (גוף בשכבה 4).
# ============================================================
class Sheep extends Node2D:
	static var shot_count := 0       # לבדיקות
	var home_x := 0.0
	var roam := 80.0
	var ground_y := 630.0
	var pen := Vector2(-INF, INF)    # (מכלאה) גבולות
	var mode := 0                    # 0 רועה, 1 בורחת, 2 דוהרת
	var _dir := 1.0
	var _vx := 0.0
	var _goal := 0.0
	var _t := 0.0
	var _tt := 0.0
	var _walk := 0.0
	var _delay := 0.0
	var _run_v := 0.0
	var _start_x := 0.0
	var _black := false
	var _k := 1.0
	var _tint := 0.0
	var _head_dn := 0.0
	var _hop := 0.0
	var _body: StaticBody2D = null

	class Wool extends StaticBody2D:
		var sheep = null
		func take_damage(_a, p: Vector2, d: Vector2, _e := false, _s := {}) -> void:
			if sheep != null and is_instance_valid(sheep):
				sheep.shot(p, d)

	func _ready() -> void:
		add_to_group("s55_sheep")
		add_to_group("blastable")
		z_index = 2
		_black = randf() < 0.25
		_k = randf_range(0.9, 1.12)
		_tint = randf_range(-0.06, 0.08)
		_dir = -1.0 if randf() < 0.5 else 1.0
		_goal = home_x
		_t = randf_range(0.0, 3.0)
		_tt = randf() * 10.0
		_body = Wool.new()
		_body.sheep = self
		_body.collision_layer = 4
		_body.collision_mask = 0
		var cs := CollisionShape2D.new()
		var rs := RectangleShape2D.new()
		rs.size = Vector2(30, 20) * _k
		cs.shape = rs
		cs.position = Vector2(0, -16) * _k
		_body.add_child(cs)
		add_child(_body)

	func blast_rect() -> Rect2:
		return Rect2(global_position + Vector2(-16, -28), Vector2(32, 28))

	func hit_by_blast(c: Vector2, _r: float) -> void:
		flee(c.x, 3.0)
		_hop = 0.5

	func shot(p: Vector2, d: Vector2) -> void:
		shot_count += 1
		if Art.on_screen(self, p):
			Particles.burst(get_parent(), p, "mist", -d, 4)
			for i in 3:
				var dbr = DebrisScript.new()
				get_parent().add_child(dbr)
				dbr.setup(p, Vector2(randf_range(3, 6), randf_range(2, 5)), Color("eee8da"), Vector2(-d.x * randf_range(40, 160), -randf_range(80, 220)))
			Sfx.play("shr_baa", global_position, -2.0, 0.2, 3)
		if mode != 2:
			flee(p.x - d.x * 100.0, 2.5)
		# הבהלה מתפשטת, וגוזז מחופש לידה קם
		for s in get_tree().get_nodes_in_group("s55_sheep"):
			if s != self and s.mode == 0 and absf(s.global_position.x - global_position.x) < 140.0:
				s.flee(p.x - d.x * 100.0, 2.0)
		for z in get_tree().get_nodes_in_group("zombies"):
			if not z.dead and z.type_mod != null and z.type_mod.has_method("scare") and absf(z.global_position.x - global_position.x) < 130.0:
				z.type_mod.scare()

	func flee(from_x: float, t: float) -> void:
		if mode == 2:
			return
		mode = 1
		_t = t
		_dir = signf(global_position.x - from_x + 0.01)
		_vx = _dir * 60.0
		if randf() < 0.5:
			Sfx.play("shr_baa", global_position, -6.0, 0.25, 3)

	func stampede(dir: float, v: float, delay: float) -> void:
		mode = 2
		_dir = dir
		_run_v = v
		_delay = delay
		_start_x = global_position.x
		pen = Vector2(-INF, INF)
		_t = 12.0

	func _physics_process(delta: float) -> void:
		_tt += delta
		_t -= delta
		var pl := get_tree().get_first_node_in_group("player") as Node2D
		if mode != 2 and pl != null and absf(pl.global_position.x - global_position.x) > 1500.0:
			return
		_hop = maxf(0.0, _hop - delta)
		match mode:
			0:   # רועה: עומדת, מורידה ראש, לפעמים הולכת לנקודה אחרת
				_head_dn = move_toward(_head_dn, 1.0 if absf(_vx) < 5.0 else 0.0, delta * 2.0)
				if _t <= 0.0:
					_t = randf_range(2.0, 5.0)
					_goal = clampf(home_x + randf_range(-roam, roam), pen.x, pen.y)
					if randf() < 0.15 and Art.on_screen(self, global_position):
						Sfx.play("shr_baa", global_position, -10.0, 0.3, 2)
				var dx := _goal - global_position.x
				var v := signf(dx) * 26.0 if absf(dx) > 6.0 else 0.0
				_vx = move_toward(_vx, v, 120.0 * delta)
				# שחקן שרץ לתוך העדר - זזה הצידה
				if pl != null and absf(pl.global_position.x - global_position.x) < 40.0 and absf(pl.global_position.y - global_position.y) < 40.0:
					flee(pl.global_position.x, 0.8)
			1:   # בורחת
				_head_dn = 0.0
				_vx = move_toward(_vx, _dir * 210.0, 700.0 * delta)
				if _t <= 0.0:
					mode = 0
					home_x = global_position.x
					_goal = home_x
					_t = randf_range(1.0, 3.0)
			2:   # דוהרת (מכלאה / הבוס)
				_head_dn = 0.0
				_delay -= delta
				if _delay > 0.0:
					return
				_vx = _dir * _run_v
				if Engine.get_physics_frames() % 7 == 0 and Art.on_screen(self, global_position):
					Particles.burst(get_parent(), global_position + Vector2(-_dir * 10.0, -2.0), "smoke", Vector2(-_dir, -0.3), 1)
				if _t <= 0.0 or absf(global_position.x - _start_x) > 2600.0:
					if pl == null or not Art.on_screen(self, global_position, 60.0):
						queue_free()
						return
		if absf(_vx) > 2.0:
			_dir = signf(_vx)
		var nx := global_position.x + _vx * delta
		if mode != 2:
			nx = clampf(nx, pen.x, pen.y)
		global_position.x = nx
		global_position.y = ground_y
		_walk += delta * absf(_vx) / 6.0
		if Art.on_screen(self, global_position, 60.0):
			queue_redraw()

	func _draw() -> void:
		DrawBatch.begin(self)
		_draw_b()
		DrawBatch.end(self)

	func _draw_b() -> void:
		var k := _k
		var run := mode != 0
		var bob := absf(sin(_walk)) * (2.5 if run else 0.8) + _hop * 20.0
		DrawBatch.set_transform(self, Vector2.ZERO, 0.0, Vector2(_dir * k, k))
		DrawBatch.colored_polygon(self, Art.ellipse(Vector2(0, 0), 15.0, 2.5, 0.0, 12), Color(0, 0, 0, 0.22))
		var leg := Color("2a2420") if not _black else Color("141210")
		for q in 4:   # רגליים דקות
			var lx := -9.0 + float(q) * 6.0
			var sw := sin(_walk + float(q) * PI * 0.5) * (5.0 if run else 2.0)
			DrawBatch.line(self, Vector2(lx, -10 - bob), Vector2(lx + sw, 0), leg, 2.2)
		var wool := Color("ebe4d4").lightened(_tint) if _tint > 0.0 else Color("ebe4d4").darkened(-_tint)
		var wool_d := wool.darkened(0.18)
		var cs := [Vector2(-9, -17), Vector2(-2, -21), Vector2(6, -19), Vector2(-10, -12), Vector2(0, -12), Vector2(8, -13)]
		for c: Vector2 in cs:
			DrawBatch.circle(self, c + Vector2(0, -bob), 7.2, Color(0.12, 0.1, 0.08, 0.9))
		for c: Vector2 in cs:
			DrawBatch.circle(self, c + Vector2(0, -bob), 6.2, wool_d)
		for c: Vector2 in cs:
			DrawBatch.circle(self, c + Vector2(-0.6, -1.4 - bob), 5.0, wool)
		DrawBatch.circle(self, Vector2(-14, -16 - bob), 2.6, wool_d)   # זנב
		# ראש: לבן או שחור, אוזניים
		var hd := _head_dn * 9.0
		var hc := Vector2(13.0, -20.0 - bob + hd)
		var face_c := Color("1e1a18") if _black else Color("e2dccc")
		DrawBatch.colored_polygon(self, Art.ellipse(hc + Vector2(1.5, 0), 5.6, 4.0, 0.3 + _head_dn * 0.5, 12), Color(0.12, 0.1, 0.08, 0.9))
		DrawBatch.colored_polygon(self, Art.ellipse(hc + Vector2(1.5, 0), 4.8, 3.3, 0.3 + _head_dn * 0.5, 12), face_c)
		DrawBatch.colored_polygon(self, PackedVector2Array([hc + Vector2(-2, -2), hc + Vector2(-7, -3 + sin(_tt * 3.0)), hc + Vector2(-3, 0)]), face_c.darkened(0.15))
		DrawBatch.circle(self, hc + Vector2(2.5, -1.0), 0.9, Color("101010") if not _black else Color("c8b070"))
		DrawBatch.set_transform(self, Vector2.ZERO, 0.0, Vector2.ONE)


# ============================================================
#  גיזה שנזרקה (עפה ברוח, מסתובבת, דוהה)
# ============================================================
class Fleece extends Node2D:
	var side := 1.0
	var _v := Vector2.ZERO
	var _t := 0.0
	var _rot := 0.0

	func _ready() -> void:
		z_index = 4
		_v = Vector2(-side * 80.0, -260.0)

	func _process(delta: float) -> void:
		_t += delta
		var st = get_parent().get("_stage")
		var w: float = float(st.wind()) if st != null and st.has_method("wind") else -0.4
		_v += Vector2(w * 420.0 * delta, 300.0 * delta)
		_v.x = clampf(_v.x, -380.0, 380.0)
		_v.y = minf(_v.y, 120.0)
		global_position += _v * delta
		_rot += delta * (3.0 + absf(w) * 4.0)
		modulate.a = clampf(2.6 - _t, 0.0, 1.0)
		if _t > 2.6:
			queue_free()
		queue_redraw()

	func _draw() -> void:
		DrawBatch.begin(self)
		_draw_b()
		DrawBatch.end(self)

	func _draw_b() -> void:
		DrawBatch.set_transform(self, Vector2.ZERO, _rot, Vector2(1.0, 0.6 + 0.4 * absf(sin(_rot))))
		for c: Vector2 in [Vector2(-10, 0), Vector2(-3, -4), Vector2(5, -2), Vector2(11, 1), Vector2(0, 4)]:
			DrawBatch.circle(self, c, 7.0, Color("cfc5ae"))
			DrawBatch.circle(self, c + Vector2(-0.5, -1.0), 5.6, Color("ebe4d4"))
		DrawBatch.colored_polygon(self, Art.ellipse(Vector2(2, 3), 6.0, 2.0, 0.0, 10), Color(0.5, 0.06, 0.05, 0.7))   # הצד הפנימי מדמם
		DrawBatch.set_transform(self, Vector2.ZERO, 0.0, Vector2.ONE)


# ============================================================
#  מספריים שנפלו (מסתובבים באוויר, ננעצים בקרקע ונשארים לרגע)
# ============================================================
class LooseShears extends Node2D:
	var vel := Vector2.ZERO
	var k := 1.0
	var big := false
	var ground_y := 630.0
	var _rot := 0.0
	var _spin := 14.0
	var _t := 0.0
	var _stuck := false

	func _ready() -> void:
		z_index = 4

	func _process(delta: float) -> void:
		_t += delta
		if not _stuck:
			vel.y += 1100.0 * delta
			global_position += vel * delta
			_rot += _spin * delta
			if global_position.y >= ground_y - 6.0 * k and vel.y > 0.0:
				global_position.y = ground_y - 6.0 * k
				_stuck = true
				_rot = PI * 0.5 + randf_range(-0.3, 0.3)   # ננעץ בקרקע
				Sfx.play("metal_ping", global_position, 2.0 if big else -4.0, 0.15, 2)
				if big:
					var cam := get_viewport().get_camera_2d()
					if cam != null and cam.has_method("shake"):
						cam.shake(8.0, 0.3)
		if _t > (9.0 if big else 4.0):
			modulate.a -= delta
			if modulate.a <= 0.0:
				queue_free()
		queue_redraw()

	func _draw() -> void:
		DrawBatch.begin(self)
		_draw_b()
		DrawBatch.end(self)

	func _draw_b() -> void:
		DrawBatch.set_transform(self, Vector2.ZERO, _rot, Vector2(k, k) * (1.8 if big else 1.0))
		for s: float in [-1.0, 1.0]:
			var dv := Vector2.from_angle(s * 0.08)
			DrawBatch.colored_polygon(self, PackedVector2Array([Vector2(0, s * 1.5), Vector2(4, -s * 1.2), Vector2(18, 0) + dv, Vector2(6, s * 2.8)]), Color("c8ccd2") if s > 0 else Color("7a7e84"))
		DrawBatch.arc(self, Vector2(-3, 0), 3.5, PI * 0.5, PI * 1.5, 8, Color("4a4a50"), 1.6)
		DrawBatch.line(self, Vector2(8, 0), Vector2(16, 0), Color(0.5, 0.05, 0.05, 0.8), 0.8)
		DrawBatch.set_transform(self, Vector2.ZERO, 0.0, Vector2.ONE)
