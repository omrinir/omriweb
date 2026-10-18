extends RefCounted
const DrawBatch := preload("res://effects/draw_batch.gd")   # כל הציור של זומבי ב-draw call אחד
# ============================================================
#  קישוטים לשלב 57 ("PENGUIN COAST") - אזור שביעי (פטגוניה), שלב 3. "THEY LEARNED TO BE MANY".
#  חוף קר וסוער בסוף העולם: מושבת פינגווינים, חוף חלוקים, אצות ענק, מגדלור אדום-לבן ישן, תחנת ציד לווייתנים הרוסה.
#    coast_sky     - (רקע) שמיים מעוננים וכבדים, פס אור חיוור מעל הים, קרני שמש שזזות, עננים שנקרעים ברוח,
#                    שחפים ויסעורים שדואים ברוח (חלקם נגררים אחורה במשב)
#    far_coast     - (רקע, 0.06) הרי טיירה דל פואגו המושלגים, צוקים, קרחונים צפים באופק, ספינת ציד חלודה שנטרפה,
#                    מגדלור רחוק שמהבהב
#    mid_bay       - (רקע, 0.28) המפרץ: גלים מתגלגלים ונשברים על סלעים, אריות ים ופינגווינים על הסלעים, יערות אצות,
#                    ונחיל ציפורים רחוק שמשנה צורה (רמז ל-MURMUR). כאן גם הפנים הענקיות של סצנת THE CHORUS (U.face_ms).
#    near_shore    - (רקע, 0.6) סוללת חלוקים מאחורי הדרך: עשב טוסוק ברוח, צלעות לווייתן, סירות הפוכות, שרשראות עוגן,
#                    מחילות פינגווינים עם ראשים שמציצים, שחפים הולכים
#    BeachGround   - (עולם) חול רטוב, חלוקים, קונכיות, אצות שנפלטו, קו קצף
#    Colony        - (עולם, קבוצה "s57_colonies") מושבת פינגווינים חיה: מתגודדים (HUDDLE), נבהלים מיריות / פגיעה / פיצוץ /
#                    מגע (SCATTER: בורחים, מחליקים על הבטן, נופלים), ומתקבצים שוב (REGROUP). כשהם מתגודדים - "מגן":
#                    כדור שנכנס לצפיפות פוגע בפינגווין (לא הורג - הוא נופל, נוצות, והמושבה מתפזרת). אין ניקוד על פינגווינים.
#                    WADDLER מתחבא בתוכה (enemies/types/waddler.gd).
#    Lighthouse    - (עולם) המגדלור: מגדל פסים אדום-לבן, חדר עדשה עם אלומה מסתובבת, בית השומר. קומות: גג הבית + המרפסת.
#    Tank          - (עולם) מיכל שמן לווייתנים חלוד עם מסלול על הגג (קומה)
#    Gantry        - (עולם) עגורן הפשטה של תחנת הציד (קומה), ממנו תלוי ה-GantryHook
#    WhaleSkeleton - (עולם) שלד לווייתן ענק מעל הדרך, קרש הליכה על עמוד השדרה (קומה)
#    OilBurst      - (עולם, מלכודת) מיכל שמן קטן על הדרך: יורים בו (או פיצוץ) -> שמן פורץ -> כתם (Slick) -> נדלק (FireZone)
#    Slick         - (עולם, קבוצה "s57_slicks") כתם שמן לווייתנים / שומן BLUBBER: חלק (מחליקים), נדלק מאש / פיצוץ / זומבי בוער
#    GantryHook    - (עולם, מלכודת) וו ענק על שרשרת: אתה מתחתיו -> שקשוק + נמשך לאחור (WIND_T) -> נשמט ומתנדנד לרוחב הדרך.
#                    פוגע בך, משפד זומבים. ירייה בגלגלת = מתנדנד מתי שתבחר.
#    WaveSurge     - (עולם, מלכודת) קטע חוף שהים שוטף: גל מתרומם מאחור (WARN_T, שאגה) -> גל מציף את הדרך (SURGE_T): דוחף
#                    אותך אחורה ומחליק, מפיל זומבים, מכבה כתמים בוערים. על קומה / בקפיצה - לא נוגע בך.
#    SlickRocks    - (עולם, מלכודת) סלעים שטוחים רטובים עם אצות: מחליקים עליהם, זומבים מועדים
#    Obstacle      - (מוצק + מחסה) "drums" חביות שמן חלודות / "boat" סירת משוטים הפוכה / "boulders" סלעים / "vertebra" חוליות
#    BossBeach     - (עולם) חוף ה-BEACHMASTER בסוף: סלעי מנוחה, מסילת גרירה, גולגולת לווייתן, שלט התחנה
#    CoastFX       - (מסך) רוח, רסס ים, פתיתי שלג, משב (gust())
#  לשנות: Colony.SCATTER_T / REGROUP_T / HEAR_R / TOUCH_R, OilBurst.SPREAD / IGNITE_T / BURN_T, Slick.SLIP,
#         GantryHook.TRIG_R / WIND_T / SWING_T / DMG / DMG_Z / CD, WaveSurge.CD / WARN_T / SURGE_T / PUSH,
#         SlickRocks.STUMBLE.
# ============================================================

const Art := preload("res://art.gd")
const Sfx := preload("res://sfx.gd")
const Kit := preload("res://effects/backdrop_kit.gd")
const Particles := preload("res://particles.gd")
const FireZone := preload("res://environment/fire_zone.gd")

const SAND := Color("8a7c66")
const SAND_D := Color("5e5446")
const SAND_WET := Color("4e4a44")
const PEBBLE := Color("6e6a66")
const SEA := Color("3e5866")
const SEA_D := Color("243642")
const FOAM := Color("e8eef0")
const RUST := Color("8a4428")
const RUST_D := Color("4e2616")
const RUST_L := Color("b8643a")
const BONE := Color("d8ccb0")
const BONE_D := Color("9a8c70")
const RED_LH := Color("c02a24")
const WHITE_LH := Color("eae6dc")
const KELP := Color("4a5228")
const KELP_L := Color("7a7a34")
const TUSSOCK := Color("9a8a4a")


# מצב משותף (סצנת הסיפור) + עזרים - מחלקה פנימית לא רואה פונקציות סטטיות של הקובץ
class U:
	static var face_ms := -1        # "flock_form": הפנים מתחילות להיווצר מעל הים
	static var break_ms := -1       # "flock_break": הפנים מתפרקות ועפות
	static var talk := 0.0          # (סצנה) הפה של הפנים זז

	static func h(i: int, s: int) -> float:
		return fposmod(sin(float(i) * 12.9898 + float(s) * 78.233) * 43758.5453, 1.0)

	static func flush(ci: CanvasItem, pts: PackedVector2Array, cols: PackedColorArray) -> void:
		if not pts.is_empty():
			RenderingServer.canvas_item_add_triangle_array(ci.get_canvas_item(), PackedInt32Array(), pts, cols)

	static func quad(pts: PackedVector2Array, cols: PackedColorArray, a: Vector2, b: Vector2, c: Vector2, d: Vector2, ca: Color, cb: Color, cc: Color, cd: Color) -> void:
		pts.append_array([a, b, c, a, c, d])
		cols.append_array([ca, cb, cc, ca, cc, cd])

	static func rect(pts: PackedVector2Array, cols: PackedColorArray, r: Rect2, c: Color) -> void:
		pts.append_array([r.position, Vector2(r.end.x, r.position.y), r.end, r.position, r.end, Vector2(r.position.x, r.end.y)])
		cols.append_array([c, c, c, c, c, c])

	static func tri(pts: PackedVector2Array, cols: PackedColorArray, a: Vector2, b: Vector2, c: Vector2, col: Color) -> void:
		pts.append_array([a, b, c])
		cols.append_array([col, col, col])

	static func dia(pts: PackedVector2Array, cols: PackedColorArray, c: Vector2, r: float, col: Color) -> void:
		pts.append_array([c + Vector2(-r, 0), c + Vector2(0, -r), c + Vector2(r, 0), c + Vector2(-r, 0), c + Vector2(r, 0), c + Vector2(0, r)])
		cols.append_array([col, col, col, col, col, col])

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

	# ציפור קטנה עפה (גוף + 2 כנפיים מנפנפות) - משמש גם את MURMUR
	static func bird(pts: PackedVector2Array, cols: PackedColorArray, p: Vector2, s: float, flap: float, dir: float, col: Color) -> void:
		var w := 6.0 * s
		var up := sin(flap) * 4.5 * s
		pts.append_array([p + Vector2(-2.6 * s * dir, 0.4 * s), p + Vector2(3.4 * s * dir, -0.6 * s), p + Vector2(0.2 * s * dir, 1.6 * s)])
		pts.append_array([p + Vector2(-0.8 * s, 0), p + Vector2(0.9 * s, 0), p + Vector2(-w * 0.55 * dir, -up - 0.6 * s)])
		pts.append_array([p + Vector2(-0.8 * s, 0), p + Vector2(0.9 * s, 0), p + Vector2(w * 0.5 * dir, -up * 0.8 - 1.0 * s)])
		cols.append_array([col, col, col, col, col, col, col, col, col])


static func _h(i: int, s: int) -> float:
	return U.h(i, s)


static func _ms_since(ms: int) -> float:
	return -1.0 if ms < 0 else float(Time.get_ticks_msec() - ms) / 1000.0


# ============================================================
#  רקע
# ============================================================

# ---- שמיים מעוננים, קרני שמש, עננים קרועים, שחפים ----
static func coast_sky(ci: CanvasItem, v: Vector2, t: float) -> void:
	Kit.gradient_sky(ci, v, [Color("4a5868"), Color("66788a"), Color("8c9ca8"), Color("b8c2c4"), Color("d2d4cc")], 0.82)
	# פס אור חיוור מעל הים + השמש מאחורי העננים
	var sp := Vector2(v.x * 0.68, v.y * 0.36)
	Kit.soft_glow(ci, sp, 360.0, Color(1.0, 0.96, 0.84, 0.22), 0.55)
	Kit.soft_glow(ci, sp, 120.0, Color(1.0, 0.98, 0.9, 0.35))
	# קרני שמש שזזות לאט בין העננים
	var pts := PackedVector2Array()
	var cols := PackedColorArray()
	for i in 6:
		var a := 1.85 + float(i) * 0.16 + sin(t * 0.07 + float(i)) * 0.04
		var rl := 520.0 + _h(i, 3) * 200.0
		var w := 0.03 + _h(i, 4) * 0.025
		var al := (0.06 + 0.05 * sin(t * 0.3 + float(i) * 1.7)) * (0.6 + 0.4 * _h(i, 5))
		var p1 := sp + Vector2.from_angle(a - w) * rl
		var p2 := sp + Vector2.from_angle(a + w) * rl
		pts.append_array([sp, p1, p2])
		cols.append_array([Color(1.0, 0.97, 0.86, al), Color(1.0, 0.97, 0.86, 0.0), Color(1.0, 0.97, 0.86, 0.0)])
	U.flush(ci, pts, cols)
	# עננים כבדים ונמוכים שנקרעים ברוח (שמאלה)
	for i in 10:
		var spd := 14.0 + float(i) * 4.0
		var x := fposmod(_h(i, 8) * v.x * 1.8 - t * spd, v.x + 900.0) - 450.0
		var y := v.y * (0.04 + _h(i, 9) * 0.4)
		var rx := 220.0 + _h(i, 10) * 180.0
		var ry := 22.0 + _h(i, 11) * 30.0
		var dark := Color(0.3, 0.34, 0.4, 0.42 + 0.2 * _h(i, 12))
		Kit.soft_ellipse(ci, Vector2(x, y), rx, ry, 0.02, dark)
		Kit.soft_ellipse(ci, Vector2(x - rx * 0.5, y + ry * 0.4), rx * 0.5, ry * 0.7, -0.05, Color(dark, dark.a * 0.8))
		Kit.soft_ellipse(ci, Vector2(x + rx * 0.2, y - ry * 0.55), rx * 0.7, ry * 0.4, 0.0, Color(0.85, 0.88, 0.9, 0.18))   # שוליים מוארים
	# שחפים ויסעורים שדואים ברוח
	pts = PackedVector2Array()
	cols = PackedColorArray()
	for g in 3:
		var period := 30.0 + float(g) * 9.0
		var k := fmod(t / period + _h(g, 20), 1.0)
		var base := Vector2(lerpf(v.x + 120.0, -160.0, k) if g != 1 else lerpf(-160.0, v.x + 120.0, k), 90.0 + float(g) * 70.0 + sin(t * 0.4 + float(g)) * 20.0)
		for q in 5 + g * 2:
			var o := Vector2((_h(q, 21 + g) - 0.5) * 140.0, (_h(q, 31 + g) - 0.5) * 50.0)
			var s := 1.2 + _h(q, 41 + g) * 0.6 - float(g) * 0.2
			var dir := -1.0 if g != 1 else 1.0
			var col := Color(0.16, 0.18, 0.22, 0.8) if (q + g) % 3 != 0 else Color(0.94, 0.95, 0.96, 0.85)
			U.bird(pts, cols, base + o + Vector2(0, sin(t * 2.0 + float(q)) * 4.0), s, t * (5.0 + float(q % 3)) + float(q), dir, col)
	U.flush(ci, pts, cols)


