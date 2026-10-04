extends "res://abilities/ability_base.gd"
# ============================================================
#  DECOY ECHO - עותק רפאים של הדמות שעומד ו"יורה" (רעש, בלי נזק).
#  המוחות של הזומבים (ai/zombie_brain.gd) חושבים שזה אתה: תורות התקפה, איגוף ופקודות
#  הולכים אליו. משלב 8 זומבים חכמים לפעמים מזהים את הטריק (adaptation_level).
#  הזומבים מוצאים אותו דרך הקבוצה "decoys" (zombie.gd -> _target_for_brain).
#  POWER: משך + כמה מכות הוא סופג.
# ============================================================


func activate() -> bool:
	for d in player.get_tree().get_nodes_in_group("decoys"):
		d.queue_free()
	var d := Decoy.new()
	d.life = duration()
	d.hits_left = 3 + power
	d.face = player._face()
	player.get_parent().add_child(d)
	d.global_position = player.global_position
	Sfx.play("whoosh", player.global_position, 2.0)
	return true


# ה"שחקן המזויף" - יש לו את מה שזומבים שואלים על שחקן
class Decoy extends Node2D:
	const Sfx := preload("res://sfx.gd")
	var life := 5.0
	var hits_left := 3
	var face := 1.0
	var dead := false
	var velocity := Vector2.ZERO
	var _crouching := false
	var _aim := Vector2.RIGHT
	var grabbed_by: Node = null
	var health := 1
	var gun := 0
	var _t := 0.0
	var _shot := 0.0

	func _ready() -> void:
		add_to_group("decoys")
		z_index = 4
		_aim = Vector2(face, 0)

	func _face() -> float:
		return face

	func is_vulnerable() -> bool:
		return false

	func is_reloading() -> bool:
		return false

	func body_rect() -> Rect2:
		return Rect2(global_position + Vector2(-11, -52), Vector2(22, 52))

	func hurt(_amount: int, _dir: Vector2) -> void:
		hits_left -= 1
		if hits_left <= 0:
			life = 0.0

	func grab(_by: Node) -> void:
		hits_left = 0
		life = 0.0

	func _process(delta: float) -> void:
		_t += delta
		life -= delta
		_shot -= delta
		if life <= 0.0:
			dead = true
			queue_free()
			return
		if _shot <= 0.0:   # "יורה" (רעש) כדי למשוך אותם
			_shot = 0.8
			Game.make_noise(global_position, 420.0)
			Sfx.play("pistol", global_position, -14.0, 0.2, 2)
		queue_redraw()

	func _draw() -> void:
		var a := clampf(life, 0.0, 1.0) * (0.55 + 0.15 * sin(_t * 10.0))
		var col := Color(0.3, 0.8, 1.0, a)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(face, 1))
		draw_colored_polygon(PackedVector2Array([Vector2(-7, 0), Vector2(-9, -30), Vector2(-4, -44), Vector2(5, -44), Vector2(8, -30), Vector2(6, 0)]), col)
		draw_circle(Vector2(0, -48), 6.0, col)
		draw_line(Vector2(2, -34), Vector2(22, -34), col, 3.0)
		if _shot > 0.7:
			draw_circle(Vector2(24, -34), 4.0, Color(0.7, 0.95, 1.0, a))
		draw_set_transform_matrix(Transform2D.IDENTITY)
