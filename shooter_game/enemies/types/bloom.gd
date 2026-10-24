extends "res://enemies/zombie_type.gd"
# ============================================================
#  BLOOM (שלב 60, "GLACIER LAB") - מושבת ECHO שמרחפת כמו מדוזה: פעמון שקוף של סיבי פטרייה, שוליים מסולסלים,
#    זרועות חוטים ארוכות שמשתלשלות למטה, ו-N_NODES קשריות זוהרות (ירוק ECHO) על הפעמון. שוחה בפעימות (PULSE_T).
#  מה הוא למד, וממה: זה הלימוד עצמו, בגוף אחד. הכוורת למדה מהמעבדה איך מלמדים - ועכשיו היא מלמדת בגלוי.
#    "IT TEACHES THEM NOW": מרחפת מעל הזומבים (TEACH_R) ומחברת אליהם חוטים זוהרים. מי שמתחת לה "לומד" במקום:
#    מהר יותר (x TEACH_SPEED), מתכופף יותר (+ TEACH_DUCK), טבעת "למד" (effects/spore_lesson.gd) עפה אליו מהקשריות.
#    השיעור נשאר עוד LINGER_MS אחרי שהוא יוצא מתחתיה. הורגים את ה-BLOOM -> "THE LESSON BREAKS": כולם חוזרים לרגיל.
#  פגיעה: הפעמון ספוגי (x BELL_MULT). הקשריות = נקודות התורפה (x NODE_MULT, קרן מנקודת הפגיעה כמו MURMUR).
#    כל NODE_HP נזק = קשרית מתפוצצת. בלי קשריות = מת. פיצוץ x BLAST_MULT.
#  כמעט לא תוקף: STING - כשאתה ממש מתחתיה (STING_R) הזרועות זוהרות (STING_TELL) ומצליפות למטה: נזק + האטה.
#  לומד (main meta "blm_kills" >= LEARN_KILLS): "IT HIDES BEHIND THEM NOW" - אחרי שהוא מאבד קשרית, יורד ומסתתר מאחורי
#    התלמיד הקרוב (התלמיד בינך לבינו) או עולה לתקרה (HIDE_T), ורק אז חוזר ללמד.
#  ביצועים: אין צמתים לכל קשרית / חוט. התנועה בלי move_and_slide (מיקום ישיר, כמו MURMUR). הכל ב-draw call אחד.
#  לשנות: N_NODES, NODE_HP, NODE_R, *_MULT, HOVER_H, PULSE_T, PULSE_V, TEACH_*, LINGER_MS, STING_*, HIDE_T, LEARN_KILLS.
# ============================================================

const Lesson := preload("res://effects/spore_lesson.gd")

const SOUNDS := {
	"blm_pulse": {"rev": 0.4, "layers": [["N", 0, 0, 0.0, 0.45, 0.12, 3.0, 0.25, 0.12, 0, 0.05], ["S", 70, 55, 0.0, 0.4, 0.1, 3.0, 0.2, 1.0, 0.0]]},
	"blm_teach": {"rev": 0.6, "layers": [["S", 880, 1320, 0.0, 0.5, 0.05, 3.5, 0.12, 1.0, 0.02], ["S", 1320, 1760, 0.08, 0.5, 0.05, 3.5, 0.1, 1.0, 0.02]]},
	"blm_pop": {"drive": 1.8, "layers": [["N", 0, 0, 0.0, 0.12, 0.0, 18.0, 0.6, 0.4, 0, 0.1], ["S", 520, 140, 0.0, 0.15, 0.0, 14.0, 0.5, 1.0, 0], ["S", 1500, 900, 0.0, 0.1, 0.0, 20.0, 0.15, 1.0, 0]]},
	"blm_sting": {"drive": 2.0, "layers": [["N", 0, 0, 0.0, 0.25, 0.0, 10.0, 0.5, 1.0, 0, 0.5], ["S", 1800, 400, 0.0, 0.25, 0.0, 9.0, 0.3, 1.0, 0.1]]},
	"blm_die": {"rev": 0.5, "layers": [["N", 0, 0, 0.0, 1.0, 0.0, 2.5, 0.5, 0.2, 0, 0.05], ["S", 300, 60, 0.0, 1.0, 0.0, 2.5, 0.4, 1.0, 0.05], ["S", 1320, 660, 0.0, 0.8, 0.0, 3.0, 0.12, 1.0, 0.0]]},
}

