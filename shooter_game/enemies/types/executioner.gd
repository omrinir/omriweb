extends "res://enemies/zombie_type.gd"
# ============================================================
#  EXECUTIONER (שלב 46, "WINE VALLEY") - תליין זומבי: ברדס שחור מחודד עם חורי עיניים, חזה חשוף ואפור, סינר עור,
#    וחרב ענקית - ארוכה יותר ממנו - שהוא מחזיק בשתי ידיים.
#  כשהוא הולך הלהב מוחזק אלכסונית מלפנים (החוד נגרר על הריצפה): הצד השטוח של הלהב מגן על הגוף מיריות מלפנים
#    ("CLANG"). הראש חשוף - יורים בראש, או מאחור, או כשהחרב תקועה.
#  שתי מכות עם אזהרה ברורה (WIND_T):
#    * SLAM  - החרב מורמת גבוה מעל הראש -> נוחתת על המקום שבו עמדת (טווח ארוך, סדק ברצפה + רעידה). להתחמק: לזוז הצידה.
#              אחרי SLAM הלהב תקוע ברצפה (STUCK_T): הוא לא מגן ומקבל נזק x STUCK_MULT.
#    * SWEEP - החרב נמשכת אחורה ונמוך -> מטאטאת לאורך הריצפה. להתחמק: לקפוץ.
#  "THEY LEARN HOW YOU DODGE": קפצת מעל SWEEP -> הוא עובר ליותר SLAM ("HE WON'T SWING LOW AGAIN").
#    התרחקת מ-SLAM -> הוא מוסיף לעצמו טווח (LUNGE_STEP, צעד-זינוק קדימה בזמן המכה) ויותר SWEEP ("HE READS YOUR STEP").
#  בוס (chase_range > 600): "THE HEADSMAN" - ענק, הרבה חיים, SLAM שולח גל הלם לאורך הרצפה (Shockwave - לקפוץ),
#    ולפעמים קומבו של שתי מכות (SWEEP ואז SLAM או להפך).
#  צלילים: "ex_raise" (להב מורם), "ex_whoosh" (הצלפה), "ex_slam" (מכה ברצפה), "ex_clang" (חסימה).
#  לשנות: REACH / BOSS_REACH, WIND_T, STUCK_T, STUCK_MULT, LUNGE_STEP, LUNGE_MAX, CD.
# ============================================================

const SOUNDS := {
	"ex_raise": [["S", 220, 420, 0.0, 0.35, 0.05, 6.0, 0.25, 1.0, 0.02], ["N", 0, 0, 0.0, 0.3, 0.1, 6.0, 0.12, 0.4, 0, 0.6]],
	"ex_whoosh": [["N", 0, 0, 0.0, 0.25, 0.0, 12.0, 0.7, 0.5, 0, 0.7], ["S", 700, 160, 0.0, 0.2, 0.0, 14.0, 0.25, 1.0, 0]],
	"ex_slam": [["N", 0, 0, 0.0, 0.4, 0.0, 8.0, 0.9, 0.25, 0], ["S", 80, 35, 0.0, 0.35, 0.0, 8.0, 0.9, 1.0, 0], ["S", 1400, 1300, 0.0, 0.3, 0.0, 10.0, 0.2, 1.0, 0.01]],
	"ex_clang": [["S", 1500, 1380, 0.0, 0.18, 0.0, 18.0, 0.35, 1.0, 0.02], ["S", 2300, 2200, 0.0, 0.12, 0.0, 26.0, 0.2, 1.0, 0], ["N", 0, 0, 0.0, 0.05, 0.0, 40.0, 0.2, 0.3, 0, 0.5]],
}

