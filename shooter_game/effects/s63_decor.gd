extends RefCounted
const DrawBatch := preload("res://effects/draw_batch.gd")   # כל הציור של זומבי ב-draw call אחד
# ============================================================
#  קישוטים לשלב 63 ("THEY LEARNED YOU") - אזור שביעי (פטגוניה), שלב 9, השלב האחרון במשחק.
#  הלב של ה-ROOT, עמוק מתחת לאושואיה (מתחת לכלא הישן - הפרסידיו). מערה חיה: קירות של בשר פטרייה, צלעות של שורשים,
#  חוטי עצבים, ונהרות נבגים שזורמים ימינה - אל הלב. הכוורת שמרה כאן הכל: "מוזיאון שלך" - העתקים מגודלים בפטרייה של
#  המקומות שהגיבור עבר (מכונית, גולגולת לווייתן, מיכל הקפאה, מגדלור, צלב מהאנדים, קרון רכבת, עץ שרוף, צריף פאבלה),
#  פסלים של הגיבור בכל התנוחות שלו (החזרות של הכוורת), ושקי רחם שבהם גדלים HOLLOW - עותקים של הגיבור.
#  כל השלב פועם בקצב של הלב (U.beat): ככל שמתקרבים ללב - מהר וחזק יותר (U.heart_k).
#    heart_sky     - (רקע) תקרת המערה הרחוקה: אדום-שחור, זוהר הלב מימין שפועם, נהרות נבגים שזורמים ימינה
#    far_vault     - (רקע, 0.06) עמודי שורשים ענקיים, טרסות עם אלפי פסלים קטנים של הגיבור (צלליות עם עיניים ירוקות),
#                    עורקים שמתכנסים ימינה אל הלב
#    mid_memory    - (רקע, 0.28) קיר הזיכרון: בשר פטרייה עם שרידי זיכרון מגודלים (8 סוגים מכל האזורים), חוטי עצבים
#    near_flesh    - (רקע, 0.6) וילונות שורשים תלויים, גנגליונים, קשתות צלעות, שקי נבגים שפועמים עם הלב
#    heart_overlay - אובך חם מאחורי הדמויות + צל התקרה
#    FleshGround   - (עולם) רצפה של בשר פטרייה: עצבים, שברי עצם, קשריות זוהרות, שלוליות. עבה יותר ליד הלב
#    Threshold     - (עולם) הכניסה: שערי הכלא (סורגים חלודים) שהפטרייה בלעה, שלט "PRESIDIO" אכול, ועל הקיר: "WELCOME HOME, ZERO"
#    Statue        - (עולם) פסל פטרייה של הגיבור (מכוון / מתגלגל / כורע / קופץ) - החזרות של הכוורת. חלקם HOLLOW ישנים
#    HollowPod     - (עולם) שק רחם תלוי מהתקרה עם HOLLOW שגדל בפנים (enemies/types/hollow.gd): מתנפח (ripen) ומתפקע (burst)
#    RootShelf     - (עולם) מדף שורש / גשר עצם (הקומה עצמה = add_floor בשלב), סולם שורשים
#    VeinMouth     - (עולם) פה של עורק בתקרה: משם יוצאים PILGRIM (enemies/types/pilgrim.gd), ואליו הם נכנסים בדרך הביתה
#    Membrane      - (עולם, מוצק כשסגור) קרום בשר שנסגר כמו סוגר (sphincter): השערים של אולם המראות (בוס האמצע)
#    MirrorHall    - (עולם) הקיר האחורי של אולם המראות: קרום מבריק עם מאות צלליות של הגיבור, "SUBJECT ZERO" חרוט בפטרייה
#    HeartValve    - (עולם, מלכודת) שסתום עורק ברצפה: מתנפח בפעימה אחת (אזהרה) ומתפרץ בפעימה הבאה - עמוד דם ונבגים.
#                    פוגע ומעיף אותך, מעיף ופוגע בזומבים. ירייה בסוגר = מתפרץ עכשיו (להעיף קבוצה)
#    RootSnare     - (עולם, מלכודת) שורש חבוי ברצפה: הרצפה מתגלגלת כשמתקרבים, ואז שורשים לופתים את הרגליים (האטה + נזק).
#                    זומבי שעולה עליו - נתפס. ירייה בפקעת = מת
#    HeartChamber  - (עולם) זירת ה-ROOT: עורקים ענקיים שמזינים את הלב מכל הכיוונים, צלעות שורש, טבעות ורידים ברצפה
#    Obstacle      - (מוצק + מחסה) "car" / "barrels" / "sandbags" / "bones": הכוורת גידלה מחדש את המחסות שהגיבור השתמש בהן
#    HeartFX       - (מסך) נבגים, פעימת הלב בשולי המסך, מונה "LESSONS HOME" (פינה), הודעות ("A LESSON REACHED THE ROOT")
#  מצב משותף: U.beat (0..1 פעימה), U.heart_k (קרבה ללב), U.lessons {קטגוריה: כמה}, U.note / U.note_ms, U.life (סוף המשחק:
#    0 = הכוורת מתה - הזוהר כבה, 1 = רגיל, 2 = JOIN - הכל פורח), U.seen_lesson.
#  לשנות: HeartValve.* , RootSnare.*, Membrane.CLOSE_T / OPEN_T, HollowPod.RIPE_T.
# ============================================================

const Art := preload("res://art.gd")
const Sfx := preload("res://sfx.gd")
const Kit := preload("res://effects/backdrop_kit.gd")
const Particles := preload("res://particles.gd")
const WDB := preload("res://weapons/weapon_db.gd")

const FLESH := Color("4a1c22")
const FLESH_D := Color("24090e")
const FLESH_L := Color("7a3438")
const ROOTC := Color("3a2a22")
const ROOT_L := Color("6a5040")
const BONE := Color("c8bea0")
const BONE_D := Color("8a8068")
const ECHO := Color(0.75, 1.0, 0.55)        # אותו צבע כמו effects/spore_lesson.gd
const ECHO_D := Color("2e4a22")
const ECHO_M := Color("6e9a46")
const STONE := Color("2a2226")
const RUST := Color("6a3a22")
const CATS := ["auto", "shotgun", "precision", "explosive"]
const CAT_COL := {"auto": Color("ffd84a"), "shotgun": Color("ff8a3a"), "precision": Color("7ad0ff"), "explosive": Color("ff4a5a"), "other": Color(0.75, 1.0, 0.55)}
const CAT_NAME := {"auto": "BURSTS", "shotgun": "SHOTGUN", "precision": "AIM", "explosive": "BLASTS", "other": "TRICKS"}


# מצב משותף (השלב כותב, כל הקישוטים קוראים) + עזרים - מחלקה פנימית לא רואה פונקציות סטטיות של הקובץ
class U:
	static var beat := 0.0           # 0..1: פעימת הלב (קופץ ל-1 בכל פעימה ודועך)
	static var beats := 0            # מספר הפעימות מתחילת השלב
	static var heart_k := 0.0        # 0..1: כמה קרוב ללב (השלב, לפי x של השחקן)
	static var lessons := {}         # {"shotgun": 2, ...} - כמה שיעורים הגיעו הביתה (HeartFX מצייר)
	static var seen_lesson := false  # המונה מופיע רק אחרי שהשחקן ראה PILGRIM
	static var note := ""            # הודעה על המסך
	static var note_col := Color.WHITE
	static var note_ms := -1
	static var life := 1.0           # הסוף: 0 = מת (DESTROY), 1 = רגיל, 2 = פורח (JOIN)
	static var t := 0.0
	static var say_at := 0           # msec: מתי השורה הבאה של הגיבור יכולה להופיע (שלא ידברו אחד על השני)

	static func reset() -> void:
		say_at = 0
		beat = 0.0
		beats = 0
		heart_k = 0.0
		lessons = {}
		seen_lesson = false
		note = ""
		note_ms = -1
		life = 1.0

	static func since(ms: int) -> float:   # שניות מאז (או -1)
		return -1.0 if ms < 0 else float(Time.get_ticks_msec() - ms) / 1000.0

	# שורה של הגיבור, בתור: אם הוא דיבר לפני רגע - מחכים. ממתינים יותר מ-5 שניות = מוותרים
	static func say(pl: Node, text: String, c: Color) -> void:
		if pl == null or not is_instance_valid(pl):
			return
		var now := Time.get_ticks_msec()
		var wait := maxi(0, say_at - now)
		if wait > 5000:
			return
		say_at = maxi(now, say_at) + 2300
		if wait == 0:
			pl._say(text, c)
			return
		pl.get_tree().create_timer(float(wait) / 1000.0).timeout.connect(func() -> void:
			if is_instance_valid(pl) and not pl.dead:
				pl._say(text, c))

	static func notify(text: String, c: Color) -> void:
		note = text
		note_col = c
		note_ms = Time.get_ticks_msec()

	static func h(i: int, s: int) -> float:
		return fposmod(sin(float(i) * 12.9898 + float(s) * 78.233) * 43758.5453, 1.0)

	# צבע זוהר ECHO לפי מצב הכוורת (סוף המשחק: כבה לאפור / פורח)
	static func glow(c: Color) -> Color:
		if life < 1.0:
			var g := Color(0.22, 0.22, 0.2, c.a * (0.4 + 0.6 * life))
			return g.lerp(c, life)
		if life > 1.0:
			var k := minf(life - 1.0, 1.0)
			return Color(minf(c.r + 0.25 * k, 1.0), minf(c.g + 0.15 * k, 1.0), minf(c.b + 0.3 * k, 1.0), minf(c.a * (1.0 + 0.5 * k), 1.0))
		return c

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

	# עורק / עצב: קו מתפתל עם בלוטות, הדופק נע ימינה - אל הלב (wx = x בעולם בשביל הגל)
	static func vein(pts: PackedVector2Array, cols: PackedColorArray, a: Vector2, b: Vector2, w: float, t: float, wx: float, seed_v: int, base := Color("2e4a22")) -> void:
		var n := 7
		var prev := a
		for q in range(1, n + 1):
			var k := float(q) / float(n)
			var p := a.lerp(b, k) + Vector2(sin(k * 7.0 + float(seed_v)) * 5.0, cos(k * 5.0 + float(seed_v) * 0.7) * 3.0)
			var pulse := 0.5 + 0.5 * sin(t * 3.2 - (wx + p.x) * 0.012)
			var c := base.lerp(glow(Color(0.75, 1.0, 0.55)), pulse * 0.55 * clampf(life, 0.0, 1.0))
			seg(pts, cols, prev, p, w * (1.0 - k * 0.5), c)
			if q % 2 == 0:
				oval(pts, cols, p, 2.2 + pulse * 1.4, 2.0 + pulse * 1.2, glow(Color(0.75, 1.0, 0.55, 0.45 + 0.5 * pulse)), 6)
			prev = p

	# פסל / צללית של הגיבור (מעיל ארוך, ברדס) בתנוחה: 0 מכוון, 1 כורע, 2 מתגלגל, 3 קופץ. (0,0) = כפות הרגליים, s = גודל
	static func hero(pts: PackedVector2Array, cols: PackedColorArray, p: Vector2, s: float, pose: int, c: Color, face := 1.0) -> void:
		var f := face
		match pose:
			2:   # מתגלגל: כדור עם המעיל
				oval(pts, cols, p + Vector2(0, -12.0 * s), 13.0 * s, 11.0 * s, c, 10)
				oval(pts, cols, p + Vector2(f * 9.0 * s, -18.0 * s), 5.0 * s, 5.0 * s, c, 8)
				return
			1:   # כורע עם הנשק
				quad(pts, cols, p + Vector2(-7.0 * f * s, 0), p + Vector2(8.0 * f * s, 0), p + Vector2(5.0 * f * s, -24.0 * s), p + Vector2(-6.0 * f * s, -24.0 * s), c, c, c, c)
				oval(pts, cols, p + Vector2(1.0 * f * s, -29.0 * s), 5.0 * s, 5.5 * s, c, 8)
				seg(pts, cols, p + Vector2(2.0 * f * s, -20.0 * s), p + Vector2(20.0 * f * s, -21.0 * s), 3.0 * s, c)
				return
			3:   # באוויר, ברכיים מקופלות
				quad(pts, cols, p + Vector2(-6.0 * f * s, -12.0 * s), p + Vector2(7.0 * f * s, -12.0 * s), p + Vector2(5.0 * f * s, -40.0 * s), p + Vector2(-5.0 * f * s, -40.0 * s), c, c, c, c)
				seg(pts, cols, p + Vector2(0, -14.0 * s), p + Vector2(6.0 * f * s, -4.0 * s), 4.0 * s, c)
				oval(pts, cols, p + Vector2(1.0 * f * s, -46.0 * s), 5.0 * s, 5.5 * s, c, 8)
				seg(pts, cols, p + Vector2(2.0 * f * s, -34.0 * s), p + Vector2(18.0 * f * s, -44.0 * s), 3.0 * s, c)
				return
		# עומד ומכוון: מעיל ארוך עד הברכיים, ברדס, נשק לפנים
		seg(pts, cols, p + Vector2(-3.0 * f * s, -18.0 * s), p + Vector2(-5.0 * f * s, 0), 4.0 * s, c)
		seg(pts, cols, p + Vector2(3.0 * f * s, -18.0 * s), p + Vector2(6.0 * f * s, 0), 4.0 * s, c)
		quad(pts, cols, p + Vector2(-8.0 * f * s, -14.0 * s), p + Vector2(8.0 * f * s, -14.0 * s), p + Vector2(6.0 * f * s, -40.0 * s), p + Vector2(-6.0 * f * s, -40.0 * s), c, c, c, c)
		oval(pts, cols, p + Vector2(1.0 * f * s, -46.0 * s), 5.0 * s, 5.8 * s, c, 8)
		tri(pts, cols, p + Vector2(-5.0 * f * s, -48.0 * s), p + Vector2(4.0 * f * s, -52.0 * s), p + Vector2(-7.0 * f * s, -40.0 * s), c)
		seg(pts, cols, p + Vector2(2.0 * f * s, -36.0 * s), p + Vector2(22.0 * f * s, -37.0 * s), 3.0 * s, c)


