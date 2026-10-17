extends "res://enemies/zombie_type.gd"
# ============================================================
#  SHEPHERD (שלב 54, "LAST BRIDGE") - הרועה: זומבי גבוה וחיוור במעיל קפוצ'ון אדום קרוע, ורידים זוהרים בכחול-לבן.
#  השראה: "השנים-עשר" וה"רבים" שלהם ב-"The Passage" (ג'סטין קרונין) - כל אחד שולט בעדר משלו ומת איתו,
#          ו"האיש המרופט" שמוביל את הלהקה ב-"Cell" (סטיבן קינג).
#  "THEY LEARNED TO FOLLOW":
#    LINK   - כל LINK_CD שניות שולח חוט אור דק מהמצח לזומבי קרוב (LINK_R), עד MAX_MANY - ה"רבים" שלו.
#             הרבים הולכים בצעד אחד איתו (אותו שלב הליכה), מהר יותר (MANY_SPEED), ומקבלים x0.6 נזק (zombie.gd meta "morale_t").
#    LUNGE  - כל LUNGE_CD שניות מרים את הידיים (אזהרה LUNGE_WIND: החוטים מתלקחים) -> כל הרבים קופצים עליך ביחד, באותו רגע.
#    שומר מרחק (HOLD_R) מאחורי הרבים שלו (תנועה משלו).
#  לנטרל: להרוג אותו -> כל הרבים שקשורים אליו נופלים מתים בבת אחת (שרשרת, ראש מתפוצץ, MULTI KILL על כל אחד).
#  לומד (main meta "sh_kills"): אחרי SH_LEARN רועים מתים בשלב - הבאים עומדים רחוק יותר (HOLD_R_LEARN), וכשאתה מכוון
#         אליו הוא מתחלף במקום (הבזק) עם אחד הרבים שלו (SWAP_CD). "THEY HIDE BEHIND THEIR MANY".
#  בוס (chase_range > 600): "THE ARCHITECT" - ענק עם הילה של חוטים. קשור לכל זומבי בגשר (BOSS_MANY, BOSS_LINK_R).
#         כל עוד GUARD_N רבים או יותר קשורים אליו - "הרבים מגינים עליו" (GUARD_MULT). פחות מזה - החזה נפתח (OPEN_MULT).
#         MIND BLAST (MIND_CD, אזהרה MIND_WIND): גל - כל הרבים מסתערים יחד, ומי שקרוב (MIND_R) נהדף.
#         PULL (PULL_CD): כשנשארו לו מעט רבים - מושך חוטים למטה לנהר ו-PULL_N מתים מטפסים מעל המעקה.
#         מותו: כל זומבי בשלב נופל, "THE REST ALREADY CROSSED", והגשר מתפוצץ (stage.on_architect_dead).
#  לשנות: MAX_MANY, LINK_R, LINK_CD, MANY_SPEED, HOLD_R, LUNGE_*, SH_LEARN, SWAP_CD, BOSS_*, GUARD_*, MIND_*, PULL_*.
# ============================================================

const SOUNDS := {
	"sh_link": [["S", 1400, 2200, 0.0, 0.35, 0.02, 6.0, 0.14, 1.0, 0.03], ["S", 2800, 3400, 0.05, 0.3, 0.02, 8.0, 0.05, 1.0, 0.0]],
	"sh_pulse": [["S", 180, 360, 0.0, 0.55, 0.3, 3.0, 0.3, 1.0, 0.06], ["S", 900, 1500, 0.1, 0.45, 0.25, 4.0, 0.08, 1.0, 0.02], ["N", 0, 0, 0.0, 0.5, 0.3, 4.0, 0.08, 0.5, 0, 0.3]],
	"sh_snap": [["S", 2600, 500, 0.0, 0.18, 0.0, 18.0, 0.3, 1.0, 0.0], ["N", 0, 0, 0.0, 0.1, 0.0, 30.0, 0.35, 0.9, 0, 0.8]],
	"sh_swap": [["S", 600, 2400, 0.0, 0.16, 0.0, 14.0, 0.25, 1.0, 0.0], ["N", 0, 0, 0.0, 0.12, 0.0, 22.0, 0.2, 0.9, 0, 0.6]],
	"sh_blast": {"rev": 0.4, "drive": 2.0, "layers": [["S", 90, 40, 0.0, 1.0, 0.0, 3.5, 0.9, 1.0, 0.05], ["N", 0, 0, 0.0, 0.8, 0.0, 5.0, 0.6, 0.4, 0, 0.6], ["S", 1600, 300, 0.0, 0.5, 0.0, 6.0, 0.2, 1.0, 0.0]]},
	"sh_voice": {"drive": 2.2, "layers": [["V", 70, 58, 0.0, 1.4, 0.1, 1.6, 0.7, 1.0, 0.06, 0, [380, 760, 14]], ["S", 140, 116, 0.0, 1.4, 0.1, 1.6, 0.15, 1.0, 0.06], ["N", 0, 0, 0.0, 1.4, 0.2, 2.0, 0.08, 0.2, 0]]},
}

