extends "res://grenade.gd"
# ============================================================
#  GRAVITY GRENADE - פריט מיוחד (progression/arsenal.gd -> SPECIALS "gravity").
#  המראה: רק חלקיקים. מאות נקודות אור (כחול -> לבן) מסתחררות פנימה ומתכווצות, ענן חלקיקים כהים
#  יוצר את "החור" במרכז, זומבים מחשיכים ונבלעים. בסוף הכל נשאב לנקודה ומתפרץ החוצה כרסס ניצוצות.
#  נזרק כמו רימון. אחרי FUSE נפתח חור שחור קטן (Singularity) ל-PULL_T שניות:
#  כל זומבי בטווח PULL_R נשאב פנימה (מהר יותר ככל שהוא קרוב), מאבד שיווי משקל ונמעך.
#  בסוף: קריסה - פיצוץ סגול שפוגע בכל מי שנאסף במרכז וזורק אותם החוצה.
#  בוסים נמשכים חלש (BOSS_K). לשנות: PULL_R, PULL_V, PULL_T, CRUSH, BLAST_*.
# ============================================================

const PULL_R := 340.0       # טווח השאיבה
const PULL_V := 560.0       # מהירות שאיבה מקסימלית (בקצה החיצוני חלשה יותר)
const PULL_T := 1.9         # כמה זמן החור פתוח
const CORE := 26.0          # ליבה: מי שהגיע לכאן נתקע במרכז
const CRUSH := 8            # נזק כל CRUSH_TICK לזומבים שליד הליבה (פגיעות נדירות וחזקות = זול יותר מהרבה קטנות)
const CRUSH_TICK := 0.5
const BOSS_K := 0.3
const BLAST_R := 170.0
const BLAST_DMG := 60
const COL := Color(0.5, 0.72, 1.0)       # כחול-לבן של השפה
const COL_HOT := Color(0.92, 0.97, 1.0)
const DEEP := Color(0.28, 0.16, 0.55)     # סגול עמוק בתוך המערבולת
const R_MAX := 44.0                       # רדיוס הכדור השחור
const COLLAPSE_T := 0.28                  # הקריסה בסוף (מתוך PULL_T)


func _init() -> void:
	fuse = 0.9
	bounce = 0.3
	source = "grenade"


func _explode() -> void:
	var s := Singularity.new()
	s.position = global_position + Vector2(0.0, -26.0)   # באוויר מעל הנקודה - הזומבים נשאבים למרכז הגוף
	get_parent().add_child(s)
	queue_free()


func _draw() -> void:
	var t := Time.get_ticks_msec() / 1000.0
	Art.glow(self, Vector2.ZERO, 18.0, Color(COL, 0.55 + 0.25 * sin(t * 14.0)))
	Art.oval_shaded(self, Vector2.ZERO, 7.0, 7.0, Color("2a2440"), 0.0, Art.OUTLINE, 1.6)
	draw_arc(Vector2.ZERO, 4.5, t * 8.0, t * 8.0 + PI * 1.3, 10, COL_HOT, 1.6, true)   # טבעת אנרגיה מסתובבת
	Art.disc(self, Vector2.ZERO, 2.2, Color(COL_HOT, 0.9), Art.NONE)
	Art.fill(self, PackedVector2Array([Vector2(-2.5, -7.0), Vector2(2.5, -7.0), Vector2(2.5, -10.0), Vector2(-2.5, -10.0)]), Color("9a9aa2"), Art.OUTLINE, 1.0)


# אייקון (בר POWERS, הרצפה, ביד). s ~1 = 24 פיקסלים
static func draw_icon(ci: CanvasItem, c: Vector2, s: float, t: float) -> void:
	ci.draw_circle(c, 9.0 * s, Color(COL, 0.25))
	ci.draw_circle(c, 6.5 * s, Color("2a2440"))
	ci.draw_arc(c, 4.2 * s, t * 6.0, t * 6.0 + PI * 1.3, 10, COL_HOT, 1.5 * s, true)
	ci.draw_circle(c, 2.0 * s, COL_HOT)
	ci.draw_rect(Rect2(c + Vector2(-2.0, -9.5) * s, Vector2(4.0, 3.0) * s), Color("9a9aa2"))