static func _h(i: int, s: int) -> float:
	return U.h(i, s)


# קטגוריית הנשק (weapons/weapon_db.gd "category"): auto / shotgun / precision / explosive / other
static func cat_of_weapon(id: int) -> String:
	if id < 0:
		return "other"
	var c := str(WDB.val(id, "category", "other"))
	return c if c in CATS else "other"


# קטגוריה של פגיעה (src של take_damage): קליע לפי הנשק, פיצוץ = explosive
static func cat_of_src(src: Dictionary) -> String:
	var s := str(src.get("source", "bullet"))
	if s == "bullet" or s == "laser":
		return cat_of_weapon(int(src.get("weapon", -1))) if src.has("weapon") else "auto"
	if s == "melee" or s == "fire" or s == "taser" or s == "trap" or s == "stomp":
		return "other"
	return "explosive"


# ============================================================
#  רקע
# ============================================================

# ---- תקרת המערה הרחוקה: אדום-שחור, זוהר הלב מימין, נהרות נבגים שזורמים ימינה ----
static func heart_sky(ci: CanvasItem, v: Vector2, t: float) -> void:
	Kit.gradient_sky(ci, v, [Color("060203"), Color("120507"), Color("1e080c"), Color("2c0e12"), Color("3a1418")], 0.92)
	var b: float = U.beat
	var hk: float = U.heart_k
	var lf := clampf(U.life, 0.0, 1.5)
	# הלב: זוהר אדום-ירוק רחוק מימין שפועם (חזק יותר ככל שמתקרבים)
	var hp := Vector2(v.x * (0.95 - 0.25 * hk), v.y * 0.42)
	Kit.soft_glow(ci, hp, 420.0 + 120.0 * hk + 60.0 * b, Color(0.7, 0.12, 0.12, (0.16 + 0.12 * b + 0.1 * hk) * lf), 0.6)
	Kit.soft_glow(ci, hp, 200.0 + 50.0 * b, Color(0.6, 1.0, 0.45, (0.06 + 0.08 * b) * lf), 0.7)
	var pts := PackedVector2Array()
	var cols := PackedColorArray()
	# נהרות נבגים (שיעורים בדרך הביתה): שורות של נקודות זוהרות על מסלולי סינוס, זורמות ימינה
	for r in 5:
		var ry := 70.0 + float(r) * 62.0
		for i in 26:
			var x := fposmod(float(i) * 61.0 + _h(i, r) * 40.0 + t * (40.0 + float(r) * 9.0), v.x + 60.0) - 30.0
			var y := ry + sin(x * 0.006 + float(r) * 1.7 + t * 0.4) * 24.0
			var a := (0.18 + 0.3 * _h(i, r + 7)) * lf
			U.dia(pts, cols, Vector2(x, y), 1.0 + _h(i, r + 3) * 1.4, U.glow(Color(0.75, 1.0, 0.55, a)))
	# שורשים ענקיים יורדים מהתקרה (צלליות)
	for i in 6:
		var x0 := fposmod(_h(i, 31) * v.x * 1.6, v.x + 200.0) - 100.0
		var len_ := 120.0 + _h(i, 32) * 160.0
		U.seg(pts, cols, Vector2(x0, 0), Vector2(x0 + (_h(i, 33) - 0.5) * 80.0, len_), 14.0 + _h(i, 34) * 14.0, Color(0.05, 0.015, 0.02, 0.85))
	U.flush(ci, pts, cols)


# ---- עמודי שורשים ענקיים, טרסות של פסלי גיבור זעירים, עורקים שמתכנסים ימינה ----
static func far_vault(ci: CanvasItem, sc: float, v: Vector2, y: float, t: float) -> void:
	var period := 1400.0
	var start := int(floor(sc / period)) - 1
	var pts := PackedVector2Array()
	var cols := PackedColorArray()
	var eyes := PackedVector2Array()
	for k in range(start, start + int(ceil(v.x / period)) + 2):
		var bx := float(k) * period - sc
		# קיר רחוק של בשר כהה בשכבות (גלי)
		var prev := Vector2(bx, y - 40.0)
		for q in range(1, 15):
			var px := bx + float(q) * 100.0
			var py := y - 90.0 - sin(px * 0.004 + float(k)) * 40.0 - _h(k * 17 + q, 1) * 30.0
			U.quad(pts, cols, prev, Vector2(px, py), Vector2(px, y + 10.0), Vector2(prev.x, y + 10.0), Color("1c080b"), Color("1c080b"), Color("12050a"), Color("12050a"))
			prev = Vector2(px, py)
		# טרסות עם פסלים זעירים של הגיבור (הכוורת עושה חזרות) - שלוש שורות
		for row in 3:
			var ty := y - 150.0 - float(row) * 70.0
			U.rect(pts, cols, Rect2(bx + 80.0 + float(row) * 40.0, ty, period - 260.0 - float(row) * 80.0, 6.0), Color("2a0e12"))
			var n := 22 - row * 4
			for s in n:
				var sx := bx + 110.0 + float(row) * 40.0 + float(s) * (period - 320.0 - float(row) * 80.0) / float(n)
				var pose := int(_h(k * 50 + row * 30 + s, 2) * 4.0)
				U.hero(pts, cols, Vector2(sx, ty), 0.38 - 0.06 * float(row), pose, Color(0.09, 0.03, 0.04, 0.95), 1.0 if _h(s, row) < 0.7 else -1.0)
				if _h(k * 50 + row * 30 + s, 4) < 0.35:
					eyes.append(Vector2(sx + 0.8, ty - 17.0 * (0.38 - 0.06 * float(row)) * 2.6))
		# עמודי שורש עבים מהרצפה עד התקרה
		for q in 2:
			var cx := bx + 300.0 + float(q) * 700.0 + _h(k * 3 + q, 5) * 80.0
			var w := 46.0 + _h(k * 3 + q, 6) * 30.0
			var top := Vector2(cx + (_h(k, q) - 0.5) * 60.0, 0.0)
			U.quad(pts, cols, Vector2(cx - w * 0.5, y + 10.0), Vector2(cx + w * 0.5, y + 10.0), top + Vector2(w * 0.7, 0), top - Vector2(w * 0.7, 0), Color("2a1014"), Color("1a080a"), Color("140608"), Color("2a1014"))
			for s in 4:   # שורשים מתפתלים סביב העמוד
				var a := Vector2(cx - w * 0.5 + _h(k + s, 7) * w, y)
				U.seg(pts, cols, a, a + Vector2((_h(q, s) - 0.5) * 50.0, -y * (0.4 + 0.5 * _h(s, q))), 4.0, Color("3a1a1a"))
		# עורקים שמתכנסים ימינה (אל הלב)
		for q in 3:
			var a := Vector2(bx + _h(k * 7 + q, 8) * 400.0, 60.0 + float(q) * 120.0)
			U.vein(pts, cols, a, a + Vector2(period * 0.8, 40.0 - float(q) * 30.0), 5.0, t, sc * 3.0 + a.x, k * 7 + q, Color("2a1012"))
	U.flush(ci, pts, cols)
	# עיניים ירוקות קטנות בפסלים (חלק מהם מסתכלים)
	if not eyes.is_empty():
		var ep := PackedVector2Array()
		var ec := PackedColorArray()
		for i in eyes.size():
			var bl := 0.4 + 0.6 * float(sin(t * 1.3 + float(i) * 2.1) > -0.6)
			U.rect(ep, ec, Rect2(eyes[i], Vector2(1.6, 1.0)), U.glow(Color(0.75, 1.0, 0.55, 0.7 * bl * clampf(U.life, 0.0, 1.0))))
		U.flush(ci, ep, ec)


