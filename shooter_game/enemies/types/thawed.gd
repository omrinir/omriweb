extends "res://enemies/zombie_type.gd"
# ============================================================
#  THAWED (שלב 56, "ICE FJORD") - דייג מת שקפא בתוך קליפת קרח: שריון כחול שקוף, והגוף נראה בפנים
#    (סוודר, סרבל גומי, עור כחלחל, שפתיים כחולות). כבד ואיטי, צעדים שמפצחים את הקרח.
#  מה הם למדו: "ראשים נשברים" - אלפי מתים נפלו מכדור בראש. הנבגים של האחרונים שמתו נשאו את התחושה של הקור:
#    קרח עוצר כדור טוב יותר מגולגולת. אז הם נכנסו למים, יצאו, וקפאו - עם קסדה של קרח.
#  שריון: 4 לוחות קרח (PLATES: ראש / חזה / אמה קדמית / רגליים), בכל אחד שכבות (LAYERS) עם LAYER_HP.
#    כדור שפוגע בלוח עם קרח - רק מפצח אותו (רסיסים עפים, סדקים מתרבים), הגוף לא נפגע. שכבה נשברת = פיצוץ רסיסים.
#    לוח שנעלם = הבשר הקפוא חשוף (x SOFT_MULT). ירייה בראש לא עובדת עד שהקסדה נשברת ("HEAD EXPOSED").
#    אש (בעירה / קליעי אש / להביור) ממיסה את כל הלוחות (MELT_RATE לשנייה, אדים), פיצוץ מוריד BLAST_ICE מכל לוח.
#  התקפה: SLAM - מרים את שני האגרופים הקפואים (WIND_T) ומוחץ (DMG + קור: slow). כשכל הקרח ירד - מהיר יותר (BARE_SPEED).
#  "THEY LEARN" (main meta):
#    "th_heads" >= HEAD_LEARN (שברת קסדות): הבאים מכסים את הראש באמה הקפואה כשאתה מכוון אליהם ("IT GUARDS ITS HEAD").
#       נגד: לשבור קודם את האמה / לירות בגוף / לחכות שיוריד אותה כדי להכות.
#    "th_stripped" >= STRIP_LEARN (קילפת אותם עד הסוף): הבאים קופאים מחדש (REFREEZE_T בלי פגיעה -> שכבה דקה חוזרת,
#       עד REFREEZE_MAX פעמים) - "IT REFREEZES". נגד: לא להפסיק לירות / אש (בזמן בעירה לא קופא).
#  מוות: הקרח מתנפץ (IceShards - מאות רסיסים בקריאת ציור אחת), גושי דם קפוא (Quality.gore()), הגוף נופל (ragdoll).
#  בוס (chase_range > 600): "THE GLACIER" - ענק בתוך גוש קרחון. 4 לוחות עבים (BOSS_LAYERS x BOSS_LAYER_HP).
#    SMASH  - מכה בקרקע מקרוב (SMASH_WIND): גל קרח לאורך הרצפה (SMASH_R) - לקפוץ.
#    THROW  - תולש גוש קרח (THROW_WIND) וזורק בקשת אליך (גם למדף). לירות בגוש באוויר = מתנפץ. מתחת ל-50%: שניים.
#    CALVE  - שואג ורוקע (ROAR_T): המדף התלוי הקרוב אליך בזירה מתנתק (stage.calve_near). כל CALVE_EVERY מתחת ל-70%.
#    קופא מחדש תמיד (BOSS_REFREEZE_T בלי פגיעה -> שכבה חוזרת ללוח הכי פגוע). מוות: התנפצות ענקית.
#  צלילים: "th_chip", "th_crack", "th_shatter", "th_step", "th_freeze", "th_roar", "th_slam".
#  לשנות: LAYER_HP, LAYERS, SOFT_MULT, MELT_RATE, BLAST_ICE, SLAM_R, WIND_T, DMG, BARE_SPEED, HEAD_LEARN, STRIP_LEARN,
#    REFREEZE_T, REFREEZE_MAX, GUARD_R; בוס: BOSS_LAYERS, BOSS_LAYER_HP, SMASH_*, THROW_*, CALVE_EVERY, BOSS_REFREEZE_T.
# ============================================================

const SOUNDS := {
	"th_chip": [["S", 3400, 2600, 0.0, 0.06, 0.0, 60.0, 0.22, 1.0, 0], ["N", 0, 0, 0.0, 0.04, 0.0, 90.0, 0.45, 1.0, 0, 0.6], ["S", 5200, 4800, 0.0, 0.04, 0.0, 80.0, 0.1, 1.0, 0]],
	"th_crack": {"rev": 0.15, "layers": [["N", 0, 0, 0.0, 0.22, 0.0, 14.0, 0.9, 0.9, 0, 0.3], ["C", 0, 0, 0.0, 0.25, 0.0, 10.0, 0.9, 1.0, 0], ["S", 2900, 2400, 0.0, 0.18, 0.0, 16.0, 0.25, 1.0, 0], ["S", 140, 70, 0.0, 0.12, 0.0, 20.0, 0.4, 1.0, 0]]},
	"th_shatter": {"rev": 0.3, "drive": 2.0, "layers": [["N", 0, 0, 0.0, 0.5, 0.0, 7.0, 1.0, 1.0, 0, 0.3], ["C", 0, 0, 0.0, 0.6, 0.0, 5.0, 1.0, 1.0, 0], ["S", 3600, 3100, 0.0, 0.5, 0.0, 7.0, 0.2, 1.0, 0], ["S", 4700, 4600, 0.03, 0.4, 0.0, 9.0, 0.15, 1.0, 0], ["S", 110, 45, 0.0, 0.3, 0.0, 10.0, 0.6, 1.0, 0]]},
	"th_step": [["N", 0, 0, 0.0, 0.1, 0.0, 30.0, 0.55, 0.35, 0], ["C", 0, 0, 0.0, 0.1, 0.0, 25.0, 0.4, 1.0, 0], ["S", 80, 45, 0.0, 0.08, 0.0, 35.0, 0.4, 1.0, 0]],
	"th_freeze": [["S", 1800, 3600, 0.0, 0.6, 0.05, 4.0, 0.12, 1.0, 0.05], ["C", 0, 0, 0.0, 0.6, 0.0, 4.0, 0.6, 1.0, 0], ["N", 0, 0, 0.0, 0.5, 0.05, 5.0, 0.2, 0.9, 0, 0.6]],
	"th_roar": {"rev": 0.4, "drive": 2.8, "layers": [["V", 70, 48, 0.0, 1.6, 0.1, 1.4, 1.0, 1.0, 0.06, 0, [420, 760, 20]], ["N", 0, 0, 0.0, 1.5, 0.1, 1.8, 0.3, 0.12, 0], ["C", 0, 0, 0.3, 1.2, 0.0, 2.0, 0.6, 1.0, 0]]},
	"th_slam": {"rev": 0.3, "drive": 2.4, "layers": [["N", 0, 0, 0.0, 0.5, 0.0, 9.0, 1.0, 0.25, 0], ["S", 60, 28, 0.0, 0.5, 0.0, 7.0, 1.0, 1.0, 0], ["C", 0, 0, 0.0, 0.4, 0.0, 8.0, 0.8, 1.0, 0], ["S", 3000, 2600, 0.0, 0.2, 0.0, 14.0, 0.12, 1.0, 0]]},
}

const Boom := preload("res://explosion.gd")

