extends Node
# ============================================================
#  KILL STREAK - מד רצף הריגות מעל השחקן, בצד שמאל שלו.
#  2 הריגות ומעלה במהירות (כל הריגה בתוך Game.STREAK_WINDOW מהקודמת) מציגים:
#    * מד אנכי שמצביע למעלה ומתמלא (ירוק > כחול > צהוב > כתום > אדום > סגול > זהב). מלא = קצה החץ נדלק.
#      הריגה בראש ממלאת יותר (1.5).
#    * "xN" על כוכב מתפוצץ + משפט אקראי לפי הדרגה (WORDS) שנכנס בטריקה ורעידה.
#      הריגה מיוחדת (באוויר, החלקה, דריכה, פיצוץ, מרחוק, ברגע האחרון...) = משפט מ-SPECIAL במקום.
#      הריגה בודדת מיוחדת (SOLO) = כיתוב קטן שעולה.
#    * גולגולת לכל הריגה (אדומה = ראש), קו זמן שמתקצר עד שהרצף נשבר, ו"+נקודות".
#    * דרגה חדשה: ניצוצות + צליל "דינג" שעולה בכל דרגה.
#    * HEADSHOT: חותמת אדומה גדולה מעל הזומבי.
#    * הרצף נשבר: הכל נופל ונעלם. רצף של 5+ = סיכום "x6 CHAIN +900" שעולה למעלה.
#  הלוגיקה (זמן, מד, בונוס) ב-game_state.gd (streak_*). לשנות מראה: TIERS, OFF, BAR_H.
# ============================================================

const Art := preload("res://art.gd")
const Sfx := preload("res://sfx.gd")
const FONT_PATH := "res://fonts/Bangers-Regular.ttf"

