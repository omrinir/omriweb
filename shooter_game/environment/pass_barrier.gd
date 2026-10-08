extends Node2D
# ============================================================
#  PASS BARRIER - "אי אפשר לברוח מהם"
#  שחקן שרץ קדימה ומשאיר מאחוריו 4+ זומבים ערים (שכבר ראו אותו) -> מופיע מולו קיר אנרגיה שקוף.
#  הקיר חוסם רק את השחקן (שכבה 512): זומבים וקליעים עוברים. הוא נעלם כשכל מי שנשאר מאחור מת.
#  ככה לא נאסף מאחורי השחקן המון זומבים שרודפים אחריו (זה מה שהכביד על המשחק).
#  main.gd יוצר אותו פעם אחת בכל שלב.
# ============================================================

const Sfx := preload("res://sfx.gd")

const TRIGGER := 4          # כמה זומבים מאחור מקפיצים את הקיר
const BEHIND := 220.0       # כמה פיקסלים מאחורי השחקן נחשב "מאחור"
const RANGE := 1300.0       # רק כאלה שעוד באזור (רחוקים יותר ממילא ישנים)
const DROP_RANGE := 1700.0  # התרחק מאוד (נפל לבור / נתקע) - כבר לא נחשב
const AHEAD := 230.0        # כמה לפני השחקן הקיר עולה
const TIMEOUT := 40.0       # רשת ביטחון: אחרי 40 שניות הקיר נעלם בכל מקרה
const LAYER := 512          # שכבת הקיר (רק השחקן מתנגש בה - player.gd)
const COL := Color(1.0, 0.18, 0.12)

var main: Node = null
var _locked: Array = []     # הזומבים שהשאירו מאחור (צריך להרוג אותם)
var _wall: StaticBody2D = null
var _t := 0.0
var _check := 0.0
var _cool := 0.0
var _up := 0.0              # 0..1 הקיר עולה / יורד
var _fade := false
var _age := 0.0
var _total := 0


func _ready() -> void:
	z_index = 9


func _physics_process(delta: float) -> void:
	_t += delta
	_cool -= delta
	var p := get_tree().get_first_node_in_group("player")
	if p == null or p.dead or not get_tree().get_nodes_in_group("story_scene").is_empty():
		return
	if _wall != null:
		_age += delta
		_up = move_toward(_up, 0.0 if _fade else 1.0, delta * (2.0 if _fade else 4.0))
		queue_redraw()
		if _fade:
			if _up <= 0.0:
				_wall.queue_free()
				_wall = null
				_fade = false
				_cool = 2.0
			return
		_check -= delta
		if _check <= 0.0:
			_check = 0.2
			_locked = _locked.filter(func(z): return _still_counts(z, p))
			if _locked.is_empty() or _age > TIMEOUT:
				_open(p)
		return
	_check -= delta
	if _check > 0.0 or _cool > 0.0:
		return
	_check = 0.25
	var behind := []
	for z in get_tree().get_nodes_in_group("zombies"):
		if _eligible(z, p) and z.global_position.x < p.global_position.x - BEHIND and p.global_position.x - z.global_position.x < RANGE:
			behind.append(z)
	if behind.size() >= TRIGGER:
		_close(p, behind)


# זומבי ער, שראה את השחקן, שיכול ללכת אליו (לא שוכב / קפוא / עותק של מיראז')
func _eligible(z: Node, p: Node) -> bool:
	if not is_instance_valid(z) or z.dead or z.dormant or not z.get("_noticed"):
		return false
	if not z.is_physics_processing() or float(z.get("chase_speed")) <= 0.0:
		return false
	if z.get("type_mod") != null and z.type_mod.get("is_copy") == true:
		return false
	return absf(z.global_position.y - p.global_position.y) < 600.0


func _still_counts(z: Variant, p: Node) -> bool:
	if not is_instance_valid(z) or z.dead or not z.is_in_group("zombies"):
		return false
	return z.global_position.distance_to(p.global_position) < DROP_RANGE and z.is_physics_processing()


func _close(p: Node, behind: Array) -> void:
	var lw: float = float(main.level_w) if main != null else 100000.0
	var x := minf(p.global_position.x + AHEAD, lw - 120.0)
	if x <= p.global_position.x + 40.0:
		return
	_locked = behind
	_total = behind.size()
	_age = 0.0
	_up = 0.0
	_fade = false
	_wall = StaticBody2D.new()
	_wall.collision_layer = LAYER
	_wall.collision_mask = 0
	var cs := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = Vector2(26.0, 2600.0)
	cs.shape = r
	_wall.add_child(cs)
	add_child(_wall)
	_wall.global_position = Vector2(x, p.global_position.y - 400.0)
	Sfx.play("shield", _wall.global_position + Vector2(0, 380), 4.0)
	if p.has_method("_say"):
		p._say("THEY'RE BEHIND YOU", COL)


func _open(p: Node) -> void:
	_fade = true
	Sfx.play("zap", _wall.global_position + Vector2(0, 380), -2.0)


# קיר אנרגיה אדום שקוף: פסים שזורמים למעלה, קצוות מהבהבים, ומונה של מי שנשאר
func _draw() -> void:
	if _wall == null or _up <= 0.0:
		return
	var p := get_tree().get_first_node_in_group("player")
	var base: Vector2 = _wall.global_position - global_position
	var foot: float = (p.global_position.y - global_position.y + 4.0) if p != null else base.y + 400.0
	var h := 900.0 * _up
	var top: float = foot - h
	var flick := 0.85 + 0.15 * sin(_t * 23.0)
	var w := 22.0
	draw_rect(Rect2(Vector2(base.x - w, top), Vector2(w * 2.0, h)), Color(COL, 0.10 * flick))
	draw_rect(Rect2(Vector2(base.x - w * 0.45, top), Vector2(w * 0.9, h)), Color(COL, 0.13 * flick))
	for s in [-1.0, 1.0]:   # קצוות בוהקים
		draw_line(Vector2(base.x + s * w, top), Vector2(base.x + s * w, foot), Color(1.0, 0.45, 0.35, 0.55 * flick), 1.5)
	for i in 14:   # פסים שעולים
		var ly: float = foot - fposmod(_t * 160.0 + float(i) * 64.0, h)
		var a: float = 0.35 * (1.0 - (foot - ly) / h)
		draw_line(Vector2(base.x - w, ly), Vector2(base.x + w, ly), Color(1.0, 0.5, 0.4, a), 1.2)
	draw_rect(Rect2(Vector2(base.x - w - 6.0, foot - 4.0), Vector2((w + 6.0) * 2.0, 4.0)), Color(1.0, 0.3, 0.2, 0.6 * flick))   # בסיס זוהר
	if not _fade:
		var f := ThemeDB.fallback_font
		var txt := "KILL THEM  %d" % _locked.size()
		var tp := Vector2(base.x - 70.0, foot - 118.0)
		draw_string_outline(f, tp, txt, HORIZONTAL_ALIGNMENT_CENTER, 140.0, 14, 4, Color(0, 0, 0, 0.75 * _up))
		draw_string(f, tp, txt, HORIZONTAL_ALIGNMENT_CENTER, 140.0, 14, Color(1.0, 0.45, 0.38, _up))
		draw_string(f, tp + Vector2(0, 16), "<<", HORIZONTAL_ALIGNMENT_CENTER, 140.0, 13, Color(1.0, 0.45, 0.38, 0.6 * _up * flick))
