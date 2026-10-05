extends Node
# ============================================================
#  SQUAD DIRECTOR - "המפקד הנסתר" של כל הזומבים בשלב (נוצר ע"י main.gd).
#
#  מה הוא עושה:
#   * תורות התקפה (attack slots): רק 2-3 זומבים תוקפים בבת אחת. השאר מאגפים,
#     מחכים, מתחבאים או מתכוננים (ai/zombie_brain.gd מחליט מה בדיוק).
#     כשהשחקן ברגע פגיע (טוען / נתפס / נפגע) - תור אחד נוסף.
#   * תקשורת: זומבי שרואה אותך "קורא" לחברים קרובים (משלב 5) - מופיעה טבעת + צליל.
#   * היררכיה: מנהיגים (PACK LEADER / COMMANDER) מחזקים את מי שלידם.
#     מנהיג מת -> הזומבים מסביב מבולבלים לכמה שניות.
#   * פקודות: ATTACK / RETREAT / FLANK / HOLD / AMBUSH לכל מי שבטווח.
#   * התקפה משולבת: כשכמה זומבים מחכים יחד ליד השחקן, לפעמים כולם קופצים
#     פנימה ביחד מכמה כיוונים (group_attack בפרופיל).
#
#  איפה משנים: ai/intelligence_profile.gd (attack_slots, coordination_level, group_attack...)
# ============================================================

const Profile := preload("res://ai/intelligence_profile.gd")
const Brain := preload("res://ai/zombie_brain.gd")
const SignalFx := preload("res://effects/signal_fx.gd")
const Sfx := preload("res://sfx.gd")

var profile := {}
var max_slots := 99
var _slots := {}          # instance_id -> [zombie, תוקף עד זמן]
var _leaders := []        # [zombie, רדיוס, בונוס]
var _t := 0.0
var _tick := 0.0
var _wave_cd := 6.0
var _wave_t := 0.0
var _flank_cd := 0.0
var commands_issued := 0  # לבדיקות
var _sil_node: Node2D = null   # SILENCE: מרכז השדה (השחקן)
var _sil_r := 0.0
var _sil_t := 0.0
var calls_made := 0


func setup(level: int, smart: float) -> void:
	profile = Profile.for_level(level, smart)
	max_slots = int(profile.attack_slots)
	if max_slots < 99:
		max_slots = mini(max_slots, Profile.MAX_SLOTS + (1 if smart < 0.8 else 0))


func _ready() -> void:
	add_to_group("squad_director")


# יכולת SILENCE: שדה שקט סביב node (זז איתו)
func silence(node: Node2D, radius: float, seconds: float) -> void:
	_sil_node = node
	_sil_r = radius
	_sil_t = seconds


func is_silenced(pos: Vector2) -> bool:
	return _sil_t > 0.0 and _sil_node != null and is_instance_valid(_sil_node) and pos.distance_to(_sil_node.global_position) < _sil_r


func uses_slots() -> bool:
	return max_slots < 99


func coordination() -> float:
	return float(profile.get("coordination_level", 0.0))


func attackers() -> int:
	_clean()
	return _slots.size()


# ---- תורות התקפה ----
func request_slot(z: Node, vulnerable := false, forced := false) -> bool:
	_clean()
	var id := z.get_instance_id()
	if _slots.has(id):
		_slots[id][1] = _t + 6.0
		return true
	var cap := max_slots
	if vulnerable and coordination() >= 0.4:
		cap += 1   # השחקן טוען / נתפס: עוד אחד מצטרף
	if _wave_t > 0.0:
		cap += 2   # גל התקפה משולב
	if forced:
		cap += 1
	# זומבי מאחורי השחקן מקבל עדיפות אם כל התוקפים מלפנים (התקפה מכמה כיוונים)
	if _slots.size() >= cap and coordination() >= 0.6 and _behind_player(z) and not _any_attacker_behind():
		cap += 1
	if _slots.size() < cap:
		_slots[id] = [z, _t + 6.0]
		return true
	return false


