extends "res://enemies/zombie_type.gd"
# ============================================================
#  TORO (שלב 47, "PAMPAS STORM") - בוקר ענק שהפך לשור: כתפיים עצומות וגב שפוף, קרני עצם שצמחו מהגולגולת,
#  שאריות פונצ'ו קרוע, מכנסי בומבאצ'ה, חגורת מטבעות (רסטרה). "THEY LEARNED TO WRESTLE".
#    WALK   - מתקרב (המוח).
#    PAW    - אתה על אותו גובה ובטווח: מוריד את הראש, גורד את האדמה ברגל ונוחר (PAW_T) - אזהרה!
#    CHARGE - דוהר בקו ישר (CHARGE_V, עד CHARGE_T). נכנס בקיר / מכשול -> STUN (מסוחרר, פגיע x STUN_MULT).
#    HOLD   - תפס אותך: מרים אותך מעל הראש (LIFT_T). אתה לא זז. לחיצות A/D לסירוגין = משתחרר (player.grab).
#    THROW  - זורק אותך רחוק קדימה (THROW_V): נזק THROW_DMG ואתה עף בקשת.
#  התחמקות: לקפוץ מעליו / להתגלגל דרכו / לעלות לקומה. "THEY LEARN" - הוא זוכר איך ברחת:
#    קפצת מעליו (JUMP_LEARN פעמים) -> בהסתערות הבאה הוא קופץ ותופס גבוה ("HE READS YOUR JUMP").
#    התגלגלת דרכו -> הוא בולם ומסתובב מיד להסתערות קצרה חזרה ("HE TURNS ON A DIME").
#    השתחררת מהתפיסה -> זורק מהר יותר בפעם הבאה ("HE THROWS FASTER").
#  בוס: EL TORO - ענק, הסתערות כפולה, זורק אותך גבוה לאוויר ואז קופץ ונוחת עליך בגל הדף (Wave - לקפוץ מעליו).
#  לשנות: PAW_T, CHARGE_V, CHARGE_T, CHARGE_R, LIFT_T, HOLD_T, THROW_V, THROW_DMG, STUN_T, STUN_MULT, JUMP_LEARN, CD.
# ============================================================

const SOUNDS := {
	"tr_snort": [["N", 0, 0, 0.0, 0.35, 0.02, 7.0, 0.8, 0.25, 0, 0.3], ["S", 90, 60, 0.0, 0.3, 0.0, 9.0, 0.4, 1.0, 0]],
	"tr_bellow": {"drive": 2.4, "layers": [["V", 70, 52, 0.0, 1.1, 0.08, 2.2, 1.0, 1.0, 0.06, 0, [260, 700, 22]], ["N", 0, 0, 0.0, 0.9, 0.05, 3.0, 0.4, 0.15, 0]]},
	"tr_slam": {"drive": 2.4, "layers": [["S", 64, 30, 0.0, 0.5, 0.0, 5.5, 1.0, 1.0, 0], ["N", 0, 0, 0.0, 0.4, 0.0, 7.0, 0.8, 0.25, 0]]},
	"tr_grab": [["N", 0, 0, 0.0, 0.12, 0.0, 30.0, 0.7, 0.4, 0], ["S", 180, 80, 0.0, 0.12, 0.0, 25.0, 0.5, 1.0, 0]],
}

const PAW_T := 0.85
const CHARGE_V := 430.0
const CHARGE_T := 1.6
const CHARGE_R := Vector2(110.0, 560.0)   # טווח שממנו הוא מסתער
const LIFT_T := 0.45
const HOLD_T := 1.1
const THROW_V := Vector2(620.0, -480.0)
const THROW_DMG := 2
const STUN_T := 1.7
const STUN_MULT := 1.6
const JUMP_LEARN := 1
const CD := Vector2(2.2, 3.4)
const BOSS_THROW := Vector2(260.0, -980.0)
const REACH_T := 0.38           # צמוד אליך: מושיט ידיים ותופס (אזהרה קצרה)

