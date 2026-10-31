extends RefCounted
const DrawBatch := preload("res://effects/draw_batch.gd")   # כל הציור של אובייקט ב-draw call אחד
# ============================================================
#  קישוטים לשלב 61 ("END OF THE WORLD") - אזור שמיני, שלב 1. "THEY LEARNED TO MOVE AS ONE".
#  אושוואיה, העיר בקצה העולם: רחובות של בתי פח צבעוניים על מדרון, הרי מרסיאל המושלגים מאחור עם זוהר ורוד של שקיעה,
#  תעלת ביגל, הנמל עם ספינת תענוגות חלודה, רכבת קצה העולם (רכבת האסירים הישנה), והכלא הישן (PRESIDIO) בסוף.
#  כל האזור צועד לעיר כגוף אחד, בצעד אחד: על המדרונות, ברחובות, ברקע. ה-ROOT ירד מהמעבדה עם מי ההפשרה וגדל מתחת לעיר.
#    end_sky       - (רקע) שמיים של דמדומים קרים: סגול-כחול למעלה, ורוד-אפרסק באופק, עננים עדשתיים (לנטיקולריים) של פטגוניה,
#                    "זוהר" ירוק חלש של נבגים שעולים מהעיר, וקונדורים רחוקים שדואים במעגלים בלי לנפנף
#    far_peaks     - (רקע, 0.06) הרי מרסיאל + מונטה אוליביה (הפירמידה החדה), שלג בזוהר ורוד, קרחון, ותעלת ביגל עם האיים שממול
#    mid_city      - (רקע, 0.28) העיר על המדרון: שורות של בתי פח עם גגות אדומים/כחולים/ירוקים, ארובות מעשנות, כנסייה,
#                    עגורני נמל - ותהלוכה של אלפי דמויות שיורדות במדרון בצעד אחד (BEAT, כמו THRONG)
#    near_street   - (רקע, 0.6) עצי לנגה כפופים ברוח, גדרות עץ, פנסי רחוב כתומים, מכוניות נטושות בשלג, ושורה של צועדים בצעד אחד
#    end_overlay   - אובך קר מאחורי הדמויות
#    StreetGround  - (עולם) אספלט עם שלג נמס בשוליים, אבן שפה, מרצפות, שלוליות - ועקבות: כולן באותו צעד. style "pier" = מזח עץ
#    FinSign       - (עולם) השלט "USHUAIA - FIN DEL MUNDO", והכוורת כתבה מתחת בפטרייה זוהרת: "...Y EL PRINCIPIO"
#    TinHouse      - (עולם) בית פח צבעוני דו-קומתי: מרפסת עץ (קומה), קומה עליונה, גג משופע עם שלג, ארובה, כתובת של הכוורת (words)
#    EndTrain      - (עולם) רכבת קצה העולם: קטר קיטור + קרונות (גגות = קומה), "TREN DEL FIN DEL MUNDO", מסילה צרה
#    SteamValve    - (עולם, מלכודת) שסתום הקיטור של הקטר (ValveBody): ירייה / פיצוץ -> לחץ (WARN_T) -> סילון קיטור רותח לאורך
#                    הקרקע (JET_W, JET_T): צורב זומבים ("SCALDED", DMG_Z) - וגם אותך (DMG). נטען מחדש (CD).
#    CruiseShip    - (עולם) ספינת תענוגות חלודה שעוגנת במזח: חרטום, גוף עם חלונות עגולים, סיפון הטיילת (קומה), גשר, ארובה,
#                    כתובת הכוורת על הגוף. סירות ההצלה = Lifeboat.
#    Lifeboat      - (עולם, מלכודת) סירת הצלה תלויה בשני חבלים (RopeBody). ירייה בחבל / פיצוץ -> נופלת (ב-_process) ומועכת את
#                    מה שמתחת ("CRUSHED", DMG_Z) - וגם אותך (DMG). נשארת שבורה על המזח.
#    Pyre          - (עולם) מדורה של רהיטים ברחוב: עמוד של אוויר חם, ניצוצות ואפר שעולים גבוה - הזרם העולה שהקונדורים רוכבים עליו
#    Obstacle      - (מוצק + מחסה) "car" מכונית חלודה עם שלג / "traps" מלכודות סרטנים (סנטויה) / "drums" חביות / "crates" ארגזי דגים
#                    / "container" מכולה
#    Presidio      - (עולם) זירת הבוס: חזית הכלא הישן (CARCEL DE USHUAIA), חלונות עם סורגים, מגדל, ובסוף - השער שיורד למטה:
#                    שורשי ECHO זוהרים יוצאים ממנו ויורדים לתוך האדמה. "BAJEN" / "COME DOWN".
#    EndFX         - (מסך) שלג דק באלכסון, משב (gust())
#  לשנות: SteamValve.WARN_T / JET_T / JET_W / CD / DMG / DMG_Z, Lifeboat.DMG / DMG_Z / G, EndFX.GUST_EVERY, BEAT.
# ============================================================

const Art := preload("res://art.gd")
const Sfx := preload("res://sfx.gd")
const Kit := preload("res://effects/backdrop_kit.gd")
const Particles := preload("res://particles.gd")
const DebrisScript := preload("res://debris.gd")

const BEAT := 0.5                  # הקצב של הצעידה (כמו THRONG)
const SNOW := Color("e8eef4")
const SNOW_S := Color("b8c4d4")
const SLUSH := Color("7c8490")
const ASPH := Color("34363c")
const ASPH_L := Color("4a4c54")
const CURB := Color("8a8a88")
const WOOD := Color("5c4632")
const WOOD_D := Color("3a2c20")
const WOOD_L := Color("8a6c4a")
const RUST := Color("8a4a2a")
const RUST_D := Color("4e2616")
const RUST_L := Color("b86a3a")
const IRON := Color("26262a")
const STONE := Color("8c867c")
const STONE_D := Color("5e5a54")
const SPORE := Color(0.62, 1.0, 0.5)
const FUNGUS := Color("cfd4a8")
const ROCK := Color("3a3a52")
const PINK := Color("f2c4cc")
const TIN := [Color("b8443a"), Color("3a6a9a"), Color("d8b040"), Color("4a8a5a"), Color("2f7f86"), Color("c8703a"), Color("7a4a8a")]
const ROOFS := [Color("8a2a24"), Color("2a4a6e"), Color("3e6a3e"), Color("6a2a3a"), Color("4a4a50")]
const HULL := Color("2e3a4a")
const HULL_L := Color("e4e2dc")


# עזרים - מחלקה פנימית לא רואה פונקציות סטטיות של הקובץ
class U:
	static func h(i: int, s: int) -> float:
		return fposmod(sin(float(i) * 12.9898 + float(s) * 78.233) * 43758.5453, 1.0)

	static func flush(ci: CanvasItem, pts: PackedVector2Array, cols: PackedColorArray) -> void:
		if not pts.is_empty():
			DrawBatch.tris(ci, pts, cols)

	static func quad(pts: PackedVector2Array, cols: PackedColorArray, a: Vector2, b: Vector2, c: Vector2, d: Vector2, ca: Color, cb: Color, cc: Color, cd: Color) -> void:
		pts.append_array([a, b, c, a, c, d])
		cols.append_array([ca, cb, cc, ca, cc, cd])

	static func rect(pts: PackedVector2Array, cols: PackedColorArray, r: Rect2, c: Color) -> void:
		pts.append_array([r.position, Vector2(r.end.x, r.position.y), r.end, r.position, r.end, Vector2(r.position.x, r.end.y)])
		cols.append_array([c, c, c, c, c, c])

	static func vrect(pts: PackedVector2Array, cols: PackedColorArray, r: Rect2, top: Color, bot: Color) -> void:
		quad(pts, cols, r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y), top, top, bot, bot)

	static func tri(pts: PackedVector2Array, cols: PackedColorArray, a: Vector2, b: Vector2, c: Vector2, col: Color) -> void:
		pts.append_array([a, b, c])
		cols.append_array([col, col, col])

	static func dia(pts: PackedVector2Array, cols: PackedColorArray, c: Vector2, r: float, col: Color) -> void:
		pts.append_array([c + Vector2(-r, 0), c + Vector2(0, -r), c + Vector2(r, 0), c + Vector2(-r, 0), c + Vector2(r, 0), c + Vector2(0, r)])
		cols.append_array([col, col, col, col, col, col])

	# קו עבה בין שתי נקודות
	static func seg(pts: PackedVector2Array, cols: PackedColorArray, a: Vector2, b: Vector2, w: float, col: Color) -> void:
		var d := b - a
		if d.length_squared() < 0.0001:
			return
		var n := d.normalized().orthogonal() * w * 0.5
		quad(pts, cols, a - n, a + n, b + n, b - n, col, col, col, col)

	static func oval(pts: PackedVector2Array, cols: PackedColorArray, c: Vector2, rx: float, ry: float, col: Color, n := 8, rot := 0.0) -> void:
		var cr := cos(rot)
		var sr := sin(rot)
		var prev := c + Vector2(rx * cr, rx * sr)
		for q in n:
			var a1 := float(q + 1) / float(n) * TAU
			var lx := cos(a1) * rx
			var ly := sin(a1) * ry
			var p := c + Vector2(lx * cr - ly * sr, lx * sr + ly * cr)
			pts.append_array([c, prev, p])
			cols.append_array([col, col, col])
			prev = p

	# רצועה עבה לאורך קו (שורש / חבל): רוחב משתנה w0 -> w1
	static func strip(pts: PackedVector2Array, cols: PackedColorArray, line: PackedVector2Array, w0: float, w1: float, col: Color, col2 := Color(0, 0, 0, 0)) -> void:
		var n := line.size()
		if n < 2:
			return
		var c2 := col if col2.a <= 0.0 else col2
		for i in n - 1:
			var a := line[i]
			var b := line[i + 1]
			var d := (b - a).normalized().orthogonal()
			var k0 := float(i) / float(n - 1)
			var k1 := float(i + 1) / float(n - 1)
			var wa := lerpf(w0, w1, k0) * 0.5
			var wb := lerpf(w0, w1, k1) * 0.5
			var ca := col.lerp(c2, k0)
			var cb := col.lerp(c2, k1)
			quad(pts, cols, a - d * wa, a + d * wa, b + d * wb, b - d * wb, ca, ca, cb, cb)

	# צועד בצל (רקע): רגליים בצעד אחד (ph = הפאזה של הקצב המשותף), ידיים תלויות קדימה, עיניים ירוקות
	static func walker(pts: PackedVector2Array, cols: PackedColorArray, p: Vector2, s: float, ph: float, dir: float, col: Color, eye := 0.0) -> void:
		var st := sin(ph * PI) * 3.2 * s
		var bob := absf(sin(ph * PI)) * 1.2 * s
		var hip := p + Vector2(0, -9.0 * s - bob)
		quad(pts, cols, hip + Vector2(-1.4 * s, 0), hip + Vector2(1.4 * s, 0), p + Vector2(st + 0.8 * s, 0), p + Vector2(st - 0.8 * s, 0), col, col, col, col)
		quad(pts, cols, hip + Vector2(-1.4 * s, 0), hip + Vector2(1.4 * s, 0), p + Vector2(-st + 0.8 * s, 0), p + Vector2(-st - 0.8 * s, 0), col, col, col, col)
		var sh := hip + Vector2(1.0 * s * dir, -9.0 * s)
		quad(pts, cols, hip + Vector2(-2.6 * s, 0), hip + Vector2(2.6 * s, 0), sh + Vector2(3.0 * s, 0), sh + Vector2(-3.0 * s, 0), col, col, col, col)
		seg(pts, cols, sh + Vector2(0.5 * s * dir, 0.6 * s), sh + Vector2(6.0 * s * dir, 4.5 * s), 1.4 * s, col)
		oval(pts, cols, sh + Vector2(1.2 * s * dir, -2.8 * s), 2.2 * s, 2.5 * s, col, 6)
		if eye > 0.0:
			rect(pts, cols, Rect2(sh + Vector2(2.0 * s * dir - 0.5, -3.4 * s), Vector2(1.2, 1.0)), Color(SPORE.r, SPORE.g, SPORE.b, eye))

	# קונדור רחוק דואה (V רחב עם "אצבעות" בקצוות, בלי לנפנף)
	static func glider(pts: PackedVector2Array, cols: PackedColorArray, p: Vector2, s: float, tilt: float, col: Color) -> void:
		var l := p + Vector2(-14.0 * s, -2.0 * s + tilt * 4.0 * s)
		var r := p + Vector2(14.0 * s, -2.0 * s - tilt * 4.0 * s)
		quad(pts, cols, p + Vector2(-1.5 * s, 0.5 * s), p + Vector2(1.5 * s, 0.5 * s), r, l, col, col, col, col)
		quad(pts, cols, p + Vector2(-5.0 * s, 0.0), p + Vector2(5.0 * s, 0.0), r + Vector2(-2.0 * s, 2.4 * s), l + Vector2(2.0 * s, 2.4 * s), col, col, col, col)
		for q in 3:
			seg(pts, cols, l + Vector2(1.0 * s, 0.6 * s), l + Vector2(-2.6 * s, (-1.4 + float(q) * 1.4) * s), 0.8 * s, col)
			seg(pts, cols, r + Vector2(-1.0 * s, 0.6 * s), r + Vector2(2.6 * s, (-1.4 + float(q) * 1.4) * s), 0.8 * s, col)
		tri(pts, cols, p + Vector2(-1.5 * s, 1.0 * s), p + Vector2(1.5 * s, 1.0 * s), p + Vector2(0, 4.5 * s), col)

	# כתם פטריית ECHO זוהרת. pulse 0..1
	static func growth(pts: PackedVector2Array, cols: PackedColorArray, c: Vector2, s: float, seed_v: int, pulse: float) -> void:
		oval(pts, cols, c, 14.0 * s, 5.0 * s, Color(SPORE.r, SPORE.g, SPORE.b, 0.10 + 0.08 * pulse), 10)
		for q in 5:
			var x := (h(seed_v + q, 1) - 0.5) * 18.0 * s
			var hh := (5.0 + h(seed_v + q, 2) * 9.0) * s
			var b := c + Vector2(x, 2.0 * s)
			var tp := b + Vector2(sin(float(q) * 1.7) * 2.0 * s, -hh)
			quad(pts, cols, b + Vector2(-0.8 * s, 0), b + Vector2(0.8 * s, 0), tp + Vector2(0.5 * s, 0), tp + Vector2(-0.5 * s, 0), FUNGUS.darkened(0.2), FUNGUS.darkened(0.2), FUNGUS, FUNGUS)
			oval(pts, cols, tp, (1.6 + h(seed_v + q, 3) * 1.4) * s, (1.3 + h(seed_v + q, 3)) * s, SPORE.lerp(Color(1, 1, 0.8), 0.3 * pulse), 6)

	# שורש ECHO מתפתל (מנקודה a לנקודה b), עם גלים שזזים (t)
	static func root(pts: PackedVector2Array, cols: PackedColorArray, a: Vector2, b: Vector2, w: float, t: float, wav: float, seed_v: int, col: Color, col2: Color) -> void:
		var line := PackedVector2Array()
		var n := 9
		var d := b - a
		var nrm := d.normalized().orthogonal()
		for q in n:
			var u := float(q) / float(n - 1)
			line.append(a + d * u + nrm * sin(u * 5.0 + float(seed_v) + t * 0.6) * wav * sin(u * PI))
		strip(pts, cols, line, w, w * 0.3, col, col2)

	# גג פח גלי (קווים אנכיים דקים) על מלבן
	static func ribs(pts: PackedVector2Array, cols: PackedColorArray, r: Rect2, step: float, col: Color) -> void:
		var x := r.position.x + step * 0.5
		while x < r.end.x:
			rect(pts, cols, Rect2(x, r.position.y, 1.0, r.size.y), col)
			x += step

	# שלט כתוב של הכוורת (פטרייה זוהרת)
	static func hive_words(ci: CanvasItem, pos: Vector2, w: float, words: String, pulse: float, size := 18) -> void:
		var lines := words.split("|")
		for i in lines.size():
			var yy := pos.y + float(i) * (size + 6)
			Kit.soft_glow(ci, Vector2(pos.x + w * 0.5, yy - size * 0.4), w * 0.5, Color(0.55, 1.0, 0.45, 0.08 + 0.07 * pulse), 0.25)
			DrawBatch.string(ci, ThemeDB.fallback_font, Vector2(pos.x, yy), lines[i], HORIZONTAL_ALIGNMENT_CENTER, w, size, Color(0.7, 1.0, 0.55, 0.6 + 0.32 * pulse))


