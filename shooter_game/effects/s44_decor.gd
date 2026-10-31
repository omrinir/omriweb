extends RefCounted
const DrawBatch := preload("res://effects/draw_batch.gd")
# ============================================================
#  קישוטים לשלב 44 ("THE DAM") - סכר איטאיפו על נהר הפרנה (גבול ברזיל-פרגוואי). אזור חמישי, שלב 8.
#  אימפריית המתים תפסה את תחנת הכוח הגדולה ביבשת כדי להפעיל את מכונת המלחמה. הקרב על דרך הכתר של הסכר.
#    dam_sky        - (רקע) שמיים אפורים-כחולים עם ערפל מים, מטוסי תובלה חוצים (מצנחנים)
#    far_river      - (רקע) עמק הפרנה, גבעות ירוקות, קווי מתח גבוה עם עמודים
#    mid_dam        - (רקע) חזית הסכר: מקטעי בטון עם תומכות, צינורות הלחץ, ערוץ השפך עם מים לבנים וערפל
#    near_parapet   - (רקע) מעקה הבטון של הכתר, עמודי תאורה, כבלים
#    CrestGround    - (עולם) דרך הכתר: אספלט, פס צהוב, מעקה
#    Gantry         - (עולם) עגורן שער ענק על הכתר (הקומה = add_floor)
#    Surge          - (עולם, מלכודת) שערי השפך נפתחים: צופר + אור כתום (WARN_T) -> גל מים שוטף את הכתר בקטע: דוחף, נזק, מפיל זומבים.
#                     חיילי האימפריה יודעים - עולים על העגורנים / יוצאים מהקטע. עלו על העגורן!
#    Transformer    - (עולם, מלכודת) שנאי: מזמזם, נטען (CHARGE_T - ניצוצות) ואז קשת חשמל לכל מה שבטווח R (נזק + סחרור). ירי בו = פריקה מוקדמת.
#    DropZone       - (עולם) מטוס תובלה עובר: מצנחנים קופצים מאחוריך (PARATROOPER) כשאתה עובר את הנקודה
#    Obstacle       - (מוצק + מחסה) "jersey" מחסום בטון / "cable_drum" תוף כבלים / "valve" שסתום ענק
#    DamFX          - (מסך) רסס מים וערפל
#  לשנות: Surge.CYCLE / WARN_T / PUSH / DMG, Transformer.CYCLE / CHARGE_T / R, DropZone.N.
# ============================================================

const Art := preload("res://art.gd")
const Kit := preload("res://effects/backdrop_kit.gd")
const E := preload("res://enemies/empire_kit.gd")


static func _h(i: int, s: int) -> float:
	return fposmod(sin(float(i) * 12.9898 + float(s) * 78.233) * 43758.5453, 1.0)


static func dam_sky(ci: CanvasItem, v: Vector2, t: float) -> void:
	Kit.gradient_sky(ci, v, [Color("4a5868"), Color("6a7a88"), Color("98a6ae"), Color("c0c8c8")], 0.9)
	Kit.clouds(ci, t * 4.0, v, t, v.y * 0.18, Color(0.85, 0.88, 0.9, 0.35), 3, 6.0)
	# מטוס תובלה עם מצנחנים
	var per := 26.0
	var k := fposmod(t, per) / per
	var px := -200.0 + k * (v.x + 400.0)
	var py := v.y * 0.14
	DrawBatch.colored_polygon(ci, PackedVector2Array([Vector2(px - 50, py), Vector2(px + 46, py - 4), Vector2(px + 54, py), Vector2(px + 46, py + 6), Vector2(px - 50, py + 5)]), Color("2a3038"))
	DrawBatch.line(ci, Vector2(px - 10, py), Vector2(px + 10, py - 30), Color("2a3038"), 4.0)
	DrawBatch.line(ci, Vector2(px - 10, py), Vector2(px + 10, py + 30), Color("2a3038"), 4.0)
	DrawBatch.line(ci, Vector2(px - 48, py), Vector2(px - 56, py - 14), Color("2a3038"), 3.0)
	for q in 4:   # מצנחים שנפתחו מאחור
		var age := k * per - float(q) * 1.4
		if age > 0.5 and age < 10.0:
			var cx := px - 80.0 - age * 34.0 - float(q) * 10.0
			var cy := py + age * 26.0
			DrawBatch.colored_polygon(ci, Art.ellipse(Vector2(cx, cy), 9.0, 5.0, 0.0, 10), Color(0.8, 0.2, 0.18, 0.85))
			DrawBatch.line(ci, Vector2(cx - 8, cy + 2), Vector2(cx, cy + 14), Color(0.2, 0.2, 0.2, 0.7), 0.8)
			DrawBatch.line(ci, Vector2(cx + 8, cy + 2), Vector2(cx, cy + 14), Color(0.2, 0.2, 0.2, 0.7), 0.8)
			DrawBatch.circle(ci, Vector2(cx, cy + 15), 1.8, Color(0.15, 0.15, 0.15, 0.8))


