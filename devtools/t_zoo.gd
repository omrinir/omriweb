extends SceneTree
# zoo: render every zombie kind frozen in walk + attack poses on neutral + dark backgrounds.
# args: mode out_dir [kinds csv | "all"] [zoom]
#   mode = shot  -> pages at given zoom: out_dir/p_<zoom>_<n>.png
#   mode = prof  -> draw cost per kind (usec per draw), prints PROF lines
var ZS: PackedScene
var ZScript: GDScript
const Reg := preload("res://enemies/zombie_registry.gd")
var M: Node = null
var frames := 0
var mode := "shot"
var out := "/tmp"
var zoom := 1.25
var entries := []   # [kind, boss, big]
var zs := []        # per zombie: [node, entry_idx, pose]
var cam: Camera2D
var pages := []     # rect per page
var page_i := 0
var wait := 0
var phase := 0
var only := []
const BASE := Vector2(0, -20000)
const CW := 100.0
const RH := 140.0
const BCW := 300.0
const BRH := 300.0

class Bg extends Node2D:
	var rects := []
	func _draw() -> void:
		for r in rects:
			draw_rect(r[0], r[1])
			draw_rect(Rect2(r[0].position.x, r[0].end.y - 10, r[0].size.x, 10), r[2])
		for r in rects:
			if r.size() > 3:
				draw_string(ThemeDB.fallback_font, r[0].position + Vector2(4, 12), r[3], HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(1, 1, 1, 0.8) if r[1].v < 0.4 else Color(0, 0, 0, 0.8))

func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	mode = a[0]
	out = a[1]
	if a.size() > 2 and a[2] != "all":
		for s in a[2].split(","):
			only.append(s)
	if a.size() > 3:
		zoom = float(a[3])
	ZS = load("res://zombie.tscn")
	ZScript = load("res://zombie.gd")
	var g = root.get_node("Game")
	g.new_run()
	g.start_practice(5)
	g.level = 5
	M = load("res://main.tscn").instantiate()
	root.add_child(M)
	current_scene = M

func _want(name: String, k: int) -> bool:
	return only.is_empty() or only.has(name) or only.has(str(k))

func _build() -> void:
	# hide everything of the level
	for c in M.get_children():
		if c.is_in_group("zombies"):
			c.queue_free()
		elif c is CanvasItem:
			c.visible = false
		elif c is CanvasLayer:
			c.visible = false
	for n in root.get_children():
		if n != M and n is CanvasLayer:
			n.visible = false
	_hide_mod(root)
	var kinds := []
	for k in 20:
		if k == 11:   # HAND: hidden under water
			pass
		kinds.append([k, false])
		if k in [5, 7, 19]:
			kinds[-1][1] = true
	var ks := Reg.TYPES.keys()
	ks.sort()
	for k in ks:
		var st: Dictionary = Reg.make(k).stats()
		kinds.append([k, bool(st.get("boss", false))])
		# boss variant via chase_range 650
		var m = Reg.make(k)
		var fake := ZS.instantiate()
		fake.chase_range = 650.0
		m.z = fake
		var st2: Dictionary = m.stats()
		if bool(st2.get("boss", false)) and not bool(st.get("boss", false)):
			kinds.append([k, true])
		fake.free()
	for e in kinds:
		var nm := _kname(e[0])
		if not _want(nm, e[0]):
			continue
		entries.append([e[0], e[1], e[1] or e[0] in [2, 13]])
	if OS.get_environment("REPEAT") != "":
		var rep := []
		for e in entries:
			for i in int(OS.get_environment("REPEAT")):
				rep.append(e)
		entries = rep
	# layout: normal pages 10 cols, big pages 3 cols
	var small := entries.filter(func(e): return not e[2])
	var big := entries.filter(func(e): return e[2])
	var bg := Bg.new()
	bg.z_index = -50
	M.add_child(bg)
	var y0 := BASE.y
	var per := 10 if mode == "shot" else 10
	var rows := []
	for i in range(0, small.size(), per):
		rows.append([small.slice(i, i + per), CW, RH])
	for i in range(0, big.size(), 3):
		rows.append([big.slice(i, i + 3), BCW, BRH])
	var y := y0
	for r in rows:
		var list: Array = r[0]
		var cw: float = r[1]
		var rh: float = r[2]
		var w := cw * per if cw == CW else cw * 3.0
		# 4 bands: neutral walk, neutral attack, dark walk, dark attack
		var bands := [[Color(0.55, 0.56, 0.58), Color(0.35, 0.33, 0.3)], [Color(0.55, 0.56, 0.58), Color(0.35, 0.33, 0.3)], [Color(0.07, 0.08, 0.11), Color(0.03, 0.03, 0.04)], [Color(0.07, 0.08, 0.11), Color(0.03, 0.03, 0.04)]]
		var top := y
		for b in 4:
			var rect := Rect2(BASE.x, y, w, rh)
			bg.rects.append([rect, bands[b][0], bands[b][1]])
			var floor_y := y + rh - 10.0
			var body := StaticBody2D.new()
			body.collision_layer = 1
			var cs := CollisionShape2D.new()
			var sh := RectangleShape2D.new()
			sh.size = Vector2(w, 10)
			cs.shape = sh
			cs.position = Vector2(BASE.x + w / 2.0, floor_y + 5.0)
			body.add_child(cs)
			M.add_child(body)
			for i in list.size():
				var e = list[i]
				var x := BASE.x + cw * (float(i) + 0.5)
				if b == 0:
					bg.rects.append([Rect2(x - cw / 2.0, y, cw, 14), Color(0, 0, 0, 0), Color(0, 0, 0, 0), _kname(e[0]) + (" B" if e[1] else "")])
				var z = ZS.instantiate()
				if OS.get_environment("AB") != "" and (b >= 2) != (OS.get_environment("ABSWAP") != ""):
					z.set_script(load("res://zombie_b0.gd"))
				z.kind = e[0]
				if e[1]:
					z.chase_range = 650.0
				z.position = Vector2(x, floor_y)
				M.add_child(z)
				z.position = Vector2(x, floor_y)
				z.dormant = false
				z._dir = 1.0
				z.set_physics_process(false)
				z.set_process(false)
				zs.append([z, x, floor_y, b % 2])
			y += rh
		pages.append(Rect2(BASE.x, top, w, y - top))
		y += 40.0
	cam = Camera2D.new()
	M.add_child(cam)
	cam.make_current()
	print("entries ", entries.size(), " zombies ", zs.size(), " pages ", pages.size())

