extends RefCounted
# ============================================================
#  תנועה חלקה במסכים מהירים (physics interpolation).
#  הפיזיקה רצה 60 פעם בשנייה. במסך 120/144Hz יש 2-3 פריימים לכל צעד פיזיקה, אז כל מה שזז
#  ב-_physics_process (השחקן, זומבים, כדורים...) "קפץ" כל 2-3 פריימים והמצלמה גמגמה אחריו.
#  עם physics/common/physics_interpolation (project.godot) Godot מצייר אותם בכל פריים בין שני מיקומי הפיזיקה האחרונים.
#  רק מה שזז ב-_physics_process מוחלק (MOVERS למטה). כל השאר (דברים שזזים ב-_process, ממשק, קישוטים) כבוי:
#  החלון הראשי כבוי (game_state.gd), וגם ילדים של עצם מוחלק כבויים (הם ממילא נעים עם ההורה המוחלק,
#  ואנימציה משלהם ב-_process הייתה מפגרת).
#  המצלמה עוקבת אחרי המיקום המוחלק של השחקן: player.gd -> _process, shake_camera.gd -> follow_smooth.
#  main.gd מחבר את on_node_added ל-SceneTree.node_added.
#  עצם חדש שזז ב-_physics_process? להוסיף את הסקריפט שלו ל-MOVERS.
# ============================================================

const MOVERS := [
	"res://player.gd", "res://zombie.gd", "res://survivor.gd", "res://bullet.gd", "res://grenade.gd",
	"res://weapons/rocket.gd", "res://weapons/molotov.gd", "res://debris.gd", "res://severed_leg.gd",
	"res://blood_drop.gd", "res://acid.gd", "res://pickup.gd",
]

static var _set := {}


static func _build() -> void:
	for path in MOVERS:
		_set[load(path)] = true
	var z: Script = load("res://zombie.gd")
	_set[z.Orb] = true
	_set[z.EnemyShot] = true


static func is_mover(n: Node) -> bool:
	if _set.is_empty():
		_build()
	var s: Script = n.get_script()
	while s != null:
		if _set.has(s):
			return true
		s = s.get_base_script()
	return false


static func on_node_added(n: Node) -> void:
	if not (n is CanvasItem):
		return
	if is_mover(n):
		n.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_ON
		n.reset_physics_interpolation.call_deferred()   # אחרי שמי שיצר אותו קבע לו מיקום - שלא "יימרח" מ-(0,0)
		return
	if n is Light2D:   # אור הוא עצם נפרד ב-RenderingServer עם מיקום עולמי - שיוחלק יחד עם ההורה
		return
	var p := n.get_parent()
	if p != null and p.is_physics_interpolated():
		n.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
