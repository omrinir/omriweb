extends RefCounted
const DrawBatch := preload("res://effects/draw_batch.gd")   # כל הציור של זומבי ב-draw call אחד
# ============================================================
#  קישוטים לשלב 50 ("TANGO CEMETERY") - בית הקברות רקולטה בבואנוס איירס, בלילה. אזור שישי (החרוט הדרומי), שלב 5.
#  שדרות של מאוזוליאומים משיש, מלאכים על הגגות, דלתות ברזל, ברושים, חתולים - וירח שנכנס ויוצא מהעננים.
#    cem_sky       - (רקע) לילה כחול-סגול, כוכבים, הירח + גוש עננים שמכסה/חושף אותו (לפי moon_k), עננים זזים
#    far_city      - (רקע, 0.06) קו הרקיע של בואנוס איירס, הבזיליקה דל פילאר עם מגדל הפעמונים, עטלפים
#    mid_tombs     - (רקע, 0.28) שורות מאוזוליאומים עם כיפות, צלבים ומלאכים, נרות מהבהבים בפתחים, ערפל נודד
#    near_cypress  - (רקע, 0.6) ברושים מתנדנדים, גדר ברזל, מצבות, חתולים משוטטים עם עיניים זוהרות
#    CemeteryGround - (עולם) שביל אבן עם לוחות שיש סדוקים
#    Mausoleum     - (עולם) מאוזוליאום משיש עם עמודים ודלת ברזל; הגג = קומה שנייה (add_floor)
#    AngelStatue   - (עולם, מלכודת) מלאך שיש על כן ליד השביל: אתה מתקרב -> סדקים + חריקה (WARN_T) -> נופל לכיוונך
#                    (FALL_L לאורך הרצפה: DMG לך, DMG_Z לזומבים). ירייה בכן = נופל לכיוון הירייה (על זומבים!).
#    CryptDoor     - (עולם, מלכודת) קריפטה עם דלת ברזל כפולה: אתה מתקרב -> הדלת רועדת (WARN_T) -> נפרצת: פרץ אבק (BLAST_R)
#                    שהודף ופוגע, ו-RELEASE מתים יוצאים. פעם אחת.
#    RecoletaGate  - (עולם) השער הגדול של רקולטה עם העמודים ("REQUIESCANT IN PACE") מאחורי הבוס
#    Obstacle      - (מוצק + מחסה) "grave" מצבה עם צלב / "sarcophagus" ארון אבן / "urn" כד אבן על כן
#    MoonCycle     - (עולם, בלי ציור) מחזור הירח של השלב: עננים (CLOUD_T) -> אזהרה (WARN_T) -> ירח מלא (FULL_T).
#                    LOBIZON (enemies/types/lobizon.gd) הופך לזאב בירח מלא. קבוצה "moon_cycle".
#    MoonFX        - (מסך) ערפל קרקע, הבזק אור ירח, ובאנר "THE CLOUDS ARE PARTING" / "FULL MOON"
#  לשנות: MoonCycle.CLOUD_T / WARN_T / FULL_T, AngelStatue.WARN_T / FALL_L / DMG / DMG_Z, CryptDoor.WARN_T / RELEASE / BLAST_R.
# ============================================================

const Art := preload("res://art.gd")
const Kit := preload("res://effects/backdrop_kit.gd")
const S50 := preload("res://effects/s50_decor.gd")   # (המחלקות הפנימיות ניגשות למשתנים הסטטיים דרכו)

const MARBLE := Color("c8c4bc")
const MARBLE_D := Color("8e8a84")
const IRON := Color("16141a")

# מצב הירח - משותף לרקע, למסך ול-LOBIZON. MoonCycle מעדכן (ומאפס כשהשלב נגמר)
static var moon_k := 0.0       # 0 = מכוסה בעננים, 1 = ירח מלא
static var moon_warn := 0.0    # >0 = העננים נפתחים (אזהרה)
static var active := false     # יש MoonCycle בשלב הזה
static var full_now := false   # ירח מלא עכשיו (מיידי - moon_k רק לציור, עולה לאט)


static func _h(i: int, s: int) -> float:
	return fposmod(sin(float(i) * 12.9898 + float(s) * 78.233) * 43758.5453, 1.0)


static func cem_sky(ci: CanvasItem, v: Vector2, t: float) -> void:
	var k := moon_k
	Kit.gradient_sky(ci, v, [Color("05060f"), Color("0e1228"), Color("1a1e3a").lerp(Color("2a3050"), k), Color("2e2a44").lerp(Color("4a4a64"), k)], 0.9)
	for i in 60:   # כוכבים
		var p := Vector2(_h(i, 1) * v.x, _h(i, 2) * v.y * 0.55)
		var tw := 0.4 + 0.6 * absf(sin(t * (0.7 + _h(i, 3) * 2.0) + float(i)))
		DrawBatch.circle(ci, p, 0.7 + _h(i, 4) * 0.9, Color(0.9, 0.92, 1.0, 0.45 * tw))
	var mp := Vector2(v.x * 0.7, v.y * 0.2)
	# הירח: בהיר יותר כשהוא חשוף, הילה גדולה בירח מלא
	Art.glow(ci, mp, 70.0 + 90.0 * k, Color(0.85, 0.9, 1.0, 0.08 + 0.22 * k))
	DrawBatch.circle(ci, mp, 34.0, Color(0.96, 0.95, 0.86))
	DrawBatch.circle(ci, mp + Vector2(10, -8), 7.0, Color(0.86, 0.85, 0.78))
	DrawBatch.circle(ci, mp + Vector2(-12, 7), 5.0, Color(0.87, 0.86, 0.79))
	DrawBatch.circle(ci, mp + Vector2(4, 14), 4.0, Color(0.88, 0.87, 0.8))
	# גוש העננים שמכסה את הירח: זז ימינה ונעלם כשהירח נחשף
	var off := k * 320.0
	var ca := 0.97 * (1.0 - k * 0.85)
	for q in 9:
		var cp := mp + Vector2(-110.0 + float(q) * 30.0 + off, sin(float(q) * 1.7) * 14.0 + float(q % 3) * 6.0)
		var cr := 34.0 + _h(q, 21) * 22.0
		DrawBatch.colored_polygon(ci, Art.ellipse(cp, cr * 1.4, cr * 0.75, 0.0, 16), Color(0.1, 0.11, 0.2, ca))
		DrawBatch.colored_polygon(ci, Art.ellipse(cp + Vector2(0, -cr * 0.25), cr * 1.1, cr * 0.45, 0.0, 14), Color(0.16, 0.17, 0.28, ca))
	if moon_warn > 0.0:   # העננים נפתחים: שולי כסף על העננים
		var a := 0.3 + 0.3 * sin(t * 6.0)
		for q in 9:
			var cp := mp + Vector2(-110.0 + float(q) * 30.0 + off, sin(float(q) * 1.7) * 14.0 + float(q % 3) * 6.0)
			DrawBatch.arc(ci, cp, 30.0, PI * 1.1, PI * 1.9, 10, Color(0.85, 0.9, 1.0, a), 2.0)
	Kit.clouds(ci, t * 5.0, v, t, v.y * 0.32, Color(0.1, 0.1, 0.2, 0.45), 17, 6.0)


