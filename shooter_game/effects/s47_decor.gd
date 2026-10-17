extends RefCounted
# ============================================================
#  קישוטים לשלב 47 ("PAMPAS STORM") - הפמפס הארגנטינית, אסטנסיה (חוות בקר) בסופת רעמים. אזור שישי, שלב 2.
#  המישור האינסופי, עשב פמפס גבוה, טחנות רוח מברזל, עצי אומבו, ופרות מתות שעוד רועות.
#    pampa_sky     - (רקע) שמיים ירוקים-אפורים של סערה, עננים כבדים שזזים מהר, ברקים בתוך העננים
#    far_horizon   - (רקע, 0.06) קו אופק שטוח לגמרי, תאי סערה רחוקים (ענני סדן), וילונות גשם, ברקים שנוגעים בקרקע
#    mid_estancia  - (רקע, 0.28) בית האסטנסיה הלבן עם גג רעפים, עצי אומבו מתנדנדים, טחנות רוח מסתובבות,
#                    פרות מתות רועות (ראש עולה ויורד), גדרות ושער (טרנקרה)
#    near_grass    - (רקע, 0.62) עשב פמפס גבוה עם נוצות לבנות שמתנופף ברוח, עמודי גדר עם תיל
#    PampaGround   - (עולם) אדמה בוצית רטובה עם גומות עשב ושלוליות
#    Galpon        - (עולם) מחסן פח עם עליית שחת (הקומה = add_floor). מקום בטוח מהברקים
#    Windmill      - (עולם, מלכודת) טחנת רוח מברזל עם במה (הקומה = add_floor). בסערה (StormFX.warning) - "אש אלמו" כחולה
#                    בקצה ובברזל, ובזמן הברק - ברק פוגע בטחנה: מחשמל את הבמה ואת העיגול סביב הבסיס (DMG לשחקן, DMG_Z לזומבים)
#    Stampede      - (עולם, מלכודת) עדר פרות מתות. אתה עובר את נקודת ההפעלה -> רעש + אבק (WARN_T, "STAMPEDE!")
#                    -> העדר דוהר לרוחב הכביש (SPEED). פגיעה = DMG + הדף. לעלות על מכשול / קומה! דורס גם זומבים.
#    Mud           - (עולם) בוץ עמוק: מאט אותך (slow_t)
#    Corral        - (עולם) מכלאה עם גדר עץ לפני היציאה (הזירה של EL TORO)
#    Obstacle      - (מוצק + מחסה) "bale" גליל חציר / "trough" שוקת מים מפח / "carreta" עגלת שוורים
#    StormFX       - (מסך, קבוצה "storm") גשם אלכסוני כבד + ברקים בזמנים קבועים: warning() לפני, flashing() בזמן.
#  לשנות: StormFX.PERIOD / WARN, Windmill.R / DMG / DMG_Z, Stampede.WARN_T / SPEED / HERD / DMG, Mud.SLOW.
# ============================================================

const Art := preload("res://art.gd")
const Sfx := preload("res://sfx.gd")
const Kit := preload("res://effects/backdrop_kit.gd")

const EARTH := Color("2e2a22")
const EARTH_D := Color("1c1a15")
const GRASS := Color("3a4a2a")
const GRASS_D := Color("24301c")
const IRON := Color("3a3e44")
const BOLT := Color(0.85, 0.92, 1.0)


static func _h(i: int, s: int) -> float:
	return fposmod(sin(float(i) * 12.9898 + float(s) * 78.233) * 43758.5453, 1.0)


static func storm() -> Node:
	var tree := Engine.get_main_loop() as SceneTree
	return tree.get_first_node_in_group("storm") if tree != null else null


static func bolt_pts(from: Vector2, to: Vector2, seed_v: int, jag := 26.0) -> PackedVector2Array:
	var pts := PackedVector2Array([from])
	var n := maxi(4, int(from.distance_to(to) / 40.0))
	for i in range(1, n):
		var k := float(i) / float(n)
		var p := from.lerp(to, k)
		p.x += (_h(i, seed_v) - 0.5) * jag * 2.0
		pts.append(p)
	pts.append(to)
	return pts


static func draw_bolt(ci: CanvasItem, pts: PackedVector2Array, a: float) -> void:
	ci.draw_polyline(pts, Color(0.55, 0.75, 1.0, 0.45 * a), 8.0)
	ci.draw_polyline(pts, Color(1, 1, 1, a), 2.6)


# ---- שמיים ----
static func pampa_sky(ci: CanvasItem, v: Vector2, t: float) -> void:
	Kit.gradient_sky(ci, v, [Color("0c1214"), Color("18242a"), Color("2c3a38"), Color("4a5244")], 0.82)
	var st := storm()
	var flash: float = st.flash_k() if st != null else 0.0
	for i in 3:   # שלוש שכבות עננים שזזות מהר ברוח
		Kit.clouds(ci, float(i) * 260.0, v, t, v.y * (0.08 + 0.11 * float(i)), Color(0.08 + flash * 0.3, 0.11 + flash * 0.3, 0.12 + flash * 0.35, 0.6 - float(i) * 0.12), 47 + i, 26.0 + float(i) * 12.0)
	# ברקים בתוך העננים (הבהובים בלי בורג)
	var idx := int(t / 2.3)
	var k := fmod(t, 2.3)
	if k < 0.18:
		var c := Vector2(_h(idx, 3) * v.x, v.y * (0.1 + _h(idx, 4) * 0.2))
		Art.glow(ci, c, 140.0, Color(0.7, 0.8, 1.0, 0.35 * (1.0 - k / 0.18)))


