extends RefCounted
# ============================================================
#  קישוטים לשלב 52 ("RAIL YARD") - מגרש רכבות המשא הענק בקצה בואנוס איירס (בהשראת הסדנאות של רמדיוס דה אסקלדה
#  ומגרש המשא של רטירו). דמדומים כתומים של סמוג שהופכים לערב של פנסי נתרן. אזור שישי, שלב 7.
#  המתים עולים על הרכבות דרומה - ומישהו מנהל להם את לוח הזמנים.
#    yard_sky      - (רקע) שמיים של סמוג: שמש אדומה נמוכה ששוקעת לאט, פסי סמוג, ציפורים. עם הזמן (DUSK_T) מחשיך,
#                    זוהר הנתרן עולה מהאופק וכוכבים ראשונים
#    far_city      - (רקע, 0.06) קו הרקיע של בואנוס איירס (חלונות נדלקים עם הזמן), ארובות עם עשן ונורות אדומות,
#                    רכבת נוסעים רחוקה עם חלונות מוארים שחוצה על גשר
#    mid_yard      - (רקע, 0.28) בית הקטרים העגול (רוטונדה) עם שערים קשתיים, מגדל מים של הרכבת, שורות קרונות,
#                    עמודי חשמל עיליים - ופעם בכמה זמן (TRAIN_EVERY) רכבת משא מלאה זומבים נוסעת דרומה לאט
#                    (גופות על הגגות, ידיים תלויות מהדלתות)
#    near_rails    - (רקע, 0.6) מסילות ואדנים, עמודי איתות מהבהבים, אדים מפתחי אוורור, עשבים וגרוטאות
#    yard_overlay  - אובך נתרן כתום מאחורי הדמויות (שהצלליות ייקראו)
#    YardGround    - (עולם) חצץ מסילה עם פסי ברזל ואדנים בתוך הכביש
#    Boxcar        - (עולם) קרון משא חלוד עם גרפיטי. הגג = קומה (add_floor בשלב)
#    Gantry        - (עולם) גשר איתות מעל המסילות: שני מגדלי סריג ומסלול הליכה (קומה), ראשי איתות שמתחלפים לפי "לוח הזמנים"
#    Hopper        - (עולם) מגדל פחם (הופר) עם במה (קומה) וערימות פחם
#    SodiumLamp    - (עולם) עמוד תאורה גבוה עם פנס נתרן וקונוס אור (קריאות)
#    Switch        - (עולם, מלכודת) מנוף העתקה: עוברים לידו (או יורים בו!) -> פעמון + אור אדום (WARN_T) ->
#                    קרון שטוח בורח (Flatcar) מתגלגל מקדימה לאורך המסילה שבכביש: לקפוץ מעליו / להתגלגל. דורס זומבים.
#    LiveWire      - (עולם, מלכודת) חוט חשמל עילי קרוע שמתנדנד. מדי פעם (או כשאתה מתחתיו) מתחיל לזמזם (WARN_T) ואז
#                    מכה בקרקע בקשת חשמל (ARC_T): פוגע בך ומטגן זומבים.
#    Turntable     - (עולם) הגלגלת של בית הקטרים בסוף השלב - הזירה של THE ENGINE, עם תא בקרה מוגבה (קומה = מקום מסתור מההסתערות)
#    Obstacle      - (מוצק + מחסה) "buffer" מעצור מסילה / "sleepers" ערימת אדנים / "crates" ארגזים / "wheels" זוג גלגלי רכבת
#    YardFX        - (מסך) סמוג שנע + פיח וגחלים באוויר (לפי Quality.ambient())
#  לשנות: DUSK_T, TRAIN_EVERY, Switch.WARN_T / Flatcar.SPEED / DMG / DMG_Z / HP, LiveWire.WARN_T / ARC_T / EVERY / DMG / DMG_Z.
# ============================================================

const Art := preload("res://art.gd")
const Sfx := preload("res://sfx.gd")
const Kit := preload("res://effects/backdrop_kit.gd")
const Particles := preload("res://particles.gd")

const DUSK_T := 260.0            # כמה שניות עד שהדמדומים הופכים לערב
const TRAIN_EVERY := 46.0        # כל כמה זמן רכבת הזומבים עוברת ברקע
const TRAIN_T := 30.0            # כמה זמן היא עוברת
const RUST := Color("8a4a2a")
const RUST_D := Color("5a2e1c")
const STEEL := Color("6a6e74")
const STEEL_D := Color("3a3c42")
const BALLAST := Color("5a5250")
const SODIUM := Color(1.0, 0.68, 0.28)
const WOOD := Color("5a4232")


static func _h(i: int, s: int) -> float:
	return fposmod(sin(float(i) * 12.9898 + float(s) * 78.233) * 43758.5453, 1.0)


# 0 = דמדומים, 1 = ערב
static func dusk(t: float) -> float:
	return clampf(t / DUSK_T, 0.0, 1.0)


# ---- שמיים ----
static func yard_sky(ci: CanvasItem, v: Vector2, t: float) -> void:
	var k := dusk(t)
	var top := Color("3a2a4a").lerp(Color("1a1830"), k)
	var mid := Color("b4503a").lerp(Color("5a2a3a"), k)
	var low := Color("e88a4a").lerp(Color("b4502a"), k)
	var hor := Color("f0b070").lerp(Color("e08a40"), k)
	Kit.gradient_sky(ci, v, [top, top.lerp(mid, 0.5), mid, low, hor], 0.86)
	# כוכבים ראשונים (רק בערב)
	if k > 0.35:
		for i in 26:
			var sp := Vector2(_h(i, 1) * v.x, _h(i, 2) * v.y * 0.3)
			var tw := 0.5 + 0.5 * sin(t * 2.0 + float(i) * 1.7)
			ci.draw_rect(Rect2(sp, Vector2(1.6, 1.6)), Color(1.0, 0.95, 0.85, (k - 0.35) * 0.9 * tw))
	# השמש האדומה הנמוכה, שוקעת לאט אל תוך הסמוג
	var sun := Vector2(v.x * 0.7, lerpf(v.y * 0.42, v.y * 0.62, k))
	Kit.soft_glow(ci, sun, 300.0, Color(1.0, 0.45, 0.2, 0.28 * (1.0 - k * 0.6)))
	Kit.soft_glow(ci, sun, 120.0, Color(1.0, 0.6, 0.3, 0.45 * (1.0 - k * 0.5)))
	ci.draw_circle(sun, 34.0, Color(1.0, 0.5, 0.28).lerp(Color(0.85, 0.25, 0.18), k))
	# פסי סמוג שחוצים את השמש
	for q in 5:
		var yy := v.y * (0.3 + float(q) * 0.08)
		var xx := fposmod(t * (6.0 + float(q) * 2.0) + float(q) * 330.0, v.x + 900.0) - 450.0
		Kit.soft_ellipse(ci, Vector2(xx, yy), 520.0, 26.0 + float(q) * 4.0, 0.0, Color(0.35, 0.2, 0.22, 0.22))
		Kit.soft_ellipse(ci, Vector2(xx - v.x * 0.6, yy + 18.0), 420.0, 20.0, 0.0, Color(0.42, 0.24, 0.2, 0.16))
	# זוהר הנתרן של העיר עולה מהאופק
	Kit.haze_band(ci, v, v.y * 0.45, v.y * 0.86, Color(1.0, 0.55, 0.2, 0.12 + 0.18 * k))
	Kit.birds(ci, v, t, 52, Color(0.1, 0.06, 0.08, 0.8), 9)