# ---- קו הרקיע + הבזיליקה + עטלפים ----
static func far_city(ci: CanvasItem, sc: float, v: Vector2, y: float, t: float) -> void:
	Kit.skyline(ci, sc, v, y - 20.0, Color("101226"), 50, Vector2(50, 110), Vector2(70, 220), 0.05, Color(1.0, 0.8, 0.5, 0.55), t, 0.0)
	var period := 1700.0
	var start := int(floor(sc / period)) - 1
	var wall := Color("1e2034").lerp(Color("2e3250"), moon_k)
	for k in range(start, start + int(ceil(v.x / period)) + 2):
		var bx := float(k) * period - sc
		# הבזיליקה דל פילאר: כנסייה קולוניאלית לבנה עם מגדל פעמונים אחד
		var cx := bx + 600.0
		DrawBatch.rect(ci, Rect2(cx - 90, y - 110, 180, 90), wall)
		DrawBatch.colored_polygon(ci, PackedVector2Array([Vector2(cx - 96, y - 110), Vector2(cx - 30, y - 140), Vector2(cx + 96, y - 110)]), wall.darkened(0.1))
		var tx := cx - 70.0
		DrawBatch.rect(ci, Rect2(tx - 22, y - 230, 44, 120), wall)
		DrawBatch.rect(ci, Rect2(tx - 26, y - 236, 52, 8), wall.lightened(0.1))
		DrawBatch.rect(ci, Rect2(tx - 16, y - 286, 32, 52), wall)
		for q in 2:   # חלון הפעמון
			DrawBatch.rect(ci, Rect2(tx - 11 + float(q) * 13.0, y - 278, 9, 22), Color("0a0a14"))
			DrawBatch.circle(ci, Vector2(tx - 6.5 + float(q) * 13.0, y - 278), 4.5, Color("0a0a14"))
		var sw := sin(t * 1.8 + float(k)) * 2.0   # הפעמון מתנדנד
		DrawBatch.colored_polygon(ci, PackedVector2Array([Vector2(tx - 4 + sw, y - 270), Vector2(tx + 4 + sw, y - 270), Vector2(tx + 6 + sw, y - 260), Vector2(tx - 6 + sw, y - 260)]), Color("6a5a30"))
		DrawBatch.colored_polygon(ci, Art.ellipse(Vector2(tx, y - 290), 18.0, 12.0, 0.0, 12), wall.lightened(0.05))   # כיפה
		DrawBatch.line(ci, Vector2(tx, y - 300), Vector2(tx, y - 322), wall, 2.5)
		DrawBatch.line(ci, Vector2(tx - 6, y - 314), Vector2(tx + 6, y - 314), wall, 2.5)
		for q in 4:   # חלונות מוארים בכנסייה
			DrawBatch.rect(ci, Rect2(cx - 40 + float(q) * 30.0, y - 90, 10, 22), Color(1.0, 0.78, 0.45, 0.55))
		# מגדל דירות עם אור אדום על הגג
		DrawBatch.rect(ci, Rect2(bx + 1200, y - 260, 70, 240), Color("14162c"))
		DrawBatch.circle(ci, Vector2(bx + 1235, y - 264), 2.2, Color(1.0, 0.15, 0.1, 0.35 + 0.65 * float(int(t * 1.4 + float(k)) % 2)))
	# עטלפים
	for i in 6:
		var u := fposmod(t * (0.035 + float(i) * 0.006) + float(i) * 0.17, 1.0)
		var p := Vector2(u * (v.x + 200.0) - 100.0, v.y * (0.12 + 0.05 * float(i % 3)) + sin(t * 2.0 + float(i) * 2.0) * 22.0)
		var fl := sin(t * 18.0 + float(i) * 3.0)
		var bc := Color(0.02, 0.02, 0.04, 0.9)
		DrawBatch.colored_polygon(ci, PackedVector2Array([p + Vector2(0, -1), p + Vector2(-9, -5 * fl - 2), p + Vector2(-4, 1.5)]), bc)   # (משולשים - לא נשברים בשום תנופה)
		DrawBatch.colored_polygon(ci, PackedVector2Array([p + Vector2(0, -1), p + Vector2(9, -5 * fl - 2), p + Vector2(4, 1.5)]), bc)
		DrawBatch.circle(ci, p, 1.8, bc)


