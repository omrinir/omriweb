extends "res://enemies/zombie_type.gd"
# ============================================================
#  WADDLER (שלב 57, "PENGUIN COAST") - מת נמוך וכפוף במעיל פרקה שחור-לבן עם ברדס בצורת ראש פינגווין
#    (פס לבן סביב הפנים, כתם כתום, מצחייה כמו מקור), שרוולים ארוכים שמשתלשלים כמו סנפירים, מגפי גומי כתומים.
#  מה הוא למד, וממה: המתים ראו שהגיבור לא יורה לתוך קהל של חיים (ניצולים, עדרים). אז הם מתחבאים בתוך החיים.
#    HIDE   - מתכופף בתוך מושבת פינגווינים (effects/s57_decor.gd Colony) וזז איתה. כשהמושבה מתגודדת - כדור שנכנס
#             לצפיפות פוגע בפינגווין והמושבה מתפזרת (ColonyBody). מלמעלה (קומה) / מעל הפינגווינים אפשר לפגוע בו (x HIDE_MULT).
#    REVEAL - המושבה התפזרה / התקרבת (AMBUSH_R) / נפגע: קם לגובה מלא (גבוה מהפינגווינים, עיניים אדומות, דם) - הסימן (REVEAL_T).
#    WADDLE - רץ אליך בדידוס מהיר. בטווח LUNGE_R -> WIND (מתכווץ) -> LUNGE: זינוק עם ציפורניים (LUNGE_DMG).
#    FLOP   - החטיא: נוחת על הבטן ומחליק (FLOP_T) - פגיע (x FLOP_MULT).
#  נגד: ירייה אחת למושבה (או קפיצה פנימה) - הפינגווינים מתפזרים והוא נחשף. להתגלגל / לקפוץ מעל הזינוק.
#  לומד (main meta "wd_kills" >= LEARN_KILLS): "IT WAITS FOR THE COLONY" - כשהמושבה מתפזרת הוא לא תוקף אלא בורח עם
#    הפינגווינים ומחכה שיתקבצו סביבו שוב (WAIT, עד WAIT_MAX), דוחף את המושבה אליך (Colony.lure), וזונק מתוכה רק כשאתה
#    ממש קרוב (LEARN_R, WIND קצר יותר). חלון: בזמן שהוא מחכה הוא חשוף.
#  בוס (chase_range > 600): "THE BEACHMASTER" - WADDLER ענק, בעל החוף.
#    SLIDE  - נופל על הבטן (SLIDE_WIND, אבק) ומחליק לאורך החוף (SLIDE_V) - לקפוץ מעליו! מעיף פינגווינים.
#    WALLOW - אחרי ההחלקה שוכב על הבטן (WALLOW_T) - הגב פתוח (x WALLOW_MULT).
#    FLOP   - כשאתה קרוב (FLOP_R): קופץ ונוחת עליך - גל הדף (SLAM_R) על הקרקע. לקפוץ.
#    ROAR   - שואג (ROAR_T, החזה פתוח x ROAR_MULT) וקורא ל-ROAR_N WADDLER מהגלים (עד ROAR_MAX חיים).
#    לומד בקרב: אחרי 2 החלקות שקפצת מעליהן / מתחת לחצי חיים - "IT TURNS BACK NOW": ההחלקה חוזרת אחורה מיד.
#  שחקן בסצנת סיפור (story/scenes/l57_chorus.gd): talking, tilt, smile, t. מחוץ לקבוצה "zombies" הוא לא תוקף.
#  לשנות: HIDE_R, AMBUSH_R, LEARN_R, REVEAL_T, LUNGE_R, WIND_T, LUNGE_V, FLOP_T, FLOP_MULT, HIDE_MULT, WAIT_MAX, LEARN_KILLS;
#         בוס: SLIDE_WIND, SLIDE_V, SLIDE_MAX, WALLOW_T, WALLOW_MULT, FLOP_R, SLAM_R, ROAR_*, B_CD.
# ============================================================

const SOUNDS := {
	"wd_shriek": {"drive": 2.6, "layers": [["V", 380, 520, 0.0, 0.32, 0.01, 4.0, 0.8, 1.0, 0.06, 0, [900, 1900, 45]], ["N", 0, 0, 0.0, 0.25, 0.0, 8.0, 0.25, 0.6, 0, 0.3]]},
	"wd_lunge": {"drive": 2.4, "layers": [["V", 260, 180, 0.0, 0.35, 0.01, 4.0, 0.8, 1.0, 0.05, 0, [700, 1300, 40]], ["N", 0, 0, 0.0, 0.25, 0.02, 9.0, 0.35, 0.25, 0, 0.05]]},
	"wd_flop": [["N", 0, 0, 0.0, 0.3, 0.0, 10.0, 0.7, 0.15, 0], ["S", 80, 40, 0.0, 0.25, 0.0, 10.0, 0.6, 1.0, 0], ["B", 0.7, 0.7, 0.0, 0.3, 0.0, 6.0, 0.3, 1.0, 0, 0, 80.0]],
	"bm_roar": {"rev": 0.4, "drive": 2.8, "layers": [["V", 70, 55, 0.0, 1.6, 0.08, 1.2, 1.0, 1.0, 0.06, 0, [380, 750, 28]], ["V", 105, 80, 0.05, 1.5, 0.08, 1.2, 0.6, 1.0, 0.06, 0, [450, 900, 22]], ["N", 0, 0, 0.0, 1.5, 0.1, 1.6, 0.3, 0.15, 0]]},
	"bm_slide": {"rev": 0.2, "layers": [["N", 0, 0, 0.0, 1.6, 0.05, 1.0, 0.7, 0.2, 0, 0.02], ["B", 0.5, 0.5, 0.0, 1.6, 0.0, 1.0, 0.3, 1.0, 0, 0, 60.0]]},
	"bm_slam": {"rev": 0.3, "drive": 2.4, "layers": [["N", 0, 0, 0.0, 0.6, 0.0, 5.0, 1.0, 0.1, 0], ["S", 60, 28, 0.0, 0.6, 0.0, 5.0, 1.0, 1.0, 0], ["B", 0.6, 0.6, 0.0, 0.5, 0.0, 5.0, 0.4, 1.0, 0, 0, 100.0]]},
}

