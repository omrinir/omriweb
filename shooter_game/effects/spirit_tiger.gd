extends Node2D
const DrawBatch := preload("res://effects/draw_batch.gd")
# ============================================================
#  SPIRIT TIGER - פריט מיוחד (progression/arsenal.gd -> SPECIALS "tiger", שימוש אחד).
#  C -> נמר רוח ירוק יוצא מהגוף של השחקן: עמוד להבות ירוקות סביב הגוף, הנמר גדל מהחזה וקופץ החוצה.
#  רץ בקפיצות (דהירה) לזומבי הכי קרוב, מזנק עליו בקשת גבוהה והורג אותו (נזק ענק, גם דרך שריון).
#  אחרי KILLS הריגות (או כשאין זומבים IDLE_MAX שניות / LIFE_MAX בסך הכל) - שואג ומתפרק ללהבות שעולות.
#  רוח: עובר דרך קירות ובורות, לא נפגע. בוסים וזומבי MIND CONTROL - לא תוקף.
#  ציור: גוף אטום (ירוקים) בקריאת DrawBatch אחת + ילד _glow עם אור מצטבר (הילה, עיניים, להבות).
#  לשנות: KILLS, SEARCH, POUNCE_R, RUN_BOUND / BOUND_T, POUNCE_T, SCALE, FLAME_RATE, FLAMES_MAX.
#  בדיקה: devtools/t_tiger.gd (TIGER_SHOTS=1 עם xvfb = תמונות).
# ============================================================

const Sfx := preload("res://sfx.gd")

const KILLS := 3
const SCALE := 1.15
const SEARCH := 1100.0           # כמה רחוק הוא מחפש זומבים
const POUNCE_R := 280.0          # מהמרחק הזה מזנק
const RUN_BOUND := 190.0         # אורך קפיצת דהירה
const BOUND_T := 0.24
const BOUND_H := 24.0
const POUNCE_T := 0.42
const POUNCE_H := 110.0
const MAUL_T := 0.34             # כמה זמן נשאר על הגופה
const SUMMON_T := 0.75           # יוצא מהגוף
const FADE_T := 0.9
const IDLE_MAX := 5.0
const LIFE_MAX := 22.0
const FLAME_RATE := 75.0         # להבות בשנייה מהגוף
const FLAMES_MAX := 170
const DMG := 9999

const C_BODY := Color("2fd36a")
const C_BELLY := Color("9affbe")
const C_FAR := Color("1c9a4c")
const C_STRIPE := Color("0a5a26")
const C_EYE := Color(0.85, 1.0, 0.85)

const SOUNDS := {
	"tiger_summon": [["N", 0, 0, 0.0, 0.75, 0.3, 0.0, 0.45, 0.35, 0], ["S", 110, 460, 0.0, 0.75, 0.25, 0.0, 0.22, 1.0, 0.03], ["C", 0, 0, 0.0, 0.8, 0.1, 2.0, 0.45, 1.0, 0]],
	"tiger_roar": {"drive": 3.0, "rev": 0.3, "layers": [["V", 150, 82, 0.0, 1.1, 0.06, 1.6, 0.9, 1.0, 0.05, 0, [350, 900, 24]], ["W", 74, 52, 0.0, 1.1, 0.08, 1.6, 0.35, 0.25, 0.06], ["N", 0, 0, 0.0, 0.9, 0.05, 2.5, 0.25, 0.2, 0]]},
	"tiger_pounce": [["N", 0, 0, 0.0, 0.28, 0.04, 8.0, 0.45, 0.45, 0], ["S", 320, 150, 0.0, 0.22, 0.0, 11.0, 0.15, 1.0, 0]],
	"tiger_maul": {"drive": 2.5, "layers": [["N", 0, 0, 0.0, 0.12, 0.0, 28.0, 0.8, 0.7, 0], ["S", 140, 60, 0.0, 0.18, 0.0, 16.0, 0.7, 1.0, 0], ["V", 115, 90, 0.04, 0.4, 0.02, 5.0, 0.6, 1.0, 0.05, 0, [300, 700, 30]]]},
}

