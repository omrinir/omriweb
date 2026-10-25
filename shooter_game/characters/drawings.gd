extends RefCounted
const DrawBatch := preload("res://effects/draw_batch.gd")
const Preset := preload("res://characters/character_preset.gd")
# ============================================================
#  DRAWINGS - "הציור שלך" ב-CHARACTER MAKER (לשונית DRAW): תמונה (ציור על נייר, בצייר, מה שרוצים) שיושבת על חלק
#  של הדמות - כובע, פנים, שיער, גוף, תוספת או ביד - כמו שהיא, עד ש-Claude מצייר אותה כחלק אמיתי ב-characters/parts.gd.
#  preset.drawings = [{"slot", "name", "file", "original", "x", "y", "size", "rot", "flip", "behind", "cut", "look", "warp"}]
#    slot = החלק (SLOTS). name = מה זה ("VIKING HELMET")
#    file = התמונה שהזומבי לובש: res://characters/drawings/<שם>.res (Image מוקטנת, הרקע נחתך, חתוכה צמוד לציור,
#           עם mipmaps). קובץ .res ולא .png: נטען מיד, בלי הייבוא של העורך, וגם במשחק המיוצא
#    original = הקובץ בדיוק כמו שהועלה: characters/drawings/originals/ (עם .gdignore: Godot לא מייבא, לא נכנס למשחק המיוצא)
#    x / y = איפה (פיקסלים של הדמות, ביחס לעוגן של החלק - START), size = הגובה שלו, rot = סיבוב במעלות,
#    flip = הפוך, behind = מאחורי הראש / הגוף, cut = לחתוך את הרקע (ציור על דף לבן)
#    look = מסובב כמו ראש עגול (מעלות, + = מסתכל קדימה - אל השחקן שהוא הולך אליו). ראש שצויר מסתכל אליך -> מסתכל הצידה.
#           כל שורה של הציור מסתובבת בתוך הרוחב של הציור באותה שורה (ראש עגול נשאר עגול): הפנים זזות קדימה ונדחסות,
#           הצד האחורי נמתח
#    warp = 9 נקודות (3x3: פינות, אמצעי הצלעות, מרכז) שגוררים כדי לכופף: 18 מספרים, ההזזה של כל נקודה (x, y) ביחידות
#           של גובה הציור, שורה אחרי שורה. ריק = ישר. הציור עובר בדיוק דרך הנקודות (אינטרפולציה ריבועית)
#  ****  Claude: "make my drawings"  ****
#   קוראים את characters/saved/*.tres ואת התמונות ב-characters/drawings/originals/, מציירים כל ציור כחלק חדש
#   ב-parts.gd באותו מקום ובאותו גודל (אותן מערכות צירים, ראו למטה), שמים אותו בדמות (FIELD) ומוחקים את הציור מ-drawings.
#   קבצים שאף דמות לא משתמשת בהם נמחקים לבד (clean) כשהעורך נפתח / שומרים / יוצאים.
# ============================================================

const DIR := "res://characters/drawings/"
const ORIG := "res://characters/drawings/originals/"
const SAVED := "res://characters/saved/"   # (= custom_characters.gd DIR)
const MAX_PX := 256               # התמונה שהזומבי לובש: לכל היותר 256 פיקסלים (על המסך הוא קטן בהרבה)
const SLOTS := ["hat", "face", "hair", "body", "extra", "hand"]
const LABELS := {"hat": "HAT", "face": "FACE", "hair": "HAIR", "body": "BODY", "extra": "EXTRA", "hand": "IN HAND"}
const FIELD := {"hat": "hat", "face": "face", "hair": "hair", "body": "top", "extra": "extras", "hand": "item"}   # השדה שהחלק האמיתי יחליף
const HEAD_SLOTS := ["hat", "face", "hair"]
const BODY_SLOTS := ["body", "extra"]
# העוגן והמקום ההתחלתי. ראש: (0,0) = מרכז הראש (גובה ~16, הפנים לכיוון +x). גוף: (0,0) = אמצע הגוף בין הכתפיים
# לאגן, נוטה איתו (הכתפיים ב-y -8, האגן ב-y +8). יד: (0,0) = כף היד הקדמית, x = לאורך הזרוע.
const START := {
	"hat": {"x": 0.0, "y": -8.0, "size": 12.0},
	"face": {"x": 3.0, "y": 0.5, "size": 9.0},
	"hair": {"x": -1.0, "y": -3.0, "size": 16.0},
	"body": {"x": 0.0, "y": 0.0, "size": 24.0},
	"extra": {"x": 1.0, "y": 2.0, "size": 16.0},
	"hand": {"x": 5.0, "y": 0.0, "size": 18.0},
}
const EXTS := ["png", "jpg", "jpeg", "webp", "bmp", "svg", "tga"]
# חיתוך הרקע (0-255): צבע עד BG_TOL מהרקע נחתך. בצילום של דף הנייר מתכהה לאט מצד לצד: פיקסל ששונה
# מהשכן שכבר נחתך בפחות מ-STEP נחתך גם הוא, כל עוד הוא לא רחוק מהרקע יותר מ-DRIFT
const BG_TOL := 40
const STEP := 12
const DRIFT := 110