enum { WALK, PAW, CHARGE, HOLD, STUN, REST, SLAM, REACH }
var state := WALK
var charges := 0             # לבדיקות
var grabs := 0
var throws := 0
var stuns := 0
var slams := 0
var escapes := 0
var learned := {"jump": 0, "roll": 0, "mash": 0}
var held: Node = null
var _st := 0.0
var _cd := 1.2
var _ct := 0.0               # כמה זמן כבר מסתער
var _side := 0.0             # באיזה צד של הטורו השחקן היה בתחילת ההסתערות
var _dodged := false
var _leapt := false
var _back := false           # הסתערות חזרה (אחרי גלגול)
var _double := 0             # בוס: הסתערות שנייה
var _air := 0.0
var _ht := 0.0               # כמה זמן הוא מחזיק אותך
var _snort := 0.0


func _boss() -> bool:
	return z != null and float(z.chase_range) > 600.0


func stats() -> Dictionary:
	if _boss():
		return {"name": "TORO", "hp": 560, "walk": 40.0, "chase": 72.0, "damage": 2, "bite_delay": 1.0, "scale": 2.45, "width": 1.35,
			"duck": 0.0, "cover": 0.0, "skin": Color("8a8e78"), "shirt": Color("7a2a20"), "pants": Color("cfc6b0"), "shoe": Color("2a1e14"),
			"points": 1400, "boss": true, "boss_name": "EL TORO - JUMP HIS CHARGE", "ragdoll": false}
	return {"name": "TORO", "hp": 140, "walk": 40.0, "chase": 74.0, "damage": 2, "bite_delay": 1.0, "scale": 1.7, "width": 1.35,
		"duck": 0.0, "cover": 0.0, "skin": Color("8a8e78"), "shirt": Color("7a2a20"), "pants": Color("cfc6b0"), "shoe": Color("2a1e14"),
		"points": 650, "ragdoll": false}


func brain_overrides() -> Dictionary:
	return {"aggression": 0.8, "flank_probability": -0.5}


func can_bite() -> bool:
	return false


func damage_mult(_zone: String, _src: Dictionary) -> float:
	return STUN_MULT if state == STUN else 1.0


func physics(pl: Node, delta: float) -> bool:
	_cd -= delta
	_st -= delta
	_snort -= delta
	if z.dead:
		_drop_player()
		return false
	var has_pl: bool = pl != null and not pl.dead
	match state:
		WALK:
			if not has_pl or not z.is_on_floor():
				return false
			var d: Vector2 = pl.global_position - z.global_position
			if _cd <= 0.0 and absf(d.y) < 50.0 and absf(d.x) < 34.0 * z.sc + 26.0:   # צמוד: תפיסה מקרוב
				state = REACH
				_st = REACH_T
				z._dir = signf(d.x) if d.x != 0.0 else z._dir
				Sfx.play("tr_snort", z.global_position, 0.0, 0.1, 2, 0.8)
				return _move(delta, 0.0)
			var r := CHARGE_R * (1.15 if _boss() else 1.0)
			if _cd <= 0.0 and absf(d.y) < 46.0 and absf(d.x) > r.x * 0.5 and absf(d.x) < r.y and _clear(pl):
				_start_paw(d, PAW_T * (0.8 if _boss() else 1.0))
				return _move(delta, 0.0)
			return false
		PAW:
			if has_pl:
				var d2: Vector2 = pl.global_position - z.global_position
				z._dir = signf(d2.x) if absf(d2.x) > 4.0 else z._dir
			if Engine.get_physics_frames() % 7 == 0 and Art.on_screen(z, z.global_position):
				Particles.burst(z.get_parent(), z.global_position + Vector2(-z._dir * 8.0, -3.0) * z.sc, "smoke", Vector2(-z._dir, -0.4), 2)
			if _snort <= 0.0:
				_snort = 0.4
				Sfx.play("tr_snort", z.global_position, -3.0, 0.1, 2, 0.9 if not _boss() else 0.7)
			if _st <= 0.0:
				_start_charge(pl)
			return _move(delta, 0.0)
		CHARGE:
			return _charge(pl, delta)
		HOLD:
			return _hold(pl, delta)
		STUN:
			if Engine.get_physics_frames() % 10 == 0 and Art.on_screen(z, z.global_position):
				Particles.burst(z.get_parent(), z.global_position + Vector2(0, -78.0 * z.sc), "spark", Vector2.UP, 1)
			if _st <= 0.0:
				state = WALK
				_cd = randf_range(CD.x, CD.y) * 0.6
			return _move(delta, 0.0)
		REST:
			if _st <= 0.0:
				state = WALK
			return _move(delta, 0.0)
		SLAM:
			return _slam(pl, delta)
		REACH:
			if _st <= 0.0:
				if has_pl and pl.grabbed_by == null and pl._roll_t <= 0.0 and not pl.god_mode() and _grab_zone().grow(10.0).intersects(pl.body_rect()):
					_grab(pl)
					return true
				state = REST
				_st = 0.6
				_cd = randf_range(CD.x, CD.y) * 0.5
			return _move(delta, 0.0)
	return false


