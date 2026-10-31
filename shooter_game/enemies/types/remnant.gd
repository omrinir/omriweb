extends "res://enemies/zombie_type.gd"
# ============================================================
#  REMNANT (שלב 62, "THE HIVE MIND") - הד של קרב ישן: זיכרון שהכוורת שמרה, עולה מבריכת זיכרון (MemoryPool.rise())
#    כגוף שקוף בצבע אור הזיכרון (Decor.MEM), עם שורות סריקה, "גליץ'" שמזיז אותו הצידה ובבואה שנגררת אחריו.
#  מה הם למדו, וממה: כל קרב של הגיבור נשלח הביתה. הכוורת לא רק זוכרת שהוא ניצח - היא זוכרת *איך* הם נלחמו בו.
#    "THEY REMEMBER YOUR FIGHTS NOW": כל REMNANT משחזר את הטריק של זיכרון אחד (memory = Decor.MEMORIES):
#    0 THE FIRST     - הבוס הראשון: דלת מכונית כמגן (חוסמת קליעים מלפנים בפס שלה). SLAM - מרים אותה מעל הראש
#                      (DOOR_WIND - החזית פתוחה x OPEN_MULT) וחובט.
#    1 THE SPITTER   - שומר מרחק (SPIT_R) ויורק חומצה בקשת (acid.gd).
#    2 SUBJECT FOUR  - מתגלגל אליך (ROLL - "PHASED": קליעים עוברים דרכו) ו-UPPERCUT מקרוב. אחרי - פתוח (RECOVER, x OPEN_MULT).
#    3 THE HOUND     - על ארבע: מתכופף (POUNCE_WIND) וזינוק ארוך עליך. נוחת - פתוח.
#  כל השאר: SWIPE קרוב. RISE - עולה מהבריכה (לא פגיע עד שהוא שלם).
#  לומד (main meta "rmn_kills" >= LEARN_KILLS): "THEY USE IT ALL AT ONCE NOW" - כל REMNANT חדש מקבל טריק שני של זיכרון
#    אחר (tricks): THE FIRST שגם יורק, כלב שגם מתגלגל... והבריכות משחררות זוגות (stage_62).
#  לשנות: HP_BY, DOOR_*, OPEN_MULT, SPIT_*, ROLL_*, UPPER_*, POUNCE_*, SWIPE_*, RISE_T, LEARN_KILLS, CD.
# ============================================================

const Decor := preload("res://effects/s62_decor.gd")
const AcidScript := preload("res://acid.gd")
const U := Decor.U

const SOUNDS := {
	"rmn_rise": {"rev": 0.6, "layers": [["S", 220, 660, 0.0, 0.8, 0.2, 2.0, 0.15, 1.0, 0.01], ["S", 330, 990, 0.05, 0.8, 0.2, 2.0, 0.1, 1.0, 0.01], ["N", 0, 0, 0.0, 0.8, 0.3, 2.0, 0.15, 1.0, 0, 0.7]]},
	"rmn_glitch": [["Q", 180, 90, 0.0, 0.08, 0.0, 30.0, 0.15, 0.5, 0], ["N", 0, 0, 0.0, 0.06, 0.0, 40.0, 0.15, 1.0, 0, 0.8]],
	"rmn_fade": {"rev": 0.7, "layers": [["S", 880, 220, 0.0, 0.9, 0.0, 2.5, 0.18, 1.0, 0.02], ["S", 1320, 330, 0.0, 0.8, 0.0, 2.5, 0.1, 1.0, 0.02], ["N", 0, 0, 0.0, 0.7, 0.0, 3.0, 0.2, 1.0, 0, 0.6]]},
	"rmn_slam": {"rev": 0.3, "drive": 2.0, "layers": [["C", 0, 0, 0.0, 0.3, 0.0, 9.0, 0.8, 1.0, 0], ["S", 520, 300, 0.0, 0.35, 0.0, 6.0, 0.3, 1.0, 0], ["N", 0, 0, 0.0, 0.3, 0.0, 9.0, 0.4, 0.4, 0]]},
	"rmn_door": [["S", 1400, 1300, 0.0, 0.1, 0.0, 30.0, 0.2, 1.0, 0], ["S", 2200, 2100, 0.0, 0.08, 0.0, 40.0, 0.12, 1.0, 0], ["Q", 300, 150, 0.0, 0.06, 0.0, 30.0, 0.08, 0.5, 0]],
	"rmn_whoosh": [["N", 0, 0, 0.0, 0.35, 0.05, 7.0, 0.4, 0.3, 0, 0.1], ["S", 600, 1200, 0.0, 0.3, 0.05, 6.0, 0.08, 1.0, 0]],
	"rmn_howl": {"rev": 0.6, "drive": 1.6, "layers": [["V", 330, 520, 0.0, 0.8, 0.1, 2.0, 0.5, 1.0, 0.05, 0, [800, 1300, 30]], ["S", 990, 1560, 0.0, 0.8, 0.1, 2.0, 0.08, 1.0, 0.02]]},
}

