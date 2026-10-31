extends "res://enemies/zombie_type.gd"
# ============================================================
#  SPECIMEN (שלב 60, "GLACIER LAB") - נבדק של פרויקט ECHO שברח (או הופשר): חלוק מעבדה קרוע ומוכתם, עור אפור-כחלחל,
#    ראש מגולח עם סיכות ניתוח ואלקטרודות, צינור אינפוזיה תלוי מהזרוע, צמיד זיהוי עם ברקוד, גידולי ECHO זוהרים בכתף ובגב,
#    כפור על הכתפיים. עיניים אדומות (ירוקות כשהוא מעתיק אותך).
#  מה הוא למד, וממה: ECHO נבנה כדי שחיילים יחלקו זיכרון קרב. הנבדקים כאן קיבלו את הזיכרון של החיילים - והם נלחמים כמוהם.
#    TANK    - קפוא במיכל הקפאה (effects/s60_decor.gd CryoTank). כשאתה עובר לידו (_thaw_r, שונה לכל אחד - חלקם מאחוריך)
#              המיכל מפשיר ומתנפץ. ירייה במיכל = מנפצת אותו מיד (x TANK_MULT דרך הזכוכית). hold = רק כשהשלב מחליט.
#    STIFF   - יוצא קפוא וקשיח (STIFF_T): איטי, שביר (x STIFF_MULT), כפור נושר.
#    HUNT    - רודף. "THEY ROLL LIKE SOLDIERS NOW": בטווח ROLL_R מתגלגל אליך כמו חייל (נמוך - כדורים בגובה החזה עוברים
#              מעליו), ובסוף הגלגול קם במכת טפרים עולה (STRIKE). רואה אותך יורה -> לפעמים מתגלגל (ON_SHOT_CHANCE).
#    RECOVER - אחרי מכה / גלגול: על ברך אחת (x RECOVER_MULT) - החלון שלך. SWIPE - מכה מקרוב.
#  נגד: להתכופף מול הגלגול (או לירות נמוך), להתגלגל / לקפוץ מעל המכה העולה, לירות בו כשהוא על הברך.
#  לומד (main meta "sp_beaten" >= LEARN_N - מכות שהחטיאו כי התגלגלת / קפצת, והריגות בזמן גלגול / ברך):
#    "IT COPIES YOU NOW" - מעתיק את התנועה האחרונה שלך אחרי COPY_DELAY: אתה מתגלגל - הוא מתגלגל לאותו כיוון (בלתי פגיע
#    כמוך, חוץ מפיצוץ), אתה מתכופף - הוא מתכופף (עד שאתה קם), אתה קופץ - הוא קופץ. טבעת ירוקה + עיניים ירוקות בכל העתקה.
#    נגד: לא לחזור על אותה תנועה. הוא תמיד מאחר ב-COPY_DELAY, ואחרי גלגול מועתק הוא כורע (RECOVER).
#  בוס (chase_range > 600): "SUBJECT FOUR" - אחד משבעת חיילי ECHO, מאוחד עם הרובה שלו. נלחם במהלכים של הגיבור עצמו
#    (ai/player_memory.gd): שומר על המרחק שאתה אוהב (avg_distance; רחוק יותר משוטגאן), מתגלגל כשאתה יורה עליו (B_ROLL,
#    בלתי פגיע), נכנס למחסה (שולחנות / מיכלים בזירה, group "cover") ומציץ לצרור, יורה צרורות (B_BURST) אחרי לייזר
#    כיוון (B_AIM), ומכה בקת כשאתה קרוב (B_MELEE). לייזר גבוה = להתכופף. "IT AIMS LOW NOW": אחרי SEEN_DUCKS פעמים שהתכופפת
#    מתחת לצרור (או שאתה מתכופף הרבה - PlayerMemory.crouch) - מחליף גבוה / נמוך: לייזר נמוך = לקפוץ / להתגלגל.
#    מתחת לחצי חיים: "IT REMEMBERS EVERYTHING" - קורא ל-SPECIMEN במיכלי הזירה (stage_60.thaw_arena), צרורות ארוכים יותר.
#  שחקן בסצנה (story/scenes/l60_file.gd): tank_actor = עומד במיכל של הסצנה, עיניים עצומות עד wake_actor() ("welcome").
#  לשנות: THAW_R, STIFF_T, ROLL_R, ROLL_V, ROLL_T, STRIKE_*, SWIPE_*, RECOVER_T, *_MULT, LEARN_N, COPY_*;
#         בוס: B_PREF, B_AIM_T, B_SHOTS, B_SHOT_V, B_ROLL_*, B_COVER_T, B_MELEE_*, B_ARMOR, SEEN_DUCKS, AIM_HIGH, AIM_LOW.
# ============================================================

const ZScript := preload("res://zombie.gd")

const SOUNDS := {
	"sp_gasp": {"rev": 0.3, "drive": 2.0, "layers": [["N", 0, 0, 0.0, 0.7, 0.15, 2.0, 0.6, 0.35, 0, 0.15], ["V", 160, 120, 0.05, 0.6, 0.1, 2.5, 0.35, 1.0, 0.05, 0, [600, 1300, 20]]]},
	"sp_roll": [["N", 0, 0, 0.0, 0.3, 0.02, 9.0, 0.45, 0.25, 0, 0.05], ["S", 110, 60, 0.0, 0.12, 0.0, 20.0, 0.35, 1.0, 0]],
	"sp_claw": {"drive": 2.2, "layers": [["N", 0, 0, 0.0, 0.18, 0.01, 12.0, 0.5, 1.0, 0, 0.4], ["V", 420, 260, 0.0, 0.25, 0.01, 6.0, 0.45, 1.0, 0.06, 0, [900, 1800, 40]]]},
	"sp_copy": {"rev": 0.5, "layers": [["S", 660, 990, 0.0, 0.35, 0.02, 5.0, 0.18, 1.0, 0.0], ["S", 990, 1320, 0.06, 0.35, 0.02, 5.0, 0.14, 1.0, 0.0], ["N", 0, 0, 0.0, 0.25, 0.05, 6.0, 0.12, 1.0, 0, 0.7]]},
	"s4_laser": [["S", 2400, 2400, 0.0, 0.05, 0.0, 40.0, 0.12, 1.0, 0], ["S", 2400, 2400, 0.12, 0.05, 0.0, 40.0, 0.12, 1.0, 0]],
	"s4_call": {"rev": 0.5, "drive": 2.6, "layers": [["V", 95, 70, 0.0, 1.4, 0.06, 1.3, 0.9, 1.0, 0.05, 0, [420, 900, 26]], ["V", 140, 110, 0.04, 1.3, 0.06, 1.3, 0.5, 1.0, 0.05, 0, [500, 1100, 20]], ["S", 660, 990, 0.2, 1.0, 0.2, 2.0, 0.12, 1.0, 0.0]]},
	"s4_butt": [["N", 0, 0, 0.0, 0.12, 0.0, 20.0, 0.7, 0.3, 0], ["S", 140, 60, 0.0, 0.12, 0.0, 22.0, 0.6, 1.0, 0]],
}

const BASE_H := 22.0               # גובה הבסיס של המיכל (CryoTank.BASE_H)
const THAW_R := Vector2(150.0, 360.0)
const STIFF_T := 1.5
const STIFF_MULT := 1.4
const TANK_MULT := 0.7
const ROLL_R := 250.0
const ROLL_MIN := 110.0
const ROLL_V := 430.0
const ROLL_T := 0.42
const ROLL_CD := Vector2(1.8, 2.8)
const ON_SHOT_CHANCE := 0.3
const STRIKE_R := 80.0
const STRIKE_WIND := 0.14
const STRIKE_HIT := 0.12
const STRIKE_DMG := 1
const SWIPE_R := 54.0
const SWIPE_WIND := 0.32
const SWIPE_CD := 0.9
const RECOVER_T := 0.6
const RECOVER_MULT := 1.3
const LEARN_N := 3
const COPY_DELAY := Vector2(0.12, 0.22)
const COPY_R := 640.0
const COPY_CD := 0.8
const DUCK_MAX := 2.6
# בוס
const B_PREF := Vector2(220.0, 470.0)
const B_AIM_T := 0.55
const B_AIM_T2 := 0.4
const B_SHOTS := 3
const B_SHOTS2 := 5
const B_RATE := 0.11
const B_SHOT_V := 860.0
const B_RELOAD_T := 0.7
const B_ROLL_T := 0.42
const B_ROLL_V := 470.0
const B_ROLL_CD := 1.8
const B_ROLL_CD_FAST := 1.1
const B_COVER_T := 4.5
const B_COVER_MULT := 0.6
const B_MELEE_R := 95.0
const B_MELEE_WIND := 0.36
const B_MELEE_DMG := 1
const B_ARMOR := 0.85
const B_OPEN_MULT := 1.3
const B_CD := Vector2(0.5, 1.1)
const SEEN_DUCKS := 2
const AIM_HIGH := -44.0            # מעל שחקן כפוף (34), בחזה של שחקן עומד (52)
const AIM_LOW := -16.0             # פוגע גם בכפוף - לקפוץ / להתגלגל
const ARENA_X0 := 9210.0           # (stage_60 DOORS[5] + 60)

