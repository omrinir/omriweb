extends RefCounted
# ============================================================
#  DYN LIGHTS - אורות שזזים (פנס של השחקן וכו') לכל שכבות החושך.
#  כל צומת בקבוצה "dyn_lights" עם lights() -> [[מיקום בעולם, רדיוס, עוצמה], ...].
#  משתמשים: subway.gd, effects/s11_decor.gd (NightOverlay), effects/s14_decor.gd (StormOverlay).
#  gather() מחזיר [רשימת Vector4 למסך, האם השחקן מואר (= הזומבים רואים אותו)].
# ============================================================

static func gather(tree: SceneTree, ct: Transform2D, zoom: float, player: Node2D) -> Array:
	var out := []
	var lit := false
	for n in tree.get_nodes_in_group("dyn_lights"):
		if not n.has_method("lights"):
			continue
		for l in n.lights():
			var wp: Vector2 = l[0]
			var sp: Vector2 = ct * wp
			out.append(Vector4(sp.x, sp.y, float(l[1]) * zoom, float(l[2])))
			if player != null and float(l[2]) > 0.3 and player.global_position.distance_to(wp) < float(l[1]):
				lit = true
	return [out, lit]


# מכניס את האורות הדינמיים לתחילת הרשימה (שלא ייחתכו) ומקצץ לגודל המערך של ה-shader
static func merge(dyn: Array, lights: Array, size: int) -> Array:
	var all := dyn.duplicate()
	all.append_array(lights)
	if all.size() > size:
		all.resize(size)
	while all.size() < size:
		all.append(Vector4(0, 0, 1, 0))
	return all
