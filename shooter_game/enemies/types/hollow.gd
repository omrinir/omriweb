extends "res://enemies/zombie_type.gd"
# ============================================================
#  HOLLOW (שלב 63, "THE HEART") - עותק של הגיבור שגדל בכוורת: מעיל ארוך וקרוע, ברדס, ובמקום פנים - חלל שחור
#    עם שני סדקים ירוקים. עורקי ECHO זוהרים עוברים במעיל, הידיים פטרייה חיוורת, הרובה עטוף שורשים.
#  מה הוא למד, וממה: הכוורת נבנתה כדי ללמוד את SUBJECT ZERO - וכאן היא מגדלת אותו מחדש. "THEY FIGHT LIKE YOU NOW":
#    שומר על המרחק שאתה אוהב (PlayerMemory.avg_distance), יורה צרורות עם אזהרה (TELL - זוהר בקנה), מתגלגל כשיורים
#    עליו (ON_SHOT_CHANCE, בגלגול - פגיע רק לפיצוץ, כמוך), קופץ ויורה באוויר, רץ למחסה (group "cover"), מכת קת מקרוב.
#    יורה גבוה (AIM_HIGH - כפוף = מתחמק), ואחרי שראה אותך מתכופף - לפעמים נמוך (AIM_LOW).
#  לומד (main meta "ho_kills" >= LEARN_N): "THEY USE YOUR <נשק> NOW" - עוברים לנשק שאתה הכי יורה בו בשלב
#    (stage_63 fav_cat): BURSTS (auto) = צרור ארוך, SHOTGUN = מסתער ויורה מניפה מקרוב, AIM (precision) = לייזר ארוך
#    וירייה מהירה אחת מרחוק, BLASTS (explosive) = זורק רימון נבגים בקשת (SporeLob, עם סימון נחיתה).
#  מקומות: STATUE (פסל - stage_63 STATUES: נסדק ומתעורר כשמתקרבים / יורים), POD (שק רחם - HollowPod, מתפקע).
#  מת: השיעור עולה מהגופה - stage_63.hollow_dead() -> PILGRIM עם הנשק שהרג אותו.
#  בוס (chase_range > 600 - stage_63 שם אותו באולם המראות): SUBJECT ZERO. "IT IS YOU NOW": יורה מההתחלה בנשק שלך,
#    מתגלגל על רוב היריות (70%, B_ROLL_CD בין גלגולים), מחסה (HALL_COVER). ב-50%: "IT REMEMBERS YOUR LAST FIGHT" - מחליף בין הנשק הראשון והשני
#    שלך, מהר יותר, מעתיק את הגלגולים והקפיצות שלך, ומעיר את שני השקים של האולם.
#  לשנות: LEARN_N, MODES, ROLL_*, ON_SHOT_CHANCE, MAX_SHOOTERS, AIM_*, MELEE_*, WAKE_R, B_*.
# ============================================================

const ZScript := preload("res://zombie.gd")
const Decor := preload("res://effects/s63_decor.gd")

const SOUNDS := {
	"ho_tell": [["S", 600, 1400, 0.0, 0.4, 0.3, 0.0, 0.12, 1.0, 0.0], ["N", 0, 0, 0.0, 0.4, 0.3, 0.0, 0.08, 0.6, 0, 0.2]],
	"ho_crack": {"drive": 1.8, "layers": [["N", 0, 0, 0.0, 0.35, 0.0, 9.0, 0.8, 0.5, 0, 0.6], ["S", 900, 300, 0.0, 0.12, 0.0, 30.0, 0.35, 1.0, 0], ["N", 0, 0, 0.15, 0.4, 0.0, 6.0, 0.4, 0.2, 0, 0.5]]},
	"ho_breath": {"rev": 0.4, "layers": [["N", 0, 0, 0.0, 0.9, 0.3, 2.0, 0.35, 0.12, 0, 0.1], ["V", 110, 90, 0.0, 0.9, 0.3, 2.2, 0.2, 1.0, 0.02, 0, [500, 900, 4]]]},
	"ho_lob": [["N", 0, 0, 0.0, 0.25, 0.04, 9.0, 0.45, 0.3, 0], ["S", 300, 500, 0.0, 0.2, 0.0, 9.0, 0.2, 1.0, 0]],
	"ho_pop": {"rev": 0.3, "drive": 2.2, "layers": [["N", 0, 0, 0.0, 0.5, 0.0, 6.0, 1.0, 0.3, 0, 0.3], ["S", 140, 40, 0.0, 0.4, 0.0, 7.0, 0.8, 1.0, 0.05], ["S", 1200, 700, 0.0, 0.25, 0.0, 10.0, 0.15, 1.0, 0]]},
	"ho_learn": {"rev": 0.6, "layers": [["S", 660, 990, 0.0, 0.5, 0.02, 3.0, 0.18, 1.0, 0.02], ["S", 990, 1320, 0.12, 0.5, 0.02, 3.0, 0.14, 1.0, 0.02], ["V", 140, 140, 0.0, 0.8, 0.2, 2.0, 0.2, 1.0, 0.03, 0, [600, 1000, 5]]]},
	"zero_call": {"rev": 0.6, "drive": 1.6, "layers": [["V", 95, 80, 0.0, 1.3, 0.15, 1.2, 0.5, 1.0, 0.04, 0, [450, 850, 5]], ["V", 142, 120, 0.0, 1.3, 0.15, 1.2, 0.35, 1.0, 0.04, 0, [600, 1100, 4]], ["N", 0, 0, 0.0, 1.0, 0.1, 1.5, 0.3, 0.15, 0]]},
}

