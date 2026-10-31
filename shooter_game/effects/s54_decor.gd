extends RefCounted
const DrawBatch := preload("res://effects/draw_batch.gd")
# ============================================================
#  קישוטים לשלב 54 ("LAST BRIDGE") - לילה על גשר הברזל הישן מעל הריו נגרו, בין כרמן דה פטגונס לוויֶדמה. סוף אזור שישי.
#  השער לפטגוניה: ירח גדול ונמוך, רוח קרה מהדרום, ובמים מתחת - העדר חוצה. הגיבור צריך לפוצץ את הגשר.
#    bridge_sky    - (רקע) לילה, ירח ענק ונמוך עם הילה, כוכבים מנצנצים, עננים קרועים ברוח שעוברים על הירח,
#                    זוהר קר (כמו זוהר קוטב) רחוק בדרום (צד ימין), כוכב נופל מדי פעם
#    far_steppe    - (רקע, 0.06) הרים רחוקים מושלגים בדרום, מסות של הערבה הפטגונית, מגדל הכנסייה של פטגונס על הגבעה
#                    (חלון דולק, מגדלור אדום מהבהב), מדורות רחוקות, שורת מתים קטנה שהולכת דרומה
#    mid_river     - (רקע, 0.28) הנהר: הגדה הרחוקה עם צפצפות ואורות, השתקפות הירח שרועדת, העדר שחוצה במים הרדודים
#                    (ראשים כהים במים כסופים, ידיים מורמות), סירות בוערות שנסחפות עם הזרם. כשהגשר מתפוצץ - העדר שוקע.
#    near_truss    - (רקע, 0.6) המסבך של הצד השני של הגשר: אלכסונים ומסמרות שחולפים, מעקה ופנסים רחוקים, פסולת שעפה ברוח
#    BankGround / BridgeDeck / SouthGround - (עולם) מרצפת אבנים בגדה הצפונית / משטח הגשר: אספלט, מפרקי התפשטות, קורה ראשית
#                    עם מסמרות ומים חשוכים מתחת / חצץ ואדמה בגדה הדרומית
#    Truss         - (עולם) מסבך הברזל של הגשר (מאחורי הדמויות): עמודים, אלכסונים, קורה עליונה, פלטות חיבור. cut0/cut1 = חלק שנפל.
#    ClimbSpan     - (קבוצה "s54_truss") קטע קורה עליונה ש-DARKSEEKER יכול לזחול מתחתיו (x0, x1, top_y)
#    Gantry        - (עולם) מסלול שירות תלוי מתחת לקורה העליונה (הקומה = add_floor)
#    TownFront     - (עולם) בתים קולוניאליים של פטגונס בגדה הצפונית, מרפסת ברזל (קומה), חלונות דולקים
#    BridgePortal  - (עולם) עמוד האבן בכניסה לגשר עם לוח "1931", שלט "VIEDMA", גרפיטי של הצבא
#    ChargePoint   - (עולם, קבוצה "s54_charges") מטען חבלה על עמוד המסבך. עומדים לידו ARM_T שניות = דרוך (מהבהב אדום).
#    Roadblock     - (עולם, קיר) מחסום הצבא בכניסה לזירה. סגור עד שכל המטענים דרוכים.
#    BrokenDeck    - (עולם, מלכודת) לוחות סדוקים: עולים עליהם (או 3+ זומבים) -> חריקה (WARN_T) -> נופלים לנהר.
#                    נשאר חור: זומבים שנכנסים לתוכו נופלים למים. אתה עובר על הקורה.
#    RollingTruck  - (עולם, מלכודת) משאית צבא נטושה: יורים בבלם (האור האדום) -> מתגלגלת ודורסת זומבים -> מתרסקת ומתפוצצת.
#    LiveCable     - (עולם, מלכודת) כבל חשמל קרוע מהמסבך: מזמזם (WARN_T) ואז פורק קשת לכביש - פוגע בך ובזומבים (וקופץ לזומבי הבא).
#    Obstacle      - (מוצק + מחסה) "jersey" מחסומי בטון / "ammo" ארגזי תחמושת / "wreck" מכונית שרופה / "convoy" משאית שיירה
#    SouthBank     - (עולם) הגדה הדרומית - הזירה של THE ARCHITECT: ראש הגשר, שקי חול, שלט "RUTA 3 - PATAGONIA"
#    BridgeCollapse - (עולם) רצף ההתמוטטות כשהבוס מת: צפצופים מואצים, פיצוצים לאורך הגשר, חלקי מסבך ולוחות נופלים, התזות.
#    BridgeFX / ChargeHud / CollapseBanner - (מסך) רוח וערפל נהר / מונה מטענים / הבזק + "THE BRIDGE IS DOWN"
#    FlickerLamp   - פנס גשר (street_lamp.gd) שמהבהב כל הזמן
#  לשנות: TRUSS_H, ChargePoint.ARM_T / ARM_R, BrokenDeck.WARN_T / HEAVY, RollingTruck.ROLL_DIST / MAX_V / CRUSH,
#         LiveCable.CD / WARN_T / ARC_R / DMG_Z, BridgeCollapse.BEEP_T / STEP.
# ============================================================

const Art := preload("res://art.gd")
const Sfx := preload("res://sfx.gd")
const Kit := preload("res://effects/backdrop_kit.gd")
const Particles := preload("res://particles.gd")
const Boom := preload("res://explosion.gd")
const FireScript := preload("res://fire.gd")

const IRON := Color("3e4858")
const IRON_D := Color("1e242e")
const IRON_L := Color("8292a8")
const RIVET := Color("a4b0c0")
const MOON := Color("eef2fa")
const SODIUM := Color(1.0, 0.78, 0.45)
const RIVER := Color("0e1a2e")
const ASPHALT := Color("30333c")
const OLIVE := Color("4e5634")
const OLIVE_D := Color("343a22")
const TRUSS_H := 210.0          # גובה המסבך (הקורה העליונה) מעל הכביש
const PANEL := 160.0            # מרחק בין עמודי המסבך


# מצב משותף + עזרים שגם המחלקות הפנימיות צריכות (מחלקה פנימית לא רואה פונקציות סטטיות של הקובץ)
class U:
	static var boom_ms := -1        # מתי הגשר התפוצץ (השכבה האמצעית: העדר שוקע, התזות בנהר). -1 = עוד לא
	static var roar_ms := -1        # (סצנת סיפור) העדר במים מרים ידיים ועיניים נדלקות

	static func h(i: int, s: int) -> float:
		return fposmod(sin(float(i) * 12.9898 + float(s) * 78.233) * 43758.5453, 1.0)

	static func flush(ci: CanvasItem, pts: PackedVector2Array, cols: PackedColorArray) -> void:
		if not pts.is_empty():
			DrawBatch.tris(ci, pts, cols)

	static func quad(pts: PackedVector2Array, cols: PackedColorArray, a: Vector2, b: Vector2, c: Vector2, d: Vector2, ca: Color, cb: Color, cc: Color, cd: Color) -> void:
		pts.append_array([a, b, c, a, c, d])
		cols.append_array([ca, cb, cc, ca, cc, cd])


static func _h(i: int, s: int) -> float:
	return fposmod(sin(float(i) * 12.9898 + float(s) * 78.233) * 43758.5453, 1.0)


static func _flush(ci: CanvasItem, pts: PackedVector2Array, cols: PackedColorArray) -> void:
	if not pts.is_empty():
		DrawBatch.tris(ci, pts, cols)


# יהלום קטן (כוכב / מסמרה) = 2 משולשים
static func _dia(pts: PackedVector2Array, cols: PackedColorArray, c: Vector2, r: float, col: Color) -> void:
	pts.append_array([c + Vector2(-r, 0), c + Vector2(0, -r), c + Vector2(r, 0), c + Vector2(-r, 0), c + Vector2(r, 0), c + Vector2(0, r)])
	for q in 6:
		cols.append(col)


# מרובע עם צבע למעלה / למטה
static func _quad(pts: PackedVector2Array, cols: PackedColorArray, a: Vector2, b: Vector2, c: Vector2, d: Vector2, ca: Color, cb: Color, cc: Color, cd: Color) -> void:
	pts.append_array([a, b, c, a, c, d])
	cols.append_array([ca, cb, cc, ca, cc, cd])


# אליפסה מלאה כמניפת משולשים (n צלעות)
static func _oval(pts: PackedVector2Array, cols: PackedColorArray, c: Vector2, rx: float, ry: float, col: Color, n := 8) -> void:
	for q in n:
		var a0 := float(q) / float(n) * TAU
		var a1 := float(q + 1) / float(n) * TAU
		pts.append_array([c, c + Vector2(cos(a0) * rx, sin(a0) * ry), c + Vector2(cos(a1) * rx, sin(a1) * ry)])
		cols.append_array([col, col, col])


static func moon_pos(v: Vector2) -> Vector2:
	return Vector2(v.x * 0.3, v.y * 0.4)


static func _ms_since(ms: int) -> float:
	return -1.0 if ms < 0 else float(Time.get_ticks_msec() - ms) / 1000.0


# ---- שמיים ----
static func bridge_sky(ci: CanvasItem, v: Vector2, t: float) -> void:
	Kit.gradient_sky(ci, v, [Color("04070f"), Color("0a1226"), Color("17243f"), Color("2e3e5c")], 0.92)
	var pts := PackedVector2Array()
	var cols := PackedColorArray()
	for i in 160:   # כוכבים
		var p := Vector2(_h(i, 1) * v.x, pow(_h(i, 2), 1.5) * v.y * 0.6)
		var tw := 0.55 + 0.45 * sin(t * (1.2 + _h(i, 3) * 3.0) + float(i))
		_dia(pts, cols, p, 0.8 + _h(i, 4) * 1.5, Color(0.86, 0.9, 1.0, (0.25 + 0.6 * _h(i, 5)) * tw))
	# זוהר קר בדרום: וילונות אנכיים שזזים לאט (חזק יותר בצד ימין)
	var n := 56
	for i in n:
		var a0 := _aurora(float(i) / float(n), t)
		var a1 := _aurora(float(i + 1) / float(n), t)
		var x0 := float(i) / float(n) * v.x
		var x1 := float(i + 1) / float(n) * v.x
		var b0 := Vector2(x0, v.y * 0.6 + a0.y)
		var b1 := Vector2(x1, v.y * 0.6 + a1.y)
		var c0 := Color(0.35, 1.0, 0.72, a0.z)
		var c1 := Color(0.35, 1.0, 0.72, a1.z)
		_quad(pts, cols, b0 + Vector2(0, -a0.x), b1 + Vector2(0, -a1.x), b1, b0, Color(0.45, 0.55, 1.0, 0.0), Color(0.45, 0.55, 1.0, 0.0), c1, c0)
		_quad(pts, cols, b0, b1, b1 + Vector2(0, 10), b0 + Vector2(0, 10), Color(c0, a0.z * 1.4), Color(c1, a1.z * 1.4), Color(c1, 0.0), Color(c0, 0.0))
	_flush(ci, pts, cols)
	# הירח: גדול ונמוך
	var mp := moon_pos(v)
	Kit.soft_glow(ci, mp, 330.0, Color(0.62, 0.74, 1.0, 0.16))
	Kit.soft_glow(ci, mp, 160.0, Color(0.85, 0.9, 1.0, 0.3))
	DrawBatch.circle(ci, mp, 76.0, MOON)
	for q in 7:   # ים הירח
		var c := mp + Vector2(cos(float(q) * 2.1) * 34.0 * _h(q, 11), sin(float(q) * 2.1) * 30.0 * _h(q, 12))
		DrawBatch.colored_polygon(ci, Art.ellipse(c, 10.0 + _h(q, 13) * 14.0, 7.0 + _h(q, 14) * 10.0, float(q), 12), Color(0.76, 0.8, 0.88, 0.55))
	DrawBatch.arc(ci, mp, 75.0, 0.0, TAU, 48, Color(1, 1, 1, 0.6), 2.0)
	# עננים קרועים ברוח - עוברים על הירח, עם שוליים כסופים לידו
	for i in 8:
		var x := fposmod(_h(i, 8) * v.x * 1.7 - t * (20.0 + float(i) * 5.0), v.x + 800.0) - 400.0
		var y := v.y * (0.14 + _h(i, 9) * 0.36)
		var rx := 200.0 + _h(i, 10) * 140.0
		var ry := 9.0 + _h(i, 15) * 14.0
		var d := Vector2(x, y).distance_to(mp)
		Kit.soft_ellipse(ci, Vector2(x, y), rx, ry, -0.03, Color(0.05, 0.07, 0.13, 0.72))
		for w in 3:   # קרעים
			Kit.soft_ellipse(ci, Vector2(x + rx * (0.5 + 0.3 * float(w)), y + ry * (0.6 - 0.5 * float(w))), rx * 0.3, ry * 0.45, -0.06, Color(0.05, 0.07, 0.13, 0.5))
		if d < 300.0:
			Kit.soft_ellipse(ci, Vector2(x, y - ry * 0.55), rx * 0.92, ry * 0.45, -0.03, Color(0.75, 0.84, 1.0, 0.3 * (1.0 - d / 300.0)))
	# כוכב נופל
	var ph := fmod(t, 11.0)
	if ph < 0.6:
		var s0 := Vector2(v.x * (0.5 + 0.4 * _h(int(t / 11.0), 21)), v.y * 0.08)
		var p2 := s0 + Vector2(-260.0, 90.0) * (ph / 0.6)
		DrawBatch.line(ci, p2, p2 + Vector2(70.0, -24.0), Color(0.9, 0.95, 1.0, 0.7 * (1.0 - ph / 0.6)), 1.6)


# [גובה הווילון, היסט הבסיס, עוצמה] ל-x יחסי
static func _aurora(xn: float, t: float) -> Vector3:
	var h := 70.0 + 80.0 * (0.5 + 0.5 * sin(xn * 9.0 + t * 0.25)) + 30.0 * sin(xn * 23.0 - t * 0.6)
	var y := sin(xn * 5.0 + t * 0.18) * 14.0
	var a := smoothstep(0.2, 0.95, xn) * (0.45 + 0.55 * (0.5 + 0.5 * sin(xn * 13.0 - t * 0.4))) * 0.2
	return Vector3(h, y, a)


