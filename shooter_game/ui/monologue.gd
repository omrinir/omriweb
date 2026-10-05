extends Node
# ============================================================
#  MONOLOGUE - השחקן מדבר לעצמו: בועת קומיקס מעל הראש + קול (גבר צרוד, קצת לוחש).
#  בכל השלבים (main.gd מוסיף אותו). מדבר מעט: בכל שלב מוגרל MAX 1-4 משפטים (LINES_PER_LEVEL),
#  עם לפחות MIN_BETWEEN שניות ביניהם - ורק כשקורה משהו שמצדיק את זה.
#
#  איך זה עובד: Game.story (signal ב-game_state.gd) נשלח מכל מקום במשחק כשקורה משהו
#  (zombie.gd, player.gd, survivor.gd, ai/*, zombie types, hazards, השלבים). _on_story מחליט אם להגיב,
#  _poll בודק מצבים כל 0.3 שנ' (נכנסים לחושך, הרבה זומבים מתקרבים, רואים סוג זומבי בפעם הראשונה).
#  כל אירוע = כמה משפטים אפשריים (EVENTS); נבחר אחד אקראי שעוד לא נשמע בריצה הזו (heard).
#  עדיפות: 1 = קרב (קורה רק לפעמים), 2 = רגיל, 3 = חשוב (הפתעה / הם חכמים),
#    4 = חייב להגיב (ירית בניצולה) - עוקף את ההמתנה בין משפטים, אבל אף פעם לא יותר מ-4 בשלב.
#  המשפט האחרון בשלב שמור לאירוע חשוב (עדיפות 2+).
#  קול: sounds/voice/vNN.mp3 (v100.mp3). Kokoro TTS (am_onyx) + לחישה קלה (LPC על רעש, 30%) + ffmpeg.
#  להוסיף משפט: שורה ב-LINES + קובץ קול + להוסיף את המספר לאירוע ב-EVENTS (או קריאה ל-_event).
# ============================================================

const Art := preload("res://art.gd")
const Registry := preload("res://enemies/zombie_registry.gd")
const Z := preload("res://zombie.gd")
const FONT_PATH := "res://fonts/Bangers-Regular.ttf"
const VOICE_DIR := "res://sounds/voice/"

