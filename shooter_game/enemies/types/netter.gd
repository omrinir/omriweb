extends "res://enemies/zombie_type.gd"
# ============================================================
#  NETTER (שלב 31, "FLOATING ISLANDS") - דייג זומבי: כובע צ'ויו סרוג עם דשים, פונצ'ו, רשת דייגים על הכתף.
#  "THEY LEARNED TO FISH": שומר מרחק, מסובב את הרשת מעל הראש (WIND_T = אזהרה) וזורק אותה בקשת אליך.
#  נתפסת (Net): נזק 1, איטי מאוד, אי אפשר לקפוץ, והוא מושך אותך אליו בחבל (REEL_V). הגעת אליו -> מכה כל HIT_CD.
#  משתחררים: גלגול (SHIFT) קורע את הרשת / פגיעה חזקה בו (CUT_DMG) / להרוג אותו / NET_T נגמר.
#  לשנות: RANGE, WIND_T, NET_T, REEL_V, NET_CD, CUT_DMG.
# ============================================================

const SOUNDS := {
	"nt_whirl": [["N", 0, 0, 0.0, 0.5, 0.05, 3.0, 0.25, 0.25, 0, 0.1], ["S", 200, 260, 0.0, 0.5, 0.05, 3.0, 0.1, 1.0, 0.1]],
	"nt_catch": [["N", 0, 0, 0.0, 0.2, 0.0, 14.0, 0.5, 0.5, 0], ["S", 300, 180, 0.0, 0.12, 0.0, 20.0, 0.3, 1.0, 0]],
	"nt_rip": [["N", 0, 0, 0.0, 0.25, 0.0, 12.0, 0.6, 0.7, 0, 0.3]],
}

const RANGE := Vector2(120.0, 430.0)
const WIND_T := 0.55
const NET_T := 3.0
const REEL_V := 70.0
const NET_CD := 4.5
const CUT_DMG := 14
const BACKOFF := 200.0
const HIT_CD := 0.9          # נתפסת ונמשכת אליו: מכה כל HIT_CD

enum { WALK, WIND, WAIT }
var state := WALK
var throws := 0              # לבדיקות
var catches := 0
var hits := 0
var _hit_cd := 0.0
var _st := 0.0
var _cd := 1.0
var net: Node = null         # הרשת שתופסת עכשיו את השחקן


func stats() -> Dictionary:
	return {"name": "NETTER", "hp": 30, "walk": 42.0, "chase": 80.0, "damage": 1, "bite_delay": 0.8, "scale": 1.0, "width": 0.95,
		"duck": 0.0, "cover": 0.2, "skin": Color("8a9474"), "shirt": Color("8a3a2e"), "pants": Color("2e2a2a"), "shoe": Color("3a2a1a"), "points": 430}


func brain_overrides() -> Dictionary:
	return {"aggression": 0.15, "keep_range": 280.0}


func can_bite() -> bool:
	return state == WALK


func _netted(pl: Node) -> bool:
	return pl != null and pl.has_meta("netted") and is_instance_valid(pl.get_meta("netted"))


func on_damage(amount: int, _hit_pos: Vector2, _dir: Vector2, src: Dictionary) -> bool:
	if net != null and is_instance_valid(net) and hit_damage(amount, _hit_pos, src) >= CUT_DMG:
		net.release("cut")
	return true


