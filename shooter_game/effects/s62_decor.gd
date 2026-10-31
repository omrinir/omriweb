extends RefCounted
const DrawBatch := preload("res://effects/draw_batch.gd")   # כל הציור של זומבי ב-draw call אחד
# ============================================================
#  קישוטים לשלב 62 ("THE HIVE MIND") - אזור שביעי (פטגוניה), שלב 8. "THEY LEARNED TO THINK AS ONE".
#  ה-ROOT: מתחת לכלא הישן של אושואיה (ה-Presidio) גדלה מערה חיה. קירות של רקמת מוח ופטרייה, חוטי עצב שעוברים
#  בכל מקום ונושאים פולסים של אור אל הלב (ימינה, למטה), גולמים על הקירות עם גופות בפנים, ובריכות זיכרון זוהרות
#  שמשחזרות את הקרבות הישנים של הגיבור. הכוורת כותבת לו בפטרייה על הקירות.
#    hive_sky      - (רקע) חושך המערה: שחור-סגול, זוהר ירוק עמוק מלמטה (הלב), נבגים זוהרים שעולים לאט
#    far_cavern    - (רקע, 0.06) הכיפה הענקית: נטיפי בשר מהתקרה, גבעות בשר, גזעי עצב ענקיים עם פולסים, פטריות זוהרות רחוקות
#    mid_wall      - (רקע, 0.28) קיר רקמת המוח: קפלים (gyri), גולמים עם גופות, עצמות, שלפוחיות, חוטי עצב עם חרוזים זוהרים,
#                    וכתובות פטרייה של הכוורת (WRITING)
#    near_roots    - (רקע, 0.6) שורשים עבים מהתקרה, וילונות פטרייה, חבל עצב אופקי עם פולסים ימינה, פטריות זוהרות, עצמות
#    hive_overlay  - אובך ירוק מאחורי הדמויות + צל התקרה + ערפל רצפה
#    HiveGround    - (עולם) רצפת בשר ופטרייה: עורקי תפטיר זוהרים, שלוליות רפש ירוק, עצמות. בכניסה: אבני הכלא (stone)
#    Cellar        - (עולם) הכניסה: מרתף הכלא (PRESIDIO DE USHUAIA - NIVEL INFERIOR), מדרגות אבן שיורדות, סורגים,
#                    הפטרייה פורצת מהסדקים
#    Pillar        - (עולם) עמוד בשר מהרצפה עד התקרה, עטוף חוטי עצב
#    Ganglion      - (עולם, מלכודת) קשר עצב ענק על עמוד: כשהוא רואה אותך פולס יוצא מהתקרה ורץ אליו בחוט (WARN_T).
#                    הגיע = "THEY THINK AS ONE": כל הזומבים ב-RANGE יודעים איפה אתה ומסתערים יחד (מהר יותר, SYNC_T).
#                    יורים בקשר (GangBody, HP) לפני שהפולס מגיע = "SEVERED" (מת לתמיד)
#    Maw           - (עולם, מלכודת) סוגר בשר ברצפה: מי שעומד עליו (גם זומבים) - השפתיים רועדות (WARN_T) והלסתות נסגרות
#                    מלמטה: נזק + נתקע. זומבים = "DEVOURED" (הוא אוכל את שלו). יורים בעין שעל הגבעול (MawBody) = מת
#    MemoryPool    - (עולם) בריכת זיכרון זוהרת: צלליות של הגיבור נלחם בבוס ישן מהבהבות בתוכה (memory = איזה זיכרון).
#                    rise() = REMNANT יוצא ממנה (השלב מחליט). big = הבריכה של הסצנה (הכוורת מדברת ממנה)
#    Shelf         - (עולם) פטריית מדף ענקית על הקיר (הקומה עצמה = add_floor בשלב)
#    HiveChamber   - (עולם) חדר הקול האחד (סצנת הסיפור): קיר מוח ענק שכל חוטי העצב מתכנסים אליו, ופועם כשהכוורת מדברת
#    FloodArena    - (עולם) זירת THE FLOOD: אגן מוצף, קיר לב עם עורקים, ובסוף - הפיר שיורד אל הלב (הולם, U.heart)
#    Obstacle      - (מוצק + מחסה) "pod" גולם עם גופה / "bones" ערמת עצמות וגולגולות / "stalk" אשכול פטריות / "root" שורש מקושת
#    GooSplash     - (אפקט) טיפות רפש ירוק שעפות ונוחתות (SEEPER). זז ב-_process, עד MAX_LIVE בבת אחת
#    HiveFX        - (מסך) נבגים, הלמות לב בשולי המסך (U.heart), אדווה כשהכוורת מדברת (U.voice_ms), הבזק "THINK AS ONE"
#  מצב משותף: U.voice_ms / U.replay_ms / U.face_ms (הסצנה), U.heart (0..1), U.sync_ms (קשר עצב ירה), U.t.
#  לשנות: Ganglion.TRIG_R / WARN_T / RANGE / SYNC_T / HP, Maw.HALF_W / WARN_T / DMG / DMG_Z / HP, MemoryPool.W, GooSplash.MAX_LIVE.
# ============================================================

const Art := preload("res://art.gd")
const Sfx := preload("res://sfx.gd")
const Kit := preload("res://effects/backdrop_kit.gd")
const Particles := preload("res://particles.gd")

const FLESH := Color("3a1e26")
const FLESH_D := Color("1c0c12")
const FLESH_L := Color("74414a")
const GUM := Color("a8505c")
const MYC := Color("d8e4b0")
const ECHO := Color(0.75, 1.0, 0.55)        # אותו צבע כמו effects/spore_lesson.gd
const ECHO_D := Color("3c5a2c")
const ECHO_M := Color("6e9a46")
const NERVE := Color("d8c8a0")
const NERVE_D := Color("6a5a48")
const PULSE := Color(0.7, 0.95, 1.0)        # הפולס בחוטי העצב
const MEM := Color(0.62, 0.95, 1.0)         # אור הזיכרון (בריכות, REMNANT)
const TOX := Color(0.45, 1.0, 0.25)         # ירוק רעיל (SEEPER)
const TOX_D := Color(0.1, 0.42, 0.08)
const BONE := Color("e0d6bc")
const BONE_D := Color("9a8e74")
const STONE := Color("6a645a")
const STONE_D := Color("36322c")
const WRITING := ["WE ARE ONE", "EVERY LESSON|CAME HOME", "TEACHER", "COME DOWN|ZERO", "WE KEPT THEM ALL"]
const MEMORIES := ["THE FIRST", "THE SPITTER", "SUBJECT FOUR", "THE HOUND"]   # (REMNANT.memory) מה הבריכה משחזרת


# מצב משותף (השלב כותב, כל הקישוטים קוראים) + עזרים - מחלקה פנימית לא רואה פונקציות סטטיות של הקובץ
class U:
	static var voice_ms := -1        # (סצנה) הכוורת מדברת: הקיר והחוטים פועמים
	static var replay_ms := -1       # (סצנה) "replay": כל בריכות הזיכרון מבזיקות
	static var face_ms := -1         # (סצנה) "face": הפנים של הדובר נהיות הפנים שלך
	static var sync_ms := -1         # קשר עצב ירה (HiveFX - הבזק)
	static var heart := 0.0          # 0..1 - הלמות הלב (הזירה / הפיר)
	static var t := 0.0

	static func since(ms: int) -> float:   # שניות מאז (או -1)
		return -1.0 if ms < 0 else float(Time.get_ticks_msec() - ms) / 1000.0

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

	# קו עבה כמרובע (בלי draw call משלו)
	static func seg(pts: PackedVector2Array, cols: PackedColorArray, a: Vector2, b: Vector2, w: float, col: Color) -> void:
		var d := (b - a)
		if d.length_squared() < 0.0001:
			return
		var n := d.normalized().orthogonal() * w * 0.5
		quad(pts, cols, a - n, a + n, b + n, b - n, col, col, col, col)

	# קו עבה שמתחדד (a עבה -> b דק)
	static func taper(pts: PackedVector2Array, cols: PackedColorArray, a: Vector2, b: Vector2, wa: float, wb: float, ca: Color, cb: Color) -> void:
		var d := (b - a)
		if d.length_squared() < 0.0001:
			return
		var n := d.normalized().orthogonal() * 0.5
		quad(pts, cols, a - n * wa, a + n * wa, b + n * wb, b - n * wb, ca, ca, cb, cb)

	# אליפסה (מסובבת) כמניפת משולשים
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

	# אליפסה עם מרכז בהיר ושוליים שקופים (זוהר זול, בלי טקסטורה)
	static func halo(pts: PackedVector2Array, cols: PackedColorArray, c: Vector2, rx: float, ry: float, col: Color, n := 12) -> void:
		var edge := Color(col, 0.0)
		var prev := c + Vector2(rx, 0)
		for q in n:
			var a1 := float(q + 1) / float(n) * TAU
			var p := c + Vector2(cos(a1) * rx, sin(a1) * ry)
			pts.append_array([c, prev, p])
			cols.append_array([col, edge, edge])
			prev = p

	# חוט עצב: עקומה (a -> b, נמתחת למטה ב-sag), עם פולס אור שרץ לאורכה (k = 0..1 איפה הפולס, <0 = אין)
	static func nerve(pts: PackedVector2Array, cols: PackedColorArray, a: Vector2, b: Vector2, sag: float, w: float, k: float, col: Color, n := 10) -> void:
		var prev := a
		for q in range(1, n + 1):
			var u := float(q) / float(n)
			var p := a.lerp(b, u) + Vector2(0.0, sin(u * PI) * sag)
			seg(pts, cols, prev, p, w, col)
			if k >= 0.0 and absf(u - k) < 0.08:
				var g := 1.0 - absf(u - k) / 0.08
				oval(pts, cols, p, w * 1.6 + 2.0 * g, w * 1.6 + 2.0 * g, Color(PULSE, 0.85 * g), 6)
			prev = p

	# ענף מיצליום / וריד זוהר שמתפצל
	static func vein(pts: PackedVector2Array, cols: PackedColorArray, a: Vector2, b: Vector2, w: float, t: float, wx: float, seed_v: int) -> void:
		var n := 6
		var prev := a
		for q in range(1, n + 1):
			var k := float(q) / float(n)
			var p := a.lerp(b, k) + Vector2(sin(k * 7.0 + float(seed_v)) * 5.0, cos(k * 5.0 + float(seed_v) * 0.7) * 3.0)
			var pulse := 0.5 + 0.5 * sin(t * 3.0 - (wx + p.x) * 0.012)
			seg(pts, cols, prev, p, w * (1.0 - k * 0.5), ECHO_D.lerp(ECHO, pulse * 0.55))
			if q % 2 == 0:
				oval(pts, cols, p, 2.0 + pulse * 1.4, 1.8 + pulse * 1.2, Color(ECHO, 0.4 + 0.5 * pulse), 6)
			prev = p

	# צללית אנושית שטוחה (בריכות זיכרון, גולמים): x = מרכז, y = כפות הרגליים, h = גובה, pose = 0 עומד / 1 יורה / 2 נופל
	static func figure(pts: PackedVector2Array, cols: PackedColorArray, x: float, y: float, h: float, col: Color, pose: int, face: float) -> void:
		var s := h / 56.0
		var hip := Vector2(x, y - 26.0 * s)
		var sh := Vector2(x + 2.0 * face * s, y - 44.0 * s)
		if pose == 2:
			sh = Vector2(x - 12.0 * face * s, y - 36.0 * s)
		seg(pts, cols, Vector2(x - 5.0 * s, y), hip, 4.0 * s, col)
		seg(pts, cols, Vector2(x + 6.0 * s, y), hip, 4.0 * s, col)
		seg(pts, cols, hip, sh, 8.0 * s, col)
		oval(pts, cols, sh + Vector2(1.5 * face * s, -8.0 * s), 4.6 * s, 5.0 * s, col, 8)
		if pose == 1:   # יורה: יד ישרה קדימה עם רובה
			seg(pts, cols, sh, sh + Vector2(16.0 * face * s, 1.0 * s), 3.0 * s, col)
			seg(pts, cols, sh + Vector2(10.0 * face * s, 0.0), sh + Vector2(26.0 * face * s, -1.0 * s), 2.4 * s, col)
		else:
			seg(pts, cols, sh, sh + Vector2(9.0 * face * s, 14.0 * s), 3.0 * s, col)