# ---- ציור חלקיקים בקריאה אחת (מהיר: מאות חלקיקים = draw call אחד, בלי draw_circle) ----
# נקודה = מעוין קטן
static func _dot(pts: PackedVector2Array, cols: PackedColorArray, c: Vector2, r: float, col: Color) -> void:
	pts.append_array([c + Vector2(0, -r), c + Vector2(r, 0), c + Vector2(0, r), c + Vector2(0, -r), c + Vector2(0, r), c + Vector2(-r, 0)])
	for i in 6:
		cols.append(col)


# כתם רך = משושה שקוף בקצוות (לענן הכהה)
static func _blob(pts: PackedVector2Array, cols: PackedColorArray, c: Vector2, r: float, col: Color) -> void:
	var edge := Color(col, 0.0)
	for i in 6:
		pts.append_array([c, c + Vector2.from_angle(TAU * i / 6.0) * r, c + Vector2.from_angle(TAU * (i + 1) / 6.0) * r])
		cols.append_array([col, edge, edge])


# שובל = משולש מהראש (רחב) לזנב (שקוף)
static func _streak(pts: PackedVector2Array, cols: PackedColorArray, head: Vector2, tail: Vector2, w: float, col: Color) -> void:
	var n := (head - tail).orthogonal().normalized() * w
	pts.append_array([head + n, head - n, tail])
	cols.append_array([col, col, Color(col, 0.0)])


static func _flush(ci: CanvasItem, pts: PackedVector2Array, cols: PackedColorArray) -> void:
	if not pts.is_empty():
		RenderingServer.canvas_item_add_triangle_array(ci.get_canvas_item(), PackedInt32Array(), pts, cols)


