extends "res://enemies/zombie_type.gd"
# ============================================================
#  BUOY (שלב 56, "ICE FJORD") - דייג מת בחליפת הישרדות כתומה (רצועות מחזירות אור, קפוצ'ון, פנים כחולות מכפור),
#    קשור ברתמה לאשכול של מצופים: בלוני מזג אוויר לבנים מתחנת המטאורולוגיה, מצופי רשת כתומים קשיחים, פנדרים של סירות.
#  מה הם למדו: "אתה יורה במה שהולך אליך על הקרקע, מולך". אז הם עלו מעל קו האש - ונופלים עליך מלמעלה.
#  תנועה: מרחף מעליך (גובה = ALT_PER x מספר הבלונים שנשארו), נסחף ברוח. כל ATTACK_CD (כמה שניות, תמיד):
#    TELL  - פותח שסתום (שריקה) וצל מטרה מופיע על הרצפה איפה שאתה עומד (VENT_T).
#    DROP  - צונח עליך ברגליים קודם (DROP_SPEED, 1 נזק + הדיפה). גלגול / קפיצה הצידה = מתחמקים.
#    LOW   - מרחף נמוך LOW_T שניות ומכה במוט וו (GAFF) - כאן כל נשק פוגע בו, גם מכה ולהביור.
#    RISE  - עולה בחזרה.
#  בלונים: כל אחד גוף נפרד (Balloon, שכבה 4 + "blastable") - כל כדור / רסיס / פיצוץ / אש מפוצץ אותו (מצוף כתום = 2 פגיעות).
#    פחות בלונים = נמוך יותר. בלי בלונים -> נופל (FALL): על הקרח = התרסקות (נזק לפי הגובה, בדרך כלל מוות),
#    למים = שוקע. שרד את הנפילה -> "GROUNDED": זומבי צולע רגיל.
#  נהרג בגוף כשיש לו עוד 2+ בלונים -> הגופה נסחפת לשמיים (Ascend) ומטפטפת דם.
#  "THEY LEARN" (main meta "buoy_pops"): פוצצת POP_LEARN בלונים -> הבאים עוקפים אותך ונופלים מאחורייך
#    (הצד שאתה לא מכוון אליו) - "IT COMES FROM BEHIND". יש אזהרה: שריקה + הצל על הרצפה. נגד: להסתובב / להתגלגל.
#  צלילים: "bu_pop", "bu_vent", "bu_creak", "bu_gaff", "bu_splat".
#  לשנות: ALT_PER, ATTACK_CD, VENT_T, DROP_SPEED, LOW_T, GAFF_*, FALL_DMG_K, POP_LEARN, BEHIND_X, DRIFT_SPEED.
# ============================================================

const SOUNDS := {
	"bu_pop": [["N", 0, 0, 0.0, 0.05, 0.0, 120.0, 1.2, 1.0, 0], ["C", 0, 0, 0.0, 0.04, 0.0, 90.0, 0.8, 1.0, 0], ["S", 260, 90, 0.0, 0.06, 0.0, 50.0, 0.4, 1.0, 0], ["N", 0, 0, 0.02, 0.25, 0.0, 14.0, 0.25, 0.6, 0, 0.7]],
	"bu_vent": [["N", 0, 0, 0.0, 0.6, 0.03, 3.5, 0.5, 0.9, 0, 0.85], ["S", 2400, 1900, 0.0, 0.55, 0.05, 4.0, 0.06, 1.0, 0.1]],
	"bu_creak": [["W", 180, 140, 0.0, 0.35, 0.05, 6.0, 0.12, 0.35, 0.15], ["N", 0, 0, 0.0, 0.3, 0.05, 7.0, 0.1, 0.3, 0]],
	"bu_gaff": [["N", 0, 0, 0.0, 0.22, 0.0, 12.0, 0.45, 0.6, 0, 0.6], ["S", 700, 300, 0.0, 0.15, 0.0, 16.0, 0.15, 1.0, 0]],
	"bu_splat": {"rev": 0.15, "drive": 2.2, "layers": [["N", 0, 0, 0.0, 0.3, 0.0, 12.0, 1.0, 0.3, 0], ["S", 85, 35, 0.0, 0.3, 0.0, 10.0, 0.9, 1.0, 0], ["C", 0, 0, 0.0, 0.25, 0.0, 10.0, 0.6, 1.0, 0]]},
}

const Boom := preload("res://explosion.gd")

enum { WEATHER, FLOAT, FENDER }
const ALT_PER := 36.0             # גובה לכל בלון (6 בלונים = 216 מעל הרגליים שלך)
const ALT_MIN := 30.0
const DRIFT_SPEED := 150.0
const SIDE_X := 120.0
const ATTACK_CD := Vector2(1.8, 2.8)
const VENT_T := 0.6
const DROP_SPEED := 430.0
const DROP_DMG := 1
const LOW_T := 1.5
const GAFF_R := 52.0
const GAFF_WIND := 0.35
const GAFF_DMG := 1
const RISE_SPEED := 170.0
const FALL_DMG_K := 0.28          # נזק נפילה = גובה x K (בין 10 ל-60)
const POP_LEARN := 8
const BEHIND_X := 150.0
const BEHIND_T := 1.3
const WAKE_R := 760.0

enum { IDLE, HOVER, BEHIND, TELL, DROP, LOW, RISE, FALL, SINK, GROUNDED }
var state := IDLE
# לבדיקות
var pops := 0
var drops := 0
var drop_hits := 0
var gaffs := 0
var gaff_hits := 0
var falls := 0
var splats := 0
var sinks := 0
var ascends := 0
var behinds := 0
var learned := false