# ---- האופק השטוח ותאי הסערה ----
static func far_horizon(ci: CanvasItem, sc: float, v: Vector2, y: float, t: float) -> void:
	var period := 1800.0
	var start := int(floor(sc / period)) - 1
	for k in range(start, start + int(ceil(v.x / period)) + 2):
		var bx := float(k) * period - sc
		for c in 2:   # ענן סדן ענק + וילון גשם
			var cx := bx + 300.0 + float(c) * 850.0 + sin(t * 0.05 + float(k)) * 30.0
			var top := y - 300.0 - _h(k * 2 + c, 1) * 60.0
			ci.draw_colored_polygon(PackedVector2Array([Vector2(cx - 260, top + 40), Vector2(cx - 120, top - 10), Vector2(cx + 160, top - 14), Vector2(cx + 300, top + 30), Vector2(cx + 120, top + 70), Vector2(cx - 140, top + 70)]), Color("1a2224"))
			ci.draw_colored_polygon(PackedVector2Array([Vector2(cx - 140, top + 60), Vector2(cx + 120, top + 60), Vector2(cx + 60, y - 10), Vector2(cx - 180, y - 10)]), Color(0.16, 0.2, 0.22, 0.28))
			for q in 16:   # וילון גשם אלכסוני
				var rx := cx - 140.0 + float(q) * 16.0 + fmod(t * 40.0, 16.0)
				ci.draw_line(Vector2(rx, top + 70.0), Vector2(rx - 45.0, y - 6.0), Color(0.42, 0.48, 0.52, 0.1 + 0.06 * float(q % 3)), 3.0 + float(q % 2) * 3.0)
			# ברק שנוגע בקרקע, כל תא בזמן אחר
			var per := 5.0 + float((k + c) % 3)
			var ph := fmod(t + float(k * 3 + c) * 1.7, per)
			if ph < 0.22:
				var a := 1.0 - ph / 0.22
				draw_bolt(ci, bolt_pts(Vector2(cx, top + 60.0), Vector2(cx + (_h(k, c) - 0.5) * 80.0, y - 2.0), k * 7 + c, 14.0), a)
				Art.glow(ci, Vector2(cx, y - 20.0), 70.0, Color(0.7, 0.8, 1.0, 0.25 * a))
	# המישור: קו אופק שטוח לגמרי
	ci.draw_rect(Rect2(0, y - 4.0, v.x, v.y - y + 4.0), Color("1a2018"))
	ci.draw_line(Vector2(0, y - 4.0), Vector2(v.x, y - 4.0), Color("2a3426"), 2.0)


# ---- האסטנסיה: בית, אומבו, טחנות, פרות ----
static func mid_estancia(ci: CanvasItem, sc: float, v: Vector2, y: float, t: float) -> void:
	var period := 1300.0
	var start := int(floor(sc / period)) - 1
	var wind := sin(t * 0.9) * 0.5 + 0.5
	for k in range(start, start + int(ceil(v.x / period)) + 2):
		var bx := float(k) * period - sc
		# בית האסטנסיה (קאסקו): קירות לבנים, גג רעפים, גלריה עם קשתות
		var hx := bx + 120.0
		ci.draw_rect(Rect2(hx, y - 96.0, 300.0, 84.0), Color("8a8a80"))
		ci.draw_colored_polygon(PackedVector2Array([Vector2(hx - 14, y - 96), Vector2(hx + 40, y - 132), Vector2(hx + 260, y - 132), Vector2(hx + 314, y - 96)]), Color("5a2a20"))
		for q in 6:   # קשתות הגלריה
			var ax := hx + 14.0 + float(q) * 48.0
			ci.draw_rect(Rect2(ax, y - 66.0, 30.0, 54.0), Color("2a2a2a"))
			ci.draw_circle(Vector2(ax + 15.0, y - 66.0), 15.0, Color("2a2a2a"))
		var lit := _h(k, 9) < 0.5 and fmod(t * 0.3 + float(k), 4.0) > 0.4   # חלון מהבהב (נר)
		ci.draw_rect(Rect2(hx + 236.0, y - 88.0, 18.0, 16.0), Color(1.0, 0.7, 0.35, 0.8) if lit else Color("1a1a1a"))
		# עץ אומבו: גזע ענק ורחב, צמרת עבה שמתנדנדת ברוח
		var ox := bx + 560.0
		var sway := sin(t * 1.4 + float(k)) * (3.0 + wind * 4.0)
		ci.draw_colored_polygon(PackedVector2Array([Vector2(ox - 40, y - 12), Vector2(ox - 22, y - 70), Vector2(ox + 22, y - 70), Vector2(ox + 46, y - 12)]), Color("2a241e"))
		for q in 7:
			var cpt := Vector2(ox - 90.0 + float(q) * 30.0 + sway * (1.0 - absf(float(q) - 3.0) / 4.0), y - 110.0 - absf(sin(float(q) * 1.3)) * 30.0)
			ci.draw_circle(cpt, 36.0 - absf(float(q) - 3.0) * 3.0, Color("1c2a1c"))
		# טחנת רוח מברזל
		var wx := bx + 860.0
		var top := y - 170.0
		ci.draw_line(Vector2(wx - 22, y - 10), Vector2(wx - 3, top), Color("22262a"), 3.0)
		ci.draw_line(Vector2(wx + 22, y - 10), Vector2(wx + 3, top), Color("22262a"), 3.0)
		for q in 5:
			var yy := y - 10.0 - float(q + 1) * 30.0
			var ww := lerpf(22.0, 3.0, float(q + 1) / 5.5)
			ci.draw_line(Vector2(wx - ww, yy), Vector2(wx + ww, yy + 30.0), Color("22262a"), 1.4)
			ci.draw_line(Vector2(wx + ww, yy), Vector2(wx - ww, yy + 30.0), Color("22262a"), 1.4)
		var spin := t * (2.0 + wind * 4.0) + float(k)
		for q in 12:
			var a := spin + float(q) / 12.0 * TAU
			ci.draw_line(Vector2(wx, top), Vector2(wx, top) + Vector2.from_angle(a) * 30.0, Color("2a2e32"), 2.5)
		ci.draw_arc(Vector2(wx, top), 30.0, 0, TAU, 20, Color("2a2e32"), 1.5)
		ci.draw_colored_polygon(PackedVector2Array([Vector2(wx, top - 3), Vector2(wx - 50, top - 8), Vector2(wx - 50, top + 8), Vector2(wx, top + 3)]), Color("2a2e32"))   # זנב
		# פרות מתות רועות (ראש עולה ויורד)
		for c in 3:
			var cx := bx + 980.0 + float(c) * 90.0
			var gr := sin(t * 0.8 + float(c * 2 + k)) > 0.2
			cow_silhouette(ci, Vector2(cx, y - 10.0), 0.8, gr, Color("161c18"), c % 2 == 0)
		# גדר + שער (טרנקרה)
		for q in 14:
			var fx := bx + float(q) * 90.0
			ci.draw_line(Vector2(fx, y - 10.0), Vector2(fx, y - 36.0), Color("1e2018"), 3.0)
		ci.draw_line(Vector2(bx, y - 30.0), Vector2(bx + 1300.0, y - 30.0), Color("1e2018"), 1.0)
		ci.draw_line(Vector2(bx, y - 20.0), Vector2(bx + 1300.0, y - 20.0), Color("1e2018"), 1.0)
	ci.draw_rect(Rect2(0, y - 12.0, v.x, v.y - y + 12.0), Color("161c14"))


