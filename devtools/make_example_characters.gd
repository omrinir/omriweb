extends SceneTree
# Writes the 6 example CHARACTER MAKER characters to res://characters/saved/ (kinds 1000-1005).
# They are in no level (levels = []): they only show up in the maker until someone ticks levels for them.
# usage (in a copy of the game folder, then copy characters/saved/*.tres back):
#   godot --headless --path . -s res://make_example_characters.gd
const Preset := preload("res://characters/character_preset.gd")

const EXAMPLES := [
	{"id": "butcher", "kind": 1000, "name": "BUTCHER", "build": "big", "height": 1.04, "width": 1.08, "head_size": 0.95, "hunch": 4.0,
		"hair": "none", "top": "tank", "extras": ["apron"], "item": "cleaver", "gore": ["rot", "cheek", "blood"],
		"skin_color": "8a9e6e", "shirt_color": "d8d4c8", "pants_color": "4a4a50", "shoe_color": "2c241e", "eye_color": "ff3020", "gear_color": "e8e4dc",
		"hp": 60, "walk_speed": 40.0, "run_speed": 85.0, "damage": 2, "bite_delay": 1.0, "duck": 0.1, "cover": 0.2, "notice": 480.0, "points": 300, "voice": 0.75},
	{"id": "hard_hat", "kind": 1001, "name": "HARD HAT", "hunch": 3.0,
		"hair": "short", "hat": "hardhat", "top": "shirt", "extras": ["vest", "belt"], "item": "wrench", "gore": ["rot", "flesh"],
		"skin_color": "86a06a", "shirt_color": "4f6688", "pants_color": "34466a", "shoe_color": "4a3220", "hair_color": "5a4630", "hat_color": "e8b820", "gear_color": "e87020",
		"hp": 40, "points": 200},
	{"id": "surgeon", "kind": 1002, "name": "SURGEON", "build": "skinny", "height": 1.06, "hunch": 2.0,
		"hair": "short", "hat": "bandana", "face": "surgical", "top": "shirt", "item": "knife", "gore": ["rot", "chest_stitches", "blood"],
		"skin_color": "aab7a6", "shirt_color": "4a8a84", "pants_color": "3e7470", "shoe_color": "d8d8d0", "hat_color": "4a8a84", "eye_color": "60ff40",
		"hp": 25, "walk_speed": 50.0, "run_speed": 125.0, "duck": 0.4, "cover": 0.3, "notice": 600.0, "points": 200, "voice": 1.15},
	{"id": "party_guy", "kind": 1003, "name": "PARTY GUY", "head_size": 1.1, "hunch": 3.5,
		"hair": "afro", "hat": "party", "face": "sunglasses", "top": "shirt", "extras": ["tie"], "item": "teddy", "gore": ["rot", "cheek"],
		"skin_color": "a8b04a", "shirt_color": "6a3a8a", "pants_color": "1e1e24", "shoe_color": "1a1a1a", "hair_color": "1a1616", "hat_color": "e87aa0", "gear_color": "c8a020",
		"walk_speed": 48.0, "run_speed": 105.0, "voice": 1.1},
	{"id": "convict", "kind": 1004, "name": "CONVICT", "width": 1.1, "hunch": 4.5,
		"hair": "none", "top": "prison", "item": "pipe", "gore": ["rot", "scalp_stitches", "head_wound"],
		"skin_color": "74945a", "shirt_color": "d86a20", "pants_color": "d86a20", "shoe_color": "d8d8d0", "eye_color": "ff9020",
		"hp": 45, "walk_speed": 46.0, "run_speed": 110.0, "damage": 2, "duck": 0.3, "cover": 0.6, "points": 250, "voice": 0.9},
	{"id": "tourist", "kind": 1005, "name": "TOURIST", "height": 0.95, "width": 1.14, "head_size": 1.05, "hunch": 2.5,
		"hair": "short", "hat": "cap", "face": "glasses", "top": "shirt", "extras": ["backpack", "belt"], "item": "phone", "gore": ["rot", "cheek", "bone_arm"],
		"skin_color": "b8b47a", "shirt_color": "d8a040", "pants_color": "c8b48a", "shoe_color": "d8d8d0", "hair_color": "8a8880", "hat_color": "d83020", "gear_color": "2a4a8a",
		"hp": 30, "walk_speed": 38.0, "run_speed": 85.0, "notice": 420.0, "voice": 0.95},
]


func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://characters/saved"))
	for e in EXAMPLES:
		var p = Preset.new()
		for k in e:
			var v = e[k]
			match typeof(p.get(k)):
				TYPE_COLOR:
					v = Color(v)
				TYPE_PACKED_STRING_ARRAY:
					v = PackedStringArray(v)
			p.set(k, v)
		var path := "res://characters/saved/%s.tres" % e.id
		print(path, " -> ", error_string(ResourceSaver.save(p, path)))
	quit()
