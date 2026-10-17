extends "res://grenade.gd"
# ============================================================
#  GRAVITY GRENADE - פריט מיוחד (progression/arsenal.gd -> SPECIALS "gravity").
#  המראה: כמו רימוני החור השחור ב-THOR: THE DARK WORLD - כדור שחור עם שפה לבנה-כחולה מבהבת,
#  הילה כהה סביבו, חומר שנמתח ונשאב פנימה, זומבים שמחשיכים ונבלעים, ובסוף קריסה לנקודה והבזק.
#  נזרק כמו רימון. אחרי FUSE נפתח חור שחור קטן (Singularity) ל-PULL_T שניות:
#  כל זומבי בטווח PULL_R נשאב פנימה (מהר יותר ככל שהוא קרוב), מאבד שיווי משקל ונמעך.
#  בסוף: קריסה - פיצוץ סגול שפוגע בכל מי שנאסף במרכז וזורק אותם החוצה.
#  בוסים נמשכים חלש (BOSS_K). לשנות: PULL_R, PULL_V, PULL_T, CRUSH, BLAST_*.
# ============================================================

const PULL_R := 340.0       # טווח השאיבה
const PULL_V := 560.0       # מהירות שאיבה מקסימלית (בקצה החיצוני חלשה יותר)
const PULL_T := 1.9         # כמה זמן החור פתוח
const CORE := 26.0          # ליבה: מי שהגיע לכאן נתקע במרכז
const CRUSH := 3            # נזק כל CRUSH_TICK לזומבים שליד הליבה
const CRUSH_TICK := 0.2
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


# ---- החור השחור ----
class Singularity extends Node2D:
	const Boom := preload("res://explosion.gd")
	const Sfx := preload("res://sfx.gd")
	const Art := preload("res://art.gd")
	const GG := preload("res://weapons/gravity_grenade.gd")
	var _t := 0.0
	var _tick := 0.0
	var _done := false
	var _bits := []        # חומר שנשאב: [זווית, מרחק, מהירות, כהה?]
	var _caught := {}      # זומבים שנתפסו (מחשיכים ככל שהם קרובים; מחזירים צבע בסוף)
	var _arcs := []        # ברקים קצרים על השפה
	var _arc_t := 0.0
	var _seed := randf() * 100.0

	func _ready() -> void:
		z_index = 14   # מעל הזומבים: מי שמגיע למרכז נבלע בתוך השחור
		for i in 70:
			_bits.append([randf() * TAU, randf_range(GG.R_MAX, GG.PULL_R), randf_range(0.6, 1.4), randf() < 0.35])
		Sfx.play("lz_charge", global_position, 2.0, 0.0, 2, 0.4)   # זמזום עמוק שעולה
		Sfx.play("explosion", global_position, -12.0, 0.05, 4, 0.5)
		Game.make_noise(global_position, 500.0)
		var cam := get_viewport().get_camera_2d()
		if cam != null and cam.has_method("shake"):
			cam.shake(5.0, 0.3)

	# רדיוס הכדור: נפתח מנקודה, נושם, ובסוף קורס לנקודה
	func radius() -> float:
		var grow := 1.0 - pow(1.0 - clampf(_t / 0.22, 0.0, 1.0), 3.0)
		var left := GG.PULL_T - _t
		var shrink := clampf(left / GG.COLLAPSE_T, 0.0, 1.0)
		shrink = shrink * shrink
		return GG.R_MAX * grow * shrink * (1.0 + 0.04 * sin(_t * 23.0))

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
			if dist < GG.CORE:   # במרכז: נתקע בתוך השחור
				z.velocity = d * 8.0
			else:
				z.velocity = d / dist * pull + Vector2(0.0, -40.0)   # קצת הרמה - נגררים באוויר ולא נתקעים בריצפה
			z.stagger(0.3)
			var dk := clampf(1.0 - (dist - GG.R_MAX) / (GG.PULL_R * 0.6), 0.0, 1.0)   # מחשיך ככל שמתקרב
			var c := 1.0 - 0.75 * dk
			z.modulate = Color(c, c * 0.95, c + 0.1 * dk, z.modulate.a)
			if crush and dist < GG.CORE * 2.5:
				z.take_damage(GG.CRUSH, zc, d.normalized(), false, {"source": "grenade", "fixed": GG.CRUSH})
		for b in _bits:   # חומר מסתחרר פנימה, מאיץ ונמתח ליד השפה
			b[0] += delta * (1.5 + 300.0 / maxf(b[1], 20.0)) * b[2]
			b[1] -= delta * (120.0 + 1400.0 / maxf(b[1], 15.0)) * b[2]
			if b[1] < radius() * 0.9:
				b[0] = randf() * TAU
				b[1] = randf_range(GG.PULL_R * 0.55, GG.PULL_R)
		_arc_t -= delta
		if _arc_t <= 0.0:   # ברקים חדשים על השפה
			_arc_t = 0.05
			_arcs.clear()
			for i in randi_range(2, 5):
				var a0 := randf() * TAU
				var pts := PackedVector2Array()
				for j in 6:
					var aa := a0 + float(j) * 0.09
					pts.append(Vector2.from_angle(aa) * (1.0 + randf_range(0.0, 0.35)))
				_arcs.append(pts)
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
		var k := clampf(_t / 0.25, 0.0, 1.0)
		var r := radius()
		var fade := clampf((GG.PULL_T - _t) / GG.COLLAPSE_T, 0.0, 1.0)
		# 1. בור כבידה: הילה כהה שמחשיכה את מה שמסביב (עדשת כבידה)
		for i in 7:
			var rr := r * (1.25 + 0.32 * float(i)) + 6.0
			draw_circle(Vector2.ZERO, rr, Color(0.0, 0.0, 0.04, 0.11 * k * fade))
		# טבעת הטווח: עדינה, מתכווצת לאט (מראה מאיפה נשאבים)
		var rr2 := GG.PULL_R * (1.0 - 0.3 * _t / GG.PULL_T)
		draw_arc(Vector2.ZERO, rr2, 0.0, TAU, 72, Color(GG.COL, 0.1 * k * fade), 1.5, true)
		# 2. חומר שנשאב: פסים שנמתחים (ככל שקרוב - ארוך ודק יותר)
		for b in _bits:
			var dist: float = b[1]
			var ang: float = b[0]
			var stretch := clampf(900.0 / maxf(dist, 20.0), 4.0, 40.0)
			var p := Vector2.from_angle(ang) * dist
			var tail := Vector2.from_angle(ang - stretch / maxf(dist, 1.0) * 0.8) * (dist + stretch * 0.6)
			var near := clampf(1.0 - dist / GG.PULL_R, 0.0, 1.0)
			var col := Color(0.05, 0.04, 0.08, 0.8 * k) if b[3] else Color(GG.COL_HOT.lerp(GG.COL, 1.0 - near), (0.25 + 0.6 * near) * k)
			draw_line(tail, p, col, 1.0 + 1.5 * near, true)
		if r < 0.5:
			return
		# 3. דיסקת ספיחה: קשתות שמסתובבות מהר סביב השפה
		for i in 9:
			var rad := r * (1.08 + 0.07 * float(i % 5))
			var a0 := _t * (7.0 - 0.5 * float(i)) + float(i) * 1.7 + _seed
			var length := 0.6 + 0.5 * sin(_t * 3.0 + float(i))
			var cc := GG.COL.lerp(GG.DEEP, float(i % 3) / 3.0)
			draw_arc(Vector2.ZERO, rad, a0, a0 + length, 12, Color(cc, 0.55 * k), 1.6 + float(i % 2), true)
		# 4. הכדור השחור עם שפה רועדת
		var edge := PackedVector2Array()
		for j in 40:
			var a := float(j) / 40.0 * TAU
			var wob := 1.0 + 0.05 * sin(a * 5.0 + _t * 13.0) + 0.03 * sin(a * 9.0 - _t * 21.0)
			edge.append(Vector2.from_angle(a) * r * wob)
		Art.glow(self, Vector2.ZERO, r * 1.6, Color(GG.COL, 0.35 * k))
		draw_colored_polygon(edge, Color(0.0, 0.0, 0.02, 1.0))
		# מערבולת כהה בפנים (עומק)
		for i in 3:
			var a0 := -_t * (4.0 + float(i)) + float(i) * 2.1
			draw_arc(Vector2.ZERO, r * (0.35 + 0.2 * float(i)), a0, a0 + 2.2, 14, Color(GG.DEEP, 0.35), 2.0, true)
		# 5. אופק האירועים: שפה לבנה-כחולה מהבהבת (מתבהרת בקריסה)
		var fl := 0.7 + 0.3 * sin(_t * 40.0) + (1.0 - fade) * 0.6
		var rim := edge.duplicate()
		rim.append(edge[0])
		draw_polyline(rim, Color(GG.COL, 0.6 * fl), 4.0, true)
		draw_polyline(rim, Color(GG.COL_HOT, minf(fl, 1.0)), 1.6, true)
		# 6. ברקים קטנים שקופצים מהשפה
		for pts in _arcs:
			var sc := PackedVector2Array()
			for q in pts:
				sc.append(q * r)
			draw_polyline(sc, Color(GG.COL_HOT, 0.85 * k), 1.2, true)