enum { HEAD, CHEST, ARM, LEGS }
const LAYERS := [2, 2, 1, 1]
const LAYER_HP := [26, 30, 22, 20]
const SOFT_MULT := 1.25           # בשר קפוא חשוף
const MELT_RATE := 34.0           # נקודות קרח לשנייה בזמן בעירה (מכל לוח)
const INC_MELT := 3.0             # קליע אש: x3 על הקרח
const BLAST_ICE := 40             # פיצוץ: מכל לוח
const ICED_BLAST := 0.5           # פיצוץ על גוף שעדיין בקרח: חצי נזק לגוף
const SLAM_R := 62.0
const WIND_T := 0.55
const STRIKE_T := 0.18
const RECOVER_T := 0.55
const DMG := 1
const CHILL := 0.8                # slow_t אחרי מכה
const CD := Vector2(1.0, 1.7)
const BARE_SPEED := 1.45          # בלי קרח בכלל: מהיר יותר
const HEAD_LEARN := 2
const STRIP_LEARN := 2
const REFREEZE_T := 3.0
const REFREEZE_MAX := 3
const THIN_HP := 12               # שכבה שקפאה מחדש = דקה
const GUARD_R := 620.0
# בוס
const BOSS_LAYERS := [2, 2, 2, 2]
const BOSS_LAYER_HP := [44, 56, 44, 40]
const SMASH_R := 190.0
const SMASH_WIND := 0.75
const SMASH_DMG := 2
const THROW_WIND := 0.6
const THROW_R := Vector2(200.0, 900.0)
const THROW_DMG := 1
const CALVE_EVERY := 11.0
const ROAR_T := 1.1
const BOSS_REFREEZE_T := 3.5
const BOSS_CD := Vector2(1.1, 1.8)

enum { WALK, WIND, STRIKE, RECOVER, SMASH_W, SMASH, THROW_W, THROW, ROAR }
var state := WALK
# לבדיקות
var chips := 0
var layers_broken := 0
var plates_gone := 0
var melts := 0.0
var blast_strips := 0
var guards := 0               # ירייה בראש שנחסמה ע"י האמה
var refreezes := 0
var slams := 0
var slam_hits := 0
var head_hits_blocked := 0    # ירייה בראש שהקסדה ספגה
var smashes := 0
var smash_hits := 0
var throws := 0
var throw_hits := 0
var blocks_shot := 0
var calves := 0
var guarding := false

var ice := [0, 0, 0, 0]       # hp בשכבה הנוכחית
var lay := [0, 0, 0, 0]       # כמה שכבות נשארו
var _thin := [false, false, false, false]
var _st := 0.0
var _cd := 1.0
var _since_hit := 0.0
var _met := false
var _hit_done := false
var _hit_kind := "ice"
var _guard_k := 0.0
var _step := 0.0
var _breath := 0.0
var _refrozen := 0
var _freeze_fx := 0.0
var _calve_cd := 6.0
var _throw_n := 0
var _throw_to := Vector2.ZERO
var _seed := 0
var _sweater := Color("2a3a5a")
var _pants := Color("d8a02a")
var _beanie := Color("b03a2a")
var _has_beanie := true
var _tint := Color(0.75, 0.9, 1.0)
var _fish := false
var _learn_g := false
var _learn_r := false


func _boss() -> bool:
	return z != null and float(z.chase_range) > 600.0


func stats() -> Dictionary:
	if _boss():
		return {"name": "THAWED", "hp": 230, "walk": 26.0, "chase": 46.0, "damage": 2, "bite_delay": 1.2, "scale": 2.5, "width": 1.15,
			"duck": 0.0, "cover": 0.0, "skin": Color("8ea8bc"), "shirt": Color("2a3a5a"), "pants": Color("3a3a40"), "shoe": Color("1a1a1e"),
			"points": 2800, "boss": true, "boss_name": "THE GLACIER", "ragdoll": false, "flesh": _hit_kind != "ice"}
	return {"name": "THAWED", "hp": 46, "walk": 32.0, "chase": 58.0, "damage": 1, "bite_delay": 1.0, "scale": 1.12, "width": 1.2,
		"duck": 0.0, "cover": 0.0, "skin": Color("9fb6c8"), "shirt": Color("2a3a5a"), "pants": Color("d8a02a"), "shoe": Color("1e2a22"),
		"points": 520, "flesh": _hit_kind != "ice"}


func use_brain_movement() -> bool:
	return false


func can_bite() -> bool:
	return false


func setup() -> void:
	var r := RandomNumberGenerator.new()
	r.seed = z.get_instance_id()
	_seed = r.randi()
	_sweater = [Color("b8322a"), Color("28407a"), Color("2f7a3e"), Color("c8901e"), Color("7a2a5a"), Color("1e6a7a")][r.randi() % 6]
	_pants = [Color("f2c21e"), Color("ec6a16"), Color("f2c21e"), Color("2f5a8a")][r.randi() % 4]
	_beanie = [Color("b03a2a"), Color("e0c040"), Color("3a6aa0"), Color("2a2a2a")][r.randi() % 4]
	_has_beanie = r.randf() < 0.6
	_tint = Color(0.72, 0.9, 1.0).lerp(Color(0.75, 1.0, 0.92), r.randf() * 0.6)
	_fish = r.randf() < 0.35
	var m := _main()
	_learn_g = not _boss() and m != null and int(m.get_meta("th_heads", 0)) >= HEAD_LEARN
	_learn_r = _boss() or (m != null and int(m.get_meta("th_stripped", 0)) >= STRIP_LEARN)
	for i in 4:
		lay[i] = int(BOSS_LAYERS[i] if _boss() else LAYERS[i])
		ice[i] = _layer_hp(i)
	if _boss():
		var rs := z._shape.shape as RectangleShape2D
		rs.size = Vector2(46.0 * z.wf * z.sc, 66.0 * z.sc)
		z._shape.position = Vector2(0.0, -33.0 * z.sc)
	_breath = randf() * 3.0


func _main() -> Node:
	return z.get_parent()


func _layer_hp(i: int) -> int:
	return int(BOSS_LAYER_HP[i] if _boss() else LAYER_HP[i])


func has_ice(i: int) -> bool:
	return lay[i] > 0


func iced_count() -> int:
	var n := 0
	for i in 4:
		if lay[i] > 0:
			n += 1
	return n


func learned_guard() -> bool:
	return _learn_g


func learned_refreeze() -> bool:
	return _learn_r


# ============================================================
#  תנועה
# ============================================================
func physics(pl: Node, delta: float) -> bool:
	_st -= delta
	_cd -= delta
	_since_hit += delta
	_step -= delta
	_breath += delta
	_freeze_fx = move_toward(_freeze_fx, 0.0, delta * 1.5)
	if not z.is_on_floor():
		z.velocity.y += z.gravity * delta
	var has: bool = pl != null and not pl.dead
	var d: Vector2 = (pl.global_position - z.global_position) if has else Vector2.ZERO
	if z._burn_t > 0.0 and iced_count() > 0:   # בוער: הקרח נמס
		_melt_all(MELT_RATE * delta)
		if Engine.get_physics_frames() % 6 == 0 and Art.on_screen(z, z.global_position):
			Particles.burst(z.get_parent(), z.global_position + Vector2(randf_range(-10, 10), -40.0 * z.sc), "mist", Vector2.UP, 2)
	if _learn_r and _since_hit > (BOSS_REFREEZE_T if _boss() else REFREEZE_T) and z._burn_t <= 0.0 and (_boss() or _refrozen < REFREEZE_MAX):
		_refreeze()
	if not _met and has and (absf(d.x) < z.chase_range or z._alert_t > 0.0):
		_met = true
		z._noticed = true
		if _boss():
			Game.story.emit("boss", {"z": z})
			Sfx.play("th_roar", z.global_position, 3.0, 0.0, 1)
			z._popup("THE GLACIER", Color("9adcff"), 22, -170.0)
	if _boss():
		_boss_physics(pl, has, d, delta)
		z.move_and_slide()
		return true
	_guard_update(pl, has, d, delta)
	match state:
		WALK:
			var v := 0.0
			if has and _met:
				var want: float = signf(d.x) if absf(d.x) > 4.0 else z._dir
				z._dir = want
				if absf(d.x) > SLAM_R * z.sc * 0.8:
					v = z._dir * float(z.chase_speed) * (BARE_SPEED if iced_count() == 0 else 1.0) * (0.8 if guarding else 1.0)
				if _cd <= 0.0 and absf(d.x) < SLAM_R * z.sc and absf(d.y) < 50.0 and z.is_on_floor():
					state = WIND
					_st = WIND_T
					Sfx.play("th_crack", z.global_position, -8.0, 0.2, 2)
			z.velocity.x = move_toward(z.velocity.x, v, 700.0 * delta)
			z._walk_phase += delta * absf(z.velocity.x) / 15.0
			if absf(z.velocity.x) > 15.0 and _step <= 0.0 and Art.on_screen(z, z.global_position):
				_step = 0.48
				Sfx.play("th_step", z.global_position, -9.0, 0.2, 2)
				if randf() < 0.5:
					Particles.burst(z.get_parent(), z.global_position + Vector2(z._dir * 4.0, -2.0), "snow", Vector2.UP, 2)
			if z.is_on_floor() and z.is_on_wall() and absf(z.velocity.x) < 20.0 and absf(d.x) > 60.0:
				z.velocity.y = -520.0
		WIND:
			z.velocity.x = move_toward(z.velocity.x, 0.0, 1200.0 * delta)
			if has and _st > WIND_T * 0.4:
				z._dir = signf(d.x) if absf(d.x) > 4.0 else z._dir
			if _st <= 0.0:
				state = STRIKE
				_st = STRIKE_T
				_hit_done = false
				slams += 1
				Sfx.play("th_slam", z.global_position, -2.0, 0.1, 3)
				if Art.on_screen(z, z.global_position):
					Particles.burst(z.get_parent(), z.global_position + Vector2(z._dir * 26.0 * z.sc, -4.0), "snow", Vector2.UP, 8)
					IceShards.spray(z.get_parent(), z.global_position + Vector2(z._dir * 24.0 * z.sc, -4.0), Vector2(0, -1), 6, z.global_position.y, _tint, 0.6)
		STRIKE:
			z.velocity.x = move_toward(z.velocity.x, 0.0, 1500.0 * delta)
			if has and not _hit_done and absf(d.x) < (SLAM_R + 14.0) * z.sc and d.x * z._dir > -10.0 and absf(d.y + 10.0) < 50.0:
				_hit_done = true
				if pl._roll_t <= 0.0:
					slam_hits += 1
					pl.slow_t = maxf(pl.slow_t, CHILL)
				pl.hurt(DMG, Vector2(z._dir * 1.3, -0.5))
			if _st <= 0.0:
				state = RECOVER
				_st = RECOVER_T
		RECOVER:
			z.velocity.x = move_toward(z.velocity.x, 0.0, 1200.0 * delta)
			if _st <= 0.0:
				state = WALK
				_cd = randf_range(CD.x, CD.y)
	z.move_and_slide()
	return true