# ---- הרים מושלגים, צוקים, קרחונים, ספינה טרופה, מגדלור רחוק ----
static func far_coast(ci: CanvasItem, sc: float, v: Vector2, y: float, t: float) -> void:
	var sea_top := y - 40.0
	var period := 2000.0
	var start := int(floor(sc / period)) - 1
	for k in range(start, start + int(ceil(v.x / period)) + 2):
		var bx := float(k) * period - sc
		# הרים רחוקים (כחול-אפור, שלג)
		var ridge := PackedVector2Array([Vector2(bx, sea_top)])
		var peaks := []
		for q in 21:
			var px := bx + float(q) * 100.0
			var hh := 30.0
			if q > 0 and q < 20:
				hh = (110.0 + _h(k * 23 + q, 1) * 120.0) if q % 2 == 1 else (50.0 + _h(k * 23 + q, 2) * 50.0)
			ridge.append(Vector2(px, sea_top - hh))
			if q % 2 == 1:
				peaks.append(Vector2(px, sea_top - hh))
		ridge.append(Vector2(bx + period, sea_top))
		DrawBatch.colored_polygon(ci, ridge, Color("7c8a9a"))
		for pk: Vector2 in peaks:
			DrawBatch.colored_polygon(ci, PackedVector2Array([pk, pk + Vector2(38, 34), pk + Vector2(16, 28), pk + Vector2(2, 40), pk + Vector2(-14, 27), pk + Vector2(-36, 34)]), Color("e4e8ec"))
			DrawBatch.line(ci, pk, pk + Vector2(36, 33), Color(0.5, 0.56, 0.66, 0.5), 1.4)
		# צוק כהה קרוב יותר עם מגדלור קטן
		var cx := bx + 1300.0
		DrawBatch.colored_polygon(ci, PackedVector2Array([Vector2(cx - 220, sea_top), Vector2(cx - 150, sea_top - 46), Vector2(cx - 40, sea_top - 70), Vector2(cx + 60, sea_top - 66), Vector2(cx + 110, sea_top - 30), Vector2(cx + 160, sea_top)]), Color("4e5866"))
		DrawBatch.line(ci, Vector2(cx - 40, sea_top - 70), Vector2(cx + 60, sea_top - 66), Color(0.8, 0.84, 0.88, 0.4), 1.5)
		DrawBatch.rect(ci, Rect2(cx + 6.0, sea_top - 98.0, 8.0, 30.0), Color("d8d4cc"))
		DrawBatch.rect(ci, Rect2(cx + 6.0, sea_top - 88.0, 8.0, 5.0), Color("a83a30"))
		DrawBatch.rect(ci, Rect2(cx + 4.0, sea_top - 104.0, 12.0, 6.0), Color("3a3e46"))
		var blink := 0.5 + 0.5 * sin(t * 2.2 + float(k))
		Kit.soft_glow(ci, Vector2(cx + 10.0, sea_top - 101.0), 18.0 + 14.0 * blink, Color(1.0, 0.9, 0.6, 0.5 * blink))
	# הים הרחוק
	DrawBatch.rect(ci, Rect2(0, sea_top, v.x, v.y - sea_top), Color("5a7280"))
	DrawBatch.line(ci, Vector2(0, sea_top), Vector2(v.x, sea_top), Color(0.86, 0.9, 0.92, 0.5), 1.5)
	var pts := PackedVector2Array()
	var cols := PackedColorArray()
	for i in 40:   # נצנוצים על המים
		var gx := fposmod(_h(i, 5) * 3000.0 - sc - t * (6.0 + _h(i, 6) * 6.0), v.x + 100.0) - 50.0
		var gy := sea_top + 3.0 + _h(i, 7) * 34.0
		var a := 0.15 + 0.25 * (0.5 + 0.5 * sin(t * 3.0 + float(i) * 2.3))
		U.quad(pts, cols, Vector2(gx, gy), Vector2(gx + 12.0, gy), Vector2(gx + 12.0, gy + 1.0), Vector2(gx, gy + 1.0), Color(1, 1, 1, 0.0), Color(1, 1, 1, a), Color(1, 1, 1, a), Color(1, 1, 1, 0.0))
	# קרחונים צפים
	var ip := 1300.0
	var is0 := int(floor(sc / ip)) - 1
	for k in range(is0, is0 + int(ceil(v.x / ip)) + 2):
		var ix := float(k) * ip - sc + 300.0 + _h(k, 8) * 600.0
		var iy := sea_top + 10.0 + _h(k, 9) * 20.0 + sin(t * 0.6 + float(k)) * 1.5
		var iw := 30.0 + _h(k, 10) * 50.0
		var ih := 10.0 + _h(k, 11) * 16.0
		U.quad(pts, cols, Vector2(ix - iw * 0.5, iy), Vector2(ix - iw * 0.3, iy - ih), Vector2(ix + iw * 0.2, iy - ih * 1.1), Vector2(ix + iw * 0.5, iy), Color("dce8ee"), Color("f4f8fa"), Color("f4f8fa"), Color("b8ccd8"))
		U.quad(pts, cols, Vector2(ix - iw * 0.5, iy), Vector2(ix + iw * 0.5, iy), Vector2(ix + iw * 0.4, iy + 3.0), Vector2(ix - iw * 0.4, iy + 3.0), Color(0.6, 0.8, 0.9, 0.6), Color(0.6, 0.8, 0.9, 0.6), Color(0.6, 0.8, 0.9, 0.0), Color(0.6, 0.8, 0.9, 0.0))
	U.flush(ci, pts, cols)
	# ספינת ציד חלודה שנטרפה (נוטה), עם עשן קלוש
	var wp := 2600.0
	var ws := int(floor(sc / wp)) - 1
	for k in range(ws, ws + int(ceil(v.x / wp)) + 2):
		var sx := float(k) * wp - sc + 900.0
		var sy := sea_top + 22.0
		if sx < -200.0 or sx > v.x + 200.0:
			continue
		DrawBatch.colored_polygon(ci, PackedVector2Array([Vector2(sx - 80, sy - 6), Vector2(sx + 70, sy - 20), Vector2(sx + 86, sy - 4), Vector2(sx - 60, sy + 4)]), Color("4a3a34"))
		DrawBatch.colored_polygon(ci, PackedVector2Array([Vector2(sx - 30, sy - 12), Vector2(sx + 10, sy - 18), Vector2(sx + 12, sy - 34), Vector2(sx - 26, sy - 28)]), Color("5a4a42"))
		DrawBatch.line(ci, Vector2(sx - 10, sy - 30), Vector2(sx - 22, sy - 74), Color("3a302c"), 2.5)
		DrawBatch.line(ci, Vector2(sx + 40, sy - 16), Vector2(sx + 34, sy - 52), Color("3a302c"), 2.0)
		DrawBatch.line(ci, Vector2(sx - 22, sy - 74), Vector2(sx + 34, sy - 52), Color("3a302c"), 0.8)
		Kit.soft_smoke(ci, Vector2(sx - 4, sy - 36), t, 120.0, Color(0.36, 0.38, 0.42, 0.2), -90.0, 6)


# ---- המפרץ: גלים, סלעים עם אריות ים ופינגווינים, אצות, נחיל רחוק, הפנים של THE CHORUS ----
static func mid_bay(ci: CanvasItem, sc: float, v: Vector2, y: float, t: float) -> void:
	var top := y - 160.0
	var bands := 24
	var span := v.y - top
	for i in bands:
		var k2 := float(i) / float(bands - 1)
		DrawBatch.rect(ci, Rect2(0, top + span * float(i) / float(bands - 1) - 1.0, v.x, span / float(bands - 1) + 2.0), Color("5c7684").lerp(SEA_D, pow(k2, 0.8)))
	var pts := PackedVector2Array()
	var cols := PackedColorArray()
	# מסדרי גלים שמתגלגלים אל החוף (קווי קצף שזזים למטה ומתבהרים)
	for r in 7:
		var ph := fmod(t * 0.12 + float(r) / 7.0, 1.0)
		var yy := top + 8.0 + ph * (span - 20.0)
		var a := sin(ph * PI) * 0.35
		var amp := 3.0 + ph * 6.0
		var x := -40.0
		var seg := 0
		while x < v.x + 40.0:
			var x2 := x + 40.0
			var w0 := sin((x + sc * (0.9 + ph * 0.4)) * 0.02 + t * 1.3 + float(r)) * amp
			var w1 := sin((x2 + sc * (0.9 + ph * 0.4)) * 0.02 + t * 1.3 + float(r)) * amp
			var c := Color(0.9, 0.95, 0.97, a * (0.5 + 0.5 * _h(seg + r * 50, 3)))
			U.quad(pts, cols, Vector2(x, yy + w0), Vector2(x2, yy + w1), Vector2(x2, yy + w1 + 2.2), Vector2(x, yy + w0 + 2.2), c, c, Color(c, 0.0), Color(c, 0.0))
			x = x2
			seg += 1
	U.flush(ci, pts, cols)
	# סלעים בים: אריות ים ופינגווינים, גלים שנשברים עליהם
	var period := 1150.0
	var start := int(floor(sc / period)) - 1
	for k in range(start, start + int(ceil(v.x / period)) + 2):
		var rx := float(k) * period - sc + 200.0 + _h(k, 12) * 500.0
		var ry := top + 46.0 + _h(k, 13) * 40.0
		var rw := 90.0 + _h(k, 14) * 90.0
		DrawBatch.colored_polygon(ci, PackedVector2Array([Vector2(rx - rw * 0.5, ry + 8), Vector2(rx - rw * 0.4, ry - 14), Vector2(rx - rw * 0.1, ry - 24), Vector2(rx + rw * 0.2, ry - 20), Vector2(rx + rw * 0.45, ry - 8), Vector2(rx + rw * 0.5, ry + 8)]), Color("3a4048"))
		DrawBatch.line(ci, Vector2(rx - rw * 0.1, ry - 24), Vector2(rx + rw * 0.2, ry - 20), Color(0.85, 0.85, 0.8, 0.5), 2.0)   # גואנו
		pts = PackedVector2Array()
		cols = PackedColorArray()
		for q in 6:   # תושבי הסלע
			var px := rx - rw * 0.35 + float(q) * rw * 0.13
			var py := ry - 20.0 + absf(float(q) - 2.5) * 2.0
			if _h(k * 7 + q, 15) < 0.4:   # אריה ים שוכב, מרים ראש
				U.oval(pts, cols, Vector2(px, py + 2.0), 7.0, 3.0, Color("5a4a3e"), 6)
				var lift := maxf(0.0, sin(t * 0.8 + float(q * 3 + k))) * 3.0
				U.oval(pts, cols, Vector2(px + 6.0, py - 1.0 - lift), 2.4, 2.0, Color("5a4a3e"), 6)
			else:   # פינגווין קטן
				var bob := sin(t * 3.0 + float(q * 5 + k)) * 0.5
				U.oval(pts, cols, Vector2(px, py - 3.0 + bob), 2.0, 3.6, Color("1a1c20"), 6)
				U.oval(pts, cols, Vector2(px + 0.7, py - 2.4 + bob), 1.2, 2.6, Color("e8e8e4"), 6)
		U.flush(ci, pts, cols)
		# גל נשבר על הסלע
		var bph := fmod(t * 0.35 + _h(k, 16) * 3.0, 3.0)
		if bph < 1.2:
			var hh := sin(bph / 1.2 * PI) * 30.0
			Kit.soft_glow(ci, Vector2(rx - rw * 0.4, ry - hh * 0.5), 26.0 + bph * 22.0, Color(0.94, 0.97, 1.0, 0.55 * (1.0 - bph / 1.2)), 0.8)
		DrawBatch.line(ci, Vector2(rx - rw * 0.55, ry + 9.0), Vector2(rx + rw * 0.55, ry + 9.0), Color(0.9, 0.95, 1.0, 0.45 + 0.2 * sin(t * 2.0 + float(k))), 2.0)
		# יער אצות על פני המים
		for q in 5:
			var kx := rx + rw * 0.8 + float(q) * 22.0 + sin(t * 0.8 + float(q)) * 3.0
			DrawBatch.line(ci, Vector2(kx, ry + 18.0), Vector2(kx + 9.0, ry + 20.0 + sin(t + float(q)) * 2.0), Color(0.4, 0.38, 0.16, 0.7), 2.0)
	# נחיל ציפורים רחוק שמשנה צורה (רמז)
	var fx := fposmod(t * 22.0 - sc * 0.3, v.x + 800.0) - 400.0
	var fy := top - 70.0 + sin(t * 0.3) * 30.0
	pts = PackedVector2Array()
	cols = PackedColorArray()
	for i in 70:
		var a := float(i) * 2.399 + t * 0.6
		var r := sqrt(float(i)) * 6.5 * (1.0 + 0.35 * sin(t * 0.9 + float(i) * 0.1))
		var p := Vector2(fx + cos(a) * r * 1.8 + sin(t * 0.7 + float(i)) * 6.0, fy + sin(a) * r * 0.7 + sin(t * 1.3 + a) * 8.0)
		U.dia(pts, cols, p, 1.4, Color(0.1, 0.1, 0.13, 0.75))
	U.flush(ci, pts, cols)
	chorus_face(ci, v, t)


# ---- הפנים של THE CHORUS (סצנת סיפור): מאות ציפורים יוצרות פנים ענקיות מעל הים, הפה "מדבר", ואז מתפרקות ----
static func chorus_face(ci: CanvasItem, v: Vector2, t: float) -> void:
	var tf := _ms_since(U.face_ms)
	if tf < 0.0:
		return
	var tb := _ms_since(U.break_ms) if U.break_ms >= U.face_ms else -1.0
	if tb > 6.0:
		return
	var form := smoothstep(0.0, 3.0, tf)
	var c := Vector2(v.x * 0.5, v.y * 0.32)
	var pts := PackedVector2Array()
	var cols := PackedColorArray()
	var n := 190
	var talk := U.talk
	for i in n:
		var slot := _face_slot(i, n, t, talk)
		var a0 := float(i) * 2.399 + t * 0.8
		var swirl := c + Vector2(cos(a0) * (200.0 + _h(i, 1) * 260.0) + sin(t * 0.5 + float(i)) * 40.0, sin(a0) * 80.0 - 240.0 + _h(i, 2) * 60.0)
		var k := clampf(form * (1.15 - 0.3 * _h(i, 3)), 0.0, 1.0)
		var p := swirl.lerp(c + slot, k * k * (3.0 - 2.0 * k))
		p += Vector2(sin(t * 3.0 + float(i) * 1.7), cos(t * 2.6 + float(i))) * 2.0
		var al := 0.95
		if tb >= 0.0:   # מתפרקות: עפות החוצה ולמעלה
			var dirv := (slot + Vector2((_h(i, 4) - 0.5) * 60.0, -30.0)).normalized()
			p += dirv * tb * tb * (90.0 + _h(i, 5) * 140.0) + Vector2(0, -tb * 40.0)
			al = clampf(1.0 - tb / 5.5, 0.0, 1.0)
		var s := 1.5 + _h(i, 6) * 0.6
		U.bird(pts, cols, p, s, t * 14.0 + float(i), 1.0 if _h(i, 7) < 0.5 else -1.0, Color(0.06, 0.06, 0.08, al))
	U.flush(ci, pts, cols)
	if tb < 0.0 and form > 0.7:   # עיניים: הציפורים בעיניים מנצנצות באדום
		var ea := (form - 0.7) / 0.3
		for s2: float in [-1.0, 1.0]:
			var e := c + Vector2(s2 * 62.0, -40.0)
			Kit.soft_glow(ci, e, 26.0, Color(1.0, 0.18, 0.12, 0.45 * ea))
			DrawBatch.circle(ci, e, 3.0, Color(1.0, 0.4, 0.3, ea))


