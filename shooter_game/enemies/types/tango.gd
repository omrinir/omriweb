extends "res://enemies/zombie_type.gd"
# ============================================================
#  TANGO (שלב 48, "OLD QUARTER" - בואנוס איירס) - זוג רקדני טנגו מתים שלא הפסיקו לרקוד בקמיניטו.
#  תמיד בא בזוג: הוא (חליפה שחורה, כובע פדורה, שיער משוח) והיא (שמלה אדומה עם שסע, ורד בשיער).
#  כשאחד נוצר - הוא מזמין את בן/בת הזוג (main._spawn_zombie). הם נשארים קרובים זה לזה (PAIR_GAP).
#    DANCE - מתקדמים אליך בצעדי טנגו (ההליכה = צעד-צעד-עצירה).
#    SPIN  - רואים את הירייה שלך (on_shot) -> מסתובבים (SPIN_T): הקליעים עוברים דרכם. אחר כך SPIN_CD.
#    GANCHO - קרוב אליך: הרגל עולה (KICK_T) ובועטת (נזק + הדף).
#    HEARTBREAK - בן הזוג מת: זעם - מהיר יותר (RAGE_SPEED), נזק +1, ולא מסתובב יותר (רק ריצה ישר אליך).
#  "THEY LEARN YOUR RHYTHM - TOGETHER": כל זוגות הטנגו מקשיבים לקצב היריות שלך (main meta "tango_beat").
#    ירי בקצב קבוע = ה-SPIN_CD מתכוונן בדיוק לקצב שלך (עד SPIN_MIN) והם מתחמקים מכל ירייה.
#    איך פוגעים: לשבור את הקצב - שתי יריות מהר, הפסקה, ושוב. או כשהם בועטים. פיצוץ / שוטגאן מקרוב.
#  צלילים: "tg_spin" (סיבוב), "tg_kick", "tg_heart" (צעקת שבר לב), "tg_bando" (אקורד בנדוניאון כשהם מופיעים).
#  לשנות: SPIN_T, SPIN_CD0, SPIN_MIN, DODGE_CHANCE, PAIR_GAP, KICK_R, KICK_T, RAGE_SPEED, CLOSE.
# ============================================================

const SOUNDS := {
	"tg_spin": [["N", 0, 0, 0.0, 0.3, 0.02, 7.0, 0.3, 0.5, 0, 0.6]],
	"tg_kick": [["N", 0, 0, 0.0, 0.18, 0.0, 12.0, 0.6, 0.4, 0, 0.6], ["S", 170, 90, 0.0, 0.14, 0.0, 16.0, 0.4, 1.0, 0]],
	"tg_heart": {"drive": 2.6, "layers": [["V", 300, 180, 0.0, 1.1, 0.04, 1.6, 0.9, 1.0, 0.06, 0, [900, 1400, 50]], ["N", 0, 0, 0.0, 1.0, 0.02, 2.5, 0.15, 0.5, 0, 0.1]]},
	"tg_bando": [["W", 220, 220, 0.0, 0.9, 0.08, 1.4, 0.18, 0.5, 0.01], ["W", 277, 277, 0.0, 0.9, 0.08, 1.4, 0.14, 0.5, 0.01], ["W", 330, 330, 0.0, 0.9, 0.08, 1.4, 0.12, 0.5, 0.01]],
}

const SPIN_T := 0.42
const SPIN_CD0 := 1.2
const SPIN_MIN := 0.06       # (הפסקה מינימלית בין סיבוב לסיבוב, מעבר ל-SPIN_T)
const PAIR_GAP := 34.0
const KICK_R := 46.0
const KICK_T := 0.32
const KICK_CD := 1.4
const RAGE_SPEED := 1.7
const CLOSE := 70.0         # מקרוב לא מספיקים להסתובב
const DODGE_CHANCE := 0.75  # גם כשהם מוכנים - לא תמיד מספיקים

