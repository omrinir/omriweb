extends RefCounted
# ============================================================
#  קישוטים לשלב 56 ("ICE FJORD") - פיורד קפוא בפטגוניה: קירות קרחון כחולים שמתנתקים (calving), גושי קרח
#  על מים שחורים, סירות דייגים שקפאו בתוך הקרח, מפעל שימורי דגים על כלונסאות. אזור שביעי, שלב 2.
#  "THEY LEARNED THE COLD" - הקור שומר עליהם מריקבון, והקרח שובר כדורים לאט יותר מגולגולת.
#    fjord_sky     - (רקע) דמדומי קוטב בהירים: שמש נמוכה עם הילה, וילונות זוהר צפוני (ירוק / טורקיז / סגול) שמתנופפים
#    far_peaks     - (רקע, 0.06) צריחי גרניט מושלגים (בהשראת פיץ רוי), לשון קרחון, דגלי שלג שנושבים מהפסגות, עננים
#    mid_fjord     - (רקע, 0.28) מי הפיורד, חזית הקרחון הכחולה עם סדקים - שמתנתקת מדי פעם (CALVE_EVERY / calve_ms)
#                    ונופלת למים בפיצוץ מים, קרחונים צפים שנעים לאט, ספינת מכמורת תקועה, ציפורי ים
#    near_floes    - (רקע, 0.6) גושי קרח שמתנדנדים על מים שחורים, רכסי לחץ, עמודי מזח קפואים, שלג נושב
#    fjord_overlay - אובך קר מאחורי הדמויות (קריאות)
#    IceGround     - (עולם) קרח ים מושלג (סדקים, בועות קפואות) או רציף עץ עם כפור ("dock")
#    WaterLead     - (עולם) פס מים פתוחים בין גושי קרח: הולכים בתוכו לאט (player.in_water), וקפואים: FREEZE_T -> נזק
#    FishingHole   - (עולם, group "ice_holes") חור דיג בקרח עם דגל "tip-up" - הדגל קופץ כשמשהו שוחה מתחת (SEALER!)
#    ThinIce       - (עולם, מלכודת, group "ice_holes" כשהוא שבור) קרח דק: עומדים עליו -> נסדק (CRACK_T) -> נשבר:
#                    DMG + slow, זומבים עליו DMG_Z. נשאר חור מים (SEALER יכול לצאת ממנו!) ואז קופא שוב (REFREEZE)
#    Calving       - (עולם, מלכודת) מדף קרח תלוי מקיר הקרחון: מתקרבים -> סדקים + חריקה + צל על הרצפה (WARN_T) ->
#                    גושי קרח נופלים (DMG / DMG_Z). לירות בסדק הכחול = נופל מיד (על הזומבים שמתחת). חוזר אחרי REGROW_T.
#    HookLine      - (עולם, מלכודת) מסילת וו דגים של המפעל: נכנסים לקטע -> פעמון + נורה (WARN_T) -> העגלה רצה עם וו
#                    בגובה החזה (להתכופף / לקפוץ / להתגלגל). וו שתופס זומבים - גורר וזורק אותם. לירות בקופסת המנוע = מפעיל.
#    FuelDrum      - (עולם, מלכודת) חבית דלק קפואה: יריות שוברות את הכפור (HP), ואז היא מתיזה ומתפוצצת (FUSE) -
#                    הפיצוץ ממיס קרח של THAWED ושובר קרח דק קרוב.
#    Cannery       - (עולם) מפעל שימורים על כלונסאות: מסלול הליכה (קומה) + גג (קומה שנייה), שלט, מסוע
#    FrozenBoat    - (עולם) סירת דייגים תקועה בקרח: סיפון (קומה), גג תא ההגה (קומה), תורן, נטיפים
#    IceLedge      - (עולם) מדף קרח בקיר הקרחון (קומה) עם סולם חבל
#    GlacierArena  - (עולם) חזית הקרחון בסוף השלב - הזירה של THE GLACIER, עם מדף מסתור (קומה)
#    Obstacle      - (מוצק + מחסה) "ice_block" גוש קרח עם דג קפוא / "fish_box" ארגזי דגים / "net_pile" רשתות ומצופים
#    FjordFX       - (מסך) שלג נושב, דגלי שלג, גוון קר (לפי Quality.ambient())
#    IceArt        - צייר קירות קרחון משותף (Calving.Wall, IceLedge, GlacierArena): גוון, שכבות שנתיות, נקיקים, שלג ונטיפים
#  לשנות: CALVE_EVERY, WaterLead.FREEZE_T, ThinIce.CRACK_T / DMG / DMG_Z / REFREEZE, Calving.WARN_T / DMG / DMG_Z / REGROW_T,
#         HookLine.WARN_T / SPEED / DMG / DMG_Z / CD, FuelDrum.HP / FUSE / BLAST_R / BLAST_DMG.
# ============================================================

const Art := preload("res://art.gd")
const Sfx := preload("res://sfx.gd")
const Kit := preload("res://effects/backdrop_kit.gd")
const Particles := preload("res://particles.gd")
const Boom := preload("res://explosion.gd")

const CALVE_EVERY := 38.0         # כל כמה זמן חזית הקרחון ברקע מתנתקת
const ICE_HI := Color("eaf7ff")
const ICE := Color("a9d6ee")
const ICE_D := Color("5d9fc6")
const ICE_DEEP := Color("2b6694")
const SNOW := Color("f3f7fb")
const SNOW_S := Color("c9d9e8")   # צל של שלג
const WATER := Color("0f1c29")
const WATER_HI := Color("436a86")
const WOOD := Color("5e4a3a")
const WOOD_D := Color("3a2e26")
const RUST := Color("8a4a32")
const STEEL := Color("6a7682")
const STEEL_D := Color("3a424c")

static var calve_ms := -1         # on_story_beat("calve"): הקרחון ברקע מתנתק עכשיו


static func _h(i: int, s: int) -> float:
	return fposmod(sin(float(i) * 12.9898 + float(s) * 78.233) * 43758.5453, 1.0)


# ============================================================
#  רקע
# ============================================================
static func fjord_sky(ci: CanvasItem, v: Vector2, t: float) -> void:
	Kit.gradient_sky(ci, v, [Color("1d3a68"), Color("2e5688"), Color("4f7fac"), Color("88aacb"), Color("c9c0d2"), Color("f2cfb2")], 0.86)
	# כוכבים חלשים למעלה
	for i in 30:
		var sp := Vector2(_h(i, 1) * v.x, _h(i, 2) * v.y * 0.28)
		var tw := 0.5 + 0.5 * sin(t * 1.7 + float(i) * 2.3)
		ci.draw_rect(Rect2(sp, Vector2(1.6, 1.6)), Color(0.9, 0.95, 1.0, 0.5 * tw))
	# זוהר צפוני: 3 וילונות שמתנופפים (גלי סינוס), קצוות רכים
	var cols := [Color(0.35, 1.0, 0.65), Color(0.3, 0.9, 1.0), Color(0.75, 0.5, 1.0)]
	for c in 3:
		var base_y := v.y * (0.1 + float(c) * 0.06)
		var amp := 26.0 + float(c) * 8.0
		var n := 26
		for q in n:
			var u := float(q) / float(n - 1)
			var x := lerpf(-60.0, v.x + 60.0, u) + sin(t * 0.07 + float(c)) * 80.0
			var y := base_y + sin(u * 7.0 + t * (0.35 + float(c) * 0.1) + float(c) * 2.0) * amp
			var hgt := 70.0 + 50.0 * (0.5 + 0.5 * sin(u * 11.0 - t * 0.6 + float(c)))
			var a := (0.12 + 0.08 * sin(u * 5.0 + t * 0.9 + float(c) * 1.3)) * (1.0 - absf(u - 0.5) * 0.8)
			Kit.soft_ellipse(ci, Vector2(x, y + hgt * 0.35), 34.0, hgt * 0.6, 0.0, Color(cols[c], a))
	# שמש נמוכה עם הילה (מאירה את כל השלב)
	var sun := Vector2(v.x * 0.78, v.y * 0.6)
	Kit.soft_glow(ci, sun, 360.0, Color(1.0, 0.82, 0.62, 0.3))
	Kit.soft_glow(ci, sun, 120.0, Color(1.0, 0.9, 0.75, 0.55))
	ci.draw_circle(sun, 26.0, Color(1.0, 0.95, 0.85))
	# עננים נמוכים שנעים
	Kit.clouds(ci, t * 4.0, v, t, v.y * 0.42, Color(0.92, 0.88, 0.94, 0.35), 561, 5.0)
	Kit.birds(ci, v, t, 56, Color(0.12, 0.16, 0.22, 0.75), 5)


# ---- צריחי הגרניט + לשון הקרחון ----
static func far_peaks(ci: CanvasItem, sc: float, v: Vector2, y: float, t: float) -> void:
	var period := 1600.0
	var start := int(floor(sc / period)) - 1
	for kk in range(start, start + int(ceil(v.x / period)) + 2):
		var bx := float(kk) * period - sc
		# רכס רחוק בהיר
		var far := PackedVector2Array([Vector2(bx - 40, y)])
		for q in 9:
			far.append(Vector2(bx + float(q) * 205.0, y - 150.0 - _h(kk * 9 + q, 3) * 110.0))
		far.append(Vector2(bx + 1700.0, y))
		ci.draw_colored_polygon(far, Color("8aa4c4"))
		# הצריחים: מחודדים וכהים עם שלג בסדקים
		var spires := [[260.0, 300.0, 70.0], [380.0, 250.0, 50.0], [470.0, 210.0, 40.0], [980.0, 270.0, 60.0], [1090.0, 220.0, 44.0]]
		for s in spires:
			var sx: float = bx + float(s[0])
			var sh: float = s[1]
			var sw: float = s[2]
			var pk := PackedVector2Array([Vector2(sx - sw, y), Vector2(sx - sw * 0.35, y - sh * 0.7), Vector2(sx - sw * 0.1, y - sh), Vector2(sx + sw * 0.2, y - sh * 0.88), Vector2(sx + sw * 0.45, y - sh * 0.55), Vector2(sx + sw, y)])
			ci.draw_colored_polygon(pk, Color("4a5e7c"))
			ci.draw_colored_polygon(PackedVector2Array([Vector2(sx - sw * 0.1, y - sh), Vector2(sx + sw * 0.2, y - sh * 0.88), Vector2(sx + sw * 0.45, y - sh * 0.55), Vector2(sx + sw * 0.1, y - sh * 0.62)]), Color("6a80a0"))   # צד מואר
			ci.draw_colored_polygon(PackedVector2Array([Vector2(sx - sw * 0.35, y - sh * 0.7), Vector2(sx - sw * 0.1, y - sh), Vector2(sx - sw * 0.05, y - sh * 0.78), Vector2(sx - sw * 0.25, y - sh * 0.6)]), Color(0.95, 0.97, 1.0, 0.85))
			for q in 3:   # רצועות שלג
				var yy := y - sh * (0.25 + float(q) * 0.15)
				ci.draw_line(Vector2(sx - sw * (0.6 - float(q) * 0.12), yy), Vector2(sx + sw * (0.3 - float(q) * 0.05), yy - 8.0), Color(0.93, 0.96, 1.0, 0.6), 3.0)
			# דגל שלג שנושב מהפסגה
			for q in 3:
				var k := fmod(t * 0.25 + float(q) / 3.0 + _h(kk, int(sx)), 1.0)
				Kit.soft_ellipse(ci, Vector2(sx + 20.0 + k * 140.0, y - sh - 6.0 + k * 22.0), 30.0 + k * 50.0, 10.0 + k * 10.0, 0.15, Color(1.0, 1.0, 1.0, 0.32 * (1.0 - k)))
		# לשון הקרחון שיורדת בין ההרים
		var gx := bx + 640.0
		ci.draw_colored_polygon(PackedVector2Array([Vector2(gx, y), Vector2(gx + 60, y - 120), Vector2(gx + 170, y - 190), Vector2(gx + 250, y - 120), Vector2(gx + 330, y)]), Color("c8e2f2"))
		for q in 5:
			ci.draw_line(Vector2(gx + 40.0 + float(q) * 55.0, y), Vector2(gx + 120.0 + float(q) * 20.0, y - 150.0), Color(0.55, 0.75, 0.9, 0.5), 1.5)
	ci.draw_rect(Rect2(0, y - 2.0, v.x, v.y - y + 2.0), Color("6d88a8"))