# נקודה בפנים (יחסית למרכז): קו לסת / גולגולת, גבות, עיניים, אף, פה שזז
static func _face_slot(i: int, n: int, t: float, talk: float) -> Vector2:
	var u := float(i) / float(n)
	if u < 0.42:   # מתאר הראש
		var a := u / 0.42 * TAU
		var r := Vector2(150.0, 170.0)
		var p := Vector2(cos(a) * r.x, sin(a) * r.y)
		if p.y > 60.0:
			p.x *= 1.0 - (p.y - 60.0) / 300.0   # לסת צרה
		return p + Vector2(_h(i, 9) - 0.5, _h(i, 10) - 0.5) * 14.0
	if u < 0.56:   # עיניים (שתי טבעות)
		var k := (u - 0.42) / 0.14
		var side := -1.0 if k < 0.5 else 1.0
		var a := fmod(k * 2.0, 1.0) * TAU
		return Vector2(side * 62.0 + cos(a) * 26.0, -40.0 + sin(a) * 14.0)
	if u < 0.66:   # גבות
		var k := (u - 0.56) / 0.1
		var side := -1.0 if k < 0.5 else 1.0
		var x := fmod(k * 2.0, 1.0)
		return Vector2(side * (30.0 + x * 70.0), -78.0 - sin(x * PI) * 10.0 + x * 6.0)
	if u < 0.76:   # אף
		var k := (u - 0.66) / 0.1
		return Vector2(-6.0 + k * 14.0, -20.0 + k * 62.0)
	# פה (נפתח ונסגר כשמדבר)
	var k := (u - 0.76) / 0.24
	var a := k * TAU
	var open := 6.0 + talk * (14.0 + 12.0 * absf(sin(t * 9.0)))
	return Vector2(cos(a) * 56.0, 92.0 + sin(a) * open)


# ---- סוללת חלוקים מאחורי הדרך: טוסוק, צלעות לווייתן, סירות, מחילות פינגווינים ----
static func near_shore(ci: CanvasItem, sc: float, v: Vector2, y: float, t: float) -> void:
	var base := y - 20.0
	var period := 900.0
	var start := int(floor(sc / period)) - 1
	var pts := PackedVector2Array()
	var cols := PackedColorArray()
	for k in range(start, start + int(ceil(v.x / period)) + 2):
		var bx := float(k) * period - sc
		# הסוללה (שיפוע חלוקים)
		var bank := PackedVector2Array([Vector2(bx, base + 30.0)])
		for q in 10:
			bank.append(Vector2(bx + float(q) * 100.0, base - 34.0 - _h(k * 11 + q, 1) * 26.0))
		bank.append(Vector2(bx + period, base + 30.0))
		DrawBatch.colored_polygon(ci, bank, Color("5e5850"))
		for q in 40:   # חלוקים על הסוללה
			var px := bx + _h(k * 41 + q, 2) * period
			var py := base - 10.0 - _h(k * 41 + q, 3) * 26.0
			U.oval(pts, cols, Vector2(px, py), 3.0 + _h(k * 41 + q, 4) * 3.0, 2.0 + _h(k * 41 + q, 5) * 1.5, Color("787068").lerp(Color("4a4642"), _h(k * 41 + q, 6)), 6)
		# טוסוק - גושי עשב צהבהב שמתנופפים ברוח
		for q in 9:
			var gx := bx + 40.0 + float(q) * 98.0 + _h(k * 9 + q, 7) * 40.0
			var gy := base - 30.0 - _h(k * 9 + q, 8) * 14.0
			for b in 9:
				var lean := -0.5 + float(b) / 8.0
				var sway := sin(t * 2.4 + float(q) * 0.7 + float(b) * 0.3) * 0.18 - 0.22
				var tip := Vector2(gx, gy) + Vector2.from_angle(-PI / 2.0 + lean * 0.9 + sway) * (22.0 + _h(b + q, 9) * 12.0)
				U.tri(pts, cols, Vector2(gx - 3.0 + float(b) * 0.7, gy + 2.0), Vector2(gx - 1.5 + float(b) * 0.7, gy + 2.0), tip, TUSSOCK.lerp(Color("6a5a2e"), _h(b * 3 + q, 10)))
		# צלעות לווייתן בולטות מהחלוקים
		if posmod(k, 2) == 0:
			var wx := bx + 520.0
			for r in 5:
				var rx := wx + float(r) * 34.0
				var rh := 70.0 - absf(float(r) - 2.0) * 10.0
				var pr := PackedVector2Array()
				for q in 7:
					var u := float(q) / 6.0
					pr.append(Vector2(rx + sin(u * 2.4) * 22.0, base - 26.0 - u * rh))
				DrawBatch.polyline(ci, pr, BONE_D, 6.0)
				DrawBatch.polyline(ci, pr, BONE, 3.0)
		else:   # סירת משוטים הפוכה + שרשרת עוגן
			var bx2 := bx + 420.0
			DrawBatch.colored_polygon(ci, PackedVector2Array([Vector2(bx2 - 60, base - 30), Vector2(bx2 - 50, base - 52), Vector2(bx2 + 40, base - 54), Vector2(bx2 + 66, base - 34)]), Color("6a4030"))
			DrawBatch.line(ci, Vector2(bx2 - 50, base - 52), Vector2(bx2 + 40, base - 54), Color("a86a44"), 2.0)
			for q in 4:
				DrawBatch.line(ci, Vector2(bx2 - 40 + float(q) * 25.0, base - 52), Vector2(bx2 - 44 + float(q) * 27.0, base - 31), Color("4a2a20"), 1.2)
			var ch := PackedVector2Array()
			for q in 12:
				ch.append(Vector2(bx2 + 80.0 + float(q) * 9.0, base - 28.0 + sin(float(q) * 0.6) * 4.0))
			DrawBatch.polyline(ci, ch, Color("5a3020"), 3.0)
		# מחילות פינגווינים: חור כהה, ראש מציץ ונעלם
		for q in 3:
			var hx := bx + 150.0 + float(q) * 290.0
			var hy := base - 18.0 - _h(k * 3 + q, 11) * 10.0
			U.oval(pts, cols, Vector2(hx, hy), 11.0, 6.0, Color("2a2622"), 8)
			var pk := sin(t * 0.9 + float(q * 7 + k) * 1.3)
			if pk > 0.2:
				var up := (pk - 0.2) / 0.8 * 7.0
				U.oval(pts, cols, Vector2(hx, hy - up), 3.4, 4.0, Color("16181c"), 6)
				U.quad(pts, cols, Vector2(hx - 3.2, hy - up - 1.0), Vector2(hx + 3.2, hy - up - 1.0), Vector2(hx + 3.0, hy - up + 0.4), Vector2(hx - 3.0, hy - up + 0.4), Color("e8e6e0"), Color("e8e6e0"), Color("e8e6e0"), Color("e8e6e0"))
				U.tri(pts, cols, Vector2(hx + 2.5, hy - up - 1.5), Vector2(hx + 7.0, hy - up - 0.6), Vector2(hx + 2.5, hy - up + 0.2), Color("2a2a2a"))
	U.flush(ci, pts, cols)
	DrawBatch.rect(ci, Rect2(0, base + 12.0, v.x, v.y - base), Color("4a4640"))
	# שחפים הולכים על הסוללה (בלי קשר לגלילה, הולכים לאט)
	pts = PackedVector2Array()
	cols = PackedColorArray()
	for i in 4:
		var gx := fposmod(_h(i, 30) * v.x * 1.5 + t * (8.0 + float(i) * 3.0) - sc * 0.1, v.x + 200.0) - 100.0
		var gy := base - 40.0 + _h(i, 31) * 10.0
		var step := sin(t * 8.0 + float(i)) * 1.0
		U.oval(pts, cols, Vector2(gx, gy - 6.0), 6.0, 3.6, Color("eceeee"), 8)
		U.oval(pts, cols, Vector2(gx - 1.0, gy - 7.5), 4.6, 2.2, Color("8a949c"), 6)
		U.oval(pts, cols, Vector2(gx + 5.0, gy - 10.0), 2.4, 2.2, Color("f4f4f2"), 6)
		U.tri(pts, cols, Vector2(gx + 6.5, gy - 10.5), Vector2(gx + 10.5, gy - 9.8), Vector2(gx + 6.5, gy - 9.2), Color("e8b030"))
		U.tri(pts, cols, Vector2(gx - 4.0, gy - 7.0), Vector2(gx - 10.0, gy - 8.0), Vector2(gx - 4.0, gy - 5.0), Color("1e2024"))
		DrawBatch.line(ci, Vector2(gx, gy - 3.0), Vector2(gx - 1.0 + step, gy), Color("c08040"), 1.0)
		DrawBatch.line(ci, Vector2(gx + 2.0, gy - 3.0), Vector2(gx + 2.0 - step, gy), Color("c08040"), 1.0)
	U.flush(ci, pts, cols)


# אובך ים מאחורי הדמויות + רסס שעף
static func coast_overlay(ci: CanvasItem, v: Vector2, t: float) -> void:
	Kit.haze_band(ci, v, 400.0, 614.0, Color(0.78, 0.84, 0.88, 0.24))
	for i in 5:
		var mx := fposmod(float(i) * 300.0 - t * (30.0 + float(i) * 6.0), v.x + 600.0) - 300.0
		Kit.soft_glow(ci, Vector2(mx, 560.0 + float(i % 3) * 16.0), 220.0, Color(0.88, 0.92, 0.94, 0.07 + 0.03 * sin(t * 0.4 + float(i))), 0.25)


# ============================================================
#  עולם
# ============================================================

# ---- חוף: חול רטוב, חלוקים, קונכיות, אצות שנפלטו ----
class BeachGround extends Node2D:
	var w := 1024.0
	var depth := 90.0
	var seed_v := 0

	func _ready() -> void:
		z_index = 1

	func _draw() -> void:
		DrawBatch.rect(self, Rect2(0, 0, w, depth), Color("2e2a26"))
		DrawBatch.rect(self, Rect2(0, 0, w, 14.0), SAND)
		DrawBatch.rect(self, Rect2(0, 10.0, w, 6.0), SAND_D)
		DrawBatch.rect(self, Rect2(0, 16.0, w, 26.0), SAND_WET)
		DrawBatch.rect(self, Rect2(0, 0, w, 1.6), Color(0.92, 0.92, 0.86, 0.6))
		var r := RandomNumberGenerator.new()
		r.seed = seed_v
		var pts := PackedVector2Array()
		var cols := PackedColorArray()
		for i in int(w / 5.0):   # חלוקים
			var c := PEBBLE.darkened(r.randf() * 0.35).lerp(Color("a49884"), r.randf() * 0.35)
			U.oval(pts, cols, Vector2(r.randf_range(0.0, w), r.randf_range(2.0, 12.0)), r.randf_range(1.4, 3.4), r.randf_range(1.0, 2.0), c, 6)
		for i in int(w / 60.0):   # קונכיות מולים כהות
			var p := Vector2(r.randf_range(0.0, w), r.randf_range(3.0, 11.0))
			U.oval(pts, cols, p, 2.6, 1.3, Color("26283a"), 6, r.randf_range(-0.5, 0.5))
			U.oval(pts, cols, p + Vector2(-0.6, -0.4), 1.2, 0.5, Color(0.6, 0.62, 0.8, 0.6), 4)
		for i in int(w / 120.0):   # אצות שנפלטו לחוף
			var p := Vector2(r.randf_range(0.0, w), r.randf_range(4.0, 10.0))
			var ln := r.randf_range(18.0, 40.0)
			for q in 4:
				var a := r.randf_range(-0.3, 0.3)
				var e := p + Vector2(cos(a) * ln * (0.6 + 0.15 * float(q)), sin(a) * 4.0 - 1.0)
				U.quad(pts, cols, p + Vector2(0, -1.2), e + Vector2(0, -0.8), e + Vector2(0, 0.8), p + Vector2(0, 1.2), KELP, KELP_L, KELP_L, KELP)
		for i in int(w / 40.0):   # שלוליות במים הרטובים
			var p := Vector2(r.randf_range(0.0, w), r.randf_range(20.0, 36.0))
			U.oval(pts, cols, p, r.randf_range(12.0, 30.0), 1.6, Color(0.7, 0.78, 0.82, 0.3), 8)
		U.flush(self, pts, cols)
		for i in int(w / 26.0):
			DrawBatch.circle(self, Vector2(r.randf_range(0.0, w), r.randf_range(46.0, depth - 6.0)), r.randf_range(1.5, 3.5), Color("3a3530"))