enum { DANCE, SPIN, KICK }
var state := DANCE
var role := 0                # 0 = הוא, 1 = היא
var partner: Node = null
var heartbroken := false
var spins := 0               # לבדיקות
var kicks := 0
var seen := 0
var _st := 0.0
var _cd := 0.0
var _kick_cd := 0.5
var _kicked := false
var _layer := 4
var _spin_dir := 1.0
var _last_shot := -1.0
static var _spawning := false   # יוצרים עכשיו בן/בת זוג (לא יוצר זוג משלו)


func stats() -> Dictionary:
	if role == 1:
		return {"name": "TANGO", "hp": 34, "walk": 48.0, "chase": 104.0, "damage": 1, "bite_delay": 0.8, "scale": 1.0, "width": 0.9,
			"duck": 0.0, "cover": 0.0, "skin": Color("b8b0a8"), "shirt": Color("b01822"), "pants": Color("b01822"), "shoe": Color("1a1012"), "points": 380}
	return {"name": "TANGO", "hp": 38, "walk": 48.0, "chase": 104.0, "damage": 1, "bite_delay": 0.8, "scale": 1.04, "width": 0.95,
		"duck": 0.0, "cover": 0.0, "skin": Color("a8aca0"), "shirt": Color("1c1c22"), "pants": Color("1c1c22"), "shoe": Color("e8e4dc"), "points": 380}


func brain_overrides() -> Dictionary:
	return {"aggression": 0.35, "flank_probability": -0.2}


func setup() -> void:
	_layer = z.collision_layer
	if _spawning:
		return
	var main: Node = z.get_parent()
	if main == null or not main.has_method("_spawn_zombie"):
		return
	_spawning = true
	var c = main._spawn_zombie(z.global_position.x + 30.0, z.global_position.y, z.kind)
	_spawning = false
	if c == null:
		return
	c.global_position.y = z.global_position.y
	c.dormant = false
	c.type_mod.role = 1
	c.type_mod._restyle()
	c.type_mod.partner = z
	partner = c
	Sfx.play("tg_bando", z.global_position, -8.0, 0.05, 2)


func _restyle() -> void:   # היא: שמלה אדומה
	var k := stats()
	z.skin = k.skin
	z.shirt = k.shirt
	z.pants = k.pants
	z.shoe = k.shoe
	z.hp = int(k.hp)
	z.max_hp = int(k.hp)
	z.sc = float(k.scale)
	z.wf = float(k.width)


func _partner_ok() -> bool:
	return partner != null and is_instance_valid(partner) and not partner.dead


# ---- "רואים" את הירייה ----
func on_shot(from: Vector2, dir: Vector2) -> void:
	if z == null or z.dead or heartbroken:
		return
	var c: Vector2 = z.global_position + Vector2(0, -28.0 * z.sc)
	var rel := c - from
	var along := rel.dot(dir)
	if along < 0.0 or along > 1300.0 or absf(rel.cross(dir)) > 50.0:
		return
	seen += 1
	_learn_beat()
	if state != DANCE or _cd > 0.0 or rel.length() < CLOSE or randf() > DODGE_CHANCE:
		return
	_spin()


func _learn_beat() -> void:   # הקצב שלך: הזמן בין שתי יריות (ממוצע משותף לכל הזוגות)
	var now: float = z._time
	var main: Node = z.get_parent()
	if _last_shot >= 0.0 and main != null:
		var gap := now - _last_shot
		if gap > 0.08 and gap < 2.0:
			var beat: float = float(main.get_meta("tango_beat")) if main.has_meta("tango_beat") else SPIN_CD0
			var nb := lerpf(beat, gap * 0.92, 0.35)
			main.set_meta("tango_beat", nb)
			if beat > 0.55 and nb <= 0.55:
				z._popup("THEY LEARNED YOUR RHYTHM", Color("ffd0e0"), 12, -80.0)
	_last_shot = now


func spin_cd() -> float:
	var main: Node = z.get_parent()
	var beat: float = float(main.get_meta("tango_beat")) if main != null and main.has_meta("tango_beat") else SPIN_CD0
	return clampf(beat * 0.85, SPIN_T + SPIN_MIN, SPIN_CD0)   # מוכנים בדיוק לירייה הבאה שלך


