extends "res://environment/hazard.gd"
# ============================================================
#  S7 BLAST DOOR - דלת פלדה שנסגרת (שלב 7)
#  פתוחה כרגיל (הלוח מקופל למעלה במשקוף). זומבי ENGINEER שמושך ידית בלוח בקרה
#  -> אזעקה + אור אדום מסתובב (0.7 שנ') -> הדלת יורדת וחוסמת את המעבר בקומת הקרקע.
#  נשארת סגורה hold שניות (נורות ספירה לאחור) ואז נפתחת שוב - אף פעם לא נתקעים לתמיד,
#  ויש תמיד דרך חלופית למעלה (הגשר שמעל הדלת).
#
#  * גוף פיזי: StaticBody2D בשכבה 1 (חוסם שחקן, זומבים וקליעים) - מופעל רק כשהדלת סגורה.
#  * היא "hazard" רק כדי שמהנדס ימצא אותה (triggerable) - active תמיד false, לא פוגעת.
#  * position = אמצע תחתית הדלת. height = גובה (עד מתחת לגשר).
#  איך משנים: height, width, hold (כמה זמן סגורה).
# ============================================================

const Art := preload("res://art.gd")
const Sfx := preload("res://sfx.gd")
const Particles := preload("res://particles.gd")

enum { OPEN, WARN, CLOSING, CLOSED, OPENING }

var height := 150.0
var width := 26.0
var hold := 6.0
var state := OPEN
var closes := 0                 # לבדיקות
var _st := 0.0
var _k := 0.0                   # 0 = פתוחה, 1 = סגורה
var _t := 0.0
var _body: StaticBody2D
var _cs: CollisionShape2D


func _ready() -> void:
	super._ready()
	add_to_group("s7_doors")
	triggerable = true
	active = false
	player_damage = 0
	rect = Rect2(-width * 0.5, -height, width, height)
	_body = StaticBody2D.new()
	_body.collision_layer = 1
	_body.collision_mask = 0
	_cs = CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = Vector2(width, height)
	_cs.shape = r
	_cs.position = Vector2(0.0, -height * 0.5)
	_cs.disabled = true
	_body.add_child(_cs)
	add_child(_body)
	z_index = 2


# ENGINEER / לוח בקרה: סוגר את הדלת
func trigger() -> void:
	if state == OPEN:
		_enter(WARN)


func is_closed() -> bool:
	return state == CLOSED


func link_point() -> Vector2:
	return global_position + Vector2(0.0, -height - 14.0)


func _enter(s: int) -> void:
	state = s
	_st = 0.0
	match s:
		WARN:
			Sfx.play("s7_klaxon", global_position + Vector2(0, -height), 0.0, 0.05, 2)
		CLOSED:
			closes += 1
			_shove()
			_cs.set_deferred("disabled", false)
			Sfx.play("s7_door", global_position, 2.0, 0.05, 2)
			if Art.on_screen(self, global_position):
				Particles.burst(get_parent(), global_position + Vector2(0, -3), "smoke", Vector2.UP, 8)
		OPENING:
			_cs.set_deferred("disabled", true)
			Sfx.play("s7_lift", global_position, -4.0, 0.05, 2)


# הדלת נסגרת על מישהו: דוחפים אותו לצד הקרוב (לא נתקעים בתוך הדלת)
func _shove() -> void:
	var list := get_tree().get_nodes_in_group("zombies")
	var pl := get_tree().get_first_node_in_group("player")
	if pl != null:
		list.append(pl)
	for b in list:
		var bp: Vector2 = b.global_position
		var dx := bp.x - global_position.x
		if absf(dx) < width * 0.5 + 14.0 and bp.y > global_position.y - height and bp.y <= global_position.y + 4.0:
			var side := signf(dx) if dx != 0.0 else -1.0
			b.global_position.x = global_position.x + side * (width * 0.5 + 16.0)


