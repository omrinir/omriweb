extends "res://enemies/zombie_type.gd"
# ============================================================
#  IRONARMS (שלב 48, "OLD QUARTER" - בואנוס איירס) - פועל נמל זומבי שמישהו בריג' את הזרועות שלו לזרועות רובוטיות.
#  במקום אמות - קני תותח מברזל: בוכנות, צינורות הידראוליים, מנוע/סוללה על הגב ועין אופטית אדומה.
#    WALK    - מתקרב (המוח), שומר מרחק KEEP.
#    VOLLEY  - יורה בזרועות לסירוגין (VOLLEY_N יריות, SHOT_GAP ביניהן). זרוע אחת = לאט יותר (ONE_ARM_SLOW).
#    CHARGE  - כל CHARGE_EVERY מטחים: הקנים זוהרים וזמזום עולה (CHARGE_T) = אזהרה -> פיצוץ אנרגיה גדול (BLAST_DMG).
#    RAGE    - בלי זרועות: מסתער ונושך (x RAGE_SPEED).
#  הזרועות מברזל: ירייה מלפנים בגובה הזרועות -> ניצוצות, אין נזק לגוף - הזרוע סופגת (ARM_HP).
#    זרוע שנשברת נופלת לרצפה כחתיכה (ArmPiece). מאחור / בראש / ברגליים - נזק רגיל. פיצוץ פוגע בכל הזרועות.
#  "THEY LEARNED STEEL - TOGETHER": כל ה-IRONARMS בשלב לומדים יחד (main meta):
#    קפצת מעל ירייה -> כולם מקדימים יותר (ia_lead) ומכוונים גבוה. התכופפת -> מכוונים נמוך.
#    התחבאת מאחורי מחסה COVER_LEARN פעמים -> יורים בקשת מעל המחסה (Lob).
#  בוס "THE MACHINIST" (chase_range > 600): ענק, ארבע זרועות (2 תותחים + 2 משגרי רקטות), BARRAGE של כל התותחים,
#    רקטות בקשת (ROCKET_CD), ופעם אחת כשהוא נפגע קשה - REBUILD: עוצר ומרכיב מחדש את הזרועות שנפלו.
#  צלילים: "ia_shot", "ia_charge", "ia_blast", "ia_break", "ia_servo", "ia_rocket".
#  לשנות: ARM_HP, BOSS_ARM_HP, VOLLEY_N, SHOT_GAP, CHARGE_EVERY, CHARGE_T, SHOT_V, KEEP, COVER_LEARN, ROCKET_CD.
# ============================================================

const SB := preload("res://enemies/stationary_boss.gd")

const SOUNDS := {
	"ia_shot": [["N", 0, 0, 0.0, 0.08, 0.0, 40.0, 0.6, 0.5, 0], ["S", 230, 90, 0.0, 0.09, 0.0, 38.0, 0.5, 1.0, 0], ["S", 1900, 1300, 0.0, 0.04, 0.0, 80.0, 0.15, 1.0, 0]],
	"ia_charge": [["Q", 110, 520, 0.0, 1.0, 0.05, 0.0, 0.25, 0.4, 0.05], ["S", 400, 1500, 0.0, 1.0, 0.05, 0.0, 0.12, 1.0, 0.02]],
	"ia_blast": [["N", 0, 0, 0.0, 0.35, 0.0, 9.0, 0.8, 0.3, 0], ["S", 140, 40, 0.0, 0.3, 0.0, 10.0, 0.7, 1.0, 0], ["Q", 900, 200, 0.0, 0.2, 0.0, 15.0, 0.2, 0.5, 0]],
	"ia_break": [["S", 900, 300, 0.0, 0.3, 0.0, 10.0, 0.4, 1.0, 0], ["N", 0, 0, 0.0, 0.25, 0.0, 14.0, 0.5, 0.5, 0], ["C", 0, 0, 0.0, 0.2, 0.0, 20.0, 0.4, 1.0, 0]],
	"ia_servo": [["S", 300, 560, 0.0, 0.16, 0.02, 8.0, 0.14, 1.0, 0], ["N", 0, 0, 0.0, 0.1, 0.0, 30.0, 0.06, 1.0, 0, 0.5]],
	"ia_rocket": [["N", 0, 0, 0.0, 0.6, 0.02, 4.0, 0.5, 0.4, 0, 0.5], ["S", 300, 900, 0.0, 0.4, 0.0, 6.0, 0.2, 1.0, 0]],
}

