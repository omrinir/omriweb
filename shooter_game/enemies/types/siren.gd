extends "res://enemies/zombie_type.gd"
# ============================================================
#  SIREN (שלב 8 - ה-SCREAMER של השלב) - חוקרת לשעבר שהפכה ל"משדר".
#  צללית: גבוהה ורזה, מרחפת מעט מעל הרצפה (בלי רגליים נראות - חלוק מעבדה קרוע כמו שמלה),
#         שיער ארוך שצף למעלה כמו במים, שק גרון סגול-ורוד זוהר שפועם, עיניים לבנות.
#  תנועה: גולשת בשקט, שומרת מרחק (~400) ונסוגה כשמתקרבים (אבל לאט יותר מהשחקן - אפשר לתפוס).
#  התנהגות: כל כמה שניות היא "שרה": עוצרת, פורשת ידיים, טבעות קול יוצאות מהגרון (1.4 שנ').
#    בסוף השיר: כל הזומבים בטווח שומעים איפה אתה, ומגיעה תגבורת מחוץ למסך.
#    ככל שהיא חיה יותר זמן - השירים תכופים יותר והקבוצה גדלה (1 -> 2 -> 3 זומבים בכל פעם).
#    מגבלות קשיחות: MAX_TOTAL לכל סירנה, MAX_ALIVE תגבורת חיה בבת אחת (לכל הסירנות יחד).
#    פגיעה בזמן השיר = השיר נקטע (חלון ברור להגיב).
#  שונה מה-SCREAMER (סוג 4) שצורח פעם אחת: היא קריאה מתמשכת שגדלה עם הזמן.
#  התקפה: כמעט לא תוקפת (שריטה חלשה רק כשנלכדה).
#  צליל: "siren_song" (יללה גבוהה עם ויברטו), "siren_call" (פעימה נמוכה כשהתגבורת יוצאת).
# ============================================================

const Registry := preload("res://enemies/zombie_registry.gd")
const SOUNDS := {
	"siren_song": {"drive": 2.0, "rev": 0.3, "layers": [["V", 520, 760, 0.0, 1.3, 0.15, 0.6, 0.7, 1.0, 0.09, 0, [900, 2600, 6]], ["S", 1040, 1520, 0.1, 1.1, 0.2, 1.0, 0.12, 1.0, 0.08]]},
	"siren_call": {"drive": 2.2, "layers": [["V", 180, 120, 0.0, 0.6, 0.02, 3.0, 0.8, 1.0, 0.05, 0, [600, 1300, 18]], ["S", 90, 60, 0.0, 0.5, 0.0, 5.0, 0.5, 1.0, 0]]},
}

const MAX_TOTAL := 7           # כמה תגבורת סירנה אחת יכולה להביא בסך הכל
const MAX_ALIVE := 8           # כמה זומבי-תגבורת חיים בבת אחת (כל הסירנות)
const SONG_TIME := 1.4
const GROUP := "s8_siren_spawn"

var _alive_t := 0.0            # כמה זמן היא "פעילה" (רואה / רודפת)
var _song_cd := 4.0
var _song_t := 0.0
var _stagger := 0.0
var _side := 1.0
var summoned := 0              # לבדיקות: כמה תגבורת הביאה
var songs := 0


func stats() -> Dictionary:
	return {"name": "SIREN", "hp": 24, "walk": 40.0, "chase": 88.0, "damage": 1, "bite_delay": 1.2, "scale": 1.1, "width": 0.75,
		"duck": 0.1, "cover": 0.6, "skin": Color("c4bcd6"), "shirt": Color("dfe3e6"), "pants": Color("40384a"), "shoe": Color(0, 0, 0, 0), "points": 350}


func brain_overrides() -> Dictionary:
	return {"keep_range": 400.0, "aggression": -0.4, "communication": 1}


func use_brain_movement() -> bool:
	return false


func can_bite() -> bool:
	return _song_t <= 0.0


