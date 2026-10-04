extends Node2D
# ============================================================
#  S7 CONTROL CONSOLE - לוח בקרה עם ידית (שלב 7)
#  מחובר בכבלים (שרואים!) למכונות בסביבה: מכבשים, צינורות קיטור, כבלי חשמל,
#  דלתות ותריסים (links). זומבי ENGINEER רץ אליו, מושך בידית:
#    begin_use() -> אזעקה + נורה אדומה מסתובבת + הידית יורדת
#    activate(x) -> "פולס" אור רץ לאורך הכבל אל המכונות שליד x, ורק כשהוא מגיע - trigger().
#  כך השחקן רואה מה עומד לקרות ויש לו זמן להגיב (הוגן).
#
#  * position = תחתית הלוח (על הריצפה / על גשר). group "s7_consoles".
#  * links נקבעים ב-levels/stage_7.gd (_link_consoles): כל מכונה triggerable בטווח.
#  איך משנים: cooldown (זמן בין הפעלות), radius ב-activate.
# ============================================================

const Art := preload("res://art.gd")
const Sfx := preload("res://sfx.gd")

var links: Array = []           # מכונות (environment/hazard.gd עם triggerable)
var cooldown := 5.0
var activations := 0            # לבדיקות
var _cd := 0.0
var _use := 0.0                 # > 0 = מישהו מושך בידית
var _pulses := []               # [מכונה, התקדמות 0..1]
var _t := 0.0


func _ready() -> void:
	add_to_group("s7_consoles")
	z_index = 0
	_t = randf() * 5.0


func ready_to_use() -> bool:
	return _cd <= 0.0 and _use <= 0.0 and _pulses.is_empty() and not links.is_empty()


# מכונות מחוברות שקרובות ל-x (בעולם)
func machines_near(x: float, radius: float) -> Array:
	var out := []
	for m in links:
		if is_instance_valid(m) and absf(m.world_rect().get_center().x - x) < radius:
			out.append(m)
	return out


func begin_use() -> void:
	_use = 0.9
	Sfx.play("s7_alarm", global_position, 0.0, 0.05, 2)


# מפעיל את המכונות שליד target_x (אם אין - את הקרובה ביותר). תריסים נפתחים תמיד.
func activate(target_x: float) -> int:
	var ms := machines_near(target_x, 300.0)
	if ms.is_empty():
		var best: Node = null
		var bd := INF
		for m in links:
			if is_instance_valid(m):
				var d := absf(m.world_rect().get_center().x - target_x)
				if d < bd:
					bd = d
					best = m
		if best != null:
			ms.append(best)
	for m in links:
		if is_instance_valid(m) and m.is_in_group("s7_gates") and not m.opened and not ms.has(m):
			ms.append(m)
	for m in ms:
		_pulses.append([m, 0.0])
	_cd = cooldown
	activations += 1
	Sfx.play("s7_lever", global_position, 0.0, 0.05, 2)
	return ms.size()


func _link_pt(m: Node) -> Vector2:
	var p: Vector2 = m.link_point() if m.has_method("link_point") else m.global_position + Vector2(0, -40)
	return p - global_position


# מסלול הכבל: למעלה מהלוח, לאורך "תעלת כבלים", ואז למטה אל המכונה
func _path(m: Node) -> PackedVector2Array:
	var e := _link_pt(m)
	var tray := minf(-80.0, e.y - 30.0)
	return PackedVector2Array([Vector2(0, -52), Vector2(0, tray), Vector2(e.x, tray), e])


func _process(delta: float) -> void:
	_t += delta
	_cd -= delta
	_use -= delta
	for p in _pulses:
		p[1] += delta / 0.5
		if p[1] >= 1.0 and is_instance_valid(p[0]):
			p[0].trigger()
	_pulses = _pulses.filter(func(p: Array) -> bool: return p[1] < 1.0 and is_instance_valid(p[0]))
	if Art.on_screen(self, global_position, 300.0) and (Engine.get_process_frames() % 4 == 0 or _use > 0.0 or not _pulses.is_empty()):
		queue_redraw()