const REACH := 120.0          # SWEEP: כמה רחוק קדימה
const BOSS_REACH := 185.0
const SLAM_MIN := 28.0        # SLAM נוחת בין SLAM_MIN ל-REACH + lunge קדימה
const SLAM_W := 74.0
const WIND_T := 0.62
const BOSS_WIND_T := 0.55
const STRIKE_T := 0.18
const STUCK_T := 1.1          # הלהב תקוע ברצפה אחרי SLAM
const STUCK_MULT := 1.6
const RECOVER_T := 0.4
const CD := Vector2(1.4, 2.2)
const LUNGE_STEP := 26.0      # כמה טווח הוא מוסיף כל פעם שהתרחקת מ-SLAM
const LUNGE_MAX := 78.0
const WAVE_V := 430.0         # (בוס) מהירות גל ההלם
const WAVE_RANGE := 520.0

enum { IDLE, WIND, STRIKE, STUCK, RECOVER }
enum { SWEEP, SLAM }
var state := IDLE
var attack := SWEEP
var strikes := 0              # לבדיקות
var hits := 0
var blocks := 0
var waves := 0
var lunge := 0.0              # טווח נוסף שלמד
var slam_bias := 0.5          # הסיכוי ל-SLAM (לומד)
var dodges := {"jump": 0, "step": 0}
var _st := 0.0
var _cd := 1.0
var _tx := 0.0                # SLAM: איפה הלהב נוחת (x גלובלי)
var _px0 := 0.0               # איפה השחקן עמד בתחילת התנופה
var _hit_done := false
var _hit_now := false
var _combo := false
var _clang := 0.0


func _boss() -> bool:
	return z != null and float(z.chase_range) > 600.0


func stats() -> Dictionary:
	if _boss():
		return {"name": "EXECUTIONER", "hp": 260, "walk": 32.0, "chase": 66.0, "damage": 2, "bite_delay": 1.2, "scale": 1.75, "width": 1.4,
			"duck": 0.0, "cover": 0.0, "skin": Color("8a9480"), "shirt": Color("1a1416"), "pants": Color("2a2020"), "shoe": Color("1a1212"),
			"points": 1600, "boss": true, "boss_name": "THE HEADSMAN"}
	return {"name": "EXECUTIONER", "hp": 60, "walk": 36.0, "chase": 72.0, "damage": 2, "bite_delay": 1.1, "scale": 1.22, "width": 1.2,
		"duck": 0.0, "cover": 0.0, "skin": Color("8a9a84"), "shirt": Color("1a1416"), "pants": Color("3a2a22"), "shoe": Color("1a1212"), "points": 640}


func brain_overrides() -> Dictionary:
	return {"aggression": 0.55, "keep_range": REACH * 0.6}


func reach() -> float:
	return (BOSS_REACH if _boss() else REACH) + lunge


func can_bite() -> bool:
	return false


# הצד השטוח של הלהב מגן על הגוף מלפנים (לא על הראש). כשהלהב באוויר / תקוע - אין מגן.
func on_damage(_amount: int, hit_pos: Vector2, dir: Vector2, src: Dictionary) -> bool:
	var s := str(src.get("source", "bullet"))
	if not (s == "bullet" or s == "melee") or src.has("blast"):
		return true
	if not (state == IDLE or state == RECOVER) or z.dead or z._lying():
		return true
	if dir.x * z._dir >= 0.0:   # מאחור
		return true
	var ly: float = (hit_pos.y - z.global_position.y) / z.sc
	if ly < -41.0 or ly > -4.0:   # הראש / הכפות
		return true
	blocks += 1
	_clang = 0.12
	Sfx.play("ex_clang", hit_pos, -4.0, 0.12, 3)
	Particles.burst(z.get_parent(), hit_pos, "spark", Vector2(-dir.x, -0.4), 4)
	if blocks % 6 == 1:
		z._popup("CLANG", Color("d0d4dc"), 12, -70.0 * z.sc)
	return false


func damage_mult(_zone: String, _src: Dictionary) -> float:
	return STUCK_MULT if state == STUCK else 1.0