# ---- העיר הרחוקה ----
static func far_city(ci: CanvasItem, sc: float, v: Vector2, y: float, t: float) -> void:
	var k := dusk(t)
	var city := Color("4a2a34").lerp(Color("2a1a26"), k)
	Kit.skyline(ci, sc * 0.6, v, y - 30.0, Color(city, 0.6), 521, Vector2(50, 110), Vector2(60, 170), 0.04 + 0.12 * k, Color(1.0, 0.75, 0.4, 0.8), t, 0.0)
	Kit.skyline(ci, sc, v, y, city, 522, Vector2(60, 130), Vector2(40, 130), 0.06 + 0.14 * k, Color(1.0, 0.72, 0.38, 0.9), t, 0.05)
	var period := 1300.0
	var start := int(floor(sc / period)) - 1
	for kk in range(start, start + int(ceil(v.x / period)) + 2):
		var bx := float(kk) * period - sc
		# ארובות מפעל עם פסים ונורה אדומה מהבהבת + עשן
		for q in 2:
			var cx := bx + 300.0 + float(q) * 70.0
			var chh := 150.0 + float(q) * 30.0
			ci.draw_rect(Rect2(cx - 7.0, y - chh, 14.0, chh), city.darkened(0.2))
			for s in 3:
				ci.draw_rect(Rect2(cx - 7.0, y - chh + 8.0 + float(s) * 22.0, 14.0, 6.0), Color(0.55, 0.22, 0.2, 0.7))
			if fmod(t + float(q) * 0.5, 1.4) < 0.7:
				ci.draw_rect(Rect2(cx - 2.0, y - chh - 4.0, 4.0, 4.0), Color(1.0, 0.2, 0.15))
				Kit.soft_glow(ci, Vector2(cx, y - chh - 2.0), 12.0, Color(1.0, 0.2, 0.15, 0.5))
			Kit.soft_smoke(ci, Vector2(cx, y - chh - 6.0), t + float(kk * 3 + q), 160.0, Color(0.28, 0.22, 0.24, 0.32), 90.0, 7)
		# מגדל המים של העיר / כנסייה (צללית)
		var tx := bx + 900.0
		ci.draw_rect(Rect2(tx, y - 110.0, 26.0, 110.0), city)
		ci.draw_colored_polygon(PackedVector2Array([Vector2(tx - 4, y - 110), Vector2(tx + 13, y - 150), Vector2(tx + 30, y - 110)]), city)
	# גשר רכבת רחוק + רכבת נוסעים עם חלונות מוארים שחוצה
	var by := y - 46.0
	ci.draw_rect(Rect2(0, by, v.x, 5.0), city.darkened(0.15))
	for q in int(v.x / 90.0) + 2:
		var ax := fposmod(float(q) * 90.0 - sc * 1.0, v.x + 90.0) - 45.0
		ci.draw_rect(Rect2(ax, by + 5.0, 6.0, 41.0), city.darkened(0.1))
	var tk := fmod(t, 34.0) / 34.0
	var trx := lerpf(-700.0, v.x + 100.0, tk)
	for c in 6:
		var cx2 := trx + float(c) * 92.0
		ci.draw_rect(Rect2(cx2, by - 16.0, 86.0, 15.0), Color(0.16, 0.12, 0.16))
		for w in 7:
			ci.draw_rect(Rect2(cx2 + 6.0 + float(w) * 11.0, by - 12.0, 6.0, 5.0), Color(1.0, 0.85, 0.5, 0.35 + 0.5 * k))
	Kit.soft_glow(ci, Vector2(trx + 556.0, by - 9.0), 22.0, Color(1.0, 0.9, 0.6, 0.6))
	# הקרקע הרחוקה
	ci.draw_rect(Rect2(0, y - 2.0, v.x, v.y - y + 2.0), Color("3a2a2a").lerp(Color("241a1e"), k))


# ---- המגרש: רוטונדה, מגדל מים, קרונות, עמודי חשמל + רכבת הזומבים ----
static func mid_yard(ci: CanvasItem, sc: float, v: Vector2, y: float, t: float) -> void:
	var k := dusk(t)
	var shade := Color(1, 1, 1).lerp(Color(0.62, 0.55, 0.62), k)
	var period := 1500.0
	var start := int(floor(sc / period)) - 1
	for kk in range(start, start + int(ceil(v.x / period)) + 2):
		var bx := float(kk) * period - sc
		# הרוטונדה: בניין לבנים עגול-מקומר עם שערים קשתיים
		var rx := bx + 60.0
		var brick := Color("8a4a36") * shade
		ci.draw_rect(Rect2(rx, y - 120.0, 420.0, 112.0), brick)
		ci.draw_colored_polygon(PackedVector2Array([Vector2(rx - 10, y - 120), Vector2(rx + 60, y - 146), Vector2(rx + 360, y - 146), Vector2(rx + 430, y - 120)]), Color("5a4a48") * shade)
		for q in 5:
			var gx := rx + 20.0 + float(q) * 80.0
			ci.draw_rect(Rect2(gx, y - 92.0, 58.0, 84.0), Color("1e1416"))
			ci.draw_arc(Vector2(gx + 29.0, y - 92.0), 29.0, PI, TAU, 10, Color("6a3a2a") * shade, 5.0)
			ci.draw_colored_polygon(PackedVector2Array([Vector2(gx, y - 92), Vector2(gx + 29, y - 120), Vector2(gx + 58, y - 92)]), Color("1e1416"))
			if (kk + q) % 3 == 0:   # קטר בתוך השער
				ci.draw_rect(Rect2(gx + 8.0, y - 56.0, 42.0, 40.0), Color("2a2a30"))
				Kit.soft_glow(ci, Vector2(gx + 44.0, y - 46.0), 10.0, Color(1.0, 0.85, 0.5, 0.6))
		for q in 14:   # שורות לבנים
			ci.draw_line(Vector2(rx, y - 112.0 + float(q) * 8.0), Vector2(rx + 420.0, y - 112.0 + float(q) * 8.0), Color(0.3, 0.15, 0.1, 0.25), 1.0)
		ci.draw_string(ThemeDB.fallback_font, Vector2(rx + 150.0, y - 126.0), "F.C. SUD", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.9, 0.82, 0.6, 0.7))
		# מגדל מים של הרכבת עם צינור מילוי
		var wx := bx + 560.0
		for lx in [0.0, 50.0]:
			ci.draw_line(Vector2(wx + lx, y - 6.0), Vector2(wx + 10.0 + lx * 0.6, y - 120.0), Color("3a3a40") * shade, 4.0)
		ci.draw_rect(Rect2(wx - 12.0, y - 176.0, 80.0, 58.0), Color("6a5040") * shade)
		for q in 5:
			ci.draw_line(Vector2(wx - 12.0 + float(q) * 16.0, y - 176.0), Vector2(wx - 12.0 + float(q) * 16.0, y - 118.0), Color(0.25, 0.18, 0.12, 0.5), 1.4)
		ci.draw_colored_polygon(PackedVector2Array([Vector2(wx - 16, y - 176), Vector2(wx + 28, y - 200), Vector2(wx + 72, y - 176)]), Color("4a3a36") * shade)
		var sw := sin(t * 0.8 + float(kk)) * 0.05
		ci.draw_line(Vector2(wx + 68.0, y - 150.0), Vector2(wx + 68.0, y - 150.0) + Vector2.from_angle(0.5 + sw) * 46.0, Color("2a2a30"), 5.0)
		# שורת קרונות בצבעים חלודים
		for q in 4:
			var cx := bx + 700.0 + float(q) * 168.0
			var cc: Color = [Color("7a3a2a"), Color("5a4a3a"), Color("3a4a5a"), Color("6a3a3a")][(kk + q) % 4] * shade
			ci.draw_rect(Rect2(cx, y - 74.0, 160.0, 58.0), cc)
			ci.draw_rect(Rect2(cx, y - 74.0, 160.0, 5.0), cc.lightened(0.12))
			ci.draw_rect(Rect2(cx + 62.0, y - 66.0, 36.0, 48.0), cc.darkened(0.25))
			ci.draw_rect(Rect2(cx + 4.0, y - 16.0, 152.0, 6.0), Color("1e1a1c"))
			for wq in [22.0, 44.0, 116.0, 138.0]:
				ci.draw_circle(Vector2(cx + wq, y - 10.0), 7.0, Color("1a1618"))
			if _h(kk * 5 + q, 3) < 0.6:   # גרפיטי
				var gc: Color = [Color(0.9, 0.3, 0.5, 0.6), Color(0.4, 0.8, 0.9, 0.6), Color(0.95, 0.85, 0.3, 0.6)][(kk + q) % 3]
				ci.draw_polyline(PackedVector2Array([Vector2(cx + 14, y - 30), Vector2(cx + 24, y - 50), Vector2(cx + 34, y - 34), Vector2(cx + 46, y - 52), Vector2(cx + 54, y - 30)]), gc, 3.0)
		# עמודי חשמל עיליים עם חוט
		for q in 3:
			var px := bx + float(q) * 500.0 + 40.0
			ci.draw_rect(Rect2(px, y - 210.0, 6.0, 204.0), Color("3a3a42") * shade)
			ci.draw_rect(Rect2(px - 24.0, y - 206.0, 54.0, 4.0), Color("3a3a42") * shade)
		ci.draw_line(Vector2(bx - 20.0, y - 200.0), Vector2(bx + 1500.0, y - 200.0), Color(0.15, 0.12, 0.14, 0.7), 1.2)
	_zombie_train(ci, sc, v, y, t, shade)
	ci.draw_rect(Rect2(0, y - 8.0, v.x, v.y - y + 8.0), Color("4a3a36").lerp(Color("2e2428"), k))
	for q in 3:   # מסילות במגרש הרחוק
		ci.draw_line(Vector2(0, y - 6.0 + float(q) * 7.0), Vector2(v.x, y - 6.0 + float(q) * 7.0), Color(0.55, 0.5, 0.48, 0.35), 1.2)


