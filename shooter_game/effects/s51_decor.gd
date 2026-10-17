extends RefCounted
# ============================================================
#  קישוטים לשלב 51 ("THE RANCH") - אסטנסיה ארגנטינית בצהרי קיץ לוהטים. אזור שישי, שלב 6.
#  ההפך מהסערה של שלב 47: שמש לבנה, אבק, שקט מת. המכלאות מלאות בבקר מת, והבוקרים המתים עוד רוכבים, מסמנים ומגדלים דבורים.
#    ranch_sky     - (רקע) שמיים לבנים-כחולים של צהריים, שמש חזקה עם קרניים, נשרים שמסתובבים במעגלים
#    far_plain     - (רקע, 0.06) אופק שטוח עם אוויר רועד וחזיון תעתועים, שורת אקליפטוסים, ענן אבק של עדר מת רחוק
#    mid_casco     - (רקע, 0.28) בית האחוזה (קאסקו) עם גלריה ותריסים ירוקים, טחנות רוח "אוסטרליות" + מיכל מים עגול,
#                    אסם, ממגורות תבואה מפח, דגל שמתנופף, אבק
#    near_fence    - (רקע, 0.6) גדר תיל עם עמודים, קוצים סגולים (קרדו) שמתנדנדים, גלגלי קוצים מתגלגלים, גולגולות בקר
#    RanchGround   - (עולם) אדמה יבשה וסדוקה עם עקבות פרסות וקש
#    WaterTower    - (עולם) מגדל מים מעץ עם במה (הקומה = add_floor)
#    Silo          - (עולם) ממגורה עם מסלול הליכה בגובה TIER (הקומה = add_floor)
#    GrainChute    - (עולם, מלכודת) צינור הריקון של הממגורה מעל הכביש: אתה מתחתיו -> חריקה + אבק (WARN_T) -> שופך תבואה
#                    (POUR_T): נזק, האטה, קובר זומבים. נשארת ערימה שמאטה (PILE_T). ירייה בפתח = שפיכה ברגע שתבחר.
#    Chute         - (עולם, מלכודת) מכלאת הובלה (מנגה) עם שער: אתה מתקרב -> השער רועד (WARN_T) ונפתח, ושור מת (Steer)
#                    דוהר עליך לאורך הכביש. לקפוץ מעליו! דורס גם זומבים. אפשר להרוג אותו (STEER_HP) או לירות בבריח מוקדם.
#    Trough        - (עולם, קבוצה "troughs") שוקת מים. עומדים בתוכה = שוטפים את הסימון של BRANDER.
#    AsadoPit      - (עולם, קבוצה "smoke_src") אסאדו על צלב ברזל מעל גחלים. העשן (SMOKE_R) מפזר נחילי דבורים (BEEKEEPER).
#    BeeBoxes / Coop - (עולם) תיבות כוורת עם דבורים, לול עם תרנגולות (קישוט)
#    DomaArena     - (עולם) זירת האילוף (דומה) בסוף - הזירה של EL PATRON, שער עם סימן האחוזה
#    Obstacle      - (מוצק + מחסה) "bales" חבילות חציר / "drums" חביות דלק / "tractor" טרקטור חלוד
#    RanchFX       - (מסך) אבק באוויר + משב אבק מדי פעם + סנוור חום
#  עזרים: smoky(tree, p) - האם יש עשן בנקודה (אסאדו, אש של מולוטוב). brand_mark() - סימן האחוזה (P עם קו).
#  לשנות: GrainChute.WARN_T / POUR_T / DMG / PILE_T, Chute.WARN_T / Steer.SPEED / DMG / STEER_HP, AsadoPit.SMOKE_R.
# ============================================================

const Art := preload("res://art.gd")
const Sfx := preload("res://sfx.gd")
const Kit := preload("res://effects/backdrop_kit.gd")
const Particles := preload("res://particles.gd")

const DIRT := Color("a88a5a")
const DIRT_D := Color("6e5638")
const WOOD := Color("7a5a36")
const WOOD_D := Color("4e3820")
const STEEL := Color("9aa0a4")
const BONE := Color("e6dcc2")
const HAY := Color("d2b05a")


static func _h(i: int, s: int) -> float:
	return fposmod(sin(float(i) * 12.9898 + float(s) * 78.233) * 43758.5453, 1.0)


# האם יש עשן בנקודה: מדורות אסאדו (קבוצה smoke_src) ואש (fire_zone / fire.gd בקבוצת hazards)
static func smoky(tree: SceneTree, p: Vector2) -> bool:
	if tree == null:
		return false
	for s in tree.get_nodes_in_group("smoke_src"):
		if s.has_method("smoke_covers") and s.smoke_covers(p):
			return true
	for h in tree.get_nodes_in_group("hazards"):
		if h.get("zombie_burn") != null and h.global_position.distance_to(p) < 150.0:   # (environment/fire_zone.gd)
			return true
	return false


# סימן האחוזה "לה פטרונה": P עם קו מתחת ושני קרניים
static func brand_mark(ci: CanvasItem, c: Vector2, r: float, col: Color, w := 2.0) -> void:
	ci.draw_line(c + Vector2(-r * 0.35, r * 0.7), c + Vector2(-r * 0.35, -r * 0.7), col, w)
	ci.draw_arc(c + Vector2(-r * 0.05, -r * 0.35), r * 0.36, -PI * 0.5, PI * 0.5, 8, col, w)
	ci.draw_line(c + Vector2(-r * 0.8, r * 0.95), c + Vector2(r * 0.8, r * 0.95), col, w)
	ci.draw_line(c + Vector2(-r * 0.35, -r * 0.7), c + Vector2(-r * 0.9, -r * 1.05), col, w * 0.8)
	ci.draw_line(c + Vector2(r * 0.25, -r * 0.7), c + Vector2(r * 0.8, -r * 1.05), col, w * 0.8)


# ---- שמיים ----
static func ranch_sky(ci: CanvasItem, v: Vector2, t: float) -> void:
	Kit.gradient_sky(ci, v, [Color("2a62a2"), Color("4e8cc4"), Color("9cc2da"), Color("e6e2c8")], 0.86)
	var sun := Vector2(v.x * 0.64, v.y * 0.13)
	for q in 10:   # קרני שמש שמסתובבות לאט
		var a := float(q) / 10.0 * TAU + t * 0.02
		ci.draw_line(sun + Vector2.from_angle(a) * 40.0, sun + Vector2.from_angle(a) * (170.0 + 40.0 * sin(t * 0.7 + float(q))), Color(1.0, 0.98, 0.85, 0.07), 10.0)
	Art.glow(ci, sun, 260.0, Color(1.0, 0.97, 0.82, 0.22))
	Art.glow(ci, sun, 110.0, Color(1.0, 1.0, 0.92, 0.45))
	ci.draw_circle(sun, 30.0, Color(1.0, 1.0, 0.95))
	Kit.clouds(ci, 0.0, v, t, v.y * 0.3, Color(1.0, 1.0, 1.0, 0.16), 51, 3.0)   # רק כמה קווי ענן דקים
	# נשרים מסתובבים מעל משהו מת
	var c := Vector2(v.x * 0.24, v.y * 0.24)
	for i in 4:
		var r := 60.0 + float(i) * 22.0
		var a2 := t * (0.35 + float(i) * 0.06) + float(i) * 1.7
		var p := c + Vector2(cos(a2) * r, sin(a2) * r * 0.35)
		var fl := 3.0 + (sin(t * 6.0 + float(i)) * 2.0 if fmod(t + float(i), 5.0) < 0.8 else 0.0)   # בעיקר דואים, מנפנפים לפעמים
		var s := 0.8 + float(i % 2) * 0.3
		ci.draw_polyline(PackedVector2Array([p + Vector2(-13, -fl) * s, p + Vector2(-5, 0) * s, p, p + Vector2(5, 0) * s, p + Vector2(13, -fl) * s]), Color(0.12, 0.1, 0.1, 0.75), 2.2 * s)


