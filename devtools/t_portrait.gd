extends SceneTree
# portrait: one character at a time, frozen and big, on white then black (difference matte -> alpha) for promo art.
# env: PORT_OUT=<dir>  PORT_LIST="name:kind[:k=v,k=v...];..."  PORT_LEVEL (default 5)
#   kind = zombie number or name, HERO, SURV<variant>
#   opts: boss=1, pose=walk|attack, dir=1|-1, zoom=<f> (default 7), cy=<f> (camera y above the feet, default 36),
#         wp=<walk phase>, tm=<_time>, gun=<weapon_db id> (HERO), ax/ay (HERO aim), any other key = a type_mod variable
# out: <name>_w.png (white) + <name>_k.png (black), 2560x1440 when run with --resolution 2560x1440
const Reg := preload("res://enemies/zombie_registry.gd")
const BASE := Vector2(0, -20000)
var ZS: PackedScene
var M: Node
var frames := 0
var items := []
var idx := 0
var step := 0
var cur: Node = null
var cam: Camera2D
var bg: Bg
var out := "/tmp"

class Bg extends Node2D:
	var col := Color.WHITE
	func _draw() -> void:
		draw_rect(Rect2(-60000, -60000, 120000, 120000), col)

func _initialize() -> void:
	out = OS.get_environment("PORT_OUT")
	for spec in OS.get_environment("PORT_LIST").split(";", false):
		var p := spec.split(":")
		var it := {"name": p[0], "kind": p[1], "opt": {}}
		if p.size() > 2:
			for kv in p[2].split(",", false):
				it.opt[kv.get_slice("=", 0)] = kv.get_slice("=", 1)
		items.append(it)
	ZS = load("res://zombie.tscn")
	var g = root.get_node("Game")
	g.new_run()
	var lv := int(OS.get_environment("PORT_LEVEL")) if OS.get_environment("PORT_LEVEL") != "" else 5
	g.start_practice(lv)
	g.level = lv
	M = load("res://main.tscn").instantiate()
	root.add_child(M)
	current_scene = M

func _hide_mod(n: Node) -> void:
	for c in n.get_children():
		if c is CanvasModulate:
			c.visible = false
		_hide_mod(c)

func _build() -> void:
	for c in M.get_children():
		if c.is_in_group("zombies") or c.is_in_group("survivors"):
			c.queue_free()
		elif c.is_in_group("player"):
			pass
		elif c is CanvasItem or c is CanvasLayer:
			c.visible = false
	for n in root.get_children():
		if n != M and n is CanvasLayer:
			n.visible = false
	for n in M.get_tree().get_nodes_in_group("monologue"):
		n.queue_free()
	_hide_mod(root)
	bg = Bg.new()
	bg.z_index = -4000
	M.add_child(bg)
	var body := StaticBody2D.new()
	body.collision_layer = 1
	var cs := CollisionShape2D.new()
	var sh := RectangleShape2D.new()
	sh.size = Vector2(4000, 20)
	cs.shape = sh
	cs.position = BASE + Vector2(0, 10)
	body.add_child(cs)
	M.add_child(body)
	cam = Camera2D.new()
	M.add_child(cam)
	cam.make_current()

func _opt(k: String, d):
	var o: Dictionary = items[idx].opt
	if not o.has(k):
		return d
	return float(o[k]) if typeof(d) == TYPE_FLOAT else int(o[k]) if typeof(d) == TYPE_INT else o[k]

func _kind(s: String) -> int:
	if s.is_valid_int():
		return int(s)
	var small := ["WALKER", "RUNNER", "BRUTE", "SPITTER", "SCREAMER", "BOSS", "BLOATER", "CONDUCTOR", "CRAWLER", "COP", "RAT", "HAND", "MECH", "HURLER", "IMP", "DOG", "DRUNK", "GUNNER", "JETPACK", "HOUND"]
	if s in small:
		return small.find(s)
	for k in Reg.TYPES.keys():
		if Reg.display_name(k) == s:
			return k
	return 0

func _player() -> Node:
	return M.get_tree().get_first_node_in_group("player")

