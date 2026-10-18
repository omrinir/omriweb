extends "res://enemies/zombie_type.gd"
# ============================================================
#  PURSUER (שלב 53, "CAPITAL SIEGE") - "SENT FOR YOU". (Nemesis / Terminator) ענק במעיל ארוך, קירח, ראש תפור,
#    עין אחת עם עדשה אדומה, משגר רקטות על הכתף ותג על החזה עם השם שלך. THE ARCHITECT שלח אותו - רק בשבילך.
#  אחד בשלב, לא מהבמאי: Director (בתחתית הקובץ) מוריד אותו מהשמיים מולך כשאתה עובר את start_x,
#    עם "HE WAS SENT FOR YOU" על כל המסך. משם הוא הולך אחריך בקצב קבוע (WALK_V) כל השלב.
#    אף פעם לא נתקע: נשאר מאחור יותר מ-CATCH_D / לא זז STUCK_T שניות מחוץ למסך -> מופיע מחדש קרוב מאחוריך.
#  "נופל" ולא מת: באפס חיים הוא כורע על ברך (DOWN_T, בלי נזק) וקם עם PHASE_HP הבא. רק בפעם השלישית הוא מת באמת
#    (פרס גדול: BOOST + SUPPLY + AMMO + HEALTH).
#  "THEY LEARN WHERE YOU SHOOT": כל פעם שהוא קם - צומח לו שריון (קסדה / שריון חזה / מגיני שוקיים) על האזור שבו
#    פגעת הכי הרבה. קליעים ניתזים מהשריון בניצוצות - צריך לכוון למקום אחר (פיצוצים ואש עוברים).
#  התקפות: GRAB - תופס, מרים מעל הראש (LIFT_T) וזורק (A/D לסירוגין = משתחרר). PUNCH - מכה קצרה מקרוב.
#           ROCKET - בטווח ROCKET_R ועם קו ראייה: נקודת לייזר אדומה עלייך (AIM_T) ואז רקטה (Boom.blast). להתגלגל / מחסה.
#  צלילים: "pu_step" (צעד כבד), "pu_aim" (ביפ לייזר), "pu_launch" (שיגור), "pu_down" (נופל), "pu_rise" (קם + שאגה).
#  לשנות: WALK_V, PHASE_HP, DOWN_T, GRAB_R, LIFT_T, THROW_V, THROW_DMG, ROCKET_R, AIM_T, ROCKET_V, ROCKET_DMG, CATCH_D, STUCK_T.
#  בדיקות: downs, armor, blocks, grabs, throws, punches, rockets, teleports (Director), killed.
# ============================================================

const FONT := preload("res://fonts/Bangers-Regular.ttf")
const Boom := preload("res://explosion.gd")
const Registry := preload("res://enemies/zombie_registry.gd")
const PickupScript := preload("res://pickup.gd")
const SOUNDS := {
	"pu_step": [["N", 0, 0, 0.0, 0.14, 0.0, 28.0, 0.7, 0.08, 0], ["S", 70, 40, 0.0, 0.14, 0.0, 24.0, 0.7, 1.0, 0]],
	"pu_aim": [["S", 1700, 1700, 0.0, 0.07, 0.0, 30.0, 0.18, 1.0, 0], ["S", 3400, 3400, 0.0, 0.05, 0.0, 40.0, 0.06, 1.0, 0]],
	"pu_launch": {"rev": 0.3, "drive": 2.4, "layers": [["N", 0, 0, 0.0, 0.5, 0.0, 6.0, 1.0, 0.5, 0], ["S", 220, 90, 0.0, 0.35, 0.0, 9.0, 0.6, 1.0, 0], ["N", 0, 0, 0.05, 0.8, 0.1, 3.0, 0.4, 0.8, 0, 0.3]]},
	"pu_down": {"rev": 0.3, "layers": [["W", 90, 45, 0.0, 1.2, 0.02, 2.0, 0.6, 0.12, 0.06], ["N", 0, 0, 0.0, 0.3, 0.0, 12.0, 0.8, 0.12, 0], ["S", 60, 30, 0.0, 0.3, 0.0, 12.0, 0.8, 1.0, 0]]},
	"pu_rise": {"rev": 0.35, "drive": 2.4, "layers": [["W", 60, 95, 0.0, 1.3, 0.25, 1.6, 0.7, 0.1, 0.08], ["V", 120, 85, 0.1, 1.2, 0.1, 1.8, 0.6, 1.0, 0.05, 0, [480, 820, 20]], ["N", 0, 0, 0.0, 1.3, 0.2, 2.0, 0.3, 0.15, 0]]},
}

const WALK_V := 62.0
const PHASE_HP := [90, 115, 140]
const BUFFER := 5000            # חיים "נסתרים" עד הנפילה השלישית (כדי שלא ימות לפני הזמן)
const DOWN_T := 3.0
const RISE_T := 0.9
const GRAB_R := 46.0
const REACH_T := 0.35
const LIFT_T := 0.75
const THROW_V := Vector2(470.0, -430.0)
const THROW_DMG := 2
const PUNCH_T := 0.35
const ROCKET_R := Vector2(300.0, 700.0)
const AIM_T := 1.0
const ROCKET_V := 430.0
const ROCKET_DMG := 30
const ROCKET_CD := Vector2(4.5, 7.0)
const GRAB_CD := Vector2(2.2, 3.4)
const ARMOR_NAMES := {"head": "HE GREW A HELMET", "body": "PLATE ARMOR", "leg": "IRON GREAVES"}

enum { ENTER, WALK, REACH, HOLD, PUNCH, AIM, FIRE, DOWN, RISE, STUN }
var state := WALK
var downs := 0
var armor := {"head": false, "body": false, "leg": false}
var zone_hits := {"head": 0, "body": 0, "leg": 0}
var blocks := 0
var grabs := 0
var throws := 0
var punches := 0
var rockets := 0
var escapes := 0
var held: Node = null
var _st := 0.0
var _ht := 0.0
var _grab_cd := 1.5
var _punch_cd := 0.0
var _rocket_cd := 3.0
var _hop_cd := 0.0
var _step_t := 0.0
var _dot := Vector2.ZERO
var _spark := 0.0
var _coat := 0.0
var _phase_max := 90
var _air := 0.0