# ---- החור השחור: רק חלקיקים ----
class Singularity extends Node2D:
	const Boom := preload("res://explosion.gd")
	const Sfx := preload("res://sfx.gd")
	const GG := preload("res://weapons/gravity_grenade.gd")
	const N_LIGHT := 150   # נקודות אור שנשאבות
	const N_DARK := 45     # ענן כהה שמסתובב במרכז ("החור")
	var _t := 0.0
	var _tick := 0.0
	var _done := false
	var _pts := []         # [זווית, מרחק, מהירות, כהה?, גודל, גיל]
	var _caught := {}      # זומבים שנתפסו (מחשיכים ככל שהם קרובים; מחזירים צבע בסוף)

	func _ready() -> void:
		z_index = 14   # מעל הזומבים: מי שמגיע למרכז נבלע בענן הכהה
		for i in N_LIGHT:
			_pts.append(_spawn(false, true))
		for i in N_DARK:
			_pts.append(_spawn(true, true))
		Sfx.play("lz_charge", global_position, 2.0, 0.0, 2, 0.4)   # זמזום עמוק שעולה
		Sfx.play("explosion", global_position, -12.0, 0.05, 4, 0.5)
		Game.make_noise(global_position, 500.0)
		var cam := get_viewport().get_camera_2d()
		if cam != null and cam.has_method("shake"):
			cam.shake(5.0, 0.3)

	# חלקיק חדש. אור: חצי בטבעת צפופה סביב החור (מסתובבת מהר), חצי נופל פנימה מבחוץ.
	# בהתחלה הכל נולד קרוב, כדי שהחור "יתפרץ" מהנקודה. כהה: צפוף במרכז
	func _spawn(dark: bool, first: bool) -> Array:
		var ring := not dark and randf() < 0.5
		var dist: float
		if dark:
			dist = GG.R_MAX * sqrt(randf())
		elif first:
			dist = randf_range(4.0, 60.0)
		elif ring:
			dist = randf_range(GG.R_MAX * 1.05, GG.R_MAX * 2.3)
		else:
			dist = randf_range(GG.PULL_R * 0.45, GG.PULL_R)
		var size := randf_range(6.0, 12.0) if dark else (randf_range(1.6, 3.2) if ring else randf_range(1.2, 2.4))
		return [randf() * TAU, dist, randf_range(0.7, 1.3), dark, size, 0.0, ring]

	# מהירות סיבוב (רדיאנים לשנייה) לפי המרחק מהמרכז
	func _spin(dist: float, ring: bool) -> float:
		return (2.6 if ring else 1.0) + 260.0 / maxf(dist, 14.0)

	# 0..1: כמה חזק החור עכשיו (נפתח מהר, ובקריסה נשאב פנימה)
	func _collapse_k() -> float:
		return 1.0 - clampf((GG.PULL_T - _t) / GG.COLLAPSE_T, 0.0, 1.0)

	func _physics_process(delta: float) -> void:
		_t += delta
		if _t >= GG.PULL_T:
			_collapse()
			return
		var k := clampf(_t / 0.25, 0.0, 1.0)   # נפתח מהר
		_tick -= delta
		var crush := _tick <= 0.0
		if crush:
			_tick = GG.CRUSH_TICK
		for z in get_tree().get_nodes_in_group("zombies"):
			if z.dead:
				continue
			var zc: Vector2 = z.global_position + Vector2(0.0, -28.0)
			var d := global_position - zc
			var dist := d.length()
			if dist > GG.PULL_R:
				continue
			_caught[z] = true
			var pull := GG.PULL_V * lerpf(1.0, 0.4, dist / GG.PULL_R) * k * (GG.BOSS_K if z.is_boss() else 1.0)
			if dist < GG.CORE:   # במרכז: נתקע בתוך הענן
				z.velocity = d * 8.0
			else:
				z.velocity = d / dist * pull + Vector2(0.0, -40.0)   # קצת הרמה - נגררים באוויר ולא נתקעים בריצפה
			z.stagger(0.3)
			var dk := clampf(1.0 - (dist - GG.R_MAX) / (GG.PULL_R * 0.6), 0.0, 1.0)   # מחשיך ככל שמתקרב
			var c := 1.0 - 0.75 * dk
			z.modulate = Color(c, c * 0.95, c + 0.1 * dk, z.modulate.a)
			if crush and dist < GG.CORE * 2.5:
				z.take_damage(GG.CRUSH, zc, d.normalized(), false, {"source": "grenade", "fixed": GG.CRUSH})
		# חלקיקים: מסתחררים פנימה, מהר יותר ככל שקרובים. בקריסה - הכל נשאב לנקודה ולא נולד מחדש
		var ck := _collapse_k()
		for p in _pts:
			p[5] += delta
			var dist: float = p[1]
			if p[3]:   # ענן כהה: מסלול צפוף סביב המרכז, מתכווץ בקריסה
				p[0] += delta * (3.0 + 40.0 / maxf(dist, 6.0)) * p[2]
				p[1] = maxf(dist + randf_range(-30.0, 30.0) * delta - ck * 260.0 * delta, 0.0)
				if p[1] > GG.R_MAX * 1.1 and ck <= 0.0:
					p[1] = GG.R_MAX * 0.6
				continue
			p[0] += delta * _spin(dist, p[6]) * p[2] * k
			if p[6]:   # טבעת: מסתובבת מהר ונכנסת לאט
				p[1] = dist - delta * (22.0 + ck * 900.0) * p[2] * k
			else:
				p[1] = dist - delta * (90.0 + 1300.0 / maxf(dist, 12.0) + ck * 900.0) * p[2] * k
			if p[1] < (GG.R_MAX * 0.8 if _t > 0.35 else 3.0):   # נבלע בחור
				if ck > 0.0:
					p[1] = 0.0
				else:
					var np := _spawn(false, false)
					for j in np.size():
						p[j] = np[j]
		queue_redraw()

	func _collapse() -> void:
		if _done:
			return
		_done = true
		for z in _caught:   # מי ששרד חוזר לצבע הרגיל
			if is_instance_valid(z):
				z.modulate = Color(1, 1, 1, z.modulate.a)
		Boom.blast(get_parent(), global_position, GG.BLAST_R, 80.0, GG.BLAST_DMG, 1, "grenade")
		Sfx.play("lz_fire", global_position, 0.0, 0.0, 2, 0.55)
		var fl := Flash.new()
		fl.position = global_position
		get_parent().add_child(fl)
		queue_free()

	func _draw() -> void:
		var ck := _collapse_k()
		var flat := Vector2(1.0, 0.8)   # מעט פחוס - מערבולת ולא עיגול
		var pts := PackedVector2Array()
		var cols := PackedColorArray()
		# קודם הענן הכהה (החור), מעליו נקודות האור
		for p in _pts:
			if not p[3] or p[1] <= 0.0:
				continue
			var pos: Vector2 = Vector2.from_angle(p[0]) * p[1] * flat
			var a: float = clampf(p[5] / 0.3, 0.0, 1.0) * (1.0 - ck * 0.5)
			GG._blob(pts, cols, pos, p[4] * 1.6 * (1.0 - 0.5 * ck), Color(0.02, 0.0, 0.05, 0.75 * a))
		for p in _pts:
			if p[3] or p[1] <= 0.0:
				continue
			var dist: float = p[1]
			var near := clampf(1.0 - (dist - GG.R_MAX) / (GG.PULL_R - GG.R_MAX), 0.0, 1.0)
			var size: float = p[4]
			var col := GG.COL.lerp(GG.COL_HOT, near * near)
			if int(p[2] * 10.0) % 4 == 0:
				col = GG.DEEP.lerp(GG.COL, near)   # חלק סגולים
			var a: float = clampf(p[5] / 0.25, 0.0, 1.0) * lerpf(0.35, 1.0, near)
			var pos: Vector2 = Vector2.from_angle(p[0]) * dist * flat
			# שובל לאורך המסלול, כך רואים את הסיבוב
			var back: float = _spin(dist, p[6]) * p[2] * 0.11
			var tail: Vector2 = Vector2.from_angle(p[0] - back) * (dist + (0.0 if p[6] else 22.0)) * flat
			GG._streak(pts, cols, pos, tail, size * 0.8, Color(col, 0.55 * a))
			GG._dot(pts, cols, pos, size * 1.2, Color(col, a))
		GG._flush(self, pts, cols)

