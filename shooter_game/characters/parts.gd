extends RefCounted
const DrawBatch := preload("res://effects/draw_batch.gd")
const Art := preload("res://art.gd")
# ============================================================
#  PARTS - כל החלקים של CHARACTER MAKER: שיער, כובעים, פנים, בגדים, תוספות וחפצים ביד.
#  כל חלק מצויר בקוד באותו סגנון של הזומבים (Art / DrawBatch, קו מתאר כהה), על הגוף הרגיל של zombie.gd.
#
#  ****  איך מוסיפים חלק חדש  ****
#   1. מוסיפים את השם לרשימה (HATS / FACES / ...) ואם צריך שם יפה יותר בעורך - ל-LABELS.
#   2. מוסיפים ענף match בפונקציית הציור של הרשימה (hat / face / item ...).
#   זהו: העורך (characters/maker.gd) בונה את הכפתורים מהרשימות, והזומבים מציירים לפי השם שבקובץ הדמות.
#
#  מערכות צירים:
#   * ראש (hair_back / hair_front / hat / face): (0,0) = מרכז הראש, x קדימה (לכיוון הפנים), y למטה.
#     הראש ברדיוס 7.2 x 8.2 (zombie.gd _head). העין הזוהרת ב-(4.5, -1.8), הלסת ב-(1.5..7.5, 2..7), האוזן ב-(-2.5, 0.5).
#   * גוף (back_gear / torso_over / item): כמו zombie.gd _draw_body - (0,0) = כפות הרגליים, פונה ימינה,
#     sh = הכתפיים (~(3, -41)), hip = המותן (~(0, -24)), hand = כף היד הקדמית.
#  t = פונקציית צבע (custom_character.gd tone): לבן כשנפגע, משחיר כשנשרף.
# ============================================================

const HAIRS := ["none", "short", "long", "mohawk", "back", "afro", "ponytail"]
const HATS := ["none", "cap", "helmet", "hardhat", "beanie", "hood", "bandana", "cop", "tophat", "party", "chef", "crown", "bucket", "headphones"]
const FACES := ["none", "glasses", "sunglasses", "eyepatch", "gasmask", "surgical", "bandages", "clown"]
const TOPS := ["shirt", "tank", "overalls", "bare", "suit", "coat", "hoodie", "prison"]
const EXTRAS := ["belt", "tie", "apron", "vest", "bandolier", "scarf", "backpack", "ribs"]
const ITEMS := ["none", "axe", "pipe", "cleaver", "knife", "bat", "machete", "wrench", "shovel", "chainsaw", "teddy", "briefcase", "phone"]
const GORE := ["rot", "cheek", "flesh", "chest_stitches", "bone_arm", "head_wound", "scalp_stitches", "blood"]
const BUILDS := ["normal", "skinny", "big"]

const LABELS := {
	"back": "BACK TUFT", "hardhat": "HARD HAT", "cop": "POLICE CAP", "tophat": "TOP HAT", "party": "PARTY HAT",
	"chef": "CHEF HAT", "sunglasses": "SHADES", "eyepatch": "EYE PATCH", "gasmask": "GAS MASK", "surgical": "MASK",
	"clown": "CLOWN NOSE", "tank": "TANK TOP", "bare": "NO SHIRT", "prison": "PRISON", "ribs": "OPEN RIBS",
	"teddy": "TEDDY BEAR", "rot": "ROT + DROOL", "cheek": "TORN CHEEK", "flesh": "HANGING FLESH",
	"chest_stitches": "CHEST STITCHES", "bone_arm": "BONE IN ARM", "head_wound": "HEAD WOUND",
	"scalp_stitches": "SCALP STITCHES", "blood": "BLOOD STAINS", "bat": "NAIL BAT",
}

# כובעים שמכסים את הקודקוד (השיער למעלה לא מצויר מתחתיהם)
const COVERS := ["cap", "helmet", "hardhat", "beanie", "hood", "cop", "tophat", "chef", "bucket"]
const BONE := Color("e0d4b8")
const BLOOD := Color(0.45, 0.03, 0.03, 0.7)
const METAL := Color("a8b0b8")
const WOOD := Color("6a4426")
const DARK := Color("1a1a1e")


static func label(id: String) -> String:
	return LABELS.get(id, id.to_upper().replace("_", " "))


# איזה גוף של zombie.gd מתחת לבגד: walker (חולצה עם שרוולים), runner (גופייה), brute (אוברול), bare (בלי חולצה)
static func torso_base(top: String) -> String:
	match top:
		"tank":
			return "runner"
		"overalls":
			return "brute"
		"bare":
			return "bare"
	return "walker"


static func has_sleeves(top: String) -> bool:
	return not top in ["tank", "overalls", "bare"]


# חצי אליפסה עליונה (כיפה של כובע): משמאל, מעל הראש, ימינה
static func _dome(c: Vector2, rx: float, ry: float, n := 12) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in n + 1:
		var a := PI + PI * float(i) / float(n)
		pts.append(c + Vector2(cos(a) * rx, sin(a) * ry))
	return pts


# כמה עיגולים שמתמזגים לגוש אחד עם קו מתאר אחד מסביב (פונפון של שף, אפרו, דובי)
static func _blob(ci: CanvasItem, circles: Array, col: Color) -> void:
	for b in circles:
		DrawBatch.circle(ci, b[0], float(b[1]) + 1.0, Art.OUTLINE)
	for b in circles:
		DrawBatch.circle(ci, b[0], float(b[1]), col)


# ============================================================
#  שיער
# ============================================================
# מאחורי הראש (לפני האליפסה של הראש)
static func hair_back(ci: CanvasItem, style: String, hc: Color, t: Callable, time: float, hat: String) -> void:
	var c: Color = t.call(hc)
	if hat == "hood":   # הכובע מכסה את כל החלק האחורי
		return
	match style:
		"short", "back":
			Art.oval(ci, Vector2(-2.5, -2.5), 6.0, 5.5, c, 0.2)
		"long":
			Art.oval(ci, Vector2(-2.5, -2.5), 6.0, 5.5, c, 0.2)
			for i in 6:
				var a := Vector2(-4.0 + float(i) * 1.2, -6.5 + float(i) * 0.4)
				var flow := Vector2(-12.0 - float(i), 3.0 + float(i) * 1.6 + sin(time * 8.0 + float(i)) * 1.5)
				DrawBatch.line(ci, a, a + flow, c, 2.2, true)
		"ponytail":
			Art.oval(ci, Vector2(-2.5, -2.5), 6.0, 5.5, c, 0.2)
			var sw := sin(time * 4.0) * 1.2
			Art.limb(ci, PackedVector2Array([Vector2(-6.5, -4.0), Vector2(-10.5, 0.0 + sw * 0.5), Vector2(-11.5, 6.5 + sw)]), 3.2, c)
			Art.disc(ci, Vector2(-6.8, -3.8), 1.3, t.call(Color("6a2030")), Art.OUTLINE, 0.6)   # גומייה
		"afro":
			_blob(ci, [[Vector2(-2.0, -4.6), 9.4], [Vector2(-7.2, 0.4), 5.2], [Vector2(3.2, -9.0), 5.0]], c)
			for i in 5:   # תלתלים
				var p := Vector2(-8.0 + float(i) * 3.2, -9.0 + absf(float(i) - 2.0) * 1.6)
				DrawBatch.arc(ci, p, 1.6, 0.4, 2.8, 5, Art.shade(c, 0.35), 0.7, true)


