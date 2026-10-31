extends "res://enemies/zombie_type.gd"
# ============================================================
#  CAPOEIRA (שלב 37, "FAVELA HEIGHTS") - קפואריסטה זומבי: מכנסי אבאדה לבנים, חגורת קורדאו, בלי חולצה. זז בג'ינגה (נדנוד).
#  "THEY LEARNED TO DODGE": רואה כל ירייה שלך (zombie.gd on_player_fired -> on_shot). ירייה שעוברת דרכו -> AU (גלגלון) הצידה/קדימה,
#    הקליע עובר דרכו (בזמן ה-AU הוא לא פגיע). אחרי כל התחמקות - DODGE_CD.
#    לומד את הקצב שלך: כל ירייה שהוא רואה מקצרת את ה-DODGE_CD (עד DODGE_MIN).
#    איך פוגעים: שתי יריות מהר (השנייה בזמן ה-CD), מקרוב (CLOSE), שוטגאן/פיצוץ, או כשהוא בועט (לא יכול להתחמק).
#    בועט "מֵיָה לוּאָה" (סיבוב) כשהוא קרוב: KICK_T הכנה -> מכה שהודפת.
#  לשנות: DODGE_CD0, DODGE_MIN, CLOSE, KICK_R, KICK_T.
# ============================================================

const SOUNDS := {
	"cp_au": [["N", 0, 0, 0.0, 0.25, 0.0, 8.0, 0.3, 0.5, 0, 0.7]],
	"cp_kick": [["N", 0, 0, 0.0, 0.2, 0.0, 10.0, 0.6, 0.4, 0, 0.6], ["S", 160, 90, 0.0, 0.15, 0.0, 15.0, 0.4, 1.0, 0]],
	"cp_berimbau": [["S", 220, 230, 0.0, 0.4, 0.0, 5.0, 0.25, 1.0, 0.01], ["S", 245, 240, 0.25, 0.3, 0.0, 6.0, 0.2, 1.0, 0.01]],
}

const DODGE_CD0 := 1.1
const DODGE_MIN := 0.4
const CLOSE := 80.0
const KICK_R := 70.0
const KICK_T := 0.35
const KICK_CD := 1.5
const AU_T := 0.42

enum { GINGA, AU, KICK }
var state := GINGA
var dodges := 0              # לבדיקות
var seen := 0
var kicks := 0
var dodge_cd := DODGE_CD0
var _cd := 0.0
var _st := 0.0
var _kick_cd := 1.0
var _layer := 4
var _au_dir := 1.0
var _kicked := false


func stats() -> Dictionary:
	return {"name": "CAPOEIRA", "hp": 34, "walk": 50.0, "chase": 96.0, "damage": 1, "bite_delay": 0.7, "scale": 1.0, "width": 1.0,
		"duck": 0.0, "cover": 0.0, "skin": Color("7a8a6a"), "shirt": Color("7a8a6a"), "pants": Color("ecece4"), "shoe": Color("7a8a6a"), "points": 520}


func setup() -> void:
	_layer = z.collision_layer


func brain_overrides() -> Dictionary:
	return {"aggression": 0.9}


func can_bite() -> bool:
	return false


# zombie.gd (on_player_fired): ירית מ-from לכיוון dir
func on_shot(from: Vector2, dir: Vector2) -> void:
	if z == null or z.dead:
		return
	var c: Vector2 = z.global_position + Vector2(0, -28.0 * z.sc)
	var rel := c - from
	var along := rel.dot(dir)
	if along < 0.0 or along > 1400.0:
		return
	var off := absf(rel.cross(dir))
	if off > 46.0:
		return
	seen += 1
	dodge_cd = maxf(DODGE_MIN, DODGE_CD0 - 0.12 * float(seen))   # לומד את הקצב שלך
	if state != GINGA or _cd > 0.0 or rel.length() < CLOSE:
		return
	dodges += 1
	state = AU
	_st = AU_T
	_cd = dodge_cd
	z.collision_layer = 0
	var pl := player()
	_au_dir = signf(pl.global_position.x - z.global_position.x) if pl != null and randf() < 0.65 else (1.0 if randf() < 0.5 else -1.0)
	z.velocity = Vector2(_au_dir * 300.0, -230.0)
	Sfx.play("cp_au", z.global_position, -4.0, 0.15, 3)
	if dodges == 3:
		z._popup("IT READS YOUR RHYTHM", Color("ffe080"), 13, -80.0)


func damage_mult(_zone: String, _src: Dictionary) -> float:
	return 1.3 if state == KICK else 1.0


