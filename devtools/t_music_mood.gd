extends SceneTree
# MUSIC MOOD (test only): effects/music_mood.gd - prints the level-music filter / volume in each state.
# calm (no awake zombie near) -> ~3800 Hz, -2.5 dB | zombies near -> 20500 Hz, 0 dB | hush (before an event) -> ~650 Hz, -17 dB
# | hit (the event starts) -> open again at once | boss: hushed while a boss you have not met is 900-1350 px away, then the boss track.
# usage: godot --headless --fixed-fps 60 --path . -s res://t_music_mood.gd -- [level 1]
var lv := 1
var main_node: Node
var pl: Node
var f := 0
var boss: Node = null


func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	lv = int(a[0]) if a.size() > 0 else lv
	var g = root.get_node("Game")
	g.new_run()
	g.level = lv
	main_node = load("res://main.tscn").instantiate()
	root.add_child(main_node)
	current_scene = main_node


func _state(label: String) -> void:
	var b := AudioServer.get_bus_index("LevelMusic")
	if b < 0:
		print("MOOD %-34s no LevelMusic bus" % label)
		return
	var lp := AudioServer.get_bus_effect(b, 0) as AudioEffectLowPassFilter
	var amp := AudioServer.get_bus_effect(b, 1) as AudioEffectAmplify
	var bm = main_node._boss_music
	print("MOOD %-34s cutoff %5.0f Hz  vol %5.1f dB | level track %5.1f dB  boss track %s" % [label, lp.cutoff_hz, amp.volume_db,
		main_node._music.volume_db if main_node._music != null else -99.0, ("%5.1f dB" % bm.volume_db) if bm != null else "-"])


func _physics_process(_d: float) -> bool:
	f += 1
	pl = main_node.get_tree().get_first_node_in_group("player")
	if pl == null:
		return false
	pl.health = pl.max_health
	if "_invuln" in pl:
		pl._invuln = 1.0
	for s in main_node.get_tree().get_nodes_in_group("story_scene"):
		if s.has_method("_finish"):
			s._finish()
	if (f < 620 or (f > 700 and f < 1300)) and f % 10 == 0:   # בלי זומבים (חוץ מהבוס), כדי שיהיה רגוע
		for z in main_node.get_tree().get_nodes_in_group("zombies"):
			if not z.is_boss():
				z.queue_free()
	match f:
		600:
			_state("calm (nobody near)")
		620:
			for i in 2:
				var z = main_node._spawn_zombie(pl.global_position.x + 320.0 + 60.0 * float(i), pl.global_position.y, 0)
				z.dormant = false
		650:
			_state("2 zombies near (+0.5 s)")
		700:
			_state("still near")
		890:
			_state("gone +3 s (still open: hold)")
		1100:
			_state("gone +6.7 s (calm again)")
		1171:
			_state("hush for 1.15 s")
		1172:
			main_node.music_hit()
		1178:
			_state("hit +0.1 s")
		1300:
			for z in main_node.get_tree().get_nodes_in_group("zombies"):
				if z.is_boss() and z.hp > 0:
					boss = z
					break
			if boss == null:
				print("MOOD no boss on this level")
				print("MOOD done")
				quit()
				return false
			_state("before the boss")
			pl.global_position = Vector2(boss.global_position.x - 1200.0, boss.global_position.y - 4.0)
			pl.reset_physics_interpolation()
		1390:
			_state("boss 1200 px away (+1.5 s)")
			pl.global_position = Vector2(boss.global_position.x - 800.0, boss.global_position.y - 4.0)
			pl.reset_physics_interpolation()
		1400:
			_state("boss 800 px away (+0.15 s)")
		1480:
			_state("boss fight (+1.5 s)")
			print("MOOD done")
			quit()
	if f > 1100 and f < 1172:
		main_node.music_hush()
	if f > 1300 and f < 1390 and boss != null and is_instance_valid(boss):   # הבוס נשאר במקום (שלא יבוא אלינו לפני הזמן)
		boss.global_position.x = pl.global_position.x + 1200.0
	return false
