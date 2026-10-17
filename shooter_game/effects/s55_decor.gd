extends RefCounted
# ============================================================
#  קישוטים לשלב 55 ("WIND STEPPE") - הערבה הפטגונית הריקה תחת שמיים ענקיים, רוח שלא נגמרת.
#  אחרי הגשר (54) הגיבור בפטגוניה: חוות כבשים (אסטנסיות), מחסן גז"ז, טורבינות רוח, גדרות תיל, גולגולות גואנקו,
#  עצים שכולם נוטים לאותו צד. הרוח היא המכונאי של השלב: היא מזיזה עשב, אבק, דגלים, כבשים, זומבים מעופפים וכדורי קוצים.
#    W             - מצב הרוח המשותף (stage_55 מעדכן כל פריים): wind (עם סימן, -1..1), mag, gust (0..1), warn (0..1),
#                    lean (כמה העשב נוטה), drift (מרחק מצטבר שהרוח "עברה" - לעננים / אבק), spin (זווית רוטורים)
#    steppe_sky    - (רקע) כחול פטגוני עמוק, שמש נמוכה במערב, עננים עדשתיים (lenticular) שעומדים במקום מעל האנדים,
#                    קרעי עננים שדוהרים ברוח (מהר יותר במשב), שני קונדורים חגים
#    far_andes     - (רקע, 0.06) האנדים: מחטי גרניט (כמו פיץ רוי) עם שלג, נוצות שלג שהרוח תולשת מהפסגות, קרחונים,
#                    רצועת אגם טורקיז מנצנצת, צללי עננים שרצים על הערבה
#    mid_estancia  - (רקע, 0.28) גבעות אוכרה, שורות צפצפה שמתכופפות במשב, הקאסקו של האסטנסיה (גג אדום), חוות טורבינות
#                    (הרוטורים לפי הרוח), עדר גואנקו, נקודות כבשים, כביש 40 עם ענן אבק
#    near_steppe   - (רקע, 0.6) עמודי גדר עם 4 חוטים, גולגולות על העמודים, ציצי קוירון שנוטים ורועדים, שיחי קלפטה,
#                    עצי ניירה כפופים, משאבת רוח אוסטרלית, כדורי קוצים מתגלגלים
#    steppe_overlay- ערפל אבק חם מאחורי הדמויות + זרמי אבק נמוכים לפי הרוח
#    SteppeGround  - (עולם) כביש חצץ (ripio), אדמה, אבנים, ציצי עשב בקצה שנוטים ברוח
#    WoolShed      - (עולם) מחסן הגז"ז: פח גלי, גמלון, דלת הזזה, "ESQUILA", עליית גג (קומה = add_floor), חבילות צמר
#    WaterTower    - (עולם) מגדל מים על רגליים עם במה (קומה)
#    Turbine       - (עולם) טורבינת רוח עם במת תחזוקה (קומה). broken = להב סדוק (מלכודת BladeDrop)
#    WindPump      - (עולם, מאחור) משאבת רוח אוסטרלית + מיכל ("australiano"), הגלגל מסתובב לפי הרוח
#    EstanciaArch  - (עולם) שער הכניסה "ESTANCIA LA VENTOSA" + דגל ארגנטינה שמתנופף
#    Puesto        - (עולם) בקתת רועים מאבן + פח, ארובה מעשנת, גולגולות על הגדר
#    WireFence     - (עולם, מאחור) גדר תיל ארוכה עם עמודים, כבשה מתה תקועה, צמר על התיל
#    SheetTrap     - (מלכודת) לוח פח רופף על גג המחסן: רועד (אזהרה) -> נתלש במשב ועף במורד הרוח בגובה ראש.
#                    פוגע בך (DMG), חותך זומבים (DMG_Z). לירות בו = נתלש מיד. SHEETS לוחות.
#    BladeDrop     - (מלכודת) להב שבור בטורבינה: חורק + צל על הקרקע (WARN_T) -> נופל ומתרסק (R). לירות בבורג האדום = עכשיו.
#    GasBottle     - (מלכודת) בלון גז (garrafa) ליד הבקתה: משב מפיל אותו -> מתגלגל במורד הרוח ושורק -> מתפוצץ אחרי FUSE.
#                    לירות בו = מתפוצץ איפה שהוא (גם על הזומבים). פיצוץ אחר מפוצץ אותו.
#    BarbedWire    - (מלכודת) גדר תיל דוקרני נמוכה על הכביש: הולכים דרכה = נתפס (האטה + לב, CD). לקפוץ!
#                    זומבים נתקעים ומדממים. כדורי קוצים (TUMBLER) נתפסים בתיל ונפתחים.
#    Corral        - (מלכודת) מכלאה: מתקרבים -> השער נפרץ -> עדר כבשים דוהר אליך (לא מזיק, אבל חוסם יריות) ובתוכו SHEARER.
#    Obstacle      - (מוצק + מחסה) "wool" חבילות צמר / "posts" ערימת עמודי גדר / "rusty" טנדר חלוד / "trough" שוקת
#    ShearingYard  - (עולם) חזית מחסן הגז"ז הגדול - הזירה של THE ESTANCIERO. WoolPress - מכבש צמר מוגבה (קומה).
#    WindFX / WindHud - (מסך) פסי אבק וזרעים לפי הרוח, הבזק במשב / שרוול רוח קטן + "GUST" באזהרה
#  לשנות: SheetTrap.WARN_T / V / DMG_Z / SHEETS, BladeDrop.WARN_T / R / DMG_Z, GasBottle.FUSE / ROLL_V / BOOM_R,
#         BarbedWire.W / SNAG_T / CD, Corral.N_SHEEP / TRIG_R / RUN_V.
# ============================================================

const Art := preload("res://art.gd")
const Sfx := preload("res://sfx.gd")
const Kit := preload("res://effects/backdrop_kit.gd")
const Particles := preload("res://particles.gd")
const Boom := preload("res://explosion.gd")
const DebrisScript := preload("res://debris.gd")

const OCHRE := Color("b08a52")
const OCHRE_D := Color("7a5c34")
const GRASS := Color("c8b070")
const GRASS_D := Color("8a7440")
const IRON := Color("8a8e90")
const IRON_D := Color("4e5254")
const RUST := Color("8a4a2a")
const WOOD := Color("6a4a30")
const WOOD_D := Color("3e2a1a")
const WHITE := Color("eee8dc")
const ROOF_RED := Color("a83a2a")


# ============================================================
#  מצב הרוח (סטטי - שכבות הרקע וכל המחלקות קוראות אותו)
# ============================================================
class W:
	static var wind := -0.4           # עם סימן: שלילי = נושבת שמאלה (מדרום, מול הגיבור)
	static var mag := 0.4
	static var gust := 0.0            # 0..1 עוצמת המשב עכשיו
	static var warn := 0.0            # 0..1 אזהרה לפני משב (העשב נוטה, וווש)
	static var lean := 0.4            # כמה הצמחייה נוטה (חלק)
	static var drift := 0.0           # מרחק מצטבר (פיקסלים) - נעים "עם הרוח"
	static var spin := 0.0            # זווית מצטברת לרוטורים / גלגלי משאבות
	static var t := 0.0

	static func dir() -> float:
		return -1.0 if wind < 0.0 else 1.0

	static func h(i: int, s: int) -> float:
		return fposmod(sin(float(i) * 12.9898 + float(s) * 78.233) * 43758.5453, 1.0)

	static func flush(ci: CanvasItem, pts: PackedVector2Array, cols: PackedColorArray) -> void:
		if not pts.is_empty():
			RenderingServer.canvas_item_add_triangle_array(ci.get_canvas_item(), PackedInt32Array(), pts, cols)

	static func quad(pts: PackedVector2Array, cols: PackedColorArray, a: Vector2, b: Vector2, c: Vector2, d: Vector2, ca: Color, cb: Color, cc: Color, cd: Color) -> void:
		pts.append_array([a, b, c, a, c, d])
		cols.append_array([ca, cb, cc, ca, cc, cd])

	static func tri(pts: PackedVector2Array, cols: PackedColorArray, a: Vector2, b: Vector2, c: Vector2, ca: Color, cc: Color) -> void:
		pts.append_array([a, b, c])
		cols.append_array([ca, ca, cc])

	static func seg(pts: PackedVector2Array, cols: PackedColorArray, a: Vector2, b: Vector2, w: float, c: Color) -> void:
		var n := (b - a).orthogonal().normalized() * w * 0.5
		pts.append_array([a - n, a + n, b + n, a - n, b + n, b - n])
		cols.append_array([c, c, c, c, c, c])

	static func dia(pts: PackedVector2Array, cols: PackedColorArray, c: Vector2, r: float, col: Color) -> void:
		pts.append_array([c + Vector2(-r, 0), c + Vector2(0, -r), c + Vector2(r, 0), c + Vector2(-r, 0), c + Vector2(r, 0), c + Vector2(0, r)])
		for q in 6:
			cols.append(col)

	static func oval(pts: PackedVector2Array, cols: PackedColorArray, c: Vector2, rx: float, ry: float, col: Color, n := 8) -> void:
		for q in n:
			var a0 := float(q) / float(n) * TAU
			var a1 := float(q + 1) / float(n) * TAU
			pts.append_array([c, c + Vector2(cos(a0) * rx, sin(a0) * ry), c + Vector2(cos(a1) * rx, sin(a1) * ry)])
			cols.append_array([col, col, col])

	# ציצת עשב (5 להבים) שנוטה ברוח. k = גודל
	static func tuft(pts: PackedVector2Array, cols: PackedColorArray, base: Vector2, k: float, seed_i: int, c0: Color, c1: Color) -> void:
		var bend := W.lean * W.dir() * 10.0 * k
		for b in 5:
			var hh := (10.0 + h(seed_i, b) * 9.0) * k
			var sp := (float(b) - 2.0) * 2.2 * k
			var fl := sin(W.t * (7.0 + h(seed_i, b + 9) * 5.0) + float(seed_i + b)) * (1.0 + 2.2 * W.gust) * k
			var tip := base + Vector2(sp + bend * (0.7 + 0.3 * h(seed_i, b + 3)) + fl, -hh + absf(bend) * 0.25)
			pts.append_array([base + Vector2(sp * 0.3 - 1.4 * k, 0), base + Vector2(sp * 0.3 + 1.4 * k, 0), tip])
			cols.append_array([c0, c0, c1])

	# משאבת רוח אוסטרלית + מיכל (רקע + עולם)
	static func pump(ci: CanvasItem, base: Vector2, h: float, k: int) -> void:
		var c := Color("5a5e62")
		ci.draw_line(base + Vector2(-16, 0), base + Vector2(-3, -h), c, 2.5)
		ci.draw_line(base + Vector2(16, 0), base + Vector2(3, -h), c, 2.5)
		for q in 4:
			var yy := -h * (0.2 + 0.2 * float(q))
			var hw := 16.0 - 13.0 * (0.2 + 0.2 * float(q))
			ci.draw_line(base + Vector2(-hw, yy), base + Vector2(hw, yy - h * 0.2), c, 1.0)
		var hub := base + Vector2(0, -h - 4.0)
		var ang := W.spin * 1.6 + float(k)
		for b in 14:
			var dv := Vector2.from_angle(ang + float(b) * TAU / 14.0)
			ci.draw_line(hub + dv * 6.0, hub + dv * 22.0, Color("7a7e82"), 3.0)
		ci.draw_arc(hub, 22.0, 0.0, TAU, 20, Color("4a4e52"), 1.2)
		ci.draw_circle(hub, 3.0, Color("3a3e42"))
		ci.draw_colored_polygon(PackedVector2Array([hub + Vector2(2, -2), hub + Vector2(30, -8), hub + Vector2(32, 6), hub + Vector2(2, 2)]), Color("8a2a20"))   # זנב
		# מיכל אוסטרלי
		ci.draw_rect(Rect2(base.x + 26.0, base.y - 22.0, 70.0, 22.0), Color("6a6e70"))
		ci.draw_rect(Rect2(base.x + 26.0, base.y - 22.0, 70.0, 3.0), Color("9aa0a2"))


static func _h(i: int, s: int) -> float:
	return W.h(i, s)


# ============================================================
#  רקע
# ============================================================
static func sun_pos(v: Vector2) -> Vector2:
	return Vector2(v.x * 0.16, v.y * 0.17)