# ---- קיר הזיכרון: בשר פטרייה + שרידי זיכרון מגודלים מכל האזורים ----
static func mid_memory(ci: CanvasItem, sc: float, v: Vector2, y: float, t: float) -> void:
	var period := 760.0
	var start := int(floor(sc / period)) - 1
	var pts := PackedVector2Array()
	var cols := PackedColorArray()
	var glows := []
	var lf := clampf(U.life, 0.0, 1.0)
	for k in range(start, start + int(ceil(v.x / period)) + 2):
		var bx := float(k) * period - sc
		if bx > v.x + 40.0 or bx + period < -40.0:
			continue
		# הקיר: בשר עם קפלים (גלי למעלה)
		var prev := Vector2(bx, y - 260.0)
		for q in range(1, 9):
			var px := bx + float(q) * 95.0
			var py := y - 250.0 - sin(px * 0.01 + float(k)) * 30.0 - _h(k * 9 + q, 11) * 40.0
			U.quad(pts, cols, prev, Vector2(px, py), Vector2(px, y + 10.0), Vector2(prev.x, y + 10.0), Color("3a1418"), Color("3a1418"), Color("24090e"), Color("24090e"))
			prev = Vector2(px, py)
		for q in 7:   # קפלי בשר
			var fx := bx + _h(k * 7 + q, 12) * period
			U.seg(pts, cols, Vector2(fx, y - 220.0 + _h(q, k) * 60.0), Vector2(fx + 30.0, y - 40.0), 3.0, Color(0.1, 0.02, 0.04, 0.6))
		# שריד הזיכרון של הקטע (מגודל בפטרייה)
		var kind := posmod(k, 8)
		var mx := bx + 360.0
		var my := y - 6.0
		var mc := Color("2c1a1c")
		var ml := Color("4a2a2c")
		match kind:
			0:   # מכונית (אזור 5 - המכונות שלנו)
				U.quad(pts, cols, Vector2(mx - 110, my), Vector2(mx + 110, my), Vector2(mx + 100, my - 50), Vector2(mx - 105, my - 46), ml, ml, mc, mc)
				U.quad(pts, cols, Vector2(mx - 60, my - 48), Vector2(mx + 50, my - 50), Vector2(mx + 30, my - 86), Vector2(mx - 44, my - 84), mc, mc, ml, ml)
				U.oval(pts, cols, Vector2(mx - 60, my - 4), 18, 18, Color("140608"), 10)
				U.oval(pts, cols, Vector2(mx + 62, my - 4), 18, 18, Color("140608"), 10)
				U.rect(pts, cols, Rect2(mx - 36, my - 80, 30, 26), Color("120406"))
			1:   # גולגולת לווייתן (58)
				U.quad(pts, cols, Vector2(mx - 140, my), Vector2(mx + 60, my), Vector2(mx + 40, my - 70), Vector2(mx - 120, my - 30), Color("5a5048"), Color("5a5048"), Color("3a3430"), Color("3a3430"))
				U.oval(pts, cols, Vector2(mx + 40, my - 50), 50, 44, Color("4a423a"), 12)
				U.oval(pts, cols, Vector2(mx + 30, my - 56), 12, 9, Color("140608"), 8)
			2:   # מיכל הקפאה (60)
				U.vrect(pts, cols, Rect2(mx - 30, my - 160, 60, 160), Color("2a3a3a"), Color("1a2224"))
				U.vrect(pts, cols, Rect2(mx - 22, my - 150, 44, 130), Color(0.3, 0.5, 0.45, 0.35), Color(0.2, 0.35, 0.3, 0.35))
				U.hero(pts, cols, Vector2(mx, my - 28), 1.6, 0, Color(0.05, 0.08, 0.06, 0.9))
				glows.append([Vector2(mx, my - 90), 60.0])
			3:   # מגדלור (12)
				U.quad(pts, cols, Vector2(mx - 34, my), Vector2(mx + 34, my), Vector2(mx + 18, my - 230), Vector2(mx - 18, my - 230), Color("4a3a36"), Color("4a3a36"), Color("2e2224"), Color("2e2224"))
				for s in 3:
					U.rect(pts, cols, Rect2(mx - 26 + float(s) * 3.0, my - 60 - float(s) * 60.0, 52 - float(s) * 6.0, 10), Color("5a1a1c"))
				U.rect(pts, cols, Rect2(mx - 22, my - 260, 44, 30), Color("1a0a0c"))
				glows.append([Vector2(mx, my - 246), 46.0])
			4:   # צלב מהאנדים (36)
				U.rect(pts, cols, Rect2(mx - 8, my - 200, 16, 200), Color("3a2c26"))
				U.rect(pts, cols, Rect2(mx - 60, my - 160, 120, 14), Color("3a2c26"))
				U.oval(pts, cols, Vector2(mx, my - 8), 50, 10, Color("2a1e1a"), 10)
			5:   # קרון רכבת (52)
				U.vrect(pts, cols, Rect2(mx - 150, my - 110, 300, 96), Color("3a2626"), Color("241618"))
				for s in 5:
					U.rect(pts, cols, Rect2(mx - 130 + float(s) * 56.0, my - 96, 36, 30), Color("140608"))
				U.oval(pts, cols, Vector2(mx - 100, my - 8), 14, 12, Color("140608"), 8)
				U.oval(pts, cols, Vector2(mx + 100, my - 8), 14, 12, Color("140608"), 8)
			6:   # עץ לנגה שרוף (59)
				U.quad(pts, cols, Vector2(mx - 16, my), Vector2(mx + 16, my), Vector2(mx + 6, my - 240), Vector2(mx - 6, my - 240), Color("1a1010"), Color("1a1010"), Color("120a0a"), Color("120a0a"))
				U.seg(pts, cols, Vector2(mx, my - 150), Vector2(mx + 60, my - 210), 6.0, Color("1a1010"))
				U.seg(pts, cols, Vector2(mx, my - 110), Vector2(mx - 54, my - 170), 6.0, Color("1a1010"))
			7:   # צריף בפאבלה (37)
				U.vrect(pts, cols, Rect2(mx - 70, my - 100, 140, 100), Color("4a3028"), Color("2a1a18"))
				U.tri(pts, cols, Vector2(mx - 80, my - 100), Vector2(mx + 80, my - 100), Vector2(mx, my - 140), Color("3a2220"))
				U.rect(pts, cols, Rect2(mx - 20, my - 60, 30, 60), Color("140608"))
				U.rect(pts, cols, Rect2(mx + 26, my - 80, 26, 22), Color("140608"))
		# הפטרייה עוטפת את השריד: חוטים ובלוטות
		for q in 6:
			var a := Vector2(mx - 100.0 + float(q) * 40.0, my - _h(k * 6 + q, 13) * 140.0)
			U.vein(pts, cols, a, a + Vector2((_h(q, 14) - 0.5) * 90.0, -40.0 - _h(q, 15) * 80.0), 3.0, t, sc + a.x, k * 6 + q, Color("2a1012"))
		# עצבים לאורך הקיר
		U.vein(pts, cols, Vector2(bx, y - 200.0), Vector2(bx + period, y - 180.0 + sin(float(k)) * 30.0), 6.0, t, sc + bx, k, Color("2a1012"))
	U.flush(ci, pts, cols)
	for g in glows:
		Kit.soft_glow(ci, g[0], g[1], U.glow(Color(0.6, 1.0, 0.45, (0.12 + 0.06 * U.beat) * lf)), 0.8)


# ---- וילונות שורשים, גנגליונים, קשתות צלעות, שקי נבגים שפועמים ----
static func near_flesh(ci: CanvasItem, sc: float, v: Vector2, y: float, t: float) -> void:
	var period := 680.0
	var start := int(floor(sc / period)) - 1
	var pts := PackedVector2Array()
	var cols := PackedColorArray()
	var glows := []
	var b: float = U.beat
	for k in range(start, start + int(ceil(v.x / period)) + 2):
		var bx := float(k) * period - sc
		if bx > v.x + 60.0 or bx + period < -60.0:
			continue
		# תקרה: בשר כהה עם בליטות
		U.vrect(pts, cols, Rect2(bx, 0.0, period, 50.0), Color("0a0204"), Color("1a060a"))
		for q in 6:
			U.oval(pts, cols, Vector2(bx + float(q) * 115.0 + _h(k * 6 + q, 21) * 40.0, 52.0), 50.0, 16.0 + _h(q, k) * 12.0, Color("1a060a"), 10)
		# קשת צלע של שורש (מהרצפה מעל הדרך ובחזרה)
		var ax := bx + 120.0 + _h(k, 22) * 200.0
		var prev := Vector2(ax, y)
		for q in range(1, 11):
			var u := float(q) / 10.0
			var p := Vector2(ax + u * 260.0, y - sin(u * PI) * (y - 70.0))
			U.seg(pts, cols, prev, p, 14.0 - 4.0 * sin(u * PI), Color("2a1612"))
			prev = p
		# וילון שורשים תלויים
		for q in 7:
			var hx := bx + 30.0 + float(q) * 95.0 + _h(k * 7 + q, 23) * 40.0
			var hl := 60.0 + _h(k * 7 + q, 24) * 130.0
			var sw := sin(t * 0.9 + float(q + k)) * 5.0
			U.seg(pts, cols, Vector2(hx, 40.0), Vector2(hx + sw, 40.0 + hl), 3.0 + _h(q, 25) * 3.0, Color("2a1410"))
			U.seg(pts, cols, Vector2(hx + sw, 40.0 + hl), Vector2(hx + sw * 1.6 + 6.0, 40.0 + hl + 26.0), 1.6, Color("3a1c14"))
		# שקי נבגים שפועמים עם הלב
		for q in 2:
			var sp := Vector2(bx + 200.0 + float(q) * 300.0, 90.0 + _h(k * 2 + q, 26) * 60.0)
			var r := 18.0 + 5.0 * b
			U.seg(pts, cols, Vector2(sp.x, 40.0), sp, 3.0, Color("2a1410"))
			U.oval(pts, cols, sp, r, r * 1.15, Color("3a1a14"), 12)
			U.oval(pts, cols, sp + Vector2(0, 2), r * 0.7, r * 0.8, U.glow(Color(0.5, 0.8, 0.35, 0.5 + 0.3 * b)), 10)
			glows.append(sp)
		# גנגליון (צומת עצבים) נמוך מאחורי הדרך
		var gx := bx + 470.0 + _h(k, 27) * 120.0
		U.oval(pts, cols, Vector2(gx, y - 20.0), 46.0, 28.0, Color("3a1418"), 12)
		for q in 5:
			var a := Vector2(gx, y - 24.0)
			U.vein(pts, cols, a, a + Vector2.from_angle(PI + float(q) * 0.75) * 110.0, 3.0, t, sc + gx, k * 5 + q, Color("2a1012"))
		U.oval(pts, cols, Vector2(gx, y - 26.0), 12.0 + 3.0 * b, 9.0 + 3.0 * b, U.glow(Color(0.75, 1.0, 0.55, 0.7)), 10)
	U.flush(ci, pts, cols)
	var lf := clampf(U.life, 0.0, 1.0)
	for g: Vector2 in glows:
		Kit.soft_glow(ci, g, 44.0 + 10.0 * b, U.glow(Color(0.6, 1.0, 0.45, (0.12 + 0.12 * b) * lf)), 1.0)
	DrawBatch.rect(ci, Rect2(0, y + 6.0, v.x, v.y - y), Color("12050a"))


# אובך חם מאחורי הדמויות + צל התקרה
static func heart_overlay(ci: CanvasItem, v: Vector2, t: float) -> void:
	Kit.haze_band(ci, v, 430.0, 616.0, Color(0.45, 0.16, 0.16, 0.18 + 0.06 * U.beat))
	DrawBatch.polygon(ci, PackedVector2Array([Vector2(0, 0), Vector2(v.x, 0), Vector2(v.x, 130.0), Vector2(0, 130.0)]),
		PackedColorArray([Color(0, 0, 0, 0.5), Color(0, 0, 0, 0.5), Color(0, 0, 0, 0.0), Color(0, 0, 0, 0.0)]))
	for i in 3:   # אדי נבגים שזוחלים על הרצפה (ימינה)
		var mx := fposmod(float(i) * 420.0 + t * (18.0 + float(i) * 5.0), v.x + 600.0) - 300.0
		Kit.soft_glow(ci, Vector2(mx, 594.0 + float(i % 2) * 12.0), 220.0, U.glow(Color(0.6, 0.9, 0.5, 0.05)), 0.22)


# ============================================================
#  עולם
# ============================================================