enum {TANK, STIFF, HUNT, ROLL, STRIKE, SWIPE, RECOVER, DUCK, IDLE,
	B_IDLE, B_WALK, B_AIM, B_BURST, B_RELOAD, B_ROLL, B_COVER, B_MELEE, B_CALL}
var state := HUNT
# לבדיקות
var rolls := 0
var strikes := 0
var strike_hits := 0
var whiffs := 0
var swipes := 0
var copies := 0
var copy_rolls := 0
var copy_ducks := 0
var copy_jumps := 0
var releases := 0
var b_bursts := 0
var b_shots := 0
var b_rolls := 0
var b_covers := 0
var b_melees := 0
var b_low := 0
var b_calls := 0
# שחקן בסצנה
var talking := false
var tilt := 0.0
var smile := 0.0
var t := 0.0
var tank_actor := false
var awake := false

var learned := false
var hold := false                  # במיכל: לא מפשיר מקרבה (השלב מחליט)
var tank = null                    # CryoTank
var _thaw_r := 260.0
var _ground := 630.0
var _st := 0.0
var _cd := 0.5
var _roll_cd := 1.0
var _hit := false
var _copy := false                 # הגלגול הנוכחי הוא העתקה (בלתי פגיע)
var _queue := ""                   # העתקה שמחכה: "roll" / "duck" / "jump"
var _queue_t := 0.0
var _queue_dir := 1.0
var _copy_cd := 0.0
var _ring := -1.0                  # טבעת "למד" (העתקה)
var _was_roll := false
var _was_crouch := false
var _was_floor := true
var _learn_chk := 0.0
var _var := []                     # [סוג חלוק, דם, צד הגידול, צינור, מספר]
var _glass := false
var _shape_k := 0                  # 0 = עומד, 1 = נמוך (גלגול), 2 = כפוף
# בוס
var _engaged := false
var _b_cd := 1.0
var _left := 0
var _shot_t := 0.0
var _aim := 0.0                    # זווית הכיוון (עולם)
var _aim_y := AIM_HIGH
var _low_on := false               # למד: מחליף גבוה / נמוך
var _ducks_seen := 0
var _duck_this := false
var _hp_at := 0
var _phase2 := false
var _cover_node: Node = null
var _cover_x := 0.0
var _cover_phase := 0              # 0 = רץ למחסה, 1 = מתחבא, 2 = מציץ ומכוון
var _cover_t := 0.0
var _flash := 0.0
var _roll_dir := 1.0
var _said_low := false


func _boss() -> bool:
	return z != null and float(z.chase_range) > 600.0


func stats() -> Dictionary:
	if _boss():
		return {"name": "SPECIMEN", "hp": 360, "walk": 60.0, "chase": 150.0, "damage": 1, "bite_delay": 1.0, "scale": 1.45, "width": 1.0,
			"duck": 0.0, "cover": 0.0, "skin": Color("8a9a92"), "shirt": Color("3a4232"), "pants": Color("2e3428"), "shoe": Color("1a1a16"),
			"points": 3000, "boss": true, "boss_name": "SUBJECT FOUR", "ragdoll": false}
	return {"name": "SPECIMEN", "hp": 38, "walk": 44.0, "chase": 112.0, "damage": 1, "bite_delay": 0.8, "scale": 1.0, "width": 0.95,
		"duck": 0.0, "cover": 0.0, "skin": Color("8c9ca6"), "shirt": Color("b4c0b8"), "pants": Color("7e8c94"), "shoe": Color("5e6a70"), "points": 420}


func brain_overrides() -> Dictionary:
	return {"aggression": 0.8}


func use_brain_movement() -> bool:
	return false


func can_bite() -> bool:
	return false


func can_groan() -> bool:
	return state != TANK and not _scene_actor()


func death_sound() -> String:
	return "zdeath"


func _main() -> Node:
	return z.get_parent()


func _stage() -> Node:
	var m := _main()
	return m.get("_stage") if m != null else null


func setup() -> void:
	z.add_to_group("s60_specimens")
	var m := _main()
	learned = not _boss() and m != null and int(m.get_meta("sp_beaten", 0)) >= LEARN_N
	_ground = z.global_position.y
	var r := RandomNumberGenerator.new()
	r.seed = z.get_instance_id()
	_var = [r.randi() % 3, r.randf_range(0.2, 1.0), 1.0 if r.randf() < 0.5 else -1.0, r.randf() < 0.6, r.randi() % 10]
	_thaw_r = r.randf_range(THAW_R.x, THAW_R.y)
	_roll_cd = r.randf_range(0.6, 1.6)
	if _boss():
		state = B_IDLE
		_resize(Vector2(30.0, 56.0))
	else:
		state = HUNT
		_resize(Vector2(28.0, 54.0))


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
			_resize(Vector2(28.0, 54.0) if not _boss() else Vector2(30.0, 56.0))


func _scene_actor() -> bool:
	return not z.is_in_group("zombies")


# ============================================================
#  מיכל ההקפאה (stage_60 -> extra_spawns)
# ============================================================
func enter_tank(tk: Node, hold_it := false) -> void:
	tank = tk
	hold = hold_it
	state = TANK
	z.velocity = Vector2.ZERO
	z.global_position.y = _ground - BASE_H
	z._dir = -1.0 if randf() < 0.5 else 1.0


func in_tank() -> bool:
	return state == TANK


# CryoTank.burst() -> יוצא
func release() -> void:
	if state != TANK or z.dead:
		return
	releases += 1
	tank = null
	state = STIFF
	_st = STIFF_T
	var pl := player() as Node2D
	if pl != null:
		z._dir = signf(pl.global_position.x - z.global_position.x + 0.01)
	z.velocity = Vector2(z._dir * 90.0, -170.0)
	z._alert_t = 3.0
	Sfx.play("sp_gasp", z.global_position + Vector2(0, -40), 0.0, 0.15, 3)


# סצנת הסיפור ("welcome"): פוקח עיניים
func wake_actor() -> void:
	awake = true
	_ring = 0.0


func on_shot(from: Vector2, dir: Vector2) -> void:
	if z == null or z.dead or _scene_actor():
		return
	if _boss():
		_boss_on_shot(from, dir)
		return
	if state != HUNT or _roll_cd > 0.0 or not z.is_on_floor() or randf() > ON_SHOT_CHANCE:
		return
	var c: Vector2 = z.global_position + Vector2(0, -30.0 * z.sc)
	var rel := c - from
	var along := rel.dot(dir)
	if along < 0.0 or along > ROLL_R * 1.7 or absf(rel.cross(dir)) > 50.0:
		return
	_start_roll(-signf(rel.x) if absf(rel.x) > 1.0 else z._dir, false)


