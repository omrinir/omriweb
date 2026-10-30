extends Node
# ============================================================
#  FLANK DIRECTOR - "THEY LEARN": מדי פעם זומבי (לפעמים שניים) מתגנב מאחורי השחקן.
#  מעט: כמה פעמים בשלב (EVENTS לפי האזור ורמת הקושי), עם הפסקה ארוכה בין פעם לפעם (GAP).
#  מתי: כשהשחקן עסוק קדימה (ירה ימינה עכשיו / זומבי ער מולו) או עומד במקום (CAMP_T) - אז זה מלקחיים.
#    מי שנוטה לעמוד במקום (PlayerMemory.camping) - הם לומדים את זה ובאים מאחור קצת יותר מהר (CAMP_GAP_K).
#  לא: בשלב 1, באזור ההתחלה, ליד בוס, בסצנת סיפור, ב-HOLD THE LINE / ESCAPE (event.is_active()), כשנשאר לב אחד,
#    כשהשחקן פונה / הולך שמאלה ("מאחור" זה מולו), כשכבר יש הרבה ערים מסביב או מאחור (pass_barrier.gd נדלק ב-4).
#  איפה: ממש מחוץ למסך משמאל (BEHIND_MIN..BEHIND_MAX), על הכביש (לא בבור / מים / אש / בתוך קיר),
#    ובלי קיר גבוה בדרך אל השחקן (WALL_H).
#  מי: מהתמהיל של השלב - רק מי שהולך / רץ אליך בעצמו ונושך: לא בוס, לא חולדות (להקה), לא זוחל תקרה,
#    לא סוג עם תנועה משלו, לא איטי (MIN_CHASE), לא קשור בכבל, ולא מי שיורה / זורק מרחוק או מחכה במקום
#    (NO_KINDS, וכל סוג עם קבוע RANGE / KEEP... - NO_CONSTS) - יריות בגב ממחוץ למסך זה לא הוגן. כלבים באים בזוג.
#    מתגנב שלא זז STALL_T שניות = סוג חדש שמחכה במקום: לא שולחים עוד ממנו בשלב (_hunt).
#  שומעים אותם לפני שרואים (הצרחה כשהם מזהים אותך - מצד שמאל), והחץ האדום (ui/threat_arrows.gd) מראה מאיפה.
#  main.gd יוצר אותו ליד PACE DIRECTOR (לא בשלב עם מנהל גלים משלו: stage.pace_stream() -> false).
# ============================================================

const Registry := preload("res://enemies/zombie_registry.gd")

