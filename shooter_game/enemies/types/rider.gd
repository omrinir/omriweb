extends "res://enemies/zombie_type.gd"
# ============================================================
#  RIDER (שלב 51, "THE RANCH") - גאוצ'ו מת על סוס מת. כובע רחב שוליים, פונצ'ו מאובק, בומבאצ'ה, חגורת מטבעות,
#  פאקון (סכין גאוצ'ו ארוכה) ביד. הסוס: עור אפור-חום רקוב, צלעות חשופות, רעמה קרועה, גולגולת עם עיניים בוערות.
#  "THEY LEARNED TO HERD".
#    TROT   - רוכב לכיוונך. קרוב מדי? מתרחק כדי לקחת תנופה. על מכשול (חבילות חציר) - הסוס קופץ מעליו.
#             אתה על במה / ממגורה - הסוס לא מטפס: מסתובב מתחת ומחכה.
#    WIND   - אתה באותו גובה ובטווח: הסוס רוקע ומצהל, הרוכב מרים את הפאקון (WIND_T) - אזהרה!
#    CHARGE - דוהר דרכך (CHARGE_V) ועוד OVERSHOOT אחריך. הסוס דורס (TRAMPLE_DMG), הפאקון חותך מי שעומד לידו (SLASH_DMG).
#             נכנס בקיר / מכשול -> STUMBLE (מועד, פגיע x STUMBLE_MULT). קפיצה מעליו / גלגול = עוברים בשלום.
#    TURN   - בולם, מסתובב, וחוזר.
#  הסוס: פגיעה בסוס (גובה הסוס) יורדת מ-horse_hp, לא מהרוכב. הסוס מת -> הגופה נשארת, הרוכב עף ונלחם ברגל (חיים נפרדים).
#  "THEY LEARN": קפצת מעל ההסתערות (JUMP_LEARN) -> בהסתערות הבאה הוא נעצר מולך ומזדקף (REAR) - הפרסות מכות גבוה
#                (תופס קופצים), ורק אז ממשיך להסתער. נגד: להתגלגל דרכו / להתרחק.
#  בוס: EL PATRON - ענק על סוס משוריין (שריון = HORSE_ARMOR על קליעים, פיצוצים פוגעים מלא).
#       LASSO - מסובב לאסו (LASSO_WIND) וזורק: תפס -> גורר אותך אליו (DRAG_V) ישר לפרסות. לירות בחבל = חותך.
#       CALL  - שורק לרוכבים (CALL_AT - כשהחיים יורדים). STAMPEDE - מתחת לחצי: מסתער עם עדר שוורים מתים לצידו.
#  לשנות: HORSE_HP, WIND_T, CHARGE_V, CHARGE_R, OVERSHOOT, TRAMPLE_DMG, SLASH_DMG, REAR_T, JUMP_LEARN, CD,
#         HORSE_ARMOR, RIDER_GUARD, LASSO_*, DRAG_*, CALL_AT, STAMPEDE_N.
# ============================================================

const Decor := preload("res://effects/s51_decor.gd")

const SOUNDS := {
	"rd_neigh": {"drive": 1.6, "layers": [["V", 520, 380, 0.0, 0.9, 0.04, 2.6, 0.9, 1.0, 0.18, 0, [700, 1800, 18]], ["N", 0, 0, 0.0, 0.5, 0.02, 4.0, 0.3, 0.5, 0]]},
	"rd_hoof": [["N", 0, 0, 0.0, 0.08, 0.0, 40.0, 0.7, 0.25, 0], ["S", 120, 70, 0.0, 0.08, 0.0, 35.0, 0.5, 1.0, 0]],
	"rd_slash": [["N", 0, 0, 0.0, 0.18, 0.0, 16.0, 0.6, 0.8, 0], ["S", 2600, 900, 0.0, 0.16, 0.0, 18.0, 0.18, 1.0, 0]],
	"rd_whistle": [["S", 1500, 2400, 0.0, 0.35, 0.02, 3.0, 0.4, 1.0, 0], ["S", 2400, 1600, 0.35, 0.4, 0.02, 3.0, 0.4, 1.0, 0]],
	"rd_lasso": [["N", 0, 0, 0.0, 0.3, 0.05, 8.0, 0.5, 0.6, 0, 0.4]],
}

const HORSE_HP := 80
const WIND_T := 0.7
const TROT_V := 120.0
const CHARGE_V := 540.0
const CHARGE_T := 2.4
const CHARGE_R := Vector2(170.0, 620.0)   # טווח שממנו הוא מסתער
const OVERSHOOT := 260.0
const TRAMPLE_DMG := 2
const SLASH_DMG := 1
const STUMBLE_T := 1.2
const STUMBLE_MULT := 1.5
const TURN_T := 0.55
const REAR_T := 0.8
const REAR_DIST := 80.0
const REAR_DMG := 2
const JUMP_LEARN := 1
const CD := Vector2(1.4, 2.4)
const THROWN_T := 0.9
# בוס
const BOSS_HORSE_HP := 300
const HORSE_ARMOR := 0.55
const RIDER_GUARD := 0.5        # בוס רכוב: נזק לרוכב עצמו
const LASSO_R := Vector2(240.0, 640.0)
const LASSO_WIND := 0.85
const LASSO_V := 950.0
const DRAG_V := 360.0
const DRAG_T := 1.6
const LASSO_CD := 6.0
const CALL_AT := [0.75, 0.45]
const CALL_N := 2
const STAMPEDE_N := 3

enum { TROT, WIND, CHARGE, REAR, TURN, STUMBLE, LASSO, THROWN }
var state := TROT
var mounted := true
var horse_hp := HORSE_HP
var horse_max := HORSE_HP
# לבדיקות
var charges := 0
var tramples := 0
var slashes := 0
var rears := 0
var rear_hits := 0
var jumps_seen := 0
var stumbles := 0
var unhorsed := 0
var lassos := 0
var drags := 0
var cuts := 0
var calls := 0
var stampedes := 0
var horse_hits := 0
var learned := 0
var corpse: Node = null
var _st := 0.0
var _cd := 1.0
var _ct := 0.0
var _side := 1.0
var _end_x := 0.0
var _hit := false            # כבר פגע בהסתערות הזאת
var _passed := false
var _reared := false
var _struck := false
var _ph := 0.0               # שלב הדהירה
var _hoof := 0.0
var _swing := 0.0            # אנימציית חיתוך
var _pass := false           # (העברת פגיעה לרוכב עצמו)
var _lasso_cd := 3.0
var _lasso: Node = null
var _called := 0
var _patrol := 0.0
var _foot_sc := 1.0


func _boss() -> bool:
	return z != null and float(z.chase_range) > 600.0


