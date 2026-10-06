extends Node2D
const DynLights := preload("res://effects/dyn_lights.gd")
const Sfx := preload("res://sfx.gd")   # אפקטים קוליים
# ============================================================
#  עולם הרכבת התחתית (שלבים זוגיים). main.gd יוצר אותו.
#  * תקרה (אפשר להיתפס בה עם וו הקרס, זוחלים הולכים עליה)
#  * מים עד הקרסול: מאטים, ניתזים, והטייזר חזק בהם פי 3
#  * פסים מחושמלים: זומבי שנכנס אליהם מתחשמל
#  * רכבת רפאים: מדי פעם אזהרה ואז רכבת שדורסת את מי שעל הריצפה
#  * חושך: רק ליד מנורות רואים. שוברים מנורה = חושך,
#    אבל גם הזומבים רואים אותך פחות
# ============================================================

const Particles := preload("res://particles.gd")

var floor_y := 630.0
var ceil_y := 250.0                 # התחתית של התקרה
var level_w := 10240.0
var darkness := 0.62                # כמה חשוך (0 = בכלל לא)
var train_every := Vector2(70.0, 110.0)   # רכבת רפאים: נדיר
var train_speed := 1700.0
var train_len := 1100.0

var rails := []                     # קטעים מחושמלים [x0, x1]
var _train_t := 45.0                # שניות עד הרכבת הבאה
var _warn_t := 0.0                  # אזהרה לפני הרכבת
var _train_x := INF                 # קצה שמאל של הרכבת (INF = אין רכבת)
var _train_hit := false
var _time := 0.0
var _drops := []                    # טיפות מים [מיקום, מהירות, חיים]
var _splash_t := 0.0
var _zap_t := {}                    # זומבי -> מתי חושמל לאחרונה
var _overlay: ColorRect
var _warn: WarnFx


func _ready() -> void:
	z_index = 3
	# תקרה פיזית (לוו הקרס ולחסימת קפיצות)
	var body := StaticBody2D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	var cs := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = Vector2(level_w, 200.0)
	cs.shape = r
	cs.position = Vector2(level_w * 0.5, ceil_y - 100.0)
	body.add_child(cs)
	add_child(body)
	# ציור התקרה והפסים בחתיכות של 1024 (מצויר פעם אחת)
	var x := 0.0
	while x < level_w:
		var c := Chunk.new()
		c.sub = self
		c.position = Vector2(x, 0.0)
		get_parent().add_child.call_deferred(c)
		x += 1024.0
	# חושך + אזהרת רכבת (על המסך)
	var layer := CanvasLayer.new()
	layer.layer = 1
	add_child(layer)
	_overlay = ColorRect.new()
	_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var mat := ShaderMaterial.new()
	mat.shader = Shader.new()
	mat.shader.code = DARK_SHADER
	_overlay.material = mat
	layer.add_child(_overlay)
	_warn = WarnFx.new()
	_warn.sub = self
	layer.add_child(_warn)


# קטעי פסים מחושמלים (לא בבורות ולא בהתחלה)
func make_rails(rng: RandomNumberGenerator, pits: Array, safe: float) -> void:
	for i in 3:
		var x0 := rng.randf_range(safe + 300.0, level_w - 900.0)
		var ok := true
		for p in pits:
			if x0 + 260.0 > float(p[0]) - 60.0 and x0 < float(p[0]) + float(p[1]) + 60.0:
				ok = false
		if ok:
			rails.append([x0, x0 + rng.randf_range(160.0, 260.0)])


const DARK_SHADER := """
shader_type canvas_item;
uniform float darkness = 0.6;
uniform vec4 lights[10];   // x, y (פיקסלים), רדיוס, עוצמה
uniform vec2 vp_size = vec2(1280.0, 720.0);
void fragment() {
	vec2 p = SCREEN_UV * vp_size;
	float lit = 0.0;
	for (int i = 0; i < 10; i++) {
		vec4 l = lights[i];
		if (l.w <= 0.0) continue;
		vec2 d = (p - l.xy) / vec2(l.z, l.z * 1.6);
		lit = max(lit, l.w * (1.0 - smoothstep(0.35, 1.0, length(d))));
	}
	COLOR = vec4(0.0, 0.0, 0.02, darkness * (1.0 - lit));
}
"""