static func _h(i: int, s: int) -> float:
	return U.h(i, s)


# ============================================================
#  רקע
# ============================================================

# ---- חושך המערה: שחור-סגול, זוהר הלב מלמטה, נבגים שעולים ----
static func hive_sky(ci: CanvasItem, v: Vector2, t: float) -> void:
	Kit.gradient_sky(ci, v, [Color("030205"), Color("09050c"), Color("140a16"), Color("1c1020"), Color("122418")], 0.92)
	Kit.soft_glow(ci, Vector2(v.x * 0.7, v.y * 0.95), 520.0, Color(0.35, 0.9, 0.3, 0.1 + 0.05 * U.heart), 0.45)
	Kit.soft_glow(ci, Vector2(v.x * 0.2, v.y * 0.3), 380.0, Color(0.5, 0.2, 0.6, 0.08), 0.6)
	var pts := PackedVector2Array()
	var cols := PackedColorArray()
	for i in 40:   # נבגים זוהרים שעולים לאט
		var x := fposmod(_h(i, 1) * v.x * 1.3 + sin(t * 0.4 + float(i)) * 24.0, v.x)
		var y := fposmod(_h(i, 2) * v.y - t * (5.0 + _h(i, 3) * 9.0), v.y)
		var c := ECHO if i % 3 != 0 else MEM
		U.dia(pts, cols, Vector2(x, y), 0.8 + _h(i, 4) * 1.3, Color(c, 0.2 + 0.35 * _h(i, 5)))
	U.flush(ci, pts, cols)


# ---- הכיפה הענקית: נטיפי בשר, גזעי עצב עם פולסים, פטריות זוהרות רחוקות ----
static func far_cavern(ci: CanvasItem, sc: float, v: Vector2, y: float, t: float) -> void:
	var period := 1400.0
	var start := int(floor(sc / period)) - 1
	var pts := PackedVector2Array()
	var cols := PackedColorArray()
	for k in range(start, start + int(ceil(v.x / period)) + 2):
		var bx := float(k) * period - sc
		if bx > v.x + 40.0 or bx + period < -40.0:
			continue
		# התקרה: מסה כהה עם נטיפי בשר
		U.vrect(pts, cols, Rect2(bx, 0.0, period, 70.0), Color("050206"), Color("0e0610"))
		for q in 14:
			var sx := bx + float(q) * 100.0 + _h(k * 14 + q, 1) * 40.0
			var sl := 60.0 + _h(k * 14 + q, 2) * 170.0
			var sw := 16.0 + _h(k * 14 + q, 3) * 26.0
			U.quad(pts, cols, Vector2(sx - sw, 60.0), Vector2(sx + sw, 60.0), Vector2(sx + 3.0, 60.0 + sl), Vector2(sx - 3.0, 60.0 + sl),
				Color("0e0610"), Color("0e0610"), Color("2a1420"), Color("2a1420"))
			if q % 3 == 0:   # טיפה זוהרת בקצה
				var drip := fposmod(t * 0.3 + _h(k, q), 1.0)
				U.oval(pts, cols, Vector2(sx, 62.0 + sl + drip * 40.0), 2.2, 3.0, Color(ECHO, 0.5 * (1.0 - drip)), 6)
		# גבעות בשר על הרצפה הרחוקה
		var prev := Vector2(bx, y - 40.0)
		for q in range(1, 15):
			var px := bx + float(q) * 100.0
			var py := y - 40.0 - (40.0 + 60.0 * _h(k * 15 + q, 4)) * absf(sin(float(q) * 0.9 + float(k)))
			U.quad(pts, cols, prev, Vector2(px, py), Vector2(px, y + 60.0), Vector2(prev.x, y + 60.0), Color("1e0e18"), Color("1e0e18"), Color("0c060a"), Color("0c060a"))
			prev = Vector2(px, py)
		# גזעי עצב ענקיים: מהתקרה אל הרצפה, הפולס רץ למטה (אל הלב)
		for q in 2:
			var ax := bx + 200.0 + float(q) * 700.0 + _h(k * 2 + q, 5) * 160.0
			var a := Vector2(ax, 60.0)
			var b := Vector2(ax + 260.0 + _h(k + q, 6) * 200.0, y - 30.0)
			var kk := fposmod(t * 0.22 + _h(k * 2 + q, 7), 1.0)
			U.nerve(pts, cols, a, b, 90.0, 9.0, -1.0, Color("2a2018"), 12)
			U.nerve(pts, cols, a + Vector2(0, -2), b + Vector2(0, -2), 90.0, 3.0, kk, Color(0.45, 0.4, 0.3, 0.6), 12)
		# פטריות זוהרות רחוקות
		for q in 7:
			var fx := bx + _h(k * 7 + q, 8) * period
			var fy := y - 50.0 - _h(k * 7 + q, 9) * 120.0
			var pul := 0.5 + 0.5 * sin(t * 1.4 + float(q + k))
			U.halo(pts, cols, Vector2(fx, fy), 30.0, 18.0, Color(ECHO, 0.12 + 0.08 * pul), 10)
			U.oval(pts, cols, Vector2(fx, fy), 6.0, 3.0, Color(ECHO, 0.35 + 0.2 * pul), 8)
	U.flush(ci, pts, cols)


# ---- קיר רקמת המוח: קפלים, גולמים, עצמות, שלפוחיות, חוטי עצב, כתובות ----
static func mid_wall(ci: CanvasItem, sc: float, v: Vector2, y: float, t: float) -> void:
	var period := 900.0
	var start := int(floor(sc / period)) - 1
	var talk := clampf(1.0 - U.since(U.voice_ms) * 0.5, 0.0, 1.0) if U.voice_ms >= 0 else 0.0
	for k in range(start, start + int(ceil(v.x / period)) + 2):
		var bx := float(k) * period - sc
		if bx > v.x + 20.0 or bx + period < -20.0:
			continue
		var pts := PackedVector2Array()
		var cols := PackedColorArray()
		var top := 150.0 + _h(k, 10) * 40.0
		# הקיר: בשר כהה, בהיר יותר באמצע
		U.vrect(pts, cols, Rect2(bx, top, period, y - top + 30.0), Color("24121a"), Color("341a22"))
		U.quad(pts, cols, Vector2(bx, top - 60.0), Vector2(bx + period, top - 70.0), Vector2(bx + period, top), Vector2(bx, top), Color(0.08, 0.03, 0.06, 0.0), Color(0.08, 0.03, 0.06, 0.0), Color("24121a"), Color("24121a"))
		# קפלי מוח (gyri): פסים גליים בהירים עם חריצים כהים
		for r in 7:
			var ry := top + 20.0 + float(r) * (y - top - 30.0) / 7.0
			var prev := Vector2(bx, ry)
			for q in range(1, 19):
				var px := bx + float(q) * 50.0
				var py := ry + sin(float(q) * 1.3 + float(r * 2 + k)) * 10.0 + cos(float(q) * 0.6 + float(r)) * 5.0
				var p := Vector2(px, py)
				U.seg(pts, cols, prev, p, 13.0, Color("3e2028").lerp(GUM, 0.12 + 0.1 * talk))
				U.seg(pts, cols, prev + Vector2(0, 7.0), p + Vector2(0, 7.0), 2.0, Color(0.06, 0.02, 0.04, 0.7))
				U.seg(pts, cols, prev + Vector2(0, -4.0), p + Vector2(0, -4.0), 1.4, Color(0.7, 0.45, 0.5, 0.18))
				prev = p
		# גולמים עם גופות בפנים (הכוורת שומרת אותם)
		for q in 2:
			var cx := bx + 180.0 + float(q) * 420.0 + _h(k * 2 + q, 11) * 100.0
			var cy := top + 90.0 + _h(k * 2 + q, 12) * 80.0
			var open := (k + q) % 3 == 1
			U.oval(pts, cols, Vector2(cx, cy), 30.0, 52.0, Color("4a3a2c"), 14)
			U.oval(pts, cols, Vector2(cx, cy), 25.0, 46.0, Color("1a1410") if open else Color("6a5a40"), 14)
			if open:   # נפתח: הגוף יצא, נשאר רפש
				U.tri(pts, cols, Vector2(cx - 24.0, cy - 10.0), Vector2(cx - 40.0, cy - 30.0), Vector2(cx - 16.0, cy - 34.0), Color("4a3a2c"))
				U.oval(pts, cols, Vector2(cx, cy + 40.0), 20.0, 4.0, Color(TOX, 0.35), 10)
			else:
				U.figure(pts, cols, cx, cy + 38.0, 70.0, Color(0.15, 0.1, 0.08, 0.55), 0, 1.0)
				for s in 4:   # חוטים שעוטפים
					var yy := cy - 36.0 + float(s) * 22.0
					U.seg(pts, cols, Vector2(cx - 26.0, yy), Vector2(cx + 26.0, yy + 8.0), 1.4, Color(MYC, 0.35))
			U.vein(pts, cols, Vector2(cx, cy - 50.0), Vector2(cx + 30.0, top - 10.0), 3.0, t, sc, k * 2 + q)
		# עצמות וגולגולות שקועות בקיר
		for q in 5:
			var sx := bx + _h(k * 5 + q, 13) * period
			var sy := top + 40.0 + _h(k * 5 + q, 14) * (y - top - 80.0)
			if q % 2 == 0:
				U.oval(pts, cols, Vector2(sx, sy), 9.0, 8.0, Color(BONE_D, 0.8), 10)
				U.oval(pts, cols, Vector2(sx - 3.0, sy - 1.0), 2.4, 2.4, Color(0.05, 0.03, 0.03, 0.9), 6)
				U.oval(pts, cols, Vector2(sx + 3.0, sy - 1.0), 2.4, 2.4, Color(0.05, 0.03, 0.03, 0.9), 6)
			else:
				U.seg(pts, cols, Vector2(sx - 14.0, sy), Vector2(sx + 14.0, sy - 6.0), 4.0, Color(BONE_D, 0.75))
		# שלפוחיות זוהרות
		for q in 9:
			var px2 := bx + _h(k * 9 + q, 15) * period
			var py2 := top + 30.0 + _h(k * 9 + q, 16) * (y - top - 50.0)
			var pul := 0.5 + 0.5 * sin(t * 2.6 + float(q) * 1.7 + float(k))
			U.oval(pts, cols, Vector2(px2, py2), 3.0 + pul * 1.5, 3.0 + pul * 1.5, Color(ECHO, 0.35 + 0.4 * pul + 0.2 * talk), 6)
		# חוטי עצב תלויים מהתקרה עם חרוזים, הפולס זז ימינה
		for q in 4:
			var hx := bx + 60.0 + float(q) * 220.0 + _h(k * 4 + q, 17) * 60.0
			var hl := 80.0 + _h(k * 4 + q, 18) * 140.0
			var kk := fposmod(t * 0.7 - (sc + hx) * 0.001, 1.0)
			U.nerve(pts, cols, Vector2(hx, top - 60.0), Vector2(hx + 40.0, top - 60.0 + hl), 10.0, 1.6, kk, Color(NERVE_D, 0.9), 8)
		U.flush(ci, pts, cols)
		# כתובת פטרייה של הכוורת (כל שני קטעים)
		if posmod(k, 2) == 1:
			var txt: String = WRITING[posmod(k / 2, WRITING.size())]
			var parts := txt.split("|")
			var wx := bx + 470.0
			var wy := top + 120.0
			var a := 0.55 + 0.25 * sin(t * 1.3 + float(k)) + 0.2 * talk
			for i in parts.size():
				DrawBatch.string(ci, ThemeDB.fallback_font, Vector2(wx + 2.0, wy + float(i) * 34.0 + 2.0), parts[i], HORIZONTAL_ALIGNMENT_LEFT, -1, 28, Color(0.02, 0.05, 0.02, 0.7))
				DrawBatch.string(ci, ThemeDB.fallback_font, Vector2(wx, wy + float(i) * 34.0), parts[i], HORIZONTAL_ALIGNMENT_LEFT, -1, 28, Color(ECHO, a))


