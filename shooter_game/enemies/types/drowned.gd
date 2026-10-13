extends "res://enemies/zombie_type.gd"
# ============================================================
#  DROWNED (שלב 31, "FLOATING ISLANDS") - טובע מאגם טיטיקקה: עור כחלחל-ירוק נפוח, אצות בשיער, מים נוטפים.
#  "THEY LEARNED TO SWIM": שוחה מתחת למים - רואים רק בועות ואדווה. קליעים לא עוברים במים (אי אפשר לפגוע בו).
#    SWIM    - שוחה אליך. אתה במים וקרוב (LUNGE_R) -> RISE
#    RISE    - בועות גדולות (אזהרה RISE_T) -> פורץ מהמים ונושך
#    UP      - מעל המים UP_T (פגיע, x1.4) ואז צולל שוב
#    LEAP    - אתה על אי קרוב למים (LEAP_R)? קופץ עליך מהמים בהתזה ונושך כשהוא נוחת לידך
#    CLIMB   - אתה על אי רחוק יותר מהשפה? מחכה ליד השפה (LURK_T) ואז מטפס על האי (פגיע) -> זומבי רגיל עד שנופל למים
#    STUNNED - רימון / פיצוץ / טייזר במים: צף מעלה המום (STUN_T, x2)
#  בוס: MAMA QUCHA - ענקית. מתרוממת ושולחת גל (Wave) לאורך האגם: על האי אתה בטוח, במים - נזק והדף. אחרי הגל - פגיעה.
#        אבל אם אתה על אי קרוב (520) - היא מושכת אותך קודם למים ("למדה"), ורק אז הגל.
#  לשנות: SWIM_V, LUNGE_R, RISE_T, UP_T, LURK_T, STUN_T, WAVE_V, WAVE_CD.
# ============================================================

const SOUNDS := {
	"dr_burst": [["N", 0, 0, 0.0, 0.4, 0.0, 9.0, 0.9, 0.3, 0], ["S", 240, 80, 0.0, 0.3, 0.0, 12.0, 0.4, 1.0, 0], ["B", 1.2, 1.2, 0.0, 0.3, 0.0, 8.0, 0.3, 1.0, 0, 0, 60.0]],
	"dr_bubble": [["S", 380, 900, 0.0, 0.05, 0.0, 50.0, 0.18, 1.0, 0], ["S", 520, 1200, 0.07, 0.05, 0.0, 50.0, 0.14, 1.0, 0], ["S", 450, 1000, 0.15, 0.05, 0.0, 50.0, 0.1, 1.0, 0]],
	"dr_wave": {"drive": 1.5, "layers": [["N", 0, 0, 0.0, 1.4, 0.25, 2.0, 1.0, 0.12, 0], ["S", 70, 45, 0.0, 1.2, 0.1, 2.5, 0.5, 1.0, 0]]},
}

const SWIM_V := 115.0
const LUNGE_R := 70.0
const RISE_T := 0.4
const UP_T := 1.3
const LURK_T := 3.0
const LEAP_R := 150.0        # אתה על אי קרוב למים -> קופץ עליך מהמים
const CLIMB_T := 0.6
const STUN_T := 2.5
const WAVE_V := 420.0
const WAVE_CD := Vector2(4.5, 6.5)

enum { SWIM, RISE, UP, DIVE, CLIMB, WALK, STUNNED, WAVE, LEAP }
var state := SWIM
var bites := 0               # לבדיקות
var surfaces := 0
var climbs := 0
var leaps := 0
var waves := 0
var stuns := 0
var _st := 0.0
var _cd := 1.0
var _lurk := 0.0
var _bub := 0.0
var _layer := 4
var _wave_cd := 3.0
var _wet := 0.0
var _climb_to := Vector2.ZERO
var _yanked := false
var _mask := 1 | 16
var yanks := 0               # לבדיקות


func _boss() -> bool:
	return z != null and float(z.chase_range) > 600.0