func _spin() -> void:
	spins += 1
	state = SPIN
	_st = SPIN_T
	_cd = spin_cd()
	_spin_dir = 1.0 if randf() < 0.5 else -1.0
	z.collision_layer = 0   # הקליעים עוברים
	z.velocity.x = _spin_dir * 160.0
	Sfx.play("tg_spin", z.global_position, -4.0, 0.15, 3)


func damage_mult(_zone: String, _src: Dictionary) -> float:
	return 1.3 if state == KICK else 1.0


func on_death() -> void:
	z.collision_layer = _layer
	if _partner_ok() and partner.type_mod != null:
		partner.type_mod.break_heart()


func break_heart() -> void:
	if heartbroken or z.dead:
		return
	heartbroken = true
	z.damage += 1
	z._popup("HEARTBREAK!", Color("ff4060"), 17, -85.0)
	Sfx.play("tg_heart", z.global_position, 2.0, 0.1, 2, 1.1 if role == 1 else 0.8)
	if z.brain != null:
		z._alert_t = 6.0


func logic(_pl: Node, _d: Vector2, _delta: float, speed: float) -> float:
	if heartbroken:
		return speed * RAGE_SPEED
	if _partner_ok():   # להישאר צמודים: אם בן הזוג רחוק - הולכים אליו
		var dx: float = partner.global_position.x - z.global_position.x
		if absf(dx) > PAIR_GAP * 2.5 and absf(partner.global_position.y - z.global_position.y) < 40.0:
			z._dir = signf(dx)
			return speed * 1.2
	var beat := fposmod(z._time * 2.0, 2.0)   # צעד-צעד-עצירה
	return speed * (1.0 if beat < 1.4 else 0.25)


func physics(pl: Node, delta: float) -> bool:
	_st -= delta
	_cd -= delta
	_kick_cd -= delta
	if z.dead:
		z.collision_layer = _layer
		return false
	match state:
		SPIN:
			z.velocity.x = move_toward(z.velocity.x, 0.0, 500.0 * delta)
			if not z.is_on_floor():
				z.velocity.y += z.gravity * delta
			z.move_and_slide()
			if _st <= 0.0:
				state = DANCE
				z.collision_layer = _layer
			return true
		KICK:
			z.velocity.x = move_toward(z.velocity.x, 0.0, 900.0 * delta)
			if not z.is_on_floor():
				z.velocity.y += z.gravity * delta
			z.move_and_slide()
			if _st <= 0.0 and not _kicked:
				_kicked = true
				Sfx.play("tg_kick", z.global_position, 0.0, 0.1, 2)
				if pl != null and not pl.dead and absf(pl.global_position.x - z.global_position.x) < KICK_R + 16.0 and absf(pl.global_position.y - z.global_position.y) < 60.0:
					kicks += 1
					pl.hurt(z.damage, Vector2(signf(pl.global_position.x - z.global_position.x) * 2.2, -0.9))
			if _st <= -0.25:
				state = DANCE
				_kick_cd = KICK_CD * (0.6 if heartbroken else 1.0)
			return true
	if pl != null and not pl.dead and _kick_cd <= 0.0 and z.is_on_floor() and absf(pl.global_position.x - z.global_position.x) < KICK_R and absf(pl.global_position.y - z.global_position.y) < 50.0:
		state = KICK
		_st = KICK_T
		_kicked = false
		z._dir = signf(pl.global_position.x - z.global_position.x)
		return true
	return false


