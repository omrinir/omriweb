extends Node2D
# ============================================================
#  HUD: לבבות, מגן, נשק ותחמושת, בוסטים, ניקוד + קומבו, מספר שלב,
#  בר חיים של הבוס, צבע של BULLET TIME והודעת GAME OVER.
#  נוצר ע"י main.gd בתוך CanvasLayer (לא זז עם המצלמה).
# ============================================================

const Art := preload("res://art.gd")
const PickupScript := preload("res://pickup.gd")

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


func _process(delta: float) -> void:
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


func _text(pos: Vector2, t: String, size: int, col: Color, align := HORIZONTAL_ALIGNMENT_LEFT, width := -1.0) -> void:
	var f := ThemeDB.fallback_font
	draw_string_outline(f, pos, t, align, width, size, 4, Color(0, 0, 0, 0.75))
	draw_string(f, pos, t, align, width, size, col)


func _draw() -> void:
	var vp := get_viewport_rect().size
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
			var low: bool = player.ammo <= 5
			_text(Vector2(x, wy), "%s  %d" % [["RIFLE", "SHOTGUN", "SNIPER", "TASER"][player.gun], player.ammo], 16, Color("ff6050") if low else Color.WHITE)
		else:
			_text(Vector2(x, wy), "GRENADE  x%d" % player.grenades, 16, Color("ff6050") if player.grenades == 0 else Color.WHITE)
		_text(Vector2(x + 160.0, wy), "G x%d" % player.grenades if _weapon == 0 else "A %d" % player.ammo, 13, Color(1, 1, 1, 0.6))
	if difficulty != "":
		_text(Vector2(x + 190.0, wy), difficulty, 16, difficulty_color)
	# ---- בוסטים פעילים ----
	if player != null:
		var bx := hearts_pos.x - 10.0
		for b in player.boosts.keys():
			var left: float = player.boosts[b]
			var col: Color = PickupScript.BOOST_COLORS[b]
			draw_rect(Rect2(Vector2(bx, 66), Vector2(30, 30)), Color(0, 0, 0, 0.55))
			draw_rect(Rect2(Vector2(bx, 66), Vector2(30, 30)), col, false, 1.5)
			PickupScript.draw_boost_icon(self, Vector2(bx + 15, 81), b, col)
			var k := clampf(left / player.boost_time, 0.0, 1.0)
			draw_rect(Rect2(Vector2(bx, 98), Vector2(30 * k, 3)), col)
			bx += 36.0
	# ---- שלב, ניקוד, קומבו (ימין למעלה) ----
	var rx := vp.x - 20.0
	_text(Vector2(rx - 300, 30), "LEVEL %d" % Game.level, 16, Color(0.85, 0.8, 0.75), HORIZONTAL_ALIGNMENT_RIGHT, 300)
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
				var bp := Vector2((vp.x - w) / 2.0, 108)
				_text(Vector2(0, bp.y - 6), ("THE CONDUCTOR" if z.kind == 7 else "THE GATEKEEPER") + ("" if z.kind != 7 or z._transformer == 0 else "   - SHOOT THE TRANSFORMER ON HIS BACK"), 16, Color("ff7060"), HORIZONTAL_ALIGNMENT_CENTER, vp.x)
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
