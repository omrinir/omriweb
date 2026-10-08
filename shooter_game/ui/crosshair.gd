extends Node2D
# ============================================================
#  CROSSHAIR - כוונת דינמית במקום חץ העכבר (כמו Enter the Gungeon / Nuclear Throne)
#  4 קווים סביב העכבר. הרווח ביניהם = הפיזור האמיתי של הנשק במרחק הזה
#  (רובה צר, שוטגאן רחב, SMG נפתח כשהקנה מטפס). אדום = הירייה תפגע בזומבי.
#  הקו המנוקד מהקנה מצויר ב-player.gd (_draw_aim_guide). L = מחליף מצב (Settings.aim_guide).
#  רץ גם כשהמשחק עצור: מחזיר את חץ העכבר בתפריטים, בגלגל הנשקים ובחנות.
# ============================================================

var player: Node = null
var _shown := false
var _pop := 0.0          # קפיצה קטנה בכל ירייה


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	z_index = 50


func _exit_tree() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _process(delta: float) -> void:
	var show := _active()
	if show != _shown:
		_shown = show
		Input.mouse_mode = Input.MOUSE_MODE_HIDDEN if show else Input.MOUSE_MODE_VISIBLE
	if show and player.get("_muzzle_flash") != null and float(player._muzzle_flash) > 0.0:
		_pop = 1.0
	_pop = maxf(_pop - delta * 6.0, 0.0)
	queue_redraw()


func _active() -> bool:
	if player == null or not is_instance_valid(player) or player.dead or not player.controllable:
		return false
	if get_tree().paused or player.wheel_open or Settings.aim_guide <= 0:
		return false
	return true


func _draw() -> void:
	if not _shown:
		return
	var m := get_viewport().get_mouse_position()
	var cam := get_viewport().get_camera_2d()
	var zoom: float = cam.zoom.x if cam != null else 1.0
	var spread: float = player.aim_spread()
	var dist: float = player.aim_dist
	var gap := clampf(5.0 + tan(spread) * dist * zoom + 4.0 * _pop, 5.0, 90.0)
	var hot: bool = player.aim_on_zombie
	var col := Color(1.0, 0.3, 0.25, 0.95) if hot else Color(0.95, 0.95, 0.9, 0.85)
	var sh := Color(0, 0, 0, 0.55)
	var ln := 7.0
	for d in [Vector2.RIGHT, Vector2.LEFT, Vector2.UP, Vector2.DOWN]:
		var a: Vector2 = m + d * gap
		var b: Vector2 = m + d * (gap + ln)
		draw_line(a + Vector2(1, 1), b + Vector2(1, 1), sh, 2.6)
		draw_line(a, b, col, 2.0)
	draw_circle(m + Vector2(0.6, 0.6), 1.9, sh)
	draw_circle(m, 1.5, col)
	if player.weapon != player.GUN:   # פריט מיוחד (רימון / משגר): עיגול במקום פיזור
		draw_arc(m, 10.0, 0.0, TAU, 20, Color(col, 0.6), 1.2, true)