# ============================================================
#  ציור. הוא: חליפה שחורה, חולצה לבנה, פדורה, נעליים דו-צבעוניות. היא: שמלה אדומה מתנפנפת, שיער שחור אסוף + ורד.
#  SPIN = הגוף "מסתובב" (מתכווץ לרוחב) והחצאית מתעופפת. KICK = רגל אחת עולה ב"גנצ'ו".
# ============================================================
func draw() -> bool:
	begin_draw()
	if state == SPIN and not z.dead and not z._lying():
		var k := cos((1.0 - _st / SPIN_T) * TAU * 1.5 * _spin_dir)
		z.draw_set_transform(Vector2.ZERO, 0.0, Vector2(z._dir * z.wf * z.sc * (0.25 + 0.75 * absf(k)) * signf(k + 0.001), z.sc))
	var sk := col(z.skin)
	var p: float = z._walk_phase
	var f: Array = feet(5.0, 2.0)
	var hip := Vector2(0, -22)
	var sh := Vector2(1.5, -38)
	var head := sh + Vector2(3.0, -8.5)
	var kick := state == KICK
	var lift := clampf(1.0 - _st / KICK_T, 0.0, 1.0) if kick else 0.0
	if kick:   # גנצ'ו: הרגל הקדמית עולה ונמתחת קדימה
		f[0] = Vector2(6.0 + 14.0 * lift, -4.0 - 16.0 * lift)
		f[1] = Vector2(-3, 0)
	if role == 1:
		_draw_her(sk, f, hip, sh, head, p, kick)
	else:
		_draw_him(sk, f, hip, sh, head, p, kick)
	end_draw()
	return true


func _draw_him(sk: Color, f: Array, hip: Vector2, sh: Vector2, head: Vector2, p: float, kick: bool) -> void:
	var suit := col(z.shirt)
	var shoe := col(z.shoe)
	z._leg(hip + Vector2(-2, 0), f[1], col(Art.shade(z.pants, 0.2)), col(z.pants), shoe)
	z._leg(hip + Vector2(2, 0), f[0], col(z.pants), col(z.pants), shoe)
	for ft in [f[0], f[1]]:   # נעליים דו-צבעוניות
		z.draw_rect(Rect2(ft + Vector2(-1, -2.5), Vector2(4, 2.5)), col(Color("1a1012")))
	var hb := sh + Vector2(-6.0 - sin(p) * 2.0, 13.0)
	if _partner_ok() and not heartbroken:
		hb = sh + Vector2(-9.0, 2.0)   # יד אחורית מושטת לבת הזוג
	_sleeve_arm(sh + Vector2(-3, 1), hb, Art.shade(sk, 0.25), Art.shade(suit, 0.3))
	Art.fill_shaded(z, PackedVector2Array([sh + Vector2(-8, -1), sh + Vector2(8, 0), hip + Vector2(6, 2), hip + Vector2(-6, 2)]), suit, 0.12, 0.35)
	Art.fill(z, PackedVector2Array([sh + Vector2(2, 0), sh + Vector2(6, 0), sh + Vector2(4, 10)]), col(Color("e8e4dc")), Art.NONE)   # חולצה
	z.draw_line(sh + Vector2(4, 1), sh + Vector2(4, 6), col(Color("8a1018")), 1.4)   # עניבה
	z.draw_circle(sh + Vector2(-3, 4), 1.4, col(Color("b01822")))   # ציפורן בדש
	Art.oval_shaded(z, head, 5.2, 5.8, sk, 0.0)
	face(head, Vector2(3.2, -0.6))
	z.draw_line(head + Vector2(1, 3.5), head + Vector2(5.5, 3.0), col(Color("2a1418")), 0.9)   # שפם דק
	z.draw_circle(head + Vector2(3.5, -1.0), 1.0, Color(0.95, 0.9, 0.7) if not heartbroken else Color(1.0, 0.25, 0.2))
	# פדורה
	Art.fill(z, PackedVector2Array([head + Vector2(-8, -3.5), head + Vector2(8, -4.5), head + Vector2(7, -3), head + Vector2(-8, -2)]), col(Color("1a1a20")), Art.OUTLINE, 0.9)
	Art.fill(z, PackedVector2Array([head + Vector2(-5, -3.5), head + Vector2(-4, -10), head + Vector2(4, -10.5), head + Vector2(5, -4)]), col(Color("22222a")), Art.OUTLINE, 0.9)
	z.draw_rect(Rect2(head + Vector2(-4.8, -5.5), Vector2(9.6, 1.6)), col(Color("8a1018")))
	var hf := sh + (Vector2(11, 4) if not kick else Vector2(9, -4))
	_sleeve_arm(sh + Vector2(3, 1), hf, sk, suit)