# ---- הערבה הרחוקה והרי הדרום ----
static func far_steppe(ci: CanvasItem, sc: float, v: Vector2, y: float, t: float) -> void:
	Kit.soft_glow(ci, Vector2(v.x * 0.86, y - 50.0), 460.0, Color(0.3, 0.95, 0.7, 0.07), 0.3)   # זוהר מאחורי ההרים
	var period := 1800.0
	var start := int(floor(sc / period)) - 1
	for k in range(start, start + int(ceil(v.x / period)) + 2):
		var bx := float(k) * period - sc
		# הרים: רכס משונן, שלג על הפסגות
		var ridge := PackedVector2Array([Vector2(bx, y)])
		var peaks := []
		for q in 25:
			var px := bx + float(q) * 75.0
			var hh := 46.0
			if q > 0 and q < 24:
				hh = (95.0 + _h(k * 31 + q, 1) * 85.0) if q % 2 == 1 else (40.0 + _h(k * 31 + q, 2) * 35.0)
			ridge.append(Vector2(px, y - hh))
			if q % 2 == 1:
				peaks.append(Vector2(px, y - hh))
		ridge.append(Vector2(bx + period, y))
		DrawBatch.colored_polygon(ci, ridge, Color("1d2a46"))
		for pk: Vector2 in peaks:
			var gl := 0.75 + 0.25 * sin(t * 0.8 + pk.x * 0.01)
			DrawBatch.colored_polygon(ci, PackedVector2Array([pk, pk + Vector2(26, 24), pk + Vector2(10, 20), pk + Vector2(0, 28), pk + Vector2(-12, 19), pk + Vector2(-26, 24)]), Color(0.6, 0.7, 0.86).darkened(0.1) * Color(gl, gl, gl))
			DrawBatch.line(ci, pk, pk + Vector2(-20, 19), Color(0.85, 0.92, 1.0, 0.5), 1.2)   # צד מואר מהירח
		# מסות שטוחות של הערבה
		for q in 4:
			var mx := bx + 120.0 + float(q) * 440.0 + _h(k * 7 + q, 3) * 80.0
			var mw := 160.0 + _h(k * 7 + q, 4) * 140.0
			var mh := 26.0 + _h(k * 7 + q, 5) * 22.0
			DrawBatch.colored_polygon(ci, PackedVector2Array([Vector2(mx - 30, y), Vector2(mx, y - mh), Vector2(mx + mw, y - mh), Vector2(mx + mw + 40, y)]), Color("141c30"))
			DrawBatch.line(ci, Vector2(mx, y - mh), Vector2(mx + mw, y - mh), Color(0.5, 0.6, 0.8, 0.35), 1.2)
		# הגבעה של פטגונס עם מגדל הכנסייה (רק פעם בשתי תקופות - זה מאחורינו, בצפון)
		if posmod(k, 2) == 0:
			var cx := bx + 320.0
			DrawBatch.colored_polygon(ci, Art.ellipse(Vector2(cx, y + 6.0), 190.0, 52.0, 0.0, 24), Color("111829"))
			DrawBatch.rect(ci, Rect2(cx - 50.0, y - 86.0, 74.0, 50.0), Color("1a2236"))   # הספינה
			DrawBatch.colored_polygon(ci, PackedVector2Array([Vector2(cx - 54, y - 86), Vector2(cx - 13, y - 104), Vector2(cx + 28, y - 86)]), Color("161e30"))
			DrawBatch.rect(ci, Rect2(cx + 24.0, y - 150.0, 26.0, 114.0), Color("1e283e"))   # המגדל
			DrawBatch.rect(ci, Rect2(cx + 22.0, y - 118.0, 30.0, 3.0), Color("2a3450"))
			DrawBatch.rect(ci, Rect2(cx + 31.0, y - 140.0, 12.0, 16.0), Color("0a0e18"))   # פתח הפעמון
			DrawBatch.arc(ci, Vector2(cx + 37.0, y - 140.0), 6.0, PI, TAU, 8, Color("0a0e18"), 3.0)
			DrawBatch.colored_polygon(ci, Art.ellipse(Vector2(cx + 37.0, y - 152.0), 15.0, 12.0, 0.0, 14), Color("222c44"))   # כיפה
			DrawBatch.line(ci, Vector2(cx + 37.0, y - 164.0), Vector2(cx + 37.0, y - 180.0), Color("2a3450"), 2.0)
			DrawBatch.line(ci, Vector2(cx + 32.0, y - 175.0), Vector2(cx + 42.0, y - 175.0), Color("2a3450"), 2.0)
			var wl := 0.7 + 0.3 * sin(t * 5.0) * sin(t * 1.7)
			DrawBatch.rect(ci, Rect2(cx - 30.0, y - 72.0, 6.0, 10.0), Color(1.0, 0.75, 0.4, 0.8 * wl))   # חלון דולק - מישהו עוד שם
			Art.glow(ci, Vector2(cx - 27.0, y - 67.0), 14.0, Color(1.0, 0.7, 0.35, 0.3 * wl))
			if fmod(t, 2.4) < 0.25:   # מגדלור אדום על המגדל
				Art.glow(ci, Vector2(cx + 37.0, y - 182.0), 16.0, Color(1.0, 0.2, 0.15, 0.6))
				DrawBatch.circle(ci, Vector2(cx + 37.0, y - 182.0), 2.0, Color(1.0, 0.4, 0.3))
		# מדורות רחוקות על הערבה
		for q in 3:
			var fx := bx + 500.0 + float(q) * 520.0 + _h(k * 3 + q, 6) * 100.0
			var fl := 0.6 + 0.4 * sin(t * 9.0 + float(q * 3 + k))
			Art.glow(ci, Vector2(fx, y - 4.0), 10.0 + 4.0 * fl, Color(1.0, 0.5, 0.2, 0.35 * fl))
			DrawBatch.rect(ci, Rect2(fx - 1.0, y - 6.0, 2.0, 3.0), Color(1.0, 0.7, 0.3, fl))
	# שורת מתים זעירה שהולכת דרומה (ימינה) על קו האופק - לא תלוי בגלילה
	var hx := fposmod(t * 7.0 - sc * 0.4, v.x + 500.0) - 250.0
	for q in 22:
		var dx := hx - float(q) * 11.0 - _h(q, 7) * 30.0
		var bob := absf(sin(t * 4.0 + float(q))) * 0.8
		DrawBatch.line(ci, Vector2(dx, y - 2.0), Vector2(dx, y - 7.0 - bob), Color(0.05, 0.07, 0.11, 0.9), 1.6)
		DrawBatch.circle(ci, Vector2(dx, y - 8.0 - bob), 1.3, Color(0.05, 0.07, 0.11, 0.9))
	DrawBatch.rect(ci, Rect2(0, y - 1.0, v.x, v.y - y + 1.0), Color("0f1626"))


# ---- הנהר: הגדה הרחוקה, השתקפות הירח, העדר שחוצה, סירות בוערות ----
static func mid_river(ci: CanvasItem, sc: float, v: Vector2, y: float, t: float) -> void:
	var ry := y - 150.0    # פני המים
	var boom := _ms_since(U.boom_ms)
	var roar := _ms_since(U.roar_ms)
	# הגדה הרחוקה: צפצפות ואורות קטנים
	var period := 1100.0
	var start := int(floor(sc / period)) - 1
	for k in range(start, start + int(ceil(v.x / period)) + 2):
		var bx := float(k) * period - sc
		DrawBatch.colored_polygon(ci, PackedVector2Array([Vector2(bx, ry + 2), Vector2(bx, ry - 14), Vector2(bx + 300, ry - 20), Vector2(bx + 700, ry - 12), Vector2(bx + period, ry - 16), Vector2(bx + period, ry + 2)]), Color("0b111d"))
		for q in 9:
			var px := bx + 40.0 + float(q) * 118.0 + _h(k * 9 + q, 1) * 40.0
			var ph := 40.0 + _h(k * 9 + q, 2) * 34.0
			var sw := sin(t * 1.4 + float(q)) * 2.5
			DrawBatch.colored_polygon(ci, PackedVector2Array([Vector2(px - 7, ry - 12), Vector2(px - 5 + sw * 0.5, ry - ph * 0.6), Vector2(px + sw, ry - ph), Vector2(px + 5 + sw * 0.5, ry - ph * 0.6), Vector2(px + 7, ry - 12)]), Color("0d1424"))
		for q in 5:   # אורות של ויֶדמה (מעטים - העיר כמעט ריקה)
			var lx := bx + 90.0 + float(q) * 210.0 + _h(k * 5 + q, 3) * 60.0
			if _h(k * 5 + q, 4) < 0.55:
				var on := 0.6 + 0.4 * sin(t * 2.0 + float(q * 7 + k))
				DrawBatch.rect(ci, Rect2(lx, ry - 9.0, 3.0, 2.0), Color(1.0, 0.8, 0.5, 0.8 * on))
				DrawBatch.line(ci, Vector2(lx + 1.5, ry + 3.0), Vector2(lx + 1.5, ry + 14.0 + 4.0 * on), Color(1.0, 0.75, 0.4, 0.25 * on), 2.0)
	# המים: פסים כהים, אדוות שזורמות שמאלה
	var bands := 26
	var span := v.y - ry
	for i in bands:
		var k2 := float(i) / float(bands - 1)
		DrawBatch.rect(ci, Rect2(0, ry + span * float(i) / float(bands - 1) - 1.0, v.x, span / float(bands - 1) + 2.0), Color("1e3050").lerp(RIVER, pow(k2, 0.7)))
	var pts := PackedVector2Array()
	var cols := PackedColorArray()
	var mx := moon_pos(v).x
	for i in 70:   # אדוות
		var yy := ry + 4.0 + pow(_h(i, 5), 1.3) * (span - 10.0)
		var xx := fposmod(_h(i, 6) * 2400.0 - sc * (0.9 + (yy - ry) / span * 0.4) - t * (14.0 + _h(i, 7) * 10.0), v.x + 200.0) - 100.0
		var ln := 14.0 + _h(i, 8) * 30.0
		var a := 0.08 + 0.1 * (1.0 - absf(xx - mx) / v.x)
		_quad(pts, cols, Vector2(xx, yy), Vector2(xx + ln, yy), Vector2(xx + ln, yy + 1.4), Vector2(xx, yy + 1.4), Color(0.7, 0.8, 1.0, a), Color(0.7, 0.8, 1.0, 0.0), Color(0.7, 0.8, 1.0, 0.0), Color(0.7, 0.8, 1.0, a))
	# השתקפות הירח: עמוד של פסים כסופים שרועדים
	for i in 24:
		var yy := ry + 3.0 + float(i) * 6.5
		if yy > v.y:
			break
		var w := 26.0 + float(i) * 4.0 + sin(t * 2.3 + float(i) * 1.7) * 12.0
		var a := 0.55 * (1.0 - float(i) / 24.0) * (0.7 + 0.3 * sin(t * 3.1 + float(i)))
		var off := sin(t * 1.6 + float(i) * 0.9) * 8.0
		var c := Color(0.85, 0.92, 1.0, a)
		var gap := 6.0 + 6.0 * absf(sin(t + float(i)))
		_quad(pts, cols, Vector2(mx - w * 0.5 + off, yy), Vector2(mx - gap + off, yy), Vector2(mx - gap + off, yy + 2.2), Vector2(mx - w * 0.5 + off, yy + 2.2), Color(c, 0.0), c, c, Color(c, 0.0))
		_quad(pts, cols, Vector2(mx + gap + off, yy), Vector2(mx + w * 0.5 + off, yy), Vector2(mx + w * 0.5 + off, yy + 2.2), Vector2(mx + gap + off, yy + 2.2), c, Color(c, 0.0), Color(c, 0.0), c)
	_flush(ci, pts, cols)
	# סירות בוערות שנסחפות עם הזרם (שמאלה), נעלמות בהדרגה בקצוות של המחזור
	var bp := 1500.0
	var bs := int(floor(sc / bp)) - 1
	for k in range(bs, bs + int(ceil(v.x / bp)) + 2):
		var ph := fposmod(t * 9.0 + float(k) * 333.0, 900.0)
		var bxx := float(k) * bp - sc + 900.0 - ph
		var fade := sin(ph / 900.0 * PI)
		var by := ry + 26.0 + _h(k, 9) * 30.0
		_burning_boat(ci, Vector2(bxx, by), t + float(k), fade, 0.8 + _h(k, 10) * 0.35)
	# העדר שחוצה: שלוש שורות של ראשים במים (רחוק = קטן), נעים דרומה (ימינה)
	pts = PackedVector2Array()
	cols = PackedColorArray()
	var sink := clampf(boom / 3.0, 0.0, 1.0) if boom >= 0.0 else 0.0
	var arms := roar >= 0.0 and roar < 4.0
	for r in 3:
		var s := 0.55 + float(r) * 0.28
		var yy := ry + 20.0 + float(r) * 36.0
		var hp := 760.0 + float(r) * 140.0
		var hs := int(floor((sc - t * (9.0 + float(r) * 3.0)) / hp)) - 1
		for k in range(hs, hs + int(ceil(v.x / hp)) + 2):
			var base := float(k) * hp - sc + t * (9.0 + float(r) * 3.0)
			for q in 13:
				var hx := base + 60.0 + float(q) * 17.0 * s + _h(k * 13 + q, r + 20) * 120.0 * s + (0.0 if q < 7 else 160.0 * s)
				if hx < -30.0 or hx > v.x + 30.0:
					continue
				var bob := sin(t * 2.2 + float(q) * 1.3 + float(k)) * 1.6 * s + sink * 26.0 * s
				var a := 1.0 - sink
				if a <= 0.02:
					continue
				var dark := Color(0.03, 0.04, 0.07, 0.95 * a)
				_oval(pts, cols, Vector2(hx, yy + 2.0 * s + bob * 0.3), 10.0 * s, 4.0 * s, Color(0.03, 0.04, 0.07, 0.8 * a), 8)   # כתפיים שקועות
				_oval(pts, cols, Vector2(hx, yy - 5.0 * s + bob), 5.5 * s, 6.5 * s, dark, 8)
				var dm := absf(hx - mx)
				if dm < 200.0:   # שוליים כסופים מהירח
					_quad(pts, cols, Vector2(hx - 5.0 * s, yy - 9.0 * s + bob), Vector2(hx + 5.0 * s, yy - 9.0 * s + bob), Vector2(hx + 4.0 * s, yy - 7.6 * s + bob), Vector2(hx - 4.0 * s, yy - 7.6 * s + bob), Color(0.85, 0.92, 1.0, 0.6 * (1.0 - dm / 200.0) * a), Color(0.85, 0.92, 1.0, 0.6 * (1.0 - dm / 200.0) * a), Color(0.85, 0.92, 1.0, 0.0), Color(0.85, 0.92, 1.0, 0.0))
				# גל קטן סביב (קווים בהירים לצדדים)
				_quad(pts, cols, Vector2(hx - 15.0 * s, yy + 4.0 * s), Vector2(hx - 8.0 * s, yy + 4.0 * s), Vector2(hx - 8.0 * s, yy + 5.0 * s), Vector2(hx - 15.0 * s, yy + 5.0 * s), Color(0.7, 0.8, 1.0, 0.0), Color(0.7, 0.8, 1.0, 0.35 * a), Color(0.7, 0.8, 1.0, 0.35 * a), Color(0.7, 0.8, 1.0, 0.0))
				_quad(pts, cols, Vector2(hx + 8.0 * s, yy + 4.0 * s), Vector2(hx + 15.0 * s, yy + 4.0 * s), Vector2(hx + 15.0 * s, yy + 5.0 * s), Vector2(hx + 8.0 * s, yy + 5.0 * s), Color(0.7, 0.8, 1.0, 0.35 * a), Color(0.7, 0.8, 1.0, 0.0), Color(0.7, 0.8, 1.0, 0.0), Color(0.7, 0.8, 1.0, 0.35 * a))
				var raise := arms or fmod(t * 0.4 + _h(k * 13 + q, 30) * 7.0, 7.0) < 0.6
				if raise and sink < 0.5:   # יד מורמת
					var hb := Vector2(hx + 4.0 * s, yy - 3.0 * s + bob)
					var ht := hb + Vector2(3.0 * s, -16.0 * s)
					_quad(pts, cols, hb, hb + Vector2(2.0 * s, 0), ht + Vector2(1.5 * s, 0), ht, dark, dark, dark, dark)
				if arms or _h(k * 13 + q, 31) < 0.08:   # עיניים שבוהות בגשר
					var ec := Color(0.75, 0.95, 1.0, (0.9 if arms else 0.5) * a)
					_dia(pts, cols, Vector2(hx - 1.8 * s, yy - 6.0 * s + bob), 0.9 * s, ec)
					_dia(pts, cols, Vector2(hx + 1.8 * s, yy - 6.0 * s + bob), 0.9 * s, ec)
	_flush(ci, pts, cols)
	# הגשר התפוצץ: התזות ענק וטבעות במים
	if boom >= 0.0 and boom < 14.0:
		for q in 6:
			var sx := v.x * (0.12 + 0.15 * float(q)) + sin(float(q) * 3.0) * 40.0
			var st := boom - float(q) * 0.35
			if st > 0.0 and st < 3.0:
				var hh := 120.0 * sin(clampf(st / 1.6, 0.0, 1.0) * PI)
				Kit.soft_ellipse(ci, Vector2(sx, ry + 30.0 - hh * 0.5), 24.0 + st * 10.0, hh * 0.5 + 4.0, 0.0, Color(0.8, 0.88, 1.0, 0.35 * (1.0 - st / 3.0)))
			if st > 0.0:
				var rr := st * 60.0
				DrawBatch.polyline(ci, Art.ellipse(Vector2(sx, ry + 34.0), rr, rr * 0.12, 0.0, 24), Color(0.75, 0.85, 1.0, 0.3 * maxf(0.0, 1.0 - st / 6.0)), 1.5)