const HIDE_R := 420.0
const AMBUSH_R := 125.0
const LEARN_R := 105.0
const REVEAL_T := 0.4
const LUNGE_R := 175.0
const WIND_T := 0.38
const WIND_T_LEARN := 0.2
const LUNGE_V := Vector2(430.0, -300.0)
const LUNGE_DMG := 1
const LUNGE_CD := 1.1
const FLOP_T := 0.75
const FLOP_MULT := 1.5
const HIDE_MULT := 0.6
const WAIT_MAX := 4.0
const LEARN_KILLS := 2
# בוס
const SLIDE_WIND := 0.6
const SLIDE_V := 600.0
const SLIDE_MAX := 1.7
const SLIDE_DMG := 2
const SLIDE_PAST := 300.0         # ההחלקה נגמרת אחרי שעברה אותך בכך
const ARENA_W := 1150.0           # הבוס לא יוצא מהזירה (world_w - ARENA_W)
const WALLOW_T := 1.4
const WALLOW_MULT := 1.6
const FLOP_R := 240.0
const FLOP_WIND := 0.5
const SLAM_R := 190.0
const SLAM_DMG := 1
const ROAR_T := 1.3
const ROAR_CD := 9.0
const ROAR_N := 2
const ROAR_MAX := 3
const ROAR_MULT := 1.4
const ARMOR := 0.8
const B_CD := Vector2(1.2, 2.2)

enum {SEEK, HIDE, REVEAL, WADDLE, WIND, LUNGE, FLOP, WAIT, B_WALK, B_SLIDE_WIND, B_SLIDE, B_WALLOW, B_FLOP_WIND, B_FLOP_AIR, B_ROAR}
var state := SEEK
# לבדיקות
var hides := 0
var reveals := 0
var lunges := 0
var lunge_hits := 0
var flops := 0
var waits := 0
var lured := 0
var learned_lunges := 0
var slides := 0
var slide_hits := 0
var jumped := 0
var turnbacks := 0
var slams := 0
var slam_hits := 0
var roars := 0
var summoned := 0
var wallow_hits := 0
# שחקן בסצנה
var talking := false
var tilt := 0.0
var smile := 0.0
var t := 0.0

var learned := false
var colony: Node = null
var _st := 0.0
var _cd := 0.8
var _hit := false
var _rise := 0.0               # 0 = מתכופף, 1 = עומד מלא
var _wait_t := 0.0
var _revealed := false
var _said := false
var _var := []                 # מראה לכל זומבי: [פרקה, כתם, סוג פס, דם]
var _b_cd := 2.0
var _roar_cd := 6.0
var _spawned: Array = []
var _slide_dir := 1.0
var _over := false
var _back := false
var _engaged := false
var _dust := 0.0
var _ring := -1.0
var _ring_pos := Vector2.ZERO


func _boss() -> bool:
	return z != null and float(z.chase_range) > 600.0


func stats() -> Dictionary:
	if _boss():
		return {"name": "WADDLER", "hp": 380, "walk": 46.0, "chase": 96.0, "damage": 2, "bite_delay": 1.0, "scale": 2.35, "width": 1.25,
			"duck": 0.0, "cover": 0.0, "skin": Color("8a9a8e"), "shirt": Color("16181e"), "pants": Color("1a1c22"), "shoe": Color("d8782a"),
			"points": 2600, "boss": true, "boss_name": "THE BEACHMASTER", "ragdoll": false}
	return {"name": "WADDLER", "hp": 34, "walk": 40.0, "chase": 128.0, "damage": 1, "bite_delay": 0.8, "scale": 0.92, "width": 1.15,
		"duck": 0.0, "cover": 0.0, "skin": Color("8fa294"), "shirt": Color("16181e"), "pants": Color("1c1e24"), "shoe": Color("d8782a"), "points": 380}


func brain_overrides() -> Dictionary:
	return {"aggression": 0.7}


func use_brain_movement() -> bool:
	return false


func can_bite() -> bool:
	return false


func can_groan() -> bool:
	return state != HIDE


func death_sound() -> String:
	return "zdeath"


func _main() -> Node:
	return z.get_parent()


func setup() -> void:
	var m := _main()
	learned = not _boss() and m != null and int(m.get_meta("wd_kills", 0)) >= LEARN_KILLS
	var r := RandomNumberGenerator.new()
	r.seed = z.get_instance_id()
	var parkas := [Color("16181e"), Color("1a2030"), Color("22262c"), Color("141418")]
	var patches := [Color("f0a028"), Color("f4c840"), Color("e86a2a"), Color(0, 0, 0, 0)]
	_var = [parkas[r.randi() % parkas.size()], patches[r.randi() % patches.size()], r.randi() % 3, r.randf_range(0.3, 1.0), r.randf() < 0.5]
	if _boss():
		state = B_WALK
		_rise = 1.0
		_resize(Vector2(34.0, 52.0))
	else:
		state = SEEK
		_find_colony()
		if colony != null:
			state = HIDE
			hides += 1
		_resize(Vector2(30.0, 34.0))