# ---- הפיורד: מים, חזית הקרחון שמתנתקת, קרחונים צפים, ספינת מכמורת ----
static func mid_fjord(ci: CanvasItem, sc: float, v: Vector2, y: float, t: float) -> void:
	var wy := y - 50.0
	ci.draw_rect(Rect2(0, wy, v.x, v.y - wy), Color("2c4a66"))
	# ניצוצות על המים
	for i in 24:
		var x := fposmod(_h(i, 7) * v.x * 1.3 - sc * 0.2 + sin(t * 0.5 + float(i)) * 8.0, v.x)
		var yy := wy + 4.0 + _h(i, 8) * 40.0
		ci.draw_rect(Rect2(x, yy, 10.0 + _h(i, 9) * 18.0, 1.4), Color(0.85, 0.92, 1.0, 0.25 + 0.2 * sin(t * 2.0 + float(i))))
	var period := 2100.0
	var start := int(floor(sc / period)) - 1
	var cyc := fmod(t + 10.0, CALVE_EVERY) / CALVE_EVERY
	var forced := calve_ms > 0 and Time.get_ticks_msec() - calve_ms < 4500
	var ck := (float(Time.get_ticks_msec() - calve_ms) / 4500.0) if forced else clampf((cyc - 0.85) / 0.15, -1.0, 1.0)
	for kk in range(start, start + int(ceil(v.x / period)) + 2):
		var bx := float(kk) * period - sc
		# חזית הקרחון: קיר כחול-לבן משונן
		var gx := bx + 200.0
		var gw := 760.0
		var top := PackedVector2Array([Vector2(gx, wy)])
		for q in 13:
			top.append(Vector2(gx + float(q) * gw / 12.0, wy - 110.0 - _h(kk * 13 + q, 4) * 40.0))
		top.append(Vector2(gx + gw, wy))
		ci.draw_colored_polygon(top, Color("8fc4e2"))
		for q in 12:   # סדקים כחולים עמוקים
			var cx := gx + 30.0 + float(q) * gw / 12.0
			ci.draw_line(Vector2(cx, wy - 100.0 + _h(q, kk) * 20.0), Vector2(cx + 6.0, wy - 4.0), Color("3f84b4"), 3.0)
			ci.draw_line(Vector2(cx + 8.0, wy - 90.0), Vector2(cx + 10.0, wy - 30.0), Color(0.9, 0.97, 1.0, 0.5), 1.4)
		ci.draw_rect(Rect2(gx, wy - 16.0, gw, 16.0), Color(0.25, 0.5, 0.72, 0.5))   # פס כהה בקו המים
		# ההתנתקות: גוש גדול נופל למים + פיצוץ מים
		var lead := kk % 2 == 0
		if lead and ck > 0.0:
			var chx := gx + gw * 0.55
			var fall := clampf(ck * 2.2, 0.0, 1.0)
			var tilt := fall * 0.6
			var cy := wy - 120.0 + fall * fall * 110.0
			var blk := PackedVector2Array([Vector2(-40, -60), Vector2(36, -64), Vector2(42, 10), Vector2(-46, 14)])
			var xf := Transform2D(tilt, Vector2(chx, cy))
			ci.draw_colored_polygon(xf * blk, Color("b6dcf0"))
			ci.draw_line(xf * Vector2(-40, -60), xf * Vector2(36, -64), Color(1, 1, 1, 0.7), 2.0)
			if fall >= 1.0:   # פיצוץ מים
				var sk := clampf((ck - 0.45) / 0.55, 0.0, 1.0)
				for q in 7:
					var a := -PI / 2.0 + (float(q) - 3.0) * 0.28
					var r := 30.0 + sk * 130.0
					Kit.soft_ellipse(ci, Vector2(chx, wy) + Vector2.from_angle(a) * r * Vector2(1.0, 1.1), 22.0 + sk * 20.0, 14.0 + sk * 10.0, a, Color(0.95, 0.98, 1.0, 0.6 * (1.0 - sk)))
				Kit.soft_ellipse(ci, Vector2(chx, wy - 4.0), 140.0 * (0.4 + sk), 10.0, 0.0, Color(0.9, 0.96, 1.0, 0.5 * (1.0 - sk)))
		# ספינת מכמורת תקועה (צללית)
		if kk % 3 == 1:
			var sx := bx + 1200.0
			ci.draw_colored_polygon(PackedVector2Array([Vector2(sx, wy - 6), Vector2(sx + 170, wy - 10), Vector2(sx + 150, wy + 8), Vector2(sx + 14, wy + 8)]), Color("3a3a48"))
			ci.draw_rect(Rect2(sx + 100.0, wy - 40.0, 40.0, 30.0), Color("4a4a58"))
			ci.draw_line(Vector2(sx + 70.0, wy - 8.0), Vector2(sx + 70.0, wy - 74.0), Color("3a3a48"), 3.0)
			ci.draw_line(Vector2(sx + 70.0, wy - 74.0), Vector2(sx + 10.0, wy - 10.0), Color("3a3a48"), 1.0)
			ci.draw_line(Vector2(sx + 70.0, wy - 74.0), Vector2(sx + 160.0, wy - 12.0), Color("3a3a48"), 1.0)
			if fmod(t + float(kk), 3.0) < 1.5:
				Kit.soft_glow(ci, Vector2(sx + 70.0, wy - 76.0), 10.0, Color(1.0, 0.3, 0.2, 0.7))
	# קרחונים צפים שנעים לאט עם הזרם
	for i in 6:
		var ix := fposmod(_h(i, 11) * 3000.0 - sc * 1.0 + t * (6.0 + float(i) * 1.5), v.x + 400.0) - 200.0
		var iw := 50.0 + _h(i, 12) * 70.0
		var ih := 14.0 + _h(i, 13) * 26.0
		var bob := sin(t * 0.8 + float(i)) * 1.5
		var iy := wy + 10.0 + _h(i, 14) * 30.0 + bob
		ci.draw_colored_polygon(PackedVector2Array([Vector2(ix, iy), Vector2(ix + iw * 0.2, iy - ih), Vector2(ix + iw * 0.6, iy - ih * 1.2), Vector2(ix + iw, iy)]), Color("dff0fa"))
		ci.draw_colored_polygon(PackedVector2Array([Vector2(ix + iw * 0.6, iy - ih * 1.2), Vector2(ix + iw, iy), Vector2(ix + iw * 0.6, iy)]), Color("9ccbe6"))
		ci.draw_rect(Rect2(ix + 2.0, iy, iw - 4.0, 3.0), Color(0.6, 0.8, 0.95, 0.4))
	Kit.birds(ci, v, t * 0.8, 57, Color(0.92, 0.94, 0.98, 0.85), 4)   # ציפורי ים לבנות
	ci.draw_rect(Rect2(0, y - 8.0, v.x, v.y - y + 8.0), Color("27435c"))


# ---- קרוב: גושי קרח על מים שחורים ----
static func near_floes(ci: CanvasItem, sc: float, v: Vector2, y: float, t: float) -> void:
	ci.draw_rect(Rect2(0, y - 30.0, v.x, v.y - y + 30.0), Color("13222f"))
	var period := 300.0
	var start := int(floor(sc / period)) - 1
	for kk in range(start, start + int(ceil(v.x / period)) + 2):
		var x := float(kk) * period - sc
		var bob := sin(t * 1.1 + float(kk) * 1.7) * 2.0
		var fw := 140.0 + _h(kk, 1) * 120.0
		var fy := y - 18.0 + bob
		# גוש קרח צף: עליון לבן, צד טורקיז, השתקפות
		ci.draw_colored_polygon(PackedVector2Array([Vector2(x, fy), Vector2(x + 10, fy - 10), Vector2(x + fw - 12, fy - 12), Vector2(x + fw, fy)]), SNOW)
		ci.draw_rect(Rect2(x, fy, fw, 7.0), Color("7fb8d6"))
		ci.draw_rect(Rect2(x + 6.0, fy + 9.0, fw - 12.0, 2.0), Color(0.6, 0.85, 1.0, 0.25 + 0.15 * sin(t * 2.0 + float(kk))))
		# רכס לחץ: גושים שבורים שבולטים
		if _h(kk, 2) < 0.5:
			var rx := x + fw * 0.4
			for q in 3:
				var px := rx + float(q) * 16.0
				var ph := 14.0 + _h(kk * 3 + q, 3) * 18.0
				ci.draw_colored_polygon(PackedVector2Array([Vector2(px - 10, fy - 8), Vector2(px - 3, fy - 8 - ph), Vector2(px + 9, fy - 6 - ph * 0.7), Vector2(px + 12, fy - 8)]), Color("cfe8f6"))
				ci.draw_line(Vector2(px - 3, fy - 8 - ph), Vector2(px + 9, fy - 6 - ph * 0.7), Color(1, 1, 1, 0.8), 1.5)
		# עמוד מזח קפוא עם נטיפים
		if _h(kk, 4) < 0.35:
			var px2 := x + fw + 40.0
			ci.draw_rect(Rect2(px2 - 6.0, y - 70.0, 12.0, 60.0), WOOD_D)
			ci.draw_rect(Rect2(px2 - 8.0, y - 74.0, 16.0, 6.0), SNOW)
			for q in 3:
				ci.draw_colored_polygon(PackedVector2Array([Vector2(px2 - 6 + q * 5, y - 68), Vector2(px2 - 3 + q * 5, y - 68), Vector2(px2 - 4.5 + q * 5, y - 56 + q * 3)]), Color("d8eef8"))
		# שלג נושב מעל הגוש
		var k := fmod(t * 0.5 + _h(kk, 5), 1.0)
		Kit.soft_ellipse(ci, Vector2(x + fw * k, fy - 6.0 - k * 6.0), 40.0, 5.0, 0.0, Color(1, 1, 1, 0.22 * sin(k * PI)))
	# אדי ים (sea smoke) מעל המים השחורים
	for q in 5:
		var mx := fposmod(float(q) * 290.0 - t * 12.0 - sc * 0.1, v.x + 300.0) - 150.0
		Kit.soft_ellipse(ci, Vector2(mx, y - 16.0), 120.0, 12.0, 0.0, Color(0.85, 0.92, 1.0, 0.14))


