extends "res://enemies/zombie_type.gd"
# ============================================================
#  QUISLING (שלב 52, "RAIL YARD") - "המשת"פ". בהשראת ה-quislings של "World War Z" (מקס ברוקס) ושל ה-Whisperers
#  מ-"The Walking Dead": בן אדם חי, עטוף בגלימה ובמסכה תפורות מעור של מתים, שהולך בתוך קבוצות זומבים ומתחזה לאחד מהם.
#  עובד בשביל THE ARCHITECT (הבוס של שלב 54): מוביל את המתים דרומה, אל הרכבות.
#  סימנים שהוא חי (הקאונטר - להסתכל טוב): אדי נשימה מהפה, הוא ממצמץ, ועיניים לבנות של בן אדם בתוך חורי המסכה.
#  כשהוא מוסתר (HIDDEN) הוא "לוחש" לקבוצה שלו (WHISPER_T): הם משתתקים (בלי אנקות), צועדים באותו קצב בדיוק,
#    וחצי מהם מאגפים אותך (FLANK) - קבוצה שקטה ומסונכרנת = יש בה משת"פ.
#  נחשף (REVEAL) כשיורים בו, כשמתקרבים אליו (EXPOSE_R), או כשכל הקבוצה שלו מתה. אז: מוריד את המסכה (mask_off),
#    יורה באקדח (AIM עם קו כוונה - להתחמק), זורק בקבוק תבערה (THROW), ובורח (RUN) לקבוצה הבאה ומתחפש שוב (REHIDE).
#  דם אדום וצרחה, מעט חיים (hp 22). הורגים אותו -> הקבוצה שלו מבולבלת (CONFUSE_T, "LEADERLESS").
#  "THEY LEARN" (main meta "quisling_exposed" >= LEARN_EXPOSED): המשת"פים הבאים מתחבאים עמוק יותר - בקבוצות גדולות
#    יותר, בצד הרחוק של הקבוצה, נחשפים רק מקרוב יותר (LEARN_EXPOSE_R), ומפסיקים לנשום כשאתה מסתכל עליהם.
#  שחקן בסצנת סיפור (story_trigger / story_scene, כמו stranger.gd): talking, tilt, smile, look_back, t,
#    ו-mask_off (0 = מסכה על הפנים, 1 = מסכה מורדת: פנים של בן אדם חי, מפוחד ומזיע).
#  צלילים: "qs_whisper", "qs_gasp", "qs_scream", "pistol", "whoosh".
#  לשנות: HERD_R, EXPOSE_R, LEARN_EXPOSE_R, WHISPER_T, AIM_T, SHOT_V, SHOT_DMG, THROW_R, MOLOTOV_CD, RUN_V, SEEK_R,
#    CONFUSE_T, LEARN_EXPOSED, SHOTS_BEFORE_RUN.
# ============================================================

const SOUNDS := {
	"qs_whisper": [["N", 0, 0, 0.0, 0.45, 0.08, 3.0, 0.3, 0.25, 0, 0.55], ["N", 0, 0, 0.22, 0.4, 0.06, 4.0, 0.22, 0.3, 0, 0.6],
		["N", 0, 0, 0.5, 0.3, 0.05, 5.0, 0.18, 0.28, 0, 0.6]],
	"qs_gasp": [["N", 0, 0, 0.0, 0.35, 0.03, 5.0, 0.5, 0.45, 0, 0.3], ["V", 300, 380, 0.0, 0.25, 0.02, 6.0, 0.45, 1.0, 0.02, 0, [700, 1250, 0]]],
	"qs_scream": {"drive": 1.6, "layers": [["V", 420, 640, 0.0, 0.75, 0.02, 2.2, 0.85, 1.0, 0.07, 0, [820, 1450, 20]],
		["N", 0, 0, 0.0, 0.5, 0.0, 4.0, 0.2, 0.5, 0]]},
}

const RevolverT := preload("res://enemies/types/revolver.gd")   # Slug = כדור של אויב
const TorchT := preload("res://enemies/types/torch.gd")         # Bottle = בקבוק תבערה של אויב
const Brain := preload("res://ai/zombie_brain.gd")

const HERD_R := 280.0            # מי נחשב "הקבוצה שלו"
const EXPOSE_R := 180.0          # מתקרבים מזה -> נחשף
const LEARN_EXPOSE_R := 120.0
const WHISPER_T := 3.0
const SILENCE_R := 320.0
const AIM_T := 0.55
const SHOT_V := 1100.0
const SHOT_DMG := 1
const THROW_R := Vector2(150.0, 470.0)
const MOLOTOV_CD := 5.0
const FIRE_W := 100.0
const FIRE_T := 3.5
const RUN_V := 215.0
const SEEK_R := Vector2(360.0, 1300.0)   # מחפש קבוצה חדשה בטווח הזה
const CONFUSE_T := 3.0
const LEARN_EXPOSED := 2
const SHOTS_BEFORE_RUN := 2

