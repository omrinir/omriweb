extends RefCounted
const DrawBatch := preload("res://effects/draw_batch.gd")   # כל הציור של זומבי ב-draw call אחד
# ============================================================
#  קישוטים לשלב 32 ("DEVIL'S CARNIVAL") - הקרנבל של אורורו (בוליביה) בלילה: ריקוד הדיאבלדה.
#  כיכר קולוניאלית, כנסיית הסוקבון, פסל הבתולה על הגבעה, שרשראות נורות שמהבהבות בקצב, קשתות כסף,
#  זיקוקים בשמיים, קונפטי. התזמורת לא הפסיקה לנגן - והמתים רוקדים לפי הקצב.
#    carnival_sky   - (רקע) לילה סגול, כוכבים, זיקוקים שמתפוצצים
#    far_hills      - (רקע) גבעות עם אורות העיר ופסל הבתולה המואר
#    mid_town       - (רקע) בתים קולוניאליים צבעוניים עם מרפסות, הכנסייה, שרשראות נורות (מהבהבות בקצב)
#    near_crowd     - (רקע) קהל זומבים ביציעים שמנענע ראש בקצב, דגלים, בלונים
#    PlazaGround    - (עולם) אבני מרצפת, קונפטי וסרטים
#    Arch           - (עולם, מאחור) קשת קרנבל עם צלחות כסף נוצצות ואריגים
#    Facade         - (עולם, מאחור) חזית בית קולוניאלי עם מרפסת (הקומה עצמה = add_floor)
#    Castillo       - (עולם, מלכודת, קבוצה "castillos") מגדל זיקוקים מעץ: יורים בגלגלים -> 4 שניות של ניצוצות שורפות מסביב
#    Firecrackers   - (עולם, מלכודת) שרשרת נפצים על הרצפה: דורכים -> פיצוצים (נזק קטן, רעש, זומבים עפים)
#    Obstacle       - (מוצק + מחסה) "food_cart" עגלת אנטיקוצ'וס מעשנת / "bleachers" יציע עץ / "brass_drums" תופים
#    Band           - (קבוצה "band") התזמורת = המוזיקה של השלב: תוף, תובה, חצוצרות בקצב BPM. beat_id = מספר הפעמה
#    CarnivalFX     - (מסך) קונפטי נופל, מחוון קצב קטן למטה
#  לשנות: Band.BPM, Castillo.BURN_T / RADIUS, Firecrackers.
# ============================================================

const Art := preload("res://art.gd")
const Sfx := preload("res://sfx.gd")
const Kit := preload("res://effects/backdrop_kit.gd")
const Particles := preload("res://particles.gd")

const STONE := Color("6a6058")
const STONE_D := Color("3e3832")
const BULBS := [Color("ff4060"), Color("ffd040"), Color("40d0ff"), Color("60ff80"), Color("ff80ff")]


static func _rng(s: int) -> RandomNumberGenerator:
	var r := RandomNumberGenerator.new()
	r.seed = s
	return r


static func _h(i: int, s: int) -> float:
	return fposmod(sin(float(i) * 127.1 + float(s) * 311.7) * 43758.5453, 1.0)


static func band() -> Node:
	var tree := Engine.get_main_loop() as SceneTree
	return tree.get_first_node_in_group("band") if tree != null else null


static func pulse() -> float:   # 1 על הפעמה, יורד ל-0 עד הפעמה הבאה
	var b: Node = band()
	return 0.0 if b == null else b.pulse()


# ---- לילה + זיקוקים ----
static func carnival_sky(ci: CanvasItem, v: Vector2, t: float) -> void:
	Kit.gradient_sky(ci, v, [Color("0c0820"), Color("1e1240"), Color("3a1e50"), Color("6a2e4a"), Color("a04a3a")], 0.85)
	for i in 50:   # כוכבים
		var sx := fposmod(float(i) * 197.3, v.x)
		var sy := fposmod(float(i) * 73.1, v.y * 0.45)
		DrawBatch.circle(ci, Vector2(sx, sy), 1.0, Color(1, 1, 1, 0.3 + 0.3 * sin(t * 2.0 + float(i))))
	for k in 4:   # זיקוקים: כל אחד מתפוצץ במחזור משלו
		var per := 2.6 + float(k) * 0.7
		var cyc := floori((t + float(k) * 1.1) / per)
		var age := fposmod(t + float(k) * 1.1, per)
		var c: Color = BULBS[(cyc + k) % BULBS.size()]
		var cen := Vector2(v.x * (0.15 + 0.7 * _h(cyc * 7 + k, 3)), v.y * (0.12 + 0.25 * _h(cyc * 5 + k, 8)))
		if age < 0.5:   # עולה
			var p := cen + Vector2(0, (0.5 - age) * 400.0)
			DrawBatch.line(ci, p, p + Vector2(0, 14), Color(1, 0.9, 0.6, 0.8), 2.0)
		elif age < 2.0:
			var k2 := (age - 0.5) / 1.5
			var r := 20.0 + k2 * 90.0
			for q in 20:
				var a := float(q) * TAU / 20.0
				var p := cen + Vector2.from_angle(a) * r + Vector2(0, k2 * k2 * 40.0)
				DrawBatch.circle(ci, p, 2.2 * (1.0 - k2) + 0.6, Color(c, 1.0 - k2))
			if k2 < 0.25:
				DrawBatch.circle(ci, cen, 40.0 * (1.0 - k2 * 4.0), Color(c, 0.15))