const ARM_HP := 36
const BOSS_ARM_HP := 70
const VOLLEY_N := 4
const BOSS_VOLLEY_N := 10
const SHOT_GAP := 0.32
const ONE_ARM_SLOW := 1.8
const CHARGE_EVERY := 3
const CHARGE_T := 1.0
const BLAST_DMG := 2
const SHOT_V := 640.0
const RANGE := 640.0
const KEEP := 280.0
const CD := Vector2(1.4, 2.3)
const RAGE_SPEED := 1.5
const COVER_LEARN := 2
const ROCKET_CD := 5.5
const REBUILD_T := 2.2
const EXPLODE_ARM := 30      # פיצוץ: כמה נזק לכל זרוע

# זרוע: [כתף מקומית, גובה עליון, גובה תחתון של אזור הפגיעה (מקומי, לפני sc), סוג, מאחורי הגוף?]
const ARMS := [[Vector2(4, -39), -42.0, -33.0, "gun", false], [Vector2(-3, -33), -33.0, -21.0, "gun", true]]
const BOSS_ARMS := [[Vector2(-6, -44), -42.0, -37.0, "rocket", true], [Vector2(4, -39), -37.0, -31.0, "gun", false],
	[Vector2(-3, -33), -31.0, -26.0, "gun", true], [Vector2(5, -29), -26.0, -20.0, "rocket", false]]

enum { WALK, AIM, VOLLEY, CHARGE, REBUILD, RAGE }
var state := WALK
var arms := []                # [{hp, alive, kick}]
var shots := 0                # לבדיקות
var hits := 0
var blasts := 0
var lobs := 0
var rockets := 0
var arms_lost := 0
var rebuilt := false
var _st := 0.0
var _cd := 1.0
var _volleys := 0
var _left := 0
var _gap := 0.0
var _next := 0
var _ang := 0.0               # זווית הכוונה (מקומית: 0 = קדימה)
var _rocket_cd := 3.0
var _glow := 0.0


func _boss() -> bool:
	return z != null and float(z.chase_range) > 600.0


func _layout() -> Array:
	return BOSS_ARMS if _boss() else ARMS


func stats() -> Dictionary:
	if _boss():
		return {"name": "IRONARMS", "hp": 340, "walk": 30.0, "chase": 58.0, "damage": 2, "bite_delay": 1.0, "scale": 1.7, "width": 1.45,
			"duck": 0.0, "cover": 0.0, "skin": Color("8a9480"), "shirt": Color("3a4a5a"), "pants": Color("2a2a30"), "shoe": Color("1a1a1a"),
			"points": 1400, "boss": true, "boss_name": "THE MACHINIST"}
	return {"name": "IRONARMS", "hp": 60, "walk": 36.0, "chase": 70.0, "damage": 1, "bite_delay": 0.9, "scale": 1.15, "width": 1.2,
		"duck": 0.0, "cover": 0.1, "skin": Color("8a9a84"), "shirt": Color("5a6a7a"), "pants": Color("2e3440"), "shoe": Color("1a1612"), "points": 520}


func brain_overrides() -> Dictionary:
	return {"aggression": 0.15, "keep_range": KEEP}


func setup() -> void:
	arms.clear()
	for a in _layout():
		arms.append({"hp": BOSS_ARM_HP if _boss() else ARM_HP, "alive": true, "kick": 0.0})


func alive_arms(kind := "") -> Array:
	var r := []
	for i in arms.size():
		if arms[i].alive and (kind == "" or _layout()[i][3] == kind):
			r.append(i)
	return r


func can_bite() -> bool:
	return state == WALK or state == RAGE


func logic(_pl: Node, _d: Vector2, _delta: float, speed: float) -> float:
	return speed * RAGE_SPEED if state == RAGE else speed


# ---- למידה משותפת (main meta) ----
func _main() -> Node:
	return z.get_parent()


func _m(key: String, def: float) -> float:
	var m := _main()
	return float(m.get_meta(key)) if m != null and m.has_meta(key) else def