static func _h(i: int, s: int) -> float:
	return U.h(i, s)


# ============================================================
#  רקע
# ============================================================

# ---- דמדומים קרים: ורוד באופק, עננים עדשתיים, זוהר נבגים ירוק, קונדורים רחוקים ----
static func end_sky(ci: CanvasItem, v: Vector2, t: float) -> void:
	Kit.gradient_sky(ci, v, [Color("1c2140"), Color("343a64"), Color("5e5684"), Color("b0809a"), Color("eab0a0")], 0.82)
	# השמש שירדה מאחורי ההרים: זוהר ורוד-כתום רחב באופק
	var sp := Vector2(v.x * 0.22, v.y * 0.74)
	Kit.soft_glow(ci, sp, 520.0, Color(1.0, 0.62, 0.52, 0.22), 0.3)
	Kit.soft_glow(ci, sp, 200.0, Color(1.0, 0.78, 0.6, 0.3), 0.45)
	# כוכבים ראשונים למעלה
	var pts := PackedVector2Array()
	var cols := PackedColorArray()
	for i in 44:
		var p := Vector2(_h(i, 1) * v.x, _h(i, 2) * v.y * 0.32)
		var a := (0.25 + 0.5 * _h(i, 3)) * (0.6 + 0.4 * sin(t * (1.0 + _h(i, 4) * 2.0) + float(i))) * (1.0 - p.y / (v.y * 0.36))
		U.dia(pts, cols, p, 0.9 + _h(i, 5) * 0.8, Color(0.9, 0.92, 1.0, a))
	U.flush(ci, pts, cols)
	# "זוהר" ירוק חלש: נבגים שעולים מהעיר ונמתחים בשמיים כמו זוהר קוטב
	pts = PackedVector2Array()
	cols = PackedColorArray()
	for b in 3:
		var y0 := v.y * (0.16 + 0.07 * float(b))
		var seg_n := 16
		for q in seg_n:
			var x0 := v.x * float(q) / float(seg_n) - 40.0
			var x1 := v.x * float(q + 1) / float(seg_n) + 40.0
			var ya := y0 + sin(float(q) * 0.7 + t * 0.12 + float(b) * 2.0) * 26.0
			var yb := y0 + sin(float(q + 1) * 0.7 + t * 0.12 + float(b) * 2.0) * 26.0
			var a := (0.05 + 0.04 * sin(t * 0.4 + float(q) * 0.9 + float(b))) * (0.5 + 0.5 * sin(float(q) / float(seg_n) * PI))
			var c := Color(0.5, 1.0, 0.6, a)
			U.quad(pts, cols, Vector2(x0, ya - 50.0), Vector2(x1 - 40.0, yb - 50.0), Vector2(x1 - 40.0, yb + 10.0), Vector2(x0, ya + 10.0), Color(c, 0.0), Color(c, 0.0), c, c)
	U.flush(ci, pts, cols)
	# עננים עדשתיים (כמו צלחות שטוחות מעל ההרים) - שכבות עם שוליים ורודים
	for i in 4:
		var x := fposmod(_h(i, 8) * v.x * 1.5 - t * (3.0 + float(i)), v.x + 700.0) - 350.0
		var y := v.y * (0.2 + _h(i, 9) * 0.3)
		var rx := 180.0 + _h(i, 10) * 140.0
		for l in 2:   # שתי "צלחות" + שוליים ורודים אחד (כל אליפסה רכה = קריאת ציור)
			Kit.soft_ellipse(ci, Vector2(x + float(l) * 10.0, y - float(l) * 11.0), rx * (1.0 - float(l) * 0.24), 9.0, 0.0, Color(0.42, 0.4, 0.6, 0.5))
		Kit.soft_ellipse(ci, Vector2(x - rx * 0.2, y + 4.0), rx * 0.7, 2.5, 0.0, Color(1.0, 0.72, 0.7, 0.36))
	# שכבות סטרטוס נמוכות
	for i in 5:
		var x := fposmod(_h(i, 11) * v.x * 1.7 - t * (5.0 + float(i) * 2.0), v.x + 900.0) - 450.0
		var y := v.y * (0.46 + _h(i, 12) * 0.16)
		Kit.soft_ellipse(ci, Vector2(x, y), 280.0 + _h(i, 13) * 160.0, 16.0 + _h(i, 14) * 14.0, 0.0, Color(0.36, 0.3, 0.46, 0.4))
		if i % 2 == 0:
			Kit.soft_ellipse(ci, Vector2(x + 30.0, y + 10.0), 220.0, 4.0, 0.0, Color(1.0, 0.7, 0.62, 0.18))
	# קונדורים רחוקים דואים במעגלים (בלי לנפנף)
	pts = PackedVector2Array()
	cols = PackedColorArray()
	for g in 3:
		var cx := fposmod(_h(g, 20) * v.x * 1.3 + t * (3.0 + float(g)), v.x + 400.0) - 200.0
		var cy := 110.0 + float(g) * 60.0
		for q in 2 + g % 2:
			var a := t * (0.22 + 0.05 * float(q)) + float(q) * 2.6 + float(g)
			var r := 50.0 + _h(q, 21 + g) * 60.0
			U.glider(pts, cols, Vector2(cx + cos(a) * r, cy + sin(a) * r * 0.3), 1.1 - float(g) * 0.15, cos(a), Color(0.08, 0.07, 0.1, 0.85))
	U.flush(ci, pts, cols)


# ---- הרי מרסיאל, מונטה אוליביה, קרחון, תעלת ביגל ----
static func far_peaks(ci: CanvasItem, sc: float, v: Vector2, y: float, t: float) -> void:
	var sea_top := y - 30.0
	var period := 2400.0
	var start := int(floor(sc / period)) - 1
	for k in range(start, start + int(ceil(v.x / period)) + 2):
		var bx := float(k) * period - sc
		if bx > v.x + 40.0 or bx + period + 100.0 < -40.0:   # מקטע שכולו מחוץ למסך
			continue
		# רכס אחורי (סגול-כחול) + רכס קדמי (כהה) עם שלג ורוד
		for layer in 2:
			var ridge := PackedVector2Array([Vector2(bx, sea_top)])
			var peaks := []
			var n := 16
			for q in n + 1:
				var px := bx + float(q) * period / float(n)
				var hh := 30.0
				if q > 0 and q < n:
					var base_h := 170.0 if layer == 0 else 110.0
					hh = (base_h + _h(k * 37 + q + layer * 5, 1) * 120.0) if q % 2 == 1 else (base_h * 0.5 + _h(k * 37 + q, 2) * 50.0)
					if layer == 0 and q == 9:   # מונטה אוליביה: פירמידה חדה וגבוהה
						hh = 330.0
				ridge.append(Vector2(px + (_h(q, 3 + layer) - 0.5) * 26.0, sea_top - hh))
				if q % 2 == 1 and q < n:
					peaks.append([ridge[ridge.size() - 1], hh])
			ridge.append(Vector2(bx + period, sea_top))
			DrawBatch.colored_polygon(ci, ridge, Color("4a4a6e") if layer == 0 else Color("2a2c40"))
			if layer == 0:   # קרחון מרסיאל: לשון צרה למעלה ורחבה למטה, בין הרכסים (הרכס הקדמי מסתיר את התחתית)
				var gx0 := bx + 1500.0
				DrawBatch.colored_polygon(ci, PackedVector2Array([Vector2(gx0 - 14, sea_top - 236), Vector2(gx0 + 18, sea_top - 230), Vector2(gx0 + 60, sea_top - 60), Vector2(gx0 - 64, sea_top - 60)]), Color("d4cce0"))
				for q in 4:
					DrawBatch.line(ci, Vector2(gx0 - 8 + float(q) * 7.0, sea_top - 226), Vector2(gx0 - 50 + float(q) * 32.0, sea_top - 64), Color(0.62, 0.6, 0.8, 0.45), 1.0)
			for pk in peaks:   # שלג בזוהר ורוד, עם ערוצים
				var p0: Vector2 = pk[0]
				var s := clampf(float(pk[1]) / 220.0, 0.6, 1.6) * (1.0 if layer == 0 else 0.75)
				var sn := PINK if layer == 0 else Color("c8b0c4")
				DrawBatch.colored_polygon(ci, PackedVector2Array([p0, p0 + Vector2(30, 38) * s, p0 + Vector2(14, 32) * s, p0 + Vector2(6, 58) * s, p0 + Vector2(-8, 36) * s, p0 + Vector2(-26, 44) * s]), sn)
				DrawBatch.line(ci, p0, p0 + Vector2(28, 37) * s, Color(0.5, 0.42, 0.6, 0.5), 1.2)
		var gx := bx + 1500.0
		# מי ההפשרה שיורדים מהקרחון - עם קו ירוק דק (הדרך שבה ה-ROOT ירד לעיר)
		var pulse := 0.5 + 0.5 * sin(t * 0.8 + float(k))
		DrawBatch.polyline(ci, PackedVector2Array([Vector2(gx, sea_top - 92), Vector2(gx + 12, sea_top - 60), Vector2(gx - 6, sea_top - 34), Vector2(gx + 8, sea_top - 4)]), Color(0.75, 0.82, 0.92, 0.6), 2.0)
		DrawBatch.polyline(ci, PackedVector2Array([Vector2(gx, sea_top - 92), Vector2(gx + 12, sea_top - 60), Vector2(gx - 6, sea_top - 34), Vector2(gx + 8, sea_top - 4)]), Color(0.55, 1.0, 0.5, 0.18 + 0.2 * pulse), 1.0)
		# ענן נמוך בין ההרים
		for c in 3:
			var cx := bx + 400.0 + float(c) * 760.0 + sin(t * 0.04 + float(c + k)) * 60.0
			Kit.soft_ellipse(ci, Vector2(cx, sea_top - 80.0 - float(c % 2) * 30.0), 230.0, 16.0, 0.0, Color(0.6, 0.52, 0.68, 0.4))
	# תעלת ביגל: מים כהים עם השתקפות ורודה והאיים שממול (נבארינו)
	DrawBatch.rect(ci, Rect2(0, sea_top, v.x, v.y - sea_top), Color("2e3854"))
	var pts := PackedVector2Array()
	var cols := PackedColorArray()
	var isl := sea_top + 10.0
	for i in 8:
		var ix := fposmod(_h(i, 30) * 4000.0 - sc * 1.6, v.x + 500.0) - 250.0
		var iw := 160.0 + _h(i, 31) * 240.0
		U.quad(pts, cols, Vector2(ix, isl), Vector2(ix + iw * 0.3, isl - 14.0 - _h(i, 32) * 14.0), Vector2(ix + iw * 0.7, isl - 10.0 - _h(i, 33) * 10.0), Vector2(ix + iw, isl), Color("252a40"), Color("2c3048"), Color("2c3048"), Color("252a40"))
	for i in 30:
		var gx := fposmod(_h(i, 5) * 3000.0 - sc - t * (4.0 + _h(i, 6) * 4.0), v.x + 100.0) - 50.0
		var gy := sea_top + 14.0 + _h(i, 7) * 26.0
		var near_sun := clampf(1.0 - absf(gx - v.x * 0.22) / 520.0, 0.0, 1.0)
		var a := (0.06 + 0.26 * near_sun) * (0.5 + 0.5 * sin(t * 2.2 + float(i) * 2.3))
		var c := Color(1.0, 0.72, 0.72, a)
		U.quad(pts, cols, Vector2(gx, gy), Vector2(gx + 16.0, gy), Vector2(gx + 16.0, gy + 1.0), Vector2(gx, gy + 1.0), Color(c, 0.0), c, c, Color(c, 0.0))
	U.flush(ci, pts, cols)