# ---- גבעות, אורות העיר, פסל הבתולה ----
static func far_hills(ci: CanvasItem, sc: float, v: Vector2, y: float, t: float) -> void:
	var pts := PackedVector2Array()
	var x := -20.0
	while x <= v.x + 20.0:
		var u := x + sc
		pts.append(Vector2(x, y - 60.0 - sin(u * 0.004) * 40.0 - sin(u * 0.011 + 1.0) * 20.0))
		x += 20.0
	var poly := pts.duplicate()
	poly.append(Vector2(v.x + 20.0, v.y))
	poly.append(Vector2(-20.0, v.y))
	DrawBatch.colored_polygon(ci, poly, Color("1a1428"))
	for i in 40:   # אורות בתים על הגבעות
		var lx := fposmod(float(i) * 97.0 - sc, v.x + 100.0) - 50.0
		var ly := y - 20.0 - fposmod(float(i) * 31.0, 50.0)
		DrawBatch.circle(ci, Vector2(lx, ly), 1.3, Color(1.0, 0.8, 0.4, 0.7))
	var px := fposmod(900.0 - sc, 2600.0) - 300.0   # פסל הבתולה של הסוקבון על הגבעה
	var base := Vector2(px, y - 96.0)
	Art.glow(ci, base + Vector2(0, -40), 70.0, Color(0.6, 0.8, 1.0, 0.18))
	DrawBatch.colored_polygon(ci, PackedVector2Array([base + Vector2(-14, 0), base + Vector2(14, 0), base + Vector2(8, -50), base + Vector2(0, -62), base + Vector2(-8, -50)]), Color("e8eef8"))
	DrawBatch.circle(ci, base + Vector2(0, -66), 6.0, Color("e8eef8"))
	DrawBatch.arc(ci, base + Vector2(0, -67), 9.0, PI * 1.1, PI * 1.9, 10, Color(1.0, 0.9, 0.5, 0.8), 1.5)


# ---- בתים קולוניאליים, הכנסייה, שרשראות נורות ----
static func mid_town(ci: CanvasItem, sc: float, v: Vector2, y: float, t: float) -> void:
	var pl := pulse()
	var period := 1300.0
	var start := int(floor(sc / period)) - 1
	for k in range(start, start + int(ceil(v.x / period)) + 2):
		var x := float(k) * period - sc
		var r := _rng(k * 137 + 5)
		var bx := x
		for b in 5:   # שורת בתים
			var bw := r.randf_range(150.0, 230.0)
			var bh := r.randf_range(110.0, 170.0)
			var c: Color = [Color("6a5a8a"), Color("8a5a4a"), Color("4a6a7a"), Color("8a7a4a"), Color("5a7a5a")][r.randi() % 5].darkened(0.35)
			if b == 2 and k % 2 == 0:   # הכנסייה עם שני מגדלים
				var cw := 300.0
				DrawBatch.rect(ci, Rect2(bx, y - 170, cw, 170), Color("7a6a5a").darkened(0.3))
				for tw in [bx + 10.0, bx + cw - 60.0]:
					DrawBatch.rect(ci, Rect2(tw, y - 250, 50, 250), Color("8a7a6a").darkened(0.3))
					DrawBatch.colored_polygon(ci, PackedVector2Array([Vector2(tw - 4, y - 250), Vector2(tw + 25, y - 290), Vector2(tw + 54, y - 250)]), Color("5a4a3a"))
					DrawBatch.rect(ci, Rect2(tw + 17, y - 230, 16, 22), Color(1.0, 0.8, 0.4, 0.6))
					DrawBatch.line(ci, Vector2(tw + 25, y - 290), Vector2(tw + 25, y - 306), Color("e0d0a0"), 2.0)
					DrawBatch.line(ci, Vector2(tw + 19, y - 300), Vector2(tw + 31, y - 300), Color("e0d0a0"), 2.0)
				DrawBatch.colored_polygon(ci, PackedVector2Array([Vector2(bx + cw * 0.5 - 40, y), Vector2(bx + cw * 0.5 - 40, y - 70), Vector2(bx + cw * 0.5, y - 100), Vector2(bx + cw * 0.5 + 40, y - 70), Vector2(bx + cw * 0.5 + 40, y)]), Color(1.0, 0.75, 0.4, 0.55))
				DrawBatch.circle(ci, Vector2(bx + cw * 0.5, y - 130), 14.0, Color(1.0, 0.85, 0.5, 0.5))
				bx += cw + 10.0
				continue
			DrawBatch.rect(ci, Rect2(bx, y - bh, bw, bh), c)
			DrawBatch.rect(ci, Rect2(bx - 4, y - bh - 6, bw + 8, 6), c.darkened(0.3))
			for fl in 2:   # חלונות + מרפסות
				var wy := y - bh + 20.0 + float(fl) * (bh * 0.45)
				for wi in int(bw / 50.0):
					var wx := bx + 16.0 + float(wi) * 50.0
					var lit := _h(k * 31 + b * 7 + fl * 3 + wi, 2) < 0.6
					DrawBatch.rect(ci, Rect2(wx, wy, 18, 28), Color(1.0, 0.75, 0.4, 0.75) if lit else Color(0.1, 0.08, 0.12))
					if fl == 0:
						DrawBatch.rect(ci, Rect2(wx - 5, wy + 28, 28, 3), Color("2a2224"))
						for q in 4:
							DrawBatch.line(ci, Vector2(wx - 4 + float(q) * 8.0, wy + 31), Vector2(wx - 4 + float(q) * 8.0, wy + 40), Color("2a2224"), 1.0)
			bx += bw + r.randf_range(4.0, 14.0)
		# שרשראות נורות לרוחב
		for s in 3:
			var x0 := x + float(s) * 430.0
			var x1 := x0 + 400.0
			var sag := 40.0
			var prev := Vector2(x0, y - 150.0)
			for q in 17:
				var u := float(q) / 16.0
				var p := Vector2(lerpf(x0, x1, u), y - 150.0 + sin(u * PI) * sag)
				if q > 0:
					DrawBatch.line(ci, prev, p, Color(0.15, 0.12, 0.12), 1.0)
				var bc: Color = BULBS[(q + s + k) % BULBS.size()]
				var on := 0.45 + 0.55 * (pl if (q + s) % 2 == 0 else 1.0 - pl)
				DrawBatch.circle(ci, p + Vector2(0, 3), 2.6, Color(bc, on))
				if on > 0.8:
					DrawBatch.circle(ci, p + Vector2(0, 3), 6.0, Color(bc, 0.18))
				prev = p
	DrawBatch.rect(ci, Rect2(0, y, v.x, v.y - y), Color("1a1418"))


