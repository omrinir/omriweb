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
var darkness := 0.52                # כמה חשוך (0 = בכלל לא). היה 0.62 - זומבים נעלמו בחושך
const PLAYER_GLOW := 130.0          # רדיוס האור סביב השחקן (היה 70)
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
		lights.append(Vector4(pp.x, pp.y, PLAYER_GLOW * zoom, 0.5))   # אור חלש סביב השחקן: רואים זומבים שמתקרבים
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


# רקע: תחנת רכבת תחתית נטושה - 3 שכבות פרלקסה (effects/parallax_backdrop.gd)
#   רחוק: קיר אריחים של הרציף ממול - פס פסיפס, שלטי תחנה, כרזות קרועות, גרפיטי, כתמי רטיבות, קשתות
#   אמצע: עמודי פלדה עם מסמרות ופסי אזהרה, כבלים לאורך הקיר
#   קרוב: נורות פלורסנט תלויות (חלקן מהבהבות) שמאירות כתמים על הקיר
#   overlay: אובך ירקרק בהיר מאחורי הדמויות - שהצלליות הכהות ייקראו גם בחושך
class TunnelBg extends "res://effects/parallax_backdrop.gd":
	const Kit := preload("res://effects/backdrop_kit.gd")
	const HZ := 607.0          # הריצפה על המסך
	const TOP := 128.0         # מתחת לתקרה
	const TILE := Color("3c524a")
	const TILE2 := Color("4a6258")
	const STEEL := Color("23262b")
	const NAMES := ["DEAD END ST.", "CANAL ST.", "14TH AVE", "UNION SQ.", "GRAVE ROW", "NORTH GATE"]

	func _ready() -> void:
		sky = func(ci: CanvasItem, v: Vector2, t: float): _back(ci, v, t)
		add_layer(0.35, func(ci: CanvasItem, sc: float, v: Vector2, t: float): _wall(ci, sc, v, t))
		add_layer(0.6, func(ci: CanvasItem, sc: float, v: Vector2, t: float): _pillars(ci, sc, v, t))
		add_layer(0.8, func(ci: CanvasItem, sc: float, v: Vector2, t: float): _lights(ci, sc, v, t))
		overlay = func(ci: CanvasItem, v: Vector2, t: float): _over(ci, v, t)

	static func _h(i: int, s: int) -> float:
		return fposmod(sin(float(i) * 12.9898 + float(s) * 78.233) * 43758.5453, 1.0)

	static func _back(ci: CanvasItem, v: Vector2, _t: float) -> void:
		Kit.gradient_sky(ci, v, [Color("0c0e10"), Color("161a1c"), Color("1c2422")], 1.0)

	# ---- קיר האריחים ----
	static func _wall(ci: CanvasItem, sc: float, v: Vector2, t: float) -> void:
		var y0 := TOP
		var y1 := HZ - 40.0
		ci.draw_rect(Rect2(0, y0, v.x, y1 - y0), TILE)
		# אריחים: שורות מוסטות, גוון משתנה קצת
		var tw := 44.0
		var th := 22.0
		var off := fposmod(sc, tw * 2.0)
		var row := 0
		var y := y0 + 4.0
		while y < y1:
			var sh := (tw * 0.5) if row % 2 == 1 else 0.0
			var x := -off - sh
			var ix := int(floor((sc - off - sh) / tw))
			while x < v.x:
				var hv := float(posmod((ix * 73856093) ^ (row * 19349663), 100)) * 0.01   # hash שלם (זול יותר מ-sin)
				if hv < 0.3:
					ci.draw_rect(Rect2(x + 1.0, y + 1.0, tw - 2.0, th - 2.0), TILE2)
				elif hv > 0.93:   # אריח שנפל
					ci.draw_rect(Rect2(x + 1.0, y + 1.0, tw - 2.0, th - 2.0), Color("26302c"))
				x += tw
				ix += 1
			ci.draw_line(Vector2(0, y), Vector2(v.x, y), Color(0, 0, 0, 0.25), 1.0)
			y += th
			row += 1
		# פס פסיפס צבעוני + פס בורדו
		ci.draw_rect(Rect2(0, y0 + 98.0, v.x, 16.0), Color("6a2a24"))
		ci.draw_rect(Rect2(0, y0 + 98.0, v.x, 3.0), Color("c8a050"))
		ci.draw_rect(Rect2(0, y0 + 111.0, v.x, 3.0), Color("c8a050"))
		var period := 900.0
		var start := int(floor(sc / period)) - 1
		for k in range(start, start + int(ceil(v.x / period)) + 2):
			var bx := float(k) * period - sc
			# שלט תחנה
			var nm: String = NAMES[posmod(k, NAMES.size())]
			ci.draw_rect(Rect2(bx + 300.0, y0 + 36.0, 190.0, 40.0), Color("10141a"))
			ci.draw_rect(Rect2(bx + 303.0, y0 + 39.0, 184.0, 34.0), Color("1c3e78"))
			ci.draw_string(ThemeDB.fallback_font, Vector2(bx + 316.0, y0 + 64.0), nm, HORIZONTAL_ALIGNMENT_LEFT, 170.0, 19, Color(0.92, 0.92, 0.96, 0.9))
			# כרזות (חלקן קרועות)
			for q in 2:
				var px := bx + 60.0 + float(q) * 560.0
				var py := y0 + 160.0
				var pc: Color = [Color("8a5a2a"), Color("2a5a7a"), Color("7a2a3a"), Color("5a6a2a")][posmod(k * 2 + q, 4)]
				ci.draw_rect(Rect2(px - 4.0, py - 4.0, 128.0, 168.0), Color("1a1c1e"))
				ci.draw_rect(Rect2(px, py, 120.0, 160.0), pc)
				ci.draw_rect(Rect2(px + 10.0, py + 12.0, 100.0, 14.0), Color(1, 1, 1, 0.45))
				ci.draw_circle(Vector2(px + 60.0, py + 80.0), 30.0, Color(0, 0, 0, 0.25))
				ci.draw_rect(Rect2(px + 10.0, py + 126.0, 70.0, 8.0), Color(1, 1, 1, 0.3))
				if _h(k, q + 9) < 0.6:   # קרוע: משולש של קיר
					ci.draw_colored_polygon(PackedVector2Array([Vector2(px + 60, py + 160), Vector2(px + 120, py + 70), Vector2(px + 120, py + 160)]), TILE)
				if _h(k, q + 4) < 0.5:   # "X" אדום של שורדים
					ci.draw_line(Vector2(px + 20, py + 40), Vector2(px + 100, py + 130), Color(0.75, 0.08, 0.06, 0.8), 5.0)
					ci.draw_line(Vector2(px + 100, py + 40), Vector2(px + 20, py + 130), Color(0.75, 0.08, 0.06, 0.8), 5.0)
			# גרפיטי (קווים צבעוניים)
			var gx := bx + 520.0
			var gc := Color(0.3, 0.85, 0.45, 0.55) if k % 2 == 0 else Color(0.95, 0.45, 0.75, 0.5)
			var gp := PackedVector2Array()
			for q in 12:
				gp.append(Vector2(gx + float(q) * 9.0, y0 + 230.0 + sin(float(q) * 1.9 + float(k)) * 16.0))
			ci.draw_polyline(gp, gc, 4.0)
			ci.draw_polyline(gp, Color(0, 0, 0, 0.4), 1.0)
			# כתמי רטיבות שזולגים
			for q in 3:
				var dx := bx + 200.0 + float(q) * 230.0 + 60.0 * _h(k, q)
				ci.draw_rect(Rect2(dx, y0 + 114.0, 18.0, 160.0 + 120.0 * _h(k, q + 2)), Color(0.05, 0.08, 0.06, 0.25))
		# שוליים תחתונים: קיר כהה מעל המסילה
		ci.draw_rect(Rect2(0, y1, v.x, v.y - y1), Color("1a201e"))
		ci.draw_rect(Rect2(0, y1, v.x, 4.0), Color("5a5a50"))

	# ---- עמודי פלדה ----
	static func _pillars(ci: CanvasItem, sc: float, v: Vector2, _t: float) -> void:
		var period := 420.0
		var start := int(floor(sc / period)) - 1
		for k in range(start, start + int(ceil(v.x / period)) + 2):
			var x := float(k) * period - sc
			ci.draw_rect(Rect2(x, TOP - 10.0, 40.0, HZ - TOP + 10.0), STEEL)
			ci.draw_rect(Rect2(x - 6.0, TOP - 10.0, 52.0, 10.0), STEEL.lightened(0.06))
			ci.draw_rect(Rect2(x + 4.0, TOP, 5.0, HZ - TOP), STEEL.lightened(0.12))   # אור על הקצה
			var ry := TOP + 20.0
			while ry < HZ - 20.0:   # מסמרות
				ci.draw_rect(Rect2(x + 29.0, ry - 1.0, 3.0, 3.0), STEEL.lightened(0.2))
				ry += 34.0
			for s in 4:   # פסי אזהרה בתחתית
				ci.draw_rect(Rect2(x, HZ - 100.0 + float(s) * 22.0, 40.0, 11.0), Color(0.75, 0.6, 0.15, 0.7))
			# כבלים שנתלים בין העמודים
			var cab := PackedVector2Array()
			for q in 11:
				var u := float(q) / 10.0
				cab.append(Vector2(x + 40.0 + u * (period - 40.0), TOP + 30.0 + sin(u * PI) * 26.0))
			ci.draw_polyline(cab, Color(0.04, 0.04, 0.05, 0.9), 2.0)

	# ---- נורות פלורסנט תלויות ----
	static func _lights(ci: CanvasItem, sc: float, v: Vector2, t: float) -> void:
		var period := 640.0
		var start := int(floor(sc / period)) - 1
		for k in range(start, start + int(ceil(v.x / period)) + 2):
			var x := float(k) * period - sc + 200.0
			var dead := _h(k, 1) < 0.2
			var on := 0.0 if dead else 1.0
			if not dead and _h(k, 2) < 0.4:   # מהבהבת
				on = 1.0 if fmod(t * 3.0 + float(k) * 1.7, 4.0) > 0.35 and sin(t * 37.0 + float(k)) > -0.7 else 0.15
			ci.draw_line(Vector2(x + 10.0, 0.0), Vector2(x + 10.0, TOP + 8.0), Color(0.05, 0.05, 0.06), 1.5)
			ci.draw_line(Vector2(x + 90.0, 0.0), Vector2(x + 90.0, TOP + 8.0), Color(0.05, 0.05, 0.06), 1.5)
			ci.draw_rect(Rect2(x, TOP + 8.0, 100.0, 8.0), Color("1a1c1e"))
			ci.draw_rect(Rect2(x + 4.0, TOP + 15.0, 92.0, 4.0), Color(0.85, 1.0, 0.92, 0.25 + 0.7 * on))
			if on > 0.1:
				Kit.soft_glow(ci, Vector2(x + 50.0, TOP + 20.0), 180.0, Color(0.7, 0.95, 0.85, 0.22 * on), 0.7)
				ci.draw_colored_polygon(PackedVector2Array([Vector2(x + 4, TOP + 18), Vector2(x + 96, TOP + 18), Vector2(x + 190, HZ), Vector2(x - 90, HZ)]), Color(0.75, 1.0, 0.9, 0.035 * on))

	static func _over(ci: CanvasItem, v: Vector2, _t: float) -> void:
		Kit.haze_band(ci, v, HZ - 230.0, HZ, Color(0.55, 0.72, 0.66, 0.2))
		var c0 := Color(0.0, 0.0, 0.0, 0.45)   # צל מתחת לתקרה (אווירה)
		var c1 := Color(0.0, 0.0, 0.0, 0.0)
		ci.draw_polygon(PackedVector2Array([Vector2(0, TOP), Vector2(v.x, TOP), Vector2(v.x, TOP + 170.0), Vector2(0, TOP + 170.0)]),
			PackedColorArray([c0, c0, c1, c1]))
