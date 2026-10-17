extends "res://t_bot.gd"
# CLIP RECORDER (test only): the playtest bot, with the HUD hidden. Use with --write-movie.
# env REC_SPECIAL=<special id> gives that item at frame 60 (e.g. gravity)

func _physics_process(d: float) -> bool:
	var r := super(d)
	if f % 20 == 1:
		for n in main_node.get_children():
			if n is CanvasLayer and n.layer >= 2:
				n.visible = false
	var sp := OS.get_environment("REC_SPECIAL")
	if sp != "" and pl != null and f % 240 == 60 and pl.special == "":
		pl.take_special(sp)
	return r