# ---- קהל זומבים ביציעים שמנענע ראש בקצב ----
static func near_crowd(ci: CanvasItem, sc: float, v: Vector2, y: float, t: float) -> void:
	var pl := pulse()
	var period := 900.0
	var start := int(floor(sc / period)) - 1
	for k in range(start, start + int(ceil(v.x / period)) + 2):
		var x := float(k) * period - sc
		var r := _rng(k * 53 + 11)
		var sx := x + r.randf_range(0.0, 200.0)
		var sw := r.randf_range(380.0, 560.0)
		for row in 3:   # יציע
			DrawBatch.rect(ci, Rect2(sx + float(row) * 12.0, y - 18.0 - float(row) * 18.0, sw - float(row) * 24.0, 5.0), Color("3a2a22"))
			var n := int((sw - float(row) * 24.0) / 26.0)
			DrawBatch.rect(ci, Rect2(sx + float(row) * 12.0 + 4.0, y - 30.0 - float(row) * 18.0, sw - float(row) * 24.0 - 8.0, 12.0), Color("241a20"))   # גופים (מלבן אחד)
			for q in n:
				var hx := sx + float(row) * 12.0 + 12.0 + float(q) * 26.0
				var bob := pl * 3.0 if (q + row) % 2 == 0 else 0.0
				var hy := y - 30.0 - float(row) * 18.0 + bob
				DrawBatch.circle(ci, Vector2(hx, hy - 4), 5.0, Color("2e2228"))
				if _h(k * 13 + row * 7 + q, 4) < 0.15:   # עיניים זוהרות
					DrawBatch.circle(ci, Vector2(hx + 2, hy - 5), 0.9, Color(0.9, 1.0, 0.5))
				if _h(k * 17 + row * 3 + q, 6) < 0.12:   # ידיים למעלה
					DrawBatch.line(ci, Vector2(hx - 5, hy + 2), Vector2(hx - 8, hy - 12 - bob), Color("2e2228"), 2.0)
		var fx := sx + sw + 60.0   # דגל בוליביה + בלונים
		DrawBatch.line(ci, Vector2(fx, y), Vector2(fx, y - 110), Color("3a3030"), 2.0)
		var wav := sin(t * 3.0 + float(k)) * 4.0
		for q in 3:
			DrawBatch.colored_polygon(ci, PackedVector2Array([Vector2(fx, y - 110 + float(q) * 9.0), Vector2(fx + 44, y - 110 + float(q) * 9.0 + wav), Vector2(fx + 44, y - 101 + float(q) * 9.0 + wav), Vector2(fx, y - 101 + float(q) * 9.0)]), [Color("d02a2a"), Color("f0d020"), Color("2a8a3a")][q])
		for q in 3:
			var bp := Vector2(sx + 40.0 + float(q) * 18.0, y - 140.0 + sin(t * 1.5 + float(q)) * 5.0)
			DrawBatch.line(ci, bp + Vector2(0, 9), Vector2(sx + 50.0, y - 60.0), Color(0.6, 0.6, 0.6, 0.4), 1.0)
			DrawBatch.colored_polygon(ci, Art.ellipse(bp, 7.0, 9.0, 0.0, 10), Color(BULBS[(q + k) % BULBS.size()], 0.85))
	DrawBatch.rect(ci, Rect2(0, y, v.x, v.y - y), Color("120e12"))