func _resize(b: Vector2) -> void:
	var rs := z._shape.shape as RectangleShape2D
	rs.size = Vector2(b.x * z.wf * z.sc, b.y * z.sc)
	z._shape.position = Vector2(0.0, -b.y * 0.5 * z.sc)


func _find_colony() -> void:
	colony = null
	var bd := HIDE_R
	for c in z.get_tree().get_nodes_in_group("s57_colonies"):
		var d: float = absf(c.center().x - z.global_position.x)
		if d < bd:
			var n := 0
			for o in z.get_tree().get_nodes_in_group("zombies"):
				if o != z and o.type_mod != null and o.type_mod.get("colony") == c:
					n += 1
			if n < 2:
				bd = d
				colony = c


func _scene_actor() -> bool:
	return not z.is_in_group("zombies")


# ============================================================
#  תנועה
# ============================================================
func physics(pl: Node, delta: float) -> bool:
	t += delta
	_st -= delta
	_cd -= delta
	if not z.is_on_floor():
		z.velocity.y += z.gravity * delta
	if _scene_actor():   # שחקן בסצנה: עומד, נושם, מסתכל על השחקן
		_rise = move_toward(_rise, 1.0, delta * 2.0)
		z.velocity.x = 0.0
		if pl != null:
			z._dir = signf(pl.global_position.x - z.global_position.x) if absf(pl.global_position.x - z.global_position.x) > 4.0 else z._dir
		z.move_and_slide()
		return true
	var has: bool = pl != null and not pl.dead
	var d: Vector2 = (pl.global_position - z.global_position) if has else Vector2.ZERO
	if _boss():
		_boss_physics(pl, has, d, delta)
		z.move_and_slide()
		return true
	var standing := state in [REVEAL, WADDLE, WIND, LUNGE]
	_rise = move_toward(_rise, 1.0 if standing else 0.0, delta * (6.0 if standing else 3.0))
	match state:
		SEEK:
			if colony == null or not is_instance_valid(colony):
				_find_colony()
			if colony != null and colony.huddled():
				var tx: float = colony.center().x
				_move_to(tx, z.chase_speed * 0.6, delta)
				if absf(tx - z.global_position.x) < 10.0:
					state = HIDE
					hides += 1
					_resize(Vector2(30.0, 34.0))
			else:
				state = WADDLE
		HIDE:
			if colony == null or not is_instance_valid(colony):
				_reveal()
			else:
				var tx: float = colony.center().x + sin(t * 0.7 + float(z.get_instance_id() % 7)) * colony.half_w() * 0.35
				_move_to(tx, 70.0, delta)
				if has:
					z._dir = signf(d.x) if absf(d.x) > 6.0 else z._dir
				var near := has and absf(d.x) < (LEARN_R if learned else AMBUSH_R) and absf(d.y) < 60.0
				if learned and has and absf(d.x) < 700.0 and absf(d.y) < 120.0 and colony.huddled():   # דוחף את המושבה אליך
					colony.lure(pl.global_position.x)
					if Engine.get_physics_frames() % 60 == 0:
						lured += 1
				if near:
					if learned:
						learned_lunges += 1
						_start_wind(pl)
					else:
						_reveal()
				elif not colony.huddled():
					if learned:
						_start_wait()
					else:
						_reveal()
		WAIT:   # (למד) בורח עם הפינגווינים ומחכה שיתקבצו סביבו
			_wait_t -= delta
			if colony == null or not is_instance_valid(colony) or _wait_t <= 0.0:
				_reveal()
			else:
				_move_to(colony.center().x, z.chase_speed * 0.8, delta)
				if colony.huddled() and absf(colony.center().x - z.global_position.x) < 30.0:
					state = HIDE
					hides += 1
		REVEAL:
			z.velocity.x = move_toward(z.velocity.x, 0.0, 900.0 * delta)
			if has:
				z._dir = signf(d.x) if absf(d.x) > 4.0 else z._dir
			if _st <= 0.0:
				state = WADDLE
		WADDLE:
			if not has:
				z.velocity.x = move_toward(z.velocity.x, 0.0, 600.0 * delta)
			else:
				z._dir = signf(d.x) if absf(d.x) > 4.0 else z._dir
				z.velocity.x = move_toward(z.velocity.x, z._dir * z.chase_speed, 900.0 * delta)
				z._walk_phase += delta * 16.0
				if absf(d.x) < LUNGE_R and absf(d.y) < 70.0 and _cd <= 0.0 and z.is_on_floor():
					_start_wind(pl)
				if z.is_on_floor() and z.is_on_wall() and absf(z.velocity.x) < 40.0:
					z.velocity.y = -480.0
		WIND:
			z.velocity.x = move_toward(z.velocity.x, 0.0, 1400.0 * delta)
			if has:
				z._dir = signf(d.x) if absf(d.x) > 4.0 else z._dir
			if _st <= 0.0:
				state = LUNGE
				lunges += 1
				_hit = false
				var dist := clampf(absf(d.x) if has else LUNGE_R, 60.0, LUNGE_R + 40.0)
				z.velocity = Vector2(z._dir * LUNGE_V.x * clampf(dist / LUNGE_R, 0.55, 1.15), LUNGE_V.y)
				Sfx.play("wd_lunge", z.global_position, 0.0, 0.1, 3)
		LUNGE:
			if has and not _hit:
				var me := Rect2(z.global_position + Vector2(-16.0 * z.sc, -40.0 * z.sc), Vector2(32.0 * z.sc, 40.0 * z.sc))
				if me.intersects(pl.body_rect()):
					_hit = true
					if pl._roll_t <= 0.0:
						lunge_hits += 1
					pl.hurt(LUNGE_DMG, Vector2(z._dir * 1.2, -0.4))
			if z.is_on_floor() and z.velocity.y >= 0.0 and _st < -0.15:
				if _hit:
					state = WADDLE
					_cd = LUNGE_CD
				else:
					state = FLOP
					flops += 1
					_st = FLOP_T
					_resize(Vector2(44.0, 18.0))
					Sfx.play("wd_flop", z.global_position, 0.0, 0.1, 2)
					if Art.on_screen(z, z.global_position):
						Particles.burst(z.get_parent(), z.global_position + Vector2(0, -4), "smoke", Vector2.UP, 4)
		FLOP:
			z.velocity.x = move_toward(z.velocity.x, 0.0, 500.0 * delta)
			if _st <= 0.0:
				_resize(Vector2(34.0, 48.0))
				_cd = LUNGE_CD
				if learned:
					_find_colony()
					if colony != null and colony.huddled():
						state = SEEK
						_resize(Vector2(30.0, 34.0))
						return _end()
				state = WADDLE
	return _end()


