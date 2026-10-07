extends Node2D
# ============================================================
#  CHECKPOINT - עמוד עם דגל באמצע השלב (main.gd מניח אותו ב-CHECKPOINT_AT).
#  השחקן עובר אותו -> הדגל עולה ונצבע ירוק, "CHECKPOINT · SAVED", ו-Game.reach_checkpoint שומר לקובץ:
#  המיקום, הנשקים, התחמושת והרימונים. מתים אחרי זה -> TRY AGAIN מתחיל מכאן עם מה שהיה לך כאן.
# ============================================================

const Art := preload("res://art.gd")
const Sfx := preload("res://sfx.gd")

var reached := false
var _raise := 0.0            # 0 = הדגל למטה, 1 = למעלה
var _t := 0.0


func _ready() -> void:
	z_index = -1
	add_to_group("checkpoints")


func set_reached() -> void:   # מתחילים ממנה (TRY AGAIN / CONTINUE)
	reached = true
	_raise = 1.0
	queue_redraw()


func _process(delta: float) -> void:
	_t += delta
	if not reached:
		var pl := get_tree().get_first_node_in_group("player") as Node2D
		if pl != null and not pl.dead and pl.global_position.x >= global_position.x:
			reached = true
			Game.reach_checkpoint(global_position.x, pl)
			Sfx.play("pickup", null, 2.0)
			if pl.has_method("_say"):
				pl._say("CHECKPOINT  ·  SAVED", Color("7ee08a"))
	if reached and _raise < 1.0:
		_raise = minf(_raise + delta * 2.0, 1.0)
	if Art.on_screen(self, global_position):
		queue_redraw()


func _draw() -> void:
	var h := 110.0
	draw_line(Vector2(0, 0), Vector2(0, -h), Color("2a2a2e"), 4.0)   # עמוד
	draw_line(Vector2(-1, 0), Vector2(-1, -h), Color("6a6a72"), 1.5)
	draw_circle(Vector2(0, -h), 3.5, Color("c8c8d0"))
	draw_rect(Rect2(-12, -4, 24, 4), Color("2a2a2e"))   # בסיס
	var top := -h + 6.0 + (1.0 - _raise) * (h - 30.0)
	var col := Color("3ec05a") if reached else Color("8a8a90")
	var wave := sin(_t * 5.0) * 3.0
	var flag := PackedVector2Array([Vector2(2, top), Vector2(40, top + 4.0 + wave), Vector2(36, top + 13.0 + wave * 0.5), Vector2(40, top + 22.0 + wave), Vector2(2, top + 22.0)])
	Art.fill(self, flag, col, Art.OUTLINE, 1.4)
	if reached:   # וי לבן על הדגל
		draw_polyline(PackedVector2Array([Vector2(12, top + 11.0), Vector2(17, top + 16.0), Vector2(27, top + 6.0)]), Color.WHITE, 2.2)
