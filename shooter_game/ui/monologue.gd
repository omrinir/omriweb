extends Node
# ============================================================
#  MONOLOGUE - השחקן מדבר לעצמו (בועת קומיקס מעל הראש + קריינות בקול גבר כהה).
#  כרגע פעיל רק בשלב 14 (levels/stage_14.gd -> build_effects מוסיף אותו).
#  כל משפט מחובר לאירוע אמיתי במשחק: Game.story (signal) נשלח מ-zombie.gd, player.gd,
#  ai/zombie_brain.gd, ai/squad_director.gd ומהשלב עצמו (רעם). חלק מהמצבים נבדקים כל 0.3 שנ' (_poll).
#
#  LINES: [טקסט, קטגוריה, קובץ קול]. קטגוריות: "combat" (צהוב-כתום), "scary" (תכלת), "smart" (סגול).
#  איך מוסיפים משפט: שורה ב-LINES + קובץ sounds/voice/vNN.mp3 + קריאה ל-_try(NN, עדיפות) במקום המתאים.
#  כמה הוא מדבר: MAX_LINES (כרגע 2 בשלב), MIN_BETWEEN (שניות בין משפטים), FIRST_AFTER, COMBAT_CHANCE.
#  הקולות נוצרו עם Kokoro TTS (קול am_onyx - בריטון עמוק) + ffmpeg בסגנון "גיבור נואר" (מקס פיין / מקס הזועם):
#  הגשה איטית ושטוחה, צרידות (ענף מעוות + טרמולו מהיר), מיקרופון קרוב, חדר קטן ויבש.
# ============================================================

const Art := preload("res://art.gd")
const Registry := preload("res://enemies/zombie_registry.gd")
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
}
const COLORS := {"combat": Color("ffd23a"), "scary": Color("9fe8ff"), "smart": Color("d8a8ff")}
const GAP := 4.5            # שקט מינימלי אחרי משפט (עדיפות 3 = רק 1.5 שנ')
const LINE_CD := 40.0       # אותו משפט לא חוזר לפני זה
const ONCE := [14, 22]      # רק פעם אחת בשלב
const VOICE_DB := 1.0
# כמה הוא מדבר: מעט, ורק ברגעים החזקים
const MAX_LINES := 2        # הכי הרבה משפטים בשלב אחד
const MIN_BETWEEN := 75.0   # שניות לפחות בין שני המשפטים
const FIRST_AFTER := 20.0   # לפני זה (תחילת השלב) - רק רגע חשוב באמת (עדיפות 3)
const COMBAT_CHANCE := 0.35 # משפטי קרב (עדיפות 1) קורים רק לפעמים, כדי שלא תמיד יבחר דווקא אותם

static var _font: Font = null

var player: Node2D = null
var said := {}              # id -> כמה פעמים (לבדיקות)
var log_lines := []         # [זמן, id] (לבדיקות)
var _t := 0.0
var _line_t := {}           # id -> מתי נאמר לאחרונה
var _cur := 0               # המשפט שמוצג עכשיו
var _show := 0.0            # כמה זמן הבועה עוד מוצגת
var _dur := 0.0
var _quiet := 2.0           # כמה זמן חייבים לשתוק
var _pending := 0
var _pending_p := 0
var _pending_t := 0.0
var _voice: AudioStreamPlayer
var _layer: CanvasLayer      # הבועה מעל הכל (גם מעל החושך של השלב)
var _ui: Node2D
var _poll_t := 0.0
# מעקב אחרי זומבים
var _hits := {}             # instance_id -> [זמני פגיעה]
var _total := {}            # instance_id -> סה"כ פגיעות
var _flags := {}            # instance_id -> {"die":, "why":, "lying":, "smart":}
var _attackers := {}        # זומבים שפגעו בך
var _kills := []
var _cleared_t := -99.0
var _dodges := 0
var _was_dark := false
var _was_inside := false
var _seen_big := {}


func _ready() -> void:
	add_to_group("monologue")
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


