extends "res://enemies/zombie_type.gd"
# ============================================================
#  PUPPETEER (שלב 50, "TANGO CEMETERY") - הבוקור: מכשף זומבי רזה וגבוה במגבעת וצבע-גולגולת על הפנים,
#  מחזיק צלב-בובנאי (מוט עץ בצורת צלב). השראה: הבוקור מהאיטי ששולט בזומבים, ומריונטות.
#  "THEY LEARNED TO PULL THE STRINGS":
#    STRING  - כל STRING_CD שניות שולח חוט סגול זוהר לזומבי קרוב (STRING_R), עד MAX_STRINGS בובות.
#              בובה = מהירה יותר (PUPPET_SPEED).
#    JERK    - כל JERK_CD שניות מושך בצלב (אזהרה: הצלב נמשך אחורה והחוטים מתלקחים) -> כל הבובות קופצות עליך ביחד.
#    REVIVE  - בובה שמתה כשהיא קשורה: הוא מושך אותה חזרה פעם אחת ("DANCE AGAIN!"). REVIVES פעמים לכל פאפטיר.
#    שומר מרחק (HOLD_R, תנועה משלו) - נשאר מאחורי הבובות. בובה שהתרחקה מעבר ל-STRING_MAX - החוט מחליק ממנה.
#  לנטרל: לירות בחוט עצמו (החלק האמצעי שלו הוא גוף פגיע קטן - StringCut) או להרוג אותו ->
#         כל החוטים נקרעים והבובות המומות (SNAP_STUN).
#  לומד (main meta "pp_cuts"): אחרי CUT_LEARN חוטים שנחתכו בשלב - קושר חוטים כפולים (צריך לחתוך פעמיים)
#         ומחבר מחדש מהר יותר (STRING_CD_LEARN). "HE TIES TWO STRINGS NOW".
#  בוס (chase_range > 600): "THE BOKOR" - ענק, עד BOSS_STRINGS בובות, מקים בובות מהאדמה (SUMMON_CD),
#         ומצליף בחוט (WHIP) כשאתה קרוב - הצלב מורם (אזהרה WHIP_WIND) ואז שוט סגול לאורך WHIP_R.
#  לשנות: MAX_STRINGS, STRING_R, STRING_MAX, STRING_CD, PUPPET_SPEED, JERK_CD, JERK_V, REVIVES, CUT_LEARN, WHIP_*.
# ============================================================

const SOUNDS := {
	"pp_string": [["S", 900, 1400, 0.0, 0.25, 0.01, 8.0, 0.18, 1.0, 0.04], ["S", 1800, 2600, 0.0, 0.2, 0.01, 10.0, 0.06, 1.0, 0.0]],
	"pp_snap": [["N", 0, 0, 0.0, 0.08, 0.0, 40.0, 0.5, 0.9, 0, 0.9], ["S", 1600, 400, 0.0, 0.12, 0.0, 25.0, 0.3, 1.0, 0.0]],
	"pp_jerk": [["S", 220, 160, 0.0, 0.25, 0.0, 10.0, 0.35, 1.0, 0.1], ["N", 0, 0, 0.0, 0.2, 0.0, 14.0, 0.3, 0.5, 0, 0.5]],
	"pp_laugh": [["V", 180, 140, 0.0, 0.9, 0.05, 2.5, 0.4, 1.0, 0.06, 0, [500, 1100, 7]], ["S", 360, 300, 0.1, 0.8, 0.05, 3.0, 0.1, 1.0, 0.1]],
	"pp_whip": [["N", 0, 0, 0.0, 0.18, 0.0, 22.0, 0.6, 0.8, 0, 0.7], ["S", 2400, 600, 0.0, 0.15, 0.0, 20.0, 0.25, 1.0, 0.0]],
}

