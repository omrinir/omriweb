extends SceneTree
# ESCAPE horde draw cost (levels/events/escape.gd _draw_b): CPU time to build one frame of the horde,
# with its front at 25% / 55% / 98% of the screen (98% = the most figures on screen).
# usage: godot --headless --fixed-fps 60 --path . -s res://t_horde_bench.gd -- [level]   (an ESCAPE level: 11, 23, 41, 55)
# 2026-10-24 (container): old drawing 1.0-2.6 ms per frame, 6.6k-12.9k vertices; new 0.3-0.7 ms, 4.7k-9.2k vertices.
const DrawBatch := preload("res://effects/draw_batch.gd")
var f := 0
var main_node: Node = null
var esc: Node = null


func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	var g = root.get_node("Game")
	g.new_run()
	g.level = int(a[0]) if a.size() > 0 else 55
	main_node = load("res://main.tscn").instantiate()
	root.add_child(main_node)
	current_scene = main_node


func _physics_process(_d: float) -> bool:
	f += 1
	var p = main_node.get_tree().get_first_node_in_group("player")
	if p == null:
		return false
	p.health = p.max_health
	if esc == null:
		for n in main_node.get_children():
			if n.get_script() != null and str(n.get_script().resource_path).ends_with("events/escape.gd"):
				esc = n
	if f == 330:
		if esc == null:
			print("no ESCAPE event on this level")
			quit()
			return false
		p.global_position.x = esc._trigger_x + 20.0   # the horde rises
	if f == 420:
		var v: Rect2 = esc._view()
		var w: Node2D = esc._world
		var rid := w.get_canvas_item()
		for where in [0.25, 0.55, 0.98]:
			esc._hx = v.position.x + v.size.x * where
			DrawBatch.begin(w)
			esc._draw_b()
			var nv := DrawBatch._pts.size()
			DrawBatch._flush()
			DrawBatch._ci = null
			RenderingServer.canvas_item_clear(rid)
			var t0 := Time.get_ticks_usec()
			for i in 300:
				esc._anim += 1.0 / 60.0
				DrawBatch.begin(w)
				esc._draw_b()
				DrawBatch._flush()
				DrawBatch._ci = null
				RenderingServer.canvas_item_clear(rid)
			print("HORDE front at %.2f of the screen: %.0f us per frame, %d vertices" % [where, (Time.get_ticks_usec() - t0) / 300.0, nv])
		quit()
	return false
