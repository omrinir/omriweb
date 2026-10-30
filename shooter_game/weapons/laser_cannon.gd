extends RefCounted
const DrawBatch := preload("res://effects/draw_batch.gd")
# ============================================================
#  LASER CANNON - פריט מיוחד (progression/arsenal.gd -> SPECIALS "laser", CHARGES שימושים).
#  מחזיקים את הירי: נטען CHARGE_T שניות - חלקיקים ירוקים נשאבים לקנה, הליבה זוהרת, צליל עולה.
#  עזבת לפני הסוף = הטעינה מתבטלת (לא מבזבז שימוש).
#  טעינה מלאה -> פיצוץ אנרגיה: הבזק, גל הדף, רעידת מסך, ואז קרן ירוקה עבה שנמשכת BEAM_T שניות,
#  עוקבת אחרי הכוונת, עוברת דרך כל הזומבים בדרך (DPS כל TICK) ונעצרת רק בקירות.
#  חלקים: tick() (נקרא מ-player.gd כל פריים), ChargeFX (חלקיקי טעינה), Beam (הקרן), draw_gun() (הנשק ביד / על הריצפה).
#  לשנות: CHARGES (ב-arsenal), CHARGE_T, BEAM_T, TICK, DMG, RANGE, WIDTH, BOSS_K.
# ============================================================

const Art := preload("res://art.gd")
const Sfx := preload("res://sfx.gd")

const CHARGE_T := 1.4
const BEAM_T := 1.6
const TICK := 0.1            # כל כמה זמן הקרן פוגעת
const DMG := 18              # נזק לכל פגיעה (16 פגיעות בשנייה וחצי = ~290 למי שנשאר בקרן)
const BOSS_K := 0.6          # בוסים מקבלים פחות
const RANGE := 1500.0
const WIDTH := 22.0          # רוחב הקרן (פגיעה)
const COL := Color(0.35, 1.0, 0.45)
const CORE := Color(0.9, 1.0, 0.9)

const SOUNDS := {
	"lz_charge": [["S", 180, 1300, 0.0, 1.4, 0.15, 0.0, 0.22, 1.0, 0.02], ["Q", 90, 650, 0.0, 1.4, 0.2, 0.0, 0.07, 0.4, 0.03], ["N", 0, 0, 0.0, 1.4, 0.4, 0.0, 0.08, 0.25, 0, 0.4]],
	"lz_fire": {"drive": 2.4, "layers": [["N", 0, 0, 0.0, 0.35, 0.0, 7.0, 1.3, 0.7, 0], ["S", 95, 35, 0.0, 0.6, 0.0, 5.0, 1.2, 1.0, 0], ["Q", 120, 100, 0.0, 1.6, 0.03, 1.0, 0.22, 0.45, 0.04], ["S", 1900, 1500, 0.0, 1.6, 0.05, 1.0, 0.07, 1.0, 0.06], ["C", 0, 0, 0.0, 1.6, 0.0, 1.0, 0.35, 1.0, 0]]},
	"lz_hit": [["N", 0, 0, 0.0, 0.08, 0.0, 40.0, 0.5, 0.6, 0, 0.3], ["S", 600, 300, 0.0, 0.08, 0.0, 40.0, 0.15, 1.0, 0]],
}


static func muzzle(pl: Node) -> Vector2:
	return pl.global_position + pl._front_shoulder() + pl._aim * 30.0


# נקרא מ-player.gd כל פריים כשהפריט ביד. held = טוענים (C הפעיל טעינה אוטומטית: player._laser_auto)
static func tick(pl: Node, held: bool, delta: float) -> void:
	var beam: Node = pl.get_meta("laser_beam") if pl.has_meta("laser_beam") else null
	if beam != null and is_instance_valid(beam):
		pl.laser_charge = 0.0
		return
	if held and pl._cooldown <= 0.0 and pl.special_uses > 0:
		if pl.laser_charge <= 0.0:
			Sfx.play("lz_charge", pl.global_position, 0.0, 0.0, 1)
			var fx := ChargeFX.new()
			fx.pl = pl
			pl.get_parent().add_child(fx)
		pl.laser_charge += delta
		if pl.laser_charge >= CHARGE_T:
			_fire(pl)
	elif pl.laser_charge > 0.0:   # עזבת לפני הסוף - מתבטל
		pl.laser_charge = 0.0


static func _fire(pl: Node) -> void:
	pl.laser_charge = 0.0
	pl.special_uses -= 1
	var b := Beam.new()
	b.pl = pl
	pl.get_parent().add_child(b)
	pl.set_meta("laser_beam", b)
	pl._muzzle_flash = 0.1
	pl._recoil = 1.0
	Sfx.play("lz_fire", pl.global_position, 4.0, 0.0, 2)
	PlayerMemory.on_explosive()
	Game.make_noise(pl.global_position, 900.0)