# האם יש קו פתוח לשחקן (בלי קיר באמצע)
func _clear(pl: Node) -> bool:
	var a: Vector2 = z.global_position + Vector2(0, -30.0)
	var b: Vector2 = pl.global_position + Vector2(0, -30.0)
	var hit: Dictionary = z.get_world_2d().direct_space_state.intersect_ray(PhysicsRayQueryParameters2D.create(a, b, 1))
	return hit.is_empty()


func _start_paw(d: Vector2, t: float) -> void:
	state = PAW
	_st = t
	z._dir = signf(d.x) if d.x != 0.0 else z._dir
	z._popup("!", Color("ff7050"), 18, -80.0 * z.sc)
	Sfx.play("tr_bellow", z.global_position, 0.0 if not _boss() else 3.0, 0.08, 2, 1.0 if not _boss() else 0.75)


func _start_charge(pl: Node) -> void:
	state = CHARGE
	charges += 1
	_ct = 0.0
	_dodged = false
	_leapt = false
	if pl != null:
		_side = signf(pl.global_position.x - z.global_position.x)
		if _side == 0.0:
			_side = z._dir
		z._dir = _side


func _charge(pl: Node, delta: float) -> bool:
	_ct += delta
	var v := CHARGE_V * (1.12 if _boss() else 1.0) * (0.85 if _back else 1.0)
	z.velocity.x = move_toward(z.velocity.x, z._dir * v, 2400.0 * delta)
	if not z.is_on_floor():
		z.velocity.y += z.gravity * delta
	z.move_and_slide()
	if Engine.get_physics_frames() % 4 == 0 and Art.on_screen(z, z.global_position):
		Particles.burst(z.get_parent(), z.global_position + Vector2(-z._dir * 12.0, -2.0) * z.sc, "smoke", Vector2(-z._dir, -0.3), 1)
	if pl != null and not pl.dead:
		var d: Vector2 = pl.global_position - z.global_position
		# למד שאתה קופץ: קופץ אחריך ותופס גבוה
		if learned.jump >= JUMP_LEARN and not _leapt and z.is_on_floor() and not pl.is_on_floor() and signf(d.x) == z._dir and absf(d.x) < 150.0 * z.sc * 0.7:
			_leapt = true
			z.velocity.y = -600.0
			Sfx.play("tr_snort", z.global_position, 2.0, 0.1, 2, 0.7)
		if _grab_zone().intersects(pl.body_rect()) and pl.grabbed_by == null:
			if pl._roll_t > 0.0 or pl.god_mode():
				pass   # מתגלגל = עובר דרכו
			else:
				_grab(pl)
				return true
		# עבר אותך בלי לתפוס -> לומד איך התחמקת
		if not _dodged and signf(d.x) != _side and absf(d.x) > 10.0:
			_dodged = true
			var how := "roll" if pl._roll_t > 0.0 else ("jump" if not pl.is_on_floor() else "")
			if how != "":
				_learn(how)
				if how == "roll" and learned.roll >= 1 and not _back:   # בולם ומסתובב מיד
					_back = true
					_ct = CHARGE_T * 0.55
					z._dir = -z._dir
					_side = -_side
					_dodged = false
					z.velocity.x = 0.0
					return true
	if z.is_on_wall() and _ct > 0.12:   # נכנס בקיר / מכשול
		_stun()
		return true
	if _ct >= CHARGE_T:
		_back = false
		if _boss() and _double == 0:   # בוס: מסתער שוב מיד
			_double = 1
			if pl != null and not pl.dead:
				_start_paw(pl.global_position - z.global_position, 0.35)
				return true
		_double = 0
		state = REST
		_st = 0.7
		_cd = randf_range(CD.x, CD.y)
	return true


