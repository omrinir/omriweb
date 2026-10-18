extends "res://enemies/zombie_type.gd"
# ============================================================
#  STATIONARY BOSS - בסיס לבוסים ענקיים שלא זזים ממקומם (משלב 34): זורקים / יורים.
#  יורש: enemies/types/<boss>.gd -> extends "res://enemies/stationary_boss.gd"
#    * לא זז (רק מסתובב אליך). think(pl, delta) = מה לעשות. eye() = מאיפה יורה.
#    * wind(name, t) -> אזהרה של t שניות -> attack(name, pl) (מימוש אצל היורש).
#    * fire_shot(...) = קליע ישר (Shot), fire_lob(...) = קשת שנוחתת (Lob, יכול להתפוצץ).
#    * weak_rect() = נקודת התורפה (מקומי, לפני הגדלה): פגיעה בה x WEAK_MULT, בשאר הגוף x ARMOR_MULT.
#  "THEY LEARN":
#    * lead: כל פספוס מלמד אותו לירות לאן שאתה הולך (כיוון מקדים לפי המהירות שלך).
#    * learned_lob: מתחבא מאחורי מחסה יותר מ-HIDE_LEARN שניות -> עובר לזריקות בקשת מעל המחסה.
#    * צמוד אליו (POUND_R) -> מכת קרקע שזורקת אותך אחורה.
#  לשנות: WEAK_MULT, ARMOR_MULT, HIDE_LEARN, POUND_R, POUND_CD.
# ============================================================

const WEAK_MULT := 1.5
const ARMOR_MULT := 0.6
const HIDE_LEARN := 1.3
const POUND_R := 110.0
const POUND_CD := 2.5

var learned_lob := false
var lead := 0.0              # 0..1 - כמה הוא מקדים (לומד מפספוסים)
var shots := 0               # לבדיקות
var shot_hits := 0
var misses := 0
var pounds := 0
var hidden_t := 0.0
var winding := ""            # שם ההתקפה שבהכנה ("" = אין)
var _wind_t := 0.0
var _wind_max := 1.0
var _vis := true
var _vis_t := 0.0
var _pound_cd := 1.0
var _last_hit := Vector2.ZERO
var _cover_pt := Vector2.INF


func _boss() -> bool:
	return z != null and float(z.chase_range) > 600.0


func setup() -> void:
	z.set_meta("pit_hop", false)
	_place.call_deferred()


const EDGE := 720.0   # כמה רחוק מסוף השלב הוא עומד (שייראה כולו על המסך, ויהיה מקום מאחוריו)


# אזור הפגיעה (ברירת מחדל של zombie.gd: 38*wf רוחב, 66*sc גובה). בוס רחב (רכבת / טנק) מגדיל אותו כדי שכל הציור ייפגע
func hit_size() -> Vector2:
	return Vector2(38.0 * z.wf, maxf(66.0, -weak_rect().position.y + 2.0) * z.sc)   # גבוה מספיק כדי לכלול את נקודת התורפה


# נקודת התורפה היא הדבר הכי קדמי בגובה שלה (ראש / מפקד / חלון)? אז קליע שפוגע בצד של אזור הפגיעה בגובה הזה = פגיעה בה.
# (הקליע נעצר בשפת אזור הפגיעה, לא בתוך הציור.) בוס שהנקודה שלו מאחור / למעלה (מנוע) מחזיר false.
func weak_on_face() -> bool:
	return true


func can_turn() -> bool:   # בוס שלא יכול להסתובב (PROTOTYPE - מוברג לפס הייצור)
	return true


func floats() -> bool:   # בוס מרחף (RED ZEPPELIN)
	return false


func _place() -> void:
	if z != null and is_instance_valid(z) and z._shape != null:
		var r := z._shape.shape as RectangleShape2D
		r.size = hit_size()
		z._shape.position = Vector2(0.0, -r.size.y * 0.5)
	if z != null and is_instance_valid(z) and z.world_w < 90000.0:
		z.global_position.x = minf(z.global_position.x, float(z.world_w) - EDGE)
		var main: Node = z.get_parent()
		if main.has_meta("boss_x"):   # השלב קובע איפה הוא עומד (למשל על גג)
			z.global_position.x = float(main.get_meta("boss_x"))
		if main.has_meta("boss_y"):
			z.global_position.y = float(main.get_meta("boss_y"))
			z.velocity = Vector2.ZERO