func _set_m(key: String, v: float) -> void:
	var m := _main()
	if m != null:
		m.set_meta(key, v)


func shot_result(hit: bool) -> void:   # SB.Shot / SB.Lob מדווחים
	if hit:
		hits += 1
		return
	if z.dead:
		return
	var pl := player()
	if pl == null or pl.dead:
		return
	if not pl.is_on_floor():
		var lead := _m("ia_lead", 0.0)
		if lead < 0.35:
			_set_m("ia_lead", minf(lead + 0.1, 0.35))
			_set_m("ia_aim_y", maxf(_m("ia_aim_y", -28.0) - 7.0, -50.0))
			z._popup("THEY LEAD YOUR JUMPS", Color("ffb070"), 12, -90.0 * z.sc)
	elif pl._crouching:
		var ay := _m("ia_aim_y", -28.0)
		if ay < -14.0:
			_set_m("ia_aim_y", minf(ay + 6.0, -14.0))
			z._popup("THEY AIM LOW", Color("ffb070"), 12, -90.0 * z.sc)


# ---- נקודות ----
func _w(local: Vector2) -> Vector2:   # מקומי (פונה ימינה) -> עולם
	return z.global_position + Vector2(local.x * z._dir * z.wf, local.y) * z.sc


func _arm_pts(i: int) -> Array:   # [כתף, מרפק, לוע] מקומי
	var s: Vector2 = _layout()[i][0]
	var a := _ang + (0.1 if _layout()[i][3] == "rocket" else 0.0) * (-1.0 if i == 0 else 1.0)
	var k: float = arms[i].kick if i < arms.size() else 0.0
	if state == RAGE or state == REBUILD:
		a = 0.9
	var e := s + Vector2(6.0, 4.0) - Vector2.from_angle(a) * k * 4.0
	var m := e + Vector2.from_angle(a) * 19.0
	return [s, e, m]


func _muzzle(i: int) -> Vector2:
	return _w(_arm_pts(i)[2])


# ---- נזק: הזרועות מברזל ----
func on_damage(_amount: int, hit_pos: Vector2, dir: Vector2, src: Dictionary) -> bool:
	if z.dead:
		return true
	var source := str(src.get("source", "bullet"))
	var explosive: bool = src.has("blast") or src.get("explosive", false) or source in ["grenade", "barrel", "boom", "rocket", "car"]
	if explosive:
		for i in arms.size():
			if arms[i].alive:
				_arm_hit(i, EXPLODE_ARM, dir)
		return true
	if not (source == "bullet" or source == "melee"):
		return true
	if dir.x * z._dir >= 0.0 or state == RAGE:   # מאחור: נזק רגיל לגוף
		return true
	var ly: float = (hit_pos.y - z.global_position.y) / z.sc
	for i in arms.size():
		var l: Array = _layout()[i]
		if arms[i].alive and ly >= float(l[1]) and ly < float(l[2]):
			_arm_hit(i, hit_damage(0, hit_pos, src), dir)
			Sfx.play("metal_ping", hit_pos, -2.0, 0.18, 4)
			Particles.burst(z.get_parent(), hit_pos, "spark", Vector2(-dir.x, -0.5), 5)
			Game.on_zombie_hit({"source": "bullet", "zone": "arm"})
			return false
	return true


func _arm_hit(i: int, dmg: int, dir: Vector2) -> void:
	arms[i].hp = int(arms[i].hp) - maxi(dmg, 1)
	z._flash = 0.06
	if int(arms[i].hp) > 0:
		return
	arms[i].alive = false
	arms_lost += 1
	var pts := _arm_pts(i)
	var piece := ArmPiece.new()
	piece.kind = _layout()[i][3]
	piece.sc = z.sc
	piece.face = z._dir
	piece.velocity = Vector2(-dir.x * randf_range(-60.0, 160.0) if dir.x != 0.0 else 0.0, -randf_range(160.0, 300.0))
	z.get_parent().add_child(piece)
	piece.global_position = _w(pts[1])
	Particles.burst(z.get_parent(), _w(pts[0]), "spark", Vector2(z._dir, -1.0), 14)
	Particles.burst(z.get_parent(), _w(pts[0]), "smoke", Vector2.UP, 4)
	Sfx.play("ia_break", _w(pts[0]), 2.0, 0.1, 3)
	z._popup("ARM OFF!", Color("ffd060"), 16, -80.0 * z.sc)
	Game.story.emit("crumble", {"z": z})
	if alive_arms().is_empty():
		if _boss() and not rebuilt:
			_start_rebuild()
		else:
			state = RAGE
			z._popup("NO ARMS - RAGE!", Color("ff6040"), 16, -95.0 * z.sc)
			Sfx.play("roar", z.global_position, 2.0, 0.1, 2, 0.8)