const MAX_MANY := 5
const LINK_R := 460.0
const LINK_MAX := 680.0        # אחד הרבים שהתרחק יותר - החוט נקרע (בלי מוות)
const LINK_CD := 2.2
const GROW_T := 0.45           # החוט "נורה" מהמצח לאחד הרבים
const MANY_SPEED := 1.22
const GUARD_T := 0.4           # כל כמה זמן מחדשים את ה-morale_t (x0.6 נזק)
const HOLD_R := 300.0
const HOLD_R_LEARN := 470.0
const LUNGE_CD := 3.6
const LUNGE_WIND := 0.55
const LUNGE_V := Vector2(400.0, -210.0)
const CASCADE_STEP := 0.07     # השרשרת: כל כמה זמן נופל עוד אחד
const SH_LEARN := 2
const SWAP_CD := 4.5
const AIM_DOT := 0.985
# בוס
const BOSS_MANY := 12
const BOSS_LINK_R := 900.0
const BOSS_LINK_CD := 0.7
const BOSS_HOLD_R := 190.0
const GUARD_N := 3
const GUARD_MULT := 0.2
const OPEN_MULT := 1.35
const MIND_CD := 7.5
const MIND_WIND := 1.0
const MIND_R := 260.0
const PULL_CD := 9.0
const PULL_N := 2              # (פחות מ-GUARD_N: אחרי משיכה הוא עדיין פתוח לרגע)
const PULL_BELOW := 6          # מושך מהנהר רק כשיש לו פחות מזה

# לבדיקות
var links := 0
var lunges := 0
var swaps := 0
var chain_kills := 0
var blasts := 0
var pulls := 0
var guarded_hits := 0
var open_hits := 0

var many: Array = []            # [{p, t}]
var _layer: Node2D = null
var _lcd := 0.6
var _lucd := LUNGE_CD
var _lwind := 0.0
var _gcd := 0.0
var _swcd := 1.5
var _mcd := 4.0
var _mwind := 0.0
var _pcd := 5.0
var _ring := -1.0               # גל ה-MIND BLAST (שניות מאז)
var _blink := 0.0
var _learn_said := false
var _open_said := false
var _guard_pop := 0.0


func _boss() -> bool:
	return z != null and float(z.chase_range) > 600.0


func stats() -> Dictionary:
	if _boss():
		return {"name": "SHEPHERD", "hp": 520, "walk": 28.0, "chase": 50.0, "damage": 2, "bite_delay": 1.1, "scale": 2.0, "width": 0.95,
			"duck": 0.0, "cover": 0.0, "skin": Color("d2dce2"), "shirt": Color("5a141a"), "pants": Color("1c1c26"), "shoe": Color("101014"),
			"points": 2600, "boss": true, "boss_name": "THE ARCHITECT"}
	return {"name": "SHEPHERD", "hp": 60, "walk": 36.0, "chase": 66.0, "damage": 1, "bite_delay": 1.0, "scale": 1.24, "width": 0.84,
		"duck": 0.05, "cover": 0.3, "skin": Color("cfd8de"), "shirt": Color("6a1a1e"), "pants": Color("24242e"), "shoe": Color("141418"), "points": 800}


func brain_overrides() -> Dictionary:
	if _boss():
		return {"aggression": 0.3, "keep_range": 200.0}
	return {"aggression": 0.1, "keep_range": 280.0, "retreat_probability": 0.15}


func setup() -> void:
	_layer = ThreadLayer.new()
	_layer.owner_t = self
	z.get_parent().add_child.call_deferred(_layer)


func can_bite() -> bool:
	return _lwind <= 0.0 and _mwind <= 0.0


func max_many() -> int:
	return BOSS_MANY if _boss() else MAX_MANY


func learned() -> bool:
	var m: Node = z.get_parent()
	return m != null and int(m.get_meta("sh_kills", 0)) >= SH_LEARN


# המצח - משם יוצאים החוטים
func brow() -> Vector2:
	var up := -64.0
	if _lwind > 0.0 or _mwind > 0.0:
		up = -66.0
	return z.global_position + Vector2(z._dir * 3.0 * z.wf, up) * z.sc


static func head_point(p: Node) -> Vector2:
	return p.global_position + Vector2(float(p._dir) * 3.0, -51.0) * float(p.sc)


func alive_many() -> int:
	var n := 0
	for s in many:
		if _ok(s.p):
			n += 1
	return n


func guarded() -> bool:
	return _boss() and alive_many() >= GUARD_N


func _ok(p) -> bool:
	return p != null and is_instance_valid(p) and not p.dead and not p.is_queued_for_deletion()


# תנועה משלו: עומד מאחורי הרבים במרחק HOLD_R (הבוס מתקרב יותר)
func use_brain_movement() -> bool:
	return false


