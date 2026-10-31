extends "res://enemies/zombie_type.gd"
# ============================================================
#  CLOCKWORK (שלב 48, "OLD QUARTER" - בואנוס איירס) - בובת-מכונה מחנות צעצועים ישנה בסן טלמו, ועם מת בפנים.
#  מסכת חרסינה סדוקה, מעיל אדום עם כפתורי פליז, חזה פתוח עם גלגלי שיניים, ומפתח קפיץ ענק בגב.
#    RUN      - הקפיץ מתוח (wind): רץ בזינוקים (BURST_T זינוק מהיר x BURST_MULT, ואז עצירת "תיק" קצרה). הקפיץ נפרם עם התנועה.
#    STOPPED  - הקפיץ נגמר: קופא במקום, הראש צונח - פגיע (x STOP_MULT). אחרי רגע מתחיל להתמתח מחדש (REWIND_T).
#               CLOCKWORK אחר עם קפיץ מלא בטווח HELP_R בא ו"מותח" אותו - פי 2 מהר יותר ("WIND ME!").
#    HAYWIRE  - ירייה במפתח מאחור (KEY_HP פגיעות בגובה המפתח, מהגב) -> המפתח נשבר: הקפיץ משתחרר בבת אחת -
#               רץ בטירוף לכל כיוון, נזק כפול, אבל נקרע מבפנים (HAYWIRE_DPS) ומת תוך כמה שניות.
#  "THEY LEARNED TO WIND UP OUT OF SIGHT - TOGETHER": כל פגיעה בבובה עומדת נספרת (main meta "cw_stop_hits").
#    אחרי STOP_LEARN פגיעות - כשהקפיץ כמעט נגמר הם בורחים ממך (RETREAT) ונעצרים רחוק / מאחורי זומבים אחרים.
#  צלילים: "cw_tick" (תקתוק), "cw_wind" (מתיחת קפיץ), "cw_snap" (המפתח נשבר), "cw_boing".
#  לשנות: WIND_DRAIN, BURST_T, BURST_MULT, REWIND_T, STOP_MULT, KEY_HP, HAYWIRE_DPS, HELP_R, STOP_LEARN.
# ============================================================

const SOUNDS := {
	"cw_tick": [["C", 0, 0, 0.0, 0.03, 0.0, 120.0, 0.35, 1.0, 0], ["S", 3200, 3100, 0.0, 0.03, 0.0, 120.0, 0.12, 1.0, 0]],
	"cw_wind": [["C", 0, 0, 0.0, 0.5, 0.0, 6.0, 0.25, 1.0, 0], ["S", 1800, 2400, 0.0, 0.5, 0.02, 4.0, 0.08, 1.0, 0.02]],
	"cw_snap": [["S", 2600, 600, 0.0, 0.25, 0.0, 12.0, 0.4, 1.0, 0], ["C", 0, 0, 0.0, 0.15, 0.0, 30.0, 0.5, 1.0, 0], ["N", 0, 0, 0.0, 0.1, 0.0, 40.0, 0.3, 1.0, 0]],
	"cw_boing": [["S", 180, 520, 0.0, 0.35, 0.0, 6.0, 0.3, 1.0, 0.08]],
}

const WIND_DRAIN := 0.11       # כמה מהקפיץ נגמר בשנייה (בזמן ריצה)
const BURST_T := 0.55
const BURST_GAP := 0.35
const BURST_MULT := 2.3
const REWIND_T := 2.6
const STOP_MULT := 1.6
const KEY_HP := 2
const HAYWIRE_DPS := 5.0
const HAYWIRE_SPEED := 300.0
const HELP_R := 260.0
const STOP_LEARN := 4
const RETREAT_AT := 0.22

enum { RUN, RETREAT, STOPPED, HAYWIRE }
var state := RUN
var wind := 1.0
var key_hp := KEY_HP
var stops := 0                 # לבדיקות
var bursts := 0
var keys_broken := 0
var retreats := 0
var helped := 0
var _st := 0.0
var _burst := 0.0
var _key_a := 0.0
var _gear_a := 0.0
var _tick := 0.0
var _help_cd := 0.0
var _hw_dir := 1.0
var _hw_acc := 0.0
var _helper: Node = null


