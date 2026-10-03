extends Node2D
# ============================================================
#  היציאה מהשלב: שער מבוצר ומסוק פינוי שמרחף מעליו.
#  השער נעול (אור אדום) עד שהבוס מת. אחרי זה הוא נפתח (אור ירוק),
#  ומי שעובר בו מסיים את השלב.  נקודת ה-(0,0) = על הריצפה.
# ============================================================

const Art := preload("res://art.gd")

signal reached

var locked := true
var _open_k := 0.0
var _t := 0.0
var _wall: StaticBody2D
var _done := false


func _ready() -> void:
	add_to_group("level_exit")
	z_index = 0
	# קיר בלתי נראה שחוסם את המעבר כל עוד השער נעול
	_wall = StaticBody2D.new()
	_wall.collision_layer = 1
	_wall.collision_mask = 0
	var cs := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = Vector2(16, 400)
	cs.shape = r
	cs.position = Vector2(0, -200)
	_wall.add_child(cs)
	add_child(_wall)


func on_boss_dead() -> void:
	if not locked:
		return
	locked = false
	_wall.queue_free()
	var t = preload("res://zombie.gd").HitText.new()
	t.text = "THE GATE IS OPEN!"
	t.color = Color(0.5, 1.0, 0.6)
	t.size = 22
	t.life = 2.5
	get_parent().add_child(t)
	t.global_position = global_position + Vector2(0, -150)


func _process(delta: float) -> void:
	_t += delta
	if not locked:
		_open_k = move_toward(_open_k, 1.0, delta * 0.8)
	var p := get_tree().get_first_node_in_group("player")
	if not _done and not locked and p != null and not p.dead and p.global_position.x > global_position.x + 20.0:
		_done = true
		reached.emit()
	if Art.on_screen(self, global_position, 300.0):
		queue_redraw()


func _draw() -> void:
	# מסוק פינוי שמרחף
	var hb := Vector2(60, -235 + sin(_t * 1.6) * 6.0)
	_heli(hb)
	# עמודי בטון
	for x in [-34.0, 34.0]:
		Art.fill_shaded(self, PackedVector2Array([Vector2(x - 10, 0), Vector2(x - 10, -110), Vector2(x + 10, -110), Vector2(x + 10, 0)]), Color("6e6c68"), 0.15, 0.35, Art.OUTLINE, 1.5)
		draw_line(Vector2(x - 10, -60), Vector2(x + 10, -58), Color(0, 0, 0, 0.3), 1.0, true)
	# שלט EVAC
	Art.fill(self, PackedVector2Array([Vector2(-46, -132), Vector2(46, -132), Vector2(46, -112), Vector2(-46, -112)]), Color("2a2a2e"), Art.OUTLINE, 1.4)
	var f := ThemeDB.fallback_font
	draw_string(f, Vector2(-46, -116), "EVAC", HORIZONTAL_ALIGNMENT_CENTER, 92, 16, Color(0.9, 0.85, 0.5))
	# שער רשת שנפתח למעלה
	var gate_h := 100.0 * (1.0 - _open_k)
	if gate_h > 1.0:
		var top := -100.0 + (100.0 - gate_h) * 0.0 - (100.0 - gate_h)
		var gate := PackedVector2Array([Vector2(-24, top), Vector2(24, top), Vector2(24, top + gate_h), Vector2(-24, top + gate_h)])
		Art.fill(self, gate, Color(0.15, 0.15, 0.17, 0.85), Art.OUTLINE, 1.2)
		var y := top + 6.0
		while y < top + gate_h:
			draw_line(Vector2(-24, y), Vector2(24, y), Color(0.55, 0.55, 0.6, 0.6), 1.0, true)
			y += 8.0
		for x in [-16.0, -8.0, 0.0, 8.0, 16.0]:
			draw_line(Vector2(x, top), Vector2(x, top + gate_h), Color(0.55, 0.55, 0.6, 0.6), 1.0, true)
	# אור אדום/ירוק
	var col := Color(1.0, 0.2, 0.15) if locked else Color(0.3, 1.0, 0.4)
	var blink := 0.6 + 0.4 * sin(_t * 6.0)
	Art.glow(self, Vector2(0, -142), 20.0, Color(col, 0.6 * blink))
	Art.disc(self, Vector2(0, -142), 5.0, col, Art.OUTLINE, 1.0)
	if locked:
		draw_string(f, Vector2(-60, -160), "KILL THE BOSS", HORIZONTAL_ALIGNMENT_CENTER, 120, 12, Color(1.0, 0.5, 0.45, 0.9))
	else:   # עשן ירוק של זיקוק סימון
		for i in 8:
			var k := fmod(float(i) / 8.0 + _t * 0.25, 1.0)
			draw_circle(Vector2(40 + k * 20.0 + sin(k * 7.0) * 6.0, -4.0 - k * 120.0), 5.0 + k * 16.0, Color(0.3, 0.9, 0.4, 0.3 * (1.0 - k)))
		Art.glow(self, Vector2(40, -3), 12.0, Color(0.4, 1.0, 0.5, 0.8))