const LINES := {
	1: ["Die! Die! DIE!", "combat"],
	2: ["Why won't you fucking die?!", "combat"],
	3: ["Stay down!", "combat"],
	4: ["You're not getting back up.", "combat"],
	5: ["Come on! Come on!", "combat"],
	6: ["That's the last one.", "combat"],
	7: ["Got you!", "combat"],
	8: ["Eat this!", "combat"],
	9: ["Back off!", "combat"],
	10: ["I've had enough of you!", "combat"],
	11: ["Shit! You scared me!", "scary"],
	12: ["Jesus Christ...", "scary"],
	13: ["What the hell was that?", "scary"],
	14: ["I really don't like this place.", "scary"],
	15: ["It's really fucking dark in here.", "scary"],
	16: ["I heard something...", "scary"],
	17: ["Please don't let there be more of them.", "scary"],
	18: ["They're getting closer...", "scary"],
	19: ["Wait... they're learning.", "smart"],
	20: ["That didn't work twice.", "smart"],
	21: ["They know where I am.", "smart"],
	22: ["How the hell did it know I'd go this way?", "smart"],
	23: ["They're working together...", "smart"],
	24: ["Okay... they're getting smarter.", "smart"],
	25: ["Oh shit. They figured me out.", "smart"],
	26: ["Ow, shit! Sorry, sorry!", "wtf"],
	27: ["Shit! I didn't mean that!", "wtf"],
	28: ["Hang on. I'm coming for you.", "wtf"],
	29: ["I'm sorry. I need this more than you.", "wtf"],
	30: ["Go. Get out of here.", "wtf"],
	31: ["No... no, no, no.", "scary"],
	32: ["That's not her. That's NOT her!", "wtf"],
	33: ["Since when do they wear faces?", "wtf"],
	34: ["I'm not dying in this shithole.", "scary"],
	35: ["Hold it together. Hold it together.", "scary"],
	36: ["Better. Much better.", "wtf"],
	37: ["Get your hands off me!", "wtf"],
	38: ["Something grabbed my leg!", "wtf"],
	39: ["Oh god, that's disgusting!", "wtf"],
	40: ["It's in my mouth. It's in my MOUTH!", "wtf"],
	41: ["Hot, hot, hot!", "wtf"],
	42: ["Great. Quicksand. Of course.", "wtf"],
	43: ["Empty. Of course it's empty.", "wtf"],
	44: ["Come on, I need bullets!", "wtf"],
	45: ["Now we're talking.", "combat"],
	46: ["Hello, beautiful.", "combat"],
	47: ["Thank god. Bullets.", "combat"],
	48: ["Boom. Who's next?", "combat"],
	49: ["Never stand next to a barrel.", "combat"],
	50: ["Right between the eyes.", "combat"],
	51: ["One shot. One less.", "combat"],
	52: ["Two for one.", "combat"],
	53: ["Watch your head.", "combat"],
	54: ["Hop along, buddy.", "combat"],
	55: ["I'm on fire tonight.", "combat"],
	56: ["Too slow.", "combat"],
	57: ["Hell yes. I can fly.", "combat"],
	58: ["Yeah... don't do that twice.", "combat"],
	59: ["That's a big one.", "scary"],
	60: ["Oh, you've got to be kidding me.", "scary"],
	61: ["And stay dead.", "combat"],
	62: ["Biggest one yet. Still dead.", "combat"],
	63: ["There's my way out.", "combat"],
	64: ["Just thunder. Just thunder.", "scary"],
	65: ["Can't see a damn thing in this sand.", "scary"],
	66: ["Smart. Real smart. Now it's dark.", "scary"],
	67: ["Dark. Why is it always dark?", "scary"],
	68: ["Should've stayed home tonight.", "scary"],
	69: ["Too quiet. I hate it when it's quiet.", "scary"],
	70: ["Keep moving. Just keep moving.", "scary"],
	71: ["They're coming out of the ground?!", "scary"],
	72: ["Did he just... eat his friend?", "scary"],
	73: ["His head just opened up!", "scary"],
	74: ["Since when do they fly?!", "wtf"],
	75: ["He's falling apart. Literally.", "wtf"],
	76: ["Even in pieces, he keeps coming.", "wtf"],
	77: ["Bullets don't do shit to that shield.", "wtf"],
	78: ["Tentacles. Why are there tentacles?", "scary"],
	79: ["Where the hell did that one come from?", "scary"],
	80: ["Electric zombies. Great. Just great.", "wtf"],
	81: ["Sand in my eyes! Sand everywhere!", "wtf"],
	82: ["Somebody shut that one up!", "wtf"],
	83: ["Is that one... giving orders?", "smart"],
	84: ["It dodged. It actually dodged.", "smart"],
	85: ["Big guy's charging. Move!", "wtf"],
	86: ["A zombie with a jetpack. Sure. Why not.", "wtf"],
	87: ["Rats. I hate rats.", "wtf"],
	88: ["Even the dogs...", "wtf"],
	89: ["Acid. That's new.", "wtf"],
	90: ["Officer, I don't think you're on duty anymore.", "wtf"],
	91: ["Don't pop. Don't pop. Don't pop.", "wtf"],
	92: ["From the ceiling?!", "scary"],
	93: ["I knew it. I knew it was a trap.", "smart"],
	94: ["Keep it together. You've got this.", "scary"],
	95: ["One more step. One more.", "scary"],
	96: ["Clean shot.", "combat"],
	97: ["Not today.", "combat"],
	98: ["Did that thing just shoot back?", "smart"],
	99: ["Who builds a robot for a zombie?", "wtf"],
	100: ["That's one way to cross a street.", "wtf"],
}

