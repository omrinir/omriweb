extends RefCounted
const DrawBatch := preload("res://effects/draw_batch.gd")   # כל הציור של זומבי ב-draw call אחד
# ============================================================
#  קישוטים לשלב 46 ("WINE VALLEY") - מנדוסה, ארגנטינה, בזמן הבציר בשקיעה. אזור שישי (החרוט הדרומי), שלב 1.
#  כרמים בשורות מתחת להרי האנדים המושלגים ולאקונקגואה, יקבים (בודגות) מאדובי עם גגות רעפים, שדרות צפצפות.
#    valley_sky   - (רקע) שקיעה: כחול עמוק -> סגול -> ורוד-כתום, שמש נמוכה, עננים זזים, קונדורים
#    far_andes    - (רקע, 0.06) רכס האנדים המושלג + האקונקגואה עם זוהר ורוד על השלג, ערפל שזז על הפסגות
#    mid_bodegas  - (רקע, 0.28) גבעות, שדרות צפצפות שמתנדנדות ברוח, יקבים עם חלונות מהבהבים ועשן מארובות, מגדל אבן
#    near_vines   - (רקע, 0.6) שורות גפנים (עמודים, חוטים, עלי סתיו, אשכולות סגולים) שמתנדנדות
#    VineyardGround - (עולם) דרך עפר עם עקבות טרקטור וענבים מעוכים
#    Pergola      - (עולם) פרגולת גפן ("פרל") - הקומה העליונה (add_floor) עם אשכולות תלויים
#    BarrelStack  - (עולם, מלכודת) ערימת חביות על רמפה ליד היקב: כשאתה מתקרב משחררת חבית מתגלגלת (RollingBarrel) לכיוונך.
#                   לקפוץ. חבית מתגלגלת פוגעת גם בזומבים. ירייה בטריז (גוף קטן) משחררת מיד - על זומבים!
#    FermentVat   - (עולם, מלכודת) מיכל תסיסה: כל CYCLE פולט ענן CO2 (WARN_T שריקה) - מי שבתוכו מסוחרר (daze).
#                   ירייה במיכל מעלה לחץ: VAT_HP יריות -> מתפוצץ (גל יין: נזק לזומבים DMG_Z, לך DMG אם קרוב).
#    Obstacle     - (מוצק + מחסה) "casks" חביות מוערמות / "bins" ארגזי בציר מלאים ענבים / "press" מכבש ענבים ישן
#    BodegaGate   - (עולם) שער היקב הגדול בסוף השלב (קשת אבן + שלט + פנסים)
#    WineSpray    - (עולם) פרץ יין (חבית של CASK נשברה / מיכל התפוצץ)
#    HarvestFX    - (מסך) עלי גפן נושרים + אור שקיעה חם
#  לשנות: BarrelStack.RANGE / CD / ROLL_V, FermentVat.CYCLE / WARN_T / CLOUD_T / R / VAT_HP / DMG_Z.
# ============================================================

const Art := preload("res://art.gd")
const Kit := preload("res://effects/backdrop_kit.gd")

const LEAF := [Color("6a7a2a"), Color("a88a2a"), Color("b8582a"), Color("8a2a2a"), Color("4a6a2a")]
const GRAPE := Color("4a1a4a")
const ADOBE := Color("b88a62")
const ROOF := Color("8a3a26")


static func _h(i: int, s: int) -> float:
	return fposmod(sin(float(i) * 12.9898 + float(s) * 78.233) * 43758.5453, 1.0)


static func valley_sky(ci: CanvasItem, v: Vector2, t: float) -> void:
	Kit.gradient_sky(ci, v, [Color("1a2048"), Color("3a2a5a"), Color("8a3a5a"), Color("e07a4a"), Color("f0b060")], 0.82)
	var sun := Vector2(v.x * 0.24, v.y * 0.5)
	Art.glow(ci, sun, 150.0, Color(1.0, 0.6, 0.3, 0.18))
	DrawBatch.circle(ci, sun, 30.0, Color(1.0, 0.82, 0.5, 0.95))
	for i in 9:   # עננים שטוחים וארוכים של שקיעה (מוארים מלמטה), זזים לאט
		var cy := v.y * (0.1 + _h(i, 7) * 0.3)
		var cw := 160.0 + _h(i, 8) * 220.0
		var cx := fposmod(_h(i, 9) * 1900.0 - t * (3.0 + _h(i, 10) * 5.0), v.x + cw * 2.0) - cw
		var lit := Color(1.0, 0.6, 0.5, 0.32) if cy > v.y * 0.22 else Color(0.75, 0.42, 0.6, 0.26)
		DrawBatch.colored_polygon(ci, Art.ellipse(Vector2(cx, cy), cw * 0.5, 9.0 + _h(i, 11) * 6.0, 0.0, 18), Color(0.3, 0.16, 0.3, 0.3))
		DrawBatch.colored_polygon(ci, Art.ellipse(Vector2(cx + 10.0, cy + 4.0), cw * 0.42, 4.0, 0.0, 14), lit)
	Kit.birds(ci, v, t, 46, Color(0.08, 0.05, 0.1, 0.8), 3)   # קונדורים
	Kit.birds(ci, v, t + 11.0, 48, Color(0.08, 0.05, 0.1, 0.6), 5)


