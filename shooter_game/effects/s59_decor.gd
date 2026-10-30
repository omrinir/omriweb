extends RefCounted
const DrawBatch := preload("res://effects/draw_batch.gd")   # כל הציור של זומבי ב-draw call אחד
# ============================================================
#  קישוטים לשלב 59 ("BLACK FOREST") - אזור שביעי (פטגוניה), שלב 5. "THEY LEARNED TO BURN".
#  יער לנגה (אשור דרומי) שרוף בטיירה דל פואגו אחרי שריפה: גזעים שחורים, אפר אפור, גדמים מעלים עשן, קווי אש חיים,
#  עשן, סכרי בונים ועצים מתים טבועים בקרחות מוצפות, בקתת שומרי הפארק, ניצוצות עולים, אור כתום עמום דרך העשן.
#    forest_sky    - (רקע) שמיים של שריפה: חום-אפור למעלה, ענבר ליד האופק, שמש אדומה כמו מטבע דרך העשן, פסי עשן שזזים,
#                    גצים שעולים גבוה, קונדור
#    far_range     - (רקע, 0.06) הרי מרסיאל המושלגים (שלג בגוון כתום), תעלת ביגל, שריפות רחוקות על המדרונות + עמודי עשן
#    mid_burn      - (רקע, 0.28) גבעות של גזעי לנגה שרופים, איים של יער חי שלא נשרף, חזיתות אש על המדרון, עשן
#    near_forest   - (רקע, 0.6) גזעים שחורים עבים עם פחם "עור תנין" וסדקים לוחשים, גדמים מחודדים של בונים, גדמים מעלים עשן,
#                    גזעים שנפלו, ערימות אפר
#    forest_overlay- אובך חם מאחורי הדמויות + פסי עשן נמוכים (חזק יותר כשהעשן סמיך - U.smoke)
#    AshGround     - (עולם) אפר אפור על אדמה שרופה, פחמים, גחלים קטנות
#    ParkSign      - (עולם) שלט הכניסה לפארק (חרוך) + שעון "PELIGRO DE INCENDIO" על EXTREMO
#    RangerHut     - (עולם) בקתת שומרי הפארק ("GUARDAPARQUES") חצי שרופה - גג המרפסת = קומה
#    LookoutTower  - (עולם) מגדל תצפית אש מעץ - הבמה = קומה
#    BeaverPond    - (עולם, קבוצה "s59_ponds") קרחה מוצפת מאחורי סכר בונים: מים כהים עם אפר, עצים מתים טבועים, מאורת בונים.
#                    במים: הליכה איטית (player.in_water), אש נכבית. הסכר (צד ימין) = קומה נמוכה מעל המים.
#    FireLine      - (עולם, מלכודת, hazard, קבוצה "s59_fires") פס אש זוחל על הקרקע: LOW (גחלים, אפשר לעבור) ->
#                    WARN (פצפוץ, ניצוצות, WARN_T) -> FLARE (להבות גבוהות, FLARE_T: פוגע בך, מצית זומבים - CHARRED נהנה מזה).
#                    ASHMOTH נמשך לפס שבוער כשאין לו הבזק לרדוף אחריו.
#    Snag          - (עולם, מלכודת) עץ שרוף שעומד ליפול ("widow-maker"): אתה מתקרב -> חריקה, ניצוצות בבסיס וצל על הדרך
#                    (WARN_T) -> נופל לרוחב הדרך: DMG לך, DMG_Z לזומבים. ירייה בבסיס הלוחש (SnagBody) = נופל עכשיו.
#                    משאיר FallenLog: גזע שוכב שמעלה עשן (מחסה נמוך, אפשר לקפוץ).
#    Stump         - (עולם) גדם מעלה עשן עם גחלים
#    Obstacle      - (מוצק + מחסה) "logs" ערימת בולי עץ שרופים / "stump" גדם ענק / "boulder" סלע נודד עם אפר / "rootball" שורשים הפוכים
#    BurntTruck    - (עולם) הטנדר השרוף של שומרי הפארק - הארגז = קומה נמוכה
#    Sawmill       - (עולם) זירת הבוס: המנסרה הבוערת "ASERRADERO LAPATAIA", ערימות בולים, במת בולים (קומה)
#    SmokeVeil     - (עולם) ענן עשן סמיך שמתגלגל על נקודה (סצנת הסיפור: ה-STRANGER נעלם בעשן)
#    SmokeFX       - (מסך) גצים עולים, פסי עשן (סמיכות לפי U.smoke), הבזק הירייה מאיר את העשן, משב ניצוצות (sparks())
#  לשנות: FireLine.LOW_T / WARN_T / FLARE_T / DMG, Snag.TRIG_R / WARN_T / FALL_T / DMG / DMG_Z, BeaverPond (רוחב/סכר),
#         SmokeFX (כמויות לפי Quality.ambient()).
# ============================================================

const Art := preload("res://art.gd")
const Sfx := preload("res://sfx.gd")
const Kit := preload("res://effects/backdrop_kit.gd")
const Particles := preload("res://particles.gd")
const Hazard := preload("res://environment/hazard.gd")
const DebrisScript := preload("res://debris.gd")

const ASH := Color("8a8580")
const ASH_L := Color("b2aca4")
const ASH_D := Color("4e4a46")
const SOIL := Color("231c1a")
const CHAR := Color("1a1817")
const CHAR_L := Color("3a3532")
const EMBER := Color("ff6a1a")
const EMBER_L := Color("ffb848")
const EMBER_D := Color("a0300a")
const SMOKE := Color("6e655e")
const WATER := Color("2a2e30")
const LENGA := Color("4a5a2e")
const WOOD := Color("6a4a30")
const WOOD_D := Color("3e2a1c")
const WOOD_L := Color("94704a")
const RANGER := Color("3e5a3a")
const SIGN_Y := Color("d8b030")


# מצב משותף (השלב מעדכן) + עזרים - מחלקה פנימית לא רואה פונקציות סטטיות של הקובץ
class U:
	static var smoke := 0.0          # 0..1 - כמה העשן סמיך עכשיו (stage_59 -> _smoke_tick)
	static var flash := 0.0          # 0..1 - הבזק הירייה (מאיר את העשן)
	static var flash_pos := Vector2.ZERO   # איפה (במסך)
	static var sparks_ms := -1       # משב ניצוצות (סצנה / משב)
	static var pocket := Vector2.ZERO  # השחקן במסך (הכיס הנקי בתוך העשן)

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

	# כתם רך: מניפה שהמרכז שלה בצבע והשוליים שקופים (עשן / הילה בלי טקסטורה - נשאר באותו draw call)
	static func blob(pts: PackedVector2Array, cols: PackedColorArray, c: Vector2, rx: float, ry: float, col: Color, n := 10) -> void:
		var edge := Color(col, 0.0)
		var prev := c + Vector2(rx, 0)
		for q in n:
			var a1 := float(q + 1) / float(n) * TAU
			var p := c + Vector2(cos(a1) * rx, sin(a1) * ry)
			pts.append_array([c, prev, p])
			cols.append_array([col, edge, edge])
			prev = p

	# לשון אש (משולשים, באותו draw call): 3 שכבות - אדום כהה, כתום, צהוב
	static func flame(pts: PackedVector2Array, cols: PackedColorArray, base: Vector2, w: float, hh: float, sway: float, a := 1.0) -> void:
		if hh < 2.0:
			return
		var cs := [Color(0.7, 0.12, 0.02, 0.85 * a), Color(1.0, 0.42, 0.06, 0.9 * a), Color(1.0, 0.8, 0.32, 0.9 * a)]
		for L in 3:
			var k: float = [1.0, 0.7, 0.42][L]
			var lw := w * k
			var lh := hh * k
			var tip := base + Vector2(sway * k, -lh)
			var mid_l := base + Vector2(-lw * 0.9 + sway * 0.25, -lh * 0.35)
			var mid_r := base + Vector2(lw * 0.9 + sway * 0.25, -lh * 0.35)
			var c: Color = cs[L]
			pts.append_array([base + Vector2(-lw * 0.6, 0), mid_l, mid_r, base + Vector2(-lw * 0.6, 0), mid_r, base + Vector2(lw * 0.6, 0), mid_l, tip, mid_r])
			cols.append_array([c, c, c, c, c, c, c, Color(c, 0.0), c])

	# גזע שרוף (קו עבה עם כהה/בהיר + ענפים שבורים), מלמטה למעלה
	static func trunk(pts: PackedVector2Array, cols: PackedColorArray, base: Vector2, hh: float, w: float, lean: float, col: Color, seed_i: int) -> void:
		var top := base + Vector2(lean * hh, -hh)
		var lt := Color(col.lightened(0.12), col.a)
		quad(pts, cols, base + Vector2(-w, 0), top + Vector2(-w * 0.45, 0), top + Vector2(w * 0.45, 0), base + Vector2(w, 0), col, col, lt, lt)
		# קצה שבור משונן
		tri(pts, cols, top + Vector2(-w * 0.45, 0), top + Vector2(-w * 0.1, -w * (1.5 + h(seed_i, 3) * 2.0)), top + Vector2(w * 0.45, 0), col)
		var nb := 2 + int(h(seed_i, 1) * 3.0)
		for q in nb:   # ענפים קצרים ושבורים
			var k := 0.35 + 0.55 * h(seed_i * 3 + q, 2)
			var p := base.lerp(top, k)
			var s := -1.0 if q % 2 == 0 else 1.0
			var ln := hh * (0.08 + 0.1 * h(seed_i + q, 4))
			var e := p + Vector2(s * ln, -ln * (0.5 + h(seed_i, q) * 0.6))
			quad(pts, cols, p + Vector2(0, -w * 0.3), e, e + Vector2(0, 1.0), p + Vector2(0, w * 0.3), col, col, col, col)


static func _h(i: int, s: int) -> float:
	return U.h(i, s)


# ============================================================
#  רקע
# ============================================================

