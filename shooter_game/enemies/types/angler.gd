extends "res://enemies/zombie_type.gd"
# ============================================================
#  ANGLER (שלב 49, "RIVER DELTA") - דייג טובע: גוף דק ושחוח, ידיים ארוכות, פה רחב עם שיני מחט (כמו דג-פנס),
#    ומוט עצם שצומח מהגב ומחזיק פנס דייגים ישן מול הפנים. (השראה: "לוס מאלה" - האור הרע של הפולקלור הארגנטינאי
#    שמטעה מטיילים בלילה, ודג-הפנס שמפתה טרף עם אור.)
#  LURK  - שקוע עד העיניים במים (ערוץ / בוץ / מאחורי קנים) - רואים רק את הפנס שמרחף כמו אור תועה. יריות בגוף = "SPLASH"
#          (רק העיניים מעל המים נפגעות). הפנס עצמו = מטרה (Lure, גוף קטן בשכבה 4).
#  SWING - אתה מתקרב (SPRING_R): הפנס מתנדנד חזק והעיניים נדלקות (אזהרה SWING_T) ->
#  LEAP  - זינוק מהמים אליך. תפס? -> DRAG: גורר אותך אחורה למים (DRAG_T) ונושך. A/D לסירוגין = להשתחרר (player.grab).
#  HUNT  - פספס / שוחרר: רודף רגיל, וכשאתה מתרחק (LURK_CD) - שוקע שוב איפה שהוא.
#  פנס שנורה -> BLIND: נשבר, הוא נחשף ומסונוור (BLIND_T, נזק x BLIND_MULT) ומשם רודף בלי פנס (לא מתחבא יותר).
#  בגאות (TideDirector) - שוחה אליך מתחת למים מכל מקום (SWIM_V).
#  "THEY LEARN THE LIGHT - TOGETHER": אחרי DARK_LEARN פנסים שנורו (main meta "lures_shot") הדייגים מחשיכים את הפנס,
#    ומדליקים אותו רק כשאתה כבר קרוב (DARK_R) - עם אזהרה קצרה יותר ("THE LIGHTS GO DARK").
#  צלילים: "an_lure" (צליל מתכתי של הפנס), "an_splash" (זינוק), "an_glass" (פנס נשבר).
#  לשנות: SPRING_R, SWING_T, LEAP_V, DRAG_T, DRAG_V, LURK_CD, BLIND_T, BLIND_MULT, DARK_LEARN, DARK_R, SWIM_V.
# ============================================================

const SOUNDS := {
	"an_lure": [["S", 1800, 1750, 0.0, 0.5, 0.0, 6.0, 0.18, 1.0, 0.02], ["S", 2700, 2650, 0.0, 0.4, 0.0, 8.0, 0.1, 1.0, 0.02]],
	"an_splash": [["N", 0, 0, 0.0, 0.4, 0.0, 9.0, 0.6, 0.6, 0, 0.7], ["S", 200, 90, 0.0, 0.2, 0.0, 12.0, 0.3, 1.0, 0.1]],
	"an_glass": [["C", 0, 0, 0.0, 0.04, 0.0, 60.0, 0.4, 1.0, 0], ["S", 3200, 2600, 0.0, 0.15, 0.0, 25.0, 0.25, 1.0, 0.05], ["N", 0, 0, 0.0, 0.2, 0.0, 20.0, 0.3, 0.8, 0, 0.9]],
}

const SPRING_R := 150.0
const SWING_T := 0.45
const SWING_T_DARK := 0.3
const LEAP_V := Vector2(440.0, -300.0)
const DRAG_T := 1.3
const DRAG_V := 110.0
const LURK_CD := 6.0
const BLIND_T := 2.0
const BLIND_MULT := 1.5
const DARK_LEARN := 2
const DARK_R := 230.0
const SWIM_V := 150.0
const LURE_OFF := Vector2(30.0, -46.0)   # איפה הפנס ביחס לרגליים (מול הפנים)

enum { LURK, SWING, LEAP, DRAG, HUNT, BLIND }
var state := LURK
var has_lantern := true
var lit := true
var leaps := 0                # לבדיקות
var grabs := 0
var drags_done := 0
var splashes := 0
var lures_shot := 0
var _st := 0.0
var _lurk_cd := 0.0
var _air := 0.0
var _lure: Node2D = null
var _dark_said := false