# ============================================================
#  מושבת הפינגווינים
# ============================================================
class Colony extends Node2D:
	const SCATTER_T := Vector2(2.2, 3.2)
	const REGROUP_T := 3.2
	const HEAR_R := 560.0           # ירייה במרחק הזה -> נבהלים
	const TOUCH_R := 24.0           # השחקן נכנס לצפיפות -> נבהלים
	const DRIFT_V := 9.0
	const LURE_V := 30.0            # (WADDLER שלמד) המושבה נדחפת אליך
	const WANDER := 150.0           # כמה רחוק מהבית המושבה מסתובבת
	const PG := 8.5                 # רווח בין פינגווינים בצפיפות
	enum {HUDDLE, SCATTER, REGROUP}
	var n := 18
	var seed_v := 0
	var state := HUDDLE
	var scatters := 0               # לבדיקות
	var hits := 0
	var lure_x := NAN               # (גלובלי) WADDLER שלמד מושך את המושבה לכאן
	var _lure_t := 0.0
	var _cx := 0.0                  # מרכז הצפיפות (מקומי)
	var _hw := 40.0
	var _p := []                    # [pos, vx, phase, size, face, st, timer, species, slot, vy, rot]
	var _shot := -1
	var _body: StaticBody2D = null
	var _shape: CollisionShape2D = null
	var _t := 0.0
	var _st := 0.0
	var _sq := 1.0
	var _threat := 0.0
	var _awake := false

	func _ready() -> void:
		z_index = 2
		add_to_group("s57_colonies")
		add_to_group("blastable")
		var r := RandomNumberGenerator.new()
		r.seed = seed_v
		var rows := 3 if n > 12 else 2
		var per := int(ceil(float(n) / float(rows)))
		_hw = float(per) * PG * 0.5 + 6.0
		for i in n:
			var row := i % rows
			var col := i / rows
			var slot := Vector2((float(col) - float(per - 1) * 0.5) * PG + (4.0 if row == 1 else 0.0) + r.randf_range(-1.5, 1.5), [-2.5, 0.0, 2.5][row] if rows == 3 else [-1.5, 1.5][row])
			var sp := 0
			var q := r.randf()
			if q < 0.14:
				sp = 1   # פינגווין מלך (גבוה, כתום)
			elif q < 0.3:
				sp = 2   # ג'נטו (מקור כתום, כתם לבן)
			_p.append([slot, 0.0, r.randf() * TAU, (1.32 if sp == 1 else 1.0) * r.randf_range(0.9, 1.08), 1.0 if r.randf() < 0.5 else -1.0, 0, 0.0, sp, slot, 0.0, 0.0])
		_p.sort_custom(func(a, b): return a[8].y < b[8].y)   # עומק: השורה האחורית קודם
		_body = ColonyBody.new()
		_body.colony = self
		_body.collision_mask = 0
		_body.add_to_group("no_outline")
		_shape = CollisionShape2D.new()
		var rs := RectangleShape2D.new()
		rs.size = Vector2(_hw * 2.0, 30.0)
		_shape.shape = rs
		_body.add_child(_shape)
		add_child(_body)
		_shot = Game.shot_id
		_set_shield(true)

	func _set_shield(on: bool) -> void:
		_body.collision_layer = 4 if on else 0
		_body.position = Vector2(_cx, -15.0)

	func huddled() -> bool:
		return state == HUDDLE

	func center() -> Vector2:
		return global_position + Vector2(_cx, 0.0)

	func half_w() -> float:
		return _hw

	# כמה פינגווינים (לא נופלים) ליד x גלובלי
	func cover_count(gx: float, r: float) -> int:
		var c := 0
		for p in _p:
			if int(p[5]) != 3 and absf(global_position.x + p[0].x - gx) < r:
				c += 1
		return c

	func lure(gx: float) -> void:
		lure_x = gx
		_lure_t = 0.4

	func blast_rect() -> Rect2:
		return Rect2(global_position + Vector2(_cx - _hw - 200.0, -30.0), Vector2(_hw * 2.0 + 400.0, 30.0))

	func hit_by_blast(c: Vector2, _r: float) -> void:
		for p in _p:
			var gp: Vector2 = global_position + p[0]
			if gp.distance_to(c) < 170.0:
				_knock(p, signf(gp.x - c.x + 0.01), 1.4)
		scatter(c.x, true)

	# כדור פגע בצפיפות (ColonyBody): הפינגווין הקרוב נופל, נוצות, וכולם בורחים
	func bullet_hit(hp: Vector2, dir: Vector2) -> void:
		hits += 1
		var best = null
		var bd := 1e9
		for p in _p:
			var d: float = absf(global_position.x + p[0].x - hp.x)
			if d < bd and int(p[5]) != 3:
				bd = d
				best = p
		if best != null:
			_knock(best, signf(dir.x) if dir.x != 0.0 else 1.0, 1.0)
		Particles.burst(get_parent(), hp, "snow", -dir, 8)
		Sfx.play("pg_squawk", hp, 2.0, 0.15, 3)
		var m := get_parent()
		if m != null and not m.has_meta("s57_colony_said"):
			m.set_meta("s57_colony_said", true)
			var pl := get_tree().get_first_node_in_group("player")
			if pl != null and pl.has_method("_say"):
				pl._say("Not the birds... they hide in there.", Color("c8dce8"))
		var pl2 := get_tree().get_first_node_in_group("player") as Node2D
		scatter(pl2.global_position.x if pl2 != null else hp.x - dir.x * 100.0, false)

	func _knock(p: Array, side: float, k: float) -> void:
		p[5] = 3
		p[6] = randf_range(0.9, 1.4)
		p[1] = side * randf_range(90.0, 160.0) * k
		p[9] = -randf_range(150.0, 240.0) * k
		p[4] = -side

	func scatter(from_x: float, strong := false) -> void:
		_threat = from_x
		if state == SCATTER:
			_st = maxf(_st, 1.2)
			return
		state = SCATTER
		scatters += 1
		_st = randf_range(SCATTER_T.x, SCATTER_T.y)
		_set_shield(false)
		if Art.on_screen(self, center(), 200.0):
			Sfx.play("pg_flee", center(), 1.0, 0.1, 2)
			Sfx.play("pg_squawk", center() + Vector2(0, -10), 0.0, 0.2, 3)
		var m := get_parent()
		if m != null and not m.has_meta("s57_scatter_popup") and Art.on_screen(self, center(), 0.0):
			m.set_meta("s57_scatter_popup", true)
			_popup("THE COLONY SCATTERS")
		for p in _p:
			if int(p[5]) == 3:
				continue
			var gx: float = global_position.x + p[0].x
			var away := signf(gx - from_x) if absf(gx - from_x) > 4.0 else (1.0 if randf() < 0.5 else -1.0)
			if randf() < 0.25:
				away = -away * (1.0 if absf(gx - from_x) > 140.0 else -1.0)   # חלק בורחים לצד השני (אם יש מקום)
			p[4] = away
			if randf() < (0.45 if strong else 0.3):
				p[5] = 2   # מחליק על הבטן
				p[1] = away * randf_range(170.0, 230.0)
			else:
				p[5] = 1
				p[1] = away * randf_range(80.0, 130.0)
			p[6] = randf_range(0.0, 0.25)   # עיכוב קטן - לא כולם באותו פריים

	func _popup(txt: String) -> void:
		var l := Label.new()
		l.text = txt
		l.add_theme_font_size_override("font_size", 15)
		l.add_theme_color_override("font_color", Color("cfe6f2"))
		l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
		l.add_theme_constant_override("outline_size", 4)
		l.z_index = 30
		l.position = center() + Vector2(-80.0, -70.0)
		get_parent().add_child(l)
		var tw := l.create_tween()
		tw.tween_property(l, "position:y", l.position.y - 40.0, 1.6)
		tw.parallel().tween_property(l, "modulate:a", 0.0, 1.6).set_delay(0.6)
		tw.tween_callback(l.queue_free)

	func _physics_process(delta: float) -> void:
		var pl := get_tree().get_first_node_in_group("player") as Node2D
		if pl == null:
			return
		var dx: float = pl.global_position.x - center().x
		_awake = absf(dx) < 1500.0
		if not _awake:
			_shot = Game.shot_id
			return
		_t += delta
		_st -= delta
		_lure_t -= delta
		_sq -= delta
		var shot: int = Game.shot_id
		if shot != _shot:
			_shot = shot
			if state == HUDDLE and absf(dx) < HEAR_R and absf(pl.global_position.y - global_position.y) < 260.0 and not pl.dead:
				scatter(pl.global_position.x)
		if state == HUDDLE and not pl.dead and absf(dx) < _hw + TOUCH_R and absf(pl.global_position.y - global_position.y) < 40.0:
			scatter(pl.global_position.x)
		match state:
			HUDDLE:
				var tx := sin(_t * 0.11 + float(seed_v % 97)) * WANDER
				var v := DRIFT_V
				if _lure_t > 0.0 and not is_nan(lure_x):
					tx = clampf(lure_x - global_position.x, -WANDER - 260.0, WANDER + 260.0)
					v = LURE_V
				_cx = move_toward(_cx, tx, v * delta)
				_body.position = Vector2(_cx, -15.0)
				if _sq <= 0.0:   # מישהו צועק (נחירת חמור של פינגווין מגלני)
					_sq = randf_range(1.5, 4.0)
					var p: Array = _p[randi() % _p.size()]
					p[6] = 0.8
					if Art.on_screen(self, center(), 0.0):
						Sfx.play("pg_squawk", center(), -10.0, 0.25, 2)
			SCATTER:
				if _st <= 0.0:
					state = REGROUP
					_st = REGROUP_T
					var away := signf(center().x - _threat) if absf(center().x - _threat) > 2.0 else 1.0
					_cx = clampf(_cx + away * 140.0, -WANDER - 120.0, WANDER + 120.0)
					for p in _p:
						if int(p[5]) != 3:
							p[5] = 4
			REGROUP:
				var done := true
				for p in _p:
					if absf(p[0].x - (_cx + p[8].x)) > 6.0 or int(p[5]) == 3:
						done = false
						break
				if done or _st <= 0.0:
					state = HUDDLE
					_set_shield(true)
					for p in _p:
						if int(p[5]) != 3:
							p[5] = 0
		for p in _p:
			_step(p, delta)
		if Art.on_screen(self, center(), _hw + 420.0):
			queue_redraw()

	func _step(p: Array, delta: float) -> void:
		var st: int = p[5]
		p[2] = float(p[2]) + delta * (6.0 if st == 0 else 15.0)
		match st:
			0, 4:   # עומד / חוזר למקום בצפיפות
				var tgt: float = _cx + p[8].x
				var dx: float = tgt - p[0].x
				var sp := 34.0 if st == 0 else 55.0
				if absf(dx) > 1.0:
					p[0].x += clampf(dx, -sp * delta, sp * delta)
					p[4] = signf(dx)
				elif st == 0 and randf() < 0.004:
					p[4] = -float(p[4])
				p[0].y = move_toward(p[0].y, p[8].y, 10.0 * delta)
				p[6] = maxf(0.0, float(p[6]) - delta)
			1, 2:   # בורח / מחליק
				if float(p[6]) > 0.0:   # עיכוב קטן לפני שבורח
					p[6] = float(p[6]) - delta
					return
				var lim := WANDER + 420.0
				p[0].x = clampf(p[0].x + float(p[1]) * delta, -lim, lim)
				if st == 2:
					p[1] = move_toward(float(p[1]), 0.0, 120.0 * delta)
					if absf(float(p[1])) < 30.0:
						p[5] = 1
						p[1] = signf(float(p[4])) * 70.0
				if absf(p[0].x) >= lim - 1.0:
					p[1] = 0.0
			3:   # נפל / עף מפגיעה
				p[9] = float(p[9]) + 700.0 * delta
				p[0] += Vector2(float(p[1]), float(p[9])) * delta
				p[10] = float(p[10]) + float(p[1]) * 0.05 * delta
				if p[0].y >= p[8].y:
					p[0].y = p[8].y
					p[9] = 0.0
					p[1] = move_toward(float(p[1]), 0.0, 400.0 * delta)
					p[6] = float(p[6]) - delta
					if float(p[6]) <= 0.0:
						p[10] = 0.0
						p[5] = 4 if state == REGROUP else (1 if state == SCATTER else 4)
						if int(p[5]) == 1:
							p[1] = signf(float(p[4])) * 90.0
				p[0].x = clampf(p[0].x, -WANDER - 420.0, WANDER + 420.0)

	func _draw() -> void:
		var pts := PackedVector2Array()
		var cols := PackedColorArray()
		if state == HUDDLE:   # צל של הצפיפות
			U.oval(pts, cols, Vector2(_cx, 1.0), _hw + 4.0, 3.5, Color(0, 0, 0, 0.25), 12)
		for p in _p:
			penguin(pts, cols, p[0], float(p[3]), float(p[4]), int(p[5]), float(p[2]), int(p[7]), float(p[10]), float(p[6]) > 0.0 and int(p[5]) == 0)
		U.flush(self, pts, cols)

	# פינגווין אחד (רגליים ב-p, פונה ימינה כש-face = 1). st: 0 עומד, 1 בורח, 2 מחליק, 3 נופל, 4 הולך
	static func penguin(pts: PackedVector2Array, cols: PackedColorArray, p: Vector2, s: float, face: float, st: int, ph: float, sp: int, rot: float, squawk: bool) -> void:
		var r := rot
		var lift := 0.0
		if st == 2:
			r = face * 1.32
			lift = -1.0
		elif st == 1 or st == 4:
			r = sin(ph) * 0.16 + face * 0.12
			lift = -absf(sin(ph)) * 1.2
		else:
			r += sin(ph * 0.35) * 0.04
		var xf := Transform2D(r, p + Vector2(0, lift))
		var black := Color("16181e") if sp != 1 else Color("1e2430")
		var white := Color("eeeee8")
		var L := func(v: Vector2) -> Vector2: return xf * (Vector2(v.x * face, v.y) * s)
		# שלג / צל קטן
		if st != 3:
			U.oval(pts, cols, p + Vector2(0, 0.5), 5.5 * s, 1.4, Color(0, 0, 0, 0.22), 6)
		# רגליים
		var fk := sin(ph) * 2.0 if st == 1 or st == 4 else 0.0
		var feet := Color("e08a6a") if sp != 1 else Color("3a3430")
		U.tri(pts, cols, L.call(Vector2(-2.5 + fk, -1.2)), L.call(Vector2(1.5 + fk, 0.0)), L.call(Vector2(-2.0 + fk, 0.2)), feet)
		U.tri(pts, cols, L.call(Vector2(0.5 - fk, -1.2)), L.call(Vector2(4.2 - fk, 0.0)), L.call(Vector2(0.8 - fk, 0.2)), feet)
		var ro := r * 1.0
		# גוף
		U.oval(pts, cols, L.call(Vector2(0, -10)), 6.2 * s, 10.0 * s, black, 10, ro)
		U.oval(pts, cols, L.call(Vector2(1.9, -9.2)), 4.3 * s, 8.4 * s, white, 10, ro)
		if sp == 0:   # מגלני: שני פסים שחורים על החזה
			U.oval(pts, cols, L.call(Vector2(2.4, -13.6)), 4.3 * s, 1.0 * s, black, 6, ro)
			U.oval(pts, cols, L.call(Vector2(2.9, -10.4)), 3.9 * s, 0.75 * s, black, 6, ro)
			U.dia(pts, cols, L.call(Vector2(1.6, -6.0)), 0.6 * s, Color("3a3a3a"))
		elif sp == 1:   # מלך: צוואר כתום-צהוב
			U.oval(pts, cols, L.call(Vector2(2.8, -16.5)), 2.8 * s, 2.4 * s, Color("f0a830"), 8, ro)
		# סנפיר (מנפנף כשבורח)
		var fl := (sin(ph * 2.0) * 3.0 - 2.0) if st == 1 else (-4.0 if st == 2 else sin(ph * 0.5) * 0.6)
		U.tri(pts, cols, L.call(Vector2(-1.2, -16.0)), L.call(Vector2(-3.4 + fl * 0.4, -5.0 + fl)), L.call(Vector2(0.9, -14.5)), black.lightened(0.08))
		# ראש
		var hd := Vector2(1.4, -21.0)
		U.oval(pts, cols, L.call(hd), 4.2 * s, 4.0 * s, black, 10, ro)
		match sp:
			0:   # פס לבן סביב הפנים + עור ורוד ליד המקור
				U.oval(pts, cols, L.call(hd + Vector2(-0.6, 0.6)), 3.8 * s, 0.75 * s, white, 6, ro - face * 0.9)
				U.dia(pts, cols, L.call(hd + Vector2(2.4, 0.4)), 0.8 * s, Color("e89a9a"))
			1:   # כתם אוזן כתום
				U.oval(pts, cols, L.call(hd + Vector2(-1.2, 0.8)), 1.3 * s, 2.3 * s, Color("f6a020"), 6, ro)
			2:   # כתם לבן מעל העין
				U.oval(pts, cols, L.call(hd + Vector2(0.2, -2.4)), 1.8 * s, 0.8 * s, white, 6, ro)
		# מקור (פתוח ולמעלה כשצועק)
		var bc := Color("1a1a1a") if sp == 0 else Color("e07028")
		if squawk:
			U.tri(pts, cols, L.call(hd + Vector2(2.8, -1.6)), L.call(hd + Vector2(5.5, -7.0)), L.call(hd + Vector2(3.6, -0.6)), bc)
			U.tri(pts, cols, L.call(hd + Vector2(3.2, -0.2)), L.call(hd + Vector2(7.4, -3.0)), L.call(hd + Vector2(3.4, 0.8)), bc)
		else:
			U.tri(pts, cols, L.call(hd + Vector2(3.2, -0.8)), L.call(hd + Vector2(7.6 if sp == 1 else 6.6, 0.4)), L.call(hd + Vector2(3.2, 0.9)), bc)
		U.dia(pts, cols, L.call(hd + Vector2(1.8, -0.8)), 0.7 * s, Color("f4f0e8"))
		U.dia(pts, cols, L.call(hd + Vector2(1.9, -0.8)), 0.35 * s, Color("1a0a0a"))