enum { HIDDEN, REVEAL, AIM, THROW, RUN, REHIDE }
var state := HIDDEN
# שליטה מסצנת סיפור
var talking := false
var tilt := 0.0
var smile := 0.0
var look_back := 0.0
var t := 0.0
var mask_off := 0.0
# לבדיקות
var exposures := 0
var whispers := 0
var shots := 0
var throws := 0
var rehides := 0
var confused := 0
var silenced := 0
var last_reason := ""
var _herd: Array = []
var _herd_t := 0.0
var _had_herd := false
var _st := 0.0
var _wh := 1.2
var _shots_left := SHOTS_BEFORE_RUN
var _mol_cd := 1.5
var _run_x := NAN
var _run_t := 0.0
var _run_t0 := 0.0
var _aim_to := Vector2.ZERO
var _blink := 2.0
var _breath := 0.0
var _whisper_anim := 0.0
var _recoil := 0.0
var _watched := false
var _cloak := Color("7a7a62")
var _hair := Color("2a2018")


func stats() -> Dictionary:
	return {"name": "QUISLING", "hp": 22, "walk": 40.0, "chase": 90.0, "damage": 1, "bite_delay": 1.0, "scale": 1.0, "width": 0.95,
		"duck": 0.0, "cover": 0.0, "skin": Color("d4a07a"), "shirt": Color("6a6a54"), "pants": Color("3a3428"), "shoe": Color("201a14"),
		"points": 500}


func use_brain_movement() -> bool:
	return false


func can_bite() -> bool:
	return false


func can_groan() -> bool:
	return false


func death_sound() -> String:
	return "qs_scream"


func setup() -> void:
	var r := RandomNumberGenerator.new()
	r.seed = z.get_instance_id()
	_cloak = Art.shade(Color("7a7a62"), r.randf_range(-0.1, 0.1))
	_hair = [Color("2a2018"), Color("4a3020"), Color("1a1614"), Color("6a5030")][r.randi() % 4]
	z.skin = Art.shade(Color("d4a07a"), r.randf_range(-0.12, 0.08))
	_blink = r.randf_range(1.0, 3.0)
	_breath = r.randf() * 2.4


func _main() -> Node:
	return z.get_parent()


func _learned() -> bool:
	var m := _main()
	return m != null and int(m.get_meta("quisling_exposed", 0)) >= LEARN_EXPOSED


func _actor() -> bool:
	return not z.is_in_group("zombies")


# ============================================================
#  תנועה
# ============================================================
func physics(pl: Node, delta: float) -> bool:
	if not z.is_on_floor():
		z.velocity.y += z.gravity * delta
	if _actor():   # סצנת סיפור: עומד (הסצנה מזיזה / מנפישה, ה-trigger מקדם את t)
		z.velocity.x = 0.0
		z.move_and_slide()
		return true
	t += delta
	_st -= delta
	_mol_cd -= delta
	_blink -= delta
	_breath += delta
	_whisper_anim -= delta
	_recoil -= delta
	if _blink < -0.12:
		_blink = randf_range(1.6, 3.6)
	if pl == null or pl.dead:
		z.velocity.x = move_toward(z.velocity.x, 0.0, 900.0 * delta)
		z.move_and_slide()
		return true
	var d: Vector2 = pl.global_position - z.global_position
	_herd_t -= delta
	if _herd_t <= 0.0:
		_herd_t = 0.4
		_scan_herd()
	match state:
		HIDDEN:
			_hidden(pl, d, delta)
		REVEAL:
			mask_off = move_toward(mask_off, 1.0, delta / 0.35)
			z._dir = signf(d.x) if absf(d.x) > 2.0 else z._dir
			z.velocity.x = move_toward(z.velocity.x, 0.0, 1400.0 * delta)
			if _st <= 0.0:
				_next_attack(pl, d)
		AIM:
			z._dir = signf(d.x) if absf(d.x) > 2.0 else z._dir
			z.velocity.x = move_toward(z.velocity.x, 0.0, 1400.0 * delta)
			if _st > 0.12:   # הקו עוקב אחריך עד רגע לפני הירייה
				_aim_to = pl.global_position + Vector2(0, -36) + pl.velocity * 0.12
			if _st <= 0.0:
				_fire()
				_after_attack(pl, d)
		THROW:
			z._dir = signf(d.x) if absf(d.x) > 2.0 else z._dir
			z.velocity.x = move_toward(z.velocity.x, 0.0, 1400.0 * delta)
			if _st <= 0.0:
				_throw(pl)
				_after_attack(pl, d)
		RUN:
			_run(pl, d, delta)
		REHIDE:
			mask_off = move_toward(mask_off, 0.0, delta / 0.5)
			z.velocity.x = move_toward(z.velocity.x, 0.0, 900.0 * delta)
			if absf(d.x) < _expose_r() and absf(d.y) < 90.0:
				_expose("close")
			elif mask_off <= 0.0:
				state = HIDDEN
				rehides += 1
				_had_herd = not _herd.is_empty()
	if z.is_on_floor() and z.is_on_wall() and absf(z.velocity.x) < 30.0 and (state == RUN or state == HIDDEN):
		z.velocity.y = -520.0   # מכשול: קופץ
	z.move_and_slide()
	return true