# אחרי גל התקפה / רגע פגיע: חוזרים למספר התוקפים הרגיל (הרחוקים מוותרים על התור)
func _trim() -> void:
	if _wave_t > 0.0 or not uses_slots():
		return
	var p := _player()
	if p == null:
		return
	var cap := max_slots + (1 if p.is_vulnerable() and coordination() >= 0.4 else 0)
	if _slots.size() <= cap:
		return
	var list := _slots.values()
	list.sort_custom(func(a, b): return absf(a[0].global_position.x - p.global_position.x) < absf(b[0].global_position.x - p.global_position.x))
	for i in range(cap, list.size()):
		var z = list[i][0]
		_slots.erase(z.get_instance_id())
		if z.brain != null and z.brain.forced_t <= 0.0:
			z.brain.role = Brain.HOLD


func release_slot(z: Node) -> void:
	_slots.erase(z.get_instance_id())


func _clean() -> void:
	for id in _slots.keys():
		var e: Array = _slots[id]
		var z = e[0]
		if not is_instance_valid(z) or z.dead or float(e[1]) < _t or (z.brain != null and z.brain.role != Brain.ATTACK and z.brain.role != Brain.APPROACH):
			_slots.erase(id)


func _player() -> Node:
	return get_tree().get_first_node_in_group("player")


func _behind_player(z: Node) -> bool:
	var p := _player()
	if p == null:
		return false
	return signf(z.global_position.x - p.global_position.x) == -p._face()


func _any_attacker_behind() -> bool:
	for id in _slots:
		var z = _slots[id][0]
		if is_instance_valid(z) and _behind_player(z):
			return true
	return false


# לאיזה צד לאגף: הצד עם פחות זומבים, ובשלבים מתקדמים - הצד ש"נלמד" (PlayerMemory)
func pick_flank_side(_z: Node, player: Node) -> float:
	var left := 0
	var right := 0
	for o in get_tree().get_nodes_in_group("zombies"):
		if o.dead:
			continue
		var dx: float = o.global_position.x - player.global_position.x
		if absf(dx) < 500.0:
			if dx < 0.0:
				left += 1
			else:
				right += 1
	var side := -1.0 if left < right else 1.0
	if float(profile.get("adaptation_level", 0.0)) > 0.2 and randf() < float(profile.adaptation_level):
		side = PlayerMemory.flank_side()
	return side


# ---- תקשורת ----
func broadcast(from_z: Node, pos: Vector2) -> void:
	if int(profile.get("communication", 0)) <= 0 or is_silenced(from_z.global_position):
		return
	var radius := 260.0 + 280.0 * coordination()
	var n := 0
	for o in get_tree().get_nodes_in_group("zombies"):
		if o == from_z or o.dead or o.brain == null or is_silenced(o.global_position):
			continue
		var dd: float = o.global_position.distance_to(from_z.global_position)
		if dd < radius:
			o.brain.hear_call(pos, 0.35 + dd / 700.0)   # הקול לוקח זמן להגיע
			n += 1
	if n > 0:
		calls_made += 1
		Game.story.emit("call", {"z": from_z, "n": n})
		_signal(from_z.global_position + Vector2(0, -70.0 * from_z.sc), "!", Color(1.0, 0.45, 0.3))
		Sfx.play("zcall", from_z.global_position, -2.0, 0.15, 2)


func _signal(at: Vector2, text: String, col: Color) -> void:
	var fx = SignalFx.new()
	fx.text = text
	fx.color = col
	get_parent().add_child(fx)
	fx.global_position = at


# ---- היררכיה ----
func register_leader(z: Node, radius: float, bonus: float) -> void:
	_leaders.append([z, radius, bonus])


func leader_boost_at(pos: Vector2) -> float:
	var b := 0.0
	for l in _leaders:
		var z = l[0]
		if is_instance_valid(z) and not z.dead and z.global_position.distance_to(pos) < float(l[1]):
			b = maxf(b, float(l[2]))
	return b


func on_death(z: Node) -> void:
	release_slot(z)
	for l in _leaders:
		if l[0] == z:   # המנהיג מת: בלבול
			disorganize(z.global_position, float(l[1]) * 1.1, 4.0)
			_signal(z.global_position + Vector2(0, -80.0 * z.sc), "?", Color(0.7, 0.8, 1.0))
	_leaders = _leaders.filter(func(l): return is_instance_valid(l[0]) and l[0] != z and not l[0].dead)