func can_bite() -> bool:
	return false


func can_groan() -> bool:
	return true


# ---- לממש אצל היורש ----
func think(_pl: Node, _delta: float) -> void:
	pass


func attack(_name: String, _pl: Node) -> void:
	pass


func eye() -> Vector2:   # מאיפה יורה (עולם)
	return z.global_position + Vector2(z._dir * 20.0, -60.0) * z.sc


func weak_rect() -> Rect2:   # מקומי (לפני הגדלה, כיוון ימינה)
	return Rect2(-8, -50, 16, 16)


# ---- נזק: נקודת תורפה / שריון ----
func on_damage(_amount: int, hit_pos: Vector2, _dir: Vector2, _src: Dictionary) -> bool:
	_last_hit = hit_pos
	return true


func in_weak(p: Vector2) -> bool:
	var l: Vector2 = (p - z.global_position) / z.sc
	l.x *= z._dir / maxf(float(z.wf), 0.1)   # (הציור מכווץ/מתרחב ב-wf לרוחב)
	var wr := weak_rect().grow(3.0)
	if wr.has_point(l):
		return true
	if not weak_on_face():
		return false
	var face: float = hit_size().x * 0.5 / (z.sc * maxf(float(z.wf), 0.1))
	return absf(absf(l.x) - face) < 2.5 and l.y >= wr.position.y and l.y <= wr.end.y


func damage_mult(_zone: String, src: Dictionary) -> float:
	var s := str(src.get("source", "bullet"))
	if not (s == "bullet" or s == "melee"):
		return 1.0
	return WEAK_MULT if in_weak(_last_hit) else ARMOR_MULT


# ---- הלולאה ----
func physics(pl: Node, delta: float) -> bool:
	if z.dead:
		return false
	z.velocity.x = 0.0
	if floats():   # (RED ZEPPELIN) מרחף - לא נופל
		z.velocity = Vector2.ZERO
	else:
		if not z.is_on_floor():
			z.velocity.y += z.gravity * delta
		z.move_and_slide()
	_pound_cd -= delta
	var has_pl: bool = pl != null and not pl.dead
	if not has_pl:
		return true
	var dx: float = pl.global_position.x - z.global_position.x
	if winding == "" and absf(dx) > 8.0 and can_turn():
		z._dir = signf(dx)
	_frame(pl, absf(dx) < 1150.0 and absf(pl.global_position.y - z.global_position.y) < 400.0)
	_vis_t -= delta
	if _vis_t <= 0.0:
		_vis_t = 0.2
		_vis = can_see(pl)
	if _vis:
		hidden_t = maxf(hidden_t - delta * 0.5, 0.0)
	else:
		hidden_t += delta
		if hidden_t > HIDE_LEARN and not learned_lob:
			learned_lob = true
			z._popup("IT LEARNED - HIDING WON'T HELP", Color("ff8060"), 15, -60.0 - 70.0 * z.sc)
	if winding != "":
		_wind_t -= delta
		if _wind_t <= 0.0:
			var w := winding
			winding = ""
			attack(w, pl)
		return true
	if _pound_cd <= 0.0 and absf(dx) < POUND_R * z.sc * 0.45 and absf(pl.global_position.y - z.global_position.y) < 60.0 * z.sc:
		wind("pound", 0.45)
		return true
	think(pl, delta)
	return true


# המצלמה מזיזה את עצמה כדי שהבוס הענק ייראו כולו (shake_camera.gd frame_target)
func _frame(pl: Node, on: bool) -> void:
	var cam = pl.get_viewport().get_camera_2d()
	if cam == null or not ("frame_target" in cam):
		return
	if on:
		cam.frame_target = z
		cam.frame_half = 36.0 * float(z.wf) * float(z.sc)
	elif cam.frame_target == z:
		cam.frame_target = null


func on_death() -> void:
	var pl := player()
	if pl != null:
		var cam = pl.get_viewport().get_camera_2d()
		if cam != null and ("frame_target" in cam) and cam.frame_target == z:
			cam.frame_target = null


func wind(name: String, t: float) -> void:
	winding = name
	_wind_t = t
	_wind_max = t
	if name == "pound":
		z._popup("!", Color("ff6040"), 20, -40.0 - 70.0 * z.sc)


func wind_k() -> float:   # 0 -> 1 במהלך ההכנה
	return 1.0 - clampf(_wind_t / maxf(_wind_max, 0.01), 0.0, 1.0) if winding != "" else 0.0


