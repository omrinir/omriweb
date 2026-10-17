extends RefCounted
# ============================================================
#  GUN ART - הציור של נשקי ההתקדמות (REVOLVER, DOUBLE BARREL, LEVER-ACTION, CROSSBOW, FLAMETHROWER,
#  LMG, DRAGON'S BREATH, ANTI-MATERIEL, MARKSMAN RIFLE, MINIGUN) - ביד ובגלגל/איסוף.
#  player.gd -> _draw_rifle קורא ל-draw_held() כשה-"style" של הנשק כאן (has_style),
#  weapon_wheel.gd -> draw_weapon קורא ל-draw_icon() לכל id שאין לו ציור משלו.
#  הקואורדינטות ביד: x לאורך הקנה (la), y = ניצב (n). כמו _draw_rifle: מחסנית ב-+y, כוונת ב- -y.
# ============================================================
const Art := preload("res://art.gd")
const WeaponDB := preload("res://weapons/weapon_db.gd")

const STYLES := ["revolver", "dbarrel", "lever", "crossbow", "flamer", "lmg", "hsniper", "dmr", "minigun", "dbreath", "rail"]
const METAL := Color("1d1d23")
const STEEL := Color("2c2c34")
const WOOD := Color("4b2d1c")
const WOOD_HI := Color("6e4428")


static func has_style(style: String) -> bool:
	return style in STYLES