const TIERS := [
	["GOOD", Color(0.47, 0.9, 0.35)],
	["GREAT", Color(0.31, 0.78, 1.0)],
	["EXCELLENT", Color(1.0, 0.75, 0.16)],
	["AMAZING", Color(1.0, 0.47, 0.12)],
	["INSANE", Color(1.0, 0.24, 0.24)],
	["UNSTOPPABLE", Color(0.9, 0.27, 1.0)],
	["GODLIKE", Color(1.0, 0.94, 0.47)],
]
# כמה משפטים לכל דרגה - נבחר אקראית (לא אותו משפט פעמיים ברצף)
const WORDS := [
	["GOOD!", "NICE!", "DOUBLE TAP!", "TWO DOWN!", "NOT BAD!", "TWOFER!"],
	["GREAT!", "TRIPLE!", "HAT TRICK!", "SWEET!", "ON FIRE!", "KEEP GOING!"],
	["EXCELLENT!", "WICKED!", "BRUTAL!", "CLEAN UP!", "RAMPAGE!", "FOUR ON THE FLOOR!"],
	["AMAZING!", "SAVAGE!", "MASSACRE!", "KILLING SPREE!", "UNREAL!", "HIGH FIVE!"],
	["INSANE!", "MANIAC!", "BLOODBATH!", "PSYCHO!", "MAYHEM!", "NO MERCY!"],
	["UNSTOPPABLE!", "RELENTLESS!", "WRECKING BALL!", "DEATH MACHINE!", "ZOMBIE BANE!", "LUCKY SEVEN!"],
	["GODLIKE!", "LEGENDARY!", "APOCALYPSE!", "ONE MAN ARMY!", "THEY FEAR YOU!", "EXTINCTION!"],
]
# הריגות מיוחדות (תגיות מ-game_state.gd -> _kill_tags). מחליפות את המילה של הדרגה
const SPECIAL := {
	"stomp": ["STOMPED!", "BOOT PARTY!", "CURB STOMP!", "SQUASHED!"],
	"head3": ["HEAD HUNTER!", "BRAIN DRAIN!", "SHARPSHOOTER!", "SKULL COLLECTOR!"],
	"pierce": ["TWO FOR ONE!", "SKEWERED!", "SHISH KEBAB!", "LINED UP!"],
	"air": ["AIRBORNE!", "SKY HIGH!", "FROM ABOVE!", "AIR STRIKE!", "TOP GUN!"],
	"slide": ["SLIDE KILL!", "SMOOTH!", "BASEBALL SLIDE!", "SLICK!"],
	"roll": ["ROLL KILL!", "TUCK & ROLL!", "ROLLING THUNDER!", "STUNTMAN!"],
	"melee": ["BARE HANDS!", "SMACKDOWN!", "KNUCKLE SANDWICH!", "UP CLOSE & PERSONAL!"],
	"edge": ["ON THE EDGE!", "DEATH WISH!", "NOT TODAY!", "STILL BREATHING!"],
	"clutch": ["CLUTCH!", "JUST IN TIME!", "BUZZER BEATER!", "SO CLOSE!"],
	"hidden": ["FLUSHED OUT!", "NO HIDING!", "PEEKABOO!"],
	"boom": ["KABOOM!", "FIREWORKS!", "BLAST OFF!", "BOOM BOOM!", "SCATTERED!"],
	"fire": ["ROASTED!", "WELL DONE!", "BBQ!", "EXTRA CRISPY!"],
	"taser": ["SHOCKING!", "ELECTRIFIED!", "ZAPPED!", "FRIED!"],
	"far": ["LONG SHOT!", "SNIPED!", "DOWNTOWN!", "EAGLE EYE!"],
	"close": ["POINT BLANK!", "IN YOUR FACE!", "TOO CLOSE!", "PERSONAL SPACE!"],
}
const SPECIAL_COL := {"stomp": Color(1.0, 0.6, 0.25), "head3": Color(1.0, 0.3, 0.3), "pierce": Color(0.6, 0.9, 1.0), "air": Color(0.5, 0.85, 1.0),
	"slide": Color(0.5, 1.0, 0.7), "roll": Color(0.5, 1.0, 0.7), "melee": Color(1.0, 0.7, 0.4), "edge": Color(1.0, 0.35, 0.45), "hidden": Color(0.8, 0.9, 0.5)}
const SOLO := ["stomp", "head3", "pierce", "air", "slide", "roll", "melee", "edge", "hidden", "far"]   # מוצגות גם בהריגה בודדת
const BAR_COLS := [Color(0.47, 0.9, 0.35), Color(0.31, 0.78, 1.0), Color(1.0, 0.75, 0.16), Color(1.0, 0.47, 0.12),
	Color(1.0, 0.24, 0.24), Color(0.9, 0.27, 1.0), Color(1.0, 0.94, 0.47)]
const OFF := Vector2(-165.0, -10.0)    # תחתית המד ביחס לרגלי השחקן (במסך)
const BAR_W := 14.0
const BAR_H := 120.0
const BAR_Y := -92.0                  # תחתית המד (מעל הרגליים)
const OUTLINE := Color(0.08, 0.04, 0.04)

var player: Node2D = null
var count := 0
var heads: Array = []                 # true = ראש, לכל הריגה ברצף
var tier := -1
var _meter := 0.0                     # מה שמוצג (רודף אחרי Game.streak_meter)
var _pop := 0.0                       # טריקה של המילה
var _bump := 0.0                      # קפיצה של xN
var _flash := 0.0                     # הבזק לבן במד
var _spin := 0.0
var _spin_v := 0.0
var _alpha := 0.0
var _end_t := 0.0                     # נשבר: נופל ונעלם
var _bonus := 0
var _bonus_t := 0.0
var _sparks: Array = []               # [pos, vel, life, color]
var _stamps: Array = []               # HEADSHOT: [world pos, age]
var _summaries: Array = []            # [text, age, screen pos, color]
var _anchor := Vector2.ZERO
var _word := ""
var _last_word := ""
var _layer: CanvasLayer
var _ui: Node2D
static var _font: Font = null