func stats() -> Dictionary:
	return {"name": "CLOCKWORK", "hp": 40, "walk": 46.0, "chase": 92.0, "damage": 1, "bite_delay": 0.7, "scale": 1.06, "width": 0.95,
		"duck": 0.0, "cover": 0.0, "skin": Color("d8d0c4"), "shirt": Color("a8242a"), "pants": Color("2a2e48"), "shoe": Color("1a1418"), "points": 410}


func brain_overrides() -> Dictionary:
	return {"aggression": 0.4}


func setup() -> void:
	wind = randf_range(0.7, 1.0)
	_burst = randf_range(0.0, BURST_T + BURST_GAP)


func can_bite() -> bool:
	return state == RUN or state == HAYWIRE


func damage_mult(_zone: String, _src: Dictionary) -> float:
	return STOP_MULT if state == STOPPED else 1.0


func _learned() -> bool:
	var m: Node = z.get_parent()
	return m != null and m.has_meta("cw_stop_hits") and int(m.get_meta("cw_stop_hits")) >= STOP_LEARN


func on_damage(_amount: int, hit_pos: Vector2, dir: Vector2, src: Dictionary) -> bool:
	if z.dead:
		return true
	var source := str(src.get("source", "bullet"))
	if state == STOPPED:
		var m: Node = z.get_parent()
		if m != null:
			var n := (int(m.get_meta("cw_stop_hits")) if m.has_meta("cw_stop_hits") else 0) + 1
			m.set_meta("cw_stop_hits", n)
			if n == STOP_LEARN:
				z._popup("THEY WIND UP OUT OF SIGHT", Color("ffe0a0"), 12, -80.0)
	if state != HAYWIRE and key_hp > 0 and (source == "bullet" or source == "melee") and dir.x * z._dir > 0.0:   # מאחור
		var ly: float = (hit_pos.y - z.global_position.y) / z.sc
		if ly > -44.0 and ly < -26.0:
			key_hp -= 1
			Sfx.play("metal_ping", hit_pos, -2.0, 0.15, 3)
			Particles.burst(z.get_parent(), hit_pos, "fire", Vector2(dir.x, -0.6), 4)
			if key_hp <= 0:
				_haywire()
	return true


func _haywire() -> void:
	keys_broken += 1
	state = HAYWIRE
	z.damage = 2
	_hw_dir = z._dir
	_st = 0.0
	Sfx.play("cw_snap", z.global_position, 2.0, 0.1, 2)
	Sfx.play("cw_boing", z.global_position, 0.0, 0.15, 2)
	z._popup("HAYWIRE!", Color("ffb040"), 17, -80.0)
	Particles.burst(z.get_parent(), z.global_position + Vector2(-z._dir * 10.0, -34.0) * z.sc, "spark", Vector2(-z._dir, -1.0), 12)


func logic(_pl: Node, _d: Vector2, _delta: float, speed: float) -> float:
	if state != RUN:
		return speed
	if _help_target != null:   # הולך למתוח חבר שנעצר
		if not is_instance_valid(_help_target) or _help_target.dead or _help_target.type_mod.state != STOPPED:
			_help_target = null
		else:
			var dx: float = _help_target.global_position.x - z.global_position.x
			if absf(dx) > 30.0:
				z._dir = signf(dx)
				return speed * 1.1
			return 0.0
	var k := clampf(wind / 0.3, 0.25, 1.0)   # הקפיץ נגמר: לאט יותר
	return speed * (BURST_MULT if _burst < BURST_T else 0.15) * k


