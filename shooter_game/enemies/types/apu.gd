extends "res://enemies/stationary_boss.gd"
# ============================================================
#  APU (הבוס של שלב 36, "THE SUMMIT" - סוף האנדים) - בוס נייח: רוח ההר. ענק של סלע ושלג שיושב על כס האבן בפסגה,
#  לבוש אונקו אדום-זהב, ועל פניו מסכת שמש מזהב (אינטי) = נקודת התורפה. ביד אחת מטה זהב, בשנייה מקלע (וארקה).
#  התקפות (stationary_boss.gd):
#    sling     - 2 אבני מקלע מהירות (מקדים אותך אחרי פספוסים)
#    rocks     - 2 סלעים בקשת שמתפוצצים (3 מעל המחסה כשלמד שאתה מתחבא)
#    lightning - מרים את המטה: ברק עליך + ברק שני בצד שאליו אתה בורח (Strike מ-effects/s36_decor.gd)
#    pound     - צמוד אליו: מכת קרקע
#  "THEY LEARN": אחרי כל ברק הוא בודק לאיזה צד ברחת. ברחת לאותו צד DODGE_LEARN פעמים -> הברק השני כבר מחכה שם.
#  לשנות: SLING_CD, ROCK_CD, BOLT_CD, DODGE_LEARN.
# ============================================================

const Decor := preload("res://effects/s36_decor.gd")

const SOUNDS := {
	"ap_sling": [["N", 0, 0, 0.0, 0.25, 0.0, 10.0, 0.3, 0.6, 0, 0.6], ["S", 300, 500, 0.0, 0.25, 0.0, 10.0, 0.15, 1.0, 0]],
	"ap_call": {"drive": 1.5, "layers": [["V", 70, 90, 0.0, 1.2, 0.2, 1.0, 0.6, 1.0, 0.05, 0, [250, 600, 3]], ["S", 140, 180, 0.0, 1.2, 0.2, 1.0, 0.2, 1.0, 0.05]]},
	"ap_rock": [["N", 0, 0, 0.0, 0.3, 0.0, 8.0, 0.6, 0.2, 0, 0.5], ["S", 90, 60, 0.0, 0.25, 0.0, 10.0, 0.4, 1.0, 0]],
}

const SLING_CD := 2.4
const ROCK_CD := 4.0
const BOLT_CD := 5.0
const SLING_V := 560.0
const DODGE_LEARN := 2

var bolts := 0               # לבדיקות
var dodge := {-1: 0, 1: 0}   # לאיזה צד ברחת מהברק
var knows_side := 0          # 0 = עוד לא למד, -1/1 = הצד שהוא מחכה לך בו
var hits := 0                # פגיעות ברק
var _sling_cd := 1.4
var _rock_cd := 3.0
var _bolt_cd := 2.5
var _check := []             # [זמן, x של הברק]
var _clock := 0.0


func stats() -> Dictionary:
	return {"name": "APU", "hp": 400, "walk": 0.0, "chase": 0.0, "damage": 2, "bite_delay": 1.0, "scale": 3.1, "width": 1.6,
		"duck": 0.0, "cover": 0.0, "skin": Color("6a6270"), "shirt": Color("a02a24"), "pants": Color("3a3440"), "shoe": Color("2a2630"),
		"points": 2400, "boss": true, "boss_name": "APU, SPIRIT OF THE MOUNTAIN - SHOOT THE SUN MASK"}


func eye() -> Vector2:   # יד המקלע
	return z.global_position + Vector2(z._dir * 16.0 * z.wf, -64.0) * z.sc


func staff_top() -> Vector2:
	return z.global_position + Vector2(z._dir * 18.0 * z.wf, -100.0) * z.sc


func weak_rect() -> Rect2:
	return Rect2(-4, -84, 20, 22)


func think(pl: Node, delta: float) -> void:
	_clock += delta
	_sling_cd -= delta
	_rock_cd -= delta
	_bolt_cd -= delta
	# בודק לאן ברחת מהברק
	for c in _check.duplicate():
		if _clock >= float(c[0]):
			_check.erase(c)
			var side := int(signf(pl.global_position.x - float(c[1])))
			if side != 0 and absf(pl.global_position.x - float(c[1])) > 30.0:
				dodge[side] = int(dodge[side]) + 1
				if knows_side == 0 and int(dodge[side]) >= DODGE_LEARN and int(dodge[side]) > int(dodge[-side]):
					knows_side = side
					z._popup("IT KNOWS WHICH WAY YOU RUN", Color("ffd070"), 15, -60.0 - 100.0 * z.sc)
	var dx: float = absf(pl.global_position.x - z.global_position.x)
	if dx > 1200.0:
		return
	if learned_lob and _rock_cd <= 0.0 and (not _vis or randf() < 0.4):
		wind("rocks", 0.8)
		return
	if _bolt_cd <= 0.0 and dx > 200.0:
		wind("lightning", 1.1)
		return
	if _rock_cd <= 0.0 and randf() < 0.4:
		wind("rocks", 0.8)
		return
	if _sling_cd <= 0.0:
		wind("sling", 0.6)