# ============================================================
#  תנועה
# ============================================================
func physics(pl: Node, delta: float) -> bool:
	t += delta
	_st -= delta
	_cd -= delta
	_roll_cd -= delta
	_copy_cd -= delta
	_flash -= delta
	if _ring >= 0.0:
		_ring += delta
		if _ring > 0.45:
			_ring = -1.0
	if _scene_actor():   # שחקן בסצנה
		if tank_actor:
			z.velocity = Vector2.ZERO
			z.global_position.y = _ground - BASE_H
			return true
		if not z.is_on_floor():
			z.velocity.y += z.gravity * delta
		z.velocity.x = 0.0
		z.move_and_slide()
		return true
	if z.dead:
		return false
	var has: bool = pl != null and not pl.dead
	var d: Vector2 = (pl.global_position - z.global_position) if has else Vector2.ZERO
	if _boss():
		_boss_physics(pl, has, d, delta)
		return _end(delta)
	if state == TANK:
		z.velocity = Vector2.ZERO
		if tank == null or not is_instance_valid(tank):
			release()
			return true
		if has and not hold and absf(d.x) < _thaw_r and absf(d.y) < 240.0 and tank.frozen():
			tank.thaw()
		if Engine.get_physics_frames() % 20 == 0:
			z.queue_redraw()
		return true
	if learned:
		_watch(pl, has, d, delta)
	elif Engine.get_physics_frames() % 30 == 0:
		_learn_chk += 1.0
		var m := _main()
		if m != null and int(m.get_meta("sp_beaten", 0)) >= LEARN_N:
			learned = true
	match state:
		STIFF:
			_set_shape(0)
			if has:
				z._dir = signf(d.x) if absf(d.x) > 6.0 else z._dir
			z.velocity.x = move_toward(z.velocity.x, z._dir * z.walk_speed * 0.6, 300.0 * delta)
			z._walk_phase += delta * 4.0
			if Engine.get_physics_frames() % 10 == 0 and Art.on_screen(z, z.global_position):
				Particles.burst(_main(), z.global_position + Vector2(randf_range(-8, 8), -randf_range(20, 50)), "snow", Vector2.DOWN, 1)
			if _st <= 0.0:
				state = HUNT
		HUNT:
			_set_shape(0)
			_hunt(pl, has, d, delta)
		ROLL:
			_set_shape(1)
			if not _copy:
				z.velocity.x = move_toward(z.velocity.x, z._dir * ROLL_V * 0.75, 600.0 * delta)
			if _st <= 0.0:
				_copy_end_or_strike(has, d)
		STRIKE:
			z.velocity.x = move_toward(z.velocity.x, z._dir * 80.0, 900.0 * delta)
			_set_shape(0 if _st < STRIKE_HIT else 2)
			if _st <= STRIKE_HIT and _st > 0.0 and has and not _hit:
				var me: Rect2 = Rect2(z.global_position + Vector2(-6.0 + z._dir * 22.0 - 22.0, -58.0 * z.sc), Vector2(44.0, 58.0 * z.sc))
				if me.intersects(pl.body_rect()):
					_hit = true
					if pl._roll_t > 0.0:
						_beaten()
					else:
						strike_hits += 1
					pl.hurt(STRIKE_DMG, Vector2(z._dir * 1.3, -0.6))
			if _st <= 0.0:
				if not _hit:
					whiffs += 1
					if has and (pl._roll_t > 0.0 or not pl.is_on_floor()):   # התגלגלת / קפצת מעל המכה
						_beaten()
				_start_recover(RECOVER_T)
		SWIPE:
			z.velocity.x = move_toward(z.velocity.x, 0.0, 900.0 * delta)
			if _st <= 0.0 and not _hit:
				_hit = true
				if has and absf(d.x) < SWIPE_R + 14.0 and absf(d.y) < 60.0:
					pl.hurt(z.damage, Vector2(z._dir, -0.3))
				Sfx.play("sp_claw", z.global_position + Vector2(0, -36), -4.0, 0.15, 3)
			if _st <= -0.18:
				state = HUNT
				_cd = SWIPE_CD
		RECOVER:
			_set_shape(2)
			z.velocity.x = move_toward(z.velocity.x, 0.0, 900.0 * delta)
			if _st <= 0.0:
				state = HUNT
		DUCK:   # (למד) מתכופף כמוך, מתקדם לאט
			_set_shape(2)
			if has:
				z._dir = signf(d.x) if absf(d.x) > 6.0 else z._dir
				z.velocity.x = move_toward(z.velocity.x, z._dir * 40.0 if absf(d.x) > 70.0 else 0.0, 500.0 * delta)
				z._walk_phase += delta * 4.0
			if _st <= 0.0 or (has and not pl._crouching and _st < DUCK_MAX - 0.45):
				state = HUNT
		IDLE:
			z.velocity.x = move_toward(z.velocity.x, 0.0, 500.0 * delta)
			if has and absf(d.x) < 900.0:
				state = HUNT
	return _end(delta)


func _end(delta: float) -> bool:
	if not z.is_on_floor():
		z.velocity.y += z.gravity * delta
	z.move_and_slide()
	return true


func _hunt(pl: Node, has: bool, d: Vector2, delta: float) -> void:
	if not has:
		z.velocity.x = move_toward(z.velocity.x, 0.0, 500.0 * delta)
		return
	z._dir = signf(d.x) if absf(d.x) > 6.0 else z._dir
	var sp: float = z.chase_speed if (absf(d.x) < 900.0 or z._alert_t > 0.0) else z.walk_speed
	z.velocity.x = move_toward(z.velocity.x, z._dir * sp if absf(d.x) > 30.0 else 0.0, 700.0 * delta)
	z._walk_phase += delta * (11.0 if sp > 80.0 else 6.0)
	if z.is_on_floor() and z.is_on_wall() and absf(z.velocity.x) < 30.0:
		z.velocity.y = -470.0
	if not z.is_on_floor() or absf(d.y) > 70.0:
		return
	if absf(d.x) < SWIPE_R and _cd <= 0.0:
		state = SWIPE
		swipes += 1
		_st = SWIPE_WIND
		_hit = false
	elif absf(d.x) > ROLL_MIN and absf(d.x) < ROLL_R and _roll_cd <= 0.0:
		_start_roll(signf(d.x), false)


func _start_roll(dir: float, copy: bool) -> void:
	state = ROLL
	_copy = copy
	_st = ROLL_T
	z._dir = dir
	z.velocity.x = dir * ROLL_V
	_roll_cd = randf_range(ROLL_CD.x, ROLL_CD.y)
	_set_shape(1)
	rolls += 1
	Sfx.play("sp_roll", z.global_position, -3.0, 0.12, 3)
	var m := _main()
	if m != null and not copy and not m.has_meta("sp_said"):
		m.set_meta("sp_said", true)
		z._popup("THEY ROLL LIKE SOLDIERS NOW", Color("ff8a7a"), 12, -80.0)
		var pl := player()
		if pl != null:
			pl._say("It rolled... like a soldier. Like ME.", Color("bfe8ff"))


func _copy_end_or_strike(has: bool, d: Vector2) -> void:
	_copy = false
	if has and absf(d.x) < STRIKE_R and absf(d.y) < 70.0:
		state = STRIKE
		strikes += 1
		_st = STRIKE_WIND + STRIKE_HIT
		_hit = false
		z._dir = signf(d.x) if absf(d.x) > 4.0 else z._dir
		Sfx.play("sp_claw", z.global_position + Vector2(0, -30), 0.0, 0.12, 3)
	else:
		_start_recover(0.35)


func _start_recover(tt: float) -> void:
	state = RECOVER
	_st = tt


func _beaten() -> void:
	var m := _main()
	if m == null:
		return
	m.set_meta("sp_beaten", int(m.get_meta("sp_beaten", 0)) + 1)


# (למד) מסתכל עליך ומעתיק את התנועה האחרונה
func _watch(pl: Node, has: bool, d: Vector2, delta: float) -> void:
	if not has:
		return
	var rolling: bool = pl._roll_t > 0.0
	var crouch: bool = pl._crouching
	var floor_now: bool = pl.is_on_floor()
	var near := absf(d.x) < COPY_R and absf(d.y) < 160.0
	if near and _copy_cd <= 0.0 and _queue == "":
		if rolling and not _was_roll:
			_queue = "roll"
			_queue_dir = float(pl._roll_dir)
		elif crouch and not _was_crouch and not rolling:
			_queue = "duck"
		elif _was_floor and not floor_now and float(pl.velocity.y) < -150.0:
			_queue = "jump"
		if _queue != "":
			_queue_t = randf_range(COPY_DELAY.x, COPY_DELAY.y)
	_was_roll = rolling
	_was_crouch = crouch
	_was_floor = floor_now
	if _queue == "":
		return
	_queue_t -= delta
	if _queue_t > 0.0:
		return
	if not (state in [HUNT, DUCK, RECOVER, STIFF]) or not z.is_on_floor():
		if _queue_t < -0.7:   # (עסוק - ההעתקה מחכה עד 0.7 שניות)
			_queue = ""
		return
	var what := _queue
	_queue = ""
	_copy_cd = COPY_CD
	copies += 1
	_ring = 0.0
	match what:
		"roll":
			copy_rolls += 1
			_start_roll(_queue_dir, true)
			_roll_cd = maxf(_roll_cd, 1.0)
		"duck":
			copy_ducks += 1
			state = DUCK
			_st = DUCK_MAX
		"jump":
			copy_jumps += 1
			state = HUNT
			z.velocity.y = -560.0
	Sfx.play("sp_copy", z.global_position + Vector2(0, -40), -6.0, 0.1, 2)
	var m := _main()
	if m != null and not m.has_meta("sp_copy_said"):
		m.set_meta("sp_copy_said", true)
		z._popup("IT COPIES YOU NOW", Color("b8ff9a"), 14, -90.0)
		pl._say("It's copying me. Every move I make.", Color("bfe8ff"))


