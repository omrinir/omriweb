extends "res://enemies/zombie_type.gd"
# ============================================================
#  SKUA (שלב 58, "WHALE GRAVEYARD") - המעופף של השלב. מת שתפר לעצמו כנפיים: לוחות מזיפות של לווייתן (baleen) קשורים לאמות
#    כמו נוצות ראשוניות, ועור כלב ים תפור ביניהם כקרום. ברדס עור כלב ים, ומקור מעוקל משן לווייתן קשור על הפנים.
#  מה הוא למד, וממה: הסקואות של החוף צדות כך - דואות גבוה, צוללות על הטרף מאחור, וחוזרות למעלה. המתים ראו את זה מהחוף שנים.
#    הוא לא נסחף ברוח (DRIFTER) ולא להקה (MURMUR): הוא ציפור טורפת אחת, מהירה, שתוקפת ונעלמת.
#  מחזור:
#    PERCH   - יושב על תורן / גג מיכל עם הכנפיים מקופלות כמו גלימה. אתה בטווח (PERCH_R) -> TAKEOFF.
#    SOAR    - דואה גבוה (SOAR_H) בצד שלך (SOAR_OFF), במעגלים רחבים. תמיד צולל תוך SOAR_T.
#    STOOP_W - נעצר באוויר, מקפל כנפיים וצווח (STOOP_WIND) - הסימן.
#    STOOP   - צלילה ישרה ומהירה (STOOP_V) אל המקום שלך (קצת מתקן): שריטה (RAKE_DMG) וממשיך דרכך.
#    CLIMB   - עולה בכבדות בצד השני עם כנפיים פרושות ומשק כנפיים חזק (CLIMB_T) - המטרה הכי גדולה שלו.
#  נגד: לירות בכנפיים (WingBody, WING_HP לכל אחת) כשהן פרושות (דאייה / טיפוס). כנף אחת נקרעה -> SPIRAL: מסתחרר לצד
#    השבור ומתרסק (CRASH_DMG). מקופלות (צלילה) - רק הגוף הקטן פגיע. לקפוץ / להתגלגל מתחת לצלילה. פיצוץ קורע את שתיהן,
#    קליעי אש מבעירים כנף.
#  "THEY FEINT THE DIVE NOW" (main meta "sk_downs" >= LEARN - כמה הפלת): בצלילה (FEINT_CHANCE) הוא נמשך למעלה ממש לפני
#    שהוא מגיע אליך (FEINT_R), עובר מעליך לצד השני וצולל משם בצלילה קצרה (FEINT_WIND). נגד: לא להתגלגל מוקדם - לחכות לצלילה
#    השנייה, או להפיל אותו בזמן המשיכה למעלה (הכנפיים נפתחות).
#  לשנות: SOAR_H, SOAR_OFF, SOAR_V, SOAR_T, STOOP_WIND, STOOP_V, STOOP_MAX, RAKE_DMG, CLIMB_T, CLIMB_V, WING_HP, CRASH_DMG,
#    PERCH_R, LEARN, FEINT_CHANCE, FEINT_R, FEINT_WIND.
# ============================================================

const SOUNDS := {
	"sk_screech": {"drive": 2.8, "layers": [["V", 620, 980, 0.0, 0.42, 0.01, 4.0, 0.8, 1.0, 0.1, 0, [1100, 2600, 55]], ["V", 700, 1100, 0.05, 0.3, 0.01, 6.0, 0.4, 1.0, 0.12, 0, [1200, 2800, 50]], ["N", 0, 0, 0.0, 0.3, 0.0, 8.0, 0.25, 0.7, 0, 0.3]]},
	"sk_flap": {"drive": 1.4, "layers": [["N", 0, 0, 0.0, 0.22, 0.01, 8.0, 0.55, 0.22, 0.5, 0.05], ["B", 10.0, 6.0, 0.0, 0.22, 0.0, 8.0, 0.25, 1.0, 0, 0, 24.0]]},
	"sk_dive": [["N", 0, 0, 0.0, 0.8, 0.15, 2.0, 0.6, 0.45, 0, 0.6], ["S", 900, 1500, 0.0, 0.8, 0.2, 2.0, 0.12, 1.0, 0.0]],
	"sk_rip": [["N", 0, 0, 0.0, 0.25, 0.0, 10.0, 0.7, 0.6, 0.5, 0.35], ["C", 0, 0, 0.0, 0.12, 0.0, 26.0, 0.5, 1.0, 0], ["N", 0, 0, 0.08, 0.18, 0.0, 12.0, 0.45, 0.9, 0.9, 0.5]],
	"sk_crash": {"drive": 2.4, "layers": [["N", 0, 0, 0.0, 0.45, 0.0, 7.0, 0.9, 0.12, 0], ["C", 0, 0, 0.0, 0.25, 0.0, 10.0, 0.7, 1.0, 0], ["S", 85, 40, 0.0, 0.3, 0.0, 8.0, 0.7, 1.0, 0], ["V", 300, 160, 0.03, 0.35, 0.01, 6.0, 0.4, 1.0, 0.1, 0, [700, 1600, 60]]]},
	"sk_rake": [["N", 0, 0, 0.0, 0.18, 0.0, 14.0, 0.7, 0.7, 0, 0.4], ["S", 2600, 1800, 0.0, 0.08, 0.0, 30.0, 0.25, 1.0, 0]],
}