func logic(pl: Node, d: Vector2, _delta: float, speed: float) -> float:
	if _lwind > 0.0 or _mwind > 0.0:
		return speed * 0.1
	if pl == null or pl.dead:
		return speed
	var want := BOSS_HOLD_R if _boss() else (HOLD_R_LEARN if learned() else HOLD_R)
	if not _boss() and alive_many() == 0:
		want = 140.0   # בלי רבים - בא בעצמו
	var ad := absf(d.x)
	var face: float = signf(d.x) if d.x != 0.0 else float(z._dir)
	if ad > want + 60.0:
		z._dir = face
		return speed
	if ad < want - 100.0 and not _boss():
		z._dir = -face
		return speed * 0.85
	z._dir = face
	return 0.0


func physics(pl: Node, delta: float) -> bool:
	_tick(pl, delta)
	return false


func _tick(pl: Node, delta: float) -> void:
	_lcd -= delta
	_lucd -= delta
	_gcd -= delta
	_swcd -= delta
	_mcd -= delta
	_pcd -= delta
	_blink -= delta
	_guard_pop -= delta
	if _ring >= 0.0:
		_ring += delta
		if _ring > 0.6:
			_ring = -1.0
	_update_many(delta)
	if z.dead:
		return
	var has_pl: bool = pl != null and not pl.dead
	if has_pl and (alive_many() > 0 or z._noticed) and absf(pl.global_position.x - z.global_position.x) < LINK_MAX + 400.0:
		z._alert_t = maxf(float(z._alert_t), 0.5)
	# חוט חדש
	if _lcd <= 0.0:
		_lcd = 0.3
		if alive_many() < max_many():
			var c := _find_many()
			if c != null:
				_link(c)
				_lcd = BOSS_LINK_CD if _boss() else LINK_CD
	# LUNGE: מרים ידיים -> כל הרבים קופצים יחד
	if _lwind > 0.0:
		_lwind -= delta
		if _lwind <= 0.0:
			_lunge(pl)
	elif has_pl and _lucd <= 0.0 and _mwind <= 0.0 and not _boss():
		_lucd = 0.5
		var near := 0
		for s in many:
			if s.t >= 1.0 and _ok(s.p) and absf(s.p.global_position.x - pl.global_position.x) < 380.0:
				near += 1
		if near > 0:
			_lwind = LUNGE_WIND
			_lucd = LUNGE_CD
			Sfx.play("sh_pulse", z.global_position, 0.0, 0.08, 2, 1.2)
	# לומד: מתחלף במקום עם אחד הרבים כשמכוונים אליו
	if has_pl and not _boss() and learned() and _swcd <= 0.0 and alive_many() > 0 and _aimed_at(pl):
		_swap()
	# בוס: MIND BLAST + PULL
	if _boss() and has_pl:
		if _mwind > 0.0:
			_mwind -= delta
			if _mwind <= 0.0:
				_mind_blast(pl)
		elif _mcd <= 0.0 and absf(pl.global_position.x - z.global_position.x) < 900.0:
			_mwind = MIND_WIND * (0.75 if z.hp < z.max_hp / 2 else 1.0)
			_mcd = MIND_CD * (0.75 if z.hp < z.max_hp / 2 else 1.0)
			Sfx.play("sh_pulse", z.global_position, 4.0, 0.03, 2, 0.6)
			z._popup("FOLLOW...", Color("bfe8ff"), 16, -70.0)
		if _pcd <= 0.0 and z._chasing and alive_many() < PULL_BELOW:
			_pcd = PULL_CD
			_pull(pl)


func _aimed_at(pl: Node) -> bool:
	var chest: Vector2 = z.global_position + Vector2(0, -36.0 * z.sc)
	var from: Vector2 = pl.global_position + Vector2(0, -34.0)
	var to := chest - from
	if to.length() > 900.0 or to.length() < 60.0:
		return false
	var aim: Vector2 = pl._aim
	if aim.length() < 0.1:
		return false
	return aim.normalized().dot(to.normalized()) > AIM_DOT


func _find_many() -> Node:
	var best: Node = null
	var bd := BOSS_LINK_R if _boss() else LINK_R
	for o in z.get_tree().get_nodes_in_group("zombies"):
		if o == z or not _ok(o) or o.is_boss() or o.dormant or o.has_meta("shepherd"):
			continue
		if not _boss() and o.type_mod != null:   # רועה רגיל: רק זומבים רגילים (הבוס - כל אחד)
			continue
		if o.type_mod != null and o.type_mod.get_script() == get_script():   # לא רועה אחר
			continue
		var dist: float = o.global_position.distance_to(z.global_position)
		if dist < bd:
			bd = dist
			best = o
	return best