# ---- רצפה של בשר פטרייה: עצבים, שברי עצם, קשריות, שלוליות דם ונבגים. wx = x בעולם (עבה יותר ליד הלב) ----
class FleshGround extends Node2D:
	var w := 1024.0
	var depth := 90.0
	var seed_v := 0
	var wx := 0.0
	var prison := 0.0        # 0..1: אבני הכלא בכניסה
	var _t := 0.0

	func _ready() -> void:
		z_index = 1

	func _process(delta: float) -> void:
		_t += delta
		if Engine.get_process_frames() % 6 == 0 and Art.on_screen(self, global_position + Vector2(w * 0.5, 0), w * 0.5 + 40.0):
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
		var thick := clampf((wx - 1000.0) / 8000.0, 0.0, 1.0)
		U.rect(pts, cols, Rect2(0, 0, w, depth), Color("14060a"))
		U.vrect(pts, cols, Rect2(0, 0, w, 18.0), Color("5a2228"), Color("3a1418"))
		U.rect(pts, cols, Rect2(0, 0, w, 2.0), Color(0.85, 0.45, 0.42, 0.55))
		U.rect(pts, cols, Rect2(0, 18.0, w, 6.0), Color("22080c"))
		if prison > 0.0:   # אבני הכלא (הפרסידיו) שהבשר בולע
			var x := 0.0
			while x < w * prison:
				U.vrect(pts, cols, Rect2(x + 1.0, 1.0, 58.0, 15.0), Color("4a4448"), Color("2e2a2e"))
				U.rect(pts, cols, Rect2(x + 1.0, 1.0, 58.0, 1.5), Color(0.75, 0.72, 0.7, 0.5))
				x += 60.0
		# גלי בשר (קפלים) + חוטי עצבים לאורך הרצפה
		for i in int(w / 60.0):
			var p := Vector2(r.randf_range(0.0, w), r.randf_range(4.0, 14.0))
			U.oval(pts, cols, p, r.randf_range(14.0, 30.0), r.randf_range(2.0, 4.0), Color(0.5, 0.18, 0.2, 0.5), 8)
		for i in int(w / 260.0) + 1:
			var a := Vector2(r.randf_range(0.0, w - 200.0), r.randf_range(2.0, 8.0))
			U.vein(pts, cols, a, a + Vector2(r.randf_range(120.0, 260.0), r.randf_range(-3.0, 3.0)), 2.6 + 2.0 * thick, _t, wx + a.x, seed_v % 97 + i, Color("3a1c16"))
		# שברי עצם ושיניים (מכל מי שמת כאן)
		for i in int(w / 120.0):
			var p := Vector2(r.randf_range(0.0, w), r.randf_range(-1.0, 6.0))
			if r.randf() < 0.5:
				U.seg(pts, cols, p, p + Vector2(r.randf_range(8.0, 18.0), r.randf_range(-3.0, 1.0)), 2.6, BONE_D)
			else:
				U.oval(pts, cols, p, 3.5, 2.5, BONE, 6)
		# קשריות זוהרות (יותר ליד הלב) - פועמות עם הלב
		var b: float = U.beat
		for i in int(w / 80.0 * (0.3 + thick)):
			var p := Vector2(r.randf_range(0.0, w), r.randf_range(-2.0, 4.0))
			var rr := r.randf_range(2.5, 5.0) * (1.0 + 0.25 * b)
			U.oval(pts, cols, p, rr * 1.3, rr, Color("3a5a2a"), 8)
			U.oval(pts, cols, p + Vector2(0, -0.5), rr * 0.6, rr * 0.5, U.glow(Color(0.75, 1.0, 0.55, 0.55 + 0.4 * b)), 6)
		# שלוליות דם ונוזל נבגים
		for i in int(w / 300.0):
			var p := Vector2(r.randf_range(0.0, w), r.randf_range(3.0, 9.0))
			U.oval(pts, cols, p, r.randf_range(14.0, 30.0), r.randf_range(2.0, 3.4), Color(0.38, 0.03, 0.05, 0.6) if i % 2 == 0 else Color(0.4, 0.7, 0.3, 0.25), 8)
		U.flush(self, pts, cols)


# ---- הכניסה: שער הכלא שהפטרייה בלעה, שלט אכול, שרשראות, ו"WELCOME HOME, ZERO" חרוט בפטרייה על הקיר ----
class Threshold extends Node2D:
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
		# פיר הירידה מהכלא: קיר אבן, וחור למעלה שדרכו נכנס אור לבן חלש
		U.vrect(pts, cols, Rect2(-60.0, -720.0, 300.0, 720.0), Color("2a2428"), Color("3a3034"))
		for q in 12:   # שורות אבנים
			U.rect(pts, cols, Rect2(-60.0, -700.0 + float(q) * 58.0, 300.0, 2.0), Color(0.1, 0.08, 0.1, 0.7))
		U.quad(pts, cols, Vector2(40, -720), Vector2(160, -720), Vector2(200, -420), Vector2(0, -420), Color(0.85, 0.88, 0.95, 0.16), Color(0.85, 0.88, 0.95, 0.16), Color(0.85, 0.88, 0.95, 0.0), Color(0.85, 0.88, 0.95, 0.0))
		# שרשראות תלויות מהכלא
		for q in 3:
			var cx := 30.0 + float(q) * 70.0
			var l := 260.0 + float(q) * 70.0
			var yy := -720.0
			while yy < -720.0 + l:
				U.oval(pts, cols, Vector2(cx + sin(_t * 0.7 + float(q)) * 3.0 * (yy + 720.0) / l, yy), 3.0, 5.0, Color("4a3a30"), 6)
				yy += 9.0
		# סורגי השער (חלודים, כפופים) והבשר שבלע אותם
		var gx := 280.0
		U.rect(pts, cols, Rect2(gx - 10.0, -330.0, 220.0, 16.0), RUST)
		for q in 8:
			var bxp := gx + float(q) * 27.0
			var bend := (12.0 if q in [3, 4] else 0.0)
			U.seg(pts, cols, Vector2(bxp, -320.0), Vector2(bxp + bend, -150.0), 5.0, RUST.darkened(0.2))
			U.seg(pts, cols, Vector2(bxp + bend, -150.0), Vector2(bxp + bend * 2.6, 0.0), 5.0, RUST.darkened(0.3))
		U.oval(pts, cols, Vector2(gx + 100.0, -40.0), 150.0, 46.0, FLESH, 16)
		U.oval(pts, cols, Vector2(gx + 30.0, -300.0), 70.0, 40.0, FLESH, 12)
		for q in 7:
			var a := Vector2(gx + float(q) * 30.0, -10.0)
			U.vein(pts, cols, a, a + Vector2((U.h(q, 3) - 0.5) * 80.0, -150.0 - U.h(q, 4) * 150.0), 4.0, _t, global_position.x + a.x, q, Color("3a1c16"))
		# שלט הכלא אכול
		var sp := Vector2(560.0, -300.0)
		U.quad(pts, cols, sp, sp + Vector2(240, -8), sp + Vector2(236, 46), sp + Vector2(4, 52), Color("3a3a40"), Color("3a3a40"), Color("2a2a30"), Color("2a2a30"))
		U.oval(pts, cols, sp + Vector2(200, 20), 60.0, 40.0, FLESH, 12)
		# הקיר עם הכתובת: גבשושית בשר שצמחה על הקיר (שפה עליונה גלית, קפלים, עורקים)
		var prev := Vector2(840.0, 0.0)
		for q in range(1, 15):
			var wx0 := 840.0 + float(q) * 44.0
			var top := -330.0 - sin(float(q) * 0.45) * 70.0 - U.h(q, 21) * 30.0
			if q == 14:
				top = 0.0
			var ptop := prev if q > 1 else Vector2(840.0, -40.0)
			U.quad(pts, cols, ptop, Vector2(wx0, top), Vector2(wx0, 0.0), Vector2(ptop.x, 0.0), Color("3a1218"), Color("3a1218"), Color("1e070a"), Color("1e070a"))
			U.seg(pts, cols, ptop, Vector2(wx0, top), 5.0, Color("5a2228"))
			prev = Vector2(wx0, top)
		for q in 9:   # קפלים
			var fx := 880.0 + float(q) * 58.0
			U.seg(pts, cols, Vector2(fx, -290.0 + U.h(q, 22) * 60.0), Vector2(fx + 18.0, -20.0), 6.0, Color(0.1, 0.02, 0.04, 0.5))
		for q in 5:
			var a := Vector2(870.0 + float(q) * 110.0, -10.0)
			U.vein(pts, cols, a, a + Vector2(40.0, -260.0 - U.h(q, 23) * 60.0), 5.0, _t, global_position.x + a.x, q + 30, Color("2e1012"))
		U.flush(self, pts, cols)
		var f := ThemeDB.fallback_font
		DrawBatch.string(self, f, sp + Vector2(14, 30), "PRESIDIO DE USH", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(0.75, 0.72, 0.68, 0.8))
		var pul := 0.6 + 0.4 * sin(_t * 2.0)
		var gc := U.glow(Color(0.75, 1.0, 0.55, 0.55 + 0.35 * pul))
		Kit.soft_glow(self, Vector2(1120.0, -230.0), 220.0, U.glow(Color(0.6, 1.0, 0.45, 0.08 + 0.05 * pul)), 0.5)
		DrawBatch.string_outline(self, f, Vector2(932.0, -236.0), "WELCOME HOME", HORIZONTAL_ALIGNMENT_LEFT, -1, 40, 4, Color(0.05, 0.1, 0.03, 0.6))
		DrawBatch.string(self, f, Vector2(932.0, -236.0), "WELCOME HOME", HORIZONTAL_ALIGNMENT_LEFT, -1, 40, gc)
		DrawBatch.string_outline(self, f, Vector2(1050.0, -170.0), "ZERO", HORIZONTAL_ALIGNMENT_LEFT, -1, 52, 4, Color(0.05, 0.1, 0.03, 0.6))
		DrawBatch.string(self, f, Vector2(1050.0, -170.0), "ZERO", HORIZONTAL_ALIGNMENT_LEFT, -1, 52, gc)


# ---- פסל פטרייה של הגיבור (החזרות של הכוורת). pose: 0 מכוון, 1 כורע, 2 מתגלגל, 3 קופץ ----
class Statue extends Node2D:
	var pose := 0
	var face := 1.0
	var size := 1.0
	var cracked := 0.0           # (HOLLOW שהתעורר ליד) סדוק
	var seed_v := 0

	func _ready() -> void:
		z_index = -1

	func _draw() -> void:
		DrawBatch.begin(self)
		_draw_b()
		DrawBatch.end(self)

	func _draw_b() -> void:
		var pts := PackedVector2Array()
		var cols := PackedColorArray()
		U.oval(pts, cols, Vector2(0, -3.0), 30.0 * size, 7.0 * size, Color("2a1014"), 10)   # בסיס של בשר
		U.hero(pts, cols, Vector2(0, -4.0), 1.15 * size, pose, Color("3c3430"), face)
		U.hero(pts, cols, Vector2(-1.2 * face, -5.0), 1.08 * size, pose, Color("524840"), face)   # אור על הצד
		for q in 4:   # חוטי פטרייה על הפסל
			var a := Vector2((U.h(seed_v + q, 1) - 0.5) * 16.0 * size, -U.h(seed_v + q, 2) * 50.0 * size)
			U.seg(pts, cols, a, a + Vector2(U.h(q, 3) * 8.0 - 4.0, 12.0), 1.4, Color("3a5a2a"))
		if cracked > 0.0:
			U.seg(pts, cols, Vector2(-4, -50), Vector2(3, -30), 1.2, Color(0.1, 0.05, 0.05))
			U.seg(pts, cols, Vector2(3, -30), Vector2(-2, -12), 1.2, Color(0.1, 0.05, 0.05))
		U.flush(self, pts, cols)