const HP_BY := [78, 56, 62, 50]
const SCALE_BY := [1.22, 1.0, 1.02, 1.0]
const DOOR_Y := -32.0             # מרכז הדלת (יחידות ציור)
const DOOR_H := 22.0              # חצי גובה הפס שהיא חוסמת
const DOOR_R := 92.0
const DOOR_WIND := 0.6
const DOOR_DMG := 1
const OPEN_MULT := 1.4
const SPIT_R := Vector2(220.0, 540.0)
const SPIT_WIND := 0.45
const SPIT_CD := 2.4
const ROLL_R := Vector2(150.0, 360.0)
const ROLL_V := 420.0
const ROLL_T := 0.45
const UPPER_R := 72.0
const UPPER_WIND := 0.18
const UPPER_DMG := 1
const POUNCE_R := Vector2(190.0, 430.0)
const POUNCE_WIND := 0.45
const POUNCE_T := 0.55
const POUNCE_DMG := 1
const SWIPE_R := 56.0
const SWIPE_WIND := 0.35
const SWIPE_DMG := 1
const RECOVER := 0.6
const RISE_T := 0.9
const CD := Vector2(0.9, 1.7)
const WAKE_R := 900.0
const LEARN_KILLS := 4

enum {RISE, WALK, DOOR_W, DOOR_SLAM, SPIT_W, ROLL, UPPER_W, UPPER, POUNCE_W, POUNCE, SWIPE_W, SWIPE, RECOVERY}
var state := WALK
# לבדיקות
var blocks := 0
var phased := 0
var slams := 0
var slam_hits := 0
var spits := 0
var rolls := 0
var uppers := 0
var upper_hits := 0
var pounces := 0
var pounce_hits := 0
var swipes := 0
var swipe_hits := 0

var memory := -1                  # Decor.MEMORIES (stage_62 / set_memory)
var tricks: Array = []
var learned := false
var _st := 0.0
var _cd := 1.0
var _spit_cd := 1.0
var _hit := false
var _pop_t := 0.0
var _jump_cd := 0.0
var _mult := 1.0
var _seed := 0.0
var _glitch := 0.0
var _glitch_x := 0.0
var _glitch_cd := 1.0
var _dpos := Vector2.ZERO
var _said_all := false


func stats() -> Dictionary:
	var m := memory if memory >= 0 else 0
	return {"name": "REMNANT", "hp": HP_BY[m], "walk": 52.0, "chase": 100.0 if m != 3 else 150.0, "damage": 1, "bite_delay": 1.0,
		"scale": SCALE_BY[m], "width": 1.0, "duck": 0.0, "cover": 0.0, "skin": Color("9ae8ff"), "shirt": Color("4aa8c8"), "pants": Color("2a6a88"),
		"shoe": Color("1a4a60"), "points": 360, "ragdoll": false, "flesh": false}


func brain_overrides() -> Dictionary:
	return {"aggression": 0.8}


func use_brain_movement() -> bool:
	return false


func can_bite() -> bool:
	return false


func can_groan() -> bool:
	return false


func death_sound() -> String:
	return "rmn_fade"


func _main() -> Node:
	return z.get_parent()


func setup() -> void:
	_seed = float(z.get_instance_id() % 997) * 0.71
	if memory < 0:
		memory = randi() % 4
	_apply()


# השלב בוחר זיכרון (הבריכה). rising = עולה מהבריכה עכשיו
func set_memory(i: int, rising := true) -> void:
	memory = clampi(i, 0, 3)
	_apply()
	if rising:
		state = RISE
		_st = RISE_T
		Sfx.play("rmn_rise", z.global_position, 0.0, 0.1, 2)


