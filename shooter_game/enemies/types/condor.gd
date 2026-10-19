extends "res://enemies/zombie_type.gd"
# ============================================================
#  CONDOR (שלב 61, "END OF THE WORLD") - המעופף של השלב. קונדור אנדים מת, ענק (מוטת כנפיים של אדם וחצי): גוף שחור, צווארון
#    נוצות לבן, ראש קירח אפור-ורדרד עם כרבולת, מקור מכופף, ולמטה - "אצבעות" הנוצות הראשוניות הפרושות שלו. הנוצות נשרו
#    במקומות וחושפות צלעות וקרום. עין ירוקה של ECHO. ובטפרים הוא מחזיק זומבי (RIDER) שמשתלשל ובועט.
#  מה הוא למד, וממה: הגיבור עוצר אותם בקו - הם הולכים אליו מלפנים ומתים בשורה. אז הכוורת למדה לעבור מעל הקו:
#    "THEY CARRY EACH OTHER NOW". הקונדור לא תוקף בעצמו. הוא מוביל: לוקח זומבי מלפנים ומפיל אותו עליך (או מאחוריך).
#  איך הוא עף (לא כמו אף מעופף קודם): הוא כמעט לא מנפנף. הוא דואה על זרמים עולים (THERMAL) של העיר - עמודי אוויר חם
#    מהארובות (stage_61 updrafts()) - מטפס בהם במעגלים (CLIMB_V) עד THERMAL_TOP, ואז גולש אליך (GLIDE_V) ושוקע לאט (SINK_V).
#    נמוך מדי (MIN_H) -> חוזר לזרם הקרוב. הקו שלו צפוי (הוא לא יכול לסטות) - וככה יורים בו.
#  מחזור: THERMAL -> GLIDE -> RUN (מעליך, הרוכב צורח) -> DROP (משחרר את הרוכב עליך - נחת עליך = נזק) -> LEAVE (כמה משקי
#    כנפיים כבדים, ריק) -> PICK: צולל ותופס זומבי מהקרקע מלפנים (PICK_R) כדי להעביר גם אותו. אין אף אחד? מביא מבחוץ (RIDERS).
#  נגד: לירות ברוכב (RiderBody, RIDER_HP) - הוא מת ונופל (גופה). לירות בכנף (WingBody, WING_HP) - הקונדור מסתחרר
#    ומתרסק (CRASH_DMG) והרוכב נופל חי. פיצוץ קורע את שתי הכנפיים. כנפיים רחבות = מטרה גדולה, אבל עבות.
#  לומד (main meta "cd_shot" >= LEARN - כמה רוכבים הפלת באוויר): "THEY DROP THEM BEHIND YOU NOW" - עף גבוה יותר (HIGH_LEARN),
#    מגיע מאחוריך וצולל נמוך (SWOOP) ברגע האחרון כדי להפיל את הרוכב מאחורי הגב שלך. נגד: להסתובב, לשמור את הגב לקיר.
#  לשנות: GLIDE_V, SINK_V, CLIMB_V, THERMAL_TOP, THERMAL_R, MIN_H, RUN_R, DROP_DMG, RIDERS, RIDER_HP, WING_HP, CRASH_DMG, PICK_R,
#    LEARN, HIGH_LEARN, SWOOP_H, BEHIND, FAR_GONE.
# ============================================================

const SOUNDS := {
	"cd_whoosh": {"rev": 0.3, "layers": [["N", 0, 0, 0.0, 1.4, 0.4, 1.2, 0.55, 0.12, 0, 0.3], ["N", 0, 0, 0.2, 1.0, 0.3, 1.6, 0.3, 0.35, 0, 0.6]]},
	"cd_flap": {"drive": 1.6, "layers": [["N", 0, 0, 0.0, 0.32, 0.02, 6.0, 0.75, 0.14, 0.4, 0.05], ["B", 7.0, 4.0, 0.0, 0.3, 0.0, 6.0, 0.4, 1.0, 0, 0, 20.0]]},
	"cd_hiss": {"drive": 2.4, "layers": [["N", 0, 0, 0.0, 0.6, 0.02, 3.0, 0.55, 0.7, 0, 0.5], ["V", 180, 140, 0.0, 0.55, 0.02, 3.5, 0.3, 1.0, 0.1, 0, [700, 1500, 40]]]},
	"cd_rider": {"drive": 2.6, "layers": [["V", 260, 380, 0.0, 0.7, 0.02, 2.2, 0.8, 1.0, 0.07, 0, [900, 1500, 50]], ["N", 0, 0, 0.0, 0.6, 0.02, 3.0, 0.15, 0.4, 0, 0.1]]},
	"cd_grab": [["C", 0, 0, 0.0, 0.1, 0.0, 30.0, 0.6, 1.0, 0], ["N", 0, 0, 0.0, 0.25, 0.0, 10.0, 0.5, 0.3, 0, 0.1], ["S", 130, 70, 0.0, 0.2, 0.0, 12.0, 0.4, 1.0, 0]],
	"cd_crash": {"drive": 2.4, "layers": [["N", 0, 0, 0.0, 0.55, 0.0, 6.0, 1.0, 0.12, 0], ["C", 0, 0, 0.0, 0.3, 0.0, 9.0, 0.8, 1.0, 0], ["S", 70, 34, 0.0, 0.4, 0.0, 6.0, 0.8, 1.0, 0], ["V", 220, 120, 0.03, 0.5, 0.01, 5.0, 0.45, 1.0, 0.1, 0, [600, 1400, 50]]]},
	"cd_rip": [["N", 0, 0, 0.0, 0.3, 0.0, 9.0, 0.75, 0.5, 0.5, 0.35], ["C", 0, 0, 0.0, 0.14, 0.0, 22.0, 0.55, 1.0, 0], ["N", 0, 0, 0.1, 0.22, 0.0, 10.0, 0.45, 0.9, 0.9, 0.5]],
}

const DebrisScript := preload("res://debris.gd")
const Registry := preload("res://enemies/zombie_registry.gd")