func physics(pl: Node, delta: float) -> bool:
	_st -= delta
	_cd -= delta
	if z.dead:
		return false
	var has_pl: bool = pl != null and not pl.dead
	var d := Vector2.ZERO
	if has_pl:
		d = pl.global_position - z.global_position
	match state:
		WALK:
			if net != null and is_instance_valid(net):   # מושך את הרשת: עומד במקום. הגעת אליו -> מכה
				z._dir = signf(d.x) if absf(d.x) > 4.0 else z._dir
				_hit_cd -= delta
				if has_pl and absf(d.x) < 34.0 and absf(d.y) < 50.0 and _hit_cd <= 0.0:
					_hit_cd = HIT_CD
					hits += 1
					pl.hurt(1, Vector2(signf(d.x) * 0.6, -0.3))
					Sfx.play("nt_catch", z.global_position, -2.0, 0.1, 2)
				return _stay(delta)
			if has_pl and _cd <= 0.0 and absf(d.x) > RANGE.x and absf(d.x) < RANGE.y and absf(d.y) < 90.0 and not _netted(pl) and z.is_on_floor():
				state = WIND
				_st = WIND_T
				z._dir = signf(d.x)
				Sfx.play("nt_whirl", z.global_position, -2.0, 0.1, 2)
				return _stay(delta)
			if has_pl and absf(d.x) < BACKOFF and absf(d.y) < 90.0 and not _netted(pl):   # שומר מרחק לזריקה
				z._dir = signf(d.x) if absf(d.x) > 4.0 else z._dir
				z.velocity.x = move_toward(z.velocity.x, -z._dir * float(z.walk_speed) * 1.6, 600.0 * delta)
				if not z.is_on_floor():
					z.velocity.y += z.gravity * delta
				elif z.is_on_wall():
					z.velocity.y = -380.0
				z.move_and_slide()
				return true
			return false
		WIND:
			if has_pl:
				z._dir = signf(d.x) if absf(d.x) > 4.0 else z._dir
			if _st <= 0.0:
				_throw(pl)
				state = WAIT
				_st = 0.5
			return _stay(delta)
		WAIT:
			if _st <= 0.0:
				state = WALK
			return _stay(delta)
	return false


func _stay(delta: float) -> bool:
	z.velocity.x = move_toward(z.velocity.x, 0.0, 800.0 * delta)
	if not z.is_on_floor():
		z.velocity.y += z.gravity * delta
	z.move_and_slide()
	return true


func _throw(pl: Node) -> void:
	throws += 1
	_cd = NET_CD
	var n := Net.new()
	n.owner_z = z
	z.get_parent().add_child(n)
	n.global_position = z.global_position + Vector2(z._dir * 10.0, -50.0)
	var target: Vector2 = (pl.global_position + Vector2(pl.velocity.x * 0.25, -20.0)) if pl != null else n.global_position + Vector2(z._dir * 250.0, 40.0)
	var flight := clampf(absf(target.x - n.global_position.x) / 420.0, 0.35, 0.9)
	n.velocity = Vector2((target.x - n.global_position.x) / flight, (target.y - n.global_position.y) / flight - 0.5 * n.gravity * flight)
	Sfx.play("throw", z.global_position, 0.0)


func on_death() -> void:
	if net != null and is_instance_valid(net):
		net.release("dead")