func _link(p: Node, instant := false) -> void:
	p.set_meta("shepherd", z)
	p.set_meta("sh_mul", p._speed_mul)
	p._speed_mul = float(p._speed_mul) * MANY_SPEED
	p._alert_t = maxf(float(p._alert_t), 6.0)
	many.append({"p": p, "t": 1.0 if instant else 0.0})
	links += 1
	Sfx.play("sh_link", z.global_position, -3.0, 0.08, 3)
	if learned() and not _learn_said and not _boss():
		_learn_said = true
		z._popup("THEY HIDE BEHIND THEIR MANY", Color("bfe8ff"), 13, -90.0)


func _unlink(s: Dictionary) -> void:
	var p = s.p
	if p != null and is_instance_valid(p):
		if p.has_meta("sh_mul"):
			p._speed_mul = float(p.get_meta("sh_mul"))
			p.remove_meta("sh_mul")
		if p.has_meta("shepherd"):
			p.remove_meta("shepherd")


func _update_many(delta: float) -> void:
	var keep: Array = []
	var refresh := _gcd <= 0.0
	if refresh:
		_gcd = GUARD_T * 0.5
	for s in many:
		var p = s.p
		if not _ok(p):
			continue
		if s.t < 1.0:
			s.t = minf(s.t + delta / GROW_T, 1.0)
		if not z.dead and p.global_position.distance_to(z.global_position) > (BOSS_LINK_R * 1.3 if _boss() else LINK_MAX):
			_unlink(s)
			continue
		if s.t >= 1.0 and not z.dead:
			# צעד אחד: אותו שלב הליכה כמו הרועה (נראה כמו להקה אחת)
			p._walk_phase = lerpf(float(p._walk_phase), float(z._walk_phase), 0.35)
			if refresh:
				p.set_meta("morale_t", float(p._time) + GUARD_T)
		keep.append(s)
	many = keep


func _lunge(pl: Node) -> void:
	if pl == null or pl.dead:
		return
	lunges += 1
	Sfx.play("sh_pulse", z.global_position, 3.0, 0.05, 2, 1.5)
	for s in many:
		var p = s.p
		if s.t < 1.0 or not _ok(p):
			continue
		var dx: float = pl.global_position.x - p.global_position.x
		if absf(dx) > 440.0:
			continue
		p._dir = signf(dx) if dx != 0.0 else p._dir
		p.velocity = Vector2(p._dir * minf(LUNGE_V.x, absf(dx) * 2.4 + 120.0), LUNGE_V.y)
		p._alert_t = maxf(float(p._alert_t), 4.0)


func _swap() -> void:
	var best = null
	var bd := INF
	for s in many:
		if s.t >= 1.0 and _ok(s.p) and s.p.is_on_floor():
			var dd: float = absf(s.p.global_position.y - z.global_position.y)
			if dd < 40.0 and s.p.global_position.distance_to(z.global_position) < bd:
				bd = s.p.global_position.distance_to(z.global_position)
				best = s.p
	if best == null:
		return
	_swcd = SWAP_CD
	swaps += 1
	var a: Vector2 = z.global_position
	var b: Vector2 = best.global_position
	z.global_position = Vector2(b.x, a.y)
	best.global_position = Vector2(a.x, b.y)
	_blink = 0.25
	var m: Node = z.get_parent()
	Particles.burst(m, a + Vector2(0, -40), "spark", Vector2.UP, 8)
	Particles.burst(m, b + Vector2(0, -40), "spark", Vector2.UP, 8)
	Sfx.play("sh_swap", b, 0.0, 0.1, 2)
	if swaps == 1:
		z._popup("SWAPPED", Color("bfe8ff"), 13, -90.0)


func _mind_blast(pl: Node) -> void:
	blasts += 1
	_ring = 0.0
	Sfx.play("sh_blast", z.global_position, 4.0, 0.05, 2)
	var cam: Camera2D = z.get_viewport().get_camera_2d()
	if cam != null and cam.has_method("shake"):
		cam.shake(10.0, 0.4)
	for s in many:
		var p = s.p
		if not _ok(p):
			continue
		p._rush_t = maxf(float(p._rush_t), 2.5)
		p._alert_t = maxf(float(p._alert_t), 6.0)
		var dx: float = pl.global_position.x - p.global_position.x
		if absf(dx) < 520.0 and p.is_on_floor():
			p._dir = signf(dx) if dx != 0.0 else p._dir
			p.velocity = Vector2(p._dir * minf(LUNGE_V.x, absf(dx) * 2.0 + 140.0), LUNGE_V.y * 0.8)
	var dd: Vector2 = pl.global_position - z.global_position
	if dd.length() < MIND_R * z.sc * 0.6 and pl._roll_t <= 0.0:
		pl.hurt(1, Vector2(signf(dd.x + 0.01) * 2.2, -1.0))