func _ready() -> void:
	_layer = CanvasLayer.new()
	_layer.layer = 3
	add_child(_layer)
	_ui = Node2D.new()
	_layer.add_child(_ui)
	_ui.draw.connect(_draw_ui)
	Game.streak_kill.connect(_on_kill)
	Game.streak_end.connect(_on_end)


static func font() -> Font:
	if _font != null:
		return _font
	if ResourceLoader.exists(FONT_PATH):
		_font = load(FONT_PATH) as Font
	if _font == null and FileAccess.file_exists(FONT_PATH):
		var ff := FontFile.new()
		if ff.load_dynamic_font(FONT_PATH) == OK:
			_font = ff
	if _font == null:
		_font = ThemeDB.fallback_font
	return _font


func _pick(arr: Array) -> String:
	var w: String = arr[randi() % arr.size()]
	if w == _last_word and arr.size() > 1:
		w = arr[(arr.find(w) + 1 + randi() % (arr.size() - 1)) % arr.size()]
	_last_word = w
	return w


func _on_kill(n: int, head: bool, bonus: int, pos: Vector2, tags: Array) -> void:
	if head and pos != Vector2.INF:
		_stamps.append([pos, 0.0])
	if n == 1:
		heads = [head]
		count = 1
		for tg in tags:   # הריגה בודדת מיוחדת: כיתוב קטן שעולה
			if tg in SOLO:
				var c: Color = SPECIAL_COL.get(tg, Color(1.0, 0.85, 0.3))
				_summaries.append([_pick(SPECIAL[tg]), 0.0, _anchor + Vector2(70.0, -175.0), c, true])
				Sfx.play("streak_tick", null, -6.0, 0.05, 2, 1.2)
				break
		return
	_end_t = 0.0
	count = n
	_summaries = _summaries.filter(func(sm): return not sm[4])   # הרצף התחיל: הכיתוב הקטן מפנה מקום למד
	heads.append(head)
	if heads.size() > 12:
		heads.pop_front()
	_pop = 1.0
	_bump = 1.0
	_flash = 1.0
	_bonus = bonus
	_bonus_t = 0.0
	var t := clampi(n - 2, 0, TIERS.size() - 1)
	_word = _pick(SPECIAL[tags[0]]) if not tags.is_empty() and SPECIAL.has(tags[0]) else _pick(WORDS[t])
	if t != tier or n == 2:
		tier = t
		_spin_v = 9.0
		_burst_sparks(TIERS[tier][1], 14 + tier * 3)
		Sfx.play("streak_up", null, -4.0 + float(tier) * 0.4, 0.0, 2, 1.0 + 0.09 * float(tier))
	else:
		Sfx.play("streak_tick", null, -8.0, 0.05, 3, 1.0 + 0.03 * float(n))


func _on_end(n: int, total: int) -> void:
	if n >= 2:
		_end_t = 0.001
	if n >= 5 and tier >= 0:
		_summaries.append(["x%d CHAIN  +%d" % [n, total], 0.0, _anchor + Vector2(70.0, -185.0), TIERS[tier][1], false])
	count = 0


func _burst_sparks(col: Color, n: int) -> void:
	for i in n:
		var a := randf() * TAU
		_sparks.append([Vector2(55.0, -195.0), Vector2.from_angle(a) * randf_range(120.0, 320.0), randf_range(0.35, 0.7), col.lerp(Color.WHITE, randf() * 0.5)])