# הגוף שתופס כדורים כשהמושבה מתגודדת (שכבה 4, כמו זומבים - הכדור עוצר בפינגווין)
class ColonyBody extends StaticBody2D:
	var colony = null

	func take_damage(_amount: int, hit_pos: Vector2, dir: Vector2, _explosive := false, _src := {}) -> void:
		if colony != null and is_instance_valid(colony):
			colony.bullet_hit(hit_pos, dir)


# ============================================================
#  המגדלור + בית השומר
# ============================================================
class Lighthouse extends Node2D:
	var house_tier := 150.0
	var gallery_tier := 300.0
	var house := Vector2(-280.0, -50.0)    # מקומי x0, x1 של בית השומר
	var beams := 0.0                       # (סצנה) עוצמת האלומה
	var _t := 0.0

	func _ready() -> void:
		z_index = -2

	func _process(delta: float) -> void:
		_t += delta
		if Engine.get_process_frames() % 2 == 0 and Art.on_screen(self, global_position + Vector2(0, -200), 700.0):
			queue_redraw()

	func _draw() -> void:
		var g := gallery_tier
		var hx0 := house.x
		var hx1 := house.y
		var ht := house_tier
		# בית השומר: קירות לבנים מכוסים חזזית, גג שטוח עם מעקה, חלונות, דלת
		DrawBatch.rect(self, Rect2(hx0, -ht, hx1 - hx0, ht), Color("c8c0b0"))
		DrawBatch.rect(self, Rect2(hx0, -ht, hx1 - hx0, ht), Color("6a6458"), false, 2.0)
		DrawBatch.rect(self, Rect2(hx0, -40.0, hx1 - hx0, 40.0), Color("a89e8a"))
		for q in int((hx1 - hx0) / 22.0):
			DrawBatch.line(self, Vector2(hx0 + 4.0 + float(q) * 22.0, -ht + 6.0), Vector2(hx0 + 8.0 + float(q) * 22.0, -ht + 30.0 + float(q % 3) * 12.0), Color(0.45, 0.4, 0.3, 0.35), 3.0)   # כתמי רטיבות
		DrawBatch.rect(self, Rect2(hx0 - 6.0, -ht - 8.0, hx1 - hx0 + 12.0, 10.0), RED_LH.darkened(0.3))
		for q in 2:
			var wx := hx0 + 30.0 + float(q) * 100.0
			DrawBatch.rect(self, Rect2(wx, -ht + 34.0, 34.0, 40.0), Color("2a3036"))
			DrawBatch.rect(self, Rect2(wx, -ht + 34.0, 34.0, 40.0), Color("eae6dc"), false, 3.0)
			DrawBatch.line(self, Vector2(wx + 17.0, -ht + 34.0), Vector2(wx + 17.0, -ht + 74.0), Color("eae6dc"), 2.0)
			var lit := 0.55 + 0.45 * sin(_t * 1.3 + float(q))
			DrawBatch.rect(self, Rect2(wx + 2.0, -ht + 36.0, 13.0, 36.0), Color(1.0, 0.8, 0.45, 0.25 * lit))
		DrawBatch.rect(self, Rect2(hx1 - 70.0, -64.0, 30.0, 64.0), RED_LH.darkened(0.25))
		DrawBatch.circle(self, Vector2(hx1 - 46.0, -32.0), 2.0, Color("d8c070"))
		# המגדל: פסים אדומים-לבנים, צר למעלה
		var b0 := 46.0
		var b1 := 34.0
		var stripes := 6
		for q in stripes:
			var y0 := -g * float(q) / float(stripes)
			var y1 := -g * float(q + 1) / float(stripes)
			var w0 := lerpf(b0, b1, float(q) / float(stripes))
			var w1 := lerpf(b0, b1, float(q + 1) / float(stripes))
			var c := RED_LH if q % 2 == 0 else WHITE_LH
			DrawBatch.colored_polygon(self, PackedVector2Array([Vector2(-w0, y0), Vector2(w0, y0), Vector2(w1, y1), Vector2(-w1, y1)]), c)
			DrawBatch.colored_polygon(self, PackedVector2Array([Vector2(w0 * 0.35, y0), Vector2(w0, y0), Vector2(w1, y1), Vector2(w1 * 0.35, y1)]), Color(0, 0, 0, 0.14))   # צל עגול
			DrawBatch.colored_polygon(self, PackedVector2Array([Vector2(-w0 * 0.75, y0), Vector2(-w0 * 0.45, y0), Vector2(-w1 * 0.45, y1), Vector2(-w1 * 0.75, y1)]), Color(1, 1, 1, 0.12))
		for q in 3:   # חלונות קטנים במגדל
			var wy := -g * (0.25 + float(q) * 0.25)
			DrawBatch.rect(self, Rect2(-5.0, wy - 10.0, 10.0, 16.0), Color("1e2228"))
		for q in 5:   # חלודה שזולגת
			var rx := -30.0 + float(q) * 14.0
			DrawBatch.line(self, Vector2(rx, -g + 4.0), Vector2(rx + 1.0, -g + 30.0 + float(q % 3) * 20.0), Color(0.5, 0.25, 0.12, 0.35), 2.0)
		# מרפסת (הקומה) + מעקה
		DrawBatch.rect(self, Rect2(-62.0, -g, 124.0, 9.0), Color("3a3c40"))
		DrawBatch.rect(self, Rect2(-62.0, -g, 124.0, 2.0), Color("8a9098"))
		for q in 2:
			DrawBatch.line(self, Vector2(-62.0, -g - 18.0 - float(q) * 10.0 + 10.0), Vector2(62.0, -g - 18.0 - float(q) * 10.0 + 10.0), Color("2a2c30"), 2.0)
		for q in 9:
			DrawBatch.line(self, Vector2(-60.0 + float(q) * 15.0, -g), Vector2(-60.0 + float(q) * 15.0, -g - 18.0), Color("2a2c30"), 1.6)
		for q in 4:   # תומכות מתחת למרפסת
			DrawBatch.line(self, Vector2(-60.0 + float(q) * 40.0, -g + 9.0), Vector2(-b1 * 0.9 + float(q) * b1 * 0.6, -g + 30.0), Color("2a2c30"), 2.0)
		# חדר העדשה: זכוכית, כיפה אדומה, עדשה מסתובבת
		DrawBatch.rect(self, Rect2(-24.0, -g - 52.0, 48.0, 52.0), Color("2a3440"))
		var lamp := Vector2(0, -g - 28.0)
		var rot := fmod(_t * 0.9, TAU)
		var face := cos(rot)
		Kit.soft_glow(self, lamp, 46.0 + 18.0 * maxf(face, 0.0), Color(1.0, 0.92, 0.6, 0.55 + 0.35 * maxf(face, 0.0)))
		DrawBatch.circle(self, lamp, 9.0, Color(1.0, 0.96, 0.8))
		for q in 4:
			DrawBatch.line(self, Vector2(-24.0 + float(q) * 16.0, -g - 52.0), Vector2(-24.0 + float(q) * 16.0, -g), Color("1a1e24"), 2.0)
		DrawBatch.colored_polygon(self, PackedVector2Array([Vector2(-30, -g - 52), Vector2(30, -g - 52), Vector2(18, -g - 70), Vector2(0, -g - 78), Vector2(-18, -g - 70)]), RED_LH.darkened(0.15))
		DrawBatch.line(self, Vector2(0, -g - 78), Vector2(0, -g - 92), Color("2a2c30"), 2.0)
		DrawBatch.circle(self, Vector2(0, -g - 92), 3.0, Color("2a2c30"))
		# האלומה: נמתחת ומתקצרת כשהיא "מסתובבת"
		var reach := 700.0 * absf(face) + 60.0
		var side := signf(face) if face != 0.0 else 1.0
		var a := 0.22 * absf(face) + 0.04 + beams * 0.2
		var tip := lamp + Vector2(side * reach, 26.0)
		DrawBatch.polygon(self, PackedVector2Array([lamp + Vector2(0, -6), tip + Vector2(0, -60), tip + Vector2(0, 60), lamp + Vector2(0, 6)]),
			PackedColorArray([Color(1.0, 0.95, 0.7, a), Color(1.0, 0.95, 0.7, 0.0), Color(1.0, 0.95, 0.7, 0.0), Color(1.0, 0.95, 0.7, a)]))
		# דלת המגדל
		DrawBatch.rect(self, Rect2(-12.0, -46.0, 24.0, 46.0), Color("3a2a24"))
		DrawBatch.arc(self, Vector2(0, -46.0), 12.0, PI, TAU, 10, Color("3a2a24"), 3.0)


# ============================================================
#  מיכל שמן לווייתנים חלוד (הגג = קומה)
# ============================================================
class Tank extends Node2D:
	var w := 170.0
	var tier := 165.0
	var seed_v := 0

	func _ready() -> void:
		z_index = -2

	func _draw() -> void:
		var r := RandomNumberGenerator.new()
		r.seed = seed_v
		var bands := 10
		for q in bands:   # גליל: הצללה אנכית
			var k := float(q) / float(bands)
			var shade := 0.75 + 0.35 * sin(k * PI) - 0.2 * k
			var c := RUST.lerp(RUST_D, 1.0 - shade)
			DrawBatch.rect(self, Rect2(w * k, -tier, w / float(bands) + 1.0, tier), c)
		for q in 4:   # תפרים אופקיים + מסמרות
			var yy := -tier + 10.0 + float(q) * (tier - 20.0) / 3.0
			DrawBatch.line(self, Vector2(0, yy), Vector2(w, yy), Color(0.25, 0.12, 0.06, 0.7), 2.0)
			var x := 6.0
			while x < w:
				DrawBatch.circle(self, Vector2(x, yy - 3.0), 1.2, Color(0.75, 0.45, 0.3, 0.6))
				x += 12.0
		for q in 7:   # חלודה זולגת
			var rx := r.randf_range(8.0, w - 8.0)
			var ln := r.randf_range(30.0, tier * 0.8)
			DrawBatch.line(self, Vector2(rx, -tier + 4.0), Vector2(rx + r.randf_range(-3, 3), -tier + ln), Color(0.3, 0.12, 0.05, 0.45), r.randf_range(3.0, 6.0))
		DrawBatch.string(self, ThemeDB.fallback_font, Vector2(16.0, -tier * 0.48), "C.B.A. 1912", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.9, 0.8, 0.6, 0.35))
		# כיפה שטוחה + מעקה על הגג
		DrawBatch.colored_polygon(self, PackedVector2Array([Vector2(-4, -tier), Vector2(w + 4, -tier), Vector2(w - 10, -tier - 8), Vector2(10, -tier - 8)]), RUST_L.darkened(0.2))
		DrawBatch.line(self, Vector2(0, -tier), Vector2(w, -tier), Color("d0a080"), 1.5)
		for q in int(w / 20.0) + 1:
			DrawBatch.line(self, Vector2(float(q) * 20.0, -tier - 8.0), Vector2(float(q) * 20.0, -tier - 26.0), Color("2e1e18"), 1.8)
		DrawBatch.line(self, Vector2(0, -tier - 26.0), Vector2(w, -tier - 26.0), Color("2e1e18"), 2.0)
		DrawBatch.line(self, Vector2(0, -tier - 16.0), Vector2(w, -tier - 16.0), Color("2e1e18"), 1.2)
		# צינור + ברז בתחתית
		DrawBatch.rect(self, Rect2(w - 14.0, -40.0, 30.0, 10.0), RUST_D)
		DrawBatch.circle(self, Vector2(w + 18.0, -35.0), 7.0, Color("6a2a1a"))
		DrawBatch.colored_polygon(self, Art.ellipse(Vector2(w + 10.0, -2.0), 30.0, 3.0, 0.0, 12), Color(0.1, 0.08, 0.06, 0.6))   # שלולית שמן ישנה


# ============================================================
#  עגורן ההפשטה (הקורה העליונה = קומה). הוו (GantryHook) נתלה ממנו בנפרד.
# ============================================================
class Gantry extends Node2D:
	var w := 260.0
	var tier := 205.0

	func _ready() -> void:
		z_index = -2

	func _draw() -> void:
		var c := Color("4a3026")
		var hi := Color("9a5a3a")
		for lx: float in [10.0, w - 10.0]:   # רגליים בצורת A
			DrawBatch.line(self, Vector2(lx - 24.0, 0), Vector2(lx, -tier), c, 9.0)
			DrawBatch.line(self, Vector2(lx + 24.0, 0), Vector2(lx, -tier), c, 9.0)
			DrawBatch.line(self, Vector2(lx - 24.0, 0), Vector2(lx, -tier), hi, 1.5)
			DrawBatch.line(self, Vector2(lx - 14.0, -tier * 0.45), Vector2(lx + 14.0, -tier * 0.45), c, 5.0)
		DrawBatch.rect(self, Rect2(-6.0, -tier - 4.0, w + 12.0, 14.0), c)   # הקורה
		DrawBatch.line(self, Vector2(-6.0, -tier - 4.0), Vector2(w + 6.0, -tier - 4.0), hi, 2.0)
		var x := 0.0
		while x < w:   # קורת מסבך
			DrawBatch.line(self, Vector2(x, -tier + 10.0), Vector2(x + 20.0, -tier + 26.0), c, 3.0)
			DrawBatch.line(self, Vector2(x + 20.0, -tier + 26.0), Vector2(x + 40.0, -tier + 10.0), c, 3.0)
			x += 40.0
		DrawBatch.line(self, Vector2(0, -tier + 26.0), Vector2(w, -tier + 26.0), c, 4.0)
		for q in int(w / 14.0):   # קרשי הדק
			DrawBatch.rect(self, Rect2(float(q) * 14.0 - 4.0, -tier - 8.0, 12.0, 4.0), Color("6a5440").darkened(0.1 * float(q % 3)))
		DrawBatch.string(self, ThemeDB.fallback_font, Vector2(w * 0.5 - 42.0, -tier + 7.0), "CAPACIDAD 40 T", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.95, 0.85, 0.6, 0.55))