func logic(pl: Node, d: Vector2, delta: float, speed: float) -> float:
	_cd -= delta
	_clang -= delta
	if pl == null:
		return speed
	if state == IDLE:
		var sees: bool = z.brain == null or z.brain.sees
		if _cd <= 0.0 and sees and not pl.dead and absf(d.x) < reach() + 20.0 and d.y > -170.0 and d.y < 60.0:
			_start(pl, SLAM if d.y < -50.0 or randf() < slam_bias else SWEEP)
			return 0.0
		return speed
	_st -= delta
	match state:
		WIND:
			z._dir = signf(d.x) if d.x != 0.0 else z._dir
			if _st <= 0.0:
				state = STRIKE
				_st = STRIKE_T
				_hit_done = false
				strikes += 1
				Sfx.play("ex_whoosh", z.global_position, 1.0, 0.1, 3)
		STRIKE:
			if not _hit_done and _st < STRIKE_T - 0.06:
				_hit_done = true
				_resolve(pl)
			if _st <= 0.0:
				if attack == SLAM:
					state = STUCK
					_st = STUCK_T * (0.6 if _boss() else 1.0)
				else:
					state = RECOVER
					_st = RECOVER_T
			# זינוק קדימה בזמן המכה (טווח שלמד)
			if lunge > 0.0:
				return lunge / STRIKE_T
		STUCK:
			if _st <= 0.0:
				state = RECOVER
				_st = RECOVER_T
				Sfx.play("ex_raise", z.global_position, -6.0, 0.1, 2)
		RECOVER:
			if _st <= 0.0:
				state = IDLE
				_cd = randf_range(CD.x, CD.y) * (0.7 if _boss() else 1.0)
				if _combo and not pl.dead:
					_combo = false
					_start(pl, SLAM if attack == SWEEP else SWEEP)
					_st = 0.42
	return 0.0


func _start(pl: Node, kind: int) -> void:
	attack = kind
	state = WIND
	_st = BOSS_WIND_T if _boss() else WIND_T
	_px0 = pl.global_position.x
	z._dir = signf(pl.global_position.x - z.global_position.x) if pl.global_position.x != z.global_position.x else z._dir
	var px: float = pl.global_position.x + clampf(float(pl.velocity.x) * 0.25, -70.0, 70.0)
	var lo: float = z.global_position.x + z._dir * SLAM_MIN * z.sc
	var hi: float = z.global_position.x + z._dir * reach()
	_tx = clampf(px, minf(lo, hi), maxf(lo, hi))
	_combo = _boss() and randf() < 0.45
	Sfx.play("ex_raise", z.global_position, -1.0, 0.1, 3)


# הרגע של המכה: מי בתוך האזור נפגע. ואם השחקן התחמק - לומד איך
func _resolve(pl: Node) -> void:
	var zp: Vector2 = z.global_position
	var area: Rect2
	if attack == SWEEP:
		var r := reach()
		area = Rect2(zp.x if z._dir > 0.0 else zp.x - r, zp.y - 26.0, r, 26.0)
	else:
		var w := SLAM_W * (1.3 if _boss() else 1.0)
		area = Rect2(_tx - w * 0.5, zp.y - 170.0 * z.sc, w, 170.0 * z.sc)
		Sfx.play("ex_slam", Vector2(_tx, zp.y), 3.0, 0.1, 3)
		Particles.burst(z.get_parent(), Vector2(_tx, zp.y - 4.0), "smoke", Vector2.UP, 9)
		var cr := Crack.new()
		z.get_parent().add_child(cr)
		cr.global_position = Vector2(_tx, zp.y)
		cr.big = _boss()
		var cam: Node = z.get_viewport().get_camera_2d()
		if cam != null and cam.has_method("shake") and Art.on_screen(z, Vector2(_tx, zp.y)):
			cam.shake(7.0 if not _boss() else 12.0, 0.28)
		if _boss():   # גל הלם לשני הצדדים
			for dd in [-1.0, 1.0]:
				var wv := Shockwave.new()
				wv.dir = dd
				wv.owner_t = self
				z.get_parent().add_child(wv)
				wv.global_position = Vector2(_tx, zp.y)
			waves += 1
	_hit_now = pl != null and not pl.dead and area.intersects(pl.body_rect())
	if _hit_now:
		hits += 1
		pl.hurt(z.damage, Vector2(z._dir * 1.8, -0.5))
		Game.story.emit("kraken", {"z": z})
		return
	if pl == null or pl.dead or absf(pl.global_position.x - zp.x) > reach() + 140.0:
		return
	if attack == SWEEP and not pl.is_on_floor() and absf(pl.global_position.x - zp.x) < reach() + 20.0:
		learn("jump")
	elif attack == SLAM and absf(_px0 - _tx) < SLAM_W and absf(pl.global_position.x - _tx) > SLAM_W * 0.5:
		learn("step")