func stats() -> Dictionary:
	if _boss():
		return {"name": "DROWNED", "hp": 330, "walk": 40.0, "chase": 80.0, "damage": 2, "bite_delay": 0.9, "scale": 1.85, "width": 1.15,
			"duck": 0.0, "cover": 0.0, "skin": Color("6e948c"), "shirt": Color("3e5a50"), "pants": Color("2a3a3a"), "shoe": Color("6e948c"),
			"points": 1400, "boss": true, "boss_name": "MAMA QUCHA - STAY ON THE REEDS"}
	return {"name": "DROWNED", "hp": 28, "walk": 40.0, "chase": 86.0, "damage": 1, "bite_delay": 0.8, "scale": 1.0, "width": 1.0,
		"duck": 0.0, "cover": 0.0, "skin": Color("7a9e96"), "shirt": Color("3a4a52"), "pants": Color("2a3a40"), "shoe": Color("7a9e96"), "points": 420}


func setup() -> void:
	_layer = z.collision_layer
	_submerge()


func _floor() -> float:
	return float(z.get_parent().get_meta("lake_floor", z.global_position.y))


func in_water_pos(p: Vector2) -> bool:
	return p.y > _floor() - 8.0


func submerged() -> bool:   # (לבדיקות ולשלב)
	return state == SWIM or state == RISE or state == DIVE


func _submerge() -> void:
	state = SWIM
	z.collision_layer = 0
	z.z_index = 7   # מציירים רק אדוות - מעל פני המים


func _surface() -> void:
	z.collision_layer = _layer
	z.z_index = 0
	surfaces += 1
	Sfx.play("dr_burst", z.global_position, 0.0, 0.1, 3)
	preload("res://effects/s31_decor.gd").splash(z.get_parent(), Vector2(z.global_position.x, _floor() - 18.0), 10 if _boss() else 6)


func can_bite() -> bool:
	return state == UP or state == WALK


func can_groan() -> bool:
	return state == WALK


func brain_overrides() -> Dictionary:
	return {"aggression": 0.4}


func on_damage(_amount: int, _hit_pos: Vector2, _dir: Vector2, src: Dictionary) -> bool:
	var s := str(src.get("source", ""))
	if state in [SWIM, RISE, DIVE]:   # מתחת למים: רק פיצוץ / טייזר מגיעים אליו
		if s in ["grenade", "explosion", "dynamite", "mine", "barrel", "artillery"]:
			_stun.call_deferred()
			return true
		return s == "taser"
	return true


func _stun() -> void:
	if z == null or not is_instance_valid(z) or z.dead or not (state in [SWIM, RISE, DIVE]):
		return
	stuns += 1
	_surface()
	state = STUNNED
	_st = STUN_T * (0.5 if _boss() else 1.0)
	z._popup("STUNNED", Color("a0e0ff"), 14, -80.0)


func damage_mult(_zone: String, _src: Dictionary) -> float:
	match state:
		UP, WAVE:
			return 1.4
		STUNNED:
			return 2.0
		CLIMB, LEAP:
			return 1.5
	return 1.0