func _end() -> bool:
	z.move_and_slide()
	return true


func _move_to(tx: float, sp: float, delta: float) -> void:
	var dx: float = tx - z.global_position.x
	if absf(dx) > 3.0:
		z.velocity.x = move_toward(z.velocity.x, signf(dx) * minf(sp, absf(dx) * 6.0), 900.0 * delta)
		z._walk_phase += delta * 10.0
	else:
		z.velocity.x = move_toward(z.velocity.x, 0.0, 900.0 * delta)


func _reveal() -> void:
	if state == REVEAL or state == WADDLE:
		return
	state = REVEAL
	reveals += 1
	_revealed = true
	_st = REVEAL_T
	_resize(Vector2(34.0, 48.0))
	Sfx.play("wd_shriek", z.global_position, 0.0, 0.1, 3)
	if colony != null and is_instance_valid(colony) and colony.huddled():
		var pl := player() as Node2D
		colony.scatter(pl.global_position.x if pl != null else z.global_position.x)


func _start_wind(pl: Node) -> void:
	state = WIND
	_st = WIND_T_LEARN if learned else WIND_T
	_resize(Vector2(34.0, 44.0))
	_revealed = true
	if pl != null:
		z._dir = signf(pl.global_position.x - z.global_position.x + 0.01)
	if colony != null and is_instance_valid(colony) and colony.huddled():
		colony.scatter(pl.global_position.x if pl != null else z.global_position.x)
	Sfx.play("wd_shriek", z.global_position, -2.0, 0.1, 3)


func _start_wait() -> void:
	state = WAIT
	waits += 1
	_wait_t = WAIT_MAX
	var m := _main()
	if m != null and not m.has_meta("wd_said"):
		m.set_meta("wd_said", true)
		z._popup("IT WAITS FOR THE COLONY NOW", Color("ff8a7a"), 12, -70.0)


func on_damage(_amount: int, _hit_pos: Vector2, _dir: Vector2, src: Dictionary) -> bool:
	if z.dead or _scene_actor():
		return not _scene_actor()
	if _boss():
		return true
	if state == HIDE or state == SEEK or state == WAIT:
		if str(src.get("source", "bullet")) != "fire":
			if learned and state == HIDE:
				_start_wait()
			else:
				_reveal()
	return true


func damage_mult(_zone: String, _src: Dictionary) -> float:
	if _boss():
		match state:
			B_WALLOW:
				wallow_hits += 1
				return WALLOW_MULT
			B_ROAR:
				return ROAR_MULT
		return ARMOR
	if state == FLOP:
		return FLOP_MULT
	if state == HIDE and colony != null and is_instance_valid(colony) and colony.huddled():
		return HIDE_MULT
	return 1.0


func on_death() -> void:
	if _boss():
		for w in _spawned:   # הקטנים שהוא קרא להם נופלים איתו
			if is_instance_valid(w) and not w.dead:
				w.take_damage(999, w.global_position + Vector2(0, -20), Vector2.UP, true, {"source": "hazard", "fixed": 999})
		var cam: Camera2D = z.get_viewport().get_camera_2d()
		if cam != null and cam.has_method("shake"):
			cam.shake(16.0, 0.7)
		Sfx.play("bm_roar", z.global_position, 2.0, 0.0, 1, 0.7)
		for c in z.get_tree().get_nodes_in_group("s57_colonies"):
			if absf(c.global_position.x - z.global_position.x) < 900.0:
				c.scatter(z.global_position.x, true)
		Particles.burst(z.get_parent(), z.global_position + Vector2(0, -60), "hit", Vector2.UP, int(30.0 * Quality.gore()))
		return
	var m := _main()
	if m != null and _revealed:
		m.set_meta("wd_kills", int(m.get_meta("wd_kills", 0)) + 1)
	if colony != null and is_instance_valid(colony) and colony.huddled():
		colony.scatter(z.global_position.x)
	Particles.burst(z.get_parent(), z.global_position + Vector2(0, -26), "snow", Vector2.UP, 6)   # נוצות מהברדס


