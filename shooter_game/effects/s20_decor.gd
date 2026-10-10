extends RefCounted
# ============================================================
#  קישוטים לשלב 20 ("GREEN HELL") - ג'ונגל צפוף עוד יותר. הרקע והאפקטים משותפים עם שלב 19
#  (effects/s19_decor.gd). כאן רק הצמחייה שבעולם - הכל סטטי (מצויר פעם אחת = כמעט בלי עלות):
#    Undergrowth - (מאחורי הדמויות, z 2) שרכים ועשב בגובה הברך לאורך כל הקרקע
#    Bush        - (מלפני הדמויות, z 6!) שיחים צפופים שמסתירים את מי שמאחוריהם.
#                  אותם צבעים כמו חליפת ה-GHILLIE (enemies/types/ghillie.gd SUIT) - הוא נבלע בהם.
#                  קבוצה "s20_bush" - ה-GHILLIE מתמקם בהם.
#    Curtain     - (מלפני הדמויות, z 6) וילון ליאנות ועלים שתלוי מהצמרת בחלק העליון של המסך
#    BushFader   - שיח שהשחקן בתוכו נהיה שקוף (רואים את עצמך ואת מי שאיתך בשיח)
#  לשנות: BUSH, BUSH_ALPHA, FADE_ALPHA.
# ============================================================

const BUSH := [Color("1d3a20"), Color("27482a"), Color("335a30"), Color("3f6a36")]
const FERN := [Color("2f5a2c"), Color("3d6e35"), Color("4a7a3a")]
const BUSH_ALPHA := 0.94
const FADE_ALPHA := 0.42


# ---- שרכים ועשב מאחורי הדמויות (חתיכה של 1024) ----
class Undergrowth extends Node2D:
	var w := 1024.0
	var seed_v := 0

	func _ready() -> void:
		z_index = 2

	func _draw() -> void:
		var r := RandomNumberGenerator.new()
		r.seed = seed_v
		var S := preload("res://effects/s20_decor.gd")
		var x := r.randf_range(0.0, 40.0)
		while x < w:
			var c: Color = S.FERN[r.randi() % 3]
			if r.randf() < 0.55:   # שרך: כמה עלעלים מתעקלים
				for q in 5:
					var a := -PI * 0.5 + (float(q) - 2.0) * 0.42
					var ln := r.randf_range(26.0, 44.0)
					var d := Vector2.from_angle(a)
					var tip := Vector2(x, 0) + d * ln + Vector2(d.x * 8.0, 6.0)
					var n := d.orthogonal() * 5.0
					draw_colored_polygon(PackedVector2Array([Vector2(x, 0), Vector2(x, 0) + d * ln * 0.5 + n, tip, Vector2(x, 0) + d * ln * 0.5 - n]), c)
			else:   # עשב
				for q in 6:
					var bx := x + float(q) * 4.0 - 10.0
					var h := r.randf_range(18.0, 36.0)
					draw_colored_polygon(PackedVector2Array([Vector2(bx - 2.0, 2), Vector2(bx + (float(q) - 2.5) * 3.0, -h), Vector2(bx + 2.0, 2)]), c)
			x += r.randf_range(26.0, 60.0)