static func steppe_sky(ci: CanvasItem, v: Vector2, t: float) -> void:
	Kit.gradient_sky(ci, v, [Color("10346e"), Color("1f55a0"), Color("3f7cc0"), Color("7eb0d8"), Color("c4d8dc"), Color("ecdcb6")], 0.92)
	var sp := sun_pos(v)
	Kit.soft_glow(ci, sp, 420.0, Color(1.0, 0.92, 0.7, 0.22))
	Kit.soft_glow(ci, sp, 150.0, Color(1.0, 0.97, 0.85, 0.5))
	ci.draw_circle(sp, 34.0, Color(1.0, 0.98, 0.9))
	# עננים עדשתיים - עומדים במקום מעל האנדים (רק "נושמים")
	for i in 3:
		var c := Vector2(v.x * (0.38 + 0.26 * float(i)) + sin(t * 0.05 + float(i)) * 12.0, v.y * (0.27 + 0.07 * float(i % 2)))
		var rx := 190.0 + 60.0 * _h(i, 2)
		for k in 4:
			var kk := float(k)
			var br := 0.6 + 0.4 * sin(t * 0.3 + kk + float(i))
			Kit.soft_ellipse(ci, c + Vector2(kk * 6.0, -kk * 9.0), rx * (1.0 - 0.17 * kk), 13.0 + br * 2.0, 0.0, Color(1.0, 0.97, 0.94, 0.55 - 0.08 * kk))
		Kit.soft_ellipse(ci, c + Vector2(0, 8.0), rx * 0.9, 7.0, 0.0, Color(0.95, 0.72, 0.62, 0.32))   # תחתית ורודה
	# קרעי עננים שדוהרים ברוח
	for i in 9:
		var spd := 0.35 + _h(i, 3) * 0.4
		var x := fposmod(_h(i, 4) * 2600.0 + W.drift * spd, v.x + 700.0) - 350.0
		var y := v.y * (0.06 + _h(i, 5) * 0.38)
		var rx := 90.0 + _h(i, 6) * 110.0
		var ry := 10.0 + _h(i, 7) * 12.0
		Kit.soft_ellipse(ci, Vector2(x, y), rx, ry, -0.04, Color(1.0, 1.0, 1.0, 0.5))
		Kit.soft_ellipse(ci, Vector2(x + rx * 0.4, y - ry * 0.5), rx * 0.55, ry * 0.8, -0.04, Color(1.0, 1.0, 1.0, 0.45))
		Kit.soft_ellipse(ci, Vector2(x - rx * 0.1, y + ry * 0.4), rx * 0.8, ry * 0.45, -0.02, Color(0.62, 0.68, 0.8, 0.28))
		for w in 3:   # שוליים קרועים במורד הרוח
			Kit.soft_ellipse(ci, Vector2(x + W.dir() * rx * (0.9 + 0.35 * float(w)), y + float(w - 1) * 5.0), rx * 0.25, ry * 0.3, 0.0, Color(1, 1, 1, 0.22))
	# קונדורים חגים
	for i in 2:
		var cc := Vector2(v.x * (0.62 + 0.18 * float(i)), v.y * (0.16 + 0.05 * float(i)))
		var a := t * (0.22 + 0.06 * float(i)) + float(i) * 2.0
		var p := cc + Vector2(cos(a) * 90.0, sin(a) * 26.0)
		var fl := sin(t * 1.3 + float(i)) * 1.5
		var s := 1.0 - 0.25 * float(i)
		var dk := Color(0.08, 0.08, 0.1, 0.85)
		ci.draw_polyline(PackedVector2Array([p + Vector2(-24, -3 + fl) * s, p + Vector2(-10, -1) * s, p, p + Vector2(10, -1) * s, p + Vector2(24, -3 + fl) * s]), dk, 2.6 * s)
		for q in 3:   # "אצבעות" בקצות הכנפיים
			ci.draw_line(p + Vector2(-24, -3 + fl) * s, p + Vector2(-29, -5 + fl + float(q) * 2.0) * s, dk, 1.0)
			ci.draw_line(p + Vector2(24, -3 + fl) * s, p + Vector2(29, -5 + fl + float(q) * 2.0) * s, dk, 1.0)
		ci.draw_line(p + Vector2(-5, 0.5) * s, p + Vector2(5, 0.5) * s, Color(0.95, 0.95, 0.9, 0.8), 1.2)   # צווארון לבן


# ---- האנדים: מחטי גרניט, שלג, נוצות שלג ברוח, קרחונים, אגם טורקיז, צללי עננים ----
static func far_andes(ci: CanvasItem, sc: float, v: Vector2, y: float, t: float) -> void:
	var period := 2200.0
	var start := int(floor(sc / period)) - 1
	for k in range(start, start + int(ceil(v.x / period)) + 2):
		var bx := float(k) * period - sc
		# רכס רחוק (כחלחל)
		var ridge := PackedVector2Array([Vector2(bx, y)])
		for q in 23:
			var hh := 70.0 + _h(k * 40 + q, 1) * 70.0 + (40.0 if q % 3 == 0 else 0.0)
			ridge.append(Vector2(bx + float(q) * 100.0, y - hh))
		ridge.append(Vector2(bx + period, y))
		ci.draw_colored_polygon(ridge, Color("8a9cbc"))
		for q in range(1, 22):
			var pk: Vector2 = ridge[q + 1]
			ci.draw_colored_polygon(PackedVector2Array([pk, pk + Vector2(30, 26), pk + Vector2(8, 20), pk + Vector2(-6, 30), pk + Vector2(-28, 24)]), Color("e4ecf6"))
		# הגוש של המחטים (פיץ רוי): כמה מחטים תלולות
		var mx := bx + 700.0 + _h(k, 3) * 400.0
		var mass := PackedVector2Array([Vector2(mx - 330, y), Vector2(mx - 200, y - 120), Vector2(mx - 120, y - 150)])
		var spires := [[-90.0, 205.0], [-48.0, 250.0], [0.0, 300.0], [44.0, 262.0], [86.0, 220.0], [130.0, 175.0]]
		for s in spires:
			var sx: float = mx + float(s[0])
			var sh: float = float(s[1]) * (0.9 + 0.2 * _h(k * 7 + int(s[0]), 4))
			mass.append(Vector2(sx - 14.0, y - sh * 0.72))
			mass.append(Vector2(sx - 3.0, y - sh))
			mass.append(Vector2(sx + 6.0, y - sh * 0.96))
			mass.append(Vector2(sx + 16.0, y - sh * 0.7))
		mass.append_array([Vector2(mx + 190, y - 130), Vector2(mx + 300, y - 90), Vector2(mx + 420, y)])
		ci.draw_colored_polygon(mass, Color("6a7898"))
		for s in spires:   # צד מואר מהשמש (מערב = שמאל), שלג בסדקים
			var sx2: float = mx + float(s[0])
			var sh2: float = float(s[1]) * (0.9 + 0.2 * _h(k * 7 + int(s[0]), 4))
			ci.draw_colored_polygon(PackedVector2Array([Vector2(sx2 - 3.0, y - sh2), Vector2(sx2 - 14.0, y - sh2 * 0.72), Vector2(sx2 - 9.0, y - sh2 * 0.55), Vector2(sx2 - 2.0, y - sh2 * 0.8)]), Color("b6a9a4"))
			ci.draw_colored_polygon(PackedVector2Array([Vector2(sx2 - 5.0, y - sh2 * 0.62), Vector2(sx2 + 2.0, y - sh2 * 0.66), Vector2(sx2, y - sh2 * 0.5)]), Color("eef2f8"))
			# נוצת שלג שהרוח תולשת מהפסגה
			for q in 4:
				var ph := fposmod(t * 0.35 + float(q) * 0.25 + _h(int(s[0]) + k, 5), 1.0)
				var pp := Vector2(sx2 - 3.0, y - sh2) + Vector2(W.dir() * ph * (70.0 + 50.0 * W.mag), -6.0 + ph * 10.0)
				Kit.soft_ellipse(ci, pp, 10.0 + ph * 30.0, 4.0 + ph * 5.0, 0.0, Color(1.0, 1.0, 1.0, 0.4 * (1.0 - ph) * (0.5 + W.mag)))
		# קרחון שזורם למטה
		ci.draw_colored_polygon(PackedVector2Array([Vector2(mx - 120, y - 100), Vector2(mx + 60, y - 110), Vector2(mx + 110, y - 30), Vector2(mx + 40, y - 6), Vector2(mx - 40, y - 8), Vector2(mx - 90, y - 50)]), Color("d8eaf2"))
		for q in 5:
			ci.draw_line(Vector2(mx - 70 + float(q) * 30, y - 90), Vector2(mx - 40 + float(q) * 28, y - 14), Color(0.6, 0.78, 0.88, 0.6), 1.2)
		# גבעות קדמיות של הרכס (מורנות)
		ci.draw_colored_polygon(PackedVector2Array([Vector2(bx, y + 2), Vector2(bx + 300, y - 26), Vector2(bx + 800, y - 14), Vector2(bx + 1300, y - 30), Vector2(bx + 1800, y - 12), Vector2(bx + period, y - 22), Vector2(bx + period, y + 2)]), Color("7a7c84"))
	# האגם (טורקיז חלבי) עם נצנוצים
	ci.draw_rect(Rect2(0, y - 4.0, v.x, 12.0), Color("5ab4c4"))
	ci.draw_rect(Rect2(0, y - 4.0, v.x, 2.0), Color("a6e0e6"))
	var pts := PackedVector2Array()
	var cols := PackedColorArray()
	for i in 40:
		var gx := fposmod(_h(i, 8) * 3000.0 - sc - t * 6.0, v.x)
		var a := 0.3 + 0.5 * absf(sin(t * 3.0 + float(i)))
		W.quad(pts, cols, Vector2(gx, y + 1.0 + float(i % 3) * 2.0), Vector2(gx + 8.0, y + 1.0 + float(i % 3) * 2.0), Vector2(gx + 8.0, y + 2.0 + float(i % 3) * 2.0), Vector2(gx, y + 2.0 + float(i % 3) * 2.0), Color(1, 1, 1, a), Color(1, 1, 1, 0), Color(1, 1, 1, 0), Color(1, 1, 1, a))
	W.flush(ci, pts, cols)
	# הערבה עד הקרקע + צללי עננים שרצים
	ci.draw_rect(Rect2(0, y + 8.0, v.x, v.y - y), Color("b49a68"))
	ci.draw_rect(Rect2(0, y + 8.0, v.x, 3.0), Color("c8b07a"))
	for i in 5:
		var cx := fposmod(_h(i, 9) * 2000.0 + W.drift * 0.5, v.x + 800.0) - 400.0
		Kit.soft_ellipse(ci, Vector2(cx, y + 24.0 + float(i % 2) * 14.0), 200.0 + 80.0 * _h(i, 10), 12.0, 0.0, Color(0.25, 0.22, 0.3, 0.2))


# ---- גבעות, צפצפות, אסטנסיה, טורבינות, גואנקו ----
static func mid_estancia(ci: CanvasItem, sc: float, v: Vector2, y: float, t: float) -> void:
	var lean := W.lean * W.dir()
	# גבעות מתגלגלות
	var period := 1600.0
	var start := int(floor(sc / period)) - 1
	var hill := PackedVector2Array()
	var px0 := float(start) * period - sc
	var steps := int((v.x - px0) / 40.0) + 3
	for q in steps:
		var x := px0 + float(q) * 40.0
		var wx := x + sc
		hill.append(Vector2(x, y - 70.0 - sin(wx * 0.0021) * 26.0 - sin(wx * 0.0057 + 1.0) * 12.0))
	var poly := PackedVector2Array(hill)
	poly.append(Vector2(hill[hill.size() - 1].x, v.y))
	poly.append(Vector2(px0, v.y))
	ci.draw_colored_polygon(poly, Color("a88a58"))
	ci.draw_polyline(hill, Color("c9ae76"), 2.0)
	for k in range(start, start + int(ceil(v.x / period)) + 2):
		var bx := float(k) * period - sc
		var hy := func(x: float) -> float:
			var wx2 := x + sc
			return y - 70.0 - sin(wx2 * 0.0021) * 26.0 - sin(wx2 * 0.0057 + 1.0) * 12.0
		# טורבינות על הרכס
		for q in 3:
			var tx := bx + 180.0 + float(q) * 210.0 + _h(k * 3 + q, 1) * 40.0
			var ty: float = hy.call(tx) + 4.0
			var th := 120.0 + 20.0 * _h(k * 3 + q, 2)
			var top := Vector2(tx, ty - th)
			ci.draw_line(Vector2(tx - 2.0, ty), top + Vector2(-1.0, 0), Color("dfe4e8"), 4.0)
			ci.draw_line(Vector2(tx + 1.0, ty), top + Vector2(1.0, 0), Color("b8bec4"), 1.5)
			ci.draw_rect(Rect2(top.x - 7.0, top.y - 4.0, 14.0, 7.0), Color("e8ecef"))
			var ang := W.spin * (0.9 + 0.2 * _h(k * 3 + q, 3)) + float(q) * 1.7
			for b in 3:
				var dv := Vector2.from_angle(ang + float(b) * TAU / 3.0)
				ci.draw_colored_polygon(PackedVector2Array([top + dv.orthogonal() * 2.5, top + dv * 46.0, top - dv.orthogonal() * 2.0]), Color("eef2f4"))
			ci.draw_circle(top, 3.0, Color("c8ced2"))
			if fmod(t + float(q), 2.0) < 0.2:   # נורית אדומה
				Art.glow(ci, top + Vector2(0, -5), 6.0, Color(1.0, 0.2, 0.15, 0.8))
		# שורת צפצפות (שובר רוח) + הקאסקו
		if posmod(k, 2) == 0:
			var cx := bx + 960.0
			var cy: float = hy.call(cx) + 6.0
			for q in 9:
				var px := cx - 150.0 + float(q) * 24.0
				var ph := 54.0 + 14.0 * _h(k * 9 + q, 4)
				var sw := lean * 9.0 + sin(t * 2.4 + float(q) * 0.7) * (1.5 + 4.0 * W.gust)
				ci.draw_colored_polygon(PackedVector2Array([Vector2(px - 6, cy - 8), Vector2(px - 7 + sw * 0.5, cy - ph * 0.55), Vector2(px + sw, cy - ph), Vector2(px + 6 + sw * 0.6, cy - ph * 0.5), Vector2(px + 6, cy - 8)]), Color("4e6a32").darkened(0.15 * float(q % 2)))
				ci.draw_line(Vector2(px, cy), Vector2(px, cy - 10.0), Color("3a2a1a"), 2.0)
			# הקאסקו: קירות לבנים, גג אדום
			var hx := cx + 30.0
			ci.draw_rect(Rect2(hx, cy - 30.0, 90.0, 30.0), Color("e6e0d2"))
			ci.draw_colored_polygon(PackedVector2Array([Vector2(hx - 6, cy - 30), Vector2(hx + 45, cy - 48), Vector2(hx + 96, cy - 30)]), ROOF_RED)
			for q in 4:
				ci.draw_rect(Rect2(hx + 8.0 + float(q) * 20.0, cy - 22.0, 7.0, 10.0), Color("3a4a5a"))
			ci.draw_rect(Rect2(hx + 70.0, cy - 58.0, 5.0, 14.0), Color("8a8078"))   # ארובה
			Kit.soft_smoke(ci, Vector2(hx + 72.0, cy - 60.0), t, 60.0, Color(0.85, 0.85, 0.85, 0.25), 70.0 * W.dir(), 4)
			# מחסן עם גג פח
			ci.draw_rect(Rect2(hx + 110.0, cy - 24.0, 60.0, 24.0), Color("9aa0a0"))
			ci.draw_colored_polygon(PackedVector2Array([Vector2(hx + 106, cy - 24), Vector2(hx + 140, cy - 36), Vector2(hx + 174, cy - 24)]), Color("b8bcbc"))
		# עדר גואנקו
		var gx := bx + 400.0 + _h(k, 6) * 500.0
		for q in 6:
			var gpx := gx + float(q) * 16.0 + sin(t * 0.3 + float(q)) * 6.0
			var gy: float = hy.call(gpx) + 10.0 + float(q % 2) * 3.0
			var c := Color("8a5a30")
			ci.draw_line(Vector2(gpx - 4, gy), Vector2(gpx - 4, gy - 6), c, 1.2)
			ci.draw_line(Vector2(gpx + 3, gy), Vector2(gpx + 3, gy - 6), c, 1.2)
			ci.draw_colored_polygon(Art.ellipse(Vector2(gpx, gy - 8), 6.0, 3.0, 0.0, 10), c)
			var head_up := sin(t * 0.7 + float(q) * 2.0) > -0.3
			var nk := Vector2(gpx + 5, gy - 9)
			var hd := nk + (Vector2(2, -9) if head_up else Vector2(4, 4))
			ci.draw_line(nk, hd, c, 1.6)
			ci.draw_circle(hd, 1.5, c)
			ci.draw_line(Vector2(gpx - 4, gy - 10), Vector2(gpx + 3, gy - 10), Color(0.95, 0.9, 0.8, 0.6), 1.0)   # בטן לבנה
		# כבשים רחוקות (נקודות לבנות)
		for q in 12:
			var spx := bx + 1200.0 + float(q) * 9.0 + _h(k * 12 + q, 7) * 60.0
			var spy: float = hy.call(spx) + 14.0 + _h(k * 12 + q, 8) * 8.0
			ci.draw_rect(Rect2(spx, spy - 3.0, 5.0, 3.0), Color("ece6d6"))
	# כביש 40 (חצץ) עם ענן אבק של משהו שנוסע (אף אחד לא נוסע...)
	ci.draw_rect(Rect2(0, y - 22.0, v.x, 4.0), Color("c8b48a"))
	var dx := fposmod(-t * 40.0 + 300.0, v.x + 600.0) - 300.0
	Kit.soft_smoke(ci, Vector2(dx, y - 22.0), t, 40.0, Color(0.85, 0.75, 0.55, 0.3), 90.0 * W.dir(), 5)
	ci.draw_rect(Rect2(dx - 6.0, y - 27.0, 12.0, 5.0), Color("3a3430"))
	ci.draw_rect(Rect2(0, y - 18.0, v.x, v.y - y + 18.0), Color("a08452"))