# ---- שמיים של שריפה: חום-אפור, שמש אדומה דרך העשן, פסי עשן, גצים ----
static func forest_sky(ci: CanvasItem, v: Vector2, t: float) -> void:
	Kit.gradient_sky(ci, v, [Color("2a2224"), Color("3e302c"), Color("6a4c3a"), Color("9a6a46"), Color("c08a56"), Color("d6a46a")], 0.84)
	# השמש: מטבע אדום-כתום דרך העשן (כמו בשריפות אמיתיות)
	var sp := Vector2(v.x * 0.64, v.y * 0.3)
	Kit.soft_glow(ci, sp, 300.0, Color(1.0, 0.55, 0.22, 0.22), 0.7)
	Kit.soft_glow(ci, sp, 90.0, Color(1.0, 0.62, 0.3, 0.45))
	var pts := PackedVector2Array()
	var cols := PackedColorArray()
	U.oval(pts, cols, sp, 30.0, 30.0, Color(1.0, 0.5, 0.24, 0.92), 24)
	U.oval(pts, cols, sp + Vector2(-6, -7), 18.0, 16.0, Color(1.0, 0.68, 0.4, 0.5), 16)
	# פסי עשן חוצים את השמש ואת השמיים (רכים, באותו draw call)
	for i in 12:
		var spd := 6.0 + float(i) * 2.2
		var x := fposmod(_h(i, 8) * v.x * 1.7 - t * spd, v.x + 900.0) - 450.0
		var y := v.y * (0.08 + _h(i, 9) * 0.5)
		var rx := 240.0 + _h(i, 10) * 200.0
		var ry := 20.0 + _h(i, 11) * 34.0
		var c := Color(0.22, 0.17, 0.15, 0.28 + 0.2 * _h(i, 12))
		U.blob(pts, cols, Vector2(x, y), rx, ry, c, 14)
		U.blob(pts, cols, Vector2(x + rx * 0.35, y - ry * 0.4), rx * 0.6, ry * 0.6, Color(0.55, 0.38, 0.26, 0.14), 12)
	# גצים שעולים גבוה
	for i in 34:
		var k := fmod(t * (0.03 + 0.02 * _h(i, 13)) + _h(i, 14), 1.0)
		var x := fposmod(_h(i, 15) * v.x + sin(t * 0.7 + float(i)) * 30.0 - t * 8.0, v.x)
		var y := v.y * (0.85 - k * 0.8)
		var a := sin(k * PI) * (0.5 + 0.5 * sin(t * 6.0 + float(i) * 2.0))
		U.dia(pts, cols, Vector2(x, y), 1.4, Color(1.0, 0.62, 0.24, 0.75 * a))
	# קונדור דואה בעשן
	var ck := fmod(t / 70.0, 1.0)
	var cp := Vector2(lerpf(-120.0, v.x + 120.0, ck), v.y * 0.2 + sin(t * 0.3) * 30.0)
	var fl := sin(t * 0.8) * 3.0
	U.tri(pts, cols, cp + Vector2(-34, -fl), cp + Vector2(0, -2), cp + Vector2(-4, 3), Color(0.08, 0.06, 0.06, 0.8))
	U.tri(pts, cols, cp + Vector2(34, -fl), cp + Vector2(0, -2), cp + Vector2(4, 3), Color(0.08, 0.06, 0.06, 0.8))
	U.oval(pts, cols, cp, 6.0, 2.4, Color(0.08, 0.06, 0.06, 0.8), 6)
	# עשן סמיך: השמיים מחשיכים
	if U.smoke > 0.02:
		U.rect(pts, cols, Rect2(0, 0, v.x, v.y), Color(0.2, 0.15, 0.13, 0.32 * U.smoke))
	U.flush(ci, pts, cols)


# ---- הרי מרסיאל, תעלת ביגל, שריפות רחוקות ----
static func far_range(ci: CanvasItem, sc: float, v: Vector2, y: float, t: float) -> void:
	var base := y - 56.0
	var period := 2200.0
	var start := int(floor(sc / period)) - 1
	var pts := PackedVector2Array()
	var cols := PackedColorArray()
	for k in range(start, start + int(ceil(v.x / period)) + 2):
		var bx := float(k) * period - sc
		var ridge := PackedVector2Array([Vector2(bx, base)])
		var peaks := []
		for q in 23:
			var px := bx + float(q) * 100.0
			var hh := 26.0
			if q > 0 and q < 22:
				hh = (90.0 + _h(k * 29 + q, 1) * 130.0) if q % 2 == 1 else (40.0 + _h(k * 29 + q, 2) * 50.0)
				if q == 11:
					hh = 240.0   # קרן חדה (כמו הר אוליביה)
			ridge.append(Vector2(px, base - hh))
			if q % 2 == 1:
				peaks.append(Vector2(px, base - hh))
		ridge.append(Vector2(bx + period, base))
		DrawBatch.colored_polygon(ci, ridge, Color("6a5e64"))
		for pk: Vector2 in peaks:
			U.tri(pts, cols, pk, pk + Vector2(34, 32), pk + Vector2(-30, 30), Color("d8c0b0"))
			U.tri(pts, cols, pk, pk + Vector2(34, 32), pk + Vector2(10, 24), Color("b8988a"))
		# שריפה רחוקה על המדרון: קו כתום מהבהב + עשן
		var fx := bx + 500.0 + _h(k, 5) * 900.0
		var fy := base - 30.0 - _h(k, 6) * 20.0
		for q in 9:
			var px := fx + float(q) * 14.0
			var fl := 3.0 + 5.0 * (0.5 + 0.5 * sin(t * 5.0 + float(q) * 1.7 + float(k)))
			U.tri(pts, cols, Vector2(px - 6, fy + float(q % 3)), Vector2(px + 6, fy + float(q % 3)), Vector2(px, fy - fl), Color(1.0, 0.5, 0.15, 0.8))
		U.blob(pts, cols, Vector2(fx + 60.0, fy - 4.0), 90.0, 16.0, Color(1.0, 0.45, 0.15, 0.25), 12)
		for q in 6:   # עמוד עשן שנוטה
			var kk := fmod(float(q) / 6.0 + t * 0.03, 1.0)
			U.blob(pts, cols, Vector2(fx + 60.0 + kk * 140.0, fy - 10.0 - kk * 200.0), 30.0 + kk * 70.0, 18.0 + kk * 40.0, Color(0.3, 0.24, 0.22, 0.3 * (1.0 - kk)), 10)
	U.flush(ci, pts, cols)
	# תעלת ביגל: פס מים עמום עם ברק כתום
	DrawBatch.rect(ci, Rect2(0, base, v.x, v.y - base), Color("5a5250"))
	pts = PackedVector2Array()
	cols = PackedColorArray()
	U.rect(pts, cols, Rect2(0, base, v.x, 26.0), Color("4a4a50"))
	for i in 30:
		var gx := fposmod(_h(i, 5) * 3000.0 - sc - t * 5.0, v.x + 100.0) - 50.0
		var gy := base + 3.0 + _h(i, 7) * 20.0
		var a := 0.12 + 0.2 * (0.5 + 0.5 * sin(t * 2.0 + float(i) * 2.3))
		U.quad(pts, cols, Vector2(gx, gy), Vector2(gx + 14.0, gy), Vector2(gx + 14.0, gy + 1.0), Vector2(gx, gy + 1.0), Color(1, 0.7, 0.4, 0.0), Color(1, 0.7, 0.4, a), Color(1, 0.7, 0.4, a), Color(1, 0.7, 0.4, 0.0))
	U.flush(ci, pts, cols)


# ---- גבעות של יער שרוף, איים של יער חי, חזיתות אש, עשן ----
static func mid_burn(ci: CanvasItem, sc: float, v: Vector2, y: float, t: float) -> void:
	var top := y - 150.0
	var period := 1400.0
	var start := int(floor(sc / period)) - 1
	var pts := PackedVector2Array()
	var cols := PackedColorArray()
	for k in range(start, start + int(ceil(v.x / period)) + 2):
		var bx := float(k) * period - sc
		# גבעה
		var hill := PackedVector2Array([Vector2(bx - 20.0, y + 40.0)])
		for q in 15:
			var u := float(q) / 14.0
			hill.append(Vector2(bx + u * period, top + 30.0 - sin(u * PI) * (40.0 + _h(k, 1) * 50.0) + _h(k * 15 + q, 2) * 14.0))
		hill.append(Vector2(bx + period + 20.0, y + 40.0))
		DrawBatch.colored_polygon(ci, hill, Color("4a3e3a"))
		# אי של יער חי שלא נשרף (ירוק-אפור, מעונן)
		if posmod(k, 3) == 1:
			var gx := bx + 300.0 + _h(k, 3) * 500.0
			for q in 16:
				var px := gx + float(q) * 13.0 + (_h(k * 16 + q, 8) - 0.5) * 10.0
				var u := (px - bx) / period
				var gy := top + 34.0 - sin(u * PI) * (40.0 + _h(k, 1) * 50.0) + 12.0 + _h(k * 16 + q, 9) * 6.0
				var ph := (18.0 + _h(k * 12 + q, 4) * 22.0) * (1.0 - absf(float(q) - 7.5) / 12.0)
				var gc := Color(0.27, 0.32, 0.22, 0.8).lerp(Color(0.36, 0.38, 0.28, 0.8), _h(q, k + 4))
				U.tri(pts, cols, Vector2(px - 9, gy), Vector2(px + 9, gy), Vector2(px, gy - ph), gc)
				U.tri(pts, cols, Vector2(px - 7, gy - ph * 0.35), Vector2(px + 7, gy - ph * 0.35), Vector2(px + 1.0, gy - ph * 1.15), gc.lightened(0.06))
		# גזעים שרופים: עשרות קווים דקים
		for q in 70:
			var px := bx + _h(k * 70 + q, 5) * period
			var u := px - bx
			var gy := top + 34.0 - sin(u / period * PI) * (40.0 + _h(k, 1) * 50.0) + 10.0
			var th := 40.0 + _h(k * 70 + q, 6) * 60.0
			var c := Color(0.13, 0.11, 0.1, 0.9).lerp(Color(0.26, 0.22, 0.2, 0.9), _h(q, k + 9))
			U.trunk(pts, cols, Vector2(px, gy + 30.0), th, 1.4 + _h(q, k) * 1.2, (_h(q, k + 3) - 0.5) * 0.12, c, k * 70 + q)
		# חזית אש על המדרון
		if posmod(k, 2) == 0:
			var fx := bx + 200.0 + _h(k, 7) * 700.0
			var fy := top + 48.0
			U.blob(pts, cols, Vector2(fx + 90.0, fy), 150.0, 30.0, Color(1.0, 0.42, 0.12, 0.28 + 0.06 * sin(t * 3.0)), 14)
			for q in 14:
				var px := fx + float(q) * 13.0
				var fl := 6.0 + 10.0 * (0.5 + 0.5 * sin(t * 6.0 + float(q) * 1.9 + float(k)))
				U.flame(pts, cols, Vector2(px, fy + float(q % 3) * 2.0), 6.0, fl, sin(t * 3.0 + float(q)) * 3.0, 0.9)
			for q in 7:   # עשן מהחזית
				var kk := fmod(float(q) / 7.0 + t * 0.04, 1.0)
				U.blob(pts, cols, Vector2(fx + 90.0 - kk * 80.0, fy - 14.0 - kk * 220.0), 40.0 + kk * 90.0, 22.0 + kk * 50.0, Color(0.25, 0.2, 0.19, 0.4 * (1.0 - kk)), 10)
	U.flush(ci, pts, cols)
	# אובך שדוחף את הגבעות לאחור
	Kit.haze_band(ci, v, top - 60.0, y + 20.0, Color(0.55, 0.42, 0.34, 0.3))


