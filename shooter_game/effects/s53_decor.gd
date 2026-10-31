extends RefCounted
const DrawBatch := preload("res://effects/draw_batch.gd")
# ============================================================
#  קישוטים לשלב 53 ("CAPITAL SIEGE") - מונטווידאו, העיר העתיקה (Ciudad Vieja) תחת מצור, בוקר קר אפור-כחול.
#  החיים מחזיקים את העיר העתיקה, המתים תוקפים אותה: מחסומים של אוטובוסים ושקי חול, שער הסיטדלה, מרפסות ברזל.
#    siege_sky     - (רקע) בוקר קר ומעונן: עמודי עשן מהעיר, שחפים, זרקור שסורק לאט את העננים
#    far_river     - (רקע, 0.06) ה-Rio de la Plata הרחב: הגבעה (Cerro) עם המבצר והמגדלור, אוניות בוערות באופק, מנופי הנמל
#    mid_oldcity   - (רקע, 0.28) Palacio Salvo ומגדלי העיר, הדגלים של המגינים, זרקורים, והעדר - ים של מתים שגועש
#                    מחוץ לחומה, ופירמידות של גופות שמטפסות עליה (כמו STACKER)
#    near_barricade- (רקע, 0.6) קיפודים צ'כיים מפלדה, גלילי תיל, שקי חול, עמוד מודעות עם פוסטרים שמתנופפים, עשן נסחף
#    haze          - (overlay) אובך קר מאחורי הדמויות (קריאות)
#    SiegeGround   - (עולם) אבני ריצוף (adoquines) עם פסי חשמלית
#    CitadelGate   - (עולם) Puerta de la Ciudadela: שער אבן עם קשת. הגג = הקומה (add_floor) + 2 סולמות
#    Facade        - (עולם) חזית קולוניאלית (שני קומות, צבעי פסטל) עם מרפסת ברזל = קומה (add_floor) + סולם
#    BusBarricade  - (עולם, מוצק + מחסה) אוטובוס שרוף שחוסם את הרחוב. עומדים על הגג (סולם בצד)
#    OilDrum       - (עולם, מלכודת של המגינים) חבית שמן תלויה על פיגום מעל הכביש. יורים בה -> נשפכת ובוערת
#                    (fire_zone) לרוחב POUR_W ל-BURN_T שניות. שורף מגדלי STACKER (וגם אותך אם אתה מתחת).
#    BreachWall    - (עולם, מלכודת) מחסום גרוטאות בצד הרחוב שהעדר דוחף מאחוריו. מתקרבים -> רועד וחורק (WARN_T, "!")
#                    -> קורס קדימה: גרוטאות על הכביש (DMG לשחקן, DMG_Z לזומבים) ו-BURST זומבים פורצים דרך הפרצה.
#    ArenaBarricade- (עולם, מוצק + מחסה) מחסום שקי חול בזירת הבוס. איל הניגוח של THE SIEGE TOWER מנפץ אותו (smash).
#    SeaWall       - (עולם) הרמבלה בסוף השלב: מעקה אבן, הים, פנסים ואותיות "MONTEVIDEO"
#    Obstacle      - (מוצק + מחסה) "sandbags" קיר שקי חול / "tram" קרון חשמלית ישן / "stalls" דוכני שוק עם סוכך
#    SiegeFX       - (מסך) פסי ערפל קר שזזים + הבהובי ארטילריה רחוקים
#  לשנות: OilDrum.POUR_W / BURN_T, BreachWall.WARN_T / DMG / DMG_Z / BURST, ArenaBarricade.SIZE.
# ============================================================

const Art := preload("res://art.gd")
const Kit := preload("res://effects/backdrop_kit.gd")
const Sfx := preload("res://sfx.gd")

const STONE := Color("8a8274")
const STONE_D := Color("5e584e")
const COBBLE := Color("5a5852")
const SAND := Color("a8946a")
const SAND_D := Color("7a6a48")
const RUST := Color("6a3a24")
const HOUSES := [Color("c8a868"), Color("c88a7a"), Color("8aa8b8"), Color("b8b48a"), Color("a88aa0"), Color("d0b898")]
const FLAG_BLUE := Color("2a4a9a")


static func _h(i: int, s: int) -> float:
	return fposmod(sin(float(i) * 12.9898 + float(s) * 78.233) * 43758.5453, 1.0)


# דגל אורוגוואי שמתנופף (9 פסים לבן/כחול + השמש של מאי בפינה)
static func flag(ci: CanvasItem, top: Vector2, w: float, h: float, t: float, ph := 0.0) -> void:
	var n := 6
	var sh := h / 9.0
	for s in 9:
		var col := Color("e8e8e0") if s % 2 == 0 else FLAG_BLUE
		var pts := PackedVector2Array()
		for i in n + 1:
			var u := float(i) / float(n)
			pts.append(top + Vector2(u * w, float(s) * sh + sin(t * 4.0 + u * 5.0 + ph) * 2.2 * u))
		for i in range(n, -1, -1):
			var u2 := float(i) / float(n)
			pts.append(top + Vector2(u2 * w, float(s + 1) * sh + sin(t * 4.0 + u2 * 5.0 + ph) * 2.2 * u2))
		DrawBatch.colored_polygon(ci, pts, col)
	var cw := w * 0.36
	DrawBatch.rect(ci, Rect2(top, Vector2(cw, sh * 5.0)), Color("e8e8e0"))
	DrawBatch.circle(ci, top + Vector2(cw * 0.5, sh * 2.5), sh * 1.3, Color("f0c030"))


# ============================================================
#  רקע
# ============================================================
static func siege_sky(ci: CanvasItem, v: Vector2, t: float) -> void:
	var cols := [Color("44505e"), Color("5c6876"), Color("7c8792"), Color("9aa2a6"), Color("b0aea4")]
	var steps := 32
	for i in steps:
		var k := float(i) / float(steps - 1)
		var f := k * float(cols.size() - 1)
		var a := int(floor(f))
		var b := mini(a + 1, cols.size() - 1)
		DrawBatch.rect(ci, Rect2(0, v.y * 0.86 * k, v.x, v.y * 0.86 / float(steps - 1) + 1.0), (cols[a] as Color).lerp(cols[b], f - float(a)))
	DrawBatch.rect(ci, Rect2(0, v.y * 0.86, v.x, v.y * 0.14), cols[cols.size() - 1])
	var sun := Vector2(v.x * 0.3, v.y * 0.3)   # שמש חיוורת מאחורי העננים
	Kit.soft_glow(ci, sun, 150.0, Color(1.0, 0.96, 0.86, 0.18))
	DrawBatch.circle(ci, sun, 20.0, Color(1.0, 0.98, 0.92, 0.42))
	for i in 9:   # רצועות עננים נמוכות וכבדות שזזות לאט
		var y := v.y * (0.08 + float(i) * 0.065)
		var x := fposmod(float(i) * 330.0 + t * (5.0 + float(i % 3) * 2.5), v.x + 900.0) - 450.0
		Kit.soft_ellipse(ci, Vector2(x, y), 360.0 + float(i % 3) * 110.0, 34.0 + float(i % 2) * 14.0, 0.0, Color(0.32, 0.36, 0.42, 0.32))
	# זרקור שסורק לאט את בטן העננים (מהעיר)
	for q in 2:
		var base := Vector2(v.x * (0.62 + 0.25 * float(q)), v.y * 0.86)
		var ang := -PI * 0.5 + sin(t * (0.22 + 0.07 * float(q)) + float(q) * 2.0) * 0.55
		var d := Vector2.from_angle(ang)
		var nrm := d.orthogonal()
		var L := v.y * 0.95
		DrawBatch.polygon(ci, PackedVector2Array([base - nrm * 3.0, base + nrm * 3.0, base + d * L + nrm * 46.0, base + d * L - nrm * 46.0]),
			PackedColorArray([Color(0.95, 0.97, 1.0, 0.16), Color(0.95, 0.97, 1.0, 0.16), Color(0.95, 0.97, 1.0, 0.0), Color(0.95, 0.97, 1.0, 0.0)]))
	# עמודי עשן כבדים מהעיר הבוערת (רחוקים, קבועים במסך)
	for q in 4:
		var bx := v.x * (0.12 + 0.24 * float(q)) + sin(float(q) * 3.1) * 40.0
		Kit.soft_smoke(ci, Vector2(bx, v.y * 0.8), t + float(q) * 4.0, 420.0, Color(0.16, 0.16, 0.18, 0.34), 150.0, 9)
	# שחפים
	for i in 6:
		var gx := fposmod(float(i) * 233.0 + t * (26.0 + float(i) * 4.0), v.x + 260.0) - 130.0
		var gy := v.y * 0.18 + float(i % 3) * 34.0 + sin(t * 0.8 + float(i)) * 14.0
		var fl := sin(t * 6.0 + float(i) * 1.7) * 5.0
		DrawBatch.polyline(ci, PackedVector2Array([Vector2(gx - 11, gy + fl), Vector2(gx - 4, gy - 3), Vector2(gx, gy), Vector2(gx + 4, gy - 3), Vector2(gx + 11, gy + fl)]), Color(0.92, 0.92, 0.9, 0.85), 1.6)


