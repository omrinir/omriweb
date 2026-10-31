extends "res://enemies/zombie_type.gd"
# ============================================================
#  FLENSER (שלב 58, "WHALE GRAVEYARD") - פועל בתחנת ציד הלווייתנים: סוודר צמר עבה, סינר שעוונית מגואל בשומן ובדם,
#    מגפיים עם דורבנות, כובע גרב. ביד אחת סכין הפשטה על מוט ארוך (flensing knife), ביד השנייה - עצם שכמה של לווייתן
#    קשורה בחבלים לאמה: מגן.
#  מה הוא למד, וממה: הנבגים נשאו אלפי מיתות של ירייה בראש. הם למדו שגולגולת נשברת - ועצם לווייתן לא. אז הם לובשים את המתים.
#    המגן (BONE_HP) חוסם כל ירייה מלפנים בפס שלו (SHIELD_H סביב shield_y). בהליכה הוא מחזיק אותו גבוה (HIGH_Y - שומר על הראש
#    והחזה): לירות מתחת (בטן / רגליים), מאחור (x BACK_MULT), או לפוצץ (רימון שובר עצם, BLAST_CHIP). ירי ארוך במגן סודק אותו
#    (כל פגיעה שנחסמה מורידה CHIP מהנזק) - "BONE SHATTERS" ואז הוא פתוח לגמרי (ומשתולל, RAGE).
#  התקפות:
#    HOOK  - בטווח HOOK_R: מושך את המוט אחורה (HOOK_WIND, המגן יורד נמוך = הראש פתוח!) ודוקר נמוך בגובה הקרסול (HOOK_T):
#            לקפוץ. פגע -> נזק + הוו מושך אותך אליו (HOOK_PULL) ומאט.
#    SLASH - קרוב (SLASH_R): מרים את הסכין מעל הראש (SLASH_WIND, המגן זז הצידה = פתוח x OPEN_MULT), קוצץ, ומתאושש (RECOVER).
#  לומד (main meta "fl_around" >= LEARN_AROUND - כמה פעמים ירית "מסביב" למגן מלפנים): "IT READS YOUR AIM NOW" -
#    המגן עוקב אחרי הגובה שאליו אתה מכוון (באיחור TRACK_DELAY, במהירות TRACK_V). נגד: לכוון למעלה ולהזיז מהר למטה (או הפוך),
#    להתגלגל מאחוריו, רימונים.
#  בוס (chase_range > 600): "THE BONE KING" - ענק עם גולגולת לווייתן כקסדה (SKULL_HP: ירייה בראש x SKULL_MULT עד שהיא נשברת)
#    ולסת לווייתן כמגן (JAW_HP, חוסמת את כל הגוף מלפנים). צמח ECHO על הגב = נקודת התורפה (x GROWTH_MULT).
#    SWEEP - לסת נמוכה לרוחב (B_SWEEP_*): לקפוץ. אחרי - פתוח מלפנים. RAM - מסתער עם הגולגולת (RAM_V): נתקע במכשול / בקיר
#      (STUCK_T - הגב פתוח x STUCK_MULT). THROW - זורק צלצל עם חבל (מושך אותך אליו). CALL - שואג וקורא ל-FLENSER (CALL_*).
#    מסתובב לאט (TURN_T) - להתגלגל מאחוריו. לומד בקרב: אחרי BACK_LEARN פגיעות בגב - "IT GUARDS ITS BACK NOW" (מסתובב
#    מהר ומטאטא אחורה), ומתחת לחצי חיים - "IT READS YOUR AIM NOW" (הלסת עוקבת אחרי הכוונת).
#  לשנות: HIGH_Y, LOW_Y, SHIELD_H, BONE_HP, CHIP, BLAST_CHIP, BACK_MULT, OPEN_MULT, LEARN_AROUND, TRACK_V, TRACK_DELAY,
#    HOOK_R, HOOK_WIND, HOOK_DMG, HOOK_PULL, SLASH_R, SLASH_WIND, RECOVER, CD;
#    בוס: SKULL_HP, SKULL_MULT, JAW_HP, GROWTH_MULT, B_SWEEP_R, RAM_V, STUCK_T, STUCK_MULT, THROW_R, CALL_*, TURN_T, BACK_LEARN.
# ============================================================

const SOUNDS := {
	"fl_chip": [["C", 0, 0, 0.0, 0.12, 0.0, 30.0, 0.55, 1.0, 0], ["S", 1400, 900, 0.0, 0.06, 0.0, 40.0, 0.25, 1.0, 0], ["N", 0, 0, 0.0, 0.1, 0.0, 20.0, 0.3, 0.6, 0]],
	"fl_shatter": {"rev": 0.2, "layers": [["C", 0, 0, 0.0, 0.4, 0.0, 8.0, 0.9, 1.0, 0], ["N", 0, 0, 0.0, 0.5, 0.0, 6.0, 0.6, 0.5, 0, 0.2], ["S", 900, 300, 0.0, 0.3, 0.0, 9.0, 0.4, 1.0, 0], ["C", 0, 0, 0.12, 0.2, 0.0, 14.0, 0.5, 1.0, 0]]},
	"fl_hook": [["N", 0, 0, 0.0, 0.3, 0.05, 6.0, 0.6, 0.25, 0, 0.05], ["S", 2200, 1800, 0.18, 0.08, 0.0, 30.0, 0.3, 1.0, 0], ["C", 0, 0, 0.2, 0.1, 0.0, 30.0, 0.4, 1.0, 0]],
	"fl_slash": [["N", 0, 0, 0.0, 0.25, 0.0, 9.0, 0.75, 0.55, 0, 0.3], ["S", 3200, 2400, 0.0, 0.12, 0.0, 20.0, 0.2, 1.0, 0]],
	"fl_grunt": {"drive": 2.2, "layers": [["V", 140, 110, 0.0, 0.35, 0.02, 4.0, 0.7, 1.0, 0.04, 0, [450, 1100, 20]]]},
	"kb_bellow": {"rev": 0.45, "drive": 2.8, "layers": [["V", 62, 48, 0.0, 1.8, 0.1, 1.0, 1.0, 1.0, 0.07, 0, [340, 700, 26]], ["V", 93, 70, 0.05, 1.7, 0.1, 1.0, 0.6, 1.0, 0.07, 0, [420, 860, 22]], ["N", 0, 0, 0.0, 1.6, 0.1, 1.4, 0.35, 0.12, 0]]},
	"kb_ram": {"rev": 0.2, "layers": [["N", 0, 0, 0.0, 1.0, 0.1, 1.6, 0.6, 0.12, 0, 0.1], ["S", 70, 50, 0.0, 1.0, 0.1, 1.6, 0.5, 1.0, 0.04]]},
	"kb_crunch": {"rev": 0.3, "drive": 2.4, "layers": [["C", 0, 0, 0.0, 0.5, 0.0, 6.0, 1.0, 1.0, 0], ["N", 0, 0, 0.0, 0.6, 0.0, 5.0, 0.8, 0.15, 0], ["S", 55, 30, 0.0, 0.6, 0.0, 5.0, 0.9, 1.0, 0]]},
	"kb_sweep": [["N", 0, 0, 0.0, 0.45, 0.08, 4.0, 0.8, 0.2, 0, 0.05], ["S", 120, 60, 0.0, 0.4, 0.05, 5.0, 0.5, 1.0, 0]],
}

const DebrisScript := preload("res://debris.gd")
const Decor := preload("res://effects/s58_decor.gd")

const HIGH_Y := -49.0            # מרכז המגן בהליכה (יחידות ציור, 0 = כפות הרגליים, ראש ~ -50)
const LOW_Y := -25.0             # מרכז המגן בדקירת הוו
const SHIELD_H := 15.0           # חצי גובה הפס שהמגן מכסה
const BONE_HP := 85
const CHIP := 0.6                # כמה מהנזק שנחסם יורד מהמגן
const BLAST_CHIP := 60
const BLAST_MULT := 0.8
const BACK_MULT := 1.3
const OPEN_MULT := 1.25
const LEARN_AROUND := 8
const TRACK_V := 80.0            # (למד) כמה מהר המגן עוקב אחרי הכוונת (יחידות לשנייה)
const TRACK_DELAY := 0.25
const TURN_DELAY := 0.3          # מסתובב אליך באיחור (חלון לגב)
const HOOK_R := Vector2(85.0, 175.0)
const HOOK_WIND := 0.45
const HOOK_T := 0.22
const HOOK_DMG := 1
const HOOK_PULL := 1.0
const SLASH_R := 80.0
const SLASH_WIND := 0.42
const SLASH_DMG := 1
const RECOVER := 0.55
const CD := Vector2(0.5, 1.1)
const RAGE := 1.3                # בלי מגן: מהיר יותר
# בוס
const SKULL_HP := 150
const SKULL_MULT := 0.3
const JAW_HP := 320
const JAW_Y := -24.0
const JAW_H := 17.0
const GROWTH_MULT := 1.6
const B_ARMOR := 0.85
const B_SWEEP_R := 250.0
const B_SWEEP_WIND := 0.55
const B_SWEEP_T := 0.3
const B_SWEEP_DMG := 2
const B_OPEN_MULT := 1.2
const RAM_R := Vector2(260.0, 760.0)
const RAM_WIND := 0.55
const RAM_V := 540.0
const RAM_MAX := 1.5
const RAM_DMG := 2
const RAM_PAST := 240.0
const STUCK_T := 1.7
const STUCK_MULT := 2.0
const THROW_R := 330.0
const THROW_WIND := 0.6
const THROW_CD := 6.0
const CALL_T := 1.2
const CALL_CD := 13.0
const CALL_N := 2
const CALL_MAX := 2
const TURN_T := 0.9
const TURN_T_LEARN := 0.25
const BACK_LEARN := 10
const ARENA_W := 1150.0
const B_CD := Vector2(0.7, 1.4)