const GLIDE_V := 200.0
const SINK_V := 26.0
const CLIMB_V := 90.0
const THERMAL_TOP := 400.0       # גובה מעל הקרקע שאליו הוא מטפס בזרם
const THERMAL_R := 110.0
const MIN_H := 175.0
const RUN_R := 300.0
const DROP_DMG := 1
const RIDERS := 2                # כמה רוכבים הוא מביא "מבחוץ" (חוץ ממה שהוא תופס מהקרקע)
const RIDER_HP := 26
const WING_HP := 34
const CRASH_DMG := 90
const PICK_R := 650.0
const LEARN := 3
const HIGH_LEARN := 90.0
const SWOOP_H := 150.0
const BEHIND := 120.0
const PIVOT := Vector2(0.0, -30.0)
const FAR_GONE := 2200.0         # רחוק ממך יותר מזה (ולא מתרסק) -> נעלם

enum {TAKEOFF, THERMAL, GLIDE, RUN, DROP, LEAVE, PICK, SPIRAL, AWAY}

# לבדיקות
var drops := 0
var drop_hits := 0
var picks := 0
var fetched := 0
var rider_kills := 0
var wing_hits := 0
var rips := 0
var crashes := 0
var swoops := 0
var thermals := 0

var state := THERMAL
var rider := false
var _rider_kind := 0
var _rider_hp := RIDER_HP
var _rider_col := [Color("8a9a86"), Color("5a6448"), Color("34466a")]   # [עור, חולצה, מכנס]
var _riders_left := RIDERS
var _first := true
var _t := 0.0
var _side := 1.0
var _orbit := 0.0
var _thermal_x := 0.0
var _target_x := 0.0
var _drop_dir := 1.0
var _pick: Node = null
var _dropped: Array = []         # [zombie, זמן] - בודקים אם נחת עליך
var _flap := 0.0
var _flap_v := 0.0
var _flap_n := 0
var _flap_snd := 0.0
var _ang := 0.0
var _spin := 0.0
var _broken := -1
var _wing_hp := [WING_HP, WING_HP]
var _gy := 630.0
var _gy_t := 0.0
var _kick := 0.0
var _scream_t := 0.0
var _bodies: Array = []
var _rbody: StaticBody2D = null
var _var := []                   # [ורדרד בראש, נוצות חסרות, צלעות]


class WingBody extends StaticBody2D:
	var owner_t = null
	var idx := 0
	func take_damage(_a, p: Vector2, d: Vector2, _e := false, s := {}) -> void:
		if owner_t != null:
			owner_t.wing_hit(idx, p, d, s)


class RiderBody extends StaticBody2D:
	var owner_t = null
	func take_damage(_a, p: Vector2, d: Vector2, _e := false, s := {}) -> void:
		if owner_t != null:
			owner_t.rider_hit(p, d, s)


func stats() -> Dictionary:
	return {"name": "CONDOR", "hp": 70, "walk": 40.0, "chase": 90.0, "damage": 1, "bite_delay": 0.8, "scale": 1.0, "width": 1.0,
		"duck": 0.0, "cover": 0.0, "skin": Color("8a7e80"), "shirt": Color("1c1a1e"), "pants": Color("3a3436"), "shoe": Color("2a2420"),
		"points": 520, "ragdoll": false}


func brain_overrides() -> Dictionary:
	return {"aggression": 0.5}


func use_brain_movement() -> bool:
	return false


func can_bite() -> bool:
	return false


func can_groan() -> bool:
	return false


func _main() -> Node:
	return z.get_parent()


func _floor() -> float:
	var m := _main()
	var st = m.get("_stage") if m != null else null
	return float(st.floor_y) if st != null else 630.0


static func is_learned(m: Node) -> bool:
	return m != null and int(m.get_meta("cd_shot", 0)) >= LEARN


func learned() -> bool:
	return is_learned(_main())


func setup() -> void:
	var r := RandomNumberGenerator.new()
	r.seed = z.get_instance_id() * 13 + 1
	_var = [Color("b07a78").lerp(Color("8a7a80"), r.randf()), r.randi() % 3, r.randf() < 0.6]
	for i in 2:
		var b := WingBody.new()
		b.owner_t = self
		b.idx = i
		b.collision_layer = 4
		b.collision_mask = 0
		var cs := CollisionShape2D.new()
		var cc := CircleShape2D.new()
		cc.radius = 22.0 * z.sc
		cs.shape = cc
		b.add_child(cs)
		z.add_child(b)
		_bodies.append(b)
	_rbody = RiderBody.new()
	_rbody.owner_t = self
	_rbody.collision_layer = 0
	_rbody.collision_mask = 0
	var cs2 := CollisionShape2D.new()
	var rr := RectangleShape2D.new()
	rr.size = Vector2(20.0, 46.0) * z.sc
	cs2.shape = rr
	_rbody.add_child(cs2)
	z.add_child(_rbody)
	var rs := z._shape.shape as RectangleShape2D
	rs.size = Vector2(40.0 * z.sc, 18.0 * z.sc)
	z._shape.position = Vector2(0.0, PIVOT.y * z.sc)


func _init_state() -> void:
	z.collision_mask = 0
	z.dormant = false
	rider = true
	_new_rider(0 if randf() < 0.6 else 1)
	_riders_left = RIDERS
	var pl := player() as Node2D
	_side = signf(z.global_position.x - pl.global_position.x) if pl != null else 1.0
	if _side == 0.0:
		_side = 1.0
	if z.has_meta("cd_fly"):
		_thermal_x = z.global_position.x
		state = GLIDE
		z._dir = -_side
	else:
		state = TAKEOFF
		_t = 1.4
		_flap_v = 7.0


func _new_rider(kind: int, cols := []) -> void:
	_rider_kind = kind
	_rider_hp = RIDER_HP
	if cols.is_empty():
		var skins := [Color("8a9ea4"), Color("b8b47a"), Color("74945a"), Color("a08a8a")]
		var shirts := [Color("4f6688"), Color("7a4a3a"), Color("6e3036"), Color("b0342a"), Color("d8702a"), Color("2c3a5a")]
		var pants := [Color("3d3a4c"), Color("34466a"), Color("4e4638"), Color("2e3a2e")]
		_rider_col = [skins[randi() % skins.size()], shirts[randi() % shirts.size()], pants[randi() % pants.size()]]
	else:
		_rider_col = cols


