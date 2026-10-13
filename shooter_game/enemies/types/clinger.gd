extends "res://enemies/zombie_type.gd"
# ============================================================
#  CLINGER (שלב 28, "DEATH ROAD") - נוסע שנפל מהכביש וחזר. פונצ'ו גשם כתום קרוע, ידיים ארוכות, אצבעות דקות.
#  "THEY LEARNED TO WAIT": תלוי על שפת הבור (effects/s28_decor.gd Washout) או מתחת לשפת הכביש העליון (CliffLedge),
#  רק האצבעות בולטות (ומדי פעם הראש מציץ = אזהרה).
#    HANG    - מחכה. אתה עומד על השפה / קופץ מעל הבור / הולך מעליו בכביש העליון -> LUNGE
#    LUNGE   - חובט בסלע (LUNGE_T) ותופס את הרגל (player.grab) -> HOLD
#    HOLD    - מושך אותך לבור / מהכביש העליון (PULL_T). A/D לסירוגין = משתחררים. נזק חזק = עוזב.
#    EXPOSED - אחרי שהשתחררת / שהוא פספס: תלוי חצי בחוץ, פגיע (x1.5) -> מטפס החוצה ונלחם, או חוזר לחכות
#    אם עברת אותו בלי שנגעת בשפה - מטפס החוצה ותוקף מאחור. ירית בו כשהוא תלוי ולא מת - נעלם בערפל ועובר לשפה השנייה.
#  זומבים שנולדים רחוק מבור (משקל בשלב) הולכים לשפה פנויה ומחכים שם (SEEK).
#  לשנות: GRAB_X, GRAB_UP, LUNGE_T, PULL_T, PASS_R, SEEK_R.
# ============================================================

const SOUNDS := {
	"cl_slap": [["C", 0, 0, 0.0, 0.08, 0.0, 40.0, 0.8, 1.0, 0], ["N", 0, 0, 0.0, 0.1, 0.0, 30.0, 0.35, 0.4, 0]],
	"cl_rasp": {"drive": 2.0, "layers": [["V", 140, 110, 0.0, 0.5, 0.05, 4.0, 0.6, 1.0, 0.04, 0, [600, 1200, 30]], ["N", 0, 0, 0.0, 0.45, 0.05, 4.0, 0.25, 0.6, 0]]},
}

const GRAB_X := 44.0
const GRAB_UP := 70.0
const LUNGE_T := 0.24
const PULL_T := 2.0
const PASS_R := 260.0
const SEEK_R := 700.0
const HIDE_T := 1.3
const HANG_Y := 32.0         # כפות הרגליים מתחת לשפה (נשאר מעל היתדות של הבור)
const DRAW_Y := 24.0         # הציור יורד עוד (הגוף נראה תלוי באמת)

enum { START, SEEK, HANG, LUNGE, HOLD, EXPOSED, HIDE, CLIMB, WALK }
var state := START
var grabs := 0               # לבדיקות
var pulls := 0
var relocations := 0
var _a: Dictionary = {}      # העוגן: {"x" ידיים, "y" שפה, "side", "pit", "node", "key", "bx" הגוף}
var _st := 0.0
var _cd := 0.0
var _peek := 0.0
var _peek_cd := 2.0
var _near := false
var _taken := 0
var _shape_y := 0.0
var _z0 := 0


func stats() -> Dictionary:
	return {"name": "CLINGER", "hp": 22, "walk": 44.0, "chase": 96.0, "damage": 1, "bite_delay": 0.7, "scale": 1.0, "width": 0.9,
		"duck": 0.0, "cover": 0.0, "skin": Color("8a9478"), "shirt": Color("d0661e"), "pants": Color("2e2a2a"), "shoe": Color("8a9478"), "points": 420}


func brain_overrides() -> Dictionary:
	return {"aggression": 0.3, "flank_probability": 0.3}


func can_bite() -> bool:
	return state == WALK


func can_groan() -> bool:
	return state == WALK or state == SEEK


func _grabbable(pl: Node) -> bool:
	return pl != null and not pl.dead and pl.grabbed_by == null and pl._roll_t <= 0.0 and not pl._climbing