# ---- העיר על המדרון: בתי פח, ארובות, כנסייה, עגורנים - ותהלוכה בצעד אחד ----
static func mid_city(ci: CanvasItem, sc: float, v: Vector2, y: float, t: float) -> void:
	var period := 1800.0
	var start := int(floor(sc / period)) - 1
	var ph := t / BEAT
	# המדרון עצמו (ירוק-כהה, יער לנגה) - נמוך משמאל, עולה ימינה, חוזר
	var hill := PackedVector2Array([Vector2(0, v.y)])
	var steps := 24
	for q in steps + 1:
		var x := v.x * float(q) / float(steps)
		var wx := x + sc
		hill.append(Vector2(x, y - 120.0 - sin(wx / 520.0) * 40.0 - sin(wx / 210.0) * 12.0))
	hill.append(Vector2(v.x, v.y))
	DrawBatch.colored_polygon(ci, hill, Color("2a2e3c"))
	var pts := PackedVector2Array()
	var cols := PackedColorArray()
	for k in range(start, start + int(ceil(v.x / period)) + 2):
		var bx := float(k) * period - sc
		if bx > v.x + 40.0 or bx + period + 100.0 < -40.0:   # מקטע שכולו מחוץ למסך
			continue
		# שלוש שורות של בתים על המדרון (האחורית קטנה וכהה יותר)
		for row in 3:
			var ry := y - 120.0 + float(row) * 42.0
			var s := 0.6 + 0.2 * float(row)
			var dark := 0.55 - 0.18 * float(row)
			var x := bx + _h(k, row + 1) * 60.0
			var i := 0
			while x < bx + period and x < v.x + 40.0:
				if x < -90.0:   # בית מחוץ למסך משמאל - רק מתקדמים (אותם מספרים, אותו סדר)
					x += (26.0 + _h(i, row * 7 + k) * 22.0) * s + (4.0 + _h(i, row + 80) * 10.0) * s
					i += 1
					continue
				var wx := x + sc
				var gy := ry - sin(wx / 520.0) * 40.0 * (1.0 - float(row) * 0.3) - sin(wx / 210.0) * 12.0 * (1.0 - float(row) * 0.3)
				var hw := (26.0 + _h(i, row * 7 + k) * 22.0) * s
				var hh := (22.0 + _h(i, row * 7 + k + 1) * 16.0) * s
				var wall: Color = TIN[int(_h(i, row + k * 3) * 7.0) % 7]
				var roof: Color = ROOFS[int(_h(i, row + k * 3 + 1) * 5.0) % 5]
				wall = wall.darkened(dark)
				roof = roof.darkened(dark)
				U.rect(pts, cols, Rect2(x, gy - hh, hw, hh + 10.0), wall)
				U.quad(pts, cols, Vector2(x - 3.0 * s, gy - hh), Vector2(x + hw + 3.0 * s, gy - hh), Vector2(x + hw * 0.5 + 2.0, gy - hh - 12.0 * s), Vector2(x + hw * 0.5 - 2.0, gy - hh - 12.0 * s), roof, roof, roof.lightened(0.1), roof.lightened(0.1))
				U.tri(pts, cols, Vector2(x + hw * 0.2, gy - hh - 4.0 * s), Vector2(x + hw * 0.5, gy - hh - 12.0 * s), Vector2(x + hw * 0.8, gy - hh - 4.0 * s), Color(0.92, 0.9, 0.96, 0.75 - 0.15 * float(row)))
				# חלונות: רובם חשוכים, חלק בזוהר ירוק (הם בבית, עומדים במקום ומחכים לקצב)
				for wq in 2:
					var lit := _h(i * 3 + wq, row + 40 + k)
					var wc := Color(0.08, 0.08, 0.12) if lit < 0.6 else (Color(1.0, 0.78, 0.4, 0.85) if lit < 0.78 else Color(0.5, 1.0, 0.5, 0.55 + 0.25 * sin(t * 2.0 + float(i))))
					U.rect(pts, cols, Rect2(x + hw * (0.2 + 0.4 * float(wq)), gy - hh * 0.7, 4.0 * s, 5.0 * s), wc)
				# ארובה
				if _h(i, row + 60 + k) < 0.4:
					U.rect(pts, cols, Rect2(x + hw * 0.7, gy - hh - 14.0 * s, 4.0 * s, 9.0 * s), wall.darkened(0.3))
				x += hw + (4.0 + _h(i, row + 80) * 10.0) * s
				i += 1
		# כנסייה עם צריח לבן (פעם במקטע)
		var cx := bx + 900.0
		var cgy := y - 150.0 - sin((cx + sc) / 520.0) * 40.0
		U.rect(pts, cols, Rect2(cx, cgy - 30.0, 40.0, 40.0), Color("c8c4c8"))
		U.rect(pts, cols, Rect2(cx + 26.0, cgy - 70.0, 14.0, 44.0), Color("d4d0d4"))
		U.tri(pts, cols, Vector2(cx + 24.0, cgy - 70.0), Vector2(cx + 33.0, cgy - 96.0), Vector2(cx + 42.0, cgy - 70.0), Color("8a2a24"))
		U.quad(pts, cols, Vector2(cx - 3.0, cgy - 30.0), Vector2(cx + 28.0, cgy - 30.0), Vector2(cx + 20.0, cgy - 44.0), Vector2(cx + 5.0, cgy - 44.0), Color("8a2a24"), Color("8a2a24"), Color("a03a30"), Color("a03a30"))
		# עגורני נמל
		for g in 2:
			var gx := bx + 300.0 + float(g) * 1100.0
			var gy0 := y - 30.0
			U.rect(pts, cols, Rect2(gx, gy0 - 120.0, 5.0, 120.0), Color("3a2a28"))
			U.seg(pts, cols, Vector2(gx + 2.0, gy0 - 116.0), Vector2(gx + 90.0, gy0 - 140.0), 3.0, Color("3a2a28"))
			U.seg(pts, cols, Vector2(gx + 2.0, gy0 - 116.0), Vector2(gx - 30.0, gy0 - 110.0), 3.0, Color("3a2a28"))
			U.seg(pts, cols, Vector2(gx + 80.0, gy0 - 138.0), Vector2(gx + 80.0, gy0 - 80.0), 1.0, Color("1a1416"))
			U.rect(pts, cols, Rect2(gx + 76.0, gy0 - 80.0, 9.0, 6.0), Color("8a3a20"))
		# התהלוכה: דרך אלכסונית במדרון, אלפי דמויות יורדות - כולן בצעד אחד
		var road_a := Vector2(bx + 80.0, y - 175.0)
		var road_b := Vector2(bx + 1700.0, y - 34.0)
		U.seg(pts, cols, road_a, road_b, 7.0, Color(0.42, 0.42, 0.5, 0.6))
		var nw := 36
		for q in nw:
			var u := fposmod(float(q) / float(nw) + t * 0.004, 1.0)
			var p := road_a.lerp(road_b, u)
			if p.x < -20.0 or p.x > v.x + 20.0:
				continue
			U.walker(pts, cols, p + Vector2(0, 1.0), 0.75, ph + float(q % 2) * 0.0, 1.0, Color(0.1, 0.1, 0.14, 0.92), 0.9)
	U.flush(ci, pts, cols)
	# עשן ארובות (מעט, רך)
	for c in 3:
		var sx := fposmod(_h(c, 50) * 3600.0 - sc, v.x + 200.0) - 100.0
		Kit.soft_smoke(ci, Vector2(sx, y - 150.0 + _h(c, 51) * 40.0), t, 120.0, Color(0.5, 0.48, 0.58, 0.24), 50.0, 4)
	# הים בתחתית (התעלה ליד הנמל)
	DrawBatch.rect(ci, Rect2(0, y - 26.0, v.x, v.y - y + 26.0), Color("252c42"))
	DrawBatch.line(ci, Vector2(0, y - 26.0), Vector2(v.x, y - 26.0), Color(1.0, 0.7, 0.7, 0.25), 1.2)


# ---- קרוב: עצי לנגה כפופים, גדרות, פנסים, מכוניות בשלג - ושורת צועדים בצעד אחד ----
static func near_street(ci: CanvasItem, sc: float, v: Vector2, y: float, t: float) -> void:
	var pts := PackedVector2Array()
	var cols := PackedColorArray()
	var ph := t / BEAT
	# סוללה כהה עם שלג למעלה
	DrawBatch.rect(ci, Rect2(0, y - 22.0, v.x, v.y - y + 22.0), Color("1e2028"))
	# שורת צועדים מאחורי הגדר (צל) - כולם באותו צעד, הולכים ימינה (אל הכלא)
	var nw := 22
	for q in nw:
		var wx := fposmod(float(q) * 96.0 + _h(q, 70) * 40.0 + t * 26.0 - sc, v.x + 200.0) - 100.0
		U.walker(pts, cols, Vector2(wx, y - 40.0), 1.5 + _h(q, 71) * 0.25, ph, 1.0, Color(0.16, 0.15, 0.24, 0.8), 0.8)
	var period := 1400.0
	var start := int(floor(sc / period)) - 1
	for k in range(start, start + int(ceil(v.x / period)) + 2):
		var bx := float(k) * period - sc
		if bx > v.x + 40.0 or bx + period + 150.0 < -40.0:   # מקטע שכולו מחוץ למסך
			continue
		# עצי לנגה ("עצי דגל" שהרוח כופפה מזרחה)
		for q in 4:
			var tx := bx + 80.0 + float(q) * 330.0 + _h(k, q) * 80.0
			var th := 90.0 + _h(k * 5 + q, 2) * 60.0
			var base := Vector2(tx, y - 20.0)
			var top := base + Vector2(th * 0.55, -th)
			U.strip(pts, cols, PackedVector2Array([base, base + Vector2(6.0, -th * 0.4), base + Vector2(th * 0.25, -th * 0.75), top]), 8.0, 2.0, Color("1a1416"))
			for b in 5:   # הענפים: כולם לכיוון אחד
				var u := 0.35 + float(b) * 0.13
				var bp := base.lerp(top, u)
				U.seg(pts, cols, bp, bp + Vector2(40.0 + _h(b, q + k) * 30.0, -6.0 + float(b) * 2.0), 2.0, Color("1a1416"))
				U.oval(pts, cols, bp + Vector2(36.0 + _h(b, q + 3) * 20.0, -8.0), 24.0, 7.0, Color(0.12, 0.14, 0.16, 0.95), 8, -0.1)
				U.oval(pts, cols, bp + Vector2(34.0 + _h(b, q + 3) * 20.0, -12.0), 18.0, 3.0, Color(0.85, 0.85, 0.95, 0.7), 6, -0.1)
		# גדר עץ נמוכה
		for q in 26:
			var fx := bx + 40.0 + float(q) * 14.0
			U.rect(pts, cols, Rect2(fx, y - 46.0, 4.0, 26.0), Color("2a2224"))
			U.rect(pts, cols, Rect2(fx, y - 48.0, 4.0, 2.4), Color(0.85, 0.86, 0.92, 0.8))
		U.rect(pts, cols, Rect2(bx + 40.0, y - 40.0, 364.0, 3.0), Color("2a2224"))
		# פנס רחוב עם אור נתרן כתום
		var lx := bx + 760.0
		U.rect(pts, cols, Rect2(lx, y - 170.0, 4.0, 150.0), Color("1c1c22"))
		U.seg(pts, cols, Vector2(lx + 2.0, y - 168.0), Vector2(lx + 26.0, y - 176.0), 3.0, Color("1c1c22"))
		U.rect(pts, cols, Rect2(lx + 20.0, y - 176.0, 14.0, 5.0), Color(1.0, 0.7, 0.35))
		# מכונית נטושה מכוסה שלג
		var cx := bx + 1050.0
		U.quad(pts, cols, Vector2(cx, y - 22.0), Vector2(cx + 96.0, y - 22.0), Vector2(cx + 96.0, y - 42.0), Vector2(cx, y - 44.0), Color("1e2026"), Color("1e2026"), Color("262830"), Color("262830"))
		U.quad(pts, cols, Vector2(cx + 18.0, y - 44.0), Vector2(cx + 76.0, y - 43.0), Vector2(cx + 64.0, y - 62.0), Vector2(cx + 28.0, y - 62.0), Color("262830"), Color("262830"), Color("2c2e36"), Color("2c2e36"))
		U.oval(pts, cols, Vector2(cx + 46.0, y - 63.0), 22.0, 4.0, Color(0.88, 0.9, 0.96, 0.85), 8)
		U.oval(pts, cols, Vector2(cx + 10.0, y - 45.0), 12.0, 3.0, Color(0.88, 0.9, 0.96, 0.8), 8)
	U.flush(ci, pts, cols)
	# הילות הפנסים
	for k in range(start, start + int(ceil(v.x / period)) + 2):
		var lx := float(k) * period - sc + 787.0
		if lx > -200.0 and lx < v.x + 200.0:
			Kit.soft_glow(ci, Vector2(lx, y - 170.0), 70.0, Color(1.0, 0.65, 0.3, 0.2), 0.8)


static func end_overlay(ci: CanvasItem, v: Vector2, t: float) -> void:
	Kit.haze_band(ci, v, 400.0, 616.0, Color(0.62, 0.58, 0.74, 0.2))
	for i in 5:
		var mx := fposmod(float(i) * 320.0 - t * (14.0 + float(i) * 4.0), v.x + 600.0) - 300.0
		Kit.soft_glow(ci, Vector2(mx, 560.0 + float(i % 3) * 16.0), 240.0, Color(0.78, 0.76, 0.88, 0.06 + 0.03 * sin(t * 0.35 + float(i))), 0.22)


# ============================================================
#  עולם
# ============================================================

# ---- רחוב: אספלט, שלג נמס בשוליים, אבן שפה, שלוליות, עקבות בצעד אחד. style "pier" = מזח עץ ----
class StreetGround extends Node2D:
	var w := 1024.0
	var depth := 90.0
	var seed_v := 0
	var style := "street"

	func _ready() -> void:
		z_index = 1

	func _draw() -> void:
		DrawBatch.begin(self)
		_draw_b()
		DrawBatch.end(self)

	func _draw_b() -> void:
		var r := RandomNumberGenerator.new()
		r.seed = seed_v
		var pts := PackedVector2Array()
		var cols := PackedColorArray()
		if style == "pier":
			DrawBatch.rect(self, Rect2(0, 0, w, depth), Color("1a1e28"))
			# קרשי המזח
			var x := 0.0
			var i := 0
			while x < w:
				var pw := r.randf_range(26.0, 34.0)
				var c := WOOD.lerp(WOOD_D, r.randf() * 0.6)
				U.vrect(pts, cols, Rect2(x, 0, pw - 1.5, 14.0), c.lightened(0.08), c.darkened(0.2))
				U.rect(pts, cols, Rect2(x + pw * 0.3, 6.0, 2.0, 2.0), IRON)
				x += pw
				i += 1
			U.rect(pts, cols, Rect2(0, 14.0, w, 8.0), WOOD_D.darkened(0.4))
			# כלונסאות במים + המים מתחת
			for q in int(w / 120.0) + 1:
				var px := float(q) * 120.0 + 20.0
				U.vrect(pts, cols, Rect2(px, 22.0, 14.0, depth - 22.0), WOOD_D, Color("10141c"))
			U.rect(pts, cols, Rect2(0, 40.0, w, depth - 40.0), Color(0.12, 0.16, 0.24, 0.85))
			for q in int(w / 30.0):
				var wx := r.randf_range(0.0, w)
				U.rect(pts, cols, Rect2(wx, r.randf_range(44.0, depth - 8.0), r.randf_range(8.0, 22.0), 1.2), Color(0.8, 0.6, 0.65, 0.18))
			# שלג בין הקרשים + חבלים
			for q in int(w / 60.0):
				U.oval(pts, cols, Vector2(r.randf_range(0.0, w), 1.0), r.randf_range(8.0, 22.0), 2.0, Color(SNOW, 0.75), 8)
		else:
			DrawBatch.rect(self, Rect2(0, 0, w, depth), Color("1c1c22"))
			U.vrect(pts, cols, Rect2(0, 0, w, 18.0), ASPH_L, ASPH)
			U.rect(pts, cols, Rect2(0, 18.0, w, 7.0), CURB)
			U.rect(pts, cols, Rect2(0, 25.0, w, 3.0), CURB.darkened(0.4))
			# מרצפות המדרכה (מתחת לאבן השפה)
			var x := 0.0
			while x < w:
				var c := Color("4a4a50").lerp(Color("5c5a5e"), r.randf())
				U.rect(pts, cols, Rect2(x + 1.0, 29.0, 28.0, 12.0), c)
				x += 30.0
			# סדקים, טלאי אספלט, מכסה ביוב
			for q in int(w / 90.0):
				var p := Vector2(r.randf_range(0.0, w), r.randf_range(3.0, 15.0))
				U.seg(pts, cols, p, p + Vector2(r.randf_range(-20.0, 20.0), r.randf_range(-3.0, 3.0)), 1.0, Color(0.1, 0.1, 0.12, 0.7))
			if r.randf() < 0.5:
				var mx := r.randf_range(60.0, w - 60.0)
				U.oval(pts, cols, Vector2(mx, 8.0), 18.0, 4.0, Color("26262a"), 12)
				U.oval(pts, cols, Vector2(mx, 8.0), 14.0, 3.0, Color("3a3a40"), 12)
			# שלג נמס בשוליים ושלוליות שמשקפות את השמיים הוורודים
			for q in int(w / 26.0):
				var p := Vector2(r.randf_range(0.0, w), r.randf_range(0.0, 3.0))
				U.oval(pts, cols, p, r.randf_range(6.0, 22.0), 2.2, Color(SNOW, r.randf_range(0.6, 0.95)), 8)
			for q in int(w / 120.0):
				var p := Vector2(r.randf_range(0.0, w), r.randf_range(6.0, 14.0))
				var pw := r.randf_range(16.0, 40.0)
				U.oval(pts, cols, p, pw, 2.0, Color(0.7, 0.6, 0.75, 0.3), 10)
				U.oval(pts, cols, p + Vector2(pw * 0.25, -0.3), pw * 0.35, 0.7, Color(1.0, 0.75, 0.75, 0.25), 6)
			# שלג על המדרכה
			for q in int(w / 18.0):
				U.oval(pts, cols, Vector2(r.randf_range(0.0, w), 30.0), r.randf_range(5.0, 14.0), 2.0, Color(SNOW, 0.8), 6)
		# עקבות בשלג: זוגות בדיוק באותו מרחק - הם הולכים בצעד אחד
		var rows := 2 if style != "pier" else 1
		for row in rows:
			var yy := 4.0 + float(row) * 6.0
			var off := r.randf_range(0.0, 40.0)
			var x2 := off
			var k := 0
			while x2 < w:
				var c2 := Color(0.12, 0.13, 0.18, 0.4)
				U.oval(pts, cols, Vector2(x2, yy + (1.2 if k % 2 == 0 else -1.2)), 3.2, 1.1, c2, 6)
				x2 += 22.0
				k += 1
		# כתמי נבגים ירוקים
		for q in int(w / 140.0):
			var p := Vector2(r.randf_range(0.0, w), r.randf_range(2.0, 12.0))
			U.oval(pts, cols, p, r.randf_range(2.0, 4.0), 1.2, Color(SPORE.r, SPORE.g, SPORE.b, 0.35), 6)
		U.flush(self, pts, cols)


