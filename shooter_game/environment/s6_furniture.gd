extends StaticBody2D
# ============================================================
#  רהיט מוצק (שלב 6): שולחן משרדי, ארון מגירות, ספה, מחסום מאולתר, מכונת משקאות.
#  * מוצק (שכבה 1): חוסם קליעים וקו ראייה -> זומבי STALKER מתחבא מאחוריו
#    (קבוצת "cover" + cover_rect()), כמו מאחורי מכוניות וארגזים.
#  * נשבר אחרי hp פגיעות קליע או מפיצוץ (שבבים + אבק).
#  position = הפינה השמאלית-תחתונה (על הריצפה). kind קובע גודל וציור.
#  להוספת רהיט: מוסיפים שורה ל-SIZES ו-HP, ומקרה ב-_draw().
# ============================================================

const Art := preload("res://art.gd")
const Sfx := preload("res://sfx.gd")
const Particles := preload("res://particles.gd")
const DebrisScript := preload("res://debris.gd")

const SIZES := {"desk": Vector2(78, 42), "cabinet": Vector2(30, 60), "sofa": Vector2(84, 34), "barricade": Vector2(92, 56),
	"vending": Vector2(40, 64), "copier": Vector2(46, 40)}
const HP := {"desk": 6, "cabinet": 8, "sofa": 5, "barricade": 9, "vending": 12, "copier": 6}
const CHIPS := {"desk": Color("5a4636"), "cabinet": Color("6a7076"), "sofa": Color("5a3a3a"), "barricade": Color("6a5236"),
	"vending": Color("8a2a2a"), "copier": Color("8a8a84")}

var kind := "desk"
var size := Vector2(78, 42)
var seed_v := 0
var hp := 6
var _dents := []
var _broken := false


func _ready() -> void:
	collision_layer = 1
	collision_mask = 0
	size = SIZES.get(kind, size)
	hp = int(HP.get(kind, 6))
	add_to_group("cover")
	add_to_group("blastable")
	var cs := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = size
	cs.shape = r
	cs.position = Vector2(size.x * 0.5, -size.y * 0.5)
	add_child(cs)
	z_index = 0


func cover_rect() -> Rect2:
	return Rect2(global_position + Vector2(0.0, -size.y), size)


func blast_rect() -> Rect2:
	return cover_rect()


func hit_by_bullet(world_pos: Vector2, normal: Vector2, _dir: Vector2) -> void:
	if _broken:
		return
	hp -= 1
	_chips(world_pos, normal, 3)
	if _dents.size() < 8:
		_dents.append(to_local(world_pos))
	Sfx.play("hit", world_pos, -10.0, 0.2, 3)
	if hp <= 0:
		_break()
	else:
		queue_redraw()


func hit_by_blast(_center: Vector2, _radius: float) -> void:
	_break()


func _chips(pos: Vector2, normal: Vector2, n: int) -> void:
	var c: Color = CHIPS.get(kind, Color("5a5040"))
	for i in n:
		var d = DebrisScript.new()
		get_parent().add_child(d)
		var v := Vector2.from_angle(normal.angle() + randf_range(-1.0, 1.0)) * randf_range(80.0, 220.0)
		d.setup(pos, Vector2(randf_range(2.0, 4.0), randf_range(2.0, 4.0)), c.lerp(Color.BLACK, randf() * 0.3), v)


func _break() -> void:
	if _broken:
		return
	_broken = true
	var center := global_position + Vector2(size.x * 0.5, -size.y * 0.5)
	for i in 10:
		var d = DebrisScript.new()
		get_parent().add_child(d)
		d.setup(center + Vector2(randf_range(-size.x, size.x) * 0.4, randf_range(-size.y, size.y) * 0.4), Vector2(randf_range(3.0, 7.0), randf_range(3.0, 6.0)),
			(CHIPS.get(kind, Color("5a5040")) as Color).lerp(Color.BLACK, randf() * 0.4), Vector2(randf_range(-200.0, 200.0), -randf_range(80.0, 300.0)))
	Particles.burst(get_parent(), center, "smoke", Vector2.UP, 6)
	Sfx.play("splat", center, -6.0, 0.2, 2)
	queue_free()