# ---- עוגנים: שתי השפות של כל בור + שתי נקודות מתחת לכל כביש עליון ----
func _anchors() -> Array:
	var out := []
	for wn in z.get_tree().get_nodes_in_group("washouts"):
		var gx: float = wn.global_position.x
		var w: float = wn.w
		var ly: float = wn.global_position.y
		out.append({"x": gx + 3.0, "y": ly, "side": -1.0, "pit": true, "node": wn, "key": "cl_l", "bx": gx + 14.0, "road": gx - 16.0})
		out.append({"x": gx + w - 3.0, "y": ly, "side": 1.0, "pit": true, "node": wn, "key": "cl_r", "bx": gx + w - 14.0, "road": gx + w + 16.0})
	for ln in z.get_tree().get_nodes_in_group("ledges"):
		var gx: float = ln.global_position.x
		var w: float = ln.w
		for f in [0.3, 0.72]:
			var hx := gx + w * float(f)
			out.append({"x": hx, "y": ln.lip_y(), "side": -1.0, "pit": false, "node": ln, "key": "cl_%d" % int(f * 100.0), "bx": hx, "road": hx})
	return out


func _free(a: Dictionary) -> bool:
	var n: Node = a.node
	if not n.has_meta(a.key):
		return true
	var o = n.get_meta(a.key)
	return o == z or o == null or not is_instance_valid(o) or o.dead


func _take(a: Dictionary) -> void:
	_release_anchor()
	_a = a
	(a.node as Node).set_meta(a.key, z)


func _release_anchor() -> void:
	if not _a.is_empty() and is_instance_valid(_a.node) and _a.node.has_meta(_a.key) and _a.node.get_meta(_a.key) == z:
		_a.node.set_meta(_a.key, null)
	_a = {}


func _nearest(max_d: float, pits_only: bool, from_y := INF) -> Dictionary:
	var best: Dictionary = {}
	var bd := max_d
	for a in _anchors():
		if pits_only and not a.pit:
			continue
		if not _free(a):
			continue
		if from_y != INF and absf(float(a.y) - from_y) > 40.0:
			continue
		var d := absf(float(a.road) - z.global_position.x)
		if d < bd:
			bd = d
			best = a
	return best


func _hang_at(a: Dictionary) -> void:
	_take(a)
	state = HANG
	_near = false
	z.global_position = Vector2(float(a.bx), float(a.y) + HANG_Y)
	z.velocity = Vector2.ZERO
	z._dir = float(a.side)
	if _shape_y == 0.0:
		_shape_y = z._shape.position.y
	z._shape.position.y = -6.0
	if a.pit:
		z.z_index = 3   # מעל הבור, מתחת לערפל שלו
	z.set_meta("pit_hop", false)


func _climb_out() -> void:
	state = CLIMB
	_st = 0.4
	Sfx.play("cl_rasp", z.global_position, -2.0, 0.1, 2)


func _to_road() -> void:
	z.global_position = Vector2(float(_a.road), float(_a.y) - 1.0)
	z.velocity = Vector2(float(_a.side) * -60.0 if _a.pit else 0.0, -120.0)
	z._shape.position.y = _shape_y if _shape_y != 0.0 else -33.0 * z.sc
	z.z_index = _z0
	z.set_meta("pit_hop", true)   # למד: תמיד קופץ מעל בורות
	z._alert_t = maxf(float(z._alert_t), 6.0)
	_release_anchor()
	state = WALK


func setup() -> void:
	_z0 = z.z_index


# השלב קורא לזה מיד אחרי spawn: נתלה על השפה הקרובה (בור / כביש עליון) לפני שהוא נופל
func attach() -> bool:
	var a := _nearest(140.0, false, z.global_position.y)
	if a.is_empty():
		return false
	_hang_at(a)
	return true


