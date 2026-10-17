extends "res://enemies/zombie_type.gd"
# ============================================================
#  BRANDER (שלב 51, "THE RANCH") - המסמן של האחוזה. גאוצ'ו כבד בסינר עור חרוך, שרוולים מופשלים וידיים שרופות,
#  שפם עבות, מטפחת על הראש. מחזיק ביד ברזל סימון ארוך שהקצה שלו (סימן ה-P של "לה פטרונה") לוהט כתום.
#    AIM    - אתה בטווח (REACH): מושך את הברזל לאחור, הקצה מתלהט ושורק (AIM_T) - אזהרה!
#    THRUST - נועץ קדימה (THRUST_T). פגע -> נזק + סימון (Brand) ל-BRAND_T שניות. עוד סימון = עוד זמן (עד BRAND_MAX).
#    RECOVER - מושך את הברזל חזרה.
#  מסומן: סימן לוהט על החזה. כל הזומבים ברדיוס HERD_R יודעים איפה אתה ומתכנסים אליך (מהר יותר) - "THE HERD KNOWS YOU".
#         לעמוד בתוך שוקת מים (s51_decor Trough) = שוטף את הסימון.
#  "THEY LEARN": שטפת סימון -> המסמנים שומרים על השוקות: כשאתה מסומן (או ליד שוקת) הם נעמדים בינך לבין השוקת הקרובה.
#  לשנות: REACH, AIM_T, THRUST_T, BRAND_T, BRAND_MAX, HERD_R, HERD_EVERY, CD, GUARD_R.
# ============================================================

const SOUNDS := {
	"br_sizzle": [["N", 0, 0, 0.0, 0.6, 0.02, 3.0, 0.5, 0.9, 0, 0.5], ["S", 3200, 2600, 0.0, 0.5, 0.0, 4.0, 0.06, 1.0, 0]],
	"br_brand": {"drive": 1.4, "layers": [["N", 0, 0, 0.0, 0.9, 0.0, 2.6, 0.8, 0.85, 0, 0.6], ["S", 140, 90, 0.0, 0.2, 0.0, 12.0, 0.5, 1.0, 0]]},
	"br_splash": [["N", 0, 0, 0.0, 0.4, 0.0, 7.0, 0.7, 0.35, 0]],
}

const REACH := 66.0             # טווח הנעיצה (כפול sc)
const AIM_T := 0.6
const THRUST_T := 0.2
const RECOVER_T := 0.55
const BRAND_T := 8.0
const BRAND_MAX := 24.0
const HERD_R := 900.0
const HERD_EVERY := 0.5
const CD := Vector2(1.4, 2.2)
const GUARD_R := 420.0          # ליד שוקת (כשלמד)
const DMG := 1

enum { WALK, AIM, THRUST, RECOVER }
var state := WALK
# לבדיקות
var thrusts := 0
var brands := 0
var guards := 0
var _st := 0.0
var _cd := 1.0
var _hit := false
var _guard_said := false
var _sizzle := 0.0


func stats() -> Dictionary:
	return {"name": "BRANDER", "hp": 85, "walk": 40.0, "chase": 80.0, "damage": 1, "bite_delay": 1.0, "scale": 1.15, "width": 1.15,
		"duck": 0.1, "cover": 0.15, "skin": Color("8a9070"), "shirt": Color("c8b89a"), "pants": Color("3a3430"), "shoe": Color("2a1e14"),
		"points": 420}


func brain_overrides() -> Dictionary:
	return {"aggression": 0.6}


func can_bite() -> bool:
	return false


