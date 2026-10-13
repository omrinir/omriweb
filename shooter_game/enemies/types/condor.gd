extends "res://enemies/zombie_type.gd"
# ============================================================
#  CONDOR (שלב 28, "CLOUD PASS") - קונדור אנדים זומבי: כנפיים שחורות ענקיות, צווארון לבן, ראש קירח אדמדם, נוצות נושרות.
#    CIRCLE - חג גבוה מעליך (ALT), נע מצד לצד.
#    MARK   - צווחה + צל מסומן על הקרקע מתחתיך (MARK_T) = אזהרה. הצל לא זז אחריך.
#    DIVE   - צולל לנקודה המסומנת (DIVE_V). פגיעה = DAMAGE.
#    GROUND - אחרי הצלילה הוא על הקרקע ומנפנף (GROUND_T) - פגיע (x GROUND_MULT). ואז חוזר לשמיים.
#  באוויר קשה לפגוע בו (x AIR_MULT). התחמקות: לזוז מהצל.
#  בוס: APU KUNTUR - ענק, צולל פעמיים ברצף.
#  לשנות: ALT, MARK_T, DIVE_V, GROUND_T, AIR_MULT, GROUND_MULT.
# ============================================================

const SOUNDS := {
	"cd_screech": [["S", 2400, 1500, 0.0, 0.45, 0.02, 3.0, 0.3, 1.0, 0.12], ["N", 0, 0, 0.0, 0.4, 0.02, 4.0, 0.25, 0.6, 0, 0.3]],
	"cd_flap": [["N", 0, 0, 0.0, 0.12, 0.02, 18.0, 0.4, 0.2, 0]],
}

const ALT := 300.0
const MARK_T := 0.75
const DIVE_V := 760.0
const GROUND_T := 1.3
const AIR_MULT := 0.6
const GROUND_MULT := 1.5
const DAMAGE := 2
const CD := Vector2(1.6, 2.6)

enum { CIRCLE, MARK, DIVE, GROUND, RISE }
var state := CIRCLE
var dives := 0               # לבדיקות
var hits := 0
var _st := 0.0
var _cd := 2.0
var _phase := 0.0
var _mark := Vector2.ZERO
var _floor := 0.0
var _hit := false
var _flap := 0.0
var _chain := 0


func _boss() -> bool:
	return z != null and float(z.chase_range) > 600.0


func stats() -> Dictionary:
	if _boss():
		return {"name": "CONDOR", "hp": 360, "walk": 60.0, "chase": 110.0, "damage": 2, "bite_delay": 0.9, "scale": 1.7, "width": 1.0,
			"duck": 0.0, "cover": 0.0, "skin": Color("b06a5a"), "shirt": Color("1a1a1e"), "pants": Color("1a1a1e"), "shoe": Color("4a4a40"),
			"points": 1200, "boss": true, "boss_name": "APU KUNTUR - WATCH THE SHADOW"}
	return {"name": "CONDOR", "hp": 30, "walk": 60.0, "chase": 110.0, "damage": 1, "bite_delay": 0.8, "scale": 1.0, "width": 1.0,
		"duck": 0.0, "cover": 0.0, "skin": Color("b06a5a"), "shirt": Color("1a1a1e"), "pants": Color("1a1a1e"), "shoe": Color("4a4a40"), "points": 450}


func setup() -> void:
	_floor = z.global_position.y
	z.global_position.y = _floor - ALT * (0.6 if _boss() else 1.0)
	_phase = randf() * TAU
	z.dormant = false


func in_air() -> bool:   # (הרוח לא דוחפת אותו - effects/s28_decor.gd)
	return state != GROUND


func can_bite() -> bool:
	return state == GROUND


func can_groan() -> bool:
	return false


func damage_mult(_zone: String, _src: Dictionary) -> float:
	if state == GROUND:
		return GROUND_MULT
	return AIR_MULT if state != DIVE else 1.0


func death_sound() -> String:
	return "cd_screech"