# ---- גדר, קוירון, גולגולות, עצים כפופים, משאבות רוח, כדורי קוצים ----
static func near_steppe(ci: CanvasItem, sc: float, v: Vector2, y: float, t: float) -> void:
	var top := y - 20.0
	ci.draw_rect(Rect2(0, top, v.x, v.y - top), Color("8e7448"))
	ci.draw_rect(Rect2(0, top, v.x, 3.0), Color("b89a62"))
	var lean := W.lean * W.dir()
	# עצי ניירה כפופים (כולם נוטים במורד הרוח, מעוצבים ע"י שנים של רוח)
	var tp := 900.0
	var ts := int(floor(sc / tp)) - 1
	for k in range(ts, ts + int(ceil(v.x / tp)) + 2):
		var tx := float(k) * tp - sc + 200.0 + _h(k, 1) * 300.0
		var bend := -1.0   # הרוח השולטת שמאלה: הגזע נוטה שמאלה
		var trunk := PackedVector2Array([Vector2(tx, top), Vector2(tx + bend * 14.0, top - 40.0), Vector2(tx + bend * 46.0, top - 72.0), Vector2(tx + bend * 92.0, top - 86.0)])
		ci.draw_polyline(trunk, Color("3a2a20"), 9.0)
		ci.draw_polyline(trunk, Color("5a4434"), 3.0)
		for q in 7:   # עלווה דחוסה, מתנופפת
			var c: Vector2 = Vector2(tx + bend * (30.0 + float(q) * 12.0), top - 70.0 - float(q % 3) * 12.0) + Vector2(lean * 4.0 + sin(t * 3.0 + float(q)) * (1.0 + 3.0 * W.gust), 0)
			Kit.soft_ellipse(ci, c, 26.0, 14.0, -0.2, Color("3e5a2a").darkened(0.1 * float(q % 3)))
		# משאבת רוח (פעם בשתיים)
		if posmod(k, 2) == 1:
			_windpump(ci, Vector2(tx + 380.0, top + 4.0), 150.0, k)
	# גדר: עמודים כל 64, 4 חוטים
	var fp := 64.0
	var fs := int(floor(sc / fp)) - 1
	var pts := PackedVector2Array()
	var cols := PackedColorArray()
	for i in 4:
		var wy := top - 14.0 - float(i) * 13.0
		W.quad(pts, cols, Vector2(0, wy), Vector2(v.x, wy), Vector2(v.x, wy + 1.2), Vector2(0, wy + 1.2), Color("3a3634"), Color("3a3634"), Color("3a3634"), Color("3a3634"))
	for k in range(fs, fs + int(v.x / fp) + 3):
		var fx := float(k) * fp - sc
		var pc := Color("4a3a2a").darkened(0.15 * _h(k, 2))
		W.quad(pts, cols, Vector2(fx - 3, top + 2), Vector2(fx + 3, top + 2), Vector2(fx + 2.5, top - 58), Vector2(fx - 2.5, top - 60), pc, pc, pc.lightened(0.15), pc.lightened(0.15))
		if _h(k, 3) < 0.12:   # גולגולת גואנקו על העמוד
			var sp := Vector2(fx, top - 62.0)
			W.oval(pts, cols, sp, 7.0, 4.5, Color("e8e2d0"), 8)
			W.quad(pts, cols, sp + Vector2(2, -3), sp + Vector2(14, -1), sp + Vector2(13, 3), sp + Vector2(2, 3), Color("e0d8c4"), Color("d0c6b0"), Color("d0c6b0"), Color("e0d8c4"))
			W.dia(pts, cols, sp + Vector2(-1, -1), 1.8, Color("2a2420"))
		elif _h(k, 4) < 0.1:   # צמר שנתפס בתיל ומתנופף
			var wp := Vector2(fx + 20.0, top - 27.0)
			W.oval(pts, cols, wp + Vector2(lean * 3.0 + sin(t * 9.0 + float(k)) * 2.0, 0), 5.0, 3.0, Color("f0ebe0"), 6)
	# ציצי קוירון לפני הגדר
	var gp := 26.0
	var gs := int(floor(sc / gp)) - 1
	for k in range(gs, gs + int(v.x / gp) + 3):
		var gx := float(k) * gp - sc + _h(k, 5) * 16.0
		W.tuft(pts, cols, Vector2(gx, top + 4.0 + _h(k, 6) * 6.0), 1.2 + _h(k, 7) * 0.8, k, Color("7a6432"), Color("e2cc8a"))
		if _h(k, 8) < 0.06:   # שיח קלפטה עם פירות סגולים
			var bp := Vector2(gx + 6.0, top + 4.0)
			W.oval(pts, cols, bp + Vector2(0, -9), 16.0, 10.0, Color("4a5a2e"), 10)
			for q in 4:
				W.dia(pts, cols, bp + Vector2(-8.0 + float(q) * 5.0, -10.0 + float(q % 2) * 4.0), 1.6, Color("5a2a6a"))
	W.flush(ci, pts, cols)
	# כדורי קוצים מתגלגלים ברקע (במורד הרוח, קופצים)
	for i in 3:
		var spd := 0.9 + 0.3 * _h(i, 9)
		var bx := fposmod(_h(i, 10) * 3000.0 + W.drift * spd * 1.6 - sc * 0.2, v.x + 400.0) - 200.0
		var by := top - 12.0 - absf(sin(W.drift * 0.012 * spd + float(i))) * (14.0 + 20.0 * W.gust)
		var rot := W.drift * 0.03 * spd
		ci.draw_arc(Vector2(bx, by), 12.0, rot, rot + TAU * 0.8, 10, Color("b49a62"), 2.0)
		ci.draw_arc(Vector2(bx, by), 8.0, -rot, -rot + TAU * 0.7, 8, Color("8a7444"), 1.5)
		ci.draw_line(Vector2(bx, by) + Vector2.from_angle(rot) * 12.0, Vector2(bx, by) - Vector2.from_angle(rot) * 12.0, Color("9a8250"), 1.2)


static func _windpump(ci: CanvasItem, base: Vector2, h: float, k: int) -> void:
	W.pump(ci, base, h, k)


static func steppe_overlay(ci: CanvasItem, v: Vector2, t: float) -> void:
	Kit.haze_band(ci, v, 420.0, 612.0, Color(0.92, 0.84, 0.66, 0.24))
	for i in 6:   # זרמי אבק נמוכים
		var x := fposmod(_h(i, 11) * 2400.0 + W.drift * (1.4 + 0.4 * _h(i, 12)), v.x + 900.0) - 450.0
		var yy := 560.0 + _h(i, 13) * 50.0 + sin(t + float(i)) * 6.0
		Kit.soft_ellipse(ci, Vector2(x, yy), 220.0 + 80.0 * W.gust, 10.0, 0.0, Color(0.85, 0.74, 0.52, 0.08 + 0.12 * W.mag))


# ============================================================
#  עולם
# ============================================================
class SteppeGround extends Node2D:
	var w := 1024.0
	var depth := 90.0
	var seed_v := 0
	var _stones := PackedVector2Array()
	var _tufts := PackedVector2Array()

	func _ready() -> void:
		z_index = 1
		var r := RandomNumberGenerator.new()
		r.seed = seed_v
		for i in int(w / 34.0):
			_tufts.append(Vector2(r.randf_range(0.0, w), r.randf_range(0.6, 1.1)))

	func _process(_delta: float) -> void:
		if Engine.get_process_frames() % 3 == seed_v % 3 and Art.on_screen(self, global_position + Vector2(w * 0.5, 0), w * 0.5 + 40.0):
			queue_redraw()

	func _draw() -> void:
		draw_rect(Rect2(0, 0, w, depth), Color("5a4630"))
		draw_rect(Rect2(0, 0, w, 12.0), Color("a48658"))
		draw_rect(Rect2(0, 12.0, w, 5.0), Color("7a603c"))
		draw_rect(Rect2(0, 0, w, 1.6), Color(1.0, 0.92, 0.72, 0.6))
		var r := RandomNumberGenerator.new()
		r.seed = seed_v
		var pts := PackedVector2Array()
		var cols := PackedColorArray()
		for i in int(w / 5.0):   # חצץ
			W.dia(pts, cols, Vector2(r.randf_range(0.0, w), r.randf_range(2.0, 11.0)), r.randf_range(0.8, 1.9), Color("c4a878").darkened(r.randf() * 0.35))
		for i in int(w / 22.0):   # אבנים גדולות באדמה
			W.oval(pts, cols, Vector2(r.randf_range(0.0, w), r.randf_range(22.0, depth - 8.0)), r.randf_range(3.0, 7.0), r.randf_range(2.0, 4.0), Color("6e5a42").darkened(r.randf() * 0.3), 6)
		for i in int(w / 160.0):   # תלמי צמיגים ישנים
			var tx := r.randf_range(0.0, w - 80.0)
			W.quad(pts, cols, Vector2(tx, 5.0), Vector2(tx + 80.0, 5.5), Vector2(tx + 80.0, 6.5), Vector2(tx, 6.0), Color(0.3, 0.22, 0.12, 0.0), Color(0.3, 0.22, 0.12, 0.0), Color(0.3, 0.22, 0.12, 0.35), Color(0.3, 0.22, 0.12, 0.35))
		for i in _tufts.size():   # ציצי עשב בקצה - נוטים ברוח
			var tf: Vector2 = _tufts[i]
			W.tuft(pts, cols, Vector2(tf.x, 1.0), tf.y, seed_v % 997 + i, Color("6a5a2a"), Color("d8c27e"))
		W.flush(self, pts, cols)


