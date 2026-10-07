extends SceneTree
var n := 0
var m
var p
var G
var step := 0
var rects_a := []
var cp_x := 0.0
var slots_at_cp := []
func _initialize():
	G = root.get_node("Game")
	G.start_level(3)
	print("start: seed=", G.attempt_seed, " checkpoint=", G.checkpoint)
	m = load("res://main.tscn").instantiate()
	root.add_child(m)
func _physics_process(_d):
	n += 1
	if step == 0 and n == 20:
		p = get_first_node_in_group("player")
		rects_a = m._rects.slice(0, 5).map(func(r): return r.position.round())
		var cp = get_first_node_in_group("checkpoints")
		cp_x = cp.global_position.x
		p.slots[0].ammo = 77
		p.grenades = 5
		p.global_position = Vector2(cp_x + 40.0, p.global_position.y - 60)
	if step == 0 and n == 40:
		var cfg := ConfigFile.new()
		cfg.load("user://progress.cfg")
		var saved = cfg.get_value("progress", "campaign", {}).get("checkpoint", {})
		print("after passing flag: Game.checkpoint level=", G.checkpoint.get("level"), " x=", int(G.checkpoint.get("x", 0)), " | on disk: level=", saved.get("level"), " slots0 ammo=", saved.get("slots", [{}])[0].get("ammo"), " grenades=", saved.get("grenades"))
		# "מתים" ולוחצים TRY AGAIN
		G.restart_level()
		print("restart: use_checkpoint=", G.use_checkpoint, " seed=", G.attempt_seed)
		m.queue_free()
		m = load("res://main.tscn").instantiate()
		root.add_child(m)
		step = 1
		n = 0
	if step == 1 and n == 20:
		p = get_first_node_in_group("player")
		var rects_b = m._rects.slice(0, 5).map(func(r): return r.position.round())
		print("after TRY AGAIN: player x=", int(p.global_position.x), " (checkpoint ", int(cp_x), ") rifle ammo=", p.slots[0].ammo, " grenades=", p.grenades, " same layout=", rects_a == rects_b)
		# תרגול לא נוגע בקובץ
		var before := FileAccess.get_file_as_string("user://progress.cfg")
		G.start_practice(16)
		G._save()
		G.unlock("test_trophy_xyz")
		var after := FileAccess.get_file_as_string("user://progress.cfg")
		print("practice: loadout=", G.weapon_slots.map(func(s): return s.id if s != null else -1), " file unchanged=", before == after)
		G.end_practice()
		print("after practice: practice=", G.practice, " checkpoint level=", G.checkpoint.get("level"), " resume_level=", G.resume_level(), " has_progress=", G.has_progress())
		G.trophies.erase("test_trophy_xyz")
		quit()