func physics(pl: Node, delta: float) -> bool:
	_cd -= delta
	_st -= delta
	_phase += delta
	if z.dead:
		return false
	var has_pl: bool = pl != null and not pl.dead
	var alt: float = ALT * (0.6 if _boss() else 1.0)
	match state:
		CIRCLE, RISE:
			var cx: float = pl.global_position.x if has_pl else z.global_position.x
			var tx := cx + sin(_phase * 0.7) * 260.0
			var ty := _floor - alt + sin(_phase * 1.3) * 22.0
			if state == RISE:
				ty = _floor - alt
			var to := Vector2(tx, ty)
			var step: Vector2 = (to - z.global_position).limit_length((180.0 if state == CIRCLE else 260.0) * delta)
			z.global_position += step
			z._dir = signf(step.x) if absf(step.x) > 0.2 else z._dir
			_wing_sound(delta, 0.5)
			if state == RISE and z.global_position.distance_to(to) < 20.0:
				state = CIRCLE
			if state == CIRCLE and has_pl and _cd <= 0.0 and absf(pl.global_position.x - z.global_position.x) < 420.0:
				_start_mark(pl)
			return true
		MARK:
			z.global_position.y += sin(_phase * 8.0) * 0.3
			z._dir = signf(_mark.x - z.global_position.x) if absf(_mark.x - z.global_position.x) > 4.0 else z._dir
			if _st <= 0.0:
				state = DIVE
				_hit = false
				dives += 1
				Sfx.play("cd_flap", z.global_position, 4.0, 0.1, 2)
			return true
		DIVE:
			var d: Vector2 = _mark - z.global_position
			var step: Vector2 = d.limit_length(DIVE_V * delta)
			z.global_position += step
			z._dir = signf(d.x) if absf(d.x) > 2.0 else z._dir
			if has_pl and not _hit and z.global_position.distance_to(_mark) < 80.0 * z.sc:   # פוגע רק ליד הצל
				var r: Rect2 = pl.body_rect().grow(6.0 * z.sc)
				if r.has_point(z.global_position + Vector2(0, -10.0 * z.sc)):
					_hit = true
					hits += 1
					pl.hurt(DAMAGE + (1 if _boss() else 0), Vector2(signf(d.x if d.x != 0.0 else 1.0) * 1.8, -1.0))
			if d.length() < 6.0:
				z.global_position = _mark
				Particles.burst(z.get_parent(), _mark, "smoke", Vector2.UP, 8)
				Sfx.play("land", _mark, 2.0)
				if _boss() and _chain < 1 and has_pl:   # בוס: צלילה שנייה מיד
					_chain += 1
					z.global_position.y -= 6.0
					_start_mark(pl, 0.45)
				else:
					_chain = 0
					state = GROUND
					_st = GROUND_T
					z.velocity = Vector2.ZERO
			return true
		GROUND:
			z.velocity.x = move_toward(z.velocity.x, 0.0, 600.0 * delta)
			if not z.is_on_floor():
				z.velocity.y += z.gravity * delta
			z.move_and_slide()
			_wing_sound(delta, 0.25)
			if _st <= 0.0:
				state = RISE
				_cd = randf_range(CD.x, CD.y)
				_floor = z.global_position.y
			return true
	return true


func _start_mark(pl: Node, t := MARK_T) -> void:
	state = MARK
	_st = t
	var top: Vector2 = pl.global_position + Vector2(0, -40)
	var hit: Dictionary = z.get_world_2d().direct_space_state.intersect_ray(PhysicsRayQueryParameters2D.create(top, top + Vector2(0, 600), 1 | 16))
	_mark = hit.position if hit else pl.global_position
	_floor = _mark.y
	Sfx.play("cd_screech", z.global_position, 2.0, 0.1, 2)
	var sh := Shadow.new()
	sh.life = t + 0.25
	sh.r = 30.0 * z.sc
	z.get_parent().add_child(sh)
	sh.global_position = _mark


func _wing_sound(delta: float, every: float) -> void:
	_flap -= delta
	if _flap <= 0.0:
		_flap = every
		if Art.on_screen(z, z.global_position):
			Sfx.play("cd_flap", z.global_position, -8.0, 0.15, 2)


