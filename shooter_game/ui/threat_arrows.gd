extends Node
const DrawBatch := preload("res://effects/draw_batch.gd")
const ZombieScript := preload("res://zombie.gd")
# ============================================================
#  THREAT ARROWS - חץ אדום קטן בקצה המסך כשזומבי עומד להגיע אליך מחוץ למסך (מאחור, מלמעלה...).
#  רק מי שבאמת בדרך: ער, גלוי (לא במארב), זז לכיוונך ויגיע תוך TTC_MAX שניות. זומבי איטי ורחוק - בלי חץ.
#  ככל שהוא קרוב יותר החץ גדל, מתחזק ופועם מהר יותר; ממש קרוב = חץ כפול. בוס = חץ גדול יותר.
#  נעלם (בדעיכה קצרה) כשהזומבי נכנס למסך או מת. כמה זומבים מאותו כיוון = חץ אחד.
#  מהפיץ': "אף פעם לא מכה שלא ראית".
# ============================================================

const TTC_MAX := 3.2       # שניות עד המגע: מתחת לזה מופיע חץ (רץ מופיע בערך שנייה לפני שהוא נכנס למסך)
const TTC_FULL := 0.8      # מתחת לזה = עוצמה מלאה
const MIN_SPEED := 60.0    # מהירות לכיוונך (פחות = משוטט, לא איום)
const REACH := 30.0
const MAX_DIST := 1300.0   # (רחוק מ-1400 הזומבים "ישנים" ולא זזים)
const INSET := 22.0        # מרחק החץ מקצה המסך
const TOP := 175.0         # מתחת ל-HUD
const MERGE := 34.0        # חצים קרובים מזה = אחד
const COL := Color(1.0, 0.22, 0.18)

var main: Node
var _layer: CanvasLayer
var _ui: Node2D
var _marks := {}   # instance id -> [מיקום במסך, כיוון, עוצמה 0..1, שקיפות, בוס, נמצא בסריקה האחרונה]
var _t := 0.0
var _scan_t := 0.0
var _empty := false


func _ready() -> void:
	_layer = CanvasLayer.new()
	_layer.layer = 3
	add_child(_layer)
	_ui = Node2D.new()
	_layer.add_child(_ui)
	_ui.draw.connect(_draw_ui)


func _process(delta: float) -> void:
	_t += delta
	_scan_t -= delta
	if _scan_t <= 0.0:   # 20 פעמים בשנייה מספיק (עם 100 זומבים זה כבר עולה משהו)
		_scan_t = 0.05
		for id in _marks:
			_marks[id][5] = false
		var p = get_tree().get_first_node_in_group("player")
		if p != null and not p.dead and ZombieScript.mind_traitor == null and not (main != null and main._finished) \
				and get_tree().get_nodes_in_group("story_scene").is_empty():
			_scan(p)
	for id in _marks.keys():
		var m: Array = _marks[id]
		m[3] = move_toward(m[3], 1.0 if m[5] else 0.0, delta / (0.12 if m[5] else 0.2))
		if m[3] <= 0.0 and not m[5]:
			_marks.erase(id)
	if _marks.is_empty() and _empty:   # כבר נמחק: אין מה לצייר מחדש
		return
	_empty = _marks.is_empty()
	_ui.queue_redraw()


func _scan(p: Node2D) -> void:
	var vp := _ui.get_viewport_rect().size
	var ct := _ui.get_viewport().get_canvas_transform()
	var inner := Rect2(Vector2(INSET, TOP), vp - Vector2(INSET * 2.0, TOP + INSET))
	var screen := Rect2(Vector2(-6.0, -6.0), vp + Vector2(12.0, 12.0))
	var pc: Vector2 = p.global_position + Vector2(0.0, -40.0)
	for z in get_tree().get_nodes_in_group("zombies"):
		if z.dead or z.dormant or not z.visible or z == ZombieScript.mind_traitor:
			continue
		var c: Vector2 = z.global_position + Vector2(0.0, -40.0 * float(z.sc))
		var to: Vector2 = pc - c
		var dist := to.length()
		if dist > MAX_DIST or dist < 1.0:
			continue
		var sp: Vector2 = ct * c
		if screen.has_point(sp):   # על המסך: רואים אותו
			continue
		var id: int = z.get_instance_id()
		var had: bool = _marks.has(id)   # כבר מוצג: ספים רכים יותר, שהחץ לא יהבהב כשהמהירות שלו קופצת
		var app: float = (z.velocity as Vector2).dot(to / dist)
		if app < MIN_SPEED * (0.5 if had else 1.0):
			continue
		var ttc := maxf(dist - REACH, 0.0) / app
		if ttc > TTC_MAX * (1.3 if had else 1.0):
			continue
		var at := Vector2(clampf(sp.x, inner.position.x, inner.end.x), clampf(sp.y, inner.position.y, inner.end.y))
		var k := clampf(1.0 - (ttc - TTC_FULL) / (TTC_MAX - TTC_FULL), 0.0, 1.0)
		var m: Array = _marks.get(id, [at, Vector2.LEFT, 0.0, 0.0, false, true])
		m[0] = at
		m[1] = (sp - at).normalized() if sp.distance_to(at) > 1.0 else Vector2.LEFT
		m[2] = k
		m[4] = z.is_boss()
		m[5] = true
		_marks[id] = m


func _draw_ui() -> void:
	if _marks.is_empty():
		return
	var list: Array = _marks.values()
	list.sort_custom(func(a, b): return a[2] * a[3] > b[2] * b[3])
	var shown := []   # [מיקום, כמה זומבים, החץ החזק]
	DrawBatch.begin(_ui)
	for m in list:
		var near := -1
		for i in shown.size():
			if (shown[i][0] as Vector2).distance_to(m[0]) < MERGE:
				near = i
				break
		if near >= 0:   # כבר יש חץ חזק יותר כאן
			shown[near][1] += 1
			continue
		shown.append([m[0], 1, m])
	for sh in shown:
		var m: Array = sh[2]
		var k: float = m[2]
		var a: float = m[3] * lerpf(0.6, 1.0, k)
		var s: float = lerpf(0.95, 1.35, k) * (1.35 if m[4] else 1.0) * minf(1.0 + 0.1 * float(sh[1] - 1), 1.3)
		s *= 1.0 + 0.12 * sin(_t * lerpf(7.0, 16.0, k))
		_arrow(m[0], m[1], s, a)
		if k > 0.7:   # ממש קרוב: חץ שני מאחור
			_arrow(m[0] - (m[1] as Vector2) * 13.0 * s, m[1], s * 0.8, a * 0.75)
	DrawBatch.end(_ui)


func _arrow(at: Vector2, dir: Vector2, s: float, a: float) -> void:
	var n := Vector2(-dir.y, dir.x)
	DrawBatch.circle(_ui, at, 18.0 * s, Color(COL, 0.07 * a))   # הילה
	DrawBatch.circle(_ui, at, 12.0 * s, Color(COL, 0.10 * a))
	for pass_i in 2:   # קו מתאר כהה, ואז האדום
		var g := 1.0 + 0.3 * float(1 - pass_i)
		var tip := at + dir * 11.0 * s * g
		var b := at - dir * 7.0 * s * g
		var pts := PackedVector2Array([tip, b + n * 10.0 * s * g, b + dir * 4.0 * s * g, b - n * 10.0 * s * g])
		DrawBatch.colored_polygon(_ui, pts, Color(0.12, 0.0, 0.0, 0.75 * a) if pass_i == 0 else Color(COL, a))