func physics(pl: Node, delta: float) -> bool:
	_st -= delta
	_cd -= delta
	_peek -= delta
	_peek_cd -= delta
	if z.dead:
		return false
	var has_pl: bool = pl != null and not pl.dead
	match state:
		START:   # נולד ליד שפה -> נתלה. אחרת הולך לחפש אחת
			if attach():
				return true
			state = SEEK
			return false
		SEEK:
			if has_pl and absf(pl.global_position.x - z.global_position.x) < 420.0:
				state = WALK
				return false
			if _a.is_empty() or not _free(_a):
				var a := _nearest(SEEK_R, true)
				if a.is_empty():
					state = WALK
					return false
				_take(a)
			var dx: float = float(_a.road) - z.global_position.x
			if absf(dx) < 8.0 and z.is_on_floor():
				_hang_at(_a)
				return true
			z._dir = signf(dx)
			z.velocity.x = move_toward(z.velocity.x, z._dir * float(z.walk_speed) * 2.0, 400.0 * delta)
			if not z.is_on_floor():
				z.velocity.y += z.gravity * delta
			elif z.is_on_wall():   # מכשול בדרך: קופץ
				z.velocity.y = -430.0
			z.set_meta("pit_hop", false)
			z.move_and_slide()
			return true
		WALK:
			return false
		HANG:
			if _peek_cd <= 0.0:   # מציץ מעל השפה (אזהרה)
				_peek_cd = randf_range(2.5, 4.5)
				_peek = 0.7
			if has_pl:
				var dx: float = pl.global_position.x - float(_a.x)
				if absf(dx) < 220.0:
					_near = true
				if _cd <= 0.0 and _in_reach(pl, 0.0) and _grabbable(pl):
					state = LUNGE
					_st = LUNGE_T
					Sfx.play("cl_slap", Vector2(float(_a.x), float(_a.y)), 2.0, 0.1, 2)
				elif _near and absf(dx) > PASS_R:   # עברת אותו - יוצא ותוקף מאחור
					_climb_out()
		LUNGE:
			if _st <= 0.0:
				if has_pl and _in_reach(pl, 12.0) and _grabbable(pl):
					state = HOLD
					_st = PULL_T
					_taken = 0
					grabs += 1
					pl.grab(z)
					Sfx.play("cl_rasp", z.global_position, 2.0, 0.1, 2)
				else:   # פספס: תלוי חצי בחוץ
					state = EXPOSED
					_st = 1.0
		HOLD:
			if not has_pl or pl.grabbed_by != z:
				state = EXPOSED
				_st = 1.0
			else:
				if _a.pit:   # מושך אל הבור
					var cx: float = _a.node.global_position.x + float(_a.node.w) * 0.5
					pl.global_position.x = move_toward(pl.global_position.x, cx, 60.0 * delta)
				pl.velocity.x = 0.0
				if _st <= 0.0:
					_pull(pl)
		EXPOSED:
			if _st <= 0.0:
				if has_pl and absf(pl.global_position.x - float(_a.x)) < 240.0:
					_climb_out()
				else:
					state = HANG
					_cd = 2.0
		HIDE:   # נעלם בערפל ועובר לשפה השנייה של הבור
			if _st <= 0.0:
				var other: Dictionary = {}
				for a in _anchors():
					if a.node == _a.node and a.key != _a.key and _free(a):
						other = a
				if not other.is_empty():
					relocations += 1
					_hang_at(other)
					_cd = 1.0
				else:
					state = HANG
		CLIMB:
			if _st <= 0.0:
				_to_road()
				return false
	z.velocity = Vector2.ZERO
	return true


func _in_reach(pl: Node, extra: float) -> bool:
	var dx: float = absf(pl.global_position.x - float(_a.x))
	var py: float = pl.global_position.y
	var ly: float = _a.y
	if dx > GRAB_X + extra:
		return false
	if _a.pit:   # עומד על השפה / קופץ מעל / נופל פנימה
		return py > ly - GRAB_UP - extra and py < ly + 40.0
	return absf(py - ly) < 10.0 + extra and pl.is_on_floor()