const LEARN_N := 4                 # כמה HOLLOW מתים עד שהם לומדים את הנשק שלך
# [זמן אזהרה, כדורים, קצב, מהירות, פיזור, חיים, מרחק מועדף]
const MODES := {
	"rifle": {"tell": 0.62, "n": 2, "rate": 0.24, "v": 760.0, "spread": 0.03, "life": 1.5, "pref": Vector2(300.0, 470.0)},
	"auto": {"tell": 0.5, "n": 4, "rate": 0.1, "v": 800.0, "spread": 0.06, "life": 1.4, "pref": Vector2(260.0, 420.0)},
	"shotgun": {"tell": 0.45, "n": 1, "pellets": 5, "rate": 0.5, "v": 700.0, "spread": 0.2, "life": 0.5, "pref": Vector2(130.0, 220.0)},
	"precision": {"tell": 0.85, "n": 1, "rate": 0.5, "v": 1250.0, "spread": 0.0, "life": 1.2, "pref": Vector2(470.0, 640.0)},
	"explosive": {"tell": 0.55, "n": 1, "rate": 0.5, "v": 0.0, "spread": 0.0, "life": 0.0, "pref": Vector2(300.0, 460.0)},
}
const MODE_OF := {"auto": "auto", "shotgun": "shotgun", "precision": "precision", "explosive": "explosive"}
const MAX_SHOOTERS := 2            # כמה HOLLOW (לא בוס) מכוונים / יורים בבת אחת
const AIM_HIGH := -44.0            # מעל שחקן כפוף (34)
const AIM_LOW := -16.0
const ROLL_V := 430.0
const ROLL_T := 0.42
const ROLL_CD := 2.2
const ON_SHOT_CHANCE := 0.35
const MELEE_R := 70.0
const MELEE_WIND := 0.3
const MELEE_DMG := 1
const WAKE_R := 240.0              # פסל מתעורר
const STATUE_MULT := 0.5           # פסל: אבן-פטרייה קשה
const POD_MULT := 0.7
const CD := Vector2(1.1, 2.0)
const JUMP_CHANCE := 0.22
const COVER_CHANCE := 0.3
const LOB_T := 0.9
const LOB_R := 74.0
const B_ROLL_CD := 1.1
const B_ROLL_CD2 := 0.8
const B_CD := Vector2(0.6, 1.1)
const B_CD2 := Vector2(0.35, 0.8)
const B_OPEN_MULT := 1.35          # בוס: טוען / קורא - פגיע יותר
const B_ARMOR := 0.9
const B_COPY_DELAY := 0.16

enum {STATUE, POD, WAKE, HUNT, AIM, FIRE, ROLL, COVER, MELEE, RECOVER, CALL}
var state := HUNT
var mode := "rifle"
var learned := false
var shots := 0                     # לבדיקות
var bursts := 0
var rolls := 0
var lobs := 0
var melees := 0
var copies := 0
var jumps := 0
var covers := 0
var phase2 := false
var _st := 0.0
var _cd := 1.0
var _roll_cd := 0.0
var hits := 0              # לבדיקות: כמה פגיעות הגיעו
var _left := 0
var _shot_t := 0.0
var _aim := 0.0                    # זווית (עולם)
var _aim_y := AIM_HIGH
var _jump_shot := false
var _hit := false
var _pod = null
var _hold := false
var _pose := 0                     # פסל: תנוחה
var _crack := 0.0
var _seed := 0.0
var _last_cat := "auto"
var _shape_k := -1
var _ducks := 0
var _cover_node: Node = null
var _cover_x := 0.0
var _cover_phase := 0
var _cover_t := 0.0
var _roll_dir := 1.0
var _copy_q := ""
var _copy_t := 0.0
var _was_roll := false
var _was_floor := true
var _ring := -1.0
var _engaged := false
var _z0 := 0
var _second := ""
var _glass := false              # הפגיעה שפוצצה את השק עברה דרך הקרום


func _boss() -> bool:
	return z != null and float(z.chase_range) > 600.0


func stats() -> Dictionary:
	if _boss():
		return {"name": "HOLLOW", "hp": 200, "walk": 70.0, "chase": 165.0, "damage": 1, "bite_delay": 1.0, "scale": 1.3, "width": 1.0,
			"duck": 0.0, "cover": 0.0, "skin": Color("9aa894"), "shirt": Color("1e1d1a"), "pants": Color("1a1a18"), "shoe": Color("101010"),
			"points": 3500, "boss": true, "boss_name": "SUBJECT ZERO", "ragdoll": false}
	return {"name": "HOLLOW", "hp": 46, "walk": 55.0, "chase": 150.0, "damage": 1, "bite_delay": 0.8, "scale": 1.0, "width": 0.95,
		"duck": 0.0, "cover": 0.0, "skin": Color("8e9c8a"), "shirt": Color("2c2b26"), "pants": Color("23221e"), "shoe": Color("141412"), "points": 480}


func brain_overrides() -> Dictionary:
	return {"aggression": 0.6}


func use_brain_movement() -> bool:
	return false


func can_bite() -> bool:
	return false


func can_groan() -> bool:
	return not dormant()


func death_sound() -> String:
	return "zdeath"


func _main() -> Node:
	return z.get_parent()


func _stage() -> Node:
	var m := _main()
	return m.get("_stage") if m != null else null


func dormant() -> bool:
	return state == STATUE or state == POD


func is_statue() -> bool:
	return state == STATUE


func setup() -> void:
	z.add_to_group("s63_hollows")
	_seed = float(z.get_instance_id() % 997) * 0.31
	_z0 = z.z_index
	_cd = randf_range(0.6, 1.4)
	var m := _main()
	if _boss():
		state = HUNT
		mode = _fav(0)
		learned = true
	elif m != null and int(m.get_meta("ho_kills", 0)) >= LEARN_N:
		_learn(false)
	_set_shape(0)


func _fav(rank: int) -> String:
	var st := _stage()
	if st != null and st.has_method("fav_cat"):
		return String(MODE_OF.get(st.fav_cat(rank), "auto"))
	return "auto"


func _resize(b: Vector2) -> void:
	var rs := z._shape.shape as RectangleShape2D
	rs.size = Vector2(b.x * z.wf * z.sc, b.y * z.sc)
	z._shape.position = Vector2(0.0, -b.y * 0.5 * z.sc)


func _set_shape(k: int) -> void:
	if k == _shape_k:
		return
	_shape_k = k
	match k:
		1:
			_resize(Vector2(30.0, 22.0))
		2:
			_resize(Vector2(30.0, 36.0))
		_:
			_resize(Vector2(26.0, 54.0))


# ============================================================
#  פסל / שק רחם (stage_63 -> extra_spawns)
# ============================================================
func as_statue(pose: int) -> void:
	state = STATUE
	_pose = clampi(pose, 0, 1)   # (פסל שמתעורר: עומד או כורע)
	z._dir = -1.0 if randf() < 0.6 else 1.0
	_set_shape(2 if _pose == 1 else 0)


func enter_pod(p: Node, hold := false) -> void:
	_pod = p
	_hold = hold
	state = POD
	z.z_index = 3
	z.velocity = Vector2.ZERO
	z._dir = -1.0 if randf() < 0.5 else 1.0
	_set_shape(2)


