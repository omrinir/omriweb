extends "res://enemies/zombie_type.gd"
# ============================================================
#  DRILLER (שלב 18, "THE QUARRY") - זומבי שיושב בתוך מכונת קידוח (זחלים, תא נהג, מקדח ענק מקדימה).
#  מחזור:
#    DRIVE  - נוסע אליך לאט על הזחלים, המקדח מסתובב (נגיעה = נשיכה). אפשר לירות בו.
#    DIG    - מטה את המקדח למטה ונקדח לתוך האדמה (DIG_T): עפר עף, המכונה שוקעת.
#    UNDER  - מתחת לאדמה: רואים רק תל עפר וסדקים שזזים אליך (אי אפשר לפגוע בו).
#    WARN   - בדיוק מתחתיך: שנייה אחת של אזהרה (WARN_T) - עיגול אדום על הקרקע, "!", סדקים, רעידה. זוז!
#             המקום ננעל ברגע שהאזהרה מתחילה - מי שזז, ניצל.
#    ERUPT  - פורץ החוצה עם המקדח למעלה: מי שעומד מעל נפגע ונזרק לאוויר.
#    STUN   - נוחת על הצד, המנוע משתעל עשן (STUN_T): פגיעה = x1.5. החלון שלך.
#  בוס: "THE EXCAVATOR" - מכונה ענקית, התפרצות רחבה, וקודח שוב מהר.
#  צלילים: "dr_drill" (מקדח), "dr_rumble" (רעם מתחת לאדמה), "dr_burst" (התפרצות), "dr_cough" (מנוע משתעל).
#  לשנות: DIG_T, UNDER_SPEED, WARN_T, ERUPT_R, STUN_T, CD.
# ============================================================

const SOUNDS := {
	"dr_drill": [["Q", 140, 220, 0.0, 0.6, 0.05, 0.0, 0.25, 0.35, 0.08], ["N", 0, 0, 0.0, 0.6, 0.05, 0.0, 0.2, 0.5, 0]],
	"dr_rumble": [["S", 42, 30, 0.0, 1.0, 0.15, 1.5, 0.75, 1.0, 0.25], ["N", 0, 0, 0.0, 1.0, 0.1, 2.0, 0.5, 0.1, 0]],
	"dr_burst": [["N", 0, 0, 0.0, 0.5, 0.0, 5.0, 0.95, 0.3, 0], ["S", 70, 30, 0.0, 0.4, 0.0, 6.0, 0.85, 1.0, 0], ["C", 0, 0, 0.04, 0.45, 0.0, 5.0, 0.55, 1.0, 0]],
	"dr_cough": [["N", 0, 0, 0.0, 0.12, 0.0, 30.0, 0.45, 0.25, 0], ["N", 0, 0, 0.18, 0.12, 0.0, 30.0, 0.4, 0.25, 0], ["S", 60, 50, 0.0, 0.35, 0.0, 9.0, 0.3, 1.0, 0]],
}

const DRIVE_SPEED := 62.0
const DIG_T := 0.7
const UNDER_SPEED := 240.0
const WARN_T := 1.0          # שנייה של אזהרה לפני שהוא מגיח מתחתיך
const ERUPT_R := 44.0
const ERUPT_T := 0.55
const STUN_T := 1.5
const CD := Vector2(1.8, 3.2)
const DIG_RANGE := Vector2(110.0, 720.0)
const DIRT := Color("c9b088")
const DIRT_D := Color("8e7552")
const PAINT := Color("e2a224")
const GROUND := Color("a88c64")   # צבע האדמה מתחת לפני השטח (כמו effects/s18_decor.gd)

enum { DRIVE, DIG, UNDER, WARN, ERUPT, STUN }
var state := DRIVE
var erupts := 0             # לבדיקות
var hits := 0
var warned := 0
var _st := 0.0
var _cd := 1.5
var _spin := 0.0
var _tilt := 0.0            # 0 = מקדח קדימה, 1 = למטה, -1 = למעלה
var _sink := 0.0            # 0 = על הקרקע, 1 = מתחת
var _bits := []             # רסיסי עפר / אבנים [מיקום מקומי, מהירות, גיל]
var _target_x := 0.0
var _under_t := 0.0
var _snd := 0.0


func _boss() -> bool:
	return z != null and float(z.chase_range) > 600.0


