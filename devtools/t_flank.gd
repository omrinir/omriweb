extends SceneTree
# FLANK DIRECTOR (test only): levels/flank_director.gd - zombies that sneak up from behind.
# The player stands at FLANK_X facing right (invulnerable, never shoots), so after FIRST_T s he counts as "camping".
# Prints every flanker: when, kind, how far behind, whether it started off screen, when it reached the player
# and whether a threat arrow (ui/threat_arrows.gd) pointed at it first. Every flanker is killed once it arrives,
# so the next one can come. Ends after FLANK_T s with the totals.
# usage: godot --headless --fixed-fps 60 --path . -s res://t_flank.gd -- [level 5] [seconds 240]
#   env FLANK_X=3000 (player x), FLANK_DIFF=0/1/2 (difficulty)
var lv := 5
var secs := 240.0
var f := 0
var main_node: Node
var pl: Node2D
var flank: Node = null
var arrows: Node = null
var seen := {}        # instance id -> [zombie, spawn time, dx at spawn, arrived time, arrow seen]
var first_t := -1.0
var times := []


func _env(k: String, d: Variant) -> Variant:
	var v := OS.get_environment(k)
	if v == "":
		return d
	return float(v) if d is float else (int(v) if d is int else v)


func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	lv = int(a[0]) if a.size() > 0 else lv
	secs = float(a[1]) if a.size() > 1 else secs
	root.get_node("Settings").difficulty = _env("FLANK_DIFF", 1)
	var g = root.get_node("Game")
	g.new_run()
	g.level = lv
	main_node = load("res://main.tscn").instantiate()
	root.add_child(main_node)
	current_scene = main_node


func _physics_process(_d: float) -> bool:
	f += 1
	var t := float(f) / 60.0
	if pl == null:
		pl = main_node.get_tree().get_first_node_in_group("player")
		for c in main_node.get_children():
			var sc = c.get_script()
			if sc != null and str(sc.resource_path).ends_with("flank_director.gd"):
				flank = c
			if sc != null and str(sc.resource_path).ends_with("threat_arrows.gd"):
				arrows = c
		if flank == null:
			print("FLANK L%d no flank director (stage has its own waves)" % lv)
			quit()
			return true
		print("FLANK L%d events %d" % [lv, flank.events])
		return false
	pl.max_health = 99
	pl.health = 99
	pl.global_position.x = float(_env("FLANK_X", 3000.0))
	pl.velocity.x = 0.0
	pl.controllable = false   # aims at idle_aim (headless: the mouse sits at the top left)
	pl.idle_aim = Vector2.RIGHT
	for z in main_node.get_tree().get_nodes_in_group("zombies"):
		var dx: float = z.global_position.x - pl.global_position.x
		if z.dead:
			continue
		var id: int = z.get_instance_id()
		if not seen.has(id) and f > 3 and not z.is_boss() and dx < -500.0 and z._alert_t > 5.5 and z._alert_t <= flank.ALERT:   # noise = 5 at most
			seen[id] = [z, t, dx, -1.0, false]
			if first_t < 0.0:
				first_t = t
			times.append(t)
			var vp: Vector2 = main_node.get_viewport_rect().size
			var cam: Camera2D = main_node.get_viewport().get_camera_2d()
			var half: float = vp.x * 0.5 / cam.zoom.x
			print("  t=%5.1f kind %d dx %4.0f off_screen %s (half view %.0f)" % [t, z.kind, dx, str(-dx > half), half])
		if seen.has(id):
			var s: Array = seen[id]
			if arrows != null and arrows._marks.has(id):
				s[4] = true
			if s[3] < 0.0 and absf(dx) < 60.0:
				s[3] = t
				print("  t=%5.1f kind %d arrived after %.1fs, arrow first %s" % [t, z.kind, t - float(s[1]), str(s[4])])
				z.take_damage(9999, z.global_position + Vector2(0, -30), Vector2.ZERO, true, {})
		elif absf(dx) < 900.0 and not z.is_boss():   # the stage's own zombies: out of the way (only flankers here)
			z.queue_free()
	if t >= secs:
		var late := 0
		for id in seen:
			if float(seen[id][3]) < 0.0:
				late += 1
		var gaps := []
		for i in range(1, times.size()):
			gaps.append("%.0f" % (float(times[i]) - float(times[i - 1])))
		print("FLANK L%d done: flankers %d (spawned %d) first at %.1fs, gaps %s, left %d events, never arrived %d" % [
			lv, seen.size(), flank.spawned, first_t, str(gaps), flank.events, late])
		if flank.spawned == 0:   # why not? (the level layout is random: often just no free ground behind this x)
			print("  now: fits %s, spot %.0f, kinds %s" % [str(flank._fits(pl)), flank._spot(pl.global_position.x), str(flank._kind_ok)])
		quit()
		return true
	return false
