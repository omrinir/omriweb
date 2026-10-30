extends SceneTree
# CORPSE AUDIT (test only): for every zombie kind, do its plain (non-ragdoll) corpses stop being redrawn once they lie still?
# A body that keeps changing (an idle animation by z._time, random jitter, wind...) is redrawn for its whole corpse time,
# and a mass kill then costs dozens of extra draws every frame. zombie.gd draws corpses with the time of death and stops
# redrawing after 3 identical draws (_corpse_redraw); a type whose dead body should keep moving returns true in corpse_anim().
# Per kind: 6 spawned next to the player on level 55, all killed in one frame, checked AFTER frames later.
# usage: godot --headless --fixed-fps 60 --path . -s res://t_corpse_audit.gd -- <kinds csv | all | a-b>
# env: CA_AFTER=<frames after the kill, default 230>, CA_DBG=1 (prints the state of the corpses still being redrawn)
# A new zombie type should come out "still" (plain == still) or "MOVING" only when its body moves on purpose.
var Reg = null
var ArtS = null
var kinds := []
var main_node: Node
var pl: Node
var f := 0
var ki := -1
var pf := 0
var phase := "boot"
var zs := []
const WAIT := 30
var AFTER := 230


func _initialize() -> void:
	Reg = load("res://enemies/zombie_registry.gd")
	ArtS = load("res://art.gd")
	if OS.get_environment("CA_AFTER") != "":
		AFTER = int(OS.get_environment("CA_AFTER"))
	var a := OS.get_cmdline_user_args()
	var sel: String = a[0] if a.size() > 0 else "all"
	var all := []
	for k in 20:
		all.append(k)
	var ks: Array = Reg.TYPES.keys()
	ks.sort()
	all.append_array(ks)
	if sel == "all":
		kinds = all
	elif sel.contains("-") and not sel.contains(","):
		var r := sel.split("-")
		for k in all:
			if k >= int(r[0]) and k <= int(r[1]):
				kinds.append(k)
	else:
		for s in sel.split(","):
			kinds.append(int(s))
	var g = root.get_node("Game")
	g.new_run()
	g.level = 55
	main_node = load("res://main.tscn").instantiate()
	root.add_child(main_node)
	current_scene = main_node


func _name(k: int) -> String:
	if k < 20:
		return ["WALKER", "RUNNER", "BRUTE", "SPITTER", "SCREAMER", "BOSS", "BLOATER", "CONDUCTOR", "CRAWLER", "COP", "RAT", "HAND", "MECH", "HURLER", "IMP", "DOG", "DRUNK", "GUNNER", "JETPACK", "HOUND"][k]
	return Reg.display_name(k)


func _process(_d: float) -> bool:
	f += 1
	pf += 1
	root.get_node("Quality").level = 0
	pl = main_node.get_tree().get_first_node_in_group("player")
	if pl == null:
		return false
	pl.health = pl.max_health
	if "_invuln" in pl:
		pl._invuln = 1.0
	for s in main_node.get_tree().get_nodes_in_group("story_scene"):
		if s.has_method("_finish"):
			s._finish()
	match phase:
		"boot":
			if f == 60:
				for z in main_node.get_tree().get_nodes_in_group("zombies"):
					z.queue_free()
			if f == 100:
				_next()
		"alive":
			if pf == WAIT:
				for z in zs:
					if is_instance_valid(z) and not z.dead:
						z.take_damage(99999, z.global_position + Vector2(0.0, -40.0 * float(z.sc)), Vector2(1.0, -0.2), false, {"source": "bullet", "fixed": 99999, "shot": f})
					if is_instance_valid(z) and not z.dead:   # מגן / שריון מלפנים: פיצוץ מאחור
						z.take_damage(99999, z.global_position + Vector2(0.0, -40.0 * float(z.sc)), Vector2(-1.0, -0.2), true, {"source": "explosive", "fixed": 99999, "shot": f + 1})
					if is_instance_valid(z) and not z.dead:   # עדיין חי (שלב של בוס וכו'): מוות ישיר
						z.hp = 0
						z._die(Vector2(1.0, -0.2))
				phase = "after"
				pf = 0
		"after":
			if pf == AFTER:
				var nr := 0
				var still := 0
				var rag := 0
				var other := 0
				for z in zs:
					if not is_instance_valid(z):
						other += 1
					elif not z.dead:
						other += 1
					elif z._rag != null:
						rag += 1
					elif z._hw_t > 0.0 or z._char != null or not z.visible or not ArtS.on_screen(z, z.global_position):   # (מחוץ למסך / מוסתרת: לא מצוירת בכלל)
						other += 1
					else:
						nr += 1
						if z._c_same >= 2:
							still += 1
						elif OS.get_environment("CA_DBG") != "":
							print("   still redrawn: floor=%s ang=%.4f spin=%.3f vel=%s dead_t=%.2f land=%.2f" % [z.is_on_floor(), z._angle, z._spin, z.velocity.round(), z._dead_t, z._land_t])
				print("CA k=%d %-18s plain %d still %d | ragdoll %d gone/hidden/off-screen %d %s" % [kinds[ki], _name(kinds[ki]), nr, still, rag, other, "MOVING" if nr > still else ""])
				for z in main_node.get_tree().get_nodes_in_group("zombies"):
					z.queue_free()
				for z in zs:
					if is_instance_valid(z):
						z.queue_free()
				phase = "clean"
				pf = 0
		"clean":
			if pf == 20:
				_next()
	return false


func _next() -> void:
	ki += 1
	if ki >= kinds.size():
		print("CA done")
		quit()
		return
	zs.clear()
	var k: int = kinds[ki]
	for i in 6:
		var z = main_node._spawn_zombie(pl.global_position.x + 200.0 + float(i) * 70.0, pl.global_position.y, k)
		if z != null:
			z.dormant = false
			zs.append(z)
	phase = "alive"
	pf = 0