# ---- גזעים שחורים עבים, גדמי בונים, גדמים מעלים עשן, גזעים שנפלו ----
static func near_forest(ci: CanvasItem, sc: float, v: Vector2, y: float, t: float) -> void:
	var base := y - 16.0
	var period := 1100.0
	var start := int(floor(sc / period)) - 1
	var pts := PackedVector2Array()
	var cols := PackedColorArray()
	DrawBatch.rect(ci, Rect2(0, base - 6.0, v.x, v.y - base + 6.0), Color("3a3330"))
	for k in range(start, start + int(ceil(v.x / period)) + 2):
		var bx := float(k) * period - sc
		# תלוליות אפר
		for q in 6:
			var ax := bx + _h(k * 6 + q, 1) * period
			U.oval(pts, cols, Vector2(ax, base - 2.0), 60.0 + _h(q, k) * 50.0, 10.0, Color(0.42, 0.39, 0.37), 10)
			U.oval(pts, cols, Vector2(ax - 10.0, base - 6.0), 34.0, 4.0, Color(0.56, 0.53, 0.5, 0.7), 8)
		# גזעים עבים
		for q in 5:
			var tx := bx + 80.0 + float(q) * 210.0 + _h(k * 5 + q, 3) * 90.0
			var th := 160.0 + _h(k * 5 + q, 4) * 170.0
			var tw := 9.0 + _h(k * 5 + q, 5) * 7.0
			var lean := (_h(k * 5 + q, 6) - 0.5) * 0.08
			U.trunk(pts, cols, Vector2(tx, base), th, tw, lean, Color("181514"), k * 5 + q + 300)
			# פחם "עור תנין": משבצות קטנות בהירות יותר
			for r in int(th / 14.0):
				var ry := base - 8.0 - float(r) * 13.0
				var rx := tx + lean * (base - ry) + (float(r % 2) - 0.5) * tw * 0.6
				U.quad(pts, cols, Vector2(rx - tw * 0.35, ry), Vector2(rx + tw * 0.3, ry - 1.0), Vector2(rx + tw * 0.28, ry - 7.0), Vector2(rx - tw * 0.33, ry - 6.0), Color("2a2624"), Color("2a2624"), Color("34302c"), Color("34302c"))
			# סדק לוחש בגזע (חלק מהגזעים)
			if _h(k * 5 + q, 7) < 0.45:
				var gy := base - 20.0 - _h(k * 5 + q, 8) * th * 0.5
				var gx := tx + lean * (base - gy)
				var pulse := 0.55 + 0.45 * sin(t * (1.5 + _h(q, k) * 2.0) + float(q * 3 + k))
				U.blob(pts, cols, Vector2(gx, gy - 8.0), tw * 1.8, 18.0, Color(1.0, 0.4, 0.1, 0.25 * pulse), 10)
				U.quad(pts, cols, Vector2(gx - 1.6, gy), Vector2(gx + 1.6, gy), Vector2(gx + 0.8, gy - 18.0), Vector2(gx - 0.8, gy - 18.0), Color(1.0, 0.5, 0.15, pulse), Color(1.0, 0.5, 0.15, pulse), Color(1.0, 0.8, 0.3, pulse), Color(1.0, 0.8, 0.3, pulse))
			# זקן שרוף תלוי (Usnea)
			if q % 2 == 1:
				var lp := Vector2(tx + lean * th * 0.6 + tw, base - th * 0.6)
				for r in 4:
					var sw := sin(t * 1.2 + float(r + q)) * 2.0
					U.tri(pts, cols, lp + Vector2(float(r) * 3.0, 0), lp + Vector2(float(r) * 3.0 + 2.0, 0), lp + Vector2(float(r) * 3.0 + 1.0 + sw, 12.0 + float(r % 2) * 6.0), Color(0.5, 0.48, 0.42, 0.7))
		# גדם מחודד של בונה (חתוך כמו עיפרון)
		var px := bx + 610.0 + _h(k, 9) * 120.0
		U.quad(pts, cols, Vector2(px - 8, base), Vector2(px + 8, base), Vector2(px + 7, base - 18.0), Vector2(px - 7, base - 18.0), Color("2a2420"), Color("2a2420"), Color("3a3028"), Color("3a3028"))
		U.tri(pts, cols, Vector2(px - 7, base - 18.0), Vector2(px + 7, base - 18.0), Vector2(px + 1, base - 32.0), Color("8a6a48"))
		U.tri(pts, cols, Vector2(px + 1, base - 32.0), Vector2(px + 7, base - 18.0), Vector2(px + 3, base - 18.0), Color("6a4c34"))
		# גדם מעלה עשן עם גחלים
		var sx := bx + 420.0 + _h(k, 10) * 140.0
		U.quad(pts, cols, Vector2(sx - 14, base), Vector2(sx + 14, base), Vector2(sx + 11, base - 22.0), Vector2(sx - 12, base - 24.0), Color("1e1a18"), Color("1e1a18"), Color("2c2724"), Color("2c2724"))
		var gl := 0.6 + 0.4 * sin(t * 2.3 + float(k))
		U.oval(pts, cols, Vector2(sx, base - 23.0), 10.0, 3.0, Color(1.0, 0.45, 0.12, 0.8 * gl), 8)
		for q in 5:
			var kk := fmod(float(q) / 5.0 + t * 0.12 + _h(k, 11), 1.0)
			U.blob(pts, cols, Vector2(sx + kk * 26.0 + sin(t + float(q)) * 4.0, base - 30.0 - kk * 120.0), 8.0 + kk * 26.0, 6.0 + kk * 18.0, Color(0.36, 0.32, 0.3, 0.42 * (1.0 - kk)), 8)
		# גזע שנפל
		var lx := bx + 860.0
		U.quad(pts, cols, Vector2(lx, base - 2.0), Vector2(lx + 150.0, base - 12.0), Vector2(lx + 150.0, base - 26.0), Vector2(lx, base - 18.0), Color("1c1816"), Color("1c1816"), Color("2e2824"), Color("2e2824"))
		U.oval(pts, cols, Vector2(lx + 150.0, base - 19.0), 4.0, 7.0, Color("5a4632"), 8)
	U.flush(ci, pts, cols)


# אובך חם מאחורי הדמויות + עשן נמוך (סמיך יותר כשיש עשן)
static func forest_overlay(ci: CanvasItem, v: Vector2, t: float) -> void:
	var s := U.smoke
	Kit.haze_band(ci, v, 420.0, 614.0, Color(0.66, 0.54, 0.46, 0.26 + 0.12 * s))
	var pts := PackedVector2Array()
	var cols := PackedColorArray()
	for i in 8:
		var mx := fposmod(float(i) * 260.0 - t * (18.0 + float(i) * 5.0), v.x + 600.0) - 300.0
		U.blob(pts, cols, Vector2(mx, 540.0 + float(i % 3) * 22.0), 240.0, 34.0, Color(0.55, 0.5, 0.47, 0.1 + 0.18 * s), 14)
	U.flush(ci, pts, cols)


# ============================================================
#  עולם
# ============================================================

# ---- קרקע: אפר על אדמה שרופה, פחמים, גחלים ----
class AshGround extends Node2D:
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
		var r := RandomNumberGenerator.new()
		r.seed = seed_v
		var pts := PackedVector2Array()
		var cols := PackedColorArray()
		U.rect(pts, cols, Rect2(0, 0, w, depth), SOIL)
		U.rect(pts, cols, Rect2(0, 0, w, 12.0), ASH)
		U.rect(pts, cols, Rect2(0, 9.0, w, 7.0), ASH_D)
		U.rect(pts, cols, Rect2(0, 16.0, w, 20.0), Color("2e2624"))
		U.rect(pts, cols, Rect2(0, 0, w, 1.6), Color(0.86, 0.84, 0.8, 0.55))
		for i in int(w / 6.0):   # גושי אפר ופחם
			var c := ASH.lerp(ASH_L, r.randf() * 0.6) if r.randf() < 0.6 else CHAR_L.lerp(CHAR, r.randf())
			U.oval(pts, cols, Vector2(r.randf_range(0.0, w), r.randf_range(1.0, 11.0)), r.randf_range(1.2, 3.4), r.randf_range(0.8, 1.8), c, 6)
		for i in int(w / 70.0):   # ענפים שרופים שוכבים
			var p := Vector2(r.randf_range(0.0, w), r.randf_range(2.0, 9.0))
			var ln := r.randf_range(14.0, 34.0)
			var a := r.randf_range(-0.25, 0.25)
			U.quad(pts, cols, p + Vector2(0, -1.0), p + Vector2(cos(a) * ln, sin(a) * ln - 1.0), p + Vector2(cos(a) * ln, sin(a) * ln + 1.0), p + Vector2(0, 1.0), CHAR, CHAR, CHAR_L, CHAR_L)
		for i in int(w / 55.0):   # גחלים קטנות בתוך האפר
			var p := Vector2(r.randf_range(0.0, w), r.randf_range(3.0, 10.0))
			U.oval(pts, cols, p, r.randf_range(1.0, 2.0), 0.9, Color(1.0, 0.45, 0.12, r.randf_range(0.5, 0.9)), 6)
		for i in int(w / 30.0):   # שורשים / אבנים בעומק
			U.oval(pts, cols, Vector2(r.randf_range(0.0, w), r.randf_range(26.0, depth - 6.0)), r.randf_range(2.0, 4.0), r.randf_range(1.4, 2.6), Color("1a1514"), 6)
		U.flush(self, pts, cols)


# ---- שלט הכניסה לפארק + שעון סכנת שריפה על "EXTREMO" ----
class ParkSign extends Node2D:
	func _ready() -> void:
		z_index = -2

	func _draw() -> void:
		DrawBatch.begin(self)
		_draw_b()
		DrawBatch.end(self)

	func _draw_b() -> void:
		var f := ThemeDB.fallback_font
		# שלט עץ גדול על שני עמודים (חרוך בצד ימין)
		for px in [10.0, 250.0]:
			DrawBatch.rect(self, Rect2(px, -170.0, 14.0, 170.0), WOOD_D)
		DrawBatch.colored_polygon(self, PackedVector2Array([Vector2(-6, -200), Vector2(280, -200), Vector2(290, -186), Vector2(276, -150), Vector2(240, -142), Vector2(-6, -142)]), Color("7a5634"))
		DrawBatch.colored_polygon(self, PackedVector2Array([Vector2(200, -200), Vector2(280, -200), Vector2(290, -186), Vector2(276, -150), Vector2(240, -142), Vector2(196, -150), Vector2(214, -170)]), CHAR)
		DrawBatch.line(self, Vector2(-6, -200), Vector2(200, -200), WOOD_L, 2.0)
		DrawBatch.string(self, f, Vector2(4, -180), "PARQUE NACIONAL", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("f0e0b0"))
		DrawBatch.string(self, f, Vector2(4, -160), "TIERRA DEL FUEGO", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("f0e0b0"))
		# שעון סכנת שריפה (חצי עיגול צבעוני, המחוג על EXTREMO)
		var c := Vector2(360, -120)
		DrawBatch.rect(self, Rect2(c.x - 4.0, c.y, 8.0, 120.0), Color("5a5048"))
		DrawBatch.rect(self, Rect2(c.x - 70.0, c.y - 74.0, 140.0, 84.0), Color("e8e0cc"))
		DrawBatch.rect(self, Rect2(c.x - 70.0, c.y - 74.0, 140.0, 84.0), Color("3a3028"), false, 2.0)
		var bands := [Color("3a8a3a"), Color("3a6ac0"), Color("e0c030"), Color("e07020"), Color("c02020")]
		for i in 5:
			var a0 := PI + float(i) / 5.0 * PI
			var a1 := PI + float(i + 1) / 5.0 * PI
			var poly := PackedVector2Array([c + Vector2.from_angle(a0) * 24.0])
			for q in 5:
				poly.append(c + Vector2.from_angle(lerpf(a0, a1, float(q) / 4.0)) * 58.0)
			poly.append(c + Vector2.from_angle(a1) * 24.0)
			DrawBatch.colored_polygon(self, poly, bands[i])
		DrawBatch.line(self, c, c + Vector2.from_angle(PI * 1.9) * 54.0, Color("1a1a1a"), 3.0)
		DrawBatch.circle(self, c, 5.0, Color("1a1a1a"))
		DrawBatch.string(self, f, Vector2(c.x - 62.0, c.y + 4.0), "PELIGRO DE INCENDIO", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("3a2018"))
		DrawBatch.string(self, f, Vector2(c.x + 18.0, c.y - 44.0), "EXTREMO", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color("c02020"))
		# כתם חריכה על הכל
		DrawBatch.colored_polygon(self, Art.ellipse(Vector2(c.x + 40.0, c.y - 60.0), 26.0, 14.0, 0.3, 12), Color(0.08, 0.06, 0.05, 0.55))