const N_NODES := 6
const NODE_HP := 13
const NODE_R := 12.0
const NODE_MULT := 1.6
const BELL_MULT := 0.45
const BLAST_MULT := 2.0
const HEAD_NORM := 0.4             # "ראש" / "רגל" לא אומרים כלום במדוזה: מנרמלים
const LEG_NORM := 1.4
const OFF := 30.0                  # z.global_position = מרכז הפעמון + (0, OFF)
const BELL := Vector2(34.0, 24.0)
const HOVER_H := 215.0             # גובה מעל הרצפה
const LOW_H := 72.0                # (למד) מסתתר מאחורי תלמיד
const CEIL_H := 440.0              # ...או עולה לתקרה
const WAKE_R := 950.0
const PULSE_T := 1.1
const PULSE_V := 150.0
const DRAG := 1.5
const TEACH_R := 230.0
const TEACH_SPEED := 1.35
const TEACH_DUCK := 0.3
const TEACH_EVERY := 0.4
const FLASH_EVERY := 1.6
const LINGER_MS := 2500
const MAX_STUDENTS := 6
const STING_R := 64.0
const STING_TELL := 0.6
const STING_DMG := 1
const STING_SLOW := 1.2
const STING_CD := 3.5
const HIDE_T := 2.3
const LEARN_KILLS := 2
const COL := Color(0.75, 1.0, 0.55)
const NODE_P := [Vector2(-24.0, 4.0), Vector2(-14.0, -12.0), Vector2(1.0, -18.0), Vector2(16.0, -12.0), Vector2(25.0, 3.0), Vector2(0.0, -2.0)]

enum {IDLE, SWIM, TELL, STING, HIDE}
var state := IDLE
# לבדיקות
var taught := 0
var flashes := 0
var stings := 0
var sting_hits := 0
var hides := 0
var nodes_popped := 0
var node_hits := 0
var bell_hits := 0

var learned := false
var center := Vector2.ZERO
var vel := Vector2.ZERO
var students: Array = []
var alive := PackedByteArray()
var _ground := 630.0
var _t := 0.0
var _st := 0.0
var _phase := 0.0
var _teach_t := 0.0
var _flash_t := 0.6
var _sting_cd := 2.0
var _target := Vector2.ZERO
var _tgt_t := 0.0
var _node_flag := -1
var _blast := false
var _pending := -1
var _pending_pos := Vector2.ZERO
var _pop := -1.0                   # טבעת קשרית שהתפוצצה
var _pop_pos := Vector2.ZERO
var _hide_x := 0.0
var _hide_y := 0.0
var _said := false
var _seed := 0.0
var _whip := 0.0                   # הצלפה (ציור)


func stats() -> Dictionary:
	return {"name": "BLOOM", "hp": N_NODES * NODE_HP, "walk": 60.0, "chase": 90.0, "damage": 1, "bite_delay": 1.0, "scale": 1.0, "width": 1.19,
		"duck": 0.0, "cover": 0.0, "skin": Color("7a8a6a"), "shirt": Color("4a5a3a"), "pants": Color("2a3020"), "shoe": Color("2a3020"),
		"points": 520, "ragdoll": false, "flesh": false}


func use_brain_movement() -> bool:
	return false


func can_bite() -> bool:
	return false


func can_groan() -> bool:
	return false


func death_sound() -> String:
	return "blm_die"


func _main() -> Node:
	return z.get_parent()


