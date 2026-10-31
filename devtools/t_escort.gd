extends "res://t_bot.gd"
# ESCORT test (test only): the autoplay bot + a report on the medic.
# usage: godot --headless --fixed-fps 60 --path . -s res://t_escort.gd -- <level> <god 1/0> <max_sec> [start_x]
var _m: Node = null
var _ev: Node = null
var _joined_f := -1
var _tp := 0
var _last_pos := Vector2.ZERO
var _hunts := 0
var _hids := {}
var _min_hp := 99
var _states := {}
var _max_gap := 0.0
var _last_hp := 99
var _bitten := {}
var _dead_f := -1

func _physics_process(d: float) -> bool:
	var r = super._physics_process(d)
	if main_node == null:
		return r
	if _ev == null:
		for c in main_node.get_children():
			if c.get_script() != null and str(c.get_script().resource_path).ends_with("escort.gd"):
				if OS.get_environment("ESCORT_OFF") != "":   # baseline: the level without the event
					c.set_physics_process(false)
					c.set_process(false)
					if c.medic != null:
						c.medic.queue_free()
					else:
						c.queue_free()
					return r
				_ev = c
	if _ev != null and _ev.medic != null and is_instance_valid(_ev.medic):
		_m = _ev.medic
		if _joined_f < 0 and _m.state != 0:
			_joined_f = f
		if _last_pos != Vector2.ZERO and _m.global_position.distance_to(_last_pos) > 120.0:
			_tp += 1
		_last_pos = _m.global_position
		if _m.hp < _last_hp:
			var best = null
			var bd := 9999.0
			for z in main_node.get_tree().get_nodes_in_group("zombies"):
				var dd: float = z.global_position.distance_to(_m.global_position)
				if dd < bd:
					bd = dd
					best = z
			if best != null:
				var nm: String = str(best.type_mod.get_script().resource_path.get_file()) if best.type_mod != null else "k" + str(best.kind)
				_bitten[nm] = int(_bitten.get(nm, 0)) + 1
		if _m.hp <= 0 and _dead_f < 0:
			_dead_f = f
		_last_hp = _m.hp
		_min_hp = mini(_min_hp, _m.hp)
		_states[_m.state] = int(_states.get(_m.state, 0)) + 1
		for id in _ev.hunters:
			_hids[id] = true
		if _m.state == 1 and pl != null:
			_max_gap = maxf(_max_gap, absf(pl.global_position.x - _m.global_position.x))
	return r

func _report_and_quit(why: String) -> void:
	if _ev != null:
		print("ESCORT lv=%d outcome=%s joined=%.1fs medic_tp=%d hunters=%d min_hp=%d spawn_x=%d states=%s max_gap=%d bitten=%s dead_f=%.1fs" % [lv, _ev.outcome if _ev.outcome != "" else "NONE", float(_joined_f) / 60.0, _tp, _hids.size(), _min_hp, _ev.spawn_x, str(_states), _max_gap, str(_bitten), float(_dead_f) / 60.0])
	super._report_and_quit(why)

# ESCORT_CP=1: the run starts at the mid-level checkpoint (TRY AGAIN / CONTINUE)
func _initialize() -> void:
	if OS.get_environment("ESCORT_CP") == "":
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
	g.checkpoint = {"level": lv, "x": 5120.0, "slots": (g.weapon_slots as Array).duplicate(true), "special": "", "special_uses": 0,
		"seed": g.attempt_seed, "run_score": 0, "scrap": g.scrap, "time": 40.0}
	g.use_checkpoint = true
	main_node = load("res://main.tscn").instantiate()
	root.add_child(main_node)
	current_scene = main_node
	t_prev = Time.get_ticks_usec()
	UpgradesS = load("res://progression/upgrade_db.gd")
