extends "res://enemies/zombie_type.gd"
# ============================================================
#  STORMCALLER (שלב 47, "PAMPAS STORM") - נפח האסטנסיה שנפגע מברק ולא מת: פונצ'ו שחור ספוג, עור חרוך עם צלקות ברק
#  (תבנית שרכים), עיניים כחולות זוהרות, ובגב אשפת מוטות ברזל (מוטות גדר / כליאי ברק).
#    WALK    - שומר מרחק (keep_range).
#    THROW   - מניף (WIND_T) וזורק מוט ברזל כמו כידון - הוא ננעץ באדמה לידך (PlantedRod).
#              המוט "טוען" (CHARGE_T: ניצוצות עולים במוט + עיגול אזהרה על הקרקע) -> ברק פוגע במוט: נזק DMG בעיגול R.
#              אחר כך המוט נשאר חי (LIVE_T) ומושך ברק שוב כל RESTRIKE שניות (עם אזהרה). ירייה במוט (ROD_HP) = הוא נופל.
#    CALL    - נגמרו לו המוטות (RODS) או שהוא פצוע: מרים ידיים לשמיים והברק פוגע בו עצמו (בלי נזק) -> CHARGED.
#    CHARGED - (CHARGED_T) זוהר כחול, רץ אליך מהר, נגיעה = מכת חשמל (TOUCH_DMG), וקשת חשמל (ARC_R) עם אזהרה קצרה.
#  "THEY LEARN TOGETHER": ברחת מעיגול לכיוון מסוים -> כל קוראי הסערה נועצים את המוט הבא קדימה בכיוון הריצה שלך
#    (main meta "storm_lead", עד LEAD_MAX). הפלת ROD_SHOT_LEARN מוטות -> הם נועצים שניים, משני הצדדים שלך.
#  לשנות: KEEP, RANGE, WIND_T, CD, RODS, CHARGE_T, R, DMG, LIVE_T, RESTRIKE, ROD_HP, CHARGED_T, ARC_R, LEAD_STEP.
# ============================================================

const SOUNDS := {
	"sc_hum": [["Q", 60, 62, 0.0, 1.2, 0.1, 1.5, 0.2, 0.4, 0.05], ["C", 0, 0, 0.0, 1.2, 0.1, 1.5, 0.35, 1.0, 0]],
	"sc_throw": [["N", 0, 0, 0.0, 0.22, 0.0, 12.0, 0.5, 0.5, 0, 0.6], ["S", 700, 300, 0.0, 0.18, 0.0, 18.0, 0.2, 1.0, 0]],
	"sc_stick": [["C", 0, 0, 0.0, 0.05, 0.0, 60.0, 0.6, 1.0, 0], ["S", 900, 860, 0.0, 0.25, 0.0, 14.0, 0.25, 1.0, 0]],
	"sc_arc": [["Q", 90, 70, 0.0, 0.25, 0.0, 10.0, 0.35, 0.6, 0], ["C", 0, 0, 0.0, 0.25, 0.0, 8.0, 0.8, 1.0, 0], ["S", 4200, 3600, 0.0, 0.15, 0.0, 18.0, 0.1, 1.0, 0]],
}

const KEEP := 300.0
const RANGE := 600.0
const WIND_T := 0.5
const CD := Vector2(3.4, 4.6)
const RODS := 3
const MAX_LIVE := 2
const CHARGE_T := 1.4
const R := 72.0
const DMG := 2
const Z_DMG := 25
const LIVE_T := 7.0
const RESTRIKE := 3.4
const ROD_HP := 3
const CALL_T := 1.0
const CHARGED_T := 7.0
const CHARGED_SPEED := 1.7
const TOUCH_DMG := 2
const ARC_R := 190.0
const ARC_WARN := 0.45
const ARC_CD := 1.8
const LEAD_STEP := 50.0
const LEAD_MAX := 150.0
const ROD_SHOT_LEARN := 2

