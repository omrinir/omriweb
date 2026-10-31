extends "res://t_bot.gd"
# ESCAPE test: same as t_bot.gd, plus a log line about the horde every 2 s and its hits on the player.
# usage: godot --headless --fixed-fps 60 --path . -s res://t_escape.gd -- <level> <god 1/0> <max_sec>
# shots: xvfb-run ... godot --path . --rendering-driver opengl3 -s res://t_escape.gd -- <level> shot <frame_to_safe> <frame_png> <png>
#   (player to x=1700 at frame 5 -> horde starts, to safe_x + 20 at frame_to_safe -> crumble, PNG at frame_png)
var _esc: Node = null
var _cd_last := 0.0
var _logged_end := false
var horde_hits := 0


func _shot(_d: float) -> bool:
	var a := OS.get_cmdline_user_args()
	f += 1
	var p = main_node.get_tree().get_first_node_in_group("player")
	if p == null:
		return false
	p.health = p.max_health
	if f == 5:
		p.global_position.x = 1700.0
		if a.size() > 5:   # start close to the safe point (to see the crumble on screen)
			for n in main_node.get_children():
				if n.get_script() != null and str(n.get_script().resource_path).ends_with("events/escape.gd"):
					p.global_position.x = n._safe_x - float(a[5])
	if f == int(a[2]):
		for n in main_node.get_children():
			if n.get_script() != null and str(n.get_script().resource_path).ends_with("events/escape.gd"):
				p.global_position.x = n._safe_x + 20.0
	if f == int(a[3]):
		root.get_viewport().get_texture().get_image().save_png(a[4])
		print("saved ", a[4])
		quit()
	return false


func _physics_process(d: float) -> bool:
	var ua := OS.get_cmdline_user_args()
	if ua.size() > 1 and ua[1] == "shot":
		return _shot(d)
	var r := super(d)
	if main_node == null or pl == null:
		return r
	if _esc == null:
		for n in main_node.get_children():
			if n.get_script() != null and str(n.get_script().resource_path).ends_with("events/escape.gd"):
				_esc = n
				print("ESC trigger=%d safe=%d" % [n._trigger_x, n._safe_x])
	if _esc != null and is_instance_valid(_esc):
		var hp: int = pl.health
		var cd: float = _esc._touch_cd
		if cd > _cd_last + 0.5:   # the wall just hit (TOUCH_CD reset)
			horde_hits += 1
			print("ESC HIT t=%.1f px=%d hx=%d" % [_esc._t, pl.global_position.x, _esc._hx])
		_cd_last = cd
		if f % 120 == 0 and _esc._state == 1:
			print("ESC t=%.1f px=%d hx=%d gap=%d budget=%d hp=%d" % [_esc._t, pl.global_position.x, _esc._hx, pl.global_position.x - _esc._hx, _esc._budget, hp])
		if _esc._state == 2 and not _logged_end:
			_logged_end = true
			print("ESC END t=%.1f timed_out=%s horde_hits=%d" % [_esc._t, str(_esc._timed_out), horde_hits])
	elif _esc != null and not _logged_end:
		_logged_end = true
	return r