# אירוע -> [משפטים אפשריים, עדיפות]
const EVENTS := {
	"survivor_shot": [[26, 27], 4], "survivor_blown": [[31, 27], 4], "survivor_seen": [[28], 2],
	"drain": [[29, 36], 3], "spared": [[30], 2], "mimic": [[32, 33], 3],
	"low_hp": [[34, 35, 94, 95], 2], "grabbed": [[37], 3], "hand_grab": [[38], 3],
	"puked": [[39, 40], 3], "fire": [[41], 2], "acid": [[89], 2], "shock": [[80], 2], "quicksand": [[42], 3],
	"no_ammo": [[43, 44], 2], "new_weapon": [[45, 46], 2], "ammo_saved": [[47], 2], "combo": [[55], 2],
	"perfect_dodge": [[56], 2], "jetpack": [[57], 2], "stomp_hurt": [[58], 3], "last_breath": [[97], 3],
	"boss": [[59, 60, 12], 3], "boss_dead": [[61, 62], 3], "gate_open": [[63], 2],
	"thunder": [[13, 64], 2], "sandstorm": [[65], 2], "lamp_shot": [[66], 2], "dark": [[15, 67, 14], 3],
	"after_fight": [[69, 70, 68, 17], 2],
	"graveborn": [[71], 3], "devour": [[72], 3], "splitjaw": [[73], 3], "flyer": [[74], 3],
	"crumble": [[75], 2], "crumble_crawl": [[76], 2], "shield": [[77], 2], "kraken": [[78], 3], "portal": [[79], 3],
	"sandblast": [[81], 2], "call": [[82, 23], 3], "squad": [[83, 23], 3], "dodge_bullet": [[84], 3],
	"charge": [[85], 2], "ceiling_drop": [[92], 3], "ambush": [[22, 93], 3], "bloater": [[91], 3],
	"leg": [[54], 1], "headshots": [[50, 96], 1], "long_head": [[51], 2], "double": [[52], 1], "blast": [[48], 2],
	"barrel": [[49], 2], "car": [[100], 2], "stomp_kill": [[53], 1],
	"grenade_dodged": [[19, 20], 3], "adapt": [[19, 24], 3], "cover": [[24], 2], "flank_jump": [[25], 3],
	"know": [[21], 3], "heard": [[16], 2], "scared": [[11], 3], "closer": [[18], 2],
	"die_die": [[1], 1], "wont_die": [[2], 2], "stay_down": [[3], 1], "not_up": [[4], 1], "come_on": [[5], 1],
	"last_one": [[6], 2], "got_you": [[7], 1], "eat_this": [[8], 1], "back_off": [[9], 1], "had_enough": [[10], 2],
}
# סוג זומבי שרואים בפעם הראשונה (בריצה) -> אירוע
const SIGHTS := {Z.JETPACK: [86], Z.RAT: [87], Z.DOG: [88], Z.HOUND: [88], Z.COP: [90], Z.GUNNER: [98], Z.MECH: [99], Registry.IRONWING: [74]}
const COLORS := {"combat": Color("ffd23a"), "scary": Color("9fe8ff"), "smart": Color("d8a8ff"), "wtf": Color("ff8a5a")}
const VOICE_DB := 1.0
const LINES_PER_LEVEL := Vector2i(1, 4)   # כמה משפטים מקסימום בשלב (מוגרל בכל שלב)
const MIN_BETWEEN := 40.0                  # שניות לפחות בין משפטים
const FIRST_AFTER := 10.0                  # בהתחלה: רק אירועים חשובים
const COMBAT_CHANCE := 0.35                # משפטי קרב (עדיפות 1) - רק לפעמים
const SIGHT_RANGE := 750.0

static var _font: Font = null
static var heard := {}      # משפטים שכבר נאמרו בריצה הזו (עדיפות למשפטים חדשים)
static var seen_kinds := {} # סוגי זומבים שכבר ראה

var player: Node2D = null
var max_lines := 2
var said := {}              # id -> כמה פעמים (לבדיקות)
var log_lines := []         # [זמן, id] (לבדיקות)
var _t := 0.0
var _cur := 0
var _show := 0.0
var _dur := 0.0
var _voice: AudioStreamPlayer
var _layer: CanvasLayer
var _ui: Node2D
var _poll_t := 0.0
var _hits := {}
var _total := {}
var _flags := {}
var _attackers := {}
var _kills := []            # זמני הריגות
var _blast_kills := []
var _head_streak := 0
var _shield_t := []
var _was_dark := false
var _was_inside := false
var _dark_said := false
var _fight_t := -99.0       # מתי היה הקרב האחרון (הריגות)
var _calm_said := false
var _seen_big := {}