enum { WALK, WIND, CALL, CHARGED }
var state := WALK
var rods := RODS
var live := []               # המוטות שלו שעדיין נעוצים
var throws := 0              # לבדיקות
var strikes := 0
var strike_hits := 0
var calls := 0
var shocks := 0
var _st := 0.0
var _cd := 1.6
var _arc_cd := 0.0
var _arc_t := 0.0
var _arc_to := Vector2.ZERO
var _arc_show := 0.0
var _touch_cd := 0.0
var _hurt_call := false


func stats() -> Dictionary:
	return {"name": "STORMCALLER", "hp": 48, "walk": 42.0, "chase": 84.0, "damage": 1, "bite_delay": 0.8, "scale": 1.12, "width": 1.0,
		"duck": 0.1, "cover": 0.4, "skin": Color("7a8a8c"), "shirt": Color("1e2226"), "pants": Color("3a3430"), "shoe": Color("1a1612"), "points": 520}


func brain_overrides() -> Dictionary:
	return {"aggression": 0.3, "keep_range": KEEP}


func can_bite() -> bool:
	return state == WALK


func damage_mult(_zone: String, _src: Dictionary) -> float:
	return 0.75 if state == CHARGED else 1.0


static func lead(main: Node) -> float:
	return float(main.get_meta("storm_lead")) if main.has_meta("storm_lead") else 0.0


static func rods_shot(main: Node) -> int:
	return int(main.get_meta("storm_rods_shot")) if main.has_meta("storm_rods_shot") else 0


func learn_escape(dir: float) -> void:   # נקרא מהמוט: ברחת מהעיגול לכיוון dir
	var m: Node = z.get_parent()
	var l := lead(m)
	var nl := clampf(absf(l) + LEAD_STEP, 0.0, LEAD_MAX) * dir
	m.set_meta("storm_lead", nl)
	z._popup("THEY PLANT WHERE YOU RUN", Color("a8d0ff"), 12, -80.0)


func rod_down() -> void:   # ירו במוט שלו והוא נפל
	var m: Node = z.get_parent()
	m.set_meta("storm_rods_shot", rods_shot(m) + 1)
	if rods_shot(m) == ROD_SHOT_LEARN:
		z._popup("THEY PLANT TWO", Color("a8d0ff"), 12, -80.0)


func physics(pl: Node, delta: float) -> bool:
	_cd -= delta
	_st -= delta
	_arc_cd -= delta
	_touch_cd -= delta
	_arc_show -= delta
	if z.dead:
		return false
	var i := live.size() - 1
	while i >= 0:
		if not is_instance_valid(live[i]):
			live.remove_at(i)
		i -= 1
	var has_pl: bool = pl != null and not pl.dead
	match state:
		WALK:
			if not has_pl or not z.is_on_floor():
				return false
			var d: Vector2 = pl.global_position - z.global_position
			if (rods <= 0 or (z.hp < z.max_hp * 0.5 and not _hurt_call)) and _cd <= 0.0 and absf(d.x) < 700.0:
				_hurt_call = _hurt_call or z.hp < z.max_hp * 0.5
				state = CALL
				_st = CALL_T
				Sfx.play("sc_hum", z.global_position, -2.0, 0.1, 2)
				z._popup("!", Color("a8d0ff"), 16, -78.0)
				return _stay(delta)
			var sees: bool = z.brain == null or z.brain.sees or absf(d.x) < 400.0
			if rods > 0 and _cd <= 0.0 and live.size() < MAX_LIVE and sees and absf(d.x) < RANGE and absf(d.y) < 260.0:
				state = WIND
				_st = WIND_T
				z._dir = signf(d.x) if d.x != 0.0 else z._dir
				return _stay(delta)
			return false
		WIND:
			if _st <= 0.0:
				if has_pl:
					_throw(pl)
				state = WALK
				_cd = randf_range(CD.x, CD.y)
			return _stay(delta)
		CALL:
			if Engine.get_physics_frames() % 4 == 0 and Art.on_screen(z, z.global_position):
				Particles.burst(z.get_parent(), z.global_position + Vector2(0, -70.0) * z.sc, "spark", Vector2.UP, 2)
			if _st <= 0.0:
				_self_strike()
			return _stay(delta)
		CHARGED:
			return _charged(pl, delta)
	return false