func stats() -> Dictionary:
	return {"name": "ANGLER", "hp": 34, "walk": 40.0, "chase": 96.0, "damage": 1, "bite_delay": 0.8, "scale": 1.05, "width": 1.0,
		"duck": 0.0, "cover": 0.0, "skin": Color("6a8a84"), "shirt": Color("8a7a4a"), "pants": Color("3a4a4a"), "shoe": Color("2a2a2a"), "points": 460}


func brain_overrides() -> Dictionary:
	return {"aggression": 0.7}


func setup() -> void:
	_lure = Lure.new()
	_lure.owner_t = self
	z.get_parent().add_child.call_deferred(_lure)


static func learned(main: Node) -> bool:
	return main.has_meta("lures_shot") and int(main.get_meta("lures_shot")) >= DARK_LEARN


func lure_pos() -> Vector2:
	var t: float = z._time
	var sw := 0.0
	if state == SWING:
		sw = sin(t * 24.0) * 10.0
	elif state == LURK:
		sw = sin(t * 1.6) * 4.0
	var off := LURE_OFF + Vector2(sw, sin(t * 2.1) * 3.0 + (14.0 if state == LURK else 0.0))
	return z.global_position + Vector2(off.x * z._dir, off.y) * z.sc


func can_bite() -> bool:
	return state == HUNT


func can_groan() -> bool:
	return state != LURK


# בזמן ההמתנה הגוף מתחת למים: רק העיניים פגיעות. פיצוצים פוגעים תמיד
func on_damage(_amount: int, hit_pos: Vector2, dir: Vector2, src: Dictionary) -> bool:
	if z.dead or not (state == LURK or state == SWING):
		return true
	var s := str(src.get("source", "bullet"))
	if src.has("blast") or not (s == "bullet" or s == "melee"):
		return true
	var ly: float = (hit_pos.y - z.global_position.y) / z.sc
	if ly > -24.0 and ly < -8.0:
		return true
	splashes += 1
	Sfx.play("an_splash", hit_pos, -10.0, 0.2, 2)
	Particles.burst(z.get_parent(), Vector2(hit_pos.x, z.global_position.y - 4.0), "smoke", Vector2(-dir.x, -1.0), 3)
	if splashes % 5 == 1:
		z._popup("SPLASH", Color("a0c0b0"), 11, -40.0)
	return false


func damage_mult(_zone: String, _src: Dictionary) -> float:
	return BLIND_MULT if state == BLIND else 1.0


func lantern_shot() -> void:
	if not has_lantern or z.dead:
		return
	has_lantern = false
	lures_shot += 1
	var main: Node = z.get_parent()
	main.set_meta("lures_shot", int(main.get_meta("lures_shot")) + 1 if main.has_meta("lures_shot") else 1)
	Sfx.play("an_glass", lure_pos(), 0.0, 0.1, 2)
	Particles.burst(main, lure_pos(), "fire", Vector2.UP, 6)
	_release_player()
	state = BLIND
	_st = BLIND_T
	z.velocity = Vector2(-z._dir * 60.0, -220.0)
	z._popup("BLINDED", Color("ffe080"), 14, -70.0)
	if learned(main) and not main.has_meta("lures_dark_said"):
		main.set_meta("lures_dark_said", true)
		z._popup("THE LIGHTS GO DARK", Color("ffd070"), 15, -95.0)