# ---- העמק והנהר ----
static func far_river(ci: CanvasItem, sc: float, v: Vector2, y: float, t: float) -> void:
	var hills := PackedVector2Array()
	hills.append(Vector2(0, v.y))
	var x := -40.0
	while x <= v.x + 40.0:
		var wx := x + sc
		hills.append(Vector2(x, y - 120.0 - sin(wx * 0.004) * 40.0 - sin(wx * 0.011) * 18.0))
		x += 40.0
	hills.append(Vector2(v.x, v.y))
	DrawBatch.colored_polygon(ci, hills, Color("4a6450"))
	DrawBatch.rect(ci, Rect2(0, y - 40.0, v.x, v.y - y + 40.0), Color("5a7a88"))   # הנהר
	for q in 8:
		var rx := fposmod(float(q) * 170.0 - sc * 0.5 + t * 10.0, v.x + 80.0) - 40.0
		DrawBatch.line(ci, Vector2(rx, y - 30.0 + float(q % 3) * 8.0), Vector2(rx + 40.0, y - 30.0 + float(q % 3) * 8.0), Color(0.9, 0.95, 1.0, 0.25), 1.5)
	var period := 600.0
	var start := int(floor(sc / period)) - 1
	for k in range(start, start + int(ceil(v.x / period)) + 2):   # עמודי מתח גבוה
		var px := float(k) * period - sc + 200.0
		var py := y - 150.0 - sin((px + sc) * 0.004) * 40.0
		DrawBatch.line(ci, Vector2(px - 18, py + 80), Vector2(px, py - 30), Color("3a4048"), 2.0)
		DrawBatch.line(ci, Vector2(px + 18, py + 80), Vector2(px, py - 30), Color("3a4048"), 2.0)
		DrawBatch.line(ci, Vector2(px - 22, py - 10), Vector2(px + 22, py - 10), Color("3a4048"), 2.0)
		DrawBatch.line(ci, Vector2(px - 16, py + 10), Vector2(px + 16, py + 10), Color("3a4048"), 1.5)
		var nx := px + period
		var ny := y - 150.0 - sin((nx + sc) * 0.004) * 40.0
		for w in 2:
			var pts := PackedVector2Array()
			for i in 9:
				var u := float(i) / 8.0
				pts.append(Vector2(lerpf(px, nx, u), lerpf(py - 10.0 + float(w) * 20.0, ny - 10.0 + float(w) * 20.0, u) + sin(u * PI) * 26.0))
			DrawBatch.polyline(ci, pts, Color(0.2, 0.22, 0.25, 0.6), 1.0)