# ---- מחסן הגז"ז: פח גלי, גמלון, דלת הזזה, עליית גג ----
class WoolShed extends Node2D:
	var w := 560.0
	var tier := 150.0
	var h := 250.0
	var seed_v := 0

	func _ready() -> void:
		z_index = -2

	func _process(_delta: float) -> void:
		if Engine.get_process_frames() % 4 == 0 and Art.on_screen(self, global_position + Vector2(w * 0.5, -h * 0.5), w * 0.5 + 60.0):
			queue_redraw()

	func _draw() -> void:
		var pts := PackedVector2Array()
		var cols := PackedColorArray()
		var wall := Color("9aa2a4")
		draw_rect(Rect2(0, -h * 0.72, w, h * 0.72), wall)
		var x := 0.0
		while x < w:   # גלי הפח
			W.quad(pts, cols, Vector2(x, -h * 0.72), Vector2(x + 3.0, -h * 0.72), Vector2(x + 3.0, 0), Vector2(x, 0), Color(1, 1, 1, 0.16), Color(1, 1, 1, 0.16), Color(1, 1, 1, 0.1), Color(1, 1, 1, 0.1))
			W.quad(pts, cols, Vector2(x + 5.0, -h * 0.72), Vector2(x + 8.0, -h * 0.72), Vector2(x + 8.0, 0), Vector2(x + 5.0, 0), Color(0, 0, 0, 0.12), Color(0, 0, 0, 0.12), Color(0, 0, 0, 0.18), Color(0, 0, 0, 0.18))
			x += 10.0
		var r := RandomNumberGenerator.new()
		r.seed = seed_v
		for i in 9:   # חלודה זולגת
			var rx := r.randf_range(10.0, w - 20.0)
			var rl := r.randf_range(30.0, 90.0)
			W.quad(pts, cols, Vector2(rx, -h * 0.72), Vector2(rx + 10.0, -h * 0.72), Vector2(rx + 7.0, -h * 0.72 + rl), Vector2(rx + 3.0, -h * 0.72 + rl), Color(0.55, 0.28, 0.12, 0.5), Color(0.55, 0.28, 0.12, 0.5), Color(0.55, 0.28, 0.12, 0.0), Color(0.55, 0.28, 0.12, 0.0))
		W.flush(self, pts, cols)
		# גג גמלון אדום-חלוד
		var roof := PackedVector2Array([Vector2(-16, -h * 0.72), Vector2(w * 0.5, -h), Vector2(w + 16, -h * 0.72), Vector2(w + 16, -h * 0.68), Vector2(w * 0.5, -h + 6.0), Vector2(-16, -h * 0.68)])
		draw_colored_polygon(roof, Color("8a3a26"))
		draw_line(Vector2(-16, -h * 0.72), Vector2(w * 0.5, -h), Color(1.0, 0.7, 0.55, 0.6), 2.0)
		draw_colored_polygon(PackedVector2Array([Vector2(0, -h * 0.72), Vector2(w * 0.5, -h + 6.0), Vector2(w, -h * 0.72)]), Color("848c8e"))   # גמלון
		# הקומה (עליית הגג): קורה + פתח העמסה
		draw_rect(Rect2(-6, -tier - 2.0, w + 12.0, 10.0), Color("5a4030"))
		draw_rect(Rect2(-6, -tier - 2.0, w + 12.0, 2.0), Color("a07a58"))
		for q in int(w / 46.0) + 1:
			draw_line(Vector2(float(q) * 46.0, -tier + 8.0), Vector2(float(q) * 46.0 + 20.0, -tier + 30.0), Color("4a3428"), 3.0)   # זיזים
		draw_rect(Rect2(w * 0.5 - 40.0, -tier - 70.0, 80.0, 66.0), Color("2a2420"))   # פתח עליית הגג
		for q in 3:   # חבילות צמר בפתח
			draw_rect(Rect2(w * 0.5 - 34.0 + float(q) * 24.0, -tier - 26.0, 22.0, 22.0), Color("d8ceb8").darkened(0.1 * float(q % 2)))
			draw_line(Vector2(w * 0.5 - 34.0 + float(q) * 24.0, -tier - 15.0), Vector2(w * 0.5 - 12.0 + float(q) * 24.0, -tier - 15.0), Color("8a7a5a"), 1.0)
		draw_line(Vector2(w * 0.5, -tier - 70.0), Vector2(w * 0.5, -tier - 100.0), Color("3a3a3a"), 2.0)   # מנוף קטן
		draw_line(Vector2(w * 0.5, -tier - 100.0), Vector2(w * 0.5 + 40.0, -tier - 100.0), Color("3a3a3a"), 2.0)
		var sw := sin(W.t * 2.0) * (2.0 + 6.0 * W.gust)
		draw_line(Vector2(w * 0.5 + 38.0, -tier - 100.0), Vector2(w * 0.5 + 38.0 + sw, -tier - 70.0), Color("2a2a2a"), 1.0)
		draw_circle(Vector2(w * 0.5 + 38.0 + sw, -tier - 70.0), 2.5, Color("4a4a4a"))
		# דלת הזזה גדולה, פתוחה למחצה (חושך בפנים, כבשים מתות על הרצפה)
		draw_rect(Rect2(w * 0.18, -tier + 12.0, w * 0.26, tier - 12.0), Color("1a1614"))
		for q in 3:
			Art.oval(self, Vector2(w * 0.22 + float(q) * 30.0, -6.0), 12.0, 5.0, Color(0.85, 0.82, 0.74, 0.5), 0.0, Art.NONE)
		draw_rect(Rect2(w * 0.4, -tier + 8.0, w * 0.2, tier - 8.0), Color("7a8486"))
		draw_rect(Rect2(w * 0.4, -tier + 8.0, w * 0.2, 4.0), Color("4a5254"))
		draw_line(Vector2(w * 0.4, -tier + 8.0), Vector2(w * 0.6, 0), Color(0.3, 0.3, 0.3, 0.6), 2.0)
		# שלט
		var sy := -tier + 34.0   # מתחת לעליית הגג, שלא יוסתר ע"י פריטים על הרצפה העליונה
		draw_rect(Rect2(w * 0.66, sy, 130.0, 26.0), Color("e8dcc0"))
		draw_rect(Rect2(w * 0.66, sy, 130.0, 26.0), Color("3a2a20"), false, 2.0)
		draw_string(ThemeDB.fallback_font, Vector2(w * 0.66 + 10.0, sy + 19.0), "ESQUILA", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("7a1a14"))
		# כתם דם גדול שנגרר ליד הדלת
		draw_colored_polygon(PackedVector2Array([Vector2(w * 0.3, -2), Vector2(w * 0.38, -6), Vector2(w * 0.5, -3), Vector2(w * 0.46, 0), Vector2(w * 0.3, 0)]), Color(0.45, 0.06, 0.05, 0.7))


# ---- מגדל מים ----
class WaterTower extends Node2D:
	var tier := 190.0
	var w := 150.0

	func _ready() -> void:
		z_index = -2

	func _draw() -> void:
		var legs := [8.0, w * 0.36, w * 0.64, w - 8.0]
		for lx: float in legs:
			draw_line(Vector2(lx, 0), Vector2(lx + (w * 0.5 - lx) * 0.12, -tier), Color("4a3a2a"), 6.0)
		for q in 3:   # חיזוקים
			var y0 := -tier * (0.15 + 0.3 * float(q))
			var y1 := y0 - tier * 0.3
			draw_line(Vector2(8, y0), Vector2(w - 8, y1), Color("5a4a36"), 2.0)
			draw_line(Vector2(w - 8, y0), Vector2(8, y1), Color("5a4a36"), 2.0)
		draw_rect(Rect2(-8, -tier - 4.0, w + 16.0, 8.0), Color("5a4030"))   # הבמה
		draw_rect(Rect2(-8, -tier - 4.0, w + 16.0, 2.0), Color("a8845e"))
		for q in 9:   # מעקה
			draw_line(Vector2(-6.0 + float(q) * (w + 12.0) / 8.0, -tier - 4.0), Vector2(-6.0 + float(q) * (w + 12.0) / 8.0, -tier - 26.0), Color("3a2a20"), 2.0)
		draw_line(Vector2(-6, -tier - 26.0), Vector2(w + 6, -tier - 26.0), Color("3a2a20"), 2.0)
		# המיכל (עץ, חישוקי ברזל) - מאחורי הבמה, גבוה
		var tk := Rect2(16.0, -tier - 120.0, w - 32.0, 86.0)
		draw_rect(tk, Color("7a5a3a"))
		for q in int(tk.size.x / 9.0):
			draw_line(Vector2(tk.position.x + float(q) * 9.0, tk.position.y), Vector2(tk.position.x + float(q) * 9.0, tk.end.y), Color("5a3e26"), 1.0)
		for q in 4:
			draw_line(Vector2(tk.position.x - 2.0, tk.position.y + 10.0 + float(q) * 22.0), Vector2(tk.end.x + 2.0, tk.position.y + 10.0 + float(q) * 22.0), Color("3a3a3c"), 2.4)
		draw_colored_polygon(PackedVector2Array([Vector2(tk.position.x - 6, tk.position.y), Vector2(w * 0.5, tk.position.y - 22.0), Vector2(tk.end.x + 6, tk.position.y)]), Color("6a6e70"))
		draw_line(Vector2(tk.position.x + 12, tk.end.y), Vector2(tk.position.x + 12, -tier - 4.0), Color("3a3a3c"), 3.0)   # צינור
		draw_line(Vector2(tk.end.x - 10, tk.position.y + 40), Vector2(tk.end.x - 10, tk.end.y + 6.0), Color(0.6, 0.75, 0.85, 0.5), 1.0)   # דליפה


# ---- טורבינת רוח עם במת תחזוקה ----
class Turbine extends Node2D:
	var tier := 170.0
	var h := 470.0
	var broken := false
	var blade_gone := false       # BladeDrop: הלהב השבור נפל
	var plat_w := 160.0

	func _ready() -> void:
		z_index = -2

	func _process(_delta: float) -> void:
		if Engine.get_process_frames() % 2 == 0 and Art.on_screen(self, global_position + Vector2(0, -h * 0.6), 300.0):
			queue_redraw()

	func hub() -> Vector2:
		return Vector2(0, -h - 6.0)

	func _draw() -> void:
		# מגדל לבן מתחדד
		draw_colored_polygon(PackedVector2Array([Vector2(-15, 0), Vector2(15, 0), Vector2(7, -h), Vector2(-7, -h)]), Color("e8ecee"))
		draw_colored_polygon(PackedVector2Array([Vector2(4, 0), Vector2(15, 0), Vector2(7, -h), Vector2(2, -h)]), Color("c4cacc"))
		for q in 6:   # תפרי המקטעים
			var yy := -h * (0.16 + 0.15 * float(q))
			var hw := 15.0 - 8.0 * (yy / -h)
			draw_line(Vector2(-hw, yy), Vector2(hw, yy), Color(0.6, 0.64, 0.66, 0.7), 1.0)
		draw_rect(Rect2(-5, -32, 10, 30), Color("7a8288"))   # דלת
		# במת תחזוקה
		draw_rect(Rect2(-plat_w * 0.5, -tier - 3.0, plat_w, 7.0), Color("5a6066"))
		draw_rect(Rect2(-plat_w * 0.5, -tier - 3.0, plat_w, 2.0), Color("c8d0d4"))
		for q in 9:
			var px := -plat_w * 0.5 + float(q) * plat_w / 8.0
			draw_line(Vector2(px, -tier - 3.0), Vector2(px, -tier - 24.0), Color("ffd040"), 1.6)
		draw_line(Vector2(-plat_w * 0.5, -tier - 24.0), Vector2(plat_w * 0.5, -tier - 24.0), Color("ffd040"), 2.0)
		draw_line(Vector2(-plat_w * 0.5, -tier + 4.0), Vector2(-10, -tier + 30.0), Color("5a6066"), 2.5)
		draw_line(Vector2(plat_w * 0.5, -tier + 4.0), Vector2(10, -tier + 30.0), Color("5a6066"), 2.5)
		# נאסל
		var hb := hub()
		draw_colored_polygon(PackedVector2Array([hb + Vector2(-34, -10), hb + Vector2(20, -12), hb + Vector2(26, 0), hb + Vector2(20, 10), hb + Vector2(-34, 9)]), Color("eef0f2"))
		draw_line(hb + Vector2(-34, 9), hb + Vector2(20, 10), Color("aab0b4"), 2.0)
		if fmod(W.t, 1.8) < 0.18:
			Art.glow(self, hb + Vector2(-20, -14), 8.0, Color(1.0, 0.2, 0.15, 0.9))
		# להבים (הטורבינה השבורה: תקועה, להב אחד סדוק ומתנדנד)
		var ang := W.spin * 0.8 if not broken else 0.4 + sin(W.t * 1.3) * 0.03
		var hub_c := hb + Vector2(28, 0)
		for b in 3:
			var a := ang + float(b) * TAU / 3.0
			if broken and b == 0:
				if blade_gone:
					draw_line(hub_c, hub_c + Vector2.from_angle(a) * 22.0, Color("6a6e70"), 6.0)   # גדם
					continue
				a += sin(W.t * 3.0) * (0.04 + 0.1 * W.gust)
			var dv := Vector2.from_angle(a)
			var L := 210.0
			var bl := PackedVector2Array([hub_c + dv.orthogonal() * 8.0, hub_c + dv * L * 0.3 + dv.orthogonal() * 11.0, hub_c + dv * L, hub_c + dv * L * 0.95 - dv.orthogonal() * 3.0, hub_c - dv.orthogonal() * 5.0])
			draw_colored_polygon(bl, Color("f2f4f5"))
			draw_polyline(PackedVector2Array([hub_c - dv.orthogonal() * 5.0, hub_c + dv * L * 0.95 - dv.orthogonal() * 3.0]), Color("b4bcc0"), 1.5)
			if broken and b == 0:   # סדק + חלודה
				var cp := hub_c + dv * 26.0
				draw_polyline(PackedVector2Array([cp + dv.orthogonal() * 9.0, cp + dv * 4.0, cp - dv.orthogonal() * 2.0 + dv * 2.0, cp - dv.orthogonal() * 6.0 + dv * 6.0]), Color("2a2420"), 2.0)
		draw_circle(hub_c, 9.0, Color("dfe3e6"))
		draw_circle(hub_c, 9.0, Color("9aa2a6"), false, 1.5)