static func fjord_overlay(ci: CanvasItem, v: Vector2, _t: float) -> void:
	Kit.haze_band(ci, v, 420.0, 612.0, Color(0.78, 0.88, 0.98, 0.24))


# ============================================================
#  עולם: הקרקע
# ============================================================
class IceGround extends Node2D:
	var w := 1024.0
	var depth := 90.0
	var seed_v := 0
	var dock := false

	func _ready() -> void:
		z_index = 1

	func _draw() -> void:
		var r := RandomNumberGenerator.new()
		r.seed = seed_v
		if dock:   # רציף עץ עם כפור, כלונסאות מתחת
			draw_rect(Rect2(0, 0, w, depth), Color("1d2a36"))
			draw_rect(Rect2(0, 0, w, 14.0), WOOD)
			for i in int(w / 26.0):
				var px := float(i) * 26.0
				draw_line(Vector2(px, 0), Vector2(px, 14.0), WOOD_D, 1.4)
				draw_rect(Rect2(px + 3.0, 0.0, 20.0, 2.0), Color(0.85, 0.9, 0.95, 0.55))   # כפור על הקרשים
				if r.randf() < 0.3:
					draw_circle(Vector2(px + 6.0, 7.0), 0.9, Color("2a2420"))
			for i in int(w / 120.0) + 1:   # כלונסאות במים
				var sx := float(i) * 120.0 + 30.0
				draw_rect(Rect2(sx, 14.0, 12.0, depth - 14.0), Color("2a2420"))
				draw_rect(Rect2(sx - 2.0, 30.0, 16.0, 5.0), Color(0.85, 0.92, 1.0, 0.5))
			draw_rect(Rect2(0, 14.0, w, 4.0), Color(0, 0, 0, 0.35))
			# שלג ליד הקצוות
			for i in int(w / 90.0):
				draw_colored_polygon(Art.ellipse(Vector2(r.randf_range(0, w), 1.0), r.randf_range(14, 30), 3.0, 0.0, 10), SNOW)
			return
		# קרח ים: שכבת שלג, קרח טורקיז מתחת עם בועות קפואות וסדקים
		draw_rect(Rect2(0, 0, w, depth), Color("3e7ca6"))
		draw_rect(Rect2(0, 10.0, w, depth - 10.0), Color("2f6790"))
		draw_rect(Rect2(0, 0, w, 12.0), SNOW)
		draw_rect(Rect2(0, 10.0, w, 3.0), SNOW_S)
		for i in int(w / 70.0):   # גלי שלג על המשטח
			draw_colored_polygon(Art.ellipse(Vector2(r.randf_range(0, w), 1.0), r.randf_range(18, 40), 3.5, 0.0, 10), Color("ffffff"))
		for i in int(w / 18.0):   # בועות קפואות
			draw_circle(Vector2(r.randf_range(0, w), r.randf_range(20, depth - 8)), r.randf_range(1.0, 2.6), Color(0.85, 0.95, 1.0, 0.45))
		for i in int(w / 110.0):   # סדקים לבנים בתוך הקרח
			var cx := r.randf_range(0, w)
			var cy := r.randf_range(18, depth - 20)
			var pts := PackedVector2Array([Vector2(cx, cy)])
			for q in 4:
				pts.append(pts[q] + Vector2(r.randf_range(6, 18), r.randf_range(-8, 8)))
			draw_polyline(pts, Color(0.9, 0.97, 1.0, 0.55), 1.2)
		for i in int(w / 200.0):   # טביעות רגליים בשלג
			var fx := r.randf_range(0, w)
			for q in 4:
				draw_rect(Rect2(fx + float(q) * 9.0, 3.0 + float(q % 2) * 3.0, 4.0, 2.0), SNOW_S)



# ---- צייר קיר קרחון משותף: גוון, שכבות שנתיות מלוכלכות, נקיקים כחולים עמוקים, שלג וקרח על השפה ----
class IceArt:
	static func hh(i: int, s: int) -> float:
		return fposmod(sin(float(i) * 12.9898 + float(s) * 78.233) * 43758.5453, 1.0)

	static func _clip(ci: CanvasItem, face: PackedVector2Array, poly: PackedVector2Array, c: Color) -> void:
		for part in Geometry2D.intersect_polygons(face, poly):
			if part.size() >= 3:
				ci.draw_colored_polygon(part, c)

	# face: מצולע הקיר (נקודה ראשונה ואחרונה על הרצפה, y=0). top: הגובה המקסימלי (שלילי)
	static func cliff(ci: CanvasItem, face: PackedVector2Array, x0: float, x1: float, top: float, seed_v: int, base := Color("7db7da")) -> void:
		ci.draw_colored_polygon(face, base)
		var w := x1 - x0
		# גוון: למעלה בהיר, למטה כהה
		_clip(ci, face, PackedVector2Array([Vector2(x0 - 60, top - 120), Vector2(x1 + 60, top - 120), Vector2(x1 + 60, top * 0.55), Vector2(x0 - 60, top * 0.55)]), Color(0.92, 0.98, 1.0, 0.22))
		_clip(ci, face, PackedVector2Array([Vector2(x0 - 60, top * 0.35), Vector2(x1 + 60, top * 0.35), Vector2(x1 + 60, 2), Vector2(x0 - 60, 2)]), Color(0.1, 0.3, 0.55, 0.16))
		_clip(ci, face, PackedVector2Array([Vector2(x0 - 60, -40), Vector2(x1 + 60, -40), Vector2(x1 + 60, 2), Vector2(x0 - 60, 2)]), Color(0.05, 0.2, 0.4, 0.16))
		# שכבות שנתיות (פסים גליים, חלקם אפורים מאבק הרי געש)
		for b in 4:
			var by := top * (0.25 + 0.17 * float(b)) + hh(b, seed_v) * 14.0
			var band := PackedVector2Array()
			var n := 10
			for q in n + 1:
				var x := x0 - 60.0 + (w + 120.0) * float(q) / float(n)
				band.append(Vector2(x, by + sin(x * 0.012 + float(b)) * 8.0))
			for q in n + 1:
				var x2 := x0 - 60.0 + (w + 120.0) * float(n - q) / float(n)
				band.append(Vector2(x2, by + 4.0 + hh(b, 7) * 5.0 + sin(x2 * 0.012 + float(b)) * 8.0))
			var bc := Color(0.35, 0.45, 0.55, 0.22) if b % 2 == 0 else Color(0.2, 0.45, 0.7, 0.22)
			_clip(ci, face, band, bc)
		# נקיקים: טריזים כחולים כהים עם קו אור לידם
		var nc := int(w / 70.0) + 1
		for q in nc:
			var cx := x0 + (float(q) + 0.3 + hh(q, seed_v + 3) * 0.4) * w / float(nc)
			var ct := top * (0.92 - hh(q, seed_v + 5) * 0.25)
			var cb := top * (0.05 + hh(q, seed_v + 9) * 0.35)
			var cw := 5.0 + hh(q, seed_v + 11) * 7.0
			_clip(ci, face, PackedVector2Array([Vector2(cx - cw, ct), Vector2(cx + cw * 0.4, ct + 6.0), Vector2(cx + 2.0, cb), Vector2(cx - 1.0, cb + 8.0)]), Color("2f6e9c"))
			_clip(ci, face, PackedVector2Array([Vector2(cx - cw * 0.5, ct + 10.0), Vector2(cx, ct + 14.0), Vector2(cx + 1.0, cb + 4.0)]), Color("1d4a72"))
			ci.draw_line(Vector2(cx + cw * 0.6, ct + 8.0), Vector2(cx + 4.0, cb + 6.0), Color(1, 1, 1, 0.4), 1.4)
		# שפה עליונה: שלג + נטיפים
		var edge := PackedVector2Array()
		for i in range(1, face.size() - 1):
			edge.append(face[i])
		if edge.size() >= 2:
			ci.draw_polyline(edge, Color("f4fbff"), 7.0)
			ci.draw_polyline(edge, Color(0.8, 0.9, 1.0, 0.8), 2.0)
			for i in edge.size() - 1:
				var a: Vector2 = edge[i]
				var bb: Vector2 = edge[i + 1]
				for k in 3:
					var p := a.lerp(bb, (float(k) + 0.5) / 3.0)
					var ln := 8.0 + hh(i * 3 + k, seed_v) * 18.0
					ci.draw_colored_polygon(PackedVector2Array([p + Vector2(-3, 2), p + Vector2(3, 2), p + Vector2(0, ln)]), Color("e6f6fd"))


# ---- פס מים פתוחים (z מעל כפות הרגליים) ----
class WaterLead extends Node2D:
	const FREEZE_T := 2.6         # כמה שניות במים הקפואים עד נזק
	var w := 140.0
	var _t := 0.0

	func _ready() -> void:
		z_index = 6
		add_to_group("water_leads")
		add_to_group("ice_holes")

	func surface_point() -> Vector2:
		return global_position + Vector2(w * 0.5, 0.0)

	func hole_w() -> float:
		return w

	func is_open() -> bool:
		return true

	func boil(_k: float) -> void:
		pass

	func _process(delta: float) -> void:
		_t += delta
		if Art.on_screen(self, global_position + Vector2(w * 0.5, 0), w) and Engine.get_process_frames() % 3 == 0:
			queue_redraw()

	func _draw() -> void:
		# קצוות קרח שבורים, מים שחורים, גושונים צפים, אדים
		draw_rect(Rect2(0, -4.0, w, 34.0), WATER)
		draw_rect(Rect2(0, -4.0, w, 2.0), WATER_HI)
		for q in 4:
			var rx := fposmod(float(q) * 41.0 + _t * 9.0, w - 22.0)
			draw_line(Vector2(rx, 2.0 + float(q % 3) * 4.0), Vector2(rx + 14.0, 2.0 + float(q % 3) * 4.0), Color(0.55, 0.75, 0.9, 0.35), 1.0)
		for q in 3:   # גושוני קרח צפים
			var px := fposmod(float(q) * 53.0 + sin(_t * 0.4 + float(q)) * 10.0, w - 20.0) + 4.0
			var bob := sin(_t * 1.6 + float(q) * 2.0) * 1.0
			draw_colored_polygon(PackedVector2Array([Vector2(px, -2 + bob), Vector2(px + 4, -6 + bob), Vector2(px + 14, -5 + bob), Vector2(px + 16, -1 + bob)]), Color("d4ecf8"))
		for side in [0.0, w]:   # שפת הקרח השבורה
			var dx := 1.0 if side == 0.0 else -1.0
			draw_colored_polygon(PackedVector2Array([Vector2(side, -6), Vector2(side + dx * 10.0, -3), Vector2(side + dx * 6.0, 10), Vector2(side, 14)]), Color("cfe8f6"))
			draw_line(Vector2(side, -6), Vector2(side + dx * 10.0, -3), Color(1, 1, 1, 0.9), 2.0)
		for q in 2:   # אדי ים
			var k := fmod(_t * 0.3 + float(q) * 0.5, 1.0)
			Kit.soft_ellipse(self, Vector2(w * (0.3 + 0.4 * float(q)), -8.0 - k * 24.0), 26.0 + k * 20.0, 8.0, 0.0, Color(0.9, 0.96, 1.0, 0.22 * sin(k * PI)))