static func _burning_boat(ci: CanvasItem, p: Vector2, t: float, fade: float, s: float) -> void:
	if fade <= 0.03:
		return
	Kit.soft_glow(ci, p + Vector2(0, 4), 70.0 * s, Color(1.0, 0.45, 0.15, 0.22 * fade), 0.45)
	for q in 6:   # השתקפות האש במים
		var yy := p.y + 6.0 + float(q) * 5.0
		var w := (16.0 - float(q) * 2.0) * s + sin(t * 4.0 + float(q)) * 4.0
		DrawBatch.line(ci, Vector2(p.x - w, yy), Vector2(p.x + w, yy), Color(1.0, 0.55, 0.2, 0.3 * fade * (1.0 - float(q) / 6.0)), 2.0)
	var hull := PackedVector2Array([p + Vector2(-34, -6) * s, p + Vector2(30, -8) * s, p + Vector2(22, 4) * s, p + Vector2(-26, 4) * s])
	DrawBatch.colored_polygon(ci, hull, Color(0.05, 0.04, 0.05, fade))
	DrawBatch.line(ci, p + Vector2(-6, -8) * s, p + Vector2(-12, -40) * s, Color(0.06, 0.05, 0.05, fade), 2.0 * s)   # תורן שבור
	Kit.soft_smoke(ci, p + Vector2(0, -26) * s, t, 150.0 * s, Color(0.06, 0.06, 0.08, 0.3 * fade), 50.0, 6)
	for q in 5:
		var fx := (-20.0 + float(q) * 10.0) * s
		var fh := (14.0 + 10.0 * absf(sin(t * 7.0 + float(q) * 1.9))) * s
		DrawBatch.colored_polygon(ci, PackedVector2Array([p + Vector2(fx - 6.0 * s, -6.0 * s), p + Vector2(fx + 6.0 * s, -6.0 * s), p + Vector2(fx + sin(t * 9.0 + float(q)) * 3.0, -6.0 * s - fh)]), Color(1.0, 0.55 + 0.2 * float(q % 2), 0.15, 0.85 * fade))
	Art.glow(ci, p + Vector2(0, -12) * s, 24.0 * s, Color(1.0, 0.8, 0.4, 0.35 * fade))


# ---- המסבך של הצד השני: אלכסונים, מסמרות, מעקה, פנסים רחוקים, פסולת ברוח ----
static func near_truss(ci: CanvasItem, sc: float, v: Vector2, y: float, t: float) -> void:
	var col := Color("243048")
	var rim := Color(0.55, 0.65, 0.85, 0.25)
	var top := y - 262.0
	var bot := y - 26.0
	var p := 240.0
	var start := int(floor(sc / p)) - 1
	var pts := PackedVector2Array()
	var cols := PackedColorArray()
	DrawBatch.rect(ci, Rect2(0, top - 8.0, v.x, 16.0), col)   # קורה עליונה
	DrawBatch.line(ci, Vector2(0, top - 8.0), Vector2(v.x, top - 8.0), rim, 1.5)
	DrawBatch.rect(ci, Rect2(0, bot - 4.0, v.x, 10.0), col)   # קורה תחתונה
	for k in range(start, start + int(ceil(v.x / p)) + 2):
		var bx := float(k) * p - sc
		DrawBatch.line(ci, Vector2(bx, top), Vector2(bx, bot), col, 11.0)
		DrawBatch.line(ci, Vector2(bx - 5.0, top), Vector2(bx - 5.0, bot), rim, 1.2)
		var a := Vector2(bx, top) if posmod(k, 2) == 0 else Vector2(bx, bot)
		var b := Vector2(bx + p, bot) if posmod(k, 2) == 0 else Vector2(bx + p, top)
		DrawBatch.line(ci, a, b, col, 9.0)
		DrawBatch.line(ci, a + Vector2(0, -4), b + Vector2(0, -4), rim, 1.0)
		for q in 14:   # מסמרות לאורך האלכסון והעמוד
			var r := a.lerp(b, (float(q) + 0.5) / 14.0)
			_dia(pts, cols, r + Vector2(0, -2), 1.3, Color(0.55, 0.62, 0.78, 0.45))
			_dia(pts, cols, Vector2(bx + 3.0, lerpf(top, bot, (float(q) + 0.5) / 14.0)), 1.3, Color(0.55, 0.62, 0.78, 0.4))
		_quad(pts, cols, Vector2(bx - 14, top - 10), Vector2(bx + 14, top - 10), Vector2(bx + 14, top + 14), Vector2(bx - 14, top + 14), col.darkened(0.2), col.darkened(0.2), col.darkened(0.2), col.darkened(0.2))   # פלטת חיבור
		if posmod(k, 4) == 1:   # פנס רחוק בצד השני
			var lp := Vector2(bx + p * 0.5, bot - 150.0)
			DrawBatch.line(ci, Vector2(lp.x, bot), lp, Color("161e2e"), 3.0)
			var fl := 1.0 if fmod(t * 1.3 + float(k), 9.0) > 0.4 else 0.2
			Kit.soft_glow(ci, lp, 46.0, Color(1.0, 0.75, 0.42, 0.22 * fl))
			DrawBatch.circle(ci, lp, 3.0, Color(1.0, 0.85, 0.6, fl))
	_flush(ci, pts, cols)
	for q in 5:   # מעקה הצד השני
		DrawBatch.line(ci, Vector2(0, bot - 34.0 + float(q) * 0.0), Vector2(v.x, bot - 34.0), Color("19212f"), 3.0)
	var rp := 40.0
	var rs := int(floor(sc / rp))
	for k in range(rs, rs + int(v.x / rp) + 2):
		var rx := float(k) * rp - sc
		DrawBatch.line(ci, Vector2(rx, bot - 34.0), Vector2(rx, bot), Color("19212f"), 2.0)
	# פסולת שעפה ברוח (עיתונים, שקיות) - נעה בעצמה, לא תלויה בגלילה
	for i in 7:
		var dx := fposmod(_h(i, 40) * v.x * 2.0 - t * (170.0 + _h(i, 41) * 140.0), v.x + 240.0) - 120.0
		var dy := 180.0 + _h(i, 42) * 330.0 + sin(t * 2.0 + float(i)) * 40.0
		var rot := t * (3.0 + float(i)) + float(i)
		var c2 := Color(0.72, 0.74, 0.7, 0.55) if i % 3 != 0 else Color(0.62, 0.75, 0.9, 0.35)
		var sz := 5.0 + _h(i, 43) * 4.0
		DrawBatch.colored_polygon(ci, PackedVector2Array([Vector2(dx, dy) + Vector2.from_angle(rot) * sz, Vector2(dx, dy) + Vector2.from_angle(rot + 1.9) * sz * 0.6, Vector2(dx, dy) + Vector2.from_angle(rot + PI) * sz, Vector2(dx, dy) + Vector2.from_angle(rot + 4.4) * sz * 0.7]), c2)


# ============================================================
#  עולם
# ============================================================

# ---- מרצפת אבנים בגדה הצפונית (פטגונס) ----
class BankGround extends Node2D:
	var w := 1024.0
	var depth := 90.0
	var seed_v := 0

	func _ready() -> void:
		z_index = 1

	func _draw() -> void:
		DrawBatch.begin(self)
		_draw_b()
		DrawBatch.end(self)

	func _draw_b() -> void:
		DrawBatch.rect(self, Rect2(0, 0, w, depth), Color("17161c"))
		DrawBatch.rect(self, Rect2(0, 0, w, 13.0), Color("34313a"))
		var r := RandomNumberGenerator.new()
		r.seed = seed_v
		var pts := PackedVector2Array()
		var cols := PackedColorArray()
		for row in 3:   # אבני מרצפת
			var x := -float(row % 2) * 8.0
			while x < w:
				var bw := r.randf_range(12.0, 18.0)
				var c := Color("4a4654").darkened(r.randf() * 0.35).lerp(Color("5a6070"), r.randf() * 0.2)
				var y0 := 1.0 + float(row) * 4.2
				_s54_quad(pts, cols, Rect2(x + 1.0, y0, bw - 2.0, 3.4), c)
				x += bw
		if not pts.is_empty():
			DrawBatch.tris(self, pts, cols)
		DrawBatch.rect(self, Rect2(0, 0, w, 1.5), Color(0.62, 0.7, 0.86, 0.5))   # קצה מואר בירח
		for i in int(w / 220.0):   # שלוליות שמשקפות את הירח
			var px := r.randf_range(0.0, w)
			DrawBatch.colored_polygon(self, Art.ellipse(Vector2(px, 4.0), r.randf_range(18.0, 34.0), 2.2, 0.0, 12), Color(0.5, 0.6, 0.8, 0.35))
		for i in int(w / 30.0):
			DrawBatch.circle(self, Vector2(r.randf_range(0.0, w), r.randf_range(22.0, depth - 6.0)), r.randf_range(1.5, 3.5), Color("24222a"))

	static func _s54_quad(pts: PackedVector2Array, cols: PackedColorArray, rc: Rect2, c: Color) -> void:
		pts.append_array([rc.position, Vector2(rc.end.x, rc.position.y), rc.end, rc.position, rc.end, Vector2(rc.position.x, rc.end.y)])
		for q in 6:
			cols.append(c)


# ---- משטח הגשר: אספלט, מפרקים, הקורה הראשית עם מסמרות, ומתחת - הנהר החשוך ----
class BridgeDeck extends Node2D:
	var w := 1024.0
	var depth := 90.0
	var seed_v := 0

	func _ready() -> void:
		z_index = 1

	func _draw() -> void:
		DrawBatch.begin(self)
		_draw_b()
		DrawBatch.end(self)

	func _draw_b() -> void:
		DrawBatch.rect(self, Rect2(0, 0, w, depth), Color("09101c"))
		DrawBatch.rect(self, Rect2(0, 0, w, 11.0), ASPHALT)
		DrawBatch.rect(self, Rect2(0, 0, w, 2.0), Color(0.58, 0.64, 0.78, 0.55))
		var r := RandomNumberGenerator.new()
		r.seed = seed_v
		for i in int(w / 160.0) + 1:   # קווי נתיב דהויים
			DrawBatch.rect(self, Rect2(float(i) * 160.0 + 30.0, 5.0, 56.0, 2.0), Color(0.86, 0.82, 0.6, 0.3))
		for i in int(w / 256.0) + 1:   # מפרקי התפשטות (שיניים)
			var jx := float(i) * 256.0 + 10.0
			DrawBatch.rect(self, Rect2(jx, 0.0, 10.0, 11.0), Color("44484f"))
			for q in 4:
				DrawBatch.line(self, Vector2(jx + 1.0, 2.0 + float(q) * 2.5), Vector2(jx + 9.0, 3.0 + float(q) * 2.5), Color("2a2d33"), 1.0)
		for i in int(w / 70.0):   # טלאים וסדקים באספלט
			var cx := r.randf_range(0.0, w)
			DrawBatch.line(self, Vector2(cx, 3.0), Vector2(cx + r.randf_range(-10.0, 10.0), 9.0), Color(0.1, 0.1, 0.12, 0.6), 1.0)
		# הקורה הראשית (צד)
		DrawBatch.rect(self, Rect2(0, 11.0, w, 30.0), Color("262d3a"))
		DrawBatch.rect(self, Rect2(0, 11.0, w, 3.0), Color("4a5668"))
		DrawBatch.rect(self, Rect2(0, 38.0, w, 4.0), Color("171c26"))
		var pts := PackedVector2Array()
		var cols := PackedColorArray()
		var x := 0.0
		while x < w:
			DrawBatch.line(self, Vector2(x, 14.0), Vector2(x, 38.0), Color("323b4a"), 3.0)   # מחזקים
			DrawBatch.line(self, Vector2(x - 1.5, 14.0), Vector2(x - 1.5, 38.0), Color(0.5, 0.58, 0.72, 0.25), 1.0)
			x += 48.0
		x = 4.0
		while x < w:   # מסמרות
			_dia(pts, cols, Vector2(x, 17.0), 1.4, Color(0.62, 0.68, 0.8, 0.7))
			_dia(pts, cols, Vector2(x, 35.0), 1.4, Color(0.62, 0.68, 0.8, 0.55))
			x += 12.0
		# קורות רוחב שנעלמות בחושך + הנהר רחוק למטה
		for i in int(w / 128.0) + 1:
			DrawBatch.rect(self, Rect2(float(i) * 128.0 + 20.0, 42.0, 10.0, 22.0), Color("121824"))
		DrawBatch.rect(self, Rect2(0, 66.0, w, depth - 66.0), Color("0c1628"))
		for i in int(w / 40.0):
			var gx := r.randf_range(0.0, w)
			_dia(pts, cols, Vector2(gx, r.randf_range(70.0, depth - 4.0)), r.randf_range(1.0, 2.2), Color(0.7, 0.8, 1.0, 0.25))
		if not pts.is_empty():
			DrawBatch.tris(self, pts, cols)

	static func _dia(pts: PackedVector2Array, cols: PackedColorArray, c: Vector2, r: float, col: Color) -> void:
		pts.append_array([c + Vector2(-r, 0), c + Vector2(0, -r), c + Vector2(r, 0), c + Vector2(-r, 0), c + Vector2(r, 0), c + Vector2(0, r)])
		for q in 6:
			cols.append(col)


# ---- אדמה וחצץ בגדה הדרומית ----
class SouthGround extends Node2D:
	var w := 1024.0
	var depth := 90.0
	var seed_v := 0

	func _ready() -> void:
		z_index = 1

	func _draw() -> void:
		DrawBatch.begin(self)
		_draw_b()
		DrawBatch.end(self)

	func _draw_b() -> void:
		DrawBatch.rect(self, Rect2(0, 0, w, depth), Color("1a1814"))
		DrawBatch.rect(self, Rect2(0, 0, w, 12.0), Color("4a4236"))
		DrawBatch.rect(self, Rect2(0, 0, w, 1.5), Color(0.62, 0.68, 0.82, 0.45))
		var r := RandomNumberGenerator.new()
		r.seed = seed_v
		for i in int(w / 6.0):
			DrawBatch.circle(self, Vector2(r.randf_range(0.0, w), r.randf_range(2.0, 11.0)), r.randf_range(0.8, 2.0), Color("6a6050").darkened(r.randf() * 0.4))
		for i in int(w / 40.0):   # שיחי ערבה יבשים
			var bx := r.randf_range(0.0, w)
			for q in 5:
				DrawBatch.line(self, Vector2(bx, 1.0), Vector2(bx + r.randf_range(-7.0, 7.0), r.randf_range(-9.0, -4.0)), Color("5a5236"), 1.0)


