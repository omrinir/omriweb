extends SceneTree
# FLANK DIRECTOR kinds (test only): every kind of the level's mix that levels/flank_director.gd would send from behind
# is spawned the way a flanker is (flank._spot / flank._flanker, ALERT) behind the standing player, one at a time.
# Prints per kind: how long it took to reach the player (REACH px) / STOPPED (stays away = keeps its distance) / died on the
# way (a trap of the level), the closest it got, and how many hits the player took while it was still far away (FAR px = a
# ranged attack from behind - those kinds should not be sent; a level trap can also hit, so check the kind before blaming it).
# Kinds the director refuses (boss, slow, own movement, leash, NO_KINDS) print as "no".
# usage: godot --headless --fixed-fps 60 --path . -s res://t_flank_reach.gd -- [level 2] [seconds per kind 14]
const PX := 3000.0
const REACH := 70.0
const FAR := 160.0
const NAMES := ["walker", "runner", "brute", "spitter", "screamer", "boss", "bloater", "conductor", "crawler", "cop", "rat",
	"hand", "mech", "hurler", "imp", "dog", "drunk", "gunner", "jetpack", "hound"]
var lv := 2
var per := 14.0
var f := 0
var main_node: Node
var pl: Node2D
var flank: Node = null
var pending := []
var cur: Node = null
var cur_k := -1
var cur_t := 0.0
var reach_t := -1.0
var min_d := 99999.0
var far_hits := 0
var px := PX
var out := []
var bad := []


func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	lv = int(a[0]) if a.size() > 0 else lv
	per = float(a[1]) if a.size() > 1 else per
	var g = root.get_node("Game")
	g.new_run()
	g.level = lv
	main_node = load("res://main.tscn").instantiate()
	root.add_child(main_node)
	current_scene = main_node


func _name(k: int) -> String:
	if k < NAMES.size():
		return NAMES[k]
	var reg = load("res://enemies/zombie_registry.gd")
	return str(reg.TYPES.get(k, "?")).get_file().get_basename()


func _physics_process(d: float) -> bool:
	f += 1
	if f == 3:
		pl = main_node.get_tree().get_first_node_in_group("player")
		for c in main_node.get_children():
			var sc = c.get_script()
			if sc != null and str(sc.resource_path).ends_with("flank_director.gd"):
				flank = c
		if flank == null:
			print("REACH L%d no flank director" % lv)
			quit()
			return true
		flank.events = 0   # the director itself stays quiet; this test sends them
		var w: Array = main_node.zombie_weights
		for k in w.size():
			if float(w[k]) > 0.0:
				pending.append(k)
		return false
	if f < 3:
		return false
	pl.max_health = 99
	if pl.health < 99:
		var nd := absf(cur.global_position.x - pl.global_position.x) if cur != null and is_instance_valid(cur) else 99999.0
		if nd > FAR:
			far_hits += 1
		pl.health = 99
	pl.global_position.x = px
	pl.velocity.x = 0.0
	pl.controllable = false
	pl.idle_aim = Vector2.RIGHT
	for z in main_node.get_tree().get_nodes_in_group("zombies"):   # nobody else around
		if z != cur and not z.dead and not z.is_boss() and absf(z.global_position.x - px) < 1500.0:
			z.queue_free()
	if cur != null:
		cur_t += d
		var dist: float = absf(cur.global_position.x - pl.global_position.x) if is_instance_valid(cur) and not cur.dead else 99999.0
		min_d = minf(min_d, dist)
		if reach_t < 0.0 and dist < REACH:
			reach_t = cur_t
		if cur_t >= per or (reach_t >= 0.0 and cur_t > reach_t + 3.0) or dist >= 99999.0:
			# died on the way = a trap / hazard of the level got it (not the kind's fault)
			var how := ("reach %.1fs" % reach_t) if reach_t >= 0.0 else ("died %.1fs" % cur_t if dist >= 99999.0 else "STOPPED")
			out.append("%d:%s %s min %.0f far_hits %d" % [cur_k, _name(cur_k), how, min_d, far_hits])
			if how == "STOPPED" or far_hits > 0:
				bad.append("%d:%s%s" % [cur_k, _name(cur_k), "" if how == "STOPPED" else " far_hits"])
			if is_instance_valid(cur):
				cur.queue_free()
			cur = null
		return false
	if pending.is_empty():
		print("REACH L%d | %s" % [lv, " | ".join(out)])
		print("REACH L%d BAD %s" % [lv, str(bad)])
		quit()
		return true
	cur_k = pending.pop_front()
	var x: float = flank._spot(px)
	var tries := 0
	while x < 0.0 and tries < 8:   # no room behind here: try another place
		tries += 1
		px += 400.0
		pl.global_position.x = px   # now (the zombie's brain takes the player's position as "last seen" on its first step)
		x = flank._spot(px)
	if x < 0.0:
		out.append("%d:%s NO-SPOT" % [cur_k, _name(cur_k)])
		return false
	if flank.NO_KINDS.has(cur_k):
		out.append("%d:%s no(NO_KINDS)" % [cur_k, _name(cur_k)])
		return false
	cur = flank._flanker(x, cur_k)
	if cur == null:
		out.append("%d:%s no" % [cur_k, _name(cur_k)])
		return false
	cur._dir = 1.0
	cur._alert_t = flank.ALERT
	flank._hunters.append([cur, flank._time + flank.HUNT_T, cur.global_position.x, flank._time])   # like flank._send
	cur_t = 0.0
	reach_t = -1.0
	min_d = 99999.0
	far_hits = 0
	return false