# ---- חור דיג בקרח + דגל "tip-up" (קופץ כשמשהו שוחה מתחת) ----
class FishingHole extends Node2D:
	var w := 46.0
	var flag := 0.0               # 0..1 הדגל מורם
	var _boil := 0.0              # בועות (SEALER עומד לצאת)
	var _t := 0.0
	var _splash := 0.0

	func _ready() -> void:
		z_index = 5
		add_to_group("ice_holes")

	func surface_point() -> Vector2:
		return global_position

	func hole_w() -> float:
		return w

	func is_open() -> bool:
		return true

	func boil(k: float) -> void:
		_boil = maxf(_boil, k)
		flag = 1.0

	func splash() -> void:
		_splash = 1.0

	func _process(delta: float) -> void:
		_t += delta
		_boil = move_toward(_boil, 0.0, delta * 1.5)
		_splash = move_toward(_splash, 0.0, delta * 1.6)
		flag = move_toward(flag, 0.0, delta * 0.25)
		if Art.on_screen(self, global_position, 120.0) and (Engine.get_process_frames() % 3 == 0 or _boil > 0.0 or _splash > 0.0):
			queue_redraw()

	func _draw() -> void:
		# שוליים של שלג וקרח שבור, מים כהים, בועות
		draw_colored_polygon(Art.ellipse(Vector2(0, 1), w * 0.72, 6.0, 0.0, 16), Color("d8ecf6"))
		draw_colored_polygon(Art.ellipse(Vector2(0, 1), w * 0.5, 4.2, 0.0, 16), WATER)
		draw_colored_polygon(Art.ellipse(Vector2(-3, 0), w * 0.3, 1.4, 0.0, 10), Color(0.3, 0.5, 0.65, 0.6))
		for q in 3:   # גושוני קרח שנחתכו מהחור
			var bx := w * 0.55 + float(q) * 9.0
			draw_rect(Rect2(bx, -6.0 + float(q % 2) * 2.0, 8.0, 6.0), Color("bfe0f2"))
			draw_rect(Rect2(bx, -6.0 + float(q % 2) * 2.0, 8.0, 1.5), Color(1, 1, 1, 0.9))
		if _boil > 0.0:
			for q in 6:
				var k := fmod(_t * 3.0 + float(q) / 6.0, 1.0)
				var bx2 := sin(float(q) * 2.1 + _t) * w * 0.35
				draw_circle(Vector2(bx2, -k * 16.0 * _boil), 1.5 + k * 2.5, Color(0.85, 0.95, 1.0, 0.8 * (1.0 - k) * _boil))
			draw_colored_polygon(Art.ellipse(Vector2(0, -1), w * 0.45 * (0.8 + 0.2 * sin(_t * 30.0)), 3.0, 0.0, 12), Color(0.7, 0.88, 1.0, 0.5 * _boil))
		if _splash > 0.0:
			for q in 7:
				var a := -PI / 2.0 + (float(q) - 3.0) * 0.32
				var r := (1.0 - _splash) * 50.0 + 6.0
				draw_circle(Vector2.from_angle(a) * r * Vector2(0.9, 1.3), 3.0 + _splash * 3.0, Color(0.9, 0.97, 1.0, 0.75 * _splash))
		# ה-tip-up: מוט עץ, קפיץ, דגל כתום
		var px := -w * 0.8
		draw_line(Vector2(px - 8, 0), Vector2(px + 8, 0), WOOD_D, 3.0)
		draw_line(Vector2(px, 0), Vector2(px, -14), WOOD, 2.0)
		var ang := lerpf(PI * 0.45, -PI * 0.5, clampf(flag * 1.3, 0.0, 1.0))
		var tip := Vector2(px, -14) + Vector2.from_angle(ang) * 22.0
		draw_line(Vector2(px, -14), tip, Color("2a2a2a"), 1.6)
		var fl := tip + Vector2(0, 0)
		var wv := sin(_t * 9.0) * 2.0 * flag
		draw_colored_polygon(PackedVector2Array([fl, fl + Vector2(11, 3 + wv), fl + Vector2(0, 7)]), Color("ff6a1a"))
		if flag > 0.6:
			Kit.soft_glow(self, fl + Vector2(4, 3), 16.0, Color(1.0, 0.5, 0.1, 0.45 * flag))


# ============================================================
#  מלכודת: קרח דק
# ============================================================
class ThinIce extends Node2D:
	const W := 150.0
	const CRACK_T := 1.1          # כמה זמן עומדים עד שזה נשבר
	const DMG := 1
	const DMG_Z := 45
	const SLOW := 1.4             # מים עד הברכיים
	const REFREEZE := 16.0
	var state := 0                # 0 שלם, 1 נסדק, 2 שבור (מים), 3 קופא מחדש
	var crack := 0.0
	var breaks := 0               # לבדיקות
	var hits := 0
	var drowned := 0
	var _t := 0.0
	var _tt := 0.0
	var _snd := 0.0
	var rect := Rect2(-W * 0.5, -30.0, W, 30.0)

	func _ready() -> void:
		z_index = 2
		add_to_group("hazards")
		add_to_group("blastable")

	func world_rect() -> Rect2:
		return Rect2(global_position + Vector2(-W * 0.5, -60.0), Vector2(W, 60.0))

	func danger_at(p: Vector2, margin := 0.0) -> bool:
		return state == 1 and world_rect().grow(margin).has_point(p)

	# SEALER: חור פתוח
	func surface_point() -> Vector2:
		return global_position

	func hole_w() -> float:
		return W * 0.8

	func is_open() -> bool:
		return state == 2

	func boil(_k: float) -> void:
		pass

	func blast_rect() -> Rect2:
		return Rect2(global_position + Vector2(-W * 0.5, -20.0), Vector2(W, 24.0))

	func hit_by_blast(_c: Vector2, _r: float) -> void:
		if state == 0 or state == 1:
			_break()

	func on_ice(p: Vector2) -> bool:
		return absf(p.x - global_position.x) < W * 0.5 - 4.0 and absf(p.y - global_position.y) < 8.0

	func _break() -> void:
		state = 2
		_t = REFREEZE
		breaks += 1
		if not is_in_group("ice_holes"):
			add_to_group("ice_holes")
		Sfx.play("ti_break", global_position, 2.0, 0.1, 2)
		Sfx.play("splash", global_position, 0.0, 0.1, 2)
		Particles.burst(get_parent(), global_position + Vector2(0, -6), "snow", Vector2.UP, 14)
		Particles.burst(get_parent(), global_position + Vector2(0, -4), "drop", Vector2.UP, 10)
		var pl := get_tree().get_first_node_in_group("player")
		if pl != null and not pl.dead and on_ice(pl.global_position):
			hits += 1
			pl.hurt(DMG, Vector2(0, -0.4))
			pl.slow_t = maxf(pl.slow_t, SLOW)
			pl._say("THROUGH THE ICE!", Color("9adcff"))
		for z in get_tree().get_nodes_in_group("zombies"):
			if not z.dead and on_ice(z.global_position) and z.collision_layer != 0:
				drowned += 1
				z.take_damage(DMG_Z if not z.is_boss() else 15, z.global_position + Vector2(0, -20), Vector2.UP, true, {"source": "hazard", "fixed": DMG_Z if not z.is_boss() else 15})

	func _physics_process(delta: float) -> void:
		_tt += delta
		_snd -= delta
		match state:
			0, 1:
				var heavy := false
				var pl := get_tree().get_first_node_in_group("player")
				var on: bool = pl != null and not pl.dead and pl.is_on_floor() and on_ice(pl.global_position)
				for z in get_tree().get_nodes_in_group("zombies"):
					if z.is_boss() and not z.dead and on_ice(z.global_position):
						heavy = true
				if on or heavy:
					if state == 0:
						state = 1
						Sfx.play("ti_crack", global_position, 0.0, 0.15, 2)
					crack += delta / CRACK_T * (2.5 if heavy else 1.0)
					if _snd <= 0.0:
						_snd = 0.28
						Sfx.play("ti_crack", global_position, -4.0 + crack * 4.0, 0.2, 2)
					if crack >= 1.0:
						_break()
				else:
					crack = maxf(0.0, crack - delta * 0.15)   # הסדקים נשארים (מחלימים לאט)
					if crack <= 0.0 and state == 1:
						state = 0
			2:
				_t -= delta
				if _t <= 0.0:
					state = 3
					_t = 2.0
			3:
				_t -= delta
				if _t <= 0.0:
					state = 0
					crack = 0.0
					remove_from_group("ice_holes")
		if Art.on_screen(self, global_position, W) and (state == 1 or state == 2 or Engine.get_physics_frames() % 10 == 0):
			queue_redraw()

	func _draw() -> void:
		var hw := W * 0.5
		if state == 2 or state == 3:
			var fr := 0.0 if state == 2 else 1.0 - _t / 2.0
			draw_rect(Rect2(-hw + 6.0, -3.0, W - 12.0, 28.0), WATER)
			draw_rect(Rect2(-hw + 6.0, -3.0, W - 12.0, 2.0), WATER_HI)
			for q in 5:   # גושי קרח שבורים צפים
				var px := -hw + 14.0 + float(q) * 26.0 + sin(_tt + float(q)) * 3.0
				var bob := sin(_tt * 2.0 + float(q) * 1.3) * 1.2
				draw_colored_polygon(PackedVector2Array([Vector2(px, bob), Vector2(px + 5, -5 + bob), Vector2(px + 18, -4 + bob), Vector2(px + 20, 1 + bob)]), Color("cfe7f4"))
			if fr > 0.0:
				draw_rect(Rect2(-hw + 6.0, -3.0, W - 12.0, 6.0), Color(0.75, 0.88, 0.96, fr))
			for side in [-hw, hw]:
				var dx := 1.0 if side < 0.0 else -1.0
				draw_colored_polygon(PackedVector2Array([Vector2(side, -4), Vector2(side + dx * 12.0, -2), Vector2(side + dx * 8.0, 12), Vector2(side, 14)]), Color("cfe8f6"))
			return
		# משטח קרח דק: אפור-כחול שקוף, בלי שלג (מנוקה), מים כהים מתחת, סדקים
		draw_rect(Rect2(-hw, -1.0, W, 12.0), Color("6f9cbc"))
		draw_rect(Rect2(-hw, -1.0, W, 3.0), Color("b9dcef"))
		for q in 6:
			draw_line(Vector2(-hw + 10.0 + float(q) * 24.0, 4.0), Vector2(-hw + 18.0 + float(q) * 24.0, 8.0), Color(0.15, 0.3, 0.45, 0.6), 2.0)
		# שלט אזהרה קטן בצד
		draw_line(Vector2(-hw - 10.0, 0), Vector2(-hw - 10.0, -30.0), WOOD_D, 2.0)
		draw_rect(Rect2(-hw - 22.0, -40.0, 24.0, 14.0), Color("e8d04a"))
		draw_string(ThemeDB.fallback_font, Vector2(-hw - 19.0, -29.0), "!", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("2a2a2a"))
		var c := clampf(crack, 0.0, 1.0)
		if c > 0.0:   # סדקים שגדלים מהמרכז
			var n := 3 + int(c * 6.0)
			for q in n:
				var a := float(q) / float(n) * PI + 0.2
				var l := (20.0 + float(q % 3) * 14.0) * c
				var p0 := Vector2(sin(float(q) * 3.1) * 12.0, 4.0)
				draw_polyline(PackedVector2Array([p0, p0 + Vector2(cos(a) * l * 0.5, 2.0), p0 + Vector2(cos(a) * l, (-1.0 if q % 2 == 0 else 3.0))]), Color(1.0, 1.0, 1.0, 0.9), 1.4)
			if state == 1 and int(_tt * 8.0) % 2 == 0:
				draw_string(ThemeDB.fallback_font, Vector2(-6.0, -24.0), "!", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color("9adcff"))
			Kit.soft_glow(self, Vector2(0, 4), 60.0 * c, Color(0.5, 0.8, 1.0, 0.25 * c), 0.25)