var _b := []                      # [{kind, off, col, r, hp, alive, node, ph}]
var _st := 0.0
var _cd := 2.0
var _gcd := 0.0
var _gwind := -1.0
var _target := Vector2.ZERO
var _side := 1.0
var _home := Vector2.ZERO
var _inited := false
var _hit_done := false
var _fall_y := 0.0
var _sink_k := 0.0
var _creak := 0.0
var _flap := 0.0
var _sc := 1.0
var _suit := Color("ff6a1a")
var _tape := Color("d8dde0")
var _skin := Color("a8b8c0")
var _hood := true
var _cap := Color("2a3a6a")
var _beard := false
var _boots := Color("2a2a2a")
var _vented := false


func stats() -> Dictionary:
	return {"name": "BUOY", "hp": 30, "walk": 36.0, "chase": 62.0, "damage": 1, "bite_delay": 0.9, "scale": 1.0, "width": 1.15,
		"duck": 0.0, "cover": 0.0, "skin": Color("a8b8c0"), "shirt": Color("ff6a1a"), "pants": Color("ff6a1a"), "shoe": Color("2a2a2a"),
		"points": 380, "ragdoll": false}


func use_brain_movement() -> bool:
	return state == GROUNDED


func can_bite() -> bool:
	return state == GROUNDED


func setup() -> void:
	var r := RandomNumberGenerator.new()
	r.seed = z.get_instance_id() * 7 + 3
	_sc = z.sc
	_suit = [Color("ff6a1a"), Color("ff4a2a"), Color("f0b020"), Color("e85a10")][r.randi() % 4]
	_tape = Color("dfe6ea")
	_skin = Color(0.62, 0.72, 0.78).lerp(Color(0.7, 0.66, 0.72), r.randf() * 0.6)
	_hood = r.randf() < 0.6
	_cap = [Color("2a3a6a"), Color("b02a2a"), Color("2a5a3a"), Color("d8c040")][r.randi() % 4]
	_beard = r.randf() < 0.5
	_boots = [Color("2a2a2a"), Color("e8d040"), Color("3a5a3a")][r.randi() % 3]
	var n := 5 + r.randi() % 2
	var wcols := [Color(0.97, 0.97, 0.94), Color(0.98, 0.94, 0.8), Color(0.95, 0.5, 0.42), Color(0.9, 0.95, 1.0)]
	for i in n:
		var k := WEATHER
		var rv := r.randf()
		if i == 0 or rv < 0.4:
			k = WEATHER
		elif rv < 0.8:
			k = FLOAT
		else:
			k = FENDER
		var a := lerpf(-0.95, 0.95, (float(i) + 0.5) / float(n)) + r.randf_range(-0.12, 0.12)
		var len := r.randf_range(62.0, 92.0) + (18.0 if k == WEATHER else 0.0)
		var off := Vector2(sin(a) * len * 0.55, -50.0 - cos(a) * len)
		var c: Color
		match k:
			WEATHER:
				c = wcols[r.randi() % wcols.size()]
			FLOAT:
				c = [Color("ff7a1a"), Color("ff9a20"), Color("e8e0d0")][r.randi() % 3]
			_:
				c = [Color("2a5ac0"), Color("c02a2a"), Color("e0e0e0")][r.randi() % 3]
		var rad := (15.0 if k == WEATHER else (10.0 if k == FLOAT else 7.0)) * r.randf_range(0.9, 1.12)
		_b.append({"kind": k, "off": off, "col": c, "r": rad, "hp": 2 if k == FLOAT else 1, "alive": true, "node": null, "ph": r.randf() * TAU})
	var m: Node = z.get_parent()
	learned = m != null and int(m.get_meta("buoy_pops", 0)) >= POP_LEARN
	_side = -1.0 if r.randf() < 0.5 else 1.0
	_cd = r.randf_range(1.0, 2.0)
	z.collision_mask = 1
	for i in _b.size():
		var bn := Balloon.new()
		bn.tm = self
		bn.idx = i
		bn.collision_layer = 4
		bn.collision_mask = 0
		var cs := CollisionShape2D.new()
		var sh := CircleShape2D.new()
		sh.radius = float(_b[i].r) + 3.0
		cs.shape = sh
		bn.add_child(cs)
		z.add_child(bn)
		bn.position = _b[i].off
		_b[i].node = bn


func alive_count() -> int:
	var n := 0
	for b in _b:
		if b.alive:
			n += 1
	return n


func _alt() -> float:
	return maxf(ALT_MIN, ALT_PER * float(alive_count()))


func _bpos(i: int) -> Vector2:   # מקום הבלון יחסית לזומבי (בלי היפוך)
	var b: Dictionary = _b[i]
	if not is_instance_valid(z):
		return (b.off as Vector2) * _sc
	var t: float = z._time
	return (b.off as Vector2) * _sc + Vector2(sin(t * 1.3 + float(b.ph)) * 5.0 - z.velocity.x * 0.03, cos(t * 1.7 + float(b.ph)) * 3.0 + z.velocity.y * 0.02)


func _bpos_free(i: int, t: float) -> Vector2:   # בלי זומבי (גופה נסחפת)
	var b: Dictionary = _b[i]
	return (b.off as Vector2) * _sc + Vector2(sin(t * 1.3 + float(b.ph)) * 5.0, cos(t * 1.7 + float(b.ph)) * 3.0)