# ---- בקתת שומרי הפארק: עץ, חצי שרופה, גג המרפסת = קומה ----
class RangerHut extends Node2D:
	var w := 300.0
	var tier := 150.0
	var _t := 0.0

	func _ready() -> void:
		z_index = -2

	func _process(delta: float) -> void:
		_t += delta
		if Engine.get_process_frames() % 4 == 0 and Art.on_screen(self, global_position + Vector2(w * 0.5, -80.0), w):
			queue_redraw()

	func _draw() -> void:
		DrawBatch.begin(self)
		_draw_b()
		DrawBatch.end(self)

	func _draw_b() -> void:
		var f := ThemeDB.fallback_font
		var pts := PackedVector2Array()
		var cols := PackedColorArray()
		# קירות קרשים (ירוק שומרים דהוי, חרוך מימין)
		var wall := Rect2(10.0, -tier, w - 20.0, tier)
		U.rect(pts, cols, wall, Color("4a5a40"))
		for q in int(wall.size.y / 12.0):
			var yy := -tier + 6.0 + float(q) * 12.0
			U.rect(pts, cols, Rect2(wall.position.x, yy, wall.size.x, 1.6), Color(0.15, 0.18, 0.12, 0.6))
		U.quad(pts, cols, Vector2(w * 0.62, 0), Vector2(w - 10.0, 0), Vector2(w - 10.0, -tier), Vector2(w * 0.74, -tier), Color(0.08, 0.07, 0.06, 0.95), Color(0.08, 0.07, 0.06, 0.95), Color(0.12, 0.1, 0.09, 0.9), Color(0.12, 0.1, 0.09, 0.0))
		# חלון זוהר (אש בפנים) + דלת פתוחה
		var gl := 0.6 + 0.3 * sin(_t * 7.0) * sin(_t * 3.1)
		U.rect(pts, cols, Rect2(40.0, -tier + 36.0, 50.0, 40.0), Color(1.0, 0.5, 0.16, 0.55 + 0.35 * gl))
		U.rect(pts, cols, Rect2(63.0, -tier + 36.0, 4.0, 40.0), WOOD_D)
		U.rect(pts, cols, Rect2(40.0, -tier + 54.0, 50.0, 4.0), WOOD_D)
		U.blob(pts, cols, Vector2(65.0, -tier + 56.0), 60.0, 40.0, Color(1.0, 0.5, 0.16, 0.25 * gl), 12)
		U.rect(pts, cols, Rect2(120.0, -96.0, 44.0, 96.0), Color("120e0c"))
		U.quad(pts, cols, Vector2(164, -96), Vector2(184, -90), Vector2(184, -4), Vector2(164, 0), Color("5a4630"), Color("4a3a28"), Color("4a3a28"), Color("5a4630"))
		# גג המרפסת: קורות + מעקה (הקומה)
		U.rect(pts, cols, Rect2(-6.0, -tier - 8.0, w + 12.0, 10.0), WOOD_D)
		U.rect(pts, cols, Rect2(-6.0, -tier - 8.0, w + 12.0, 2.0), WOOD_L)
		for q in int(w / 24.0) + 1:
			U.rect(pts, cols, Rect2(float(q) * 24.0 - 2.0, -tier - 30.0, 3.0, 22.0), WOOD_D)
		U.rect(pts, cols, Rect2(-6.0, -tier - 32.0, w * 0.7, 4.0), WOOD)
		# אנטנת רדיו + ארובה מעשנת
		U.rect(pts, cols, Rect2(w - 50.0, -tier - 90.0, 3.0, 60.0), Color("6a6a6a"))
		U.tri(pts, cols, Vector2(w - 60.0, -tier - 74.0), Vector2(w - 36.0, -tier - 74.0), Vector2(w - 48.5, -tier - 90.0), Color(0.5, 0.5, 0.5, 0.6))
		U.rect(pts, cols, Rect2(30.0, -tier - 56.0, 18.0, 26.0), Color("5a4a40"))
		for q in 5:
			var kk := fmod(float(q) / 5.0 + _t * 0.12, 1.0)
			U.blob(pts, cols, Vector2(39.0 - kk * 40.0, -tier - 60.0 - kk * 110.0), 9.0 + kk * 26.0, 7.0 + kk * 20.0, Color(0.3, 0.27, 0.25, 0.5 * (1.0 - kk)), 8)
		U.flush(self, pts, cols)
		DrawBatch.rect(self, Rect2(30.0, -tier + 4.0, 170.0, 22.0), Color("2e3a26"))
		DrawBatch.string(self, f, Vector2(36.0, -tier + 20.0), "GUARDAPARQUES", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, SIGN_Y)


# ---- מגדל תצפית אש (במה למעלה = קומה) ----
class LookoutTower extends Node2D:
	var w := 140.0
	var tier := 220.0

	func _ready() -> void:
		z_index = -2

	func _draw() -> void:
		DrawBatch.begin(self)
		_draw_b()
		DrawBatch.end(self)

	func _draw_b() -> void:
		var pts := PackedVector2Array()
		var cols := PackedColorArray()
		var lt := Vector2(18.0, -tier)
		var rt := Vector2(w - 18.0, -tier)
		for s in [[Vector2(0, 0), lt], [Vector2(w, 0), rt]]:   # רגליים
			var a: Vector2 = s[0]
			var b: Vector2 = s[1]
			U.quad(pts, cols, a + Vector2(-4, 0), b + Vector2(-3, 0), b + Vector2(3, 0), a + Vector2(4, 0), WOOD_D, WOOD_D, WOOD, WOOD)
		for q in 4:   # קורות אלכסוניות (X)
			var y0 := -float(q) * tier / 4.0
			var y1 := -float(q + 1) * tier / 4.0
			var x0 := lerpf(0.0, 18.0, -y0 / tier)
			var x1 := lerpf(w, w - 18.0, -y1 / tier)
			U.quad(pts, cols, Vector2(x0, y0), Vector2(x1, y1), Vector2(x1, y1 + 3.0), Vector2(x0, y0 + 3.0), WOOD_D, WOOD_D, WOOD_D, WOOD_D)
			U.quad(pts, cols, Vector2(lerpf(w, w - 18.0, -y0 / tier), y0), Vector2(lerpf(0.0, 18.0, -y1 / tier), y1), Vector2(lerpf(0.0, 18.0, -y1 / tier), y1 + 3.0), Vector2(lerpf(w, w - 18.0, -y0 / tier), y0 + 3.0), WOOD_D, WOOD_D, WOOD_D, WOOD_D)
		# הבמה + תא התצפית
		U.rect(pts, cols, Rect2(-10.0, -tier - 8.0, w + 20.0, 10.0), WOOD_D)
		U.rect(pts, cols, Rect2(-10.0, -tier - 8.0, w + 20.0, 2.0), WOOD_L)
		U.rect(pts, cols, Rect2(-10.0, -tier - 34.0, w + 20.0, 4.0), WOOD)
		for q in 8:
			U.rect(pts, cols, Rect2(-10.0 + float(q) * (w + 20.0) / 7.0, -tier - 34.0, 3.0, 26.0), WOOD_D)
		U.rect(pts, cols, Rect2(20.0, -tier - 104.0, w - 40.0, 70.0), Color("5a4a3a"))
		U.rect(pts, cols, Rect2(28.0, -tier - 94.0, w - 56.0, 30.0), Color(1.0, 0.62, 0.3, 0.4))
		U.quad(pts, cols, Vector2(6.0, -tier - 104.0), Vector2(w - 6.0, -tier - 104.0), Vector2(w * 0.5 + 10.0, -tier - 140.0), Vector2(w * 0.5 - 10.0, -tier - 140.0), Color("3a2a22"), Color("3a2a22"), Color("4a362a"), Color("4a362a"))
		U.rect(pts, cols, Rect2(w * 0.5 - 1.0, -tier - 170.0, 2.0, 30.0), Color("6a6a6a"))
		# שקית רוח קרועה
		U.tri(pts, cols, Vector2(w * 0.5 + 1.0, -tier - 170.0), Vector2(w * 0.5 + 1.0, -tier - 160.0), Vector2(w * 0.5 + 30.0, -tier - 162.0), Color("d06a2a"))
		U.flush(self, pts, cols)