enum { SUMMON, RUN, POUNCE, MAUL, LEAVE }
var pl: Node2D = null
var state := SUMMON
var kills := 0
var face := 1.0
var pos := Vector2.ZERO          # כפות הרגליים (קואורדינטות השלב)
var _st := 0.0                   # זמן במצב הנוכחי
var _life := 0.0
var _t := 0.0
var _idle := 0.0
var _target: Node2D = null
var _skip := {}                  # זומבים ששרדו מכה (שריון מיוחד) - לא חוזרים אליהם
var _from := Vector2.ZERO
var _to := Vector2.ZERO
var _arc_h := 0.0
var _arc_t := 0.3
var _rot := 0.0
var _bounding := false
var _gait := 0.0
var _jaw := 0.0
var _crouch := 0.0
var _stretch := 0.0
var _grow := 0.0
var _alpha := 0.0
var _flames: Array = []          # [pos, vel, life, age, size]
var _emit := 0.0
var _glow: Node2D
var _space: PhysicsDirectSpaceState2D
var kills_log: Array = []        # לבדיקות


func setup(player: Node2D) -> void:
	pl = player
	face = float(player._face()) if player.has_method("_face") else 1.0
	pos = player.global_position


func _ready() -> void:
	z_index = 3
	_space = get_world_2d().direct_space_state
	_glow = Node2D.new()
	_glow.material = preload("res://effects/boom_fx.gd").res()["add"]
	_glow.draw.connect(_draw_glow)
	add_child(_glow)
	Sfx.play("tiger_summon", pos, 2.0, 0.0, 1)
	for i in 26:   # הבזק להבות מהגוף
		_flame(pos + Vector2(randf_range(-12.0, 12.0), -randf_range(5.0, 55.0)), Vector2(randf_range(-160.0, 160.0), -randf_range(80.0, 260.0)), randf_range(0.4, 0.8), randf_range(6.0, 11.0))


func _process(delta: float) -> void:
	_t += delta
	_st += delta
	_life += delta
	match state:
		SUMMON:
			_do_summon()
		RUN:
			_do_run(delta)
		POUNCE:
			_do_pounce()
		MAUL:
			_jaw = absf(sin(_st * 22.0)) * 0.9
			_crouch = minf(1.0, _st * 8.0)
			if _st >= MAUL_T:
				_crouch = 0.0
				_jaw = 0.0
				if kills >= KILLS:
					_leave()
				else:
					_goto(RUN)
		LEAVE:
			_alpha = clampf(1.0 - _st / FADE_T, 0.0, 1.0)
			pos.y -= delta * 30.0
			if _st > FADE_T and _flames.is_empty():
				queue_free()
				return
	if state != LEAVE and state != SUMMON and _life > LIFE_MAX:
		_leave()
	_update_flames(delta)
	queue_redraw()
	_glow.queue_redraw()


func _goto(s: int) -> void:
	state = s
	_st = 0.0


# ---- יוצא מהגוף: גדל מהחזה של השחקן, ואז קופץ קדימה ----
func _do_summon() -> void:
	var u := clampf(_st / SUMMON_T, 0.0, 1.0)
	if pl != null and is_instance_valid(pl):
		var chest: Vector2 = pl.global_position + Vector2(0.0, -30.0)
		var out: Vector2 = pl.global_position + Vector2(face * 46.0, 0.0)
		var e := u * u * (3.0 - 2.0 * u)
		pos = chest.lerp(out, e)
		_from = pl.global_position
	_grow = 0.25 + 0.75 * (1.0 - pow(1.0 - u, 3.0))
	_alpha = minf(1.0, u * 2.2)
	_stretch = 0.6 * sin(u * PI)
	_jaw = 0.5 * u
	if u >= 1.0:
		_grow = 1.0
		_jaw = 0.0
		pos = _floor_at(pos.x, pos.y)
		Sfx.play("tiger_roar", pos, 1.0, 0.05, 1)
		_goto(RUN)