func _apply() -> void:
	var m := _main()
	learned = m != null and int(m.get_meta("rmn_kills", 0)) >= LEARN_KILLS
	tricks = [memory]
	if learned:
		var extra := (memory + 1 + randi() % 3) % 4
		if memory == 3 and extra == 0:   # כלב לא מחזיק דלת
			extra = 1 + randi() % 2
		if extra == 3:   # זינוק - כל אחד יכול
			pass
		tricks.append(extra)
	z.sc = float(SCALE_BY[memory])
	z.max_hp = int(HP_BY[memory]) + (12 if learned else 0)
	z.hp = z.max_hp
	if memory == 3:
		_resize(Vector2(42.0, 34.0))
	else:
		_resize(Vector2(26.0, 56.0))


func _resize(b: Vector2) -> void:
	var rs := z._shape.shape as RectangleShape2D
	rs.size = Vector2(b.x * z.wf * z.sc, b.y * z.sc)
	z._shape.position = Vector2(0.0, -b.y * 0.5 * z.sc)


func has_trick(i: int) -> bool:
	return tricks.has(i)


func _open() -> bool:
	return state in [DOOR_W, DOOR_SLAM, RECOVERY, POUNCE, UPPER]


# ============================================================
#  תנועה
# ============================================================
func physics(pl: Node, delta: float) -> bool:
	_st -= delta
	_cd -= delta
	_spit_cd -= delta
	_pop_t -= delta
	_jump_cd -= delta
	_glitch -= delta
	_glitch_cd -= delta
	if z.dead:
		return false
	if _glitch_cd <= 0.0:   # גליץ': הזיכרון קופץ לרגע הצידה
		_glitch_cd = randf_range(0.6, 1.8)
		_glitch = 0.09
		_glitch_x = randf_range(-6.0, 6.0)
		if randf() < 0.3 and Art.on_screen(z, z.global_position, -20.0):
			Sfx.play("rmn_glitch", z.global_position, -10.0, 0.2, 2)
	if not z.is_on_floor():
		z.velocity.y += z.gravity * delta
	var has: bool = pl != null and not pl.dead
	var d: Vector2 = (pl.global_position - z.global_position) if has else Vector2.ZERO
	match state:
		RISE:
			z.velocity.x = 0.0
			if _st <= 0.0:
				state = WALK
				_cd = 0.6
				z._popup("MEMORY: " + String(Decor.MEMORIES[memory]), Decor.MEM, 12, -80.0)
				if tricks.size() > 1 and not _said_all:
					_said_all = true
					var m := _main()
					if m != null and not m.has_meta("rmn_all_said"):
						m.set_meta("rmn_all_said", true)
						z._popup("THEY USE IT ALL AT ONCE NOW", Color("a8f0ff"), 13, -100.0)
		WALK:
			_walk(pl, has, d, delta)
		DOOR_W:
			z.velocity.x = move_toward(z.velocity.x, 0.0, 900.0 * delta)
			if _st <= 0.0:
				state = DOOR_SLAM
				_st = 0.2
				slams += 1
				Sfx.play("rmn_slam", z.global_position, 0.0, 0.1, 2)
				_melee_hit(pl, has, DOOR_R, 70.0, DOOR_DMG, Vector2(z._dir * 1.3, -0.6), "slam")
		DOOR_SLAM, SWIPE, UPPER:
			z.velocity.x = move_toward(z.velocity.x, 0.0, 900.0 * delta)
			if _st <= 0.0:
				_start(RECOVERY, RECOVER)
		SPIT_W:
			z.velocity.x = move_toward(z.velocity.x, 0.0, 900.0 * delta)
			if _st <= 0.0:
				_spit(pl, has)
				_start(RECOVERY, 0.3)
		ROLL:
			z.velocity.x = z._dir * ROLL_V
			if has and absf(d.x) < UPPER_R and signf(d.x) == z._dir:
				_st = 0.0
			if _st <= 0.0:
				z.velocity.x *= 0.3
				if has and absf(d.x) < UPPER_R * 1.4:
					_start(UPPER_W, UPPER_WIND)
				else:
					_start(RECOVERY, RECOVER * 0.5)
		UPPER_W:
			z.velocity.x = move_toward(z.velocity.x, 0.0, 1200.0 * delta)
			if _st <= 0.0:
				state = UPPER
				_st = 0.22
				uppers += 1
				Sfx.play("rmn_whoosh", z.global_position, 0.0, 0.1, 2)
				_melee_hit(pl, has, UPPER_R, 64.0, UPPER_DMG, Vector2(z._dir * 0.5, -1.4), "upper")
		POUNCE_W:
			z.velocity.x = move_toward(z.velocity.x, 0.0, 1200.0 * delta)
			if has and absf(d.x) > 6.0:
				z._dir = signf(d.x)
			if _st <= 0.0:
				state = POUNCE
				_st = POUNCE_T + 0.4
				_hit = false
				pounces += 1
				var dx: float = clampf(d.x, -POUNCE_R.y, POUNCE_R.y) if has else z._dir * 300.0
				z.velocity = Vector2(dx / POUNCE_T, -0.5 * z.gravity * POUNCE_T)
				Sfx.play("rmn_howl", z.global_position, -2.0, 0.1, 2)
		POUNCE:
			if has and not _hit:
				var r := Rect2(z.global_position + Vector2(-24.0, -34.0) * z.sc, Vector2(48.0, 34.0) * z.sc)
				if r.intersects(pl.body_rect()):
					_hit = true
					if pl._roll_t <= 0.0:
						pounce_hits += 1
					pl.hurt(POUNCE_DMG, Vector2(z._dir * 1.2, -0.5))
			if (z.is_on_floor() and _st < POUNCE_T + 0.3) or _st <= 0.0:
				z.velocity.x = 0.0
				_start(RECOVERY, RECOVER * 1.2)
		SWIPE_W:
			z.velocity.x = move_toward(z.velocity.x, 0.0, 1200.0 * delta)
			if _st <= 0.0:
				state = SWIPE
				_st = 0.15
				swipes += 1
				Sfx.play("rmn_whoosh", z.global_position, -3.0, 0.1, 2)
				_melee_hit(pl, has, SWIPE_R + 14.0, 56.0, SWIPE_DMG, Vector2(z._dir * 0.9, -0.3), "swipe")
		RECOVERY:
			z.velocity.x = move_toward(z.velocity.x, 0.0, 900.0 * delta)
			if _st <= 0.0:
				state = WALK
				_cd = randf_range(CD.x, CD.y)
	z.move_and_slide()
	return true