func stats() -> Dictionary:
	if _boss():
		return {"name": "RIDER", "hp": 260, "walk": 50.0, "chase": 96.0, "damage": 2, "bite_delay": 0.8, "scale": 2.0, "width": 1.0,
			"duck": 0.0, "cover": 0.0, "skin": Color("8a8a74"), "shirt": Color("2a2a30"), "pants": Color("d8d0bc"), "shoe": Color("1e140c"),
			"points": 1500, "boss": true, "boss_name": "EL PATRON - SHOOT THE HORSE", "ragdoll": false}
	return {"name": "RIDER", "hp": 70, "walk": 45.0, "chase": 92.0, "damage": 1, "bite_delay": 0.75, "scale": 1.25, "width": 1.0,
		"duck": 0.1, "cover": 0.0, "skin": Color("8e9a78"), "shirt": Color("8a5a34"), "pants": Color("d6ccb4"), "shoe": Color("2a1e14"),
		"points": 450, "ragdoll": false}


func brain_overrides() -> Dictionary:
	return {"aggression": 0.75}


func setup() -> void:
	horse_max = BOSS_HORSE_HP if _boss() else HORSE_HP
	horse_hp = horse_max
	_foot_sc = z.sc * (0.85 if _boss() else 0.8)
	_resize()
	_cd = randf_range(0.6, 1.4)


# אזור פגיעה: רכוב = רחב וגבוה (סוס + רוכב). ברגל = רגיל
func _resize() -> void:
	var r := z._shape.shape as RectangleShape2D
	if mounted:
		r.size = Vector2(66.0 * z.sc, 76.0 * z.sc)
		z._shape.position = Vector2(0.0, -38.0 * z.sc)
	else:
		r.size = Vector2(38.0 * z.wf, 66.0 * z.sc)
		z._shape.position = Vector2(0.0, -33.0 * z.sc)


func can_bite() -> bool:
	return not mounted and state != THROWN


func on_bite(_pl: Node) -> void:
	_swing = 0.3
	Sfx.play("rd_slash", z.global_position, -2.0, 0.1, 2)


func damage_mult(_zone: String, _src: Dictionary) -> float:
	var m := STUMBLE_MULT if state == STUMBLE else 1.0
	if _pass and _boss():   # EL PATRON על הסוס: מוסתר מאחורי הצוואר המשוריין
		m *= RIDER_GUARD
	return m


# רכוב: מה שפוגע בגובה הסוס - יורד מהסוס. מה שפוגע ברוכב - עובר אליו (ראש / גוף לפי הגובה האמיתי שלו על האוכף)
func on_damage(amount: int, hit_pos: Vector2, dir: Vector2, src: Dictionary) -> bool:
	if _pass or not mounted:
		return true
	var source := str(src.get("source", "bullet"))
	var ly: float = (hit_pos.y - z.global_position.y) / z.sc
	var explosive := not (source == "bullet" or source == "melee" or source == "taser")
	if ly > -36.0 or explosive:   # הסוס
		var dmg := hit_damage(amount, Vector2(hit_pos.x, z.global_position.y - 30.0 * z.sc), src)
		if _boss() and not explosive and not src.has("god"):
			dmg = maxi(1, int(round(float(dmg) * HORSE_ARMOR)))
			if randf() < 0.3:
				Sfx.play("metal_ping", hit_pos, -4.0, 0.15, 3)
		dmg = maxi(0, int(round(float(dmg) * damage_mult("body", src))))
		horse_hp -= dmg
		horse_hits += 1
		z._flash = 0.1
		z._damage_number(dmg, "body")
		Particles.burst(z.get_parent(), hit_pos, "hit", dir if dir != Vector2.ZERO else Vector2.UP, 8)
		Game.on_zombie_hit({"source": source, "zone": "horse"})
		if horse_hp <= 0:
			_unhorse(dir)
		return explosive   # פיצוץ / אש פוגעים גם ברוכב
	# הרוכב: מתרגמים את הגובה לגובה "רגיל" כדי שראש = ראש וגוף = גוף
	var fake := Vector2(hit_pos.x, z.global_position.y + (-46.0 if ly < -57.0 else -32.0) * z.sc)
	_pass = true
	z.take_damage(amount, fake, dir, false, src)
	_pass = false
	return false


# ---- הסוס מת: הגופה נשארת, הרוכב עף ונלחם ברגל ----
func _unhorse(dir: Vector2) -> void:
	if not mounted:
		return
	mounted = false
	unhorsed += 1
	_drop_lasso()
	var hc := HorseCorpse.new()
	hc.dir = z._dir
	hc.s = z.sc
	hc.armored = _boss()
	z.get_parent().add_child(hc)
	hc.global_position = z.global_position
	corpse = hc
	Sfx.play("rd_neigh", z.global_position, 3.0, 0.1, 2, 0.7)
	Particles.burst(z.get_parent(), z.global_position + Vector2(0, -20.0 * z.sc), "smoke", Vector2.UP, 10)
	z.sc = _foot_sc
	_resize()
	state = THROWN
	_st = THROWN_T
	var fl: float = signf(dir.x) if dir.x != 0.0 else -z._dir
	z.velocity = Vector2(fl * 260.0, -420.0)
	z.global_position.y -= 30.0
	z._popup("UNHORSED!" if not _boss() else "EL PATRON ON FOOT!", Color("ffd080"), 16 if not _boss() else 22, -90.0 * z.sc)
	if _boss():
		z.chase_speed *= 1.25


func physics(pl: Node, delta: float) -> bool:
	_cd -= delta
	_st -= delta
	_swing -= delta
	_lasso_cd -= delta
	if z.dead:
		_drop_lasso()
		return false
	var has_pl: bool = pl != null and not pl.dead
	if _boss() and has_pl:
		_boss_extras(pl)
	if state == LASSO:
		return _lasso_state(pl, delta)
	if not mounted:
		if state == THROWN:
			if not z.is_on_floor():
				z.velocity.y += z.gravity * delta
			z.velocity.x = move_toward(z.velocity.x, 0.0, 300.0 * delta)
			z.move_and_slide()
			if _st <= 0.0 and z.is_on_floor():
				state = TROT
				z._alert_t = maxf(z._alert_t, 4.0)
			return true
		if _boss():   # בזירה: תמיד רודף
			z._alert_t = maxf(z._alert_t, 0.5)
		if _boss() and has_pl and _lasso_cd <= 0.0 and _lasso_ok(pl):   # ברגל: עדיין זורק לאסו
			_start_lasso(pl)
			return true
		return false
	_ph += delta * (16.0 if state == CHARGE else (7.0 if absf(z.velocity.x) > 20.0 else 0.0))
	z._walk_phase = _ph
	match state:
		TROT:
			return _trot(pl, has_pl, delta)
		WIND:
			if has_pl:
				var d: Vector2 = pl.global_position - z.global_position
				z._dir = signf(d.x) if absf(d.x) > 4.0 else z._dir
			if Engine.get_physics_frames() % 8 == 0 and Art.on_screen(z, z.global_position):
				Particles.burst(z.get_parent(), z.global_position + Vector2(z._dir * 20.0, -2.0) * z.sc, "smoke", Vector2(-z._dir, -0.4), 2)
			if _st <= 0.0:
				_start_charge(pl)
			return _move(delta, 0.0)
		CHARGE:
			return _charge(pl, has_pl, delta)
		REAR:
			return _rear(pl, has_pl, delta)
		TURN:
			if _st <= 0.0:
				if has_pl:
					var d2: Vector2 = pl.global_position - z.global_position
					z._dir = signf(d2.x) if absf(d2.x) > 4.0 else -z._dir
				state = TROT
			return _move(delta, 0.0, 900.0)
		STUMBLE:
			if Engine.get_physics_frames() % 10 == 0 and Art.on_screen(z, z.global_position):
				Particles.burst(z.get_parent(), z.global_position + Vector2(0, -70.0 * z.sc), "spark", Vector2.UP, 1)
			if _st <= 0.0:
				state = TROT
				_cd = randf_range(CD.x, CD.y) * 0.6
			return _move(delta, 0.0)
	return false