static var _tex := {}             # קובץ -> טקסטורה
# ציור כפוף (look / warp): רשת משולשים במקום מלבן
const COLS := 20
const ROWS := 16
static var _mesh := {}            # (קובץ, look, flip, warp, w, h) -> [נקודות, uv]
static var _idx := PackedInt32Array()
static var _spans := {}           # קובץ -> לכל שורה של הרשת: איפה הציור מתחיל ונגמר (u, לפי השקיפות)
const LOOK_STRETCH := 2.0         # LOOK: כמה הצד האחורי נמתח לכל היותר


static func texture(file: String) -> Texture2D:
	if file == "":
		return null
	if not _tex.has(file):
		var img = load(file) if ResourceLoader.exists(file) else null
		_tex[file] = ImageTexture.create_from_image(img) if img is Image and not img.is_empty() else null
	return _tex[file]


static func is_picture(path: String) -> bool:
	return EXTS.has(path.get_extension().to_lower())


# "viking-helmet_2.png" -> "VIKING HELMET 2"
static func nice_name(path: String) -> String:
	var s := path.get_file().get_basename().replace("_", " ").replace("-", " ").strip_edges().to_upper()
	return s.substr(0, 28) if s != "" else "MY DRAWING"


# תמונה מהמחשב -> שני קבצים בתיקיית המשחק. מחזיר {"file", "original"} או {"error"}
static func import_picture(src: String) -> Dictionary:
	var img := Image.load_from_file(src)
	if img == null or img.is_empty():
		return {"error": "COULD NOT OPEN THAT PICTURE"}
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(ORIG))
	var ign := ProjectSettings.globalize_path(ORIG + ".gdignore")
	if not FileAccess.file_exists(ign):
		var fa := FileAccess.open(ign, FileAccess.WRITE)
		if fa != null:
			fa.close()
	var ext := src.get_extension().to_lower()
	var base := Preset.make_id(src.get_file().get_basename())
	var orig := ORIG + base + "." + ext
	var n := 2
	while FileAccess.file_exists(orig):
		orig = "%s%s_%d.%s" % [ORIG, base, n, ext]
		n += 1
	var err := DirAccess.copy_absolute(src, ProjectSettings.globalize_path(orig))
	if err != OK:
		return {"error": "COULD NOT COPY IT (%s)" % error_string(err)}
	var file := _save(prepare(img, true), orig.get_file().get_basename())
	if file == "":
		return {"error": "COULD NOT SAVE IT"}
	return {"file": file, "original": orig}


# CUT OUT BACKGROUND הודלק / כובה: בונים שוב את התמונה מהמקור, לקובץ חדש (דמות אחרת אולי משתמשת בישן)
static func remake(d: Dictionary) -> bool:
	var orig := str(d.get("original", ""))
	var img := Image.load_from_file(ProjectSettings.globalize_path(orig))
	if img == null or img.is_empty():
		return false
	var file := _save(prepare(img, bool(d.get("cut", true))), orig.get_file().get_basename())
	if file == "":
		return false
	d.file = file
	return true


static func _save(img: Image, base: String) -> String:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(DIR))
	var file := DIR + base + ".res"
	var n := 2
	while FileAccess.file_exists(file):
		file = "%s%s_%d.res" % [DIR, base, n]
		n += 1
	img.generate_mipmaps()   # קטן על המסך: בלי ריצוד (custom_character.gd: LINEAR_WITH_MIPMAPS)
	if ResourceSaver.save(img, file, ResourceSaver.FLAG_COMPRESS) != OK:
		return ""
	_tex[file] = ImageTexture.create_from_image(img)
	return file


