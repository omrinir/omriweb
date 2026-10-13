extends RefCounted
# ============================================================
#  EMPIRE KIT - כלים משותפים ל"אימפריית המתים" (שלבים 40-45).
#  הזומבים התארגנו: מדים, דרגות, דגלים אדומים - ומטרה אחת: לכבוש את העולם.
#  הסמל: אורובורוס - נחש עתיק שבולע את זנבו - סביב גולגולת, בשחור על עיגול לבן, על דגל אדום.
#    emblem(ci, c, r)                - הסמל
#    flag(ci, pole_top, w, h, t, s)  - דגל מתנופף על תורן (לצד ימין של התורן)
#    banner(ci, top, w, h, t)        - כרזה אנכית ענקית תלויה (על בניינים)
#    armband(ci, p, w)               - סרט זרוע אדום עם הסמל
#    helmet(ci, head, col)           - קסדה עגולה עם שוליים
#    fire(z, from, target, ...)      - ירייה של חייל (Shot של stationary_boss.gd)
#    order(z, kind, r)               - פקודה לכל חיילי האימפריה בטווח (type.on_order(kind, z))
#    squad_aim_y(main) / squad_miss(main, how) - "הם לומדים כקבוצה": גובה הכיוון המשותף לכל הרובאים בשלב
#  קבוצה: "empire" - כל זומבי של האימפריה (נכנס ב-setup של הסוג).
# ============================================================

const SB := preload("res://enemies/stationary_boss.gd")
const Art := preload("res://art.gd")

const RED := Color("b0181c")
const RED_D := Color("7a1014")
const UNIFORM := Color("4a4e3c")
const UNIFORM_D := Color("34382a")
const STEEL := Color("3a3e34")
const BRASS := Color("c8a040")


# ---- הסמל: אורובורוס סביב גולגולת ----
static func emblem(ci: CanvasItem, c: Vector2, r: float, bg := Color(0.95, 0.93, 0.88)) -> void:
	ci.draw_circle(c, r, bg)
	var black := Color("141010")
	var rr := r * 0.72
	var a0 := -PI * 0.5 + 0.3             # קצה הזנב (מימין למעלה)
	var a1 := a0 + TAU - 0.62             # הצוואר (משמאל למעלה)
	ci.draw_arc(c, rr, a0 + 0.25, a1, 28, black, r * 0.17)
	# זנב מתחדד שנכנס לפה
	var tail := PackedVector2Array()
	for q in 5:
		var u := float(q) / 4.0
		var a := a0 + 0.25 - u * 0.33
		var wdt := r * 0.085 * (1.0 - u)
		tail.append(c + Vector2.from_angle(a) * (rr + wdt))
	for q in range(4, -1, -1):
		var u := float(q) / 4.0
		var a := a0 + 0.25 - u * 0.33
		var wdt := r * 0.085 * (1.0 - u)
		tail.append(c + Vector2.from_angle(a) * (rr - wdt))
	ci.draw_colored_polygon(tail, black)
	# ראש הנחש: אליפסה לאורך המעגל, עין, לסת פתוחה סביב הזנב
	var ha := a1 + 0.2
	var hc := c + Vector2.from_angle(ha) * rr
	var tang := Vector2.from_angle(ha + PI * 0.5)   # כיוון ההתקדמות (עם השעון)
	ci.draw_colored_polygon(Art.ellipse(hc, r * 0.24, r * 0.15, tang.angle(), 12), black)
	var jaw := hc + tang * r * 0.16
	ci.draw_colored_polygon(PackedVector2Array([jaw + Vector2.from_angle(ha) * r * 0.1, jaw + tang * r * 0.1 + Vector2.from_angle(ha) * r * 0.06, jaw + tang * r * 0.02]), black)
	ci.draw_colored_polygon(PackedVector2Array([jaw - Vector2.from_angle(ha) * r * 0.1, jaw + tang * r * 0.1 - Vector2.from_angle(ha) * r * 0.06, jaw + tang * r * 0.02]), black)
	if r > 8.0:
		ci.draw_circle(hc + Vector2.from_angle(ha) * r * 0.05 + tang * r * 0.04, r * 0.035, bg)   # עין
		var q := a0 + 0.6
		while q < a1 - 0.1:   # קשקשים
			ci.draw_circle(c + Vector2.from_angle(q) * rr, r * 0.022, Color(bg, 0.55))
			q += 0.45
	# גולגולת
	var sk := c + Vector2(0, -r * 0.06)
	ci.draw_circle(sk, r * 0.32, black)
	ci.draw_rect(Rect2(sk + Vector2(-r * 0.18, r * 0.16), Vector2(r * 0.36, r * 0.2)), black)
	ci.draw_circle(sk + Vector2(-r * 0.12, -r * 0.01), r * 0.09, bg)
	ci.draw_circle(sk + Vector2(r * 0.12, -r * 0.01), r * 0.09, bg)
	ci.draw_colored_polygon(PackedVector2Array([sk + Vector2(0, r * 0.08), sk + Vector2(-r * 0.04, r * 0.15), sk + Vector2(r * 0.04, r * 0.15)]), bg)
	for q in 3:
		ci.draw_line(sk + Vector2(-r * 0.1 + float(q) * r * 0.1, r * 0.22), sk + Vector2(-r * 0.1 + float(q) * r * 0.1, r * 0.35), bg, maxf(r * 0.03, 1.0))