func physics(pl: Node, delta: float) -> bool:
	_st -= delta
	_lurk_cd -= delta
	if z.dead:
		return false
	var has_pl: bool = pl != null and not pl.dead
	var d: Vector2 = pl.global_position - z.global_position if has_pl else Vector2(9999, 0)
	var main: Node = z.get_parent()
	match state:
		LURK:
			var dark := learned(main)
			lit = not dark or absf(d.x) < DARK_R
			if not has_pl:
				return _move(0.0, delta)
			var tide := float(main.get_meta("tide")) if main.has_meta("tide") else 0.0
			if absf(d.y) < 60.0 and absf(d.x) < SPRING_R and z.is_on_floor():
				z._dir = signf(d.x) if d.x != 0.0 else z._dir
				state = SWING
				_st = SWING_T_DARK if dark else SWING_T
				lit = true
				Sfx.play("an_lure", lure_pos(), -2.0, 0.1, 2)
				return _move(0.0, delta)
			if tide > 0.9 and absf(d.x) < 650.0 and absf(d.y) < 40.0:   # גאות: שוחה מתחת למים
				z._dir = signf(d.x)
				return _move(z._dir * SWIM_V, delta)
			return _move(0.0, delta)
		SWING:
			if has_pl:
				z._dir = signf(d.x) if d.x != 0.0 else z._dir
			if _st <= 0.0:
				state = LEAP
				leaps += 1
				_air = 0.0
				var vx := clampf((absf(d.x) + 10.0) / (2.0 * absf(LEAP_V.y) / float(z.gravity)), 160.0, LEAP_V.x)   # נוחת עליך
				z.velocity = Vector2(z._dir * vx, LEAP_V.y)
				Sfx.play("an_splash", z.global_position, 0.0, 0.1, 2)
				Particles.burst(main, z.global_position + Vector2(0, -6), "smoke", Vector2.UP, 6)
				z._voice("zscream", 1.0, -4.0)
			return _move(0.0, delta)
		LEAP:
			_air += delta
			z.velocity.y += z.gravity * delta
			z.move_and_slide()
			if has_pl and pl.grabbed_by == null and pl._roll_t <= 0.0 and not pl.god_mode() and pl.body_rect().grow(6.0).intersects(Rect2(z.global_position + Vector2(-14.0, -50.0) * z.sc, Vector2(28.0, 50.0) * z.sc)):
				grabs += 1
				pl.hurt(1, Vector2(z._dir * 0.3, -0.2))
				pl.grab(z)
				state = DRAG
				_st = DRAG_T
				z._popup("DRAGGED!", Color("a0e0c0"), 14, -80.0)
				return true
			if _air > 0.15 and z.is_on_floor():
				state = HUNT
				_lurk_cd = LURK_CD
			return true
		DRAG:
			if not has_pl or pl.grabbed_by != z:
				state = HUNT
				_lurk_cd = LURK_CD
				return false
			var away: float = -signf(d.x) if d.x != 0.0 else -z._dir
			z._dir = -away
			z.velocity.x = away * DRAG_V
			if not z.is_on_floor():
				z.velocity.y += z.gravity * delta
			z.move_and_slide()
			pl.velocity.x = z.velocity.x
			pl._push_t = maxf(float(pl._push_t), 0.12)
			if _st <= 0.0:
				drags_done += 1
				_release_player()
				pl.hurt(1, Vector2(-away * 1.2, -0.5))
				Sfx.play("zhit", pl.global_position, 0.0, 0.1, 2)
				state = HUNT
				_lurk_cd = LURK_CD
			return true
		BLIND:
			if _st <= 0.0:
				state = HUNT
				_lurk_cd = 9999.0
				return false
			z.velocity.x = move_toward(z.velocity.x, sin(z._time * 6.0) * 40.0, 400.0 * delta)
			if not z.is_on_floor():
				z.velocity.y += z.gravity * delta
			z.move_and_slide()
			return true
		HUNT:
			if has_lantern and _lurk_cd <= 0.0 and z.is_on_floor() and absf(d.x) > 380.0:
				state = LURK
				z._popup("...", Color("a0c0b0"), 12, -40.0)
				return _move(0.0, delta)
	return false


func _move(vx: float, delta: float) -> bool:
	z.velocity.x = move_toward(z.velocity.x, vx, 900.0 * delta)
	if not z.is_on_floor():
		z.velocity.y += z.gravity * delta
	z.move_and_slide()
	return true


func _release_player() -> void:
	var pl := player()
	if pl != null and pl.grabbed_by == z:
		pl.grabbed_by = null


func on_release() -> void:   # השחקן השתחרר (A/D)
	state = HUNT
	_lurk_cd = LURK_CD
	z.velocity = Vector2(-z._dir * 160.0, -180.0)
	z._popup("SHAKEN OFF", Color("c0e0d0"), 12, -70.0)


func on_death() -> void:
	_release_player()
	if is_instance_valid(_lure):
		_lure.queue_free()