func _start_rebuild() -> void:
	rebuilt = true
	state = REBUILD
	_st = REBUILD_T
	z._popup("REBUILD!", Color("80d0ff"), 18, -110.0 * z.sc)
	Sfx.play("ia_charge", z.global_position, 2.0, 0.05, 2, 0.6)


func damage_mult(_zone: String, _src: Dictionary) -> float:
	return 0.5 if state == REBUILD else 1.0   # מתכופף מאחורי השלד בזמן ההרכבה


func on_death() -> void:
	for i in arms.size():   # מה שנשאר נופל
		if arms[i].alive:
			arms[i].alive = false
			var piece := ArmPiece.new()
			piece.kind = _layout()[i][3]
			piece.sc = z.sc
			piece.face = z._dir
			piece.velocity = Vector2(randf_range(-120.0, 120.0), -randf_range(120.0, 260.0))
			z.get_parent().add_child(piece)
			piece.global_position = _w(_arm_pts(i)[1])


# ============================================================
#  התנהגות
# ============================================================
func physics(pl: Node, delta: float) -> bool:
	_cd -= delta
	_st -= delta
	_gap -= delta
	_rocket_cd -= delta
	for a in arms:
		a.kick = maxf(float(a.kick) - delta * 6.0, 0.0)
	if z.dead:
		return false
	_glow = move_toward(_glow, 1.0 if state == CHARGE else 0.0, delta * (1.0 / CHARGE_T if state == CHARGE else 4.0))
	var has_pl: bool = pl != null and not pl.dead
	if has_pl and state != RAGE and state != REBUILD:
		var tgt := _target(pl)
		var c := _w(Vector2(8, -34))
		var want := (tgt - c).angle()
		var la := want if z._dir > 0.0 else PI - want   # מקומי: 0 = קדימה
		la = wrapf(la, -PI, PI)
		_ang = lerp_angle(_ang, clampf(la, -0.65, 0.55), delta * 6.0)
	match state:
		WALK:
			if _boss() and not rebuilt and z.hp < z.max_hp / 2 and arms_lost > 0:
				_start_rebuild()
				return _stay(delta)
			if not has_pl or _cd > 0.0 or alive_arms().is_empty():
				return false
			var d: Vector2 = pl.global_position - z.global_position
			var sees: bool = z.brain == null or z.brain.sees or float(z.brain.seen_t) < 3.0 or _boss()   # (מאחורי מחסה: זוכר איפה אתה)
			if not sees or absf(d.x) > RANGE or absf(d.y) > 220.0:
				return false
			z._dir = signf(d.x) if d.x != 0.0 else z._dir
			if _boss() and _rocket_cd <= 0.0 and not alive_arms("rocket").is_empty():
				_rockets(pl)
				_rocket_cd = ROCKET_CD
				_cd = 1.0
				return _stay(delta)
			_volleys += 1
			if _volleys % CHARGE_EVERY == 0 and not alive_arms("gun").is_empty():
				state = CHARGE
				_st = CHARGE_T
				Sfx.play("ia_charge", z.global_position, 0.0, 0.05, 2)
				z._popup("!", Color("80e0ff"), 18, -80.0 * z.sc)
			else:
				state = AIM
				_st = 0.3
				Sfx.play("ia_servo", z.global_position, -4.0, 0.1, 2)
			return _stay(delta)
		AIM:
			if _st <= 0.0:
				state = VOLLEY
				_left = BOSS_VOLLEY_N if _boss() else VOLLEY_N
				_gap = 0.0
			return _stay(delta)
		VOLLEY:
			var guns := alive_arms("gun")
			if guns.is_empty() or not has_pl:
				_end_attack()
				return _stay(delta)
			if _gap <= 0.0:
				_next = (_next + 1) % guns.size()
				_fire(guns[_next], pl, false)
				_left -= 1
				_gap = SHOT_GAP * (ONE_ARM_SLOW if guns.size() == 1 else 1.0) * (0.5 if _boss() else 1.0)
				if _left <= 0:
					_end_attack()
			return _stay(delta)
		CHARGE:
			if randf() < delta * 20.0:
				for i in alive_arms("gun"):
					Particles.burst(z.get_parent(), _muzzle(i), "spark", Vector2.UP, 1)
			if _st <= 0.0:
				blasts += 1
				for i in alive_arms("gun"):
					if has_pl:
						_fire(i, pl, true)
				Sfx.play("ia_blast", z.global_position, 2.0, 0.08, 2)
				_end_attack()
			return _stay(delta)
		REBUILD:
			if randf() < delta * 14.0:
				Particles.burst(z.get_parent(), _w(Vector2(0, -36)), "spark", Vector2(randf_range(-1, 1), -1), 2)
			if _st <= 0.0:
				for a in arms:
					a.alive = true
					a.hp = int(BOSS_ARM_HP * 0.6)
				state = WALK
				_cd = 0.6
				z._popup("ARMS BACK ONLINE", Color("80d0ff"), 15, -110.0 * z.sc)
			return _stay(delta)
		RAGE:
			return false
	return false