func _trot(pl: Node, has_pl: bool, delta: float) -> bool:
	var hunting: bool = has_pl and (_boss() or z.global_position.distance_to(pl.global_position) < float(z.chase_range) * 1.3 or z._alert_t > 0.0)
	if not hunting:   # מסתובב לאט בשטח
		_patrol -= delta
		if _patrol <= 0.0:
			_patrol = randf_range(2.0, 4.0)
			z._dir = -z._dir if randf() < 0.5 else z._dir
		return _move(delta, z._dir * z.walk_speed, 600.0, true)
	var d: Vector2 = pl.global_position - z.global_position
	var r := CHARGE_R * (1.1 if _boss() else 1.0)
	if _boss() and _lasso_cd <= 0.0 and _lasso_ok(pl):
		_start_lasso(pl)
		return true
	if absf(d.y) > 60.0:   # אתה למעלה: מסתובב מתחתיך ומחכה שתרד
		if absf(d.x) > 60.0:
			z._dir = signf(d.x)
			return _move(delta, z._dir * TROT_V * 0.8, 600.0, true)
		_patrol -= delta
		if _patrol <= 0.0:
			_patrol = randf_range(0.8, 1.6)
			z._dir = -z._dir
		return _move(delta, z._dir * 40.0, 600.0)
	if absf(d.x) < r.x:   # קרוב מדי: מתרחק כדי לקחת תנופה
		z._dir = -signf(d.x) if d.x != 0.0 else z._dir
		if _cd <= 0.0 and absf(d.x) < 70.0 * z.sc:   # צמוד: מסתובב ומסתער מיד
			z._dir = signf(d.x) if d.x != 0.0 else z._dir
			_start_wind(0.45)
		return _move(delta, z._dir * TROT_V * 1.4, 700.0, true)
	if _cd <= 0.0 and absf(d.x) < r.y and _clear(pl):
		_start_wind(WIND_T * (0.8 if _boss() else 1.0))
		return _move(delta, 0.0)
	z._dir = signf(d.x)
	return _move(delta, z._dir * TROT_V, 600.0, true)


func _start_wind(t: float) -> void:
	state = WIND
	_st = t
	z._popup("!", Color("ff7050"), 18, -86.0 * z.sc)
	Sfx.play("rd_neigh", z.global_position, 0.0 if not _boss() else 3.0, 0.1, 2, 1.0 if not _boss() else 0.75)


func _start_charge(pl: Node) -> void:
	state = CHARGE
	charges += 1
	_ct = 0.0
	_hit = false
	_passed = false
	_reared = false
	if pl != null:
		var dx: float = pl.global_position.x - z.global_position.x
		_side = signf(dx) if dx != 0.0 else z._dir
		z._dir = _side
		_end_x = pl.global_position.x + _side * OVERSHOOT * (1.2 if _boss() else 1.0)
	else:
		_side = z._dir
		_end_x = z.global_position.x + z._dir * 500.0
	if _boss() and z.hp < int(float(z.max_hp) * 0.6) and charges % 2 == 0:   # עדר מתים לצד הבוס
		_stampede()


func _charge(pl: Node, has_pl: bool, delta: float) -> bool:
	_ct += delta
	var v := CHARGE_V * (1.1 if _boss() else 1.0)
	z.velocity.x = move_toward(z.velocity.x, z._dir * v, 1800.0 * delta)
	if not z.is_on_floor():
		z.velocity.y += z.gravity * delta
	z.move_and_slide()
	_hoof -= delta
	if _hoof <= 0.0:
		_hoof = 0.16
		if Art.on_screen(z, z.global_position):
			Sfx.play("rd_hoof", z.global_position, -4.0, 0.2, 3)
			Particles.burst(z.get_parent(), z.global_position + Vector2(-z._dir * 16.0, -2.0) * z.sc, "smoke", Vector2(-z._dir, -0.3), 1)
	if has_pl:
		var d: Vector2 = pl.global_position - z.global_position
		# למד שאתה קופץ: נעצר מולך ומזדקף (פרסות גבוהות)
		if learned >= JUMP_LEARN and not _reared and not _passed and signf(d.x) == z._dir and absf(d.x) < REAR_DIST * z.sc and absf(d.y) < 160.0:
			_reared = true
			_start_rear()
			return true
		if not _hit:
			var hr := _horse_rect()
			var pr: Rect2 = pl.body_rect()
			if hr.intersects(pr) and pl._roll_t <= 0.0 and not pl.god_mode():
				_hit = true
				tramples += 1
				pl.hurt(TRAMPLE_DMG + (1 if _boss() else 0), Vector2(z._dir * 2.2, -1.6))
				Sfx.play("rd_hoof", pl.global_position, 4.0, 0.1, 2, 0.7)
				_shake(5.0)
			elif absf(d.x) < 24.0 * z.sc and _rider_rect().intersects(pr) and pl._roll_t <= 0.0 and not pl.god_mode():   # קפיצה נמוכה מדי: הפאקון חותך
				_hit = true
				slashes += 1
				_swing = 0.3
				pl.hurt(SLASH_DMG, Vector2(z._dir * 1.2, -0.6))
				Sfx.play("rd_slash", pl.global_position, 2.0, 0.1, 2)
		if not _passed and signf(d.x) != _side and absf(d.x) > 12.0:   # עבר אותך
			_passed = true
			if not _hit and not pl.is_on_floor() and absf(d.y) < 220.0:   # קפצת מעליו
				jumps_seen += 1
				learned += 1
				if learned == JUMP_LEARN:
					z._popup("IT READS YOUR JUMP", Color("ffd080"), 12, -96.0 * z.sc)
	if z.is_on_wall() and _ct > 0.15:   # נכנס בקיר / מכשול
		_stumble()
		return true
	if _ct >= CHARGE_T or (z._dir > 0.0 and z.global_position.x > _end_x) or (z._dir < 0.0 and z.global_position.x < _end_x):
		state = TURN
		_st = TURN_T
		_cd = randf_range(CD.x, CD.y) * (0.7 if _boss() else 1.0)
	return true