# ---- שורות המאוזוליאומים ----
static func mid_tombs(ci: CanvasItem, sc: float, v: Vector2, y: float, t: float) -> void:
	var period := 170.0
	var start := int(floor(sc / period)) - 1
	var mk := moon_k
	for k in range(start, start + int(ceil(v.x / period)) + 2):
		var bx := float(k) * period - sc
		var kind := int(_h(k, 5) * 4.0)
		var w := 120.0 + _h(k, 6) * 30.0
		var hh := 120.0 + _h(k, 7) * 70.0
		var c := Color("4a4a58").lerp(Color("7a7a88"), mk * 0.6).darkened(0.1 * float(k % 2))
		var cx := bx + w * 0.5
		DrawBatch.rect(ci, Rect2(bx, y - hh, w, hh), c)
		DrawBatch.rect(ci, Rect2(bx - 4, y - hh - 6, w + 8, 8), c.lightened(0.12))
		for q in 2:   # עמודים
			DrawBatch.rect(ci, Rect2(bx + 8.0 + float(q) * (w - 24.0), y - hh + 4.0, 8.0, hh - 4.0), c.lightened(0.08))
		# פתח עם דלת ברזל ונר
		var dw := 34.0
		DrawBatch.rect(ci, Rect2(cx - dw * 0.5, y - 70, dw, 70), Color("0c0a12"))
		DrawBatch.circle(ci, Vector2(cx, y - 70), dw * 0.5, Color("0c0a12"))
		for q in 5:
			DrawBatch.line(ci, Vector2(cx - 14 + float(q) * 7.0, y - 80), Vector2(cx - 14 + float(q) * 7.0, y), Color("22202a"), 1.0)
		var fl := 0.65 + 0.35 * sin(t * (9.0 + _h(k, 8) * 6.0) + float(k)) * sin(t * 4.3 + float(k))
		if _h(k, 9) < 0.7:
			Art.glow(ci, Vector2(cx, y - 14), 22.0, Color(1.0, 0.65, 0.3, 0.3 * fl))
			DrawBatch.rect(ci, Rect2(cx - 1.5, y - 14, 3, 8), Color("e8e0d0"))
			DrawBatch.circle(ci, Vector2(cx, y - 17), 1.8, Color(1.0, 0.8, 0.4, fl))
		match kind:
			0:   # כיפה + צלב
				DrawBatch.colored_polygon(ci, Art.ellipse(Vector2(cx, y - hh - 6), w * 0.32, w * 0.26, 0.0, 16), c.lightened(0.05))
				DrawBatch.rect(ci, Rect2(cx - w * 0.32, y - hh - 6, w * 0.64, 6), c)
				DrawBatch.line(ci, Vector2(cx, y - hh - 6 - w * 0.26), Vector2(cx, y - hh - 30 - w * 0.26), IRON, 2.5)
				DrawBatch.line(ci, Vector2(cx - 7, y - hh - 22 - w * 0.26), Vector2(cx + 7, y - hh - 22 - w * 0.26), IRON, 2.5)
			1:   # גמלון + מלאך עם כנפיים
				DrawBatch.colored_polygon(ci, PackedVector2Array([Vector2(bx - 4, y - hh - 6), Vector2(cx, y - hh - 34), Vector2(bx + w + 4, y - hh - 6)]), c.lightened(0.04))
				_angel(ci, Vector2(cx, y - hh - 34), 0.8, c.lightened(0.2), t, k)
			2:   # אובליסק קטן
				DrawBatch.colored_polygon(ci, PackedVector2Array([Vector2(cx - 10, y - hh - 6), Vector2(cx - 6, y - hh - 60), Vector2(cx, y - hh - 70), Vector2(cx + 6, y - hh - 60), Vector2(cx + 10, y - hh - 6)]), c.lightened(0.1))
			_:   # גג שטוח עם כד
				DrawBatch.rect(ci, Rect2(cx - 8, y - hh - 22, 16, 16), c.lightened(0.1))
				DrawBatch.colored_polygon(ci, Art.ellipse(Vector2(cx, y - hh - 30), 9.0, 10.0, 0.0, 10), c.lightened(0.14))
	# ערפל נודד בין הקברים
	for i in 7:
		var fx := fposmod(float(i) * 233.0 + t * (10.0 + float(i % 3) * 5.0) - sc * 0.2, v.x + 400.0) - 200.0
		DrawBatch.colored_polygon(ci, Art.ellipse(Vector2(fx, y - 18.0 - float(i % 3) * 10.0), 160.0, 18.0, 0.0, 16), Color(0.6, 0.65, 0.85, 0.06 + 0.04 * mk))
	DrawBatch.rect(ci, Rect2(0, y, v.x, v.y - y), Color("0e0e18"))


# מלאך שיש (פסל): גוף בגלימה, כנפיים, ראש מורכן
static func _angel(ci: CanvasItem, base: Vector2, s: float, c: Color, t: float, k: int) -> void:
	var wing := c.darkened(0.15)
	var fl := sin(t * 0.5 + float(k)) * 0.03
	DrawBatch.colored_polygon(ci, PackedVector2Array([base + Vector2(-2, -30) * s, base + Vector2(-22, -54 - 6 * fl) * s, base + Vector2(-16, -30) * s, base + Vector2(-10, -18) * s]), wing)
	DrawBatch.colored_polygon(ci, PackedVector2Array([base + Vector2(2, -30) * s, base + Vector2(22, -54 + 6 * fl) * s, base + Vector2(16, -30) * s, base + Vector2(10, -18) * s]), wing)
	DrawBatch.colored_polygon(ci, PackedVector2Array([base + Vector2(-8, 0) * s, base + Vector2(8, 0) * s, base + Vector2(5, -32) * s, base + Vector2(-5, -32) * s]), c)
	DrawBatch.circle(ci, base + Vector2(1, -37) * s, 5.0 * s, c)


# ---- ברושים, גדר, מצבות וחתולים ----
static func near_cypress(ci: CanvasItem, sc: float, v: Vector2, y: float, t: float) -> void:
	var period := 300.0
	var start := int(floor(sc / period)) - 1
	var dark := Color("06080c")
	for k in range(start, start + int(ceil(v.x / period)) + 2):
		var x := float(k) * period - sc
		# ברוש: להבה כהה וגבוהה שמתנדנדת
		var cx := x + 60.0 + _h(k, 3) * 40.0
		var ht := 190.0 + _h(k, 4) * 60.0
		var sw := sin(t * 0.9 + float(k) * 1.3) * 6.0
		DrawBatch.colored_polygon(ci, PackedVector2Array([Vector2(cx - 18, y), Vector2(cx - 22, y - ht * 0.4), Vector2(cx - 12 + sw * 0.6, y - ht * 0.8), Vector2(cx + sw, y - ht), Vector2(cx + 12 + sw * 0.6, y - ht * 0.8), Vector2(cx + 22, y - ht * 0.4), Vector2(cx + 18, y)]), Color("0a120e"))
		DrawBatch.line(ci, Vector2(cx - 6, y - ht * 0.3), Vector2(cx - 3 + sw * 0.5, y - ht * 0.8), Color(0.3, 0.4, 0.5, 0.08 + 0.12 * moon_k), 2.0)
		# גדר ברזל עם חודים
		for q in 14:
			var fx := x + 110.0 + float(q) * 11.0
			DrawBatch.line(ci, Vector2(fx, y), Vector2(fx, y - 44.0), dark, 2.0)
			DrawBatch.colored_polygon(ci, PackedVector2Array([Vector2(fx - 3, y - 44), Vector2(fx, y - 51), Vector2(fx + 3, y - 44)]), dark)
		DrawBatch.line(ci, Vector2(x + 108.0, y - 34.0), Vector2(x + 265.0, y - 34.0), dark, 2.0)
		DrawBatch.line(ci, Vector2(x + 108.0, y - 8.0), Vector2(x + 265.0, y - 8.0), dark, 2.0)
		# מצבות
		for q in 2:
			var gx := x + 20.0 + float(q) * 250.0 * _h(k, 10 + q)
			DrawBatch.rect(ci, Rect2(gx, y - 30, 20, 30), Color("101218"))
			DrawBatch.circle(ci, Vector2(gx + 10, y - 30), 10.0, Color("101218"))
			if q == 0:
				DrawBatch.line(ci, Vector2(gx + 10, y - 48), Vector2(gx + 10, y - 30), Color("101218"), 3.0)
				DrawBatch.line(ci, Vector2(gx + 4, y - 42), Vector2(gx + 16, y - 42), Color("101218"), 3.0)
	# חתולים משוטטים (עם עיניים זוהרות)
	for i in 3:
		var u := fposmod(t * (0.018 + float(i) * 0.007) + float(i) * 0.37, 1.0)
		var dirc := 1.0 if i % 2 == 0 else -1.0
		var px := (u if dirc > 0.0 else 1.0 - u) * (v.x + 120.0) - 60.0
		var p := Vector2(px, y - 2.0)
		var st := sin(t * 9.0 + float(i)) * 2.0
		var cc := Color("040406")
		DrawBatch.colored_polygon(ci, Art.ellipse(p + Vector2(0, -8), 12.0, 5.0, 0.0, 10), cc)
		DrawBatch.circle(ci, p + Vector2(11.0 * dirc, -12), 4.5, cc)
		DrawBatch.colored_polygon(ci, PackedVector2Array([p + Vector2(8.0 * dirc, -15), p + Vector2(9.0 * dirc, -20), p + Vector2(11.0 * dirc, -15)]), cc)
		DrawBatch.colored_polygon(ci, PackedVector2Array([p + Vector2(12.0 * dirc, -15), p + Vector2(14.0 * dirc, -20), p + Vector2(15.0 * dirc, -14)]), cc)
		for lg in 4:
			var lx := -8.0 + float(lg) * 5.0
			DrawBatch.line(ci, p + Vector2(lx, -6), p + Vector2(lx + (st if lg % 2 == 0 else -st), 0), cc, 1.6)
		DrawBatch.polyline(ci, PackedVector2Array([p + Vector2(-11.0 * dirc, -9), p + Vector2(-17.0 * dirc, -16), p + Vector2(-19.0 * dirc, -24 + sin(t * 3.0 + float(i)) * 3.0)]), cc, 1.8)
		DrawBatch.circle(ci, p + Vector2(13.0 * dirc, -13), 1.1, Color(0.6, 1.0, 0.4, 0.9))
	DrawBatch.rect(ci, Rect2(0, y, v.x, v.y - y), Color("07070c"))