# ============================================================
#  מלכודת: מדף קרח תלוי שמתנתק
# ============================================================
class Calving extends Node2D:
	const W := 170.0              # אזור הנפילה
	const H := 270.0              # גובה המדף מעל הרצפה
	const TRIGGER := 140.0
	const WARN_T := 1.15
	const SHOT_WARN := 0.35
	const DMG := 1
	const DMG_Z := 60
	const REGROW_T := 14.0
	var state := 0                # 0 תלוי, 1 נסדק (אזהרה), 2 נופל, 3 נשבר (צומח מחדש)
	var falls := 0                # לבדיקות
	var hits := 0
	var crushed := 0
	var _t := 0.0
	var _tt := 0.0
	var _chunks := []             # [x, y, vy, size, rot]
	var _hit_done := false
	var _crushed_ids := {}
	var _body: StaticBody2D = null
	var rect := Rect2(-W * 0.5, -40.0, W, 40.0)

	class Crack extends StaticBody2D:
		var c = null
		func hit_by_bullet(_p: Vector2, _n: Vector2, _d: Vector2) -> void:
			if c != null and c.state == 0:
				c.trigger(c.SHOT_WARN)

	func _ready() -> void:
		z_index = 4
		add_to_group("hazards")
		add_to_group("calving")
		var b := Crack.new()
		b.c = self
		b.collision_layer = 4
		b.collision_mask = 0
		var cs := CollisionShape2D.new()
		var sh := RectangleShape2D.new()
		sh.size = Vector2(70, 34)
		cs.shape = sh
		cs.position = Vector2(0, -H - 10.0)
		b.add_child(cs)
		add_child(b)
		_body = b
		var wall := Wall.new()
		wall.z_as_relative = false
		wall.z_index = -2
		add_child(wall)

	class Wall extends Node2D:   # קיר הקרחון מאחורי המדף (מאחורי הדמויות)
		func _draw() -> void:
			var W := Calving.W
			var H := Calving.H
			var hw := W * 0.5 + 40.0
			var face := PackedVector2Array([Vector2(-hw - 30, 0), Vector2(-hw - 10, -H - 60), Vector2(-hw + 40, -H - 90), Vector2(hw - 30, -H - 80), Vector2(hw + 20, -H - 40), Vector2(hw + 40, 0)])
			IceArt.cliff(self, face, -hw - 30.0, hw + 40.0, -H - 90.0, int(global_position.x) % 97)
			draw_colored_polygon(PackedVector2Array([Vector2(-hw - 30, 0), Vector2(-hw - 10, -H - 60), Vector2(-hw + 10, -H - 66), Vector2(-hw + 6, 0)]), Color(0.75, 0.9, 1.0, 0.5))
			draw_rect(Rect2(-hw - 30.0, -14.0, hw * 2.0 + 70.0, 14.0), Color("cfe7f4"))

	func world_rect() -> Rect2:
		return Rect2(global_position + Vector2(-W * 0.5, -H), Vector2(W, H))

	func danger_at(p: Vector2, margin := 0.0) -> bool:
		return (state == 1 or state == 2) and Rect2(global_position + Vector2(-W * 0.5, -90.0), Vector2(W, 90.0)).grow(margin).has_point(p)

	func trigger(t := WARN_T) -> void:
		if state != 0:
			return
		state = 1
		_t = t
		Sfx.play("cv_groan", global_position + Vector2(0, -H), 2.0, 0.1, 2)
		var pl := get_tree().get_first_node_in_group("player")
		if pl != null and t >= WARN_T and pl.global_position.distance_to(global_position) < 500.0 and pl.has_method("_say"):
			pl._say("THE ICE IS CALVING!", Color("9adcff"))

	func _physics_process(delta: float) -> void:
		_tt += delta
		_t -= delta
		match state:
			0:
				var pl := get_tree().get_first_node_in_group("player")
				if pl != null and not pl.dead and absf(pl.global_position.x - global_position.x) < TRIGGER and absf(pl.global_position.y - global_position.y) < 220.0:
					trigger()
			1:
				if Engine.get_physics_frames() % 4 == 0 and Art.on_screen(self, global_position + Vector2(0, -H), 200.0):
					Particles.burst(get_parent(), global_position + Vector2(randf_range(-40, 40), -H + 4.0), "snow", Vector2.DOWN, 2)
				if _t <= 0.0:
					_fall()
			2:
				var all_down := true
				for c in _chunks:
					if c[1] < 0.0:
						c[2] += 1500.0 * delta
						c[1] = minf(0.0, c[1] + c[2] * delta)
						c[4] += delta * 3.0
						all_down = false
						if c[1] >= 0.0:
							_land(c)
				_check_hit()
				if all_down:
					state = 3
					_t = REGROW_T
			3:
				if _t <= 0.0:
					state = 0
					_chunks.clear()
		if Art.on_screen(self, global_position + Vector2(0, -H * 0.5), H) and (state != 0 or Engine.get_physics_frames() % 12 == 0):
			queue_redraw()

	func _fall() -> void:
		state = 2
		falls += 1
		_hit_done = false
		_crushed_ids.clear()
		_chunks.clear()
		for q in 4:
			_chunks.append([-W * 0.4 + float(q) * W * 0.27 + randf_range(-8, 8), -H + randf_range(-10, 10), randf_range(-60.0, 40.0), randf_range(18.0, 28.0), randf()])
		Sfx.play("cv_crash", global_position + Vector2(0, -H * 0.5), 3.0, 0.1, 2)

	func _land(c: Array) -> void:
		Sfx.play("glass", global_position + Vector2(c[0], 0), -2.0, 0.2, 3)
		if Art.on_screen(self, global_position, 200.0):
			Particles.burst(get_parent(), global_position + Vector2(c[0], -6.0), "snow", Vector2.UP, 10)
			var cam := get_viewport().get_camera_2d()
			if cam != null and cam.has_method("shake"):
				cam.shake(5.0, 0.2)

	func _check_hit() -> void:
		var low := -999.0
		for c in _chunks:
			low = maxf(low, c[1])
		if low < -70.0:
			return
		var r := Rect2(global_position + Vector2(-W * 0.5, -70.0), Vector2(W, 72.0))
		var pl := get_tree().get_first_node_in_group("player")
		if not _hit_done and pl != null and not pl.dead and r.intersects(pl.body_rect()):
			_hit_done = true
			if pl._roll_t <= 0.0:
				hits += 1
			pl.hurt(DMG, Vector2(signf(pl.global_position.x - global_position.x + 0.01) * 1.2, -0.4))
		for z in get_tree().get_nodes_in_group("zombies"):
			if z.dead or _crushed_ids.has(z.get_instance_id()) or z.collision_layer == 0:
				continue
			if r.has_point(z.global_position + Vector2(0, -10)):
				_crushed_ids[z.get_instance_id()] = true
				crushed += 1
				var d: int = DMG_Z if not z.is_boss() else 25
				z.take_damage(d, z.global_position + Vector2(0, -40), Vector2.DOWN, true, {"source": "hazard", "fixed": d, "calve": true})

	func _draw() -> void:
		var hw := W * 0.5
		var grow := 1.0
		if state == 3:
			grow = clampf(1.0 - _t / REGROW_T, 0.0, 1.0)
		if state != 2:
			# המדף התלוי: גוש כחול-לבן עם נטיפים
			var sh := Vector2(sin(_tt * 40.0) * 1.5, 0.0) if state == 1 else Vector2.ZERO
			var k := grow if state == 3 else 1.0
			var top := -H - 30.0
			var bot := -H + 22.0 * k
			var poly := PackedVector2Array([Vector2(-hw - 20, top), Vector2(hw + 30, top), Vector2(hw + 10, bot - 6), Vector2(hw * 0.3, bot), Vector2(-hw * 0.4, bot + 4), Vector2(-hw, bot - 8)])
			for i in poly.size():
				poly[i] += sh
			draw_colored_polygon(poly, Color("b8e0f4"))
			draw_line(poly[0], poly[1], Color(1, 1, 1, 0.95), 3.0)
			for q in 7:   # נטיפים
				var ix := -hw + 10.0 + float(q) * W / 6.5
				var il := (14.0 + float((q * 7) % 5) * 5.0) * k
				draw_colored_polygon(PackedVector2Array([Vector2(ix - 4, bot - 4) + sh, Vector2(ix + 4, bot - 4) + sh, Vector2(ix, bot + il) + sh]), Color("dff2fb"))
			# הסדק הכחול (אפשר לירות בו)
			var glow := 0.35 + 0.15 * sin(_tt * 3.0)
			if state == 1:
				glow = 0.9
			draw_polyline(PackedVector2Array([Vector2(-26, top + 6) + sh, Vector2(-10, -H - 12) + sh, Vector2(4, -H - 18) + sh, Vector2(18, -H) + sh, Vector2(30, -H + 10) + sh]), Color(0.25, 0.6, 1.0, 0.9), 3.0)
			Kit.soft_glow(self, Vector2(2, -H - 8) + sh, 28.0, Color(0.4, 0.75, 1.0, glow * 0.6))
		if state == 1:   # צל על הרצפה + סימן
			var k2 := clampf(1.0 - _t / WARN_T, 0.0, 1.0)
			draw_colored_polygon(Art.ellipse(Vector2(0, -2), hw * (0.6 + 0.4 * k2), 6.0, 0.0, 18), Color(0.05, 0.15, 0.3, 0.35 + 0.25 * k2))
			if int(_tt * 8.0) % 2 == 0:
				draw_string(ThemeDB.fallback_font, Vector2(-7.0, -H + 70.0), "!", HORIZONTAL_ALIGNMENT_LEFT, -1, 26, Color("9adcff"))
		for c in _chunks:   # גושים נופלים / שוכבים
			var s: float = c[3]
			var a := 1.0
			if state == 3:
				a = clampf((_t - REGROW_T + 3.0) / 3.0, 0.0, 1.0)
			var xf := Transform2D(c[4], Vector2(c[0], c[1] - s * 0.5))
			draw_colored_polygon(xf * PackedVector2Array([Vector2(-s, -s * 0.7), Vector2(s * 0.8, -s * 0.8), Vector2(s, s * 0.6), Vector2(-s * 0.9, s * 0.7)]), Color(0.78, 0.9, 0.97, a))
			draw_line(xf * Vector2(-s, -s * 0.7), xf * Vector2(s * 0.8, -s * 0.8), Color(1, 1, 1, a), 2.0)