func _expose_r() -> float:
	return LEARN_EXPOSE_R if _learned() else EXPOSE_R


# הקבוצה: זומבים חיים קרובים (לא משת"פים אחרים, לא בוסים)
func _scan_herd() -> void:
	_herd.clear()
	var p: Vector2 = z.global_position
	for m in z.get_tree().get_nodes_in_group("zombies"):
		if m == z or m.dead or m.dormant or m.is_boss() or (m.type_mod != null and "mask_off" in m.type_mod):
			continue
		var dd: Vector2 = m.global_position - p
		if absf(dd.x) < HERD_R and absf(dd.y) < 120.0:
			_herd.append(m)


func _hidden(pl: Node, d: Vector2, delta: float) -> void:
	mask_off = move_toward(mask_off, 0.0, delta * 2.0)
	_herd = _herd.filter(func(m): return is_instance_valid(m) and not m.dead)
	if not _herd.is_empty():
		_had_herd = true
	# נחשף: קרוב מדי / כל הקבוצה מתה
	if absf(d.x) < _expose_r() and absf(d.y) < 90.0:
		_expose("close")
		return
	if _had_herd and _herd.is_empty():
		_expose("alone")
		return
	_watched = signf(-d.x) == float(pl._face()) and absf(d.x) < 900.0
	var tx: float = z.global_position.x
	var spd := 0.0
	if not _herd.is_empty():
		# הולך עם הקבוצה - בצד הרחוק ממך (למד: עמוק יותר מאחור)
		var cx := 0.0
		for m in _herd:
			cx += m.global_position.x
		cx /= float(_herd.size())
		var away := signf(-d.x) if d.x != 0.0 else 1.0
		tx = cx + away * (70.0 if _learned() else 14.0)
		spd = float(z.chase_speed) if absf(d.x) < 700.0 else float(z.walk_speed)
		# לוחש: שקט, צעד מסונכרן, איגוף
		for m in _herd:
			if m.global_position.distance_to(z.global_position) < SILENCE_R:
				m._groan_t = maxf(m._groan_t, 2.0)
				if absf(m.velocity.x) > 5.0:
					m._walk_phase = z._walk_phase
		_wh -= delta
		if _wh <= 0.0:
			_wh = WHISPER_T
			if absf(d.x) < 950.0:
				_whisper(pl)
	elif not _had_herd:
		# עוד אין לו קבוצה: מחפש אחת (מתחפש בינתיים)
		if is_nan(_run_x) or Engine.get_physics_frames() % 60 == 0:
			_run_x = _find_group(pl, false)
		if not is_nan(_run_x):
			tx = _run_x
			spd = float(z.walk_speed) * 1.4
	var gd: float = tx - z.global_position.x
	if absf(gd) > 8.0 and spd > 0.0:
		z._dir = signf(gd)
		z.velocity.x = move_toward(z.velocity.x, spd * signf(gd), 900.0 * delta)
		z._walk_phase += delta * 6.0
	else:
		z.velocity.x = move_toward(z.velocity.x, 0.0, 900.0 * delta)
		if absf(d.x) < 900.0:
			z._dir = signf(d.x) if d.x != 0.0 else z._dir


func _whisper(pl: Node) -> void:
	whispers += 1
	_whisper_anim = 0.7
	if Art.on_screen(z, z.global_position):
		Sfx.play("qs_whisper", z.global_position, -9.0, 0.1, 2)
	var i := 0
	for m in _herd:
		if not is_instance_valid(m) or m.brain == null:
			continue
		silenced += 1
		m._alert_t = maxf(m._alert_t, WHISPER_T + 0.5)
		if i % 2 == 0:   # חצי מאגפים מהצד השני
			m.brain.flank_side = -signf(m.global_position.x - pl.global_position.x)
			m.brain.command(Brain.FLANK, WHISPER_T)
		else:
			m.brain.command(Brain.APPROACH, WHISPER_T)
		i += 1