func _stay(delta: float) -> bool:
	z.velocity.x = move_toward(z.velocity.x, 0.0, 900.0 * delta)
	if not z.is_on_floor():
		z.velocity.y += z.gravity * delta
	z.move_and_slide()
	return true


func hand() -> Vector2:
	return z.global_position + Vector2(z._dir * 8.0, -50.0) * z.sc


func _throw(pl: Node) -> void:
	var m: Node = z.get_parent()
	var base: float = pl.global_position.x
	var l := lead(m)
	if absf(pl.velocity.x) > 40.0 and signf(pl.velocity.x) == signf(l):
		base += l   # למדו לאן אתה בורח
	var xs := [base]
	if rods_shot(m) >= ROD_SHOT_LEARN and rods >= 2:
		xs = [base - 110.0, base + 110.0]
	for x in xs:
		if rods <= 0:
			break
		rods -= 1
		throws += 1
		var j := Javelin.new()
		j.owner_t = self
		j.target = _ground(Vector2(float(x), pl.global_position.y))
		z.get_parent().add_child(j)
		j.global_position = hand()
		j.launch()
	Sfx.play("sc_throw", hand(), 0.0, 0.1, 3)


func _ground(p: Vector2) -> Vector2:
	var top := p + Vector2(0, -80.0)
	var hit: Dictionary = z.get_world_2d().direct_space_state.intersect_ray(PhysicsRayQueryParameters2D.create(top, top + Vector2(0, 600), 1 | 16))
	return hit.position if hit else p


func planted(r: Node) -> void:
	live.append(r)


func _self_strike() -> void:
	calls += 1
	state = CHARGED
	_st = CHARGED_T
	var b := SelfBolt.new()
	z.get_parent().add_child(b)
	b.global_position = z.global_position + Vector2(0, -60.0 * z.sc)
	Sfx.play("thunder", z.global_position, 0.0, 0.15, 2)
	Sfx.play("sc_arc", z.global_position, 4.0, 0.1, 2)
	_flash_sky()
	z._popup("CHARGED!", Color("a8d0ff"), 14, -86.0)


func _charged(pl: Node, delta: float) -> bool:
	if _st <= 0.0:   # נגמר החשמל: אוסף שוב מוטות מהאשפה
		state = WALK
		rods = 2
		_cd = 2.0
		Particles.burst(z.get_parent(), z.global_position + Vector2(0, -30), "smoke", Vector2.UP, 4)
		return _stay(delta)
	if Engine.get_physics_frames() % 6 == 0 and Art.on_screen(z, z.global_position):
		Particles.burst(z.get_parent(), z.global_position + Vector2(randf_range(-10, 10), -randf_range(10, 60)) * z.sc, "spark", Vector2.ZERO, 1)
	if pl == null or pl.dead:
		return _stay(delta)
	var d: Vector2 = pl.global_position - z.global_position
	z._dir = signf(d.x) if absf(d.x) > 4.0 else z._dir
	# קשת חשמל
	if _arc_t > 0.0:
		_arc_t -= delta
		if _arc_t <= 0.0:
			_arc(pl)
		return _stay(delta)
	if _arc_cd <= 0.0 and d.length() < ARC_R and d.length() > 40.0:
		_arc_t = ARC_WARN
		_arc_cd = ARC_CD
		Sfx.play("sc_hum", z.global_position, 0.0, 0.1, 2, 1.5)
		return _stay(delta)
	# נגיעה = מכת חשמל
	if _touch_cd <= 0.0 and absf(d.x) < 30.0 * z.sc and absf(d.y) < 50.0:
		_touch_cd = 1.0
		shocks += 1
		pl.hurt(TOUCH_DMG, Vector2(signf(d.x) * 1.6, -1.0))
		Sfx.play("sc_arc", pl.global_position, 2.0, 0.1, 2)
		Game.story.emit("hazard", {"kind": "shock"})
	z.velocity.x = move_toward(z.velocity.x, z._dir * float(z.chase_speed) * CHARGED_SPEED, 900.0 * delta)
	if not z.is_on_floor():
		z.velocity.y += z.gravity * delta
	elif z.is_on_wall():
		z.velocity.y = -420.0
	z.move_and_slide()
	return true