# ============================================================
#  מלכודת: מסילת וו הדגים של המפעל
# ============================================================
class HookLine extends Node2D:
	const WARN_T := 0.9
	const SPEED := 430.0
	const DMG := 1
	const DMG_Z := 70
	const CD := 5.0
	const HOOK_Y := Vector2(-52.0, -38.0)   # רצועת הפגיעה מעל הרצפה (מתכופפים = 34 -> עובר מעל)
	var w := 520.0
	var rail_y := -132.0
	var state := 0                # 0 חונה, 1 אזהרה, 2 רץ, 3 מתקרר
	var runs := 0                 # לבדיקות
	var hits := 0
	var hooked := 0
	var _x := 0.0                 # מקום העגלה (0..w)
	var _dir := 1.0
	var _t := 0.0
	var _tt := 0.0
	var _swing := 0.0
	var _hit_done := false
	var _carry := []
	var rect := Rect2(0, -60.0, 520.0, 60.0)

	class Motor extends StaticBody2D:
		var h = null
		func hit_by_bullet(_p: Vector2, _n: Vector2, _d: Vector2) -> void:
			if h != null and h.state == 0:
				h.start(0.3)

	func _ready() -> void:
		z_index = 5
		add_to_group("hazards")
		rect = Rect2(0, -60.0, w, 60.0)
		var m := Motor.new()
		m.h = self
		m.collision_layer = 4
		m.collision_mask = 0
		var cs := CollisionShape2D.new()
		var sh := RectangleShape2D.new()
		sh.size = Vector2(30, 26)
		cs.shape = sh
		cs.position = Vector2(-20, rail_y - 6.0)
		m.add_child(cs)
		add_child(m)

	func world_rect() -> Rect2:
		return Rect2(global_position + Vector2(0, -60.0), Vector2(w, 60.0))

	func hook_pos() -> Vector2:
		var lag := sin(_swing) * 26.0
		return global_position + Vector2(_x - lag * _dir, -46.0)

	func danger_at(p: Vector2, margin := 0.0) -> bool:
		if state != 2:
			return state == 1 and world_rect().grow(margin).has_point(p)
		return absf(p.x - hook_pos().x) < 80.0 + margin and absf(p.y - global_position.y) < 40.0

	func start(t := WARN_T) -> void:
		state = 1
		_t = t
		Sfx.play("sw_bell" if Sfx.has_sound("sw_bell") else "beep", global_position + Vector2(-20, rail_y), 1.0, 0.05, 2)
		Sfx.play("hk_rattle", global_position + Vector2(_x, rail_y), 1.0, 0.1, 2)

	func _physics_process(delta: float) -> void:
		_tt += delta
		_t -= delta
		match state:
			0:
				var pl := get_tree().get_first_node_in_group("player")
				if pl != null and not pl.dead and pl.global_position.x > global_position.x + 30.0 and pl.global_position.x < global_position.x + w - 30.0 \
						and absf(pl.global_position.y - global_position.y) < 30.0:
					start()
			1:
				if _t <= 0.0:
					state = 2
					runs += 1
					_hit_done = false
					Sfx.play("hk_run", global_position + Vector2(_x, rail_y), 2.0, 0.05, 2)
			2:
				_x += _dir * SPEED * delta
				_swing += delta * 9.0
				_check()
				for c in _carry:
					if is_instance_valid(c) and not c.dead:
						c.global_position = hook_pos() + Vector2(0, 30.0)
						c.velocity = Vector2.ZERO
				if (_dir > 0.0 and _x >= w) or (_dir < 0.0 and _x <= 0.0):
					_x = clampf(_x, 0.0, w)
					_dir = -_dir
					state = 3
					_t = CD
					for c in _carry:   # זורק אותם בסוף המסלול
						if is_instance_valid(c) and not c.dead:
							c.velocity = Vector2(-_dir * 380.0, -320.0)
							c.take_damage(DMG_Z, c.global_position + Vector2(0, -30), Vector2(-_dir, -0.5), true, {"source": "hazard", "fixed": DMG_Z})
					_carry.clear()
					Sfx.play("clang", global_position + Vector2(_x, rail_y), -2.0, 0.1, 2)
			3:
				_swing = move_toward(_swing, 0.0, delta * 2.0)
				if _t <= 0.0:
					state = 0
		if Art.on_screen(self, global_position + Vector2(w * 0.5, -60.0), w * 0.6) and (state != 0 or Engine.get_physics_frames() % 8 == 0):
			queue_redraw()

	func _check() -> void:
		var hp := hook_pos()
		var band := Rect2(hp.x - 14.0, global_position.y + HOOK_Y.x, 28.0, HOOK_Y.y - HOOK_Y.x)
		var pl := get_tree().get_first_node_in_group("player")
		if not _hit_done and pl != null and not pl.dead and band.intersects(pl.body_rect()):
			_hit_done = true
			if pl._roll_t <= 0.0:
				hits += 1
			pl.hurt(DMG, Vector2(_dir * 1.6, -0.5))
		for z in get_tree().get_nodes_in_group("zombies"):
			if z.dead or z.is_boss() or _carry.has(z) or _carry.size() >= 2 or z.collision_layer == 0:
				continue
			var zr := Rect2(z.global_position + Vector2(-12.0, -56.0 * z.sc), Vector2(24.0, 56.0 * z.sc))
			if zr.intersects(band):
				_carry.append(z)
				hooked += 1
				Sfx.play("hook", z.global_position, 2.0, 0.1, 2)
				Particles.burst(z.get_parent(), z.global_position + Vector2(0, -40), "hit", Vector2.UP, 6)
				z._popup("HOOKED", Color("ffb070"), 13, -84.0)

	func _draw() -> void:
		# המסילה + תומכים + קופסת המנוע עם נורה
		draw_line(Vector2(-30, rail_y), Vector2(w + 10, rail_y), STEEL_D, 5.0)
		draw_line(Vector2(-30, rail_y - 2.0), Vector2(w + 10, rail_y - 2.0), STEEL, 1.5)
		for q in int(w / 130.0) + 1:
			var sx := float(q) * 130.0
			draw_line(Vector2(sx, rail_y), Vector2(sx, rail_y - 40.0), STEEL_D, 3.0)
		draw_rect(Rect2(-36.0, rail_y - 20.0, 32.0, 26.0), Color("3a4450"))
		draw_rect(Rect2(-36.0, rail_y - 20.0, 32.0, 5.0), Color("c03a2a"))
		draw_string(ThemeDB.fallback_font, Vector2(-34.0, rail_y), "M", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.9, 0.9, 0.85, 0.8))
		var blink := (state == 1 or state == 2) and int(_tt * 8.0) % 2 == 0
		var lc := Color(1.0, 0.25, 0.15) if blink else Color(0.35, 0.1, 0.08)
		draw_circle(Vector2(-20, rail_y - 26.0), 4.0, lc)
		if blink:
			Kit.soft_glow(self, Vector2(-20, rail_y - 26.0), 36.0, Color(1.0, 0.25, 0.1, 0.5))
		# העגלה + השרשרת + הוו (מתנדנד)
		var tx := _x
		draw_rect(Rect2(tx - 12.0, rail_y - 6.0, 24.0, 10.0), Color("2a3038"))
		draw_circle(Vector2(tx - 7.0, rail_y - 4.0), 3.0, STEEL)
		draw_circle(Vector2(tx + 7.0, rail_y - 4.0), 3.0, STEEL)
		var hp := hook_pos() - global_position
		var a := Vector2(tx, rail_y + 4.0)
		var n := 8
		for q in n:
			var p0 := a.lerp(hp + Vector2(0, -10), float(q) / float(n))
			draw_circle(p0, 1.8, Color("4a525c"))
		# הוו הגדול + פיתיון: דג קפוא
		draw_arc(hp + Vector2(0, 2), 9.0, -0.3, PI + 0.6, 12, Color("b8c0c8"), 3.0)
		draw_line(hp + Vector2(0, -10), hp + Vector2(9, 2), Color("b8c0c8"), 3.0)
		draw_colored_polygon(PackedVector2Array([hp + Vector2(-9, 2), hp + Vector2(-13, -4), hp + Vector2(-6, -1)]), Color("d8dde2"))
		if state == 0 or state == 3:
			Art.oval(self, hp + Vector2(2, 16), 10.0, 4.0, Color("8aa0b4"), 0.2, Art.OUTLINE, 1.0)
			draw_colored_polygon(PackedVector2Array([hp + Vector2(11, 15), hp + Vector2(17, 10), hp + Vector2(17, 21)]), Color("6a8296"))
		if state == 1 and int(_tt * 8.0) % 2 == 0:
			draw_string(ThemeDB.fallback_font, Vector2(tx - 6.0, rail_y - 18.0), "!", HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color("ffb050"))
		if state == 2:   # קווי מהירות
			for q in 3:
				draw_line(hp + Vector2(-_dir * (20.0 + float(q) * 8.0), -6.0 + float(q) * 6.0), hp + Vector2(-_dir * (44.0 + float(q) * 12.0), -6.0 + float(q) * 6.0), Color(1, 1, 1, 0.4), 1.4)


# ============================================================
#  מלכודת: חבית דלק קפואה
# ============================================================
class FuelDrum extends StaticBody2D:
	const HP := 3
	const FUSE := 0.7
	const BLAST_R := 140.0
	const BLAST_DMG := 70
	var hp := HP
	var blown := 0                # לבדיקות
	var _fuse := -1.0
	var _t := 0.0
	var _gone := false

	func _ready() -> void:
		collision_layer = 1
		collision_mask = 0
		z_index = 2
		add_to_group("blastable")
		add_to_group("fuel_drums")
		var cs := CollisionShape2D.new()
		var sh := RectangleShape2D.new()
		sh.size = Vector2(30, 44)
		cs.shape = sh
		cs.position = Vector2(0, -22)
		add_child(cs)

	func blast_rect() -> Rect2:
		return Rect2(global_position + Vector2(-15, -44), Vector2(30, 44))

	func hit_by_blast(_c: Vector2, _r: float) -> void:
		if _fuse < 0.0 and not _gone:
			_fuse = 0.12

	func hit_by_bullet(p: Vector2, _n: Vector2, d: Vector2) -> void:
		if _gone:
			return
		hp -= 1
		Sfx.play("metal_ping" if Sfx.has_sound("metal_ping") else "clang", p, -4.0, 0.15, 3)
		Particles.burst(get_parent(), p, "snow", -d, 5)
		if hp <= 0 and _fuse < 0.0:
			_fuse = FUSE
			Sfx.play("fd_hiss", global_position, 1.0, 0.1, 2)

	func ignite(t := FUSE) -> void:
		if _fuse < 0.0 and not _gone:
			_fuse = t

	func _physics_process(delta: float) -> void:
		_t += delta
		if _gone:
			return
		if _fuse >= 0.0:
			_fuse -= delta
			if Engine.get_physics_frames() % 3 == 0:
				Particles.burst(get_parent(), global_position + Vector2(8, -40), "fire", Vector2(0.3, -1.0), 2)
			queue_redraw()
			if _fuse <= 0.0:
				_explode()

	func _explode() -> void:
		_gone = true
		blown += 1
		var p := global_position + Vector2(0, -24)
		var par := get_parent()
		Boom.blast(par, p, BLAST_R, 80.0, BLAST_DMG, 1, "barrel")
		Particles.burst(par, p, "snow", Vector2.UP, 12)
		queue_free()

	func _draw() -> void:
		var shake := Vector2(randf_range(-1.5, 1.5), 0) if _fuse >= 0.0 else Vector2.ZERO
		# חבית אדומה עם כפור, פסים, סימן דליק
		draw_rect(Rect2(Vector2(-15, -44) + shake, Vector2(30, 44)), Color("a03224"))
		draw_rect(Rect2(Vector2(-15, -44) + shake, Vector2(8, 44)), Color("c4483a"))
		draw_rect(Rect2(Vector2(-15, -32) + shake, Vector2(30, 3)), Color("5a1a14"))
		draw_rect(Rect2(Vector2(-15, -14) + shake, Vector2(30, 3)), Color("5a1a14"))
		draw_colored_polygon(PackedVector2Array([Vector2(-6, -18) + shake, Vector2(0, -28) + shake, Vector2(6, -18) + shake]), Color("f0c030"))
		var frost := clampf(float(hp) / float(HP), 0.0, 1.0)
		draw_rect(Rect2(Vector2(-16, -46) + shake, Vector2(32, 6)), Color(0.92, 0.97, 1.0, 0.9 * frost + 0.2))
		for q in 4:
			draw_line(Vector2(-14 + q * 9, -40) + shake, Vector2(-12 + q * 9, -30 + (q % 2) * 6) + shake, Color(0.9, 0.97, 1.0, 0.7 * frost), 2.0)
		if _fuse >= 0.0:
			Kit.soft_glow(self, Vector2(8, -40), 24.0, Color(1.0, 0.5, 0.15, 0.7))