func _horse_rect() -> Rect2:
	var s: float = z.sc
	var x0: float = z.global_position.x + (-26.0 * s if z._dir > 0.0 else -40.0 * s)
	return Rect2(Vector2(x0, z.global_position.y - 38.0 * s), Vector2(66.0 * s, 38.0 * s))


# החלק התחתון של הרוכב (מעל האוכף) - מי שקופץ נמוך מדי נחתך
func _rider_rect() -> Rect2:
	var s: float = z.sc
	return Rect2(Vector2(z.global_position.x - 16.0 * s, z.global_position.y - 62.0 * s), Vector2(32.0 * s, 24.0 * s))


func _start_rear() -> void:
	state = REAR
	rears += 1
	_st = REAR_T
	_struck = false
	z.velocity.x *= 0.3
	Sfx.play("rd_neigh", z.global_position, 3.0, 0.1, 2, 0.85 if not _boss() else 0.65)
	z._popup("REARS!", Color("ff9050"), 14, -100.0 * z.sc)


# מזדקף: הפרסות הקדמיות מכות גבוה מולו (תופס מי שקופץ), ואז ממשיך להסתער
func _rear(pl: Node, has_pl: bool, delta: float) -> bool:
	var k := 1.0 - _st / REAR_T
	if not _struck and k > 0.55:
		_struck = true
		Sfx.play("rd_hoof", z.global_position, 4.0, 0.1, 2, 0.6)
		_shake(4.0)
		if has_pl:
			var s: float = z.sc
			var x0: float = z.global_position.x + (0.0 if z._dir > 0.0 else -80.0 * s)
			var zone := Rect2(Vector2(x0, z.global_position.y - 120.0 * s), Vector2(80.0 * s, 120.0 * s))
			if zone.intersects(pl.body_rect()) and pl._roll_t <= 0.0 and not pl.god_mode():
				rear_hits += 1
				_hit = true
				pl.hurt(REAR_DMG, Vector2(z._dir * 2.0, -1.2))
	if _st <= 0.0:
		state = CHARGE
		_ct = minf(_ct, CHARGE_T * 0.5)
		if has_pl:
			_end_x = pl.global_position.x + z._dir * OVERSHOOT
	return _move(delta, 0.0, 2400.0)


func _stumble() -> void:
	state = STUMBLE
	stumbles += 1
	_st = STUMBLE_T * (0.7 if _boss() else 1.0)
	z.velocity.x = -z._dir * 140.0
	z._popup("STUMBLES", Color("a0d0ff"), 14, -86.0 * z.sc)
	Sfx.play("rd_neigh", z.global_position, 2.0, 0.1, 2, 0.8)
	Particles.burst(z.get_parent(), z.global_position + Vector2(z._dir * 26.0, -30.0) * z.sc, "smoke", Vector2(-z._dir, -0.5), 6)
	_shake(4.0)


# האם יש קו פתוח לשחקן (בלי קיר באמצע)
func _clear(pl: Node) -> bool:
	var a: Vector2 = z.global_position + Vector2(0, -30.0)
	var b: Vector2 = pl.global_position + Vector2(0, -30.0)
	var hit: Dictionary = z.get_world_2d().direct_space_state.intersect_ray(PhysicsRayQueryParameters2D.create(a, b, 1))
	return hit.is_empty()


# ============================================================
#  בוס: לאסו, קריאה לרוכבים, עדר
# ============================================================
func _boss_extras(_pl: Node) -> void:
	var frac := float(z.hp) / maxf(float(z.max_hp), 1.0)
	if mounted:
		frac = minf(frac, float(horse_hp) / float(horse_max))
	if _called < CALL_AT.size() and frac < float(CALL_AT[_called]):
		_called += 1
		_call_riders()


func _call_riders() -> void:
	calls += 1
	Sfx.play("rd_whistle", z.global_position, 4.0, 0.05, 2)
	z._popup("A LOS CABALLOS!", Color("ffd080"), 18, -110.0 * z.sc)
	var riders := 0
	for o in z.get_tree().get_nodes_in_group("zombies"):
		if o != z and not o.dead and o.type_mod != null and o.type_mod.get_script() == get_script():
			riders += 1
	var main: Node = z.get_parent()
	if not main.has_method("_spawn_zombie"):
		return
	for i in mini(CALL_N, 4 - riders):
		var x: float = z.global_position.x + (-720.0 if i % 2 == 0 else 720.0)
		var r = main._spawn_zombie(x, z.global_position.y, z.kind)
		if r != null:
			r._alert_t = 8.0
			r._dir = signf(z.global_position.x - x)


func _stampede() -> void:
	stampedes += 1
	z._popup("STAMPEDE!", Color("ff8050"), 20, -110.0 * z.sc)
	Sfx.play("rd_whistle", z.global_position, 3.0, 0.05, 2)
	for i in STAMPEDE_N:
		var s := Decor.Steer.new()
		s.dir = z._dir
		z.get_parent().add_child(s)
		s.global_position = Vector2(z.global_position.x - z._dir * (90.0 + float(i) * 110.0), z.global_position.y)


func _lasso_ok(pl: Node) -> bool:
	var d: Vector2 = pl.global_position - z.global_position
	return absf(d.x) > LASSO_R.x and absf(d.x) < LASSO_R.y and absf(d.y) < 260.0 and pl.grabbed_by == null and _clear(pl)


func _start_lasso(pl: Node) -> void:
	state = LASSO
	lassos += 1
	_st = LASSO_WIND
	_lasso_cd = LASSO_CD
	z._dir = signf(pl.global_position.x - z.global_position.x)
	z._popup("LASSO!", Color("ffd080"), 16, -110.0 * z.sc)
	Sfx.play("rd_lasso", z.global_position, 0.0, 0.1, 2)


func _hand() -> Vector2:
	if mounted:
		return z.global_position + Vector2(z._dir * 6.0, -74.0) * z.sc
	return z.global_position + Vector2(z._dir * 4.0, -60.0) * z.sc


func _lasso_state(pl: Node, delta: float) -> bool:
	var has_pl: bool = pl != null and not pl.dead
	if _lasso == null:   # מסובב מעל הראש
		if Engine.get_physics_frames() % 18 == 0:
			Sfx.play("rd_lasso", z.global_position, -4.0, 0.1, 2)
		if _st <= 0.0:
			if not has_pl:
				_end_lasso()
				return _move(delta, 0.0)
			var l := Lasso.new()
			l.owner_z = z
			l.boss = self
			l.target = pl.global_position + Vector2(0, -30)
			l.position = _hand()
			z.get_parent().add_child(l)
			_lasso = l
			Sfx.play("rd_lasso", z.global_position, 3.0, 0.1, 2, 1.3)
		return _move(delta, 0.0)
	if not is_instance_valid(_lasso):
		_lasso = null
		_end_lasso()
		return _move(delta, 0.0)
	return _move(delta, 0.0)