# ============================================================
#  השלט "USHUAIA - FIN DEL MUNDO" + מה שהכוורת כתבה מתחת
# ============================================================
class FinSign extends Node2D:
	var w := 300.0
	var _t := 0.0

	func _ready() -> void:
		z_index = -2

	func _process(delta: float) -> void:
		_t += delta
		if Engine.get_process_frames() % 6 == 0 and Art.on_screen(self, global_position + Vector2(w * 0.5, -120), w):
			queue_redraw()

	func _draw() -> void:
		DrawBatch.begin(self)
		_draw_b()
		DrawBatch.end(self)

	func _draw_b() -> void:
		var pts := PackedVector2Array()
		var cols := PackedColorArray()
		var top := -230.0
		# שני עמודי עץ עבים
		for s in 2:
			var px := 20.0 if s == 0 else w - 40.0
			U.vrect(pts, cols, Rect2(px, top - 10.0, 20.0, -top + 10.0), WOOD_L.darkened(0.15), WOOD_D)
			U.oval(pts, cols, Vector2(px + 10.0, top - 12.0), 13.0, 4.0, SNOW, 10)
		# הלוח: עץ כהה עם מסגרת, שלג על השפה
		U.vrect(pts, cols, Rect2(0, top, w, 110.0), Color("6a4a30"), Color("4a3220"))
		for q in 5:
			U.rect(pts, cols, Rect2(0, top + 8.0 + float(q) * 21.0, w, 1.4), Color(0.18, 0.1, 0.05, 0.6))
		U.rect(pts, cols, Rect2(-4, top - 4.0, w + 8.0, 6.0), WOOD_D)
		U.rect(pts, cols, Rect2(-4, top + 108.0, w + 8.0, 6.0), WOOD_D)
		U.oval(pts, cols, Vector2(w * 0.5, top - 5.0), w * 0.52, 5.0, SNOW, 16)
		U.oval(pts, cols, Vector2(w * 0.2, top - 7.0), 30.0, 4.0, SNOW_S, 10)
		# פטרייה שעולה על העמודים ונכנסת בין הקרשים
		var pulse := 0.5 + 0.5 * sin(_t * 1.6)
		U.growth(pts, cols, Vector2(30.0, -2.0), 1.0, 7, pulse)
		U.growth(pts, cols, Vector2(w - 30.0, -2.0), 1.2, 19, pulse)
		U.growth(pts, cols, Vector2(w - 26.0, top + 112.0), 0.8, 31, pulse)
		U.flush(self, pts, cols)
		var f := ThemeDB.fallback_font
		DrawBatch.string(self, f, Vector2(0, top + 46.0), "USHUAIA", HORIZONTAL_ALIGNMENT_CENTER, w, 40, Color("f4ead2"))
		DrawBatch.string(self, f, Vector2(0, top + 78.0), "FIN DEL MUNDO", HORIZONTAL_ALIGNMENT_CENTER, w, 22, Color("e8c890"))
		DrawBatch.string(self, f, Vector2(0, top + 98.0), "THE END OF THE WORLD", HORIZONTAL_ALIGNMENT_CENTER, w, 12, Color(0.95, 0.9, 0.8, 0.7))
		# הכוורת כתבה מתחת: "...והתחלה"
		U.hive_words(self, Vector2(0, top + 150.0), w, "...Y EL PRINCIPIO|AND THE BEGINNING", pulse, 18)


# ============================================================
#  בית פח צבעוני: קומת קרקע, מרפסת עץ (קומה), קומה עליונה, גג משופע עם שלג, ארובה
# ============================================================
class TinHouse extends Node2D:
	var w := 220.0
	var tier := 130.0
	var wall := Color("b8443a")
	var roof := Color("8a2a24")
	var seed_v := 0
	var words := ""
	var _t := 0.0

	func _ready() -> void:
		z_index = -2

	func _process(delta: float) -> void:
		if words == "":
			return
		_t += delta
		if Engine.get_process_frames() % 6 == 0 and Art.on_screen(self, global_position + Vector2(w * 0.5, -tier), w):
			queue_redraw()

	func _draw() -> void:
		DrawBatch.begin(self)
		_draw_b()
		DrawBatch.end(self)

	func _draw_b() -> void:
		var r := RandomNumberGenerator.new()
		r.seed = seed_v
		var pts := PackedVector2Array()
		var cols := PackedColorArray()
		var up := 96.0                     # גובה הקומה העליונה
		var top := -tier - up
		# קירות פח גלי (קומת קרקע + עליונה, העליונה קצת צרה)
		U.vrect(pts, cols, Rect2(0, -tier, w, tier), wall.lightened(0.05), wall.darkened(0.25))
		U.vrect(pts, cols, Rect2(10.0, top, w - 20.0, up), wall.lightened(0.02), wall.darkened(0.18))
		U.ribs(pts, cols, Rect2(0, -tier, w, tier), 7.0, Color(0, 0, 0, 0.14))
		U.ribs(pts, cols, Rect2(10.0, top, w - 20.0, up), 7.0, Color(0, 0, 0, 0.12))
		# חלודה זולגת מהברגים
		for q in 6:
			var rx := r.randf_range(8.0, w - 8.0)
			var ln := r.randf_range(20.0, tier * 0.6)
			U.quad(pts, cols, Vector2(rx - 2.0, -tier + 4.0), Vector2(rx + 2.0, -tier + 4.0), Vector2(rx + 0.6, -tier + ln), Vector2(rx - 0.6, -tier + ln), Color(0.35, 0.15, 0.06, 0.45), Color(0.35, 0.15, 0.06, 0.45), Color(0.35, 0.15, 0.06, 0.0), Color(0.35, 0.15, 0.06, 0.0))
		# דלת + חלונות עם מסגרות לבנות (חלקם שבורים, בחלק זוהר ירוק)
		var dx := w * 0.12
		U.rect(pts, cols, Rect2(dx - 3.0, -78.0, 40.0, 78.0), Color("e8e4dc"))
		U.rect(pts, cols, Rect2(dx, -75.0, 34.0, 75.0), wall.darkened(0.55))
		U.rect(pts, cols, Rect2(dx + 26.0, -40.0, 4.0, 4.0), Color("c8a040"))
		for q in 2:
			var wx := w * (0.45 + 0.28 * float(q))
			_window(pts, cols, Vector2(wx, -tier * 0.62), r)
		for q in 3:
			var wx := 20.0 + float(q) * (w - 70.0) / 2.0
			_window(pts, cols, Vector2(wx, top + 26.0), r)
		# הגג המשופע: פח גלי כהה, שלג עבה למעלה
		var rl := Vector2(-8.0, top)
		var rr := Vector2(w + 8.0, top)
		var peak := Vector2(w * 0.5, top - 52.0)
		U.quad(pts, cols, rl, rr, peak + Vector2(4, 0), peak - Vector2(4, 0), roof, roof, roof.lightened(0.15), roof.lightened(0.15))
		U.ribs(pts, cols, Rect2(0, top - 40.0, w, 40.0), 9.0, Color(0, 0, 0, 0.0))
		U.quad(pts, cols, peak + Vector2(-60, 18), peak + Vector2(60, 18), peak + Vector2(6, -2), peak + Vector2(-6, -2), SNOW, SNOW, SNOW, SNOW)
		U.quad(pts, cols, rl + Vector2(20, -6), rl + Vector2(80, -26), rl + Vector2(84, -22), rl + Vector2(20, -2), SNOW_S, SNOW, SNOW, SNOW_S)
		for q in 6:   # נטיפי קרח בשפת הגג
			var ix := 8.0 + float(q) * (w - 16.0) / 5.0
			U.tri(pts, cols, Vector2(ix - 2.0, top), Vector2(ix + 2.0, top), Vector2(ix, top + 6.0 + U.h(q, seed_v % 31) * 8.0), Color(0.85, 0.92, 1.0, 0.85))
		# ארובה + עשן דק
		U.rect(pts, cols, Rect2(w * 0.72, top - 52.0, 14.0, 30.0), Color("5a4a44"))
		U.rect(pts, cols, Rect2(w * 0.72 - 2.0, top - 54.0, 18.0, 4.0), SNOW)
		# המרפסת: קורת עץ, עמודים ומעקה (זו הקומה)
		U.rect(pts, cols, Rect2(-14.0, -tier - 2.0, w + 28.0, 9.0), WOOD_D)
		U.rect(pts, cols, Rect2(-14.0, -tier - 4.0, w + 28.0, 3.0), SNOW)
		for q in int((w + 28.0) / 18.0) + 1:
			U.rect(pts, cols, Rect2(-14.0 + float(q) * 18.0, -tier - 30.0, 2.4, 28.0), WOOD_D.darkened(0.2))
		U.rect(pts, cols, Rect2(-14.0, -tier - 32.0, w + 28.0, 3.0), WOOD)
		U.rect(pts, cols, Rect2(-14.0, -tier - 34.0, w + 28.0, 2.0), Color(SNOW, 0.8))
		U.rect(pts, cols, Rect2(-12.0, -tier + 6.0, 5.0, tier - 6.0), WOOD_D)
		U.rect(pts, cols, Rect2(w + 7.0, -tier + 6.0, 5.0, tier - 6.0), WOOD_D)
		# שלג נערם ליד הקיר
		U.oval(pts, cols, Vector2(w * 0.5, -1.0), w * 0.55, 5.0, Color(SNOW, 0.9), 14)
		if words != "":
			var pulse := 0.5 + 0.5 * sin(_t * 1.8)
			for q in 3:
				U.growth(pts, cols, Vector2(20.0 + float(q) * (w - 40.0) / 2.0, -2.0), 0.9, seed_v % 50 + q * 7, pulse)
		U.flush(self, pts, cols)
		DrawBatch.string(self, ThemeDB.fallback_font, Vector2(w * 0.3, -tier + 22.0), "Nº %d" % (100 + seed_v % 800), HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(1, 1, 1, 0.45))
		if words != "":
			U.hive_words(self, Vector2(10.0, -tier * 0.36), w - 20.0, words, 0.5 + 0.5 * sin(_t * 1.8), 17)

	func _window(pts: PackedVector2Array, cols: PackedColorArray, c: Vector2, r: RandomNumberGenerator) -> void:
		U.rect(pts, cols, Rect2(c.x - 3.0, c.y - 3.0, 32.0, 40.0), Color("ece8e0"))
		var k := r.randf()
		var glass := Color("1a1c26") if k < 0.55 else (Color(1.0, 0.75, 0.4, 0.9) if k < 0.75 else Color(0.45, 0.95, 0.5, 0.7))
		U.rect(pts, cols, Rect2(c.x, c.y, 26.0, 34.0), glass)
		U.rect(pts, cols, Rect2(c.x + 12.0, c.y, 2.0, 34.0), Color("ece8e0"))
		U.rect(pts, cols, Rect2(c.x, c.y + 15.0, 26.0, 2.0), Color("ece8e0"))
		if k > 0.75:   # מישהו עומד בחלון ומחכה לקצב
			U.oval(pts, cols, Vector2(c.x + 7.0, c.y + 12.0), 4.0, 5.0, Color(0.06, 0.07, 0.08, 0.9), 8)
			U.rect(pts, cols, Rect2(c.x + 2.0, c.y + 17.0, 10.0, 17.0), Color(0.06, 0.07, 0.08, 0.9))
			U.rect(pts, cols, Rect2(c.x + 8.0, c.y + 11.0, 1.4, 1.0), SPORE)
		if r.randf() < 0.25:   # זכוכית שבורה
			U.tri(pts, cols, Vector2(c.x + 14.0, c.y + 17.0), Vector2(c.x + 26.0, c.y + 17.0), Vector2(c.x + 26.0, c.y + 30.0), Color("0e0e14"))