func _end_attack() -> void:
	state = WALK
	_cd = randf_range(CD.x, CD.y) * (0.7 if _boss() else 1.0)


func _stay(delta: float) -> bool:
	z.velocity.x = move_toward(z.velocity.x, 0.0, 800.0 * delta)
	if not z.is_on_floor():
		z.velocity.y += z.gravity * delta
	z.move_and_slide()
	return true


func _target(pl: Node) -> Vector2:
	return pl.global_position + Vector2(pl.velocity.x * _m("ia_lead", 0.0), _m("ia_aim_y", -28.0))


func _fire(i: int, pl: Node, big: bool) -> void:
	var from := _muzzle(i)
	var tgt := _target(pl)
	arms[i].kick = 1.0
	shots += 1
	var clear := _clear(from, pl.global_position + Vector2(0, -26))
	if not clear:   # מחסה בדרך
		var seen := _m("ia_cover", 0.0) + 1.0
		_set_m("ia_cover", seen)
		if int(seen) == COVER_LEARN:
			z._popup("THEY LOB OVER COVER", Color("ffb070"), 12, -90.0 * z.sc)
	if not clear and _m("ia_cover", 0.0) >= float(COVER_LEARN):
		_lob(from, pl.global_position + Vector2(0, -10), "orb", 0.0)
		return
	var s = SB.Shot.new()
	s.owner_t = self
	s.velocity = (tgt - from).normalized() * (SHOT_V * (1.2 if big else 1.0))
	s.damage = BLAST_DMG if big else 1
	s.kind = "orb" if big else "bolt"
	s.col = Color(0.5, 0.9, 1.0) if big else Color(1.0, 0.75, 0.35)
	s.r = 9.0 if big else 4.5
	z.get_parent().add_child(s)
	s.global_position = from
	Particles.burst(z.get_parent(), from, "fire", (tgt - from).normalized(), 3)
	Sfx.play("ia_shot", from, -3.0 if not big else 0.0, 0.12, 4, 0.8 if big else 1.0)


func _clear(from: Vector2, to: Vector2) -> bool:
	var q := PhysicsRayQueryParameters2D.create(from, to, 1)
	var ex: Array[RID] = [z.get_rid()]
	q.exclude = ex
	return z.get_world_2d().direct_space_state.intersect_ray(q).is_empty()


func _lob(from: Vector2, to: Vector2, kind: String, blast: float) -> void:
	var l = SB.Lob.new()
	l.owner_t = self
	var t := clampf(absf(to.x - from.x) / 300.0, 0.7, 1.6)
	l.gravity = 900.0
	l.velocity = Vector2((to.x - from.x) / t, (to.y - from.y) / t - 0.5 * l.gravity * t)
	l.kind = kind
	l.col = Color(1.0, 0.7, 0.3)
	l.r = 6.0
	l.blast_r = blast
	z.get_parent().add_child(l)
	l.global_position = from
	lobs += 1
	Sfx.play("ia_shot", from, -4.0, 0.1, 3, 0.7)