# ---- רחוב אבנים עם קונפטי ----
class PlazaGround extends Node2D:
	var w := 1024.0
	var depth := 90.0
	var seed_v := 0

	func _ready() -> void:
		z_index = 1

	func _draw() -> void:
		var r := RandomNumberGenerator.new()
		r.seed = seed_v
		var S := preload("res://effects/s32_decor.gd")
		DrawBatch.rect(self, Rect2(0, 0, w, depth), S.STONE_D)
		DrawBatch.rect(self, Rect2(0, 0, w, 9.0), S.STONE)
		var x := 0.0
		while x < w:   # אבני מרצפת
			var bw := r.randf_range(14.0, 22.0)
			DrawBatch.rect(self, Rect2(x + 1, 1, bw - 2, 7), S.STONE.lightened(r.randf_range(-0.08, 0.1)))
			x += bw
		for i in int(w / 6.0):   # קונפטי
			var c: Color = S.BULBS[r.randi() % S.BULBS.size()]
			DrawBatch.rect(self, Rect2(r.randf_range(0.0, w), r.randf_range(0.0, 6.0), 2.5, 1.5), Color(c, 0.85))
		for i in int(w / 200.0):   # סרטים
			var sx := r.randf_range(0.0, w - 40.0)
			var pts := PackedVector2Array()
			for q in 6:
				pts.append(Vector2(sx + float(q) * 7.0, 3.0 + sin(float(q) * 1.5 + sx) * 2.0))
			DrawBatch.polyline(self, pts, S.BULBS[r.randi() % S.BULBS.size()], 1.5)
		for i in int(w / 60.0):
			DrawBatch.colored_polygon(self, Art.ellipse(Vector2(r.randf_range(0.0, w), r.randf_range(16.0, depth - 6.0)), r.randf_range(5.0, 10.0), r.randf_range(3.0, 5.0), 0.0, 8), Color("2e2a26"))


# ---- קשת קרנבל עם צלחות כסף ----
class Arch extends Node2D:
	var w := 260.0
	var h := 230.0
	var seed_v := 0
	var _t := 0.0

	func _ready() -> void:
		z_index = -1

	func _process(delta: float) -> void:
		_t += delta
		if Engine.get_process_frames() % 6 == 0 and Art.on_screen(self, global_position + Vector2(w * 0.5, -h * 0.5), w):
			queue_redraw()

	func _draw() -> void:
		var r := RandomNumberGenerator.new()
		r.seed = seed_v
		var pl := preload("res://effects/s32_decor.gd").pulse()
		for px in [0.0, w - 16.0]:   # עמודים עטופים באריג
			DrawBatch.rect(self, Rect2(px, -h + 40.0, 16, h - 40.0), Color("5a3a2a"))
			for q in int((h - 40.0) / 14.0):
				DrawBatch.rect(self, Rect2(px, -h + 40.0 + float(q) * 14.0, 16, 7), [Color("c0264a"), Color("2a8a5a"), Color("e09a20"), Color("2a5ac0")][q % 4])
		var prev := Vector2(0, -h + 46.0)
		for q in 21:   # הקשת עם צלחות כסף
			var u := float(q) / 20.0
			var p := Vector2(u * w, -h + 46.0 - sin(u * PI) * 60.0)
			DrawBatch.line(self, prev, p, Color("8a7a5a"), 8.0)
			prev = p
			if q % 2 == 0:
				var shine := 0.5 + 0.5 * sin(_t * 2.0 + float(q))
				DrawBatch.circle(self, p, 7.0, Color("b8c0c8"))
				DrawBatch.circle(self, p + Vector2(-2, -2), 2.5, Color(1, 1, 1, 0.4 + 0.5 * shine * maxf(pl, 0.3)))
		var mid := Vector2(w * 0.5, -h + 46.0 - 60.0)   # מסכת שטן בראש הקשת
		Art.fill(self, PackedVector2Array([mid + Vector2(-16, 10), mid + Vector2(-20, -6), mid + Vector2(-28, -24), mid + Vector2(-12, -12), mid + Vector2(0, -16), mid + Vector2(12, -12), mid + Vector2(28, -24), mid + Vector2(20, -6), mid + Vector2(16, 10), mid + Vector2(0, 16)]), Color("c02a2a"), Art.OUTLINE, 1.5)
		DrawBatch.circle(self, mid + Vector2(-7, -2), 4.0, Color("f0f0e0"))
		DrawBatch.circle(self, mid + Vector2(7, -2), 4.0, Color("f0f0e0"))
		DrawBatch.circle(self, mid + Vector2(-7, -2), 1.8, Color(1.0, 0.2, 0.1))
		DrawBatch.circle(self, mid + Vector2(7, -2), 1.8, Color(1.0, 0.2, 0.1))
		for q in 5:   # אריגים תלויים
			var hx := w * (0.15 + 0.175 * float(q))
			var hy := -h + 46.0 - sin((hx / w) * PI) * 60.0
			DrawBatch.colored_polygon(self, PackedVector2Array([Vector2(hx - 9, hy + 4), Vector2(hx + 9, hy + 4), Vector2(hx + 7, hy + 34), Vector2(hx - 7, hy + 34)]), [Color("c0264a"), Color("e8c030"), Color("2a8a5a"), Color("6a3aa0"), Color("2a5ac0")][q])
			DrawBatch.line(self, Vector2(hx - 8, hy + 14), Vector2(hx + 8, hy + 14), Color(1, 1, 1, 0.5), 1.5)