# ============================================================
#  שק רחם עם HOLLOW בפנים (enemies/types/hollow.gd). תלוי מהתקרה על חבל-שורש עד הרצפה. ripen() = מתנפח ופועם,
#  burst() = מתפקע (קרום קרוע נשאר). hold = רק כשהשלב / הבוס מחליטים (אולם המראות, זירת ה-ROOT).
# ============================================================
class HollowPod extends Node2D:
	const RIPE_T := 0.9
	const SAC := Vector2(30.0, 50.0)
	enum {GROW, RIPE, OPEN}
	var z = null                    # ה-HOLLOW שבפנים
	var state := GROW
	var bursts := 0                 # לבדיקות
	var _t := 0.0
	var _st := 0.0

	func _ready() -> void:
		z_index = 4                 # הקרום מקדימה (מעל ה-HOLLOW, z 3)
		add_to_group("s63_pods")

	func closed() -> bool:
		return state != OPEN

	func ripen() -> void:
		if state != GROW:
			return
		state = RIPE
		_st = RIPE_T
		Sfx.play("s63_squelch", global_position + Vector2(0, -50), -2.0, 0.15, 2)

	func burst() -> void:
		if state == OPEN:
			return
		state = OPEN
		bursts += 1
		Sfx.play("s63_burst", global_position + Vector2(0, -50), 0.0, 0.12, 3)
		if Art.on_screen(self, global_position, 80.0):
			Particles.burst(get_parent(), global_position + Vector2(0, -50), "drop", Vector2.UP, int(10.0 * Quality.gore()) + 2)
			Particles.burst(get_parent(), global_position + Vector2(0, -50), "mist", Vector2.UP, 4)
		if z != null and is_instance_valid(z) and z.type_mod != null:
			z.type_mod.release()
		queue_redraw()

	func _process(delta: float) -> void:
		_t += delta
		if state == RIPE:
			_st -= delta
			if _st <= 0.0:
				burst()
		if Engine.get_process_frames() % 3 == 0 and Art.on_screen(self, global_position + Vector2(0, -120), 140.0):
			queue_redraw()

	func _draw() -> void:
		DrawBatch.begin(self)
		_draw_b()
		DrawBatch.end(self)

	func _draw_b() -> void:
		var pts := PackedVector2Array()
		var cols := PackedColorArray()
		var b: float = U.beat
		var c := Vector2(0, -56.0)
		# חבל השורש מהתקרה
		U.seg(pts, cols, Vector2(0, -600.0), c + Vector2(0, -SAC.y), 6.0, Color("2a1410"))
		U.seg(pts, cols, Vector2(6, -600.0), c + Vector2(8, -SAC.y + 4.0), 3.0, Color("3a1c14"))
		if state == OPEN:   # קרום קרוע, נוזל על הרצפה
			U.oval(pts, cols, Vector2(0, -2.0), 40.0, 5.0, Color(0.4, 0.6, 0.3, 0.45), 10)
			for s: float in [-1.0, 1.0]:
				U.quad(pts, cols, c + Vector2(s * 6.0, -SAC.y), c + Vector2(s * SAC.x, -SAC.y * 0.4), c + Vector2(s * (SAC.x + 6.0), -6.0), c + Vector2(s * 12.0, -SAC.y * 0.5), Color(0.55, 0.3, 0.3, 0.75), Color(0.55, 0.3, 0.3, 0.6), Color(0.45, 0.2, 0.22, 0.4), Color(0.55, 0.3, 0.3, 0.6))
			U.flush(self, pts, cols)
			return
		var swell := 1.0 + 0.04 * b + (0.12 * (1.0 - _st / RIPE_T) + 0.05 * sin(_t * 30.0) if state == RIPE else 0.0)
		U.oval(pts, cols, Vector2(0, -2.0), 34.0, 6.0, Color(0.3, 0.08, 0.1, 0.8), 10)
		# הקרום: שקוף-ורדרד עם ורידים (ה-HOLLOW נראה מבפנים)
		U.oval(pts, cols, c, SAC.x * swell, SAC.y * swell, Color(0.75, 0.42, 0.42, 0.28), 18)
		U.oval(pts, cols, c + Vector2(-SAC.x * 0.35, -SAC.y * 0.4), SAC.x * 0.25, SAC.y * 0.3, Color(1.0, 0.85, 0.85, 0.16), 10)
		for q in 5:
			var a := c + Vector2((U.h(q, 7) - 0.5) * SAC.x * 1.4, -SAC.y * 0.85)
			U.seg(pts, cols, a, a + Vector2((U.h(q, 8) - 0.5) * 20.0, SAC.y * 1.5), 1.2, Color(0.6, 0.15, 0.18, 0.55))
		U.oval(pts, cols, c + Vector2(0, SAC.y * 0.85), 14.0, 6.0, Color(0.5, 0.18, 0.2, 0.7), 10)   # טבור
		if state == RIPE:
			for q in 4:
				var a := c + Vector2.from_angle(float(q) * 1.6 + 0.4) * SAC.x * 0.7
				U.seg(pts, cols, a, a + Vector2.from_angle(float(q) * 1.6 + 0.9) * 12.0, 1.4, Color(1.0, 0.9, 0.85, 0.6))
		U.flush(self, pts, cols)
		Kit.soft_glow(self, c, 40.0, U.glow(Color(0.6, 1.0, 0.45, 0.1 + 0.08 * b)), 1.2)


# ---- מדף שורש / גשר עצם (הקומה = add_floor בשלב). עורקים תומכים מלמטה ----
class RootShelf extends Node2D:
	var w := 300.0
	var tier := 170.0
	var bone := false
	var _t := 0.0

	func _ready() -> void:
		z_index = 2

	func _process(delta: float) -> void:
		_t += delta
		if Engine.get_process_frames() % 6 == 0 and Art.on_screen(self, global_position + Vector2(w * 0.5, -tier), w * 0.5 + 60.0):
			queue_redraw()

	func _draw() -> void:
		DrawBatch.begin(self)
		_draw_b()
		DrawBatch.end(self)

	func _draw_b() -> void:
		var pts := PackedVector2Array()
		var cols := PackedColorArray()
		var top := -tier
		if bone:   # גשר של צלעות לווייתן מכוסות בשר
			U.vrect(pts, cols, Rect2(0, top, w, 12.0), BONE, BONE_D)
			for q in int(w / 26.0):
				U.rect(pts, cols, Rect2(float(q) * 26.0, top, 2.0, 12.0), Color(0.3, 0.26, 0.2, 0.6))
		else:
			U.vrect(pts, cols, Rect2(0, top, w, 14.0), Color("5a2a26"), Color("2e1214"))
			U.rect(pts, cols, Rect2(0, top, w, 2.0), Color(0.9, 0.55, 0.5, 0.5))
			for q in int(w / 30.0):   # בליטות בשר מתחת
				U.oval(pts, cols, Vector2(15.0 + float(q) * 30.0, top + 14.0), 15.0, 7.0 + U.h(q, 3) * 6.0, Color("3a1418"), 8)
		# שורשים תומכים יורדים לרצפה + שורשים תלויים
		for s in 2:
			var sx := 30.0 + float(s) * (w - 60.0)
			U.quad(pts, cols, Vector2(sx - 10.0, top + 10.0), Vector2(sx + 10.0, top + 10.0), Vector2(sx + 18.0, 0), Vector2(sx - 18.0, 0), Color("3a1c16"), Color("3a1c16"), Color("24100c"), Color("24100c"))
		for q in int(w / 40.0):
			var hx := 20.0 + float(q) * 40.0
			U.seg(pts, cols, Vector2(hx, top + 12.0), Vector2(hx + sin(_t + float(q)) * 3.0, top + 30.0 + U.h(q, 4) * 30.0), 2.0, Color("3a1c14"))
		U.vein(pts, cols, Vector2(0, top + 4.0), Vector2(w, top + 6.0), 3.0, _t, global_position.x, 3, Color("3a1c16"))
		U.flush(self, pts, cols)


# ---- פה של עורק בתקרה: משם יוצאים PILGRIM, ואליו הם חוזרים. pulse() = נפתח לרגע ----
class VeinMouth extends Node2D:
	var _t := 0.0
	var _open := 0.0

	func _ready() -> void:
		z_index = -1
		add_to_group("s63_mouths")

	func pulse() -> void:
		_open = 1.0
		Sfx.play("s63_squelch", global_position, -6.0, 0.15, 2, 0.8)

	func _process(delta: float) -> void:
		_t += delta
		_open = move_toward(_open, 0.0, delta * 0.8)
		if Engine.get_process_frames() % 3 == 0 and Art.on_screen(self, global_position, 120.0):
			queue_redraw()

	func _draw() -> void:
		DrawBatch.begin(self)
		_draw_b()
		DrawBatch.end(self)

	func _draw_b() -> void:
		var pts := PackedVector2Array()
		var cols := PackedColorArray()
		var b: float = U.beat
		U.seg(pts, cols, Vector2(-60, -140), Vector2(-10, -10), 26.0, Color("3a1418"))   # העורק יורד מהתקרה
		U.seg(pts, cols, Vector2(70, -150), Vector2(14, -8), 18.0, Color("3a1418"))
		U.oval(pts, cols, Vector2.ZERO, 46.0, 24.0, Color("4a1a1e"), 14)
		var op := 0.35 + 0.65 * _open + 0.1 * b
		U.oval(pts, cols, Vector2(0, 6.0), 30.0 * op, 12.0 * op, Color("0a0204"), 12)
		U.oval(pts, cols, Vector2(0, 6.0), 18.0 * op, 7.0 * op, U.glow(Color(0.75, 1.0, 0.55, 0.5 + 0.5 * _open)), 10)
		for q in 6:   # שפתיים / קפלים
			var a := Vector2.from_angle(float(q) / 6.0 * TAU) * Vector2(40.0, 20.0)
			U.seg(pts, cols, a, a * 0.6, 3.0, Color("6a2a2e"))
		U.flush(self, pts, cols)
		Kit.soft_glow(self, Vector2(0, 10), 50.0 + 40.0 * _open, U.glow(Color(0.6, 1.0, 0.45, 0.1 + 0.25 * _open)), 0.8)