# ============================================================
#  שלד לווייתן ענק מעל הדרך (קרש הליכה על עמוד השדרה = קומה)
# ============================================================
class WhaleSkeleton extends Node2D:
	var w := 440.0
	var tier := 170.0
	var _t := 0.0

	func _ready() -> void:
		z_index = -2

	func spine_y(x: float) -> float:
		return -tier - sin(clampf(x / w, 0.0, 1.0) * PI) * 16.0

	func _draw() -> void:
		var pts := PackedVector2Array()
		var cols := PackedColorArray()
		# צלעות מאחור (כהות) ומלפנים (בהירות)
		for side in 2:
			var c := BONE_D.darkened(0.25) if side == 0 else BONE
			var n := int(w / 46.0)
			for q in n:
				var x := 50.0 + float(q) * (w - 90.0) / float(n - 1)
				var top := Vector2(x, spine_y(x) + 8.0)
				var hh := -top.y - 8.0
				var bend := (24.0 + 20.0 * sin(float(q) / float(n) * PI)) * (1.0 if side == 1 else -0.6)
				var prev := top
				for k in range(1, 9):
					var u := float(k) / 8.0
					var p := top + Vector2(sin(u * PI * 0.95) * bend + u * 8.0, u * hh * 0.92)
					var wd := lerpf(6.0, 2.4, u)
					var d := (p - prev).normalized().orthogonal() * wd * 0.5
					U.quad(pts, cols, prev - d, prev + d, p + d, p - d, c, c, c, c)
					prev = p
		U.flush(self, pts, cols)
		# עמוד השדרה: חוליות
		var x := 30.0
		while x < w - 10.0:
			var y := spine_y(x)
			DrawBatch.colored_polygon(self, Art.ellipse(Vector2(x, y + 4.0), 11.0, 8.0, 0.0, 12), BONE)
			DrawBatch.line(self, Vector2(x, y - 2.0), Vector2(x - 4.0, y - 14.0), BONE_D, 4.0)
			DrawBatch.circle(self, Vector2(x, y + 4.0), 3.0, BONE_D)
			x += 22.0
		# קרשי הליכה על השדרה
		DrawBatch.rect(self, Rect2(0, -tier - 6.0, w, 8.0), Color("6a5236"))
		DrawBatch.line(self, Vector2(0, -tier - 6.0), Vector2(w, -tier - 6.0), Color("a88a5a"), 1.5)
		for q in int(w / 30.0):
			DrawBatch.line(self, Vector2(float(q) * 30.0, -tier - 6.0), Vector2(float(q) * 30.0, -tier + 2.0), Color("3a2a1a"), 1.5)
		# הגולגולת והלסתות בקצה השמאלי
		DrawBatch.colored_polygon(self, PackedVector2Array([Vector2(-10, -tier - 6), Vector2(-60, -tier + 6), Vector2(-120, -tier + 40), Vector2(-150, -tier + 70), Vector2(-60, -tier + 50), Vector2(0, -tier + 30)]), BONE)
		DrawBatch.polyline(self, PackedVector2Array([Vector2(-20, -tier + 34), Vector2(-90, -tier + 70), Vector2(-150, -tier + 120), Vector2(-170, -tier + 168)]), BONE_D, 9.0)
		DrawBatch.polyline(self, PackedVector2Array([Vector2(-20, -tier + 34), Vector2(-90, -tier + 70), Vector2(-150, -tier + 120), Vector2(-170, -tier + 168)]), BONE, 5.0)
		DrawBatch.circle(self, Vector2(-40, -tier + 20), 8.0, Color("3a3024"))


# ============================================================
#  מלכודת: מיכל שמן לווייתנים על הדרך. ירייה / פיצוץ -> השמן פורץ, נשפך לכתם (Slick) ונדלק
# ============================================================
class OilBurst extends Node2D:
	const SPREAD := 300.0
	const IGNITE_T := 0.7
	const BURN_T := 6.0
	var state := 0                  # 0 = שלם, 1 = נפרץ
	var bursts := 0                 # לבדיקות
	var slick: Node2D = null
	var _t := 0.0
	var _ig := -1.0
	var _body: StaticBody2D = null

	func _ready() -> void:
		z_index = 0
		add_to_group("blastable")
		_body = BurstBody.new()
		_body.trap = self
		_body.collision_layer = 4
		_body.collision_mask = 0
		_body.add_to_group("no_outline")
		var cs := CollisionShape2D.new()
		var rs := RectangleShape2D.new()
		rs.size = Vector2(54.0, 66.0)
		cs.shape = rs
		cs.position = Vector2(0, -42.0)
		_body.add_child(cs)
		add_child(_body)

	func blast_rect() -> Rect2:
		return Rect2(global_position + Vector2(-30, -76), Vector2(60, 76))

	func hit_by_blast(_c: Vector2, _r: float) -> void:
		burst()

	func burst() -> void:
		if state != 0:
			return
		state = 1
		bursts += 1
		_ig = IGNITE_T
		_body.collision_layer = 0
		Sfx.play("s57_burst", global_position + Vector2(0, -40), 4.0, 0.08, 2)
		Particles.burst(get_parent(), global_position + Vector2(0, -44), "smoke", Vector2.UP, 6)
		Particles.burst(get_parent(), global_position + Vector2(0, -40), "hit", Vector2(0, -1), 10)
		slick = Slick.new()
		slick.w = SPREAD
		slick.life = 16.0
		slick.grow_t = 0.6
		get_parent().add_child(slick)
		slick.global_position = global_position + Vector2(0, -1)
		var cam := get_viewport().get_camera_2d()
		if cam != null and cam.has_method("shake") and Art.on_screen(self, global_position, 0.0):
			cam.shake(6.0, 0.25)

	func _physics_process(delta: float) -> void:
		_t += delta
		if _ig > 0.0:
			_ig -= delta
			if Engine.get_physics_frames() % 3 == 0:
				Particles.burst(get_parent(), global_position + Vector2(randf_range(-10, 10), -34), "spark", Vector2.DOWN, 2)
			if _ig <= 0.0 and slick != null and is_instance_valid(slick):
				slick.ignite()
		if Engine.get_physics_frames() % 3 == 0 and Art.on_screen(self, global_position, 120.0):
			queue_redraw()

	func _draw() -> void:
		DrawBatch.line(self, Vector2(-22, 0), Vector2(-18, -18), Color("3a2a22"), 4.0)   # רגליים
		DrawBatch.line(self, Vector2(22, 0), Vector2(18, -18), Color("3a2a22"), 4.0)
		var body := Rect2(-26, -76, 52, 60)
		for q in 6:
			var k := float(q) / 6.0
			DrawBatch.rect(self, Rect2(body.position.x + body.size.x * k, body.position.y, body.size.x / 6.0 + 1.0, body.size.y), RUST.lerp(RUST_D, absf(k - 0.35) * 1.3))
		DrawBatch.colored_polygon(self, Art.ellipse(Vector2(0, -76), 26.0, 6.0, 0.0, 14), RUST_L.darkened(0.15))
		DrawBatch.rect(self, Rect2(-26, -50, 52, 2), Color(0.2, 0.08, 0.04, 0.8))
		DrawBatch.string(self, ThemeDB.fallback_font, Vector2(-20, -58), "ACEITE", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.95, 0.85, 0.6, 0.6))
		if state == 0:
			# כתם חלודה אדום = נקודה לירות בה + טפטוף
			DrawBatch.circle(self, Vector2(6, -36), 7.0, Color("c0442a"))
			DrawBatch.circle(self, Vector2(6, -36), 3.0, Color("6a1a0a"))
			var dk := fmod(_t * 0.8, 1.0)
			DrawBatch.circle(self, Vector2(6, -28 + dk * 26.0), 1.6, Color(0.12, 0.1, 0.06, 1.0 - dk))
			DrawBatch.colored_polygon(self, Art.ellipse(Vector2(8, -1), 14.0, 2.0, 0.0, 10), Color(0.08, 0.06, 0.04, 0.7))
		else:
			# חור קרוע עם פח מקופל
			DrawBatch.colored_polygon(self, PackedVector2Array([Vector2(-10, -50), Vector2(4, -60), Vector2(16, -46), Vector2(10, -28), Vector2(-6, -24)]), Color("120c08"))
			DrawBatch.line(self, Vector2(4, -60), Vector2(14, -70), RUST_L, 3.0)
			DrawBatch.line(self, Vector2(16, -46), Vector2(30, -42), RUST_L, 3.0)
			DrawBatch.line(self, Vector2(-6, -24), Vector2(-16, -14), RUST_L, 3.0)
			if _t < 30.0:
				var k := clampf(1.0 - _t / 30.0, 0.0, 1.0)
				DrawBatch.line(self, Vector2(4, -30), Vector2(10, -2), Color(0.1, 0.08, 0.05, 0.9 * k), 4.0 * k + 1.0)


class BurstBody extends StaticBody2D:
	var trap = null

	func take_damage(_amount: int, hit_pos: Vector2, dir: Vector2, _explosive := false, _src := {}) -> void:
		if trap != null and is_instance_valid(trap):
			Particles.burst(trap.get_parent(), hit_pos, "spark", -dir, 4)
			trap.burst()


# ============================================================
#  כתם שמן (ממיכל / מ-BLUBBER שהתפוצץ): חלק, ונדלק מאש / פיצוץ / זומבי בוער
# ============================================================
class Slick extends Node2D:
	const SLIP := 0.35
	const STUMBLE := 0.12
	const BURN_T := 6.0
	static var ignites := 0         # לבדיקות
	static var slips := 0
	var w := 200.0
	var life := 14.0
	var grow_t := 0.4
	var burning := false
	var col := Color(0.08, 0.06, 0.04)
	var _g := 0.0
	var _t := 0.0
	var _fire: Node2D = null
	var _life0 := 14.0
	var _slip_cd := 0.0

	func _ready() -> void:
		z_index = 2
		_life0 = life
		add_to_group("s57_slicks")
		add_to_group("blastable")

	func cur_w() -> float:
		return w * _g

	func blast_rect() -> Rect2:
		return Rect2(global_position + Vector2(-cur_w() * 0.5, -20), Vector2(cur_w(), 24))

	func hit_by_blast(_c: Vector2, _r: float) -> void:
		ignite()

	func ignite() -> void:
		if burning or life <= 0.6:
			return
		burning = true
		ignites += 1
		_fire = FireZone.new()
		_fire.setup(maxf(cur_w(), 60.0), minf(BURN_T, life))
		get_parent().add_child(_fire)
		_fire.global_position = global_position
		Sfx.play("s57_whoosh", global_position, 3.0, 0.1, 2)
		life = minf(life, BURN_T + 0.4)
		for s in get_tree().get_nodes_in_group("s57_slicks"):   # נדלק גם כתם סמוך
			if s != self and not s.burning and absf(s.global_position.x - global_position.x) < (cur_w() + s.cur_w()) * 0.5 + 40.0 and absf(s.global_position.y - global_position.y) < 20.0:
				s.ignite.call_deferred()

	func douse() -> void:   # גל שוטף את הכתם
		if _fire != null and is_instance_valid(_fire):
			_fire.life = minf(_fire.life, 0.3)
		burning = false
		life = minf(life, 0.8)

	func _physics_process(delta: float) -> void:
		_t += delta
		_g = minf(1.0, _g + delta / maxf(grow_t, 0.01))
		life -= delta
		_slip_cd -= delta
		if life <= 0.0:
			queue_free()
			return
		var hw := cur_w() * 0.5
		var pl := get_tree().get_first_node_in_group("player") as Node2D
		if pl != null and not pl.dead and absf(pl.global_position.x - global_position.x) < hw and absf(pl.global_position.y - global_position.y) < 8.0 and pl.is_on_floor():
			pl.slip_t = maxf(pl.slip_t, SLIP)
			if _slip_cd <= 0.0:
				_slip_cd = 1.0
				slips += 1
		if Engine.get_physics_frames() % 10 == 0:
			for z in get_tree().get_nodes_in_group("zombies"):
				if z.dead or absf(z.global_position.x - global_position.x) > hw or absf(z.global_position.y - global_position.y) > 8.0:
					continue
				if not burning and float(z._burn_t) > 0.0:
					ignite()
				elif not z.is_boss() and absf(z.velocity.x) > 40.0 and randf() < STUMBLE:
					z.stagger(0.5)
			if not burning:
				for h in get_tree().get_nodes_in_group("hazards"):
					if h != _fire and h.get("zombie_burn") != null and float(h.zombie_burn) > 0.0 and absf(h.global_position.x - global_position.x) < hw + 20.0 and absf(h.global_position.y - global_position.y) < 40.0:
						ignite()
						break
		if Engine.get_physics_frames() % 4 == 0 and Art.on_screen(self, global_position, cur_w()):
			queue_redraw()

	func _draw() -> void:
		var hw := cur_w() * 0.5
		if hw < 1.0:
			return
		var a := clampf(life / 1.5, 0.0, 1.0)
		var c := col.darkened(0.3) if burning else col
		var pts := PackedVector2Array()
		var cols := PackedColorArray()
		U.oval(pts, cols, Vector2(0, 1.0), hw, 3.4, Color(c, 0.85 * a), 16)
		if not burning:   # ברק קשת בענן של שמן
			for q in 5:
				var x := fposmod(float(q) * 0.37 + _t * 0.05, 1.0) * hw * 1.6 - hw * 0.8
				var hue := fposmod(float(q) * 0.21 + _t * 0.1, 1.0)
				U.oval(pts, cols, Vector2(x, 0.5), hw * 0.18, 1.0, Color.from_hsv(hue, 0.5, 0.7, 0.28 * a), 8)
			U.oval(pts, cols, Vector2(-hw * 0.3, -0.2), hw * 0.4, 0.6, Color(1, 1, 1, 0.22 * a), 8)
		U.flush(self, pts, cols)