# HollowPod.burst() -> נופל החוצה
func release() -> void:
	if state != POD or z.dead:
		return
	_pod = null
	z.z_index = _z0
	_wake(0.55)
	z.velocity = Vector2(z._dir * 60.0, -200.0)


func _wake(t: float) -> void:
	state = WAKE
	_st = t
	z._alert_t = 4.0
	var pl := player() as Node2D
	if pl != null:
		z._dir = signf(pl.global_position.x - z.global_position.x + 0.01)
	Sfx.play("ho_breath", z.global_position + Vector2(0, -40), -4.0, 0.12, 2)


func _crack_statue() -> void:
	if state != STATUE:
		return
	_crack = 1.0
	_wake(0.7)
	Sfx.play("ho_crack", z.global_position + Vector2(0, -30), 0.0, 0.1, 2)
	if Art.on_screen(z, z.global_position):
		Particles.burst(_main(), z.global_position + Vector2(0, -30), "smoke", Vector2.UP, 6)
		Particles.burst(_main(), z.global_position + Vector2(0, -40), "snow", Vector2.UP, 6)


# ============================================================
#  למידה
# ============================================================
func _learn(announce: bool) -> void:
	if learned:
		return
	learned = true
	var m := _main()
	var md := ""
	if m != null and m.has_meta("ho_mode"):
		md = str(m.get_meta("ho_mode"))
	else:
		md = _fav(0)
		if m != null:
			m.set_meta("ho_mode", md)
	mode = md
	_ring = 0.0
	if announce and m != null and not m.has_meta("ho_learn_said"):
		m.set_meta("ho_learn_said", true)
		var cat := md
		z._popup("THEY USE YOUR " + String(Decor.CAT_NAME.get(cat, "GUN")) + " NOW", Decor.CAT_COL.get(cat, Decor.ECHO), 15, -120.0)
		Sfx.play("ho_learn", z.global_position + Vector2(0, -40), 0.0, 0.0, 1)
		var pl := player()
		if pl != null:
			var line := {"auto": "Bursts. They're spraying like I do.", "shotgun": "They took my shotgun... and they're closing in like I do.",
				"precision": "Laser sights. They aim like me now - keep moving!", "explosive": "They're lobbing spores. My trick. Watch the arc!"}
			Decor.U.say(pl, String(line.get(cat, "They learned my gun.")), Color("ffb0a0"))


func on_shot(from: Vector2, dir: Vector2) -> void:
	if z == null or z.dead or dormant() or state in [ROLL, MELEE, CALL, WAKE]:
		return
	if _roll_cd > 0.0 or not z.is_on_floor():
		return
	var chance := 0.7 if _boss() else ON_SHOT_CHANCE
	if randf() > chance:
		return
	var c: Vector2 = z.global_position + Vector2(0, -30.0 * z.sc)
	var rel := c - from
	var along := rel.dot(dir)
	if along < 0.0 or along > 1100.0 or absf(rel.cross(dir)) > 46.0 * z.sc:
		return
	var away := signf(rel.x) if absf(rel.x) > 1.0 else 1.0
	var pref := _pref()
	_start_roll(away if absf(rel.x) < pref.x else -away)


func _start_roll(dir: float) -> void:
	var bx: float = z.global_position.x + dir * ROLL_V * ROLL_T
	if _boss():
		var st := _stage()
		if st != null and (bx < float(st.HALL.x) + 60.0 or bx > float(st.HALL.y) - 60.0):
			dir = -dir
	state = ROLL
	_st = ROLL_T
	_roll_dir = dir
	z.velocity.x = dir * ROLL_V
	_roll_cd = (B_ROLL_CD2 if phase2 else B_ROLL_CD) if _boss() else ROLL_CD
	rolls += 1
	_set_shape(1)
	Sfx.play("roll", z.global_position, -2.0, 0.12, 3)


func _pref() -> Vector2:
	var p: Vector2 = MODES[mode].pref
	var d := clampf(PlayerMemory.avg_distance, 150.0, 650.0)   # המרחק שאתה אוהב (שלבים קודמים)
	var c := lerpf((p.x + p.y) * 0.5, d, 0.35)
	var half := (p.y - p.x) * 0.5
	return Vector2(maxf(c - half, 110.0), c + half)


func _shooters() -> int:
	var n := 0
	for o in z.get_tree().get_nodes_in_group("s63_hollows"):
		if o != z and not o.dead and o.type_mod != null and not o.type_mod._boss() and o.type_mod.state in [AIM, FIRE]:
			n += 1
	return n