func stats() -> Dictionary:
	if _boss():
		return {"name": "DRILLER", "hp": 240, "walk": 40.0, "chase": 70.0, "damage": 2, "bite_delay": 1.0, "scale": 1.9, "width": 1.3,
			"duck": 0.0, "cover": 0.0, "skin": Color("8aa070"), "shirt": Color("e2a224"), "pants": Color("3a3a3e"), "shoe": Color("202024"),
			"points": 900, "boss": true, "boss_name": "THE EXCAVATOR - MOVE WHEN THE GROUND SHAKES"}
	return {"name": "DRILLER", "hp": 70, "walk": 40.0, "chase": 70.0, "damage": 1, "bite_delay": 0.9, "scale": 1.0, "width": 1.25,
		"duck": 0.0, "cover": 0.0, "skin": Color("8aa070"), "shirt": Color("e2a224"), "pants": Color("3a3a3e"), "shoe": Color("202024"), "points": 520}


func brain_overrides() -> Dictionary:
	return {"aggression": 0.2}


func setup() -> void:
	_cd = randf_range(0.8, 2.0)


func can_bite() -> bool:
	return state == DRIVE


func can_groan() -> bool:
	return state == DRIVE or state == STUN


func death_sound() -> String:
	return "dr_burst"


func damage_mult(_zone: String, _src: Dictionary) -> float:
	return 1.5 if state == STUN else 1.0


func _radius() -> float:
	return ERUPT_R * (1.8 if _boss() else 1.0)


func physics(pl: Node, delta: float) -> bool:
	_st -= delta
	_cd -= delta
	_snd -= delta
	_tick_bits(delta)
	if z.dead:
		return false
	var spin_v := 0.0
	if not z.is_on_floor() and state != UNDER and state != WARN:
		z.velocity.y += z.gravity * delta
	var has_pl: bool = pl != null and not pl.dead
	var dx: float = (pl.global_position.x - z.global_position.x) if has_pl else 0.0
	match state:
		DRIVE:
			spin_v = 14.0
			_tilt = move_toward(_tilt, 0.0, delta * 3.0)
			_sink = move_toward(_sink, 0.0, delta * 3.0)
			var spd := 0.0
			if has_pl and absf(dx) < 900.0:
				z._dir = signf(dx) if dx != 0.0 else z._dir
				spd = DRIVE_SPEED * (0.8 if _boss() else 1.0)
				if absf(dx) < 26.0 * z.sc:
					spd = 0.0
				if _cd <= 0.0 and z.is_on_floor() and absf(dx) > DIG_RANGE.x and absf(dx) < DIG_RANGE.y and absf(pl.global_position.y - z.global_position.y) < 160.0:
					state = DIG
					_st = DIG_T
					spd = 0.0
					Sfx.play("dr_drill", z.global_position, 0.0, 0.08, 2)
			z.velocity.x = move_toward(z.velocity.x, z._dir * spd, 400.0 * delta)
			if randf() < delta * 3.0 and Art.on_screen(z, z.global_position):   # עשן מהצינור
				Particles.burst(z.get_parent(), z.global_position + Vector2(-14.0 * z._dir * z.wf, -62.0) * z.sc, "smoke", Vector2.UP, 1)
			if absf(z.velocity.x) > 5.0 and randf() < delta * 6.0:   # אבק מהזחלים
				_bits.append([Vector2(-20.0 * z.sc, -2.0), Vector2(-z._dir * randf_range(20, 60), randf_range(-60, -20)), 0.0])
		DIG:
			spin_v = 30.0
			z.velocity.x = 0.0
			var k := 1.0 - clampf(_st / DIG_T, 0.0, 1.0)
			_tilt = minf(1.0, k * 2.0)
			_sink = clampf(k * 1.3 - 0.3, 0.0, 1.0)
			if randf() < delta * 30.0:
				_bits.append([Vector2(randf_range(10, 30) * z.sc, -2.0), Vector2(randf_range(-120, 120), randf_range(-240, -90)), 0.0])
			if _st <= 0.0:
				state = UNDER
				_under_t = 0.0
				_sink = 1.0
				z.collision_layer = 0   # מתחת לאדמה: אי אפשר לפגוע בו
		UNDER:
			spin_v = 30.0
			_under_t += delta
			var spd2 := 0.0
			if has_pl:
				z._dir = signf(dx) if dx != 0.0 else z._dir
				spd2 = UNDER_SPEED * (0.8 if _boss() else 1.0)
				if absf(dx) < 12.0 or _under_t > 4.0:   # מתחתיך (או שהוא מחפש יותר מדי זמן) -> אזהרה
					_start_warn(pl)
					spd2 = 0.0
			elif _under_t > 3.0:
				_start_warn(null)
			z.velocity.x = move_toward(z.velocity.x, z._dir * spd2, 900.0 * delta)
			z.velocity.y = 0.0
			if _snd <= 0.0:
				_snd = 0.9
				Sfx.play("dr_rumble", z.global_position, -6.0, 0.1, 2)
		WARN:
			spin_v = 30.0
			z.velocity = Vector2.ZERO
			z.global_position.x = move_toward(z.global_position.x, _target_x, 600.0 * delta)
			if randf() < delta * 25.0:
				_bits.append([Vector2(randf_range(-_radius(), _radius()), -1.0), Vector2(randf_range(-20, 20), randf_range(-140, -50)), 0.0])
			if _st <= 0.0:
				_erupt(pl)
		ERUPT:
			spin_v = 22.0
			var k2 := 1.0 - clampf(_st / ERUPT_T, 0.0, 1.0)
			_tilt = -1.0 + k2 * 0.4
			_sink = 0.0   # קפץ החוצה מהאדמה
			z.velocity.x = 0.0
			if _st <= 0.0:
				state = STUN
				_st = STUN_T * (0.6 if _boss() else 1.0)
				Sfx.play("dr_cough", z.global_position, 0.0, 0.1, 2)
		STUN:
			spin_v = 3.0 if randf() < 0.5 else 0.0
			_tilt = move_toward(_tilt, 0.0, delta * 2.0)
			z.velocity.x = move_toward(z.velocity.x, 0.0, 600.0 * delta)
			if randf() < delta * 8.0:
				Particles.burst(z.get_parent(), z.global_position + Vector2(-z._dir * 10.0, -34.0) * z.sc, "smoke", Vector2.UP, 1)
			if _st <= 0.0:
				state = DRIVE
				_cd = randf_range(CD.x, CD.y) * (0.5 if _boss() else 1.0)
	_spin += spin_v * delta
	if state == UNDER or state == WARN:   # מתחת לאדמה: עובר מתחת למכשולים (בלי התנגשויות)
		z.global_position.x = clampf(z.global_position.x + z.velocity.x * delta, 40.0, float(z.world_w) - 40.0)
		return true
	z.move_and_slide()
	if z.is_on_floor():
		z._walk_phase += absf(z.velocity.x) * 0.075 / z.sc / 60.0
	return true