func _start(s: int, tt: float) -> void:
	state = s
	_st = tt


func _drum() -> float:
	return 1.3 if z.has_meta("drum_t") and float(z.get_meta("drum_t")) > float(z._time) else 1.0


func _walk(pl: Node, has: bool, d: Vector2, delta: float) -> void:
	var awake: bool = has and absf(d.y) < 420.0 and (absf(d.x) < WAKE_R or z._alert_t > 0.0)
	if not awake:
		z.velocity.x = move_toward(z.velocity.x, 0.0, 400.0 * delta)
		return
	if absf(d.x) > 6.0:
		z._dir = signf(d.x)
	var dist := absf(d.x)
	var spd: float = z.chase_speed * z.speed_mult * _drum() * (0.75 if has_trick(0) else 1.0)
	var mv: float = z._dir * spd
	if has_trick(1) and not has_trick(0) and memory == 1 and dist < SPIT_R.x * 0.85:   # יורק: שומר מרחק
		mv = -z._dir * spd * 0.8
	elif dist < SWIPE_R * 0.7:
		mv = 0.0
	z.velocity.x = move_toward(z.velocity.x, mv, 700.0 * delta)
	z._walk_phase += delta * absf(z.velocity.x) / (9.0 if memory == 3 else 7.0)
	if z.is_on_floor() and _jump_cd <= 0.0 and (d.y < -80.0 and dist < 240.0 or (z.is_on_wall() and absf(z.velocity.x) < 30.0)):
		z.velocity.y = -640.0
		_jump_cd = 1.4
	if _cd > 0.0 or not z.is_on_floor() or absf(d.y) > 90.0:
		return
	# בוחר טריק לפי המרחק (מכל הזיכרונות שיש לו)
	if has_trick(0) and dist < DOOR_R:
		_start(DOOR_W, DOOR_WIND)
		Sfx.play("rmn_door", z.global_position, -2.0, 0.1, 2)
	elif has_trick(3) and dist > POUNCE_R.x and dist < POUNCE_R.y:
		_start(POUNCE_W, POUNCE_WIND)
	elif has_trick(2) and dist > ROLL_R.x and dist < ROLL_R.y:
		_start(ROLL, ROLL_T)
		rolls += 1
		Sfx.play("rmn_whoosh", z.global_position, -4.0, 0.1, 2)
	elif has_trick(1) and _spit_cd <= 0.0 and dist > SPIT_R.x and dist < SPIT_R.y:
		_start(SPIT_W, SPIT_WIND)
	elif dist < SWIPE_R and not has_trick(0):
		_start(SWIPE_W, SWIPE_WIND)