# ---- דהירה לזומבי הכי קרוב ----
func _do_run(delta: float) -> void:
	if _bounding:   # באמצע קפיצת דהירה
		var u := _st / _arc_t
		if u < 1.0:
			_move_arc(u)
			_gait = u
			return
		pos = _to   # נחת
		_bounding = false
		_rot = 0.0
	if not _valid(_target):
		_target = _find_target()
	if _target == null:
		_idle += delta
		_stretch = 0.0
		_gait = fmod(_gait + delta * 0.6, 1.0)
		if _idle > IDLE_MAX:
			_leave()
		return
	_idle = 0.0
	var tp: Vector2 = _target.global_position
	if pos.distance_to(tp) < POUNCE_R:
		_from = pos
		_to = tp
		face = signf(tp.x - pos.x) if absf(tp.x - pos.x) > 4.0 else face
		_arc_h = POUNCE_H + maxf(0.0, pos.y - tp.y) * 0.5
		_arc_t = POUNCE_T
		Sfx.play("tiger_pounce", pos, 0.0, 0.1, 2)
		_goto(POUNCE)
		return
	var dx := tp.x - pos.x
	face = signf(dx) if absf(dx) > 4.0 else face
	var step := clampf(absf(dx) - POUNCE_R * 0.6, 70.0, RUN_BOUND)
	var nx := pos.x + face * step
	var ref_y := lerpf(pos.y, tp.y, clampf(step / maxf(absf(dx), 1.0), 0.0, 1.0))
	_from = pos
	_to = _floor_at(nx, ref_y)
	_arc_h = BOUND_H + maxf(0.0, pos.y - _to.y)
	_arc_t = BOUND_T * clampf(step / RUN_BOUND, 0.6, 1.0)
	_bounding = true
	_st = 0.0


func _do_pounce() -> void:
	if _valid(_target):
		_to = _target.global_position   # מזנק אחרי הזומבי (גם אם זז)
	var u := clampf(_st / _arc_t, 0.0, 1.0)
	_move_arc(u)
	_stretch = sin(u * PI)
	_jaw = clampf(u * 2.0 - 0.6, 0.0, 1.0)
	_gait = 0.0
	if u >= 1.0:
		pos = _to
		_from = _to
		_rot = 0.0
		_strike()
		_goto(MAUL)


func _move_arc(u: float) -> void:
	var p := _from.lerp(_to, u) + Vector2(0.0, -4.0 * _arc_h * u * (1.0 - u))
	var v := (_to - _from) + Vector2(0.0, -4.0 * _arc_h * (1.0 - 2.0 * u))
	_rot = clampf(atan2(v.y, maxf(absf(v.x), 1.0)), -0.7, 0.7) * face * (0.8 if state == POUNCE else 0.35)
	pos = p


func _strike() -> void:
	_stretch = 0.0
	if not _valid(_target):
		return
	var z := _target
	var d := Vector2(face, -0.35).normalized()
	var hit := z.global_position + Vector2(0.0, -30.0 * float(z.get("sc") if z.get("sc") != null else 1.0))
	z.take_damage(DMG, hit, d, false, {"source": "tiger", "fixed": DMG})
	if not z.dead:
		z.take_damage(DMG, hit, d, true, {"source": "tiger", "fixed": DMG})
	Sfx.play("tiger_maul", hit, 1.0, 0.1, 2)
	for i in 22:
		_flame(hit + Vector2(randf_range(-16.0, 16.0), randf_range(-16.0, 16.0)), Vector2(randf_range(-200.0, 200.0), -randf_range(60.0, 300.0)), randf_range(0.3, 0.6), randf_range(5.0, 10.0))
	var cam := get_viewport().get_camera_2d()
	if cam != null and cam.has_method("shake"):
		cam.shake(6.0)
	if z.dead:
		kills += 1
		kills_log.append(z.kind if z.get("kind") != null else -1)
		if z.has_method("_popup"):
			z._popup("SPIRIT %d/%d" % [kills, KILLS], Color("7dffa0"), 18, -95.0)
	else:
		_skip[z.get_instance_id()] = true
	_target = null


func _leave() -> void:
	if state == LEAVE:
		return
	Sfx.play("tiger_roar", pos, 0.0, 0.05, 1)
	_crouch = 0.0
	_jaw = 1.0
	_rot = 0.0
	_goto(LEAVE)


