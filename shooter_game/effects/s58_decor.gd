extends RefCounted
const DrawBatch := preload("res://effects/draw_batch.gd")   # כל הציור של זומבי ב-draw call אחד
# ============================================================
#  קישוטים לשלב 58 ("WHALE GRAVEYARD") - אזור שביעי (פטגוניה), שלב 4. "THEY LEARNED TO WEAR THE DEAD".
#  תחנת ציד לווייתנים נטושה (PUERTO HUESO, בהשראת גריטוויקן / טיירה דל פואגו) על חוף אפור וקר: שלדי לווייתנים ענקיים
#  וקשתות צלעות על החול, משטחי הפשטה, מיכלי שמן חלודים ותנורי שמן, תותחי צלצל, מסילות גרירה וספינות ציד טרופות,
#  שחפים, טפטוף, שמש נמוכה. ECHO למד שהוא יכול לגדול בכל דבר מת - והמתים כאן ענקיים: התחנה הפכה לחווה של ECHO.
#    grey_sky      - (רקע) שמיים אפורים וכבדים, פס אפרסק חיוור באופק, שמש נמוכה מאחורי ענן, וילונות טפטוף רחוקים,
#                    שחפים וסקואות שדואים
#    far_isle      - (רקע, 0.06) הרים תלולים מושלגים עם קרחונים שיורדים לים, ענן נמוך שנתקע באמצע ההרים,
#                    ובמערב - עמוד עשן עם זוהר כתום (היער השחור בוער - השלב הבא)
#    mid_harbor    - (רקע, 0.28) המפרץ האפור: גלי ים, החוף שממול עם סככות חלודות, מיכלים, כנסייה לבנה עם צריח,
#                    מזח, ספינת ציד חצי טבועה עם תותח צלצל, ופגר לווייתן נפוח שצף עם שחפים וזוהר ירוק
#    near_bones    - (רקע, 0.6) סוללת חלוקים כהה: טוסוק, חוליות וגולגולות, קשתות צלעות, סיר שמן חלוד, מסילה,
#                    בית קברות של ציידים (צלבים עקומים), ופטריית ECHO זוהרת על העצמות
#    grey_overlay  - אובך קר מאחורי הדמויות
#    GraveGround   - (עולם) חול געשי כהה, חלוקים, שברי עצם, פתיתי חלודה, שלוליות, קרשים ישנים
#    BoneArch      - (עולם) שער של שתי לסתות לווייתן עם השלט "PUERTO HUESO"
#    OilTank       - (עולם) מיכל שמן לווייתנים חלוד, מסלול על הגג (קומה), וכתובת הכוורת בפטרייה זוהרת (words)
#    FlensingPlan  - (עולם) משטח ההפשטה: במת עץ על כלונסאות (קומה), כננת, ווים על שרשראות, לווייתן חצי מופשט
#    EchoCarcass   - (עולם, מלכודת + "רחם", קבוצה "s58_carcass") פגר לווייתן מכוסה בגידולי ECHO: שלפוחיות זוהרות
#                    (PustuleBody). מתקרבים (TRIG_R) -> הפגר מתנשם (WARN_T) -> BIRTH: הצלעות נפרצות, BONECRAWLER יוצא
#                    וענן נבגים (CLOUD_R) מטשטש את הכוונת. כל השלפוחיות פוצצו לפני כן = "STILLBORN" (בלי לידה).
#    CatcherBoat   - (עולם) ספינת ציד חלודה על מסילת הגרירה: סיפון + גג תא ההגה (קומות), ארובה, תורן
#    HarpoonGun    - (עולם, מלכודת) תותח צלצל על החרטום / על בסיס, עם תותחן מת שגדל לתוכו (GunnerBody).
#                    אתה בטווח מולו -> מכוון (AIM_T) -> ננעל (קו כוונה, LOCK_T) -> יורה צלצל (Harpoon): פוגע בך,
#                    משפד זומבים בדרך. ירייה בתותחן (GUNNER_HP) משתיקה אותו לתמיד.
#    TryPot        - (עולם, מלכודת) תנור שמן: שני סירי ברזל של שמן לווייתנים רותח מעל אש. ירייה בסיר (PotBody) / פיצוץ ->
#                    הסיר נסדק ונשפך: שמן רותח בוער (FireZone, SPILL_W, BURN_T). זומבים נדלקים - והשחקן נכווה.
#    Obstacle      - (מוצק + מחסה) "casks" חביות עץ של שמן / "boiler" דוד חלוד על הצד / "bones" ערימת עצמות / "winch" כננת קיטור
#    BoneThrone    - (עולם) זירת הבוס: גולגולת לווייתן ענקית ככס, גדר לסתות, קן של ECHO, שלט "PLAN"
#    GreyFX        - (מסך) טפטוף דק באלכסון, ערפל שנסחף, משב (gust())
#  לשנות: EchoCarcass.TRIG_R / WARN_T / CLOUD_R / SWAY_T, HarpoonGun.RANGE / AIM_T / LOCK_T / CD / DMG / DMG_Z / GUNNER_HP,
#         Harpoon.V, TryPot.SPILL_W / BURN_T / POT_HP, GreyFX.GUST_EVERY.
# ============================================================

const Art := preload("res://art.gd")
const Sfx := preload("res://sfx.gd")
const Kit := preload("res://effects/backdrop_kit.gd")
const Particles := preload("res://particles.gd")
const FireZone := preload("res://environment/fire_zone.gd")

const SAND := Color("4c4a46")
const SAND_L := Color("6c675e")
const SAND_D := Color("2c2a28")
const WET := Color("383a3c")
const RUST := Color("844228")
const RUST_D := Color("4a2416")
const RUST_L := Color("b4643a")
const BONE := Color("ddd3ba")
const BONE_D := Color("a29679")
const BONE_S := Color("786c56")
const SPORE := Color(0.66, 1.0, 0.52)
const SPORE_D := Color("5e7e3e")
const FUNGUS := Color("cfd4a8")
const OLD_BLOOD := Color("5a2420")
const SKIN_W := Color("3a3c42")     # עור לווייתן
const SKIN_WL := Color("5c6068")
const MEAT := Color("7a2a26")
const WOOD := Color("5c4632")
const WOOD_D := Color("3a2c20")
const WOOD_L := Color("8a6c4a")
const TUSSOCK := Color("8a8248")
const SEA := Color("4c5c66")
const SEA_D := Color("2c3840")
const IRON := Color("2e2c2c")


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

	static func tri(pts: PackedVector2Array, cols: PackedColorArray, a: Vector2, b: Vector2, c: Vector2, col: Color) -> void:
		pts.append_array([a, b, c])
		cols.append_array([col, col, col])

	static func dia(pts: PackedVector2Array, cols: PackedColorArray, c: Vector2, r: float, col: Color) -> void:
		pts.append_array([c + Vector2(-r, 0), c + Vector2(0, -r), c + Vector2(r, 0), c + Vector2(-r, 0), c + Vector2(r, 0), c + Vector2(0, r)])
		cols.append_array([col, col, col, col, col, col])

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

	# רצועה עבה לאורך קו (צלע / עצם / חבל): רוחב משתנה w0 -> w1
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

	# קשת צלע: מבסיס (על הקרקע) עד קצה עליון, מתעקלת. מחזיר את הנקודות
	static func rib_line(base: Vector2, top: Vector2, bend: float, n := 7) -> PackedVector2Array:
		var out := PackedVector2Array()
		var d := (top - base)
		var nrm := d.normalized().orthogonal()
		for q in n:
			var u := float(q) / float(n - 1)
			out.append(base + d * u + nrm * sin(u * PI) * bend)
		return out

	# ציפור קטנה עפה (גוף + 2 כנפיים מנפנפות)
	static func bird(pts: PackedVector2Array, cols: PackedColorArray, p: Vector2, s: float, flap: float, dir: float, col: Color) -> void:
		var w := 6.0 * s
		var up := sin(flap) * 4.5 * s
		pts.append_array([p + Vector2(-2.6 * s * dir, 0.4 * s), p + Vector2(3.4 * s * dir, -0.6 * s), p + Vector2(0.2 * s * dir, 1.6 * s)])
		pts.append_array([p + Vector2(-0.8 * s, 0), p + Vector2(0.9 * s, 0), p + Vector2(-w * 0.55 * dir, -up - 0.6 * s)])
		pts.append_array([p + Vector2(-0.8 * s, 0), p + Vector2(0.9 * s, 0), p + Vector2(w * 0.5 * dir, -up * 0.8 - 1.0 * s)])
		cols.append_array([col, col, col, col, col, col, col, col, col])

	# חוליה של לווייתן (דיסקה + זיז עליון + שני זיזים לצדדים)
	static func vertebra(pts: PackedVector2Array, cols: PackedColorArray, c: Vector2, r: float, col: Color, dk: Color) -> void:
		quad(pts, cols, c + Vector2(-r * 0.25, -r * 0.6), c + Vector2(r * 0.25, -r * 0.6), c + Vector2(r * 0.12, -r * 2.0), c + Vector2(-r * 0.2, -r * 1.9), col, col, dk, dk)
		quad(pts, cols, c + Vector2(-r * 0.7, -r * 0.1), c + Vector2(-r * 0.6, r * 0.25), c + Vector2(-r * 1.6, r * 0.05), c + Vector2(-r * 1.6, -r * 0.2), col, col, dk, dk)
		quad(pts, cols, c + Vector2(r * 0.7, -r * 0.1), c + Vector2(r * 0.6, r * 0.25), c + Vector2(r * 1.6, r * 0.05), c + Vector2(r * 1.6, -r * 0.2), col, col, dk, dk)
		oval(pts, cols, c, r, r * 0.8, col, 10)
		oval(pts, cols, c + Vector2(r * 0.1, r * 0.1), r * 0.45, r * 0.35, dk, 8)

	# כתם פטריית ECHO זוהרת (גבעולים + ראשים + הילה). pulse 0..1
	static func growth(pts: PackedVector2Array, cols: PackedColorArray, c: Vector2, s: float, seed_v: int, pulse: float) -> void:
		oval(pts, cols, c, 14.0 * s, 5.0 * s, Color(SPORE.r, SPORE.g, SPORE.b, 0.10 + 0.08 * pulse), 10)
		for q in 5:
			var x := (h(seed_v + q, 1) - 0.5) * 18.0 * s
			var hh := (5.0 + h(seed_v + q, 2) * 9.0) * s
			var b := c + Vector2(x, 2.0 * s)
			var tp := b + Vector2(sin(float(q) * 1.7) * 2.0 * s, -hh)
			quad(pts, cols, b + Vector2(-0.8 * s, 0), b + Vector2(0.8 * s, 0), tp + Vector2(0.5 * s, 0), tp + Vector2(-0.5 * s, 0), FUNGUS.darkened(0.2), FUNGUS.darkened(0.2), FUNGUS, FUNGUS)
			oval(pts, cols, tp, (1.6 + h(seed_v + q, 3) * 1.4) * s, (1.3 + h(seed_v + q, 3)) * s, SPORE.lerp(Color(1, 1, 0.8), 0.3 * pulse), 6)


static func _h(i: int, s: int) -> float:
	return U.h(i, s)


# ============================================================
#  רקע
# ============================================================

# ---- שמיים אפורים, שמש נמוכה מאחורי ענן, וילונות טפטוף, שחפים ----
static func grey_sky(ci: CanvasItem, v: Vector2, t: float) -> void:
	Kit.gradient_sky(ci, v, [Color("3c434c"), Color("555d66"), Color("767b80"), Color("a39a92"), Color("d6b48e")], 0.84)
	var sp := Vector2(v.x * 0.78, v.y * 0.6)
	# השמש הנמוכה: הילה רחבה חמה, דיסקה חיוורת
	Kit.soft_glow(ci, sp, 420.0, Color(1.0, 0.72, 0.45, 0.26), 0.42)
	Kit.soft_glow(ci, sp, 150.0, Color(1.0, 0.85, 0.62, 0.42), 0.8)
	DrawBatch.circle(ci, sp, 30.0, Color(1.0, 0.9, 0.74, 0.75))
	var pts := PackedVector2Array()
	var cols := PackedColorArray()
	# קרני שמש חלשות שעולות מבין העננים
	for i in 5:
		var a := -PI * 0.5 + (float(i) - 2.0) * 0.32 + sin(t * 0.05 + float(i)) * 0.03
		var rl := 340.0 + _h(i, 3) * 160.0
		var w := 0.035 + _h(i, 4) * 0.02
		var al := 0.05 + 0.035 * sin(t * 0.25 + float(i) * 1.9)
		pts.append_array([sp, sp + Vector2.from_angle(a - w) * rl, sp + Vector2.from_angle(a + w) * rl])
		cols.append_array([Color(1.0, 0.86, 0.66, al), Color(1.0, 0.86, 0.66, 0.0), Color(1.0, 0.86, 0.66, 0.0)])
	U.flush(ci, pts, cols)
	# ענן ארוך וכהה שחוצה את השמש, עם שוליים מוארים באפרסק
	for i in 3:
		var x := fposmod(sp.x - 300.0 + float(i) * 260.0 - t * (5.0 + float(i)), v.x + 700.0) - 350.0
		var y := sp.y - 18.0 + float(i) * 22.0
		Kit.soft_ellipse(ci, Vector2(x, y), 260.0, 14.0, 0.0, Color(0.28, 0.29, 0.33, 0.55))
		Kit.soft_ellipse(ci, Vector2(x + 20.0, y + 9.0), 220.0, 4.0, 0.0, Color(1.0, 0.75, 0.52, 0.3))
	# שכבות סטרטוס כבדות שזזות לאט
	for i in 9:
		var spd := 6.0 + float(i) * 2.4
		var x := fposmod(_h(i, 8) * v.x * 1.7 - t * spd, v.x + 900.0) - 450.0
		var y := v.y * (0.03 + _h(i, 9) * 0.36)
		var rx := 260.0 + _h(i, 10) * 200.0
		var ry := 20.0 + _h(i, 11) * 26.0
		var dark := Color(0.24, 0.26, 0.3, 0.4 + 0.22 * _h(i, 12))
		Kit.soft_ellipse(ci, Vector2(x, y), rx, ry, 0.01, dark)
		Kit.soft_ellipse(ci, Vector2(x - rx * 0.45, y + ry * 0.45), rx * 0.55, ry * 0.7, -0.04, Color(dark, dark.a * 0.8))
		Kit.soft_ellipse(ci, Vector2(x + rx * 0.15, y + ry * 0.7), rx * 0.6, ry * 0.25, 0.0, Color(0.95, 0.78, 0.6, 0.1))   # בטן מוארת
	# וילונות טפטוף רחוקים (virga) שיורדים מהעננים באלכסון
	pts = PackedVector2Array()
	cols = PackedColorArray()
	for i in 7:
		var x := fposmod(_h(i, 14) * v.x * 1.6 - t * (9.0 + _h(i, 15) * 6.0), v.x + 500.0) - 250.0
		var top := v.y * (0.2 + _h(i, 16) * 0.15)
		var bot := v.y * (0.62 + _h(i, 17) * 0.1)
		var w := 70.0 + _h(i, 18) * 110.0
		var a := 0.06 + 0.05 * _h(i, 19)
		var c := Color(0.42, 0.45, 0.5, a)
		U.quad(pts, cols, Vector2(x, top), Vector2(x + w, top), Vector2(x + w - 60.0, bot), Vector2(x - 60.0, bot), c, c, Color(c, 0.0), Color(c, 0.0))
	U.flush(ci, pts, cols)
	# שחפים (לבנים) וסקואות (חומות) שדואים במעגלים
	pts = PackedVector2Array()
	cols = PackedColorArray()
	for g in 4:
		var cx := fposmod(_h(g, 20) * v.x * 1.4 + t * (4.0 + float(g)), v.x + 400.0) - 200.0
		var cy := 80.0 + float(g) * 52.0
		for q in 3 + g:
			var a := t * (0.35 + 0.1 * float(q % 3)) + float(q) * 2.1 + float(g)
			var r := 40.0 + _h(q, 21 + g) * 70.0
			var p := Vector2(cx + cos(a) * r, cy + sin(a) * r * 0.35)
			var skua := (q + g) % 4 == 0
			var col := Color(0.32, 0.24, 0.18, 0.85) if skua else (Color(0.95, 0.95, 0.96, 0.85) if q % 2 == 0 else Color(0.16, 0.17, 0.2, 0.8))
			U.bird(pts, cols, p, 1.3 - float(g) * 0.15 + (0.3 if skua else 0.0), t * (6.0 if skua else 4.0) + float(q * 3 + g), -signf(sin(a)) if sin(a) != 0.0 else 1.0, col)
	U.flush(ci, pts, cols)