enum {WALK, HOOK_W, HOOK, SLASH_W, SLASH, RECOVERY, B_WALK, B_SWEEP_W, B_SWEEP, B_RAM_W, B_RAM, B_STUCK, B_THROW_W, B_CALL, B_RECOVER}
var state := WALK
# לבדיקות
var blocks := 0
var arounds := 0
var back_hits := 0
var hooks := 0
var hook_hits := 0
var slashes := 0
var slash_hits := 0
var breaks := 0
var tracked := 0
var sweeps := 0
var sweep_hits := 0
var rams := 0
var ram_hits := 0
var stucks := 0
var throws := 0
var pulls := 0
var calls := 0
var summoned := 0
var skull_broken := false
var jaw_broken := false
var back_sweeps := 0

var learned := false
var shield_y := HIGH_Y
var _shield_hp := BONE_HP
var _track_y := HIGH_Y          # הגובה שאליו אתה מכוון (מאוחר)
var _aim_hist := []             # [זמן, גובה]
var _st := 0.0
var _cd := 1.0
var _hit := false
var _turn := 0.0
var _hit_back := false
var _hit_blast := false
var _pop_t := 0.0
var _cracks := []               # סדקים במגן [x, y, זווית]
var _var := []                  # [סוודר, סינר, כובע, דם, זקן]
# בוס
var _skull_hp := SKULL_HP
var _jaw_hp := JAW_HP
var _b_cd := 2.0
var _throw_cd := 3.0
var _call_cd := 7.0
var _spawned: Array = []
var _engaged := false
var _ram_dir := 1.0
var _back_learn := false
var _aim_learn := false
var _back_n := 0
var _dust := 0.0
var _ring := -1.0
var _ring_pos := Vector2.ZERO


func _boss() -> bool:
	return z != null and float(z.chase_range) > 600.0


func stats() -> Dictionary:
	if _boss():
		return {"name": "FLENSER", "hp": 470, "walk": 44.0, "chase": 92.0, "damage": 2, "bite_delay": 1.0, "scale": 2.3, "width": 1.2,
			"duck": 0.0, "cover": 0.0, "skin": Color("8c968a"), "shirt": Color("3c3a36"), "pants": Color("2a2c28"), "shoe": Color("1e1c1a"),
			"points": 2800, "boss": true, "boss_name": "THE BONE KING", "ragdoll": false}
	return {"name": "FLENSER", "hp": 72, "walk": 42.0, "chase": 88.0, "damage": 1, "bite_delay": 0.9, "scale": 1.05, "width": 1.08,
		"duck": 0.0, "cover": 0.0, "skin": Color("8f9c8e"), "shirt": Color("8a7e66"), "pants": Color("2e3430"), "shoe": Color("221e1a"), "points": 420}


func brain_overrides() -> Dictionary:
	return {"aggression": 0.6}


func use_brain_movement() -> bool:
	return false


func can_bite() -> bool:
	return false


func _main() -> Node:
	return z.get_parent()


func setup() -> void:
	var m := _main()
	var r := RandomNumberGenerator.new()
	r.seed = z.get_instance_id() * 3 + 11
	var sweaters := [Color("b4a888"), Color("6a665e"), Color("2e3446"), Color("6a2e2a"), Color("8a7e66")]
	var aprons := [Color("6e6232"), Color("2e3a32"), Color("4a3a2a"), Color("7a6a3a")]
	var caps := [Color("2a2e3a"), Color("7a2a24"), Color("3a3a36"), Color("5a6a4a")]
	_var = [sweaters[r.randi() % sweaters.size()], aprons[r.randi() % aprons.size()], caps[r.randi() % caps.size()], r.randf_range(0.3, 1.0), r.randf() < 0.6]
	z.shirt = _var[0]
	if _boss():
		state = B_WALK
		_resize(Vector2(36.0, 60.0))
		z.set_meta("no_cover", true)
	else:
		learned = m != null and int(m.get_meta("fl_around", 0)) >= LEARN_AROUND
		state = WALK
		_resize(Vector2(26.0, 56.0))


func _resize(b: Vector2) -> void:
	var rs := z._shape.shape as RectangleShape2D
	rs.size = Vector2(b.x * z.wf * z.sc, b.y * z.sc)
	z._shape.position = Vector2(0.0, -b.y * 0.5 * z.sc)


func has_shield() -> bool:
	return _shield_hp > 0 and not _boss()


# המגן זז הצידה (פתוח מלפנים)
func _open() -> bool:
	return state == SLASH_W or state == SLASH or state == RECOVERY


# ============================================================
#  תנועה
# ============================================================
func physics(pl: Node, delta: float) -> bool:
	if z.dead:
		return false
	_st -= delta
	_cd -= delta
	_pop_t -= delta
	if not z.is_on_floor():
		z.velocity.y += z.gravity * delta
	var has: bool = pl != null and not pl.dead
	var d: Vector2 = (pl.global_position - z.global_position) if has else Vector2.ZERO
	if _boss():
		_boss_physics(pl, has, d, delta)
		z.move_and_slide()
		return true
	_shield_update(pl, has, d, delta)
	var spd: float = z.chase_speed * (RAGE if not has_shield() else 1.0)
	match state:
		WALK:
			if not has or absf(d.x) > 1300.0:
				z.velocity.x = move_toward(z.velocity.x, 0.0, 600.0 * delta)
			else:
				_face(d, delta)
				var want := spd
				if absf(d.x) < HOOK_R.y and has_shield():   # בטווח: מתקדם לאט מאחורי המגן
					want = maxf(z.walk_speed, z.chase_speed * 0.55)
				var mv: float = z._dir * want if absf(d.x) > SLASH_R * 0.7 else 0.0
				z.velocity.x = move_toward(z.velocity.x, mv, 700.0 * delta)
				z._walk_phase += delta * absf(z.velocity.x) / 7.0
				if z.is_on_floor() and z.is_on_wall() and absf(z.velocity.x) < 30.0:
					z.velocity.y = -470.0
				var facing: bool = signf(d.x) == z._dir
				if _cd <= 0.0 and z.is_on_floor() and facing and absf(d.y) < 70.0:
					if absf(d.x) < SLASH_R:
						_start(SLASH_W, SLASH_WIND)
						Sfx.play("fl_grunt", z.global_position, 0.0, 0.1, 3)
					elif absf(d.x) > HOOK_R.x and absf(d.x) < HOOK_R.y:
						_start(HOOK_W, HOOK_WIND)
						Sfx.play("fl_grunt", z.global_position, -2.0, 0.1, 3)
		HOOK_W:
			z.velocity.x = move_toward(z.velocity.x, 0.0, 1200.0 * delta)
			if _st <= 0.0:
				_start(HOOK, HOOK_T)
				hooks += 1
				_hit = false
				z.velocity.x = z._dir * 160.0
				Sfx.play("fl_hook", z.global_position, 0.0, 0.1, 3)
		HOOK:
			z.velocity.x = move_toward(z.velocity.x, 0.0, 900.0 * delta)
			if has and not _hit:
				var x0: float = z.global_position.x + z._dir * 20.0 * z.sc
				var x1: float = z.global_position.x + z._dir * HOOK_R.y
				var r := Rect2(minf(x0, x1), z.global_position.y - 24.0, absf(x1 - x0), 26.0)
				if r.intersects(pl.body_rect()):
					_hit = true
					if pl._roll_t <= 0.0:
						hook_hits += 1
						pl.slow_t = maxf(pl.slow_t, 0.6)
						z._popup("HOOKED", Color("ffb070"), 13, -70.0)
					pl.hurt(HOOK_DMG, Vector2(-z._dir * HOOK_PULL, -0.1))
			if _st <= 0.0:
				_start(RECOVERY, RECOVER * 0.55)
		SLASH_W:
			z.velocity.x = move_toward(z.velocity.x, 0.0, 1200.0 * delta)
			if has and absf(d.x) > 6.0 and _st > SLASH_WIND * 0.5:
				z._dir = signf(d.x)
			if _st <= 0.0:
				_start(SLASH, 0.16)
				slashes += 1
				_hit = false
				z.velocity.x = z._dir * 120.0
				Sfx.play("fl_slash", z.global_position, 0.0, 0.1, 3)
		SLASH:
			z.velocity.x = move_toward(z.velocity.x, 0.0, 900.0 * delta)
			if has and not _hit:
				var r := Rect2(z.global_position.x + (0.0 if z._dir > 0.0 else -95.0), z.global_position.y - 64.0 * z.sc, 95.0, 64.0 * z.sc)
				if r.intersects(pl.body_rect()):
					_hit = true
					if pl._roll_t <= 0.0:
						slash_hits += 1
					pl.hurt(SLASH_DMG, Vector2(z._dir * 1.1, -0.4))
					z._spray_blood(pl.global_position + Vector2(0, -30), Vector2(z._dir, -0.4), 6, 260.0)
			if _st <= 0.0:
				_start(RECOVERY, RECOVER)
		RECOVERY:
			z.velocity.x = move_toward(z.velocity.x, 0.0, 900.0 * delta)
			if _st <= 0.0:
				state = WALK
				_cd = randf_range(CD.x, CD.y) * (0.7 if not has_shield() else 1.0)
	z.move_and_slide()
	return true