# ---- המישור הרחוק ----
static func far_plain(ci: CanvasItem, sc: float, v: Vector2, y: float, t: float) -> void:
	var haze := Color(0.78, 0.82, 0.8)
	var period := 1700.0
	var start := int(floor(sc / period)) - 1
	for k in range(start, start + int(ceil(v.x / period)) + 2):
		var bx := float(k) * period - sc
		# שורת אקליפטוסים (שוברי רוח) - צלליות גבוהות, דהויות באובך
		for q in 9:
			var tx := bx + 200.0 + float(q) * 30.0 + _h(k * 9 + q, 1) * 12.0
			var th := 70.0 + _h(k * 9 + q, 2) * 50.0
			var sway := sin(t * 0.8 + float(q)) * 1.5
			ci.draw_line(Vector2(tx, y - 4.0), Vector2(tx + sway, y - th * 0.6), Color(0.62, 0.64, 0.6), 2.0)
			for e in 4:
				ci.draw_colored_polygon(Art.ellipse(Vector2(tx + sway * float(e) * 0.4 + (float(e % 2) - 0.5) * 6.0, y - th + float(e) * th * 0.18), 9.0 - float(e), th * 0.14, 0.0, 10), Color(0.5, 0.6, 0.58, 0.9).lerp(haze, 0.35))
		# מבנה רחוק: פוסטה קטנה עם עץ
		var px := bx + 1100.0
		ci.draw_rect(Rect2(px, y - 18.0, 40.0, 14.0), Color(0.82, 0.8, 0.72))
		ci.draw_colored_polygon(PackedVector2Array([Vector2(px - 4, y - 18), Vector2(px + 20, y - 28), Vector2(px + 44, y - 18)]), Color(0.66, 0.5, 0.42))
		ci.draw_circle(Vector2(px + 64.0, y - 30.0), 16.0, Color(0.52, 0.6, 0.54).lerp(haze, 0.3))
	# העדר המת הרחוק: נקודות שזזות לאט + ענן אבק מאחוריהן (לא תלוי בגלילה - הם נעים בעצמם)
	var hx := fposmod(t * 16.0 - sc * 0.5, v.x + 900.0) - 450.0
	for q in 6:
		var dx := hx - float(q) * 60.0
		ci.draw_colored_polygon(Art.ellipse(Vector2(dx - 40.0, y - 18.0), 70.0, 16.0, 0.0, 14), Color(0.86, 0.78, 0.62, 0.14))
	for q in 14:
		var cx := hx + float(q) * 9.0 - _h(q, 7) * 40.0
		var bob := absf(sin(t * 7.0 + float(q))) * 1.0
		ci.draw_rect(Rect2(cx, y - 9.0 - bob, 6.0, 3.0), Color(0.35, 0.3, 0.26, 0.8))
		ci.draw_line(Vector2(cx + 1.0, y - 6.0 - bob), Vector2(cx + 1.0, y - 4.0), Color(0.35, 0.3, 0.26, 0.8), 1.0)
		ci.draw_line(Vector2(cx + 5.0, y - 6.0 - bob), Vector2(cx + 5.0, y - 4.0), Color(0.35, 0.3, 0.26, 0.8), 1.0)
	# המישור
	ci.draw_rect(Rect2(0, y - 4.0, v.x, v.y - y + 4.0), Color("c2ae7c"))
	# חזיון תעתועים: פס בהיר שמשקף את השמיים ורועד
	for q in 4:
		var yy := y - 3.0 + float(q) * 3.0
		var a := 0.18 + 0.1 * sin(t * 3.0 + float(q) * 1.3)
		ci.draw_line(Vector2(0, yy), Vector2(v.x, yy + sin(t * 2.0 + float(q)) * 0.6), Color(0.8, 0.88, 0.95, a), 2.0)
	for q in 6:   # רעד חום מעל האופק
		var yy2 := y - 10.0 - float(q) * 7.0
		var xo := fmod(t * 30.0 + float(q) * 70.0, 200.0)
		for s in int(v.x / 200.0) + 2:
			var sx := float(s) * 200.0 - xo
			ci.draw_line(Vector2(sx, yy2), Vector2(sx + 90.0, yy2 + sin(t * 5.0 + float(s + q)) * 1.5), Color(1.0, 1.0, 0.95, 0.05), 3.0)


# ---- האחוזה: קאסקו, טחנות, אסם, ממגורות ----
static func mid_casco(ci: CanvasItem, sc: float, v: Vector2, y: float, t: float) -> void:
	var period := 1450.0
	var start := int(floor(sc / period)) - 1
	for k in range(start, start + int(ceil(v.x / period)) + 2):
		var bx := float(k) * period - sc
		# הקאסקו: בית לבן נמוך, גג רעפים אדום, גלריה עם עמודים וצל עמוק, תריסים ירוקים
		var hx := bx + 80.0
		ci.draw_rect(Rect2(hx, y - 100.0, 360.0, 92.0), Color("ece4cc"))
		ci.draw_colored_polygon(PackedVector2Array([Vector2(hx - 20, y - 100), Vector2(hx + 50, y - 140), Vector2(hx + 310, y - 140), Vector2(hx + 380, y - 100)]), Color("a8462a"))
		for q in 18:   # שורות רעפים
			ci.draw_line(Vector2(hx + 30.0 + float(q) * 17.0, y - 138.0), Vector2(hx - 6.0 + float(q) * 21.0, y - 101.0), Color("8a3620"), 1.4)
		ci.draw_rect(Rect2(hx - 10.0, y - 64.0, 380.0, 6.0), Color("8a3620"))   # גג הגלריה
		ci.draw_rect(Rect2(hx, y - 58.0, 360.0, 50.0), Color(0.3, 0.24, 0.18, 0.55))   # הצל בגלריה
		for q in 8:
			ci.draw_rect(Rect2(hx + 2.0 + float(q) * 50.0, y - 58.0, 7.0, 50.0), Color("d8cdb0"))
		for q in 4:   # חלונות עם תריסים ירוקים
			var wx := hx + 40.0 + float(q) * 84.0
			ci.draw_rect(Rect2(wx, y - 50.0, 20.0, 28.0), Color("2a2018"))
			ci.draw_rect(Rect2(wx - 9.0, y - 50.0, 8.0, 28.0), Color("3a6a4a"))
			ci.draw_rect(Rect2(wx + 21.0, y - 50.0, 8.0, 28.0), Color("3a6a4a"))
		ci.draw_rect(Rect2(hx + 300.0, y - 160.0, 16.0, 30.0), Color("d8cdb0"))   # ארובה
		# פעמון על קשת קטנה + דגל ארגנטינה דהוי שמתנופף
		ci.draw_rect(Rect2(hx + 170.0, y - 168.0, 4.0, 30.0), Color("d8cdb0"))
		ci.draw_rect(Rect2(hx + 190.0, y - 168.0, 4.0, 30.0), Color("d8cdb0"))
		ci.draw_arc(Vector2(hx + 182.0, y - 168.0), 10.0, PI, TAU, 8, Color("d8cdb0"), 4.0)
		ci.draw_circle(Vector2(hx + 182.0 + sin(t * 1.3) * 1.5, y - 158.0), 5.0, Color("8a6a2a"))
		var fx := hx + 60.0
		ci.draw_line(Vector2(fx, y - 140.0), Vector2(fx, y - 215.0), Color("5a5a5a"), 2.0)
		for s in 3:
			var pts := PackedVector2Array()
			for i in 7:
				var xx := float(i) * 8.0
				pts.append(Vector2(fx + xx, y - 214.0 + float(s) * 7.0 + sin(t * 3.0 + xx * 0.12) * 2.5 * (xx / 48.0)))
			ci.draw_polyline(pts, Color(0.55, 0.75, 0.9) if s != 1 else Color(0.95, 0.95, 0.92), 7.0)
		# טחנת רוח אוסטרלית + מיכל מים עגול
		var wx2 := bx + 600.0
		var top := y - 190.0
		for sd in [-1.0, 1.0]:
			ci.draw_line(Vector2(wx2 + sd * 24.0, y - 6.0), Vector2(wx2 + sd * 3.0, top), Color("6a6e72"), 3.0)
		for q in 5:
			var yy := y - 6.0 - float(q + 1) * 34.0
			var ww := lerpf(24.0, 3.0, float(q + 1) / 5.5)
			ci.draw_line(Vector2(wx2 - ww, yy), Vector2(wx2 + ww, yy + 34.0), Color("6a6e72"), 1.2)
			ci.draw_line(Vector2(wx2 + ww, yy), Vector2(wx2 - ww, yy + 34.0), Color("6a6e72"), 1.2)
		var spin := t * 0.9 + float(k)   # כמעט בלי רוח - מסתובבת לאט
		for q in 14:
			var a := spin + float(q) / 14.0 * TAU
			ci.draw_line(Vector2(wx2, top), Vector2(wx2, top) + Vector2.from_angle(a) * 34.0, Color("8a8e92"), 3.0)
		ci.draw_arc(Vector2(wx2, top), 34.0, 0, TAU, 22, Color("7a7e82"), 1.5)
		ci.draw_colored_polygon(PackedVector2Array([Vector2(wx2, top - 3), Vector2(wx2 - 56, top - 10), Vector2(wx2 - 56, top + 9), Vector2(wx2, top + 3)]), Color("8a8e92"))
		ci.draw_rect(Rect2(wx2 + 40.0, y - 46.0, 120.0, 40.0), Color("8a8e8a"))   # טנק אוסטרלי
		for q in 6:
			ci.draw_line(Vector2(wx2 + 40.0, y - 40.0 + float(q) * 6.0), Vector2(wx2 + 160.0, y - 40.0 + float(q) * 6.0), Color("7a7e7a"), 1.0)
		ci.draw_rect(Rect2(wx2 + 38.0, y - 48.0, 124.0, 4.0), Color("a8aca8"))
		# אסם אדום-חום
		var gx := bx + 830.0
		ci.draw_rect(Rect2(gx, y - 120.0, 190.0, 112.0), Color("9a4a30"))
		ci.draw_colored_polygon(PackedVector2Array([Vector2(gx - 10, y - 120), Vector2(gx + 95, y - 168), Vector2(gx + 200, y - 120)]), Color("7a3a24"))
		ci.draw_rect(Rect2(gx + 65.0, y - 76.0, 60.0, 68.0), Color("3a2418"))
		ci.draw_line(Vector2(gx + 65.0, y - 76.0), Vector2(gx + 125.0, y - 8.0), Color("e8dcc0"), 2.0)
		ci.draw_line(Vector2(gx + 125.0, y - 76.0), Vector2(gx + 65.0, y - 8.0), Color("e8dcc0"), 2.0)
		ci.draw_rect(Rect2(gx + 82.0, y - 140.0, 26.0, 20.0), Color("3a2418"))
		# ממגורות תבואה מפח עם ברק שמש
		for q in 3:
			var sx := bx + 1100.0 + float(q) * 70.0
			var sh := 170.0 + float(q % 2) * 30.0
			ci.draw_rect(Rect2(sx, y - sh, 56.0, sh - 8.0), Color("b4b8b8"))
			ci.draw_colored_polygon(PackedVector2Array([Vector2(sx - 3, y - sh), Vector2(sx + 28, y - sh - 26), Vector2(sx + 59, y - sh)]), Color("a0a4a4"))
			for r in int(sh / 14.0):
				ci.draw_line(Vector2(sx, y - sh + float(r) * 14.0), Vector2(sx + 56.0, y - sh + float(r) * 14.0), Color("9a9e9e"), 1.0)
			ci.draw_rect(Rect2(sx + 8.0, y - sh, 7.0, sh - 8.0), Color(1.0, 1.0, 1.0, 0.25 + 0.1 * sin(t * 0.5 + float(q))))
		Kit.smoke_column(ci, Vector2(bx + 980.0, y - 10.0), t, 120.0, Color(0.85, 0.76, 0.58, 0.18), 70.0)   # אבק מהחצר
	ci.draw_rect(Rect2(0, y - 8.0, v.x, v.y - y + 8.0), Color("b09a68"))
	ci.draw_line(Vector2(0, y - 8.0), Vector2(v.x, y - 8.0), Color("9a845a"), 2.0)