# ---- הרים תלולים, קרחונים, ענן נמוך, עשן היער הבוער במערב ----
static func far_isle(ci: CanvasItem, sc: float, v: Vector2, y: float, t: float) -> void:
	var sea_top := y - 34.0
	var period := 2200.0
	var start := int(floor(sc / period)) - 1
	for k in range(start, start + int(ceil(v.x / period)) + 2):
		var bx := float(k) * period - sc
		# עשן היער הבוער (רחוק, במערב של כל מקטע) - הרמז לשלב הבא
		var smx := bx + 260.0
		if smx > -300.0 and smx < v.x + 300.0:
			Kit.soft_glow(ci, Vector2(smx, sea_top - 30.0), 160.0, Color(1.0, 0.45, 0.18, 0.22 + 0.06 * sin(t * 1.3 + float(k))), 0.35)
			Kit.soft_smoke(ci, Vector2(smx, sea_top - 40.0), t, 330.0, Color(0.2, 0.17, 0.16, 0.32), 140.0, 8)
		# רכס אחורי (כחלחל) + רכס קדמי (צפחה כהה) עם שלג
		for layer in 2:
			var ridge := PackedVector2Array([Vector2(bx, sea_top)])
			var peaks := []
			var n := 15
			for q in n + 1:
				var px := bx + float(q) * period / float(n)
				var hh := 24.0
				if q > 0 and q < n:
					var base_h := 150.0 if layer == 0 else 110.0
					hh = (base_h + _h(k * 31 + q + layer * 7, 1) * 120.0) if q % 2 == 1 else (base_h * 0.45 + _h(k * 31 + q, 2) * 50.0)
				ridge.append(Vector2(px + (_h(q, 3 + layer) - 0.5) * 30.0, sea_top - hh))
				if q % 2 == 1 and q < n:
					peaks.append(ridge[ridge.size() - 1])
			ridge.append(Vector2(bx + period, sea_top))
			DrawBatch.colored_polygon(ci, ridge, Color("6c7684") if layer == 0 else Color("3e434c"))
			for pk: Vector2 in peaks:   # שלג על הפסגות, עם ערוצים כהים
				var s := 1.0 if layer == 0 else 0.8
				DrawBatch.colored_polygon(ci, PackedVector2Array([pk, pk + Vector2(26, 30) * s, pk + Vector2(12, 26) * s, pk + Vector2(4, 48) * s, pk + Vector2(-6, 30) * s, pk + Vector2(-22, 36) * s]), Color("dfe4ea") if layer == 0 else Color("c8ced6"))
				DrawBatch.line(ci, pk, pk + Vector2(24, 29) * s, Color(0.4, 0.45, 0.55, 0.45), 1.2)
		# קרחונים שיורדים לים (לשון לבנה-כחולה)
		for g in 2:
			var gx := bx + 700.0 + float(g) * 900.0
			DrawBatch.colored_polygon(ci, PackedVector2Array([Vector2(gx - 20, sea_top - 120), Vector2(gx + 30, sea_top - 110), Vector2(gx + 80, sea_top - 6), Vector2(gx - 60, sea_top - 6)]), Color("c4d4e0"))
			DrawBatch.colored_polygon(ci, PackedVector2Array([Vector2(gx - 60, sea_top - 6), Vector2(gx + 80, sea_top - 6), Vector2(gx + 84, sea_top + 2), Vector2(gx - 64, sea_top + 2)]), Color("8fb0c8"))
			for q in 4:
				DrawBatch.line(ci, Vector2(gx - 10 + float(q) * 12.0, sea_top - 100 + float(q) * 4.0), Vector2(gx - 40 + float(q) * 30.0, sea_top - 8), Color(0.55, 0.65, 0.75, 0.5), 1.0)
		# ענן נמוך שנתקע באמצע ההרים
		for c in 3:
			var cx := bx + 300.0 + float(c) * 700.0 + sin(t * 0.05 + float(c + k)) * 60.0
			Kit.soft_ellipse(ci, Vector2(cx, sea_top - 70.0 - float(c % 2) * 30.0), 220.0, 18.0, 0.0, Color(0.72, 0.74, 0.78, 0.42))
	# הים הרחוק עם נצנוצי שמש כתומים
	DrawBatch.rect(ci, Rect2(0, sea_top, v.x, v.y - sea_top), Color("56646e"))
	DrawBatch.line(ci, Vector2(0, sea_top), Vector2(v.x, sea_top), Color(0.9, 0.8, 0.66, 0.45), 1.5)
	var pts := PackedVector2Array()
	var cols := PackedColorArray()
	for i in 36:
		var gx := fposmod(_h(i, 5) * 3000.0 - sc - t * (5.0 + _h(i, 6) * 5.0), v.x + 100.0) - 50.0
		var gy := sea_top + 3.0 + _h(i, 7) * 30.0
		var near_sun := clampf(1.0 - absf(gx - v.x * 0.78) / 420.0, 0.0, 1.0)
		var a := (0.08 + 0.3 * near_sun) * (0.5 + 0.5 * sin(t * 2.6 + float(i) * 2.3))
		var c := Color(1.0, 0.82, 0.6, a)
		U.quad(pts, cols, Vector2(gx, gy), Vector2(gx + 14.0, gy), Vector2(gx + 14.0, gy + 1.0), Vector2(gx, gy + 1.0), Color(c, 0.0), c, c, Color(c, 0.0))
	U.flush(ci, pts, cols)


# ---- המפרץ: גלים, התחנה שממול (סככות, מיכלים, כנסייה), מזח, ספינת ציד טבועה, פגר צף ----
static func mid_harbor(ci: CanvasItem, sc: float, v: Vector2, y: float, t: float) -> void:
	var top := y - 150.0
	var bands := 20
	var span := v.y - top
	for i in bands:
		var k2 := float(i) / float(bands - 1)
		DrawBatch.rect(ci, Rect2(0, top + span * float(i) / float(bands - 1) - 1.0, v.x, span / float(bands - 1) + 2.0), Color("66747c").lerp(SEA_D, pow(k2, 0.75)))
	var period := 1700.0
	var start := int(floor(sc / period)) - 1
	for k in range(start, start + int(ceil(v.x / period)) + 2):
		var bx := float(k) * period - sc
		if bx > v.x + 50.0 or bx + period < -50.0:
			continue
		var shore := top + 4.0
		# החוף שממול: מדרון טוסוק
		var hill := PackedVector2Array([Vector2(bx, shore + 6.0)])
		for q in 9:
			hill.append(Vector2(bx + float(q) * period / 8.0, shore - 46.0 - _h(k * 9 + q, 1) * 40.0))
		hill.append(Vector2(bx + period, shore + 6.0))
		DrawBatch.colored_polygon(ci, hill, Color("4a4c3e"))
		DrawBatch.rect(ci, Rect2(bx, shore - 6.0, period, 12.0), Color("3a3a34"))
		# סככות חלודות עם גגות משופעים
		for q in 5:
			var hx := bx + 120.0 + float(q) * 120.0 + _h(k * 5 + q, 2) * 30.0
			var hw := 70.0 + _h(k * 5 + q, 3) * 40.0
			var hh := 26.0 + _h(k * 5 + q, 4) * 22.0
			var c := RUST.lerp(Color("6a5a4e"), _h(k * 5 + q, 5)).darkened(0.25)
			DrawBatch.rect(ci, Rect2(hx, shore - hh, hw, hh), c)
			DrawBatch.colored_polygon(ci, PackedVector2Array([Vector2(hx - 4, shore - hh), Vector2(hx + hw * 0.5, shore - hh - 14.0), Vector2(hx + hw + 4, shore - hh)]), c.darkened(0.3))
			for w in int(hw / 18.0):
				DrawBatch.rect(ci, Rect2(hx + 6.0 + float(w) * 18.0, shore - hh + 8.0, 8.0, 7.0), Color(0.08, 0.08, 0.09, 0.85))
		# מיכלי שמן ממול
		for q in 3:
			var tx := bx + 790.0 + float(q) * 56.0
			DrawBatch.rect(ci, Rect2(tx, shore - 52.0, 46.0, 52.0), RUST.darkened(0.2 + 0.1 * float(q)))
			DrawBatch.colored_polygon(ci, Art.ellipse(Vector2(tx + 23.0, shore - 52.0), 23.0, 4.0, 0.0, 10), RUST_L.darkened(0.3))
			DrawBatch.line(ci, Vector2(tx + 8.0, shore - 50.0), Vector2(tx + 8.0, shore - 4.0), Color(0.25, 0.12, 0.05, 0.6), 3.0)
		# כנסייה לבנה של הציידים עם צריח
		var chx := bx + 1060.0
		DrawBatch.rect(ci, Rect2(chx, shore - 40.0, 54.0, 40.0), Color("dcdcd4"))
		DrawBatch.colored_polygon(ci, PackedVector2Array([Vector2(chx - 4, shore - 40.0), Vector2(chx + 27.0, shore - 58.0), Vector2(chx + 58.0, shore - 40.0)]), Color("2e3034"))
		DrawBatch.rect(ci, Rect2(chx + 40.0, shore - 74.0, 14.0, 34.0), Color("e4e4dc"))
		DrawBatch.colored_polygon(ci, PackedVector2Array([Vector2(chx + 38.0, shore - 74.0), Vector2(chx + 47.0, shore - 100.0), Vector2(chx + 56.0, shore - 74.0)]), Color("2e3034"))
		for w in 3:
			DrawBatch.rect(ci, Rect2(chx + 6.0 + float(w) * 12.0, shore - 30.0, 6.0, 12.0), Color(0.2, 0.22, 0.26))
		# זוהר ירוק חלש בחלון אחד (ECHO כבר בפנים)
		Kit.soft_glow(ci, Vector2(chx + 9.0, shore - 24.0), 14.0 + 4.0 * sin(t * 1.4 + float(k)), Color(0.6, 1.0, 0.5, 0.35))
		# ארובה גבוהה של בית הקיטור (בלי עשן - נטוש)
		DrawBatch.rect(ci, Rect2(bx + 680.0, shore - 110.0, 12.0, 110.0), Color("4a3a30"))
		DrawBatch.rect(ci, Rect2(bx + 678.0, shore - 114.0, 16.0, 6.0), Color("2a2420"))
		# מזח + ספינת ציד חצי טבועה עם תותח צלצל בחרטום
		var jx := bx + 1260.0
		DrawBatch.rect(ci, Rect2(jx, shore + 4.0, 200.0, 5.0), WOOD_D)
		for q in 9:
			DrawBatch.line(ci, Vector2(jx + float(q) * 24.0, shore + 9.0), Vector2(jx + float(q) * 24.0, shore + 34.0), WOOD_D, 3.0)
		var sx := jx + 120.0
		var sy := shore + 46.0
		var tilt := sin(t * 0.4 + float(k)) * 0.01
		var hull := PackedVector2Array([Vector2(sx - 70, sy - 20), Vector2(sx + 90, sy - 34), Vector2(sx + 100, sy - 8), Vector2(sx - 52, sy + 6)])
		for q in hull.size():
			hull[q] = sx * Vector2.ONE * 0.0 + hull[q] + Vector2(0, (hull[q].x - sx) * tilt)
		DrawBatch.colored_polygon(ci, hull, Color("3a2a26"))
		DrawBatch.line(ci, hull[0], hull[1], Color("8a4428"), 2.0)
		DrawBatch.rect(ci, Rect2(sx + 10.0, sy - 50.0, 32.0, 20.0), Color("cfc6b4"))
		DrawBatch.rect(ci, Rect2(sx + 22.0, sy - 66.0, 9.0, 16.0), Color("1e1e20"))
		DrawBatch.rect(ci, Rect2(sx + 22.0, sy - 62.0, 9.0, 3.0), Color("a82a20"))
		DrawBatch.line(ci, Vector2(sx - 30.0, sy - 22.0), Vector2(sx - 34.0, sy - 76.0), Color("2a2420"), 2.0)
		DrawBatch.line(ci, Vector2(sx + 80.0, sy - 32.0), Vector2(sx + 92.0, sy - 40.0), Color("2a2420"), 4.0)   # תותח הצלצל
		DrawBatch.line(ci, Vector2(sx - 52, sy + 8.0), Vector2(sx + 100, sy - 6.0), Color(0.85, 0.9, 0.92, 0.45), 1.5)
		# פגר לווייתן נפוח שצף, שחפים מעליו, וזוהר ירוק של ECHO
		var fx := bx + 380.0
		var fy := top + 70.0 + sin(t * 0.6 + float(k)) * 2.0
		DrawBatch.colored_polygon(ci, Art.ellipse(Vector2(fx, fy), 70.0, 13.0, 0.0, 16), Color("d8c8bc"))
		DrawBatch.colored_polygon(ci, Art.ellipse(Vector2(fx - 10.0, fy - 4.0), 50.0, 7.0, 0.0, 12), Color("ece0d4"))
		DrawBatch.colored_polygon(ci, Art.ellipse(Vector2(fx + 30.0, fy + 2.0), 14.0, 5.0, 0.0, 10), Color("8a5a50"))
		Kit.soft_glow(ci, Vector2(fx, fy - 4.0), 60.0, Color(0.55, 1.0, 0.45, 0.16 + 0.08 * sin(t * 1.1 + float(k))), 0.4)
		DrawBatch.line(ci, Vector2(fx - 74, fy + 10.0), Vector2(fx + 74, fy + 10.0), Color(0.85, 0.9, 0.92, 0.4), 1.5)
		var pts := PackedVector2Array()
		var cols := PackedColorArray()
		for q in 6:
			var a := t * (1.1 + 0.2 * float(q % 3)) + float(q) * 1.05
			U.bird(pts, cols, Vector2(fx + cos(a) * (40.0 + float(q) * 6.0), fy - 30.0 + sin(a) * 12.0), 1.0, t * 7.0 + float(q), signf(-sin(a)) if sin(a) != 0.0 else 1.0, Color(0.94, 0.94, 0.95, 0.85))
		U.flush(ci, pts, cols)
	# מסדרי גלים קרים
	var pts := PackedVector2Array()
	var cols := PackedColorArray()
	for r in 6:
		var ph := fmod(t * 0.1 + float(r) / 6.0, 1.0)
		var yy := top + 30.0 + ph * (span - 40.0)
		var a := sin(ph * PI) * 0.28
		var amp := 2.0 + ph * 5.0
		var x := -40.0
		var seg := 0
		while x < v.x + 40.0:
			var x2 := x + 48.0
			var w0 := sin((x + sc * (0.9 + ph * 0.4)) * 0.018 + t * 1.1 + float(r)) * amp
			var w1 := sin((x2 + sc * (0.9 + ph * 0.4)) * 0.018 + t * 1.1 + float(r)) * amp
			var c := Color(0.86, 0.9, 0.92, a * (0.4 + 0.6 * _h(seg + r * 50, 3)))
			U.quad(pts, cols, Vector2(x, yy + w0), Vector2(x2, yy + w1), Vector2(x2, yy + w1 + 2.0), Vector2(x, yy + w0 + 2.0), c, c, Color(c, 0.0), Color(c, 0.0))
			x = x2
			seg += 1
	U.flush(ci, pts, cols)