const MAX_STRINGS := 3
const BOSS_STRINGS := 6
const STRING_R := 440.0
const STRING_MAX := 600.0     # בובה שהתרחקה יותר מזה - החוט מחליק ממנה (בלי לספור כחיתוך)
const STRING_CD := 3.0
const HOLD_R := 310.0         # באיזה מרחק ממך הוא עומד
const BOSS_HOLD_R := 150.0
const STRING_CD_LEARN := 1.4
const GROW_T := 0.35          # החוט "נורה" מהצלב לבובה
const PUPPET_SPEED := 1.35
const JERK_CD := 2.6
const JERK_WIND := 0.4
const JERK_V := Vector2(380.0, -220.0)
const REVIVES := 1
const BOSS_REVIVES := 3
const REVIVE_DELAY := 1.1
const SNAP_STUN := 1.5
const CUT_LEARN := 3
const WHIP_R := 230.0
const WHIP_WIND := 0.5
const WHIP_CD := 2.2
const SUMMON_CD := 6.0

# לבדיקות
var strung := 0
var cuts := 0
var jerks := 0
var revives := 0
var whips := 0
var whip_hits := 0
var summons := 0

var strings: Array = []       # [{p: puppet, t: גדילה, n: כמה חוטים (1/2), body, dead_t}]
var _layer: Node2D = null
var _scd := 0.8
var _jcd := JERK_CD
var _jwind := 0.0
var _wcd := 1.0
var _wwind := 0.0
var _wflash := 0.0
var _wdir := 1.0
var _sumcd := 2.0
var _revives_left := 0
var _learn_said := false


func _boss() -> bool:
	return z != null and float(z.chase_range) > 600.0


func stats() -> Dictionary:
	if _boss():
		return {"name": "PUPPETEER", "hp": 240, "walk": 30.0, "chase": 58.0, "damage": 2, "bite_delay": 1.2, "scale": 1.7, "width": 1.0,
			"duck": 0.0, "cover": 0.0, "skin": Color("d8d2c4"), "shirt": Color("1c1620"), "pants": Color("221c26"), "shoe": Color("121014"),
			"points": 1700, "boss": true, "boss_name": "THE BOKOR"}
	return {"name": "PUPPETEER", "hp": 45, "walk": 34.0, "chase": 62.0, "damage": 1, "bite_delay": 1.0, "scale": 1.12, "width": 0.85,
		"duck": 0.1, "cover": 0.5, "skin": Color("d0cabc"), "shirt": Color("241c28"), "pants": Color("2a2230"), "shoe": Color("141016"), "points": 700}


func brain_overrides() -> Dictionary:
	if _boss():
		return {"aggression": 0.35, "keep_range": 170.0}
	return {"aggression": 0.1, "keep_range": 260.0, "retreat_probability": 0.15}


func setup() -> void:
	_revives_left = BOSS_REVIVES if _boss() else REVIVES
	_layer = StringLayer.new()
	_layer.owner_t = self
	z.get_parent().add_child.call_deferred(_layer)


func can_bite() -> bool:
	return _wwind <= 0.0


func max_strings() -> int:
	return BOSS_STRINGS if _boss() else MAX_STRINGS


func learned() -> bool:
	var m: Node = z.get_parent()
	return m != null and int(m.get_meta("pp_cuts", 0)) >= CUT_LEARN


# נקודת הצלב (גלובלית) - משם יוצאים החוטים
func bar_point() -> Vector2:
	var up := -78.0
	if _jwind > 0.0:
		up = -84.0
	if _wwind > 0.0:
		up = -92.0
	return z.global_position + Vector2(z._dir * (17.0 if _jwind <= 0.0 else 8.0), up) * z.sc


static func head_point(p: Node) -> Vector2:
	return p.global_position + Vector2(0, -54.0 * float(p.sc))


# תנועה משלו (לא המוח): נשאר במרחק HOLD_R ממך - מאחורי הבובות. קרוב מדי -> נסוג. הבוס מתקרב יותר (BOSS_HOLD_R)
func use_brain_movement() -> bool:
	return false