# ---- גדר תיל, קוצים, גלגלי קוצים וגולגולות ----
static func near_fence(ci: CanvasItem, sc: float, v: Vector2, y: float, t: float) -> void:
	var period := 260.0
	var start := int(floor(sc / period)) - 1
	for k in range(start, start + int(ceil(v.x / period)) + 2):
		var x := float(k) * period - sc
		# עמוד גדר + שלושה חוטי תיל
		var px := x + 200.0
		ci.draw_rect(Rect2(px - 4.0, y - 62.0, 8.0, 62.0), Color("5a4430"))
		ci.draw_rect(Rect2(px - 4.0, y - 62.0, 3.0, 62.0), Color("6e5640"))
		for wy in [y - 54.0, y - 38.0, y - 22.0]:
			ci.draw_line(Vector2(px - 256.0, wy + 2.0), Vector2(px, wy), Color("4a4440"), 1.0)
		if _h(k, 4) < 0.3:   # גולגולת בקר על העמוד
			var sk := Vector2(px, y - 70.0)
			ci.draw_colored_polygon(Art.ellipse(sk, 8.0, 6.0, 0.0, 10), BONE)
			ci.draw_line(sk + Vector2(-6, -3), sk + Vector2(-18, -10), BONE, 2.4)
			ci.draw_line(sk + Vector2(6, -3), sk + Vector2(18, -10), BONE, 2.4)
			ci.draw_circle(sk + Vector2(-3, -1), 1.6, Color("2a2018"))
			ci.draw_circle(sk + Vector2(3, -1), 1.6, Color("2a2018"))
		# קרדו: קוץ עם פרח סגול שמתנדנד ברוח חמה
		var cx := x + 60.0 + _h(k, 5) * 70.0
		var chh := 36.0 + _h(k, 6) * 26.0
		var sw := sin(t * 1.6 + float(k)) * 3.0
		ci.draw_line(Vector2(cx, y), Vector2(cx + sw, y - chh), Color("5a6a42"), 2.0)
		for q in 4:
			var ly := y - 6.0 - float(q) * chh * 0.2
			var d := 1.0 if q % 2 == 0 else -1.0
			ci.draw_colored_polygon(PackedVector2Array([Vector2(cx + sw * float(q) / 4.0, ly), Vector2(cx + d * 14.0, ly - 6.0), Vector2(cx + d * 8.0, ly - 2.0), Vector2(cx + d * 12.0, ly + 2.0)]), Color("6a7a4e"))
		var fl := Vector2(cx + sw, y - chh)
		ci.draw_circle(fl + Vector2(0, 4), 5.0, Color("6a7a4e"))
		for q in 7:
			var a := -PI * 0.5 + (float(q) - 3.0) * 0.32
			ci.draw_line(fl, fl + Vector2.from_angle(a) * 8.0, Color("a050b0"), 2.0)
		if _h(k, 8) < 0.2:   # גולגולת על הקרקע
			var gs := Vector2(x + 140.0, y - 4.0)
			ci.draw_colored_polygon(Art.ellipse(gs, 10.0, 5.0, 0.2, 10), BONE)
			ci.draw_line(gs + Vector2(-8, -2), gs + Vector2(-20, -8), BONE, 2.0)
			ci.draw_circle(gs + Vector2(2, -1), 1.5, Color("2a2018"))
	ci.draw_rect(Rect2(0, y, v.x, v.y - y), Color("7a6040"))
	# גלגלי קוצים מתגלגלים ברוח (זזים בעצמם, לא רק עם הגלילה)
	for i in 3:
		var rr := 14.0 + float(i) * 4.0
		var gx := fposmod(float(i) * 610.0 + t * (70.0 + float(i) * 25.0) - sc, v.x + 400.0) - 200.0
		var gy := y - rr - absf(sin(t * 3.2 + float(i) * 2.0)) * (8.0 + float(i) * 3.0)
		var rot := gx / rr
		for q in 9:
			var a := rot + float(q) * 0.7
			ci.draw_arc(Vector2(gx, gy) + Vector2.from_angle(a) * rr * 0.3, rr * 0.75, a, a + 2.6, 8, Color("8a7046"), 1.2)
		ci.draw_arc(Vector2(gx, gy), rr, 0, TAU, 16, Color(0.55, 0.44, 0.27, 0.8), 1.4)


# ============================================================
#  עולם
# ============================================================
class RanchGround extends Node2D:
	var w := 1024.0
	var depth := 90.0
	var seed_v := 0

	func _ready() -> void:
		z_index = 1

	func _draw() -> void:
		draw_rect(Rect2(0, 0, w, depth), DIRT_D)
		draw_rect(Rect2(0, 0, w, 14.0), DIRT)
		draw_rect(Rect2(0, 0, w, 3.0), DIRT.lightened(0.12))
		var r := RandomNumberGenerator.new()
		r.seed = seed_v
		for i in int(w / 60.0):   # סדקים באדמה היבשה
			var cx := r.randf_range(0.0, w)
			var pts := PackedVector2Array([Vector2(cx, 3.0)])
			for q in 4:
				pts.append(pts[q] + Vector2(r.randf_range(-8.0, 8.0), r.randf_range(3.0, 7.0)))
			draw_polyline(pts, Color(0.35, 0.26, 0.16, 0.55), 1.0)
		for i in int(w / 45.0):   # עקבות פרסות
			var hx := r.randf_range(0.0, w)
			draw_arc(Vector2(hx, 6.0), 3.0, 0.3, PI - 0.3, 6, Color(0.4, 0.3, 0.2, 0.5), 1.2)
		for i in int(w / 18.0):   # קש
			var sx := r.randf_range(0.0, w)
			draw_line(Vector2(sx, 1.0), Vector2(sx + r.randf_range(-6.0, 6.0), r.randf_range(-1.0, 3.0)), Color(0.85, 0.72, 0.4, 0.8), 1.0)
		for i in int(w / 36.0):
			draw_circle(Vector2(r.randf_range(0.0, w), r.randf_range(20.0, depth - 8.0)), r.randf_range(1.5, 3.5), Color("5e4a30"))