const DebrisScript := preload("res://debris.gd")
const Decor := preload("res://effects/s58_decor.gd")

const SOAR_H := Vector2(240.0, 320.0)    # גובה הדאייה מעל הקרקע
const SOAR_OFF := 240.0
const SOAR_V := 270.0
const SOAR_T := Vector2(1.5, 2.7)
const STOOP_WIND := 0.38
const STOOP_V := 650.0
const STOOP_MAX := 1.1
const RAKE_DMG := 1
const CLIMB_T := 0.85
const CLIMB_V := 300.0
const WING_HP := 16
const CRASH_DMG := 70
const PERCH_R := 640.0
const LEARN := 3
const FEINT_CHANCE := 0.65
const FEINT_R := 210.0
const FEINT_WIND := 0.16
const PIVOT := Vector2(0.0, -30.0)       # מרכז הגוף (יחידות ציור) - סביבו מסתובב

enum {PERCH, TAKEOFF, SOAR, STOOP_W, STOOP, CLIMB, FEINT, SPIRAL}

# לבדיקות
var takeoffs := 0
var stoops := 0
var rakes := 0
var feints := 0
var wing_hits := 0
var rips := 0
var crashes := 0
var burns := 0
var climbs := 0

var state := SOAR
var _first := true
var _t := 0.0
var _side := 1.0                 # באיזה צד שלך הוא דואה
var _target := Vector2.ZERO
var _hit := false
var _feint_plan := false
var _feinted := false
var _spread := 1.0               # 0 מקופלות .. 1 פרושות
var _flap := 0.0
var _flap_v := 2.0
var _flap_snd := 0.0
var _ang := 0.0                  # זווית הגוף
var _spin := 0.0
var _wing_hp := [WING_HP, WING_HP]   # [קרובה (קדמית), רחוקה (אחורית)]
var _wfire := [0.0, 0.0]
var _broken := -1                # איזו כנף נקרעה
var _gy := 630.0
var _gy_t := 0.0
var _dove := false               # צלל לפחות פעם אחת
var _bodies: Array = []
var _var := []                   # [עור, מזיפות, ברדס, צלקת]


class WingBody extends StaticBody2D:
	var owner_t = null
	var idx := 0
	func take_damage(_a, p: Vector2, d: Vector2, _e := false, s := {}) -> void:
		if owner_t != null:
			owner_t.wing_hit(idx, p, d, s)


func stats() -> Dictionary:
	return {"name": "SKUA", "hp": 30, "walk": 40.0, "chase": 90.0, "damage": 1, "bite_delay": 0.8, "scale": 1.0, "width": 1.0,
		"duck": 0.0, "cover": 0.0, "skin": Color("94a090"), "shirt": Color("5a5048"), "pants": Color("3a3632"), "shoe": Color("2a2420"),
		"points": 400, "ragdoll": false}


func brain_overrides() -> Dictionary:
	return {"aggression": 0.8}


func use_brain_movement() -> bool:
	return false


func can_bite() -> bool:
	return false


func can_groan() -> bool:
	return state == PERCH


func _main() -> Node:
	return z.get_parent()


func _floor() -> float:
	var m := _main()
	var st = m.get("_stage") if m != null else null
	return float(st.floor_y) if st != null else 630.0


static func is_learned(m: Node) -> bool:
	return m != null and int(m.get_meta("sk_downs", 0)) >= LEARN


func learned() -> bool:
	return is_learned(_main())


func setup() -> void:
	var r := RandomNumberGenerator.new()
	r.seed = z.get_instance_id() * 5 + 7
	var skins := [Color("6e5a48"), Color("7a6650"), Color("5e5044"), Color("84705a")]
	var baleens := [Color("2a2622"), Color("3a322a"), Color("1e1c1a")]
	var hoods := [Color("4a4642"), Color("5c5650"), Color("3a3634")]
	_var = [skins[r.randi() % skins.size()], baleens[r.randi() % baleens.size()], hoods[r.randi() % hoods.size()], r.randf() < 0.5]
	for i in 2:
		var b := WingBody.new()
		b.owner_t = self
		b.idx = i
		b.collision_layer = 4
		b.collision_mask = 0
		var cs := CollisionShape2D.new()
		var cc := CircleShape2D.new()
		cc.radius = 17.0 * z.sc
		cs.shape = cc
		b.add_child(cs)
		z.add_child(b)
		_bodies.append(b)


func _init_state() -> void:
	if z.has_meta("sk_fly"):
		state = SOAR
		_t = randf_range(SOAR_T.x, SOAR_T.y) + 0.6
		z.collision_mask = 1
		_spread = 1.0
		var pl := player() as Node2D
		_side = signf(z.global_position.x - pl.global_position.x) if pl != null else 1.0
		if _side == 0.0:
			_side = 1.0
	elif z.global_position.y < _floor() - 40.0:
		state = PERCH
		_spread = 0.0
	else:
		_takeoff()
	_shape_for_state()


