extends "res://abilities/ability_base.gd"
# ============================================================
#  SMOKE BOMB - רימון עשן לרגליים (במקום PHANTOM STEP).
#  ענן סמיך: זומבים בתוכו נחנקים (נעצרים לרגע) ומאבדים אותך - המוח שלהם (ai/zombie_brain.gd)
#  זוכר רק נקודה אקראית בענן. כל עוד אתה בתוך הענן, זומבים מבחוץ לא רואים אותך.
#  "הם לא יכולים ללמוד את מה שהם לא רואים". POWER: רדיוס + משך.
# ============================================================
const RADIUS := 170.0
const TICK := 0.3

var _cloud: Node2D = null
var _left := 0.0
var _tick := 0.0


func radius() -> float:
	return RADIUS + 22.0 * float(power)


func activate() -> bool:
	_left = duration()
	if _cloud != null and is_instance_valid(_cloud):
		_cloud.queue_free()
	_cloud = Cloud.new()
	_cloud.r = radius()
	_cloud.life = _left
	player.get_parent().add_child(_cloud)
	_cloud.global_position = player.global_position + Vector2(0, -30)
	Sfx.play("whoosh", player.global_position, 4.0)
	Sfx.play("fire_whoosh", player.global_position, -6.0, 0.1, 2, 1.6)   # שששש של עשן
	for z in zombies_near(_cloud.global_position, radius()):   # נחנקים
		z.stagger(0.6 + 0.1 * float(power))
	_blind(true)
	return true


func active() -> bool:
	return _left > 0.0


func process(delta: float) -> void:
	if _left <= 0.0:
		return
	_left -= delta
	_tick -= delta
	if _tick <= 0.0:
		_tick = TICK
		_blind(false)


# זומבים בענן מאבדים אותך; אם אתה בתוך הענן - גם אלה שמבחוץ
func _blind(first: bool) -> void:
	if _cloud == null or not is_instance_valid(_cloud):
		return
	var c: Vector2 = _cloud.global_position
	var inside: bool = player.global_position.distance_to(c + Vector2(0, 30)) < radius()
	for z in player.get_tree().get_nodes_in_group("zombies"):
		if z.dead or z.brain == null or z.is_boss():
			continue
		var d: float = z.global_position.distance_to(c)
		if d < radius() or (inside and d < 900.0):
			z.brain.sees = false
			z.brain.last_seen = c + Vector2(randf_range(-radius(), radius()) * 0.7, 30.0)
			z.brain.seen_t = 0.5
			if first and d < radius():
				Game.story.emit("smoke", {})


class Cloud extends Node2D:
	const Art := preload("res://art.gd")
	var r := 170.0
	var life := 5.0
	var _t := 0.0
	var _puffs := []   # [מיקום, גודל, שלב]

	func _ready() -> void:
		z_index = 12
		for i in 16:
			var a := randf() * TAU
			var d := sqrt(randf()) * r * 0.75
			_puffs.append([Vector2(cos(a) * d, sin(a) * d * 0.55), randf_range(0.45, 0.8) * r * 0.55, randf() * TAU])

	func _process(delta: float) -> void:
		_t += delta
		if _t > life + 1.2:
			queue_free()
			return
		if Art.on_screen(self, global_position):
			queue_redraw()

	func _draw() -> void:
		var grow := clampf(_t / 0.45, 0.0, 1.0)
		var fade := clampf((life + 1.2 - _t) / 1.2, 0.0, 1.0)
		for p in _puffs:
			var pos: Vector2 = p[0] * (0.4 + 0.6 * grow) + Vector2(sin(_t * 0.7 + p[2]) * 8.0, -_t * 6.0)
			var rr: float = p[1] * (0.5 + 0.5 * grow) * (1.0 + 0.04 * sin(_t * 1.3 + p[2]))
			draw_circle(pos, rr, Color(0.62, 0.65, 0.68, 0.16 * fade))
			draw_circle(pos + Vector2(-rr * 0.2, -rr * 0.2), rr * 0.6, Color(0.78, 0.8, 0.82, 0.12 * fade))
