extends "res://enemies/zombie_type.gd"
# ============================================================
#  STALKER (שלב 6) - הזומבי הראשון שמשתמש במחסות בצורה אקטיבית.
#  צללית: גבוה ורזה, מעיל גשם ארוך ("טרנץ'") וכובע רחב שוליים - צללית נואר.
#  צבעים: מעיל פחם רטוב (פסי ברק של גשם), ידיים חיוורות עם אצבעות ארוכות,
#         ועיניים ירוקות שמחזירות אור מתחת לשוליים של הכובע.
#  תנועה: מתגנב כפוף ממחסה למחסה (שולחנות, ארונות, ארגזים - קבוצת "cover"),
#         תמיד בצד של המחסה שהרחק מהשחקן, כך שאין לשחקן קו ראייה ישיר אליו.
#         אין מחסה? מסתתר מחוץ למסך, מאחורי הגב של השחקן.
#  התקפה: מחכה. ברגע שהשחקן טוען (player.is_reloading()) או נתפס - מבקש "תור"
#         מה-SquadDirector, לוחש בחדות ("!") ומסתער נמוך ומהר, עם זינוק בסוף.
#  אחרי ההתקפה (או כשנפגע במחבוא) - בורח למחסה אחר (לא לאותו אחד!).
#  הוגנות: מציץ מעל המחסה כל כמה שניות (הראש חשוף), נושם בשקט כשהוא קרוב
#          (רמז קולי), וההסתערות מתחילה בלחישה ברורה.
#  צלילים: "stalker_breath" (נשימה צרודה שקטה), "stalker_hiss" (לחישה + קליק לפני הסתערות)
#  לשנות: STRIKE_RANGE (מאיזה מרחק הוא מסתער), ENGAGE (טווח מחסה מהשחקן), stats() למהירות.
# ============================================================

const Brain := preload("res://ai/zombie_brain.gd")

const SOUNDS := {
	"stalker_breath": {"drive": 1.6, "layers": [["N", 0, 0, 0.0, 0.75, 0.3, 2.4, 0.55, 0.16, 0, 0.04], ["V", 74, 66, 0.0, 0.7, 0.3, 2.6, 0.22, 0.6, 0.06, 0, [430, 880, 11]], ["N", 0, 0, 0.9, 0.55, 0.06, 3.6, 0.4, 0.3, 0, 0.12]]},
	"stalker_hiss": {"drive": 2.4, "layers": [["N", 0, 0, 0.0, 0.5, 0.01, 4.5, 0.85, 0.95, 0, 0.5], ["V", 300, 540, 0.0, 0.35, 0.01, 7.0, 0.45, 1.0, 0.05, 0, [1250, 2700, 85]], ["S", 2100, 1900, 0.0, 0.025, 0.0, 120.0, 0.3, 1.0, 0], ["S", 2300, 2100, 0.08, 0.025, 0.0, 120.0, 0.3, 1.0, 0]]},
}

const STRIKE_RANGE := 600.0          # מסתער רק אם השחקן קרוב מזה
const ENGAGE := Vector2(170.0, 560.0)   # מחבוא: לא קרוב מ-170 ולא רחוק מ-560 מהשחקן
const SHADOW_DIST := 560.0           # בלי מחסה: נשאר כל כך רחוק, מאחורי הגב

enum { SEEK, HIDE, STRIKE, RELOCATE }
var state := SEEK
var _spot := 0.0
var _cover: Node = null
var _last_cover: Node = null
var _t := 0.0
var _peek := 0.0
var _peek_cd := 2.0
var _breath := 2.0
var _brain_t := 0.0
var _lunged := false
var strikes := 0                     # לבדיקות: כמה פעמים הסתער
var relocations := 0                 # לבדיקות: כמה פעמים החליף מחבוא


func stats() -> Dictionary:
	return {"name": "STALKER", "hp": 26, "walk": 50.0, "chase": 125.0, "damage": 1, "bite_delay": 0.7, "scale": 1.04, "width": 0.8,
		"duck": 0.0, "cover": 0.0, "skin": Color("aaa6b8"), "shirt": Color("2e2c32"), "pants": Color("1e1c22"), "shoe": Color("121014"), "points": 240}


func brain_overrides() -> Dictionary:
	return {"aggression": -0.2, "cover_usage": 0.3}