func _start(s: int, t: float) -> void:
	state = s
	_st = t


# מסתובב אליך באיחור קטן (חלון לירות בגב אחרי גלגול)
func _face(d: Vector2, delta: float) -> void:
	if absf(d.x) < 6.0:
		return
	if signf(d.x) != z._dir:
		_turn += delta
		if _turn >= TURN_DELAY:
			z._dir = signf(d.x)
			_turn = 0.0
	else:
		_turn = 0.0


# איפה המגן: גבוה בהליכה, נמוך בוו, בצד כשקוצץ. (למד) עוקב אחרי הגובה שאליו אתה מכוון
func _shield_update(pl: Node, has: bool, d: Vector2, delta: float) -> void:
	var want := HIGH_Y
	match state:
		HOOK_W, HOOK:
			want = LOW_Y
	if learned and has and has_shield() and not _open() and absf(d.x) < 900.0:
		var ay := _aimed_y(pl)
		var now: float = z._time
		_aim_hist.append([now, ay])
		while _aim_hist.size() > 2 and now - float(_aim_hist[0][0]) > TRACK_DELAY:
			_aim_hist.pop_front()
		_track_y = float(_aim_hist[0][1])
		want = clampf(_track_y, -58.0, -14.0)
		if absf(want - shield_y) > 12.0 and Engine.get_physics_frames() % 20 == 0:
			tracked += 1
		var m := _main()
		if m != null and not m.has_meta("fl_said") and absf(d.x) < 700.0 and Art.on_screen(z, z.global_position, -40.0):
			m.set_meta("fl_said", true)
			z._popup("IT READS YOUR AIM NOW", Color("ff8a7a"), 13, -86.0)
			if pl.has_method("_say"):
				pl._say("The bone follows my gun... aim high, then snap low", Color("ff8a7a"))
		shield_y = move_toward(shield_y, want, TRACK_V * delta)
	else:
		shield_y = move_toward(shield_y, want, 140.0 * delta)


# לאיזה גובה (ביחידות ציור של הזומבי) השחקן מכוון כרגע
func _aimed_y(pl: Node) -> float:
	var a: Vector2 = pl._aim
	var o: Vector2 = pl.global_position + Vector2(0, -36)
	var dx: float = z.global_position.x - o.x
	if absf(a.x) < 0.15 or signf(a.x) != signf(dx):
		return HIGH_Y
	var y: float = o.y + a.y * (dx / a.x)
	return (y - z.global_position.y) / z.sc


# ============================================================
#  נזק: המגן
# ============================================================
func on_damage(amount: int, hit_pos: Vector2, dir: Vector2, src: Dictionary) -> bool:
	if z.dead:
		return true
	var s := str(src.get("source", "bullet"))
	_hit_back = false
	_hit_blast = false
	if _boss():
		return _boss_damage(amount, hit_pos, dir, src, s)
	if s == "fire" or s == "hazard":
		return true
	var front: bool = dir.x * z._dir < 0.0
	if not (s == "bullet" or s == "melee"):   # פיצוץ / מלכודת: שובר את העצם, הגוף נפגע פחות מאחורי המגן
		_hit_blast = has_shield() and front
		if has_shield():
			_chip(BLAST_CHIP, hit_pos, dir)
		return true
	if not front:
		_hit_back = true
		back_hits += 1
		return true
	var ly: float = (hit_pos.y - z.global_position.y) / z.sc
	if has_shield() and not _open():
		if absf(ly - shield_y) <= SHIELD_H:
			blocks += 1
			_chip(_chip_dmg(src), hit_pos, dir)
			z._flash = 0.03
			Game.on_zombie_hit({"source": "bullet", "zone": "shield"})
			if _pop_t <= 0.0:
				_pop_t = 0.6
				z._popup("BONE", Color("e8dcc0"), 12, -95.0)
			var m := _main()
			if m != null and int(m.get_meta("fl_blocked", 0)) < 99:
				m.set_meta("fl_blocked", int(m.get_meta("fl_blocked", 0)) + 1)
				if int(m.get_meta("fl_blocked", 0)) == 4:
					var pl := player()
					if pl != null and pl.has_method("_say"):
						pl._say("Whale bone stops bullets... shoot UNDER it", Color("e8dcc0"))
			return false
		# ירייה "מסביב" למגן - זה מה שהם לומדים
		arounds += 1
		var m2 := _main()
		if m2 != null:
			m2.set_meta("fl_around", int(m2.get_meta("fl_around", 0)) + 1)
	return true


# כמה עצם יורדת מפגיעה שנחסמה (לפי הנשק, לא לפי מקום הפגיעה - ירייה בראש לא שוברת מגן מהר יותר)
func _chip_dmg(src: Dictionary) -> int:
	var d := 12.0
	if src.has("fixed"):
		d = float(src.fixed)
	elif src.has("dmg_mult"):
		d = 12.0 * float(src.dmg_mult)
	if src.get("sniper", false):
		d *= 2.0
	if src.get("god", false):
		d *= 4.0
	return maxi(1, int(round(d * CHIP)))


func _chip(n: int, hit_pos: Vector2, dir: Vector2) -> void:
	_shield_hp -= n
	if Art.on_screen(z, hit_pos):
		Sfx.play("fl_chip", hit_pos, -2.0, 0.2, 4)
		for i in Quality.scaled(3, 1.0):
			var c = DebrisScript.new()
			_main().add_child(c)
			c.setup(hit_pos, Vector2(2, 2), Decor.BONE if i % 2 == 0 else Decor.BONE_D, Vector2(-dir.x * randf_range(80, 220), -randf_range(40, 200)))
	if _cracks.size() < 7 and randf() < 0.6:
		_cracks.append([randf_range(-3.0, 6.0), randf_range(-11.0, 11.0), randf_range(-1.2, 1.2)])
	if _shield_hp <= 0:
		_shatter(hit_pos, dir)


func _shatter(at: Vector2, dir: Vector2) -> void:
	breaks += 1
	_shield_hp = 0
	Sfx.play("fl_shatter", at, 2.0, 0.1, 2)
	z._popup("BONE SHATTERS", Color("ffd34a"), 15, -100.0)
	if Art.on_screen(z, at):
		for i in Quality.scaled(9, 1.0):
			var c = DebrisScript.new()
			_main().add_child(c)
			c.setup(at + Vector2(randf_range(-8, 8), randf_range(-12, 12)), Vector2(randf_range(3, 7), randf_range(2, 5)), Decor.BONE if i % 3 != 0 else Decor.BONE_S, Vector2(-dir.x * randf_range(60, 260), -randf_range(80, 300)))
		Particles.burst(_main(), at, "smoke", Vector2(-dir.x, -0.5), 4)
	if state == WALK:
		_cd = minf(_cd, 0.3)


func damage_mult(_zone: String, _src: Dictionary) -> float:
	if _boss():
		return _boss_mult(_zone)
	if _hit_blast:
		return BLAST_MULT
	if _hit_back:
		return BACK_MULT
	if _open():
		return OPEN_MULT
	return 1.0