# ============================================================
#  תעופה
# ============================================================
func physics(pl: Node, delta: float) -> bool:
	if z.dead:
		return false
	if _first:
		_first = false
		_init_state()
	_t -= delta
	_scream_t -= delta
	_kick += delta * (9.0 if state == RUN else 4.0)
	var has: bool = pl != null and not pl.dead
	var d: Vector2 = (pl.global_position - z.global_position) if has else Vector2(9999, 0)
	if has and absf(d.x) > FAR_GONE and state != SPIRAL:   # נשאר הרחק מאחור (ריצה / קפיצה): נעלם, שלא יצטברו
		z.queue_free()
		return true
	_gy_t -= delta
	if _gy_t <= 0.0:
		_gy_t = 0.15
		_gy = _ground_under()
	var fl := _floor()
	var hgt: float = fl - z.global_position.y
	_check_drops(pl, has, delta)
	var top := THERMAL_TOP + (HIGH_LEARN if learned() else 0.0)
	match state:
		TAKEOFF:   # המריאה היחידה שבה הוא מנפנף באמת
			_flap_v = 7.0
			z.velocity = z.velocity.move_toward(Vector2(-_side * 90.0, -200.0), 600.0 * delta)
			_ang = lerp_angle(_ang, -0.35, clampf(delta * 4.0, 0.0, 1.0))
			if hgt > MIN_H + 40.0 or _t <= 0.0:
				_to_thermal()
		THERMAL:
			_flap_v = 0.0
			_orbit += delta * 1.15
			var c := Vector2(_thermal_x, z.global_position.y)
			var tgt := c + Vector2(cos(_orbit) * THERMAL_R, -CLIMB_V * 0.6)
			var want: Vector2 = (tgt - z.global_position) * 2.2
			want.y = -CLIMB_V if hgt < top else 0.0
			z.velocity = z.velocity.move_toward(want, 300.0 * delta)
			if absf(z.velocity.x) > 20.0:
				z._dir = signf(z.velocity.x)
			_ang = lerp_angle(_ang, sin(_orbit) * 0.18, clampf(delta * 3.0, 0.0, 1.0))
			if hgt >= top - 20.0 and _t <= 0.0:
				if rider and has and absf(d.x) < 1500.0:
					_glide_to(pl)
				elif not rider:
					_after_empty(pl, has)
		GLIDE:
			_flap_v = 0.0
			var dx: float = _target_x - z.global_position.x
			if has and rider:
				_target_x = _drop_x(pl)
				dx = _target_x - z.global_position.x
			var dirx: float = signf(dx) if absf(dx) > 4.0 else z._dir
			z.velocity.x = move_toward(z.velocity.x, dirx * GLIDE_V, 160.0 * delta)
			z.velocity.y = move_toward(z.velocity.y, SINK_V, 120.0 * delta)
			z._dir = signf(z.velocity.x) if absf(z.velocity.x) > 10.0 else z._dir
			_ang = lerp_angle(_ang, 0.08, clampf(delta * 3.0, 0.0, 1.0))
			if hgt < MIN_H and absf(dx) > RUN_R:   # שקע מדי: חוזר לזרם
				_to_thermal()
			elif rider and absf(dx) < RUN_R and has:
				state = RUN
				_scream_t = 0.0
				if not _main().has_meta("cd_said"):
					_main().set_meta("cd_said", true)
					Game.story.emit("flyer", {"z": z})
		RUN:
			_flap_v = 0.0
			if has:
				_target_x = _drop_x(pl)
			var dx2: float = _target_x - z.global_position.x
			var dirx2: float = signf(dx2) if absf(dx2) > 3.0 else z._dir
			z.velocity.x = move_toward(z.velocity.x, dirx2 * GLIDE_V * 1.15, 260.0 * delta)
			var low := learned() and absf(dx2) < 230.0
			if low:   # (למד) צלילה נמוכה ברגע האחרון
				z.velocity.y = move_toward(z.velocity.y, 300.0 if hgt > SWOOP_H else 0.0, 900.0 * delta)
			else:
				z.velocity.y = move_toward(z.velocity.y, SINK_V, 120.0 * delta)
			z._dir = signf(z.velocity.x) if absf(z.velocity.x) > 10.0 else z._dir
			_ang = lerp_angle(_ang, 0.3 if low else 0.1, clampf(delta * 5.0, 0.0, 1.0))
			if _scream_t <= 0.0:
				_scream_t = 1.6
				Sfx.play("cd_rider", z.global_position + Vector2(0, 30), 0.0, 0.1, 2)
			if absf(dx2) < 26.0 or dx2 * dirx2 < 0.0 or (has and absf(d.x) > 900.0):
				if low:
					swoops += 1
				_drop()
		DROP:
			_flap_v = 9.0
			z.velocity = z.velocity.move_toward(Vector2(z._dir * GLIDE_V, -150.0), 500.0 * delta)
			_ang = lerp_angle(_ang, -0.3, clampf(delta * 5.0, 0.0, 1.0))
			if _t <= 0.0:
				state = LEAVE
				_t = 1.6
		LEAVE:
			_flap_v = 6.0 if _t > 0.8 else 0.0
			z.velocity = z.velocity.move_toward(Vector2(z._dir * GLIDE_V, -60.0 if hgt < top else 0.0), 300.0 * delta)
			_ang = lerp_angle(_ang, -0.1, clampf(delta * 3.0, 0.0, 1.0))
			if _t <= 0.0:
				_after_empty(pl, has)
		PICK:
			_flap_v = 0.0
			if _pick == null or not is_instance_valid(_pick) or _pick.dead:
				_pick = null
				_to_thermal()
			else:
				var tp: Vector2 = _pick.global_position + Vector2(0, -78.0)
				var to: Vector2 = tp - z.global_position
				var v: Vector2 = to.normalized() * minf(360.0, to.length() * 3.0 + 120.0)
				z.velocity = z.velocity.move_toward(v, 700.0 * delta)
				z._dir = signf(z.velocity.x) if absf(z.velocity.x) > 10.0 else z._dir
				_ang = lerp_angle(_ang, clampf(to.angle_to(Vector2(z._dir, 0)) * -0.5, -0.6, 0.6), clampf(delta * 4.0, 0.0, 1.0))
				if to.length() < 34.0:
					_grab(_pick)
				elif _t <= 0.0:
					_pick = null
					_to_thermal()
		AWAY:   # אין לו את מי להעביר: עף לים (נעלם מחוץ למסך)
			_flap_v = 0.0
			z.velocity = z.velocity.move_toward(Vector2(z._dir * GLIDE_V, -70.0), 200.0 * delta)
			if not has or absf(d.x) > 1500.0:
				z.queue_free()
				return true
		SPIRAL:
			_spin += delta * 7.0
			_flap_v = 14.0
			var bs := 1.0 if _broken == 0 else -1.0
			z.velocity.x = move_toward(z.velocity.x, cos(_spin) * 160.0 + bs * z._dir * 70.0, 800.0 * delta)
			z.velocity.y = move_toward(z.velocity.y, 420.0, 500.0 * delta)
			_ang = sin(_spin) * 1.1 + bs * 0.6
			if Engine.get_physics_frames() % 5 == 0 and Art.on_screen(z, z.global_position):
				var dbr = DebrisScript.new()
				_main().add_child(dbr)
				dbr.setup(_wpos(maxi(_broken, 0)), Vector2(randf_range(3, 6), randf_range(6, 10)), Color("1c1a1e") if randf() < 0.7 else Color("e8e4dc"), Vector2(randf_range(-90, 90), -randf_range(30, 120)))
			if z.global_position.y > _gy - 6.0 or z.global_position.y > fl - 4.0:
				_crash()
				return true
	_flap_tick(delta)
	_bodies_update()
	z.move_and_slide()
	if state != SPIRAL:
		var gx: float = z.global_position.x
		if gx < 40.0 or gx > z.world_w - 40.0:
			z.global_position.x = clampf(gx, 40.0, z.world_w - 40.0)
			z.velocity.x = -z.velocity.x * 0.5
			z._dir = -z._dir
		if z.global_position.y < fl - 560.0:
			z.velocity.y = maxf(z.velocity.y, 40.0)
		if z.global_position.y > fl - 90.0 and state != PICK:
			z.velocity.y = minf(z.velocity.y, -40.0)
	return true