# ============================================================
#  תנועה
# ============================================================
func physics(pl: Node, delta: float) -> bool:
	_st -= delta
	_cd -= delta
	_roll_cd -= delta
	if _ring >= 0.0:
		_ring += delta
		if _ring > 0.5:
			_ring = -1.0
	if z.dead:
		return false
	var has: bool = pl != null and not pl.dead
	var d: Vector2 = (pl.global_position - z.global_position) if has else Vector2.ZERO
	match state:
		STATUE:
			z.velocity = Vector2.ZERO
			if has and absf(d.x) < WAKE_R and absf(d.y) < 160.0:
				_crack_statue()
			return true
		POD:
			z.velocity = Vector2.ZERO
			if _pod == null or not is_instance_valid(_pod):
				release()
			return true
	if not learned and Engine.get_physics_frames() % 30 == 0:
		var m := _main()
		if m != null and int(m.get_meta("ho_kills", 0)) >= LEARN_N:
			_learn(true)
	if z.has_meta("s63_held"):   # RootSnare
		z.velocity.x = 0.0
	if _boss():
		_boss_tick(pl, has, d)
		if not _engaged:   # מחכה באולם
			_set_shape(0)
			z.velocity.x = 0.0
			if not z.is_on_floor():
				z.velocity.y += z.gravity * delta
			z.move_and_slide()
			return true
	if phase2 and has:
		_copy(pl, delta)
	var face: float = signf(d.x) if has and absf(d.x) > 6.0 else float(z._dir)
	match state:
		WAKE:
			_set_shape(0)
			z.velocity.x = move_toward(z.velocity.x, 0.0, 300.0 * delta)
			if _st <= 0.0:
				state = HUNT
				_cd = randf_range(0.3, 0.8)
		HUNT:
			_set_shape(0)
			_hunt(pl, has, d, face, delta)
		AIM:
			_set_shape(0)
			z._dir = face
			if z.is_on_floor():
				z.velocity.x = move_toward(z.velocity.x, 0.0, 900.0 * delta)
			if has:
				_aim = lerp_angle(_aim, _target_angle(pl), delta * (5.0 if mode == "precision" else 8.0))
			if _st <= 0.0 or (_jump_shot and z.velocity.y > -60.0):
				_jump_shot = false
				state = FIRE
				bursts += 1
				_left = int(MODES[mode].n) + (2 if _boss() and mode == "auto" else 0)
				_shot_t = 0.0
		FIRE:
			if z.is_on_floor():
				z.velocity.x = move_toward(z.velocity.x, 0.0, 900.0 * delta)
			_shot_t -= delta
			if _shot_t <= 0.0 and _left > 0:
				_shot_t = float(MODES[mode].rate)
				_left -= 1
				if has:
					_aim = lerp_angle(_aim, _target_angle(pl), 0.5)
				_fire(pl)
			if _left <= 0 and _shot_t <= 0.0:
				if has and _aim_y == AIM_HIGH and pl._crouching:
					_ducks += 1
				if _cover_node != null and _cover_phase == 2:
					state = COVER
					_cover_phase = 1
					_st = randf_range(0.6, 1.0)
				else:
					state = RECOVER
					_st = 0.35 if mode != "precision" else 0.5
		ROLL:
			_set_shape(1)
			z.velocity.x = move_toward(z.velocity.x, _roll_dir * ROLL_V * 0.75, 600.0 * delta)
			if _st <= 0.0:
				_set_shape(0)
				z._dir = face
				if has and _can_shoot():   # קם מהגלגול ויורה (כמוך)
					_start_aim(pl, 0.7)
				else:
					state = RECOVER
					_st = 0.2
		COVER:
			_cover_tick(pl, has, d, face, delta)
		MELEE:
			z.velocity.x = move_toward(z.velocity.x, 0.0, 1200.0 * delta)
			if _st <= 0.0 and not _hit:
				_hit = true
				var me := Rect2(z.global_position + Vector2(z._dir * 36.0 * z.sc - 36.0 * z.sc, -58.0 * z.sc), Vector2(72.0 * z.sc, 58.0 * z.sc))
				if has and me.intersects(pl.body_rect()):
					pl.hurt(MELEE_DMG, Vector2(z._dir * 1.6, -0.7))
				Sfx.play("melee", z.global_position + Vector2(z._dir * 26.0, -36), -2.0, 0.1, 2)
			if _st <= -0.3:
				state = HUNT
				_cd = maxf(_cd, 0.3)
		RECOVER:
			z.velocity.x = move_toward(z.velocity.x, 0.0, 900.0 * delta)
			if _st <= 0.0:
				state = HUNT
				var c := B_CD2 if phase2 else B_CD
				_cd = randf_range(c.x, c.y) if _boss() else randf_range(CD.x, CD.y)
		CALL:
			z.velocity.x = move_toward(z.velocity.x, 0.0, 900.0 * delta)
			if _st <= 0.0:
				state = HUNT
				_cd = 0.3
	if _boss():   # לא יוצא מהאולם
		var st := _stage()
		if st != null:
			var hx: Vector2 = st.HALL
			if (z.global_position.x < hx.x + 50.0 and z.velocity.x < 0.0) or (z.global_position.x > hx.y - 50.0 and z.velocity.x > 0.0):
				z.velocity.x = 0.0
	if not z.is_on_floor():
		z.velocity.y += z.gravity * delta
	z.move_and_slide()
	return true


func _hunt(pl: Node, has: bool, d: Vector2, face: float, delta: float) -> void:
	if not has:
		z.velocity.x = move_toward(z.velocity.x, 0.0, 500.0 * delta)
		return
	z._dir = face
	var pref := _pref()
	var want := 0.0
	var far: bool = absf(d.x) > 900.0 and z._alert_t <= 0.0
	if absf(d.x) > pref.y:
		want = face * (z.walk_speed if far else z.chase_speed)
	elif absf(d.x) < pref.x:
		want = -face * z.walk_speed * 1.5   # נסוג אחורה - שומר על המרחק שלך
	z.velocity.x = move_toward(z.velocity.x, want, 700.0 * delta)
	if absf(z.velocity.x) > 10.0:
		z._walk_phase += delta * 10.0 * signf(z.velocity.x) * face
	if z.is_on_floor() and z.is_on_wall() and absf(z.velocity.x) < 20.0 and want != 0.0:
		z.velocity.y = -470.0
	if not z.is_on_floor():
		return
	if absf(d.x) < MELEE_R * z.sc and absf(d.y) < 70.0:
		state = MELEE
		_st = MELEE_WIND
		_hit = false
		melees += 1
		return
	if _cd > 0.0 or absf(d.x) > 860.0 or not _can_shoot():
		return
	if absf(d.y) > 260.0 and mode != "explosive":
		return
	if not _boss() and randf() < COVER_CHANCE and float(z.hp) < float(z.max_hp) and _find_cover(pl):
		state = COVER
		_cover_phase = 0
		_cover_t = 0.0
		covers += 1
		return
	if _boss() and randf() < 0.35 and _find_cover(pl):
		state = COVER
		_cover_phase = 0
		_cover_t = 0.0
		covers += 1
		return
	# קפיצה ויריה באוויר (כמוך) - או כשאתה על מדף מעליו
	if mode != "explosive" and (randf() < JUMP_CHANCE or d.y < -90.0):
		z.velocity.y = -540.0
		jumps += 1
		_start_aim(pl, 0.0)
		_jump_shot = true
		_st = 0.5
		return
	_start_aim(pl, 1.0)


func _can_shoot() -> bool:
	return _boss() or _shooters() < MAX_SHOOTERS


func _start_aim(pl: Node, k: float) -> void:
	state = AIM
	_st = float(MODES[mode].tell) * (0.8 if _boss() else 1.0) * (0.75 if phase2 else 1.0) * maxf(k, 0.35)
	_aim_y = AIM_HIGH
	var low_ok: bool = _ducks >= 2 or PlayerMemory.crouch > 0.3
	if low_ok and randf() < (0.5 if _boss() else 0.3):
		_aim_y = AIM_LOW
	_aim = _target_angle(pl)
	Sfx.play("ho_tell", z.global_position + Vector2(0, -40), -6.0, 0.05, 2, 1.3 if mode == "precision" else 1.0)


func _target_angle(pl: Node) -> float:
	var tgt: Vector2 = pl.global_position + Vector2(0.0, _aim_y)
	if mode == "precision" or _boss():   # מוביל קצת (כמוך)
		tgt.x += float(pl.velocity.x) * 0.12
	return (tgt - _muzzle_world()).angle()