# ---- קרחה מוצפת מאחורי סכר בונים: מים כהים, עצים מתים טבועים, מאורה. הסכר = קומה נמוכה ----
class BeaverPond extends Node2D:
	var w := 500.0
	var dam_from := 0.55          # מאיזה חלק של הרוחב מתחיל הסכר (עד הסוף)
	var dam_tier := 56.0
	var seed_v := 0
	var _t := 0.0

	func _ready() -> void:
		z_index = 2
		add_to_group("s59_ponds")

	func has_x(x: float, margin := 0.0) -> bool:
		return x > global_position.x - margin and x < global_position.x + w + margin

	func _process(delta: float) -> void:
		_t += delta
		if Engine.get_process_frames() % 4 == 0 and Art.on_screen(self, global_position + Vector2(w * 0.5, -40.0), w * 0.5 + 60.0):
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
		# המים (מעל הקרקע, כהים, עם שכבת אפר)
		U.quad(pts, cols, Vector2(-14, 2), Vector2(w + 14, 2), Vector2(w + 4, 16), Vector2(-4, 16), Color("2a2624"), Color("2a2624"), Color("1e1a18"), Color("1e1a18"))
		U.quad(pts, cols, Vector2(-6, -4), Vector2(w + 6, -4), Vector2(w, 10), Vector2(0, 10), WATER.lightened(0.08), WATER.lightened(0.08), WATER, WATER)
		U.rect(pts, cols, Rect2(-6, -4.5, w + 12, 1.4), Color(0.85, 0.6, 0.4, 0.5))   # ברק כתום מהשמיים
		for i in 9:   # אדוות
			var x := fposmod(float(i) * 61.0 + _t * (6.0 + float(i % 3) * 3.0), w - 20.0) + 10.0
			var a := 0.2 + 0.15 * sin(_t * 2.0 + float(i))
			U.quad(pts, cols, Vector2(x, -1.0), Vector2(x + 18.0, -1.0), Vector2(x + 18.0, 0.0), Vector2(x, 0.0), Color(1, 0.8, 0.6, 0.0), Color(1, 0.8, 0.6, a), Color(1, 0.8, 0.6, a), Color(1, 0.8, 0.6, 0.0))
		for i in int(w / 22.0):   # אפר צף
			U.oval(pts, cols, Vector2(r.randf_range(4.0, w - 4.0), r.randf_range(-3.0, 3.0)), r.randf_range(3.0, 8.0), 0.8, Color(0.6, 0.58, 0.55, 0.45), 6)
		# עצים מתים טבועים (אפורים, בלי קליפה) עם השתקפות
		var n := 3 + int(w / 200.0)
		for i in n:
			var tx := w * (0.1 + 0.42 * float(i) / float(n)) + r.randf_range(-10.0, 10.0)
			var th := r.randf_range(120.0, 210.0)
			U.trunk(pts, cols, Vector2(tx, 0.0), th, r.randf_range(4.0, 6.0), r.randf_range(-0.06, 0.06), Color("8a8480"), int(seed_v % 997) + i)
			U.quad(pts, cols, Vector2(tx - 4.0, 0.0), Vector2(tx + 4.0, 0.0), Vector2(tx + 3.0, 10.0), Vector2(tx - 3.0, 10.0), Color(0.55, 0.52, 0.5, 0.4), Color(0.55, 0.52, 0.5, 0.4), Color(0.55, 0.52, 0.5, 0.0), Color(0.55, 0.52, 0.5, 0.0))
		# מאורת הבונים (תל של מקלות ובוץ) בשמאל
		var lx := w * 0.2
		U.oval(pts, cols, Vector2(lx, -6.0), 46.0, 26.0, Color("4a3a2c"), 14)
		for q in 18:
			var a := PI + r.randf() * PI
			var p := Vector2(lx, -6.0) + Vector2(cos(a) * 40.0 * r.randf(), sin(a) * 22.0 * r.randf())
			var e := p + Vector2.from_angle(r.randf_range(-0.8, 0.8)) * r.randf_range(10.0, 22.0)
			U.quad(pts, cols, p, e, e + Vector2(0, 1.4), p + Vector2(0, 1.4), Color("6a5038"), Color("6a5038"), Color("4a3828"), Color("4a3828"))
		# הסכר: קיר של מקלות, בוץ ובולים (הקומה)
		var d0 := w * dam_from
		var dpts := PackedVector2Array([Vector2(d0 - 20.0, 4.0), Vector2(d0, -dam_tier), Vector2(w + 10.0, -dam_tier + 2.0), Vector2(w + 24.0, 4.0)])
		DrawBatch.colored_polygon(self, dpts, Color("3a2c22"))
		for q in int((w - d0) / 6.0):
			var x := r.randf_range(d0, w + 10.0)
			var yy := -r.randf_range(4.0, dam_tier)
			var e := Vector2(x, yy) + Vector2.from_angle(r.randf_range(-0.6, 0.6) + (PI if r.randf() < 0.5 else 0.0)) * r.randf_range(10.0, 26.0)
			U.quad(pts, cols, Vector2(x, yy), e, e + Vector2(0, 1.6), Vector2(x, yy + 1.6), Color("7a5a3c"), Color("5a4430"), Color("5a4430"), Color("7a5a3c"))
		U.rect(pts, cols, Rect2(d0, -dam_tier - 4.0, w - d0 + 10.0, 6.0), Color("5a4430"))
		U.rect(pts, cols, Rect2(d0, -dam_tier - 4.0, w - d0 + 10.0, 1.6), WOOD_L)
		# מים שזולגים מעל הסכר
		for q in 4:
			var x := d0 + (w - d0) * (0.2 + 0.2 * float(q))
			var k := fmod(_t * 1.2 + float(q) * 0.3, 1.0)
			U.quad(pts, cols, Vector2(x, -dam_tier + 2.0), Vector2(x + 3.0, -dam_tier + 2.0), Vector2(x + 4.0, -dam_tier + 2.0 + dam_tier * k), Vector2(x + 1.0, -dam_tier + 2.0 + dam_tier * k), Color(0.7, 0.68, 0.66, 0.4), Color(0.7, 0.68, 0.66, 0.4), Color(0.7, 0.68, 0.66, 0.0), Color(0.7, 0.68, 0.66, 0.0))
		U.flush(self, pts, cols)


# ============================================================
#  מלכודת: פס אש זוחל (LOW -> WARN -> FLARE)
# ============================================================
class FireLine extends Hazard:
	const LOW_T := Vector2(3.2, 4.6)
	const WARN_T := 0.85
	const FLARE_T := 2.6
	const DMG := 1
	var w := 200.0
	var state := 0                  # 0 = גחלים, 1 = אזהרה, 2 = להבות
	var flares := 0                 # לבדיקות
	var _st := 2.0
	var _t := 0.0
	var _seed := 0.0
	var _licks := []

	func _ready() -> void:
		super._ready()
		add_to_group("s59_fires")
		z_index = 3
		_seed = randf() * 50.0
		_st = randf_range(1.0, 3.0)
		rect = Rect2(0.0, -40.0, w, 42.0)
		story_kind = "fire"
		tick = 0.5
		player_damage = 0
		zombie_burn = 0.0
		var n := int(w / 14.0)
		for i in n:
			_licks.append([(float(i) + 0.5 + randf_range(-0.3, 0.3)) * w / float(n), randf_range(0.7, 1.2), randf() * TAU, randf_range(0.8, 1.3)])

	func flaring() -> bool:
		return state == 2

	func glow_pos() -> Vector2:
		return global_position + Vector2(w * 0.5, -30.0)

	# כמה להבות עכשיו (0..1) - למשיכת ASHMOTH ולציור
	func heat() -> float:
		match state:
			1:
				return 0.3 + 0.4 * (1.0 - _st / WARN_T)
			2:
				return 1.0
		return 0.15

	func flare_now() -> void:
		if state == 2:
			_st = maxf(_st, FLARE_T * 0.6)
			return
		state = 1
		_st = 0.25

	func _hazard_tick(delta: float) -> void:
		_t += delta
		_st -= delta
		match state:
			0:
				if _st <= 0.0:
					state = 1
					_st = WARN_T
					if Art.on_screen(self, glow_pos(), w):
						Sfx.play("s59_crackle", glow_pos(), -4.0, 0.15, 3)
			1:
				if Engine.get_physics_frames() % 4 == 0 and Art.on_screen(self, glow_pos(), w):
					Particles.burst(get_parent(), global_position + Vector2(randf_range(0.0, w), -6.0), "fire", Vector2.UP, 2)
				if _st <= 0.0:
					state = 2
					_st = FLARE_T
					flares += 1
					player_damage = DMG
					zombie_burn = 3.0
					_tick_t = 0.0
					if Art.on_screen(self, glow_pos(), w):
						Sfx.play("s59_flare", glow_pos(), 0.0, 0.1, 2)
			2:
				if _st <= 0.0:
					state = 0
					_st = randf_range(LOW_T.x, LOW_T.y)
					player_damage = 0
					zombie_burn = 0.0
		if (Engine.get_physics_frames() + int(_seed)) % (2 if Quality.level < 2 else 3) == 0 and Art.on_screen(self, glow_pos(), w * 0.5 + 120.0):
			queue_redraw()

	func _draw() -> void:
		DrawBatch.begin(self)
		_draw_b()
		DrawBatch.end(self)

	func _draw_b() -> void:
		var pts := PackedVector2Array()
		var cols := PackedColorArray()
		var tt := _t + _seed
		var I := heat()
		# פס אדמה חרוכה + גחלים לוחשות
		U.quad(pts, cols, Vector2(-10, 1), Vector2(w + 10, 1), Vector2(w + 4, -3), Vector2(-4, -3), Color(0.06, 0.04, 0.03, 0.8), Color(0.06, 0.04, 0.03, 0.8), Color(0.1, 0.06, 0.04, 0.6), Color(0.1, 0.06, 0.04, 0.6))
		U.blob(pts, cols, Vector2(w * 0.5, -4.0), w * 0.6 + 20.0, 18.0 + 30.0 * I, Color(1.0, 0.42, 0.12, 0.18 + 0.22 * I), 14)
		for L in _licks:
			var x: float = L[0]
			var ph: float = L[2]
			var g := 0.5 + 0.5 * sin(tt * 3.0 * float(L[3]) + ph)
			U.oval(pts, cols, Vector2(x, -1.0), 5.0, 1.6, Color(1.0, 0.4 + 0.3 * g, 0.1, 0.7 + 0.3 * g), 6)
		# להבות: נמוכות בגחלים, גבוהות ב-FLARE
		for L in _licks:
			var x: float = L[0]
			var ph: float = L[2]
			var sp: float = L[3]
			var wv := 0.5 + 0.3 * sin(tt * 7.3 * sp + ph) + 0.2 * sin(tt * 13.1 * sp + ph * 2.0)
			var hh := (5.0 + 6.0 * wv) if state == 0 else (lerpf(10.0, 44.0, I) * float(L[1]) * (0.6 + 0.6 * wv))
			var sway := sin(tt * 3.1 * sp + ph) * (2.0 + 4.0 * I)
			U.flame(pts, cols, Vector2(x, 0.0), 6.0 + 3.0 * I, hh, sway, 0.65 + 0.35 * I)
		# ניצוצות עולים
		var ne := 4 + int(w / 30.0 * I)
		for i in ne:
			var k := fmod(float(i) * 0.37 + tt * (0.5 + float(i % 3) * 0.2), 1.0)
			var ex := fmod(float(i) * 41.0, w) + sin(tt * 3.0 + float(i)) * 6.0
			U.dia(pts, cols, Vector2(ex, -8.0 - k * (40.0 + 60.0 * I)), 1.3 * (1.0 - k) + 0.5, Color(1.0, 0.7, 0.3, (1.0 - k) * (0.4 + 0.6 * I)))
		if state == 2:   # עשן מעל הלהבות
			for i in 4:
				var k := fmod(float(i) / 4.0 + tt * 0.3, 1.0)
				U.blob(pts, cols, Vector2(w * (0.2 + 0.2 * float(i)) + k * 20.0, -50.0 - k * 80.0), 20.0 + k * 30.0, 14.0 + k * 20.0, Color(0.2, 0.17, 0.16, 0.35 * (1.0 - k)), 8)
		U.flush(self, pts, cols)