# לאן להפיל: עליך (מוביל לאן שאתה הולך), או (למד) מאחוריך - בצד שאליו אתה לא מסתכל
func _drop_x(pl: Node) -> float:
	var px: float = pl.global_position.x
	if learned():
		var face: float = signf(pl._aim.x) if absf(pl._aim.x) > 0.1 else 1.0
		return px - face * BEHIND
	return px + pl.velocity.x * 0.45


func _glide_to(pl: Node) -> void:
	state = GLIDE
	_target_x = _drop_x(pl)
	Sfx.play("cd_whoosh", z.global_position, -4.0, 0.1, 2)


func _to_thermal() -> void:
	state = THERMAL
	thermals += 1
	_t = 1.0
	_thermal_x = _nearest_thermal()
	_orbit = atan2(0.0, z.global_position.x - _thermal_x)


# זרם עולה קרוב (השלב: updrafts()). בלי - מטפס במקום
func _nearest_thermal() -> float:
	var m := _main()
	var st = m.get("_stage") if m != null else null
	var best: float = z.global_position.x
	if st != null and st.has_method("updrafts"):
		var bd := 99999.0
		var pl := player() as Node2D
		var px: float = pl.global_position.x if pl != null else z.global_position.x
		for ux in st.updrafts():
			var dd := absf(float(ux) - z.global_position.x) + absf(float(ux) - px) * 0.5
			if dd < bd:
				bd = dd
				best = float(ux)
		if bd > 1400.0:
			best = z.global_position.x
	return best


# ריק: תופס זומבי מהקרקע לפניך (PICK), או מביא מבחוץ, או עף
func _after_empty(pl: Node, has: bool) -> void:
	if not has:
		_to_thermal()
		return
	var cand := _find_pick(pl)
	if cand != null:
		state = PICK
		_pick = cand
		_t = 3.5
		Sfx.play("cd_hiss", z.global_position, 0.0, 0.1, 2)
		return
	if _riders_left > 0:
		_riders_left -= 1
		fetched += 1
		rider = true
		_new_rider(0 if randf() < 0.55 else 1)
		_to_thermal()
		return
	state = AWAY


func _find_pick(pl: Node) -> Node:
	var px: float = pl.global_position.x
	var best: Node = null
	var bd := PICK_R
	for zz in z.get_tree().get_nodes_in_group("zombies"):
		if zz == z or zz.dead or zz.is_boss() or not zz.is_on_floor() or zz.has_meta("cd_picked"):
			continue
		if not (zz.kind == 0 or zz.kind == 1 or zz.kind == Registry.THRONG):
			continue
		var dx: float = zz.global_position.x - px
		if absf(dx) < 220.0 or absf(dx) > PICK_R:
			continue
		var dd := absf(zz.global_position.x - z.global_position.x)
		if dd < bd:
			bd = dd
			best = zz
	return best


# תופס את הזומבי: הוא נעלם מהקרקע והופך לרוכב (שומר סוג, צבעים וחיים)
func _grab(zz: Node) -> void:
	picks += 1
	zz.set_meta("cd_picked", true)
	var cols := [zz.skin, zz.shirt, zz.pants]
	var k: int = zz.kind
	var hp: int = zz.hp
	zz.remove_from_group("zombies")
	zz.queue_free()
	_pick = null
	rider = true
	_new_rider(k, cols)
	_rider_hp = clampi(hp, 8, RIDER_HP)
	Sfx.play("cd_grab", z.global_position, 2.0, 0.1, 2)
	if Art.on_screen(z, z.global_position):
		Particles.burst(_main(), z.global_position + Vector2(0, -10), "smoke", Vector2.UP, 4)
	var m := _main()
	if not m.has_meta("cd_pick_said"):
		m.set_meta("cd_pick_said", true)
		z._popup("THEY CARRY EACH OTHER NOW", Color("ff8a7a"), 14, -120.0)
		var pl := player()
		if pl != null and pl.has_method("_say"):
			pl._say("It picked one up... it's carrying them over my head!", Color("ff8a7a"))
	state = THERMAL
	_thermal_x = z.global_position.x
	_t = 0.6
	z.velocity = Vector2(z.velocity.x * 0.4, -120.0)


