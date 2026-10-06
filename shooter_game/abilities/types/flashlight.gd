extends "res://abilities/ability_base.gd"
# ============================================================
#  FLASHLIGHT - פנס. C = מדליק, C שוב = מכבה.
#  אור טבעי (לא קונוס): "בריכת" אור רכה וחמימה שנמשכת קדימה לכיוון הכוונת + הילה עדינה סביב הדמות,
#  בלי קצוות חדים. הפנס רועד קצת ביד ומתעדכן באיחור קטן אחרי הכוונת (כמו יד אמיתית).
#  מאיר באמת את החושך: השכבות החשוכות (subway.gd, s11 NightOverlay, s14 StormOverlay) קוראות
#  לכל מי שבקבוצה "dyn_lights" -> lights(). בשלבי יום הוא מוסיף רק זוהר חמים עדין.
#  מחיר: עם פנס דולק הזומבים רואים אותך (Game.player_dark = false).
#  זמן: TIME לפי רמת POWER (50 שניות -> 2 דקות). FLICKER_T שניות לפני הסוף הוא מתחיל להבהב ולהיחלש.
#  ה-cooldown מתחיל כשהפנס כבה (ability_db: "cd_after").
# ============================================================

const TIME := [50.0, 64.0, 78.0, 92.0, 106.0, 120.0]   # שניות לפי רמת POWER (0-5). מקסימום 2 דקות
const FLICKER_T := 4.0                               # כמה שניות לפני הסוף מתחיל להבהב

var on := false
var left := 0.0
var lit_time := 0.0          # לבדיקות: כמה זמן דלק
var beam: Node2D = null
var _t := 0.0
var _blink := 0.0
var _next_blink := 0.0


func duration() -> float:
	return TIME[clampi(power, 0, TIME.size() - 1)]


func activate() -> bool:
	if on:
		return false
	on = true
	left = duration()
	_next_blink = 0.0
	_blink = 0.0
	if beam == null or not is_instance_valid(beam):
		beam = Beam.new()
		beam.ability = self
		player.get_parent().add_child(beam)
	Sfx.play("empty", player.global_position, -8.0, 0.05, 2)   # קליק של מתג
	return true


func stop() -> void:
	if not on:
		return
	on = false
	left = 0.0
	if player != null:
		Sfx.play("empty", player.global_position, -10.0, 0.05, 2)


func active() -> bool:
	return on


func cooldown_scale() -> float:
	return clampf(1.0 - left / maxf(duration(), 0.01), 0.35, 1.0)


func on_level_start() -> void:
	on = false
	beam = null


func process(delta: float) -> void:
	_t += delta
	if not on:
		return
	if player == null or player.dead:
		stop()
		return
	left -= delta
	lit_time += delta
	if left <= FLICKER_T:   # הסוללה נגמרת: הבהובים שמתגברים
		var k := 1.0 - clampf(left / FLICKER_T, 0.0, 1.0)
		_blink -= delta
		_next_blink -= delta
		if _next_blink <= 0.0:
			_blink = randf_range(0.04, 0.09 + 0.12 * k)
			_next_blink = _blink + lerpf(0.55, 0.07, k) * randf_range(0.6, 1.3)
			if randf() < 0.4:
				Sfx.play("empty", player.global_position, -22.0, 0.3, 1)   # זמזום חלש של מגע רופף
	if left <= 0.0:
		player._say("BATTERY DEAD", Color("ffe0a0"))
		stop()


# 0..1 עוצמת האור עכשיו
func intensity() -> float:
	if not on:
		return 0.0
	var breathe := 0.97 + 0.03 * sin(_t * 2.3) * sin(_t * 0.7 + 1.0)   # תנודה טבעית קטנה
	if left > FLICKER_T:
		return breathe
	var k := 1.0 - clampf(left / FLICKER_T, 0.0, 1.0)
	if _blink > 0.0:
		return 0.08 + 0.1 * randf()
	if left < 0.35:   # רגע לפני שכבה: גמגום מהיר
		return 0.15 if int(_t * 22.0) % 2 == 0 else 0.7
	return breathe * (1.0 - 0.35 * k)