func _muzzle_world() -> Vector2:
	var lp := Vector2(4.0, -38.0)
	if state == COVER and _cover_phase == 1:
		lp.y = -26.0
	var la := Vector2(cos(_aim) * z._dir, sin(_aim)) if state in [AIM, FIRE] else Vector2(1.0, 0.05)
	lp += la.normalized() * 22.0
	return z.global_position + Vector2(lp.x * z._dir * z.wf * z.sc, lp.y * z.sc)


func _fire(pl: Node) -> void:
	var mz := _muzzle_world()
	var md: Dictionary = MODES[mode]
	if mode == "explosive":
		_lob(pl, mz)
		return
	var n := int(md.get("pellets", 1))
	for i in n:
		var b = ZScript.EnemyShot.new()
		_main().add_child(b)
		b.global_position = mz
		var a := _aim + (randf_range(-1.0, 1.0) * float(md.spread) if n == 1 else lerpf(-float(md.spread), float(md.spread), float(i) / float(n - 1)))
		b.velocity = Vector2.from_angle(a) * float(md.v)
		b.life = float(md.life)
		shots += 1
	var snd := "rifle"
	match mode:
		"shotgun":
			snd = "shotgun"
		"precision":
			snd = "sniper"
	Sfx.play(snd, mz, -7.0, 0.1, 3, 0.8)
	if Art.on_screen(z, mz):
		Particles.burst(_main(), mz, "spark", Vector2.from_angle(_aim), 2)


func _lob(pl: Node, mz: Vector2) -> void:
	lobs += 1
	var g := SporeLob.new()
	_main().add_child(g)
	g.global_position = mz
	var tgt: Vector2 = pl.global_position + Vector2(float(pl.velocity.x) * 0.35, 0.0)
	g.ground = pl.global_position.y if pl.is_on_floor() else z.global_position.y
	g.land_x = tgt.x
	var tt := LOB_T
	g.vel = Vector2((tgt.x - mz.x) / tt, (g.ground - 10.0 - mz.y - 0.5 * SporeLob.G * tt * tt) / tt)
	Sfx.play("ho_lob", mz, -2.0, 0.1, 2)


# ---- מחסה ----
func _find_cover(pl: Node) -> bool:
	_cover_node = null
	var best := 380.0
	var px: float = pl.global_position.x
	for c in z.get_tree().get_nodes_in_group("cover"):
		if not c.has_method("cover_rect"):
			continue
		var r: Rect2 = c.cover_rect()
		var cx := r.get_center().x
		if absf(cx - z.global_position.x) > 420.0:
			continue
		var side := -signf(px - cx)
		var spot := cx + side * (r.size.x * 0.5 + 24.0)
		if absf(px - cx) < r.size.x * 0.5 + 140.0:
			continue
		if _boss():
			var st := _stage()
			if st != null and (spot < float(st.HALL.x) + 60.0 or spot > float(st.HALL.y) - 60.0):
				continue
		var dd: float = absf(spot - z.global_position.x)
		if dd < best:
			best = dd
			_cover_node = c
			_cover_x = spot
	return _cover_node != null


func _cover_tick(pl: Node, has: bool, d: Vector2, face: float, delta: float) -> void:
	_cover_t += delta
	if not has or _cover_node == null or not is_instance_valid(_cover_node):
		_leave_cover()
		return
	var r: Rect2 = _cover_node.cover_rect()
	var cx := r.get_center().x
	var flanked: bool = signf(pl.global_position.x - cx) == signf(z.global_position.x - cx)
	if _cover_t > 5.0 or (flanked and _cover_phase > 0) or absf(d.x) < 120.0:
		_leave_cover()
		return
	match _cover_phase:
		0:
			_set_shape(0)
			var dx: float = _cover_x - z.global_position.x
			z._dir = signf(dx) if absf(dx) > 6.0 else face
			z.velocity.x = move_toward(z.velocity.x, signf(dx) * z.chase_speed * 1.15 if absf(dx) > 8.0 else 0.0, 1100.0 * delta)
			z._walk_phase += delta * 12.0
			if absf(dx) <= 10.0:
				_cover_phase = 1
				_st = randf_range(0.5, 0.9)
				z.velocity.x = 0.0
			elif _cover_t > 2.5:
				_leave_cover()
		1:   # מתחבא
			_set_shape(2)
			z._dir = face
			z.velocity.x = move_toward(z.velocity.x, 0.0, 900.0 * delta)
			if _st <= 0.0 and _can_shoot():
				_cover_phase = 2
				_set_shape(0)
				_start_aim(pl, 0.8)
				_cover_phase = 2
		2:
			_leave_cover()


func _leave_cover() -> void:
	_cover_node = null
	_cover_phase = 0
	state = HUNT
	_cd = 0.4
	_set_shape(0)


# ---- בוס: SUBJECT ZERO ----
func _boss_tick(pl: Node, has: bool, d: Vector2) -> void:
	if not _engaged and has and absf(d.x) < 600.0 and absf(d.y) < 200.0:
		_engaged = true
		Decor.U.notify("IT IS YOU NOW", Color("ff8a7a"))   # (על המסך, מתחת לפס הבוס - הוא עומד בקצה המסך)
		Sfx.play("zero_call", z.global_position, 0.0, 0.0, 1)
		Decor.U.say(pl, "Subject Zero. They grew ME. With my gun.", Color("ffb0a0"))
	if not _engaged:
		z.velocity.x = 0.0
		if state == HUNT:
			_cd = 0.6
		return
	if not phase2 and float(z.hp) < float(z.max_hp) * 0.5 and state in [HUNT, RECOVER]:
		phase2 = true
		state = CALL
		_st = 1.1
		z.chase_speed *= 1.15
		_ring = 0.0
		var second := _fav(1)
		Decor.U.notify("IT REMEMBERS YOUR LAST FIGHT", Decor.ECHO)
		Sfx.play("zero_call", z.global_position, 3.0, 0.0, 1, 0.85)
		var cam: Camera2D = z.get_viewport().get_camera_2d()
		if cam != null and cam.has_method("shake"):
			cam.shake(8.0, 0.6)
		var st := _stage()
		if st != null and st.has_method("wake_hall"):
			st.wake_hall()
		_second = second
	if phase2 and state == RECOVER and _st <= 0.0:   # מחליף נשקים: הראשון והשני שלך
		var a := _fav(0)
		var b := _second if _second != "" else a
		mode = b if mode == a else a