func _shape_for_state() -> void:
	var rs := z._shape.shape as RectangleShape2D
	if state == PERCH:
		rs.size = Vector2(22.0 * z.sc, 46.0 * z.sc)
		z._shape.position = Vector2(0.0, -23.0 * z.sc)
	else:   # באוויר: רק הגוף הקטן (הכנפיים הן גופים נפרדים)
		rs.size = Vector2(30.0 * z.sc, 20.0 * z.sc)
		z._shape.position = Vector2(0.0, PIVOT.y * z.sc)


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
	var has: bool = pl != null and not pl.dead
	var d: Vector2 = (pl.global_position - z.global_position) if has else Vector2(9999, 0)
	_wing_fire_tick(delta)
	_gy_t -= delta
	if _gy_t <= 0.0:
		_gy_t = 0.15
		_gy = _ground_under()
	var fl := _floor()
	match state:
		PERCH:
			if not z.is_on_floor():
				z.velocity.y += z.gravity * delta
			z.velocity.x = move_toward(z.velocity.x, 0.0, 600.0 * delta)
			_spread = move_toward(_spread, 0.0, delta * 2.0)
			_ang = 0.0
			if has:
				z._dir = signf(d.x) if absf(d.x) > 4.0 else z._dir
				if absf(d.x) < PERCH_R:
					_takeoff()
					z.velocity = Vector2(signf(d.x) * 120.0, -260.0)
		TAKEOFF:
			_spread = move_toward(_spread, 1.0, delta * 4.0)
			_flap_v = 14.0
			var ty := fl - SOAR_H.x
			z.velocity.y = move_toward(z.velocity.y, -CLIMB_V if z.global_position.y > ty else 0.0, 900.0 * delta)
			z.velocity.x = move_toward(z.velocity.x, _side * 120.0, 300.0 * delta)
			_ang = lerpf(_ang, -0.5, clampf(delta * 6.0, 0.0, 1.0))
			if z.global_position.y < ty + 20.0 or _t <= 0.0:
				state = SOAR
				_t = randf_range(SOAR_T.x, SOAR_T.y)
		SOAR:
			_soar(pl, has, d, delta, fl)
		STOOP_W:
			_spread = move_toward(_spread, 0.15, delta * 4.0)
			_flap_v = 0.0
			z.velocity = z.velocity.move_toward(Vector2(0.0, -30.0), 900.0 * delta)
			if has:
				_target = _target.lerp(pl.global_position + Vector2(0, -26) + pl.velocity * 0.12, clampf(delta * 4.0, 0.0, 1.0))
				_target.y = minf(_target.y, fl - 14.0)
				z._dir = signf(_target.x - z.global_position.x) if absf(_target.x - z.global_position.x) > 4.0 else z._dir
			var to := _target - _center()
			_ang = lerp_angle(_ang, _dive_angle(to), clampf(delta * 8.0, 0.0, 1.0))
			if _t <= 0.0:
				state = STOOP
				_t = STOOP_MAX
				_hit = false
				stoops += 1
				if stoops == 1:
					Game.story.emit("flyer", {"z": z})   # ui/monologue.gd: "flyer"
				_dove = true
				_feint_plan = learned() and not _feinted and randf() < FEINT_CHANCE
				z.velocity = to.normalized() * STOOP_V * 0.6
				Sfx.play("sk_dive", z.global_position, 0.0, 0.1, 2)
		STOOP:
			_spread = move_toward(_spread, 0.0, delta * 5.0)
			if has:   # מתקן קצת (לא טיל)
				_target = _target.lerp(pl.global_position + Vector2(0, -26), clampf(delta * 1.2, 0.0, 1.0))
				_target.y = minf(_target.y, fl - 14.0)
			var to2 := _target - _center()
			if to2.length() > 30.0:
				z.velocity = z.velocity.move_toward(to2.normalized() * STOOP_V, 2400.0 * delta)
			z._dir = signf(z.velocity.x) if absf(z.velocity.x) > 10.0 else z._dir
			_ang = lerp_angle(_ang, _dive_angle(z.velocity), clampf(delta * 10.0, 0.0, 1.0))
			_check_rake(pl, has)
			if _feint_plan and to2.length() < FEINT_R and not _hit:
				_feint(pl)
			elif _t <= 0.0 or z.is_on_floor() or z.global_position.y > fl - 10.0 or (to2.dot(z.velocity) < 0.0 and to2.length() > 26.0) or _hit:
				_climb()
		FEINT:
			_spread = move_toward(_spread, 1.0, delta * 6.0)
			_flap_v = 16.0
			z.velocity = z.velocity.move_toward(Vector2(_side * 320.0, -380.0), 1800.0 * delta)
			z._dir = signf(z.velocity.x) if absf(z.velocity.x) > 10.0 else z._dir
			_ang = lerp_angle(_ang, -0.7, clampf(delta * 8.0, 0.0, 1.0))
			if _t <= 0.0:   # עכשיו מהצד השני - צלילה קצרה ומהירה
				state = STOOP_W
				_t = FEINT_WIND
				if has:
					_target = pl.global_position + Vector2(0, -26) + pl.velocity * 0.1
		CLIMB:
			_spread = move_toward(_spread, 1.0, delta * 5.0)
			_flap_v = 15.0
			z.velocity = z.velocity.move_toward(Vector2(z._dir * 200.0, -CLIMB_V), 1100.0 * delta)
			_ang = lerp_angle(_ang, -0.55, clampf(delta * 6.0, 0.0, 1.0))
			if _t <= 0.0 or z.global_position.y < fl - SOAR_H.y:
				state = SOAR
				_t = randf_range(SOAR_T.x, SOAR_T.y)
				if has:
					_side = signf(z.global_position.x - pl.global_position.x) if absf(d.x) > 20.0 else -_side
		SPIRAL:
			_spin += delta * 9.0
			_spread = move_toward(_spread, 0.6, delta)
			_flap_v = 18.0
			var bs := 1.0 if _broken == 0 else -1.0
			z.velocity.x = move_toward(z.velocity.x, cos(_spin) * 200.0 + bs * z._dir * 60.0, 900.0 * delta)
			z.velocity.y = move_toward(z.velocity.y, 380.0, 500.0 * delta)
			_ang = sin(_spin) * 1.2 + bs * 0.5
			if Engine.get_physics_frames() % 6 == 0 and Art.on_screen(z, z.global_position):
				var dbr = DebrisScript.new()
				_main().add_child(dbr)
				dbr.setup(_wpos(_broken), Vector2(randf_range(2, 5), randf_range(4, 8)), _var[1] if randf() < 0.5 else _var[0], Vector2(randf_range(-90, 90), -randf_range(30, 120)))
			if z.is_on_floor() or z.is_on_wall() or z.global_position.y > _gy - 4.0:
				_crash()
				return true
	_flap_tick(delta)
	_wings_update()
	z.move_and_slide()
	if state != PERCH:
		var gx: float = z.global_position.x
		if gx < 40.0 or gx > z.world_w - 40.0:
			z.global_position.x = clampf(gx, 40.0, z.world_w - 40.0)
			z.velocity.x = -z.velocity.x * 0.5
		if z.global_position.y < fl - 460.0:
			z.velocity.y = maxf(z.velocity.y, 60.0)
	return true


