extends RefCounted
# ============================================================
#  RAGDOLL - גופה רכה לזומבים אנושיים (במקום "בלוק" שמסתובב ונוחת תמיד באותה תנוחה).
#  11 מפרקים (ראש, צוואר, אגן, ברכיים, כפות רגליים, מרפקים, ידיים) מחוברים ב"עצמות".
#  פיזיקת Verlet פשוטה: כוח משיכה + עצמות + התנגשות בקרקע/קירות/קומות (קרן אחת לכל מפרק).
#  * המכה קובעת איך הוא נופל: ירייה בראש = הראש נזרק אחורה, פיצוץ = עף ומתגלגל,
#    ירייה מקרוב / חלשה = לפעמים מתקפל במקום (הברכיים נשברות קדימה).
#  * ביצועים: מדמה רק עד שהגופה נרגעת (בערך 1-2 שניות, מקסימום SIM_MAX), ואז קופאת
#    ורק מצוירת. גם בזמן הדמיה - 11 נקודות ו-11 קרניים לפריים לכל גופה.
#  לשנות: GRAV, ITER, FRICTION, BOUNCE, SIM_MAX.
# ============================================================

const Art := preload("res://art.gd")

const GRAV := 1300.0
const ITER := 4
const FRICTION := 0.93        # כמה מהירות נשארת לאורך הקרקע במגע (גופה מחליקה)
const BOUNCE := 0.22
const SIM_MAX := 4.0
enum { HEAD, NECK, PELVIS, KNEE_B, FOOT_B, KNEE_F, FOOT_F, ELBOW_B, HAND_B, ELBOW_F, HAND_F }

var z: Node2D
var p := PackedVector2Array()       # מיקום (קואורדינטות מקומיות של הזומבי)
var q := PackedVector2Array()       # מיקום קודם
var ground := PackedFloat32Array()  # גובה מגע אחרון לכל מפרק (INF = אין)
var ground_t := PackedFloat32Array() # כמה זמן עוד זוכרים את המגע (נופל מקצה = נשכח)
var rad := PackedFloat32Array()     # עובי כל מפרק (נח על הריצפה בלי לשקוע בה)
var bones := []                     # [a, b, אורך, סוג: 0 = קבוע, 1 = רק מינימום]
var asleep := false
static var active := 0              # כמה גופות מדומות עכשיו (הרבה ביחד = הדמיה זולה יותר)
var _counted := false
var t := 0.0
var _still := 0
var _blood_cd := 0.0
var headless := false
var one_leg := false