# ============================================================
#  תנועה
# ============================================================
func physics(pl: Node, delta: float) -> bool:
	if state == GROUNDED:
		return false
	_st -= delta
	_cd -= delta
	_gcd -= delta
	_creak -= delta
	_flap += delta
	if not _inited:
		_inited = true
		_home = z.global_position + Vector2(0.0, -_alt() - randf_range(0.0, 40.0))
		z.global_position = _home
	var has: bool = pl != null and not pl.dead
	var d: Vector2 = (pl.global_position - z.global_position) if has else Vector2(9999, 0)
	if state == IDLE and absf(d.x) > 1500.0:   # רחוק: ישן (חוסך ביצועים)
		return true
	for i in _b.size():
		if _b[i].alive and _b[i].node != null:
			_b[i].node.position = _bpos(i)
	if alive_count() == 0 and state != FALL and state != SINK:
		_start_fall()
	if has and absf(d.x) < 30.0 + 20.0 * float(alive_count()) and state == HOVER and _creak <= 0.0 and Art.on_screen(z, z.global_position):
		_creak = randf_range(1.5, 3.0)
		Sfx.play("bu_creak", z.global_position, -10.0, 0.2, 2)
	match state:
		IDLE:
			_steer(_home + Vector2(sin(z._time * 0.4) * 40.0, sin(z._time * 0.9) * 10.0), 60.0, delta)
			if has and (absf(d.x) < WAKE_R or z._alert_t > 0.0):
				state = HOVER
				z._noticed = true
		HOVER:
			if not has:
				_steer(_home, 60.0, delta)
				z.move_and_slide()
				return true
			z._dir = signf(d.x) if absf(d.x) > 6.0 else z._dir
			var tgt: Vector2 = pl.global_position + Vector2(-signf(d.x) * SIDE_X + sin(z._time * 0.8) * 40.0, -_alt() + sin(z._time * 1.5) * 12.0)
			_steer(tgt, DRIFT_SPEED, delta)
			if _cd <= 0.0 and absf(d.x) < 380.0:
				if learned:
					state = BEHIND
					_st = BEHIND_T
					behinds += 1
					_tell_learned(pl)
				else:
					_start_tell(pl)
		BEHIND:   # עוקף אותך אל הצד שאתה לא מכוון אליו
			if has:
				var face: float = signf(pl._aim.x) if absf(pl._aim.x) > 0.05 else 1.0
				var tgt: Vector2 = pl.global_position + Vector2(-face * BEHIND_X, -_alt() * 0.8)
				_steer(tgt, 300.0, delta)
				z._dir = signf(d.x) if absf(d.x) > 6.0 else z._dir
				if _st <= 0.0 or (z.global_position.distance_to(tgt) < 40.0 and _st < BEHIND_T - 0.4):
					_start_tell(pl)
			else:
				state = HOVER
		TELL:
			z.velocity = z.velocity.move_toward(Vector2.ZERO, 500.0 * delta)
			if has and _st > VENT_T * 0.35:
				_target = _target.lerp(pl.global_position + Vector2(pl.velocity.x * 0.15, 0.0), delta * 4.0)
			if _st <= 0.0:
				state = DROP
				_st = 1.1
				_hit_done = false
				drops += 1
				if drops == 1:
					Game.story.emit("flyer", {"z": z})
				var aim: Vector2 = _target + Vector2(0.0, -6.0) - z.global_position
				z.velocity = aim.normalized() * DROP_SPEED
				Sfx.play("whoosh", z.global_position, -4.0, 0.15, 2)
		DROP:
			z.velocity = z.velocity.move_toward((_target + Vector2(0.0, -6.0) - z.global_position).normalized() * DROP_SPEED, 900.0 * delta)
			if has and not _hit_done and _body_rect().intersects(pl.body_rect()):
				_hit_done = true
				if pl._roll_t <= 0.0:
					drop_hits += 1
				pl.hurt(DROP_DMG, Vector2(signf(d.x) if d.x != 0.0 else z._dir, -0.6))
			if _st <= 0.0 or z.global_position.y >= _target.y - 8.0 or z.is_on_floor() or z.get_slide_collision_count() > 0:
				state = LOW
				_st = LOW_T
				_gwind = -1.0
				_gcd = 0.15
				z.velocity *= 0.2
				if Art.on_screen(z, z.global_position):
					Particles.burst(z.get_parent(), z.global_position, "snow", Vector2.UP, 6)
		LOW:
			var gy: float = (pl.global_position.y if has else z.global_position.y) - 4.0
			var tx: float = pl.global_position.x - signf(d.x) * 30.0 if has else z.global_position.x
			_steer(Vector2(tx, gy + sin(z._time * 3.0) * 3.0), 70.0, delta)
			if has:
				z._dir = signf(d.x) if absf(d.x) > 6.0 else z._dir
			if _gwind >= 0.0:
				_gwind -= delta
				if _gwind < 0.0:
					gaffs += 1
					Sfx.play("bu_gaff", z.global_position, -3.0, 0.15, 2)
					if has and absf(d.x) < GAFF_R + 10.0 and absf(d.y) < 60.0 and d.x * z._dir > -8.0:
						if pl._roll_t <= 0.0:
							gaff_hits += 1
						pl.hurt(GAFF_DMG, Vector2(z._dir * 1.0, -0.3))
					_gcd = 0.9
			elif has and _gcd <= 0.0 and absf(d.x) < GAFF_R and absf(d.y) < 60.0:
				_gwind = GAFF_WIND
			if _st <= 0.0:
				state = RISE
				_st = 1.6
		RISE:
			z.velocity = z.velocity.move_toward(Vector2(z._dir * -40.0, -RISE_SPEED * (0.5 + 0.12 * float(alive_count()))), 500.0 * delta)
			var top: float = (pl.global_position.y if has else _home.y + _alt()) - _alt()
			if z.global_position.y <= top or _st <= 0.0:
				state = HOVER
				_cd = randf_range(ATTACK_CD.x, ATTACK_CD.y)
				_side = -_side
		FALL:
			z.velocity.y += z.gravity * delta
			z.velocity.x = move_toward(z.velocity.x, 0.0, 100.0 * delta)
			if z.is_on_floor():
				_land()
				return true
		SINK:
			_sink_k = minf(1.0, _sink_k + delta * 0.9)
			z.velocity = Vector2.ZERO
			if Engine.get_physics_frames() % 8 == 0:
				Particles.burst(z.get_parent(), z.global_position + Vector2(randf_range(-8, 8), -4.0), "drop", Vector2.UP, 2)
			if _sink_k >= 1.0 and not z.dead:
				z.take_damage(999, z.global_position + Vector2(0, -30), Vector2.DOWN, false, {"source": "drown", "fixed": 999})
			z.move_and_slide()
			return true
	z.move_and_slide()
	return true


