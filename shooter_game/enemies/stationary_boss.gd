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
	l.x *= z._dir
	return weak_rect().grow(3.0).has_point(l)


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
	if not z.is_on_floor():
		z.velocity.y += z.gravity * delta
	z.move_and_slide()
	_pound_cd -= delta
	var has_pl: bool = pl != null and not pl.dead
	if not has_pl:
		return true
	var dx: float = pl.global_position.x - z.global_position.x
	if winding == "" and absf(dx) > 8.0:
		z._dir = signf(dx)
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
		queue_redraw()

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
				draw_line(Vector2(-r * 1.6, 0), Vector2(r * 0.6, 0), Color(col, 0.5), r * 0.6)
				draw_line(Vector2(-r, 0), Vector2(r, 0), col.lightened(0.4), r * 0.35)
			"ball":
				draw_circle(Vector2.ZERO, r + 1.5, Color(0.1, 0.1, 0.1))
				draw_circle(Vector2.ZERO, r, Color(0.95, 0.95, 0.95))
				for q in 5:
					draw_circle(Vector2.from_angle(_t * 20.0 + float(q) * TAU / 5.0) * r * 0.55, r * 0.25, Color(0.1, 0.1, 0.1))
				draw_line(Vector2(-r * 3.0, 0), Vector2(-r, 0), Color(col, 0.6), r * 0.8)   # זנב אש
			_:   # כדור אנרגיה
				draw_circle(Vector2.ZERO, r * 1.9, Color(col, 0.18))
				draw_circle(Vector2.ZERO, r, col)
				draw_circle(Vector2.ZERO, r * 0.5, col.lightened(0.6))
				draw_line(Vector2(-r * 3.0, 0), Vector2(-r, 0), Color(col, 0.4), r * 0.9)


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
				draw_colored_polygon(pts, Color(0.75, 0.9, 1.0, 0.95))
				draw_polyline(pts + PackedVector2Array([pts[0]]), Color(1, 1, 1), 1.2)
			"rock":
				draw_circle(Vector2.ZERO, r + 1.5, Color(0.1, 0.08, 0.06))
				draw_circle(Vector2.ZERO, r, Color("6a5e52"))
				draw_circle(Vector2(-r * 0.3, -r * 0.3), r * 0.35, Color("8a7e70"))
			"canister":
				draw_rect(Rect2(-r * 0.6, -r, r * 1.2, r * 2.0), col)
				draw_rect(Rect2(-r * 0.6, -r, r * 1.2, r * 0.4), Color(0.2, 0.2, 0.2))
				draw_circle(Vector2(0, -r * 1.2), 2.5 + sin(_t * 30.0), Color(1, 0.7, 0.2))
			"beam":
				draw_rect(Rect2(-r * 2.5, -r * 0.5, r * 5.0, r), Color("8a3a2a"))
				draw_line(Vector2(-r * 2.5, 0), Vector2(r * 2.5, 0), Color(0.3, 0.1, 0.1), 1.5)
			_:
				draw_circle(Vector2.ZERO, r * 1.8, Color(col, 0.2))
				draw_circle(Vector2.ZERO, r, col)