# רכבת המשא של המתים: נוסעת לאט דרומה (ימינה) - גופות על הגגות, ידיים מהדלתות, אחד עומד ומנופף בפנס
static func _zombie_train(ci: CanvasItem, sc: float, v: Vector2, y: float, t: float, shade: Color) -> void:
	var ph := fmod(t + 12.0, TRAIN_EVERY)
	if ph > TRAIN_T:
		return
	var k := ph / TRAIN_T
	var head := lerpf(-200.0, v.x + 2000.0, k) - fposmod(sc * 0.15, 400.0) * 0.0
	var cars := 11
	for c in cars:
		var cx := head - float(c) * 176.0
		if cx < -200.0 or cx > v.x + 200.0:
			continue
		var bob := sin(t * 3.0 + float(c)) * 0.8
		if c == 0:   # קטר דיזל עם פנס
			ci.draw_rect(Rect2(cx - 10.0, y - 88.0 + bob, 170.0, 72.0), Color("2a3a3a") * shade)
			ci.draw_rect(Rect2(cx + 120.0, y - 108.0 + bob, 40.0, 30.0), Color("223030") * shade)
			ci.draw_rect(Rect2(cx + 128.0, y - 102.0 + bob, 24.0, 12.0), Color(1.0, 0.8, 0.4, 0.7))
			Kit.soft_glow(ci, Vector2(cx + 166.0, y - 66.0 + bob), 46.0, Color(1.0, 0.88, 0.55, 0.45))
			Kit.soft_smoke(ci, Vector2(cx + 40.0, y - 92.0), t, 120.0, Color(0.2, 0.18, 0.2, 0.3), -120.0, 6)
		else:
			var cc := (Color("5a3a2a") if c % 2 == 0 else Color("4a4a4e")) * shade
			ci.draw_rect(Rect2(cx, y - 80.0 + bob, 166.0, 64.0), cc)
			ci.draw_rect(Rect2(cx + 56.0, y - 72.0 + bob, 52.0, 54.0), Color("140e10"))
			# ידיים ופנים בדלת הפתוחה
			for q in 4:
				var hx := cx + 60.0 + float(q) * 12.0
				var sw := sin(t * 2.4 + float(c * 4 + q)) * 3.0
				ci.draw_line(Vector2(hx, y - 50.0 + bob), Vector2(hx + sw, y - 26.0 + bob), Color(0.45, 0.5, 0.42) * shade, 2.4)
				ci.draw_circle(Vector2(hx + 2.0, y - 56.0 + bob), 4.0, Color(0.38, 0.42, 0.36) * shade)
				ci.draw_rect(Rect2(hx + 2.0, y - 57.0 + bob, 1.5, 1.5), Color(1.0, 0.25, 0.15))
			# גופות על הגג: יושבות, שוכבות, אחת עומדת
			for q in 5:
				var zx := cx + 10.0 + float(q) * 32.0 + _h(c * 7 + q, 4) * 8.0
				var zc := Color(0.24, 0.24, 0.26) * shade
				if (c + q) % 4 == 0:   # עומד
					ci.draw_line(Vector2(zx, y - 80.0 + bob), Vector2(zx + 1.0, y - 104.0 + bob), zc, 5.0)
					ci.draw_circle(Vector2(zx + 1.0, y - 109.0 + bob), 4.5, zc)
					ci.draw_line(Vector2(zx, y - 98.0 + bob), Vector2(zx + 10.0, y - 92.0 + sin(t * 3.0 + float(q)) * 3.0 + bob), zc, 2.4)
				else:   # יושב / שוכב
					ci.draw_colored_polygon(Art.ellipse(Vector2(zx, y - 86.0 + bob), 10.0, 6.0, 0.0, 8), zc)
					ci.draw_circle(Vector2(zx + 8.0, y - 92.0 + bob), 4.0, zc)
		ci.draw_rect(Rect2(cx + 4.0, y - 18.0, 160.0, 5.0), Color("161214"))
		for wq in [22.0, 44.0, 120.0, 142.0]:
			ci.draw_circle(Vector2(cx + wq, y - 12.0), 7.0, Color("161214"))
			var ra: float = t * 6.0 + wq
			ci.draw_line(Vector2(cx + wq, y - 12.0), Vector2(cx + wq, y - 12.0) + Vector2.from_angle(ra) * 6.0, Color(0.4, 0.38, 0.38), 1.2)
		ci.draw_line(Vector2(cx - 10.0, y - 30.0), Vector2(cx, y - 30.0), Color("161214"), 3.0)


# ---- קרוב: מסילות, עמודי איתות, אדים, עשבים וגרוטאות ----
static func near_rails(ci: CanvasItem, sc: float, v: Vector2, y: float, t: float) -> void:
	var k := dusk(t)
	var dark := Color("2a2226").lerp(Color("1c171c"), k)
	ci.draw_rect(Rect2(0, y - 4.0, v.x, v.y - y + 4.0), dark)
	var period := 340.0
	var start := int(floor(sc / period)) - 1
	for kk in range(start, start + int(ceil(v.x / period)) + 2):
		var x := float(kk) * period - sc
		# אדנים ופסים
		for q in 8:
			ci.draw_rect(Rect2(x + float(q) * 42.0, y - 6.0, 26.0, 6.0), Color("3a2a22"))
		# עמוד איתות: אור אדום/ירוק שמתחלף לפי לוח זמנים, ומהבהב בצהוב לפני
		if _h(kk, 1) < 0.55:
			var px := x + 120.0
			ci.draw_rect(Rect2(px - 3.0, y - 96.0, 6.0, 92.0), Color("2a2a30"))
			ci.draw_rect(Rect2(px - 9.0, y - 128.0, 18.0, 36.0), Color("161618"))
			var cyc := fmod(t + float(kk) * 3.1, 12.0)
			var red := cyc < 6.0
			var amber := cyc > 10.5 and int(t * 6.0) % 2 == 0
			var c1 := Color(1.0, 0.18, 0.12) if red else Color(0.25, 0.08, 0.06)
			var c2 := Color(1.0, 0.75, 0.2) if amber else Color(0.25, 0.18, 0.05)
			var c3 := Color(0.25, 1.0, 0.45) if not red and not amber else Color(0.05, 0.2, 0.08)
			ci.draw_rect(Rect2(px - 4.0, y - 124.0, 8.0, 8.0), c1)
			ci.draw_rect(Rect2(px - 4.0, y - 114.0, 8.0, 8.0), c2)
			ci.draw_rect(Rect2(px - 4.0, y - 104.0, 8.0, 8.0), c3)
			var lit := c1 if red else (c2 if amber else c3)
			Kit.soft_glow(ci, Vector2(px, y - 110.0), 26.0, Color(lit, 0.35))
		# עשבים
		for q in 6:
			var gx := x + _h(kk * 6 + q, 2) * period
			var gh := 10.0 + _h(kk * 6 + q, 3) * 16.0
			var sw := sin(t * 1.5 + float(q + kk)) * 2.0
			ci.draw_line(Vector2(gx, y), Vector2(gx + sw, y - gh), Color("4a5a36"), 1.6)
			ci.draw_line(Vector2(gx + 3.0, y), Vector2(gx + 3.0 + sw * 1.3, y - gh * 0.7), Color("5a6a3e"), 1.3)
		# גרוטאות: גלגל רכבת, ארגז שבור, חבית
		var j := _h(kk, 5)
		var sx := x + 240.0
		if j < 0.3:
			ci.draw_circle(Vector2(sx, y - 18.0), 18.0, Color("2a2628"))
			ci.draw_circle(Vector2(sx, y - 18.0), 7.0, Color("4a4044"))
			ci.draw_line(Vector2(sx - 30.0, y - 18.0), Vector2(sx + 30.0, y - 18.0), Color("2a2628"), 5.0)
		elif j < 0.55:
			ci.draw_rect(Rect2(sx - 20.0, y - 26.0, 40.0, 26.0), Color("5a3e2a"))
			ci.draw_line(Vector2(sx - 20.0, y - 26.0), Vector2(sx + 20.0, y), Color("3a2a1c"), 2.0)
		elif j < 0.7:
			ci.draw_rect(Rect2(sx - 12.0, y - 30.0, 24.0, 30.0), Color("6a2a1e"))
			ci.draw_rect(Rect2(sx - 12.0, y - 22.0, 24.0, 3.0), Color("3a1a12"))
		# אדים מפתח אוורור
		if _h(kk, 6) < 0.35:
			Kit.soft_smoke(ci, Vector2(x + 60.0, y - 2.0), t * 1.4 + float(kk), 110.0, Color(0.75, 0.7, 0.7, 0.22), 30.0, 6)
	# מסילה ארוכה קדמית
	ci.draw_line(Vector2(0, y - 7.0), Vector2(v.x, y - 7.0), Color("7a7470"), 2.4)
	ci.draw_line(Vector2(0, y - 6.0), Vector2(v.x, y - 6.0), Color("3a3634"), 1.0)