# ---- חזית הסכר וערוץ השפך ----
static func mid_dam(ci: CanvasItem, sc: float, v: Vector2, y: float, t: float) -> void:
	var top := y - 300.0
	DrawBatch.rect(ci, Rect2(0, top, v.x, v.y - top), Color("8a8c88"))
	# מרקם בטון: קווי יציקה אופקיים, כתמי רטיבות שזולגים מהכתר, טחב בתחתית (הקיר היה אפור שטוח)
	var ly := top + 34.0
	while ly < y:
		DrawBatch.rect(ci, Rect2(0, ly, v.x, 2.0), Color(0.3, 0.31, 0.3, 0.18))
		ly += 38.0
	var sp := 70.0
	var ss := int(floor(sc / sp)) - 1
	for k in range(ss, ss + int(ceil(v.x / sp)) + 2):
		var x := float(k) * sp - sc + _h(k, 4) * 40.0
		var ln := 60.0 + _h(k, 5) * 200.0
		DrawBatch.rect(ci, Rect2(x, top, 6.0 + _h(k, 6) * 12.0, ln), Color(0.25, 0.27, 0.26, 0.16))
		DrawBatch.rect(ci, Rect2(x + 2.0, top, 3.0, ln * 0.6), Color(0.2, 0.22, 0.2, 0.14))
	Kit.haze_band(ci, v, y - 110.0, y, Color(0.32, 0.4, 0.3, 0.2))
	var c0 := Color(0.0, 0.0, 0.0, 0.3)
	var c1 := Color(0.0, 0.0, 0.0, 0.0)
	DrawBatch.polygon(ci, PackedVector2Array([Vector2(0, top), Vector2(v.x, top), Vector2(v.x, top + 60.0), Vector2(0, top + 60.0)]), PackedColorArray([c0, c0, c1, c1]))   # צל מתחת לכתר
	var period := 220.0
	var start := int(floor(sc / period)) - 1
	for k in range(start, start + int(ceil(v.x / period)) + 2):
		var x := float(k) * period - sc
		DrawBatch.rect(ci, Rect2(x, top, 60.0, v.y - top), Color("7a7c78"))   # תומכה (buttress)
		DrawBatch.rect(ci, Rect2(x + 60.0, top, 4.0, v.y - top), Color("6a6c68"))
		DrawBatch.rect(ci, Rect2(x + 90.0, top + 40.0, 26.0, y - top - 40.0), Color("5a5c58"))   # צינור לחץ
		DrawBatch.rect(ci, Rect2(x + 94.0, top + 40.0, 6.0, y - top - 40.0), Color("6e706c"))
		if posmod(k, 5) == 2:   # ערוץ שפך עם מים לבנים
			var cx := x + 130.0
			DrawBatch.rect(ci, Rect2(cx, top, 80.0, v.y - top), Color("5a6a74"))
			for q in 10:
				var wy := top + fposmod(t * 120.0 + float(q) * 40.0, v.y - top)
				DrawBatch.line(ci, Vector2(cx + 6.0 + float(q % 4) * 18.0, wy), Vector2(cx + 6.0 + float(q % 4) * 18.0, wy + 30.0), Color(0.95, 0.97, 1.0, 0.7), 3.0)
			Art.glow(ci, Vector2(cx + 40.0, y - 10.0), 70.0, Color(1, 1, 1, 0.25))
		if posmod(k, 4) == 1:
			E.banner(ci, Vector2(x + 30.0, top + 10.0), 40.0, 160.0, t + float(k))
	DrawBatch.rect(ci, Rect2(0, top - 12.0, v.x, 12.0), Color("9a9c98"))
	E.emblem(ci, Vector2(fposmod(800.0 - sc, 1600.0), top + 80.0), 36.0)