# מכסה את הראש באמה כשאתה מכוון אליו (למד)
func _guard_update(pl: Node, has: bool, d: Vector2, delta: float) -> void:
	var want := false
	if _learn_g and has and has_ice(ARM) and state == WALK and absf(d.x) < GUARD_R and signf(d.x) == z._dir:
		var head: Vector2 = z.global_position + Vector2(z._dir * 3.0 * z.wf * z.sc, -51.0 * z.sc)
		var to: Vector2 = (head - pl.global_position - Vector2(0, -36)).normalized()
		want = pl._aim.normalized().dot(to) > 0.93
	if want and not guarding:
		var m := _main()
		if m != null and not m.has_meta("th_told_guard"):
			m.set_meta("th_told_guard", true)
			z._popup("IT GUARDS ITS HEAD NOW", Color("9adcff"), 14, -96.0)
			if pl.has_method("_say"):
				pl._say("They learned I go for the head... break the arm", Color("9adcff"))
	guarding = want
	_guard_k = move_toward(_guard_k, 1.0 if guarding else 0.0, delta * (7.0 if guarding else 4.0))


# ============================================================
#  נזק: קרח / בשר
# ============================================================
func on_damage(amount: int, hit_pos: Vector2, dir: Vector2, src: Dictionary) -> bool:
	if z.dead:
		return true
	var s := str(src.get("source", "bullet"))
	_since_hit = 0.0
	if s == "th_block":   # גוש הקרח של עצמו
		return false
	if s == "fire":   # בעירה: נזק לגוף (הקרח נמס ב-physics)
		_hit_kind = "soft"
		return true
	if not (s == "bullet" or s == "melee"):   # פיצוץ / מלכודת: מוריד קרח מכל הלוחות, הגוף נפגע חלקית
		var had := iced_count() > 0
		if src.has("blast") or s in ["grenade", "barrel", "rocket", "launcher", "molotov", "hauler_tank"]:
			blast_strips += 1
			for i in 4:
				_ice_damage(i, BLAST_ICE, hit_pos, -dir, true)
			Particles.burst(z.get_parent(), z.global_position + Vector2(0, -30.0 * z.sc), "mist", Vector2.UP, 6)
		_hit_kind = "blast_iced" if had else "soft"
		return true
	var p := _plate_at(hit_pos, dir)
	if p >= 0 and has_ice(p):
		var dmg := hit_damage(amount, hit_pos, src)
		if src.get("incendiary", false):
			dmg = int(float(dmg) * INC_MELT) + 4
			z.ignite(2.0)
			melts += float(dmg)
		if p == ARM and guarding and _plate_raw(hit_pos) == HEAD:
			guards += 1
		if p == HEAD:
			head_hits_blocked += 1
		_ice_damage(p, dmg, hit_pos, -dir, false)
		z._flash = 0.04
		Game.on_zombie_hit({"source": "bullet", "zone": "ice"})
		if Art.on_screen(z, hit_pos):
			Sfx.play("th_chip", hit_pos, -3.0, 0.2, 4)
		return false
	_hit_kind = "soft"
	return true


func damage_mult(_zone: String, _src: Dictionary) -> float:
	match _hit_kind:
		"soft":
			return SOFT_MULT if not _boss() else 1.0
		"blast_iced":
			return ICED_BLAST
	return 1.0


# הלוח שהכדור פוגע בו (בלי שמירה)
func _plate_raw(hit_pos: Vector2) -> int:
	var ly: float = (hit_pos.y - z.global_position.y) / z.sc
	if ly < -42.0:
		return HEAD
	if ly > -20.0:
		return LEGS
	if _boss():
		var lx: float = (hit_pos.x - z.global_position.x) * z._dir / (z.sc * z.wf)
		if lx > 9.0:
			return ARM
	return CHEST


func _plate_at(hit_pos: Vector2, dir: Vector2) -> int:
	var p := _plate_raw(hit_pos)
	var front: bool = dir.x * z._dir < 0.0
	if p == HEAD and _guard_k > 0.5 and has_ice(ARM) and front:
		return ARM   # האמה הקפואה לפני הפנים
	if p == CHEST and not _boss() and front and has_ice(ARM) and (hit_pos.x - z.global_position.x) * z._dir / (z.sc * z.wf) > 7.0 and _guard_k < 0.5:
		var ly: float = (hit_pos.y - z.global_position.y) / z.sc
		if ly > -34.0:   # האמה מכסה את הבטן מלפנים
			return ARM
	return p


func _ice_damage(i: int, dmg: int, pos: Vector2, out: Vector2, blast: bool) -> void:
	if not has_ice(i) or dmg <= 0:
		return
	chips += 1
	ice[i] -= dmg
	var on := Art.on_screen(z, pos, 80.0)
	if on:
		IceShards.spray(z.get_parent(), pos, out if out != Vector2.ZERO else Vector2.UP, 2 + int(dmg / 12), z.global_position.y, _tint, 0.5 * z.sc)
	var m := _main()
	if i == HEAD and m != null and not m.has_meta("th_told_head") and not _boss():
		m.set_meta("th_told_head", true)
		z._popup("ICE HELMET", Color("9adcff"), 14, -92.0)
		var pl := player()
		if pl != null and pl.has_method("_say"):
			pl._say("They froze their heads... break the ice first. Fire melts it", Color("9adcff"))
	while ice[i] <= 0 and lay[i] > 0:
		var over: int = -int(ice[i])
		lay[i] -= 1
		layers_broken += 1
		_thin[i] = false
		if lay[i] > 0:
			ice[i] = _layer_hp(i) - over
		else:
			ice[i] = 0
		if on or blast:
			Sfx.play("th_crack", pos, 0.0, 0.15, 3)
			IceShards.spray(z.get_parent(), _plate_center(i), out if out != Vector2.ZERO else Vector2.UP, 10 if lay[i] > 0 else 16, z.global_position.y, _tint, 0.8 * z.sc)
			Particles.burst(z.get_parent(), _plate_center(i), "snow", Vector2.UP, 6)
		if lay[i] == 0:
			plates_gone += 1
			_on_plate_gone(i)