# מעל הראש (אחרי האליפסה). covered = יש כובע שמכסה את הקודקוד
static func hair_front(ci: CanvasItem, style: String, hc: Color, t: Callable, covered: bool) -> void:
	if covered:
		return
	var c: Color = t.call(hc)
	match style:
		"short", "long", "ponytail":
			var cap := PackedVector2Array([Vector2(-6.8, -2.0), Vector2(-5.6, -5.6), Vector2(-2.0, -7.9), Vector2(2.5, -7.8),
				Vector2(5.4, -5.8), Vector2(3.0, -6.0), Vector2(1.0, -4.9), Vector2(-1.0, -6.2), Vector2(-3.0, -4.6),
				Vector2(-4.6, -5.4), Vector2(-5.8, -1.4)])
			DrawBatch.colored_polygon(ci, cap, c)
			DrawBatch.line(ci, Vector2(-4.2, -6.6), Vector2(0.5, -8.0), Color(1, 1, 1, 0.2), 1.0, true)   # ברק בשיער
		"mohawk":
			var sp := PackedVector2Array([Vector2(-6.6, -4.4), Vector2(-8.4, -9.6), Vector2(-4.6, -7.6), Vector2(-4.4, -13.2),
				Vector2(-1.4, -8.6), Vector2(0.4, -14.4), Vector2(2.0, -8.6), Vector2(4.4, -12.6), Vector2(4.6, -7.4),
				Vector2(6.6, -9.0), Vector2(5.6, -5.4), Vector2(0.0, -7.4)])
			Art.fill(ci, sp, c, Art.OUTLINE, 1.0)
			DrawBatch.line(ci, Vector2(-3.6, -8.6), Vector2(0.4, -12.6), Color(1, 1, 1, 0.22), 0.9, true)
		"afro":
			_blob(ci, [[Vector2(-4.6, -6.2), 3.0], [Vector2(-0.8, -7.8), 3.2], [Vector2(3.0, -7.0), 2.6]], c)
		"none":   # קרחת: כתם ריקבון על הקודקוד
			Art.oval(ci, Vector2(-2.0, -5.0), 2.2, 1.4, Color(0.42, 0.06, 0.05, 0.75), 0.3, Art.NONE)