func _steer(tgt: Vector2, spd: float, delta: float) -> void:
	var to: Vector2 = tgt - z.global_position
	var want: Vector2 = to.limit_length(spd) if to.length() > 6.0 else Vector2.ZERO
	if to.length() < 60.0:
		want *= to.length() / 60.0
	z.velocity = z.velocity.move_toward(want, 360.0 * delta)


func _body_rect() -> Rect2:
	return Rect2(z.global_position + Vector2(-16.0 * _sc, -54.0 * _sc), Vector2(32.0 * _sc, 54.0 * _sc))


func _start_tell(pl: Node) -> void:
	state = TELL
	_st = VENT_T
	_target = pl.global_position
	_vented = true
	Sfx.play("bu_vent", z.global_position, -2.0, 0.15, 2)


func _tell_learned(pl: Node) -> void:
	var m: Node = z.get_parent()
	if m != null and not m.has_meta("bu_told_behind"):
		m.set_meta("bu_told_behind", true)
		z._popup("IT COMES FROM BEHIND", Color("ffb070"), 14, -100.0)
		if pl.has_method("_say"):
			pl._say("They saw me popping the balloons... now they drop behind me", Color("ffb070"))


func _start_fall() -> void:
	state = FALL
	falls += 1
	_fall_y = z.global_position.y
	z.collision_mask = 1 | 16
	z.velocity = Vector2(z.velocity.x * 0.5, minf(z.velocity.y, 0.0) - 60.0)
	z._popup("NO MORE LIFT", Color("ffb070"), 12, -80.0)


func _land() -> void:
	var stage: Node = z.get_parent().get("_stage") if z.get_parent() != null else null
	if stage != null and stage.has_method("in_water_at") and stage.in_water_at(z.global_position):
		state = SINK
		sinks += 1
		_sink_k = 0.0
		Sfx.play("splash", z.global_position, 2.0, 0.1, 2)
		Particles.burst(z.get_parent(), z.global_position, "drop", Vector2.UP, 14)
		Particles.burst(z.get_parent(), z.global_position, "mist", Vector2.UP, 5)
		return
	var h: float = z.global_position.y - _fall_y
	var dmg := int(clampf(h * FALL_DMG_K, 10.0, 60.0))
	splats += 1
	Sfx.play("bu_splat", z.global_position, 0.0, 0.1, 2)
	Particles.burst(z.get_parent(), z.global_position, "snow", Vector2.UP, 10)
	if Quality.gore() > 0.0:
		Particles.burst(z.get_parent(), z.global_position + Vector2(0, -6), "hit", Vector2.UP, int(10 * Quality.gore()))
	var cam: Camera2D = z.get_viewport().get_camera_2d() if z.get_viewport() != null else null
	if cam != null and cam.has_method("shake") and Art.on_screen(z, z.global_position):
		cam.shake(3.0, 0.2)
	state = GROUNDED
	z.chase_speed = z.chase_speed * 0.8
	z.take_damage(dmg, z.global_position + Vector2(0, -30), Vector2.UP, false, {"source": "fall", "fixed": dmg})
	if not z.dead:
		z._popup("GROUNDED", Color("ffb070"), 12, -80.0)


# ============================================================
#  בלונים
# ============================================================
func hit_balloon(i: int, dmg := 1) -> void:
	if i < 0 or i >= _b.size() or not _b[i].alive or z == null or not is_instance_valid(z):
		return
	_b[i].hp = int(_b[i].hp) - dmg
	var wp: Vector2 = z.global_position + _bpos(i)
	if int(_b[i].hp) > 0:
		Sfx.play("clink", wp, -4.0, 0.2, 2)
		Particles.burst(z.get_parent(), wp, "spark", Vector2.UP, 3)
		return
	_b[i].alive = false
	pops += 1
	if _b[i].node != null and is_instance_valid(_b[i].node):
		_b[i].node.queue_free()
	_b[i].node = null
	Sfx.play("bu_pop", wp, 0.0, 0.15, 3)
	var fx := PopFx.new()
	fx.c = _b[i].col
	fx.r = float(_b[i].r) * _sc
	fx.position = wp
	z.get_parent().add_child(fx)
	if not z.dead:
		var m: Node = z.get_parent()
		if m != null:
			m.set_meta("buoy_pops", int(m.get_meta("buoy_pops", 0)) + 1)
		z.velocity.y += 70.0
		if state == HOVER or state == IDLE:
			state = HOVER
			_cd = minf(_cd + 0.3, 1.2)   # נבהל - אבל עדיין יורד לתקוף בקרוב


func on_damage(_amount: int, _hit_pos: Vector2, _dir: Vector2, src: Dictionary) -> bool:
	var s := str(src.get("source", "bullet"))
	if src.has("blast") or s in ["grenade", "barrel", "rocket", "launcher", "molotov"]:   # פיצוץ קרוב: מפוצץ גם בלונים
		for i in _b.size():
			if _b[i].alive and randf() < 0.6:
				hit_balloon(i, 2)
	return true


func on_death() -> void:
	for i in _b.size():
		if _b[i].node != null and is_instance_valid(_b[i].node):
			_b[i].node.queue_free()
		_b[i].node = null
	if state == SINK:
		z.hide()
		return
	if alive_count() >= 2 and state != FALL and state != GROUNDED:   # הגופה נסחפת לשמיים
		ascends += 1
		var a := Ascend.new()
		a.tm = self
		a.dir = z._dir
		a.position = z.global_position
		a.vel = Vector2(z.velocity.x * 0.3, -30.0)
		z.get_parent().add_child(a)
		z.hide()
		return
	# בלון אחד: עף לבד, הגוף נופל
	for i in _b.size():
		if _b[i].alive:
			_b[i].alive = false
			var a := Ascend.new()
			a.tm = self
			a.only = i
			a.position = z.global_position
			a.vel = Vector2(0.0, -60.0)
			z.get_parent().add_child(a)