# ---- סוללת חלוקים: עצמות, קשתות צלעות, סירי שמן, מסילה, בית קברות, פטריית ECHO ----
static func near_bones(ci: CanvasItem, sc: float, v: Vector2, y: float, t: float) -> void:
	var base := y - 20.0
	var period := 1000.0
	var start := int(floor(sc / period)) - 1
	var pts := PackedVector2Array()
	var cols := PackedColorArray()
	var glow_at := []
	for k in range(start, start + int(ceil(v.x / period)) + 2):
		var bx := float(k) * period - sc
		if bx > v.x + 60.0 or bx + period < -60.0:
			continue
		var bank := PackedVector2Array([Vector2(bx, base + 30.0)])
		for q in 11:
			bank.append(Vector2(bx + float(q) * 100.0, base - 30.0 - _h(k * 13 + q, 1) * 24.0))
		bank.append(Vector2(bx + period, base + 30.0))
		DrawBatch.colored_polygon(ci, bank, Color("44423e"))
		for q in 36:   # חלוקים
			var px := bx + _h(k * 41 + q, 2) * period
			var py := base - 8.0 - _h(k * 41 + q, 3) * 22.0
			U.oval(pts, cols, Vector2(px, py), 3.0 + _h(k * 41 + q, 4) * 3.0, 2.0 + _h(k * 41 + q, 5) * 1.4, Color("5c5852").lerp(Color("34322e"), _h(k * 41 + q, 6)), 6)
		# טוסוק
		for q in 7:
			var gx := bx + 60.0 + float(q) * 140.0 + _h(k * 7 + q, 7) * 50.0
			var gy := base - 28.0 - _h(k * 7 + q, 8) * 10.0
			for b in 8:
				var lean := -0.5 + float(b) / 7.0
				var sway := sin(t * 2.0 + float(q) * 0.7 + float(b) * 0.3) * 0.14 - 0.12
				var tip := Vector2(gx, gy) + Vector2.from_angle(-PI / 2.0 + lean * 0.9 + sway) * (18.0 + _h(b + q, 9) * 12.0)
				U.tri(pts, cols, Vector2(gx - 3.0 + float(b) * 0.7, gy + 2.0), Vector2(gx - 1.5 + float(b) * 0.7, gy + 2.0), tip, TUSSOCK.lerp(Color("5a5430"), _h(b * 3 + q, 10)))
		var kind := posmod(k, 4)
		if kind == 0:   # קשת צלעות גדולה שבולטת מהחלוקים
			var wx := bx + 380.0
			for r in 6:
				var rx := wx + float(r) * 38.0
				var rh := 92.0 - absf(float(r) - 2.5) * 12.0
				var ln := U.rib_line(Vector2(rx, base - 22.0), Vector2(rx + 34.0, base - 22.0 - rh), -26.0, 8)
				U.strip(pts, cols, ln, 8.0, 3.0, BONE_D.darkened(0.15), BONE_S)
				U.strip(pts, cols, ln, 4.6, 1.6, BONE, BONE_D)
			glow_at.append(Vector2(wx + 90.0, base - 26.0))
		elif kind == 1:   # גולגולת ענקית + חוליות מפוזרות
			var gx := bx + 540.0
			U.quad(pts, cols, Vector2(gx - 90, base - 20), Vector2(gx - 40, base - 62), Vector2(gx + 50, base - 70), Vector2(gx + 90, base - 24), BONE_D, BONE, BONE, BONE_D)
			U.quad(pts, cols, Vector2(gx - 90, base - 20), Vector2(gx - 150, base - 30), Vector2(gx - 200, base - 26), Vector2(gx - 180, base - 18), BONE_D, BONE, BONE_D, BONE_S)
			U.oval(pts, cols, Vector2(gx + 30.0, base - 50.0), 11.0, 8.0, Color("2a2622"), 10)
			for q in 4:
				U.vertebra(pts, cols, Vector2(gx - 260.0 + float(q) * 46.0 + _h(k + q, 11) * 10.0, base - 18.0 - _h(k + q, 12) * 6.0), 8.0 + _h(k + q, 13) * 3.0, BONE, BONE_D)
			glow_at.append(Vector2(gx - 60.0, base - 30.0))
		elif kind == 2:   # בית קברות של ציידים: צלבים לבנים עקומים + סיר שמן חלוד
			for q in 6:
				var cx := bx + 300.0 + float(q) * 44.0 + _h(k * 6 + q, 14) * 12.0
				var lean := (_h(k * 6 + q, 15) - 0.5) * 0.4
				var c := Color("cfcabc").darkened(_h(q, 16) * 0.3)
				var top := Vector2(cx, base - 26.0) + Vector2(sin(lean), -cos(lean)) * 40.0
				U.strip(pts, cols, PackedVector2Array([Vector2(cx, base - 22.0), top]), 4.0, 3.4, c)
				var mid := Vector2(cx, base - 22.0).lerp(top, 0.72)
				var arm := Vector2(cos(lean), sin(lean)) * 11.0
				U.strip(pts, cols, PackedVector2Array([mid - arm, mid + arm]), 3.2, 3.2, c)
			var px := bx + 660.0
			U.oval(pts, cols, Vector2(px, base - 30.0), 30.0, 22.0, RUST_D, 14)
			U.oval(pts, cols, Vector2(px - 4.0, base - 34.0), 24.0, 15.0, RUST, 12)
			U.oval(pts, cols, Vector2(px, base - 50.0), 28.0, 5.0, Color("1e1612"), 10)
		else:   # מסילת גרירה ישנה + חביות עץ שבורות
			for q in 14:
				var rx := bx + 200.0 + float(q) * 30.0
				U.quad(pts, cols, Vector2(rx, base - 18.0), Vector2(rx + 16.0, base - 18.0), Vector2(rx + 18.0, base - 12.0), Vector2(rx - 2.0, base - 12.0), WOOD_D, WOOD_D, WOOD, WOOD)
			U.strip(pts, cols, PackedVector2Array([Vector2(bx + 196.0, base - 20.0), Vector2(bx + 620.0, base - 22.0)]), 3.0, 3.0, Color("3a2a22"))
			for q in 3:
				var cx := bx + 700.0 + float(q) * 34.0
				U.oval(pts, cols, Vector2(cx, base - 30.0), 14.0, 17.0, WOOD.lerp(WOOD_D, 0.3 * float(q)), 12)
				U.strip(pts, cols, PackedVector2Array([Vector2(cx - 13.0, base - 38.0), Vector2(cx + 13.0, base - 38.0)]), 2.2, 2.2, IRON)
				U.strip(pts, cols, PackedVector2Array([Vector2(cx - 13.0, base - 22.0), Vector2(cx + 13.0, base - 22.0)]), 2.2, 2.2, IRON)
			glow_at.append(Vector2(bx + 300.0, base - 22.0))
	U.flush(ci, pts, cols)
	# פטריית ECHO על העצמות - זוהרת ופועמת
	pts = PackedVector2Array()
	cols = PackedColorArray()
	for i in glow_at.size():
		var p: Vector2 = glow_at[i]
		var pulse := 0.5 + 0.5 * sin(t * 1.6 + float(i) * 2.0)
		U.growth(pts, cols, p, 1.1, i * 7 + 3, pulse)
	U.flush(ci, pts, cols)
	for i in glow_at.size():
		Kit.soft_glow(ci, glow_at[i] + Vector2(0, -8), 46.0, Color(0.55, 1.0, 0.45, 0.16 + 0.08 * sin(t * 1.6 + float(i) * 2.0)), 0.6)
	DrawBatch.rect(ci, Rect2(0, base + 12.0, v.x, v.y - base), Color("383632"))


# אובך קר מאחורי הדמויות + ערפל שנסחף
static func grey_overlay(ci: CanvasItem, v: Vector2, t: float) -> void:
	Kit.haze_band(ci, v, 390.0, 614.0, Color(0.7, 0.73, 0.76, 0.22))
	for i in 5:
		var mx := fposmod(float(i) * 320.0 - t * (18.0 + float(i) * 5.0), v.x + 600.0) - 300.0
		Kit.soft_glow(ci, Vector2(mx, 556.0 + float(i % 3) * 18.0), 240.0, Color(0.8, 0.82, 0.84, 0.07 + 0.03 * sin(t * 0.35 + float(i))), 0.22)


# ============================================================
#  עולם
# ============================================================

# ---- חוף: חול געשי כהה, חלוקים, שברי עצם, חלודה, שלוליות, קרשים ----
class GraveGround extends Node2D:
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
		DrawBatch.rect(self, Rect2(0, 0, w, depth), Color("24221f"))
		DrawBatch.rect(self, Rect2(0, 0, w, 14.0), SAND)
		DrawBatch.rect(self, Rect2(0, 10.0, w, 6.0), SAND_D)
		DrawBatch.rect(self, Rect2(0, 16.0, w, 26.0), WET)
		DrawBatch.rect(self, Rect2(0, 0, w, 1.6), Color(0.86, 0.84, 0.8, 0.45))
		var r := RandomNumberGenerator.new()
		r.seed = seed_v
		var pts := PackedVector2Array()
		var cols := PackedColorArray()
		for i in int(w / 5.0):   # חלוקים
			var c := SAND_L.darkened(r.randf() * 0.45).lerp(Color("8a8478"), r.randf() * 0.25)
			U.oval(pts, cols, Vector2(r.randf_range(0.0, w), r.randf_range(2.0, 12.0)), r.randf_range(1.4, 3.2), r.randf_range(1.0, 1.9), c, 6)
		for i in int(w / 34.0):   # שברי עצם לבנים
			var p := Vector2(r.randf_range(0.0, w), r.randf_range(3.0, 11.0))
			var a := r.randf_range(-0.6, 0.6)
			var ln := r.randf_range(4.0, 11.0)
			U.quad(pts, cols, p + Vector2(-ln, -1.0).rotated(a), p + Vector2(ln, -1.0).rotated(a), p + Vector2(ln, 1.0).rotated(a), p + Vector2(-ln, 1.0).rotated(a), BONE, BONE, BONE_D, BONE_D)
			U.oval(pts, cols, p + Vector2(ln, 0).rotated(a), 1.6, 1.4, BONE, 5)
		for i in int(w / 70.0):   # פתיתי חלודה + כתמי שמן ישנים
			var p := Vector2(r.randf_range(0.0, w), r.randf_range(4.0, 12.0))
			U.oval(pts, cols, p, r.randf_range(3.0, 7.0), 1.6, RUST.darkened(r.randf() * 0.4), 6, r.randf_range(-0.3, 0.3))
		for i in int(w / 160.0):   # כתמי שמן לווייתנים כהים
			var p := Vector2(r.randf_range(0.0, w), r.randf_range(18.0, 34.0))
			U.oval(pts, cols, p, r.randf_range(18.0, 40.0), 2.2, Color(0.1, 0.08, 0.06, 0.55), 10)
		for i in int(w / 44.0):   # שלוליות שמשקפות את השמיים
			var p := Vector2(r.randf_range(0.0, w), r.randf_range(20.0, 36.0))
			var pw := r.randf_range(12.0, 30.0)
			U.oval(pts, cols, p, pw, 1.6, Color(0.72, 0.74, 0.76, 0.28), 8)
			U.oval(pts, cols, p + Vector2(pw * 0.3, -0.3), pw * 0.3, 0.6, Color(1.0, 0.85, 0.65, 0.22), 6)
		if r.randf() < 0.7:   # קרשי מדרכה ישנים
			var px := r.randf_range(40.0, w - 220.0)
			for q in r.randi_range(4, 8):
				var x := px + float(q) * 22.0
				U.quad(pts, cols, Vector2(x, 2.0), Vector2(x + 19.0, 2.5), Vector2(x + 19.0, 7.0), Vector2(x, 6.5), WOOD_L.darkened(0.3 + 0.1 * float(q % 2)), WOOD_L.darkened(0.3), WOOD.darkened(0.3), WOOD.darkened(0.3))
		U.flush(self, pts, cols)
		for i in int(w / 28.0):
			DrawBatch.circle(self, Vector2(r.randf_range(0.0, w), r.randf_range(46.0, depth - 6.0)), r.randf_range(1.5, 3.5), Color("34302c"))