# ============================================================
#  מלכודת: עץ שרוף שנופל לרוחב הדרך
# ============================================================
class Snag extends Node2D:
	const TRIG_R := 300.0
	const WARN_T := 1.1
	const FALL_T := 0.55
	const DMG := 2
	const DMG_Z := 70
	var h := 260.0
	var fall_dir := -1.0            # לאיזה צד נופל (נקבע לכיוון השחקן)
	var state := 0                  # 0 עומד, 1 חורק, 2 נופל, 3 שוכב
	var falls := 0                  # לבדיקות
	var hits := 0
	var zhits := 0
	var _st := 0.0
	var _ang := 0.0
	var _t := 0.0
	var _body: StaticBody2D = null
	var _seed := 0

	func _ready() -> void:
		z_index = 3
		_seed = randi() % 1000
		add_to_group("blastable")
		_body = SnagBody.new()
		_body.trap = self
		_body.collision_layer = 4
		_body.collision_mask = 0
		_body.add_to_group("no_outline")
		var cs := CollisionShape2D.new()
		var rs := RectangleShape2D.new()
		rs.size = Vector2(26.0, 40.0)
		cs.shape = rs
		cs.position = Vector2(0, -22.0)
		_body.add_child(cs)
		add_child(_body)

	func blast_rect() -> Rect2:
		return Rect2(global_position + Vector2(-16, -50), Vector2(32, 50))

	func hit_by_blast(_c: Vector2, _r: float) -> void:
		start(true)

	# shot = נורה / פוצץ: נופל מהר יותר
	func start(shot := false) -> void:
		if state != 0:
			if state == 1 and shot:
				_st = minf(_st, 0.2)
			return
		state = 1
		_st = WARN_T * (0.35 if shot else 1.0)
		var pl := get_tree().get_first_node_in_group("player") as Node2D
		if pl != null:
			fall_dir = signf(pl.global_position.x - global_position.x)
			if fall_dir == 0.0:
				fall_dir = -1.0
		Sfx.play("s59_creak", global_position + Vector2(0, -h * 0.5), 2.0, 0.1, 2)

	func _process(delta: float) -> void:
		_t += delta
		var pl := get_tree().get_first_node_in_group("player") as Node2D
		match state:
			0:
				if pl != null and not pl.dead and absf(pl.global_position.x - global_position.x) < TRIG_R and absf(pl.global_position.y - global_position.y) < 120.0:
					start(false)
			1:
				_st -= delta
				_ang = sin(_t * 30.0) * 0.012 + fall_dir * 0.03 * (1.0 - _st / WARN_T)
				if Engine.get_process_frames() % 4 == 0:
					Particles.burst(get_parent(), global_position + Vector2(randf_range(-8, 8), -10.0), "fire", Vector2(0, -1), 2)
				if _st <= 0.0:
					state = 2
					_st = FALL_T
					falls += 1
					_body.collision_layer = 0
					Sfx.play("s59_crack", global_position, 4.0, 0.1, 2)
			2:
				_st -= delta
				var k := clampf(1.0 - _st / FALL_T, 0.0, 1.0)
				_ang = fall_dir * (0.03 + (PI * 0.5 - 0.06) * k * k)
				if _st <= 0.0:
					_land(pl)
		if state != 3 and Art.on_screen(self, global_position + Vector2(0, -h * 0.5), h):
			if state != 0 or Engine.get_process_frames() % 6 == 0:
				queue_redraw()

	func _land(pl: Node2D) -> void:
		state = 3
		_ang = fall_dir * (PI * 0.5 - 0.06)
		var x0 := global_position.x + minf(0.0, fall_dir * h)
		var x1 := global_position.x + maxf(0.0, fall_dir * h)
		var r := Rect2(x0, global_position.y - 40.0, x1 - x0, 44.0)
		Sfx.play("s59_thud", global_position + Vector2(fall_dir * h * 0.5, -10.0), 6.0, 0.05, 2)
		var cam := get_viewport().get_camera_2d()
		if cam != null and cam.has_method("shake") and Art.on_screen(self, global_position, h):
			cam.shake(10.0, 0.35)
		for i in 10:
			Particles.burst(get_parent(), Vector2(lerpf(x0, x1, float(i) / 9.0), global_position.y - 6.0), "smoke" if i % 2 == 0 else "fire", Vector2.UP, 3)
		if pl != null and not pl.dead and r.intersects(pl.body_rect()):
			if pl._roll_t <= 0.0:
				hits += 1
			pl.hurt(DMG, Vector2(fall_dir * 0.6, -0.6))
		for z in get_tree().get_nodes_in_group("zombies"):
			if not z.dead and r.has_point(z.global_position + Vector2(0, -10)):
				zhits += 1
				z.take_damage(DMG_Z if not z.is_boss() else 30, z.global_position + Vector2(0, -30), Vector2(fall_dir, -0.3), true, {"source": "s59_snag", "fixed": DMG_Z if not z.is_boss() else 30})
		# הגזע נשאר על הדרך: מחסה נמוך שמעלה עשן
		var lg := FallenLog.new()
		lg.w = h * 0.86
		lg.seed_v = _seed
		get_parent().add_child(lg)
		lg.global_position = Vector2(x0 + (h * 0.14 if fall_dir < 0.0 else 0.0), global_position.y)
		queue_redraw()

	func _draw() -> void:
		DrawBatch.begin(self)
		_draw_b()
		DrawBatch.end(self)

	func _draw_b() -> void:
		var pts := PackedVector2Array()
		var cols := PackedColorArray()
		if state == 3:   # רק הגדם נשאר
			U.quad(pts, cols, Vector2(-11, 0), Vector2(11, 0), Vector2(9, -16), Vector2(-10, -12), Color("1a1614"), Color("1a1614"), Color("2a2420"), Color("2a2420"))
			U.oval(pts, cols, Vector2(0, -14), 9.0, 3.0, Color(1.0, 0.45, 0.12, 0.7), 8)
			U.flush(self, pts, cols)
			return
		# צל על הדרך איפה שייפול (אזהרה)
		if state == 1 or state == 2:
			var k := 1.0 if state == 2 else clampf(1.0 - _st / WARN_T, 0.0, 1.0)
			U.quad(pts, cols, Vector2(0, 2), Vector2(fall_dir * h, 2), Vector2(fall_dir * h, -3), Vector2(0, -3), Color(0, 0, 0, 0.45 * k), Color(0, 0, 0, 0.15 * k), Color(0, 0, 0, 0.0), Color(0, 0, 0, 0.0))
		U.flush(self, pts, cols)
		pts = PackedVector2Array()
		cols = PackedColorArray()
		DrawBatch.set_transform(self, Vector2.ZERO, _ang, Vector2.ONE)
		U.trunk(pts, cols, Vector2.ZERO, h, 11.0, 0.0, Color("161312"), _seed)
		for r in int(h / 16.0):   # פחם עור תנין
			var yy := -10.0 - float(r) * 15.0
			var xx := (float(r % 2) - 0.5) * 5.0
			U.quad(pts, cols, Vector2(xx - 4.0, yy), Vector2(xx + 4.0, yy - 1.0), Vector2(xx + 3.6, yy - 9.0), Vector2(xx - 3.8, yy - 8.0), Color("2a2522"), Color("2a2522"), Color("36302c"), Color("36302c"))
		# הבסיס הלוחש (נקודת התורפה - לירות כאן)
		var pulse := 0.6 + 0.4 * sin(_t * (4.0 if state == 0 else 16.0))
		U.blob(pts, cols, Vector2(0, -18.0), 22.0, 24.0, Color(1.0, 0.42, 0.1, 0.35 * pulse), 10)
		U.quad(pts, cols, Vector2(-8, -6), Vector2(8, -10), Vector2(6, -30), Vector2(-6, -26), Color(1.0, 0.4, 0.08, pulse), Color(1.0, 0.5, 0.1, pulse), Color(1.0, 0.8, 0.3, pulse), Color(1.0, 0.7, 0.2, pulse))
		U.quad(pts, cols, Vector2(-3, -8), Vector2(3, -9), Vector2(2, -26), Vector2(-2, -24), Color(1, 0.95, 0.7, pulse), Color(1, 0.95, 0.7, pulse), Color(1, 0.9, 0.6, 0.0), Color(1, 0.9, 0.6, 0.0))
		U.flush(self, pts, cols)
		DrawBatch.set_transform(self, Vector2.ZERO, 0.0, Vector2.ONE)


class SnagBody extends StaticBody2D:
	var trap = null

	func take_damage(_amount: int, hit_pos: Vector2, dir: Vector2, _explosive := false, _src := {}) -> void:
		if trap != null and is_instance_valid(trap):
			Particles.burst(trap.get_parent(), hit_pos, "fire", -dir, 4)
			trap.start(true)


# ---- גזע שנפל: מחסה נמוך (אפשר לקפוץ עליו), מעלה עשן לאט ----
class FallenLog extends Node2D:
	var w := 220.0
	var seed_v := 0
	var _t := 0.0
	var _life := 0.0

	func _ready() -> void:
		z_index = 2
		add_to_group("cover")
		var body := StaticBody2D.new()
		body.collision_layer = 1
		body.add_to_group("no_outline")
		var cs := CollisionShape2D.new()
		var sh := RectangleShape2D.new()
		sh.size = Vector2(w, 30.0)
		cs.shape = sh
		cs.position = Vector2(w * 0.5, -15.0)
		body.add_child(cs)
		add_child(body)

	func cover_rect() -> Rect2:
		return Rect2(global_position + Vector2(0.0, -30.0), Vector2(w, 30.0))

	func _process(delta: float) -> void:
		_t += delta
		_life += delta
		if Engine.get_process_frames() % 5 == 0 and Art.on_screen(self, global_position + Vector2(w * 0.5, -20.0), w):
			queue_redraw()

	func _draw() -> void:
		DrawBatch.begin(self)
		_draw_b()
		DrawBatch.end(self)

	func _draw_b() -> void:
		var pts := PackedVector2Array()
		var cols := PackedColorArray()
		U.quad(pts, cols, Vector2(0, 0), Vector2(w, 0), Vector2(w - 4.0, -30.0), Vector2(4.0, -28.0), Color("141110"), Color("141110"), Color("2e2824"), Color("2e2824"))
		for q in int(w / 18.0):
			var x := 8.0 + float(q) * 18.0
			U.quad(pts, cols, Vector2(x, -6.0), Vector2(x + 12.0, -7.0), Vector2(x + 11.0, -22.0), Vector2(x + 1.0, -21.0), Color("26211e"), Color("26211e"), Color("332c28"), Color("332c28"))
		U.oval(pts, cols, Vector2(w - 2.0, -15.0), 5.0, 14.0, Color("5a4430"), 10)
		U.oval(pts, cols, Vector2(w - 2.0, -15.0), 3.0, 9.0, Color(1.0, 0.45, 0.12, 0.6 + 0.3 * sin(_t * 3.0)), 8)
		var fade := clampf(1.0 - _life / 40.0, 0.25, 1.0)
		for i in 3:   # עשן
			var k := fmod(float(i) / 3.0 + _t * 0.15, 1.0)
			U.blob(pts, cols, Vector2(w * (0.25 + 0.25 * float(i)) + k * 20.0, -30.0 - k * 90.0), 10.0 + k * 24.0, 8.0 + k * 16.0, Color(0.34, 0.3, 0.28, 0.4 * (1.0 - k) * fade), 8)
		U.flush(self, pts, cols)