func stats() -> Dictionary:
	return {"name": "PURSUER", "hp": PHASE_HP[0] + BUFFER, "walk": WALK_V, "chase": WALK_V, "damage": 2, "bite_delay": 1.2, "scale": 1.85, "width": 1.25,
		"duck": 0.0, "cover": 0.0, "skin": Color("b4b0a6"), "shirt": Color("4a4038"), "pants": Color("2a2a30"), "shoe": Color("18181a"),
		"points": 3000, "ragdoll": false}


func use_brain_movement() -> bool:
	return false


func can_bite() -> bool:
	return false


func can_groan() -> bool:
	return false


func setup() -> void:
	z.add_to_group("pursuers")
	_phase_max = PHASE_HP[0]
	z.max_hp = PHASE_HP[0] + BUFFER
	z.hp = z.max_hp
	z.chase_range = 2000.0   # (לא בוס: chase_range > 600 לא משנה סוג בקבצים שלא בודקים אותו)


func _main() -> Node:
	return z.get_parent()


func _phase_hp() -> int:
	return int(z.hp) - (BUFFER if downs < 2 else 0)


# ============================================================
#  תנועה והתקפות
# ============================================================
func physics(pl: Node, delta: float) -> bool:
	_st -= delta
	_grab_cd -= delta
	_punch_cd -= delta
	_rocket_cd -= delta
	_hop_cd -= delta
	_spark -= delta
	_coat += delta * (1.0 + absf(z.velocity.x) * 0.02)
	z._alert_t = 5.0
	if z.dead:
		_drop_player()
		return false
	var has_pl: bool = pl != null and not pl.dead
	var d: Vector2 = pl.global_position - z.global_position if has_pl else Vector2.ZERO
	if downs < 2 and _phase_hp() <= 0 and state != DOWN and state != RISE:
		_go_down()
	match state:
		ENTER:
			_air += delta
			z.velocity.y += z.gravity * delta
			z.velocity.x = 0.0
			z.move_and_slide()
			if z.is_on_floor() and _air > 0.1:
				_land_entry()
			return true
		WALK:
			if not has_pl:
				return _move(delta, 0.0)
			z._dir = signf(d.x) if absf(d.x) > 8.0 else z._dir
			var vx: float = z._dir * WALK_V * z.speed_mult
			if z.is_on_floor():
				if absf(d.x) < GRAB_R * z.sc * 0.5 + 20.0 and absf(d.y) < 60.0:
					if _grab_cd <= 0.0 and pl.grabbed_by == null:
						state = REACH
						_st = REACH_T
						Sfx.play("pu_step", z.global_position, 2.0, 0.1, 2, 0.7)
						return _move(delta, 0.0)
					if _punch_cd <= 0.0:
						state = PUNCH
						_st = PUNCH_T
						return _move(delta, 0.0)
					vx = 0.0
				elif _rocket_cd <= 0.0 and absf(d.x) > ROCKET_R.x and absf(d.x) < ROCKET_R.y and absf(d.y) < 260.0 and _clear(pl):
					state = AIM
					_st = AIM_T
					_dot = pl.global_position + Vector2(0, -30)
					Sfx.play("pu_aim", z.global_position, 0.0, 0.0, 2)
					return _move(delta, 0.0)
				# קומות: השחקן למעלה -> קפיצה ענקית; למטה -> יורד
				if d.y < -70.0 and absf(d.x) < 150.0 and _hop_cd <= 0.0:
					_hop_cd = 1.4
					var top := _platform_above(-d.y + 40.0)
					if top < INF:
						z.velocity.y = -sqrt(2.0 * z.gravity * (z.global_position.y - top + 30.0))
						z.velocity.x = z._dir * 120.0
				elif d.y > 70.0 and absf(d.x) < 220.0 and _hop_cd <= 0.0:
					_hop_cd = 1.0
					z.drop_through()
			_step_t -= delta * absf(z.velocity.x) / 60.0
			if _step_t <= 0.0 and z.is_on_floor():
				_step_t = 0.55
				if Art.on_screen(z, z.global_position):
					Sfx.play("pu_step", z.global_position, -4.0, 0.1, 2)
			return _move(delta, vx, true)
		REACH:
			if _st <= 0.0:
				if has_pl and pl.grabbed_by == null and pl._roll_t <= 0.0 and not pl.god_mode() and _grab_zone().intersects(pl.body_rect()):
					_grab(pl)
				else:
					state = WALK
					_grab_cd = randf_range(GRAB_CD.x, GRAB_CD.y) * 0.5
			return _move(delta, 0.0)
		HOLD:
			return _hold(delta)
		PUNCH:
			if _st <= 0.12 and _st + delta > 0.12:
				punches += 1
				Sfx.play("melee", z.global_position, 2.0, 0.1, 2, 0.7)
				var x0: float = z.global_position.x + (0.0 if z._dir > 0.0 else -60.0)
				if has_pl and Rect2(Vector2(x0, z.global_position.y - 90.0), Vector2(60.0, 90.0)).intersects(pl.body_rect()):
					pl.hurt(1, Vector2(z._dir * 2.2, -0.6))
			if _st <= 0.0:
				state = WALK
				_punch_cd = 1.4
			return _move(delta, 0.0)
		AIM:
			if has_pl:
				z._dir = signf(d.x) if absf(d.x) > 8.0 else z._dir
				var tgt: Vector2 = pl.global_position + Vector2(0, -28)
				_dot = _dot.lerp(tgt, clampf(delta * 3.5, 0.0, 1.0))
			if Engine.get_physics_frames() % 15 == 0:
				Sfx.play("pu_aim", z.global_position, -4.0, 0.0, 2, 1.0 + (AIM_T - _st) * 0.4)
			if _st <= 0.0:
				_fire()
				state = FIRE
				_st = 0.6
			return _move(delta, 0.0)
		FIRE:
			if _st <= 0.0:
				state = WALK
			return _move(delta, 0.0)
		DOWN:
			if Engine.get_physics_frames() % 8 == 0 and Art.on_screen(z, z.global_position):
				Particles.burst(_main(), z.global_position + Vector2(randf_range(-14, 14), -60.0 * z.sc), "smoke", Vector2.UP, 1)
			if _st <= 0.0:
				_rise()
			return _move(delta, 0.0)
		RISE:
			if _st <= 0.0:
				state = WALK
				_grab_cd = 0.6
			return _move(delta, 0.0)
		STUN:
			if _st <= 0.0:
				state = WALK
			return _move(delta, 0.0)
	return _move(delta, 0.0)


