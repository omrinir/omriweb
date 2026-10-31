extends RefCounted
const DrawBatch := preload("res://effects/draw_batch.gd")   # כל הציור של זומבי ב-draw call אחד
# ============================================================
#  קישוטים לשלב 60 ("GLACIER LAB") - אזור שביעי (פטגוניה), שלב 6. "THEY LEARNED WHERE THEY CAME FROM".
#  תחנת המחקר של פרויקט ECHO, בנויה בתוך הקרחון: מנהרות קרח באור כחול, מסדרונות פלדה, מעבדות עם מיכלי הקפאה
#  שבורים, צנצנות דגימות, ארונות שרתים, דלתות הדף, אורות חירום אדומים ואזעקות, כפור על הכל, ופטריית ECHO
#  שמטפסת על הקירות ופועמת לכיוון הקומות העמוקות (ה-ROOT - נשמר לשלב 62).
#    lab_sky       - (רקע) עומק הקרחון: כחול כהה, סדקי אור, גבישי קרח שנופלים לאט
#    far_ice       - (רקע, 0.06) קיר מערת הקרח: שכבות קרח בגווני כחול, סדקים, סלעים כלואים, בועות אוויר, עמודי אור,
#                    קורות פלדה רחוקות עם מנורות כחולות
#    mid_lab       - (רקע, 0.28) הקיר האחורי של המעבדה: לוחות פלדה, חלונות אל הקרחון / אל חדרי מעבדה עם מיכלים,
#                    עורקי ECHO שפועמים ימינה (לעומק), מנורות חירום (מסתובבות באדום בזמן LOCKDOWN), שלטים
#    near_rig      - (רקע, 0.6) צינורות ענק עם כפור ונטיפים, מגשי כבלים, תעלות אוורור בתקרה, פלורסנטים מהבהבים,
#                    חוטי פטרייה תלויים, מכונות נמוכות מאחורי הדרך
#    lab_overlay   - אובך קר מאחורי הדמויות + צל התקרה
#    LabGround     - (עולם) רצפת פלדה מחוררת, כפור, כתמי קרח, פסי סכנה, פטרייה זוחלת. בכניסה: שלג וקרח
#    Entrance      - (עולם) פתח המנהרה בקרחון ושער התחנה ("ESTACION GLACIAR - PROYECTO ECHO")
#    BlastDoor     - (עולם, מוצק כשסגור) דלת הדף ענקית בין האגפים. LOCKDOWN = נטרקת (מועכת זומבים שמתחתיה).
#                    לוח אזעקה + קורא כרטיסים ליד הדלת, משואה אדומה מעל. נפתחת בכרטיס של WARDEN (enemies/types/warden.gd)
#    CryoTank      - (עולם) מיכל הקפאה עם SPECIMEN קפוא בפנים (enemies/types/specimen.gd): הזכוכית מתכסה סדקים ואדים
#                    (thaw) ומתנפצת (burst). TankGlass = הזכוכית מקדימה (z מעל הזומבי). גם ריקים / שבורים מזמן לקישוט
#    JarShelf      - (עולם) מדפי צנצנות דגימה: איברים, מוחות ועוברים בנוזל עכור עם חוטי פטרייה, תוויות
#    ServerRack    - (עולם) ארון שרתים עם נוריות מהבהבות, כבלים, כפור
#    Catwalk       - (עולם) גשר הליכה מפלדה תלוי מהתקרה (הקומה עצמה = add_floor בשלב)
#    Terminal      - (עולם) מסוף בקיר ארכיון התיקים. בסצנת הסיפור מציג את התיק SUBJECT ZERO (U.file_ms),
#                    ואז נבלע בפטרייה "WELCOME HOME" (U.welcome_ms)
#    FungusPatch   - (עולם) גידול ECHO על הקיר / הרצפה: חוטים ובלוטות שפועמים ימינה
#    CoolantVent   - (עולם, מלכודת) פתח חנקן נוזלי ברצפה: מתקרבים -> שריקה וטבעת כפור (WARN_T) -> עמוד קור (BLAST_T):
#                    פוגע + מאט אותך, מקפיא זומבים (נעצרים, שבירים). ירייה בגלגל השסתום = מפעילים מתי שרוצים
#    Keycard       - (עולם) כרטיס מפתח של WARDEN שנפל: נאסף כשעוברים עליו (השלב מחליט מה הוא פותח)
#    Obstacle      - (מוצק + מחסה) "bench" שולחן מעבדה / "dewar" מיכלי חנקן / "gurney" אלונקה הפוכה / "rack" ארון שרתים שנפל
#    ContainmentArena - (עולם) חדר הכליאה של SUBJECT FOUR: תא כליאה ענק שנפרץ מבפנים, חלון תצפית, צוהר "NIVEL -4"
#                    שהפטרייה זורמת אליו (ה-ROOT)
#    LabFX         - (מסך) גבישי כפור, אדי קור, הבהוב אדום של אזעקה, הבהוב חשמל, כרטיסי המפתח שלך (פינה)
#  מצב משותף: U.alarm (0..1, LOCKDOWN), U.file_ms / U.welcome_ms (הסצנה), U.cards (כמה כרטיסים יש לך).
#  לשנות: BlastDoor.CLOSE_T / OPEN_T, CryoTank.THAW_T, CoolantVent.TRIG_R / WARN_T / BLAST_T / CD / DMG / FREEZE_T / DMG_Z,
#         Keycard.PICK_R.
# ============================================================

const Art := preload("res://art.gd")
const Sfx := preload("res://sfx.gd")
const Kit := preload("res://effects/backdrop_kit.gd")
const Particles := preload("res://particles.gd")

const STEEL := Color("4e5964")
const STEEL_D := Color("2a3139")
const STEEL_L := Color("8494a2")
const ICE := Color("9fd4ec")
const ICE_D := Color("2e6a8e")
const ICE_L := Color("dff3fb")
const FROST := Color("e8f6fc")
const RED_E := Color("ff2e2a")
const AMBER := Color("ffb040")
const ECHO := Color(0.75, 1.0, 0.55)        # אותו צבע כמו effects/spore_lesson.gd
const ECHO_D := Color("3c5a2c")
const ECHO_M := Color("6e9a46")
const HAZ := Color("e8b828")
const GOWN := Color("9ab8b4")


# מצב משותף (השלב כותב, כל הקישוטים קוראים) + עזרים - מחלקה פנימית לא רואה פונקציות סטטיות של הקובץ
class U:
	static var alarm := 0.0          # 0..1 - LOCKDOWN (אורות אדומים, משואות מסתובבות)
	static var file_ms := -1         # (סצנה) "file_open": התיק מופיע במסוף
	static var welcome_ms := -1      # (סצנה) "welcome": הפטרייה בולעת את המסך, האורות מהבהבים
	static var cards := 0            # כרטיסי מפתח אצלך (LabFX מצייר)
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

	# עורק פטרייה: קו מתפתל עם בלוטות, הדופק נע ימינה (pulse_x = x בעולם בשביל הגל)
	static func vein(pts: PackedVector2Array, cols: PackedColorArray, a: Vector2, b: Vector2, w: float, t: float, wx: float, seed_v: int) -> void:
		var n := 7
		var prev := a
		for q in range(1, n + 1):
			var k := float(q) / float(n)
			var p := a.lerp(b, k) + Vector2(sin(k * 7.0 + float(seed_v)) * 5.0, cos(k * 5.0 + float(seed_v) * 0.7) * 3.0)
			var pulse := 0.5 + 0.5 * sin(t * 3.2 - (wx + p.x) * 0.012)
			var c := ECHO_D.lerp(ECHO, pulse * 0.55)
			seg(pts, cols, prev, p, w * (1.0 - k * 0.5), c)
			if q % 2 == 0:
				oval(pts, cols, p, 2.2 + pulse * 1.4, 2.0 + pulse * 1.2, Color(ECHO, 0.45 + 0.5 * pulse), 6)
			prev = p


static func _h(i: int, s: int) -> float:
	return U.h(i, s)


static func _ms_since(ms: int) -> float:
	return U.since(ms)


# ============================================================
#  רקע
# ============================================================

# ---- עומק הקרחון: כחול כהה, סדקי אור, גבישים ----
static func lab_sky(ci: CanvasItem, v: Vector2, t: float) -> void:
	Kit.gradient_sky(ci, v, [Color("04090f"), Color("08182a"), Color("0e2e48"), Color("17496a"), Color("22607e")], 0.92)
	Kit.soft_glow(ci, Vector2(v.x * 0.3, v.y * 0.25), 420.0, Color(0.4, 0.8, 1.0, 0.12), 0.6)
	Kit.soft_glow(ci, Vector2(v.x * 0.78, v.y * 0.4), 360.0, Color(0.3, 0.7, 1.0, 0.1), 0.5)
	var pts := PackedVector2Array()
	var cols := PackedColorArray()
	for i in 46:   # גבישי קרח שנופלים לאט בחושך
		var x := fposmod(_h(i, 1) * v.x * 1.3 + sin(t * 0.3 + float(i)) * 20.0, v.x)
		var y := fposmod(_h(i, 2) * v.y + t * (6.0 + _h(i, 3) * 10.0), v.y)
		U.dia(pts, cols, Vector2(x, y), 0.8 + _h(i, 4) * 1.2, Color(0.8, 0.95, 1.0, 0.25 + 0.3 * _h(i, 5)))
	U.flush(ci, pts, cols)


# ---- קיר מערת הקרח: שכבות, סדקים, סלעים כלואים, בועות, עמודי אור, קורות פלדה רחוקות ----
static func far_ice(ci: CanvasItem, sc: float, v: Vector2, y: float, t: float) -> void:
	var period := 1600.0
	var start := int(floor(sc / period)) - 1
	var pts := PackedVector2Array()
	var cols := PackedColorArray()
	var bands := [Color("123a58"), Color("1a4e70"), Color("246482"), Color("1c587a"), Color("2c7294"), Color("1e5476"), Color("163e5c")]
	for k in range(start, start + int(ceil(v.x / period)) + 2):
		var bx := float(k) * period - sc
		# שכבות קרח גליות (מלמעלה למטה)
		var prev_y := []
		for q in 17:
			prev_y.append(0.0)
		for b in bands.size():
			var top_y: Array = prev_y.duplicate()
			var bot_y := []
			for q in 17:
				var px := float(q) * 100.0
				var base := (y + 30.0) * float(b + 1) / float(bands.size())
				bot_y.append(base + sin(px * 0.004 + float(k * 3 + b)) * 26.0 + _h(k * 31 + q, b) * 14.0)
			for q in 16:
				var x0 := bx + float(q) * 100.0
				var x1 := x0 + 100.0
				var c: Color = bands[b]
				var c2: Color = c.lightened(0.06)
				U.quad(pts, cols, Vector2(x0, float(top_y[q])), Vector2(x1, float(top_y[q + 1])), Vector2(x1, float(bot_y[q + 1])), Vector2(x0, float(bot_y[q])), c2, c2, c, c)
			# קו השכבה (אבק / אפר עתיק כלוא בקרח)
			for q in 16:
				var a := Vector2(bx + float(q) * 100.0, float(bot_y[q]))
				var bb := Vector2(bx + float(q + 1) * 100.0, float(bot_y[q + 1]))
				U.seg(pts, cols, a, bb, 1.4, Color(0.05, 0.12, 0.2, 0.35) if b % 2 == 0 else Color(0.7, 0.9, 1.0, 0.12))
			prev_y = bot_y
		# סלעים כלואים בקרח
		for q in 6:
			var rp := Vector2(bx + _h(k * 7 + q, 11) * period, 80.0 + _h(k * 7 + q, 12) * (y - 120.0))
			var rr := 10.0 + _h(k * 7 + q, 13) * 22.0
			U.oval(pts, cols, rp, rr, rr * 0.7, Color(0.08, 0.13, 0.18, 0.55), 7, _h(q, 14) * 3.0)
			U.oval(pts, cols, rp + Vector2(-rr * 0.2, -rr * 0.2), rr * 0.5, rr * 0.3, Color(0.4, 0.6, 0.75, 0.18), 6)
		# בועות אוויר קפואות
		for q in 34:
			var bp := Vector2(bx + _h(k * 41 + q, 15) * period, 30.0 + _h(k * 41 + q, 16) * (y - 40.0))
			U.oval(pts, cols, bp, 1.2 + _h(q, 17) * 2.2, 1.2 + _h(q, 17) * 2.2, Color(0.85, 0.96, 1.0, 0.35), 6)
		# סדקים בהירים
		for q in 5:
			var cp := Vector2(bx + _h(k * 5 + q, 18) * period, 40.0 + _h(k * 5 + q, 19) * 200.0)
			var a := cp
			for s in 5:
				var b2 := a + Vector2((_h(k + q * 5 + s, 20) - 0.5) * 70.0, 30.0 + _h(q + s, 21) * 50.0)
				U.seg(pts, cols, a, b2, 1.6, Color(0.75, 0.95, 1.0, 0.35))
				a = b2
		# קורות פלדה רחוקות (התחנה נבנתה לתוך הקרח)
		for q in 2:
			var tx := bx + 380.0 + float(q) * 800.0
			U.rect(pts, cols, Rect2(tx - 7.0, 0.0, 14.0, y), Color(0.08, 0.12, 0.16, 0.85))
			var yy := 30.0
			while yy < y - 40.0:
				U.seg(pts, cols, Vector2(tx - 7.0, yy), Vector2(tx + 60.0, yy + 50.0), 3.0, Color(0.08, 0.12, 0.16, 0.7))
				yy += 110.0
	U.flush(ci, pts, cols)
	# עמודי אור שעוברים דרך הקרח הדק + מנורות כחולות על הקורות
	for k in range(start, start + int(ceil(v.x / period)) + 2):
		var bx := float(k) * period - sc
		var lx := bx + 900.0 + _h(k, 22) * 300.0
		if lx > -300.0 and lx < v.x + 300.0:
			var a := 0.12 + 0.05 * sin(t * 0.5 + float(k))
			DrawBatch.polygon(ci, PackedVector2Array([Vector2(lx - 40.0, 0), Vector2(lx + 40.0, 0), Vector2(lx + 150.0, y), Vector2(lx - 70.0, y)]),
				PackedColorArray([Color(0.7, 0.92, 1.0, a), Color(0.7, 0.92, 1.0, a), Color(0.7, 0.92, 1.0, 0.0), Color(0.7, 0.92, 1.0, 0.0)]))
		for q in 2:
			var tx := bx + 380.0 + float(q) * 800.0
			if tx > -60.0 and tx < v.x + 60.0:
				Kit.soft_glow(ci, Vector2(tx, 140.0 + float(q) * 60.0), 34.0, Color(0.5, 0.85, 1.0, 0.4 + 0.1 * sin(t * 1.3 + float(k + q))))