# ============================================================
#  הרשת: עפה בקשת. פוגעת בשחקן -> נתפס (מתחת לרגליים: איטי, בלי קפיצה, נמשך לדייג)
# ============================================================
class Net extends Node2D:
	const REEL := 70.0           # = REEL_V
	const LIFE := 3.0            # = NET_T
	var owner_z: Node = null
	var velocity := Vector2.ZERO
	var gravity := 900.0
	var caught: Node = null
	var cut_by := ""             # לבדיקות: "roll" / "cut" / "dead" / "time"
	var _t := 0.0
	var _life := 0.0

	func _ready() -> void:
		z_index = 9

	func _physics_process(delta: float) -> void:
		_t += delta
		if caught == null:
			velocity.y += gravity * delta
			var to := global_position + velocity * delta
			var pl := get_tree().get_first_node_in_group("player")
			if pl != null and not pl.dead and not pl.has_meta("netted") and pl.body_rect().grow(14.0).has_point(to) and pl._roll_t <= 0.0:
				_catch(pl)
				return
			var hit := get_world_2d().direct_space_state.intersect_ray(PhysicsRayQueryParameters2D.create(global_position, to, 1 | 16))
			if not hit.is_empty() or _t > 2.0:
				queue_free()   # פספס: נופלת לקרקע
				return
			global_position = to
			queue_redraw()
			return
		# תפוס
		if not is_instance_valid(caught) or caught.dead:
			release("dead")
			return
		if owner_z == null or not is_instance_valid(owner_z) or owner_z.dead:
			release("dead")
			return
		_life -= delta
		if caught._roll_t > 0.0:
			release("roll")
			return
		if _life <= 0.0:
			release("time")
			return
		var dir := signf(owner_z.global_position.x - caught.global_position.x)
		caught.velocity.x = clampf(caught.velocity.x, -70.0, 70.0)   # איטי מאוד
		if absf(owner_z.global_position.x - caught.global_position.x) > 22.0:   # נמשך לדייג (עד אליו)
			caught.move_and_collide(Vector2(dir * REEL * delta, 0.0))
		if caught.velocity.y < 0.0 and caught.is_on_floor():   # אי אפשר לקפוץ
			caught.velocity.y = 0.0
		global_position = caught.global_position
		queue_redraw()

	func _catch(pl: Node) -> void:
		caught = pl
		_life = LIFE
		pl.set_meta("netted", self)
		if owner_z != null and is_instance_valid(owner_z) and owner_z.type_mod != null:
			owner_z.type_mod.net = self
			owner_z.type_mod.catches += 1
		preload("res://sfx.gd").play("nt_catch", pl.global_position, 0.0)
		pl.hurt(1, Vector2.ZERO)   # משקולות הרשת
		pl._say("NETTED! ROLL (SHIFT) TO TEAR IT", Color("e0c080"))

	func release(why: String) -> void:
		cut_by = why
		if caught != null and is_instance_valid(caught) and caught.has_meta("netted"):
			caught.remove_meta("netted")
		if owner_z != null and is_instance_valid(owner_z) and owner_z.type_mod != null:
			owner_z.type_mod.net = null
		if why == "roll" or why == "cut":
			preload("res://sfx.gd").play("nt_rip", global_position, 0.0)
			preload("res://particles.gd").burst(get_parent(), global_position + Vector2(0, -30), "leaf", Vector2.UP, 6)
		caught = null
		queue_free()

	func _draw() -> void:
		var c := Color(0.85, 0.82, 0.7, 0.9)
		if caught == null:   # רשת פרושה באוויר
			var r := 16.0 + minf(_t * 30.0, 10.0)
			for q in 5:
				var a := float(q) * TAU / 5.0 + _t * 6.0
				DrawBatch.line(self, Vector2.ZERO, Vector2.from_angle(a) * r, c, 1.0)
			for k in 2:
				var pts := PackedVector2Array()
				for q in 9:
					pts.append(Vector2.from_angle(float(q) * TAU / 8.0 + _t * 6.0) * r * (0.5 + 0.5 * float(k)))
				DrawBatch.polyline(self, pts, c, 1.0)
			for q in 4:   # משקולות
				DrawBatch.circle(self, Vector2.from_angle(float(q) * TAU / 4.0 + _t * 6.0) * r, 1.8, Color("5a5a5a"))
			return
		# עוטפת את השחקן + חבל לדייג
		var h := 52.0
		for q in 6:
			var x := -14.0 + float(q) * 5.6
			DrawBatch.line(self, Vector2(x, 0), Vector2(x * 0.6, -h), c, 1.0)
		for q in 7:
			var y := -float(q) * h / 6.0
			var ww := 14.0 - float(q) * 0.9
			DrawBatch.line(self, Vector2(-ww, y), Vector2(ww, y), c, 1.0)
		if owner_z != null and is_instance_valid(owner_z):
			var hand: Vector2 = owner_z.global_position + Vector2(owner_z._dir * 10.0, -36.0) - global_position
			var mid := (Vector2(0, -26) + hand) * 0.5 + Vector2(0, 10)
			DrawBatch.polyline(self, PackedVector2Array([Vector2(0, -26), mid, hand]), Color("8a6a3a"), 1.6)