# ---- חזית בית קולוניאלי עם מרפסת ----
class Facade extends Node2D:
	var w := 320.0
	var tier := 140.0
	var seed_v := 0

	func _ready() -> void:
		z_index = -1

	func _draw() -> void:
		var r := RandomNumberGenerator.new()
		r.seed = seed_v
		var c: Color = [Color("c08a6a"), Color("7a8ab0"), Color("a0b080"), Color("d0b070"), Color("b07a9a")][r.randi() % 5].darkened(0.25)
		var H := tier + 120.0
		DrawBatch.rect(self, Rect2(0, -H, w, H), c)
		DrawBatch.rect(self, Rect2(-6, -H - 8, w + 12, 10), c.darkened(0.35))   # כרכוב
		for i in int(w / 70.0):   # חלונות למטה וקומה עליונה
			var wx := 22.0 + float(i) * 70.0
			DrawBatch.rect(self, Rect2(wx, -86, 30, 60), Color(0.12, 0.08, 0.1))
			DrawBatch.rect(self, Rect2(wx, -86, 30, 6), c.darkened(0.4))
			DrawBatch.rect(self, Rect2(wx, -tier - 80, 30, 66), Color(1.0, 0.75, 0.42, 0.85) if r.randf() < 0.6 else Color(0.1, 0.08, 0.12))
			DrawBatch.line(self, Vector2(wx + 15, -tier - 80), Vector2(wx + 15, -tier - 14), c.darkened(0.4), 2.0)
		# מרפסת עץ מגולפת (הקומה שעליה עומדים)
		DrawBatch.rect(self, Rect2(-12, -tier, w + 24, 12), Color("5a3a24"))
		for q in int((w + 24.0) / 10.0):
			DrawBatch.line(self, Vector2(-12.0 + float(q) * 10.0, -tier), Vector2(-12.0 + float(q) * 10.0, -tier - 24.0), Color("6a4a2e"), 2.0)
		DrawBatch.rect(self, Rect2(-12, -tier - 26, w + 24, 4), Color("7a5a3a"))
		for q in int(w / 60.0):   # זיזים מתחת למרפסת
			DrawBatch.colored_polygon(self, PackedVector2Array([Vector2(10.0 + float(q) * 60.0, -tier + 12.0), Vector2(30.0 + float(q) * 60.0, -tier + 12.0), Vector2(18.0 + float(q) * 60.0, -tier + 30.0)]), Color("4a2e1e"))
		for q in 3:   # אריג תלוי מהמרפסת
			var ax := w * (0.2 + 0.3 * float(q))
			DrawBatch.colored_polygon(self, PackedVector2Array([Vector2(ax - 18, -tier - 22), Vector2(ax + 18, -tier - 22), Vector2(ax + 14, -tier + 24), Vector2(ax - 14, -tier + 24)]), [Color("c0264a"), Color("2a8a5a"), Color("e09a20")][q])
			for k in 3:
				DrawBatch.line(self, Vector2(ax - 15, -tier - 12.0 + float(k) * 12.0), Vector2(ax + 15, -tier - 12.0 + float(k) * 12.0), Color(1, 1, 1, 0.35), 1.5)