func _move(delta: float, vx: float, walking := false) -> bool:
	z.velocity.x = move_toward(z.velocity.x, vx, 900.0 * delta)
	if not z.is_on_floor():
		z.velocity.y += z.gravity * delta
	z.move_and_slide()
	if walking and z.is_on_wall() and z.is_on_floor():
		z.velocity.y = z.jump_velocity * 1.05
	if z.is_on_floor():
		z._walk_phase += delta * absf(z.velocity.x) * 0.075 / z.sc
	z.global_position.x = clampf(z.global_position.x, 30.0, z.world_w - 30.0)
	return true


func _platform_above(max_h: float) -> float:
	var best := INF
	var zp: Vector2 = z.global_position
	for p in z.get_tree().get_nodes_in_group("platforms"):
		var r: Rect2 = p.world_rect()
		if zp.x > r.position.x - 30.0 and zp.x < r.end.x + 30.0 and r.position.y < zp.y - 20.0 and zp.y - r.position.y <= max_h:
			if best == INF or r.position.y > best:
				best = r.position.y
	return best


func _clear(pl: Node) -> bool:
	var a: Vector2 = z.global_position + Vector2(0, -80.0 * z.sc)
	var b: Vector2 = pl.global_position + Vector2(0, -30.0)
	return z.get_world_2d().direct_space_state.intersect_ray(PhysicsRayQueryParameters2D.create(a, b, 1)).is_empty()


func _grab_zone() -> Rect2:
	var w: float = GRAB_R * z.sc
	var x0: float = z.global_position.x + (0.0 if z._dir > 0.0 else -w)
	return Rect2(Vector2(x0, z.global_position.y - 60.0 * z.sc), Vector2(w, 60.0 * z.sc))


func _grab(pl: Node) -> void:
	state = HOLD
	grabs += 1
	held = pl
	_ht = 0.0
	z.velocity.x = 0.0
	pl.grab(z)
	Sfx.play("tr_grab", pl.global_position, 3.0, 0.1, 2, 0.8)
	if grabs == 1:
		z._popup("I HAVE YOU", Color("ff5040"), 14, -82.0)


func _hold(delta: float) -> bool:
	_ht += delta
	if held == null or not is_instance_valid(held) or held.dead or held.grabbed_by != z:
		held = null
		state = WALK
		_grab_cd = randf_range(GRAB_CD.x, GRAB_CD.y)
		return _move(delta, 0.0)
	var k := clampf(_ht / LIFT_T, 0.0, 1.0)
	k = k * k * (3.0 - 2.0 * k)
	var front: Vector2 = Vector2(z._dir * 24.0, -18.0) * z.sc
	var over: Vector2 = Vector2(-z._dir * 2.0, -64.0 * z.sc - 6.0)
	held.global_position = z.global_position + front.lerp(over, k) + Vector2(0, sin(_ht * 30.0) * 1.5 * k)
	held.velocity = Vector2.ZERO
	if _ht >= LIFT_T + 0.25:
		_throw()
	return _move(delta, 0.0)


func _throw() -> void:
	var pl := held
	held = null
	throws += 1
	if pl.grabbed_by == z:
		pl.grabbed_by = null
	pl.hurt(THROW_DMG, Vector2(z._dir, -1.0))
	pl.velocity = Vector2(z._dir * THROW_V.x, THROW_V.y)
	pl._push_t = maxf(float(pl._push_t), 0.9)
	Sfx.play("throw", z.global_position, 3.0)
	Sfx.play("pu_rise", z.global_position, -2.0, 0.08, 2, 1.3)
	_shake(5.0)
	state = STUN
	_st = 0.7
	_grab_cd = randf_range(GRAB_CD.x, GRAB_CD.y)


func on_release() -> void:
	if held != null and is_instance_valid(held):
		held.global_position = z.global_position + Vector2(z._dir * 34.0, -8.0) * z.sc
		held.velocity = Vector2(z._dir * 220.0, -220.0)
	held = null
	escapes += 1
	state = STUN
	_st = 0.8
	_grab_cd = randf_range(GRAB_CD.x, GRAB_CD.y)


func _drop_player() -> void:
	if held != null and is_instance_valid(held):
		if held.grabbed_by == z:
			held.grabbed_by = null
		held.velocity = Vector2(0, -150)
	held = null


func _launcher_tip() -> Vector2:
	return z.global_position + Vector2(z._dir * 26.0 * z.wf, -64.0) * z.sc


func _fire() -> void:
	rockets += 1
	_rocket_cd = randf_range(ROCKET_CD.x, ROCKET_CD.y)
	var r := Rocket.new()
	var from := _launcher_tip()
	r.vel = (_dot - from).normalized() * ROCKET_V
	_main().add_child(r)
	r.global_position = from
	Sfx.play("pu_launch", from, 3.0, 0.08, 2)
	Particles.burst(_main(), from, "smoke", -r.vel.normalized(), 8)
	Particles.burst(_main(), z.global_position + Vector2(-z._dir * 20.0, -64.0) * z.sc, "fire", Vector2(-z._dir, 0.0), 6)
	z.velocity.x = -z._dir * 90.0


