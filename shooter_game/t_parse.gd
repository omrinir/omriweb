extends SceneTree
func _walk(d: String, out: Array) -> void:
	var da := DirAccess.open(d)
	for f in da.get_files():
		if f.ends_with(".gd") and not f.begins_with("t_"):
			out.append(d.path_join(f))
	for sd in da.get_directories():
		if not sd.begins_with(".") and sd != "build":
			_walk(d.path_join(sd), out)
func _initialize():
	var files := []
	_walk("res://", files)
	var bad := 0
	for f in files:
		var s = load(f)
		if s == null or not s.can_instantiate():
			print("FAIL ", f)
			bad += 1
	print("checked ", files.size(), " bad ", bad)
	quit()