func setup() -> void:
	var m := _main()
	learned = m != null and int(m.get_meta("blm_kills", 0)) >= LEARN_KILLS
	_ground = z.global_position.y
	_seed = float(z.get_instance_id() % 997) * 0.37
	alive.resize(N_NODES)
	alive.fill(1)
	z.hp = N_NODES * NODE_HP
	z.max_hp = z.hp
	z._dir = 1.0
	center = z.global_position + Vector2(0.0, -HOVER_H - 40.0)
	_target = center
	z.global_position = center + Vector2(0.0, OFF)
	var rs := z._shape.shape as RectangleShape2D
	rs.size = Vector2(BELL.x * 2.2, BELL.y * 2.2)
	z._shape.position = Vector2(0.0, -OFF)
	z.collision_mask = 0   # לא נתקע בקירות / קומות (המיקום נקבע ישירות)


func _n_alive() -> int:
	var n := 0
	for i in N_NODES:
		n += int(alive[i])
	return n


# הקשרית בעולם (מרחפת עם פעימת הפעמון)
func node_pos(i: int) -> Vector2:
	var sq := _squeeze()
	var p: Vector2 = NODE_P[i]
	return center + Vector2(p.x * (1.0 - sq * 0.35), p.y * (1.0 + sq * 0.25)) * z.sc


func _squeeze() -> float:   # 0..1: הפעמון מתכווץ בתחילת כל פעימה
	var k := fposmod(_phase, 1.0)
	if state == TELL:
		return 0.6 + 0.2 * sin(_t * 30.0)
	return sin(clampf(k / 0.3, 0.0, 1.0) * PI) if k < 0.3 else 0.0


# ============================================================
#  תנועה
# ============================================================
func physics(pl: Node, delta: float) -> bool:
	_t += delta
	_st -= delta
	_sting_cd -= delta
	_whip -= delta
	if _pop >= 0.0:
		_pop += delta
		if _pop > 0.4:
			_pop = -1.0
	_sync()
	if z.dead:
		return false
	if not learned and Engine.get_physics_frames() % 30 == 0:   # לומד גם באמצע השלב
		var m := _main()
		learned = m != null and int(m.get_meta("blm_kills", 0)) >= LEARN_KILLS
	var has: bool = pl != null and not pl.dead
	var pp: Vector2 = pl.global_position if has else center + Vector2(0.0, HOVER_H)
	var d: Vector2 = pp - center
	match state:
		IDLE:
			center += Vector2(sin(_t * 0.4 + _seed) * 14.0, cos(_t * 0.6 + _seed) * 6.0) * delta
			_phase += delta / (PULSE_T * 1.5)
			if has and absf(d.x) < WAKE_R and absf(d.y) < 700.0:
				state = SWIM
				var m := _main()
				if m != null and not m.has_meta("blm_seen"):
					m.set_meta("blm_seen", true)
		SWIM:
			_swim(pl, has, pp, delta)
			if has and _sting_cd <= 0.0 and absf(d.x) < STING_R and d.y > 40.0 and d.y < HOVER_H + 80.0:
				state = TELL
				_st = STING_TELL
				Sfx.play("blm_sting", center, -6.0, 0.1, 2, 0.6)
		TELL:
			vel = vel.move_toward(Vector2.ZERO, 300.0 * delta)
			center += vel * delta
			_phase += delta / PULSE_T * 0.3
			if _st <= 0.0:
				state = STING
				stings += 1
				_st = 0.25
				_whip = 0.3
				Sfx.play("blm_sting", center, 0.0, 0.1, 2)
				if has and absf(pp.x - center.x) < STING_R * 0.75 + 12.0 and pp.y > center.y:
					sting_hits += 1
					pl.hurt(STING_DMG, Vector2(signf(pp.x - center.x + 0.01) * 0.6, -0.2))
					pl.slow_t = maxf(float(pl.slow_t), STING_SLOW)
		STING:
			if _st <= 0.0:
				state = SWIM
				_sting_cd = STING_CD
		HIDE:
			_swim(pl, has, Vector2(_hide_x, _hide_y + HOVER_H), delta, true)
			if _st <= 0.0:
				state = SWIM
	# הגבולות: לא מתחת לרצפה, לא מעל התקרה, לא דרך דלת הדף סגורה
	center.y = clampf(center.y, _ground - CEIL_H - 20.0, _ground - LOW_H + 10.0)
	center.x = clampf(center.x, 40.0, z.world_w - 40.0)
	if Engine.get_physics_frames() % 6 == 0:
		_doors()
	z.global_position = center + Vector2(0.0, OFF)
	z.velocity = Vector2.ZERO
	_teach_t -= delta
	if _teach_t <= 0.0:
		_teach_t = TEACH_EVERY
		_teach(pl)
	return true