# צללית פרה מתה: צלעות, קרניים, ראש מורכן לאכול
static func cow_silhouette(ci: CanvasItem, p: Vector2, s: float, grazing: bool, c: Color, face_right := true) -> void:
	var d := 1.0 if face_right else -1.0
	ci.draw_colored_polygon(Art.ellipse(p + Vector2(0, -26) * s, 30.0 * s, 13.0 * s, 0.0, 14), c)
	for q in 4:
		var lx := p.x + (-20.0 + float(q) * 12.0) * s * d
		ci.draw_line(Vector2(lx, p.y - 18.0 * s), Vector2(lx + (1.0 if q % 2 == 0 else -1.0) * s, p.y), c, 3.0 * s)
	var neck := p + Vector2(26.0 * d, -30.0) * s
	var head := neck + (Vector2(12.0 * d, 18.0) if grazing else Vector2(14.0 * d, -4.0)) * s
	ci.draw_line(neck, head, c, 7.0 * s)
	ci.draw_colored_polygon(Art.ellipse(head, 8.0 * s, 5.0 * s, 0.6 * d if grazing else 0.0, 10), c)
	ci.draw_line(head + Vector2(-2.0 * d, -4.0) * s, head + Vector2(-8.0 * d, -12.0) * s, c, 2.0 * s)   # קרן
	ci.draw_line(p + Vector2(-30.0 * d, -30.0) * s, p + Vector2(-36.0 * d, -14.0) * s, c, 1.6 * s)   # זנב


# ---- עשב פמפס גבוה ועמודי גדר ----
static func near_grass(ci: CanvasItem, sc: float, v: Vector2, y: float, t: float) -> void:
	var period := 220.0
	var start := int(floor(sc / period)) - 1
	var gust := 0.6 + 0.4 * sin(t * 0.7)
	for k in range(start, start + int(ceil(v.x / period)) + 2):
		var x := float(k) * period - sc
		# שיח קורטדריה: עלים ארוכים + נוצות לבנות שמתכופפות ברוח
		var bx := x + 60.0 + _h(k, 2) * 60.0
		var h := 70.0 + _h(k, 5) * 40.0
		for q in 9:
			var a := -PI * 0.5 + (float(q) - 4.0) * 0.16
			var bend := (sin(t * 2.4 + float(q) * 0.5 + float(k)) * 0.12 + 0.18) * gust
			var tip := Vector2(bx, y) + Vector2.from_angle(a + bend) * h * (0.7 + 0.3 * absf(sin(float(q))))
			ci.draw_line(Vector2(bx + (float(q) - 4.0) * 2.0, y), tip, Color("2a3420"), 2.0)
		for q in 4:   # נוצות
			var a2 := -PI * 0.5 + (float(q) - 1.5) * 0.2 + (sin(t * 2.0 + float(q) + float(k)) * 0.15 + 0.25) * gust
			var base := Vector2(bx + (float(q) - 1.5) * 4.0, y - h * 0.55)
			var tip2 := base + Vector2.from_angle(a2) * h * 0.75
			ci.draw_line(base, tip2, Color("4a4a3a"), 1.6)
			ci.draw_colored_polygon(Art.ellipse(tip2, 5.0, 14.0, a2 + PI * 0.5, 10), Color(0.75, 0.74, 0.66, 0.85))
		# עמוד גדר עם תיל
		var px := x + 190.0
		ci.draw_rect(Rect2(px - 4.0, y - 64.0, 8.0, 64.0), Color("1a160f"))
		for wy in [y - 56.0, y - 42.0, y - 28.0]:
			ci.draw_line(Vector2(px - 186.0, wy + 2.0), Vector2(px, wy), Color("2a2a2a"), 1.0)
	ci.draw_rect(Rect2(0, y, v.x, v.y - y), Color("10140c"))