# ============================================================
#  רכבת קצה העולם (פעם רכבת האסירים של הכלא): קרונות עץ (גגות = קומה) + קטר קיטור בחזית (ימינה). מלאה נוסעים שמחכים.
# ============================================================
class EndTrain extends Node2D:
	const COACH_W := 180.0
	const GAP := 16.0
	const LOCO_W := 230.0
	var coaches := 2
	var tier := 112.0                 # גובה גג הקרון (הקומה)
	var _t := 0.0

	func total_w() -> float:
		return float(coaches) * (COACH_W + GAP) + LOCO_W

	func loco_x() -> float:
		return float(coaches) * (COACH_W + GAP)

	func _ready() -> void:
		z_index = -1

	func _process(delta: float) -> void:
		_t += delta
		if Engine.get_process_frames() % 5 == 0 and Art.on_screen(self, global_position + Vector2(total_w() * 0.5, -100), total_w() * 0.6):
			queue_redraw()

	func _draw() -> void:
		DrawBatch.begin(self)
		_draw_b()
		DrawBatch.end(self)

	func _draw_b() -> void:
		var pts := PackedVector2Array()
		var cols := PackedColorArray()
		var tw := total_w()
		# מסילה צרה: אדנים + פסים
		for q in int((tw + 400.0) / 22.0):
			U.rect(pts, cols, Rect2(-200.0 + float(q) * 22.0, -5.0, 14.0, 5.0), WOOD_D)
		U.rect(pts, cols, Rect2(-200.0, -8.0, tw + 400.0, 2.4), Color("5a5a60"))
		var ph := _t / BEAT
		# הקרונות: עץ אדום-חום, חלונות, נוסעים בצל עם עיניים ירוקות (מתנדנדים כולם יחד)
		for c in coaches:
			var cx := float(c) * (COACH_W + GAP)
			U.vrect(pts, cols, Rect2(cx, -tier + 8.0, COACH_W, tier - 26.0), Color("8a3426"), Color("5a1e16"))
			U.rect(pts, cols, Rect2(cx, -tier + 52.0, COACH_W, 3.0), Color("c8a040"))
			for q in 5:
				var wx := cx + 12.0 + float(q) * 34.0
				U.rect(pts, cols, Rect2(wx, -tier + 20.0, 24.0, 26.0), Color("1a1418"))
				var nod := sin(ph * PI) * 1.4
				U.oval(pts, cols, Vector2(wx + 12.0, -tier + 34.0 + nod), 5.0, 6.0, Color(0.05, 0.05, 0.07), 8)
				U.rect(pts, cols, Rect2(wx + 6.0, -tier + 39.0 + nod, 12.0, 8.0), Color(0.05, 0.05, 0.07))
				U.rect(pts, cols, Rect2(wx + 13.0, -tier + 32.0 + nod, 1.6, 1.2), SPORE)
				U.rect(pts, cols, Rect2(wx - 1.0, -tier + 18.0, 26.0, 2.0), Color("c8a040"))
			# גג קשתי עם שלג
			U.quad(pts, cols, Vector2(cx - 6.0, -tier + 8.0), Vector2(cx + COACH_W + 6.0, -tier + 8.0), Vector2(cx + COACH_W - 4.0, -tier), Vector2(cx + 4.0, -tier), Color("3a2a24"), Color("3a2a24"), Color("4a3a32"), Color("4a3a32"))
			U.oval(pts, cols, Vector2(cx + COACH_W * 0.5, -tier - 1.0), COACH_W * 0.48, 3.5, SNOW, 14)
			# שלדה + גלגלים
			U.rect(pts, cols, Rect2(cx + 6.0, -18.0, COACH_W - 12.0, 6.0), IRON)
			for q in 2:
				U.oval(pts, cols, Vector2(cx + 30.0 + float(q) * (COACH_W - 60.0), -10.0), 9.0, 9.0, Color("1a1a1e"), 10)
				U.oval(pts, cols, Vector2(cx + 30.0 + float(q) * (COACH_W - 60.0), -10.0), 3.0, 3.0, Color("6a6a70"), 6)
			# מצמד
			U.rect(pts, cols, Rect2(cx + COACH_W, -16.0, GAP, 4.0), IRON)
			# גידול ECHO מתחת לחלונות
			U.growth(pts, cols, Vector2(cx + COACH_W * 0.7, -tier + 56.0), 0.7, c * 13 + 3, 0.5 + 0.5 * sin(_t * 1.5))
		# הקטר: תא הנהג (שמאל), דוד ארוך, ארובת יהלום, פנס, פגוש
		var lx := loco_x()
		U.vrect(pts, cols, Rect2(lx, -tier - 38.0, 70.0, tier + 20.0), Color("2a2a30"), Color("16161a"))
		U.rect(pts, cols, Rect2(lx + 12.0, -tier - 26.0, 24.0, 26.0), Color(1.0, 0.7, 0.4, 0.3))
		U.quad(pts, cols, Vector2(lx - 6.0, -tier - 38.0), Vector2(lx + 76.0, -tier - 38.0), Vector2(lx + 70.0, -tier - 48.0), Vector2(lx, -tier - 48.0), Color("8a2a24"), Color("8a2a24"), Color("a03a30"), Color("a03a30"))
		U.oval(pts, cols, Vector2(lx + 35.0, -tier - 49.0), 34.0, 3.0, SNOW, 10)
		var by := -tier + 30.0               # מרכז הדוד
		U.vrect(pts, cols, Rect2(lx + 70.0, by - 30.0, 140.0, 60.0), Color("1e1e24"), Color("2e2e36"))
		U.rect(pts, cols, Rect2(lx + 70.0, by - 22.0, 140.0, 5.0), Color(0.5, 0.5, 0.6, 0.3))
		for q in 3:
			U.rect(pts, cols, Rect2(lx + 90.0 + float(q) * 40.0, by - 30.0, 4.0, 60.0), Color("c8a040"))
		U.oval(pts, cols, Vector2(lx + 210.0, by), 10.0, 30.0, Color("3a3a42"), 12)
		# ארובת יהלום + כיפת הקיטור
		U.rect(pts, cols, Rect2(lx + 172.0, by - 58.0, 14.0, 30.0), Color("1a1a1e"))
		U.quad(pts, cols, Vector2(lx + 162.0, by - 58.0), Vector2(lx + 196.0, by - 58.0), Vector2(lx + 204.0, by - 80.0), Vector2(lx + 154.0, by - 80.0), Color("1a1a1e"), Color("1a1a1e"), Color("2a2a30"), Color("2a2a30"))
		U.oval(pts, cols, Vector2(lx + 120.0, by - 32.0), 14.0, 9.0, Color("c8a040"), 10)
		U.oval(pts, cols, Vector2(lx + 179.0, by - 81.0), 26.0, 3.0, SNOW, 10)
		# פנס קדמי ופגוש
		U.rect(pts, cols, Rect2(lx + 196.0, by - 44.0, 18.0, 14.0), Color("2a2a30"))
		U.oval(pts, cols, Vector2(lx + 214.0, by - 37.0), 4.0, 5.0, Color(1.0, 0.9, 0.6), 8)
		U.quad(pts, cols, Vector2(lx + 200.0, -22.0), Vector2(lx + LOCO_W, -4.0), Vector2(lx + 200.0, -4.0), Vector2(lx + 196.0, -12.0), Color("8a2a24"), Color("8a2a24"), Color("5a1a16"), Color("5a1a16"))
		# גלגלי הנעה גדולים אדומים + מוט
		for q in 3:
			var wc := Vector2(lx + 90.0 + float(q) * 42.0, -18.0)
			U.oval(pts, cols, wc, 17.0, 17.0, Color("1a1a1e"), 14)
			U.oval(pts, cols, wc, 14.0, 14.0, Color("8a2a24"), 14)
			U.oval(pts, cols, wc, 4.0, 4.0, Color("c8a040"), 8)
		U.seg(pts, cols, Vector2(lx + 90.0, -24.0), Vector2(lx + 174.0, -24.0), 3.0, Color("9a9aa0"))
		U.rect(pts, cols, Rect2(lx + 60.0, -40.0, 150.0, 6.0), IRON)
		U.flush(self, pts, cols)
		var f := ThemeDB.fallback_font
		DrawBatch.string(self, f, Vector2(0, -tier + 72.0), "TREN DEL FIN DEL MUNDO", HORIZONTAL_ALIGNMENT_CENTER, COACH_W * float(coaches) + GAP, 13, Color("e8c870"))
		DrawBatch.string(self, f, Vector2(lx + 82.0, by + 2.0), "Nº 2", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("c8a040"))
		# קיטור חלש מהארובה (הקטר עוד חם)
		Kit.soft_glow(self, Vector2(lx + 179.0 + sin(_t * 0.7) * 8.0, by - 110.0), 34.0, Color(0.9, 0.9, 0.95, 0.18), 0.8)
		Kit.soft_glow(self, Vector2(lx + 190.0 + sin(_t * 0.5) * 14.0, by - 150.0), 46.0, Color(0.9, 0.9, 0.95, 0.1), 0.8)


# ============================================================
#  שסתום הקיטור של הקטר (מלכודת): ירייה בשסתום / פיצוץ -> לחץ עולה -> סילון קיטור רותח לאורך הקרקע (dir)
# ============================================================
class SteamValve extends Node2D:
	const WARN_T := 0.45
	const JET_T := 1.5
	const JET_W := 330.0
	const JET_H := 86.0
	const CD := 6.0
	const DMG := 1
	const DMG_Z := 70
	enum {IDLE, WARN, BLAST}
	var dir := 1.0
	var state := IDLE
	var blasts := 0                 # לבדיקות
	var scalded := 0
	var hits := 0
	var _t := 0.0
	var _st := 0.0
	var _cd := 0.0
	var _hit := false
	var _hit_z := {}
	var _said := false
	var _body: StaticBody2D = null

	func _ready() -> void:
		z_index = 2
		add_to_group("hazards")
		add_to_group("blastable")
		_body = ValveBody.new()
		_body.trap = self
		_body.collision_layer = 4
		_body.collision_mask = 0
		_body.add_to_group("no_outline")
		var cs := CollisionShape2D.new()
		var rs := RectangleShape2D.new()
		rs.size = Vector2(30, 30)
		cs.shape = rs
		_body.add_child(cs)
		_body.position = Vector2(-dir * 30.0, -60.0)
		add_child(_body)

	func world_rect() -> Rect2:
		var x0 := global_position.x if dir > 0.0 else global_position.x - JET_W
		return Rect2(Vector2(x0, global_position.y - JET_H), Vector2(JET_W, JET_H))

	func danger_at(p: Vector2, margin := 0.0) -> bool:
		return state != IDLE and world_rect().grow(margin).has_point(p)

	func blast_rect() -> Rect2:
		return Rect2(global_position + Vector2(-dir * 30.0 - 20.0, -80.0), Vector2(40.0, 40.0))

	func hit_by_blast(_c: Vector2, _r: float) -> void:
		trigger()

	func ready_to_fire() -> bool:
		return state == IDLE and _cd <= 0.0

	func trigger() -> void:
		if state != IDLE or _cd > 0.0:
			return
		state = WARN
		_st = WARN_T
		Sfx.play("s61_valve", global_position + Vector2(0, -60), 2.0, 0.1, 2)

	func _process(delta: float) -> void:
		_t += delta
		_cd -= delta
		match state:
			WARN:
				_st -= delta
				if _st <= 0.0:
					state = BLAST
					_st = JET_T
					_hit = false
					_hit_z.clear()
					blasts += 1
					Sfx.play("s61_steam", global_position + Vector2(dir * JET_W * 0.4, -30), 5.0, 0.08, 2)
					var cam := get_viewport().get_camera_2d()
					if cam != null and cam.has_method("shake") and Art.on_screen(self, global_position, 80.0):
						cam.shake(4.0, 0.25)
			BLAST:
				_st -= delta
				_check()
				if Engine.get_process_frames() % 3 == 0 and Art.on_screen(self, global_position, JET_W) and Quality.particles() > 0.3:
					Particles.burst(get_parent(), global_position + Vector2(dir * randf_range(20.0, JET_W), -randf_range(10.0, JET_H)), "mist", Vector2(dir, -0.4), 2)
				if _st <= 0.0:
					state = IDLE
					_cd = CD
		var on := Art.on_screen(self, global_position + Vector2(dir * JET_W * 0.5, -60), JET_W)
		if on and (state != IDLE or Engine.get_process_frames() % 4 == 0):
			queue_redraw()

	func _check() -> void:
		var r := world_rect()
		var pl := get_tree().get_first_node_in_group("player") as Node2D
		if pl != null and not pl.dead and not _hit and r.intersects(pl.body_rect()):
			_hit = true
			hits += 1
			pl.hurt(DMG, Vector2(dir * 0.9, -0.6))
			if not _said and pl.has_method("_say"):
				_said = true
				pl._say("Scalding steam! Stay out of the jet...", Color("ffd0b0"))
		for z in get_tree().get_nodes_in_group("zombies"):
			if z.dead or _hit_z.has(z):
				continue
			var zp: Vector2 = z.global_position
			if zp.x < r.position.x - 10.0 or zp.x > r.end.x + 10.0 or absf(zp.y - global_position.y) > 50.0:
				continue
			_hit_z[z] = true
			scalded += 1
			var dmg := DMG_Z if not z.is_boss() else 25
			z.take_damage(dmg, zp + Vector2(0, -30), Vector2(dir, -0.2), false, {"source": "hazard", "fixed": dmg})
			if not z.dead and z.has_method("stagger"):
				z.stagger(0.7)
			if scalded <= 6 or scalded % 4 == 0:
				z._popup("SCALDED", Color("ffd0b0"), 15, -85.0)

	func _draw() -> void:
		DrawBatch.begin(self)
		_draw_b()
		DrawBatch.end(self)

	func _draw_b() -> void:
		var pts := PackedVector2Array()
		var cols := PackedColorArray()
		var warn := 0.0
		if state == WARN:
			warn = 1.0 - _st / WARN_T
		elif state == BLAST:
			warn = 1.0
		var ready := ready_to_fire()
		# צינור הקיטור מהדוד אל השסתום ואל הפייה ליד הקרקע
		var vc := Vector2(-dir * 30.0, -60.0)
		U.seg(pts, cols, vc + Vector2(0, -40), vc, 8.0, Color("5a5a62"))
		U.seg(pts, cols, vc, Vector2(-dir * 6.0, -24.0), 8.0, Color("5a5a62"))
		U.rect(pts, cols, Rect2(Vector2(-6.0 if dir > 0.0 else -8.0, -32.0), Vector2(14.0, 16.0)), Color("c8a040"))
		# גלגל השסתום האדום (המטרה) - מהבהב כשהוא טעון
		var spin := _t * (10.0 if state == BLAST else 0.0)
		var rc := Color("b02a20") if ready else Color("5a2a24")
		U.oval(pts, cols, vc, 15.0, 15.0, rc, 14)
		for q in 4:
			U.seg(pts, cols, vc, vc + Vector2.from_angle(spin + float(q) * PI * 0.5) * 13.0, 2.6, Color("e05a40") if ready else Color("7a4a40"))
		U.oval(pts, cols, vc, 4.0, 4.0, Color("2a2a30"), 8)
		# מד לחץ
		var gc := vc + Vector2(0, -38.0)
		U.oval(pts, cols, gc, 9.0, 9.0, Color("e8eef0"), 12)
		var ang := lerpf(-2.4, -0.4, warn if state != IDLE else clampf(1.0 - _cd / CD, 0.0, 1.0) * 0.6) + (sin(_t * 30.0) * 0.1 if state != IDLE else 0.0)
		U.seg(pts, cols, gc, gc + Vector2.from_angle(ang) * 7.0, 1.2, Color(0.8, 0.1, 0.1))
		# הסילון: ענני קיטור לבנים שנורים לאורך הקרקע
		if state == BLAST:
			var k := clampf(1.0 - _st / JET_T, 0.0, 1.0)
			var reach := JET_W * minf(1.0, k * 6.0)
			var fade := 1.0 - maxf(0.0, k - 0.7) / 0.3
			for q in 10:
				var u := float(q) / 9.0
				var cx := dir * (14.0 + reach * u)
				var rr := 14.0 + JET_H * 0.45 * u
				U.oval(pts, cols, Vector2(cx + sin(_t * 17.0 + float(q)) * 5.0, -20.0 - rr * 0.6), rr, rr * 0.75, Color(0.96, 0.97, 1.0, (0.55 - 0.035 * float(q)) * fade), 12)
			U.quad(pts, cols, Vector2(dir * 8.0, -30.0), Vector2(dir * 8.0, -16.0), Vector2(dir * reach, -6.0), Vector2(dir * reach, -JET_H), Color(1, 1, 1, 0.8 * fade), Color(1, 1, 1, 0.8 * fade), Color(1, 1, 1, 0.0), Color(1, 1, 1, 0.0))
		elif state == WARN:
			for q in 3:
				U.oval(pts, cols, Vector2(dir * (10.0 + float(q) * 8.0), -24.0 - float(q) * 4.0), 4.0 + 3.0 * warn, 3.0 + 2.0 * warn, Color(1, 1, 1, 0.5), 8)
		U.flush(self, pts, cols)
		if ready:
			Kit.soft_glow(self, vc, 26.0, Color(1.0, 0.4, 0.3, 0.16 + 0.1 * sin(_t * 4.0)), 1.0)
		if state == WARN:
			DrawBatch.string(self, ThemeDB.fallback_font, vc + Vector2(-5.0, -54.0), "!", HORIZONTAL_ALIGNMENT_LEFT, -1, 26, Color(1.0, 0.85, 0.7, 0.6 + 0.4 * sin(_t * 30.0)))