func _ready() -> void:
	add_to_group("monologue")
	max_lines = randi_range(LINES_PER_LEVEL.x, LINES_PER_LEVEL.y)
	_layer = CanvasLayer.new()
	_layer.layer = 4
	add_child(_layer)
	_ui = Node2D.new()
	_layer.add_child(_ui)
	_ui.draw.connect(_draw_bubble)
	_voice = AudioStreamPlayer.new()
	_voice.bus = "SFX" if AudioServer.get_bus_index("SFX") >= 0 else "Master"
	_voice.volume_db = VOICE_DB
	add_child(_voice)
	Game.story.connect(_on_story)


static func font() -> Font:
	if _font != null:
		return _font
	if ResourceLoader.exists(FONT_PATH):
		_font = load(FONT_PATH) as Font
	if _font == null and FileAccess.file_exists(FONT_PATH):   # עוד לא יובא ע"י העורך
		var ff := FontFile.new()
		if ff.load_dynamic_font(FONT_PATH) == OK:
			_font = ff
	if _font == null:
		_font = ThemeDB.fallback_font
	return _font


func _voice_stream(id: int) -> AudioStream:
	var path := VOICE_DIR + "v%02d.mp3" % id
	if ResourceLoader.exists(path):
		var s := load(path) as AudioStream
		if s != null:
			return s
	if FileAccess.file_exists(path):
		var mp3 := AudioStreamMP3.new()
		mp3.data = FileAccess.get_file_as_bytes(path)
		return mp3
	return null


# ---- האם מותר לדבר עכשיו (בלי לבחור משפט) ----
func can_talk(prio: int) -> bool:
	if player == null or not is_instance_valid(player) or player.dead or _show > 0.0:
		return false
	if prio >= 4:
		return log_lines.size() < LINES_PER_LEVEL.y and (log_lines.is_empty() or _t - float(log_lines[-1][0]) > 6.0)
	if log_lines.size() >= max_lines:
		return false
	if log_lines.size() == max_lines - 1 and prio < 2:   # המשפט האחרון בשלב - רק לרגע ששווה אותו
		return false
	if not log_lines.is_empty() and _t - float(log_lines[-1][0]) < MIN_BETWEEN:
		return false
	if _t < FIRST_AFTER and prio < 3:
		return false
	return true


# אירוע -> אולי משפט. מחזיר true אם דיבר
func _event(ev: String, chance := 1.0) -> bool:
	if not EVENTS.has(ev):
		return false
	var prio: int = EVENTS[ev][1]
	if not can_talk(prio):
		return false
	if prio == 1 and randf() > COMBAT_CHANCE:
		return false
	if chance < 1.0 and randf() > chance:
		return false
	var ids: Array = EVENTS[ev][0]
	if prio < 4 and ids.all(func(i: int) -> bool: return heard.has(i)) and randf() > 0.3:
		return false   # כל המשפטים של האירוע כבר נשמעו בריצה הזו - רק לפעמים חוזר
	_say(_pick(ids))
	return true


func _pick(ids: Array) -> int:
	var fresh := ids.filter(func(i: int) -> bool: return not heard.has(i))
	var pool: Array = fresh if not fresh.is_empty() else ids
	return pool[randi() % pool.size()]


func _say(id: int) -> void:
	_cur = id
	said[id] = int(said.get(id, 0)) + 1
	heard[id] = true
	log_lines.append([snappedf(_t, 0.1), id])
	var st := _voice_stream(id)
	var vlen := 0.0
	if st != null:
		_voice.stream = st
		_voice.play()
		vlen = st.get_length()
	var txt: String = LINES[id][0]
	_dur = maxf(vlen + 0.6, 1.4 + float(txt.length()) * 0.045)
	_show = _dur


func say_now(id: int) -> void:   # לבדיקות
	_say(id)


# ============================================================
#  אירועים
# ============================================================
func _flag(id: int) -> Dictionary:
	if not _flags.has(id):
		_flags[id] = {}
	return _flags[id]


func _on_screen(n: Node2D) -> bool:
	return n != null and is_instance_valid(n) and Art.on_screen(n, n.global_position)


func _dist(n: Node2D) -> float:
	return absf(n.global_position.x - player.global_position.x) if n != null and is_instance_valid(n) else INF