func on_death() -> void:
	if _boss():
		for w in _spawned:
			if is_instance_valid(w) and not w.dead:
				w.take_damage(999, w.global_position + Vector2(0, -20), Vector2.UP, true, {"source": "hazard", "fixed": 999})
		var cam: Camera2D = z.get_viewport().get_camera_2d()
		if cam != null and cam.has_method("shake"):
			cam.shake(16.0, 0.8)
		Sfx.play("kb_bellow", z.global_position, 2.0, 0.0, 1, 0.7)
		Sfx.play("fl_shatter", z.global_position, 4.0, 0.0, 1, 0.6)
		var m := _main()
		var c0: Vector2 = z.global_position + Vector2(0, -110)
		for i in Quality.scaled(16, 1.0):
			var dbr = DebrisScript.new()
			m.add_child(dbr)
			dbr.setup(c0 + Vector2(randf_range(-40, 40), randf_range(-30, 30)), Vector2(randf_range(4, 10), randf_range(3, 7)), Decor.BONE if i % 2 == 0 else Decor.BONE_D, Vector2(randf_range(-300, 300), -randf_range(120, 420)))
		Particles.burst(m, z.global_position + Vector2(0, -80), "hit", Vector2.UP, int(34.0 * Quality.gore()))
		Particles.burst(m, z.global_position + Vector2(0, -90), "mist", Vector2.UP, 14)
		return
	if has_shield() and Art.on_screen(z, z.global_position):   # המגן נופל
		for i in Quality.scaled(4, 1.0):
			var c = DebrisScript.new()
			_main().add_child(c)
			c.setup(z.global_position + Vector2(z._dir * 10.0, -40.0 * z.sc), Vector2(randf_range(4, 8), randf_range(3, 6)), Decor.BONE, Vector2(z._dir * randf_range(-60, 120), -randf_range(60, 200)))


# ============================================================
#  בוס: THE BONE KING
# ============================================================
func _boss_physics(pl: Node, has: bool, d: Vector2, delta: float) -> void:
	_b_cd -= delta
	_throw_cd -= delta
	_call_cd -= delta
	if _ring >= 0.0:
		_ring += delta
		if _ring > 0.5:
			_ring = -1.0
	var met: bool = has and (_engaged or absf(d.x) < z.chase_range or z._alert_t > 0.0)
	if met:
		_engaged = true
	# הלסת: למטה כשהוא פתוח, (למד) עוקבת אחרי הכוונת
	var want := JAW_Y
	if _aim_learn and has and state == B_WALK:
		want = clampf(_aimed_y(pl), -40.0, -14.0)
	shield_y = move_toward(shield_y, want, (TRACK_V * 0.8 if _aim_learn else 120.0) * delta)
	if not _aim_learn and z.hp < z.max_hp / 2:
		_aim_learn = true
		z._popup("IT READS YOUR AIM NOW", Color("ff8a7a"), 18, -150.0)
		if has and pl.has_method("_say"):
			pl._say("The jaw follows my aim... feint it, or get behind him", Color("ff8a7a"))
	match state:
		B_WALK:
			if not met:
				z.velocity.x = move_toward(z.velocity.x, 0.0, 500.0 * delta)
				return
			_boss_turn(d, delta)
			var mv: float = z._dir * z.chase_speed if absf(d.x) > 140.0 else 0.0
			z.velocity.x = move_toward(z.velocity.x, mv, 500.0 * delta)
			z._walk_phase += delta * absf(z.velocity.x) / 12.0
			_keep_arena()
			if z.is_on_floor() and z.is_on_wall() and absf(z.velocity.x) < 30.0 and absf(d.x) > 140.0:   # קופץ מעל חביות
				z.velocity.y = -640.0
			if _b_cd <= 0.0 and z.is_on_floor():
				var facing: bool = signf(d.x) == z._dir
				if _call_cd <= 0.0 and _alive_spawned() < CALL_MAX:
					_start(B_CALL, CALL_T)
					calls += 1
					_call_cd = CALL_CD
					Sfx.play("kb_bellow", z.global_position, 4.0, 0.05, 1)
					_shake(9.0, 0.8)
				elif not facing:
					pass
				elif absf(d.x) < B_SWEEP_R and absf(d.y) < 90.0:
					_start(B_SWEEP_W, B_SWEEP_WIND)
				elif absf(d.x) > THROW_R and _throw_cd <= 0.0 and (randf() < 0.5 or absf(d.x) > RAM_R.y):
					_start(B_THROW_W, THROW_WIND)
					_throw_cd = THROW_CD
				elif absf(d.x) > RAM_R.x and absf(d.x) < RAM_R.y and absf(d.y) < 90.0:
					_start(B_RAM_W, RAM_WIND)
					_ram_dir = z._dir
					Sfx.play("kb_bellow", z.global_position, 0.0, 0.1, 1, 1.4)
		B_SWEEP_W:
			z.velocity.x = move_toward(z.velocity.x, 0.0, 1400.0 * delta)
			if _st <= 0.0:
				_start(B_SWEEP, B_SWEEP_T)
				sweeps += 1
				_hit = false
				z.velocity.x = z._dir * 140.0
				Sfx.play("kb_sweep", z.global_position, 3.0, 0.1, 2)
		B_SWEEP:
			z.velocity.x = move_toward(z.velocity.x, 0.0, 900.0 * delta)
			_sweep_hit(pl, has, z._dir)
			if _st <= 0.0:
				_dust_ring()
				_start(B_RECOVER, 0.7)
		B_RAM_W:
			z.velocity.x = move_toward(z.velocity.x, -_ram_dir * 30.0, 1200.0 * delta)
			_dust -= delta
			if _dust <= 0.0 and Art.on_screen(z, z.global_position):
				_dust = 0.1
				Particles.burst(_main(), z.global_position + Vector2(-_ram_dir * 20.0, -4), "smoke", Vector2(-_ram_dir, -0.5), 2)
			if _st <= 0.0:
				_start(B_RAM, RAM_MAX)
				rams += 1
				_hit = false
				Sfx.play("kb_ram", z.global_position, 3.0, 0.05, 2)
		B_RAM:
			z.velocity.x = _ram_dir * RAM_V
			z._walk_phase += delta * 22.0
			_dust -= delta
			if _dust <= 0.0 and Art.on_screen(z, z.global_position):
				_dust = 0.06
				Particles.burst(_main(), z.global_position + Vector2(-_ram_dir * 30.0, -4), "smoke", Vector2(-_ram_dir, -0.6), 2)
			if has and not _hit:
				var me := Rect2(z.global_position + Vector2(-50.0, -130.0), Vector2(100.0, 130.0))
				if me.intersects(pl.body_rect()):
					_hit = true
					if pl._roll_t <= 0.0:
						ram_hits += 1
					pl.hurt(RAM_DMG, Vector2(_ram_dir * 2.4, -0.8))
			var bx: float = z.global_position.x
			var edge: bool = (_ram_dir < 0.0 and bx < z.world_w - ARENA_W) or (_ram_dir > 0.0 and bx > z.world_w - 80.0)
			var wall: bool = z.is_on_wall() and _st < RAM_MAX - 0.12
			var past: bool = has and (bx - pl.global_position.x) * _ram_dir > RAM_PAST
			if wall or edge:   # נתקע עם הגולגולת במכשול / בגדר
				stucks += 1
				_start(B_STUCK, STUCK_T)
				z.velocity.x = -_ram_dir * 80.0
				Sfx.play("kb_crunch", z.global_position, 4.0, 0.05, 2)
				_shake(10.0, 0.35)
				if Art.on_screen(z, z.global_position):
					Particles.burst(_main(), z.global_position + Vector2(_ram_dir * 50.0, -90), "smoke", Vector2(-_ram_dir, -0.4), 8)
				if stucks == 1:
					z._popup("STUCK - HIT HIS BACK", Color("ffd34a"), 15, -150.0)
			elif _st <= 0.0 or past:
				_start(B_RECOVER, 0.6)
		B_STUCK:
			z.velocity.x = move_toward(z.velocity.x, 0.0, 600.0 * delta)
			if _st <= 0.0:
				_start(B_RECOVER, 0.3)
		B_THROW_W:
			z.velocity.x = move_toward(z.velocity.x, 0.0, 1400.0 * delta)
			if has and absf(d.x) > 6.0:
				z._dir = signf(d.x)
			if _st <= 0.0:
				_throw(pl, has)
				_start(B_RECOVER, 0.6)
		B_CALL:
			z.velocity.x = move_toward(z.velocity.x, 0.0, 1400.0 * delta)
			if _st < CALL_T * 0.5 and _st + delta >= CALL_T * 0.5:
				_summon(pl)
			if _st <= 0.0:
				_start(B_RECOVER, 0.2)
		B_RECOVER:
			z.velocity.x = move_toward(z.velocity.x, 0.0, 900.0 * delta)
			if _st <= 0.0:
				state = B_WALK
				_b_cd = randf_range(B_CD.x, B_CD.y)


# מסתובב לאט (TURN_T). למד: מהר, ומטאטא אחורה כשאתה מאחוריו
func _boss_turn(d: Vector2, delta: float) -> void:
	if absf(d.x) < 8.0 or signf(d.x) == z._dir:
		_turn = 0.0
		return
	_turn += delta
	if _back_learn and absf(d.x) < B_SWEEP_R * 0.9 and absf(d.y) < 90.0:
		if _turn >= TURN_T_LEARN:
			z._dir = signf(d.x)
			_turn = 0.0
			back_sweeps += 1
			_start(B_SWEEP_W, B_SWEEP_WIND * 0.55)
		return
	if _turn >= (TURN_T_LEARN if _back_learn else TURN_T):
		z._dir = signf(d.x)
		_turn = 0.0