func _melee_hit(pl: Node, has: bool, reach: float, h: float, dmg: int, knock: Vector2, what: String) -> void:
	if not has:
		return
	var x0: float = z.global_position.x - z._dir * 8.0
	var x1: float = z.global_position.x + z._dir * reach
	var r := Rect2(minf(x0, x1), z.global_position.y - h * z.sc, absf(x1 - x0), h * z.sc)
	if not r.intersects(pl.body_rect()):
		return
	if pl._roll_t <= 0.0:
		match what:
			"slam":
				slam_hits += 1
			"upper":
				upper_hits += 1
			_:
				swipe_hits += 1
	pl.hurt(dmg, knock)


func _spit(pl: Node, has: bool) -> void:
	spits += 1
	_spit_cd = SPIT_CD
	var from: Vector2 = z.global_position + Vector2(z._dir * 8.0, -48.0 * z.sc)
	var to: Vector2 = pl.global_position + Vector2(0, -20) if has else from + Vector2(z._dir * 300.0, 50.0)
	var tt := 0.75
	var a = AcidScript.new()
	_main().add_child(a)
	a.setup(from, Vector2((to.x - from.x) / tt, (to.y - from.y - 0.5 * 900.0 * tt * tt) / tt))
	Sfx.play("spit", from, 0.0, 0.1, 2)


# ============================================================
#  נזק
# ============================================================
func on_damage(_amount: int, hit_pos: Vector2, dir: Vector2, src: Dictionary) -> bool:
	if z.dead:
		return true
	_mult = 1.0
	var s := str(src.get("source", "bullet"))
	var bullet := s == "bullet" or s == "melee" or s == "laser"
	if state == RISE:   # עוד לא שלם
		if bullet and _pop_t <= 0.0:
			_pop_t = 0.6
			z._popup("NOT YET", Decor.MEM, 11, -40.0)
		return false
	if state == ROLL and bullet:   # SUBJECT FOUR: מתגלגל דרך הקליעים
		phased += 1
		if _pop_t <= 0.0:
			_pop_t = 0.6
			z._popup("PHASED", Decor.MEM, 12, -40.0)
		return false
	if bullet and has_trick(0) and not _open() and dir.x * z._dir < 0.0:   # הדלת חוסמת מלפנים
		var ly: float = (hit_pos.y - z.global_position.y) / z.sc
		if absf(ly - DOOR_Y) <= DOOR_H:
			blocks += 1
			z._flash = 0.03
			Game.on_zombie_hit({"source": "bullet", "zone": "shield"})
			if Art.on_screen(z, hit_pos):
				Sfx.play("shield", hit_pos, -4.0, 0.15, 3)
				Particles.burst(_main(), hit_pos, "spark", Vector2(-dir.x, -0.4), 3)
			if _pop_t <= 0.0:
				_pop_t = 0.7
				z._popup("BLOCKED", Decor.MEM, 12, -80.0)
			return false
	if _open():
		_mult = OPEN_MULT
	return true


func damage_mult(_zone: String, _src: Dictionary) -> float:
	var m := _mult
	_mult = 1.0
	return m


func on_death() -> void:
	_dpos = z.global_position
	var m := _main()
	if m != null:
		m.set_meta("rmn_kills", int(m.get_meta("rmn_kills", 0)) + 1)
	z._popup("MEMORY FADES", Decor.MEM, 13, -60.0)
	if Art.on_screen(z, z.global_position):
		Particles.burst(m, z.global_position + Vector2(0, -30.0 * z.sc), "mist", Vector2.UP, 8)
		Particles.burst(m, z.global_position + Vector2(0, -30.0 * z.sc), "spark", Vector2.UP, 6)


func wants_redraw() -> bool:
	return true