# ---- מעקה הכתר ----
static func near_parapet(ci: CanvasItem, sc: float, v: Vector2, y: float, t: float) -> void:
	var period := 300.0
	var start := int(floor(sc / period)) - 1
	for k in range(start, start + int(ceil(v.x / period)) + 2):
		var x := float(k) * period - sc
		DrawBatch.rect(ci, Rect2(x, y - 40.0, 300.0, 40.0), Color("6a6c6a"))
		DrawBatch.rect(ci, Rect2(x, y - 44.0, 300.0, 5.0), Color("7a7c7a"))
		DrawBatch.line(ci, Vector2(x + 150.0, y - 44.0), Vector2(x + 150.0, y - 150.0), Color("3a3c40"), 3.0)   # עמוד תאורה
		DrawBatch.line(ci, Vector2(x + 150.0, y - 150.0), Vector2(x + 172.0, y - 154.0), Color("3a3c40"), 2.0)
		Art.glow(ci, Vector2(x + 174.0, y - 152.0), 14.0, Color(1.0, 0.95, 0.8, 0.25))
	DrawBatch.rect(ci, Rect2(0, y, v.x, v.y - y), Color("4a4c4a"))


# ============================================================
#  עולם
# ============================================================
class CrestGround extends Node2D:
	var w := 1024.0
	var depth := 90.0

	func _ready() -> void:
		z_index = 1

	func _draw() -> void:
		DrawBatch.begin(self)
		_draw_b()
		DrawBatch.end(self)

	func _draw_b() -> void:
		DrawBatch.rect(self, Rect2(0, 0, w, depth), Color("5a5c5a"))
		DrawBatch.rect(self, Rect2(0, 0, w, 4.0), Color("7a7c7a"))
		var x := 0.0
		while x < w:
			DrawBatch.rect(self, Rect2(x, 16.0, 40.0, 3.0), Color("d8b830"))
			x += 90.0
		x = 0.0
		while x < w:   # מפרקי התפשטות
			DrawBatch.line(self, Vector2(x, 0), Vector2(x, depth), Color("4a4c4a"), 1.0)
			x += 128.0


class Gantry extends Node2D:   # עגורן שער (הקומה = add_floor)
	var w := 300.0
	var tier := 160.0

	func _ready() -> void:
		z_index = -1

	func _draw() -> void:
		DrawBatch.begin(self)
		_draw_b()
		DrawBatch.end(self)

	func _draw_b() -> void:
		var c := Color("c8a028")
		for px in [0.0, w - 18.0]:   # רגליים
			DrawBatch.rect(self, Rect2(px, -tier, 18.0, tier), c.darkened(0.15))
			for q in int(tier / 40.0):
				DrawBatch.line(self, Vector2(px, -tier + float(q) * 40.0), Vector2(px + 18.0, -tier + 40.0 + float(q) * 40.0), c.darkened(0.35), 1.5)
			DrawBatch.rect(self, Rect2(px - 4.0, -10.0, 26.0, 10.0), Color("3a3a3a"))   # גלגלים
		DrawBatch.rect(self, Rect2(-10.0, -tier - 4.0, w + 20.0, 16.0), c)   # הקורה
		for q in int(w / 20.0) + 1:
			DrawBatch.line(self, Vector2(float(q) * 20.0, -tier - 4.0), Vector2(float(q) * 20.0, -tier - 26.0), Color("3a3a3a"), 1.2)
		DrawBatch.line(self, Vector2(0, -tier - 26.0), Vector2(w, -tier - 26.0), Color("3a3a3a"), 2.0)
		DrawBatch.rect(self, Rect2(w * 0.5 - 30.0, -tier + 12.0, 60.0, 30.0), Color("4a4a4a"))   # עגלת ההרמה
		DrawBatch.line(self, Vector2(w * 0.5, -tier + 42.0), Vector2(w * 0.5, -tier + 90.0), Color("2a2a2a"), 1.5)
		E.emblem(self, Vector2(w * 0.5, -tier + 27.0), 9.0)