func _on_plate_gone(i: int) -> void:
	var m := _main()
	if i == HEAD:
		z._popup("HEAD EXPOSED" if not _boss() else "CROWN BROKEN", Color("ffe08a"), 15 if not _boss() else 20, -92.0 if not _boss() else -170.0)
		if m != null and not _boss():
			m.set_meta("th_heads", int(m.get_meta("th_heads", 0)) + 1)
	elif _boss():
		z._popup(["", "CORE EXPOSED", "ARMS BROKEN", "LEGS BROKEN"][i], Color("ffe08a"), 18, -160.0)
	if iced_count() == 0 and not _boss():
		z._popup("THAWED!", Color("ff9a7a"), 16, -96.0)
		if m != null:
			m.set_meta("th_stripped", int(m.get_meta("th_stripped", 0)) + 1)


func _melt_all(amount: float) -> void:
	_acc_melt += amount
	if _acc_melt < 1.0:
		return
	var a := int(_acc_melt)
	_acc_melt -= float(a)
	melts += float(a)
	for i in 4:
		if has_ice(i):
			_ice_damage(i, a, _plate_center(i), Vector2.UP, false)


var _acc_melt := 0.0


func _refreeze() -> void:
	# לוח שנעלם / פגוע -> שכבה דקה חוזרת (בוס: שכבה מלאה ללוח הכי פגוע)
	var best := -1
	var worst := 99999.0
	for i in 4:
		var full := float(_layer_hp(i) * int(BOSS_LAYERS[i] if _boss() else LAYERS[i]))
		var now := float(maxi(lay[i] - 1, 0) * _layer_hp(i) + maxi(ice[i], 0))
		var frac := now / full
		if frac < 0.99 and frac < worst:
			worst = frac
			best = i
	if best < 0:
		_since_hit = 0.0
		return
	refreezes += 1
	_refrozen += 1
	_since_hit = (BOSS_REFREEZE_T if _boss() else REFREEZE_T) - (1.2 if _boss() else 0.0)
	if lay[best] == 0:
		lay[best] = 1
		ice[best] = _layer_hp(best) if _boss() else THIN_HP
		_thin[best] = not _boss()
	else:
		ice[best] = _layer_hp(best)
	_freeze_fx = 1.0
	Sfx.play("th_freeze", z.global_position, 0.0, 0.1, 2)
	Particles.burst(z.get_parent(), _plate_center(best), "snow", Vector2.UP, 5)
	var m := _main()
	if m != null and not m.has_meta("th_told_ref"):
		m.set_meta("th_told_ref", true)
		z._popup("IT REFREEZES", Color("9adcff"), 15, -96.0 if not _boss() else -170.0)
		var pl := player()
		if pl != null and pl.has_method("_say"):
			pl._say("It freezes over when I stop... keep shooting. Burn it", Color("9adcff"))


func _plate_center(i: int) -> Vector2:
	var c: Vector2 = [Vector2(3, -51), Vector2(1, -34), Vector2(10, -32), Vector2(0, -12)][i]
	return z.global_position + Vector2(c.x * z._dir * z.wf * z.sc, c.y * z.sc)


func on_death() -> void:
	var par: Node = z.get_parent()
	var y0: float = z.global_position.y
	var n := 0
	for i in 4:
		if has_ice(i):
			n += 1
			IceShards.spray(par, _plate_center(i), Vector2(0, -1), 14 if not _boss() else 40, y0, _tint, (0.9 if not _boss() else 2.2))
	# דם קפוא: גושים אדומים-ורודים
	IceShards.spray(par, z.global_position + Vector2(0, -34.0 * z.sc), Vector2(0, -1), int((8 if not _boss() else 30) * Quality.gore()), y0, Color(0.85, 0.25, 0.3), 0.6 * z.sc)
	if n > 0 or _boss():
		Sfx.play("th_shatter", z.global_position, 2.0 if not _boss() else 6.0, 0.1, 2)
		Particles.burst(par, z.global_position + Vector2(0, -30.0 * z.sc), "snow", Vector2.UP, 10 if not _boss() else 30)
	for i in 4:
		lay[i] = 0
	if _boss():
		var cam: Camera2D = z.get_viewport().get_camera_2d()
		if cam != null and cam.has_method("shake"):
			cam.shake(22.0, 1.0)
		var fl := ShatterFlash.new()
		par.add_child(fl)
		fl.global_position = z.global_position + Vector2(0, -80.0 * z.sc * 0.5)
		for b in z.get_tree().get_nodes_in_group("th_blocks"):
			b.shatter()


# ============================================================
#  בוס: THE GLACIER
# ============================================================
func _boss_physics(pl: Node, has: bool, d: Vector2, delta: float) -> void:
	if not has or not _met:
		z.velocity.x = move_toward(z.velocity.x, 0.0, 600.0 * delta)
		return
	_calve_cd -= delta
	match state:
		WALK:
			var want: float = signf(d.x) if absf(d.x) > 8.0 else z._dir
			z._dir = want
			var v := 0.0
			if absf(d.x) > 150.0:
				v = z._dir * float(z.chase_speed) * (1.35 if float(z.hp) < float(z.max_hp) * 0.5 else 1.0)
			z.velocity.x = move_toward(z.velocity.x, v, 400.0 * delta)
			z._walk_phase += delta * absf(z.velocity.x) / 22.0
			if absf(z.velocity.x) > 10.0 and _step <= 0.0:
				_step = 0.62
				Sfx.play("th_step", z.global_position, 0.0, 0.1, 2)
				var cam: Camera2D = z.get_viewport().get_camera_2d()
				if cam != null and cam.has_method("shake") and Art.on_screen(z, z.global_position):
					cam.shake(2.5, 0.12)
			if _cd > 0.0:
				return
			var high: bool = d.y < -60.0   # השחקן על המדף
			if _calve_cd <= 0.0 and float(z.hp) < float(z.max_hp) * 0.7:
				state = ROAR
				_st = ROAR_T
				_calve_cd = CALVE_EVERY
				Sfx.play("th_roar", z.global_position, 4.0, 0.0, 1)
				z._popup("ROAR", Color("9adcff"), 18, -170.0)
			elif absf(d.x) < SMASH_R and not high and z.is_on_floor():
				state = SMASH_W
				_st = SMASH_WIND
				Sfx.play("th_crack", z.global_position, 2.0, 0.1, 2)
			elif absf(d.x) > THROW_R.x or high:
				state = THROW_W
				_st = THROW_WIND
				_throw_n = 2 if float(z.hp) < float(z.max_hp) * 0.5 else 1
				Sfx.play("th_crack", z.global_position, 0.0, 0.1, 2)
		SMASH_W:
			z.velocity.x = move_toward(z.velocity.x, 0.0, 900.0 * delta)
			if _st <= 0.0:
				state = SMASH
				_st = 0.45
				smashes += 1
				_hit_done = false
				Sfx.play("th_slam", z.global_position, 6.0, 0.0, 1)
				var cam: Camera2D = z.get_viewport().get_camera_2d()
				if cam != null and cam.has_method("shake"):
					cam.shake(12.0, 0.4)
				var w := Shockwave.new()
				w.r = SMASH_R + 60.0
				z.get_parent().add_child(w)
				w.global_position = z.global_position + Vector2(z._dir * 30.0 * z.sc, 0)
				IceShards.spray(z.get_parent(), z.global_position + Vector2(z._dir * 30.0 * z.sc, -6.0), Vector2(0, -1), 14, z.global_position.y, _tint, 1.2)
				if has and not _hit_done and absf(d.x) < SMASH_R + 60.0 and absf(d.y) < 50.0 and pl.is_on_floor():
					_hit_done = true
					if pl._roll_t <= 0.0:
						smash_hits += 1
						pl.slow_t = maxf(pl.slow_t, CHILL)
					pl.hurt(SMASH_DMG, Vector2(signf(d.x) * 1.8, -0.8))
		SMASH:
			if _st <= 0.0:
				state = WALK
				_cd = randf_range(BOSS_CD.x, BOSS_CD.y)
		THROW_W:
			z.velocity.x = move_toward(z.velocity.x, 0.0, 900.0 * delta)
			z._dir = signf(d.x) if absf(d.x) > 8.0 else z._dir
			if _st <= 0.0:
				_throw(pl)
				_throw_n -= 1
				if _throw_n > 0:
					_st = 0.45
				else:
					state = THROW
					_st = 0.5
		THROW:
			if _st <= 0.0:
				state = WALK
				_cd = randf_range(BOSS_CD.x, BOSS_CD.y)
		ROAR:
			z.velocity.x = move_toward(z.velocity.x, 0.0, 900.0 * delta)
			if _st <= ROAR_T - 0.5 and _st + delta > ROAR_T - 0.5:   # רוקע: המדף הקרוב אליך מתנתק
				calves += 1
				var stage: Node = z.get_parent().get("_stage") if z.get_parent() != null else null
				if stage != null and stage.has_method("calve_near"):
					stage.calve_near(pl.global_position.x, 0.8)
				var cam: Camera2D = z.get_viewport().get_camera_2d()
				if cam != null and cam.has_method("shake"):
					cam.shake(10.0, 0.6)
			if _st <= 0.0:
				state = WALK
				_cd = 0.6