func _grab_zone() -> Rect2:
	var w: float = 34.0 * z.sc
	var h: float = 52.0 * z.sc
	var up: float = 60.0 * z.sc if learned.jump >= JUMP_LEARN else 0.0
	var x0: float = z.global_position.x + (0.0 if z._dir > 0.0 else -w)
	return Rect2(Vector2(x0, z.global_position.y - h - up), Vector2(w, h + up))


func _learn(how: String) -> void:
	learned[how] = int(learned[how]) + 1
	escapes += 1
	match how:
		"jump":
			z._popup("HE READS YOUR JUMP", Color("ffd080"), 12, -90.0 * z.sc)
		"roll":
			z._popup("HE TURNS ON A DIME", Color("ffd080"), 12, -90.0 * z.sc)
		"mash":
			z._popup("HE THROWS FASTER", Color("ffd080"), 12, -90.0 * z.sc)


func _stun() -> void:
	state = STUN
	stuns += 1
	_st = STUN_T * (0.7 if _boss() else 1.0)
	_back = false
	_double = 0
	z.velocity.x = -z._dir * 120.0
	z._popup("STUNNED", Color("a0d0ff"), 14, -80.0 * z.sc)
	Sfx.play("tr_slam", z.global_position, 2.0, 0.1, 2)
	Particles.burst(z.get_parent(), z.global_position + Vector2(z._dir * 20.0, -40.0) * z.sc, "smoke", Vector2(-z._dir, -0.5), 6)
	_shake(5.0 if not _boss() else 9.0)
	if _boss():
		_wave(z.global_position)


# ---- התפיסה ----
func _grab(pl: Node) -> void:
	state = HOLD
	grabs += 1
	held = pl
	_ht = 0.0
	_back = false
	_double = 0
	z.velocity.x = 0.0
	pl.grab(z)
	Sfx.play("tr_grab", pl.global_position, 3.0, 0.1, 2)
	Sfx.play("tr_bellow", z.global_position, 2.0, 0.08, 2, 0.9 if not _boss() else 0.7)


func _hold(pl: Node, delta: float) -> bool:
	_ht += delta
	if held == null or not is_instance_valid(held) or held.dead or held.grabbed_by != z:
		held = null
		state = REST
		_ht = 0.8
		_cd = randf_range(CD.x, CD.y)
		return _move(delta, 0.0)
	var k := clampf(_ht / LIFT_T, 0.0, 1.0)
	k = k * k * (3.0 - 2.0 * k)
	var front: Vector2 = Vector2(z._dir * 26.0, -8.0) * z.sc
	var over: Vector2 = Vector2(-z._dir * 4.0, -66.0 * z.sc - 4.0)
	held.global_position = z.global_position + front.lerp(over, k) + Vector2(0, sin(_ht * 30.0) * 1.5 * k)
	held.velocity = Vector2.ZERO
	var hold_t := HOLD_T * (0.6 if int(learned.mash) > 0 else 1.0) * (0.8 if _boss() else 1.0)
	if _ht >= hold_t:
		_throw()
	return _move(delta, 0.0)


func _throw() -> void:
	var pl := held
	held = null
	throws += 1
	if pl.grabbed_by == z:
		pl.grabbed_by = null
	var tv := BOSS_THROW if _boss() else THROW_V
	pl.hurt(THROW_DMG, Vector2(z._dir, -1.0))
	pl.velocity = Vector2(z._dir * tv.x, tv.y)
	pl._push_t = maxf(float(pl._push_t), 0.9)
	Sfx.play("tr_bellow", z.global_position, 3.0, 0.08, 2, 0.8)
	Sfx.play("throw", z.global_position, 3.0)
	_shake(4.0)
	Game.story.emit("phurt", {"amount": THROW_DMG})
	if _boss():   # קופץ ונוחת איפה שתיפול
		state = SLAM
		_st = 0.0
		_air = 0.0
		var land_x: float = pl.global_position.x + z._dir * tv.x * 1.1
		z.velocity = Vector2(clampf((land_x - z.global_position.x) / 1.1, -520.0, 520.0), -780.0)
		z._popup("BODY SLAM!", Color("ff8050"), 16, -80.0 * z.sc)
	else:
		state = REST
		_st = 0.9
		_cd = randf_range(CD.x, CD.y)