func _arc(pl: Node) -> void:
	var from: Vector2 = z.global_position + Vector2(z._dir * 6.0, -48.0) * z.sc
	var to: Vector2 = pl.global_position + Vector2(0, -26)
	_arc_to = to - z.global_position
	_arc_show = 0.25
	Sfx.play("sc_arc", from, 3.0, 0.1, 2)
	if from.distance_to(to) < ARC_R + 30.0 and E_clear(from, to):
		shocks += 1
		pl.hurt(1, Vector2(z._dir * 1.2, -0.8))


func E_clear(a: Vector2, b: Vector2) -> bool:
	var hit: Dictionary = z.get_world_2d().direct_space_state.intersect_ray(PhysicsRayQueryParameters2D.create(a, b, 1))
	return hit.is_empty()


func _flash_sky() -> void:
	var st: Node = z.get_tree().get_first_node_in_group("storm")
	if st != null and st.has_method("strike_flash"):
		st.strike_flash()


func on_death() -> void:
	state = WALK


# ---- מוט ברזל שעף כמו כידון ונועץ באדמה ----
class Javelin extends Node2D:
	const G := 900.0
	var owner_t = null
	var target := Vector2.ZERO
	var velocity := Vector2.ZERO
	var _t := 0.0

	func launch() -> void:
		var dx := target.x - global_position.x
		var t := clampf(absf(dx) / 420.0, 0.35, 1.1)
		velocity = Vector2(dx / t, (target.y - global_position.y - 0.5 * G * t * t) / t)

	func _ready() -> void:
		z_index = 9

	func _physics_process(delta: float) -> void:
		_t += delta
		velocity.y += G * delta
		var to := global_position + velocity * delta
		if (velocity.y > 0.0 and to.y >= target.y) or _t > 2.0:
			_plant(Vector2(to.x, target.y))
			return
		global_position = to
		rotation = velocity.angle()
		queue_redraw()

	func _plant(at: Vector2) -> void:
		var r := PlantedRod.new()
		r.owner_t = owner_t
		r.tilt = clampf(velocity.x * 0.0006, -0.35, 0.35)
		get_parent().add_child(r)
		r.global_position = at
		if owner_t != null and is_instance_valid(owner_t.z) and not owner_t.z.dead:
			owner_t.planted(r)
		preload("res://sfx.gd").play("sc_stick", at, 2.0, 0.1, 3)
		preload("res://particles.gd").burst(get_parent(), at, "smoke", Vector2.UP, 3)
		queue_free()

	func _draw() -> void:
		DrawBatch.begin(self)
		_draw_b()
		DrawBatch.end(self)

	func _draw_b() -> void:
		DrawBatch.line(self, Vector2(-30, 0), Vector2(30, 0), Color("101214"), 4.0)
		DrawBatch.line(self, Vector2(-30, 0), Vector2(30, 0), Color("6a6e74"), 2.4)
		DrawBatch.colored_polygon(self, PackedVector2Array([Vector2(30, -3), Vector2(40, 0), Vector2(30, 3)]), Color("d88a40"))


