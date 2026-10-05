extends RefCounted
# ============================================================
#  שלב 13 (צפון-מזרח, "DUNES OF BONE") - הדיונות עצמן + סופת החול.
#  * Dune      - גבעת חול מוצקה שהולכים עליה (StaticBody2D + CollisionPolygon2D, שכבה 1).
#                צורה: "קוסינוס מורם" - שיפוע 0 בקצוות, שיפוע מקסימלי ~32 מעלות (h / w <= 0.2).
#                קליעים לא עוברים דרכה = מחסה. עצמות בולטות מהחול, אדוות רוח, קו מתאר כהה.
#                surface_y(x) = גובה פני החול (גלובלי) - להצבת זומבים / חפצים.
#  * SandStorm - כל SANDSTORM_EVERY שניות: סופת חול (SANDSTORM_T). המסך מתערפל בצהוב,
#                פסי חול מהירים, והזומבים רואים אותך פחות (Game.player_dark) - וגם אתה אותם.
# ============================================================

const Art := preload("res://art.gd")


class Dune extends StaticBody2D:
	var w := 700.0
	var h := 120.0
	var seed_v := 0
	const N := 28

	func _ready() -> void:
		collision_layer = 1
		collision_mask = 0
		add_to_group("no_outline")
		add_to_group("s13_dunes")
		var cp := CollisionPolygon2D.new()
		var pts := PackedVector2Array()
		for i in N + 1:
			var x := w * float(i) / float(N)
			pts.append(Vector2(x, -_height(x)))
		pts.append(Vector2(w, 14.0))
		pts.append(Vector2(0.0, 14.0))
		cp.polygon = pts
		add_child(cp)
		z_index = 1

	func _height(x: float) -> float:
		var u := clampf(x / w, 0.0, 1.0)
		return h * (0.5 - 0.5 * cos(u * TAU))

	# גובה פני החול בנקודה גלובלית x (או INF אם x מחוץ לדיונה)
	func surface_y(gx: float) -> float:
		var lx := gx - global_position.x
		if lx < 0.0 or lx > w:
			return INF
		return global_position.y - _height(lx)

	func _draw() -> void:
		var r := Art_rng(seed_v)
		var top := PackedVector2Array()
		for i in N + 1:
			var x := w * float(i) / float(N)
			top.append(Vector2(x, -_height(x)))
		var body := top.duplicate()
		body.append(Vector2(w, 2.0))
		body.append(Vector2(0.0, 2.0))
		draw_colored_polygon(body, Color("e2d2b0"))
		# צד מוצל (הצד שמאחורי הרוח)
		var shade := PackedVector2Array()
		for i in range(N / 2, N + 1):
			var x := w * float(i) / float(N)
			shade.append(Vector2(x, -_height(x) + 2.0))
		shade.append(Vector2(w, 2.0))
		shade.append(Vector2(w * 0.5, 2.0))
		draw_colored_polygon(shade, Color("c8b48e"))
		for k in 5:   # אדוות רוח
			var yk := 8.0 + float(k) * 9.0
			var line := PackedVector2Array()
			for i in N + 1:
				var x := w * float(i) / float(N)
				var hy := -_height(x)
				if hy + yk < 0.0:
					line.append(Vector2(x, hy + yk + sin(x * 0.05 + float(k)) * 1.5))
			if line.size() > 1:
				draw_polyline(line, Color(0.6, 0.5, 0.35, 0.35), 1.0)
		for q in int(w / 140.0):   # עצמות בולטות מהחול
			var bx := r.randf_range(w * 0.1, w * 0.9)
			var by := -_height(bx) + 6.0
			match r.randi() % 3:
				0:   # צלעות
					for i in 4:
						var x0 := bx + float(i) * 7.0
						draw_arc(Vector2(x0, by), 10.0, PI + 0.3, TAU - 0.6, 8, Color("efe8d6"), 2.2)
				1:   # גולגולת שור
					Art.oval(self, Vector2(bx, by - 4.0), 6.0, 5.0, Color("efe8d6"), 0.0, Art.OUTLINE, 1.0)
					draw_circle(Vector2(bx - 2.0, by - 5.0), 1.4, Color("2a2018"))
					draw_circle(Vector2(bx + 2.0, by - 5.0), 1.4, Color("2a2018"))
					draw_arc(Vector2(bx - 9.0, by - 10.0), 6.0, 0.2, 1.6, 6, Color("efe8d6"), 2.0)
					draw_arc(Vector2(bx + 9.0, by - 10.0), 6.0, PI - 1.6, PI - 0.2, 6, Color("efe8d6"), 2.0)
				_:   # עצם ארוכה
					draw_line(Vector2(bx - 8.0, by), Vector2(bx + 8.0, by - 6.0), Color("efe8d6"), 3.0)
					draw_circle(Vector2(bx - 8.0, by), 2.4, Color("efe8d6"))
					draw_circle(Vector2(bx + 8.0, by - 6.0), 2.4, Color("efe8d6"))
		draw_polyline(top, Color(0.12, 0.09, 0.06, 0.9), 3.0)   # קו מתאר (במקום המלבן של collision_outlines)

	static func Art_rng(s: int) -> RandomNumberGenerator:
		var rr := RandomNumberGenerator.new()
		rr.seed = s
		return rr