func _draw_her(sk: Color, f: Array, hip: Vector2, sh: Vector2, head: Vector2, p: float, kick: bool) -> void:
	var dress := col(z.shirt)
	var legc := col(Color("c0b4ac"))
	z._leg(hip + Vector2(-2, 0), f[1], legc, sk, col(z.shoe))
	z._leg(hip + Vector2(2, 0), f[0], legc, sk, col(z.shoe))
	# חצאית: מתנפנפת בסיבוב, שסע לרגל הקדמית
	var flare := 4.0 + (10.0 if state == SPIN else 0.0) + sin(p) * 1.5
	var skirt := PackedVector2Array([hip + Vector2(-6, -4), hip + Vector2(6, -4), hip + Vector2(8.0 + flare * 0.6, 12.0), hip + Vector2(3.0, 9.0 + (0.0 if kick else 3.0)),
		hip + Vector2(-2.0, 13.0), hip + Vector2(-8.0 - flare, 11.0 + sin(z._time * 5.0) * 1.5)])
	Art.fill_shaded(z, skirt, dress, 0.15, 0.4)
	z.draw_line(hip + Vector2(-6, 10), hip + Vector2(6, 9), col(Color("6a0a10")), 1.0)
	var hb := sh + Vector2(-6.0 - sin(p) * 2.0, 13.0)
	if _partner_ok() and not heartbroken:
		hb = sh + Vector2(-8.0, 1.0)
	z._arm(sh + Vector2(-2, 1), hb, Art.shade(sk, 0.2), Color(0, 0, 0, 0))
	Art.fill_shaded(z, PackedVector2Array([sh + Vector2(-6, 0), sh + Vector2(6, 0), hip + Vector2(5, -3), hip + Vector2(-5, -3)]), dress, 0.15, 0.35)
	Art.oval_shaded(z, head, 4.8, 5.6, sk, 0.0)
	# שיער שחור אסוף + ורד אדום
	Art.fill(z, PackedVector2Array([head + Vector2(-5.5, 1), head + Vector2(-4, -5.5), head + Vector2(2, -6.5), head + Vector2(5.5, -3), head + Vector2(0, -3.5), head + Vector2(-2, 2)]), col(Color("120c10")), Art.OUTLINE, 0.8)
	Art.disc(z, head + Vector2(-6.5, -2.5), 3.0, col(Color("120c10")), Art.OUTLINE, 0.8)   # פקעת
	Art.disc(z, head + Vector2(-3.5, -6.0), 2.2, col(Color("d01828")), Art.OUTLINE, 0.7)   # ורד
	z.draw_line(head + Vector2(3.0, 3.5), head + Vector2(5.5, 3.2), col(Color("8a0a14")), 1.2)   # שפתון
	z.draw_circle(head + Vector2(3.2, -0.8), 0.9, Color(0.95, 0.9, 0.7) if not heartbroken else Color(1.0, 0.25, 0.2))
	var hf := sh + (Vector2(10, 5) if not kick else Vector2(-4, -12))
	z._arm(sh + Vector2(3, 1), hf, sk, Color(0, 0, 0, 0))


func _sleeve_arm(shoulder: Vector2, hand: Vector2, sk: Color, sleeve: Color) -> void:   # יד עם שרוול חליפה
	z._arm(shoulder, hand, sk, sleeve)
	var elbow := Art.joint(shoulder, hand, 9.0, 9.5, -1.0)
	Art.limb(z, PackedVector2Array([shoulder, elbow, elbow.lerp(hand, 0.6)]), 6.0, sleeve, Art.OUTLINE, true, false)
	z.draw_circle(elbow.lerp(hand, 0.62), 1.6, col(Color("e8e4dc")))   # חפת
