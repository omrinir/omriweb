extends Node2D
const Arsenal := preload("res://progression/arsenal.gd")
const LevelClock := preload("res://progression/level_clock.gd")
const Sfx := preload("res://sfx.gd")
# ============================================================
#  HUD: לבבות, מגן, נשק ותחמושת, בוסטים, ניקוד + קומבו, מספר שלב,
#  בר חיים של הבוס, צבע של BULLET TIME והודעת GAME OVER.
#  נוצר ע"י main.gd בתוך CanvasLayer (לא זז עם המצלמה).
# ============================================================

const Art := preload("res://art.gd")
const PickupScript := preload("res://pickup.gd")
const WeaponDB := preload("res://weapons/weapon_db.gd")
const Upgrades := preload("res://progression/upgrade_db.gd")

var hearts_pos := Vector2(24, 46)
var heart_gap := 30.0
var player: Node = null

var _health := 5
var _max := 5
var _weapon := 0
var _game_over := false
var _pulse := 0.0
var _score_shown := 0.0
var _combo_pop := 0.0
var _last_mult := 1
var difficulty := ""
var difficulty_color := Color.WHITE


func set_health(h: int, m: int) -> void:
	if h < _health:
		_pulse = 0.4
	_health = h
	_max = m


func set_weapon(w: int) -> void:
	_weapon = w


func show_game_over() -> void:
	_game_over = true


var _intro_t := 0.0   # כותרת השלב (THEY LEARN)
var _tier_shown := 0      # דרגת הלמידה שכבר הודענו עליה
var _learn_alert := 0.0   # התראה "THEY'RE LEARNING YOU" (שניות שנשארו)
var _last_tick := -1      # צליל תקתוק בשניות האחרונות לפני GOLD / SILVER


func _process(delta: float) -> void:
	_intro_t += delta / maxf(Engine.time_scale, 0.05)
	_clock_update(delta)
	_pulse = maxf(_pulse - delta, 0.0)
	_combo_pop = maxf(_combo_pop - delta * 3.0, 0.0)
	_score_shown = move_toward(_score_shown, float(Game.run_score + Game.level_score), maxf(400.0 * delta, absf(float(Game.run_score + Game.level_score) - _score_shown) * 6.0 * delta))
	var m := Game.multiplier()
	if m != _last_mult:
		if m > _last_mult:
			_combo_pop = 1.0
		_last_mult = m
	queue_redraw()