func _rockets(pl: Node) -> void:
	var k := 0
	for i in alive_arms("rocket"):
		arms[i].kick = 1.0
		for q in 2:
			k += 1
			rockets += 1
			_lob(_muzzle(i), pl.global_position + Vector2(randf_range(-90.0, 90.0) + float(k) * 25.0 * z._dir, 0.0), "rocket", 70.0)
	Sfx.play("ia_rocket", z.global_position, 2.0, 0.1, 2)
	z._popup("ROCKETS!", Color("ff9040"), 15, -120.0 * z.sc)


# ============================================================
#  זרוע שנפלה: חתיכת מתכת שקופצת על הרצפה, מעלה ניצוצות ונעלמת
# ============================================================
class ArmPiece extends Node2D:
	var kind := "gun"
	var sc := 1.0
	var face := 1.0
	var velocity := Vector2.ZERO
	var spin := 0.0
	var life := 8.0
	var _rest := false
	var _spark := 0.0

	func _ready() -> void:
		z_index = 4
		spin = randf_range(-9.0, 9.0)

	func _physics_process(delta: float) -> void:
		life -= delta
		if life <= 0.0:
			queue_free()
			return
		if _rest:
			_spark -= delta
			if _spark <= 0.0 and life > 4.0:
				_spark = randf_range(0.5, 1.2)
				preload("res://particles.gd").burst(get_parent(), global_position + Vector2(0, -4), "spark", Vector2.UP, 2)
			if life < 1.0:
				modulate.a = life
			return
		velocity.y += 1100.0 * delta
		var to := global_position + velocity * delta
		var hit := get_world_2d().direct_space_state.intersect_ray(PhysicsRayQueryParameters2D.create(global_position, to + Vector2(0, 4), 1 | 16))
		if not hit.is_empty() and velocity.y > 0.0:
			global_position = hit.position - Vector2(0, 4)
			velocity = Vector2(velocity.x * 0.4, -velocity.y * 0.3)
			spin *= 0.5
			preload("res://sfx.gd").play("clink", global_position, -6.0, 0.15, 3)
			if absf(velocity.y) < 60.0:
				_rest = true
				rotation = 0.0 if absf(wrapf(rotation, -PI, PI)) < PI * 0.5 else PI
				queue_redraw()
				return
		else:
			global_position = to
		rotation += spin * delta
		queue_redraw()

	func _draw() -> void:
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(face * sc, sc))
		Art.limb(self, PackedVector2Array([Vector2(-10, 0), Vector2(-3, 0)]), 5.0, Color("6a6e74"))
		if kind == "rocket":
			Art.fill(self, PackedVector2Array([Vector2(-4, -5), Vector2(10, -5), Vector2(10, 5), Vector2(-4, 5)]), Color("5a4a3a"))
			for q in 3:
				draw_circle(Vector2(10, -3 + q * 3), 1.4, Color(0.1, 0.1, 0.1))
		else:
			Art.fill(self, PackedVector2Array([Vector2(-4, -4), Vector2(9, -3), Vector2(9, 3), Vector2(-4, 4)]), Color("7a7e86"))
			Art.fill(self, PackedVector2Array([Vector2(9, -2), Vector2(16, -2), Vector2(16, 2), Vector2(9, 2)]), Color("3a3c40"))
		draw_line(Vector2(-10, 0), Vector2(-14, randf_range(-3, 3)), Color(0.9, 0.2, 0.15), 1.4)   # צינור קרוע
		draw_line(Vector2(-10, 1), Vector2(-13, 4), Color(0.3, 0.3, 0.35), 1.2)


# ============================================================
#  ציור: גוף רחב של פועל נמל (גופייה קרועה, כתפיות ברזל מוברגות לבשר), מנוע על הגב עם צינורות,
#  ראש עם לסת מתכת ועין אופטית אדומה. הזרועות: בוכנה + מרפק + קנה תותח (זוהרות בטעינה).
# ============================================================
const STEEL := Color("7a7e86")
const STEEL_D := Color("4a4e56")
const BRASS := Color("b89040")