# ---- שורשים מהתקרה, וילונות פטרייה, חבל עצב אופקי, פטריות זוהרות, עצמות ----
static func near_roots(ci: CanvasItem, sc: float, v: Vector2, y: float, t: float) -> void:
	var period := 760.0
	var start := int(floor(sc / period)) - 1
	var pts := PackedVector2Array()
	var cols := PackedColorArray()
	for k in range(start, start + int(ceil(v.x / period)) + 2):
		var bx := float(k) * period - sc
		if bx > v.x + 40.0 or bx + period < -40.0:
			continue
		# תקרה: מסת שורשים כהה
		U.vrect(pts, cols, Rect2(bx, 0.0, period, 50.0), Color("070306"), Color("140a10"))
		for q in 9:
			var ex := bx + float(q) * 85.0
			U.quad(pts, cols, Vector2(ex, 48.0), Vector2(ex + 85.0, 48.0), Vector2(ex + 70.0, 62.0 + _h(k * 9 + q, 20) * 18.0), Vector2(ex + 10.0, 60.0 + _h(k * 9 + q, 21) * 16.0), Color("140a10"), Color("140a10"), Color("1e1016"), Color("1e1016"))
		# שורשים עבים תלויים
		for q in 4:
			var rx := bx + 50.0 + float(q) * 190.0 + _h(k * 4 + q, 22) * 50.0
			var rl := 120.0 + _h(k * 4 + q, 23) * 200.0
			var sw := sin(t * 0.6 + float(q + k)) * 5.0
			var p0 := Vector2(rx, 50.0)
			var p1 := Vector2(rx + 10.0 + sw * 0.5, 50.0 + rl * 0.5)
			var p2 := Vector2(rx - 6.0 + sw, 50.0 + rl)
			U.taper(pts, cols, p0, p1, 18.0, 11.0, Color("1e1216"), Color("2a1a1e"))
			U.taper(pts, cols, p1, p2, 11.0, 2.0, Color("2a1a1e"), Color("3a2428"))
			U.seg(pts, cols, p0 + Vector2(-4, 0), p1 + Vector2(-3, 0), 1.6, Color(0.6, 0.4, 0.4, 0.2))
		# וילונות פטרייה (חוטים דקים)
		for q in 16:
			var fx := bx + float(q) * 47.0 + _h(k * 16 + q, 24) * 20.0
			var fl := 30.0 + _h(k * 16 + q, 25) * 80.0
			var sw2 := sin(t * 1.2 + float(q) * 0.7 + float(k)) * 4.0
			U.seg(pts, cols, Vector2(fx, 55.0), Vector2(fx + sw2, 55.0 + fl), 1.2, Color(MYC, 0.28))
			if q % 3 == 0:
				U.oval(pts, cols, Vector2(fx + sw2, 55.0 + fl), 1.8, 1.8, Color(ECHO, 0.6), 6)
		# חבל עצב אופקי לאורך הקיר (הפולסים רצים ימינה - אל הלב)
		var cy := 300.0
		var a := Vector2(bx, cy + sin(float(k)) * 10.0)
		var b := Vector2(bx + period, cy + sin(float(k + 1)) * 10.0)
		U.nerve(pts, cols, a, b, 26.0, 7.0, -1.0, Color("3a3026"), 10)
		for q in 3:
			var kk := fposmod(t * 0.45 - (sc + bx) * 0.0004 + float(q) * 0.33, 1.0)
			U.nerve(pts, cols, a + Vector2(0, -1), b + Vector2(0, -1), 26.0, 2.0, kk, Color(NERVE, 0.25), 10)
		for q in 3:   # עצבים שיורדים מהחבל אל הרצפה
			var dx := bx + 120.0 + float(q) * 250.0
			U.nerve(pts, cols, Vector2(dx, cy + 18.0), Vector2(dx + 60.0, y - 10.0), 30.0, 2.4, fposmod(t * 0.5 + float(q + k) * 0.37, 1.0), Color("4a3e30"), 8)
		# פטריות זוהרות ליד הרצפה
		for q in 5:
			var mx := bx + 40.0 + float(q) * 150.0 + _h(k * 5 + q, 26) * 60.0
			var mh := 20.0 + _h(k * 5 + q, 27) * 40.0
			var pul := 0.5 + 0.5 * sin(t * 1.8 + float(q * 3 + k))
			U.seg(pts, cols, Vector2(mx, y + 4.0), Vector2(mx + 3.0, y + 4.0 - mh), 4.0, Color("6a6a50"))
			U.oval(pts, cols, Vector2(mx + 3.0, y + 4.0 - mh), 14.0, 6.0, Color("2a4a24"), 12)
			U.oval(pts, cols, Vector2(mx + 3.0, y + 6.0 - mh), 12.0, 3.0, Color(ECHO, 0.3 + 0.4 * pul), 10)
			U.halo(pts, cols, Vector2(mx + 3.0, y + 4.0 - mh), 34.0, 22.0, Color(ECHO, 0.1 + 0.08 * pul), 10)
		# עצמות ליד הרצפה
		for q in 4:
			var ox := bx + _h(k * 4 + q, 28) * period
			U.seg(pts, cols, Vector2(ox - 12.0, y + 2.0), Vector2(ox + 12.0, y - 4.0), 3.5, Color(BONE_D, 0.8))
	U.flush(ci, pts, cols)
	DrawBatch.rect(ci, Rect2(0, y + 6.0, v.x, v.y - y), Color("140a10"))


# אובך ירוק מאחורי הדמויות + צל התקרה + ערפל רצפה
static func hive_overlay(ci: CanvasItem, v: Vector2, t: float) -> void:
	Kit.haze_band(ci, v, 420.0, 616.0, Color(0.3, 0.55, 0.32, 0.18))
	DrawBatch.polygon(ci, PackedVector2Array([Vector2(0, 0), Vector2(v.x, 0), Vector2(v.x, 130.0), Vector2(0, 130.0)]),
		PackedColorArray([Color(0, 0, 0, 0.55), Color(0, 0, 0, 0.55), Color(0, 0, 0, 0.0), Color(0, 0, 0, 0.0)]))
	for i in 3:   # ערפל ירוק שזוחל על הרצפה
		var mx := fposmod(float(i) * 420.0 + t * (10.0 + float(i) * 5.0), v.x + 600.0) - 300.0
		Kit.soft_glow(ci, Vector2(mx, 596.0 + float(i % 2) * 14.0), 240.0, Color(0.5, 0.9, 0.5, 0.06), 0.22)


# ============================================================
#  עולם
# ============================================================

# ---- רצפת בשר ופטרייה: עורקי תפטיר, שלוליות רפש, עצמות. stone = אבני הכלא (בכניסה) ----
class HiveGround extends Node2D:
	var w := 1024.0
	var depth := 90.0
	var seed_v := 0
	var stone := 0.0
	var wx := 0.0
	var _t := 0.0

	func _ready() -> void:
		z_index = 1

	func _process(delta: float) -> void:
		_t += delta
		if Engine.get_process_frames() % 6 == 0 and Art.on_screen(self, global_position + Vector2(w * 0.5, 0), w * 0.6):
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
		U.rect(pts, cols, Rect2(0, 0, w, depth), Color("12080c"))
		U.vrect(pts, cols, Rect2(0, 0, w, 18.0), Color("4a2a30").lerp(STONE, stone), Color("2a1418").lerp(STONE_D, stone))
		U.rect(pts, cols, Rect2(0, 0, w, 1.6), Color(0.85, 0.6, 0.6, 0.35).lerp(Color(0.8, 0.78, 0.7, 0.5), stone))
		if stone > 0.0:   # אבני הכלא
			var x := 0.0
			while x < w * stone + 40.0 and x < w:
				U.rect(pts, cols, Rect2(x, 1.0, 1.8, 17.0), Color(0.1, 0.09, 0.08, 0.8))
				x += r.randf_range(50.0, 80.0)
		# גבשושיות בשר על פני השטח
		var bx := 0.0
		while bx < w:
			var bw := r.randf_range(30.0, 70.0)
			if r.randf() > stone:
				U.oval(pts, cols, Vector2(bx + bw * 0.5, 1.0), bw * 0.5, r.randf_range(2.0, 5.0), Color("5a3038").lerp(Color("3a2026"), r.randf()), 10)
			bx += bw
		# עורקי תפטיר זוהרים
		var thick := clampf(1.0 - stone, 0.0, 1.0)
		for i in int(w / 60.0 * thick):
			var p := Vector2(r.randf_range(0.0, w), r.randf_range(0.0, 4.0))
			var ln := r.randf_range(24.0, 70.0)
			var pul := 0.5 + 0.5 * sin(_t * 2.6 + p.x * 0.02 - (wx + p.x) * 0.004)
			U.seg(pts, cols, p, p + Vector2(ln, r.randf_range(-3.0, 3.0)), r.randf_range(1.2, 2.6), ECHO_D.lerp(ECHO_M, pul))
			if i % 3 == 0:
				U.oval(pts, cols, p + Vector2(ln, 0), 2.2 + pul, 1.6 + pul * 0.6, Color(ECHO, 0.5 + 0.4 * pul), 6)
		# שלוליות רפש ירוק (מבריקות)
		for i in int(w / 280.0):
			var p := Vector2(r.randf_range(20.0, w - 20.0), r.randf_range(2.0, 5.0))
			var pw := r.randf_range(18.0, 44.0)
			U.oval(pts, cols, p, pw, r.randf_range(2.0, 3.4), Color(TOX_D, 0.75), 12)
			U.oval(pts, cols, p + Vector2(-pw * 0.2, -0.6), pw * 0.4, 0.8, Color(0.85, 1.0, 0.7, 0.35 + 0.2 * sin(_t * 2.0 + p.x)), 8)
		# עצמות וגולגולות קטנות
		for i in int(w / 220.0):
			var p := Vector2(r.randf_range(0.0, w), r.randf_range(1.0, 4.0))
			if i % 3 == 0:
				U.oval(pts, cols, p + Vector2(0, -3.0), 5.0, 4.4, BONE_D, 10)
				U.oval(pts, cols, p + Vector2(1.6, -3.4), 1.3, 1.3, Color(0.06, 0.04, 0.04), 6)
			else:
				U.seg(pts, cols, p, p + Vector2(r.randf_range(10.0, 22.0), r.randf_range(-3.0, 1.0)), 2.6, BONE_D)
		# פטריות קטנות
		for i in int(w / 160.0 * thick):
			var p := Vector2(r.randf_range(0.0, w), 1.0)
			var mh := r.randf_range(4.0, 10.0)
			U.seg(pts, cols, p, p + Vector2(0, -mh), 1.6, Color("a8a080"))
			U.oval(pts, cols, p + Vector2(0, -mh), r.randf_range(3.0, 6.0), 2.0, Color("6a8a4a") if i % 2 == 0 else Color("b8604a"), 8)
		U.flush(self, pts, cols)