# ---- האנדים והאקונקגואה ----
static func far_andes(ci: CanvasItem, sc: float, v: Vector2, y: float, t: float) -> void:
	var step := 24.0
	var back := PackedVector2Array([Vector2(0, v.y)])
	var x := -step
	while x <= v.x + step:   # רכס רחוק (כחלחל)
		var wx := x + sc * 0.7
		back.append(Vector2(x, y - 210.0 - sin(wx * 0.004) * 50.0 - absf(sin(wx * 0.011)) * 45.0))
		x += step
	back.append(Vector2(v.x, v.y))
	DrawBatch.colored_polygon(ci, back, Color("5a5a8a"))
	var period := 1700.0
	var start := int(floor(sc / period)) - 1
	for k in range(start, start + int(ceil(v.x / period)) + 2):
		var bx := float(k) * period - sc
		# האקונקגואה: מסה ענקית עם שתי פסגות
		var peak := PackedVector2Array([Vector2(bx + 200, y), Vector2(bx + 520, y - 300), Vector2(bx + 600, y - 352), Vector2(bx + 660, y - 330), Vector2(bx + 720, y - 345), Vector2(bx + 860, y - 250), Vector2(bx + 1100, y)])
		DrawBatch.colored_polygon(ci, peak, Color("4a4670"))
		var snow := PackedVector2Array([Vector2(bx + 470, y - 250), Vector2(bx + 520, y - 300), Vector2(bx + 600, y - 352), Vector2(bx + 660, y - 330), Vector2(bx + 720, y - 345), Vector2(bx + 800, y - 290),
			Vector2(bx + 760, y - 270), Vector2(bx + 720, y - 290), Vector2(bx + 680, y - 262), Vector2(bx + 640, y - 300), Vector2(bx + 580, y - 255), Vector2(bx + 540, y - 275)])
		DrawBatch.colored_polygon(ci, snow, Color(1.0, 0.86, 0.88))
		DrawBatch.colored_polygon(ci, PackedVector2Array([Vector2(bx + 600, y - 352), Vector2(bx + 660, y - 330), Vector2(bx + 640, y - 300), Vector2(bx + 610, y - 320)]), Color(1.0, 0.72, 0.7))   # זוהר
		# פסגות קטנות מושלגות
		for q in 3:
			var px := bx + 1150.0 + float(q) * 170.0
			var ph := 150.0 + _h(q + k * 5, 2) * 80.0
			DrawBatch.colored_polygon(ci, PackedVector2Array([Vector2(px - 130, y), Vector2(px, y - ph), Vector2(px + 130, y)]), Color("524e78"))
			DrawBatch.colored_polygon(ci, PackedVector2Array([Vector2(px - 34, y - ph + 40), Vector2(px, y - ph), Vector2(px + 34, y - ph + 40), Vector2(px + 12, y - ph + 30), Vector2(px - 6, y - ph + 44)]), Color(1.0, 0.88, 0.9))
		# ענן "כובע" שזז על הפסגה
		for q in 5:
			var cx := bx + 560.0 + fposmod(t * 6.0 + float(q) * 40.0, 220.0)
			DrawBatch.circle(ci, Vector2(cx, y - 330.0 + sin(float(q)) * 8.0), 22.0 + float(q % 2) * 8.0, Color(1.0, 0.8, 0.85, 0.22))
	DrawBatch.rect(ci, Rect2(0, y, v.x, v.y - y), Color("4a4670"))
	DrawBatch.rect(ci, Rect2(0, y - 30.0, v.x, 40.0), Color(0.9, 0.55, 0.5, 0.12))   # אובך


# ---- גבעות, צפצפות ויקבים ----
static func mid_bodegas(ci: CanvasItem, sc: float, v: Vector2, y: float, t: float) -> void:
	var hill := PackedVector2Array([Vector2(0, v.y)])
	var x := -20.0
	while x <= v.x + 20.0:
		var wx := x + sc
		hill.append(Vector2(x, y - 60.0 - sin(wx * 0.003) * 26.0 - sin(wx * 0.009) * 10.0))
		x += 20.0
	hill.append(Vector2(v.x, v.y))
	DrawBatch.colored_polygon(ci, hill, Color("4a3a3a"))
	var period := 1300.0
	var start := int(floor(sc / period)) - 1
	for k in range(start, start + int(ceil(v.x / period)) + 2):
		var bx := float(k) * period - sc
		var gy := y - 40.0
		# שדרת צפצפות (מתנדנדות)
		for q in 9:
			var px := bx + 40.0 + float(q) * 34.0
			var hh := 120.0 + _h(q + k * 9, 4) * 30.0
			var sw := sin(t * 1.3 + float(q) * 0.7) * 4.0
			DrawBatch.line(ci, Vector2(px, gy), Vector2(px, gy - 20.0), Color("2a1e1a"), 3.0)
			DrawBatch.colored_polygon(ci, PackedVector2Array([Vector2(px - 9, gy - 16), Vector2(px - 7 + sw * 0.5, gy - hh * 0.6), Vector2(px + sw, gy - hh), Vector2(px + 7 + sw * 0.5, gy - hh * 0.6), Vector2(px + 9, gy - 16)]),
				Color("5a5a2a") if q % 3 != 1 else Color("8a6a24"))
		# היקב: בניין אדובי ארוך עם גג רעפים ומגדל
		var wx2 := bx + 420.0
		DrawBatch.rect(ci, Rect2(wx2, gy - 90.0, 360.0, 90.0), ADOBE.darkened(0.25))
		DrawBatch.colored_polygon(ci, PackedVector2Array([Vector2(wx2 - 14, gy - 90), Vector2(wx2 + 180, gy - 130), Vector2(wx2 + 374, gy - 90)]), ROOF.darkened(0.15))
		for q in 12:
			DrawBatch.line(ci, Vector2(wx2 + float(q) * 31.0, gy - 90.0 - minf(float(q) * 31.0, 360.0 - float(q) * 31.0) * 0.2), Vector2(wx2 + float(q) * 31.0, gy - 90.0), Color(0.3, 0.12, 0.08, 0.5), 1.0)
		for q in 6:   # חלונות מוארים בקשת (חלק מהבהבים)
			var fx := wx2 + 26.0 + float(q) * 56.0
			var fl := 0.8 + 0.2 * sin(t * (5.0 + float(q)) + float(q + k))
			var lit := _h(q + k * 7, 6) < 0.75
			var c := Color(1.0, 0.72, 0.35, 0.85 * fl) if lit else Color("2a1c18")
			DrawBatch.rect(ci, Rect2(fx, gy - 60.0, 18.0, 26.0), c)
			DrawBatch.circle(ci, Vector2(fx + 9.0, gy - 60.0), 9.0, c)
			if lit:
				Art.glow(ci, Vector2(fx + 9.0, gy - 48.0), 24.0, Color(1.0, 0.6, 0.3, 0.12))
		DrawBatch.rect(ci, Rect2(wx2 + 150.0, gy - 54.0, 60.0, 54.0), Color("3a2418"))   # שער עץ
		DrawBatch.circle(ci, Vector2(wx2 + 180.0, gy - 54.0), 30.0, Color("3a2418"))
		# מגדל אבן עם פעמון
		var tx := wx2 + 380.0
		DrawBatch.rect(ci, Rect2(tx, gy - 170.0, 46.0, 170.0), Color("6a5a4a"))
		DrawBatch.colored_polygon(ci, PackedVector2Array([Vector2(tx - 6, gy - 170), Vector2(tx + 23, gy - 200), Vector2(tx + 52, gy - 170)]), ROOF.darkened(0.2))
		DrawBatch.rect(ci, Rect2(tx + 14.0, gy - 160.0, 18.0, 24.0), Color("1a1210"))
		DrawBatch.circle(ci, Vector2(tx + 23.0 + sin(t * 2.0) * 2.0, gy - 146.0), 5.0, Color("8a6a30"))
		Kit.smoke_column(ci, Vector2(wx2 + 60.0, gy - 120.0), t + float(k), 130.0, Color(0.25, 0.2, 0.25, 0.3), 70.0)
		# גבעה עם שורות כרם רחוקות
		for q in 8:
			var ry := gy - 6.0 - float(q) * 4.0
			DrawBatch.line(ci, Vector2(bx + 820.0 + float(q) * 6.0, ry), Vector2(bx + 1260.0 - float(q) * 6.0, ry), Color(0.25, 0.3, 0.12, 0.8), 2.0)
	DrawBatch.rect(ci, Rect2(0, y - 40.0, v.x, v.y - y + 40.0), Color("3a2e2a"))


