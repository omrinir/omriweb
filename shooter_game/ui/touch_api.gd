extends RefCounted
# ============================================================
#  TOUCH API - גישה לשליטה במגע (ui/touch_controls.gd) מכל סקריפט.
#  לא תלוי ב-autoload "Touch" שב-project.godot: אם הוא חסר (למשל project.godot ישן / שנשמר מחדש
#  ע"י העורך) - יוצרים את השכבה בעצמנו ומוסיפים אותה ל-root.
#  שימוש:  const TouchAPI := preload("res://ui/touch_api.gd")
#          if TouchAPI.on(): ... TouchAPI.node().fire / .run / .aim_point(...)
# ============================================================

static var _node: Node = null


static func node() -> Node:
	if _node != null and is_instance_valid(_node):
		return _node
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return null
	_node = tree.root.get_node_or_null("Touch")
	if _node == null:
		_node = load("res://ui/touch_controls.gd").new()
		_node.name = "Touch"
		tree.root.add_child.call_deferred(_node)
	return _node


static func on() -> bool:
	var n := node()
	return n != null and n.on
