extends SceneTree
# CHARACTER MAKER characters test (characters/custom_character.gd + parts.gd).
# Builds test presets in memory (CustomChars.live, kinds 1000+) that together use every part, then:
#   CHAR_MODE=zoo (default): all of them in a row on a light and a dark band, walk + bite poses -> <out>_zoo.png
#   CHAR_MODE=deaths: level 3, spawns them next to the player and kills each one with a different special death
#     (torn in half, headless walk, burst, crawling torso, burned to bones, plain ragdoll) -> <out>_d<frame>.png
#   CHAR_MODE=saved: like zoo, but with the presets saved in res://characters/saved/ (CustomChars.all())
# usage: xvfb-run -a -s "-screen 0 1280x720x24" godot --fixed-fps 60 --path . --rendering-driver opengl3 -s res://t_characters.gd -- <png_prefix>
#        headless (errors only): godot --headless --fixed-fps 60 --path . -s res://t_characters.gd -- none
var CustomChars = null   # characters/custom_characters.gd (loaded in _initialize: its scripts use autoloads)
const Preset := preload("res://characters/character_preset.gd")
const Parts := preload("res://characters/parts.gd")
const LV := 3
var M: Node = null
var f := 0
var out := "none"
var mode := "zoo"
var kinds := []
var zs := []
var cam: Camera2D
const BASE := Vector2(0, -20000)
const CW := 64.0
const RH := 110.0


class Bg extends Node2D:
	var rects := []
	func _draw() -> void:
		for r in rects:
			draw_rect(r[0], r[1])


func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	out = a[0] if a.size() > 0 else "none"
	mode = OS.get_environment("CHAR_MODE") if OS.get_environment("CHAR_MODE") != "" else "zoo"
	CustomChars = load("res://enemies/zombie_registry.gd").custom()
	if mode == "saved":
		for p in CustomChars.all():
			kinds.append(int(p.kind))
	else:
		_make_presets()
	var g = root.get_node("Game")
	g.new_run()
	g.start_practice(LV)
	g.level = LV
	M = load("res://main.tscn").instantiate()
	root.add_child(M)
	current_scene = M


# 14 presets: preset i uses hat i, and cycles the other lists, so every part shows up at least once
func _make_presets() -> void:
	var n := Parts.HATS.size()
	for i in n:
		var p = Preset.new()
		p.kind = 1000 + i
		p.id = "test_%d" % i
		p.name = "TEST %d" % i
		p.build = Parts.BUILDS[i % 3]
		p.hat = Parts.HATS[i]
		p.hair = Parts.HAIRS[i % Parts.HAIRS.size()]
		p.face = Parts.FACES[i % Parts.FACES.size()]
		p.top = Parts.TOPS[i % Parts.TOPS.size()]
		p.item = Parts.ITEMS[(i + 1) % Parts.ITEMS.size()]
		p.extras = PackedStringArray([Parts.EXTRAS[i % Parts.EXTRAS.size()], Parts.EXTRAS[(i + 3) % Parts.EXTRAS.size()]])
		p.gore = PackedStringArray([Parts.GORE[i % Parts.GORE.size()], Parts.GORE[(i + 5) % Parts.GORE.size()]])
		p.head_size = [1.0, 1.2, 0.9, 1.4][i % 4]
		p.height = [1.0, 1.1, 0.9][i % 3]
		p.hunch = float(i % 4) * 2.5
		p.barefoot = i % 5 == 4
		p.skin_color = Color.from_hsv(0.22 + 0.05 * float(i % 5), 0.3, 0.6)
		p.shirt_color = Color.from_hsv(float(i) / float(n), 0.5, 0.5)
		p.hat_color = Color.from_hsv(fposmod(float(i) / float(n) + 0.5, 1.0), 0.6, 0.65)
		p.gear_color = Color.from_hsv(fposmod(float(i) / float(n) + 0.25, 1.0), 0.5, 0.55)
		p.eye_color = [Color("ffd940"), Color("ff3020"), Color("60ff40"), Color("40c0ff")][i % 4]
		CustomChars.live[int(p.kind)] = p
		kinds.append(int(p.kind))


func _physics_process(_d: float) -> bool:
	f += 1
	if mode == "deaths":
		return _deaths()
	return _zoo()


# grid of COLS x rows on a light (CHAR_DARK=1: dark) background, pages of 2 rows at zoom ZOOM -> <out>_zoo<page>.png.
# odd rows of each pair: bite pose
const COLS := 5
const ZOOM := 3.6
var _pages := 0


