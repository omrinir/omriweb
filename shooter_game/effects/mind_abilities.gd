extends RefCounted
# ============================================================
#  MIND ABILITIES - היכולת המיוחדת של הזומבי שבשליטת MIND CONTROL (effects/mind_control.gd).
#  לוחצים C / לחצן ימני (בטלפון: SKILL) -> הזומבי עושה את הדבר שלו:
#    spin    - BLADES: מערבולת להבים קדימה, חותך כל מה שבדרך
#    pounce  - LEAPER / AMBUSHER / GHILLIE / STALKER / רצים / כלבים (וברירת מחדל): זינוק ענק, נחיתה = מכה מסביב
#    shoot   - UZI / MINIGUNNER / SANDBLASTER / GUNNER: צרור כדורים לכיוון הכוונת
#    spit    - SPITTER / RETCHER / HURLER: כדור חומצה בקשת, מתיז מסביב
#    slam    - BRUTE / TANK / SHIELDED / DEVOURER / CRUMBLER: מכת קרקע - גל הדף שזורק ופוגע
#    scream  - SCREAMER / SIREN / COMMANDER / PACK_LEADER: צרחה שמשתקת זומבים מסביב
#    explode - BLOATER / BOMBHEAD: פיצוץ ענק (הזומבי מת - השליטה נגמרת)
#  לשנות: INFO (זמן טעינה), והמספרים בכל יכולת.
# ============================================================

const ZScript := preload("res://zombie.gd")
const Registry := preload("res://enemies/zombie_registry.gd")
const Boom := preload("res://explosion.gd")
const Sfx := preload("res://sfx.gd")
const Particles := preload("res://particles.gd")

const INFO := {
	"spin": {"name": "BLADE SPIN", "cd": 2.0},
	"pounce": {"name": "POUNCE", "cd": 1.5},
	"shoot": {"name": "BURST FIRE", "cd": 1.3},
	"spit": {"name": "ACID SPIT", "cd": 1.0},
	"slam": {"name": "GROUND SLAM", "cd": 2.2},
	"scream": {"name": "STUN SCREAM", "cd": 4.0},
	"explode": {"name": "SELF-DESTRUCT", "cd": 99.0},
}


static func ability_for(z: Node) -> String:
	var k: int = z.kind
	match k:
		ZScript.BRUTE:
			return "slam"
		ZScript.SPITTER, ZScript.HURLER:
			return "spit"
		ZScript.SCREAMER:
			return "scream"
		ZScript.BLOATER:
			return "explode"
		ZScript.GUNNER:
			return "shoot"
	if k == Registry.BLADES:
		return "spin"
	if k in [Registry.UZI, Registry.MINIGUNNER, Registry.SANDBLASTER]:
		return "shoot"
	if k in [Registry.RETCHER]:
		return "spit"
	if k in [Registry.TANK, Registry.SHIELDED, Registry.SHIELD_ELITE, Registry.DEVOURER, Registry.CRUMBLER, Registry.SPARE_PARTS, Registry.SPLITJAW]:
		return "slam"
	if k in [Registry.BOMBHEAD]:
		return "explode"
	if k in [Registry.SIREN, Registry.COMMANDER, Registry.PACK_LEADER]:
		return "scream"
	return "pounce"


# פוגע בכל הזומבים ברדיוס (חוץ מהבוגד). מחזיר כמה נהרגו
static func hurt_area(zz: Node, center: Vector2, radius: float, dmg: int, knock := 0.0) -> int:
	var kills := 0
	for o in zz.get_tree().get_nodes_in_group("zombies"):
		if o == zz or o.dead:
			continue
		var c: Vector2 = o.global_position + Vector2(0.0, -28.0 * float(o.sc))
		if c.distance_to(center) > radius + 10.0 * float(o.wf):
			continue
		var side := signf(c.x - center.x) if c.x != center.x else 1.0
		o.take_damage(dmg, c, Vector2(side, -0.4), false, {"source": "mind", "fixed": dmg})
		if knock > 0.0 and not o.dead:
			o.velocity = Vector2(side * knock, -knock * 0.6)
		if o.dead:
			kills += 1
	return kills