func _keep_arena() -> void:
	var bx: float = z.global_position.x
	if bx < z.world_w - ARENA_W and z.velocity.x < 0.0:
		z.velocity.x = 0.0
	if bx > z.world_w - 70.0 and z.velocity.x > 0.0:
		z.velocity.x = 0.0


func _sweep_hit(pl: Node, has: bool, dirx: float) -> void:
	if not has or _hit:
		return
	var x0: float = z.global_position.x - dirx * 20.0
	var x1: float = z.global_position.x + dirx * B_SWEEP_R
	var r := Rect2(minf(x0, x1), z.global_position.y - 40.0, absf(x1 - x0), 40.0)
	if r.intersects(pl.body_rect()):
		_hit = true
		if pl._roll_t <= 0.0:
			sweep_hits += 1
		pl.hurt(B_SWEEP_DMG, Vector2(dirx * 2.0, -0.9))


func _dust_ring() -> void:
	_ring = 0.0
	_ring_pos = z.global_position + Vector2(z._dir * B_SWEEP_R * 0.5, 0)
	if Art.on_screen(z, z.global_position):
		Particles.burst(_main(), _ring_pos + Vector2(0, -4), "smoke", Vector2(z._dir, -0.4), 6)


func _throw(pl: Node, has: bool) -> void:
	throws += 1
	var from: Vector2 = z.global_position + Vector2(z._dir * 30.0, -120.0)
	var to: Vector2 = (pl.global_position + Vector2(0, -30)) if has else from + Vector2(z._dir * 400.0, 60.0)
	var v: Vector2 = (to - from).normalized()
	if v.x * z._dir < 0.2:
		v = Vector2(z._dir, 0.1).normalized()
	var hp := Decor.Harpoon.new()
	hp.thrower = z
	hp.pull = 1.9
	hp.dmg = 1
	hp.vel = v * 860.0
	_main().add_child(hp)
	hp.global_position = from
	Sfx.play("fl_hook", z.global_position, 4.0, 0.05, 2, 0.6)


# הצלצל פגע: נמשכת אליו - והוא מתחיל לטאטא
func harpoon_hit(_pl: Node) -> void:
	pulls += 1
	if pulls == 1:
		z._popup("REELED IN", Color("ffb070"), 15, -150.0)
	if state == B_RECOVER or state == B_WALK:
		_start(B_RECOVER, 0.35)
		_b_cd = 0.0


func _alive_spawned() -> int:
	var n := 0
	for w in _spawned:
		if is_instance_valid(w) and not w.dead:
			n += 1
	return n


func _summon(pl: Node) -> void:
	var m := _main()
	if m == null or not m.has_method("_spawn_zombie"):
		return
	for i in CALL_N:
		if _alive_spawned() >= CALL_MAX:
			return
		var side := 1.0 if i % 2 == 0 else -1.0
		var x: float = z.global_position.x + side * randf_range(260.0, 380.0)
		if pl != null:
			x = clampf(x, pl.global_position.x - 520.0, pl.global_position.x + 520.0)
		x = clampf(x, z.world_w - 1080.0, z.world_w - 120.0)
		var w = m._spawn_zombie(x, z.global_position.y, z.kind)
		if w == null:
			continue
		w.dormant = false
		_spawned.append(w)
		summoned += 1
		Particles.burst(m, Vector2(x, z.global_position.y - 20.0), "smoke", Vector2.UP, 8)
		Sfx.play("fl_chip", Vector2(x, z.global_position.y), 2.0, 0.1, 2)


func _shake(a: float, t: float) -> void:
	var cam: Camera2D = z.get_viewport().get_camera_2d()
	if cam != null and cam.has_method("shake"):
		cam.shake(a, t)


func _jaw_up() -> bool:
	return not jaw_broken and state in [B_WALK, B_RAM_W, B_RAM, B_THROW_W]


func _boss_damage(amount: int, hit_pos: Vector2, dir: Vector2, src: Dictionary, s: String) -> bool:
	var front: bool = dir.x * z._dir < 0.0
	if s == "fire" or s == "hazard":
		return true
	if not (s == "bullet" or s == "melee"):   # פיצוץ: סודק גולגולת ולסת
		_hit_blast = true
		_skull_chip(40, hit_pos, dir)
		if front:
			_jaw_chip(50, hit_pos, dir)
		return true
	var ly: float = (hit_pos.y - z.global_position.y) / z.sc
	if not front:
		_hit_back = ly > -46.0
		if _hit_back:
			back_hits += 1
			_back_n += 1
			if not _back_learn and _back_n >= BACK_LEARN:
				_back_learn = true
				z._popup("IT GUARDS ITS BACK NOW", Color("ff8a7a"), 18, -150.0)
				var pl := player()
				if pl != null and pl.has_method("_say"):
					pl._say("He turns faster now... hit him while he's stuck", Color("ff8a7a"))
		return true
	if ly < -40.0 and not skull_broken:   # הקסדה
		_skull_chip(maxi(1, int(round(float(hit_damage(amount, hit_pos, src)) * 0.5))), hit_pos, dir)
		return true
	if _jaw_up() and absf(ly - shield_y) <= JAW_H:
		blocks += 1
		_jaw_chip(_chip_dmg(src), hit_pos, dir)
		Game.on_zombie_hit({"source": "bullet", "zone": "shield"})
		z._flash = 0.03
		if _pop_t <= 0.0:
			_pop_t = 0.7
			z._popup("JAWBONE", Color("e8dcc0"), 13, -150.0)
		return false
	return true


func _skull_chip(n: int, at: Vector2, dir: Vector2) -> void:
	if skull_broken:
		return
	_skull_hp -= n
	if Art.on_screen(z, at):
		Sfx.play("fl_chip", at, 0.0, 0.2, 3, 0.8)
		var c = DebrisScript.new()
		_main().add_child(c)
		c.setup(at, Vector2(3, 3), Decor.BONE, Vector2(-dir.x * randf_range(80, 220), -randf_range(60, 220)))
	if _skull_hp <= 0:
		skull_broken = true
		z._popup("SKULL BROKEN", Color("ffd34a"), 20, -160.0)
		Sfx.play("fl_shatter", at, 4.0, 0.0, 1, 0.7)
		_shake(8.0, 0.3)
		for i in Quality.scaled(12, 1.0):
			var dbr = DebrisScript.new()
			_main().add_child(dbr)
			dbr.setup(at + Vector2(randf_range(-20, 20), randf_range(-14, 14)), Vector2(randf_range(4, 9), randf_range(3, 6)), Decor.BONE if i % 2 == 0 else Decor.BONE_D, Vector2(-dir.x * randf_range(60, 280), -randf_range(100, 340)))
		var pl := player()
		if pl != null and pl.has_method("_say"):
			pl._say("The skull's off - GO FOR THE HEAD", Color("ffd34a"))


func _jaw_chip(n: int, at: Vector2, dir: Vector2) -> void:
	if jaw_broken:
		return
	_jaw_hp -= n
	if Art.on_screen(z, at):
		Sfx.play("fl_chip", at, -1.0, 0.2, 4, 0.7)
		var c = DebrisScript.new()
		_main().add_child(c)
		c.setup(at, Vector2(3, 2), Decor.BONE_D, Vector2(-dir.x * randf_range(80, 220), -randf_range(40, 200)))
	if _cracks.size() < 7 and randf() < 0.3:
		_cracks.append([randf_range(-2.0, 2.0), randf_range(-14.0, 14.0), randf_range(-1.2, 1.2)])
	if _jaw_hp <= 0:
		jaw_broken = true
		breaks += 1
		z._popup("JAW BROKEN", Color("ffd34a"), 20, -150.0)
		Sfx.play("fl_shatter", at, 4.0, 0.0, 1, 0.8)
		_shake(8.0, 0.3)
		for i in Quality.scaled(12, 1.0):
			var dbr = DebrisScript.new()
			_main().add_child(dbr)
			dbr.setup(at + Vector2(randf_range(-10, 10), randf_range(-30, 30)), Vector2(randf_range(4, 10), randf_range(3, 6)), Decor.BONE if i % 2 == 0 else Decor.BONE_S, Vector2(-dir.x * randf_range(60, 280), -randf_range(80, 320)))


func _boss_mult(zone: String) -> float:
	if _hit_blast:
		return B_ARMOR
	if zone == "head" and not skull_broken:
		return SKULL_MULT
	if _hit_back:
		return STUCK_MULT if state == B_STUCK else GROWTH_MULT
	if state in [B_SWEEP_W, B_SWEEP, B_RECOVER, B_CALL, B_STUCK] or jaw_broken:
		return B_OPEN_MULT
	return B_ARMOR


func wants_redraw() -> bool:
	return true