# ---- מסבך הברזל של הגשר (מאחורי הדמויות) ----
class Truss extends Node2D:
	var w := 1024.0
	var h := TRUSS_H
	var cut0 := INF                 # (גלובלי) החלק שנפל - לא מצויר
	var cut1 := -INF

	func _ready() -> void:
		z_index = -2

	func cut(a: float, b: float) -> void:
		cut0 = minf(cut0, a)
		cut1 = maxf(cut1, b)
		queue_redraw()

	func _gone(lx: float) -> bool:
		var gx := global_position.x + lx
		return gx > cut0 and gx < cut1

	func _draw() -> void:
		DrawBatch.begin(self)
		_draw_b()
		DrawBatch.end(self)

	func _draw_b() -> void:
		var top := -h
		var pts := PackedVector2Array()
		var cols := PackedColorArray()
		var gi0 := int(round(global_position.x / PANEL))
		var n := int(round(w / PANEL))
		for i in n:   # קורה עליונה (קטעים)
			var x0 := float(i) * PANEL
			var x1 := x0 + PANEL
			if _gone(x0 + PANEL * 0.5):
				continue
			DrawBatch.rect(self, Rect2(x0, top - 10.0, PANEL, 20.0), IRON_D)
			DrawBatch.rect(self, Rect2(x0, top - 8.0, PANEL, 16.0), IRON)
			DrawBatch.line(self, Vector2(x0, top - 8.0), Vector2(x1, top - 8.0), Color(IRON_L, 0.8), 1.6)   # מואר מהירח
			var zz := PackedVector2Array()
			for q in 11:   # שריג
				zz.append(Vector2(x0 + float(q) * PANEL / 10.0, top + (-5.0 if q % 2 == 0 else 5.0)))
			DrawBatch.polyline(self, zz, IRON_D, 1.6)
			for q in 13:
				_s54_dia(pts, cols, Vector2(x0 + 6.0 + float(q) * 12.0, top - 5.0), 1.3, Color(RIVET, 0.6))
				_s54_dia(pts, cols, Vector2(x0 + 6.0 + float(q) * 12.0, top + 6.0), 1.3, Color(RIVET, 0.4))
			# אלכסון (פראט: יורד לכיוון המרכז, מתחלף)
			var down := posmod(gi0 + i, 2) == 0
			var a := Vector2(x0, top) if down else Vector2(x0, -6.0)
			var b := Vector2(x1, -6.0) if down else Vector2(x1, top)
			_member(a, b, 8.0, pts, cols)
		for i in n + 1:   # עמודים
			var x := float(i) * PANEL
			if _gone(x):
				continue
			_member(Vector2(x, -4.0), Vector2(x, top), 10.0, pts, cols)
			DrawBatch.rect(self, Rect2(x - 13.0, top - 12.0, 26.0, 26.0), IRON_D.lightened(0.05))   # פלטת חיבור למעלה
			DrawBatch.rect(self, Rect2(x - 12.0, -30.0, 24.0, 26.0), IRON_D.lightened(0.05))   # ולמטה
			for q in 4:
				_s54_dia(pts, cols, Vector2(x - 6.0 + float(q % 2) * 12.0, top - 6.0 + float(q / 2) * 12.0), 1.6, RIVET)
				_s54_dia(pts, cols, Vector2(x - 6.0 + float(q % 2) * 12.0, -24.0 + float(q / 2) * 12.0), 1.6, RIVET)
		# קצוות שבורים ליד החלק שנפל
		for i in n + 1:
			var x := float(i) * PANEL
			if _gone(x) and not _gone(x - PANEL):
				_stub(Vector2(x - PANEL, top), 1.0)
				_stub(Vector2(x - PANEL, -6.0), 1.0)
			if _gone(x) and not _gone(x + PANEL) and i < n:
				_stub(Vector2(x + PANEL, top), -1.0)
		if not pts.is_empty():
			DrawBatch.tris(self, pts, cols)

	func _stub(p: Vector2, dir: float) -> void:
		DrawBatch.line(self, p, p + Vector2(dir * 46.0, 14.0), IRON, 12.0)
		DrawBatch.line(self, p + Vector2(dir * 46.0, 14.0), p + Vector2(dir * 60.0, 34.0), IRON_D, 4.0)   # ברזל מעוקם
		DrawBatch.circle(self, p + Vector2(dir * 46.0, 14.0), 4.0, Color(1.0, 0.5, 0.2, 0.5))   # עוד לוהט

	# קורה מסומרת: שני אוגנים + שריג + מסמרות
	func _member(a: Vector2, b: Vector2, wd: float, pts: PackedVector2Array, cols: PackedColorArray) -> void:
		var d := (b - a).normalized()
		var nrm := d.orthogonal() * wd * 0.5
		DrawBatch.line(self, a, b, IRON_D, wd + 3.0)
		DrawBatch.line(self, a + nrm, b + nrm, IRON, 3.0)
		DrawBatch.line(self, a - nrm, b - nrm, IRON, 3.0)
		var lit := nrm if nrm.y < 0.0 else -nrm
		DrawBatch.line(self, a + lit * 1.3, b + lit * 1.3, Color(IRON_L, 0.55), 1.2)
		var ln := a.distance_to(b)
		var steps := int(ln / 13.0)
		var zz := PackedVector2Array()
		for q in steps + 1:
			zz.append(a + d * (float(q) * ln / float(maxi(steps, 1))) + (nrm if q % 2 == 0 else -nrm) * 0.8)
		DrawBatch.polyline(self, zz, IRON.darkened(0.15), 1.4)
		for q in int(ln / 22.0):
			_s54_dia(pts, cols, a + d * (11.0 + float(q) * 22.0) + nrm, 1.2, Color(RIVET, 0.55))

	static func _s54_dia(pts: PackedVector2Array, cols: PackedColorArray, c: Vector2, r: float, col: Color) -> void:
		pts.append_array([c + Vector2(-r, 0), c + Vector2(0, -r), c + Vector2(r, 0), c + Vector2(-r, 0), c + Vector2(r, 0), c + Vector2(0, r)])
		for q in 6:
			cols.append(col)


# ---- קטע קורה עליונה ש-DARKSEEKER זוחל מתחתיו ----
class ClimbSpan extends Node:
	var x0 := 0.0
	var x1 := 0.0
	var top_y := 0.0

	func _ready() -> void:
		add_to_group("s54_truss")


# ---- מסלול שירות תלוי (הקומה = add_floor) ----
class Gantry extends Node2D:
	var w := 400.0
	var tier := 150.0

	func _ready() -> void:
		z_index = -1

	func _draw() -> void:
		DrawBatch.begin(self)
		_draw_b()
		DrawBatch.end(self)

	func _draw_b() -> void:
		var y := -tier
		var x := 20.0
		while x < w:   # מתלים לקורה העליונה
			DrawBatch.line(self, Vector2(x, y), Vector2(x, -TRUSS_H + 8.0), IRON_D, 3.0)
			DrawBatch.line(self, Vector2(x - 1.0, y), Vector2(x - 1.0, -TRUSS_H + 8.0), Color(IRON_L, 0.3), 1.0)
			x += 100.0
		DrawBatch.rect(self, Rect2(0, y, w, 9.0), Color("2a3342"))
		for q in int(w / 8.0):   # רשת
			DrawBatch.line(self, Vector2(float(q) * 8.0, y + 1.0), Vector2(float(q) * 8.0 + 6.0, y + 8.0), Color("1a202a"), 1.0)
		DrawBatch.rect(self, Rect2(0, y, w, 1.6), IRON_L)
		for q in int(w / 30.0) + 1:   # פס אזהרה צהוב-שחור
			DrawBatch.rect(self, Rect2(float(q) * 30.0, y + 9.0, 15.0, 4.0), Color(0.85, 0.7, 0.15, 0.85))
			DrawBatch.rect(self, Rect2(float(q) * 30.0 + 15.0, y + 9.0, 15.0, 4.0), Color("15181e"))
		DrawBatch.line(self, Vector2(0, y - 34.0), Vector2(w, y - 34.0), IRON_L.darkened(0.25), 2.4)   # מעקה
		DrawBatch.line(self, Vector2(0, y - 17.0), Vector2(w, y - 17.0), IRON.lightened(0.1), 1.6)
		x = 0.0
		while x <= w:
			DrawBatch.line(self, Vector2(x, y), Vector2(x, y - 34.0), IRON_L.darkened(0.3), 2.0)
			x += 40.0


# ---- הבתים הקולוניאליים של פטגונס + מרפסת ברזל (קומה) ----
class TownFront extends Node2D:
	var w := 1500.0
	var balcony := Vector2(500.0, 860.0)    # מקומי x0, x1 של המרפסת
	var tier := 150.0
	var _t := 0.0

	func _ready() -> void:
		z_index = -3

	func _process(delta: float) -> void:
		_t += delta
		if Engine.get_process_frames() % 6 == 0 and Art.on_screen(self, global_position + Vector2(w * 0.5, -120.0), w * 0.6):
			queue_redraw()

	func _draw() -> void:
		DrawBatch.begin(self)
		_draw_b()
		DrawBatch.end(self)

	func _draw_b() -> void:
		var houses := [[0.0, 230.0, 140.0, Color("4e5470")], [240.0, 210.0, 120.0, Color("6a5a52")], [460.0, 440.0, 270.0, Color("4a6460")],
			[910.0, 250.0, 150.0, Color("6c6252")], [1170.0, 300.0, 130.0, Color("545a74")]]
		for i in houses.size():
			var hs: Array = houses[i]
			var hx: float = hs[0]
			var hw: float = hs[1]
			var hh: float = hs[2]
			var c: Color = hs[3]
			DrawBatch.rect(self, Rect2(hx, -hh, hw, hh), c)
			DrawBatch.rect(self, Rect2(hx, -hh, hw, 2.0), Color(0.75, 0.82, 0.95, 0.35))
			DrawBatch.rect(self, Rect2(hx - 4.0, -hh - 14.0, hw + 8.0, 14.0), c.lightened(0.08))   # מעקה גג (פרפט)
			for q in int(hw / 26.0):
				DrawBatch.rect(self, Rect2(hx + 4.0 + float(q) * 26.0, -hh - 22.0, 14.0, 8.0), c.lightened(0.04))
			DrawBatch.rect(self, Rect2(hx, -16.0, hw, 16.0), c.darkened(0.25))   # צוקל
			for q in int(hw / 26.0):   # טיח שנפל
				if (i * 7 + q) % 5 == 0:
					DrawBatch.rect(self, Rect2(hx + float(q) * 26.0 + 8.0, -hh * 0.6, 14.0, 9.0), c.darkened(0.18))
			var nwin := maxi(1, int(hw / 90.0))
			for q in nwin:   # חלונות קשתיים עם סורגים
				var wx := hx + (float(q) + 0.5) * hw / float(nwin) - 15.0
				for fl in (2 if hh > 200.0 else 1):
					var wy := -100.0 - float(fl) * 130.0
					var lit := (i + q + fl) % 3 == 0
					var on := 0.75 + 0.25 * sin(_t * 6.0 + float(q)) if lit else 0.0
					var wc := Color(0.95, 0.7, 0.36).lerp(Color("0c0e16"), 1.0 - on)
					DrawBatch.rect(self, Rect2(wx, wy, 30.0, 54.0), wc)
					DrawBatch.circle(self, Vector2(wx + 15.0, wy), 15.0, wc)
					if lit:
						Art.glow(self, Vector2(wx + 15.0, wy + 20.0), 40.0, Color(1.0, 0.7, 0.35, 0.18 * on))
					for b in 4:
						DrawBatch.line(self, Vector2(wx + 4.0 + float(b) * 7.0, wy - 10.0), Vector2(wx + 4.0 + float(b) * 7.0, wy + 54.0), Color("1a1c22"), 1.6)
					DrawBatch.rect(self, Rect2(wx - 10.0, wy - 4.0, 9.0, 58.0), c.darkened(0.35))   # תריס
					DrawBatch.rect(self, Rect2(wx + 31.0, wy - 4.0, 9.0, 58.0), c.darkened(0.35))
			if i == 1 or i == 3:   # דלת עץ גדולה
				var dx := hx + hw * 0.5 - 20.0
				DrawBatch.rect(self, Rect2(dx, -74.0, 40.0, 74.0), Color("2a1e18"))
				DrawBatch.line(self, Vector2(dx + 20.0, -74.0), Vector2(dx + 20.0, 0.0), Color("1a120e"), 2.0)
		# מרפסת ברזל (הקומה)
		var by := -tier
		DrawBatch.rect(self, Rect2(balcony.x, by, balcony.y - balcony.x, 10.0), Color("3a3c46"))
		DrawBatch.rect(self, Rect2(balcony.x, by, balcony.y - balcony.x, 2.0), Color(0.7, 0.78, 0.9, 0.5))
		for q in int((balcony.y - balcony.x) / 14.0) + 1:
			var px := balcony.x + float(q) * 14.0
			DrawBatch.line(self, Vector2(px, by), Vector2(px, by - 30.0), Color("1c1e26"), 2.0)
			if q % 2 == 0:
				DrawBatch.arc(self, Vector2(px + 7.0, by - 22.0), 6.0, PI, TAU, 6, Color("1c1e26"), 1.4)
		DrawBatch.line(self, Vector2(balcony.x, by - 30.0), Vector2(balcony.y, by - 30.0), Color("2a2c36"), 3.0)
		for q in 3:   # קונזולות
			var cx := lerpf(balcony.x + 20.0, balcony.y - 20.0, float(q) / 2.0)
			DrawBatch.colored_polygon(self, PackedVector2Array([Vector2(cx - 6, by + 10), Vector2(cx + 6, by + 10), Vector2(cx, by + 30)]), Color("2a2c36"))
		# שלט העיר + דגל קרוע
		DrawBatch.rect(self, Rect2(250.0, -112.0, 190.0, 24.0), Color("1e3a6a"))
		DrawBatch.rect(self, Rect2(250.0, -112.0, 190.0, 24.0), Color("d8dce4"), false, 1.5)
		DrawBatch.string(self, ThemeDB.fallback_font, Vector2(258.0, -94.0), "CARMEN DE PATAGONES", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("e8ecf2"))
		var fx := 1180.0
		DrawBatch.line(self, Vector2(fx, -130.0), Vector2(fx, -230.0), Color("2a2c34"), 2.5)
		for s in 3:
			var pts := PackedVector2Array()
			for k in 7:
				var xx := float(k) * 9.0
				pts.append(Vector2(fx + xx, -228.0 + float(s) * 7.0 + sin(_t * 6.0 + xx * 0.2) * 3.0 * (xx / 54.0)))
			DrawBatch.polyline(self, pts, Color(0.5, 0.7, 0.9) if s != 1 else Color(0.92, 0.92, 0.9), 7.0)
		# שקי חול ומחסום פינוי ישן
		for q in 7:
			DrawBatch.colored_polygon(self, Art.ellipse(Vector2(1400.0 + float(q % 4) * 22.0 + float(q / 4) * 11.0, -8.0 - float(q / 4) * 13.0), 13.0, 7.0, 0.0, 12), Color("6a6248").darkened(0.1 * float(q % 3)))


# ---- עמוד האבן בכניסה לגשר ----
class BridgePortal extends Node2D:
	var _t := 0.0

	func _ready() -> void:
		z_index = -2

	func _process(delta: float) -> void:
		_t += delta
		if Engine.get_process_frames() % 5 == 0 and Art.on_screen(self, global_position + Vector2(0, -150), 300.0):
			queue_redraw()

	func _draw() -> void:
		DrawBatch.begin(self)
		_draw_b()
		DrawBatch.end(self)

	func _draw_b() -> void:
		var stone := Color("4c4a54")
		DrawBatch.rect(self, Rect2(-150.0, -300.0, 110.0, 300.0), stone)
		for q in 12:   # שורות אבן
			DrawBatch.line(self, Vector2(-150.0, -300.0 + float(q) * 25.0), Vector2(-40.0, -300.0 + float(q) * 25.0), stone.darkened(0.3), 1.5)
			DrawBatch.line(self, Vector2(-150.0 + float(q % 2) * 30.0 + 25.0, -300.0 + float(q) * 25.0), Vector2(-150.0 + float(q % 2) * 30.0 + 25.0, -275.0 + float(q) * 25.0), stone.darkened(0.3), 1.2)
		DrawBatch.rect(self, Rect2(-160.0, -316.0, 130.0, 18.0), stone.lightened(0.1))
		DrawBatch.rect(self, Rect2(-150.0, -300.0, 3.0, 300.0), Color(0.75, 0.8, 0.95, 0.3))
		DrawBatch.rect(self, Rect2(-138.0, -200.0, 86.0, 46.0), Color("6a5a3a"))   # לוח ברונזה
		DrawBatch.rect(self, Rect2(-138.0, -200.0, 86.0, 46.0), Color("a8905a"), false, 2.0)
		DrawBatch.string(self, ThemeDB.fallback_font, Vector2(-132.0, -182.0), "PUENTE", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("d8c890"))
		DrawBatch.string(self, ThemeDB.fallback_font, Vector2(-122.0, -162.0), "1931", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("e8d8a0"))
		# קורת הפורטל מעל הכביש עם שלט
		_s54_beam(Vector2(-40.0, -TRUSS_H - 20.0), Vector2(240.0, -TRUSS_H - 20.0))
		_s54_beam(Vector2(-40.0, -4.0), Vector2(-40.0, -TRUSS_H - 20.0))
		DrawBatch.rect(self, Rect2(10.0, -TRUSS_H - 8.0, 170.0, 30.0), Color("1e5a3a"))
		DrawBatch.rect(self, Rect2(10.0, -TRUSS_H - 8.0, 170.0, 30.0), Color("e0e4e0"), false, 1.5)
		DrawBatch.string(self, ThemeDB.fallback_font, Vector2(20.0, -TRUSS_H + 12.0), "VIEDMA  ->  RUTA 3", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("f0f2f0"))
		# לוח עץ של הצבא עם כתובת ריסוס
		DrawBatch.colored_polygon(self, PackedVector2Array([Vector2(-36, 0), Vector2(-28, -96), Vector2(70, -90), Vector2(66, 0)]), Color("5a4a36"))
		for q in 4:
			DrawBatch.line(self, Vector2(-34, -float(q) * 24.0), Vector2(68, -float(q) * 24.0 - 2.0), Color("3a3024"), 1.4)
		DrawBatch.string(self, ThemeDB.fallback_font, Vector2(-24.0, -64.0), "LAST", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("c82a20"))
		DrawBatch.string(self, ThemeDB.fallback_font, Vector2(-24.0, -42.0), "BRIDGE", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("c82a20"))
		DrawBatch.string(self, ThemeDB.fallback_font, Vector2(-24.0, -20.0), "BLOW IT", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("e8e0d0"))
		var bl := 0.6 + 0.4 * sin(_t * 3.0)
		Art.glow(self, Vector2(-95.0, -330.0), 30.0, Color(1.0, 0.25, 0.15, 0.4 * bl))   # אור אזהרה על העמוד
		DrawBatch.circle(self, Vector2(-95.0, -330.0), 4.0, Color(1.0, 0.35, 0.25, bl))

	func _s54_beam(a: Vector2, b: Vector2) -> void:
		DrawBatch.line(self, a, b, IRON_D, 22.0)
		DrawBatch.line(self, a, b, IRON, 16.0)
		var d := (b - a).normalized()
		for q in int(a.distance_to(b) / 14.0):
			DrawBatch.circle(self, a + d * (7.0 + float(q) * 14.0) + d.orthogonal() * 5.0, 1.4, RIVET)