func _hand_pos() -> Vector2:
	return z.global_position + Vector2(z._dir * 6.0 * z.wf * z.sc, -78.0 * z.sc)


func _throw(pl: Node) -> void:
	throws += 1
	var b := IceBlock.new()
	b.owner_z = z
	z.get_parent().add_child(b)
	var from := _hand_pos()
	b.global_position = from
	var lead: Vector2 = pl.velocity * 0.35 if pl.is_on_floor() else Vector2.ZERO
	var to: Vector2 = pl.global_position + lead + Vector2(randf_range(-20, 20), -10.0)
	var tt := clampf(absf(to.x - from.x) / 520.0, 0.65, 1.3)
	b.vel = Vector2((to.x - from.x) / tt, (to.y - from.y - 0.5 * IceBlock.G * tt * tt) / tt)
	b.ground_y = pl.global_position.y if absf(pl.global_position.y - z.global_position.y) > 60.0 else z.global_position.y
	Sfx.play("whoosh", from, 2.0, 0.1, 2)


func wants_redraw() -> bool:
	return true


# ============================================================
#  ציור
# ============================================================
const SKIN_F := Color("9fb6c8")
const LIP := Color("2a3a6a")
const FLESH := Color("b86a70")


func draw() -> bool:
	if _boss():
		return _draw_boss()
	begin_draw()
	var t: float = z._time
	var sk := col(z.skin)
	var f: Array = feet(4.0, 2.0)
	var wind := 0.0
	if state == WIND:
		wind = clampf(1.0 - _st / WIND_T, 0.0, 1.0)
	elif state == STRIKE:
		wind = -1.0
	var lean := 2.0 if state == STRIKE else (-1.5 * wind if wind > 0.0 else 0.0)
	var hip := Vector2(0, -24)
	var sh := Vector2(1.5 + lean, -44)
	var head := sh + Vector2(1.8 + lean * 0.3, -7.5)
	# רגליים: סרבל גומי + מגפיים
	var pa := col(_pants)
	z._leg(hip + Vector2(-2, 0), f[1], col(Art.shade(_pants, 0.25)), sk, col(z.shoe))
	z._leg(hip + Vector2(2, 0), f[0], pa, sk, col(z.shoe))
	# יד אחורית
	var hb := sh + Vector2(-4.0 + sin(t * 1.4), 14.0)
	if wind > 0.0:
		hb = sh + Vector2(-2.0, -14.0 * wind)
	elif state == STRIKE:
		hb = sh + Vector2(13.0, 12.0)
	_arm(sh + Vector2(-3, 1), hb, true)
	# גוף: סוודר צמר עם סרבל (כתפיות)
	var torso := PackedVector2Array([sh + Vector2(-7, -1), sh + Vector2(7, 0), hip + Vector2(7, 0), hip + Vector2(-7, -1)])
	Art.fill_shaded(z, torso, col(_sweater), 0.12, 0.32)
	for q in 3:   # טקסטורת סריגה
		DrawBatch.line(z, sh.lerp(hip, 0.2 + float(q) * 0.25) + Vector2(-6, 0), sh.lerp(hip, 0.2 + float(q) * 0.25) + Vector2(6, 0), col(Art.shade(_sweater, 0.3)), 0.8)
	DrawBatch.colored_polygon(z, PackedVector2Array([hip + Vector2(-6, -9), hip + Vector2(6, -9), hip + Vector2(7, 0), hip + Vector2(-7, -1)]), pa)
	DrawBatch.line(z, hip + Vector2(-4, -9), sh + Vector2(-3, 2), col(Art.shade(_pants, 0.15)), 1.6)
	DrawBatch.line(z, hip + Vector2(4, -9), sh + Vector2(4, 2), col(Art.shade(_pants, 0.15)), 1.6)
	if _fish:   # דג קפוא תלוי בחגורה
		var fp := hip + Vector2(-6, -4)
		Art.oval(z, fp + Vector2(0, 5), 2.2, 5.0, col(Color("8aa0b0")), 0.15, Art.OUTLINE, 0.8)
		DrawBatch.colored_polygon(z, PackedVector2Array([fp + Vector2(0, 10), fp + Vector2(-2, 13), fp + Vector2(2, 13)]), col(Color("6a8090")))
	# ראש: עור כחלחל, שפתיים כחולות, כפור בגבות ובזקן, כובע צמר
	_head(head, sk)
	# יד קדמית: האגרוף הקפוא
	var hf := sh + Vector2(6.0 + sin(t * 1.6) * 1.0, 14.0)
	if _guard_k > 0.01:
		hf = hf.lerp(head + Vector2(5.0, 2.0), _guard_k)
	if wind > 0.0:
		hf = sh + Vector2(2.0, -16.0 * wind)
	elif state == STRIKE:
		hf = sh + Vector2(16.0, 12.0)
	var el := _arm(sh + Vector2(4, 1), hf, false)
	# ===== קליפת הקרח =====
	_draw_plate(LEGS, PackedVector2Array([hip + Vector2(-8, 4), hip + Vector2(8, 4), f[0] + Vector2(6, -2), f[0] + Vector2(4, -10), f[1] + Vector2(-5, -10), f[1] + Vector2(-6, -2)]))
	_draw_plate(CHEST, PackedVector2Array([sh + Vector2(-10, -3), sh + Vector2(-2, -6), sh + Vector2(9, -3), hip + Vector2(10, 2), hip + Vector2(2, 5), hip + Vector2(-10, 1)]))
	_draw_plate(HEAD, PackedVector2Array([head + Vector2(-9, -6), head + Vector2(-4, -11), head + Vector2(6, -11), head + Vector2(10, -4), head + Vector2(9, 6), head + Vector2(1, 9), head + Vector2(-8, 5)]))
	var ad := (hf - el).normalized()
	var an := Vector2(-ad.y, ad.x)
	_draw_plate(ARM, PackedVector2Array([el - an * 4.0 - ad * 2.0, el + an * 4.0 - ad * 2.0, hf + an * 5.5 + ad * 3.0, hf + ad * 6.0, hf - an * 5.5 + ad * 3.0]))
	if state == STRIKE and not z.dead:
		for q in 3:
			DrawBatch.line(z, hf + Vector2(-6.0 + float(q) * 6.0, 4.0), hf + Vector2(-9.0 + float(q) * 9.0, 10.0), Color(1, 1, 1, 0.6), 1.2)
	# נשימה קרה
	var bp := fmod(_breath, 2.6)
	if bp < 1.0 and not z.dead:
		Art.oval(z, head + Vector2(7.0 + bp * 6.0, 3.0 - bp * 3.0), 1.5 + bp * 3.0, 1.0 + bp * 2.0, Color(1, 1, 1, 0.45 * (1.0 - bp)), 0.0, Art.NONE)
	if _freeze_fx > 0.0:
		Art.glow(z, Vector2(0, -32), 26.0, Color(0.6, 0.9, 1.0, 0.45 * _freeze_fx))
	end_draw()
	return true


func _arm(s: Vector2, h: Vector2, back: bool) -> Vector2:
	var c := col(Art.shade(_sweater, 0.25 if back else 0.0))
	var el := Art.joint(s, h, 11.0, 11.0, -1.0 if back else 1.0)
	Art.limb(z, PackedVector2Array([s, el, el.lerp(h, 0.6)]), 3.4, c)
	Art.limb(z, PackedVector2Array([el.lerp(h, 0.55), h]), 2.4, col(Art.shade(z.skin, 0.2 if back else 0.0)))
	DrawBatch.circle(z, h, 2.4, col(Art.shade(z.skin, 0.25 if back else 0.05)))
	return el