# נקרא כשהקרן נגמרת
static func beam_done(pl: Node) -> void:
	if pl == null or not is_instance_valid(pl):
		return
	pl.remove_meta("laser_beam")
	pl._cooldown = 0.35
	if pl.special_uses <= 0 and pl.special == "laser":
		pl._say("LASER CANNON  -  EMPTY", Color(1, 1, 1, 0.75))
		pl.special = ""
		pl.special_uses = 0
	pl.weapon = pl.GUN   # שימוש דרך C: אחרי הקרן חוזרים לנשק
	pl.weapon_changed.emit(pl.weapon)


# ---- הנשק: גוף כהה עם סלילים ירוקים וליבה זוהרת (charge 0..1 = כמה נטען) ----
static func draw_gun(ci: CanvasItem, hand: Vector2, la: Vector2, t: float, charge := 0.0, s := 1.0) -> void:
	var n := la.rotated(PI / 2.0)
	var g := func(x: float, y: float) -> Vector2: return hand + (la * x + n * y) * s
	Art.fill(ci, PackedVector2Array([g.call(-8.0, -3.5), g.call(10.0, -5.0), g.call(22.0, -3.0), g.call(22.0, 3.0), g.call(10.0, 4.5), g.call(-8.0, 4.0)]), Color("2a2e30"), Art.OUTLINE, 1.2 * s)
	Art.fill(ci, PackedVector2Array([g.call(-4.0, 3.5), g.call(2.0, 3.5), g.call(0.0, 9.0), g.call(-5.0, 8.0)]), Color("1e2022"), Art.OUTLINE, 1.0 * s)   # ידית
	for i in 3:   # סלילים
		var x := 6.0 + float(i) * 5.0
		DrawBatch.line(ci, g.call(x, -5.0), g.call(x, 5.0), Color(0.3, 0.9, 0.4, 0.5 + 0.5 * charge), 2.0 * s)
	Art.fill(ci, PackedVector2Array([g.call(22.0, -4.0), g.call(28.0, -3.0), g.call(28.0, 3.0), g.call(22.0, 4.0)]), Color("4a5054"), Art.OUTLINE, 1.0 * s)   # פיה
	var core: Vector2 = g.call(2.0, 0.0)
	var pulse := 0.6 + 0.4 * sin(t * (8.0 + 30.0 * charge))
	Art.glow(ci, core, (5.0 + 10.0 * charge) * s, Color(COL, 0.7 * pulse))
	Art.disc(ci, core, (1.8 + 1.4 * charge) * s, CORE, Art.NONE)
	if charge > 0.0:
		Art.glow(ci, g.call(28.0, 0.0), (4.0 + 18.0 * charge) * s, Color(COL, 0.4 + 0.5 * charge))


# ---- חלקיקי טעינה: נשאבים אל הקנה, מתחזקים עם הטעינה ----
class ChargeFX extends Node2D:
	var pl: Node = null
	var _p := []      # [מיקום יחסי, זמן]
	var _t := 0.0

	func _ready() -> void:
		z_index = 12

	func _process(delta: float) -> void:
		if pl == null or not is_instance_valid(pl) or pl.laser_charge <= 0.0 or pl.special != "laser":
			queue_free()
			return
		_t += delta
		var k: float = clampf(pl.laser_charge / preload("res://weapons/laser_cannon.gd").CHARGE_T, 0.0, 1.0)
		global_position = preload("res://weapons/laser_cannon.gd").muzzle(pl)
		var spawn := int(2.0 + 6.0 * k)
		for i in spawn:   # חלקיקים חדשים מסביב
			var a := randf() * TAU
			var r := randf_range(40.0, 90.0) * (1.0 - 0.4 * k)
			_p.append([Vector2.from_angle(a) * r, 0.0, randf_range(1.0, 2.6)])
		for p in _p:   # נשאבים פנימה בספירלה
			var v: Vector2 = p[0]
			v = v.rotated(delta * 3.0) * (1.0 - delta * (4.0 + 6.0 * k))
			p[0] = v
			p[1] += delta
		_p = _p.filter(func(p): return (p[0] as Vector2).length() > 3.0 and p[1] < 0.6)
		if _p.size() > 90:
			_p = _p.slice(_p.size() - 90)
		queue_redraw()

	func _draw() -> void:
		DrawBatch.begin(self)
		_draw_b()
		DrawBatch.end(self)

	func _draw_b() -> void:
		var C := preload("res://weapons/laser_cannon.gd")
		var k: float = clampf(pl.laser_charge / C.CHARGE_T, 0.0, 1.0) if pl != null and is_instance_valid(pl) else 0.0
		for p in _p:
			var v: Vector2 = p[0]
			DrawBatch.line(self, v, v * 0.82, Color(C.COL, 0.85), float(p[2]))
			DrawBatch.circle(self, v, float(p[2]) * 0.8, Color(C.CORE, 0.9))
		DrawBatch.circle(self, Vector2.ZERO, 6.0 + 22.0 * k, Color(C.COL, 0.12 + 0.2 * k))
		DrawBatch.circle(self, Vector2.ZERO, 3.0 + 9.0 * k, Color(C.COL, 0.35 + 0.3 * k))
		DrawBatch.circle(self, Vector2.ZERO, 2.0 + 4.0 * k, Color(C.CORE, 0.9))
		for i in 3:   # טבעות שמתכווצות
			var rk := fmod(_t * 2.5 + float(i) / 3.0, 1.0)
			DrawBatch.arc(self, Vector2.ZERO, 50.0 * (1.0 - rk) * (1.0 - 0.3 * k), 0.0, TAU, 24, Color(C.COL, 0.5 * rk * (0.4 + k)), 1.5)
		if k > 0.85 and fmod(_t * 20.0, 1.0) < 0.5:   # כמעט מלא - מהבהב
			DrawBatch.circle(self, Vector2.ZERO, 14.0, Color(1, 1, 1, 0.35))