func _physics_process(delta: float) -> void:
	_time += delta
	var tree := get_tree()
	var player := tree.get_first_node_in_group("player")
	var vp := get_viewport()
	var ct := vp.get_canvas_transform()
	var view := ct.affine_inverse() * vp.get_visible_rect()
	# ---- חושך: אור סביב כל מנורה שעובדת + קצת סביב השחקן ----
	var lights := []
	var zoom := ct.get_scale().x
	var dark := true
	for lp in tree.get_nodes_in_group("lamps"):
		if lp._broken or absf(lp.global_position.x - view.get_center().x) > view.size.x:
			continue
		var hp: Vector2 = lp.global_position + lp.head()
		var mid := Vector2(hp.x, (hp.y + floor_y) * 0.5 + 30.0)
		if lights.size() < 9:
			lights.append(Vector4((ct * mid).x, (ct * mid).y, 170.0 * zoom, 0.9 * lp._on))
		if player != null and absf(player.global_position.x - hp.x) < 150.0 and lp._on > 0.5:
			dark = false
	if player != null:
		var pp: Vector2 = ct * (player.global_position + Vector2(0.0, -30.0))
		lights.append(Vector4(pp.x, pp.y, 70.0 * zoom, 0.55))
	var dyn: Array = DynLights.gather(tree, ct, zoom, player)   # פנס של השחקן
	lights = DynLights.merge(dyn[0], lights, 10)
	Game.player_dark = dark and not dyn[1]
	var m: ShaderMaterial = _overlay.material
	m.set_shader_parameter("lights", lights)
	m.set_shader_parameter("darkness", darkness)
	m.set_shader_parameter("vp_size", vp.get_visible_rect().size)

	# ---- מים: השחקן מואט וניתז ----
	if player != null:
		player.in_water = player.global_position.y > floor_y - 4.0
		_splash_t -= delta
		if player.in_water and player.is_on_floor() and absf(player.velocity.x) > 120.0 and _splash_t <= 0.0:
			_splash_t = 0.09
			for i in 3:
				_drops.append([player.global_position + Vector2(randf_range(-8, 8), -2.0), Vector2(-player.velocity.x * randf_range(0.1, 0.3) + randf_range(-30, 30), -randf_range(80, 170)), 0.6])
	for d in _drops:
		d[1].y += 900.0 * delta
		d[0] += d[1] * delta
		d[2] -= delta
	_drops = _drops.filter(func(d): return d[2] > 0.0 and d[0].y < floor_y + 2.0)

	# ---- פסים מחושמלים ----
	for z in tree.get_nodes_in_group("zombies"):
		if z.dead or not z.is_on_floor() or z.global_position.y < floor_y - 4.0:
			continue
		for rl in rails:
			if z.global_position.x > rl[0] and z.global_position.x < rl[1] and _time - float(_zap_t.get(z, -9.0)) > 0.5:
				_zap_t[z] = _time
				z._popup("ZAP", Color("a0c8ff"), 16, -90.0)
				Sfx.play("zap", z.global_position, -2.0, 0.15, 3)
				z.take_damage(10, z.global_position + Vector2(0, -20), Vector2.UP, true, {"source": "rail"})
				Particles.burst(get_parent(), z.global_position, "fire", Vector2.UP, 6)

	# ---- רכבת רפאים ----
	if _train_x == INF:
		_train_t -= delta
		if _train_t <= 0.0 and _warn_t <= 0.0:
			_warn_t = 2.2
			Sfx.play("horn", null, 2.0, 0.0)
			_train_t = randf_range(train_every.x, train_every.y)
		if _warn_t > 0.0:
			_warn_t -= delta
			if _warn_t <= 0.0:
				_train_x = view.end.x + 80.0
				Sfx.play("train", null, 4.0, 0.0)
				_train_hit = false
				var cam := vp.get_camera_2d()
				if cam != null and cam.has_method("shake"):
					cam.shake(6.0, 1.2)
	else:
		_train_x -= train_speed * delta
		var x0 := _train_x
		var x1 := _train_x + train_len
		for z in tree.get_nodes_in_group("zombies"):
			# הרכבת פוגעת רק בזוחלים שעל התקרה: נופלים עליה ומתים
			if not z.dead and z.on_ceiling and z.global_position.x > x0 and z.global_position.x < x1:
				z._drop_down()
				z._popup("SPLAT", Color("ff5040"), 18, -70.0)
				z.take_damage(999, z.global_position + Vector2(0, -30), Vector2.LEFT, true, {"source": "train"})
		if x1 < view.position.x - 100.0:
			_train_x = INF
	queue_redraw()
	_warn.queue_redraw()