# ---- גדם מעלה עשן עם גחלים ----
class Stump extends Node2D:
	var seed_v := 0
	var _t := 0.0

	func _ready() -> void:
		z_index = -1
		_t = float(seed_v % 100)

	func _process(delta: float) -> void:
		_t += delta
		if Engine.get_process_frames() % 5 == 0 and Art.on_screen(self, global_position + Vector2(0, -40.0), 80.0):
			queue_redraw()

	func _draw() -> void:
		DrawBatch.begin(self)
		_draw_b()
		DrawBatch.end(self)

	func _draw_b() -> void:
		var pts := PackedVector2Array()
		var cols := PackedColorArray()
		U.quad(pts, cols, Vector2(-18, 0), Vector2(18, 0), Vector2(13, -30), Vector2(-15, -34), Color("171312"), Color("171312"), Color("2a2522"), Color("2a2522"))
		U.tri(pts, cols, Vector2(-18, 0), Vector2(-28, 0), Vector2(-12, -10), Color("171312"))
		U.tri(pts, cols, Vector2(18, 0), Vector2(30, 0), Vector2(12, -8), Color("171312"))
		var g := 0.6 + 0.4 * sin(_t * 2.6)
		U.oval(pts, cols, Vector2(-1, -32), 13.0, 4.0, Color(1.0, 0.42, 0.1, 0.85 * g), 10)
		U.oval(pts, cols, Vector2(-1, -32), 7.0, 2.0, Color(1.0, 0.8, 0.35, g), 8)
		U.blob(pts, cols, Vector2(0, -30), 34.0, 22.0, Color(1.0, 0.45, 0.12, 0.2 * g), 10)
		for i in 5:
			var k := fmod(float(i) / 5.0 + _t * 0.14, 1.0)
			U.blob(pts, cols, Vector2(k * 24.0 + sin(_t + float(i)) * 4.0, -40.0 - k * 140.0), 8.0 + k * 30.0, 6.0 + k * 20.0, Color(0.36, 0.32, 0.3, 0.45 * (1.0 - k)), 8)
		U.flush(self, pts, cols)


# ---- מכשולים (מוצק + מחסה) ----
class Obstacle extends Node2D:
	var kind := "logs"
	var size := Vector2(90, 50)
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
		var hh := size.y
		var r := RandomNumberGenerator.new()
		r.seed = seed_v
		var pts := PackedVector2Array()
		var cols := PackedColorArray()
		U.oval(pts, cols, Vector2(w * 0.5, 0.0), w * 0.6, 3.0, Color(0.05, 0.04, 0.03, 0.6), 12)
		match kind:
			"logs":   # ערימת בולים שרופים (3 למטה, 2 למעלה)
				var rows := [[3, 0.0], [2, 0.5]]
				var lr := hh / 4.0
				for ri in 2:
					var n: int = rows[ri][0]
					for q in n:
						var cx := w * 0.5 + (float(q) - float(n - 1) * 0.5) * lr * 2.1
						var cy := -lr - float(ri) * lr * 1.8
						U.quad(pts, cols, Vector2(4.0, cy - lr), Vector2(w - 4.0, cy - lr), Vector2(w - 4.0, cy + lr), Vector2(4.0, cy + lr), Color("1a1614"), Color("1a1614"), Color("221d1a"), Color("221d1a"))
						U.oval(pts, cols, Vector2(cx, cy), lr, lr, Color("5a4430"), 12)
						U.oval(pts, cols, Vector2(cx, cy), lr * 0.62, lr * 0.62, Color("7a5a3a"), 10)
						U.oval(pts, cols, Vector2(cx, cy), lr * 0.2, lr * 0.2, Color(1.0, 0.42, 0.12, 0.7) if r.randf() < 0.4 else Color("3a2a1e"), 6)
			"stump":   # גדם ענק עם שורשים
				U.quad(pts, cols, Vector2(8, 0), Vector2(w - 8, 0), Vector2(w - 16, -hh), Vector2(14, -hh + 4), Color("171312"), Color("171312"), Color("2a2420"), Color("2a2420"))
				U.tri(pts, cols, Vector2(8, 0), Vector2(-6, 0), Vector2(16, -hh * 0.4), Color("171312"))
				U.tri(pts, cols, Vector2(w - 8, 0), Vector2(w + 6, 0), Vector2(w - 16, -hh * 0.4), Color("171312"))
				U.oval(pts, cols, Vector2(w * 0.5, -hh + 2.0), w * 0.36, 4.0, Color("4a3828"), 12)
				U.oval(pts, cols, Vector2(w * 0.5, -hh + 2.0), w * 0.22, 2.4, Color(1.0, 0.45, 0.12, 0.6), 10)
			"boulder":   # סלע נודד עם שכבת אפר
				U.oval(pts, cols, Vector2(w * 0.5, -hh * 0.5), w * 0.5, hh * 0.5, Color("4e4a48"), 16)
				U.oval(pts, cols, Vector2(w * 0.45, -hh * 0.62), w * 0.38, hh * 0.32, Color("625e5a"), 14)
				U.oval(pts, cols, Vector2(w * 0.45, -hh * 0.9), w * 0.3, hh * 0.1, ASH_L, 12)
				for q in 4:
					U.quad(pts, cols, Vector2(w * 0.2 + float(q) * w * 0.15, -hh * 0.3), Vector2(w * 0.25 + float(q) * w * 0.15, -hh * 0.36), Vector2(w * 0.3 + float(q) * w * 0.15, -hh * 0.1), Vector2(w * 0.26 + float(q) * w * 0.15, -hh * 0.06), Color(0, 0, 0, 0.3), Color(0, 0, 0, 0.3), Color(0, 0, 0, 0.0), Color(0, 0, 0, 0.0))
			_:   # rootball: צלחת שורשים הפוכה של עץ שנפל
				U.oval(pts, cols, Vector2(w * 0.4, -hh * 0.55), w * 0.4, hh * 0.55, Color("2e2420"), 16)
				U.oval(pts, cols, Vector2(w * 0.42, -hh * 0.55), w * 0.3, hh * 0.4, Color("3e3028"), 14)
				for q in 10:
					var a := r.randf() * TAU
					var p := Vector2(w * 0.4, -hh * 0.55) + Vector2(cos(a) * w * 0.3, sin(a) * hh * 0.4)
					var e := p + Vector2(cos(a), sin(a)) * r.randf_range(10.0, 22.0)
					U.quad(pts, cols, p, e, e + Vector2(1.5, 0), p + Vector2(2.5, 0), Color("1e1814"), Color("1e1814"), Color("1e1814"), Color("1e1814"))
				U.quad(pts, cols, Vector2(w * 0.75, -hh * 0.75), Vector2(w, -hh * 0.62), Vector2(w, -hh * 0.3), Vector2(w * 0.75, -hh * 0.35), Color("171312"), Color("171312"), Color("2a2420"), Color("2a2420"))
		U.flush(self, pts, cols)


# ---- הטנדר השרוף של שומרי הפארק (הארגז = קומה נמוכה) ----
class BurntTruck extends Node2D:
	var w := 230.0
	var tier := 70.0

	func _ready() -> void:
		z_index = -1

	func _draw() -> void:
		DrawBatch.begin(self)
		_draw_b()
		DrawBatch.end(self)

	func _draw_b() -> void:
		var pts := PackedVector2Array()
		var cols := PackedColorArray()
		# גוף חלוד ושרוף
		U.quad(pts, cols, Vector2(0, -22), Vector2(w, -22), Vector2(w, -tier), Vector2(0, -tier), Color("3a2a22"), Color("4a3226"), Color("6a4030"), Color("5a3a2a"))
		U.quad(pts, cols, Vector2(w * 0.6, -tier), Vector2(w - 10.0, -tier), Vector2(w - 24.0, -tier - 46.0), Vector2(w * 0.62, -tier - 46.0), Color("4a3226"), Color("4a3226"), Color("5a3a2a"), Color("5a3a2a"))
		U.quad(pts, cols, Vector2(w * 0.66, -tier - 6.0), Vector2(w - 26.0, -tier - 6.0), Vector2(w - 34.0, -tier - 38.0), Vector2(w * 0.67, -tier - 38.0), Color("120e0c"), Color("120e0c"), Color("1e1816"), Color("1e1816"))
		U.rect(pts, cols, Rect2(4.0, -tier - 4.0, w * 0.56, 4.0), Color("2a1e18"))
		# פס ירוק-לבן של שומרי הפארק שעוד נשאר
		U.rect(pts, cols, Rect2(w * 0.1, -tier + 18.0, w * 0.8, 6.0), Color(0.3, 0.42, 0.28, 0.6))
		# גלגלים בלי צמיגים (רק חישוקים)
		for x in [w * 0.2, w * 0.8]:
			U.oval(pts, cols, Vector2(x, -14.0), 15.0, 15.0, Color("181412"), 14)
			U.oval(pts, cols, Vector2(x, -14.0), 9.0, 9.0, Color("5a4a40"), 12)
		for q in 6:   # חלודה
			U.oval(pts, cols, Vector2(w * (0.1 + 0.15 * float(q)), -tier * 0.55), 8.0, 5.0, Color(0.55, 0.25, 0.1, 0.5), 8)
		U.flush(self, pts, cols)