func _swim(pl: Node, has: bool, pp: Vector2, delta: float, hiding := false) -> void:
	_tgt_t -= delta
	if hiding:
		_target = Vector2(_hide_x, _hide_y)
	elif _tgt_t <= 0.0:
		_tgt_t = 0.5
		_target = _pick_target(pl, has, pp)
	var prev := fposmod(_phase, 1.0)
	_phase += delta / (PULSE_T * (0.7 if hiding else 1.0))
	if fposmod(_phase, 1.0) < prev:   # פעימה: דחיפה אל המטרה
		var to := _target - center
		var k := clampf(to.length() / 220.0, 0.25, 1.6)
		vel += to.normalized() * PULSE_V * k * (1.5 if hiding else 1.0)
		if Art.on_screen(z, center) and randf() < 0.35:
			Sfx.play("blm_pulse", center, -10.0, 0.15, 2)
	vel *= exp(-DRAG * delta)
	vel.y += 10.0 * delta   # שוקע לאט בין פעימות
	center += vel * delta


# מעל התלמידים (ממוצע), אחרת מעליך בצד
func _pick_target(pl: Node, has: bool, pp: Vector2) -> Vector2:
	var sx := 0.0
	var n := 0
	for s in students:
		if is_instance_valid(s) and not s.dead:
			sx += s.global_position.x
			n += 1
	var tx: float = sx / float(n) if n > 0 else pp.x + (-150.0 if center.x < pp.x else 150.0)
	if n == 0 and has:   # מחפש תלמידים ליד הגיבור
		var best = null
		var bd := 700.0
		for o in z.get_tree().get_nodes_in_group("zombies"):
			if not _can_teach(o):
				continue
			var dd: float = absf(o.global_position.x - center.x)
			if dd < bd and absf(o.global_position.x - pp.x) < 800.0:
				bd = dd
				best = o
		if best != null:
			tx = best.global_position.x
	var h := HOVER_H + sin(_t * 0.5 + _seed) * 25.0
	return Vector2(tx, _ground - h)


func _doors() -> void:
	for dn in z.get_tree().get_nodes_in_group("s60_doors"):
		if not dn.is_closed():
			continue
		var dx: float = dn.global_position.x
		if (center.x - dx) * (_target.x - dx) < 0.0:
			_target.x = dx + signf(center.x - dx) * 70.0
		if absf(center.x - dx) < 46.0:
			center.x = dx + signf(center.x - dx + 0.01) * 46.0
			vel.x = 0.0


func _can_teach(o) -> bool:
	if o == z or o.dead or o.dormant or o.is_boss() or o.kind == z.kind:
		return false
	if o.type_mod != null and o.type_mod.has_method("in_tank") and o.type_mod.in_tank():
		return false
	return true