func do_pound(pl: Node) -> void:   # מכת קרקע (נקרא מ-attack("pound"))
	pounds += 1
	_pound_cd = POUND_CD
	Sfx.play("explosion", z.global_position, -4.0, 0.1, 2)
	Particles.burst(z.get_parent(), z.global_position, "smoke", Vector2.UP, 10)
	var cam: Camera2D = z.get_viewport().get_camera_2d()
	if cam != null and cam.has_method("shake"):
		cam.shake(10.0, 0.35)
	if pl != null and not pl.dead and absf(pl.global_position.x - z.global_position.x) < POUND_R * z.sc * 0.6 and absf(pl.global_position.y - z.global_position.y) < 60.0 * z.sc:
		pl.hurt(2, Vector2(signf(pl.global_position.x - z.global_position.x) * 3.0, -1.6))
		pl.velocity.x = signf(pl.global_position.x - z.global_position.x) * 560.0


# "רואה" אותך = אין מחסה בגובה המותניים בינך לבינו (קרן אופקית). מאחורי מחסה -> היריות הישרות פוגעות במחסה
func can_see(pl: Node) -> bool:
	var y: float = pl.global_position.y - 14.0
	var from := Vector2(z.global_position.x + z._dir * 30.0 * z.sc, y)
	var to := Vector2(pl.global_position.x, y)
	if signf(to.x - from.x) != z._dir:
		return true
	var q := PhysicsRayQueryParameters2D.create(from, to, 1)
	var ex: Array[RID] = [z.get_rid()]
	q.exclude = ex
	var hit: Dictionary = z.get_world_2d().direct_space_state.intersect_ray(q)
	if hit.is_empty() or hit.collider.is_in_group("zombies") or absf(hit.position.x - to.x) > 320.0:
		_cover_pt = Vector2.INF
		return true
	_cover_pt = Vector2(hit.position.x, y - 10.0)
	return false


# לאן לכוון: עם הקדמה לפי מהירות השחקן (lead לומד מפספוסים). מאחורי מחסה -> במחסה
func aim_point(pl: Node, speed: float) -> Vector2:
	if not _vis and _cover_pt != Vector2.INF:
		return _cover_pt
	var tgt: Vector2 = pl.global_position + Vector2(0, -24)
	var t := eye().distance_to(tgt) / maxf(speed, 1.0)
	return tgt + Vector2(pl.velocity.x, 0.0) * t * lead


func shot_result(hit: bool) -> void:
	if hit:
		shot_hits += 1
	else:
		misses += 1
		lead = clampf(float(misses) * 0.2, 0.0, 1.0)


func fire_shot(from: Vector2, target: Vector2, speed: float, dmg: int, kind: String, col := Color(1, 0.6, 0.2), r := 7.0) -> Node:
	shots += 1
	var s := Shot.new()
	s.owner_t = self
	s.velocity = (target - from).normalized() * speed
	s.damage = dmg
	s.kind = kind
	s.col = col
	s.r = r
	z.get_parent().add_child(s)
	s.global_position = from
	return s


func fire_lob(from: Vector2, target: Vector2, flight: float, dmg: int, kind: String, blast_r := 0.0, col := Color(1, 0.6, 0.2), r := 9.0) -> Node:
	shots += 1
	var l := Lob.new()
	l.owner_t = self
	l.damage = dmg
	l.kind = kind
	l.col = col
	l.r = r
	l.blast_r = blast_r
	l.velocity = Vector2((target.x - from.x) / flight, (target.y - from.y) / flight - 0.5 * l.gravity * flight)
	z.get_parent().add_child(l)
	l.global_position = from
	return l