func _on_story(ev: String, info: Dictionary) -> void:
	if player == null or not is_instance_valid(player) or player.dead:
		return
	var z: Node2D = info.get("z") if info.get("z") != null and is_instance_valid(info.get("z")) else null
	var zid: int = z.get_instance_id() if z != null else 0
	match ev:
		"zhit":
			_on_hit(z, zid, info)
		"zkill":
			_on_kill(z, zid, info)
		"wake":
			if z != null and _dist(z) < 230.0:
				_wake_check.call_deferred(zid)
		"notice":
			if z == null:
				return
			if Game.player_dark and _dist(z) < 700.0:
				_event("know")
			elif not _on_screen(z) and _dist(z) < 1300.0:
				_event("heard", 0.3)
			elif _dist(z) < 170.0 and signf(z.global_position.x - player.global_position.x) != player._face():
				_event("scared")
		"phurt":
			var near := _nearest(150.0)
			if near != null:
				_attackers[near.get_instance_id()] = true
			if player.health == 1:
				_event("low_hp")
			elif near != null and _dist(near) < 80.0:
				_event("back_off")
		"reload":
			if _chasing_within(320.0) >= 1:
				_event("come_on")
		"grenade":
			if _nearest(480.0) != null:
				_event("eat_this")
		"dodge":
			_event("grenade_dodged")
		"survivor_dead":
			_event("survivor_blown" if info.get("source", "") != "bullet" else "survivor_shot")
		"survivor_seen":
			_event("survivor_seen", 0.5)
		"grabbed":
			_event("hand_grab" if z != null and z.get("kind") == Z.HAND else "grabbed")
		"hazard":
			var k: String = info.get("kind", "")
			_event("puked" if k == "puke" else k)
		"ammo":
			if info.get("was_empty", false):
				_event("ammo_saved")
		"boss":
			_event("boss")
		"thunder":
			_event("thunder", 0.5)
		"lamp_shot":
			_event("lamp_shot", 0.6)
		"call", "squad":
			if z != null and _dist(z) < 1000.0:
				_event(ev)
		"cover":
			if _on_screen(z):
				_event("cover")
		"graveborn", "ceiling_drop", "bloater":
			if z != null and _dist(z) < 300.0:
				_event(ev)
		"devour", "portal", "charge", "crumble_crawl":
			if _on_screen(z):
				_event(ev)
		"crumble":
			if _on_screen(z) and not _flag(zid).has("crumble"):
				_flag(zid)["crumble"] = true
				_event("crumble", 0.5)
		"shield_block":
			_shield_t.append(_t)
			_shield_t = _shield_t.filter(func(q: float) -> bool: return _t - q < 2.0)
			if _shield_t.size() >= 4:
				_event("shield")
		"dodge_bullet", "ambush", "flank_jump", "adapt":
			if zid != 0:
				_flag(zid)["smart"] = true
			_event(ev)
		"flyer":
			if not seen_kinds.has("flyer_dive"):
				seen_kinds["flyer_dive"] = true
				_event("flyer")
		_:
			if EVENTS.has(ev):   # survivor/hazard/weapon/... שם האירוע = שם ב-EVENTS
				_event(ev)


func _on_hit(z: Node2D, zid: int, info: Dictionary) -> void:
	if z == null:
		return
	var arr: Array = _hits.get(zid, [])
	arr.append(_t)
	arr = arr.filter(func(q: float) -> bool: return _t - q < 2.0)
	_hits[zid] = arr
	_total[zid] = int(_total.get(zid, 0)) + 1
	var f := _flag(zid)
	if info.get("was_lying", false):
		f["lying"] = true
	if z.hp <= 0:
		return
	if info.get("was_lying", false):
		_event("stay_down")
	elif int(_total[zid]) >= 10 and not f.has("why"):
		f["why"] = true
		_event("wont_die")
	elif arr.size() >= 6 and not f.has("die"):
		f["die"] = true
		_event("die_die")