# ---- הקיר האחורי של המעבדה: לוחות, חלונות, עורקי ECHO, מנורות חירום, שלטים ----
static func mid_lab(ci: CanvasItem, sc: float, v: Vector2, y: float, t: float) -> void:
	var period := 900.0
	var start := int(floor(sc / period)) - 1
	var floor_top := y - 150.0         # מתחת לחלונות: קיר עד הרצפה
	var win_top := 120.0
	var al: float = U.alarm
	for k in range(start, start + int(ceil(v.x / period)) + 2):
		var bx := float(k) * period - sc
		if bx > v.x + 20.0 or bx + period < -20.0:
			continue
		var pts := PackedVector2Array()
		var cols := PackedColorArray()
		var wx0 := bx + 160.0
		var wx1 := bx + 640.0
		var room := posmod(k, 3) == 1    # חלון אל חדר מעבדה (אחרת - אל הקרחון)
		# קירות סביב החלון (החלון עצמו שקוף - רואים את שכבת הקרח מאחור)
		U.vrect(pts, cols, Rect2(bx, 0.0, period, win_top), Color("1c242c"), Color("2c3640"))
		U.vrect(pts, cols, Rect2(bx, floor_top, period, v.y - floor_top), Color("3e4a56"), Color("2c3540"))
		U.vrect(pts, cols, Rect2(bx, win_top, wx0 - bx, floor_top - win_top), Color("34404c"), Color("3c4854"))
		U.vrect(pts, cols, Rect2(wx1, win_top, bx + period - wx1, floor_top - win_top), Color("34404c"), Color("3c4854"))
		if room:   # חדר מעבדה מואר בכחול: קיר אחורי, שורת מיכלים, אחד שבור
			U.vrect(pts, cols, Rect2(wx0, win_top, wx1 - wx0, floor_top - win_top), Color("16303e"), Color("244656"))
			for q in 5:
				var tx := wx0 + 60.0 + float(q) * 92.0
				var tb := floor_top - 6.0
				U.rect(pts, cols, Rect2(tx - 22.0, tb - 18.0, 44.0, 18.0), Color("1a252e"))
				var broken := (q + k) % 4 == 2
				U.vrect(pts, cols, Rect2(tx - 17.0, tb - 120.0, 34.0, 102.0), Color(0.3, 0.75, 0.9, 0.35 if not broken else 0.1), Color(0.2, 0.55, 0.75, 0.5 if not broken else 0.12))
				U.rect(pts, cols, Rect2(tx - 22.0, tb - 132.0, 44.0, 12.0), Color("1a252e"))
				if not broken:   # צללית בתוך המיכל
					U.oval(pts, cols, Vector2(tx, tb - 92.0), 5.0, 6.0, Color(0.05, 0.12, 0.16, 0.8), 7)
					U.quad(pts, cols, Vector2(tx - 6.0, tb - 85.0), Vector2(tx + 6.0, tb - 85.0), Vector2(tx + 5.0, tb - 30.0), Vector2(tx - 5.0, tb - 30.0), Color(0.05, 0.12, 0.16, 0.8), Color(0.05, 0.12, 0.16, 0.8), Color(0.05, 0.12, 0.16, 0.6), Color(0.05, 0.12, 0.16, 0.6))
					var bub := fposmod(t * 30.0 + float(q * 37), 90.0)
					U.dia(pts, cols, Vector2(tx + 6.0, tb - 24.0 - bub), 1.4, Color(0.8, 1.0, 1.0, 0.5))
				else:   # שבור: רסיסים, נוזל על הרצפה
					U.tri(pts, cols, Vector2(tx - 17.0, tb - 18.0), Vector2(tx - 10.0, tb - 60.0), Vector2(tx - 4.0, tb - 18.0), Color(0.6, 0.85, 0.95, 0.35))
					U.tri(pts, cols, Vector2(tx + 17.0, tb - 18.0), Vector2(tx + 12.0, tb - 44.0), Vector2(tx + 5.0, tb - 18.0), Color(0.6, 0.85, 0.95, 0.3))
					U.oval(pts, cols, Vector2(tx, tb + 2.0), 34.0, 3.0, Color(0.3, 0.7, 0.8, 0.35), 8)
		else:   # הזכוכית אל הקרחון: גוון כחול + השתקפויות אלכסוניות
			U.rect(pts, cols, Rect2(wx0, win_top, wx1 - wx0, floor_top - win_top), Color(0.4, 0.7, 0.9, 0.12))
			for q in 3:
				var rx := wx0 + 60.0 + float(q) * 150.0
				U.quad(pts, cols, Vector2(rx, win_top), Vector2(rx + 30.0, win_top), Vector2(rx - 50.0, floor_top), Vector2(rx - 80.0, floor_top), Color(1, 1, 1, 0.06), Color(1, 1, 1, 0.06), Color(1, 1, 1, 0.0), Color(1, 1, 1, 0.0))
		# מסגרת החלון + כפור בפינות
		U.rect(pts, cols, Rect2(wx0 - 8.0, win_top - 8.0, wx1 - wx0 + 16.0, 8.0), Color("5a6a78"))
		U.rect(pts, cols, Rect2(wx0 - 8.0, floor_top, wx1 - wx0 + 16.0, 10.0), Color("5a6a78"))
		U.rect(pts, cols, Rect2(wx0 - 8.0, win_top, 8.0, floor_top - win_top), Color("4a5866"))
		U.rect(pts, cols, Rect2(wx1, win_top, 8.0, floor_top - win_top), Color("4a5866"))
		U.rect(pts, cols, Rect2((wx0 + wx1) * 0.5 - 3.0, win_top, 6.0, floor_top - win_top), Color("4a5866"))
		for c2: Vector2 in [Vector2(wx0, win_top), Vector2(wx1, win_top), Vector2(wx0, floor_top), Vector2(wx1, floor_top)]:
			var sx := 1.0 if c2.x < bx + 400.0 else -1.0
			var sy := 1.0 if c2.y < 200.0 else -1.0
			U.tri(pts, cols, c2, c2 + Vector2(sx * 46.0, 0), c2 + Vector2(0, sy * 34.0), Color(0.9, 0.97, 1.0, 0.45))
			U.tri(pts, cols, c2, c2 + Vector2(sx * 24.0, 0), c2 + Vector2(0, sy * 60.0), Color(0.9, 0.97, 1.0, 0.25))
		# לוחות הקיר: תפרים + מסמרות
		for q in 9:
			var px := bx + float(q) * 100.0
			if px > wx0 - 10.0 and px < wx1 + 10.0:
				continue
			U.rect(pts, cols, Rect2(px, win_top, 2.0, floor_top - win_top), Color(0.1, 0.13, 0.16, 0.6))
		for q in 18:
			U.rect(pts, cols, Rect2(bx + float(q) * 50.0, floor_top + 4.0, 50.0, 2.0), Color(0.12, 0.15, 0.18, 0.5))
			if q % 2 == 0:
				U.dia(pts, cols, Vector2(bx + float(q) * 50.0 + 12.0, floor_top + 18.0), 1.6, Color(0.6, 0.68, 0.74, 0.6))
		# פס סכנה צהוב-שחור לאורך הקיר
		var sy0 := floor_top + 70.0
		for q in 30:
			var xx := bx + float(q) * 30.0
			U.quad(pts, cols, Vector2(xx, sy0), Vector2(xx + 15.0, sy0), Vector2(xx + 5.0, sy0 + 10.0), Vector2(xx - 10.0, sy0 + 10.0), Color(HAZ, 0.6), Color(HAZ, 0.6), Color(HAZ, 0.6), Color(HAZ, 0.6))
		# צינורות אופקיים על הקיר
		U.vrect(pts, cols, Rect2(bx, win_top - 30.0, period, 14.0), Color("6e7c88"), Color("3a4550"))
		U.vrect(pts, cols, Rect2(bx, floor_top + 40.0, period, 9.0), Color("7a6a50"), Color("4a3e2c"))
		for q in 4:   # חבקים
			U.rect(pts, cols, Rect2(bx + 60.0 + float(q) * 230.0, win_top - 33.0, 8.0, 20.0), Color("2a3038"))
		# עורקי ECHO: מטפסים על הקירות, עבים יותר ימינה (לעומק)
		var thick := clampf((sc + bx + 450.0) / 10000.0, 0.2, 1.0)
		for q in 3:
			var vx := bx + 40.0 + float(q) * 300.0 + _h(k * 3 + q, 30) * 80.0
			var vy0 := floor_top + 90.0
			U.vein(pts, cols, Vector2(vx, vy0), Vector2(vx + 60.0 + _h(q, 31) * 80.0, win_top - 20.0 + _h(k + q, 32) * 60.0), 3.0 + 3.5 * thick, t, sc, k * 3 + q)
			if thick > 0.5:
				U.vein(pts, cols, Vector2(vx, vy0), Vector2(vx + 160.0, vy0 - 30.0), 2.5 + 2.0 * thick, t, sc, k * 7 + q)
		U.flush(ci, pts, cols)
		# מנורות חירום על העמודים: כתום עמום, ובזמן LOCKDOWN - אדום מסתובב
		for q in 2:
			var lx := bx + 80.0 + float(q) * 640.0
			var ly := win_top + 26.0
			DrawBatch.rect(ci, Rect2(lx - 8.0, ly - 4.0, 16.0, 10.0), Color("2a3038"))
			if al > 0.02:
				var rot := sin(t * 6.0 + float(q)) * 0.5 + 0.5
				DrawBatch.circle(ci, Vector2(lx, ly - 6.0), 6.0, Color(1.0, 0.2, 0.15, 0.6 + 0.4 * rot))
				Kit.soft_glow(ci, Vector2(lx, ly), 60.0 + 60.0 * rot * al, Color(1.0, 0.15, 0.1, 0.35 * al))
			else:
				DrawBatch.circle(ci, Vector2(lx, ly - 6.0), 5.0, Color(1.0, 0.65, 0.25, 0.7))
		# שלט
		if posmod(k, 2) == 0:
			var sx2 := bx + 670.0
			DrawBatch.rect(ci, Rect2(sx2, floor_top + 16.0, 176.0, 36.0), Color("1e2a32"))
			DrawBatch.rect(ci, Rect2(sx2, floor_top + 16.0, 176.0, 36.0), Color("8ab0c4"), false, 2.0)
			DrawBatch.string(ci, ThemeDB.fallback_font, Vector2(sx2 + 10.0, floor_top + 32.0), "PROYECTO ECHO", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("c8e4f0"))
			DrawBatch.string(ci, ThemeDB.fallback_font, Vector2(sx2 + 10.0, floor_top + 46.0), "NIVEL 2 - ACCESO RESTRINGIDO", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color(1.0, 0.55, 0.4, 0.85))


# ---- צינורות ענק, תעלות בתקרה, פלורסנטים, נטיפים, חוטי פטרייה, מכונות נמוכות ----
static func near_rig(ci: CanvasItem, sc: float, v: Vector2, y: float, t: float) -> void:
	var period := 760.0
	var start := int(floor(sc / period)) - 1
	var pts := PackedVector2Array()
	var cols := PackedColorArray()
	var glows := []
	for k in range(start, start + int(ceil(v.x / period)) + 2):
		var bx := float(k) * period - sc
		if bx > v.x + 40.0 or bx + period < -40.0:
			continue
		# תקרה: לוחות כהים + קורות
		U.vrect(pts, cols, Rect2(bx, 0.0, period, 46.0), Color("0e1318"), Color("1e262e"))
		for q in 4:
			U.rect(pts, cols, Rect2(bx + float(q) * 190.0, 0.0, 16.0, 64.0), Color("161c22"))
			U.rect(pts, cols, Rect2(bx + float(q) * 190.0, 60.0, 16.0, 4.0), Color("3a444e"))
		# צינור ענק עם כפור ואוגנים
		var py := 76.0
		U.vrect(pts, cols, Rect2(bx, py, period, 30.0), Color("8a98a4"), Color("38434e"))
		U.rect(pts, cols, Rect2(bx, py, period, 5.0), Color(0.92, 0.97, 1.0, 0.75))   # כפור על הצינור
		for q in 3:
			var fx := bx + 120.0 + float(q) * 250.0
			U.vrect(pts, cols, Rect2(fx, py - 5.0, 16.0, 40.0), Color("9aa8b4"), Color("4a5560"))
			for s in 4:   # נטיפי קרח
				var ix := fx - 30.0 + float(s) * 22.0 + _h(k * 13 + q * 4 + s, 40) * 10.0
				var il := 10.0 + _h(k * 13 + q * 4 + s, 41) * 24.0
				U.tri(pts, cols, Vector2(ix - 3.0, py + 30.0), Vector2(ix + 3.0, py + 30.0), Vector2(ix, py + 30.0 + il), Color(0.85, 0.95, 1.0, 0.8))
		# צינור דק שני + מגש כבלים
		U.vrect(pts, cols, Rect2(bx, py + 42.0, period, 10.0), Color("6a5444"), Color("3a2c22"))
		for q in 8:
			var cx := bx + float(q) * 95.0
			var sag := 10.0 + _h(k * 8 + q, 42) * 10.0
			var cc := [Color("1a1a1a"), Color("7a1a1a"), Color("1a3a6a")][q % 3] as Color
			var prev := Vector2(cx, py + 56.0)
			for s in range(1, 6):
				var u := float(s) / 5.0
				var p := Vector2(cx + u * 95.0, py + 56.0 + sin(u * PI) * sag)
				U.seg(pts, cols, prev, p, 2.0, cc)
				prev = p
		# צינור יורד אל הרצפה עם שסתום
		var vx := bx + 520.0
		U.vrect(pts, cols, Rect2(vx, py + 30.0, 18.0, y - py - 30.0), Color("6e7c88"), Color("4a5560"))
		U.rect(pts, cols, Rect2(vx - 2.0, py + 30.0, 22.0, 6.0), Color(0.92, 0.97, 1.0, 0.6))
		U.oval(pts, cols, Vector2(vx + 9.0, y - 120.0), 13.0, 13.0, Color("8a2a24"), 12)
		U.oval(pts, cols, Vector2(vx + 9.0, y - 120.0), 5.0, 5.0, Color("4a1a14"), 8)
		# מכונות נמוכות מאחורי הדרך (גנרטור / יחידת קירור) עם נוריות
		var mx := bx + 140.0 + _h(k, 43) * 160.0
		var mw := 120.0 + _h(k, 44) * 70.0
		U.vrect(pts, cols, Rect2(mx, y - 70.0, mw, 70.0), Color("4a5662"), Color("2e363e"))
		U.rect(pts, cols, Rect2(mx, y - 70.0, mw, 3.0), Color(0.9, 0.96, 1.0, 0.6))
		for q in int(mw / 14.0):
			U.rect(pts, cols, Rect2(mx + 8.0 + float(q) * 14.0, y - 56.0, 8.0, 26.0), Color("232a30"))
		var led := 0.5 + 0.5 * sin(t * 4.0 + float(k))
		U.rect(pts, cols, Rect2(mx + mw - 18.0, y - 64.0, 6.0, 4.0), Color(0.3, 1.0, 0.5, 0.4 + 0.6 * led))
		U.rect(pts, cols, Rect2(mx + mw - 28.0, y - 64.0, 6.0, 4.0), Color(1.0, 0.3, 0.2, 0.9 - 0.6 * led))
		# חוטי פטרייה תלויים מהתקרה
		for q in 5:
			var hx := bx + 40.0 + float(q) * 150.0 + _h(k * 5 + q, 45) * 40.0
			var hl := 40.0 + _h(k * 5 + q, 46) * 90.0
			var sw := sin(t * 1.1 + float(q + k)) * 6.0
			var pulse := 0.5 + 0.5 * sin(t * 3.2 - (sc + hx) * 0.012)
			U.seg(pts, cols, Vector2(hx, 106.0), Vector2(hx + sw, 106.0 + hl), 2.0, ECHO_D.lerp(ECHO_M, pulse))
			U.oval(pts, cols, Vector2(hx + sw, 106.0 + hl), 3.0 + 2.0 * pulse, 3.0 + 2.0 * pulse, Color(ECHO, 0.5 + 0.4 * pulse), 6)
		# פלורסנטים תלויים (חלקם מהבהבים, אחד מת)
		for q in 2:
			var fx2 := bx + 230.0 + float(q) * 360.0
			var fl := 1.0
			var id := k * 2 + q
			if posmod(id, 5) == 3:
				fl = 0.0
			elif posmod(id, 4) == 1:
				fl = 1.0 if sin(t * 23.0 + float(id)) > -0.2 and fposmod(t + float(id), 3.1) > 0.25 else 0.15
			U.seg(pts, cols, Vector2(fx2 - 40.0, 46.0), Vector2(fx2 - 40.0, 140.0), 1.2, Color("1a1e22"))
			U.seg(pts, cols, Vector2(fx2 + 40.0, 46.0), Vector2(fx2 + 40.0, 140.0), 1.2, Color("1a1e22"))
			U.rect(pts, cols, Rect2(fx2 - 46.0, 140.0, 92.0, 8.0), Color("2a3036"))
			U.rect(pts, cols, Rect2(fx2 - 42.0, 146.0, 84.0, 3.0), Color(0.85, 0.95, 1.0, 0.25 + 0.75 * fl))
			if fl > 0.5:
				glows.append(Vector2(fx2, 150.0))
	U.flush(ci, pts, cols)
	for g: Vector2 in glows:
		Kit.soft_glow(ci, g + Vector2(0, 20.0), 110.0, Color(0.75, 0.9, 1.0, 0.16), 0.5)
	DrawBatch.rect(ci, Rect2(0, y + 6.0, v.x, v.y - y), Color("1a2026"))