func _expose(reason: String) -> void:
	if state != HIDDEN and state != REHIDE:
		return
	last_reason = reason
	state = REVEAL
	_st = 0.35
	exposures += 1
	_shots_left = SHOTS_BEFORE_RUN
	Sfx.play("qs_gasp", z.global_position, 0.0, 0.1, 2)
	z._popup("ALIVE!", Color("ff6a50"), 16, -84.0)
	var pl := player()
	var m := _main()
	if m != null:
		var n := int(m.get_meta("quisling_exposed", 0)) + 1
		m.set_meta("quisling_exposed", n)
		if pl != null and pl.has_method("_say"):
			if n == 1:
				pl._say("THAT ONE'S ALIVE! A QUISLING!", Color("ffb070"))
			elif n == LEARN_EXPOSED:
				pl._say("THE LIVING ONES HIDE BETTER NOW", Color("ffb070"))


func _next_attack(pl: Node, d: Vector2) -> void:
	if _mol_cd <= 0.0 and absf(d.x) > THROW_R.x and absf(d.x) < THROW_R.y and absf(d.y) < 160.0:
		state = THROW
		_st = 0.45
		Sfx.play("whoosh", z.global_position, -6.0, 0.1, 2)
	else:
		state = AIM
		_st = AIM_T
		_aim_to = pl.global_position + Vector2(0, -36)


func _after_attack(pl: Node, d: Vector2) -> void:
	_shots_left -= 1
	if _shots_left > 0:
		_next_attack(pl, d)
		return
	_run_x = _find_group(pl, true)
	state = RUN
	_run_t = 5.0
	if is_nan(_run_x):   # אין לאן לברוח: מתרחק ויורה שוב
		_run_x = z.global_position.x - signf(d.x) * 320.0
		_run_t = 1.6
	_run_t0 = _run_t


func _muzzle() -> Vector2:
	return z.global_position + Vector2(z._dir * 20.0 * z.wf * z.sc, -40.0 * z.sc)


func _fire() -> void:
	shots += 1
	_recoil = 0.18
	var mz := _muzzle()
	var s = RevolverT.Slug.new()
	s.damage = SHOT_DMG
	s.velocity = (_aim_to - mz).normalized() * SHOT_V
	z.get_parent().add_child(s)
	s.global_position = mz
	Sfx.play("pistol", mz, -2.0, 0.08, 3)
	if Art.on_screen(z, mz):
		Particles.burst(z.get_parent(), mz, "smoke", s.velocity.normalized(), 2)


func _throw(pl: Node) -> void:
	throws += 1
	_mol_cd = MOLOTOV_CD
	var from: Vector2 = z.global_position + Vector2(z._dir * 6.0, -58.0 * z.sc)
	var to: Vector2 = pl.global_position + Vector2(pl.velocity.x * 0.45, 0.0)
	var b = TorchT.Bottle.new()
	var g: float = b.gravity
	var ft := clampf(absf(to.x - from.x) / 430.0, 0.5, 1.1)
	b.velocity = Vector2((to.x - from.x) / ft, (to.y - from.y - 0.5 * g * ft * ft) / ft)
	b.owner_z = z
	b.fire_w = FIRE_W
	b.fire_t = FIRE_T
	z.get_parent().add_child(b)
	b.global_position = from


# בורח לקבוצה הבאה ומתחפש שוב
func _run(pl: Node, d: Vector2, delta: float) -> void:
	_run_t -= delta
	mask_off = move_toward(mask_off, 1.0, delta * 3.0)
	if absf(d.x) < 120.0 and absf(d.y) < 80.0 and _run_t < _run_t0 - 0.6:   # תפסת אותו בדרך: מסתובב ויורה
		state = AIM
		_st = AIM_T * 0.7
		_shots_left = 1
		_aim_to = pl.global_position + Vector2(0, -36)
		return
	var gd: float = _run_x - z.global_position.x
	if absf(gd) < 30.0 or _run_t <= 0.0:
		_scan_herd()
		if not _herd.is_empty() and absf(d.x) > _expose_r() + 80.0:
			state = REHIDE
		else:
			_shots_left = 1
			_next_attack(pl, d)
		return
	z._dir = signf(gd)
	z.velocity.x = move_toward(z.velocity.x, RUN_V * signf(gd), 1800.0 * delta)
	z._walk_phase += delta * 15.0


# קבוצה של זומבים (2+) בטווח SEEK_R ממנו, רחוק מהשחקן. למד = הכי גדולה, לא הכי קרובה
func _find_group(pl: Node, away_only: bool) -> float:
	var p: Vector2 = z.global_position
	var cand: Array = []
	for m in z.get_tree().get_nodes_in_group("zombies"):
		if m == z or m.dead or m.dormant or m.is_boss() or (m.type_mod != null and "mask_off" in m.type_mod):
			continue
		var dx: float = m.global_position.x - p.x
		if absf(dx) > SEEK_R.y or absf(m.global_position.y - p.y) > 150.0:
			continue
		if away_only and (absf(dx) < SEEK_R.x or absf(m.global_position.x - pl.global_position.x) < 420.0):
			continue
		cand.append(m)
	var best := NAN
	var best_s := -INF
	for m in cand:
		var n := 0
		for o in cand:
			if absf(o.global_position.x - m.global_position.x) < HERD_R * 0.8:
				n += 1
		if n < 2:
			continue
		var dist := absf(m.global_position.x - p.x)
		var s := (float(n) * 400.0 - dist * 0.3) if _learned() else -dist
		if s > best_s:
			best_s = s
			best = m.global_position.x
	return best