# ---- מגדל מים מעץ (הבמה = add_floor) ----
class WaterTower extends Node2D:
	var w := 220.0
	var tier := 150.0
	var _t := 0.0

	func _ready() -> void:
		z_index = -1

	func _process(delta: float) -> void:
		_t += delta
		if Art.on_screen(self, global_position + Vector2(w * 0.5, -tier), w) and Engine.get_process_frames() % 6 == 0:
			queue_redraw()

	func _draw() -> void:
		for lx in [12.0, w * 0.5 - 4.0, w - 20.0]:   # רגליים
			draw_rect(Rect2(lx, -tier, 9.0, tier), WOOD_D)
		for q in 2:   # חיזוקי X
			var y0 := -tier + 10.0 + float(q) * tier * 0.48
			var y1 := y0 + tier * 0.45
			draw_line(Vector2(16, y0), Vector2(w * 0.5, y1), WOOD, 3.0)
			draw_line(Vector2(w * 0.5, y0), Vector2(16, y1), WOOD, 3.0)
			draw_line(Vector2(w * 0.5, y0), Vector2(w - 16, y1), WOOD, 3.0)
			draw_line(Vector2(w - 16, y0), Vector2(w * 0.5, y1), WOOD, 3.0)
		# הטנק: חביות עץ ענקית מאחורי הבמה (לא חוסמת)
		var tx := w * 0.5
		var tw := w * 0.36
		draw_rect(Rect2(tx - tw, -tier - 120.0, tw * 2.0, 112.0), Color("8a6440"))
		for q in int(tw * 2.0 / 12.0):
			draw_line(Vector2(tx - tw + float(q) * 12.0, -tier - 120.0), Vector2(tx - tw + float(q) * 12.0, -tier - 8.0), Color("6e4e30"), 1.4)
		for yy in [-tier - 104.0, -tier - 60.0, -tier - 20.0]:   # חישוקי ברזל
			draw_rect(Rect2(tx - tw - 2.0, yy, tw * 2.0 + 4.0, 4.0), Color("3a3634"))
		draw_colored_polygon(PackedVector2Array([Vector2(tx - tw - 8.0, -tier - 120.0), Vector2(tx, -tier - 160.0), Vector2(tx + tw + 8.0, -tier - 120.0)]), Color("6a6e70"))
		draw_string(ThemeDB.fallback_font, Vector2(tx - 30.0, -tier - 70.0), "LA PATRONA", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("e8dcc0"))
		# טפטוף מהברז
		var k := fmod(_t * 1.4, 1.0)
		draw_line(Vector2(tx + tw - 6.0, -tier - 12.0), Vector2(tx + tw + 6.0, -tier - 12.0), Color("3a3634"), 3.0)
		draw_circle(Vector2(tx + tw + 6.0, -tier - 8.0 + k * (tier + 4.0)), 2.0, Color(0.6, 0.75, 0.85, 0.8 * (1.0 - k)))
		# הבמה
		draw_rect(Rect2(-6, -tier, w + 12.0, 10.0), WOOD)
		draw_rect(Rect2(-6, -tier + 10.0, w + 12.0, 4.0), WOOD_D)
		for q in int(w / 20.0) + 1:
			draw_line(Vector2(-6.0 + float(q) * 20.0, -tier), Vector2(-6.0 + float(q) * 20.0, -tier + 10.0), WOOD_D, 1.0)
		draw_line(Vector2(-6, -tier - 26.0), Vector2(w + 6.0, -tier - 26.0), WOOD_D, 3.0)   # מעקה
		for q in 6:
			draw_line(Vector2(-4.0 + float(q) * (w + 8.0) / 5.0, -tier), Vector2(-4.0 + float(q) * (w + 8.0) / 5.0, -tier - 26.0), WOOD_D, 2.0)


# ---- ממגורה עם מסלול הליכה (הקומה = add_floor) ----
class Silo extends Node2D:
	var w := 170.0
	var tier := 170.0

	func _ready() -> void:
		z_index = -1

	func _draw() -> void:
		var h := tier + 190.0
		var c := Color("b8bcbc")
		draw_rect(Rect2(0, -h, w, h), c)
		for r in int(h / 16.0):   # גלי הפח
			draw_line(Vector2(0, -h + float(r) * 16.0), Vector2(w, -h + float(r) * 16.0), Color("a0a4a4"), 1.4)
		draw_rect(Rect2(12.0, -h, 16.0, h), Color(1, 1, 1, 0.3))   # ברק השמש
		draw_rect(Rect2(w - 30.0, -h, 30.0, h), Color(0, 0, 0, 0.12))
		draw_colored_polygon(PackedVector2Array([Vector2(-6, -h), Vector2(w * 0.5, -h - 50.0), Vector2(w + 6.0, -h)]), Color("9ea2a2"))
		draw_rect(Rect2(w * 0.5 - 8.0, -h - 58.0, 16.0, 10.0), Color("8a8e8e"))
		Art.glow(self, Vector2(w * 0.5, -h * 0.55), 20.0, Color(1, 1, 1, 0.1))
		preload("res://effects/s51_decor.gd").brand_mark(self, Vector2(w * 0.5, -h * 0.6), 18.0, Color("7a2a20"), 4.0)
		# מסלול ההליכה
		draw_rect(Rect2(-30, -tier, w + 60.0, 8.0), Color("5a5e60"))
		for q in int((w + 60.0) / 14.0):
			draw_line(Vector2(-30.0 + float(q) * 14.0, -tier), Vector2(-26.0 + float(q) * 14.0, -tier + 8.0), Color("3a3e40"), 1.0)
		draw_line(Vector2(-30, -tier - 26.0), Vector2(w + 30.0, -tier - 26.0), Color("4a4e50"), 2.0)
		for q in 7:
			draw_line(Vector2(-30.0 + float(q) * (w + 60.0) / 6.0, -tier), Vector2(-30.0 + float(q) * (w + 60.0) / 6.0, -tier - 26.0), Color("4a4e50"), 2.0)
		draw_line(Vector2(-26, -tier + 8.0), Vector2(0, -tier + 40.0), Color("4a4e50"), 2.0)   # תומכות
		draw_line(Vector2(w + 26.0, -tier + 8.0), Vector2(w, -tier + 40.0), Color("4a4e50"), 2.0)