# ============================================================
#  כובעים (על הראש, אחרי הפנים). eye = צבע העין הזוהרת (דלי: מציצה מהחור)
# ============================================================
static func hat(ci: CanvasItem, id: String, hc: Color, eye: Color, t: Callable, time: float, lo: bool) -> void:
	var c: Color = t.call(hc)
	match id:
		"cap":
			Art.fill_shaded(ci, _dome(Vector2(0.0, -3.2), 7.7, 6.4), c, 0.18, 0.35, Art.OUTLINE, 1.1)
			Art.fill(ci, PackedVector2Array([Vector2(4.0, -4.6), Vector2(12.8, -3.9), Vector2(12.3, -2.5), Vector2(4.0, -3.0)]), Art.shade(c, 0.3), Art.OUTLINE, 1.0)   # מצחייה
			DrawBatch.line(ci, Vector2(-0.6, -9.4), Vector2(-3.0, -3.6), Color(0, 0, 0, 0.25), 0.8, true)   # תפר
			Art.disc(ci, Vector2(-0.6, -9.6), 1.0, Art.shade(c, -0.15), Art.OUTLINE, 0.6)
		"helmet":
			Art.fill_shaded(ci, _dome(Vector2(-0.3, -2.4), 9.0, 8.4, 14), c, 0.15, 0.4, Art.OUTLINE, 1.2)
			if not lo:
				for i in 3:   # רשת הסוואה
					DrawBatch.line(ci, Vector2(-6.5 + float(i) * 4.2, -9.4 + absf(float(i) - 1.0) * 1.8), Vector2(-4.0 + float(i) * 4.6, -3.0), Color(0, 0, 0, 0.22), 0.7, true)
			Art.limb(ci, PackedVector2Array([Vector2(-9.8, -2.3), Vector2(9.6, -2.6)]), 2.0, Art.shade(c, 0.2))   # שוליים
			DrawBatch.polyline(ci, PackedVector2Array([Vector2(-1.6, -1.6), Vector2(0.8, 6.8), Vector2(5.4, 6.2)]), t.call(Color(0.1, 0.09, 0.07)), 0.9, true)   # רצועת סנטר
		"hardhat":
			Art.fill_shaded(ci, _dome(Vector2(0.0, -3.6), 7.8, 6.5), c, 0.25, 0.3, Art.OUTLINE, 1.1)
			DrawBatch.line(ci, Vector2(-0.6, -9.9), Vector2(-0.4, -4.0), Art.shade(c, -0.25), 1.8, true)   # רכס
			Art.fill(ci, PackedVector2Array([Vector2(-9.2, -4.0), Vector2(11.8, -3.7), Vector2(11.2, -2.3), Vector2(-9.0, -2.6)]), Art.shade(c, 0.15), Art.OUTLINE, 1.0)
		"beanie":
			Art.fill_shaded(ci, _dome(Vector2(-0.4, -2.6), 8.0, 8.0), c, 0.15, 0.35, Art.OUTLINE, 1.1)
			if not lo:
				for i in 4:   # פסי סריגה
					DrawBatch.line(ci, Vector2(-6.0 + float(i) * 3.8, -4.4), Vector2(-4.2 + float(i) * 2.8, -9.0 + absf(float(i) - 1.5) * 0.8), Color(0, 0, 0, 0.18), 0.7, true)
			Art.fill(ci, PackedVector2Array([Vector2(-8.6, -4.6), Vector2(7.8, -4.8), Vector2(8.0, -1.6), Vector2(-8.6, -1.4)]), Art.shade(c, 0.2), Art.OUTLINE, 1.0)   # קיפול
			Art.disc(ci, Vector2(-1.6, -11.2), 2.3, Art.shade(c, -0.25), Art.OUTLINE, 0.9)   # פונפון
		"hood":
			var hood := PackedVector2Array([Vector2(6.5, -8.8), Vector2(2.0, -11.8), Vector2(-4.5, -11.6), Vector2(-9.6, -7.5),
				Vector2(-11.4, -1.0), Vector2(-10.6, 5.5), Vector2(-7.6, 10.0), Vector2(-2.5, 11.6), Vector2(2.5, 11.0),
				Vector2(0.8, 8.2), Vector2(-2.0, 4.0), Vector2(-2.8, -1.0), Vector2(-1.2, -5.4), Vector2(2.6, -8.0)])
			Art.fill_shaded(ci, hood, c, 0.12, 0.4, Art.OUTLINE, 1.2)
			DrawBatch.polyline(ci, PackedVector2Array([Vector2(1.2, 8.6), Vector2(-1.6, 4.0), Vector2(-2.3, -1.0), Vector2(-0.8, -5.2), Vector2(3.0, -7.8)]),
				Color(0, 0, 0, 0.45), 1.6, true)   # צל בפנים
		"bandana":
			var sw := sin(time * 6.0) * 1.2
			Art.fill(ci, PackedVector2Array([Vector2(-7.2, -5.0), Vector2(-12.8, -2.2 + sw), Vector2(-12.0, -0.4 + sw), Vector2(-7.0, -3.6)]), Art.shade(c, 0.15), Art.OUTLINE, 0.9)
			Art.fill(ci, PackedVector2Array([Vector2(-7.2, -4.4), Vector2(-11.0, 1.8 + sw * 0.7), Vector2(-9.6, 2.6 + sw * 0.7), Vector2(-6.8, -3.4)]), Art.shade(c, 0.25), Art.OUTLINE, 0.9)
			Art.fill_shaded(ci, PackedVector2Array([Vector2(-7.6, -6.2), Vector2(7.0, -6.8), Vector2(7.5, -3.8), Vector2(-7.6, -3.2)]), c, 0.2, 0.3, Art.OUTLINE, 1.0)
			Art.disc(ci, Vector2(-7.4, -4.5), 1.5, Art.shade(c, 0.1), Art.OUTLINE, 0.8)   # קשר
			if not lo:
				for i in 3:
					DrawBatch.circle(ci, Vector2(-4.0 + float(i) * 4.0, -5.0 - float(i) * 0.25), 0.6, Color(1, 1, 1, 0.55))
		"cop":
			Art.fill_shaded(ci, PackedVector2Array([Vector2(-6.6, -5.0), Vector2(-6.8, -10.2), Vector2(6.4, -10.9), Vector2(6.8, -5.0)]), c, 0.15, 0.3, Art.OUTLINE, 1.0)
			Art.fill(ci, PackedVector2Array([Vector2(4.0, -5.5), Vector2(10.4, -4.5), Vector2(9.2, -3.4), Vector2(4.0, -4.0)]), t.call(Color("0e0e12")), Art.OUTLINE, 0.8)
			DrawBatch.line(ci, Vector2(-6.4, -6.4), Vector2(6.6, -6.4), t.call(Color("8090a0")), 1.2)
			Art.disc(ci, Vector2(1.6, -8.6), 1.1, t.call(Color("d8b040")), Art.OUTLINE, 0.6)   # סמל
		"tophat":
			Art.fill_shaded(ci, PackedVector2Array([Vector2(-5.6, -6.0), Vector2(6.2, -6.2), Vector2(5.6, -20.0), Vector2(-5.2, -19.8)]), c, 0.15, 0.3, Art.OUTLINE, 1.1)
			DrawBatch.colored_polygon(ci, PackedVector2Array([Vector2(-5.5, -9.2), Vector2(6.0, -9.4), Vector2(6.1, -7.2), Vector2(-5.6, -7.0)]), t.call(Color("8a1a1a")))   # סרט
			Art.fill(ci, PackedVector2Array([Vector2(-9.2, -6.6), Vector2(10.2, -6.9), Vector2(10.0, -5.0), Vector2(-9.0, -4.8)]), Art.shade(c, 0.1), Art.OUTLINE, 1.0)
		"party":
			var l0 := Vector2(-5.8, -6.6)
			var r0 := Vector2(5.6, -7.2)
			var top := Vector2(0.6, -21.0)
			Art.fill_shaded(ci, PackedVector2Array([l0, r0, top]), c, 0.25, 0.25, Art.OUTLINE, 1.0)
			for f in [0.3, 0.6]:   # פסים
				DrawBatch.line(ci, l0.lerp(top, f), r0.lerp(top, f - 0.12), t.call(Color(1, 1, 1, 0.75)), 1.3, true)
			Art.disc(ci, top + Vector2(0.0, -0.6), 2.0, t.call(Color("f0e040")), Art.OUTLINE, 0.8)
			DrawBatch.line(ci, l0 + Vector2(0.8, 0.0), Vector2(1.0, 8.4), Color(0.9, 0.9, 0.9, 0.5), 0.5, true)   # גומייה מתחת לסנטר
		"chef":
			_blob(ci, [[Vector2(-4.2, -10.6), 4.2], [Vector2(4.0, -10.8), 4.0], [Vector2(-0.2, -13.2), 4.8]], c)
			if not lo:
				DrawBatch.line(ci, Vector2(-1.8, -9.0), Vector2(-2.6, -14.0), Color(0, 0, 0, 0.15), 0.8, true)
				DrawBatch.line(ci, Vector2(2.2, -9.0), Vector2(2.8, -13.6), Color(0, 0, 0, 0.15), 0.8, true)
			Art.fill_shaded(ci, PackedVector2Array([Vector2(-6.8, -7.4), Vector2(7.0, -7.8), Vector2(7.2, -3.8), Vector2(-7.0, -3.4)]), c, 0.1, 0.2, Art.OUTLINE, 1.0)
		"crown":
			var cr := PackedVector2Array([Vector2(-6.6, -4.6), Vector2(-7.2, -12.4), Vector2(-3.8, -8.6), Vector2(-0.4, -14.0),
				Vector2(3.2, -8.8), Vector2(7.0, -12.8), Vector2(6.8, -4.8)])
			Art.fill_shaded(ci, cr, c, 0.3, 0.3, Art.OUTLINE, 1.0)
			Art.disc(ci, Vector2(0.0, -6.6), 1.2, t.call(Color("c02030")), Art.NONE)   # אבני חן
			Art.disc(ci, Vector2(-4.0, -6.4), 0.9, t.call(Color("3060c0")), Art.NONE)
			Art.disc(ci, Vector2(4.0, -6.8), 0.9, t.call(Color("30a050")), Art.NONE)
			for p in [Vector2(-7.2, -12.4), Vector2(-0.4, -14.0), Vector2(7.0, -12.8)]:
				DrawBatch.circle(ci, p, 0.9, Art.shade(c, -0.3))
		"bucket":
			Art.fill_shaded(ci, PackedVector2Array([Vector2(-8.2, 2.6), Vector2(8.8, 2.0), Vector2(7.0, -10.8), Vector2(-6.6, -10.4)]), c, 0.25, 0.35, Art.OUTLINE, 1.2)
			DrawBatch.line(ci, Vector2(-7.4, -3.5), Vector2(7.9, -4.0), Art.shade(c, 0.25), 0.9, true)
			Art.limb(ci, PackedVector2Array([Vector2(-8.6, 2.4), Vector2(9.2, 1.8)]), 1.6, Art.shade(c, -0.15))   # שוליים
			Art.oval(ci, Vector2(-3.0, -6.0), 1.8, 1.2, Color(0.45, 0.22, 0.08, 0.6), 0.3, Art.NONE)   # חלודה
			Art.oval(ci, Vector2(4.6, -1.4), 2.4, 1.6, Color("0a0606"), 0.0, Art.NONE)   # חור לעין
			Art.glow(ci, Vector2(4.6, -1.4), 3.4, Color(eye, 0.7))
			DrawBatch.circle(ci, Vector2(4.6, -1.4), 0.8, eye.lightened(0.5))
		"headphones":
			DrawBatch.polyline(ci, PackedVector2Array([Vector2(-2.6, -1.5), Vector2(-3.8, -6.6), Vector2(-1.6, -10.4), Vector2(2.6, -10.2), Vector2(5.0, -7.6)]),
				Art.OUTLINE, 3.2, true)
			DrawBatch.polyline(ci, PackedVector2Array([Vector2(-2.6, -1.5), Vector2(-3.8, -6.6), Vector2(-1.6, -10.4), Vector2(2.6, -10.2), Vector2(5.0, -7.6)]),
				Art.shade(c, -0.1), 1.6, true)
			Art.oval(ci, Vector2(-2.4, 0.6), 3.0, 3.6, c, 0.0, Art.OUTLINE, 1.0)
			Art.oval(ci, Vector2(-2.0, 0.6), 1.6, 2.2, Art.shade(c, 0.35), 0.0, Art.NONE)