# משחרר את הרוכב: זומבי אמיתי שנופל (עליך)
func _drop() -> void:
	drops += 1
	state = DROP
	_t = 0.55
	rider = false
	var nz = _spawn_rider()
	if nz != null:
		nz.velocity = Vector2(z.velocity.x * 0.5, 60.0)
		_dropped.append([nz, 1.6])
	Sfx.play("cd_flap", z.global_position, 2.0, 0.1, 2)
	var m := _main()
	if learned() and not m.has_meta("cd_behind_said"):
		m.set_meta("cd_behind_said", true)
		z._popup("THEY DROP THEM BEHIND YOU NOW", Color("ff8a7a"), 14, -120.0)
		var pl := player()
		if pl != null and pl.has_method("_say"):
			pl._say("Behind me - it's dropping them BEHIND me!", Color("ff8a7a"))


func _rider_feet() -> Vector2:
	return _center() + Vector2(0.0, 62.0 * z.sc)


func _spawn_rider() -> Node:
	var m := _main()
	if m == null or not m.has_method("_spawn_zombie"):
		return null
	var p := _rider_feet()
	var nz = m._spawn_zombie(p.x, p.y, _rider_kind)
	if nz == null:
		return null
	nz.dormant = false
	nz.position = p
	nz.skin = _rider_col[0]
	nz.shirt = _rider_col[1]
	nz.pants = _rider_col[2]
	nz.hp = mini(nz.hp, _rider_hp) if _rider_hp > 0 else nz.hp
	nz._alert_t = 6.0
	nz.set_meta("cd_picked", true)
	if nz.type_mod != null and nz.type_mod.get("_var") != null and nz.type_mod._var.size() > 0:
		nz.type_mod._var[0] = _rider_col[1]
	return nz


# זומבי שהופל: נחת עליך?
func _check_drops(pl: Node, has: bool, delta: float) -> void:
	if _dropped.is_empty():
		return
	for i in range(_dropped.size() - 1, -1, -1):
		var e: Array = _dropped[i]
		e[1] = float(e[1]) - delta
		var nz = e[0]
		if not is_instance_valid(nz) or nz.dead or float(e[1]) <= 0.0 or nz.is_on_floor():
			_dropped.remove_at(i)
			continue
		if has and nz.velocity.y > 40.0:
			var r := Rect2(nz.global_position + Vector2(-12.0, -50.0), Vector2(24.0, 50.0))
			if r.intersects(pl.body_rect()):
				_dropped.remove_at(i)
				if pl._roll_t <= 0.0:
					drop_hits += 1
					nz._popup("LANDED ON YOU", Color("ffb070"), 13, -70.0)
				pl.hurt(DROP_DMG, Vector2(signf(pl.global_position.x - nz.global_position.x + 0.01) * 1.4, -0.4))
				nz.velocity = Vector2(-nz.velocity.x * 0.3, -160.0)


func _flap_tick(delta: float) -> void:
	if _flap_v > 0.0:
		_flap += delta * _flap_v
		_flap_snd -= delta
		if _flap_snd <= 0.0 and Art.on_screen(z, z.global_position):
			_flap_snd = TAU / _flap_v
			Sfx.play("cd_flap", z.global_position, -2.0, 0.12, 2)
	else:   # דאייה: הכנפיים כמעט לא זזות (רק רעד קל בקצוות)
		_flap = lerpf(_flap, sin(z._time * 1.4) * 0.12, clampf(delta * 3.0, 0.0, 1.0))


func _center() -> Vector2:
	return z.global_position + PIVOT * z.sc


# ============================================================
#  כנפיים + רוכב: גופי הפגיעה, נזק, קריעה
# ============================================================
func _wing_ang(i: int) -> float:
	var flap := sin(_flap) * 0.55 if _flap_v > 0.0 else _flap
	return (-1.05 if i == 0 else -2.15) + flap * (1.0 if i == 0 else 0.8)   # V רחב: הקרובה קדימה-למעלה, הרחוקה אחורה-למעלה


func _shoulder(i: int) -> Vector2:
	return Vector2(4.0, -34.0) if i == 0 else Vector2(1.0, -35.0)


func _wpos(i: int) -> Vector2:
	var a := _wing_ang(i)
	var local := _shoulder(i) - PIVOT + Vector2(cos(a), sin(a)) * 38.0
	local = local.rotated(_ang)
	local.x *= z._dir
	return _center() + local * z.sc


func _bodies_update() -> void:
	for i in 2:
		var b: StaticBody2D = _bodies[i]
		var live: bool = int(_wing_hp[i]) > 0 and state != SPIRAL
		b.collision_layer = 4 if live else 0
		if live:
			b.global_position = _wpos(i)
	_rbody.collision_layer = 4 if rider and state != SPIRAL else 0
	if rider:
		_rbody.global_position = _center() + Vector2(0.0, 36.0 * z.sc)


func wing_hit(i: int, p: Vector2, d: Vector2, src: Dictionary) -> void:
	if z.dead or int(_wing_hp[i]) <= 0:
		return
	var dmg := _shot_dmg(src)
	wing_hits += 1
	z._flash = 0.05
	Game.on_zombie_hit({"source": "bullet", "zone": "wing", "shot": src.get("shot", 0)})
	Sfx.play("cd_rip", p, -8.0, 0.2, 3)
	if Art.on_screen(z, p):
		for k in Quality.scaled(2, 1.0):
			var dbr = DebrisScript.new()
			_main().add_child(dbr)
			dbr.setup(p, Vector2(randf_range(2, 4), randf_range(5, 9)), Color("1c1a1e") if k % 2 == 0 else Color("e8e4dc"), Vector2(d.x * randf_range(60, 180), -randf_range(40, 180)))
		Particles.burst(_main(), p, "hit", d, 3)
	_wing_hp[i] = int(_wing_hp[i]) - dmg
	if int(_wing_hp[i]) <= 0:
		_rip(i, d)


func _shot_dmg(src: Dictionary) -> int:
	var dmg := 10
	if src.has("fixed"):
		dmg = int(src.fixed)
	elif src.has("dmg_mult"):
		dmg = maxi(4, int(round(10.0 * float(src.dmg_mult))))
	if src.get("sniper", false):
		dmg *= 2
	if src.get("god", false):
		dmg *= 4
	return dmg