func learn(how: String) -> void:
	dodges[how] = int(dodges[how]) + 1
	if how == "jump":
		slam_bias = minf(slam_bias + 0.15, 0.88)
		if int(dodges.jump) == 2:
			z._popup("HE WON'T SWING LOW AGAIN", Color("ffb070"), 12, -80.0 * z.sc)
	else:
		lunge = minf(lunge + LUNGE_STEP, LUNGE_MAX)
		slam_bias = maxf(slam_bias - 0.08, 0.3)
		if int(dodges.step) == 1 or lunge >= LUNGE_MAX:
			z._popup("HE READS YOUR STEP", Color("ffb070"), 12, -80.0 * z.sc)


# ============================================================
#  סדק ברצפה אחרי SLAM (נעלם לאט)
# ============================================================
class Crack extends Node2D:
	var big := false
	var _t := 0.0

	func _ready() -> void:
		z_index = 2

	func _process(delta: float) -> void:
		_t += delta
		if _t > 2.5:
			queue_free()
			return
		if Engine.get_process_frames() % 6 == 0:
			queue_redraw()

	func _draw() -> void:
		var a := clampf(1.0 - (_t - 1.5), 0.0, 1.0)
		var s := 1.6 if big else 1.0
		var c := Color(0.05, 0.03, 0.03, 0.85 * a)
		for q in 5:
			var ang := -PI + 0.35 + float(q) * (PI - 0.7) / 4.0
			var p := Vector2.ZERO
			for k in 3:
				var np := p + Vector2.from_angle(ang + sin(float(q * 3 + k)) * 0.4) * Vector2(16.0, 3.0) * s
				DrawBatch.line(self, p, np, c, 2.0 - float(k) * 0.5)
				p = np
		DrawBatch.colored_polygon(self, Art.ellipse(Vector2(0, 1), 12.0 * s, 2.5, 0.0, 10), c)


# ============================================================
#  גל הלם (בוס): רץ לאורך הרצפה. פוגע בשחקן שעומד על הרצפה בדרך - לקפוץ מעליו
# ============================================================
class Shockwave extends Node2D:
	var dir := 1.0
	var owner_t = null
	var _d := 0.0
	var _hit := false

	func _ready() -> void:
		z_index = 4

	func _physics_process(delta: float) -> void:
		var step := 430.0 * delta   # = WAVE_V
		_d += step
		global_position.x += dir * step
		var hit := get_world_2d().direct_space_state.intersect_ray(PhysicsRayQueryParameters2D.create(global_position + Vector2(-dir * 4.0, -12), global_position + Vector2(dir * (step + 6.0), -12), 1))
		if not hit.is_empty() or _d > 520.0:   # = WAVE_RANGE
			queue_free()
			return
		var pl := get_tree().get_first_node_in_group("player")
		if not _hit and pl != null and not pl.dead and pl.is_on_floor() and absf(pl.global_position.x - global_position.x) < 18.0 and absf(pl.global_position.y - global_position.y) < 30.0:
			_hit = true
			pl.hurt(1, Vector2(dir * 1.5, -1.0))
		if Art.on_screen(self, global_position, 60.0):
			queue_redraw()
			if Engine.get_physics_frames() % 4 == 0:
				Particles.burst(get_parent(), global_position + Vector2(0, -4), "smoke", Vector2(-dir, -1.0), 1)

	func _draw() -> void:
		var a := clampf(1.0 - _d / 520.0, 0.2, 1.0)
		for q in 4:
			var x := -dir * float(q) * 9.0
			var h := (26.0 - float(q) * 6.0) * a
			DrawBatch.colored_polygon(self, PackedVector2Array([Vector2(x - 7, 0), Vector2(x + dir * 4.0, -h), Vector2(x + 7, 0)]), Color(0.45, 0.32, 0.22, 0.9 - float(q) * 0.18))
		DrawBatch.line(self, Vector2(-dir * 30.0, 0), Vector2(dir * 6.0, 0), Color(1.0, 0.8, 0.5, 0.6 * a), 2.0)