# ============================================================
#  עולם
# ============================================================
class PampaGround extends Node2D:
	var w := 1024.0
	var depth := 90.0
	var seed_v := 0

	func _ready() -> void:
		z_index = 1

	func _draw() -> void:
		draw_rect(Rect2(0, 0, w, depth), EARTH_D)
		draw_rect(Rect2(0, 0, w, 16.0), EARTH)
		var r := RandomNumberGenerator.new()
		r.seed = seed_v
		for i in int(w / 70.0):   # שלוליות קטנות שמשקפות את השמיים
			var px := r.randf_range(0.0, w)
			draw_colored_polygon(Art.ellipse(Vector2(px, 6.0), r.randf_range(14.0, 34.0), 2.6, 0.0, 12), Color(0.35, 0.42, 0.45, 0.5))
		for i in int(w / 9.0):   # גומות עשב על השפה
			var gx := r.randf_range(0.0, w)
			var gh := r.randf_range(4.0, 11.0)
			draw_line(Vector2(gx, 1.0), Vector2(gx + r.randf_range(-3.0, 3.0), -gh), GRASS if i % 3 else GRASS_D, 1.4)
		for i in int(w / 40.0):   # חלוקי אבן ושורשים באדמה
			draw_circle(Vector2(r.randf_range(0.0, w), r.randf_range(22.0, depth - 8.0)), r.randf_range(1.5, 3.5), Color("26231c"))


# ---- מחסן פח עם עליית שחת ----
class Galpon extends Node2D:
	var w := 360.0
	var tier := 150.0

	func _ready() -> void:
		z_index = -1

	func _draw() -> void:
		var h := tier + 110.0
		draw_rect(Rect2(0, -h + 30.0, w, h - 30.0), Color("3a1e1a"))   # קיר אחורי (פח צבוע אדום כהה)
		for q in int(w / 12.0):   # גלי הפח
			draw_line(Vector2(float(q) * 12.0, -h + 30.0), Vector2(float(q) * 12.0, 0), Color("2a1412"), 2.0)
		var roof := PackedVector2Array()   # גג מעוגל
		for i in 17:
			var a := PI + float(i) / 16.0 * PI
			roof.append(Vector2(w * 0.5 + cos(a) * (w * 0.5 + 16.0), -h + 30.0 + sin(a) * 50.0))
		draw_colored_polygon(roof, Color("4a4e52"))
		draw_polyline(roof, Color("2a2e32"), 3.0)
		for q in 6:   # קורות עץ
			draw_rect(Rect2(float(q) * (w - 14.0) / 5.0, -h + 30.0, 14.0, h - 30.0), Color("4a3422"))
		# עליית השחת
		draw_rect(Rect2(-6, -tier, w + 12.0, 12.0), Color("6a4a2a"))
		draw_rect(Rect2(-6, -tier + 12.0, w + 12.0, 4.0), Color("3a2818"))
		for q in 5:   # חבילות חציר על הקומה (רקע)
			draw_rect(Rect2(20.0 + float(q) * 64.0, -tier - 26.0, 50.0, 26.0), Color("8a7a3a"))
			draw_line(Vector2(20.0 + float(q) * 64.0, -tier - 13.0), Vector2(70.0 + float(q) * 64.0, -tier - 13.0), Color("6a5a2a"), 1.0)
		draw_rect(Rect2(w * 0.5 - 40.0, -h + 50.0, 80.0, 26.0), Color("d8d0b8"))   # שלט האסטנסיה
		draw_string(ThemeDB.fallback_font, Vector2(w * 0.5 - 34.0, -h + 69.0), "LA ULTIMA", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("3a1e1a"))