# ============================================================
#  זירת הבוס: המנסרה הבוערת (ASERRADERO LAPATAIA)
# ============================================================
class Sawmill extends Node2D:
	var w := 1000.0
	var deck_x := 220.0
	var deck_w := 180.0
	var deck_tier := 130.0
	var _t := 0.0

	func _ready() -> void:
		z_index = -3

	func _process(delta: float) -> void:
		_t += delta
		if Engine.get_process_frames() % 3 == 0 and Art.on_screen(self, global_position + Vector2(w * 0.5, -150.0), w * 0.6):
			queue_redraw()

	func _draw() -> void:
		DrawBatch.begin(self)
		_draw_b()
		DrawBatch.end(self)

	func _draw_b() -> void:
		var f := ThemeDB.fallback_font
		var pts := PackedVector2Array()
		var cols := PackedColorArray()
		# המבנה הגדול: שלד קורות שרוף, גג קרוס, אש בפנים
		var sx := 460.0
		var sw := 460.0
		U.rect(pts, cols, Rect2(sx, -250.0, sw, 250.0), Color("1e1816"))
		var fl := 0.7 + 0.3 * sin(_t * 9.0) * sin(_t * 4.3)
		U.quad(pts, cols, Vector2(sx + 20.0, 0.0), Vector2(sx + sw - 20.0, 0.0), Vector2(sx + sw - 30.0, -200.0), Vector2(sx + 30.0, -200.0), Color(1.0, 0.5, 0.16, 0.7 * fl), Color(1.0, 0.5, 0.16, 0.7 * fl), Color(0.6, 0.2, 0.06, 0.4), Color(0.6, 0.2, 0.06, 0.4))
		U.blob(pts, cols, Vector2(sx + sw * 0.5, -80.0), sw * 0.7, 160.0, Color(1.0, 0.5, 0.16, 0.3 * fl), 16)
		for q in 7:   # עמודים
			U.rect(pts, cols, Rect2(sx + float(q) * sw / 6.0 - 5.0, -250.0, 10.0, 250.0), Color("120e0c"))
		# גג משולש קרוס
		U.quad(pts, cols, Vector2(sx - 20.0, -250.0), Vector2(sx + sw * 0.4, -250.0), Vector2(sx + sw * 0.4, -330.0), Vector2(sx + sw * 0.2, -320.0), Color("2a2220"), Color("2a2220"), Color("3a302c"), Color("3a302c"))
		U.quad(pts, cols, Vector2(sx + sw * 0.62, -250.0), Vector2(sx + sw + 20.0, -250.0), Vector2(sx + sw * 0.86, -300.0), Vector2(sx + sw * 0.62, -270.0), Color("2a2220"), Color("2a2220"), Color("3a302c"), Color("3a302c"))
		for q in 5:   # קורות גג שבורות
			var x := sx + sw * (0.42 + 0.04 * float(q))
			U.quad(pts, cols, Vector2(x, -250.0), Vector2(x + 5.0, -250.0), Vector2(x + 14.0 - float(q) * 6.0, -300.0 + float(q) * 6.0), Vector2(x + 9.0 - float(q) * 6.0, -300.0 + float(q) * 6.0), Color("120e0c"), Color("120e0c"), Color("120e0c"), Color("120e0c"))
		# להבות מהגג
		for q in 10:
			var x := sx + sw * (0.38 + 0.03 * float(q))
			var hh := 30.0 + 26.0 * (0.5 + 0.5 * sin(_t * 6.0 + float(q) * 1.7))
			U.flame(pts, cols, Vector2(x, -252.0), 12.0, hh, sin(_t * 3.0 + float(q)) * 6.0, 0.95)
		for i in 7:   # עשן כבד
			var k := fmod(float(i) / 7.0 + _t * 0.06, 1.0)
			U.blob(pts, cols, Vector2(sx + sw * 0.5 - k * 160.0, -300.0 - k * 300.0), 60.0 + k * 120.0, 40.0 + k * 70.0, Color(0.16, 0.13, 0.12, 0.55 * (1.0 - k)), 12)
		# המסור העגול הענק (ניצב ליד הכניסה)
		var bc := Vector2(sx - 70.0, -90.0)
		U.oval(pts, cols, bc, 44.0, 44.0, Color("5a5856"), 24)
		U.oval(pts, cols, bc, 34.0, 34.0, Color("787470"), 20)
		U.oval(pts, cols, bc, 6.0, 6.0, Color("2a2826"), 10)
		for q in 18:
			var a := float(q) / 18.0 * TAU
			U.tri(pts, cols, bc + Vector2.from_angle(a) * 43.0, bc + Vector2.from_angle(a + 0.17) * 43.0, bc + Vector2.from_angle(a + 0.05) * 50.0, Color("4a4846"))
		U.rect(pts, cols, Rect2(bc.x - 50.0, -42.0, 100.0, 42.0), Color("3a2a20"))
		# ערימות בולים (מאחור)
		for pile in [[60.0, 4, 3], [880.0, 5, 3]]:
			var px: float = pile[0]
			var n: int = pile[1]
			for row in int(pile[2]):
				for q in n - row:
					var c := Vector2(px + (float(q) + float(row) * 0.5) * 30.0, -15.0 - float(row) * 26.0)
					U.oval(pts, cols, c, 15.0, 15.0, Color("4a3624"), 12)
					U.oval(pts, cols, c, 10.0, 10.0, Color("7a5a3a"), 10)
					U.oval(pts, cols, c, 3.0, 3.0, Color("3a2a1c"), 6)
		# במת בולים (הקומה)
		var dx := deck_x
		for q in 4:
			U.rect(pts, cols, Rect2(dx + float(q) * deck_w / 3.0 - 5.0, -deck_tier, 10.0, deck_tier), WOOD_D)
		U.rect(pts, cols, Rect2(dx - 8.0, -deck_tier - 6.0, deck_w + 16.0, 12.0), Color("4a3624"))
		for q in int(deck_w / 22.0) + 1:
			U.oval(pts, cols, Vector2(dx - 4.0 + float(q) * 22.0, -deck_tier), 6.0, 6.0, Color("7a5a3a"), 8)
		U.flush(self, pts, cols)
		DrawBatch.rect(self, Rect2(sx + 40.0, -236.0, 250.0, 34.0), Color("3a2a1e"))
		DrawBatch.rect(self, Rect2(sx + 40.0, -236.0, 250.0, 34.0), Color("8a6a4a"), false, 2.0)
		DrawBatch.string(self, f, Vector2(sx + 52.0, -213.0), "ASERRADERO LAPATAIA", HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color("e0c890"))


# ============================================================
#  ענן עשן סמיך על נקודה (סצנת הסיפור: ה-STRANGER נעלם בעשן)
# ============================================================
class SmokeVeil extends Node2D:
	var life := 5.0
	var r := 160.0
	var _t := 0.0

	func _ready() -> void:
		z_index = 9

	func _process(delta: float) -> void:
		_t += delta
		if _t >= life:
			queue_free()
			return
		queue_redraw()

	func _draw() -> void:
		DrawBatch.begin(self)
		_draw_b()
		DrawBatch.end(self)

	func _draw_b() -> void:
		var grow := clampf(_t / 0.9, 0.0, 1.0)
		var fade := clampf((life - _t) / 1.4, 0.0, 1.0)
		var pts := PackedVector2Array()
		var cols := PackedColorArray()
		for i in 14:
			var a := float(i) * 2.399 + _t * 0.3
			var d := r * 0.55 * sqrt(float(i) / 14.0) * grow
			var p := Vector2(cos(a) * d * 1.3, -60.0 + sin(a) * d * 0.7 - _t * 8.0 * float(i % 3))
			var c := Color(0.4, 0.36, 0.34, 0.5 * fade) if i % 3 != 0 else Color(0.25, 0.21, 0.2, 0.55 * fade)
			U.blob(pts, cols, p, r * (0.45 + 0.3 * U.h(i, 2)) * grow, r * (0.3 + 0.2 * U.h(i, 3)) * grow, c, 12)
		for i in 10:   # גצים בתוך העשן
			var k := fmod(float(i) * 0.31 + _t * 0.4, 1.0)
			U.dia(pts, cols, Vector2((U.h(i, 5) - 0.5) * r * 1.4, -20.0 - k * r * 1.2), 1.6, Color(1.0, 0.6, 0.25, (1.0 - k) * fade))
		U.flush(self, pts, cols)


# ============================================================
#  מסך: גצים עולים, פסי עשן (סמיכות לפי U.smoke), הבזק הירייה בעשן, משב ניצוצות
# ============================================================
class SmokeFX extends Node2D:
	var vp := Vector2(1280, 720)
	var gusts := 0                  # לבדיקות
	var _t := 0.0
	var _gust := -1.0

	func sparks() -> void:
		_gust = 0.0
		gusts += 1
		Sfx.play("s59_whoosh", null, -2.0)

	func _process(delta: float) -> void:
		_t += delta
		if _gust >= 0.0:
			_gust += delta
			if _gust > 2.4:
				_gust = -1.0
		if U.sparks_ms >= 0:
			U.sparks_ms = -1
			sparks()
		U.flash = maxf(0.0, U.flash - delta * 5.0)
		if Engine.get_process_frames() % 2 == 0:
			queue_redraw()

	func _draw() -> void:
		DrawBatch.begin(self)
		_draw_b()
		DrawBatch.end(self)

	func _draw_b() -> void:
		var g := 0.0 if _gust < 0.0 else sin(clampf(_gust / 2.4, 0.0, 1.0) * PI)
		var q := clampf(Quality.ambient(), 0.3, 1.0)
		var s := U.smoke
		var pts := PackedVector2Array()
		var cols := PackedColorArray()
		# פסי עשן שזזים לאורך המסך (סמיך = יותר ויותר כהה, ומשאיר "כיס" ברור סביב השחקן - U.pocket)
		if s > 0.02:
			var pc := U.pocket if U.pocket != Vector2.ZERO else Vector2(vp.x * 0.5, vp.y * 0.62)
			var nb := int(7.0 + 11.0 * s * q)
			for i in nb:
				var sp := 26.0 + U.h(i, 1) * 40.0
				var x := fposmod(U.h(i, 2) * vp.x * 2.0 - _t * sp, vp.x + 700.0) - 350.0
				var y := vp.y * (0.25 + 0.65 * U.h(i, 3)) + sin(_t * 0.4 + float(i)) * 20.0
				var away := clampf((Vector2(x, y).distance_to(pc) - 160.0) / 260.0, 0.0, 1.0)
				var a := (0.2 + 0.25 * U.h(i, 4)) * s * (0.2 + 0.8 * away)
				U.blob(pts, cols, Vector2(x, y), 260.0 + U.h(i, 5) * 200.0, 70.0 + U.h(i, 6) * 60.0, Color(0.3, 0.26, 0.24, a), 14)
			# קיר העשן: שקוף סביבך, סמיך מ-R_IN ומעבר (מה שרחוק נבלע)
			var sc := Color(0.2, 0.17, 0.16, 0.0)
			var sa := 0.72 * s
			var n := 28
			for i in n:
				var a0 := float(i) / float(n) * TAU
				var a1 := float(i + 1) / float(n) * TAU
				var d0 := Vector2(cos(a0), sin(a0) * 0.7)
				var d1 := Vector2(cos(a1), sin(a1) * 0.7)
				var r_in := 190.0
				var r_mid := 430.0
				var r_out := 1500.0
				U.quad(pts, cols, pc + d0 * r_in, pc + d1 * r_in, pc + d1 * r_mid, pc + d0 * r_mid, sc, sc, Color(sc, sa), Color(sc, sa))
				U.quad(pts, cols, pc + d0 * r_mid, pc + d1 * r_mid, pc + d1 * r_out, pc + d0 * r_out, Color(sc, sa), Color(sc, sa), Color(sc, sa * 1.18), Color(sc, sa * 1.18))
			# שוליים כהים (העשן "סוגר" על המסך)
			U.quad(pts, cols, Vector2(0, 0), Vector2(vp.x, 0), Vector2(vp.x, 160), Vector2(0, 160), Color(0.12, 0.1, 0.09, 0.4 * s), Color(0.12, 0.1, 0.09, 0.4 * s), Color(0.12, 0.1, 0.09, 0.0), Color(0.12, 0.1, 0.09, 0.0))
		# הבזק הירייה מאיר את העשן ("הם רואים את זה")
		if U.flash > 0.02 and s > 0.1:
			U.blob(pts, cols, U.flash_pos, 190.0, 140.0, Color(1.0, 0.72, 0.38, 0.3 * U.flash * s), 14)
		# גצים שעולים מלמטה
		for i in int((22.0 + 40.0 * g) * q):
			var sp := 50.0 + U.h(i, 7) * 70.0 + 160.0 * g
			var y := vp.y - fposmod(U.h(i, 8) * vp.y + _t * sp, vp.y + 40.0)
			var x := fposmod(U.h(i, 9) * vp.x + sin(_t * 1.3 + float(i)) * 30.0 - _t * (10.0 + 80.0 * g), vp.x)
			var a := (0.5 + 0.5 * sin(_t * 8.0 + float(i) * 2.3)) * (0.5 + 0.5 * U.h(i, 10))
			U.dia(pts, cols, Vector2(x, y), 1.2 + U.h(i, 11) * 1.4, Color(1.0, 0.58 + 0.25 * U.h(i, 12), 0.2, 0.85 * a))
		if g > 0.0:   # משב: גל ניצוצות ואור חם מלמטה
			U.quad(pts, cols, Vector2(0, vp.y - 200.0), Vector2(vp.x, vp.y - 200.0), Vector2(vp.x, vp.y), Vector2(0, vp.y), Color(1.0, 0.45, 0.12, 0.0), Color(1.0, 0.45, 0.12, 0.0), Color(1.0, 0.45, 0.12, 0.14 * g), Color(1.0, 0.45, 0.12, 0.14 * g))
		U.flush(self, pts, cols)