# מוקטנת, הרקע נחתך (אם אין לה שקיפות משלה), וחתוכה צמוד לציור (כך ש-size = הגובה של הציור עצמו)
static func prepare(src: Image, cut: bool) -> Image:
	var img := src.duplicate() as Image
	if img.is_compressed():
		img.decompress()
	img.clear_mipmaps()
	img.convert(Image.FORMAT_RGBA8)
	var k := float(MAX_PX) / float(maxi(img.get_width(), img.get_height()))
	if k < 1.0:
		img.resize(maxi(1, int(round(img.get_width() * k))), maxi(1, int(round(img.get_height() * k))), Image.INTERPOLATE_LANCZOS)
	if cut and img.detect_alpha() == Image.ALPHA_NONE:
		var whole := img.duplicate() as Image
		_cut_background(img)
		if img.get_used_rect().size.x <= 0:   # נחתך הכל (דף ריק?): נשארת כמו שהיא
			img = whole
	var r := img.get_used_rect()
	if r.size.x > 0 and r.size.y > 0 and r.size != img.get_size():
		img = img.get_region(r)
	return img


# הרקע = הצבע של רוב הפינות. מוחקים אותו מהשוליים פנימה (מילוי), כך שלבן בתוך הציור (עיניים, שיניים) נשאר
static func _cut_background(img: Image) -> void:
	var w := img.get_width()
	var h := img.get_height()
	var px := img.get_data()
	var corners := [0, (w - 1) * 4, (h - 1) * w * 4, ((h - 1) * w + w - 1) * 4]
	var bg := -1
	var best := 1
	for c in corners:
		var same := 0
		for o in corners:
			if _dist(px, c, px[o], px[o + 1], px[o + 2]) <= BG_TOL:
				same += 1
		if same > best:
			best = same
			bg = c
	if bg < 0:   # כל פינה בצבע אחר: אין רקע אחיד, לא נוגעים
		return
	var br := px[bg]
	var bgg := px[bg + 1]
	var bb := px[bg + 2]
	var done := PackedByteArray()
	done.resize(w * h)
	var stack := PackedInt32Array()   # זוגות: פיקסל, והשכן שלו שכבר נחתך (-1 = השוליים)
	for x in w:
		stack.append_array([x, -1, (h - 1) * w + x, -1])
	for y in h:
		stack.append_array([y * w, -1, y * w + w - 1, -1])
	while not stack.is_empty():
		var n := stack.size()
		var i := stack[n - 2]
		var from := stack[n - 1]
		stack.resize(n - 2)
		if done[i] != 0:
			continue
		var o := i * 4
		var dd := _dist(px, o, br, bgg, bb)
		var dn := dd if from < 0 else _dist(px, o, px[from * 4], px[from * 4 + 1], px[from * 4 + 2])
		if dd > BG_TOL and (from < 0 or dd > DRIFT or dn > STEP):
			# קצה רך: חצי שקוף, ולא ממשיכים ממנו
			var a := int(255.0 * clampf(float(mini(dd, dn + BG_TOL - STEP) - BG_TOL) / float(BG_TOL), 0.0, 1.0))
			px[o + 3] = mini(px[o + 3], a)
			continue
		done[i] = 1
		px[o + 3] = 0
		var x := i % w
		if x > 0:
			stack.append_array([i - 1, i])
		if x < w - 1:
			stack.append_array([i + 1, i])
		if i >= w:
			stack.append_array([i - w, i])
		if i < (h - 1) * w:
			stack.append_array([i + w, i])
	img.set_data(w, h, false, Image.FORMAT_RGBA8, px)


static func _dist(px: PackedByteArray, o: int, r: int, g: int, b: int) -> int:
	return maxi(absi(px[o] - r), maxi(absi(px[o + 1] - g), absi(px[o + 2] - b)))


# מוחקים תמונות שאף דמות לא משתמשת בהן (הוסרו, או דמות שלא נשמרה). presets = כל מי שעדיין צריך אותן.
# כל שם שמופיע בקובץ שמור כלשהו נשאר (גם אם הקובץ לא נטען - לא מוחקים ציור של דמות שבורה)
static func clean(presets: Array) -> void:
	var used := {}
	for p in presets:
		if p == null:
			continue
		for d in p.drawings:
			if d is Dictionary:
				used[str(d.get("file", ""))] = true
				used[str(d.get("original", ""))] = true
	var saved := ""
	var sd := DirAccess.open(SAVED)
	if sd != null:
		for f in sd.get_files():
			if f.ends_with(".tres"):
				saved += FileAccess.get_file_as_string(SAVED + f)
	for dir in [DIR, ORIG]:
		var da := DirAccess.open(dir)
		if da == null:
			continue
		for f in da.get_files():
			if f.begins_with("."):
				continue
			var path: String = dir + f
			var gone: bool = not FileAccess.file_exists(path.trim_suffix(".import")) if f.ends_with(".import") else not (used.has(path) or saved.contains(path))
			if gone:
				DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
				_tex.erase(path)
				_spans.erase(path)