func _soar(pl: Node, has: bool, d: Vector2, delta: float, fl: float) -> void:
	_spread = move_toward(_spread, 1.0, delta * 3.0)
	var tt: float = z._time
	if has and absf(d.x) > 1600.0:   # נשאר הרחק מאחור: עף לים (לא נערמות סקואות מאחוריך)
		z.queue_free()
		return
	var px: float = pl.global_position.x if has else z.global_position.x
	var h := lerpf(SOAR_H.x, SOAR_H.y, 0.5 + 0.5 * sin(tt * 0.8 + float(z.get_instance_id() % 13)))
	var tgt := Vector2(px + _side * SOAR_OFF + sin(tt * 0.9) * 70.0, fl - h + sin(tt * 1.7) * 16.0)
	var want: Vector2 = (tgt - z.global_position) * 2.0
	if want.length() > SOAR_V:
		want = want.normalized() * SOAR_V
	z.velocity = z.velocity.move_toward(want, 520.0 * delta)
	if absf(z.velocity.x) > 40.0:
		z._dir = signf(z.velocity.x)
	elif has:
		z._dir = signf(d.x) if absf(d.x) > 4.0 else z._dir
	_ang = lerp_angle(_ang, clampf(z.velocity.y / 600.0, -0.4, 0.4) + sin(tt * 1.3) * 0.06, clampf(delta * 4.0, 0.0, 1.0))
	_flap_v = 3.0 if z.velocity.y < -60.0 else 1.2
	if not has:
		return
	if _t <= 0.0 and absf(d.x) < 520.0 and d.y > 60.0:
		_start_stoop(pl)


func _start_stoop(pl: Node) -> void:
	state = STOOP_W
	_t = STOOP_WIND
	_target = pl.global_position + Vector2(0, -26) + pl.velocity * 0.15
	Sfx.play("sk_screech", z.global_position, 1.0, 0.1, 2)


func _feint(pl: Node) -> void:
	state = FEINT
	feints += 1
	_feinted = true
	_feint_plan = false
	_t = 0.38
	if pl != null:
		_side = signf(pl.global_position.x - z.global_position.x) if absf(pl.global_position.x - z.global_position.x) > 10.0 else _side
	Sfx.play("sk_flap", z.global_position, 2.0, 0.1, 2)
	var m := _main()
	if m != null and not m.has_meta("sk_feint_said"):
		m.set_meta("sk_feint_said", true)
		z._popup("THEY FEINT THE DIVE NOW", Color("ff8a7a"), 14, -110.0)
		if pl != null and pl.has_method("_say"):
			pl._say("It pulled up - wait for the second dive!", Color("ff8a7a"))


func _climb() -> void:
	state = CLIMB
	climbs += 1
	_t = CLIMB_T
	_feinted = false
	if absf(z.velocity.x) > 20.0:
		z._dir = signf(z.velocity.x)
	z.velocity.y = minf(z.velocity.y, 0.0) - 120.0
	Sfx.play("sk_flap", z.global_position, 0.0, 0.1, 2)


func _takeoff() -> void:
	state = TAKEOFF
	takeoffs += 1
	_t = 1.2
	z.collision_mask = 1
	var pl := player() as Node2D
	_side = signf(z.global_position.x - pl.global_position.x) if pl != null else 1.0
	if _side == 0.0:
		_side = 1.0
	_shape_for_state()
	Sfx.play("sk_flap", z.global_position, 0.0, 0.1, 2)
	if Art.on_screen(z, z.global_position):
		Particles.burst(_main(), z.global_position + Vector2(0, -6), "smoke", Vector2(0, -1), 3)