# הלאסו גמר (פספס / נחתך / גרר אותך עד הסוס)
func lasso_done(caught: bool) -> void:
	_lasso = null
	if caught:
		var pl := player()
		if pl != null and not pl.dead:
			if mounted:
				state = REAR
				rears += 1
				_st = REAR_T * 0.6
				_struck = false
				_reared = true
				Sfx.play("rd_neigh", z.global_position, 3.0, 0.1, 2, 0.65)
				return
			_swing = 0.3
			pl.hurt(2, Vector2(z._dir * 1.6, -1.0))
			Sfx.play("rd_slash", pl.global_position, 3.0, 0.1, 2)
	_end_lasso()


func _end_lasso() -> void:
	state = TROT
	_cd = 0.6


func _drop_lasso() -> void:
	if _lasso != null and is_instance_valid(_lasso):
		_lasso.cut(false)
	_lasso = null


func on_death() -> void:
	_drop_lasso()
	if mounted:   # מת על הסוס: הסוס נופל איתו
		mounted = false
		var hc := HorseCorpse.new()
		hc.dir = z._dir
		hc.s = z.sc
		hc.armored = _boss()
		z.get_parent().add_child(hc)
		hc.global_position = z.global_position
		corpse = hc
		z.sc = _foot_sc


func _move(delta: float, vx: float, acc := 1200.0, hop := false) -> bool:
	z.velocity.x = move_toward(z.velocity.x, vx, acc * delta)
	if not z.is_on_floor():
		z.velocity.y += z.gravity * delta
	elif hop and z.is_on_wall() and absf(vx) > 1.0:   # הסוס קופץ מעל חבילות חציר / חביות
		z.velocity.y = -560.0
		z.velocity.x = z._dir * maxf(absf(vx), 160.0)
		Sfx.play("rd_neigh", z.global_position, -4.0, 0.1, 2, 1.2)
	z.move_and_slide()
	return true


func _shake(s: float) -> void:
	var cam: Camera2D = z.get_viewport().get_camera_2d()
	if cam != null and cam.has_method("shake") and Art.on_screen(z, z.global_position):
		cam.shake(s, 0.25)


# ============================================================
#  לאסו (בוס): לולאה שעפה, תופסת וגוררת. ירייה בחבל = נחתך
# ============================================================
class Lasso extends Node2D:
	const Sfx2 := preload("res://sfx.gd")
	var owner_z: Node = null
	var boss = null
	var target := Vector2.ZERO
	var caught := false
	var _v := Vector2.ZERO
	var _t := 0.0
	var _d := 0.0
	var _dead := false
	var _body: StaticBody2D = null
	var _seg: SegmentShape2D = null

	class Rope extends StaticBody2D:
		var l = null
		func hit_by_bullet(_p: Vector2, _n: Vector2, _d: Vector2) -> void:
			if l != null:
				l.cut(true)

	func _ready() -> void:
		z_index = 7
		_v = (target - global_position).normalized() * 950.0
		var b := Rope.new()
		b.l = self
		b.collision_layer = 4
		b.collision_mask = 0
		var cs := CollisionShape2D.new()
		_seg = SegmentShape2D.new()
		cs.shape = _seg
		b.add_child(cs)
		add_child(b)
		_body = b

	func _hand() -> Vector2:
		if boss != null and owner_z != null and is_instance_valid(owner_z):
			return boss._hand()
		return global_position

	func cut(by_shot: bool) -> void:
		if _dead:
			return
		_dead = true
		var pl := get_tree().get_first_node_in_group("player")
		if by_shot and boss != null:
			boss.cuts += 1
		if by_shot and pl != null and pl.has_method("_say"):
			pl._say("ROPE CUT!", Color("a0ffa0"))
		Sfx2.play("rd_slash", global_position, 0.0, 0.1, 2, 1.4)
		if boss != null and owner_z != null and is_instance_valid(owner_z) and not owner_z.dead:
			boss.lasso_done(false)
		queue_free()

	func _physics_process(delta: float) -> void:
		if _dead:
			return
		if owner_z == null or not is_instance_valid(owner_z) or owner_z.dead:
			_dead = true
			queue_free()
			return
		_t += delta
		var pl := get_tree().get_first_node_in_group("player")
		var hand := _hand()
		if not caught:
			global_position += _v * delta
			_d += _v.length() * delta
			if pl != null and not pl.dead and pl.body_rect().grow(10.0).has_point(global_position) and pl._roll_t <= 0.0 and not pl.god_mode() and pl.grabbed_by == null:
				caught = true
				_t = 0.0
				boss.drags += 1
				pl._say("LASSOED!  SHOOT THE ROPE", Color("ff9050"))
				Sfx2.play("tr_grab" if Sfx2.has_sound("tr_grab") else "hit", pl.global_position, 2.0)
			elif _d > 700.0:
				_dead = true
				boss.lasso_done(false)
				queue_free()
				return
		else:
			if pl == null or pl.dead:
				_dead = true
				boss.lasso_done(false)
				queue_free()
				return
			global_position = pl.global_position + Vector2(0, -30)
			var dx: float = hand.x - pl.global_position.x
			pl.velocity.x = signf(dx) * 360.0
			pl._push_t = maxf(float(pl._push_t), 0.12)
			if absf(dx) < 70.0 * owner_z.sc or _t > 1.6:   # הגיע אל הסוס
				_dead = true
				pl.velocity.x = 0.0
				boss.lasso_done(absf(dx) < 110.0 * owner_z.sc)
				queue_free()
				return
		_seg.a = to_local(hand)
		_seg.b = Vector2.ZERO
		queue_redraw()

	func _draw() -> void:
		var h := to_local(_hand())
		var mid := h.lerp(Vector2.ZERO, 0.5) + Vector2(0, 14.0 if not caught else 4.0)
		var pts := PackedVector2Array()
		for i in 9:
			var k := float(i) / 8.0
			pts.append(h.lerp(mid, k).lerp(mid.lerp(Vector2.ZERO, k), k))
		DrawBatch.polyline(self, pts, Color("3a2a18"), 3.0)
		DrawBatch.polyline(self, pts, Color("b89a6a"), 1.6)
		DrawBatch.arc(self, Vector2.ZERO, 14.0 if not caught else 18.0, 0, TAU, 16, Color("3a2a18"), 3.0)
		DrawBatch.arc(self, Vector2.ZERO, 14.0 if not caught else 18.0, 0, TAU, 16, Color("b89a6a"), 1.6)