# ============================================================
#  עולם
# ============================================================
class CemeteryGround extends Node2D:
	var w := 1024.0
	var depth := 90.0

	func _ready() -> void:
		z_index = 1

	func _draw() -> void:
		DrawBatch.begin(self)
		_draw_b()
		DrawBatch.end(self)

	func _draw_b() -> void:
		DrawBatch.rect(self, Rect2(0, 0, w, depth), Color("2a2a32"))
		var x := 0.0
		var i := 0
		while x < w:   # לוחות שיש בשביל
			var sw := 58.0 + float(i % 3) * 6.0
			var c := Color("5a5a64").darkened(0.06 * float(i % 2))
			DrawBatch.rect(self, Rect2(x + 1, 0, sw - 2, 20), c)
			DrawBatch.line(self, Vector2(x + 1, 1), Vector2(x + sw - 1, 1), Color("7a7a86"), 1.0)
			if i % 3 == 1:   # סדק
				DrawBatch.polyline(self, PackedVector2Array([Vector2(x + 12, 2), Vector2(x + 20, 9), Vector2(x + 17, 14), Vector2(x + 26, 19)]), Color("26262e"), 1.0)
			x += sw
			i += 1
		DrawBatch.rect(self, Rect2(0, 20, w, 6), Color("1e2a20"))   # שוליים עם עשב
		for q in int(w / 9.0):
			DrawBatch.line(self, Vector2(float(q) * 9.0 + 3.0, 22), Vector2(float(q) * 9.0 + 5.0, 16 + float(q % 3)), Color("2a3a2a"), 1.0)


# ---- מאוזוליאום (הגג = קומה שנייה) ----
class Mausoleum extends Node2D:
	var w := 330.0
	var tier := 150.0
	var seed_v := 0

	func _ready() -> void:
		z_index = -1

	func _draw() -> void:
		DrawBatch.begin(self)
		_draw_b()
		DrawBatch.end(self)

	func _draw_b() -> void:
		var c := MARBLE.darkened(0.25)
		DrawBatch.rect(self, Rect2(0, -tier, w, tier), c)
		for q in int(w / 30.0):   # אבני שיש
			DrawBatch.line(self, Vector2(float(q) * 30.0, -tier + 14.0), Vector2(float(q) * 30.0, 0), c.darkened(0.12), 1.0)
		for q in 4:
			DrawBatch.line(self, Vector2(0, -tier + 14.0 + float(q) * 34.0), Vector2(w, -tier + 14.0 + float(q) * 34.0), c.darkened(0.1), 1.0)
		# כרכוב + גג
		DrawBatch.rect(self, Rect2(-8, -tier - 4.0, w + 16, 14.0), MARBLE.darkened(0.1))
		DrawBatch.rect(self, Rect2(-8, -tier + 10.0, w + 16, 3.0), MARBLE_D.darkened(0.3))
		# עמודים
		for px: float in [14.0, w * 0.5 - 70.0, w * 0.5 + 56.0, w - 30.0]:
			DrawBatch.rect(self, Rect2(px, -tier + 14.0, 16.0, tier - 14.0), MARBLE.darkened(0.12))
			DrawBatch.rect(self, Rect2(px - 3, -tier + 14.0, 22.0, 6.0), MARBLE)
			DrawBatch.rect(self, Rect2(px - 3, -8.0, 22.0, 8.0), MARBLE)
			DrawBatch.line(self, Vector2(px + 5, -tier + 22.0), Vector2(px + 5, -10.0), MARBLE_D, 1.0)
		# דלת ברזל עם קשת וזכוכית
		var cx := w * 0.5
		DrawBatch.rect(self, Rect2(cx - 40, -96, 80, 96), Color("0e0c12"))
		DrawBatch.circle(self, Vector2(cx, -96), 40.0, Color("0e0c12"))
		DrawBatch.rect(self, Rect2(cx - 34, -92, 68, 92), Color("1a1820"))
		for q in 7:
			DrawBatch.line(self, Vector2(cx - 30.0 + float(q) * 10.0, -92), Vector2(cx - 30.0 + float(q) * 10.0, 0), IRON, 2.0)
		DrawBatch.line(self, Vector2(cx, -92), Vector2(cx, 0), IRON, 3.0)
		for q in 3:
			DrawBatch.arc(self, Vector2(cx, -60.0 + float(q) * 22.0), 8.0, 0.0, TAU, 10, Color("3a3440"), 1.2)
		DrawBatch.arc(self, Vector2(cx, -96), 34.0, PI, TAU, 16, Color("3a3440"), 2.0)
		DrawBatch.rect(self, Rect2(cx - 2, -50, 4, 6), Color("8a7a40"))   # מנעול
		# שם המשפחה על המשקוף
		DrawBatch.rect(self, Rect2(cx - 60, -tier + 22.0, 120, 18), MARBLE.darkened(0.05))
		var names := ["FAMILIA PAZ", "FAMILIA ROCA", "FAMILIA ALVEAR", "FAMILIA DORREGO", "FAMILIA SOLER"]
		DrawBatch.string(self, ThemeDB.fallback_font, Vector2(cx - 52, -tier + 36.0), names[seed_v % names.size()], HORIZONTAL_ALIGNMENT_CENTER, 104, 11, Color("3a3640"))
		# מלאכים על הגג (רק בצדדים - שלא יפריעו לעמוד על הגג)
		S50._angel(self, Vector2(10, -tier - 4.0), 1.0, MARBLE.darkened(0.08), 0.0, seed_v)
		S50._angel(self, Vector2(w - 10, -tier - 4.0), 1.0, MARBLE.darkened(0.08), 0.0, seed_v + 1)
		# כתמי טחב ונרות בפתח
		for q in 4:
			DrawBatch.colored_polygon(self, Art.ellipse(Vector2(30.0 + float(q) * (w - 60.0) / 3.0, -tier + 50.0 + float(q % 2) * 40.0), 14.0, 8.0, 0.0, 10), Color(0.2, 0.3, 0.2, 0.25))
		for q in 2:
			var vx := cx - 52.0 + float(q) * 104.0
			DrawBatch.rect(self, Rect2(vx - 2, -12, 4, 12), Color("e8e0d0"))
			Art.glow(self, Vector2(vx, -16), 16.0, Color(1.0, 0.7, 0.3, 0.35))
			DrawBatch.circle(self, Vector2(vx, -14), 1.8, Color(1.0, 0.85, 0.5))