const FROM_LEVEL := 2                   # שלב 1 = לומדים לשחק: אף אחד לא בא מאחור
const CHECK := 0.25                     # כל כמה שניות בודקים
const FIRST_T := 20.0                   # שקט בתחילת השלב (גם אחרי TRY AGAIN)
const TIER_FROM := [2, 10, 28, 46]      # אזורים: שלבים 2-9 / 10-27 / 28-45 / 46+
const EVENTS := [2, 2, 3, 3]            # כמה פעמים בשלב (מעט: "לא הרבה זומבים משמאל")
const GAP := [Vector2(40.0, 60.0), Vector2(32.0, 50.0), Vector2(28.0, 45.0), Vector2(25.0, 40.0)]   # שניות בין פעם לפעם
const PAIR := [0.15, 0.25, 0.3, 0.35]   # הסיכוי שבאים שניים
const DIFF_EVENTS := [-1, 0, 1]         # קל / רגיל / קשה
const DIFF_GAP := [1.25, 1.0, 0.85]
const CAMP_LEARN := 0.35                # PlayerMemory.camping מעל זה = "הוא תמיד עומד במקום"
const CAMP_GAP_K := 0.75
const BEHIND_MIN := 600.0               # כמה מאחורי השחקן (חצי מסך = 512): מחפשים מקום פנוי מכאן...
const BEHIND_MAX := 1000.0              # ...ועד כאן, מהקרוב לרחוק (בשלבים צפופים במכשולים צריך לחפש רחוק יותר)
const SPOT_TRIES := 10
const START_CLEAR := 1500.0             # השחקן עבר לפחות כך מההתחלה
const BOSS_ZONE := 1500.0               # לא בסוף השלב (הבוס)
const BOSS_NEAR := 1800.0               # לא ליד בוס (גם בוס באמצע השלב: 10, 19, 40)
const ENGAGE := 750.0                   # זומבי ער כל כך קרוב מקדימה = השחקן עסוק
const SHOT_RECENT := 1.5                # ירה ימינה לפני פחות מזה = עסוק
const CAMP_T := 3.0                     # עומד באותו מקום (CAMP_R) כל כך הרבה זמן
const CAMP_R := 80.0
const CROWD := 3                        # יותר רודפים מזה בסביבה (CROWD_R) -> מחכים
const CROWD_R := 900.0
const BEHIND_AWAKE := 1                 # כבר יש כל כך הרבה ערים מאחור -> מחכים (עם עוד 2 לא מגיעים ל-4)
const MIN_HP := 2                       # לב אחד אחרון: לא מתגנבים
const TRY := 0.35                       # הסיכוי בכל בדיקה כשהכל מתאים (לא תמיד באותו רגע בדיוק)
const ALERT := 10.0                     # רצים אל השחקן מיד (כמו pace_director, יותר כי באים מרחוק - גם בשלב חשוך)
const HUNT_T := 12.0                    # עד אז הם יודעים איפה השחקן גם כשמכונית / ארגז מסתירים אותו (קריאה מחבר: zombie_brain.hear_call)
const STALL_T := 5.0                    # מתגנב שלא זז כל הזמן הזה (סוג שמחכה במקום / תקוע) - לא שולחים עוד מהסוג שלו בשלב
const WALL_H := 150.0                   # מכשול בגובה הזה בין המקום לשחקן = קיר שלא עוברים
# לא שולחים מאחור (וגם לא כל סוג עם קבוע NO_CONSTS / KEEP...). נבדק בכל השלבים: devtools/t_flank_reach.gd
const NO_KINDS := [
	3, 13, 16, Registry.BANDLEADER, Registry.FLAMER, Registry.PIONEER,   # יורק, זורק אימפים, שיכור עם אקדח, טובה, להביור, בונה קירות
	8, Registry.WALL_CRAWLER, Registry.GLIDER, Registry.DRILLER,          # תקרה / קירות / דאון מקומה / קודח מתחת לאדמה
	Registry.AMBUSHER, Registry.SPLITJAW, Registry.MIMIC, Registry.GHILLIE, Registry.SCARECROW, Registry.CLINGER,
	Registry.ENCASED, Registry.WASHER, Registry.ANGLER, Registry.COFFIN_BREAKER,   # אורבים: מחכים במקום שתעבור לידם
	10, Registry.RIDER, Registry.TORO,                                    # חולדות (להקה), פרש / שור שמסתערים (חזק מדי מאחור)
]
const NO_CONSTS := ["LEASH", "RANGE", "THROW_RANGE"]   # קבועים של סוג = קשור בכבל / יורה-זורק מרחוק (וגם כל KEEP... = שומר מרחק)
const DOG := 15
const MIN_CHASE := 70.0                 # איטי מזה (ענק, מכונות) לא מגיע אליך מאחור
const KIND_TRIES := 6

var main: Node = null
var floor_y := 630.0
var events := 0
var spawned := 0                        # לבדיקות (devtools/t_flank.gd)
var _t := 0.0
var _cool := FIRST_T
var _shots := -1                        # PlayerMemory.shots_total בבדיקה הקודמת
var _shot_t := 99.0                     # שניות מאז הירייה האחרונה ימינה
var _camp_pos := Vector2.ZERO
var _camp_t := 0.0
var _kind_ok := {}                      # kind -> מתאים / לא (בודקים כל סוג פעם אחת בשלב)
var _hunters: Array = []                # [זומבי, עד מתי, x אחרון שזז ממנו, מתי זז] - המתגנבים שעוד בדרך
var _time := 0.0
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.randomize()
	if Game.level >= FROM_LEVEL:
		events = maxi(1, int(EVENTS[_tier()]) + int(DIFF_EVENTS[_diff()]))