# ============================================================
#  ציור: סוודר צמר, סינר שעוונית מגואל, כובע גרב, מגפיים עם דורבנות. מוט עם סכין הפשטה מעוקלת ביד האחורית,
#  עצם שכמה של לווייתן קשורה לאמה הקדמית (סדקים לפי הנזק, כתמי ECHO זוהרים). הבוס: גולגולת לווייתן כקסדה (חרטום ארוך),
#  לסת לווייתן כמגן, גלימת עור כלב ים, צלצלים תקועים בגב וגידול ECHO זוהר על הגב.
# ============================================================
func draw() -> bool:
	if _var.is_empty():
		return false
	if _boss():
		return _draw_boss()
	begin_draw()
	var tt: float = z._time
	var sweater := col(_var[0])
	var apron := col(_var[1])
	var skin := col(z.skin)
	var blood: float = _var[3]
	var f: Array = feet(4.6, 2.4)
	var lean := 0.0
	match state:
		HOOK_W:
			lean = -2.0
		HOOK:
			lean = 4.0
		SLASH_W:
			lean = -1.5
		SLASH:
			lean = 5.0
	var bob := absf(sin(z._walk_phase)) * 1.0
	var hip := Vector2(0, -22.0 + bob * 0.4)
	var sh := Vector2(1.0 + lean, -40.0 + bob * 0.5)
	var head := sh + Vector2(2.5 + lean * 0.3, -10.0)
	# רגליים (שעוונית) + מגפיים עם דורבנות
	for i in 2:
		var ft: Vector2 = f[i]
		var hp := hip + Vector2(-2.5 + float(i) * 4.0, 0)
		z._leg(hp, ft, col(Art.shade(z.pants, 0.18 if i == 0 else 0.0)), skin, col(z.shoe))
		DrawBatch.line(z, ft + Vector2(-3.5, -5.5), ft + Vector2(4.0, -5.5), col(Color("3a3430")), 1.2)
		for q in 3:
			DrawBatch.circle(z, ft + Vector2(-2.5 + float(q) * 3.0, 0.8), 0.7, col(Color("9a948a")))
	# יד אחורית + מוט ההפשטה
	var pole := _pole_pose(sh, tt)
	var hand_b: Vector2 = pole[0]
	z._arm(sh + Vector2(-3.0, 1.5), hand_b, skin, col(Art.shade(_var[0], -0.18)))
	_pole(hand_b, pole[1], pole[2], pole[3])
	# גוף: סוודר צמר עבה
	var torso := PackedVector2Array([sh + Vector2(-8.0, -1.0), sh + Vector2(7.5, -1.5), hip + Vector2(7.0, 1.0), hip + Vector2(-7.5, 1.0)])
	Art.fill_shaded(z, torso, sweater, 0.12, 0.25)
	for q in 4:   # צמות סריגה
		var y := sh.y + 3.0 + float(q) * 4.2
		DrawBatch.line(z, Vector2(sh.x - 5.0, y), Vector2(sh.x + 5.0, y + 0.6), col(Art.shade(_var[0], -0.12)), 0.9)
	DrawBatch.line(z, sh + Vector2(-5.0, -1.0), sh + Vector2(5.0, -1.4), col(Art.shade(_var[0], 0.15)), 2.2)   # צווארון
	# סינר שעוונית (מגואל בדם ובשומן)
	var ap := PackedVector2Array([sh + Vector2(1.0, 3.0), sh + Vector2(9.0, 3.5), hip + Vector2(10.5, 12.0), hip + Vector2(1.5, 12.5)])
	Art.fill(z, ap, apron, Art.OUTLINE, 1.0)
	DrawBatch.line(z, sh + Vector2(1.5, 3.0), sh + Vector2(-5.0, 0.0), col(Art.shade(_var[1], -0.2)), 1.0)
	Art.oval(z, hip + Vector2(6.0, -4.0), 2.6 * blood + 1.2, 4.5 * blood + 1.5, Color(0.42, 0.06, 0.05, 0.85), 0.2, Art.NONE)
	Art.oval(z, sh + Vector2(6.0, 8.0), 1.8, 1.4 + blood * 1.5, Color(0.5, 0.06, 0.05, 0.8), 0.0, Art.NONE)
	DrawBatch.line(z, hip + Vector2(7.0, 2.0), hip + Vector2(7.5, 11.0 * blood + 2.0), Color(0.45, 0.04, 0.04, 0.8), 1.0)
	Art.oval(z, hip + Vector2(3.0, 6.0), 2.2, 1.0, col(Color(0.85, 0.82, 0.62, 0.7)), 0.3, Art.NONE)   # שומן
	# ראש: כובע גרב, זקן
	z._head(head, skin)
	face(head)
	if _var[4]:
		DrawBatch.colored_polygon(z, PackedVector2Array([head + Vector2(-1.0, 2.0), head + Vector2(5.0, 2.5), head + Vector2(3.5, 6.5), head + Vector2(0.0, 5.5)]), col(Color("4a4440")))
	var cap := col(_var[2])
	DrawBatch.colored_polygon(z, PackedVector2Array([head + Vector2(-6.0, -1.5), head + Vector2(5.5, -2.5), head + Vector2(4.0, -6.5), head + Vector2(-1.0, -8.5), head + Vector2(-5.5, -6.0)]), cap)
	DrawBatch.line(z, head + Vector2(-6.0, -1.8), head + Vector2(5.5, -2.8), col(Art.shade(_var[2], 0.2)), 1.8)
	if not z.dead:
		var ec := _eye_col()
		DrawBatch.circle(z, head + Vector2(3.5, -0.5), 1.0, ec)
		Art.glow(z, head + Vector2(3.5, -0.5), 4.0 if not learned else 6.0, Color(ec, 0.35))
	# יד קדמית + המגן
	var sc_c := _shield_center(sh)
	z._arm(sh + Vector2(3.0, 1.5), sc_c + Vector2(-2.0, 2.0), skin, col(Art.shade(_var[0], 0.05)))
	if has_shield():
		_scapula(sc_c, _open(), tt)
	elif not z.dead:   # שבר שנשאר קשור לאמה
		DrawBatch.colored_polygon(z, PackedVector2Array([sc_c + Vector2(-2, -4), sc_c + Vector2(4, -6), sc_c + Vector2(5, 3), sc_c + Vector2(0, 4)]), col(Decor.BONE_D))
		DrawBatch.line(z, sc_c + Vector2(-3, 0), sc_c + Vector2(4, 1), col(Color("5a4a36")), 1.2)
	if not z.dead and (state == SLASH_W or state == HOOK_W):
		var k := clampf(_st / (SLASH_WIND if state == SLASH_W else HOOK_WIND), 0.0, 1.0)
		DrawBatch.string(z, ThemeDB.fallback_font, head + Vector2(-2, -12), "!", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(1.0, 0.35, 0.2, k))
	end_draw()
	return true


func _eye_col() -> Color:
	var lf := 0.0
	if z.has_meta("s57_learned_t"):
		lf = clampf(1.0 - float(Time.get_ticks_msec() - int(z.get_meta("s57_learned_t"))) / 600.0, 0.0, 1.0)
	return Color(1.0, 0.25, 0.15).lerp(Color(0.6, 1.0, 0.75), lf)


func _shield_center(sh: Vector2) -> Vector2:
	if _open():
		var k := 1.0
		if state == SLASH_W:
			k = clampf(1.0 - _st / SLASH_WIND, 0.0, 1.0) * 1.6
		return Vector2(lerpf(10.0, -3.0, minf(k, 1.0)), lerpf(shield_y, -30.0, minf(k, 1.0)))
	return Vector2(10.5 + (sh.x - 1.0) * 0.5, shield_y)


# [יד, זווית, אורך קדימה, אורך אחורה]
func _pole_pose(sh: Vector2, tt: float) -> Array:
	match state:
		HOOK_W:
			var k := clampf(1.0 - _st / HOOK_WIND, 0.0, 1.0)
			return [sh + Vector2(-10.0 - 4.0 * k, 14.0), 0.18, 56.0 - 14.0 * k, 34.0 + 14.0 * k]
		HOOK:
			var k2 := clampf(1.0 - _st / HOOK_T, 0.0, 1.0)
			return [sh + Vector2(6.0, 14.0), 0.2, 70.0 + 70.0 * sin(k2 * PI * 0.5), 20.0]
		SLASH_W:
			var k3 := clampf(1.0 - _st / SLASH_WIND, 0.0, 1.0)
			return [sh + Vector2(1.0, -14.0 * k3 - 2.0), lerpf(-1.2, -2.5, k3), 50.0, 16.0]
		SLASH:
			return [sh + Vector2(10.0, 4.0), 0.75, 58.0, 14.0]
		RECOVERY:
			var k4 := clampf(_st / RECOVER, 0.0, 1.0)
			return [sh + Vector2(4.0, 10.0), lerpf(-1.15, 0.6, k4), 56.0, 18.0]
	return [sh + Vector2(-4.0, 11.0 + sin(z._walk_phase) * 0.8), -1.15 + sin(tt * 1.3) * 0.03, 56.0, 18.0]