func _pull(pl: Node) -> void:
	pulls += 1
	pl.grabbed_by = null
	if _a.pit:   # לתוך הבור (הברזלים עושים את השאר)
		pl.global_position.x = _a.node.global_position.x + float(_a.node.w) * 0.5
		pl.velocity = Vector2(0.0, 220.0)
		pl.hurt(1, Vector2(0.0, 0.5))
	else:   # מהכביש העליון למטה
		pl.collision_mask &= ~16
		pl._drop_t = 0.3
		pl.velocity = Vector2(0.0, 160.0)
		pl.hurt(1, Vector2(0.0, 0.5))
	z._popup("PULLED!", Color("ff9050"), 14, -40.0)
	state = HANG
	_cd = 3.0
	_near = false


func on_release() -> void:   # השחקן השתחרר (A/D)
	state = EXPOSED
	_st = 1.2
	_cd = 2.5
	z._popup("SHAKEN OFF", Color(1.0, 0.75, 0.4), 13, -40.0)


func on_damage(amount: int, _hit_pos: Vector2, _dir: Vector2, _src: Dictionary) -> bool:
	if state == HOLD:
		_taken += hit_damage(amount, _hit_pos, _src)
		if _taken >= 12:
			var pl := player()
			if pl != null and pl.grabbed_by == z:
				pl.grabbed_by = null
			state = EXPOSED
			_st = 1.0
			_cd = 2.5
			z._popup("LET GO!", Color(1.0, 0.75, 0.4), 13, -40.0)
	elif state == HANG and _a.get("pit", false):   # נפגע כשהוא תלוי: אם ישרוד - יעבור לשפה השנייה
		_hide_after_hit.call_deferred()
	return true


func _hide_after_hit() -> void:
	if z == null or not is_instance_valid(z) or z.dead or state != HANG:
		return
	state = HIDE
	_st = HIDE_T


func damage_mult(_zone: String, _src: Dictionary) -> float:
	return 1.5 if state == EXPOSED else 1.0


func on_death() -> void:
	var pl := player()
	if pl != null and pl.grabbed_by == z:
		pl.grabbed_by = null
	if state != WALK and state != SEEK and state != START:
		z._shape.position.y = _shape_y if _shape_y != 0.0 else -33.0 * z.sc
		z.z_index = _z0
	_release_anchor()


# ============================================================
#  ציור: גוף רזה, פונצ'ו כתום קרוע, ידיים ארוכות.
#  תלוי: הגוף מתחת לשפה, הידיים למעלה על השפה (מציץ / מתרומם / תופס את הרגל)
# ============================================================
func _hang_off() -> float:
	match state:
		HANG:
			return DRAW_Y - (12.0 if _peek > 0.0 else 0.0)
		LUNGE:
			return lerpf(4.0, DRAW_Y, clampf(_st / LUNGE_T, 0.0, 1.0))
		HOLD:
			return 8.0
		EXPOSED:
			return 2.0
		HIDE:
			return DRAW_Y + 40.0 * clampf(1.0 - _st / HIDE_T, 0.0, 1.0) * 1.5
		CLIMB:
			return lerpf(-14.0, 2.0, clampf(_st / 0.4, 0.0, 1.0))
	return 0.0