# ============================================================
#  קליעים
# ============================================================
class Shot extends Node2D:
	const A := preload("res://art.gd")
	var owner_t = null
	var velocity := Vector2.ZERO
	var damage := 1
	var kind := "orb"
	var col := Color(1, 0.6, 0.2)
	var r := 7.0
	var _t := 0.0
	var _done := false

	func _ready() -> void:
		z_index = 9

	func _physics_process(delta: float) -> void:
		_t += delta
		var to := global_position + velocity * delta
		var pl := get_tree().get_first_node_in_group("player")
		if pl != null and not pl.dead and pl.body_rect().grow(r * 0.7).has_point(to):
			pl.hurt(damage, Vector2(signf(velocity.x) * 1.4, -0.6))
			_end(true)
			return
		var hit := get_world_2d().direct_space_state.intersect_ray(PhysicsRayQueryParameters2D.create(global_position, to, 1))
		if (not hit.is_empty() and not hit.collider.is_in_group("zombies")) or _t > 3.5:
			if not hit.is_empty():
				preload("res://particles.gd").burst(get_parent(), hit.position, "spark", -velocity.normalized(), 6)
			_end(false)
			return
		global_position = to
		rotation = velocity.angle()
		if A.on_screen(self, global_position, 60.0):   # (ביצועים: מחוץ למסך לא מציירים)
			queue_redraw()
		elif pl != null and global_position.distance_to(pl.global_position) > 1500.0:   # רחוק מדי - לא יחזור
			_end(false)

	func _end(hit_player: bool) -> void:
		if _done:
			return
		_done = true
		if owner_t != null and is_instance_valid(owner_t.z):
			owner_t.shot_result(hit_player)
		queue_free()

	func _draw() -> void:
		match kind:
			"nail", "bolt":
				DrawBatch.line(self, Vector2(-r * 1.6, 0), Vector2(r * 0.6, 0), Color(col, 0.5), r * 0.6)
				DrawBatch.line(self, Vector2(-r, 0), Vector2(r, 0), col.lightened(0.4), r * 0.35)
			"stone":   # אבן מקלע
				DrawBatch.line(self, Vector2(-r * 3.0, 0), Vector2(-r, 0), Color(1, 1, 1, 0.22), r * 0.7)
				DrawBatch.circle(self, Vector2.ZERO, r + 1.2, Color(0.1, 0.08, 0.06))
				DrawBatch.circle(self, Vector2.ZERO, r, Color("7a7068"))
				DrawBatch.circle(self, Vector2(-r * 0.3, -r * 0.3), r * 0.35, Color("9a9088"))
			"ball":
				DrawBatch.circle(self, Vector2.ZERO, r + 1.5, Color(0.1, 0.1, 0.1))
				DrawBatch.circle(self, Vector2.ZERO, r, Color(0.95, 0.95, 0.95))
				for q in 5:
					DrawBatch.circle(self, Vector2.from_angle(_t * 20.0 + float(q) * TAU / 5.0) * r * 0.55, r * 0.25, Color(0.1, 0.1, 0.1))
				DrawBatch.line(self, Vector2(-r * 3.0, 0), Vector2(-r, 0), Color(col, 0.6), r * 0.8)   # זנב אש
			_:   # כדור אנרגיה
				DrawBatch.circle(self, Vector2.ZERO, r * 1.9, Color(col, 0.18))
				DrawBatch.circle(self, Vector2.ZERO, r, col)
				DrawBatch.circle(self, Vector2.ZERO, r * 0.5, col.lightened(0.6))
				DrawBatch.line(self, Vector2(-r * 3.0, 0), Vector2(-r, 0), Color(col, 0.4), r * 0.9)


