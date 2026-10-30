extends RefCounted
const DrawBatch := preload("res://effects/draw_batch.gd")
const Sfx := preload("res://sfx.gd")   # אפקטים קוליים
# ============================================================
#  פיצוץ משותף: רימון, חביות נפץ ומכוניות משתמשים באותו פיצוץ.
#  Boom.blast(...) פוגע בכל מה שבטווח, מרעיד את המצלמה
#  ויוצר את אפקט האש והעשן.
# ============================================================


# center = מרכז הפיצוץ, radius = טווח, break_radius = לבנים קרובות מזה נשברות מיד,
# damage = נזק לזומבים, player_damage = נזק לשחקן (אם הוא קרוב)
static var _next_blast := 1


# source = מה התפוצץ ("grenade" / "barrel" / "car") - משמש לניקוד ולגביעים
static func blast(parent: Node2D, center: Vector2, radius := 120.0, break_radius := 70.0, damage := 40, player_damage := 2, source := "grenade") -> void:
	var tree := parent.get_tree()
	_next_blast += 1
	var src := {"source": source, "blast": _next_blast}
	Game.make_noise(center, 700.0)   # פיצוץ מעיר את כל הזומבים מסביב
	Sfx.play("explosion", center, 3.0, 0.12, 4)
	preload("res://effects/toxic_mist.gd").poke(tree, center, radius)   # הערפל החי (שלבים 2, 4) נדחף החוצה
	# לבנים, מכוניות, חביות...
	for b in tree.get_nodes_in_group("blastable"):
		if b.has_method("hit_by_blast") and b.has_method("blast_rect"):
			var r: Rect2 = b.blast_rect()
			var cp := Vector2(clampf(center.x, r.position.x, r.end.x), clampf(center.y, r.position.y, r.end.y))
			if center.distance_to(cp) <= radius:
				b.hit_by_blast(center, break_radius)
	for z in tree.get_nodes_in_group("zombies"):
		var zc: Vector2 = z.global_position + Vector2(0, -32)
		if center.distance_to(zc) <= radius:
			z.take_damage(damage, zc, (zc - center).normalized(), true, src)
	for sv in tree.get_nodes_in_group("survivors"):
		var sc: Vector2 = sv.global_position + Vector2(0, -26)
		if center.distance_to(sc) <= radius:
			sv.take_damage(damage, sc, (sc - center).normalized(), true)
	var p := tree.get_first_node_in_group("player")
	if p != null:
		var pc: Vector2 = p.global_position + Vector2(0, -26)
		if center.distance_to(pc) <= radius * 0.6:
			p.hurt(player_damage, Vector2(signf(pc.x - center.x), 0.0))
	var cam := parent.get_viewport().get_camera_2d()
	if cam != null and cam.has_method("shake"):
		cam.shake(16.0, 0.45)
	# על הריצפה? אז האש והעשן הולכים רק למעלה ולצדדים
	var q := PhysicsRayQueryParameters2D.create(center, center + Vector2(0.0, 24.0), 1)
	var on_ground := not parent.get_world_2d().direct_space_state.intersect_ray(q).is_empty()
	var fx = Explosion.new()   # אש, ניצוצות, עשן (effects/boom_fx.gd)
	fx.radius = radius
	fx.on_ground = on_ground
	parent.add_child(fx)
	fx.global_position = center


# אפקט הפיצוץ: 3 סגנונות חלקיקים שמתחלפים באקראי (effects/boom_fx.gd).
# Boom.Explosion.new() + radius / on_ground (לפני add_child) - גם hauler.gd ו-shearer.gd משתמשים בזה ישירות.
const Explosion := preload("res://effects/boom_fx.gd")