func on_damage(_amount: int, _hit_pos: Vector2, _dir: Vector2, _src: Dictionary) -> bool:
	if not _actor() and (state == HIDDEN or state == REHIDE):
		_expose("shot")
	return true


# מת: הקבוצה שלו מבולבלת
func on_death() -> void:
	var n := 0
	for m in z.get_tree().get_nodes_in_group("zombies"):
		if m == z or m.dead or m.brain == null:
			continue
		if m.global_position.distance_to(z.global_position) < SILENCE_R + 40.0:
			m.brain.confuse(CONFUSE_T)
			m._groan_t = 0.2
			n += 1
			if n <= 4 and Art.on_screen(m, m.global_position):
				m._popup("?", Color("e0e0a0"), 16, -78.0)
	confused += n
	if n > 0:
		z._popup("LEADERLESS", Color("e0e0a0"), 15, -96.0)


func wants_redraw() -> bool:
	return true


# ============================================================
#  ציור: בן אדם בגלימה של עור מתים תפור, מסכת פנים של מת. מוסתר = מדדה כמו זומבי.
#  נחשף = המסכה למטה (mask_off), פנים מזיעות ומפוחדות, אקדח ביד.
# ============================================================
var _hc := Vector2.ZERO
var _ht := 0.0


func _H(p: Vector2) -> Vector2:   # נקודה על הראש (מסובבת לפי tilt)
	return _hc + p.rotated(_ht)