func draw() -> bool:
	begin_draw()
	var sk := col(z.skin)
	var shirt := col(z.shirt)
	var f: Array = feet(4.5, 2.5) if state != RAGE else feet(6.5, 3.5)
	var hip := Vector2(0, -21)
	var lean := 4.0 if state == RAGE else (-1.5 if state == CHARGE else 0.0)
	var sh := Vector2(1.0 + lean, -38.0)
	var head := sh + Vector2(4.0 + lean * 0.3, -9.0)
	# המנוע על הגב
	var pack := sh + Vector2(-12, 3)
	Art.fill_shaded(z, PackedVector2Array([pack + Vector2(-5, -6), pack + Vector2(6, -7), pack + Vector2(7, 13), pack + Vector2(-6, 14)]), col(STEEL_D), 0.15, 0.35)
	z.draw_rect(Rect2(pack + Vector2(-3, -3), Vector2(7, 3)), col(BRASS))
	var vent := 0.5 + 0.5 * sin(z._time * 6.0)
	z.draw_circle(pack + Vector2(0, 6), 2.2, Color(1.0, 0.35 + 0.3 * _glow, 0.15 + 0.6 * _glow, 0.6 + 0.4 * vent))
	if not z.dead and Engine.get_physics_frames() % 40 == 0 and Art.on_screen(z, z.global_position):
		Particles.burst(z.get_parent(), _w(pack + Vector2(0, -8)), "smoke", Vector2.UP, 1)
	# זרועות שמאחורי הגוף
	for i in arms.size():
		if _layout()[i][4]:
			_draw_arm(i, sk)
	z._leg(hip + Vector2(-3, 0), f[1], col(Art.shade(z.pants, 0.25)), sk, col(z.shoe))
	z._leg(hip + Vector2(3, 0), f[0], col(z.pants), sk, col(z.shoe))
	# גוף: גופייה קרועה על חזה רחב
	var torso := PackedVector2Array([sh + Vector2(-10, -2), sh + Vector2(9, -1), sh + Vector2(9, 9), hip + Vector2(7, 2), hip + Vector2(-7, 2), sh + Vector2(-10, 9)])
	Art.fill_shaded(z, torso, shirt, 0.12, 0.4)
	Art.fill(z, PackedVector2Array([sh + Vector2(-4, 6), sh + Vector2(3, 9), sh + Vector2(-1, 14)]), sk, Art.NONE)   # קרע
	z.draw_line(sh + Vector2(-7, 2), sh + Vector2(-6, 14), col(Color(0.5, 0.1, 0.1, 0.6)), 1.0)   # תפר
	# צינורות מהמנוע לכתפיים
	z.draw_line(pack + Vector2(4, -6), sh + Vector2(2, -2), col(Color("9a2a22")), 1.8)
	z.draw_line(pack + Vector2(5, 0), sh + Vector2(0, 5), col(Color("2a2a30")), 1.6)
	# כתפיות ברזל מוברגות
	Art.oval_shaded(z, sh + Vector2(3, 0), 6.5, 4.5, col(STEEL), -0.2)
	for q in 3:
		z.draw_circle(sh + Vector2(-0.5 + float(q) * 3.0, 0.5 - float(q) * 0.6), 0.8, col(BRASS))
	z.draw_rect(Rect2(hip + Vector2(-7, -1), Vector2(14, 3)), col(Color("2a2018")))   # חגורה
	# ראש: לסת מתכת + עין אופטית
	Art.oval_shaded(z, head, 5.6, 6.0, sk, 0.0)
	Art.fill(z, PackedVector2Array([head + Vector2(-2, 1), head + Vector2(6, 1), head + Vector2(5.5, 6), head + Vector2(-1, 6.5)]), col(STEEL), Art.OUTLINE, 0.9)
	for q in 3:
		z.draw_line(head + Vector2(0.5 + float(q) * 2.0, 2.5), head + Vector2(0.5 + float(q) * 2.0, 5.5), col(STEEL_D), 0.7)
	z.draw_circle(head + Vector2(3.5, -1.5), 2.2, col(Color("2a2a30")))
	if not z.dead:
		z.draw_circle(head + Vector2(3.8, -1.5), 1.2, Color(1.0, 0.2, 0.15))
		Art.glow(z, head + Vector2(3.8, -1.5), 4.0, Color(1.0, 0.2, 0.1, 0.5))
	z.draw_line(head + Vector2(-5, -3), head + Vector2(2, -6), col(Color(0.3, 0.1, 0.1, 0.6)), 0.9)   # תפרים על הקרקפת
	# זרועות שלפני הגוף
	for i in arms.size():
		if not _layout()[i][4]:
			_draw_arm(i, sk)
	end_draw()
	return true