# vel = מהירות הגוף, dir = כיוון המכה, hit = איפה נפגע (גלובלי), boom = פיצוץ
func setup(zz: Node2D, vel: Vector2, dir: Vector2, hit: Vector2, boom: bool) -> void:
	z = zz
	headless = z._headless
	one_leg = z._one_leg
	var sx: float = z._dir * z.wf * z.sc
	var sy: float = z.sc
	var crouch: float = z._crouch_k
	var pose := [Vector2(3, -50), Vector2(2, -39), Vector2(0, -22 + crouch * 6.0),
		Vector2(-2, -11), Vector2(-3, 0), Vector2(4, -11), Vector2(3, 0),
		Vector2(-3, -30), Vector2(-2, -21), Vector2(7, -31), Vector2(11, -24)]
	if z.type_mod != null and z.type_mod.has_method("ragdoll_pose"):   # סוג עם פרופורציות אחרות (למשל רגלי קנגורו)
		pose = z.type_mod.ragdoll_pose()
	var lie: float = PI / 2.0 * z._lie_side if z._lying() else 0.0
	for v: Vector2 in pose:
		var lp := Vector2(v.x * sx, v.y * sy)
		if lie != 0.0:
			lp = (lp - Vector2(0, -9.0 * sy)).rotated(lie) + Vector2(0, -9.0 * sy)
		p.append(lp)
		ground.append(INF)
		ground_t.append(0.0)
	for r: float in [6.0, 4.0, 4.6, 3.4, 2.4, 3.6, 2.6, 2.6, 2.4, 2.8, 2.6]:
		rad.append(r * sy)
	for b in [[HEAD, NECK, 0], [NECK, PELVIS, 0], [PELVIS, KNEE_B, 0], [KNEE_B, FOOT_B, 0], [PELVIS, KNEE_F, 0], [KNEE_F, FOOT_F, 0],
			[NECK, ELBOW_B, 0], [ELBOW_B, HAND_B, 0], [NECK, ELBOW_F, 0], [ELBOW_F, HAND_F, 0],
			[HEAD, PELVIS, 1], [FOOT_B, PELVIS, 1], [FOOT_F, PELVIS, 1], [KNEE_B, KNEE_F, 1], [HAND_B, PELVIS, 1], [HAND_F, PELVIS, 1]]:
		var a: int = b[0]
		var c: int = b[1]
		var l := p[a].distance_to(p[c])
		if b[2] == 1:
			l *= 0.55 if a == HAND_B or a == HAND_F else (0.3 if a == KNEE_B else 0.8)
		bones.append([a, c, l, b[2]])
	# מהירות התחלתית: כל הגוף + דחיפה חזקה יותר למפרקים שקרובים למכה
	var dt := 1.0 / 60.0
	var lh: Vector2 = z.to_local(hit)
	var collapse := not boom and randf() < 0.3   # מתקפל במקום
	var base := vel * (0.2 if collapse else 0.8)
	if not collapse:   # עף מהרצפה (אחרת הרגליים "נדבקות" לקרקע והגוף רק מתקפל במקום)
		base.y = minf(base.y, -150.0)
	q.resize(p.size())
	for i in p.size():
		var v := base
		var near := clampf(1.0 - p[i].distance_to(lh) / (40.0 * float(z.sc)), 0.0, 1.0)
		v += dir.normalized() * near * (150.0 if not boom else 110.0)
		if boom:
			v += Vector2(randf_range(-160.0, 160.0), randf_range(-260.0, -60.0))
		else:
			v += Vector2(randf_range(-40.0, 40.0), randf_range(-40.0, 40.0))
		if collapse and (i == KNEE_B or i == KNEE_F):   # הברכיים נשברות קדימה
			v += Vector2(float(z._dir) * 140.0, 60.0)
		q[i] = p[i] - v * dt
		p[i].y -= 1.5   # מתחיל טיפה מעל הקרקע
		q[i].y -= 1.5
	if lh.y < -40.0 * float(z.sc) and not boom:   # ירייה בראש: הראש נזרק אחורה
		q[HEAD] = p[HEAD] - (dir.normalized() * 210.0 + base * 0.5) * dt


# מדמה צעד אחד. מחזיר true אם משהו זז (צריך לצייר מחדש)
func on_ground() -> bool:   # נקודה כלשהי של הגופה נוגעת בקרקע
	for gy in ground:
		if gy != INF:
			return true
	return false