# אובך קר מאחורי הדמויות + צל התקרה
static func lab_overlay(ci: CanvasItem, v: Vector2, t: float) -> void:
	Kit.haze_band(ci, v, 420.0, 614.0, Color(0.55, 0.74, 0.86, 0.22))
	DrawBatch.polygon(ci, PackedVector2Array([Vector2(0, 0), Vector2(v.x, 0), Vector2(v.x, 120.0), Vector2(0, 120.0)]),
		PackedColorArray([Color(0, 0, 0, 0.45), Color(0, 0, 0, 0.45), Color(0, 0, 0, 0.0), Color(0, 0, 0, 0.0)]))
	for i in 4:   # אדי קור שזוחלים על הרצפה
		var mx := fposmod(float(i) * 340.0 + t * (14.0 + float(i) * 4.0), v.x + 600.0) - 300.0
		Kit.soft_glow(ci, Vector2(mx, 590.0 + float(i % 2) * 14.0), 230.0, Color(0.8, 0.92, 1.0, 0.07), 0.22)


# ============================================================
#  עולם
# ============================================================

# ---- רצפת פלדה מחוררת: כפור, כתמי קרח, פסי סכנה, פטרייה זוחלת. snow = רצפת הכניסה (שלג וקרח) ----
class LabGround extends Node2D:
	var w := 1024.0
	var depth := 90.0
	var seed_v := 0
	var snow := 0.0          # 0..1: כמה שלג (הכניסה מהקרחון)
	var wx := 0.0            # x בעולם (לעובי הפטרייה)

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
		U.rect(pts, cols, Rect2(0, 0, w, depth), Color("161c22"))
		U.vrect(pts, cols, Rect2(0, 0, w, 16.0), Color("6a7884"), Color("46525e"))
		U.rect(pts, cols, Rect2(0, 0, w, 1.6), Color(0.9, 0.97, 1.0, 0.7))
		U.rect(pts, cols, Rect2(0, 16.0, w, 5.0), Color("232b33"))
		# לוחות מחוררים: תפרים + שורות חורים
		var x := 0.0
		while x < w:
			U.rect(pts, cols, Rect2(x, 1.0, 1.6, 15.0), Color(0.12, 0.15, 0.18, 0.8))
			for q in 6:
				for s in 2:
					U.rect(pts, cols, Rect2(x + 8.0 + float(q) * 10.0, 5.0 + float(s) * 5.0, 4.0, 2.0), Color(0.1, 0.12, 0.15, 0.7))
			x += 80.0
		# קורות מתחת לרצפה
		for q in int(w / 128.0) + 1:
			U.rect(pts, cols, Rect2(float(q) * 128.0, 21.0, 10.0, depth - 21.0), Color("20272e"))
		# כפור + כתמי קרח (יותר בכניסה)
		for i in int(w / (40.0 - 26.0 * snow)):
			var p := Vector2(r.randf_range(0.0, w), r.randf_range(1.0, 6.0))
			U.oval(pts, cols, p, r.randf_range(10.0, 34.0) * (1.0 + snow), r.randf_range(1.0, 2.4), Color(0.86, 0.95, 1.0, 0.35 + 0.4 * snow), 8)
		if snow > 0.0:   # שלג נערם על הרצפה
			var prev := Vector2(0, 2.0)
			for q in int(w / 32.0) + 1:
				var p := Vector2(float(q) * 32.0, -r.randf_range(0.0, 7.0) * snow)
				U.quad(pts, cols, prev, p, Vector2(p.x, 6.0), Vector2(prev.x, 6.0), Color("f2f8fc"), Color("f2f8fc"), Color("cfe2ec"), Color("cfe2ec"))
				prev = p
		# פסי סכנה בקצוות הלוחות (פה ושם)
		for i in int(w / 300.0):
			var hx := r.randf_range(20.0, w - 80.0)
			for q in 5:
				U.quad(pts, cols, Vector2(hx + float(q) * 12.0, 0.0), Vector2(hx + float(q) * 12.0 + 6.0, 0.0), Vector2(hx + float(q) * 12.0 + 2.0, 6.0), Vector2(hx + float(q) * 12.0 - 4.0, 6.0), Color(HAZ, 0.55), Color(HAZ, 0.55), Color(HAZ, 0.55), Color(HAZ, 0.55))
		# פטרייה זוחלת על הרצפה (עבה יותר ככל שמעמיקים ימינה)
		var thick := clampf((wx - 2500.0) / 7000.0, 0.0, 1.0)
		for i in int(w / 70.0 * thick):
			var p := Vector2(r.randf_range(0.0, w), r.randf_range(-1.0, 3.0))
			var ln := r.randf_range(20.0, 60.0)
			U.seg(pts, cols, p, p + Vector2(ln, r.randf_range(-2.0, 2.0)), r.randf_range(1.5, 3.5), Color(ECHO_D, 0.85))
			U.oval(pts, cols, p + Vector2(ln, 0), 2.5, 2.0, Color(ECHO_M, 0.9), 6)
		# דם קפוא / נוזל מיכלים שנשפך
		for i in int(w / 260.0):
			var p := Vector2(r.randf_range(0.0, w), r.randf_range(3.0, 8.0))
			U.oval(pts, cols, p, r.randf_range(10.0, 26.0), r.randf_range(1.6, 2.8), Color(0.35, 0.03, 0.05, 0.55) if i % 2 == 0 else Color(0.3, 0.7, 0.8, 0.3), 8)
		U.flush(self, pts, cols)


# ---- פתח המנהרה בקרחון + שער התחנה ----
class Entrance extends Node2D:
	var _t := 0.0

	func _ready() -> void:
		z_index = -3

	func _process(delta: float) -> void:
		_t += delta
		if Engine.get_process_frames() % 3 == 0 and Art.on_screen(self, global_position + Vector2(300, -200), 500.0):
			queue_redraw()

	func _draw() -> void:
		DrawBatch.begin(self)
		_draw_b()
		DrawBatch.end(self)

	func _draw_b() -> void:
		var pts := PackedVector2Array()
		var cols := PackedColorArray()
		# קשת המנהרה: קרח עבה (מתחיל משמאל למסך)
		U.vrect(pts, cols, Rect2(-260.0, -700.0, 560.0, 700.0), Color("2a6a8c"), Color("4a90b0"))
		for q in 9:
			var yy := -640.0 + float(q) * 72.0
			U.seg(pts, cols, Vector2(-260.0, yy), Vector2(300.0, yy + 20.0 + U.h(q, 1) * 20.0), 2.0, Color(0.75, 0.95, 1.0, 0.25))
		for q in 14:   # נטיפים ענקיים מתקרת המנהרה
			var ix := -240.0 + float(q) * 40.0
			var il := 30.0 + U.h(q, 2) * 70.0
			U.tri(pts, cols, Vector2(ix - 8.0, -560.0), Vector2(ix + 8.0, -560.0), Vector2(ix, -560.0 + il), Color(0.85, 0.96, 1.0, 0.85))
		# שער התחנה: מסגרת פלדה עבה בתוך הקרח
		var gx := 300.0
		U.vrect(pts, cols, Rect2(gx, -460.0, 60.0, 460.0), Color("5a6672"), Color("343e48"))
		U.vrect(pts, cols, Rect2(gx + 360.0, -460.0, 60.0, 460.0), Color("5a6672"), Color("343e48"))
		U.vrect(pts, cols, Rect2(gx, -500.0, 420.0, 60.0), Color("6a7884"), Color("3e4a56"))
		U.rect(pts, cols, Rect2(gx, -500.0, 420.0, 4.0), Color(0.92, 0.97, 1.0, 0.8))
		for q in 14:   # פסי סכנה על המשקוף
			var xx := gx + 10.0 + float(q) * 29.0
			U.quad(pts, cols, Vector2(xx, -452.0), Vector2(xx + 14.0, -452.0), Vector2(xx + 6.0, -444.0), Vector2(xx - 8.0, -444.0), HAZ, HAZ, HAZ, HAZ)
		# דלת השער: פתוחה (נגררה הצידה), קרועה ממכה מבפנים
		U.vrect(pts, cols, Rect2(gx + 60.0, -440.0, 70.0, 440.0), Color("4a5560"), Color("2a3038"))
		U.tri(pts, cols, Vector2(gx + 130.0, -300.0), Vector2(gx + 160.0, -260.0), Vector2(gx + 130.0, -200.0), Color("2a3038"))
		for q in 3:
			U.seg(pts, cols, Vector2(gx + 128.0, -280.0 + float(q) * 18.0), Vector2(gx + 152.0, -262.0 + float(q) * 12.0), 2.0, Color("9aa8b4"))
		# שלג שנערם בשער + עקבות גרירה בדם
		U.quad(pts, cols, Vector2(-260.0, 0), Vector2(-260.0, -40.0), Vector2(200.0, -14.0), Vector2(420.0, 0), Color("eef6fa"), Color("f8fcfe"), Color("e6f0f6"), Color("dce8ee"))
		for q in 5:
			U.oval(pts, cols, Vector2(360.0 + float(q) * 34.0, -2.0), 9.0, 2.0, Color(0.45, 0.05, 0.06, 0.5), 8)
		U.flush(self, pts, cols)
		# מנורת אזהרה + שלט
		var blink := 0.5 + 0.5 * sin(_t * 3.0)
		DrawBatch.circle(self, Vector2(gx + 210.0, -520.0), 7.0, Color(1.0, 0.6, 0.2, 0.5 + 0.5 * blink))
		Kit.soft_glow(self, Vector2(gx + 210.0, -520.0), 50.0, Color(1.0, 0.55, 0.2, 0.3 * blink))
		DrawBatch.rect(self, Rect2(gx + 74.0, -430.0, 272.0, 50.0), Color("1a242c"))
		DrawBatch.rect(self, Rect2(gx + 74.0, -430.0, 272.0, 50.0), Color("9ab8c8"), false, 2.0)
		DrawBatch.string(self, ThemeDB.fallback_font, Vector2(gx + 86.0, -410.0), "ESTACION GLACIAR ECHO", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("d8eef8"))
		DrawBatch.string(self, ThemeDB.fallback_font, Vector2(gx + 86.0, -392.0), "PROYECTO ECHO - PERSONAL AUTORIZADO", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(1.0, 0.5, 0.4, 0.9))