# ============================================================
#  הפנס: מרחף מול הפנים, גוף קטן בשכבה 4 - כדורים נעצרים בו (hit_by_bullet).
# ============================================================
class Lure extends Node2D:
	var owner_t = null
	var _body: StaticBody2D = null

	class LureBody extends StaticBody2D:
		var l = null
		func hit_by_bullet(_p: Vector2, _n: Vector2, _d: Vector2) -> void:
			if l != null and l.owner_t != null:
				l.owner_t.lantern_shot()

	func _ready() -> void:
		z_index = 7
		var b := LureBody.new()
		b.l = self
		b.collision_layer = 4
		b.collision_mask = 0
		var cs := CollisionShape2D.new()
		var sh := CircleShape2D.new()
		sh.radius = 9.0
		cs.shape = sh
		b.add_child(cs)
		add_child(b)
		_body = b

	func _physics_process(_delta: float) -> void:
		if owner_t == null or owner_t.z == null or not is_instance_valid(owner_t.z) or owner_t.z.dead or not owner_t.has_lantern:
			queue_free()
			return
		global_position = owner_t.lure_pos()
		if Art.on_screen(self, global_position, 60.0):
			queue_redraw()

	func _draw() -> void:
		DrawBatch.begin(self)
		_draw_b()
		DrawBatch.end(self)

	func _draw_b() -> void:
		var o = owner_t
		var on: bool = o.lit
		var t := float(Engine.get_physics_frames()) / 60.0
		var fl := 0.8 + 0.2 * sin(t * 13.0) * sin(t * 7.0)
		if o.state == o.SWING:
			fl = 1.2
		if on:
			Art.glow(self, Vector2.ZERO, 46.0 * fl, Color(0.75, 1.0, 0.7, 0.22))
			Art.glow(self, Vector2.ZERO, 16.0, Color(0.9, 1.0, 0.8, 0.5 * fl))
		DrawBatch.line(self, Vector2(0, -9), Vector2(0, -13), Color("2a2a26"), 1.5)   # ידית
		DrawBatch.rect(self, Rect2(-5, -9, 10, 2), Color("3a3a32"))
		DrawBatch.rect(self, Rect2(-4.5, -7, 9, 11), Color(0.85, 1.0, 0.75, 0.9 * fl) if on else Color(0.2, 0.25, 0.2, 0.9))   # זכוכית
		DrawBatch.line(self, Vector2(-4.5, -7), Vector2(-4.5, 4), Color("2a2a26"), 1.2)
		DrawBatch.line(self, Vector2(4.5, -7), Vector2(4.5, 4), Color("2a2a26"), 1.2)
		DrawBatch.rect(self, Rect2(-5, 4, 10, 2.5), Color("3a3a32"))
		if on:
			DrawBatch.circle(self, Vector2(0, -1), 2.2, Color(1, 1, 0.9))
			var wl: float = o.z.global_position.y - global_position.y
			if o.state == o.LURK and wl > 0.0:   # ההשתקפות במים
				DrawBatch.colored_polygon(self, Art.ellipse(Vector2(0, wl - 2.0), 12.0, 2.0, 0.0, 10), Color(0.75, 1.0, 0.7, 0.25 * fl))