func use_brain_movement() -> bool:
	return false   # תנועה משלו: ממחסה למחסה


func can_bite() -> bool:
	return state == STRIKE


func logic(pl: Node, d: Vector2, delta: float, speed: float) -> float:
	_t -= delta
	_peek -= delta
	_peek_cd -= delta
	_breath -= delta
	_brain_t -= delta
	var dist := absf(d.x)
	var zx: float = z.global_position.x
	var br = z.brain
	# המנהיג מת: מבולבל, משוטט לאט
	if br != null and br.confused_t > 0.0:
		if state == STRIKE:
			_end_strike()
		return speed * 0.3
	# מחוץ להתקפה: המוח לא תופס לו "תור" התקפה של אחרים
	if state != STRIKE and _brain_t <= 0.0 and br != null:
		_brain_t = 0.3
		br.command(Brain.WAIT, 0.8)
	match state:
		SEEK, RELOCATE:
			# השחקן בקומה אחרת: מנסה להגיע לקומה שלו (קפיצה / ירידה)
			if absf(d.y) > 80.0 and br != null:
				br._heights(z, pl, d)
				z._dir = signf(d.x) if dist > 60.0 else z._dir
				return speed * 0.7 if dist > 200.0 else 0.0
			if _t <= 0.0 or (_cover != null and not is_instance_valid(_cover)):
				_pick_spot(pl)
			var dx := _spot - zx
			if absf(dx) < 12.0 and z.is_on_floor():
				state = HIDE
				_t = 1.2
				_peek_cd = randf_range(1.2, 2.4)
				return 0.0
			z._dir = signf(dx)
			return speed * (1.35 if state == RELOCATE else 0.85)
		HIDE:
			z._dir = signf(d.x) if d.x != 0.0 else z._dir
			if _cover != null and _peek <= 0.0:
				z._duck_t = maxf(z._duck_t, 0.15)   # כפוף מאחורי המחסה
			if not _still_good(pl):
				state = SEEK
				_t = 0.0
				return 0.0
			var vulnerable: bool = pl.is_reloading() or pl.grabbed_by != null
			if (vulnerable and dist < STRIKE_RANGE and absf(d.y) < 70.0) or (dist < 85.0 and absf(d.y) < 50.0):
				if _try_strike():
					return speed * 1.9
			if _peek_cd <= 0.0 and _cover != null:   # מציץ מעל המחסה (חלון לירות לו בראש)
				_peek_cd = randf_range(1.8, 3.4)
				_peek = 0.7
			if _breath <= 0.0 and dist < 460.0:
				_breath = randf_range(3.5, 5.5)
				Sfx.play("stalker_breath", z.global_position, -9.0, 0.1, 2)
			if _t <= 0.0:   # בודק מדי פעם אם יש מחבוא טוב יותר
				_t = 1.5
				if _cover == null:
					_pick_spot(pl)
					if absf(_spot - zx) > 40.0:
						state = SEEK
			return 0.0
		STRIKE:
			z._dir = signf(d.x) if d.x != 0.0 else z._dir
			if _t <= 0.0:
				_end_strike()
				return 0.0
			if not _lunged and dist < 120.0 and dist > 30.0 and z.is_on_floor():   # זינוק אחרון
				_lunged = true
				z.velocity.y = -330.0
				z.velocity.x = z._dir * 430.0
			return speed * 1.9
	return 0.0


func _try_strike() -> bool:
	var dr := director()
	if dr != null and dr.uses_slots() and not dr.request_slot(z, true):
		return false   # אין תור פנוי (הוגנות: לא יותר מדי תוקפים ביחד)
	state = STRIKE
	strikes += 1
	_t = 2.6
	_lunged = false
	_peek = 0.0
	z._duck_t = 0.0
	if z.brain != null:
		z.brain.command(Brain.ATTACK, 2.8)
	Sfx.play("stalker_hiss", z.global_position, 1.0)
	z._popup("!", Color(0.6, 1.0, 0.5), 20, -74.0)
	return true


func _end_strike() -> void:
	var dr := director()
	if dr != null:
		dr.release_slot(z)
	if z.brain != null:
		z.brain.command(Brain.WAIT, 0.8)
	_relocate()


func _relocate() -> void:
	if _cover != null:
		_last_cover = _cover
	_cover = null
	state = RELOCATE
	relocations += 1
	_t = 0.0