func physics(pl: Node, delta: float) -> bool:
	_cd -= delta
	_st -= delta
	if z.dead:
		return false
	_sizzle -= delta
	if _sizzle <= 0.0:   # הקצה הלוהט מעשן
		_sizzle = 0.4
		if Art.on_screen(z, z.global_position):
			Particles.burst(z.get_parent(), _tip() + Vector2(0, -6), "smoke", Vector2.UP, 1)
	var has_pl: bool = pl != null and not pl.dead
	match state:
		WALK:
			if not has_pl or _cd > 0.0 or not z.is_on_floor():
				return false
			var d: Vector2 = pl.global_position - z.global_position
			if absf(d.x) < REACH * z.sc + 10.0 and absf(d.y) < 46.0:
				state = AIM
				_st = AIM_T
				z._dir = signf(d.x) if d.x != 0.0 else z._dir
				Sfx.play("br_sizzle", z.global_position, -2.0, 0.1, 2)
				return _move(delta, 0.0)
			return false
		AIM:
			if has_pl:
				var d2: Vector2 = pl.global_position - z.global_position
				z._dir = signf(d2.x) if absf(d2.x) > 4.0 else z._dir
			if Engine.get_physics_frames() % 6 == 0 and Art.on_screen(z, z.global_position):
				Particles.burst(z.get_parent(), _tip(), "smoke", Vector2.UP, 1)
			if _st <= 0.0:
				state = THRUST
				_st = THRUST_T
				_hit = false
				thrusts += 1
				z.velocity.x = z._dir * 160.0
			return _move(delta, z.velocity.x, 600.0)
		THRUST:
			if has_pl and not _hit:
				var tip := _tip()
				var zone := Rect2(Vector2(minf(tip.x, z.global_position.x), tip.y - 16.0 * z.sc), Vector2(absf(tip.x - z.global_position.x) + 8.0, 32.0 * z.sc))
				if zone.intersects(pl.body_rect()):
					_hit = true
					if pl._roll_t <= 0.0 and not pl.god_mode():
						brands += 1
						pl.hurt(DMG, Vector2(z._dir * 1.0, -0.5))
						apply_brand(pl, BRAND_T)
			if _st <= 0.0:
				state = RECOVER
				_st = RECOVER_T
			return _move(delta, 0.0, 900.0)
		RECOVER:
			if _st <= 0.0:
				state = WALK
				_cd = randf_range(CD.x, CD.y)
			return _move(delta, 0.0)
	return false


# קצה הברזל בעולם
func _tip() -> Vector2:
	var k := 0.0
	match state:
		AIM:
			k = -0.3
		THRUST:
			k = 1.0 - clampf(_st / THRUST_T, 0.0, 1.0)
		RECOVER:
			k = clampf(_st / RECOVER_T, 0.0, 1.0)
	var reach: float = lerpf(36.0, REACH, k)
	return z.global_position + Vector2(z._dir * reach, -36.0) * z.sc


# ---- סימון השחקן (גם נקרא מבחוץ - בדיקות) ----
static func apply_brand(pl: Node, t: float) -> Node:
	var b: Node = pl.get_node_or_null("Brand")
	if b == null:
		b = Brand.new()
		b.name = "Brand"
		pl.add_child(b)
	b.add_time(t)
	Sfx.play("br_brand", pl.global_position, 3.0, 0.1, 2)
	return b


# שוקות שכבר שטפו בהן סימון בשלב הזה (= המסמנים למדו)
func _learned() -> bool:
	var m: Node = z.get_parent()
	return m != null and int(m.get_meta("brand_washes", 0)) > 0


func _nearest_trough(p: Vector2) -> Node:
	var best: Node = null
	var bd := INF
	for t in z.get_tree().get_nodes_in_group("troughs"):
		var dd: float = absf(t.global_position.x - p.x)
		if dd < bd and absf(t.global_position.y - p.y) < 120.0:
			bd = dd
			best = t
	return best


# למד: נעמד בינך לבין השוקת הקרובה
func logic(pl: Node, d: Vector2, _delta: float, speed: float) -> float:
	if pl == null or not _learned():
		return speed
	var branded: bool = pl.get_node_or_null("Brand") != null
	var t := _nearest_trough(pl.global_position)
	if t == null:
		return speed
	var tx: float = t.global_position.x
	if not branded and absf(tx - pl.global_position.x) > GUARD_R:
		return speed
	if absf(d.x) < REACH * z.sc + 20.0 and absf(d.y) < 46.0:   # כבר בטווח: נלחם
		return speed
	var side := signf(pl.global_position.x - tx)
	if side == 0.0:
		side = 1.0
	var gx: float = tx + side * 70.0
	if absf(pl.global_position.x - tx) < 70.0:   # אתה כבר בשוקת
		return speed
	var gd: float = gx - z.global_position.x
	if not _guard_said:
		_guard_said = true
		guards += 1
		z._popup("THEY GUARD THE WATER", Color("ffd080"), 12, -90.0 * z.sc)
	if absf(gd) < 10.0:
		z._dir = signf(d.x) if d.x != 0.0 else z._dir
		return 0.0
	z._dir = signf(gd)
	return speed * 1.15


func _move(delta: float, vx: float, acc := 1200.0) -> bool:
	z.velocity.x = move_toward(z.velocity.x, vx, acc * delta)
	if not z.is_on_floor():
		z.velocity.y += z.gravity * delta
	z.move_and_slide()
	return true