# ============================================================
#  ציור: גוף דק ושחוח, ידיים ארוכות עם טפרים, ראש רחב עם פה ענק ושיני מחט, מוט עצם מהגב אל הפנס,
#  כובע דייגים קרוע ומעיל שעווה. ב-LURK - שקוע: רק הראש העליון ועיניים מעל המים + אדוות.
# ============================================================
func draw() -> bool:
	begin_draw()
	var sk := col(z.skin)
	var coat := col(z.shirt)
	var t: float = z._time
	var p: float = z._walk_phase
	var sink := 0.0
	if state == LURK:
		sink = 24.0   # רק הכובע והעיניים מעל המים
	elif state == SWING:
		sink = clampf(24.0 - (SWING_T - _st) * 40.0, 6.0, 24.0)
	var o := Vector2(0, sink)
	var crouch := state == LURK or state == SWING
	var leap := state == LEAP
	var f: Array = feet(5.0, 2.5)
	var hip := Vector2(-2, -20) + o
	var sh := Vector2(5, -36) + o
	if crouch:
		sh = Vector2(8, -30) + o
	elif leap:
		sh = Vector2(9, -38)
		f = [Vector2(-4, -6), Vector2(-12, -10)]
	var head := sh + Vector2(7, -5)
	if not crouch:
		z._leg(hip + Vector2(-2, 0), f[1], col(Art.shade(z.pants, 0.25)), sk, col(z.shoe))
		z._leg(hip + Vector2(2, 0), f[0], col(z.pants), sk, col(z.shoe))
	# מוט עצם מהגב אל הפנס
	var rod_base := sh + Vector2(-6, -2)
	var lp: Vector2 = (lure_pos() - z.global_position) / z.sc
	lp.x *= z._dir / z.wf
	if has_lantern:
		var mid := rod_base.lerp(lp, 0.5) + Vector2(-4, -18)
		DrawBatch.polyline(z, PackedVector2Array([rod_base, rod_base.lerp(mid, 0.5) + Vector2(-2, -3), mid, mid.lerp(lp + Vector2(0, -13), 0.6), lp + Vector2(0, -13)]), col(Color("c8c0a8")), 2.2)
		for q in 3:   # חוליות
			DrawBatch.circle(z, rod_base.lerp(mid, 0.3 + float(q) * 0.3), 1.6, col(Color("a8a088")))
	else:
		DrawBatch.line(z, rod_base, rod_base + Vector2(4, -12), col(Color("c8c0a8")), 2.2)   # שבור
	# יד אחורית (ארוכה)
	var hb := sh + (Vector2(10, 14) if crouch else (Vector2(18, -4) if leap else Vector2(-6.0 - sin(p) * 3.0, 18.0)))
	z._arm(sh + Vector2(-3, 1), hb, Art.shade(sk, 0.25), Art.shade(coat, 0.3))
	# גוף: מעיל שעווה צהבהב קרוע, שחוח
	var torso := PackedVector2Array([sh + Vector2(-8, -1), sh + Vector2(6, 1), hip + Vector2(7, 2), hip + Vector2(-7, 2)])
	Art.fill_shaded(z, torso, coat, 0.15, 0.4)
	DrawBatch.line(z, sh + Vector2(-2, 2), hip + Vector2(0, 2), col(Color(0.2, 0.18, 0.1, 0.6)), 1.0)
	for q in 3:   # קרעים
		DrawBatch.line(z, hip + Vector2(-6.0 + float(q) * 5.0, 2.0), hip + Vector2(-5.0 + float(q) * 5.0, 6.0), coat.darkened(0.3), 1.6)
	# ראש רחב עם פה ענק
	Art.oval_shaded(z, head, 6.8, 5.6, sk, 0.0)
	var gape := 3.0 + (3.5 if state == SWING or leap or state == DRAG else 0.0) + sin(t * 3.0) * 0.6
	DrawBatch.colored_polygon(z, PackedVector2Array([head + Vector2(-1, 1.5), head + Vector2(7.2, 0.5), head + Vector2(7.0, 1.5 + gape), head + Vector2(0, 2.5 + gape * 0.6)]), col(Color("2a0a12")))
	for q in 5:   # שיני מחט
		var tx := head.x + float(q) * 1.6
		DrawBatch.line(z, Vector2(tx, head.y + 1.0), Vector2(tx + 0.3, head.y + 3.0), Color(0.92, 0.9, 0.8), 0.8)
		DrawBatch.line(z, Vector2(tx, head.y + 2.5 + gape * 0.7), Vector2(tx + 0.3, head.y + 0.8 + gape * 0.7), Color(0.92, 0.9, 0.8), 0.8)
	var eye_c := Color(0.8, 1.0, 0.7) if (state == SWING or (lit and state == LURK)) else Color(0.85, 0.85, 0.75)
	DrawBatch.circle(z, head + Vector2(2.5, -2.2), 1.6, eye_c)   # עיניים בולטות
	DrawBatch.circle(z, head + Vector2(-1.5, -2.6), 1.3, eye_c)
	DrawBatch.circle(z, head + Vector2(2.8, -2.2), 0.6, Color(0.05, 0.1, 0.05))
	# כובע דייגים קרוע
	Art.fill(z, PackedVector2Array([head + Vector2(-7, -2), head + Vector2(-4, -7), head + Vector2(4, -7.5), head + Vector2(8, -3), head + Vector2(10, -2)]), col(Color("6a5a2a")), Art.OUTLINE, 0.8)
	# יד קדמית עם טפרים
	var hf := sh + (Vector2(12, 12) if crouch else (Vector2(22, -2) if leap or state == DRAG else Vector2(10.0 + sin(p) * 3.0, 17.0)))
	z._arm(sh + Vector2(4, 1), hf, sk, coat)
	for q in 3:
		DrawBatch.line(z, hf, hf + Vector2(2.5, -1.0 + float(q) * 1.6), col(Color("d8d0b8")), 0.8)
	if crouch:   # מים: מכסים את הגוף, אדוות
		var wl := Vector2(0, -6)
		DrawBatch.colored_polygon(z, PackedVector2Array([Vector2(-16, wl.y), Vector2(20, wl.y), Vector2(20, 2), Vector2(-16, 2)]), Color(0.3, 0.26, 0.18, 0.92))
		for q in 2:
			var k := fmod(t * 0.6 + float(q) * 0.5, 1.0)
			DrawBatch.arc(z, Vector2(4, wl.y), 8.0 + k * 12.0, PI * 1.05, PI * 1.95, 10, Color(0.8, 0.78, 0.62, 0.4 * (1.0 - k)), 1.0)
		DrawBatch.line(z, Vector2(-16, wl.y), Vector2(20, wl.y), Color(0.82, 0.78, 0.62, 0.5), 1.0)
	end_draw()
	return true