# ---- הנהר הרחב, הגבעה עם המבצר, אוניות בוערות ----
static func far_river(ci: CanvasItem, sc: float, v: Vector2, y: float, t: float) -> void:
	var hz := y - 64.0   # קו האופק
	DrawBatch.rect(ci, Rect2(0, hz, v.x, v.y - hz), Color("72787a"))   # מים אפורים-חומים
	for q in 10:   # ניצוצות על המים
		var wy := hz + 6.0 + float(q) * 8.0
		var wx := fposmod(float(q) * 191.0 - sc * 0.5 + sin(t * 0.6 + float(q)) * 24.0, v.x + 240.0) - 120.0
		DrawBatch.line(ci, Vector2(wx, wy), Vector2(wx + 50.0 + float(q % 3) * 24.0, wy), Color(0.86, 0.88, 0.86, 0.28), 1.4)
	var period := 2400.0
	var start := int(floor(sc / period)) - 1
	for k in range(start, start + int(ceil(v.x / period)) + 2):
		var bx := float(k) * period - sc
		# הגבעה (Cerro) והמבצר בראשה
		var hc := Vector2(bx + 700.0, hz)
		DrawBatch.colored_polygon(ci, PackedVector2Array([hc + Vector2(-340, 2), hc + Vector2(-180, -40), hc + Vector2(-60, -84), hc + Vector2(0, -92),
			hc + Vector2(70, -82), hc + Vector2(200, -36), hc + Vector2(360, 2)]), Color("6a7270"))
		DrawBatch.rect(ci, Rect2(hc.x - 46.0, hc.y - 112.0, 92.0, 24.0), Color("626a6a"))   # חומות המבצר
		for m in 8:
			DrawBatch.rect(ci, Rect2(hc.x - 46.0 + float(m) * 12.0, hc.y - 117.0, 7.0, 6.0), Color("626a6a"))
		DrawBatch.colored_polygon(ci, PackedVector2Array([hc + Vector2(-56, -88), hc + Vector2(-46, -112), hc + Vector2(-38, -88)]), Color("5c6464"))   # מעוז
		DrawBatch.rect(ci, Rect2(hc.x + 18.0, hc.y - 150.0, 10.0, 40.0), Color("6c7272"))   # המגדלור
		DrawBatch.rect(ci, Rect2(hc.x + 15.0, hc.y - 156.0, 16.0, 7.0), Color("5a6060"))
		var beam := fmod(t * 0.4 + float(k) * 0.3, 1.0)
		if beam < 0.5:   # האור של המגדלור מסתובב
			var bd := Vector2(cos(beam * TAU * 2.0), 0.08)
			DrawBatch.colored_polygon(ci, PackedVector2Array([hc + Vector2(23, -152), hc + Vector2(23, -152) + bd * 140.0 + Vector2(0, -10), hc + Vector2(23, -152) + bd * 140.0 + Vector2(0, 10)]), Color(1.0, 0.95, 0.75, 0.16))
		Kit.soft_glow(ci, hc + Vector2(23, -152), 10.0, Color(1.0, 0.92, 0.6, 0.7))
		# מנופי הנמל
		for q in 3:
			var cx := bx + 1350.0 + float(q) * 90.0
			var cc := Color("5e6668")
			DrawBatch.line(ci, Vector2(cx, hz), Vector2(cx, hz - 90.0), cc, 4.0)
			DrawBatch.line(ci, Vector2(cx - 30.0, hz - 90.0), Vector2(cx + 60.0, hz - 90.0), cc, 3.0)
			DrawBatch.line(ci, Vector2(cx, hz - 112.0), Vector2(cx + 60.0, hz - 90.0), cc, 1.5)
			DrawBatch.line(ci, Vector2(cx, hz - 112.0), Vector2(cx - 30.0, hz - 90.0), cc, 1.5)
			DrawBatch.line(ci, Vector2(cx + 50.0, hz - 90.0), Vector2(cx + 50.0, hz - 70.0 + sin(t * 0.7 + float(q)) * 3.0), cc, 1.0)
		# אוניות בוערות באופק (עשן נוטה ברוח)
		for q in 2:
			var sx := bx + 1750.0 + float(q) * 330.0
			var sy := hz - 2.0 + sin(t * 0.8 + float(q)) * 0.8
			DrawBatch.colored_polygon(ci, PackedVector2Array([Vector2(sx - 70, sy - 12), Vector2(sx + 74, sy - 14), Vector2(sx + 62, sy + 2), Vector2(sx - 62, sy + 2)]), Color("3e4446"))
			DrawBatch.rect(ci, Rect2(sx - 20.0, sy - 34.0, 34.0, 22.0), Color("464c4e"))
			DrawBatch.rect(ci, Rect2(sx + 24.0, sy - 44.0, 8.0, 30.0), Color("464c4e"))
			Kit.fire_glow(ci, Vector2(sx - 4.0, sy - 14.0), t, 32.0, q + k * 3)
			Kit.soft_smoke(ci, Vector2(sx - 4.0, sy - 24.0), t + float(q) * 3.0, 160.0, Color(0.14, 0.13, 0.13, 0.42), 120.0, 7)
	DrawBatch.rect(ci, Rect2(0, hz - 6.0, v.x, 14.0), Color(0.78, 0.8, 0.8, 0.22))   # ערפל על האופק


# ---- Palacio Salvo, העיר, הדגלים, הזרקורים והעדר מחוץ לחומה ----
static func mid_oldcity(ci: CanvasItem, sc: float, v: Vector2, y: float, t: float) -> void:
	var gl := y - 54.0   # קו הקרקע של השכבה
	Kit.skyline(ci, sc, v, gl - 30.0, Color("68707c"), 53, Vector2(70, 150), Vector2(110, 230), 0.05, Color(1.0, 0.6, 0.3, 0.8), t, 0.25)
	var period := 2200.0
	var start := int(floor(sc / period)) - 1
	for k in range(start, start + int(ceil(v.x / period)) + 2):
		var bx := float(k) * period - sc
		_salvo(ci, Vector2(bx + 520.0, gl - 30.0), t, k)
		_cathedral(ci, Vector2(bx + 1500.0, gl - 30.0), t)
	# העדר: ים של מתים שגועש מול החומה
	var herd := PackedVector2Array()
	var base_y := gl + 6.0
	herd.append(Vector2(-20.0, base_y + 20.0))
	var x := -20.0
	while x <= v.x + 20.0:
		var wx := x + sc
		var top := base_y - 22.0 - 7.0 * sin(wx * 0.011 + t * 1.6) - 4.0 * sin(wx * 0.043 - t * 2.7) - 3.0 * absf(sin(wx * 0.31 + t * 3.0))
		herd.append(Vector2(x, top))
		x += 8.0
	herd.append(Vector2(v.x + 20.0, base_y + 20.0))
	DrawBatch.colored_polygon(ci, herd, Color("3a3c40"))
	var arms := PackedVector2Array()   # ידיים מורמות (קריאה אחת)
	x = fposmod(-sc, 23.0) - 23.0
	var i := 0
	while x <= v.x + 20.0:
		var wx2 := x + sc
		var top2 := base_y - 24.0 - 7.0 * sin(wx2 * 0.011 + t * 1.6)
		var sw := sin(t * 3.4 + wx2 * 0.07) * 5.0
		arms.append(Vector2(x, top2 + 4.0))
		arms.append(Vector2(x + sw, top2 - 10.0 - 4.0 * _h(i, 9)))
		x += 23.0
		i += 1
	DrawBatch.multiline(ci, arms, Color("34363a"), 2.0)
	# החומה של המגינים: שקי חול, דמויות עם רובים, הבזקי ירי, ופירמידות של גופות שמטפסות עליה
	var wall_y := base_y + 4.0
	DrawBatch.rect(ci, Rect2(0, wall_y, v.x, v.y - wall_y), Color("4e4c48"))
	DrawBatch.rect(ci, Rect2(0, wall_y, v.x, 4.0), Color("6a665e"))
	var wp := 640.0
	var ws := int(floor(sc / wp)) - 1
	for k2 in range(ws, ws + int(ceil(v.x / wp)) + 2):
		var wx3 := float(k2) * wp - sc
		for s in 9:   # שקי חול על החומה
			DrawBatch.colored_polygon(ci, Art.ellipse(Vector2(wx3 + 40.0 + float(s) * 16.0, wall_y - 3.0), 9.0, 4.5, 0.0, 8), Color("8a7a58"))
		for d in 2:   # מגינים קטנים
			var dx := wx3 + 70.0 + float(d) * 60.0
			DrawBatch.rect(ci, Rect2(dx, wall_y - 18.0, 5.0, 12.0), Color("2e3230"))
			DrawBatch.circle(ci, Vector2(dx + 2.5, wall_y - 20.0), 2.6, Color("2e3230"))
			DrawBatch.line(ci, Vector2(dx + 4.0, wall_y - 14.0), Vector2(dx + 14.0, wall_y - 17.0), Color("1e2020"), 1.5)
			if fmod(t * 3.0 + float(d) * 0.37 + float(k2) * 0.71, 1.7) < 0.08:
				Kit.soft_glow(ci, Vector2(dx + 16.0, wall_y - 17.0), 7.0, Color(1.0, 0.85, 0.45, 0.9))
		# פירמידת גופות שמטפסת (גדלה ונופלת במחזור)
		var cyc := fmod(t * 0.12 + float(k2) * 0.37, 1.0)
		var px := wx3 + 380.0
		var nh := int(cyc * 7.0)
		for r in nh:
			var rw := 6 - r
			for c in maxi(rw, 1):
				var hp := Vector2(px + (float(c) - float(rw - 1) * 0.5) * 8.0, wall_y - 2.0 - float(r) * 7.0)
				DrawBatch.circle(ci, hp, 3.2, Color("38393c"))
		if nh >= 6:
			DrawBatch.line(ci, Vector2(px, wall_y - 44.0), Vector2(px + 6.0, wall_y - 52.0), Color("38393c"), 2.0)
		# דגל על החומה
		DrawBatch.line(ci, Vector2(wx3 + 260.0, wall_y), Vector2(wx3 + 260.0, wall_y - 54.0), Color("2a2a2a"), 2.0)
		flag(ci, Vector2(wx3 + 261.0, wall_y - 54.0), 30.0, 20.0, t, float(k2))
		# זרקור על החומה
		var ang := -PI * 0.5 - 0.6 + sin(t * 0.35 + float(k2) * 1.3) * 0.5
		var d2 := Vector2.from_angle(ang)
		var sp := Vector2(wx3 + 560.0, wall_y - 6.0)
		DrawBatch.polygon(ci, PackedVector2Array([sp - d2.orthogonal() * 2.0, sp + d2.orthogonal() * 2.0, sp + d2 * 260.0 + d2.orthogonal() * 26.0, sp + d2 * 260.0 - d2.orthogonal() * 26.0]),
			PackedColorArray([Color(1, 1, 0.92, 0.2), Color(1, 1, 0.92, 0.2), Color(1, 1, 0.92, 0.0), Color(1, 1, 0.92, 0.0)]))
		DrawBatch.rect(ci, Rect2(sp.x - 5.0, sp.y - 4.0, 10.0, 8.0), Color("2a2a2a"))