# ---- גל השפך ----
class Surge extends Node2D:
	const CYCLE := Vector2(12.0, 16.0)
	const WARN_T := 2.2
	const RUN_T := 1.6
	const PUSH := 520.0
	const DMG := 1
	const DMG_Z := 30
	const H := 70.0
	const EARLY := 3.5              # חיילי האימפריה יודעים את לוח הזמנים - יוצאים מהקטע לפני הצופר
	var w := 600.0
	var dir := 1.0                  # לאן המים זורמים
	var state := 0                  # 0 = שקט, 1 = אזהרה, 2 = גל
	var waves := 0                  # לבדיקות
	var hits := 0
	var swept := 0
	var climbed := 0
	var _t := 6.0
	var _hit := false
	var _moved := []
	var _early := false

	func _ready() -> void:
		z_index = 7
		add_to_group("hazards")

	func world_rect() -> Rect2:
		return Rect2(global_position + Vector2(0, -H), Vector2(w, H))

	func danger_at(p: Vector2, margin := 0.0) -> bool:
		return state != 0 and world_rect().grow(margin).has_point(p)

	func _physics_process(delta: float) -> void:
		_t -= delta
		match state:
			0:
				if _t <= EARLY and not _early:
					_early = true
					_moved.clear()   # חיילי האימפריה יוצאים מהקטע
					for z in get_tree().get_nodes_in_group("empire"):
						if not z.dead and not z.is_boss() and world_rect().grow(20.0).has_point(z.global_position + Vector2(0, -10)):
							var lx: float = global_position.x - 50.0
							var rx: float = global_position.x + w + 50.0
							z.goal_x = lx if absf(z.global_position.x - lx) < absf(z.global_position.x - rx) else rx
							_moved.append(z)
							climbed += 1
				if _t <= 0.0:
					state = 1
					_t = WARN_T
					preload("res://sfx.gd").play("dm_siren", global_position + Vector2(w * 0.5, -40), 0.0, 0.02, 2)
			1:
				if _t <= 0.0:
					state = 2
					_t = RUN_T
					waves += 1
					_hit = false
					preload("res://sfx.gd").play("dm_wave", global_position + Vector2(w * 0.5, -30), 3.0, 0.05, 2)
			2:
				var pl := get_tree().get_first_node_in_group("player")
				var r := world_rect()
				if pl != null and not pl.dead and r.has_point(pl.global_position + Vector2(0, -6)):
					pl.velocity.x = dir * PUSH
					if not _hit:
						_hit = true
						hits += 1
						pl.hurt(DMG, Vector2(dir * 2.0, -0.5))
				if Engine.get_physics_frames() % 6 == 0:
					for z in get_tree().get_nodes_in_group("zombies"):
						if not z.dead and not z.is_boss() and r.has_point(z.global_position + Vector2(0, -6)):
							swept += 1
							z.velocity.x = dir * PUSH
							z.take_damage(DMG_Z, z.global_position + Vector2(0, -20), Vector2(dir, 0), false, {"source": "hazard", "fixed": DMG_Z})
					preload("res://particles.gd").burst(get_parent(), global_position + Vector2(randf() * w, -10.0), "mist" if randf() < 0.5 else "drop", Vector2(dir, -1), 2)
				if _t <= 0.0:
					state = 0
					_early = false
					_t = randf_range(CYCLE.x, CYCLE.y)
					for z in _moved:
						if is_instance_valid(z):
							z.goal_x = INF
					_moved.clear()
		if Art.on_screen(self, global_position + Vector2(w * 0.5, -40), w):
			queue_redraw()

	func _draw() -> void:
		DrawBatch.begin(self)
		_draw_b()
		DrawBatch.end(self)

	func _draw_b() -> void:
		# שערי השפך בקצה (תמיד)
		var gx := 0.0 if dir > 0.0 else w
		DrawBatch.rect(self, Rect2(gx - 14.0, -110.0, 28.0, 110.0), Color("6a6c6a"))
		DrawBatch.rect(self, Rect2(gx - 10.0, -100.0 + (40.0 if state == 2 else 0.0), 20.0, 60.0), Color("4a5a64"))
		if state == 1:
			var on := fposmod(_t * 3.0, 1.0) < 0.5
			Art.glow(self, Vector2(gx, -118.0), 14.0, Color(1.0, 0.6, 0.1, 0.9 if on else 0.3))
			var x := 0.0
			while x <= w:
				DrawBatch.rect(self, Rect2(x, -3, 30, 3), Color(1.0, 0.6, 0.1, 0.8 if on else 0.3))
				x += 60.0
			DrawBatch.string(self, ThemeDB.fallback_font, Vector2(w * 0.5 - 60.0, -130.0), "FLOODGATES", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color(1.0, 0.7, 0.3, 0.9 if on else 0.5))
		elif state == 2:
			var k := 1.0 - _t / RUN_T
			var front := (w * clampf(k * 2.0, 0.0, 1.0)) if dir > 0.0 else w * (1.0 - clampf(k * 2.0, 0.0, 1.0))
			var a := minf(_t / 0.4, 1.0)
			var r0 := 0.0 if dir > 0.0 else front
			var r1 := front if dir > 0.0 else w
			var pts := PackedVector2Array()
			pts.append(Vector2(r0, 0))
			var x2 := r0
			var tt := float(Engine.get_physics_frames()) / 60.0
			while x2 <= r1:
				pts.append(Vector2(x2, -H * 0.6 - sin(x2 * 0.05 + tt * 8.0) * 8.0))
				x2 += 20.0
			pts.append(Vector2(r1, -H))
			pts.append(Vector2(r1, 0))
			if pts.size() >= 4:
				DrawBatch.colored_polygon(self, pts, Color(0.55, 0.68, 0.78, 0.75 * a))
			DrawBatch.circle(self, Vector2(front, -H * 0.6), 26.0, Color(0.95, 0.97, 1.0, 0.7 * a))


