extends Node2D
# ============================================================
#  קישוטי רחוב ברקע (בלי התנגשות - הדמויות עוברות לפניהם):
#    TRAFFIC_LIGHT - רמזור שמהבהב בצהוב
#    LAMP          - עמוד תאורה עקום ושבור
#    FENCE         - גדר רשת קרועה עם תיל דוקרני
#    TRASH_FIRE    - פח זבל בוער
#  נקודת ה-(0,0) = על הריצפה.
# ============================================================

const Art := preload("res://art.gd")
const FireScript := preload("res://fire.gd")

enum { TRAFFIC_LIGHT, LAMP, FENCE, TRASH_FIRE }

@export_enum("TrafficLight", "Lamp", "Fence", "TrashFire") var kind := 0
var _blink := false
var _t := 0.0
var _seed := 0


func _ready() -> void:
	z_index = -1
	_seed = int(absf(position.x))
	if kind == TRASH_FIRE:
		var f = FireScript.new()
		f.width = 16.0
		f.height = 22.0
		f.position = Vector2(0, -26)
		add_child(f)
		f.z_index = 0


func _process(delta: float) -> void:
	if kind != TRAFFIC_LIGHT:
		set_process(false)
		return
	_t += delta
	var b := fmod(_t, 1.0) < 0.5
	if b != _blink:   # מציירים מחדש רק כשהאור מתחלף
		_blink = b
		queue_redraw()


func _draw() -> void:
	match kind:
		TRAFFIC_LIGHT:
			var pole := Color("2a2a2e")
			Art.limb(self, PackedVector2Array([Vector2(0, 0), Vector2(0, -150), Vector2(4, -158), Vector2(46, -160)]), 4.0, pole)
			Art.fill(self, PackedVector2Array([Vector2(36, -160), Vector2(52, -160), Vector2(52, -116), Vector2(36, -116)]), Color("1e1e20"), Art.OUTLINE, 1.4)
			for i in 3:
				var c := Vector2(44, -152 + i * 13)
				var lit := i == 1 and _blink
				if lit:
					Art.glow(self, c, 22.0, Color(1.0, 0.75, 0.2, 0.7))
				Art.disc(self, c, 4.5, Color("ffc838") if lit else Color("3a3530"), Art.OUTLINE, 1.0)
		LAMP:
			var pole := Color("2e2e33")
			Art.limb(self, PackedVector2Array([Vector2(0, 0), Vector2(2, -90), Vector2(14, -125), Vector2(34, -122)]), 4.0, pole)
			Art.fill(self, PackedVector2Array([Vector2(28, -124), Vector2(42, -121), Vector2(40, -116), Vector2(30, -118)]), Color("3a3a40"), Art.OUTLINE, 1.0)
			draw_line(Vector2(34, -117), Vector2(32, -100), Color(0.1, 0.1, 0.1), 1.0, true)   # חוט שמשתלשל
		FENCE:
			var rng := RandomNumberGenerator.new()
			rng.seed = _seed
			var w := 150.0
			var h := 64.0
			var post := Color("3a3a40")
			# רשת: קווים באלכסון
			var mesh := Color(0.55, 0.55, 0.6, 0.35)
			var hole := Vector2(rng.randf_range(40.0, 110.0), -rng.randf_range(16.0, 40.0))
			var i := -h
			while i < w:
				for d in [1.0, -1.0]:
					var a := Vector2(i, 0) if d > 0 else Vector2(i + h, 0)
					var b := a + Vector2(h * d, -h)
					var pts := PackedVector2Array()
					for k in 9:
						var p := a.lerp(b, float(k) / 8.0)
						if p.x >= 0.0 and p.x <= w and p.distance_to(hole) > 16.0:
							pts.append(p)
						elif pts.size() > 1:
							draw_polyline(pts, mesh, 1.0, true)
							pts = PackedVector2Array()
						else:
							pts = PackedVector2Array()
					if pts.size() > 1:
						draw_polyline(pts, mesh, 1.0, true)
				i += 8.0
			# קצוות קרועים של החור
			for k in 8:
				var a := TAU * float(k) / 8.0
				var p := hole + Vector2(cos(a), sin(a)) * 16.0
				draw_line(p, p + Vector2(cos(a), sin(a)) * -rng.randf_range(3.0, 7.0), mesh, 1.0, true)
			for px in [0.0, w / 2.0, w]:
				Art.limb(self, PackedVector2Array([Vector2(px, 0), Vector2(px + (rng.randf_range(-4, 4) if px == w else 0.0), -h - 4.0)]), 3.0, post)
			draw_line(Vector2(0, -h), Vector2(w, -h + 2.0), post, 2.0, true)
			# תיל דוקרני מסולסל
			var coil := PackedVector2Array()
			for k in 61:
				var t := float(k) / 60.0
				coil.append(Vector2(t * w + sin(t * 60.0) * 4.0, -h - 6.0 + cos(t * 60.0) * 5.0))
			draw_polyline(coil, Color(0.5, 0.5, 0.55, 0.8), 1.0, true)
		TRASH_FIRE:
			var can := Color("4a4c4a")
			Art.fill_shaded(self, PackedVector2Array([Vector2(-11, 0), Vector2(-13, -26), Vector2(13, -26), Vector2(11, 0)]), can, 0.15, 0.4, Art.OUTLINE, 1.4)
			for y in [-8.0, -18.0]:
				draw_line(Vector2(-12, y), Vector2(12, y), Color(0, 0, 0, 0.4), 1.2, true)
			Art.oval(self, Vector2(0, -26), 13.0, 2.5, Color("2a2a2a"), 0.0, Art.OUTLINE, 1.0)
			Art.glow(self, Vector2(0, -26), 30.0, Color(1.0, 0.5, 0.2, 0.35))