# ---- מוט ברזל נעוץ: טוען, נפגע מברק, נשאר חי ומושך עוד ברקים ----
class PlantedRod extends Node2D:
	const A := preload("res://art.gd")
	var owner_t = null
	var tilt := 0.0
	var hp := 3
	var phase := 0                 # 0 = טוען (אזהרה), 1 = נשאר חי (בין ברקים)
	var strikes := 0               # לבדיקות
	var _t := 0.0
	var _wait := 0.0
	var _life := 0.0
	var _bolt_t := 0.0
	var _bolt := PackedVector2Array()
	var _inside := false           # השחקן היה בעיגול בזמן האזהרה
	var _hb: StaticBody2D = null

	class Hitbox extends StaticBody2D:
		var r = null
		func hit_by_bullet(_p: Vector2, _n: Vector2, _d: Vector2) -> void:
			if r != null:
				r.shot()

	func _ready() -> void:
		z_index = 4
		add_to_group("hazards")
		hp = ROD_HP
		_wait = CHARGE_T
		var h := Hitbox.new()
		h.r = self
		h.collision_layer = 4
		h.collision_mask = 0
		var cs := CollisionShape2D.new()
		var sh := RectangleShape2D.new()
		sh.size = Vector2(12, 70)
		cs.shape = sh
		cs.position = Vector2(0, -36)
		h.add_child(cs)
		add_child(h)
		_hb = h

	func top() -> Vector2:
		return Vector2.from_angle(-PI * 0.5 + tilt) * 74.0

	func warning() -> bool:
		return _wait <= CHARGE_T and _wait > 0.0 and (phase == 0 or _wait < 1.0)

	func world_rect() -> Rect2:
		return Rect2(global_position + Vector2(-R, -70.0), Vector2(R * 2.0, 72.0))

	func danger_at(p: Vector2, margin := 0.0) -> bool:
		return warning() and world_rect().grow(margin).has_point(p)

	func shot() -> void:
		hp -= 1
		preload("res://particles.gd").burst(get_parent(), global_position + top() * 0.6, "spark", Vector2.UP, 4)
		preload("res://sfx.gd").play("clink", global_position, 0.0, 0.1, 3)
		if hp <= 0:
			if owner_t != null and is_instance_valid(owner_t.z) and not owner_t.z.dead:
				owner_t.rod_down()
			_fall()

	func _fall() -> void:
		preload("res://particles.gd").burst(get_parent(), global_position, "smoke", Vector2.UP, 4)
		queue_free()

	func _physics_process(delta: float) -> void:
		_t += delta
		_wait -= delta
		_life += delta
		_bolt_t = maxf(_bolt_t - delta, 0.0)
		var pl := get_tree().get_first_node_in_group("player")
		if warning() and pl != null and not pl.dead:
			var inside := absf(pl.global_position.x - global_position.x) < R and absf(pl.global_position.y - global_position.y) < 60.0
			if inside:
				_inside = true
			elif _inside:   # ברחת מהעיגול - הם לומדים לאן
				_inside = false
				if owner_t != null and is_instance_valid(owner_t.z) and not owner_t.z.dead and absf(pl.velocity.x) > 30.0:
					owner_t.learn_escape(signf(pl.velocity.x))
		if _wait <= 0.0:
			_strike(pl)
			phase = 1
			_wait = RESTRIKE
			_inside = false
		if _life > LIVE_T + CHARGE_T and _bolt_t <= 0.0:
			_fall()
			return
		if A.on_screen(self, global_position + Vector2(0, -40), R + 60.0):
			queue_redraw()

	func _strike(pl: Node) -> void:
		strikes += 1
		_bolt_t = 0.35
		var tp := top()
		_bolt = PackedVector2Array([tp + Vector2(randf_range(-30.0, 30.0), -700.0)])
		var y := -700.0
		var x: float = _bolt[0].x
		while y < tp.y - 30.0:
			y += randf_range(40.0, 80.0)
			x = clampf(x + randf_range(-28.0, 28.0), tp.x - 40.0, tp.x + 40.0)
			_bolt.append(Vector2(x, minf(y, tp.y)))
		_bolt.append(tp)
		var Sx := preload("res://sfx.gd")
		Sx.play("thunder", global_position, 0.0, 0.15, 2)
		Sx.play("sc_arc", global_position, 4.0, 0.1, 3)
		preload("res://particles.gd").burst(get_parent(), global_position + Vector2(0, -6), "spark", Vector2.UP, 14)
		var st := get_tree().get_first_node_in_group("storm")
		if st != null and st.has_method("strike_flash"):
			st.strike_flash()
		var cam := get_viewport().get_camera_2d()
		if cam != null and cam.has_method("shake"):
			cam.shake(5.0, 0.2)
		if owner_t != null and is_instance_valid(owner_t.z):
			owner_t.strikes += 1
		if pl != null and not pl.dead:
			var b: Rect2 = pl.body_rect()
			if absf(b.get_center().x - global_position.x) < R + b.size.x * 0.3 and b.end.y > global_position.y - 70.0 and b.position.y < global_position.y + 4.0:
				if pl._invuln <= 0.0 and owner_t != null and is_instance_valid(owner_t.z):
					owner_t.strike_hits += 1
				pl.hurt(DMG, Vector2(signf(b.get_center().x - global_position.x + 0.01), -1.3))
				Game.story.emit("hazard", {"kind": "shock"})
		for z in get_tree().get_nodes_in_group("zombies"):
			if z.dead or z.is_boss():
				continue
			if owner_t != null and is_instance_valid(owner_t.z) and z == owner_t.z:
				continue
			if absf(z.global_position.x - global_position.x) < R + 8.0 and absf(z.global_position.y - global_position.y) < 24.0:
				z.take_damage(Z_DMG, z.global_position + Vector2(0, -20), Vector2.UP, true, {"source": "hazard", "fixed": Z_DMG})

	func _draw() -> void:
		DrawBatch.begin(self)
		_draw_b()
		DrawBatch.end(self)

	func _draw_b() -> void:
		var tp := top()
		if warning():
			var k := clampf(1.0 - _wait / (CHARGE_T if phase == 0 else 1.0), 0.0, 1.0)
			var blink := fmod(_t * 8.0, 1.0) < 0.6
			DrawBatch.colored_polygon(self, A.ellipse(Vector2.ZERO, R, R * 0.2, 0.0, 22), Color(0.5, 0.75, 1.0, 0.15 + 0.2 * k))
			DrawBatch.set_transform(self, Vector2.ZERO, 0.0, Vector2(1.0, 0.2))
			DrawBatch.arc(self, Vector2.ZERO, R, 0, TAU, 28, Color(0.7, 0.9, 1.0, 0.9 if blink else 0.5), 3.0)
			DrawBatch.arc(self, Vector2.ZERO, R * (1.0 - k) + 4.0, 0, TAU, 20, Color(1, 1, 1, 0.6), 2.0)
			DrawBatch.set_transform(self, Vector2.ZERO, 0.0, Vector2.ONE)
			for q in 2:   # ניצוצות מטפסים על המוט
				var sp := tp * fmod(_t * 2.0 + float(q) * 0.5, 1.0)
				DrawBatch.circle(self, sp, 2.5, Color(0.8, 0.95, 1.0, 0.9))
			A.glow(self, tp, 12.0 + 10.0 * k, Color(0.6, 0.85, 1.0, 0.6))
		DrawBatch.line(self, Vector2.ZERO, tp, Color("101214"), 5.0)
		DrawBatch.line(self, Vector2.ZERO, tp, Color("5a5e64") if phase == 0 else Color("7a7e88"), 3.0)
		DrawBatch.colored_polygon(self, PackedVector2Array([tp + tp.normalized().orthogonal() * 3.0, tp * 1.1, tp - tp.normalized().orthogonal() * 3.0]), Color("d88a40"))
		DrawBatch.colored_polygon(self, A.ellipse(Vector2(0, 1), 8.0, 2.0, 0.0, 10), Color(0.1, 0.08, 0.06, 0.8))
		if phase == 1:   # חם - זוהר כתום אחרי הברק
			DrawBatch.line(self, tp * 0.6, tp, Color(1.0, 0.55, 0.2, 0.7), 2.0)
		if _bolt_t > 0.0:
			var a := _bolt_t / 0.35
			DrawBatch.polyline(self, _bolt, Color(0.55, 0.8, 1.0, 0.45 * a), 8.0)
			DrawBatch.polyline(self, _bolt, Color(1, 1, 1, a), 2.6)
			A.glow(self, Vector2(0, -8), R * 1.3, Color(0.6, 0.85, 1.0, 0.5 * a))
			DrawBatch.colored_polygon(self, A.ellipse(Vector2.ZERO, R, R * 0.2, 0.0, 22), Color(0.05, 0.05, 0.06, 0.5 * a))