# ---- דגל מתנופף ----
static func flag(ci: CanvasItem, pole_top: Vector2, w: float, h: float, t: float, s := 0, with_emblem := true) -> void:
	var pts := PackedVector2Array()
	var n := 8
	for q in n + 1:   # קצה עליון
		var u := float(q) / float(n)
		pts.append(pole_top + Vector2(u * w, sin(t * 4.0 + u * 5.0 + float(s)) * h * 0.08 * u))
	for q in range(n, -1, -1):   # קצה תחתון
		var u := float(q) / float(n)
		pts.append(pole_top + Vector2(u * w, h + sin(t * 4.0 + u * 5.0 + float(s) + 0.6) * h * 0.08 * u))
	ci.draw_colored_polygon(pts, RED)
	ci.draw_line(pole_top + Vector2(0, 1), pole_top + Vector2(0, h - 1), RED_D, 2.0)   # שרוול לתורן
	if with_emblem:
		var c := pole_top + Vector2(w * 0.45, h * 0.5 + sin(t * 4.0 + 2.25 + float(s)) * h * 0.04)
		emblem(ci, c, h * 0.3)


# ---- כרזה אנכית ענקית ----
static func banner(ci: CanvasItem, top: Vector2, w: float, h: float, t: float) -> void:
	var sway := sin(t * 1.3 + top.x * 0.01) * w * 0.04
	var pts := PackedVector2Array([top + Vector2(-w * 0.5, 0), top + Vector2(w * 0.5, 0), top + Vector2(w * 0.5 + sway, h), top + Vector2(sway, h - w * 0.25), top + Vector2(-w * 0.5 + sway, h)])
	ci.draw_colored_polygon(pts, RED)
	ci.draw_line(top + Vector2(-w * 0.5 - 3.0, 0), top + Vector2(w * 0.5 + 3.0, 0), Color("2a2420"), maxf(w * 0.05, 2.0))
	ci.draw_line(top + Vector2(-w * 0.42, 2), top + Vector2(-w * 0.42 + sway * 0.8, h - w * 0.08), Color(0, 0, 0, 0.15), maxf(w * 0.04, 1.0))
	emblem(ci, top + Vector2(sway * 0.4, h * 0.3), w * 0.34)


# ---- סרט זרוע ----
static func armband(ci: CanvasItem, p: Vector2, w := 5.0) -> void:
	ci.draw_rect(Rect2(p - Vector2(w * 0.5, w * 0.35), Vector2(w, w * 0.7)), RED)
	ci.draw_circle(p, w * 0.22, Color(0.95, 0.93, 0.88))


# ---- קסדה ----
static func helmet(ci: CanvasItem, head: Vector2, col := STEEL) -> void:
	ci.draw_colored_polygon(PackedVector2Array([head + Vector2(-6.5, -1.5), head + Vector2(-5.5, -6.0), head + Vector2(0, -8.0), head + Vector2(5.5, -6.0), head + Vector2(7.0, -1.5)]), col)
	ci.draw_line(head + Vector2(-7.0, -1.2), head + Vector2(7.5, -1.2), col.darkened(0.3), 1.6)
	ci.draw_circle(head + Vector2(-2.5, -4.5), 1.2, RED)


