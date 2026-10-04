extends "res://enemies/zombie_type.gd"
# ============================================================
#  BLOODGATE (שלב 10, צפון-מזרח) - "קנגסיירו" מת: כובע עור חצי-ירח עם כוכבים,
#    חגורות כדורים מוצלבות, חולצת כותנה מוכתמת, ורידים אדומים זוהרים, דם מטפטף כל הזמן.
#  היכולת: הדם שלו הוא פורטל.
#    יורים בו מרחוק (יותר מ-PORTAL_MIN) -> גוש דם עף מהפצע בקשת לכיוון השחקן ונוחת על הריצפה
#    (בין הזומבי לשחקן, קרוב לשחקן) -> שלולית-פורטל. הזומבי נבלע בשלולית של עצמו
#    ויוצא מהשלולית שנחתה - קרוב אליך.
#  הוגן: רואים את הגוש עף ונוחת, השלולית פועמת ועמוד אור אדום עולה ממנה (EMERGE_WARN)
#    לפני שהוא יוצא, ובזמן היציאה הוא לא נושך. בתוך הפורטל אי אפשר לפגוע בו (אבל גם הוא לא תוקף).
#  יורים בו מקרוב -> אין פורטל (רק דם). מכאן הטקטיקה: לחסל אותו מקרוב, או לזוז מהשלולית שנחתה.
#  צלילים: "bg_splat" (נחיתה), "bg_sink" (נבלע), "bg_rise" (יוצא).
#  לשנות: PORTAL_MIN, PORTAL_CD, LAND_NEAR (כמה קרוב לשחקן הדם נוחת), EMERGE_WARN.
# ============================================================

const Hz := preload("res://environment/s10_hazards.gd")

const SOUNDS := {
	"bg_splat": [["N", 0, 0, 0.0, 0.3, 0.0, 10.0, 0.7, 0.25, 0], ["S", 140, 60, 0.0, 0.2, 0.0, 14.0, 0.6, 1.0, 0]],
	"bg_sink": [["S", 260, 50, 0.0, 0.45, 0.02, 4.0, 0.5, 1.0, 0.3], ["N", 0, 0, 0.0, 0.45, 0.05, 4.0, 0.35, 0.2, 0]],
	"bg_rise": [["S", 60, 300, 0.0, 0.4, 0.05, 3.5, 0.5, 1.0, 0.3], ["N", 0, 0, 0.05, 0.35, 0.05, 5.0, 0.35, 0.22, 0], ["W", 90, 110, 0.0, 0.35, 0.05, 4.0, 0.2, 0.3, 0.2]],
}

const PORTAL_MIN := 260.0          # פחות מזה = אין פורטל
const PORTAL_CD := Vector2(4.0, 6.0)
const LAND_NEAR := Vector2(100.0, 170.0)
const SINK_T := 0.4
const EMERGE_WARN := 0.45
const RISE_T := 0.45

enum { NORMAL, SINK, HIDDEN, RISE }
var state := NORMAL
var portals_made := 0              # לבדיקות
var teleports := 0
var _st := 0.0
var _cd := 0.0
var _entry: Node2D = null
var _exit: Node2D = null
var _drips := []
var _pending := []          # [מאיפה, איפה השחקן, צד] - פורטל שמחכה לפריים הבא (אם הוא שרד את הירייה)


func stats() -> Dictionary:
	return {"name": "BLOODGATE", "hp": 32, "walk": 46.0, "chase": 98.0, "damage": 1, "bite_delay": 0.8, "scale": 1.0, "width": 1.0,
		"duck": 0.15, "cover": 0.2, "skin": Color("a08a80"), "shirt": Color("c8b89a"), "pants": Color("5a4430"), "shoe": Color("3a2818"), "points": 320}


func brain_overrides() -> Dictionary:
	return {"aggression": 0.15}


func setup() -> void:
	_cd = randf_range(0.5, 1.5)


func physics(_pl: Node, delta: float) -> bool:
	_cd -= delta
	_tick_drips(delta)
	if state == NORMAL:
		if not _pending.is_empty():   # שרד את הירייה -> פורטל
			var pd := _pending
			_pending = []
			if z.is_on_floor():
				_launch(pd[0], pd[1], pd[2])
				return true
		return false
	_st -= delta
	z.velocity = Vector2.ZERO
	match state:
		SINK:
			if _st <= 0.0:
				state = HIDDEN
				_st = 2.5   # ביטחון: אם הדם לא נחת - חוזר מהכניסה
				z.collision_layer = 0
		HIDDEN:
			if _exit != null and is_instance_valid(_exit):
				if _exit.t >= EMERGE_WARN:   # השלולית פעמה מספיק זמן (אזהרה) -> יוצא
					_emerge(_exit)
			elif _st <= 0.0:
				_emerge(_entry)
		RISE:
			if _st <= 0.0:
				state = NORMAL
				z._attack_t = maxf(z._attack_t, 0.3)
	return true


