extends Node
# ============================================================
#  PACE DIRECTOR - קצב: המסך לא נשאר ריק מזומבים הרבה זמן.
#  אם אין אף זומבי על המסך כבר IDLE_GAP שניות, ואף אחד לא "עומד להיכנס" מקדימה,
#  קבוצה קטנה (2-3, לפי zombie_weights של השלב) נכנסת מחוץ למסך מקדימה ורצה אל השחקן.
#  תקציב לכל שלב (BUDGET_SHARE מכמות הפיזור הרגיל) - השלב לא נהיה אינסופי.
#  לא באזור ההתחלה, לא ליד הבוס, לא בסצנת סיפור, לא כשהשחקן מתחת לכביש.
#  שלב עם מנהל גלים משלו (שלב 16) מבטל: stage.pace_stream() -> false.
#  main.gd יוצר אותו פעם אחת בכל שלב.
# ============================================================

const CHECK := 0.25            # כל כמה שניות בודקים
const IDLE_GAP := 1.6          # כמה שניות מסך ריק מותר
const COOLDOWN := 4.0          # מינימום בין שתי קבוצות
const AHEAD_MIN := 640.0       # כמה לפני השחקן הם מופיעים (חצי מסך = 512, בטלפון 400)
const AHEAD_MAX := 820.0
const COMING := 900.0          # זומבי בטווח הזה מקדימה = עוד רגע מגיע, לא צריך תגבורת
const SCREEN_HALF := 540.0     # "על המסך" (קצת יותר מחצי רוחב)
const SCREEN_UP := 520.0       # כמה מעל הכביש עוד נחשב על המסך
const MAX_AWAKE := 4           # כבר יש כמה ערים בסביבה (מאחור / בקומות) - לא מוסיפים
const AWAKE_R := 1300.0
const BUDGET_SHARE := 0.5      # כמה זומבים נוספים מותר בשלב (חלק מהפיזור הרגיל)
const START_X := 900.0         # לא באזור ההתחלה
const BOSS_ZONE := 1500.0      # לא ליד הבוס (מסוף השלב)
const ALERT := 6.0             # רצים אל השחקן מיד (לא מטיילים)

var main: Node = null
var floor_y := 630.0
var budget := 0
var _t := 0.0
var _idle := 0.0
var _cool := 0.0
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.randomize()


func _physics_process(delta: float) -> void:
	_t -= delta
	_cool -= delta
	if _t > 0.0:
		return
	_t = CHECK
	if budget <= 0 or main == null or main._finished or main.clock_paused:
		_idle = 0.0
		return
	var p: Node2D = get_tree().get_first_node_in_group("player")
	if p == null or p.dead:
		return
	var px := p.global_position.x
	var py := p.global_position.y
	if px < START_X or px > main.level_w - BOSS_ZONE or py > floor_y + 30.0 or py < floor_y - 380.0:
		_idle = 0.0
		return
	var on := 0
	var coming := 0
	var awake := 0
	for z in get_tree().get_nodes_in_group("zombies"):
		if z.dead:
			continue
		var d: Vector2 = z.global_position - p.global_position
		if absf(d.x) < SCREEN_HALF and z.global_position.y > floor_y - SCREEN_UP and z.global_position.y < floor_y + 120.0:
			on += 1
			break
		if d.x > 0.0 and d.x < COMING and absf(z.global_position.y - floor_y) < 200.0:
			coming += 1
		if absf(d.x) < AWAKE_R and not z.dormant and z._chasing:
			awake += 1
	if on > 0 or coming > 0 or awake >= MAX_AWAKE:
		_idle = 0.0
		return
	_idle += CHECK
	if _idle < IDLE_GAP or _cool > 0.0:
		return
	var x := _spot(px)
	if x < 0.0:
		return
	_idle = 0.0
	_cool = COOLDOWN
	var k0: int = main._pick_kind(_rng)
	var n := mini(_rng.randi_range(2, 3), budget)
	if k0 == 10 or k0 == 15:   # חולדות / כלבים - הגודל שלהם
		n = main._group_size(k0, _rng)
	for z in main._spawn_group(_rng, x, floor_y, k0, n, false):
		if z == null or not is_instance_valid(z):
			continue
		if z.is_boss():   # משקל של בוס בטעות - לא באמצע השלב
			z.queue_free()
			continue
		budget -= 1
		z._dir = -1.0
		z._alert_t = ALERT


# מקום פנוי על הכביש מקדימה (לא בבור / תעלה / מכשול / בתוך קיר). -1 = אין
func _spot(px: float) -> float:
	var ss: PhysicsDirectSpaceState2D = main.get_world_2d().direct_space_state
	for i in 8:
		var x := px + _rng.randf_range(AHEAD_MIN, AHEAD_MAX) + float(i) * 37.0
		if x > main.level_w - BOSS_ZONE + 400.0:
			return -1.0
		if main._near_brick(x) or main._near_brick(x + 110.0):
			continue
		if main._spawn_blocked(x - 30.0, x + 140.0):   # אש / חומצה / פס מחושמל
			continue
		# יש קרקע בגובה הכביש (לא בור / מים)
		var ray := PhysicsRayQueryParameters2D.create(Vector2(x, floor_y - 30.0), Vector2(x, floor_y + 12.0), 1)
		var hit: Dictionary = ss.intersect_ray(ray)
		if hit.is_empty() or absf(float(hit.position.y) - floor_y) > 6.0:
			continue
		# לא בתוך גוף מוצק
		var q := PhysicsShapeQueryParameters2D.new()
		var r := RectangleShape2D.new()
		r.size = Vector2(130.0, 50.0)
		q.shape = r
		q.transform = Transform2D(0.0, Vector2(x + 50.0, floor_y - 32.0))
		q.collision_mask = 1
		if not ss.intersect_shape(q, 1).is_empty():
			continue
		return x
	return -1.0
