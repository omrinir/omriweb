extends RefCounted
# ============================================================
#  TEX LOAD - טוען תמונה בזמן ריצה (במקום preload).
#  אם העורך עוד לא ייבא את ה-PNG (למשל אחרי שהחליפו קבצים) - קורא את הקובץ ישירות,
#  כך שהסקריפט לא נשבר ("Could not preload resource file"). כל תמונה נטענת פעם אחת (מטמון).
# ============================================================

static var _cache := {}


static func get_tex(path: String) -> Texture2D:
	if _cache.has(path):
		return _cache[path]
	var t: Texture2D = null
	if ResourceLoader.exists(path):
		t = load(path) as Texture2D
	if t == null:
		var img := Image.load_from_file(path)
		if img == null or img.is_empty():
			push_error("Image missing: " + path + " - copy it into the game folder")
			img = Image.create(8, 8, false, Image.FORMAT_RGBA8)
		t = ImageTexture.create_from_image(img)
	_cache[path] = t
	return t