func wind(name: String, t: float) -> void:
	super.wind(name, t)
	if name == "lightning":
		Sfx.play("ap_call", staff_top(), 2.0, 0.05, 2)


func attack(name: String, pl: Node) -> void:
	match name:
		"pound":
			do_pound(pl)
		"sling":
			_sling_cd = SLING_CD
			Sfx.play("ap_sling", eye(), 0.0, 0.1, 2)
			for q in 2:
				var tgt := aim_point(pl, SLING_V) + Vector2(0, float(q) * 14.0 - 7.0)
				fire_shot(eye(), tgt, SLING_V * (1.0 + 0.08 * float(q)), 1, "stone", Color(0.6, 0.55, 0.5), 6.0)
		"rocks":
			_rock_cd = ROCK_CD
			Sfx.play("ap_rock", eye(), 0.0, 0.1, 2)
			var n := 3 if learned_lob and not _vis else 2
			for q in n:
				var tx: float = pl.global_position.x + (float(q) - float(n - 1) * 0.5) * 90.0 + pl.velocity.x * 0.3 * lead
				fire_lob(eye(), Vector2(tx, pl.global_position.y), 1.1 + 0.12 * float(q), 1, "rock", 60.0, Color(0.6, 0.5, 0.4), 12.0)
		"lightning":
			_bolt_cd = BOLT_CD
			bolts += 1
			var x0: float = pl.global_position.x
			_strike(x0, pl.global_position.y, 1.0)
			_check.append([_clock + 1.6, x0])
			var side := knows_side if knows_side != 0 else (1 if randf() < 0.5 else -1)
			_strike(x0 + float(side) * 130.0, pl.global_position.y, 1.45)
			if knows_side != 0:   # למד: גם ברק שלישי רחוק יותר באותו צד
				_strike(x0 + float(side) * 250.0, pl.global_position.y, 1.8)


func _strike(x: float, y_hint: float, warn: float) -> void:
	var q := PhysicsRayQueryParameters2D.create(Vector2(x, y_hint - 200.0), Vector2(x, z.global_position.y + 30.0), 1 | 16)
	var hit: Dictionary = z.get_world_2d().direct_space_state.intersect_ray(q)
	var y: float = z.global_position.y if hit.is_empty() else float(hit.position.y)
	Decor.Storm.strike(z.get_parent(), Vector2(x, y), warn, self)