func rider_hit(p: Vector2, d: Vector2, src: Dictionary) -> void:
	if z.dead or not rider:
		return
	var dmg := _shot_dmg(src)
	_rider_hp -= dmg
	Game.on_zombie_hit({"source": "bullet", "zone": "body", "shot": src.get("shot", 0)})
	Sfx.play("hit", p, -4.0, 0.15, 4)
	_spray(p, d, 5)
	if _rider_hp <= 0:
		_rider_dies(d)


func _spray(p: Vector2, d: Vector2, n: int) -> void:
	if Art.on_screen(z, p):
		Particles.burst(_main(), p, "hit", d, int(float(n * 2) * Quality.gore()) + 1)
		z._spray_blood(p, Vector2(d.x, 0.4), n, 220.0)


# הרוכב נורה באוויר: גופה אמיתית נופלת (נספר להריגה), והקונדור "לומד"
func _rider_dies(d: Vector2) -> void:
	rider_kills += 1
	rider = false
	var nz = _spawn_rider()
	var m := _main()
	if m != null:
		m.set_meta("cd_shot", int(m.get_meta("cd_shot", 0)) + 1)
		if int(m.get_meta("cd_rider_pop", 0)) < 2:
			m.set_meta("cd_rider_pop", int(m.get_meta("cd_rider_pop", 0)) + 1)
			z._popup("CARGO DOWN", Color("ffd34a"), 15, -60.0)
	if nz != null:
		nz.take_damage(999, nz.global_position + Vector2(0, -30), Vector2(d.x, -0.3), false, {"source": "bullet", "fixed": 999, "knockback": 140.0})
	Sfx.play("cd_hiss", z.global_position, 0.0, 0.1, 2)
	if state == RUN or state == GLIDE:
		state = LEAVE
		_t = 1.4


func _rip(i: int, d: Vector2) -> void:
	_wing_hp[i] = 0
	if state == SPIRAL:
		return
	_broken = i
	rips += 1
	state = SPIRAL
	_spin = 0.0
	if rider:   # הרוכב נופל חי
		rider = false
		var nz = _spawn_rider()
		if nz != null:
			nz.velocity = Vector2(z.velocity.x * 0.4, 40.0)
			_dropped.append([nz, 1.6])
	Sfx.play("cd_rip", z.global_position, 3.0, 0.0, 2)
	Sfx.play("cd_hiss", z.global_position, 2.0, 0.1, 2, 0.8)
	var m := _main()
	if int(m.get_meta("cd_rip_pop", 0)) < 3:
		m.set_meta("cd_rip_pop", int(m.get_meta("cd_rip_pop", 0)) + 1)
		z._popup("WING!", Color("ffd34a"), 16, -110.0)
	if Art.on_screen(z, z.global_position):
		var at := _wpos(i)
		for k in Quality.scaled(8, 1.0):
			var dbr = DebrisScript.new()
			m.add_child(dbr)
			dbr.setup(at + Vector2(randf_range(-16, 16), randf_range(-16, 16)), Vector2(randf_range(3, 6), randf_range(6, 12)), Color("1c1a1e") if k % 3 != 0 else Color("e8e4dc"), Vector2(d.x * randf_range(40, 160) + randf_range(-80, 80), -randf_range(60, 240)))
		Particles.burst(m, at, "hit", d, int(8.0 * Quality.gore()) + 2)


func _crash() -> void:
	crashes += 1
	var m := _main()
	Sfx.play("cd_crash", z.global_position, 4.0, 0.08, 2)
	if Art.on_screen(z, z.global_position):
		Particles.burst(m, z.global_position + Vector2(0, -4), "smoke", Vector2.UP, Quality.scaled(10, 1.0))
		for k in Quality.scaled(7, Quality.gore()):
			var dbr = DebrisScript.new()
			m.add_child(dbr)
			dbr.setup(z.global_position + Vector2(randf_range(-14, 14), -6), Vector2(randf_range(3, 6), randf_range(4, 8)), Color("1c1a1e") if k % 2 == 0 else Color("e8e4dc"), Vector2(randf_range(-240, 240), -randf_range(120, 300)))
		var cam: Camera2D = z.get_viewport().get_camera_2d()
		if cam != null and cam.has_method("shake"):
			cam.shake(8.0, 0.25)
	if int(m.get_meta("cd_crash_pop", 0)) < 3:
		m.set_meta("cd_crash_pop", int(m.get_meta("cd_crash_pop", 0)) + 1)
		z._popup("GROUNDED!", Color("ffd34a"), 16, -70.0)
	z.collision_mask = 1 | 16
	z._spray_blood(z.global_position + Vector2(0, -16), Vector2(signf(z.velocity.x + 0.01), -0.8), 16, 400.0)
	z.velocity = Vector2(z.velocity.x * 0.5, -120.0)
	z.take_damage(CRASH_DMG, z.global_position + Vector2(0, -26.0 * z.sc), Vector2(signf(z.velocity.x + 0.01), -0.4), false, {"source": "crash", "fixed": CRASH_DMG, "knockback": 200.0})


func on_damage(_amount: int, _hit_pos: Vector2, _dir: Vector2, src: Dictionary) -> bool:
	if z.dead:
		return true
	if src.has("blast") and state != SPIRAL:   # פיצוץ קורע את שתי הכנפיים (והרוכב מת)
		if rider:
			_rider_dies(Vector2.UP)
		for i in 2:
			_wing_hp[i] = 0
		_broken = 0
		state = SPIRAL
		rips += 1
		_spin = 0.0
	return true


func on_death() -> void:
	for b in _bodies:
		if is_instance_valid(b):
			b.collision_layer = 0
	_rbody.collision_layer = 0
	z.collision_mask = 1 | 16
	if rider:   # הקונדור מת באוויר: הרוכב נופל חי
		rider = false
		var nz = _spawn_rider()
		if nz != null:
			nz.velocity = Vector2(z.velocity.x * 0.4, 40.0)
	if Art.on_screen(z, z.global_position):
		for k in Quality.scaled(5, 1.0):
			var dbr = DebrisScript.new()
			_main().add_child(dbr)
			dbr.setup(_center(), Vector2(randf_range(3, 5), randf_range(6, 10)), Color("1c1a1e") if k % 2 == 0 else Color("e8e4dc"), Vector2(randf_range(-160, 160), -randf_range(60, 220)))