class ValveBody extends StaticBody2D:
	var trap = null

	func take_damage(_amount: int, hit_pos: Vector2, dir: Vector2, _explosive := false, _src := {}) -> void:
		if trap != null and is_instance_valid(trap):
			Particles.burst(trap.get_parent(), hit_pos, "spark", -dir, 5)
			Sfx.play("metal_ping", hit_pos, -2.0, 0.1, 2)
			trap.trigger()


# ============================================================
#  ספינת תענוגות חלודה במזח: גוף כהה עם חלונות עגולים, מבנה עליון לבן, סיפון טיילת (קומה), גשר, ארובה, כתובת הכוורת
# ============================================================
class CruiseShip extends Node2D:
	var w := 1100.0
	var deck := 170.0
	var words := "WE ARE ALL|GOING HOME"
	var _t := 0.0

	func _ready() -> void:
		z_index = -3

	func _process(delta: float) -> void:
		_t += delta
		if Engine.get_process_frames() % 6 == 0 and Art.on_screen(self, global_position + Vector2(w * 0.5, -deck), w * 0.6):
			queue_redraw()

	func _draw() -> void:
		DrawBatch.begin(self)
		_draw_b()
		DrawBatch.end(self)

	func _draw_b() -> void:
		var pts := PackedVector2Array()
		var cols := PackedColorArray()
		var top := -deck - 8.0
		# הגוף: חרטום משופע משמאל, כחול-כהה עם קו מים אדום וחלודה זולגת
		var hull := PackedVector2Array([Vector2(-120.0, top - 30.0), Vector2(w, top), Vector2(w, 10.0), Vector2(-20.0, 10.0)])
		DrawBatch.colored_polygon(self, hull, HULL)
		U.quad(pts, cols, Vector2(-26.0, -12.0), Vector2(w, -12.0), Vector2(w, 10.0), Vector2(-20.0, 10.0), Color("6a1e1a"), Color("6a1e1a"), Color("4a1410"), Color("4a1410"))
		U.quad(pts, cols, Vector2(-120.0, top - 30.0), Vector2(w, top), Vector2(w, top + 8.0), Vector2(-112.0, top - 20.0), Color("e8e4dc"), Color("e8e4dc"), Color("b8b4ac"), Color("b8b4ac"))
		var r := RandomNumberGenerator.new()
		r.seed = 611
		for q in 26:   # חלודה זולגת מהחלונות והמקורות
			var rx := r.randf_range(0.0, w - 10.0)
			var ry := top + r.randf_range(10.0, 60.0)
			var ln := r.randf_range(30.0, 120.0)
			var ww := r.randf_range(3.0, 9.0)
			U.quad(pts, cols, Vector2(rx - ww * 0.5, ry), Vector2(rx + ww * 0.5, ry), Vector2(rx + 1.0, ry + ln), Vector2(rx - 1.0, ry + ln), Color(0.55, 0.24, 0.1, 0.6), Color(0.55, 0.24, 0.1, 0.6), Color(0.55, 0.24, 0.1, 0.0), Color(0.55, 0.24, 0.1, 0.0))
		for row in 2:   # חלונות עגולים
			for q in int(w / 46.0):
				var px := 30.0 + float(q) * 46.0 + float(row) * 23.0
				if px > w - 20.0:
					continue
				var py := top + 34.0 + float(row) * 34.0
				U.oval(pts, cols, Vector2(px, py), 7.0, 7.0, Color("8a8a90"), 10)
				var lit := U.h(q, row + 3)
				U.oval(pts, cols, Vector2(px, py), 5.0, 5.0, Color("10141c") if lit < 0.8 else Color(0.5, 1.0, 0.5, 0.5 + 0.3 * sin(_t * 1.6 + float(q))), 10)
		# עוגן וחבל עגינה
		U.oval(pts, cols, Vector2(-40.0, top + 10.0), 9.0, 9.0, IRON, 10)
		U.seg(pts, cols, Vector2(-40.0, top + 18.0), Vector2(-44.0, top + 58.0), 4.0, IRON)
		# המבנה העליון הלבן (שלוש קומות) מעל הסיפון, עם חלונות שורה
		var sx0 := 80.0
		var sx1 := w - 40.0
		for lvl in 3:
			var y0 := top - float(lvl + 1) * 40.0
			var x0 := sx0 + float(lvl) * 40.0
			var x1 := sx1 - float(lvl) * 30.0
			U.vrect(pts, cols, Rect2(x0, y0, x1 - x0, 40.0), HULL_L, HULL_L.darkened(0.2))
			U.rect(pts, cols, Rect2(x0, y0 - 3.0, x1 - x0, 3.0), Color("c8c4bc"))
			var wq := x0 + 10.0
			var n := 0
			while wq < x1 - 20.0:
				var lit := U.h(n, lvl + 9)
				U.rect(pts, cols, Rect2(wq, y0 + 12.0, 14.0, 12.0), Color("1a1e28") if lit < 0.85 else Color(0.5, 1.0, 0.5, 0.45))
				wq += 22.0
				n += 1
			for q in 8:   # חלודה זולגת על הלבן
				var rx2 := lerpf(x0, x1, U.h(q, lvl + 20))
				U.quad(pts, cols, Vector2(rx2 - 2.0, y0 + 26.0), Vector2(rx2 + 2.0, y0 + 26.0), Vector2(rx2 + 1.0, y0 + 40.0 + U.h(q, lvl) * 20.0), Vector2(rx2 - 1.0, y0 + 40.0 + U.h(q, lvl) * 20.0), Color(0.6, 0.3, 0.12, 0.55), Color(0.6, 0.3, 0.12, 0.55), Color(0.6, 0.3, 0.12, 0.0), Color(0.6, 0.3, 0.12, 0.0))
		# הגשר (חלון ארוך משופע) בצד החרטום
		U.quad(pts, cols, Vector2(sx0 + 80.0, top - 120.0), Vector2(sx0 + 240.0, top - 120.0), Vector2(sx0 + 230.0, top - 150.0), Vector2(sx0 + 100.0, top - 150.0), HULL_L, HULL_L, HULL_L.darkened(0.1), HULL_L.darkened(0.1))
		U.rect(pts, cols, Rect2(sx0 + 106.0, top - 144.0, 118.0, 12.0), Color("1a1e28"))
		U.oval(pts, cols, Vector2(sx0 + 160.0, top - 151.0), 70.0, 3.0, SNOW, 10)
		# הארובה: לבנה עם פס אדום, חלודה, בלי עשן (מתה)
		var fx := w * 0.62
		U.quad(pts, cols, Vector2(fx, top - 120.0), Vector2(fx + 70.0, top - 120.0), Vector2(fx + 80.0, top - 210.0), Vector2(fx + 20.0, top - 210.0), HULL_L.darkened(0.08), HULL_L.darkened(0.08), HULL_L, HULL_L)
		U.quad(pts, cols, Vector2(fx + 4.0, top - 150.0), Vector2(fx + 73.0, top - 150.0), Vector2(fx + 76.0, top - 170.0), Vector2(fx + 10.0, top - 170.0), Color("a02a24"), Color("a02a24"), Color("b83a30"), Color("b83a30"))
		U.rect(pts, cols, Rect2(fx + 18.0, top - 214.0, 64.0, 6.0), Color("1a1a1e"))
		U.oval(pts, cols, Vector2(fx + 50.0, top - 215.0), 34.0, 3.0, SNOW, 10)
		# תורן
		U.rect(pts, cols, Rect2(sx0 + 150.0, top - 230.0, 3.0, 80.0), Color("2a2a30"))
		U.seg(pts, cols, Vector2(sx0 + 151.0, top - 228.0), Vector2(-110.0, top - 32.0), 1.0, Color(0.15, 0.15, 0.18, 0.7))
		# סיפון הטיילת: מעקה לבן לכל האורך (זו הקומה)
		U.rect(pts, cols, Rect2(-60.0, -deck - 2.0, w + 60.0, 8.0), Color("c8c4bc"))
		for q in int((w + 60.0) / 14.0) + 1:
			U.rect(pts, cols, Rect2(-60.0 + float(q) * 14.0, -deck - 28.0, 2.0, 26.0), Color("e8e4dc"))
		U.rect(pts, cols, Rect2(-60.0, -deck - 30.0, w + 60.0, 3.0), Color("e8e4dc"))
		# גידולי ECHO על הגוף + שורשים שיורדים למים
		var pulse := 0.5 + 0.5 * sin(_t * 1.5)
		for q in 5:
			var gx := 120.0 + float(q) * (w - 200.0) / 4.0
			U.root(pts, cols, Vector2(gx, top + 20.0), Vector2(gx + 20.0, 6.0), 6.0, _t, 10.0, q * 3, Color(0.78, 0.8, 0.6, 0.85), Color(0.5, 0.9, 0.45, 0.6))
			U.growth(pts, cols, Vector2(gx, top + 20.0), 1.0, q * 11 + 2, pulse)
		U.flush(self, pts, cols)
		var f := ThemeDB.fallback_font
		DrawBatch.string(self, f, Vector2(-60.0, top + 26.0), "PAMPA SERENA", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(0.9, 0.88, 0.84, 0.85))
		DrawBatch.string(self, f, Vector2(-40.0, top + 44.0), "USHUAIA", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.9, 0.88, 0.84, 0.6))
		U.hive_words(self, Vector2(w * 0.3, top + 70.0), w * 0.4, words, pulse, 24)