func _on_kill(z: Node2D, zid: int, info: Dictionary) -> void:
	if z == null:
		return
	_fight_t = _t
	_kills.append(_t)
	_kills = _kills.filter(func(q: float) -> bool: return _t - q < 25.0)
	var src: String = info.get("source", "")
	var zone: String = info.get("zone", "")
	_head_streak = _head_streak + 1 if zone == "head" else 0
	var f := _flag(zid)
	var said_one := false
	if z.is_boss():
		said_one = _event("boss_dead")
	elif src == "barrel":
		said_one = _event("barrel")
	elif src == "car":
		said_one = _event("car")
	elif src == "stomp":
		said_one = _event("stomp_kill")
	elif src == "grenade" or src == "launcher":
		_blast_kills.append(_t)
		_blast_kills = _blast_kills.filter(func(q: float) -> bool: return _t - q < 0.4)
		if _blast_kills.size() >= 3:
			said_one = _event("blast")
	if said_one:
		return
	if _kills.size() >= 2 and _t - float(_kills[-2]) < 0.15:
		_event("double")
	elif _attackers.has(zid):
		_event("had_enough")
	elif f.has("lying") or bool(z.get("_one_leg")):
		_event("not_up")
	elif zone == "head" and _dist(z) > 600.0:
		_event("long_head")
	elif _head_streak >= 3:
		_head_streak = 0
		_event("headshots")
	elif f.has("smart") or _dist(z) > 520.0:
		_event("got_you")
	_check_last.call_deferred()


func _wake_check(zid: int) -> void:
	if not _flag(zid).has("lying"):
		_event("scared")


func _check_last() -> void:
	if player == null or not is_instance_valid(player) or _kills.size() < 4:
		return
	for z in get_tree().get_nodes_in_group("zombies"):
		if not z.dead and not z.dormant and _dist(z) < 1100.0:
			return
	_event("last_one")


func _nearest(r: float) -> Node2D:
	var best: Node2D = null
	var bd := r
	for z in get_tree().get_nodes_in_group("zombies"):
		if z.dead:
			continue
		var d: float = z.global_position.distance_to(player.global_position)
		if d < bd:
			bd = d
			best = z
	return best


func _chasing_within(r: float) -> int:
	var n := 0
	for z in get_tree().get_nodes_in_group("zombies"):
		if not z.dead and bool(z.get("_chasing")) and _dist(z) < r:
			n += 1
	return n


# ---- מצבים שנבדקים כל הזמן ----
func _poll() -> void:
	# חושך: נכנסים לאזור חשוך (מפעל) או פעם ראשונה בשלב שהשחקן בחושך
	var inside := false
	for dz in get_tree().get_nodes_in_group("dark_zone"):
		if dz.has_point(player.global_position):
			inside = true
	if (inside and not _was_inside) or (Game.player_dark and not _was_dark and not _dark_said and _t > 5.0):
		_dark_said = true
		_event("dark")
	_was_inside = inside
	_was_dark = Game.player_dark
	if _chasing_within(520.0) >= 5:
		_event("closer")
	# אחרי קרב גדול (5+ הריגות) ושקט של 12 שניות
	if not _calm_said and _kills.size() >= 5 and _t - _fight_t > 12.0 and _nearest(900.0) == null:
		_calm_said = true
		_event("after_fight", 0.6)
	for z in get_tree().get_nodes_in_group("zombies"):
		if z.dead or z.dormant or _dist(z) > SIGHT_RANGE or not _on_screen(z):
			continue
		var k: int = z.kind
		if SIGHTS.has(k) and not seen_kinds.has(k):   # סוג חדש בפעם הראשונה בריצה
			seen_kinds[k] = true
			if can_talk(3):
				_say(_pick(SIGHTS[k]))
		var big: bool = (z.sc >= 1.4 or k == Registry.RETCHER) and not z.is_boss()
		if big and not _seen_big.has(k):
			_seen_big[k] = true
			if can_talk(3):
				_say(_pick([12, 59]))
		var dx: float = z.global_position.x - player.global_position.x
		if absf(dx) < 46.0 and absf(z.global_position.y - player.global_position.y) < 40.0 and not z._lying() and signf(dx) == player._face():
			if randf() < 0.15:
				_event("back_off")


func _process(delta: float) -> void:
	_t += delta
	if player == null or not is_instance_valid(player):
		player = get_tree().get_first_node_in_group("player")
		return
	_show -= delta
	_poll_t -= delta
	if _poll_t <= 0.0 and not player.dead:
		_poll_t = 0.3
		_poll()
	if _show > 0.0 or _cur != 0:
		_ui.queue_redraw()
		if _show <= -0.3:
			_cur = 0