# ---- צינור ריקון התבואה (מלכודת) ----
class GrainChute extends Node2D:
	const WARN_T := 0.9
	const POUR_T := 1.6
	const PILE_T := 12.0
	const CD := 7.0
	const W := 54.0                 # רוחב העמוד
	const H := 230.0                # גובה הפתח מעל הכביש
	const DMG := 1
	const DMG_Z := 10
	const TICK := 0.45
	const SLOW := 0.35
	var state := 0                  # 0 = מחכה, 1 = חורק, 2 = שופך, 3 = מתמלא מחדש
	var pours := 0                  # לבדיקות
	var hits := 0
	var buried := 0
	var _t := 0.0
	var _tick := 0.0
	var _pile := 0.0                # גובה ערימת התבואה (0..1)
	var _pile_t := 0.0
	var _tt := 0.0
	var _hatch: StaticBody2D = null

	class Hatch extends StaticBody2D:
		var c = null
		func hit_by_bullet(_p: Vector2, _n: Vector2, _d: Vector2) -> void:
			if c != null and c.state == 0:
				c._start_warn(0.25)

	func _ready() -> void:
		z_index = 4
		add_to_group("hazards")
		var hb := Hatch.new()
		hb.c = self
		hb.collision_layer = 4
		hb.collision_mask = 0
		var cs := CollisionShape2D.new()
		var sh := RectangleShape2D.new()
		sh.size = Vector2(30, 22)
		cs.shape = sh
		cs.position = Vector2(0, -H - 8.0)
		hb.add_child(cs)
		add_child(hb)
		_hatch = hb

	func world_rect() -> Rect2:
		return Rect2(global_position + Vector2(-W * 0.5, -H), Vector2(W, H))

	func danger_at(p: Vector2, margin := 0.0) -> bool:
		return (state == 1 or state == 2) and world_rect().grow(margin).has_point(p)

	func _start_warn(t: float) -> void:
		state = 1
		_t = t
		Sfx.play("rn_creak", global_position + Vector2(0, -H), 0.0, 0.1, 2)

	func _physics_process(delta: float) -> void:
		_t -= delta
		_tick -= delta
		_tt += delta
		var pl := get_tree().get_first_node_in_group("player")
		match state:
			0:
				if pl != null and not pl.dead and absf(pl.global_position.x - global_position.x) < W * 0.6 and absf(pl.global_position.y - global_position.y) < 12.0:
					_start_warn(WARN_T)
			1:
				if Engine.get_physics_frames() % 5 == 0:
					Particles.burst(get_parent(), global_position + Vector2(randf_range(-10, 10), -H + 6.0), "smoke", Vector2.DOWN, 1)
				if _t <= 0.0:
					state = 2
					_t = POUR_T
					pours += 1
					Sfx.play("rn_pour", global_position + Vector2(0, -H * 0.5), 2.0, 0.1, 2)
			2:
				_pile = minf(1.0, _pile + delta / POUR_T)
				_pile_t = PILE_T
				if _tick <= 0.0:
					_tick = TICK
					var r := world_rect()
					if pl != null and not pl.dead and r.intersects(pl.body_rect()):
						hits += 1
						pl.hurt(DMG, Vector2(signf(pl.global_position.x - global_position.x + 0.01) * 0.6, 0.2))
						pl.slow_t = maxf(pl.slow_t, 0.9)
					for z in get_tree().get_nodes_in_group("zombies"):
						if not z.dead and not z.is_boss() and r.has_point(z.global_position + Vector2(0, -10)):
							buried += 1
							z.take_damage(DMG_Z, z.global_position + Vector2(0, -20), Vector2.DOWN, true, {"source": "hazard", "fixed": DMG_Z})
				if _t <= 0.0:
					state = 3
					_t = CD
			3:
				if _t <= 0.0:
					state = 0
		# הערימה מאטה (כמו בוץ) עד שהיא מתפזרת
		if _pile > 0.0:
			_pile_t -= delta
			if _pile_t <= 0.0:
				_pile = maxf(0.0, _pile - delta * 0.3)
			if Engine.get_physics_frames() % 4 == 0 and pl != null and pl.is_on_floor() and absf(pl.global_position.x - global_position.x) < 70.0 * _pile + 10.0 and absf(pl.global_position.y - global_position.y) < 10.0:
				pl.slow_t = maxf(pl.slow_t, SLOW)
		if (state == 1 or state == 2 or _pile > 0.0) and Art.on_screen(self, global_position + Vector2(0, -H * 0.5), H):
			queue_redraw()
		elif Engine.get_physics_frames() % 30 == 0:
			queue_redraw()

	func _draw() -> void:
		# הצינור: יוצא מהממגורה בזווית ונגמר בפתח עם מכסה
		var mouth := Vector2(0, -H)
		draw_line(mouth + Vector2(-90, -70), mouth + Vector2(-6, -10), Color("6a6e70"), 14.0)
		draw_line(mouth + Vector2(-90, -70), mouth + Vector2(-6, -10), Color("8a8e90"), 8.0)
		draw_rect(Rect2(mouth + Vector2(-16, -14), Vector2(32, 16)), Color("5a5e60"))
		var open := 0.0 if state == 0 or state == 3 else (0.4 + 0.2 * sin(_tt * 40.0) if state == 1 else 1.0)
		draw_line(mouth + Vector2(-15, 2), mouth + Vector2(-15, 2) + Vector2.from_angle(open * 1.3) * 30.0, Color("c03a20"), 4.0)   # המכסה (אדום)
		if state == 1:
			draw_string(ThemeDB.fallback_font, mouth + Vector2(-6, -24), "!", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color(1.0, 0.45, 0.2))
			for q in 4:   # טפטוף גרעינים
				var k := fmod(_tt * 2.0 + float(q) * 0.25, 1.0)
				draw_circle(mouth + Vector2(randf_range(-8, 8), 6.0 + k * H * 0.8), 1.5, HAY)
		if state == 2:   # עמוד תבואה
			for q in 26:
				var k2 := fmod(_tt * 3.0 + float(q) * 0.0385, 1.0)
				var xx := sin(float(q) * 2.3) * W * 0.32 * (0.4 + k2 * 0.6)
				draw_circle(mouth + Vector2(xx, 6.0 + k2 * H), 3.0 + k2 * 2.0, HAY.darkened(0.15 * float(q % 3)))
			draw_rect(Rect2(mouth + Vector2(-W * 0.22, 4.0), Vector2(W * 0.44, H - 4.0)), Color(0.85, 0.7, 0.35, 0.35))
			draw_colored_polygon(Art.ellipse(Vector2(0, -6), W * 0.7, 14.0, 0.0, 14), Color(0.9, 0.82, 0.6, 0.35))   # אבק בתחתית
		if _pile > 0.0:   # ערימת תבואה על הכביש
			var ph := 22.0 * _pile
			var pw := 70.0 * _pile + 10.0
			draw_colored_polygon(PackedVector2Array([Vector2(-pw, 2), Vector2(-pw * 0.4, -ph * 0.8), Vector2(0, -ph), Vector2(pw * 0.4, -ph * 0.8), Vector2(pw, 2)]), HAY)
			draw_colored_polygon(PackedVector2Array([Vector2(-pw * 0.6, 2), Vector2(-pw * 0.2, -ph * 0.6), Vector2(pw * 0.1, -ph * 0.7), Vector2(pw * 0.5, 2)]), HAY.darkened(0.12))


# ---- מכלאת הובלה עם שור מת (מלכודת) ----
class Chute extends Node2D:
	const WARN_T := 1.0
	const TRIGGER := 430.0
	const W := 170.0
	var state := 0                  # 0 = סגור, 1 = השער רועד, 2 = פתוח (השור יצא)
	var dir := -1.0                 # לאן השור דוהר (לכיוון השחקן)
	var runs := 0                   # לבדיקות
	var steer: Node = null
	var _t := 0.0
	var _tt := 0.0

	class Latch extends StaticBody2D:
		var c = null
		func hit_by_bullet(_p: Vector2, _n: Vector2, _d: Vector2) -> void:
			if c != null and c.state == 0:
				var pl: Node = c.get_tree().get_first_node_in_group("player")
				c.dir = signf(pl.global_position.x - c.global_position.x) if pl != null else -1.0
				c._open(0.2)

	func _ready() -> void:
		z_index = -1
		add_to_group("hazards")
		var lb := Latch.new()
		lb.c = self
		lb.collision_layer = 4
		lb.collision_mask = 0
		var cs := CollisionShape2D.new()
		var sh := RectangleShape2D.new()
		sh.size = Vector2(12, 16)
		cs.shape = sh
		cs.position = Vector2(0, -50.0)
		lb.add_child(cs)
		add_child(lb)

	func world_rect() -> Rect2:
		if steer != null and is_instance_valid(steer) and steer.alive():
			return steer.world_rect()
		return Rect2()

	func danger_at(p: Vector2, margin := 0.0) -> bool:
		return state == 1 and absf(p.x - global_position.x) < 80.0 + margin

	func _open(t: float) -> void:
		state = 1
		_t = t
		Sfx.play("rn_bellow", global_position + Vector2(0, -40), 2.0, 0.1, 2)
		var pl := get_tree().get_first_node_in_group("player")
		if pl != null and pl.has_method("_say") and pl.global_position.distance_to(global_position) < 700.0:
			pl._say("STEER!  JUMP IT", Color("ffb050"))

	func _physics_process(delta: float) -> void:
		_t -= delta
		_tt += delta
		match state:
			0:
				var pl := get_tree().get_first_node_in_group("player")
				if pl != null and not pl.dead:
					var dx: float = pl.global_position.x - global_position.x
					if absf(dx) < TRIGGER and absf(pl.global_position.y - global_position.y) < 200.0:
						dir = signf(dx) if dx != 0.0 else -1.0
						_open(WARN_T)
			1:
				if _t <= 0.0:
					state = 2
					runs += 1
					var s := Steer.new()
					s.dir = dir
					get_parent().add_child(s)
					s.global_position = global_position + Vector2(dir * 30.0, 0)
					steer = s
					Sfx.play("rn_bellow", global_position, 5.0, 0.1, 2, 0.8)
		if state == 1 or (Art.on_screen(self, global_position, 200.0) and Engine.get_physics_frames() % 20 == 0):
			queue_redraw()

	func _draw() -> void:
		# מכלאה צרה מקרשים + רמפה + שער
		var shake := sin(_tt * 50.0) * 2.0 if state == 1 else 0.0
		for q in 6:
			draw_rect(Rect2(-W * 0.5 + float(q) * W / 5.0 - 4.0, -96.0, 8.0, 96.0), WOOD_D)
		for yy in [-88.0, -64.0, -40.0, -18.0]:
			draw_rect(Rect2(-W * 0.5, yy, W, 7.0), WOOD)
		if state < 2:   # ראש השור מציץ בין הקרשים
			var hp := Vector2(-dir * 30.0 + shake, -60.0)
			draw_colored_polygon(Art.ellipse(hp, 12.0, 8.0, 0.0, 12), BONE)
			draw_line(hp + Vector2(-8, -5), hp + Vector2(-26, -14), BONE, 3.0)
			draw_line(hp + Vector2(8, -5), hp + Vector2(26, -14), BONE, 3.0)
			draw_circle(hp + Vector2(-4, -1), 2.0, Color(1.0, 0.3, 0.2))
			draw_circle(hp + Vector2(4, -1), 2.0, Color(1.0, 0.3, 0.2))
		# השער (בצד שאליו השור יוצא)
		var gx := dir * W * 0.5
		if state < 2:
			draw_rect(Rect2(gx - 5.0 + shake, -92.0, 10.0, 92.0), Color("8a2a20"))
			draw_rect(Rect2(gx - 9.0 + shake, -56.0, 18.0, 10.0), Color("3a3634"))   # הבריח
			if state == 1:
				draw_string(ThemeDB.fallback_font, Vector2(gx - 6.0, -110.0), "!", HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color(1.0, 0.45, 0.2))
		else:
			draw_line(Vector2(gx, -92.0), Vector2(gx + dir * 60.0, -86.0), Color("8a2a20"), 6.0)
		preload("res://effects/s51_decor.gd").brand_mark(self, Vector2(0, -78.0), 8.0, Color("7a2a20"), 2.0)