# ============================================================
#  שער לסתות הלווייתן בכניסה + השלט
# ============================================================
class BoneArch extends Node2D:
	var w := 230.0
	var hgt := 300.0

	func _ready() -> void:
		z_index = -2

	func _draw() -> void:
		DrawBatch.begin(self)
		_draw_b()
		DrawBatch.end(self)

	func _draw_b() -> void:
		var pts := PackedVector2Array()
		var cols := PackedColorArray()
		# שתי לסתות שנפגשות למעלה (קשת גותית)
		for s in 2:
			var sx := 0.0 if s == 0 else w
			var sgn := 1.0 if s == 0 else -1.0
			var line := PackedVector2Array()
			for q in 12:
				var u := float(q) / 11.0
				line.append(Vector2(sx + sgn * (sin(u * PI * 0.5) * w * 0.5 - u * u * 6.0), -u * hgt + sin(u * PI) * 10.0))
			U.strip(pts, cols, line, 22.0, 9.0, BONE_D.darkened(0.2), BONE_S)
			U.strip(pts, cols, line, 15.0, 5.0, BONE, BONE_D)
			# בסיס בתוך חבית חלודה
			U.rect(pts, cols, Rect2(sx - 18.0, -34.0, 36.0, 34.0), RUST_D)
			U.rect(pts, cols, Rect2(sx - 16.0, -32.0, 30.0, 30.0), RUST)
			U.rect(pts, cols, Rect2(sx - 18.0, -24.0, 36.0, 3.0), IRON)
			U.rect(pts, cols, Rect2(sx - 18.0, -10.0, 36.0, 3.0), IRON)
			# כתמי זמן וסדקים
			for q in 4:
				var p: Vector2 = line[2 + q * 2]
				U.oval(pts, cols, p + Vector2(sgn * 2.0, 0), 3.0, 6.0, BONE_S, 6, 0.3 * sgn)
		U.flush(self, pts, cols)
		# השלט התלוי מהשרשראות
		var c := Vector2(w * 0.5, -hgt * 0.62)
		DrawBatch.line(self, Vector2(w * 0.5 - 50.0, -hgt * 0.8), c + Vector2(-50, 0), Color("2a2420"), 1.6)
		DrawBatch.line(self, Vector2(w * 0.5 + 50.0, -hgt * 0.8), c + Vector2(50, 0), Color("2a2420"), 1.6)
		DrawBatch.rect(self, Rect2(c.x - 70.0, c.y, 140.0, 40.0), Color("5a4430"))
		DrawBatch.rect(self, Rect2(c.x - 70.0, c.y, 140.0, 40.0), Color("2a1e14"), false, 2.0)
		DrawBatch.string(self, ThemeDB.fallback_font, c + Vector2(-56, 18), "PUERTO HUESO", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("e8dcc0"))
		DrawBatch.string(self, ThemeDB.fallback_font, c + Vector2(-52, 33), "CIA. BALLENERA 1911", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("c8b898"))
		# פטריית ECHO במפגש הלסתות
		var p2 := PackedVector2Array()
		var c2 := PackedColorArray()
		U.growth(p2, c2, Vector2(w * 0.5, -hgt + 18.0), 1.2, 11, 0.6)
		U.growth(p2, c2, Vector2(w - 8.0, -36.0), 0.9, 23, 0.4)
		U.flush(self, p2, c2)
		Kit.soft_glow(self, Vector2(w * 0.5, -hgt + 10.0), 40.0, Color(0.55, 1.0, 0.45, 0.22), 0.7)


# ============================================================
#  מיכל שמן לווייתנים חלוד (גג = קומה) + כתובת הכוורת בפטרייה זוהרת
# ============================================================
class OilTank extends Node2D:
	var w := 180.0
	var tier := 170.0
	var seed_v := 0
	var words := ""                 # כתובת הכוורת ("" = בלי)
	var _t := 0.0

	func _ready() -> void:
		z_index = -2

	func _process(delta: float) -> void:
		if words == "":
			return
		_t += delta
		if Engine.get_process_frames() % 6 == 0 and Art.on_screen(self, global_position + Vector2(w * 0.5, -tier * 0.5), w):
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
		var bands := 12
		for q in bands:   # גליל: הצללה
			var k := float(q) / float(bands)
			var shade := 0.72 + 0.38 * sin(k * PI) - 0.22 * k
			U.rect(pts, cols, Rect2(w * k, -tier, w / float(bands) + 1.0, tier), RUST.lerp(RUST_D, 1.0 - shade))
		for q in 5:   # תפרים אופקיים
			var yy := -tier + 10.0 + float(q) * (tier - 20.0) / 4.0
			U.rect(pts, cols, Rect2(0, yy - 1.0, w, 2.0), Color(0.22, 0.1, 0.05, 0.75))
		for q in 9:   # חלודה זולגת
			var rx := r.randf_range(8.0, w - 8.0)
			var ln := r.randf_range(30.0, tier * 0.85)
			var ww := r.randf_range(3.0, 7.0)
			U.quad(pts, cols, Vector2(rx - ww * 0.5, -tier + 4.0), Vector2(rx + ww * 0.5, -tier + 4.0), Vector2(rx + 1.0, -tier + ln), Vector2(rx - 1.0, -tier + ln), Color(0.28, 0.1, 0.04, 0.5), Color(0.28, 0.1, 0.04, 0.5), Color(0.28, 0.1, 0.04, 0.0), Color(0.28, 0.1, 0.04, 0.0))
		# גג שטוח + מעקה
		U.quad(pts, cols, Vector2(-4, -tier), Vector2(w + 4, -tier), Vector2(w - 10, -tier - 8), Vector2(10, -tier - 8), RUST_L.darkened(0.25), RUST_L.darkened(0.25), RUST_L.darkened(0.1), RUST_L.darkened(0.1))
		for q in int(w / 22.0) + 1:
			U.rect(pts, cols, Rect2(float(q) * 22.0 - 1.0, -tier - 26.0, 2.0, 18.0), Color("2a1c16"))
		U.rect(pts, cols, Rect2(0, -tier - 27.0, w, 2.4), Color("2a1c16"))
		U.rect(pts, cols, Rect2(0, -tier - 17.0, w, 1.4), Color("2a1c16"))
		# צינור, ברז ושלולית שמן ישנה
		U.rect(pts, cols, Rect2(w - 14.0, -42.0, 34.0, 10.0), RUST_D)
		U.oval(pts, cols, Vector2(w + 22.0, -37.0), 7.0, 7.0, Color("5a2416"), 10)
		U.oval(pts, cols, Vector2(w + 12.0, -2.0), 32.0, 3.0, Color(0.08, 0.06, 0.05, 0.6), 12)
		# פטריית ECHO שעולה מהבסיס
		if words != "":
			var pulse := 0.5 + 0.5 * sin(_t * 1.8)
			for q in 4:
				U.growth(pts, cols, Vector2(16.0 + float(q) * (w - 30.0) / 3.0, -2.0), 0.8 + 0.3 * float(q % 2), seed_v + q * 5, pulse)
		U.flush(self, pts, cols)
		DrawBatch.string(self, ThemeDB.fallback_font, Vector2(14.0, -tier + 30.0), "C.B. PUERTO HUESO", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.92, 0.82, 0.62, 0.3))
		if words != "":   # הכתובת: אותיות של פטרייה זוהרת שהכוורת "כתבה" על המיכל
			var pulse2 := 0.5 + 0.5 * sin(_t * 1.8)
			var lines := words.split("|")
			for i in lines.size():
				var yy := -tier * 0.62 + float(i) * 26.0
				Kit.soft_glow(self, Vector2(w * 0.5, yy - 8.0), w * 0.55, Color(0.55, 1.0, 0.45, 0.10 + 0.08 * pulse2), 0.22)
				DrawBatch.string(self, ThemeDB.fallback_font, Vector2(4.0, yy), lines[i], HORIZONTAL_ALIGNMENT_CENTER, w - 8.0, 20, Color(0.7, 1.0, 0.55, 0.62 + 0.3 * pulse2))


# ============================================================
#  משטח ההפשטה: במת עץ על כלונסאות (קומה), כננת, ווים, לווייתן חצי מופשט מאחור
# ============================================================
class FlensingPlan extends Node2D:
	var w := 520.0
	var tier := 140.0

	func _ready() -> void:
		z_index = -2

	func _draw() -> void:
		DrawBatch.begin(self)
		_draw_b()
		DrawBatch.end(self)

	func _draw_b() -> void:
		var pts := PackedVector2Array()
		var cols := PackedColorArray()
		# הלווייתן החצי מופשט על הבמה (מאחורי הקרשים): גב כהה, בשר אדום, שומן לבן בפסים, צלעות חשופות
		var cx := w * 0.55
		var cy := -tier - 6.0
		U.oval(pts, cols, Vector2(cx, cy - 34.0), 210.0, 44.0, SKIN_W, 22)
		U.oval(pts, cols, Vector2(cx - 20.0, cy - 50.0), 170.0, 22.0, SKIN_WL, 18)
		U.oval(pts, cols, Vector2(cx + 30.0, cy - 22.0), 140.0, 26.0, MEAT, 18)
		for q in 7:   # פסי שומן שנחתכו
			var x := cx - 90.0 + float(q) * 32.0
			U.quad(pts, cols, Vector2(x, cy - 44.0), Vector2(x + 14.0, cy - 44.0), Vector2(x + 18.0, cy - 6.0), Vector2(x + 4.0, cy - 6.0), Color("e8dcc8"), Color("e8dcc8"), Color("c8a898"), Color("c8a898"))
		for q in 6:   # צלעות חשופות
			var x := cx + 80.0 + float(q) * 16.0
			U.strip(pts, cols, U.rib_line(Vector2(x, cy - 2.0), Vector2(x + 10.0, cy - 60.0), 10.0, 6), 5.0, 2.4, BONE, BONE_D)
		# זנב
		U.quad(pts, cols, Vector2(cx - 200.0, cy - 40.0), Vector2(cx - 250.0, cy - 66.0), Vector2(cx - 262.0, cy - 30.0), Vector2(cx - 200.0, cy - 22.0), SKIN_W, SKIN_W, SKIN_W.darkened(0.2), SKIN_W)
		# כלונסאות + קורות
		for q in int(w / 60.0) + 1:
			var x := minf(float(q) * 60.0 + 6.0, w - 8.0)
			U.rect(pts, cols, Rect2(x, -tier, 9.0, tier), WOOD_D)
			U.rect(pts, cols, Rect2(x + 1.0, -tier, 2.0, tier), WOOD.darkened(0.1))
		for q in 2:
			U.quad(pts, cols, Vector2(0, -tier * 0.35 - float(q) * 40.0), Vector2(w, -tier * 0.55 - float(q) * 40.0), Vector2(w, -tier * 0.55 - float(q) * 40.0 + 5.0), Vector2(0, -tier * 0.35 - float(q) * 40.0 + 5.0), WOOD_D, WOOD_D, WOOD_D, WOOD_D)
		# קרשי הבמה (עבים) + כתמי דם ישן
		U.rect(pts, cols, Rect2(-6.0, -tier - 2.0, w + 12.0, 12.0), WOOD)
		U.rect(pts, cols, Rect2(-6.0, -tier - 2.0, w + 12.0, 2.0), WOOD_L)
		for q in int(w / 26.0):
			U.rect(pts, cols, Rect2(float(q) * 26.0, -tier, 1.4, 10.0), WOOD_D)
		for q in 5:
			U.oval(pts, cols, Vector2(40.0 + float(q) * 100.0, -tier + 4.0), 22.0, 2.4, Color(OLD_BLOOD, 0.7), 10)
			U.quad(pts, cols, Vector2(44.0 + float(q) * 100.0, -tier + 8.0), Vector2(48.0 + float(q) * 100.0, -tier + 8.0), Vector2(47.0 + float(q) * 100.0, -tier + 30.0 + float(q % 3) * 12.0), Vector2(45.0 + float(q) * 100.0, -tier + 30.0 + float(q % 3) * 12.0), Color(OLD_BLOOD, 0.7), Color(OLD_BLOOD, 0.7), Color(OLD_BLOOD, 0.0), Color(OLD_BLOOD, 0.0))
		# כננת קיטור בקצה
		U.rect(pts, cols, Rect2(w - 70.0, -tier - 38.0, 50.0, 36.0), IRON)
		U.oval(pts, cols, Vector2(w - 45.0, -tier - 24.0), 15.0, 15.0, Color("4a4440"), 14)
		U.oval(pts, cols, Vector2(w - 45.0, -tier - 24.0), 8.0, 8.0, Color("2a2420"), 10)
		U.flush(self, pts, cols)
		# כבל מהכננת אל הלווייתן, ווי הפשטה תלויים
		DrawBatch.line(self, Vector2(w - 45.0, -tier - 38.0), Vector2(cx + 120.0, cy - 60.0), Color("2a2622"), 2.0)
		DrawBatch.string(self, ThemeDB.fallback_font, Vector2(14.0, -tier + 26.0), "PLAN No 1", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.9, 0.82, 0.62, 0.45))