func _ground_under() -> float:
	var from: Vector2 = z.global_position + Vector2(0, -4)
	var q := PhysicsRayQueryParameters2D.create(from, from + Vector2(0, 900), 17)
	q.exclude = [z.get_rid()]
	var hit: Dictionary = z.get_world_2d().direct_space_state.intersect_ray(q)
	return float(hit.position.y) if hit else _floor()


# ============================================================
#  ציור: קונדור ענק דואה (כנפיים פרושות ב-V, "אצבעות" בקצוות, פס לבן), צווארון לבן, ראש קירח, רוכב משתלשל בטפרים
# ============================================================
func wants_redraw() -> bool:
	return true


func draw() -> bool:
	if _var.is_empty():
		return false
	if z.dead:
		begin_draw()
		_draw_bird(true)
		end_draw()
		return true
	# צל על הקרקע (רחב - מוטת הכנפיים)
	var hgt: float = maxf(0.0, _gy - z.global_position.y)
	var a := clampf(1.0 - hgt / 560.0, 0.15, 0.55)
	DrawBatch.colored_polygon(z, Art.ellipse(Vector2(0, hgt), 46.0 * (0.7 + hgt / 700.0), 4.0, 0.0, 14), Color(0.06, 0.05, 0.05, a * 0.45))
	var s := Vector2(z._dir * z.wf * z.sc, z.sc)
	DrawBatch.set_transform_matrix(z, Transform2D(0.0, s, 0.0, Vector2.ZERO) * Transform2D(_ang, PIVOT) * Transform2D(0.0, -PIVOT))
	if rider:
		_draw_rider()
	_draw_bird(false)
	if state == RUN or state == PICK:
		var k := 0.5 + 0.5 * sin(z._time * 12.0)
		DrawBatch.string(z, ThemeDB.fallback_font, Vector2(20, -64), "!", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(1.0, 0.35, 0.2, 0.5 + 0.5 * k))
	end_draw()
	return true


func _draw_bird(dead: bool) -> void:
	var black := col(Color("1c1a1e"))
	var black2 := col(Color("2c2a30"))
	var white := col(Color("e8e4dc"))
	var tt: float = z._time
	if dead:   # גופה: כנפיים פרושות על הקרקע
		DrawBatch.colored_polygon(z, PackedVector2Array([Vector2(-50, -4), Vector2(-6, -12), Vector2(46, -6), Vector2(40, -1), Vector2(-46, 0)]), black)
		Art.oval(z, Vector2(0, -8), 13.0, 6.0, black2, 0.0)
		Art.oval(z, Vector2(14, -6), 4.0, 3.0, white, 0.0, Art.NONE)
		Art.oval(z, Vector2(19, -5), 3.6, 3.0, col(_var[0]), 0.0)
		Art.oval(z, Vector2(-4, -9), 4.0, 2.4, Color(0.45, 0.05, 0.05, 0.9), 0.0, Art.NONE)
		return
	# כנף רחוקה
	_wing(1, black2, white)
	# זנב (קצר ורחב)
	DrawBatch.colored_polygon(z, PackedVector2Array([Vector2(-14, -33), Vector2(-30, -31), Vector2(-31, -27), Vector2(-14, -27)]), black)
	# טפרים (אוחזים ברוכב / מקופלים)
	var tl := Vector2(-2.0, -22.0)
	if rider:
		for q in 2:
			var tp := Vector2(-3.0 + float(q) * 5.0, -16.0)
			DrawBatch.line(z, tl + Vector2(float(q) * 3.0, 0), tp, col(Color("6a6060")), 1.8)
			for c in 3:
				DrawBatch.line(z, tp, tp + Vector2(-2.0 + float(c) * 2.0, 3.0), col(Color("2a2420")), 0.9)
	elif state == PICK:
		for q in 2:
			DrawBatch.line(z, tl + Vector2(float(q) * 3.0, 0), tl + Vector2(4.0 + float(q) * 3.0, 9.0), col(Color("6a6060")), 1.8)
	else:
		DrawBatch.line(z, tl, tl + Vector2(-10.0, 2.0), col(Color("6a6060")), 1.8)
	# גוף
	var body := PackedVector2Array([Vector2(12, -38), Vector2(15, -31), Vector2(6, -24), Vector2(-14, -25), Vector2(-17, -31), Vector2(-8, -38)])
	Art.fill_shaded(z, body, black2, 0.1, 0.25)
	if _var[2]:   # נוצות נשרו: צלעות וקרום חשופים
		DrawBatch.colored_polygon(z, PackedVector2Array([Vector2(-6, -33), Vector2(2, -34), Vector2(3, -27), Vector2(-5, -27)]), col(Color("5a1a1a")))
		for q in 3:
			DrawBatch.line(z, Vector2(-5.0 + float(q) * 3.0, -33.0), Vector2(-4.0 + float(q) * 3.0, -27.5), col(Color("d8ccb0")), 0.8)
	# צווארון לבן פלאפי
	for q in 5:
		Art.oval(z, Vector2(12.0 + float(q % 2) * 1.5, -39.0 + float(q) * 2.0), 3.2, 2.2, white, 0.0, Art.NONE)
	# צוואר וראש קירח, כרבולת, מקור מכופף
	var head := Vector2(22.0, -42.0)
	Art.limb(z, PackedVector2Array([Vector2(14, -38), head + Vector2(-3, 1)]), 4.0, col(_var[0]))
	Art.oval_shaded(z, head, 5.0, 4.2, col(_var[0]), 0.1)
	DrawBatch.colored_polygon(z, PackedVector2Array([head + Vector2(-3.0, -3.5), head + Vector2(1.0, -6.5), head + Vector2(4.0, -4.0), head + Vector2(2.0, -3.0)]), col(Art.shade(_var[0], -0.25)))   # כרבולת
	DrawBatch.colored_polygon(z, PackedVector2Array([head + Vector2(3.5, -1.5), head + Vector2(9.0, -0.5), head + Vector2(10.0, 2.5), head + Vector2(8.0, 3.5), head + Vector2(7.6, 1.6), head + Vector2(3.5, 1.6)]), col(Color("d8c8a0")))
	DrawBatch.line(z, head + Vector2(8.5, 1.0), head + Vector2(8.8, 3.4), col(Color("6a5a40")), 0.8)
	# עין ECHO
	var ec := Color(0.55, 1.0, 0.5)
	if z.has_meta("s57_learned_t"):
		ec = ec.lerp(Color(1.0, 1.0, 0.8), clampf(1.0 - float(Time.get_ticks_msec() - int(z.get_meta("s57_learned_t"))) / 600.0, 0.0, 1.0))
	DrawBatch.circle(z, head + Vector2(1.5, -1.0), 1.0, ec)
	Art.glow(z, head + Vector2(1.5, -1.0), 4.0 + (2.0 if state == RUN else 0.0), Color(ec, 0.4))
	# כנף קרובה
	_wing(0, black, white)