# ---- מגדל זיקוקים (קסטיו): יורים בגלגל -> ניצוצות שורפות מסביב ----
class Castillo extends Node2D:
	const BURN_T := 4.0
	const RADIUS := 150.0
	const H := 170.0
	var lit := false
	var spent := false
	var lights := 0              # לבדיקות
	var _t := 0.0
	var _tick := 0.0
	var _spark := 0.0

	func _ready() -> void:
		z_index = 0
		add_to_group("castillos")
		var body := WheelBody.new()   # רק הגלגלים למעלה (אפשר ללכת מתחת)
		body.owner_c = self
		body.collision_layer = 1
		body.collision_mask = 0
		body.add_to_group("no_outline")
		var cs := CollisionShape2D.new()
		var sh := RectangleShape2D.new()
		sh.size = Vector2(56, 70)
		cs.shape = sh
		cs.position = Vector2(0, -H + 30.0)
		body.add_child(cs)
		add_child(body)

	func light() -> void:
		if lit or spent:
			return
		lit = true
		lights += 1
		_t = BURN_T
		Sfx.play("c32_fuse", global_position + Vector2(0, -H), 4.0, 0.05, 2)
		Game.make_noise(global_position, 600.0)

	func _physics_process(delta: float) -> void:
		if not lit:
			return
		_t -= delta
		_tick -= delta
		_spark -= delta
		var cen := global_position + Vector2(0, -H + 30.0)
		if _spark <= 0.0 and Art.on_screen(self, cen, 200.0):
			_spark = 0.06
			Particles.burst(get_parent(), cen + Vector2(randf_range(-20, 20), randf_range(-20, 20)), "fire", Vector2.from_angle(randf() * TAU), 4)
			Particles.burst(get_parent(), cen, "spark", Vector2.ZERO, 3)
			if randf() < 0.15:
				Particles.burst(get_parent(), cen + Vector2(0, -20), "smoke", Vector2.UP, 2)
		if _tick <= 0.0:
			_tick = 0.25
			Sfx.play("c32_crackle", cen, -4.0, 0.2, 3)
			for z in get_tree().get_nodes_in_group("zombies"):   # הניצוצות שורפות זומבים
				if not z.dead and z.global_position.distance_to(global_position + Vector2(0, -20)) < RADIUS:
					z.take_damage(9 if not z.is_boss() else 5, z.global_position + Vector2(0, -30), (z.global_position - cen).normalized(), false, {"source": "fire"})
			var pl := get_tree().get_first_node_in_group("player")
			if pl != null and not pl.dead and pl.global_position.distance_to(global_position + Vector2(0, -20)) < RADIUS * 0.7:
				pl.hurt(1, Vector2(signf(pl.global_position.x - global_position.x), -0.5))
		queue_redraw()
		if _t <= 0.0:
			lit = false
			spent = true
			queue_redraw()

	func _draw() -> void:
		var wood := Color("6a4a2e") if not spent else Color("2a2018")
		DrawBatch.line(self, Vector2(-22, 0), Vector2(-6, -H), wood, 4.0)   # מגדל עץ
		DrawBatch.line(self, Vector2(22, 0), Vector2(6, -H), wood, 4.0)
		for q in 5:
			var yy := -float(q + 1) * H / 6.0
			var ww := 22.0 - float(q + 1) * 16.0 / 6.0
			DrawBatch.line(self, Vector2(-ww, yy), Vector2(ww, yy), wood, 2.0)
		var cen := Vector2(0, -H + 30.0)
		var spin := _t * 14.0 if lit else 0.0
		for wc in [cen, cen + Vector2(0, -32), cen + Vector2(0, 30)]:   # גלגלי זיקוקים
			var rr := 16.0 if wc == cen else 11.0
			DrawBatch.arc(self, wc, rr, 0.0, TAU, 14, wood.lightened(0.2), 2.0)
			for q in 6:
				var a := spin + float(q) * TAU / 6.0
				DrawBatch.line(self, wc, wc + Vector2.from_angle(a) * rr, wood.lightened(0.1), 1.5)
				if not spent:
					DrawBatch.circle(self, wc + Vector2.from_angle(a) * rr, 2.5, Color("c02a2a") if not lit else Color(1.0, 0.9, 0.4))
			if lit:   # ניצוצות מסתובבות
				for q in 6:
					var a := spin + float(q) * TAU / 6.0
					var tip: Vector2 = wc + Vector2.from_angle(a) * rr
					DrawBatch.line(self, tip, tip + Vector2.from_angle(a + PI * 0.5) * 26.0, Color(1.0, 0.8 - float(q % 3) * 0.2, 0.3, 0.8), 2.0)
		if lit:
			Art.glow(self, cen, preload("res://effects/s32_decor.gd").Castillo.RADIUS, Color(1.0, 0.6, 0.2, 0.12 + 0.05 * sin(_t * 30.0)))
		if not lit and not spent:   # פתיל + שלט
			DrawBatch.line(self, cen + Vector2(16, 0), cen + Vector2(26, 12), Color("c8b080"), 1.0)


class WheelBody extends StaticBody2D:   # הקליע פוגע בגלגלים -> המגדל נדלק
	var owner_c: Node = null

	func hit_by_bullet(_pos: Vector2, _normal: Vector2, _dir: Vector2) -> void:
		if owner_c != null:
			owner_c.light()


# ---- שרשרת נפצים: דורכים -> פיצוצים ----
class Firecrackers extends Node2D:
	var w := 70.0
	var popped := false
	var pops := 0                # לבדיקות
	var _t := 0.0
	var _pop := 0.0
	var _hurt_done := false

	func _ready() -> void:
		z_index = 2
		add_to_group("hazards")

	func world_rect() -> Rect2:
		return Rect2(global_position + Vector2(0, -24), Vector2(w, 24))

	func danger_at(p: Vector2, margin := 0.0) -> bool:
		return _t > 0.0 and world_rect().grow(margin).has_point(p)

	func _physics_process(delta: float) -> void:
		if popped and _t <= 0.0:
			return
		var r := world_rect()
		if not popped:
			var pl := get_tree().get_first_node_in_group("player")
			var trig: bool = pl != null and not pl.dead and pl.is_on_floor() and r.intersects(pl.body_rect())
			if not trig:
				for z in get_tree().get_nodes_in_group("zombies"):
					if not z.dead and z.is_on_floor() and r.has_point(z.global_position + Vector2(0, -4)):
						trig = true
						break
			if trig:
				popped = true
				_t = 1.0
				Game.make_noise(global_position, 500.0)
			return
		_t -= delta
		_pop -= delta
		if _pop <= 0.0:
			_pop = 0.07
			pops += 1
			var px := global_position.x + w * (1.0 - _t) + randf_range(-4, 4)
			Sfx.play("c32_pop", Vector2(px, global_position.y), -2.0, 0.25, 4)
			Particles.burst(get_parent(), Vector2(px, global_position.y - 4.0), "spark", Vector2.UP, 3)
			if randf() < 0.4:
				Particles.burst(get_parent(), Vector2(px, global_position.y - 6.0), "smoke", Vector2.UP, 1)
			var pl := get_tree().get_first_node_in_group("player")
			if not _hurt_done and pl != null and not pl.dead and absf(pl.global_position.x - px) < 26.0 and pl.global_position.y > global_position.y - 30.0:
				_hurt_done = true
				pl.hurt(1, Vector2(signf(pl.global_position.x - px) * 1.2, -1.0))
			for z in get_tree().get_nodes_in_group("zombies"):
				if not z.dead and not z.is_boss() and absf(z.global_position.x - px) < 24.0 and absf(z.global_position.y - global_position.y) < 30.0:
					z.take_damage(6, z.global_position + Vector2(0, -10), Vector2.UP, false, {"source": "fire"})
					z.velocity.y = -200.0
		queue_redraw()

	func _draw() -> void:
		var done := w * (1.0 - _t) if popped else 0.0
		DrawBatch.line(self, Vector2(0, -2), Vector2(w, -2), Color("6a5a3a"), 1.0)
		var n := int(w / 6.0)
		for q in n:
			var x := 3.0 + float(q) * 6.0
			if popped and x < done:
				DrawBatch.rect(self, Rect2(x - 2, -3, 4, 2), Color("2a2020"))   # שרוף
				continue
			DrawBatch.rect(self, Rect2(x - 1.6, -6.0 - float(q % 2) * 2.0, 3.2, 6), Color("d02a2a"))
			DrawBatch.line(self, Vector2(x, -6.0 - float(q % 2) * 2.0), Vector2(x, -8.0 - float(q % 2) * 2.0), Color("e0d0a0"), 1.0)