# ============================================================
#  ציור: ברדס שחור מחודד, חזה חשוף אפור-ירקרק עם תפרים, סינר עור, חרב ענקית בשתי ידיים
# ============================================================
# זווית הלהב לפי המצב (0 = ישר קדימה, חיובי = כלפי מטה)
func _blade_angle(grip_y: float) -> float:
	var guard := asin(clampf(-grip_y / 87.0, 0.0, 1.0)) + 0.03 + sin(float(z._walk_phase)) * 0.025   # החוד נוגע ברצפה מלפנים
	if z.dead:
		return 1.4
	match state:
		WIND:
			var k := 1.0 - clampf(_st / (BOSS_WIND_T if _boss() else WIND_T), 0.0, 1.0)
			k = minf(k * 2.2, 1.0)
			var tr := sin(z._time * 45.0) * 0.03 * k
			if attack == SLAM:
				return lerp_angle(guard, -2.2, k) + tr   # מעל הראש ואחורה
			return lerp_angle(guard, 2.86, k) + tr       # אחורה ונמוך
		STRIKE:
			var k2 := 1.0 - clampf(_st / STRIKE_T, 0.0, 1.0)
			if attack == SLAM:
				return lerpf(-2.2, 0.42, k2)
			return lerpf(0.5, 0.1, k2)                     # הלהב כבר קדימה ונמוך (+ עקבת תנועה לאורך הרצפה)
		STUCK:
			return 0.44 + sin(z._time * 30.0) * 0.015
		RECOVER:
			var k3 := 1.0 - clampf(_st / RECOVER_T, 0.0, 1.0)
			return lerp_angle(0.44 if attack == SLAM else 0.12, guard, k3)
	return guard