# ============================================================
#  קרום בשר שנסגר כמו סוגר (אולם המראות): seal() = גדל ונסגר (מוצק, אי אפשר לעבור או לירות דרכו), unseal() = נפתח.
#  כשהוא נסגר הוא דוחף זומבים ואת השחקן לצד שלהם (inside = לאיזה צד השחקן נדחף)
# ============================================================
class Membrane extends Node2D:
	const W := 40.0
	const H := 680.0
	const CLOSE_T := 0.7
	const OPEN_T := 1.0
	enum {OPEN, CLOSING, SHUT, OPENING}
	var state := OPEN
	var k := 0.0                    # 0 = פתוח, 1 = סגור
	var inside := 1.0
	var _t := 0.0
	var _body: StaticBody2D = null
	var _cs: CollisionShape2D = null

	func _ready() -> void:
		z_index = 3   # מאחורי השחקן (4): הוא נדחף אל הקרום ולא נעלם בתוכו
		add_to_group("s63_membranes")
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

	func is_closed() -> bool:
		return state == SHUT or state == CLOSING

	func seal() -> void:
		if state == SHUT or state == CLOSING:
			return
		state = CLOSING
		Sfx.play("s63_membrane", global_position + Vector2(0, -120), 2.0, 0.1, 2)
		_cs.set_deferred("disabled", false)
		_push()

	func unseal() -> void:
		if state == OPEN or state == OPENING:
			return
		state = OPENING
		Sfx.play("s63_membrane", global_position + Vector2(0, -120), 0.0, 0.1, 2, 0.8)
		_cs.set_deferred("disabled", true)

	# מי שעומד בתוך הקרום כשהוא נסגר - נדחף החוצה
	func _push() -> void:
		var pl := get_tree().get_first_node_in_group("player") as Node2D
		if pl != null and absf(pl.global_position.x - global_position.x) < W:
			pl.global_position.x = global_position.x + inside * (W + 16.0)
			pl.reset_physics_interpolation()
		for zz in get_tree().get_nodes_in_group("zombies"):
			if absf(zz.global_position.x - global_position.x) < W and not zz.is_boss():
				zz.global_position.x = global_position.x - inside * (W + 20.0)

	func _process(delta: float) -> void:
		_t += delta
		match state:
			CLOSING:
				k = move_toward(k, 1.0, delta / CLOSE_T)
				if k >= 1.0:
					state = SHUT
			OPENING:
				k = move_toward(k, 0.0, delta / OPEN_T)
				if k <= 0.0:
					state = OPEN
		if Engine.get_process_frames() % 2 == 0 and Art.on_screen(self, global_position + Vector2(0, -300), 360.0):
			queue_redraw()

	func _draw() -> void:
		DrawBatch.begin(self)
		_draw_b()
		DrawBatch.end(self)

	func _draw_b() -> void:
		var pts := PackedVector2Array()
		var cols := PackedColorArray()
		var b: float = U.beat
		# המסגרת: שתי שפות בשר עבות (תמיד)
		for s: float in [-1.0, 1.0]:
			U.quad(pts, cols, Vector2(s * 26.0, 0), Vector2(s * 50.0, 0), Vector2(s * 44.0, -H), Vector2(s * 20.0, -H), Color("4a1a1e"), Color("2a0c10"), Color("2a0c10"), Color("4a1a1e"))
			for q in 8:
				U.oval(pts, cols, Vector2(s * 36.0, -40.0 - float(q) * 80.0), 16.0, 30.0, Color("5a2226"), 8)
		if k > 0.01:   # הקרום נסגר מהצדדים לאמצע (סיבים, ורידים, פועם)
			var kk := k * k * (3.0 - 2.0 * k)
			for s: float in [-1.0, 1.0]:
				var inner := s * 26.0 * (1.0 - kk)
				U.quad(pts, cols, Vector2(s * 26.0, 0), Vector2(inner, 0), Vector2(inner, -H), Vector2(s * 26.0, -H), Color(0.45, 0.14, 0.16, 0.95), Color(0.6, 0.22, 0.24, 0.95), Color(0.6, 0.22, 0.24, 0.95), Color(0.45, 0.14, 0.16, 0.95))
			if kk > 0.9:
				for q in 10:
					var yy := -30.0 - float(q) * 64.0
					U.seg(pts, cols, Vector2(-20, yy), Vector2(20, yy - 18.0), 1.6, Color(0.3, 0.05, 0.08, 0.7))
				U.seg(pts, cols, Vector2(0, 0), Vector2(0, -H), 2.0, Color(0.25, 0.04, 0.06, 0.9))
				for q in 6:
					U.oval(pts, cols, Vector2(sin(float(q) * 2.3) * 8.0, -60.0 - float(q) * 100.0), 4.0 + 2.0 * b, 4.0 + 2.0 * b, U.glow(Color(0.75, 1.0, 0.55, 0.7)), 8)
		U.flush(self, pts, cols)


# ---- הקיר האחורי של אולם המראות (בוס האמצע): קרום מבריק, מאות צלליות של הגיבור, "SUBJECT ZERO" ----
class MirrorHall extends Node2D:
	var w := 900.0
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
		U.vrect(pts, cols, Rect2(0, -560.0, w, 560.0), Color("1a080c"), Color("2a0e12"))
		# המראה: קרום כהה ומבריק עם השתקפויות
		var m := Rect2(80.0, -470.0, w - 160.0, 400.0)
		U.vrect(pts, cols, m, Color("0e1416"), Color("1a2224"))
		for q in 6:
			var sx := m.position.x + 60.0 + float(q) * (m.size.x - 120.0) / 5.0
			U.quad(pts, cols, Vector2(sx, m.position.y), Vector2(sx + 30.0, m.position.y), Vector2(sx - 40.0, m.end.y), Vector2(sx - 70.0, m.end.y), Color(1, 1, 1, 0.05), Color(1, 1, 1, 0.05), Color(1, 1, 1, 0.0), Color(1, 1, 1, 0.0))
		# שורות של צלליות הגיבור בתוך המראה (כמו המון בקצה מסדרון)
		for row in 4:
			var ry := m.end.y - 20.0 - float(row) * 34.0
			var s := 1.0 - float(row) * 0.2
			var n := 9 + row * 3
			for q in n:
				var hx := m.position.x + 30.0 + float(q) * (m.size.x - 60.0) / float(n - 1)
				U.hero(pts, cols, Vector2(hx, ry), s, int(U.h(row * 20 + q, 9) * 2.0) * 0, Color(0.03, 0.05, 0.05, 0.85 - 0.12 * float(row)), 1.0 if q % 2 == 0 else -1.0)
		# המסגרת: שורשים ועצם
		for s: float in [0.0, 1.0]:
			U.rect(pts, cols, Rect2(m.position.x - 18.0 + s * (m.size.x + 18.0), m.position.y - 18.0, 18.0, m.size.y + 36.0), Color("3a1c16"))
		U.rect(pts, cols, Rect2(m.position.x - 18.0, m.position.y - 18.0, m.size.x + 36.0, 18.0), Color("3a1c16"))
		for q in 10:
			var a := Vector2(m.position.x + U.h(q, 31) * m.size.x, m.position.y - 10.0)
			U.vein(pts, cols, a, a + Vector2((U.h(q, 32) - 0.5) * 120.0, 60.0 + U.h(q, 33) * 120.0), 4.0, _t, global_position.x + a.x, q, Color("3a1c16"))
		U.flush(self, pts, cols)
		var pul := 0.6 + 0.4 * sin(_t * 1.6)
		DrawBatch.string(self, ThemeDB.fallback_font, Vector2(w * 0.5 - 150.0, m.position.y - 30.0), "SUBJECT ZERO", HORIZONTAL_ALIGNMENT_LEFT, -1, 40, U.glow(Color(0.75, 1.0, 0.55, 0.45 + 0.3 * pul)))


# ============================================================
#  מלכודת: שסתום עורק ברצפה. עובד בקצב הלב: beat(n) - בפעימה לפני ההתפרצות מתנפח וזוהר (אזהרה), בפעימה שלו מתפרץ:
#  עמוד דם ונבגים (HGT). השחקן נפגע (DMG) ועף למעלה; זומבים נפגעים (DMG_Z) ועפים. ירייה בסוגר (ValveBody) = מתפרץ עכשיו
#  (חצי זמן אזהרה) - אפשר להעיף קבוצה. EVERY = כל כמה פעימות.
# ============================================================
class HeartValve extends Node2D:
	const EVERY := 3
	const WARN_T := 0.55
	const BLAST_T := 0.7
	const HALF_W := 46.0
	const HGT := 190.0
	const DMG := 1
	const DMG_Z := 26
	const LAUNCH := 620.0
	enum {IDLE, WARN, BLAST}
	var state := IDLE
	var phase := 0                  # באיזו פעימה (מודולו EVERY) הוא מתפרץ
	var blasts := 0                 # לבדיקות
	var hits := 0
	var z_hits := 0
	var _t := 0.0
	var _st := 0.0
	var _hit := false
	var _hit_z := {}
	var _said := false
	var _body: StaticBody2D = null

	func _ready() -> void:
		z_index = 2
		add_to_group("hazards")
		add_to_group("blastable")
		add_to_group("s63_valves")
		_body = ValveBody.new()
		_body.trap = self
		_body.collision_layer = 4
		_body.collision_mask = 0
		_body.add_to_group("no_outline")
		var cs := CollisionShape2D.new()
		var rs := RectangleShape2D.new()
		rs.size = Vector2(44, 18)
		cs.shape = rs
		_body.add_child(cs)
		_body.position = Vector2(0, -9.0)
		add_child(_body)

	func world_rect() -> Rect2:
		return Rect2(global_position + Vector2(-HALF_W, -HGT), Vector2(HALF_W * 2.0, HGT))

	func danger_at(p: Vector2, margin := 0.0) -> bool:
		return state != IDLE and world_rect().grow(margin).has_point(p)

	func blast_rect() -> Rect2:
		return Rect2(global_position + Vector2(-24.0, -20.0), Vector2(48.0, 20.0))

	func hit_by_blast(_c: Vector2, _r: float) -> void:
		trigger(true)

	# השלב קורא בכל פעימה של הלב
	func beat(n: int) -> void:
		if state != IDLE:
			return
		var pl := get_tree().get_first_node_in_group("player") as Node2D
		if pl == null or absf(pl.global_position.x - global_position.x) > 1100.0:
			return
		if posmod(n + 1, EVERY) == phase:
			trigger()

	func trigger(quick := false) -> void:
		if state != IDLE:
			return
		state = WARN
		_st = WARN_T * (0.5 if quick else 1.0)
		Sfx.play("s63_gurgle", global_position + Vector2(0, -20), -2.0, 0.1, 2)

	func _process(delta: float) -> void:
		_t += delta
		var pl := get_tree().get_first_node_in_group("player") as Node2D
		match state:
			WARN:
				_st -= delta
				if _st <= 0.0:
					state = BLAST
					_st = BLAST_T
					_hit = false
					_hit_z.clear()
					blasts += 1
					Sfx.play("s63_geyser", global_position + Vector2(0, -60), 2.0, 0.1, 2)
					if Art.on_screen(self, global_position, 80.0):
						Particles.burst(get_parent(), global_position + Vector2(0, -20), "drop", Vector2.UP, int(10.0 * Quality.gore()) + 3)
						Particles.burst(get_parent(), global_position + Vector2(0, -40), "mist", Vector2.UP, 4)
			BLAST:
				_st -= delta
				var wr := world_rect()
				if not _hit and pl != null and not pl.dead and wr.intersects(pl.body_rect()):
					_hit = true
					hits += 1
					pl.hurt(DMG, Vector2(0.0, -1.0))
					pl.velocity.y = -LAUNCH
					if not _said:
						_said = true
						U.say(pl, "The floor beats with the heart... watch the valves swell.", Color("ffb0a0"))
				if Engine.get_physics_frames() % 3 == 0:
					for zz in get_tree().get_nodes_in_group("zombies"):
						if zz.dead or zz.is_boss() or _hit_z.has(zz.get_instance_id()):
							continue
						if wr.has_point(zz.global_position + Vector2(0, -10)):
							_hit_z[zz.get_instance_id()] = true
							z_hits += 1
							zz.velocity.y = -LAUNCH * 0.8
							zz.take_damage(DMG_Z, zz.global_position + Vector2(0, -30), Vector2.UP, true, {"source": "trap"})
				if _st <= 0.0:
					state = IDLE
		if Art.on_screen(self, global_position + Vector2(0, -80), 140.0) and (state != IDLE or Engine.get_process_frames() % 3 == 0):
			queue_redraw()

	func _draw() -> void:
		DrawBatch.begin(self)
		_draw_b()
		DrawBatch.end(self)

	func _draw_b() -> void:
		var pts := PackedVector2Array()
		var cols := PackedColorArray()
		var b: float = U.beat
		var swell := 1.0 + 0.08 * b
		if state == WARN:
			swell = 1.25 + 0.15 * sin(_t * 40.0)
		# הסוגר: טבעת בשר בולטת עם חור
		U.oval(pts, cols, Vector2(0, -4.0), 44.0 * swell, 12.0 * swell, Color("5a2024"), 14)
		U.oval(pts, cols, Vector2(0, -6.0), 26.0 * swell, 7.0 * swell, Color("2a080c"), 12)
		for q in 8:
			var a := Vector2.from_angle(float(q) / 8.0 * TAU) * Vector2(38.0, 10.0) * swell + Vector2(0, -5.0)
			U.seg(pts, cols, a, a * 0.55 + Vector2(0, -2.0), 2.0, Color("7a3034"))
		if state == WARN:
			U.oval(pts, cols, Vector2(0, -7.0), 18.0, 5.0, Color(1.0, 0.35, 0.3, 0.6 + 0.4 * sin(_t * 30.0)), 10)
		elif state == BLAST:   # עמוד דם ונבגים
			var k := clampf(_st / BLAST_T, 0.0, 1.0)
			var hh := HGT * (0.6 + 0.4 * k)
			for q in 3:
				var ww := (HALF_W - float(q) * 10.0) * (0.7 + 0.3 * k)
				var c := [Color(0.5, 0.05, 0.08, 0.7 * k), Color(0.75, 0.12, 0.14, 0.75 * k), U.glow(Color(0.7, 1.0, 0.5, 0.5 * k))][q] as Color
				U.quad(pts, cols, Vector2(-ww * 0.6, -6.0), Vector2(ww * 0.6, -6.0), Vector2(ww + sin(_t * 20.0 + float(q)) * 6.0, -hh + float(q) * 14.0), Vector2(-ww + cos(_t * 17.0 + float(q)) * 6.0, -hh + float(q) * 14.0), c, c, Color(c, 0.0), Color(c, 0.0))
			for q in 10:
				var dp := Vector2((U.h(q, 41) - 0.5) * HALF_W * 1.6, -fposmod(U.h(q, 42) * hh + _t * 420.0, hh))
				U.oval(pts, cols, dp, 3.0, 4.0, Color(0.6, 0.06, 0.08, 0.8 * k), 6)
		U.flush(self, pts, cols)