# ---------------- ביד ----------------
# hand = מקום היד, la = כיוון הכוונה, t = זמן (לאנימציה), cool = כמה זמן עד הירייה הבאה (0 = מוכן)
# מחזיר את מקום הלוע (להבזק)
# spin = זווית הקנים של המיניגאן (player._spin_ang, -1 = לפי הזמן), spin_k = מהירות הסיבוב 0..1
static func draw_held(ci: CanvasItem, style: String, hand: Vector2, la: Vector2, t: float, mag_out: bool, cool: float, bl: float, spin := -1.0, spin_k := 0.0) -> Vector2:
	var n := la.rotated(PI / 2.0)
	var g := func(x: float, y: float) -> Vector2: return hand + la * x + n * y
	var poly := func(pts: Array, col: Color, w := 1.0) -> void:
		var arr := PackedVector2Array()
		for q in pts:
			arr.append(g.call(q.x, q.y))
		Art.fill(ci, arr, col, Art.OUTLINE, w)
	var bar := func(x0: float, x1: float, y: float, w: float, col: Color) -> void:
		Art.limb(ci, PackedVector2Array([g.call(x0, y), g.call(x1, y)]), w, col, Art.OUTLINE)
	var hi := Color(1, 1, 1, 0.14)
	match style:
		"revolver":   # אקדח תופי: ידית עץ, תוף, קנה ארוך
			poly.call([Vector2(-1.5, 1.0), Vector2(3.0, 1.0), Vector2(2.0, 7.5), Vector2(-2.5, 7.0)], WOOD, 0.9)
			poly.call([Vector2(-1.0, -2.2), Vector2(7.0, -2.2), Vector2(7.0, 1.6), Vector2(-1.0, 1.6)], METAL, 1.0)
			Art.disc(ci, g.call(4.0, -0.2), 2.6, Color("3a3a42"), Art.OUTLINE, 0.8)   # תוף
			bar.call(7.0, bl, -1.0, 2.2, STEEL)
			ci.draw_line(g.call(0.0, -1.6), g.call(bl - 1.0, -1.6), hi, 0.7, true)
			return g.call(bl + 1.0, -1.0)
		"dbarrel":   # דו-קני: קת עץ ארוכה, שני קנים זה על זה
			poly.call([Vector2(-12.0, -0.5), Vector2(-1.0, -1.8), Vector2(0.0, 2.4), Vector2(-11.0, 4.6)], WOOD, 1.0)
			poly.call([Vector2(-1.0, -2.2), Vector2(6.0, -2.2), Vector2(6.0, 2.4), Vector2(2.0, 2.4), Vector2(1.0, 5.5), Vector2(-1.5, 5.0)], METAL, 1.0)
			bar.call(6.0, bl, -1.4, 2.0, STEEL)
			bar.call(6.0, bl, 1.0, 2.0, STEEL)
			poly.call([Vector2(7.0, 1.8), Vector2(15.0, 1.8), Vector2(14.0, 3.8), Vector2(8.0, 3.8)], WOOD_HI, 0.8)
			return g.call(bl + 1.0, -0.2)
		"lever":   # רובה מנוף: עץ בהיר, לולאת מנוף מתחת, קנה ארוך עם צינור מחסנית
			poly.call([Vector2(-12.0, -0.5), Vector2(-2.0, -1.6), Vector2(-1.0, 2.2), Vector2(-11.0, 4.4)], WOOD_HI, 1.0)
			poly.call([Vector2(-2.0, -1.8), Vector2(9.0, -1.8), Vector2(9.0, 1.6), Vector2(-2.0, 1.6)], Color("6a5a3a"), 1.0)   # גוף פליז
			ci.draw_arc(g.call(1.5, 4.6), 3.0, 0.0, TAU, 12, METAL, 1.4, true)   # לולאת המנוף
			bar.call(9.0, bl, -0.6, 2.0, STEEL)
			bar.call(9.0, bl - 4.0, 1.4, 1.4, STEEL)   # צינור מחסנית
			poly.call([Vector2(10.0, 0.6), Vector2(18.0, 0.6), Vector2(18.0, 2.8), Vector2(10.0, 2.8)], WOOD_HI, 0.8)
			return g.call(bl + 1.0, -0.6)
		"crossbow":   # קשת מוצלבת: גוף עץ, זרועות, מיתר, חץ דרוך
			poly.call([Vector2(-10.0, -0.5), Vector2(14.0, -1.4), Vector2(14.0, 1.4), Vector2(-10.0, 3.5)], WOOD, 1.0)
			poly.call([Vector2(0.0, 1.2), Vector2(3.0, 1.2), Vector2(2.0, 7.0), Vector2(-1.0, 6.5)], METAL, 0.9)
			var tip_a: Vector2 = g.call(11.0, -8.5)   # (עבר "weapons": קשת קטנה ומעוקלת יותר - הייתה "מסגרת" גדולה)
			var tip_b: Vector2 = g.call(11.0, 8.5)
			Art.limb(ci, PackedVector2Array([tip_a, g.call(14.5, -4.5), g.call(15.5, 0.0), g.call(14.5, 4.5), tip_b]), 1.7, Color("3a3a40"), Art.OUTLINE)
			ci.draw_arc(g.call(17.0, 0.0), 1.8, -PI / 2.0, PI / 2.0, 6, METAL, 1.0, true)   # רכוב (סטירופ) בקדמת הקשת
			poly.call([Vector2(2.0, -1.6), Vector2(8.0, -1.6), Vector2(8.0, -3.6), Vector2(2.0, -3.6)], Color("16161a"), 0.8)   # כוונת קטנה
			var pull := 4.0 if cool <= 0.0 else -1.0
			ci.draw_polyline(PackedVector2Array([tip_a, g.call(pull + 2.0, 0.0), tip_b]), Color(0.9, 0.88, 0.8, 0.85), 0.8, true)
			if cool <= 0.0:   # חץ דרוך
				ci.draw_line(g.call(pull + 2.0, 0.0), g.call(22.0, 0.0), Color("8a6a40"), 1.4, true)
				ci.draw_colored_polygon(PackedVector2Array([g.call(22.0, -1.8), g.call(26.0, 0.0), g.call(22.0, 1.8)]), Color("b8b8c0"))
			return g.call(16.0, 0.0)
		"flamer":   # להביור: מכל דלק אדום, צינור, קנה עם להבת טייס
			Art.disc(ci, g.call(-6.0, 5.0), 4.6, Color("a02a1a"), Art.OUTLINE, 1.0)   # מכל
			ci.draw_arc(g.call(-6.0, 5.0), 3.0, -2.4, -1.0, 6, Color(1, 0.6, 0.5, 0.4), 1.0, true)
			poly.call([Vector2(-4.0, -2.4), Vector2(12.0, -2.4), Vector2(12.0, 2.4), Vector2(-4.0, 2.4)], Color("3a3a40"), 1.0)
			poly.call([Vector2(1.0, 2.0), Vector2(4.0, 2.0), Vector2(3.0, 7.0), Vector2(0.0, 6.5)], METAL, 0.9)
			bar.call(12.0, bl, -0.4, 2.6, STEEL)
			Art.limb(ci, PackedVector2Array([g.call(-6.0, 1.0), g.call(-2.0, -3.5), g.call(6.0, -4.0)]), 1.2, Color("1a1a1a"), Art.NONE)   # צינור
			Art.glow(ci, g.call(bl + 1.5, 1.5), 3.5 + 0.8 * sin(t * 30.0), Color(0.4, 0.6, 1.0, 0.85))   # להבת טייס כחולה
			return g.call(bl + 2.0, -0.4)
		"lmg":   # מקלע: גוף עבה, קופסת תחמושת, דו-רגל, ידית
			poly.call([Vector2(-12.0, -1.0), Vector2(-2.0, -2.4), Vector2(-1.0, 2.4), Vector2(-12.0, 4.4)], Color("2a2c26"), 1.0)
			poly.call([Vector2(-2.0, -3.0), Vector2(14.0, -3.0), Vector2(14.0, 2.6), Vector2(-2.0, 2.6)], METAL, 1.0)
			bar.call(14.0, bl, -0.6, 2.6, STEEL)
			if not mag_out:
				poly.call([Vector2(2.0, 2.4), Vector2(10.0, 2.4), Vector2(10.0, 9.5), Vector2(2.0, 9.5)], Color("3a4a2a"), 0.9)   # קופסת תחמושת
			ci.draw_line(g.call(bl - 6.0, 0.0), g.call(bl - 9.0, 8.0), STEEL, 1.2, true)   # דו-רגל מקופל
			ci.draw_line(g.call(bl - 6.0, 0.0), g.call(bl - 3.0, 8.0), STEEL, 1.2, true)
			ci.draw_line(g.call(0.0, -2.2), g.call(13.0, -2.2), hi, 0.8, true)
			return g.call(bl + 1.0, -0.6)
		"hsniper":   # רובה אנטי-חומרי: קת עבה, כוונת גדולה, בולם לוע
			poly.call([Vector2(-14.0, -1.0), Vector2(-2.0, -2.4), Vector2(-1.0, 2.6), Vector2(-9.0, 2.6), Vector2(-12.0, 6.0)], Color("2a2e26"), 1.0)
			poly.call([Vector2(-2.0, -2.6), Vector2(14.0, -2.6), Vector2(14.0, 2.4), Vector2(-2.0, 2.4)], METAL, 1.0)
			bar.call(14.0, bl, -0.4, 2.6, STEEL)
			poly.call([Vector2(bl - 3.0, -2.6), Vector2(bl + 1.0, -2.6), Vector2(bl + 1.0, 1.8), Vector2(bl - 3.0, 1.8)], Color("101014"), 0.9)   # בולם לוע
			poly.call([Vector2(-1.0, -4.0), Vector2(13.0, -4.0), Vector2(13.0, -8.0), Vector2(-1.0, -8.0)], Color("16161a"), 0.9)   # כוונת
			ci.draw_circle(g.call(13.4, -6.0), 1.6, Color(0.5, 0.8, 1.0, 0.85))
			if not mag_out:
				poly.call([Vector2(3.0, 2.2), Vector2(8.0, 2.2), Vector2(8.0, 7.0), Vector2(3.0, 7.0)], Color("18181c"), 0.9)
			return g.call(bl + 2.0, -0.4)
		"dmr":   # רובה צלפים חצי-אוטומטי: גוף רובה סער, כוונת קצרה, מחסנית ישרה
			poly.call([Vector2(-12.0, -0.6), Vector2(-2.0, -1.8), Vector2(-1.0, 2.4), Vector2(-11.0, 4.4)], Color("3a3a32"), 1.0)
			poly.call([Vector2(-2.0, -2.0), Vector2(15.0, -2.0), Vector2(15.0, 1.8), Vector2(-2.0, 1.8)], METAL, 1.0)
			bar.call(15.0, bl, -0.4, 2.0, STEEL)
			poly.call([Vector2(1.0, -3.0), Vector2(10.0, -3.0), Vector2(10.0, -6.0), Vector2(1.0, -6.0)], Color("16161a"), 0.9)
			ci.draw_circle(g.call(10.3, -4.5), 1.1, Color(0.9, 0.85, 0.5, 0.8))
			if not mag_out:
				poly.call([Vector2(5.0, 1.6), Vector2(9.0, 1.6), Vector2(9.0, 8.0), Vector2(5.0, 8.0)], Color("18181c"), 0.9)
			return g.call(bl + 1.0, -0.4)
		"minigun":   # מיניגאן: 6 קנים מסתובבים (עומק: האחוריים כהים), מנוע, ידית עליונה, תוף תחמושת
			if not mag_out:   # קופסת תחמושת + חגורת כדורים לנשק
				poly.call([Vector2(-9.0, 3.0), Vector2(0.0, 3.0), Vector2(0.0, 11.0), Vector2(-9.0, 11.0)], Color("3a4a2a"), 0.9)
				for b in 4:
					ci.draw_line(g.call(-6.5 + float(b) * 2.0, 3.4), g.call(-5.0 + float(b) * 2.6, 0.6), Color("c8a040"), 1.1, true)
			poly.call([Vector2(-7.0, -4.2), Vector2(7.0, -4.2), Vector2(8.0, -2.6), Vector2(8.0, 3.6), Vector2(-7.0, 4.2)], Color("3a3a42"), 1.0)   # מנוע
			ci.draw_line(g.call(-6.0, -3.2), g.call(7.0, -3.2), hi, 0.9, true)
			for r in 3:   # צלעות קירור
				ci.draw_line(g.call(-4.0 + float(r) * 3.0, -2.6), g.call(-4.0 + float(r) * 3.0, 2.6), Color(0, 0, 0, 0.35), 0.8, true)
			poly.call([Vector2(-1.0, 3.6), Vector2(3.0, 3.6), Vector2(2.0, 8.5), Vector2(-2.0, 8.0)], METAL, 0.9)
			ci.draw_arc(g.call(0.0, -6.0), 3.2, PI, TAU, 10, METAL, 1.6, true)   # ידית נשיאה
			var ang := spin if spin >= 0.0 else t * (40.0 if cool > 0.0 else 3.0)
			var order := []   # קודם האחוריים
			for k in 6:
				var a := ang + float(k) * TAU / 6.0
				order.append([cos(a), sin(a) * 2.7])
			order.sort_custom(func(p, q): return p[0] < q[0])
			poly.call([Vector2(8.0, -3.6), Vector2(bl - 2.0, -3.4), Vector2(bl - 2.0, 3.4), Vector2(8.0, 3.6)], Color("1a1a1f"), 0.6)   # צל בין הקנים
			for o in order:
				var lit: float = 0.5 + 0.5 * float(o[0])
				bar.call(8.0, bl, float(o[1]), 1.3, STEEL.lerp(Color("8a8a96"), lit * 0.75))
			if spin_k > 0.55:   # מהר מאוד: טשטוש תנועה
				var bw := Color(0.75, 0.75, 0.8, 0.22 * (spin_k - 0.55) / 0.45)
				ci.draw_colored_polygon(PackedVector2Array([g.call(9.0, -3.2), g.call(bl - 1.0, -3.2), g.call(bl - 1.0, 3.2), g.call(9.0, 3.2)]), bw)
			for cx in [10.0, bl - 2.0]:   # טבעות מהדק
				poly.call([Vector2(cx - 1.2, -3.8), Vector2(cx + 1.2, -3.8), Vector2(cx + 1.2, 3.8), Vector2(cx - 1.2, 3.8)], METAL, 0.8)
			if spin_k > 0.85:   # קנים מתחממים בירי ארוך
				Art.glow(ci, g.call(bl - 3.0, 0.0), 4.0, Color(1.0, 0.45, 0.15, 0.25 * (spin_k - 0.85) / 0.15))
			return g.call(bl + 1.0, 0.0)
		"dbreath":   # DRAGON'S BREATH: שוטגאן משאבה עם קנה מושחר-אדום ומשאבה כתומה
			poly.call([Vector2(-11.0, -0.5), Vector2(-2.0, -1.6), Vector2(-1.0, 2.2), Vector2(-11.0, 4.2)], Color("3a1c14"), 1.0)
			poly.call([Vector2(-2.0, -1.8), Vector2(14.0, -1.8), Vector2(14.0, 1.8), Vector2(4.0, 1.8), Vector2(2.6, 6.4), Vector2(-0.6, 6.4), Vector2(-1.0, 2.2)], METAL, 1.0)
			bar.call(14.0, bl, -0.4, 3.4, Color("3a2622"))
			poly.call([Vector2(15.0, 1.2), Vector2(21.0, 1.2), Vector2(21.0, 3.8), Vector2(15.0, 3.8)], Color("c0501a"), 0.9)
			Art.glow(ci, g.call(bl + 0.5, -0.4), 3.0, Color(1.0, 0.45, 0.1, 0.5 + 0.2 * sin(t * 8.0)))   # לוע לוחש
			return g.call(bl + 1.0, -0.4)
		"rail":   # RAILGUN: גוף לבן-אפור חלק, סלילים כחולים זוהרים לאורך הקנה הכפול
			poly.call([Vector2(-12.0, -1.0), Vector2(-2.0, -2.4), Vector2(-1.0, 2.4), Vector2(-11.0, 4.4)], Color("4a5058"), 1.0)
			poly.call([Vector2(-2.0, -3.0), Vector2(12.0, -3.0), Vector2(12.0, 2.6), Vector2(-2.0, 2.6)], Color("c8ccd4"), 1.0)
			bar.call(12.0, bl, -2.0, 1.6, Color("6a7078"))
			bar.call(12.0, bl, 1.4, 1.6, Color("6a7078"))
			var glow := 0.55 + 0.45 * clampf(1.0 - cool, 0.0, 1.0)   # נטען מחדש אחרי ירייה
			for k in 4:
				ci.draw_circle(g.call(15.0 + float(k) * 5.5, -0.3), 1.7, Color(0.4, 0.85, 1.0, glow * (0.6 + 0.4 * sin(t * 12.0 + float(k)))))
			poly.call([Vector2(2.0, 2.4), Vector2(5.0, 2.4), Vector2(4.0, 7.5), Vector2(1.0, 7.0)], METAL, 0.9)
			ci.draw_line(g.call(0.0, -2.4), g.call(11.0, -2.4), Color(1, 1, 1, 0.35), 0.8, true)
			return g.call(bl + 1.0, -0.3)
	return hand