# אובך הנתרן מאחורי הדמויות
static func yard_overlay(ci: CanvasItem, v: Vector2, t: float) -> void:
	var k := dusk(t)
	Kit.haze_band(ci, v, 420.0, 612.0, Color(0.95, 0.6, 0.35, 0.2 + 0.06 * k))


# ============================================================
#  עולם
# ============================================================
class YardGround extends Node2D:
	var w := 1024.0
	var depth := 90.0
	var seed_v := 0

	func _ready() -> void:
		z_index = 1

	func _draw() -> void:
		draw_rect(Rect2(0, 0, w, depth), Color("2e2826"))
		draw_rect(Rect2(0, 0, w, 16.0), BALLAST)
		var r := RandomNumberGenerator.new()
		r.seed = seed_v
		for i in int(w / 30.0):   # אדנים
			var sx := float(i) * 30.0 + 4.0
			draw_rect(Rect2(sx, 2.0, 18.0, 6.0), Color("3e2c22"))
			draw_rect(Rect2(sx, 2.0, 18.0, 1.5), Color("5a4232"))
		# פס הברזל (שקוע בכביש)
		draw_rect(Rect2(0, 0, w, 3.0), Color("8a8480"))
		draw_rect(Rect2(0, 3.0, w, 2.0), Color("4a4442"))
		for i in int(w / 6.0):   # חצץ
			var gx := r.randf_range(0.0, w)
			var gy := r.randf_range(6.0, 16.0)
			draw_rect(Rect2(gx, gy, 2.0, 2.0), Color(0.45 + r.randf() * 0.2, 0.42 + r.randf() * 0.15, 0.4, 1.0))
		for i in int(w / 40.0):
			draw_rect(Rect2(r.randf_range(0.0, w), r.randf_range(22.0, depth - 8.0), r.randf_range(2.0, 5.0), 2.0), Color("221c1c"))
		for i in int(w / 160.0):   # כתמי שמן
			draw_colored_polygon(Art.ellipse(Vector2(r.randf_range(0.0, w), 9.0), r.randf_range(10.0, 22.0), 2.5, 0.0, 10), Color(0.08, 0.06, 0.08, 0.5))


# ---- קרון משא (הגג = קומה, add_floor בשלב) ----
class Boxcar extends Node2D:
	var w := 280.0
	var tier := 134.0
	var seed_v := 0
	var col := Color("7a3a2a")

	func _ready() -> void:
		z_index = -1

	func _draw() -> void:
		var r := RandomNumberGenerator.new()
		r.seed = seed_v
		var c := col
		var body := Rect2(0, -tier, w, tier - 26.0)
		draw_rect(body, c)
		for q in int(w / 14.0):   # צלעות הפח
			draw_line(Vector2(float(q) * 14.0 + 6.0, -tier + 4.0), Vector2(float(q) * 14.0 + 6.0, -30.0), c.darkened(0.18), 2.0)
		draw_rect(Rect2(0, -tier, w, 6.0), c.lightened(0.15))
		draw_rect(Rect2(-4.0, -tier - 4.0, w + 8.0, 5.0), Color("2a2224"))   # שפת הגג
		# דלת הזזה פתוחה למחצה - חושך בפנים ועיניים אדומות
		var dx := w * 0.38
		draw_rect(Rect2(dx, -tier + 14.0, 70.0, tier - 44.0), Color("120c0e"))
		draw_rect(Rect2(dx + 52.0, -tier + 12.0, 46.0, tier - 40.0), c.darkened(0.12))
		draw_line(Vector2(dx - 4.0, -tier + 12.0), Vector2(dx + 110.0, -tier + 12.0), Color("2a2224"), 3.0)
		for q in 3:
			var ex := dx + 12.0 + float(q) * 16.0
			var ey := -tier * 0.55 + float(q % 2) * 10.0
			draw_rect(Rect2(ex, ey, 2.0, 2.0), Color(1.0, 0.22, 0.15))
			draw_rect(Rect2(ex + 5.0, ey, 2.0, 2.0), Color(1.0, 0.22, 0.15))
		# כתמי חלודה וגרפיטי
		for q in 6:
			draw_colored_polygon(Art.ellipse(Vector2(r.randf_range(10.0, w - 10.0), r.randf_range(-tier + 20.0, -36.0)), r.randf_range(6.0, 16.0), r.randf_range(3.0, 8.0), 0.0, 10), Color(0.35, 0.15, 0.08, 0.45))
		var gc: Color = [Color("e05080"), Color("50c0e0"), Color("f0d040"), Color("80e060")][seed_v % 4]
		var gx := w * 0.72
		draw_polyline(PackedVector2Array([Vector2(gx, -50), Vector2(gx + 10, -76), Vector2(gx + 22, -52), Vector2(gx + 34, -80), Vector2(gx + 50, -54)]), gc, 4.0)
		draw_string(ThemeDB.fallback_font, Vector2(14.0, -tier + 26.0), "FCS %d" % (1000 + seed_v % 9000), HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.9, 0.86, 0.75, 0.75))
		draw_string(ThemeDB.fallback_font, Vector2(14.0, -tier + 40.0), "SUR >>>", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.95, 0.9, 0.8, 0.6))
		# שלדה וגלגלים
		draw_rect(Rect2(-6.0, -30.0, w + 12.0, 8.0), Color("1e1a1c"))
		for bx in [36.0, w - 36.0]:
			draw_rect(Rect2(bx - 34.0, -24.0, 68.0, 8.0), Color("2a2628"))
			for wx in [-18.0, 18.0]:
				draw_circle(Vector2(bx + wx, -11.0), 11.0, Color("1a1618"))
				draw_circle(Vector2(bx + wx, -11.0), 4.0, Color("5a5450"))
		draw_rect(Rect2(-14.0, -26.0, 10.0, 6.0), Color("3a3634"))   # מצמד
		draw_rect(Rect2(w + 4.0, -26.0, 10.0, 6.0), Color("3a3634"))
		# סולם על הצד
		for lx in [6.0, w - 18.0]:
			for q in 5:
				draw_line(Vector2(lx, -tier + 14.0 + float(q) * 18.0), Vector2(lx + 12.0, -tier + 14.0 + float(q) * 18.0), Color("2a2224"), 2.0)