# ============================================================
#  דלת הדף ענקית בין האגפים (מוצקה כשהיא סגורה). השלב (levels/stage_60.gd) מחליט מתי היא נטרקת / נפתחת.
#  inside = לאיזה צד נמצא האגף שהיא נועלת (-1 שמאל, 1 ימין) - שם לוח האזעקה, ולשם נדחף השחקן אם הוא מתחתיה.
# ============================================================
class BlastDoor extends Node2D:
	const W := 44.0
	const H := 680.0                # מהרצפה עד מעל המסך: אי אפשר לקפוץ מעליה
	const CLOSE_T := 0.55
	const OPEN_T := 1.1
	const PANEL_DX := 52.0          # לוח האזעקה / קורא הכרטיסים: כמה מהדלת לכיוון האגף
	enum {OPEN, CLOSING, SEALED, OPENING}
	var label := "A"
	var inside := 1.0
	var inside_l := true            # יש לוח גם בצד השמאלי (דלת בין שני אגפים)
	var state := OPEN
	var k := 0.0                    # 0 = פתוחה (למעלה), 1 = סגורה
	var slams := 0                  # לבדיקות
	var crushed := 0
	var card_glow := 0.0            # (השלב) יש לך כרטיס ואתה ליד: הקורא זוהר
	var _t := 0.0
	var _body: StaticBody2D = null
	var _cs: CollisionShape2D = null

	func _ready() -> void:
		z_index = 2
		add_to_group("s60_doors")
		_body = StaticBody2D.new()
		_body.collision_layer = 1
		_body.collision_mask = 0
		_body.add_to_group("no_outline")
		_cs = CollisionShape2D.new()
		var rs := RectangleShape2D.new()
		rs.size = Vector2(W, H)
		_cs.shape = rs
		_cs.position = Vector2(0, -H * 0.5)
		_cs.disabled = true
		_body.add_child(_cs)
		add_child(_body)

	func panel_x(side: float) -> float:
		return global_position.x + side * PANEL_DX

	func is_closed() -> bool:
		return state == SEALED or state == CLOSING

	func world_rect() -> Rect2:
		return Rect2(global_position + Vector2(-W * 0.5, -H), Vector2(W, H))

	func seal() -> void:
		if state == SEALED or state == CLOSING:
			return
		state = CLOSING
		slams += 1
		Sfx.play("s60_door", global_position + Vector2(0, -200), 4.0, 0.05, 2)

	func unseal() -> void:
		if state == OPEN or state == OPENING:
			return
		state = OPENING
		_cs.set_deferred("disabled", true)
		Sfx.play("s60_door_open", global_position + Vector2(0, -200), 2.0, 0.05, 2)

	func _process(delta: float) -> void:
		_t += delta
		match state:
			CLOSING:
				k = minf(1.0, k + delta / CLOSE_T * (0.4 + 1.6 * k))   # מאיצה למטה
				if k >= 0.65 and _cs.disabled:
					_crush()
					_cs.set_deferred("disabled", false)
				if k >= 1.0:
					state = SEALED
					Sfx.play("s60_slam", global_position, 6.0, 0.05, 2)
					Particles.burst(get_parent(), global_position + Vector2(0, -6), "smoke", Vector2.UP, 8)
					Particles.burst(get_parent(), global_position + Vector2(0, -4), "snow", Vector2.UP, 8)
					var cam := get_viewport().get_camera_2d()
					if cam != null and cam.has_method("shake") and Art.on_screen(self, global_position, 200.0):
						cam.shake(9.0, 0.35)
			OPENING:
				k = maxf(0.0, k - delta / OPEN_T)
				if k <= 0.0:
					state = OPEN
		card_glow = move_toward(card_glow, 0.0, delta * 2.0)
		if Art.on_screen(self, global_position + Vector2(0, -250), 300.0) and (state == CLOSING or state == OPENING or Engine.get_process_frames() % 3 == 0):
			queue_redraw()

	# הדלת נוחתת: השחקן מתחתיה נדחף לתוך האגף, זומבים מתחתיה נמעכים
	func _crush() -> void:
		var r := world_rect().grow_individual(4.0, 0.0, 4.0, 0.0)
		var pl := get_tree().get_first_node_in_group("player") as Node2D
		if pl != null and not pl.dead and r.intersects(pl.body_rect()):
			pl.global_position.x = global_position.x + inside * (W * 0.5 + 18.0)
			pl.reset_physics_interpolation()
		for z in get_tree().get_nodes_in_group("zombies"):
			if z.dead or z.is_boss():
				continue
			var zr := Rect2(z.global_position + Vector2(-14.0, -50.0 * z.sc), Vector2(28.0, 50.0 * z.sc))
			if r.intersects(zr):
				crushed += 1
				z._popup("CRUSHED", Color("ff7060"), 16, -80.0)
				z.take_damage(999, z.global_position + Vector2(0, -24), Vector2.DOWN, true, {"source": "hazard", "fixed": 999})

	func _draw() -> void:
		DrawBatch.begin(self)
		_draw_b()
		DrawBatch.end(self)

	func _draw_b() -> void:
		var pts := PackedVector2Array()
		var cols := PackedColorArray()
		var al: float = U.alarm
		# מסגרת: עמודים עבים משני הצדדים + בית הדלת למעלה
		for s: float in [-1.0, 1.0]:
			var fx := s * (W * 0.5 + 9.0)
			U.vrect(pts, cols, Rect2(fx - 9.0, -H, 18.0, H), Color("5a6672"), Color("38424c"))
			U.rect(pts, cols, Rect2(fx - 9.0 + (12.0 if s > 0.0 else 0.0), -H, 6.0, H), Color(0.0, 0.0, 0.0, 0.25))
			var yy := -40.0
			while yy > -H + 20.0:   # מסמרות
				U.dia(pts, cols, Vector2(fx, yy), 1.8, Color(0.72, 0.8, 0.86, 0.8))
				yy -= 46.0
		U.vrect(pts, cols, Rect2(-W * 0.5 - 18.0, -H + 120.0, W + 36.0, 60.0), Color("6a7884"), Color("3a4550"))
		# הלוח עצמו: יורד מבית הדלת (k)
		var drop := (1.0 - k) * 560.0
		var top := -H + 180.0 - drop
		var bot := 0.0 - drop
		if bot > top:
			U.vrect(pts, cols, Rect2(-W * 0.5, top, W, bot - top), Color("56626e"), Color("3e4852"))
			var yy := top + 30.0
			while yy < bot - 20.0:   # צלעות חיזוק
				U.rect(pts, cols, Rect2(-W * 0.5, yy, W, 5.0), Color("2e363e"))
				U.rect(pts, cols, Rect2(-W * 0.5, yy, W, 1.5), Color(0.8, 0.88, 0.94, 0.4))
				yy += 64.0
			for q in 6:   # שברונים צהוב-שחור בתחתית הלוח
				var cy := bot - 40.0
				var cx := -W * 0.5 + float(q) * 8.0
				U.quad(pts, cols, Vector2(cx, cy), Vector2(cx + 4.0, cy), Vector2(cx + 4.0 + 6.0, cy + 34.0), Vector2(cx + 6.0, cy + 34.0), HAZ, HAZ, HAZ, HAZ)
			U.rect(pts, cols, Rect2(-W * 0.5, bot - 6.0, W, 6.0), Color("22282e"))
			U.rect(pts, cols, Rect2(-8.0, bot - 120.0, 16.0, 30.0), Color("16303a"))   # צוהר צר עם כפור
			U.rect(pts, cols, Rect2(-8.0, bot - 120.0, 16.0, 8.0), Color(0.9, 0.97, 1.0, 0.5))
			# כפור בפינות + פטרייה שמנסה לחדור בתפר (עבה יותר ימינה)
			U.tri(pts, cols, Vector2(-W * 0.5, bot - 6.0), Vector2(-W * 0.5 + 18.0, bot - 6.0), Vector2(-W * 0.5, bot - 30.0), Color(0.9, 0.97, 1.0, 0.5))
		# לוח אזעקה + קורא כרטיסים בצד האגף (ובצד השני אם יש)
		for s: float in ([inside, -inside] if inside_l else [inside]):
			var px := s * PANEL_DX
			U.rect(pts, cols, Rect2(px - 11.0, -112.0, 22.0, 34.0), Color("20262c"))
			U.rect(pts, cols, Rect2(px - 9.0, -110.0, 18.0, 12.0), Color("0e1a20"))
			var sealed := state == SEALED or state == CLOSING
			var lc := Color(1.0, 0.2, 0.15) if sealed else Color(0.3, 1.0, 0.45)
			var bl := 1.0 if not sealed else (0.4 + 0.6 * float(int(_t * 4.0) % 2))
			U.rect(pts, cols, Rect2(px - 6.0, -107.0, 12.0, 6.0), Color(lc, bl))
			U.rect(pts, cols, Rect2(px - 7.0, -92.0, 14.0, 3.0), Color("6a7884"))   # חריץ הכרטיס
			U.vrect(pts, cols, Rect2(px - 4.0, -86.0, 8.0, 6.0), Color(HAZ, 0.9), Color(HAZ.darkened(0.4), 0.9))   # כפתור האזעקה
		U.flush(self, pts, cols)
		# משואה אדומה מעל הדלת
		var bpos := Vector2(0, -H + 108.0)
		DrawBatch.rect(self, Rect2(bpos.x - 10.0, bpos.y - 2.0, 20.0, 8.0), Color("2a3038"))
		if is_closed() or al > 0.05:
			var rot := fmod(_t * 5.0, TAU)
			DrawBatch.circle(self, bpos + Vector2(0, -6.0), 7.0, Color(1.0, 0.2, 0.15))
			var dir := Vector2(cos(rot), sin(rot) * 0.35)
			DrawBatch.polygon(self, PackedVector2Array([bpos + Vector2(0, -6), bpos + Vector2(0, -6) + dir * 220.0 + dir.orthogonal() * 40.0, bpos + Vector2(0, -6) + dir * 220.0 - dir.orthogonal() * 40.0]),
				PackedColorArray([Color(1.0, 0.2, 0.1, 0.35), Color(1.0, 0.2, 0.1, 0.0), Color(1.0, 0.2, 0.1, 0.0)]))
			Kit.soft_glow(self, bpos + Vector2(0, -6.0), 46.0, Color(1.0, 0.15, 0.1, 0.4))
		else:
			DrawBatch.circle(self, bpos + Vector2(0, -6.0), 6.0, Color(0.35, 0.9, 0.45, 0.8))
		if card_glow > 0.0:
			Kit.soft_glow(self, Vector2(inside * PANEL_DX, -92.0), 30.0, Color(0.6, 1.0, 0.7, 0.6 * card_glow))
		# שם האגף על בית הדלת
		DrawBatch.string(self, ThemeDB.fallback_font, Vector2(-30.0, -H + 158.0), "ALA " + label, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(1.0, 0.85, 0.3, 0.9))


# ============================================================
#  מיכל הקפאה. z = ה-SPECIMEN בפנים (enemies/types/specimen.gd), או null (קישוט).
#  thaw(): הזכוכית מתכסה סדקים ואדים (THAW_T) -> burst(): מתנפצת, ה-SPECIMEN יוצא (type_mod.release())
#  variant: 0 = קפוא עם זומבי, 1 = ריק ושלם (נוזל עכור), 2 = שבור מזמן
# ============================================================
class CryoTank extends Node2D:
	const THAW_T := 1.15
	const TUBE := Vector2(46.0, 92.0)
	const BASE_H := 22.0
	enum {FROZEN, THAW, BROKEN, EMPTY}
	var z = null
	var variant := 0
	var tag := 0                    # המספר על המיכל
	var state := FROZEN
	var thaws := 0                  # לבדיקות
	var hold_burst := false         # סצנת הסיפור: נסדק אבל לא מתנפץ עד שהבמה אומרת
	var _t := 0.0
	var _st := 0.0
	var _crack := 0.0               # 0..1
	var _glass: Node2D = null

	func _ready() -> void:
		z_index = -1
		add_to_group("s60_tanks")
		if variant == 1:
			state = EMPTY
		elif variant == 2:
			state = BROKEN
			_crack = 1.0
		_glass = TankGlass.new()
		_glass.tank = self
		add_child(_glass)
		_glass.visible = state == FROZEN or state == THAW   # ריק / שבור: המיכל מצייר את הזכוכית בעצמו

	func frozen() -> bool:
		return state == FROZEN and z != null and is_instance_valid(z) and not z.dead

	func thaw(fast := false) -> void:
		if state != FROZEN:
			return
		state = THAW
		thaws += 1
		_st = THAW_T * (0.5 if fast else 1.0)
		Sfx.play("s60_hiss", global_position + Vector2(0, -60), 0.0, 0.1, 3)

	func burst() -> void:
		if state == BROKEN:
			return
		state = BROKEN
		_crack = 1.0
		Sfx.play("glass", global_position + Vector2(0, -60), 3.0, 0.1, 3)
		Sfx.play("s60_shatter", global_position + Vector2(0, -60), 0.0, 0.1, 3)
		if Art.on_screen(self, global_position, 80.0):
			Particles.burst(get_parent(), global_position + Vector2(0, -70), "snow", Vector2.UP, 16)
			Particles.burst(get_parent(), global_position + Vector2(0, -50), "mist", Vector2.UP, 8)
		if z != null and is_instance_valid(z) and not z.dead and z.type_mod != null and z.type_mod.has_method("release"):
			z.type_mod.release()
		z = null
		_glass.visible = false
		queue_redraw()

	func _process(delta: float) -> void:
		_t += delta
		if state == THAW:
			_st -= delta
			_crack = clampf(1.0 - _st / THAW_T, 0.0, 1.0)
			if Engine.get_process_frames() % 4 == 0 and Art.on_screen(self, global_position, 60.0):
				Particles.burst(get_parent(), global_position + Vector2(randf_range(-20, 20), -TUBE.y - BASE_H + 10.0), "mist", Vector2.UP, 1)
			if _st <= 0.0:
				if hold_burst:
					_st = 0.0
					_crack = 1.0
				else:
					burst()
		elif state == FROZEN and not hold_burst and (z == null or not is_instance_valid(z) or z.dead) and variant == 0:
			burst()   # הזומבי מת בפנים (פיצוץ) - המיכל מתנפץ
		var every := 2 if state == THAW else 6
		if Engine.get_process_frames() % every == 0 and Art.on_screen(self, global_position + Vector2(0, -60), 80.0):
			queue_redraw()
			if _glass.visible:
				_glass.queue_redraw()

	func _draw() -> void:
		DrawBatch.begin(self)
		_draw_b()
		DrawBatch.end(self)

	# הבסיס, הצינורות והחלק האחורי של הצינור (מאחורי הזומבי)
	func _draw_b() -> void:
		var pts := PackedVector2Array()
		var cols := PackedColorArray()
		var tw := TUBE.x
		var th := TUBE.y
		var top := -BASE_H - th
		# צינורות מהתקרה אל המכסה
		U.rect(pts, cols, Rect2(-14.0, top - 200.0, 6.0, 200.0), Color("3a4450"))
		U.rect(pts, cols, Rect2(8.0, top - 200.0, 8.0, 200.0), Color("4a5560"))
		U.rect(pts, cols, Rect2(8.0, top - 200.0, 2.0, 200.0), Color(0.9, 0.97, 1.0, 0.5))
		# הבסיס (מכונה עם נוריות ושסתומים)
		U.vrect(pts, cols, Rect2(-tw * 0.5 - 8.0, -BASE_H, tw + 16.0, BASE_H), Color("5a6672"), Color("2e363e"))
		U.rect(pts, cols, Rect2(-tw * 0.5 - 8.0, -BASE_H, tw + 16.0, 3.0), Color(0.85, 0.94, 1.0, 0.6))
		var led := 0.5 + 0.5 * sin(_t * 3.0 + float(tag))
		var lc := Color(0.3, 0.9, 1.0) if state == FROZEN else (Color(1.0, 0.6, 0.2) if state == THAW else Color(1.0, 0.2, 0.15))
		U.rect(pts, cols, Rect2(-tw * 0.5 - 2.0, -BASE_H + 8.0, 6.0, 4.0), Color(lc, 0.5 + 0.5 * led))
		U.rect(pts, cols, Rect2(-tw * 0.5 + 8.0, -BASE_H + 8.0, 6.0, 4.0), Color(lc, 0.9 - 0.4 * led))
		U.rect(pts, cols, Rect2(tw * 0.5 - 18.0, -BASE_H + 6.0, 20.0, 9.0), Color("e8eef0"))   # תווית
		for q in 4:
			U.rect(pts, cols, Rect2(tw * 0.5 - 16.0 + float(q) * 4.5, -BASE_H + 8.0, 2.5, 5.0), Color("1a1a1a"))
		# מכסה עליון
		U.vrect(pts, cols, Rect2(-tw * 0.5 - 6.0, top - 14.0, tw + 12.0, 14.0), Color("6a7884"), Color("3a4550"))
		U.rect(pts, cols, Rect2(-tw * 0.5 - 6.0, top - 14.0, tw + 12.0, 3.0), Color(0.92, 0.97, 1.0, 0.7))
		# הצד האחורי של הצינור: נוזל כחול זוהר (קפוא) / ריק
		match state:
			FROZEN, THAW:
				U.vrect(pts, cols, Rect2(-tw * 0.5, top, tw, th), Color(0.35, 0.8, 0.95, 0.5), Color(0.2, 0.55, 0.8, 0.6))
			EMPTY:
				U.vrect(pts, cols, Rect2(-tw * 0.5, top, tw, th), Color(0.3, 0.45, 0.4, 0.45), Color(0.25, 0.4, 0.3, 0.7))
				U.oval(pts, cols, Vector2(0, top + th * 0.55), 9.0, 11.0, Color(0.5, 0.4, 0.35, 0.55), 8)   # משהו צף בנוזל
				U.seg(pts, cols, Vector2(0, top + th * 0.55), Vector2(4.0, top + th * 0.9), 2.0, Color(ECHO_M, 0.6))
			BROKEN:
				U.rect(pts, cols, Rect2(-tw * 0.5, top, tw, th), Color(0.08, 0.12, 0.15, 0.55))
				U.oval(pts, cols, Vector2(0, -2.0), tw * 1.1, 4.0, Color(0.3, 0.7, 0.85, 0.35), 10)   # נוזל ההקפאה על הרצפה
				U.seg(pts, cols, Vector2(-tw * 0.5 + 4.0, top + 20.0), Vector2(-6.0, top + 60.0), 2.0, Color(0.15, 0.2, 0.2, 0.8))   # רצועות קרועות
				U.seg(pts, cols, Vector2(tw * 0.5 - 4.0, top + 26.0), Vector2(8.0, top + 50.0), 2.0, Color(0.15, 0.2, 0.2, 0.8))
		if not _glass.visible:
			TankGlass.glass(pts, cols, self)
		U.flush(self, pts, cols)
		if state == FROZEN or state == THAW:
			Kit.soft_glow(self, Vector2(0, top + th * 0.5), 60.0, Color(0.4, 0.85, 1.0, 0.22))