# ---- טחנת רוח מברזל + מלכודת ברק ----
class Windmill extends Node2D:
	const R := 120.0               # רדיוס החשמול סביב הבסיס
	const DMG := 2
	const DMG_Z := 30
	const ACTIVE_R := 1100.0       # רק טחנות קרובות לשחקן "תופסות" ברקים
	var tier := 170.0              # גובה הבמה
	var plat_w := 110.0
	var strikes := 0               # לבדיקות
	var hits := 0
	var _t := 0.0
	var _bolt_t := 0.0
	var _bolt := PackedVector2Array()
	var _was_flash := false
	var _spin := 0.0

	func _ready() -> void:
		z_index = -1
		add_to_group("hazards")

	func top() -> Vector2:
		return Vector2(0, -tier - 150.0)

	func _active() -> bool:
		var pl := get_tree().get_first_node_in_group("player")
		return pl != null and absf(pl.global_position.x - global_position.x) < ACTIVE_R

	func world_rect() -> Rect2:
		return Rect2(global_position + Vector2(-R, -tier - 40.0), Vector2(R * 2.0, tier + 40.0))

	func danger_at(p: Vector2, margin := 0.0) -> bool:
		var st := preload("res://effects/s47_decor.gd").storm()
		return st != null and (st.warning() or st.flashing()) and _active() and _in_zone(p, margin)

	func _in_zone(p: Vector2, margin := 0.0) -> bool:
		var d := p - global_position
		if absf(d.x) < R + margin and d.y > -50.0 and d.y < 10.0:
			return true   # עיגול סביב הבסיס
		return absf(d.x) < plat_w * 0.5 + margin and d.y > -tier - 70.0 and d.y < -tier + 10.0   # על הבמה

	func _physics_process(delta: float) -> void:
		_t += delta
		_bolt_t = maxf(_bolt_t - delta, 0.0)
		var st := preload("res://effects/s47_decor.gd").storm()
		_spin += delta * (3.0 + (6.0 if st != null and st.warning() else 0.0))
		var fl: bool = st != null and st.flashing()
		if fl and not _was_flash and _active():
			_strike()
		_was_flash = fl
		if Art.on_screen(self, global_position + Vector2(0, -tier), tier + 200.0) and Engine.get_physics_frames() % 2 == 0:
			queue_redraw()

	func _strike() -> void:
		strikes += 1
		_bolt_t = 0.4
		_bolt = preload("res://effects/s47_decor.gd").bolt_pts(top() + Vector2(0, -600), top(), strikes * 13 + int(global_position.x))
		Sfx.play("pm_zap", global_position + top(), 4.0, 0.1, 3)
		var P := preload("res://particles.gd")
		P.burst(get_parent(), global_position + top(), "spark", Vector2.ZERO, 14)
		P.burst(get_parent(), global_position + Vector2(0, -4), "spark", Vector2.UP, 10)
		var pl := get_tree().get_first_node_in_group("player")
		if pl != null and not pl.dead and _in_zone(pl.global_position):
			if pl._invuln <= 0.0:
				hits += 1
			pl.hurt(DMG, Vector2(signf(pl.global_position.x - global_position.x + 0.01) * 1.2, -1.2))
			Game.story.emit("hazard", {"kind": "shock"})
		for z in get_tree().get_nodes_in_group("zombies"):
			if not z.dead and not z.is_boss() and _in_zone(z.global_position):
				z.take_damage(DMG_Z, z.global_position + Vector2(0, -20), Vector2.UP, true, {"source": "hazard", "fixed": DMG_Z})

	func _draw() -> void:
		var st := preload("res://effects/s47_decor.gd").storm()
		var warn: bool = st != null and st.warning() and _active()
		var tp := top()
		var ir := IRON
		# מגדל מסבכי
		draw_line(Vector2(-34, 0), Vector2(-5, tp.y + 10.0), ir, 4.0)
		draw_line(Vector2(34, 0), Vector2(5, tp.y + 10.0), ir, 4.0)
		for q in 8:
			var y0 := -float(q) * (tier + 140.0) / 8.0
			var y1 := -float(q + 1) * (tier + 140.0) / 8.0
			var w0 := lerpf(34.0, 5.0, -y0 / (tier + 150.0))
			var w1 := lerpf(34.0, 5.0, -y1 / (tier + 150.0))
			draw_line(Vector2(-w0, y0), Vector2(w1, y1), ir, 1.6)
			draw_line(Vector2(w0, y0), Vector2(-w1, y1), ir, 1.6)
		# הבמה
		draw_rect(Rect2(-plat_w * 0.5, -tier, plat_w, 8.0), Color("5a5e64"))
		draw_line(Vector2(-plat_w * 0.5, -tier - 24.0), Vector2(plat_w * 0.5, -tier - 24.0), ir, 2.0)
		for q in 5:
			var rx := -plat_w * 0.5 + float(q) * plat_w / 4.0
			draw_line(Vector2(rx, -tier), Vector2(rx, -tier - 24.0), ir, 1.6)
		# הגלגל המסתובב + זנב
		for q in 16:
			var a := _spin + float(q) / 16.0 * TAU
			var d := Vector2.from_angle(a)
			draw_colored_polygon(PackedVector2Array([tp + d * 10.0, tp + d * 44.0 + d.orthogonal() * 4.0, tp + d * 44.0 - d.orthogonal() * 5.0]), Color("6a6e74"))
		draw_arc(tp, 44.0, 0, TAU, 24, Color("4a4e54"), 2.0)
		draw_circle(tp, 7.0, Color("2a2e32"))
		draw_colored_polygon(PackedVector2Array([tp + Vector2(0, -3), tp + Vector2(-70, -14), tp + Vector2(-70, 14), tp + Vector2(0, 3)]), Color("5a5e64"))
		# מכל מים בבסיס
		draw_rect(Rect2(36, -34, 50, 34), Color("4a5258"))
		draw_rect(Rect2(36, -34, 50, 4), Color("6a7278"))
		if warn:   # אש אלמו: הברזל זוהר כחול ומנצנץ, העיגול מסומן
			var k: float = 1.0 - clampf(st.time_to_flash() / st.WARN, 0.0, 1.0)
			Art.glow(self, tp, 40.0 + 20.0 * k, Color(0.55, 0.8, 1.0, 0.5))
			for q in 4:
				var a := randf() * TAU
				draw_line(tp, tp + Vector2.from_angle(a) * randf_range(10.0, 30.0), Color(0.85, 0.95, 1.0, 0.9), 1.4)
			draw_line(Vector2(-6, -tier), tp, Color(0.6, 0.85, 1.0, 0.3 + 0.4 * k), 3.0)
			draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.2))
			draw_arc(Vector2.ZERO, R, 0, TAU, 32, Color(0.6, 0.85, 1.0, 0.5 + 0.4 * (1.0 if fmod(_t * 8.0, 1.0) < 0.5 else 0.0)), 4.0)
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
			draw_rect(Rect2(-plat_w * 0.5, -tier - 2.0, plat_w, 4.0), Color(0.6, 0.85, 1.0, 0.5 + 0.4 * k))
		if _bolt_t > 0.0:
			var a2 := _bolt_t / 0.4
			preload("res://effects/s47_decor.gd").draw_bolt(self, _bolt, a2)
			draw_line(tp, Vector2(0, 0), Color(0.8, 0.95, 1.0, a2), 3.0)
			Art.glow(self, Vector2(0, -6), R, Color(0.6, 0.85, 1.0, 0.5 * a2))
			Art.glow(self, Vector2(0, -tier), plat_w * 0.6, Color(0.6, 0.85, 1.0, 0.5 * a2))