func physics(pl: Node, delta: float) -> bool:
	_st -= delta
	_cd -= delta
	_bub -= delta
	_wave_cd -= delta
	if z.dead:
		return false
	var has_pl: bool = pl != null and not pl.dead
	var dx: float = (pl.global_position.x - z.global_position.x) if has_pl else 0.0
	var pl_wet: bool = has_pl and in_water_pos(pl.global_position)
	match state:
		WALK:   # על אי. נפל למים -> צולל
			if z.is_on_floor() and in_water_pos(z.global_position):
				_wet += delta
				if _wet > 0.5:
					_wet = 0.0
					_submerge()
					_cd = 1.0
					return true
			else:
				_wet = 0.0
			return false
		SWIM:
			var want := 0.0
			if has_pl and absf(dx) > 8.0:
				want = signf(dx) * SWIM_V * (0.9 if _boss() else 1.0)
				z._dir = signf(dx)
			z.velocity.x = move_toward(z.velocity.x, want, 500.0 * delta)
			_move(delta)
			if z.is_on_wall() and want != 0.0:
				_under_obstacle(signf(want))
			if _bub <= 0.0 and Art.on_screen(z, z.global_position):
				_bub = randf_range(0.8, 1.6)
				if randf() < 0.4:
					Sfx.play("dr_bubble", z.global_position, -10.0, 0.2, 4)
			if not has_pl:
				return true
			if _boss():
				if _wave_cd <= 0.0 and absf(dx) < 750.0:
					_surface()
					state = WAVE
					_st = 1.0
					z.velocity.x = 0.0
					Sfx.play("dr_wave", z.global_position, 4.0, 0.0, 1)
					return true
			if _cd <= 0.0 and pl_wet and absf(dx) < LUNGE_R and absf(pl.global_position.y - z.global_position.y) < 30.0:
				state = RISE
				_st = RISE_T
				return true
			if not pl_wet and not _boss() and _cd <= 0.0 and absf(dx) < LEAP_R and pl.global_position.y > z.global_position.y - 110.0:   # קרוב לשפה: קפיצה מהמים!
				_leap(pl, dx)
				return true
			if not pl_wet and not _boss():   # אתה על אי: מחכה ליד השפה ואז מטפס
				var isl := _island_of(pl.global_position.x)
				if isl != null and _near_edge(isl):
					_lurk += delta
					if _lurk > LURK_T:
						_lurk = 0.0
						_start_climb(isl)
				else:
					_lurk = maxf(_lurk - delta, 0.0)
			elif _boss() and not pl_wet and _cd <= 0.0 and absf(dx) < 140.0:   # הבוס: אתה על אי לידה -> עולה ומכה
				state = RISE
				_st = RISE_T
			return true
		RISE:
			z.velocity.x = 0.0
			if _st <= 0.0:
				_surface()
				state = UP
				_st = UP_T * (1.6 if _boss() else 1.0)
				if has_pl and absf(dx) < LUNGE_R + (60.0 if _boss() else 24.0) and absf(pl.global_position.y - z.global_position.y) < (90.0 if _boss() else 34.0):
					bites += 1
					pl.hurt(z.damage, Vector2(signf(dx) * 1.4, -0.8))
			return true
		UP:
			if has_pl:
				z._dir = signf(dx) if absf(dx) > 4.0 else z._dir
			z.velocity.x = move_toward(z.velocity.x, 0.0, 600.0 * delta)
			_move(delta)
			if _st <= 0.0:
				state = DIVE
				_st = 0.3
			return true
		DIVE:
			if _st <= 0.0:
				preload("res://effects/s31_decor.gd").splash(z.get_parent(), Vector2(z.global_position.x, _floor() - 18.0), 4)
				_submerge()
				_cd = 1.6
			return true
		STUNNED:
			z.velocity.x = move_toward(z.velocity.x, 0.0, 600.0 * delta)
			_move(delta)
			if _st <= 0.0:
				state = DIVE
				_st = 0.3
			return true
		LEAP:   # באוויר (עובר מעל סירות וארגזים) - נוחת לידך ונושך
			z.velocity.y += z.gravity * delta
			if z.collision_mask == 0 and z.velocity.y > 0.0:
				z.collision_mask = _mask   # בירידה: נוחת על האי
			z.move_and_slide()
			if z.is_on_floor() and _st <= 0.0:
				state = WALK
				z._alert_t = maxf(float(z._alert_t), 6.0)
				if has_pl and absf(dx) < 40.0 and absf(pl.global_position.y - z.global_position.y) < 50.0:
					bites += 1
					pl.hurt(z.damage, Vector2(signf(dx) * 1.4, -0.8))
				return false
			return true
		CLIMB:
			z.velocity = Vector2.ZERO
			if _st <= 0.0:
				z.global_position = _climb_to
				state = WALK
				climbs += 1
				z._alert_t = maxf(float(z._alert_t), 6.0)
				return false
			return true
		WAVE:
			z.velocity.x = 0.0
			if has_pl:
				z._dir = signf(dx) if absf(dx) > 4.0 else z._dir
			if _st <= 0.0:
				if not _yanked and has_pl and not pl_wet and absf(dx) < 520.0:   # "למדה" שאתה מתחבא על האי: מושכת אותך למים
					_yanked = true
					yanks += 1
					_st = 0.5
					pl.velocity = Vector2(signf(-dx) * 420.0, -260.0)
					pl.hurt(1, Vector2.ZERO)
					z._popup("INTO THE WATER!", Color("a0e0ff"), 16, -150.0)
					var cam: Camera2D = z.get_viewport().get_camera_2d()
					if cam != null and cam.has_method("shake"):
						cam.shake(10.0, 0.4)
					return true
				_yanked = false
				_send_wave(pl)
				state = UP
				_st = 2.6
				_wave_cd = randf_range(WAVE_CD.x, WAVE_CD.y)
			return true
	return false