func _heli(c: Vector2) -> void:
	var body := Color("2c3430")
	# אלומת זרקור
	var beam_a := 0.12 + 0.05 * sin(_t * 2.0)
	draw_polygon(PackedVector2Array([c + Vector2(-6, 14), c + Vector2(6, 14), c + Vector2(70, 240), c + Vector2(-50, 240)]),
		PackedColorArray([Color(1, 1, 0.85, beam_a), Color(1, 1, 0.85, beam_a), Color(1, 1, 0.85, 0.0), Color(1, 1, 0.85, 0.0)]))
	# זנב
	Art.fill(self, PackedVector2Array([c + Vector2(30, -6), c + Vector2(110, -10), c + Vector2(114, -2), c + Vector2(30, 6)]), body, Art.OUTLINE, 1.4)
	Art.fill(self, PackedVector2Array([c + Vector2(104, -10), c + Vector2(112, -28), c + Vector2(118, -26), c + Vector2(114, -6)]), body, Art.OUTLINE, 1.2)
	draw_arc(c + Vector2(112, -6), 10.0, 0.0, TAU, 12, Color(0.6, 0.6, 0.6, 0.3), 1.0, true)
	# גוף
	Art.fill_shaded(self, Art.ellipse(c, 40.0, 17.0, 0.0, 24), body, 0.15, 0.4, Art.OUTLINE, 1.6)
	Art.fill(self, PackedVector2Array([c + Vector2(-38, -4), c + Vector2(-20, -14), c + Vector2(-14, -2), c + Vector2(-30, 4)]), Color("1a2a34"), Art.OUTLINE, 1.0)   # חלון
	draw_line(c + Vector2(-30, -8), c + Vector2(-22, -11), Color(1, 1, 1, 0.3), 1.0, true)
	# מגלשיים
	draw_line(c + Vector2(-26, 22), c + Vector2(26, 22), Color("1a1a1a"), 2.5, true)
	draw_line(c + Vector2(-16, 14), c + Vector2(-18, 22), Color("1a1a1a"), 2.0, true)
	draw_line(c + Vector2(16, 14), c + Vector2(18, 22), Color("1a1a1a"), 2.0, true)
	# רוטור מסתובב
	var rw := 70.0 * absf(cos(_t * 22.0)) + 8.0
	draw_line(c + Vector2(0, -17), c + Vector2(0, -24), Color("1a1a1a"), 3.0, true)
	draw_line(c + Vector2(-rw, -25), c + Vector2(rw, -25), Color(0.1, 0.1, 0.1, 0.8), 2.5, true)
	draw_line(c + Vector2(-78, -25), c + Vector2(78, -25), Color(0.1, 0.1, 0.1, 0.15), 3.0, true)
	# אור מהבהב
	if fmod(_t, 1.0) < 0.15:
		Art.glow(self, c + Vector2(0, 17), 8.0, Color(1, 0.2, 0.2, 0.9))
