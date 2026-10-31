extends "res://enemies/stationary_boss.gd"
# ============================================================
#  GOALKEEPER (הבוס של שלב 39, "THE STADIUM") - בוס נייח: שוער זומבי ענק בשער של המרקנה. חולצה ירוקה עם 1, כובע מצחייה,
#  כפפות ענק. לא זז מהקו.
#  התקפות (stationary_boss.gd):
#    punt  - בעיטה: 2 כדורי אש ישרים ונמוכים (מקדים אותך אחרי פספוסים)
#    throw - זורק כדור בקשת (מתפוצץ קטן). 3 מעל המחסה כשלמד שאתה מתחבא
#    pound - צמוד אליו: שוער שקופץ עליך (מכת קרקע)
#  "THEY LEARN - הוא קורא את הכוונת שלך": הכוונת שלך על הראש שלו יותר מ-SAVE_T שניות -> מרים את הכפפות לראש (SAVE_HOLD):
#    יריות בראש = SAVED. אז: מכוונים מהר ויורים ("סנאפ"), או יורים כשהוא בועט / זורק (הכפפות עסוקות).
#  לשנות: PUNT_CD, THROW_CD, SAVE_T, SAVE_HOLD.
# ============================================================

const SOUNDS := {
	"gk_punt": [["N", 0, 0, 0.0, 0.15, 0.0, 20.0, 0.8, 0.3, 0], ["S", 160, 70, 0.0, 0.15, 0.0, 20.0, 0.6, 1.0, 0]],
	"gk_save": [["N", 0, 0, 0.0, 0.12, 0.0, 25.0, 0.5, 0.4, 0, 0.5], ["S", 500, 400, 0.0, 0.1, 0.0, 30.0, 0.2, 1.0, 0]],
	"gk_roar": {"drive": 1.5, "layers": [["V", 90, 70, 0.0, 0.9, 0.1, 1.5, 0.6, 1.0, 0.05, 0, [350, 800, 4]]]},
}

const PUNT_CD := 2.5
const THROW_CD := 3.8
const BALL_V := 600.0
const SAVE_T := 0.6
const SAVE_HOLD := 1.6

var saves := 0               # לבדיקות
var guards := 0
var _punt_cd := 1.4
var _throw_cd := 3.0
var _aim_t := 0.0
var _save := 0.0


func stats() -> Dictionary:
	return {"name": "GOALKEEPER", "hp": 380, "walk": 0.0, "chase": 0.0, "damage": 2, "bite_delay": 1.0, "scale": 2.7, "width": 1.5,
		"duck": 0.0, "cover": 0.0, "skin": Color("7a8a6c"), "shirt": Color("2a9a4a"), "pants": Color("1a1a1e"), "shoe": Color("1a1a1a"),
		"points": 2600, "boss": true, "boss_name": "THE GOALKEEPER - DON'T LET HIM READ YOUR AIM"}


func eye() -> Vector2:   # הרגל / הידיים
	return z.global_position + Vector2(z._dir * 14.0 * z.wf, -30.0) * z.sc


func weak_rect() -> Rect2:
	return Rect2(-3, -66, 18, 18)


func saving() -> bool:
	return _save > 0.0 and winding == ""


func on_damage(amount: int, hit_pos: Vector2, dir: Vector2, src: Dictionary) -> bool:
	var s := str(src.get("source", "bullet"))
	if saving() and (s == "bullet" or s == "melee") and in_weak(hit_pos):
		saves += 1
		Sfx.play("gk_save", hit_pos, 0.0, 0.1, 3)
		Particles.burst(z.get_parent(), hit_pos, "spark", -dir, 4)
		if saves % 3 == 1:
			z._popup("SAVED!", Color("60ff90"), 16, -60.0 - 70.0 * z.sc)
		return false
	return super.on_damage(amount, hit_pos, dir, src)


func think(pl: Node, delta: float) -> void:
	_punt_cd -= delta
	_throw_cd -= delta
	_save -= delta
	# קורא את הכוונת שלך: מכוון לראש שלו? סופר
	var hr := weak_rect().grow(10.0)
	var l: Vector2 = (pl.aim_end - z.global_position) / z.sc
	l.x *= z._dir / maxf(float(z.wf), 0.1)
	if hr.has_point(l):
		_aim_t += delta
		if _aim_t > SAVE_T and _save <= 0.0:
			_save = SAVE_HOLD
			guards += 1
			if guards == 1:
				z._popup("HE READS YOUR AIM", Color("60ff90"), 15, -60.0 - 70.0 * z.sc)
	else:
		_aim_t = maxf(_aim_t - delta * 2.0, 0.0)
	var dx: float = absf(pl.global_position.x - z.global_position.x)
	if dx > 1200.0:
		return
	if _throw_cd <= 0.0 and (learned_lob or randf() < 0.4):
		wind("throw", 0.8)
		return
	if _punt_cd <= 0.0:
		wind("punt", 0.6)


func wind(name: String, t: float) -> void:
	super.wind(name, t)
	if name == "throw":
		Sfx.play("gk_roar", z.global_position, 0.0, 0.05, 2)