# הזכוכית של המיכל מקדימה (z מעל הזומבי): כפור, סדקים, השתקפות, ושברים אחרי שהתנפץ
class TankGlass extends Node2D:
	var tank = null

	func _ready() -> void:
		z_index = 5
		z_as_relative = false

	func _draw() -> void:
		DrawBatch.begin(self)
		_draw_b()
		DrawBatch.end(self)

	func _draw_b() -> void:
		if tank == null:
			return
		var pts := PackedVector2Array()
		var cols := PackedColorArray()
		glass(pts, cols, tank)
		U.flush(self, pts, cols)

	# (גם המיכל עצמו מצייר את זה כשאין אף אחד בפנים - בלי צומת נוסף = draw call אחד פחות)
	static func glass(pts: PackedVector2Array, cols: PackedColorArray, tank) -> void:
		var tw: float = tank.TUBE.x
		var th: float = tank.TUBE.y
		var top: float = -tank.BASE_H - th
		var cr: float = tank._crack
		var st: int = tank.state
		if st != tank.BROKEN:
			# זכוכית + כפור מלמטה (נמס כשמפשיר)
			U.rect(pts, cols, Rect2(-tw * 0.5, top, tw, th), Color(0.75, 0.92, 1.0, 0.1))
			var fr := (1.0 - cr) if st != tank.EMPTY else 0.4
			U.vrect(pts, cols, Rect2(-tw * 0.5, top + th * (1.0 - 0.55 * fr), tw, th * 0.55 * fr), Color(0.92, 0.98, 1.0, 0.0), Color(0.92, 0.98, 1.0, 0.75 * fr))
			U.quad(pts, cols, Vector2(-tw * 0.5 + 5.0, top), Vector2(-tw * 0.5 + 12.0, top), Vector2(-tw * 0.5 + 12.0, top + th), Vector2(-tw * 0.5 + 5.0, top + th), Color(1, 1, 1, 0.3), Color(1, 1, 1, 0.1), Color(1, 1, 1, 0.1), Color(1, 1, 1, 0.3))
			U.rect(pts, cols, Rect2(-tw * 0.5 - 3.0, top, 3.0, th), Color("4a5560"))
			U.rect(pts, cols, Rect2(tw * 0.5, top, 3.0, th), Color("4a5560"))
			# סדקים שמתפשטים מהמרכז
			if cr > 0.0:
				var c := Vector2(4.0, top + th * 0.45)
				for q in 7:
					var a := float(q) / 7.0 * TAU + 0.4
					var p := c
					var n := int(1.0 + cr * 4.0)
					for s in n:
						var p2 := p + Vector2.from_angle(a + sin(float(q * 3 + s)) * 0.5) * (6.0 + 4.0 * cr)
						p2.x = clampf(p2.x, -tw * 0.5, tw * 0.5)
						p2.y = clampf(p2.y, top, top + th)
						U.seg(pts, cols, p, p2, 1.0, Color(1, 1, 1, 0.75))
						p = p2
		else:
			# שברי זכוכית שנשארו במסגרת
			U.tri(pts, cols, Vector2(-tw * 0.5, top), Vector2(-tw * 0.5 + 14.0, top), Vector2(-tw * 0.5, top + 30.0), Color(0.8, 0.95, 1.0, 0.45))
			U.tri(pts, cols, Vector2(tw * 0.5, top), Vector2(tw * 0.5 - 10.0, top), Vector2(tw * 0.5, top + 22.0), Color(0.8, 0.95, 1.0, 0.4))
			U.tri(pts, cols, Vector2(-tw * 0.5, top + th), Vector2(-tw * 0.5 + 16.0, top + th), Vector2(-tw * 0.5, top + th - 34.0), Color(0.8, 0.95, 1.0, 0.45))
			U.tri(pts, cols, Vector2(tw * 0.5, top + th), Vector2(tw * 0.5 - 12.0, top + th), Vector2(tw * 0.5, top + th - 18.0), Color(0.8, 0.95, 1.0, 0.4))
			U.rect(pts, cols, Rect2(-tw * 0.5 - 3.0, top, 3.0, th), Color("4a5560"))
			U.rect(pts, cols, Rect2(tw * 0.5, top, 3.0, th), Color("4a5560"))
			for q in 6:   # רסיסים על הרצפה
				var gx := -tw * 0.9 + float(q) * tw * 0.36
				U.tri(pts, cols, Vector2(gx, -1.0), Vector2(gx + 5.0, -1.0), Vector2(gx + 2.0, -4.0 - float(q % 3)), Color(0.85, 0.96, 1.0, 0.7))


# ---- מדפי צנצנות דגימה: איברים, מוחות ועוברים בנוזל עכור עם חוטי פטרייה ----
class JarShelf extends Node2D:
	var w := 220.0
	var seed_v := 0
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
		var r := RandomNumberGenerator.new()
		r.seed = seed_v
		var pts := PackedVector2Array()
		var cols := PackedColorArray()
		U.rect(pts, cols, Rect2(0, -250.0, w, 250.0), Color("1c2228"))
		U.rect(pts, cols, Rect2(0, -250.0, 6.0, 250.0), Color("4a5560"))
		U.rect(pts, cols, Rect2(w - 6.0, -250.0, 6.0, 250.0), Color("4a5560"))
		for row in 3:
			var sy := -20.0 - float(row) * 78.0
			U.vrect(pts, cols, Rect2(0, sy, w, 6.0), Color("7a8894"), Color("4a5560"))
			var x := 14.0
			while x < w - 26.0:
				var jw := r.randf_range(22.0, 34.0)
				var jh := r.randf_range(34.0, 58.0)
				var fl := [Color(0.75, 0.7, 0.35, 0.55), Color(0.45, 0.65, 0.5, 0.55), Color(0.7, 0.45, 0.4, 0.5), Color(0.5, 0.7, 0.8, 0.45)][r.randi() % 4] as Color
				var c := Vector2(x + jw * 0.5, sy - jh * 0.5)
				var broken := r.randf() < 0.12
				if broken:   # צנצנת שבורה: רק התחתית, נוזל זלג מהמדף
					U.rect(pts, cols, Rect2(x, sy - jh * 0.3, jw, jh * 0.3), Color(fl, 0.4))
					U.tri(pts, cols, Vector2(x, sy - jh * 0.3), Vector2(x + 6.0, sy - jh * 0.6), Vector2(x + 10.0, sy - jh * 0.3), Color(0.85, 0.95, 1.0, 0.4))
					U.seg(pts, cols, Vector2(x + jw * 0.5, sy + 6.0), Vector2(x + jw * 0.5, sy + 30.0), 2.0, Color(fl, 0.5))
				else:
					U.vrect(pts, cols, Rect2(x, sy - jh, jw, jh), Color(fl, fl.a * 0.7), fl)
					var sp := r.randi() % 4
					var bob := sin(_t * 0.8 + float(row * 7) + x * 0.1) * 1.5
					match sp:
						0:   # מוח עם חוטי ECHO
							U.oval(pts, cols, c + Vector2(0, bob), jw * 0.3, jh * 0.2, Color("c89a90"), 10)
							U.seg(pts, cols, c + Vector2(-jw * 0.2, bob), c + Vector2(jw * 0.2, bob + 1.0), 1.0, Color(0.5, 0.3, 0.3))
							U.seg(pts, cols, c + Vector2(0, jh * 0.15 + bob), c + Vector2(r.randf_range(-6, 6), jh * 0.45), 1.2, Color(ECHO, 0.8))
						1:   # עובר מכורבל
							U.oval(pts, cols, c + Vector2(0, bob), jw * 0.26, jh * 0.26, Color("d8b8a8"), 10)
							U.oval(pts, cols, c + Vector2(jw * 0.08, -jh * 0.14 + bob), jw * 0.16, jw * 0.16, Color("e0c4b4"), 8)
						2:   # עין / איבר עם פטרייה
							U.oval(pts, cols, c + Vector2(0, bob), jw * 0.22, jw * 0.22, Color("e8e0d0"), 10)
							U.oval(pts, cols, c + Vector2(jw * 0.06, bob), jw * 0.1, jw * 0.1, Color("3a6a3a"), 8)
						_:   # יד
							U.seg(pts, cols, c + Vector2(0, jh * 0.3), c + Vector2(0, -jh * 0.1 + bob), 6.0, Color("c8b0a0"))
							for f in 4:
								U.seg(pts, cols, c + Vector2(0, -jh * 0.1 + bob), c + Vector2(-5.0 + float(f) * 3.5, -jh * 0.28 + bob), 1.6, Color("c8b0a0"))
					U.rect(pts, cols, Rect2(x - 2.0, sy - jh - 6.0, jw + 4.0, 6.0), Color("3a3a36"))   # מכסה
					U.rect(pts, cols, Rect2(x + 3.0, sy - jh * 0.35, jw - 6.0, 8.0), Color(0.92, 0.9, 0.82, 0.85))   # תווית
					U.rect(pts, cols, Rect2(x + 3.0, sy - jh, 3.0, jh), Color(1, 1, 1, 0.22))   # ברק
				x += jw + r.randf_range(6.0, 14.0)
		U.flush(self, pts, cols)