static func _salvo(ci: CanvasItem, b: Vector2, t: float, k: int) -> void:
	var c := Color("7a7c84")
	var cd := Color("6a6c74")
	var win := Color("50525a")
	# בסיס רחב (8 קומות)
	DrawBatch.rect(ci, Rect2(b.x - 70.0, b.y - 150.0, 140.0, 150.0), c)
	for f in 8:
		for w in 9:
			var wy := b.y - 142.0 + float(f) * 17.0
			var lit := _h(f * 9 + w + k * 31, 3) < 0.07
			DrawBatch.rect(ci, Rect2(b.x - 62.0 + float(w) * 14.4, wy, 7.0, 10.0), Color(1.0, 0.7, 0.35, 0.8) if lit else win)
	DrawBatch.rect(ci, Rect2(b.x - 74.0, b.y - 154.0, 148.0, 6.0), cd)
	# המגדל המדורג
	DrawBatch.rect(ci, Rect2(b.x - 40.0, b.y - 238.0, 80.0, 88.0), c)
	for f in 5:
		for w in 5:
			DrawBatch.rect(ci, Rect2(b.x - 33.0 + float(w) * 14.5, b.y - 230.0 + float(f) * 16.0, 6.0, 10.0), win)
	DrawBatch.rect(ci, Rect2(b.x - 44.0, b.y - 242.0, 88.0, 6.0), cd)
	DrawBatch.rect(ci, Rect2(b.x - 24.0, b.y - 290.0, 48.0, 50.0), c)
	for w in 4:   # עמודים
		DrawBatch.rect(ci, Rect2(b.x - 20.0 + float(w) * 12.5, b.y - 286.0, 3.0, 44.0), cd)
	DrawBatch.rect(ci, Rect2(b.x - 28.0, b.y - 294.0, 56.0, 5.0), cd)
	DrawBatch.colored_polygon(ci, PackedVector2Array([b + Vector2(-20, -294), b + Vector2(-14, -316), b + Vector2(0, -326), b + Vector2(14, -316), b + Vector2(20, -294)]), c)   # כיפה
	DrawBatch.line(ci, b + Vector2(0, -326), b + Vector2(0, -372), cd, 2.0)   # אנטנה
	if int(t * 1.5) % 2 == 0:
		DrawBatch.circle(ci, b + Vector2(0, -372), 2.2, Color(1.0, 0.25, 0.2, 0.9))
	# זרקור על הגג של Salvo
	var ang := -PI * 0.5 + sin(t * 0.3 + float(k)) * 0.7
	var d := Vector2.from_angle(ang)
	var sp := b + Vector2(0, -300)
	DrawBatch.polygon(ci, PackedVector2Array([sp - d.orthogonal() * 2.0, sp + d.orthogonal() * 2.0, sp + d * 340.0 + d.orthogonal() * 34.0, sp + d * 340.0 - d.orthogonal() * 34.0]),
		PackedColorArray([Color(1, 1, 0.95, 0.22), Color(1, 1, 0.95, 0.22), Color(1, 1, 0.95, 0.0), Color(1, 1, 0.95, 0.0)]))
	# דגל ענק על החזית
	DrawBatch.line(ci, b + Vector2(56, -154), b + Vector2(56, -196), Color("2a2a2a"), 2.0)
	flag(ci, b + Vector2(57, -196), 40.0, 26.0, t, float(k) * 2.0)


static func _cathedral(ci: CanvasItem, b: Vector2, _t: float) -> void:
	var c := Color("767880")
	DrawBatch.rect(ci, Rect2(b.x - 60.0, b.y - 100.0, 120.0, 100.0), c)
	DrawBatch.colored_polygon(ci, PackedVector2Array([b + Vector2(-60, -100), b + Vector2(0, -130), b + Vector2(60, -100)]), Color("6c6e76"))
	DrawBatch.rect(ci, Rect2(b.x - 14.0, b.y - 60.0, 28.0, 60.0), Color("4a4c54"))
	DrawBatch.circle(ci, b + Vector2(0, -60), 14.0, Color("4a4c54"))
	for s in [-1.0, 1.0]:   # שני מגדלים עם כיפות מרוצפות כחול
		var tx: float = b.x + s * 74.0
		DrawBatch.rect(ci, Rect2(tx - 16.0, b.y - 170.0, 32.0, 170.0), c)
		DrawBatch.rect(ci, Rect2(tx - 8.0, b.y - 150.0, 16.0, 26.0), Color("4a4c54"))
		DrawBatch.colored_polygon(ci, Art.ellipse(Vector2(tx, b.y - 172.0), 16.0, 14.0, 0.0, 14), Color("5a6a86"))
		DrawBatch.line(ci, Vector2(tx, b.y - 186.0), Vector2(tx, b.y - 204.0), Color("5a5c64"), 2.0)
		DrawBatch.line(ci, Vector2(tx - 5.0, b.y - 198.0), Vector2(tx + 5.0, b.y - 198.0), Color("5a5c64"), 2.0)