func _check_rake(pl: Node, has: bool) -> void:
	if _hit or not has:
		return
	var c := _center()
	var me := Rect2(c - Vector2(18.0, 16.0) * z.sc, Vector2(36.0, 32.0) * z.sc)
	if me.intersects(pl.body_rect()):
		_hit = true
		if pl._roll_t <= 0.0:
			rakes += 1
			z._spray_blood(pl.global_position + Vector2(0, -34), Vector2(signf(z.velocity.x + 0.01), -0.5), 6, 240.0)
		pl.hurt(RAKE_DMG, Vector2(signf(z.velocity.x + 0.01) * 1.2, -0.4))
		Sfx.play("sk_rake", z.global_position, 2.0, 0.1, 2)


func _center() -> Vector2:
	return z.global_position + PIVOT * z.sc


func _dive_angle(v: Vector2) -> float:
	# זווית הגוף בצלילה: הראש לכיוון התנועה (מצויר פונה ימינה, משוקף לפי _dir)
	if v.length() < 1.0:
		return 0.0
	var a := atan2(v.y, absf(v.x))
	return clampf(a, -1.2, 1.35)


func _flap_tick(delta: float) -> void:
	_flap += delta * _flap_v
	_flap_snd -= delta
	if _flap_v > 8.0 and _flap_snd <= 0.0 and Art.on_screen(z, z.global_position):
		_flap_snd = 0.32
		Sfx.play("sk_flap", z.global_position, -6.0, 0.15, 2)


# ============================================================
#  הכנפיים: מיקום הגופים, פגיעות, קריעה, אש
# ============================================================
# זוויות היד-כנף (ביחידות ציור, פונה ימינה) לפי פריסה + משק
func _wing_ang(i: int) -> float:
	var flap := sin(_flap) * 0.55 * _spread
	var open_a := -1.25 if i == 0 else -1.95
	return lerpf(-2.95 if i == 0 else -3.05, open_a, _spread) + flap


func _shoulder(i: int) -> Vector2:
	return Vector2(7.0, -35.0) if i == 0 else Vector2(3.0, -36.0)


# מרכז הכנף בעולם
func _wpos(i: int) -> Vector2:
	var a := _wing_ang(i)
	var local := _shoulder(i) - PIVOT + Vector2(cos(a), sin(a)) * 24.0
	local = local.rotated(_ang)
	local.x *= z._dir
	return _center() + local * z.sc


func _wings_update() -> void:
	for i in 2:
		var b: StaticBody2D = _bodies[i]
		var live: bool = int(_wing_hp[i]) > 0 and _spread > 0.5 and state != PERCH and state != SPIRAL
		b.collision_layer = 4 if live else 0
		if live:
			b.global_position = _wpos(i)


func wing_hit(i: int, p: Vector2, d: Vector2, src: Dictionary) -> void:
	if z.dead or int(_wing_hp[i]) <= 0:
		return
	var dmg := 10
	if src.has("fixed"):
		dmg = int(src.fixed)
	elif src.has("dmg_mult"):
		dmg = maxi(4, int(round(10.0 * float(src.dmg_mult))))
	if src.get("sniper", false):
		dmg *= 2
	if src.get("god", false):
		dmg *= 4
	wing_hits += 1
	z._flash = 0.05
	Game.on_zombie_hit({"source": "bullet", "zone": "wing", "shot": src.get("shot", 0)})
	Sfx.play("sk_rip", p, -6.0, 0.2, 3)
	if Art.on_screen(z, p):
		for k in Quality.scaled(3, 1.0):
			var dbr = DebrisScript.new()
			_main().add_child(dbr)
			dbr.setup(p, Vector2(randf_range(2, 4), randf_range(4, 8)), _var[1] if k % 2 == 0 else _var[0], Vector2(d.x * randf_range(60, 180), -randf_range(40, 180)))
		Particles.burst(_main(), p, "hit", d, 4)
	if src.get("incendiary", false):
		_ignite(i)
		return
	_wing_hp[i] = int(_wing_hp[i]) - dmg
	if int(_wing_hp[i]) <= 0:
		_rip(i, d)


func _ignite(i: int) -> void:
	if float(_wfire[i]) > 0.0:
		return
	burns += 1
	_wfire[i] = 0.6
	z._popup("WING ON FIRE", Color("ff9a3a"), 13, -100.0)


func _wing_fire_tick(delta: float) -> void:
	for i in 2:
		if float(_wfire[i]) <= 0.0:
			continue
		_wfire[i] = float(_wfire[i]) - delta
		if Engine.get_physics_frames() % 3 == 0 and Art.on_screen(z, z.global_position):
			var c := _wpos(i)
			Particles.burst(_main(), c, "fire", Vector2(0, -1), 2)
			Particles.burst(_main(), c, "smoke", Vector2(0, -1), 1)
		if float(_wfire[i]) <= 0.0 and int(_wing_hp[i]) > 0:
			_rip(i, Vector2.UP)