# ============================================================
#  ציור: גוף זיכרון שקוף (תכלת), שורות סריקה, בבואה שנגררת, גליץ'. לפי הזיכרון: ענק עם דלת מכונית / יורק עם שק
#  גרון נפוח / חייל עם קסדה (כדור כשמתגלגל) / כלב על ארבע. עולה מהבריכה = נבנה מלמטה למעלה.
# ============================================================
func draw() -> bool:
	var pts := PackedVector2Array()
	var cols := PackedColorArray()
	var tt: float = z._time
	if z.dead:
		DrawBatch.set_transform_matrix(z, Transform2D.IDENTITY)
		var k := clampf(float(z._dead_t) / 1.2, 0.0, 1.0)
		var c: Vector2 = _dpos - z.global_position
		for q in 8:   # מתפרק לרסיסי אור שעולים
			var p := c + Vector2((U.h(q, 3) - 0.5) * 30.0, -10.0 - U.h(q, 4) * 40.0 * z.sc - k * 50.0 * U.h(q, 5))
			U.dia(pts, cols, p, 2.0 + 2.0 * (1.0 - k), Color(Decor.MEM, 0.8 * (1.0 - k)))
		U.flush(z, pts, cols)
		return true
	begin_draw(state != RISE)
	var pb := PackedVector2Array()
	var cb := PackedColorArray()
	var a := 0.72 + 0.12 * sin(tt * 3.0 + _seed)
	if _glitch > 0.0:
		a = 0.85
	var body := Color(Decor.MEM, a) if z._flash <= 0.0 else Color(1, 1, 1, 0.9)
	var deep := Color(0.25, 0.6, 0.75, a * 0.9)
	match memory:
		3:
			_hound(pb, cb, body, deep, tt)
		_:
			_humanoid(pb, cb, body, deep, tt)
	# בבואה שנגררת (תנועה מהירה)
	var vx: float = z.velocity.x * z._dir
	if absf(vx) > 120.0:
		var ghost := Transform2D(0.0, Vector2(-vx * 0.07 / z.sc, 0.0))
		var gp: PackedVector2Array = ghost * pb
		var gc := PackedColorArray()
		gc.resize(cb.size())
		gc.fill(Color(Decor.MEM, 0.12))
		pts.append_array(gp)
		cols.append_array(gc)
	# עולה מהבריכה: נבנה מלמטה (מעיכה אנכית)
	var sy := 1.0
	if state == RISE:
		var k2 := clampf(1.0 - _st / RISE_T, 0.0, 1.0)
		sy = maxf(0.05, k2)
		U.halo(pts, cols, Vector2(0, -2.0), 30.0, 8.0, Color(Decor.MEM, 0.5 * (1.0 - k2)), 12)
	var xf := Transform2D(0.0, Vector2(1.0, sy), 0.0, Vector2(_glitch_x if _glitch > 0.0 else 0.0, 0.0))
	pts.append_array(xf * pb)
	cols.append_array(cb)
	# שורות סריקה (על כל הגוף)
	var top := (-40.0 if memory == 3 else -62.0) * sy
	for q in 6:
		var y := top + fposmod(tt * 26.0 + float(q) * 11.0, -top)
		U.rect(pts, cols, Rect2(-14.0, y, 30.0, 1.0), Color(0.05, 0.15, 0.2, 0.35))
	if _glitch > 0.0:   # פס גליץ' בהיר
		var gy := top * U.h(int(tt * 10.0), 9)
		U.rect(pts, cols, Rect2(-18.0 + _glitch_x, gy, 36.0, 2.2), Color(1.0, 1.0, 1.0, 0.6))
	U.flush(z, pts, cols)
	end_draw()
	return true