# ---- שורות הגפנים (הכי קרוב) ----
static func near_vines(ci: CanvasItem, sc: float, v: Vector2, y: float, t: float) -> void:
	var period := 300.0
	var start := int(floor(sc / period)) - 1
	for k in range(start, start + int(ceil(v.x / period)) + 2):
		var x := float(k) * period - sc
		var post_h := 70.0
		DrawBatch.line(ci, Vector2(x, y), Vector2(x, y - post_h), Color("3a2a1e"), 4.0)   # עמוד
		DrawBatch.line(ci, Vector2(x + period, y), Vector2(x + period, y - post_h), Color("3a2a1e"), 4.0)
		for wy in [post_h * 0.45, post_h * 0.8]:   # חוטים
			DrawBatch.line(ci, Vector2(x, y - float(wy)), Vector2(x + period, y - float(wy)), Color(0.15, 0.12, 0.12, 0.7), 1.0)
		for q in 4:   # גזע מפותל
			var gx := x + 40.0 + float(q) * 70.0
			DrawBatch.polyline(ci, PackedVector2Array([Vector2(gx, y), Vector2(gx - 3, y - 14), Vector2(gx + 2, y - 26), Vector2(gx, y - 32)]), Color("3a2418"), 3.0)
		for q in 14:   # עלים (צבעי סתיו) שמתנדנדים
			var lx := x + 8.0 + float(q) * 21.0
			var ly := y - 30.0 - _h(q + k * 13, 1) * 34.0
			var sw := sin(t * 2.2 + float(q) * 0.9 + float(k)) * 2.5
			var c: Color = LEAF[int(_h(q + k * 3, 2) * 5.0) % 5]
			DrawBatch.colored_polygon(ci, Art.ellipse(Vector2(lx + sw, ly), 10.0, 7.0, sw * 0.1, 8), c.darkened(0.35))
			DrawBatch.colored_polygon(ci, Art.ellipse(Vector2(lx + sw + 9.0, ly + 4.0), 8.0, 6.0, 0.4, 8), c.darkened(0.2))
		for q in 5:   # אשכולות ענבים
			var gx2 := x + 25.0 + float(q) * 58.0 + sin(t * 2.0 + float(q)) * 1.5
			var gy2 := y - 36.0 + _h(q + k, 3) * 8.0
			for r in 4:
				for cc in 4 - r:
					DrawBatch.circle(ci, Vector2(gx2 + float(cc) * 4.0 - float(3 - r) * 2.0, gy2 + float(r) * 4.0), 2.6, GRAPE.lightened(0.1 * float((cc + r) % 2)))
			DrawBatch.circle(ci, Vector2(gx2 + 1.0, gy2 + 1.0), 1.0, Color(1, 0.8, 0.9, 0.5))
	DrawBatch.rect(ci, Rect2(0, y, v.x, v.y - y), Color("1e1614"))