# ---- גשר איתות מעל המסילות (הקומה = add_floor בשלב) ----
class Gantry extends Node2D:
	var w := 340.0
	var tier := 196.0
	var _t := 0.0
	var _phase := 0.0

	func _ready() -> void:
		z_index = -1
		_phase = randf() * 10.0

	func _process(delta: float) -> void:
		_t += delta
		if Engine.get_process_frames() % 10 == 0 and Art.on_screen(self, global_position + Vector2(w * 0.5, -tier), w):
			queue_redraw()

	func _draw() -> void:
		# שני מגדלי סריג
		for tx in [0.0, w - 26.0]:
			draw_rect(Rect2(tx, -tier, 4.0, tier), STEEL_D)
			draw_rect(Rect2(tx + 22.0, -tier, 4.0, tier), STEEL_D)
			for q in int(tier / 24.0):
				var yy := -float(q) * 24.0
				draw_line(Vector2(tx + 2.0, yy), Vector2(tx + 24.0, yy - 24.0), STEEL, 1.6)
				draw_line(Vector2(tx + 24.0, yy), Vector2(tx + 2.0, yy - 24.0), STEEL, 1.6)
		# קורת הגשר + מסלול הליכה + מעקה
		draw_rect(Rect2(-8.0, -tier, w + 16.0, 12.0), STEEL_D)
		draw_rect(Rect2(-8.0, -tier, w + 16.0, 3.0), STEEL)
		for q in int((w + 16.0) / 20.0):
			draw_line(Vector2(-8.0 + float(q) * 20.0, -tier + 3.0), Vector2(2.0 + float(q) * 20.0, -tier + 12.0), STEEL, 1.0)
		draw_line(Vector2(-8.0, -tier - 26.0), Vector2(w + 8.0, -tier - 26.0), STEEL, 2.0)
		for q in 9:
			draw_line(Vector2(-6.0 + float(q) * (w + 12.0) / 8.0, -tier), Vector2(-6.0 + float(q) * (w + 12.0) / 8.0, -tier - 26.0), STEEL_D, 2.0)
		# ראשי איתות תלויים מתחת לגשר - מתחלפים לפי לוח הזמנים
		for q in 3:
			var hx := 70.0 + float(q) * (w - 140.0) / 2.0
			draw_rect(Rect2(hx - 9.0, -tier + 12.0, 18.0, 30.0), Color("141416"))
			var cyc := fmod(_t + _phase + float(q) * 2.0, 9.0)
			var c := Color(1.0, 0.18, 0.12) if cyc < 4.5 else Color(0.25, 1.0, 0.45)
			var cy := -tier + 20.0 if cyc < 4.5 else -tier + 34.0
			draw_rect(Rect2(hx - 4.0, cy - 4.0, 8.0, 8.0), c)
			Kit.soft_glow(self, Vector2(hx, cy), 30.0, Color(c, 0.4))
			draw_rect(Rect2(hx - 4.0, (-tier + 34.0 if cyc < 4.5 else -tier + 20.0) - 4.0, 8.0, 8.0), Color(0.15, 0.1, 0.08))
		draw_string(ThemeDB.fallback_font, Vector2(w * 0.5 - 30.0, -tier + 9.0), "VIA 3 - SUR", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color(0.95, 0.9, 0.7, 0.7))


# ---- מגדל פחם (הופר) עם במה (הקומה = add_floor בשלב) ----
class Hopper extends Node2D:
	var w := 230.0
	var tier := 176.0

	func _ready() -> void:
		z_index = -1

	func _draw() -> void:
		for lx in [10.0, w * 0.5 - 6.0, w - 22.0]:   # רגלי בטון
			draw_rect(Rect2(lx, -tier, 12.0, tier), Color("5a5250"))
			draw_rect(Rect2(lx, -tier, 3.0, tier), Color("6e6662"))
		# המשפך: גוף עליון גדול מעל הבמה
		var top := -tier - 140.0
		draw_colored_polygon(PackedVector2Array([Vector2(-10, top), Vector2(w + 10, top), Vector2(w + 10, -tier - 40.0), Vector2(w * 0.5 + 30.0, -tier - 6.0), Vector2(w * 0.5 - 30.0, -tier - 6.0), Vector2(-10, -tier - 40.0)]), Color("4a4644"))
		for q in 9:
			draw_line(Vector2(-10.0 + float(q) * (w + 20.0) / 8.0, top), Vector2(-10.0 + float(q) * (w + 20.0) / 8.0, -tier - 40.0), Color("3a3634"), 1.4)
		draw_colored_polygon(PackedVector2Array([Vector2(-14, top), Vector2(w * 0.5, top - 36.0), Vector2(w + 14, top)]), Color("3a3634"))
		draw_string(ThemeDB.fallback_font, Vector2(w * 0.5 - 26.0, top + 30.0), "CARBON", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.85, 0.8, 0.7, 0.6))
		# הבמה
		draw_rect(Rect2(-14.0, -tier, w + 28.0, 10.0), Color("3a3a40"))
		draw_rect(Rect2(-14.0, -tier, w + 28.0, 3.0), STEEL)
		draw_line(Vector2(-14.0, -tier - 24.0), Vector2(w + 14.0, -tier - 24.0), STEEL, 2.0)
		for q in 7:
			draw_line(Vector2(-12.0 + float(q) * (w + 24.0) / 6.0, -tier), Vector2(-12.0 + float(q) * (w + 24.0) / 6.0, -tier - 24.0), STEEL_D, 2.0)
		# ערימות פחם למטה
		for q in 3:
			var cx := 30.0 + float(q) * 80.0
			draw_colored_polygon(PackedVector2Array([Vector2(cx - 34, 0), Vector2(cx - 10, -22.0 - float(q % 2) * 8.0), Vector2(cx + 12, -26.0), Vector2(cx + 36, 0)]), Color("1c1a1c"))
			for s in 5:
				draw_rect(Rect2(cx - 20.0 + float(s) * 8.0, -10.0 - float(s % 3) * 4.0, 3.0, 3.0), Color(0.35, 0.33, 0.38))


# ---- עמוד פנס נתרן ----
class SodiumLamp extends Node2D:
	var h := 300.0
	var _t := 0.0
	var _flick := 0.0

	func _ready() -> void:
		z_index = -1
		_flick = randf() * 10.0

	func _process(delta: float) -> void:
		_t += delta
		if Engine.get_process_frames() % 8 == 0 and Art.on_screen(self, global_position + Vector2(0, -h * 0.5), h):
			queue_redraw()

	func _draw() -> void:
		draw_rect(Rect2(-4.0, -h, 8.0, h), Color("2a2a30"))
		draw_rect(Rect2(-4.0, -h, 2.0, h), Color("4a4a52"))
		draw_line(Vector2(0, -h), Vector2(46.0, -h - 10.0), Color("2a2a30"), 5.0)
		draw_rect(Rect2(38.0, -h - 14.0, 26.0, 9.0), Color("1a1a1e"))
		var on := 1.0
		if fmod(_t + _flick, 13.0) < 0.25:   # מהבהב לרגע
			on = 0.35 if int(_t * 20.0) % 2 == 0 else 1.0
		draw_rect(Rect2(40.0, -h - 6.0, 22.0, 3.0), Color(1.0, 0.8, 0.45, on))
		var a := 0.13 * on
		draw_colored_polygon(PackedVector2Array([Vector2(40, -h - 4), Vector2(62, -h - 4), Vector2(150, -6), Vector2(-50, -6)]), Color(SODIUM, a))
		Kit.soft_glow(self, Vector2(51.0, -h - 4.0), 60.0, Color(SODIUM, 0.55 * on))
		Kit.soft_glow(self, Vector2(51.0, -8.0), 110.0, Color(SODIUM, 0.16 * on), 0.25)