# ---- דהירת עדר פרות מתות ----
class Stampede extends Node2D:
	const WARN_T := 2.2
	const SPEED := 560.0
	const HERD := 7
	const DMG := 2
	const DMG_Z := 45
	const SAFE_H := 60.0           # מעל הכביש בגובה כזה (על מכשול / קומה) - העדר עובר מתחתיך
	const SPAN := 1500.0           # כמה רחוק הם דוהרים
	var floor_y := 630.0
	var state := 0                 # 0 = מחכה, 1 = אזהרה, 2 = דוהרים, 3 = נגמר
	var dir := 1.0                 # מאיזה צד באים
	var runs := 0                  # לבדיקות
	var hits := 0
	var trampled := 0
	var _t := 0.0
	var _cows := []                # [x יחסי, גודל, פאזה]
	var _hit_p := false

	func _ready() -> void:
		z_index = 7
		add_to_group("hazards")

	func world_rect() -> Rect2:
		if state != 2:
			return Rect2()
		var xs := _xs()
		return Rect2(Vector2(xs.x, floor_y - 70.0), Vector2(xs.y - xs.x, 70.0))

	func danger_at(p: Vector2, margin := 0.0) -> bool:
		return state == 2 and world_rect().grow(margin).has_point(p)

	func _xs() -> Vector2:
		var mn := INF
		var mx := -INF
		for c in _cows:
			mn = minf(mn, global_position.x + float(c[0]))
			mx = maxf(mx, global_position.x + float(c[0]))
		return Vector2(mn - 40.0, mx + 40.0)

	func trigger() -> void:
		if state != 0:
			return
		state = 1
		_t = WARN_T
		Sfx.play("pm_rumble", global_position, 2.0, 0.05, 2)
		var pl := get_tree().get_first_node_in_group("player")
		if pl != null and pl.has_method("_say"):
			pl._say("STAMPEDE!  GET UP HIGH", Color("ffb050"))

	func _physics_process(delta: float) -> void:
		var pl := get_tree().get_first_node_in_group("player")
		match state:
			0:
				if pl != null and not pl.dead and absf(pl.global_position.x - global_position.x) < 260.0:
					dir = 1.0 if randf() < 0.5 else -1.0
					trigger()
			1:
				_t -= delta
				if pl != null and Engine.get_physics_frames() % 6 == 0:
					var cam := get_viewport().get_camera_2d()
					if cam != null and cam.has_method("shake"):
						cam.shake(2.0 + (WARN_T - _t) * 1.5, 0.15)
				if _t <= 0.0:
					state = 2
					runs += 1
					_cows.clear()
					var px: float = pl.global_position.x if pl != null else global_position.x
					var sx := px - global_position.x - dir * 760.0
					for i in HERD:
						_cows.append([sx - dir * float(i) * randf_range(55.0, 80.0), randf_range(0.95, 1.2), randf() * TAU])
					_t = 0.0
					Sfx.play("pm_rumble", global_position, 5.0, 0.05, 2, 0.8)
			2:
				_t += delta
				for c in _cows:
					c[0] = float(c[0]) + dir * SPEED * delta
					c[2] = float(c[2]) + delta * 14.0
				if Engine.get_physics_frames() % 3 == 0:
					_collide(pl)
				if _t > (SPAN + 900.0) / SPEED:
					state = 3
		if state != 0 and state != 3:
			queue_redraw()
		elif state == 3 and _cows.size() > 0:
			_cows.clear()
			queue_redraw()

	func _collide(pl: Node) -> void:
		for c in _cows:
			var cx := global_position.x + float(c[0])
			var r := Rect2(Vector2(cx - 34.0, floor_y - SAFE_H), Vector2(68.0, SAFE_H))
			if pl != null and not pl.dead and not _hit_p and r.intersects(pl.body_rect()):
				_hit_p = true
				hits += 1
				pl.hurt(DMG, Vector2(dir * 2.6, -1.6))
			if Engine.get_physics_frames() % 6 == 0:
				for z in get_tree().get_nodes_in_group("zombies"):
					if z.dead or z.is_boss() or z.get_meta("trampled", false):
						continue
					if r.has_point(z.global_position + Vector2(0, -6)):
						z.set_meta("trampled", true)
						trampled += 1
						z.take_damage(DMG_Z, z.global_position + Vector2(0, -20), Vector2(dir, -0.5), true, {"source": "hazard", "fixed": DMG_Z})
						if not z.dead:
							z.velocity = Vector2(dir * 380.0, -300.0)

	func _draw() -> void:
		if state == 1:   # ענן אבק מתקרב מהצד + שלט אזהרה
			var pl := get_tree().get_first_node_in_group("player")
			if pl == null:
				return
			var base: Vector2 = pl.global_position - global_position + Vector2(-dir * 560.0, 0)
			var k := 1.0 - _t / WARN_T
			for q in 8:
				var p := base + Vector2(dir * float(q) * 30.0 * k - dir * 60.0, -20.0 - float(q % 3) * 14.0)
				draw_circle(p, 26.0 + k * 20.0, Color(0.35, 0.32, 0.26, 0.25 + 0.3 * k))
			var sx: float = pl.global_position.x - global_position.x
			draw_string(ThemeDB.fallback_font, Vector2(sx - 70.0, floor_y - global_position.y - 150.0), "STAMPEDE!", HORIZONTAL_ALIGNMENT_LEFT, -1, 30, Color(1.0, 0.6, 0.2, 0.6 + 0.4 * sin(_t * 18.0)))
			draw_string(ThemeDB.fallback_font, Vector2(sx - 44.0, floor_y - global_position.y - 124.0), "GET UP HIGH", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(1.0, 0.85, 0.6, 0.8))
			return
		if state != 2:
			return
		for c in _cows:
			var p := Vector2(float(c[0]), floor_y - global_position.y)
			var s: float = c[1]
			var ph: float = c[2]
			draw_circle(p + Vector2(-dir * 30.0, -14.0), 22.0, Color(0.3, 0.27, 0.22, 0.35))   # אבק
			StampedeCow.draw_cow(self, p + Vector2(0, -absf(sin(ph)) * 4.0), s, dir, ph)