# ---- שער הכניסה לאסטנסיה + דגל ----
class EstanciaArch extends Node2D:
	var w := 230.0

	func _ready() -> void:
		z_index = -2

	func _process(_delta: float) -> void:
		if Engine.get_process_frames() % 2 == 0 and Art.on_screen(self, global_position, 400.0):
			queue_redraw()

	func _draw() -> void:
		for px: float in [0.0, w]:
			draw_rect(Rect2(px - 9, -210, 18, 210), Color("5a4232"))
			draw_rect(Rect2(px - 9, -210, 5, 210), Color("7a5a44"))
		draw_rect(Rect2(-24, -232, w + 48, 30), Color("4a3428"))
		draw_rect(Rect2(-24, -232, w + 48, 4), Color("8a6a50"))
		draw_string(ThemeDB.fallback_font, Vector2(-8, -210), "ESTANCIA LA VENTOSA", HORIZONTAL_ALIGNMENT_LEFT, -1, 19, Color("eadcb8"))
		Art.oval(self, Vector2(w * 0.5, -248), 14.0, 9.0, Color("e8e0cc"), 0.0, Art.OUTLINE, 1.0)   # גולגולת פרה על השער
		draw_line(Vector2(w * 0.5 - 12, -252), Vector2(w * 0.5 - 30, -266), Color("e0d8c0"), 3.0)
		draw_line(Vector2(w * 0.5 + 12, -252), Vector2(w * 0.5 + 30, -266), Color("e0d8c0"), 3.0)
		draw_circle(Vector2(w * 0.5 - 5, -248), 2.4, Color("2a2420"))
		draw_circle(Vector2(w * 0.5 + 5, -248), 2.4, Color("2a2420"))
		# שלט שנקרע: "NO HAY PASO" בספריי אדום
		draw_string(ThemeDB.fallback_font, Vector2(20, -150), "NO PASAR", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color(0.75, 0.1, 0.08, 0.85))
		# דגל ארגנטינה על עמוד, מתנופף לפי הרוח
		var pole := Vector2(w + 70.0, 0)
		draw_line(pole, pole + Vector2(0, -300), Color("c8ccd0"), 3.0)
		var fw := 78.0
		var fh := 48.0
		var dir := W.dir()
		var cols := [Color("74acdf"), Color("f4f4f2"), Color("74acdf")]
		var n := 10
		for s in 3:
			var poly := PackedVector2Array()
			for q in n + 1:
				var u := float(q) / float(n)
				poly.append(_flag(pole, u, float(s) / 3.0, fw, fh, dir))
			for q in range(n, -1, -1):
				var u := float(q) / float(n)
				poly.append(_flag(pole, u, float(s + 1) / 3.0, fw, fh, dir))
			draw_colored_polygon(poly, cols[s])
		draw_circle(_flag(pole, 0.45, 0.5, fw, fh, dir), 5.0, Color("f6b40e"))   # שמש מאי

	func _flag(pole: Vector2, u: float, v: float, fw: float, fh: float, dir: float) -> Vector2:
		var stiff := clampf(0.35 + W.mag * 0.7, 0.0, 1.0)
		var wave := sin(u * 7.0 - W.t * (8.0 + 8.0 * W.mag)) * u * (6.0 + 6.0 * W.gust)
		var droop := (1.0 - stiff) * u * fh * 0.9
		return pole + Vector2(dir * u * fw * (0.55 + 0.45 * stiff), -296.0 + v * fh + wave + droop)


# ---- בקתת רועים (puesto) ----
class Puesto extends Node2D:
	var w := 170.0

	func _ready() -> void:
		z_index = -2

	func _process(_delta: float) -> void:
		if Engine.get_process_frames() % 3 == 0 and Art.on_screen(self, global_position, 300.0):
			queue_redraw()

	func _draw() -> void:
		draw_rect(Rect2(0, -96, w, 96), Color("8a7a66"))
		var r := RandomNumberGenerator.new()
		r.seed = 55
		for row in 8:   # אבנים
			var x := -float(row % 2) * 9.0
			while x < w:
				var bw := r.randf_range(14.0, 24.0)
				draw_rect(Rect2(x + 1.0, -96.0 + float(row) * 12.0 + 1.0, minf(bw, w - x) - 2.0, 10.0), Color("9a8a74").darkened(r.randf() * 0.25))
				x += bw
		draw_colored_polygon(PackedVector2Array([Vector2(-14, -96), Vector2(w + 14, -110), Vector2(w + 14, -102), Vector2(-14, -88)]), Color("8e9496"))   # גג פח משופע
		for q in 8:
			draw_line(Vector2(-10.0 + float(q) * 24.0, -95.0 - float(q) * 1.8), Vector2(-10.0 + float(q) * 24.0, -88.0 - float(q) * 1.8), Color("6a7072"), 1.0)
		for q in 3:   # אבנים על הגג (נגד הרוח)
			Art.oval(self, Vector2(20.0 + float(q) * 55.0, -101.0 - float(q) * 4.0), 7.0, 4.0, Color("6a6058"), 0.0, Art.OUTLINE, 1.0)
		draw_rect(Rect2(24, -66, 30, 66), Color("4a3222"))   # דלת
		draw_rect(Rect2(100, -66, 34, 26), Color("2a2a2e"))   # חלון
		draw_line(Vector2(117, -66), Vector2(117, -40), Color("5a4030"), 2.0)
		draw_rect(Rect2(w - 30, -140, 14, 44), Color("6a6058"))   # ארובה
		Kit.soft_smoke(self, Vector2(w - 23, -142), W.t, 90.0, Color(0.7, 0.7, 0.7, 0.3), 110.0 * W.dir() * (0.5 + W.mag), 5)
		Art.oval(self, Vector2(w * 0.5, -120), 10.0, 6.0, Color("e6dec8"), 0.0, Art.OUTLINE, 1.0)   # גולגולת גואנקו מעל הדלת


# ---- משאבת רוח אוסטרלית + מיכל (עולם, מאחור) ----
class WindPump extends Node2D:
	var h := 200.0
	var k := 0
	var sc := 1.3

	func _ready() -> void:
		z_index = -3

	func _process(_delta: float) -> void:
		if Engine.get_process_frames() % 2 == 0 and Art.on_screen(self, global_position + Vector2(0, -h * sc * 0.5), 200.0):
			queue_redraw()

	func _draw() -> void:
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(sc, sc))
		W.pump(self, Vector2.ZERO, h, k)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


# ---- גדר תיל ארוכה (מאחור) ----
class WireFence extends Node2D:
	var w := 600.0
	var seed_v := 0

	func _ready() -> void:
		z_index = -1

	func _process(_delta: float) -> void:
		if Engine.get_process_frames() % 4 == 1 and Art.on_screen(self, global_position + Vector2(w * 0.5, 0), w * 0.5 + 40.0):
			queue_redraw()

	func _draw() -> void:
		var pts := PackedVector2Array()
		var cols := PackedColorArray()
		var r := RandomNumberGenerator.new()
		r.seed = seed_v
		var x := 0.0
		while x <= w:
			var tilt := r.randf_range(-3.0, 3.0)
			W.quad(pts, cols, Vector2(x - 3, 0), Vector2(x + 3, 0), Vector2(x + 2.5 + tilt, -52), Vector2(x - 2.5 + tilt, -54), Color("4a3828"), Color("4a3828"), Color("6a5038"), Color("6a5038"))
			x += 58.0
		for i in 5:
			var wy := -10.0 - float(i) * 10.0
			for q in int(w / 58.0):
				var x0 := float(q) * 58.0
				var sag := 2.0 + sin(W.t * 6.0 + float(q + i)) * W.gust * 1.5
				W.seg(pts, cols, Vector2(x0, wy), Vector2(x0 + 29.0, wy + sag), 1.0, Color("2e2a28"))
				W.seg(pts, cols, Vector2(x0 + 29.0, wy + sag), Vector2(x0 + 58.0, wy), 1.0, Color("2e2a28"))
				if i % 2 == 0:   # דוקרנים
					W.dia(pts, cols, Vector2(x0 + 14.0, wy + sag * 0.5), 1.6, Color("3a3634"))
					W.dia(pts, cols, Vector2(x0 + 44.0, wy + sag * 0.5), 1.6, Color("3a3634"))
		for i in int(w / 140.0):   # צמר תקוע שמתנופף
			var wx := r.randf_range(20.0, w - 20.0)
			var wy2 := -12.0 - float(r.randi() % 4) * 10.0
			W.oval(pts, cols, Vector2(wx + W.dir() * W.lean * 4.0 + sin(W.t * 8.0 + wx) * 1.5, wy2), 6.0, 3.5, Color("f2ede2"), 7)
		W.flush(self, pts, cols)


# ============================================================
#  מלכודות
# ============================================================
# ---- לוח פח רופף על הגג: נתלש במשב ועף במורד הרוח בגובה ראש ----
class SheetTrap extends Node2D:
	const WARN_T := 1.1
	const V := 470.0
	const FLY_T := 2.4
	const DMG := 1
	const DMG_Z := 55
	const SHEETS := 3
	const TRIG_R := 900.0
	const RELOAD := 3.0
	var floor_y := 630.0
	var state := 0                   # 0 = רופף, 1 = רועד, 2 = עף, 3 = נח / טעינה
	var flights := 0                 # לבדיקות
	var hits := 0
	var sliced := 0
	var _left := SHEETS
	var _t := 0.0
	var _tt := 0.0
	var _p := Vector2.ZERO           # (מקומי) מיקום הלוח העף
	var _rot := 0.0
	var _hit := {}
	var _body: StaticBody2D = null

	class Loose extends StaticBody2D:
		var trap = null
		func hit_by_bullet(_p: Vector2, _n: Vector2, _d: Vector2) -> void:
			if trap != null and trap.state <= 1 and trap._left > 0:
				trap._tear(true)

	func _ready() -> void:
		z_index = 4
		add_to_group("hazards")
		_body = Loose.new()
		_body.trap = self
		_body.collision_layer = 4
		_body.collision_mask = 0
		var cs := CollisionShape2D.new()
		var rs := RectangleShape2D.new()
		rs.size = Vector2(54, 16)
		cs.shape = rs
		_body.add_child(cs)
		add_child(_body)
		_body.position = Vector2(0, -6)
		_t = randf_range(0.0, 2.0)

	func world_rect() -> Rect2:
		return Rect2(global_position + _p + Vector2(-40, -20), Vector2(80, 40))

	func danger_at(p: Vector2, margin := 0.0) -> bool:
		return state == 2 and world_rect().grow(margin).has_point(p)

	func _tear(shot: bool) -> void:
		state = 2
		_t = FLY_T
		_left -= 1
		flights += 1
		_p = Vector2.ZERO
		_rot = 0.0
		_hit.clear()
		_body.collision_layer = 0
		Sfx.play("w55_sheet", global_position, 3.0, 0.1, 2)
		if shot:
			Particles.burst(get_parent(), global_position, "spark", Vector2.UP, 6)

	func _physics_process(delta: float) -> void:
		_tt += delta
		_t -= delta
		var pl := get_tree().get_first_node_in_group("player") as Node2D
		var near: bool = pl != null and absf(pl.global_position.x - global_position.x) < TRIG_R
		match state:
			0:
				if _left > 0 and near and (W.warn > 0.2 or W.gust > 0.2):
					state = 1
					_t = WARN_T
					Sfx.play("w55_rattle", global_position, 2.0, 0.1, 2)
			1:
				if Engine.get_physics_frames() % 10 == 0 and Art.on_screen(self, global_position):
					Sfx.play("w55_rattle", global_position, -4.0, 0.2, 2)
				if _t <= 0.0:
					_tear(false)
			2:
				var k := 1.0 - _t / FLY_T
				var dir := W.dir()
				var target_y := floor_y - global_position.y - 52.0   # גובה ראש
				_p.x += dir * V * (0.6 + 0.6 * W.mag) * delta
				_p.y = lerpf(_p.y, target_y + sin(_tt * 5.0) * 10.0, clampf(delta * 3.5, 0.0, 1.0))
				_rot += delta * 14.0
				var wp := global_position + _p
				if pl != null and not pl.dead and not _hit.has(pl) and pl.body_rect().grow(6.0).has_point(wp):
					_hit[pl] = true
					hits += 1
					pl.hurt(DMG, Vector2(dir, -0.4))
				for z in get_tree().get_nodes_in_group("zombies"):
					if z.dead or _hit.has(z) or z.is_boss():
						continue
					if absf(z.global_position.x - wp.x) < 26.0 and wp.y > z.global_position.y - 70.0 and wp.y < z.global_position.y + 4.0:
						_hit[z] = true
						sliced += 1
						z.take_damage(DMG_Z, wp, Vector2(dir, -0.2), false, {"source": "hazard", "fixed": DMG_Z, "knockback": 160.0})
						Sfx.play("metal_ping", wp, 0.0, 0.2, 3)
						if sliced == 1:
							z._popup("SLICED", Color("d8e0e8"), 15, -90.0)
				if _t <= 0.0 or (k > 0.2 and wp.y > floor_y - 20.0):
					state = 3
					_t = RELOAD
					Sfx.play("metal_ping", wp, 2.0, 0.1, 2)
			3:
				if _t <= 0.0:
					state = 0
					_p = Vector2.ZERO
					if _left > 0:
						_body.collision_layer = 4
		if Art.on_screen(self, global_position + _p, 200.0):
			queue_redraw()

	func _draw() -> void:
		var shake := 0.0
		if state == 1:
			shake = sin(_tt * 50.0) * 0.25
		elif state == 0:
			shake = sin(_tt * 8.0) * 0.04 * (1.0 + 2.0 * W.mag)
		for q in _left - (1 if state == 2 else 0):   # הלוחות שעוד על הגג
			var o := Vector2(-float(q) * 10.0, -float(q) * 2.0)
			draw_set_transform(o, shake * (1.0 if q == 0 else 0.3), Vector2.ONE)
			_sheet()
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		if state == 1:
			draw_string(ThemeDB.fallback_font, Vector2(-6, -30), "!", HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color(1.0, 0.6, 0.2, 0.6 + 0.4 * sin(_tt * 30.0)))
		if state == 2:
			draw_set_transform(_p, _rot, Vector2(1.0, 0.35 + 0.65 * absf(cos(_rot * 0.5))))
			_sheet()
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
			for q in 3:   # פסי תנועה
				draw_line(_p + Vector2(-W.dir() * (30.0 + float(q) * 14.0), float(q - 1) * 7.0), _p + Vector2(-W.dir() * (60.0 + float(q) * 18.0), float(q - 1) * 7.0), Color(1, 1, 1, 0.35), 1.5)

	func _sheet() -> void:
		draw_rect(Rect2(-27, -6, 54, 12), Color("a8aeb0"))
		for q in 6:
			draw_line(Vector2(-25.0 + float(q) * 9.0, -6), Vector2(-25.0 + float(q) * 9.0, 6), Color("7a8082"), 2.0)
		draw_rect(Rect2(-27, -6, 54, 12), Color("4a4e50"), false, 1.2)
		draw_rect(Rect2(10, -6, 14, 5), Color(0.55, 0.28, 0.12, 0.6))