func _shake(s: float) -> void:
	var cam: Camera2D = z.get_viewport().get_camera_2d()
	if cam != null and cam.has_method("shake") and Art.on_screen(z, z.global_position):
		cam.shake(s, 0.3)


# ============================================================
#  נפילות, קימה ושריון שצומח
# ============================================================
func _go_down() -> void:
	_drop_player()
	downs += 1
	state = DOWN
	_st = DOWN_T
	z.velocity.x = 0.0
	Sfx.play("pu_down", z.global_position, 4.0, 0.05, 2)
	_shake(6.0)
	Particles.burst(_main(), z.global_position + Vector2(0, -4), "smoke", Vector2.UP, 10)
	z._popup("DOWN %d/3" % downs, Color("ffd060"), 16, -70.0)
	if downs == 1:
		z._popup("HE'S NOT DEAD...", Color("ff8060"), 12, -92.0)


func _rise() -> void:
	state = RISE
	_st = RISE_T
	_phase_max = int(PHASE_HP[mini(downs, PHASE_HP.size() - 1)])
	z.hp = _phase_max + (BUFFER if downs < 2 else 0)
	z.max_hp = z.hp
	# השריון צומח איפה שפגעת הכי הרבה
	var best := ""
	var bn := -1
	for k in zone_hits:
		if not armor[k] and int(zone_hits[k]) > bn:
			bn = int(zone_hits[k])
			best = k
	if best != "" and bn > 0:
		armor[best] = true
		z._popup(ARMOR_NAMES[best], Color("ffb070"), 14, -100.0)
		if downs == 1:
			z._popup("THEY LEARN WHERE YOU SHOOT", Color("ffd34a"), 12, -118.0)
	for k in zone_hits:
		zone_hits[k] = 0
	Sfx.play("pu_rise", z.global_position, 4.0, 0.05, 2)
	Sfx.play("roar", z.global_position, 3.0, 0.05, 2, 0.6)
	_shake(8.0)


func _zone(hit_pos: Vector2) -> String:
	var ly: float = (hit_pos.y - z.global_position.y) / z.sc
	if ly < -42.0:
		return "head"
	if ly > -20.0:
		return "leg"
	return "body"


func on_damage(_amount: int, hit_pos: Vector2, dir: Vector2, src: Dictionary) -> bool:
	if state == DOWN or state == RISE or state == ENTER:
		if _spark <= 0.0:
			_spark = 0.25
			Particles.burst(_main(), hit_pos, "spark", -dir, 2)
		return false
	var s := str(src.get("source", "bullet"))
	if not (s == "bullet" or s == "melee"):
		return true   # פיצוצים / אש עוברים את השריון
	var zn := _zone(hit_pos)
	if armor[zn]:
		blocks += 1
		_spark = 0.1
		Sfx.play("metal_ping", hit_pos, -3.0, 0.2, 4)
		Particles.burst(_main(), hit_pos, "spark", Vector2(-dir.x, -0.5), 5)
		if blocks % 8 == 1:
			z._popup("ARMORED - AIM ELSEWHERE", Color("d0d4dc"), 11, -96.0)
		return false
	zone_hits[zn] = int(zone_hits[zn]) + 1
	return true


func damage_mult(zone: String, src: Dictionary) -> float:
	if zone == "head" and not src.has("fixed"):
		return 0.6   # ראש = לא הורג בירייה אחת
	return 1.0


func on_death() -> void:
	_drop_player()
	var m := _main()
	m.set_meta("pu_killed", true)
	for pk in [PickupScript.BOOST, PickupScript.SUPPLY, PickupScript.AMMO, PickupScript.HEALTH]:
		z._drop(pk)
	var pl := player()
	if pl != null and pl.has_method("_say"):
		pl._say("STAY DOWN.", Color("ffd34a"))
	_shake(10.0)


# ============================================================
#  הכניסה: נוחת מהשמיים
# ============================================================
func start_entry() -> void:
	state = ENTER
	_air = 0.0


func _land_entry() -> void:
	state = RISE
	_st = 1.1
	Sfx.play("pu_down", z.global_position, 6.0, 0.05, 2, 0.8)
	Sfx.play("roar", z.global_position, 5.0, 0.05, 2, 0.55)
	_shake(14.0)
	Particles.burst(_main(), z.global_position + Vector2(0, -4), "smoke", Vector2.UP, 18)
	for i in 6:
		var c = load("res://debris.gd").new()
		_main().add_child(c)
		c.setup(z.global_position + Vector2(randf_range(-20, 20), -4), Vector2(4, 3), Color("6a6660"), Vector2(randf_range(-260, 260), -randf_range(120, 320)))
	z._popup("PURSUER", Color("ff5040"), 20, -90.0)