func _humanoid(pts: PackedVector2Array, cols: PackedColorArray, body: Color, deep: Color, tt: float) -> void:
	var f: Array = feet(4.6, 2.4)
	var lean := 0.0
	var curl := 0.0
	match state:
		DOOR_W:
			lean = -2.0
		DOOR_SLAM, SWIPE:
			lean = 5.0
		UPPER_W:
			lean = -3.0
		UPPER:
			lean = 3.0
		ROLL:
			curl = 1.0
		SPIT_W:
			lean = -2.0
	if curl > 0.0:   # SUBJECT FOUR מתגלגל: כדור
		var rc := Vector2(0, -14.0)
		var spin := tt * 14.0
		U.oval(pts, cols, rc, 14.0, 14.0, deep, 14)
		U.oval(pts, cols, rc, 12.0, 12.0, body, 14)
		for q in 3:
			var an := spin + float(q) * TAU / 3.0
			U.seg(pts, cols, rc + Vector2.from_angle(an) * 4.0, rc + Vector2.from_angle(an + 0.6) * 12.0, 2.4, deep)
		U.oval(pts, cols, rc + Vector2.from_angle(spin) * 7.0, 4.0, 3.0, Color(0.15, 0.3, 0.35, 0.9), 8)
		return
	var big := 1.25 if memory == 0 else 1.0
	var hunch := 4.0 if memory == 1 else 0.0
	var hip := Vector2(0, -22.0)
	var sh := Vector2(1.0 + lean + hunch * 0.5, -41.0 + hunch)
	var head := sh + Vector2(3.0 + lean * 0.3 + hunch, -9.0 + hunch * 0.3)
	# רגליים
	for i in 2:
		var ft: Vector2 = f[i]
		U.taper(pts, cols, hip + Vector2(-3.0 + float(i) * 5.0, 0.0), ft + Vector2(0, -2.0), 6.0 * big, 4.4, deep if i == 0 else body, body)
		U.oval(pts, cols, ft + Vector2(2.0, -1.5), 4.0, 2.0, body, 8)
	# יד אחורית
	var hb := sh + Vector2(-4.0 + lean, 15.0)
	if memory == 2:   # רובה על הגב
		U.seg(pts, cols, sh + Vector2(-9.0, -4.0), hip + Vector2(-6.0, 8.0), 2.6, deep)
	U.taper(pts, cols, sh + Vector2(-4.0, 1.0), hb, 5.0 * big, 4.0, deep, deep)
	# גוף
	var torso := PackedVector2Array([sh + Vector2(-8.0 * big, -1.0), sh + Vector2(7.5 * big, -1.5), hip + Vector2(6.0, 1.0), hip + Vector2(-6.5, 1.0)])
	U.tri(pts, cols, torso[0], torso[1], torso[2], body)
	U.tri(pts, cols, torso[0], torso[2], torso[3], body)
	U.seg(pts, cols, sh + Vector2(-6.0, 6.0), hip + Vector2(-4.0, -2.0), 1.4, Color(1, 1, 1, 0.25))
	if memory == 2:   # אפוד + פסים
		U.rect(pts, cols, Rect2(sh.x - 6.0, sh.y + 3.0, 12.0, 12.0), deep)
		U.seg(pts, cols, sh + Vector2(-5.0, 7.0), sh + Vector2(5.0, 7.0), 1.2, Color(1, 1, 1, 0.4))
	# ראש
	U.oval(pts, cols, head, 6.6 * (1.1 if memory == 0 else 1.0), 6.8, body, 12)
	if memory == 1:   # שק גרון נפוח (זוהר יותר לפני היריקה)
		var puff := 1.0 + (1.0 - clampf(_st / SPIT_WIND, 0.0, 1.0)) * 0.6 if state == SPIT_W else 1.0
		U.oval(pts, cols, head + Vector2(2.0, 7.0), 5.5 * puff, 4.5 * puff, Color(0.7, 1.0, 0.75, 0.75), 10)
	if memory == 2:   # קסדה
		U.oval(pts, cols, head + Vector2(-0.5, -3.0), 7.6, 4.6, deep, 12)
		U.seg(pts, cols, head + Vector2(-7.0, -1.5), head + Vector2(7.5, -1.5), 1.6, deep)
	# עיניים לבנות
	U.oval(pts, cols, head + Vector2(3.6, -1.0), 1.4, 1.1, Color(1, 1, 1, 0.95), 6)
	U.oval(pts, cols, head + Vector2(0.4, -1.2), 1.1, 0.9, Color(1, 1, 1, 0.8), 6)
	U.halo(pts, cols, head + Vector2(3.6, -1.0), 5.0, 4.0, Color(1, 1, 1, 0.25), 8)
	# יד קדמית (+ דלת המכונית)
	var hf := sh + Vector2(13.0 + lean, 8.0)
	if state == UPPER:
		hf = sh + Vector2(10.0, -16.0)
	elif state == UPPER_W:
		hf = sh + Vector2(6.0, 14.0)
	if has_trick(0):
		var up := state == DOOR_W or state == DOOR_SLAM
		var k := clampf(1.0 - _st / DOOR_WIND, 0.0, 1.0) if state == DOOR_W else (1.0 if state == DOOR_SLAM else 0.0)
		if state == DOOR_SLAM:
			k = clampf(_st / 0.2, 0.0, 1.0)
		var dc := Vector2(14.0, DOOR_Y)
		var ang := 0.0
		if up:
			dc = Vector2(lerpf(14.0, 4.0, k), lerpf(DOOR_Y, -76.0, k))
			ang = -PI * 0.5 * k
		hf = dc + Vector2(-4.0, 6.0)
		U.taper(pts, cols, sh + Vector2(4.0, 1.0), hf, 5.5 * big, 4.4, body, body)
		_door(pts, cols, dc, ang)
	else:
		U.taper(pts, cols, sh + Vector2(4.0, 1.0), hf, 5.0 * big, 4.0, body, body)
		U.oval(pts, cols, hf, 3.0, 2.6, body, 8)
	if state == DOOR_W or state == SWIPE_W or state == UPPER_W:   # אזהרה: הבהוב לבן על הגוף
		U.halo(pts, cols, sh + Vector2(0, 8.0), 18.0, 20.0, Color(1, 1, 1, 0.25 + 0.2 * sin(tt * 30.0)), 10)