# ============================================================
#  בוס: THE BEACHMASTER
# ============================================================
func _boss_physics(pl: Node, has: bool, d: Vector2, delta: float) -> void:
	_b_cd -= delta
	_roar_cd -= delta
	if _ring >= 0.0:
		_ring += delta
		if _ring > 0.6:
			_ring = -1.0
	var met: bool = has and (_engaged or absf(d.x) < z.chase_range or z._alert_t > 0.0 or state != B_WALK)
	if met:
		_engaged = true   # הקרב התחיל: לא "שוכח" אותך כשהחלקה לוקחת אותו רחוק
	match state:
		B_WALK:
			if not met:
				z.velocity.x = move_toward(z.velocity.x, 0.0, 500.0 * delta)
				return
			z._dir = signf(d.x) if absf(d.x) > 6.0 else z._dir
			z.velocity.x = move_toward(z.velocity.x, z._dir * z.chase_speed, 500.0 * delta)
			z._walk_phase += delta * 7.0
			if _b_cd <= 0.0 and z.is_on_floor():
				if _roar_cd <= 0.0 and _alive_spawned() < ROAR_MAX:
					state = B_ROAR
					_st = ROAR_T
					roars += 1
					_roar_cd = ROAR_CD
					Sfx.play("bm_roar", z.global_position, 4.0, 0.05, 1)
					var cam: Camera2D = z.get_viewport().get_camera_2d()
					if cam != null and cam.has_method("shake"):
						cam.shake(9.0, 0.8)
				elif absf(d.x) < FLOP_R and randf() < 0.6:
					state = B_FLOP_WIND
					_st = FLOP_WIND
				else:
					state = B_SLIDE_WIND
					_st = SLIDE_WIND
					_slide_dir = z._dir
					_back = false
		B_SLIDE_WIND:
			z.velocity.x = move_toward(z.velocity.x, -z._dir * 30.0, 1200.0 * delta)
			_dust -= delta
			if _dust <= 0.0 and Art.on_screen(z, z.global_position):
				_dust = 0.08
				Particles.burst(z.get_parent(), z.global_position + Vector2(z._dir * 30.0, -4), "smoke", Vector2(-z._dir, -0.4), 2)
			if _st <= 0.0:
				_begin_slide()
		B_SLIDE:
			z.velocity.x = _slide_dir * SLIDE_V
			_dust -= delta
			if _dust <= 0.0 and Art.on_screen(z, z.global_position):
				_dust = 0.05
				Particles.burst(z.get_parent(), z.global_position + Vector2(-_slide_dir * 40.0, -4), "smoke", Vector2(-_slide_dir, -0.6), 2)
				Particles.burst(z.get_parent(), z.global_position + Vector2(_slide_dir * 50.0, -2), "drop", Vector2(_slide_dir, -1.0), 1)
			if has:
				var me := Rect2(z.global_position + Vector2(-58.0, -40.0), Vector2(116.0, 40.0))
				if not _hit and me.intersects(pl.body_rect()):
					_hit = true
					if pl._roll_t <= 0.0:
						slide_hits += 1
					pl.hurt(SLIDE_DMG, Vector2(_slide_dir * 2.4, -0.7))
				if not pl.is_on_floor() and absf(d.x) < 70.0 and not _hit:
					_over = true
			if Engine.get_physics_frames() % 6 == 0:
				for c in z.get_tree().get_nodes_in_group("s57_colonies"):
					if absf(c.center().x - z.global_position.x) < c.half_w() + 60.0:
						c.scatter(z.global_position.x - _slide_dir * 50.0, true)
			var wall: bool = z.is_on_wall() and _st < SLIDE_MAX - 0.15
			var bx: float = z.global_position.x
			var edge: bool = (_slide_dir < 0.0 and bx < z.world_w - ARENA_W) or (_slide_dir > 0.0 and bx > z.world_w - 90.0)
			var past: bool = has and (bx - pl.global_position.x) * _slide_dir > SLIDE_PAST
			if _st <= 0.0 or wall or edge or past:
				if _over and not _hit:
					jumped += 1
				var turn: bool = not _back and (jumped >= 2 or z.hp < z.max_hp / 2) and has
				if turn:   # למד: חוזר מיד אחורה
					_back = true
					turnbacks += 1
					if turnbacks == 1:
						z._popup("IT TURNS BACK NOW", Color("ff8a7a"), 18, -150.0)
					_slide_dir = signf(d.x) if absf(d.x) > 10.0 else -_slide_dir
					z._dir = _slide_dir
					_begin_slide()
				else:
					state = B_WALLOW
					_st = WALLOW_T
					Sfx.play("wd_flop", z.global_position, 3.0, 0.1, 2, 0.6)
		B_WALLOW:
			z.velocity.x = move_toward(z.velocity.x, 0.0, 900.0 * delta)
			if _st <= 0.0:
				state = B_WALK
				_resize(Vector2(34.0, 52.0))
				_b_cd = randf_range(B_CD.x, B_CD.y)
		B_FLOP_WIND:
			z.velocity.x = move_toward(z.velocity.x, 0.0, 1400.0 * delta)
			if has:
				z._dir = signf(d.x) if absf(d.x) > 6.0 else z._dir
			if _st <= 0.0:
				state = B_FLOP_AIR
				var tx: float = clampf(d.x if has else z._dir * 150.0, -FLOP_R - 60.0, FLOP_R + 60.0)
				z.velocity = Vector2(tx / 0.9, -760.0)
				_st = 0.2
				Sfx.play("wd_lunge", z.global_position, 3.0, 0.05, 2, 0.6)
		B_FLOP_AIR:
			if z.is_on_floor() and _st <= 0.0:
				slams += 1
				state = B_WALLOW
				_st = WALLOW_T * 0.7
				_ring = 0.0
				_ring_pos = z.global_position
				Sfx.play("bm_slam", z.global_position, 4.0, 0.05, 2)
				var cam: Camera2D = z.get_viewport().get_camera_2d()
				if cam != null and cam.has_method("shake"):
					cam.shake(12.0, 0.4)
				if Art.on_screen(z, z.global_position):
					Particles.burst(z.get_parent(), z.global_position + Vector2(0, -4), "smoke", Vector2.UP, 10)
				if has and absf(d.x) < SLAM_R and pl.is_on_floor() and absf(d.y) < 60.0:
					if pl._roll_t <= 0.0:
						slam_hits += 1
					pl.hurt(SLAM_DMG, Vector2(signf(d.x + 0.01) * 1.6, -1.2))
				for c in z.get_tree().get_nodes_in_group("s57_colonies"):
					if absf(c.center().x - z.global_position.x) < 400.0:
						c.scatter(z.global_position.x, true)
		B_ROAR:
			z.velocity.x = move_toward(z.velocity.x, 0.0, 1400.0 * delta)
			if _st < ROAR_T * 0.5 and _st + delta >= ROAR_T * 0.5:
				_summon(pl)
			if _st <= 0.0:
				state = B_WALK
				_b_cd = randf_range(B_CD.x, B_CD.y)