# ---- מלאך שיש שנופל ----
class AngelStatue extends Node2D:
	const WARN_T := 0.8
	const NEAR := 150.0             # כמה קרוב השחקן צריך להיות כדי שהמלאך "יטה" אליו
	const FALL_L := 150.0           # אורך הפסל כשהוא שוכב
	const FALL_T := 0.45
	const DMG := 2
	const DMG_Z := 70
	var state := 0                  # 0 = עומד, 1 = נסדק (אזהרה), 2 = נופל, 3 = שוכב
	var dir := 1.0                  # לאיזה צד הוא נופל
	var falls := 0                  # לבדיקות
	var hits := 0
	var crushed := 0
	var shot := false
	var _t := 0.0
	var _ang := 0.0
	var _base: StaticBody2D = null

	class Base extends StaticBody2D:   # הכן - ירייה בו מפילה את המלאך לכיוון הירייה
		var a = null
		func hit_by_bullet(_p: Vector2, _n: Vector2, d: Vector2) -> void:
			if a != null and a.state == 0:
				a.shot = true
				a.dir = signf(d.x) if d.x != 0.0 else 1.0
				a._warn(0.25)

	func _ready() -> void:
		z_index = 3
		add_to_group("hazards")
		var b := Base.new()
		b.a = self
		b.collision_layer = 4   # כדורים פוגעים (כמו בזומבי), אף אחד לא נתקע בו
		b.collision_mask = 0
		var cs := CollisionShape2D.new()
		var sh := RectangleShape2D.new()
		sh.size = Vector2(40, 46)
		cs.shape = sh
		cs.position = Vector2(0, -23)
		b.add_child(cs)
		add_child(b)
		_base = b

	func world_rect() -> Rect2:
		var x0 := global_position.x if dir > 0.0 else global_position.x - FALL_L - 20.0
		return Rect2(Vector2(x0, global_position.y - 60.0), Vector2(FALL_L + 20.0, 60.0))

	func danger_at(p: Vector2, margin := 0.0) -> bool:
		return (state == 1 or state == 2) and world_rect().grow(margin).has_point(p)

	func _warn(t: float) -> void:
		state = 1
		_t = t
		preload("res://sfx.gd").play("rc_crack", global_position + Vector2(0, -100), -1.0, 0.1, 2)

	func _physics_process(delta: float) -> void:
		match state:
			0:
				if Engine.get_physics_frames() % 6 == 0:
					var pl := get_tree().get_first_node_in_group("player")
					if pl != null and not pl.dead and absf(pl.global_position.x - global_position.x) < NEAR and absf(pl.global_position.y - global_position.y) < 40.0:
						dir = signf(pl.global_position.x - global_position.x + 0.01)
						_warn(WARN_T)
			1:
				_t -= delta
				if _t <= 0.0:
					state = 2
					_t = FALL_T
					falls += 1
					preload("res://sfx.gd").play("rc_creak", global_position + Vector2(0, -100), 0.0, 0.1, 2)
			2:
				_t -= delta
				var k := clampf(1.0 - _t / FALL_T, 0.0, 1.0)
				_ang = dir * k * k * PI * 0.5
				if _t <= 0.0:
					state = 3
					_ang = dir * PI * 0.5
					_land()
		if state != 3 or Engine.get_physics_frames() % 30 == 0:
			if Art.on_screen(self, global_position + Vector2(0, -80), 200.0):
				queue_redraw()

	func _land() -> void:
		preload("res://sfx.gd").play("rc_smash", global_position + Vector2(dir * FALL_L * 0.6, 0), 2.0, 0.1, 2)
		var cam := get_viewport().get_camera_2d()
		if cam != null and cam.has_method("shake") and Art.on_screen(self, global_position):
			cam.shake(6.0, 0.25)
		var r := world_rect()
		for i in 5:
			preload("res://particles.gd").burst(get_parent(), global_position + Vector2(dir * (30.0 + float(i) * 28.0), -6), "smoke", Vector2.UP, 3)
		var pl := get_tree().get_first_node_in_group("player")
		if pl != null and not pl.dead and r.intersects(pl.body_rect()):
			hits += 1
			pl.hurt(DMG, Vector2(dir * 1.5, -0.6))
		for z in get_tree().get_nodes_in_group("zombies"):
			if not z.dead and not z.is_boss() and r.has_point(z.global_position + Vector2(0, -10)):
				crushed += 1
				z.take_damage(DMG_Z, z.global_position + Vector2(0, -20), Vector2(dir, 0.5), true, {"source": "hazard", "fixed": DMG_Z})
		if is_instance_valid(_base):
			_base.queue_free()

	func _draw() -> void:
		DrawBatch.begin(self)
		_draw_b()
		DrawBatch.end(self)

	func _draw_b() -> void:
		# הכן
		var c := MARBLE.darkened(0.15)
		if state < 3:
			DrawBatch.rect(self, Rect2(-20, -46, 40, 46), c)
			DrawBatch.rect(self, Rect2(-24, -50, 48, 6), MARBLE)
			DrawBatch.rect(self, Rect2(-24, -6, 48, 6), MARBLE.darkened(0.25))
			DrawBatch.string(self, ThemeDB.fallback_font, Vector2(-16, -22), "R.I.P", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("4a4650"))
		else:   # הכן שבור
			DrawBatch.colored_polygon(self, PackedVector2Array([Vector2(-20, 0), Vector2(-20, -30), Vector2(-8, -38), Vector2(4, -28), Vector2(20, -34), Vector2(20, 0)]), c)
		# המלאך (מסתובב סביב בסיס הרגליים)
		var piv := Vector2(dir * 6.0, -50.0) if state >= 2 else Vector2(0, -50.0)
		if state == 3:
			piv = Vector2(dir * 14.0, -10.0)
		var shake := sin(_t * 70.0) * 2.0 if state == 1 else 0.0
		DrawBatch.set_transform(self, piv + Vector2(shake, 0), _ang, Vector2.ONE)
		var off := Vector2(-dir * 6.0, 0.0) if state >= 2 else Vector2.ZERO
		var mc := MARBLE.darkened(0.05)
		var wing := MARBLE.darkened(0.2)
		# כנפיים
		DrawBatch.colored_polygon(self, PackedVector2Array([off + Vector2(-4, -70), off + Vector2(-40, -120), off + Vector2(-46, -90), off + Vector2(-30, -60), off + Vector2(-12, -46)]), wing)
		DrawBatch.colored_polygon(self, PackedVector2Array([off + Vector2(4, -70), off + Vector2(40, -120), off + Vector2(46, -90), off + Vector2(30, -60), off + Vector2(12, -46)]), wing)
		for q in 3:
			DrawBatch.line(self, off + Vector2(-10 - float(q) * 9.0, -64 - float(q) * 10.0), off + Vector2(-26 - float(q) * 6.0, -58 - float(q) * 6.0), MARBLE_D, 1.0)
			DrawBatch.line(self, off + Vector2(10 + float(q) * 9.0, -64 - float(q) * 10.0), off + Vector2(26 + float(q) * 6.0, -58 - float(q) * 6.0), MARBLE_D, 1.0)
		# גלימה
		Art.fill(self, PackedVector2Array([off + Vector2(-16, 0), off + Vector2(16, 0), off + Vector2(10, -50), off + Vector2(6, -76), off + Vector2(-6, -76), off + Vector2(-10, -50)]), mc, Color(0.1, 0.1, 0.12), 1.0)
		for q in 4:
			DrawBatch.line(self, off + Vector2(-8 + float(q) * 5.0, -48), off + Vector2(-11 + float(q) * 7.0, -2), MARBLE_D, 1.0)
		# ידיים משולבות + ראש מורכן
		DrawBatch.line(self, off + Vector2(-6, -66), off + Vector2(3, -58), mc.darkened(0.1), 4.0)
		DrawBatch.line(self, off + Vector2(6, -66), off + Vector2(-2, -58), mc.darkened(0.1), 4.0)
		Art.disc(self, off + Vector2(2, -84), 8.0, mc, Color(0.1, 0.1, 0.12), 1.0)
		DrawBatch.line(self, off + Vector2(-3, -86), off + Vector2(6, -84), MARBLE_D, 1.0)   # עיניים עצומות
		DrawBatch.line(self, off + Vector2(-2, -94), off + Vector2(8, -92), Color(0.8, 0.85, 0.9, 0.3), 2.0)
		if state == 1:   # סדקים
			DrawBatch.polyline(self, PackedVector2Array([off + Vector2(-8, -10), off + Vector2(-2, -24), off + Vector2(-6, -34), off + Vector2(2, -46)]), Color(0.1, 0.1, 0.1), 1.4)
		DrawBatch.set_transform_matrix(self, Transform2D.IDENTITY)
		if state == 1:
			DrawBatch.string(self, ThemeDB.fallback_font, Vector2(-6, -140), "!", HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color(1.0, 0.4, 0.2))