# ============================================================
#  מטען חבלה: עומדים לידו ARM_T שניות (ההתקדמות נשמרת) -> דרוך, מהבהב אדום ומצפצף
# ============================================================
class ChargePoint extends Node2D:
	const ARM_T := 1.5
	const ARM_R := 100.0
	const BLINK := 1.1
	var idx := 0
	var armed := false
	var progress := 0.0
	var stage: Node = null
	var arms := 0                   # לבדיקות
	var blown := false
	var _t := 0.0
	var _beep := 0.0
	var _tick := 0.0
	var _near := false
	var _fast := 0.0                # (סצנת סיפור) מהבהב מהר

	func _ready() -> void:
		z_index = -1
		add_to_group("s54_charges")
		add_to_group("s11_lights")

	func light() -> float:   # (s11 NightOverlay) הבהוב אדום קטן
		if not armed or blown:
			return 0.0
		return 0.4 if fmod(_t, BLINK if _fast <= 0.0 else 0.2) < 0.16 else 0.0

	func arm_now(quiet := false) -> void:
		if armed:
			return
		armed = true
		progress = ARM_T
		arms += 1
		_beep = 0.3
		if not quiet:
			Sfx.play("b54_arm", global_position + Vector2(0, -70), 2.0, 0.0, 2)
		if stage != null and stage.has_method("on_charge_armed"):
			stage.on_charge_armed(self, quiet)
		queue_redraw()

	func beep_fast(t: float) -> void:
		_fast = t

	func _physics_process(delta: float) -> void:
		_t += delta
		_fast -= delta
		_near = false
		if armed:
			_beep -= delta
			if _beep <= 0.0 and not blown:
				_beep = BLINK if _fast <= 0.0 else 0.2
				if Art.on_screen(self, global_position, 200.0):
					Sfx.play("b54_beep", global_position + Vector2(0, -70), -6.0, 0.0, 2)
		else:
			var pl := get_tree().get_first_node_in_group("player") as Node2D
			if pl != null and not pl.dead and absf(pl.global_position.x - global_position.x) < ARM_R and absf(pl.global_position.y - global_position.y) < 40.0:
				_near = true
				progress += delta
				_tick -= delta
				if _tick <= 0.0:
					_tick = 0.25
					Sfx.play("b54_tick", global_position + Vector2(0, -70), -2.0, 0.0, 2, 1.0 + progress / ARM_T * 0.6)
				if progress >= ARM_T:
					arm_now()
		if Art.on_screen(self, global_position + Vector2(0, -60), 220.0):
			queue_redraw()

	func _draw() -> void:
		DrawBatch.begin(self)
		_draw_b()
		DrawBatch.end(self)

	func _draw_b() -> void:
		var y0 := -112.0
		# חבילת חומר נפץ קשורה לעמוד המסבך
		for q in 3:
			var r := Rect2(-16.0, y0 + float(q) * 16.0, 32.0, 14.0)
			DrawBatch.rect(self, r, OLIVE.darkened(0.08 * float(q)))
			DrawBatch.rect(self, Rect2(r.position, Vector2(r.size.x, 2.0)), OLIVE.lightened(0.2))
			DrawBatch.rect(self, r, OLIVE_D, false, 1.2)
		for q in 2:   # סרט דביק
			DrawBatch.rect(self, Rect2(-18.0, y0 + 10.0 + float(q) * 22.0, 36.0, 4.0), Color("2a2a2a"))
		DrawBatch.rect(self, Rect2(-10.0, y0 - 14.0, 20.0, 12.0), Color("2a2e30"))   # נפץ
		DrawBatch.string(self, ThemeDB.fallback_font, Vector2(-14.0, y0 + 30.0), "TNT", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.95, 0.92, 0.7, 0.85))
		# חוטים שיורדים לכביש ונמשכים דרומה (ימינה)
		var wires := PackedVector2Array([Vector2(6, y0 + 48.0), Vector2(10, -30), Vector2(18, -4), Vector2(140, -3), Vector2(160, -2)])
		DrawBatch.polyline(self, wires, Color("a02a20"), 1.6)
		DrawBatch.polyline(self, wires, Color(1, 1, 1, 0.2), 0.6)
		var led := Vector2(0, y0 - 8.0)
		if armed and not blown:
			var on := fmod(_t, BLINK if _fast <= 0.0 else 0.2) < 0.16
			DrawBatch.circle(self, led, 3.5, Color(1.0, 0.15, 0.1) if on else Color(0.35, 0.05, 0.05))
			if on:
				Art.glow(self, led, 38.0, Color(1.0, 0.15, 0.1, 0.55))
				Art.glow(self, Vector2(0, y0 + 24.0), 60.0, Color(1.0, 0.12, 0.08, 0.15))
		elif not blown:
			DrawBatch.circle(self, led, 3.0, Color(0.45, 0.5, 0.3))
			# אזור הדריכה על הכביש: טבעת מנוקדת + קשת התקדמות
			var pulse := 0.5 + 0.5 * sin(_t * 4.0)
			var ring := Art.ellipse(Vector2(0, -2), ARM_R * 0.7, 9.0, 0.0, 28)
			for q in 14:
				DrawBatch.line(self, ring[q * 2], ring[(q * 2 + 1) % 28], Color(1.0, 0.85, 0.3, 0.35 + 0.35 * pulse), 2.0)
			var k := progress / ARM_T
			if k > 0.0:
				DrawBatch.arc(self, Vector2(0, y0 + 18.0), 30.0, -PI * 0.5, -PI * 0.5 + TAU * k, 32, Color(1.0, 0.85, 0.3, 0.9), 4.0)
			DrawBatch.arc(self, Vector2(0, y0 + 18.0), 30.0, 0.0, TAU, 32, Color(1.0, 0.85, 0.3, 0.25), 1.5)
			var label := "HOLD" if _near else "ARM"
			DrawBatch.string(self, ThemeDB.fallback_font, Vector2(-40.0, y0 - 26.0), label, HORIZONTAL_ALIGNMENT_CENTER, 80, 16, Color(1.0, 0.88, 0.4, 0.75 + 0.25 * pulse))


# ============================================================
#  מחסום הצבא בכניסה לזירה: סגור (קיר) עד שכל המטענים דרוכים
# ============================================================
class Roadblock extends Node2D:
	const H := 760.0
	var need := 4
	var armed := 0
	var is_open := false
	var opens := 0                  # לבדיקות
	var hints := 0
	var _k := 0.0                   # 0 = סגור, 1 = פתוח (אנימציה)
	var _t := 0.0
	var _hint_cd := 0.0
	var _shape: CollisionShape2D

	func _ready() -> void:
		z_index = -1
		var body := StaticBody2D.new()
		body.collision_layer = 1
		body.collision_mask = 0
		body.add_to_group("no_outline")
		_shape = CollisionShape2D.new()
		var sh := RectangleShape2D.new()
		sh.size = Vector2(40.0, H)
		_shape.shape = sh
		_shape.position = Vector2(0, -H * 0.5)
		body.add_child(_shape)
		add_child(body)

	func set_open(v: bool) -> void:
		if is_open == v:
			return
		is_open = v
		_shape.set_deferred("disabled", v)
		if v:
			opens += 1
			Sfx.play("b54_brake", global_position + Vector2(0, -80), 2.0)

	func _physics_process(delta: float) -> void:
		_t += delta
		_hint_cd -= delta
		_k = move_toward(_k, 1.0 if is_open else 0.0, delta * 0.8)
		if not is_open and _hint_cd <= 0.0:
			var pl := get_tree().get_first_node_in_group("player") as Node2D
			if pl != null and pl.global_position.x > global_position.x - 170.0 and pl.global_position.x < global_position.x:
				_hint_cd = 2.6
				hints += 1
				Sfx.play("b54_beep", global_position + Vector2(0, -90), 0.0)
				var tx = preload("res://zombie.gd").HitText.new()
				tx.text = "ARM ALL CHARGES  %d/%d" % [armed, need]
				tx.color = Color("ffd34a")
				tx.size = 18
				tx.life = 2.2
				get_parent().add_child(tx)
				tx.global_position = global_position + Vector2(-60, -190)
		if Art.on_screen(self, global_position + Vector2(0, -150), 300.0):
			queue_redraw()

	func _draw() -> void:
		DrawBatch.begin(self)
		_draw_b()
		DrawBatch.end(self)

	func _draw_b() -> void:
		# גדר רשת עד הקורה העליונה (מחליקה הצידה כשנפתח)
		var fx := -26.0 + _k * 120.0
		var fa := 1.0 - _k * 0.7
		var fr := Rect2(fx - 22.0, -TRUSS_H + 6.0, 44.0, TRUSS_H - 50.0)
		DrawBatch.rect(self, fr, Color(0.1, 0.12, 0.16, 0.35 * fa))
		for q in 9:
			DrawBatch.line(self, fr.position + Vector2(float(q) * 5.5, 0), fr.position + Vector2(float(q) * 5.5 + 20.0, fr.size.y), Color(0.6, 0.66, 0.76, 0.5 * fa), 1.0)
			DrawBatch.line(self, fr.position + Vector2(float(q) * 5.5 + 20.0, 0), fr.position + Vector2(float(q) * 5.5, fr.size.y), Color(0.6, 0.66, 0.76, 0.5 * fa), 1.0)
		DrawBatch.rect(self, fr, Color(0.5, 0.56, 0.66, fa), false, 2.0)
		for q in 6:   # תיל דוקרני למעלה
			DrawBatch.arc(self, Vector2(fx - 18.0 + float(q) * 7.0, fr.position.y - 4.0), 6.0, 0.0, TAU, 8, Color(0.7, 0.74, 0.8, 0.7 * fa), 1.0)
		# בלוקי בטון עם פסים אדומים-לבנים
		for s: float in [-1.0, 1.0]:
			var bx := s * 34.0 - 22.0
			DrawBatch.colored_polygon(self, PackedVector2Array([Vector2(bx, 0), Vector2(bx + 6, -44), Vector2(bx + 38, -44), Vector2(bx + 44, 0)]), Color("8a8a86"))
			for q in 3:
				DrawBatch.rect(self, Rect2(bx + 8.0 + float(q) * 10.0, -34.0, 5.0, 22.0), Color("b02a22"))
		# זרוע מחסום שמתרוממת
		var piv := Vector2(-60.0, -54.0)
		var ang := -lerpf(0.0, PI * 0.45, _k)
		var tip := piv + Vector2.from_angle(ang) * 150.0
		DrawBatch.rect(self, Rect2(piv + Vector2(-10, 0), Vector2(20, 54)), Color("3a3e46"))
		DrawBatch.line(self, piv, tip, Color("e8e4dc"), 8.0)
		for q in 5:
			var a2 := piv.lerp(tip, float(q * 2 + 1) / 10.0)
			var b2 := piv.lerp(tip, float(q * 2 + 2) / 10.0)
			DrawBatch.line(self, a2, b2, Color("c02a20"), 8.0)
		# שלט + 4 נורות מטענים
		var sp := Vector2(-110.0, -150.0)
		DrawBatch.rect(self, Rect2(sp, Vector2(120, 46)), Color("1a1c20"))
		DrawBatch.rect(self, Rect2(sp, Vector2(120, 46)), Color("d8c040"), false, 2.0)
		DrawBatch.string(self, ThemeDB.fallback_font, sp + Vector2(6, 16), "DEMOLITION", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("e8d050"))
		for q in need:
			var on := q < armed
			var lc := Vector2(sp.x + 18.0 + float(q) * 28.0, sp.y + 32.0)
			DrawBatch.circle(self, lc, 6.0, Color(1.0, 0.2, 0.12) if on else Color(0.25, 0.25, 0.25))
			if on and fmod(_t + float(q) * 0.2, 1.1) < 0.3:
				Art.glow(self, lc, 20.0, Color(1.0, 0.2, 0.1, 0.5))
		if is_open:
			DrawBatch.string(self, ThemeDB.fallback_font, sp + Vector2(16, -8), "OPEN", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.5, 1.0, 0.5, 0.9))