func _slam(_pl: Node, delta: float) -> bool:
	_air += delta
	z.velocity.y += z.gravity * delta
	z.move_and_slide()
	if z.is_on_floor() and _air > 0.25:
		slams += 1
		Sfx.play("tr_slam", z.global_position, 5.0, 0.1, 2)
		Particles.burst(z.get_parent(), z.global_position, "smoke", Vector2.UP, 10)
		_shake(11.0)
		_wave(z.global_position)
		state = STUN
		_st = 1.1
		z.velocity.x = 0.0
	elif _air > 3.0:
		state = WALK
	return true


func _wave(at: Vector2) -> void:
	for dir in [-1.0, 1.0]:
		var w := Wave.new()
		w.dir = dir
		z.get_parent().add_child(w)
		w.global_position = at


# השחקן השתחרר בלחיצות A/D
func on_release() -> void:
	if held != null and is_instance_valid(held):
		held.global_position = z.global_position + Vector2(z._dir * 30.0, -6.0) * z.sc
		held.velocity = Vector2(z._dir * 200.0, -200.0)
	held = null
	_learn("mash")
	state = STUN
	_st = 0.8
	stuns += 1


func _drop_player() -> void:
	if held != null and is_instance_valid(held):
		if held.grabbed_by == z:
			held.grabbed_by = null
		held.velocity = Vector2(0, -150)
	held = null


func on_death() -> void:
	_drop_player()


func _move(delta: float, vx: float) -> bool:
	z.velocity.x = move_toward(z.velocity.x, vx, 1200.0 * delta)
	if not z.is_on_floor():
		z.velocity.y += z.gravity * delta
	z.move_and_slide()
	return true


func _shake(s: float) -> void:
	var cam: Camera2D = z.get_viewport().get_camera_2d()
	if cam != null and cam.has_method("shake"):
		cam.shake(s, 0.3)


# ---- גל הדף על הקרקע (בוס): לקפוץ מעליו ----
class Wave extends Node2D:
	const SPEED := 520.0
	const RANGE := 460.0
	const DMG := 1
	var dir := 1.0
	var hit := false
	var _d := 0.0

	func _ready() -> void:
		z_index = 8

	func _physics_process(delta: float) -> void:
		_d += SPEED * delta
		if _d > RANGE:
			queue_free()
			return
		var pl := get_tree().get_first_node_in_group("player")
		if not hit and pl != null and not pl.dead and pl.is_on_floor():
			var fx := global_position.x + dir * _d
			if absf(pl.global_position.x - fx) < 22.0 and absf(pl.global_position.y - global_position.y) < 24.0:
				hit = true
				pl.hurt(DMG, Vector2(dir * 1.5, -1.4))
		queue_redraw()

	func _draw() -> void:
		var a := 1.0 - _d / RANGE
		var x := dir * _d
		for q in 5:
			var xx := x - dir * float(q) * 9.0
			var h := (16.0 - float(q) * 3.0) * a
			draw_colored_polygon(PackedVector2Array([Vector2(xx - 8.0, 0), Vector2(xx, -h), Vector2(xx + 8.0, 0)]), Color(0.35, 0.3, 0.22, 0.8 * a))
		draw_circle(Vector2(x, -6.0), 12.0 * a, Color(0.5, 0.45, 0.38, 0.35 * a))