func on_damage(_amount: int, _hit_pos: Vector2, _dir: Vector2, src: Dictionary) -> bool:
	if z.dead:
		return true
	if _scene_actor():
		return false
	var blast := src.has("blast") or str(src.get("source", "bullet")) == "grenade"
	if _boss():
		if state == B_ROLL and not blast:
			return false
		if state == B_IDLE:
			_engage()
		return true
	if state == ROLL and _copy and not blast:   # גלגול מועתק: בלתי פגיע כמוך
		return false
	if state == TANK and tank != null and is_instance_valid(tank):
		_glass = true
		tank.burst()
	return true


func damage_mult(_zone: String, _src: Dictionary) -> float:
	if _boss():
		match state:
			B_RELOAD, B_CALL:
				return B_OPEN_MULT
			B_MELEE:
				return B_OPEN_MULT if _st > 0.0 else B_ARMOR
			B_COVER:
				return B_COVER_MULT if _cover_phase == 1 else B_ARMOR
		return B_ARMOR
	if _glass:   # הירייה שניפצה את המיכל עברה דרך הזכוכית
		_glass = false
		return TANK_MULT
	match state:
		TANK:
			return TANK_MULT
		STIFF:
			return STIFF_MULT
		RECOVER:
			return RECOVER_MULT
	return 1.0


func on_death() -> void:
	if _boss():
		_boss_death()
		return
	if state in [ROLL, RECOVER, STRIKE] and not _scene_actor():
		_beaten()
	if Art.on_screen(z, z.global_position):
		Particles.burst(_main(), z.global_position + Vector2(0, -36), "snow", Vector2.UP, 5)


# ============================================================
#  בוס: SUBJECT FOUR
# ============================================================
func _engage() -> void:
	if _engaged:
		return
	_engaged = true
	state = B_WALK
	_b_cd = 0.8
	z._popup("IT FIGHTS LIKE YOU NOW", Color("ff8a7a"), 18, -150.0)
	var pl := player()
	if pl != null:
		pl._say("Subject Four... one of the seven. He fights like me.", Color("bfe8ff"))
	_low_on = PlayerMemory.crouch > 0.3


func _pref() -> float:
	var p := clampf(PlayerMemory.avg_distance, B_PREF.x, B_PREF.y)
	if float(PlayerMemory.weapon_use.get("shotgun", 0.0)) > 0.35:   # שוטגאן: לא מתקרב
		p = minf(p + 120.0, B_PREF.y + 60.0)
	return p


func _boss_on_shot(from: Vector2, dir: Vector2) -> void:
	if not _engaged or _roll_cd > 0.0 or not z.is_on_floor():
		return
	if not (state in [B_WALK, B_AIM, B_RELOAD]) and not (state == B_COVER and _cover_phase == 2):
		return
	var c: Vector2 = z.global_position + Vector2(0, -34.0 * z.sc)
	var rel := c - from
	var along := rel.dot(dir)
	if along < 0.0 or along > 1100.0 or absf(rel.cross(dir)) > 56.0:
		return
	var away := signf(rel.x) if absf(rel.x) > 1.0 else 1.0
	var dist := absf(rel.x)
	var rd := away if dist < _pref() else -away   # קרוב מדי - מתגלגל אחורה, רחוק - קדימה
	var bx: float = z.global_position.x + rd * B_ROLL_V * B_ROLL_T
	if bx < ARENA_X0 + 40.0 or bx > z.world_w - 60.0:
		rd = -rd
	state = B_ROLL
	_st = B_ROLL_T
	_roll_dir = rd
	z.velocity.x = rd * B_ROLL_V
	_roll_cd = B_ROLL_CD_FAST if float(PlayerMemory.weapon_use.get("precision", 0.5)) > 0.6 else B_ROLL_CD
	if _phase2:
		_roll_cd *= 0.8
	b_rolls += 1
	_set_shape(1)
	Sfx.play("sp_roll", z.global_position, 0.0, 0.1, 2, 0.8)


func _boss_physics(pl: Node, has: bool, d: Vector2, delta: float) -> void:
	_b_cd -= delta
	if not has:
		z.velocity.x = move_toward(z.velocity.x, 0.0, 600.0 * delta)
		return
	if state == B_IDLE:
		z.velocity.x = 0.0
		_set_shape(0)
		if absf(d.x) < float(z.chase_range) or z._alert_t > 0.0 or pl.global_position.x > ARENA_X0 + 120.0:
			_engage()
		return
	if not _phase2 and float(z.hp) < float(z.max_hp) * 0.5 and state in [B_WALK, B_RELOAD]:
		_phase2 = true
		state = B_CALL
		_st = 1.1
		b_calls += 1
		z._popup("IT REMEMBERS EVERYTHING", Color("b8ff9a"), 18, -160.0)
		Sfx.play("s4_call", z.global_position, 3.0, 0.0, 1)
		var cam: Camera2D = z.get_viewport().get_camera_2d()
		if cam != null and cam.has_method("shake"):
			cam.shake(9.0, 0.7)
		var st := _stage()
		if st != null and st.has_method("thaw_arena"):
			st.thaw_arena()
	var face: float = signf(d.x) if absf(d.x) > 6.0 else float(z._dir)
	match state:
		B_WALK:
			_set_shape(0)
			z._dir = face
			var pref := _pref()
			var want := 0.0
			if absf(d.x) > pref + 60.0:
				want = face * z.chase_speed
			elif absf(d.x) < pref - 70.0:
				want = -face * z.walk_speed * 1.6   # נסוג אחורה ושומר עליך בעין
			var nx: float = z.global_position.x + want * 0.3
			if nx < ARENA_X0 or nx > z.world_w - 50.0:
				want = 0.0
			z.velocity.x = move_toward(z.velocity.x, want, 700.0 * delta)
			if absf(z.velocity.x) > 10.0:
				z._walk_phase += delta * 9.0 * signf(z.velocity.x) * face
			if z.is_on_floor() and z.is_on_wall() and absf(z.velocity.x) < 20.0 and want != 0.0:
				z.velocity.y = -480.0
			if absf(d.x) < B_MELEE_R and absf(d.y) < 70.0 and z.is_on_floor():
				state = B_MELEE
				_st = B_MELEE_WIND
				_hit = false
				b_melees += 1
				Sfx.play("s4_butt", z.global_position, -6.0, 0.1, 2, 0.7)
			elif _b_cd <= 0.0 and z.is_on_floor():
				if _want_cover(pl):
					_go_cover()
				else:
					_start_aim(pl)
		B_AIM:
			_set_shape(0)
			z._dir = face
			z.velocity.x = move_toward(z.velocity.x, 0.0, 900.0 * delta)
			_aim = lerp_angle(_aim, _target_angle(pl), delta * 7.0)
			if _st <= 0.0:
				state = B_BURST
				b_bursts += 1
				_left = B_SHOTS2 if _phase2 else B_SHOTS
				_shot_t = 0.0
				_duck_this = pl._crouching
				_hp_at = int(pl.health)
		B_BURST:
			z.velocity.x = move_toward(z.velocity.x, 0.0, 900.0 * delta)
			_shot_t -= delta
			if _shot_t <= 0.0 and _left > 0:
				_shot_t = B_RATE
				_left -= 1
				_fire()
			if _left <= 0 and _shot_t <= 0.0:
				# התכופפת מתחת לצרור הגבוה? הוא רושם
				if _aim_y == AIM_HIGH and pl._crouching and int(pl.health) >= _hp_at:
					_ducks_seen += 1
				if not _low_on and (_ducks_seen >= SEEN_DUCKS or PlayerMemory.crouch > 0.3):
					_low_on = true
				if _cover_node != null and state == B_BURST and _cover_phase == 2:
					state = B_COVER
					_cover_phase = 1
					_st = randf_range(0.7, 1.1)
				else:
					state = B_RELOAD
					_st = B_RELOAD_T * (0.7 if _phase2 else 1.0)
		B_RELOAD:
			_set_shape(0)
			z._dir = face
			z.velocity.x = move_toward(z.velocity.x, 0.0, 900.0 * delta)
			if _st <= 0.0:
				state = B_WALK
				_b_cd = randf_range(B_CD.x, B_CD.y) * (0.7 if _phase2 else 1.0)
		B_ROLL:
			_set_shape(1)
			z.velocity.x = move_toward(z.velocity.x, _roll_dir * B_ROLL_V * 0.7, 500.0 * delta)
			if _st <= 0.0:
				_set_shape(0)
				z._dir = face
				if (_cover_node != null and _cover_phase > 0) or _want_cover(pl):   # מתגלגל אל מחסה (כמוך)
					_go_cover()
				else:
					_start_aim(pl)   # קם מהגלגול ויורה מיד (כמוך)
					_st *= 0.75
		B_COVER:
			_cover_physics(pl, d, face, delta)
		B_MELEE:
			z.velocity.x = move_toward(z.velocity.x, 0.0, 1200.0 * delta)
			z._dir = face if _st > 0.1 else z._dir
			if _st <= 0.0 and not _hit:
				_hit = true
				var me: Rect2 = Rect2(z.global_position + Vector2(z._dir * 40.0 - 40.0, -70.0 * z.sc), Vector2(80.0, 70.0 * z.sc))
				if me.intersects(pl.body_rect()):
					pl.hurt(B_MELEE_DMG, Vector2(z._dir * 1.8, -0.8))
				Sfx.play("s4_butt", z.global_position + Vector2(z._dir * 30.0, -40), 0.0, 0.1, 2)
			if _st <= -0.35:
				state = B_WALK
				_b_cd = 0.25
		B_CALL:
			z.velocity.x = move_toward(z.velocity.x, 0.0, 900.0 * delta)
			if _st <= 0.0:
				state = B_WALK
				_b_cd = 0.3
	# לא יוצא מהזירה
	if z.global_position.x < ARENA_X0 and z.velocity.x < 0.0:
		z.velocity.x = 0.0