# ============================================================
#  פנים (משקפיים, מסכות...). על הפנים, לפני הכובע
# ============================================================
static func face(ci: CanvasItem, id: String, eye: Color, t: Callable, lo: bool) -> void:
	match id:
		"glasses":
			var fr: Color = t.call(DARK)
			DrawBatch.arc(ci, Vector2(4.6, -1.8), 2.6, 0.0, TAU, 14, fr, 0.9, true)
			DrawBatch.arc(ci, Vector2(0.6, -1.6), 2.0, 0.0, TAU, 12, fr, 0.8, true)
			DrawBatch.line(ci, Vector2(2.0, -2.1), Vector2(2.6, -2.2), fr, 0.8, true)
			DrawBatch.line(ci, Vector2(-1.4, -1.8), Vector2(-3.6, -1.0), fr, 0.8, true)   # זרוע לאוזן
			if not lo:
				DrawBatch.line(ci, Vector2(3.4, -3.0), Vector2(4.6, -3.6), Color(1, 1, 1, 0.5), 0.6, true)
		"sunglasses":
			var lens: Color = t.call(Color("101014"))
			Art.oval(ci, Vector2(0.9, -1.7), 2.0, 1.8, lens, 0.0, Art.OUTLINE, 0.6)
			Art.oval(ci, Vector2(4.9, -1.9), 2.9, 2.1, lens, 0.0, Art.OUTLINE, 0.8)
			DrawBatch.line(ci, Vector2(2.4, -2.4), Vector2(2.9, -2.5), lens, 0.9, true)
			DrawBatch.line(ci, Vector2(-1.0, -2.0), Vector2(-3.6, -1.2), lens, 0.9, true)
			if not lo:
				DrawBatch.line(ci, Vector2(3.6, -3.0), Vector2(5.2, -3.4), Color(1, 1, 1, 0.35), 0.7, true)
		"eyepatch":
			var pc: Color = t.call(Color("121214"))
			DrawBatch.line(ci, Vector2(3.0, -3.9), Vector2(-6.8, -6.0), pc, 0.9, true)
			DrawBatch.line(ci, Vector2(6.8, -0.6), Vector2(7.6, 0.6), pc, 0.9, true)
			Art.oval(ci, Vector2(4.7, -1.9), 2.7, 2.5, pc, 0.1, Art.OUTLINE, 0.8)
		"gasmask":
			var m: Color = t.call(Color("3a3e36"))
			Art.fill_shaded(ci, PackedVector2Array([Vector2(0.6, -4.6), Vector2(6.8, -5.0), Vector2(8.6, 0.8), Vector2(9.4, 4.4),
				Vector2(6.8, 8.6), Vector2(1.2, 8.2), Vector2(-1.2, 3.2), Vector2(-0.8, -2.0)]), m, 0.15, 0.35, Art.OUTLINE, 1.0)
			DrawBatch.line(ci, Vector2(-0.8, -1.8), Vector2(-7.0, -4.0), Art.OUTLINE, 1.4, true)   # רצועות
			DrawBatch.line(ci, Vector2(-1.0, 3.8), Vector2(-6.6, 3.0), Art.OUTLINE, 1.4, true)
			for e in [[Vector2(0.9, -1.6), 1.7], [Vector2(4.7, -1.8), 2.3]]:   # משקפות (העין זוהרת מבפנים)
				Art.disc(ci, e[0], e[1], t.call(Color("22302a")), Art.OUTLINE, 0.8)
				DrawBatch.circle(ci, e[0], float(e[1]) * 0.55, Color(eye, 0.55))
			Art.disc(ci, Vector2(8.8, 5.6), 2.8, t.call(Color("5a5e54")), Art.OUTLINE, 1.0)   # פילטר
			if not lo:
				for i in 3:
					DrawBatch.line(ci, Vector2(7.4 + float(i) * 1.2, 4.0), Vector2(7.4 + float(i) * 1.2, 7.2), Color(0, 0, 0, 0.3), 0.6)
		"surgical":
			Art.fill_shaded(ci, PackedVector2Array([Vector2(1.0, 0.8), Vector2(7.6, 0.2), Vector2(8.4, 4.2), Vector2(6.6, 7.8),
				Vector2(1.6, 7.4), Vector2(0.6, 4.0)]), t.call(Color("a8c8d8")), 0.15, 0.25, Art.OUTLINE, 0.9)
			for i in 3:   # קפלים
				DrawBatch.line(ci, Vector2(1.4, 2.6 + float(i) * 1.6), Vector2(7.8, 2.0 + float(i) * 1.7), Color(0, 0, 0, 0.18), 0.6, true)
			DrawBatch.line(ci, Vector2(1.0, 1.4), Vector2(-2.4, 0.2), Color(0.9, 0.9, 0.9, 0.7), 0.5, true)
			DrawBatch.line(ci, Vector2(1.4, 6.6), Vector2(-2.2, 1.2), Color(0.9, 0.9, 0.9, 0.7), 0.5, true)
			Art.oval(ci, Vector2(5.4, 5.0), 1.3, 0.9, BLOOD, 0.0, Art.NONE)
		"bandages":
			var b: Color = t.call(Color("d8d0b8"))
			Art.limb(ci, PackedVector2Array([Vector2(-7.2, -5.4), Vector2(6.6, -6.8)]), 2.2, b)
			Art.limb(ci, PackedVector2Array([Vector2(-7.4, -0.6), Vector2(-1.6, 0.4), Vector2(2.6, -1.2)]), 2.0, b)   # על העין האחורית
			Art.limb(ci, PackedVector2Array([Vector2(-6.4, 4.0), Vector2(-1.0, 5.4)]), 1.8, b)
			Art.oval(ci, Vector2(3.0, -6.3), 1.0, 0.7, BLOOD, 0.0, Art.NONE)
		"clown":
			Art.disc(ci, Vector2(8.0, 0.2), 1.9, t.call(Color("d82020")), Art.OUTLINE, 0.8)
			DrawBatch.circle(ci, Vector2(7.5, -0.4), 0.6, Color(1, 1, 1, 0.55))