# שור מת שדוהר לאורך הכביש: פוגע בך (אם לא קפצת), דורס זומבים, נעצר בקיר. אפשר להרוג אותו.
class Steer extends Node2D:
	const SPEED := 470.0
	const SPAN := 1500.0
	const DMG := 2
	const DMG_Z := 45
	const H := 46.0                 # גובה הגוף - קופצים מעליו
	const STEER_HP := 45
	var dir := -1.0
	var hp := STEER_HP
	var hit_p := false
	var hits := 0                   # לבדיקות
	var crushed := 0
	var _d := 0.0
	var _ph := 0.0
	var _dead_t := -1.0
	var _body: StaticBody2D = null

	class Hide extends StaticBody2D:
		var s = null
		func take_damage(amount: int, hit_pos: Vector2, dir: Vector2, explosive := false, src := {}) -> void:
			if s != null:
				s.hurt_by(amount, hit_pos, dir, explosive, src)

	func _ready() -> void:
		z_index = 6
		var b := Hide.new()
		b.s = self
		b.collision_layer = 4
		b.collision_mask = 0
		var cs := CollisionShape2D.new()
		var sh := RectangleShape2D.new()
		sh.size = Vector2(70, 40)
		cs.shape = sh
		cs.position = Vector2(0, -30)
		b.add_child(cs)
		add_child(b)
		_body = b

	func alive() -> bool:
		return _dead_t < 0.0

	func world_rect() -> Rect2:
		return Rect2(global_position + Vector2(-40, -H), Vector2(80, H))

	func hurt_by(amount: int, hit_pos: Vector2, d: Vector2, explosive: bool, src: Dictionary) -> void:
		if not alive():
			return
		var dmg := amount
		if src.has("fixed"):
			dmg = int(src.fixed)
		elif not explosive:
			dmg = 9
		hp -= maxi(dmg, 1)
		Particles.burst(get_parent(), hit_pos, "hit", d, 6)
		if hp <= 0:
			_die()

	func _die() -> void:
		_dead_t = 0.0
		Sfx.play("rn_bellow", global_position, 0.0, 0.1, 2, 0.7)
		Particles.burst(get_parent(), global_position + Vector2(0, -10), "smoke", Vector2.UP, 8)
		if is_instance_valid(_body):
			_body.queue_free()

	func _physics_process(delta: float) -> void:
		if not alive():
			_dead_t += delta
			if _dead_t > 6.0:
				modulate.a = maxf(0.0, 1.0 - (_dead_t - 6.0))
				if _dead_t > 7.0:
					queue_free()
					return
			if Engine.get_physics_frames() % 10 == 0:
				queue_redraw()
			return
		var step := dir * SPEED * delta
		var from := global_position + Vector2(dir * 36.0, -20.0)
		var hit := get_world_2d().direct_space_state.intersect_ray(PhysicsRayQueryParameters2D.create(from, from + Vector2(step + dir * 4.0, 0), 1))
		if not hit.is_empty() or _d > SPAN:   # נכנס במכשול / קיר - מתמוטט
			var cam := get_viewport().get_camera_2d()
			if cam != null and cam.has_method("shake") and Art.on_screen(self, global_position):
				cam.shake(6.0, 0.25)
			Sfx.play("tr_slam" if Sfx.has_sound("tr_slam") else "land", global_position, 2.0)
			_die()
			return
		global_position.x += step
		_d += absf(step)
		_ph += delta * 16.0
		var r := world_rect()
		var pl := get_tree().get_first_node_in_group("player")
		if pl != null and not pl.dead and not hit_p and r.intersects(pl.body_rect()) and pl._roll_t <= 0.0:
			hit_p = true
			hits += 1
			pl.hurt(DMG, Vector2(dir * 2.4, -1.4))
		if Engine.get_physics_frames() % 4 == 0:
			for z in get_tree().get_nodes_in_group("zombies"):
				if z.dead or z.is_boss() or z.get_meta("steer_hit", 0) == get_instance_id():
					continue
				if r.has_point(z.global_position + Vector2(0, -6)):
					z.set_meta("steer_hit", get_instance_id())
					crushed += 1
					z.take_damage(DMG_Z, z.global_position + Vector2(0, -20), Vector2(dir, -0.5), true, {"source": "hazard", "fixed": DMG_Z})
					if not z.dead:
						z.velocity = Vector2(dir * 360.0, -280.0)
			if Art.on_screen(self, global_position):
				Particles.burst(get_parent(), global_position + Vector2(-dir * 30.0, -4.0), "smoke", Vector2(-dir, -0.4), 1)
		queue_redraw()

	func _draw() -> void:
		if not alive():   # שוכב על הצד
			draw_set_transform(Vector2(0, -10), dir * 0.5 * PI * 0.9, Vector2(dir, 1))
			draw_steer(self, Vector2(0, 30), 1.0, 1.0, 0.0)
			draw_set_transform_matrix(Transform2D.IDENTITY)
			return
		draw_colored_polygon(Art.ellipse(Vector2(0, -2), 40.0, 5.0, 0.0, 14), Color(0, 0, 0, 0.25))
		draw_steer(self, Vector2(0, -absf(sin(_ph)) * 4.0), 1.0, dir, _ph)

	# שור קריוז'ו מת: קרניים ארוכות, צלעות חשופות, גולגולת, עור כתום-לבן מטולא, סימן האחוזה על הירך
	static func draw_steer(ci: CanvasItem, p: Vector2, s: float, d: float, ph: float) -> void:
		var hide := Color("9a5a30")
		var patch := Color("e2d6bc")
		for q in 4:
			var lx := p.x + (-24.0 + float(q) * 15.0) * s * d
			var sw := sin(ph + float(q) * 1.7) * 9.0 * s
			var knee := Vector2(lx + sw * 0.6 * d, p.y - 12.0 * s)
			ci.draw_line(Vector2(lx, p.y - 26.0 * s), knee, Art.OUTLINE, 5.4 * s)
			ci.draw_line(knee, Vector2(lx + sw * d, p.y), Art.OUTLINE, 4.4 * s)
			ci.draw_line(Vector2(lx, p.y - 26.0 * s), knee, hide.darkened(0.25), 3.6 * s)
			ci.draw_line(knee, Vector2(lx + sw * d, p.y), hide.darkened(0.25), 2.8 * s)
		var body := Art.ellipse(p + Vector2(0, -34) * s, 34.0 * s, 15.0 * s, 0.0, 16)
		Art.fill_shaded(ci, body, hide, 0.14, 0.35)
		ci.draw_colored_polygon(Art.ellipse(p + Vector2(-14.0 * d, -36.0) * s, 12.0 * s, 8.0 * s, 0.3, 10), patch)
		for q in 4:   # צלעות חשופות
			var rx := p.x + (2.0 + float(q) * 6.0) * s * d
			ci.draw_line(Vector2(rx, p.y - 46.0 * s), Vector2(rx - 2.0 * d * s, p.y - 26.0 * s), BONE, 1.6 * s)
		ci.draw_colored_polygon(Art.ellipse(p + Vector2(10.0 * d, -36) * s, 8.0 * s, 6.0 * s, 0.0, 8), Color(0.42, 0.05, 0.05, 0.8))
		preload("res://effects/s51_decor.gd").brand_mark(ci, p + Vector2(-24.0 * d, -34.0) * s, 5.0 * s, Color("3a1a10"), 1.4 * s)
		var head := p + Vector2(40.0 * d, -28.0) * s
		ci.draw_line(p + Vector2(28.0 * d, -40.0) * s, head, hide.darkened(0.15), 9.0 * s)
		Art.fill(ci, Art.ellipse(head, 11.0 * s, 7.0 * s, 0.4 * d, 12), BONE)
		ci.draw_circle(head + Vector2(2.0 * d, -2.0) * s, 2.0 * s, Color(1.0, 0.3, 0.2))
		ci.draw_polyline(PackedVector2Array([head + Vector2(-3.0 * d, -5.0) * s, head + Vector2(-2.0 * d, -14.0) * s, head + Vector2(8.0 * d, -22.0) * s]), BONE, 2.6 * s)   # קרניים ארוכות
		ci.draw_polyline(PackedVector2Array([head + Vector2(-6.0 * d, -5.0) * s, head + Vector2(-16.0 * d, -12.0) * s, head + Vector2(-24.0 * d, -22.0) * s]), BONE.darkened(0.15), 2.6 * s)
		ci.draw_line(p + Vector2(-32.0 * d, -40.0) * s, p + Vector2(-44.0 * d, -30.0 + sin(ph) * 6.0) * s, hide, 2.0 * s)


