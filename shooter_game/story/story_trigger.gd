extends Node2D
# ============================================================
#  STORY TRIGGER - מניח את הדמות של סצנת סיפור בשלב (main.gd, לפי story/story_db.gd),
#  מפנה את הדרך אליה (מכוניות / ארגזים / לבנים קטנות בין נקודת העצירה לדמות), והשחקן הולך אליה בעצמו.
#  כשהשחקן מגיע ל-"spot" פיקסלים ממנה (ועומד על הרצפה) - מתחילה הסצנה (story/story_scene.gd).
#  אם השחקן כבר עבר את המקום (התחיל מנקודת ביקורת) - אין סצנה.
# ============================================================

const Registry := preload("res://enemies/zombie_registry.gd")
const SceneScript := preload("res://story/story_scene.gd")

var data: Dictionary = {}
var main: Node = null
var hud_layer: CanvasLayer = null
var actor: Node2D = null
var _checked := false
var _started := false
var _placed := false   # הדמות כבר הונחה (_setup)


func _ready() -> void:
	call_deferred("_setup")   # אחרי שהשלב סיים להיבנות


func _setup() -> void:
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player == null:
		queue_free()
		return
	var x: float = float(data.x)
	var floor_y: float = player.global_position.y
	global_position = Vector2(x, floor_y)
	var kind: int = int((Registry as Script).get_script_constant_map().get(String(data.actor), 0))
	actor = main._spawn_zombie(x, floor_y, kind)
	actor.dormant = false
	actor._dir = -1.0
	actor.remove_from_group("zombies")   # לא מטרה, לא נספר, אי אפשר לפגוע בו
	actor.collision_layer = 0
	_placed = true
	# מפנים את הדרך: מהמקום שבו השחקן עוצר ועד מעבר לדמות
	var x0: float = x - float(data.get("spot", 560.0)) - 40.0
	var x1: float = x + 140.0
	for n in main.get_children():
		if not (n is Node2D) or n == actor or n == player:
			continue
		var nx: float = (n as Node2D).global_position.x
		if nx < x0 or nx > x1:
			continue
		var scr: String = n.get_script().resource_path if n.get_script() != null else ""
		if n.is_in_group("pickups"):   # מה שהיה שם - מחכה אחרי הדמות
			n.global_position.x = x1 + 60.0
		elif scr.ends_with("prop.gd") or scr.ends_with("street_prop.gd") or scr.ends_with("fire.gd") or n.is_in_group("cover") \
				or (scr.ends_with("brick.gd") and float(n.size.x) <= 300.0):
			n.queue_free()


func _process(delta: float) -> void:
	if not _placed:
		return
	if not is_instance_valid(actor):   # הסצנה נגמרה (הדמות נעלמה)
		queue_free()
		return
	actor.type_mod.t += delta   # עומד וזז קצת (נושם / מסתכל) גם לפני הסצנה
	actor._time += delta
	actor.queue_redraw()
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player == null or player.dead:
		return
	var dx: float = actor.global_position.x - player.global_position.x
	if not _checked:   # התחיל אחרי המקום (נקודת ביקורת) - אין סצנה
		_checked = true
		if dx < float(data.get("spot", 560.0)) * 0.5:
			actor.queue_free()
			queue_free()
			return
	if not _started and dx <= float(data.get("spot", 560.0)) and player.is_on_floor() and player.controllable and player.grabbed_by == null:
		_started = true   # ממשיכים להנפיש את הדמות עד שהסצנה מעלימה אותה
		var sc = SceneScript.new()
		sc.data = data
		sc.main = main
		sc.player = player
		sc.actor = actor
		sc.hud_layer = hud_layer
		main.add_child(sc)