# ---- להב טורבינה שבור שנופל ----
class BladeDrop extends Node2D:
	const WARN_T := 1.2
	const FALL_T := 0.75
	const R := 110.0
	const DMG := 2
	const DMG_Z := 90
	const TRIG_DX := 260.0
	var turbine: Node2D = null
	var floor_y := 630.0
	var state := 0                   # 0 = תלוי, 1 = חורק, 2 = נופל, 3 = על הקרקע
	var falls := 0                   # לבדיקות
	var hits := 0
	var crushed := 0
	var _t := 0.0
	var _tt := 0.0
	var _start := Vector2.ZERO       # (מקומי) מאיפה נופל
	var _land := Vector2.ZERO
	var _rot := 0.0
	var _bolt: StaticBody2D = null

	class Bolt extends StaticBody2D:
		var trap = null
		func hit_by_bullet(_p: Vector2, _n: Vector2, _d: Vector2) -> void:
			if trap != null and trap.state <= 1:
				Particles.burst(trap.get_parent(), global_position, "spark", Vector2.UP, 8)
				trap._fall()

	func _ready() -> void:
		z_index = 4
		add_to_group("hazards")
		_bolt = Bolt.new()
		_bolt.trap = self
		_bolt.collision_layer = 4
		_bolt.collision_mask = 0
		var cs := CollisionShape2D.new()
		var rs := RectangleShape2D.new()
		rs.size = Vector2(26, 26)
		cs.shape = rs
		_bolt.add_child(cs)
		add_child(_bolt)
		_land = Vector2(-120.0, 0.0)   # הלהב נופל במורד הרוח (שמאלה) מהמגדל

	func _hub() -> Vector2:
		return turbine.position + turbine.hub() + Vector2(28, 0) - position if turbine != null else Vector2(0, -400)

	func world_rect() -> Rect2:
		return Rect2(global_position + _land + Vector2(-R, -60), Vector2(R * 2.0, 60))

	func danger_at(p: Vector2, margin := 0.0) -> bool:
		return (state == 1 or state == 2) and world_rect().grow(margin).has_point(p)

	func _fall() -> void:
		if state >= 2:
			return
		state = 2
		_t = FALL_T
		_start = _hub() + Vector2.from_angle(0.4) * 110.0
		Sfx.play("w55_blade", global_position + _start, 4.0, 0.0, 1)
		if turbine != null:
			turbine.blade_gone = true
		_bolt.collision_layer = 0

	func _physics_process(delta: float) -> void:
		_tt += delta
		_t -= delta
		_bolt.position = _hub()
		var pl := get_tree().get_first_node_in_group("player") as Node2D
		match state:
			0:
				if pl != null and absf(pl.global_position.x - (global_position.x + _land.x)) < TRIG_DX and pl.global_position.x < global_position.x + 40.0:
					state = 1
					_t = WARN_T
					Sfx.play("w55_creak", global_position + _hub(), 4.0, 0.0, 1)
			1:
				if _t <= 0.0:
					_fall()
			2:
				_rot += delta * 9.0
				if _t <= 0.0:
					state = 3
					_land_hit()
		if state != 3 or Engine.get_physics_frames() % 30 == 0:
			if Art.on_screen(self, global_position + _land, 400.0):
				queue_redraw()

	func _land_hit() -> void:
		falls += 1
		var c := global_position + _land
		Sfx.play("w55_crash", c, 5.0, 0.0, 1)
		Particles.burst(get_parent(), c + Vector2(0, -6), "smoke", Vector2.UP, 16)
		for i in 10:
			var d = DebrisScript.new()
			get_parent().add_child(d)
			d.setup(c + Vector2(randf_range(-R, R) * 0.6, -10.0), Vector2(randf_range(3, 8), randf_range(2, 5)), Color("e8ecee") if i % 2 == 0 else Color("a48658"), Vector2(randf_range(-260, 260), -randf_range(160, 420)))
		var cam := get_viewport().get_camera_2d()
		if cam != null and cam.has_method("shake"):
			cam.shake(14.0, 0.5)
		var pl := get_tree().get_first_node_in_group("player") as Node2D
		if pl != null and not pl.dead and absf(pl.global_position.x - c.x) < R and pl.global_position.y > c.y - 120.0:
			hits += 1
			pl.hurt(DMG, Vector2(signf(pl.global_position.x - c.x + 0.01), -0.6))
		for z in get_tree().get_nodes_in_group("zombies"):
			if z.dead or z.is_boss():
				continue
			if absf(z.global_position.x - c.x) < R and absf(z.global_position.y - c.y) < 120.0:
				crushed += 1
				z.take_damage(DMG_Z, z.global_position + Vector2(0, -30), Vector2(signf(z.global_position.x - c.x + 0.01), -0.6), true, {"source": "hazard", "fixed": DMG_Z})

	func _draw() -> void:
		if state == 1 or state == 2:   # צל על הקרקע (איפה ייפול)
			var k := 1.0 - clampf(_t / (WARN_T if state == 1 else FALL_T), 0.0, 1.0)
			var a := 0.2 + 0.3 * k if state == 1 else 0.5
			draw_colored_polygon(Art.ellipse(_land + Vector2(0, -2), R * (0.5 + 0.5 * k), 7.0, 0.0, 20), Color(0, 0, 0, a))
			draw_arc(_land + Vector2(0, -2), R, 0.0, TAU, 32, Color(1.0, 0.4, 0.2, 0.5 * (0.5 + 0.5 * sin(_tt * 20.0))), 2.0)
		if state == 1:
			draw_string(ThemeDB.fallback_font, _hub() + Vector2(-8, -36), "!", HORIZONTAL_ALIGNMENT_LEFT, -1, 30, Color(1.0, 0.5, 0.2, 0.6 + 0.4 * sin(_tt * 30.0)))
		if state <= 1:   # הבורג האדום במרכז
			var hb := _hub()
			Art.glow(self, hb, 12.0, Color(1.0, 0.2, 0.15, 0.5 + 0.3 * sin(_tt * 6.0)))
			draw_circle(hb, 5.0, Color("c82a1e"))
			return
		var p: Vector2
		var rot: float
		if state == 2:
			var k2 := 1.0 - clampf(_t / FALL_T, 0.0, 1.0)
			p = _start.lerp(_land + Vector2(0, -16), k2 * k2)
			rot = 0.4 + _rot
		else:
			p = _land + Vector2(0, -8)
			rot = 0.06
		var dv := Vector2.from_angle(rot)
		var L := 200.0
		var a0 := p - dv * L * 0.5
		var bl := PackedVector2Array([a0 + dv.orthogonal() * 7.0, a0 + dv * L * 0.3 + dv.orthogonal() * 10.0, a0 + dv * L, a0 + dv * L * 0.95 - dv.orthogonal() * 3.0, a0 - dv.orthogonal() * 5.0])
		draw_colored_polygon(bl, Color("f2f4f5"))
		draw_polyline(PackedVector2Array([a0 - dv.orthogonal() * 5.0, a0 + dv * L * 0.95 - dv.orthogonal() * 3.0]), Color("9aa2a6"), 1.5)
		draw_line(a0, a0 - dv * 10.0, Color("5a5e60"), 6.0)   # השורש השבור


# ---- בלון גז (garrafa) שמתגלגל ושורק ----
class GasBottle extends Node2D:
	const FUSE := 3.4
	const ROLL_V := 150.0
	const BOOM_R := 130.0
	const DMG_Z := 80
	const TRIG_R := 620.0
	var floor_y := 630.0
	var state := 0                   # 0 = עומד, 1 = נופל, 2 = מתגלגל ושורק, 3 = התפוצץ
	var blown := false               # לבדיקות
	var shot := false
	var _t := 0.0
	var _tt := 0.0
	var _x := 0.0                    # (מקומי)
	var _rot := 0.0
	var _hiss := 0.0
	var _body: StaticBody2D = null

	class Shell extends StaticBody2D:
		var trap = null
		func hit_by_bullet(_p: Vector2, _n: Vector2, _d: Vector2) -> void:
			if trap != null and trap.state < 3:
				trap.shot = true
				trap._boom()

	func _ready() -> void:
		z_index = 3
		add_to_group("blastable")
		_body = Shell.new()
		_body.trap = self
		_body.collision_layer = 4
		_body.collision_mask = 0
		var cs := CollisionShape2D.new()
		var rs := RectangleShape2D.new()
		rs.size = Vector2(24, 44)
		cs.shape = rs
		_body.add_child(cs)
		add_child(_body)

	func blast_rect() -> Rect2:
		return Rect2(global_position + Vector2(_x - 14, -40), Vector2(28, 40))

	func hit_by_blast(_c: Vector2, _r: float) -> void:
		if state < 3:
			_boom.call_deferred()

	func _physics_process(delta: float) -> void:
		_tt += delta
		_t -= delta
		var pl := get_tree().get_first_node_in_group("player") as Node2D
		match state:
			0:
				_body.position = Vector2(0, -22)
				var near: bool = pl != null and pl.global_position.x < global_position.x and global_position.x - pl.global_position.x < TRIG_R
				if near and (W.gust > 0.3 or W.warn > 0.6):
					state = 1
					_t = 0.4
					Sfx.play("metal_ping", global_position, 2.0, 0.1, 1)
			1:
				_rot = lerpf(0.0, -PI * 0.5, 1.0 - clampf(_t / 0.4, 0.0, 1.0))
				if _t <= 0.0:
					state = 2
					_t = FUSE
					Sfx.play("w55_hiss", global_position, 2.0, 0.05, 2)
			2:
				var dir := W.dir()
				_x += dir * ROLL_V * (0.7 + 0.6 * W.mag) * delta
				_rot -= dir * ROLL_V * delta / 12.0
				_body.position = Vector2(_x, -12)
				_hiss -= delta
				if _hiss <= 0.0:
					_hiss = 0.12 + 0.3 * clampf(_t / FUSE, 0.0, 1.0)
					if Art.on_screen(self, global_position + Vector2(_x, 0)):
						Particles.burst(get_parent(), global_position + Vector2(_x, -14), "mist", Vector2(-dir, -0.5), 2)
						Sfx.play("w55_beep", global_position + Vector2(_x, 0), -2.0, 0.0, 2)
				if _t <= 0.0:
					_boom()
		if state < 3 and Art.on_screen(self, global_position + Vector2(_x, 0), 100.0):
			queue_redraw()

	func _boom() -> void:
		if state == 3:
			return
		state = 3
		blown = true
		_body.collision_layer = 0
		remove_from_group("blastable")
		var c := global_position + Vector2(_x, -14)
		Boom.blast.call_deferred(get_parent(), c, BOOM_R, 60.0, DMG_Z, 1, "gas")
		visible = false

	func _draw() -> void:
		var base := Vector2(_x, 0)
		var lying := state >= 2
		var piv := base + (Vector2(0, -12) if lying else Vector2.ZERO)
		draw_set_transform(piv, _rot, Vector2.ONE)
		var o := Vector2(0, 12) if lying else Vector2.ZERO
		# גליל כתום (ציור לפני הסיבוב: עומד, מרכז הבסיס ב-o)
		Art.fill_shaded(self, PackedVector2Array([o + Vector2(-11, 0), o + Vector2(-11, -32), o + Vector2(-7, -38), o + Vector2(7, -38), o + Vector2(11, -32), o + Vector2(11, 0)]), Color("e8742a"), 0.2, 0.35, Art.OUTLINE, 1.2)
		draw_rect(Rect2(o + Vector2(-11, -24), Vector2(22, 4)), Color("c85a1a"))
		draw_rect(Rect2(o + Vector2(-4, -44), Vector2(8, 6)), Color("8a8e90"))   # ברז
		draw_string(ThemeDB.fallback_font, o + Vector2(-9, -8), "GAS", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color(1, 1, 1, 0.8))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		if state == 2:
			var k := 1.0 - clampf(_t / FUSE, 0.0, 1.0)
			Art.glow(self, base + Vector2(0, -12), 14.0 + 10.0 * k, Color(1.0, 0.4, 0.15, 0.25 + 0.35 * k * (0.5 + 0.5 * sin(_tt * (10.0 + 30.0 * k)))))