func _start_warn(pl: Node) -> void:
	state = WARN
	_st = WARN_T
	warned += 1
	_target_x = pl.global_position.x if pl != null else z.global_position.x
	Sfx.play("dr_rumble", Vector2(_target_x, z.global_position.y), 4.0, 0.1, 3)
	var cam: Node = z.get_viewport().get_camera_2d()
	if cam != null and cam.has_method("shake"):
		cam.shake(3.5, WARN_T)


func _erupt(pl: Node) -> void:
	state = ERUPT
	_st = ERUPT_T
	erupts += 1
	z.collision_layer = 4
	z.velocity.y = -360.0 * (0.8 if _boss() else 1.0)
	Sfx.play("dr_burst", z.global_position, 4.0, 0.1, 3)
	Particles.burst(z.get_parent(), z.global_position + Vector2(0, -6), "smoke", Vector2.UP, 14)
	for i in 14:
		_bits.append([Vector2(randf_range(-16, 16), -4.0), Vector2(randf_range(-150, 150), randf_range(-340, -140)), 0.0])
	var cam: Node = z.get_viewport().get_camera_2d()
	if cam != null and cam.has_method("shake"):
		cam.shake(7.0, 0.3)
	if pl != null and not pl.dead and absf(pl.global_position.x - z.global_position.x) < _radius() and absf(pl.global_position.y - z.global_position.y) < 60.0:
		hits += 1
		pl.hurt(z.damage, Vector2(signf(pl.global_position.x - z.global_position.x), -1.2))
		pl.velocity.y = minf(pl.velocity.y, -460.0)
	z._voice("zscream", 0.8, 3.0)


func _tick_bits(delta: float) -> void:
	for q in _bits:
		q[2] += delta
		q[1].y += 700.0 * delta
		q[0] += q[1] * delta
	_bits = _bits.filter(func(q: Array) -> bool: return q[2] < 0.9 and q[0].y < 4.0)
	if _bits.size() > 40:
		_bits = _bits.slice(_bits.size() - 40)