# ============================================================
#  ציור: גבנון ענק, ראש שור נמוך לפני הכתפיים עם קרני עצם שמתעקלות קדימה, פונצ'ו קרוע על הגב, ידיים ארוכות כמו גורילה,
#  מכנסי בומבאצ'ה, חגורת מטבעות. PAW = ראש למטה ורגל גורדת. CHARGE = נוטה קדימה, קרניים קדימה.
#  HOLD = שתי הידיים מעל הראש (מחזיק אותך). REACH = ידיים קדימה. STUN = כוכבים, ראש מתנדנד.
# ============================================================
func draw() -> bool:
	begin_draw()
	var sk := col(z.skin)
	var skd := col(Art.shade(z.skin, 0.3))
	var poncho := col(z.shirt)
	var bone := col(Color("e2d8bc"))
	var p: float = z._walk_phase
	var f: Array = feet(5.0, 2.5)
	var lean := 0.0          # כמה הגוף העליון נוטה קדימה
	var head_dy := 0.0
	match state:
		PAW:
			lean = 4.0
			head_dy = 6.0
			f[0] = Vector2(5.0 + sin(z._time * 16.0) * 5.0, -absf(sin(z._time * 16.0)) * 2.5)   # גורד את האדמה
		CHARGE:
			lean = 8.0
			head_dy = 8.0
			f = feet(8.0, 4.0)
		HOLD:
			lean = -4.0
			head_dy = -2.0
		STUN:
			head_dy = 3.0 + sin(z._time * 6.0) * 2.0
	var L := func(v: Vector2) -> Vector2:   # נטייה: ככל שגבוה יותר - זז יותר קדימה
		return v + Vector2(lean * clampf((-v.y - 20.0) / 30.0, 0.0, 1.0), absf(lean) * 0.25 * clampf((-v.y - 20.0) / 30.0, 0.0, 1.0))
	var hip := Vector2(0, -21)
	# רגליים עבות (מגפיים + בומבאצ'ה)
	z._leg(hip + Vector2(-4, 0), f[1], col(Art.shade(z.pants, 0.3)), skd, col(z.shoe))
	z._leg(hip + Vector2(4, 0), f[0], col(z.pants), sk, col(z.shoe))
	# כתפיים וידיים
	var sh_b: Vector2 = L.call(Vector2(-5, -44))
	var sh_f: Vector2 = L.call(Vector2(8, -43))
	var hb: Vector2
	var hf: Vector2
	match state:
		HOLD:
			var k := clampf(_ht / LIFT_T, 0.0, 1.0)
			hb = Vector2(16, -20).lerp(Vector2(-2, -68), k)
			hf = Vector2(22, -22).lerp(Vector2(8, -68), k)
		REACH:
			var rk := 1.0 - clampf(_st / REACH_T, 0.0, 1.0)
			hb = sh_b + Vector2(14.0 + rk * 10.0, 12.0)
			hf = sh_f + Vector2(14.0 + rk * 12.0, 10.0)
		CHARGE:
			hb = sh_b + Vector2(-10, 20)
			hf = sh_f + Vector2(-4, 24)
		STUN:
			hb = sh_b + Vector2(-2.0 + sin(z._time * 5.0) * 3.0, 28.0)
			hf = sh_f + Vector2(6.0, 28.0)
		_:
			hb = sh_b + Vector2(2.0 - sin(p) * 4.0, 31.0)
			hf = sh_f + Vector2(6.0 + sin(p) * 4.0, 30.0)
	_big_arm(sh_b, hb, skd)
	# גוף: חבית + גבנון
	var torso := PackedVector2Array()
	for v in [Vector2(-10, -19), Vector2(-15, -31), Vector2(-13, -44), Vector2(-6, -51), Vector2(4, -50), Vector2(12, -44), Vector2(14, -33), Vector2(11, -24), Vector2(8, -18)]:
		torso.append(L.call(v))
	Art.fill_shaded(z, torso, sk, 0.16, 0.42)
	z.draw_polyline(PackedVector2Array([L.call(Vector2(2, -44)), L.call(Vector2(8, -38)), L.call(Vector2(7, -30))]), Color(0.2, 0.18, 0.12, 0.5), 1.2)   # שריר חזה
	z.draw_line(L.call(Vector2(-2, -32)), L.call(Vector2(6, -26)), Color(0.2, 0.18, 0.12, 0.4), 1.0)
	# פונצ'ו קרוע על הגבנון (שולי זיגזג)
	var pon := PackedVector2Array()
	for v in [Vector2(5, -50), Vector2(-6, -53), Vector2(-14, -46), Vector2(-17, -32), Vector2(-16, -24), Vector2(-13, -28), Vector2(-11, -22), Vector2(-8, -28), Vector2(-5, -24), Vector2(-3, -32), Vector2(2, -38), Vector2(7, -42)]:
		pon.append(L.call(v))
	Art.fill_shaded(z, pon, poncho, 0.14, 0.35)
	z.draw_polyline(PackedVector2Array([L.call(Vector2(-14, -40)), L.call(Vector2(-4, -46)), L.call(Vector2(4, -47))]), col(Color("d8b060")), 1.2)   # פס
	z.draw_polyline(PackedVector2Array([L.call(Vector2(-15, -35)), L.call(Vector2(-6, -41)), L.call(Vector2(1, -41))]), col(Color("2a1410")), 1.2)
	# חגורה רחבה עם מטבעות כסף (רסטרה)
	z.draw_rect(Rect2(hip + Vector2(-11, -4), Vector2(22, 6)), col(Color("3a2418")))
	for q in 4:
		z.draw_circle(hip + Vector2(-7.0 + float(q) * 5.0, -1.0), 1.7, col(Color("cfd0c8")))
	# ראש שור נמוך, לפני הכתפיים
	var head: Vector2 = L.call(Vector2(15, -41)) + Vector2(0, head_dy)
	Art.oval_shaded(z, head, 6.4, 5.6, sk, 0.15)
	Art.oval(z, head + Vector2(5.5, 2.0), 3.6, 3.0, skd, 0.0)   # חוטם
	z.draw_circle(head + Vector2(7.5, 1.8), 0.8, Color(0.1, 0.05, 0.05))
	z.draw_line(head + Vector2(-2, -3.2), head + Vector2(5, -2.4), col(Color("2a2420")), 1.6)   # גבה כועסת
	if not z.dead:
		z.draw_circle(head + Vector2(3.0, -1.0), 1.2, Color(1.0, 0.25, 0.15))
		Art.glow(z, head + Vector2(3.0, -1.0), 4.0, Color(1.0, 0.2, 0.1, 0.4))
	Art.fill(z, PackedVector2Array([head + Vector2(0, 3), head + Vector2(7, 4), head + Vector2(6, 7), head + Vector2(0, 6.5)]), col(Color("2a0a0a")), Art.OUTLINE, 0.8)   # לסת
	z.draw_line(head + Vector2(1, 4), head + Vector2(6, 4.6), bone, 0.9)   # שיניים
	# קרני עצם: יוצאות מהצדדים, מתעקלות למעלה וקדימה (בהסתערות - ישר קדימה)
	var fwd := state == CHARGE or state == PAW
	var h1 := [head + Vector2(-3, -4), head + Vector2(-6, -9), head + Vector2(-4, -14), head + Vector2(1, -16)]
	var h2 := [head + Vector2(2, -4), head + Vector2(4, -10), head + Vector2(9, -13), head + Vector2(13, -11)]
	if fwd:
		h1 = [head + Vector2(-3, -4), head + Vector2(-2, -10), head + Vector2(4, -12), head + Vector2(9, -10)]
		h2 = [head + Vector2(2, -4), head + Vector2(7, -8), head + Vector2(13, -8), head + Vector2(18, -5)]
	_horn(h1, 3.2, col(Color("b8ae94")))
	_horn(h2, 3.6, bone)
	# יד קדמית ענקית
	_big_arm(sh_f, hf, sk)
	if state == STUN and not z.dead:   # כוכבים מעל הראש
		for q in 3:
			var a: float = z._time * 4.0 + float(q) * TAU / 3.0
			z.draw_circle(head + Vector2(cos(a) * 10.0, -20.0 + sin(a) * 3.0), 1.6, Color(1.0, 0.92, 0.5))
	end_draw()
	return true