func physics(pl: Node, delta: float) -> bool:
	_st -= delta
	_cd -= delta
	_kick_cd -= delta
	if z.dead:
		z.collision_layer = _layer
		return false
	match state:
		AU:
			if not z.is_on_floor():
				z.velocity.y += z.gravity * delta
			z.move_and_slide()
			if _st <= 0.0:
				state = GINGA
				z.collision_layer = _layer
			return true
		KICK:
			z.velocity.x = move_toward(z.velocity.x, 0.0, 900.0 * delta)
			if not z.is_on_floor():
				z.velocity.y += z.gravity * delta
			z.move_and_slide()
			if _st <= 0.0 and not _kicked:
				_kicked = true
				Sfx.play("cp_kick", z.global_position, 0.0, 0.1, 2)
				if pl != null and not pl.dead and absf(pl.global_position.x - z.global_position.x) < KICK_R + 14.0 and absf(pl.global_position.y - z.global_position.y) < 60.0:
					kicks += 1
					pl.hurt(z.damage, Vector2(signf(pl.global_position.x - z.global_position.x) * 2.4, -1.0))
					pl.velocity.x = signf(pl.global_position.x - z.global_position.x) * 480.0
			if _st <= -0.25:
				state = GINGA
				_kick_cd = KICK_CD
			return true
	if pl != null and not pl.dead and _kick_cd <= 0.0 and absf(pl.global_position.x - z.global_position.x) < KICK_R and absf(pl.global_position.y - z.global_position.y) < 50.0:
		state = KICK
		_st = KICK_T
		_kicked = false
		z._dir = signf(pl.global_position.x - z.global_position.x)
		return true
	return false


# ============================================================
#  ציור: בלי חולצה, מכנסי אבאדה לבנים רחבים, חגורת חבל צהובה. GINGA = מתנדנד ברגליים פתוחות,
#  AU = גלגלון (הגוף מסתובב סביב עצמו), KICK = רגל אחת מסתובבת בקשת רחבה
# ============================================================
func draw() -> bool:
	if state == AU and not z.dead:
		var k := 1.0 - clampf(_st / AU_T, 0.0, 1.0)
		DrawBatch.set_transform(z, Vector2(0, -24.0 * z.sc), _au_dir * k * TAU, Vector2(z._dir * z.wf * z.sc, z.sc))
		_body(Vector2(0, 24), true)
		DrawBatch.set_transform_matrix(z, Transform2D.IDENTITY)
		return true
	begin_draw()
	_body(Vector2.ZERO, false)
	end_draw()
	return true


func _body(o: Vector2, au: bool) -> void:
	var sk := col(z.skin)
	var g: float = sin(z._time * 5.0)
	var hip := o + Vector2(g * 3.0, -20)
	var sh := hip + Vector2(2.0 - g * 2.0, -15)
	var head := sh + Vector2(3.5, -8)
	var lf := o + Vector2(-9.0 + g * 2.0, 0)
	var rf := o + Vector2(9.0 + g * 2.0, 0)
	if state == KICK:   # מיה לואה: רגל אחת בקשת
		var k := clampf(1.0 - _st / KICK_T, 0.0, 1.0)
		rf = hip + Vector2.from_angle(lerpf(PI * 0.6, -PI * 0.25, k)) * 22.0
	if au:
		lf = hip + Vector2(-10, -14)
		rf = hip + Vector2(10, -14)
	z._leg(hip + Vector2(-2, 0), lf, col(z.pants), col(z.pants), sk)
	z._leg(hip + Vector2(2, 0), rf, col(z.pants), col(z.pants), sk)
	DrawBatch.rect(z, Rect2(hip + Vector2(-6, -2), Vector2(12, 4)), col(Color("e0c030")))   # קורדאו
	var ha := sh + Vector2(-8, -4 - g * 4.0) if not au else o + Vector2(-8, -2)
	var hb := sh + Vector2(10, 2 + g * 4.0) if not au else o + Vector2(8, -2)
	z._arm(sh + Vector2(-3, 1), ha, Art.shade(sk, 0.25), Art.shade(sk, 0.25))
	Art.fill_shaded(z, PackedVector2Array([sh + Vector2(-7, -1), sh + Vector2(7, 0), hip + Vector2(6, -2), hip + Vector2(-6, -2)]), sk, 0.15, 0.4)
	for q in 3:   # שרירים / צלעות
		DrawBatch.line(z, sh + Vector2(-4, 4.0 + float(q) * 3.0), sh + Vector2(4, 4.0 + float(q) * 3.0), sk.darkened(0.3), 1.0)
	Art.oval_shaded(z, head, 5.0, 5.6, sk, 0.0)
	face(head, Vector2(3.0, -0.5))
	DrawBatch.colored_polygon(z, Art.ellipse(head + Vector2(-1, -3), 5.0, 3.2, 0.0, 10), col(Color("1a1410")))   # שיער
	if not z.dead:
		DrawBatch.circle(z, head + Vector2(3.0, -0.5), 1.1, Color(1.0, 0.85, 0.4))
	z._arm(sh + Vector2(3, 1), hb, sk, sk)
