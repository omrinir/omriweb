extends "res://t_bot.gd"
# CLIP RECORDER (test only): the playtest bot, with the HUD hidden. Use with --write-movie.
# env REC_SPECIAL=<special id> gives that item at frame 60 (e.g. gravity). REC_NOMUSIC=1 mutes the music bus.

var _hooked := false

# highlights log: one line per kill streak step, used to pick the best moments
func _on_streak(count: int, head: bool, bonus: int, pos: Vector2, tags: Array) -> void:
	print("EV t=%.2f kill streak=%d head=%s tags=%s" % [f / 60.0, count, head, ",".join(tags)])


func _physics_process(d: float) -> bool:
	if not _hooked:
		_hooked = true
		root.get_node("Game").streak_kill.connect(_on_streak)
	var r := super(d)
	if OS.get_environment("REC_NOMUSIC") != "":   # music is added in the edit instead, so it doesn't jump at cuts
		var mb := AudioServer.get_bus_index("Music")
		if mb >= 0:
			AudioServer.set_bus_mute(mb, true)
	if f % 20 == 1:
		for n in main_node.get_children():
			if n is CanvasLayer and n.layer >= 2:
				n.visible = false
	var sp := OS.get_environment("REC_SPECIAL")
	if sp != "" and pl != null and f % 240 == 60 and pl.special == "":
		pl.take_special(sp)
	if boss_seen_f == f:
		print("EV t=%.2f boss_seen" % (f / 60.0))
	if boss_dead_f == f:
		print("EV t=%.2f boss_dead" % (f / 60.0))
	return r