# ---- ארון שרתים עם נוריות, כבלים וכפור ----
class ServerRack extends Node2D:
	const GAP := 80.0
	var w := 70.0
	var hgt := 230.0
	var seed_v := 0
	var count := 1                  # כמה ארונות צמודים (צומת אחד = draw call אחד)
	var _t := 0.0

	func _ready() -> void:
		z_index = -2

	func _process(delta: float) -> void:
		_t += delta
		if Engine.get_process_frames() % 4 == 0 and Art.on_screen(self, global_position + Vector2(GAP * float(count) * 0.5, -hgt * 0.5), 100.0 + GAP * float(count - 1) * 0.5):
			queue_redraw()

	func _draw() -> void:
		DrawBatch.begin(self)
		_draw_b()
		DrawBatch.end(self)

	func _draw_b() -> void:
		var pts := PackedVector2Array()
		var cols := PackedColorArray()
		for i in count:
			var p0 := pts.size()
			var hh := hgt - float((seed_v + i * 7) % 3) * 14.0 * float(mini(i, 1))
			_rack(pts, cols, hh, seed_v + i * 131)
			for k in range(p0, pts.size()):
				pts[k].x += GAP * float(i)
		U.flush(self, pts, cols)

	func _rack(pts: PackedVector2Array, cols: PackedColorArray, rh: float, rs: int) -> void:
		U.vrect(pts, cols, Rect2(0, -rh, w, rh), Color("262e36"), Color("1a2026"))
		U.rect(pts, cols, Rect2(0, -rh, w, 3.0), Color(0.88, 0.95, 1.0, 0.6))
		U.rect(pts, cols, Rect2(0, -rh, 3.0, rh), Color("4a5560"))
		U.rect(pts, cols, Rect2(w - 3.0, -rh, 3.0, rh), Color("4a5560"))
		var units := int((rh - 20.0) / 16.0)
		for q in units:
			var uy := -rh + 10.0 + float(q) * 16.0
			U.rect(pts, cols, Rect2(6.0, uy, w - 12.0, 13.0), Color("12171c"))
			for l in 4:
				var on := U.h(rs + q * 4 + l, int(_t * (3.0 + float(l))) % 97) > 0.45
				var lc := [Color(0.3, 1.0, 0.45), Color(0.3, 0.8, 1.0), Color(1.0, 0.75, 0.2), Color(1.0, 0.25, 0.2)][(q + l) % 4] as Color
				if U.alarm > 0.1 and l == 3:
					lc = Color(1.0, 0.2, 0.15)
					on = int(_t * 4.0) % 2 == 0
				U.rect(pts, cols, Rect2(10.0 + float(l) * 5.0, uy + 5.0, 3.0, 2.5), Color(lc, 0.95 if on else 0.15))
			U.rect(pts, cols, Rect2(w - 26.0, uy + 3.0, 16.0, 7.0), Color("1e252c"))
		# כבלים שנשפכים מהגב + כפור ופטרייה למטה
		for q in 3:
			U.seg(pts, cols, Vector2(w - 6.0, -rh * (0.3 + 0.2 * float(q))), Vector2(w + 10.0 + float(q) * 6.0, 0.0), 2.4, [Color("1a1a1a"), Color("6a1a1a"), Color("1a3a6a")][q] as Color)
		U.vrect(pts, cols, Rect2(0, -26.0, w, 26.0), Color(0.9, 0.97, 1.0, 0.0), Color(0.9, 0.97, 1.0, 0.45))
		U.vein(pts, cols, Vector2(4.0, 0.0), Vector2(18.0, -70.0), 3.0, _t, global_position.x, rs)


# ---- גשר הליכה מפלדה תלוי מהתקרה (הקומה = add_floor בשלב) ----
class Catwalk extends Node2D:
	var w := 320.0
	var tier := 170.0

	func _ready() -> void:
		z_index = -1

	func _draw() -> void:
		DrawBatch.begin(self)
		_draw_b()
		DrawBatch.end(self)

	func _draw_b() -> void:
		var pts := PackedVector2Array()
		var cols := PackedColorArray()
		var y := -tier
		# מוטות תלייה לתקרה
		var x := 20.0
		while x < w:
			U.seg(pts, cols, Vector2(x, y - 30.0), Vector2(x, y - 700.0), 2.4, Color("2a3038"))
			x += 110.0
		# הדק: רשת פלדה
		U.vrect(pts, cols, Rect2(0, y, w, 10.0), Color("6a7884"), Color("3a4550"))
		U.rect(pts, cols, Rect2(0, y, w, 2.0), Color(0.9, 0.97, 1.0, 0.75))
		x = 0.0
		while x < w:
			U.seg(pts, cols, Vector2(x, y + 2.0), Vector2(x + 8.0, y + 9.0), 1.0, Color("2a3038"))
			x += 8.0
		U.rect(pts, cols, Rect2(0, y + 10.0, w, 6.0), Color("2a3038"))
		# מעקה
		U.seg(pts, cols, Vector2(0, y - 26.0), Vector2(w, y - 26.0), 3.0, HAZ.darkened(0.15))
		U.seg(pts, cols, Vector2(0, y - 13.0), Vector2(w, y - 13.0), 2.0, Color("4a5560"))
		x = 0.0
		while x <= w:
			U.seg(pts, cols, Vector2(x, y), Vector2(x, y - 26.0), 2.4, Color("4a5560"))
			x += 40.0
		# נטיפים מתחת לדק
		for q in int(w / 30.0):
			var il := 6.0 + U.h(q, 50) * 16.0
			U.tri(pts, cols, Vector2(float(q) * 30.0 + 6.0, y + 16.0), Vector2(float(q) * 30.0 + 12.0, y + 16.0), Vector2(float(q) * 30.0 + 9.0, y + 16.0 + il), Color(0.88, 0.96, 1.0, 0.75))
		U.flush(self, pts, cols)


# ============================================================
#  מסוף ארכיון התיקים (סצנת הסיפור, story/scenes/l60_file.gd): מסך גדול על זרוע + שולחן מקלדת.
#  U.file_ms -> התיק של SUBJECT ZERO מופיע שורה אחר שורה. U.welcome_ms -> הפטרייה בולעת את המסך: "WELCOME HOME"
# ============================================================
class Terminal extends Node2D:
	const LINES := ["PROYECTO ECHO // EXPEDIENTE 00", "SUBJECT ZERO", "PATTERN: ORIGINAL, UNMUTATED", "STATUS: LETHE ADMINISTERED",
		"IF THE NETWORK RECLAIMS HIM,", "EVERY MIND BECOMES ONE.", "DO NOT LET HIM GO HOME."]
	var _t := 0.0

	func _ready() -> void:
		z_index = -1

	func _process(delta: float) -> void:
		_t += delta
		var live: bool = U.file_ms >= 0 or U.welcome_ms >= 0
		if Engine.get_process_frames() % (2 if live else 5) == 0 and Art.on_screen(self, global_position + Vector2(0, -150), 200.0):
			queue_redraw()

	func _draw() -> void:
		DrawBatch.begin(self)
		_draw_b()
		DrawBatch.end(self)

	func _draw_b() -> void:
		var pts := PackedVector2Array()
		var cols := PackedColorArray()
		var sr := Rect2(-92.0, -214.0, 184.0, 96.0)   # המסך (התמונה בטור הימני)
		# זרוע מהקיר + שולחן ומקלדת
		U.rect(pts, cols, Rect2(-6.0, -260.0, 12.0, 50.0), Color("2a3038"))
		U.vrect(pts, cols, Rect2(sr.position.x - 8.0, sr.position.y - 8.0, sr.size.x + 16.0, sr.size.y + 16.0), Color("4a5560"), Color("262e36"))
		U.vrect(pts, cols, Rect2(-90.0, -58.0, 180.0, 10.0), Color("6a7884"), Color("3a4550"))
		U.rect(pts, cols, Rect2(-80.0, -48.0, 8.0, 48.0), Color("2a3038"))
		U.rect(pts, cols, Rect2(72.0, -48.0, 8.0, 48.0), Color("2a3038"))
		U.rect(pts, cols, Rect2(-50.0, -64.0, 100.0, 6.0), Color("1a2026"))
		for q in 12:
			U.rect(pts, cols, Rect2(-46.0 + float(q) * 8.0, -63.0, 6.0, 2.0), Color(0.5, 0.6, 0.65, 0.6))
		# רמקולים על הקיר (משם עונה הכוורת)
		var wt := U.since(U.welcome_ms)
		for s: float in [-1.0, 1.0]:
			var sp := Vector2(s * 120.0, -230.0)
			U.oval(pts, cols, sp, 16.0, 16.0, Color("1a2026"), 12)
			var pul := 0.0 if wt < 0.0 else (0.5 + 0.5 * sin(_t * 30.0)) * clampf(3.0 - wt, 0.0, 1.0)
			U.oval(pts, cols, sp, 11.0 + pul * 2.0, 11.0 + pul * 2.0, Color("2e363e"), 12)
			for q in 3:
				U.seg(pts, cols, sp + Vector2(-8.0, -5.0 + float(q) * 5.0), sp + Vector2(8.0, -5.0 + float(q) * 5.0), 1.2, Color("12171c"))
		# המסך: כחול כהה, קווי סריקה
		U.rect(pts, cols, sr, Color("06141c"))
		var ft := U.since(U.file_ms)
		if ft < 0.0 and wt < 0.0:   # מסך המתנה: לוגו מהבהב
			U.rect(pts, cols, Rect2(sr.position.x + 50.0, sr.position.y + 34.0, 48.0, 28.0), Color(0.3, 0.8, 1.0, 0.18 + 0.1 * sin(_t * 2.0)))
		if wt >= 0.0:   # הפטרייה בולעת את המסך
			var g := clampf(wt / 1.2, 0.0, 1.0)
			for q in int(22.0 * g):
				var a := Vector2(sr.position.x + U.h(q, 60) * sr.size.x, sr.end.y)
				var b := a + Vector2((U.h(q, 61) - 0.5) * 50.0, -sr.size.y * (0.4 + 0.6 * U.h(q, 62)) * g)
				b.x = clampf(b.x, sr.position.x, sr.end.x)
				b.y = maxf(b.y, sr.position.y)
				U.seg(pts, cols, a, b, 1.6, Color(ECHO, 0.8))
				U.oval(pts, cols, b, 2.0, 2.0, Color(ECHO, 0.9), 6)
		for q in 24:
			U.rect(pts, cols, Rect2(sr.position.x, sr.position.y + float(q) * 4.0, sr.size.x, 1.0), Color(0, 0, 0, 0.25))
		U.flush(self, pts, cols)
		# הטקסט (גודל קבוע - בלי אנימציה של גודל)
		var f := ThemeDB.fallback_font
		if ft >= 0.0 and wt < 0.0:
			var n := clampi(int(ft * 2.2) + 1, 0, LINES.size())
			for i in n:
				var col := Color(0.55, 0.9, 1.0) if i != 1 else Color(1.0, 0.85, 0.4)
				if i >= 4:
					col = Color(1.0, 0.4, 0.35)
				DrawBatch.string(self, f, Vector2(sr.position.x + 6.0, sr.position.y + 11.0 + float(i) * 12.0 + (4.0 if i >= 2 else 0.0)), String(LINES[i]), HORIZONTAL_ALIGNMENT_LEFT, -1, 8, col)
			# תמונת הגיבור בתיק (צללית במעיל שחור)
			var pc := Vector2(sr.end.x - 16.0, sr.position.y + 34.0)
			DrawBatch.rect(self, Rect2(pc.x - 12.0, pc.y - 15.0, 24.0, 30.0), Color(0.2, 0.3, 0.36))
			DrawBatch.circle(self, pc + Vector2(0, -5.0), 5.0, Color(0.05, 0.06, 0.08))
			DrawBatch.rect(self, Rect2(pc.x - 8.0, pc.y + 1.0, 16.0, 14.0), Color(0.05, 0.06, 0.08))
		elif wt >= 0.0:
			var blink := int(_t * 6.0) % 2 == 0
			if blink or wt > 1.5:
				DrawBatch.string(self, f, Vector2(sr.position.x + 34.0, sr.position.y + 54.0), "WELCOME HOME", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(ECHO, 0.95))
		if ft >= 0.0 or wt >= 0.0:
			Kit.soft_glow(self, sr.get_center(), 120.0, Color(0.3, 0.8, 1.0, 0.2) if wt < 0.0 else Color(0.6, 1.0, 0.4, 0.25), 0.7)


# ---- גידול ECHO על הקיר / הרצפה: חוטים ובלוטות שפועמים ימינה (לעומק, אל ה-ROOT) ----
class FungusPatch extends Node2D:
	var size := 1.0
	var seed_v := 0
	var wall := false               # true = על הקיר (גבוה), false = תל על הרצפה
	var _t := 0.0

	func _ready() -> void:
		z_index = -1 if wall else 2

	func _process(delta: float) -> void:
		_t += delta
		if Engine.get_process_frames() % 3 == 0 and Art.on_screen(self, global_position + Vector2(0, -60), 160.0 * size):
			queue_redraw()

	func _draw() -> void:
		DrawBatch.begin(self)
		_draw_b()
		DrawBatch.end(self)

	func _draw_b() -> void:
		var pts := PackedVector2Array()
		var cols := PackedColorArray()
		var wx := global_position.x
		var s := size
		if not wall:   # תל על הרצפה
			U.oval(pts, cols, Vector2(0, -2.0), 46.0 * s, 9.0 * s, ECHO_D, 12)
			U.oval(pts, cols, Vector2(-6.0, -6.0 * s), 30.0 * s, 8.0 * s, ECHO_D.lightened(0.08), 10)
		for q in int(9.0 * s) + 3:
			var a := Vector2((U.h(seed_v + q, 1) - 0.5) * 80.0 * s, -U.h(seed_v + q, 2) * (8.0 if not wall else 40.0) * s)
			var b := a + Vector2((U.h(seed_v + q, 3) - 0.5) * 50.0 * s, -(30.0 + U.h(seed_v + q, 4) * 120.0) * s)
			U.vein(pts, cols, a, b, 3.0 * s + 1.0, _t, wx, seed_v + q)
		for q in int(6.0 * s) + 2:   # בלוטות גדולות שפועמות
			var p := Vector2((U.h(seed_v + q, 5) - 0.5) * 70.0 * s, -(4.0 + U.h(seed_v + q, 6) * (16.0 if not wall else 120.0)) * s)
			var pulse := 0.5 + 0.5 * sin(_t * 3.2 - (wx + p.x) * 0.012 + float(q))
			var r := (4.0 + U.h(seed_v + q, 7) * 5.0) * s
			U.oval(pts, cols, p, r * (1.0 + 0.15 * pulse), r * (0.9 + 0.15 * pulse), ECHO_M.lerp(ECHO, pulse * 0.6), 10)
			U.oval(pts, cols, p + Vector2(-r * 0.3, -r * 0.3), r * 0.35, r * 0.3, Color(1, 1, 0.9, 0.35 + 0.3 * pulse), 6)
		U.flush(self, pts, cols)
		var pul := 0.5 + 0.5 * sin(_t * 3.2 - wx * 0.012)
		Kit.soft_glow(self, Vector2(0, -20.0 * s), 50.0 * s, Color(ECHO, 0.12 + 0.1 * pul))