# ============================================================
#  גוף
# ============================================================
# בלי חולצה (במקום הגוף של zombie.gd): חזה חשוף, צלעות, טבור וגומי של המכנס
static func torso_bare(ci: CanvasItem, sh: Vector2, hip: Vector2, sk: Color, pa: Color) -> void:
	Art.limb(ci, PackedVector2Array([sh + Vector2(1.0, 0.0), sh + Vector2(2.0, -5.0)]), 5.0, Art.shade(sk, 0.1))   # צוואר
	var body := PackedVector2Array([sh + Vector2(-8.0, -1.0), sh + Vector2(8.0, 0.0), hip + Vector2(7.5, -2.0),
		hip + Vector2(-7.5, -1.0), sh + Vector2(-8.5, 5.0)])
	Art.fill_shaded(ci, body, Art.shade(sk, 0.05), 0.15, 0.3, Art.OUTLINE, 1.3)
	for i in 3:   # צלעות
		var y := sh.y + 6.0 + float(i) * 2.4
		DrawBatch.line(ci, Vector2(sh.x + 0.5, y), Vector2(sh.x + 6.0, y - 0.8), Art.shade(sk, 0.4), 0.9, true)
	DrawBatch.circle(ci, hip + Vector2(3.0, -6.0), 0.7, Art.shade(sk, 0.5))   # טבור
	DrawBatch.line(ci, hip + Vector2(-7.5, -1.0), hip + Vector2(7.5, -1.5), Art.shade(pa, 0.2), 2.5, true)


# תיק גב: מאחורי הגוף (לפני הגוף, אחרי היד האחורית)
static func back_gear(ci: CanvasItem, extras: PackedStringArray, sh: Vector2, gear: Color, t: Callable) -> void:
	if not extras.has("backpack"):
		return
	var g: Color = t.call(gear)
	var tl := sh + Vector2(-15.0, 0.5)
	Art.fill_shaded(ci, PackedVector2Array([tl, tl + Vector2(8.0, -1.5), tl + Vector2(9.0, 17.0), tl + Vector2(1.0, 18.5)]), g, 0.15, 0.35, Art.OUTLINE, 1.2)
	Art.fill(ci, PackedVector2Array([tl + Vector2(0.4, 0.0), tl + Vector2(8.2, -1.4), tl + Vector2(8.4, 5.6), tl + Vector2(0.6, 6.8)]), Art.shade(g, 0.15), Art.OUTLINE, 0.9)   # מכסה
	DrawBatch.rect(ci, Rect2(tl + Vector2(3.8, 4.8), Vector2(1.6, 2.2)), t.call(Color("b0a070")))   # אבזם
	Art.fill(ci, PackedVector2Array([tl + Vector2(1.6, 10.0), tl + Vector2(7.4, 9.6), tl + Vector2(7.8, 15.6), tl + Vector2(2.0, 16.4)]), Art.shade(g, 0.1), Art.OUTLINE, 0.8)   # כיס