# ---- הקרן ----
class Beam extends Node2D:
	var pl: Node = null
	var kills := 0               # לבדיקות
	var hits := 0
	var _t := 0.0
	var _tick := 0.0
	var _from := Vector2.ZERO
	var _to := Vector2.ZERO
	var _dir := Vector2.RIGHT
	var _sparks := []            # [מיקום, מהירות, חיים, גודל]
	var _rings := []             # [מיקום, גיל]
	var _ring_t := 0.0
	var _hit_set := {}

	func _ready() -> void:
		z_index = 11
		_update_line()
		# פיצוץ האנרגיה בהתחלה
		for i in 40:
			var a := randf() * TAU
			_sparks.append([_from, Vector2.from_angle(a) * randf_range(150.0, 520.0), randf_range(0.3, 0.7), randf_range(1.5, 3.5)])
		_rings.append([_from, 0.0])
		_shake(18.0, 0.5)

	func _shake(st: float, t: float) -> void:
		var cam := get_viewport().get_camera_2d()
		if cam != null and cam.has_method("shake"):
			cam.shake(st, t)

	func _update_line() -> void:
		var C := preload("res://weapons/laser_cannon.gd")
		if pl == null or not is_instance_valid(pl):
			return
		_dir = pl._aim
		_from = C.muzzle(pl)
		var to := _from + _dir * C.RANGE
		var hit := get_world_2d().direct_space_state.intersect_ray(PhysicsRayQueryParameters2D.create(_from, to, 1))   # נעצרת רק בקירות
		_to = hit.position if hit else to

	func _physics_process(delta: float) -> void:
		var C := preload("res://weapons/laser_cannon.gd")
		_t += delta
		if pl == null or not is_instance_valid(pl) or pl.dead or _t >= C.BEAM_T:
			C.beam_done(pl)
			queue_free()
			return
		_update_line()
		# הדף אחורה (קל) כל עוד הקרן יורה
		if pl.is_on_floor():
			pl.velocity.x -= _dir.x * 260.0 * delta
		_tick -= delta
		if _tick <= 0.0:
			_tick = C.TICK
			_damage()
		# ניצוצות לאורך הקרן ובנקודת הפגיעה
		var seg := _to - _from
		for i in 3:
			var p := _from + seg * randf()
			_sparks.append([p, _dir.rotated(PI * 0.5 * (1.0 if randf() < 0.5 else -1.0)) * randf_range(40.0, 160.0) + _dir * 60.0, randf_range(0.2, 0.45), randf_range(1.0, 2.4)])
		for i in 3:
			_sparks.append([_to, (-_dir).rotated(randf_range(-1.2, 1.2)) * randf_range(120.0, 380.0), randf_range(0.2, 0.5), randf_range(1.5, 3.0)])
		_ring_t -= delta
		if _ring_t <= 0.0:
			_ring_t = 0.12
			_rings.append([_from, 0.0])
		for s in _sparks:
			s[0] += s[1] * delta
			s[1] *= 1.0 - delta * 3.0
			s[2] -= delta
		_sparks = _sparks.filter(func(s): return s[2] > 0.0)
		if _sparks.size() > 160:
			_sparks = _sparks.slice(_sparks.size() - 160)
		for r in _rings:
			r[1] += delta
		_rings = _rings.filter(func(r): return r[1] < 0.35)
		if Engine.get_physics_frames() % 6 == 0:
			_shake(5.0, 0.12)
		global_position = Vector2.ZERO
		queue_redraw()

	func _damage() -> void:
		var C := preload("res://weapons/laser_cannon.gd")
		var seg := _to - _from
		for z in get_tree().get_nodes_in_group("zombies"):
			if z.dead:
				continue
			var c: Vector2 = z.global_position + Vector2(0, -28.0 * float(z.sc))
			var cp := Geometry2D.get_closest_point_to_segment(c, _from, _to)
			if cp.distance_to(c) > C.WIDTH + 16.0 * float(z.sc) * float(z.wf):
				continue
			var dmg := C.DMG
			if z.is_boss():
				dmg = int(round(float(dmg) * C.BOSS_K))
			hits += 1
			_hit_set[z.get_instance_id()] = true
			z.take_damage(dmg, c, _dir, false, {"source": "laser", "fixed": dmg, "knockback": 40.0})   # (מרכז הגוף - לא "ירייה בראש")
			if z.dead:
				kills += 1
			if z.has_method("ignite") and randf() < 0.15:
				z.ignite(1.0)
		if Engine.get_physics_frames() % 2 == 0:
			Sfx.play("lz_hit", _to, -6.0, 0.2, 2)
		for b in get_tree().get_nodes_in_group("blastable"):   # לבנים / חביות בדרך
			if b.has_method("hit_by_blast") and b.has_method("blast_rect"):
				var r: Rect2 = b.blast_rect()
				if r.grow(6.0).has_point(_to):
					b.hit_by_blast(_to, 30.0)

	func _draw() -> void:
		DrawBatch.begin(self)
		_draw_b()
		DrawBatch.end(self)

	func _draw_b() -> void:
		var C := preload("res://weapons/laser_cannon.gd")
		var k := 1.0
		if _t < 0.15:   # פיצוץ בהתחלה: עבה פי 2
			k = 2.0 - _t / 0.15
		elif _t > C.BEAM_T - 0.3:   # נגמר: מצטמצם
			k = clampf((C.BEAM_T - _t) / 0.3, 0.0, 1.0)
		var fl := 0.85 + 0.15 * sin(_t * 60.0)
		var w := C.WIDTH * k * fl
		var seg := _to - _from
		var n := seg.normalized().rotated(PI * 0.5)
		# שכבות זוהר
		DrawBatch.line(self, _from, _to, Color(C.COL, 0.12), w * 3.0)
		DrawBatch.line(self, _from, _to, Color(C.COL, 0.3), w * 1.8)
		DrawBatch.line(self, _from, _to, Color(C.COL, 0.85), w)
		DrawBatch.line(self, _from, _to, Color(C.CORE, 0.95), w * 0.4)
		# סלילי אנרגיה סביב הקרן
		var steps := int(seg.length() / 18.0)
		if steps > 1 and k > 0.05:
			for sgn in [1.0, -1.0]:
				var pts := PackedVector2Array()
				for i in steps + 1:
					var u := float(i) / float(steps)
					pts.append(_from + seg * u + n * sin(u * seg.length() * 0.05 - _t * 40.0 * sgn) * w * 0.9 * sgn)
				DrawBatch.polyline(self, pts, Color(C.CORE, 0.55 * k), 1.6)
		# פיה + נקודת פגיעה
		DrawBatch.circle(self, _from, w * 1.1, Color(C.COL, 0.5))
		DrawBatch.circle(self, _from, w * 0.55, Color(C.CORE, 0.95))
		DrawBatch.circle(self, _to, w * 1.6, Color(C.COL, 0.35))
		DrawBatch.circle(self, _to, w * 0.8, Color(C.CORE, 0.85))
		for r in _rings:   # גלי הדף מהפיה
			var rk: float = float(r[1]) / 0.35
			DrawBatch.arc(self, r[0], 10.0 + rk * 70.0 * (2.0 if _t < 0.2 else 1.0), 0.0, TAU, 24, Color(C.COL, 0.6 * (1.0 - rk)), 2.5)
		for s in _sparks:
			var p: Vector2 = s[0]
			var v: Vector2 = s[1]
			DrawBatch.line(self, p, p - v * 0.03, Color(C.COL, clampf(float(s[2]) * 2.5, 0.0, 1.0)), float(s[3]))
		if _t < 0.12:   # הבזק על כל המסך סביב הפיה
			DrawBatch.circle(self, _from, 180.0 * (1.0 - _t / 0.12), Color(0.8, 1.0, 0.8, 0.35 * (1.0 - _t / 0.12)))