# ---- לבקש משפט. עדיפות: 1 = קרב (אפשר לוותר), 2 = רגיל, 3 = חשוב (מפחיד / הם חכמים) ----
func _try(id: int, prio := 1) -> bool:
	if player == null or player.dead:
		return false
	if log_lines.size() >= MAX_LINES:
		return false
	if not log_lines.is_empty() and _t - float(log_lines[-1][0]) < MIN_BETWEEN:
		return false
	if _t < FIRST_AFTER and prio < 3:
		return false
	if prio == 1 and randf() > COMBAT_CHANCE:
		return false
	if id in ONCE and said.has(id):
		return false
	if _t - float(_line_t.get(id, -999.0)) < LINE_CD:
		return false
	var busy: bool = _show > 0.0 or _quiet > (GAP - 1.5 if prio >= 3 else 0.0)
	if busy:
		if prio > _pending_p:   # עסוק: שומרים את החשוב ביותר לעוד רגע
			_pending = id
			_pending_p = prio
			_pending_t = 2.0
		return false
	_say(id)
	return true


func _say(id: int) -> void:
	_cur = id
	said[id] = int(said.get(id, 0)) + 1
	_line_t[id] = _t
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
	_quiet = _dur + GAP
	_pending = 0
	_pending_p = 0


func say_now(id: int) -> void:   # לבדיקות / לשלב
	_say(id)


# ============================================================
#  אירועים
# ============================================================
func _zid(info: Dictionary) -> int:
	var z = info.get("z")
	if z == null or not is_instance_valid(z):
		return 0
	return z.get_instance_id()


func _flag(id: int) -> Dictionary:
	if not _flags.has(id):
		_flags[id] = {}
	return _flags[id]


func _on_story(ev: String, info: Dictionary) -> void:
	if player == null or not is_instance_valid(player) or player.dead:
		return
	var z = info.get("z")
	var zid := _zid(info)
	var zv: bool = zid != 0
	var dx: float = (z.global_position.x - player.global_position.x) if zv else 0.0
	match ev:
		"zhit":
			if not zv:
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
				_try(3, 1)                                   # Stay down!
			elif int(_total[zid]) >= 10 and not f.has("why"):
				f["why"] = true
				_try(2, 2)                                   # Why won't you fucking die?!
			elif arr.size() >= 6 and not f.has("die"):
				f["die"] = true
				_try(1, 1)                                   # Die! Die! DIE!
		"zkill":
			if not zv:
				return
			_kills.append(_t)
			_kills = _kills.filter(func(q: float) -> bool: return _t - q < 25.0)
			var f := _flag(zid)
			if _attackers.has(zid) or z.is_boss():
				_try(10, 2)                                  # I've had enough of you!
			elif f.has("lying") or bool(z.get("_one_leg")):
				_try(4, 1)                                   # You're not getting back up.
			elif f.has("smart") or absf(dx) > 520.0:
				_try(7, 1)                                   # Got you!
			_check_last.call_deferred(zid)
		"wake":   # נבדק רגע אחרי: אם קם כי ירו בו - זה לא "הפחיד אותי" (זה Stay down!)
			if zv and absf(dx) < 230.0:
				_wake_check.call_deferred(zid)
		"notice":
			if not zv:
				return
			if Game.player_dark and absf(dx) < 700.0:
				_try(21, 3)                                  # They know where I am.
			elif not Art.on_screen(z, z.global_position) and absf(dx) < 1300.0:
				_try(16, 2)                                  # I heard something...
			elif absf(dx) < 170.0 and signf(dx) != player._face():
				_try(11, 3)                                  # Shit! You scared me!
			elif _t - _cleared_t < 14.0:
				_try(17, 2)                                  # Please don't let there be more of them.
		"phurt":
			var near := _nearest(150.0)
			if near != null:
				_attackers[near.get_instance_id()] = true
				if absf(near.global_position.x - player.global_position.x) < 80.0 and randf() < 0.6:
					_try(9, 1)                               # Back off!
		"reload":
			if _chasing_within(320.0) >= 1:
				_try(5, 1)                                   # Come on! Come on!
		"grenade":
			if _nearest(480.0) != null:
				_try(8, 1)                                   # Eat this!
		"dodge":
			if zv:
				_flag(zid)["smart"] = true
			_dodges += 1
			_try(19 if _dodges == 1 else 20, 3)              # Wait... they're learning. / That didn't work twice.
		"ambush":
			if zv:
				_flag(zid)["smart"] = true
			_try(22, 3)                                      # How the hell did it know I'd go this way?
		"flank_jump":
			if zv:
				_flag(zid)["smart"] = true
			_try(25, 3)                                      # Oh shit. They figured me out.
		"cover":
			if zv and Art.on_screen(z, z.global_position):
				_try(24, 2)                                  # Okay... they're getting smarter.
		"adapt":
			if zv:
				_flag(zid)["smart"] = true
			if not _try(19, 3):
				_try(24, 2)
		"call", "squad":
			if zv and absf(dx) < 1000.0:
				if not _try(23, 3) and Game.player_dark:     # They're working together...
					_try(21, 3)
		"thunder":
			if randf() < 0.5:
				_try(13, 2)                                  # What the hell was that?
		"scare":   # השלב / זומבי מיוחד: קפיצת פחד
			_try(11, 3)
		"big":
			_try(12, 3)