# ============================================================
#  היכולת בזמן ריצה (אחת לכל סשן)
# ============================================================
class Ability extends RefCounted:
	const MA := preload("res://effects/mind_abilities.gd")
	var id := "pounce"
	var cd := 0.0            # זמן טעינה שנשאר
	var active := 0.0        # כמה זמן היכולת עוד פועלת
	var uses := 0            # לבדיקות
	var kills := 0
	var _aim := Vector2.RIGHT
	var _tick := 0.0
	var _air := false
	var _shots := 0
	var _hit: Array = []      # זינוק: מי כבר נפגע

	func info() -> Dictionary:
		return MA.INFO[id]

	func ready_k() -> float:   # 1 = מוכן
		return 1.0 - clampf(cd / float(info().cd), 0.0, 1.0)

	# מנסה להפעיל. aim = כיוון (לירי / יריקה)
	func start(zz: Node, aim: Vector2) -> void:
		if cd > 0.0 or active > 0.0:
			return
		_aim = aim
		match id:
			"spin":
				active = 0.9
				_tick = 0.0
				Sfx.play("whoosh", zz.global_position, 2.0)
				var tm = zz.type_mod
				if tm != null and zz.kind == Registry.BLADES:   # ציור המערבולת של BLADES
					tm.state = tm.SPIN
			"pounce":
				if not zz.is_on_floor():
					return
				zz.velocity = Vector2(zz._dir * 430.0, -430.0)
				active = 2.0
				_air = false
				_hit.clear()
				Sfx.play("roll", zz.global_position, 2.0)
			"shoot":
				active = 0.5
				_shots = 7
				_tick = 0.0
			"spit":
				var g := Glob.new()
				g.owner_z = zz
				zz.get_parent().add_child(g)
				g.global_position = zz.global_position + Vector2(zz._dir * 10.0, -40.0 * float(zz.sc))
				g.velocity = aim * 620.0 + Vector2(0.0, -140.0)
				Sfx.play("spit", zz.global_position, 2.0)
				zz._bite_anim = 0.25
			"slam":
				if not zz.is_on_floor():
					return
				var c: Vector2 = zz.global_position + Vector2(0.0, -10.0)
				kills += MA.hurt_area(zz, c, 140.0, 45, 380.0)
				Particles.burst(zz.get_parent(), zz.global_position, "smoke", Vector2.UP, 14)
				Sfx.play("explosion", zz.global_position, -6.0)
				_shake(zz, 9.0)
				var w := Shock.new()
				zz.get_parent().add_child(w)
				w.global_position = zz.global_position
			"scream":
				var n := 0
				for o in zz.get_tree().get_nodes_in_group("zombies"):
					if o != zz and not o.dead and o.global_position.distance_to(zz.global_position) < 280.0:
						o._stagger_t = 2.4
						n += 1
				Sfx.play("zscream", zz.global_position, 6.0)
				zz._popup("STUNNED x%d" % n, Color("ffd34a"), 14, -70.0)
				var w2 := Shock.new()
				w2.col = Color(1.0, 0.85, 0.4)
				w2.max_r = 280.0
				zz.get_parent().add_child(w2)
				w2.global_position = zz.global_position + Vector2(0, -30.0 * float(zz.sc))
			"explode":
				Boom.blast(zz.get_parent(), zz.global_position + Vector2(0.0, -24.0 * float(zz.sc)), 170.0, 90.0, 120, 0, "mind")
				_shake(zz, 14.0)
				if not zz.dead:
					zz.hp = 0
					zz._die(Vector2(0.0, -1.0))
		uses += 1
		cd = float(info().cd)

	# כל פריים. true = היכולת מזיזה את הזומבי (התנועה הרגילה לא פועלת)
	func tick(zz: Node, delta: float) -> bool:
		cd = maxf(cd - delta, 0.0)
		if active <= 0.0:
			return false
		active -= delta
		match id:
			"spin":
				var tm = zz.type_mod
				if tm != null and "_ang" in tm:
					tm._ang += delta * 26.0
				zz.velocity.x = zz._dir * 380.0
				_tick -= delta
				if _tick <= 0.0:
					_tick = 0.12
					var hit := MA.hurt_area(zz, zz.global_position + Vector2(zz._dir * 14.0, -28.0 * float(zz.sc)), 44.0, 22, 220.0)
					kills += hit
					if hit > 0 or randf() < 0.5:
						Sfx.play("melee", zz.global_position, -4.0, 0.15)
				if active <= 0.0 and tm != null and zz.kind == Registry.BLADES:
					tm.state = tm.WALK
				return true
			"pounce":
				if not zz.is_on_floor():
					_air = true
					for o in zz.get_tree().get_nodes_in_group("zombies"):   # דורס את מי שבדרך (פעם אחת לכל זומבי)
						if o == zz or o.dead or _hit.has(o):
							continue
						if absf(o.global_position.x - zz.global_position.x) < 26.0 * float(o.wf) and absf(o.global_position.y - zz.global_position.y) < 60.0:
							_hit.append(o)
							o.take_damage(35, o.global_position + Vector2(0, -30.0 * float(o.sc)), Vector2(zz._dir, -0.5), false, {"source": "mind", "fixed": 35})
							if o.dead:
								kills += 1
				elif _air:   # נחת
					active = 0.0
					kills += MA.hurt_area(zz, zz.global_position + Vector2(0, -20), 80.0, 55, 260.0)
					Particles.burst(zz.get_parent(), zz.global_position, "smoke", Vector2.UP, 8)
					Sfx.play("land", zz.global_position, 3.0)
					_shake(zz, 5.0)
				return not zz.is_on_floor()   # באוויר: הזינוק ממשיך
			"shoot":
				_tick -= delta
				var tm2 = zz.type_mod
				while _tick <= 0.0 and _shots > 0:
					_tick += 0.07
					_shots -= 1
					var b := ZShot.new()
					b.owner_z = zz
					zz.get_parent().add_child(b)
					var from: Vector2 = zz.global_position + Vector2(zz._dir * 14.0, -36.0 * float(zz.sc))
					b.global_position = from
					b.velocity = _aim.rotated(randf_range(-0.05, 0.05)) * 950.0
					Sfx.play("smg", from, -6.0, 0.1, 3)
					if tm2 != null and "_flash" in tm2:
						tm2._flash = 0.035
					if tm2 != null and "_base" in tm2:
						tm2._base = _aim.angle()
				if tm2 != null and zz.kind == Registry.UZI:   # העוזי מצויר בזמן הצרור
					tm2.state = tm2.BURST if active > 0.0 else tm2.WALK
				return false
		return false

	func _shake(zz: Node, s: float) -> void:
		var cam := zz.get_viewport().get_camera_2d()
		if cam != null and cam.has_method("shake"):
			cam.shake(s, 0.3)


