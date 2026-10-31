extends RefCounted
const DrawBatch := preload("res://effects/draw_batch.gd")   # כל הציור של זומבי ב-draw call אחד
# ============================================================
#  FLAME FX - ציור אש משותף (שטח בוער, אש קטנה על חפצים / זומבים בוערים, בקבוקי תבערה, להבות על זומבים).
#  * tongue()  - לשון אש בצורת טיפה: צד שמאל/ימין מעוגלים, הקצה מתנדנד, 3-4 שכבות צבע (אדום -> כתום -> צהוב -> לבן-חם בבסיס).
#  * puff()    - פיסת אש קטנה שניתקת מהלשון ועולה למעלה (נראית כמו אש אמיתית שמהבהבת).
#  * glow()    - הילת אור רכה (טקסטורה רדיאלית, בלי קצה חד - לא "בועה").
#  * soft()    - טקסטורה רכה (עשן / הילה).
#  צבעים: PALETTE (כתום) / BLUE (אש כחולה של SUPAY / גופרית).
#  לשנות: PALETTE, BLUE, צורת הלשון ב-tongue().
# ============================================================

const PALETTE := [Color(0.62, 0.08, 0.02), Color(0.95, 0.32, 0.04), Color(1.0, 0.62, 0.12), Color(1.0, 0.9, 0.55)]
const BLUE := [Color(0.08, 0.14, 0.62), Color(0.18, 0.42, 1.0), Color(0.45, 0.75, 1.0), Color(0.85, 0.95, 1.0)]

static var _soft: Texture2D = null
static var _add: CanvasItemMaterial = null


# טקסטורה רדיאלית רכה (לבן במרכז -> שקוף בקצה)
static func soft() -> Texture2D:
	if _soft == null:
		var g := Gradient.new()
		g.set_color(0, Color(1, 1, 1, 1))
		g.set_color(1, Color(1, 1, 1, 0))
		g.add_point(0.35, Color(1, 1, 1, 0.55))
		var t := GradientTexture2D.new()
		t.gradient = g
		t.fill = GradientTexture2D.FILL_RADIAL
		t.fill_from = Vector2(0.5, 0.5)
		t.fill_to = Vector2(1.0, 0.5)
		t.width = 64
		t.height = 64
		_soft = t
	return _soft


# חומר "הוספה" (אור): לילדים שמציירים הילה / ליבה בוהקת
static func additive() -> CanvasItemMaterial:
	if _add == null:
		_add = CanvasItemMaterial.new()
		_add.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	return _add


static func glow(ci: CanvasItem, c: Vector2, r: Vector2, col: Color) -> void:
	DrawBatch.texture_rect(ci, soft(), Rect2(c - r, r * 2.0), false, col)


# רעש חלק (סכום סינוסים) בטווח 0..1
static func wobble(t: float, ph: float) -> float:
	return 0.5 + 0.28 * sin(t * 7.3 + ph) + 0.14 * sin(t * 13.1 + ph * 2.3) + 0.08 * sin(t * 23.7 + ph * 0.7)


# לשון אש אחת. base = נקודת הבסיס, w = חצי רוחב בבסיס, h = גובה, sway = כמה הקצה זז הצידה, a = שקיפות
static func tongue(ci: CanvasItem, base: Vector2, w: float, h: float, sway: float, pal: Array, a := 1.0, core := true) -> void:
	if h < 1.5 or w < 0.5:
		return
	var layers := 4 if core else 3
	for L in layers:
		var k: float = [1.0, 0.78, 0.55, 0.3][L]
		var col: Color = pal[L]
		col.a *= a * ([0.92, 0.95, 0.95, 0.9][L])
		var lh := h * (k if L < 3 else 0.42)
		var lw := w * k
		var pts := PackedVector2Array()
		var n := 6
		for i in n + 1:   # צד שמאל, מלמטה למעלה
			var s := float(i) / float(n)
			var bulge := sin(minf(s * 1.6 + 0.35, PI)) * pow(1.0 - s, 0.55)
			pts.append(base + Vector2(-lw * bulge + sway * s * s, -lh * s))
		for i in range(n - 1, -1, -1):   # צד ימין, מלמעלה למטה
			var s := float(i) / float(n)
			var bulge := sin(minf(s * 1.6 + 0.35, PI)) * pow(1.0 - s, 0.55)
			pts.append(base + Vector2(lw * bulge + sway * s * s, -lh * s))
		DrawBatch.colored_polygon(ci, pts, col)


# פיסת אש קטנה שעולה (k = 0..1 לאורך החיים שלה)
static func puff(ci: CanvasItem, p: Vector2, size: float, k: float, pal: Array, a := 1.0) -> void:
	var s := size * (1.0 - k)
	if s < 0.6:
		return
	var c: Color = pal[1].lerp(pal[0], k)
	c.a = a * (1.0 - k * k)
	DrawBatch.colored_polygon(ci, PackedVector2Array([p + Vector2(-s * 0.6, 0), p + Vector2(-s * 0.4, -s * 0.9), p + Vector2(0, -s * 1.7),
		p + Vector2(s * 0.4, -s * 0.9), p + Vector2(s * 0.6, 0), p + Vector2(0, s * 0.45)]), c)
