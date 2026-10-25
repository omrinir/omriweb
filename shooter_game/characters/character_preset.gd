extends Resource
# ============================================================
#  CHARACTER PRESET - דמות אחת שנבנתה ב-CHARACTER MAKER (characters/maker.tscn).
#  נשמרת כקובץ טקסט: characters/saved/<id>.tres (אפשר לפתוח אותו גם ב-Inspector של Godot).
#  zombie.gd מצייר אותה בגוף הרגיל של הזומבים, כך שכל הגור עובד (ירייה בראש, נקרע לשניים, נשרף, זוחל...),
#  ומוסיף את החלקים מ-characters/parts.gd. הסוג (custom_character.gd) נבנה מהקובץ הזה.
#  kind = מספר הזומבי (מ-1000, enemies/zombie_registry.gd CUSTOM_FIRST). levels / share = איפה ובכמה הוא מופיע.
#  שמות החלקים (hair, hat, face, top, extras, item, gore) = הרשימות ב-characters/parts.gd.
# ============================================================

@export var id := ""                  # שם הקובץ: characters/saved/<id>.tres
@export var kind := 0                 # מספר הזומבי (1000 והלאה). שלבים בוחרים זומבים לפי המספר הזה
@export var name := "NEW ZOMBIE"

# ---- גוף ----
@export_enum("normal", "skinny", "big") var build: String = "normal"
@export_range(0.75, 1.5, 0.01) var height := 1.0
@export_range(0.75, 1.5, 0.01) var width := 1.0
@export_range(0.8, 1.6, 0.01) var head_size := 1.0
@export_range(0.0, 10.0, 0.5) var hunch := 3.0     # כמה הוא רכון קדימה
@export var barefoot := false

# ---- ראש / בגדים / ידיים (שמות מ-parts.gd) ----
@export var hair := "short"
@export var hat := "none"
@export var face := "none"
@export var top := "shirt"
@export var extras := PackedStringArray()
@export var item := "none"
@export var gore := PackedStringArray(["rot", "cheek"])
# הציורים שלך (לשונית DRAW, characters/drawings.gd): תמונה על חלק, כמו שהיא, עד ש-Claude מצייר אותה כחלק אמיתי
@export var drawings: Array = []

# ---- צבעים ----
@export var skin_color := Color("86a06a")
@export var shirt_color := Color("4f6688")    # החולצה / המעיל / הגופייה
@export var pants_color := Color("3d3a4c")
@export var shoe_color := Color("2c241e")
@export var hair_color := Color("3a3026")
@export var eye_color := Color("ffd940")      # העין הזוהרת
@export var hat_color := Color("3a3e46")
@export var gear_color := Color("8a6a3a")     # תוספות: סינר, אפוד, צעיף, תיק...
@export var variety := true                   # כל זומבי קצת שונה (גוון עור / חולצה / שיער)

# ---- התנהגות ----
@export var hp := 30
@export var walk_speed := 45.0
@export var run_speed := 95.0
@export var damage := 1
@export var bite_delay := 0.8                 # שניות בין נשיכות
@export_range(0.0, 0.9) var duck := 0.25      # סיכוי להתכופף מיריות
@export_range(0.0, 0.9) var cover := 0.45     # סיכוי לרוץ למחסה
@export var notice := 520.0                   # מאיזה מרחק הוא רואה אותך ומתחיל לרדוף
@export var points := 150
@export var boss := false                     # פס חיים של בוס
@export_range(0.6, 1.5) var voice := 1.0      # גובה הקול (נמוך = עמוק)

# ---- שלבים ----
@export var levels := PackedInt32Array()      # באילו שלבים הוא מופיע (ריק = באף שלב)
@export_range(1, 50) var share := 10          # אחוז מהזומבים בשלבים האלה


func has_extra(e: String) -> bool:
	return extras.has(e)


func has_gore(g: String) -> bool:
	return gore.has(g)


# שם קובץ חוקי מהשם של הדמות ("Big Bob!" -> "big_bob")
static func make_id(s: String) -> String:
	var out := ""
	for ch in s.to_lower().strip_edges():
		if (ch >= "a" and ch <= "z") or (ch >= "0" and ch <= "9"):
			out += ch
		elif not out.ends_with("_"):
			out += "_"
	out = out.trim_prefix("_").trim_suffix("_")
	return out if out != "" else "zombie"