# הקריסה: התפרצות חלקיקים החוצה (ניצוצות אור + מעט אבק כהה)
class Flash extends Node2D:
	const GG := preload("res://weapons/gravity_grenade.gd")
	const LIFE := 0.6
	var _t := 0.0
	var _p := []   # [מיקום, מהירות, גודל, כהה?]

	func _ready() -> void:
		z_index = 14
		for i in 90:
			var dark := i % 6 == 0
			var v := Vector2.from_angle(randf() * TAU) * randf_range(180.0, 720.0) * Vector2(1.0, 0.8)
			_p.append([Vector2.ZERO, v, randf_range(4.0, 8.0) if dark else randf_range(1.2, 3.0), dark])
		var cam := get_viewport().get_camera_2d()
		if cam != null and cam.has_method("shake"):
			cam.shake(11.0, 0.35)

	func _process(delta: float) -> void:
		_t += delta
		if _t > LIFE:
			queue_free()
			return
		for p in _p:
			p[0] += p[1] * delta
			p[1] *= 1.0 - 4.0 * delta   # גרר: מאט מהר
		queue_redraw()

	func _draw() -> void:
		var a := 1.0 - _t / LIFE
		var pts := PackedVector2Array()
		var cols := PackedColorArray()
		for p in _p:
			if p[3]:
				GG._blob(pts, cols, p[0], p[2] * 1.6 * (0.4 + 0.6 * a), Color(0.02, 0.0, 0.06, 0.6 * a))
			else:
				var col := Color(GG.COL_HOT.lerp(GG.COL, _t / LIFE), a)
				GG._streak(pts, cols, p[0], p[0] - p[1] * 0.03, p[2] * 0.7, col)
				GG._dot(pts, cols, p[0], p[2] * 1.2 * (0.4 + 0.6 * a), col)
		GG._flush(self, pts, cols)