func _big_arm(s: Vector2, h: Vector2, c: Color) -> void:
	var el := Art.joint(s, h, 14.0, 14.0, -1.0)
	Art.limb(z, PackedVector2Array([s, el]), 8.5, c, Art.OUTLINE, true, false)
	Art.limb(z, PackedVector2Array([el, h]), 7.5, c)
	Art.disc(z, h, 5.2, c)   # אגרוף ענק
	z.draw_line(h + Vector2(-2.5, -2), h + Vector2(2.5, -3), Color(0.2, 0.15, 0.1, 0.6), 1.0)


# קרן מחודדת: עבה בבסיס, דקה בקצה
func _horn(pts: Array, w: float, c: Color) -> void:
	var left := PackedVector2Array()
	var right := PackedVector2Array()
	var n := pts.size()
	for i in n:
		var a: Vector2 = pts[i]
		var b: Vector2 = pts[mini(i + 1, n - 1)] if i < n - 1 else pts[i] + (pts[i] - pts[i - 1])
		var nrm := (b - a).normalized().orthogonal()
		var ww := w * (1.0 - float(i) / float(n - 1)) * 0.5 + 0.2
		left.append(a + nrm * ww)
		right.append(a - nrm * ww)
	right.reverse()
	Art.fill(z, left + right, c, Art.OUTLINE, 1.0)
