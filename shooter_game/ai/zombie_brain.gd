extends RefCounted
# ============================================================
#  ZOMBIE BRAIN - "המוח" של כל זומבי (חוץ מבוסים / מכונות עם לוגיקה משלהם)
#
#  כל זומבי מקבל מוח כזה ב-zombie.gd -> _ready. המוח לא מזיז את הזומבי בעצמו -
#  הוא רק מחליט לאן ללכת ובאיזו מהירות (steer), ו-zombie.gd מבצע.
#
#  תפקידים (role):
#    APPROACH - מתקרב (עוד רחוק)
#    ATTACK   - יש לו "תור" להתקפה (ai/squad_director.gd מחלק תורות)
#    FLANK    - אין תור: עוקף ותוקף מהצד השני / מלמעלה
#    HOLD     - אין תור: מחכה במרחק, מוכן לקפוץ פנימה
#    RETREAT  - נסוג (פצוע / אחרי נשיכה מהירה)
#    AMBUSH   - מחכה בשקט עד שהשחקן עובר, ואז תוקף מאחור
#    WAIT     - עומד במקום (פקודה)
#    COVER    - רץ למחסה
#    CONFUSED - המנהיג מת: מבולבל לכמה שניות
#
#  הוגנות (לא מרמים!):
#    * רואים אותך רק בקו ראייה ישיר (קרן), וזוכרים רק memory_duration שניות.
#    * החלטות רק כל reaction_time שניות (לא פחות מ-0.25).
#    * לכל היותר attack_slots תוקפים ביחד (+1 כשאתה טוען / נתפס).
#
#  איפה משנים את האינטליגנציה: ai/intelligence_profile.gd
#  איך זומבי חדש משנה את המוח שלו: enemies/types/*.gd -> brain_overrides()
# ============================================================

const Profile := preload("res://ai/intelligence_profile.gd")

enum { APPROACH, ATTACK, FLANK, HOLD, RETREAT, AMBUSH, WAIT, COVER, CONFUSED }
const ROLE_NAMES := ["APPROACH", "ATTACK", "FLANK", "HOLD", "RETREAT", "AMBUSH", "WAIT", "COVER", "CONFUSED"]

var p := {}                      # הפרמטרים (מהפרופיל + תוספות לפי סוג)
var role := APPROACH
var role_t := 0.0                # כמה זמן נשאר לתפקיד הנוכחי
var steer_movement := true       # false = לזומבי יש לוגיקת תנועה משלו (המוח רק "רואה" ומתקשר)
var sees := false
var last_seen := Vector2.ZERO
var seen_t := 999.0              # כמה זמן עבר מאז שראה את השחקן
var flank_side := 1.0
var hold_dist := 200.0
var forced_role := -1            # פקודה מ-COMMANDER / מנהיג
var forced_t := 0.0
var confused_t := 0.0
var leader_boost := 0.0
var heard_t := -1.0              # קיבל קריאה מחבר: מגיע בעוד X שניות
var heard_pos := Vector2.ZERO
var _decide_t := 0.0
var _t := 0.0
var _hop_cd := 0.0
var _charge_state := 0           # 0 = רגיל, 1 = מתכונן, 2 = מסתער
var _charge_t := 0.0
var _charge_cd := 0.0
var _burst_t := 0.0              # האצה קצרה (יציאה ממארב / גל התקפה)
var _dodge_t := 0.0
var _dodge_dir := 1.0
var _ambush_side := 0.0
var _flank_leap := false
var _director: Node = null
var _started := false


func setup(z: Node, level: int, smart: float, overrides: Dictionary) -> void:
	p = Profile.for_level(level, smart)
	_merge(Profile.KIND_OVERRIDES.get(z.kind, {}))
	_merge(overrides)
	hold_dist = float(p.get("keep_range", randf_range(170.0, 240.0)))
	_decide_t = randf_range(0.0, float(p.reaction_time))
	if p.get("ambusher", false):
		role = AMBUSH