# ============================================================
#  מלמד: מי שמתחתיו - מהר יותר, מתכופף יותר. טבעת "למד" עפה אליו מהקשריות
# ============================================================
func _teach(pl: Node) -> void:
	var now := Time.get_ticks_msec()
	var keep: Array = []
	for s in students:   # השיעור נגמר?
		if not is_instance_valid(s) or s.dead:
			continue
		if int(s.get_meta("blm_until", 0)) < now:
			_restore(s)
		else:
			keep.append(s)
	students = keep
	if state == IDLE or _n_alive() == 0:
		return
	var added := false
	for o in z.get_tree().get_nodes_in_group("zombies"):
		if keep.size() >= MAX_STUDENTS:
			break
		if not _can_teach(o):
			continue
		var dx: float = absf(o.global_position.x - center.x)
		var dy: float = o.global_position.y - center.y
		if dx > TEACH_R or dy < 30.0 or dy > HOVER_H + 200.0:
			continue
		if not o.has_meta("blm_base"):
			o.set_meta("blm_base", [o.chase_speed, o.walk_speed, o.duck_chance])
			o.chase_speed *= TEACH_SPEED
			o.walk_speed *= TEACH_SPEED * 0.9
			o.duck_chance = minf(float(o.duck_chance) + TEACH_DUCK, 0.9)
			taught += 1
			added = true
		o.set_meta("blm_until", now + LINGER_MS)
		if not (o in students):
			students.append(o)
	if added and not _said:
		_said = true
		var m := _main()
		if m != null and not m.has_meta("blm_said"):
			m.set_meta("blm_said", true)
			z._popup("IT TEACHES THEM NOW", Color("b8ff9a"), 13, -100.0)
	_flash_t -= TEACH_EVERY
	if _flash_t <= 0.0 and not students.is_empty():
		_flash_t = FLASH_EVERY
		_send_flash(students.pick_random())


func _send_flash(s: Node) -> void:
	if Lesson.live >= Lesson.MAX_LIVE or not Art.on_screen(z, center, 60.0):
		return
	var idx := []
	for i in N_NODES:
		if alive[i] == 1:
			idx.append(i)
	if idx.is_empty():
		return
	var from := node_pos(int(idx.pick_random()))
	var fx = Lesson.new()
	fx.target = s
	fx._from = from
	fx.global_position = from
	fx.z_index = 30
	_main().add_child(fx)
	flashes += 1
	Sfx.play("blm_teach", center, -10.0, 0.1, 2)


func _restore(s: Node) -> void:
	if not s.has_meta("blm_base"):
		return
	var b: Array = s.get_meta("blm_base")
	s.chase_speed = float(b[0])
	s.walk_speed = float(b[1])
	s.duck_chance = float(b[2])
	s.remove_meta("blm_base")
	s.remove_meta("blm_until")


# ============================================================
#  פגיעות: קשריות (נקודות תורפה) / פעמון ספוגי
# ============================================================
func _ray_node(lp: Vector2, dir: Vector2) -> int:
	var best := -1
	var ba := INF
	for i in N_NODES:
		if alive[i] == 0:
			continue
		var rel := node_pos(i) - center - lp
		if dir == Vector2.ZERO:
			if rel.length() < NODE_R * 1.3 and rel.length() < ba:
				ba = rel.length()
				best = i
			continue
		var along := rel.dot(dir)
		if along < -NODE_R:
			continue
		if absf(rel.cross(dir)) < NODE_R and along < ba:
			ba = along
			best = i
	return best


func _nearest(p: Vector2) -> int:
	var best := -1
	var bd := INF
	for i in N_NODES:
		if alive[i] == 1:
			var dd := node_pos(i).distance_squared_to(p)
			if dd < bd:
				bd = dd
				best = i
	return best


func on_damage(_amount: int, hit_pos: Vector2, dir: Vector2, src: Dictionary) -> bool:
	if z.dead:
		return true
	var s := str(src.get("source", "bullet"))
	_node_flag = -1
	_blast = false
	if s == "bullet" or s == "melee" or s == "laser":
		var ni := _ray_node(hit_pos - center, dir if s != "melee" else Vector2.ZERO)
		if ni >= 0:
			_node_flag = ni
			_pending = ni
			node_hits += 1
		else:
			bell_hits += 1
			_pending_pos = hit_pos
	elif s != "fire" and s != "taser":
		_blast = true
		_pending_pos = hit_pos
		vel += (center - hit_pos).normalized() * 160.0
	return true