# ============================================================
#  ציור
# ============================================================
func draw() -> bool:
	var t: float = z._time
	var fl: bool = z._flash > 0.0
	# צל / מטרה על הרצפה
	if not z.dead and (state == TELL or state == DROP):
		var gp: Vector2 = _target - z.global_position
		var k: float = clampf(1.0 - _st / VENT_T, 0.0, 1.0) if state == TELL else 1.0
		DrawBatch.colored_polygon(z, Art.ellipse(gp, 20.0 + 8.0 * k, 4.0 + 2.0 * k, 0.0, 16), Color(0.05, 0.1, 0.18, 0.25 + 0.3 * k))
		DrawBatch.arc(z, gp, 26.0 - 8.0 * k, 0.0, TAU, 20, Color(1.0, 0.5, 0.15, 0.6 * k), 1.5)
	elif not z.dead and state != GROUNDED and state != SINK and not z.is_on_floor():
		var pl := player()
		if pl != null:
			var gy: float = pl.global_position.y - z.global_position.y
			if gy > 10.0 and gy < 420.0:
				DrawBatch.colored_polygon(z, Art.ellipse(Vector2(0, gy), 16.0, 3.0, 0.0, 12), Color(0.05, 0.1, 0.18, 0.18))
	# חבלים + בלונים (בלי היפוך)
	if not z.dead or state == FALL:
		_draw_balloons(z, Vector2(0.0, -48.0 * _sc), t, fl, -1)
	# גוף
	begin_draw(state == GROUNDED)
	var pose := 0
	match state:
		DROP:
			pose = 1
		LOW:
			pose = 2
		FALL:
			pose = 3
		TELL:
			pose = 4
		GROUNDED:
			pose = 5
		SINK:
			pose = 6
	if z.dead:
		pose = 3
	draw_body(z, pose, t, fl, z._walk_phase)
	end_draw()
	if state == SINK and not z.dead:   # מים מכסים אותו
		var sk := _sink_k * 60.0 * _sc
		DrawBatch.rect(z, Rect2(-30, -sk, 60, sk + 2.0), Color(0.03, 0.08, 0.14, 0.92))
		DrawBatch.line(z, Vector2(-30, -sk), Vector2(30, -sk), Color(0.6, 0.85, 1.0, 0.7), 1.5)
	return true


# בלונים וחבלים. anchor = נקודת הרתמה. only >= 0: רק הבלון הזה
func _draw_balloons(ci: CanvasItem, anchor: Vector2, t: float, fl: bool, only: int, k_alpha := 1.0, offs := Vector2.ZERO) -> void:
	for i in _b.size():
		if only >= 0 and i != only:
			continue
		if only < 0 and not _b[i].alive:
			continue
		var b: Dictionary = _b[i]
		var p: Vector2 = (_bpos(i) if only == -1 else _bpos_free(i, t)) + offs
		var r: float = float(b.r) * _sc
		var bottom := p + Vector2(0.0, r * (1.15 if int(b.kind) == WEATHER else 1.0))
		var mid := anchor.lerp(bottom, 0.5) + Vector2(sin(t * 2.0 + float(b.ph)) * 2.0, 3.0)
		var rc := Color(0.85, 0.8, 0.65, 0.85 * k_alpha)
		DrawBatch.polyline(ci, PackedVector2Array([anchor, mid, bottom]), rc, 1.0, true)
		var c: Color = Color.WHITE if fl else b.col
		c.a *= k_alpha
		match int(b.kind):
			WEATHER:   # בלון לטקס שקוף-למחצה, קשר למטה
				var cc := Color(c.r, c.g, c.b, 0.82 * k_alpha)
				DrawBatch.colored_polygon(ci, Art.ellipse(p, r, r * 1.12, 0.0, 22), cc)
				DrawBatch.colored_polygon(ci, Art.ellipse(p + Vector2(0, r * 0.15), r * 0.8, r * 0.85, 0.0, 16), Color(c.r * 0.88, c.g * 0.9, c.b * 0.95, 0.5 * k_alpha))
				DrawBatch.colored_polygon(ci, Art.ellipse(p + Vector2(-r * 0.38, -r * 0.45), r * 0.22, r * 0.34, -0.5, 10), Color(1, 1, 1, 0.75 * k_alpha))
				DrawBatch.colored_polygon(ci, PackedVector2Array([bottom + Vector2(-2.5, -1.0), bottom + Vector2(2.5, -1.0), bottom + Vector2(0, 2.5)]), Color(c.r * 0.8, c.g * 0.8, c.b * 0.8, k_alpha))
				DrawBatch.arc(ci, p, r * 1.02, -2.4, -0.9, 10, Color(1, 1, 1, 0.3 * k_alpha), 1.0)
			FLOAT:   # מצוף רשת קשיח: כתום, רשת חבל, עין חבל
				Art.disc(ci, p, r, c, Color(0.1, 0.05, 0.02, 0.85 * k_alpha), 1.2)
				DrawBatch.colored_polygon(ci, Art.ellipse(p + Vector2(r * 0.25, r * 0.25), r * 0.7, r * 0.7, 0.0, 14), Color(0.0, 0.0, 0.0, 0.14 * k_alpha))
				DrawBatch.colored_polygon(ci, Art.ellipse(p + Vector2(-r * 0.35, -r * 0.4), r * 0.28, r * 0.2, -0.6, 10), Color(1, 1, 1, 0.55 * k_alpha))
				var nc := Color(0.35, 0.25, 0.12, 0.8 * k_alpha)
				for q in 3:
					var ox := (float(q) - 1.0) * r * 0.6
					DrawBatch.arc(ci, p + Vector2(ox * 0.2, 0), r * 0.98, -PI / 2.0 - 0.9 + ox * 0.05, -PI / 2.0 + 0.9 + ox * 0.05, 8, nc, 1.0)
				DrawBatch.line(ci, p + Vector2(-r, 0), p + Vector2(r, 0), nc, 1.0)
				DrawBatch.line(ci, p + Vector2(0, -r), p + Vector2(0, r), nc, 1.0)
				if int(b.hp) < 2:   # סדק
					DrawBatch.polyline(ci, PackedVector2Array([p + Vector2(-r * 0.2, -r * 0.7), p + Vector2(r * 0.1, -r * 0.1), p + Vector2(-r * 0.1, r * 0.3), p + Vector2(r * 0.3, r * 0.7)]), Color(0.1, 0.0, 0.0, 0.9 * k_alpha), 1.4)
			_:   # פנדר: קפסולה מצולעת
				var pts := Art.ellipse(p, r * 0.75, r * 1.5, 0.0, 18)
				Art.fill(ci, pts, c, Color(0.05, 0.05, 0.08, 0.85 * k_alpha), 1.2)
				for q in 3:
					var yy := p.y - r * 0.8 + float(q) * r * 0.8
					DrawBatch.line(ci, Vector2(p.x - r * 0.65, yy), Vector2(p.x + r * 0.65, yy), Color(0, 0, 0, 0.25 * k_alpha), 1.2)
				DrawBatch.line(ci, p + Vector2(-r * 0.35, -r), p + Vector2(-r * 0.35, r * 0.6), Color(1, 1, 1, 0.35 * k_alpha), 1.4)