# (שלב 2) מעתיק את הגלגולים והקפיצות שלך
func _copy(pl: Node, delta: float) -> void:
	var rolling: bool = pl._roll_t > 0.0
	var fl: bool = pl.is_on_floor()
	if _copy_q == "":
		if rolling and not _was_roll:
			_copy_q = "roll"
			_copy_t = B_COPY_DELAY
		elif _was_floor and not fl and float(pl.velocity.y) < -150.0:
			_copy_q = "jump"
			_copy_t = B_COPY_DELAY
	_was_roll = rolling
	_was_floor = fl
	if _copy_q == "":
		return
	_copy_t -= delta
	if _copy_t > 0.0:
		return
	if state in [HUNT, RECOVER] and z.is_on_floor():
		copies += 1
		_ring = 0.0
		if _copy_q == "roll":
			_start_roll(float(pl._roll_dir))
		else:
			z.velocity.y = -560.0
			_start_aim(pl, 0.0)
			_jump_shot = true
			_st = 0.5
	if _copy_t < -0.6 or state == ROLL or state == AIM:
		_copy_q = ""


# ============================================================
#  נזק ומוות
# ============================================================
func on_damage(_amount: int, _hit_pos: Vector2, _dir: Vector2, src: Dictionary) -> bool:
	if z.dead:
		return true
	hits += 1
	var blast := not (str(src.get("source", "bullet")) in ["bullet", "melee", "laser", "taser"])
	_last_cat = Decor.cat_of_src(src)
	if state == ROLL and not blast:   # בגלגול: בלתי פגיע כמוך
		return false
	match state:
		STATUE:
			_crack_statue()
		POD:
			_glass = true
			if _pod != null and is_instance_valid(_pod):
				_pod.burst()
	if _boss() and not _engaged:
		_engaged = true
	return true


func damage_mult(_zone: String, _src: Dictionary) -> float:
	if _boss():
		match state:
			RECOVER, CALL:
				return B_OPEN_MULT
			COVER:
				return 0.6 if _cover_phase == 1 else B_ARMOR
		return B_ARMOR
	if _crack > 0.0 and state == WAKE and _st > 0.5:
		return STATUE_MULT
	if _glass:
		_glass = false
		return POD_MULT
	if state == COVER and _cover_phase == 1:
		return 0.6
	return 1.0


func on_death() -> void:
	z.z_index = _z0
	if _pod != null and is_instance_valid(_pod):
		_pod.burst()
	var st := _stage()
	if st != null and st.has_method("hollow_dead"):
		st.hollow_dead(z.global_position, _last_cat, _boss())
	if Art.on_screen(z, z.global_position):
		Particles.burst(_main(), z.global_position + Vector2(0, -40.0 * z.sc), "mist", Vector2.UP, 3)
	if _boss():
		var cam: Camera2D = z.get_viewport().get_camera_2d()
		if cam != null and cam.has_method("shake"):
			cam.shake(12.0, 0.6)
		Sfx.play("zero_call", z.global_position, 0.0, 0.0, 1, 0.6)
		Particles.burst(_main(), z.global_position + Vector2(0, -60), "hit", Vector2.UP, int(22.0 * Quality.gore()))


func wants_redraw() -> bool:
	if z.dead:
		return true
	if state == STATUE:
		return z._flash > 0.0 or Engine.get_physics_frames() % 20 == 0
	if state == POD:
		return Engine.get_physics_frames() % 4 == 0
	return true


# ============================================================
#  ציור: (0,0) = כפות הרגליים, פונה ימינה. מעיל ארוך עם עורקים זוהרים, ברדס, חלל במקום פנים, רובה עטוף שורשים.
#  פסל: אפור-אבן, בלי זוהר, סדקים. בשק: מכורבל, כהה. בוס: גדול יותר, מעיל שחור, "0" זוהר על החזה, שורשים מהגב.
# ============================================================
func draw() -> bool:
	begin_draw(state != POD)
	var tt: float = z._time
	var crouch := 0.0
	var roll := false
	var rot := 0.0
	if not z.dead:
		match state:
			ROLL:
				roll = true
				rot = (1.0 - clampf(_st / ROLL_T, 0.0, 1.0)) * TAU
			STATUE:
				crouch = 1.0 if _pose == 1 else 0.0
			POD:
				crouch = 1.0
			COVER:
				crouch = 0.85 if _cover_phase == 1 else 0.0
			WAKE:
				crouch = clampf(_st / 0.6, 0.0, 1.0) * (1.0 if _crack > 0.0 and _pose == 1 else 0.6)
				rot = sin(tt * 14.0) * 0.03
			MELEE:
				rot = -0.18 if _st > 0.0 else 0.2
			CALL:
				rot = -0.12
	if rot != 0.0:
		var s := Vector2(z._dir * z.wf * z.sc, z.sc)
		var piv := Vector2(0.0, -14.0)
		DrawBatch.set_transform_matrix(z, Transform2D(0.0, s, 0.0, Vector2.ZERO) * Transform2D(rot, piv) * Transform2D(0.0, -piv))
	_draw_body(tt, crouch, roll)
	end_draw()
	if z.dead:
		return true
	if _ring >= 0.0:   # טבעת "למד"
		var k := _ring / 0.5
		DrawBatch.arc(z, Vector2(0.0, -30.0 * z.sc), (16.0 + 30.0 * k) * z.sc, 0.0, TAU, 24, Color(0.75, 1.0, 0.55, 0.8 * (1.0 - k)), 2.5)
	if state == AIM:   # אזהרה: זוהר בקנה (+ לייזר ב-AIM)
		var mz: Vector2 = _muzzle_world() - z.global_position
		var tell: float = 1.0 - clampf(_st / maxf(float(MODES[mode].tell), 0.1), 0.0, 1.0)
		var cc: Color = Decor.CAT_COL.get(mode, Color(1.0, 0.4, 0.3)) if learned else Color(1.0, 0.35, 0.25)
		if _aim_y == AIM_LOW:
			cc = Color(1.0, 0.8, 0.2)
		DrawBatch.circle(z, mz, 2.0 + 4.0 * tell, Color(cc, 0.35 + 0.5 * tell))
		DrawBatch.circle(z, mz, 1.5 + 1.5 * tell, Color(1, 1, 1, 0.5 + 0.5 * tell))
		if mode == "precision" or _boss():
			var dir := Vector2.from_angle(_aim)
			var blink := 0.5 + 0.5 * absf(sin(tt * 24.0))
			DrawBatch.line(z, mz, mz + dir * 640.0, Color(cc, (0.25 + 0.3 * blink) * (0.4 + 0.6 * tell)), 1.4)
		elif mode == "explosive":   # סימון נחיתה (קשת)
			var pl := player() as Node2D
			if pl != null:
				var lx: float = pl.global_position.x - z.global_position.x
				var gy: float = pl.global_position.y - z.global_position.y
				DrawBatch.arc(z, Vector2(lx, gy - 2.0), LOB_R * 0.5 * (0.6 + 0.4 * tell), PI, TAU, 12, Color(1.0, 0.3, 0.3, 0.3 + 0.4 * tell), 2.0)
	return true