# ---- שנאי ----
class Transformer extends StaticBody2D:
	const CYCLE := Vector2(5.0, 7.0)
	const CHARGE_T := 1.3
	const R := 170.0
	const DMG := 1
	const DMG_Z := 30
	var arcs := 0                   # לבדיקות
	var shocked := 0
	var early := 0
	var _t := 3.0
	var _charge := 0.0
	var _flash := 0.0
	var _targets := []

	func _ready() -> void:
		collision_layer = 1
		add_to_group("hazards")
		add_to_group("cover")
		add_to_group("no_outline")
		var cs := CollisionShape2D.new()
		var sh := RectangleShape2D.new()
		sh.size = Vector2(54, 56)
		cs.shape = sh
		cs.position = Vector2(0, -28)
		add_child(cs)
		z_index = 2

	func cover_rect() -> Rect2:
		return Rect2(global_position + Vector2(-27, -56), Vector2(54, 56))

	func world_rect() -> Rect2:
		return Rect2(global_position + Vector2(-R, -120), Vector2(R * 2.0, 120))

	func danger_at(p: Vector2, margin := 0.0) -> bool:
		return _charge > 0.0 and world_rect().grow(margin).has_point(p)

	func hit_by_bullet(p: Vector2, _n: Vector2, d: Vector2) -> void:
		preload("res://particles.gd").burst(get_parent(), p, "spark", -d, 3)
		if _charge <= 0.0 and _flash <= 0.0:   # ירייה בשנאי: פריקה מוקדמת (קצרה)
			early += 1
			_charge = 0.25

	func _physics_process(delta: float) -> void:
		_t -= delta
		_flash = maxf(_flash - delta, 0.0)
		if _charge > 0.0:
			_charge -= delta
			if Engine.get_physics_frames() % 5 == 0:
				preload("res://particles.gd").burst(get_parent(), global_position + Vector2(randf_range(-20, 20), -60), "spark", Vector2.UP, 1)
			if _charge <= 0.0:
				_arc()
		elif _t <= 0.0:
			_t = randf_range(CYCLE.x, CYCLE.y)
			_charge = CHARGE_T
			preload("res://sfx.gd").play("dm_hum", global_position, -4.0, 0.05, 2)
		if _charge > 0.0 or _flash > 0.0 or Engine.get_physics_frames() % 12 == 0:
			queue_redraw()

	func _arc() -> void:
		arcs += 1
		_flash = 0.25
		_t = randf_range(CYCLE.x, CYCLE.y)
		_targets.clear()
		preload("res://sfx.gd").play("dm_zap", global_position, 2.0, 0.05, 2)
		var pl := get_tree().get_first_node_in_group("player")
		if pl != null and not pl.dead and pl.global_position.distance_to(global_position) < R:
			shocked += 1
			_targets.append(pl.global_position + Vector2(0, -30))
			pl.hurt(DMG, Vector2(signf(pl.global_position.x - global_position.x + 0.01), -0.6))
			pl.daze(0.6, "")
		for z in get_tree().get_nodes_in_group("zombies"):
			if not z.dead and not z.is_boss() and z.global_position.distance_to(global_position) < R:
				_targets.append(z.global_position + Vector2(0, -30))
				z.take_damage(DMG_Z, z.global_position + Vector2(0, -30), Vector2.UP, false, {"source": "hazard", "fixed": DMG_Z})

	func _draw() -> void:
		DrawBatch.begin(self)
		_draw_b()
		DrawBatch.end(self)

	func _draw_b() -> void:
		DrawBatch.rect(self, Rect2(-27, -56, 54, 56), Color("5a6a5a"))
		for q in 5:   # צלעות קירור
			DrawBatch.rect(self, Rect2(-27 + float(q) * 12.0, -50, 4, 44), Color("4a5a4a"))
		for q in 3:   # מבדדים
			var ix := -16.0 + float(q) * 16.0
			for i in 3:
				DrawBatch.rect(self, Rect2(ix - 4.0 + float(i), -66.0 - float(i) * 5.0, 8.0 - float(i) * 2.0, 4.0), Color("8a6a4a"))
			DrawBatch.circle(self, Vector2(ix, -82), 2.5, Color("8a8a8a"))
		DrawBatch.rect(self, Rect2(-12, -36, 24, 16), Color("d8b830"))
		DrawBatch.colored_polygon(self, PackedVector2Array([Vector2(1, -34), Vector2(-5, -27), Vector2(0, -27), Vector2(-3, -22), Vector2(5, -30), Vector2(0, -30)]), Color("1a1a1a"))
		if _charge > 0.0:
			var k := 1.0 - clampf(_charge / CHARGE_T, 0.0, 1.0)
			Art.glow(self, Vector2(0, -82), 10.0 + 20.0 * k, Color(0.6, 0.8, 1.0, 0.3 + 0.5 * k))
			DrawBatch.arc(self, Vector2(0, -40), R * (0.3 + 0.7 * k), 0.0, TAU, 32, Color(0.6, 0.8, 1.0, 0.25), 1.5)
		if _flash > 0.0:
			for tp in _targets:
				var to: Vector2 = tp - global_position
				var prev := Vector2(0, -82)
				for i in 6:
					var u := float(i + 1) / 6.0
					var nxt: Vector2 = Vector2(0, -82).lerp(to, u) + Vector2(randf_range(-10, 10), randf_range(-10, 10)) * (1.0 if i < 5 else 0.0)
					DrawBatch.line(self, prev, nxt, Color(0.85, 0.95, 1.0, 0.95), 2.0)
					prev = nxt
			Art.glow(self, Vector2(0, -82), 40.0, Color(0.7, 0.85, 1.0, 0.6))