# ---- שוקת מים: שוטפים בה את הסימון של BRANDER ----
class Trough extends Node2D:
	var w := 96.0
	var washes := 0                 # לבדיקות
	var _splash := 0.0
	var _t := 0.0

	func _ready() -> void:
		z_index = 3
		add_to_group("troughs")

	# האם הנקודה (רגלי השחקן) בתוך השוקת
	func covers(p: Vector2) -> bool:
		return absf(p.x - global_position.x) < w * 0.5 and absf(p.y - global_position.y) < 14.0

	func center() -> Vector2:
		return global_position

	func splash() -> void:
		_splash = 0.6
		washes += 1
		Particles.burst(get_parent(), global_position + Vector2(0, -16), "smoke", Vector2.UP, 3)

	func _process(delta: float) -> void:
		_t += delta
		_splash = maxf(0.0, _splash - delta)
		if Art.on_screen(self, global_position, w) and (Engine.get_process_frames() % 6 == 0 or _splash > 0.0):
			queue_redraw()

	func _draw() -> void:
		var hw := w * 0.5
		draw_line(Vector2(-hw + 8, 0), Vector2(-hw + 12, -10), Color("3a3634"), 3.0)
		draw_line(Vector2(hw - 8, 0), Vector2(hw - 12, -10), Color("3a3634"), 3.0)
		Art.fill(self, PackedVector2Array([Vector2(-hw, -26), Vector2(hw, -26), Vector2(hw - 8, -8), Vector2(-hw + 8, -8)]), Color("7a8a8e"))
		for q in int(w / 10.0):
			draw_line(Vector2(-hw + 6.0 + float(q) * 10.0, -24.0), Vector2(-hw + 9.0 + float(q) * 10.0, -9.0), Color("68787c"), 1.2)
		var wave := sin(_t * 2.0) * 1.0
		draw_rect(Rect2(-hw + 3.0, -26.0 + wave * 0.5, w - 6.0, 4.0), Color(0.45, 0.68, 0.82, 0.9))
		draw_line(Vector2(-hw + 10.0 + fmod(_t * 20.0, w - 20.0), -25.0), Vector2(-hw + 22.0 + fmod(_t * 20.0, w - 20.0), -25.0), Color(1, 1, 1, 0.6), 1.0)
		if _splash > 0.0:
			for q in 6:
				var a := -PI * 0.5 + (float(q) - 2.5) * 0.35
				draw_circle(Vector2(0, -26) + Vector2.from_angle(a) * (1.0 - _splash) * 40.0, 3.0 * _splash + 1.0, Color(0.6, 0.8, 0.95, _splash))


# ---- אסאדו על צלב ברזל מעל גחלים: עשן (smoke_src) ----
class AsadoPit extends Node2D:
	const SMOKE_R := 150.0
	var _t := 0.0

	func _ready() -> void:
		z_index = 2
		add_to_group("smoke_src")

	func smoke_covers(p: Vector2) -> bool:
		return p.distance_to(global_position + Vector2(0, -70)) < SMOKE_R

	func _process(delta: float) -> void:
		_t += delta
		if Art.on_screen(self, global_position + Vector2(0, -80), 200.0) and Engine.get_process_frames() % 3 == 0:
			queue_redraw()

	func _draw() -> void:
		# גחלים
		draw_colored_polygon(Art.ellipse(Vector2(0, -3), 46.0, 7.0, 0.0, 16), Color("2a1a14"))
		for q in 10:
			var gx := -38.0 + float(q) * 8.5
			var g := 0.5 + 0.5 * sin(_t * 3.0 + float(q) * 1.3)
			draw_circle(Vector2(gx, -4.0), 4.0, Color(1.0, 0.35 + 0.25 * g, 0.1, 0.9))
		Art.glow(self, Vector2(0, -10), 60.0, Color(1.0, 0.5, 0.2, 0.18))
		# צלב האסאדור עם טלה (בצד, נטוי מעל הגחלים)
		var base := Vector2(-30, 0)
		var top := Vector2(-8, -110)
		draw_line(base, top, Color("3a3634"), 4.0)
		var mid := base.lerp(top, 0.6)
		draw_line(mid + Vector2(-26, 8), mid + Vector2(28, -8), Color("3a3634"), 3.0)
		var lamb := PackedVector2Array([base.lerp(top, 0.25) + Vector2(-14, 0), base.lerp(top, 0.85) + Vector2(-12, 0), base.lerp(top, 0.9) + Vector2(14, -4), base.lerp(top, 0.3) + Vector2(16, -4)])
		Art.fill_shaded(self, lamb, Color("8a4a24"), 0.18, 0.4)
		for q in 4:
			var rp := base.lerp(top, 0.4 + float(q) * 0.12)
			draw_line(rp + Vector2(-10, 0), rp + Vector2(12, -3), Color("5a2a14"), 1.6)
		# עשן לבן-אפור שעולה ומתפזר (זה מה שמבריח את הדבורים)
		for q in 9:
			var k := fmod(_t * 0.35 + float(q) / 9.0, 1.0)
			var sp := Vector2(sin(_t * 0.8 + float(q)) * 20.0 * k + k * 40.0, -20.0 - k * 200.0)
			draw_circle(sp, 14.0 + k * 40.0, Color(0.88, 0.88, 0.85, 0.32 * (1.0 - k)))


# ---- תיבות כוורת (קישוט) ----
class BeeBoxes extends Node2D:
	var _t := 0.0

	func _ready() -> void:
		z_index = -1

	func _process(delta: float) -> void:
		_t += delta
		if Art.on_screen(self, global_position, 120.0) and Engine.get_process_frames() % 4 == 0:
			queue_redraw()

	func _draw() -> void:
		for q in 3:
			var bx := float(q) * 42.0
			var st := 2 + q % 2
			for s in st:
				var yy := -12.0 - float(s) * 18.0
				draw_rect(Rect2(bx, yy - 6.0, 34.0, 18.0), Color("e8e2d0") if (q + s) % 2 == 0 else Color("8ab0c8"))
				draw_line(Vector2(bx, yy + 12.0), Vector2(bx + 34.0, yy + 12.0), Color("8a8270"), 1.0)
			draw_rect(Rect2(bx - 2.0, -18.0 * float(st) - 20.0, 38.0, 5.0), Color("6a6250"))
			draw_rect(Rect2(bx + 2.0, -6.0, 4.0, 6.0), WOOD_D)
			draw_rect(Rect2(bx + 28.0, -6.0, 4.0, 6.0), WOOD_D)
		for i in 14:   # דבורים
			var a := _t * (2.0 + float(i % 3)) + float(i) * 1.7
			var p := Vector2(60.0 + cos(a) * (30.0 + float(i % 4) * 10.0), -50.0 + sin(a * 1.3) * 22.0)
			draw_circle(p, 1.4, Color("2a2010"))