# ============================================================
#  ציור: צ'ויו סרוג צבעוני, פונצ'ו אדום, רשת על הכתף / מסתובבת מעל הראש
# ============================================================
func draw() -> bool:
	begin_draw()
	var sk := col(z.skin)
	var poncho := col(z.shirt)
	var p: float = z._walk_phase
	var f: Array = feet(4.5, 2.0)
	var hip := Vector2(0, -22)
	var sh := Vector2(1, -37)
	var head := sh + Vector2(3.5, -8)
	z._leg(hip + Vector2(-2, 0), f[1], col(Art.shade(z.pants, 0.25)), sk, col(z.shoe))
	z._leg(hip + Vector2(2, 0), f[0], col(z.pants), sk, col(z.shoe))
	var hb := sh + Vector2(-5.0 - sin(p) * 2.0, 15.0)
	var hf := sh + Vector2(9.0 + sin(p) * 2.0, 12.0)
	var winding: bool = state == WIND and not z.dead
	var reeling: bool = net != null and is_instance_valid(net) and not z.dead
	if winding:
		hf = sh + Vector2(4, -18)
	elif reeling:
		hb = sh + Vector2(10, 4)
		hf = sh + Vector2(12, 2)
	z._arm(sh + Vector2(-3, 1), hb, Art.shade(sk, 0.25), Art.shade(poncho, 0.3))
	if not winding and not reeling and not z.dead:   # רשת מקופלת על הכתף
		DrawBatch.colored_polygon(z, Art.ellipse(sh + Vector2(-6, 6), 6.0, 10.0, 0.3, 10), col(Color(0.8, 0.76, 0.6, 0.85)))
		for q in 3:
			DrawBatch.line(z, sh + Vector2(-10.0 + float(q) * 3.0, -2), sh + Vector2(-6.0 + float(q) * 3.0, 14), Color(0.5, 0.45, 0.35, 0.6), 1.0)
	Art.fill_shaded(z, PackedVector2Array([sh + Vector2(-9, -1), sh + Vector2(9, 0), hip + Vector2(9, 5), hip + Vector2(-9, 5)]), poncho, 0.12, 0.4)
	for q in 3:   # פסים בפונצ'ו
		DrawBatch.line(z, sh + Vector2(-8, 5.0 + float(q) * 5.0), sh + Vector2(8, 5.0 + float(q) * 5.0), col([Color("e0c030"), Color("2a8a6a"), Color("f0f0f0")][q]), 1.4)
	Art.oval_shaded(z, head, 5.0, 5.6, sk, 0.0)
	face(head, Vector2(3.0, -0.5))
	# צ'ויו: כובע צמר מחודד עם דשים לאוזניים
	Art.fill(z, PackedVector2Array([head + Vector2(-5.5, 1), head + Vector2(-5, -4), head + Vector2(0, -10), head + Vector2(5, -4), head + Vector2(5.5, 1), head + Vector2(3, -2), head + Vector2(-3, -2)]), col(Color("c02a4a")), Art.OUTLINE, 1.0)
	DrawBatch.line(z, head + Vector2(-4.5, -4), head + Vector2(4.5, -4), col(Color("f0d040")), 1.6)
	DrawBatch.line(z, head + Vector2(-5, 1), head + Vector2(-5.5, 7), col(Color("2a6ac0")), 1.6)   # חוטים תלויים
	DrawBatch.circle(z, head + Vector2(0, -10.5), 1.6, col(Color("f0f0f0")))
	if not z.dead:
		DrawBatch.circle(z, head + Vector2(3.0, -0.5), 1.0, Color(0.85, 0.9, 0.5))
	z._arm(sh + Vector2(3, 1), hf, sk, poncho)
	if winding:   # הרשת מסתובבת מעל הראש
		var c := hf + Vector2(0, -8)
		var a: float = z._time * 18.0
		for q in 4:
			DrawBatch.line(z, c, c + Vector2.from_angle(a + float(q) * PI * 0.5) * 12.0, Color(0.85, 0.82, 0.7, 0.9), 1.0)
		DrawBatch.arc(z, c, 12.0, 0.0, TAU, 12, Color(0.85, 0.82, 0.7, 0.7), 1.0)
	end_draw()
	return true