func draw() -> bool:
	begin_draw()
	var sk := col(z.skin)
	var p: float = z._walk_phase
	var f: Array = feet(5.0, 2.5)
	var hood := col(Color("161214"))
	var apron := col(Color("4a2e1c"))
	var lean := 0.0
	if state == WIND:
		lean = -4.0 if attack == SLAM else -2.0
	elif state == STRIKE or state == STUCK:
		lean = 7.0
	var hip := Vector2(0, -22)
	var sh := Vector2(2.0 + lean, -40.0)
	var head := sh + Vector2(3.0 + lean * 0.2, -9.0)
	if state == STUCK or (state == STRIKE and attack == SLAM):   # רגל קדימה, כורע
		f = [Vector2(11, 0), Vector2(-10, 0)]
		hip.y = -19.0
		sh.y = -36.0
		head = sh + Vector2(5.0, -8.0)
	z._leg(hip + Vector2(-3, 0), f[1], col(Art.shade(z.pants, 0.25)), sk, col(z.shoe))
	z._leg(hip + Vector2(3, 0), f[0], col(z.pants), sk, col(z.shoe))
	# הידיים על הניצב
	var grip_c := sh + Vector2(10.0, 8.0)
	if state == WIND and attack == SLAM:
		grip_c = sh + Vector2(-2.0, -14.0)
	elif state == WIND:
		grip_c = sh + Vector2(-10.0, 12.0)
	elif state == STRIKE or state == STUCK:
		grip_c = sh + Vector2(14.0, 10.0)
	var ang := _blade_angle(grip_c.y)
	var bd := Vector2.from_angle(ang)
	var h1 := grip_c - bd * 3.0
	var h2 := grip_c + bd * 4.0
	z._arm(sh + Vector2(-5, 1), h1, Art.shade(sk, 0.25), Art.shade(sk, 0.25))
	# גוף: חזה חשוף רחב, צלעות ותפרים, סינר עור
	var torso := PackedVector2Array([sh + Vector2(-10, -1), sh + Vector2(9, 0), sh + Vector2(10, 9), hip + Vector2(8, 2), hip + Vector2(-8, 2), sh + Vector2(-11, 9)])
	Art.fill_shaded(z, torso, sk, 0.15, 0.35)
	for q in 3:
		DrawBatch.line(z, sh + Vector2(-5, 6.0 + float(q) * 3.5), sh + Vector2(4, 7.0 + float(q) * 3.5), col(Color(0.2, 0.25, 0.2, 0.5)), 1.0)
	DrawBatch.line(z, sh + Vector2(2, 2), hip + Vector2(1, -3), col(Color("4a2a2a")), 1.2)   # תפר
	for q in 4:
		DrawBatch.line(z, sh + Vector2(0.5, 4.0 + float(q) * 4.0), sh + Vector2(3.5, 4.5 + float(q) * 4.0), col(Color("4a2a2a")), 0.9)
	Art.fill_shaded(z, PackedVector2Array([hip + Vector2(-7, -7), hip + Vector2(9, -7), hip + Vector2(12, 16), hip + Vector2(4, 18), hip + Vector2(-6, 16)]), apron, 0.12, 0.35)
	DrawBatch.line(z, hip + Vector2(2, -5), hip + Vector2(4, 16), col(Color("3a2414")), 0.9)   # קפל
	DrawBatch.line(z, hip + Vector2(-7, -7), sh + Vector2(-7, 1), col(Color("3a2414")), 1.6)   # רצועות
	DrawBatch.line(z, hip + Vector2(8, -7), sh + Vector2(6, 1), col(Color("3a2414")), 1.6)
	DrawBatch.rect(z, Rect2(hip + Vector2(-9, -9), Vector2(20, 3)), col(Color("2a1a10")))
	DrawBatch.rect(z, Rect2(hip + Vector2(0, -9.5), Vector2(4, 4)), col(Color("8a7040")))   # אבזם
	for q in 3:   # נזילות דם ויין על הסינר
		var sx := -3.0 + float(q) * 5.0
		DrawBatch.line(z, hip + Vector2(sx, -3.0 + float(q) * 2.0), hip + Vector2(sx + 0.8, 6.0 + float(q % 2) * 6.0), col(Color(0.38, 0.03, 0.1, 0.85)), 1.4)
		DrawBatch.circle(z, hip + Vector2(sx + 0.8, 6.5 + float(q % 2) * 6.0), 1.2, col(Color(0.38, 0.03, 0.1, 0.85)))
	# ברדס מחודד עם חורי עיניים, נופל על הכתפיים
	Art.fill(z, PackedVector2Array([head + Vector2(-8, 9), head + Vector2(-7, -2), head + Vector2(-3, -10), head + Vector2(-6, -17), head + Vector2(3, -9), head + Vector2(7, -2), head + Vector2(9, 9)]), hood, Art.OUTLINE, 1.1)
	DrawBatch.line(z, head + Vector2(-3, -9), head + Vector2(6, -2), col(Color(1, 1, 1, 0.08)), 1.5)
	if not z.dead:
		for e in [Vector2(1.5, -2.5), Vector2(5.5, -2.5)]:
			DrawBatch.colored_polygon(z, Art.ellipse(head + e, 1.6, 1.1, 0.0, 8), Color(0, 0, 0))
			DrawBatch.circle(z, head + e + Vector2(0.4, 0), 0.8, Color(1.0, 0.3, 0.15) if state != WIND else Color(1.0, 0.85, 0.3))
	else:
		DrawBatch.line(z, head + Vector2(0, -3), head + Vector2(7, -2), Color(0, 0, 0), 1.5)
	DrawBatch.line(z, head + Vector2(1, 3), head + Vector2(6, 3.5), col(Color("2a2024")), 1.2)   # פה מתחת לבד
	# החרב
	_sword(grip_c, bd)
	z._arm(sh + Vector2(5, 1), h2, sk, sk)
	if _clang > 0.0:
		Art.glow(z, grip_c + bd * 30.0, 12.0, Color(1, 1, 0.9, 0.6))
	end_draw()
	return true