# ---- לול תרנגולות (קישוט) ----
class Coop extends Node2D:
	var _t := 0.0

	func _ready() -> void:
		z_index = -1

	func _process(delta: float) -> void:
		_t += delta
		if Art.on_screen(self, global_position, 160.0) and Engine.get_process_frames() % 5 == 0:
			queue_redraw()

	func _draw() -> void:
		draw_rect(Rect2(0, -70, 120, 70), Color("8a6a46"))
		draw_colored_polygon(PackedVector2Array([Vector2(-8, -70), Vector2(60, -96), Vector2(128, -70)]), Color("7a7e80"))
		for q in 6:
			draw_line(Vector2(float(q) * 20.0, -70), Vector2(float(q) * 20.0, 0), Color("6a4e32"), 1.4)
		draw_rect(Rect2(46, -40, 26, 40), Color("2a1e14"))
		draw_line(Vector2(120, -10), Vector2(170, -10), Color("6a6e70"), 1.0)   # רשת
		for q in 3:   # תרנגולות מנקרות
			var cx := 135.0 + float(q) * 14.0 + sin(_t * 0.6 + float(q)) * 6.0
			var peck := absf(sin(_t * 3.0 + float(q) * 2.0)) > 0.8
			draw_colored_polygon(Art.ellipse(Vector2(cx, -8), 6.0, 5.0, 0.0, 10), Color("e8e2d6"))
			var hp := Vector2(cx + 5.0, -10.0 if not peck else -4.0)
			draw_circle(hp, 3.0, Color("e8e2d6"))
			draw_circle(hp + Vector2(0, -3), 1.4, Color("c02020"))
			draw_line(hp + Vector2(2, 0), hp + Vector2(5, 1), Color("d8a020"), 1.4)


# ---- זירת האילוף (הבוס) ----
class DomaArena extends Node2D:
	var w := 900.0

	func _ready() -> void:
		z_index = -1

	func _draw() -> void:
		var wood := Color("6a4a2e")
		for q in int(w / 60.0) + 1:   # גדר עגולה של מכלאת האילוף
			var x := float(q) * 60.0
			draw_rect(Rect2(x - 5.0, -120.0, 10.0, 120.0), wood)
		for yy in [-110.0, -80.0, -50.0, -22.0]:
			draw_rect(Rect2(0, yy, w, 7.0), wood.lightened(0.1))
		# שער כניסה עם קשת וסימן האחוזה
		var gx := w * 0.5
		draw_rect(Rect2(gx - 120.0, -230.0, 16.0, 230.0), WOOD_D)
		draw_rect(Rect2(gx + 104.0, -230.0, 16.0, 230.0), WOOD_D)
		draw_rect(Rect2(gx - 136.0, -236.0, 272.0, 22.0), WOOD_D)
		draw_rect(Rect2(gx - 90.0, -210.0, 180.0, 30.0), Color("e8dcc0"))
		draw_string(ThemeDB.fallback_font, Vector2(gx - 78.0, -188.0), "LA PATRONA", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color("6a1a14"))
		preload("res://effects/s51_decor.gd").brand_mark(self, Vector2(gx, -262.0), 16.0, Color("2a1a10"), 4.0)
		for q in 2:   # גולגולות על השער
			var sx := gx + (-112.0 if q == 0 else 112.0)
			draw_colored_polygon(Art.ellipse(Vector2(sx, -248.0), 9.0, 7.0, 0.0, 10), BONE)
			draw_line(Vector2(sx - 6.0, -252.0), Vector2(sx - 18.0, -262.0), BONE, 2.4)
			draw_line(Vector2(sx + 6.0, -252.0), Vector2(sx + 18.0, -262.0), BONE, 2.4)


# ---- מכשולים ----
class Obstacle extends Node2D:
	var kind := "bales"
	var size := Vector2(80, 60)
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
			"bales":   # חבילות חציר מרובעות בערימה (שתיים למטה, אחת למעלה)
				var bh := h * 0.5
				for q in 3:
					var r := Rect2(float(q % 2) * w * 0.5, -bh, w * 0.5, bh) if q < 2 else Rect2(w * 0.22, -h, w * 0.56, bh)
					draw_rect(r, HAY)
					draw_rect(Rect2(r.position, Vector2(r.size.x, 3.0)), HAY.lightened(0.15))
					draw_rect(r, Color("a88a3a"), false, 1.4)
					draw_line(r.position + Vector2(r.size.x * 0.3, 0), r.position + Vector2(r.size.x * 0.3, r.size.y), Color("7a5a2a"), 1.2)   # חוטים
					draw_line(r.position + Vector2(r.size.x * 0.7, 0), r.position + Vector2(r.size.x * 0.7, r.size.y), Color("7a5a2a"), 1.2)
					for s in 5:
						var sx := r.position.x + float((s * 13 + seed_v) % int(maxf(r.size.x, 1.0)))
						draw_line(Vector2(sx, r.position.y), Vector2(sx + 3.0, r.position.y - 3.0), HAY.lightened(0.2), 1.0)
			"drums":   # חביות דלק חלודות
				for q in 2:
					var dx := float(q) * w * 0.5
					var col := Color("8a3a26") if q == 0 else Color("3a5a6a")
					draw_rect(Rect2(dx + 2.0, -h, w * 0.5 - 4.0, h), col)
					draw_rect(Rect2(dx + 2.0, -h, 5.0, h), Color(1, 1, 1, 0.15))
					for yy in [-h + 4.0, -h * 0.5, -6.0]:
						draw_rect(Rect2(dx + 2.0, yy, w * 0.5 - 4.0, 3.0), col.darkened(0.3))
					draw_circle(Vector2(dx + w * 0.3, -h * 0.65), 3.5, Color("6a3a1a"))   # חלודה
			_:   # טרקטור ישן וחלוד
				var c := Color("a83a22")
				draw_rect(Rect2(w * 0.32, -h * 0.75, w * 0.5, h * 0.32), c)
				draw_rect(Rect2(w * 0.32, -h * 0.75, w * 0.5, 4.0), c.lightened(0.15))
				draw_rect(Rect2(w * 0.08, -h, w * 0.3, h * 0.6), Color("3a3634"), false, 3.0)   # תא
				draw_line(Vector2(w * 0.7, -h * 0.75), Vector2(w * 0.7, -h * 1.05), Color("2a2624"), 4.0)   # אגזוז
				draw_circle(Vector2(w * 0.24, -h * 0.34), h * 0.34, Color("2a2624"))   # גלגל אחורי גדול
				draw_circle(Vector2(w * 0.24, -h * 0.34), h * 0.18, Color("7a2a1a"))
				for q in 10:
					var a := float(q) / 10.0 * TAU
					draw_line(Vector2(w * 0.24, -h * 0.34) + Vector2.from_angle(a) * h * 0.3, Vector2(w * 0.24, -h * 0.34) + Vector2.from_angle(a) * h * 0.36, Color("1a1614"), 3.0)
				draw_circle(Vector2(w * 0.78, -h * 0.18), h * 0.18, Color("2a2624"))   # גלגל קדמי
				draw_circle(Vector2(w * 0.78, -h * 0.18), h * 0.08, Color("7a2a1a"))
				for q in 3:   # חלודה
					draw_circle(Vector2(w * (0.4 + 0.12 * float(q)), -h * 0.6), 3.0 + float(q), Color(0.4, 0.2, 0.1, 0.5))


# ---- אבק באוויר, משב אבק וסנוור (מסך) ----
class RanchFX extends Node2D:
	const GUST_EVERY := Vector2(12.0, 18.0)
	var vp := Vector2(1280, 720)
	var gusts := 0                  # לבדיקות
	var _t := 0.0
	var _next := 9.0
	var _gust := -1.0

	func _process(delta: float) -> void:
		_t += delta
		_next -= delta
		if _next <= 0.0:
			_next = randf_range(GUST_EVERY.x, GUST_EVERY.y)
			_gust = 0.0
			gusts += 1
		if _gust >= 0.0:
			_gust += delta
			if _gust > 3.0:
				_gust = -1.0
		if Engine.get_process_frames() % 2 == 0:
			queue_redraw()

	func _draw() -> void:
		var n := int(26.0 * clampf(Quality.ambient(), 0.3, 1.0))   # (אבק = לא דם: יורד כשהמשחק איטי)
		for i in n:
			var x := fposmod(float(i) * 97.0 - _t * (18.0 + float(i % 5) * 6.0), vp.x)
			var y := fposmod(float(i) * 61.0 + sin(_t * 0.7 + float(i)) * 30.0, vp.y)
			draw_circle(Vector2(x, y), 1.0 + float(i % 3) * 0.6, Color(1.0, 0.95, 0.8, 0.35))
		if _gust >= 0.0:   # משב אבק שעובר על המסך מימין לשמאל
			var k := _gust / 3.0
			var gx := lerpf(vp.x + 300.0, -600.0, k)
			for q in 7:
				draw_colored_polygon(Art.ellipse(Vector2(gx + float(q) * 70.0, vp.y * 0.78 - float(q % 3) * 40.0), 160.0, 60.0, 0.0, 16), Color(0.85, 0.74, 0.55, 0.12 * sin(k * PI)))
		draw_rect(Rect2(0, 0, vp.x, vp.y), Color(1.0, 0.92, 0.7, 0.05))   # חום