func _start_aim(pl: Node) -> void:
	state = B_AIM
	_st = B_AIM_T2 if _phase2 else B_AIM_T
	if _low_on:
		if not _said_low:
			_said_low = true
			_aim_y = AIM_LOW
			z._popup("IT AIMS LOW NOW", Color("ff8a7a"), 16, -150.0)
		else:
			_aim_y = AIM_LOW if _aim_y == AIM_HIGH else AIM_HIGH
	else:
		_aim_y = AIM_HIGH
	if _aim_y == AIM_LOW:
		b_low += 1
	_aim = _target_angle(pl)
	Sfx.play("s4_laser", z.global_position + Vector2(0, -50), -6.0, 0.0, 2)


func _target_angle(pl: Node) -> float:
	var tgt: Vector2 = pl.global_position + Vector2(0.0, _aim_y)
	return (tgt - _muzzle_world()).angle()


# הקנה בעולם (הנשק מוחזק בגובה הכתף)
func _pivot_local() -> Vector2:
	var y := -40.0
	if state == B_COVER and _cover_phase == 1:
		y = -26.0
	return Vector2(4.0, y)


func _muzzle_world() -> Vector2:
	var lp := _pivot_local()
	var la: Vector2 = Vector2(cos(_aim) * z._dir, sin(_aim)) if state in [B_AIM, B_BURST] else Vector2(1.0, 0.1)
	lp += la.normalized() * 22.0
	return z.global_position + Vector2(lp.x * z._dir * z.wf * z.sc, lp.y * z.sc)


func _fire() -> void:
	b_shots += 1
	_flash = 0.05
	var b = ZScript.EnemyShot.new()
	_main().add_child(b)
	var mz := _muzzle_world()
	b.global_position = mz
	b.velocity = Vector2.from_angle(_aim + randf_range(-0.015, 0.015)) * B_SHOT_V
	b.life = 1.2
	Sfx.play("rifle", mz, -6.0, 0.1, 3, 0.85)
	if Art.on_screen(z, mz):
		Particles.burst(_main(), mz, "spark", Vector2.from_angle(_aim), 2)


func _want_cover(pl: Node) -> bool:
	return float(z.hp) < float(z.max_hp) * 0.95 and randf() < 0.5 and _find_cover(pl)


func _go_cover() -> void:
	state = B_COVER
	_cover_phase = 0
	_cover_t = 0.0
	b_covers += 1


func _find_cover(pl: Node) -> bool:
	_cover_node = null
	var best := 420.0
	for c in z.get_tree().get_nodes_in_group("cover"):
		if not c.has_method("cover_rect"):
			continue
		var r: Rect2 = c.cover_rect()
		if r.position.x < ARENA_X0:
			continue
		var cx := r.get_center().x
		var side := -signf(pl.global_position.x - cx)
		var spot := cx + side * (r.size.x * 0.5 + 26.0)
		if spot < ARENA_X0 + 20.0 or spot > z.world_w - 50.0:
			continue
		if absf(pl.global_position.x - cx) < r.size.x * 0.5 + 150.0:   # אתה ממש שם - לא מחסה
			continue
		var dd: float = absf(spot - z.global_position.x)
		if dd < best:
			best = dd
			_cover_node = c
			_cover_x = spot
	return _cover_node != null


func _cover_physics(pl: Node, d: Vector2, face: float, delta: float) -> void:
	_cover_t += delta
	if _cover_node == null or not is_instance_valid(_cover_node):
		_leave_cover()
		return
	var r: Rect2 = _cover_node.cover_rect()
	var cx := r.get_center().x
	var flanked: bool = signf(pl.global_position.x - cx) == signf(z.global_position.x - cx)   # אתה באותו צד - המחסה לא מגן
	if _cover_t > B_COVER_T or (flanked and _cover_phase > 0) or absf(d.x) < 130.0:
		_leave_cover()
		return
	match _cover_phase:
		0:   # רץ למחסה
			_set_shape(0)
			var dx: float = _cover_x - z.global_position.x
			z._dir = signf(dx) if absf(dx) > 6.0 else face
			z.velocity.x = move_toward(z.velocity.x, signf(dx) * z.chase_speed * 1.2 if absf(dx) > 8.0 else 0.0, 1100.0 * delta)
			z._walk_phase += delta * 12.0
			if absf(dx) <= 10.0:
				_cover_phase = 1
				_st = randf_range(0.5, 0.9)
				z.velocity.x = 0.0
			elif _cover_t > 2.5:
				_leave_cover()
		1:   # מתחבא (כמוך מאחורי מכונית)
			_set_shape(2)
			z._dir = face
			z.velocity.x = move_toward(z.velocity.x, 0.0, 900.0 * delta)
			if _st <= 0.0:
				_cover_phase = 2
				_set_shape(0)
				_start_aim(pl)
				state = B_COVER
				_st = (B_AIM_T2 if _phase2 else B_AIM_T) * 0.8
		2:   # מציץ ומכוון
			_set_shape(0)
			z._dir = face
			z.velocity.x = move_toward(z.velocity.x, 0.0, 900.0 * delta)
			_aim = lerp_angle(_aim, _target_angle(pl), delta * 7.0)
			if _st <= 0.0:
				state = B_BURST
				b_bursts += 1
				_left = B_SHOTS2 if _phase2 else B_SHOTS
				_shot_t = 0.0
				_hp_at = int(pl.health)


func _leave_cover() -> void:
	_cover_node = null
	_cover_phase = 0
	state = B_WALK
	_b_cd = 0.4
	_set_shape(0)


func _boss_death() -> void:
	var cam: Camera2D = z.get_viewport().get_camera_2d()
	if cam != null and cam.has_method("shake"):
		cam.shake(14.0, 0.6)
	Sfx.play("s4_call", z.global_position, 0.0, 0.0, 1, 0.7)
	Particles.burst(_main(), z.global_position + Vector2(0, -60), "hit", Vector2.UP, int(24.0 * Quality.gore()))
	Particles.burst(_main(), z.global_position + Vector2(0, -50), "mist", Vector2.UP, 8)
	var pl := player()
	if pl != null:
		pl._say("Four of seven. I'm sorry, brother.", Color("bfe8ff"))


func wants_redraw() -> bool:
	return state != TANK or _scene_actor() or z._flash > 0.0