# ============================================================
#  פגר לווייתן מכוסה ECHO: שלפוחיות זוהרות, "רחם" של BONECRAWLER
# ============================================================
class EchoCarcass extends Node2D:
	const TRIG_R := 420.0
	const WARN_T := 1.1
	const CLOUD_R := 280.0
	const SWAY_T := 2.2
	const PUS_HP := 8
	var w := 420.0
	var spawn_kind := -1            # (נקבע ע"י השלב) איזה זומבי נולד
	var births := 1
	var state := 0                  # 0 שקט, 1 מתנשם, 2 נפרץ
	var born := 0                   # לבדיקות
	var popped := 0
	var stillborn := 0
	var clouds := 0
	var _t := 0.0
	var _st := 0.0
	var _pus := []                  # [x, y, r, hp, body]
	var _puffs := []                # [x, y, t, size]
	var _gulls := []                # [x, phase, flying t]
	var _burst_t := -1.0

	func _ready() -> void:
		z_index = -2
		add_to_group("s58_carcass")
		add_to_group("blastable")
		var r := RandomNumberGenerator.new()
		r.seed = int(global_position.x)
		for i in 5:
			var p := Vector2(w * (0.18 + 0.16 * float(i)) + r.randf_range(-14, 14), -60.0 - r.randf_range(0.0, 50.0) * sin(float(i + 1) / 6.0 * PI))
			var b := PustuleBody.new()
			b.trap = self
			b.idx = i
			b.collision_layer = 4
			b.collision_mask = 0
			b.add_to_group("no_outline")
			var cs := CollisionShape2D.new()
			var cc := CircleShape2D.new()
			cc.radius = 13.0
			cs.shape = cc
			b.add_child(cs)
			b.position = p
			add_child(b)
			_pus.append([p.x, p.y, r.randf_range(9.0, 13.0), PUS_HP, b])
		for i in 3:
			_gulls.append([w * (0.2 + 0.3 * float(i)), r.randf() * TAU, -1.0])

	func blast_rect() -> Rect2:
		return Rect2(global_position + Vector2(0, -150), Vector2(w, 150))

	func hit_by_blast(_c: Vector2, _r: float) -> void:
		for i in _pus.size():
			pop(i)
		scare()

	func alive_pus() -> int:
		var n := 0
		for p in _pus:
			if int(p[3]) > 0:
				n += 1
		return n

	func scare() -> void:
		for g in _gulls:
			if float(g[2]) < 0.0:
				g[2] = 0.0

	func pop(i: int) -> void:
		var p: Array = _pus[i]
		if int(p[3]) <= 0:
			return
		p[3] = 0
		popped += 1
		var b: StaticBody2D = p[4]
		if is_instance_valid(b):
			b.collision_layer = 0
		_puffs.append([float(p[0]), float(p[1]), 0.0, 1.0])
		var at := global_position + Vector2(float(p[0]), float(p[1]))
		Sfx.play("s58_pop", at, 0.0, 0.15, 3)
		Particles.burst(get_parent(), at, "mist", Vector2.UP, 5)
		scare()
		if state == 0 and alive_pus() == 0 and births > 0:   # כל השלפוחיות פוצצו לפני הלידה
			births = 0
			stillborn += 1
			state = 2
			_burst_t = 0.0
			Sfx.play("s58_gurgle", global_position + Vector2(w * 0.5, -60), 0.0, 0.1, 2, 0.8)
			var pl := get_tree().get_first_node_in_group("player")
			if pl != null and pl.has_method("_say"):
				pl._say("STILLBORN. Whatever was growing in there is dead.", Color("b8ff9a"))

	func hit_pus(i: int, dmg: int) -> void:
		if state == 2:
			return
		var p: Array = _pus[i]
		p[3] = int(p[3]) - dmg
		if int(p[3]) <= 0:
			p[3] = 1
			pop(i)

	func _physics_process(delta: float) -> void:
		_t += delta
		var pl := get_tree().get_first_node_in_group("player") as Node2D
		var cx := global_position.x + w * 0.5
		match state:
			0:
				if births > 0 and pl != null and not pl.dead and absf(pl.global_position.x - cx) < TRIG_R and absf(pl.global_position.y - global_position.y) < 200.0:
					state = 1
					_st = WARN_T
					Sfx.play("s58_gurgle", global_position + Vector2(w * 0.5, -60), 3.0, 0.1, 2)
					scare()
			1:
				_st -= delta
				if _st <= 0.0:
					_birth(pl)
		if _burst_t >= 0.0:
			_burst_t += delta
		for g in _gulls:
			if float(g[2]) >= 0.0:
				g[2] = float(g[2]) + delta
		var i := 0
		while i < _puffs.size():
			_puffs[i][2] = float(_puffs[i][2]) + delta
			if float(_puffs[i][2]) > 2.2:
				_puffs.remove_at(i)
			else:
				i += 1
		if Engine.get_physics_frames() % 3 == 0 and Art.on_screen(self, global_position + Vector2(w * 0.5, -80), w):
			queue_redraw()

	func _birth(pl: Node2D) -> void:
		state = 2
		_burst_t = 0.0
		births -= 1
		clouds += 1
		for q in _pus.size():
			var p: Array = _pus[q]
			if int(p[3]) > 0:
				p[3] = 0
				var b: StaticBody2D = p[4]
				if is_instance_valid(b):
					b.collision_layer = 0
			_puffs.append([float(p[0]), float(p[1]), 0.0, 1.8])
		var side := 1.0
		if pl != null:
			side = signf(pl.global_position.x - (global_position.x + w * 0.5))
		var bx := global_position.x + w * 0.5 + side * w * 0.3
		Sfx.play("s58_burst", Vector2(bx, global_position.y - 60.0), 5.0, 0.05, 2)
		Particles.burst(get_parent(), Vector2(bx, global_position.y - 60.0), "hit", Vector2(side, -0.6), int(26.0 * Quality.gore()) + 4)
		Particles.burst(get_parent(), Vector2(bx, global_position.y - 70.0), "mist", Vector2.UP, 12)
		var cam := get_viewport().get_camera_2d()
		if cam != null and cam.has_method("shake"):
			cam.shake(9.0, 0.35)
		var m := get_parent()
		if spawn_kind >= 0 and m != null and m.has_method("_spawn_zombie"):
			var z = m._spawn_zombie(bx, global_position.y, spawn_kind)
			if z != null:
				z.dormant = false
				z.set_meta("s58_born", true)
				z._dir = side
				z.velocity = Vector2(side * 260.0, -260.0)
				born += 1
		if pl != null and not pl.dead and absf(pl.global_position.x - bx) < CLOUD_R:
			pl.aim_sway(SWAY_T, "SPORES - CAN'T AIM STRAIGHT")

	func _draw() -> void:
		DrawBatch.begin(self)
		_draw_b()
		DrawBatch.end(self)

	func _draw_b() -> void:
		var pts := PackedVector2Array()
		var cols := PackedColorArray()
		var heave := 0.0
		if state == 1:
			heave = sin(_t * 22.0) * 3.0 * (1.0 - _st / WARN_T)
		var c := Vector2(w * 0.5, -58.0 + heave)
		# הגוף: לווייתן על הצד, עור כהה עם קפלי גרון, הבטן נפוחה
		U.oval(pts, cols, Vector2(w * 0.5, -6.0), w * 0.56, 8.0, Color(0.06, 0.05, 0.05, 0.55), 18)
		U.oval(pts, cols, c, w * 0.5, 58.0, SKIN_W, 26)
		U.oval(pts, cols, c + Vector2(-10, -24), w * 0.42, 24.0, SKIN_WL, 22)
		U.oval(pts, cols, c + Vector2(30, 26), w * 0.38, 22.0, Color("c0aca0"), 22)   # בטן חיוורת
		for q in 9:   # קפלי הגרון
			var x := w * 0.3 + float(q) * 24.0
			U.quad(pts, cols, Vector2(x, c.y + 18.0), Vector2(x + 2.0, c.y + 18.0), Vector2(x + 30.0, c.y + 44.0), Vector2(x + 28.0, c.y + 44.0), Color("8a7a70"), Color("8a7a70"), Color("8a7a70"), Color("8a7a70"))
		# הראש בצד ימין (פה פתוח עם מזיפות), הזנב שמאלה
		U.quad(pts, cols, Vector2(w * 0.94, c.y - 30.0), Vector2(w * 1.06, c.y - 6.0), Vector2(w * 1.04, c.y + 30.0), Vector2(w * 0.92, c.y + 40.0), SKIN_W, SKIN_W.darkened(0.2), SKIN_W.darkened(0.3), SKIN_W)
		for q in 8:
			U.rect(pts, cols, Rect2(w * 0.95 + float(q) * 4.0, c.y + 4.0, 2.4, 22.0 - float(q)), Color("1e1a18"))
		U.quad(pts, cols, Vector2(10.0, c.y - 8.0), Vector2(-46.0, c.y - 40.0), Vector2(-56.0, c.y + 20.0), Vector2(14.0, c.y + 16.0), SKIN_W, SKIN_W, SKIN_W.darkened(0.25), SKIN_W)
		# הצד הקרוע: בשר אדום-שחור וצלעות חשופות
		var rip := c + Vector2(w * 0.08, -6.0)
		U.oval(pts, cols, rip, 90.0, 34.0, Color("3a0e0c"), 18)
		U.oval(pts, cols, rip + Vector2(4, 4), 76.0, 26.0, MEAT, 16)
		var open_k := 0.0 if state != 2 else clampf(_burst_t / 0.25, 0.0, 1.0)
		for q in 7:
			var x := rip.x - 66.0 + float(q) * 22.0
			var bend := 12.0 + open_k * 18.0 * (1.0 if q > 3 else -1.0)
			U.strip(pts, cols, U.rib_line(Vector2(x, rip.y + 28.0), Vector2(x + 6.0, rip.y - 34.0), bend, 6), 6.0, 3.0, BONE, BONE_D)
		# גידולי ECHO: חוטים לבנים, גבעולי פטרייה, שלפוחיות זוהרות
		var pulse := 0.5 + 0.5 * sin(_t * (2.0 if state == 0 else 9.0))
		for q in 10:
			var a := Vector2(w * (0.1 + 0.08 * float(q)), c.y - 40.0 + float(q % 3) * 14.0)
			var b := a + Vector2(18.0, 22.0 + float(q % 2) * 10.0)
			U.strip(pts, cols, PackedVector2Array([a, a.lerp(b, 0.5) + Vector2(0, -6), b]), 1.4, 0.6, Color(0.9, 0.95, 0.8, 0.55))
		for q in 6:
			U.growth(pts, cols, Vector2(w * (0.12 + 0.15 * float(q)), c.y - 50.0 + float(q % 2) * 10.0), 1.0 + 0.2 * float(q % 3), q * 13 + 7, pulse)
		var glows := []
		for p in _pus:
			if int(p[3]) <= 0:
				U.oval(pts, cols, Vector2(float(p[0]), float(p[1]) + heave), float(p[2]) * 0.8, float(p[2]) * 0.5, Color("2a3418"), 10)
				continue
			var swell := 1.0 + (0.3 * (1.0 - _st / WARN_T) if state == 1 else 0.0) + 0.06 * pulse
			var pc := Vector2(float(p[0]), float(p[1]) + heave)
			var rr: float = float(p[2]) * swell
			U.oval(pts, cols, pc, rr + 2.0, rr * 0.9 + 2.0, SPORE_D, 12)
			U.oval(pts, cols, pc, rr, rr * 0.9, SPORE.lerp(Color(1, 1, 0.8), 0.25 * pulse), 12)
			U.oval(pts, cols, pc + Vector2(-rr * 0.3, -rr * 0.35), rr * 0.35, rr * 0.25, Color(1, 1, 1, 0.55), 8)
			glows.append([pc, rr])
		# שחפים שמנקרים (עפים כשמפחידים אותם)
		for g in _gulls:
			var ft: float = g[2]
			var gp := Vector2(float(g[0]), c.y - 58.0)
			if ft >= 0.0:
				gp += Vector2(ft * 140.0 * (1.0 if float(g[0]) > w * 0.5 else -1.0), -ft * ft * 160.0 - ft * 60.0)
				if ft < 4.0:
					U.bird(pts, cols, gp, 1.8, _t * 14.0 + float(g[1]), 1.0 if float(g[0]) > w * 0.5 else -1.0, Color(0.95, 0.95, 0.96))
				continue
			var peck := maxf(0.0, sin(_t * 3.0 + float(g[1])))
			U.oval(pts, cols, gp, 7.0, 4.2, Color("eef0f0"), 10)
			U.oval(pts, cols, gp + Vector2(-2.0, -1.8), 5.4, 2.4, Color("8a949c"), 8)
			U.oval(pts, cols, gp + Vector2(6.0, -4.0 + peck * 4.0), 2.8, 2.6, Color("f4f4f2"), 8)
			U.tri(pts, cols, gp + Vector2(7.5, -4.5 + peck * 4.0), gp + Vector2(12.5, -3.2 + peck * 6.0), gp + Vector2(7.5, -2.8 + peck * 4.0), Color("e8b030"))
			U.tri(pts, cols, gp + Vector2(-5.0, -1.0), gp + Vector2(-12.0, -2.0), gp + Vector2(-5.0, 1.6), Color("1e2024"))
		# ענני נבגים (פוצצו / לידה)
		for pf in _puffs:
			var k: float = float(pf[2]) / 2.2
			var s: float = float(pf[3])
			for q in 7:
				var a := float(q) * 0.9 + float(pf[0])
				var pp := Vector2(float(pf[0]), float(pf[1])) + Vector2(cos(a), sin(a) * 0.6 - 0.8) * (10.0 + 50.0 * k) * s
				U.oval(pts, cols, pp, (6.0 + 16.0 * k) * s, (5.0 + 12.0 * k) * s, Color(0.65, 1.0, 0.55, 0.35 * (1.0 - k)), 8)
		U.flush(self, pts, cols)
		for gl in glows:
			Art.glow(self, gl[0], float(gl[1]) * 2.2, Color(0.55, 1.0, 0.45, 0.25 + 0.15 * pulse))
		if state == 1:
			DrawBatch.string(self, ThemeDB.fallback_font, c + Vector2(-6, -90), "!", HORIZONTAL_ALIGNMENT_LEFT, -1, 30, Color(0.7, 1.0, 0.5, 0.6 + 0.4 * sin(_t * 30.0)))


class PustuleBody extends StaticBody2D:
	var trap = null
	var idx := 0

	func take_damage(amount: int, _hit_pos: Vector2, _dir: Vector2, _explosive := false, src := {}) -> void:
		if trap != null and is_instance_valid(trap):
			var d := 10
			if src.has("fixed"):
				d = int(src.fixed)
			elif amount > 0:
				d = amount
			trap.hit_pus(idx, d)