func _move(delta: float) -> void:
	if not z.is_on_floor():
		z.velocity.y += z.gravity * delta
	z.move_and_slide()
	z.global_position.x = clampf(z.global_position.x, 30.0, float(z.world_w) - 30.0)


# נתקע בסירה / ארגז שצפים במים: שוחה מתחתיהם (באיים - לא)
func _under_obstacle(dir: float) -> void:
	if _island_of(z.global_position.x + dir * 30.0) != null:
		return
	for c in z.get_tree().get_nodes_in_group("lake_obstacles") + z.get_tree().get_nodes_in_group("cover"):
		if c.is_in_group("islands") or not c.has_method("cover_rect"):
			continue
		var r: Rect2 = c.cover_rect()
		if z.global_position.x + dir * 30.0 > r.position.x and z.global_position.x + dir * 30.0 < r.end.x and r.end.y > z.global_position.y - 4.0:
			z.global_position.x = (r.end.x + 14.0) if dir > 0.0 else (r.position.x - 14.0)
			return


func _island_of(x: float) -> Node:
	for isl in z.get_tree().get_nodes_in_group("islands"):
		if isl.has_x(x):
			return isl
	return null


func _near_edge(isl: Node) -> bool:
	var x0: float = isl.global_position.x
	var x1: float = x0 + float(isl.w)
	var x: float = z.global_position.x
	return (x < x0 + 4.0 and x > x0 - 50.0) or (x > x1 - 4.0 and x < x1 + 50.0)


func _leap(pl: Node, dx: float) -> void:
	_surface()
	state = LEAP
	leaps += 1
	_st = 0.15
	z._dir = signf(dx) if absf(dx) > 2.0 else z._dir
	var up: float = clampf(z.global_position.y - pl.global_position.y, 0.0, 120.0)
	var vy := 430.0 + up * 2.0
	var g: float = maxf(float(z.gravity), 100.0)
	var t := (vy + sqrt(maxf(vy * vy - 2.0 * g * up, 0.0))) / g   # זמן באוויר עד גובה השחקן -> נוחת עליו
	z.velocity = Vector2(dx / maxf(t, 0.2), -vy)
	_mask = z.collision_mask
	z.collision_mask = 0   # עולה דרך מכשולים שליד השפה
	z._popup("!", Color("a0e0ff"), 18, -70.0)


func _start_climb(isl: Node) -> void:
	_surface()
	state = CLIMB
	_st = CLIMB_T
	var x0: float = isl.global_position.x
	var left: bool = z.global_position.x < x0 + 4.0
	_climb_to = Vector2((x0 + 14.0) if left else (x0 + float(isl.w) - 14.0), float(isl.top_y()) - 1.0)
	z._dir = 1.0 if left else -1.0
	z._popup("CLIMBING", Color("a0d8d0"), 12, -70.0)


func _send_wave(pl: Node) -> void:
	waves += 1
	var dirs := [-1.0, 1.0]
	if pl != null:
		dirs = [signf(pl.global_position.x - z.global_position.x) if pl.global_position.x != z.global_position.x else 1.0]
		if randf() < 0.4:
			dirs.append(-float(dirs[0]))
	for d in dirs:
		var w := Wave.new()
		w.dir = float(d)
		w.floor_y = _floor()
		z.get_parent().add_child(w)
		w.global_position = Vector2(z.global_position.x + float(d) * 40.0 * z.sc, _floor())
	var cam: Camera2D = z.get_viewport().get_camera_2d()
	if cam != null and cam.has_method("shake"):
		cam.shake(8.0, 0.4)


func on_death() -> void:
	z.z_index = 0
	z.collision_layer = 0