# ---- מכשולים ----
class Obstacle extends Node2D:
	var kind := "food_cart"
	var size := Vector2(90, 50)
	var seed_v := 0
	var _puff := 0.0

	func _ready() -> void:
		var body := StaticBody2D.new()
		body.collision_layer = 1
		body.add_to_group("no_outline")
		if size.y >= 30.0:
			add_to_group("cover")
		var cs := CollisionShape2D.new()
		var sh := RectangleShape2D.new()
		sh.size = size
		cs.shape = sh
		cs.position = Vector2(size.x * 0.5, -size.y * 0.5)
		body.add_child(cs)
		add_child(body)
		z_index = 1

	func cover_rect() -> Rect2:
		return Rect2(global_position + Vector2(0.0, -size.y), size)

	func _process(delta: float) -> void:
		if kind != "food_cart":
			return
		_puff -= delta
		if _puff <= 0.0 and Art.on_screen(self, global_position):
			_puff = 0.3
			Particles.burst(get_parent(), global_position + Vector2(size.x * 0.4 + randf_range(-6, 6), -size.y - 4.0), "smoke", Vector2(0.1, -1.0), 1)

	func _draw() -> void:
		var r := RandomNumberGenerator.new()
		r.seed = seed_v
		var w := size.x
		var h := size.y
		match kind:
			"food_cart":   # עגלת אנטיקוצ'וס עם גריל וגחלים
				Art.fill_shaded(self, PackedVector2Array([Vector2(4, -10), Vector2(w - 4, -10), Vector2(w - 4, -h + 10), Vector2(4, -h + 10)]), Color("3a6a9a"), 0.12, 0.35, Art.OUTLINE, 1.4)
				DrawBatch.rect(self, Rect2(8, -h + 12, w - 16, 6), Color("e0e0e0"))
				DrawBatch.rect(self, Rect2(10, -h + 2, w * 0.6, 8), Color("2a2a2a"))   # גריל
				for q in 5:
					DrawBatch.circle(self, Vector2(14.0 + float(q) * w * 0.11, -h + 4.0), 2.5, Color(1.0, 0.45 + 0.1 * float(q % 2), 0.15))
					DrawBatch.line(self, Vector2(12.0 + float(q) * w * 0.11, -h + 1.0), Vector2(20.0 + float(q) * w * 0.11, -h - 6.0), Color("8a6a4a"), 1.2)   # שיפודים
				Art.glow(self, Vector2(w * 0.35, -h + 4.0), 30.0, Color(1.0, 0.5, 0.2, 0.25))
				for wc in [Vector2(16, -5), Vector2(w - 16, -5)]:
					DrawBatch.circle(self, wc, 6.0, Art.OUTLINE)
					DrawBatch.circle(self, wc, 4.5, Color("3a3a3a"))
				DrawBatch.line(self, Vector2(w - 4, -h + 16), Vector2(w + 10, -h + 8), Color("4a4a4a"), 2.0)   # ידית
			"bleachers":   # יציע עץ קטן
				for q in 3:
					var yy := -h * (0.33 * float(q + 1))
					DrawBatch.rect(self, Rect2(float(q) * w * 0.12, yy, w - float(q) * w * 0.24, 6), Color("8a6a3a"))
					DrawBatch.line(self, Vector2(float(q) * w * 0.12 + 4.0, yy), Vector2(float(q) * w * 0.12 + 4.0, 0), Color("5a4024"), 3.0)
					DrawBatch.line(self, Vector2(w - float(q) * w * 0.12 - 4.0, yy), Vector2(w - float(q) * w * 0.12 - 4.0, 0), Color("5a4024"), 3.0)
				for q in 3:   # כוסות וזבל
					DrawBatch.rect(self, Rect2(r.randf_range(4.0, w - 10.0), -h * 0.33 - 6.0, 4, 6), Color("e0e0e0"))
			_:   # תופי בומבו
				for q in 2:
					var c := Vector2(w * (0.28 + 0.44 * float(q)), -h * 0.45)
					Art.fill_shaded(self, Art.ellipse(c, w * 0.24, h * 0.45, 0.0, 14), [Color("c02a2a"), Color("2a5ac0")][q], 0.15, 0.4, Art.OUTLINE, 1.4)
					DrawBatch.colored_polygon(self, Art.ellipse(c + Vector2(-w * 0.04, 0), w * 0.14, h * 0.38, 0.0, 12), Color("e8e0d0"))
					for k in 5:
						var a := float(k) * TAU / 5.0
						DrawBatch.line(self, c + Vector2.from_angle(a) * Vector2(w * 0.22, h * 0.42), c + Vector2.from_angle(a + 0.6) * Vector2(w * 0.22, h * 0.42), Color("e0c040"), 1.2)