func _begin_slide() -> void:
	state = B_SLIDE
	_st = SLIDE_MAX
	_hit = false
	_over = false
	slides += 1
	_resize(Vector2(52.0, 17.0))
	Sfx.play("bm_slide", z.global_position, 3.0, 0.05, 2)


func _alive_spawned() -> int:
	var n := 0
	for w in _spawned:
		if is_instance_valid(w) and not w.dead:
			n += 1
	return n


func _summon(pl: Node) -> void:
	var m := _main()
	if m == null or not m.has_method("_spawn_zombie"):
		return
	for i in ROAR_N:
		if _alive_spawned() >= ROAR_MAX:
			return
		var side := 1.0 if i % 2 == 0 else -1.0
		var x: float = z.global_position.x + side * randf_range(240.0, 340.0)
		if pl != null:
			x = clampf(x, pl.global_position.x - 500.0, pl.global_position.x + 500.0)
		x = clampf(x, z.world_w - 1050.0, z.world_w - 120.0) + float(i) * 45.0
		var w = m._spawn_zombie(x, z.global_position.y, z.kind)
		if w == null:
			continue
		w.dormant = false
		_spawned.append(w)
		summoned += 1
		if w.type_mod != null:
			w.type_mod.colony = null
			w.type_mod._reveal()
		Particles.burst(m, Vector2(x, z.global_position.y - 10.0), "drop", Vector2.UP, 12)
		Sfx.play("splash", Vector2(x, z.global_position.y), 2.0, 0.1, 2)


func wants_redraw() -> bool:
	return true