class ValveBody extends StaticBody2D:
	var trap = null

	func take_damage(_amount: int, hit_pos: Vector2, dir: Vector2, _explosive := false, _src := {}) -> void:
		if trap != null and is_instance_valid(trap):
			Particles.burst(trap.get_parent(), hit_pos, "drop", -dir, 4)
			Sfx.play("hit", hit_pos, -4.0, 0.1, 2)
			if trap.has_method("trigger"):
				trap.trigger(true)
			elif trap.has_method("shot"):
				trap.shot()


# ============================================================
#  מלכודת: שורש חבוי ברצפה. השחקן מתקרב (NEAR_R) -> הרצפה מתגלגלת (רמז), נכנס (TRIG_R) -> TELL_T -> השורשים לופתים:
#  נזק (DMG) + האטה (SLOW_T), "ROOTED". זומבי שעולה עליו - נתפס (HOLD_T, לא זז). ירייה בפקעת (ValveBody) = השורש מת.
#  חוזר אחרי CD.
# ============================================================
class RootSnare extends Node2D:
	const NEAR_R := 170.0
	const TRIG_R := 34.0
	const TELL_T := 0.32
	const GRIP_T := 0.9
	const CD := 3.5
	const DMG := 1
	const SLOW_T := 1.4
	const HOLD_T := 2.0
	enum {HIDDEN, TELL, GRIP, DEAD}
	var state := HIDDEN
	var grips := 0                  # לבדיקות
	var held := 0
	var _t := 0.0
	var _st := 0.0
	var _cd := 0.0
	var _near := 0.0
	var _said := false
	var _body: StaticBody2D = null

	func _ready() -> void:
		z_index = 2
		add_to_group("hazards")
		add_to_group("s63_snares")
		_body = ValveBody.new()
		_body.trap = self
		_body.collision_layer = 4
		_body.collision_mask = 0
		_body.add_to_group("no_outline")
		var cs := CollisionShape2D.new()
		var rs := RectangleShape2D.new()
		rs.size = Vector2(22, 14)
		cs.shape = rs
		_body.add_child(cs)
		_body.position = Vector2(30.0, -7.0)
		add_child(_body)

	func world_rect() -> Rect2:
		return Rect2(global_position + Vector2(-TRIG_R, -40.0), Vector2(TRIG_R * 2.0, 40.0))

	func danger_at(p: Vector2, margin := 0.0) -> bool:
		return state != DEAD and world_rect().grow(margin).has_point(p)

	func shot() -> void:
		if state == DEAD:
			return
		state = DEAD
		Sfx.play("s63_squelch", global_position, 0.0, 0.1, 2)
		Particles.burst(get_parent(), global_position + Vector2(30, -8), "drop", Vector2.UP, 5)
		if _body != null:
			_body.queue_free()
			_body = null
		queue_redraw()

	func _process(delta: float) -> void:
		_t += delta
		_cd -= delta
		if state == DEAD:
			return
		var pl := get_tree().get_first_node_in_group("player") as Node2D
		var dx := INF
		if pl != null and not pl.dead and absf(pl.global_position.y - global_position.y) < 30.0:
			dx = absf(pl.global_position.x - global_position.x)
		_near = move_toward(_near, 1.0 if dx < NEAR_R else 0.0, delta * 3.0)
		match state:
			HIDDEN:
				if _cd <= 0.0 and dx < TRIG_R:
					state = TELL
					_st = TELL_T
					Sfx.play("s63_creak", global_position, -2.0, 0.1, 2)
				elif Engine.get_process_frames() % 10 == 0 and _cd <= 0.0:
					for zz in get_tree().get_nodes_in_group("zombies"):
						if not zz.dead and not zz.is_boss() and zz.is_on_floor() and absf(zz.global_position.x - global_position.x) < TRIG_R * 0.8 \
								and absf(zz.global_position.y - global_position.y) < 20.0 and not zz.has_meta("s63_held"):
							zz.set_meta("s63_held", Time.get_ticks_msec() + int(HOLD_T * 1000.0))
							zz.velocity = Vector2.ZERO
							held += 1
							state = GRIP
							_st = GRIP_T
							break
			TELL:
				_st -= delta
				if _st <= 0.0:
					state = GRIP
					_st = GRIP_T
					grips += 1
					Sfx.play("s63_grip", global_position, 0.0, 0.1, 2)
					if dx < TRIG_R + 18.0:
						pl.hurt(DMG, Vector2.ZERO)
						pl.slow_t = maxf(float(pl.slow_t), SLOW_T)
						if not _said:
							_said = true
							U.say(pl, "ROOTED - shoot the bulb next to it!", Color("ffb0a0"))
			GRIP:
				_st -= delta
				if _st <= 0.0:
					state = HIDDEN
					_cd = CD
		if Art.on_screen(self, global_position, 100.0) and (state != HIDDEN or _near > 0.0 or Engine.get_process_frames() % 6 == 0):
			queue_redraw()

	func _draw() -> void:
		DrawBatch.begin(self)
		_draw_b()
		DrawBatch.end(self)

	func _draw_b() -> void:
		var pts := PackedVector2Array()
		var cols := PackedColorArray()
		if state == DEAD:
			U.oval(pts, cols, Vector2(0, -1.0), 30.0, 4.0, Color(0.2, 0.15, 0.1, 0.7), 10)
			U.oval(pts, cols, Vector2(30, -3.0), 8.0, 4.0, Color(0.25, 0.2, 0.15), 8)
			U.flush(self, pts, cols)
			return
		# הרצפה מתגלגלת מעליו (רמז)
		var rip := _near * (1.0 + sin(_t * 9.0)) * 0.5
		U.oval(pts, cols, Vector2(0, -1.0 - rip * 3.0), 32.0, 4.0 + rip * 3.0, Color(0.38, 0.13, 0.15, 0.5 + 0.4 * _near), 10)
		# הפקעת (נקודת התורפה) בצד
		U.oval(pts, cols, Vector2(30, -6.0), 10.0, 7.0, Color("5a3a26"), 10)
		U.oval(pts, cols, Vector2(29, -8.0), 4.0, 3.0, U.glow(Color(0.75, 1.0, 0.55, 0.5 + 0.4 * _near)), 8)
		if state == TELL or state == GRIP:
			var k := 1.0 if state == GRIP else 1.0 - _st / TELL_T
			for q in 6:
				var bx := -24.0 + float(q) * 9.6
				var tip := Vector2(bx + sin(_t * 14.0 + float(q)) * 4.0, -10.0 - 36.0 * k * (0.6 + 0.4 * U.h(q, 51)))
				U.seg(pts, cols, Vector2(bx, 0), tip, 4.0 - float(q % 2), Color("4a2a1a"))
				U.seg(pts, cols, tip, tip + Vector2(6.0 * (1.0 if q % 2 == 0 else -1.0), 6.0), 2.0, Color("5a3a24"))
		U.flush(self, pts, cols)


# ============================================================
#  זירת ה-ROOT: עורקים ענקיים מכל הכיוונים אל הלב (מימין), צלעות שורש מעל, טבעות ורידים ברצפה,
#  ושאריות של כל מי שבא לכאן לפניך
# ============================================================
class HeartChamber extends Node2D:
	var w := 1700.0
	var _t := 0.0

	func _ready() -> void:
		z_index = -3

	func _process(delta: float) -> void:
		_t += delta
		if Engine.get_process_frames() % 3 == 0 and Art.on_screen(self, global_position + Vector2(w * 0.5, -250), w * 0.6):
			queue_redraw()

	func _draw() -> void:
		DrawBatch.begin(self)
		_draw_b()
		DrawBatch.end(self)

	func _draw_b() -> void:
		var pts := PackedVector2Array()
		var cols := PackedColorArray()
		var b: float = U.beat
		U.vrect(pts, cols, Rect2(0, -700.0, w, 700.0), Color("12040a"), Color("2a0a10"))
		# צלעות שורש מעל הזירה
		for q in 5:
			var ax := float(q) * w / 5.0 + 80.0
			var prev := Vector2(ax, 0)
			for s in range(1, 13):
				var u := float(s) / 12.0
				var p := Vector2(ax + u * 380.0, -sin(u * PI) * 560.0)
				U.seg(pts, cols, prev, p, 22.0 - 8.0 * sin(u * PI), Color("2a1014"))
				prev = p
		# עורקים ענקיים שמתכנסים אל הלב (מימין למעלה ולמטה)
		var hc := Vector2(w - 160.0, -260.0)
		for q in 7:   # עורקים מעוקלים מהתקרה אל הלב
			var a := Vector2(float(q) * w / 7.0 - 60.0, -720.0)
			var c1 := Vector2(a.x + 120.0, -420.0 + U.h(q, 63) * 140.0)
			var prev := a
			var wd := 20.0 - float(q) * 1.4
			for st in range(1, 11):
				var u := float(st) / 10.0
				var p := a.lerp(c1, u).lerp(c1.lerp(hc, u), u)   # עקומה (בזייה)
				p.x += sin(u * 5.0 + float(q)) * 10.0
				U.seg(pts, cols, prev, p, wd * (1.0 - u * 0.3), Color("3a1016"))
				U.seg(pts, cols, prev + Vector2(0, -wd * 0.3), p + Vector2(0, -wd * 0.3), 2.0, Color(0.55, 0.2, 0.22, 0.4))
				prev = p
			U.vein(pts, cols, c1, hc, 4.0, _t * 1.6, global_position.x + c1.x, q, Color("2a0c10"))
		# טבעות ורידים ברצפה סביב הלב
		for q in 4:
			U.oval(pts, cols, Vector2(w - 160.0, -4.0), 260.0 + float(q) * 220.0, 8.0 + float(q) * 2.0, Color(0.35, 0.08, 0.1, 0.5 - float(q) * 0.1), 24)
		# שאריות: נשקים, קסדות, עצמות של מי שבא לפני
		for q in 18:
			var sp := Vector2(120.0 + U.h(q, 64) * (w - 500.0), -2.0)
			if q % 3 == 0:
				U.seg(pts, cols, sp, sp + Vector2(22.0, -3.0), 3.0, Color("2a2a2a"))
			elif q % 3 == 1:
				U.oval(pts, cols, sp + Vector2(0, -4.0), 7.0, 5.0, BONE_D, 8)
			else:
				U.oval(pts, cols, sp + Vector2(0, -3.0), 9.0, 4.0, Color("3a4a30"), 8)
		U.flush(self, pts, cols)
		Kit.soft_glow(self, hc, 420.0 + 40.0 * b, Color(0.7, 0.1, 0.1, (0.14 + 0.1 * b) * clampf(U.life, 0.0, 1.5)), 0.8)