# ============================================================
#  סירת הצלה תלויה בשני חבלים (מלכודת): ירייה בחבל / פיצוץ -> נופלת ומועכת את מה שמתחת. זזה ב-_process.
# ============================================================
class Lifeboat extends Node2D:
	const W := 130.0
	const H := 40.0
	const G := 1500.0
	const DMG := 2
	const DMG_Z := 160
	enum {HANG, FALL, DOWN}
	var hang := 128.0              # גובה תחתית הסירה מעל המזח
	var davit := 230.0             # גובה זרועות המנוף (מקום החבלים)
	var state := HANG
	var crushed := 0               # לבדיקות
	var hits := 0
	var _y := 0.0                  # כמה נפלה
	var _vy := 0.0
	var _t := 0.0
	var _cut := [false, false]
	var _tilt := 0.0
	var _bodies := []
	var _done := {}

	func _ready() -> void:
		z_index = 1
		add_to_group("blastable")
		for i in 2:
			var b := RopeBody.new()
			b.trap = self
			b.idx = i
			b.collision_layer = 4
			b.collision_mask = 0
			b.add_to_group("no_outline")
			var cs := CollisionShape2D.new()
			var rs := RectangleShape2D.new()
			rs.size = Vector2(16, davit - hang - H)
			cs.shape = rs
			b.add_child(cs)
			b.position = Vector2(_rope_x(i), -(davit + hang + H) * 0.5)
			add_child(b)
			_bodies.append(b)

	func _rope_x(i: int) -> float:
		return 18.0 if i == 0 else W - 18.0

	func blast_rect() -> Rect2:
		return Rect2(global_position + Vector2(0, -davit), Vector2(W, davit - hang + 10.0))

	func hit_by_blast(_c: Vector2, _r: float) -> void:
		drop()

	func cut(i: int) -> void:
		if state != HANG or _cut[i]:
			return
		_cut[i] = true
		Sfx.play("s61_snap", global_position + Vector2(_rope_x(i), -davit + 30.0), 0.0, 0.1, 2)
		(_bodies[i] as StaticBody2D).collision_layer = 0
		drop()

	func drop() -> void:
		if state != HANG:
			return
		state = FALL
		_vy = 0.0
		for b in _bodies:
			(b as StaticBody2D).collision_layer = 0
		_tilt = -0.12 if _cut[0] else 0.12
		Sfx.play("s61_creak", global_position + Vector2(W * 0.5, -hang), 2.0, 0.1, 2)

	func _process(delta: float) -> void:
		_t += delta
		if state == FALL:
			_vy += G * delta
			_y += _vy * delta
			if _y >= hang:
				_y = hang
				_land()
			else:
				_crush(Rect2(global_position + Vector2(0.0, -hang + _y - H), Vector2(W, H + 10.0)))
			queue_redraw()
		elif Engine.get_process_frames() % 6 == 0 and Art.on_screen(self, global_position + Vector2(W * 0.5, -hang), 200.0):
			queue_redraw()

	func _land() -> void:
		state = DOWN
		var at := global_position + Vector2(W * 0.5, 0.0)
		Sfx.play("s61_crash", at, 6.0, 0.08, 2)
		var cam := get_viewport().get_camera_2d()
		if cam != null and cam.has_method("shake") and Art.on_screen(self, global_position, 120.0):
			cam.shake(9.0, 0.35)
		Particles.burst(get_parent(), at + Vector2(0, -10), "smoke", Vector2.UP, 12)
		if Quality.particles() > 0.3:
			for i in Quality.scaled(10, 4):
				var d = DebrisScript.new()
				get_parent().add_child(d)
				d.setup(at + Vector2(randf_range(-W * 0.5, W * 0.5), -20.0), Vector2(randf_range(4.0, 10.0), 3.0), Color("e06a30") if i % 2 == 0 else Color("e8e4dc"), Vector2(randf_range(-260.0, 260.0), -randf_range(120.0, 340.0)))
		_crush(Rect2(global_position + Vector2(-6.0, -H - 20.0), Vector2(W + 12.0, H + 24.0)))

	# מה שבתוך המלבן של הסירה (בנפילה ובנחיתה) נמעך - פעם אחת לכל אחד
	func _crush(r: Rect2) -> void:
		var pl := get_tree().get_first_node_in_group("player") as Node2D
		if pl != null and not pl.dead and not _done.has(pl) and r.intersects(pl.body_rect()):
			_done[pl] = true
			hits += 1
			pl.hurt(DMG, Vector2(signf(pl.global_position.x - r.get_center().x + 0.01) * 1.2, -0.5))
		for z in get_tree().get_nodes_in_group("zombies"):
			if z.dead or _done.has(z):
				continue
			var zr := Rect2(z.global_position + Vector2(-14.0 * z.sc, -56.0 * z.sc), Vector2(28.0 * z.sc, 56.0 * z.sc))
			if not zr.intersects(r):
				continue
			_done[z] = true
			crushed += 1
			var dmg := DMG_Z if not z.is_boss() else 60
			z.take_damage(dmg, z.global_position + Vector2(0, -20), Vector2.DOWN, false, {"source": "hazard", "fixed": dmg})
			if crushed <= 4:
				z._popup("CRUSHED", Color("ffb070"), 16, -80.0)

	func _draw() -> void:
		DrawBatch.begin(self)
		_draw_b()
		DrawBatch.end(self)

	func _draw_b() -> void:
		var pts := PackedVector2Array()
		var cols := PackedColorArray()
		# זרועות המנוף (davits) - מגיעות מהסיפון
		for i in 2:
			var rx := _rope_x(i)
			U.strip(pts, cols, PackedVector2Array([Vector2(rx - 12.0, -davit + 60.0), Vector2(rx - 16.0, -davit + 10.0), Vector2(rx - 6.0, -davit - 4.0), Vector2(rx, -davit)]), 7.0, 4.0, Color("d8d4cc"), Color("a8a49c"))
			U.oval(pts, cols, Vector2(rx, -davit), 4.0, 4.0, IRON, 8)
		var bot := -hang + _y           # תחתית הסירה
		var c := Vector2(W * 0.5, bot - H * 0.5)
		var tilt := _tilt if state != HANG else sin(_t * 0.8) * 0.02
		if state == DOWN:
			tilt = _tilt * 0.6
		var cs := cos(tilt)
		var sn := sin(tilt)
		# החבלים
		if state == HANG:
			for i in 2:
				var rx := _rope_x(i)
				var bp := c + Vector2((rx - W * 0.5) * cs, (rx - W * 0.5) * sn) + Vector2(0, -H * 0.5)
				U.seg(pts, cols, Vector2(rx, -davit), bp, 2.0, Color("c8b890"))
		else:
			for i in 2:   # קצוות קרועים מתנדנדים
				var rx := _rope_x(i)
				U.seg(pts, cols, Vector2(rx, -davit), Vector2(rx + sin(_t * 3.0 + float(i)) * 4.0, -davit + 30.0), 2.0, Color("c8b890"))
		# הגוף הכתום של הסירה (צורת סירה: תחתית מעוגלת), כיסוי לבן, שם
		var hull := [Vector2(-W * 0.5, -H * 0.5), Vector2(W * 0.5, -H * 0.5), Vector2(W * 0.5 - 8.0, H * 0.1), Vector2(W * 0.3, H * 0.5), Vector2(-W * 0.3, H * 0.5), Vector2(-W * 0.5 + 8.0, H * 0.1)]
		var poly := PackedVector2Array()
		for v in hull:
			poly.append(c + Vector2(v.x * cs - v.y * sn, v.x * sn + v.y * cs))
		DrawBatch.colored_polygon(self, poly, Color("e0662a") if state != DOWN else Color("b0501e"))
		var cov := [Vector2(-W * 0.48, -H * 0.5), Vector2(W * 0.48, -H * 0.5), Vector2(W * 0.3, -H * 0.95), Vector2(-W * 0.3, -H * 0.95)]
		var cp := PackedVector2Array()
		for v in cov:
			cp.append(c + Vector2(v.x * cs - v.y * sn, v.x * sn + v.y * cs))
		DrawBatch.colored_polygon(self, cp, Color("e8e4dc"))
		U.oval(pts, cols, c + Vector2(0, -H * 0.95).rotated(tilt), W * 0.28, 3.0, SNOW, 10, tilt)
		if state == DOWN:   # שבורה: סדק וקרשים
			U.seg(pts, cols, c + Vector2(-10, -14).rotated(tilt), c + Vector2(6, 16).rotated(tilt), 3.0, Color("2a1410"))
			U.seg(pts, cols, c + Vector2(20, -10).rotated(tilt), c + Vector2(30, 14).rotated(tilt), 2.0, Color("2a1410"))
		U.flush(self, pts, cols)
		DrawBatch.string(self, ThemeDB.fallback_font, c + Vector2(-30.0, 6.0), "P. SERENA", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(1, 1, 1, 0.7))


class RopeBody extends StaticBody2D:
	var trap = null
	var idx := 0

	func take_damage(_amount: int, hit_pos: Vector2, dir: Vector2, _explosive := false, _src := {}) -> void:
		if trap != null and is_instance_valid(trap):
			Particles.burst(trap.get_parent(), hit_pos, "hit", -dir, 3)
			trap.cut(idx)


# ============================================================
#  מדורה ברחוב (ערימת רהיטים בוערת): עמוד אוויר חם שעולה גבוה עם ניצוצות ואפר - הזרם העולה של הקונדורים
# ============================================================
class Pyre extends Node2D:
	const COLUMN := 560.0
	var seed_v := 0
	var _t := 0.0

	func _ready() -> void:
		z_index = -1

	func _process(delta: float) -> void:
		_t += delta
		if Engine.get_process_frames() % 3 == 0 and Art.on_screen(self, global_position + Vector2(0, -COLUMN * 0.5), COLUMN * 0.5):
			queue_redraw()

	func _draw() -> void:
		DrawBatch.begin(self)
		_draw_b()
		DrawBatch.end(self)

	func _draw_b() -> void:
		var pts := PackedVector2Array()
		var cols := PackedColorArray()
		var fl := 0.75 + 0.25 * sin(_t * 9.0) * sin(_t * 5.3 + float(seed_v))
		# עמוד האוויר החם: רצועות שקופות שמתעוותות (גלי חום) - מוצגות גבוה, עד לשמיים
		for q in 7:
			var y0 := -40.0 - float(q) * COLUMN / 7.0
			var y1 := y0 - COLUMN / 7.0
			var wv := sin(_t * 2.0 + float(q) * 1.3) * 10.0
			var w0 := 34.0 + float(q) * 9.0
			var w1 := w0 + 9.0
			var a := 0.07 * (1.0 - float(q) / 7.0)
			U.quad(pts, cols, Vector2(-w0 + wv, y0), Vector2(w0 + wv, y0), Vector2(w1 - wv, y1), Vector2(-w1 - wv, y1), Color(1.0, 0.75, 0.55, a), Color(1.0, 0.75, 0.55, a), Color(1.0, 0.75, 0.55, a * 0.6), Color(1.0, 0.75, 0.55, a * 0.6))
		# ניצוצות ואפר שעולים בספירלה
		for q in 26:
			var ph := fposmod(_t * (0.18 + U.h(q, seed_v) * 0.12) + U.h(q, 2), 1.0)
			var yy := -30.0 - ph * COLUMN
			var xx := sin(ph * 9.0 + float(q)) * (14.0 + ph * 60.0)
			var spark := q % 3 != 0
			var col := Color(1.0, 0.7, 0.3, (1.0 - ph) * 0.9) if spark else Color(0.3, 0.28, 0.3, (1.0 - ph) * 0.6)
			U.dia(pts, cols, Vector2(xx, yy), 1.6 if spark else 2.4, col)
		# הערימה: קורות, רגלי כיסאות, מזרן, צמיג
		U.seg(pts, cols, Vector2(-46, -4), Vector2(40, -30), 8.0, Color("2a1a12"))
		U.seg(pts, cols, Vector2(44, -4), Vector2(-30, -36), 8.0, Color("2a1a12"))
		U.seg(pts, cols, Vector2(-20, -2), Vector2(-8, -44), 5.0, Color("3a2416"))
		U.oval(pts, cols, Vector2(30, -12), 14.0, 12.0, Color("161414"), 12)
		U.oval(pts, cols, Vector2(30, -12), 6.0, 5.0, Color("2a2626"), 8)
		U.quad(pts, cols, Vector2(-40, -8), Vector2(-6, -16), Vector2(-4, -26), Vector2(-40, -18), Color("6a4a5a"), Color("6a4a5a"), Color("4a3440"), Color("4a3440"))
		# הלהבות
		for q in 6:
			var fx := -30.0 + float(q) * 12.0
			var fh := (34.0 + U.h(q, seed_v + 4) * 30.0) * fl * (0.8 + 0.2 * sin(_t * 11.0 + float(q) * 2.0))
			U.tri(pts, cols, Vector2(fx - 9.0, -10.0), Vector2(fx + 9.0, -10.0), Vector2(fx + sin(_t * 7.0 + float(q)) * 5.0, -10.0 - fh), Color(1.0, 0.45, 0.1, 0.85))
			U.tri(pts, cols, Vector2(fx - 5.0, -10.0), Vector2(fx + 5.0, -10.0), Vector2(fx + sin(_t * 7.0 + float(q)) * 3.0, -10.0 - fh * 0.6), Color(1.0, 0.85, 0.35, 0.9))
		U.oval(pts, cols, Vector2(0, -1.0), 54.0, 4.0, Color(0.1, 0.08, 0.06, 0.7), 12)
		U.flush(self, pts, cols)
		Kit.soft_glow(self, Vector2(0, -30.0), 110.0, Color(1.0, 0.5, 0.18, 0.24 * fl), 0.6)
		Kit.soft_glow(self, Vector2(0, -COLUMN * 0.55), 90.0, Color(1.0, 0.7, 0.5, 0.05), 0.4)


# ============================================================
#  מכשולים (מוצקים + מחסה)
# ============================================================
class Obstacle extends Node2D:
	var kind := "car"
	var size := Vector2(110, 52)
	var seed_v := 0

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

	func _draw() -> void:
		DrawBatch.begin(self)
		_draw_b()
		DrawBatch.end(self)

	func _draw_b() -> void:
		var w := size.x
		var h := size.y
		var r := RandomNumberGenerator.new()
		r.seed = seed_v
		var pts := PackedVector2Array()
		var cols := PackedColorArray()
		match kind:
			"car":   # מכונית קטנה חלודה, שלג על הגג והמכסה, דלת פתוחה
				var body: Color = TIN[r.randi() % 7].darkened(0.35)
				U.oval(pts, cols, Vector2(w * 0.5, 0), w * 0.52, 3.0, Color(0.05, 0.05, 0.07, 0.6), 12)
				U.quad(pts, cols, Vector2(0, -8.0), Vector2(w, -8.0), Vector2(w - 2.0, -h * 0.55), Vector2(2.0, -h * 0.6), body.darkened(0.25), body.darkened(0.25), body, body)
				U.quad(pts, cols, Vector2(w * 0.2, -h * 0.6), Vector2(w * 0.8, -h * 0.56), Vector2(w * 0.68, -h), Vector2(w * 0.3, -h), body, body, body.lightened(0.08), body.lightened(0.08))
				U.quad(pts, cols, Vector2(w * 0.27, -h * 0.62), Vector2(w * 0.48, -h * 0.6), Vector2(w * 0.48, -h * 0.94), Vector2(w * 0.33, -h * 0.94), Color("181a22"), Color("181a22"), Color("2a2e3a"), Color("2a2e3a"))
				U.quad(pts, cols, Vector2(w * 0.52, -h * 0.6), Vector2(w * 0.74, -h * 0.58), Vector2(w * 0.65, -h * 0.94), Vector2(w * 0.52, -h * 0.94), Color("181a22"), Color("181a22"), Color("2a2e3a"), Color("2a2e3a"))
				for q in 8:   # חלודה
					U.oval(pts, cols, Vector2(r.randf_range(4.0, w - 4.0), -r.randf_range(10.0, h * 0.5)), r.randf_range(2.0, 6.0), r.randf_range(1.5, 4.0), RUST.darkened(r.randf() * 0.3), 6)
				for q in 2:
					U.oval(pts, cols, Vector2(w * (0.2 + 0.6 * float(q)), -8.0), 10.0, 10.0, Color("141418"), 12)
					U.oval(pts, cols, Vector2(w * (0.2 + 0.6 * float(q)), -8.0), 4.0, 4.0, Color("5a5a60"), 8)
				U.oval(pts, cols, Vector2(w * 0.5, -h - 1.0), w * 0.22, 4.0, SNOW, 10)
				U.oval(pts, cols, Vector2(w * 0.12, -h * 0.58), w * 0.12, 3.0, SNOW, 8)
				U.oval(pts, cols, Vector2(w * 0.9, -h * 0.55), w * 0.1, 3.0, SNOW, 8)
				U.rect(pts, cols, Rect2(w - 6.0, -h * 0.45, 6.0, 5.0), Color(1.0, 0.85, 0.5, 0.6))
			"traps":   # מלכודות סרטנים (סנטויה): כלובים עגולים מרשת, ערימה של שלוש, עם מצופים
				for q in 3:
					var c := Vector2(w * (0.25 + 0.5 * float(q % 2)), -h * 0.28) if q < 2 else Vector2(w * 0.5, -h * 0.74)
					var rx := w * 0.26
					var ry := h * 0.27
					U.oval(pts, cols, c, rx, ry, Color("2a3a4a"), 14)
					U.oval(pts, cols, c, rx - 3.0, ry - 3.0, Color("10161e"), 14)
					for g in 5:   # הרשת
						U.rect(pts, cols, Rect2(c.x - rx + 4.0 + float(g) * (rx * 2.0 - 8.0) / 4.0, c.y - ry + 3.0, 1.0, ry * 2.0 - 6.0), Color("5a7a8a"))
					U.rect(pts, cols, Rect2(c.x - rx + 3.0, c.y - 1.0, rx * 2.0 - 6.0, 1.4), Color("5a7a8a"))
					if q == 0:   # סרטן אדום שנשאר בפנים
						U.oval(pts, cols, c + Vector2(4, 4), 8.0, 5.0, Color("b8301a"), 10)
				U.oval(pts, cols, Vector2(w * 0.9, -h * 0.2), 7.0, 7.0, Color("e8502a"), 10)
				U.oval(pts, cols, Vector2(w * 0.08, -h * 0.55), 6.0, 6.0, Color("e8c82a"), 10)
				U.oval(pts, cols, Vector2(w * 0.5, -h - 1.0), w * 0.18, 3.0, SNOW, 10)
			"drums":   # חביות דלק
				for q in 3:
					var dx := float(q) * w / 3.0
					var c: Color = [Color("2a5a7a"), Color("8a2a24"), Color("4a5a3a")][(r.randi() + q) % 3]
					U.vrect(pts, cols, Rect2(dx + 1.0, -h, w / 3.0 - 2.0, h), c.lightened(0.1), c.darkened(0.3))
					U.rect(pts, cols, Rect2(dx + 1.0, -h * 0.68, w / 3.0 - 2.0, 2.4), Color(0, 0, 0, 0.4))
					U.rect(pts, cols, Rect2(dx + 1.0, -h * 0.34, w / 3.0 - 2.0, 2.4), Color(0, 0, 0, 0.4))
					U.oval(pts, cols, Vector2(dx + w / 6.0, -h), w / 6.0 - 1.0, 3.0, SNOW, 10)
			"crates":   # ארגזי דגים פלסטיק (כחול/אדום) בערימה
				for q in 3:
					var bx := 0.0 if q == 0 else (w * 0.5 if q == 1 else w * 0.22)
					var by := 0.0 if q < 2 else -h * 0.5
					var c: Color = Color("2a6aa0") if (q + seed_v) % 2 == 0 else Color("b83a2a")
					U.vrect(pts, cols, Rect2(bx, by - h * 0.5, w * 0.5 - 2.0, h * 0.5 - 1.0), c.lightened(0.1), c.darkened(0.25))
					for g in 3:
						U.rect(pts, cols, Rect2(bx + 6.0 + float(g) * (w * 0.5 - 16.0) / 2.0, by - h * 0.38, 4.0, h * 0.26), c.darkened(0.45))
					U.oval(pts, cols, Vector2(bx + w * 0.25, by - h * 0.5), w * 0.2, 2.4, SNOW, 8)
			_:   # מכולה (חלודה, דלתות, כתובת)
				var c: Color = [Color("2a5a7a"), Color("8a2a24"), Color("3a6a3a"), Color("c8701a")][r.randi() % 4]
				U.vrect(pts, cols, Rect2(0, -h, w, h), c.lightened(0.05), c.darkened(0.3))
				U.ribs(pts, cols, Rect2(0, -h, w, h), 8.0, Color(0, 0, 0, 0.18))
				U.rect(pts, cols, Rect2(w - 30.0, -h + 4.0, 2.0, h - 8.0), Color(0, 0, 0, 0.5))
				U.rect(pts, cols, Rect2(w - 16.0, -h + 4.0, 2.0, h - 8.0), Color(0, 0, 0, 0.5))
				for q in 10:
					U.oval(pts, cols, Vector2(r.randf_range(4.0, w - 4.0), -r.randf_range(4.0, h - 4.0)), r.randf_range(3.0, 9.0), r.randf_range(2.0, 6.0), RUST.darkened(r.randf() * 0.3), 6)
				U.rect(pts, cols, Rect2(0, -h - 3.0, w, 4.0), SNOW)
		U.flush(self, pts, cols)
		if kind == "container":
			DrawBatch.string(self, ThemeDB.fallback_font, Vector2(10.0, -h * 0.5), "TDF CARGO", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(1, 1, 1, 0.5))