# ============================================================
#  מלכודת: מנוף העתקה + קרון בורח
# ============================================================
class Switch extends Node2D:
	const WARN_T := 1.3
	const TRIGGER := 60.0           # השחקן עובר ליד המנוף -> הקרון משתחרר
	const AHEAD := 860.0            # מאיזה מרחק לפני השחקן הקרון נכנס
	var state := 0                  # 0 = נעול, 1 = פעמון (אזהרה), 2 = שוחרר
	var dir := -1.0                 # לאן הקרון נוסע (לכיוון השחקן)
	var runs := 0                   # לבדיקות
	var car: Node = null
	var _t := 0.0
	var _tt := 0.0
	var _from_switch := false

	class Lever extends StaticBody2D:
		var s = null
		func hit_by_bullet(_p: Vector2, _n: Vector2, _d: Vector2) -> void:
			if s != null and s.state == 0:
				s._release(0.25, true)

	func _ready() -> void:
		z_index = 2
		add_to_group("hazards")
		var lb := Lever.new()
		lb.s = self
		lb.collision_layer = 4
		lb.collision_mask = 0
		var cs := CollisionShape2D.new()
		var sh := RectangleShape2D.new()
		sh.size = Vector2(20, 40)
		cs.shape = sh
		cs.position = Vector2(0, -30)
		lb.add_child(cs)
		add_child(lb)

	func world_rect() -> Rect2:
		if car != null and is_instance_valid(car) and car.alive():
			return car.world_rect()
		return Rect2()

	func danger_at(p: Vector2, margin := 0.0) -> bool:
		return world_rect().grow(margin).has_point(p)

	func _release(t: float, shot := false) -> void:
		state = 1
		_t = t
		_from_switch = shot
		var pl := get_tree().get_first_node_in_group("player")
		if pl != null:
			if shot:   # ירית במנוף: הקרון יוצא מהמנוף לכיוון שלך
				dir = signf(pl.global_position.x - global_position.x)
			else:      # עברת ליד המנוף: הקרון מגיע מקדימה (מהצד שאליו אתה הולך)
				var ahead: float = signf(pl.velocity.x) if absf(pl.velocity.x) > 20.0 else pl._face()
				dir = -ahead
			if dir == 0.0:
				dir = -1.0
		Sfx.play("sw_bell", global_position + Vector2(0, -40), 2.0, 0.05, 2)
		if pl != null and pl.has_method("_say") and pl.global_position.distance_to(global_position) < 900.0:
			pl._say("RUNAWAY CAR!  JUMP IT", Color("ffb050"))

	func _physics_process(delta: float) -> void:
		_t -= delta
		_tt += delta
		match state:
			0:
				var pl := get_tree().get_first_node_in_group("player")
				if pl != null and not pl.dead and absf(pl.global_position.x - global_position.x) < TRIGGER and absf(pl.global_position.y - global_position.y) < 200.0:
					_release(WARN_T)
			1:
				if Engine.get_physics_frames() % 20 == 0:
					Sfx.play("sw_bell", global_position + Vector2(0, -40), -2.0, 0.05, 2)
				if _t <= 0.0:
					state = 2
					runs += 1
					var pl2 := get_tree().get_first_node_in_group("player")
					var c := Flatcar.new()
					c.dir = dir
					get_parent().add_child(c)
					var sx: float = global_position.x
					if not _from_switch and pl2 != null:
						sx = pl2.global_position.x - dir * AHEAD
					c.global_position = Vector2(sx, global_position.y)
					car = c
					Sfx.play("sw_roll", c.global_position, 3.0, 0.05, 2)
		if state == 1 or (Art.on_screen(self, global_position, 120.0) and Engine.get_physics_frames() % 15 == 0):
			queue_redraw()

	func _draw() -> void:
		# קופסת המנוף + מוט אדום-לבן + פנס אדום
		draw_rect(Rect2(-14.0, -24.0, 28.0, 24.0), Color("3a3a40"))
		draw_rect(Rect2(-14.0, -24.0, 28.0, 4.0), Color("5a5a62"))
		var ang := -1.1 if state == 0 else -0.25
		var tip := Vector2(0, -20) + Vector2(sin(ang) * 40.0, -cos(ang) * 40.0)
		draw_line(Vector2(0, -20), tip, Color("e8e0d0"), 5.0)
		draw_line(Vector2(0, -20), Vector2(0, -20).lerp(tip, 0.33), Color("c02a20"), 5.0)
		draw_line(Vector2(0, -20).lerp(tip, 0.66), tip, Color("c02a20"), 5.0)
		draw_circle(tip, 5.0, Color("c02a20"))
		var blink := state == 1 and int(_tt * 6.0) % 2 == 0
		var lc := Color(1.0, 0.2, 0.12) if blink or state == 2 else Color(0.35, 0.1, 0.08)
		draw_rect(Rect2(10.0, -44.0, 4.0, 20.0), Color("2a2a30"))
		draw_rect(Rect2(6.0, -54.0, 12.0, 12.0), Color("161618"))
		draw_rect(Rect2(8.0, -52.0, 8.0, 8.0), lc)
		if blink:
			Kit.soft_glow(self, Vector2(12.0, -48.0), 40.0, Color(1.0, 0.2, 0.1, 0.5))
			draw_string(ThemeDB.fallback_font, Vector2(-6.0, -70.0), "!", HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color(1.0, 0.45, 0.2))
		draw_string(ThemeDB.fallback_font, Vector2(-14.0, -6.0), "SW", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color(0.9, 0.85, 0.7, 0.7))


# קרון שטוח בורח: מתגלגל על המסילה שבכביש. פוגע בך אם לא קפצת / התגלגלת, דורס זומבים, מתנפץ בקיר. אפשר להרוס אותו.
class Flatcar extends Node2D:
	const SPEED := 540.0
	const SPAN := 2200.0
	const DMG := 2
	const DMG_Z := 70
	const H := 40.0                 # גובה (קופצים מעליו)
	const HP := 70
	var dir := -1.0
	var hp := HP
	var hit_p := false
	var hits := 0                   # לבדיקות
	var crushed := 0
	var _d := 0.0
	var _ph := 0.0
	var _dead_t := -1.0
	var _body: StaticBody2D = null
	var _crushed_ids := {}

	class Deck extends StaticBody2D:
		var c = null
		func take_damage(amount: int, hit_pos: Vector2, dir: Vector2, explosive := false, src := {}) -> void:
			if c != null:
				c.hurt_by(amount, hit_pos, dir, explosive, src)

	func _ready() -> void:
		z_index = 6
		var b := Deck.new()
		b.c = self
		b.collision_layer = 4
		b.collision_mask = 0
		var cs := CollisionShape2D.new()
		var sh := RectangleShape2D.new()
		sh.size = Vector2(110, 34)
		cs.shape = sh
		cs.position = Vector2(0, -22)
		b.add_child(cs)
		add_child(b)
		_body = b

	func alive() -> bool:
		return _dead_t < 0.0

	func world_rect() -> Rect2:
		return Rect2(global_position + Vector2(-60, -H), Vector2(120, H))

	func hurt_by(amount: int, hit_pos: Vector2, d: Vector2, explosive: bool, src: Dictionary) -> void:
		if not alive():
			return
		var dmg := amount
		if src.has("fixed"):
			dmg = int(src.fixed)
		elif not explosive:
			dmg = 8
		hp -= maxi(dmg, 1)
		Sfx.play("metal_ping" if Sfx.has_sound("metal_ping") else "clang", hit_pos, -4.0, 0.15, 3)
		Particles.burst(get_parent(), hit_pos, "fire", Vector2(-d.x, -0.5), 4)
		if hp <= 0:
			_die(true)

	func _die(blown: bool) -> void:
		_dead_t = 0.0
		Sfx.play("clang", global_position, 2.0, 0.1, 2)
		Particles.burst(get_parent(), global_position + Vector2(0, -16), "smoke", Vector2.UP, 10)
		Particles.burst(get_parent(), global_position + Vector2(0, -16), "fire", Vector2.UP, 12 if blown else 6)
		var cam := get_viewport().get_camera_2d()
		if cam != null and cam.has_method("shake") and Art.on_screen(self, global_position):
			cam.shake(8.0, 0.3)
		if is_instance_valid(_body):
			_body.queue_free()

	func _physics_process(delta: float) -> void:
		if not alive():
			_dead_t += delta
			if _dead_t > 5.0:
				modulate.a = maxf(0.0, 1.0 - (_dead_t - 5.0))
				if _dead_t > 6.0:
					queue_free()
					return
			if Engine.get_physics_frames() % 10 == 0:
				queue_redraw()
			return
		var step := dir * SPEED * delta
		var from := global_position + Vector2(dir * 62.0, -16.0)
		var hit := get_world_2d().direct_space_state.intersect_ray(PhysicsRayQueryParameters2D.create(from, from + Vector2(step + dir * 4.0, 0), 1))
		if not hit.is_empty() or _d > SPAN:   # מתנגש במכשול / קיר / סוף המסילה - יורד מהפסים ומתרסק
			_die(false)
			return
		global_position.x += step
		_d += absf(step)
		_ph += delta * 18.0
		if Engine.get_physics_frames() % 3 == 0:
			Particles.burst(get_parent(), global_position + Vector2(-dir * 40.0, -2.0), "fire", Vector2(-dir, -0.4), 1)
		var r := world_rect()
		var pl := get_tree().get_first_node_in_group("player")
		if pl != null and not pl.dead and not hit_p and r.intersects(pl.body_rect()) and pl._roll_t <= 0.0:
			hit_p = true
			hits += 1
			pl.hurt(DMG, Vector2(dir * 1.8, -0.6))
		for z in get_tree().get_nodes_in_group("zombies"):
			if z.dead or z.is_boss() or _crushed_ids.has(z.get_instance_id()):
				continue
			if r.grow(6.0).has_point(z.global_position + Vector2(0, -8)):
				_crushed_ids[z.get_instance_id()] = true
				crushed += 1
				z.take_damage(DMG_Z, z.global_position + Vector2(0, -24), Vector2(dir, -0.6), true, {"source": "hazard", "fixed": DMG_Z, "blast": 9000 + get_instance_id() % 1000})
				z.velocity += Vector2(dir * 420.0, -380.0)
		queue_redraw()

	func _draw() -> void:
		var dead := not alive()
		var tilt := 0.0 if not dead else 0.12 * dir
		draw_set_transform(Vector2(0, 0), tilt, Vector2.ONE)
		# שלדה + משטח עץ + מטען של פסים קשורים בשרשראות
		draw_rect(Rect2(-60.0, -30.0, 120.0, 10.0), Color("2a2426"))
		draw_rect(Rect2(-60.0, -34.0, 120.0, 5.0), WOOD)
		for q in 4:
			draw_rect(Rect2(-54.0, -44.0 - float(q % 2) * 4.0, 108.0, 4.0), Color("6a6460"))
		draw_line(Vector2(-30, -48), Vector2(-30, -30), Color("8a8a8e"), 1.4)
		draw_line(Vector2(30, -48), Vector2(30, -30), Color("8a8a8e"), 1.4)
		draw_rect(Rect2(-62.0 * dir - 4.0, -32.0, 8.0, 12.0), Color("c02a20"))   # הבלם האדום (מאחור)
		for wx in [-36.0, -16.0, 16.0, 36.0]:
			draw_circle(Vector2(wx, -10.0), 10.0, Color("1a1618"))
			draw_circle(Vector2(wx, -10.0), 3.5, Color("6a6460"))
			if not dead:
				draw_line(Vector2(wx, -10.0), Vector2(wx, -10.0) + Vector2.from_angle(_ph * dir) * 9.0, Color("8a8480"), 1.6)
		if not dead:
			Kit.soft_glow(self, Vector2(-dir * 40.0, -4.0), 26.0, Color(1.0, 0.6, 0.2, 0.5))   # ניצוצות מהגלגלים
		draw_set_transform_matrix(Transform2D.IDENTITY)