class Lob extends Node2D:
	var owner_t = null
	var velocity := Vector2.ZERO
	var gravity := 900.0
	var damage := 1
	var kind := "rock"
	var col := Color(1, 0.6, 0.2)
	var r := 9.0
	var blast_r := 0.0
	var _t := 0.0
	var _done := false

	func _ready() -> void:
		z_index = 9

	func _physics_process(delta: float) -> void:
		_t += delta
		velocity.y += gravity * delta
		var to := global_position + velocity * delta
		var pl := get_tree().get_first_node_in_group("player")
		var direct: bool = pl != null and not pl.dead and pl.body_rect().grow(r * 0.8).has_point(to)
		var hit := get_world_2d().direct_space_state.intersect_ray(PhysicsRayQueryParameters2D.create(global_position, to, 1 | 16))
		if direct or (not hit.is_empty() and not hit.collider.is_in_group("zombies")) or _t > 4.0:
			var at: Vector2 = to if hit.is_empty() else hit.position
			_land(at, pl, direct)
			return
		global_position = to
		rotation += 6.0 * delta
		queue_redraw()

	func _land(at: Vector2, pl: Node, direct: bool) -> void:
		if _done:
			return
		_done = true
		var hit_pl := direct
		if blast_r > 0.0:
			if pl != null and not pl.dead and pl.global_position.distance_to(at) < blast_r * 0.75:
				hit_pl = true
			preload("res://explosion.gd").blast(get_parent(), at, blast_r, blast_r * 0.4, 20, damage, "boss_lob")
		elif direct:
			pl.hurt(damage, Vector2(signf(velocity.x) * 1.4, -0.8))
		var P := preload("res://particles.gd")
		match kind:
			"ice":
				P.burst(get_parent(), at, "spark", Vector2.UP, 12)
			"rock":
				P.burst(get_parent(), at, "smoke", Vector2.UP, 6)
			_:
				P.burst(get_parent(), at, "fire", Vector2.UP, 8)
		if owner_t != null and is_instance_valid(owner_t.z):
			owner_t.shot_result(hit_pl)
		queue_free()

	func _draw() -> void:
		match kind:
			"ice":
				var pts := PackedVector2Array()
				for q in 6:
					pts.append(Vector2.from_angle(float(q) * TAU / 6.0) * r * (0.8 + 0.3 * float(q % 2)))
				DrawBatch.colored_polygon(self, pts, Color(0.75, 0.9, 1.0, 0.95))
				DrawBatch.polyline(self, pts + PackedVector2Array([pts[0]]), Color(1, 1, 1), 1.2)
			"rock":
				DrawBatch.circle(self, Vector2.ZERO, r + 1.5, Color(0.1, 0.08, 0.06))
				DrawBatch.circle(self, Vector2.ZERO, r, Color("6a5e52"))
				DrawBatch.circle(self, Vector2(-r * 0.3, -r * 0.3), r * 0.35, Color("8a7e70"))
			"canister":
				DrawBatch.rect(self, Rect2(-r * 0.6, -r, r * 1.2, r * 2.0), col)
				DrawBatch.rect(self, Rect2(-r * 0.6, -r, r * 1.2, r * 0.4), Color(0.2, 0.2, 0.2))
				DrawBatch.circle(self, Vector2(0, -r * 1.2), 2.5 + sin(_t * 30.0), Color(1, 0.7, 0.2))
			"shell":   # פגז טנק / מרגמה
				var d := velocity.normalized().rotated(-rotation)
				var nn := d.orthogonal()
				DrawBatch.colored_polygon(self, PackedVector2Array([-d * r * 1.4 + nn * r * 0.5, d * r * 0.6 + nn * r * 0.5, d * r * 1.4, d * r * 0.6 - nn * r * 0.5, -d * r * 1.4 - nn * r * 0.5]), Color("3a3a30"))
				DrawBatch.line(self, -d * r * 0.6 + nn * r * 0.5, -d * r * 0.6 - nn * r * 0.5, Color("c8a040"), 1.5)
				DrawBatch.line(self, -d * r * 1.4, -d * r * 3.5, Color(1.0, 0.7, 0.3, 0.5), r * 0.6)
			"football":   # כדור (השוער)
				DrawBatch.circle(self, Vector2.ZERO, r + 1.2, Color(0.1, 0.1, 0.1))
				DrawBatch.circle(self, Vector2.ZERO, r, Color(0.97, 0.97, 0.97))
				for q in 5:
					DrawBatch.circle(self, Vector2.from_angle(float(q) * TAU / 5.0) * r * 0.55, r * 0.24, Color(0.1, 0.1, 0.1))
			"rocket":   # רוג'או (זיקוק) - מקל עם ראש אדום וזנב ניצוצות
				var d := velocity.normalized().rotated(-rotation)
				DrawBatch.line(self, -d * r * 1.6, d * r * 1.2, Color("c8a060"), 2.0)
				DrawBatch.line(self, d * r * 0.4, d * r * 1.4, Color("d03020"), r * 0.6)
				for q in 4:
					DrawBatch.circle(self, -d * (r * 1.6 + float(q) * 4.0) + Vector2(randf_range(-2, 2), randf_range(-2, 2)), 2.0 - float(q) * 0.4, Color(1.0, 0.8 - float(q) * 0.15, 0.3))
			"beam":
				DrawBatch.rect(self, Rect2(-r * 2.5, -r * 0.5, r * 5.0, r), Color("8a3a2a"))
				DrawBatch.line(self, Vector2(-r * 2.5, 0), Vector2(r * 2.5, 0), Color(0.3, 0.1, 0.1), 1.5)
			_:
				DrawBatch.circle(self, Vector2.ZERO, r * 1.8, Color(col, 0.2))
				DrawBatch.circle(self, Vector2.ZERO, r, col)
