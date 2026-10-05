extends "res://abilities/ability_base.gd"
# ============================================================
#  JETPACK - ג'טפאק על הגב. C = מדליק (קפיצת המראה), C שוב = מכבה.
#  בזמן טיסה: W / רווח = דחף למעלה, בלי = ריחוף איטי למטה, A/D = תנועה, יורים כרגיל.
#  הדלק נשרף רק באוויר (על הקרקע / קומה הוא נשמר). נגמר הדלק = הג'טפאק כבה.
#  זמן הטיסה לפי רמת POWER: FUEL (20 -> 32 שניות, כל שדרוג מוסיף פחות). ה-cooldown מתחיל
#  כשהטיסה נגמרת (ability_db: "cd_after"); כיבוי מוקדם = cooldown קצר יותר לפי הדלק שנשאר.
#  לשנות: FUEL, THRUST_SPEED, HOVER_FALL.
# ============================================================

const FUEL := [20.0, 24.0, 27.0, 29.0, 31.0, 32.0]   # שניות טיסה לפי רמת POWER (0-5). מקסימום 32
const THRUST_SPEED := -300.0    # מהירות עלייה מקסימלית
const THRUST_ACCEL := 2400.0
const HOVER_FALL := 150.0       # בלי דחף: נופל לאט
const CEILING := 200.0          # הכי גבוה שאפשר לעוף (y בעולם) - מתחת ללבבות וללוח הנשקים

var fuel := 0.0
var on := false
var thrusting := false
var flown := 0.0                # לבדיקות: כמה שניות באוויר
var _snd_t := 0.0
var _t := 0.0


func duration() -> float:
	return FUEL[clampi(power, 0, FUEL.size() - 1)]


func activate() -> bool:
	if on:
		return false
	on = true
	Game.story.emit("jetpack", {})
	fuel = duration()
	player.jetpack = self
	if player.is_on_floor():
		player.velocity.y = -360.0   # המראה
	Sfx.play("jet", player.global_position, 2.0)
	Particles.burst(player.get_parent(), player.global_position, "smoke", Vector2.DOWN, 10)
	return true


# C בזמן טיסה = כיבוי
func stop() -> void:
	if not on:
		return
	on = false
	thrusting = false
	if player != null and player.jetpack == self:
		player.jetpack = null
	Sfx.play("whoosh", player.global_position, -4.0)


func active() -> bool:
	return on


# כמה מה-cooldown להפעיל (כיבוי מוקדם עם הרבה דלק = מחכים פחות)
func cooldown_scale() -> float:
	return clampf(1.0 - fuel / maxf(duration(), 0.01), 0.35, 1.0)


func on_level_start() -> void:
	on = false


func process(delta: float) -> void:
	_t += delta
	if on and (player == null or player.dead):
		stop()


# נקרא מ-player.gd לפני התנועה (אחרי כוח המשיכה). שולט במהירות האנכית
func fly(delta: float) -> void:
	if player.is_on_floor() and player.velocity.y >= 0.0:
		thrusting = false
		return
	var want_up: bool = player.controllable and (Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_SPACE))
	thrusting = want_up
	player._air_jumps = 0   # בזמן טיסה אין קפיצה כפולה (הדחף מחליף אותה)
	fuel -= delta
	flown += delta
	if want_up:
		player.velocity.y = move_toward(player.velocity.y, THRUST_SPEED, THRUST_ACCEL * delta)
	else:
		player.velocity.y = minf(player.velocity.y, HOVER_FALL)
	if player.global_position.y < CEILING and player.velocity.y < 0.0:   # לא עפים מעל המסך
		player.velocity.y = move_toward(player.velocity.y, 0.0, 3000.0 * delta)
	_snd_t -= delta
	if _snd_t <= 0.0:
		_snd_t = 0.22 if want_up else 0.45
		Sfx.play("jet", player.global_position, -8.0 if want_up else -14.0, 0.15, 2)
	if want_up and randf() < delta * 30.0:
		Particles.burst(player.get_parent(), player.global_position + Vector2(-float(player._face()) * 9.0, -12.0), "fire", Vector2.DOWN, 2)
	if fuel <= 0.0:
		fuel = 0.0
		player._say("OUT OF FUEL", Color("ff9a3a"))
		stop()


# ציור על הגב (קואורדינטות מקומיות של השחקן, פונה ימינה). נקרא לפני ציור הגוף = מאחוריו
func draw_pack(ci: CanvasItem) -> void:
	var b := Vector2(-11.0, -34.0)
	Art.fill_shaded(ci, PackedVector2Array([b + Vector2(-5, 0), b + Vector2(4, 0), b + Vector2(5, 20), b + Vector2(-6, 20)]), Color("5a5e66"), 0.25, 0.35)
	for x: float in [-4.0, 2.0]:   # שני מכלים + נחירים
		Art.oval_shaded(ci, b + Vector2(x, 7), 3.0, 8.0, Color("8a3a2a"))
		Art.fill(ci, PackedVector2Array([b + Vector2(x - 2.5, 19), b + Vector2(x + 2.5, 19), b + Vector2(x + 3.5, 24), b + Vector2(x - 3.5, 24)]), Color("2a2a2e"))
	ci.draw_line(b + Vector2(4, 3), b + Vector2(12, 4), Color("2a2a2e"), 2.0)   # רצועה
	var k := fuel / maxf(duration(), 0.01)
	ci.draw_rect(Rect2(b.x - 7.0, b.y + 2.0, 2.0, 16.0), Color(0, 0, 0, 0.6))   # מד דלק על הצד
	ci.draw_rect(Rect2(b.x - 7.0, b.y + 18.0 - 16.0 * k, 2.0, 16.0 * k), Color(1.0, 0.75, 0.2) if k > 0.25 else Color(1.0, 0.3, 0.2))
	if player.is_on_floor() and not thrusting:
		return
	for x: float in [-4.0, 2.0]:   # להבות
		var len := (16.0 if thrusting else 7.0) + sin(_t * 60.0 + x) * 3.0
		var tip := b + Vector2(x, 24.0 + len)
		ci.draw_colored_polygon(PackedVector2Array([b + Vector2(x - 3, 24), b + Vector2(x + 3, 24), tip]), Color(1.0, 0.55, 0.15, 0.85))
		ci.draw_colored_polygon(PackedVector2Array([b + Vector2(x - 1.5, 24), b + Vector2(x + 1.5, 24), b + Vector2(x, 24.0 + len * 0.55)]), Color(1.0, 0.95, 0.6))
		Art.glow(ci, b + Vector2(x, 28), 8.0 if thrusting else 5.0, Color(1.0, 0.6, 0.2, 0.5))