func _process(delta: float) -> void:
	if player == null or not is_instance_valid(player):
		player = get_tree().get_first_node_in_group("player") as Node2D
	_pop = maxf(_pop - delta * 4.5, 0.0)
	_bump = maxf(_bump - delta * 6.0, 0.0)
	_flash = maxf(_flash - delta * 5.0, 0.0)
	_spin_v = move_toward(_spin_v, 0.6, delta * 18.0)
	_spin += _spin_v * delta
	_bonus_t += delta
	_meter = move_toward(_meter, Game.streak_meter / Game.STREAK_FULL, delta * 3.0) if Game.streak > 0 else _meter
	var showing := count >= 2 and Game.streak > 0
	if _end_t > 0.0:
		_end_t += delta
		_alpha = maxf(1.0 - _end_t / 0.45, 0.0)
		if _end_t > 0.45:
			_end_t = 0.0
			_meter = 0.0
			tier = -1
			heads.clear()
	elif showing:
		_alpha = move_toward(_alpha, 1.0, delta * 10.0)
	else:
		_alpha = move_toward(_alpha, 0.0, delta * 4.0)
	for s in _sparks:
		s[0] += s[1] * delta
		s[1] = s[1] * (1.0 - 3.0 * delta) + Vector2(0.0, 300.0) * delta
		s[2] -= delta
	_sparks = _sparks.filter(func(s): return s[2] > 0.0)
	for s in _stamps:
		s[1] += delta
	_stamps = _stamps.filter(func(s): return s[1] < 1.2)
	for s in _summaries:
		s[1] += delta
	_summaries = _summaries.filter(func(s): return s[1] < 1.6)
	# מיקום: מעל השחקן משמאל, אבל תמיד בתוך המסך
	if player != null:
		var vp := _ui.get_viewport_rect().size
		var ps: Vector2 = _ui.get_viewport().get_canvas_transform() * player.global_position
		_anchor = Vector2(clampf(ps.x + OFF.x, 30.0, vp.x - 260.0), clampf(ps.y + OFF.y, 250.0, vp.y - 10.0))
	_ui.queue_redraw()


# ============================================================
#  ציור
# ============================================================
func _draw_ui() -> void:
	var ci := _ui
	var f := font()
	if _alpha > 0.01 and tier >= 0:
		var a := _alpha
		var o := _anchor + Vector2(0.0, 22.0 * (1.0 - _alpha) if _end_t > 0.0 else 0.0)
		var col: Color = TIERS[tier][1]
		_draw_bar(ci, o, a, col)
		# כוכב מתפוצץ + xN
		var c := o + Vector2(55.0, -190.0)
		_draw_burst(ci, c, 30.0 + 6.0 * _bump, col, a)
		_text(ci, f, "x%d" % count, c + Vector2(-2.0, 14.0), 42.0 * (1.0 + 0.35 * _bump), -0.14, Color.WHITE.lerp(col, 0.25), a, 9, true)
		# המילה: טריקה + רעידה
		var sh := Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * 5.0 * _pop
		var ws := 1.0 + 1.3 * _pop * _pop
		var wsz := 32.0 * clampf(11.0 / float(maxi(_word.length(), 1)), 0.62, 1.0)   # מילים ארוכות קטנות יותר
		_text(ci, f, _word, o + Vector2(92.0, -186.0) + sh, wsz * ws, -0.1, col, a, 8, false)
		# גולגולות (אדומה = ראש)
		for i in heads.size():
			var sp := o + Vector2(98.0 + float(i) * 17.0, -146.0 + (1.5 if i % 2 == 0 else 0.0))
			var pop := (1.0 + 0.8 * _bump) if i == heads.size() - 1 else 1.0
			_skull(ci, sp, 6.0 * pop, Color(1.0, 0.36, 0.3) if heads[i] else Color(0.93, 0.93, 0.88), a)
		# קו זמן עד שהרצף נשבר
		var tk := clampf(Game.streak_t / Game.STREAK_WINDOW, 0.0, 1.0) if Game.streak > 0 else 0.0
		var tl := Rect2(o + Vector2(92.0, -134.0), Vector2(130.0, 5.0))
		ci.draw_rect(tl.grow(1.0), Color(0, 0, 0, 0.55 * a))
		ci.draw_rect(Rect2(tl.position, Vector2(tl.size.x * tk, tl.size.y)), Color(col, a))
		# +נקודות
		if _bonus > 0 and _bonus_t < 0.9:
			var bk := _bonus_t / 0.9
			_text(ci, f, "+%d" % _bonus, o + Vector2(140.0, -108.0 - 26.0 * bk), 22.0, -0.1, Color.WHITE, a * (1.0 - bk * bk), 6, false)
	for s in _sparks:
		var sc: Color = s[3]
		ci.draw_circle(_anchor + s[0], 2.2 * clampf(s[2] / 0.4, 0.3, 1.0), Color(sc, clampf(s[2] * 2.5, 0.0, 1.0)))
	# HEADSHOT מעל הזומבי
	var xf := ci.get_viewport().get_canvas_transform()
	for st in _stamps:
		var age: float = st[1]
		var sp: Vector2 = xf * (st[0] as Vector2) + Vector2(0.0, -14.0 - 18.0 * age)
		var k := 1.0 + 1.4 * pow(maxf(1.0 - age / 0.15, 0.0), 2.0)
		var al := 1.0 if age < 0.85 else maxf(1.0 - (age - 0.85) / 0.35, 0.0)
		_skull(ci, sp + Vector2(0.0, -30.0 * k), 7.0 * k, Color(1.0, 0.36, 0.3), al, true)
		_text(ci, f, "HEADSHOT!", sp + Vector2(-52.0 * k, 0.0), 24.0 * k, -0.14, Color(1.0, 0.25, 0.2), al, 7, false)
	for s in _summaries:
		var age2: float = s[1]
		var al2 := 1.0 if age2 < 1.0 else maxf(1.0 - (age2 - 1.0) / 0.6, 0.0)
		_text(ci, f, s[0], (s[2] as Vector2) + Vector2(0.0, -50.0 * age2), 30.0, -0.08, s[3], al2, 8, true)