func attack(name: String, pl: Node) -> void:
	match name:
		"pound":
			do_pound(pl)
		"punt":
			_punt_cd = PUNT_CD
			Sfx.play("gk_punt", eye(), 2.0, 0.1, 2)
			for q in 2:
				fire_shot(eye(), aim_point(pl, BALL_V) + Vector2(0, float(q) * 18.0 - 6.0), BALL_V * (1.0 + 0.1 * float(q)), 1, "ball", Color(1.0, 0.55, 0.15), 8.0)
		"throw":
			_throw_cd = THROW_CD
			var n := 3 if learned_lob and not _vis else 1
			for q in n:
				var tx: float = pl.global_position.x + (float(q) - float(n - 1) * 0.5) * 80.0 + pl.velocity.x * 0.4 * lead
				fire_lob(z.global_position + Vector2(z._dir * 6.0, -76.0) * z.sc, Vector2(tx, pl.global_position.y), 1.1 + 0.12 * float(q), 1, "football", 55.0, Color(1, 1, 1), 10.0)


# ============================================================
#  ציור: חולצת שוער ירוקה עם 1, כובע מצחייה, כפפות ענק (לראש כשהוא "קורא" אותך), רגל לבעיטה
# ============================================================
func draw() -> bool:
	begin_draw()
	var sk := col(z.skin)
	var shirt := col(z.shirt)
	var k := wind_k()
	var hip := Vector2(0, -24)
	var sh := Vector2(2, -46)
	var head := sh + Vector2(5, -12)
	var glove := col(Color("f0f0f0"))
	# רגליים (בעיטה: רגל קדמית מתנופפת)
	var kick := Vector2(10, 0)
	if winding == "punt":
		kick = Vector2(-14, -6).lerp(Vector2(18, -14), k)
	z._leg(hip + Vector2(-4, 0), Vector2(-7, 0), col(Color("1a1a1e")), sk, col(z.shoe))
	z._leg(hip + Vector2(4, 0), kick, col(Color("1a1a1e")), sk, col(z.shoe))
	DrawBatch.rect(z, Rect2(hip + Vector2(-10, -2), Vector2(20, 9)), col(z.pants))
	# יד אחורית
	var hb := sh + Vector2(-14, 6)
	if saving():
		hb = head + Vector2(-2, -2)
	elif winding == "throw":
		hb = sh + Vector2(-8, -24).lerp(Vector2(10, -28), k)
	z._arm(sh + Vector2(-8, 2), hb, Art.shade(sk, 0.25), Art.shade(shirt, 0.3))
	DrawBatch.circle(z, hb, 5.0, glove)
	if winding == "throw":   # הכדור ביד
		DrawBatch.circle(z, hb + Vector2(0, -6), 4.0, Color(0.97, 0.97, 0.97))
		DrawBatch.circle(z, hb + Vector2(1, -6), 1.2, Color(0.1, 0.1, 0.1))
	Art.fill_shaded(z, PackedVector2Array([sh + Vector2(-12, -3), sh + Vector2(12, -2), hip + Vector2(11, 2), hip + Vector2(-11, 2)]), shirt, 0.12, 0.4)
	for q in 3:   # דוגמה
		DrawBatch.line(z, sh + Vector2(-11, 6.0 + float(q) * 6.0), sh + Vector2(11, 4.0 + float(q) * 6.0), col(Color("1e7a3a")), 1.5)
	DrawBatch.line(z, sh + Vector2(1, 4), sh + Vector2(1, 14), col(Color("f0f0f0")), 1.8)   # 1 (סימטרי - נראה טוב גם כשהוא הפוך)
	DrawBatch.line(z, sh + Vector2(-1.5, 14), sh + Vector2(3.5, 14), col(Color("f0f0f0")), 1.4)
	Art.oval_shaded(z, head, 7.0, 7.5, sk, 0.0)
	DrawBatch.colored_polygon(z, Art.ellipse(head + Vector2(0, -4), 7.4, 3.6, 0.0, 12), col(Color("1a1a1a")))   # כובע
	DrawBatch.rect(z, Rect2(head + Vector2(3, -4), Vector2(9, 2)), col(Color("1a1a1a")))
	if not z.dead:
		DrawBatch.circle(z, head + Vector2(4.0, -0.5), 1.4, Color(1.0, 0.8, 0.35))
	DrawBatch.line(z, head + Vector2(1, 4), head + Vector2(6, 4.5), col(Color("2a1a10")), 1.4)
	# יד קדמית: כפפה
	var hf := sh + Vector2(16, 8)
	if saving():
		hf = head + Vector2(8, 0)
	z._arm(sh + Vector2(8, 2), hf, sk, shirt)
	DrawBatch.circle(z, hf, 6.0, glove)
	DrawBatch.arc(z, hf, 6.0, 0.0, TAU, 12, col(Color("2a9a4a")), 1.2)
	if saving() and not z.dead:
		Art.glow(z, head, 14.0, Color(0.4, 1.0, 0.6, 0.25))
	end_draw()
	return true
