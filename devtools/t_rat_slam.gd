extends SceneTree
# RAT SLAM (test only): player.gd rat_slam + zombie.gd (RAT). The level's zombies are removed, then rats run at the
# player (who stands still, aiming right, not shooting), one case after another:
#   front / behind - one rat; pack - several rats; roll - the player rolls in the middle of the slam (the rat dies at once);
#   god - GOD MODE (no damage, still slammed); shield - the shield blocks the bite (still slammed);
#   kill - the rat is killed while it is in the hand (the body must come back, visible);
#   morale - the rat takes less damage (FLAGBEARER flag, level 40): the slam must still kill it
# Prints the bite damage of each case (it must stay: 1 per slam, 0 with god / shield) and where each dead rat ends up
# (on its back, by the player's feet). At the end: the bodies must stop being redrawn (the legs kick for 1 s, then still).
# usage: godot --headless --fixed-fps 60 --path . -s res://t_rat_slam.gd -- [level 1] [pack 5]
# pictures (window under xvfb): env SLAM_SHOT=/tmp/slam -> /tmp/slam_<front|behind>_<n>.png (around the player, 3x):
# grab, lift, over the head, swing, hit, after. env SLAM_CASES=god,front = only these cases, SLAM_TRACE=1 = the rat's approach
var CASES := ["front", "behind", "pack", "roll", "god", "shield", "kill", "morale"]
var lv := 1
var pack := 5
var main_node: Node
var pl: Node
var f := 0
var ci := -1
var t0 := 0
var rats := []
var hp0 := 0
var dmg := 0
var slams := 0
var was_slam := false
var acted := false
var shots := [0.03, 0.13, 0.23, 0.29, 0.34, 0.38, 0.41, 0.47, 0.58]
var shot_i := 0
var shot := ""
var cur: Node = null
var slammed := []
var end_f := 0


func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	lv = int(a[0]) if a.size() > 0 else lv
	pack = int(a[1]) if a.size() > 1 else pack
	shot = OS.get_environment("SLAM_SHOT")
	if OS.get_environment("SLAM_CASES") != "":
		CASES = Array(OS.get_environment("SLAM_CASES").split(","))
	var g = root.get_node("Game")
	g.new_run()
	g.level = lv
	main_node = load("res://main.tscn").instantiate()
	root.add_child(main_node)
	current_scene = main_node


func _spawn(dx: float) -> Node:
	var z = main_node._spawn_zombie(pl.global_position.x + dx, pl.global_position.y, 10)
	if z != null:
		z.dormant = false
		z._alert_t = 30.0
	return z


