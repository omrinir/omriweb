extends RefCounted
const DrawBatch := preload("res://effects/draw_batch.gd")
# ============================================================
#  "נשרף עד העצמות" (zombie.gd, מוות מאש): הזומבי נשאר לעמוד ובוער,
#  הגוף משחיר (CHAR_T), ואז נשאר רק שלד שמתפרק ונופל לערימה (FALL_T) עם ענן אפר.
#  הציור של שלב ההשחרה = הציור הרגיל של הזומבי (zombie.gd), כאן רק הצבעים.
#  לשנות: CHAR_T, FALL_T, BONE_COL, CHAR_COL.
# ============================================================

const Art := preload("res://art.gd")
const Particles := preload("res://particles.gd")
const Sfx := preload("res://sfx.gd")

const CHAR_T := 0.75
const FALL_T := 0.5
const BONE_COL := Color("cdbf9f")
const CHAR_COL := Color("1c1612")

var z: Node2D
var t := 0.0
var _skin0: Color
var _shirt0: Color
var _pants0: Color
var _hair0: Color
var _ashed := false
# עצם: [סוג, מרכז בעמידה, זווית בעמידה, אורך, מרכז בערימה, זווית בערימה]
# סוג: 0 = עצם ארוכה, 1 = גולגולת, 2 = בית חזה, 3 = אגן
var bones := []


func setup(zz: Node2D) -> void:
	z = zz
	_skin0 = z.skin
	_shirt0 = z.shirt
	_pants0 = z.pants
	_hair0 = z.hair
	var segs := [   # [סוג, a, b] בקואורדינטות של זומבי עומד (x קדימה, y למטה, 0 = כפות הרגליים)
		[1, Vector2(3, -50), Vector2(3, -50)],
		[2, Vector2(1, -40), Vector2(0, -28)],
		[0, Vector2(1, -41), Vector2(0, -23)],   # עמוד שדרה
		[3, Vector2(0, -23), Vector2(0, -23)],
		[0, Vector2(-2, -23), Vector2(-2, -11)], [0, Vector2(-2, -11), Vector2(-3, 0)],
		[0, Vector2(2, -23), Vector2(3, -11)], [0, Vector2(3, -11), Vector2(3, 0)],
		[0, Vector2(-1, -39), Vector2(-3, -30)], [0, Vector2(-3, -30), Vector2(-1, -22)],
		[0, Vector2(3, -39), Vector2(7, -31)], [0, Vector2(7, -31), Vector2(11, -25)],
	]
	for s in segs:
		var a: Vector2 = s[1]
		var b: Vector2 = s[2]
		var c := (a + b) * 0.5
		var ang := (b - a).angle() if a != b else 0.0
		var ln := a.distance_to(b)
		var lie := Vector2(randf_range(-13.0, 13.0), -randf_range(1.0, 2.5))
		if int(s[0]) == 1:   # הגולגולת מתגלגלת קצת רחוק יותר
			lie = Vector2(randf_range(10.0, 20.0) * (1.0 if randf() < 0.6 else -1.0), -4.0)
		elif int(s[0]) == 2:
			lie = Vector2(randf_range(-4.0, 4.0), -4.0)
		bones.append([int(s[0]), c, ang, ln, lie, randf_range(-0.35, 0.35) + (PI if randf() < 0.5 else 0.0)])


func skeleton() -> bool:
	return t >= CHAR_T


# מחזיר true אם צריך לצייר מחדש
func step(delta: float) -> bool:
	t += delta
	if t < CHAR_T:   # משחיר בהדרגה
		var k := clampf(t / CHAR_T, 0.0, 1.0)
		z.skin = _skin0.lerp(CHAR_COL, k)
		z.shirt = _shirt0.lerp(CHAR_COL, minf(1.0, k * 1.3))
		z.pants = _pants0.lerp(CHAR_COL, minf(1.0, k * 1.2))
		z.hair = _hair0.lerp(CHAR_COL, minf(1.0, k * 1.6))
		return true
	if not _ashed:   # הבשר נופל: ענן אפר וגחלים
		_ashed = true
		var p: Node = z.get_parent()
		var pos: Vector2 = z.global_position + Vector2(0.0, -30.0 * float(z.sc))
		Particles.burst(p, pos, "smoke", Vector2.UP, 18)
		Particles.burst(p, pos + Vector2(0.0, 10.0), "fire", Vector2.UP, 10)
		Sfx.play("corpse_splat", z.global_position, -6.0, 0.15, 3, 0.7)
	return t < CHAR_T + FALL_T + 0.1


func draw(ci: CanvasItem) -> void:
	var k := clampf((t - CHAR_T) / FALL_T, 0.0, 1.0)
	k = k * k   # מאיץ כמו נפילה
	var sx: float = float(z._dir) * float(z.wf)
	DrawBatch.set_transform(ci, Vector2.ZERO, 0.0, Vector2(sx * float(z.sc), float(z.sc)))
	# כתם פיח מתחת לערימה
	DrawBatch.colored_polygon(ci, Art.ellipse(Vector2(0, -0.5), 18.0, 2.4, 0.0, 14), Color(0.05, 0.04, 0.03, 0.55 * k))
	for b in bones:
		var c: Vector2 = (b[1] as Vector2).lerp(b[4], k)
		var ang: float = lerp_angle(b[2], b[5], k)
		var col := BONE_COL.darkened(0.25 * (1.0 - k) + 0.1)
		match int(b[0]):
			0:
				var d := Vector2.from_angle(ang) * float(b[3]) * 0.5
				DrawBatch.line(ci, c - d, c + d, col, 1.8, true)
				Art.disc(ci, c - d, 1.2, col, Art.NONE)
				Art.disc(ci, c + d, 1.2, col, Art.NONE)
			1:   # גולגולת: עיניים חלולות ולסת
				Art.oval(ci, c, 4.6, 5.0, col, ang * 0.3, Art.OUTLINE, 1.0)
				var r := Vector2.from_angle(ang * 0.3)
				var up := r.rotated(-PI / 2.0)
				Art.disc(ci, c + r * 1.8 - up * 0.2, 1.3, Color(0.08, 0.06, 0.05), Art.NONE)
				Art.disc(ci, c - r * 1.0 - up * 0.2, 1.1, Color(0.08, 0.06, 0.05), Art.NONE)
				DrawBatch.line(ci, c + up * -3.0 - r * 1.5, c + up * -3.0 + r * 2.5, Color(0.1, 0.08, 0.06), 1.0, true)
			2:   # צלעות
				var ax := Vector2.from_angle(ang)
				var nr := ax.rotated(PI / 2.0)
				for i in 4:
					var o := ax * (float(i) * 2.6 - 4.0)
					DrawBatch.line(ci, c + o - nr * 4.5, c + o + nr * 4.5, col, 1.3, true)
			3:   # אגן
				Art.oval(ci, c, 4.0, 2.4, col, ang, Art.OUTLINE, 1.0)
	DrawBatch.set_transform_matrix(ci, Transform2D.IDENTITY)