func _rip(i: int, d: Vector2) -> void:
	_wing_hp[i] = 0
	if _broken >= 0 or state == PERCH:   # כבר נופל / יושב: רק הכנף
		_broken = i if _broken < 0 else _broken
		return
	_broken = i
	rips += 1
	state = SPIRAL
	_spin = 0.0
	_count_down()
	Sfx.play("sk_rip", z.global_position, 3.0, 0.0, 2)
	Sfx.play("sk_screech", z.global_position, 0.0, 0.1, 2, 0.8)
	var m := _main()
	if int(m.get_meta("sk_rip_pop", 0)) < 3:
		m.set_meta("sk_rip_pop", int(m.get_meta("sk_rip_pop", 0)) + 1)
		z._popup("WING!", Color("ffd34a"), 16, -110.0)
	if Art.on_screen(z, z.global_position):
		var at := _wpos(i)
		for k in Quality.scaled(7, 1.0):
			var dbr = DebrisScript.new()
			m.add_child(dbr)
			dbr.setup(at + Vector2(randf_range(-12, 12), randf_range(-12, 12)), Vector2(randf_range(2, 5), randf_range(5, 10)), _var[1] if k % 2 == 0 else _var[0], Vector2(d.x * randf_range(40, 160) + randf_range(-80, 80), -randf_range(60, 240)))
		Particles.burst(m, at, "hit", d, int(8.0 * Quality.gore()) + 2)


# הופל: הספירה ל-"THEY FEINT THE DIVE NOW"
func _count_down() -> void:
	var m := _main()
	if m == null or z.has_meta("sk_counted"):
		return
	z.set_meta("sk_counted", true)
	m.set_meta("sk_downs", int(m.get_meta("sk_downs", 0)) + 1)


func _crash() -> void:
	crashes += 1
	var m := _main()
	Sfx.play("sk_crash", z.global_position, 4.0, 0.08, 2)
	if Art.on_screen(z, z.global_position):
		Particles.burst(m, z.global_position + Vector2(0, -4), "smoke", Vector2.UP, Quality.scaled(10, 1.0))
		for k in Quality.scaled(6, Quality.gore()):
			var dbr = DebrisScript.new()
			m.add_child(dbr)
			dbr.setup(z.global_position + Vector2(randf_range(-10, 10), -6), Vector2(randf_range(2, 5), randf_range(2, 6)), _var[1] if k % 2 == 0 else Decor.BONE_D, Vector2(randf_range(-220, 220), -randf_range(120, 300)))
		var cam: Camera2D = z.get_viewport().get_camera_2d()
		if cam != null and cam.has_method("shake"):
			cam.shake(6.0, 0.22)
	if int(m.get_meta("sk_crash_pop", 0)) < 3:
		m.set_meta("sk_crash_pop", int(m.get_meta("sk_crash_pop", 0)) + 1)
		z._popup("GROUNDED!", Color("ffd34a"), 16, -70.0)
	z.collision_mask = 1 | 16
	z._spray_blood(z.global_position + Vector2(0, -16), Vector2(signf(z.velocity.x + 0.01), -0.8), 16, 400.0)
	z.velocity = Vector2(z.velocity.x * 0.5, -140.0)
	z.take_damage(CRASH_DMG, z.global_position + Vector2(0, -26.0 * z.sc), Vector2(signf(z.velocity.x + 0.01), -0.4), false, {"source": "crash", "fixed": CRASH_DMG, "knockback": 200.0})


func on_damage(_amount: int, _hit_pos: Vector2, _dir: Vector2, src: Dictionary) -> bool:
	if z.dead:
		return true
	var airborne := state != PERCH and state != SPIRAL
	if src.has("blast") and airborne:   # פיצוץ קורע את שתי הכנפיים
		for i in 2:
			if int(_wing_hp[i]) > 0:
				_wing_hp[i] = 0
		_rip(0, Vector2.UP)
	elif src.get("incendiary", false) and airborne:
		_ignite(0 if randf() < 0.5 else 1)
	return true


func on_death() -> void:
	for b in _bodies:
		if is_instance_valid(b):
			b.collision_layer = 0
	z.collision_mask = 1 | 16
	if state != PERCH and state != SPIRAL:
		_count_down()
	if Art.on_screen(z, z.global_position):
		for k in Quality.scaled(4, 1.0):
			var dbr = DebrisScript.new()
			_main().add_child(dbr)
			dbr.setup(_center(), Vector2(randf_range(2, 4), randf_range(5, 9)), _var[1], Vector2(randf_range(-140, 140), -randf_range(60, 200)))


func _ground_under() -> float:
	var from: Vector2 = z.global_position + Vector2(0, -4)
	var q := PhysicsRayQueryParameters2D.create(from, from + Vector2(0, 900), 17)
	q.exclude = [z.get_rid()]
	var hit: Dictionary = z.get_world_2d().direct_space_state.intersect_ray(q)
	return float(hit.position.y) if hit else _floor()


# ============================================================
#  ציור: גוף אופקי עם כנפי מזיפות + עור כלב ים תפור, ברדס, מקור משן לווייתן. הכל מסתובב סביב מרכז הגוף (PIVOT)
# ============================================================
func wants_redraw() -> bool:
	return true