# ---------------- בגלגל / על הקרקע ----------------
# אותו מבנה כמו weapon_wheel.gd -> draw_weapon (p = מרכז, s = גודל)
static func draw_icon(ci: CanvasItem, p: Vector2, id: int, s: float, alpha := 1.0) -> bool:
	var style := str(WeaponDB.val(id, "style", ""))
	if not has_style(style):
		return false
	var metal := Color(0.16, 0.16, 0.19, alpha)
	var steel := Color(0.36, 0.37, 0.41, alpha)
	var hi := Color(0.75, 0.77, 0.82, 0.55 * alpha)
	var wood := Color(0.42, 0.25, 0.13, alpha)
	var wood_hi := Color(0.62, 0.4, 0.22, alpha)
	var poly := func(pts: Array, col: Color) -> void:
		var arr := PackedVector2Array()
		for q in pts:
			arr.append(p + q * s)
		ci.draw_colored_polygon(arr, col)
		arr.append(arr[0])
		ci.draw_polyline(arr, Color(0, 0, 0, 0.7 * alpha), 1.0, true)
	var ln := func(a: Vector2, b: Vector2, col: Color, w: float) -> void:
		ci.draw_line(p + a * s, p + b * s, col, maxf(w * s, 1.0), true)
	match style:
		"revolver":
			poly.call([Vector2(-14, 0), Vector2(-4, 0), Vector2(-8, 14), Vector2(-17, 12)], wood)
			poly.call([Vector2(-14, -7), Vector2(2, -7), Vector2(2, 2), Vector2(-14, 2)], metal)
			ci.draw_circle(p + Vector2(-5, -2.5) * s, 5.5 * s, Color(0.3, 0.3, 0.34, alpha))
			for k in 3:
				ln.call(Vector2(-9, -4 + k * 2.5), Vector2(-1, -4 + k * 2.5), Color(0, 0, 0, 0.35 * alpha), 0.7)
			ln.call(Vector2(2, -4.5), Vector2(26, -4.5), steel, 3.0)
			ln.call(Vector2(24, -6.5), Vector2(24, -8.5), steel, 1.4)
			ln.call(Vector2(-4, 2), Vector2(-1, 6), metal, 1.4)
			ln.call(Vector2(-12, -6), Vector2(24, -5.8), hi, 0.8)
		"dbarrel":
			poly.call([Vector2(-34, -1), Vector2(-12, -4), Vector2(-12, 3), Vector2(-32, 9)], wood)
			poly.call([Vector2(-12, -6), Vector2(2, -6), Vector2(2, 4), Vector2(-12, 4)], metal)
			ln.call(Vector2(2, -3.5), Vector2(34, -3.5), steel, 3.4)
			ln.call(Vector2(2, 1.0), Vector2(34, 1.0), steel, 3.4)
			poly.call([Vector2(4, 2.5), Vector2(18, 2.5), Vector2(18, 6), Vector2(4, 6)], wood_hi)
			poly.call([Vector2(-9, 4), Vector2(-5, 4), Vector2(-7, 9), Vector2(-11, 8)], metal)
			ln.call(Vector2(2, -5), Vector2(33, -5), hi, 0.8)
		"lever":
			poly.call([Vector2(-34, -1), Vector2(-14, -3), Vector2(-14, 3), Vector2(-32, 8)], wood_hi)
			poly.call([Vector2(-14, -5), Vector2(4, -5), Vector2(4, 2), Vector2(-14, 2)], Color(0.55, 0.45, 0.25, alpha))
			ci.draw_arc(p + Vector2(-8, 7) * s, 5.0 * s, 0.0, TAU, 14, metal, maxf(1.8 * s, 1.0), true)
			ln.call(Vector2(4, -3), Vector2(38, -3), steel, 2.4)
			ln.call(Vector2(4, 0.5), Vector2(30, 0.5), metal, 1.8)
			poly.call([Vector2(6, -1), Vector2(20, -1), Vector2(20, 3), Vector2(6, 3)], wood_hi)
			ln.call(Vector2(-12, -4), Vector2(36, -4), hi, 0.8)
		"crossbow":
			poly.call([Vector2(-30, -1), Vector2(14, -3), Vector2(14, 2), Vector2(-30, 5)], wood)
			poly.call([Vector2(-8, 2), Vector2(-3, 2), Vector2(-5, 11), Vector2(-10, 10)], metal)
			var a := p + Vector2(8, -18) * s
			var b := p + Vector2(8, 18) * s
			ci.draw_polyline(PackedVector2Array([a, p + Vector2(15, -6) * s, p + Vector2(15, 6) * s, b]), Color(0.22, 0.22, 0.26, alpha), maxf(2.6 * s, 1.0), true)
			ci.draw_polyline(PackedVector2Array([a, p + Vector2(-4, 0) * s, b]), Color(0.9, 0.88, 0.8, 0.8 * alpha), maxf(0.8 * s, 1.0), true)
			ln.call(Vector2(-4, 0), Vector2(26, 0), Color(0.55, 0.42, 0.26, alpha), 1.6)
			poly.call([Vector2(26, -2.5), Vector2(32, 0), Vector2(26, 2.5)], steel)
		"flamer":
			ci.draw_circle(p + Vector2(-14, 6) * s, 8.0 * s, Color(0.62, 0.16, 0.1, alpha))
			ci.draw_arc(p + Vector2(-14, 6) * s, 5.5 * s, -2.4, -1.0, 8, Color(1, 0.7, 0.6, 0.45 * alpha), maxf(1.2 * s, 1.0), true)
			poly.call([Vector2(-8, -5), Vector2(14, -5), Vector2(14, 3), Vector2(-8, 3)], Color(0.23, 0.23, 0.26, alpha))
			poly.call([Vector2(-1, 3), Vector2(4, 3), Vector2(2, 11), Vector2(-3, 10)], metal)
			ln.call(Vector2(14, -1), Vector2(34, -1), steel, 3.4)
			ln.call(Vector2(-14, -2), Vector2(-4, -7), Color(0.1, 0.1, 0.1, alpha), 1.4)
			ci.draw_circle(p + Vector2(36, 1) * s, 2.4 * s, Color(0.4, 0.6, 1.0, 0.9 * alpha))
			ci.draw_circle(p + Vector2(38, -1) * s, 3.2 * s, Color(1.0, 0.55, 0.15, 0.6 * alpha))
		"lmg":
			poly.call([Vector2(-34, -2), Vector2(-14, -4), Vector2(-14, 4), Vector2(-33, 8)], Color(0.2, 0.22, 0.18, alpha))
			poly.call([Vector2(-14, -6), Vector2(12, -6), Vector2(12, 3), Vector2(-14, 3)], metal)
			ln.call(Vector2(12, -2), Vector2(40, -2), steel, 3.0)
			poly.call([Vector2(-6, 3), Vector2(8, 3), Vector2(8, 15), Vector2(-6, 15)], Color(0.24, 0.3, 0.18, alpha))   # קופסת תחמושת
			ln.call(Vector2(-6, 8), Vector2(8, 8), Color(0, 0, 0, 0.35 * alpha), 0.8)
			ln.call(Vector2(30, 0), Vector2(26, 11), steel, 1.3)
			ln.call(Vector2(30, 0), Vector2(34, 11), steel, 1.3)
			ci.draw_arc(p + Vector2(-2, -7) * s, 4.0 * s, PI, TAU, 8, metal, maxf(1.6 * s, 1.0), true)
			ln.call(Vector2(-12, -5), Vector2(10, -5), hi, 0.8)
		"hsniper":
			poly.call([Vector2(-38, -2), Vector2(-14, -4), Vector2(-14, 4), Vector2(-22, 4), Vector2(-26, 10), Vector2(-37, 9)], Color(0.2, 0.23, 0.18, alpha))
			poly.call([Vector2(-14, -5), Vector2(8, -5), Vector2(8, 3), Vector2(-14, 4)], metal)
			ln.call(Vector2(8, -2), Vector2(42, -2), steel, 3.0)
			poly.call([Vector2(40, -5), Vector2(46, -5), Vector2(46, 2), Vector2(40, 2)], metal)   # בולם לוע
			poly.call([Vector2(-12, -13), Vector2(8, -13), Vector2(10, -10), Vector2(10, -7), Vector2(-14, -7), Vector2(-14, -10)], metal)
			ci.draw_circle(p + Vector2(10.5, -10) * s, 2.6 * s, Color(0.45, 0.8, 1.0, 0.9 * alpha))
			poly.call([Vector2(-6, 3), Vector2(0, 3), Vector2(0, 10), Vector2(-6, 10)], metal)
			ln.call(Vector2(22, 0), Vector2(17, 10), steel, 1.4)
			ln.call(Vector2(22, 0), Vector2(27, 10), steel, 1.4)
		"dmr":
			poly.call([Vector2(-34, -2), Vector2(-14, -4), Vector2(-14, 3), Vector2(-33, 7)], Color(0.26, 0.26, 0.22, alpha))
			poly.call([Vector2(-14, -5), Vector2(14, -5), Vector2(14, 2), Vector2(-14, 3)], metal)
			ln.call(Vector2(14, -2), Vector2(40, -2), steel, 2.2)
			poly.call([Vector2(-8, -11), Vector2(8, -11), Vector2(8, -6), Vector2(-8, -6)], metal)
			ci.draw_circle(p + Vector2(8.5, -8.5) * s, 1.8 * s, Color(0.95, 0.85, 0.45, 0.9 * alpha))
			poly.call([Vector2(0, 2), Vector2(5, 2), Vector2(6, 13), Vector2(1, 13)], metal)
			poly.call([Vector2(-10, 2), Vector2(-6, 2), Vector2(-8, 9), Vector2(-12, 8)], metal)
			ln.call(Vector2(-12, -4), Vector2(12, -4), hi, 0.8)
		"minigun":
			poly.call([Vector2(-22, -7), Vector2(2, -7), Vector2(2, 7), Vector2(-22, 7)], Color(0.24, 0.24, 0.28, alpha))
			for k in 3:
				ln.call(Vector2(2, -4 + k * 4), Vector2(38, -4 + k * 4), steel.lightened(0.08 * float(k)), 2.2)
			poly.call([Vector2(32, -7), Vector2(35, -7), Vector2(35, 7), Vector2(32, 7)], metal)
			poly.call([Vector2(12, -7), Vector2(15, -7), Vector2(15, 7), Vector2(12, 7)], metal)
			ci.draw_arc(p + Vector2(-10, -8) * s, 6.0 * s, PI, TAU, 10, metal, maxf(2.0 * s, 1.0), true)
			poly.call([Vector2(-16, 7), Vector2(-10, 7), Vector2(-12, 15), Vector2(-18, 14)], metal)
			ln.call(Vector2(-20, -6), Vector2(0, -6), hi, 0.8)
		"dbreath":
			poly.call([Vector2(-32, -1), Vector2(-12, -4), Vector2(-12, 3), Vector2(-30, 9)], Color(0.24, 0.12, 0.08, alpha))
			poly.call([Vector2(-12, -5), Vector2(4, -5), Vector2(4, 3), Vector2(-12, 3)], metal)
			ln.call(Vector2(4, -3), Vector2(34, -3), Color(0.3, 0.2, 0.18, alpha), 3.6)
			ln.call(Vector2(4, 1.5), Vector2(28, 1.5), metal, 3.0)
			poly.call([Vector2(10, -1), Vector2(22, -1), Vector2(22, 5), Vector2(10, 5)], Color(0.78, 0.32, 0.1, alpha))
			for k in 3:
				ln.call(Vector2(12 + k * 4, -1), Vector2(12 + k * 4, 5), Color(0, 0, 0, 0.4 * alpha), 0.8)
			poly.call([Vector2(-9, 3), Vector2(-5, 3), Vector2(-7, 9), Vector2(-11, 8)], metal)
			ci.draw_circle(p + Vector2(36, -3) * s, 3.0 * s, Color(1.0, 0.45, 0.1, 0.55 * alpha))
		"rail":
			poly.call([Vector2(-34, -2), Vector2(-14, -4), Vector2(-14, 4), Vector2(-33, 8)], Color(0.29, 0.31, 0.35, alpha))
			poly.call([Vector2(-14, -6), Vector2(8, -6), Vector2(8, 4), Vector2(-14, 4)], Color(0.78, 0.8, 0.84, alpha))
			ln.call(Vector2(8, -4), Vector2(40, -4), Color(0.42, 0.44, 0.48, alpha), 2.2)
			ln.call(Vector2(8, 2), Vector2(40, 2), Color(0.42, 0.44, 0.48, alpha), 2.2)
			for k in 5:
				ci.draw_circle(p + Vector2(12 + k * 6, -1) * s, 2.2 * s, Color(0.4, 0.85, 1.0, 0.9 * alpha))
			poly.call([Vector2(-8, 4), Vector2(-3, 4), Vector2(-5, 12), Vector2(-10, 11)], metal)
			ln.call(Vector2(-12, -5), Vector2(6, -5), hi, 0.8)
	return true