# ============================================================
#  מבנים (קומות: add_floor בשלב)
# ============================================================
class Cannery extends Node2D:
	var w := 600.0
	var tier := 150.0
	var roof_tier := 290.0
	var roof_x := Vector2(100.0, 500.0)
	var _t := 0.0

	func _ready() -> void:
		z_index = -1

	func _process(delta: float) -> void:
		_t += delta
		if Engine.get_process_frames() % 10 == 0 and Art.on_screen(self, global_position + Vector2(w * 0.5, -tier), w):
			queue_redraw()

	func _draw() -> void:
		# כלונסאות
		for px in range(0, int(w) + 1, 75):
			var x := minf(float(px), w - 12.0)
			draw_rect(Rect2(x, -tier, 12.0, tier), Color("3a2e26"))
			draw_rect(Rect2(x, -40.0, 12.0, 8.0), Color(0.88, 0.95, 1.0, 0.75))
		draw_line(Vector2(0, -tier + 20.0), Vector2(w, -30.0), Color("33281f"), 3.0)
		# הבניין: פח גלי ירוק-חלוד
		var bx := roof_x.x - 20.0
		var bw := roof_x.y - roof_x.x + 40.0
		var top := -roof_tier
		draw_rect(Rect2(bx, top, bw, roof_tier - tier), Color("4a6a62"))
		for q in int(bw / 10.0):
			draw_line(Vector2(bx + float(q) * 10.0 + 4.0, top + 4.0), Vector2(bx + float(q) * 10.0 + 4.0, -tier - 2.0), Color("3a5650"), 2.0)
		for q in 6:
			Art.oval(self, Vector2(bx + 20.0 + float(q) * bw / 6.0, top + 40.0 + float(q % 2) * 30.0), 10.0, 16.0, Color(0.5, 0.28, 0.16, 0.45), 0.0, Art.NONE)
		# חלונות מוארים
		for q in 3:
			var wx := bx + 40.0 + float(q) * (bw - 80.0) / 2.0 - 22.0
			draw_rect(Rect2(wx, -tier - 80.0, 44.0, 30.0), Color("2a3a40"))
			var lit := 0.55 + 0.1 * sin(_t * 1.3 + float(q))
			draw_rect(Rect2(wx + 3.0, -tier - 77.0, 38.0, 24.0), Color(1.0, 0.85, 0.55, lit))
			draw_line(Vector2(wx + 22.0, -tier - 77.0), Vector2(wx + 22.0, -tier - 53.0), Color("2a3a40"), 2.0)
			Kit.soft_glow(self, Vector2(wx + 22.0, -tier - 65.0), 40.0, Color(1.0, 0.8, 0.5, 0.18))
		# שלט
		draw_rect(Rect2(bx + bw * 0.5 - 120.0, top - 30.0, 240.0, 28.0), Color("e8e0cc"))
		draw_rect(Rect2(bx + bw * 0.5 - 120.0, top - 30.0, 240.0, 28.0), Color("8a3a2a"), false, 3.0)
		draw_string(ThemeDB.fallback_font, Vector2(bx + bw * 0.5 - 108.0, top - 10.0), "CONSERVERA  AUSTRAL", HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color("8a3a2a"))
		# גג: שלג ונטיפים
		draw_rect(Rect2(bx - 10.0, top - 4.0, bw + 20.0, 8.0), STEEL_D)
		draw_rect(Rect2(bx - 12.0, top - 10.0, bw + 24.0, 7.0), SNOW)
		for q in int(bw / 22.0):
			var ix := bx + float(q) * 22.0
			draw_colored_polygon(PackedVector2Array([Vector2(ix, top + 4), Vector2(ix + 6, top + 4), Vector2(ix + 3, top + 12 + float(q % 3) * 5)]), Color("e0f2fa"))
		# מעקה לגג
		draw_line(Vector2(roof_x.x, top - 34.0), Vector2(roof_x.y, top - 34.0), STEEL, 2.0)
		for q in 9:
			var rx := lerpf(roof_x.x, roof_x.y, float(q) / 8.0)
			draw_line(Vector2(rx, top - 10.0), Vector2(rx, top - 34.0), STEEL_D, 2.0)
		# מסלול ההליכה (הקומה) + מעקה
		draw_rect(Rect2(-6.0, -tier, w + 12.0, 10.0), WOOD)
		draw_rect(Rect2(-6.0, -tier, w + 12.0, 3.0), Color(0.9, 0.95, 1.0, 0.85))
		draw_line(Vector2(-6.0, -tier - 26.0), Vector2(w + 6.0, -tier - 26.0), WOOD_D, 3.0)
		for q in int(w / 30.0) + 1:
			draw_line(Vector2(float(q) * 30.0, -tier), Vector2(float(q) * 30.0, -tier - 26.0), WOOD_D, 2.0)
		# ארובה עם עשן
		var cx := bx + bw - 40.0
		draw_rect(Rect2(cx, top - 70.0, 16.0, 60.0), RUST)
		for q in 3:
			var k := fmod(_t * 0.4 + float(q) / 3.0, 1.0)
			Kit.soft_glow(self, Vector2(cx + 8.0 - k * 30.0, top - 76.0 - k * 50.0), 14.0 + k * 16.0, Color(0.85, 0.88, 0.92, 0.4 * (1.0 - k)))
		# ארגזי שימורים מתחת
		for q in 3:
			var kx := 60.0 + float(q) * 170.0
			draw_rect(Rect2(kx, -28.0, 40.0, 28.0), Color("6a5236"))
			draw_rect(Rect2(kx, -28.0, 40.0, 4.0), SNOW)
			draw_string(ThemeDB.fallback_font, Vector2(kx + 3.0, -10.0), "MERLUZA", HORIZONTAL_ALIGNMENT_LEFT, -1, 7, Color(0.9, 0.85, 0.7, 0.8))


# ---- סירת דייגים תקועה בקרח ----
class FrozenBoat extends Node2D:
	var w := 340.0
	var deck := 110.0
	var cab_tier := 210.0
	var cab_x := Vector2(190.0, 300.0)
	var col := Color("b0402e")
	var seed_v := 0
	var name_s := "SAN JUAN"
	var _t := 0.0

	func _ready() -> void:
		z_index = -1

	func _process(delta: float) -> void:
		_t += delta
		if Engine.get_process_frames() % 12 == 0 and Art.on_screen(self, global_position + Vector2(w * 0.5, -deck), w):
			queue_redraw()

	func _draw() -> void:
		# קרח שנדחס סביב הגוף
		draw_colored_polygon(PackedVector2Array([Vector2(-30, 0), Vector2(-10, -24), Vector2(30, -18), Vector2(w - 20, -22), Vector2(w + 20, -10), Vector2(w + 40, 0)]), Color("cfe8f6"))
		# גוף הסירה: מוטה מעט, צבע + קו מים לבן
		var hull := PackedVector2Array([Vector2(-20, -deck), Vector2(w + 30, -deck - 14), Vector2(w, -10), Vector2(10, -6)])
		draw_colored_polygon(hull, col)
		draw_colored_polygon(PackedVector2Array([Vector2(-20, -deck), Vector2(w + 30, -deck - 14), Vector2(w + 28, -deck - 4), Vector2(-17, -deck + 10)]), col.lightened(0.18))
		draw_line(Vector2(0, -34), Vector2(w + 10, -40), Color("e8e8e0"), 4.0)
		draw_line(Vector2(4, -26), Vector2(w + 4, -30), Color("1e2a36"), 6.0)
		for q in 5:   # חלודה זולגת
			var rx := 30.0 + float(q) * w / 5.0
			draw_line(Vector2(rx, -deck + 6.0), Vector2(rx + 2.0, -deck + 40.0 + float(q % 2) * 18.0), Color(0.4, 0.2, 0.1, 0.5), 3.0)
		draw_string(ThemeDB.fallback_font, Vector2(36.0, -deck + 30.0), name_s, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.95, 0.95, 0.9, 0.85))
		# הסיפון (הקומה) + מעקה + שלג
		draw_rect(Rect2(-14.0, -deck - 4.0, w + 30.0, 6.0), WOOD_D)
		draw_rect(Rect2(-14.0, -deck - 8.0, w + 30.0, 5.0), SNOW)
		# תא ההגה (הגג = קומה שנייה)
		var cx0 := cab_x.x
		var cw := cab_x.y - cab_x.x
		draw_rect(Rect2(cx0, -cab_tier, cw, cab_tier - deck), Color("e4e0d4"))
		draw_rect(Rect2(cx0, -cab_tier, cw, 6.0), Color("2a3a4a"))
		for q in 3:
			draw_rect(Rect2(cx0 + 8.0 + float(q) * (cw - 16.0) / 3.0, -cab_tier + 16.0, (cw - 16.0) / 3.0 - 6.0, 26.0), Color("23323e"))
		draw_rect(Rect2(cx0 - 6.0, -cab_tier - 8.0, cw + 12.0, 8.0), SNOW)
		for q in int(cw / 16.0):
			var ix := cx0 + float(q) * 16.0 + 4.0
			draw_colored_polygon(PackedVector2Array([Vector2(ix, -cab_tier), Vector2(ix + 5, -cab_tier), Vector2(ix + 2.5, -cab_tier + 9 + float(q % 3) * 5)]), Color("e0f2fa"))
		# תורן + חבלים + נורה
		var mx := w * 0.3
		draw_line(Vector2(mx, -deck), Vector2(mx, -deck - 190.0), Color("3a3430"), 5.0)
		draw_line(Vector2(mx - 40.0, -deck - 150.0), Vector2(mx + 40.0, -deck - 150.0), Color("3a3430"), 3.0)
		draw_line(Vector2(mx, -deck - 190.0), Vector2(-10.0, -deck - 4.0), Color(0.2, 0.18, 0.16, 0.8), 1.2)
		draw_line(Vector2(mx, -deck - 190.0), Vector2(w + 20.0, -deck - 14.0), Color(0.2, 0.18, 0.16, 0.8), 1.2)
		for q in 6:   # כפור על החבלים
			var p := Vector2(mx, -deck - 190.0).lerp(Vector2(w + 20.0, -deck - 14.0), float(q) / 6.0)
			draw_rect(Rect2(p - Vector2(2, 1), Vector2(4, 2)), Color(1, 1, 1, 0.8))
		var on := fmod(_t + float(seed_v % 7), 2.4) < 1.6
		draw_circle(Vector2(mx, -deck - 194.0), 4.0, Color(1.0, 0.9, 0.5) if on else Color(0.4, 0.35, 0.2))
		if on:
			Kit.soft_glow(self, Vector2(mx, -deck - 194.0), 40.0, Color(1.0, 0.85, 0.45, 0.4))
		# מצופים כתומים תלויים בצד
		for q in 3:
			draw_circle(Vector2(30.0 + float(q) * 40.0, -deck + 12.0), 7.0, Color("ff7a2a"))
			draw_circle(Vector2(28.0 + float(q) * 40.0, -deck + 10.0), 2.0, Color(1, 1, 1, 0.6))