# הקריסה: הבזק לבן מנקודה, גל הדף דק, ניצוצות
class Flash extends Node2D:
	const GG := preload("res://weapons/gravity_grenade.gd")
	const Art := preload("res://art.gd")
	const LIFE := 0.55
	var _t := 0.0
	var _sparks := []

	func _ready() -> void:
		z_index = 14
		for i in 18:
			_sparks.append([randf() * TAU, randf_range(250.0, 520.0)])
		var cam := get_viewport().get_camera_2d()
		if cam != null and cam.has_method("shake"):
			cam.shake(11.0, 0.35)

	func _process(delta: float) -> void:
		_t += delta
		if _t > LIFE:
			queue_free()
		queue_redraw()

	func _draw() -> void:
		var u := _t / LIFE
		var a := 1.0 - u
		var pop := clampf(1.0 - _t / 0.12, 0.0, 1.0)   # הבזק קצר וחזק
		Art.glow(self, Vector2.ZERO, 30.0 + 90.0 * pop + 40.0 * u, Color(GG.COL_HOT, 0.9 * maxf(pop, a * 0.4)))
		draw_circle(Vector2.ZERO, 10.0 * pop, Color(1, 1, 1, pop))
		# גל הדף: טבעת כהה עבה + קו בהיר דק (עיוות)
		var rw := GG.BLAST_R * (0.2 + 1.3 * sqrt(u))
		draw_arc(Vector2.ZERO, rw, 0.0, TAU, 64, Color(0.0, 0.0, 0.05, 0.35 * a), 10.0 * a + 1.0, true)
		draw_arc(Vector2.ZERO, rw + 4.0, 0.0, TAU, 64, Color(GG.COL_HOT, 0.8 * a), 1.6, true)
		for sp in _sparks:
			var d: float = sp[1] * u * (1.0 - 0.4 * u)
			var p := Vector2.from_angle(sp[0]) * d
			draw_line(p, p * 0.85, Color(GG.COL, a), 1.5, true)