# ============================================================
#  מלכודת: וו ענק על שרשרת מעגורן ההפשטה
# ============================================================
class GantryHook extends Node2D:
	const TRIG_R := 150.0
	const WIND_T := 0.7
	const SWING_T := 0.95
	const SETTLE_T := 1.6
	const CD := 3.5
	const ANG := 1.15
	const DMG := 1
	const DMG_Z := 70
	var tier := 205.0
	var length := 170.0
	var state := 0                  # 0 שקט, 1 נמשך לאחור, 2 מתנדנד, 3 נרגע
	var swings := 0                 # לבדיקות
	var hits := 0
	var hooked := 0
	var _t := 0.0
	var _tt := 0.0
	var _cd := 1.0
	var _a := 0.0
	var _side := 1.0
	var _hit := false
	var _hit_z := {}
	var _said := false
	var _body: StaticBody2D = null

	func _ready() -> void:
		z_index = 4
		add_to_group("hazards")
		_body = HookBody.new()
		_body.trap = self
		_body.collision_layer = 4
		_body.collision_mask = 0
		_body.add_to_group("no_outline")
		var cs := CollisionShape2D.new()
		var rs := RectangleShape2D.new()
		rs.size = Vector2(26, 26)
		cs.shape = rs
		_body.add_child(cs)
		_body.position = anchor()
		add_child(_body)

	func anchor() -> Vector2:
		return Vector2(0, -tier + 22.0)

	func hook_pos() -> Vector2:
		return anchor() + Vector2(sin(_a), cos(_a)) * length

	func world_rect() -> Rect2:
		return Rect2(global_position + Vector2(-length, -80), Vector2(length * 2.0, 80))

	func danger_at(p: Vector2, margin := 0.0) -> bool:
		return state >= 1 and state <= 2 and world_rect().grow(margin).has_point(p)

	func release(from_side := 0.0) -> void:   # ירייה בגלגלת / השחקן מתחת
		if state != 0 or _cd > 0.0:
			return
		var pl := get_tree().get_first_node_in_group("player") as Node2D
		_side = from_side if from_side != 0.0 else (signf(global_position.x - pl.global_position.x) if pl != null else 1.0)
		if _side == 0.0:
			_side = 1.0
		state = 1
		_t = WIND_T
		Sfx.play("s57_chain", global_position + anchor(), 2.0, 0.1, 2)

	func _physics_process(delta: float) -> void:
		_tt += delta
		_cd -= delta
		var pl := get_tree().get_first_node_in_group("player") as Node2D
		match state:
			0:
				_a = sin(_tt * 1.1) * 0.05
				if pl != null and not pl.dead and _cd <= 0.0 and absf(pl.global_position.x - global_position.x) < TRIG_R and absf(pl.global_position.y - global_position.y) < 60.0:
					release()
			1:
				_t -= delta
				var k := 1.0 - _t / WIND_T
				_a = _side * ANG * (k * k * (3.0 - 2.0 * k)) + sin(_tt * 40.0) * 0.02
				if _t <= 0.0:
					state = 2
					_t = SWING_T
					_hit = false
					_hit_z.clear()
					swings += 1
					Sfx.play("s57_swoosh", global_position + Vector2(0, -60), 3.0, 0.1, 2)
			2:
				_t -= delta
				var k := 1.0 - _t / SWING_T
				_a = _side * ANG * cos(k * PI)
				_check(pl)
				if _t <= 0.0:
					state = 3
					_t = SETTLE_T
			3:
				_t -= delta
				var k := 1.0 - _t / SETTLE_T
				_a = -_side * ANG * 0.6 * cos(k * PI * 3.0) * (1.0 - k)
				if _t <= 0.0:
					state = 0
					_cd = CD
		_body.position = anchor() + Vector2(0, 4)
		if Art.on_screen(self, global_position + Vector2(0, -100), length + 100.0):
			queue_redraw()

	func _check(pl: Node2D) -> void:
		var hp := global_position + hook_pos()
		if pl != null and not pl.dead and not _hit and pl.body_rect().grow(8.0).has_point(hp):
			_hit = true
			hits += 1
			pl.hurt(DMG, Vector2(-_side * 1.6, -0.5))
		for z in get_tree().get_nodes_in_group("zombies"):
			if z.dead or z.is_boss() or _hit_z.has(z):
				continue
			var zr := Rect2(z.global_position + Vector2(-16, -56.0 * z.sc), Vector2(32, 56.0 * z.sc))
			if zr.grow(6.0).has_point(hp):
				_hit_z[z] = true
				hooked += 1
				Particles.burst(get_parent(), hp, "hit", Vector2(-_side, -0.3), 10)
				z.take_damage(DMG_Z, hp, Vector2(-_side, -0.4), false, {"source": "hazard", "fixed": DMG_Z})
				if not _said:
					_said = true
					z._popup("HOOKED", Color("e0a070"), 16, -90.0)

	func _draw() -> void:
		var an := anchor()
		var hp := hook_pos()
		# הגלגלת
		DrawBatch.rect(self, Rect2(an.x - 12, an.y - 18, 24, 20), Color("3a2a22"))
		DrawBatch.circle(self, an + Vector2(0, -8), 8.0, Color("6a4030"))
		DrawBatch.circle(self, an + Vector2(0, -8), 3.0, Color("2a1a14"))
		if state == 0 and _cd <= 0.0:
			Art.glow(self, an + Vector2(0, -8), 12.0, Color(1.0, 0.5, 0.2, 0.25 + 0.15 * sin(_tt * 4.0)))
		# שרשרת (חוליות)
		var n := 16
		for q in n:
			var p := an.lerp(hp, (float(q) + 0.5) / float(n))
			var d := (hp - an).normalized()
			if q % 2 == 0:
				DrawBatch.line(self, p - d * 4.0, p + d * 4.0, Color("5a3a28"), 3.4)
			else:
				DrawBatch.arc(self, p, 3.0, d.angle() - 1.2, d.angle() + 1.2, 6, Color("7a4a30"), 1.6)
		# הוו: חלודה כבדה, מסובב לפי הנדנוד
		DrawBatch.set_transform(self, hp, -_a, Vector2.ONE)
		DrawBatch.rect(self, Rect2(-6, -8, 12, 10), Color("4a2a1a"))
		DrawBatch.arc(self, Vector2(0, 12), 13.0, -PI * 0.1, PI * 1.25, 14, Color("2a1810"), 7.0)
		DrawBatch.arc(self, Vector2(0, 12), 13.0, -PI * 0.1, PI * 1.25, 14, RUST, 4.5)
		DrawBatch.colored_polygon(self, PackedVector2Array([Vector2(13, 10), Vector2(18, -2), Vector2(9, 6)]), RUST_L)
		DrawBatch.arc(self, Vector2(0, 12), 13.0, PI * 0.3, PI * 0.8, 6, Color(1.0, 0.75, 0.5, 0.5), 1.2)
		if hooked > 0:
			DrawBatch.line(self, Vector2(-8, 22), Vector2(-4, 34), Color(0.5, 0.05, 0.05, 0.85), 2.0)   # דם מטפטף
		DrawBatch.set_transform_matrix(self, Transform2D.IDENTITY)
		if state == 1:
			DrawBatch.string(self, ThemeDB.fallback_font, an + Vector2(-6, 40), "!", HORIZONTAL_ALIGNMENT_LEFT, -1, 26, Color(1.0, 0.5, 0.2, 0.6 + 0.4 * sin(_tt * 30.0)))


class HookBody extends StaticBody2D:
	var trap = null

	func take_damage(_amount: int, hit_pos: Vector2, dir: Vector2, _explosive := false, _src := {}) -> void:
		if trap != null and is_instance_valid(trap):
			Particles.burst(trap.get_parent(), hit_pos, "spark", -dir, 5)
			Sfx.play("metal_ping", hit_pos, -2.0, 0.1, 2)
			trap.release()


# ============================================================
#  מלכודת: הים שוטף את החוף
# ============================================================
class WaveSurge extends Node2D:
	const CD := Vector2(6.5, 9.5)
	const WARN_T := 1.1
	const SURGE_T := 1.2
	const PUSH := 360.0
	const NEAR := 260.0
	var w := 520.0
	var state := 0                  # 0 שקט, 1 גל מתרומם, 2 שוטף
	var surges := 0                 # לבדיקות
	var pushes := 0
	var knocked := 0
	var _t := 2.5
	var _tt := 0.0
	var _pushed := false
	var _knock := {}
	var _back: Node2D = null
	var _said := false

	func _ready() -> void:
		z_index = 4
		add_to_group("hazards")
		_back = WaveBack.new()
		_back.wave = self
		_back.z_index = -6
		add_child(_back)

	func world_rect() -> Rect2:
		return Rect2(global_position + Vector2(0, -30), Vector2(w, 30))

	func danger_at(p: Vector2, margin := 0.0) -> bool:
		return state >= 1 and world_rect().grow(margin).has_point(p)

	func trigger() -> void:
		if state == 0:
			state = 1
			_t = WARN_T
			Sfx.play("s57_wave_roar", global_position + Vector2(w * 0.5, -60), 3.0, 0.1, 2)

	# כמה מהקטע הים מכסה עכשיו (0..1) - הגל נכנס מימין ויוצא
	func cover() -> float:
		if state != 2:
			return 0.0
		var k := 1.0 - _t / SURGE_T
		return clampf(k * 2.4, 0.0, 1.0) * clampf((1.0 - k) * 3.0, 0.0, 1.0)

	func _physics_process(delta: float) -> void:
		_tt += delta
		_t -= delta
		var pl := get_tree().get_first_node_in_group("player") as Node2D
		match state:
			0:
				if _t <= 0.0 and pl != null and pl.global_position.x > global_position.x - NEAR and pl.global_position.x < global_position.x + w + NEAR:
					trigger()
			1:
				if _t <= 0.0:
					state = 2
					_t = SURGE_T
					surges += 1
					_pushed = false
					_knock.clear()
					Sfx.play("s57_wave_crash", global_position + Vector2(w * 0.5, -20), 4.0, 0.1, 2)
					for s in get_tree().get_nodes_in_group("s57_slicks"):
						if s.global_position.x > global_position.x - 40.0 and s.global_position.x < global_position.x + w + 40.0:
							s.douse()
			2:
				var front := global_position.x + w * (1.0 - cover())
				if Engine.get_physics_frames() % 3 == 0 and Art.on_screen(self, Vector2(front, global_position.y), 100.0):
					Particles.burst(get_parent(), Vector2(front, global_position.y - 6.0), "drop", Vector2(-1, -1), 3)
				if pl != null and not pl.dead and pl.global_position.x > front and pl.global_position.x < global_position.x + w + 10.0 and absf(pl.global_position.y - global_position.y) < 10.0:
					pl.velocity.x = move_toward(pl.velocity.x, -PUSH, 2600.0 * delta)
					pl.slip_t = maxf(pl.slip_t, 0.5)
					if not _pushed:
						_pushed = true
						pushes += 1
						if not _said:
							_said = true
							pl._say("The sea!", Color("a8d8ff"))
				if Engine.get_physics_frames() % 4 == 0:
					for z in get_tree().get_nodes_in_group("zombies"):
						if z.dead or z.is_boss() or _knock.has(z):
							continue
						if z.global_position.x > front and z.global_position.x < global_position.x + w and absf(z.global_position.y - global_position.y) < 10.0:
							_knock[z] = true
							knocked += 1
							z.stagger(1.0)
							z.velocity.x -= 260.0
							if Art.on_screen(z, z.global_position):
								Particles.burst(get_parent(), z.global_position + Vector2(0, -10), "drop", Vector2.UP, 5)
				if _t <= 0.0:
					state = 0
					_t = randf_range(CD.x, CD.y)
		if Art.on_screen(self, global_position + Vector2(w * 0.5, 0), w * 0.5 + 60.0):
			queue_redraw()
			_back.queue_redraw()

	func _draw() -> void:
		var pts := PackedVector2Array()
		var cols := PackedColorArray()
		# קו קצף רגיל שזז על החול הרטוב (תמיד)
		var x := 0.0
		while x < w:
			var y := 14.0 + sin(x * 0.03 + _tt * 1.6) * 2.0
			var a := 0.35 + 0.25 * sin(x * 0.05 - _tt * 2.0)
			U.quad(pts, cols, Vector2(x, y), Vector2(x + 24.0, y + sin((x + 24.0) * 0.03 + _tt * 1.6) * 2.0 - sin(x * 0.03 + _tt * 1.6) * 2.0), Vector2(x + 24.0, y + 3.0), Vector2(x, y + 3.0), Color(FOAM, a), Color(FOAM, a), Color(FOAM, 0.0), Color(FOAM, 0.0))
			x += 24.0
		var cv := cover()
		if cv > 0.0:   # המים שוטפים את הדרך
			var front := w * (1.0 - cv)
			U.quad(pts, cols, Vector2(front, -24.0), Vector2(w + 30.0, -30.0), Vector2(w + 30.0, 4.0), Vector2(front, 4.0), Color(0.55, 0.7, 0.78, 0.0), Color(0.45, 0.6, 0.7, 0.7), Color(0.4, 0.55, 0.65, 0.7), Color(0.6, 0.75, 0.82, 0.5))
			var fx := front
			while fx < w + 20.0:   # קצף על פני המים
				var fy := -22.0 + sin(fx * 0.08 + _tt * 9.0) * 3.0
				U.oval(pts, cols, Vector2(fx, fy), 9.0, 3.0, Color(FOAM, 0.8 if fx < front + 40.0 else 0.4), 6)
				fx += 13.0
			U.oval(pts, cols, Vector2(front, -14.0), 10.0, 16.0, Color(FOAM, 0.85), 8)
		U.flush(self, pts, cols)


# הגל שמתרומם מאחורי הדרך (מאחורי הדמויות)
class WaveBack extends Node2D:
	var wave = null

	func _draw() -> void:
		if wave == null:
			return
		var h := 0.0
		if wave.state == 1:
			var k: float = 1.0 - wave._t / wave.WARN_T
			h = k * 90.0
		elif wave.state == 2:
			h = 90.0 * clampf(wave._t / wave.SURGE_T - 0.4, 0.0, 1.0)
		if h <= 1.0:
			return
		var w: float = wave.w
		var tt: float = wave._tt
		var pts := PackedVector2Array()
		var cols := PackedColorArray()
		var x := -60.0
		while x < w + 60.0:
			var y0 := -20.0 - h * (0.8 + 0.2 * sin(x * 0.02 + tt * 3.0))
			var y1 := -20.0 - h * (0.8 + 0.2 * sin((x + 30.0) * 0.02 + tt * 3.0))
			U.quad(pts, cols, Vector2(x, y0), Vector2(x + 30.0, y1), Vector2(x + 30.0, -10.0), Vector2(x, -10.0), Color(0.35, 0.5, 0.58, 0.85), Color(0.35, 0.5, 0.58, 0.85), Color(0.25, 0.38, 0.46, 0.9), Color(0.25, 0.38, 0.46, 0.9))
			U.quad(pts, cols, Vector2(x, y0 - 4.0), Vector2(x + 30.0, y1 - 4.0), Vector2(x + 30.0, y1 + 6.0), Vector2(x, y0 + 6.0), Color(FOAM, 0.9), Color(FOAM, 0.9), Color(FOAM, 0.0), Color(FOAM, 0.0))
			x += 30.0
		U.flush(self, pts, cols)


