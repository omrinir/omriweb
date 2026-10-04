extends Node2D
# ============================================================
#  LADDER - סולם בין קומות. השחקן עומד עליו ולוחץ W (למעלה) / S (למטה).
#  SPACE = קופץ מהסולם. position = תחתית הסולם, height = גובה.
# ============================================================
var height := 160.0
var color := Color("6a6e74")


func _ready() -> void:
	add_to_group("ladders")
	z_index = 0


func world_rect() -> Rect2:
	return Rect2(global_position + Vector2(-12.0, -height - 8.0), Vector2(24.0, height + 8.0))


func top_y() -> float:
	return global_position.y - height


func _draw() -> void:
	draw_line(Vector2(-9, 0), Vector2(-9, -height - 10.0), color, 2.5)
	draw_line(Vector2(9, 0), Vector2(9, -height - 10.0), color, 2.5)
	var y := -10.0
	while y > -height - 4.0:
		draw_line(Vector2(-9, y), Vector2(9, y), color.darkened(0.15), 2.0)
		y -= 16.0