func can_bite() -> bool:
	return state == NORMAL


# נפגע: מרחוק -> שולח גוש דם ונבלע בשלולית
func on_damage(_amount: int, hit_pos: Vector2, _dir: Vector2, _src: Dictionary) -> bool:
	if state != NORMAL:
		return false
	var pl := player()
	if pl == null or _cd > 0.0 or not z.is_on_floor() or not _pending.is_empty():
		return true
	var pp: Vector2 = pl.global_position
	var dx: float = pp.x - z.global_position.x
	if absf(dx) < PORTAL_MIN or absf(pp.y - z.global_position.y) > 260.0:
		return true
	_cd = randf_range(PORTAL_CD.x, PORTAL_CD.y)
	_pending = [hit_pos, pp, signf(dx)]   # הנזק עוד לא חושב - מחליטים בפריים הבא אם הוא בחיים
	return true


func _launch(from: Vector2, pp: Vector2, side: float) -> void:
	var tx := pp.x - side * randf_range(LAND_NEAR.x, LAND_NEAR.y)
	var target := Vector2(tx, pp.y)
	var t := clampf(absf(target.x - from.x) / 620.0, 0.45, 0.95)
	var g := Hz.BloodGlob.new()
	g.velocity = Vector2((target.x - from.x) / t, (target.y - from.y - 0.5 * Hz.BloodGlob.GRAV * t * t) / t)
	g.owner_mod = self
	z.get_parent().add_child(g)
	g.global_position = from
	portals_made += 1
	# נבלע בשלולית של עצמו
	_entry = Hz.BloodPortal.new()
	_entry.life = 3.5
	z.get_parent().add_child(_entry)
	_entry.global_position = z.global_position
	_exit = null
	state = SINK
	_st = SINK_T
	z._dir = side
	Sfx.play("bg_sink", z.global_position, 0.0, 0.1, 3)
	z._voice("zscream", 0.5, 2.0)


# הגוש נחת (נקרא מ-BloodGlob)
func portal_ready(p: Node2D) -> void:
	if z == null or not is_instance_valid(z) or z.dead or state == NORMAL:
		p.life = 1.2
		return
	_exit = p


func portal_failed() -> void:
	_exit = null


func _emerge(p: Node2D) -> void:
	if p != null and is_instance_valid(p):
		z.global_position = p.global_position
		p.used = true
		p.life = minf(p.life, 1.2)
		if p != _entry:
			teleports += 1
	if _entry != null and is_instance_valid(_entry):
		_entry.close()
	z.collision_layer = 4
	state = RISE
	_st = RISE_T
	var pl := player()
	if pl != null:
		z._dir = signf(pl.global_position.x - z.global_position.x) if pl.global_position.x != z.global_position.x else z._dir
	Sfx.play("bg_rise", z.global_position, 0.0, 0.1, 3)
	Particles.burst(z.get_parent(), z.global_position + Vector2(0, -10), "hit", Vector2.UP, 10)


func on_death() -> void:
	if state != NORMAL:
		z.collision_layer = 0
	for p in [_entry, _exit]:
		if p != null and is_instance_valid(p):
			p.close()


func _tick_drips(delta: float) -> void:
	if not z.dead and state == NORMAL and randf() < delta * 3.0:
		_drips.append([Vector2(randf_range(-6.0, 8.0), randf_range(-40.0, -24.0)), 0.0])
	for q in _drips:
		q[1] += delta
		q[0].y += delta * 60.0 * (1.0 + q[1] * 3.0)
	_drips = _drips.filter(func(q: Array) -> bool: return q[1] < 0.6 and q[0].y < 0.0)