# ============================================================
#  הסימון: סימן לוהט על השחקן. כל הזומבים ברדיוס יודעים איפה הוא. שוקת מים שוטפת.
# ============================================================
class Brand extends Node2D:
	const Sfx2 := preload("res://sfx.gd")
	var t := 0.0
	var pulls := 0              # לבדיקות: כמה פעמים משך זומבים
	var pulled := 0
	var _herd := 0.0
	var _chk := 0.0
	var _tt := 0.0

	func _ready() -> void:
		z_index = 12
		position = Vector2(0, -36)

	func add_time(s: float) -> void:
		var was := t > 0.0
		t = minf(t + s, BRAND_MAX)
		_herd = 0.0
		var pl := get_parent()
		if pl != null and pl.has_method("_say"):
			pl._say("BRANDED!  THE HERD KNOWS YOU" if not was else "BRANDED AGAIN  +%ds" % int(s), Color("ff8040"))

	func _physics_process(delta: float) -> void:
		_tt += delta
		t -= delta
		var pl := get_parent()
		if t <= 0.0 or pl == null or pl.dead:
			queue_free()
			return
		# שוקת מים = נשטף
		_chk -= delta
		if _chk <= 0.0:
			_chk = 0.1
			for tr in get_tree().get_nodes_in_group("troughs"):
				if tr.covers(pl.global_position):
					tr.splash()
					Sfx2.play("br_splash", pl.global_position, 2.0)
					Sfx2.play("br_sizzle", pl.global_position, 0.0, 0.1, 2, 0.8)
					pl._say("WASHED OFF", Color("80d0ff"))
					var m: Node = pl.get_parent()
					if m != null:
						m.set_meta("brand_washes", int(m.get_meta("brand_washes", 0)) + 1)
					t = 0.0
					queue_free()
					return
		# העדר יודע: כל הזומבים ברדיוס מתכנסים
		_herd -= delta
		if _herd <= 0.0:
			_herd = HERD_EVERY
			pulls += 1
			var p: Vector2 = pl.global_position
			for zz in get_tree().get_nodes_in_group("zombies"):
				if zz.dead or zz.global_position.distance_to(p) > HERD_R:
					continue
				pulled += 1
				zz._alert_t = maxf(float(zz._alert_t), HERD_EVERY + 0.6)
				zz._rush_t = maxf(float(zz._rush_t), HERD_EVERY + 0.2)
				if zz.brain != null:
					zz.brain.seen_t = 0.0
					zz.brain.last_seen = p
		if Engine.get_physics_frames() % 9 == 0 and Art.on_screen(self, global_position):
			Particles.burst(get_parent().get_parent(), global_position + Vector2(0, -4), "smoke", Vector2.UP, 1)
		queue_redraw()

	func _draw() -> void:
		var k := 0.6 + 0.4 * sin(_tt * 8.0)
		var fade := clampf(t / 2.0, 0.2, 1.0)
		Art.glow(self, Vector2.ZERO, 16.0 + 6.0 * k, Color(1.0, 0.4, 0.1, 0.35 * fade))
		var c := Color(1.0, 0.55 + 0.3 * k, 0.15, fade)
		draw_line(Vector2(-2.5, 5), Vector2(-2.5, -5), c, 2.0)
		draw_arc(Vector2(-2.5, -2), 3.0, -PI * 0.5, PI * 0.5, 8, c, 2.0)
		draw_line(Vector2(-6, 7), Vector2(6, 7), c, 2.0)
		draw_line(Vector2(-6, -7), Vector2(-9, -11), c, 1.4)   # קרניים
		draw_line(Vector2(5, -7), Vector2(8, -11), c, 1.4)
		# טבעת "העדר" שמתפשטת מהשחקן
		var r := fmod(_tt * 1.2, 1.0)
		draw_arc(Vector2(0, 20), 30.0 + r * 140.0, PI * 1.05, PI * 1.95, 24, Color(1.0, 0.45, 0.15, 0.35 * (1.0 - r) * fade), 2.0)
		# כמה זמן נשאר (פס קטן)
		draw_rect(Rect2(-14, -22, 28, 3), Color(0, 0, 0, 0.4))
		draw_rect(Rect2(-14, -22, 28.0 * clampf(t / BRAND_MAX, 0.0, 1.0), 3), Color(1.0, 0.5, 0.15, 0.9))