# ============================================================
#  גופת הסוס (נשארת בשטח)
# ============================================================
class HorseCorpse extends Node2D:
	var dir := 1.0
	var s := 1.0
	var armored := false
	var _t := 0.0

	func _ready() -> void:
		z_index = 2

	func _process(delta: float) -> void:
		if _t < 1.0:
			_t += delta
			queue_redraw()
		else:
			set_process(false)

	func _draw() -> void:
		var k := clampf(_t / 0.45, 0.0, 1.0)
		k = k * k
		Art.ground_shadow(self, Vector2.ZERO, 34.0 * s)
		# קורס: הרגליים מתקפלות, הגוף שוקע לקרקע והראש נשמט
		var base := Transform2D(0.0, Vector2(dir * s, s), 0.0, Vector2.ZERO)
		DrawBatch.set_transform_matrix(self, base * Transform2D(0.1 * k, Vector2(0, 18.0 * k)))
		if k < 0.6:
			draw_horse(self, 0.0, 0.0, armored, false, true, 3)
		else:   # רגליים נוקשות שבולטות הצידה
			var hoof := Color("1e1a16")
			var hide := Color("5e5650") if armored else Color("6e6258")
			for q in 4:
				var a := Vector2(-16.0 + float(q) * 10.0, -22.0)
				var b := a + Vector2(10.0 + float(q % 2) * 4.0, 4.0 + float(q) * 0.5)
				Art.limb(self, PackedVector2Array([a, a.lerp(b, 0.5) + Vector2(0, 1), b]), 3.4, hide.darkened(0.15 * float(q % 2)))
				DrawBatch.rect(self, Rect2(b + Vector2(0, -2), Vector2(3, 4)), hoof)
			draw_horse(self, 0.0, 0.0, armored, false, true, 0)
		DrawBatch.set_transform_matrix(self, Transform2D.IDENTITY)

	# הסוס המת. ph = שלב דהירה, gal = 0..1 כמה דוהר, dead = עיניים כבויות, flash = לבן
	static func draw_horse(ci: CanvasItem, ph: float, gal: float, armored: bool, flash: bool, dead: bool, legs := 3) -> void:
		var hide := Color.WHITE if flash else (Color("5e5650") if armored else Color("6e6258"))
		var dark := Color.WHITE if flash else hide.darkened(0.3)
		var bone := Color.WHITE if flash else Color("e2d8bc")
		var mane := Color.WHITE if flash else Color("2a2420")
		var hoof := Color("1e1a16")
		# רגליים (legs: 1 = רק אחוריות, 2 = רק קדמיות, 3 = הכל)
		var lx := [-18.0, -12.0, 13.0, 19.0]
		for q in 4:
			if (q < 2 and legs & 1 == 0) or (q >= 2 and legs & 2 == 0):
				continue
			var off: float = [0.0, PI, 0.6, PI + 0.6][q]
			var sw := sin(ph + off) * (2.0 + gal * 9.0)
			var lift := maxf(0.0, cos(ph + off)) * (1.0 + gal * 5.0)
			var top := Vector2(float(lx[q]), -24.0)
			var foot := Vector2(lx[q] + sw, -lift)
			var knee := top.lerp(foot, 0.5) + Vector2((3.0 if q >= 2 else -3.0) * (0.4 + gal * 0.6), 0.0)
			var c := dark if q % 2 == 0 else hide
			Art.limb(ci, PackedVector2Array([top, knee, foot]), 3.6, c)
			DrawBatch.rect(ci, Rect2(foot + Vector2(-2.2, -2.5), Vector2(4.4, 2.5)), hoof)
			if q == 1 and not flash:   # עצם חשופה ברגל
				DrawBatch.line(ci, knee + Vector2(-1, -1), knee.lerp(foot, 0.5), bone, 1.0)
		# זנב קרוע
		var tw := sin(ph * 0.5) * 3.0 * (0.4 + gal)
		DrawBatch.polyline(ci, PackedVector2Array([Vector2(-23, -33), Vector2(-30, -30 + tw * 0.4), Vector2(-34 - gal * 6.0, -24 + tw), Vector2(-35 - gal * 8.0, -16 + tw)]), mane, 3.0)
		DrawBatch.line(ci, Vector2(-31, -28 + tw * 0.4), Vector2(-37 - gal * 6.0, -20 + tw), mane, 1.4)
		# גוף
		var body := Art.ellipse(Vector2(0, -29), 25.0, 9.5, 0.0, 18)
		Art.fill_shaded(ci, body, hide, 0.12, 0.38)
		if not flash:
			DrawBatch.colored_polygon(ci, Art.ellipse(Vector2(6, -26), 8.0, 4.5, 0.0, 12), Color(0.22, 0.03, 0.04, 0.9))   # בטן פתוחה
			for q in 4:   # צלעות מעוקלות
				var rx := 0.5 + float(q) * 3.4
				DrawBatch.polyline(ci, PackedVector2Array([Vector2(rx - 1.0, -33.5), Vector2(rx + 1.2, -28.0), Vector2(rx + 0.4, -22.5)]), bone.darkened(0.1), 1.0)
			brand_on(ci, Vector2(-15, -29), 3.2, Color("2a1a10"))
		# אוכף (רקאדו) עם עור כבש ושמיכה
		DrawBatch.rect(ci, Rect2(-10, -40, 18, 6), Color.WHITE if flash else Color("7a2a20"))   # שמיכה
		DrawBatch.rect(ci, Rect2(-10, -40, 18, 1.5), Color.WHITE if flash else Color("d8b060"))
		Art.fill(ci, PackedVector2Array([Vector2(-9, -40), Vector2(-7, -44), Vector2(5, -44), Vector2(8, -40)]), Color.WHITE if flash else Color("d8ccb0"))   # עור כבש
		DrawBatch.line(ci, Vector2(-1, -36), Vector2(-1, -26), Color("3a2a1a"), 1.0)   # רצועת האוכף
		# צוואר וראש-גולגולת
		var neck := PackedVector2Array([Vector2(14, -36), Vector2(20, -46), Vector2(27, -51), Vector2(31, -46), Vector2(25, -38), Vector2(22, -26)])
		Art.fill_shaded(ci, neck, hide, 0.12, 0.32)
		for q in 6:   # רעמה קרועה
			var mp := Vector2(15, -38).lerp(Vector2(27, -52), float(q) / 5.0)
			DrawBatch.line(ci, mp, mp + Vector2(-5.0 - gal * 4.0, -2.0 + sin(ph + float(q)) * 2.0), mane, 2.0)
		var hd := Vector2(34, -45)
		Art.fill(ci, Art.ellipse(hd, 9.5, 4.6, 0.55, 14), bone)   # גולגולת
		Art.fill(ci, PackedVector2Array([hd + Vector2(-5, -3), hd + Vector2(1, -5), hd + Vector2(3, -2), hd + Vector2(-3, 1)]), hide, Art.NONE)   # שאריות עור
		DrawBatch.line(ci, hd + Vector2(2, 3), hd + Vector2(8, 7), Color("2a0a0a"), 1.6)   # לסת פתוחה
		for q in 3:
			DrawBatch.line(ci, hd + Vector2(3.0 + float(q) * 2.0, 3.5 + float(q)), hd + Vector2(3.5 + float(q) * 2.0, 5.5 + float(q)), bone, 0.8)
		DrawBatch.line(ci, hd + Vector2(-6, -4), hd + Vector2(-8, -9), dark, 2.0)   # אוזן
		if not dead:
			DrawBatch.circle(ci, hd + Vector2(-1, -1.5), 1.6, Color(1.0, 0.45, 0.1))
			Art.glow(ci, hd + Vector2(-1, -1.5), 5.0, Color(1.0, 0.35, 0.1, 0.45))
		else:
			DrawBatch.circle(ci, hd + Vector2(-1, -1.5), 1.4, Color(0.1, 0.05, 0.05))
		DrawBatch.line(ci, hd + Vector2(5, 0), Vector2(8, -40), Color("3a2a1a"), 0.8)   # רסן
		if armored:   # שריון: מסכת ברזל לראש, לוחות על הצוואר והגוף, מסמרות
			var steel := Color.WHITE if flash else Color("8a9094")
			Art.fill(ci, PackedVector2Array([hd + Vector2(-7, -5), hd + Vector2(6, -6), hd + Vector2(9, -1), hd + Vector2(-2, 1)]), steel, Art.OUTLINE, 1.0)
			DrawBatch.line(ci, hd + Vector2(-3, -6), hd + Vector2(-5, -12), steel, 2.0)   # קוץ
			Art.fill(ci, PackedVector2Array([Vector2(16, -38), Vector2(22, -47), Vector2(27, -50), Vector2(28, -44), Vector2(22, -34)]), steel.darkened(0.1), Art.OUTLINE, 1.0)
			Art.fill(ci, PackedVector2Array([Vector2(-24, -34), Vector2(-12, -39), Vector2(12, -39), Vector2(24, -32), Vector2(20, -22), Vector2(-20, -22)]), steel.darkened(0.15), Art.OUTLINE, 1.2)
			if not flash:
				for q in 7:
					DrawBatch.circle(ci, Vector2(-18.0 + float(q) * 6.0, -24.0), 0.9, Color("d0d4d8"))
				brand_on(ci, Vector2(-12, -30), 3.6, Color("4a1a10"))
				DrawBatch.line(ci, Vector2(-22, -36), Vector2(20, -36), Color(1, 1, 1, 0.25), 1.0)

	static func brand_on(ci: CanvasItem, c: Vector2, r: float, col: Color) -> void:
		DrawBatch.line(ci, c + Vector2(-r * 0.35, r * 0.7), c + Vector2(-r * 0.35, -r * 0.7), col, 1.0)
		DrawBatch.arc(ci, c + Vector2(-r * 0.35, -r * 0.3), r * 0.4, -PI * 0.5, PI * 0.5, 6, col, 1.0)
		DrawBatch.line(ci, c + Vector2(-r * 0.7, r * 0.9), c + Vector2(r * 0.6, r * 0.9), col, 1.0)