# הגוף. pose: 0 מרחף, 1 צונח (רגליים קודם), 2 נמוך (מוט וו), 3 נופל / מת, 4 פותח שסתום, 5 על הקרקע (צולע), 6 שוקע, 7 גופה נסחפת
func draw_body(ci: CanvasItem, pose: int, t: float, fl: bool, walk: float) -> void:
	var suit := Color.WHITE if fl else _suit
	var suit_d := Color.WHITE if fl else Art.shade(_suit, 0.3)
	var sk := Color.WHITE if fl else _skin
	var tape := Color.WHITE if fl else _tape
	var boots := Color.WHITE if fl else _boots
	var sway := sin(t * 1.6) * 2.0
	var hip := Vector2(0, -24)
	var sh := Vector2(1.0, -44)
	var ff := Vector2(3.0 + sway * 0.5, -1.0)
	var fb := Vector2(-3.0 - sway * 0.5, 1.0)
	var hf := Vector2(2.0, -66.0)    # ידיים על החבל מעל הראש
	var hb := Vector2(-1.0, -64.0)
	match pose:
		1:   # רגליים קודם
			ff = Vector2(13.0, -10.0)
			fb = Vector2(9.0, -6.0)
			hf = Vector2(4.0, -68.0)
			hb = Vector2(-3.0, -66.0)
		2:   # מוט וו
			var gk: float = clampf(_gwind / GAFF_WIND, 0.0, 1.0) if _gwind >= 0.0 else 0.0
			hf = sh + Vector2(12.0 - gk * 14.0, -2.0 - gk * 16.0)
			hb = Vector2(-1.0, -64.0)
			ff = Vector2(5.0, -2.0)
			fb = Vector2(-4.0, 0.0)
		3:   # מתנופף
			ff = Vector2(10.0 + sin(t * 14.0) * 4.0, -12.0)
			fb = Vector2(-9.0 + cos(t * 13.0) * 4.0, -6.0)
			hf = sh + Vector2(14.0, -12.0 + sin(t * 16.0) * 5.0)
			hb = sh + Vector2(-12.0, -14.0 + cos(t * 15.0) * 5.0)
		4:   # מושך בחבל השסתום
			hf = Vector2(3.0, -70.0 + sin(t * 20.0) * 2.0)
			hb = Vector2(-2.0, -60.0)
			ff = Vector2(4.0, -4.0)
			fb = Vector2(-2.0, -6.0)
		5:   # צולע על הקרקע
			var p := walk
			ff = Vector2(sin(p) * 5.0 + 1.0, -maxf(0.0, cos(p)) * 2.0)
			fb = Vector2(sin(p + PI) * 3.0 - 2.0, 0.0)
			hf = sh + Vector2(9.0, 12.0)
			hb = sh + Vector2(-5.0, 14.0)
		7:   # גופה תלויה ברתמה
			ff = Vector2(2.0 + sway, 0.0)
			fb = Vector2(-2.0 + sway * 0.6, 1.0)
			hf = sh + Vector2(3.0, 16.0)
			hb = sh + Vector2(-3.0, 16.0)
	# רגליים: חליפה עבה + מגפיים
	for q in 2:
		var f: Vector2 = fb if q == 0 else ff
		var hp := hip + Vector2(-2.0 if q == 0 else 2.0, 0.0)
		var knee := Art.joint(hp, f + Vector2(0, -3), 11.5, 11.5, 1.0)
		var c := suit_d if q == 0 else suit
		Art.limb(ci, PackedVector2Array([hp, knee, f + Vector2(0, -4)]), 7.4, c)
		DrawBatch.line(ci, knee.lerp(f, 0.3) + Vector2(-3.5, 0), knee.lerp(f, 0.3) + Vector2(3.5, 0), tape, 1.6)
		Art.fill(ci, PackedVector2Array([f + Vector2(-3.5, -6.0), f + Vector2(3.5, -6.0), f + Vector2(7.5, -1.5), f + Vector2(7.5, 0.5), f + Vector2(-4.0, 0.5)]), boots, Art.OUTLINE, 1.0)
	# יד אחורית
	_limb_arm(ci, sh + Vector2(-3, 1), hb, suit_d, sk, tape)
	# גוף: חליפה תפוחה, רתמה, רצועות מחזירות
	var torso := PackedVector2Array([sh + Vector2(-8, -2), sh + Vector2(8, -1), hip + Vector2(8, 2), hip + Vector2(-8, 1)])
	Art.fill_shaded(ci, torso, suit, 0.12, 0.3)
	DrawBatch.line(ci, sh.lerp(hip, 0.45) + Vector2(-7.5, 0), sh.lerp(hip, 0.45) + Vector2(7.5, 0), tape, 2.2)
	DrawBatch.line(ci, sh + Vector2(0.5, 1), hip + Vector2(0.5, -2), Color(0.1, 0.1, 0.1, 0.5), 1.0)   # רוכסן
	var hc := Color.WHITE if fl else Color("2a2a30")
	DrawBatch.line(ci, sh + Vector2(-6, 0), hip + Vector2(5, -3), hc, 2.0)
	DrawBatch.line(ci, sh + Vector2(6, 0), hip + Vector2(-5, -3), hc, 2.0)
	Art.disc(ci, sh + Vector2(0.5, 9.5), 2.2, Color.WHITE if fl else Color("b0b0b8"), Art.OUTLINE, 0.8)   # קרבינר
	if pose != 7:
		DrawBatch.line(ci, sh + Vector2(0.5, 8.0), Vector2(0.5, -66.0), Color(0.85, 0.8, 0.65, 0.9), 1.2)   # החבל הראשי
	# ראש: קפוצ'ון החליפה או כובע צמר; פנים כחולות, כפור
	var head := sh + Vector2(2.0, -8.0)
	if pose == 3 or pose == 7:
		head = sh + Vector2(3.0, -6.0)
	Art.disc(ci, head, 6.6, sk)
	DrawBatch.colored_polygon(ci, Art.ellipse(head + Vector2(-1.5, 1.5), 4.5, 4.5, 0.0, 10), Color(0.2, 0.25, 0.45, 0.2))
	if _hood:
		var hood := PackedVector2Array([head + Vector2(-8, 5), head + Vector2(-9, -3), head + Vector2(-4, -9), head + Vector2(4, -9.5), head + Vector2(8, -4), head + Vector2(5, -3), head + Vector2(-2, -4), head + Vector2(-3, 4)])
		Art.fill_shaded(ci, hood, suit, 0.1, 0.3)
		DrawBatch.arc(ci, head + Vector2(1.5, 0.5), 7.0, -2.6, 0.6, 10, tape, 1.4)
	else:
		var cap := Color.WHITE if fl else _cap
		Art.fill(ci, PackedVector2Array([head + Vector2(-7, -1), head + Vector2(-6, -7), head + Vector2(0, -10), head + Vector2(6, -7), head + Vector2(7, -2)]), cap, Art.OUTLINE, 1.0)
		DrawBatch.line(ci, head + Vector2(-7, -2), head + Vector2(7, -2.5), Art.shade(cap, -0.2), 2.0)
		Art.disc(ci, head + Vector2(-1, -10.5), 2.0, Art.shade(cap, -0.25), Art.OUTLINE, 0.8)
	# פנים
	if pose == 7:   # עיניים סגורות
		DrawBatch.line(ci, head + Vector2(2.5, -1.0), head + Vector2(5.0, -0.8), Color(0.1, 0.1, 0.15), 1.0)
	else:
		DrawBatch.colored_polygon(ci, Art.ellipse(head + Vector2(3.6, -1.0), 1.8, 1.4, 0.0, 8), Color(0.08, 0.03, 0.05))
		if not fl:
			Art.glow(ci, head + Vector2(3.8, -1.0), 3.0, Color(0.6, 0.9, 1.0, 0.5))
			DrawBatch.circle(ci, head + Vector2(3.9, -1.0), 0.8, Color(0.85, 0.95, 1.0))
	var mo := 1.5 if pose == 1 or pose == 3 else 0.4
	DrawBatch.colored_polygon(ci, PackedVector2Array([head + Vector2(2.0, 2.6), head + Vector2(5.8, 2.2), head + Vector2(5.4, 3.6 + mo), head + Vector2(2.2, 3.8 + mo)]), Color(0.15, 0.05, 0.12))
	DrawBatch.line(ci, head + Vector2(2.0, 2.5), head + Vector2(5.8, 2.1), Color(0.35, 0.4, 0.7), 0.9)   # שפתיים כחולות
	if _beard:
		var bc := Color.WHITE if fl else Color(0.85, 0.92, 0.98)
		DrawBatch.colored_polygon(ci, PackedVector2Array([head + Vector2(-2, 2), head + Vector2(6, 3.5), head + Vector2(4, 8), head + Vector2(-1, 7)]), Color(bc.r, bc.g, bc.b, 0.85))
		for q in 3:
			DrawBatch.line(ci, head + Vector2(float(q) * 2.0, 6.5), head + Vector2(float(q) * 2.0 + 0.3, 9.5), Color(0.9, 0.97, 1.0, 0.8), 0.8)
	# יד קדמית + מוט וו
	_limb_arm(ci, sh + Vector2(4, 1), hf, suit, sk, tape)
	if pose == 2:
		var gk2: float = clampf(_gwind / GAFF_WIND, 0.0, 1.0) if _gwind >= 0.0 else 0.0
		var ang := lerpf(0.15, -1.6, gk2)
		var tip := hf + Vector2.from_angle(ang) * 30.0
		var tail := hf - Vector2.from_angle(ang) * 8.0
		DrawBatch.line(ci, tail, tip, Color.WHITE if fl else Color("8a6a3a"), 2.2)
		var hk := Color.WHITE if fl else Color("a0a8b0")
		DrawBatch.polyline(ci, PackedVector2Array([tip, tip + Vector2.from_angle(ang) * 5.0, tip + Vector2.from_angle(ang + 1.6) * 6.0, tip + Vector2.from_angle(ang + 2.6) * 3.0]), hk, 1.8)
	# כפור על החליפה + נשימה
	if pose != 7 and not fl:
		var bp := fmod(t + float(_b.size()), 2.4)
		if bp < 1.0:
			DrawBatch.colored_polygon(ci, Art.ellipse(head + Vector2(8.0 + bp * 6.0, 2.0 - bp * 3.0), 1.5 + bp * 3.0, 1.0 + bp * 2.0, 0.0, 10), Color(1, 1, 1, 0.4 * (1.0 - bp)))
	for q in 3:
		var fp := sh.lerp(hip, 0.2 + float(q) * 0.3) + Vector2(-6.0 + float(q) * 4.0, 0.0)
		DrawBatch.circle(ci, fp, 1.2, Color(1, 1, 1, 0.35))