# ============================================================
#  מלכודת: פתח חנקן נוזלי ברצפה. השחקן מתקרב (TRIG_R) -> שריקה וטבעת כפור (WARN_T) -> עמוד קור (BLAST_T):
#  השחקן נפגע (DMG) ומואט (SLOW_T), זומבים קופאים (FREEZE_T, נזק DMG_Z, meta "s60_frozen" לציור).
#  ירייה בגלגל השסתום = הפעלה מתי שרוצים (להקפיא קבוצה).
# ============================================================
class CoolantVent extends Node2D:
	const TRIG_R := 70.0
	const WARN_T := 0.85
	const BLAST_T := 1.1
	const CD := 3.2
	const HALF_W := 62.0
	const HGT := 210.0
	const DMG := 1
	const SLOW_T := 1.6
	const FREEZE_T := 2.4
	const DMG_Z := 22
	enum {IDLE, WARN, BLAST}
	var state := IDLE
	var blasts := 0                 # לבדיקות
	var hits := 0
	var frozen := 0
	var _t := 0.0
	var _st := 0.0
	var _cd := 1.0
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
		rs.size = Vector2(26, 26)
		cs.shape = rs
		_body.add_child(cs)
		_body.position = Vector2(HALF_W + 26.0, -64.0)
		add_child(_body)

	func world_rect() -> Rect2:
		return Rect2(global_position + Vector2(-HALF_W, -HGT), Vector2(HALF_W * 2.0, HGT))

	func danger_at(p: Vector2, margin := 0.0) -> bool:
		return state != IDLE and world_rect().grow(margin).has_point(p)

	func blast_rect() -> Rect2:
		return Rect2(global_position + Vector2(HALF_W + 10.0, -80.0), Vector2(32.0, 40.0))

	func hit_by_blast(_c: Vector2, _r: float) -> void:
		trigger(true)

	func trigger(quick := false) -> void:
		if state != IDLE or _cd > 0.0:
			return
		state = WARN
		_st = WARN_T * (0.5 if quick else 1.0)
		Sfx.play("s60_hiss", global_position + Vector2(0, -20), 2.0, 0.1, 2)

	func _physics_process(delta: float) -> void:
		_t += delta
		_cd -= delta
		var pl := get_tree().get_first_node_in_group("player") as Node2D
		match state:
			IDLE:
				if pl != null and not pl.dead and _cd <= 0.0 and absf(pl.global_position.x - global_position.x) < TRIG_R and absf(pl.global_position.y - global_position.y) < 40.0:
					trigger()
			WARN:
				_st -= delta
				if Engine.get_physics_frames() % 4 == 0 and Art.on_screen(self, global_position, 60.0):
					Particles.burst(get_parent(), global_position + Vector2(randf_range(-30, 30), -6), "mist", Vector2.UP, 1)
				if _st <= 0.0:
					state = BLAST
					_st = BLAST_T
					_hit = false
					_hit_z.clear()
					blasts += 1
					Sfx.play("s60_vent", global_position + Vector2(0, -60), 4.0, 0.1, 2)
			BLAST:
				_st -= delta
				_check(pl)
				if Engine.get_physics_frames() % 2 == 0 and Art.on_screen(self, global_position, 80.0):
					Particles.burst(get_parent(), global_position + Vector2(randf_range(-HALF_W, HALF_W) * 0.6, -randf_range(10, 120)), "mist", Vector2.UP, 2)
					if Quality.particles() > 0.5:
						Particles.burst(get_parent(), global_position + Vector2(randf_range(-20, 20), -40), "snow", Vector2.UP, 2)
				if _st <= 0.0:
					state = IDLE
					_cd = CD
		if Art.on_screen(self, global_position + Vector2(0, -80), 160.0) and (state != IDLE or Engine.get_physics_frames() % 4 == 0):
			queue_redraw()

	func _check(pl: Node2D) -> void:
		var r := world_rect()
		if pl != null and not pl.dead and not _hit and r.intersects(pl.body_rect()):
			_hit = true
			hits += 1
			pl.hurt(DMG, Vector2(signf(pl.global_position.x - global_position.x + 0.01) * 0.6, -0.8))
			pl.slow_t = maxf(pl.slow_t, SLOW_T)
			if not _said and pl.has_method("_say"):
				_said = true
				pl._say("LIQUID NITROGEN - DON'T STAND ON THE VENTS", Color("bfe8ff"))
		for z in get_tree().get_nodes_in_group("zombies"):
			if z.dead or _hit_z.has(z) or absf(z.global_position.x - global_position.x) > HALF_W + 10.0 or absf(z.global_position.y - global_position.y) > 60.0:
				continue
			_hit_z[z] = true
			frozen += 1
			z.set_meta("s60_frozen", Time.get_ticks_msec() + int(FREEZE_T * 1000.0))
			z.stagger(FREEZE_T)
			z._popup("FROZEN", Color("bfe8ff"), 15, -80.0)
			z.take_damage(DMG_Z, z.global_position + Vector2(0, -30), Vector2.UP, false, {"source": "hazard", "fixed": DMG_Z})

	func _draw() -> void:
		DrawBatch.begin(self)
		_draw_b()
		DrawBatch.end(self)

	func _draw_b() -> void:
		var pts := PackedVector2Array()
		var cols := PackedColorArray()
		# הסבכה ברצפה + טבעת כפור
		var warn := 0.0
		if state == WARN:
			warn = 1.0 - _st / WARN_T
		elif state == BLAST:
			warn = 1.0
		U.oval(pts, cols, Vector2(0, -1.0), HALF_W + 10.0 * warn, 4.0 + 2.0 * warn, Color(0.85, 0.96, 1.0, 0.25 + 0.5 * warn), 16)
		U.rect(pts, cols, Rect2(-HALF_W * 0.7, -4.0, HALF_W * 1.4, 5.0), Color("1a2026"))
		for q in 9:
			U.rect(pts, cols, Rect2(-HALF_W * 0.7 + 4.0 + float(q) * HALF_W * 0.15, -3.0, 3.0, 3.0), Color(0.5, 0.85, 1.0, 0.3 + 0.6 * warn))
		# הצינור והשסתום מימין (המטרה)
		var vx := HALF_W + 26.0
		U.vrect(pts, cols, Rect2(vx - 6.0, -140.0, 12.0, 140.0), Color("7a8894"), Color("4a5560"))
		U.rect(pts, cols, Rect2(vx - 6.0, -140.0, 12.0, 4.0), Color(0.92, 0.97, 1.0, 0.8))
		U.seg(pts, cols, Vector2(vx, -10.0), Vector2(HALF_W * 0.6, -3.0), 6.0, Color("5a6672"))
		var spin := _t * (8.0 if state == BLAST else 0.0)
		U.oval(pts, cols, Vector2(vx, -64.0), 13.0, 13.0, Color("1c4a8a"), 14)
		for q in 4:
			var a := spin + float(q) * PI * 0.5
			U.seg(pts, cols, Vector2(vx, -64.0), Vector2(vx, -64.0) + Vector2.from_angle(a) * 12.0, 2.4, Color("6aa0e0"))
		U.oval(pts, cols, Vector2(vx, -64.0), 4.0, 4.0, Color("2a3038"), 8)
		# מד לחץ: המחוג עולה באזהרה
		U.oval(pts, cols, Vector2(vx, -112.0), 9.0, 9.0, Color("e8eef0"), 12)
		var ang := lerpf(-2.4, -0.5, warn) + (sin(_t * 30.0) * 0.08 if state != IDLE else 0.0)
		U.seg(pts, cols, Vector2(vx, -112.0), Vector2(vx, -112.0) + Vector2.from_angle(ang) * 7.0, 1.2, Color(0.8, 0.1, 0.1))
		U.rect(pts, cols, Rect2(vx - 22.0, -158.0, 44.0, 12.0), HAZ)
		U.rect(pts, cols, Rect2(vx - 20.0, -156.0, 40.0, 8.0), Color("1a1a1a"))
		# עמוד הקור
		if state == BLAST:
			var k := clampf(1.0 - _st / BLAST_T, 0.0, 1.0)
			var hh := HGT * minf(1.0, k * 5.0) * (1.0 - maxf(0.0, k - 0.75) * 2.0)
			for q in 7:
				var wq := HALF_W * (0.5 + 0.08 * float(q)) * (0.9 + 0.1 * sin(_t * 20.0 + float(q)))
				var yq := -hh * float(q + 1) / 7.0
				U.oval(pts, cols, Vector2(sin(_t * 9.0 + float(q)) * 6.0, yq), wq, 22.0, Color(0.9, 0.97, 1.0, 0.35 - 0.03 * float(q)), 12)
			U.quad(pts, cols, Vector2(-HALF_W * 0.6, 0), Vector2(HALF_W * 0.6, 0), Vector2(HALF_W * 0.9, -hh), Vector2(-HALF_W * 0.9, -hh), Color(0.95, 1.0, 1.0, 0.6), Color(0.95, 1.0, 1.0, 0.6), Color(0.95, 1.0, 1.0, 0.0), Color(0.95, 1.0, 1.0, 0.0))
		U.flush(self, pts, cols)
		if state == WARN:
			DrawBatch.string(self, ThemeDB.fallback_font, Vector2(-6.0, -40.0), "!", HORIZONTAL_ALIGNMENT_LEFT, -1, 26, Color(0.6, 0.9, 1.0, 0.6 + 0.4 * sin(_t * 30.0)))


class ValveBody extends StaticBody2D:
	var trap = null

	func take_damage(_amount: int, hit_pos: Vector2, dir: Vector2, _explosive := false, _src := {}) -> void:
		if trap != null and is_instance_valid(trap):
			Particles.burst(trap.get_parent(), hit_pos, "spark", -dir, 5)
			Sfx.play("metal_ping", hit_pos, -2.0, 0.1, 2)
			trap.trigger(true)


# ============================================================
#  כרטיס מפתח של WARDEN שנפל: נופל לרצפה, זוהר ומסתובב. נאסף כשעוברים עליו (stage.collect_card)
# ============================================================
class Keycard extends Node2D:
	const PICK_R := 46.0
	var stage = null
	var ground := 630.0
	var vel := Vector2.ZERO
	var _t := 0.0
	var _done := false

	func _ready() -> void:
		z_index = 6
		add_to_group("s60_cards")

	func _process(delta: float) -> void:
		_t += delta
		if global_position.y < ground - 14.0 or vel.y < 0.0:
			vel.y += 900.0 * delta
			global_position += vel * delta
			if global_position.y >= ground - 14.0:
				global_position.y = ground - 14.0
				vel = Vector2.ZERO
		var pl := get_tree().get_first_node_in_group("player") as Node2D
		if not _done and _t > 0.35 and pl != null and not pl.dead and pl.body_rect().grow(PICK_R * 0.5).has_point(global_position):
			_done = true
			Sfx.play("s60_card", global_position, 2.0, 0.0, 1)
			if stage != null and is_instance_valid(stage) and stage.has_method("collect_card"):
				stage.collect_card(self)
			queue_free()
			return
		if Art.on_screen(self, global_position, 40.0):
			queue_redraw()

	func _draw() -> void:
		DrawBatch.begin(self)
		_draw_b()
		DrawBatch.end(self)

	func _draw_b() -> void:
		var bob := sin(_t * 3.0) * 2.0
		var sq := cos(_t * 2.4)   # מסתובב (מתכווץ ברוחב)
		Kit.soft_glow(self, Vector2(0, bob), 30.0, Color(0.5, 1.0, 0.6, 0.35 + 0.15 * sin(_t * 6.0)))
		var w := 10.0 * absf(sq) + 1.0
		DrawBatch.rect(self, Rect2(-w, -7.0 + bob, w * 2.0, 14.0), Color("eef2f0") if sq > 0.0 else Color("c8d0cc"))
		if sq > 0.2:
			DrawBatch.rect(self, Rect2(-w, -7.0 + bob, w * 2.0, 4.0), Color("c8281e"))
			DrawBatch.rect(self, Rect2(-w * 0.7, 0.0 + bob, w * 0.6, 4.0), Color("d8b040"))   # שבב
		DrawBatch.line(self, Vector2(0, -7.0 + bob), Vector2(0, -16.0 + bob), Color(0.2, 0.3, 0.6), 1.2)   # שרוך