# ============================================================
#  ציור: חלוק מעבדה קרוע, עור אפור-כחלחל, ראש מגולח עם סיכות, אינפוזיה, צמיד ברקוד, גידולי ECHO זוהרים.
#  בוס: מדי שדה + אפוד, רתמה קרועה, "4" על הכתף, פטרייה שעולה מהצוואר על חצי הפנים, רובה שהפטרייה עטפה.
# ============================================================
func draw() -> bool:
	if _var.is_empty():
		return false
	begin_draw()
	var boss := _boss()
	var tt: float = z._time
	var rot := 0.0
	var pivot := Vector2(0.0, -14.0)
	var crouch := 0.0
	var roll := false
	var inside := state == TANK or (_scene_actor() and tank_actor)
	if not z.dead:
		match state:
			ROLL, B_ROLL:
				roll = true
				var k := 1.0 - clampf(_st / (ROLL_T if state == ROLL else B_ROLL_T), 0.0, 1.0)
				rot = k * TAU
				crouch = 1.0
			STRIKE:
				crouch = clampf(_st / (STRIKE_WIND + STRIKE_HIT), 0.0, 1.0) * 0.9
				rot = -0.12
			RECOVER, DUCK:
				crouch = 0.85
			B_COVER:
				crouch = 0.8 if _cover_phase == 1 else 0.0
			STIFF:
				rot = sin(tt * 9.0) * 0.04
			B_CALL:
				rot = -0.1
	if rot != 0.0:
		var s: Vector2 = Vector2(z._dir * z.wf * z.sc, z.sc)
		var base: Transform2D = Transform2D(z.react_tilt(), Vector2(0.0, z.react_hop() * z.sc)) * Transform2D(0.0, s, 0.0, Vector2.ZERO)
		DrawBatch.set_transform_matrix(z, base * Transform2D(rot, pivot) * Transform2D(0.0, -pivot))
	if boss:
		_draw_boss(tt, crouch, roll)
	else:
		_draw_specimen(tt, crouch, roll, inside)
	end_draw()
	if _ring >= 0.0 and not z.dead:   # טבעת "למד" (העתקה / התעוררות)
		var k := _ring / 0.45
		var c: Vector2 = Vector2(0.0, -30.0 * z.sc)
		DrawBatch.arc(z, c, (16.0 + 30.0 * k) * z.sc, 0.0, TAU, 24, Color(0.75, 1.0, 0.55, 0.8 * (1.0 - k)), 2.5)
	if boss and not z.dead and (state == B_AIM or (state == B_COVER and _cover_phase == 2)):   # לייזר הכיוון
		var mz: Vector2 = _muzzle_world() - z.global_position
		var dir := Vector2.from_angle(_aim)
		var blink := 0.5 + 0.5 * absf(sin(tt * 24.0))
		var lc := Color(1.0, 0.15, 0.1, 0.35 + 0.35 * blink) if _aim_y == AIM_HIGH else Color(1.0, 0.75, 0.1, 0.4 + 0.4 * blink)
		DrawBatch.line(z, mz, mz + dir * 620.0, lc, 1.4)
		DrawBatch.circle(z, mz, 2.5, Color(lc, 0.9))
	return true


func _eye_col(boss: bool) -> Color:
	var green := boss or _ring >= 0.0 or (learned and _copy_cd > 0.0)
	if _scene_actor():
		green = true
	return Color(0.6, 1.0, 0.5) if green else Color(1.0, 0.25, 0.18)


func _frosted() -> float:
	if state == TANK or (_scene_actor() and tank_actor):
		return 1.0
	if state == STIFF:
		return clampf(_st / STIFF_T, 0.3, 1.0)
	if z.has_meta("s60_frozen") and int(z.get_meta("s60_frozen")) > Time.get_ticks_msec():
		return 0.9
	return 0.0


func _draw_specimen(tt: float, crouch: float, roll: bool, inside: bool) -> void:
	var sk := col(z.skin)
	var gown := col(z.shirt)
	var gown_d := col(Art.shade(z.shirt, 0.25))
	var bob := 0.0
	var float_k := 0.0
	if inside:   # תלוי בנוזל: מרחף קצת, ראש מורכן
		float_k = 1.0
		bob = sin(tt * 1.3 + float(_var[4])) * 1.2
	var hip := Vector2(0.0, -22.0 + crouch * 9.0 + bob)
	var sh := Vector2(1.0 + crouch * 3.0, -38.0 + crouch * 13.0 + bob)
	var head := sh + Vector2(3.0 + crouch * 2.0, -8.0 + crouch * 1.0)
	if inside:
		head = sh + Vector2(1.5, -7.0)   # מורכן
	head += Vector2(tilt * 3.0, 0.0)
	if talking and awake:
		head += Vector2(0.0, sin(t * 6.0) * 0.4)
	# רגליים: חשופות (אפורות), כפות יחפות
	var f: Array = feet(4.5, 2.2)
	if inside:
		f = [Vector2(2.0, -2.0 + bob), Vector2(-3.0, -1.0 + bob)]
	elif roll or crouch > 0.6:
		f = [Vector2(7.0, -1.0), Vector2(-6.0, 0.0)]
	var legc := col(Art.shade(z.skin, 0.12))
	for i in 2:
		var ft: Vector2 = f[1 - i]
		var hp := hip + Vector2(-2.0 + float(i) * 4.0, 0.0)
		var kn := Art.joint(hp, ft + Vector2(0, -2), 11.0, 11.0, 1.0)
		if crouch > 0.5:
			kn = hp + Vector2(9.0, 1.0 - crouch * 2.0) if i == 1 else hp + Vector2(-2.0, 8.0)
		Art.limb(z, PackedVector2Array([hp, kn, ft + Vector2(0, -2)]), 3.6, legc if i == 1 else col(Art.shade(z.skin, 0.28)), Art.OUTLINE, false, true)
		Art.fill(z, PackedVector2Array([ft + Vector2(-2.5, -3.5), ft + Vector2(3.5, -2.5), ft + Vector2(5.0, 0.3), ft + Vector2(-3.0, 0.3)]), col(Art.shade(z.skin, 0.35)), Art.OUTLINE, 0.8)
	# יד אחורית
	var hb: Vector2 = sh + Vector2(-5.0 + sin(z._walk_phase) * 3.0, 16.0)
	if inside:
		hb = sh + Vector2(-3.0, 17.0)
	elif state == STIFF:
		hb = sh + Vector2(6.0, 12.0)
	elif state in [ROLL, RECOVER, DUCK]:
		hb = sh + Vector2(8.0, 8.0)
	_arm(sh + Vector2(-3.0, 1.0), hb, col(Art.shade(z.skin, 0.25)), false)
	# החלוק: פתוח בגב, מכתף ועד מתחת לברכיים, שוליים קרועים
	var hem := hip.y + 9.0 - crouch * 4.0
	var bp := PackedVector2Array([sh + Vector2(-6.5, -1.0), sh + Vector2(6.0, 0.0), Vector2(hip.x + 7.5, hem - 1.0),
		Vector2(hip.x + 4.0, hem + 2.0), Vector2(hip.x + 1.0, hem - 1.5), Vector2(hip.x - 2.5, hem + 2.5), Vector2(hip.x - 5.5, hem - 1.0),
		Vector2(hip.x - 8.0, hem + 1.0)])
	Art.fill_shaded(z, bp, gown, 0.12, 0.35)
	DrawBatch.line(z, sh + Vector2(-6.0, 2.0), Vector2(hip.x - 7.0, hem - 2.0), gown_d, 1.2)   # הפתח בגב
	for q in 3:   # קשרים
		var ky := lerpf(sh.y + 4.0, hip.y, float(q) / 2.5)
		DrawBatch.line(z, Vector2(sh.x - 6.5, ky), Vector2(sh.x - 9.0, ky + 1.5), gown_d, 0.8)
	var pat: int = _var[0]
	if pat == 1:   # חלוק עם נקודות (בית חולים)
		for q in 5:
			DrawBatch.circle(z, sh + Vector2(-3.0 + float(q % 3) * 3.5, 5.0 + (7.0 if q >= 3 else 0.0)), 0.8, col(Color("7a9ab0")))
	elif pat == 2:   # פסים
		for q in 3:
			DrawBatch.line(z, sh + Vector2(-5.0, 4.0 + float(q) * 6.0), sh + Vector2(5.0, 4.5 + float(q) * 6.0), col(Color(0.5, 0.6, 0.6, 0.6)), 0.9)
	var blood: float = _var[1]
	Art.oval(z, sh + Vector2(2.5, 9.0), 2.5 + 2.0 * blood, 3.0 + 4.0 * blood, Color(0.42, 0.05, 0.05, 0.75), 0.3, Art.NONE)
	DrawBatch.line(z, sh + Vector2(3.0, 12.0), Vector2(hip.x + 3.0, hem + 1.0), Color(0.42, 0.05, 0.05, 0.6), 1.0)
	# תג מספר על החזה (ברקוד)
	var tg := sh + Vector2(-2.0, 3.0)
	DrawBatch.rect(z, Rect2(tg, Vector2(5.0, 3.2)), col(Color("e8ece4")))
	for q in 4:
		DrawBatch.rect(z, Rect2(tg + Vector2(0.6 + float(q) * 1.1, 0.5), Vector2(0.5 if (q + int(_var[4])) % 2 == 0 else 0.3, 2.2)), Color("1a1a1a"))
	# גידולי ECHO על הכתף / הגב עם קשריות זוהרות
	var side: float = _var[2]
	var gp := sh + Vector2(-4.0 if side < 0.0 else 3.0, 2.0)
	Art.oval(z, gp, 4.2, 3.0, col(Color("5a6a3a")), 0.4, Art.OUTLINE, 0.9)
	Art.oval(z, gp + Vector2(-2.0, 4.0), 2.6, 2.0, col(Color("6a7a42")), 0.0, Art.NONE)
	var pulse := 0.6 + 0.4 * sin(tt * 3.0 + float(_var[4]))
	if not z.dead:
		DrawBatch.circle(z, gp + Vector2(1.0, -1.0), 1.2, Color(0.75, 1.0, 0.55, 0.9 * pulse))
		DrawBatch.circle(z, gp + Vector2(-2.2, 3.5), 0.9, Color(0.75, 1.0, 0.55, 0.8 * pulse))
		Art.glow(z, gp, 5.0, Color(0.75, 1.0, 0.55, 0.25 * pulse))
	DrawBatch.line(z, gp, gp + Vector2(-3.0, -6.0), col(Color("5a6a3a")), 1.0)   # חוטים לצוואר
	# ראש מגולח: סיכות ניתוח, אלקטרודות
	Art.oval_shaded(z, head, 5.6, 6.0, sk, 0.0)
	DrawBatch.arc(z, head + Vector2(-0.5, 0.0), 4.4, -2.7, -0.6, 8, col(Color("6a5050")), 0.8)   # התפר
	for q in 4:
		var a := -2.5 + float(q) * 0.5
		var sp := head + Vector2(-0.5, 0.0) + Vector2.from_angle(a) * 4.4
		DrawBatch.line(z, sp + Vector2.from_angle(a) * -0.9, sp + Vector2.from_angle(a) * 0.9, col(Color("c8ccd0")), 0.6)
	DrawBatch.circle(z, head + Vector2(-3.5, -3.0), 0.9, col(Color("d0d4d8")))   # אלקטרודה
	DrawBatch.line(z, head + Vector2(-3.5, -3.0), head + Vector2(-8.0, 2.0), col(Color("303438")), 0.6)
	# פנים
	Art.oval(z, head + Vector2(2.8, -0.6), 2.3, 1.7, Color(0.08, 0.04, 0.08, 0.5), 0.0, Art.NONE)
	var open := 0.5
	if state in [STRIKE, SWIPE] or (state == STIFF and int(tt * 2.0) % 3 == 0):
		open = 2.0
	if talking and awake:
		open = 0.6 + absf(sin(t * 12.0)) * 1.6
	open += smile * 0.5
	DrawBatch.colored_polygon(z, PackedVector2Array([head + Vector2(1.2, 2.4), head + Vector2(5.0, 2.0), head + Vector2(4.6, 3.6 + open), head + Vector2(1.6, 3.6 + open * 0.7)]), col(Color("2a0a0c")))
	DrawBatch.line(z, head + Vector2(1.8, 2.6), head + Vector2(4.6, 2.3), col(Color("d8d0a8")), 0.7)
	var eyes_open := not inside or awake
	if z.dead or not eyes_open:
		DrawBatch.line(z, head + Vector2(2.4, -1.0), head + Vector2(4.6, -0.8), col(Color("2a2024")), 0.8)
	else:
		var ec := _eye_col(false)
		DrawBatch.circle(z, head + Vector2(3.6, -0.8), 1.0, ec)
		Art.glow(z, head + Vector2(3.4, -0.8), 3.5 + (2.0 if _ring >= 0.0 else 0.0), Color(ec, 0.35))
	# יד קדמית: צינור אינפוזיה תלוי, צמיד ברקוד
	var hf: Vector2 = sh + Vector2(4.0 + sin(z._walk_phase + PI) * 3.0, 15.0)
	if inside:
		hf = sh + Vector2(3.0, 16.0)
	elif state == STIFF:
		hf = sh + Vector2(13.0, 3.0)   # ידיים מושטות קשיחות
	elif state == STRIKE:
		var k := 1.0 - clampf(_st / (STRIKE_WIND + STRIKE_HIT), 0.0, 1.0)
		hf = sh + Vector2(6.0, 10.0).lerp(Vector2(14.0, -12.0), k)
	elif state == SWIPE:
		hf = sh + (Vector2(-6.0, -6.0) if _st > 0.0 else Vector2(15.0, 4.0))
	elif state == HUNT:
		hf = sh + Vector2(12.0, 2.0 + sin(z._walk_phase) * 2.0)
	elif state in [ROLL, RECOVER, DUCK]:
		hf = sh + Vector2(10.0, 9.0)
	_arm(sh + Vector2(3.0, 1.0), hf, sk, true)
	# כפור
	var fr := _frosted()
	if fr > 0.0:
		var fc := Color(0.85, 0.95, 1.0, 0.55 * fr)
		Art.oval(z, sh + Vector2(0.0, -1.0), 7.0, 2.0, fc, 0.0, Art.NONE)
		Art.oval(z, head + Vector2(-1.0, -4.5), 4.5, 1.6, fc, -0.2, Art.NONE)
		for q in 4:
			var ix := hip.x - 6.0 + float(q) * 4.0
			DrawBatch.colored_polygon(z, PackedVector2Array([Vector2(ix - 1.0, hem), Vector2(ix + 1.0, hem), Vector2(ix, hem + 3.0 + float(q % 2) * 2.0)]), Color(0.85, 0.95, 1.0, 0.7 * fr))