func _pull(pl: Node) -> void:
	var main: Node = z.get_parent()
	var n := 0
	for i in PULL_N:
		var side := 1.0 if i % 2 == 0 else -1.0
		var x: float = z.global_position.x + side * randf_range(160.0, 380.0)
		if pl != null and absf(x - pl.global_position.x) < 120.0:
			x += side * 200.0
		x = clampf(x, float(main.level_w) - 1380.0, float(main.level_w) - 280.0)   # (שלב 54: אחרי מחסום הצבא)
		var nz: Node = main._spawn_zombie(x, z.global_position.y, 0 if i < 2 else 1)
		if nz == null:
			continue
		n += 1
		nz.velocity = Vector2(0, -340.0)
		nz._alert_t = 8.0
		Particles.burst(main, Vector2(x, z.global_position.y - 4.0), "drop", Vector2.UP, 10)
		Particles.burst(main, Vector2(x, z.global_position.y - 10.0), "mist", Vector2.UP, 4)
		_link(nz, true)
	if n > 0:
		pulls += 1
		Sfx.play("splash", z.global_position, 3.0, 0.1, 2)
		z._popup("RISE FROM THE RIVER", Color("bfe8ff"), 15, -72.0)


# הבוס: הרבים מגינים עליו
func damage_mult(_zone: String, src: Dictionary) -> float:
	if not _boss():
		return 1.0
	if str(src.get("source", "")) == "link":
		return 1.0
	if guarded():
		guarded_hits += 1
		if _guard_pop <= 0.0:
			_guard_pop = 0.8
			z._popup("THE MANY SHIELD HIM", Color("a8d8f0"), 13, -78.0)
		_open_said = false
		return GUARD_MULT
	open_hits += 1
	if not _open_said:
		_open_said = true
		z._popup("HE IS OPEN!", Color("ffd34a"), 18, -82.0)
	return OPEN_MULT


func on_death() -> void:
	var m: Node = z.get_parent()
	if not _boss():
		m.set_meta("sh_kills", int(m.get_meta("sh_kills", 0)) + 1)
	var list: Array = []
	if _boss():   # כל זומבי בשלב
		for o in z.get_tree().get_nodes_in_group("zombies"):
			if o != z and _ok(o):
				list.append(o)
	else:
		for s in many:
			if s.t >= 0.5 and _ok(s.p):
				list.append(s.p)
	for s in many:
		_unlink(s)
	many.clear()
	var from: Vector2 = z.global_position
	list.sort_custom(func(a, b): return a.global_position.distance_squared_to(from) < b.global_position.distance_squared_to(from))
	if not list.is_empty():
		var c := Cascade.new()
		c.list = list
		c.from = brow()
		c.boss = _boss()
		c.owner_t = self
		c.step = 0.03 if _boss() else CASCADE_STEP
		m.add_child(c)
		Sfx.play("sh_snap", from, 4.0, 0.05, 2, 0.8)
		if not _boss():
			z._popup("THE MANY FALL x%d" % list.size(), Color("bfe8ff"), 20, -96.0)
	if _boss():
		var t = preload("res://zombie.gd").HitText.new()
		t.text = "THE REST ALREADY CROSSED"
		t.color = Color("d8f0ff")
		t.size = 26
		t.life = 4.5
		m.add_child(t)
		t.global_position = from + Vector2(0, -230.0)
		Sfx.play("sh_voice", from, 6.0, 0.02, 1, 0.8)
		var st = m.get("_stage")
		if st != null and st.has_method("on_architect_dead"):
			st.on_architect_dead(from)
	if _layer != null and is_instance_valid(_layer):
		_layer.fade = true


# ============================================================
#  השרשרת: כשהרועה מת, כל אחד מהרבים נופל - בזה אחר זה מהקרוב לרחוק, עם קו אור שנקרע אליו.
#  רועה רגיל: הראש מתפוצץ (HEADSHOT + MULTI KILL). הבוס: כל הזומבים בשלב (מוות "גוף", בלי חותמות ראש על כל המסך).
# ============================================================
class Cascade extends Node2D:
	var list: Array = []
	var from := Vector2.ZERO
	var boss := false
	var step := 0.07
	var owner_t = null
	var _t := 0.0
	var _i := 0
	var _bid := 0
	var _snaps: Array = []        # [נקודה, זמן]

	func _ready() -> void:
		z_index = 6
		_bid = 700000 + randi() % 200000

	func _process(delta: float) -> void:
		_t -= delta
		var view: Rect2 = get_viewport().get_canvas_transform().affine_inverse() * get_viewport().get_visible_rect()
		while _t <= 0.0 and _i < list.size():
			var p = list[_i]
			_i += 1
			if p == null or not is_instance_valid(p) or p.dead:
				continue
			var on: bool = view.grow(200.0).has_point(p.global_position)
			_kill(p)
			if on:
				_t += step
				_snaps.append([p.global_position + Vector2(0, -50.0 * float(p.sc)), 0.35])
		for s in _snaps:
			s[1] -= delta
		_snaps = _snaps.filter(func(s): return s[1] > 0.0)
		queue_redraw()
		if _i >= list.size() and _snaps.is_empty():
			queue_free()

	func _kill(p: Node) -> void:
		var dir: Vector2 = (p.global_position - from).normalized()
		if dir == Vector2.ZERO:
			dir = Vector2.RIGHT
		var hp: Vector2 = p.global_position + Vector2(float(p._dir) * 3.0, -50.0) * float(p.sc)
		if boss:
			hp = p.global_position + Vector2(0, -30.0 * float(p.sc))
		p.take_damage(0, hp, dir, boss, {"source": "link", "fixed": 9999, "bullet": _bid})
		if not p.dead:
			p._die(dir)
		if owner_t != null:
			owner_t.chain_kills += 1
		var m := get_parent()
		m.set_meta("sh_chain", int(m.get_meta("sh_chain", 0)) + 1)
		Particles.burst(m, hp, "spark", Vector2.UP, 4)

	func _draw() -> void:
		for s in _snaps:
			var a: float = clampf(s[1] / 0.35, 0.0, 1.0)
			var to: Vector2 = s[0]
			var mid: Vector2 = from.lerp(to, 0.5) + Vector2(0, 18.0 * (1.0 - a))
			draw_polyline(PackedVector2Array([from, mid, to]), Color(0.6, 0.85, 1.0, 0.25 * a), 6.0)
			draw_polyline(PackedVector2Array([from, mid, to]), Color(0.9, 0.97, 1.0, 0.9 * a), 1.6)
			draw_circle(to, 6.0 * a + 2.0, Color(0.85, 0.95, 1.0, 0.7 * a))