func draw() -> bool:
	begin_draw()
	var actor := _actor()
	var hidden: bool = (state == HIDDEN or state == REHIDE) and not z.dead
	var sk := col(z.skin)
	var cl := col(_cloak)
	var cl_d := col(Art.shade(_cloak, 0.3))
	var dead_sk := col(Color("8a9478"))
	var pa := col(z.pants)
	var shoe := col(z.shoe)
	var tt: float = t if actor else z._time
	var br := sin(tt * 2.2) * 0.6
	var hip := Vector2(0, -24)
	var sh := Vector2(1, -43 - br * 0.3)
	var ff := Vector2(5, 0)
	var fb := Vector2(-4, 0)
	var lean := 0.0
	var hf := sh + Vector2(4, 19)
	var hb := sh + Vector2(-3, 19)
	var moving: bool = absf(z.velocity.x) > 8.0 and not z.dead
	if moving:
		var p: float = z._walk_phase
		var stride := 9.0 if state == RUN else 5.0
		ff = Vector2(sin(p) * stride + 1.0, -maxf(0.0, cos(p)) * 3.0)
		fb = Vector2(sin(p + PI) * stride - 1.0, -maxf(0.0, cos(p + PI)) * 3.0)
	if hidden and not actor:   # מתחזה: גב שפוף, ידיים מושטות קדימה ותלויות, ראש מוטה
		lean = 3.0
		hf = sh + Vector2(15, 6 + sin(z._walk_phase) * 1.5)
		hb = sh + Vector2(12, 9)
	elif state == RUN:
		lean = 6.0
		hf = sh + Vector2(10, 12)
		hb = sh + Vector2(-8, 8)
	elif state == AIM or state == REVEAL:
		var lv := Vector2((_aim_to.x - z.global_position.x) * z._dir, _aim_to.y - (z.global_position.y - 40.0 * z.sc)).normalized()
		if state == REVEAL:
			lv = Vector2(1, 0.4).normalized()
		hf = sh + Vector2(2, 2) + lv * 19.0 - lv * (5.0 if _recoil > 0.0 else 0.0)
		hb = hf + Vector2(-3, 2)   # שתי ידיים על האקדח
	elif state == THROW:
		var k := clampf(1.0 - _st / 0.45, 0.0, 1.0)
		hf = sh + Vector2(-10 + k * 4.0, -14)   # יד מורמת אחורה עם הבקבוק
		hb = sh + Vector2(10, 6)
	sh.x += lean
	var head := sh + Vector2(2.5 + lean * 0.6, -9.0 + (2.0 if hidden and not actor else 0.0))
	# רגל אחורית, יד אחורית
	z._leg(hip + Vector2(-3, 0), fb, col(Art.shade(z.pants, 0.25)), sk, shoe)
	z._arm(sh + Vector2(-3, 2), hb, col(Art.shade(z.skin, 0.2)) if not hidden else dead_sk, cl_d)
	# גלימה: עור תפור, שוליים קרועים עד הברכיים
	var hem := hip.y + 13.0
	var sway: float = sin(tt * 3.0) * 1.5 + (-z.velocity.x * z._dir * 0.01)
	var cloak := PackedVector2Array([sh + Vector2(-9, -2), sh + Vector2(8, -1), Vector2(9 + lean * 0.3, hip.y), Vector2(10 + sway, hem - 2),
		Vector2(6 + sway, hem + 2), Vector2(2 + sway, hem - 1), Vector2(-2 + sway, hem + 3), Vector2(-6 + sway, hem), Vector2(-10 + sway, hem + 1),
		Vector2(-9, hip.y)])
	Art.fill_shaded(z, cloak, cl, 0.12, 0.38)
	# טלאים ותפרים
	DrawBatch.colored_polygon(z, PackedVector2Array([sh + Vector2(-6, 4), sh + Vector2(1, 3), sh + Vector2(2, 11), sh + Vector2(-5, 12)]), col(Art.shade(_cloak, -0.12)))
	DrawBatch.colored_polygon(z, PackedVector2Array([Vector2(1, hip.y - 4), Vector2(8, hip.y - 3), Vector2(8, hip.y + 7), Vector2(2, hip.y + 8)]), col(Art.shade(_cloak, 0.18)))
	var stc := col(Color(0.18, 0.1, 0.08))
	for q in 5:
		var a := sh + Vector2(-6.0 + float(q) * 1.8, 3.5 + float(q) * 1.7)
		DrawBatch.line(z, a + Vector2(-1.2, -1), a + Vector2(1.2, 1), stc, 0.7)
	for q in 4:
		var a := Vector2(1.5, hip.y - 3.0 + float(q) * 2.8)
		DrawBatch.line(z, a + Vector2(-1, -0.8), a + Vector2(1, 0.8), stc, 0.7)
	DrawBatch.line(z, sh + Vector2(-2, 0), Vector2(-3 + sway * 0.5, hem), col(Art.shade(_cloak, 0.45)), 0.8)
	# רגל קדמית
	z._leg(hip + Vector2(3, 0), ff, pa, sk, shoe)
	_draw_head(head, hidden, actor, tt)
	# יד קדמית (+ אקדח / בקבוק)
	var hand_sk := dead_sk if hidden else sk
	z._arm(sh + Vector2(3, 2), hf, hand_sk, cl)
	if not hidden and not z.dead:
		if state == THROW:
			var bc := hf + Vector2(0, -4)
			DrawBatch.colored_polygon(z, PackedVector2Array([bc + Vector2(-2.5, 4), bc + Vector2(2.5, 4), bc + Vector2(2.5, -3), bc + Vector2(1, -5), bc + Vector2(1, -8),
				bc + Vector2(-1, -8), bc + Vector2(-1, -5), bc + Vector2(-2.5, -3)]), col(Color(0.22, 0.42, 0.2, 0.95)))
			Art.glow(z, bc + Vector2(0, -10), 6.0 + sin(tt * 30.0), Color(1.0, 0.55, 0.15, 0.7))
			DrawBatch.circle(z, bc + Vector2(0, -10), 1.8, Color(1.0, 0.85, 0.4))
		else:
			var gv := (hf - (sh + Vector2(2, 2))).normalized()
			if state == RUN:
				gv = Vector2(0.3, 1).normalized()
			var gn := Vector2(-gv.y, gv.x)
			var g0 := hf
			var g1 := hf + gv * 11.0
			DrawBatch.line(z, g0, g1, col(Color("2a2a2e")), 2.6)                       # קנה
			DrawBatch.colored_polygon(z, PackedVector2Array([g0 - gv * 2.0 + gn * 1.5, g0 + gv * 4.0 + gn * 1.8, g0 + gv * 4.0 - gn * 2.2, g0 - gv * 2.0 - gn * 2.0]), col(Color("3a3a40")))   # תוף
			DrawBatch.line(z, g0 - gv * 1.0, g0 - gv * 3.0 - gn * 5.0, col(Color("5a3a22")), 2.4)   # ידית
			if _recoil > 0.08 and state == AIM:
				Art.glow(z, g1 + gv * 3.0, 7.0, Color(1.0, 0.8, 0.4, 0.8))
	end_draw()
	# קו כוונה (בקואורדינטות של העולם, בלי היפוך)
	if state == AIM and not z.dead and _st > 0.0:
		var mz: Vector2 = _muzzle() - z.global_position
		var to: Vector2 = _aim_to - z.global_position
		var k := clampf(1.0 - _st / AIM_T, 0.0, 1.0)
		var dirv: Vector2 = (to - mz).normalized()
		DrawBatch.line(z, mz, mz + dirv * 900.0, Color(1.0, 0.25, 0.15, 0.15 + 0.45 * k), 1.0 + k)
		DrawBatch.circle(z, mz, 2.0 + 2.0 * k, Color(1.0, 0.6, 0.3, 0.5 + 0.5 * k))
	return true