func _limb_arm(ci: CanvasItem, s: Vector2, h: Vector2, sleeve: Color, sk: Color, tape: Color) -> void:
	var el := Art.joint(s, h, 10.5, 10.5, -1.0)
	Art.limb(ci, PackedVector2Array([s, el, h]), 5.6, sleeve)
	DrawBatch.line(ci, el.lerp(h, 0.45) + Vector2(-2.5, -1.5), el.lerp(h, 0.45) + Vector2(2.5, 1.5), tape, 1.5)
	Art.disc(ci, h, 3.0, Color(0.15, 0.15, 0.18) if sk != Color.WHITE else sk, Art.OUTLINE, 0.9)   # כפפה


# ============================================================
#  גוף לבלון (נפגע = מתפוצץ)
# ============================================================
class Balloon extends StaticBody2D:
	var tm = null
	var idx := 0

	func _ready() -> void:
		add_to_group("blastable")

	func hit_by_bullet(_p: Vector2, _n: Vector2, _d: Vector2) -> void:
		if tm != null:
			tm.hit_balloon(idx, 1)

	func take_bullet(_p: Vector2) -> void:
		if tm != null:
			tm.hit_balloon(idx, 1)

	func blast_rect() -> Rect2:
		return Rect2(global_position - Vector2(14, 14), Vector2(28, 28))

	func hit_by_blast(_c: Vector2, _r: float) -> void:
		if tm != null:
			tm.hit_balloon(idx, 2)