# ============================================================
#  ספינת ציד חלודה על מסילת הגרירה: סיפון (deck) + גג תא ההגה (cab) = קומות. החרטום שמאלה
# ============================================================
class CatcherBoat extends Node2D:
	var w := 380.0
	var deck := 120.0
	var cab := 215.0
	var cab_x := Vector2(200.0, 300.0)   # תא ההגה (x0, x1)

	func _ready() -> void:
		z_index = -2

	func _draw() -> void:
		DrawBatch.begin(self)
		_draw_b()
		DrawBatch.end(self)

	func _draw_b() -> void:
		var pts := PackedVector2Array()
		var cols := PackedColorArray()
		# מסילת הגרירה (קורות עץ) מתחת
		for q in 9:
			var x := -40.0 + float(q) * 52.0
			U.quad(pts, cols, Vector2(x, -12.0), Vector2(x + 40.0, -16.0), Vector2(x + 40.0, -8.0), Vector2(x, -4.0), WOOD_D, WOOD_D, WOOD, WOOD)
		# גוף הספינה: שחור-חלוד, חרטום חד שמאלה, ירכתיים מעוגלות
		var hull := PackedVector2Array([Vector2(-50, -deck - 14), Vector2(10, -deck), Vector2(w - 10, -deck), Vector2(w + 10, -deck - 10), Vector2(w - 6, -deck * 0.4), Vector2(w - 40, -16), Vector2(60, -14), Vector2(0, -deck * 0.45)])
		DrawBatch.colored_polygon(self, hull, Color("26201e"))
		U.quad(pts, cols, Vector2(60, -14), Vector2(w - 40, -16), Vector2(w - 30, -40), Vector2(30, -38), Color("6a2a1e"), Color("6a2a1e"), Color("7a3222"), Color("7a3222"))   # צבע אדום מתחת לקו המים
		for q in 12:   # חלודה זולגת מהמסמרות
			var x := 30.0 + float(q) * 28.0
			U.quad(pts, cols, Vector2(x, -deck + 6.0), Vector2(x + 5.0, -deck + 6.0), Vector2(x + 3.0, -deck + 40.0 + float(q % 4) * 12.0), Vector2(x + 1.0, -deck + 40.0 + float(q % 4) * 12.0), Color(0.55, 0.22, 0.1, 0.7), Color(0.55, 0.22, 0.1, 0.7), Color(0.55, 0.22, 0.1, 0.0), Color(0.55, 0.22, 0.1, 0.0))
		for q in 3:   # שורות מסמרות
			var yy := -deck + 18.0 + float(q) * 26.0
			for k in 24:
				U.oval(pts, cols, Vector2(24.0 + float(k) * 15.0, yy), 1.1, 1.1, Color(0.6, 0.35, 0.25, 0.6), 4)
		U.quad(pts, cols, Vector2(-50, -deck - 14), Vector2(w + 10, -deck - 10), Vector2(w + 10, -deck - 6), Vector2(-46, -deck - 10), Color("8a7a6a"), Color("8a7a6a"), Color("5a4a40"), Color("5a4a40"))   # שפת הסיפון
		# תא ההגה + גשר
		var cx0: float = cab_x.x
		var cx1: float = cab_x.y
		U.rect(pts, cols, Rect2(cx0, -cab, cx1 - cx0, cab - deck), Color("d4ccbc"))
		U.rect(pts, cols, Rect2(cx0, -cab, cx1 - cx0, 6.0), Color("6a5a4c"))
		for q in 4:
			U.rect(pts, cols, Rect2(cx0 + 10.0 + float(q) * 22.0, -cab + 16.0, 14.0, 16.0), Color("1a1c20"))
		U.rect(pts, cols, Rect2(cx0, -cab + 46.0, cx1 - cx0, 4.0), Color(0.4, 0.2, 0.1, 0.5))
		# ארובה (שחורה עם פס אדום) מאחורי התא
		U.rect(pts, cols, Rect2(cx1 + 10.0, -cab - 50.0, 30.0, cab - deck + 50.0), Color("1e1e20"))
		U.rect(pts, cols, Rect2(cx1 + 10.0, -cab - 34.0, 30.0, 10.0), Color("a02a20"))
		U.rect(pts, cols, Rect2(cx1 + 8.0, -cab - 54.0, 34.0, 6.0), Color("101010"))
		U.flush(self, pts, cols)
		# תורן עם קן עורב (שם יושבת סקואה)
		DrawBatch.line(self, Vector2(110, -deck), Vector2(104, -deck - 210), Color("2a2420"), 5.0)
		DrawBatch.rect(self, Rect2(88, -deck - 196, 32, 16), Color("4a3a2c"))
		DrawBatch.line(self, Vector2(104, -deck - 210), Vector2(-50, -deck - 14), Color(0.15, 0.13, 0.12, 0.7), 1.0)
		DrawBatch.line(self, Vector2(104, -deck - 210), Vector2(w, -deck - 6), Color(0.15, 0.13, 0.12, 0.7), 1.0)
		DrawBatch.string(self, ThemeDB.fallback_font, Vector2(150, -deck + 40), "TORMENTA", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(0.9, 0.86, 0.76, 0.75))
		DrawBatch.string(self, ThemeDB.fallback_font, Vector2(160, -deck + 56), "PUERTO HUESO", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.9, 0.86, 0.76, 0.55))


# ============================================================
#  מלכודת: תותח צלצל עם תותחן מת שגדל לתוכו. מכוון אליך, ננעל, יורה צלצל שמשפד את מה שבדרך.
# ============================================================
class HarpoonGun extends Node2D:
	const RANGE := 780.0
	const AIM_T := 0.9
	const LOCK_T := 0.45
	const CD := 3.2
	const DMG := 2
	const DMG_Z := 110
	const GUNNER_HP := 40
	var face := -1.0                # לאיזה צד הוא יורה
	var pedestal := 0.0             # גובה בסיס בטון (0 = על החרטום)
	var state := 0                  # 0 מחכה, 1 מכוון, 2 נעול, 3 טוען, 4 התותחן מת
	var shots := 0                  # לבדיקות
	var hits := 0
	var impaled := 0
	var _t := 0.0
	var _st := 0.0
	var _cd := 1.5
	var _ang := 0.0                 # זווית הקנה (0 = ישר קדימה, חיובי = למטה)
	var _lock := Vector2.ZERO
	var _ghp := GUNNER_HP
	var _flash := 0.0
	var _recoil := 0.0
	var _body: StaticBody2D = null

	func _ready() -> void:
		z_index = 3
		add_to_group("hazards")
		add_to_group("blastable")
		_body = GunnerBody.new()
		_body.trap = self
		_body.collision_layer = 4
		_body.collision_mask = 0
		_body.add_to_group("no_outline")
		var cs := CollisionShape2D.new()
		var rs := RectangleShape2D.new()
		rs.size = Vector2(22, 38)
		cs.shape = rs
		_body.add_child(cs)
		_body.position = Vector2(-face * 22.0, -pedestal - 34.0)
		add_child(_body)

	func muzzle() -> Vector2:
		return Vector2(0, -pedestal - 30.0) + Vector2(face * cos(_ang), sin(_ang)) * 46.0

	func world_rect() -> Rect2:
		return Rect2(global_position + Vector2(minf(0.0, face * RANGE), -pedestal - 60.0), Vector2(RANGE, pedestal + 60.0))

	func danger_at(p: Vector2, margin := 0.0) -> bool:
		return state == 2 and world_rect().grow(margin).has_point(p)

	func blast_rect() -> Rect2:
		return Rect2(global_position + Vector2(-40, -pedestal - 60), Vector2(80, 60))

	func hit_by_blast(_c: Vector2, _r: float) -> void:
		hurt_gunner(GUNNER_HP)

	func hurt_gunner(d: int) -> void:
		if state == 4:
			return
		_ghp -= d
		_flash = 0.08
		var at := global_position + _body.position
		Particles.burst(get_parent(), at, "hit", Vector2(-face, -0.4), 8)
		if _ghp <= 0:
			state = 4
			_body.collision_layer = 0
			Sfx.play("zdeath", at, 0.0, 0.08, 2, 0.8)
			Particles.burst(get_parent(), at, "hit", Vector2.UP, int(18.0 * Quality.gore()) + 4)
			Particles.burst(get_parent(), at, "mist", Vector2.UP, 6)
			var pl := get_tree().get_first_node_in_group("player")
			if pl != null and pl.has_method("_say"):
				pl._say("GUNNER DOWN", Color("ffd34a"))

	func _physics_process(delta: float) -> void:
		_t += delta
		_flash -= delta
		_recoil = maxf(0.0, _recoil - delta * 3.0)
		if state == 4:
			_ang = move_toward(_ang, 0.5, delta)
			if Engine.get_physics_frames() % 6 == 0 and Art.on_screen(self, global_position, 200.0):
				queue_redraw()
			return
		_cd -= delta
		var pl := get_tree().get_first_node_in_group("player") as Node2D
		var mz := global_position + Vector2(0, -pedestal - 30.0)
		var has: bool = pl != null and not pl.dead
		var tgt := (pl.global_position + Vector2(0, -30.0)) if has else Vector2.ZERO
		var in_lane: bool = has and (tgt.x - mz.x) * face > 60.0 and absf(tgt.x - mz.x) < RANGE and absf(tgt.y - mz.y) < absf(tgt.x - mz.x) * 0.6 + 40.0
		match state:
			0:
				_ang = move_toward(_ang, sin(_t * 0.7) * 0.1, delta)
				if in_lane and _cd <= 0.0:
					state = 1
					_st = AIM_T
					Sfx.play("s58_crank", global_position, 0.0, 0.1, 2)
			1:   # עוקב אחריך (מאחר קצת)
				_st -= delta
				if has:
					var want := atan2(tgt.y - mz.y, absf(tgt.x - mz.x))
					_ang = lerp_angle(_ang, clampf(want, -0.5, 0.7), clampf(delta * 5.0, 0.0, 1.0))
				if not in_lane and _st < AIM_T * 0.5:
					state = 0
					_cd = 0.6
				elif _st <= 0.0:
					state = 2
					_st = LOCK_T
					_lock = Vector2(face * cos(_ang), sin(_ang))
					Sfx.play("s58_click", global_position, 2.0, 0.05, 2)
			2:   # נעול: קו כוונה, עוד רגע יורה
				_st -= delta
				if _st <= 0.0:
					_fire()
			3:
				_st -= delta
				if _st <= 0.0:
					state = 0
					_cd = CD
		if Art.on_screen(self, global_position, 260.0):
			queue_redraw()

	func _fire() -> void:
		state = 3
		_st = 0.8
		shots += 1
		_recoil = 1.0
		var hp := Harpoon.new()
		hp.gun = self
		hp.vel = _lock * Harpoon.V
		get_parent().add_child(hp)
		hp.global_position = global_position + muzzle()
		Sfx.play("s58_harpoon", global_position, 4.0, 0.06, 2)
		Particles.burst(get_parent(), global_position + muzzle(), "smoke", _lock, 8)
		Particles.burst(get_parent(), global_position + muzzle(), "fire", _lock, 5)
		var cam := get_viewport().get_camera_2d()
		if cam != null and cam.has_method("shake") and Art.on_screen(self, global_position, 100.0):
			cam.shake(6.0, 0.2)

	func _draw() -> void:
		DrawBatch.begin(self)
		_draw_b()
		DrawBatch.end(self)

	func _draw_b() -> void:
		var pts := PackedVector2Array()
		var cols := PackedColorArray()
		var top := -pedestal
		if pedestal > 0.0:   # בסיס בטון סדוק
			U.quad(pts, cols, Vector2(-34, 0), Vector2(34, 0), Vector2(28, top), Vector2(-28, top), Color("6a6862"), Color("5a5852"), Color("8a8880"), Color("8a8880"))
			U.rect(pts, cols, Rect2(-30, top, 60, 4), Color("4a4842"))
		# כן מסתובב
		U.quad(pts, cols, Vector2(-14, top), Vector2(14, top), Vector2(8, top - 26), Vector2(-8, top - 26), IRON, IRON, Color("4a4644"), Color("4a4644"))
		U.oval(pts, cols, Vector2(0, top - 28), 10.0, 6.0, Color("3a3634"), 12)
		# התותחן המת: גדל לתוך התותח, חוטי פטרייה מחברים אותו לברזל
		var g := Vector2(-face * 22.0, top - 34.0)
		var dead := state == 4
		var sk := Color("8a9a8a") if _flash <= 0.0 else Color.WHITE
		var coat := Color("3a3e4a") if _flash <= 0.0 else Color.WHITE
		var slump := 10.0 if dead else 0.0
		U.quad(pts, cols, g + Vector2(-9, 18), g + Vector2(9, 18), g + Vector2(8, -8 + slump), g + Vector2(-8, -10 + slump), coat.darkened(0.2), coat.darkened(0.2), coat, coat)
		U.oval(pts, cols, g + Vector2(face * 3.0, -16.0 + slump * 1.2), 7.0, 7.5, sk, 12)
		U.oval(pts, cols, g + Vector2(face * 2.0, -21.0 + slump * 1.2), 7.5, 3.4, Color("2a2a30"), 10)   # כובע צמר
		if not dead:
			U.oval(pts, cols, g + Vector2(face * 6.0, -16.0), 1.6, 1.6, Color(1.0, 0.3, 0.2), 6)
		U.strip(pts, cols, PackedVector2Array([g + Vector2(face * 4.0, -4.0 + slump), g + Vector2(face * 14.0, 2.0), g + Vector2(face * 20.0, -6.0 + slump * 0.5)]), 4.0, 3.0, coat)   # יד על הידית
		for q in 4:   # חוטי פטרייה לברזל
			var a := g + Vector2(face * float(q) * 3.0, -6.0 + float(q) * 5.0)
			U.strip(pts, cols, PackedVector2Array([a, a + Vector2(face * 8.0, 4.0), Vector2(face * 6.0, top - 28.0 + float(q) * 2.0)]), 1.2, 0.6, Color(0.85, 0.95, 0.75, 0.6))
		U.growth(pts, cols, g + Vector2(0, 16), 0.8, 31, 0.5 + 0.5 * sin(_t * 2.0))
		# הקנה (מסתובב): מגן, קנה עבה, צלצל טעון עם ראש נפץ
		var piv := Vector2(0, top - 30.0)
		var dirv := Vector2(face * cos(_ang), sin(_ang))
		var nrm := dirv.orthogonal()
		var back := piv - dirv * (14.0 + _recoil * 6.0)
		var front := piv + dirv * (46.0 - _recoil * 6.0)
		U.quad(pts, cols, back + nrm * 6.0, front + nrm * 4.5, front - nrm * 4.5, back - nrm * 6.0, Color("3c3836"), Color("2a2624"), Color("2a2624"), Color("3c3836"))
		U.quad(pts, cols, back + nrm * 6.0, front + nrm * 4.5, front + nrm * 2.5, back + nrm * 3.0, Color("6a625c"), Color("5a524c"), Color("5a524c"), Color("6a625c"))
		U.quad(pts, cols, piv + dirv * 4.0 + nrm * 16.0, piv + dirv * 8.0 + nrm * 16.0, piv + dirv * 8.0 - nrm * 10.0, piv + dirv * 4.0 - nrm * 10.0, RUST_D, RUST_D, RUST, RUST)   # מגן
		if state != 3 and not dead:   # הצלצל הטעון
			var tip := front + dirv * 14.0
			U.strip(pts, cols, PackedVector2Array([front - dirv * 10.0, tip]), 2.4, 2.4, Color("5a5450"))
			U.tri(pts, cols, tip + nrm * 5.0, tip + dirv * 12.0, tip - nrm * 5.0, Color("8a8480"))
		U.flush(self, pts, cols)
		if state == 1 or state == 2:   # ניצוץ בעין התותחן + קו כוונה כשהוא נעול
			var k := 1.0 - _st / (AIM_T if state == 1 else LOCK_T)
			Art.glow(self, g + Vector2(face * 6.0, -16.0), 6.0 + 4.0 * k, Color(1.0, 0.3, 0.2, 0.5))
			if state == 2:
				var from := piv + _lock * 50.0
				var dash := 0.0
				while dash < 640.0:
					DrawBatch.line(self, from + _lock * dash, from + _lock * (dash + 14.0), Color(1.0, 0.3, 0.2, 0.25 + 0.4 * k), 2.0)
					dash += 26.0
				DrawBatch.string(self, ThemeDB.fallback_font, piv + Vector2(-6, -40), "!", HORIZONTAL_ALIGNMENT_LEFT, -1, 28, Color(1.0, 0.4, 0.2, 0.6 + 0.4 * sin(_t * 30.0)))