# ---- הכניסה: מרתף הכלא של אושואיה - מדרגות אבן יורדות, סורגים, שלט, הפטרייה פורצת מהסדקים ----
class Cellar extends Node2D:
	var _t := 0.0

	func _ready() -> void:
		z_index = -3

	func _process(delta: float) -> void:
		_t += delta
		if Engine.get_process_frames() % 4 == 0 and Art.on_screen(self, global_position + Vector2(200, -200), 500.0):
			queue_redraw()

	func _draw() -> void:
		DrawBatch.begin(self)
		_draw_b()
		DrawBatch.end(self)

	func _draw_b() -> void:
		var pts := PackedVector2Array()
		var cols := PackedColorArray()
		# קיר אבן ענק (משמאל למסך) עם אבנים
		U.vrect(pts, cols, Rect2(-300.0, -720.0, 760.0, 720.0), Color("2e2a26"), Color("4a443c"))
		for row in 18:
			var yy := -720.0 + float(row) * 40.0
			var off := 0.0 if row % 2 == 0 else 34.0
			U.rect(pts, cols, Rect2(-300.0, yy, 760.0, 2.0), Color(0.08, 0.07, 0.06, 0.8))
			for q in 12:
				U.rect(pts, cols, Rect2(-300.0 + off + float(q) * 68.0, yy, 2.0, 40.0), Color(0.08, 0.07, 0.06, 0.7))
		# מדרגות שיורדות מלמעלה-שמאל אל הרצפה
		for q in 9:
			var sx := -260.0 + float(q) * 40.0
			var sy := -360.0 + float(q) * 40.0
			U.vrect(pts, cols, Rect2(sx, sy, 60.0, 40.0), Color("6a645a"), Color("3a3630"))
			U.rect(pts, cols, Rect2(sx, sy, 60.0, 3.0), Color(0.85, 0.82, 0.74, 0.5))
		U.quad(pts, cols, Vector2(-260.0, -320.0), Vector2(100.0, 40.0), Vector2(100.0, 0.0), Vector2(-260.0, 0.0), Color("1e1a16"), Color("1e1a16"), Color("1e1a16"), Color("1e1a16"))
		# פתח קשת בקיר (יציאה אל המערה) - חשוך, עם זוהר ירוק מבפנים
		var ax := 300.0
		U.vrect(pts, cols, Rect2(ax - 70.0, -230.0, 140.0, 230.0), Color("0a0608"), Color("10200c"))
		for q in 12:
			var a := PI + PI * float(q) / 11.0
			U.dia(pts, cols, Vector2(ax, -230.0) + Vector2(cos(a) * 76.0, sin(a) * 50.0), 9.0, Color("5a544a"))
		# חלון סורגים
		U.rect(pts, cols, Rect2(60.0, -470.0, 110.0, 80.0), Color("0c0a08"))
		for q in 6:
			U.seg(pts, cols, Vector2(70.0 + float(q) * 18.0, -470.0), Vector2(70.0 + float(q) * 18.0, -390.0), 4.0, Color("2a2622"))
		U.seg(pts, cols, Vector2(60.0, -430.0), Vector2(170.0, -430.0), 4.0, Color("2a2622"))
		# שרשראות תלויות
		for q in 2:
			var cx := -120.0 + float(q) * 340.0
			for s in 10:
				U.oval(pts, cols, Vector2(cx + sin(_t * 0.8 + float(q)) * float(s) * 0.4, -700.0 + float(s) * 14.0), 3.0, 6.0, Color("3a342e"), 8)
		# הפטרייה פורצת מהסדקים - עבה יותר ימינה (המערה)
		for q in 9:
			var vx := -100.0 + float(q) * 60.0
			U.vein(pts, cols, Vector2(vx + 120.0, -10.0), Vector2(vx + 60.0 + U.h(q, 30) * 80.0, -200.0 - U.h(q, 31) * 300.0), 2.0 + float(q) * 0.5, _t, vx, q)
		for q in 7:   # גידולים על האבן
			var gp := Vector2(200.0 + U.h(q, 32) * 260.0, -40.0 - U.h(q, 33) * 360.0)
			U.oval(pts, cols, gp, 10.0 + U.h(q, 34) * 14.0, 7.0 + U.h(q, 35) * 8.0, Color("3a2026"), 10)
			U.oval(pts, cols, gp, 3.0, 3.0, Color(ECHO, 0.5 + 0.3 * sin(_t * 2.0 + float(q))), 6)
		U.flush(self, pts, cols)
		Kit.soft_glow(self, Vector2(ax, -110.0), 110.0, Color(ECHO, 0.14 + 0.04 * sin(_t * 1.6)), 1.2)
		# שלט הכלא
		DrawBatch.rect(self, Rect2(-210.0, -560.0, 300.0, 52.0), Color("1a1814"))
		DrawBatch.rect(self, Rect2(-210.0, -560.0, 300.0, 52.0), Color("8a8270"), false, 2.0)
		DrawBatch.string(self, ThemeDB.fallback_font, Vector2(-198.0, -538.0), "PRESIDIO DE USHUAIA", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("d8d0b8"))
		DrawBatch.string(self, ThemeDB.fallback_font, Vector2(-198.0, -518.0), "NIVEL INFERIOR - NO PASAR", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(1.0, 0.5, 0.4, 0.9))


# ---- עמוד בשר מהרצפה עד התקרה, עטוף חוטי עצב ----
class Pillar extends Node2D:
	var seed_v := 0
	var w := 46.0
	var _t := 0.0

	func _ready() -> void:
		z_index = -2

	func _process(delta: float) -> void:
		_t += delta
		if Engine.get_process_frames() % 5 == 0 and Art.on_screen(self, global_position + Vector2(0, -300), 360.0):
			queue_redraw()

	func _draw() -> void:
		DrawBatch.begin(self)
		_draw_b()
		DrawBatch.end(self)

	func _draw_b() -> void:
		var pts := PackedVector2Array()
		var cols := PackedColorArray()
		Hive.column(pts, cols, w, 720.0, _t, seed_v)
		U.flush(self, pts, cols)


# ציור משותף (עמודים, קשרי עצב) - מחלקה נפרדת כי מחלקות פנימיות לא רואות פונקציות סטטיות של הקובץ
class Hive:
	static func column(pts: PackedVector2Array, cols: PackedColorArray, w: float, h: float, t: float, seed_v: int) -> void:
		var prev_l := Vector2(-w * 0.75, 0.0)
		var prev_r := Vector2(w * 0.75, 0.0)
		for q in range(1, 13):
			var y := -h * float(q) / 12.0
			var bulge := 1.0 - 0.35 * sin(float(q) / 12.0 * PI) + 0.1 * sin(float(q) * 1.7 + float(seed_v))
			var l := Vector2(-w * 0.5 * bulge + sin(float(q) + float(seed_v)) * 4.0, y)
			var r := Vector2(w * 0.5 * bulge + sin(float(q) * 1.3 + float(seed_v)) * 4.0, y)
			U.quad(pts, cols, prev_l, prev_r, r, l, Color("2e1820"), Color("4a2830"), Color("4a2830"), Color("2e1820"))
			prev_l = l
			prev_r = r
		# חוטי עצב שמלפפים את העמוד (הפולס עולה למעלה)
		for s in 3:
			var prev := Vector2(-w * 0.45, -20.0 - float(s) * 60.0)
			for q in range(1, 16):
				var u := float(q) / 15.0
				var p := Vector2(sin(u * 9.0 + float(s) * 2.1) * w * 0.48, -20.0 - float(s) * 60.0 - u * (h - 200.0))
				var k := fposmod(t * 0.4 + float(s) * 0.3 + float(seed_v % 7) * 0.1, 1.0)
				var g := clampf(1.0 - absf(u - k) / 0.1, 0.0, 1.0)
				U.seg(pts, cols, prev, p, 2.4, NERVE_D.lerp(PULSE, g * 0.8))
				prev = p
		U.oval(pts, cols, Vector2(0, -4.0), w * 0.9, 6.0, Color("2a1418"), 12)