# ============================================================
#  ציור
# ============================================================
func draw() -> bool:
	if state == HIDDEN:
		return true
	var k := 1.0   # כמה מהגוף מעל הדם
	if state == SINK:
		k = clampf(_st / SINK_T, 0.0, 1.0)
	elif state == RISE:
		k = 1.0 - clampf(_st / RISE_T, 0.0, 1.0)
	begin_draw(k > 0.9)
	if k < 1.0:   # נמס לתוך השלולית: מתכווץ לגובה ומתרחב קצת
		var s := Vector2(z._dir * z.wf * z.sc * (1.0 + (1.0 - k) * 0.5), z.sc * maxf(k, 0.05))
		z.draw_set_transform(Vector2.ZERO, sin(z._time * 30.0) * 0.06 * (1.0 - k), s)
	var sk := col(z.skin)
	var shirt := col(z.shirt)
	var p: float = z._walk_phase
	var f: Array = feet(5.0, 2.5)
	var hip := Vector2(0.0, -22.0 + absf(sin(p)) * 1.2)
	var sh := Vector2(3.0, -38.0)
	var head := sh + Vector2(4.0, -8.0)
	var blood := Color(0.55, 0.02, 0.05)
	z._leg(hip + Vector2(-1.5, 0), f[1], col(Art.shade(z.pants, 0.25)), col(Art.shade(z.skin, 0.2)), col(z.shoe))
	z._leg(hip + Vector2(1.5, 0), f[0], col(z.pants), sk, col(z.shoe))
	z._arm(sh + Vector2(-3, 2), sh + Vector2(-1.0 - sin(p) * 4.0, 16.0), col(Art.shade(z.skin, 0.25)), col(Art.shade(z.shirt, 0.3)))
	# חולצת כותנה מוכתמת בדם
	var body := PackedVector2Array([sh + Vector2(-7, -2), sh + Vector2(7, -1), hip + Vector2(7, -1), hip + Vector2(5, 3), hip + Vector2(-6, 3), sh + Vector2(-8, 5)])
	Art.fill_shaded(z, body, shirt, 0.15, 0.35)
	Art.oval(z, sh + Vector2(2, 9), 4.5, 6.0, col(blood), 0.4, Art.NONE)
	Art.oval(z, hip + Vector2(-2, -5), 3.0, 2.5, col(blood), 0.0, Art.NONE)
	# חגורות כדורים מוצלבות (כמו הקנגסיירוס)
	for side in [-1.0, 1.0]:
		var a := sh + Vector2(-6.0 * side, 0.0)
		var b := hip + Vector2(6.0 * side, -1.0)
		z.draw_line(a, b, col(Color("5a3a1a")), 3.2, true)
		for i in 4:
			var q := a.lerp(b, 0.15 + float(i) * 0.22)
			z.draw_circle(q, 0.9, col(Color("d8b040")))
	z.draw_line(hip + Vector2(-7, -1), hip + Vector2(7, -2), col(Color("3a2414")), 2.4, true)   # חגורה
	# ורידים זוהרים
	if not z.dead:
		var glow_k := 0.5 + 0.5 * sin(z._time * 5.0)
		for v in [[sh + Vector2(-2, 3), sh + Vector2(2, 10), sh + Vector2(-1, 15)], [sh + Vector2(4, 2), sh + Vector2(6, 8)]]:
			z.draw_polyline(PackedVector2Array(v), Color(1.0, 0.15, 0.2, 0.45 + 0.35 * glow_k), 1.2)
	# ראש + כובע עור חצי-ירח
	Art.oval_shaded(z, head, 5.8, 6.4, sk, 0.1)
	z.draw_line(head + Vector2(1, 3), head + Vector2(6, 4), col(Color("3a0a0a")), 1.4)   # פה
	z.draw_line(head + Vector2(3, 4), head + Vector2(3.5, 8), col(blood), 1.0)            # דם מהפה
	var eye := head + Vector2(3.0, -1.0)
	if not z.dead:
		Art.glow(z, eye, 4.0, Color(1.0, 0.15, 0.15, 0.7))
	z.draw_circle(eye, 1.1, Color(1.0, 0.3, 0.3) if not z.dead else Color("2a1a1a"))
	var hat := PackedVector2Array()
	for i in 13:   # השוליים המורמים: חצי-ירח
		var u := float(i) / 12.0
		var a := lerpf(PI + 0.25, TAU - 0.25, u)
		hat.append(head + Vector2(cos(a) * 13.0, -4.0 + sin(a) * 6.0 - absf(cos(a)) * 5.0))
	hat.append(head + Vector2(7, -5))
	hat.append(head + Vector2(-7, -5))
	Art.fill_shaded(z, hat, col(Color("7a5230")), 0.2, 0.35)
	Art.fill(z, PackedVector2Array([head + Vector2(-5, -5), head + Vector2(-4, -11), head + Vector2(4, -11), head + Vector2(5, -5)]), col(Color("6a4426")))
	for sx in [-6.0, 0.0, 6.0]:   # כוכבים על השוליים
		var c := head + Vector2(sx, -11.5 + absf(sx) * 0.25)
		z.draw_circle(c, 1.4, col(Color("e0c060")))
	# יד קדמית: מושטת קדימה
	var hand := sh + Vector2(13.0, 6.0 + sin(p) * 2.0)
	z._arm(sh + Vector2(2, 2), hand, sk, shirt)
	Art.disc(z, hand + Vector2(1, 1), 1.6, col(blood), Art.NONE)
	for q in _drips:   # טיפות דם נופלות
		z.draw_circle(q[0], 1.2, blood)
	end_draw()
	return true