# ============================================================
#  ציור החוטים (בעולם): מהמצח לראש של כל אחד מהרבים - שני סיבים דקים כחולים-לבנים, ופעימות אור שזזות לאורכם.
#  עין זוהרת על הראש של כל אחד מהרבים. בזמן LUNGE / MIND BLAST מתלקחים. הגל של ה-MIND BLAST.
# ============================================================
class ThreadLayer extends Node2D:
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
		if Art.on_screen(self, owner_t.z.global_position, 700.0):
			queue_redraw()

	func _draw() -> void:
		var o = owner_t
		var zz = o.z
		var bp: Vector2 = o.brow()
		var hot: float = 1.0 if (o._lwind > 0.0 or o._mwind > 0.0) else 0.0
		var pts := PackedVector2Array()
		var cols := PackedColorArray()
		for s in o.many:
			var p = s.p
			if p == null or not is_instance_valid(p) or p.dead:
				continue
			var hp: Vector2 = o.head_point(p)
			var tip := bp.lerp(hp, float(s.t))
			var line := PackedVector2Array()
			for q in 9:
				var u := float(q) / 8.0
				var pt := bp.lerp(tip, u)
				pt.y -= sin(u * PI) * (16.0 - 10.0 * hot)
				pt.y += sin(_t * 6.0 + u * 8.0 + float(p.get_instance_id() % 7)) * 1.4 * sin(u * PI)
				line.append(pt)
			draw_polyline(line, Color(0.55, 0.8, 1.0, 0.16 + 0.22 * hot), 4.0 + 2.0 * hot)
			draw_polyline(line, Color(0.88, 0.96, 1.0, 0.75), 1.1)
			if s.t >= 1.0:
				for k in 2:   # פעימות אור שרצות מהרועה אליהם
					var u2 := fmod(_t * (0.9 + 0.6 * hot) + float(k) * 0.5, 1.0)
					var i0 := int(u2 * 8.0)
					var c: Vector2 = line[mini(i0, 7)].lerp(line[mini(i0 + 1, 8)], u2 * 8.0 - float(i0))
					Art.glow(self, c, 5.0, Color(0.8, 0.95, 1.0, 0.5))
				# עין זוהרת על אחד הרבים
				var eye: Vector2 = p.global_position + Vector2(float(p._dir) * 4.0, -52.0) * float(p.sc)
				Art.glow(self, eye, 7.0, Color(0.6, 0.9, 1.0, 0.55))
				pts.append_array(PackedVector2Array([eye + Vector2(-1.4, 0), eye + Vector2(0, -1.4), eye + Vector2(1.4, 0), eye + Vector2(-1.4, 0), eye + Vector2(1.4, 0), eye + Vector2(0, 1.4)]))
				for q in 6:
					cols.append(Color(0.92, 0.98, 1.0, 0.95))
		if not pts.is_empty():
			RenderingServer.canvas_item_add_triangle_array(get_canvas_item(), PackedInt32Array(), pts, cols)
		if zz.dead:
			return
		Art.glow(self, bp, 14.0 + 12.0 * hot, Color(0.6, 0.88, 1.0, 0.22 + 0.25 * hot))
		if o._ring >= 0.0:   # הגל של MIND BLAST
			var k2: float = o._ring / 0.6
			var r: float = MIND_R * float(zz.sc) * 0.6 + k2 * 520.0
			var c0: Vector2 = zz.global_position + Vector2(0, -40.0 * float(zz.sc))
			draw_arc(c0, r, 0.0, TAU, 48, Color(0.7, 0.92, 1.0, 0.55 * (1.0 - k2)), 8.0 * (1.0 - k2) + 1.0)
			draw_arc(c0, r * 0.8, 0.0, TAU, 40, Color(0.9, 0.98, 1.0, 0.3 * (1.0 - k2)), 2.0)