func logic(pl: Node, d: Vector2, _delta: float, speed: float) -> float:
	if _jwind > 0.0 or _wwind > 0.0:
		return speed * 0.15
	if pl == null or pl.dead:
		return speed
	var want := BOSS_HOLD_R if _boss() else HOLD_R
	var ad := absf(d.x)
	var face: float = signf(d.x) if d.x != 0.0 else float(z._dir)
	if ad > want + 60.0:
		z._dir = face
		return speed
	if ad < want - 90.0 and not _boss():
		z._dir = -face
		return speed * 0.85
	z._dir = face
	return 0.0


# החוטים, ה-JERK וההצלפה מתעדכנים כל פריים (גם כשהוא לא רודף / בורח / במחסה). התנועה - המוח
func physics(pl: Node, delta: float) -> bool:
	_tick(pl, delta)
	return false


func _tick(pl: Node, delta: float) -> void:
	_scd -= delta
	_jcd -= delta
	_wcd -= delta
	_sumcd -= delta
	_wflash -= delta
	_update_strings(delta)
	if z.dead:
		return
	var has_pl: bool = pl != null and not pl.dead
	# הולך אחרי הבובות שלו (גם אם עוד לא ראה אותך)
	if has_pl and (_alive_count() > 0 or z._noticed) and absf(pl.global_position.x - z.global_position.x) < STRING_MAX + 300.0:
		z._alert_t = maxf(float(z._alert_t), 0.5)
	# חוט חדש
	if _scd <= 0.0:
		_scd = 0.3
		if _alive_count() < max_strings():
			var c := _find_puppet()
			if c != null:
				_attach(c)
				_scd = STRING_CD_LEARN if learned() else STRING_CD
	# JERK: מושך בצלב -> כל הבובות קופצות
	if _jwind > 0.0:
		_jwind -= delta
		if _jwind <= 0.0:
			_jerk(pl)
	elif has_pl and _jcd <= 0.0 and _wwind <= 0.0:
		_jcd = 0.5
		var near := 0
		for s in strings:
			if s.t >= 1.0 and _ok(s.p) and absf(s.p.global_position.x - pl.global_position.x) < 360.0:
				near += 1
		if near > 0:
			_jwind = JERK_WIND
			_jcd = JERK_CD * (0.8 if learned() else 1.0)
			Sfx.play("pp_jerk", z.global_position, 0.0, 0.1, 2, 0.9)
	# בוס: הצלפה בחוט ומקים בובות
	if _boss() and has_pl:
		var dd: Vector2 = pl.global_position - z.global_position
		if _wwind > 0.0:
			_wwind -= delta
			if _wwind <= 0.0:
				_whip(pl)
		elif _wcd <= 0.0 and _jwind <= 0.0 and absf(dd.x) < WHIP_R and absf(dd.y) < 120.0:
			_wwind = WHIP_WIND
			_wdir = signf(dd.x) if dd.x != 0.0 else z._dir
			z._dir = _wdir
			Sfx.play("pp_string", z.global_position, 2.0, 0.05, 2, 0.6)
		if _sumcd <= 0.0 and z._chasing:
			_sumcd = SUMMON_CD
			if _alive_count() < 2:
				_summon(pl)


func _ok(p) -> bool:
	return p != null and is_instance_valid(p) and not p.dead


func _alive_count() -> int:
	var n := 0
	for s in strings:
		if _ok(s.p):
			n += 1
	return n


func _find_puppet() -> Node:
	var best: Node = null
	var bd := STRING_R
	for o in z.get_tree().get_nodes_in_group("zombies"):
		if o == z or not _ok(o) or o.is_boss() or o.dormant or o.has_meta("puppet") or o.type_mod != null:
			continue
		if o.is_queued_for_deletion():
			continue
		var dist: float = o.global_position.distance_to(z.global_position)
		if dist < bd:
			bd = dist
			best = o
	return best