# פרה מתה דוהרת (מצוירת בעולם)
class StampedeCow:
	static func draw_cow(ci: CanvasItem, p: Vector2, s: float, d: float, ph: float) -> void:
		var hide := Color("4a3a2e")
		var bone := Color("d8ccb0")
		var body := Art.ellipse(p + Vector2(0, -34) * s, 32.0 * s, 15.0 * s, 0.0, 16)
		for q in 4:   # רגליים דוהרות
			var lx := p.x + (-22.0 + float(q) * 14.0) * s * d
			var sw := sin(ph + float(q) * 1.7) * 9.0 * s
			var knee := Vector2(lx + sw * 0.6 * d, p.y - 12.0 * s)
			ci.draw_line(Vector2(lx, p.y - 24.0 * s), knee, Art.OUTLINE, 5.0 * s)
			ci.draw_line(knee, Vector2(lx + sw * d, p.y), Art.OUTLINE, 4.0 * s)
			ci.draw_line(Vector2(lx, p.y - 24.0 * s), knee, hide.darkened(0.2), 3.4 * s)
			ci.draw_line(knee, Vector2(lx + sw * d, p.y), hide.darkened(0.2), 2.6 * s)
		Art.fill_shaded(ci, body, hide, 0.12, 0.35)
		for q in 4:   # צלעות חשופות
			var rx := p.x + (-6.0 + float(q) * 6.0) * s * d
			ci.draw_line(Vector2(rx, p.y - 44.0 * s), Vector2(rx - 2.0 * d * s, p.y - 26.0 * s), bone, 1.6 * s)
		ci.draw_colored_polygon(Art.ellipse(p + Vector2(4.0 * d, -34) * s, 7.0 * s, 6.0 * s, 0.0, 8), Color(0.4, 0.05, 0.05, 0.8))
		var head := p + Vector2(38.0 * d, -30.0) * s
		Art.fill(ci, Art.ellipse(head, 11.0 * s, 7.0 * s, 0.3 * d, 12), bone)   # גולגולת
		ci.draw_circle(head + Vector2(2.0 * d, -2.0) * s, 1.8 * s, Color(1.0, 0.3, 0.2))
		ci.draw_line(head + Vector2(-4.0 * d, -5.0) * s, head + Vector2(4.0 * d, -16.0) * s, bone, 2.4 * s)   # קרניים
		ci.draw_line(head + Vector2(-6.0 * d, -5.0) * s, head + Vector2(-12.0 * d, -14.0) * s, bone, 2.4 * s)
		ci.draw_line(p + Vector2(-30.0 * d, -40.0) * s, p + Vector2(-42.0 * d, -30.0 + sin(ph) * 6.0) * s, hide, 2.0 * s)   # זנב


# ---- בוץ עמוק ----
class Mud extends Node2D:
	const SLOW := 0.2
	var w := 150.0
	var slowed := 0                # לבדיקות
	var _t := 0.0

	func _ready() -> void:
		z_index = 2

	func _physics_process(delta: float) -> void:
		_t += delta
		if Engine.get_physics_frames() % 4 != 0:
			return
		var pl := get_tree().get_first_node_in_group("player")
		if pl != null and pl.is_on_floor() and absf(pl.global_position.x - global_position.x) < w * 0.5 and absf(pl.global_position.y - global_position.y) < 8.0:
			if pl.slow_t <= 0.0:
				slowed += 1
			pl.slow_t = maxf(pl.slow_t, SLOW)
		if Art.on_screen(self, global_position, w) and Engine.get_physics_frames() % 8 == 0:
			queue_redraw()

	func _draw() -> void:
		draw_colored_polygon(Art.ellipse(Vector2(0, 2), w * 0.5, 6.0, 0.0, 18), Color("1e1a12"))
		draw_colored_polygon(Art.ellipse(Vector2(-w * 0.1, 1), w * 0.36, 3.0, 0.0, 14), Color(0.3, 0.36, 0.38, 0.5))
		for q in 3:   # טיפות גשם על הבוץ
			var k := fmod(_t * 1.3 + float(q) * 0.33, 1.0)
			draw_arc(Vector2((float(q) - 1.0) * w * 0.25, 1), 2.0 + k * 10.0, 0, TAU, 12, Color(0.6, 0.7, 0.75, 0.5 * (1.0 - k)), 1.0)


# ---- מכלאה (זירת הבוס) ----
class Corral extends Node2D:
	var w := 900.0

	func _ready() -> void:
		z_index = -1

	func _draw() -> void:
		var wood := Color("4a3422")
		for q in int(w / 70.0) + 1:
			var x := float(q) * 70.0
			draw_rect(Rect2(x - 5.0, -110.0, 10.0, 110.0), wood)
		for yy in [-100.0, -70.0, -40.0]:
			draw_rect(Rect2(0, yy, w, 8.0), wood.lightened(0.08))
		for q in 3:   # גולגולות בקר על העמודים
			var gx := w * (0.2 + 0.3 * float(q))
			Art.fill(self, Art.ellipse(Vector2(gx, -122.0), 9.0, 7.0, 0.0, 10), Color("d8ccb0"))
			draw_line(Vector2(gx - 6.0, -126.0), Vector2(gx - 16.0, -136.0), Color("d8ccb0"), 2.2)
			draw_line(Vector2(gx + 6.0, -126.0), Vector2(gx + 16.0, -136.0), Color("d8ccb0"), 2.2)
			draw_circle(Vector2(gx - 3.0, -122.0), 1.6, Color("1a1a1a"))
			draw_circle(Vector2(gx + 3.0, -122.0), 1.6, Color("1a1a1a"))