# ============================================================
#  מלכודת: חוט חשמל עילי קרוע
# ============================================================
class LiveWire extends Node2D:
	const WARN_T := 0.75
	const ARC_T := 0.5
	const EVERY := Vector2(4.5, 7.0)
	const W := 120.0                # רוחב האזור שנפגע מהקשת
	const H := 250.0                # גובה החוט
	const TRIGGER := 160.0          # השחקן מתחת = מתחיל לזמזם מיד (אם מוכן)
	const DMG := 1
	const DMG_Z := 45
	var state := 0                  # 0 = מתנדנד, 1 = מזמזם (אזהרה), 2 = קשת
	var arcs := 0                   # לבדיקות
	var hits := 0
	var fried := 0
	var _t := 0.0
	var _tt := 0.0
	var _next := 3.0
	var _hit_done := false

	func _ready() -> void:
		z_index = 4
		add_to_group("hazards")
		_next = randf_range(1.5, EVERY.y)
		var poles := Poles.new()
		poles.z_as_relative = false
		poles.z_index = -1
		add_child(poles)

	class Poles extends Node2D:   # שני עמודים וחוט עליון תקין - מאחורי הדמויות (לא מסתירים אותן)
		func _draw() -> void:
			var W := LiveWire.W
			var H := LiveWire.H
			draw_rect(Rect2(-W * 0.5 - 70.0, -H - 20.0, 6.0, H + 20.0), Color("2a2a32"))
			draw_rect(Rect2(W * 0.5 + 64.0, -H - 20.0, 6.0, H + 20.0), Color("2a2a32"))
			draw_line(Vector2(-W * 0.5 - 90.0, -H - 14.0), Vector2(W * 0.5 + 90.0, -H - 14.0), Color("3a3a42"), 4.0)
			draw_line(Vector2(-W * 0.5 - 70.0, -H), Vector2(W * 0.5 + 70.0, -H + 6.0), Color("1e1e22"), 1.6)

	func world_rect() -> Rect2:
		return Rect2(global_position + Vector2(-W * 0.5, -H), Vector2(W, H))

	func danger_at(p: Vector2, margin := 0.0) -> bool:
		return (state == 1 or state == 2) and Rect2(global_position + Vector2(-W * 0.5, -80.0), Vector2(W, 80.0)).grow(margin).has_point(p)

	func _physics_process(delta: float) -> void:
		_tt += delta
		if state == 0 and get_tree().get_first_node_in_group("story_scene") != null:   # שקט בזמן סצנת סיפור (l52_quisling)
			return
		_t -= delta
		_next -= delta
		match state:
			0:
				var pl := get_tree().get_first_node_in_group("player")
				var near: bool = pl != null and not pl.dead and absf(pl.global_position.x - global_position.x) < TRIGGER and absf(pl.global_position.y - global_position.y) < 60.0
				if _next <= 0.0 or (near and _next < EVERY.x * 0.6):
					state = 1
					_t = WARN_T
					Sfx.play("lw_buzz", global_position + Vector2(0, -H * 0.5), 0.0, 0.1, 2)
			1:
				if _t <= 0.0:
					state = 2
					_t = ARC_T
					arcs += 1
					_hit_done = false
					Sfx.play("zap", global_position, 3.0, 0.1, 3)
					Particles.burst(get_parent(), global_position + Vector2(0, -4), "spark", Vector2.UP, 14)
					var cam := get_viewport().get_camera_2d()
					if cam != null and cam.has_method("shake") and Art.on_screen(self, global_position):
						cam.shake(4.0, 0.2)
			2:
				if not _hit_done:
					_hit_done = true
					var r := Rect2(global_position + Vector2(-W * 0.5, -80.0), Vector2(W, 82.0))
					var pl2 := get_tree().get_first_node_in_group("player")
					if pl2 != null and not pl2.dead and r.intersects(pl2.body_rect()):
						hits += 1
						pl2.hurt(DMG, Vector2(signf(pl2.global_position.x - global_position.x + 0.01) * 1.2, -0.5))
					for z in get_tree().get_nodes_in_group("zombies"):
						if not z.dead and r.has_point(z.global_position + Vector2(0, -10)):
							fried += 1
							Particles.burst(z.get_parent(), z.global_position + Vector2(0, -30), "spark", Vector2.UP, 6)
							z.take_damage(DMG_Z if not z.is_boss() else 12, z.global_position + Vector2(0, -30), Vector2.UP, true, {"source": "hazard", "fixed": DMG_Z if not z.is_boss() else 12})
				if _t <= 0.0:
					state = 0
					_next = randf_range(EVERY.x, EVERY.y)
		if Art.on_screen(self, global_position + Vector2(0, -H * 0.5), H):
			queue_redraw()

	func _draw() -> void:
		# שני עמודים, חוט עליון תקין, וחוט קרוע שמתנדנד ומגיע כמעט לקרקע
		# (העמודים מאחורי הדמויות - Poles; רק החוט הקרוע והקשת מקדימה)
		var sw := sin(_tt * 1.3) * 22.0
		var end := Vector2(sw, -26.0)
		if state == 2:
			end = Vector2(sw * 0.3, -2.0)
		var mid := Vector2(-20.0 + sw * 0.4, -H * 0.55)
		draw_polyline(PackedVector2Array([Vector2(-W * 0.5 - 70.0, -H), mid, end]), Color("1a1a1e"), 2.2)
		draw_rect(Rect2(-W * 0.5 - 74.0, -H - 4.0, 12.0, 8.0), Color("c8c0a8"))   # מבדד
		# ניצוצות בקצה החוט
		if int(_tt * 15.0) % 4 == 0 or state > 0:
			Kit.soft_glow(self, end, 14.0 if state == 0 else 34.0, Color(0.55, 0.75, 1.0, 0.55 if state == 0 else 0.85))
		if state == 1:   # מזמזם: קשתות קטנות לאורך החוט + סימן קריאה
			for q in 3:
				var p := mid.lerp(end, randf())
				draw_line(p, p + Vector2(randf_range(-10, 10), randf_range(-10, 10)), Color(0.8, 0.9, 1.0, 0.9), 1.4)
			draw_string(ThemeDB.fallback_font, end + Vector2(-6, -40), "!", HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color(0.6, 0.85, 1.0))
			draw_colored_polygon(Art.ellipse(Vector2(0, -2), W * 0.5, 6.0, 0.0, 14), Color(0.5, 0.75, 1.0, 0.12 + 0.1 * sin(_tt * 30.0)))
		if state == 2:   # הקשת: ברק שבור מהקצה לקרקע + פיצוץ אור
			for b in 3:
				var pts := PackedVector2Array([end])
				var p2 := end
				for q in 5:
					p2 = p2 + Vector2(randf_range(-26, 26), randf_range(-6, 18))
					pts.append(p2)
				draw_polyline(pts, Color(0.85, 0.95, 1.0, 0.9), 2.0 if b == 0 else 1.2)
			Kit.soft_glow(self, Vector2(0, -10), 120.0, Color(0.55, 0.75, 1.0, 0.5))
			draw_colored_polygon(Art.ellipse(Vector2(0, -2), W * 0.6, 8.0, 0.0, 14), Color(0.8, 0.9, 1.0, 0.45))