func _hide_mod(n: Node) -> void:
	for c in n.get_children():
		if c is CanvasModulate:
			c.visible = false
		_hide_mod(c)

func _kname(k: int) -> String:
	if k < 20:
		return ["WALKER", "RUNNER", "BRUTE", "SPITTER", "SCREAMER", "BOSS", "BLOATER", "CONDUCTOR", "CRAWLER", "COP", "RAT", "HAND", "MECH", "HURLER", "IMP", "DOG", "DRUNK", "GUNNER", "JETPACK", "HOUND"][k]
	return Reg.display_name(k)

func _pose() -> void:
	for q in zs:
		var z = q[0]
		if not is_instance_valid(z):
			continue
		if z.kind != 18:
			z.global_position = Vector2(q[1], q[2])
			z.velocity = Vector2(0, 400)
			z.move_and_slide()
		z.global_position = Vector2(q[1], q[2] - (60.0 if z.kind == 18 else 0.0))
		z._dir = 1.0
		z._time = 1.3
		z._flash = -1.0
		z._react_t = -1.0
		z._walk_phase = 1.1
		z._chasing = true
		if z.kind == 11:
			z._grab_state = 1
		if q[3] == 1:
			z._bite_anim = 0.3
			z._attack_t = 0.3
		else:
			z._bite_anim = -1.0
		z.queue_redraw()

func _process(_d: float) -> bool:
	frames += 1
	var pl = M.get_tree().get_first_node_in_group("player")
	if pl != null:
		pl._invuln = 99.0
		pl.visible = false
		pl.global_position = BASE + Vector2(-3000, -200)
	if frames == 4:
		_build()
		return false
	if frames < 10:
		return false
	if frames == 10 or frames == 11:
		_pose()
		return false
	if mode == "prof":
		return _prof()
	# shot pages
	if page_i >= pages.size():
		quit()
		return false
	var r: Rect2 = pages[page_i]
	var vp := Vector2(1280, 720) / zoom
	# sub-tiles if page bigger than view
	var cols := int(ceil(r.size.x / vp.x))
	var rws := int(ceil(r.size.y / vp.y))
	var ti := wait / 3
	if ti >= cols * rws:
		page_i += 1
		wait = 0
		return false
	var cx := ti % cols
	var cy := ti / cols
	cam.zoom = Vector2(zoom, zoom)
	cam.global_position = r.position + Vector2(cx * vp.x, cy * vp.y) + vp / 2.0
	_pose()
	if wait % 3 == 2:
		var img := root.get_viewport().get_texture().get_image()
		img.save_png("%s/p%d_%d_%d.png" % [out, page_i, cx, cy])
	wait += 1
	return false

var pf := 0
const WARM := 30
const RUN := 240
func _prof() -> bool:
	pf += 1
	if pf == 1:
		ZScript.prof_on = true
		if OS.get_environment("AB") != "":
			load("res://zombie_b0.gd").prof_on = true
	if pf == WARM:
		ZScript.prof.clear()
		if OS.get_environment("AB") != "":
			load("res://zombie_b0.gd").prof.clear()
	if OS.get_environment("CROWD") != "":
		ZScript._vis_prev = 999
	for q in zs:
		if is_instance_valid(q[0]):
			q[0]._walk_phase = float(pf) * 0.3
			q[0]._time = float(pf) * 0.05
			q[0].queue_redraw()
	if pf >= WARM + RUN:
		var counts := {}
		var tot := 0
		for q in zs:
			if is_instance_valid(q[0]):
				var n: String = q[0]._prof_name()
				counts[n] = int(counts.get(n, 0)) + RUN
				tot += RUN
		print("PROFDRAWS expected ", tot, " got ", ZScript.prof.get("draws", 0))
		if OS.get_environment("AB") != "":
			var B: GDScript = load("res://zombie_b0.gd")
			for n in counts:
				var a := float(ZScript.prof.get("draw:" + n, 0)) / float(counts[n] / 2)
				var b := float(B.prof.get("draw:" + n, 0)) / float(counts[n] / 2)
				print("PROF\t%s\tbefore %.1f\tafter %.1f\t%+.0f%%" % [n, b, a, 100.0 * (a / maxf(b, 0.01) - 1.0)])
		else:
			for n in counts:
				var us := float(ZScript.prof.get("draw:" + n, 0)) / float(counts[n])
				print("PROF\t%s\t%.1f" % [n, us])
		quit()
	return false