func _valid(z: Node2D) -> bool:
	return z != null and is_instance_valid(z) and not z.dead and not z.is_boss() and z.get("possessed") == null and not _skip.has(z.get_instance_id())


func _find_target() -> Node2D:
	var best: Node2D = null
	var bd := INF
	for z in get_tree().get_nodes_in_group("zombies"):
		if not _valid(z):
			continue
		var d: Vector2 = z.global_position - pos
		if absf(d.x) > SEARCH or absf(d.y) > 420.0:
			continue
		var s := d.length() + (160.0 if signf(d.x) != face else 0.0)
		if s < bd:
			bd = s
			best = z
	return best


# הרצפה מתחת ל-x (קרן למטה, שכבה 1). אין רצפה -> ref_y
func _floor_at(x: float, ref_y: float) -> Vector2:
	var q := PhysicsRayQueryParameters2D.create(Vector2(x, ref_y - 160.0), Vector2(x, ref_y + 320.0), 1)
	var hit := _space.intersect_ray(q)
	return Vector2(x, float(hit["position"].y)) if not hit.is_empty() else Vector2(x, ref_y)


# ============ להבות ============
func _flame(p: Vector2, v: Vector2, life: float, size: float) -> void:
	if _flames.size() >= FLAMES_MAX:
		return
	_flames.append([p, v, life, 0.0, size])


func _update_flames(delta: float) -> void:
	if state != LEAVE or _st < FADE_T:
		var rate := FLAME_RATE * (2.4 if state == SUMMON else (2.0 if state == LEAVE else 1.0))
		_emit += delta * rate
		var xf := _xf()
		while _emit >= 1.0:
			_emit -= 1.0
			var lp := Vector2(randf_range(-40.0, 40.0), randf_range(-44.0, -30.0))
			var r := randf()
			if r < 0.15:
				lp = Vector2(randf_range(36.0, 52.0), -50.0)   # ראש / אוזניים
			elif r < 0.27:
				lp = _tail_pt(1.0)
			elif r < 0.4:
				lp = Vector2(randf_range(-30.0, 30.0), -4.0)   # כפות
			var wp := xf * lp
			if state == SUMMON and pl != null and is_instance_valid(pl) and randf() < 0.55:   # עמוד אש מהגוף של השחקן
				wp = pl.global_position + Vector2(randf_range(-11.0, 11.0), -randf_range(0.0, 58.0))
			var mv := (_to - _from).normalized() * -60.0 if _bounding or state == POUNCE else Vector2.ZERO
			_flame(wp, Vector2(randf_range(-25.0, 25.0) + mv.x, -randf_range(70.0, 150.0)), randf_range(0.3, 0.6), randf_range(4.0, 8.5) * _grow)
	for i in range(_flames.size() - 1, -1, -1):
		var f: Array = _flames[i]
		f[3] += delta
		if f[3] >= f[2]:
			_flames.remove_at(i)
			continue
		var v: Vector2 = f[1]
		v.y -= 120.0 * delta   # אש עולה
		v.x *= 1.0 - 2.0 * delta
		f[1] = v
		f[0] += v * delta


func _xf() -> Transform2D:
	var s := SCALE * _grow
	return Transform2D(_rot, Vector2(face * s, s), 0.0, pos)


func _tail_pt(u: float) -> Vector2:
	return Vector2(-36.0 - 30.0 * u, -33.0 - 20.0 * u + sin(_t * 6.0 - u * 3.0) * 7.0 * u)


# ============ ציור ============
func _draw() -> void:
	DrawBatch.begin(self)
	_draw_b()
	DrawBatch.end(self)


func _draw_b() -> void:
	if _alpha <= 0.01:
		return
	DrawBatch.set_transform_matrix(self, _xf())
	draw_tiger(self, _t, _gait, 1.0 if _bounding else 0.0, _stretch, _crouch, _jaw, _alpha)
	DrawBatch.set_transform_matrix(self, Transform2D.IDENTITY)