func step(delta: float) -> bool:
	if asleep:
		return false
	if not _counted:
		_counted = true
		active += 1
	var busy := active > 12
	t += delta
	_blood_cd -= delta
	var dt := clampf(delta, 1.0 / 240.0, 1.0 / 30.0)
	var g := Vector2(0.0, GRAV * dt * dt)
	var space: PhysicsDirectSpaceState2D = z.get_world_2d().direct_space_state
	var origin: Vector2 = z.global_position
	var maxv := 0.0
	for i in p.size():
		ground_t[i] -= delta
		if ground_t[i] <= 0.0:
			ground[i] = INF
		var v := p[i] - q[i]
		v *= 0.8 if ground[i] != INF and v.length() < 2.5 else 0.995   # על הקרקע וכמעט עוצר: חיכוך חזק (נרגע)
		q[i] = p[i]
		var to := p[i] + v + g
		var from_g := origin + p[i]
		var to_g := origin + to
		var mask := 1 | (16 if to.y > p[i].y else 0)
		var hit := space.intersect_ray(PhysicsRayQueryParameters2D.create(from_g, to_g + Vector2(0.0, rad[i]) + (to_g - from_g).normalized() * 0.5, mask))
		if not hit.is_empty() and hit.normal != Vector2.ZERO:
			var n: Vector2 = hit.normal
			if hit.collider is CollisionObject2D and (hit.collider as CollisionObject2D).collision_layer & 1 == 0 and n.y > -0.5:
				p[i] = to   # קומה חד-כיוונית: נוגעים בה רק מלמעלה
			else:
				var hp: Vector2 = hit.position - origin + n * rad[i]
				var mv := to - p[i]
				var vn := n * mv.dot(n)
				var vt := mv - vn
				var speed := mv.length() / dt
				p[i] = hp
				q[i] = hp - (vt * FRICTION - vn * BOUNCE)
				if n.y < -0.5:
					ground[i] = hp.y
					ground_t[i] = 0.15
				if speed > 260.0 and _blood_cd <= 0.0 and hit.collider != null and hit.collider.has_method("add_blood"):
					_blood_cd = 0.15
					hit.collider.add_blood(hit.position, n, clampf(speed / 260.0, 1.0, 2.5))
		else:
			p[i] = to
		maxv = maxf(maxv, (p[i] - q[i]).length())
	for k in (2 if busy else ITER):
		for b in bones:
			var a: int = b[0]
			var c: int = b[1]
			var d := p[c] - p[a]
			var dist := maxf(d.length(), 0.001)
			if b[3] == 1 and dist >= b[2]:
				continue
			var diff: float = (dist - float(b[2])) / dist * 0.5
			p[a] += d * diff
			p[c] -= d * diff
		for i in p.size():   # לא נכנסים לריצפה שכבר נגענו בה
			if ground[i] != INF and p[i].y > ground[i]:
				p[i].y = ground[i]
	# אף מפרק לא עובר דרך קיר/ריצפה ביחס לאגן (העצמות יכולות "לדחוף" מפרק פנימה)
	var core := origin + p[PELVIS]
	for i in ([] if busy else [HEAD, HAND_B, HAND_F, FOOT_B, FOOT_F]):
		var hit := space.intersect_ray(PhysicsRayQueryParameters2D.create(core, origin + p[i] + Vector2(0.0, rad[i]), 1))
		if not hit.is_empty() and hit.normal != Vector2.ZERO:
			p[i] = hit.position - origin + (hit.normal as Vector2) * rad[i]
			if (hit.normal as Vector2).y < -0.5:
				ground[i] = p[i].y
				ground_t[i] = 0.15
	if maxv < 0.6 and t > 0.4:
		_still += 1
		if _still > 12:
			_sleep()
	else:
		_still = 0
	if t > SIM_MAX or (busy and t > SIM_MAX * 0.5):
		_sleep()
	return true


func _sleep() -> void:
	if not asleep:
		asleep = true
		if _counted:
			active -= 1


# הזומבי נמחק לפני שהגופה נרגעה
func release() -> void:
	_sleep()


func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE and _counted and not asleep:   # שלב נגמר / הזומבי נמחק באמצע
		asleep = true
		active -= 1