# ============================================================
#  קשר עצב (מלכודת): רואה אותך -> פולס רץ אליו מהתקרה -> "THEY THINK AS ONE" (כולם מסתערים). יורים בו לפני
# ============================================================
class Ganglion extends Node2D:
	const KNOT_Y := 150.0           # גובה הקשר על העמוד
	const KNOT_R := 18.0
	const TRIG_R := 540.0
	const WARN_T := 2.1             # כמה זמן הפולס רץ בחוט
	const RANGE := 1000.0
	const SYNC_T := 5.0             # כמה זמן הם מסתערים יחד
	const CD := 11.0
	const HP := 34
	const THREAD := Vector2(-420.0, -560.0)   # מאיפה בא החוט (יחסית לרצפה)
	enum {IDLE, FIRE, DEAD}
	var state := IDLE
	var hp := HP
	var fired := 0                  # לבדיקות
	var severed := false
	var synced := 0
	var seed_v := 0
	var _t := 0.0
	var _st := 0.0
	var _cd := 0.0
	var _flash := 0.0
	var _body: StaticBody2D = null
	var _said := false

	func _ready() -> void:
		z_index = -1
		add_to_group("s62_ganglia")
		add_to_group("blastable")
		_body = GangBody.new()
		_body.trap = self
		_body.collision_layer = 4
		_body.collision_mask = 0
		_body.add_to_group("no_outline")
		var cs := CollisionShape2D.new()
		var rs := CircleShape2D.new()
		rs.radius = KNOT_R + 4.0
		cs.shape = rs
		_body.add_child(cs)
		_body.position = Vector2(0, -KNOT_Y)
		add_child(_body)

	func knot() -> Vector2:
		return global_position + Vector2(0, -KNOT_Y)

	func blast_rect() -> Rect2:
		return Rect2(knot() - Vector2(KNOT_R, KNOT_R), Vector2(KNOT_R, KNOT_R) * 2.0)

	func hit_by_blast(_c: Vector2, _r: float) -> void:
		hurt(HP, knot(), Vector2.UP)

	func hurt(n: int, at: Vector2, dir: Vector2) -> void:
		if state == DEAD:
			return
		hp -= n
		_flash = 0.12
		if Art.on_screen(self, at):
			Particles.burst(get_parent(), at, "hit", -dir, 5)
			Sfx.play("s62_squish", at, -4.0, 0.15, 3)
		if hp <= 0:
			state = DEAD
			severed = state == DEAD
			if _body != null:
				_body.queue_free()
				_body = null
			Sfx.play("s62_sever", at, 2.0, 0.1, 2)
			Particles.burst(get_parent(), knot(), "hit", Vector2.UP, int(18.0 * Quality.gore()) + 2)
			Particles.burst(get_parent(), knot(), "spark", Vector2.UP, 10)
			var t = preload("res://zombie.gd").HitText.new()
			t.text = "SEVERED"
			t.color = PULSE
			t.size = 18
			get_parent().add_child(t)
			t.global_position = knot() + Vector2(0, -40)
			queue_redraw()

	func _physics_process(delta: float) -> void:
		_t += delta
		_cd -= delta
		_flash -= delta
		if state == DEAD:
			return
		var pl := get_tree().get_first_node_in_group("player") as Node2D
		match state:
			IDLE:
				if pl != null and not pl.dead and _cd <= 0.0 and absf(pl.global_position.x - global_position.x) < TRIG_R and absf(pl.global_position.y - global_position.y) < 300.0:
					state = FIRE
					_st = WARN_T
					fired += 1
					Sfx.play("s62_charge", knot(), 0.0, 0.05, 2)
					if not _said and pl.has_method("_say"):
						_said = true
						var m := get_parent()
						if m != null and not m.has_meta("s62_gang_said"):
							m.set_meta("s62_gang_said", true)
							pl._say("A signal in the nerve - SHOOT THE KNOT before it gets there!", PULSE)
			FIRE:
				_st -= delta
				if _st <= 0.0:
					_sync(pl)
					state = IDLE
					_cd = CD
		if Art.on_screen(self, knot(), 300.0) and (state == FIRE or _flash > 0.0 or Engine.get_physics_frames() % 4 == 0):
			queue_redraw()

	# הפולס הגיע: כל הזומבים בטווח יודעים איפה אתה ומסתערים יחד
	func _sync(pl: Node2D) -> void:
		U.sync_ms = Time.get_ticks_msec()
		Sfx.play("s62_sync", knot(), 3.0, 0.0, 1)
		var at: Vector2 = pl.global_position if pl != null else knot()
		for z in get_tree().get_nodes_in_group("zombies"):
			if z.dead or z.is_boss() or absf(z.global_position.x - global_position.x) > RANGE:
				continue
			synced += 1
			z._alert_t = maxf(float(z._alert_t), SYNC_T)
			z.set_meta("drum_t", float(z._time) + SYNC_T)   # (zombie.gd: מהר יותר - כמו התוף של שלב 41)
			z.set_meta("s62_sync", Time.get_ticks_msec() + int(SYNC_T * 1000.0))
			if z.has_method("rush"):
				z.rush(at)
		var t = preload("res://zombie.gd").HitText.new()
		t.text = "THEY THINK AS ONE"
		t.color = Color(1.0, 0.55, 0.45)
		t.size = 22
		get_parent().add_child(t)
		t.global_position = knot() + Vector2(0, -60)

	func _draw() -> void:
		DrawBatch.begin(self)
		_draw_b()
		DrawBatch.end(self)

	func _draw_b() -> void:
		var pts := PackedVector2Array()
		var cols := PackedColorArray()
		Hive.column(pts, cols, 40.0, 720.0, _t, seed_v)
		var kc := Vector2(0, -KNOT_Y)
		var dead := state == DEAD
		# החוט מהתקרה אל הקשר, והפולס שרץ בו
		var k := -1.0
		if state == FIRE:
			k = 1.0 - clampf(_st / WARN_T, 0.0, 1.0)
		var a := THREAD
		var prev := a
		for q in range(1, 17):
			var u := float(q) / 16.0
			var p := a.lerp(kc, u) + Vector2(0.0, sin(u * PI) * 120.0)
			U.seg(pts, cols, prev, p, 4.0 if not dead else 2.0, Color("4a3e30") if not dead else Color("2a2018"))
			if k >= 0.0 and absf(u - k) < 0.07:
				var g := 1.0 - absf(u - k) / 0.07
				U.oval(pts, cols, p, 7.0 + 4.0 * g, 7.0 + 4.0 * g, Color(1.0, 0.5, 0.4, 0.9 * g), 8)
				U.halo(pts, cols, p, 30.0, 30.0, Color(1.0, 0.45, 0.35, 0.35 * g), 10)
			prev = p
		# הקשר: גוש עצבי עם דנדריטים, גרעין זוהר
		if dead:
			U.oval(pts, cols, kc, KNOT_R * 0.8, KNOT_R * 0.6, Color("2a1414"), 12)
			U.oval(pts, cols, kc + Vector2(0, 2), KNOT_R * 0.4, KNOT_R * 0.3, Color(0.4, 0.04, 0.04, 0.9), 8)
			for q in 4:
				U.seg(pts, cols, kc, kc + Vector2.from_angle(float(q) * 1.4 + 0.5) * 16.0 + Vector2(0, 10), 2.0, Color("2a1a14"))
		else:
			var warn := 0.0 if state != FIRE else 1.0 - _st / WARN_T
			var pul := 0.5 + 0.5 * sin(_t * (3.0 + warn * 20.0))
			for q in 7:
				var an := float(q) / 7.0 * TAU + sin(_t * 1.5 + float(q)) * 0.15
				var tip := kc + Vector2.from_angle(an) * (KNOT_R + 14.0 + U.h(q, seed_v) * 10.0)
				U.taper(pts, cols, kc, tip, 6.0, 1.2, Color("8a7058"), Color("5a4a3a"))
				U.oval(pts, cols, tip, 2.0, 2.0, Color(PULSE, 0.4 + 0.5 * pul), 6)
			var body := Color("b89878") if _flash <= 0.0 else Color.WHITE
			U.oval(pts, cols, kc, KNOT_R + 2.0, KNOT_R, Color("4a3428"), 16)
			U.oval(pts, cols, kc, KNOT_R, KNOT_R - 2.0, body, 16)
			U.oval(pts, cols, kc + Vector2(-5, -5), KNOT_R * 0.35, KNOT_R * 0.25, Color(1, 1, 1, 0.3), 8)
			var nc := PULSE.lerp(Color(1.0, 0.4, 0.3), warn)
			U.halo(pts, cols, kc, 34.0 + 16.0 * warn, 34.0 + 16.0 * warn, Color(nc, 0.25 + 0.3 * pul * (0.4 + warn)), 12)
			U.oval(pts, cols, kc, 6.0 + 2.0 * pul, 6.0 + 2.0 * pul, Color(nc, 0.9), 10)
			U.oval(pts, cols, kc, 2.6, 2.6, Color(1, 1, 1, 0.9), 6)
		U.flush(self, pts, cols)
		if state == FIRE:
			DrawBatch.string(self, ThemeDB.fallback_font, kc + Vector2(-5.0, -36.0), "!", HORIZONTAL_ALIGNMENT_LEFT, -1, 26, Color(1.0, 0.5, 0.4, 0.6 + 0.4 * sin(_t * 30.0)))


class GangBody extends StaticBody2D:
	var trap = null

	func take_damage(amount: int, hit_pos: Vector2, dir: Vector2, explosive := false, src := {}) -> void:
		if trap == null or not is_instance_valid(trap):
			return
		var d := 12
		if src.has("fixed"):
			d = int(src.fixed)
		elif explosive:
			d = maxi(amount, 30)
		elif src.has("dmg_mult"):
			d = int(round(13.0 * float(src.dmg_mult)))
		trap.hurt(maxi(d, 1), hit_pos, dir)


# ============================================================
#  סוגר בשר ברצפה (מלכודת): עומדים עליו -> רועד -> הלסתות נסגרות מלמטה. אוכל גם זומבים. יורים בעין שעל הגבעול
# ============================================================
class Maw extends Node2D:
	const HALF_W := 48.0
	const WARN_T := 0.6
	const BITE_T := 0.32
	const CHEW_T := 0.9
	const CD := 2.4
	const DMG := 1
	const HOLD_T := 0.9
	const DMG_Z := 140
	const HP := 46
	const EYE := Vector2(HALF_W + 26.0, -58.0)
	enum {IDLE, WARN, BITE, CHEW, DEAD}
	var state := IDLE
	var hp := HP
	var bites := 0                  # לבדיקות
	var hits := 0
	var eaten := 0
	var _t := 0.0
	var _st := 0.0
	var _cd := 0.0
	var _flash := 0.0
	var _hit := false
	var _body: StaticBody2D = null
	var _said := false

	func _ready() -> void:
		z_index = 4
		add_to_group("hazards")
		add_to_group("blastable")
		_body = GangBody.new()
		_body.trap = self
		_body.collision_layer = 4
		_body.collision_mask = 0
		_body.add_to_group("no_outline")
		var cs := CollisionShape2D.new()
		var rs := CircleShape2D.new()
		rs.radius = 14.0
		cs.shape = rs
		_body.add_child(cs)
		_body.position = EYE
		add_child(_body)

	func world_rect() -> Rect2:
		return Rect2(global_position + Vector2(-HALF_W, -70.0), Vector2(HALF_W * 2.0, 70.0))

	func danger_at(p: Vector2, margin := 0.0) -> bool:
		return state != DEAD and world_rect().grow(margin).has_point(p)

	func blast_rect() -> Rect2:
		return Rect2(global_position + Vector2(-HALF_W, -30.0), Vector2(HALF_W * 2.0 + 40.0, 40.0))

	func hit_by_blast(_c: Vector2, _r: float) -> void:
		hurt(HP, global_position + EYE, Vector2.UP)

	func hurt(n: int, at: Vector2, dir: Vector2) -> void:
		if state == DEAD:
			return
		hp -= n
		_flash = 0.12
		if Art.on_screen(self, at):
			Particles.burst(get_parent(), at, "hit", -dir, 5)
			Sfx.play("s62_squish", at, -3.0, 0.15, 3)
		if state == IDLE:   # נפגע: נסגר חזק לרגע (לא נושך)
			_cd = maxf(_cd, 1.2)
		if hp <= 0:
			state = DEAD
			if _body != null:
				_body.queue_free()
				_body = null
			Sfx.play("s62_maw_die", global_position, 2.0, 0.1, 2)
			Particles.burst(get_parent(), global_position + Vector2(0, -10), "hit", Vector2.UP, int(16.0 * Quality.gore()) + 2)
			var t = preload("res://zombie.gd").HitText.new()
			t.text = "MAW DEAD"
			t.color = Color("ffb0a0")
			t.size = 18
			get_parent().add_child(t)
			t.global_position = global_position + Vector2(0, -90)
		queue_redraw()

	func _on_it(p: Vector2) -> bool:
		return absf(p.x - global_position.x) < HALF_W * 0.85 and absf(p.y - global_position.y) < 20.0

	func _physics_process(delta: float) -> void:
		_t += delta
		_cd -= delta
		_flash -= delta
		if state == DEAD:
			return
		var pl := get_tree().get_first_node_in_group("player") as Node2D
		match state:
			IDLE:
				if _cd <= 0.0 and Engine.get_physics_frames() % 3 == 0:
					var who: bool = pl != null and not pl.dead and _on_it(pl.global_position)
					if not who:
						for z in get_tree().get_nodes_in_group("zombies"):
							if not z.dead and z.is_on_floor() and not z.is_boss() and _on_it(z.global_position):
								who = true
								break
					if who:
						state = WARN
						_st = WARN_T
						Sfx.play("s62_gurgle", global_position, -2.0, 0.1, 2)
			WARN:
				_st -= delta
				if _st <= 0.0:
					state = BITE
					_st = BITE_T
					_hit = false
					bites += 1
					Sfx.play("s62_chomp", global_position + Vector2(0, -20), 3.0, 0.1, 2)
					_bite(pl)
			BITE:
				_st -= delta
				if _st <= 0.0:
					state = CHEW
					_st = CHEW_T
			CHEW:
				_st -= delta
				if _st <= 0.0:
					state = IDLE
					_cd = CD
		if Art.on_screen(self, global_position, 200.0) and (state != IDLE or _flash > 0.0 or Engine.get_physics_frames() % 3 == 0):
			queue_redraw()

	func _bite(pl: Node2D) -> void:
		if pl != null and not pl.dead and _on_it(pl.global_position) or (pl != null and world_rect().intersects(pl.body_rect()) and absf(pl.global_position.y - global_position.y) < 40.0):
			hits += 1
			pl.hurt(DMG, Vector2(0.0, -1.0))
			pl.slow_t = maxf(float(pl.slow_t), HOLD_T)
			if not _said and pl.has_method("_say"):
				_said = true
				pl._say("The floor BIT me - shoot the eye on the stalk!", Color("ffb0a0"))
		for z in get_tree().get_nodes_in_group("zombies"):
			if z.dead or z.is_boss() or not _on_it(z.global_position):
				continue
			eaten += 1
			z._popup("DEVOURED", Color("ffb0a0"), 15, -70.0)
			z.take_damage(DMG_Z, z.global_position + Vector2(0, -20), Vector2.UP, true, {"source": "hazard", "fixed": DMG_Z})

	func _draw() -> void:
		DrawBatch.begin(self)
		_draw_b()
		DrawBatch.end(self)

	func _draw_b() -> void:
		var pts := PackedVector2Array()
		var cols := PackedColorArray()
		var dead := state == DEAD
		var warn := 0.0
		var open := 0.0
		var jaw := 0.0
		match state:
			WARN:
				warn = 1.0 - _st / WARN_T
				open = warn * 0.6
			BITE:
				jaw = clampf(1.0 - _st / BITE_T, 0.0, 1.0)
				jaw = sin(jaw * PI * 0.5)
			CHEW:
				jaw = 1.0 - clampf(1.0 - _st / CHEW_T, 0.0, 1.0) * 0.9
		var qv := sin(_t * 40.0) * 1.5 * warn
		var breathe := 0.5 + 0.5 * sin(_t * 1.6)
		# השפתיים על הרצפה (טבעת בשר)
		U.oval(pts, cols, Vector2(0, -1.0), HALF_W + 6.0, 6.0 + 2.0 * breathe, Color("5a2830") if not dead else Color("2a1416"), 18)
		U.oval(pts, cols, Vector2(qv, -1.5), HALF_W * (0.55 + 0.4 * open), 3.0 + 2.5 * open, Color("1a0608"), 16)
		if not dead:
			U.oval(pts, cols, Vector2(qv, -1.5), HALF_W * 0.35 * (0.5 + open), 1.4 + open, Color(0.7, 0.2, 0.25, 0.6), 10)
			for q in 8:   # קפלים רדיאליים
				var a := float(q) / 8.0 * TAU
				U.seg(pts, cols, Vector2(cos(a) * HALF_W * 0.6, sin(a) * 2.0 - 1.0), Vector2(cos(a) * (HALF_W + 4.0), sin(a) * 5.0 - 1.0), 1.6, Color(0.2, 0.05, 0.08, 0.7))
			if warn > 0.0:   # רוק מבעבע
				for q in 4:
					var bp := Vector2(sin(float(q) * 2.3) * HALF_W * 0.4, -4.0 - fposmod(_t * 30.0 + float(q) * 7.0, 14.0))
					U.oval(pts, cols, bp, 2.0, 2.0, Color(0.85, 0.9, 0.7, 0.6), 6)
		# הלסתות: שתי שורות שיניים שעולות מהרצפה ונסגרות
		if jaw > 0.0:
			var hgt := 74.0 * jaw
			for s: float in [-1.0, 1.0]:
				var xin := s * HALF_W * (1.0 - jaw * 0.85)
				var xout := s * (HALF_W + 8.0)
				U.quad(pts, cols, Vector2(xout, 0.0), Vector2(xin, 0.0), Vector2(xin * 0.9, -hgt), Vector2(xout * 0.85, -hgt * 0.8), Color("6a3038"), Color("8a4048"), Color("a85060"), Color("6a3038"))
				for q in 5:
					var ty := -hgt * (0.15 + 0.18 * float(q))
					var tx := lerpf(xin, xin * 0.9, 0.15 + 0.18 * float(q))
					U.tri(pts, cols, Vector2(tx, ty - 5.0), Vector2(tx, ty + 5.0), Vector2(tx - s * 14.0, ty), Color("e8e0c8"))
		# הגבעול עם העין (המטרה)
		var stalk_top := EYE + Vector2(sin(_t * 1.3) * 4.0, 0.0)
		U.taper(pts, cols, Vector2(HALF_W + 18.0, 0.0), stalk_top + Vector2(0, 8.0), 9.0, 5.0, Color("4a2830"), Color("6a3840"))
		if dead:
			U.oval(pts, cols, stalk_top + Vector2(2, 10), 9.0, 6.0, Color("2a1416"), 10)
		else:
			var white := Color("e8dcc8") if _flash <= 0.0 else Color.WHITE
			U.oval(pts, cols, stalk_top, 12.0, 11.0, Color("5a2830"), 14)
			U.oval(pts, cols, stalk_top, 10.0, 9.0, white, 14)
			var look := Vector2(-3.0, 1.0 + 2.0 * warn)
			U.oval(pts, cols, stalk_top + look, 5.0, 5.0, Color(0.85, 0.35 + 0.4 * (1.0 - warn), 0.1), 12)
			U.oval(pts, cols, stalk_top + look, 2.2, 3.4, Color(0.02, 0.02, 0.02), 8)
			for q in 3:   # כלי דם
				U.seg(pts, cols, stalk_top + Vector2.from_angle(float(q) * 2.0 + 0.4) * 9.5, stalk_top + Vector2.from_angle(float(q) * 2.0 + 0.6) * 5.0, 0.8, Color(0.7, 0.1, 0.1, 0.7))
		U.flush(self, pts, cols)