# ---- ירייה של חייל ----
static func fire(z: Node, from: Vector2, target: Vector2, speed := 620.0, dmg := 1, col := Color(1.0, 0.85, 0.4), r := 4.0) -> Node:
	var s = SB.Shot.new()
	var tr := Tracker.new()   # פספוס -> כל הרובאים לומדים להקדים
	tr.z = z
	s.owner_t = tr
	s.velocity = (target - from).normalized() * speed
	s.damage = dmg
	s.kind = "bolt"
	s.col = col
	s.r = r
	z.get_parent().add_child(s)
	s.global_position = from
	return s


# ---- פקודות ----
static func order(z: Node, kind: String, r: float) -> int:
	var n := 0
	for o in z.get_tree().get_nodes_in_group("empire"):
		if o != z and not o.dead and o.global_position.distance_to(z.global_position) < r and o.type_mod != null and o.type_mod.has_method("on_order"):
			o.type_mod.on_order(kind, z)
			n += 1
	return n


# ---- למידה משותפת: כל הרובאים בשלב לומדים יחד איך אתה מתחמק ----
# קפצת מעל כדור -> כולם מכוונים גבוה יותר. התכופפת -> כולם מכוונים נמוך יותר. (y מעל הרגליים שלך)
static func squad_aim_y(main: Node) -> float:
	return float(main.get_meta("empire_aim_y")) if main.has_meta("empire_aim_y") else -26.0


static func squad_lead(main: Node) -> float:   # (לבדיקות - כמה הם "למדו": 0..1)
	return clampf(absf(squad_aim_y(main) + 26.0) / 24.0, 0.0, 1.0)


static func squad_miss(main: Node, how := "") -> void:
	var y := squad_aim_y(main)
	if how == "jump":
		y = maxf(y - 8.0, -54.0)
	elif how == "duck":
		y = minf(y + 6.0, -8.0)
	else:
		return
	main.set_meta("empire_aim_y", y)
	var n := int(main.get_meta("empire_learn_n")) + 1 if main.has_meta("empire_learn_n") else 1
	main.set_meta("empire_learn_n", n)
	var pl := main.get_tree().get_first_node_in_group("player")
	if n == 2 and pl != null:
		pl._say("THEY ALL LEARNED MY DODGE...", Color("ff8060"))


# מנהיג (קצין / נושא דגל / מתופף) מת - נספר. COMMISSAR (שלב 45) לומד: "אתה הורג קודם את המנהיגים"
static func leader_down(main: Node) -> void:
	main.set_meta("leaders_killed", (int(main.get_meta("leaders_killed")) if main.has_meta("leaders_killed") else 0) + 1)


static func leaders_killed(main: Node) -> int:
	return int(main.get_meta("leaders_killed")) if main.has_meta("leaders_killed") else 0


# כמה גבוה / נמוך: האם יש קו ראייה ישר (בגובה החזה) לשחקן
static func clear_shot(z: Node, from: Vector2, to: Vector2) -> bool:
	var q := PhysicsRayQueryParameters2D.create(from, to, 1)
	var ex: Array[RID] = [z.get_rid()]
	q.exclude = ex
	return z.get_world_2d().direct_space_state.intersect_ray(q).is_empty()


class Tracker extends RefCounted:   # מקבל מ-Shot אם פגע / פספס
	var z: Node = null

	func shot_result(hit: bool) -> void:
		if hit or z == null or not is_instance_valid(z) or z.get_parent() == null:
			return
		var pl := z.get_tree().get_first_node_in_group("player")
		if pl == null or pl.dead:
			return
		var how := ""
		if not pl.is_on_floor():
			how = "jump"
		elif pl._crouching:
			how = "duck"
		preload("res://enemies/empire_kit.gd").squad_miss(z.get_parent(), how)