# ============================================================
#  ציור: גבוה וכחוש, עור חיוור-כחלחל עם ורידים זוהרים, קפוצ'ון אדום-כהה קרוע (המעיל של "האיש המרופט"),
#  הברדס מורד על הכתפיים, ראש קירח וצר, עיניים לבנות זוהרות, "עין שלישית" במצח שממנה יוצאים החוטים,
#  אצבעות ארוכות. מרים את שתי הידיים כמו מנצח לפני LUNGE. בוס: הילה של חוטים קצרים מסביב לראש, והחזה נפתח
#  (לב זוהר) כשהרבים לא מגינים עליו.
# ============================================================
func draw() -> bool:
	if _blink > 0.0 and int(_blink * 40.0) % 2 == 0:
		return true
	begin_draw()
	var sk := col(z.skin)
	var coat := col(z.shirt)
	var f: Array = feet(4.5, 2.2)
	var hip := Vector2(0, -27)
	var sh := Vector2(1, -47)
	var head := sh + Vector2(2.5, -8.5)
	var up: float = 1.0 if (_lwind > 0.0 or _mwind > 0.0) else 0.0
	var lean := -2.5 * up
	sh.x += lean
	head.x += lean
	var t: float = z._time
	# קפוצ'ון: כנף אחורית קרועה מתנופפת ברוח
	var sway: float = clampf(sin(t * 2.6) * 1.8 + (-z.velocity.x * z._dir) * 0.02, -6.0, 6.0)   # (יותר מזה - המצולע מצטלב)
	Art.fill(z, PackedVector2Array([sh + Vector2(-7, 1), hip + Vector2(-6, 2), hip + Vector2(-9.0 + sway, 9), hip + Vector2(-6.0 + sway, 12), hip + Vector2(-11.0 + sway, 14), hip + Vector2(-12.0 + sway * 0.6, 4)]), col(Art.shade(z.shirt, 0.25)))
	# רגליים ארוכות, מכנס כהה קרוע, רגליים יחפות
	z._leg(hip + Vector2(-2, 0), f[1], col(Art.shade(z.pants, 0.25)), sk, sk.darkened(0.25))
	z._leg(hip + Vector2(2, 0), f[0], col(z.pants), sk, sk.darkened(0.15))
	# יד אחורית
	var hb := sh + Vector2(-5.0 + sin(t * 1.8) * 1.5, 16.0)
	if up > 0.0:
		hb = sh + Vector2(-9, -15)
	_arm(sh + Vector2(-3, 1), hb, true)
	# גוף: קפוצ'ון אדום-כהה קרוע, צלעות חשופות בקרע
	var torso := PackedVector2Array([sh + Vector2(-7, -1), sh + Vector2(7, 0), hip + Vector2(6, 0), hip + Vector2(-6, -1)])
	Art.fill_shaded(z, torso, coat, 0.12, 0.35)
	z.draw_colored_polygon(PackedVector2Array([sh + Vector2(1, 5), sh + Vector2(6, 6), hip + Vector2(4, -6), hip + Vector2(0, -4)]), col(Art.shade(z.skin, 0.25)))   # הקרע
	for q in 3:   # צלעות
		var y := sh.y + 7.0 + float(q) * 3.0
		z.draw_line(Vector2(sh.x + 1.5, y), Vector2(sh.x + 5.5, y + 1.0), col(Color("eef2f0")), 0.8)
	z.draw_line(sh + Vector2(-1, 1), hip + Vector2(-1, -2), col(Art.shade(z.shirt, 0.4)), 0.8)   # רוכסן
	z.draw_line(hip + Vector2(-6, -4), hip + Vector2(6, -3), col(Art.shade(z.shirt, 0.45)), 1.2)   # חפת תחתון
	# הברדס מורד על הכתפיים
	Art.fill(z, PackedVector2Array([sh + Vector2(-8, 1), sh + Vector2(-9, -5), sh + Vector2(-4, -8), sh + Vector2(0, -4), sh + Vector2(4, -3), sh + Vector2(7, 1)]), col(Art.shade(z.shirt, 0.1)), Art.OUTLINE, 0.9)
	# בוס: החזה נפתח - לב זוהר
	if _boss() and not z.dead:
		var open: float = 0.0 if guarded() else 1.0
		var hc := sh.lerp(hip, 0.38) + Vector2(2, 0)
		if open > 0.0:
			z.draw_colored_polygon(Art.ellipse(hc, 4.2, 5.4, 0.0, 12), col(Color("2a0a14")))
			Art.glow(z, hc, 9.0, Color(0.6, 0.9, 1.0, 0.7 + 0.2 * sin(t * 9.0)))
			z.draw_circle(hc, 2.2, Color(0.92, 0.98, 1.0))
		else:
			for q in 4:   # החוטים תפרו את החזה
				var yy := hc.y - 4.0 + float(q) * 2.6
				z.draw_line(Vector2(hc.x - 3.0, yy), Vector2(hc.x + 3.0, yy + 1.0), Color(0.7, 0.9, 1.0, 0.8), 0.7)
	_head(head, sk, up)
	# יד קדמית: אצבעות ארוכות, מורמת בזמן LUNGE / MIND BLAST
	var hf := sh + Vector2(6.0 + sin(t * 1.5) * 1.0, 15.0)
	if up > 0.0:
		hf = sh + Vector2(9, -16)
	elif z._bite_anim > 0.0:
		hf = sh + Vector2(15, 2)
	_arm(sh + Vector2(4, 1), hf, false)
	# ורידים זוהרים על הצוואר והידיים
	var vc := Color(0.62, 0.9, 1.0, 0.55 + 0.3 * up)
	z.draw_line(sh + Vector2(2, -1), head + Vector2(-1, 4), vc, 0.7)
	z.draw_line(sh + Vector2(3, -1), head + Vector2(2, 5), vc, 0.6)
	end_draw()
	return true