# ---- קיפודים צ'כיים, תיל, שקי חול, פוסטרים ועשן (הכי קרוב) ----
static func near_barricade(ci: CanvasItem, sc: float, v: Vector2, y: float, t: float) -> void:
	DrawBatch.rect(ci, Rect2(0, y - 22.0, v.x, v.y - y + 22.0), Color("3a3836"))
	DrawBatch.rect(ci, Rect2(0, y - 22.0, v.x, 3.0), Color("4e4a46"))
	var period := 560.0
	var start := int(floor(sc / period)) - 1
	for k in range(start, start + int(ceil(v.x / period)) + 2):
		var x := float(k) * period - sc
		var g := y - 20.0
		# קיפוד צ'כי (שלוש קורות פלדה מוצלבות)
		var hx := x + 90.0
		var steel := Color("2e2e32")
		DrawBatch.line(ci, Vector2(hx - 34, g), Vector2(hx + 30, g - 62), steel, 7.0)
		DrawBatch.line(ci, Vector2(hx + 34, g), Vector2(hx - 30, g - 62), steel, 7.0)
		DrawBatch.line(ci, Vector2(hx - 4, g + 2), Vector2(hx + 6, g - 70), Color("3a3836"), 7.0)
		DrawBatch.line(ci, Vector2(hx - 30, g - 2), Vector2(hx + 26, g - 58), Color(0.5, 0.25, 0.14, 0.5), 2.0)   # חלודה
		# גליל תיל (ספירלה שמנצנצת)
		var wire := PackedVector2Array()
		for i in 64:
			var a := float(i) * 0.55
			wire.append(Vector2(x + 150.0 + float(i) * 3.6 + cos(a) * 9.0, g - 16.0 + sin(a) * 15.0))
		DrawBatch.polyline(ci, wire, Color("4a4a4e"), 1.5)
		for i in 8:
			DrawBatch.line(ci, Vector2(x + 154.0 + float(i) * 28.0, g - 30.0), Vector2(x + 158.0 + float(i) * 28.0, g - 33.0), Color("6a6a6e"), 1.5)
		# שורת שקי חול
		for s in 7:
			var sx := x + 380.0 + float(s) * 22.0
			for r in 2:
				var sy := g - 8.0 - float(r) * 12.0
				var ox := 11.0 if r == 1 else 0.0
				if r == 1 and s == 6:
					continue
				DrawBatch.colored_polygon(ci, Art.ellipse(Vector2(sx + ox, sy), 12.0, 6.5, 0.0, 10), SAND_D if (s + r) % 2 == 0 else SAND_D.darkened(0.1))
				DrawBatch.line(ci, Vector2(sx + ox - 8.0, sy - 2.0), Vector2(sx + ox + 8.0, sy - 2.0), Color(1, 1, 1, 0.08), 1.5)
		# עמוד מודעות עם פוסטרים שמתנופפים ברוח
		if k % 2 == 0:
			var cx := x + 300.0
			DrawBatch.rect(ci, Rect2(cx - 16.0, g - 120.0, 32.0, 120.0), Color("4a5248"))
			DrawBatch.colored_polygon(ci, Art.ellipse(Vector2(cx, g - 122.0), 20.0, 6.0, 0.0, 12), Color("3a423a"))
			DrawBatch.colored_polygon(ci, PackedVector2Array([Vector2(cx - 14, g - 124), Vector2(cx, g - 146), Vector2(cx + 14, g - 124)]), Color("3a423a"))
			for p in 3:
				var py := g - 108.0 + float(p) * 32.0
				var fl := sin(t * 5.0 + float(p) * 2.0 + float(k)) * 6.0 * (1.0 if p != 1 else 0.3)
				var pc: Color = [Color("c8b088"), Color("b85a3a"), Color("d8d0b8")][p]
				DrawBatch.colored_polygon(ci, PackedVector2Array([Vector2(cx - 13, py), Vector2(cx + 13, py), Vector2(cx + 13 + fl, py + 26), Vector2(cx - 13 + fl * 0.4, py + 24)]), pc.darkened(0.25))
				DrawBatch.line(ci, Vector2(cx - 9, py + 8), Vector2(cx + 9 + fl * 0.3, py + 9), Color(0.15, 0.1, 0.08, 0.6), 2.0)
	# עשן נסחף נמוך
	for q in 5:
		var wx := fposmod(float(q) * 297.0 - sc * 1.1 + t * 18.0, v.x + 400.0) - 200.0
		Kit.soft_ellipse(ci, Vector2(wx, y - 40.0 - float(q % 2) * 26.0), 150.0, 26.0, 0.0, Color(0.55, 0.56, 0.58, 0.16))


# אובך קר מאחורי הדמויות (קריאות)
static func haze(ci: CanvasItem, v: Vector2, _t: float) -> void:
	Kit.haze_band(ci, v, 420.0, 612.0, Color(0.72, 0.76, 0.8, 0.22))


# ============================================================
#  עולם
# ============================================================
class SiegeGround extends Node2D:   # אבני ריצוף עם פסי חשמלית
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
		DrawBatch.rect(self, Rect2(0, 0, w, depth), Color("3a3834"))
		var row := 0
		var yy := 0.0
		while yy < 22.0:
			var off := 9.0 if row % 2 == 1 else 0.0
			var x := -off
			var i := 0
			while x < w:
				var c := COBBLE.lerp(Color("6a665c"), _h2(i + row * 97) * 0.6)
				DrawBatch.rect(self, Rect2(x + 1.0, yy + 1.0, 16.0, 6.0), c)
				DrawBatch.rect(self, Rect2(x + 1.0, yy + 1.0, 16.0, 1.5), c.lightened(0.12))
				x += 18.0
				i += 1
			yy += 7.5
			row += 1
		DrawBatch.rect(self, Rect2(0, 0, w, 2), Color("7a766c"))
		for ry in [6.0, 15.0]:   # פסי חשמלית
			DrawBatch.rect(self, Rect2(0, ry, w, 3.0), Color("6a6660"))
			DrawBatch.rect(self, Rect2(0, ry, w, 1.0), Color("9a968c"))
		for q in int(w / 140.0) + 1:   # כתמי דם / פיח
			if _h2(q + 500) < 0.35:
				DrawBatch.colored_polygon(self, Art.ellipse(Vector2(float(q) * 140.0 + 40.0, 4.0), 18.0, 3.0, 0.0, 10), Color(0.25, 0.04, 0.04, 0.5) if _h2(q) < 0.5 else Color(0.1, 0.1, 0.1, 0.45))

	func _h2(i: int) -> float:
		return fposmod(sin(float(i) * 12.9898 + position.x * 0.013 + float(seed_v)) * 43758.5453, 1.0)


# ---- Puerta de la Ciudadela: שער אבן עם קשת, גג = קומה ----
class CitadelGate extends Node2D:
	var w := 380.0
	var tier := 170.0
	var _t := 0.0

	func _ready() -> void:
		z_index = -1

	func _process(delta: float) -> void:
		_t += delta
		if Engine.get_process_frames() % 4 == 0 and Art.on_screen(self, global_position + Vector2(w * 0.5, -tier), w):
			queue_redraw()

	func _draw() -> void:
		DrawBatch.begin(self)
		_draw_b()
		DrawBatch.end(self)

	func _draw_b() -> void:
		var top := -tier
		DrawBatch.rect(self, Rect2(0, top, w, tier), STONE)
		for r in int(tier / 18.0):   # שורות אבן
			var yy := top + float(r) * 18.0
			DrawBatch.line(self, Vector2(0, yy), Vector2(w, yy), STONE_D, 1.0)
			var off := 0.0 if r % 2 == 0 else 22.0
			var x := off
			while x < w:
				DrawBatch.line(self, Vector2(x, yy), Vector2(x, yy + 18.0), STONE_D, 1.0)
				x += 44.0
		# הקשת (הכביש עובר דרכה)
		var ac := Vector2(w * 0.5, -90.0)
		var aw := 64.0
		DrawBatch.rect(self, Rect2(ac.x - aw, ac.y, aw * 2.0, 90.0), Color("2a2824"))
		DrawBatch.circle(self, ac, aw, Color("2a2824"))
		for q in 13:   # אבני הקשת
			var a := PI + float(q) / 12.0 * PI
			DrawBatch.line(self, ac + Vector2.from_angle(a) * aw, ac + Vector2.from_angle(a) * (aw + 14.0), STONE_D, 2.0)
		DrawBatch.arc(self, ac, aw + 14.0, PI, TAU, 24, STONE.lightened(0.12), 2.0)
		DrawBatch.rect(self, Rect2(ac.x - 9.0, ac.y - aw - 20.0, 18.0, 22.0), STONE.lightened(0.1))   # אבן ראשה
		# פילסטרים
		for px in [ac.x - aw - 40.0, ac.x + aw + 26.0]:
			DrawBatch.rect(self, Rect2(px, top + 26.0, 14.0, tier - 26.0), STONE.lightened(0.08))
			DrawBatch.rect(self, Rect2(px - 3.0, top + 24.0, 20.0, 5.0), STONE_D)
		# כתובת
		DrawBatch.string(self, ThemeDB.fallback_font, Vector2(ac.x - 82.0, top + 20.0), "PUERTA DE LA CIUDADELA", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("3a3630"))
		# צינה ומשוננים בראש
		DrawBatch.rect(self, Rect2(-6, top - 6.0, w + 12, 8.0), STONE_D)
		for m in int(w / 30.0) + 1:
			DrawBatch.rect(self, Rect2(float(m) * 30.0 - 4.0, top - 18.0, 16.0, 12.0), STONE)
			DrawBatch.rect(self, Rect2(float(m) * 30.0 - 4.0, top - 18.0, 16.0, 2.0), STONE.lightened(0.15))
		# שקי חול של המגינים על הגג
		for s in 4:
			DrawBatch.colored_polygon(self, Art.ellipse(Vector2(w * 0.25 + float(s) * 18.0, top - 22.0), 10.0, 5.0, 0.0, 10), SAND)
		# דגל
		DrawBatch.line(self, Vector2(w - 40.0, top - 6.0), Vector2(w - 40.0, top - 80.0), Color("2a2a2a"), 3.0)
		load("res://effects/s53_decor.gd").flag(self, Vector2(w - 39.0, top - 80.0), 44.0, 28.0, _t)
		# כתמי פיח וסדקים
		DrawBatch.line(self, Vector2(30, top + 40), Vector2(48, top + 70), Color(0.15, 0.13, 0.1, 0.6), 1.5)
		DrawBatch.line(self, Vector2(48, top + 70), Vector2(40, top + 96), Color(0.15, 0.13, 0.1, 0.6), 1.5)
		Kit.soft_glow(self, Vector2(w - 70.0, top + 60.0), 40.0, Color(0.05, 0.05, 0.05, 0.35))