func damage_mult(zone: String, src: Dictionary) -> float:
	var s := str(src.get("source", "bullet"))
	var m := 1.0
	if _blast:
		_blast = false
		return BLAST_MULT
	if s == "bullet" or s == "melee":
		if zone == "head":
			m = HEAD_NORM
		elif zone == "leg":
			m = LEG_NORM
	if _node_flag >= 0:
		_node_flag = -1
		return m * NODE_MULT
	return m * BELL_MULT


# כמה קשריות חיות לפי החיים: מפוצצים את מה שנפגע (או הקרובה לפגיעה)
func _sync() -> void:
	var target := int(ceil(float(maxi(z.hp, 0)) / float(NODE_HP)))
	var guard := 0
	while _n_alive() > target and guard < N_NODES:
		guard += 1
		var i := _pending if _pending >= 0 and alive[_pending] == 1 else _nearest(_pending_pos)
		if i < 0:
			break
		_pending = -1
		_pop_node(i)


func _pop_node(i: int) -> void:
	alive[i] = 0
	nodes_popped += 1
	_pop = 0.0
	_pop_pos = node_pos(i)
	vel += Vector2(randf_range(-60.0, 60.0), -90.0)
	if Art.on_screen(z, _pop_pos):
		Particles.burst(_main(), _pop_pos, "mist", Vector2.UP, 3)
		Particles.burst(_main(), _pop_pos, "spark", Vector2.UP, 3)
		Sfx.play("blm_pop", _pop_pos, -2.0, 0.15, 3)
	if z.dead or z.hp <= 0:
		return
	if learned:
		_hide()


# (למד) מסתתר: מאחורי התלמיד הקרוב (התלמיד בינך לבינו), אחרת לתקרה
func _hide() -> void:
	var pl := player() as Node2D
	if pl == null:
		return
	state = HIDE
	hides += 1
	_st = HIDE_T
	var best = null
	var bd := 420.0
	for s in students:
		if is_instance_valid(s) and not s.dead:
			var dd: float = absf(s.global_position.x - center.x)
			if dd < bd:
				bd = dd
				best = s
	if best != null:
		var side: float = signf(best.global_position.x - pl.global_position.x)
		_hide_x = best.global_position.x + side * 46.0
		_hide_y = _ground - LOW_H
	else:
		_hide_x = center.x + signf(center.x - pl.global_position.x + 0.01) * 80.0
		_hide_y = _ground - CEIL_H
	var m := _main()
	if m != null and not m.has_meta("blm_hide_said"):
		m.set_meta("blm_hide_said", true)
		z._popup("IT HIDES BEHIND THEM NOW", Color("b8ff9a"), 13, -100.0)


func on_death() -> void:
	var m := _main()
	if m != null:
		m.set_meta("blm_kills", int(m.get_meta("blm_kills", 0)) + 1)
	var had := not students.is_empty()
	for s in students:
		if is_instance_valid(s) and not s.dead:
			_restore(s)
	students.clear()
	for i in N_NODES:
		if alive[i] == 1:
			_pop_pos = node_pos(i)
			Particles.burst(m, _pop_pos, "mist", Vector2.UP, 2)
		alive[i] = 0
	Particles.burst(m, center, "mist", Vector2.UP, int(6.0 * Quality.particles()) + 2)
	Particles.burst(m, center, "drop", Vector2.DOWN, int(8.0 * Quality.gore()) + 2)
	z._popup("THE LESSON BREAKS" if had else "BLOOM DOWN", Color("b8ff9a"), 13, -60.0)
	z.velocity = vel * 0.3
	z.collision_mask = 1 | 16


func wants_redraw() -> bool:
	return true