# ============================================================
#  ציור. רכוב: הסוס + הגאוצ'ו על האוכף (טרנספורם בלי wf). REAR = הסוס מזדקף על הרגליים האחוריות.
#  ברגל: גאוצ'ו עם פונצ'ו, כובע רחב, בומבאצ'ה ומגפיים, פאקון ביד.
# ============================================================
func draw() -> bool:
	if mounted and not z.dead:
		_draw_mounted()
		return true
	begin_draw()
	var air: bool = state == THROWN and not z.is_on_floor()
	var f: Array = feet(6.0 if z._chasing else 5.0, 3.0)
	if air:
		f = [Vector2(8, -10), Vector2(-6, -4)]
	var hip := Vector2(0, -24)
	var sh := Vector2(3, -41)
	z._leg(hip + Vector2(-2, 0), f[1], col(Art.shade(z.pants, 0.25)), col(z.skin), col(z.shoe))
	z._leg(hip + Vector2(2, 0), f[0], col(z.pants), col(z.skin), col(z.shoe))
	var back_h: Vector2 = sh + Vector2(-6.0 + sin(z._walk_phase) * 6.0, 16.0)
	z._arm(sh + Vector2(-2, 2), back_h, col(Art.shade(z.skin, 0.25)), col(Art.shade(z.shirt, 0.3)))
	_gaucho_body(hip, sh)
	var front_h: Vector2 = sh + Vector2(14.0, 4.0)
	if _swing > 0.0:
		var k := 1.0 - _swing / 0.3
		front_h = sh + Vector2(6.0 + k * 12.0, -12.0 + k * 20.0)
	_head_hat(sh + Vector2(3.0, -9.0))
	z._arm(sh + Vector2(2, 2), front_h, col(z.skin), col(z.shirt))
	_facon(front_h, -0.5 + (1.6 * (1.0 - _swing / 0.3) if _swing > 0.0 else 0.6))
	end_draw()
	return true


func _draw_mounted() -> void:
	var s: float = z.sc
	Art.ground_shadow(z, Vector2.ZERO, 30.0 * s)
	var base := Transform2D(0.0, Vector2(z._dir * s, s), 0.0, Vector2.ZERO)
	var gal := 1.0 if state == CHARGE else (0.4 if absf(z.velocity.x) > 30.0 else 0.0)
	var ph := _ph
	var rear := 0.0
	match state:
		REAR:
			var k := 1.0 - _st / REAR_T
			rear = sin(clampf(k, 0.0, 1.0) * PI) * 0.75
		WIND:
			rear = 0.12 + sin(z._time * 14.0) * 0.04
		STUMBLE:
			rear = -0.18
	var flash: bool = z._flash > 0.0
	if rear != 0.0:   # רגליים אחוריות על הקרקע, השאר מסתובב סביב הירכיים
		DrawBatch.set_transform_matrix(z, base)
		HorseCorpse.draw_horse(z, ph, gal, _boss(), flash, false, 1)
		var piv := Vector2(-15, -24)
		DrawBatch.set_transform_matrix(z, base * Transform2D(-rear, piv) * Transform2D(0.0, -piv))
		HorseCorpse.draw_horse(z, ph + (z._time * 14.0 if state == REAR else 0.0), gal, _boss(), flash, false, 2)
		_rider(gal)
	else:
		var bob := -absf(sin(ph)) * (1.0 + gal * 2.5)
		DrawBatch.set_transform_matrix(z, base * Transform2D(0.0, Vector2(0, bob)))
		HorseCorpse.draw_horse(z, ph, gal, _boss(), flash, false, 3)
		_rider(gal)
	DrawBatch.set_transform_matrix(z, Transform2D.IDENTITY)