# ---- ברק שפוגע בו עצמו (CALL) ----
class SelfBolt extends Node2D:
	var _t := 0.0
	var _pts := PackedVector2Array()

	func _ready() -> void:
		z_index = 9
		var y := -700.0
		var x := randf_range(-30.0, 30.0)
		_pts.append(Vector2(x, y))
		while y < 0.0:
			y = minf(y + randf_range(40.0, 80.0), 0.0)
			x = clampf(x + randf_range(-26.0, 26.0), -30.0, 30.0)
			_pts.append(Vector2(x, y))

	func _physics_process(delta: float) -> void:
		_t += delta
		if _t > 0.35:
			queue_free()
			return
		queue_redraw()

	func _draw() -> void:
		DrawBatch.begin(self)
		_draw_b()
		DrawBatch.end(self)

	func _draw_b() -> void:
		var a := 1.0 - _t / 0.35
		DrawBatch.polyline(self, _pts, Color(0.55, 0.8, 1.0, 0.45 * a), 9.0)
		DrawBatch.polyline(self, _pts, Color(1, 1, 1, a), 3.0)


# ============================================================
#  ציור: פונצ'ו שחור ספוג, עור אפור-כחול עם צלקות ברק בצורת שרך, עיניים כחולות, אשפת מוטות בגב.
#  WIND = יד אחורה עם מוט. CALL = שתי ידיים לשמיים. CHARGED = הילה כחולה, ניצוצות, שיער סומר.
# ============================================================
func draw() -> bool:
	begin_draw()
	var sk := col(z.skin)
	var pon := col(z.shirt)
	var p: float = z._walk_phase
	var f: Array = feet(5.0 if state != CHARGED else 7.0, 2.5)
	var hip := Vector2(0, -22)
	var lean := 4.0 if state == CHARGED else 0.0
	var sh := Vector2(1.0 + lean, -37.0)
	var head := sh + Vector2(3.5 + lean * 0.3, -8)
	var glow_c := Color(0.55, 0.8, 1.0)
	if state == CHARGED and not z.dead:
		Art.glow(z, sh + Vector2(0, 2), 30.0, Color(glow_c, 0.35 + 0.15 * sin(z._time * 20.0)))
	# אשפת מוטות בגב
	for q in rods:
		var bx := -7.0 - float(q) * 2.5
		DrawBatch.line(z, sh + Vector2(bx, 14), sh + Vector2(bx - 6.0, -24.0 + float(q) * 3.0), Art.OUTLINE, 3.2)
		DrawBatch.line(z, sh + Vector2(bx, 14), sh + Vector2(bx - 6.0, -24.0 + float(q) * 3.0), col(Color("6a6e74")), 1.8)
		DrawBatch.circle(z, sh + Vector2(bx - 6.0, -24.0 + float(q) * 3.0), 1.6, col(Color("d88a40")))
	z._leg(hip + Vector2(-2, 0), f[1], col(Art.shade(z.pants, 0.25)), sk, col(z.shoe))
	z._leg(hip + Vector2(2, 0), f[0], col(z.pants), sk, col(z.shoe))
	var hb: Vector2
	var hf: Vector2
	match state:
		WIND:
			hb = sh + Vector2(-8, 12)
			hf = sh + Vector2(-12, -8)
		CALL:
			hb = sh + Vector2(-4, -24)
			hf = sh + Vector2(6, -25)
		CHARGED:
			hb = sh + Vector2(-10, 6)
			hf = sh + Vector2(14, 0) if _arc_t > 0.0 else sh + Vector2(10, 12)
		_:
			hb = sh + Vector2(-5.0 - sin(p) * 3.0, 15.0)
			hf = sh + Vector2(9.0 + sin(p) * 3.0, 14.0)
	z._arm(sh + Vector2(-3, 1), hb, Art.shade(sk, 0.25), Art.shade(pon, 0.3))
	# פונצ'ו ספוג (נוטף)
	var pts := PackedVector2Array([sh + Vector2(-9, 1), sh + Vector2(-3, -2), sh + Vector2(6, -2), sh + Vector2(10, 3), hip + Vector2(9, 6), hip + Vector2(4, 9), hip + Vector2(-3, 7), hip + Vector2(-9, 9)])
	Art.fill_shaded(z, pts, pon, 0.12, 0.3)
	for q in 3:   # טיפות נוטפות
		var dk := fmod(z._time * 1.5 + float(q) * 0.37, 1.0)
		DrawBatch.circle(z, hip + Vector2(-6.0 + float(q) * 6.0, 8.0 + dk * 10.0), 0.9, Color(0.6, 0.7, 0.8, 0.7 * (1.0 - dk)))
	# צלקת ברק (שרך) על הצוואר והחזה
	var sc_c := Color(0.85, 0.45, 0.4, 0.8) if state != CHARGED else Color(0.75, 0.95, 1.0, 0.95)
	DrawBatch.polyline(z, PackedVector2Array([head + Vector2(-1, 5), sh + Vector2(1, 2), sh + Vector2(-1, 6), sh + Vector2(2, 9)]), sc_c, 1.0)
	DrawBatch.line(z, sh + Vector2(1, 2), sh + Vector2(4, 4), sc_c, 0.8)
	DrawBatch.line(z, sh + Vector2(-1, 6), sh + Vector2(-4, 8), sc_c, 0.8)
	Art.oval_shaded(z, head, 5.2, 5.8, sk, 0.0)
	face(head, Vector2(3.2, -0.6))
	# שיער - סומר כשהוא טעון
	var hair := col(Color("1a1a1e"))
	for q in 5:
		var hx := -4.0 + float(q) * 2.0
		var up := -10.0 if state == CHARGED or state == CALL else -6.5
		DrawBatch.line(z, head + Vector2(hx, -4), head + Vector2(hx * 1.4, up - absf(float(q) - 2.0)), hair, 1.4)
	if not z.dead:
		var ec := glow_c if state != WALK or fmod(z._time, 3.0) < 2.7 else Color(0.3, 0.4, 0.5)
		DrawBatch.circle(z, head + Vector2(3.2, -0.5), 1.2, ec)
		Art.glow(z, head + Vector2(3.2, -0.5), 4.0, Color(glow_c, 0.5))
	# יד קדמית + מוט ביד
	z._arm(sh + Vector2(3, 1), hf, sk, pon)
	if state == WIND and rods > 0:
		var tip := hf + Vector2(34, -6)
		DrawBatch.line(z, hf + Vector2(-12, 2), tip, Art.OUTLINE, 3.6)
		DrawBatch.line(z, hf + Vector2(-12, 2), tip, col(Color("6a6e74")), 2.2)
		DrawBatch.colored_polygon(z, PackedVector2Array([tip + Vector2(0, -2.5), tip + Vector2(7, 0), tip + Vector2(0, 2.5)]), col(Color("d88a40")))
	if (state == CALL or state == CHARGED) and not z.dead:
		for q in 3:
			var a := randf() * TAU
			var c := hf if state == CHARGED else (hf + hb) * 0.5
			DrawBatch.line(z, c, c + Vector2.from_angle(a) * randf_range(4.0, 10.0), Color(0.85, 0.95, 1.0, 0.9), 1.0)
	if _arc_t > 0.0 and not z.dead:   # אזהרה: ניצוץ מתקבץ ביד
		Art.glow(z, hf, 10.0 + (ARC_WARN - _arc_t) * 20.0, Color(glow_c, 0.7))
	end_draw()
	if _arc_show > 0.0 and not z.dead:   # הקשת עצמה (בלי היפוך)
		var from: Vector2 = Vector2(z._dir * 6.0, -48.0) * z.sc
		var pts2 := PackedVector2Array([from])
		var n := 7
		for i in range(1, n):
			pts2.append(from.lerp(_arc_to, float(i) / float(n)) + Vector2(randf_range(-8, 8), randf_range(-8, 8)))
		pts2.append(_arc_to)
		DrawBatch.polyline(z, pts2, Color(0.55, 0.8, 1.0, 0.5), 6.0)
		DrawBatch.polyline(z, pts2, Color(1, 1, 1, 0.95), 2.0)
	return true