# מעל הגוף: מה שמיוחד בבגד (מעיל, חליפה...), ואז התוספות. legless = זוחל (בלי שולי מעיל / סינר למטה)
static func torso_over(ci: CanvasItem, top: String, extras: PackedStringArray, gore: PackedStringArray, sh: Vector2, hip: Vector2,
		sk: Color, shirt_c: Color, gear: Color, t: Callable, time: float, legless: bool, hat: String, lo: bool) -> void:
	var g: Color = t.call(gear)
	var sw := sin(time * 3.0) * 0.8
	match top:
		"suit":   # חולצה לבנה, דשים ועניבה (בצבע של התוספות)
			Art.fill(ci, PackedVector2Array([sh + Vector2(-1.0, 1.0), sh + Vector2(5.0, 1.0), sh + Vector2(2.0, 12.0)]), t.call(Color(0.86, 0.83, 0.76)), Art.NONE)
			DrawBatch.polyline(ci, PackedVector2Array([sh + Vector2(-2.0, 0.5), sh + Vector2(1.5, 10.0)]), Art.shade(shirt_c, 0.35), 1.0, true)
			DrawBatch.polyline(ci, PackedVector2Array([sh + Vector2(6.0, 0.5), sh + Vector2(2.5, 10.0)]), Art.shade(shirt_c, 0.35), 1.0, true)
			_tie(ci, sh, g)
		"coat":   # שולי מעיל ארוך עד הברכיים, דשים וכפתורים
			if not legless:
				Art.fill_shaded(ci, PackedVector2Array([hip + Vector2(-8.6, -1.0), hip + Vector2(8.2, -2.0), hip + Vector2(9.6 + sw, 13.0),
					hip + Vector2(5.0, 11.6 + sw), hip + Vector2(1.0, 14.0 + sw), hip + Vector2(-3.0, 12.2), hip + Vector2(-9.6 - sw, 13.6)]),
					Art.shade(shirt_c, 0.06), 0.1, 0.4, Art.OUTLINE, 1.2)
				DrawBatch.line(ci, hip + Vector2(1.6, 0.0), hip + Vector2(1.2, 13.4 + sw), Color(0, 0, 0, 0.3), 0.9, true)
			DrawBatch.polyline(ci, PackedVector2Array([sh + Vector2(-2.0, -0.5), sh + Vector2(1.8, 8.0), hip + Vector2(2.0, -3.0)]), Art.shade(shirt_c, 0.4), 1.2, true)
			Art.fill(ci, PackedVector2Array([sh + Vector2(-4.6, -1.4), sh + Vector2(-1.0, -0.6), sh + Vector2(-3.4, 4.6)]), Art.shade(shirt_c, 0.2), Art.OUTLINE, 0.8)   # צווארון
			for i in 2:
				DrawBatch.circle(ci, sh.lerp(hip, 0.45 + float(i) * 0.3) + Vector2(3.4, 0.0), 0.8, Art.shade(shirt_c, 0.5))
		"hoodie":
			Art.fill(ci, PackedVector2Array([hip + Vector2(-4.5, -9.0), hip + Vector2(5.5, -9.4), hip + Vector2(7.0, -2.5), hip + Vector2(-5.8, -2.0)]),
				Art.shade(shirt_c, 0.12), Color(0, 0, 0, 0.5), 0.8)   # כיס קנגורו
			DrawBatch.line(ci, sh + Vector2(0.6, 1.0), sh + Vector2(0.2, 7.0), t.call(Color(0.9, 0.9, 0.86)), 0.6, true)   # שרוכים
			DrawBatch.line(ci, sh + Vector2(3.0, 1.0), sh + Vector2(3.4, 7.0), t.call(Color(0.9, 0.9, 0.86)), 0.6, true)
			if hat != "hood":   # הכובע של הקפוצ'ון מקופל מאחורי הצוואר
				Art.oval(ci, sh + Vector2(-5.0, -2.0), 5.0, 3.2, Art.shade(shirt_c, 0.1), 0.4, Art.OUTLINE, 1.0)
		"prison":   # פסים כהים, והקרע עם הצלעות נשאר מעליהם
			for i in 5:
				var f := (float(i) + 0.6) / 5.4
				var y := lerpf(sh.y + 1.0, hip.y - 1.0, f)
				var x0 := lerpf(sh.x - 8.8, hip.x - 7.8, f)
				var x1 := lerpf(sh.x + 8.4, hip.x + 7.8, f)
				DrawBatch.line(ci, Vector2(x0, y), Vector2(x1, y - 0.6), Art.shade(shirt_c, 0.5), 1.6)
			Art.fill(ci, PackedVector2Array([sh + Vector2(1.0, 7.0), sh + Vector2(6.0, 5.0), sh + Vector2(5.0, 12.0), sh + Vector2(2.0, 10.0)]), Art.shade(sk, 0.15), Art.NONE)
			DrawBatch.line(ci, sh + Vector2(2.5, 7.5), sh + Vector2(5.3, 6.6), Art.shade(sk, 0.45), 0.8, true)
			DrawBatch.line(ci, sh + Vector2(2.7, 9.3), sh + Vector2(5.2, 8.6), Art.shade(sk, 0.45), 0.8, true)
			DrawBatch.rect(ci, Rect2(sh + Vector2(-5.6, 2.6), Vector2(4.4, 2.2)), t.call(Color(0.92, 0.9, 0.85)))   # מספר אסיר
			if not lo:
				DrawBatch.line(ci, sh + Vector2(-5.0, 3.7), sh + Vector2(-1.8, 3.7), t.call(Color(0.2, 0.2, 0.2)), 0.6)
	# ---- תוספות ----
	if extras.has("ribs"):   # פצע פתוח עם צלעות
		Art.fill(ci, PackedVector2Array([sh + Vector2(-2.5, 5.0), sh + Vector2(5.5, 4.0), sh + Vector2(6.5, 12.0), hip + Vector2(4.5, -5.0), sh + Vector2(-1.0, 13.0)]),
			t.call(Color("5a0c0c")), Color(0.15, 0.0, 0.0, 0.7), 0.8)
		for i in 4:
			var y := sh.y + 6.0 + float(i) * 2.2
			DrawBatch.line(ci, Vector2(sh.x - 1.3 + float(i) * 0.3, y), Vector2(sh.x + 5.6, y - 0.8), t.call(BONE), 1.1, true)
	if extras.has("belt") and top != "overalls":
		DrawBatch.line(ci, hip + Vector2(-8.4, -1.6), hip + Vector2(8.2, -2.6), t.call(Color("2a2218")), 2.2, true)
		DrawBatch.rect(ci, Rect2(hip + Vector2(2.6, -3.9), Vector2(2.6, 2.6)), t.call(Color("b8a060")))
	if extras.has("apron"):
		var bot := hip.y + (3.0 if legless else 14.0)
		Art.fill_shaded(ci, PackedVector2Array([sh + Vector2(-0.5, 3.5), sh + Vector2(6.6, 3.0), hip + Vector2(9.0, 2.0),
			Vector2(hip.x + 9.4 + sw, bot), Vector2(hip.x - 2.4 + sw, bot + 0.4), hip + Vector2(-3.4, 2.0)]), g, 0.12, 0.3, Art.OUTLINE, 1.1)
		DrawBatch.line(ci, sh + Vector2(-0.2, 3.6), sh + Vector2(2.0, -3.4), Art.shade(g, 0.3), 1.0, true)   # רצועת צוואר
		DrawBatch.line(ci, hip + Vector2(-3.2, -2.0), hip + Vector2(-8.0, -2.6), Art.shade(g, 0.3), 1.0, true)
		Art.oval(ci, hip + Vector2(4.0, -4.0), 2.6, 1.8, BLOOD, 0.4, Art.NONE)   # דם על הסינר
		Art.oval(ci, sh + Vector2(3.4, 9.0), 1.6, 2.4, BLOOD, 0.0, Art.NONE)
	if extras.has("vest"):
		Art.fill_shaded(ci, PackedVector2Array([sh + Vector2(-8.4, 0.4), sh + Vector2(-1.2, 0.2), sh + Vector2(0.6, 7.0), sh + Vector2(5.0, 0.4),
			sh + Vector2(8.4, 1.2), hip + Vector2(8.0, -1.6), hip + Vector2(-8.0, -0.6)]), g, 0.12, 0.35, Art.OUTLINE, 1.1)
		for p in [hip + Vector2(-5.4, -8.0), hip + Vector2(1.6, -8.4)]:   # כיסים
			Art.fill(ci, PackedVector2Array([p, p + Vector2(4.4, -0.2), p + Vector2(4.4, 4.2), p + Vector2(0.0, 4.4)]), Art.shade(g, 0.15), Art.OUTLINE, 0.7)
		DrawBatch.line(ci, sh + Vector2(-8.0, 6.0), sh + Vector2(8.2, 6.4), Art.shade(g, 0.3), 1.0, true)
	if extras.has("bandolier"):
		var a := sh + Vector2(-7.4, -0.4)
		var b := hip + Vector2(7.6, -1.6)
		Art.limb(ci, PackedVector2Array([a, b]), 2.6, Art.shade(g, 0.25))
		var n := (b - a).normalized().orthogonal()
		for i in 6:   # כדורים
			var p := a.lerp(b, (float(i) + 0.6) / 6.6)
			DrawBatch.line(ci, p - n * 1.6, p + n * 1.6, t.call(Color("c8a040")), 1.1)
	if extras.has("tie") and top != "suit":
		_tie(ci, sh, g)
	if extras.has("scarf"):
		var s2 := sin(time * 5.0) * 1.2
		Art.fill(ci, PackedVector2Array([sh + Vector2(-3.0, -1.6), sh + Vector2(-12.0, 1.4 + s2), sh + Vector2(-14.0, 4.6 + s2),
			sh + Vector2(-11.4, 5.6 + s2), sh + Vector2(-2.0, 1.6)]), Art.shade(g, 0.12), Art.OUTLINE, 1.0)
		Art.fill_shaded(ci, PackedVector2Array([sh + Vector2(-3.8, -3.8), sh + Vector2(5.4, -3.2), sh + Vector2(5.8, 0.6), sh + Vector2(-3.6, 0.8)]), g, 0.2, 0.3, Art.OUTLINE, 1.0)
		Art.fill(ci, PackedVector2Array([sh + Vector2(2.8, 0.0), sh + Vector2(5.4, 0.0), sh + Vector2(5.0, 9.0), sh + Vector2(2.6, 9.4)]), Art.shade(g, 0.05), Art.OUTLINE, 0.9)
	if extras.has("backpack"):   # הרצועה מקדימה
		DrawBatch.line(ci, sh + Vector2(-4.6, -0.6), sh + Vector2(-2.6, 11.0), Art.shade(g, 0.3), 1.8, true)
	if gore.has("blood"):   # כתמי דם
		Art.oval(ci, sh + Vector2(4.0, 9.0), 3.2, 2.4, BLOOD, 0.3, Art.NONE)
		Art.oval(ci, hip + Vector2(-4.0, -5.0), 2.4, 3.0, BLOOD, 0.0, Art.NONE)
		DrawBatch.line(ci, sh + Vector2(4.6, 11.0), sh + Vector2(4.2, 15.0), BLOOD, 1.0, true)