func _draw() -> void:
	var vp := get_viewport()
	var view := vp.get_canvas_transform().affine_inverse() * vp.get_visible_rect()
	var x0 := view.position.x - 10.0
	var x1 := view.end.x + 10.0
	# מים: שכבה שקופה + גלים שזזים
	draw_rect(Rect2(x0, floor_y - 5.0, x1 - x0, 7.0), Color(0.25, 0.35, 0.3, 0.55))
	var x := floorf(x0 / 40.0) * 40.0
	while x < x1:
		var off := sin(_time * 2.0 + x * 0.05) * 8.0
		draw_line(Vector2(x + off, floor_y - 5.0), Vector2(x + off + 16.0, floor_y - 5.0), Color(0.75, 0.9, 0.85, 0.3), 1.0)
		x += 40.0
	for d in _drops:
		draw_circle(d[0], 1.4, Color(0.7, 0.85, 0.85, 0.7))
	# ניצוצות על הפסים המחושמלים
	for rl in rails:
		if rl[1] < x0 or rl[0] > x1:
			continue
		for i in 3:
			if randf() < 0.5:
				var sx: float = randf_range(rl[0], rl[1])
				var s := Vector2(sx, floor_y - 4.0)
				for k in 3:
					draw_line(s, s + Vector2.from_angle(randf_range(-PI, 0.0)) * randf_range(4.0, 12.0), Color(0.7, 0.85, 1.0, 0.9), 1.2)
	# רכבת רפאים (שקופה וזוהרת)
	if _train_x != INF:
		var tx := _train_x
		var h := 150.0
		var top := floor_y - h
		var ghost := Color(0.55, 0.9, 0.8, 0.45)
		draw_rect(Rect2(tx, top, train_len, h - 6.0), Color(0.12, 0.2, 0.2, 0.55))
		draw_rect(Rect2(tx, top, train_len, h - 6.0), ghost, false, 2.0)
		draw_rect(Rect2(tx, top + 52.0, train_len, 6.0), Color(0.9, 0.3, 0.25, 0.5))   # פס אדום
		var wx := tx + 30.0
		while wx < tx + train_len - 40.0:   # חלונות מוארים
			draw_rect(Rect2(wx, top + 14.0, 44.0, 30.0), Color(0.85, 1.0, 0.8, 0.35 + 0.15 * sin(_time * 30.0 + wx)))
			wx += 66.0
		draw_circle(Vector2(tx + 10.0, top + 90.0), 9.0, Color(1.0, 1.0, 0.8, 0.9))   # פנס קדמי
		draw_rect(Rect2(tx - 260.0, top + 70.0, 260.0, 40.0), Color(1.0, 1.0, 0.8, 0.08))


# אזהרה על המסך: אור אדום מהבהב בצד ימין + טקסט
class WarnFx extends Node2D:
	var sub: Node

	func _draw() -> void:
		if sub._warn_t <= 0.0:
			return
		var vs := get_viewport().get_visible_rect().size
		var on := int(sub._warn_t * 6.0) % 2 == 0
		var a := 0.35 if on else 0.12
		for i in 8:
			draw_rect(Rect2(vs.x - 20.0 * float(i + 1), 0, 20.0, vs.y), Color(1.0, 0.1, 0.05, a * (1.0 - float(i) / 8.0)))
		if on:
			var f := ThemeDB.fallback_font
			draw_string(f, Vector2(vs.x * 0.5 - 140.0, 120.0), "!! TRAIN INCOMING !!", HORIZONTAL_ALIGNMENT_LEFT, -1, 30, Color(1.0, 0.3, 0.2))
			draw_string(f, Vector2(vs.x * 0.5 - 120.0, 150.0), "GET OFF THE TRACKS", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(1, 1, 1, 0.8))