# ============================================================
#  ציור: גוף שחור, כנפיים פרושות עם "אצבעות" נוצות, צווארון לבן, ראש קירח ואדמדם, מקור מכופף, נוצות חסרות
# ============================================================
func draw() -> bool:
	if z.dead:
		begin_draw()
	else:
		z.draw_set_transform(Vector2.ZERO, 0.0, Vector2(z._dir * z.sc, z.sc))
	var black := col(Color("1a1a1e"))
	var white := col(Color("e8e8e0"))
	var head := col(z.skin)
	var t: float = z._time
	var body_c := Vector2(0, -12)
	var flap := 0.0
	var fold := 0.0
	match state:
		CIRCLE, RISE:
			flap = sin(t * 3.0) * 0.35
		MARK:
			flap = sin(t * 10.0) * 0.5
		DIVE:
			fold = 0.8
		GROUND:
			flap = sin(t * 14.0) * 0.6
			body_c = Vector2(0, -10)
	if z.dead:
		fold = 0.6
		body_c = Vector2(0, -8)
	for side in [-1.0, 1.0]:   # כנפיים (מהצד: אחת מאחור, אחת מלפנים)
		var span := 40.0 * (1.0 - fold * 0.65)
		var root := body_c + Vector2(-2, -3)
		var tip := root + Vector2(-span * 0.5, -span * (0.35 + flap * side * 0.6) * (1.0 if side > 0.0 else 0.75))
		var wc := black if side > 0.0 else col(Color("26262c"))
		var pts := PackedVector2Array([root + Vector2(6, 0), root + Vector2(-4, -6), tip, tip + Vector2(-4, 6), root + Vector2(-14, 4)])
		Art.fill(z, pts, wc, Art.OUTLINE, 1.0)
		for f in 4:   # "אצבעות" נוצות בקצה
			var fp := tip + Vector2(-2.0 - float(f) * 1.5, 2.0 + float(f) * 2.5)
			z.draw_line(fp, fp + Vector2(-7, 3 + float(f)), wc, 2.0)
		if side > 0.0:
			z.draw_line(root + Vector2(-2, -3), tip + Vector2(6, 2), white, 1.6)   # פס לבן על הכנף
	Art.oval_shaded(z, body_c, 13.0, 7.0, black, 0.0)
	z.draw_colored_polygon(PackedVector2Array([body_c + Vector2(-12, 0), body_c + Vector2(-22, -2), body_c + Vector2(-20, 4)]), black)   # זנב
	Art.oval(z, body_c + Vector2(9, -4), 5.0, 4.0, white, 0.0, Art.OUTLINE, 1.0)   # צווארון
	var hd := body_c + Vector2(15, -7)
	Art.oval_shaded(z, hd, 4.2, 3.6, head, 0.0)
	z.draw_colored_polygon(PackedVector2Array([hd + Vector2(3, -1), hd + Vector2(8, 0), hd + Vector2(6, 3), hd + Vector2(3, 2)]), col(Color("d8d0b0")))   # מקור
	if not z.dead:
		z.draw_circle(hd + Vector2(1.5, -1), 1.0, Color(1.0, 0.25, 0.15))
	z.draw_circle(body_c + Vector2(-2, 2), 2.0, col(Color("6a2a2a")))   # פצע / חוסר נוצות
	for lg in [-3.0, 3.0]:   # רגליים (מקופלות באוויר)
		var foot := body_c + Vector2(lg, 7) if state == GROUND or z.dead else body_c + Vector2(lg - 4, 6)
		z.draw_line(body_c + Vector2(lg, 5), foot + (Vector2(0, 5) if state == GROUND else Vector2.ZERO), col(Color("4a4a40")), 1.6)
	end_draw()
	return true


# ---- הצל המסומן על הקרקע (לאן הוא יצלול) ----
class Shadow extends Node2D:
	var life := 1.0
	var r := 30.0
	var _t := 0.0

	func _ready() -> void:
		z_index = 3

	func _process(delta: float) -> void:
		_t += delta
		if _t >= life:
			queue_free()
			return
		queue_redraw()

	func _draw() -> void:
		var k := clampf(_t / life, 0.0, 1.0)
		draw_colored_polygon(preload("res://art.gd").ellipse(Vector2(0, -1), r * (1.4 - 0.5 * k), r * 0.22, 0.0, 16), Color(0, 0, 0, 0.25 + 0.35 * k))
		draw_set_transform(Vector2(0, -1), 0.0, Vector2(1.0, 0.22))
		draw_arc(Vector2.ZERO, r * 1.5, 0.0, TAU, 20, Color(1.0, 0.3, 0.2, 0.7 if fmod(_t * 8.0, 1.0) < 0.6 else 0.3), 3.0)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