# ============================================================
#  בריכת זיכרון: צלליות של הגיבור מול בוס ישן מהבהבות בתוכה. rise() = REMNANT יוצא ממנה
# ============================================================
class MemoryPool extends Node2D:
	const W := 150.0
	var memory := 0                 # MEMORIES[memory] (REMNANT.memory)
	var big := false                # הבריכה של הסצנה (גדולה, הכוורת מדברת ממנה)
	var used := 0                   # כמה פעמים משהו יצא ממנה
	var _t := 0.0
	var _rise := -1.0

	func _ready() -> void:
		z_index = 2

	func width() -> float:
		return W * (2.2 if big else 1.0)

	func rise() -> void:
		used += 1
		_rise = 0.0
		Sfx.play("s62_rise", global_position + Vector2(0, -20), 0.0, 0.1, 2)
		if Art.on_screen(self, global_position, 200.0):
			Particles.burst(get_parent(), global_position + Vector2(0, -6), "drop", Vector2.UP, 10)

	func _process(delta: float) -> void:
		_t += delta
		if _rise >= 0.0:
			_rise += delta
			if _rise > 1.2:
				_rise = -1.0
		if Engine.get_process_frames() % 3 == 0 and Art.on_screen(self, global_position + Vector2(0, -60), width()):
			queue_redraw()

	func _draw() -> void:
		DrawBatch.begin(self)
		_draw_b()
		DrawBatch.end(self)

	func _draw_b() -> void:
		var pts := PackedVector2Array()
		var cols := PackedColorArray()
		var hw := width() * 0.5
		var rp := clampf(1.0 - U.since(U.replay_ms) / 3.0, 0.0, 1.0) if U.replay_ms >= 0 else 0.0
		var talk := clampf(1.0 - U.since(U.voice_ms) * 0.35, 0.0, 1.0) if (U.voice_ms >= 0 and big) else 0.0
		var flash := (1.0 - _rise / 1.2) if _rise >= 0.0 else 0.0
		var lum := 0.55 + 0.15 * sin(_t * 1.7) + 0.35 * maxf(rp, flash) + 0.25 * talk
		# שפת הבריכה (בשר) + המים הזוהרים
		U.oval(pts, cols, Vector2(0, 0.0), hw + 10.0, 9.0, Color("2a1418"), 20)
		U.oval(pts, cols, Vector2(0, -0.5), hw, 6.0, Color(0.08, 0.3, 0.32), 20)
		U.halo(pts, cols, Vector2(0, -1.0), hw * 0.95, 5.5, Color(MEM, 0.55 * lum), 18)
		# אדוות
		for q in 3:
			var k := fposmod(_t * 0.35 + float(q) * 0.33, 1.0)
			var rr := hw * (0.2 + 0.75 * k)
			var prev := Vector2(rr, -1.0)
			for s in range(1, 17):
				var a := float(s) / 16.0 * TAU
				var p := Vector2(cos(a) * rr, sin(a) * rr * 0.055 - 1.0)
				U.seg(pts, cols, prev, p, 1.0, Color(1, 1, 1, 0.22 * (1.0 - k)))
				prev = p
		# אור עולה מהבריכה
		U.quad(pts, cols, Vector2(-hw * 0.85, -1.0), Vector2(hw * 0.85, -1.0), Vector2(hw * 0.6, -150.0 - 60.0 * talk), Vector2(-hw * 0.6, -150.0 - 60.0 * talk),
			Color(MEM, 0.16 * lum), Color(MEM, 0.16 * lum), Color(MEM, 0.0), Color(MEM, 0.0))
		# השחזור: הגיבור (שמאל) יורה על הזיכרון (ימין). מהבהב כמו סרט ישן
		if not big:
			var fl := 0.55 + 0.45 * (1.0 if fposmod(_t * 7.3, 1.0) > 0.12 else 0.2)
			var ca := Color(MEM, (0.3 + 0.4 * maxf(rp, flash)) * fl)
			var shoot := fposmod(_t, 2.4) < 1.6
			U.figure(pts, cols, -hw * 0.45, -3.0, 50.0, ca, 1 if shoot else 0, 1.0)
			if shoot and fposmod(_t * 6.0, 1.0) < 0.4:
				U.oval(pts, cols, Vector2(-hw * 0.45 + 26.0, -3.0 - 44.0 * 50.0 / 56.0), 3.0, 2.0, Color(1.0, 0.9, 0.6, 0.6 * fl), 6)
			_enemy(pts, cols, Vector2(hw * 0.4, -3.0), ca, fposmod(_t, 2.4) > 1.9)
			# שורות סריקה (זיכרון משוחזר)
			for q in 5:
				var sy := -fposmod(_t * 40.0 + float(q) * 23.0, 110.0)
				U.rect(pts, cols, Rect2(-hw * 0.8, sy, hw * 1.6, 1.2), Color(MEM, 0.08))
		U.flush(self, pts, cols)
		if not big:
			var m := memory if memory >= 0 and memory < MEMORIES.size() else 0
			DrawBatch.string(self, ThemeDB.fallback_font, Vector2(-hw * 0.6, 22.0), "MEMORY: " + String(MEMORIES[m]), HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(MEM, 0.55 + 0.3 * maxf(rp, flash)))

	# צללית הזיכרון לפי סוג (כמו ה-REMNANT שייצא)
	func _enemy(pts: PackedVector2Array, cols: PackedColorArray, p: Vector2, c: Color, fall: bool) -> void:
		match memory:
			0:   # THE FIRST: ענק עם דלת מכונית
				U.figure(pts, cols, p.x, p.y, 74.0, c, 2 if fall else 0, -1.0)
				U.rect(pts, cols, Rect2(p.x - 26.0, p.y - 62.0, 12.0, 44.0), c)
			1:   # THE SPITTER: גבנון, צוואר נפוח
				U.figure(pts, cols, p.x, p.y, 50.0, c, 2 if fall else 0, -1.0)
				U.oval(pts, cols, p + Vector2(-2.0, -40.0), 8.0, 6.0, c, 8)
			2:   # SUBJECT FOUR: חייל עם רובה
				U.figure(pts, cols, p.x, p.y, 58.0, c, 2 if fall else 1, -1.0)
			_:   # THE HOUND: על ארבע
				var b := p + Vector2(0, -22.0)
				U.oval(pts, cols, b, 22.0, 9.0, c, 10)
				U.oval(pts, cols, b + Vector2(-24.0, -6.0), 8.0, 6.0, c, 8)
				for q in 4:
					U.seg(pts, cols, b + Vector2(-14.0 + float(q) * 9.0, 4.0), Vector2(p.x - 16.0 + float(q) * 10.0, p.y), 3.0, c)