func _attach(p: Node, instant := false) -> void:
	p.set_meta("puppet", z)
	p.set_meta("pp_mul", p._speed_mul)
	p._speed_mul = float(p._speed_mul) * PUPPET_SPEED
	p._alert_t = maxf(float(p._alert_t), 6.0)
	var s := {"p": p, "t": 1.0 if instant else 0.0, "n": 2 if learned() else 1, "body": null, "dead_t": 0.0, "revived": p.has_meta("pp_revived")}
	var b := StringCut.new()
	b.owner_t = self
	b.s = s
	b.collision_layer = 4   # כדורים פוגעים בו, אף אחד לא נתקע בו
	b.collision_mask = 0
	var cs := CollisionShape2D.new()
	var sh := RectangleShape2D.new()
	sh.size = Vector2(10, 8)
	cs.shape = sh
	b.add_child(cs)
	s.body = b
	z.get_parent().add_child(b)
	b.global_position = Vector2(-9999, -9999)
	strings.append(s)
	strung += 1
	Sfx.play("pp_string", z.global_position, -2.0, 0.08, 3)
	if s.n == 2 and not _learn_said:
		_learn_said = true
		z._popup("HE TIES TWO STRINGS NOW", Color("d090ff"), 13, -110.0 * z.sc)


func _free_string(s: Dictionary, restore := true) -> void:
	var p = s.p
	if restore and p != null and is_instance_valid(p):
		if p.has_meta("pp_mul"):
			p._speed_mul = float(p.get_meta("pp_mul"))
			p.remove_meta("pp_mul")
		if p.has_meta("puppet"):
			p.remove_meta("puppet")
	if s.body != null and is_instance_valid(s.body):
		s.body.queue_free()
	s.body = null


func _update_strings(delta: float) -> void:
	var bp := bar_point()
	var keep: Array = []
	for s in strings:
		var p = s.p
		if p == null or not is_instance_valid(p) or p.is_queued_for_deletion():
			_free_string(s, false)
			continue
		if s.t < 1.0:
			s.t = minf(s.t + delta / GROW_T, 1.0)
		if not p.dead and p.global_position.distance_to(z.global_position) > STRING_MAX * (1.4 if _boss() else 1.0):
			_free_string(s)
			continue
		if p.dead:
			# בובה מתה: מושך אותה חזרה פעם אחת
			if z.dead or s.revived or _revives_left <= 0 or not p.is_in_group("corpses"):
				_free_string(s, false)
				continue
			s.dead_t += delta
			p._dead_t = minf(float(p._dead_t), 1.0)   # הגופה לא נעלמת
			if s.dead_t >= REVIVE_DELAY:
				_free_string(s, false)
				_revive(p)
				continue
		# הגוף הפגיע: באמצע החוט (לא ליד הבובה - כדי שיריות בבובה לא "ייתפסו")
		if s.body != null:
			var hp := head_point(p)
			if s.t >= 1.0:
				var mid := bp.lerp(hp, 0.5)
				s.body.global_position = mid
				s.body.rotation = (hp - bp).angle()
				var sh: RectangleShape2D = s.body.get_child(0).shape
				sh.size = Vector2(maxf(bp.distance_to(hp) * 0.45, 12.0), 10.0)
			else:
				s.body.global_position = Vector2(-9999, -9999)
		keep.append(s)
	strings = keep


# ירייה בחוט
func cut(s: Dictionary, hit_pos: Vector2) -> void:
	if not strings.has(s):
		return
	s.n -= 1
	cuts += 1
	var m: Node = z.get_parent()
	var total := int(m.get_meta("pp_cuts", 0)) + 1
	m.set_meta("pp_cuts", total)
	Sfx.play("pp_snap", hit_pos, 1.0, 0.1, 3)
	Particles.burst(m, hit_pos, "spark", Vector2.UP, 6)
	if s.n > 0:
		z._popup("ONE MORE", Color("d090ff"), 11, -90.0 * z.sc)
		return
	strings.erase(s)
	_free_string(s)
	if _ok(s.p):
		s.p.stagger(0.7)
		s.p._popup("CUT!", Color("e0c0ff"), 13, -80.0)
	if total == CUT_LEARN:
		z._popup("HE TIES TWO STRINGS NOW", Color("d090ff"), 13, -110.0 * z.sc)
		_learn_said = true