func _zoo() -> bool:
	if f == 3:
		for c in M.get_children():
			if c.is_in_group("zombies"):
				c.queue_free()
			elif c is CanvasItem or c is CanvasLayer:
				c.visible = false
		for n in root.get_children():
			if n != M and n is CanvasLayer:
				n.visible = false
		var bg := Bg.new()
		bg.z_index = -50
		M.add_child(bg)
		var rows := int(ceil(float(kinds.size()) / float(COLS)))
		var dark := OS.get_environment("CHAR_DARK") != ""
		bg.rects.append([Rect2(BASE.x - 400.0, BASE.y - 400.0, CW * COLS + 800.0, RH * 2.0 * rows + 800.0), Color(0.08, 0.09, 0.12) if dark else Color(0.62, 0.63, 0.65)])
		for i in kinds.size():
			for pose in 2:
				var z = load("res://zombie.tscn").instantiate()
				z.kind = kinds[i]
				var row := (i / COLS) * 2 + pose
				z.position = Vector2(BASE.x + CW * (float(i % COLS) + 0.5), BASE.y + RH * float(row + 1) - 12.0)
				M.add_child(z)
				z.dormant = false
				z.set_physics_process(false)
				zs.append([z, z.position, pose])
		_pages = rows
		cam = Camera2D.new()
		M.add_child(cam)
		cam.make_current()
		cam.zoom = Vector2(ZOOM, ZOOM)
		print("zoo: ", kinds.size(), " characters, pages ", _pages)
	if f > 3:
		for q in zs:
			var z = q[0]
			z.global_position = q[1]
			z._dir = 1.0
			z._time = 1.3
			z._flash = -1.0
			z._walk_phase = 1.1
			z._chasing = false
			z._bite_anim = 0.3 if q[2] == 1 else -1.0
			z.queue_redraw()
	var pg := (f - 6) / 3
	if f >= 6 and (f - 6) % 3 == 0 and pg < _pages:
		cam.position = BASE + Vector2(CW * COLS / 2.0, RH * (2.0 * float(pg) + 1.0))
	if f >= 8 and (f - 8) % 3 == 0 and (f - 8) / 3 < _pages:
		if out != "none":
			var path := "%s_zoo%d.png" % [out, (f - 8) / 3]
			root.get_viewport().get_texture().get_image().save_png(path)
			print("saved ", path)
	if f > 8 + 3 * _pages:
		quit()
	return false


# each one dies a different way
const DEATHS := ["force_tear", "force_hw", "force_burst", "force_crawl", "force_char", ""]


func _deaths() -> bool:
	var pl = M.get_tree().get_first_node_in_group("player")
	if pl == null:
		return false
	pl.health = pl.max_health
	for s in M.get_tree().get_nodes_in_group("story_scene"):
		if s.has_method("_finish"):
			s._finish()
	if f == 5:
		pl.global_position.x = 5600.0
		for z in M.get_tree().get_nodes_in_group("zombies"):
			if absf(z.global_position.x - 5600.0) < 1200.0:
				z.queue_free()
	if f == 60:
		for i in 6:
			var z = M._spawn_zombie(5600.0 + 120.0 + 60.0 * i, pl.global_position.y, kinds[i % kinds.size()], null)
			z.chase_range = 0.0
			if DEATHS[i] != "":
				z.set_meta(DEATHS[i], true)
			zs.append(z)
	if f == 90 and out != "none":
		root.get_viewport().get_texture().get_image().save_png(out + "_alive.png")
	if f == 96:
		for i in zs.size():
			var z = zs[i]
			var md: String = DEATHS[i]
			var hy: float = -52.0 * z.sc if md == "force_hw" else (-8.0 * z.sc if md == "force_crawl" else -30.0 * z.sc)
			z.take_damage(999, z.global_position + Vector2(0, hy), Vector2(1, -0.2), md == "force_burst",
				{"source": "fire" if md == "force_char" else "bullet", "fixed": 999})
			print("kind=%d %s dead=%s rag=%s split=%s hw_t=%.2f gibbed=%s char=%s legless=%s" % [z.kind, md, str(z.dead), str(z._rag != null),
				str(z._rag != null and z._rag.split), z._hw_t, str(z._gibbed), str(z._char != null), str(z._legless)])
	if f > 96 and (f - 96) in [6, 20, 45, 90] and out != "none":
		root.get_viewport().get_texture().get_image().save_png("%s_d%d.png" % [out, f - 96])
		print("saved %s_d%d.png" % [out, f - 96])
	if f >= 96 + 200:
		quit()
	return false