# הגאוצ'ו על האוכף (קואורדינטות של הסוס)
func _rider(gal: float) -> void:
	var lean := 4.0 * gal
	var hip := Vector2(-2, -42)
	var sh := Vector2(1.0 + lean, -58)
	# רגל במדרס (תלויה על הצד)
	z._leg(hip + Vector2(1, 0), Vector2(5, -27), col(z.pants), col(z.skin), col(z.shoe))
	DrawBatch.line(z, Vector2(3, -30), Vector2(3, -36), Color("3a2a1a"), 1.0)   # רצועת המדרס
	DrawBatch.rect(z, Rect2(Vector2(1, -28), Vector2(7, 2)), Color("8a8e90"))
	var rein: Vector2 = sh + Vector2(10, 10)
	z._arm(sh + Vector2(-2, 2), rein, col(Art.shade(z.skin, 0.25)), col(Art.shade(z.shirt, 0.3)))
	DrawBatch.line(z, rein, Vector2(30, -48), Color("3a2a1a"), 0.9)   # מושכות
	_gaucho_body(hip, sh)
	_head_hat(sh + Vector2(2.0, -9.0))
	var hand: Vector2
	var ang: float
	if state == LASSO and _lasso == null:   # מסובב לאסו מעל הראש
		var a: float = z._time * 14.0
		hand = sh + Vector2(4, -16)
		ang = -1.2
		var c := hand + Vector2(0, -8)
		DrawBatch.arc(z, c, 16.0, 0, TAU, 18, Color("3a2a18"), 2.2)
		DrawBatch.arc(z, c, 16.0, a, a + 4.5, 12, Color("b89a6a"), 1.4)
	elif state == WIND or (state == CHARGE and not _hit):   # פאקון מורם
		hand = sh + Vector2(10, -12)
		ang = -1.0
	elif _swing > 0.0 or state == REAR:
		var k := 1.0 - maxf(_swing, 0.0) / 0.3
		hand = sh + Vector2(10.0 + k * 8.0, -6.0 + k * 22.0)
		ang = -0.6 + k * 1.8
	else:
		hand = sh + Vector2(12, 8)
		ang = 0.5
	z._arm(sh + Vector2(2, 2), hand, col(z.skin), col(z.shirt))
	if state == LASSO:
		if _lasso == null:
			pass
	else:
		_facon(hand, ang)
	if _boss():   # לאסו מגולגל על האוכף
		DrawBatch.arc(z, Vector2(-12, -38), 5.0, 0, TAU, 12, Color("b89a6a"), 1.6)
		DrawBatch.arc(z, Vector2(-12, -38), 3.5, 0, TAU, 12, Color("8a6a40"), 1.2)


# גוף הגאוצ'ו: פונצ'ו מאובק עם פסים, חגורת מטבעות (רסטרה), מטפחת אדומה. בוס: מעיל ארוך שחור עם כפתורי כסף
func _gaucho_body(hip: Vector2, sh: Vector2) -> void:
	var poncho := col(z.shirt)
	var pts := PackedVector2Array([sh + Vector2(-9, -1), sh + Vector2(9, 0), sh + Vector2(13, 13), hip + Vector2(10, -2),
		hip + Vector2(6, 2), hip + Vector2(2, -1), hip + Vector2(-3, 2), hip + Vector2(-8, -1), hip + Vector2(-11, -3), sh + Vector2(-12, 12)])
	if _boss():
		pts = PackedVector2Array([sh + Vector2(-9, -1), sh + Vector2(9, 0), sh + Vector2(11, 12), hip + Vector2(9, 6),
			hip + Vector2(4, 9), hip + Vector2(-4, 9), hip + Vector2(-10, 7), sh + Vector2(-11, 12)])
	Art.fill_shaded(z, pts, poncho, 0.14, 0.36)
	if _boss():
		for q in 4:
			DrawBatch.circle(z, sh.lerp(hip, 0.15 + float(q) * 0.22) + Vector2(4, 0), 1.0, col(Color("d8dce0")))
		DrawBatch.line(z, sh + Vector2(-2, 2), hip + Vector2(-3, 8), col(Color("4a4a54")), 1.0)
	else:
		DrawBatch.polyline(z, PackedVector2Array([sh + Vector2(-11, 9), sh + Vector2(0, 11), sh + Vector2(12, 9)]), col(Color("d8b060")), 1.4)   # פסים
		DrawBatch.polyline(z, PackedVector2Array([sh + Vector2(-11, 12), sh + Vector2(0, 14), sh + Vector2(12, 12)]), col(Color("2a1410")), 1.2)
		DrawBatch.line(z, sh + Vector2(4, 5), sh + Vector2(7, 9), Color(0.15, 0.08, 0.05, 0.6), 1.0)   # קרע
	DrawBatch.rect(z, Rect2(hip + Vector2(-9, -6), Vector2(18, 5)), col(Color("3a2418")))   # רסטרה
	for q in 4:
		DrawBatch.circle(z, hip + Vector2(-6.0 + float(q) * 4.0, -3.5), 1.4, col(Color("cfd0c8")))
	Art.fill(z, PackedVector2Array([sh + Vector2(-4, -1), sh + Vector2(6, -1), sh + Vector2(2, 5)]), col(Color("a82a20")), Art.OUTLINE, 0.8)   # מטפחת


# ראש עם כובע רחב שוליים (בוס: כובע שחור גבוה עם סרט כסף)
func _head_hat(c: Vector2) -> void:
	z._head(c, col(z.skin))
	var hat := col(Color("2a2420") if _boss() else Color("5a4632"))
	var brim_w := 13.0 if not _boss() else 15.0
	Art.fill(z, PackedVector2Array([c + Vector2(-brim_w, -4), c + Vector2(brim_w, -5), c + Vector2(brim_w - 2.0, -7), c + Vector2(-brim_w + 1.0, -6.5)]), hat, Art.OUTLINE, 1.0)
	var crown_h := 7.0 if not _boss() else 10.0
	Art.fill(z, PackedVector2Array([c + Vector2(-6, -6.5), c + Vector2(6, -7), c + Vector2(5, -6.5 - crown_h), c + Vector2(-5, -6 - crown_h)]), hat, Art.OUTLINE, 1.0)
	DrawBatch.line(z, c + Vector2(-6, -8.5), c + Vector2(6, -9), col(Color("c8ccd0") if _boss() else Color("7a2a20")), 1.6)   # סרט
	if not z.dead:   # עיניים בוערות מתחת לשוליים
		DrawBatch.circle(z, c + Vector2(4.0, -1.5), 1.1, Color(1.0, 0.5, 0.15))


# פאקון: סכין גאוצ'ו ארוכה עם ידית כסף
func _facon(hand: Vector2, ang: float) -> void:
	var d := Vector2.from_angle(ang)
	var tip := hand + d * (17.0 if not _boss() else 20.0)
	DrawBatch.line(z, hand - d * 3.0, hand + d * 2.0, Color("c8ccd0"), 2.6)
	DrawBatch.colored_polygon(z, PackedVector2Array([hand + d * 2.0 + d.orthogonal() * 1.6, tip, hand + d * 2.0 - d.orthogonal() * 1.2]), Color("d8dce0"))
	DrawBatch.line(z, hand + d * 3.0, tip - d * 2.0, Color(1, 1, 1, 0.6), 0.6)
	if _swing > 0.0:   # קשת החיתוך
		DrawBatch.arc(z, hand, 18.0, ang - 1.4, ang, 10, Color(1, 1, 1, 0.5 * _swing / 0.3), 2.0)