func _draw_head(head: Vector2, hidden: bool, actor: bool, tt: float) -> void:
	_hc = head
	_ht = tilt if actor else (0.22 if hidden else 0.0) + (0.25 if _whisper_anim > 0.0 else 0.0)
	var mo := clampf(mask_off, 0.0, 1.0)
	var sk := col(z.skin)
	var lb := clampf(look_back, 0.0, 1.0)
	var eye_dx := lerpf(0.0, -4.5, lb)   # מסתכל אחורה: העיניים זזות לצד השני
	var talk: float = (absf(sin(tt * 13.0)) * 1.6) if talking else 0.0
	var scared: bool = not hidden and not z.dead
	# ראש אנושי (תמיד מצויר - מתחת למסכה)
	var face := Art.ellipse(Vector2.ZERO, 5.6, 6.4, 0.0, 16)
	for i in face.size():
		face[i] = _H(face[i])
	Art.fill_shaded(z, face, sk, 0.16, 0.28)
	# שיער
	DrawBatch.colored_polygon(z, PackedVector2Array([_H(Vector2(-5.8, -1)), _H(Vector2(-5, -5.5)), _H(Vector2(-1, -7)), _H(Vector2(4, -6)), _H(Vector2(5.4, -3.5)),
		_H(Vector2(1, -4.6)), _H(Vector2(-2.5, -3.8)), _H(Vector2(-4.2, 0.5))]), col(_hair))
	if mo > 0.05:
		# פנים חיות: גבות מורמות, עיניים פקוחות לרווחה, זיעה, פה פתוח
		var by := -3.6 - (0.6 if scared else 0.0)
		DrawBatch.line(z, _H(Vector2(1.6 + eye_dx * 0.4, by + 0.4)), _H(Vector2(4.4 + eye_dx * 0.4, by - 0.4)), col(Color("3a2418")), 1.0)
		var ec := _H(Vector2(3.4 + eye_dx * 0.3, -1.4))
		var shut := _blink < 0.0 and not actor
		if shut:
			DrawBatch.line(z, ec + Vector2(-1.4, 0), ec + Vector2(1.4, 0), col(Color("3a2418")), 0.9)
		else:
			DrawBatch.circle(z, ec, 1.5, col(Color("f4f0e8")))
			DrawBatch.circle(z, ec + Vector2(0.4 + eye_dx * 0.25, 0.1), 0.75, Color(0.15, 0.1, 0.08))
		DrawBatch.line(z, _H(Vector2(5.6, -0.5)), _H(Vector2(6.4, 1.2)), col(Art.shade(z.skin, 0.25)), 1.0)   # אף
		var mo_y := 3.0
		var mo_open := (1.4 if scared else 0.0) + talk
		if smile > 0.05 and not scared:
			DrawBatch.polyline(z, PackedVector2Array([_H(Vector2(1.4, mo_y - smile * 0.6)), _H(Vector2(3.0, mo_y + 0.5)), _H(Vector2(4.8, mo_y - smile * 1.0))]), col(Color("5a2a22")), 0.9)
		elif mo_open > 0.2:
			DrawBatch.colored_polygon(z, PackedVector2Array([_H(Vector2(2.0, mo_y - 0.4)), _H(Vector2(4.6, mo_y - 0.4)), _H(Vector2(4.2, mo_y + mo_open)), _H(Vector2(2.4, mo_y + mo_open))]), col(Color("3a1010")))
		else:
			DrawBatch.line(z, _H(Vector2(2.0, mo_y)), _H(Vector2(4.6, mo_y)), col(Color("5a2a22")), 0.9)
		if scared or actor:   # טיפות זיעה (מבריקות)
			for q in 2:
				var sy := fmod(tt * 0.8 + float(q) * 0.5, 1.0)
				var sp := _H(Vector2(-1.0 + float(q) * 3.5, -3.0 + sy * 6.0))
				DrawBatch.circle(z, sp, 0.8, Color(0.85, 0.95, 1.0, 0.75 * (1.0 - sy) * mo))
	# המסכה: עור של מת, תפור. mask_off מוריד אותה לצוואר
	var drop := mo * 10.0
	var squash := 1.0 - mo * 0.55
	var mk := col(Color("8a9478"))
	var mk_d := col(Color("5a6450"))
	var mpts := PackedVector2Array()
	for p in [Vector2(-6.4, -6.6), Vector2(0.0, -7.6), Vector2(5.8, -6.0), Vector2(6.8, -1.0), Vector2(6.6, 3.4), Vector2(4.6, 6.8), Vector2(0.0, 7.6), Vector2(-5.8, 6.0), Vector2(-6.8, 0.0)]:
		mpts.append(_H(Vector2(p.x * (1.0 + mo * 0.1), p.y * squash + drop)))
	if mo >= 0.95:   # מורדת לגמרי: נתלית על הצוואר כמו צעיף
		Art.fill_shaded(z, mpts, mk, 0.1, 0.35)
		DrawBatch.line(z, _H(Vector2(-5, drop - 1)), _H(Vector2(5, drop - 1.5)), col(Color(0.2, 0.12, 0.1)), 0.7)
		return
	Art.fill_shaded(z, mpts, mk, 0.12, 0.36)
	# תפרים בצד המסכה ובמצח
	var stc := col(Color(0.2, 0.1, 0.08))
	DrawBatch.polyline(z, PackedVector2Array([_H(Vector2(-4.5, -6 * squash + drop)), _H(Vector2(-5.5, -1 * squash + drop)), _H(Vector2(-4.8, 4 * squash + drop))]), stc, 0.7)
	for q in 4:
		var a := _H(Vector2(-5.2 + (0.3 if q % 2 == 0 else -0.3), (-5.0 + float(q) * 2.6) * squash + drop))
		DrawBatch.line(z, a + Vector2(-1, 0), a + Vector2(1, 0), stc, 0.7)
	# שיער מת מודבק למסכה
	for q in 4:
		var hp0 := _H(Vector2(-4.0 + float(q) * 2.6, -6.4 * squash + drop))
		DrawBatch.line(z, hp0, hp0 + Vector2(-1.0 + float(q) * 0.3, 6.0 + float(q % 2) * 3.0), col(Color("3a3a30")), 0.8)
	# ריקבון / כתמים על המסכה
	Art.oval(z, _H(Vector2(-2.0, 2.2 * squash + drop)), 1.6, 1.1, Color(0.35, 0.2, 0.15, 0.7 * (1.0 - mo)), 0.0, Art.NONE)
	if mo < 0.5:
		# חורי עיניים - ובתוכם עיניים לבנות של בן אדם (ממצמצות!)
		var ep := _H(Vector2(3.4, -1.4 + drop))
		DrawBatch.colored_polygon(z, Art.ellipse(ep, 2.2, 1.7 * squash, _ht, 10), col(Color("1a1410")))
		var shut2 := _blink < 0.0 and not actor
		if shut2:
			DrawBatch.line(z, ep + Vector2(-1.2, 0), ep + Vector2(1.2, 0), sk, 0.9)
		elif not z.dead:
			DrawBatch.circle(z, ep, 1.25, Color(0.96, 0.95, 0.9))
			DrawBatch.circle(z, ep + Vector2(0.35 + eye_dx * 0.25, 0.1), 0.6, Color(0.1, 0.08, 0.06))
		# פה המסכה: חתך רפוי
		var mo2 := talk
		DrawBatch.colored_polygon(z, PackedVector2Array([_H(Vector2(1.6, 3.0 + drop)), _H(Vector2(5.0, 2.6 + drop)), _H(Vector2(4.6, 4.0 + drop + mo2)),
			_H(Vector2(2.2, 4.2 + drop + mo2))]), col(Color("2a1a14")))
		if smile > 0.05:
			DrawBatch.polyline(z, PackedVector2Array([_H(Vector2(1.2, 2.6 + drop)), _H(Vector2(3.2, 3.6 + drop)), _H(Vector2(5.4, 2.2 + drop - smile))]), col(Color("1a0c08")), 0.8)
		DrawBatch.line(z, _H(Vector2(5.8, -0.6 + drop)), _H(Vector2(6.8, 1.4 + drop)), mk_d, 1.0)
	# אדי נשימה: בן אדם חי נושם (למד: עוצר נשימה כשמסתכלים עליו)
	if not z.dead and not (_learned() and _watched and state == HIDDEN):
		var bp := fmod(_breath if not actor else tt, 2.4)
		if bp < 0.9:
			var k := bp / 0.9
			var c0 := _H(Vector2(7.5 + k * 7.0, 3.0 - k * 4.0))
			var a := 0.4 * (1.0 - k)
			Art.oval(z, c0, 2.0 + k * 4.0, 1.4 + k * 2.6, Color(0.92, 0.94, 0.98, a), 0.0, Art.NONE)
			Art.oval(z, c0 + Vector2(-2.5, 1.0), 1.4 + k * 2.4, 1.0 + k * 1.6, Color(0.92, 0.94, 0.98, a * 0.7), 0.0, Art.NONE)