# ============================================================
#  רקטה
# ============================================================
class Rocket extends Node2D:
	var vel := Vector2.ZERO
	var _d := 0.0
	var _done := false

	func _ready() -> void:
		z_index = 6

	func _physics_process(delta: float) -> void:
		if _done:
			return
		var step := vel * delta
		_d += step.length()
		var hit := get_world_2d().direct_space_state.intersect_ray(PhysicsRayQueryParameters2D.create(global_position, global_position + step, 1))
		if not hit.is_empty():
			_boom(hit.position)
			return
		global_position += step
		var pl := get_tree().get_first_node_in_group("player")
		if pl != null and not pl.dead and pl.body_rect().grow(4.0).has_point(global_position):
			_boom(global_position)
			return
		if _d > 900.0:
			_boom(global_position)
			return
		if Engine.get_physics_frames() % 2 == 0:
			Particles.burst(get_parent(), global_position - vel.normalized() * 10.0, "smoke", -vel.normalized(), 1)
		rotation = vel.angle()
		queue_redraw()

	func _boom(at: Vector2) -> void:
		_done = true
		var m := get_parent()
		m.set_meta("pu_rocket_booms", int(m.get_meta("pu_rocket_booms", 0)) + 1)
		Boom.blast(m, at, 90.0, 50.0, ROCKET_DMG, 2, "rocket")
		Particles.burst(m, at, "fire", Vector2.UP, 14)
		queue_free()

	func _draw() -> void:
		var fl := 6.0 + sin(Time.get_ticks_msec() * 0.05) * 2.0
		DrawBatch.colored_polygon(self, PackedVector2Array([Vector2(-9, -2.5), Vector2(-9 - fl * 1.6, 0), Vector2(-9, 2.5)]), Color(1.0, 0.65, 0.2, 0.9))
		DrawBatch.colored_polygon(self, PackedVector2Array([Vector2(-9, -1.3), Vector2(-9 - fl, 0), Vector2(-9, 1.3)]), Color(1.0, 0.95, 0.7))
		Art.fill(self, PackedVector2Array([Vector2(-9, -3), Vector2(6, -3), Vector2(11, 0), Vector2(6, 3), Vector2(-9, 3)]), Color("5a6048"), Art.OUTLINE, 1.0)
		DrawBatch.rect(self, Rect2(Vector2(3, -3), Vector2(2, 6)), Color("c0a040"))
		DrawBatch.colored_polygon(self, PackedVector2Array([Vector2(-9, -3), Vector2(-12, -6), Vector2(-6, -3)]), Color("3a3e30"))
		DrawBatch.colored_polygon(self, PackedVector2Array([Vector2(-9, 3), Vector2(-12, 6), Vector2(-6, 3)]), Color("3a3e30"))


# ============================================================
#  Director: מכניס אותו פעם אחת, דואג שלא ייתקע / יישאר מאחור
# ============================================================
class Director extends Node:
	const CATCH_D := 1100.0     # רחוק מזה מאחוריך -> מופיע מחדש מאחוריך
	const STUCK_T := 4.0
	const RESPAWN_D := 760.0
	var main: Node = null
	var floor_y := 630.0
	var start_x := 1000.0
	var end_x := 9000.0
	var screen_layer: CanvasLayer = null
	var pursuer: Node = null
	var spawned := false
	var done := false
	var teleports := 0
	var _last_x := 0.0
	var _stuck := 0.0

	func _physics_process(delta: float) -> void:
		if done or main == null:
			return
		var pl := get_tree().get_first_node_in_group("player")
		if pl == null or pl.dead:
			return
		if not spawned:
			if pl.global_position.x > start_x:
				_spawn(pl)
			return
		if pursuer == null or not is_instance_valid(pursuer) or pursuer.dead:
			done = true
			return
		var pp: Vector2 = pursuer.global_position
		var dx: float = pl.global_position.x - pp.x
		var on_scr := Art.on_screen(pursuer, pp, 40.0)
		# זירת הבוס: אם הוא רחוק - נעלם (לא מפריע לבוס)
		if pl.global_position.x > end_x:
			if not on_scr and absf(dx) > 500.0:
				pursuer.queue_free()
				done = true
			return
		if absf(pp.x - _last_x) > 30.0:
			_last_x = pp.x
			_stuck = 0.0
		else:
			_stuck += delta
		var tm = pursuer.type_mod
		var busy: bool = tm.state in [DOWN, RISE, HOLD, ENTER]
		if busy:
			_stuck = 0.0
			return
		if (absf(dx) > CATCH_D or (_stuck > STUCK_T and not on_scr and absf(dx) > 300.0) or pp.y > floor_y + 200.0):
			_teleport(pl, signf(dx) if dx != 0.0 else 1.0)

	func _spawn(pl: Node) -> void:
		spawned = true
		var x: float = _free_x(pl.global_position.x + 520.0, 1.0)
		pursuer = main._spawn_zombie(x, floor_y, Registry.PURSUER)
		if pursuer == null:
			done = true
			return
		pursuer.position.y -= 560.0
		pursuer._dir = -1.0
		pursuer.type_mod.start_entry()
		_last_x = x
		main.set_meta("pu_spawned", true)
		var b := Banner.new()
		main.add_child(b)

	# מופיע מחדש מחוץ למסך, מאחוריך, על הרצפה במקום פנוי
	func _teleport(pl: Node, side: float) -> void:
		var x: float = _free_x(pl.global_position.x - side * RESPAWN_D, -side)
		x = clampf(x, 60.0, float(main.level_w) - 60.0)
		pursuer.global_position = Vector2(x, floor_y)
		pursuer.velocity = Vector2.ZERO
		pursuer._dir = side
		_last_x = x
		_stuck = 0.0
		teleports += 1
		main.set_meta("pu_teleports", teleports)

	# x על הרצפה בלי קיר / אוטובוס, ובלי קומה מעליו (שלא ינחת על מרפסת) ובלי מלכודת
	func _free_x(x: float, step_dir: float) -> float:
		var space: PhysicsDirectSpaceState2D = main.get_world_2d().direct_space_state
		for i in 40:
			var px := x + step_dir * float(i) * 24.0
			var ok := true
			for p in main.get_tree().get_nodes_in_group("platforms"):
				var r: Rect2 = p.world_rect()
				if px > r.position.x - 40.0 and px < r.end.x + 40.0:
					ok = false
			for h in main.get_tree().get_nodes_in_group("hazards"):
				if h.has_method("world_rect") and absf(h.world_rect().get_center().x - px) < h.world_rect().size.x * 0.5 + 40.0:
					ok = false
			if not ok:
				continue
			for yy in [-20.0, -60.0, -100.0]:
				var q := PhysicsPointQueryParameters2D.new()
				q.position = Vector2(px, floor_y + yy)
				q.collision_mask = 1
				if not space.intersect_point(q, 1).is_empty():
					ok = false
					break
			if ok:
				return px
		return x


