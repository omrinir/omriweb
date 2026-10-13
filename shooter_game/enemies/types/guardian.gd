extends "res://enemies/zombie_type.gd"
# ============================================================
#  GUARDIAN (שלב 36, "THE SUMMIT") - לוחם אינקה: מגן עץ מלבני מצויר עם נוצות, אלת כוכב מברונזה (צ'אמפי), קסדת קש.
#  "THEY LEARNED WHERE YOU AIM": המגן מכסה חצי גוף - גבוה (ראש + חזה) או נמוך (מותניים + רגליים).
#    יריות מלפנים בחצי המכוסה = BLOCKED. הוא סופר איפה אתה יורה: LEARN_HITS פגיעות בחצי החשוף ->
#    מזיז את המגן לשם (SWITCH_T) - והחצי השני נחשף. מאחור / מלמעלה (מדרגה) / פיצוץ = נזק מלא.
#    צמוד אליך: מכת מגן שהודפת אחורה.
#  לשנות: LEARN_HITS, SWITCH_T, BASH_CD.
# ============================================================

const SOUNDS := {
	"gd_block": [["S", 700, 650, 0.0, 0.08, 0.0, 30.0, 0.3, 1.0, 0], ["N", 0, 0, 0.0, 0.1, 0.0, 30.0, 0.3, 0.3, 0, 0.6]],
	"gd_switch": [["N", 0, 0, 0.0, 0.15, 0.0, 15.0, 0.3, 0.4, 0, 0.6], ["C", 0, 0, 0.1, 0.05, 0.0, 50.0, 0.3, 1.0, 0]],
	"gd_bash": [["N", 0, 0, 0.0, 0.2, 0.0, 12.0, 0.7, 0.3, 0, 0.5], ["S", 120, 70, 0.0, 0.2, 0.0, 14.0, 0.5, 1.0, 0]],
}

const LEARN_HITS := 2
const SWITCH_T := 0.4
const BASH_CD := 1.6
const SPLIT := -27.0          # הגובה (מקומי) שמפריד בין "גבוה" ל"נמוך"

var guard_high := true
var blocked := 0             # לבדיקות
var switches := 0
var bashes := 0
var _open_hits := 0
var _switch := 0.0
var _bash_cd := 1.0
var _bash_anim := 0.0


func stats() -> Dictionary:
	return {"name": "GUARDIAN", "hp": 36, "walk": 36.0, "chase": 60.0, "damage": 1, "bite_delay": 0.9, "scale": 1.05, "width": 1.15,
		"duck": 0.0, "cover": 0.0, "skin": Color("8a8070"), "shirt": Color("a03a2a"), "pants": Color("3a2a22"), "shoe": Color("5a4430"), "points": 500}


func brain_overrides() -> Dictionary:
	return {"aggression": 0.7}


func can_bite() -> bool:
	return false


func on_damage(amount: int, hit_pos: Vector2, dir: Vector2, src: Dictionary) -> bool:
	var s := str(src.get("source", "bullet"))
	if not (s == "bullet" or s == "melee") or dir.x * z._dir >= 0.0 or _switch > 0.0:
		return true   # מאחור / פיצוץ / באמצע החלפה
	var ly: float = (hit_pos.y - z.global_position.y) / z.sc
	if dir.y > 0.55:   # יורים עליו מלמעלה (ממדרגה) - המגן לא עוזר
		return true
	var high := ly < SPLIT
	if high == guard_high:
		blocked += 1
		Sfx.play("gd_block", hit_pos, -4.0, 0.15, 3)
		Particles.burst(z.get_parent(), hit_pos, "leaf", -dir, 2)
		if randf() < 0.3:
			z._popup("BLOCKED", Color("e0c080"), 11, -70.0)
		return false
	_open_hits += 1   # פגעת בחצי החשוף - הוא לומד
	if _open_hits >= LEARN_HITS:
		_open_hits = 0
		_switch_guard.call_deferred()
	return true


func _switch_guard() -> void:
	if z == null or not is_instance_valid(z) or z.dead:
		return
	guard_high = not guard_high
	switches += 1
	_switch = SWITCH_T
	Sfx.play("gd_switch", z.global_position, -4.0, 0.1, 2)
	z._popup("SHIELD UP" if guard_high else "SHIELD DOWN", Color("e0c080"), 12, -80.0)