# הנמר בקואורדינטות מקומיות: פונה ימינה, כפות הרגליים ב-y=0, אורך ~100. גם לאייקון (draw_icon)
static func draw_tiger(ci: CanvasItem, t: float, gait: float, run: float, stretch: float, crouch: float, jaw: float, a: float) -> void:
	var cb := Color(C_BODY, a)
	var cs := Color(C_STRIPE, a)
	var sx := 1.0 + 0.16 * stretch
	var cy := crouch * 7.0
	var breathe := sin(t * 3.0) * 0.8
	# רגליים רחוקות (כהות יותר)
	_leg(ci, Vector2(-24.0 * sx, -30.0 + cy), gait + 0.5, run, stretch, -1.0, crouch, Color(C_FAR, a))
	_leg(ci, Vector2(20.0 * sx, -31.0 + cy * 1.3), gait + 0.75, run, stretch, 1.0, crouch, Color(C_FAR, a))
	# זנב
	var prev := Vector2(-36.0 * sx, -33.0 + cy)
	for i in range(1, 9):
		var u := float(i) / 8.0
		var p := Vector2(-36.0 * sx - 30.0 * u, -33.0 + cy - 20.0 * u + sin(t * 6.0 - u * 3.0) * 7.0 * u)
		DrawBatch.line(ci, prev, p, cs if i % 3 == 0 else cb, 6.0 - 3.5 * u)
		prev = p
	# גוף
	var body := PackedVector2Array()
	var top := [Vector2(-40, -30), Vector2(-28, -41), Vector2(-8, -39), Vector2(12, -43), Vector2(28, -42), Vector2(38, -38)]
	var bot := [Vector2(36, -25), Vector2(18, -19), Vector2(-4, -21.5), Vector2(-24, -19.5), Vector2(-40, -23)]
	for p: Vector2 in top:
		body.append(Vector2(p.x * sx, p.y + breathe * (0.5 if p.x < 0 else 1.0) + cy * (1.3 if p.x > 0 else 1.0)))
	for p: Vector2 in bot:
		body.append(Vector2(p.x * sx, p.y + cy * (1.3 if p.x > 0 else 1.0)))
	DrawBatch.colored_polygon(ci, body, cb)
	DrawBatch.ellipse(ci, Vector2(2.0 * sx, -23.0 + cy), 26.0 * sx, 4.0, Color(C_BELLY, 0.55 * a))   # בטן בהירה
	for i in 5:   # פסים
		var x := (-28.0 + float(i) * 11.0) * sx
		var ty := -40.0 + cy * (1.3 if x > 0.0 else 1.0) + breathe
		DrawBatch.line(ci, Vector2(x, ty), Vector2(x - 5.0, ty + 11.0), cs, 3.2)
		DrawBatch.line(ci, Vector2(x - 5.0, ty + 11.0), Vector2(x - 2.0, ty + 15.0), cs, 2.0)
	# רגליים קרובות
	_leg(ci, Vector2(-26.0 * sx, -29.0 + cy), gait, run, stretch, -1.0, crouch, cb)
	_leg(ci, Vector2(22.0 * sx, -30.0 + cy * 1.3), gait + 0.25, run, stretch, 1.0, crouch, cb)
	# ראש
	var h := Vector2(38.0 * sx, cy * 1.6 + crouch * 3.0)
	var head := PackedVector2Array([Vector2(-4, -46), Vector2(6, -51), Vector2(15, -47), Vector2(22, -41), Vector2(24, -35), Vector2(18, -31), Vector2(8, -30), Vector2(-3, -33)])
	for i in head.size():
		head[i] = head[i] + h
	DrawBatch.colored_polygon(ci, PackedVector2Array([h + Vector2(-1, -45), h + Vector2(1, -51), h + Vector2(6, -47)]), cb)   # אוזן
	DrawBatch.colored_polygon(ci, PackedVector2Array([h + Vector2(7, -48), h + Vector2(11, -56), h + Vector2(14, -47)]), cb)
	DrawBatch.colored_polygon(ci, PackedVector2Array([h + Vector2(8.5, -49), h + Vector2(11, -53.5), h + Vector2(12.5, -48.5)]), Color(C_STRIPE, a * 0.8))
	# לסת תחתונה (נפתחת בזינוק / נשיכה)
	var jp := h + Vector2(4.0, -31.0)
	var jr := jaw * 0.6
	var jaw_pts := PackedVector2Array()
	for p: Vector2 in [Vector2(0, 0), Vector2(18, 0), Vector2(14, 5), Vector2(2, 4)]:
		jaw_pts.append(jp + p.rotated(jr))
	DrawBatch.colored_polygon(ci, jaw_pts, Color(C_FAR, a))
	if jaw > 0.2:   # שיניים
		DrawBatch.colored_polygon(ci, PackedVector2Array([h + Vector2(17, -32), h + Vector2(19, -32), h + Vector2(18, -27.5)]), Color(1, 1, 1, a))
		DrawBatch.colored_polygon(ci, PackedVector2Array([jp + Vector2(12, 0).rotated(jr), jp + Vector2(14, 0).rotated(jr), jp + Vector2(13, -4).rotated(jr)]), Color(1, 1, 1, a))
	DrawBatch.colored_polygon(ci, head, cb)
	DrawBatch.line(ci, h + Vector2(4, -49), h + Vector2(7, -44), cs, 2.0)   # פסים על המצח
	DrawBatch.line(ci, h + Vector2(9, -49), h + Vector2(10, -45), cs, 2.0)
	DrawBatch.line(ci, h + Vector2(-2, -42), h + Vector2(3, -38), cs, 2.0)
	DrawBatch.ellipse(ci, h + Vector2(21, -36), 3.2, 2.4, Color(C_STRIPE, a))   # אף
	DrawBatch.line(ci, h + Vector2(11, -42), h + Vector2(16, -41), Color(C_EYE, a), 2.4)   # עין (הזוהר ב-_glow)