# "HE WAS SENT FOR YOU" על כל המסך
class Banner extends CanvasLayer:
	var t := 0.0
	var _p: Node2D = null

	func _ready() -> void:
		layer = 3
		_p = BannerPaint.new()
		_p.owner_b = self
		add_child(_p)

	func _process(delta: float) -> void:
		t += delta
		if t > 3.6:
			queue_free()
			return
		_p.queue_redraw()


class BannerPaint extends Node2D:
	var owner_b = null

	func _draw() -> void:
		var t: float = owner_b.t
		var vs := get_viewport_rect().size
		var a := clampf(t / 0.25, 0.0, 1.0) * clampf((3.6 - t) / 0.6, 0.0, 1.0)
		var band_h := 120.0 * a
		DrawBatch.rect(self, Rect2(0, vs.y * 0.36 - band_h * 0.5, vs.x, band_h), Color(0.0, 0.0, 0.0, 0.55 * a))
		DrawBatch.rect(self, Rect2(0, vs.y * 0.36 - band_h * 0.5, vs.x, 3), Color(0.8, 0.1, 0.08, 0.8 * a))
		DrawBatch.rect(self, Rect2(0, vs.y * 0.36 + band_h * 0.5 - 3, vs.x, 3), Color(0.8, 0.1, 0.08, 0.8 * a))
		var txt := "HE WAS SENT FOR YOU"
		var fs := 64
		var w := FONT.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		var k := 1.0 + 0.25 * clampf(1.0 - t / 0.2, 0.0, 1.0)
		var sh := Vector2(sin(t * 50.0), cos(t * 41.0)) * 3.0 * clampf(1.0 - t / 0.6, 0.0, 1.0)
		DrawBatch.set_transform(self, Vector2(vs.x * 0.5, vs.y * 0.36 + 20.0) + sh, 0.0, Vector2(k, k))
		DrawBatch.string_outline(self, FONT, Vector2(-w * 0.5, 0), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, 10, Color(0, 0, 0, a))
		DrawBatch.string(self, FONT, Vector2(-w * 0.5, 0), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(1.0, 0.22, 0.16, a))
		DrawBatch.set_transform(self, Vector2.ZERO, 0.0, Vector2.ONE)
		var sub := "THE ARCHITECT KNOWS YOUR NAME"
		var sw := FONT.get_string_size(sub, HORIZONTAL_ALIGNMENT_LEFT, -1, 22).x
		var sa := a * clampf((t - 0.7) / 0.4, 0.0, 1.0)
		DrawBatch.string_outline(self, FONT, Vector2(vs.x * 0.5 - sw * 0.5, vs.y * 0.36 + 50.0), sub, HORIZONTAL_ALIGNMENT_LEFT, -1, 22, 6, Color(0, 0, 0, sa))
		DrawBatch.string(self, FONT, Vector2(vs.x * 0.5 - sw * 0.5, vs.y * 0.36 + 50.0), sub, HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color(0.92, 0.86, 0.78, sa))