# ---- גדר תיל דוקרני נמוכה על הכביש ----
class BarbedWire extends Node2D:
	const W_ := 120.0
	const H := 34.0
	const SNAG_T := 0.9
	const CD := 1.6
	const DMG_Z := 8
	var snags := 0                   # לבדיקות
	var z_snags := 0
	var balls := 0
	var _cd := 0.0
	var _zcd := {}
	var _shake := 0.0
	var rect := Rect2(0, -H, W_, H)

	func _ready() -> void:
		z_index = 4
		add_to_group("hazards")

	func world_rect() -> Rect2:
		return Rect2(global_position + Vector2(0, -H), Vector2(W_, H))

	func danger_at(p: Vector2, margin := 0.0) -> bool:
		return world_rect().grow(margin).has_point(p)

	func _physics_process(delta: float) -> void:
		_cd -= delta
		_shake = maxf(0.0, _shake - delta)
		var r := world_rect()
		var pl := get_tree().get_first_node_in_group("player") as Node2D
		if pl != null and not pl.dead and _cd <= 0.0 and pl._roll_t <= 0.0:
			var pr: Rect2 = pl.body_rect()
			if pr.intersects(r) and pr.end.y > r.position.y + 10.0:
				_cd = CD
				snags += 1
				_shake = 0.5
				pl.slow_t = maxf(pl.slow_t, SNAG_T)
				pl.hurt(1, Vector2(-signf(pl.velocity.x + 0.01) * 0.4, -0.2))
				pl._say("SNAGGED - JUMP THE WIRE", Color("e0b080"))
				Sfx.play("w55_wire", pl.global_position, 0.0, 0.1, 2)
		if Engine.get_physics_frames() % 6 == 0:
			var now := Time.get_ticks_msec()
			for z in get_tree().get_nodes_in_group("zombies"):
				if z.dead or z.is_boss():
					continue
				var zx: float = z.global_position.x
				if zx < r.position.x - 6.0 or zx > r.end.x + 6.0 or z.global_position.y < r.position.y - 4.0:
					continue
				var id: int = z.get_instance_id()
				if now - int(_zcd.get(id, -99999)) < 2500:
					continue
				_zcd[id] = now
				_shake = 0.4
				if z.type_mod != null and z.type_mod.has_method("snag_wire"):
					if z.type_mod.snag_wire(self):
						balls += 1
					continue
				z_snags += 1
				z.take_damage(DMG_Z, z.global_position + Vector2(0, -18), Vector2.UP, false, {"source": "hazard", "fixed": DMG_Z})
				if not z.dead:
					z.stagger(0.9)
		if (_shake > 0.0 or Engine.get_physics_frames() % 6 == 0) and Art.on_screen(self, global_position, 100.0):
			queue_redraw()

	func _draw() -> void:
		var pts := PackedVector2Array()
		var cols := PackedColorArray()
		for px: float in [4.0, W_ * 0.5, W_ - 4.0]:
			W.quad(pts, cols, Vector2(px - 3, 0), Vector2(px + 3, 0), Vector2(px + 2.5, -H - 6.0), Vector2(px - 2.5, -H - 8.0), Color("4a3828"), Color("4a3828"), Color("6a5038"), Color("6a5038"))
		for i in 3:
			var wy := -8.0 - float(i) * 12.0
			var n := 12
			var prev := Vector2(0, wy)
			for q in range(1, n + 1):
				var u := float(q) / float(n)
				var p := Vector2(u * W_, wy + sin(u * PI) * 2.5 + sin(W.t * 30.0 + u * 9.0) * 2.0 * _shake)
				W.seg(pts, cols, prev, p, 1.3, Color("3a3634"))
				if q % 2 == 0:   # דוקרן: X קטן
					W.seg(pts, cols, p + Vector2(-2.5, -2.5), p + Vector2(2.5, 2.5), 1.0, Color("2a2624"))
					W.seg(pts, cols, p + Vector2(-2.5, 2.5), p + Vector2(2.5, -2.5), 1.0, Color("2a2624"))
				prev = p
		W.flush(self, pts, cols)
		draw_colored_polygon(Art.ellipse(Vector2(W_ * 0.7, -20 + sin(W.t * 7.0) * 1.0), 6.0, 3.5, 0.0, 10), Color("f0ebe0"))   # צמר תקוע
		draw_colored_polygon(Art.ellipse(Vector2(W_ * 0.3, -9), 4.0, 2.0, 0.0, 8), Color(0.5, 0.06, 0.05, 0.6))   # דם ישן


# ---- מכלאה: השער נפרץ, עדר דוהר אליך ----
class Corral extends Node2D:
	const N_SHEEP := 12
	const TRIG_R := 560.0
	const RUN_V := Vector2(250.0, 330.0)
	const WARN_T := 0.7
	const W_ := 300.0
	const ShearerT := preload("res://enemies/types/shearer.gd")
	var state := 0                   # 0 = סגור, 1 = חורק, 2 = פרוץ
	var bursts := 0                  # לבדיקות
	var sheep: Array = []
	var hidden_z: Array = []         # SHEARER-ים בתוך העדר (stage_55 מוסיף)
	var _t := 0.0
	var _tt := 0.0
	var _gate := 0.0                 # 0 סגור .. 1 עף

	func _ready() -> void:
		z_index = -1
		for i in N_SHEEP:
			var s = ShearerT.Sheep.new()
			s.home_x = global_position.x + 40.0 + randf() * (W_ - 80.0)
			s.position = Vector2(s.home_x, global_position.y)
			s.ground_y = global_position.y
			s.roam = W_ * 0.5 - 30.0
			s.pen = Vector2(global_position.x + 20.0, global_position.x + W_ - 20.0)
			get_parent().add_child.call_deferred(s)
			sheep.append(s)

	func burst() -> void:
		if state == 2:
			return
		state = 2
		bursts += 1
		_gate = 0.01
		Sfx.play("w55_gate", global_position, 4.0, 0.0, 1)
		Sfx.play("w55_stampede", global_position, 4.0, 0.0, 1)
		Particles.burst(get_parent(), global_position + Vector2(0, -20), "smoke", Vector2(-1, -0.4), 10)
		var dir := -1.0
		for s in sheep:
			if is_instance_valid(s):
				s.stampede(dir, randf_range(RUN_V.x, RUN_V.y), randf_range(0.0, 0.5))
		for z in hidden_z:
			if is_instance_valid(z) and not z.dead and z.type_mod != null:
				z.type_mod.stampede(dir, randf_range(RUN_V.x, RUN_V.y) * 0.95)

	func _physics_process(delta: float) -> void:
		_tt += delta
		_t -= delta
		var pl := get_tree().get_first_node_in_group("player") as Node2D
		match state:
			0:
				if pl != null and pl.global_position.x < global_position.x and global_position.x - pl.global_position.x < TRIG_R:
					state = 1
					_t = WARN_T
					Sfx.play("w55_baa", global_position + Vector2(40, -20), 4.0, 0.2, 2)
					Sfx.play("w55_creak", global_position, 0.0, 0.2, 1)
			1:
				if _t <= 0.0:
					burst()
			2:
				if _gate > 0.0 and _gate < 1.0:
					_gate = minf(1.0, _gate + delta * 2.0)
		if (state != 0 or Engine.get_physics_frames() % 10 == 0) and Art.on_screen(self, global_position + Vector2(W_ * 0.5, 0), W_):
			queue_redraw()

	func _draw() -> void:
		var pts := PackedVector2Array()
		var cols := PackedColorArray()
		var post := Color("5a4232")
		var rail := Color("7a5a3e")
		for q in 7:   # עמודי המכלאה (גב)
			var px := float(q) * W_ / 6.0
			W.quad(pts, cols, Vector2(px - 3.5, 0), Vector2(px + 3.5, 0), Vector2(px + 3, -56), Vector2(px - 3, -58), post, post, post.lightened(0.15), post.lightened(0.15))
		for i in 3:
			var ry := -14.0 - float(i) * 17.0
			W.quad(pts, cols, Vector2(0, ry), Vector2(W_, ry), Vector2(W_, ry + 4.0), Vector2(0, ry + 4.0), rail, rail, rail.darkened(0.3), rail.darkened(0.3))
		W.flush(self, pts, cols)
		# השער (צד שמאל): רועד, ואז עף
		var sh := sin(_tt * 45.0) * 3.0 if state == 1 else 0.0
		if _gate <= 0.0:
			for i in 3:
				draw_line(Vector2(-2 + sh, -12.0 - float(i) * 17.0), Vector2(-2 + sh * 0.5, -10.0 - float(i) * 17.0), rail, 4.0)
			draw_line(Vector2(-1 + sh, -6), Vector2(-1 + sh, -56), post, 5.0)
			draw_line(Vector2(-1 + sh, -10), Vector2(-1 + sh, -50), Color("e0c040"), 1.0)
		elif _gate < 1.0:
			var p := Vector2(-90.0 * _gate, -30.0 - sin(_gate * PI) * 50.0)
			draw_set_transform(p, -_gate * 5.0, Vector2.ONE)
			draw_rect(Rect2(-6, -26, 12, 52), rail)
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		if state == 1:
			draw_string(ThemeDB.fallback_font, Vector2(-6, -70), "!", HORIZONTAL_ALIGNMENT_LEFT, -1, 26, Color(1.0, 0.6, 0.2, 0.6 + 0.4 * sin(_tt * 30.0)))


# ============================================================
#  מכשולים
# ============================================================
class Obstacle extends Node2D:
	var kind := "wool"
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
		var r := RandomNumberGenerator.new()
		r.seed = seed_v
		var rim := Color(1.0, 0.92, 0.72, 0.6)
		match kind:
			"wool":   # חבילות צמר בשקי יוטה, קשורות
				var bw := w / 2.0
				for q in 3:
					var rc := Rect2(float(q % 2) * bw, -h * 0.5, bw, h * 0.5) if q < 2 else Rect2(bw * 0.45, -h, bw * 1.1, h * 0.5)
					Art.fill_shaded(self, PackedVector2Array([rc.position + Vector2(2, 2), Vector2(rc.end.x - 2, rc.position.y + 1), rc.end - Vector2(1, 0), Vector2(rc.position.x + 1, rc.end.y)]), Color("c8b48c").darkened(r.randf() * 0.12), 0.15, 0.3, Art.OUTLINE, 1.2)
					for s in 2:
						draw_line(Vector2(rc.position.x + rc.size.x * (0.3 + 0.4 * float(s)), rc.position.y + 2), Vector2(rc.position.x + rc.size.x * (0.3 + 0.4 * float(s)), rc.end.y), Color("6a5434"), 1.6)
					draw_string(ThemeDB.fallback_font, rc.position + Vector2(5, rc.size.y * 0.65), "LV", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.3, 0.2, 0.15, 0.7))
					for s in 3:   # צמר שבורח מהשק
						Art.oval(self, rc.position + Vector2(r.randf_range(4, rc.size.x - 4), r.randf_range(2, 6)), 3.0, 2.0, Color("f2ede2"), 0.0, Art.NONE)
				draw_line(Vector2(bw * 0.45, -h), Vector2(bw * 1.55, -h), rim, 1.4)
			"posts":   # ערימת עמודי גדר
				for q in 6:
					var ry := -6.0 - float(q % 3) * 12.0 - float(q / 3) * 12.0
					if -ry > h - 4.0:
						continue
					var x0 := r.randf_range(0.0, 8.0)
					draw_rect(Rect2(x0, ry - 6.0, w - x0 - r.randf_range(0.0, 8.0), 12.0), WOOD.darkened(r.randf() * 0.2))
					draw_rect(Rect2(x0, ry - 6.0, w - x0, 2.0), Color(0.75, 0.6, 0.45, 0.6))
					Art.disc(self, Vector2(x0 + 4.0, ry), 5.5, Color("8a6a48"), Art.OUTLINE, 1.0)
					draw_arc(Vector2(x0 + 4.0, ry), 3.0, 0.0, TAU, 10, Color("5a4030"), 0.8)
				draw_line(Vector2(w * 0.3, 0), Vector2(w * 0.3, -h + 4.0), Color("3a3634"), 1.2)   # חוט קושר
			"rusty":   # טנדר F100 חלוד, בלי גלגלים
				var c := Color("7a4a32")
				Art.fill_shaded(self, PackedVector2Array([Vector2(2, -10), Vector2(2, -h * 0.55), Vector2(w * 0.5, -h * 0.58), Vector2(w * 0.56, -h), Vector2(w * 0.82, -h), Vector2(w * 0.9, -h * 0.58), Vector2(w - 2, -h * 0.52), Vector2(w - 2, -10)]), c, 0.12, 0.35, Art.OUTLINE, 1.3)
				draw_line(Vector2(w * 0.56, -h), Vector2(w * 0.82, -h), rim, 1.4)
				draw_colored_polygon(PackedVector2Array([Vector2(w * 0.59, -h + 5), Vector2(w * 0.8, -h + 5), Vector2(w * 0.86, -h * 0.62), Vector2(w * 0.55, -h * 0.62)]), Color("1a1c20"))
				draw_rect(Rect2(4, -h * 0.55, w * 0.46, 4.0), Color("5a3422"))
				for q in 8:
					Art.oval(self, Vector2(r.randf_range(8, w - 8), r.randf_range(-h * 0.5, -14)), r.randf_range(3, 6), r.randf_range(2, 4), Color(0.35, 0.16, 0.08, 0.7), 0.0, Art.NONE)
				for wx: float in [w * 0.2, w * 0.8]:
					draw_rect(Rect2(wx - 12, -12, 24, 12), Color("2a2622"))   # על לבנים
					draw_rect(Rect2(wx - 12, -12, 24, 3), Color("8a4a3a"))
				draw_string(ThemeDB.fallback_font, Vector2(w * 0.06, -h * 0.28), "FORD", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color(0.85, 0.8, 0.7, 0.5))
			_:   # שוקת בטון עם מים קפואים-למחצה
				Art.fill_shaded(self, PackedVector2Array([Vector2(0, 0), Vector2(0, -h), Vector2(w, -h), Vector2(w, 0)]), Color("8a8a84"), 0.15, 0.3, Art.OUTLINE, 1.3)
				draw_rect(Rect2(4, -h + 3.0, w - 8.0, 6.0), Color("5a8a9a"))
				draw_rect(Rect2(4, -h + 3.0, w - 8.0, 1.5), Color(0.85, 0.95, 1.0, 0.7))
				draw_line(Vector2(0, -h), Vector2(w, -h), rim, 1.4)
				for q in 4:
					draw_line(Vector2(r.randf_range(4, w - 4), -h + 10), Vector2(r.randf_range(4, w - 4), -4), Color(0.4, 0.4, 0.38, 0.5), 1.0)
				Art.oval(self, Vector2(w * 0.7, -h + 2.0), 6.0, 3.0, Color("e8e2d0"), 0.0, Art.OUTLINE, 0.8)   # גולגולת כבשה בשוקת