# ============================================================
#  מכשולים (מוצקים + מחסה): "bench" שולחן מעבדה / "dewar" מיכלי חנקן / "gurney" אלונקה הפוכה / "rack" ארון שרתים שנפל
# ============================================================
class Obstacle extends Node2D:
	var kind := "bench"
	var size := Vector2(110, 54)
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
			"bench":   # שולחן מעבדה מפלדה: מגירות, מיקרוסקופ, כוסות, מבחנות שבורות
				U.vrect(pts, cols, Rect2(0, -h, w, 8.0), Color("9aa8b4"), Color("6a7884"))
				U.rect(pts, cols, Rect2(0, -h, w, 2.0), Color(0.95, 0.98, 1.0, 0.8))
				U.vrect(pts, cols, Rect2(4.0, -h + 8.0, w - 8.0, h - 8.0), Color("4a5560"), Color("2e363e"))
				for q in 3:
					var dx := 8.0 + float(q) * (w - 16.0) / 3.0
					U.rect(pts, cols, Rect2(dx, -h + 14.0, (w - 16.0) / 3.0 - 4.0, h - 22.0), Color("3a444e"))
					U.rect(pts, cols, Rect2(dx + (w - 16.0) / 6.0 - 8.0, -h + 22.0, 12.0, 3.0), Color("8a98a4"))
				# מיקרוסקופ
				var mx := w * 0.25
				U.rect(pts, cols, Rect2(mx - 8.0, -h - 4.0, 16.0, 4.0), Color("2a3038"))
				U.seg(pts, cols, Vector2(mx, -h - 4.0), Vector2(mx + 4.0, -h - 22.0), 4.0, Color("2a3038"))
				U.seg(pts, cols, Vector2(mx + 4.0, -h - 22.0), Vector2(mx + 10.0, -h - 14.0), 3.0, Color("6a7884"))
				# כוסות ומבחנות
				for q in 3:
					var bx := w * 0.5 + float(q) * 12.0
					var bh := 8.0 + r.randf_range(0.0, 8.0)
					var lc := [Color(0.4, 0.9, 0.6, 0.6), Color(0.9, 0.4, 0.4, 0.6), Color(0.5, 0.8, 1.0, 0.6)][q] as Color
					U.rect(pts, cols, Rect2(bx, -h - bh, 7.0, bh), Color(0.85, 0.95, 1.0, 0.35))
					U.rect(pts, cols, Rect2(bx, -h - bh * 0.5, 7.0, bh * 0.5), lc)
				U.oval(pts, cols, Vector2(w * 0.8, -h - 1.0), 14.0, 2.0, Color(0.4, 0.05, 0.06, 0.6), 8)   # כתם דם על השולחן
			"dewar":   # מיכלי חנקן נוזלי (גלילים עם מכסה ושסתום, כפור)
				for q in 2:
					var dx := 4.0 + float(q) * w * 0.5
					var dw := w * 0.5 - 8.0
					var dh := h * (0.85 if q == 0 else 1.0)
					U.vrect(pts, cols, Rect2(dx, -dh, dw, dh), Color("c8d4dc"), Color("7a8894"))
					U.rect(pts, cols, Rect2(dx + 3.0, -dh, 4.0, dh), Color(1, 1, 1, 0.35))
					U.rect(pts, cols, Rect2(dx, -dh * 0.55, dw, 6.0), Color("2a5a9a"))
					U.oval(pts, cols, Vector2(dx + dw * 0.5, -dh), dw * 0.5, 4.0, Color("8a98a4"), 10)
					U.rect(pts, cols, Rect2(dx + dw * 0.5 - 3.0, -dh - 8.0, 6.0, 8.0), Color("4a5560"))
					U.vrect(pts, cols, Rect2(dx, -12.0, dw, 12.0), Color(0.92, 0.98, 1.0, 0.0), Color(0.92, 0.98, 1.0, 0.7))
				U.dia(pts, cols, Vector2(w * 0.25, -h * 0.4), 5.0, HAZ)
			"gurney":   # אלונקה הפוכה עם רצועות, סדין מוכתם
				U.seg(pts, cols, Vector2(6.0, 0), Vector2(18.0, -h + 6.0), 3.0, Color("8a98a4"))
				U.seg(pts, cols, Vector2(w - 6.0, 0), Vector2(w - 18.0, -h + 6.0), 3.0, Color("8a98a4"))
				U.vrect(pts, cols, Rect2(4.0, -h, w - 8.0, 12.0), Color("aab4bc"), Color("6a7884"))
				U.quad(pts, cols, Vector2(10.0, -h + 4.0), Vector2(w - 10.0, -h + 2.0), Vector2(w - 24.0, -h + 34.0), Vector2(20.0, -h + 40.0), Color("dce4e2"), Color("dce4e2"), Color("b8c4c0"), Color("b8c4c0"))
				U.oval(pts, cols, Vector2(w * 0.5, -h + 18.0), 16.0, 8.0, Color(0.45, 0.05, 0.06, 0.75), 10)
				U.oval(pts, cols, Vector2(w * 0.62, -h + 26.0), 6.0, 10.0, Color(0.4, 0.04, 0.05, 0.6), 8)
				for q in 2:   # רצועות קרועות
					U.seg(pts, cols, Vector2(w * (0.3 + 0.35 * float(q)), -h + 6.0), Vector2(w * (0.3 + 0.35 * float(q)) + 6.0, -h + 30.0), 3.0, Color("3a2a1a"))
				for q in 2:
					U.oval(pts, cols, Vector2(12.0 + float(q) * (w - 24.0), -4.0), 5.0, 5.0, Color("1a1a1a"), 8)
			_:   # ארון שרתים שנפל על הצד
				U.vrect(pts, cols, Rect2(0, -h, w, h), Color("2a323a"), Color("1a2026"))
				U.rect(pts, cols, Rect2(0, -h, w, 3.0), Color(0.88, 0.95, 1.0, 0.6))
				for q in int(w / 16.0):
					U.rect(pts, cols, Rect2(4.0 + float(q) * 16.0, -h + 6.0, 12.0, h - 12.0), Color("12171c"))
					U.rect(pts, cols, Rect2(8.0 + float(q) * 16.0, -h + 10.0, 3.0, 2.0), Color(1.0, 0.3, 0.2, 0.8) if q % 3 == 0 else Color(0.3, 0.3, 0.3))
				for q in 3:
					U.seg(pts, cols, Vector2(w * 0.3 * float(q + 1), -h), Vector2(w * 0.3 * float(q + 1) + r.randf_range(-10, 10), -h - 14.0), 2.0, Color("1a1a1a"))
				U.tri(pts, cols, Vector2(w * 0.6, -h), Vector2(w * 0.75, -h), Vector2(w * 0.7, -h + 20.0), Color(0.8, 0.95, 1.0, 0.4))   # זכוכית שבורה
		U.flush(self, pts, cols)


# ============================================================
#  חדר הכליאה של SUBJECT FOUR (זירת הבוס): תא כליאה ענק שנפרץ מבפנים, רצועות קרועות, חלון תצפית עם דם,
#  חורי קליעים (הוא ירה את דרכו החוצה), תרמילים, וצוהר ענק "NIVEL -4" שהפטרייה זורמת אליו (ה-ROOT - שלב 62)
# ============================================================
class ContainmentArena extends Node2D:
	var w := 1100.0
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
		# קיר החדר: פלדה כהה עם פסי סכנה
		U.vrect(pts, cols, Rect2(0, -520.0, w, 520.0), Color("1e262e"), Color("2c3640"))
		for q in int(w / 64.0):
			U.rect(pts, cols, Rect2(float(q) * 64.0, -520.0, 2.0, 520.0), Color(0.1, 0.13, 0.16, 0.6))
		for q in int(w / 30.0):
			var xx := float(q) * 30.0
			U.quad(pts, cols, Vector2(xx, -90.0), Vector2(xx + 15.0, -90.0), Vector2(xx + 5.0, -78.0), Vector2(xx - 10.0, -78.0), Color(HAZ, 0.7), Color(HAZ, 0.7), Color(HAZ, 0.7), Color(HAZ, 0.7))
		# "4" ענק צבוע על הקיר
		var fx := 120.0
		U.seg(pts, cols, Vector2(fx + 40.0, -420.0), Vector2(fx, -320.0), 16.0, Color(0.85, 0.75, 0.3, 0.35))
		U.seg(pts, cols, Vector2(fx, -320.0), Vector2(fx + 70.0, -320.0), 16.0, Color(0.85, 0.75, 0.3, 0.35))
		U.seg(pts, cols, Vector2(fx + 50.0, -380.0), Vector2(fx + 50.0, -270.0), 16.0, Color(0.85, 0.75, 0.3, 0.35))
		# תא הכליאה: גליל ענק שנפרץ מבפנים (פח מקופל החוצה), רצועות, נוזל
		var cx := 470.0
		U.vrect(pts, cols, Rect2(cx - 90.0, -360.0, 180.0, 330.0), Color("38444e"), Color("222a32"))
		U.rect(pts, cols, Rect2(cx - 90.0, -360.0, 180.0, 4.0), Color(0.9, 0.96, 1.0, 0.6))
		U.vrect(pts, cols, Rect2(cx - 62.0, -330.0, 124.0, 280.0), Color(0.08, 0.12, 0.14), Color(0.04, 0.06, 0.08))
		for s: float in [-1.0, 1.0]:   # הפח קרוע ומקופל החוצה
			U.tri(pts, cols, Vector2(cx + s * 62.0, -300.0), Vector2(cx + s * 110.0, -250.0), Vector2(cx + s * 62.0, -200.0), Color("5a6672"))
			U.tri(pts, cols, Vector2(cx + s * 62.0, -170.0), Vector2(cx + s * 100.0, -120.0), Vector2(cx + s * 62.0, -90.0), Color("4a5560"))
			U.seg(pts, cols, Vector2(cx + s * 40.0, -280.0), Vector2(cx + s * 20.0, -200.0), 4.0, Color("2a1e14"))   # רצועות קרועות
			U.seg(pts, cols, Vector2(cx + s * 44.0, -160.0), Vector2(cx + s * 26.0, -110.0), 4.0, Color("2a1e14"))
		U.vein(pts, cols, Vector2(cx - 20.0, -60.0), Vector2(cx - 50.0, -300.0), 6.0, _t, 9000.0, 3)
		U.vein(pts, cols, Vector2(cx + 20.0, -60.0), Vector2(cx + 46.0, -280.0), 5.0, _t, 9000.0, 7)
		U.rect(pts, cols, Rect2(cx - 50.0, -392.0, 100.0, 26.0), Color("1a2026"))
		# חלון התצפית עם כתמי דם וחורי קליעים
		var ox := 700.0
		U.rect(pts, cols, Rect2(ox, -420.0, 240.0, 110.0), Color("0c1820"))
		U.rect(pts, cols, Rect2(ox, -420.0, 240.0, 110.0), Color(0.4, 0.7, 0.9, 0.12))
		U.oval(pts, cols, Vector2(ox + 70.0, -370.0), 30.0, 22.0, Color(0.45, 0.04, 0.05, 0.7), 12)
		for q in 4:
			U.seg(pts, cols, Vector2(ox + 60.0 + float(q) * 8.0, -360.0), Vector2(ox + 58.0 + float(q) * 9.0, -320.0 - float(q) * 4.0), 3.0, Color(0.45, 0.04, 0.05, 0.6))
		for q in 9:   # חורי קליעים
			var hp := Vector2(ox + 120.0 + U.h(q, 70) * 110.0, -410.0 + U.h(q, 71) * 90.0)
			U.oval(pts, cols, hp, 3.0, 3.0, Color("060a0c"), 6)
			for s in 3:
				U.seg(pts, cols, hp, hp + Vector2.from_angle(float(s) * 2.1 + float(q)) * 9.0, 0.8, Color(0.85, 0.95, 1.0, 0.5))
		for q in 4:
			U.rect(pts, cols, Rect2(ox - 6.0 + float(q % 2) * 246.0, -426.0, 6.0, 122.0), Color("4a5560"))
		# הצוהר אל NIVEL -4: הפטרייה זורמת אליו מכל הכיוונים (ה-ROOT)
		var hx := w - 170.0
		U.vrect(pts, cols, Rect2(hx - 80.0, -300.0, 160.0, 290.0), Color("2a323a"), Color("161c22"))
		U.oval(pts, cols, Vector2(hx, -150.0), 64.0, 64.0, Color("3a444e"), 24)
		U.oval(pts, cols, Vector2(hx, -150.0), 52.0, 52.0, Color("1a2026"), 24)
		for q in 6:
			var a := float(q) / 6.0 * TAU + 0.3
			U.seg(pts, cols, Vector2(hx, -150.0), Vector2(hx, -150.0) + Vector2.from_angle(a) * 52.0, 5.0, Color("2a323a"))
		for q in 9:
			var a2 := Vector2(-200.0 + float(q) * 70.0, -10.0 - U.h(q, 72) * 200.0)
			U.vein(pts, cols, Vector2(hx, -150.0) + Vector2.from_angle(float(q) * 0.7) * 50.0, Vector2(hx, -150.0) + a2 * 0.0 + Vector2(-300.0 + float(q) * 40.0, -20.0 - U.h(q, 73) * 260.0), 6.0, _t, global_position.x + hx, q)
		# תרמילים על הרצפה
		for q in 26:
			var sp := Vector2(260.0 + U.h(q, 74) * 520.0, -2.0)
			U.rect(pts, cols, Rect2(sp.x, sp.y, 4.0, 2.0), Color(0.8, 0.65, 0.3, 0.9))
		U.flush(self, pts, cols)
		var pul := 0.5 + 0.5 * sin(_t * 3.2)
		Kit.soft_glow(self, Vector2(hx, -150.0), 140.0, Color(ECHO, 0.14 + 0.1 * pul))
		DrawBatch.rect(self, Rect2(cx - 50.0, -392.0, 100.0, 26.0), Color("1a2026"))
		DrawBatch.string(self, ThemeDB.fallback_font, Vector2(cx - 42.0, -373.0), "SUJETO 04", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(1.0, 0.5, 0.4, 0.9))
		DrawBatch.string(self, ThemeDB.fallback_font, Vector2(hx - 48.0, -318.0), "NIVEL -4", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(ECHO, 0.85))


# ============================================================
#  מסך: גבישי כפור, אדי קור, הבהוב אדום של אזעקה, הבהוב חשמל בסצנה, וכרטיסי המפתח שלך (פינה ימנית עליונה)
# ============================================================
class LabFX extends Node2D:
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
		for i in int(40.0 * q):   # גבישי כפור מהאוורור
			var x := fposmod(U.h(i, 1) * vp.x * 1.7 + sin(_t * 0.6 + float(i)) * 30.0 - _t * 8.0, vp.x)
			var y := fposmod(U.h(i, 2) * vp.y + _t * (24.0 + U.h(i, 3) * 30.0), vp.y)
			U.dia(pts, cols, Vector2(x, y), 1.0 + U.h(i, 4) * 1.4, Color(0.9, 0.97, 1.0, 0.35 + 0.3 * U.h(i, 5)))
		# אזעקה: הבהוב אדום בשולי המסך
		if U.alarm > 0.01:
			var p := (0.5 + 0.5 * sin(_t * 6.0)) * U.alarm
			var c0 := Color(1.0, 0.1, 0.05, 0.22 * p)
			var c1 := Color(1.0, 0.1, 0.05, 0.0)
			U.quad(pts, cols, Vector2(0, 0), Vector2(vp.x, 0), Vector2(vp.x, 90.0), Vector2(0, 90.0), c0, c0, c1, c1)
			U.quad(pts, cols, Vector2(0, vp.y - 90.0), Vector2(vp.x, vp.y - 90.0), Vector2(vp.x, vp.y), Vector2(0, vp.y), c1, c1, c0, c0)
			U.quad(pts, cols, Vector2(0, 0), Vector2(120.0, 0), Vector2(120.0, vp.y), Vector2(0, vp.y), c0, c1, c1, c0)
			U.quad(pts, cols, Vector2(vp.x - 120.0, 0), Vector2(vp.x, 0), Vector2(vp.x, vp.y), Vector2(vp.x - 120.0, vp.y), c1, c0, c0, c1)
		# "WELCOME HOME": החשמל מהבהב
		var wt := U.since(U.welcome_ms)
		if wt >= 0.0 and wt < 3.0:
			var fl := 1.0 if sin(_t * 37.0) > 0.3 else 0.0
			U.rect(pts, cols, Rect2(Vector2.ZERO, vp), Color(0.0, 0.02, 0.0, 0.35 * fl * (1.0 - wt / 3.0)))
		# כרטיסי המפתח שלך
		for i in mini(U.cards, 4):
			var cp := Vector2(vp.x - 70.0 - float(i) * 30.0, 96.0)
			U.rect(pts, cols, Rect2(cp + Vector2(-11, -7), Vector2(22, 14)), Color("eef2f0"))
			U.rect(pts, cols, Rect2(cp + Vector2(-11, -7), Vector2(22, 4)), Color("c8281e"))
			U.rect(pts, cols, Rect2(cp + Vector2(-8, 0), Vector2(7, 4)), Color("d8b040"))
		U.flush(self, pts, cols)
		if U.cards > 0:
			DrawBatch.string(self, ThemeDB.fallback_font, Vector2(vp.x - 128.0 - float(mini(U.cards, 4) - 1) * 30.0, 101.0), "KEY", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.85, 1.0, 0.85, 0.85))