func physics(pl: Node, delta: float) -> bool:
	_st -= delta
	_help_cd -= delta
	if z.dead:
		return false
	match state:
		RUN, RETREAT:
			_burst += delta
			if _burst > BURST_T + BURST_GAP:
				_burst = 0.0
				bursts += 1
			var moving := absf(z.velocity.x) > 15.0
			wind -= delta * WIND_DRAIN * (1.6 if moving and _burst < BURST_T else 0.4)
			_key_a += delta * (6.0 * wind + 1.0)
			_gear_a += delta * (8.0 * wind + 0.5)
			_tick -= delta
			if _tick <= 0.0:
				_tick = 0.25 + (1.0 - wind) * 0.35
				if Art.on_screen(z, z.global_position):
					Sfx.play("cw_tick", z.global_position, -14.0, 0.1, 3)
			if wind <= 0.0:
				_stop()
				return _stay(delta)
			if state == RUN and wind < RETREAT_AT and _learned() and pl != null and not pl.dead:
				state = RETREAT
				retreats += 1
				z._popup("...", Color("ffe0a0"), 14, -70.0)
			if state == RETREAT:
				if pl == null or pl.dead:
					return false
				var away := signf(z.global_position.x - pl.global_position.x)
				z._dir = away if away != 0.0 else 1.0
				return _move(delta, z._dir * float(z.chase_speed) * 1.4)
			return false
		STOPPED:
			if _helper == null and _help_cd <= 0.0:   # (טיימר - לא כל פריים) חבר בא למתוח
				_help_cd = 0.5
				_helper = _find_helper()
				if _helper != null:
					z._popup("WIND ME!", Color("ffe0a0"), 12, -70.0)
			var rate := 1.0
			if _helper != null and is_instance_valid(_helper) and not _helper.dead and _helper.type_mod.state == RUN:
				var hd: float = _helper.global_position.x - z.global_position.x
				if absf(hd) < 36.0:
					rate = 2.0
					if _helper.type_mod.has_method("hold"):
						_helper.type_mod.hold(0.2)
			else:
				_helper = null
			if _st < REWIND_T:   # מתמתח
				_key_a += delta * 4.0 * rate
				wind += delta / REWIND_T * rate
				if Engine.get_physics_frames() % 30 == 0 and Art.on_screen(z, z.global_position):
					Sfx.play("cw_wind", z.global_position, -8.0, 0.1, 2)
			if wind >= 1.0:
				wind = 1.0
				state = RUN
				if _helper != null:
					helped += 1
				_helper = null
				Sfx.play("cw_boing", z.global_position, -4.0, 0.15, 2)
			return _stay(delta)
		HAYWIRE:
			_key_a += delta * 30.0
			_gear_a += delta * 40.0
			_hw_acc += HAYWIRE_DPS * delta
			if _hw_acc >= 1.0:
				var d := int(_hw_acc)
				_hw_acc -= float(d)
				z.take_damage(d, z.global_position + Vector2(0, -30.0 * z.sc), Vector2.ZERO, false, {"source": "fire", "fixed": d})
				if z.dead:
					return true
			if _st <= 0.0:   # מחליף כיוון בטירוף (בדרך כלל אליך)
				_st = randf_range(0.3, 0.7)
				_hw_dir = signf(pl.global_position.x - z.global_position.x) if pl != null and randf() < 0.7 else -_hw_dir
				if _hw_dir == 0.0:
					_hw_dir = 1.0
				if z.is_on_floor() and randf() < 0.35:
					z.velocity.y = -360.0
				if Art.on_screen(z, z.global_position) and randf() < 0.5:
					Particles.burst(z.get_parent(), z.global_position + Vector2(0, -30.0 * z.sc), "spark", Vector2.UP, 4)
			z._dir = _hw_dir
			return _move(delta, _hw_dir * HAYWIRE_SPEED)
	return false


func hold(t: float) -> void:   # עוזר למתוח חבר: עומד
	if state == RUN:
		_burst = BURST_T   # (בעצירת התיק)
		z.velocity.x = 0.0
		wind = minf(wind + t * 0.02, 1.0)


func _stop() -> void:
	wind = 0.0
	state = STOPPED
	stops += 1
	_st = REWIND_T + 1.1   # רגע קפוא לפני שמתחיל להתמתח
	Sfx.play("cw_boing", z.global_position, -6.0, 0.1, 2, 0.6)


func _find_helper() -> Node:
	for o in z.get_tree().get_nodes_in_group("zombies"):
		if o == z or o.dead or o.type_mod == null or not o.type_mod.has_method("hold") or o.type_mod.state != RUN or float(o.type_mod.wind) < 0.5:
			continue
		if absf(o.global_position.x - z.global_position.x) < HELP_R and absf(o.global_position.y - z.global_position.y) < 40.0:
			o.type_mod.come_help(z)
			return o
	return null