# ============================================================
#  מלכודת: סלעים שטוחים רטובים עם אצות (מחליקים / זומבים מועדים)
# ============================================================
class SlickRocks extends Node2D:
	const SLIP := 0.3
	const STUMBLE := 0.35
	var w := 170.0
	var seed_v := 0
	var stumbles := 0               # לבדיקות
	var _seen := {}

	func _ready() -> void:
		z_index = 2

	func _physics_process(_delta: float) -> void:
		var pl := get_tree().get_first_node_in_group("player") as Node2D
		if pl == null or absf(pl.global_position.x - global_position.x) > 1400.0:
			return
		if not pl.dead and absf(pl.global_position.x - global_position.x) < w * 0.5 and absf(pl.global_position.y - global_position.y) < 8.0 and pl.is_on_floor():
			pl.slip_t = maxf(pl.slip_t, SLIP)
		if Engine.get_physics_frames() % 6 == 0:
			for z in get_tree().get_nodes_in_group("zombies"):
				if z.dead or z.is_boss():
					continue
				var on: bool = absf(z.global_position.x - global_position.x) < w * 0.45 and absf(z.global_position.y - global_position.y) < 8.0
				if on and not _seen.has(z):
					_seen[z] = true
					if randf() < STUMBLE and absf(z.velocity.x) > 20.0:
						stumbles += 1
						z.stagger(0.8)
						z._popup("SLIP", Color("b0d8c0"), 11, -70.0)
				elif not on and _seen.has(z):
					_seen.erase(z)

	func _draw() -> void:
		var r := RandomNumberGenerator.new()
		r.seed = seed_v
		var pts := PackedVector2Array()
		var cols := PackedColorArray()
		var x := -w * 0.5
		while x < w * 0.5:
			var rw := r.randf_range(26.0, 44.0)
			var c := Color("3e4446").lerp(Color("2a3032"), r.randf())
			U.oval(pts, cols, Vector2(x + rw * 0.5, 1.0), rw * 0.55, 5.0, c, 10)
			U.oval(pts, cols, Vector2(x + rw * 0.4, -1.6), rw * 0.3, 1.2, Color(0.85, 0.92, 0.95, 0.45), 8)   # ברק רטוב
			for q in 3:   # אצות
				var kx := x + r.randf_range(0.0, rw)
				U.quad(pts, cols, Vector2(kx, -1), Vector2(kx + r.randf_range(8, 16), r.randf_range(-3, 1)), Vector2(kx + r.randf_range(8, 16), 2), Vector2(kx, 2), KELP_L, KELP, KELP, KELP_L)
			x += rw * 0.85
		U.flush(self, pts, cols)


# ============================================================
#  מכשולים (מוצקים + מחסה)
# ============================================================
class Obstacle extends Node2D:
	var kind := "drums"
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
		var w := size.x
		var h := size.y
		var rim := Color(0.9, 0.92, 0.9, 0.5)
		var r := RandomNumberGenerator.new()
		r.seed = seed_v
		match kind:
			"drums":   # חביות שמן חלודות (2 למטה, 1 שוכבת למעלה)
				for q in 2:
					var dx := float(q) * w * 0.5
					var c := RUST.lerp(Color("5a6a6a"), float(q) * 0.5)
					DrawBatch.rect(self, Rect2(dx + 2.0, -h * 0.62, w * 0.5 - 4.0, h * 0.62), c)
					DrawBatch.rect(self, Rect2(dx + 2.0, -h * 0.62, w * 0.5 - 4.0, h * 0.62), Color(0, 0, 0, 0.5), false, 1.2)
					for b in 2:
						DrawBatch.line(self, Vector2(dx + 2.0, -h * (0.2 + 0.25 * float(b))), Vector2(dx + w * 0.5 - 2.0, -h * (0.2 + 0.25 * float(b))), Color(0, 0, 0, 0.35), 2.0)
					DrawBatch.line(self, Vector2(dx + 6.0, -h * 0.6), Vector2(dx + 7.0, -h * 0.1), Color(1, 1, 1, 0.18), 3.0)
				DrawBatch.colored_polygon(self, Art.ellipse(Vector2(w * 0.5, -h * 0.81), w * 0.3, h * 0.19, 0.0, 14), RUST_D)
				DrawBatch.colored_polygon(self, Art.ellipse(Vector2(w * 0.5 + w * 0.26, -h * 0.81), h * 0.08, h * 0.17, 0.0, 10), RUST_L)
				DrawBatch.line(self, Vector2(w * 0.22, -h), Vector2(w * 0.78, -h), rim, 1.4)
				DrawBatch.colored_polygon(self, Art.ellipse(Vector2(w * 0.3, 0), w * 0.35, 2.5, 0.0, 10), Color(0.06, 0.05, 0.04, 0.6))
			"boat":   # סירת משוטים הפוכה
				DrawBatch.colored_polygon(self, PackedVector2Array([Vector2(0, 0), Vector2(6, -h * 0.75), Vector2(w * 0.3, -h), Vector2(w * 0.8, -h * 0.95), Vector2(w, -h * 0.5), Vector2(w - 4, 0)]), Color("2e5a6a"))
				for q in 4:
					var yy := -h * (0.2 + 0.18 * float(q))
					DrawBatch.line(self, Vector2(4, yy), Vector2(w - 4, yy - 2.0), Color(0, 0, 0, 0.3), 1.4)
				DrawBatch.line(self, Vector2(w * 0.3, -h), Vector2(w * 0.8, -h * 0.95), rim, 1.5)
				DrawBatch.rect(self, Rect2(0, -6, w, 6), Color("e8e0d0"))
				DrawBatch.rect(self, Rect2(0, -6, w, 2), RED_LH)
				for q in 5:   # צבע מתקלף
					DrawBatch.circle(self, Vector2(r.randf_range(8, w - 8), -r.randf_range(8, h - 8)), r.randf_range(2.0, 5.0), Color("6a4a3a"))
				DrawBatch.line(self, Vector2(w * 0.9, -h * 0.4), Vector2(w + 20.0, -6.0), Color("8a6a40"), 4.0)   # משוט
			"boulders":   # סלעים עם אצות וגואנו
				DrawBatch.colored_polygon(self, PackedVector2Array([Vector2(0, 0), Vector2(4, -h * 0.6), Vector2(w * 0.3, -h), Vector2(w * 0.55, -h * 0.85), Vector2(w * 0.8, -h * 0.95), Vector2(w, -h * 0.4), Vector2(w, 0)]), Color("4a4e52"))
				DrawBatch.colored_polygon(self, PackedVector2Array([Vector2(w * 0.55, -h * 0.85), Vector2(w * 0.8, -h * 0.95), Vector2(w, -h * 0.4), Vector2(w, 0), Vector2(w * 0.6, 0)]), Color("3a3e42"))
				DrawBatch.line(self, Vector2(w * 0.3, -h), Vector2(w * 0.55, -h * 0.85), Color(0.95, 0.95, 0.9, 0.8), 3.0)
				for q in 6:
					var kx := r.randf_range(4, w - 4)
					DrawBatch.line(self, Vector2(kx, -r.randf_range(4, 14)), Vector2(kx + r.randf_range(-6, 6), 0), KELP_L, 3.0)
			_:   # ערימת חוליות לווייתן
				for q in 3:
					var c := Vector2(w * (0.22 + 0.28 * float(q)), -h * 0.35)
					DrawBatch.colored_polygon(self, Art.ellipse(c, w * 0.16, h * 0.34, 0.0, 14), BONE)
					DrawBatch.colored_polygon(self, Art.ellipse(c, w * 0.06, h * 0.12, 0.0, 10), BONE_D)
					DrawBatch.line(self, c + Vector2(0, -h * 0.3), c + Vector2(r.randf_range(-6, 6), -h * 0.62), BONE, 6.0)
					DrawBatch.line(self, c + Vector2(-w * 0.14, 0), c + Vector2(-w * 0.2, -h * 0.1), BONE_D, 3.0)
				DrawBatch.colored_polygon(self, Art.ellipse(Vector2(w * 0.5, -h * 0.82), w * 0.18, h * 0.18, 0.4, 12), BONE.darkened(0.08))


# ============================================================
#  חוף ה-BEACHMASTER (הזירה בסוף): סלעי מנוחה, מסילת גרירה, גולגולת לווייתן, שלט התחנה
# ============================================================
class BossBeach extends Node2D:
	var w := 1000.0

	func _ready() -> void:
		z_index = -3

	func _draw() -> void:
		# ערימות סלעים מעוגלים ורטובים מאחור (צל, גוף, אור מלמעלה, ברק רטוב, בלוטי ים, אצות)
		var pts := PackedVector2Array()
		var cols := PackedColorArray()
		var rocks := [[80, 30, 26], [130, 52, 40], [205, 60, 54], [280, 50, 44], [345, 40, 30], [400, 28, 20], [175, 24, 16], [318, 22, 14],
			[660, 34, 24], [730, 56, 42], [810, 62, 50], [890, 48, 36], [950, 30, 20]]
		for i in rocks.size():
			var r: Array = rocks[i]
			var c := Vector2(float(r[0]), -float(r[2]) * 0.55)
			var rx: float = r[1]
			var ry: float = r[2]
			var tone := 0.04 * (U.h(i, 3) - 0.5)
			U.oval(pts, cols, c + Vector2(4, 4), rx, ry, Color(0.12, 0.13, 0.15, 0.5), 14)
			U.oval(pts, cols, c, rx, ry, Color(0.3 + tone, 0.32 + tone, 0.35 + tone), 14)
			U.oval(pts, cols, c + Vector2(-rx * 0.15, -ry * 0.25), rx * 0.8, ry * 0.62, Color(0.42 + tone, 0.44 + tone, 0.46 + tone), 12)
			U.oval(pts, cols, c + Vector2(-rx * 0.3, -ry * 0.5), rx * 0.42, ry * 0.2, Color(0.75, 0.8, 0.85, 0.35), 10)   # ברק רטוב
			for q in 5:   # בלוטי ים
				var bp := c + Vector2((U.h(i * 7 + q, 5) - 0.5) * rx * 1.4, ry * (0.25 + 0.4 * U.h(i * 7 + q, 6)))
				U.dia(pts, cols, bp, 1.6, Color(0.82, 0.8, 0.72, 0.8))
			if i % 2 == 0:   # אצות תלויות
				var kx := c.x + rx * 0.3
				U.quad(pts, cols, Vector2(kx - 3, c.y - ry * 0.4), Vector2(kx + 3, c.y - ry * 0.4), Vector2(kx + 6, c.y + ry * 0.7), Vector2(kx - 1, c.y + ry * 0.7), KELP, KELP, KELP_L, KELP_L)
		U.flush(self, pts, cols)
		# מסילת הגרירה (שבה גררו את הלווייתנים מהים)
		for q in 2:
			DrawBatch.line(self, Vector2(440, -6.0 - float(q) * 10.0), Vector2(640, -30.0 - float(q) * 10.0), Color("3a2a22"), 4.0)
		for q in 9:
			var x := 450.0 + float(q) * 22.0
			DrawBatch.line(self, Vector2(x, -4.0 - float(q) * 2.6), Vector2(x + 6.0, -24.0 - float(q) * 2.6), Color("5a4430"), 4.0)
		# גולגולת לווייתן ענקית
		DrawBatch.colored_polygon(self, PackedVector2Array([Vector2(700, -60), Vector2(760, -110), Vector2(880, -122), Vector2(940, -100), Vector2(920, -70), Vector2(820, -64)]), BONE)
		DrawBatch.polyline(self, PackedVector2Array([Vector2(700, -60), Vector2(620, -40), Vector2(560, -10)]), BONE, 10.0)
		DrawBatch.polyline(self, PackedVector2Array([Vector2(720, -54), Vector2(650, -28), Vector2(600, 0)]), BONE_D, 8.0)
		DrawBatch.circle(self, Vector2(870, -100), 10.0, Color("2a2420"))
		# שלט
		DrawBatch.line(self, Vector2(250, 0), Vector2(250, -150), Color("3a2a1e"), 5.0)
		DrawBatch.line(self, Vector2(330, 0), Vector2(330, -150), Color("3a2a1e"), 5.0)
		DrawBatch.rect(self, Rect2(230, -176, 130, 40), Color("e0d8c4"))
		DrawBatch.rect(self, Rect2(230, -176, 130, 40), RED_LH, false, 3.0)
		DrawBatch.string(self, ThemeDB.fallback_font, Vector2(240, -160), "ESTACION BALLENERA", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("3a2a22"))
		DrawBatch.string(self, ThemeDB.fallback_font, Vector2(262, -145), "PUNTA 1906", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, RED_LH.darkened(0.2))


# ============================================================
#  מסך: רוח, רסס ים, פתיתי שלג, משב
# ============================================================
class CoastFX extends Node2D:
	const GUST_EVERY := Vector2(12.0, 19.0)
	var vp := Vector2(1280, 720)
	var gusts := 0                  # לבדיקות
	var _t := 0.0
	var _next := 7.0
	var _gust := -1.0

	func gust() -> void:
		_gust = 0.0
		gusts += 1
		Sfx.play("s57_wind", null, 0.0)

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
		var g := 0.0 if _gust < 0.0 else sin(clampf(_gust / 3.0, 0.0, 1.0) * PI)
		var q := clampf(Quality.ambient(), 0.3, 1.0)
		var pts := PackedVector2Array()
		var cols := PackedColorArray()
		for i in int((18.0 + 26.0 * g) * q):   # פסי רוח
			var sp := 650.0 + U.h(i, 1) * 450.0 + 600.0 * g
			var x := fposmod(U.h(i, 2) * vp.x * 3.0 - _t * sp, vp.x + 400.0) - 200.0
			var y := U.h(i, 3) * vp.y * 0.92 + sin(_t * 1.5 + float(i)) * 10.0
			var ln := 60.0 + U.h(i, 4) * 110.0
			var a := 0.05 + 0.05 * U.h(i, 5) + 0.07 * g
			U.quad(pts, cols, Vector2(x, y), Vector2(x + ln, y - 2.0), Vector2(x + ln, y - 1.0), Vector2(x, y + 1.2), Color(0.95, 0.97, 1.0, a), Color(0.95, 0.97, 1.0, 0.0), Color(0.95, 0.97, 1.0, 0.0), Color(0.95, 0.97, 1.0, a))
		for i in int(44.0 * q):   # פתיתי שלג / רסס שעפים שמאלה
			var sp := 120.0 + U.h(i, 6) * 160.0 + 300.0 * g
			var x := fposmod(U.h(i, 7) * vp.x * 2.0 - _t * sp, vp.x + 40.0) - 20.0
			var y := fposmod(U.h(i, 8) * vp.y + _t * (30.0 + U.h(i, 9) * 30.0) + sin(_t * 2.0 + float(i)) * 8.0, vp.y)
			U.dia(pts, cols, Vector2(x, y), 1.2 + U.h(i, 10) * 1.4, Color(1, 1, 1, 0.4 + 0.3 * U.h(i, 11)))
		U.flush(self, pts, cols)
		if g > 0.0:   # במשב: רסס ים על המסך
			for i in 4:
				Kit.soft_glow(self, Vector2(vp.x * (0.1 + 0.27 * float(i)) - _gust * 200.0, vp.y - 60.0 - float(i % 2) * 40.0), 160.0, Color(0.9, 0.95, 1.0, 0.1 * g), 0.4)