# רגל: ירך -> ברך -> כף. ph = שלב הדהירה (0..1), side: 1 = קדמית, -1 = אחורית
static func _leg(ci: CanvasItem, base: Vector2, ph: float, run: float, stretch: float, side: float, crouch: float, col: Color) -> void:
	var a := TAU * ph
	var swing := sin(a) * 0.75 * run + stretch * 0.95 * side   # + = קדימה (בזינוק: קדמיות קדימה, אחוריות אחורה)
	var lift := maxf(0.0, -cos(a)) * 7.0 * run
	var hind := side < 0.0
	var up_len := 16.0 - crouch * 4.0
	var knee := base + Vector2.from_angle(PI * 0.5 - swing - (0.35 if hind else 0.0)) * up_len   # ירך אחורית נוטה קדימה
	var paw := knee + Vector2.from_angle(PI * 0.5 - swing * 0.4 + (0.4 if hind else -0.12)) * (15.0 - crouch * 3.0) + Vector2(0.0, -lift)
	DrawBatch.line(ci, base, knee, col, 8.0)
	DrawBatch.line(ci, knee, paw, col, 5.5)
	DrawBatch.ellipse(ci, paw + Vector2(2.0, -1.0), 4.2, 2.6, col)


func _draw_glow() -> void:
	DrawBatch.begin(_glow)
	if _alpha > 0.01:
		var xf := _xf()
		var a := _alpha
		var gs := SCALE * _grow   # הילה רכה סביב הגוף (שתי שכבות: רחבה וחלשה, צרה וחזקה יותר)
		DrawBatch.ellipse(_glow, xf * Vector2(4.0, -33.0), 62.0 * gs, 26.0 * gs, Color(0.15, 1.0, 0.4, 0.06 * a), _rot)
		DrawBatch.ellipse(_glow, xf * Vector2(4.0, -33.0), 48.0 * gs, 17.0 * gs, Color(0.15, 1.0, 0.4, 0.07 * a), _rot)
		DrawBatch.circle(_glow, xf * Vector2(46.0, -40.0), 16.0 * gs, Color(0.15, 1.0, 0.4, 0.08 * a))
		var ep := xf * Vector2(52.0, -41.0)   # עין בוערת
		DrawBatch.circle(_glow, ep, 7.0 * _grow, Color(0.5, 1.0, 0.6, 0.45 * a))
		DrawBatch.circle(_glow, ep, 2.6 * _grow, Color(C_EYE, 0.95 * a))
		if state == SUMMON and pl != null and is_instance_valid(pl):   # הגוף של השחקן בוער ירוק
			var k := sin(clampf(_st / SUMMON_T, 0.0, 1.0) * PI)
			DrawBatch.ellipse(_glow, pl.global_position + Vector2(0.0, -30.0), 22.0, 36.0, Color(0.2, 1.0, 0.45, 0.35 * k))
	for f: Array in _flames:   # להבות: טיפה שמצביעה למעלה, לבן-ירוק -> ירוק -> ירוק כהה ונעלם
		var u: float = float(f[3]) / float(f[2])
		var r: float = float(f[4]) * (1.0 - u * 0.65)
		var p: Vector2 = f[0]
		var fa := (1.0 - u) * (1.0 - u)
		var outer := Color(0.1, 0.85, 0.3, 0.32 * fa)
		var inner := Color(0.7, 1.0, 0.75, 0.75 * fa) if u < 0.35 else Color(0.3, 1.0, 0.45, 0.6 * fa)
		var wob := sin(_t * 18.0 + float(f[4]) * 7.0) * r * 0.4
		DrawBatch.colored_polygon(_glow, PackedVector2Array([p + Vector2(-r * 0.85, 0.0), p + Vector2(r * 0.85, 0.0), p + Vector2(wob, -r * 3.4)]), outer)
		DrawBatch.circle(_glow, p, r * 0.85, outer)
		DrawBatch.circle(_glow, p + Vector2(0.0, -r * 0.2), r * 0.5, inner)
	DrawBatch.end(_glow)