func _head(c: Vector2, sk: Color) -> void:
	Art.oval_shaded(z, c, 5.4, 6.0, sk, 0.0)
	# לחיים שקועות, כפור
	Art.oval(z, c + Vector2(2.8, 1.5), 1.8, 1.2, Color(0.3, 0.4, 0.6, 0.4), 0.0, Art.NONE)
	if not z.dead:
		# עיניים: לבן חלבי עם אישון אדום
		DrawBatch.colored_polygon(z, Art.ellipse(c + Vector2(2.6, -1.2), 1.7, 1.3, 0.0, 8), col(Color("e8eef2")))
		DrawBatch.circle(z, c + Vector2(2.9, -1.2), 0.7, Color(0.9, 0.15, 0.15))
		DrawBatch.colored_polygon(z, Art.ellipse(c + Vector2(-1.4, -1.2), 1.1, 1.0, 0.0, 8), col(Color("c8d4dc")))
		Art.glow(z, c + Vector2(2.9, -1.2), 3.0, Color(1.0, 0.3, 0.25, 0.35))
	# פה: שפתיים כחולות, שיניים
	DrawBatch.line(z, c + Vector2(1.2, 3.0), c + Vector2(5.0, 2.6), col(LIP), 1.4)
	DrawBatch.line(z, c + Vector2(1.8, 3.0), c + Vector2(4.4, 2.8), col(Color("d8d4c0")), 0.6)
	# זקן כפור + נטיפים מהסנטר
	DrawBatch.colored_polygon(z, PackedVector2Array([c + Vector2(-1, 3), c + Vector2(5, 3.5), c + Vector2(3, 6.5), c + Vector2(0, 6)]), col(Color(0.92, 0.96, 1.0, 0.85)))
	for q in 3:
		DrawBatch.colored_polygon(z, PackedVector2Array([c + Vector2(0.5 + q * 1.5, 6), c + Vector2(1.5 + q * 1.5, 6), c + Vector2(1.0 + q * 1.5, 8.5 + float(q % 2))]), col(Color("e6f4fb")))
	if _has_beanie:
		Art.fill(z, PackedVector2Array([c + Vector2(-6, -1), c + Vector2(-5, -6), c + Vector2(0, -8), c + Vector2(5, -6), c + Vector2(6, -2)]), col(_beanie), Art.OUTLINE, 0.9)
		DrawBatch.line(z, c + Vector2(-6, -1.5), c + Vector2(6, -2), col(Art.shade(_beanie, 0.3)), 1.4)
		DrawBatch.line(z, c + Vector2(-5, -5.5), c + Vector2(5, -5.5), Color(1, 1, 1, 0.5), 0.8)   # כפור
	else:
		for q in 4:   # שיער קפוא בקוצים
			DrawBatch.line(z, c + Vector2(-4.0 + float(q) * 2.6, -5.0), c + Vector2(-5.0 + float(q) * 2.8, -8.5), col(Color("d8e4ec")), 1.2)


# לוח קרח: שקוף (הגוף נראה), שוליים בהירים, ברק, סדקים לפי הנזק
# קליפת קרח קמורה (רגליים שמתחלפות בהליכה לא יוצרות מצולע שחוצה את עצמו)
static func _hull(pts: PackedVector2Array) -> PackedVector2Array:
	var h := Geometry2D.convex_hull(pts)
	if h.size() > 1 and h[0] == h[h.size() - 1]:
		h.remove_at(h.size() - 1)
	return h


func _draw_plate(i: int, pts: PackedVector2Array) -> void:
	if lay[i] <= 0:
		if not z.dead and i != ARM:   # שאריות קרח קטנות + בשר חשוף
			var c := Vector2.ZERO
			for p in pts:
				c += p
			c /= float(pts.size())
			Art.oval(z, c + Vector2(1, 0), 2.0, 1.4, Color(0.75, 0.2, 0.25, 0.7), 0.0, Art.NONE)
			DrawBatch.line(z, pts[0], pts[0].lerp(c, 0.25), Color(0.85, 0.95, 1.0, 0.7), 1.2)
		return
	pts = _hull(pts)
	if pts.size() < 3:
		return
	var full: float = float(_layer_hp(i))
	var dmg := clampf(1.0 - float(ice[i]) / full, 0.0, 1.0)
	var thick: float = float(lay[i]) / float(LAYERS[i] if not _boss() else BOSS_LAYERS[i])
	var a := 0.15 + 0.13 * thick
	if _thin[i]:
		a = 0.12
	var tc := Color(_tint.r, _tint.g, _tint.b, a)
	if z._flash > 0.0:
		tc = Color(1, 1, 1, 0.75)
	# שכבה חיצונית מעט גדולה כשיש שתיים
	if lay[i] >= 2:
		var c2 := Vector2.ZERO
		for p in pts:
			c2 += p
		c2 /= float(pts.size())
		var big := PackedVector2Array()
		for p in pts:
			big.append(c2 + (p - c2) * 1.13)
		DrawBatch.colored_polygon(z, big, Color(tc.r, tc.g, tc.b, a * 0.55))
	DrawBatch.colored_polygon(z, pts, tc)
	var edge := PackedVector2Array(pts)
	edge.append(pts[0])
	DrawBatch.polyline(z, edge, Color(0.55, 0.85, 1.0, 0.9), 2.2)
	DrawBatch.polyline(z, edge, Color(0.95, 1.0, 1.0, 0.95), 1.0)
	DrawBatch.line(z, pts[0].lerp(pts[1], 0.15), pts[1].lerp(pts[2], 0.6), Color(1, 1, 1, 0.75), 1.3)   # ברק
	# סדקים: מספר לפי הנזק, צורה קבועה לזומבי
	var n := int(dmg * 5.0 + 0.5)
	if n > 0:
		var c3 := Vector2.ZERO
		for p in pts:
			c3 += p
		c3 /= float(pts.size())
		for q in n:
			var a2 := float((_seed >> (q * 3)) % 628) / 100.0 + float(i)
			var l := 3.0 + float((_seed >> (q * 2)) % 5)
			var p0 := c3 + Vector2.from_angle(a2 * 1.7) * 1.5
			DrawBatch.polyline(z, PackedVector2Array([p0, p0 + Vector2.from_angle(a2) * l * 0.5 + Vector2(0.8, 0), p0 + Vector2.from_angle(a2) * l]), Color(1, 1, 1, 0.9), 0.7)