func _draw_body(tt: float, crouch: float, roll: bool) -> void:
	var boss := _boss()
	var stone := 1.0 if state == STATUE else (clampf(_st / 0.7, 0.0, 1.0) if state == WAKE and _crack > 0.0 else 0.0)
	var pod_k := 1.0 if state == POD else 0.0
	var coat := col(z.shirt.lerp(Color("6a6660"), stone).lerp(Color("3a2226"), pod_k * 0.4))
	var coat_d := Art.shade(coat, -0.35)
	var pants := col(z.pants.lerp(Color("5a5650"), stone))
	var skin := col(z.skin.lerp(Color("7a7670"), stone))
	var glow_on := stone < 0.5 and pod_k < 1.0
	var vein: Color = Decor.ECHO if not learned or boss else Decor.CAT_COL.get(mode, Decor.ECHO)
	vein = Color(vein, (0.55 + 0.35 * sin(tt * 4.0 + _seed)) if glow_on else 0.0)
	if roll:   # כדור: המעיל עוטף
		Art.oval(z, Vector2(0, -14.0), 14.0, 12.0, coat, 0.0)
		Art.oval(z, Vector2(6.0, -20.0), 6.0, 6.0, coat_d, 0.0, Art.NONE)
		DrawBatch.arc(z, Vector2(0, -14.0), 10.0, -1.0, 1.6, 8, vein, 1.4)
		return
	var cr := crouch
	var hip := Vector2(0.0, -24.0 + cr * 9.0)
	var ft := feet(5.5, 2.5)
	var f1: Vector2 = ft[0]
	var f2: Vector2 = ft[1]
	if cr > 0.3:
		f1 = Vector2(9.0, 0.0)
		f2 = Vector2(-7.0, 0.0)
	# רגליים
	var k1 := Art.joint(hip + Vector2(2, 0), f1, 13.0, 13.0, 1.0)
	var k2 := Art.joint(hip + Vector2(-2, 0), f2, 13.0, 13.0, 1.0)
	Art.limb(z, PackedVector2Array([hip + Vector2(-2, 0), k2, f2 + Vector2(0, -2)]), 4.6, Art.shade(pants, -0.2))
	Art.limb(z, PackedVector2Array([hip + Vector2(2, 0), k1, f1 + Vector2(0, -2)]), 4.6, pants)
	Art.oval(z, f2 + Vector2(1.5, -1.6), 4.0, 2.0, col(z.shoe), 0.0)
	Art.oval(z, f1 + Vector2(1.5, -1.6), 4.0, 2.0, col(z.shoe), 0.0)
	# מעיל ארוך (מתנופף עם ההליכה)
	var sh := Vector2(1.0, -44.0 + cr * 12.0)
	var flap := sin(z._walk_phase) * 2.5 if z.is_on_floor() else 4.0
	var hem := hip.y + 13.0 - cr * 4.0
	var coat_pts := PackedVector2Array([sh + Vector2(-7, 0), sh + Vector2(7, -1), hip + Vector2(8, 0), Vector2(10.0 + flap * 0.4, hem),
		Vector2(1.0, hem + 2.0), Vector2(-9.0 - flap, hem - 1.0), hip + Vector2(-8, 0)])
	Art.fill_shaded(z, coat_pts, coat, 0.12, 0.3)
	# קרעים בשולי המעיל
	DrawBatch.colored_polygon(z, PackedVector2Array([Vector2(-4.0, hem), Vector2(-2.0, hem - 5.0), Vector2(0.0, hem + 1.0)]), coat_d)
	# עורקים זוהרים במעיל
	if vein.a > 0.01:
		DrawBatch.polyline(z, PackedVector2Array([sh + Vector2(-3, 2), hip + Vector2(-2, -6), hip + Vector2(-5, 4), Vector2(-6.0, hem - 3.0)]), vein, 1.2)
		DrawBatch.polyline(z, PackedVector2Array([sh + Vector2(4, 3), hip + Vector2(3, -3), Vector2(6.0, hem - 2.0)]), Color(vein, vein.a * 0.7), 1.0)
	elif stone > 0.5:   # סדקים של פסל
		DrawBatch.polyline(z, PackedVector2Array([sh + Vector2(-2, 3), hip + Vector2(1, -5), hip + Vector2(-3, 5)]), Color(0.2, 0.18, 0.16, 0.8), 1.0)
	# חגורה / רצועת הרובה
	DrawBatch.line(z, sh + Vector2(-6, 1), hip + Vector2(7, -2), col(Color("3a3226")), 1.6)
	if boss:   # "0" זוהר על החזה + שורשים יוצאים מהגב
		DrawBatch.arc(z, sh + Vector2(2.0, 9.0), 2.6, 0.0, TAU, 10, Color(Decor.ECHO, 0.85), 1.1)
		for q in 3:
			var a := sh + Vector2(-6.0, 4.0 + float(q) * 5.0)
			DrawBatch.polyline(z, PackedVector2Array([a, a + Vector2(-7.0, -4.0 + sin(tt * 2.0 + float(q)) * 2.0), a + Vector2(-13.0, -10.0 + float(q) * 3.0)]), col(Color("2a1a14")), 1.8)
	# הנשק והידיים
	var aim_l := 0.0
	if state in [AIM, FIRE] and not z.dead:
		var wa := Vector2(cos(_aim) * z._dir, sin(_aim))
		aim_l = clampf(wa.angle(), -1.2, 1.2)
	elif state == MELEE:
		aim_l = -0.9 if _st > 0.0 else 0.5
	elif cr > 0.5:
		aim_l = 0.1
	var piv := sh + Vector2(3.0, 6.0)
	var dirv := Vector2.from_angle(aim_l)
	var nrm := dirv.orthogonal()
	var gun_len := 24.0
	var gun_w := 2.4
	match mode:
		"shotgun":
			gun_len = 20.0
			gun_w = 3.2
		"precision":
			gun_len = 30.0
			gun_w = 2.0
		"explosive":
			gun_len = 18.0
			gun_w = 4.4
	var stock := piv - dirv * 6.0
	var tip := piv + dirv * gun_len
	var gcol := col(Color("1e1c18").lerp(Color("5a5650"), stone))
	Art.limb(z, PackedVector2Array([sh + Vector2(-3, 2), piv + dirv * 2.0 + nrm * 2.0]), 3.6, coat_d)   # זרוע אחורית
	DrawBatch.colored_polygon(z, PackedVector2Array([stock + nrm * gun_w, tip + nrm * gun_w * 0.6, tip - nrm * gun_w * 0.6, stock - nrm * gun_w]), gcol)
	DrawBatch.colored_polygon(z, PackedVector2Array([stock + nrm * gun_w, stock - nrm * (gun_w + 3.0), stock - dirv * 5.0 - nrm * (gun_w + 2.0), stock - dirv * 4.0 + nrm * gun_w]), gcol)
	if mode == "precision":   # כוונת
		DrawBatch.colored_polygon(z, PackedVector2Array([piv + dirv * 6.0 + nrm * 3.0, piv + dirv * 14.0 + nrm * 3.0, piv + dirv * 14.0 + nrm * 5.5, piv + dirv * 6.0 + nrm * 5.5]), gcol)
	# שורשים שעוטפים את הרובה
	DrawBatch.line(z, piv + dirv * 4.0 - nrm * 2.5, piv + dirv * 10.0 + nrm * 2.5, col(Color("3a2416")), 1.2)
	DrawBatch.line(z, piv + dirv * 12.0 - nrm * 2.0, piv + dirv * 17.0 + nrm * 2.0, col(Color("3a2416")), 1.0)
	if vein.a > 0.01:
		DrawBatch.circle(z, piv + dirv * 8.0, 1.3, vein)
	Art.limb(z, PackedVector2Array([sh + Vector2(3, 2), piv + dirv * 9.0 - nrm * 1.0]), 3.8, coat)   # זרוע קדמית
	Art.oval(z, piv + dirv * 9.0 - nrm * 1.0, 2.2, 2.0, skin, 0.0, Art.NONE)
	if z._flash > 0.0 and state == FIRE:
		Art.glow(z, tip, 6.0, Color(1.0, 0.85, 0.5, 0.8))
	# ראש: ברדס, חלל שחור, שני סדקים ירוקים
	var head := sh + Vector2(1.5, -7.0)
	Art.oval(z, head + Vector2(-0.5, 0.0), 6.6, 7.4, coat, 0.0)
	DrawBatch.colored_polygon(z, PackedVector2Array([head + Vector2(-6, -3), head + Vector2(-2, -9), head + Vector2(-10, -1)]), coat)   # קצה הברדס
	Art.oval(z, head + Vector2(2.6, 1.0), 3.6, 5.0, col(Color("060505")), 0.0, Art.NONE)
	DrawBatch.line(z, head + Vector2(1.0, 6.0), head + Vector2(4.6, 5.0), skin, 1.2)   # סנטר חיוור
	if glow_on and not z.dead:
		var ec := Color(0.7, 1.0, 0.5, 0.95)
		DrawBatch.line(z, head + Vector2(1.6, -0.6), head + Vector2(3.4, -0.2), ec, 1.1)
		DrawBatch.line(z, head + Vector2(4.2, 0.0), head + Vector2(5.6, 0.4), ec, 1.0)
		Art.glow(z, head + Vector2(3.6, 0.0), 5.0, Color(0.6, 1.0, 0.45, 0.35))
	elif stone > 0.5:
		DrawBatch.line(z, head + Vector2(-3, -5), head + Vector2(1, 2), Color(0.25, 0.22, 0.2, 0.8), 0.8)