func _hazard_tick(delta: float) -> void:
	_t += delta
	_st += delta
	match state:
		WARN:
			if _st >= 0.7:
				_enter(CLOSING)
				Sfx.play("s7_lift", global_position, -2.0, 0.05, 2)
		CLOSING:
			_k = minf(1.0, _k + delta / 0.45)
			if _k >= 1.0:
				_enter(CLOSED)
		CLOSED:
			if _st >= hold:
				_enter(OPENING)
		OPENING:
			_k = maxf(0.0, _k - delta / 0.8)
			if _k <= 0.0:
				_enter(OPEN)
	if Art.on_screen(self, global_position + Vector2(0, -height * 0.5), 160.0) and (state != OPEN or Engine.get_physics_frames() % 15 == 0):
		queue_redraw()


func _draw() -> void:
	var w := width
	var steel := Color("3c4046")
	var dark := Color("1c1e22")
	var hz := Color("b8901c")
	# מסגרת: שני עמודים + משקוף
	for sx in [-1.0, 1.0]:
		var px: float = sx * (w * 0.5 + 6.0)
		draw_rect(Rect2(px - 5.0, -height - 10.0, 10.0, height + 10.0), dark)
		draw_rect(Rect2(px - 2.0, -height - 10.0, 3.0, height + 10.0), steel)
		var y := -height + 14.0
		while y < -6.0:   # פסי אזהרה על העמודים
			draw_colored_polygon(PackedVector2Array([Vector2(px - 5.0, y), Vector2(px + 5.0, y - 6.0), Vector2(px + 5.0, y), Vector2(px - 5.0, y + 6.0)]), Color(hz, 0.7))
			y += 20.0
	draw_rect(Rect2(-w * 0.5 - 12.0, -height - 14.0, w + 24.0, 16.0), dark)
	# הלוח: יורד מהמשקוף
	if _k > 0.0:
		var hh := height * _k
		Art.fill_shaded(self, PackedVector2Array([Vector2(-w * 0.5, -height), Vector2(w * 0.5, -height), Vector2(w * 0.5, -height + hh), Vector2(-w * 0.5, -height + hh)]), Color("50545a"), 0.2, 0.35)
		var y := -height + 10.0
		while y < -height + hh - 8.0:   # חריצים אופקיים + ברגים
			draw_line(Vector2(-w * 0.5 + 2, y), Vector2(w * 0.5 - 2, y), Color("2c2f34"), 1.0)
			draw_circle(Vector2(-w * 0.5 + 4, y + 4), 1.0, Color("7a8088"))
			draw_circle(Vector2(w * 0.5 - 4, y + 4), 1.0, Color("7a8088"))
			y += 18.0
		# שוליים תחתונים צהוב-שחור
		var by := -height + hh
		var x := -w * 0.5
		var i := 0
		while x < w * 0.5:
			draw_rect(Rect2(x, by - 7.0, minf(6.0, w * 0.5 - x), 7.0), hz if i % 2 == 0 else dark)
			x += 6.0
			i += 1
		if _k > 0.6:
			draw_string(ThemeDB.fallback_font, Vector2(-5, -height + hh * 0.45), "7", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(0.75, 0.7, 0.55, 0.5))
	# אור אזהרה מסתובב על המשקוף
	var alarm := state != OPEN
	var bc := Vector2(0, -height - 20.0)
	draw_rect(Rect2(bc.x - 5.0, bc.y - 2.0, 10.0, 6.0), dark)
	draw_circle(bc, 4.0, Color(1.0, 0.15, 0.1) if alarm else Color(0.3, 0.1, 0.08))
	if alarm:
		var a := _t * 9.0
		var beam := Vector2.from_angle(a) * 70.0
		draw_colored_polygon(PackedVector2Array([bc, bc + beam.rotated(-0.25), bc + beam.rotated(0.25)]), Color(1.0, 0.15, 0.1, 0.18 * absf(cos(a))))
		Art.glow(self, bc, 18.0, Color(1.0, 0.2, 0.1, 0.6))
	# ספירה לאחור: 3 נורות שכבות לפי הזמן שנשאר
	if state == CLOSED:
		var left := 1.0 - _st / hold
		for q in 3:
			var on := left > float(q) / 3.0
			draw_circle(Vector2(-8.0 + float(q) * 8.0, -height - 6.0), 2.0, Color(1.0, 0.3, 0.2) if on else Color(0.2, 0.1, 0.1))