func draw() -> bool:
	if _var.is_empty():
		return false
	if z.dead:
		begin_draw()
		_draw_body(0.0, true)
		end_draw()
		return true
	var flying := state != PERCH
	if flying:   # צל על הקרקע (הרמז)
		var hgt: float = maxf(0.0, _gy - z.global_position.y)
		var a := clampf(1.0 - hgt / 480.0, 0.15, 0.6)
		DrawBatch.colored_polygon(z, Art.ellipse(Vector2(0, hgt), 16.0 * (0.6 + hgt / 600.0) * (0.5 + 0.5 * _spread), 3.5, 0.0, 12), Color(0.08, 0.06, 0.04, a * 0.5))
	var s := Vector2(z._dir * z.wf * z.sc, z.sc)
	var piv := PIVOT
	var ang := _ang
	var lift := 0.0
	if not flying:
		ang = -1.25
		piv = Vector2(0.0, -26.0)
		lift = 6.0
	# סיבוב סביב מרכז הגוף לפני השיקוף (הזווית תמיד "פונה ימינה")
	DrawBatch.set_transform_matrix(z, Transform2D(0.0, s, 0.0, Vector2.ZERO) * Transform2D(ang, piv + Vector2(0.0, lift)) * Transform2D(0.0, -piv))
	_draw_body(_spread, false)
	if not z.dead and state == STOOP_W:
		var k := clampf(_t / STOOP_WIND, 0.0, 1.0)
		DrawBatch.string(z, ThemeDB.fallback_font, Vector2(14, -50), "!", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(1.0, 0.35, 0.2, k))
	end_draw()
	return true


func _draw_body(spread: float, dead: bool) -> void:
	var skin := col(z.skin)
	var hood := col(_var[2])
	var seal := col(_var[0])
	var tt: float = z._time
	# כנף רחוקה (מאחור)
	_wing(1, spread, dead, seal)
	# רגליים מקופלות מאחור (טפרים)
	var hip := Vector2(-8.0, -29.0)
	var kick := sin(tt * 3.0) * 1.5 if state == SOAR else 0.0
	for i in 2:
		var kn := hip + Vector2(-6.0, 3.0 + float(i) * 2.0)
		var ft := hip + Vector2(-15.0 + kick * float(i), -1.0 + float(i) * 4.0)
		if state == STOOP or state == STOOP_W:   # טפרים קדימה לשריטה
			ft = hip + Vector2(4.0 + float(i) * 3.0, 9.0)
			kn = hip + Vector2(-2.0, 6.0)
		Art.limb(z, PackedVector2Array([hip, kn, ft]), 3.4, col(Art.shade(z.pants, 0.15 if i == 0 else 0.0)))
		for q in 3:   # ציפורניים
			DrawBatch.line(z, ft, ft + Vector2(2.0 + float(q), 1.5 - float(q) * 1.5), col(Color("2a2420")), 0.9)
	# גוף: עור כלב ים עם תפרים
	var body := PackedVector2Array([Vector2(9.0, -38.5), Vector2(12.0, -33.0), Vector2(4.0, -25.0), Vector2(-10.0, -25.5), Vector2(-12.0, -31.0), Vector2(-6.0, -37.5)])
	Art.fill_shaded(z, body, seal, 0.12, 0.28)
	for q in 4:
		var p0 := Vector2(-7.0 + float(q) * 4.0, -36.5 + float(q % 2))
		DrawBatch.line(z, p0, p0 + Vector2(0.6, 1.8), col(Color("c8c0a8")), 0.6)
	Art.oval(z, Vector2(2.0, -28.0), 4.0, 1.6, Color(0.42, 0.06, 0.05, 0.75), 0.1, Art.NONE)
	# ראש + ברדס + מקור משן לווייתן
	var head := Vector2(15.0, -38.0)
	Art.oval_shaded(z, head, 5.5, 5.0, hood, 0.0)
	Art.oval(z, head + Vector2(2.0, 1.0), 3.4, 3.4, skin, 0.0, Art.NONE)
	DrawBatch.colored_polygon(z, PackedVector2Array([head + Vector2(3.5, -1.5), head + Vector2(11.0, 0.0), head + Vector2(12.0, 3.5), head + Vector2(9.5, 2.0), head + Vector2(4.0, 2.0)]), col(Decor.BONE))
	DrawBatch.line(z, head + Vector2(4.0, 0.6), head + Vector2(11.0, 1.0), col(Decor.BONE_S), 0.6)
	DrawBatch.line(z, head + Vector2(-1.0, -2.0), head + Vector2(5.0, 0.5), col(Color("3a2c22")), 0.9)   # רצועה
	if _var[3]:
		DrawBatch.line(z, head + Vector2(1.0, 2.0), head + Vector2(3.0, 4.0), Color(0.45, 0.05, 0.05, 0.8), 0.8)
	if not dead:
		var ec := Color(1.0, 0.3, 0.15)
		if z.has_meta("s57_learned_t"):
			ec = ec.lerp(Color(0.6, 1.0, 0.75), clampf(1.0 - float(Time.get_ticks_msec() - int(z.get_meta("s57_learned_t"))) / 600.0, 0.0, 1.0))
		DrawBatch.circle(z, head + Vector2(3.0, -0.8), 0.95, ec)
		Art.glow(z, head + Vector2(3.0, -0.8), 3.5 + (2.0 if state == STOOP_W or state == STOOP else 0.0), Color(ec, 0.4))
		if state == STOOP_W or state == STOOP:   # פה פתוח בצווחה
			DrawBatch.colored_polygon(z, PackedVector2Array([head + Vector2(3.0, 2.2), head + Vector2(7.0, 2.6), head + Vector2(5.0, 4.4)]), col(Color("2a0608")))
	# כנף קרובה (מלפנים)
	_wing(0, spread, dead, seal)