# ============================================================
#  רימון נבגים (BLASTS): עף בקשת, מתפוצץ על הרצפה. זז ב-_process (לא ב-MOVERS)
# ============================================================
class SporeLob extends Node2D:
	const G := 900.0
	var vel := Vector2.ZERO
	var ground := 630.0
	var land_x := 0.0
	var _t := 0.0
	var _done := false

	func _ready() -> void:
		z_index = 9

	func _process(delta: float) -> void:
		if _done:
			return
		_t += delta
		vel.y += G * delta
		global_position += vel * delta
		var pl := get_tree().get_first_node_in_group("player")
		var hit_pl: bool = pl != null and not pl.dead and pl.body_rect().has_point(global_position)
		if hit_pl or (vel.y > 0.0 and global_position.y >= ground - 6.0) or _t > 3.0:
			_pop(pl)
			return
		queue_redraw()

	func _pop(pl: Node) -> void:
		_done = true
		var c := Vector2(global_position.x, minf(global_position.y, ground - 6.0))
		if pl != null and not pl.dead:
			var pc: Vector2 = pl.global_position + Vector2(0, -26)
			if pc.distance_to(c) < 74.0 and float(pl._roll_t) <= 0.0:
				pl.hurt(1, Vector2(signf(pc.x - c.x + 0.01), -0.6))
		Sfx.play("ho_pop", c, -2.0, 0.1, 2)
		var par := get_parent()
		Particles.burst(par, c, "mist", Vector2.UP, 6)
		Particles.burst(par, c, "smoke", Vector2.UP, 4)
		var cam: Camera2D = get_viewport().get_camera_2d()
		if cam != null and cam.has_method("shake") and Art.on_screen(self, c, 0.0):
			cam.shake(4.0, 0.2)
		queue_free()

	func _draw() -> void:
		DrawBatch.begin(self)
		_draw_b()
		DrawBatch.end(self)

	func _draw_b() -> void:
		var p := 0.5 + 0.5 * sin(_t * 30.0)
		DrawBatch.circle(self, Vector2.ZERO, 7.0, Color("3a5a2a"))
		DrawBatch.circle(self, Vector2.ZERO, 4.0 + p * 1.5, Color(0.75, 1.0, 0.55, 0.8))
		DrawBatch.circle(self, Vector2(-vel.normalized() * 8.0), 3.0, Color(0.75, 1.0, 0.55, 0.3))
		# סימון נחיתה על הרצפה
		var gl := Vector2(land_x - global_position.x, ground - global_position.y - 2.0)
		DrawBatch.arc(self, gl, 30.0, PI, TAU, 12, Color(1.0, 0.35, 0.3, 0.35 + 0.3 * p), 2.0)