# ---- חזית קולוניאלית עם מרפסת ברזל (המרפסת = קומה) ----
class Facade extends Node2D:
	var w := 300.0
	var tier := 160.0
	var col := Color("c8a868")
	var seed_v := 0

	func _ready() -> void:
		z_index = -1

	func _draw() -> void:
		DrawBatch.begin(self)
		_draw_b()
		DrawBatch.end(self)

	func _draw_b() -> void:
		var h := tier + 120.0
		DrawBatch.rect(self, Rect2(0, -h, w, h), col.darkened(0.12))
		DrawBatch.rect(self, Rect2(0, -h, w, 8.0), col.darkened(0.3))
		DrawBatch.rect(self, Rect2(-6, -h - 14.0, w + 12, 16.0), col.lightened(0.08))   # כרכוב
		DrawBatch.rect(self, Rect2(-6, -h - 14.0, w + 12, 3.0), col.lightened(0.25))
		for q in int(w / 22.0):   # מעקה גג
			DrawBatch.rect(self, Rect2(float(q) * 22.0 + 4.0, -h - 30.0, 6.0, 16.0), col.lightened(0.05))
		DrawBatch.rect(self, Rect2(-6, -h - 34.0, w + 12, 5.0), col.lightened(0.08))
		DrawBatch.rect(self, Rect2(0, -tier - 6.0, w, 8.0), col.darkened(0.25))   # פס בין הקומות
		var n := 3
		for q in n:   # דלתות עץ גבוהות למטה, חלונות צרפתיים למעלה
			var dx := w * (0.12 + 0.3 * float(q))
			DrawBatch.rect(self, Rect2(dx, -110.0, 44.0, 110.0), Color("4a3424"))
			DrawBatch.rect(self, Rect2(dx + 3.0, -106.0, 18.0, 50.0), Color("5a4030"))
			DrawBatch.rect(self, Rect2(dx + 23.0, -106.0, 18.0, 50.0), Color("5a4030"))
			DrawBatch.rect(self, Rect2(dx - 4.0, -116.0, 52.0, 8.0), col.lightened(0.15))
			DrawBatch.rect(self, Rect2(dx + 2.0, -tier - 96.0, 40.0, 92.0), Color("2e3436"))
			DrawBatch.rect(self, Rect2(dx + 2.0, -tier - 96.0, 40.0, 92.0), col.darkened(0.4), false, 3.0)
			DrawBatch.line(self, Vector2(dx + 22.0, -tier - 96.0), Vector2(dx + 22.0, -tier - 4.0), col.darkened(0.4), 2.0)
			DrawBatch.rect(self, Rect2(dx - 6.0, -tier - 104.0, 56.0, 8.0), col.lightened(0.15))   # משקוף מעוטר
			DrawBatch.colored_polygon(self, PackedVector2Array([Vector2(dx - 6, -tier - 104), Vector2(dx + 22, -tier - 120), Vector2(dx + 50, -tier - 104)]), col.lightened(0.1))
			# תריס פתוח שנתלה
			DrawBatch.rect(self, Rect2(dx - 14.0, -tier - 94.0, 12.0, 84.0), Color("3e5a4a") if seed_v % 2 == 0 else Color("4a4a6a"))
		# המרפסת: רצפת אבן + מעקה ברזל מסולסל
		DrawBatch.rect(self, Rect2(w * 0.06, -tier - 2.0, w * 0.88, 9.0), STONE_D)
		var rail_y := -tier - 28.0
		DrawBatch.line(self, Vector2(w * 0.06, rail_y), Vector2(w * 0.94, rail_y), Color("1e1e22"), 3.0)
		var bx := w * 0.06
		while bx < w * 0.94:
			DrawBatch.line(self, Vector2(bx, -tier - 2.0), Vector2(bx, rail_y), Color("1e1e22"), 1.5)
			DrawBatch.arc(self, Vector2(bx + 6.0, rail_y + 12.0), 5.0, 0.0, TAU, 8, Color("1e1e22"), 1.2)
			bx += 12.0
		for q in 3:   # תמוכות מתחת למרפסת
			var sx := w * (0.15 + 0.35 * float(q))
			DrawBatch.colored_polygon(self, PackedVector2Array([Vector2(sx - 6, -tier + 6), Vector2(sx + 6, -tier + 6), Vector2(sx, -tier + 22)]), STONE_D)
		# סימני מלחמה: חורי כדורים, פיח, כתובת
		for q in 6:
			DrawBatch.circle(self, Vector2(w * _hh(q), -tier + 30.0 + 70.0 * _hh(q + 9)), 1.8, Color(0.1, 0.1, 0.1, 0.8))
		Kit.soft_glow(self, Vector2(w * 0.8, -tier - 60.0), 60.0, Color(0.05, 0.04, 0.04, 0.3))
		if seed_v % 3 == 0:
			DrawBatch.string(self, ThemeDB.fallback_font, Vector2(w * 0.08, -40.0), "RESISTIR", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color(0.75, 0.15, 0.12, 0.8))

	func _hh(i: int) -> float:
		return fposmod(sin(float(i + seed_v * 13) * 12.9898) * 43758.5453, 1.0)


# ---- אוטובוס שרוף שחוסם את הרחוב (מוצק + מחסה, עומדים על הגג) ----
class BusBarricade extends Node2D:
	var size := Vector2(236, 92)
	var seed_v := 0

	func _ready() -> void:
		var body := StaticBody2D.new()
		body.collision_layer = 1
		body.add_to_group("no_outline")
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
		var paint := Color("c8b048").darkened(0.35) if seed_v % 2 == 0 else Color("3a6a9a").darkened(0.35)
		DrawBatch.rect(self, Rect2(2, -h + 6.0, w - 4.0, h - 22.0), Color("2a2624"))   # שלד שרוף
		DrawBatch.rect(self, Rect2(2, -h + 6.0, w - 4.0, h - 22.0), paint, false, 0.0)
		DrawBatch.rect(self, Rect2(2, -h * 0.45, w - 4.0, h * 0.45 - 16.0), paint)   # צבע שנשאר למטה
		for q in 6:   # כתמי חלודה ופיח
			DrawBatch.colored_polygon(self, Art.ellipse(Vector2(w * (0.1 + 0.15 * float(q)), -h * 0.3), 14.0, 8.0, 0.4, 8), Color(0.35, 0.18, 0.1, 0.6))
		for q in 7:   # חלונות שבורים (שחור)
			var wx := 12.0 + float(q) * 31.0
			DrawBatch.rect(self, Rect2(wx, -h + 14.0, 25.0, 26.0), Color("121212"))
			DrawBatch.colored_polygon(self, PackedVector2Array([Vector2(wx, -h + 14), Vector2(wx + 9, -h + 14), Vector2(wx, -h + 24)]), Color(0.7, 0.75, 0.8, 0.35))
		DrawBatch.rect(self, Rect2(0, -h, w, 7.0), Color("3a3634"))   # גג
		DrawBatch.rect(self, Rect2(0, -h, w, 2.0), Color("5a5650"))
		DrawBatch.rect(self, Rect2(-2, -18.0, w + 4.0, 6.0), Color("2a2624"))
		for wx2 in [34.0, w - 52.0]:   # גלגלים שרופים
			DrawBatch.circle(self, Vector2(wx2, -10.0), 15.0, Color("161414"))
			DrawBatch.circle(self, Vector2(wx2, -10.0), 6.0, Color("4a3a30"))
		# שקי חול ומזרנים מתחת ולצד
		for s in 4:
			DrawBatch.colored_polygon(self, Art.ellipse(Vector2(w * 0.3 + float(s) * 22.0, -6.0), 12.0, 6.0, 0.0, 10), SAND)
		# שלט מספר הקו
		DrawBatch.rect(self, Rect2(w - 46.0, -h + 9.0, 36.0, 14.0), Color("1a1a1a"))
		DrawBatch.string(self, ThemeDB.fallback_font, Vector2(w - 42.0, -h + 21.0), str(100 + seed_v % 90), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(1.0, 0.6, 0.2))
		Kit.soft_glow(self, Vector2(w * 0.5, -h + 10.0), 50.0, Color(0.05, 0.05, 0.05, 0.3))