# ---- THE GLACIER: ענק בתוך גוש קרחון ----
func _draw_boss() -> bool:
	begin_draw()
	var t: float = z._time
	var sk := col(Color("7f98ae"))
	var p: float = z._walk_phase
	var moving: bool = absf(z.velocity.x) > 8.0
	var f0 := Vector2(sin(p) * 5.0 + 4.0, -maxf(0.0, cos(p)) * 3.0) if moving else Vector2(5, 0)
	var f1 := Vector2(sin(p + PI) * 5.0 - 4.0, -maxf(0.0, cos(p + PI)) * 3.0) if moving else Vector2(-5, 0)
	var raise := 0.0
	if state == SMASH_W:
		raise = clampf(1.0 - _st / SMASH_WIND, 0.0, 1.0)
	elif state == THROW_W:
		raise = clampf(1.0 - _st / THROW_WIND, 0.0, 1.0)
	var smash := state == SMASH
	var roar := state == ROAR
	var hip := Vector2(0, -24)
	var sh := Vector2(1, -46) + (Vector2(2, 2) if smash else Vector2.ZERO)
	var head := sh + Vector2(3, -9) + (Vector2(0, -2) if roar else Vector2.ZERO)
	# רגליים (בתוך גושי קרח)
	z._leg(hip + Vector2(-4, 0), f1, col(Color("2a2e36")), sk, col(Color("1a1a1e")))
	z._leg(hip + Vector2(4, 0), f0, col(Color("343a44")), sk, col(Color("1a1a1e")))
	# גוף ענק: שרידי מעיל קרוע
	var torso := PackedVector2Array([sh + Vector2(-11, -2), sh + Vector2(11, 0), hip + Vector2(10, 0), hip + Vector2(-10, -1)])
	Art.fill_shaded(z, torso, col(Color("9a3424")), 0.14, 0.36)
	DrawBatch.line(z, sh + Vector2(-2, 2), hip + Vector2(-1, -2), col(Color("1e2630")), 1.2)
	for q in 3:   # צלעות חשופות
		DrawBatch.line(z, sh + Vector2(-6, 6 + q * 4), sh + Vector2(2, 7 + q * 4), col(Color("c8c0b0")), 0.9)
	# ראש
	Art.oval_shaded(z, head, 6.5, 7.5, sk, 0.0)
	if not z.dead:
		Art.oval(z, head + Vector2(3.0, -1.5), 1.8, 1.4, col(Color("e8eef2")), 0.0, Art.NONE)
		DrawBatch.circle(z, head + Vector2(3.3, -1.5), 0.9, Color(0.4, 0.85, 1.0))
		Art.glow(z, head + Vector2(3.3, -1.5), 5.0, Color(0.4, 0.85, 1.0, 0.6))
		Art.oval(z, head + Vector2(-2.0, -1.5), 1.2, 1.1, col(Color("c8d4dc")), 0.0, Art.NONE)
	var jaw := 3.0 if roar or smash else 1.0
	DrawBatch.colored_polygon(z, PackedVector2Array([head + Vector2(0, 3), head + Vector2(6, 2.5), head + Vector2(5.5, 3.0 + jaw), head + Vector2(0.5, 3.0 + jaw)]), col(Color("101828")))
	DrawBatch.line(z, head + Vector2(0.5, 3.2), head + Vector2(5.6, 2.8), col(Color("d8d4c0")), 0.8)
	# ידיים: אלות קרח ענקיות
	var hb := sh + Vector2(-8, 16)
	var hf := sh + Vector2(10, 16)
	if raise > 0.0:
		hb = sh + Vector2(-4, 16).lerp(Vector2(-2, -24), raise)
		hf = sh + Vector2(10, 16).lerp(Vector2(6, -26), raise)
	elif smash:
		hb = sh + Vector2(14, 22)
		hf = sh + Vector2(20, 22)
	elif roar:
		hb = sh + Vector2(-14, -6)
		hf = sh + Vector2(16, -8)
	Art.limb(z, PackedVector2Array([sh + Vector2(-7, 1), Art.joint(sh + Vector2(-7, 1), hb, 12.0, 12.0, -1.0), hb]), 4.0, col(Color("6a8298")))
	# ===== גוש הקרחון =====
	var base_pts := PackedVector2Array([hip + Vector2(-14, 4), hip + Vector2(14, 4), Vector2(14, 0), Vector2(-14, 0)])
	_draw_plate(LEGS, base_pts)
	_draw_plate(CHEST, PackedVector2Array([sh + Vector2(-17, -8), sh + Vector2(-4, -13), sh + Vector2(14, -8), hip + Vector2(16, 4), hip + Vector2(0, 8), hip + Vector2(-16, 4)]))
	_draw_plate(HEAD, PackedVector2Array([head + Vector2(-12, -6), head + Vector2(-8, -16), head + Vector2(-2, -12), head + Vector2(3, -20), head + Vector2(8, -12), head + Vector2(13, -15), head + Vector2(13, 4), head + Vector2(2, 11), head + Vector2(-11, 7)]))
	if has_ice(HEAD) and not z.dead:   # כתר נטיפים
		for q in 3:
			var cx := head + Vector2(-6.0 + float(q) * 7.0, -16.0 - float(q % 2) * 4.0)
			DrawBatch.colored_polygon(z, PackedVector2Array([cx + Vector2(-2, 4), cx + Vector2(2, 4), cx + Vector2(0, -5)]), Color(0.9, 0.97, 1.0, 0.8))
	# יד קדמית + אלת קרח (ARM)
	var el := Art.joint(sh + Vector2(6, 1), hf, 12.0, 12.0, 1.0)
	Art.limb(z, PackedVector2Array([sh + Vector2(6, 1), el, hf]), 4.4, col(Color("7a92a8")))
	var ad := (hf - el).normalized()
	var an := Vector2(-ad.y, ad.x)
	_draw_plate(ARM, PackedVector2Array([el - an * 6.0, el + an * 6.0, hf + an * 9.0 + ad * 4.0, hf + ad * 11.0, hf - an * 9.0 + ad * 4.0]))
	if not has_ice(ARM):
		Art.disc(z, hf, 3.6, col(sk), Art.OUTLINE, 1.0)
	# THROW: גוש קרח מעל הראש
	if state == THROW_W and raise > 0.3:
		var bc := head + Vector2(2, -24)
		var blk := PackedVector2Array([bc + Vector2(-10, -7), bc + Vector2(9, -9), bc + Vector2(11, 7), bc + Vector2(-9, 8)])
		Art.fill(z, blk, col(Color("b8e0f4")), Art.OUTLINE, 1.0)
		DrawBatch.line(z, blk[0], blk[1], Color(1, 1, 1, 0.9), 1.2)
	if smash and not z.dead:
		for q in 5:
			DrawBatch.line(z, Vector2(10.0 + float(q) * 6.0, -1.0), Vector2(14.0 + float(q) * 9.0, -8.0 - float(q % 2) * 6.0), Color(0.85, 0.95, 1.0, 0.8), 1.4)
	if roar and not z.dead:
		for q in 3:
			var k := fmod(t * 2.0 + float(q) / 3.0, 1.0)
			DrawBatch.arc(z, head + Vector2(8, 3), 6.0 + k * 22.0, -0.8, 0.8, 8, Color(0.8, 0.95, 1.0, 0.5 * (1.0 - k)), 1.2)
	# אדי קור
	if not z.dead:
		var bp := fmod(_breath, 2.0)
		if bp < 1.0:
			Art.oval(z, head + Vector2(10.0 + bp * 10.0, 3.0 - bp * 4.0), 2.0 + bp * 5.0, 1.5 + bp * 3.0, Color(1, 1, 1, 0.4 * (1.0 - bp)), 0.0, Art.NONE)
	if _freeze_fx > 0.0:
		Art.glow(z, Vector2(0, -40), 40.0, Color(0.6, 0.9, 1.0, 0.5 * _freeze_fx))
	end_draw()
	return true


# ============================================================
#  רסיסי קרח: כל הרסיסים בצומת אחד, ציור אחד (משולשים)
# ============================================================
class IceShards extends Node2D:
	const MAX := 260
	var _s := []                  # [pos, vel, rot, spin, size, life, ground_y, col]

	static func spray(parent: Node, pos: Vector2, dir: Vector2, n: int, ground_y: float, c: Color, k := 1.0) -> void:
		if parent == null or n <= 0:
			return
		var node: Node = parent.get_tree().get_first_node_in_group("ice_shards")
		if node == null:
			node = IceShards.new()
			parent.add_child(node)
		node.add(pos, dir, Quality.scaled(n, Quality.gore()), ground_y, c, k)

	func _ready() -> void:
		add_to_group("ice_shards")
		z_index = 8

	func add(pos: Vector2, dir: Vector2, n: int, ground_y: float, c: Color, k: float) -> void:
		for i in n:
			if _s.size() >= MAX:
				_s.pop_front()
			var a := dir.angle() + randf_range(-1.1, 1.1)
			var sp := randf_range(120.0, 340.0) * (0.7 + 0.3 * k)
			var cc := Color(c.r, c.g, c.b, 0.9).lerp(Color(1, 1, 1, 0.95), randf() * 0.5)
			_s.append([pos + Vector2(randf_range(-4, 4), randf_range(-4, 4)), Vector2.from_angle(a) * sp + Vector2(0, -80.0), randf() * TAU, randf_range(-14.0, 14.0), randf_range(1.6, 3.8) * clampf(k, 0.5, 2.5), randf_range(1.2, 2.2), ground_y, cc])

	func _process(delta: float) -> void:
		if _s.is_empty():
			return
		var keep := []
		for s in _s:
			s[5] -= delta
			if s[5] <= 0.0:
				continue
			var v: Vector2 = s[1]
			v.y += 1300.0 * delta
			var p: Vector2 = s[0] + v * delta
			if p.y >= s[6] - 1.0 and v.y > 0.0:
				p.y = s[6] - 1.0
				v = Vector2(v.x * 0.5, -v.y * 0.3)
				s[3] = float(s[3]) * 0.5
				if absf(v.y) < 40.0:
					v = Vector2(v.x * 0.6, 0.0)
			s[0] = p
			s[1] = v
			s[2] = float(s[2]) + float(s[3]) * delta
			keep.append(s)
		_s = keep
		queue_redraw()

	func _draw() -> void:
		if _s.is_empty():
			return
		var pts := PackedVector2Array()
		var cols := PackedColorArray()
		for s in _s:
			var p: Vector2 = s[0]
			var r: float = s[4]
			var a: float = s[2]
			var c: Color = s[7]
			c.a *= clampf(float(s[5]) / 0.4, 0.0, 1.0)
			var p1 := p + Vector2.from_angle(a) * r * 1.4
			var p2 := p + Vector2.from_angle(a + 2.3) * r
			var p3 := p + Vector2.from_angle(a + 3.9) * r * 0.8
			pts.append_array([p1, p2, p3])
			cols.append_array([c, c.darkened(0.25), c])
		RenderingServer.canvas_item_add_triangle_array(get_canvas_item(), PackedInt32Array(), pts, cols)