# דלת מכונית שקופה (הזיכרון של הבוס הראשון): מסגרת, חלון, ידית
func _door(pts: PackedVector2Array, cols: PackedColorArray, c: Vector2, ang: float) -> void:
	var xf := Transform2D(ang, c)
	var p := PackedVector2Array()
	var cl := PackedColorArray()
	U.rect(p, cl, Rect2(-6.0, -DOOR_H, 12.0, DOOR_H * 2.0), Color(0.55, 0.85, 0.95, 0.75))
	U.rect(p, cl, Rect2(-4.5, -DOOR_H + 2.0, 9.0, DOOR_H * 0.75), Color(0.08, 0.2, 0.26, 0.8))
	U.rect(p, cl, Rect2(-6.0, -1.0, 12.0, 1.4), Color(1, 1, 1, 0.4))
	U.rect(p, cl, Rect2(2.0, 4.0, 3.0, 1.6), Color(1, 1, 1, 0.7))
	pts.append_array(xf * p)
	cols.append_array(cl)


func _hound(pts: PackedVector2Array, cols: PackedColorArray, body: Color, deep: Color, tt: float) -> void:
	var crouch := 0.0
	if state == POUNCE_W:
		crouch = clampf(1.0 - _st / POUNCE_WIND, 0.0, 1.0)
	var air: bool = state == POUNCE and not z.is_on_floor()
	var ph: float = z._walk_phase
	var bc := Vector2(-2.0, -22.0 + crouch * 6.0)
	# רגליים
	for i in 4:
		var hx := -14.0 + floorf(float(i) / 2.0) * 22.0 + float(i % 2) * 3.0
		var sw := sin(ph + float(i) * 1.6) * 6.0
		var foot := Vector2(hx + sw, -1.0)
		if air:
			foot = Vector2(hx + (10.0 if i >= 2 else -12.0), -10.0)
		U.taper(pts, cols, bc + Vector2(hx + 2.0, 4.0), foot, 4.6, 2.6, deep if i % 2 == 0 else body, body)
	# זנב
	U.taper(pts, cols, bc + Vector2(-18.0, -2.0), bc + Vector2(-30.0, -8.0 + sin(tt * 6.0) * 4.0), 3.0, 1.0, body, Color(body, 0.3))
	# גוף
	U.oval(pts, cols, bc, 20.0, 9.5, body, 14)
	U.oval(pts, cols, bc + Vector2(8.0, -2.0), 10.0, 9.0, body, 12)
	for q in 4:   # צלעות
		U.seg(pts, cols, bc + Vector2(-6.0 + float(q) * 4.0, -6.0), bc + Vector2(-5.0 + float(q) * 4.0, 5.0), 1.0, Color(0.1, 0.25, 0.3, 0.4))
	# ראש + לסת
	var hd := bc + Vector2(24.0, -6.0 + crouch * 2.0)
	var jaw := 3.0 if (state == POUNCE or state == POUNCE_W) else 1.0
	U.oval(pts, cols, hd, 8.0, 6.0, body, 12)
	U.tri(pts, cols, hd + Vector2(4.0, -2.0), hd + Vector2(14.0, 1.0), hd + Vector2(4.0, 3.0), body)
	U.tri(pts, cols, hd + Vector2(3.0, 3.0), hd + Vector2(12.0, 4.0 + jaw), hd + Vector2(3.0, 6.0 + jaw * 0.5), deep)
	U.tri(pts, cols, hd + Vector2(-4.0, -5.0), hd + Vector2(-1.0, -12.0), hd + Vector2(1.0, -5.0), body)
	U.oval(pts, cols, hd + Vector2(3.0, -1.5), 1.4, 1.1, Color(1, 1, 1, 0.95), 6)
	U.halo(pts, cols, hd + Vector2(3.0, -1.5), 5.0, 4.0, Color(1, 1, 1, 0.25), 8)