func _draw_bar(ci: CanvasItem, o: Vector2, a: float, col: Color) -> void:
	var x0 := o.x
	var bot := o.y + BAR_Y
	var top := bot - BAR_H
	var r := Rect2(x0, top, BAR_W, BAR_H)
	ci.draw_rect(r.grow(3.0), Color(0.06, 0.05, 0.07, 0.88 * a))
	ci.draw_rect(r.grow(3.0), Color(1, 1, 1, 0.8 * a), false, 2.0)
	var fy := bot - BAR_H * clampf(_meter, 0.0, 1.0)
	var y := bot
	while y > fy:   # מילוי בצבעים לפי הגובה
		var t := (bot - y) / BAR_H
		var i := mini(int(t * 6.999), 6)
		var fr := t * 7.0 - float(i)
		var c: Color = (BAR_COLS[i] as Color).lerp(BAR_COLS[mini(i + 1, 6)], fr * 0.6)
		var h := minf(2.0, y - fy)
		ci.draw_rect(Rect2(x0, y - h, BAR_W, h), Color(c.lerp(Color.WHITE, _flash * 0.6), a))
		y -= 2.0
	if _meter > 0.0:
		ci.draw_line(Vector2(x0 + 3.0, fy + 2.0), Vector2(x0 + 3.0, bot - 2.0), Color(1, 1, 1, 0.4 * a), 2.0)
		ci.draw_rect(Rect2(x0 - 4.0, fy - 2.0, BAR_W + 8.0, 4.0), Color(1.0, 1.0, 0.94, a))
		Art.glow(ci, Vector2(x0 + BAR_W * 0.5, fy), 16.0 + 10.0 * _flash, Color(col, 0.55 * a))
	for i in range(1, 7):   # שנתות = דרגות
		var ny := bot - BAR_H * float(i) / 7.0
		ci.draw_line(Vector2(x0 - 3.0, ny), Vector2(x0 + 5.0, ny), Color(1, 1, 1, 0.85 * a), 2.0)
	# קצה החץ למעלה: נדלק כשהמד מלא
	var full := _meter >= 0.999
	var tip := PackedVector2Array([Vector2(x0 - 6.0, top - 3.0), Vector2(x0 + BAR_W + 6.0, top - 3.0), Vector2(x0 + BAR_W * 0.5, top - 24.0)])
	var tc := Color(1.0, 0.94, 0.47) if full else Color(0.16, 0.14, 0.2)
	if full:
		tc = tc.lerp(Color.WHITE, 0.4 + 0.4 * sin(Time.get_ticks_msec() * 0.02))
		Art.glow(ci, Vector2(x0 + BAR_W * 0.5, top - 12.0), 26.0, Color(1.0, 0.9, 0.4, 0.7 * a))
	ci.draw_colored_polygon(tip, Color(tc, a))
	tip.append(tip[0])
	ci.draw_polyline(tip, Color(1, 1, 1, 0.85 * a), 2.0)