func _point_on(path: PackedVector2Array, k: float) -> Vector2:
	var total := 0.0
	for i in path.size() - 1:
		total += path[i].distance_to(path[i + 1])
	var d := total * k
	for i in path.size() - 1:
		var sl := path[i].distance_to(path[i + 1])
		if d <= sl:
			return path[i].lerp(path[i + 1], d / maxf(sl, 0.01))
		d -= sl
	return path[path.size() - 1]


func _draw() -> void:
	# כבלים למכונות
	for m in links:
		if is_instance_valid(m):
			draw_polyline(_path(m), Color(0.07, 0.07, 0.08, 0.85), 2.5)
	for p in _pulses:
		if is_instance_valid(p[0]):
			var pt := _point_on(_path(p[0]), float(p[1]))
			Art.glow(self, pt, 12.0, Color(1.0, 0.5, 0.15, 0.9))
			draw_circle(pt, 2.5, Color(1.0, 0.85, 0.5))
	# עמוד + לוח
	var dark := Color("1e2024")
	draw_rect(Rect2(-6, -22, 12, 22), dark)
	Art.fill_shaded(self, PackedVector2Array([Vector2(-20, -54), Vector2(20, -54), Vector2(22, -22), Vector2(-22, -22)]), Color("3a4038"), 0.2, 0.4)
	# מסך
	var on := 0.6 + 0.4 * absf(sin(_t * 2.0))
	draw_rect(Rect2(-15, -50, 20, 13), Color(0.05, 0.12, 0.1))
	for i in 3:
		var lw := 6.0 + 10.0 * absf(sin(_t * 0.9 + float(i) * 1.7))
		draw_rect(Rect2(-13, -48 + i * 4, minf(lw, 16.0), 1.5), Color(0.3, 1.0, 0.7, 0.6 * on))
	# כפתורים
	for i in 3:
		var bc := Color(1.0, 0.3, 0.2) if i == 0 else (Color(1.0, 0.8, 0.2) if i == 1 else Color(0.3, 1.0, 0.4))
		var lit := fmod(_t * 1.5 + float(i) * 0.33, 1.0) < 0.5
		draw_circle(Vector2(-12 + i * 7, -29), 2.0, bc if lit else bc.darkened(0.6))
	# ידית: למעלה כרגיל, יורדת כשמושכים
	var a := -0.9 if _use <= 0.0 else lerpf(0.9, -0.9, clampf(_use / 0.9, 0.0, 1.0))
	var piv := Vector2(16, -40)
	var tip := piv + Vector2.from_angle(a - PI * 0.5) * 16.0
	draw_line(piv, tip, Color("8a9098"), 2.2)
	draw_circle(tip, 3.2, Color("b02a20"))
	draw_circle(piv, 2.2, dark)
	# נורת אזעקה למעלה
	var alarm := _use > 0.0 or not _pulses.is_empty()
	var bc2 := Vector2(-2, -60)
	draw_rect(Rect2(bc2.x - 4, bc2.y + 1, 8, 5), dark)
	draw_circle(bc2, 3.5, Color(1.0, 0.2, 0.1) if alarm else Color(0.35, 0.12, 0.08))
	if alarm:
		var ang := _t * 10.0
		draw_colored_polygon(PackedVector2Array([bc2, bc2 + Vector2.from_angle(ang - 0.3) * 80.0, bc2 + Vector2.from_angle(ang + 0.3) * 80.0]), Color(1.0, 0.2, 0.1, 0.16))
		Art.glow(self, bc2, 16.0, Color(1.0, 0.2, 0.1, 0.7))
	elif _cd > 0.0:
		draw_circle(bc2, 1.5, Color(1.0, 0.6, 0.2, 0.6))