func _heart(c: Vector2, s: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in 28:
		var t := TAU * float(i) / 28.0
		var x := 16.0 * pow(sin(t), 3.0)
		var y := -(13.0 * cos(t) - 5.0 * cos(2.0 * t) - 2.0 * cos(3.0 * t) - cos(4.0 * t))
		pts.append(c + Vector2(x, y) * s)
	return pts


# כותרת בתחילת השלב: מה הזומבים למדו הפעם
func _draw_intro(vp: Vector2) -> void:
	if _intro_t > 5.0:
		return
	var a := clampf(_intro_t / 0.6, 0.0, 1.0) * clampf((5.0 - _intro_t) / 1.2, 0.0, 1.0)
	var t: Array = Game.level_title()
	var y := vp.y * 0.36
	for i in 8:   # פס כהה רך
		var h := 120.0 - float(i) * 12.0
		draw_rect(Rect2(0, y - h * 0.5, vp.x, h), Color(0, 0, 0, 0.09 * a))
	var spread := 1.0 + 0.04 * _intro_t   # הכותרת "נפתחת" לאט
	_text(Vector2(0, y - 34), "STAGE %d  ·  %s" % [Game.level, Game.level_name(Game.level).to_upper()], 18, Color(1, 1, 1, 0.7 * a), HORIZONTAL_ALIGNMENT_CENTER, vp.x)
	var f := ThemeDB.fallback_font
	var title: String = t[0]
	var fs := int(54.0 * spread)
	var w := f.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	draw_string_outline(f, Vector2((vp.x - w) * 0.5, y + 22), title, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, 6, Color(0, 0, 0, 0.8 * a))
	draw_string(f, Vector2((vp.x - w) * 0.5, y + 22), title, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(0.85, 0.12, 0.1, a))
	_text(Vector2(0, y + 52), t[1], 18, Color(0.9, 0.85, 0.8, 0.85 * a), HORIZONTAL_ALIGNMENT_CENTER, vp.x)


# "העין": סמל עדין של כמה הזומבים "ערים" בשלב הזה. בלי מספרים - נפתחת יותר בכל שלב,
# ומהבהבת באדום כשהם מתקשרים / מקבלים פקודות (ai/squad_director.gd)
var _eye_flash := 0.0
var _last_calls := 0
func _draw_eye(c: Vector2) -> void:
	var sd := get_tree().get_first_node_in_group("squad_director")
	if sd != null:
		var calls: int = sd.calls_made + sd.commands_issued
		if calls != _last_calls:
			_last_calls = calls
			_eye_flash = 1.0
	_eye_flash = maxf(_eye_flash - get_process_delta_time() * 1.2, 0.0)
	var open := clampf(float(Game.level - 1) / 8.0, 0.08, 1.0)
	var w := 13.0
	var h := 7.5 * open
	var lid := PackedVector2Array()
	for i in 17:
		var t := PI * float(i) / 16.0
		lid.append(c + Vector2(-cos(t) * w, -sin(t) * h))
	for i in range(1, 16):
		var t := PI * float(i) / 16.0
		lid.append(c + Vector2(cos(t) * w, sin(t) * h))
	draw_colored_polygon(lid, Color(0.05, 0.02, 0.02, 0.8))
	var ic := Color(0.75, 0.15, 0.1).lerp(Color(1.0, 0.35, 0.2), _eye_flash)
	if h > 1.5:
		draw_circle(c, minf(h, 5.0), Color(ic, 0.9))
		draw_circle(c, minf(h, 5.0) * 0.4, Color(0, 0, 0, 0.9))
	lid.append(lid[0])
	draw_polyline(lid, Color(0.85, 0.8, 0.75, 0.6), 1.2, true)
	if _eye_flash > 0.0:
		draw_circle(c, 18.0, Color(1.0, 0.2, 0.1, 0.12 * _eye_flash))


func _text(pos: Vector2, t: String, size: int, col: Color, align := HORIZONTAL_ALIGNMENT_LEFT, width := -1.0) -> void:
	var f := ThemeDB.fallback_font
	draw_string_outline(f, pos, t, align, width, size, 4, Color(0, 0, 0, 0.75))
	draw_string(f, pos, t, align, width, size, col)


# ============================================================
#  THEY LEARN CLOCK (progression/level_clock.gd): שעון למעלה באמצע + פס GOLD / SILVER / אדום
# ============================================================
func _clock_update(delta: float) -> void:
	_learn_alert = maxf(_learn_alert - delta, 0.0)
	if Game.learn_tier < _tier_shown:   # שלב חדש / TRY AGAIN
		_tier_shown = Game.learn_tier
	if Game.learn_tier > _tier_shown:
		_tier_shown = Game.learn_tier
		_learn_alert = 2.8
		Sfx.play("zscream", null, -4.0, 0.0, 1, 0.6)
		Sfx.play("thunder", null, -10.0, 0.0, 1, 0.7)
	var p: Vector2 = Game.clock_pars
	var t := Game.level_time
	var goal := p.x if t <= p.x else (p.y if t <= p.y else -1.0)
	if goal > 0.0:   # 10 השניות האחרונות לפני היעד: תקתוק
		var left := int(ceil(goal - t))
		if left <= 10 and left != _last_tick and left > 0:
			_last_tick = left
			Sfx.play("beep", null, -14.0 + float(10 - left) * 0.6, 0.0, 1, 1.4 if left > 3 else 1.8)


func _draw_clock(vp: Vector2) -> void:
	var p: Vector2 = Game.clock_pars
	if p.x <= 0.0 or player == null:
		return
	var t := Game.level_time
	var cx := vp.x * 0.5
	var gold_c := Color("f0c040")
	var silver_c := Color("c8ccd8")
	var red_c := Color("ff3a2a")
	var goal := p.x if t <= p.x else (p.y if t <= p.y else -1.0)
	var left := goal - t
	var urgent := goal > 0.0 and left <= 10.0
	var beat := 0.5 + 0.5 * sin(Game.level_time * TAU)   # פעימה פעם בשנייה
	# הזמן עצמו
	var tcol := Color.WHITE
	if Game.learn_tier > 0:
		tcol = red_c.lerp(Color.WHITE, 0.25 * beat)
	elif urgent:
		tcol = (gold_c if t <= p.x else silver_c).lerp(red_c, beat)
	var fs := 30 + (int(3.0 * beat) if urgent or Game.learn_tier > 0 else 0)
	_text(Vector2(0, 66), LevelClock.fmt(t), fs, tcol, HORIZONTAL_ALIGNMENT_CENTER, vp.x)
	# פס: GOLD | SILVER | למידה (3 דרגות)
	var full := p.y + LevelClock.LEARN_STEP * float(LevelClock.MAX_TIER)
	var bw := 220.0
	var bx := cx - bw * 0.5
	var by := 74.0
	var gx := bw * p.x / full
	var sx := bw * p.y / full
	draw_rect(Rect2(bx - 2, by - 2, bw + 4, 10), Color(0, 0, 0, 0.6))
	draw_rect(Rect2(bx, by, gx, 6), Color(gold_c, 0.35))
	draw_rect(Rect2(bx + gx, by, sx - gx, 6), Color(silver_c, 0.3))
	draw_rect(Rect2(bx + sx, by, bw - sx, 6), Color(red_c, 0.3))
	var k := clampf(t / full, 0.0, 1.0)
	var fill_c := gold_c if t <= p.x else (silver_c if t <= p.y else red_c)
	draw_rect(Rect2(bx, by, bw * k, 6), fill_c)
	draw_rect(Rect2(bx + bw * k - 1.5, by - 4, 3, 14), Color.WHITE)   # הסמן
	for i in LevelClock.MAX_TIER:   # 3 עיניים בקטע האדום: נדלקות בכל דרגת למידה
		var ex := bx + sx + (bw - sx) * (float(i) + 0.5) / float(LevelClock.MAX_TIER)
		var on := i < Game.learn_tier
		Art.oval(self, Vector2(ex, by + 17), 5.0, 2.6, Color(red_c, 0.95) if on else Color(0, 0, 0, 0.55), 0.0, Art.NONE)
		if on:
			draw_circle(Vector2(ex, by + 17), 1.6, Color(1, 0.9, 0.6))
	# מה היעד עכשיו
	var label := ""
	var lcol := Color.WHITE
	if t <= p.x:
		label = "GOLD  %s" % LevelClock.fmt(left + 0.99)
		lcol = gold_c
	elif t <= p.y:
		label = "SILVER  %s" % LevelClock.fmt(left + 0.99)
		lcol = silver_c
	else:
		label = LevelClock.TIER_WORDS[Game.learn_tier]
		lcol = Color(red_c, 0.6 + 0.4 * beat)
	_text(Vector2(0, by + 35), label, 13, lcol, HORIZONTAL_ALIGNMENT_CENTER, vp.x)
	# התראה גדולה כשהם מתחילים ללמוד אותך
	if _learn_alert > 0.0:
		var a := clampf(_learn_alert / 0.6, 0.0, 1.0) * clampf((2.8 - _learn_alert) / 0.2, 0.0, 1.0)
		for i in 6:   # הבזק אדום בשוליים
			var w := 40.0 + float(i) * 22.0
			draw_rect(Rect2(0, 0, w, vp.y), Color(0.6, 0.0, 0.0, 0.05 * a))
			draw_rect(Rect2(vp.x - w, 0, w, vp.y), Color(0.6, 0.0, 0.0, 0.05 * a))
		_text(Vector2(0, vp.y * 0.3), LevelClock.TIER_WORDS[Game.learn_tier], 42, Color(1.0, 0.2, 0.15, a), HORIZONTAL_ALIGNMENT_CENTER, vp.x)
		_text(Vector2(0, vp.y * 0.3 + 30), "too slow  -  they read your every move", 16, Color(1, 0.85, 0.8, 0.8 * a), HORIZONTAL_ALIGNMENT_CENTER, vp.x)


func _draw() -> void:
	var vp := get_viewport_rect().size
	_draw_intro(vp)
	_draw_clock(vp)
	if _intro_t < 1.0:   # מעבר שלב: נכנסים מתוך שחור
		draw_rect(Rect2(Vector2.ZERO, vp), Color(0, 0, 0, 1.0 - _intro_t))
	# BULLET TIME: המסך כחלחל-אפור
	if Engine.time_scale < 0.99 and not _game_over:
		draw_rect(Rect2(Vector2.ZERO, vp), Color(0.55, 0.62, 0.8, 0.13))
		for i in 4:
			var w := 60.0 - float(i) * 14.0
			draw_rect(Rect2(Vector2.ZERO, Vector2(w, vp.y)), Color(0.1, 0.12, 0.2, 0.08))
			draw_rect(Rect2(Vector2(vp.x - w, 0), Vector2(w, vp.y)), Color(0.1, 0.12, 0.2, 0.08))
	# ---- לבבות + מגן ----
	for i in _max:
		var c := hearts_pos + Vector2(float(i) * heart_gap, 0.0)
		var full := i < _health
		var s := 0.62
		if full and i == _health - 1 and _pulse > 0.0:
			s *= 1.0 + _pulse * 0.5
		if full:
			Art.fill(self, _heart(c, s), Color("e0283a"), Color(0.1, 0.0, 0.0, 0.9), 2.0)
			Art.oval(self, c + Vector2(-4.5, -4.0), 2.6, 1.8, Color(1, 1, 1, 0.45), -0.6, Art.NONE)
		else:
			Art.fill(self, _heart(c, s), Color(0.15, 0.05, 0.07, 0.6), Color(0.6, 0.6, 0.6, 0.6), 1.5)
	var x := hearts_pos.x + float(_max) * heart_gap
	if player != null and player.shield_hits > 0:
		for i in player.shield_hits:
			var c := Vector2(x + float(i) * 22.0, hearts_pos.y)
			PickupScript.draw_boost_icon(self, c, PickupScript.SHIELD, Color("40e0e8"))
		x += float(player.shield_hits) * 22.0 + 6.0
	# ---- נשק ותחמושת ----
	var wy := hearts_pos.y + 6.0
	if player != null:
		if _weapon == 0:
			var msize: int = Upgrades.wval(player.gun, "magazine_size", 0)
			var low: bool = player.ammo <= 5 or (msize > 0 and player.mag <= maxi(1, msize / 5))
			var at := "%d / %d" % [player.mag, player.ammo - player.mag] if msize > 0 else str(player.ammo)
			_text(Vector2(x, wy), "%s  %s" % [Game.WEAPON_NAMES[player.gun], at], 16, Color("ff6050") if low else Color.WHITE)
			if player.is_reloading():   # בר טעינה
				var k: float = 1.0 - player._reload_t / maxf(player._reload_total, 0.01)
				draw_rect(Rect2(x, wy + 6.0, 120.0, 4.0), Color(0, 0, 0, 0.5))
				draw_rect(Rect2(x, wy + 6.0, 120.0 * k, 4.0), Color(1.0, 0.85, 0.4))
				_text(Vector2(x + 126.0, wy + 12.0), "RELOADING", 11, Color(1.0, 0.85, 0.4, 0.8))
			elif msize > 0 and player.mag == 0 and player.ammo > 0:
				_text(Vector2(x, wy + 16.0), "R  RELOAD", 12, Color(1.0, 0.5, 0.4, 0.6 + 0.4 * sin(_intro_t * 8.0)))
		else:
			var sn: String = str(Arsenal.SPECIALS[player.special].name) if player.special != "" else "NONE"
			_text(Vector2(x, wy), "%s  x%d" % [sn, player.special_uses], 16, Color.WHITE if player.special != "" else Color("ff6050"))
		if _weapon != 0:   # (הפריט עצמו מוצג במשבצת E בבר הנשקים)
			_text(Vector2(x + 210.0, wy), "A %d" % player.ammo, 13, Color(1, 1, 1, 0.6))
	if difficulty != "":
		_text(Vector2(x + 280.0, wy), difficulty, 16, difficulty_color)
	# בר הנשקים מצויר ב-weapon_wheel.gd
	# ---- בוסטים פעילים ----
	if player != null:
		var bx := hearts_pos.x - 10.0
		for b in player.boosts.keys():
			var left: float = player.boosts[b]
			var col: Color = PickupScript.BOOST_COLORS[b]
			draw_rect(Rect2(Vector2(bx, 66), Vector2(30, 30)), Color(0, 0, 0, 0.55))
			draw_rect(Rect2(Vector2(bx, 66), Vector2(30, 30)), col, false, 1.5)
			PickupScript.draw_boost_icon(self, Vector2(bx + 15, 81), b, col)
			var k := clampf(left / (player.GOD_TIME if b == PickupScript.GOD else player.boost_time), 0.0, 1.0)
			draw_rect(Rect2(Vector2(bx, 98), Vector2(30 * k, 3)), col)
			bx += 36.0
	# ---- שלב, ניקוד, קומבו (ימין למעלה) ----
	var rx := vp.x - 20.0
	_text(Vector2(rx - 300, 30), "STAGE %d" % Game.level, 16, Color(0.85, 0.8, 0.75), HORIZONTAL_ALIGNMENT_RIGHT, 300)
	_draw_eye(Vector2(rx - 92.0, 25.0))
	_text(Vector2(rx - 300, 58), "%d" % int(_score_shown), 26, Color.WHITE, HORIZONTAL_ALIGNMENT_RIGHT, 300)
	var m := Game.multiplier()
	if Game.combo > 0:
		var size := int(20 + 10 * _combo_pop)
		var mc := Color("ffd34a") if m > 1 else Color(1, 1, 1, 0.8)
		_text(Vector2(rx - 300, 88), "x%d   COMBO %d" % [m, Game.combo], size, mc, HORIZONTAL_ALIGNMENT_RIGHT, 300)
		var k := clampf(Game.combo_t / Game.COMBO_WINDOW, 0.0, 1.0)
		draw_rect(Rect2(Vector2(rx - 120, 96), Vector2(120, 3)), Color(0, 0, 0, 0.5))
		draw_rect(Rect2(Vector2(rx - 120 * k, 96), Vector2(120 * k, 3)), mc)
	# ---- דירוג סטייל ----
	var sr := Game.style_rank()
	var scol: Color = [Color(0.6, 0.6, 0.6), Color("7ad0ff"), Color("7aff8a"), Color("ffd34a"), Color("ff4a3a")][sr]
	_text(Vector2(rx - 300, 150), Game.STYLE_RANKS[sr], 40, Color(scol, 0.4 + 0.6 * clampf(Game.style / 20.0, 0.0, 1.0)), HORIZONTAL_ALIGNMENT_RIGHT, 300)
	_text(Vector2(rx - 300, 168), "STYLE", 12, Color(1, 1, 1, 0.6), HORIZONTAL_ALIGNMENT_RIGHT, 300)
	var sk := fmod(Game.style, 20.0) / 20.0 if sr < 4 else 1.0
	draw_rect(Rect2(Vector2(rx - 60, 174), Vector2(60, 3)), Color(0, 0, 0, 0.5))
	draw_rect(Rect2(Vector2(rx - 60, 174), Vector2(60 * sk, 3)), scol)
	# ---- בר חיים של הבוס ----
	if player != null:
		for z in get_tree().get_nodes_in_group("zombies"):
			if z.is_boss() and absf(z.global_position.x - player.global_position.x) < 900.0:
				var w := 420.0
				var bp := Vector2((vp.x - w) / 2.0, 140)   # מתחת לשעון
				var bname: String = {7: "THE CONDUCTOR", 19: "THE HOUND"}.get(z.kind, "THE GATEKEEPER")
				if z.type_mod != null:   # בוס חדש (enemies/types): השם מ-stats()["boss_name"]
					bname = str(z.type_mod.stats().get("boss_name", bname))
				_text(Vector2(0, bp.y - 6), bname + ("" if z.kind != 7 or z._transformer == 0 else "   - SHOOT THE TRANSFORMER ON HIS BACK"), 16, Color("ff7060"), HORIZONTAL_ALIGNMENT_CENTER, vp.x)
				draw_rect(Rect2(bp - Vector2(2, 2), Vector2(w + 4, 14)), Color(0, 0, 0, 0.7))
				var k := clampf(float(z.hp) / float(z.max_hp), 0.0, 1.0)
				draw_rect(Rect2(bp, Vector2(w * k, 10)), Color("c0201c"))
				draw_rect(Rect2(bp, Vector2(w * k, 3)), Color(1, 0.5, 0.45, 0.6))
				break
	# ---- GAME OVER ----
	if _game_over:
		draw_rect(Rect2(Vector2.ZERO, vp), Color(0, 0, 0, 0.55))
		_text(Vector2(0, vp.y / 2.0 - 40.0), "GAME OVER", 64, Color("ff4040"), HORIZONTAL_ALIGNMENT_CENTER, vp.x)
		_text(Vector2(0, vp.y / 2.0 + 4.0), "SCORE  %d" % (Game.run_score + Game.level_score), 24, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, vp.x)
		_text(Vector2(0, vp.y / 2.0 + 34.0), "BEST  %d" % Game.high_scores[Settings.difficulty], 18, Color("d8a033"), HORIZONTAL_ALIGNMENT_CENTER, vp.x)