# חתיכת תקרה + פסים (1024 פיקסלים, מצויר פעם אחת)
class Chunk extends Node2D:
	var sub: Node

	func _ready() -> void:
		z_index = -2

	func _draw() -> void:
		var w := 1024.0
		var cy: float = sub.ceil_y
		var fy: float = sub.floor_y
		var rng := RandomNumberGenerator.new()
		rng.seed = int(position.x) + 77
		# תקרת בטון
		draw_rect(Rect2(0, cy - 140.0, w, 140.0), Color("1c1d20"))
		draw_rect(Rect2(0, cy - 10.0, w, 10.0), Color("2a2b2f"))
		draw_line(Vector2(0, cy), Vector2(w, cy), Color(0, 0, 0, 0.8), 2.0)
		var x := 0.0
		while x < w:   # קורות
			draw_rect(Rect2(x, cy - 30.0, 14.0, 30.0), Color("26272b"))
			draw_rect(Rect2(x, cy - 2.0, 14.0, 6.0), Color("303136"))
			x += 128.0
		# צינורות ונטיפות
		draw_line(Vector2(0, cy - 20.0), Vector2(w, cy - 20.0), Color("3a3328"), 5.0)
		draw_line(Vector2(0, cy - 12.0), Vector2(w, cy - 12.0), Color("2c3a34"), 3.0)
		for i in 6:
			var dx := rng.randf_range(0.0, w)
			draw_line(Vector2(dx, cy + 4.0), Vector2(dx, cy + rng.randf_range(6.0, 18.0)), Color(0.3, 0.4, 0.3, 0.5), 1.5)
		# פסי רכבת על הריצפה
		for rl in sub.rails:
			var a := maxf(float(rl[0]) - position.x, 0.0)
			var b := minf(float(rl[1]) - position.x, w)
			if b > a:   # פס שלישי מחושמל: צהוב-שחור
				draw_rect(Rect2(a, fy - 6.0, b - a, 5.0), Color("c8a020"))
				var sx := a
				while sx < b:
					draw_line(Vector2(sx, fy - 6.0), Vector2(sx + 6.0, fy - 1.0), Color(0, 0, 0, 0.8), 2.0)
					sx += 14.0
		draw_line(Vector2(0, fy - 2.0), Vector2(w, fy - 2.0), Color("5a5650"), 2.0)
		x = 0.0
		while x < w:   # אדנים
			draw_rect(Rect2(x, fy - 1.0, 18.0, 4.0), Color("3a2e24"))
			x += 36.0


# רקע: קיר מנהרה עם אריחים, עמודים וכרזות (פרלקסה)
class TunnelBg extends Node2D:
	var level_w := 10240.0
	var _last_x := INF

	func _process(_d: float) -> void:
		var cam := get_viewport().get_camera_2d()
		if cam == null:
			return
		var cx := cam.get_screen_center_position().x
		if absf(cx - _last_x) > 0.5:
			_last_x = cx
			queue_redraw()

	func _draw() -> void:
		var vs := get_viewport().get_visible_rect().size
		var cx := 0.0 if _last_x == INF else _last_x
		draw_rect(Rect2(Vector2.ZERO, vs), Color("121316"))
		# קיר אריחים (זז לאט)
		var off := fmod(cx * 0.45, 48.0)
		draw_rect(Rect2(0, 230, vs.x, 330), Color("23302c"))
		var x := -off
		while x < vs.x:
			draw_line(Vector2(x, 230), Vector2(x, 560), Color(0, 0, 0, 0.25), 1.0)
			x += 48.0
		var y := 230.0
		while y < 560.0:
			draw_line(Vector2(0, y), Vector2(vs.x, y), Color(0, 0, 0, 0.25), 1.0)
			y += 24.0
		draw_rect(Rect2(0, 330, vs.x, 14), Color("6a2a24"))   # פס צבע על הקיר
		# כרזות ושלטים
		var poff := fmod(cx * 0.45, 900.0)
		for i in 3:
			var px := float(i) * 900.0 - poff + 200.0
			draw_rect(Rect2(px, 380, 120, 80), Color("3a3430"))
			draw_rect(Rect2(px + 6, 386, 108, 68), Color("5a4a3a"))
			draw_rect(Rect2(px + 14, 396, 60, 8), Color(0.8, 0.7, 0.5, 0.4))
			draw_rect(Rect2(px + 300, 250, 160, 36), Color("1a3a6a"))   # שלט תחנה
			draw_string(ThemeDB.fallback_font, Vector2(px + 314, 276), "DEAD END ST.", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(0.9, 0.9, 0.95, 0.8))
		# עמודים (קרובים יותר = זזים מהר יותר)
		var coff := fmod(cx * 0.8, 380.0)
		x = -coff
		while x < vs.x + 40.0:
			draw_rect(Rect2(x, 200, 34, 400), Color("2b2c30"))
			draw_rect(Rect2(x, 200, 6, 400), Color("34353a"))
			x += 380.0
		# צל בתחתית
		for i in 6:
			draw_rect(Rect2(0, 560 + float(i) * 12.0, vs.x, 12.0), Color(0, 0, 0, 0.15 + float(i) * 0.1))