func wave_size() -> int:
	return clampi(1 + int(_alive_t / 18.0), 1, 3)


func song_period() -> float:
	return maxf(4.0, 8.0 - _alive_t / 25.0)


func logic(pl: Node, d: Vector2, delta: float, speed: float) -> float:
	_alive_t += delta
	_stagger -= delta
	var dist := absf(d.x)
	var toward: float = signf(d.x) if d.x != 0.0 else z._dir
	z._dir = toward
	if _stagger > 0.0:
		return 0.0
	if _song_t > 0.0:   # שרה: עומדת במקום
		_song_t -= delta
		if _song_t <= 0.0:
			_call(pl)
		return 0.0
	_song_cd -= delta
	if _song_cd <= 0.0 and dist < 900.0:
		_song_t = SONG_TIME
		_song_cd = song_period()
		songs += 1
		Sfx.play("siren_song", z.global_position, 2.0, 0.05, 2)
		return 0.0
	# שומרת מרחק: גולשת אחורה כשמתקרבים, ומתקרבת לאט כשרחוק
	if dist < 300.0:
		if dist < 60.0:
			return speed * 0.5
		z._dir = -toward
		return speed * 0.85
	if dist > 470.0:
		return speed * 0.7
	return 0.0


# סוף השיר: מזעיקה את כולם + תגבורת מחוץ למסך
func _call(pl: Node) -> void:
	Sfx.play("siren_call", z.global_position, 1.0, 0.05, 2)
	var pp: Vector2 = pl.global_position
	for o in z.get_tree().get_nodes_in_group("zombies"):
		if o == z or o.dead or o.brain == null:
			continue
		var dd: float = o.global_position.distance_to(z.global_position)
		if dd < 750.0:
			o.brain.hear_call(pp, 0.2 + dd / 900.0)
			o._alert_t = maxf(o._alert_t, 6.0)
	var dr := director()
	if dr != null:
		dr.calls_made += 1
		dr._signal(z.global_position + Vector2(0, -80.0 * z.sc), "SONG", Color(0.95, 0.5, 1.0))
	var n := spawn_wave(pl, wave_size())
	if n > 0:
		z._popup("+%d" % n, Color(0.95, 0.5, 1.0), 16, -100.0)


# תגבורת מחוץ למסך (עם מגבלה קשיחה). מחזיר כמה נוצרו
func spawn_wave(pl: Node, want: int) -> int:
	var main: Node = z.get_parent()
	if main == null or not main.has_method("_spawn_zombie"):
		return 0
	var alive := 0
	for o in z.get_tree().get_nodes_in_group(GROUP):
		if not o.dead:
			alive += 1
	var n := mini(want, mini(MAX_TOTAL - summoned, MAX_ALIVE - alive))
	if n <= 0:
		return 0
	var pp: Vector2 = pl.global_position
	var view_half := 700.0
	var cam: Camera2D = z.get_viewport().get_camera_2d()
	var cx: float = pp.x
	if cam != null:
		cx = cam.get_screen_center_position().x
		view_half = z.get_viewport_rect().size.x * 0.5 / cam.zoom.x
	var floor_y: float = pp.y
	if "_stage" in main and main._stage != null:
		floor_y = main._stage.floor_y
	var ww: float = z.world_w
	var made := 0
	for i in n:
		_side = -_side
		var x := cx + _side * (view_half + 70.0 + float(i) * 40.0)
		if x < 80.0 or x > ww - 80.0:
			x = cx - _side * (view_half + 70.0 + float(i) * 40.0)
		x = _free_x(x, floor_y)
		if x < 0.0:
			continue
		var kinds := [0, 0, 0, 1, 1, Registry.ADAPTOR, Registry.DODGER]
		var nz: Node = main._spawn_zombie(x, floor_y, int(kinds[randi() % kinds.size()]), null)
		if nz == null:
			continue
		nz.add_to_group(GROUP)
		nz._alert_t = 8.0
		nz._dir = signf(pp.x - x)
		if nz.brain != null:
			nz.brain.hear_call(pp, 0.3)
		made += 1
	summoned += made
	return made


