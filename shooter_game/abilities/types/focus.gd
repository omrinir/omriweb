extends "res://abilities/ability_base.gd"
# ============================================================
#  FOCUS - הזמן מאט סביבך (במקום SILENCE). אתה זז ויורה במהירות רגילה
#  (player.gd מפצה על Engine.time_scale), והמחסנית מתמלאת. משתמש בבוסט BULLET TIME
#  (שורת הבוסטים ב-HUD מראה את הזמן שנשאר). POWER: משך.
# ============================================================
const PickupScript := preload("res://pickup.gd")
const Upgrades := preload("res://progression/upgrade_db.gd")
const SCALE := 0.35   # כמה איטי העולם

var _ov: CanvasLayer = null


func activate() -> bool:
	var d := duration()
	player.boosts[PickupScript.BULLET_TIME] = maxf(float(player.boosts.get(PickupScript.BULLET_TIME, 0.0)), d)
	Engine.time_scale = SCALE
	if player.weapon == 0:   # GUN: המחסנית מתמלאת
		var msize := int(Upgrades.wval(player.gun, "magazine_size", 0))
		if msize > 0:
			player.mag = mini(msize, player.ammo)
			player._reload_t = 0.0
	Sfx.play("boost", null, 0.0, 0.0, 2, 0.5)
	Sfx.play("heal", null, -8.0, 0.0, 2, 0.5)
	if _ov == null or not is_instance_valid(_ov):
		_ov = Tint.new()
		player.get_parent().add_child(_ov)
	return true


func active() -> bool:
	return player != null and player.boosts.has(PickupScript.BULLET_TIME)


func process(_delta: float) -> void:
	if _ov != null and is_instance_valid(_ov):
		_ov.on = active()


# גוון כחלחל וקצוות כהים כל עוד הזמן איטי
class Tint extends CanvasLayer:
	var on := true
	var _k := 0.0
	var _c: Control

	func _ready() -> void:
		layer = 4
		_c = Control.new()
		_c.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_c.set_anchors_preset(Control.PRESET_FULL_RECT)
		add_child(_c)
		_c.draw.connect(_draw_tint)

	func _process(delta: float) -> void:
		var real := delta / maxf(Engine.time_scale, 0.05)
		_k = move_toward(_k, 1.0 if on else 0.0, real * 4.0)
		_c.queue_redraw()

	func _draw_tint() -> void:
		if _k <= 0.0:
			return
		var vs := _c.get_viewport_rect().size
		_c.draw_rect(Rect2(Vector2.ZERO, vs), Color(0.35, 0.55, 1.0, 0.07 * _k))
		for i in 6:   # קצוות כהים
			var m := 18.0 * float(i)
			_c.draw_rect(Rect2(Vector2(m, m), vs - Vector2(m, m) * 2.0), Color(0.02, 0.04, 0.12, 0.05 * _k), false, 18.0)
