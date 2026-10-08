extends Node
# ============================================================
#  הגדרות המשחק (Autoload בשם Settings - זמין מכל מקום).
#  רמת הקושי נשמרת בקובץ, כך שהמשחק זוכר אותה בפעם הבאה.
# ============================================================

enum { EASY, NORMAL, HARD }

const NAMES := ["EASY", "NORMAL", "HARD"]
const COLORS := [Color("5fae4a"), Color("d8a033"), Color("d0242c")]

# מה משתנה בכל רמת קושי
const PRESETS := [
	{   # EASY
		"player_hp": 7, "zombies_per_screen": 1.1, "zombie_speed": 0.85, "smart": 0.5, "dormant": 0.15,
		"desc": "More hearts. Fewer, slower zombies that rarely hide.",
	},
	{   # NORMAL
		"player_hp": 5, "zombies_per_screen": 1.6, "zombie_speed": 1.0, "smart": 1.0, "dormant": 0.25,
		"desc": "The city as it is. Stay sharp.",
	},
	{   # HARD
		"player_hp": 3, "zombies_per_screen": 2.3, "zombie_speed": 1.2, "smart": 1.5, "dormant": 0.35,
		"desc": "Three hearts. A fast, clever horde. Good luck.",
	},
]

const SAVE_PATH := "user://settings.cfg"

# מדריך כוונה (L מחליף): 0 כבוי, 1 רק כוונת, 2 כוונת + קו מנוקד מהקנה
const AIM_NAMES := ["OFF", "CROSSHAIR", "CROSSHAIR + LINE"]
var aim_guide := 2

var difficulty := NORMAL:
	set(v):
		difficulty = clampi(v, 0, 2)
		_save()


# ---- עוצמת שמע (0..1). ערוצים נפרדים: "Music" (מוזיקה) ו-"SFX" (אפקטים) ----
var music_volume := 0.8
var sfx_volume := 0.9


func _ready() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) == OK:
		difficulty = clampi(int(cfg.get_value("game", "difficulty", NORMAL)), 0, 2)
		aim_guide = clampi(int(cfg.get_value("game", "aim_guide", 2)), 0, 2)
		music_volume = clampf(float(cfg.get_value("audio", "music", 0.8)), 0.0, 1.0)
		sfx_volume = clampf(float(cfg.get_value("audio", "sfx", 0.9)), 0.0, 1.0)
	_ensure_buses()
	apply_volumes()


# יוצר את ערוצי השמע אם הם לא קיימים
func _ensure_buses() -> void:
	for b in ["Music", "SFX"]:
		if AudioServer.get_bus_index(b) < 0:
			AudioServer.add_bus()
			var i := AudioServer.bus_count - 1
			AudioServer.set_bus_name(i, b)
			AudioServer.set_bus_send(i, "Master")
	# לימיטר על הערוץ הראשי: יריות ופגיעות חזקות לא "נשברות" (עיוות) כשהרבה צלילים יחד
	var m := AudioServer.get_bus_index("Master")
	var has_lim := false
	for e in AudioServer.get_bus_effect_count(m):
		if AudioServer.get_bus_effect(m, e) is AudioEffectHardLimiter:
			has_lim = true
	if not has_lim:
		var lim := AudioEffectHardLimiter.new()
		lim.ceiling_db = -0.5
		AudioServer.add_bus_effect(m, lim)


func apply_volumes() -> void:
	for pair in [["Music", music_volume], ["SFX", sfx_volume]]:
		var i := AudioServer.get_bus_index(pair[0])
		if i >= 0:
			var v: float = pair[1]
			AudioServer.set_bus_mute(i, v <= 0.001)
			AudioServer.set_bus_volume_db(i, linear_to_db(maxf(v, 0.001)))


func set_volume(kind: String, v: float) -> void:
	if kind == "music":
		music_volume = clampf(v, 0.0, 1.0)
	else:
		sfx_volume = clampf(v, 0.0, 1.0)
	apply_volumes()
	_save()


func preset() -> Dictionary:
	return PRESETS[difficulty]


func difficulty_name() -> String:
	return NAMES[difficulty]


func _save() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("game", "difficulty", difficulty)
	cfg.set_value("game", "aim_guide", aim_guide)
	cfg.set_value("audio", "music", music_volume)
	cfg.set_value("audio", "sfx", sfx_volume)
	cfg.save(SAVE_PATH)