func _jerk(pl: Node) -> void:
	if pl == null or pl.dead:
		return
	jerks += 1
	Sfx.play("pp_jerk", z.global_position, 3.0, 0.05, 2, 1.3)
	for s in strings:
		var p = s.p
		if s.t < 1.0 or not _ok(p):
			continue
		var dx: float = pl.global_position.x - p.global_position.x
		if absf(dx) > 420.0:
			continue
		p._dir = signf(dx) if dx != 0.0 else p._dir
		p.velocity = Vector2(p._dir * minf(JERK_V.x, absf(dx) * 2.4 + 120.0), JERK_V.y)
		p._alert_t = maxf(float(p._alert_t), 4.0)


func _whip(pl: Node) -> void:
	whips += 1
	_wcd = WHIP_CD
	_wflash = 0.22
	Sfx.play("pp_whip", z.global_position, 3.0, 0.05, 2)
	var dd: Vector2 = pl.global_position - z.global_position
	if signf(dd.x) == _wdir and absf(dd.x) < WHIP_R + 10.0 and absf(dd.y) < 110.0 and pl._roll_t <= 0.0:
		whip_hits += 1
		pl.hurt(z.damage, Vector2(_wdir * 1.7, -0.7))


func _summon(pl: Node) -> void:
	var main: Node = z.get_parent()
	for i in 2:
		var x: float = z.global_position.x + (float(i) * 2.0 - 1.0) * randf_range(90.0, 150.0)
		if pl != null:
			x = clampf(x, 60.0, float(main.level_w) - 300.0)
		var nz: Node = main._spawn_zombie(x, z.global_position.y, 0)
		if nz == null:
			continue
		summons += 1
		nz.velocity = Vector2(0, -260.0)
		nz._alert_t = 8.0
		Particles.burst(main, Vector2(x, z.global_position.y - 6.0), "smoke", Vector2.UP, 8)
		_attach(nz, true)
	z._popup("RISE, MY DOLLS", Color("d090ff"), 15, -130.0 * z.sc)
	Sfx.play("pp_laugh", z.global_position, 3.0, 0.05, 2, 0.8)


func _revive(c: Node) -> void:
	var R := preload("res://enemies/types/reviver.gd")
	var pos: Vector2 = c.global_position
	var main: Node = z.get_parent()
	var nz: Node = main._spawn_zombie(pos.x, pos.y, R._kind_for(int(c.kind)))
	if nz == null:
		return
	_revives_left -= 1
	revives += 1
	nz.set_meta("revived", true)
	nz.set_meta("pp_revived", true)
	nz.velocity = Vector2(0, -260.0)   # נמשך למעלה בחוט
	Particles.burst(main, pos + Vector2(0, -20), "spark", Vector2.UP, 10)
	nz._popup("DANCE AGAIN!", Color("d090ff"), 15, -80.0)
	Sfx.play("pp_laugh", z.global_position, 1.0, 0.05, 2)
	if c.get("_rag") != null:
		c._rag.release()
	c.remove_from_group("corpses")
	c.queue_free()
	_attach(nz, true)


func on_death() -> void:
	# כל החוטים נקרעים, הבובות המומות
	var any := false
	for s in strings:
		if _ok(s.p):
			s.p.stagger(SNAP_STUN)
			s.p._popup("SNAP", Color("e0c0ff"), 12, -80.0)
			any = true
		_free_string(s)
	strings.clear()
	if any:
		Sfx.play("pp_snap", z.global_position, 3.0, 0.05, 2, 0.7)
	if _layer != null and is_instance_valid(_layer):
		_layer.fade = true


# ============================================================
#  גוף פגיע באמצע כל חוט (שכבה 4 כמו זומבי, mask 0 - אף אחד לא נתקע בו)
# ============================================================
class StringCut extends StaticBody2D:
	var owner_t = null
	var s = null

	func hit_by_bullet(p: Vector2, _n: Vector2, _d: Vector2) -> void:
		if owner_t != null and owner_t.z != null and is_instance_valid(owner_t.z) and s != null:
			owner_t.cut(s, p)