func _arm(s: Vector2, h: Vector2, back: bool) -> void:
	var c := col(Art.shade(z.shirt, 0.28 if back else 0.0))
	var el := Art.joint(s, h, 15.0, 15.0, -1.0 if back else 1.0)
	Art.limb(z, PackedVector2Array([s, el, el.lerp(h, 0.55)]), 3.0, c)
	Art.limb(z, PackedVector2Array([el.lerp(h, 0.5), h]), 2.0, col(Art.shade(z.skin, 0.22 if back else 0.0)))
	var dir := (h - el).normalized()
	for q in 3:   # אצבעות ארוכות
		var a := dir.rotated((float(q) - 1.0) * 0.35)
		z.draw_line(h, h + a * 4.5, col(Art.shade(z.skin, 0.15 if back else 0.0)), 0.9)
	z.draw_line(el.lerp(h, 0.55), h, Color(0.62, 0.9, 1.0, 0.45), 0.6)   # וריד זוהר


func _head(c: Vector2, sk: Color, up: float) -> void:
	# ראש צר וארוך, קירח, ורידים זוהרים על הקרקפת
	Art.oval_shaded(z, c, 4.4, 6.2, sk, 0.0)
	z.draw_colored_polygon(Art.ellipse(c + Vector2(1.4, 1.6), 3.2, 1.5, 0.0, 8), col(Art.shade(z.skin, 0.35)))   # לחיים שקועות
	if not z.dead:
		var vc := Color(0.62, 0.9, 1.0, 0.6 + 0.3 * up)
		z.draw_polyline(PackedVector2Array([c + Vector2(-3, -5), c + Vector2(-1, -2), c + Vector2(-2, 1)]), vc, 0.6)
		z.draw_polyline(PackedVector2Array([c + Vector2(1, -6), c + Vector2(0, -3.5)]), vc, 0.6)
		# עיניים לבנות זוהרות
		z.draw_colored_polygon(Art.ellipse(c + Vector2(2.4, -0.6), 1.7, 1.4, 0.0, 8), col(Color("0a0e14")))
		z.draw_colored_polygon(Art.ellipse(c + Vector2(-1.6, -0.6), 1.2, 1.2, 0.0, 8), col(Color("0a0e14")))
		z.draw_circle(c + Vector2(2.6, -0.6), 0.9, Color(0.9, 0.98, 1.0))
		z.draw_circle(c + Vector2(-1.4, -0.6), 0.6, Color(0.8, 0.92, 1.0, 0.8))
		Art.glow(z, c + Vector2(2.6, -0.6), 4.0, Color(0.6, 0.9, 1.0, 0.45))
		# פה: חריץ דק ושקט (הוא לא נוהם - הוא מנצח)
		z.draw_line(c + Vector2(1.0, 3.6), c + Vector2(4.2, 3.2), col(Color("1a1018")), 0.8)
		# "העין השלישית" במצח
		var bc := c + Vector2(1.6, -3.6)
		z.draw_circle(bc, 1.1, Color(0.9, 0.98, 1.0, 0.95))
	if _boss() and not z.dead:   # הילה: חוטים קצרים שעומדים סביב הראש כמו כתר
		for q in 11:
			var a := -PI + float(q) / 10.0 * PI
			var r0 := 7.0
			var r1 := 11.0 + 2.0 * sin(z._time * 4.0 + float(q)) + 3.0 * up
			z.draw_line(c + Vector2.from_angle(a) * r0, c + Vector2.from_angle(a) * r1, Color(0.75, 0.94, 1.0, 0.7), 0.7)
			z.draw_circle(c + Vector2.from_angle(a) * r1, 0.8, Color(0.9, 0.98, 1.0, 0.85))