# הגודל של ציור על הדמות (רוחב, גובה) בפיקסלים של הדמות
static func pic_size(d: Dictionary) -> Vector2:
	var tex := texture(str(d.get("file", "")))
	var h := maxf(1.0, float(d.get("size", 12.0)))
	if tex == null:
		return Vector2(h, h)
	return Vector2(h * float(tex.get_width()) / maxf(1.0, float(tex.get_height())), h)


# לכל שורה של הרשת (ROWS + 1): [תחילת הציור, סוף הציור] ב-u, מפס של שורות סביבה
static func _row_spans(file: String) -> PackedVector2Array:
	if _spans.has(file):
		return _spans[file]
	var out := PackedVector2Array()
	var img = load(file) if ResourceLoader.exists(file) else null
	if img is Image and not img.is_empty():
		var im: Image = img
		if im.has_mipmaps():
			im = im.duplicate()
			im.clear_mipmaps()
		var w := im.get_width()
		var h := im.get_height()
		var band := maxi(1, int(ceil(float(h) / ROWS)))
		for r in ROWS + 1:
			var y0 := clampi(int(round(float(r) / ROWS * (h - 1))) - band / 2, 0, h - 1)
			var u := im.get_region(Rect2i(0, y0, w, mini(band, h - y0))).get_used_rect()
			if u.size.x <= 1:
				out.append(Vector2(0.5, 0.5))   # (שורה ריקה: לא מסובבים)
			else:
				out.append(Vector2(float(u.position.x) / maxf(1.0, w - 1.0), float(u.end.x - 1) / maxf(1.0, w - 1.0)))
	else:
		for r in ROWS + 1:
			out.append(Vector2(0.0, 1.0))
	_spans[file] = out
	return out


# LOOK בשורה אחת: u בתוך [a, b] מסתובב על גליל (הקצוות נשארים). הצד שאליו מסתכלים נדחס, הצד האחורי נמתח -
# לכל היותר פי LOOK_STRETCH (גליל אמיתי מותח את הקצה בלי סוף: הקו השחור בקצה של הציור היה נהיה פס עבה)
static func _turn_u(u: float, a: float, b: float, th: float) -> float:
	if b - a < 0.02 or u <= a or u >= b:
		return u
	return a + (_turn_x((u - a) / (b - a) * 2.0 - 1.0, th) + 1.0) * 0.5 * (b - a)


static func _turn_x(x: float, th: float) -> float:
	if th < 0.0:
		return -_turn_x(-x, -th)
	var lo := -cos(th)
	var k := 2.0 / (1.0 - lo)                        # הגליל: (sin(asin(x) + th) - lo) * k - 1, מ-1- עד 1
	var pk := atan((cos(th) - LOOK_STRETCH / k) / sin(th))   # מכאן ואחורה המתיחה הייתה עולה על LOOK_STRETCH: ישר
	var xk := sin(pk)
	var fk := (sin(pk + th) - lo) * k - 1.0
	var g0 := fk - LOOK_STRETCH * (1.0 + xk)         # לאן מגיע הקצה האחורי
	var g := fk + LOOK_STRETCH * (x - xk)
	if x > xk:
		g = (sin(minf(asin(clampf(x, -1.0, 1.0)) + th, PI / 2.0)) - lo) * k - 1.0
	return (g - g0) / (1.0 - g0) * 2.0 - 1.0


static func bent(d: Dictionary) -> bool:
	return absf(float(d.get("look", 0.0))) > 0.01 or (d.get("warp", []) as Array).size() == 18