func _merge(o: Dictionary) -> void:
	for k in o:
		var v = o[k]
		if p.has(k) and (v is float or v is int) and (p[k] is float or p[k] is int) and not (k == "attack_slots"):
			p[k] = clampf(float(p[k]) + float(v), 0.0, 1.0) if float(p[k]) <= 1.0 else float(p[k]) + float(v)
		else:
			p[k] = v


func director() -> Node:
	if _director == null or not is_instance_valid(_director):
		var tree := Engine.get_main_loop() as SceneTree
		_director = tree.get_first_node_in_group("squad_director") if tree != null else null
	return _director


func coord() -> float:
	if confused_t > 0.0:
		return 0.0
	return clampf(float(p.coordination_level) + leader_boost, 0.0, 1.0)


func adapt_k() -> float:
	return clampf(float(p.adaptation_level), 0.0, 1.0)


# האם הזומבי עדיין "יודע" איפה השחקן (ראה אותו לאחרונה / שמע עליו)
func tracking() -> bool:
	return seen_t < float(p.memory_duration) or heard_t >= 0.0


# ראה את השחקן בפעם הראשונה: מזעיק חברים (משלב 5)
func on_notice(z: Node, player: Node) -> void:
	sees = true
	seen_t = 0.0
	last_seen = player.global_position
	var d := director()
	if d != null and int(p.communication) > 0:
		d.broadcast(z, player.global_position)


# חבר קרא לו
func hear_call(pos: Vector2, delay: float) -> void:
	if heard_t < 0.0 and seen_t > 1.0:
		heard_t = delay
		heard_pos = pos


func command(r: int, seconds: float) -> void:
	forced_role = r
	forced_t = seconds
	role = r
	role_t = seconds


func confuse(seconds: float) -> void:
	confused_t = seconds
	role = CONFUSED


# ---- אחרי נשיכה: רץ נסוג קצת ואז חוזר (hit & run) ----
func on_bite(z: Node) -> void:
	if randf() < float(p.get("hit_and_run", 0.0)):
		_set_role(z, RETREAT, randf_range(0.5, 0.9))


func _set_role(z: Node, r: int, t := 0.0) -> void:
	if r != ATTACK and role == ATTACK:
		var d := director()
		if d != null:
			d.release_slot(z)
	role = r
	role_t = t