func _spawn() -> void:
	var it: Dictionary = items[idx]
	var k: String = it.kind
	var pl := _player()
	if k == "HERO":
		cur = pl
		pl.visible = true
		pl.global_position = BASE
		pl.velocity = Vector2.ZERO
		var g: int = _opt("gun", 1)
		pl.slots[0] = {"id": g, "ammo": 999, "mag": 99}
		pl.select_slot(0)
		return
	if k.begins_with("SURV"):
		var sv = load("res://survivor.gd").new()
		sv.variant = int(k.substr(4))
		sv.position = BASE
		sv.drain_range = 0.0
		M.add_child(sv)
		sv.world_w = float(M.level_w)
		cur = sv
		return
	var z = ZS.instantiate()
	z.kind = _kind(k)
	if _opt("boss", 0) == 1:
		z.chase_range = 650.0
	z.position = BASE
	M.add_child(z)
	z.position = BASE
	z.dormant = false
	z._dir = float(_opt("dir", 1))
	cur = z

func _pose(first: bool) -> void:
	var it: Dictionary = items[idx]
	var pl := _player()
	if cur != pl:
		pl.visible = false
		pl.global_position = BASE + Vector2(-3000, -400)
		pl._invuln = 99.0
	if cur == pl:
		pl._aim = Vector2(_opt("ax", 1.0), _opt("ay", -0.05)).normalized()
		pl._invuln = 0.0
		if not first:
			pl.set_process(false)
			pl.set_physics_process(false)
		pl.queue_redraw()
		return
	if it.kind.begins_with("SURV"):
		cur.global_position = BASE
		if not first:
			cur.set_process(false)
			cur.set_physics_process(false)
		cur.queue_redraw()
		return
	var z = cur
	z.set_physics_process(false)
	z.set_process(false)
	z.global_position = BASE + Vector2(0, -2)
	z.velocity = Vector2(0, 400)
	z.move_and_slide()
	z._dir = float(_opt("dir", 1))
	z._time = _opt("tm", 1.3)
	z._flash = -1.0
	z._react_t = -1.0
	z._walk_phase = _opt("wp", 1.1)
	z._chasing = true
	if str(_opt("pose", "walk")) == "attack":
		z._bite_anim = 0.3
		z._attack_t = 0.3
	else:
		z._bite_anim = -1.0
	if z.type_mod != null:
		for key in it.opt:
			if key in ["boss", "pose", "dir", "zoom", "cy", "wp", "tm", "gun", "ax", "ay", "cx"]:
				continue
			if key in z.type_mod:
				z.type_mod.set(key, float(it.opt[key]) if str(it.opt[key]).is_valid_float() else it.opt[key])
	z.queue_redraw()

func _process(_d: float) -> bool:
	frames += 1
	if frames == 4:
		_build()
		return false
	if frames < 10:
		var pl := _player()
		if pl != null:
			pl._invuln = 99.0
		return false
	if idx >= items.size():
		quit()
		return false
	for c in M.get_children():   # pop-ups (HELP!, score), bubbles: only the portrait + the background stay
		if c is CanvasItem and c != cur and c != bg and c != cam and c != _player() and c.visible:
			c.visible = false
	for n in M.get_tree().get_nodes_in_group("cine_hide"):
		if n is CanvasItem:
			n.visible = false
	var z := _opt("zoom", 7.0) as float
	cam.zoom = Vector2(z, z)
	cam.global_position = BASE + Vector2(_opt("cx", 0.0), -_opt("cy", 36.0))
	match step:
		0:
			_spawn()
		1, 2, 3:
			_pose(step < 3)
		4:
			bg.col = Color.WHITE
			bg.queue_redraw()
		7:
			root.get_viewport().get_texture().get_image().save_png("%s/%s_w.png" % [out, items[idx].name])
			bg.col = Color.BLACK
			bg.queue_redraw()
		10:
			root.get_viewport().get_texture().get_image().save_png("%s/%s_k.png" % [out, items[idx].name])
			print("PORTRAIT ", items[idx].name)
			if cur != _player():
				cur.queue_free()
			else:
				cur.visible = false
				cur.set_process(true)
				cur.set_physics_process(true)
			cur = null
			idx += 1
			step = -1
	step += 1
	return false