# נקודה בציור (u, v מ-0 עד 1: שמאל-למעלה עד ימין-למטה) אחרי LOOK ו-WARP, בפיקסלים של הדמות סביב מרכז הציור
# (לפני ההזזה, הסיבוב וההיפוך). LOOK: כל שורה מסתובבת בתוך הרוחב של הציור באותה שורה (_row_spans), כמו ראש עגול
static func bend_point(d: Dictionary, w: float, h: float, u: float, v: float) -> Vector2:
	var th := deg_to_rad(float(d.get("look", 0.0))) * (-1.0 if bool(d.get("flip", false)) else 1.0)   # (הפוך: קדימה נשאר קדימה)
	if absf(th) > 0.0001:
		var sp := _row_spans(str(d.get("file", "")))
		var fr := clampf(v, 0.0, 1.0) * ROWS
		var r := mini(int(fr), ROWS - 1)
		var ab := sp[r].lerp(sp[r + 1], fr - r)
		u = _turn_u(u, ab.x, ab.y, th)
	var p := Vector2((2.0 * u - 1.0) * w * 0.5, (v - 0.5) * h)
	var wp: Array = d.get("warp", [])
	if wp.size() == 18:
		var lu := [2.0 * u * u - 3.0 * u + 1.0, 4.0 * u - 4.0 * u * u, 2.0 * u * u - u]
		var lv := [2.0 * v * v - 3.0 * v + 1.0, 4.0 * v - 4.0 * v * v, 2.0 * v * v - v]
		for j in 3:
			for i in 3:
				var k: float = lu[i] * lv[j]
				p += Vector2(float(wp[(j * 3 + i) * 2]), float(wp[(j * 3 + i) * 2 + 1])) * (h * k)
	return p


static func _bent_mesh(d: Dictionary, w: float, h: float) -> Array:
	var key := hash([str(d.get("file", "")), float(d.get("look", 0.0)), bool(d.get("flip", false)), d.get("warp", []), w, h])
	if _mesh.has(key):
		return _mesh[key]
	if _mesh.size() > 64:
		_mesh.clear()
	var pts := PackedVector2Array()
	var uvs := PackedVector2Array()
	for r in ROWS + 1:
		for c in COLS + 1:
			var u := float(c) / COLS
			var v := float(r) / ROWS
			pts.append(bend_point(d, w, h, u, v))
			uvs.append(Vector2(u, v))
	if _idx.is_empty():
		for r in ROWS:
			for c in COLS:
				var a := r * (COLS + 1) + c
				_idx.append_array([a, a + 1, a + COLS + 2, a, a + COLS + 2, a + COLS + 1])
	var m := [pts, uvs]
	_mesh[key] = m
	return m


# ציור אחד. at = העוגן של החלק, ang = הזווית שלו (גוף: הנטייה, יד: כיוון הזרוע). mod = צבע (נפגע / נשרף).
# מחזיר את הטרנספורם שלו (העורך: הנקודות של WARP על המסך)
static func draw(ci: CanvasItem, d: Dictionary, at: Vector2, ang: float, mod: Color) -> Transform2D:
	var base := DrawBatch.current_transform(ci)
	var off := Vector2(float(d.get("x", 0.0)), float(d.get("y", 0.0))).rotated(ang)
	var flip := -1.0 if bool(d.get("flip", false)) else 1.0
	var xf := base * Transform2D(ang + deg_to_rad(float(d.get("rot", 0.0))), Vector2(flip, 1.0), 0.0, at + off)
	var tex := texture(str(d.get("file", "")))
	if tex == null:
		return xf
	var s := pic_size(d)
	DrawBatch.set_transform_matrix(ci, xf)
	if bent(d):
		var m := _bent_mesh(d, s.x, s.y)
		DrawBatch.textured_tris(ci, tex, m[0], m[1], _idx, mod)
	else:
		DrawBatch.texture_rect(ci, tex, Rect2(-s.x / 2.0, -s.y / 2.0, s.x, s.y), false, mod)
	DrawBatch.set_transform_matrix(ci, base)
	return xf


# כל הציורים של החלקים האלה, מאחור (behind) או מלפנים. ביד: כולם (behind לא משנה). rec: מספר הציור -> הטרנספורם שלו
static func draw_slots(ci: CanvasItem, p: Resource, slots: Array, behind: bool, at: Vector2, ang: float, mod: Color, rec = null) -> void:
	var arr: Array = p.drawings
	for i in arr.size():
		var d = arr[i]
		if d is Dictionary and slots.has(str(d.get("slot", ""))) and (bool(d.get("behind", false)) == behind or str(d.slot) == "hand"):
			var xf := draw(ci, d, at, ang, mod)
			if rec != null:
				rec[i] = xf