# ============================================================
#  steer: נקרא מ-zombie.gd בכל פריים שהזומבי רודף.
#  מחזיר את המהירות הרצויה וקובע את z._dir (כיוון).
# ============================================================
func steer(z: Node, player: Node, d: Vector2, delta: float, base_speed: float) -> float:
	_t += delta
	role_t -= delta
	forced_t -= delta
	confused_t -= delta
	seen_t += delta
	_hop_cd -= delta
	_charge_cd -= delta
	_burst_t -= delta
	_dodge_t -= delta
	if heard_t >= 0.0:
		heard_t -= delta
		if heard_t < 0.0:   # הקריאה הגיעה: יודע איפה השחקן (אבל לא בדיוק)
			last_seen = heard_pos
			seen_t = 0.5
			z._alert_t = maxf(z._alert_t, 4.0)
	_decide_t -= delta
	if _decide_t <= 0.0:
		_decide_t = float(p.reaction_time) * randf_range(0.8, 1.25)
		_perceive(z, player)
		_decide(z, player, d)
	if not _started:   # התחיל לרדוף (שמע / ראה): יודע בערך איפה השחקן
		_started = true
		last_seen = player.global_position
		seen_t = 0.0
	if not steer_movement:
		return base_speed
	# איבד את השחקן (לא רואה + הזיכרון נגמר): מחפש באזור שבו ראה אותו אחרון - לא "יודע" איפה אתה
	if not sees and seen_t > float(p.memory_duration) and heard_t < 0.0 and float(p.coordination_level) > 0.0:
		var ldx: float = last_seen.x - z.global_position.x
		if absf(ldx) > 24.0:
			z._dir = signf(ldx)
			return base_speed * 0.6
		if randf() < 0.01:
			z._dir = -z._dir
		return base_speed * 0.3
	var tx: float = player.global_position.x if sees else last_seen.x
	var dx: float = tx - z.global_position.x
	var dist := absf(d.x)
	var face: float = signf(dx) if dx != 0.0 else z._dir
	var speed := base_speed
	var ag := clampf(float(p.aggression) + leader_boost * 0.5, 0.0, 1.2)

	# ---- התחמקות מרימון / בקבוק שנחת קרוב ----
	if float(p.awareness) > 0.55 and _dodge_t <= 0.0 and Engine.get_physics_frames() % 6 == 0:
		for g in z.get_tree().get_nodes_in_group("grenades"):
			var gd: Vector2 = g.global_position - z.global_position
			if absf(gd.x) < 120.0 and absf(gd.y) < 90.0 and randf() < float(p.awareness):
				_dodge_t = 0.7
				_dodge_dir = -signf(gd.x) if gd.x != 0.0 else -face
				Game.story.emit("dodge", {"z": z})
				break
	if _dodge_t > 0.0:
		z._dir = _dodge_dir
		return base_speed * 1.35

	match role:
		APPROACH, ATTACK:
			z._dir = face
			speed *= 0.8 + 0.4 * ag
			if _burst_t > 0.0:
				speed *= 1.4
			speed = _adapt_attack(z, player, dist, speed)
			speed = _charge(z, dist, speed, delta)
		FLANK:
			speed = _flank(z, player, delta, base_speed)
		HOLD:
			var hd := hold_dist + 140.0 * PlayerMemory.likes_close_range() * adapt_k()
			z._dir = face
			if dist > hd + 50.0:
				speed *= 0.6
			elif dist < hd - 60.0 and not player.is_vulnerable():   # השחקן מתקרב: נסוג לאט (מחכה לתור)
				z._dir = -face
				speed *= 0.45
			else:
				speed = 0.0
				z._dir = face
		RETREAT:
			z._dir = -face
			speed *= 1.05
		AMBUSH:
			speed = 0.0
			z._duck_t = maxf(z._duck_t, 0.3)   # כורע בחושך
			if _ambush_side == 0.0:
				_ambush_side = signf(player.global_position.x - z.global_position.x)
			var side := signf(player.global_position.x - z.global_position.x)
			# השחקן עבר אותו (או נהיה ממש קרוב) - קופץ עליו מאחור
			if dist < 70.0 or (side != _ambush_side and dist < 260.0):
				_set_role(z, ATTACK, 0.0)
				_burst_t = 1.6
				z._duck_t = 0.0
				Game.story.emit("ambush", {"z": z})
				z._voice("zscream", 1.0, 4.0)
		WAIT:
			speed = 0.0
			z._dir = face
		COVER:
			if z._cover_state == 0:
				z._try_cover(player)
			_set_role(z, HOLD, 1.0)
		CONFUSED:
			if int(_t * 1.3) % 2 == 0:
				z._dir = -z._dir if randf() < 0.02 else z._dir
			speed *= 0.35

	# ---- לא נכנסים למלכודות (אש / חומצה / חביות) ----
	if float(p.hazard_awareness) > 0.25 and role != RETREAT and speed > 0.0:
		var ahead: Vector2 = z.global_position + Vector2(z._dir * 34.0, -12.0)
		for h in z.get_tree().get_nodes_in_group("hazards"):
			if h.danger_at(ahead, 6.0) and randf() < float(p.hazard_awareness) + 0.3:
				speed = 0.0
				if z.is_on_floor() and _hop_cd <= 0.0 and float(p.hazard_awareness) > 0.6 and h.world_rect().size.x < 140.0:
					z.velocity.y = z.jump_velocity * 1.05   # קופץ מעל אש קטנה
					z.velocity.x = z._dir * 260.0
					_hop_cd = 1.2
				break

	# ---- גבהים: מטפסים לקומה של השחקן / קופצים למטה ----
	_heights(z, player, d)

	# ---- התפזרות: השחקן אוהב רימונים -> לא מתקבצים ----
	var spread_k := PlayerMemory.explosives * adapt_k()
	if spread_k > 0.3 and speed > 0.0 and Engine.get_physics_frames() % 4 == 0:
		for o in z.get_tree().get_nodes_in_group("zombies"):
			if o != z and not o.dead and absf(o.global_position.x - z.global_position.x) < 34.0 and signf(o.global_position.x - z.global_position.x) == z._dir and absf(o.global_position.y - z.global_position.y) < 30.0:
				speed *= 0.4
				break
	return speed