# ---- חבית שמן תלויה על פיגום מעל הכביש: יורים בה -> נשפכת ובוערת ----
class OilDrum extends Node2D:
	const POUR_W := 170.0
	const BURN_T := 6.5
	const H := 214.0              # גובה החבית מעל הכביש
	const DMG_Z := 18             # נזק מיידי לזומבים מתחת לזרם
	var used := false
	var pours := 0                # לבדיקות
	var hint_shown := false
	var _t := 0.0
	var _tip := 0.0               # 0..1 החבית מתהפכת
	var _stream := 0.0            # זמן הזרם
	var _body: StaticBody2D

	class Hit extends StaticBody2D:
		var d = null
		func hit_by_bullet(_p: Vector2, _n: Vector2, _dir: Vector2) -> void:
			if d != null:
				d.shoot()

	func _ready() -> void:
		z_index = 2
		add_to_group("s53_drums")
		var b := Hit.new()
		b.d = self
		b.collision_layer = 4   # קליעים פוגעים (כמו זומבים)
		b.collision_mask = 0
		var cs := CollisionShape2D.new()
		var sh := RectangleShape2D.new()
		sh.size = Vector2(34, 42)
		cs.shape = sh
		cs.position = Vector2(0, -H + 6.0)
		b.add_child(cs)
		add_child(b)
		_body = b

	func shoot() -> void:
		if used:
			return
		used = true
		pours += 1
		_tip = 0.001
		Sfx.play("sg_clank", global_position + Vector2(0, -H), 2.0, 0.1, 2)
		var pl := get_tree().get_first_node_in_group("player")
		if pl != null and pl.has_method("_say"):
			pl._say("BURNING OIL!", Color("ffb050"))
		_body.queue_free()

	func _physics_process(delta: float) -> void:
		_t += delta
		if _tip > 0.0 and _tip < 1.0:
			_tip = minf(_tip + delta / 0.35, 1.0)
			if _tip >= 1.0:
				_pour()
		if _stream > 0.0:
			_stream -= delta
		# רמז: מגדל STACKER נבנה מתחת לחבית שלא השתמשו בה
		if not used and not hint_shown and Engine.get_physics_frames() % 20 == 0:
			for z in get_tree().get_nodes_in_group("stackers"):
				if z.type_mod != null and z.type_mod.in_tower() and absf(z.global_position.x - global_position.x) < 160.0:
					hint_shown = true
					var pl := get_tree().get_first_node_in_group("player")
					if pl != null and pl.has_method("_say"):
						pl._say("SHOOT THE OIL DRUM!", Color("ffd34a"))
					break
		if Art.on_screen(self, global_position + Vector2(0, -H * 0.5), 200.0) and (Engine.get_physics_frames() % 3 == 0 or _stream > 0.0 or (_tip > 0.0 and _tip < 1.0)):
			queue_redraw()

	func _pour() -> void:
		_stream = 0.9
		Sfx.play("sg_pour", global_position, 2.0, 0.1, 2)
		var FZ := preload("res://environment/fire_zone.gd")
		var f = FZ.new()
		f.setup(POUR_W, BURN_T)
		get_parent().add_child(f)
		f.global_position = global_position
		for z in get_tree().get_nodes_in_group("zombies"):
			if z.dead or absf(z.global_position.x - global_position.x) > POUR_W * 0.5 + 10.0:
				continue
			if z.global_position.y < global_position.y - H + 30.0:
				continue
			z.ignite(4.0)
			z.take_damage(DMG_Z, z.global_position + Vector2(0, -30), Vector2.DOWN, true, {"source": "hazard", "fixed": DMG_Z})
			if z.type_mod != null and z.type_mod.has_method("topple"):
				z.type_mod.topple(Vector2(randf_range(-1.0, 1.0), -0.4), "fire")

	func _draw() -> void:
		DrawBatch.begin(self)
		_draw_b()
		DrawBatch.end(self)

	func _draw_b() -> void:
		var top := -H - 40.0
		var wood := Color("5a4630")
		# פיגום: שני עמודים מצדי הכביש וקורה
		DrawBatch.line(self, Vector2(-POUR_W * 0.5 - 30.0, 0), Vector2(-POUR_W * 0.5 - 30.0, top), wood, 7.0)
		DrawBatch.line(self, Vector2(POUR_W * 0.5 + 30.0, 0), Vector2(POUR_W * 0.5 + 30.0, top), wood, 7.0)
		DrawBatch.line(self, Vector2(-POUR_W * 0.5 - 38.0, top), Vector2(POUR_W * 0.5 + 38.0, top), wood.darkened(0.15), 8.0)
		DrawBatch.line(self, Vector2(-POUR_W * 0.5 - 30.0, top + 50.0), Vector2(-POUR_W * 0.5 + 10.0, top), wood.darkened(0.2), 4.0)
		DrawBatch.line(self, Vector2(POUR_W * 0.5 + 30.0, top + 50.0), Vector2(POUR_W * 0.5 - 10.0, top), wood.darkened(0.2), 4.0)
		for s in 3:   # שקי חול בבסיס העמודים
			DrawBatch.colored_polygon(self, Art.ellipse(Vector2(-POUR_W * 0.5 - 30.0 + float(s - 1) * 14.0, -5.0), 9.0, 5.0, 0.0, 8), SAND)
			DrawBatch.colored_polygon(self, Art.ellipse(Vector2(POUR_W * 0.5 + 30.0 + float(s - 1) * 14.0, -5.0), 9.0, 5.0, 0.0, 8), SAND)
		# שרשרת + החבית (מתהפכת)
		var hook := Vector2(0, top + 4.0)
		var sway := sin(_t * 1.3) * 0.04 * (1.0 - _tip)
		var c := Vector2(0, -H + 6.0)
		DrawBatch.line(self, hook, c + Vector2(0, -22), Color("3a3a3a"), 2.0)
		var rot := sway + _tip * 2.1
		DrawBatch.set_transform(self, c, rot, Vector2.ONE)
		var body := Color("7a2a1e") if not used else Color("4a2a20")
		DrawBatch.rect(self, Rect2(-16, -21, 32, 42), body)
		DrawBatch.rect(self, Rect2(-16, -21, 6, 42), Color(1, 1, 1, 0.12))
		for yy in [-18.0, -2.0, 14.0]:
			DrawBatch.rect(self, Rect2(-16, yy, 32, 3), body.darkened(0.35))
		if not used:
			DrawBatch.string(self, ThemeDB.fallback_font, Vector2(-14, 4), "OIL", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(1.0, 0.85, 0.4))
			var pulse := 0.4 + 0.3 * sin(_t * 5.0)
			DrawBatch.arc(self, Vector2.ZERO, 26.0, 0.0, TAU, 20, Color(1.0, 0.75, 0.2, pulse), 1.5)   # מטרה: לירות כאן
		DrawBatch.set_transform_matrix(self, Transform2D.IDENTITY)
		if _stream > 0.0:   # זרם שמן בוער
			var a := clampf(_stream / 0.9, 0.0, 1.0)
			var mouth := c + Vector2.from_angle(rot - PI * 0.5) * 20.0
			DrawBatch.polygon(self, PackedVector2Array([mouth + Vector2(-6, 0), mouth + Vector2(6, 0), Vector2(POUR_W * 0.5, -2), Vector2(-POUR_W * 0.5, -2)]),
				PackedColorArray([Color(1.0, 0.6, 0.15, 0.9 * a), Color(1.0, 0.6, 0.15, 0.9 * a), Color(1.0, 0.35, 0.05, 0.25 * a), Color(1.0, 0.35, 0.05, 0.25 * a)]))
			Kit.soft_glow(self, Vector2(0, -H * 0.5), 90.0, Color(1.0, 0.55, 0.15, 0.35 * a))