# ============================================================
#  ציור: פרקה שחורה עם חזית לבנה (מגואלת בדם), ברדס בצורת ראש פינגווין עם פס לבן, כתם כתום ומצחייה כמו מקור,
#  שרוולים ארוכים כמו סנפירים, ציפורניים, מגפי גומי כתומים. עיניים אדומות בפתח הברדס.
#  מתחבא: נמוך, ראש מורכן, עיניים עמומות - נראה כמו עוד פינגווין גדול. נחשף: קם, מתרחב, העיניים בוערות.
# ============================================================
func draw() -> bool:
	if _var.is_empty():
		return false
	begin_draw()
	var boss := _boss()
	var tt: float = z._time
	var rot := 0.0
	var lift := 0.0
	var lying := false
	if not z.dead:
		match state:
			FLOP, B_WALLOW:
				rot = PI * 0.47
				lift = -9.0
				lying = true
			B_SLIDE:
				rot = PI * 0.5
				lift = -10.0
				lying = true
			B_SLIDE_WIND:
				rot = PI * 0.5 * clampf(1.0 - _st / SLIDE_WIND, 0.0, 1.0) * 0.85
				lift = -9.0 * clampf(1.0 - _st / SLIDE_WIND, 0.0, 1.0)
			LUNGE, B_FLOP_AIR:
				rot = 0.9 if z.velocity.y < 0.0 else 1.2
				lift = -16.0
			WIND, B_FLOP_WIND:
				rot = -0.15
	if rot != 0.0 or lift != 0.0:
		var s := Vector2(z._dir * z.wf * z.sc, z.sc)
		var base := Transform2D(z.react_tilt(), Vector2(0.0, z.react_hop() * z.sc)) * Transform2D(0.0, s, 0.0, Vector2.ZERO)
		DrawBatch.set_transform_matrix(z, base * Transform2D(rot, Vector2(0.0, lift)) * Transform2D(0.0, Vector2(0.0, -lift)))
	var parka: Color = _var[0]
	var patch: Color = _var[1]
	var stripe: int = _var[2]
	var blood: float = _var[3]
	var rise := _rise
	var crouch := 1.0 - rise
	var skin := col(z.skin)
	var pk := col(parka)
	var white := col(Color("e6e2d6"))
	var boots := col(z.shoe)
	var bob := sin(tt * 3.0) * 0.6 if talking else 0.0
	var f: Array = feet(3.4, 1.6)
	var hip := Vector2(0, -12.0 + crouch * 2.0)
	var sh := Vector2(1.5 + crouch * 2.5, -32.0 + crouch * 9.0 + bob)
	var head := sh + Vector2(2.5 + crouch * 2.0, -9.0 + crouch * 3.0)
	if state == WIND or state == B_FLOP_WIND:
		var k := clampf(1.0 - _st / WIND_T, 0.0, 1.0)
		sh += Vector2(-2.0, 4.0) * k
		head += Vector2(-1.0, 5.0) * k
	head += Vector2(tilt * 3.0, 0.0)
	# רגליים קצרות + מגפי גומי כתומים
	for i in 2:
		var ft: Vector2 = f[i]
		var hp := hip + Vector2(-3.0 + float(i) * 5.0, 0)
		var kn := hp.lerp(ft, 0.5) + Vector2(2.0, 0)
		Art.limb(z, PackedVector2Array([hp, kn, ft + Vector2(0, -4)]), 3.6, col(Art.shade(z.pants, 0.2 if i == 0 else 0.0)))
		Art.fill(z, PackedVector2Array([ft + Vector2(-3, -6), ft + Vector2(2.5, -6), ft + Vector2(3.0, -2), ft + Vector2(6.0, -1.0), ft + Vector2(6.0, 0.5), ft + Vector2(-3.5, 0.5)]), boots if i == 1 else col(Art.shade(z.shoe, 0.2)), Art.OUTLINE, 0.9)
	# יד אחורית (סנפיר)
	_flipper(sh + Vector2(-5, 2), true, tt, crouch, boss)
	# גוף הפרקה: עגול ושמן
	var body := Vector2((sh.x + hip.x) * 0.5, (sh.y + hip.y) * 0.5 - 1.0)
	var rx := 11.5 + crouch * 1.5
	var ry := (hip.y - sh.y) * 0.62 + 3.0
	Art.oval_shaded(z, body, rx, ry, pk, 0.0)
	# חזית לבנה (בטן פינגווין) מגואלת בדם
	Art.oval(z, body + Vector2(3.5, 1.0), rx * 0.62, ry * 0.8, white, 0.0, Art.NONE)
	if stripe == 0:   # פס שחור על החזה (מגלני)
		DrawBatch.arc(z, body + Vector2(1.5, -3.0), rx * 0.62, -0.9, 0.9, 10, pk, 2.0)
	if not z.dead or true:
		Art.oval(z, body + Vector2(4.0, 3.0), 3.0 * blood + 1.0, 5.0 * blood + 1.0, Color(0.5, 0.04, 0.04, 0.85), 0.2, Art.NONE)
		Art.oval(z, body + Vector2(1.5, -4.0), 2.0, 1.6 * blood + 0.6, Color(0.42, 0.03, 0.03, 0.8), 0.0, Art.NONE)
		DrawBatch.line(z, body + Vector2(4.5, 6.0), body + Vector2(5.0, 9.0 + 3.0 * blood), Color(0.45, 0.03, 0.03, 0.8), 1.0)
	for q in 3:   # רוכסן / קרעים
		DrawBatch.line(z, body + Vector2(-rx * 0.6 + float(q) * 3.0, ry * 0.3), body + Vector2(-rx * 0.5 + float(q) * 3.5, ry * 0.6), col(Art.shade(parka, -0.2)), 0.8)
	if boss:   # הבוס: נוצות פינגווינים תקועות בפרקה, צלקות, צלצל תקוע בגב
		for q in 6:
			var fp := body + Vector2(-rx * 0.8 + float(q) * 3.4, -ry * 0.5 + float(q % 3) * 5.0)
			DrawBatch.line(z, fp, fp + Vector2(-2.0, -3.0), col(Color("e8e4dc")), 1.0)
		DrawBatch.line(z, body + Vector2(-rx * 0.6, -ry * 0.4), body + Vector2(-rx * 1.6, -ry * 1.3), col(Color("5a4a3a")), 1.6)
		DrawBatch.colored_polygon(z, PackedVector2Array([body + Vector2(-rx * 0.55, -ry * 0.35), body + Vector2(-rx * 0.75, -ry * 0.25), body + Vector2(-rx * 0.66, -ry * 0.5)]), col(Color("9a9a98")))
		DrawBatch.line(z, body + Vector2(-rx * 1.6, -ry * 1.3), body + Vector2(-rx * 2.6, -ry * 0.6), Color(0.3, 0.26, 0.2, 0.8), 0.6)   # חבל
	_hood(head, skin, pk, white, patch, stripe, tt, boss)
	# יד קדמית (סנפיר עם ציפורניים)
	_flipper(sh + Vector2(4, 2), false, tt, crouch, boss)
	if not z.dead and (state == REVEAL or (state == B_ROAR)):
		var k2 := clampf(_st / (REVEAL_T if state == REVEAL else ROAR_T), 0.0, 1.0)
		DrawBatch.string(z, ThemeDB.fallback_font, head + Vector2(-2, -14), "!", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(1.0, 0.3, 0.2, k2))
	end_draw()
	if _ring >= 0.0 and boss:   # גל ההדף של הנחיתה
		var k := _ring / 0.6
		var c: Vector2 = _ring_pos - z.global_position
		var pts := Art.ellipse(c, SLAM_R * k, SLAM_R * k * 0.12, 0.0, 28)
		DrawBatch.polyline(z, pts, Color(0.9, 0.85, 0.7, 0.6 * (1.0 - k)), 4.0)
	return true


func _flipper(s: Vector2, back: bool, tt: float, crouch: float, boss: bool) -> void:
	var c := col(Art.shade(_var[0], 0.18 if back else 0.0))
	var h: Vector2
	match state:
		WIND, B_FLOP_WIND:
			h = s + Vector2(-8.0, 6.0)
		LUNGE, B_FLOP_AIR:
			h = s + Vector2(16.0, -2.0 if back else 2.0)
		REVEAL, B_ROAR:
			h = s + Vector2(10.0 if not back else -9.0, -12.0)   # ידיים פרושות
		HIDE, WAIT, SEEK:
			h = s + Vector2(-2.0 + sin(tt * 2.0) * 1.0, 14.0 - crouch * 2.0)
		B_SLIDE, B_SLIDE_WIND:
			h = s + Vector2(-14.0, 6.0)
		_:
			h = s + Vector2(3.0 + sin(z._walk_phase) * 3.0, 15.0)
	if talking and not back:
		h = s + Vector2(9.0, 6.0 + sin(t * 4.0) * 2.0)
	var mid := s.lerp(h, 0.5) + Vector2(-1.5, 1.0)
	Art.limb(z, PackedVector2Array([s, mid, h]), 4.2 if not boss else 4.6, c)
	var dir := (h - mid).normalized()
	var claw := col(Color("d8cca0"))
	var hand := col(Art.shade(z.skin, 0.15 if back else 0.0))
	DrawBatch.circle(z, h, 1.8, hand)
	for q in 3:
		DrawBatch.line(z, h, h + dir.rotated((float(q) - 1.0) * 0.45) * 4.6, claw, 1.0)