# ---- מדף קרח בקיר הקרחון (הקומה = add_floor בשלב) ----
class IceLedge extends Node2D:
	var w := 300.0
	var tier := 170.0

	func _ready() -> void:
		z_index = -1

	func _draw() -> void:
		# קיר קרח מאחור (לא מסתיר דמויות)
		var face := PackedVector2Array([Vector2(-40, 0), Vector2(-20, -tier - 120), Vector2(w * 0.4, -tier - 150), Vector2(w + 30, -tier - 110), Vector2(w + 50, 0)])
		IceArt.cliff(self, face, -40.0, w + 50.0, -tier - 150.0, int(global_position.x) % 89, Color("86bedf"))
		# המדף: קרח לבן-כחול עבה עם שלג למעלה ונטיפים
		draw_colored_polygon(PackedVector2Array([Vector2(-10, -tier), Vector2(w + 10, -tier), Vector2(w - 10, -tier + 26), Vector2(w * 0.5, -tier + 34), Vector2(20, -tier + 24)]), Color("bfe2f4"))
		draw_rect(Rect2(-12.0, -tier - 6.0, w + 24.0, 8.0), SNOW)
		for q in int(w / 20.0):
			var ix := float(q) * 20.0 + 6.0
			draw_colored_polygon(PackedVector2Array([Vector2(ix, -tier + 22), Vector2(ix + 6, -tier + 22), Vector2(ix + 3, -tier + 34 + float(q % 4) * 5)]), Color("e3f4fb"))


# ---- זירת הבוס: חזית הקרחון + מדף מסתור ----
class GlacierArena extends Node2D:
	var w := 1100.0
	var ledge := Vector2(40.0, 230.0)
	var tier := 170.0
	var _t := 0.0

	func _ready() -> void:
		z_index = -2

	func _process(delta: float) -> void:
		_t += delta
		if Engine.get_process_frames() % 10 == 0 and Art.on_screen(self, global_position + Vector2(w * 0.5, -200.0), w * 0.6):
			queue_redraw()

	func _draw() -> void:
		# קיר קרחון ענק
		var pts := PackedVector2Array([Vector2(0, 0)])
		for q in 12:
			pts.append(Vector2(float(q) * w / 11.0, -380.0 - fposmod(sin(float(q) * 12.9898 + 5.0 * 78.233) * 43758.5453, 1.0) * 80.0))
		pts.append(Vector2(w, 0))
		IceArt.cliff(self, pts, 0.0, w, -460.0, 31, Color("7fb9dc"))
		# מערת קרח: פתח כחול עמוק (משם יצא THE GLACIER)
		var cx := w * 0.62
		draw_colored_polygon(Art.ellipse(Vector2(cx, -110.0), 150.0, 120.0, 0.0, 24), Color("2c6a9a"))
		draw_colored_polygon(Art.ellipse(Vector2(cx, -90.0), 110.0, 90.0, 0.0, 20), Color("1d4c74"))
		Kit.soft_glow(self, Vector2(cx, -100.0), 120.0, Color(0.4, 0.8, 1.0, 0.25 + 0.08 * sin(_t * 1.5)))
		for q in 9:   # נטיפים בפתח
			var ix := cx - 130.0 + float(q) * 32.0
			draw_colored_polygon(PackedVector2Array([Vector2(ix - 6, -200 + absf(float(q) - 4.0) * 12.0), Vector2(ix + 6, -200 + absf(float(q) - 4.0) * 12.0), Vector2(ix, -160 + absf(float(q) - 4.0) * 10.0)]), Color("dff2fb"))
		# המדף (מקום מסתור) + קיר
		draw_colored_polygon(PackedVector2Array([Vector2(ledge.x - 10, -tier), Vector2(ledge.y + 10, -tier), Vector2(ledge.y - 10, -tier + 30), Vector2(ledge.x + 20, -tier + 26)]), Color("c4e4f4"))
		draw_rect(Rect2(ledge.x - 12.0, -tier - 6.0, ledge.y - ledge.x + 24.0, 8.0), SNOW)
		# גושי קרח ענקיים על הרצפה
		for q in 4:
			var bx := 280.0 + float(q) * 200.0
			if absf(bx - cx) < 90.0:
				continue
			draw_colored_polygon(PackedVector2Array([Vector2(bx - 30, 0), Vector2(bx - 18, -34 - float(q % 2) * 14.0), Vector2(bx + 14, -40), Vector2(bx + 30, 0)]), Color("b2d9ee"))


# ============================================================
#  מכשולים (מוצקים + מחסה)
# ============================================================
class Obstacle extends Node2D:
	var kind := "ice_block"
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
			"ice_block":   # גוש קרח שקוף עם דג (או יד...) קפוא בפנים
				draw_rect(Rect2(0, -h, w, h), Color("9fd0ea"))
				draw_rect(Rect2(0, -h, w * 0.25, h), Color("c3e5f5"))
				var fish := seed_v % 3 != 0
				if fish:
					Art.oval(self, Vector2(w * 0.5, -h * 0.5), w * 0.26, h * 0.13, Color(0.45, 0.55, 0.62, 0.8), 0.3, Art.NONE)
					draw_colored_polygon(PackedVector2Array([Vector2(w * 0.25, -h * 0.58), Vector2(w * 0.14, -h * 0.72), Vector2(w * 0.16, -h * 0.4)]), Color(0.4, 0.5, 0.58, 0.8))
				else:   # יד של מת קפואה בקרח
					draw_line(Vector2(w * 0.3, -h * 0.2), Vector2(w * 0.55, -h * 0.65), Color(0.5, 0.6, 0.55, 0.85), 5.0)
					for q in 4:
						draw_line(Vector2(w * 0.55, -h * 0.65), Vector2(w * 0.55, -h * 0.65) + Vector2.from_angle(-1.2 + float(q) * 0.35) * 9.0, Color(0.5, 0.6, 0.55, 0.85), 2.0)
				draw_rect(Rect2(0, -h, w, h), Color("5d9fc6"), false, 2.0)
				draw_line(Vector2(4, -h + 4), Vector2(w - 8, -h + 4), Color(1, 1, 1, 0.8), 2.0)
				draw_line(Vector2(w * 0.7, -h + 8), Vector2(w * 0.8, -12), Color(1, 1, 1, 0.5), 1.4)
				draw_rect(Rect2(-2.0, -h - 5.0, w + 4.0, 6.0), SNOW)
			"fish_box":   # ארגזי דגים כחולים מפלסטיק, מוערמים
				for q in 3:
					var r := Rect2(float(q % 2) * w * 0.5, -h * 0.5, w * 0.5 - 2.0, h * 0.5) if q < 2 else Rect2(w * 0.25, -h, w * 0.5 - 2.0, h * 0.5)
					draw_rect(r, Color("2a6aa8"))
					draw_rect(Rect2(r.position, Vector2(r.size.x, 4.0)), Color("4a8ac8"))
					for s in 3:
						draw_rect(Rect2(r.position + Vector2(5.0 + float(s) * r.size.x / 3.2, 8.0), Vector2(5.0, r.size.y - 12.0)), Color("1a4a7a"))
					draw_rect(Rect2(r.position + Vector2(0, -3), Vector2(r.size.x, 4.0)), SNOW)
					if q == 2:   # זנבות דגים בולטים
						for s in 3:
							draw_colored_polygon(PackedVector2Array([r.position + Vector2(8.0 + float(s) * 9.0, 0), r.position + Vector2(4.0 + float(s) * 9.0, -7), r.position + Vector2(12.0 + float(s) * 9.0, -7)]), Color("9aa8b4"))
			_:   # "net_pile" ערימת רשתות ירוקות עם מצופים כתומים וחבלים
				draw_colored_polygon(PackedVector2Array([Vector2(0, 0), Vector2(w * 0.12, -h * 0.75), Vector2(w * 0.45, -h), Vector2(w * 0.8, -h * 0.8), Vector2(w, 0)]), Color("3e6a4a"))
				for q in 8:
					var x := w * (0.1 + float(q) * 0.11)
					draw_line(Vector2(x, 0), Vector2(x + w * 0.1, -h * 0.85), Color(0.2, 0.35, 0.25, 0.8), 1.2)
					draw_line(Vector2(x, -h * 0.8), Vector2(x + w * 0.12, -4.0), Color(0.2, 0.35, 0.25, 0.8), 1.2)
				for q in 4:
					var bp := Vector2(w * (0.18 + float(q) * 0.2), -h * (0.4 + 0.3 * float(q % 2)))
					draw_circle(bp, 7.0, Color("ff7a2a"))
					draw_circle(bp + Vector2(-2, -2), 2.0, Color(1, 1, 1, 0.6))
				draw_colored_polygon(Art.ellipse(Vector2(w * 0.45, -h + 2.0), w * 0.35, 4.0, 0.0, 12), SNOW)


# ============================================================
#  מסך: שלג נושב + גוון קר
# ============================================================
class FjordFX extends Node2D:
	var vp := Vector2(1280, 720)
	var _t := 0.0

	func _process(delta: float) -> void:
		_t += delta
		if Engine.get_process_frames() % 2 == 0:
			queue_redraw()

	func _draw() -> void:
		var q := clampf(Quality.ambient(), 0.3, 1.0)
		var n := int(46.0 * q)
		for i in n:   # פתיתי שלג נושבים באלכסון
			var big := i % 5 == 0
			var sp := 40.0 + float(i % 7) * 12.0
			var x := fposmod(float(i) * 97.0 - _t * sp * 1.4 + sin(_t * 0.7 + float(i)) * 24.0, vp.x)
			var y := fposmod(float(i) * 61.0 + _t * sp, vp.y)
			draw_rect(Rect2(x, y, 3.0 if big else 2.0, 3.0 if big else 2.0), Color(1, 1, 1, 0.75 if big else 0.55))
		# משב שלג (spindrift) כל כמה שניות
		var g := fmod(_t, 11.0)
		if g < 2.4:
			var k := g / 2.4
			for s in 3:
				Kit.soft_ellipse(self, Vector2(lerpf(vp.x + 300.0, -400.0, k) + float(s) * 160.0, vp.y * 0.82 - float(s) * 20.0), 260.0, 26.0, 0.0, Color(1, 1, 1, 0.16 * sin(k * PI) * q))
		draw_rect(Rect2(0, 0, vp.x, vp.y), Color(0.6, 0.8, 1.0, 0.035))   # גוון קר