# ---- קריפטה עם דלת שנפרצת ----
class CryptDoor extends Node2D:
	const WARN_T := 1.0
	const NEAR := 190.0
	const BLAST_R := 120.0
	const RELEASE := 2              # כמה מתים יוצאים
	const DMG := 1
	var state := 0                  # 0 = סגורה, 1 = רועדת, 2 = נפרצה
	var bursts := 0                 # לבדיקות
	var hits := 0
	var released := 0
	var _t := 0.0
	var _open := 0.0

	func _ready() -> void:
		z_index = -1
		add_to_group("hazards")

	func world_rect() -> Rect2:
		return Rect2(global_position + Vector2(-BLAST_R, -110), Vector2(BLAST_R * 2.0, 110))

	func danger_at(p: Vector2, margin := 0.0) -> bool:
		return state == 1 and world_rect().grow(margin).has_point(p)

	func _physics_process(delta: float) -> void:
		match state:
			0:
				if Engine.get_physics_frames() % 6 == 0:
					var pl := get_tree().get_first_node_in_group("player")
					if pl != null and not pl.dead and absf(pl.global_position.x - global_position.x) < NEAR and absf(pl.global_position.y - global_position.y) < 60.0:
						state = 1
						_t = WARN_T
						preload("res://sfx.gd").play("rc_rattle", global_position + Vector2(0, -50), 0.0, 0.1, 2)
			1:
				_t -= delta
				if _t <= 0.0:
					_burst()
			2:
				_open = minf(_open + delta * 4.0, 1.0)
		if state == 1 or (state == 2 and _open < 1.0):
			queue_redraw()

	func _burst() -> void:
		state = 2
		bursts += 1
		preload("res://sfx.gd").play("rc_burst", global_position + Vector2(0, -50), 3.0, 0.1, 2)
		for i in 4:
			preload("res://particles.gd").burst(get_parent(), global_position + Vector2(-40.0 + float(i) * 26.0, -40), "smoke", Vector2(0, -0.5), 4)
		var pl := get_tree().get_first_node_in_group("player")
		if pl != null and not pl.dead and pl.global_position.distance_to(global_position + Vector2(0, -30)) < BLAST_R:
			hits += 1
			pl.hurt(DMG, Vector2(signf(pl.global_position.x - global_position.x + 0.01) * 2.2, -0.8))
		var main := get_parent()
		if main != null and main.has_method("_spawn_zombie"):
			for i in RELEASE:
				var nz = main._spawn_zombie(global_position.x - 14.0 + float(i) * 28.0, global_position.y, i % 2)
				if nz != null:
					released += 1
					nz._alert_t = 6.0
					nz.velocity = Vector2((-1.0 if i == 0 else 1.0) * 120.0, -200.0)

	func _draw() -> void:
		DrawBatch.begin(self)
		_draw_b()
		DrawBatch.end(self)

	func _draw_b() -> void:
		var c := MARBLE.darkened(0.3)
		# בית הקריפטה הקטן
		DrawBatch.rect(self, Rect2(-70, -130, 140, 130), c)
		DrawBatch.colored_polygon(self, PackedVector2Array([Vector2(-80, -130), Vector2(0, -164), Vector2(80, -130)]), c.lightened(0.05))
		DrawBatch.rect(self, Rect2(-80, -134, 160, 6), MARBLE.darkened(0.1))
		DrawBatch.line(self, Vector2(0, -164), Vector2(0, -190), IRON, 3.0)
		DrawBatch.line(self, Vector2(-9, -180), Vector2(9, -180), IRON, 3.0)
		DrawBatch.string(self, ThemeDB.fallback_font, Vector2(-60, -114), "CRIPTA", HORIZONTAL_ALIGNMENT_CENTER, 120, 11, Color("3a3640"))
		DrawBatch.rect(self, Rect2(-44, -100, 88, 100), Color("050407"))
		if state == 2:   # מבפנים: חושך וענן
			Art.glow(self, Vector2(0, -50), 40.0, Color(0.4, 0.5, 0.7, 0.2 * (1.0 - _open * 0.5)))
		var sh := sin(_t * 60.0) * 2.5 if state == 1 else 0.0
		var oa := _open * 1.3
		for s: float in [-1.0, 1.0]:   # שתי כנפות הדלת
			var hinge := Vector2(s * 44.0, 0)
			var w := 44.0 * cos(oa)
			var x0 := hinge.x - s * w
			var rx := minf(hinge.x, x0)
			DrawBatch.rect(self, Rect2(rx + sh * (1.0 - _open), -100, absf(w), 100), Color("1c1a22"))
			for q in 4:
				var bx := lerpf(hinge.x, x0, (float(q) + 0.5) / 4.0) + sh * (1.0 - _open)
				DrawBatch.line(self, Vector2(bx, -96), Vector2(bx, -4), IRON, 2.0)
			DrawBatch.line(self, Vector2(rx + sh, -50), Vector2(rx + absf(w) + sh, -50), IRON, 2.0)
		if state < 2:
			DrawBatch.line(self, Vector2(-6 + sh, -54), Vector2(6 + sh, -46), Color("8a7a40"), 3.0)   # שרשרת + מנעול
			DrawBatch.line(self, Vector2(-6 + sh, -46), Vector2(6 + sh, -54), Color("8a7a40"), 3.0)
			DrawBatch.rect(self, Rect2(-4 + sh, -48, 8, 9), Color("a08a40"))
		if state == 1:
			for q in 3:   # אבק נושר מהמשקוף
				DrawBatch.circle(self, Vector2(-30.0 + float(q) * 30.0 + sh, -100.0 + fposmod(_t * 160.0 + float(q) * 20.0, 40.0)), 1.5, Color(0.7, 0.7, 0.7, 0.6))
			DrawBatch.string(self, ThemeDB.fallback_font, Vector2(-6, -200), "!", HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color(1.0, 0.4, 0.2))


