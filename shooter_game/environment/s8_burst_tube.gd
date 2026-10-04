extends "res://environment/hazard.gd"
# ============================================================
#  צינור כליאה שמתפוצץ (שלב 8). גליל זכוכית עם נוזל ירוק ו"נבדק" צף בפנים.
#    שלם   - בועות עולות, הנבדק זז קצת.
#    CRACK - השחקן (או זומבי שנזרק עליו) מתקרב: סדקים מתפשטים + שריקת לחץ (CRACK_TIME שניות
#            = אזהרה הוגנת, אפשר לברוח).
#    BURST - הזכוכית מתנפצת: שברים, התזה ירוקה, שלולית חומצה זמנית (environment/acid_pool.gd),
#            נזק למי שעומד קרוב (שחקן וזומבים). לפעמים הנבדק בורח (main._spawn_zombie, עם מגבלה).
#  בזמן CRACK והשנייה הראשונה אחרי הפיצוץ זומבים חכמים לא מתקרבים (danger_at).
#  לשנות: TRIGGER_DIST, CRACK_TIME, BLAST_R, release_kind (-1 = בלי נבדק), stage.specimen_cap.
# ============================================================
const Art := preload("res://art.gd")
const Sfx := preload("res://sfx.gd")
const AcidPool := preload("res://environment/acid_pool.gd")
const DebrisScript := preload("res://debris.gd")

const TRIGGER_DIST := 105.0
const CRACK_TIME := 1.0
const BLAST_R := 85.0
const H := 118.0

var release_kind := -1        # איזה זומבי יוצא מהצינור (-1 = הנבדק מת)
var stage: Node = null        # levels/stage_8.gd (מגבלת נבדקים שבורחים)
var burst := false
var _crack := -1.0            # >= 0: נסדק עכשיו
var _post := 0.0
var _t := 0.0
var _seed := 0
var _bubbles := []


func _ready() -> void:
	super._ready()
	rect = Rect2(-BLAST_R, -H, BLAST_R * 2.0, H)
	player_damage = 0          # הנזק ניתן פעם אחת בפיצוץ
	active = false
	z_index = -1
	_seed = int(position.x)
	_t = randf() * 10.0
	for i in 6:
		_bubbles.append([randf_range(-12.0, 12.0), randf()])


func danger_at(p: Vector2, margin := 0.0) -> bool:
	return (_crack >= 0.0 or _post > 0.0) and world_rect().grow(margin).has_point(p)


func trigger() -> void:
	if not burst and _crack < 0.0:
		_crack = 0.0
		Sfx.play("glass", global_position + Vector2(0, -60), -6.0, 0.1, 2)
		Sfx.play("s8_hiss", global_position + Vector2(0, -60), -2.0, 0.1, 2)


func _hazard_tick(delta: float) -> void:
	_t += delta
	_post -= delta
	var vis := Art.on_screen(self, global_position, 160.0)
	if not burst:
		for b in _bubbles:
			b[1] = fmod(float(b[1]) + delta * 0.35, 1.0)
		if _crack < 0.0 and Engine.get_physics_frames() % 8 == 0:
			var p := get_tree().get_first_node_in_group("player")
			if p != null and not p.dead:
				var pp: Vector2 = p.global_position
				if absf(pp.x - global_position.x) < TRIGGER_DIST and absf(pp.y - global_position.y) < 140.0:
					trigger()
		if _crack >= 0.0:
			_crack += delta
			if _crack >= CRACK_TIME:
				_burst()
	if vis and (Engine.get_physics_frames() % 2 == 0 or _crack >= 0.0):
		queue_redraw()


func _burst() -> void:
	burst = true
	_crack = -1.0
	_post = 1.0
	var c := global_position + Vector2(0, -H * 0.5)
	Sfx.play("glass", c, 2.0)
	Sfx.play("splat", c, 0.0)
	for i in 14:   # שברי זכוכית
		var d = DebrisScript.new()
		get_parent().add_child(d)
		d.setup(c + Vector2(randf_range(-18, 18), randf_range(-40, 40)), Vector2(randf_range(2, 6), randf_range(2, 5)), Color(0.7, 0.9, 0.95, 0.8), Vector2(randf_range(-260, 260), -randf_range(60, 320)))
	var fx = load("res://particles.gd").new()   # התזה ירוקה
	get_parent().add_child(fx)
	fx.global_position = c
	fx.z_index = 12
	for i in 22:
		var a := randf() * TAU
		fx._p.append([Vector2.ZERO, Vector2.from_angle(a) * randf_range(80, 300) + Vector2(0, -120), 0.0, randf_range(0.4, 0.8), randf_range(2.0, 3.5), Color(0.5, 1.0, 0.3, 0.85)])
	var pool = AcidPool.new()
	pool.setup(150.0, 6.0)
	pool.position = position
	get_parent().add_child(pool)
	var cam := get_viewport().get_camera_2d()
	if cam != null and cam.has_method("shake"):
		cam.shake(5.0, 0.3)
	var p := get_tree().get_first_node_in_group("player")
	if p != null and not p.dead and (p.global_position as Vector2).distance_to(c) < BLAST_R + 20.0:
		p.hurt(1, Vector2(signf(p.global_position.x - global_position.x), 0.0))
	for z in get_tree().get_nodes_in_group("zombies"):
		if not z.dead and (z.global_position as Vector2).distance_to(global_position) < BLAST_R:
			z.take_damage(15, z.global_position + Vector2(0, -20), Vector2.UP, true, {"source": "hazard"})
	# הנבדק בורח (עם מגבלה לכל השלב)
	if release_kind >= 0 and stage != null and stage.specimens_left > 0 and stage.main != null:
		stage.specimens_left -= 1
		var nz: Node = stage.main._spawn_zombie(global_position.x, global_position.y, release_kind, null)
		if nz != null:
			nz._alert_t = 6.0
			nz._popup("!", Color(0.5, 1.0, 0.3), 22, -80.0)
	queue_redraw()