# ---- פיצוץ בלון: טבעת + פיסות גומי ----
class PopFx extends Node2D:
	var c := Color.WHITE
	var r := 12.0
	var _t := 0.0
	var _bits := []

	func _ready() -> void:
		z_index = 9
		for i in 9:
			var a := randf() * TAU
			_bits.append([Vector2.from_angle(a) * r * 0.6, Vector2.from_angle(a) * randf_range(90.0, 220.0) + Vector2(0, -40), randf() * TAU, randf_range(-12.0, 12.0)])

	func _process(delta: float) -> void:
		_t += delta
		if _t > 0.8:
			queue_free()
			return
		for b in _bits:
			b[1] = (b[1] as Vector2) * (1.0 - delta * 2.5) + Vector2(0, 300.0 * delta)
			b[0] = (b[0] as Vector2) + (b[1] as Vector2) * delta
			b[2] = float(b[2]) + float(b[3]) * delta
		queue_redraw()

	func _draw() -> void:
		DrawBatch.begin(self)
		_draw_b()
		DrawBatch.end(self)

	func _draw_b() -> void:
		var k := clampf(_t / 0.12, 0.0, 1.0)
		if _t < 0.18:
			DrawBatch.arc(self, Vector2.ZERO, r * (0.8 + k * 1.2), 0.0, TAU, 20, Color(1, 1, 1, 0.8 * (1.0 - k)), 2.0)
		var a := clampf(1.0 - (_t - 0.4) / 0.4, 0.0, 1.0)
		for b in _bits:
			var p: Vector2 = b[0]
			var d := Vector2.from_angle(float(b[2]))
			DrawBatch.colored_polygon(self, PackedVector2Array([p - d * 3.0, p + d * 3.0 + Vector2(0, 1.5), p + Vector2(d.y, -d.x) * 2.0]), Color(c.r, c.g, c.b, a))


# ---- גופה שנסחפת לשמיים (או בלון בודד שעף) ----
class Ascend extends Node2D:
	var tm = null
	var only := -1
	var dir := 1.0
	var vel := Vector2(0, -30)
	var _t := 0.0
	var _drip := 0.0

	func _ready() -> void:
		z_index = 3

	func _process(delta: float) -> void:
		_t += delta
		vel.y = move_toward(vel.y, -42.0 if only < 0 else -80.0, 20.0 * delta)
		vel.x = move_toward(vel.x, 18.0 + sin(_t * 0.5) * 10.0, 10.0 * delta)
		position += vel * delta
		if only < 0 and Quality.gore() > 0.0:
			_drip -= delta
			if _drip <= 0.0 and _t < 4.0:
				_drip = randf_range(0.25, 0.6) / maxf(0.3, Quality.gore())
				Particles.burst(get_parent(), global_position + Vector2(0, -2), "hit", Vector2.DOWN, 1)
		if _t > 9.0:
			queue_free()
			return
		queue_redraw()

	func _draw() -> void:
		DrawBatch.begin(self)
		_draw_b()
		DrawBatch.end(self)

	func _draw_b() -> void:
		if tm == null:
			return
		var a := clampf(9.0 - _t, 0.0, 1.0)
		if only >= 0:
			tm._draw_balloons(self, (tm._b[only].off as Vector2) * tm._sc + Vector2(0, 40), _t, false, only, a)
			return
		tm._draw_balloons(self, Vector2(0.0, -48.0 * tm._sc), _t, false, -2, a)
		var rot := sin(_t * 0.9) * 0.12
		DrawBatch.set_transform(self, Vector2.ZERO, rot, Vector2(dir * tm._sc, tm._sc))
		modulate = Color(1, 1, 1, a)
		tm.draw_body(self, 7, _t, false, 0.0)
		DrawBatch.set_transform(self, Vector2.ZERO, 0.0, Vector2.ONE)