# ============================================================
#  ציור: (0,0) של הזומבי = מרכז הפעמון + (0, OFF). החוטים לתלמידים - בקואורדינטות העולם (בלי היפוך).
# ============================================================
func draw() -> bool:
	if alive.is_empty():
		return false
	var c := Vector2(0.0, -OFF)
	var tt := _t
	if z.dead:
		_draw_dead()
		return true
	# חוטי לימוד אל התלמידים (לפני הפעמון)
	DrawBatch.set_transform_matrix(z, Transform2D.IDENTITY)
	var pulse := 0.55 + 0.45 * sin(tt * 4.0)
	var k0 := 0
	for s in students:
		if not is_instance_valid(s) or s.dead:
			continue
		var a: Vector2 = node_pos(k0 % N_NODES) - z.global_position
		k0 += 1
		var b: Vector2 = s.global_position - z.global_position + Vector2(0.0, -46.0 * float(s.sc))
		var mid := a.lerp(b, 0.5) + Vector2(sin(tt * 3.0 + float(k0)) * 12.0, 10.0)
		DrawBatch.polyline(z, PackedVector2Array([a, a.lerp(mid, 0.5) + Vector2(0, 4), mid, mid.lerp(b, 0.5), b]), Color(COL, 0.22 + 0.25 * pulse), 1.4)
		DrawBatch.circle(z, b, 2.5 + pulse * 1.5, Color(COL, 0.5 * pulse))
	begin_draw(false)
	var sq := _squeeze()
	var rx := BELL.x * (1.0 - sq * 0.3)
	var ry := BELL.y * (1.0 + sq * 0.25)
	# זרועות החוטים (מתחת לפעמון)
	var reach := 1.0
	var glow_t := 0.0
	if state == TELL:
		glow_t = 1.0 - clampf(_st / STING_TELL, 0.0, 1.0)
		reach = 1.0 + glow_t * 0.4
	if _whip > 0.0:
		reach = 2.6
		glow_t = 1.0
	for i in 7:
		var u := float(i) / 6.0
		var x0 := (u - 0.5) * rx * 1.6
		var ln := (54.0 + 30.0 * absf(sin(float(i) * 1.7 + _seed))) * reach
		var sway := sin(tt * 1.6 + float(i) * 0.9 + _seed) * 9.0
		var p0 := c + Vector2(x0, ry * 0.25)
		var p1 := p0 + Vector2(sway * 0.4 + x0 * 0.1, ln * 0.35)
		var p2 := p0 + Vector2(sway, ln * 0.7)
		var p3 := p0 + Vector2(sway * 1.4 - x0 * 0.15, ln)
		var tc := Color(0.55, 0.7, 0.45, 0.55).lerp(Color(COL, 0.9), glow_t)
		DrawBatch.polyline(z, PackedVector2Array([p0, p1, p2, p3]), col(tc), 1.6 - u * 0.3 if i % 2 == 0 else 1.0)
		if i % 2 == 1:
			DrawBatch.circle(z, p3, 1.3, Color(COL, 0.4 + 0.5 * glow_t))
	# זרועות הפה (רצועות עבות במרכז)
	for i in 2:
		var sx := -5.0 + float(i) * 10.0
		var sw := sin(tt * 1.2 + float(i) * 2.0) * 6.0
		DrawBatch.polyline(z, PackedVector2Array([c + Vector2(sx, ry * 0.2), c + Vector2(sx + sw * 0.5, 22.0), c + Vector2(sx + sw, 40.0 * reach)]), col(Color(0.5, 0.62, 0.42, 0.7)), 3.0)
	# הפעמון: כיפה שקופה של סיבים, שוליים מסולסלים
	var dome := PackedVector2Array()
	for q in 15:
		var a := PI + PI * float(q) / 14.0
		dome.append(c + Vector2(cos(a) * rx, sin(a) * ry + ry * 0.25))
	for q in 9:   # שוליים מסולסלים (מימין לשמאל)
		var u := 1.0 - float(q) / 8.0
		dome.append(c + Vector2((u - 0.5) * 2.0 * rx * 0.98, ry * 0.25 + (3.0 if q % 2 == 0 else 0.0) + sin(tt * 3.0 + float(q)) * 1.0))
	DrawBatch.colored_polygon(z, dome, col(Color(0.42, 0.55, 0.38, 0.55)))
	Art.glow(z, c + Vector2(0.0, -2.0), 20.0, Color(COL, 0.18 + 0.12 * pulse))
	# סיבים מהקודקוד אל השוליים
	for q in 7:
		var u := float(q) / 6.0
		var e := c + Vector2((u - 0.5) * 2.0 * rx * 0.9, ry * 0.2)
		var top := c + Vector2((u - 0.5) * rx * 0.3, -ry * 0.92)
		DrawBatch.line(z, top, e, col(Color(0.7, 0.82, 0.6, 0.45)), 0.9)
	# קו המתאר + ברק
	var rim := PackedVector2Array()
	for q in 15:
		var a := PI + PI * float(q) / 14.0
		rim.append(c + Vector2(cos(a) * rx, sin(a) * ry + ry * 0.25))
	DrawBatch.polyline(z, rim, col(Color(0.82, 0.95, 0.75, 0.7)), 1.4)
	DrawBatch.arc(z, c + Vector2(-rx * 0.3, -ry * 0.25), rx * 0.45, PI * 1.1, PI * 1.5, 6, Color(1, 1, 1, 0.35), 1.6)
	# הקשריות
	for i in N_NODES:
		var np: Vector2 = node_pos(i) - z.global_position
		if alive[i] == 1:
			var pk := 0.6 + 0.4 * sin(tt * 5.0 + float(i) * 1.3)
			Art.glow(z, np, 9.0 + 2.0 * pk, Color(COL, 0.4 * pk + 0.15))
			DrawBatch.circle(z, np, 4.2, col(Color(0.6, 0.85, 0.4)))
			DrawBatch.circle(z, np, 2.4, Color(0.92, 1.0, 0.8, 0.7 + 0.3 * pk))
		else:   # פצע: קשרית שהתפוצצה
			DrawBatch.circle(z, np, 3.4, col(Color(0.18, 0.2, 0.12, 0.9)))
			DrawBatch.circle(z, np + Vector2(0.5, 0.8), 1.6, Color(0.4, 0.05, 0.05, 0.8))
	end_draw()
	if _pop >= 0.0:
		var k := _pop / 0.4
		DrawBatch.arc(z, _pop_pos - z.global_position, 6.0 + 26.0 * k, 0.0, TAU, 16, Color(COL, 0.8 * (1.0 - k)), 2.0)
	return true


func _draw_dead() -> void:
	# נפל: פעמון מקומט על הרצפה, החוטים פרושים, הקשריות כבויות
	DrawBatch.set_transform_matrix(z, Transform2D.IDENTITY)
	var g: bool = z.is_on_floor()
	var c := Vector2(0.0, -6.0) if g else Vector2(0.0, -OFF)
	var rx := BELL.x * (1.15 if g else 0.9)
	var ry := BELL.y * (0.35 if g else 0.8)
	for i in 6:
		var a := -0.3 - float(i) * 0.5
		var p0 := c + Vector2((float(i) - 2.5) * 8.0, 0.0)
		var p1 := p0 + Vector2(cos(a) * 30.0 if g else (float(i) - 2.5) * 4.0, 4.0 if g else 40.0)
		DrawBatch.line(z, p0, p1, Color(0.4, 0.5, 0.35, 0.6), 1.2)
	DrawBatch.colored_polygon(z, Art.ellipse(c, rx, ry, 0.0, 16), Color(0.36, 0.45, 0.32, 0.7))
	for i in N_NODES:
		DrawBatch.circle(z, c + Vector2((float(i) - 2.5) * 9.0, -ry * 0.3), 2.2, Color(0.2, 0.24, 0.16, 0.9))