func _draw_arm(i: int, sk: Color) -> void:
	var pts := _arm_pts(i)
	var s: Vector2 = pts[0]
	if not arms[i].alive:   # גדם: בשר + חוטים קרועים
		Art.disc(z, s + Vector2(2, 2), 3.0, col(Color("6a2a24")))
		z.draw_line(s + Vector2(3, 3), s + Vector2(6, 6 + sin(z._time * 9.0)), col(Color(0.9, 0.2, 0.15)), 1.0)
		if not z.dead and randf() < 0.08:
			z.draw_circle(s + Vector2(6, 6), 1.6, Color(1.0, 0.9, 0.5))
		return
	var e: Vector2 = pts[1]
	var m: Vector2 = pts[2]
	var dk: float = 0.82 if _layout()[i][4] else 1.0   # מאחור = כהה יותר
	var st := col(STEEL * Color(dk, dk, dk))
	# עליון: בוכנה
	Art.limb(z, PackedVector2Array([s, e]), 4.6, col(STEEL_D * Color(dk, dk, dk)))
	z.draw_line(s + Vector2(0, -2), s.lerp(e, 0.7) + Vector2(0, -2), col(Color("c8c8d0")), 1.2)
	Art.disc(z, e, 2.8, col(BRASS), Art.OUTLINE, 1.0)
	z.draw_line(e, s + Vector2(-1, 4), col(Color("9a2a22")), 1.2)   # צינור הידראולי
	# אמה = קנה
	var dirv := (m - e).normalized()
	var n := dirv.orthogonal()
	if _layout()[i][3] == "rocket":
		var b0 := e + dirv * 3.0
		Art.fill_shaded(z, PackedVector2Array([b0 + n * 5.0, b0 + dirv * 14.0 + n * 5.0, b0 + dirv * 14.0 - n * 5.0, b0 - n * 5.0]), col(Color("5a4a3a")), 0.15, 0.3)
		for q in 3:
			z.draw_circle(b0 + dirv * 14.0 + n * (-3.0 + float(q) * 3.0), 1.3, Color(0.08, 0.06, 0.05))
		if _rocket_cd < 1.0 and not z.dead:
			Art.glow(z, b0 + dirv * 15.0, 6.0, Color(1.0, 0.5, 0.2, 0.7))
		return
	Art.fill_shaded(z, PackedVector2Array([e + n * 3.6, e + dirv * 13.0 + n * 3.2, e + dirv * 13.0 - n * 3.2, e - n * 3.6]), st, 0.18, 0.35)
	for q in 2:   # טבעות קירור
		var rp := e + dirv * (5.0 + float(q) * 4.0)
		z.draw_line(rp + n * 3.6, rp - n * 3.6, col(STEEL_D), 1.0)
	Art.fill(z, PackedVector2Array([e + dirv * 13.0 + n * 2.0, m + n * 2.0, m - n * 2.0, e + dirv * 13.0 - n * 2.0]), col(Color("2e3036")), Art.OUTLINE, 0.9)
	z.draw_circle(m, 1.3, Color(0.05, 0.05, 0.05))
	var g := _glow if state == CHARGE else 0.0
	if g > 0.0 and not z.dead:
		Art.glow(z, m, 5.0 + 6.0 * g, Color(0.5, 0.9, 1.0, 0.5 + 0.4 * g))
		z.draw_line(e + dirv * 4.0, m, Color(0.5, 0.9, 1.0, 0.6 * g), 1.4)
	if float(arms[i].kick) > 0.6 and not z.dead:   # הבזק
		Art.glow(z, m + dirv * 3.0, 6.0, Color(1.0, 0.8, 0.4, 0.8))
	if int(arms[i].hp) < (BOSS_ARM_HP if _boss() else ARM_HP) / 2:   # זרוע פגועה: ניצוצות
		if not z.dead and randf() < 0.2:
			z.draw_circle(e + n * 2.0, 1.2, Color(1.0, 0.9, 0.5))