func _hood(c: Vector2, skin: Color, pk: Color, white: Color, patch: Color, stripe: int, tt: float, boss: bool) -> void:
	var hidden := state == HIDE or state == WAIT or state == SEEK
	# ברדס (ראש פינגווין)
	Art.oval_shaded(z, c + Vector2(-0.5, -0.5), 7.4, 7.2, pk, 0.0)
	# כתם כתום (מלך) / פס לבן (מגלני) / כתם לבן מעל העין (ג'נטו)
	match stripe:
		0:
			DrawBatch.arc(z, c + Vector2(1.5, 0.5), 6.2, -2.4, 1.2, 12, white, 1.6)
		1:
			if patch.a > 0.0:
				Art.oval(z, c + Vector2(-3.5, 1.0), 1.8, 3.4, col(patch), 0.2, Art.NONE)
		_:
			Art.oval(z, c + Vector2(0.0, -5.0), 3.0, 1.1, white, -0.2, Art.NONE)
	if patch.a > 0.0 and stripe != 1:
		Art.oval(z, c + Vector2(-4.5, 2.5), 1.3, 1.6, col(patch), 0.0, Art.NONE)
	# פתח הפנים
	var fo := c + Vector2(3.0, 1.0)
	Art.oval(z, fo, 4.5, 5.1, col(Color("0c0c10")), 0.0, Art.NONE)
	Art.oval(z, fo + Vector2(0.7, 0.3), 3.7, 4.3, skin, 0.0, Art.NONE)
	Art.oval(z, fo + Vector2(1.5, 1.8), 2.2, 1.4, col(Art.shade(z.skin, -0.25)), 0.0, Art.NONE)   # לחי שקועה
	if not z.dead:   # ארובות עיניים
		Art.oval(z, fo + Vector2(1.7, -1.2), 1.5, 1.2, col(Color("1a0a0c")), 0.0, Art.NONE)
		Art.oval(z, fo + Vector2(-0.9, -1.2), 1.2, 1.1, col(Color("1a0a0c")), 0.0, Art.NONE)
	# מצחייה כמו מקור
	DrawBatch.colored_polygon(z, PackedVector2Array([c + Vector2(3.0, -3.6), c + Vector2(9.5, -2.0), c + Vector2(3.5, -2.0)]), col(Color("20222a")))
	if patch.a > 0.0:
		DrawBatch.line(z, c + Vector2(4.0, -2.4), c + Vector2(8.5, -2.1), col(patch), 0.9)
	if z.dead:
		DrawBatch.line(z, fo + Vector2(-0.5, -1.6), fo + Vector2(2.5, -0.4), Color(0.2, 0.05, 0.05), 0.8)
		return
	# עיניים אדומות (עמומות כשמתחבא, בוערות כשנחשף / מדבר)
	var glow := 0.35 if hidden else 1.0
	if talking:
		glow = 1.3
	var learned_flash := 0.0
	if z.has_meta("s57_learned_t"):
		learned_flash = clampf(1.0 - float(Time.get_ticks_msec() - int(z.get_meta("s57_learned_t"))) / 600.0, 0.0, 1.0)
	var ec := Color(1.0, 0.22, 0.15).lerp(Color(0.6, 1.0, 0.75), learned_flash)
	DrawBatch.circle(z, fo + Vector2(1.7, -1.2), 1.1, Color(ec, 0.6 + 0.4 * minf(glow, 1.0)))
	DrawBatch.circle(z, fo + Vector2(-0.9, -1.2), 0.85, Color(ec, 0.4 + 0.4 * minf(glow, 1.0)))
	Art.glow(z, fo + Vector2(1.2, -1.2), 3.0 + 2.5 * glow + (6.0 if boss else 0.0), Color(ec, 0.3 * glow + 0.3 * learned_flash))
	# פה: שיניים, נפתח בחשיפה / בזינוק / כשמדבר
	var open := 0.4
	if state in [REVEAL, WIND, LUNGE, B_ROAR, B_FLOP_WIND]:
		open = 2.2
	if talking:
		open = 0.6 + absf(sin(t * 13.0)) * 1.8
	open += smile * 0.6
	DrawBatch.colored_polygon(z, PackedVector2Array([fo + Vector2(-1.0, 1.4), fo + Vector2(2.6, 1.2), fo + Vector2(2.2, 1.8 + open), fo + Vector2(-0.6, 1.8 + open * 0.8)]), col(Color("2a0608")))
	DrawBatch.line(z, fo + Vector2(-0.6, 1.6), fo + Vector2(2.4, 1.4), col(Color("d8d0a8")), 0.6)
	if open > 1.0:
		DrawBatch.line(z, fo + Vector2(0.0, 2.0 + open * 0.8), fo + Vector2(1.0, 3.0 + open), Color(0.5, 0.04, 0.04, 0.8), 0.7)   # ריר דם
