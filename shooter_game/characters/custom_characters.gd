extends RefCounted
const Preset := preload("res://characters/character_preset.gd")
const Custom := preload("res://characters/custom_character.gd")
# ============================================================
#  CUSTOM CHARACTERS - כל הדמויות שנשמרו ב-CHARACTER MAKER (characters/saved/*.tres).
#  כל דמות = סוג זומבי עם מספר (kind) מ-1000. enemies/zombie_registry.gd שולח לכאן כל kind >= FIRST.
#  איפה הן מופיעות: levels = רשימת שלבים, share = אחוז מהזומבים בשלבים האלה (main.gd -> add_weights).
#  להוסיף דמות לשלב בקוד: לפתוח את הקובץ שלה ב-characters/saved/ ולשנות levels / share.
# ============================================================

const FIRST := 1000
const DIR := "res://characters/saved/"

static var _by_kind := {}         # kind -> preset (מהקבצים)
static var _loaded := false
static var live := {}             # kind -> preset שנבדק עכשיו (העורך, TRY IN LEVEL) - גובר על הקובץ


static func reload() -> void:
	_by_kind.clear()
	_loaded = true
	var d := DirAccess.open(DIR)
	if d == null:
		return
	for f in d.get_files():
		var fn := f.trim_suffix(".remap")   # במשחק המיוצא הקבצים נקראים <id>.tres.remap
		if not fn.ends_with(".tres"):
			continue
		var p = ResourceLoader.load(DIR + fn, "", ResourceLoader.CACHE_MODE_REPLACE)
		if p == null or p.get_script() != Preset or int(p.kind) < FIRST:
			continue
		_by_kind[int(p.kind)] = p


static func _ensure() -> void:
	if not _loaded:
		reload()


# כל הדמויות השמורות, לפי המספר
static func all() -> Array:
	_ensure()
	var ks := _by_kind.keys()
	ks.sort()
	var out := []
	for k in ks:
		out.append(_by_kind[k])
	return out


static func has(kind: int) -> bool:
	_ensure()
	return live.has(kind) or _by_kind.has(kind)


static func get_preset(kind: int) -> Resource:
	_ensure()
	if live.has(kind):
		return live[kind]
	return _by_kind.get(kind)


# הדמות השמורה עם השם (שם הקובץ) הזה, או null
static func get_preset_by_id(id: String) -> Resource:
	_ensure()
	for k in _by_kind:
		if str(_by_kind[k].id) == id:
			return _by_kind[k]
	return null


static func make(kind: int) -> RefCounted:
	var p := get_preset(kind)
	if p == null:
		return null
	var m = Custom.new()
	m.bind(p)
	return m


static func stats(kind: int) -> Dictionary:
	var m := make(kind)
	return m.stats() if m != null else {}


# מספר פנוי לדמות חדשה
static func next_kind() -> int:
	_ensure()
	var k := FIRST
	while _by_kind.has(k) or live.has(k):
		k += 1
	return k


# main.gd: מוסיף את הדמויות של השלב הזה למשקלים (מערך לפי kind, כמו zombie_weights).
# share 10 = בערך 10% מהזומבים בשלב. test = {"kind", "share"} (TRY IN LEVEL מהעורך)
static func add_weights(weights: Array, level: int, test := {}) -> void:
	_ensure()
	var picks := {}
	for k in _by_kind:
		var p = _by_kind[k]
		if (p.levels as PackedInt32Array).has(level):
			picks[k] = clampf(float(p.share) / 100.0, 0.0, 0.9)
	if not test.is_empty() and has(int(test.kind)):
		picks[int(test.kind)] = clampf(float(test.get("share", 0.4)), 0.0, 0.9)
	if picks.is_empty():
		return
	var total := 0.0
	for w in weights:
		total += float(w)
	var s := 0.0
	for k in picks:
		s += float(picks[k])
	var fit := minf(1.0, 0.9 / maxf(s, 0.001))   # ביחד לא יותר מ-90% (נשארים גם זומבים של השלב)
	s *= fit
	for k in picks:
		var w := float(picks[k]) * fit
		if total > 0.0:
			w = total * w / (1.0 - s)
		var old := weights.size()
		if old <= k:
			weights.resize(k + 1)
			for i in range(old, k + 1):
				weights[i] = 0.0
		weights[k] = w