# ============================================================
#  עולם
# ============================================================
class VineyardGround extends Node2D:
	var w := 1024.0
	var depth := 90.0

	func _ready() -> void:
		z_index = 1

	func _draw() -> void:
		DrawBatch.rect(self, Rect2(0, 0, w, depth), Color("4a3428"))
		DrawBatch.rect(self, Rect2(0, 0, w, 14), Color("6a4a34"))
		DrawBatch.rect(self, Rect2(0, 0, w, 3), Color("8a6444"))
		var x := 6.0
		var i := 0
		while x < w:   # עקבות טרקטור + ענבים מעוכים + אבנים
			var hh := _h2(i)
			if hh < 0.4:
				DrawBatch.rect(self, Rect2(x, 5, 10, 2), Color(0.25, 0.16, 0.12, 0.7))
			elif hh < 0.55:
				DrawBatch.circle(self, Vector2(x, 6), 2.0, Color(0.35, 0.08, 0.25, 0.8))
				DrawBatch.circle(self, Vector2(x + 3, 7), 1.5, Color(0.3, 0.06, 0.2, 0.8))
			elif hh < 0.7:
				DrawBatch.circle(self, Vector2(x, 9), 2.5, Color("7a6a5a"))
			x += 18.0
			i += 1
		for q in int(w / 90.0):
			DrawBatch.rect(self, Rect2(float(q) * 90.0 + 20.0, 24, 30, 2), Color(0.2, 0.14, 0.1, 0.6))

	func _h2(i: int) -> float:
		return fposmod(sin(float(i) * 12.9898 + position.x * 0.013) * 43758.5453, 1.0)


# ---- פרגולת גפן (הקומה = add_floor) ----
class Pergola extends Node2D:
	var w := 320.0
	var tier := 150.0

	func _ready() -> void:
		z_index = -1

	func _draw() -> void:
		var t := float(Engine.get_process_frames()) / 60.0
		for px in range(0, int(w) + 1, 80):   # עמודי עץ
			var x := minf(float(px), w - 10.0)
			DrawBatch.rect(self, Rect2(x, -tier, 10, tier), Color("5a3e26"))
			DrawBatch.rect(self, Rect2(x + 7, -tier, 3, tier), Color("3a2818"))
		DrawBatch.rect(self, Rect2(-6, -tier - 2, w + 12, 12), Color("6a4a2c"))   # קורה (הרצפה)
		DrawBatch.rect(self, Rect2(-6, -tier - 2, w + 12, 3), Color("8a6a44"))
		for q in int(w / 16.0) + 1:   # קורות רוחב
			DrawBatch.rect(self, Rect2(float(q) * 16.0 - 2.0, -tier + 10.0, 5, 4), Color("4a3220"))
		for q in int(w / 22.0):   # גפן ועלים מעל ומתחת
			var lx := 6.0 + float(q) * 22.0
			var sw := sin(t * 1.8 + float(q)) * 1.5
			var c: Color = LEAF[q % 5]
			DrawBatch.colored_polygon(self, Art.ellipse(Vector2(lx, -tier - 4.0), 12.0, 6.0, 0.2, 8), c.darkened(0.25))
			DrawBatch.colored_polygon(self, Art.ellipse(Vector2(lx + 6.0 + sw, -tier + 18.0), 9.0, 6.0, -0.3, 8), c.darkened(0.15))
			if q % 3 == 1:   # אשכול תלוי
				for r in 4:
					for cc in 4 - r:
						DrawBatch.circle(self, Vector2(lx + sw + float(cc) * 3.5 - float(3 - r) * 1.75, -tier + 22.0 + float(r) * 3.6), 2.2, GRAPE.lightened(0.12 * float((cc + r) % 2)))


# ---- ערימת חביות + רמפה: משחררת חבית מתגלגלת ----
class BarrelStack extends Node2D:
	const RANGE := Vector2(140.0, 620.0)   # השחקן במרחק הזה -> משחרר
	const CD := 3.2
	const ROLL_V := 330.0
	var released := 0               # לבדיקות
	var shot := 0
	var dir := 1.0                  # לאיזה כיוון הרמפה (נקבע לפי איפה הכביש)
	var _cd := 1.0
	var _warn := 0.0
	var _left := 6
	var _chock: StaticBody2D = null

	class Chock extends StaticBody2D:
		var s = null
		func hit_by_bullet(_p: Vector2, _n: Vector2, _d: Vector2) -> void:
			if s != null:
				s.shot += 1
				s._release(true)

	func _ready() -> void:
		z_index = 2
		add_to_group("hazards")
		var b := Chock.new()
		b.s = self
		b.collision_layer = 4
		b.collision_mask = 0
		var cs := CollisionShape2D.new()
		var sh := RectangleShape2D.new()
		sh.size = Vector2(14, 14)
		cs.shape = sh
		cs.position = Vector2(dir * 44.0, -10)
		b.add_child(cs)
		add_child(b)
		_chock = b
		var body := StaticBody2D.new()   # הערימה עצמה = מחסה מוצק
		body.collision_layer = 1
		body.add_to_group("no_outline")
		var cs2 := CollisionShape2D.new()
		var sh2 := RectangleShape2D.new()
		sh2.size = Vector2(64, 70)
		cs2.shape = sh2
		cs2.position = Vector2(-dir * 10.0, -35)
		body.add_child(cs2)
		add_child(body)

	func world_rect() -> Rect2:
		return Rect2(global_position + Vector2(-40, -80), Vector2(80, 80))

	func danger_at(p: Vector2, margin := 0.0) -> bool:
		return _warn > 0.0 and world_rect().grow(margin).has_point(p)

	func _physics_process(delta: float) -> void:
		_cd -= delta
		if _left <= 0:
			return
		if _warn > 0.0:
			_warn -= delta
			if _warn <= 0.0:
				_release(false)
			queue_redraw()
			return
		if _cd > 0.0 or Engine.get_physics_frames() % 6 != 0:
			return
		var pl := get_tree().get_first_node_in_group("player")
		if pl == null or pl.dead:
			return
		var dx: float = (pl.global_position.x - global_position.x) * dir
		if dx > RANGE.x and dx < RANGE.y and absf(pl.global_position.y - global_position.y) < 60.0:
			_warn = 0.6
			preload("res://sfx.gd").play("wv_creak", global_position, -2.0, 0.1, 2)

	func _release(forced: bool) -> void:
		if _left <= 0:
			return
		_left -= 1
		_warn = 0.0
		_cd = CD * (0.5 if forced else 1.0)
		released += 1
		var rb := RollingBarrel.new()
		rb.dir = dir
		rb.speed = ROLL_V
		get_parent().add_child(rb)
		rb.global_position = global_position + Vector2(dir * 46.0, -16)
		preload("res://sfx.gd").play("ck_roll", global_position, 0.0, 0.1, 2)
		queue_redraw()

	func _draw() -> void:
		var d := dir
		# רמפה
		DrawBatch.colored_polygon(self, PackedVector2Array([Vector2(-d * 40, -36), Vector2(d * 50, -2), Vector2(d * 50, 0), Vector2(-d * 40, 0)]), Color("5a3e26"))
		DrawBatch.line(self, Vector2(-d * 40, -36), Vector2(d * 50, -2), Color("8a6444"), 2.0)
		# חביות בערימה
		var n := mini(_left, 6)
		var slots := [Vector2(-d * 28, -50), Vector2(-d * 4, -50), Vector2(-d * 16, -78), Vector2(-d * 40, -22), Vector2(-d * 16, -22), Vector2(-d * 40, -78)]
		for q in n:
			_barrel(slots[q], 13.0)
		# הטריז (לירות בו)
		var wob := sin(float(Engine.get_physics_frames()) * 0.8) * 2.0 if _warn > 0.0 else 0.0
		DrawBatch.colored_polygon(self, PackedVector2Array([Vector2(d * 38 + wob, -4), Vector2(d * 50 + wob, -4), Vector2(d * 44 + wob, -16)]), Color("c89048"))
		if _warn > 0.0:
			DrawBatch.string(self, ThemeDB.fallback_font, Vector2(-6, -100), "!", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color(1.0, 0.4, 0.2))

	func _barrel(c: Vector2, r: float) -> void:
		DrawBatch.circle(self, c, r + 1.2, Color("1a1210"))
		DrawBatch.circle(self, c, r, Color("7a5430"))
		DrawBatch.arc(self, c, r - 1.5, 0.0, TAU, 18, Color("2e2e34"), 2.0)
		DrawBatch.arc(self, c, r * 0.5, 0.0, TAU, 12, Color("4a3018"), 1.2)
		DrawBatch.circle(self, c, 1.6, Color("2a1a10"))