func _sword(grip: Vector2, bd: Vector2) -> void:
	var nrm := bd.orthogonal()
	var L := 76.0
	var steel := col(Color("a8adb4"))
	var edge := col(Color("dfe3e8"))
	# ניצב + פומל
	DrawBatch.line(z, grip - bd * 9.0, grip + bd * 6.0, col(Color("3a2216")), 3.2)
	for q in 3:
		DrawBatch.line(z, grip - bd * (7.0 - float(q) * 4.5) - nrm * 1.6, grip - bd * (6.0 - float(q) * 4.5) + nrm * 1.6, col(Color("6a4a30")), 0.9)
	DrawBatch.circle(z, grip - bd * 10.5, 2.6, col(Color("8a7040")))
	# מגן
	var g := grip + bd * 7.0
	Art.fill(z, PackedVector2Array([g - nrm * 9.0 - bd * 1.5, g - nrm * 10.0 + bd * 1.5, g + nrm * 10.0 + bd * 1.5, g + nrm * 9.0 - bd * 1.5]), col(Color("7a6038")), Art.OUTLINE, 0.9)
	# להב רחב ועבה עם קצה מחודד-ריבועי (חרב תליין)
	var b0 := g + bd * 1.5
	var tip := b0 + bd * L
	var pts := PackedVector2Array([b0 - nrm * 5.0, b0 + bd * (L - 6.0) - nrm * 6.5, tip - nrm * 2.0, tip + nrm * 5.0, b0 + bd * (L - 4.0) + nrm * 6.5, b0 + nrm * 5.0])
	Art.fill(z, pts, steel, Art.OUTLINE, 1.2)
	DrawBatch.line(z, b0 + bd * 3.0, b0 + bd * (L - 8.0), col(Color("7a8088")), 1.6)   # חריץ
	DrawBatch.line(z, b0 + nrm * 4.5, b0 + bd * (L - 4.0) + nrm * 6.0, edge, 1.1)   # הלהב החד
	for q in 3:   # פגימות בלהב
		var nq := b0 + bd * (18.0 + float(q) * 19.0) + nrm * 6.0
		DrawBatch.colored_polygon(z, PackedVector2Array([nq, nq + bd * 3.0 - nrm * 1.8, nq + bd * 5.0]), col(Color("2a2a2e")))
	for q in 4:   # דם על הלהב
		DrawBatch.circle(z, b0 + bd * (L - 14.0 + float(q) * 3.0) + nrm * (2.0 - float(q)), 1.6 - float(q) * 0.2, col(Color(0.45, 0.04, 0.06, 0.85)))
	DrawBatch.line(z, b0 + bd * (L - 18.0) - nrm * 1.0, b0 + bd * (L - 4.0) + nrm * 3.0, col(Color(0.45, 0.04, 0.06, 0.7)), 1.6)
	if state == STRIKE and not z.dead:   # עקבת תנועה
		if attack == SLAM:
			DrawBatch.arc(z, g, L * 0.85, bd.angle() - 0.9, bd.angle(), 10, Color(1, 1, 1, 0.25), 5.0)
		else:   # חצי עיגול שטוח לאורך הרצפה, מאחור ועד הקצה
			var arc := PackedVector2Array()
			for i in 13:
				var u := float(i) / 12.0
				arc.append(Vector2(lerpf(-40.0, g.x + L, u), -6.0 - sin(u * PI) * 7.0))
			DrawBatch.polyline(z, arc, Color(1, 1, 1, 0.3), 6.0)
			DrawBatch.polyline(z, arc, Color(1, 1, 1, 0.5), 2.0)
