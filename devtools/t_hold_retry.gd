extends "res://t_hold.gd"
# HOLD THE LINE retry test: 5 s into the hold the bot "dies" -> TRY AGAIN (Game.restart_level + new main, like pause_menu).
# Expect: the level restarts just before the arena (Game.checkpoint has "hold"), not at the start; the arena is in the
# same place, closes again when the bot walks in, and the mid-level checkpoint is not marked reached.
# usage: godot --headless --fixed-fps 60 --path . -s res://t_hold_retry.gd -- <level> <god 1/0> <max_sec>

var _retried := false
var _retry_f := -1
var _first := {}


func _move() -> void:
	if not _retried and _hold != null and is_instance_valid(_hold) and _hold.is_active() and _hold_f0 >= 0 and f - _hold_f0 == 300:
		var g = root.get_node("Game")
		_first = {"x0": _hold.x0, "x1": _hold.x1, "cp": g.checkpoint.duplicate(true)}
		print("RETRY dying in hold: player x=%d checkpoint x=%s hold=%s time=%.1f" % [pl.global_position.x, str(g.checkpoint.get("x")), str(g.checkpoint.get("hold")), float(g.checkpoint.get("time", -1))])
		_retried = true
		_retry_f = f
		g.restart_level()
		main_node.queue_free()
		main_node = load("res://main.tscn").instantiate()
		root.add_child(main_node)
		current_scene = main_node
		pl = null
		_hold = null
		_seen = false
		_hold_info = ""
		_hold_f0 = -1
		_end_f0 = -1
		_end_logged = false
		return
	if _retried and f == _retry_f + 5 and pl != null:
		var h := _find_hold()
		print("RETRY restarted: player x=%d (want %s) level_time=%.1f mid_cp_reached=%s hold=%s x0=%s (was %d)" % [
			pl.global_position.x, str(_first.cp.get("x")), float(root.get_node("Game").level_time), str(main_node._checkpoint.reached),
			"none" if h == null else str(h.state), "-" if h == null else str(h.x0), _first.x0])
	super._move()