# ---- מכשולים ----
class Obstacle extends Node2D:
	var kind := "bale"
	var size := Vector2(50, 50)
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
			"bale":   # גליל חציר (מהצד: עיגול עם ספירלה)
				var c := Vector2(w * 0.5, -h * 0.5)
				var r := minf(w, h) * 0.5
				Art.disc(self, c, r, Color("9a8240"))
				for q in 4:
					draw_arc(c, r * (0.25 + 0.2 * float(q)), float(q), float(q) + 5.0, 14, Color("7a6430"), 1.4)
				for q in 6:
					var a := float(q) * 1.1 + float(seed_v % 5)
					draw_line(c + Vector2.from_angle(a) * r * 0.9, c + Vector2.from_angle(a) * (r + 4.0), Color("b8a050"), 1.2)
				draw_colored_polygon(Art.ellipse(c + Vector2(0, -r * 0.6), r * 0.7, r * 0.2, 0.0, 10), Color(0.4, 0.45, 0.5, 0.35))   # רטוב מגשם
			"trough":   # שוקת מים מפח על רגליים
				draw_line(Vector2(6, 0), Vector2(10, -h * 0.4), IRON, 3.0)
				draw_line(Vector2(w - 6, 0), Vector2(w - 10, -h * 0.4), IRON, 3.0)
				Art.fill(self, PackedVector2Array([Vector2(0, -h), Vector2(w, -h), Vector2(w - 8, -h * 0.35), Vector2(8, -h * 0.35)]), Color("5a6a6e"))
				for q in int(w / 10.0):
					draw_line(Vector2(6.0 + float(q) * 10.0, -h + 2.0), Vector2(9.0 + float(q) * 10.0, -h * 0.36), Color("4a585c"), 1.4)
				draw_rect(Rect2(2, -h - 2.0, w - 4.0, 4.0), Color(0.45, 0.55, 0.6, 0.8))   # מים עולים על גדותיהם
			_:   # עגלת שוורים (קרטה) עם גלגלים גבוהים
				Art.fill(self, PackedVector2Array([Vector2(0, -h * 0.75), Vector2(w, -h * 0.75), Vector2(w - 4, -h * 0.42), Vector2(4, -h * 0.42)]), Color("5a3e26"))
				for q in 4:
					draw_line(Vector2(4.0 + float(q) * (w - 8.0) / 3.0, -h), Vector2(4.0 + float(q) * (w - 8.0) / 3.0, -h * 0.75), Color("4a3220"), 3.0)
				draw_line(Vector2(0, -h), Vector2(w, -h), Color("4a3220"), 3.0)
				draw_line(Vector2(w, -h * 0.55), Vector2(w + 30.0, -h * 0.3), Color("4a3220"), 3.0)   # מוט
				var wc := Vector2(w * 0.5, -h * 0.36)
				var wr := h * 0.36
				draw_arc(wc, wr, 0, TAU, 22, Art.OUTLINE, 5.0)
				draw_arc(wc, wr, 0, TAU, 22, Color("6a4a2c"), 3.0)
				for q in 8:
					draw_line(wc, wc + Vector2.from_angle(float(q) / 8.0 * TAU) * wr, Color("5a3e26"), 2.0)
				draw_circle(wc, 4.0, Color("3a2818"))


# ---- סערה: גשם כבד + ברקים בזמנים קבועים (שכבת מסך) ----
class StormFX extends Node2D:
	const PERIOD := Vector2(8.0, 11.0)   # כל כמה זמן ברק גדול
	const WARN := 1.4                     # כמה זמן לפני - טחנות הרוח זוהרות
	const FLASH := 0.4
	var vp := Vector2(1280, 720)
	var flashes := 0                      # לבדיקות
	var _next := 7.0
	var _flash := 0.0
	var _small := 0.0
	var _bolt := PackedVector2Array()
	var _drops := []

	func _ready() -> void:
		add_to_group("storm")
		var r := RandomNumberGenerator.new()
		r.seed = 47
		for i in 130:
			_drops.append(Vector3(r.randf_range(0, vp.x + 300.0), r.randf_range(0, vp.y), r.randf_range(0.7, 1.3)))

	func warning() -> bool:
		return _next > 0.0 and _next <= WARN

	func flashing() -> bool:
		return _flash > FLASH * 0.2

	func time_to_flash() -> float:
		return _next

	func flash_k() -> float:
		return maxf(_flash / FLASH, _small * 2.0)

	func strike_flash() -> void:   # ברק קטן (STORMCALLER)
		_small = 0.25

	func _process(delta: float) -> void:
		_next -= delta
		_flash = maxf(_flash - delta, 0.0)
		_small = maxf(_small - delta, 0.0)
		if _next <= 0.0:
			_next = randf_range(PERIOD.x, PERIOD.y)
			_flash = FLASH
			flashes += 1
			Sfx.play("thunder", null, 1.0, 0.15)
			Game.story.emit("thunder", {})
			_bolt = PackedVector2Array([Vector2(randf_range(vp.x * 0.1, vp.x * 0.9), 0)])
			var y := 0.0
			var x: float = _bolt[0].x
			while y < vp.y * 0.6:
				y += randf_range(25.0, 50.0)
				x += randf_range(-34.0, 34.0)
				_bolt.append(Vector2(x, y))
		var n := int(float(_drops.size()) * clampf(Quality.ambient(), 0.3, 1.0))   # (גשם = לא דם: יורד כשהמשחק איטי)
		for i in _drops.size():
			var d: Vector3 = _drops[i]
			d.x -= 380.0 * delta * d.z
			d.y += 1000.0 * delta * d.z
			if d.y > vp.y:
				d = Vector3(randf_range(0.0, vp.x + 400.0), -10.0, d.z)
			_drops[i] = d
		set_meta("n", n)
		queue_redraw()

	func _draw() -> void:
		var n: int = int(get_meta("n", _drops.size()))
		for i in mini(n, _drops.size()):
			var d: Vector3 = _drops[i]
			draw_line(Vector2(d.x, d.y), Vector2(d.x + 8.0, d.y - 20.0 * d.z), Color(0.7, 0.8, 0.9, 0.32), 1.0)
		if _flash > 0.0:
			var a := (_flash / FLASH) * (1.0 if fmod(_flash, 0.1) < 0.06 else 0.5)
			draw_rect(Rect2(Vector2.ZERO, vp), Color(0.78, 0.86, 1.0, 0.3 * a))
			draw_polyline(_bolt, Color(0.6, 0.8, 1.0, 0.4 * a), 7.0)
			draw_polyline(_bolt, Color(0.95, 0.97, 1.0, a), 2.5)
		elif _small > 0.0:
			draw_rect(Rect2(Vector2.ZERO, vp), Color(0.75, 0.85, 1.0, 0.25 * _small))
		draw_rect(Rect2(0, 0, vp.x, vp.y), Color(0.04, 0.08, 0.1, 0.14))   # כהות סערה