# ============================================================
#  לוחות סדוקים שנופלים לנהר (מלכודת)
# ============================================================
class BrokenDeck extends Node2D:
	const W := 150.0
	const WARN_T := 0.75
	const FALL_T := 0.9
	const HEAVY := 3                # כמה זומבים עליו מפילים אותו
	const DMG := 1
	var state := 0                  # 0 = שלם (סדוק), 1 = חורק, 2 = נופל, 3 = חור
	var falls := 0                  # לבדיקות
	var drops := 0
	var hits := 0
	var _t := 0.0
	var _tt := 0.0
	var _plates := []               # [מיקום, מהירות, זווית, סיבוב, רוחב]
	var _said := false

	func _ready() -> void:
		z_index = 2
		add_to_group("hazards")

	func world_rect() -> Rect2:
		return Rect2(global_position + Vector2(-W * 0.5, -60.0), Vector2(W, 60.0))

	func danger_at(p: Vector2, margin := 0.0) -> bool:
		return (state == 1 or state == 2) and world_rect().grow(margin).has_point(p)

	func _on(n: Node2D) -> bool:
		return absf(n.global_position.x - global_position.x) < W * 0.5 - 6.0 and absf(n.global_position.y - global_position.y) < 10.0

	func _start(t: float) -> void:
		state = 1
		_t = t
		Sfx.play("b54_creak", global_position, 3.0, 0.1, 2)

	func _physics_process(delta: float) -> void:
		_t -= delta
		_tt += delta
		var pl := get_tree().get_first_node_in_group("player") as Node2D
		match state:
			0:
				if pl != null and not pl.dead and _on(pl) and pl.is_on_floor():
					_start(WARN_T)
				elif Engine.get_physics_frames() % 10 == 0:
					var n := 0
					for z in get_tree().get_nodes_in_group("zombies"):
						if not z.dead and _on(z):
							n += 1
					if n >= HEAVY:
						_start(WARN_T * 0.6)
			1:
				if Engine.get_physics_frames() % 4 == 0:
					Particles.burst(get_parent(), global_position + Vector2(randf_range(-W * 0.4, W * 0.4), 14.0), "smoke", Vector2.DOWN, 1)
				if _t <= 0.0:
					state = 2
					_t = FALL_T
					falls += 1
					Sfx.play("b54_crash", global_position, 3.0, 0.1, 2)
					for q in 4:
						_plates.append([Vector2(-W * 0.5 + (float(q) + 0.5) * W / 4.0, 4.0), Vector2(randf_range(-40, 40), randf_range(-60, 20)), 0.0, randf_range(-3.0, 3.0), W / 4.0 - 2.0])
					if pl != null and not pl.dead and _on(pl):
						hits += 1
						pl.hurt(DMG, Vector2(0.0, -0.5))
						pl.velocity.y = -430.0   # תופס את הקורה וקופץ למעלה
						pl.slow_t = maxf(pl.slow_t, 0.8)
					for z in get_tree().get_nodes_in_group("zombies"):
						if not z.dead and not z.is_boss() and _on(z):
							_drop(z)
			2:
				for p in _plates:
					p[1].y += 900.0 * delta
					p[0] += p[1] * delta
					p[2] += p[3] * delta
				if _t <= 0.0:
					state = 3
					_plates.clear()
					Sfx.play("splash", global_position + Vector2(0, 80), 4.0)
					Particles.burst(get_parent(), global_position + Vector2(0, 70), "drop", Vector2.UP, 16)
			3:
				if Engine.get_physics_frames() % 3 == 0:
					for z in get_tree().get_nodes_in_group("zombies"):
						if not z.dead and not z.is_boss() and _on(z) and z.is_on_floor():
							_drop(z)
		if state != 0 or Engine.get_physics_frames() % 20 == 0:
			if Art.on_screen(self, global_position, W + 100.0):
				queue_redraw()

	func _drop(z: Node) -> void:
		drops += 1
		z.take_damage(9999, z.global_position + Vector2(0, -20), Vector2.DOWN, false, {"source": "hazard", "fixed": 9999})
		Sfx.play("splash", z.global_position + Vector2(0, 80), 2.0, 0.1, 3)
		Particles.burst(get_parent(), Vector2(z.global_position.x, global_position.y + 70.0), "drop", Vector2.UP, 12)
		Particles.burst(get_parent(), Vector2(z.global_position.x, global_position.y + 60.0), "mist", Vector2.UP, 4)
		if not _said:
			_said = true
			z._popup("INTO THE RIVER", Color("a8d8ff"), 16, -90.0)

	func _draw() -> void:
		DrawBatch.begin(self)
		_draw_b()
		DrawBatch.end(self)

	func _draw_b() -> void:
		var hw := W * 0.5
		if state <= 1:
			var sag := (sin(_tt * 40.0) * 1.5 + 2.0) if state == 1 else 0.0
			DrawBatch.rect(self, Rect2(-hw, 0.0 + sag * 0.5, W, 11.0), Color("2a2c32"))
			for q in 4:   # לוחות ברזל עם חלודה במקום אספלט
				var px := -hw + float(q) * W / 4.0
				DrawBatch.rect(self, Rect2(px + 1.0, sag * (0.5 + 0.5 * sin(float(q))), W / 4.0 - 2.0, 9.0), Color("4a3a30").lerp(Color("5a4a3a"), float(q % 2) * 0.5))
				DrawBatch.rect(self, Rect2(px + 1.0, sag * (0.5 + 0.5 * sin(float(q))), W / 4.0 - 2.0, 1.5), Color(0.75, 0.6, 0.45, 0.6))
				DrawBatch.circle(self, Vector2(px + 8.0, 4.0), 1.5, Color("8a7a6a"))
				DrawBatch.circle(self, Vector2(px + W / 4.0 - 8.0, 4.0), 1.5, Color("8a7a6a"))
			DrawBatch.polyline(self, PackedVector2Array([Vector2(-hw + 20, 1), Vector2(-hw + 34, 6), Vector2(-hw + 30, 10)]), Color(0.05, 0.05, 0.06), 1.4)
			DrawBatch.polyline(self, PackedVector2Array([Vector2(10, 1), Vector2(4, 5), Vector2(14, 10)]), Color(0.05, 0.05, 0.06), 1.4)
			# שלט אזהרה קטן של הצבא
			DrawBatch.line(self, Vector2(hw - 8.0, 0.0), Vector2(hw - 8.0, -36.0), Color("2a2c30"), 2.0)
			DrawBatch.colored_polygon(self, PackedVector2Array([Vector2(hw - 20, -36), Vector2(hw - 8, -56), Vector2(hw + 4, -36)]), Color("e0b020"))
			DrawBatch.string(self, ThemeDB.fallback_font, Vector2(hw - 11.0, -39.0), "!", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("1a1a1a"))
			if state == 1:
				DrawBatch.string(self, ThemeDB.fallback_font, Vector2(-8.0, -40.0), "!", HORIZONTAL_ALIGNMENT_LEFT, -1, 26, Color(1.0, 0.5, 0.2, 0.6 + 0.4 * sin(_tt * 30.0)))
		else:
			# חור: רואים את הנהר הרחק למטה, ונשארה רק הקורה הצרה שעוברים עליה
			DrawBatch.rect(self, Rect2(-hw, 0.0, W, 90.0), Color("060b16"))
			DrawBatch.rect(self, Rect2(-hw, 60.0, W, 30.0), Color("0e1c34"))
			for q in 5:
				var gx := -hw + fposmod(float(q) * 37.0 + _tt * 10.0, W)
				DrawBatch.line(self, Vector2(gx, 70.0 + float(q % 3) * 6.0), Vector2(gx + 14.0, 70.0 + float(q % 3) * 6.0), Color(0.7, 0.8, 1.0, 0.3), 1.2)
			DrawBatch.rect(self, Rect2(-hw - 2.0, 0.0, W + 4.0, 5.0), Color("4a5262"))   # הקורה
			DrawBatch.rect(self, Rect2(-hw - 2.0, 0.0, W + 4.0, 1.5), Color(0.7, 0.78, 0.92, 0.7))
			DrawBatch.rect(self, Rect2(-hw - 2.0, 5.0, W + 4.0, 3.0), Color("262c38"))
			for s: float in [-1.0, 1.0]:   # שולי האספלט השבורים
				var ex := s * hw
				DrawBatch.colored_polygon(self, PackedVector2Array([Vector2(ex, 0), Vector2(ex - s * 10.0, 2), Vector2(ex - s * 4.0, 7), Vector2(ex - s * 12.0, 11), Vector2(ex, 11)]), ASPHALT)
				DrawBatch.line(self, Vector2(ex - s * 6.0, 11.0), Vector2(ex - s * 14.0, 40.0), Color("6a4a30"), 2.0)   # ברזל זיון תלוי
			for p in _plates:
				var c: Vector2 = p[0]
				var hwp: float = p[4] * 0.5
				DrawBatch.set_transform(self, c, p[2], Vector2.ONE)
				DrawBatch.rect(self, Rect2(-hwp, -5.0, hwp * 2.0, 10.0), Color("4a3a30"))
				DrawBatch.rect(self, Rect2(-hwp, -5.0, hwp * 2.0, 2.0), Color(0.75, 0.6, 0.45, 0.6))
				DrawBatch.set_transform(self, Vector2.ZERO, 0.0, Vector2.ONE)


# ============================================================
#  משאית צבא נטושה: יורים בבלם -> מתגלגלת קדימה, דורסת, מתרסקת ומתפוצצת
# ============================================================
class RollingTruck extends Node2D:
	const ROLL_DIST := 540.0
	const MAX_V := 360.0
	const ACC := 280.0
	const CRUSH := 160
	const DMG := 1
	const BOOM_R := 150.0
	const W := 210.0
	var rolled := false             # לבדיקות
	var crushed := 0
	var player_hits := 0
	var blown := false
	var _x := 0.0
	var _v := 0.0
	var _wheel := 0.0
	var _hit_cd := 0.0
	var _t := 0.0
	var _hit := {}

	class Brake extends StaticBody2D:
		var tr = null
		func hit_by_bullet(_p: Vector2, _n: Vector2, _d: Vector2) -> void:
			if tr != null:
				tr.release()

	func _ready() -> void:
		z_index = -1
		var b := Brake.new()
		b.tr = self
		b.collision_layer = 4
		b.collision_mask = 0
		var cs := CollisionShape2D.new()
		var sh := RectangleShape2D.new()
		sh.size = Vector2(30, 26)
		cs.shape = sh
		cs.position = Vector2(-W * 0.5 + 18.0, -24.0)   # תוף הבלם האחורי + נורה אדומה
		b.add_child(cs)
		add_child(b)

	func release() -> void:
		if rolled or blown:
			return
		rolled = true
		Sfx.play("b54_brake", global_position + Vector2(0, -40), 4.0)
		Sfx.play("b54_creak", global_position, 2.0, 0.1, 2, 0.7)
		var tx = preload("res://zombie.gd").HitText.new()
		tx.text = "BRAKES OFF!"
		tx.color = Color("ffb03a")
		tx.size = 18
		get_parent().add_child(tx)
		tx.global_position = global_position + Vector2(0, -130)

	func _physics_process(delta: float) -> void:
		_t += delta
		_hit_cd -= delta
		if rolled and not blown:
			_v = minf(MAX_V, _v + ACC * delta)
			var step := _v * delta
			_x += step
			position.x += step
			_wheel += step / 18.0
			var front := global_position.x + W * 0.5
			for z in get_tree().get_nodes_in_group("zombies"):
				if z.dead or _hit.has(z) or z.is_boss():
					continue
				var zx: float = z.global_position.x
				if zx > front - W and zx < front + 16.0 and absf(z.global_position.y - global_position.y) < 90.0:
					_hit[z] = true
					crushed += 1
					z.take_damage(CRUSH, z.global_position + Vector2(0, -30), Vector2(1.0, -0.3), true, {"source": "hazard", "fixed": CRUSH})
			var pl := get_tree().get_first_node_in_group("player") as Node2D
			if pl != null and not pl.dead and _hit_cd <= 0.0 and Rect2(global_position + Vector2(-W * 0.5, -96.0), Vector2(W, 96.0)).intersects(pl.body_rect()):
				_hit_cd = 0.8
				player_hits += 1
				pl.hurt(DMG, Vector2(1.0, -0.4))
			if Engine.get_physics_frames() % 3 == 0:
				Particles.burst(get_parent(), global_position + Vector2(-W * 0.4, -6.0), "smoke", Vector2(-1, -0.3), 1)
			if _x >= ROLL_DIST:
				_crash()
		if Art.on_screen(self, global_position + Vector2(0, -50), W + 60.0):
			queue_redraw()

	func _crash() -> void:
		blown = true
		var c := global_position + Vector2(W * 0.4, -40.0)
		Boom.blast(get_parent(), c, BOOM_R, 80.0, 70, 1, "truck")
		Particles.burst(get_parent(), c, "fire", Vector2.UP, 24)
		for q in 2:   # שרידים בוערים
			var f = FireScript.new()
			f.width = 30.0
			f.height = 34.0
			get_parent().add_child(f)
			f.global_position = global_position + Vector2(-40.0 + float(q) * 90.0, 0.0)

	func _draw() -> void:
		DrawBatch.begin(self)
		_draw_b()
		DrawBatch.end(self)

	func _draw_b() -> void:
		var hw := W * 0.5
		var burnt := blown
		var body := Color("1e201a") if burnt else OLIVE
		var dark := Color("121410") if burnt else OLIVE_D
		# שלדה
		DrawBatch.rect(self, Rect2(-hw + 6.0, -34.0, W - 12.0, 10.0), Color("1a1c1e"))
		# ארגז עם ברזנט וקשתות
		var tarp := Color("26281c") if burnt else Color("5a6038")
		DrawBatch.rect(self, Rect2(-hw, -100.0, W * 0.64, 66.0), tarp)
		for q in 4:
			var tx := -hw + 10.0 + float(q) * W * 0.17
			DrawBatch.line(self, Vector2(tx, -100.0), Vector2(tx, -36.0), tarp.darkened(0.25), 2.0)
		DrawBatch.rect(self, Rect2(-hw, -100.0, W * 0.64, 3.0), Color(0.7, 0.75, 0.85, 0.3))
		if not burnt:
			DrawBatch.string(self, ThemeDB.fallback_font, Vector2(-hw + 30.0, -60.0), "EA  21-B", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.85, 0.85, 0.75, 0.7))
		else:   # חורים שרופים בברזנט
			for q in 4:
				DrawBatch.colored_polygon(self, Art.ellipse(Vector2(-hw + 20.0 + float(q) * 30.0, -80.0 + float(q % 2) * 18.0), 10.0, 7.0, 0.3, 10), Color("0a0a0a"))
		# תא נהג
		var cx := -hw + W * 0.66
		DrawBatch.colored_polygon(self, PackedVector2Array([Vector2(cx, -34), Vector2(cx, -92), Vector2(cx + 40, -92), Vector2(cx + 54, -64), Vector2(hw, -60), Vector2(hw, -34)]), body)
		DrawBatch.colored_polygon(self, PackedVector2Array([Vector2(cx + 6, -86), Vector2(cx + 36, -86), Vector2(cx + 46, -66), Vector2(cx + 6, -66)]), Color("0e1218") if not burnt else Color("050505"))
		DrawBatch.line(self, Vector2(cx + 10, -84), Vector2(cx + 30, -70), Color(0.7, 0.8, 1.0, 0.25), 2.0)   # השתקפות ירח בחלון
		DrawBatch.rect(self, Rect2(hw - 8.0, -58.0, 8.0, 22.0), dark)   # גריל
		DrawBatch.circle(self, Vector2(hw - 4.0, -50.0), 4.0, Color("b0a880") if not burnt else Color("222"))
		DrawBatch.rect(self, Rect2(hw - 4.0, -36.0, 12.0, 6.0), Color("2a2c2e"))   # פגוש
		if not burnt:   # קסדה על מכסה המנוע
			DrawBatch.arc(self, Vector2(hw - 26.0, -62.0), 8.0, PI, TAU, 10, Color("3a4228"), 5.0)
		# גלגלים מסתובבים
		for wx: float in [-hw + 34.0, -hw + 74.0, hw - 36.0]:
			var wc := Vector2(wx, -15.0)
			DrawBatch.circle(self, wc, 16.0, Color("121212"))
			DrawBatch.circle(self, wc, 8.0, dark.lightened(0.1))
			for q in 5:
				DrawBatch.line(self, wc, wc + Vector2.from_angle(_wheel + float(q) / 5.0 * TAU) * 7.0, Color("0a0a0a"), 2.0)
		# הבלם: נורה אדומה מהבהבת = "תירה בי"
		if not rolled and not burnt:
			var bp := Vector2(-hw + 18.0, -24.0)
			var on := fmod(_t, 1.0) < 0.5
			DrawBatch.rect(self, Rect2(bp - Vector2(10, 8), Vector2(20, 16)), Color("4a1a14"))
			DrawBatch.circle(self, bp, 4.0, Color(1.0, 0.2, 0.1) if on else Color(0.4, 0.08, 0.05))
			if on:
				Art.glow(self, bp, 26.0, Color(1.0, 0.2, 0.1, 0.5))


