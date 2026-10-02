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

var difficulty := NORMAL:
	set(v):
		difficulty = clampi(v, 0, 2)
		_save()


func _ready() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) == OK:
		difficulty = clampi(int(cfg.get_value("game", "difficulty", NORMAL)), 0, 2)


func preset() -> Dictionary:
	return PRESETS[difficulty]


func difficulty_name() -> String:
	return NAMES[difficulty]


func _save() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("game", "difficulty", difficulty)
	cfg.save(SAVE_PATH)