func draw() -> bool:
	var hanging: bool = not z.dead and state in [HANG, LUNGE, HOLD, EXPOSED, HIDE, CLIMB] and not _a.is_empty()
	begin_draw(not hanging)
	var sk := col(z.skin)
	var poncho := col(z.shirt)
	var p: float = z._walk_phase
	var o := Vector2(0.0, _hang_off() / z.sc) if hanging else Vector2.ZERO
	var hip := Vector2(0, -22) + o
	var sh := Vector2(1, -36) + o
	var head := sh + Vector2(3.0, -8.0)
	var f: Array = feet(5.0, 2.5)
	if hanging:   # רגליים תלויות
		f = [hip + Vector2(3.0 + sin(z._time * 1.7) * 1.5, 21.0), hip + Vector2(-3.0, 22.0)]
	z._leg(hip + Vector2(-2, 0), f[1], col(Art.shade(z.pants, 0.25)), sk, sk)
	z._leg(hip + Vector2(2, 0), f[0], col(z.pants), sk, sk)
	var hb: Vector2
	var hf: Vector2
	if hanging:   # הידיים על השפה (מקומי)
		var lip := Vector2((float(_a.x) - z.global_position.x) * z._dir / (z.wf * z.sc), (float(_a.y) - z.global_position.y) / z.sc)
		hb = lip + Vector2(-10.0, 1.0)   # ידיים פשוקות: הראש באמצע, מביט למעלה
		hf = lip + Vector2(10.0, 1.0)
		if state == HOLD:   # יד אחת על הקרסול של השחקן
			var pl := player()
			if pl != null:
				hf = Vector2((pl.global_position.x - z.global_position.x) * z._dir / (z.wf * z.sc), (pl.global_position.y - 4.0 - z.global_position.y) / z.sc)
		elif state == LUNGE:
			hf = lip + Vector2(14.0, -6.0)
	else:
		hb = sh + Vector2(-6.0 - sin(p) * 3.0, 17.0)
		hf = sh + Vector2(12.0 + sin(p) * 3.0, 9.0)   # ידיים ארוכות קדימה
	z._arm(sh + Vector2(-3, 1), hb, Art.shade(sk, 0.25), Art.shade(poncho, 0.3))
	if hanging:
		z._arm(sh + Vector2(3, 1), hf, sk, poncho)
	# פונצ'ו קרוע
	var pts := PackedVector2Array([sh + Vector2(-8, -1), sh + Vector2(8, 0), hip + Vector2(10, 4), hip + Vector2(6, 9), hip + Vector2(2, 5), hip + Vector2(-3, 10), hip + Vector2(-8, 4)])
	Art.fill_shaded(z, pts, poncho, 0.15, 0.4)
	z.draw_line(sh + Vector2(-6, 5), hip + Vector2(-4, 2), col(Color(0.3, 0.2, 0.1, 0.35)), 2.0)   # בוץ
	if hanging:
		head = sh + Vector2(0.5, -7.5)
	Art.oval_shaded(z, head, 5.4 if hanging else 5.0, 6.0 if hanging else 5.8, sk, 0.0)
	if hanging:   # ברדס מלפנים (פנים למעלה)
		Art.fill(z, PackedVector2Array([head + Vector2(-6.5, 3), head + Vector2(-6, -4), head + Vector2(0, -8), head + Vector2(6, -4), head + Vector2(6.5, 3), head + Vector2(4.5, -2.5), head + Vector2(0, -5), head + Vector2(-4.5, -2.5)]), Art.shade(poncho, 0.15), Art.OUTLINE, 0.9)
	else:
		Art.fill(z, PackedVector2Array([head + Vector2(-6, 3), head + Vector2(-5, -5), head + Vector2(1, -7), head + Vector2(5, -5), head + Vector2(0, -3), head + Vector2(-2, 4)]), Art.shade(poncho, 0.15), Art.OUTLINE, 0.9)   # ברדס
	if not z.dead:
		if hanging:   # שתי עיניים זוהרות שמביטות למעלה, פה פעור
			z.draw_circle(head + Vector2(-2.0, -1.5), 1.1, Color(0.95, 1.0, 0.6))
			z.draw_circle(head + Vector2(2.2, -1.5), 1.1, Color(0.95, 1.0, 0.6))
			z.draw_colored_polygon(Art.ellipse(head + Vector2(0.2, 2.5), 1.6, 2.0, 0.0, 8), col(Color("1a0e0a")))
		else:
			z.draw_circle(head + Vector2(3.0, -0.5), 1.0, Color(0.75, 0.8, 0.5))
			z.draw_line(head + Vector2(1, 3), head + Vector2(5, 3.5), col(Color("2a1a14")), 1.2)
	if not hanging:
		z._arm(sh + Vector2(3, 1), hf, sk, poncho)
	for q in 3:   # אצבעות ארוכות
		z.draw_line(hf, hf + Vector2.from_angle(-PI * 0.5 + float(q - 1) * 0.45) * 4.0, sk, 1.1)
		if hanging:
			z.draw_line(hb, hb + Vector2.from_angle(-PI * 0.5 + float(q - 1) * 0.45) * 4.0, sk, 1.1)
	end_draw()
	return true
