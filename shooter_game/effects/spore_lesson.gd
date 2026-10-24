extends Node2D
const DrawBatch := preload("res://effects/draw_batch.gd")
# ============================================================
#  SPORE LESSON (פטגוניה, משלב 55) - "THEY LEARN" רואים את זה: כשזומבי מת, ענן נבגים זוהר קטן
#  יוצא מהגופה, מרחף לזומבי החי הכי קרוב ונבלע בו - והוא מהבהב בטבעת ("הוא למד").
#  הסיפור (/mnt/project-files/story/THEY_LEARN_story.md): הנבגים נושאים את מה שהמת ראה.
#  זול: עד DOTS נקודות, עד MAX_LIVE אפקטים בבת אחת, בלי צמתים נוספים. zombie.gd -> _spore_lesson()
#  לשנות: FROM_LEVEL (ב-zombie.gd), CHANCE, RANGE, DOTS, MAX_LIVE, RISE_T, FLY_T, FLASH_T, COL.
# ============================================================

const CHANCE := 0.6                 # כמה מההריגות שולחות נבגים
const RANGE := 650.0                # עד כמה רחוק מחפשים "תלמיד"
const DOTS := 7
const MAX_LIVE := 3
const RISE_T := 0.35                # הענן עולה מהגופה
const FLY_T := 0.85                 # ...וטס אל הזומבי
const FLASH_T := 0.4                # טבעת "למד" סביבו
const COL := Color(0.75, 1.0, 0.55)

static var live := 0
var target: Node2D = null
var _t := 0.0
var _from := Vector2.ZERO
var _dots := []                     # [זווית, רדיוס, מהירות סיבוב, גודל]


static func send(parent: Node, from: Vector2, dead: Node) -> void:
	if live >= MAX_LIVE or randf() > CHANCE or parent == null:
		return
	var best: Node2D = null
	var bd := RANGE * RANGE
	for z in parent.get_tree().get_nodes_in_group("zombies"):
		if z == dead or not (z is Node2D) or z.get("dead"):
			continue
		var d := from.distance_squared_to((z as Node2D).global_position)
		if d < bd:
			bd = d
			best = z
	if best == null:
		return
	var fx = load("res://effects/spore_lesson.gd").new()
	fx.target = best
	fx._from = from
	fx.global_position = from
	fx.z_index = 30
	parent.add_child(fx)


func _ready() -> void:
	live += 1
	for i in DOTS:
		_dots.append([randf() * TAU, randf_range(4.0, 16.0), randf_range(-5.0, 5.0), randf_range(1.6, 3.2)])


func _exit_tree() -> void:
	live -= 1


func _goal() -> Vector2:
	if target != null and is_instance_valid(target):
		return target.global_position + Vector2(0.0, -48.0 * float(target.get("sc") if target.get("sc") != null else 1.0))
	return global_position


func _process(delta: float) -> void:
	_t += delta
	if target == null or not is_instance_valid(target) or target.get("dead"):
		if _t < RISE_T + FLY_T:
			_t = RISE_T + FLY_T + FLASH_T * 0.7   # התלמיד מת בדרך: הענן מתפוגג
	if _t < RISE_T:
		global_position = _from + Vector2(0.0, -40.0 * _t / RISE_T)
	elif _t < RISE_T + FLY_T:
		var k := (_t - RISE_T) / FLY_T
		var a := _from + Vector2(0.0, -40.0)
		var b := _goal()
		var mid := (a + b) * 0.5 + Vector2(0.0, -60.0)
		var e := k * k * (3.0 - 2.0 * k)
		global_position = a.lerp(mid, e).lerp(mid.lerp(b, e), e)
	elif _t < RISE_T + FLY_T + FLASH_T:
		global_position = _goal()
	else:
		queue_free()
		return
	for d in _dots:
		d[0] += d[2] * delta
	queue_redraw()


func _draw() -> void:
	DrawBatch.begin(self)
	_draw_b()
	DrawBatch.end(self)

func _draw_b() -> void:
	var fly_end := RISE_T + FLY_T
	if _t < fly_end:
		var shrink := 1.0 - clampf((_t - RISE_T) / FLY_T, 0.0, 1.0) * 0.6
		for d in _dots:
			var p: Vector2 = Vector2(cos(d[0]), sin(d[0])) * float(d[1]) * shrink
			DrawBatch.circle(self, p, d[3] * 2.2, Color(COL, 0.18))
			DrawBatch.circle(self, p, d[3], Color(COL, 0.85))
	else:   # טבעת "למד": מתרחבת ונעלמת
		var k := (_t - fly_end) / FLASH_T
		var r := lerpf(10.0, 46.0, k)
		DrawBatch.arc(self, Vector2.ZERO, r, 0.0, TAU, 24, Color(COL, 0.9 * (1.0 - k)), 3.0 * (1.0 - k) + 1.0)
		DrawBatch.circle(self, Vector2.ZERO, 7.0 * (1.0 - k), Color(1.0, 1.0, 0.85, 0.8 * (1.0 - k)))