# ---- השער של רקולטה (מאחורי הבוס) ----
class RecoletaGate extends Node2D:
	func _ready() -> void:
		z_index = -2

	func _draw() -> void:
		DrawBatch.begin(self)
		_draw_b()
		DrawBatch.end(self)

	func _draw_b() -> void:
		var c := MARBLE.darkened(0.2)
		DrawBatch.rect(self, Rect2(-260, -300, 520, 300), c.darkened(0.15))
		# פרונטון יווני
		DrawBatch.colored_polygon(self, PackedVector2Array([Vector2(-290, -300), Vector2(0, -380), Vector2(290, -300)]), c)
		DrawBatch.colored_polygon(self, PackedVector2Array([Vector2(-250, -306), Vector2(0, -368), Vector2(250, -306)]), c.darkened(0.1))
		DrawBatch.rect(self, Rect2(-300, -312, 600, 14), MARBLE)
		DrawBatch.string(self, ThemeDB.fallback_font, Vector2(-200, -320), "REQUIESCANT IN PACE", HORIZONTAL_ALIGNMENT_CENTER, 400, 18, Color("2a2832"))
		for q in 4:   # עמודים דוריים
			var px := -230.0 + float(q) * 140.0 + (40.0 if q >= 2 else 0.0)
			DrawBatch.rect(self, Rect2(px, -298, 44, 298), MARBLE.darkened(0.08))
			for k in 4:
				DrawBatch.line(self, Vector2(px + 6.0 + float(k) * 10.0, -290), Vector2(px + 6.0 + float(k) * 10.0, -10), MARBLE_D, 1.2)
			DrawBatch.rect(self, Rect2(px - 6, -304, 56, 10), MARBLE)
			DrawBatch.rect(self, Rect2(px - 6, -10, 56, 10), MARBLE.darkened(0.2))
		# שער ברזל במרכז
		DrawBatch.rect(self, Rect2(-60, -240, 120, 240), Color("06050a"))
		for q in 9:
			DrawBatch.line(self, Vector2(-56.0 + float(q) * 14.0, -236), Vector2(-56.0 + float(q) * 14.0, 0), IRON.lightened(0.1), 2.5)
			DrawBatch.colored_polygon(self, PackedVector2Array([Vector2(-60.0 + float(q) * 14.0, -236), Vector2(-56.0 + float(q) * 14.0, -246), Vector2(-52.0 + float(q) * 14.0, -236)]), IRON.lightened(0.1))
		DrawBatch.arc(self, Vector2(0, -150), 34.0, 0.0, TAU, 20, IRON.lightened(0.15), 3.0)
		DrawBatch.line(self, Vector2(0, -184), Vector2(0, -116), IRON.lightened(0.15), 3.0)
		DrawBatch.line(self, Vector2(-22, -160), Vector2(22, -160), IRON.lightened(0.15), 3.0)
		for s: float in [-1.0, 1.0]:   # לפידים
			var tx := s * 120.0
			DrawBatch.line(self, Vector2(tx, -150), Vector2(tx, -180), IRON, 4.0)
			var fl := 0.7 + 0.3 * sin(float(Engine.get_process_frames()) * 0.3 + s)
			Art.glow(self, Vector2(tx, -192), 40.0, Color(1.0, 0.6, 0.25, 0.3 * fl))
			DrawBatch.colored_polygon(self, PackedVector2Array([Vector2(tx - 6, -182), Vector2(tx + 6, -182), Vector2(tx, -200 - 6.0 * fl)]), Color(1.0, 0.6, 0.2, 0.9))