func _draw() -> void:
	var r := 22.0
	var top := -H
	# בסיס ומכסה מתכת
	draw_rect(Rect2(-r - 6, -14, r * 2 + 12, 14), Color("2a3036"))
	draw_rect(Rect2(-r - 6, -14, r * 2 + 12, 3), Color("4a5258"))
	draw_rect(Rect2(-r - 6, top - 12, r * 2 + 12, 12), Color("2a3036"))
	for i in 3:   # צינורות מהמכסה למעלה
		draw_line(Vector2(-12 + i * 12, top - 12), Vector2(-12 + i * 12 + (i - 1) * 6, top - 40), Color("1c2024"), 3.0)
	if burst:   # שארית: זכוכית שבורה + שאריות נוזל
		var stub := PackedVector2Array([Vector2(-r, -14), Vector2(-r, -40), Vector2(-r + 7, -28), Vector2(-r + 12, -48), Vector2(-r + 18, -30), Vector2(-4, -22), Vector2(-4, -14)])
		draw_colored_polygon(stub, Color(0.6, 0.85, 0.9, 0.35))
		var stub2 := PackedVector2Array([Vector2(6, -14), Vector2(6, -26), Vector2(12, -36), Vector2(16, -24), Vector2(r, -44), Vector2(r, -14)])
		draw_colored_polygon(stub2, Color(0.6, 0.85, 0.9, 0.35))
		var tstub := PackedVector2Array([Vector2(-r, top), Vector2(r, top), Vector2(r, top + 20), Vector2(8, top + 8), Vector2(-6, top + 26), Vector2(-r, top + 12)])
		draw_colored_polygon(tstub, Color(0.6, 0.85, 0.9, 0.3))
		draw_rect(Rect2(-r, -18, r * 2, 4), Color(0.4, 0.9, 0.3, 0.6))
		return
	# נוזל + נבדק צף
	var lv := top + 10.0
	draw_rect(Rect2(-r, lv, r * 2, -14 - lv), Color(0.25, 0.75, 0.35, 0.55))
	var bob := sin(_t * 0.9) * 3.0
	var sp := Vector2(0, -60 + bob)
	draw_colored_polygon(PackedVector2Array([sp + Vector2(-6, -24), sp + Vector2(6, -24), sp + Vector2(8, 10), sp + Vector2(3, 30), sp + Vector2(-3, 30), sp + Vector2(-8, 10)]), Color(0.12, 0.22, 0.16, 0.85))
	draw_circle(sp + Vector2(0, -30), 7.0, Color(0.12, 0.22, 0.16, 0.85))
	draw_line(sp + Vector2(-6, -18), sp + Vector2(-14, 4 + bob), Color(0.12, 0.22, 0.16, 0.85), 3.0)
	draw_line(sp + Vector2(6, -18), sp + Vector2(13, 2 - bob), Color(0.12, 0.22, 0.16, 0.85), 3.0)
	draw_line(sp + Vector2(0, -37), Vector2(0, top), Color(0.1, 0.1, 0.1, 0.6), 1.0)   # כבל מהראש
	for b in _bubbles:
		var k: float = b[1]
		draw_circle(Vector2(float(b[0]), lerpf(-16.0, lv + 4.0, k)), 1.5 + k, Color(0.8, 1.0, 0.8, 0.6 * (1.0 - k)))
	# זכוכית: השתקפויות
	draw_rect(Rect2(-r, top, r * 2, H - 14), Color(0.6, 0.85, 0.95, 0.12))
	draw_line(Vector2(-r + 5, top + 4), Vector2(-r + 5, -20), Color(1, 1, 1, 0.3), 2.0)
	draw_line(Vector2(-r, top), Vector2(-r, -14), Color(0.7, 0.85, 0.9, 0.6), 1.5)
	draw_line(Vector2(r, top), Vector2(r, -14), Color(0.7, 0.85, 0.9, 0.6), 1.5)
	Art.glow(self, Vector2(0, -60), 40.0, Color(0.4, 1.0, 0.4, 0.12))
	# סדקים מתפשטים (אזהרה)
	if _crack >= 0.0:
		var k := clampf(_crack / CRACK_TIME, 0.0, 1.0)
		var rr := RandomNumberGenerator.new()
		rr.seed = _seed
		for i in 6:
			var c0 := Vector2(rr.randf_range(-r * 0.6, r * 0.6), rr.randf_range(-90, -30))
			var pts := PackedVector2Array([c0])
			var cp := c0
			for j in 4:
				cp += Vector2(rr.randf_range(-9, 9), rr.randf_range(-12, 12)) * k
				pts.append(cp)
			draw_polyline(pts, Color(1, 1, 1, 0.8), 1.0)
		var shake := sin(_crack * 50.0) * 2.0 * k
		draw_rect(Rect2(-r + shake, top, r * 2, H - 14), Color(1.0, 0.3, 0.2, 0.1 * k))
		var jet := k * 30.0   # נוזל מתיז מסדק
		draw_line(Vector2(r, -50), Vector2(r + jet, -40 + jet * 0.4), Color(0.5, 1.0, 0.3, 0.8), 2.0)