func _draw_burst(ci: CanvasItem, c: Vector2, r: float, col: Color, a: float) -> void:
	var pts := PackedVector2Array()
	for i in 28:
		var ang := _spin + float(i) * PI / 14.0
		pts.append(c + Vector2.from_angle(ang) * (r if i % 2 == 0 else r * 0.62))
	Art.glow(ci, c, r * 1.5, Color(col, 0.45 * a))
	ci.draw_colored_polygon(pts, Color(col.darkened(0.15), 0.9 * a))
	pts.append(pts[0])
	ci.draw_polyline(pts, Color(OUTLINE, a), 2.5)


# טקסט עם קו מתאר עבה, צל וזוהר, מסובב סביב נקודת ההתחלה
func _text(ci: CanvasItem, f: Font, txt: String, pos: Vector2, size: float, rot: float, col: Color, a: float, ow: int, center: bool) -> void:
	var fs := int(size)
	var w := f.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	var org := Vector2(-w * 0.5, 0.0) if center else Vector2.ZERO
	ci.draw_set_transform(pos, rot, Vector2.ONE)
	Art.glow(ci, org + Vector2(w * 0.5, -size * 0.35), maxf(w * 0.55, size * 0.6), Color(col, 0.16 * a))
	ci.draw_string_outline(f, org + Vector2(2.0, 3.0), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, ow, Color(0, 0, 0, 0.45 * a))
	ci.draw_string_outline(f, org, txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, ow, Color(OUTLINE, a))
	ci.draw_string(f, org, txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(col, a))
	# הברקה עליונה
	ci.draw_string(f, org + Vector2(0.0, -size * 0.06), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(1, 1, 1, 0.18 * a))
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _skull(ci: CanvasItem, c: Vector2, s: float, col: Color, a: float, cross := false) -> void:
	var o := Color(OUTLINE, a)
	ci.draw_circle(c, s + 1.5, o)
	ci.draw_rect(Rect2(c + Vector2(-s * 0.55 - 1.5, s * 0.3), Vector2(s * 1.1 + 3.0, s * 0.85 + 1.5)), o)
	ci.draw_circle(c, s, Color(col, a))
	ci.draw_rect(Rect2(c + Vector2(-s * 0.55, s * 0.3), Vector2(s * 1.1, s * 0.85)), Color(col, a))
	ci.draw_circle(c + Vector2(-s * 0.38, s * 0.05), s * 0.27, o)
	ci.draw_circle(c + Vector2(s * 0.38, s * 0.05), s * 0.27, o)
	if cross:
		var rc := Color(1.0, 0.24, 0.2, a)
		ci.draw_arc(c, s * 1.55, 0.0, TAU, 24, rc, 2.0)
		for d in [Vector2.LEFT, Vector2.RIGHT, Vector2.UP]:
			ci.draw_line(c + d * s * 1.15, c + d * s * 2.0, rc, 2.0)
