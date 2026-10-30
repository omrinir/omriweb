extends "res://t_bot.gd"
# HOLD THE LINE test: the autoplay bot (t_bot.gd), but while the hold is active the bot "waits on purpose"
# (like it does for the pass barrier) instead of teleporting forward after 25 s. Prints a HOLD line at the end.
# usage: godot --headless --fixed-fps 60 --path . -s res://t_hold.gd -- <level> <god 1/0> <max_sec>
# screenshots (needs xvfb + opengl3, not headless): env HOLD_SHOTS="1,20,-1" (seconds into the hold; -1 = 1s after it ends)
#   HOLD_SHOT_PREFIX=/tmp/x  -> /tmp/x_1.png ...

var _hold: Node = null
var _seen := false
var _hold_info := ""
var _hp_at_start := -1
var _dmg_in_hold := 0
var _end_logged := false
var _tp0 := 0
var _shots: Array = []
var _shot_prefix := ""
var _hold_f0 := -1
var _end_f0 := -1
var _h_slow := 0
var _h_worst := 0.0
var _h_sum := 0.0
var _h_n := 0
var _h_prev := 0
var _h_zmax := 0


# env HOLD_DIFF=0/1/2: the EVENT's difficulty scaling only (Settings.difficulty is saved to disk - not touched). env HOLD_CP=1: the level starts at the checkpoint (like TRY AGAIN / CONTINUE) - the hold must be skipped
func _initialize() -> void:
	if OS.get_environment("HOLD_CP") == "":
		super._initialize()
		return
	var a := OS.get_cmdline_user_args()
	lv = int(a[0]) if a.size() > 0 else 1
	god = (a[1] != "0") if a.size() > 1 else true
	max_frames = int(float(a[2]) * 60.0) if a.size() > 2 else 21600
	var g = root.get_node("Game")
	g.new_run()
	g.start_practice(lv)
	g.level = lv
	g.attempt_seed = 1000 + lv * 7
	seed(g.attempt_seed)
	g.checkpoint = {"level": lv, "time": 90.0, "slots": g.weapon_slots.duplicate(true), "special": "", "special_uses": 0}
	g.use_checkpoint = true
	main_node = load("res://main.tscn").instantiate()
	root.add_child(main_node)
	current_scene = main_node
	t_prev = Time.get_ticks_usec()
	UpgradesS = load("res://progression/upgrade_db.gd")


func _find_hold() -> Node:
	if main_node == null:
		return null
	for c in main_node.get_children():
		if c.get_script() != null and str(c.get_script().resource_path).ends_with("events/hold.gd"):
			return c
	return null


func _shoot(tag: String) -> void:
	var img := root.get_viewport().get_texture().get_image()
	var path := "%s_%s.png" % [_shot_prefix, tag]
	img.save_png(path)
	print("HOLD SHOT ", path)


func _ammo_str() -> String:
	var out := []
	for sl in pl.slots:
		if sl != null:
			out.append("%s:%d" % [str(root.get_node("Game").WEAPON_NAMES[int(sl.id)]), int(sl.ammo)])
	return ",".join(out)


func _move() -> void:
	if f == 10 and OS.get_environment("HOLD_CP") != "":
		print("HOLD CP start: player x=%d hold_node=%s clock_pars=%s" % [pl.global_position.x, str(_find_hold()), str(root.get_node("Game").clock_pars)])
	if _shot_prefix == "" and OS.get_environment("HOLD_SHOTS") != "":
		_shot_prefix = OS.get_environment("HOLD_SHOT_PREFIX")
		for v in OS.get_environment("HOLD_SHOTS").split(","):
			_shots.append(float(v))
	if _hold_f0 >= 0:
		for v in _shots.duplicate():
			var sec: float = v
			if (sec >= 0.0 and f - _hold_f0 == int(sec * 60.0)) or (sec < 0.0 and _end_f0 >= 0 and f - _end_f0 == 60):
				_shoot(str(v))
				_shots.erase(v)
	if _end_f0 >= 0 and f - _end_f0 == 240:
		print("HOLD +4s: player=%s ammo=%s" % [str(pl.global_position.round()), _ammo_str()])
	if _hold == null or not is_instance_valid(_hold):
		_hold = _find_hold()
	if _hold != null and is_instance_valid(_hold):
		if _hold_info == "" and OS.get_environment("HOLD_DIFF") != "" and _hold.state == 0:
			var d := int(OS.get_environment("HOLD_DIFF"))
			_hold._diff = d
			_hold.duration = float(_hold.DURATION[d])
			_hold._max_alive = int(_hold.MAX_ALIVE[d]) - (1 if lv <= _hold.EARLY_LEVEL else 0)
		if _hold_info == "":
			_hold_info = "x0=%d cx=%d x1=%d w=%d dur=%.0f" % [_hold.x0, _hold.cx, _hold.x1, _hold.x1 - _hold.x0, _hold.duration]
		if _hold.is_active():
			if not _seen:
				_seen = true
				_hp_at_start = dmg_taken
				_tp0 = teleports
				_hold_f0 = f
				print("HOLD started f=%d player=%s ammo=%s" % [f, str(pl.global_position.round()), _ammo_str()])
			best_x_f = f
			var now := Time.get_ticks_usec()
			if _h_prev > 0:
				var ms := float(now - _h_prev) / 1000.0
				_h_sum += ms
				_h_n += 1
				_h_worst = maxf(_h_worst, ms)
				if ms > 25.0:
					_h_slow += 1
			_h_prev = now
			if f % 30 == 0:
				_h_zmax = maxi(_h_zmax, main_node.get_tree().get_nodes_in_group("zombies").size())
		elif _seen and not _end_logged and _hold.state == 2:
			_end_logged = true
			_end_f0 = f
			_dmg_in_hold = dmg_taken - _hp_at_start
			print("HOLD ended f=%d player=%s spawned=%d drops=%d dmg_in_hold=%d alive_in_arena=%d frames: avg=%.1fms slow25=%d worst=%.0fms zombies_max=%d ammo=%s" % [f, str(pl.global_position.round()), _hold.spawned, _hold.drops, _dmg_in_hold, _hold._alive_in_arena(), _h_sum / maxf(_h_n, 1), _h_slow, _h_worst, _h_zmax, _ammo_str()])
	super._move()


func _report_and_quit(why: String) -> void:
	print("HOLD lv=%d spot=[%s] triggered=%s ended=%s dmg_in_hold=%d" % [lv, _hold_info, str(_seen), str(_end_logged), _dmg_in_hold])
	super._report_and_quit(why)