# ============================================================
#  זירת הבוס: החצר מול הכלא הישן (CARCEL DE USHUAIA 1902). בסוף - השער שיורד למטה, ושורשי ECHO שיוצאים ממנו
# ============================================================
class Presidio extends Node2D:
	var w := 1240.0
	var gate_x := 1010.0            # מרכז השער (היציאה של השלב)
	var _t := 0.0

	func _ready() -> void:
		z_index = -3

	func _process(delta: float) -> void:
		_t += delta
		if Engine.get_process_frames() % 4 == 0 and Art.on_screen(self, global_position + Vector2(w * 0.5, -150), w * 0.6):
			queue_redraw()

	func _draw() -> void:
		DrawBatch.begin(self)
		_draw_b()
		DrawBatch.end(self)

	func _draw_b() -> void:
		var pts := PackedVector2Array()
		var cols := PackedColorArray()
		var pulse := 0.5 + 0.5 * sin(_t * 1.3)
		var wall_h := 250.0
		# החזית: שתי קומות של אבן אפורה-צהבהבה, חלונות קשתיים עם סורגים
		U.vrect(pts, cols, Rect2(0, -wall_h, gate_x - 140.0, wall_h), Color("8c8474"), Color("5e574c"))
		for row in 2:
			var yy := -wall_h + 40.0 + float(row) * 100.0
			U.rect(pts, cols, Rect2(0, yy + 70.0, gate_x - 140.0, 4.0), Color("6e675c"))
			var x := 30.0
			var i := 0
			while x < gate_x - 180.0:
				U.rect(pts, cols, Rect2(x, yy, 30.0, 46.0), Color("16161a"))
				U.oval(pts, cols, Vector2(x + 15.0, yy), 15.0, 10.0, Color("16161a"), 10)
				for b in 4:
					U.rect(pts, cols, Rect2(x + 4.0 + float(b) * 7.0, yy - 6.0, 2.0, 52.0), Color("4a4a50"))
				if U.h(i, row + 5) > 0.7:   # עיניים ירוקות מאחורי הסורגים
					U.rect(pts, cols, Rect2(x + 10.0, yy + 16.0, 2.0, 1.4), SPORE)
					U.rect(pts, cols, Rect2(x + 17.0, yy + 16.0, 2.0, 1.4), SPORE)
				U.rect(pts, cols, Rect2(x - 4.0, yy + 46.0, 38.0, 3.0), SNOW_S)
				x += 70.0
				i += 1
		U.rect(pts, cols, Rect2(-4.0, -wall_h - 10.0, gate_x - 132.0, 12.0), Color("6e675c"))
		U.rect(pts, cols, Rect2(-4.0, -wall_h - 13.0, gate_x - 132.0, 4.0), SNOW)
		# המגדל המרכזי (מרכז הכוכב של הכלא)
		var tx := (gate_x - 140.0) * 0.45
		U.vrect(pts, cols, Rect2(tx - 60.0, -wall_h - 90.0, 120.0, 92.0), Color("948c7c"), Color("7a7264"))
		U.tri(pts, cols, Vector2(tx - 70.0, -wall_h - 90.0), Vector2(tx, -wall_h - 140.0), Vector2(tx + 70.0, -wall_h - 90.0), Color("4a4a50"))
		U.tri(pts, cols, Vector2(tx - 40.0, -wall_h - 108.0), Vector2(tx, -wall_h - 140.0), Vector2(tx + 40.0, -wall_h - 108.0), SNOW)
		U.oval(pts, cols, Vector2(tx, -wall_h - 50.0), 18.0, 18.0, Color("e8e0cc"), 16)
		U.seg(pts, cols, Vector2(tx, -wall_h - 50.0), Vector2(tx, -wall_h - 63.0), 2.0, Color("1a1a1e"))
		U.seg(pts, cols, Vector2(tx, -wall_h - 50.0), Vector2(tx + 8.0, -wall_h - 50.0), 2.0, Color("1a1a1e"))
		# חומת חצר נמוכה עם תיל בחזית
		for q in int((gate_x - 140.0) / 40.0):
			var px := float(q) * 40.0
			U.rect(pts, cols, Rect2(px, -wall_h - 34.0, 2.0, 22.0), Color("2a2a2e"))
			U.seg(pts, cols, Vector2(px, -wall_h - 30.0), Vector2(px + 40.0, -wall_h - 26.0), 1.0, Color("3a3a40"))
			U.seg(pts, cols, Vector2(px, -wall_h - 20.0), Vector2(px + 40.0, -wall_h - 24.0), 1.0, Color("3a3a40"))
		# בית השער: אבן כהה, קשת גדולה פתוחה, דלתות ברזל פתוחות לצדדים
		var gx0 := gate_x - 150.0
		var gx1 := gate_x + 150.0
		U.vrect(pts, cols, Rect2(gx0, -wall_h - 60.0, gx1 - gx0, wall_h + 60.0), Color("6a6458"), Color("4a453c"))
		U.rect(pts, cols, Rect2(gx0 - 6.0, -wall_h - 64.0, gx1 - gx0 + 12.0, 8.0), SNOW)
		for q in 7:   # אבני הקשת
			var a := PI + float(q) / 6.0 * PI
			U.oval(pts, cols, Vector2(gate_x, -150.0) + Vector2(cos(a), sin(a)) * 104.0, 12.0, 9.0, Color("8a8274"), 8, a)
		# החושך שבתוך השער + מדרגות שיורדות למטה
		U.rect(pts, cols, Rect2(gate_x - 96.0, -150.0, 192.0, 150.0), Color("08080a"))
		U.oval(pts, cols, Vector2(gate_x, -150.0), 96.0, 96.0, Color("08080a"), 20)
		U.rect(pts, cols, Rect2(gate_x - 96.0, -150.0, 192.0, 152.0), Color("08080a"))
		for q in 6:
			var sy := -16.0 - float(q) * 14.0
			var sw := 160.0 - float(q) * 22.0
			U.rect(pts, cols, Rect2(gate_x - sw * 0.5, sy, sw, 3.0), Color(0.2, 0.3, 0.2, 0.5 - 0.07 * float(q)))
		# הזוהר הירוק מלמטה
		U.quad(pts, cols, Vector2(gate_x - 90.0, 0.0), Vector2(gate_x + 90.0, 0.0), Vector2(gate_x + 60.0, -110.0), Vector2(gate_x - 60.0, -110.0), Color(0.5, 1.0, 0.45, 0.25 + 0.15 * pulse), Color(0.5, 1.0, 0.45, 0.25 + 0.15 * pulse), Color(0.5, 1.0, 0.45, 0.0), Color(0.5, 1.0, 0.45, 0.0))
		# דלתות הברזל הפתוחות
		for s in 2:
			var dx := gate_x - 96.0 - 50.0 if s == 0 else gate_x + 96.0
			U.vrect(pts, cols, Rect2(dx, -200.0, 50.0, 200.0), Color("2a2a30"), Color("1a1a1e"))
			for b in 5:
				U.rect(pts, cols, Rect2(dx + 4.0 + float(b) * 10.0, -196.0, 2.0, 192.0), Color("4a4a52"))
		# השורשים: יוצאים מהשער, זוחלים על הקרקע ונעלמים לתוך האדמה. פעימות אור יורדות לאורכם (למטה - אל ה-ROOT)
		for q in 9:
			var a2 := Vector2(gate_x + (U.h(q, 1) - 0.5) * 160.0, -60.0 - U.h(q, 2) * 90.0)
			var b2 := Vector2(gate_x + (U.h(q, 3) - 0.5) * 520.0, 4.0)
			U.root(pts, cols, a2, b2, 9.0 + U.h(q, 4) * 6.0, _t, 16.0, q * 5, Color(0.72, 0.74, 0.56), Color(0.45, 0.6, 0.35))
			var u := fposmod(_t * 0.5 + U.h(q, 5), 1.0)
			U.oval(pts, cols, a2.lerp(b2, u), 5.0, 5.0, Color(0.7, 1.0, 0.55, 0.85 * (1.0 - u)), 8)
		for q in 4:   # שורשים מטפסים על החזית
			var a3 := Vector2(gate_x - 150.0 - float(q) * 120.0, 0.0)
			U.root(pts, cols, a3, a3 + Vector2(-30.0 + float(q) * 10.0, -wall_h + 20.0 + float(q) * 30.0), 7.0, _t, 12.0, q * 7 + 1, Color(0.7, 0.72, 0.55, 0.9), Color(0.5, 0.85, 0.45, 0.5))
			U.growth(pts, cols, a3 + Vector2(-20.0, -wall_h * 0.5), 1.1, q * 13, pulse)
		U.flush(self, pts, cols)
		Kit.soft_glow(self, Vector2(gate_x, -60.0), 200.0, Color(0.5, 1.0, 0.45, 0.14 + 0.1 * pulse), 0.6)
		var f := ThemeDB.fallback_font
		DrawBatch.string(self, f, Vector2(tx - 120.0, -wall_h + 22.0), "CARCEL DE USHUAIA", HORIZONTAL_ALIGNMENT_CENTER, 240.0, 18, Color("2a2620"))
		DrawBatch.string(self, f, Vector2(tx - 120.0, -wall_h + 36.0), "PRESIDIO  1902", HORIZONTAL_ALIGNMENT_CENTER, 240.0, 11, Color("3a342a"))
		U.hive_words(self, Vector2(gx0, -wall_h - 24.0), gx1 - gx0, "BAJEN", pulse, 30)
		U.hive_words(self, Vector2(gx0, -wall_h + 14.0), gx1 - gx0, "COME DOWN, ZERO", pulse, 15)


# ============================================================
#  מסך: שלג דק באלכסון שנסחף, משב (gust())
# ============================================================
class EndFX extends Node2D:
	const GUST_EVERY := Vector2(14.0, 22.0)
	var vp := Vector2(1280, 720)
	var gusts := 0                  # לבדיקות
	var _t := 0.0
	var _next := 9.0
	var _gust := -1.0

	func gust() -> void:
		_gust = 0.0
		gusts += 1
		Sfx.play("s61_wind", null, -3.0)

	func _process(delta: float) -> void:
		_t += delta
		_next -= delta
		if _next <= 0.0:
			_next = randf_range(GUST_EVERY.x, GUST_EVERY.y)
			gust()
		if _gust >= 0.0:
			_gust += delta
			if _gust > 3.0:
				_gust = -1.0
		if Engine.get_process_frames() % 2 == 0:
			queue_redraw()

	func _draw() -> void:
		DrawBatch.begin(self)
		_draw_b()
		DrawBatch.end(self)

	func _draw_b() -> void:
		var g := 0.0 if _gust < 0.0 else sin(clampf(_gust / 3.0, 0.0, 1.0) * PI)
		var q := clampf(Quality.ambient(), 0.3, 1.0)
		var pts := PackedVector2Array()
		var cols := PackedColorArray()
		for i in int((80.0 + 50.0 * g) * q):   # פתיתים: נופלים לאט, מתנדנדים, נסחפים באלכסון במשב
			var sp := 40.0 + U.h(i, 1) * 50.0
			var y := fposmod(U.h(i, 3) * vp.y + _t * sp * (1.0 + g), vp.y + 20.0) - 10.0
			var x := fposmod(U.h(i, 4) * vp.x * 1.3 - _t * (20.0 + 260.0 * g) + sin(_t * 1.2 + float(i)) * 14.0, vp.x + 40.0) - 20.0
			var s := 1.0 + U.h(i, 5) * 1.6
			U.dia(pts, cols, Vector2(x, y), s, Color(0.95, 0.96, 1.0, 0.35 + 0.35 * U.h(i, 6)))
		U.flush(self, pts, cols)
		Kit.soft_glow(self, Vector2(vp.x * 0.5, vp.y * 0.06), vp.x * 0.7, Color(0.6, 0.55, 0.75, 0.05 + 0.04 * g), 0.18)