# ---- חבית מתגלגלת ----
class RollingBarrel extends Node2D:
	const DMG_Z := 40
	var dir := 1.0
	var speed := 330.0
	var hits := 0
	var crushed := 0
	var _t := 0.0
	var _rot := 0.0
	var _vy := 0.0
	var _hit_pl := false
	var _hit_z := {}

	func _ready() -> void:
		z_index = 5

	func _physics_process(delta: float) -> void:
		_t += delta
		_rot += dir * speed * delta / 14.0
		var step := Vector2(dir * speed * delta, 0)
		var space := get_world_2d().direct_space_state
		var wall := space.intersect_ray(PhysicsRayQueryParameters2D.create(global_position, global_position + step + Vector2(dir * 14.0, 0), 1))
		if not wall.is_empty() or _t > 5.0:
			_smash()
			return
		global_position += step
		var floor := space.intersect_ray(PhysicsRayQueryParameters2D.create(global_position, global_position + Vector2(0, 16.0 + maxf(_vy, 0.0) * delta), 1))
		if floor.is_empty():
			_vy += 1500.0 * delta
			global_position.y += _vy * delta
		else:
			_vy = 0.0
			global_position.y = floor.position.y - 14.0
		var pl := get_tree().get_first_node_in_group("player")
		if not _hit_pl and pl != null and not pl.dead and pl.body_rect().intersects(Rect2(global_position - Vector2(14, 14), Vector2(28, 28))):
			_hit_pl = true
			hits += 1
			pl.hurt(1, Vector2(dir * 2.0, -0.9))
		if Engine.get_physics_frames() % 3 == 0:
			for z in get_tree().get_nodes_in_group("zombies"):
				if z.dead or z.is_boss() or _hit_z.has(z.get_instance_id()):
					continue
				if absf(z.global_position.x - global_position.x) < 20.0 and absf(z.global_position.y - 14.0 - global_position.y) < 30.0:
					_hit_z[z.get_instance_id()] = true
					crushed += 1
					z.take_damage(DMG_Z, global_position, Vector2(dir, -0.3), true, {"source": "hazard", "fixed": DMG_Z})
		if Art.on_screen(self, global_position, 40.0):
			queue_redraw()

	func _smash() -> void:
		preload("res://sfx.gd").play("ck_break", global_position, -2.0, 0.1, 2)
		var w := WineSpray.new()
		w.small = true
		get_parent().add_child(w)
		w.global_position = global_position
		var D := preload("res://debris.gd")
		for i in 4:
			var c = D.new()
			get_parent().add_child(c)
			c.setup(global_position, Vector2(randf_range(4, 8), 2.5), Color("7a5430"), Vector2(randf_range(-200, 200), -randf_range(100, 300)))
		queue_free()

	func _draw() -> void:
		DrawBatch.circle(self, Vector2.ZERO, 15.2, Color("1a1210"))
		DrawBatch.circle(self, Vector2.ZERO, 14.0, Color("7a5430"))
		DrawBatch.arc(self, Vector2.ZERO, 12.5, 0.0, TAU, 18, Color("2e2e34"), 2.0)
		DrawBatch.arc(self, Vector2.ZERO, 7.0, 0.0, TAU, 12, Color("4a3018"), 1.2)
		for q in 4:
			var a := _rot + float(q) * TAU / 4.0
			DrawBatch.line(self, Vector2.from_angle(a) * 7.5, Vector2.from_angle(a) * 12.0, Color("4a3018"), 1.2)
		DrawBatch.circle(self, Vector2.from_angle(_rot) * 4.0, 1.6, Color("2a1a10"))