func _physics_process(_d: float) -> bool:
	f += 1
	pl = main_node.get_tree().get_first_node_in_group("player")
	if pl == null:
		return false
	for s in main_node.get_tree().get_nodes_in_group("story_scene"):
		if s.has_method("_finish"):
			s._finish()
	if end_f > 0:   # הגופות: אחרי שהרגליים הפסיקו לפרכס - לא מצוירות מחדש
		if f - end_f >= 150:
			var still := 0
			var n := 0
			for r in slammed:
				if is_instance_valid(r) and r.dead and r._belly_up:
					n += 1
					still += 1 if r._c_same >= 2 else 0
			print("SLAM bodies on their back 2.5 s later: %d, still (not redrawn) %d" % [n, still])
			print("SLAM done")
			quit()
		return false
	if ci < 0:
		pl.health = pl.max_health
		if f % 10 == 0:
			for z in main_node.get_tree().get_nodes_in_group("zombies"):
				z.queue_free()
		if f == 300:
			pl.global_position.x += 500.0
			pl.reset_physics_interpolation()
			pl.controllable = false   # עומד במקום ומכוון ימינה
			pl.idle_aim = Vector2.RIGHT
		if f == 330:
			_next()
		return false
	var case: String = CASES[ci]
	if pl.health < hp0:   # נשיכה שפגעה
		dmg += hp0 - pl.health
	if pl.health <= 2:   # (לא למות באמצע הבדיקה)
		pl.health = pl.max_health
	hp0 = pl.health
	if OS.get_environment("SLAM_TRACE") != "" and (f - t0) % 15 == 0 and rats.size() > 0 and is_instance_valid(rats[0]):
		var r0: Node = rats[0]
		print("SLAM   t=%.2f rat dx %.0f vx %.0f attack_t %.2f invuln %.2f" % [float(f - t0) / 60.0, r0.global_position.x - pl.global_position.x, r0.velocity.x, r0._attack_t, pl._invuln])
	var slam: bool = pl._slam_e >= 0.0
	if slam and not was_slam:
		slams += 1
		cur = pl._slam_rat
		slammed.append(cur)
		if case != "pack":
			print("SLAM %s grab at t=%.2f s: bite damage %d, rat side %+.0f, rat hidden %s" % [case, float(f - t0) / 60.0, dmg, pl._slam_side,
				str(cur != null and not cur.visible)])
	if slam and not acted:
		if case == "roll" and pl._slam_e > 0.2:   # גלגול באמצע
			acted = true
			pl._roll_t = 0.35
			print("SLAM roll: rolling at slam time %.2f s" % pl._slam_e)
		elif case == "kill" and pl._slam_e > 0.15 and cur != null:   # נהרגת ביד (פיצוץ...)
			acted = true
			cur.take_damage(5, cur.global_position, Vector2.UP, true, {"source": "grenade"})
			print("SLAM kill: rat killed in the hand at slam time %.2f s" % pl._slam_e)
	if slam and shot != "" and ci <= 1 and shot_i < shots.size() and pl._slam_e >= shots[shot_i]:
		_shoot("%s_%s_%d.png" % [shot, case, shot_i])
		shot_i += 1
	was_slam = slam
	var alive := 0
	for r in rats:
		if is_instance_valid(r) and not r.dead:
			alive += 1
	if alive == 0 and not slam and f - t0 > 50:
		print("SLAM %s done after %.1f s: %d slam(s), bite damage %d, shield left %d" % [case, float(f - t0) / 60.0, slams, dmg, pl.shield_hits])
		for r in rats:
			if is_instance_valid(r):
				var rel: Vector2 = r.global_position - pl.global_position
				print("SLAM   corpse %s from the player's feet, on floor %s, angle %.2f, belly up %s, visible %s, held %s" % [rel.round(),
					str(r.is_on_floor()), r._angle, str(r._belly_up), str(r.visible), str(r.held_by != null)])
		_next()
	elif f - t0 > 60 * 15:
		print("SLAM %s: not finished after 15 s? (%d rats alive, slam %s)" % [case, alive, str(slam)])
		_next()
	return false


func _next() -> void:
	ci += 1
	pl.boosts.erase(load("res://pickup.gd").GOD)
	if ci >= CASES.size():
		end_f = f
		return
	var case: String = CASES[ci]
	t0 = f
	shot_i = 0
	dmg = 0
	slams = 0
	acted = false
	pl._invuln = 0.0
	pl.health = pl.max_health
	hp0 = pl.health
	pl.shield_hits = 1 if case == "shield" else 0
	if case == "god":
		pl.boosts[load("res://pickup.gd").GOD] = 6.0
	rats.clear()
	if case == "pack":
		for i in pack:
			rats.append(_spawn(160.0 + 22.0 * float(i)))
	else:
		rats.append(_spawn(-150.0 if case == "behind" else 150.0))
		if case == "morale" and rats[0] != null:
			rats[0].set_meta("morale_t", 1.0e9)
	print("SLAM %s: %d rat(s) spawned (player faces %+.0f)" % [case, rats.size(), pl._face()])


func _shoot(path: String) -> void:
	var img: Image = root.get_viewport().get_texture().get_image()
	var ct := root.get_viewport().get_canvas_transform()
	var c: Vector2 = ct * (pl.global_position + Vector2(0.0, -30.0))
	var w := 220
	var h := 150
	var r := Rect2i(clampi(int(c.x) - w / 2, 0, img.get_width() - w), clampi(int(c.y) - h / 2 - 10, 0, img.get_height() - h), w, h)
	var sub := img.get_region(r)
	sub.resize(w * 3, h * 3, Image.INTERPOLATE_NEAREST)
	sub.save_png(path)