# ============================================================
#  ציור: ענק במעיל ארוך, ראש תפור, עין עם עדשה אדומה, משגר על הכתף, שריון שצומח
# ============================================================
func draw() -> bool:
	begin_draw()
	var sk := col(z.skin)
	var dk := col(Art.shade(z.skin, 0.28))
	var coat := col(Color("4e4339"))
	var coat_d := col(Color("2e2824"))
	var pa := col(z.pants)
	var t: float = z._time
	var p: float = z._walk_phase
	var f: Array = feet(6.0, 2.5)
	var hip := Vector2(0, -22)
	var sh := Vector2(2, -41)
	var head := sh + Vector2(2, -9)
	var kneel := 0.0
	if state == DOWN:
		kneel = 1.0
	elif state == RISE:
		kneel = clampf(_st / RISE_T, 0.0, 1.0)
	elif state == ENTER:
		kneel = 0.0
	if kneel > 0.0:   # על ברך אחת, הראש למטה
		f = [Vector2(8, 0), Vector2(-9, 0).lerp(Vector2(-6, 0), kneel)]
		hip.y = lerpf(-22.0, -13.0, kneel)
		sh = Vector2(2.0 + 5.0 * kneel, lerpf(-41.0, -30.0, kneel))
		head = sh + Vector2(2.0 + 4.0 * kneel, lerpf(-9.0, -5.0, kneel))
	# כנפי המעיל מאחור (מתנופפות)
	var flap := sin(_coat * 4.0) * 2.0 + clampf(absf(z.velocity.x) * 0.05, 0.0, 4.0)
	Art.fill_shaded(z, PackedVector2Array([sh + Vector2(-8, 2), hip + Vector2(-8, -2), hip + Vector2(-11.0 - flap, 16.0 - kneel * 6.0), hip + Vector2(-3.0 - flap * 0.5, 18.0 - kneel * 6.0), hip + Vector2(2, 4)]), coat_d, 0.1, 0.3)
	# רגל אחורית
	z._leg(hip + Vector2(-3, 0), f[1], col(Art.shade(z.pants, 0.25)), dk, col(z.shoe))
	if armor.leg:
		_greave(f[1], hip + Vector2(-3, 0), true)
	# יד אחורית (או מחזיקה את המשגר)
	var aim := state == AIM or state == FIRE
	var hb := sh + Vector2(-4.0 + sin(p) * 2.0, 17.0)
	if aim:
		hb = sh + Vector2(10, -6)
	_arm2(sh + Vector2(-5, 1), hb, dk, coat_d, 5.6)
	# משגר הרקטות (על הגב / על הכתף)
	_launcher(sh, aim)
	# גוף: מעיל ארוך עם צווארון מורם
	var torso := PackedVector2Array([sh + Vector2(-11, -2), sh + Vector2(10, -1), sh + Vector2(11, 10), hip + Vector2(10, 4), hip + Vector2(8.0 + flap * 0.3, 17.0 - kneel * 6.0), hip + Vector2(-8, 17.0 - kneel * 6.0), hip + Vector2(-10, 2)])
	Art.fill_shaded(z, torso, coat, 0.2, 0.35)
	DrawBatch.line(z, sh + Vector2(-10, -1.5), sh + Vector2(9, -0.5), col(Color(1, 0.95, 0.85, 0.22)), 1.6)   # אור על הכתפיים
	DrawBatch.line(z, sh + Vector2(10.5, 1), hip + Vector2(9, 4), col(Color(1, 0.95, 0.85, 0.14)), 1.2)   # שפת המעיל
	DrawBatch.line(z, sh + Vector2(2, 1), hip + Vector2(3, 15.0 - kneel * 6.0), coat_d, 1.2)   # שוליים
	for q in 4:   # כפתורים
		DrawBatch.circle(z, sh + Vector2(4, 4.0 + float(q) * 5.0), 0.9, col(Color("6a6a70")))
	DrawBatch.rect(z, Rect2(hip + Vector2(-9, -4), Vector2(19, 3)), col(Color("141418")))   # חגורה
	DrawBatch.rect(z, Rect2(hip + Vector2(1, -4.5), Vector2(4, 4)), col(Color("8a8a90")))
	# תג עם השם: "SENT FOR YOU"
	DrawBatch.rect(z, Rect2(sh + Vector2(-5, 4), Vector2(7, 4)), col(Color("c8c0a8")))
	DrawBatch.line(z, sh + Vector2(-4, 5.5), sh + Vector2(1, 5.5), col(Color("8a2020")), 0.7)
	DrawBatch.line(z, sh + Vector2(-4, 7), sh + Vector2(0, 7), col(Color("2a2a2a")), 0.5)
	if armor.body:
		_plate(sh, hip)
	# צווארון מורם
	Art.fill(z, PackedVector2Array([sh + Vector2(-7, 1), sh + Vector2(-6, -6), sh + Vector2(-2, -3), sh + Vector2(2, -6), sh + Vector2(6, 1)]), coat_d, Art.OUTLINE, 1.0)
	# רגל קדמית
	z._leg(hip + Vector2(3, 0), f[0], pa, sk, col(z.shoe))
	if armor.leg:
		_greave(f[0], hip + Vector2(3, 0), false)
	# ראש קירח, תפרים, עין עם עדשה אדומה
	Art.oval_shaded(z, head, 6.2, 6.8, sk, 0.0)
	DrawBatch.line(z, head + Vector2(-5, -3), head + Vector2(3, -6.5), col(Color("4a2a2a")), 1.1)   # תפר על הקרחת
	for q in 5:
		var sp := head + Vector2(-5, -3).lerp(Vector2(3, -6.5), float(q) / 4.0)
		DrawBatch.line(z, sp + Vector2(-0.6, -1.1), sp + Vector2(0.6, 1.1), col(Color("4a2a2a")), 0.7)
	DrawBatch.line(z, head + Vector2(1, 3.8), head + Vector2(6, 3.2), col(Color("1a0a0a")), 1.4)   # פה סגור, שפתיים חתוכות
	for q in 3:
		DrawBatch.line(z, head + Vector2(2.0 + float(q) * 1.5, 3.0), head + Vector2(2.0 + float(q) * 1.5, 4.6), col(Color("4a2a2a")), 0.6)
	Art.oval(z, head + Vector2(3.6, -1.0), 1.8, 1.5, col(Color("1a1414")), 0.0, Art.NONE)
	var eye_on: bool = not z.dead and state != DOWN
	if eye_on:
		Art.disc(z, head + Vector2(3.8, -1.0), 1.3, Color(1.0, 0.15, 0.1), Art.NONE)
		Art.glow(z, head + Vector2(3.8, -1.0), 4.5, Color(1.0, 0.1, 0.05, 0.6))
	DrawBatch.rect(z, Rect2(head + Vector2(-2.5, -2.2), Vector2(3.5, 1.0)), col(Color("6a6a70")))   # מסגרת העדשה
	if armor.head:
		_helmet(head)
	# יד קדמית: מושיטה / מחזיקה / מכה / על הקרקע
	var hf := sh + Vector2(6.0 + sin(p + 1.5) * 2.0, 17.0)
	match state:
		REACH:
			hf = sh + Vector2(18, 4)
		HOLD:
			var k := clampf(_ht / LIFT_T, 0.0, 1.0)
			hf = sh + Vector2(16, 4).lerp(Vector2(1, -22), k)
		PUNCH:
			hf = sh + (Vector2(-6, 6) if _st > 0.12 else Vector2(20, 2))
		AIM, FIRE:
			hf = sh + Vector2(14, -4)
		DOWN, RISE:
			hf = Vector2(12, -1).lerp(sh + Vector2(6, 17), 1.0 - kneel)
	_arm2(sh + Vector2(5, 1), hf, sk, coat, 5.8, true)
	Art.disc(z, hf, 3.0, sk)   # אגרוף גדול עם תחבושת
	DrawBatch.line(z, hf + Vector2(-2, -1), hf + Vector2(2, 1), col(Color("c8c0b0")), 1.0)
	end_draw()
	# הלייזר והנקודה האדומה
	if state == AIM and not z.dead:
		var tip: Vector2 = _launcher_tip() - z.global_position
		var dot: Vector2 = _dot - z.global_position
		var blink := 0.6 + 0.4 * sin(z._time * 30.0)
		DrawBatch.line(z, tip, dot, Color(1.0, 0.1, 0.05, 0.35), 1.2)
		Art.glow(z, dot, 9.0, Color(1.0, 0.05, 0.05, 0.6 * blink))
		DrawBatch.circle(z, dot, 2.4, Color(1.0, 0.2, 0.15, blink))
	# בר חיים + 3 נפילות
	if not z.dead and Art.on_screen(z, z.global_position):
		var top := Vector2(-26, -100.0 * z.sc)
		var frac := clampf(float(_phase_hp()) / float(maxi(_phase_max, 1)), 0.0, 1.0)
		if state == DOWN or state == RISE or state == ENTER:
			frac = 0.0
		DrawBatch.rect(z, Rect2(top, Vector2(52, 5)), Color(0, 0, 0, 0.7))
		DrawBatch.rect(z, Rect2(top + Vector2(1, 1), Vector2(50.0 * frac, 3)), Color(0.9, 0.18, 0.12))
		for i in 3:
			var pc := top + Vector2(10.0 + float(i) * 16.0, -6.0)
			var gone := i < downs
			Art.disc(z, pc, 3.2, Color(0.25, 0.25, 0.28) if gone else Color(0.95, 0.85, 0.6), Art.OUTLINE, 1.0)
			if gone:
				DrawBatch.line(z, pc + Vector2(-2.5, -2.5), pc + Vector2(2.5, 2.5), Color(0.9, 0.2, 0.15), 1.2)
	return true