# ---- מכשולים ----
class Obstacle extends Node2D:
	var kind := "grave"
	var size := Vector2(50, 60)
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
		var c := MARBLE.darkened(0.3 + 0.05 * float(seed_v % 3))
		match kind:
			"grave":   # מצבה מעוגלת עם צלב ופרחים מתים
				DrawBatch.rect(self, Rect2(0, -h * 0.75, w, h * 0.75), c)
				DrawBatch.circle(self, Vector2(w * 0.5, -h * 0.75), w * 0.5, c)
				DrawBatch.rect(self, Rect2(-3, -6, w + 6, 6), c.darkened(0.2))
				DrawBatch.line(self, Vector2(w * 0.5, -h * 0.9), Vector2(w * 0.5, -h * 0.45), c.darkened(0.3), 3.0)
				DrawBatch.line(self, Vector2(w * 0.3, -h * 0.76), Vector2(w * 0.7, -h * 0.76), c.darkened(0.3), 3.0)
				DrawBatch.polyline(self, PackedVector2Array([Vector2(w * 0.15, -h * 0.3), Vector2(w * 0.3, -h * 0.4), Vector2(w * 0.25, -h * 0.55)]), Color(0.1, 0.1, 0.1, 0.5), 1.0)
				for q in 3:
					DrawBatch.circle(self, Vector2(w * 0.2 + float(q) * 6.0, -8), 2.5, Color("5a2030"))
			"sarcophagus":   # ארון אבן עם מכסה מגולף
				DrawBatch.rect(self, Rect2(0, -h * 0.8, w, h * 0.8), c)
				DrawBatch.colored_polygon(self, PackedVector2Array([Vector2(-4, -h * 0.8), Vector2(w * 0.5, -h), Vector2(w + 4, -h * 0.8)]), c.lightened(0.08))
				for q in 3:
					DrawBatch.rect(self, Rect2(8.0 + float(q) * (w - 16.0) / 3.0, -h * 0.65, (w - 24.0) / 3.0, h * 0.45), c.darkened(0.1))
				DrawBatch.line(self, Vector2(w * 0.5, -h * 0.98), Vector2(w * 0.5, -h * 0.82), c.darkened(0.3), 2.0)
			_:   # כד אבן על כן עם קיסוס
				DrawBatch.rect(self, Rect2(w * 0.25, -h * 0.45, w * 0.5, h * 0.45), c)
				DrawBatch.rect(self, Rect2(w * 0.15, -h * 0.5, w * 0.7, 6), c.lightened(0.1))
				DrawBatch.colored_polygon(self, Art.ellipse(Vector2(w * 0.5, -h * 0.72), w * 0.4, h * 0.24, 0.0, 14), c.lightened(0.05))
				DrawBatch.rect(self, Rect2(w * 0.2, -h * 0.98, w * 0.6, 6), c.lightened(0.1))
				for q in 6:   # קיסוס
					DrawBatch.circle(self, Vector2(w * 0.3 + sin(float(q) * 1.9) * w * 0.15, -h * 0.4 - float(q) * h * 0.08), 3.2, Color("1e3424"))


# ============================================================
#  מחזור הירח (אחד לשלב). LOBIZON שואל S50.moon_full() / moon_rising()
# ============================================================
class MoonCycle extends Node:
	const CLOUD_T := Vector2(14.0, 19.0)
	const WARN_T := 3.0
	const FULL_T := 11.0
	var state := 0                  # 0 = עננים, 1 = אזהרה, 2 = ירח מלא
	var fulls := 0                  # לבדיקות
	var _t := 9.0

	func _ready() -> void:
		add_to_group("moon_cycle")
		S50.active = true
		S50.full_now = false
		S50.moon_k = 0.0
		S50.moon_warn = 0.0

	func _exit_tree() -> void:
		S50.active = false
		S50.full_now = false
		S50.moon_k = 0.0
		S50.moon_warn = 0.0

	func force(s: int, t := 4.0) -> void:   # (לבדיקות)
		state = s
		_t = t

	func _physics_process(delta: float) -> void:
		_t -= delta
		match state:
			0:
				S50.moon_k = move_toward(S50.moon_k, 0.0, delta * 0.8)
				S50.moon_warn = 0.0
				if _t <= 0.0:
					state = 1
					_t = WARN_T
					preload("res://sfx.gd").play("rc_howl", null, -6.0)
			1:
				S50.moon_warn = _t
				S50.moon_k = move_toward(S50.moon_k, 0.25, delta * 0.2)
				if _t <= 0.0:
					state = 2
					_t = FULL_T
					fulls += 1
					S50.moon_warn = 0.0
					Game.story.emit("thunder", {})
			2:
				S50.moon_k = move_toward(S50.moon_k, 1.0, delta * 1.5)
				if _t <= 0.0:
					state = 0
					_t = randf_range(CLOUD_T.x, CLOUD_T.y)
		S50.full_now = state == 2   # (אחרי המעבר - אין פריים "חור" בין האזהרה לירח המלא)


static func moon_full() -> bool:
	return active and full_now


static func moon_rising() -> bool:
	return active and moon_warn > 0.0


# ============================================================
#  מסך: ערפל קרקע, אור הירח, והבאנר של הירח
# ============================================================
class MoonFX extends Node2D:
	var vp := Vector2(1280, 720)
	var _t := 0.0

	func _process(delta: float) -> void:
		_t += delta
		if Engine.get_process_frames() % 2 == 0:
			queue_redraw()

	func _draw() -> void:
		DrawBatch.begin(self)
		_draw_b()
		DrawBatch.end(self)

	func _draw_b() -> void:
		var k := S50.moon_k
		# חושך כשהירח מכוסה, אור כסוף כשהוא מלא
		DrawBatch.rect(self, Rect2(0, 0, vp.x, vp.y), Color(0.03, 0.04, 0.12, 0.2 * (1.0 - k)))
		if k > 0.05:
			DrawBatch.rect(self, Rect2(0, 0, vp.x, vp.y), Color(0.55, 0.6, 0.85, 0.06 * k))
		var n: int = Quality.scaled(16, Quality.ambient())
		for i in n:   # ערפל קרקע שזוחל
			var x := fposmod(float(i) * 127.0 + _t * (9.0 + float(i % 4) * 4.0), vp.x + 320.0) - 160.0
			var y := vp.y * 0.82 + sin(_t * 0.35 + float(i)) * 14.0 + float(i % 4) * 12.0
			DrawBatch.colored_polygon(self, Art.ellipse(Vector2(x, y), 140.0, 20.0, 0.0, 14), Color(0.65, 0.7, 0.9, 0.05 + 0.03 * k))
		var f: Font = ThemeDB.fallback_font
		if S50.moon_warn > 0.0:
			var a := 0.55 + 0.45 * sin(_t * 8.0)
			DrawBatch.string(self, f, Vector2(0, vp.y * 0.28), "THE CLOUDS ARE PARTING...", HORIZONTAL_ALIGNMENT_CENTER, vp.x, 26, Color(0.8, 0.88, 1.0, a))
		elif k > 0.8:
			var a2 := clampf((1.0 - k) * 10.0 + 0.0, 0.0, 1.0)
			var mc := get_tree().get_first_node_in_group("moon_cycle")
			if mc != null and mc.state == 2 and mc._t > MoonCycle.FULL_T - 2.0:
				DrawBatch.string(self, f, Vector2(0, vp.y * 0.28), "FULL MOON", HORIZONTAL_ALIGNMENT_CENTER, vp.x, 30, Color(1.0, 0.95, 0.75, 0.9 - a2 * 0.3))