# ---- פטריית מדף ענקית על הקיר (הקומה = add_floor בשלב) ----
class Shelf extends Node2D:
	var w := 200.0
	var tier := 120.0
	var seed_v := 0
	var _t := 0.0

	func _ready() -> void:
		z_index = 0

	func _process(delta: float) -> void:
		_t += delta
		if Engine.get_process_frames() % 8 == 0 and Art.on_screen(self, global_position + Vector2(w * 0.5, -tier), w):
			queue_redraw()

	func _draw() -> void:
		DrawBatch.begin(self)
		_draw_b()
		DrawBatch.end(self)

	func _draw_b() -> void:
		var pts := PackedVector2Array()
		var cols := PackedColorArray()
		var top := -tier
		# הגבעול / הקיר שהמדף צומח ממנו
		U.vrect(pts, cols, Rect2(w * 0.35, top, w * 0.3, tier), Color("3a2a22"), Color("1e1410"))
		for q in 3:
			U.seg(pts, cols, Vector2(w * 0.4 + float(q) * w * 0.1, top + 10.0), Vector2(w * 0.38 + float(q) * w * 0.11, 0.0), 1.4, Color(MYC, 0.25))
		# מתחת: זימים
		U.quad(pts, cols, Vector2(0, top + 4.0), Vector2(w, top + 4.0), Vector2(w * 0.8, top + 26.0), Vector2(w * 0.2, top + 26.0), Color("6a5440"), Color("6a5440"), Color("2a1e16"), Color("2a1e16"))
		for q in int(w / 9.0):
			var gx := 4.0 + float(q) * 9.0
			U.seg(pts, cols, Vector2(gx, top + 5.0), Vector2(lerpf(gx, w * 0.5, 0.35), top + 24.0), 1.0, Color(0.12, 0.08, 0.06, 0.7))
		# הכובע (המשטח שעומדים עליו)
		var prev := Vector2(-6.0, top + 6.0)
		for q in range(1, 13):
			var u := float(q) / 12.0
			var p := Vector2(-6.0 + u * (w + 12.0), top + 6.0 - sin(u * PI) * 7.0)
			U.quad(pts, cols, prev, p, Vector2(p.x, top + 8.0), Vector2(prev.x, top + 8.0), Color("c8a878"), Color("c8a878"), Color("8a6a48"), Color("8a6a48"))
			prev = p
		U.seg(pts, cols, Vector2(0, top + 1.0), Vector2(w, top + 1.0), 1.4, Color(1.0, 0.95, 0.8, 0.4))
		for q in int(w / 30.0):   # טבעות גדילה + נקודות זוהרות
			var px := 10.0 + float(q) * 30.0 + U.h(q, seed_v) * 10.0
			U.oval(pts, cols, Vector2(px, top + 2.0), 3.0, 1.2, Color(ECHO, 0.4 + 0.3 * sin(_t * 2.0 + float(q))), 6)
		U.flush(self, pts, cols)


# ============================================================
#  חדר הקול האחד (סצנת הסיפור): קיר מוח ענק, כל חוטי העצב מתכנסים אל הבריכה הגדולה שבמרכז
# ============================================================
class HiveChamber extends Node2D:
	var w := 1500.0
	var cx := 900.0                 # מרכז הבריכה (יחסית)
	var _t := 0.0

	func _ready() -> void:
		z_index = -3

	func _process(delta: float) -> void:
		_t += delta
		if Engine.get_process_frames() % 3 == 0 and Art.on_screen(self, global_position + Vector2(w * 0.5, -200), w * 0.6):
			queue_redraw()

	func _draw() -> void:
		DrawBatch.begin(self)
		_draw_b()
		DrawBatch.end(self)

	func _draw_b() -> void:
		var pts := PackedVector2Array()
		var cols := PackedColorArray()
		var talk := clampf(1.0 - U.since(U.voice_ms) * 0.35, 0.0, 1.0) if U.voice_ms >= 0 else 0.0
		var fc := clampf(U.since(U.face_ms) / 2.0, 0.0, 1.0) if U.face_ms >= 0 else 0.0
		# קשת המוח הענקית מאחורי הבריכה
		var c := Vector2(cx, -260.0)
		for r in 6:
			var rr := 520.0 - float(r) * 60.0
			var col := Color("2a141c").lerp(GUM, 0.08 + float(r) * 0.03 + 0.12 * talk)
			var prev := c + Vector2(-rr, 260.0)
			for q in range(1, 25):
				var a := PI + PI * float(q) / 24.0
				var wob := sin(float(q) * 1.9 + float(r) * 2.0) * 10.0
				var p := c + Vector2(cos(a) * (rr + wob), sin(a) * (rr * 0.72 + wob) + 260.0 * (1.0 - absf(sin(a))) * 0.0 + 260.0 + sin(a) * 0.0)
				p.y = c.y + 260.0 + sin(a) * (rr * 0.9 + wob)
				U.seg(pts, cols, prev, p, 30.0, col)
				U.seg(pts, cols, prev + Vector2(0, 14.0), p + Vector2(0, 14.0), 2.0, Color(0.05, 0.02, 0.03, 0.7))
				prev = p
		# חוטי העצב מכל הכיוונים אל הבריכה - פולסים רצים פנימה (וכשהיא מדברת - חזק)
		for q in 14:
			var a := Vector2(-200.0 + float(q) * (w + 400.0) / 13.0, -620.0 + U.h(q, 40) * 200.0)
			var b := Vector2(cx + (float(q) - 6.5) * 12.0, -14.0)
			var kk := fposmod(_t * (0.35 + 0.6 * talk) + U.h(q, 41), 1.0)
			U.nerve(pts, cols, a, b, 120.0 + U.h(q, 42) * 80.0, 3.0, kk, Color("4a3e30").lerp(NERVE, 0.2 + 0.3 * talk), 12)
		# עמודי זיכרון בצדדים (גולמים זוהרים)
		for q in 4:
			var px := 120.0 + float(q) * (w - 240.0) / 3.0
			if absf(px - cx) < 260.0:
				continue
			U.oval(pts, cols, Vector2(px, -150.0), 34.0, 80.0, Color("3a2a22"), 14)
			U.oval(pts, cols, Vector2(px, -150.0), 28.0, 72.0, Color(MEM, 0.12 + 0.12 * talk), 14)
			U.figure(pts, cols, px, -84.0, 110.0, Color(0.1, 0.2, 0.22, 0.5), q % 3, 1.0 if px < cx else -1.0)
		# הפנים: מעל הבריכה, בקיר, מופיעים כשהכוורת מדברת (והופכים לפנים שלך ב-"face")
		var fa := 0.08 + 0.3 * talk
		if fa > 0.1:
			var fcx := Vector2(cx, -420.0)
			U.oval(pts, cols, fcx, 70.0, 90.0, Color(ECHO, fa * 0.25), 18)
			U.oval(pts, cols, fcx + Vector2(-24.0, -10.0), 12.0, 6.0 + 2.0 * fc, Color(0.0, 0.0, 0.0, fa * 1.6), 10)
			U.oval(pts, cols, fcx + Vector2(24.0, -10.0), 12.0, 6.0 + 2.0 * fc, Color(0.0, 0.0, 0.0, fa * 1.6), 10)
			U.oval(pts, cols, fcx + Vector2(-24.0, -10.0), 3.0, 3.0, Color(ECHO, fa * 2.4), 8)
			U.oval(pts, cols, fcx + Vector2(24.0, -10.0), 3.0, 3.0, Color(ECHO, fa * 2.4), 8)
			U.oval(pts, cols, fcx + Vector2(0, 40.0), 20.0 - 6.0 * fc, 3.0 + 4.0 * talk * (0.5 + 0.5 * sin(_t * 18.0)), Color(0.0, 0.0, 0.0, fa * 1.4), 10)
			if fc > 0.0:   # קווי הפנים של הגיבור: לסת, שיער קצר
				U.seg(pts, cols, fcx + Vector2(-60.0, 20.0), fcx + Vector2(0, 80.0), 3.0, Color(MEM, fa * fc * 1.4))
				U.seg(pts, cols, fcx + Vector2(60.0, 20.0), fcx + Vector2(0, 80.0), 3.0, Color(MEM, fa * fc * 1.4))
				U.seg(pts, cols, fcx + Vector2(-56.0, -50.0), fcx + Vector2(56.0, -56.0), 6.0, Color(MEM, fa * fc * 1.2))
		U.flush(self, pts, cols)


# ============================================================
#  זירת THE FLOOD: אגן מוצף, קיר הלב עם עורקים, ובסוף הפיר שיורד אל הלב (U.heart = הלמות)
# ============================================================
class FloodArena extends Node2D:
	var w := 1200.0
	var _t := 0.0

	func _ready() -> void:
		z_index = -3

	func _process(delta: float) -> void:
		_t += delta
		if Engine.get_process_frames() % 3 == 0 and Art.on_screen(self, global_position + Vector2(w * 0.5, -200), w * 0.6):
			queue_redraw()

	func _draw() -> void:
		DrawBatch.begin(self)
		_draw_b()
		DrawBatch.end(self)

	func _draw_b() -> void:
		var pts := PackedVector2Array()
		var cols := PackedColorArray()
		var beat := pow(maxf(0.0, sin(_t * 5.2)), 6.0) + 0.6 * pow(maxf(0.0, sin(_t * 5.2 - 0.9)), 6.0)
		var hb := (0.3 + 0.7 * U.heart) * beat
		# קיר הלב: צלעות בשר עבות, אדום-סגול
		U.vrect(pts, cols, Rect2(0, -620.0, w, 620.0), Color("1a080c"), Color("3a1418"))
		for q in int(w / 90.0) + 1:
			var rx := float(q) * 90.0
			U.quad(pts, cols, Vector2(rx, -620.0), Vector2(rx + 30.0, -620.0), Vector2(rx + 50.0 + sin(float(q)) * 10.0, 0.0), Vector2(rx + 10.0, 0.0),
				Color("2a0e14"), Color("3a141a"), Color("5a2028").lerp(Color("8a2a30"), hb * 0.5), Color("3a141a"))
		# עורקים גדולים שמתכנסים אל הפיר (ימינה למטה)
		var hole := Vector2(w - 120.0, -90.0)
		for q in 7:
			var a := Vector2(float(q) * 150.0, -560.0 + U.h(q, 50) * 260.0)
			var col := Color("6a1a22").lerp(Color("c0303a"), hb * 0.6)
			U.nerve(pts, cols, a, hole + Vector2(-20.0 + float(q) * 6.0, -40.0 + float(q) * 6.0), -80.0, 9.0 - float(q) * 0.6, -1.0, col, 12)
		# הפיר אל הלב: פתח בשר ענק עם זוהר ירוק-אדום מבפנים
		U.oval(pts, cols, hole, 150.0, 120.0, Color("2a0a0e"), 24)
		U.oval(pts, cols, hole + Vector2(0, 10.0), 120.0, 96.0, Color("0a0204"), 24)
		U.halo(pts, cols, hole + Vector2(0, 30.0), 110.0, 80.0, Color(0.8, 0.25, 0.2, 0.25 + 0.4 * hb), 16)
		U.halo(pts, cols, hole + Vector2(0, 40.0), 70.0, 50.0, Color(ECHO, 0.15 + 0.25 * hb), 12)
		for q in 12:   # קפלי הסוגר
			var a := float(q) / 12.0 * TAU
			U.taper(pts, cols, hole + Vector2(cos(a) * 150.0, sin(a) * 120.0), hole + Vector2(cos(a) * 100.0, sin(a) * 80.0) * (1.0 - 0.06 * hb) + hole * 0.06 * hb, 14.0, 4.0, Color("4a1a20"), Color("7a2a30"))
		# הנוזל הירוק על רצפת הזירה (שכבה דקה, אדוות)
		U.vrect(pts, cols, Rect2(0, -6.0, w - 200.0, 6.0), Color(TOX, 0.0), Color(TOX_D, 0.55))
		for q in 10:
			var k := fposmod(_t * 0.3 + float(q) * 0.1, 1.0)
			U.oval(pts, cols, Vector2(80.0 + float(q) * (w - 300.0) / 10.0, -2.0), 20.0 + 40.0 * k, 1.6, Color(0.8, 1.0, 0.7, 0.25 * (1.0 - k)), 12)
		U.flush(self, pts, cols)
		DrawBatch.string(self, ThemeDB.fallback_font, hole + Vector2(-58.0, -150.0), "EL CORAZON", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color(1.0, 0.5, 0.45, 0.45 + 0.4 * hb))