# ---- גוש קרח שהבוס זורק: אפשר לירות בו באוויר ----
class IceBlock extends Node2D:
	const G := 1100.0
	const Sfx := preload("res://sfx.gd")
	const Particles := preload("res://particles.gd")
	var vel := Vector2.ZERO
	var ground_y := 630.0
	var owner_z: Node = null
	var _rot := 0.0
	var _body: StaticBody2D = null
	var _done := false
	var _t := 0.0

	class Hit extends StaticBody2D:
		var b = null
		func hit_by_bullet(_p: Vector2, _n: Vector2, _d: Vector2) -> void:
			if b != null:
				b.shot()

	func _ready() -> void:
		z_index = 7
		add_to_group("th_blocks")
		add_to_group("blastable")
		var h := Hit.new()
		h.b = self
		h.collision_layer = 4
		h.collision_mask = 0
		var cs := CollisionShape2D.new()
		var sh := RectangleShape2D.new()
		sh.size = Vector2(34, 30)
		cs.shape = sh
		h.add_child(cs)
		add_child(h)
		_body = h

	func blast_rect() -> Rect2:
		return Rect2(global_position - Vector2(17, 15), Vector2(34, 30))

	func hit_by_blast(_c: Vector2, _r: float) -> void:
		shot()

	func shot() -> void:
		if _done:
			return
		if owner_z != null and is_instance_valid(owner_z) and owner_z.type_mod != null:
			owner_z.type_mod.blocks_shot += 1
		Sfx.play("th_crack", global_position, 2.0, 0.1, 2)
		IceShards.spray(get_parent(), global_position, Vector2.UP, 14, ground_y, Color(0.75, 0.9, 1.0), 1.0)
		_done = true
		queue_free()

	func shatter() -> void:
		shot()

	func _physics_process(delta: float) -> void:
		if _done:
			return
		_t += delta
		vel.y += G * delta
		global_position += vel * delta
		_rot += delta * 4.0 * signf(vel.x)
		var pl := get_tree().get_first_node_in_group("player")
		if pl != null and not pl.dead and Rect2(global_position - Vector2(16, 14), Vector2(32, 28)).intersects(pl.body_rect()):
			_impact(pl, true)
			return
		if global_position.y >= ground_y - 8.0 and vel.y > 0.0 or _t > 4.0:
			_impact(pl, false)
			return
		queue_redraw()

	func _impact(pl: Node, direct: bool) -> void:
		_done = true
		var hit: bool = direct or (pl != null and not pl.dead and pl.global_position.distance_to(global_position) < 64.0)
		if hit and pl != null:
			if pl._roll_t <= 0.0 and owner_z != null and is_instance_valid(owner_z) and owner_z.type_mod != null:
				owner_z.type_mod.throw_hits += 1
			pl.hurt(THROW_DMG, Vector2(signf(vel.x) * 1.4, -0.5))
		Sfx.play("th_shatter", global_position, 0.0, 0.1, 2)
		IceShards.spray(get_parent(), global_position, Vector2.UP, 18, ground_y, Color(0.75, 0.9, 1.0), 1.2)
		Particles.burst(get_parent(), global_position, "snow", Vector2.UP, 8)
		for z in get_tree().get_nodes_in_group("zombies"):   # גם זומבים מתחת נפגעים
			if not z.dead and not z.is_boss() and z.global_position.distance_to(global_position + Vector2(0, 20)) < 60.0:
				z.take_damage(30, z.global_position + Vector2(0, -30), Vector2.UP, true, {"source": "th_block_hit", "fixed": 30})
		queue_free()

	func _draw() -> void:
		DrawBatch.set_transform(self, Vector2.ZERO, _rot, Vector2.ONE)
		var blk := PackedVector2Array([Vector2(-16, -12), Vector2(14, -14), Vector2(17, 11), Vector2(-14, 13)])
		DrawBatch.colored_polygon(self, blk, Color("b8e0f4"))
		DrawBatch.colored_polygon(self, PackedVector2Array([Vector2(-16, -12), Vector2(14, -14), Vector2(8, -4), Vector2(-10, -3)]), Color("e2f4fc"))
		var e := PackedVector2Array(blk)
		e.append(blk[0])
		DrawBatch.polyline(self, e, Color("4a8ab8"), 1.6)
		DrawBatch.line(self, Vector2(-6, -6), Vector2(4, 6), Color(1, 1, 1, 0.7), 1.2)
		DrawBatch.set_transform_matrix(self, Transform2D.IDENTITY)
		# צל על הרצפה (איפה ייפול)
		var gy := ground_y - global_position.y
		if gy > 20.0:
			var k := clampf(1.0 - gy / 500.0, 0.2, 1.0)
			DrawBatch.colored_polygon(self, Art.ellipse(Vector2(vel.x * 0.05, gy - 1.0), 18.0 * k, 3.5 * k, 0.0, 12), Color(0.05, 0.15, 0.3, 0.35 * k))


# ---- גל הלם של SMASH: סדקים לאורך הקרח ----
class Shockwave extends Node2D:
	var r := 240.0
	var _t := 0.0

	func _ready() -> void:
		z_index = 2

	func _process(delta: float) -> void:
		_t += delta
		if _t > 0.6:
			queue_free()
			return
		queue_redraw()

	func _draw() -> void:
		var k := _t / 0.6
		var rr := r * minf(1.0, k * 2.0)
		for s in [-1.0, 1.0]:
			var pts := PackedVector2Array([Vector2.ZERO])
			for q in 6:
				pts.append(Vector2(s * rr * float(q + 1) / 6.0, -2.0 + (float(q % 2) * 4.0 - 2.0)))
			DrawBatch.polyline(self, pts, Color(0.9, 0.98, 1.0, 1.0 - k), 2.4)
			for q in 4:   # קוצי קרח קטנים שמזדקרים
				var x: float = s * rr * (0.25 + float(q) * 0.22)
				var h := 14.0 * (1.0 - k) * (1.0 - float(q) * 0.15)
				DrawBatch.colored_polygon(self, PackedVector2Array([Vector2(x - 5, 0), Vector2(x + 5, 0), Vector2(x + s * 2.0, -h)]), Color(0.8, 0.94, 1.0, 1.0 - k))


# ---- הבזק לבן כשהבוס מתנפץ ----
class ShatterFlash extends Node2D:
	var _t := 0.0

	func _ready() -> void:
		z_index = 9

	func _process(delta: float) -> void:
		_t += delta
		if _t > 0.9:
			queue_free()
			return
		queue_redraw()

	func _draw() -> void:
		var k := _t / 0.9
		Art.glow(self, Vector2.ZERO, 60.0 + k * 220.0, Color(0.85, 0.95, 1.0, 0.7 * (1.0 - k)))
		for q in 10:
			var a := float(q) * TAU / 10.0
			DrawBatch.line(self, Vector2.from_angle(a) * (20.0 + k * 90.0), Vector2.from_angle(a) * (40.0 + k * 200.0), Color(1, 1, 1, 0.6 * (1.0 - k)), 3.0)