# ============================================================
#  ציור (בצבעים של הזומבי)
# ============================================================
func draw(ci: CanvasItem) -> void:
	if z.type_mod != null and z.type_mod.has_method("draw_ragdoll"):   # סוג שמצייר את הגופה שלו בעצמו
		z.type_mod.draw_ragdoll(ci, self)
		return
	var sc: float = z.sc
	var w: float = sqrt(float(z.wf))
	var sk: Color = z.skin
	var shirt: Color = z.shirt
	var pa: Color = z.pants
	var shoe: Color = z.shoe if z.shoe.a > 0.0 else z.skin
	var back := 0.25
	# צל רך מתחת לגופה
	var lo := minf(p[PELVIS].x, minf(p[HEAD].x, p[FOOT_F].x))
	var hi := maxf(p[PELVIS].x, maxf(p[HEAD].x, p[FOOT_F].x))
	var gy := (p[PELVIS].y if ground[PELVIS] == INF else ground[PELVIS]) + rad[PELVIS]
	ci.draw_colored_polygon(Art.ellipse(Vector2((lo + hi) * 0.5, gy + 1.0), (hi - lo) * 0.5 + 8.0 * sc, 3.0 * sc, 0.0, 14), Color(0, 0, 0, 0.25))
	# יד ורגל אחוריות (כהות יותר)
	_arm(ci, NECK, ELBOW_B, HAND_B, Art.shade(sk, back), Art.shade(shirt, back), 4.6 * sc * w)
	_leg(ci, KNEE_B, FOOT_B, Art.shade(pa, back), Art.shade(sk, back), Art.shade(shoe, back), 6.2 * sc * w)
	# גוף
	var axis := (p[PELVIS] - p[NECK]).normalized()
	var nrm := Vector2(-axis.y, axis.x) * 4.6 * sc * w
	var torso := PackedVector2Array([p[NECK] + nrm - axis * 2.0 * sc, p[NECK] - nrm - axis * 2.0 * sc, p[PELVIS] - nrm * 0.85, p[PELVIS] + nrm * 0.85])
	Art.fill_shaded(ci, torso, shirt, 0.15, 0.35)
	Art.disc(ci, p[PELVIS], 4.2 * sc * w, pa)
	if not one_leg:
		_leg(ci, KNEE_F, FOOT_F, pa, sk, shoe, 6.6 * sc * w)
	else:
		Art.disc(ci, p[PELVIS] + axis * 2.0, 3.0 * sc, Color(0.45, 0.02, 0.04))
	# ראש
	if headless:
		Art.disc(ci, p[NECK] - axis * 2.0 * sc, 2.6 * sc, Color(0.5, 0.03, 0.05))
	else:
		var hd := (p[HEAD] - p[NECK]).normalized()
		Art.limb(ci, PackedVector2Array([p[NECK], p[NECK].lerp(p[HEAD], 0.45)]), 3.6 * sc, sk)
		Art.oval_shaded(ci, p[HEAD], 6.0 * sc, 6.6 * sc, sk, hd.angle() + PI / 2.0)
		var side := Vector2(-hd.y, hd.x) * (1.0 if float(z._dir) > 0.0 else -1.0)
		var eye := p[HEAD] + side * 2.6 * sc + hd * 0.5 * sc
		ci.draw_line(eye + Vector2(-1.4, -1.4) * sc, eye + Vector2(1.4, 1.4) * sc, Color(0.1, 0.05, 0.05), 1.2)   # עין X
		ci.draw_line(eye + Vector2(-1.4, 1.4) * sc, eye + Vector2(1.4, -1.4) * sc, Color(0.1, 0.05, 0.05), 1.2)
		ci.draw_line(p[HEAD] + side * 3.5 * sc - hd * 2.5 * sc, p[HEAD] + side * 1.0 * sc - hd * 3.0 * sc, Color(0.25, 0.05, 0.05), 1.4)   # פה
	_arm(ci, NECK, ELBOW_F, HAND_F, sk, shirt, 5.0 * sc * w)


func _leg(ci: CanvasItem, knee: int, foot: int, pa: Color, sk: Color, shoe: Color, lw: float) -> void:
	var mid := p[knee].lerp(p[foot], 0.45)
	Art.limb(ci, PackedVector2Array([p[PELVIS], p[knee], mid]), lw, pa)
	Art.limb(ci, PackedVector2Array([mid, p[foot]]), lw * 0.75, sk)
	var fd := (p[foot] - p[knee]).normalized()
	var toe := Vector2(-fd.y, fd.x) * (1.0 if float(z._dir) > 0.0 else -1.0)
	Art.fill(ci, PackedVector2Array([p[foot] - fd * 2.0, p[foot] + toe * 6.0 * z.sc - fd * 1.0, p[foot] + toe * 6.0 * z.sc + fd * 2.0, p[foot] + fd * 2.0]), shoe, Art.OUTLINE, 1.0)


func _arm(ci: CanvasItem, sh: int, el: int, hd: int, sk: Color, sleeve: Color, aw: float) -> void:
	var cuff := p[sh].lerp(p[el], 0.7)
	Art.limb(ci, PackedVector2Array([cuff, p[el], p[hd]]), aw * 0.85, sk)
	Art.limb(ci, PackedVector2Array([p[sh], cuff]), aw, sleeve)
	Art.disc(ci, p[hd], aw * 0.5 + 0.6, sk)