static func _tie(ci: CanvasItem, sh: Vector2, g: Color) -> void:
	Art.fill(ci, PackedVector2Array([sh + Vector2(1.4, 2.6), sh + Vector2(3.0, 2.6), sh + Vector2(2.6, 13.6), sh + Vector2(1.4, 15.4), sh + Vector2(0.4, 13.4)]), g, Art.OUTLINE, 0.7)
	Art.disc(ci, sh + Vector2(2.2, 2.0), 1.3, Art.shade(g, 0.15), Art.OUTLINE, 0.6)


# ============================================================
#  חפץ ביד הקדמית (רק מראה - הזומבי עדיין נושך). hand = כף היד, d = כיוון הזרוע (מהכתף ליד)
# ============================================================
static func item(ci: CanvasItem, id: String, hand: Vector2, d: Vector2, t: Callable, time: float, lo: bool) -> void:
	if id == "none":
		return
	# ציר החפץ: נטוי קצת קדימה לפי הזרוע. P(x, y): y = לאורך הידית (למעלה), x = קדימה
	var u := (Vector2(0.0, -1.0) * 0.8 + d * 0.35).normalized()
	var s := u.rotated(PI / 2.0)
	var P := func(x: float, y: float) -> Vector2: return hand + s * x + u * y
	var metal: Color = t.call(METAL)
	var wood: Color = t.call(WOOD)
	var dark: Color = t.call(Color("242024"))
	match id:
		"axe":
			Art.limb(ci, PackedVector2Array([P.call(0, -5), P.call(0, 13)]), 2.0, wood)
			DrawBatch.line(ci, P.call(-1, 12), P.call(-4.4, 12.8), metal, 1.6, true)
			Art.fill_shaded(ci, PackedVector2Array([P.call(-1, 13.6), P.call(8, 15.4), P.call(7.4, 9.4), P.call(-1, 10.4)]), metal, 0.25, 0.3, Art.OUTLINE, 1.0)
			DrawBatch.line(ci, P.call(7.8, 15.0), P.call(7.2, 9.8), BLOOD, 1.2, true)
		"pipe":
			Art.limb(ci, PackedVector2Array([P.call(0, -6), P.call(0, 14)]), 2.6, t.call(Color("7a7e84")))
			Art.limb(ci, PackedVector2Array([P.call(0, 12.4), P.call(0, 14.8)]), 3.8, t.call(Color("5a5e64")))
			if not lo:
				Art.oval(ci, P.call(0.2, 6), 1.0, 0.8, Color(0.5, 0.26, 0.1, 0.7), 0.0, Art.NONE)
		"cleaver":
			Art.limb(ci, PackedVector2Array([P.call(0, -4), P.call(0, 3)]), 2.0, dark)
			Art.fill_shaded(ci, PackedVector2Array([P.call(-1, 3), P.call(6.8, 3.2), P.call(7.2, 13.6), P.call(-0.8, 13.2)]), metal, 0.25, 0.3, Art.OUTLINE, 1.0)
			DrawBatch.circle(ci, P.call(1.4, 11.4), 0.9, Art.OUTLINE)
			DrawBatch.line(ci, P.call(7.0, 3.8), P.call(7.3, 13.0), t.call(Color(0.92, 0.94, 0.96)), 0.7)
			Art.oval(ci, P.call(4.4, 7.0), 1.8, 1.2, BLOOD, 0.0, Art.NONE)
		"knife":
			Art.limb(ci, PackedVector2Array([P.call(0, -3), P.call(0, 2.5)]), 1.8, dark)
			Art.fill(ci, PackedVector2Array([P.call(-0.8, 2.5), P.call(1.6, 2.5), P.call(0.2, 11.5)]), metal, Art.OUTLINE, 0.8)
		"bat":
			Art.fill_shaded(ci, PackedVector2Array([P.call(-0.8, -5), P.call(0.8, -5), P.call(2.0, 15), P.call(-2.0, 15)]), t.call(Color("b08a5a")), 0.2, 0.3, Art.OUTLINE, 1.0)
			Art.disc(ci, P.call(0, 15), 2.0, t.call(Color("b08a5a")), Art.OUTLINE, 1.0)
			for n in [[-2.0, 12.0, -4.2, 12.8], [2.0, 10.0, 4.4, 10.4], [-1.8, 7.6, -4.0, 7.8]]:   # מסמרים
				DrawBatch.line(ci, P.call(n[0], n[1]), P.call(n[2], n[3]), t.call(Color("8a8e94")), 0.8, true)
			Art.oval(ci, P.call(0.6, 13.0), 1.4, 1.0, BLOOD, 0.0, Art.NONE)
		"machete":
			Art.limb(ci, PackedVector2Array([P.call(0, -4), P.call(0, 2)]), 2.0, dark)
			Art.fill_shaded(ci, PackedVector2Array([P.call(-1, 2), P.call(2.2, 2), P.call(4.0, 16), P.call(2.6, 19), P.call(-0.6, 15)]), metal, 0.25, 0.3, Art.OUTLINE, 1.0)
			DrawBatch.line(ci, P.call(2.6, 3.0), P.call(4.0, 15.6), t.call(Color(0.92, 0.94, 0.96)), 0.6)
		"wrench":
			Art.limb(ci, PackedVector2Array([P.call(0, -4), P.call(0, 10)]), 2.2, metal)
			Art.fill(ci, PackedVector2Array([P.call(-2.6, 10), P.call(2.6, 10), P.call(3.4, 14), P.call(1.2, 15.6), P.call(1.2, 12.6),
				P.call(-1.2, 12.6), P.call(-1.2, 15.6), P.call(-3.4, 14)]), metal, Art.OUTLINE, 1.0)
		"shovel":
			Art.limb(ci, PackedVector2Array([P.call(0, -9), P.call(0, 14)]), 1.8, wood)
			DrawBatch.line(ci, P.call(-2.2, -9), P.call(2.2, -9), wood, 1.8, true)
			Art.fill_shaded(ci, PackedVector2Array([P.call(-3.2, 14), P.call(3.2, 14), P.call(2.8, 21), P.call(0, 23), P.call(-2.8, 21)]), metal, 0.2, 0.35, Art.OUTLINE, 1.0)
			Art.oval(ci, P.call(0.4, 20.0), 1.6, 1.0, t.call(Color(0.3, 0.22, 0.14, 0.8)), 0.0, Art.NONE)   # בוץ
		"chainsaw":   # מכוון קדימה לאורך הזרוע
			var f := d
			var up := d.orthogonal() * -1.0 if d.orthogonal().y > 0.0 else d.orthogonal()
			var Q := func(x: float, y: float) -> Vector2: return hand + f * x + up * y
			Art.limb(ci, PackedVector2Array([Q.call(5, 0), Q.call(19, 0)]), 3.0, metal)   # להב
			if not lo:
				for i in 6:   # שיני השרשרת
					DrawBatch.circle(ci, Q.call(6.0 + float(i) * 2.4, 1.7 + sin(time * 40.0 + float(i)) * 0.3), 0.5, dark)
			Art.fill_shaded(ci, PackedVector2Array([Q.call(-4, -3), Q.call(5.5, -3), Q.call(5.5, 3.5), Q.call(-4, 3.5)]), t.call(Color("d86a20")), 0.2, 0.35, Art.OUTLINE, 1.0)
			DrawBatch.polyline(ci, PackedVector2Array([Q.call(-2, 3.5), Q.call(-0.5, 6.5), Q.call(4, 6.5), Q.call(5.2, 3.5)]), dark, 1.4, true)   # ידית
		"teddy":   # תלוי מהיד, מטה (כוח משיכה)
			var bc: Color = t.call(Color("8a5a30"))
			var h0 := hand + Vector2(1.0, 4.0)
			_blob(ci, [[h0 + Vector2(-2.2, -2.0), 1.4], [h0 + Vector2(2.2, -2.0), 1.4], [h0, 2.8], [h0 + Vector2(0.4, 5.6), 3.6],
				[h0 + Vector2(-2.6, 8.6), 1.5], [h0 + Vector2(3.0, 8.8), 1.5]], bc)
			Art.disc(ci, h0 + Vector2(0.6, 6.0), 1.8, Art.shade(bc, -0.25), Art.NONE)   # בטן
			DrawBatch.circle(ci, h0 + Vector2(1.2, 0.8), 1.1, Art.shade(bc, -0.3))   # חוטם
			DrawBatch.circle(ci, h0 + Vector2(-0.8, -0.6), 0.5, Art.OUTLINE)
			DrawBatch.circle(ci, h0 + Vector2(1.8, -0.8), 0.5, Art.OUTLINE)
		"briefcase":
			var b0 := hand + Vector2(0.0, 2.0)
			DrawBatch.arc(ci, hand + Vector2(0.0, 1.0), 1.8, PI, TAU, 6, dark, 1.0, true)
			Art.fill_shaded(ci, PackedVector2Array([b0 + Vector2(-5.0, 0.5), b0 + Vector2(5.0, 0.5), b0 + Vector2(5.0, 8.5), b0 + Vector2(-5.0, 8.5)]), t.call(Color("5a3a22")), 0.15, 0.35, Art.OUTLINE, 1.0)
			DrawBatch.rect(ci, Rect2(b0 + Vector2(-0.8, 1.0), Vector2(1.6, 1.4)), t.call(Color("c8a850")))
		"phone":
			Art.fill(ci, PackedVector2Array([P.call(-1.3, -0.5), P.call(1.3, -0.5), P.call(1.3, 4.8), P.call(-1.3, 4.8)]), dark, Art.OUTLINE, 0.6)
			DrawBatch.colored_polygon(ci, PackedVector2Array([P.call(-0.8, 0.2), P.call(0.8, 0.2), P.call(0.8, 4.0), P.call(-0.8, 4.0)]), t.call(Color("9ad0f0")))
			Art.glow(ci, P.call(0, 2.2), 4.0, Color(0.6, 0.85, 1.0, 0.35))