class GunnerBody extends StaticBody2D:
	var trap = null

	func take_damage(amount: int, _hit_pos: Vector2, _dir: Vector2, _explosive := false, src := {}) -> void:
		if trap != null and is_instance_valid(trap):
			var d := 12
			if src.has("fixed"):
				d = int(src.fixed)
			elif amount > 0:
				d = amount
			if src.get("god", false):
				d *= 4
			trap.hurt_gunner(d)


# הצלצל עצמו: טס ישר (זז ב-_process), משפד זומבים בדרך, פוגע בשחקן, ננעץ בקרקע / בקיר ונשאר
class Harpoon extends Node2D:
	const V := 980.0
	const LIFE := 1.6
	var gun = null
	var thrower = null              # זומבי שזרק אותו (THE BONE KING) - לא משפד את עצמו
	var pull := 0.0                 # >0 = החבל מושך אותך אל הזורק
	var dmg := -1
	var vel := Vector2.ZERO
	var _stuck := -1.0
	var _life := LIFE
	var _hit := false
	var _done := {}
	var _skewer := 0

	func _ready() -> void:
		z_index = 7

	func _process(delta: float) -> void:
		if _stuck >= 0.0:
			_stuck += delta
			if _stuck > 6.0:
				modulate.a = clampf(7.0 - _stuck, 0.0, 1.0)
				if _stuck > 7.0:
					queue_free()
			return
		_life -= delta
		var from := global_position
		var to := from + vel * delta
		# קיר / קרקע
		var q := PhysicsRayQueryParameters2D.create(from, to, 1)
		var hit := get_world_2d().direct_space_state.intersect_ray(q)
		if hit:
			to = hit.position
		var pl := get_tree().get_first_node_in_group("player") as Node2D
		if pl != null and not pl.dead and not _hit:
			var r: Rect2 = pl.body_rect().grow(4.0)
			if Geometry2D.segment_intersects_segment(from, to, r.position, r.end) != null or r.has_point(to) or Geometry2D.segment_intersects_segment(from, to, Vector2(r.position.x, r.end.y), Vector2(r.end.x, r.position.y)) != null:
				_hit = true
				if gun != null and is_instance_valid(gun) and pl._roll_t <= 0.0:
					gun.hits += 1
				var pd: int = dmg if dmg >= 0 else (gun.DMG if gun != null and is_instance_valid(gun) else 2)
				if pull > 0.0:   # צלצל עם חבל: מושך אותך אל הזורק
					if pl._roll_t <= 0.0 and thrower != null and is_instance_valid(thrower) and thrower.type_mod != null and thrower.type_mod.has_method("harpoon_hit"):
						thrower.type_mod.harpoon_hit(pl)
					pl.hurt(pd, Vector2(-signf(vel.x) * pull, -0.2))
				else:
					pl.hurt(pd, Vector2(signf(vel.x) * 1.6, -0.4))
		for z in get_tree().get_nodes_in_group("zombies"):
			if z.dead or _done.has(z) or z == thrower:
				continue
			var zr := Rect2(z.global_position + Vector2(-14.0 * z.sc, -56.0 * z.sc), Vector2(28.0 * z.sc, 56.0 * z.sc))
			if zr.has_point(to) or Geometry2D.segment_intersects_segment(from, to, zr.position, zr.end) != null:
				_done[z] = true
				_skewer += 1
				if gun != null and is_instance_valid(gun):
					gun.impaled += 1
				var zd := 110 if not z.is_boss() else 30
				z.take_damage(zd, to, vel.normalized(), false, {"source": "hazard", "fixed": zd, "harpoon": true})
				Particles.burst(get_parent(), to, "hit", vel.normalized(), 12)
				if _skewer == 1:
					z._popup("IMPALED", Color("ffb070"), 15, -90.0)
		global_position = to
		rotation = vel.angle()
		if hit or _life <= 0.0:
			_stuck = 0.0
			Sfx.play("s58_thunk", global_position, 0.0, 0.1, 3)
			if Art.on_screen(self, global_position):
				Particles.burst(get_parent(), global_position, "smoke", -vel.normalized(), 5)
		queue_redraw()

	func _draw() -> void:
		DrawBatch.begin(self)
		_draw_b()
		DrawBatch.end(self)

	func _draw_b() -> void:
		DrawBatch.line(self, Vector2(-70, 0), Vector2(0, 0), Color("4a4440"), 3.0)
		DrawBatch.line(self, Vector2(-70, -1), Vector2(0, -1), Color(0.8, 0.75, 0.7, 0.4), 1.0)
		DrawBatch.colored_polygon(self, PackedVector2Array([Vector2(0, -5), Vector2(16, 0), Vector2(0, 5)]), Color("8a847e"))
		DrawBatch.line(self, Vector2(-4, -4), Vector2(-12, -9), Color("6a6460"), 2.0)   # זרועות הצלצל
		DrawBatch.line(self, Vector2(-4, 4), Vector2(-12, 9), Color("6a6460"), 2.0)
		if _skewer > 0:
			DrawBatch.line(self, Vector2(-40, 1), Vector2(-8, 1), Color(0.5, 0.05, 0.05, 0.85), 2.4)
		if _stuck < 0.0:   # חבל שנגרר מאחור
			DrawBatch.line(self, Vector2(-70, 0), Vector2(-150, 6), Color(0.3, 0.26, 0.2, 0.6), 1.2)


# ============================================================
#  מלכודת: תנור שמן (tryworks) - שני סירי ברזל של שמן לווייתנים רותח. ירייה / פיצוץ -> נשפך ובוער
# ============================================================
class TryPot extends Node2D:
	const POT_HP := 2               # כמה פגיעות לסדוק סיר
	const SPILL_W := 250.0
	const BURN_T := 5.0
	const W := 170.0
	var spills := 0                 # לבדיקות
	var _t := 0.0
	var _pots := [[42.0, POT_HP, -1.0], [W - 42.0, POT_HP, -1.0]]   # [x, hp, זמן מאז שנשפך]
	var _bodies := []

	func _ready() -> void:
		z_index = 0
		add_to_group("blastable")
		for i in 2:
			var b := PotBody.new()
			b.trap = self
			b.idx = i
			b.collision_layer = 4
			b.collision_mask = 0
			b.add_to_group("no_outline")
			var cs := CollisionShape2D.new()
			var rs := RectangleShape2D.new()
			rs.size = Vector2(56, 34)
			cs.shape = rs
			b.add_child(cs)
			b.position = Vector2(float(_pots[i][0]), -86.0)
			add_child(b)
			_bodies.append(b)

	func blast_rect() -> Rect2:
		return Rect2(global_position + Vector2(0, -110), Vector2(W, 110))

	func hit_by_blast(c: Vector2, _r: float) -> void:
		var i := 0 if c.x < global_position.x + W * 0.5 else 1
		spill(i)

	func hit_pot(i: int) -> void:
		var p: Array = _pots[i]
		if float(p[2]) >= 0.0:
			return
		p[1] = int(p[1]) - 1
		Sfx.play("metal_ping", global_position + Vector2(float(p[0]), -86.0), -2.0, 0.15, 3)
		if int(p[1]) <= 0:
			spill(i)

	func spill(i: int) -> void:
		var p: Array = _pots[i]
		if float(p[2]) >= 0.0:
			return
		p[2] = 0.0
		spills += 1
		var b: StaticBody2D = _bodies[i]
		b.collision_layer = 0
		var side := -1.0 if i == 0 else 1.0
		var at := global_position + Vector2(float(p[0]) + side * 30.0, 0.0)
		Sfx.play("s58_hiss", at, 4.0, 0.08, 2)
		Sfx.play("metal_ping", at + Vector2(0, -80), 0.0, 0.1, 2, 0.6)
		Particles.burst(get_parent(), at + Vector2(0, -60), "mist", Vector2.UP, 14)
		Particles.burst(get_parent(), at + Vector2(0, -70), "fire", Vector2(side, -0.5), 10)
		var fz := FireZone.new()
		fz.setup(SPILL_W, BURN_T)
		get_parent().add_child(fz)
		fz.global_position = Vector2(at.x + side * SPILL_W * 0.35, global_position.y)
		var cam := get_viewport().get_camera_2d()
		if cam != null and cam.has_method("shake") and Art.on_screen(self, global_position, 60.0):
			cam.shake(5.0, 0.2)

	func _process(delta: float) -> void:
		_t += delta
		for p in _pots:
			if float(p[2]) >= 0.0:
				p[2] = float(p[2]) + delta
		if Engine.get_process_frames() % 3 == 0 and Art.on_screen(self, global_position + Vector2(W * 0.5, -60), 120.0):
			queue_redraw()

	func _draw() -> void:
		DrawBatch.begin(self)
		_draw_b()
		DrawBatch.end(self)

	func _draw_b() -> void:
		var pts := PackedVector2Array()
		var cols := PackedColorArray()
		# תנור לבנים
		U.rect(pts, cols, Rect2(0, -70, W, 70), Color("6a3a2a"))
		for row in 7:
			var off := 0.0 if row % 2 == 0 else 9.0
			var x := -off
			while x < W:
				U.rect(pts, cols, Rect2(maxf(x, 0.0) + 1.0, -70.0 + float(row) * 10.0 + 1.0, minf(17.0, W - maxf(x, 0.0) - 1.0), 8.0), Color("7a4432").lerp(Color("5a2e22"), U.h(row * 13 + int(x), 3)))
				x += 18.0
		# פתחי האש (זוהר כתום שמהבהב)
		var fl := 0.7 + 0.3 * sin(_t * 9.0) * sin(_t * 5.3)
		for i in 2:
			var fx := float(_pots[i][0])
			U.quad(pts, cols, Vector2(fx - 18, -6), Vector2(fx + 18, -6), Vector2(fx + 14, -30), Vector2(fx - 14, -30), Color("1a0c08"), Color("1a0c08"), Color("2a1008"), Color("2a1008"))
			U.oval(pts, cols, Vector2(fx, -12), 12.0, 6.0 * fl, Color(1.0, 0.5, 0.15, 0.85), 10)
			U.oval(pts, cols, Vector2(fx, -12), 6.0, 3.0 * fl, Color(1.0, 0.85, 0.4), 8)
		# ארובה
		U.rect(pts, cols, Rect2(W * 0.5 - 9.0, -150, 18, 80), Color("5a2e22"))
		U.rect(pts, cols, Rect2(W * 0.5 - 11.0, -154, 22, 6), Color("3a1e16"))
		# הסירים
		for i in 2:
			var p: Array = _pots[i]
			var px: float = p[0]
			var spilled: float = p[2]
			var tilt := 0.0 if spilled < 0.0 else clampf(spilled / 0.3, 0.0, 1.0) * (-0.5 if i == 0 else 0.5)
			var c := Vector2(px, -84.0)
			var sx := cos(tilt)
			var sy := sin(tilt)
			var rot := func(v: Vector2) -> Vector2: return c + Vector2(v.x * sx - v.y * sy, v.x * sy + v.y * sx)
			var body := [Vector2(-30, -10), Vector2(30, -10), Vector2(24, 12), Vector2(0, 18), Vector2(-24, 12)]
			var poly := PackedVector2Array()
			for v in body:
				poly.append(rot.call(v))
			DrawBatch.colored_polygon(self, poly, Color("1e1c1c") if spilled < 0.0 else Color("2a2422"))
			U.quad(pts, cols, rot.call(Vector2(-31, -12)), rot.call(Vector2(31, -12)), rot.call(Vector2(31, -8)), rot.call(Vector2(-31, -8)), Color("4a4644"), Color("4a4644"), Color("2a2828"), Color("2a2828"))
			if spilled < 0.0:   # שמן רותח: בועות ואדים
				U.oval(pts, cols, c + Vector2(0, -11), 27.0, 3.6, Color("6a4a1a"), 12)
				for q in 4:
					var bph := fmod(_t * 2.2 + float(q) * 0.37 + float(i), 1.0)
					U.oval(pts, cols, c + Vector2(-18.0 + float(q) * 12.0, -12.0), 2.5 * bph + 0.5, 1.6 * bph + 0.4, Color(0.95, 0.8, 0.45, 0.8 * (1.0 - bph)), 6)
				var crack := POT_HP - int(p[1])
				if crack > 0:
					U.strip(pts, cols, PackedVector2Array([c + Vector2(-6, -6), c + Vector2(0, 4), c + Vector2(-4, 12)]), 1.4, 0.8, Color(1.0, 0.6, 0.2, 0.9))
			elif spilled < 1.2:   # שמן נשפך מהשפה
				var lip: Vector2 = rot.call(Vector2(-30.0 if i == 0 else 30.0, -10.0))
				var k := spilled / 1.2
				U.strip(pts, cols, PackedVector2Array([lip, lip + Vector2((-1.0 if i == 0 else 1.0) * 14.0, 30.0), Vector2(lip.x + (-1.0 if i == 0 else 1.0) * 30.0, 0.0)]), 8.0 * (1.0 - k), 4.0 * (1.0 - k), Color(0.9, 0.55, 0.15, 0.9))
		U.flush(self, pts, cols)
		for i in 2:   # אדים מהסירים
			if float(_pots[i][2]) < 0.0:
				Kit.soft_glow(self, Vector2(float(_pots[i][0]), -110.0 - 6.0 * sin(_t * 1.5 + float(i))), 30.0, Color(0.9, 0.9, 0.88, 0.16), 0.7)
		Kit.soft_glow(self, Vector2(W * 0.5, -14.0), 70.0, Color(1.0, 0.5, 0.15, 0.18 * fl), 0.4)