# ---- מיכל תסיסה: ענן CO2 + מתפוצץ מיריות ----
class FermentVat extends Node2D:
	const CYCLE := Vector2(5.0, 7.5)
	const WARN_T := 1.0
	const CLOUD_T := 2.2
	const R := 120.0
	const VAT_HP := 8
	const DMG := 1
	const DMG_Z := 70
	const BLAST_R := 190.0
	var vents := 0                  # לבדיקות
	var dazed := 0
	var bursts := 0
	var pressure := 0
	var _state := 0                 # 0 שקט, 1 שורק (אזהרה), 2 ענן, 3 התפוצץ
	var _t := 3.0
	var _tt := 0.0
	var _body: StaticBody2D = null

	class VatBody extends StaticBody2D:
		var v = null
		func hit_by_bullet(_p: Vector2, _n: Vector2, _d: Vector2) -> void:
			if v != null:
				v.shot()

	func _ready() -> void:
		z_index = 0
		add_to_group("hazards")
		add_to_group("cover")
		var b := VatBody.new()
		b.v = self
		b.collision_layer = 1
		b.add_to_group("no_outline")
		var cs := CollisionShape2D.new()
		var sh := RectangleShape2D.new()
		sh.size = Vector2(70, 110)
		cs.shape = sh
		cs.position = Vector2(0, -55)
		b.add_child(cs)
		add_child(b)
		_body = b

	func cover_rect() -> Rect2:
		return Rect2(global_position + Vector2(-35, -110), Vector2(70, 110))

	func world_rect() -> Rect2:
		return Rect2(global_position + Vector2(-R, -140), Vector2(R * 2.0, 140))

	func danger_at(p: Vector2, margin := 0.0) -> bool:
		return (_state == 1 or _state == 2) and world_rect().grow(margin).has_point(p)

	func shot() -> void:
		if _state == 3:
			return
		pressure += 1
		preload("res://sfx.gd").play("metal_ping", global_position + Vector2(0, -60), -4.0, 0.15, 2)
		if pressure >= VAT_HP:
			_burst()

	func _burst() -> void:
		_state = 3
		bursts += 1
		preload("res://sfx.gd").play("ck_break", global_position, 4.0, 0.1, 2)
		preload("res://sfx.gd").play("wv_burst", global_position, 2.0, 0.1, 2)
		var cam := get_viewport().get_camera_2d()
		if cam != null and cam.has_method("shake"):
			cam.shake(8.0, 0.3)
		var w := WineSpray.new()
		get_parent().add_child(w)
		w.global_position = global_position + Vector2(0, -50)
		var w2 := WineSpray.new()
		w2.wave = true
		get_parent().add_child(w2)
		w2.global_position = global_position
		var pl := get_tree().get_first_node_in_group("player")
		if pl != null and not pl.dead and pl.global_position.distance_to(global_position) < BLAST_R * 0.6:
			pl.hurt(DMG, Vector2(signf(pl.global_position.x - global_position.x + 0.01) * 2.0, -1.0))
		for z in get_tree().get_nodes_in_group("zombies"):
			if not z.dead and not z.is_boss() and z.global_position.distance_to(global_position) < BLAST_R:
				z.take_damage(DMG_Z, z.global_position + Vector2(0, -20), Vector2(signf(z.global_position.x - global_position.x + 0.01), -0.5), true, {"source": "hazard", "fixed": DMG_Z})
		if is_instance_valid(_body):
			_body.queue_free()
		queue_redraw()

	func _physics_process(delta: float) -> void:
		_tt += delta
		if _state == 3:
			return
		_t -= delta
		match _state:
			0:
				if _t <= 0.0:
					_state = 1
					_t = WARN_T
					preload("res://sfx.gd").play("wv_hiss", global_position + Vector2(0, -100), -2.0, 0.1, 2)
			1:
				if _t <= 0.0:
					_state = 2
					_t = CLOUD_T
					vents += 1
			2:
				if Engine.get_physics_frames() % 10 == 0:
					var pl := get_tree().get_first_node_in_group("player")
					if pl != null and not pl.dead and absf(pl.global_position.x - global_position.x) < R and pl.global_position.y > global_position.y - 150.0 and pl.global_position.y < global_position.y + 10.0:
						if not pl.is_dazed():
							dazed += 1
						pl.daze(1.2, "CO2 FUMES")
				if _t <= 0.0:
					_state = 0
					_t = randf_range(CYCLE.x, CYCLE.y)
		if Art.on_screen(self, global_position + Vector2(0, -60), R + 60.0) and Engine.get_physics_frames() % 2 == 0:
			queue_redraw()

	func _draw() -> void:
		if _state == 3:   # שרידים
			DrawBatch.colored_polygon(self, PackedVector2Array([Vector2(-36, 0), Vector2(-32, -40), Vector2(-20, -24), Vector2(-8, -52), Vector2(6, -30), Vector2(20, -46), Vector2(34, -20), Vector2(36, 0)]), Color("8a8e94"))
			DrawBatch.colored_polygon(self, Art.ellipse(Vector2(0, -2), 70.0, 6.0, 0.0, 16), Color(0.35, 0.04, 0.2, 0.75))
			return
		var shake := Vector2(sin(_tt * 50.0), 0) * (float(pressure) / float(VAT_HP)) * 2.0
		DrawBatch.rect(self, Rect2(Vector2(-30, -20) + shake, Vector2(8, 20)), Color("5a5e64"))   # רגליים
		DrawBatch.rect(self, Rect2(Vector2(22, -20) + shake, Vector2(8, 20)), Color("5a5e64"))
		DrawBatch.rect(self, Rect2(Vector2(-36, -104) + shake, Vector2(72, 86)), Color("a8acb2"))   # המיכל (נירוסטה)
		DrawBatch.rect(self, Rect2(Vector2(-36, -104) + shake, Vector2(14, 86)), Color("c8ccd2"))
		DrawBatch.rect(self, Rect2(Vector2(20, -104) + shake, Vector2(16, 86)), Color("8a8e94"))
		DrawBatch.colored_polygon(self, PackedVector2Array([Vector2(-36, -104) + shake, Vector2(0, -118) + shake, Vector2(36, -104) + shake]), Color("9a9ea4"))
		DrawBatch.rect(self, Rect2(Vector2(-6, -126) + shake, Vector2(12, 10)), Color("6a6e74"))   # שסתום
		for yy in [-90.0, -40.0]:
			DrawBatch.line(self, Vector2(-36, yy) + shake, Vector2(36, yy) + shake, Color("6a6e74"), 2.0)
		# שעון לחץ
		var g := Vector2(-14, -66) + shake
		DrawBatch.circle(self, g, 8.0, Color("1a1a1e"))
		DrawBatch.circle(self, g, 6.5, Color("e8e4d8"))
		var a := -PI * 0.8 + PI * 1.6 * clampf(float(pressure) / float(VAT_HP), 0.0, 1.0)
		DrawBatch.line(self, g, g + Vector2.from_angle(a) * 5.5, Color(0.8, 0.1, 0.1), 1.2)
		DrawBatch.string(self, ThemeDB.fallback_font, Vector2(2, -58) + shake, "MALBEC", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.35, 0.05, 0.15))
		if pressure > 0:   # דליפות יין
			for q in mini(pressure, 6):
				var lp := Vector2(-30.0 + float(q * 11 % 60), -30.0 - float(q * 17 % 60)) + shake
				DrawBatch.line(self, lp, lp + Vector2(0, 8.0 + float(q % 3) * 4.0), Color(0.42, 0.04, 0.22, 0.85), 1.6)
		if _state == 1:   # שורק
			for q in 4:
				var k := fmod(_tt * 3.0 + float(q) * 0.25, 1.0)
				DrawBatch.circle(self, Vector2(0, -128.0 - k * 30.0), 3.0 + k * 6.0, Color(0.85, 0.85, 0.8, 0.5 * (1.0 - k)))
			DrawBatch.string(self, ThemeDB.fallback_font, Vector2(-6, -150), "!", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color(1.0, 0.4, 0.2))
		elif _state == 2:   # ענן CO2 כבד שזוחל לרצפה
			var k2 := 1.0 - _t / CLOUD_T
			var al := 0.32 * minf(1.0, (1.0 - k2) * 3.0) * minf(1.0, k2 * 6.0 + 0.3)
			for q in 14:
				var ox := sin(float(q) * 2.3 + _tt * 0.6) * R * (0.4 + 0.6 * k2)
				var oy := -20.0 - absf(cos(float(q) * 1.7 + _tt * 0.5)) * 90.0 * (1.0 - k2 * 0.5)
				DrawBatch.circle(self, Vector2(ox, oy), 26.0 + float(q % 3) * 8.0, Color(0.78, 0.8, 0.72, al))