# ============================================================
#  מכשולים (מוצקים + מחסה): הכוורת גידלה מחדש את המחסות שהגיבור התחבא מאחוריהן כל הדרך.
#  "car" מכונית של בשר / "barrels" חביות / "sandbags" שקי חול / "bones" ערימת עצמות. כולם מכוסים חוטי ECHO.
# ============================================================
class Obstacle extends Node2D:
	var kind := "car"
	var size := Vector2(150, 56)
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
			"car":   # מכונית שגדלה מבשר: גוף מעוגל, חלונות של קרום, גלגלים של פקעות
				U.quad(pts, cols, Vector2(0, -8.0), Vector2(w, -8.0), Vector2(w - 8.0, -h * 0.62), Vector2(6.0, -h * 0.58), Color("5a2a28"), Color("5a2a28"), Color("4a1e20"), Color("4a1e20"))
				U.quad(pts, cols, Vector2(w * 0.22, -h * 0.58), Vector2(w * 0.8, -h * 0.6), Vector2(w * 0.68, -h), Vector2(w * 0.32, -h), Color("4a1e20"), Color("4a1e20"), Color("5e2c2a"), Color("5e2c2a"))
				U.quad(pts, cols, Vector2(w * 0.3, -h * 0.62), Vector2(w * 0.48, -h * 0.62), Vector2(w * 0.48, -h * 0.94), Vector2(w * 0.36, -h * 0.94), Color(0.6, 0.35, 0.35, 0.5), Color(0.6, 0.35, 0.35, 0.5), Color(0.7, 0.45, 0.42, 0.4), Color(0.7, 0.45, 0.42, 0.4))
				U.quad(pts, cols, Vector2(w * 0.52, -h * 0.62), Vector2(w * 0.72, -h * 0.62), Vector2(w * 0.64, -h * 0.94), Vector2(w * 0.52, -h * 0.94), Color(0.6, 0.35, 0.35, 0.5), Color(0.6, 0.35, 0.35, 0.5), Color(0.7, 0.45, 0.42, 0.4), Color(0.7, 0.45, 0.42, 0.4))
				for s: float in [0.2, 0.8]:
					U.oval(pts, cols, Vector2(w * s, -10.0), 13.0, 13.0, Color("2a1010"), 10)
					U.oval(pts, cols, Vector2(w * s, -10.0), 5.0, 5.0, Color("4a3a26"), 8)
				U.rect(pts, cols, Rect2(w - 10.0, -h * 0.45, 8.0, 5.0), U.glow(Color(0.75, 1.0, 0.55, 0.7)))   # פנס של קשרית
			"barrels":   # חביות שהבשר עטף
				for q in 2:
					var bx := 4.0 + float(q) * w * 0.5
					var bw := w * 0.5 - 8.0
					var bh := h * (1.0 if q == 0 else 0.85)
					U.vrect(pts, cols, Rect2(bx, -bh, bw, bh), Color("5a3a2a"), Color("3a2418"))
					U.rect(pts, cols, Rect2(bx, -bh * 0.7, bw, 4.0), Color("2a1a12"))
					U.rect(pts, cols, Rect2(bx, -bh * 0.3, bw, 4.0), Color("2a1a12"))
					U.oval(pts, cols, Vector2(bx + bw * 0.5, -bh), bw * 0.5, 4.0, Color("4a2a20"), 10)
				U.oval(pts, cols, Vector2(w * 0.5, -h * 0.5), w * 0.3, h * 0.25, Color(0.4, 0.12, 0.14, 0.6), 10)
			"sandbags":   # שקי חול של בשר (המחסום שלך מהבסיס)
				var rows := 3
				for row in rows:
					var n := 4 - row
					for q in n:
						var sx := (float(q) + float(row) * 0.5) * w / 4.0 + 4.0
						var sy := -float(row) * h / float(rows) - h / float(rows) * 0.5
						U.oval(pts, cols, Vector2(sx + w / 8.0, sy), w / 8.0 - 1.0, h / float(rows) * 0.55, Color("5a3030") if (q + row) % 2 == 0 else Color("4a2626"), 10)
			_:   # ערימת עצמות מכל מי שמת כאן
				U.oval(pts, cols, Vector2(w * 0.5, -h * 0.4), w * 0.5, h * 0.5, Color("3a2a24"), 14)
				for q in 14:
					var a := Vector2(r.randf_range(6.0, w - 6.0), -r.randf_range(4.0, h * 0.9))
					U.seg(pts, cols, a, a + Vector2.from_angle(r.randf() * TAU) * r.randf_range(10.0, 22.0), 3.0, BONE if q % 2 == 0 else BONE_D)
				for q in 3:
					U.oval(pts, cols, Vector2(r.randf_range(10.0, w - 10.0), -r.randf_range(h * 0.4, h * 0.85)), 6.0, 5.5, BONE, 8)
		# חוטי ECHO על כל מחסה
		for q in 4:
			var a := Vector2(r.randf_range(0.0, w), -r.randf_range(0.0, h))
			U.seg(pts, cols, a, a + Vector2(r.randf_range(-12.0, 12.0), r.randf_range(4.0, 14.0)), 1.4, Color("3a5a2a"))
			U.oval(pts, cols, a, 2.0, 2.0, U.glow(Color(0.75, 1.0, 0.55, 0.6)), 6)
		U.flush(self, pts, cols)


# ============================================================
#  מסך: נבגים מרחפים, פעימת הלב בשולי המסך (חזקה יותר ליד הלב), מונה "LESSONS HOME" (ימין, מתחת למד הסטייל),
#  והודעות (U.notify) - למשל "A LESSON REACHED THE ROOT"
# ============================================================
class HeartFX extends Node2D:
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
		var lf := clampf(U.life, 0.0, 1.5)
		for i in int(46.0 * q):   # נבגים שנסחפים ימינה (אל הלב)
			var x := fposmod(U.h(i, 1) * vp.x * 1.7 + _t * (20.0 + U.h(i, 3) * 40.0), vp.x)
			var y := fposmod(U.h(i, 2) * vp.y + sin(_t * 0.7 + float(i)) * 30.0 - _t * 6.0, vp.y)
			U.dia(pts, cols, Vector2(x, y), 1.0 + U.h(i, 4) * 1.6, U.glow(Color(0.75, 1.0, 0.55, (0.12 + 0.25 * U.h(i, 5)) * lf)))
		# פעימת הלב: שוליים אדומים שמתכווצים
		var p: float = U.beat * (0.35 + 0.65 * U.heart_k) * minf(U.life, 1.0)
		if p > 0.02:
			var c0 := Color(0.6, 0.02, 0.05, 0.3 * p)
			var c1 := Color(0.6, 0.02, 0.05, 0.0)
			var e := 70.0 + 40.0 * p
			U.quad(pts, cols, Vector2(0, 0), Vector2(vp.x, 0), Vector2(vp.x, e), Vector2(0, e), c0, c0, c1, c1)
			U.quad(pts, cols, Vector2(0, vp.y - e), Vector2(vp.x, vp.y - e), Vector2(vp.x, vp.y), Vector2(0, vp.y), c1, c1, c0, c0)
			U.quad(pts, cols, Vector2(0, 0), Vector2(e * 1.6, 0), Vector2(e * 1.6, vp.y), Vector2(0, vp.y), c0, c1, c1, c0)
			U.quad(pts, cols, Vector2(vp.x - e * 1.6, 0), Vector2(vp.x, 0), Vector2(vp.x, vp.y), Vector2(vp.x - e * 1.6, vp.y), c1, c0, c0, c1)
		# מונה השיעורים שהגיעו הביתה: עיגול צבעוני לכל קטגוריה עם מספר
		var shown := []
		if U.seen_lesson and U.life >= 1.0:
			for cat in CATS:
				if int(U.lessons.get(cat, 0)) > 0:
					shown.append(cat)
			for i in shown.size():
				var cp := Vector2(vp.x - 40.0 - float(i) * 44.0, 222.0)
				var cc: Color = CAT_COL[shown[i]]
				U.oval(pts, cols, cp, 15.0, 15.0, Color(0, 0, 0, 0.6), 14)
				U.oval(pts, cols, cp, 12.0, 12.0, Color(cc, 0.85), 14)
		U.flush(self, pts, cols)
		var f := ThemeDB.fallback_font
		if not shown.is_empty():
			DrawBatch.string_outline(self, f, Vector2(vp.x - 222.0, 198.0), "LESSONS HOME", HORIZONTAL_ALIGNMENT_RIGHT, 200, 14, 4, Color(0, 0, 0, 0.8))
			DrawBatch.string(self, f, Vector2(vp.x - 222.0, 198.0), "LESSONS HOME", HORIZONTAL_ALIGNMENT_RIGHT, 200, 14, Color(0.85, 1.0, 0.75, 0.9))
			for i in shown.size():
				var cp := Vector2(vp.x - 40.0 - float(i) * 44.0, 222.0)
				DrawBatch.string_outline(self, f, cp + Vector2(-20.0, 6.0), str(int(U.lessons[shown[i]])), HORIZONTAL_ALIGNMENT_CENTER, 40, 16, 4, Color(0, 0, 0, 0.9))
				DrawBatch.string(self, f, cp + Vector2(-20.0, 6.0), str(int(U.lessons[shown[i]])), HORIZONTAL_ALIGNMENT_CENTER, 40, 16, Color.WHITE)
		var nt := U.since(U.note_ms)
		if nt >= 0.0 and nt < 2.8 and U.note != "":
			var a := clampf(nt / 0.2, 0.0, 1.0) * clampf((2.8 - nt) / 0.5, 0.0, 1.0)
			DrawBatch.string_outline(self, f, Vector2(0, 196.0), U.note, HORIZONTAL_ALIGNMENT_CENTER, vp.x, 22, 6, Color(0, 0, 0, 0.85 * a))
			DrawBatch.string(self, f, Vector2(0, 196.0), U.note, HORIZONTAL_ALIGNMENT_CENTER, vp.x, 22, Color(U.note_col, a))