func _wake_check(zid: int) -> void:
	if not _flag(zid).has("lying"):
		_try(11, 3)                                      # Shit! You scared me!


func _check_last(_zid_v: int) -> void:
	if player == null or not is_instance_valid(player) or _kills.size() < 3:
		return
	for z in get_tree().get_nodes_in_group("zombies"):
		if z.dead or z.dormant:
			continue
		if absf(z.global_position.x - player.global_position.x) < 1100.0:
			return
	if _try(6, 2):                                       # That's the last one.
		_cleared_t = _t


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
		if not z.dead and bool(z.get("_chasing")) and absf(z.global_position.x - player.global_position.x) < r:
			n += 1
	return n


# ---- מצבים שנבדקים כל הזמן ----
func _poll() -> void:
	if _t > 30.0 and not said.has(14) and _nearest(700.0) == null and randf() < 0.01:
		_try(14, 2)                                      # I really don't like this place. (רגע שקט)
	# It's really fucking dark in here: כשנכנסים לאזור חשוך (המפעל), או פעם אחת בחושך בחוץ
	var inside := false
	for dz in get_tree().get_nodes_in_group("dark_zone"):
		if dz.has_point(player.global_position):
			inside = true
	if inside and not _was_inside:
		_try(15, 3)
	_was_inside = inside
	_was_dark = Game.player_dark
	if _chasing_within(520.0) >= 4:
		_try(18, 2)                                      # They're getting closer...
	for z in get_tree().get_nodes_in_group("zombies"):
		if z.dead or z.dormant:
			continue
		var big: bool = z.sc >= 1.4 or z.is_boss() or z.kind == Registry.RETCHER
		if big and not _seen_big.has(z.kind) and Art.on_screen(z, z.global_position):
			_seen_big[z.kind] = true
			_try(12, 3)                                  # Jesus Christ...
		var dx: float = z.global_position.x - player.global_position.x
		if absf(dx) < 46.0 and absf(z.global_position.y - player.global_position.y) < 40.0 and not z._lying() and signf(dx) == player._face():
			if randf() < 0.25:
				_try(9, 1)                                   # Back off!


func _process(delta: float) -> void:
	_t += delta
	if player == null or not is_instance_valid(player):
		player = get_tree().get_first_node_in_group("player")
		return
	_show -= delta
	_quiet -= delta
	_pending_t -= delta
	if _pending_t <= 0.0:
		_pending = 0
		_pending_p = 0
	elif _pending != 0 and _show <= 0.0 and _quiet <= (GAP - 1.5 if _pending_p >= 3 else 0.0):
		var pid := _pending
		_pending = 0
		_pending_p = 0
		_say(pid)
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
	elif cat == "scary":
		c += Vector2(sin(_t * 47.0), cos(_t * 39.0)) * 1.2   # רועד מפחד
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