# ============================================================
#  ציור
# ============================================================
func draw() -> bool:
	var s: float = z.sc
	if state == UNDER or state == WARN:
		_draw_under(s)
		return true
	begin_draw(_sink < 0.3)
	var sink_y := _sink * 40.0
	if sink_y > 0.0:   # שוקע לתוך האדמה: חותכים מה שמתחת לקרקע (מציירים רק את מה שמעל)
		z.draw_set_transform(Vector2(0.0, sink_y * s), 0.0, Vector2(z._dir * z.wf * s, s))
	_draw_machine()
	end_draw()
	if sink_y > 0.0:   # מה שמתחת לקרקע מוסתר באדמה + תל עפר סביב החור
		z.draw_rect(Rect2(-48.0 * s, 0.0, 96.0 * s, 70.0 * s), GROUND)
		z.draw_rect(Rect2(-48.0 * s, 0.0, 96.0 * s, 6.0 * s), DIRT)
		z.draw_colored_polygon(_mound(30.0 * s * z.wf, 8.0 * s), DIRT)
	for q in _bits:
		z.draw_circle(q[0], 1.6 if int(q[1].x) % 2 == 0 else 2.4, Color(DIRT_D, 1.0 - q[2] / 0.9))
	return true


func _mound(w: float, h: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in 13:
		var u := float(i) / 12.0
		pts.append(Vector2((u - 0.5) * w * 2.0, -sin(u * PI) * h * (0.8 + 0.2 * sin(_spin + u * 9.0))))
	return pts


func _draw_under(s: float) -> void:
	# תל עפר שזז + סדקים מאחוריו
	z.draw_colored_polygon(_mound(20.0 * s, 7.0 * s), DIRT)
	z.draw_polyline(_mound(20.0 * s, 7.0 * s), DIRT_D, 1.2)
	for i in 4:
		var bx: float = -z._dir * (10.0 + float(i) * 9.0) * s
		z.draw_line(Vector2(bx, -1), Vector2(bx - z._dir * 7.0 * s, -1.0 - float(i % 2) * 2.0), Color(0.35, 0.25, 0.15, 0.8 - float(i) * 0.15), 1.4)
	if state == WARN:
		var k := 1.0 - clampf(_st / WARN_T, 0.0, 1.0)
		var r := _radius()
		var pulse := 0.5 + 0.5 * sin(k * 40.0)
		var off: float = _target_x - z.global_position.x
		z.draw_set_transform(Vector2(off, -1.0), 0.0, Vector2(1.0, 0.22))   # עיגול אזהרה אדום שטוח על הקרקע
		z.draw_circle(Vector2.ZERO, r, Color(1.0, 0.1, 0.05, 0.18 + 0.2 * pulse))
		z.draw_arc(Vector2.ZERO, r, 0.0, TAU, 28, Color(1.0, 0.2, 0.1, 0.9), 3.0)
		z.draw_arc(Vector2.ZERO, r * k, 0.0, TAU, 24, Color(1.0, 0.85, 0.3, 0.8), 2.0)   # טבעת שמתמלאת = הזמן שנשאר
		z.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		for i in 9:   # סדקים מתרחבים
			var a := -PI + float(i) * PI / 8.0
			var ln := r * (0.3 + 0.8 * k)
			z.draw_line(Vector2(off, -1), Vector2(off + cos(a) * ln, -1.0 - absf(sin(a)) * 3.0), Color(0.25, 0.15, 0.08, 0.9), 1.6)
		var ex := Vector2(off, -70.0 - 6.0 * pulse)   # "!" מעל המקום
		z.draw_circle(ex, 11.0, Color(1.0, 0.15, 0.1, 0.85))
		z.draw_rect(Rect2(ex + Vector2(-1.8, -7), Vector2(3.6, 9)), Color.WHITE)
		z.draw_circle(ex + Vector2(0, 5), 1.9, Color.WHITE)
		if k > 0.6:   # קצה המקדח מבצבץ
			var tip := (k - 0.6) / 0.4 * 12.0
			z.draw_colored_polygon(PackedVector2Array([Vector2(off - 6, 0), Vector2(off, -tip), Vector2(off + 6, 0)]), Color("b8bcc4"))


# המכונה (בקואורדינטות מקומיות: פונה ימינה, (0,0) = תחתית הזחלים)
func _draw_machine() -> void:
	var paint := col(PAINT)
	var dark := col(Art.shade(PAINT, 0.35))
	var steel := col(Color("8a9098"))
	var steel_d := col(Color("4e545c"))
	# זחלים
	var tr := Rect2(-22, -10, 40, 10)
	Art.fill_shaded(z, PackedVector2Array([Vector2(-20, -10), Vector2(16, -10), Vector2(20, -5), Vector2(16, 0), Vector2(-20, 0), Vector2(-24, -5)]), col(Color("2a2a2e")), 0.1, 0.3, Art.OUTLINE, 1.2)
	for i in 5:
		var wx := -18.0 + float(i) * 8.5
		Art.disc(z, Vector2(wx, -5), 3.2, steel_d)
		z.draw_line(Vector2(wx, -5), Vector2(wx, -5) + Vector2.from_angle(_spin * 0.4 + float(i)) * 2.6, steel, 1.0)
	var tread_off := fposmod(z._walk_phase * 6.0, 4.0)
	for i in 10:
		var tx := tr.position.x + 2.0 + float(i) * 4.0 + tread_off
		if tx < tr.end.x - 2.0:
			z.draw_line(Vector2(tx, -10), Vector2(tx, -9), Color(0.6, 0.6, 0.62), 1.0)
	# גוף
	var body := PackedVector2Array([Vector2(-22, -10), Vector2(14, -10), Vector2(16, -30), Vector2(-18, -32)])
	Art.fill_shaded(z, body, paint, 0.15, 0.45, Art.OUTLINE, 1.4)
	for i in 4:   # פסי אזהרה שחור-צהוב
		var hx := -16.0 + float(i) * 7.0
		z.draw_colored_polygon(PackedVector2Array([Vector2(hx, -10), Vector2(hx + 3, -10), Vector2(hx + 6, -15), Vector2(hx + 3, -15)]), col(Color("1e1e20")))
	for p in [Vector2(-18, -27), Vector2(10, -27), Vector2(-4, -27)]:   # ניטים
		z.draw_circle(p, 1.1, dark)
	# תא נהג עם הזומבי
	var cab := Rect2(-18, -50, 20, 19)
	Art.fill_shaded(z, PackedVector2Array([cab.position, cab.position + Vector2(cab.size.x, 2), cab.end, Vector2(cab.position.x, cab.end.y)]), dark, 0.1, 0.35, Art.OUTLINE, 1.2)
	var win := Rect2(-14, -47, 13, 11)
	z.draw_rect(win, Color(0.55, 0.75, 0.8, 0.55))
	var sk := col(z.skin)
	var head := Vector2(-7, -41)
	Art.oval_shaded(z, head, 4.2, 4.6, sk, 0.0)
	z.draw_rect(Rect2(head + Vector2(-4.5, -5.5), Vector2(9, 3)), col(Color("e8c020")))   # קסדה
	if not z.dead:
		z.draw_circle(head + Vector2(2.0, -0.5), 1.0, Color(1.0, 0.25, 0.15))
	z.draw_line(head + Vector2(0.5, 2.5), head + Vector2(3.5, 2.2), col(Color("2a0a0a")), 1.0)
	z.draw_line(win.position + Vector2(2, 1), win.position + Vector2(6, 9), Color(1, 1, 1, 0.5), 1.0)   # ברק זכוכית + סדק
	z.draw_line(win.position + Vector2(9, 2), win.position + Vector2(11, 7), Color(0.2, 0.2, 0.2, 0.7), 0.8)
	# צינור פליטה
	z.draw_line(Vector2(-14, -50), Vector2(-14, -60), steel_d, 3.0)
	# זרוע + מקדח (מסתובב לפי _tilt: 0 קדימה, 1 למטה, -1 למעלה)
	var piv := Vector2(14, -20)
	var ang := _tilt * PI * 0.5
	var t := Transform2D(ang, piv)
	Art.fill_shaded(z, t * PackedVector2Array([Vector2(-2, -5), Vector2(8, -5), Vector2(8, 5), Vector2(-2, 5)]), steel_d, 0.1, 0.3, Art.OUTLINE, 1.2)
	var cone := t * PackedVector2Array([Vector2(8, -9), Vector2(34, 0), Vector2(8, 9)])
	Art.fill_shaded(z, cone, steel, 0.2, 0.45, Art.OUTLINE, 1.3)
	for i in 5:   # ספירלה מסתובבת על המקדח
		var u := fposmod(float(i) / 5.0 + _spin * 0.25, 1.0)
		var x := 8.0 + u * 26.0
		var hw := 9.0 * (1.0 - u)
		z.draw_line(t * Vector2(x, -hw), t * Vector2(x + 4.0, hw), col(Color("3e434a")), 1.2)