func physics(pl: Node, delta: float) -> bool:
	_switch = maxf(_switch - delta, 0.0)
	_bash_cd -= delta
	_bash_anim = maxf(_bash_anim - delta, 0.0)
	if z.dead or pl == null or pl.dead:
		return false
	var d: Vector2 = pl.global_position - z.global_position
	if absf(d.x) < 34.0 * z.sc and absf(d.y) < 50.0 and _bash_cd <= 0.0:   # מכת מגן
		_bash_cd = BASH_CD
		_bash_anim = 0.25
		bashes += 1
		Sfx.play("gd_bash", z.global_position, 0.0, 0.1, 2)
		pl.hurt(z.damage, Vector2(signf(d.x) * 2.2, -0.8))
		pl.velocity.x = signf(d.x) * 420.0
	return false


# ============================================================
#  ציור: טוניקה אדומה עם דוגמת טוקאפו, קסדת קש עם נוצה, אלת כוכב, מגן מלבני מצויר (גבוה / נמוך)
# ============================================================
func draw() -> bool:
	begin_draw()
	var sk := col(z.skin)
	var tun := col(z.shirt)
	var p: float = z._walk_phase
	var f: Array = feet(4.5, 2.5)
	var hip := Vector2(0, -22)
	var sh := Vector2(1, -37)
	var head := sh + Vector2(3.5, -8)
	z._leg(hip + Vector2(-2, 0), f[1], col(Art.shade(z.skin, 0.25)), sk, col(z.shoe))
	z._leg(hip + Vector2(2, 0), f[0], sk, sk, col(z.shoe))
	# אלה ביד האחורית
	var mh := sh + Vector2(-8.0, -10.0) if _bash_anim > 0.0 else sh + Vector2(-7.0 - sin(p) * 2.0, 12.0)
	z._arm(sh + Vector2(-3, 1), mh, Art.shade(sk, 0.25), Art.shade(tun, 0.3))
	z.draw_line(mh, mh + Vector2(-2, -14), col(Color("5a3a22")), 2.0)
	var star := mh + Vector2(-2, -15)
	for q in 6:
		z.draw_line(star, star + Vector2.from_angle(float(q) * TAU / 6.0) * 4.0, col(Color("c89a40")), 2.0)
	Art.fill_shaded(z, PackedVector2Array([sh + Vector2(-8, -1), sh + Vector2(8, 0), hip + Vector2(9, 6), hip + Vector2(-9, 6)]), tun, 0.15, 0.4)   # אונקו
	for q in 3:   # טוקאפו
		for r in 2:
			z.draw_rect(Rect2(sh + Vector2(-6.0 + float(q) * 4.5, 8.0 + float(r) * 5.0), Vector2(3, 3)), col(Color("e0c060") if (q + r) % 2 == 0 else Color("1a1a1a")))
	Art.oval_shaded(z, head, 5.2, 5.8, sk, 0.0)
	z.draw_colored_polygon(Art.ellipse(head + Vector2(0, -3), 6.0, 3.6, 0.0, 10), col(Color("c8a860")))   # קסדת קש
	z.draw_line(head + Vector2(-2, -6), head + Vector2(-6, -14), col(Color("2a8a6a")), 2.0)
	if not z.dead:
		z.draw_circle(head + Vector2(3.0, -0.5), 1.2, Color(1.0, 0.7, 0.3))
	z.draw_line(head + Vector2(1, 3), head + Vector2(5, 3.5), col(Color("2a1a10")), 1.2)
	# המגן
	var sx := 11.0
	var top := -50.0 if guard_high else -34.0
	var bot := -20.0 if guard_high else -2.0
	if _switch > 0.0:   # באמצע ההחלפה: באמצע הדרך
		var k := _switch / SWITCH_T
		var t2 := -34.0 if guard_high else -50.0
		var b2 := -2.0 if guard_high else -20.0
		top = lerpf(top, t2, k)
		bot = lerpf(bot, b2, k)
	if _bash_anim > 0.0:
		sx += 5.0
	z._arm(sh + Vector2(3, 1), Vector2(sx - 1.0, (top + bot) * 0.5), sk, tun)
	var shield := PackedVector2Array([Vector2(sx - 3, top), Vector2(sx + 5, top), Vector2(sx + 5, bot), Vector2(sx - 3, bot)])
	Art.fill_shaded(z, shield, col(Color("7a5030")), 0.15, 0.4, Art.OUTLINE, 1.2)
	var hh := bot - top
	for q in 3:   # פסים מצוירים
		z.draw_rect(Rect2(sx - 2.0, top + 3.0 + float(q) * hh / 3.2, 6.0, 3.0), col([Color("c03a2a"), Color("e0c040"), Color("2a6a9a")][q]))
	for q in 3:   # נוצות בראש המגן
		z.draw_line(Vector2(sx + float(q) * 2.5 - 2.0, top), Vector2(sx + float(q) * 3.0 - 1.0, top - 7.0), col([Color("2a8a6a"), Color("e0b030"), Color("c03a2a")][q]), 1.6)
	end_draw()
	return true