# ============================================================
#  זירת הבוס: חזית מחסן הגז"ז הגדול + מכבש צמר מוגבה
# ============================================================
class ShearingYard extends Node2D:
	var w := 1100.0

	func _ready() -> void:
		z_index = -3

	func _process(_delta: float) -> void:
		if Engine.get_process_frames() % 4 == 2 and Art.on_screen(self, global_position + Vector2(w * 0.5, -150), w * 0.5 + 100.0):
			queue_redraw()

	func _draw() -> void:
		var h := 300.0
		draw_rect(Rect2(60, -h, w - 120, h), Color("8a9294"))
		var pts := PackedVector2Array()
		var cols := PackedColorArray()
		var x := 60.0
		while x < w - 60.0:
			W.quad(pts, cols, Vector2(x, -h), Vector2(x + 4, -h), Vector2(x + 4, 0), Vector2(x, 0), Color(1, 1, 1, 0.14), Color(1, 1, 1, 0.14), Color(1, 1, 1, 0.08), Color(1, 1, 1, 0.08))
			W.quad(pts, cols, Vector2(x + 6, -h), Vector2(x + 9, -h), Vector2(x + 9, 0), Vector2(x + 6, 0), Color(0, 0, 0, 0.14), Color(0, 0, 0, 0.14), Color(0, 0, 0, 0.2), Color(0, 0, 0, 0.2))
			x += 11.0
		W.flush(self, pts, cols)
		draw_colored_polygon(PackedVector2Array([Vector2(40, -h), Vector2(w * 0.5, -h - 90), Vector2(w - 40, -h), Vector2(w - 40, -h + 6), Vector2(w * 0.5, -h - 82), Vector2(40, -h + 6)]), Color("7a3424"))
		draw_rect(Rect2(w * 0.5 - 220, -h + 26, 440, 40), Color("e4d8bc"))
		draw_rect(Rect2(w * 0.5 - 220, -h + 26, 440, 40), Color("3a2a20"), false, 3.0)
		draw_string(ThemeDB.fallback_font, Vector2(w * 0.5 - 206, -h + 56), "GALPON DE ESQUILA - LA VENTOSA", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color("7a1a14"))
		# דלתות ענק פתוחות - חושך, ווים תלויים עם גיזות
		draw_rect(Rect2(w * 0.3, -210, w * 0.4, 210), Color("4a3c30"))   # פנים המחסן: חום חמים (שהבוס ייקרא מולו)
		draw_rect(Rect2(w * 0.3, -210, w * 0.4, 60), Color("2e2620"))
		for q in 5:   # קרני אור דרך הפח
			var lx := w * 0.33 + float(q) * w * 0.08
			draw_colored_polygon(PackedVector2Array([Vector2(lx, -210), Vector2(lx + 14, -210), Vector2(lx + 40, 0), Vector2(lx + 22, 0)]), Color(1.0, 0.85, 0.55, 0.08))
		draw_rect(Rect2(w * 0.3, -40, w * 0.4, 40), Color("6a5a44"))   # רצפת עץ
		for q in 9:
			var hx := w * 0.32 + float(q) * w * 0.045
			var sw := sin(W.t * 1.5 + float(q)) * (2.0 + 5.0 * W.gust)
			draw_line(Vector2(hx, -210), Vector2(hx + sw, -150), Color("4a4a4a"), 1.2)
			if q % 2 == 0:
				Art.fill(self, PackedVector2Array([Vector2(hx + sw - 8, -150), Vector2(hx + sw + 8, -150), Vector2(hx + sw + 10, -120), Vector2(hx + sw, -110), Vector2(hx + sw - 10, -120)]), Color("d8cfba"), Art.OUTLINE, 1.0)
				draw_line(Vector2(hx + sw - 6, -130), Vector2(hx + sw + 4, -118), Color(0.5, 0.06, 0.05, 0.8), 2.0)
		# מכלאות לפני המחסן (גב)
		for q in 12:
			var px := 80.0 + float(q) * (w - 160.0) / 11.0
			draw_line(Vector2(px, 0), Vector2(px, -60), Color("5a4232"), 5.0)
		for i in 2:
			draw_line(Vector2(80, -22.0 - float(i) * 24.0), Vector2(w - 80, -22.0 - float(i) * 24.0), Color("7a5a3e"), 4.0)


class WoolPress extends Node2D:
	var tier := 130.0
	var w := 170.0

	func _ready() -> void:
		z_index = -1

	func _draw() -> void:
		for lx: float in [6.0, w - 6.0]:
			draw_line(Vector2(lx, 0), Vector2(lx, -tier), Color("4a3a2a"), 7.0)
		draw_line(Vector2(6, -10), Vector2(w - 6, -tier + 10), Color("5a4a36"), 2.5)
		draw_rect(Rect2(-4, -tier - 4, w + 8, 10), Color("5a4030"))
		draw_rect(Rect2(-4, -tier - 4, w + 8, 2.5), Color("a8845e"))
		# המכבש: מסגרת ברזל עם בורג ענק וחבילת צמר
		draw_rect(Rect2(w * 0.5 - 30, -tier - 90, 60, 86), Color("3a3e40"), false, 4.0)
		draw_line(Vector2(w * 0.5, -tier - 90), Vector2(w * 0.5, -tier - 50), Color("6a6e70"), 5.0)
		draw_line(Vector2(w * 0.5 - 24, -tier - 92), Vector2(w * 0.5 + 24, -tier - 88), Color("6a6e70"), 3.0)
		draw_rect(Rect2(w * 0.5 - 26, -tier - 46, 52, 40), Color("d0c4a4"))
		draw_line(Vector2(w * 0.5 - 26, -tier - 26), Vector2(w * 0.5 + 26, -tier - 26), Color("6a5434"), 1.5)


# ============================================================
#  מסך: פסי אבק וזרעים ברוח, ושרוול רוח קטן
# ============================================================
class WindFX extends Node2D:
	var vp := Vector2(1280, 720)
	var _t := 0.0

	func _process(delta: float) -> void:
		_t += delta
		if Engine.get_process_frames() % 2 == 0:
			queue_redraw()

	func _draw() -> void:
		var q := clampf(Quality.ambient(), 0.3, 1.0)
		var pts := PackedVector2Array()
		var cols := PackedColorArray()
		var dir := W.dir()
		var n := int((18.0 + 34.0 * W.mag + 30.0 * W.gust) * q)
		for i in n:   # פסי אבק
			var sp := 0.8 + W.h(i, 1) * 0.9
			var x := fposmod(W.h(i, 2) * vp.x * 3.0 + W.drift * sp * 3.2, vp.x + 400.0) - 200.0
			var y := W.h(i, 3) * vp.y * 0.95 + sin(_t * 1.7 + float(i)) * 14.0
			var ln := (40.0 + W.h(i, 4) * 90.0) * (0.5 + W.mag)
			var a := (0.05 + 0.07 * W.h(i, 5)) * (0.6 + W.mag) + 0.06 * W.gust
			var c := Color(0.95, 0.86, 0.66, a)
			var c0 := Color(c, 0.0)
			W.quad(pts, cols, Vector2(x, y), Vector2(x - dir * ln, y - 1.5), Vector2(x - dir * ln, y - 0.5), Vector2(x, y + 1.2), c, c0, c0, c)
		for i in int((10.0 + 16.0 * W.mag) * q):   # זרעים / קרעי עשב
			var sp2 := 1.2 + W.h(i, 6) * 0.8
			var x2 := fposmod(W.h(i, 7) * vp.x * 2.0 + W.drift * sp2 * 3.8, vp.x + 100.0) - 50.0
			var y2 := 200.0 + W.h(i, 8) * 460.0 + sin(_t * 4.0 + float(i) * 1.3) * 18.0
			var rot := _t * 6.0 + float(i)
			var s := 2.0 + W.h(i, 9) * 2.5
			W.quad(pts, cols, Vector2(x2, y2) + Vector2.from_angle(rot) * s, Vector2(x2, y2) + Vector2.from_angle(rot + 1.8) * s * 0.4, Vector2(x2, y2) - Vector2.from_angle(rot) * s, Vector2(x2, y2) + Vector2.from_angle(rot - 1.8) * s * 0.4, Color(0.9, 0.82, 0.55, 0.7), Color(0.9, 0.82, 0.55, 0.7), Color(0.7, 0.6, 0.35, 0.7), Color(0.7, 0.6, 0.35, 0.7))
		W.flush(self, pts, cols)
		if W.gust > 0.05:   # במשב: אובך אבק חם על כל המסך (חלש)
			draw_rect(Rect2(Vector2.ZERO, vp), Color(0.9, 0.78, 0.55, 0.07 * W.gust))


class WindHud extends Node2D:
	var vp := Vector2(1280, 720)
	var _t := 0.0

	func _process(delta: float) -> void:
		_t += delta
		if Engine.get_process_frames() % 2 == 1:
			queue_redraw()

	func _draw() -> void:
		var p := Vector2(vp.x - 96.0, 168.0)
		var dir := W.dir()
		draw_line(p + Vector2(0, -2), p + Vector2(0, 34), Color(0.1, 0.1, 0.12, 0.8), 3.0)
		# שרוול רוח: נעשה ישר כשהרוח חזקה
		var stiff := clampf(W.mag, 0.0, 1.0)
		var n := 5
		for i in n:
			var u0 := float(i) / float(n)
			var u1 := float(i + 1) / float(n)
			var a0 := _sock(p, u0, stiff, dir)
			var a1 := _sock(p, u1, stiff, dir)
			var r0 := 9.0 - u0 * 5.0
			var r1 := 9.0 - u1 * 5.0
			var cc := Color("f05a28") if i % 2 == 0 else Color("f4f0e8")
			draw_colored_polygon(PackedVector2Array([a0 + Vector2(0, -r0), a1 + Vector2(0, -r1), a1 + Vector2(0, r1), a0 + Vector2(0, r0)]), cc)
		var txt := "WIND"
		var col := Color(1, 1, 1, 0.75)
		if W.warn > 0.05 or W.gust > 0.3:
			txt = "GUST!"
			col = Color(1.0, 0.75, 0.3, 0.6 + 0.4 * sin(_t * 18.0))
		draw_string(ThemeDB.fallback_font, p + Vector2(-26, 54), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, col)
		var bw := 52.0
		draw_rect(Rect2(p + Vector2(-26, 60), Vector2(bw, 4)), Color(0, 0, 0, 0.4))
		draw_rect(Rect2(p + Vector2(-26, 60), Vector2(bw * clampf(W.mag, 0.0, 1.0), 4)), Color(1.0, 0.7 - 0.4 * W.gust, 0.3))

	func _sock(p: Vector2, u: float, stiff: float, dir: float) -> Vector2:
		var droop := (1.0 - stiff) * u * u * 30.0
		var wave := sin(u * 6.0 - _t * (6.0 + 10.0 * stiff)) * 2.5 * u
		return p + Vector2(dir * u * 44.0 * (0.4 + 0.6 * stiff), droop + wave)