# ============================================================
#  DuneSinker - מי שעומד על דיונה "שוקע" קצת לתוך החול (רק בציור, לא בפיזיקה).
#  למה: על שיפוע, הגוף המלבני נשען על הפינה העליונה שלו -> הדמות נראית מרחפת.
#  איך: אחרי שכולם זזו (process_priority גבוה), מזיזים את ה-canvas item של הדמות למטה
#  עד פני החול + SINK פיקסלים. הפיזיקה, הקליעים והפגיעות לא משתנים בכלל.
# ============================================================
class DuneSinker extends Node:
	const SINK := 4.0          # כמה פיקסלים "לתוך" החול
	const MAX_DROP := 16.0     # הכי הרבה שמזיזים למטה
	var dunes: Array = []
	var _off := {}             # instance_id -> ההזזה הנוכחית (מוחלקת)

	func _ready() -> void:
		process_priority = 1000   # אחרי כל ה-_process האחרים, רגע לפני הציור

	func _surface(x: float) -> Vector2:   # (גובה פני החול, גובה הדיונה בנקודה) או INF
		for d in dunes:
			if not is_instance_valid(d):
				continue
			var y: float = d.surface_y(x)
			if y != INF:
				return Vector2(y, d.global_position.y - y)
		return Vector2(INF, 0.0)

	func _process(delta: float) -> void:
		var bodies: Array = get_tree().get_nodes_in_group("zombies")
		bodies.append_array(get_tree().get_nodes_in_group("player"))
		var seen := {}
		for b in bodies:
			if not is_instance_valid(b) or not (b is CharacterBody2D):
				continue
			var id: int = b.get_instance_id()
			seen[id] = true
			var want := 0.0
			var alive: bool = not bool(b.get("dead")) and b.is_on_floor() and b.visible
			if alive:
				var sf := _surface(b.global_position.x)
				if sf.x != INF and absf(sf.x - b.global_position.y) < MAX_DROP + 4.0:
					var gap := clampf(sf.x - b.global_position.y, 0.0, MAX_DROP)
					want = gap + SINK * clampf(sf.y / 24.0, 0.0, 1.0)   # בקצוות הדיונה (גובה ~0) לא שוקעים
			var cur: float = _off.get(id, 0.0)
			if want == 0.0 and cur == 0.0:
				continue
			cur = move_toward(cur, want, delta * 90.0)
			if absf(cur) < 0.05:
				cur = 0.0
			_off[id] = cur
			var t: Transform2D = b.get_transform()
			t.origin.y += cur
			RenderingServer.canvas_item_set_transform(b.get_canvas_item(), t)
			if cur == 0.0:
				_off.erase(id)
		for id in _off.keys():
			if not seen.has(id):
				_off.erase(id)


# ============================================================
#  סופת חול מחזורית (שכבת מסך)
# ============================================================
class SandStorm extends Node2D:
	const SANDSTORM_EVERY := Vector2(32.0, 46.0)
	const SANDSTORM_T := 8.0
	var vp := Vector2(1280, 720)
	var storms := 0          # לבדיקות
	var k := 0.0             # 0..1 עוצמת הסופה עכשיו
	var _next := 20.0
	var _left := 0.0
	var _t := 0.0
	var _streaks := []

	func _ready() -> void:
		for i in 60:
			_streaks.append([Vector2(randf() * vp.x, randf() * vp.y), randf_range(600.0, 1100.0), randf_range(20.0, 60.0)])

	func _exit_tree() -> void:
		Game.player_dark = false

	func _process(delta: float) -> void:
		_t += delta
		if _left > 0.0:
			_left -= delta
			k = move_toward(k, 1.0 if _left > 1.5 else 0.0, delta * 0.8)
		else:
			k = move_toward(k, 0.0, delta * 0.8)
			_next -= delta
			if _next <= 0.0:
				_next = randf_range(SANDSTORM_EVERY.x, SANDSTORM_EVERY.y)
				_left = SANDSTORM_T
				storms += 1
				Sfx.play("whoosh", null, 2.0)
				Game.story.emit("sandstorm", {})
		Game.player_dark = k > 0.5   # בסופה: הזומבים רואים פחות (רק בשלב הזה)
		if k > 0.01:
			for s in _streaks:
				s[0].x -= float(s[1]) * delta
				s[0].y += sin(_t * 3.0 + s[0].x * 0.01) * 30.0 * delta
				if s[0].x < -80.0:
					s[0] = Vector2(vp.x + randf() * 100.0, randf() * vp.y)
			queue_redraw()
		elif k == 0.0 and _streaks.size() > 0:
			queue_redraw()

	func _draw() -> void:
		if k <= 0.0:
			return
		draw_rect(Rect2(Vector2.ZERO, vp), Color(0.82, 0.68, 0.45, 0.42 * k))
		for s in _streaks:
			draw_line(s[0], s[0] + Vector2(float(s[2]), 0.0), Color(0.95, 0.85, 0.6, 0.45 * k), 1.5)
		var f := ThemeDB.fallback_font
		if k > 0.3 and fmod(_t, 1.0) < 0.6 and _left > SANDSTORM_T - 2.5:
			draw_string_outline(f, Vector2(0, 150), "SANDSTORM", HORIZONTAL_ALIGNMENT_CENTER, vp.x, 26, 5, Color(0, 0, 0, 0.6))
			draw_string(f, Vector2(0, 150), "SANDSTORM", HORIZONTAL_ALIGNMENT_CENTER, vp.x, 26, Color(1.0, 0.85, 0.5, 0.9))

	const Sfx := preload("res://sfx.gd")