func _tier() -> int:
	var t := 0
	for i in TIER_FROM.size():
		if Game.level >= int(TIER_FROM[i]):
			t = i
	return t


func _diff() -> int:
	return clampi(int(Settings.difficulty), 0, 2)


func _physics_process(delta: float) -> void:
	_cool -= delta
	_shot_t += delta
	_time += delta
	_t -= delta
	if _t > 0.0:
		return
	_t = CHECK
	if main == null or main._finished:
		return
	var p: Node2D = get_tree().get_first_node_in_group("player")
	if p == null or p.dead:
		return
	_hunt(p)
	if events <= 0 or main.clock_paused:
		return
	_track(p)
	if _cool > 0.0 or not _fits(p) or _rng.randf() > TRY:
		return
	var x := _spot(p.global_position.x)
	if x < 0.0 or _send(p, x) == 0:
		return
	events -= 1
	var g: Vector2 = GAP[_tier()] * float(DIFF_GAP[_diff()])
	_cool = _rng.randf_range(g.x, g.y) * (CAMP_GAP_K if PlayerMemory.camping > CAMP_LEARN else 1.0)


# המתגנבים שבדרך "שומעים" איפה השחקן (כמו קריאה מחבר - zombie_brain.hear_call), עד HUNT_T:
# בלי זה זומבי שלא רואה אותך מאחורי מכונית הולך למקום שבו ראה אותך אחרון ומחפש שם.
# מי שלא זז בכלל STALL_T שניות - כנראה סוג שמחכה במקום (אורב / מתחבא): לא שולחים עוד ממנו בשלב הזה.
func _hunt(p: Node2D) -> void:
	for i in range(_hunters.size() - 1, -1, -1):
		var h: Array = _hunters[i]
		var z = h[0]
		if not is_instance_valid(z) or z.dead or _time > float(h[1]):
			_hunters.remove_at(i)
			continue
		if absf(z.global_position.x - float(h[2])) >= 40.0:
			h[2] = z.global_position.x
			h[3] = _time
		elif _time - float(h[3]) > STALL_T and absf(z.global_position.x - p.global_position.x) > 150.0:
			_kind_ok[int(z.kind)] = false
			_hunters.remove_at(i)
			continue
		if z.brain != null:
			z.brain.hear_call(p.global_position, CHECK)


# יורה ימינה? עומד במקום?
func _track(p: Node2D) -> void:
	if PlayerMemory.shots_total != _shots:
		if _shots >= 0 and p._face() > 0.0:
			_shot_t = 0.0
		_shots = PlayerMemory.shots_total
	if p.global_position.distance_to(_camp_pos) < CAMP_R:
		_camp_t += CHECK
	else:
		_camp_pos = p.global_position
		_camp_t = 0.0


# הרגע מתאים: השחקן עסוק קדימה / עומד, לא מוצף, לא ליד בוס, לא באירוע
func _fits(p: Node2D) -> bool:
	var px := p.global_position.x
	var py := p.global_position.y
	if p.health < MIN_HP or px < START_CLEAR or px > main.level_w - BOSS_ZONE or py > floor_y + 30.0 or py < floor_y - 380.0:
		return false
	if p._face() < 0.0 or p.velocity.x < -60.0:
		return false
	if not get_tree().get_nodes_in_group("story_scene").is_empty():
		return false
	var ev = main.get("_event")
	if ev != null and is_instance_valid(ev) and ev.has_method("is_active") and ev.is_active():
		return false
	var busy := _shot_t < SHOT_RECENT or _camp_t >= CAMP_T
	var crowd := 0
	var behind := 0
	for z in get_tree().get_nodes_in_group("zombies"):
		if z.dead:
			continue
		var d: Vector2 = z.global_position - p.global_position
		if z.is_boss() and d.length() < BOSS_NEAR:
			return false
		if z.dormant or absf(d.x) > 1300.0:
			continue
		if d.x < -150.0 and z._noticed:   # כבר ראה אותך ונשאר מאחור (כמו pass_barrier.gd - שלא יגיעו ל-4)
			behind += 1
		if not z._chasing:
			continue
		if absf(d.x) < CROWD_R:
			crowd += 1
		if d.x > 0.0 and d.x < ENGAGE and absf(d.y) < 250.0:
			busy = true
	return busy and crowd <= CROWD and behind <= BEHIND_AWAKE