# ============================================================
#  ציור: גבעת סלע ושלג (הכס), גוף סלע עם כתפיים מושלגות כמו פסגות, אונקו אדום עם טוקאפו זהב,
#  מסכת שמש מזהב עם קרניים, כתר אדום (מסקאפאיצ'ה), מטה זהב ביד אחת, מקלע מסתובב בשנייה
# ============================================================
func draw() -> bool:
	begin_draw()
	var sk := col(z.skin)
	var k := wind_k()
	var hip := Vector2(0, -16)
	var sh := Vector2(2, -54)
	var head := sh + Vector2(5, -18)
	var gold := Color("e0b030")
	# יד אחורית: המקלע
	var sling_h := sh + Vector2(-14, -14)
	z._arm(sh + Vector2(-10, 2), sling_h, Art.shade(sk, 0.3), Art.shade(sk, 0.25))
	var sa: float = z._time * (4.0 + (14.0 * k if winding == "sling" else 0.0))
	var sp := sling_h + Vector2.from_angle(sa) * 9.0
	z.draw_line(sling_h, sp, col(Color("c8b080")), 1.0)
	z.draw_circle(sp, 2.0, col(Color("7a7068")))
	# גוף
	var torso := PackedVector2Array([sh + Vector2(-16, -2), sh + Vector2(-6, -8), sh + Vector2(14, -6), sh + Vector2(18, 4), hip + Vector2(16, 0), hip + Vector2(-16, 0)])
	Art.fill_shaded(z, torso, sk, 0.2, 0.45)
	z.draw_colored_polygon(PackedVector2Array([sh + Vector2(-16, -2), sh + Vector2(-11, -12), sh + Vector2(-5, -8)]), col(Color("e8eaf2")))   # כתפיים מושלגות (פסגות)
	z.draw_colored_polygon(PackedVector2Array([sh + Vector2(11, -6), sh + Vector2(16, -13), sh + Vector2(19, 3)]), col(Color("e8eaf2")))
	var unku := PackedVector2Array([sh + Vector2(-12, 2), sh + Vector2(13, 2), hip + Vector2(14, -2), hip + Vector2(-14, -2)])
	Art.fill_shaded(z, unku, col(z.shirt), 0.15, 0.4)
	for q in 4:   # רצועת טוקאפו
		for r in 2:
			z.draw_rect(Rect2(-9.0 + float(q) * 5.0, -38.0 + float(r) * 4.5, 3.5, 3.5), col(gold if (q + r) % 2 == 0 else Color("1a1a1a")))
	z.draw_line(sh + Vector2(-12, 2), sh + Vector2(13, 2), col(gold), 1.5)
	# ראש: מסכת שמש
	if not z.dead:
		Art.glow(z, head, 16.0 + 10.0 * k, Color(1.0, 0.8, 0.3, 0.2 + 0.3 * k))
	for q in 14:   # קרניים משוננות
		var a := float(q) / 14.0 * TAU
		var r0 := 9.0
		var r1 := 13.0 + float(q % 2) * 2.0
		z.draw_colored_polygon(PackedVector2Array([head + Vector2.from_angle(a - 0.16) * r0, head + Vector2.from_angle(a) * r1, head + Vector2.from_angle(a + 0.16) * r0]), col(gold.darkened(0.1)))
	Art.oval_shaded(z, head, 9.5, 9.5, col(gold), 0.0)
	z.draw_arc(head, 7.5, 0.0, TAU, 18, col(gold.darkened(0.3)), 1.0)
	var ec := Color(1.0, 0.95, 0.8) if winding == "lightning" else Color(0.95, 0.85, 0.5)
	if not z.dead:
		for e in [Vector2(-3, -1), Vector2(4, -1)]:
			z.draw_rect(Rect2(head + e - Vector2(2, 1), Vector2(4, 2.4)), col(Color("2a1a10")))
			z.draw_circle(head + e, 0.9 + 0.8 * k, ec)
	z.draw_rect(Rect2(head + Vector2(-3, 4), Vector2(7, 2)), col(Color("2a1a10")))   # פה
	z.draw_colored_polygon(PackedVector2Array([head + Vector2(-1, 0), head + Vector2(1, 0), head + Vector2(0, 3)]), col(gold.darkened(0.25)))
	# מסקאפאיצ'ה: גדיל אדום על המצח + נוצות
	z.draw_rect(Rect2(head + Vector2(-6, -12), Vector2(12, 3)), col(Color("c02a20")))
	for q in 3:
		z.draw_line(head + Vector2(-3.0 + float(q) * 3.0, -12), head + Vector2(-5.0 + float(q) * 4.0, -21), col([Color("2a2a2a"), Color("e8e8e8"), Color("2a2a2a")][q]), 2.0)
	# יד קדמית: מטה זהב (מורם בזמן ברק)
	var hf := sh + Vector2(18, -8)
	if winding == "lightning":
		hf = sh + Vector2(14, -10).lerp(Vector2(16, -38), k)
	elif winding == "rocks":
		hf = sh + Vector2(10, -24)
	z._arm(sh + Vector2(12, 2), hf, sk, Art.shade(sk, 0.1))
	z.draw_line(hf + Vector2(0, 14), hf + Vector2(2, -26), col(gold.darkened(0.2)), 2.0)
	var top := hf + Vector2(2, -28)
	z.draw_circle(top, 3.5, col(gold))
	if winding == "lightning" and not z.dead:
		Art.glow(z, top, 8.0 + 14.0 * k, Color(0.8, 0.9, 1.0, 0.5 * k))
		for q in 3:
			var a: float = z._time * 30.0 + float(q) * 2.1
			z.draw_line(top, top + Vector2.from_angle(a) * (6.0 + 6.0 * k), Color(0.9, 0.95, 1.0, 0.8), 1.0)
	if winding == "rocks":   # סלע ביד
		z.draw_circle(hf + Vector2(0, -5), 4.0 * (0.5 + 0.5 * k), col(Color("6a6058")))
	# הכס: גבעת סלע עם שלג
	var mound := PackedVector2Array([Vector2(-30, 0), Vector2(-26, -10), Vector2(-14, -18), Vector2(0, -15), Vector2(14, -19), Vector2(26, -11), Vector2(30, 0)])
	Art.fill_shaded(z, mound, col(Color("4a4448")), 0.2, 0.4, Art.OUTLINE, 1.2)
	z.draw_colored_polygon(PackedVector2Array([Vector2(-26, -10), Vector2(-14, -18), Vector2(0, -15), Vector2(-6, -12), Vector2(-16, -14)]), col(Color("e8eaf2")))
	z.draw_colored_polygon(PackedVector2Array([Vector2(14, -19), Vector2(26, -11), Vector2(18, -12)]), col(Color("e8eaf2")))
	for q in 3:   # אבנים מצולעות בבסיס
		z.draw_line(Vector2(-20.0 + float(q) * 16.0, -6), Vector2(-12.0 + float(q) * 16.0, -6), col(Color("2e2a2e")), 1.0)
	end_draw()
	return true