# אייקון (ביד / על הריצפה / בבר): ראש נמר ירוק עם להבה. s ~1 = 24 פיקסלים
static func draw_icon(ci: CanvasItem, c: Vector2, s: float, t: float) -> void:
	var fl := 0.85 + 0.15 * sin(t * 9.0)
	DrawBatch.circle(ci, c, 11.0 * s, Color(0.15, 0.9, 0.4, 0.22))
	DrawBatch.colored_polygon(ci, PackedVector2Array([c + Vector2(-6, 2) * s, c + Vector2(6, 2) * s, c + Vector2(1.5, -13.0 * fl) * s]), Color(0.3, 1.0, 0.5, 0.7))
	var h := PackedVector2Array()
	for p: Vector2 in [Vector2(-8, -4), Vector2(-5, -7), Vector2(5, -7), Vector2(8, -4), Vector2(8, 3), Vector2(4, 7), Vector2(-4, 7), Vector2(-8, 3)]:
		h.append(c + p * s)
	DrawBatch.colored_polygon(ci, PackedVector2Array([c + Vector2(-8, -4) * s, c + Vector2(-7, -10) * s, c + Vector2(-3, -6) * s]), C_BODY)
	DrawBatch.colored_polygon(ci, PackedVector2Array([c + Vector2(8, -4) * s, c + Vector2(7, -10) * s, c + Vector2(3, -6) * s]), C_BODY)
	DrawBatch.colored_polygon(ci, h, C_BODY)
	DrawBatch.line(ci, c + Vector2(0, -7) * s, c + Vector2(0, -3) * s, C_STRIPE, 1.6 * s)
	DrawBatch.line(ci, c + Vector2(-7, 0) * s, c + Vector2(-4, 1) * s, C_STRIPE, 1.4 * s)
	DrawBatch.line(ci, c + Vector2(7, 0) * s, c + Vector2(4, 1) * s, C_STRIPE, 1.4 * s)
	DrawBatch.circle(ci, c + Vector2(-3, -2) * s, 1.4 * s, C_EYE)
	DrawBatch.circle(ci, c + Vector2(3, -2) * s, 1.4 * s, C_EYE)
	DrawBatch.ellipse(ci, c + Vector2(0, 3) * s, 2.0 * s, 1.4 * s, C_STRIPE)