# יד עם מרפק מוגבל: בלי "כנף" כשהיד קרובה לכתף (z._arm מותח את המרפק החוצה). המרפק פונה למטה/אחורה (fwd = קדימה)
func _arm2(a: Vector2, b: Vector2, skin_c: Color, sleeve: Color, w := 4.6, fwd := false) -> void:
	var d := b - a
	var n := Vector2.ZERO
	if d.length() > 0.01:
		n = d.orthogonal().normalized()
		if n.y + (n.x if fwd else -n.x) * 0.5 < 0.0:
			n = -n
	var half := d.length() * 0.5
	var e := a + d * 0.5 + n * minf(sqrt(maxf(0.0, 90.0 - half * half)), 3.5)
	Art.limb(z, PackedVector2Array([a, e]), w + 0.6, sleeve)
	Art.limb(z, PackedVector2Array([e, b]), w, skin_c)
	Art.disc(z, b, w * 0.55, skin_c, Art.OUTLINE, 1.0)


func _launcher(sh: Vector2, aim: bool) -> void:
	var a := sh + Vector2(-12, -8)
	var b := sh + Vector2(20, -6)
	if not aim:   # על הגב, אלכסוני
		a = sh + Vector2(-10, -14)
		b = sh + Vector2(6, 12)
	var d := (b - a).normalized()
	var n := d.orthogonal()
	Art.fill_shaded(z, PackedVector2Array([a - n * 3.0, b - n * 3.0, b + n * 3.0, a + n * 3.0]), col(Color("4a5040")), 0.15, 0.35, Art.OUTLINE, 1.0)
	DrawBatch.rect(z, Rect2(a.lerp(b, 0.45) - Vector2(2, 3.5), Vector2(4, 7)), col(Color("2a2e24")))
	Art.oval(z, b, 1.4, 3.2, col(Color("1a1a1a")), d.angle(), Art.OUTLINE, 0.8)
	DrawBatch.line(z, a.lerp(b, 0.2) + n * 3.0, a.lerp(b, 0.2) + n * 6.0, col(Color("2a2e24")), 1.4)   # ידית
	if aim:
		DrawBatch.rect(z, Rect2(a.lerp(b, 0.6) - n * 5.0 - Vector2(1, 1), Vector2(3, 2)), col(Color("c03020")))   # כוונת לייזר


func _plate(sh: Vector2, hip: Vector2) -> void:
	var pc := col(Color("5a5a5e"))
	Art.fill_shaded(z, PackedVector2Array([sh + Vector2(-8, 1), sh + Vector2(9, 1), sh + Vector2(9, 14), hip + Vector2(6, -6), hip + Vector2(-7, -6)]), pc, 0.25, 0.3, Art.OUTLINE, 1.2)
	DrawBatch.line(z, sh + Vector2(-7, 8), sh + Vector2(8, 8), col(Color("3a3a3e")), 1.0)
	for q in 6:
		DrawBatch.circle(z, sh + Vector2(-6.0 + float(q % 3) * 6.5, 3.0 + float(q / 3) * 9.0), 0.8, col(Color("9a9aa0")))
	DrawBatch.line(z, sh + Vector2(-5, 2), hip + Vector2(-4, -7), col(Color(1, 1, 1, 0.15)), 1.2)
	if _spark > 0.0:
		Art.glow(z, sh + Vector2(2, 10), 10.0, Color(1, 0.9, 0.6, 0.5))


func _helmet(head: Vector2) -> void:
	var hc := col(Color("5a5a5e"))
	Art.fill_shaded(z, PackedVector2Array([head + Vector2(-7, 1), head + Vector2(-6.5, -5), head + Vector2(-2, -8.5), head + Vector2(4, -8), head + Vector2(7, -4), head + Vector2(7, -2.4), head + Vector2(1, -2.4), head + Vector2(-1, 1)]), hc, 0.25, 0.3, Art.OUTLINE, 1.1)
	DrawBatch.line(z, head + Vector2(-6, -4.5), head + Vector2(6, -4.5), col(Color("3a3a3e")), 0.8)
	for q in 4:
		DrawBatch.circle(z, head + Vector2(-5.0 + float(q) * 3.5, -6.0), 0.6, col(Color("9a9aa0")))


func _greave(foot: Vector2, hip: Vector2, back: bool) -> void:
	var ankle := foot + Vector2(0, -3)
	var knee := Art.joint(hip, ankle, 11.5, 11.5, 1.0)
	var c := col(Color("4a4a4e") if back else Color("5a5a5e"))
	var d := (ankle - knee).normalized()
	var n := d.orthogonal()
	Art.fill_shaded(z, PackedVector2Array([knee - n * 4.0 - d * 1.5, knee + n * 4.0 - d * 1.5, ankle + n * 3.4, ankle - n * 3.4]), c, 0.25, 0.3, Art.OUTLINE, 1.0)
	DrawBatch.circle(z, knee, 2.6, c)
	DrawBatch.circle(z, knee.lerp(ankle, 0.5) + n * 2.0, 0.6, col(Color("9a9aa0")))