# מוט עץ ארוך עם סכין הפשטה מעוקלת (כמו מקל הוקי) בקצה
func _pole(hand: Vector2, ang: float, fwd: float, back: float) -> void:
	var dv := Vector2(cos(ang), sin(ang))
	var tip := hand + dv * fwd
	var butt := hand - dv * back
	DrawBatch.line(z, butt, tip, col(Color("2a2018")), 3.0)
	DrawBatch.line(z, butt, tip, col(Color("6a5038")), 1.8)
	var nv := Vector2(-dv.y, dv.x)   # (למטה מהמוט)
	if dv.x < 0.0:
		nv = -nv
	var b0 := tip
	var b1 := tip + dv * 9.0 + nv * 1.5
	var b2 := tip + dv * 14.0 + nv * 6.5
	var b3 := tip + dv * 10.0 + nv * 8.5
	var b4 := tip + dv * 5.0 + nv * 3.0
	DrawBatch.colored_polygon(z, PackedVector2Array([b0 - nv * 1.2, b1 - nv * 1.0, b2, b3, b4]), col(Color("8a8680")))
	DrawBatch.line(z, b1 - nv * 1.0, b2, col(Color("d8d4cc")), 0.8)   # להב
	DrawBatch.line(z, b0, b4, Color(0.45, 0.05, 0.04, 0.85), 1.2)     # דם
	DrawBatch.line(z, tip - dv * 3.0, tip + dv * 1.0, col(Color("3a3632")), 3.4)   # טבעת


# עצם שכמה של לווייתן: צלחת מניפה עם צוואר, קשורה בחבלים. c = מרכז
func _scapula(c: Vector2, open: bool, tt: float) -> void:
	var bone := col(Decor.BONE)
	var dk := col(Decor.BONE_D)
	if open:   # מהצד: צר
		var pts := PackedVector2Array([c + Vector2(-2.0, -15.0), c + Vector2(2.0, -14.0), c + Vector2(2.5, 14.0), c + Vector2(-1.5, 15.0)])
		DrawBatch.colored_polygon(z, pts, dk)
		DrawBatch.line(z, c + Vector2(0.5, -14.0), c + Vector2(0.5, 14.0), bone, 1.0)
		return
	var h := SHIELD_H
	var pts2 := PackedVector2Array([c + Vector2(-4.0, -h), c + Vector2(4.0, -h - 1.5), c + Vector2(8.5, -h + 4.0), c + Vector2(7.5, 2.0),
		c + Vector2(4.0, h - 2.0), c + Vector2(2.0, h + 1.0), c + Vector2(-1.0, h - 1.0), c + Vector2(-3.0, 4.0), c + Vector2(-5.0, -h + 5.0)])
	Art.fill(z, pts2, bone, Art.OUTLINE, 1.0)
	DrawBatch.colored_polygon(z, PackedVector2Array([c + Vector2(-1.0, -h + 2.0), c + Vector2(5.0, -h + 1.0), c + Vector2(6.0, -2.0), c + Vector2(2.0, 4.0)]), col(Color(0.94, 0.9, 0.8)))
	DrawBatch.line(z, c + Vector2(1.0, -h + 1.0), c + Vector2(2.5, h - 2.0), dk, 1.4)   # רכס העצם
	DrawBatch.circle(z, c + Vector2(2.2, h - 0.5), 2.0, dk)   # מפרק
	for k in _cracks:
		var p0: Vector2 = c + Vector2(float(k[0]), float(k[1]))
		var a: float = k[2]
		DrawBatch.line(z, p0, p0 + Vector2(cos(a), sin(a)) * 4.0, col(Decor.BONE_S), 0.8)
		DrawBatch.line(z, p0, p0 + Vector2(cos(a + 2.2), sin(a + 2.2)) * 2.5, col(Decor.BONE_S), 0.6)
	# כתמי ECHO זוהרים (עדינים)
	var pulse := 0.6 + 0.4 * sin(tt * 3.0)
	DrawBatch.circle(z, c + Vector2(5.0, -6.0), 1.4, Color(Decor.SPORE, 0.7 * pulse))
	DrawBatch.circle(z, c + Vector2(-2.0, 6.0), 1.0, Color(Decor.SPORE, 0.6 * pulse))
	# חבלים
	DrawBatch.line(z, c + Vector2(-4.5, -4.0), c + Vector2(8.0, -5.0), col(Color("6a5638")), 1.3)
	DrawBatch.line(z, c + Vector2(-3.5, 5.0), c + Vector2(6.5, 4.0), col(Color("6a5638")), 1.3)


# ============================================================
#  ציור הבוס
# ============================================================
func _draw_boss() -> bool:
	begin_draw()
	var tt: float = z._time
	var skin := col(z.skin)
	var cloak := col(Color("4a4a4c"))
	var f: Array = feet(4.2, 2.0)
	var lean := 0.0
	var crouch := 0.0
	match state:
		B_SWEEP_W:
			lean = -3.0
			crouch = 2.0
		B_SWEEP:
			lean = 5.0
			crouch = 3.0
		B_RAM_W:
			lean = 4.0
			crouch = 4.0
		B_RAM:
			lean = 8.0
			crouch = 3.0
		B_STUCK:
			lean = 9.0 + sin(tt * 18.0) * 1.0
			crouch = 2.0
		B_THROW_W:
			lean = -3.0
		B_CALL:
			lean = -2.0 + sin(tt * 9.0) * 0.5
	var hip := Vector2(0, -23.0 + crouch)
	var sh := Vector2(1.0 + lean, -42.0 + crouch * 1.4)
	var head := sh + Vector2(3.0 + lean * 0.3, -10.0)
	# רגליים עבות
	for i in 2:
		var ft: Vector2 = f[i]
		var hp := hip + Vector2(-3.5 + float(i) * 5.5, 0)
		z._leg(hp, ft, col(Art.shade(z.pants, 0.15 if i == 0 else 0.0)), skin, col(z.shoe))
		DrawBatch.line(z, ft + Vector2(-4.0, -6.0), ft + Vector2(4.5, -6.0), col(Color("2a2420")), 1.4)
	# גלימת עור כלב ים מאחור + גידול ECHO על הגב
	var cl := PackedVector2Array([sh + Vector2(-2.0, -3.0), sh + Vector2(-13.0, 2.0), hip + Vector2(-13.0, 14.0), hip + Vector2(-3.0, 12.0)])
	Art.fill(z, cl, cloak, Art.OUTLINE, 1.0)
	for q in 4:   # תפרים
		var p0 := sh.lerp(hip, 0.2 + float(q) * 0.2) + Vector2(-9.0, 2.0)
		DrawBatch.line(z, p0, p0 + Vector2(2.0, 1.0), col(Color("8a8070")), 0.6)
	var pulse := 0.6 + 0.4 * sin(tt * 2.6)
	var g0 := sh.lerp(hip, 0.4) + Vector2(-10.0, 0.0)
	Art.glow(z, g0, 16.0 * pulse + 6.0, Color(Decor.SPORE, 0.28))
	for q in 5:
		var gp := g0 + Vector2(-2.0 + float(q % 3) * 2.2, -7.0 + float(q) * 3.4)
		Art.oval(z, gp, 2.6 + float(q % 2), 2.0 + float(q % 2), col(Decor.SPORE_D), 0.0, Art.NONE)
		DrawBatch.circle(z, gp + Vector2(-0.5, -0.5), 1.0 + 0.4 * float(q % 2), Color(Decor.SPORE, 0.9 * pulse))
	# צלצלים תקועים בגב
	for q in 2:
		var hb := sh + Vector2(-6.0, 4.0 + float(q) * 7.0)
		DrawBatch.line(z, hb, hb + Vector2(-16.0, -10.0 + float(q) * 4.0), col(Color("4a4440")), 1.4)
		DrawBatch.line(z, hb, hb + Vector2(2.0, 1.0), Color(0.45, 0.05, 0.04, 0.8), 1.6)
	# יד אחורית: צלצל / סכין
	var hand_b: Vector2
	match state:
		B_THROW_W:
			var k := clampf(1.0 - _st / THROW_WIND, 0.0, 1.0)
			hand_b = sh + Vector2(-8.0 - 6.0 * k, -10.0 - 6.0 * k)
		B_CALL:
			hand_b = sh + Vector2(-10.0, -14.0)
		B_RAM, B_RAM_W, B_STUCK:
			hand_b = sh + Vector2(-9.0, 10.0)
		_:
			hand_b = sh + Vector2(-5.0, 12.0 + sin(z._walk_phase) * 1.0)
	z._arm(sh + Vector2(-3.0, 2.0), hand_b, skin, cloak)
	if state == B_THROW_W:
		_pole(hand_b, -0.15, 34.0, 26.0)
	elif state != B_CALL:
		_pole(hand_b, -1.1, 48.0, 14.0)
	# גוף: חזה חשוף ותפור, רצועות
	var torso := PackedVector2Array([sh + Vector2(-8.5, -1.5), sh + Vector2(8.5, -2.0), hip + Vector2(8.0, 1.0), hip + Vector2(-8.0, 1.0)])
	Art.fill_shaded(z, torso, skin, 0.1, 0.3)
	DrawBatch.line(z, sh + Vector2(1.0, 1.0), hip + Vector2(2.0, -2.0), col(Color("3a2a2a")), 0.8)   # תפר
	for q in 4:
		var sp := sh.lerp(hip, 0.15 + float(q) * 0.2) + Vector2(1.5, 0)
		DrawBatch.line(z, sp + Vector2(-1.2, -0.4), sp + Vector2(1.4, 0.4), col(Color("3a2a2a")), 0.6)
	DrawBatch.line(z, sh + Vector2(-7.0, 0.0), hip + Vector2(7.0, -4.0), col(Color("3a2c22")), 2.0)   # רצועה
	Art.oval(z, sh.lerp(hip, 0.6) + Vector2(4.0, 0.0), 3.0, 2.0, Color(0.42, 0.05, 0.05, 0.8), 0.2, Art.NONE)
	# חגורה עם חוליות
	DrawBatch.line(z, hip + Vector2(-8.0, -1.0), hip + Vector2(8.0, -1.0), col(Color("2a2420")), 2.4)
	for q in 3:
		DrawBatch.circle(z, hip + Vector2(-5.0 + float(q) * 5.0, -1.0), 1.4, col(Decor.BONE_D))
	# ראש + קסדת גולגולת
	z._head(head, skin)
	face(head, Vector2(INF, INF) if not skull_broken else Vector2(3.5, -0.5))
	if not skull_broken:
		_skull_helm(head, tt)
	elif not z.dead:
		Art.glow(z, head + Vector2(3.5, -0.5), 6.0, Color(1.0, 0.3, 0.15, 0.5))
		DrawBatch.colored_polygon(z, PackedVector2Array([head + Vector2(-6.0, -3.0), head + Vector2(-2.0, -8.0), head + Vector2(-5.0, -9.0)]), col(Decor.BONE_D))
	# יד קדמית + לסת הלווייתן
	var jc := _jaw_center(sh)
	z._arm(sh + Vector2(3.0, 2.0), jc + Vector2(-3.0, 0.0), skin, cloak)
	if not jaw_broken:
		_jaw(jc, tt)
	if not z.dead and state in [B_SWEEP_W, B_RAM_W, B_THROW_W, B_CALL]:
		var k5 := clampf(_st / (B_SWEEP_WIND if state == B_SWEEP_W else (RAM_WIND if state == B_RAM_W else (THROW_WIND if state == B_THROW_W else CALL_T))), 0.0, 1.0)
		DrawBatch.string(z, ThemeDB.fallback_font, head + Vector2(-3, -20), "!", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(1.0, 0.35, 0.2, k5))
	end_draw()
	if _ring >= 0.0:
		var kk := _ring / 0.5
		var c: Vector2 = _ring_pos - z.global_position
		DrawBatch.polyline(z, Art.ellipse(c, B_SWEEP_R * 0.6 * kk + 20.0, 10.0 * kk + 3.0, 0.0, 24), Color(0.85, 0.82, 0.7, 0.55 * (1.0 - kk)), 3.0)
	return true