func _arm(s: Vector2, h: Vector2, sk: Color, front: bool) -> void:
	var el := Art.joint(s, h, 9.0, 9.5, -1.0)
	var c := sk if front else sk
	# שרוול קצר של החלוק
	Art.limb(z, PackedVector2Array([s, el, h]), 3.2, c, Art.OUTLINE, false, true)
	Art.limb(z, PackedVector2Array([s, s.lerp(el, 0.45)]), 4.4, col(Art.shade(z.shirt, 0.1 if front else 0.3)), Art.OUTLINE, false, true)
	# ציפורניים
	var dir := (h - el).normalized()
	for q in 3:
		DrawBatch.line(z, h, h + dir.rotated((float(q) - 1.0) * 0.4) * 4.0, col(Color("cfc6a0")), 0.8)
	if front:
		var wr := el.lerp(h, 0.75)
		DrawBatch.line(z, wr + dir.orthogonal() * 1.8, wr - dir.orthogonal() * 1.8, col(Color("e8ece4")), 1.6)   # צמיד
		if _var[3]:   # צינור אינפוזיה תלוי
			var ip := el.lerp(h, 0.4)
			var sw: float = sin(z._time * 2.0) * 2.0
			DrawBatch.polyline(z, PackedVector2Array([ip, ip + Vector2(-2.0 + sw, 7.0), ip + Vector2(-4.0 + sw * 1.5, 13.0)]), Color(0.8, 0.9, 0.95, 0.6), 0.8)
			DrawBatch.rect(z, Rect2(ip + Vector2(-1.2, -1.0), Vector2(2.4, 2.0)), col(Color("e0e4e8")))