# מקום פנוי על הרצפה (בלי קיר / מכשול). -1 = לא נמצא
func _free_x(x: float, floor_y: float) -> float:
	var space: PhysicsDirectSpaceState2D = z.get_world_2d().direct_space_state
	var pq := PhysicsPointQueryParameters2D.new()
	pq.collision_mask = 1
	for k in 8:
		var tx := x + float(k) * 45.0 * (1.0 if k % 2 == 0 else -1.0)
		var ok := true
		for yy in [15.0, 40.0, 60.0]:
			pq.position = Vector2(tx, floor_y - float(yy))
			if not space.intersect_point(pq, 1).is_empty():
				ok = false
				break
		if ok:
			return tx
	return -1.0


func on_damage(_amount: int, _hit_pos: Vector2, _dir: Vector2, _src: Dictionary) -> bool:
	if _song_t > 0.0:   # השיר נקטע
		_song_t = 0.0
		_stagger = 0.6
		_song_cd = 3.0
		z._popup("SILENCED", Color(0.8, 0.7, 1.0), 13, -100.0)
	return true


func draw() -> bool:
	begin_draw()
	var sk := col(z.skin)
	var coat := col(z.shirt)
	var coat_d := col(Art.shade(z.shirt, 0.3))
	var t: float = z._time
	var singing: bool = _song_t > 0.0 and not z.dead
	var hover: float = 0.0 if z.dead else -5.0 - sin(t * 2.0) * 2.0
	var hip := Vector2(0.0, -22.0 + hover)
	var sh := Vector2(1.0, -44.0 + hover)
	var head := sh + Vector2(2.0, -9.0)
	var hair := col(Color("6a5a7a"))
	# שיער ארוך שצף למעלה ואחורה כמו במים (מאחורי הכל)
	for i in 9:
		var root := head + Vector2(-4.5 + float(i) * 1.0, -3.0 - absf(float(i) - 4.0) * 0.4)
		var w1 := sin(t * 1.8 + float(i) * 0.7) * 3.0
		var w2 := sin(t * 1.3 + float(i) * 1.1) * 4.0
		var pts := PackedVector2Array([root, root + Vector2(-5.0 + w1 * 0.4, -5.0), root + Vector2(-11.0 + w1, -7.0 + w2 * 0.5 - float(i) * 0.6), root + Vector2(-18.0 + w1 * 1.3, -4.0 + w2 - float(i) * 0.8), root + Vector2(-24.0 + w1 * 1.6, -1.0 + w2 * 1.3 - float(i) * 0.5)])
		z.draw_polyline(pts, Color(hair, 0.85), 1.3, true)
	# יד אחורית
	var bh := sh + Vector2(-4.0, 18.0 + sin(t * 1.5) * 2.0)
	if singing:
		bh = sh + Vector2(-16.0, -12.0)
	Art.limb(z, PackedVector2Array([sh + Vector2(-2, 1), sh.lerp(bh, 0.5) + Vector2(-2, 1), bh]), 2.6, col(Art.shade(z.skin, 0.25)))
	# חלוק מעבדה קרוע כשמלה (בלי רגליים - מרחפת)
	var hem := 2.0 + hover
	var dress := PackedVector2Array([sh + Vector2(-6, 0), sh + Vector2(6, 0), hip + Vector2(6, 2), Vector2(9, hem - 4.0), Vector2(5, hem), Vector2(2, hem - 3.0), Vector2(-2, hem + 1.0), Vector2(-5, hem - 3.0), Vector2(-9, hem - 1.0), hip + Vector2(-7, 2)])
	Art.fill_shaded(z, dress, coat, 0.1, 0.35)
	for i in 4:   # רצועות קרועות שמתנופפות
		var sx := -7.0 + float(i) * 4.5
		z.draw_line(Vector2(sx, hem - 2.0), Vector2(sx - 2.0 + sin(t * 3.0 + float(i)) * 2.0, hem + 5.0), coat_d, 1.2)
	z.draw_line(sh + Vector2(1, 1), hip + Vector2(2, 3), coat_d, 1.0)   # שולי החלוק
	Art.oval(z, hip.lerp(sh, 0.4) + Vector2(3, 0), 2.2, 3.5, col(Color(0.5, 0.05, 0.05, 0.7)), 0.0, Art.NONE)   # כתם דם
	# צוואר + שק גרון זוהר
	var pulse := 0.5 + 0.5 * sin(t * (12.0 if singing else 3.0))
	Art.limb(z, PackedVector2Array([sh + Vector2(1, 0), head + Vector2(0, 5)]), 3.4, sk)
	var throat := sh + Vector2(3.0, -3.0)
	var tr := 2.6 + (1.8 if singing else 0.6) * pulse
	Art.glow(z, throat, tr * 3.0, Color(1.0, 0.35, 0.85, 0.35 + 0.4 * pulse))
	Art.oval(z, throat, tr, tr * 0.9, col(Color(0.95, 0.45, 0.85)), 0.0, Art.OUTLINE, 0.9)
	# ראש: פנים צרות, עיניים לבנות, פה פתוח כשהיא שרה
	Art.oval_shaded(z, head, 5.0, 6.5, sk, 0.0)
	for e in [Vector2(1.5, -1.5), Vector2(4.2, -1.2)]:
		var ev: Vector2 = e
		z.draw_circle(head + ev, 1.1, Color(0.95, 0.92, 1.0))
		Art.glow(z, head + ev, 2.6, Color(0.85, 0.75, 1.0, 0.5))
	if singing:
		Art.oval(z, head + Vector2(3.0, 3.0), 1.6, 2.6, Color(0.1, 0.0, 0.05), 0.0, Art.NONE)
	else:
		z.draw_line(head + Vector2(1.5, 3.0), head + Vector2(4.5, 3.2), Color(0.25, 0.05, 0.1), 0.9)
	# שיער מקדימה
	for i in 3:
		var r0 := head + Vector2(-3.0 + float(i) * 2.0, -5.5)
		z.draw_line(r0, r0 + Vector2(-3.0 + sin(t * 2.0 + float(i)) * 1.5, 7.0), hair, 1.4)
	# יד קדמית
	var fh := sh + Vector2(6.0, 18.0 + sin(t * 1.5 + 1.0) * 2.0)
	if singing:
		fh = sh + Vector2(16.0, -12.0)
	elif z._bite_anim > 0.0:
		fh = sh + Vector2(16.0, 2.0)
	Art.limb(z, PackedVector2Array([sh + Vector2(2, 1), sh.lerp(fh, 0.5) + Vector2(2, 1), fh]), 2.6, sk)
	for i in 3:   # אצבעות ארוכות
		z.draw_line(fh, fh + Vector2(3.0, -2.0 + float(i) * 2.0), sk, 0.9)
	# "מד גודל הקבוצה": כדורים קטנים שמקיפים את הגרון (1-3)
	if not z.dead:
		for i in wave_size():
			var a := t * 2.0 + TAU * float(i) / float(wave_size())
			z.draw_circle(throat + Vector2(cos(a) * 9.0, sin(a) * 4.0), 1.2, Color(1.0, 0.5, 0.9, 0.8))
	# טבעות קול בזמן השיר
	if singing:
		var k := 1.0 - _song_t / SONG_TIME
		for i in 3:
			var q := fmod(k * 2.0 + float(i) * 0.33, 1.0)
			z.draw_arc(throat, 6.0 + q * 46.0, -1.2, 1.2, 16, Color(1.0, 0.55, 0.95, 0.7 * (1.0 - q)), 2.0, true)
			z.draw_arc(throat, 6.0 + q * 46.0, PI - 1.2, PI + 1.2, 16, Color(1.0, 0.55, 0.95, 0.45 * (1.0 - q)), 1.5, true)
	end_draw()
	return true