# ---- נקודת הצנחה ----
class DropZone extends Node2D:
	const N := 3
	var dropped := 0                # לבדיקות
	var done := false

	func _physics_process(_delta: float) -> void:
		if done or Engine.get_physics_frames() % 10 != 0:
			return
		var pl := get_tree().get_first_node_in_group("player")
		if pl == null or pl.dead or pl.global_position.x < global_position.x:
			return
		done = true
		preload("res://sfx.gd").play("dm_plane", pl.global_position + Vector2(0, -400), 0.0, 0.02, 2)
		var main := get_parent()
		var R := preload("res://enemies/zombie_registry.gd")
		for i in N:
			# נוחתים מאחוריך - בצד שאליו אתה לא מסתכל
			var behind: float = -signf(pl._aim.x) if pl._aim.x != 0.0 else -1.0
			var x: float = pl.global_position.x + behind * (220.0 + float(i) * 70.0)
			var z: Node = main._spawn_zombie(x, global_position.y, R.PARATROOPER)
			if z != null:
				z.set_meta("drop", true)
				dropped += 1


# ---- מכשולים ----
class Obstacle extends Node2D:
	var kind := "jersey"
	var size := Vector2(80, 36)
	var seed_v := 0

	func _ready() -> void:
		var body := StaticBody2D.new()
		body.collision_layer = 1
		body.add_to_group("no_outline")
		if size.y >= 30.0:
			add_to_group("cover")
		var cs := CollisionShape2D.new()
		var sh := RectangleShape2D.new()
		sh.size = size
		cs.shape = sh
		cs.position = Vector2(size.x * 0.5, -size.y * 0.5)
		body.add_child(cs)
		add_child(body)
		z_index = 1

	func cover_rect() -> Rect2:
		return Rect2(global_position + Vector2(0.0, -size.y), size)

	func _draw() -> void:
		DrawBatch.begin(self)
		_draw_b()
		DrawBatch.end(self)

	func _draw_b() -> void:
		var w := size.x
		var h := size.y
		match kind:
			"jersey":   # מחסום בטון
				Art.fill_shaded(self, PackedVector2Array([Vector2(0, 0), Vector2(w, 0), Vector2(w - 8, -h * 0.3), Vector2(w - 14, -h), Vector2(14, -h), Vector2(8, -h * 0.3)]), Color("9a9a94"), 0.15, 0.35, Art.OUTLINE, 1.2)
				DrawBatch.rect(self, Rect2(w * 0.2, -h * 0.6, w * 0.6, 4), E.RED)
			"cable_drum":   # תוף כבלים
				var c := Vector2(w * 0.5, -h * 0.5)
				DrawBatch.colored_polygon(self, Art.ellipse(c, w * 0.5, h * 0.5, 0.0, 18), Color("6a4a2a"))
				DrawBatch.colored_polygon(self, Art.ellipse(c, w * 0.36, h * 0.36, 0.0, 16), Color("1a1a1a"))
				DrawBatch.colored_polygon(self, Art.ellipse(c, w * 0.12, h * 0.12, 0.0, 10), Color("6a4a2a"))
			_:   # שסתום ענק
				DrawBatch.rect(self, Rect2(w * 0.3, -h * 0.6, w * 0.4, h * 0.6), Color("3a5a7a"))
				DrawBatch.arc(self, Vector2(w * 0.5, -h * 0.7), w * 0.45, 0.0, TAU, 20, Color("c83020"), 4.0)
				for q in 4:
					DrawBatch.line(self, Vector2(w * 0.5, -h * 0.7), Vector2(w * 0.5, -h * 0.7) + Vector2.from_angle(float(q) * PI * 0.5) * w * 0.45, Color("c83020"), 2.0)


# ---- רסס וערפל (מסך) ----
class DamFX extends Node2D:
	var vp := Vector2(1280, 720)
	var _t := 0.0

	func _process(delta: float) -> void:
		_t += delta
		if Engine.get_process_frames() % 2 == 0:
			queue_redraw()

	func _draw() -> void:
		DrawBatch.begin(self)
		_draw_b()
		DrawBatch.end(self)

	func _draw_b() -> void:
		for i in 26:
			var x := fposmod(float(i) * 61.0 + _t * (30.0 + float(i % 4) * 10.0), vp.x)
			var y := fposmod(float(i) * 97.0 + sin(_t + float(i)) * 20.0 + _t * 12.0, vp.y)
			DrawBatch.circle(self, Vector2(x, y), 1.2, Color(0.9, 0.95, 1.0, 0.35))
		DrawBatch.rect(self, Rect2(0, vp.y * 0.6, vp.x, vp.y * 0.4), Color(0.85, 0.9, 0.95, 0.05))