# ============================================================
#  ציור החוטים (בקואורדינטות עולם): מהצלב לראש ולידיים של כל בובה, סגול זוהר, מתוח ורוטט.
#  בזמן JERK מתלקחים. גם שוט החוט של הבוס.
# ============================================================
class StringLayer extends Node2D:
	var owner_t = null
	var fade := false
	var _t := 0.0

	func _ready() -> void:
		z_index = 5

	func _process(delta: float) -> void:
		_t += delta
		if owner_t == null or owner_t.z == null or not is_instance_valid(owner_t.z):
			queue_free()
			return
		if fade:
			modulate.a -= delta * 3.0
			if modulate.a <= 0.0:
				queue_free()
				return
		if Art.on_screen(self, owner_t.z.global_position, 500.0):
			queue_redraw()

	func _draw() -> void:
		var o = owner_t
		var zz = o.z
		var bp: Vector2 = o.bar_point()
		var hot: float = 1.0 if o._jwind > 0.0 else 0.0
		var base := Color(0.75, 0.4, 1.0)
		for s in o.strings:
			var p = s.p
			if p == null or not is_instance_valid(p):
				continue
			var hp: Vector2 = o.head_point(p)
			var ps: float = float(p.sc)
			var ends := [hp, p.global_position + Vector2(-12.0 * ps, -34.0 * ps), p.global_position + Vector2(12.0 * ps, -34.0 * ps)]
			for e in 3:
				var to: Vector2 = ends[e]
				var tip := bp.lerp(to, float(s.t))
				var w := 1.6 if e == 0 else 0.9
				var a := 0.85 if e == 0 else 0.45
				var strands: int = int(s.n) if e == 0 else 1
				for k in strands:
					var off := Vector2(0, float(k) * 3.0)
					var pts := PackedVector2Array()
					for q in 9:
						var u := float(q) / 8.0
						var pt: Vector2 = bp.lerp(tip, u) + off * sin(u * PI)
						pt.y += sin(u * PI) * (8.0 - 6.0 * hot) + sin(_t * 9.0 + u * 7.0 + float(e)) * 1.2 * sin(u * PI)
						pts.append(pt)
					draw_polyline(pts, Color(base.r, base.g, base.b, 0.18 + 0.25 * hot), w + 3.0)
					draw_polyline(pts, Color(0.9, 0.75, 1.0, a), w)
				if e == 0 and s.t >= 1.0:
					draw_circle(tip, 2.5, Color(0.9, 0.7, 1.0, 0.8))
		if zz.dead:
			return
		# הצלב זוהר
		Art.glow(self, bp, 16.0 + 10.0 * hot, Color(0.7, 0.35, 1.0, 0.18 + 0.2 * hot))
		# שוט החוט (בוס)
		if o._wwind > 0.0:
			var k: float = 1.0 - o._wwind / WHIP_WIND
			draw_arc(bp, 20.0 + 10.0 * k, 0.0, TAU * k, 16, Color(0.9, 0.6, 1.0, 0.7), 2.0)
		if o._wflash > 0.0:
			var a2: float = o._wflash / 0.22
			var pts2 := PackedVector2Array()
			var gp: Vector2 = zz.global_position
			for q in 13:
				var u := float(q) / 12.0
				pts2.append(Vector2(bp.x + o._wdir * WHIP_R * u, lerpf(bp.y, gp.y - 30.0, u) + sin(u * 11.0 + _t * 30.0) * 10.0 * u))
			draw_polyline(pts2, Color(0.75, 0.4, 1.0, 0.3 * a2), 8.0)
			draw_polyline(pts2, Color(0.95, 0.85, 1.0, a2), 2.2)