# בוחר מחבוא: הצד הרחוק של מחסה, באותה קומה, בטווח ENGAGE מהשחקן, בלי לעבור לידו
func _pick_spot(pl: Node) -> void:
	_t = 1.5
	var px: float = pl.global_position.x
	var py: float = pl.global_position.y
	var zp: Vector2 = z.global_position
	var best := INF
	var found: Node = null
	var sx := 0.0
	for c in z.get_tree().get_nodes_in_group("cover"):
		if c == _last_cover and state == RELOCATE:
			continue
		var r: Rect2 = c.cover_rect()
		if r.size.y < 28.0 or absf(r.end.y - zp.y) > 14.0 or absf(r.end.y - py) > 40.0:
			continue
		var cx := r.get_center().x
		var hx := r.end.x + 12.0 if px < cx else r.position.x - 12.0
		var pd := absf(hx - px)
		if pd < ENGAGE.x or pd > ENGAGE.y or (hx - px) * (zp.x - px) < 0.0:
			continue
		var dd := absf(hx - zp.x)
		if dd > 720.0:
			continue
		var score := dd + absf(pd - 330.0) * 0.5
		if score < best and z._spot_ok(hx):
			best = score
			found = c
			sx = hx
	if found != null:
		_cover = found
		_spot = sx
		return
	# אין מחסה: מחכה מחוץ לטווח הראייה, בצד שלו
	_cover = null
	var side := signf(zp.x - px)
	if side == 0.0:
		side = -1.0
	_spot = clampf(px + side * SHADOW_DIST, 40.0, z.world_w - 40.0)


func _still_good(pl: Node) -> bool:
	var px: float = pl.global_position.x
	var zx: float = z.global_position.x
	if absf(px - zx) < 70.0:
		return false
	if _cover == null:   # מחבוא "צל": השחקן התקרב / פונה אליו מקרוב -> מתרחק
		return absf(px - zx) > SHADOW_DIST * 0.7 or (pl._face() != signf(zx - px) and absf(px - zx) > 300.0)
	if not is_instance_valid(_cover):
		return false
	var cx: float = (_cover.cover_rect() as Rect2).get_center().x
	return signf(px - cx) != signf(_spot - cx)   # המחסה עדיין בינו לבין השחקן


func on_bite(_pl: Node) -> void:
	if state == STRIKE:
		_end_strike()


func on_damage(_amount: int, _hit_pos: Vector2, _dir: Vector2, _src: Dictionary) -> bool:
	if state == HIDE or state == SEEK:   # נחשף: בורח למחבוא אחר
		_relocate()
		Sfx.play("stalker_hiss", z.global_position, -6.0, 0.2, 2)
	return true


func on_death() -> void:
	var dr := director()
	if dr != null:
		dr.release_slot(z)


