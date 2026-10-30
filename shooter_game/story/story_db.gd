extends RefCounted
# ============================================================
#  STORY DB - רשימת סצנות הסיפור בשלבים. כל סצנה = קובץ ב-story/scenes/ עם const SCENE.
#  להוספת סצנה לשלב אחר: מעתיקים את l01_stranger.gd, משנים level / x / actor / voices / beats,
#  ומוסיפים אותו ל-SCENES כאן. כל סצנה מתנגנת פעם אחת בכל משחק של השלב (לא שוב אחרי TRY AGAIN).
# ============================================================

const SCENES := [
	preload("res://story/scenes/l01_stranger.gd"),
	preload("res://story/scenes/l03_survivor.gd"),
	preload("res://story/scenes/l17_stranger.gd"),
	preload("res://story/scenes/l52_quisling.gd"),
	preload("res://story/scenes/l54_stranger.gd"),
	preload("res://story/scenes/l55_stranger.gd"),
	preload("res://story/scenes/l57_chorus.gd"),
	preload("res://story/scenes/l59_stranger.gd"),
	preload("res://story/scenes/l60_file.gd"),
	preload("res://story/scenes/l62_hive.gd"),
]


static func for_level(lv: int) -> Array:
	var out := []
	for s in SCENES:
		if int(s.SCENE.level) == lv:
			out.append(s.SCENE)
	return out