# ---- הגלגלת של בית הקטרים (זירת THE ENGINE) + תא בקרה מוגבה ----
class Turntable extends Node2D:
	var w := 900.0
	var booth_tier := 150.0
	var _t := 0.0

	func _ready() -> void:
		z_index = -1

	func _process(delta: float) -> void:
		_t += delta
		if Engine.get_process_frames() % 8 == 0 and Art.on_screen(self, global_position + Vector2(w * 0.5, -100.0), w * 0.6):
			queue_redraw()

	func _draw() -> void:
		# קיר הרוטונדה מאחור: שער ענק ושלט
		draw_rect(Rect2(40.0, -330.0, w - 80.0, 330.0), Color("5a3028"))
		for q in 30:
			draw_line(Vector2(40.0, -320.0 + float(q) * 11.0), Vector2(w - 40.0, -320.0 + float(q) * 11.0), Color(0.25, 0.12, 0.08, 0.35), 1.0)
		for q in 3:
			var gx := 120.0 + float(q) * 250.0
			draw_rect(Rect2(gx, -240.0, 150.0, 240.0), Color("120c0e"))
			draw_arc(Vector2(gx + 75.0, -240.0), 75.0, PI, TAU, 16, Color("3a1e16"), 10.0)
			draw_colored_polygon(PackedVector2Array([Vector2(gx, -240), Vector2(gx + 75, -315), Vector2(gx + 150, -240)]), Color("120c0e"))
			for s in 4:   # קורות זכוכית שבורות
				draw_line(Vector2(gx + 10.0 + float(s) * 40.0, -300.0), Vector2(gx + 10.0 + float(s) * 40.0, -246.0), Color("3a2a26"), 3.0)
		draw_string(ThemeDB.fallback_font, Vector2(w * 0.5 - 80.0, -300.0), "TALLERES  ESCALADA", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(0.9, 0.8, 0.6, 0.8))
		# הגלגלת עצמה: בור רדוד עם גשר מסתובב (על הריצפה)
		var cx := w * 0.5
		draw_colored_polygon(Art.ellipse(Vector2(cx, 2.0), 300.0, 12.0, 0.0, 30), Color("1a1416"))
		var a := sin(_t * 0.15) * 0.6
		var dx := cos(a) * 280.0
		draw_line(Vector2(cx - dx, 2.0 + sin(a) * 6.0), Vector2(cx + dx, 2.0 - sin(a) * 6.0), Color("4a4448"), 8.0)
		draw_line(Vector2(cx - dx, -1.0 + sin(a) * 6.0), Vector2(cx + dx, -1.0 - sin(a) * 6.0), Color("8a8480"), 2.0)
		# תא הבקרה המוגבה (הקומה = add_floor בשלב)
		var bx := 40.0
		draw_rect(Rect2(bx, -booth_tier - 70.0, 150.0, 70.0), Color("3a3a40"))
		draw_rect(Rect2(bx + 14.0, -booth_tier - 56.0, 122.0, 30.0), Color(1.0, 0.7, 0.35, 0.35 + 0.1 * sin(_t * 2.0)))
		draw_rect(Rect2(bx - 10.0, -booth_tier, 170.0, 10.0), STEEL_D)
		draw_rect(Rect2(bx - 10.0, -booth_tier, 170.0, 3.0), STEEL)
		for lx in [bx, bx + 140.0]:
			draw_rect(Rect2(lx, -booth_tier + 10.0, 8.0, booth_tier - 10.0), Color("2a2a30"))
		Kit.soft_glow(self, Vector2(bx + 75.0, -booth_tier - 40.0), 80.0, Color(1.0, 0.7, 0.35, 0.25))


# ============================================================
#  מכשולים
# ============================================================
class Obstacle extends Node2D:
	var kind := "buffer"
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
		match kind:
			"buffer":   # מעצור סוף מסילה: מסגרת ברזל עם פסים אדומים-לבנים ובולמים
				draw_rect(Rect2(w * 0.1, -h, w * 0.8, h), Color("2a2a30"))
				draw_rect(Rect2(w * 0.1, -h, w * 0.8, h * 0.4), Color("e8e0d0"))
				for q in 4:
					var sx := w * 0.1 + float(q) * w * 0.2
					draw_colored_polygon(PackedVector2Array([Vector2(sx, -h), Vector2(sx + w * 0.1, -h), Vector2(sx + w * 0.2, -h * 0.6), Vector2(sx + w * 0.1, -h * 0.6)]), Color("c02a20"))
				for bx in [0.0, w * 0.86]:
					draw_rect(Rect2(bx, -h * 0.75, w * 0.14, h * 0.16), Color("5a5a62"))
					draw_circle(Vector2(bx + w * 0.07, -h * 0.67), h * 0.12, Color("8a8a92"))
				draw_line(Vector2(w * 0.1, 0), Vector2(w * 0.5, -h * 0.5), Color("3a3a42"), 3.0)
				draw_line(Vector2(w * 0.9, 0), Vector2(w * 0.5, -h * 0.5), Color("3a3a42"), 3.0)
			"sleepers":   # ערימת אדני עץ
				var n := int(h / 9.0)
				for q in n:
					var y0 := -float(q + 1) * 9.0
					var off := float((q * 7 + seed_v) % 5) - 2.0
					draw_rect(Rect2(off, y0, w, 8.0), Color("4a3426").lightened(0.04 * float(q % 3)))
					draw_rect(Rect2(off, y0, w, 2.0), Color("6a4c36"))
					draw_line(Vector2(off + w * 0.3, y0 + 4.0), Vector2(off + w * 0.6, y0 + 4.0), Color(0.15, 0.1, 0.06, 0.5), 1.0)
			"crates":
				var cw := w * 0.5
				for q in 3:
					var r := Rect2(float(q % 2) * cw, -h * 0.5, cw - 2.0, h * 0.5) if q < 2 else Rect2(w * 0.25, -h, cw - 2.0, h * 0.5)
					draw_rect(r, Color("7a5a3a"))
					draw_rect(r, Color("4a3220"), false, 2.0)
					draw_line(r.position, r.end, Color("4a3220"), 2.0)
					draw_line(Vector2(r.position.x, r.end.y), Vector2(r.end.x, r.position.y), Color("4a3220"), 2.0)
					draw_string(ThemeDB.fallback_font, r.position + Vector2(4, 12), "FCS", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color(0.15, 0.1, 0.05, 0.7))
			_:   # "wheels" - זוג גלגלי רכבת על ציר, על מתלה עץ
				draw_rect(Rect2(0, -10.0, w, 10.0), WOOD)
				var r2 := h * 0.42
				for wx in [w * 0.25, w * 0.75]:
					draw_circle(Vector2(wx, -h * 0.55), r2, Color("2a2628"))
					draw_circle(Vector2(wx, -h * 0.55), r2 * 0.75, Color("4a4448"))
					draw_circle(Vector2(wx, -h * 0.55), r2 * 0.22, Color("8a8480"))
					draw_arc(Vector2(wx, -h * 0.55), r2, -2.4, -0.8, 8, Color("8a8480"), 2.0)
				draw_line(Vector2(w * 0.25, -h * 0.55), Vector2(w * 0.75, -h * 0.55), Color("5a5450"), 6.0)


# ============================================================
#  מסך: סמוג שנע + פיח וגחלים
# ============================================================
class YardFX extends Node2D:
	var vp := Vector2(1280, 720)
	var _t := 0.0

	func _process(delta: float) -> void:
		_t += delta
		if Engine.get_process_frames() % 2 == 0:
			queue_redraw()

	func _draw() -> void:
		var q := clampf(Quality.ambient(), 0.3, 1.0)
		var n := int(30.0 * q)
		for i in n:   # פיח שחור + גחלים כתומות שעולות
			var ember := i % 4 == 0
			var x := fposmod(float(i) * 113.0 - _t * (14.0 + float(i % 5) * 5.0), vp.x)
			var y := fposmod(float(i) * 71.0 + (-_t * 22.0 if ember else _t * 9.0) + sin(_t * 0.8 + float(i)) * 20.0, vp.y)
			if ember:
				draw_rect(Rect2(x, y, 2.0, 2.0), Color(1.0, 0.55, 0.2, 0.75))
			else:
				draw_rect(Rect2(x, y, 2.0, 1.5), Color(0.12, 0.1, 0.1, 0.45))
		for s in 2:   # שכבות סמוג רכות שנעות לאט
			var sx := fposmod(_t * (10.0 + float(s) * 6.0) + float(s) * 500.0, vp.x + 1200.0) - 600.0
			Kit.soft_ellipse(self, Vector2(sx, vp.y * (0.35 + float(s) * 0.25)), 700.0, 90.0, 0.0, Color(0.55, 0.38, 0.3, 0.08 * q))
		draw_rect(Rect2(0, 0, vp.x, vp.y), Color(1.0, 0.6, 0.3, 0.04))   # גוון כתום של סמוג