# ---- SUBJECT FOUR ----
func _draw_boss(tt: float, crouch: float, roll: bool) -> void:
	var sk := col(z.skin)
	var cam := col(z.shirt)
	var cam_d := col(Art.shade(z.shirt, 0.3))
	var vest := col(Color("262a22"))
	var breathe := sin(tt * 2.2) * 0.5
	var hip := Vector2(0.0, -22.0 + crouch * 9.0)
	var sh := Vector2(1.0 + crouch * 3.0, -39.0 + crouch * 12.0 + breathe)
	var head := sh + Vector2(2.5 + crouch * 2.0, -8.5)
	if state == B_CALL:
		head += Vector2(-1.0, -1.5)
	var f: Array = feet(5.0, 2.4)
	if roll or crouch > 0.6:
		f = [Vector2(8.0, -1.0), Vector2(-7.0, 0.0)]
	elif state in [B_AIM, B_BURST, B_RELOAD] or (state == B_COVER and _cover_phase == 2):
		f = [Vector2(6.0, 0.0), Vector2(-6.0, 0.0)]   # עמידת ירי
	for i in 2:
		var ft: Vector2 = f[1 - i]
		var hp := hip + Vector2(-2.5 + float(i) * 5.0, 0.0)
		var kn := Art.joint(hp, ft + Vector2(0, -3), 11.0, 11.0, 1.0)
		if crouch > 0.5:
			kn = hp + Vector2(10.0, -1.0) if i == 1 else hp + Vector2(-2.0, 9.0)
		Art.limb(z, PackedVector2Array([hp, kn, ft + Vector2(0, -3)]), 4.6, cam if i == 1 else cam_d, Art.OUTLINE, false, true)
		DrawBatch.rect(z, Rect2(kn + Vector2(-2.5, -2.0), Vector2(5.0, 4.0)), col(Color("1c1e1a")))   # מגן ברך
		Art.fill(z, PackedVector2Array([ft + Vector2(-3.5, -5.0), ft + Vector2(3.0, -5.0), ft + Vector2(6.0, -1.5), ft + Vector2(6.0, 0.5), ft + Vector2(-3.5, 0.5)]), col(z.shoe), Art.OUTLINE, 0.9)
	# יד אחורית (מחזיקה את הקנה)
	var la: Vector2 = Vector2(cos(_aim) * z._dir, sin(_aim)).normalized() if (state in [B_AIM, B_BURST] or (state == B_COVER and _cover_phase == 2)) else Vector2(0.9, 0.35).normalized()
	if state == B_MELEE:
		var k := clampf(_st / B_MELEE_WIND, 0.0, 1.0)
		la = Vector2(-0.4, -0.9).lerp(Vector2(1.0, 0.1), 1.0 - k).normalized()
	elif state == B_CALL:
		la = Vector2(0.3, 0.95).normalized()
	elif roll:
		la = Vector2(1.0, 0.0)
	var piv := _pivot_local() + Vector2(0.0, crouch * 2.0)
	if crouch > 0.6:
		piv = sh + Vector2(4.0, 6.0)
	var kick := 1.6 if _flash > 0.0 else 0.0
	var grip := piv + la * (4.0 - kick)
	var fore := piv + la * (13.0 - kick)
	Art.limb(z, PackedVector2Array([sh + Vector2(-3.0, 1.0), Art.joint(sh + Vector2(-3.0, 1.0), fore, 9.0, 9.5, -1.0), fore]), 4.2, cam_d, Art.OUTLINE, false, true)
	# הגוף: חולצת מדים + אפוד עם כיסים, רתמה קרועה
	var body := PackedVector2Array([sh + Vector2(-7.0, -1.0), sh + Vector2(7.0, 0.0), hip + Vector2(6.0, 2.0), hip + Vector2(-6.0, 2.0)])
	Art.fill_shaded(z, body, cam, 0.12, 0.35)
	var vp := PackedVector2Array([sh + Vector2(-5.5, 2.0), sh + Vector2(6.5, 2.5), hip + Vector2(5.5, -2.0), hip + Vector2(-5.0, -2.0)])
	Art.fill(z, vp, vest, Art.OUTLINE, 1.0)
	for q in 3:   # כיסי מחסניות
		DrawBatch.rect(z, Rect2(sh + Vector2(-3.5 + float(q) * 3.4, 8.0), Vector2(2.8, 4.5)), col(Color("3a3e30")))
	DrawBatch.line(z, sh + Vector2(-5.0, 0.0), hip + Vector2(4.0, -3.0), col(Color("1a1a14")), 1.4)   # רתמה
	DrawBatch.line(z, hip + Vector2(4.0, -3.0), hip + Vector2(8.0, 6.0), col(Color("1a1a14")), 1.0)   # קרועה ותלויה
	DrawBatch.rect(z, Rect2(hip + Vector2(-6.0, -1.0), Vector2(12.0, 2.4)), col(Color("1e1e18")))   # חגורה
	# "4" על הכתף (טלאי צהוב)
	var pt := sh + Vector2(-4.0, 2.5)
	DrawBatch.rect(z, Rect2(pt + Vector2(-2.5, -2.5), Vector2(5.0, 5.5)), col(Color("c8a838")))
	DrawBatch.line(z, pt + Vector2(0.6, -2.0), pt + Vector2(-1.6, 1.0), Color("141410"), 0.7)
	DrawBatch.line(z, pt + Vector2(-1.6, 1.0), pt + Vector2(1.6, 1.0), Color("141410"), 0.7)
	DrawBatch.line(z, pt + Vector2(0.8, -0.5), pt + Vector2(0.8, 2.6), Color("141410"), 0.7)
	# פטרייה: מהגב והצוואר עד הלחי
	var pulse := 0.6 + 0.4 * sin(tt * 2.6)
	Art.oval(z, sh + Vector2(-5.0, 4.0), 4.0, 6.0, col(Color("586838")), 0.2, Art.OUTLINE, 0.9)
	DrawBatch.polyline(z, PackedVector2Array([sh + Vector2(-4.0, 0.0), head + Vector2(-3.0, 4.0), head + Vector2(-2.0, -1.0)]), col(Color("5e6e3a")), 2.2)
	# ראש: מגולח, צלקות, הפטרייה מכסה את חצי הפנים האחורי
	Art.oval_shaded(z, head, 5.8, 6.2, sk, 0.0)
	Art.oval(z, head + Vector2(-2.5, 0.5), 3.4, 5.0, col(Color("62723e")), 0.1, Art.NONE)
	if not z.dead:
		DrawBatch.circle(z, head + Vector2(-3.0, -1.5), 1.0, Color(0.75, 1.0, 0.55, 0.9 * pulse))
		DrawBatch.circle(z, head + Vector2(-2.2, 2.5), 0.8, Color(0.75, 1.0, 0.55, 0.8 * pulse))
		DrawBatch.circle(z, sh + Vector2(-5.5, 5.0), 1.1, Color(0.75, 1.0, 0.55, 0.85 * pulse))
	DrawBatch.line(z, head + Vector2(1.0, -5.0), head + Vector2(4.5, -2.0), col(Color("6a5050")), 0.8)   # צלקת
	# פנים: לסת סגורה, עין ירוקה זוהרת (מקושר)
	DrawBatch.colored_polygon(z, PackedVector2Array([head + Vector2(1.6, 2.6), head + Vector2(5.0, 2.2), head + Vector2(4.6, 3.8), head + Vector2(1.8, 3.8)]), col(Color("2a1414")))
	if z.dead:
		DrawBatch.line(z, head + Vector2(2.4, -1.0), head + Vector2(4.8, -0.8), Color(0.2, 0.06, 0.06), 0.8)
	else:
		var ec := _eye_col(true)
		DrawBatch.circle(z, head + Vector2(3.8, -0.8), 1.1, ec)
		Art.glow(z, head + Vector2(3.6, -0.8), 6.0 + 2.0 * pulse, Color(ec, 0.35))
	# הרובה: גוף, מחסנית, קנה. הפטרייה עוטפת אותו
	var tr := Transform2D(la.angle(), grip)
	Art.fill(z, tr * PackedVector2Array([Vector2(-8, -2.2), Vector2(14, -2.2), Vector2(14, 1.6), Vector2(-8, 1.6)]), col(Color("22241e")), Art.OUTLINE, 1.0)
	Art.fill(z, tr * PackedVector2Array([Vector2(-12, -1.6), Vector2(-7, -2.0), Vector2(-7, 3.5), Vector2(-12, 4.5)]), col(Color("3a2e22")), Art.OUTLINE, 0.9)   # קת
	Art.fill(z, tr * PackedVector2Array([Vector2(3, 1.6), Vector2(6.5, 1.6), Vector2(7.5, 8.0), Vector2(4.0, 8.0)]), col(Color("1a1c18")), Art.OUTLINE, 0.8)   # מחסנית
	DrawBatch.line(z, tr * Vector2(14, -0.4), tr * Vector2(22, -0.4), Art.OUTLINE, 2.0)
	for q in 3:   # חוטי פטרייה על הרובה
		var a0 := tr * Vector2(-4.0 + float(q) * 6.0, -2.2)
		DrawBatch.line(z, a0, tr * Vector2(-1.0 + float(q) * 6.0, 2.2), col(Color("6a7a42")), 1.0)
	if not z.dead:
		DrawBatch.circle(z, tr * Vector2(9.0, -2.4), 0.9, Color(0.75, 1.0, 0.55, 0.8 * pulse))
	if _flash > 0.0:
		var m := tr * Vector2(23, -0.4)
		Art.glow(z, m, 7.0, Color(1.0, 0.8, 0.3, 0.9))
		DrawBatch.colored_polygon(z, PackedVector2Array([m + la.orthogonal() * 2.5, m + la * 9.0, m - la.orthogonal() * 2.5]), Color(1.0, 0.92, 0.55))
	# יד קדמית על הידית
	Art.limb(z, PackedVector2Array([sh + Vector2(3.0, 1.0), Art.joint(sh + Vector2(3.0, 1.0), grip, 9.0, 9.5, -1.0), grip]), 4.4, cam, Art.OUTLINE, false, true)
	DrawBatch.circle(z, grip, 2.0, sk)
	DrawBatch.circle(z, fore, 1.9, col(Art.shade(z.skin, 0.2)))