class PotBody extends StaticBody2D:
	var trap = null
	var idx := 0

	func take_damage(_amount: int, hit_pos: Vector2, dir: Vector2, _explosive := false, _src := {}) -> void:
		if trap != null and is_instance_valid(trap):
			Particles.burst(trap.get_parent(), hit_pos, "spark", -dir, 4)
			trap.hit_pot(idx)


# ============================================================
#  מכשולים (מוצקים + מחסה)
# ============================================================
class Obstacle extends Node2D:
	var kind := "casks"
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
		var r := RandomNumberGenerator.new()
		r.seed = seed_v
		var pts := PackedVector2Array()
		var cols := PackedColorArray()
		match kind:
			"casks":   # חביות עץ של שמן: 2 עומדות + אחת שוכבת למעלה
				for q in 2:
					var dx := float(q) * w * 0.5
					var c := WOOD.lerp(WOOD_D, 0.25 * float(q))
					U.quad(pts, cols, Vector2(dx + 3.0, 0), Vector2(dx + w * 0.5 - 3.0, 0), Vector2(dx + w * 0.5 - 1.0, -h * 0.62), Vector2(dx + 1.0, -h * 0.62), c.darkened(0.2), c.darkened(0.3), c, c.lightened(0.05))
					for b in 3:
						U.rect(pts, cols, Rect2(dx + 1.0, -h * (0.08 + 0.24 * float(b)) - 2.0, w * 0.5 - 2.0, 3.0), IRON)
					for s in 3:
						U.rect(pts, cols, Rect2(dx + 6.0 + float(s) * (w * 0.5 - 12.0) / 2.0, -h * 0.62, 1.0, h * 0.62), Color(0, 0, 0, 0.25))
				U.oval(pts, cols, Vector2(w * 0.5, -h * 0.81), w * 0.32, h * 0.19, WOOD.darkened(0.1), 14)
				U.oval(pts, cols, Vector2(w * 0.82, -h * 0.81), h * 0.09, h * 0.18, WOOD_L, 10)
				U.oval(pts, cols, Vector2(w * 0.82, -h * 0.81), h * 0.05, h * 0.1, WOOD_D, 8)
				U.rect(pts, cols, Rect2(w * 0.3, -h * 0.95, 3.0, h * 0.28), IRON)
				U.rect(pts, cols, Rect2(w * 0.62, -h * 0.95, 3.0, h * 0.28), IRON)
				U.oval(pts, cols, Vector2(w * 0.3, 0), w * 0.35, 2.4, Color(0.08, 0.06, 0.04, 0.6), 10)
			"boiler":   # דוד קיטור חלוד שוכב על הצד
				U.quad(pts, cols, Vector2(0, -h * 0.1), Vector2(w, -h * 0.1), Vector2(w, -h * 0.9), Vector2(0, -h * 0.9), RUST_D, RUST_D, RUST, RUST)
				U.quad(pts, cols, Vector2(0, -h * 0.9), Vector2(w, -h * 0.9), Vector2(w - 4.0, -h), Vector2(4.0, -h), RUST_L.darkened(0.2), RUST_L.darkened(0.2), RUST, RUST)
				U.oval(pts, cols, Vector2(w - 2.0, -h * 0.5), h * 0.14, h * 0.45, RUST_D.darkened(0.2), 14)
				U.oval(pts, cols, Vector2(w - 2.0, -h * 0.5), h * 0.08, h * 0.3, IRON, 12)
				for q in int(w / 16.0):
					U.oval(pts, cols, Vector2(8.0 + float(q) * 16.0, -h * 0.82), 1.4, 1.4, RUST_L, 4)
					U.oval(pts, cols, Vector2(8.0 + float(q) * 16.0, -h * 0.2), 1.4, 1.4, RUST_L, 4)
				U.rect(pts, cols, Rect2(6.0, -h * 0.1, 10.0, h * 0.1), IRON)
				U.rect(pts, cols, Rect2(w - 20.0, -h * 0.1, 10.0, h * 0.1), IRON)
			"bones":   # ערימת חוליות + גולגולת קטנה
				for q in 3:
					U.vertebra(pts, cols, Vector2(w * (0.2 + 0.3 * float(q)), -h * 0.32), minf(w * 0.12, h * 0.28), BONE.darkened(0.05 * float(q)), BONE_D)
				U.quad(pts, cols, Vector2(w * 0.15, -h * 0.55), Vector2(w * 0.7, -h * 0.75), Vector2(w * 0.9, -h * 0.6), Vector2(w * 0.3, -h * 0.45), BONE_D, BONE, BONE, BONE_D)
				U.oval(pts, cols, Vector2(w * 0.62, -h * 0.65), 4.0, 3.0, Color("2a2622"), 8)
				U.growth(pts, cols, Vector2(w * 0.4, -h * 0.5), 0.6, seed_v % 97, 0.5)
			_:   # כננת קיטור: מסגרת ברזל, תוף עם כבל, גלגל שיניים
				U.rect(pts, cols, Rect2(0, -h * 0.25, w, h * 0.25), IRON)
				U.quad(pts, cols, Vector2(6, -h * 0.25), Vector2(18, -h * 0.25), Vector2(16, -h), Vector2(10, -h), Color("3a3634"), Color("3a3634"), Color("4a4644"), Color("4a4644"))
				U.quad(pts, cols, Vector2(w - 18, -h * 0.25), Vector2(w - 6, -h * 0.25), Vector2(w - 10, -h), Vector2(w - 16, -h), Color("3a3634"), Color("3a3634"), Color("4a4644"), Color("4a4644"))
				U.rect(pts, cols, Rect2(16, -h * 0.82, w - 32, h * 0.44), Color("3a2a20"))
				for q in 6:
					U.rect(pts, cols, Rect2(18.0, -h * 0.8 + float(q) * h * 0.07, w - 36.0, 2.0), Color("6a625a"))
				U.oval(pts, cols, Vector2(w - 12.0, -h * 0.6), h * 0.3, h * 0.3, Color("4a4440"), 14)
				U.oval(pts, cols, Vector2(w - 12.0, -h * 0.6), h * 0.1, h * 0.1, Color("1e1c1a"), 8)
		U.flush(self, pts, cols)


# ============================================================
#  זירת הבוס: גולגולת לווייתן ענקית ככס, גדר לסתות, קן ECHO זוהר, שרשראות, שלט
# ============================================================
class BoneThrone extends Node2D:
	var w := 1000.0
	var _t := 0.0

	func _ready() -> void:
		z_index = -3

	func _process(delta: float) -> void:
		_t += delta
		if Engine.get_process_frames() % 4 == 0 and Art.on_screen(self, global_position + Vector2(w * 0.5, -100), w * 0.6):
			queue_redraw()

	func _draw() -> void:
		DrawBatch.begin(self)
		_draw_b()
		DrawBatch.end(self)

	func _draw_b() -> void:
		var pts := PackedVector2Array()
		var cols := PackedColorArray()
		# גדר של לסתות ענקיות נעוצות בחול (פליסדה)
		for q in 12:
			var x := 30.0 + float(q) * 82.0
			if x > 360.0 and x < 640.0:
				continue
			var hh := 150.0 + U.h(q, 1) * 70.0
			var lean := (U.h(q, 2) - 0.5) * 0.25
			var ln := U.rib_line(Vector2(x, 0), Vector2(x + sin(lean) * hh, -hh), 18.0 * (1.0 if q % 2 == 0 else -1.0), 8)
			U.strip(pts, cols, ln, 16.0, 5.0, BONE_D.darkened(0.25), BONE_S.darkened(0.2))
			U.strip(pts, cols, ln, 10.0, 3.0, BONE.darkened(0.1), BONE_D)
		# הכס: גולגולת לווייתן ענקית (מבט מהצד, החרטום שמאלה), עם ערימת חוליות מתחת
		var c := Vector2(500.0, -110.0)
		for q in 5:
			U.vertebra(pts, cols, Vector2(410.0 + float(q) * 46.0, -16.0), 18.0, BONE.darkened(0.08), BONE_D)
		U.quad(pts, cols, c + Vector2(-180, 40), c + Vector2(-20, -40), c + Vector2(110, -50), c + Vector2(150, 50), BONE_D, BONE, BONE, BONE_D)
		U.quad(pts, cols, c + Vector2(-180, 40), c + Vector2(-260, 70), c + Vector2(-300, 88), c + Vector2(-200, 70), BONE_D, BONE, BONE_D, BONE_S)
		U.oval(pts, cols, c + Vector2(80, -10), 20.0, 16.0, Color("1a1612"), 12)
		U.oval(pts, cols, c + Vector2(-60, 20), 30.0, 10.0, Color("2a2420"), 12)
		# הלסת התחתונה הענקית נשענת כמשענת
		U.strip(pts, cols, PackedVector2Array([c + Vector2(140, 60), c + Vector2(170, -40), c + Vector2(150, -150), c + Vector2(100, -230)]), 26.0, 10.0, BONE_D, BONE_S)
		U.strip(pts, cols, PackedVector2Array([c + Vector2(140, 60), c + Vector2(170, -40), c + Vector2(150, -150), c + Vector2(100, -230)]), 16.0, 6.0, BONE, BONE_D)
		# קן ECHO: גידולים זוהרים על הגולגולת
		var pulse := 0.5 + 0.5 * sin(_t * 1.4)
		for q in 7:
			U.growth(pts, cols, c + Vector2(-120.0 + float(q) * 40.0, -30.0 - float(q % 3) * 12.0), 1.2 + 0.2 * float(q % 2), q * 17 + 5, pulse)
		for q in 8:   # חוטים לבנים שנמתחים בין העצמות
			var a := c + Vector2(-150.0 + float(q) * 40.0, -20.0)
			U.strip(pts, cols, PackedVector2Array([a, a + Vector2(20, -40 - float(q % 3) * 20.0), a + Vector2(46, -10)]), 1.4, 0.6, Color(0.9, 0.95, 0.8, 0.5))
		U.flush(self, pts, cols)
		Kit.soft_glow(self, c + Vector2(-20, -40), 160.0, Color(0.55, 1.0, 0.45, 0.12 + 0.08 * pulse), 0.5)
		# שרשראות + ווי הפשטה תלויים מהלסתות
		for q in 3:
			var top := Vector2(150.0 + float(q) * 330.0, -200.0)
			var sw := sin(_t * 0.9 + float(q)) * 3.0
			DrawBatch.line(self, top, top + Vector2(sw, 90), Color("3a2a22"), 2.4)
			DrawBatch.arc(self, top + Vector2(sw, 100), 9.0, -0.2, PI * 1.2, 10, RUST, 3.0)
		# השלט
		DrawBatch.line(self, Vector2(820, 0), Vector2(820, -130), WOOD_D, 5.0)
		DrawBatch.rect(self, Rect2(770, -150, 110, 34), Color("d8ccb0"))
		DrawBatch.rect(self, Rect2(770, -150, 110, 34), OLD_BLOOD, false, 2.0)
		DrawBatch.string(self, ThemeDB.fallback_font, Vector2(782, -128), "PLAN No 2", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("3a2a22"))
		DrawBatch.string(self, ThemeDB.fallback_font, Vector2(780, -96), "HE WEARS THEM ALL", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.7, 1.0, 0.55, 0.7 + 0.25 * pulse))


# ============================================================
#  מסך: טפטוף דק באלכסון, ערפל שנסחף, משב
# ============================================================
class GreyFX extends Node2D:
	const GUST_EVERY := Vector2(13.0, 20.0)
	var vp := Vector2(1280, 720)
	var gusts := 0                  # לבדיקות
	var _t := 0.0
	var _next := 8.0
	var _gust := -1.0

	func gust() -> void:
		_gust = 0.0
		gusts += 1
		Sfx.play("s58_wind", null, -2.0)

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
		var slant := Vector2(-0.28 - 0.25 * g, 1.0).normalized()
		for i in int((70.0 + 30.0 * g) * q):   # טפטוף: קווים דקים ושקופים באלכסון
			var sp := 520.0 + U.h(i, 1) * 260.0
			var ln := 10.0 + U.h(i, 2) * 14.0
			var y := fposmod(U.h(i, 3) * vp.y + _t * sp, vp.y + 40.0) - 20.0
			var x := fposmod(U.h(i, 4) * vp.x * 1.3 + _t * sp * slant.x / slant.y - 0.0, vp.x + 80.0) - 40.0
			var a := 0.1 + 0.1 * U.h(i, 5)
			var p := Vector2(x, y)
			var d := slant * ln
			var n := Vector2(0.6, 0.0)
			U.quad(pts, cols, p - n, p + n, p + d + n, p + d - n, Color(0.85, 0.88, 0.92, 0.0), Color(0.85, 0.88, 0.92, 0.0), Color(0.85, 0.88, 0.92, a), Color(0.85, 0.88, 0.92, a))
		for i in int(14.0 * q):   # רסס / טיפות גדולות שנישאות ברוח במשב
			if g <= 0.05:
				break
			var x := fposmod(U.h(i, 6) * vp.x * 2.0 - _t * (500.0 + 300.0 * g), vp.x + 40.0) - 20.0
			var y := fposmod(U.h(i, 7) * vp.y + _t * 60.0, vp.y)
			U.dia(pts, cols, Vector2(x, y), 1.3, Color(1, 1, 1, 0.35 * g))
		U.flush(self, pts, cols)
		# גוון קר עדין בקצוות (וינייט אפור)
		Kit.soft_glow(self, Vector2(vp.x * 0.5, vp.y * 0.08), vp.x * 0.7, Color(0.5, 0.55, 0.62, 0.05 + 0.04 * g), 0.18)