func disorganize(pos: Vector2, radius: float, seconds: float) -> void:
	for o in get_tree().get_nodes_in_group("zombies"):
		if not o.dead and o.brain != null and o.global_position.distance_to(pos) < radius:
			o.brain.confuse(seconds * randf_range(0.8, 1.2))
			release_slot(o)


# ---- פקודות (COMMANDER / PACK LEADER) ----
func command(from_z: Node, cmd: String, radius: float, seconds: float) -> int:
	var map := {"ATTACK": Brain.ATTACK, "RETREAT": Brain.RETREAT, "FLANK": Brain.FLANK, "HOLD": Brain.HOLD, "AMBUSH": Brain.AMBUSH}
	if not map.has(cmd) or is_silenced(from_z.global_position):
		return 0
	var n := 0
	var p := _player()
	for o in get_tree().get_nodes_in_group("zombies"):
		if o == from_z or o.dead or o.brain == null or not o.brain.steer_movement or is_silenced(o.global_position):
			continue
		if o.global_position.distance_to(from_z.global_position) < radius:
			if cmd == "FLANK" and p != null:
				o.brain.flank_side = pick_flank_side(o, p)
			o.brain.command(map[cmd], seconds)
			n += 1
	if cmd == "ATTACK":
		_wave_t = minf(seconds, 3.0)
	commands_issued += 1
	Game.story.emit("squad", {"z": from_z, "cmd": cmd, "n": n})
	_signal(from_z.global_position + Vector2(0, -86.0 * from_z.sc), cmd, Color(1.0, 0.8, 0.3))
	Sfx.play("zcommand", from_z.global_position, 0.0, 0.1, 2)
	return n


# TACTICIAN: השחקן יורה שוב ושוב מאותו מקום -> שולחים 2 זומבים מסביב
func order_flank(from_z: Node, player: Node) -> int:
	if _flank_cd > 0.0:
		return 0
	_flank_cd = 7.0
	var side: float = -player._face()   # מאחוריו
	var n := 0
	for o in get_tree().get_nodes_in_group("zombies"):
		if n >= 2:
			break
		if o == from_z or o.dead or o.brain == null or not o.brain.steer_movement or o.brain.role == Brain.ATTACK:
			continue
		if absf(o.global_position.x - player.global_position.x) < 600.0:
			o.brain.flank_side = side
			o.brain.command(Brain.FLANK, 4.5)
			n += 1
	if n > 0:
		_signal(from_z.global_position + Vector2(0, -86.0 * from_z.sc), "FLANK", Color(0.6, 0.9, 1.0))
		commands_issued += 1
		Game.story.emit("squad", {"z": from_z, "cmd": "FLANK", "n": n})
	return n


func _process(delta: float) -> void:
	_t += delta
	_sil_t -= delta
	_wave_t -= delta
	_wave_cd -= delta
	_flank_cd -= delta
	_tick -= delta
	if _tick > 0.0:
		return
	_tick = 0.3
	_clean()
	_trim()
	# התקפה משולבת: כמה זומבים מחכים יחד -> כולם פנימה מכמה כיוונים
	var ga := float(profile.get("group_attack", 0.0))
	if ga <= 0.0 or _wave_cd > 0.0:
		return
	var p := _player()
	if p == null or p.dead:
		return
	var waiting := []
	var sides := {}
	for o in get_tree().get_nodes_in_group("zombies"):
		if o.dead or o.brain == null or not o.brain.steer_movement:
			continue
		if o.brain.role == Brain.HOLD and absf(o.global_position.x - p.global_position.x) < 420.0 and not is_silenced(o.global_position):
			waiting.append(o)
			sides[signf(o.global_position.x - p.global_position.x)] = true
	if waiting.size() >= 3 and randf() < ga * 0.35:
		_wave_cd = 9.0
		_wave_t = 2.5
		for o in waiting:
			o.brain.command(Brain.ATTACK, 2.5)
		_signal(p.global_position + Vector2(0, -120), "!!" if sides.size() > 1 else "!", Color(1.0, 0.3, 0.25))
		Sfx.play("zcall", p.global_position, 2.0, 0.1, 2)