func _draw() -> void:
	var w := size.x
	var h := size.y
	var r := RandomNumberGenerator.new()
	r.seed = seed_v
	Art.ground_shadow(self, Vector2(w * 0.5, 0.0), w * 0.55)
	match kind:
		"desk":   # שולחן משרדי הפוך על הצד (מחסה) עם מגירות
			var top := Color("5e4a38")
			Art.fill_shaded(self, PackedVector2Array([Vector2(0, -h), Vector2(w, -h), Vector2(w, -h + 6), Vector2(0, -h + 6)]), top, 0.2, 0.3)
			Art.fill_shaded(self, PackedVector2Array([Vector2(4, -h + 6), Vector2(w - 4, -h + 6), Vector2(w - 4, 0), Vector2(4, 0)]), Color("4a3a2e"), 0.1, 0.35)
			for i in 3:   # מגירות
				draw_rect(Rect2(w - 30, -h + 10 + i * 10, 22, 8), Color("3a2e24"))
				draw_line(Vector2(w - 22, -h + 14 + i * 10), Vector2(w - 16, -h + 14 + i * 10), Color("9a9080"), 1.5)
			draw_rect(Rect2(10, -h + 12, 30, 20), Color(0.1, 0.08, 0.07, 0.5))   # חלל לרגליים
			# מחשב שבור על השולחן
			draw_rect(Rect2(14, -h - 18, 24, 17), Color("1c1e22"))
			draw_rect(Rect2(16, -h - 16, 20, 13), Color("101418"))
			draw_line(Vector2(18, -h - 15), Vector2(30, -h - 6), Color(0.6, 0.7, 0.8, 0.35), 1.0)
			draw_rect(Rect2(24, -h - 2, 5, 2), Color("1c1e22"))
			draw_rect(Rect2(48, -h - 4, 18, 4), Color("2a2a2e"))   # מקלדת
			if r.randf() < 0.6:   # ערימת ניירות
				draw_rect(Rect2(w - 18, -h - 5, 12, 5), Color("a8a49a"))
		"cabinet":   # ארון מגירות מתכת, אחת פתוחה
			Art.fill_shaded(self, PackedVector2Array([Vector2(0, -h), Vector2(w, -h), Vector2(w, 0), Vector2(0, 0)]), Color("5c6268"), 0.2, 0.35)
			for i in 4:
				var y := -h + 4 + i * 14
				draw_rect(Rect2(3, y, w - 6, 12), Color("4a5056"))
				draw_rect(Rect2(w * 0.5 - 5, y + 4, 10, 3), Color("9aa0a6"))
			draw_rect(Rect2(-6, -h + 32, w - 4, 10), Color("40464c"))   # מגירה פתוחה
			draw_rect(Rect2(-4, -h + 29, 14, 4), Color("b8b4a8"))   # תיקיות
		"sofa":
			var c := Color("5a3434") if r.randf() < 0.5 else Color("3a4a5a")
			Art.fill_shaded(self, PackedVector2Array([Vector2(0, -h + 6), Vector2(10, -h), Vector2(w - 10, -h), Vector2(w, -h + 6), Vector2(w, -4), Vector2(0, -4)]), c, 0.2, 0.35)
			draw_rect(Rect2(8, -h + 14, w - 16, 10), c.darkened(0.2))
			draw_line(Vector2(w * 0.5, -h + 14), Vector2(w * 0.5, -6), c.darkened(0.4), 1.0)
			draw_rect(Rect2(4, -4, 6, 4), Color("1a1410"))
			draw_rect(Rect2(w - 10, -4, 6, 4), Color("1a1410"))
			# קרע עם ספוג
			Art.fill(self, PackedVector2Array([Vector2(20, -h + 4), Vector2(34, -h + 6), Vector2(28, -h + 12)]), Color("c8b888"), Art.NONE)
		"barricade":   # מחסום שניצולים בנו: שולחנות, כיסאות, קרשים
			Art.fill_shaded(self, PackedVector2Array([Vector2(0, 0), Vector2(6, -h * 0.6), Vector2(30, -h), Vector2(64, -h + 4), Vector2(w - 4, -h * 0.55), Vector2(w, 0)]), Color("4a3c2e"), 0.15, 0.4)
			for i in 5:   # קרשים באלכסון
				var x0 := r.randf_range(0, w - 30)
				var y0 := -r.randf_range(8, h - 6)
				var pc := Color("7a5a3a").lerp(Color("5a4028"), r.randf())
				var a := r.randf_range(-0.5, 0.5)
				var ln := r.randf_range(28.0, 46.0)
				var dv := Vector2.from_angle(a)
				var nv := Vector2(-dv.y, dv.x) * 3.0
				var p0 := Vector2(x0, y0)
				Art.fill(self, PackedVector2Array([p0 - nv, p0 + dv * ln - nv, p0 + dv * ln + nv, p0 + nv]), pc, Art.OUTLINE, 1.0)
				draw_circle(p0 + dv * 4.0, 1.0, Color("2a2a2a"))
			# רגל כיסא בולטת + שלט
			draw_line(Vector2(30, -h), Vector2(22, -h - 14), Color("2a2a2e"), 2.5)
			draw_line(Vector2(40, -h + 2), Vector2(44, -h - 12), Color("2a2a2e"), 2.5)
			draw_rect(Rect2(w * 0.35, -h * 0.55, 30, 14), Color("b8b0a0"))
			draw_string(ThemeDB.fallback_font, Vector2(w * 0.35 + 2, -h * 0.55 + 11), "KEEP OUT", HORIZONTAL_ALIGNMENT_LEFT, 28, 7, Color("8a1a14"))
		"vending":   # מכונת משקאות עם זכוכית שבורה ונורה מהבהבת
			Art.fill_shaded(self, PackedVector2Array([Vector2(0, -h), Vector2(w, -h), Vector2(w, 0), Vector2(0, 0)]), Color("7a2424"), 0.2, 0.35)
			draw_rect(Rect2(4, -h + 6, w - 16, h - 22), Color("16181c"))
			for i in 4:
				for j in 3:
					draw_rect(Rect2(7 + j * 7, -h + 9 + i * 10, 5, 7), Color.from_hsv(r.randf(), 0.5, 0.5))
			draw_line(Vector2(6, -h + 10), Vector2(18, -h + 30), Color(0.8, 0.9, 1.0, 0.4), 1.0)
			draw_rect(Rect2(w - 10, -h + 10, 6, 14), Color("2a2a2a"))
			draw_rect(Rect2(6, -12, w - 12, 6), Color("101010"))
			draw_rect(Rect2(2, -h + 2, w - 4, 3), Color(1.0, 0.8, 0.6, 0.5))
		"copier":
			Art.fill_shaded(self, PackedVector2Array([Vector2(0, -h), Vector2(w, -h), Vector2(w, 0), Vector2(0, 0)]), Color("8a8a84"), 0.2, 0.35)
			draw_rect(Rect2(4, -h - 4, w - 8, 4), Color("5a5a56"))
			draw_rect(Rect2(6, -h + 10, w - 12, 6), Color("4a4a46"))
			draw_rect(Rect2(w - 12, -h + 4, 6, 3), Color(0.3, 1.0, 0.4, 0.8))
	for dpt in _dents:   # חורי קליעים
		draw_circle(dpt, 1.5, Color(0.05, 0.04, 0.04, 0.8))