# ============================================================
#  האור עצמו (בעולם). מקור = הכתף/הנשק, כיוון = הכוונת (עם איחור ורעד קטן)
# ============================================================
class Beam extends Node2D:
	var ability = null
	var _dir := Vector2.RIGHT
	var _origin := Vector2.ZERO
	var _t := 0.0
	var _i := 0.0
	static var _tex: GradientTexture2D = null

	func _ready() -> void:
		add_to_group("dyn_lights")
		z_index = 6
		top_level = true
		var mat := CanvasItemMaterial.new()
		mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		material = mat

	static func tex() -> GradientTexture2D:
		if _tex == null:
			var g := Gradient.new()   # נפילה רכה (כמעט אינברס-ריבועית), בלי קצה
			g.offsets = PackedFloat32Array([0.0, 0.22, 0.5, 0.78, 1.0])
			g.colors = PackedColorArray([Color(1, 1, 1, 1.0), Color(1, 1, 1, 0.72), Color(1, 1, 1, 0.32), Color(1, 1, 1, 0.08), Color(1, 1, 1, 0.0)])
			_tex = GradientTexture2D.new()
			_tex.gradient = g
			_tex.fill = GradientTexture2D.FILL_RADIAL
			_tex.fill_from = Vector2(0.5, 0.5)
			_tex.fill_to = Vector2(1.0, 0.5)
			_tex.width = 256
			_tex.height = 256
		return _tex

	func _process(delta: float) -> void:
		_t += delta
		if ability == null or ability.player == null or not is_instance_valid(ability.player):
			queue_free()
			return
		var p = ability.player
		_i = ability.intensity()
		var want: Vector2 = p._aim if p._aim.length() > 0.1 else Vector2(p._face(), 0.0)
		_dir = _dir.slerp(want.normalized(), clampf(delta * 9.0, 0.0, 1.0)).normalized()   # היד מגיבה באיחור קטן
		var sway := Vector2(sin(_t * 1.7), sin(_t * 2.3 + 0.8)) * 2.0   # רעד קטן של היד
		_origin = p.global_position + p._front_shoulder() + _dir * 16.0 + sway
		global_position = Vector2.ZERO
		queue_redraw()

	# לשכבות החושך: [מיקום בעולם, רדיוס, עוצמה]. שלוש נקודות חופפות = צורת "טיפה" רכה לכיוון הכוונת
	func lights() -> Array:
		if _i <= 0.01:
			return []
		return [[_origin + _dir * 150.0, 250.0, 0.95 * _i], [_origin + _dir * 55.0, 175.0, 0.9 * _i], [_origin - _dir * 10.0, 115.0, 0.65 * _i]]

	func _draw() -> void:
		if _i <= 0.01:
			return
		var t := tex()
		var warm := Color(1.0, 0.92, 0.76)
		var ang := _dir.angle()
		# בריכת האור הרחוקה (אליפסה רכה לאורך הכוונת)
		draw_set_transform(_origin + _dir * 150.0, ang, Vector2(1.35, 0.95))
		draw_texture_rect(t, Rect2(-250, -250, 500, 500), false, Color(warm, 0.17 * _i))
		# האור הקרוב (חזק יותר)
		draw_set_transform(_origin + _dir * 55.0, ang, Vector2(1.2, 1.0))
		draw_texture_rect(t, Rect2(-160, -160, 320, 320), false, Color(warm, 0.16 * _i))
		# הילה סביב הדמות + נקודה חמה בפנס עצמו
		draw_set_transform(_origin, 0.0, Vector2.ONE)
		draw_texture_rect(t, Rect2(-90, -90, 180, 180), false, Color(warm, 0.1 * _i))
		draw_texture_rect(t, Rect2(-9, -9, 18, 18), false, Color(1.0, 0.97, 0.88, 0.9 * _i))
		draw_set_transform_matrix(Transform2D.IDENTITY)