# ============================================================
#  ציור: גבוה ורזה, מעיל-זנב שחור, מגבעת עם סרט סגול, פנים צבועות כגולגולת (באמצע: וודו),
#  יד קדמית מורמת מחזיקה צלב-בובנאי (מוט + מוט רוחב), יד אחורית "מנגנת" באוויר.
# ============================================================
func draw() -> bool:
	begin_draw()
	var sk := col(z.skin)
	var coat := col(z.shirt)
	var p: float = z._walk_phase
	var f: Array = feet(4.0, 2.0)
	var hip := Vector2(0, -26)
	var sh := Vector2(2, -46)
	var head := sh + Vector2(2, -8)
	var lean := 0.0
	if _jwind > 0.0:
		lean = -3.0
	elif _wwind > 0.0:
		lean = -4.0
	sh.x += lean
	head.x += lean
	# זנבות המעיל מאחור
	var sway: float = sin(z._time * 2.0) * 1.5 + (-z.velocity.x * z._dir) * 0.02
	Art.fill(z, PackedVector2Array([hip + Vector2(-8, -4), hip + Vector2(-1, -2), hip + Vector2(-4.0 + sway, 16), hip + Vector2(-9.0 + sway, 19), hip + Vector2(-12.0 + sway, 12)]), col(Art.shade(z.shirt, 0.2)))
	# רגליים ארוכות ורזות
	z._leg(hip + Vector2(-2, 0), f[1] * Vector2(1.0, 1.0), col(Art.shade(z.pants, 0.25)), sk, col(z.shoe))
	z._leg(hip + Vector2(2, 0), f[0], col(z.pants), sk, col(z.shoe))
	# יד אחורית: אצבעות "מנגנות" (בזמן JERK - נמשכת אחורה)
	var hb := sh + Vector2(-6.0 + sin(z._time * 3.0) * 2.0, 14.0 + cos(z._time * 3.0) * 2.0)
	if _jwind > 0.0:
		hb = sh + Vector2(-14, 2)
	_arm(sh + Vector2(-3, 1), hb, true)
	for q in 3:
		z.draw_line(hb, hb + Vector2(-2.0 + float(q) * 2.0, 4.0 + sin(z._time * 8.0 + float(q)) * 1.5), col(sk), 0.9)
	# גוף: מעיל-זנב צר עם חזייה סגולה
	var torso := PackedVector2Array([sh + Vector2(-7, -1), sh + Vector2(7, 0), hip + Vector2(6, 0), hip + Vector2(-7, -2)])
	Art.fill_shaded(z, torso, coat, 0.1, 0.35)
	z.draw_colored_polygon(PackedVector2Array([sh + Vector2(0, 1), sh + Vector2(5, 1), hip + Vector2(3, -4), hip + Vector2(0, -6)]), col(Color("4a2a5a")))
	z.draw_line(sh + Vector2(1, 1), hip + Vector2(0, -6), col(Color("0c0a0e")), 1.0)
	for q in 3:   # כפתורי עצם
		z.draw_circle(sh.lerp(hip, 0.25 + float(q) * 0.2) + Vector2(3.5, -1), 0.9, col(Color("e0d8c4")))
	# צווארון גבוה
	Art.fill(z, PackedVector2Array([sh + Vector2(-6, 0), sh + Vector2(-5, -6), sh + Vector2(-1, -2), sh + Vector2(4, -6), sh + Vector2(6, 0)]), col(Art.shade(z.shirt, -0.1)), Art.OUTLINE, 0.9)
	_head(head, sk)
	# יד קדמית מורמת עם הצלב
	var bar_l: Vector2 = (bar_point() - z.global_position) / z.sc
	bar_l.x *= z._dir / z.wf
	var hf := bar_l + Vector2(-1, 8)
	_arm(sh + Vector2(4, 1), hf, false)
	_cross(bar_l)
	end_draw()
	return true


func _arm(s: Vector2, h: Vector2, back: bool) -> void:
	var c := col(Art.shade(z.shirt, 0.25 if back else 0.0))
	var el := Art.joint(s, h, 14.0, 14.0, -1.0 if back else 1.0)
	Art.limb(z, PackedVector2Array([s, el, h]), 3.2, c)
	Art.disc(z, h, 1.9, col(Art.shade(z.skin, 0.2 if back else 0.0)), Art.OUTLINE, 0.8)