# ============================================================
#  ציור: כתפיים רחבות, סינר עור חרוך, שרוולים מופשלים, מטפחת על הראש ושפם. שתי ידיים על ברזל הסימון.
#  AIM = הברזל נמשך לאחור והקצה בוהק. THRUST = נעיצה קדימה. הקצה תמיד לוהט ומעשן.
# ============================================================
func draw() -> bool:
	begin_draw()
	var sk := col(z.skin)
	var skd := col(Art.shade(z.skin, 0.25))
	var p: float = z._walk_phase
	var f: Array = feet(5.0, 2.5)
	var lean := 0.0
	match state:
		AIM:
			lean = -3.0
		THRUST:
			lean = 6.0
			f = [Vector2(9, 0), Vector2(-7, 0)]
	var hip := Vector2(0, -23)
	var sh := Vector2(4.0 + lean, -41)
	z._leg(hip + Vector2(-3, 0), f[1], col(Art.shade(z.pants, 0.25)), skd, col(z.shoe))
	z._leg(hip + Vector2(3, 0), f[0], col(z.pants), sk, col(z.shoe))
	# הברזל (בעולם: מקומי - לפני ההיפוך כבר מטופל ע"י begin_draw)
	var tip_l: Vector2 = (_tip() - z.global_position) / z.sc
	tip_l.x *= z._dir / z.wf
	var grip_b: Vector2 = sh + Vector2(4, 12)
	var grip_f: Vector2 = grip_b.lerp(tip_l, 0.28)
	z._arm(sh + Vector2(-2, 2), grip_b, skd, col(Color("8a8070")))
	# גוף רחב עם סינר עור
	var body := PackedVector2Array([sh + Vector2(-10, -1), sh + Vector2(10, 0), hip + Vector2(9, -2), hip + Vector2(7, 3), hip + Vector2(-7, 3), hip + Vector2(-10, -2)])
	Art.fill_shaded(z, body, col(z.shirt), 0.15, 0.35)
	var apron := PackedVector2Array([sh + Vector2(-5, 4), sh + Vector2(9, 4), hip + Vector2(10, 8), hip + Vector2(8, 13), hip + Vector2(-2, 12), hip + Vector2(-6, 8)])
	Art.fill_shaded(z, apron, col(Color("5a3a22")), 0.12, 0.35)
	z.draw_line(sh + Vector2(-5, 4), sh + Vector2(-3, -2), col(Color("3a2414")), 1.4)   # רצועה
	for q in 3:   # כוויות וכתמים על הסינר
		z.draw_circle(hip + Vector2(-1.0 + float(q) * 3.5, -6.0 + float(q % 2) * 6.0), 1.4, Color(0.15, 0.08, 0.04, 0.6))
	if not z.dead:
		_brand_p(sh + Vector2(2, 10), 2.4, Color(0.25, 0.12, 0.06, 0.8))
	# ראש: מטפחת, שפם
	var head: Vector2 = sh + Vector2(3.0, -9.0)
	z._head(head, sk)
	Art.fill(z, PackedVector2Array([head + Vector2(-8, -3), head + Vector2(7, -6), head + Vector2(5, -10), head + Vector2(-5, -10), head + Vector2(-9, -6)]), col(Color("6a1a14")), Art.OUTLINE, 1.0)
	z.draw_line(head + Vector2(-8, -4), head + Vector2(-13, 0), col(Color("6a1a14")), 2.0)   # קשר
	z.draw_polyline(PackedVector2Array([head + Vector2(2, 3), head + Vector2(5, 2.5), head + Vector2(8, 4.5)]), col(Color("2a2420")), 1.8)   # שפם
	if not z.dead:
		z.draw_circle(head + Vector2(4.0, -1.5), 1.1, Color(1.0, 0.5, 0.15))
	# הברזל: מוט ארוך, ידית עץ, קצה לוהט בצורת P
	var tail: Vector2 = grip_b - (tip_l - grip_b).normalized() * 10.0
	z.draw_line(tail, grip_b.lerp(tip_l, 0.4), col(Color("4a3020")), 3.4)   # ידית
	z.draw_line(grip_b.lerp(tip_l, 0.4), tip_l, col(Color("3a3634")), 2.2)
	var heat := 1.0 if state == AIM or state == THRUST else 0.65
	var hot := Color(1.0, 0.45 + 0.35 * heat * (0.5 + 0.5 * sin(z._time * 12.0)), 0.1)
	z.draw_line(tip_l.lerp(grip_b, 0.18), tip_l, Color(1.0, 0.35, 0.1, 0.9 * heat), 2.4)   # מתלהט לאורך המוט
	Art.glow(z, tip_l, 9.0 + 5.0 * heat, Color(1.0, 0.4, 0.1, 0.35 * heat))
	_brand_p(tip_l + Vector2(3, 0), 4.0, hot)
	z._arm(sh + Vector2(2, 2), grip_f, sk, col(Color("8a8070")))
	end_draw()
	return true


func _brand_p(c: Vector2, r: float, cl: Color) -> void:
	z.draw_line(c + Vector2(-r * 0.35, r * 0.7), c + Vector2(-r * 0.35, -r * 0.7), cl, 1.6)
	z.draw_arc(c + Vector2(-r * 0.35, -r * 0.3), r * 0.4, -PI * 0.5, PI * 0.5, 6, cl, 1.6)
	z.draw_line(c + Vector2(-r * 0.7, r * 0.9), c + Vector2(r * 0.6, r * 0.9), cl, 1.4)
