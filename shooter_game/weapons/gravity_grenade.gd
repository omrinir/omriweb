extends "res://grenade.gd"
# ============================================================
#  GRAVITY GRENADE - פריט מיוחד (progression/arsenal.gd -> SPECIALS "gravity").
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
const COL := Color(0.62, 0.42, 1.0)
const COL_HOT := Color(0.85, 0.75, 1.0)


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
	var _bits := []        # חלקיקים שנשאבים: [זווית, מרחק, מהירות]
	var _caught := {}      # זומבים שנתפסו (לניקוד / סאונד)

	func _ready() -> void:
		z_index = 2   # מאחורי הזומבים (3): רואים אותם נשאבים אל תוך החור
		for i in 46:
			_bits.append([randf() * TAU, randf_range(30.0, GG.PULL_R), randf_range(0.6, 1.4)])
		Sfx.play("lz_charge", global_position, 2.0, 0.0, 2, 0.45)   # זמזום עמוק שעולה
		Sfx.play("explosion", global_position, -10.0, 0.05, 4, 0.6)
		Game.make_noise(global_position, 500.0)

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
			if not _caught.has(z):
				_caught[z] = true
			var pull := GG.PULL_V * lerpf(1.0, 0.4, dist / GG.PULL_R) * k * (GG.BOSS_K if z.is_boss() else 1.0)
			if dist < GG.CORE:   # במרכז: נתקע ומסתובב
				z.velocity = d * 8.0
			else:
				z.velocity = d / dist * pull + Vector2(0.0, -40.0)   # קצת הרמה - נגררים באוויר ולא נתקעים בריצפה
			z.stagger(0.3)
			if crush and dist < GG.CORE * 2.5:
				z.take_damage(GG.CRUSH, zc, d.normalized(), false, {"source": "grenade", "fixed": GG.CRUSH})
		for b in _bits:   # חלקיקים מסתחררים פנימה
			b[0] += delta * (2.0 + 260.0 / maxf(b[1], 20.0)) * b[2]
			b[1] -= delta * (140.0 + 900.0 / maxf(b[1], 15.0)) * b[2]
			if b[1] < 8.0:
				b[0] = randf() * TAU
				b[1] = randf_range(GG.PULL_R * 0.6, GG.PULL_R)
		queue_redraw()

	func _collapse() -> void:
		if _done:
			return
		_done = true
		Boom.blast(get_parent(), global_position, GG.BLAST_R, 80.0, GG.BLAST_DMG, 1, "grenade")
		Sfx.play("lz_fire", global_position, 0.0, 0.0, 2, 0.6)
		var fl := Flash.new()
		fl.position = global_position
		get_parent().add_child(fl)
		queue_free()

	func _draw() -> void:
		var k := clampf(_t / 0.25, 0.0, 1.0)
		var end := clampf((GG.PULL_T - _t) / 0.3, 0.0, 1.0)
		var r_core := 18.0 * k * (0.6 + 0.4 * end) + 3.0 * sin(_t * 30.0) * k
		# טבעת הטווח: מתכווצת לאט (מראה לשחקן מאיפה נשאבים)
		var rr := GG.PULL_R * (1.0 - 0.25 * _t / GG.PULL_T)
		draw_arc(Vector2.ZERO, rr, 0.0, TAU, 64, Color(GG.COL, 0.18 * k), 2.0, true)
		# חלקיקים
		for b in _bits:
			var p: Vector2 = Vector2.from_angle(b[0]) * b[1]
			var tail: Vector2 = Vector2.from_angle(b[0] - 0.25) * (b[1] + 14.0)
			var a: float = clampf(1.0 - b[1] / GG.PULL_R, 0.1, 1.0) * k
			draw_line(tail, p, Color(GG.COL_HOT, 0.7 * a), 1.6, true)
		# זרועות ספירלה
		for arm in 4:
			var pts := PackedVector2Array()
			for i in 14:
				var u := float(i) / 13.0
				var ang := _t * 5.0 + float(arm) * TAU / 4.0 + u * 3.2
				pts.append(Vector2.from_angle(ang) * lerpf(r_core + 4.0, 120.0 * k, u))
			draw_polyline(pts, Color(GG.COL, 0.45 * k), 3.0, true)
		Art.glow(self, Vector2.ZERO, r_core * 3.2 + 8.0, Color(GG.COL, 0.55 * k))
		draw_circle(Vector2.ZERO, r_core + 4.0, Color(GG.COL_HOT, 0.8 * k))   # אופק אירועים זוהר
		draw_circle(Vector2.ZERO, r_core, Color(0.02, 0.0, 0.05, k))          # הליבה השחורה


# הבזק הקריסה: טבעת סגולה שמתרחבת
class Flash extends Node2D:
	const GG := preload("res://weapons/gravity_grenade.gd")
	const Art := preload("res://art.gd")
	var _t := 0.0

	func _ready() -> void:
		z_index = 14

	func _process(delta: float) -> void:
		_t += delta
		if _t > 0.45:
			queue_free()
		queue_redraw()

	func _draw() -> void:
		var u := _t / 0.45
		var a := 1.0 - u
		Art.glow(self, Vector2.ZERO, 40.0 + 120.0 * u, Color(GG.COL_HOT, 0.8 * a))
		draw_arc(Vector2.ZERO, GG.BLAST_R * (0.3 + 0.9 * u), 0.0, TAU, 48, Color(GG.COL, a), 6.0 * a + 1.0, true)
		draw_arc(Vector2.ZERO, GG.BLAST_R * (0.2 + 0.6 * u), 0.0, TAU, 40, Color(1, 1, 1, 0.7 * a), 2.0, true)