# ---- שיח קדמי (מסתיר דמויות) ----
class Bush extends Node2D:
	var w := 110.0
	var h := 80.0
	var seed_v := 0

	func _ready() -> void:
		z_index = 6
		add_to_group("s20_bush")
		modulate.a = preload("res://effects/s20_decor.gd").BUSH_ALPHA

	func _draw() -> void:
		var r := RandomNumberGenerator.new()
		r.seed = seed_v
		var S := preload("res://effects/s20_decor.gd")
		# גוש כהה בבסיס
		var base := PackedVector2Array()
		for i in 9:
			var a := PI + float(i) * PI / 8.0
			base.append(Vector2(cos(a) * w * 0.5, 4.0 + sin(a) * h * 0.55 * r.randf_range(0.85, 1.05)))
		draw_colored_polygon(base, S.BUSH[0])
		# עלים רחבים שנפרשים מהמרכז
		var n := int(w / 9.0)
		for i in n:
			var u := float(i) / float(n - 1)
			var a := -PI * 0.5 + (u - 0.5) * 2.6 + r.randf_range(-0.15, 0.15)
			var d := Vector2.from_angle(a)
			var root := Vector2(r.randf_range(-w * 0.25, w * 0.25), 2.0)
			var ln := h * r.randf_range(0.7, 1.05) * (1.0 - absf(u - 0.5) * 0.6)
			var o := d.orthogonal() * ln * 0.24
			var c: Color = S.BUSH[1 + r.randi() % 3]
			draw_colored_polygon(PackedVector2Array([root, root + d * ln * 0.5 + o, root + d * ln, root + d * ln * 0.5 - o]), c)
			draw_line(root, root + d * ln * 0.9, Color(0, 0, 0, 0.18), 1.0)
		# עשב בקדמת השיח
		for q in 8:
			var bx := r.randf_range(-w * 0.45, w * 0.45)
			var gh := r.randf_range(14.0, 30.0)
			draw_colored_polygon(PackedVector2Array([Vector2(bx - 2.0, 4), Vector2(bx + r.randf_range(-6.0, 6.0), -gh), Vector2(bx + 2.0, 4)]), S.BUSH[0])

	func covers(p: Vector2) -> bool:
		return absf(p.x - global_position.x) < w * 0.5 + 6.0 and p.y > global_position.y - h - 20.0 and p.y < global_position.y + 30.0


# ---- וילון ליאנות ועלים מהצמרת (מלמעלה, מסתיר חלק מהתלויים) ----
class Curtain extends Node2D:
	var w := 220.0
	var drop := 260.0     # כמה עמוק הוא יורד מלמעלה
	var seed_v := 0

	func _ready() -> void:
		z_index = 6

	func _draw() -> void:
		var r := RandomNumberGenerator.new()
		r.seed = seed_v
		var S := preload("res://effects/s20_decor.gd")
		# גוש עלים עליון
		var top := PackedVector2Array([Vector2(-20, -10)])
		for i in 9:
			var u := float(i) / 8.0
			top.append(Vector2(w * u, r.randf_range(30.0, 70.0)))
		top.append(Vector2(w + 20.0, -10))
		draw_colored_polygon(top, S.BUSH[0])
		# ליאנות שיורדות עם עלים
		for v in 5:
			var x := r.randf_range(10.0, w - 10.0)
			var ln := r.randf_range(drop * 0.45, drop)
			var sway := r.randf_range(-14.0, 14.0)
			var pts := PackedVector2Array([Vector2(x, 30), Vector2(x + sway, ln * 0.5), Vector2(x + sway * 0.4, ln)])
			draw_polyline(pts, S.BUSH[0], 2.5, true)
			for k in int(ln / 26.0):
				var p := Vector2(x + sway * sin(float(k) / 3.0) * 0.8, 40.0 + float(k) * 26.0)
				var sd := 1.0 if k % 2 == 0 else -1.0
				var d := Vector2(sd * 0.8, 0.6).normalized()
				var o := d.orthogonal() * 4.5
				draw_colored_polygon(PackedVector2Array([p, p + d * 8.0 + o, p + d * 17.0, p + d * 8.0 - o]), S.BUSH[1 + (k + v) % 3])


# ---- שיח שהשחקן בתוכו נהיה שקוף ----
class BushFader extends Node:
	var bushes: Array = []
	var _pl: Node = null

	func _process(delta: float) -> void:
		if _pl == null or not is_instance_valid(_pl):
			_pl = get_tree().get_first_node_in_group("player")
			if _pl == null:
				return
		var S := preload("res://effects/s20_decor.gd")
		var px: float = _pl.global_position.x
		for b in bushes:
			if absf(b.global_position.x - px) > 260.0 and b.modulate.a >= S.BUSH_ALPHA:
				continue
			var target: float = S.FADE_ALPHA if b.covers(_pl.global_position + Vector2(0, -20)) else S.BUSH_ALPHA
			b.modulate.a = move_toward(b.modulate.a, target, delta * 3.0)