# ============================================================
#  ציור: בועת קומיקס עם פונט BANGERS, קופצת פנימה, האותיות מופיעות מהר
# ============================================================
func _draw_bubble() -> void:
	if _cur == 0 or _show <= -0.3 or player == null or not is_instance_valid(player):
		return
	var f := font()
	var txt: String = LINES[_cur][0]
	var cat: String = LINES[_cur][1]
	var col: Color = COLORS[cat]
	var el := _dur - _show                     # כמה זמן הבועה כבר מוצגת
	var a := clampf(el / 0.12, 0.0, 1.0) * clampf((_show + 0.3) / 0.3, 0.0, 1.0)
	var pop := 1.0 + 0.35 * maxf(0.0, 1.0 - el / 0.18) * sin(clampf(el / 0.18, 0.0, 1.0) * PI)
	var fs := 26 if txt.length() < 24 else 22
	var shown := txt.substr(0, int(ceil(clampf(el * 45.0, 0.0, float(txt.length())))))
	var w := minf(f.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x, 300.0)
	var lines := 1 if f.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x <= 300.0 else 2
	var h := float(fs) * 1.05 * float(lines) + 14.0
	var bw := w + 28.0
	# מיקום: מעל הראש, נשאר בתוך המסך
	var anchor := Vector2(0, -92)
	var ct := _ui.get_viewport().get_canvas_transform()
	var vs := _ui.get_viewport().get_visible_rect().size
	var sp := ct * player.global_position + anchor   # מיקום על המסך
	var shift_x := clampf(sp.x, bw * 0.5 + 12.0, vs.x - bw * 0.5 - 12.0) - sp.x
	var shift_y := maxf(0.0, h + 70.0 - sp.y)
	var c := sp + Vector2(shift_x, shift_y)
	var wob := 0.0
	if cat == "combat":
		wob = sin(_t * 30.0) * 0.03 * maxf(0.0, 1.0 - el / 0.5)
	elif cat == "scary" or cat == "wtf":
		c += Vector2(sin(_t * 47.0), cos(_t * 39.0)) * 1.2   # רועד מפחד / בהלם
	_ui.draw_set_transform(c, wob, Vector2(pop, pop))
	var r := Rect2(-bw * 0.5, -h, bw, h)
	# זנב הבועה (לכיוון הראש)
	var tail_x := clampf(-shift_x, -bw * 0.5 + 18.0, bw * 0.5 - 18.0)
	var tail := PackedVector2Array([Vector2(tail_x - 9, -2), Vector2(tail_x + 9, -2), Vector2(tail_x * 0.6 - 2, 20.0 - shift_y)])
	_ui.draw_colored_polygon(PackedVector2Array([tail[0] + Vector2(-3, 0), tail[1] + Vector2(3, 0), tail[2] + Vector2(0, 4)]), Color(0, 0, 0, a))
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.06, 0.05, 0.08, 0.88 * a)
	sb.border_color = Color(col, a)
	sb.set_border_width_all(3)
	sb.set_corner_radius_all(14)
	sb.shadow_color = Color(0, 0, 0, 0.45 * a)
	sb.shadow_size = 6
	_ui.draw_style_box(sb, r)
	_ui.draw_colored_polygon(tail, Color(0.06, 0.05, 0.08, 0.88 * a))
	_ui.draw_polyline(PackedVector2Array([tail[0], tail[2], tail[1]]), Color(col, a), 3.0)
	# הטקסט: קו מתאר שחור עבה + צבע הקטגוריה
	var tp := Vector2(-w * 0.5, -h + 7.0 + float(fs) * 0.92)
	f.draw_multiline_string_outline(_ui.get_canvas_item(), tp, shown, HORIZONTAL_ALIGNMENT_CENTER, w, fs, 2, 6, Color(0, 0, 0, a))
	f.draw_multiline_string(_ui.get_canvas_item(), tp, shown, HORIZONTAL_ALIGNMENT_CENTER, w, fs, 2, Color(col.lerp(Color.WHITE, 0.35), a))
	_ui.draw_set_transform_matrix(Transform2D.IDENTITY)