# כנף: עצם יד (לוח מזיפות על האמה) + מניפת מזיפות + קרום עור תפור. נקרעה = גדם עם רצועות
func _wing(i: int, spread: float, dead: bool, seal: Color) -> void:
	var sh := _shoulder(i)
	var a := _wing_ang(i) if not dead else (-2.9 if i == 0 else -3.0)
	var dv := Vector2(cos(a), sin(a))
	var elbow := sh + dv * 15.0 + Vector2(-dv.y, dv.x) * -2.0
	var a2 := a + (0.3 if i == 0 else 0.2) * spread
	var wrist := elbow + Vector2(cos(a2), sin(a2)) * 18.0
	var shade_k := 0.08 if i == 0 else -0.2
	var bal := col(Art.shade(_var[1], shade_k * 0.5))
	var skin_c := col(Art.shade(seal, shade_k))
	var skin_d := col(Art.shade(seal, shade_k - 0.2))
	var arm_c := col(Art.shade(z.skin, shade_k))
	var hip := Vector2(-9.0, -28.0)
	var tt: float = z._time
	if int(_wing_hp[i]) <= 0:   # נקרעה: גדם עם רצועות עור ודם
		Art.limb(z, PackedVector2Array([sh, elbow]), 2.8, arm_c)
		for q in 3:
			var e := elbow + Vector2(-6.0 - float(q) * 3.0, 4.0 + sin(tt * 14.0 + float(q)) * 3.0)
			DrawBatch.line(z, elbow, e, skin_c if q != 1 else bal, 1.6)
		DrawBatch.circle(z, elbow, 1.8, Color(0.5, 0.05, 0.05, 0.9))
		return
	# מזיפות (נוצות ראשוניות): מניפה מהשורש אחורה אל הזנב
	var tips := []
	var fan := 0.32 * (0.45 + 0.55 * spread)
	for q in 5:
		var fa := a2 - float(q) * fan
		var ln := (30.0 - float(q) * 2.8) * (0.75 + 0.25 * spread)
		tips.append(wrist + Vector2(cos(fa), sin(fa)) * ln)
	# קרום עור כלב ים: משולשים (כתף-מרפק-ירך, מרפק-שורש-ירך, בין המזיפות, הקצה האחרון-ירך)
	DrawBatch.colored_polygon(z, PackedVector2Array([sh, elbow, hip]), skin_c)
	DrawBatch.colored_polygon(z, PackedVector2Array([elbow, wrist, hip]), skin_c)
	for q in 4:
		DrawBatch.colored_polygon(z, PackedVector2Array([wrist, tips[q], tips[q + 1]]), skin_c if q % 2 == 0 else skin_d)
	DrawBatch.colored_polygon(z, PackedVector2Array([wrist, tips[4], hip]), skin_d)
	# שפה אחורית משוננת + תפרים
	var mid: Vector2 = tips[4].lerp(hip, 0.5) + (tips[4] - hip).orthogonal().normalized() * -2.5
	DrawBatch.polyline(z, PackedVector2Array([tips[4], mid, hip]), col(Art.shade(seal, -0.4)), 1.0)
	for q in 3:
		var m0: Vector2 = elbow.lerp(hip, 0.25 + float(q) * 0.22)
		var m1: Vector2 = wrist.lerp(tips[3], 0.35).lerp(hip, 0.25 + float(q) * 0.22)
		DrawBatch.line(z, m0, m1, col(Color(0.82, 0.78, 0.66, 0.75)), 0.55)
		var mm := m0.lerp(m1, 0.5)
		DrawBatch.line(z, mm + Vector2(-0.8, -0.8), mm + Vector2(0.8, 0.8), col(Color(0.82, 0.78, 0.66, 0.75)), 0.5)
	# לוחות המזיפות: שחורים, עם שוליים סיביים בהירים
	for q in tips.size():
		var tp: Vector2 = tips[q]
		var dd := (tp - wrist).normalized()
		DrawBatch.line(z, wrist, tp, bal, 2.8 - float(q) * 0.3)
		DrawBatch.line(z, tp - dd * 4.0, tp + dd * 2.0 + dd.orthogonal() * 1.2, col(Color(0.62, 0.56, 0.46)), 0.8)
	# עצם היד (מלפנים)
	Art.limb(z, PackedVector2Array([sh, elbow, wrist]), 2.8, arm_c)
	DrawBatch.circle(z, wrist, 1.6, col(Decor.BONE_D))
	DrawBatch.line(z, sh.lerp(elbow, 0.5), sh.lerp(elbow, 0.5) + Vector2(-1.0, 2.0), col(Color("5a4a36")), 1.0)   # חבל קשירה
	if float(_wfire[i]) > 0.0:
		Art.glow(z, elbow.lerp(wrist, 0.5), 9.0, Color(1.0, 0.5, 0.1, 0.55))