# ---- מכשולים ----
class Obstacle extends Node2D:
	var kind := "casks"
	var size := Vector2(60, 50)
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
		match kind:
			"casks":   # חביות שוכבות על מתלה
				DrawBatch.rect(self, Rect2(0, -6, w, 6), Color("4a3220"))
				var r := minf(h * 0.27, w * 0.25)
				var cols := int(w / (r * 2.0))
				for row in 2:
					for q in cols - row:
						var c := Vector2(r + float(q) * r * 2.0 + float(row) * r, -6.0 - r - float(row) * r * 1.7)
						DrawBatch.circle(self, c, r + 1.2, Color("1a1210"))
						DrawBatch.circle(self, c, r, Color("7a5430").darkened(0.08 * float((q + row) % 2)))
						DrawBatch.arc(self, c, r - 1.5, 0.0, TAU, 16, Color("2e2e34"), 1.8)
						DrawBatch.arc(self, c, r * 0.5, 0.0, TAU, 12, Color("4a3018"), 1.0)
						DrawBatch.circle(self, c, 1.5, Color("2a1a10"))
				DrawBatch.string(self, ThemeDB.fallback_font, Vector2(4, -h + 6.0), "", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color.WHITE)
			"bins":   # ארגזי בציר מלאים ענבים
				DrawBatch.rect(self, Rect2(0, -h, w, h), Color("1a1210"))
				DrawBatch.rect(self, Rect2(1, -h + 1, w - 2, h - 2), Color("9a7a4a"))
				for q in 4:
					DrawBatch.line(self, Vector2(1, -h + 4.0 + float(q) * (h - 6.0) / 3.0), Vector2(w - 1, -h + 4.0 + float(q) * (h - 6.0) / 3.0), Color("6a502a"), 1.2)
				for q in int(w / 5.0):
					DrawBatch.circle(self, Vector2(3.0 + float(q) * 5.0, -h + 1.0 - float((q + seed_v) % 3)), 3.0, GRAPE.lightened(0.1 * float(q % 2)))
			_:   # מכבש ענבים ישן (סל עץ + בורג)
				DrawBatch.rect(self, Rect2(0, -10, w, 10), Color("3a2a1e"))
				DrawBatch.rect(self, Rect2(w * 0.12, -h * 0.72, w * 0.76, h * 0.62), Color("1a1210"))
				for q in 8:
					DrawBatch.rect(self, Rect2(w * 0.13 + float(q) * w * 0.094, -h * 0.71, w * 0.07, h * 0.6), Color("8a6034"))
				DrawBatch.line(self, Vector2(w * 0.12, -h * 0.55), Vector2(w * 0.88, -h * 0.55), Color("2e2e34"), 2.0)
				DrawBatch.line(self, Vector2(w * 0.12, -h * 0.25), Vector2(w * 0.88, -h * 0.25), Color("2e2e34"), 2.0)
				DrawBatch.rect(self, Rect2(w * 0.47, -h, w * 0.06, h * 0.3), Color("4a4a50"))   # בורג
				DrawBatch.rect(self, Rect2(w * 0.2, -h * 0.84, w * 0.6, 4), Color("4a3220"))
				DrawBatch.line(self, Vector2(w * 0.2, -h * 0.98), Vector2(w * 0.8, -h * 0.94), Color("3a3a40"), 3.0)   # ידית