var _help_target: Node = null


func come_help(other: Node) -> void:
	_help_target = other


func _stay(delta: float) -> bool:
	z.velocity.x = move_toward(z.velocity.x, 0.0, 900.0 * delta)
	if not z.is_on_floor():
		z.velocity.y += z.gravity * delta
	z.move_and_slide()
	return true


func _move(delta: float, vx: float) -> bool:
	z.velocity.x = move_toward(z.velocity.x, vx, 1400.0 * delta)
	if not z.is_on_floor():
		z.velocity.y += z.gravity * delta
	elif z.is_on_wall() and vx != 0.0:
		z.velocity.y = -380.0
	z.move_and_slide()
	return true


# ============================================================
#  ציור: גוף צר וזקוף, מעיל אדום עם כפתורי פליז ושוליים מוזהבים, מכנס כחול עם פס, חזה פתוח עם גלגלי שיניים מסתובבים,
#  מסכת חרסינה סדוקה (עין זומבי אמיתית מציצה מהסדק), מפתח פליז ענק בגב שמסתובב לפי הקפיץ.
#  STOPPED = הראש צונח והידיים תלויות. HAYWIRE = רועד, המפתח שבור, קפיץ קפוץ החוצה.
# ============================================================
func draw() -> bool:
	begin_draw()
	var sk := col(z.skin)
	var coat := col(z.shirt)
	var brass := col(Color("c8a040"))
	var f: Array = feet(5.5 if state != STOPPED else 0.0, 3.0)
	if state == STOPPED:
		f = [Vector2(4, 0), Vector2(-3, 0)]
	var jit := Vector2(randf_range(-1.0, 1.0), randf_range(-0.8, 0.8)) if state == HAYWIRE and not z.dead else Vector2.ZERO
	var droop := 0.0
	if state == STOPPED:
		droop = clampf(1.0 - wind * 2.0, 0.0, 1.0)
	var hip := Vector2(0, -22)
	var sh := Vector2(1.0 + droop * 2.0, -39.0 + droop * 2.0) + jit
	var head := sh + Vector2(2.5 + droop * 3.0, -9.0 + droop * 4.0)
	# מפתח בגב (מאחורי הגוף): הרוחב משתנה = מסתובב
	var kc := sh + Vector2(-9, 8)
	DrawBatch.line(z, kc, kc + Vector2(-6, 0), brass, 2.4)
	if key_hp > 0 or state != HAYWIRE:
		var kw := cos(_key_a) * 6.5
		Art.fill(z, PackedVector2Array([kc + Vector2(-6, -1), kc + Vector2(-6 - absf(kw) * 0.3, -8), kc + Vector2(-10, -9), kc + Vector2(-10, 9), kc + Vector2(-6 - absf(kw) * 0.3, 8), kc + Vector2(-6, 1)]), brass, Art.OUTLINE, 1.0)
		DrawBatch.circle(z, kc + Vector2(-9, -5.5), 1.6, col(Color("5a4010")))
		DrawBatch.circle(z, kc + Vector2(-9, 5.5), 1.6, col(Color("5a4010")))
		if key_hp < KEY_HP:
			DrawBatch.line(z, kc + Vector2(-7, -4), kc + Vector2(-9, 2), col(Color(0.2, 0.1, 0.05)), 1.0)   # סדק
	else:   # קפיץ שבור קופץ החוצה
		var pts := PackedVector2Array()
		for q in 10:
			pts.append(kc + Vector2(-6.0 - float(q) * 1.4, sin(float(q) * 1.8 + _key_a) * 3.5))
		DrawBatch.polyline(z, pts, brass, 1.2)
	z._leg(hip + Vector2(-2, 0), f[1], col(Art.shade(z.pants, 0.25)), col(z.pants), col(z.shoe))
	z._leg(hip + Vector2(2, 0), f[0], col(z.pants), col(z.pants), col(z.shoe))
	DrawBatch.line(z, hip + Vector2(2.5, 1), f[0] + Vector2(1, -4), col(Color("d8b040")), 1.0)   # פס על המכנס
	var hb := sh + (Vector2(-3, 15) if state == STOPPED else Vector2(-6.0 - sin(z._walk_phase) * 3.0, 12.0))
	z._arm(sh + Vector2(-3, 1), hb, Art.shade(sk, 0.2), coat)
	# מעיל אדום
	var torso := PackedVector2Array([sh + Vector2(-7, -1), sh + Vector2(7, 0), hip + Vector2(6, 3), hip + Vector2(-7, 3)])
	Art.fill_shaded(z, torso, coat, 0.15, 0.35)
	# חזה פתוח: גלגלי שיניים
	var gc := sh + Vector2(1, 8)
	DrawBatch.colored_polygon(z, Art.ellipse(gc, 4.5, 5.5, 0.0, 12), col(Color("2a1a14")))
	_gear(gc + Vector2(-1, -1.5), 3.0, _gear_a, brass)
	_gear(gc + Vector2(2, 2.5), 2.2, -_gear_a * 1.4, col(Color("a87a30")))
	for q in 3:   # כפתורים
		DrawBatch.circle(z, sh + Vector2(6, 3 + q * 5), 1.0, brass)
	DrawBatch.line(z, sh + Vector2(-7, -1), sh + Vector2(7, 0), brass, 1.4)   # כתפיות מוזהבות
	DrawBatch.line(z, hip + Vector2(-7, 3), hip + Vector2(6, 3), brass, 1.2)
	# ראש: מסכת חרסינה סדוקה
	Art.oval_shaded(z, head, 5.0, 6.0, col(Color("ece6dc")), 0.0)
	DrawBatch.circle(z, head + Vector2(3.2, 3.5), 1.4, col(Color("d8606a", 0.5)))   # לחי צבועה
	DrawBatch.line(z, head + Vector2(1.5, -5.0), head + Vector2(3.5, -1.0), col(Color("3a2a24")), 0.8)   # סדק
	DrawBatch.line(z, head + Vector2(3.5, -1.0), head + Vector2(2.0, 2.5), col(Color("3a2a24")), 0.8)
	Art.fill(z, PackedVector2Array([head + Vector2(2.2, -2.5), head + Vector2(5.0, -2.0), head + Vector2(4.4, 0.0), head + Vector2(2.6, 0.2)]), col(Color("5a7a5a")), Art.NONE)   # בשר מתחת לחרסינה
	var eye := Color(1.0, 0.85, 0.3) if state == HAYWIRE else Color(0.95, 0.9, 0.7)
	if not z.dead and state != STOPPED:
		DrawBatch.circle(z, head + Vector2(3.6, -1.2), 0.9, eye)
	DrawBatch.line(z, head + Vector2(2.5, 3.8), head + Vector2(5.0, 3.6), col(Color("6a1a1a")), 0.9)
	# כובע מתופף קטן
	Art.fill(z, PackedVector2Array([head + Vector2(-4, -4.5), head + Vector2(4.5, -5), head + Vector2(4, -10), head + Vector2(-3.5, -9.5)]), coat, Art.OUTLINE, 0.9)
	DrawBatch.line(z, head + Vector2(-4, -5), head + Vector2(4.5, -5.5), brass, 1.2)
	DrawBatch.circle(z, head + Vector2(0.5, -10.5), 1.3, brass)
	var hf := sh + (Vector2(4, 15) if state == STOPPED else (Vector2(13, 2) if state == HAYWIRE else Vector2(10.0 + sin(z._walk_phase) * 2.0, 8.0)))
	z._arm(sh + Vector2(3, 1), hf, sk, coat)
	end_draw()
	return true


func _gear(c: Vector2, r: float, a: float, c1: Color) -> void:
	var pts := PackedVector2Array()
	for q in 16:
		var ang := a + float(q) / 16.0 * TAU
		pts.append(c + Vector2.from_angle(ang) * (r if q % 2 == 0 else r * 0.7))
	DrawBatch.colored_polygon(z, pts, c1)
	DrawBatch.circle(z, c, r * 0.3, col(Color("3a2a14")))
