extends "res://environment/platform.gd"
# ============================================================
#  רצפה מתמוטטת (שלב 6): קטע סדוק של הקומה השנייה.
#  השחקן עומד עליה -> היא חורקת ורועדת CREAK_TIME שניות (אבק + צליל) -> קורסת:
#  חתיכות בטון נופלות, והזומבים שמתחת נפגעים (אפשר לנצל את זה!).
#  אחרי הקריסה נשאר חור קבוע (הסולמות ממשיכים לעבוד).
#  שימוש: כמו platform.gd (position = פינה שמאלית-עליונה, size = רוחב x עובי).
# ============================================================

const Sfx := preload("res://sfx.gd")
const Particles := preload("res://particles.gd")
const DebrisScript := preload("res://debris.gd")

const CREAK_TIME := 0.7
const CRUSH_DAMAGE := 18

var collapsed := false
var _creak := 0.0
var _creak_snd := 0.0
var _t := 0.0


func _ready() -> void:
	super._ready()
	add_to_group("s6_collapse")


func _physics_process(delta: float) -> void:
	if collapsed:
		return
	_t += delta
	var p := get_tree().get_first_node_in_group("player")
	var on := false
	if p != null and not p.dead and p.is_on_floor():
		var pp: Vector2 = p.global_position
		on = pp.x > global_position.x - 6.0 and pp.x < global_position.x + size.x + 6.0 and absf(pp.y - global_position.y) < 6.0
	if on:
		_creak += delta
		_creak_snd -= delta
		if _creak_snd <= 0.0:
			_creak_snd = 0.35
			Sfx.play("s6_creak", global_position + Vector2(size.x * 0.5, 0), -2.0, 0.15, 2)
			Particles.burst(get_parent(), global_position + Vector2(randf_range(0.0, size.x), size.y), "smoke", Vector2.DOWN, 2)
		if _creak >= CREAK_TIME:
			collapse()
			return
	else:
		_creak = maxf(_creak - delta * 0.5, 0.0)
	if _creak > 0.0 or Engine.get_physics_frames() % 10 == 0:
		queue_redraw()


func collapse() -> void:
	if collapsed:
		return
	collapsed = true
	remove_from_group("platforms")
	for c in get_children():
		if c is CollisionShape2D:
			c.set_deferred("disabled", true)
	var base := global_position
	Sfx.play("s6_crumble", base + Vector2(size.x * 0.5, 0), 3.0)
	for i in 12:
		var d = DebrisScript.new()
		get_parent().add_child(d)
		d.setup(base + Vector2(randf_range(0.0, size.x), randf_range(0.0, size.y)), Vector2(randf_range(5.0, 12.0), randf_range(4.0, 9.0)),
			Color("6e6a64").lerp(Color("3a3836"), randf()), Vector2(randf_range(-90.0, 90.0), randf_range(-60.0, 120.0)))
	for i in 3:
		Particles.burst(get_parent(), base + Vector2(size.x * (0.2 + 0.3 * float(i)), size.y + 10.0), "smoke", Vector2.DOWN, 5)
	# זומבים שמתחת נפגעים מהבטון שנופל
	for z in get_tree().get_nodes_in_group("zombies"):
		if z.dead:
			continue
		var zp: Vector2 = z.global_position
		if zp.x > base.x - 10.0 and zp.x < base.x + size.x + 10.0 and zp.y > base.y + 20.0 and zp.y - base.y < 220.0:
			z.take_damage(CRUSH_DAMAGE, zp + Vector2(0, -40), Vector2.DOWN, true, {"source": "debris"})
	var cam := get_viewport().get_camera_2d()
	if cam != null and cam.has_method("shake"):
		cam.shake(8.0, 0.35)
	queue_redraw()


func _draw() -> void:
	var w := size.x
	var h := size.y
	if collapsed:   # נשארו רק בדלים שבורים בקצוות + ברזלים תלויים
		for e in [0.0, w]:
			var sgn := 1.0 if e == 0.0 else -1.0
			draw_colored_polygon(PackedVector2Array([Vector2(e, 0), Vector2(e + sgn * 14.0, 2), Vector2(e + sgn * 8.0, h), Vector2(e, h)]), Color("4e4a46"))
			for k in 3:
				draw_line(Vector2(e + sgn * 4.0, 4 + k * 3), Vector2(e + sgn * (12.0 + k * 5.0), h + 6.0 + k * 6.0), Color("6a4a3a"), 1.2)
		return
	var shake := 0.0
	if _creak > 0.0:
		shake = sin(_t * 70.0) * 1.6 * (_creak / CREAK_TIME)
	draw_set_transform(Vector2(shake, 0.0), 0.0, Vector2.ONE)
	super._draw()
	# סדקים גדולים + אריחים חסרים: סימן אזהרה שהקטע הזה לא יציב
	var r := RandomNumberGenerator.new()
	r.seed = _seed + 7
	for i in int(w / 24.0):
		var cx := r.randf_range(4.0, w - 4.0)
		var pts := PackedVector2Array([Vector2(cx, 0)])
		var y := 0.0
		while y < h:
			y += r.randf_range(3.0, 6.0)
			pts.append(Vector2(cx + r.randf_range(-5, 5), minf(y, h)))
		draw_polyline(pts, Color(0.1, 0.09, 0.08, 0.9), 1.2)
	for i in 3:
		draw_rect(Rect2(r.randf_range(4.0, w - 20.0), 0, r.randf_range(8.0, 16.0), 3), Color("2a2826"))
	draw_set_transform_matrix(Transform2D.IDENTITY)