# ---- שער היקב בסוף השלב ----
class BodegaGate extends Node2D:
	func _ready() -> void:
		z_index = -2

	func _draw() -> void:
		var t := float(Engine.get_process_frames()) / 60.0
		DrawBatch.rect(self, Rect2(-180, -230, 50, 230), ADOBE.darkened(0.1))
		DrawBatch.rect(self, Rect2(130, -230, 50, 230), ADOBE.darkened(0.1))
		DrawBatch.rect(self, Rect2(-190, -250, 380, 30), ADOBE)
		DrawBatch.colored_polygon(self, PackedVector2Array([Vector2(-200, -250), Vector2(0, -290), Vector2(200, -250)]), ROOF)
		DrawBatch.arc(self, Vector2(0, -220), 130.0, PI, TAU, 24, ADOBE.darkened(0.2), 10.0)
		DrawBatch.rect(self, Rect2(-100, -284, 200, 26), Color("2a1a12"))
		DrawBatch.string(self, ThemeDB.fallback_font, Vector2(-84, -265), "BODEGA LA MUERTE", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(0.95, 0.8, 0.5))
		for px in [-155.0, 155.0]:   # פנסים
			DrawBatch.line(self, Vector2(px, -232), Vector2(px, -214), Color("1a1a1a"), 2.0)
			var fl := 0.8 + 0.2 * sin(t * 9.0 + px)
			DrawBatch.circle(self, Vector2(px, -208), 6.0, Color(1.0, 0.75, 0.35, fl))
			Art.glow(self, Vector2(px, -208), 30.0, Color(1.0, 0.6, 0.3, 0.2 * fl))
		for q in 5:   # גפן מטפסת על הקשת
			DrawBatch.colored_polygon(self, Art.ellipse(Vector2(-150.0 + float(q) * 70.0, -246.0), 14.0, 7.0, 0.3, 8), LEAF[q % 5].darkened(0.2))


# ---- פרץ יין ----
class WineSpray extends Node2D:
	var small := false
	var wave := false               # גל לאורך הרצפה (מיכל שהתפוצץ)
	var _p := []
	var _t := 0.0

	func _ready() -> void:
		z_index = 7
		var n := 10 if small else 26
		n = Quality.scaled(n, Quality.particles())
		for i in n:
			var a := randf_range(-PI * 0.95, -PI * 0.05)
			var sp := randf_range(120.0, 360.0) * (0.7 if small else 1.0)
			if wave:
				a = PI if i % 2 == 0 else 0.0
				a += randf_range(-0.25, -0.05) * (1.0 if a == 0.0 else -1.0)
				sp = randf_range(200.0, 420.0)
			_p.append([Vector2.ZERO, Vector2.from_angle(a) * sp, randf_range(1.5, 3.5)])

	func _process(delta: float) -> void:
		_t += delta
		for q in _p:
			q[1].y += 900.0 * delta
			q[0] += q[1] * delta
			if q[0].y > 0.0 and not wave:
				q[0].y = 0.0
				q[1] = Vector2.ZERO
			elif wave and q[0].y > 0.0:
				q[0].y = 0.0
				q[1].y = 0.0
				q[1].x *= 1.0 - 2.0 * delta
		if _t > 2.2:
			queue_free()
			return
		queue_redraw()

	func _draw() -> void:
		var a := clampf(2.2 - _t, 0.0, 1.0)
		DrawBatch.colored_polygon(self, Art.ellipse(Vector2(0, 0 if wave else 30), (90.0 if wave else 30.0) * minf(_t * 2.0, 1.0), 4.0, 0.0, 14), Color(0.32, 0.03, 0.18, 0.7 * a))
		for q in _p:
			DrawBatch.circle(self, q[0], q[2], Color(0.45, 0.05, 0.25, 0.9 * a))
			DrawBatch.line(self, q[0], q[0] - q[1] * 0.02, Color(0.45, 0.05, 0.25, 0.6 * a), q[2])


# ---- עלים נושרים + אור שקיעה (מסך) ----
class HarvestFX extends Node2D:
	var vp := Vector2(1280, 720)
	var _t := 0.0

	func _process(delta: float) -> void:
		_t += delta
		if Engine.get_process_frames() % 2 == 0:
			queue_redraw()

	func _draw() -> void:
		var n := Quality.scaled(18, Quality.ambient())
		for i in n:
			var x := fposmod(float(i) * 83.0 + sin(_t * 0.9 + float(i)) * 50.0 - _t * 18.0, vp.x)
			var y := fposmod(float(i) * 61.0 + _t * (30.0 + float(i % 5) * 7.0), vp.y)
			var c: Color = LEAF[i % 5]
			DrawBatch.colored_polygon(self, Art.ellipse(Vector2(x, y), 4.0, 2.2, _t * 2.5 + float(i), 6), Color(c, 0.75))
		DrawBatch.rect(self, Rect2(0, 0, vp.x, vp.y), Color(1.0, 0.5, 0.25, 0.05))