# ============================================================
#  כבל חשמל קרוע: מזמזם ואז פורק קשת לכביש (פוגע בך ובזומבים, קופץ לזומבי הבא)
# ============================================================
class LiveCable extends Node2D:
	const CD := 3.2
	const WARN_T := 0.8
	const ARC_T := 0.45
	const ARC_R := 75.0
	const CHAIN_R := 170.0
	const DMG := 1
	const DMG_Z := 45
	var state := 0                  # 0 = שקט, 1 = מזמזם, 2 = קשת
	var arcs := 0                   # לבדיקות
	var hits := 0
	var zapped := 0
	var _t := 1.0
	var _tt := 0.0
	var _chain: Array = []          # נקודות של קשתות שקפצו לזומבים
	var _seed := 0

	func _ready() -> void:
		z_index = 3
		add_to_group("hazards")
		add_to_group("s11_lights")
		_t = randf_range(0.5, CD)

	func light() -> float:
		return 0.9 if state == 2 else (0.25 if state == 1 else 0.0)

	func end_pos() -> Vector2:   # (מקומי) קצה הכבל המתנדנד
		return Vector2(sin(_tt * 1.3) * 22.0, -46.0 + sin(_tt * 2.1) * 3.0)

	func world_rect() -> Rect2:
		return Rect2(global_position + Vector2(-ARC_R, -80.0), Vector2(ARC_R * 2.0, 80.0))

	func danger_at(p: Vector2, margin := 0.0) -> bool:
		return state >= 1 and world_rect().grow(margin).has_point(p)

	func _physics_process(delta: float) -> void:
		_tt += delta
		_t -= delta
		match state:
			0:
				if _t <= 0.0 and Art.on_screen(self, global_position, 500.0):
					state = 1
					_t = WARN_T
					Sfx.play("b54_buzz", global_position + Vector2(0, -60), 0.0, 0.05, 2)
				elif Engine.get_physics_frames() % 40 == 0 and randf() < 0.4:
					Particles.burst(get_parent(), global_position + end_pos(), "spark", Vector2.DOWN, 3)
			1:
				if Engine.get_physics_frames() % 4 == 0:
					Particles.burst(get_parent(), global_position + end_pos(), "spark", Vector2.DOWN, 2)
				if _t <= 0.0:
					state = 2
					_t = ARC_T
					arcs += 1
					_seed = randi()
					_zap()
			2:
				if Engine.get_physics_frames() % 3 == 0:
					_seed = randi()
				if _t <= 0.0:
					state = 0
					_t = CD
					_chain.clear()
		if state != 0 or Engine.get_physics_frames() % 3 == 0:
			if Art.on_screen(self, global_position + Vector2(0, -100), 200.0):
				queue_redraw()

	func _zap() -> void:
		Sfx.play("b54_zap", global_position + Vector2(0, -20), 3.0, 0.1, 3)
		Particles.burst(get_parent(), global_position + Vector2(end_pos().x, -4.0), "spark", Vector2.UP, 14)
		var strike := global_position + Vector2(end_pos().x, 0.0)
		var pl := get_tree().get_first_node_in_group("player") as Node2D
		if pl != null and not pl.dead and absf(pl.global_position.x - strike.x) < ARC_R and absf(pl.global_position.y - strike.y) < 70.0:
			hits += 1
			pl.hurt(DMG, Vector2(signf(pl.global_position.x - strike.x + 0.01), -0.3))
		var last := strike
		for z in get_tree().get_nodes_in_group("zombies"):
			if z.dead or z.is_boss():
				continue
			if absf(z.global_position.x - strike.x) < ARC_R and absf(z.global_position.y - strike.y) < 70.0:
				zapped += 1
				z.take_damage(DMG_Z, z.global_position + Vector2(0, -30), Vector2.UP, false, {"source": "hazard", "fixed": DMG_Z})
				if not z.dead:
					z.stagger(0.8)
		# קפיצה לזומבי הקרוב הבא
		var best: Node2D = null
		var bd := CHAIN_R
		for z in get_tree().get_nodes_in_group("zombies"):
			if z.dead or z.is_boss():
				continue
			var d: float = z.global_position.distance_to(last)
			if d > ARC_R * 0.8 and d < bd:
				bd = d
				best = z
		if best != null:
			zapped += 1
			_chain.append(to_local(best.global_position + Vector2(0, -30)))
			best.take_damage(DMG_Z, best.global_position + Vector2(0, -30), Vector2.UP, false, {"source": "hazard", "fixed": DMG_Z})

	func _bolt(a: Vector2, b: Vector2, r: RandomNumberGenerator, w: float) -> void:
		var pts := PackedVector2Array([a])
		var n := 7
		for q in range(1, n):
			pts.append(a.lerp(b, float(q) / float(n)) + Vector2(r.randf_range(-12.0, 12.0), r.randf_range(-5.0, 5.0)))
		pts.append(b)
		DrawBatch.polyline(self, pts, Color(0.45, 0.65, 1.0, 0.45), w * 3.0)
		DrawBatch.polyline(self, pts, Color(0.92, 0.97, 1.0, 0.95), w)

	func _draw() -> void:
		DrawBatch.begin(self)
		_draw_b()
		DrawBatch.end(self)

	func _draw_b() -> void:
		var anchor := Vector2(-30.0, -TRUSS_H + 10.0)
		var e := end_pos()
		var mid := anchor.lerp(e, 0.5) + Vector2(14.0, 16.0)
		var curve := PackedVector2Array()
		for q in 13:
			var k := float(q) / 12.0
			curve.append(anchor.lerp(mid, k).lerp(mid.lerp(e, k), k))
		DrawBatch.polyline(self, curve, Color("0c0c10"), 4.5)
		DrawBatch.polyline(self, curve, Color(0.5, 0.55, 0.7, 0.35), 1.2)
		DrawBatch.circle(self, e, 4.0, Color("c87a3a"))   # נחושת חשופה
		var hot := 1.0 if state == 2 else (0.6 + 0.4 * sin(_tt * 50.0) if state == 1 else 0.25 + 0.2 * sin(_tt * 7.0))
		Art.glow(self, e, 16.0 + 30.0 * hot, Color(0.55, 0.75, 1.0, 0.35 * hot))
		DrawBatch.colored_polygon(self, Art.ellipse(Vector2(e.x, -1.0), ARC_R * 0.55, 4.0, 0.0, 16), Color(0.05, 0.05, 0.06, 0.6))   # חריכה
		var r := RandomNumberGenerator.new()
		r.seed = _seed + int(_tt * 20.0)
		if state == 1:
			for q in 3:
				_bolt(e, e + Vector2(r.randf_range(-20, 20), r.randf_range(4, 22)), r, 1.0)
		if state == 2:
			_bolt(e, Vector2(e.x + r.randf_range(-10, 10), -2.0), r, 2.2)
			for q in 3:
				_bolt(Vector2(e.x, -2.0), Vector2(e.x + r.randf_range(-ARC_R, ARC_R), -2.0 - r.randf_range(0, 10)), r, 1.0)
			for c: Vector2 in _chain:
				_bolt(Vector2(e.x, -10.0), c, r, 1.4)
			Art.glow(self, Vector2(e.x, -10.0), 90.0, Color(0.6, 0.8, 1.0, 0.35))


# ============================================================
#  מכשולים
# ============================================================
class Obstacle extends Node2D:
	var kind := "jersey"
	var size := Vector2(80, 50)
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
		var rim := Color(0.62, 0.7, 0.86, 0.55)
		match kind:
			"jersey":   # מחסומי בטון עם פסים
				for q in 2:
					var bx := float(q) * w * 0.5
					var c := Color("7a7a78").darkened(0.08 * float(q))
					DrawBatch.colored_polygon(self, PackedVector2Array([Vector2(bx + 1, 0), Vector2(bx + 6, -h * 0.4), Vector2(bx + 10, -h), Vector2(bx + w * 0.5 - 10, -h), Vector2(bx + w * 0.5 - 6, -h * 0.4), Vector2(bx + w * 0.5 - 1, 0)]), c)
					DrawBatch.line(self, Vector2(bx + 10, -h), Vector2(bx + w * 0.5 - 10, -h), rim, 1.5)
					for s in 2:
						DrawBatch.rect(self, Rect2(bx + 12.0 + float(s) * 14.0, -h * 0.7, 6.0, h * 0.35), Color("b8a020") if (q + s) % 2 == 0 else Color("1a1a1a"))
					DrawBatch.string(self, ThemeDB.fallback_font, Vector2(bx + 6.0, -6.0), "EA", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color(0.2, 0.2, 0.2, 0.6))
			"ammo":   # ארגזי תחמושת ירוקים
				var bh := h * 0.5
				for q in 3:
					var r := Rect2(float(q % 2) * w * 0.5, -bh, w * 0.5, bh) if q < 2 else Rect2(w * 0.2, -h, w * 0.55, bh)
					DrawBatch.rect(self, r, OLIVE.darkened(0.05 * float(q)))
					DrawBatch.rect(self, r, OLIVE_D, false, 1.4)
					DrawBatch.rect(self, Rect2(r.position, Vector2(r.size.x, 2.0)), rim)
					DrawBatch.rect(self, Rect2(r.position + Vector2(r.size.x * 0.4, 4.0), Vector2(r.size.x * 0.2, 5.0)), Color("1a1c14"))
					DrawBatch.string(self, ThemeDB.fallback_font, r.position + Vector2(4.0, r.size.y - 6.0), "7.62", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color(0.9, 0.85, 0.5, 0.6))
			"wreck":   # מכונית שרופה
				var c2 := Color("2a2622")
				DrawBatch.colored_polygon(self, PackedVector2Array([Vector2(4, -14), Vector2(4, -h * 0.55), Vector2(w * 0.25, -h * 0.6), Vector2(w * 0.36, -h), Vector2(w * 0.7, -h), Vector2(w * 0.82, -h * 0.6), Vector2(w - 2, -h * 0.5), Vector2(w - 2, -14)]), c2)
				DrawBatch.line(self, Vector2(w * 0.36, -h), Vector2(w * 0.7, -h), rim, 1.4)
				DrawBatch.colored_polygon(self, PackedVector2Array([Vector2(w * 0.4, -h + 5), Vector2(w * 0.66, -h + 5), Vector2(w * 0.76, -h * 0.62), Vector2(w * 0.32, -h * 0.62)]), Color("0a0a0c"))
				for q in 5:   # חלודה
					DrawBatch.circle(self, Vector2(w * (0.15 + 0.16 * float(q)), -h * 0.38), 3.0 + float(q % 3), Color(0.42, 0.2, 0.1, 0.6))
				for wx: float in [w * 0.2, w * 0.8]:
					DrawBatch.circle(self, Vector2(wx, -12.0), 12.0, Color("141210"))
					DrawBatch.circle(self, Vector2(wx, -12.0), 5.0, Color("4a3a2a"))
			_:   # משאית שיירה נטושה
				DrawBatch.rect(self, Rect2(0.0, -h, w * 0.66, h - 22.0), Color("50583a"))
				for q in 4:
					DrawBatch.line(self, Vector2(8.0 + float(q) * w * 0.16, -h), Vector2(8.0 + float(q) * w * 0.16, -24.0), Color("3a4028"), 2.0)
				DrawBatch.rect(self, Rect2(0.0, -h, w * 0.66, 2.0), rim)
				DrawBatch.colored_polygon(self, PackedVector2Array([Vector2(w * 0.68, -22), Vector2(w * 0.68, -h * 0.85), Vector2(w * 0.86, -h * 0.85), Vector2(w, -h * 0.5), Vector2(w, -22)]), OLIVE)
				DrawBatch.rect(self, Rect2(w * 0.71, -h * 0.8, w * 0.13, h * 0.24), Color("0e1218"))
				DrawBatch.rect(self, Rect2(0.0, -26.0, w, 6.0), Color("1a1c1e"))
				for wx: float in [w * 0.16, w * 0.36, w * 0.86]:
					DrawBatch.circle(self, Vector2(wx, -12.0), 13.0, Color("121212"))
					DrawBatch.circle(self, Vector2(wx, -12.0), 6.0, OLIVE_D)


# ---- הגדה הדרומית: ראש הגשר וזירת THE ARCHITECT ----
class SouthBank extends Node2D:
	var _t := 0.0

	func _ready() -> void:
		z_index = -3

	func _process(delta: float) -> void:
		_t += delta
		if Engine.get_process_frames() % 5 == 0 and Art.on_screen(self, global_position + Vector2(500, -150), 700.0):
			queue_redraw()

	func _draw() -> void:
		DrawBatch.begin(self)
		_draw_b()
		DrawBatch.end(self)

	func _draw_b() -> void:
		# ראש הגשר: גוש בטון
		DrawBatch.rect(self, Rect2(-40.0, -60.0, 80.0, 60.0), Color("4a4a52"))
		DrawBatch.rect(self, Rect2(-40.0, -60.0, 80.0, 3.0), Color(0.7, 0.76, 0.9, 0.4))
		# עמדת צבא שרופה
		var px := 220.0
		DrawBatch.rect(self, Rect2(px, -120.0, 120.0, 120.0), Color("2a2a26"))
		DrawBatch.rect(self, Rect2(px - 10.0, -132.0, 140.0, 14.0), Color("3a3a34"))
		DrawBatch.rect(self, Rect2(px + 20.0, -96.0, 40.0, 26.0), Color("0a0a0a"))
		DrawBatch.string(self, ThemeDB.fallback_font, Vector2(px + 8.0, -20.0), "PUESTO SUR", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.8, 0.8, 0.72, 0.6))
		Kit.soft_smoke(self, Vector2(px + 60.0, -134.0), _t, 220.0, Color(0.08, 0.08, 0.1, 0.35), 70.0, 7)
		for q in 9:   # שקי חול
			DrawBatch.colored_polygon(self, Art.ellipse(Vector2(px + 160.0 + float(q % 5) * 22.0 + float(q / 5) * 11.0, -8.0 - float(q / 5) * 13.0), 13.0, 7.0, 0.0, 12), Color("5e5640").darkened(0.08 * float(q % 3)))
		# שלט הדרך דרומה
		var sx := 620.0
		DrawBatch.line(self, Vector2(sx, 0.0), Vector2(sx, -170.0), Color("3a3e44"), 4.0)
		DrawBatch.line(self, Vector2(sx + 120.0, 0.0), Vector2(sx + 120.0, -170.0), Color("3a3e44"), 4.0)
		DrawBatch.rect(self, Rect2(sx - 10.0, -220.0, 140.0, 60.0), Color("1e5a3a"))
		DrawBatch.rect(self, Rect2(sx - 10.0, -220.0, 140.0, 60.0), Color("e0e4e0"), false, 2.0)
		DrawBatch.string(self, ThemeDB.fallback_font, Vector2(sx, -196.0), "PATAGONIA", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("f0f2f0"))
		DrawBatch.string(self, ThemeDB.fallback_font, Vector2(sx, -174.0), "RUTA 3  USHUAIA 3000", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("d0d4d0"))
		DrawBatch.line(self, Vector2(sx - 6.0, -205.0), Vector2(sx + 60.0, -170.0), Color(0.75, 0.1, 0.08, 0.8), 3.0)   # שריטת דם
		# פנס שבור על הגדה, מהבהב
		var lx := 900.0
		DrawBatch.line(self, Vector2(lx, 0.0), Vector2(lx, -190.0), Color("2a2c32"), 4.0)
		DrawBatch.line(self, Vector2(lx, -190.0), Vector2(lx - 24.0, -196.0), Color("2a2c32"), 3.0)
		var on := 1.0 if fmod(_t * 1.7, 3.0) > 0.35 else 0.15
		Art.glow(self, Vector2(lx - 24.0, -192.0), 50.0, Color(0.85, 0.9, 1.0, 0.35 * on))
		DrawBatch.circle(self, Vector2(lx - 24.0, -192.0), 4.0, Color(0.9, 0.95, 1.0, on))