# שוטגאן / צלף / SMG: כל זומבי מגיב בהדרגה לסגנון של השחקן
func _adapt_attack(z: Node, player: Node, dist: float, speed: float) -> float:
	var a := adapt_k()
	if a <= 0.01:
		return speed
	# אוהב לרסס: מסתערים מהר (פחות זמן לירות)
	speed *= 1.0 + 0.3 * PlayerMemory.likes_spray() * a
	# צלף: זיגזג + קפיצות קטנות
	var lr := PlayerMemory.likes_long_range() * a
	if lr > 0.25 and dist > 160.0:
		speed *= 0.65 + 0.7 * absf(sin(_t * 3.3 + float(z.get_instance_id() % 7)))
		if z.is_on_floor() and _hop_cd <= 0.0 and randf() < 0.02 * lr:
			z.velocity.y = z.jump_velocity * 0.6
			_hop_cd = 1.4
	# שוטגאן: לא נכנסים לטווח קצר מלפנים, אלא אם השחקן טוען / פגיע / הם מאחוריו
	var cr := PlayerMemory.likes_close_range() * a
	if cr > 0.35 and dist < 170.0 and dist > 60.0 and not player.is_vulnerable():
		var in_front: bool = signf(z.global_position.x - player.global_position.x) == player._face()
		if in_front and randf() < cr:
			Game.story.emit("adapt", {"z": z, "why": "shotgun"})
			return 0.0
	return speed


# ענק: מתכונן ומסתער
func _charge(z: Node, dist: float, speed: float, delta: float) -> float:
	if not p.get("charge", false):
		return speed
	match _charge_state:
		0:
			if dist < 200.0 and dist > 60.0 and _charge_cd <= 0.0 and z.is_on_floor():
				_charge_state = 1
				_charge_t = 0.5
				Game.story.emit("charge", {"z": z})
				z._voice("roar", 1.0, 2.0)
		1:   # מתכונן (חלון לירות בו)
			_charge_t -= delta
			if _charge_t <= 0.0:
				_charge_state = 2
				_charge_t = 0.7
			return 0.0
		2:
			_charge_t -= delta
			if _charge_t <= 0.0:
				_charge_state = 0
				_charge_cd = 3.5
			return speed * 2.7
	return speed


func is_charging() -> bool:
	return _charge_state == 2


func _flank(z: Node, player: Node, _delta: float, base: float) -> float:
	var px: float = player.global_position.x
	var behind := signf(z.global_position.x - px) == flank_side   # כבר בצד הנכון
	if behind:
		_set_role(z, ATTACK, 0.0)
		_burst_t = 0.8
		return base
	var dx: float = px - z.global_position.x
	z._dir = signf(dx) if dx != 0.0 else z._dir
	# קרוב: קפיצה גבוהה מעל השחקן אל הצד השני
	if absf(dx) < 130.0 and z.is_on_floor() and _hop_cd <= 0.0:
		z.velocity.y = -720.0
		z.velocity.x = z._dir * 430.0
		_hop_cd = 1.5
		_flank_leap = true
		Game.story.emit("flank_jump", {"z": z})
	return base * 1.15