# ---- גוף של חייל האימפריה (משותף לכל הסוגים) ----
# t = ה-type (בשביל col / feet), hf = לאן היד הקדמית (מקומי), hat = "helmet" / "cap" / "none" / "gasmask"
# מחזיר {sh, head, hip, hf} - כדי לצייר נשק / ציוד ביד
static func soldier(t, z: Node, hf_off: Vector2, hat := "helmet", coat := UNIFORM, back_off := Vector2(999, 0), stride := 4.5) -> Dictionary:
	var sk: Color = t.col(z.skin)
	var cc: Color = t.col(coat)
	var p: float = z._walk_phase
	var f: Array = t.feet(stride, 2.5)
	var hip := Vector2(0, -22)
	var sh := Vector2(1, -37)
	var head := sh + Vector2(3.5, -8)
	var boot: Color = t.col(Color("1a1816"))
	z._leg(hip + Vector2(-2, 0), f[1], t.col(Art.shade(coat, 0.3)), sk, boot)
	z._leg(hip + Vector2(2, 0), f[0], cc, sk, boot)
	var hb := sh + Vector2(-5.0 - sin(p) * 2.0, 15.0) if back_off.x > 900.0 else sh + back_off
	z._arm(sh + Vector2(-3, 1), hb, Art.shade(sk, 0.25), Art.shade(cc, 0.3))
	Art.fill_shaded(z, PackedVector2Array([sh + Vector2(-8, -1), sh + Vector2(8, 0), hip + Vector2(8, 5), hip + Vector2(-8, 5)]), cc, 0.12, 0.4)   # מעיל
	z.draw_line(sh + Vector2(1, 0), hip + Vector2(1.5, 4), cc.darkened(0.3), 1.0)
	z.draw_rect(Rect2(hip + Vector2(-8, -2), Vector2(16, 2.5)), t.col(Color("2a2018")))   # חגורה
	z.draw_circle(sh + Vector2(1.5, 4), 0.9, t.col(BRASS))
	z.draw_circle(sh + Vector2(1.6, 9), 0.9, t.col(BRASS))
	Art.oval_shaded(z, head, 5.2, 5.8, sk, 0.0)
	match hat:
		"helmet":
			helmet(z, head, t.col(STEEL))
		"cap":   # כובע קצינים: מצחייה שחורה, פס אדום, הסמל
			z.draw_colored_polygon(PackedVector2Array([head + Vector2(-6, -3), head + Vector2(-5, -8), head + Vector2(6, -9), head + Vector2(7, -4)]), t.col(UNIFORM_D))
			z.draw_rect(Rect2(head + Vector2(-6, -4.5), Vector2(13, 2)), t.col(RED))
			z.draw_rect(Rect2(head + Vector2(2, -3), Vector2(8, 1.6)), t.col(Color("141414")))
			z.draw_circle(head + Vector2(1, -6.5), 1.4, t.col(Color(0.92, 0.9, 0.85)))
		"gasmask":
			helmet(z, head, t.col(STEEL))
			z.draw_circle(head + Vector2(3.0, 1.5), 3.6, t.col(Color("2a2a2a")))
			z.draw_circle(head + Vector2(3.6, -0.8), 1.3, Color(0.6, 0.8, 0.5, 0.9))
			z.draw_rect(Rect2(head + Vector2(4.5, 2.5), Vector2(3, 3)), t.col(Color("3a3a3a")))
	if hat != "gasmask" and not z.dead:
		z.draw_circle(head + Vector2(3.0, -0.5), 1.1, Color(1.0, 0.25, 0.2))   # עיניים אדומות - "מאורגנים"
	armband(z, sh + Vector2(-4, 6), 4.5)
	var hf := sh + hf_off
	z._arm(sh + Vector2(3, 1), hf, sk, cc)
	return {"sh": sh, "head": head, "hip": hip, "hf": hf}


# רובה ביד (מכוון לכיוון aim המקומי)
static func rifle(z: Node, hf: Vector2, aim := Vector2.RIGHT, col := Color("2a2420")) -> void:
	var d := aim.normalized()
	z.draw_line(hf - d * 8.0, hf + d * 12.0, col, 2.4)   # גוף
	z.draw_line(hf + d * 12.0, hf + d * 17.0, Color("1a1a1a"), 1.4)   # קנה
	z.draw_line(hf - d * 8.0, hf - d * 8.0 + d.orthogonal() * -3.0, col, 2.0)   # קת