# מקום פנוי על הכביש מאחור (אותן בדיקות כמו pace_director._spot, וגם בלי קיר גבוה בדרך). -1 = אין
func _spot(px: float) -> float:
	var ss: PhysicsDirectSpaceState2D = main.get_world_2d().direct_space_state
	for i in SPOT_TRIES:
		var x := px - lerpf(BEHIND_MIN, BEHIND_MAX, (float(i) + _rng.randf()) / float(SPOT_TRIES))
		if x < float(main.safe_zone):
			return -1.0
		if main._near_brick(x) or main._near_brick(x + 60.0):
			continue
		if main._spawn_blocked(x - 30.0, x + 90.0):   # אש / חומצה / פס מחושמל
			continue
		var ray := PhysicsRayQueryParameters2D.create(Vector2(x, floor_y - 30.0), Vector2(x, floor_y + 12.0), 1)
		var hit: Dictionary = ss.intersect_ray(ray)
		if hit.is_empty() or absf(float(hit.position.y) - floor_y) > 6.0:   # בור / מים
			continue
		var q := PhysicsShapeQueryParameters2D.new()
		var r := RectangleShape2D.new()
		r.size = Vector2(90.0, 50.0)
		q.shape = r
		q.transform = Transform2D(0.0, Vector2(x + 25.0, floor_y - 32.0))
		q.collision_mask = 1
		if not ss.intersect_shape(q, 1).is_empty():   # בתוך גוף מוצק
			continue
		var wall := PhysicsRayQueryParameters2D.create(Vector2(x, floor_y - WALL_H), Vector2(px, floor_y - WALL_H), 1)
		if not ss.intersect_ray(wall).is_empty():
			continue
		return x
	return -1.0


# אחד (או זוג) מהתמהיל של השלב, רצים אל השחקן. מחזיר כמה יצאו
func _send(p: Node2D, x: float) -> int:
	var first: Node = _flanker(x, -1)
	if first == null:
		return 0
	var out := [first]
	if int(first.kind) == DOG or _rng.randf() < float(PAIR[_tier()]):
		var second: Node = _flanker(x + 50.0, DOG if int(first.kind) == DOG else -1)
		if second != null:
			out.append(second)
	for z in out:
		z._dir = 1.0
		z._alert_t = ALERT
		_hunters.append([z, _time + HUNT_T, z.global_position.x, _time])
		spawned += 1
	return out.size()


func _flanker(x: float, kind: int) -> Node:
	for i in KIND_TRIES:
		var k: int = kind if kind >= 0 else main._pick_kind(_rng)
		if not NO_KINDS.has(k) and _kind_ok.get(k, true):
			var z: Node = main._spawn_zombie(x, floor_y, k, null)
			_kind_ok[k] = _can_flank(z)
			if _kind_ok[k]:
				return z
			z.queue_free()
		if kind >= 0:
			return null
	return null


func _can_flank(z: Node) -> bool:
	if z.is_boss() or float(z.chase_speed) < MIN_CHASE or (int(z.collision_layer) & 4) == 0:
		return false
	if z.type_mod != null:
		if not z.type_mod.use_brain_movement():
			return false
		for c in z.type_mod.get_script().get_script_constant_map():
			if NO_CONSTS.has(c) or str(c).begins_with("KEEP"):
				return false
	return true