# ============================================================
#  התזמורת: המוזיקה של השלב, לפי פעמות. beat_id עולה בכל פעמה. pulse() = 1 על הפעמה.
#  מחזור של 4 פעמות: תוף + תובה / תוף סנר + חצוצרות / תוף + תובה / סנר + חצוצרות (מרש של דיאבלדה)
# ============================================================
class Band extends Node:
	const BPM := 104.0
	var beat_id := 0
	var playing := true
	var _t := 0.0

	func _ready() -> void:
		add_to_group("band")

	func beat_len() -> float:
		return 60.0 / BPM

	func pulse() -> float:
		return clampf(1.0 - _t / (beat_len() * 0.6), 0.0, 1.0)

	func _physics_process(delta: float) -> void:
		_t += delta
		if _t < beat_len():
			return
		_t -= beat_len()
		beat_id += 1
		if not playing:
			return
		var b := beat_id % 4
		var vol := -7.0
		match b:
			0:
				Sfx.play("c32_kick", null, vol, 0.0, 2)
				Sfx.play("c32_tuba", null, vol - 1.0, 0.0, 2)
				if beat_id % 16 == 0:
					Sfx.play("c32_cym", null, vol - 3.0, 0.0, 2)
			1, 3:
				Sfx.play("c32_snare", null, vol - 2.0, 0.05, 2)
				Sfx.play("c32_brass" if (beat_id / 4) % 2 == 0 else "c32_brass2", null, vol - 2.0, 0.0, 2)
			2:
				Sfx.play("c32_kick", null, vol, 0.0, 2)
				Sfx.play("c32_tuba", null, vol - 1.0, 0.0, 2, 0.75)


# ---- קונפטי + מחוון קצב (מסך) ----
class CarnivalFX extends Node2D:
	var vp := Vector2(1280, 720)
	var floor_y := 630.0         # הקרקע בעולם: הקונפטי נוחת עליה (לא נופל עד תחתית המסך)
	var _t := 0.0
	var _c := []

	func _ready() -> void:
		var r := RandomNumberGenerator.new()
		r.seed = 32
		for i in 60:
			_c.append([Vector2(r.randf_range(0, vp.x), r.randf_range(0, vp.y)), r.randf_range(0.5, 1.4), r.randi() % 5, r.randf() * TAU])

	func _process(delta: float) -> void:
		_t += delta
		var gy: float = (get_viewport().get_canvas_transform() * Vector2(0.0, floor_y)).y   # הקרקע על המסך
		for e in _c:
			var p: Vector2 = e[0]
			p.y += 50.0 * delta * float(e[1])
			p.x += sin(_t * 2.0 + float(e[3])) * 20.0 * delta
			if p.y > minf(gy - 2.0, vp.y + 8.0):   # נחת על הקרקע -> פיסה חדשה למעלה
				p.y = -8.0
				p.x = randf_range(0.0, vp.x)
			e[0] = p
			e[3] = float(e[3]) + delta * 4.0
		queue_redraw()

	func _draw() -> void:
		var S := preload("res://effects/s32_decor.gd")
		for e in _c:   # (בלי טרנספורם לכל פיסה - זול)
			var p: Vector2 = e[0]
			var a: float = e[3]
			var c: Color = S.BULBS[int(e[2])]
			var hw := 0.5 + 2.5 * absf(sin(a))
			DrawBatch.rect(self, Rect2(p.x - hw, p.y - 1.5, hw * 2.0, 3.0), Color(c, 0.85))
		var pl := S.pulse()   # מחוון קצב: תוף קטן למטה במרכז
		var c := Vector2(vp.x * 0.5, vp.y - 26.0)
		DrawBatch.circle(self, c, 9.0 + pl * 5.0, Color(1.0, 0.8, 0.3, 0.12 + 0.3 * pl))
		DrawBatch.arc(self, c, 9.0, 0.0, TAU, 16, Color(1.0, 0.85, 0.4, 0.5), 1.5)
		DrawBatch.circle(self, c, 3.0, Color(1.0, 0.85, 0.4, 0.4 + 0.6 * pl))