# ---- מחסום גרוטאות שהעדר דוחף מאחוריו: רועד -> קורס על הכביש ----
class BreachWall extends Node2D:
	const W := 200.0
	const WARN_T := 1.3
	const DMG := 1
	const DMG_Z := 30
	const BURST := 4              # כמה זומבים פורצים
	const TRIGGER_R := 260.0
	var state := 0                # 0 עומד, 1 רועד, 2 קרס
	var collapses := 0            # לבדיקות
	var hits_p := 0
	var main: Node = null
	var _t := 0.0
	var _tt := 0.0

	func _ready() -> void:
		z_index = -1
		add_to_group("hazards")

	func world_rect() -> Rect2:
		return Rect2(global_position + Vector2(-20, -60), Vector2(W + 40, 60))

	func danger_at(p: Vector2, margin := 0.0) -> bool:
		return state == 1 and world_rect().grow(margin).has_point(p)

	func _physics_process(delta: float) -> void:
		_tt += delta
		match state:
			0:
				if Engine.get_physics_frames() % 6 == 0:
					var pl := get_tree().get_first_node_in_group("player")
					if pl != null and not pl.dead and absf(pl.global_position.x - (global_position.x + W * 0.5)) < TRIGGER_R:
						state = 1
						_t = WARN_T
						Sfx.play("sg_creak", global_position + Vector2(W * 0.5, -60), 3.0, 0.1, 2)
						Sfx.play("groan", global_position + Vector2(W * 0.5, -60), 4.0, 0.1, 3)
			1:
				_t -= delta
				if Engine.get_physics_frames() % 5 == 0:
					preload("res://particles.gd").burst(get_parent(), global_position + Vector2(randf_range(0, W), -randf_range(20, 120)), "smoke", Vector2.UP, 1)
				if _t <= 0.0:
					_collapse()
		if state == 1 or Engine.get_physics_frames() % 8 == 0:
			if Art.on_screen(self, global_position + Vector2(W * 0.5, -80), W):
				queue_redraw()

	func _collapse() -> void:
		state = 2
		collapses += 1
		Sfx.play("sg_crash", global_position + Vector2(W * 0.5, -40), 4.0, 0.08, 2)
		var cam := get_viewport().get_camera_2d()
		if cam != null and cam.has_method("shake"):
			cam.shake(9.0, 0.4)
		var D := preload("res://debris.gd")
		for i in 10:
			var c = D.new()
			get_parent().add_child(c)
			c.setup(global_position + Vector2(randf_range(0, W), -randf_range(30, 140)), Vector2(randf_range(8, 22), randf_range(5, 12)),
				[RUST, SAND_D, Color("4a4a50"), Color("6a5a40")][i % 4], Vector2(randf_range(-160, 160), -randf_range(60, 260)))
		preload("res://particles.gd").burst(get_parent(), global_position + Vector2(W * 0.5, -30), "smoke", Vector2.UP, 14)
		var r := Rect2(global_position + Vector2(-30, -70), Vector2(W + 60, 72))
		var pl := get_tree().get_first_node_in_group("player")
		if pl != null and not pl.dead and r.intersects(pl.body_rect()):
			hits_p += 1
			pl.hurt(DMG, Vector2(signf(pl.global_position.x - global_position.x - W * 0.5), -0.5))
		for z in get_tree().get_nodes_in_group("zombies"):
			if not z.dead and not z.is_boss() and r.has_point(z.global_position + Vector2(0, -10)):
				z.take_damage(DMG_Z, z.global_position + Vector2(0, -20), Vector2.DOWN, true, {"source": "hazard", "fixed": DMG_Z})
		# העדר פורץ דרך הפרצה
		if main != null:
			var Reg := preload("res://enemies/zombie_registry.gd")
			for i in BURST:
				var kind := 1 if i % 2 == 0 else 0
				if i == BURST - 1:
					kind = Reg.STACKER
				var z = main._spawn_zombie(global_position.x + 30.0 + float(i) * 40.0, global_position.y, kind)
				if z != null:
					z._alert_t = 6.0
					z._rush_t = 2.0
		queue_redraw()

	func _draw() -> void:
		DrawBatch.begin(self)
		_draw_b()
		DrawBatch.end(self)

	func _draw_b() -> void:
		if state == 2:   # פרצה: שני גדמים שבורים בצדדים + ערימת גרוטאות נמוכה
			DrawBatch.colored_polygon(self, PackedVector2Array([Vector2(0, 0), Vector2(0, -132), Vector2(14, -118), Vector2(22, -96), Vector2(30, -60), Vector2(34, 0)]), Color("4a4540"))
			DrawBatch.colored_polygon(self, PackedVector2Array([Vector2(W, 0), Vector2(W, -140), Vector2(W - 12, -110), Vector2(W - 26, -88), Vector2(W - 36, -40), Vector2(W - 40, 0)]), Color("4a4540"))
			DrawBatch.line(self, Vector2(2, -128), Vector2(28, -64), Color(1, 1, 1, 0.1), 2.0)
			DrawBatch.rect(self, Rect2(W - 30, -100, 22, 46), Color("6a6a64"))   # שארית מקרר
			for q in 7:
				var px := 10.0 + float(q) * 28.0
				DrawBatch.colored_polygon(self, PackedVector2Array([Vector2(px, 0), Vector2(px + 8, -14 - float(q % 3) * 6.0), Vector2(px + 26, -10), Vector2(px + 30, 0)]), [RUST, SAND_D, Color("4a4a50")][q % 3])
			return
		var j := Vector2(sin(_tt * 55.0) * 2.0, 0) if state == 1 else Vector2.ZERO
		# גרוטאות: מכונית הפוכה, דלתות, שקי חול, מקרר, קורות
		DrawBatch.rect(self, Rect2(Vector2(0, -150) + j, Vector2(W, 150)), Color("4a4540"))
		DrawBatch.rect(self, Rect2(Vector2(0, -150) + j, Vector2(W, 6)), Color("5e5852"))
		for q in 6:   # כתמי חלודה ופיח
			DrawBatch.colored_polygon(self, Art.ellipse(Vector2(20.0 + float(q) * 32.0, -40.0 - float(q % 3) * 30.0) + j, 12.0, 7.0, 0.3, 8), Color(0.42, 0.24, 0.14, 0.35) if q % 2 == 0 else Color(0.1, 0.09, 0.08, 0.3))
		DrawBatch.colored_polygon(self, PackedVector2Array([Vector2(6, -58) + j, Vector2(110, -64) + j, Vector2(118, -20) + j, Vector2(0, -16) + j]), Color("5a4a6a").darkened(0.3))   # מכונית הפוכה
		DrawBatch.circle(self, Vector2(30, -70) + j, 11.0, Color("161414"))
		DrawBatch.circle(self, Vector2(92, -72) + j, 11.0, Color("161414"))
		DrawBatch.rect(self, Rect2(Vector2(120, -100) + j, Vector2(36, 100)), Color("8a8a84"))   # מקרר
		DrawBatch.rect(self, Rect2(Vector2(124, -60) + j, Vector2(28, 2)), Color("5a5a54"))
		for s in 8:
			DrawBatch.colored_polygon(self, Art.ellipse(Vector2(12.0 + float(s) * 24.0, -8.0) + j, 13.0, 7.0, 0.0, 10), SAND_D)
		DrawBatch.line(self, Vector2(0, -120) + j, Vector2(W, -96) + j, Color("4a3a28"), 8.0)   # קורה
		DrawBatch.rect(self, Rect2(Vector2(40, -140) + j, Vector2(40, 70)), Color("5a4430"))   # דלת
		DrawBatch.rect(self, Rect2(Vector2(160, -150) + j, Vector2(30, 60)), Color("4a3a2a"))
		# ידיים שנדחקות דרך הרווחים
		for q in 5:
			var hx := 20.0 + float(q) * 38.0
			var hy := -110.0 + float(q % 3) * 26.0
			var reach := 8.0 + sin(_tt * (3.0 if state == 0 else 9.0) + float(q)) * 6.0
			DrawBatch.line(self, Vector2(hx, hy) + j, Vector2(hx + reach * 0.5, hy - reach) + j, Color("6a7a6a"), 4.0)
			DrawBatch.circle(self, Vector2(hx + reach * 0.5, hy - reach) + j, 3.0, Color("6a7a6a"))
		if state == 1:
			DrawBatch.string(self, ThemeDB.fallback_font, Vector2(W * 0.5 - 6.0, -170.0), "!", HORIZONTAL_ALIGNMENT_LEFT, -1, 30, Color(1.0, 0.4, 0.2))


# ---- מחסום שקי חול בזירת הבוס: איל הניגוח מנפץ אותו ----
class ArenaBarricade extends Node2D:
	const SIZE := Vector2(72, 66)
	var broken := false
	var _body: StaticBody2D

	func _ready() -> void:
		z_index = 1
		add_to_group("s53_barricades")
		add_to_group("cover")
		var body := StaticBody2D.new()
		body.collision_layer = 1
		body.add_to_group("no_outline")
		var cs := CollisionShape2D.new()
		var sh := RectangleShape2D.new()
		sh.size = SIZE
		cs.shape = sh
		cs.position = Vector2(SIZE.x * 0.5, -SIZE.y * 0.5)
		body.add_child(cs)
		add_child(body)
		_body = body

	func cover_rect() -> Rect2:
		return Rect2(global_position + Vector2(0.0, -SIZE.y), SIZE) if not broken else Rect2()

	func center() -> Vector2:
		return global_position + Vector2(SIZE.x * 0.5, -SIZE.y * 0.5)

	func smash(dir: float) -> void:
		if broken:
			return
		broken = true
		remove_from_group("cover")
		_body.queue_free()
		Sfx.play("sg_crash", center(), 3.0, 0.1, 2)
		var D := preload("res://debris.gd")
		for i in 9:
			var c = D.new()
			get_parent().add_child(c)
			c.setup(center() + Vector2(randf_range(-30, 30), randf_range(-26, 20)), Vector2(randf_range(10, 18), randf_range(6, 9)), SAND if i % 2 == 0 else SAND_D,
				Vector2(dir * randf_range(80, 320), -randf_range(80, 300)))
		preload("res://particles.gd").burst(get_parent(), center(), "smoke", Vector2(dir, -0.5), 10)
		queue_redraw()

	func _draw() -> void:
		DrawBatch.begin(self)
		_draw_b()
		DrawBatch.end(self)

	func _draw_b() -> void:
		if broken:
			for q in 4:
				DrawBatch.colored_polygon(self, Art.ellipse(Vector2(10.0 + float(q) * 17.0, -4.0), 10.0, 4.0, 0.2, 8), SAND_D)
			return
		for r in 4:
			var n := 3 if r % 2 == 0 else 2
			for s in n:
				var sx := (12.0 if r % 2 == 1 else 0.0) + float(s) * 24.0 + 12.0
				var sy := -8.0 - float(r) * 15.5
				DrawBatch.colored_polygon(self, Art.ellipse(Vector2(sx, sy), 13.0, 8.0, 0.0, 12), SAND if (r + s) % 2 == 0 else SAND.darkened(0.1))
				DrawBatch.line(self, Vector2(sx - 9.0, sy - 3.0), Vector2(sx + 9.0, sy - 3.0), Color(1, 1, 1, 0.1), 1.5)
				DrawBatch.line(self, Vector2(sx + 7.0, sy - 4.0), Vector2(sx + 9.0, sy + 4.0), SAND_D.darkened(0.2), 1.2)