func _jaw_center(sh: Vector2) -> Vector2:
	match state:
		B_SWEEP_W:
			var k := clampf(1.0 - _st / B_SWEEP_WIND, 0.0, 1.0)
			return Vector2(lerpf(12.0, -8.0, k), lerpf(shield_y, -36.0, k))
		B_SWEEP:
			var k2 := clampf(1.0 - _st / B_SWEEP_T, 0.0, 1.0)
			return Vector2(lerpf(-8.0, 22.0, k2), lerpf(-36.0, -8.0, k2))
		B_RECOVER, B_STUCK:
			return Vector2(14.0, -12.0)
		B_CALL:
			return Vector2(8.0, -16.0)
	return Vector2(12.0 + (sh.x - 1.0) * 0.5, shield_y)


# לסת לווייתן: קשת עצם ארוכה ומעוקלת, אנכית מול הגוף (באמצע ההטאטא - נוטה קדימה)
func _jaw(c: Vector2, tt: float) -> void:
	var ang := 0.0
	if state == B_SWEEP:
		ang = clampf(1.0 - _st / B_SWEEP_T, 0.0, 1.0) * 1.3
	elif state == B_SWEEP_W:
		ang = -0.5 * clampf(1.0 - _st / B_SWEEP_WIND, 0.0, 1.0)
	elif state in [B_RECOVER, B_STUCK]:
		ang = 1.1
	var up := Vector2(sin(ang), -cos(ang))
	var side := Vector2(cos(ang), sin(ang))
	var pts := PackedVector2Array()
	var pts2 := PackedVector2Array()
	for i in 9:
		var k := float(i) / 8.0
		var along := (k - 0.5) * JAW_H * 2.4
		var bow := sin(k * PI) * 4.5 - 1.0
		var p := c + up * -along + side * bow
		pts.append(p + side * (1.8 + 0.8 * sin(k * PI)))
		pts2.append(p - side * (1.6 + 0.5 * sin(k * PI)))
	var poly := pts.duplicate()
	for i in range(pts2.size() - 1, -1, -1):
		poly.append(pts2[i])
	Art.fill(z, poly, col(Decor.BONE), Art.OUTLINE, 1.0)
	DrawBatch.polyline(z, pts, col(Color(0.95, 0.92, 0.82)), 0.8)
	for q in 4:   # חורי עצבים
		var k2 := 0.2 + float(q) * 0.18
		DrawBatch.circle(z, c + up * -((k2 - 0.5) * JAW_H * 2.4) + side * (sin(k2 * PI) * 4.5 - 1.0), 0.8, col(Decor.BONE_S))
	for k3 in _cracks:
		var p0: Vector2 = c + up * float(k3[1]) + side * float(k3[0])
		var a: float = k3[2]
		DrawBatch.line(z, p0, p0 + Vector2(cos(a), sin(a)) * 4.0, col(Decor.BONE_S), 0.8)
	var pulse := 0.6 + 0.4 * sin(tt * 3.0)
	DrawBatch.circle(z, c + up * 8.0 + side * 3.0, 1.3, Color(Decor.SPORE, 0.7 * pulse))
	DrawBatch.line(z, c + side * -2.0 + up * 2.0, c + side * 4.0 + up * 1.0, col(Color("5a4a36")), 1.4)   # חבל


# קסדה: גולגולת לווייתן - קופסת ראש עגולה עם חרטום ארוך ושטוח שמצביע קדימה, ארובות עיניים עם זוהר אדום
func _skull_helm(head: Vector2, tt: float) -> void:
	var bone := col(Decor.BONE)
	var dk := col(Decor.BONE_D)
	var dmg := 1.0 - float(_skull_hp) / float(SKULL_HP)
	Art.oval_shaded(z, head + Vector2(-1.0, -2.5), 8.5, 7.5, bone, 0.0)
	var rost := PackedVector2Array([head + Vector2(3.0, -6.5), head + Vector2(23.0, -4.0), head + Vector2(25.0, -2.5), head + Vector2(22.0, -1.0), head + Vector2(5.0, 1.5)])
	Art.fill(z, rost, bone, Art.OUTLINE, 1.0)
	DrawBatch.line(z, head + Vector2(5.0, -3.0), head + Vector2(23.0, -2.6), dk, 0.8)   # תפר החרטום
	DrawBatch.colored_polygon(z, PackedVector2Array([head + Vector2(-8.0, 0.0), head + Vector2(-4.0, 3.0), head + Vector2(-9.0, 5.0)]), dk)   # עצם לחי
	# ארובה + עין
	Art.oval(z, head + Vector2(3.5, -1.0), 2.4, 2.0, col(Color("1a0a0c")), 0.0, Art.NONE)
	if not z.dead:
		var ec := _eye_col()
		DrawBatch.circle(z, head + Vector2(3.8, -1.0), 1.1, ec)
		Art.glow(z, head + Vector2(3.8, -1.0), 5.0 + 1.5 * sin(tt * 4.0), Color(ec, 0.45))
	if dmg > 0.25:
		DrawBatch.line(z, head + Vector2(-4.0, -9.0), head + Vector2(0.0, -4.0), col(Decor.BONE_S), 0.9)
	if dmg > 0.55:
		DrawBatch.line(z, head + Vector2(0.0, -4.0), head + Vector2(6.0, -6.0), col(Decor.BONE_S), 0.9)
		DrawBatch.line(z, head + Vector2(12.0, -5.0), head + Vector2(16.0, -2.0), col(Decor.BONE_S), 0.8)
	# ECHO על הגולגולת
	var pulse := 0.6 + 0.4 * sin(tt * 2.2 + 1.0)
	DrawBatch.circle(z, head + Vector2(-5.0, -7.0), 1.6, Color(Decor.SPORE, 0.8 * pulse))
	DrawBatch.circle(z, head + Vector2(-2.0, -9.5), 1.1, Color(Decor.SPORE, 0.7 * pulse))