func _head(c: Vector2, sk: Color) -> void:
	# פנים צרות, צבועות לבן כגולגולת
	Art.oval_shaded(z, c, 4.6, 6.0, sk, 0.0)
	if not z.dead:
		z.draw_colored_polygon(Art.ellipse(c + Vector2(1.6, -0.8), 1.7, 1.9, 0.0, 8), col(Color("0c0a10")))   # ארובת עין
		z.draw_colored_polygon(Art.ellipse(c + Vector2(-2.4, -0.8), 1.2, 1.7, 0.0, 8), col(Color("0c0a10")))
		var glow := 0.6 + 0.4 * sin(z._time * 5.0)
		z.draw_circle(c + Vector2(1.8, -0.8), 0.8, Color(0.85, 0.5, 1.0, glow))
		z.draw_colored_polygon(PackedVector2Array([c + Vector2(3.6, 1.4), c + Vector2(4.6, 2.4), c + Vector2(3.4, 2.6)]), col(Color("0c0a10")))   # אף
		for q in 4:   # שיניים מצוירות על השפתיים
			var x := -1.0 + float(q) * 1.4
			z.draw_line(c + Vector2(x, 3.6), c + Vector2(x, 5.2), col(Color("1a1418")), 0.7)
		z.draw_line(c + Vector2(-1.6, 4.4), c + Vector2(4.0, 4.4), col(Color("1a1418")), 0.7)
	# מגבעת גבוהה עם סרט סגול ונוצה
	var hb := c + Vector2(0, -5)
	Art.fill(z, PackedVector2Array([hb + Vector2(-8, 0.5), hb + Vector2(8, -0.5), hb + Vector2(8, 1.5), hb + Vector2(-8, 2.5)]), col(Color("141016")), Art.OUTLINE, 0.9)
	Art.fill_shaded(z, PackedVector2Array([hb + Vector2(-5, 0.5), hb + Vector2(-4.5, -12), hb + Vector2(5.5, -12.5), hb + Vector2(5, 0)]), col(Color("1a1620")), 0.15, 0.3, Art.OUTLINE, 0.9)
	z.draw_colored_polygon(PackedVector2Array([hb + Vector2(-5, -1), hb + Vector2(5, -1.4), hb + Vector2(5, -3.6), hb + Vector2(-5, -3.2)]), col(Color("6a2a8a")))
	z.draw_line(hb + Vector2(-4, -3), hb + Vector2(-9, -11), col(Color("2a1a30")), 1.4)   # נוצה
	z.draw_line(hb + Vector2(-5, -5), hb + Vector2(-8, -8), col(Color("4a2a5a")), 1.0)
	# שיער לבן ודליל מתחת למגבעת
	for q in 3:
		z.draw_line(hb + Vector2(-4.0 + float(q) * 0.5, 1.5), hb + Vector2(-6.0 + float(q), 7.0), col(Color("c8c4bc")), 0.8)


func _cross(b: Vector2) -> void:
	var wood := col(Color("6a4a30"))
	var tilt := 0.0
	if _jwind > 0.0:
		tilt = -0.5
	elif _wwind > 0.0:
		tilt = 0.4 + sin(z._time * 30.0) * 0.1
	else:
		tilt = sin(z._time * 1.7) * 0.12
	var ax := Vector2(1, 0).rotated(tilt)
	var ay := Vector2(0, 1).rotated(tilt)
	Art.limb(z, PackedVector2Array([b - ay * 3.0, b + ay * 14.0]), 2.4, wood)
	Art.limb(z, PackedVector2Array([b - ax * 9.0, b + ax * 9.0]), 2.2, wood)
	Art.limb(z, PackedVector2Array([b + ay * 9.0 - ax * 6.0, b + ay * 9.0 + ax * 6.0]), 1.8, wood)
	z.draw_circle(b - ay * 3.0, 1.6, col(Color("c8a0e8")))
	for e in [b - ax * 9.0, b + ax * 9.0, b + ay * 14.0]:   # טבעות לחוטים
		z.draw_circle(e, 1.1, col(Color("d8c0f0")))