# ============================================================
#  גל: נע לאורך האגם. פוגע במי שבמים (לא על אי / מכשול). נשבר על איים.
# ============================================================
class Wave extends Node2D:
	const W := 46.0
	const V := 420.0             # = WAVE_V
	var dir := 1.0
	var floor_y := 630.0
	var hits := 0
	var _dist := 0.0
	var _hit := false
	var _sp := 0.0

	func _ready() -> void:
		z_index = 7

	func _physics_process(delta: float) -> void:
		var S := preload("res://effects/s31_decor.gd")
		var step: float = dir * V * delta
		global_position.x += step
		_dist += absf(step)
		_sp -= delta
		if _sp <= 0.0 and Art.on_screen(self, global_position):
			_sp = 0.08
			Particles.burst(get_parent(), global_position + Vector2(dir * 10.0, -S.WATER_Y - 24.0), "drop", Vector2(dir, -1.0), 2)
		for isl in get_tree().get_nodes_in_group("islands"):   # נשבר על אי
			if isl.has_x(global_position.x + dir * W * 0.5):
				S.splash(get_parent(), global_position + Vector2(0, -S.WATER_Y - 10.0), 12)
				queue_free()
				return
		var pl := get_tree().get_first_node_in_group("player")
		if not _hit and pl != null and not pl.dead and absf(pl.global_position.x - global_position.x) < W * 0.6 and pl.global_position.y > floor_y - 24.0:
			_hit = true
			hits += 1
			pl.hurt(2, Vector2(dir * 2.4, -1.4))
		for zz in get_tree().get_nodes_in_group("zombies"):   # מפיל זומבים על הדרך
			if not zz.dead and not zz.is_boss() and absf(zz.global_position.x - global_position.x) < W * 0.5 and zz.global_position.y > floor_y - 10.0 and zz.collision_layer != 0 and not (zz.type_mod != null and zz.type_mod.has_method("to_water")):
				zz.velocity = Vector2(dir * 260.0, -220.0)
		if _dist > 1000.0 or global_position.x < 0.0:
			queue_free()
			return
		queue_redraw()

	func _draw() -> void:
		var S := preload("res://effects/s31_decor.gd")
		var k := clampf(1.0 - _dist / 1000.0, 0.3, 1.0)
		var hgt := 54.0 * k
		var top := -S.WATER_Y - hgt
		var back := -dir * W
		var pts := PackedVector2Array([Vector2(back * 1.6, -S.WATER_Y), Vector2(back * 0.6, top + hgt * 0.4), Vector2(0, top), Vector2(dir * W * 0.4, top + 6.0), Vector2(dir * W * 0.3, top + hgt * 0.5), Vector2(dir * W * 0.6, -S.WATER_Y)])
		draw_colored_polygon(pts, Color(0.2, 0.45, 0.55, 0.85))
		draw_polyline(PackedVector2Array([Vector2(back * 0.6, top + hgt * 0.4), Vector2(0, top), Vector2(dir * W * 0.4, top + 6.0)]), Color(0.9, 0.97, 1.0, 0.9), 3.0)   # קצף
		for q in 4:
			draw_circle(Vector2(dir * W * 0.3 + float(q) * dir * 5.0, top + 4.0 + float(q) * 4.0), 3.0 - float(q) * 0.5, Color(1, 1, 1, 0.8))


