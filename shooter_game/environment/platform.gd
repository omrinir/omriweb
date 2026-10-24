extends StaticBody2D
const DrawBatch := preload("res://effects/draw_batch.gd")
# ============================================================
#  PLATFORM - קומה / גג / מסלול מתכת. אפשר לקפוץ אליה מלמטה (one-way)
#  ולרדת ממנה: S + קפיצה. שכבת התנגשות 16 (קליעים עוברים דרכה).
#
#  שימוש (levels/stage_base.gd -> add_floor):
#    position = הפינה השמאלית-עליונה, size = רוחב x עובי
#    style: "concrete" / "steel" / "wood" / "lab" / "roof" / "scaffold"
#    supports = עמודים עד הריצפה (ground_y), railing = מעקה
# ============================================================
const Art := preload("res://art.gd")

var size := Vector2(300, 14)
var style := "concrete"
var supports := true
var ground_y := 630.0
var railing := false
var tint := Color.WHITE
var _seed := 0


func _ready() -> void:
	add_to_group("platforms")
	collision_layer = 16
	collision_mask = 0
	var cs := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = Vector2(size.x, 8.0)
	cs.shape = r
	cs.position = Vector2(size.x * 0.5, 4.0)
	cs.one_way_collision = true
	cs.one_way_collision_margin = 6.0
	add_child(cs)
	_seed = int(position.x * 7.0 + position.y)
	z_index = 1


func world_rect() -> Rect2:
	return Rect2(global_position, size)


func _draw() -> void:
	DrawBatch.begin(self)
	_draw_b()
	DrawBatch.end(self)

func _draw_b() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = _seed
	var w := size.x
	var h := size.y
	var base: Color
	match style:
		"steel", "scaffold": base = Color("3c4046")
		"wood": base = Color("5a3e28")
		"lab": base = Color("b8c4c8")
		"roof": base = Color("4a4440")
		_: base = Color("6e6a64")
	base = base * tint
	# עמודים
	if supports and ground_y > position.y + h + 4.0:
		var ph := ground_y - position.y - h
		var n := maxi(2, int(w / 220.0) + 1)
		for i in n:
			var px := 10.0 + (w - 30.0) * float(i) / float(n - 1)
			if style == "scaffold" or style == "steel":
				DrawBatch.rect(self, Rect2(px, h, 5, ph), Art.shade(base, 0.2))
				for k in int(ph / 40.0):   # הצלבות
					DrawBatch.line(self, Vector2(px, h + k * 40.0), Vector2(px + 5, h + k * 40.0 + 40.0), Art.shade(base, 0.35), 1.0)
			else:
				DrawBatch.rect(self, Rect2(px, h, 14, ph), Art.shade(base, 0.25))
				DrawBatch.rect(self, Rect2(px, h, 3, ph), Color(1, 1, 1, 0.05))
	# הקומה עצמה
	match style:
		"steel", "scaffold":   # רשת מתכת
			DrawBatch.rect(self, Rect2(0, 0, w, 6), base)
			DrawBatch.rect(self, Rect2(0, 6, w, 3), Art.shade(base, 0.4))
			var x := 0.0
			while x < w:
				DrawBatch.line(self, Vector2(x, 0), Vector2(x + 6, 6), Art.shade(base, 0.3), 1.0)
				x += 8.0
			DrawBatch.line(self, Vector2(0, 0), Vector2(w, 0), Color(0.8, 0.85, 0.9, 0.35), 1.0)
		"wood":
			DrawBatch.rect(self, Rect2(0, 0, w, h), base)
			var x := 0.0
			while x < w:
				DrawBatch.line(self, Vector2(x, 0), Vector2(x, h), Art.shade(base, 0.35), 1.0)
				x += rng.randf_range(24.0, 48.0)
			DrawBatch.line(self, Vector2(0, 0), Vector2(w, 0), Color(0.85, 0.65, 0.4, 0.4), 1.0)
		"lab":
			DrawBatch.rect(self, Rect2(0, 0, w, h), base)
			DrawBatch.rect(self, Rect2(0, h - 3, w, 3), Art.shade(base, 0.4))
			var x := 0.0
			while x < w:
				DrawBatch.line(self, Vector2(x, 0), Vector2(x, h - 3), Art.shade(base, 0.2), 1.0)
				x += 40.0
			DrawBatch.rect(self, Rect2(0, h - 1, w, 1), Color(0.4, 0.9, 1.0, 0.5))   # פס תאורה
		"roof":
			DrawBatch.rect(self, Rect2(0, 0, w, h), base)
			DrawBatch.rect(self, Rect2(0, -6, 6, 6), Art.shade(base, -0.1))
			DrawBatch.rect(self, Rect2(w - 6, -6, 6, 6), Art.shade(base, -0.1))
			DrawBatch.line(self, Vector2(0, 0), Vector2(w, 0), Color(1, 1, 1, 0.15), 1.0)
		_:   # בטון עם ברזלים חשופים
			DrawBatch.rect(self, Rect2(0, 0, w, h), base)
			DrawBatch.rect(self, Rect2(0, h - 4, w, 4), Art.shade(base, 0.35))
			DrawBatch.line(self, Vector2(0, 0), Vector2(w, 0), Color(1, 1, 1, 0.18), 1.0)
			for i in int(w / 70.0):   # סדקים
				var cx := rng.randf_range(0.0, w)
				DrawBatch.line(self, Vector2(cx, 2), Vector2(cx + rng.randf_range(-6, 6), h - 2), Art.shade(base, 0.45), 1.0)
			# קצוות שבורים עם ברזל
			for e in [0.0, w]:
				for k in 2:
					DrawBatch.line(self, Vector2(e, 4 + k * 4), Vector2(e + (5.0 if e == 0.0 else -5.0) * -1.0, 6 + k * 5), Color("6a4a3a"), 1.2)
	if railing:
		var rc := Art.shade(base, 0.15)
		DrawBatch.line(self, Vector2(0, -22), Vector2(w, -22), rc, 2.0)
		var x := 0.0
		while x <= w:
			DrawBatch.line(self, Vector2(x, 0), Vector2(x, -22), rc, 1.5)
			x += 30.0
