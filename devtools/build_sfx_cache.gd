extends SceneTree
# Builds res://sounds/sfx_cache.res: every synthesized sound (sfx.gd R, the BANKS, and the SOUNDS of all
# zombie types and stages), already rendered, so the game does not synthesize ~870 sounds at startup.
# Run after adding or changing sounds (a changed recipe still works without it, it is just synthesized live):
#   godot --headless --path <game folder> -s res://build_sfx_cache.gd      (copy this file to the game folder first)
func _initialize() -> void:
	var Sfx = load("res://sfx.gd")
	var t := Time.get_ticks_msec()
	for path in Sfx.BANKS:
		Sfx.register(load(path).SOUNDS)
	Sfx.scan_all()
	var out := {}
	for k in Sfx.R:
		out[k] = [Sfx.recipe_hash(Sfx.R[k]), Sfx._stream(k).data]
	for k in Sfx.EXTRA:
		out[k] = [Sfx.recipe_hash(Sfx.EXTRA[k]), Sfx._stream(k).data]
	var r := Resource.new()
	r.set_meta("sounds", out)
	var err := ResourceSaver.save(r, Sfx.CACHE_PATH, ResourceSaver.FLAG_COMPRESS)
	var bytes := 0
	for k in out:
		bytes += out[k][1].size()
	print("SFX CACHE %d sounds, %.1f MB raw, saved %s err=%d in %d ms" % [out.size(), bytes / 1048576.0, Sfx.CACHE_PATH, err, Time.get_ticks_msec() - t])
	quit()