# ---- כדור של הבוגד: פוגע רק בזומבים ----
class ZShot extends Node2D:
	var velocity := Vector2.ZERO
	var owner_z: Node = null
	var life := 0.9

	func _ready() -> void:
		z_index = 9

	func _physics_process(delta: float) -> void:
		life -= delta
		var to := global_position + velocity * delta
		if life <= 0.0 or not get_world_2d().direct_space_state.intersect_ray(PhysicsRayQueryParameters2D.create(global_position, to, 1)).is_empty():
			queue_free()
			return
		for o in get_tree().get_nodes_in_group("zombies"):
			if o == owner_z or o.dead:
				continue
			var c: Vector2 = o.global_position + Vector2(0.0, -30.0 * float(o.sc))
			if absf(to.x - c.x) < 12.0 * float(o.wf) + 4.0 and absf(to.y - c.y) < 32.0 * float(o.sc):
				o.take_damage(16, to, velocity.normalized(), false, {"source": "mind", "fixed": 16})
				Particles.burst(get_parent(), to, "hit", -velocity.normalized(), 4)
				queue_free()
				return
		global_position = to
		rotation = velocity.angle()
		queue_redraw()

	func _draw() -> void:
		draw_line(Vector2(-18, 0), Vector2(0, 0), Color(0.75, 0.45, 1.0, 0.5), 2.0)
		draw_line(Vector2(-6, 0), Vector2(2, 0), Color(0.95, 0.85, 1.0), 2.2)


# ---- כדור חומצה ----
class Glob extends Node2D:
	var velocity := Vector2.ZERO
	var owner_z: Node = null
	var life := 2.0

	func _ready() -> void:
		z_index = 9

	func _physics_process(delta: float) -> void:
		life -= delta
		velocity.y += 700.0 * delta
		var to := global_position + velocity * delta
		var hit_wall := not get_world_2d().direct_space_state.intersect_ray(PhysicsRayQueryParameters2D.create(global_position, to, 1 | 16)).is_empty()
		var hit_z := false
		for o in get_tree().get_nodes_in_group("zombies"):
			if o != owner_z and not o.dead and (o.global_position + Vector2(0, -28.0 * float(o.sc))).distance_to(to) < 22.0:
				hit_z = true
				break
		if hit_wall or hit_z or life <= 0.0:
			if owner_z != null and is_instance_valid(owner_z):
				preload("res://effects/mind_abilities.gd").hurt_area(owner_z, to, 60.0, 40, 120.0)
			Particles.burst(get_parent(), to, "smoke", Vector2.UP, 6)
			Sfx.play("splat", to, 0.0)
			queue_free()
			return
		global_position = to
		queue_redraw()

	func _draw() -> void:
		draw_circle(Vector2.ZERO, 7.0, Color(0.55, 0.85, 0.2, 0.45))
		draw_circle(Vector2.ZERO, 4.5, Color(0.7, 0.95, 0.3))


# ---- גל הדף (מכת קרקע / צרחה) ----
class Shock extends Node2D:
	var col := Color(0.85, 0.75, 0.55)
	var max_r := 140.0
	var t := 0.0

	func _ready() -> void:
		z_index = 8

	func _process(delta: float) -> void:
		t += delta
		if t > 0.4:
			queue_free()
			return
		queue_redraw()

	func _draw() -> void:
		var k := t / 0.4
		draw_arc(Vector2.ZERO, max_r * k, PI, TAU, 28, Color(col, 0.8 * (1.0 - k)), 4.0 * (1.0 - k) + 1.0, true)