# כנף: עצם יד ארוכה, נוצות כיסוי שחורות, פס לבן (נוצות משניות), חמש "אצבעות" פרושות בקצה. נקרעה = גדם
func _wing(i: int, black: Color, white: Color) -> void:
	var sh := _shoulder(i)
	var a := _wing_ang(i)
	var dv := Vector2(cos(a), sin(a))
	var nv := Vector2(-dv.y, dv.x)
	if nv.x > 0.0:   # (הקצה האחורי של הכנף לכיוון הזנב)
		nv = -nv
	var ln := 64.0 if i == 0 else 56.0
	var wd := 20.0 if i == 0 else 17.0
	if int(_wing_hp[i]) <= 0:
		var e := sh + dv * 18.0
		Art.limb(z, PackedVector2Array([sh, e]), 3.4, black)
		DrawBatch.circle(z, e, 2.2, Color(0.5, 0.05, 0.05, 0.9))
		for q in 3:
			DrawBatch.line(z, e, e + nv * (5.0 + float(q) * 3.0) + dv * float(q), black, 1.4)
		return
	var tip := sh + dv * ln
	# נוצות כיסוי (גוף הכנף)
	var poly := PackedVector2Array([sh + nv * 2.0, sh + dv * ln * 0.55 - nv * 2.0, tip, tip + nv * wd * 0.7, sh + dv * ln * 0.5 + nv * wd, sh + nv * wd * 0.8])
	Art.fill(z, poly, black, Art.OUTLINE, 1.0)
	# פס לבן (נוצות משניות - הסימן של הקונדור)
	var w0 := sh + dv * 10.0 + nv * wd * 0.55
	var w1 := sh + dv * ln * 0.7 + nv * wd * 0.55
	DrawBatch.colored_polygon(z, PackedVector2Array([w0, w1, w1 + nv * wd * 0.3, w0 + nv * wd * 0.35]), Color(white, 0.85 if i == 0 else 0.6))
	for q in 5:   # קצוות משוננים של הנוצות המשניות
		var p0 := w0.lerp(w1, float(q) / 4.0) + nv * wd * 0.33
		DrawBatch.colored_polygon(z, PackedVector2Array([p0 - dv * 3.0, p0 + dv * 3.0, p0 + nv * 4.0]), black)
	# "אצבעות": 5 נוצות ראשוניות פרושות בקצה
	for q in 5:
		var fa := a + 0.16 * float(q) * signf(nv.angle_to(dv) * -1.0 + 0.0001) - 0.3
		var fd := Vector2(cos(fa), sin(fa)).rotated(0.08 * float(q))
		var base := tip + nv * float(q) * 2.6
		DrawBatch.line(z, base, base + fd * (16.0 - float(q) * 1.2), black, 2.6 - float(q) * 0.2)
	# עצם היד (שולי הכנף הקדמיים)
	DrawBatch.line(z, sh, sh + dv * ln * 0.55, col(Art.shade(Color("2c2a30"), 0.15)), 2.2)
	if _var[1] == i:   # נוצות חסרות: חור עם קרום ועצם
		var hp := sh + dv * ln * 0.4 + nv * wd * 0.4
		Art.oval(z, hp, 5.0, 3.0, col(Color("6a2a26")), a, Art.NONE)
		DrawBatch.line(z, hp - dv * 4.0, hp + dv * 4.0, col(Color("d8ccb0")), 0.9)


# הרוכב: זומבי שמשתלשל מהטפרים - כתפיים למעלה, ידיים מושטות למטה (אליך), רגליים בועטות, ראש שמוט
func _draw_rider() -> void:
	var skin := col(_rider_col[0])
	var shirt := col(_rider_col[1])
	var pa := col(_rider_col[2])
	var top := Vector2(0.0, -14.0)
	var kick := sin(_kick) * 4.0
	var sh := top + Vector2(0.0, 2.0)
	var hip := top + Vector2(-1.0, 22.0)
	# ידיים מושטות למטה (רוצות אותך)
	var reach := 1.0 if state == RUN else 0.4
	z._arm(sh + Vector2(-3.0, 1.0), sh + Vector2(-6.0 + sin(_kick * 0.7) * 3.0, 16.0 + reach * 4.0), skin, shirt)
	# רגליים בועטות
	z._leg(hip + Vector2(-2.0, 0), hip + Vector2(-4.0 + kick, 24.0), pa, skin, col(Color("2a2420")))
	z._leg(hip + Vector2(2.0, 0), hip + Vector2(3.0 - kick, 23.0), Art.shade(pa, 0.1), skin, col(Color("2a2420")))
	# גוף
	var body := PackedVector2Array([sh + Vector2(-7.5, -1.0), sh + Vector2(7.0, -1.0), hip + Vector2(6.5, 1.0), hip + Vector2(-7.0, 1.0)])
	Art.fill_shaded(z, body, shirt, 0.15, 0.3)
	Art.oval(z, sh + Vector2(1.0, 8.0), 2.4, 3.0, Color(0.45, 0.05, 0.05, 0.7), 0.2, Art.NONE)
	# ראש שמוט קדימה, פה פתוח
	var head := sh + Vector2(5.0, -4.0)
	Art.oval_shaded(z, head, 5.6, 6.2, skin, 0.4)
	DrawBatch.colored_polygon(z, PackedVector2Array([head + Vector2(1.0, 2.0), head + Vector2(5.0, 2.0), head + Vector2(4.0, 5.0)]), col(Color("2a0a0c")))
	DrawBatch.circle(z, head + Vector2(3.0, -1.0), 0.9, Color(1.0, 0.4, 0.2))
	z._arm(sh + Vector2(3.0, 1.0), sh + Vector2(6.0 + cos(_kick * 0.8) * 3.0, 15.0 + reach * 5.0), skin, shirt)