# ---- ציור: מעיל ארוך + כובע רחב שוליים ----
func draw() -> bool:
	begin_draw()
	var k: float = clampf(z._crouch_k, 0.0, 1.0)
	var striking: bool = state == STRIKE and not z.dead
	var p: float = z._walk_phase
	var sk := col(z.skin)
	var coat := col(z.shirt)
	var coat_d := col(Art.shade(z.shirt, 0.35))
	var f: Array = feet(6.0, 3.0)
	var lean := 9.0 if striking else (3.0 + 2.0 * k)
	var hip := Vector2(-1.0, -24.0 + k * 9.0 + absf(sin(p)) * 1.0)
	var sh := Vector2(lean, -44.0 + k * 15.0)
	var head := sh + Vector2(4.0 + (3.0 if striking else 0.0), -8.0)
	if _peek > 0.0 and k < 0.5:
		head += Vector2(-1.0, -1.5)
	# רגל אחורית
	z._leg(hip + Vector2(-2, 0), f[1], col(Art.shade(z.pants, 0.3)), col(Art.shade(z.skin, 0.3)), col(z.shoe))
	# יד אחורית (ארוכה, חיוורת)
	var bh := sh + (Vector2(20, 2) if striking else Vector2(6, 16 - k * 4.0))
	_long_arm(sh + Vector2(-2, 2), bh, col(Art.shade(z.skin, 0.25)), coat_d)
	z._leg(hip + Vector2(2, 0), f[0], col(z.pants), sk, col(z.shoe))
	# המעיל: מהכתפיים עד הברכיים, מתנפנף מאחור
	var flap := sin(z._time * (9.0 if striking else 2.5)) * (5.0 if striking else 1.5)
	var hem_y := minf(hip.y + 16.0, -5.0)
	var coat_pts := PackedVector2Array([sh + Vector2(-6, -1), sh + Vector2(5, -1), hip + Vector2(7, 2), Vector2(hip.x + 8.0, hem_y),
		Vector2(hip.x + 1.0, hem_y + 2.0), Vector2(hip.x - 7.0 - flap, hem_y + 1.0), Vector2(hip.x - 10.0 - flap * 1.4, hem_y - 3.0), hip + Vector2(-7, 0)])
	Art.fill_shaded(z, coat_pts, coat, 0.12, 0.4)
	# חגורה + פסי גשם מבריקים
	z.draw_line(hip + Vector2(-6, -4), hip + Vector2(7, -3), col(Color("16141a")), 2.0)
	for i in 3:
		var a: Vector2 = sh.lerp(hip, 0.2 + float(i) * 0.25) + Vector2(-3.0 + float(i), 0.0)
		z.draw_line(a, a + Vector2(-1.0, 5.0), Color(0.75, 0.85, 1.0, 0.25), 1.0)
	# צווארון מורם
	Art.fill(z, PackedVector2Array([sh + Vector2(-5, 0), sh + Vector2(-3, -7), sh + Vector2(1, -3), sh + Vector2(5, -6), sh + Vector2(5, 1)]), coat_d, Art.OUTLINE, 1.0)
	# ראש צנום
	Art.oval_shaded(z, head + Vector2(0, 1), 5.0, 6.5, sk, 0.1)
	z.draw_line(head + Vector2(1, 3), head + Vector2(5, 4), Color(0.15, 0.0, 0.05), 1.2)
	# כובע רחב שוליים
	var brim_tilt := -0.12 if striking else 0.05
	Art.fill_shaded(z, PackedVector2Array([head + Vector2(-5, -5), head + Vector2(-4.5, -9.5), head + Vector2(-1, -10.5), head + Vector2(1, -9.2), head + Vector2(4, -10.5), head + Vector2(6, -9), head + Vector2(6.5, -5)]), col(Color("221f26")), 0.2, 0.3)
	Art.oval(z, head + Vector2(1.0, -4.8), 12.5, 2.0, col(Color("19171c")), brim_tilt)
	z.draw_line(head + Vector2(-4.8, -6.4), head + Vector2(6.4, -6.4), col(Color("6a2a2c")), 1.6)   # סרט אדום כהה
	# עיניים ירוקות שמחזירות אור (חזקות יותר כשמציץ / מסתער)
	var glow_k := 1.0 if (striking or _peek > 0.0) else 0.55
	var eye := Color(0.55, 1.0, 0.45)
	for e in [Vector2(2.5, -2.0), Vector2(5.0, -1.8)]:
		Art.glow(z, head + e, 3.2, Color(eye, 0.6 * glow_k))
		z.draw_circle(head + e, 0.9, Color(eye, glow_k))
	# יד קדמית: מושטת עם אצבעות ארוכות (מסתער) / נשענת על המחסה
	var fh := sh + (Vector2(24, -2) if striking else (Vector2(13, 4) if k > 0.5 else Vector2(9, 15)))
	_long_arm(sh + Vector2(2, 1), fh, sk, coat)
	end_draw()
	return true


func _long_arm(shoulder: Vector2, hand: Vector2, sk: Color, sleeve: Color) -> void:
	var elbow := Art.joint(shoulder, hand, 10.0, 11.0, -1.0)
	var cuff := shoulder.lerp(elbow, 0.5).lerp(elbow.lerp(hand, 0.5), 0.8)
	Art.limb(z, PackedVector2Array([shoulder, elbow, cuff]), 4.8, sleeve)
	Art.limb(z, PackedVector2Array([cuff, hand]), 2.6, sk)
	var dvec := (hand - elbow).normalized()
	for i in 4:   # אצבעות ארוכות ודקות
		var a := dvec.rotated(-0.5 + float(i) * 0.33)
		z.draw_line(hand, hand + a * 6.0, col(Art.shade(z.skin, 0.1)), 1.0, true)