# ---- הרמבלה בסוף השלב: מעקה, ים, פנסים, "MONTEVIDEO" ----
class SeaWall extends Node2D:
	var w := 1200.0
	var _t := 0.0

	func _ready() -> void:
		z_index = -2

	func _process(delta: float) -> void:
		_t += delta
		if Engine.get_process_frames() % 3 == 0 and Art.on_screen(self, global_position + Vector2(w * 0.5, -60), w * 0.5 + 200.0):
			queue_redraw()

	func _draw() -> void:
		DrawBatch.begin(self)
		_draw_b()
		DrawBatch.end(self)

	func _draw_b() -> void:
		DrawBatch.rect(self, Rect2(0, -96, w, 60), Color("5e6a70"))   # הים
		for q in 10:
			var wx := fposmod(float(q) * 131.0 + _t * 20.0, w - 60.0)
			DrawBatch.line(self, Vector2(wx, -80.0 + float(q % 4) * 9.0), Vector2(wx + 40.0, -80.0 + float(q % 4) * 9.0), Color(0.88, 0.9, 0.9, 0.35), 1.5)
		var sp := fmod(_t * 0.5, 1.0)   # גלים שמתנפצים על החומה
		if sp < 0.4:
			for q in 6:
				Kit.soft_glow(self, Vector2(80.0 + float(q) * 190.0, -50.0 - sp * 80.0), 26.0 + sp * 30.0, Color(0.92, 0.95, 0.96, 0.4 * (1.0 - sp / 0.4)))
		DrawBatch.rect(self, Rect2(0, -40, w, 40), STONE)   # חומת הים
		for q in int(w / 40.0):   # מעקה עמודונים
			DrawBatch.rect(self, Rect2(float(q) * 40.0 + 6.0, -62.0, 10.0, 22.0), STONE.lightened(0.1))
		DrawBatch.rect(self, Rect2(0, -66, w, 6.0), STONE.lightened(0.15))
		for q in 4:   # פנסים
			var lx := 100.0 + float(q) * 300.0
			DrawBatch.line(self, Vector2(lx, -66.0), Vector2(lx, -170.0), Color("2a2a2e"), 4.0)
			DrawBatch.line(self, Vector2(lx, -170.0), Vector2(lx + 18.0, -176.0), Color("2a2a2e"), 3.0)
			DrawBatch.rect(self, Rect2(lx + 12.0, -180.0, 12.0, 10.0), Color("3a3a3e"))
		# האותיות הגדולות "MONTEVIDEO" (כמו ברמבלה)
		var letters := "MONTEVIDEO"
		var cols := [Color("d84a3a"), Color("e8b030"), Color("3a8ad8"), Color("4ab060"), Color("e87a30")]
		for i in letters.length():
			var lx2 := w * 0.3 + float(i) * 38.0
			DrawBatch.string(self, ThemeDB.fallback_font, Vector2(lx2, -70.0), letters[i], HORIZONTAL_ALIGNMENT_LEFT, -1, 46, cols[i % cols.size()].darkened(0.15))


# ---- מכשולים: שקי חול / קרון חשמלית / דוכני שוק ----
class Obstacle extends Node2D:
	var kind := "sandbags"
	var size := Vector2(80, 46)
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
		match kind:
			"sandbags":
				var rows := 3
				for r in rows:
					var n := int(w / 22.0) - (r % 2)
					for s in n:
						var sx := (11.0 if r % 2 == 1 else 0.0) + float(s) * 22.0 + 11.0
						var sy := -7.0 - float(r) * (h / float(rows))
						var c := SAND if (r + s + seed_v) % 3 != 0 else SAND.darkened(0.12)
						DrawBatch.colored_polygon(self, Art.ellipse(Vector2(sx, sy), 12.5, 8.0, 0.0, 12), c)
						DrawBatch.line(self, Vector2(sx - 8.0, sy - 3.0), Vector2(sx + 8.0, sy - 3.0), Color(1, 1, 1, 0.1), 1.5)
						DrawBatch.line(self, Vector2(sx + 7.0, sy - 4.0), Vector2(sx + 9.0, sy + 4.0), SAND_D.darkened(0.2), 1.2)
			"tram":   # קרון חשמלית ישן (ירוק-קרם), הפוך על הצד חלקית
				var body_c := Color("4a6a4a")
				DrawBatch.rect(self, Rect2(4, -h, w - 8.0, h - 14.0), body_c)
				DrawBatch.rect(self, Rect2(4, -h, w - 8.0, 10.0), Color("d8ccaa"))
				DrawBatch.rect(self, Rect2(4, -h * 0.45, w - 8.0, 5.0), Color("d8ccaa"))
				for q in int((w - 20.0) / 26.0):
					DrawBatch.rect(self, Rect2(12.0 + float(q) * 26.0, -h + 14.0, 18.0, 20.0), Color("1a1e1e"))
				DrawBatch.rect(self, Rect2(0, -16.0, w, 8.0), Color("2a2a2a"))
				for wx in [20.0, w - 30.0]:
					DrawBatch.circle(self, Vector2(wx, -8.0), 8.0, Color("1a1a1a"))
				DrawBatch.line(self, Vector2(w * 0.5, -h), Vector2(w * 0.5 + 20.0, -h - 26.0), Color("2a2a2a"), 2.0)   # זרוע החשמל
				DrawBatch.string(self, ThemeDB.fallback_font, Vector2(w * 0.3, -h * 0.55), "UTE", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("d8ccaa"))
				Kit.soft_glow(self, Vector2(w * 0.6, -h * 0.7), 30.0, Color(0.05, 0.05, 0.05, 0.4))
			_:   # דוכני שוק הפוכים עם סוכך מפוספס
				var wood := Color("6a5236")
				DrawBatch.rect(self, Rect2(4, -h * 0.55, w - 8.0, h * 0.55), wood)
				DrawBatch.rect(self, Rect2(4, -h * 0.55, w - 8.0, 4.0), wood.lightened(0.2))
				for q in 4:   # ארגזי פירות שנשפכו
					DrawBatch.rect(self, Rect2(8.0 + float(q) * (w - 16.0) / 4.0, -h * 0.55 - 12.0, 16.0, 12.0), Color("8a6a3a"))
					DrawBatch.circle(self, Vector2(14.0 + float(q) * (w - 16.0) / 4.0, -h * 0.55 - 14.0), 3.5, [Color("d84a2a"), Color("e8a030"), Color("6aa040")][q % 3])
				DrawBatch.line(self, Vector2(6, -h * 0.55), Vector2(6, -h), Color("3a3020"), 3.0)
				DrawBatch.line(self, Vector2(w - 6.0, -h * 0.55), Vector2(w - 6.0, -h + 6.0), Color("3a3020"), 3.0)
				for q in 6:   # סוכך מפוספס, נוטה
					var c := Color("c83a2a") if q % 2 == 0 else Color("e8e0d0")
					var x0 := float(q) * w / 6.0
					DrawBatch.colored_polygon(self, PackedVector2Array([Vector2(x0, -h + float(q) * 1.0), Vector2(x0 + w / 6.0, -h + float(q + 1) * 1.0), Vector2(x0 + w / 6.0, -h + 10.0 + float(q + 1)), Vector2(x0, -h + 10.0 + float(q))]), c.darkened(0.15))


# ---- ערפל קר נמוך + הבזקי ארטילריה רחוקים (מסך) ----
class SiegeFX extends Node2D:
	var vp := Vector2(1280, 720)
	var flashes := 0               # לבדיקות
	var _t := 0.0
	var _next := 6.0
	var _flash := 0.0
	var _fx := 0.0

	func _process(delta: float) -> void:
		_t += delta
		_next -= delta
		_flash = maxf(_flash - delta * 2.5, 0.0)
		if _next <= 0.0:
			_next = randf_range(7.0, 14.0)
			_flash = 1.0
			_fx = randf_range(0.1, 0.9)
			flashes += 1
		if Engine.get_process_frames() % 2 == 0 or _flash > 0.0:
			queue_redraw()

	func _draw() -> void:
		DrawBatch.begin(self)
		_draw_b()
		DrawBatch.end(self)

	func _draw_b() -> void:
		var n := 3 if Quality.level < 2 else 1
		for i in n:   # ערפל קר נמוך שזז
			var x := fposmod(float(i) * 520.0 + _t * (14.0 + float(i) * 6.0), vp.x + 900.0) - 450.0
			Kit.soft_ellipse(self, Vector2(x, vp.y * 0.88 - float(i) * 24.0), 420.0, 40.0, 0.0, Color(0.82, 0.86, 0.9, 0.12))
		if _flash > 0.0:   # הבזק ארטילריה מעבר לאופק
			Kit.soft_glow(self, Vector2(vp.x * _fx, vp.y * 0.55), 260.0, Color(1.0, 0.8, 0.55, 0.12 * _flash), 0.5)