func _heights(z: Node, player: Node, d: Vector2) -> void:
	var uh := clampf(float(p.use_heights) + 0.3 * PlayerMemory.high_ground * adapt_k(), 0.0, 1.0)
	if uh <= 0.05 or not z.is_on_floor() or _hop_cd > 0.0:
		return
	if d.y < -70.0 and absf(d.x) < 300.0:   # השחקן למעלה
		_hop_cd = randf_range(0.8, 1.6)
		if randf() < uh:
			var top := _platform_above(z, -d.y + 40.0)
			if top < INF:
				z.hop_up(z.global_position.y - top + 26.0)
	elif d.y > 70.0 and absf(d.x) < 360.0:   # השחקן למטה
		_hop_cd = randf_range(0.6, 1.2)
		if randf() < uh:
			z.drop_through()


# הקומה (one-way) הכי קרובה מעל הזומבי, בטווח max_h. מחזיר y או INF
func _platform_above(z: Node, max_h: float) -> float:
	var best := INF
	var zp: Vector2 = z.global_position
	for pl in z.get_tree().get_nodes_in_group("platforms"):
		var r: Rect2 = pl.world_rect()
		if zp.x > r.position.x + 6.0 and zp.x < r.end.x - 6.0 and r.position.y < zp.y - 20.0 and zp.y - r.position.y <= max_h:
			if best == INF or r.position.y > best:
				best = r.position.y
	return best


func _perceive(z: Node, player: Node) -> void:
	if player == null or player.dead:
		sees = false
		return
	var from: Vector2 = z.global_position + Vector2(0.0, -40.0 * z.sc)
	var to: Vector2 = player.global_position + Vector2(0.0, -30.0)
	var range_k := 0.6 + 0.6 * float(p.awareness)
	if from.distance_to(to) > z.chase_range * range_k * (0.5 if Game.player_dark else 1.0) and not z._alert_t > 0.0:
		sees = false
		return
	var q := PhysicsRayQueryParameters2D.create(from, to, 1)
	var hit: Dictionary = z.get_world_2d().direct_space_state.intersect_ray(q)
	sees = hit.is_empty()
	if sees:
		seen_t = 0.0
		last_seen = player.global_position


func _decide(z: Node, player: Node, d: Vector2) -> void:
	var dr := director()
	if dr != null:
		leader_boost = dr.leader_boost_at(z.global_position)
		if dr.has_method("is_silenced") and dr.is_silenced(z.global_position):   # SILENCE: בלי תיאום - תוקף בצורה בסיסית
			leader_boost = 0.0
			forced_t = 0.0
			role = ATTACK
			return
	if forced_t > 0.0:
		role = forced_role
		if role == ATTACK and dr != null:
			dr.request_slot(z, true, true)
		return
	forced_role = -1
	if confused_t > 0.0:
		role = CONFUSED
		return
	if role == AMBUSH:
		return
	if (role == RETREAT or role == FLANK) and role_t > 0.0:
		return
	var dist := absf(d.x)
	# פצוע: נסוג להתאושש (ואז חוזר)
	if z.hp < z.max_hp * 0.35 and randf() < float(p.retreat_probability) * 0.5 and role != RETREAT and not player.is_vulnerable():
		_set_role(z, RETREAT, randf_range(1.2, 2.2))
		return
	if dr == null or not dr.uses_slots():
		role = ATTACK
		return
	if dist > 360.0:
		_set_role(z, APPROACH)
		return
	if dr.request_slot(z, player.is_vulnerable()):
		if role != ATTACK and z.is_on_floor() and float(p.coordination_level) > 0.45:
			_burst_t = 0.5
		role = ATTACK
		return
	# אין תור: מאגפים / מחסה / מחכים
	var r := randf()
	var fl := float(p.flank_probability) * (0.5 + 0.5 * coord())
	if role != FLANK and r < fl:
		flank_side = dr.pick_flank_side(z, player)
		if signf(z.global_position.x - player.global_position.x) == flank_side:
			_set_role(z, HOLD)   # כבר בצד הזה
		else:
			_set_role(z, FLANK, randf_range(3.0, 5.0))
	elif r < fl + float(p.cover_usage) * 0.3 and z._cover_state == 0:
		_set_role(z, COVER)
	elif role != FLANK:
		_set_role(z, HOLD)
