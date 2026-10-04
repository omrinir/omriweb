extends Node2D
# ============================================================
#  HAZARD - בסיס לכל המלכודות / סכנות בסביבה (אש, חומצה, אדים, מכבש, חשמל...)
#
#  * כל hazard נמצא בקבוצה "hazards".
#  * זומבים חכמים (ai/zombie_brain.gd) שואלים danger_at() כדי לא להיכנס לסכנה
#    ("avoid obvious traps"), וזומבי מהנדס (ENGINEER) קורא ל-trigger() כדי להפעיל
#    מלכודת כשהשחקן לידה ("use environmental hazards").
#  * כדי ליצור סכנה חדשה: יורשים מהקובץ הזה (extends "res://environment/hazard.gd"),
#    קובעים rect (מלבן מקומי), ומממשים _hazard_tick(delta) / _draw().
# ============================================================

var rect := Rect2(-20, -20, 40, 20)   # אזור הסכנה (יחסית ל-position)
var active := true                     # פעיל כרגע?
var triggerable := false               # מהנדס יכול להפעיל אותו
var player_damage := 1                 # נזק לשחקן בכל "פגיעה"
var zombie_burn := 0.0                 # מצית זומבים שנכנסים (שניות)
var zombie_damage := 0                 # נזק ישיר לזומבים בכל tick
var tick := 0.5                        # כל כמה שניות פוגע
var life := -1.0                       # -1 = לתמיד
var _tick_t := 0.0


func _ready() -> void:
	add_to_group("hazards")


func world_rect() -> Rect2:
	return Rect2(global_position + rect.position, rect.size)


# האם הנקודה בתוך הסכנה (margin = כמה רחוק להיזהר)
func danger_at(p: Vector2, margin := 0.0) -> bool:
	return active and world_rect().grow(margin).has_point(p)


# מהנדס / מנגנון מפעיל את הסכנה
func trigger() -> void:
	active = true


func _physics_process(delta: float) -> void:
	if life > 0.0:
		life -= delta
		if life <= 0.0:
			queue_free()
			return
	_hazard_tick(delta)
	if not active:
		return
	_tick_t -= delta
	if _tick_t > 0.0:
		return
	_tick_t = tick
	var r := world_rect()
	var p := get_tree().get_first_node_in_group("player")
	if p != null and not p.dead and player_damage > 0 and r.intersects(p.body_rect()):
		p.hurt(player_damage, Vector2(signf(p.global_position.x - r.get_center().x), 0.0))
	if zombie_burn > 0.0 or zombie_damage > 0:
		for z in get_tree().get_nodes_in_group("zombies"):
			if z.dead or not r.has_point(z.global_position + Vector2(0, -10)):
				continue
			if zombie_burn > 0.0:
				z.ignite(zombie_burn)
			if zombie_damage > 0:
				z.take_damage(zombie_damage, z.global_position + Vector2(0, -20), Vector2.UP, true, {"source": "hazard"})


# לשימוש בירושה (אנימציה, הפעלה/כיבוי מחזורי...)
func _hazard_tick(_delta: float) -> void:
	pass