# ============================================================
#  מכשולים (מוצקים + מחסה): "pod" גולם עם גופה / "bones" ערמת עצמות / "stalk" אשכול פטריות / "root" שורש מקושת
# ============================================================
class Obstacle extends Node2D:
	var kind := "pod"
	var size := Vector2(90, 56)
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
			"pod":   # גולם פטרייה שוכב, גופה בפנים, חוטים
				U.oval(pts, cols, Vector2(w * 0.5, -h * 0.5), w * 0.5 + 2.0, h * 0.5 + 2.0, Color("2a1e16"), 18)
				U.oval(pts, cols, Vector2(w * 0.5, -h * 0.5), w * 0.5, h * 0.5, Color("7a6a4a"), 18)
				U.oval(pts, cols, Vector2(w * 0.45, -h * 0.62), w * 0.32, h * 0.2, Color(1, 1, 1, 0.12), 12)
				U.oval(pts, cols, Vector2(w * 0.3, -h * 0.5), h * 0.18, h * 0.16, Color(0.2, 0.14, 0.1, 0.6), 10)
				U.seg(pts, cols, Vector2(w * 0.38, -h * 0.5), Vector2(w * 0.85, -h * 0.45), h * 0.22, Color(0.2, 0.14, 0.1, 0.5))
				for q in 6:
					var x := w * (0.1 + 0.16 * float(q))
					U.seg(pts, cols, Vector2(x, -h), Vector2(x + r.randf_range(-6, 6), 0.0), 1.2, Color(MYC, 0.35))
				U.vein(pts, cols, Vector2(w * 0.8, -h * 0.2), Vector2(w * 0.95, -h * 0.9), 2.0, 0.0, float(seed_v % 100), seed_v)
			"bones":   # ערמת עצמות וגולגולות
				U.quad(pts, cols, Vector2(0, 0), Vector2(w * 0.3, -h), Vector2(w * 0.7, -h * 0.95), Vector2(w, 0), Color("6a5e4a"), Color("8a7e66"), Color("8a7e66"), Color("6a5e4a"))
				for q in 14:
					var p := Vector2(r.randf_range(w * 0.1, w * 0.9), -r.randf_range(4.0, h * 0.9))
					p.y = maxf(p.y, -h * (1.0 - absf(p.x / w - 0.5) * 1.6))
					if q % 3 == 0:
						U.oval(pts, cols, p, 8.0, 7.0, BONE, 10)
						U.oval(pts, cols, p + Vector2(-3, -1), 2.2, 2.4, Color(0.06, 0.04, 0.04), 6)
						U.oval(pts, cols, p + Vector2(3, -1), 2.2, 2.4, Color(0.06, 0.04, 0.04), 6)
					else:
						var a := r.randf_range(-0.8, 0.8)
						U.seg(pts, cols, p - Vector2.from_angle(a) * 12.0, p + Vector2.from_angle(a) * 12.0, 3.5, BONE.darkened(r.randf_range(0.0, 0.3)))
				U.vein(pts, cols, Vector2(w * 0.2, -2.0), Vector2(w * 0.5, -h * 0.8), 2.0, 0.0, float(seed_v % 100), seed_v)
			"stalk":   # אשכול פטריות ענקיות
				for q in 3:
					var sx := w * (0.2 + 0.3 * float(q))
					var sh2 := h * (0.7 + 0.3 * float((q + seed_v) % 2))
					U.vrect(pts, cols, Rect2(sx - 6.0, -sh2, 12.0, sh2), Color("c8c0a0"), Color("8a8268"))
					U.oval(pts, cols, Vector2(sx, -sh2), w * 0.22, 9.0, Color("3a5a2c"), 14)
					U.oval(pts, cols, Vector2(sx, -sh2 + 2.0), w * 0.2, 4.0, Color(ECHO, 0.55), 12)
					U.oval(pts, cols, Vector2(sx - 4.0, -sh2 - 4.0), w * 0.08, 2.0, Color(1, 1, 1, 0.2), 8)
			_:   # שורש מקושת שיוצא מהרצפה
				var prev_o := Vector2(0, 0)
				var prev_i := Vector2(14.0, 0)
				for q in range(1, 11):
					var a := PI - PI * float(q) / 10.0
					var o := Vector2(w * 0.5 + cos(a) * w * 0.5, -sin(a) * h)
					var i := Vector2(w * 0.5 + cos(a) * (w * 0.5 - 14.0), -sin(a) * (h - 14.0))
					U.quad(pts, cols, prev_o, o, i, prev_i, Color("4a3428"), Color("4a3428"), Color("2a1c14"), Color("2a1c14"))
					prev_o = o
					prev_i = i
				U.vein(pts, cols, Vector2(6.0, -4.0), Vector2(w * 0.5, -h + 4.0), 2.4, 0.0, float(seed_v % 100), seed_v)
		U.flush(self, pts, cols)


# ============================================================
#  רסס רפש ירוק (SEEPER): טיפות שעפות ונוחתות, נשארות רגע ככתם. זז ב-_process (לא MOVER)
# ============================================================
class GooSplash extends Node2D:
	const MAX_LIVE := 10
	static var live := 0
	var ground := 630.0
	var drops := []                 # [מיקום, מהירות, גודל, נחת]
	var tint := TOX
	var _t := 0.0

	static func spawn(parent: Node, at: Vector2, dir: Vector2, n: int, ground_y: float, col := TOX) -> void:
		if parent == null or live >= MAX_LIVE or not Art.on_screen(parent, at, 80.0):
			return
		var g := GooSplash.new()
		g.ground = ground_y
		g.tint = col
		var k := Quality.scaled(n, Quality.gore())
		for i in k:
			var a := dir.angle() + randf_range(-1.1, 1.1) if dir != Vector2.ZERO else -PI * 0.5 + randf_range(-1.3, 1.3)
			g.drops.append([Vector2(randf_range(-4, 4), randf_range(-4, 4)), Vector2.from_angle(a) * randf_range(90.0, 300.0) + Vector2(0, -90.0), randf_range(1.6, 3.6), false])
		parent.add_child(g)
		g.global_position = at

	func _enter_tree() -> void:
		live += 1
		z_index = 9

	func _exit_tree() -> void:
		live -= 1

	func _process(delta: float) -> void:
		_t += delta
		if _t > 1.4:
			queue_free()
			return
		var gy := ground - global_position.y
		for d in drops:
			if d[3]:
				continue
			d[1].y += 900.0 * delta
			d[0] += d[1] * delta
			if d[0].y >= gy:
				d[0].y = gy
				d[3] = true
		queue_redraw()

	func _draw() -> void:
		DrawBatch.begin(self)
		_draw_b()
		DrawBatch.end(self)

	func _draw_b() -> void:
		var a := clampf((1.4 - _t) / 0.5, 0.0, 1.0)
		var pts := PackedVector2Array()
		var cols := PackedColorArray()
		for d in drops:
			var p: Vector2 = d[0]
			var r: float = d[2]
			if d[3]:
				U.oval(pts, cols, p, r * 2.2, r * 0.5, Color(tint.darkened(0.3), 0.75 * a), 8)
			else:
				var v: Vector2 = d[1]
				U.seg(pts, cols, p - v * 0.02, p, r * 1.4, Color(tint, 0.8 * a))
				U.oval(pts, cols, p, r, r, Color(tint, 0.9 * a), 6)
				U.oval(pts, cols, p + Vector2(-r * 0.3, -r * 0.3), r * 0.35, r * 0.35, Color(1, 1, 1, 0.6 * a), 4)
		U.flush(self, pts, cols)


# ============================================================
#  מסך: נבגים, הלמות לב בשולי המסך (U.heart), אדווה כשהכוורת מדברת (U.voice_ms), הבזק "THINK AS ONE" (U.sync_ms)
# ============================================================
class HiveFX extends Node2D:
	var vp := Vector2(1280, 720)
	var _t := 0.0

	func _process(delta: float) -> void:
		_t += delta
		U.t = _t
		if Engine.get_process_frames() % 2 == 0:
			queue_redraw()

	func _draw() -> void:
		DrawBatch.begin(self)
		_draw_b()
		DrawBatch.end(self)

	func _draw_b() -> void:
		var q := clampf(Quality.ambient(), 0.3, 1.0)
		var pts := PackedVector2Array()
		var cols := PackedColorArray()
		for i in int(34.0 * q):   # נבגים שמרחפים מול המצלמה
			var x := fposmod(U.h(i, 1) * vp.x * 1.7 + sin(_t * 0.5 + float(i)) * 40.0 + _t * 6.0, vp.x)
			var y := fposmod(U.h(i, 2) * vp.y - _t * (12.0 + U.h(i, 3) * 20.0), vp.y)
			U.dia(pts, cols, Vector2(x, y), 1.0 + U.h(i, 4) * 1.6, Color(ECHO if i % 4 != 0 else MEM, 0.22 + 0.3 * U.h(i, 5)))
		# הלמות לב בשולי המסך (חזק יותר ליד הלב)
		if U.heart > 0.01:
			var beat := pow(maxf(0.0, sin(_t * 5.2)), 6.0) + 0.6 * pow(maxf(0.0, sin(_t * 5.2 - 0.9)), 6.0)
			var c0 := Color(0.55, 0.05, 0.08, 0.22 * U.heart * beat)
			var c1 := Color(0.55, 0.05, 0.08, 0.0)
			U.quad(pts, cols, Vector2(0, 0), Vector2(140.0, 0), Vector2(140.0, vp.y), Vector2(0, vp.y), c0, c1, c1, c0)
			U.quad(pts, cols, Vector2(vp.x - 140.0, 0), Vector2(vp.x, 0), Vector2(vp.x, vp.y), Vector2(vp.x - 140.0, vp.y), c1, c0, c0, c1)
			U.quad(pts, cols, Vector2(0, vp.y - 100.0), Vector2(vp.x, vp.y - 100.0), Vector2(vp.x, vp.y), Vector2(0, vp.y), c1, c1, c0, c0)
		# הכוורת מדברת: אדווה ירוקה בשוליים
		var vt := U.since(U.voice_ms)
		if vt >= 0.0 and vt < 2.5:
			var a := (1.0 - vt / 2.5) * 0.2
			var g0 := Color(0.5, 1.0, 0.5, a)
			var g1 := Color(0.5, 1.0, 0.5, 0.0)
			U.quad(pts, cols, Vector2(0, 0), Vector2(vp.x, 0), Vector2(vp.x, 70.0), Vector2(0, 70.0), g0, g0, g1, g1)
			U.quad(pts, cols, Vector2(0, vp.y - 70.0), Vector2(vp.x, vp.y - 70.0), Vector2(vp.x, vp.y), Vector2(0, vp.y), g1, g1, g0, g0)
		# קשר עצב ירה: הבזק אדום-כתום קצר
		var st := U.since(U.sync_ms)
		if st >= 0.0 and st < 0.6:
			var a2 := (1.0 - st / 0.6) * 0.18
			U.rect(pts, cols, Rect2(Vector2.ZERO, vp), Color(1.0, 0.4, 0.3, a2))
		U.flush(self, pts, cols)