# ============================================================
#  ציור: במים - בועות, אדווה בצורת V, צל כהה. מעל המים - גוף נפוח, אצות, מים נוטפים.
# ============================================================
func draw() -> bool:
	if not z.dead and state in [SWIM, RISE, DIVE]:
		return _draw_under()
	begin_draw()
	var sk := col(z.skin)
	var shirt := col(z.shirt)
	var p: float = z._walk_phase
	var f: Array = feet(4.0, 2.0)
	var hip := Vector2(0, -22)
	var sh := Vector2(1, -37)
	var head := sh + Vector2(3.5, -8)
	var raise := state == WAVE or (state == UP and _st > UP_T - 0.25)
	z._leg(hip + Vector2(-2, 0), f[1], col(Art.shade(z.pants, 0.25)), sk, sk)
	z._leg(hip + Vector2(2, 0), f[0], col(z.pants), sk, sk)
	var hb := sh + Vector2(-5.0 - sin(p) * 2.0, 15.0)
	var hf := sh + Vector2(10.0 + sin(p) * 2.0, 10.0)
	if raise:   # ידיים למעלה (גל / פריצה מהמים)
		hb = sh + Vector2(-8, -16)
		hf = sh + Vector2(10, -18)
	elif state == CLIMB:
		hb = sh + Vector2(6, -14)
		hf = sh + Vector2(12, -12)
	z._arm(sh + Vector2(-3, 1), hb, Art.shade(sk, 0.25), Art.shade(shirt, 0.3))
	Art.fill_shaded(z, PackedVector2Array([sh + Vector2(-8, -1), sh + Vector2(8, 0), hip + Vector2(8, 3), hip + Vector2(-8, 3)]), shirt, 0.12, 0.4)
	for q in 3:   # קרעים
		z.draw_line(hip + Vector2(-6.0 + float(q) * 5.0, 3), hip + Vector2(-5.0 + float(q) * 5.0, 7), shirt, 1.6)
	Art.oval_shaded(z, head, 6.0, 6.4, sk, 0.0)   # ראש נפוח
	for q in 5:   # אצות בשיער
		var a := -PI * 0.5 + float(q - 2) * 0.45
		var b := head + Vector2.from_angle(a) * 5.5
		z.draw_line(b, b + Vector2(-2.0 + float(q) * 0.5, 8.0 + float(q % 2) * 4.0), col(Color("3a6a2a")), 1.4)
	if not z.dead:
		z.draw_circle(head + Vector2(3.0, -0.5), 1.4, Color(0.85, 0.95, 0.9))
		z.draw_circle(head + Vector2(3.0, -0.5), 0.6, Color(0.1, 0.2, 0.2))
		z.draw_colored_polygon(Art.ellipse(head + Vector2(3.5, 3.0), 1.8, 1.3, 0.0, 8), col(Color("1a2a2a")))
		for q in 2:   # טיפות
			var dy := fposmod(z._time * 30.0 + float(q) * 9.0, 18.0)
			z.draw_circle(hb + Vector2(0, dy), 0.9, Color(0.7, 0.9, 1.0, 0.8))
	z._arm(sh + Vector2(3, 1), hf, sk, shirt)
	end_draw()
	return true


func _draw_under() -> bool:
	z.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	var S := preload("res://effects/s31_decor.gd")
	var sc: float = z.sc
	var surf := -S.WATER_Y
	z.draw_colored_polygon(Art.ellipse(Vector2(0, -8.0 * sc), 12.0 * sc, 6.0 * sc, 0.0, 10), Color(0.05, 0.12, 0.14, 0.35))   # צל מתחת למים
	var spd := absf(z.velocity.x)
	if spd > 20.0:   # אדווה בצורת V
		var back := -signf(z.velocity.x) * 22.0 * sc
		z.draw_line(Vector2(4.0 * sc * signf(z.velocity.x), surf), Vector2(back, surf - 3.0), Color(0.9, 0.97, 1.0, 0.55), 1.5)
		z.draw_line(Vector2(4.0 * sc * signf(z.velocity.x), surf), Vector2(back, surf + 3.0), Color(0.9, 0.97, 1.0, 0.4), 1.5)
	var n := 4 if state == SWIM else 9
	for q in n:   # בועות
		var t: float = z._time * (1.6 if state == SWIM else 3.0) + float(q) * 0.37
		var k := fposmod(t, 1.0)
		var bx := sin(float(q) * 2.1 + z._time) * 5.0 * sc
		z.draw_arc(Vector2(bx, lerpf(-6.0, surf - 2.0, k)), (1.2 + float(q % 3) * 0.6) * sc, 0.0, TAU, 8, Color(0.85, 0.95, 1.0, 0.7 * (1.0 - k * 0.5)), 1.0)
	if state == RISE:   # אזהרה: מים רותחים
		z.draw_colored_polygon(Art.ellipse(Vector2(0, surf), 16.0 * sc, 3.0, 0.0, 12), Color(1, 1, 1, 0.45 + 0.2 * sin(z._time * 30.0)))
	return true