# ============================================================
#  ההתמוטטות: צפצופים מואצים -> פיצוצים לאורך הגשר (מהקצה אחורה) -> לוחות וקורות נופלים לנהר
# ============================================================
class BridgeCollapse extends Node2D:
	const BEEP_T := 2.2
	const STEP := 0.16              # שניות בין פיצוצים
	const GAP := 230.0              # פיקסלים בין פיצוצים
	var x0 := 7600.0                # (גלובלי) תחילת החלק שנופל
	var x1 := 9280.0                # (גלובלי) הקצה החדש של הגשר (הקיר)
	var floor_y := 630.0
	var stage: Node = null
	var booms := 0                  # לבדיקות
	var chunks := 0
	var splashes := 0
	var _t := 0.0
	var _beep := 0.0
	var _bx := 0.0                  # איפה הפיצוץ הבא
	var _gone := 0.0                # (גלובלי) עד איפה הגשר כבר נעלם (משמאל ל-x1)
	var _boom_cd := 0.0
	var _pieces := []               # [מיקום, מהירות, זווית, סיבוב, גודל, סוג (0 = לוח, 1 = קורה), התיז]
	var _started := false

	func _ready() -> void:
		z_index = 3
		_bx = x1 - 60.0
		_gone = x1
		var body := StaticBody2D.new()   # קיר בקצה החדש - אין דרך חזרה
		body.collision_layer = 1
		body.collision_mask = 0
		body.add_to_group("no_outline")
		var cs := CollisionShape2D.new()
		var sh := RectangleShape2D.new()
		sh.size = Vector2(30.0, 900.0)
		cs.shape = sh
		cs.position = Vector2(x1 - 15.0, floor_y - 450.0)
		body.add_child(cs)
		add_child(body)

	func _process(delta: float) -> void:
		_t += delta
		var pl := get_tree().get_first_node_in_group("player") as Node2D
		if _t < BEEP_T:
			_beep -= delta
			if _beep <= 0.0:
				_beep = lerpf(0.42, 0.06, _t / BEEP_T)
				Sfx.play("b54_beep", (pl.global_position if pl != null else Vector2(x1, floor_y)) + Vector2(-200, -100), 4.0, 0.0, 3, 1.0 + _t / BEEP_T * 0.5)
		elif not _started:
			_started = true
			boom_ms_set()
			var cam := get_viewport().get_camera_2d()
			if cam != null and cam.has_method("shake"):
				cam.shake(24.0, 1.4)
			Sfx.play("b54_rumble", Vector2(x1 - 200.0, floor_y), 8.0)
			if stage != null and stage.has_method("collapse_started"):
				stage.collapse_started(self)
		if _started:
			_boom_cd -= delta
			if _boom_cd <= 0.0 and _bx > x0:
				_boom_cd = STEP
				_boom(_bx)
				_bx -= GAP
			var cam2 := get_viewport().get_camera_2d()
			if cam2 != null and cam2.has_method("shake") and _bx > x0:
				cam2.shake(9.0, 0.2)
		for p in _pieces:
			p[1].y += 900.0 * delta
			p[0] += p[1] * delta
			p[2] += p[3] * delta
			if not p[6] and p[0].y > floor_y + 70.0:
				p[6] = true
				splashes += 1
				if Art.on_screen(self, p[0], 200.0):
					Sfx.play("splash", p[0], 4.0, 0.15, 4, 0.7)
					Particles.burst(get_parent(), Vector2(p[0].x, floor_y + 66.0), "drop", Vector2.UP, 18)
					Particles.burst(get_parent(), Vector2(p[0].x, floor_y + 60.0), "mist", Vector2.UP, 6)
		_pieces = _pieces.filter(func(p): return p[0].y < floor_y + 500.0)
		if _started and _t < 24.0 and Art.on_screen(self, Vector2(x1, floor_y), 200.0):   # הקצה השבור בוער ומעשן
			var f := Engine.get_process_frames()
			if f % 5 == 0:
				Particles.burst(get_parent(), Vector2(x1 - 40.0 + randf_range(-20, 10), floor_y + 6.0), "smoke", Vector2(0.3, -1.0), 1)
			if f % 14 == 0:
				Particles.burst(get_parent(), Vector2(x1 - 36.0, floor_y + 10.0), "fire", Vector2.UP, 2)
		queue_redraw()
		if _started and _bx <= x0 and _pieces.is_empty() and _t > 24.0:
			set_process(false)

	static func boom_ms_set() -> void:
		U.boom_ms = Time.get_ticks_msec()

	func _boom(bx: float) -> void:
		booms += 1
		_gone = minf(_gone, bx - GAP * 0.5)
		var pl := get_tree().get_first_node_in_group("player") as Node2D
		var c := Vector2(bx, floor_y - 30.0)
		var far := pl == null or absf(pl.global_position.x - bx) > 900.0
		if far:
			Sfx.play("explosion", c, -4.0, 0.1, 3, 0.8)
		elif pl.global_position.distance_to(c) > 140.0:
			Boom.blast(get_parent(), c, 120.0, 60.0, 300, 0, "bridge")
		Particles.burst(get_parent(), c, "fire", Vector2.UP, 10)
		if stage != null and stage.has_method("collapse_at"):
			stage.collapse_at(bx - GAP, bx + GAP * 0.5)
		for q in 3:   # לוחות כביש
			chunks += 1
			_pieces.append([Vector2(bx + randf_range(-GAP * 0.5, GAP * 0.5), floor_y + 10.0), Vector2(randf_range(-80, 80), randf_range(-260, -60)), randf_range(-0.2, 0.2), randf_range(-2.5, 2.5), Vector2(randf_range(70, 130), 34), 0, false])
		for q in 2:   # קורות מסבך
			chunks += 1
			_pieces.append([Vector2(bx + randf_range(-GAP * 0.5, GAP * 0.5), floor_y - TRUSS_H + randf_range(-10, 120)), Vector2(randf_range(-120, 120), randf_range(-200, 0)), randf_range(0.0, PI), randf_range(-3.0, 3.0), Vector2(randf_range(110, 180), 12), 1, false])

	func _draw() -> void:
		DrawBatch.begin(self)
		_draw_b()
		DrawBatch.end(self)

	func _draw_b() -> void:
		if _gone < x1:
			# החור: אוויר ונהר רחוק למטה (מכסה את משטח הגשר)
			var r := Rect2(_gone, floor_y - 1.0, x1 - _gone - 30.0, 140.0)
			DrawBatch.rect(self, r, Color("070c18"))
			DrawBatch.rect(self, Rect2(r.position.x, floor_y + 64.0, r.size.x, 80.0), Color("0e1c34"))
			for q in int(r.size.x / 60.0):
				var gx := r.position.x + fposmod(float(q) * 61.0 + _t * 16.0, r.size.x)
				DrawBatch.line(self, Vector2(gx, floor_y + 72.0 + float(q % 3) * 7.0), Vector2(gx + 18.0, floor_y + 72.0 + float(q % 3) * 7.0), Color(0.7, 0.8, 1.0, 0.25), 1.2)
			# קצה שבור (ימין, ליד הקיר) + קצה שבור משמאל
			for s: float in [-1.0, 1.0]:
				var ex := (x1 - 30.0) if s > 0.0 else _gone
				DrawBatch.colored_polygon(self, PackedVector2Array([Vector2(ex, floor_y), Vector2(ex - s * 26.0, floor_y + 4.0), Vector2(ex - s * 10.0, floor_y + 14.0), Vector2(ex - s * 30.0, floor_y + 30.0), Vector2(ex - s * 6.0, floor_y + 44.0), Vector2(ex, floor_y + 44.0)]), Color("262d3a"))
				DrawBatch.line(self, Vector2(ex - s * 8.0, floor_y + 12.0), Vector2(ex - s * 30.0, floor_y + 70.0), Color("6a4a30"), 2.0)
				DrawBatch.line(self, Vector2(ex - s * 14.0, floor_y + 20.0), Vector2(ex - s * 22.0, floor_y + 90.0), Color("101010"), 1.5)   # כבל
				Art.glow(self, Vector2(ex - s * 8.0, floor_y + 8.0), 26.0, Color(1.0, 0.45, 0.15, 0.35 * (0.6 + 0.4 * sin(_t * 7.0))))
		for p in _pieces:
			var sz: Vector2 = p[4]
			DrawBatch.set_transform(self, p[0], p[2], Vector2.ONE)
			if p[5] == 0:
				DrawBatch.rect(self, Rect2(-sz.x * 0.5, -sz.y * 0.5, sz.x, 11.0), ASPHALT)
				DrawBatch.rect(self, Rect2(-sz.x * 0.5, -sz.y * 0.5, sz.x, 2.0), Color(0.6, 0.66, 0.8, 0.6))
				DrawBatch.rect(self, Rect2(-sz.x * 0.5, -sz.y * 0.5 + 11.0, sz.x, sz.y - 11.0), Color("262d3a"))
			else:
				DrawBatch.rect(self, Rect2(-sz.x * 0.5, -sz.y * 0.5, sz.x, sz.y), IRON)
				DrawBatch.rect(self, Rect2(-sz.x * 0.5, -sz.y * 0.5, sz.x, 2.0), IRON_L)
			DrawBatch.set_transform(self, Vector2.ZERO, 0.0, Vector2.ONE)


# ============================================================
#  מסך
# ============================================================

# ---- רוח קרה מהדרום + ערפל נהר + משבים ----
class BridgeFX extends Node2D:
	const GUST_EVERY := Vector2(13.0, 20.0)
	var vp := Vector2(1280, 720)
	var gusts := 0                  # לבדיקות
	var _t := 0.0
	var _next := 8.0
	var _gust := -1.0

	func gust() -> void:
		_gust = 0.0
		gusts += 1
		Sfx.play("b54_wind", null, 0.0)

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
		for i in int((22.0 + 30.0 * g) * q):   # פסי רוח שעוברים מימין לשמאל
			var sp := 700.0 + U.h(i, 1) * 500.0 + 600.0 * g
			var x := fposmod(U.h(i, 2) * vp.x * 3.0 - _t * sp, vp.x + 400.0) - 200.0
			var y := U.h(i, 3) * vp.y * 0.9 + sin(_t * 1.5 + float(i)) * 12.0
			var ln := 60.0 + U.h(i, 4) * 120.0
			var a := 0.05 + 0.06 * U.h(i, 5) + 0.08 * g
			U.quad(pts, cols, Vector2(x, y), Vector2(x + ln, y - 2.0), Vector2(x + ln, y - 1.0), Vector2(x, y + 1.2), Color(0.8, 0.86, 1.0, a), Color(0.8, 0.86, 1.0, 0.0), Color(0.8, 0.86, 1.0, 0.0), Color(0.8, 0.86, 1.0, a))
		U.flush(self, pts, cols)
		for i in 7:   # ערפל נהר נמוך
			var mx := fposmod(float(i) * 260.0 - _t * (26.0 + float(i) * 4.0), vp.x + 500.0) - 250.0
			Kit.soft_ellipse(self, Vector2(mx, vp.y - 30.0 - float(i % 3) * 22.0), 260.0, 40.0, 0.0, Color(0.68, 0.76, 0.92, 0.07 + 0.03 * sin(_t * 0.5 + float(i))))
		if g > 0.0:   # במשב: עלים וניירות על המסך
			for i in 6:
				var dx := vp.x + 100.0 - (_gust / 3.0) * (vp.x + 300.0) * (0.8 + U.h(i, 6) * 0.5)
				var dy := 150.0 + U.h(i, 7) * 400.0 + sin(_t * 5.0 + float(i)) * 30.0
				var rot := _t * 7.0 + float(i)
				DrawBatch.colored_polygon(self, PackedVector2Array([Vector2(dx, dy) + Vector2.from_angle(rot) * 9.0, Vector2(dx, dy) + Vector2.from_angle(rot + 2.0) * 6.0, Vector2(dx, dy) + Vector2.from_angle(rot + PI) * 9.0, Vector2(dx, dy) + Vector2.from_angle(rot + 4.3) * 6.0]), Color(0.78, 0.78, 0.72, 0.6 * g))


# ---- מונה המטענים (למעלה במרכז) + חץ למטען שדילגת עליו ----
class ChargeHud extends Node2D:
	var vp := Vector2(1280, 720)
	var need := 4
	var armed := 0
	var done_t := -1.0              # כולם דרוכים: מציג הודעה ואז נעלם
	var off := false
	var _t := 0.0
	var _flash := 0.0

	func flash() -> void:
		_flash = 1.0

	func _process(delta: float) -> void:
		_t += delta
		_flash = maxf(0.0, _flash - delta * 1.5)
		if done_t >= 0.0:
			done_t += delta
		if Engine.get_process_frames() % 3 == 0:
			queue_redraw()

	func _draw() -> void:
		DrawBatch.begin(self)
		_draw_b()
		DrawBatch.end(self)

	func _draw_b() -> void:
		if off or (done_t > 5.0):
			return
		var a := 1.0 if done_t < 0.0 else clampf(1.0 - (done_t - 4.0), 0.0, 1.0)
		var c := Vector2(vp.x - 140.0, 206.0)   # מתחת לסגנון (STYLE) - לא על השעון באמצע
		var font := ThemeDB.fallback_font
		DrawBatch.rect(self, Rect2(c + Vector2(-120, -20), Vector2(240, 38)), Color(0.02, 0.03, 0.06, 0.55 * a))
		DrawBatch.rect(self, Rect2(c + Vector2(-120, -20), Vector2(240, 38)), Color(1.0, 0.82, 0.3, (0.3 + 0.6 * _flash) * a), false, 1.5)
		var txt := "CHARGES ARMED" if done_t < 0.0 else "BRIDGE WIRED"
		DrawBatch.string(self, font, c + Vector2(-112, 4), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color(1.0, 0.86, 0.4, a))
		for q in need:
			var p := c + Vector2(42.0 + float(q) * 20.0, -1.0)
			var on := q < armed
			var blink := on and fmod(_t + float(q) * 0.27, 1.1) < 0.2
			DrawBatch.circle(self, p, 6.0, (Color(1.0, 0.2, 0.12) if blink else Color(0.7, 0.1, 0.06)) if on else Color(0.3, 0.3, 0.32))
			DrawBatch.arc(self, p, 6.0, 0.0, TAU, 12, Color(0, 0, 0, 0.6 * a), 1.2)
			if blink:
				Art.glow(self, p, 16.0, Color(1.0, 0.2, 0.1, 0.5 * a))
		if done_t >= 0.0 and done_t < 4.0:
			DrawBatch.string(self, font, c + Vector2(-200, 40), "THE GATE IS OPEN - FIND THE ARCHITECT", HORIZONTAL_ALIGNMENT_RIGHT, 320, 14, Color(1.0, 0.9, 0.6, a * (0.7 + 0.3 * sin(_t * 6.0))))
		# מטען שעברת בלי לדרוך
		var pl := get_tree().get_first_node_in_group("player") as Node2D
		if pl != null and done_t < 0.0:
			for ch in get_tree().get_nodes_in_group("s54_charges"):
				if not ch.armed and ch.global_position.x < pl.global_position.x - 640.0:
					var y := vp.y * 0.42
					var k := 0.6 + 0.4 * sin(_t * 6.0)
					DrawBatch.colored_polygon(self, PackedVector2Array([Vector2(16, y), Vector2(36, y - 14), Vector2(36, y + 14)]), Color(1.0, 0.8, 0.3, k))
					DrawBatch.string(self, font, Vector2(42, y + 5), "UNARMED CHARGE", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(1.0, 0.85, 0.4, k))
					break


# ---- הבזק + כותרת ענק כשהגשר נופל ----
class CollapseBanner extends Node2D:
	var vp := Vector2(1280, 720)
	var delay := 2.2                # מתי ההבזק (אחרי הצפצופים)
	var _t := 0.0

	func _process(delta: float) -> void:
		_t += delta
		queue_redraw()
		if _t > delay + 9.0:
			queue_free()

	func _draw() -> void:
		DrawBatch.begin(self)
		_draw_b()
		DrawBatch.end(self)

	func _draw_b() -> void:
		var k := _t - delay
		if k < 0.0:   # צפצופים: מסגרת אדומה פועמת
			var p := 0.5 + 0.5 * sin(_t * lerpf(8.0, 40.0, _t / delay))
			DrawBatch.rect(self, Rect2(Vector2.ZERO, vp), Color(1.0, 0.1, 0.05, 0.12 * p), false, 18.0)
			return
		if k < 0.6:
			DrawBatch.rect(self, Rect2(Vector2.ZERO, vp), Color(1.0, 0.95, 0.85, 0.18 * (1.0 - k / 0.6)))
		if k > 1.4:
			var a := clampf((k - 1.4) * 2.0, 0.0, 1.0) * clampf(7.5 - k, 0.0, 1.0)
			var font := ThemeDB.fallback_font
			var c := Vector2(vp.x * 0.5, vp.y * 0.3)
			DrawBatch.rect(self, Rect2(0, c.y - 46.0, vp.x, 84.0), Color(0.0, 0.0, 0.03, 0.45 * a))
			DrawBatch.string(self, font, c + Vector2(-vp.x * 0.5 + 2.0, 2.0), "THE BRIDGE IS DOWN", HORIZONTAL_ALIGNMENT_CENTER, vp.x, 44, Color(0, 0, 0, 0.7 * a))
			DrawBatch.string(self, font, c + Vector2(-vp.x * 0.5, 0.0), "THE BRIDGE IS DOWN", HORIZONTAL_ALIGNMENT_CENTER, vp.x, 44, Color(1.0, 0.9, 0.7, a))
			DrawBatch.string(self, font, c + Vector2(-vp.x * 0.5, 30.0), "nothing else crosses into Patagonia... nothing that walks", HORIZONTAL_ALIGNMENT_CENTER, vp.x, 15, Color(0.75, 0.85, 1.0, a * 0.9))


# ---- פנס גשר שמהבהב כל הזמן (חוטים קרועים) ----
class FlickerLamp extends "res://street_lamp.gd":
	func _process(delta: float) -> void:
		super._process(delta)
		if _next_flicker > 2.4:
			_next_flicker = randf_range(0.4, 2.4)
