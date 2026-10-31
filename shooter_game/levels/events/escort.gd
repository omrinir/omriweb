extends Node
# ============================================================
#  ESCORT - "RESCUE" (levels/level_events.gd: שלבים 13, 34, 44, 52)
#  בתחילת השלב (בערך 15% מהאורך) מחכה חובשת קרבית עם קשר על הגב (Medic - דמות חדשה, מצוירת כאן.
#  לא survivor.gd: אין לה "שאיבה", וקליעים של השחקן עוברים דרכה בלי לפגוע).
#  * כשמגיעים אליה היא מצטרפת והולכת אחריך במרחק קצר: קופצת על מכשולים ובורות, מטפסת בסולמות
#    לקומה שבה אתה עומד, יורדת דרך קומות. נתקעה / נשארה מאחור מחוץ למסך -> קופצת ("טלפורט") לידך.
#  * יש לה כמה לבבות (לפי רמת הקושי) ופס חיים מעל הראש. זומבי שנוגע בה כשהוא רודף - נושך (לב אחד).
#  * מדי פעם 1-2 זומבים קרובים "צדים" אותה (goal_x של zombie.gd - מתעלמים ממך ורצים אליה), עם סימן אדום
#    מעל הראש. צריך להוריד אותם לפני שהם מגיעים.
#  * באזור הבוס (BOSS_ZONE האחרון) היא מתחבאת לפני הזירה ולא נפגעת. השער נפתח (הבוס מת) והיא חיה ->
#    "SURVIVOR RESCUED" + בונוס ניקוד (Game.add_score) וגרוטאות (Game.scrap). מתה -> "SURVIVOR LOST", בלי עונש.
#  * התחלה מנקודת הביקורת (או השחקן כבר עבר אותה): היא מופיעה מיד לידך.
#  * רחוק מסצנות סיפור (story_db: STORY_CLEAR) - בשלב 52 היא מחכה אחרי x=2300.
#  לשנות: SPAWN_AT, STORY_CLEAR, HP, HUNT_EVERY, HUNTERS, HUNT_T, HUNT_FIRST, HUNT_CHECK, BITE_CD, IFRAME, FOLLOW_DIST, WALK, SPRINT,
#         TP_FAR, STUCK_T, STUCK_FORCE, BOSS_ZONE, RESCUE_SCORE, RESCUE_SCRAP, SIZE.
# ============================================================

const DrawBatch := preload("res://effects/draw_batch.gd")
const Art := preload("res://art.gd")
const Sfx := preload("res://sfx.gd")
const Particles := preload("res://particles.gd")
const BloodScript := preload("res://blood_drop.gd")
const ZombieScript := preload("res://zombie.gd")
const StoryDB := preload("res://story/story_db.gd")
const KillStreak := preload("res://ui/kill_streak.gd")   # font() = Bangers

const SPAWN_AT := 0.15            # איפה היא מחכה (חלק מאורך השלב)
const STORY_CLEAR := 1000.0       # מרחק מינימלי מסצנת סיפור
const HP := [7, 6, 5]             # לבבות לפי קושי (EASY / NORMAL / HARD)
const HUNT_EVERY := [13.0, 10.0, 8.0]   # כל כמה שניות זומבים יוצאים לצוד אותה
const HUNTERS := [1, 1, 2]        # כמה צדים בכל פעם
const HUNT_T := 7.0               # כמה זמן צד מתעקש עליה (ואז חוזר אליך)
const HUNT_FIRST := 7.0           # שקט אחרי שהיא מצטרפת
const HUNT_RANGE := Vector2(220.0, 900.0)   # מאיזה מרחק ממנה בוחרים צד
const HUNT_KINDS := [0, 1, 2, 9, 16]        # רגיל, רץ, ענק, שוטר, שיכור - קודם כל הם
const NO_HUNT := [3, 5, 6, 7, 8, 11, 12, 13, 17, 18, 19]   # יורק, בוסים, נפוח, זוחל, יד, מכונה, זורק, מקלען, ג'טפק - לא
const HUNT_CHECK := 1.6           # צד מסוג מיוחד שלא מתקרב אליה תוך ... (התנועה שלו לא מקשיבה) -> משחררים
const BITE_CD := 1.2              # כל זומבי נושך אותה לכל היותר פעם ב...
const BITE_REACH := Vector2(26.0, 46.0)
const IFRAME := 0.9               # אחרי נשיכה - רגע בלי נזק
const FOLLOW_DIST := 80.0              # כמה מאחוריך היא הולכת
const JOIN_DIST := 320.0          # מאיזה מרחק היא מצטרפת
const WALK := 235.0
const SPRINT := 345.0             # רחוקה (השחקן רץ 320)
const TP_FAR := 1000.0            # רחוקה מזה = טלפורט לידך
const STUCK_T := 2.5              # תקועה ומחוץ למסך -> טלפורט
const STUCK_FORCE := 5.0          # תקועה גם על המסך -> טלפורט (עם ענן אבק)
const BOSS_ZONE := 1500.0         # מסוף השלב: היא מתחבאת לפני הזירה
const RESCUE_SCORE := 1500
const RESCUE_SCRAP := 40          # גרוטאות + 2 לכל מספר שלב (שלב 13: 66, שלב 52: 144)
const SIZE := 0.95

var main: Node
var floor_y := 630.0
var hud_layer: CanvasLayer

var medic: Medic = null
var hide_x := 0.0
var spawn_x := 0.0
var outcome := ""                 # "" / "rescued" / "lost"
var hunters := {}                 # instance_id -> {"z", "t", "gx", "chk", "d0"}
var _diff := 1
var _hunt_t := 0.0
var _frames := 0
var _cp_start := false
var _ui: Node2D
var _marks: Node2D
var _banners: Array = []          # {"text", "sub", "col", "t", "dur", "delay"}
var _rng := RandomNumberGenerator.new()


func start() -> void:
	_rng.randomize()
	_diff = clampi(int(Settings.difficulty), 0, 2)
	var lw: float = main.level_w
	hide_x = lw - BOSS_ZONE - 80.0
	spawn_x = lw * SPAWN_AT
	for sc in StoryDB.for_level(Game.level):   # לא ליד סצנת סיפור
		var sx := float(sc.get("x", -99999.0))
		if absf(spawn_x - sx) < STORY_CLEAR:
			spawn_x = sx + STORY_CLEAR
	spawn_x = main._free_spot(spawn_x)
	for i in 12:   # לא בתוך בור
		if not main._in_pit(spawn_x - 50.0, spawn_x + 50.0, 10.0):
			break
		spawn_x += 90.0
	var p: Node2D = main._player
	_cp_start = p != null and p.global_position.x > spawn_x - 200.0   # התחלה מנקודת הביקורת
	# שכבות ציור: באנרים על ה-HUD, סימנים מעל הצדים בעולם
	_ui = Node2D.new()
	hud_layer.add_child(_ui)
	_ui.draw.connect(_draw_ui)
	_marks = Node2D.new()
	_marks.z_index = 40
	main.add_child(_marks)
	_marks.draw.connect(_draw_marks)
	_banner("RESCUE: GET HER TO THE EXTRACTION", "A medic is waiting ahead. Zombies will go for her - keep her alive for a bonus.", Color(1.0, 0.9, 0.55), 4.5, 1.0 if _cp_start else 4.6)


func player() -> Node2D:
	return main._player if main != null and is_instance_valid(main._player) else null


func _physics_process(delta: float) -> void:
	_frames += 1
	if _frames == 2:   # (פריים פיזיקה אחד אחרי שהשלב נבנה - כדי שהקרן תפגע בקרקע)
		_spawn_medic()
	if medic == null or main._finished:
		return
	if outcome == "" and medic.alive():
		_check_rescue()
		_hunt(delta)
		if _frames % 3 == 0:
			_bites()
	if not hunters.is_empty() or _marks_dirty:
		_marks.queue_redraw()
		_marks_dirty = not hunters.is_empty()


var _marks_dirty := false


func _process(delta: float) -> void:
	for b in _banners:
		b["t"] = float(b["t"]) + delta
	_banners = _banners.filter(func(b): return b.t < b.delay + b.dur + 0.2)
	if not _banners.is_empty() or _ui_dirty:
		_ui.queue_redraw()
		_ui_dirty = not _banners.is_empty()


var _ui_dirty := false


func _spawn_medic() -> void:
	medic = Medic.new()
	medic.ev = self
	medic.max_hp = int(HP[_diff])
	medic.hp = medic.max_hp
	medic.world_w = main.level_w
	var p := player()
	var x := spawn_x
	if _cp_start and p != null:
		x = p.global_position.x - 70.0
	medic.position = Vector2(x, _ground_y(x) - 2.0)
	main.add_child(medic)
	if _cp_start:
		medic.join(false)


# גובה הקרקע (כביש / דיונה / מכשול) בנקודה x
func _ground_y(x: float) -> float:
	var ss: PhysicsDirectSpaceState2D = main.get_world_2d().direct_space_state
	var ray := PhysicsRayQueryParameters2D.create(Vector2(x, floor_y - 420.0), Vector2(x, floor_y + 40.0), 1)
	var hit: Dictionary = ss.intersect_ray(ray)
	return floor_y if hit.is_empty() else float(hit.position.y)


# השחקן באזור הבוס והשער עוד נעול -> היא מתחבאת
func boss_hide() -> bool:
	var p := player()
	if p == null:
		return false
	var ex := get_tree().get_first_node_in_group("level_exit")
	var locked: bool = ex == null or bool(ex.locked)
	return locked and p.global_position.x > main.level_w - BOSS_ZONE


func _check_rescue() -> void:
	var p := player()
	var ex := get_tree().get_first_node_in_group("level_exit")
	if ex == null or p == null:
		return
	if not bool(ex.locked) or p.global_position.x > ex.global_position.x - 30.0:
		if medic.state == Medic.WAIT:   # (לא אמור לקרות - עברת אותה בלי שהצטרפה)
			return
		outcome = "rescued"
		_release_all()
		var scrap := RESCUE_SCRAP + 2 * int(Game.level)
		var before: int = Game.level_score
		Game.add_score(RESCUE_SCORE)
		var gained: int = Game.level_score - before   # (אחרי המכפילים של Game.add_score)
		Game.scrap += scrap
		medic.extract(ex.global_position.x + 60.0)
		_banner("SURVIVOR RESCUED", "+%d SCORE   +%d SCRAP" % [gained, scrap], Color(0.55, 1.0, 0.6), 3.2, 0.0)
		Sfx.play("streak_up", null, -2.0, 0.0, 2, 1.1)
		Sfx.play("heal", null, -4.0)


func on_medic_dead() -> void:
	if outcome != "":
		return
	outcome = "lost"
	_release_all()
	_banner("SURVIVOR LOST", "No rescue bonus this time", Color(1.0, 0.35, 0.3), 3.0, 0.0)
	Sfx.play("fwail", medic.global_position, 0.0, 0.05, 1)


# ---------------- זומבים צדים אותה ----------------
func _hunt(delta: float) -> void:
	# עדכון הצדים: הולכים אליה. מישהו אחר שינה את goal_x (שלב 44: גל השפך) -> משחררים
	for id in hunters.keys():
		var h: Dictionary = hunters[id]
		var z = h.z
		h.t -= delta
		if not is_instance_valid(z) or z.dead or absf(float(z.goal_x) - float(h.gx)) > 0.5:
			hunters.erase(id)
			_marks_dirty = true
			continue
		if h.t <= 0.0 or not medic.can_be_hurt():
			_release(z)
			hunters.erase(id)
			_marks_dirty = true
			continue
		h.chk -= delta
		var dist := absf(float(z.global_position.x) - medic.global_position.x)
		if h.chk <= 0.0:   # לא מתקרב (סוג עם תנועה משלו) -> משחררים, ובודקים אחר בקרוב
			if dist > float(h.d0) - 40.0 and dist > 40.0:
				_release(z)
				hunters.erase(id)
				_marks_dirty = true
				_hunt_t = minf(_hunt_t, 1.0)
				continue
			h.chk = 99.0
		var off := 10.0 * signf(float(z.global_position.x) - medic.global_position.x)
		h.gx = medic.global_position.x + off
		z.goal_x = h.gx
	if not medic.can_be_hurt() or main.clock_paused:
		return
	if medic.state != Medic.FOLLOW and medic.state != Medic.CLIMB:
		return
	_hunt_t -= delta
	if _hunt_t > 0.0:
		return
	_hunt_t = HUNT_EVERY[_diff] * _rng.randf_range(0.8, 1.2)
	var want: int = HUNTERS[_diff] - hunters.size()
	if want <= 0:
		return
	var cands: Array = []
	var mp := medic.global_position
	for z in get_tree().get_nodes_in_group("zombies"):
		if not z.has_method("is_boss") or z.dead or z.dormant or z.is_boss() or z.on_ceiling:
			continue
		if int(z.kind) in NO_HUNT or float(z.goal_x) < INF or hunters.has(z.get_instance_id()):
			continue
		var special: bool = z.type_mod != null or not int(z.kind) in HUNT_KINDS
		if special and (not bool(z._chasing) or (z.type_mod != null and z.type_mod.has_method("can_bite") and not z.type_mod.can_bite())):
			continue
		var d: Vector2 = z.global_position - mp
		if absf(d.x) < HUNT_RANGE.x or absf(d.x) > HUNT_RANGE.y or absf(d.y) > 160.0:
			continue
		cands.append([absf(d.x) + (400.0 if special else 0.0), z])   # רגילים קודם
	if cands.is_empty():
		_hunt_t = 1.5   # אין אף אחד קרוב - בודקים שוב בקרוב
		return
	cands.sort_custom(func(a, b): return a[0] < b[0])
	for i in mini(want, cands.size()):
		var z = cands[i][1]
		var gx := medic.global_position.x
		z.goal_x = gx
		hunters[z.get_instance_id()] = {"z": z, "t": HUNT_T, "gx": gx, "chk": HUNT_CHECK, "d0": absf(float(z.global_position.x) - gx)}
	_marks_dirty = true
	medic.say("THEY'RE COMING FOR ME!" if cands.size() > 1 and HUNTERS[_diff] > 1 else "HE'S AFTER ME!", Color(1.0, 0.75, 0.6))
	Sfx.play("zscream", cands[0][1].global_position, -2.0, 0.08, 2)


func _release(z) -> void:
	if is_instance_valid(z) and not z.dead:
		z.goal_x = INF
		z._alert_t = 3.0   # חוזר לרדוף אחריך


func _release_all() -> void:
	for id in hunters:
		_release(hunters[id].z)
	hunters.clear()
	_marks_dirty = true


# נשיכות: זומבי ער שנוגע בה (כמו הנשיכה ב-zombie.gd, אבל עליה)
func _bites() -> void:
	if not medic.can_be_hurt():
		return
	var mp := medic.global_position
	var now := Time.get_ticks_msec() / 1000.0
	for z in get_tree().get_nodes_in_group("zombies"):
		if not z.has_method("is_boss") or z.dead or z.dormant or z.is_boss() or z.on_ceiling:
			continue
		var d: Vector2 = z.global_position - mp
		if absf(d.x) > BITE_REACH.x * float(z.wf) or absf(d.y) > BITE_REACH.y:
			continue
		var hunting := hunters.has(z.get_instance_id())
		if not hunting and not bool(z._chasing):
			continue
		if int(z.kind) in [ZombieScript.BOSS, ZombieScript.BLOATER, ZombieScript.MECH, ZombieScript.HOUND, ZombieScript.GUNNER]:
			continue
		if z.type_mod != null and z.type_mod.has_method("can_bite") and not z.type_mod.can_bite():
			continue
		if now < float(z.get_meta("esc_bite", 0.0)):
			continue
		z.set_meta("esc_bite", now + BITE_CD)
		z._bite_anim = 0.25
		medic.hurt(1, signf(-d.x) if d.x != 0.0 else 1.0)
		if not medic.alive():
			return


# ---------------- ציור ----------------
func _banner(text: String, sub: String, col: Color, dur: float, delay: float) -> void:
	_banners.append({"text": text, "sub": sub, "col": col, "t": 0.0, "dur": dur, "delay": delay})


func _draw_ui() -> void:
	DrawBatch.begin(_ui)
	_draw_ui_b()
	DrawBatch.end(_ui)


func _draw_ui_b() -> void:
	var vs := _ui.get_viewport().get_visible_rect().size
	var f := KillStreak.font()
	var y := vs.y * 0.27
	for b in _banners:
		var k: float = b.t - b.delay
		if k < 0.0:
			continue
		var dur: float = b.dur
		var a := clampf(k / 0.25, 0.0, 1.0) * clampf((dur - k) / 0.45, 0.0, 1.0)
		if a <= 0.0:
			continue
		var big: bool = b.sub.begins_with("+") or b.text.begins_with("SURVIVOR")
		var fs := 46 if big else 30
		var pop := 1.0 + 0.25 * clampf(1.0 - k / 0.18, 0.0, 1.0)   # "קופץ" (סקייל, לא גודל פונט)
		var text: String = b.text
		var sub: String = b.sub
		var w := f.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		var sw := f.get_string_size(sub, HORIZONTAL_ALIGNMENT_LEFT, -1, 18).x if sub != "" else 0.0
		var bw := maxf(w, sw) + 44.0
		var bh := float(fs) + 22.0 + (24.0 if sub != "" else 0.0)
		var col: Color = b.col
		DrawBatch.set_transform(_ui, Vector2(vs.x * 0.5, y), 0.0, Vector2(pop, pop))
		DrawBatch.rect(_ui, Rect2(-bw * 0.5, -bh * 0.5, bw, bh), Color(0.04, 0.04, 0.06, 0.78 * a))
		DrawBatch.rect(_ui, Rect2(-bw * 0.5, -bh * 0.5, bw, bh), Color(col, a), false, 3.0)
		DrawBatch.rect(_ui, Rect2(-bw * 0.5, -bh * 0.5, 8.0, bh), Color(col, 0.9 * a))
		_cross(Vector2(-bw * 0.5 + 15.0, -bh * 0.5 + float(fs) * 0.5 + 9.0), 9.0, Color(col.lightened(0.4), a))
		var tp := Vector2(-w * 0.5, -bh * 0.5 + float(fs) + 6.0)
		DrawBatch.string_outline(_ui, f, tp, text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, 6, Color(0, 0, 0, a))
		DrawBatch.string(_ui, f, tp, text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(col.lightened(0.3), a))
		if sub != "":
			DrawBatch.string(_ui, f, Vector2(-sw * 0.5, tp.y + 24.0), sub, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(0.92, 0.92, 0.95, 0.95 * a))
		DrawBatch.set_transform(_ui, Vector2.ZERO)
		y += bh + 12.0


func _cross(c: Vector2, s: float, col: Color) -> void:
	DrawBatch.rect(_ui, Rect2(c.x - s * 0.18, c.y - s * 0.5, s * 0.36, s), col)
	DrawBatch.rect(_ui, Rect2(c.x - s * 0.5, c.y - s * 0.18, s, s * 0.36), col)


# סימן אדום מעל זומבי שצד אותה (ושורת "קו" עדינה אליה כשהוא קרוב)
func _draw_marks() -> void:
	DrawBatch.begin(_marks)
	_draw_marks_b()
	DrawBatch.end(_marks)


func _draw_marks_b() -> void:
	var t := Time.get_ticks_msec() / 1000.0
	for id in hunters:
		var z = hunters[id].z
		if not is_instance_valid(z) or z.dead:
			continue
		var top: Vector2 = z.global_position + Vector2(0.0, -78.0 * float(z.sc))
		var bob := sin(t * 9.0) * 3.0
		var c := top + Vector2(0.0, bob)
		var pulse := 0.6 + 0.4 * sin(t * 12.0)
		var tri := PackedVector2Array([c + Vector2(-9, -12), c + Vector2(9, -12), c + Vector2(0, 0)])
		DrawBatch.colored_polygon(_marks, PackedVector2Array([c + Vector2(-12, -15), c + Vector2(12, -15), c + Vector2(0, 3)]), Color(0, 0, 0, 0.7))
		DrawBatch.colored_polygon(_marks, tri, Color(1.0, 0.18 + 0.2 * pulse, 0.12, 0.95))
		# כוונת קטנה: "הוא הולך עליה"
		DrawBatch.arc(_marks, c + Vector2(0, -24), 6.0, 0.0, TAU, 14, Color(1.0, 0.3, 0.2, 0.8 * pulse), 2.0)
		if medic != null and medic.global_position.distance_to(z.global_position) < 420.0:
			var a: Vector2 = z.global_position + Vector2(0, -30)
			var b := medic.global_position + Vector2(0, -30)
			var n := 8
			for i in n:
				if i % 2 == 0:
					DrawBatch.line(_marks, a.lerp(b, float(i) / n), a.lerp(b, float(i + 1) / n), Color(1.0, 0.25, 0.2, 0.35), 2.0)


# ============================================================
#  MEDIC - החובשת. (0,0) = כפות הרגליים. שכבת התנגשות 0: קליעים / זומבים / השחקן עוברים דרכה.
#  מתנגשת רק בקרקע (1) ובקומות (16).
# ============================================================
class Medic extends CharacterBody2D:
	enum { WAIT, FOLLOW, CLIMB, HIDE, EXTRACT, DEAD }
	const GRAVITY := 1500.0
	const JUMP := -600.0
	const CLIMB_SPEED := 170.0
	const SKIN := Color("d9a27a")
	const HAIR := Color("2e1d14")
	const JACKET := Color("e0662a")       # כתום בולט (נקרא גם על חול לבן וגם בלילה)
	const PANTS := Color("4b5636")
	const BOOTS := Color("221a14")
	const HELMET := Color("ecebe4")
	const PACK := Color("3b4232")
	const RED := Color("d0281e")

	var ev: Node = null
	var state := WAIT
	var hp := 5
	var max_hp := 5
	var world_w := 100000.0
	var _dir := 1.0
	var _t := 0.0
	var _phase := 0.0
	var _hurt_t := 0.0          # הבהוב אדום
	var _iframe := 0.0
	var _say_cd := 0.0
	var _heart_pop := 0.0
	var _pl_y := 0.0            # הגובה האחרון שבו השחקן עמד
	var _ladder: Node2D = null
	var _drop_t := 0.0
	var _stuck_t := 0.0
	var _best_d := INF
	var _dead_t := 0.0
	var _angle := 0.0
	var _exit_x := 0.0
	var _ext_t := 0.0
	var _called := false
	var _still_t := 0.0
	var _last_pos := Vector2.ZERO
	var _shape: CollisionShape2D

	func _ready() -> void:
		add_to_group("escort_medic")
		collision_layer = 0
		collision_mask = 1 | 16
		floor_snap_length = 10.0
		_shape = CollisionShape2D.new()
		var r := RectangleShape2D.new()
		r.size = Vector2(14, 42)
		_shape.shape = r
		_shape.position = Vector2(0, -21)
		add_child(_shape)
		z_index = 3
		_t = randf() * 4.0

	func alive() -> bool:
		return state != DEAD

	func can_be_hurt() -> bool:
		return state == FOLLOW or state == CLIMB

	func join(shout := true) -> void:
		state = FOLLOW
		var p: Node2D = ev.player()
		if p != null:
			_pl_y = p.global_position.y
		ev._hunt_t = HUNT_FIRST
		if shout:
			say("FINALLY! GET ME OUT OF HERE!", Color(1.0, 0.92, 0.7))
			Sfx.play("pickup", global_position, -2.0)

	func say(text: String, col := Color(1, 1, 1)) -> void:
		if _say_cd > 0.0:
			return
		_say_cd = 2.2
		var p = ZombieScript.HitText.new()
		p.text = text
		p.color = col
		p.size = 15
		p.life = 1.6
		get_parent().add_child(p)
		p.global_position = global_position + Vector2(0, -84)

	func hurt(amount: int, from_dir: float) -> void:
		if not can_be_hurt() or _iframe > 0.0:
			return
		hp -= amount
		_iframe = IFRAME
		_hurt_t = 0.25
		_heart_pop = 0.35
		velocity.x = from_dir * 140.0
		Sfx.play("hurt", global_position, 0.0, 0.08, 3, 1.45)
		for i in 4:
			var b = BloodScript.new()
			get_parent().add_child(b)
			b.setup(global_position + Vector2(0, -28), Vector2(randf_range(-160.0, 160.0), randf_range(-260.0, -80.0)))
		if hp <= 0:
			_die(from_dir)
			return
		var lines := ["HELP!", "GET IT OFF ME!", "I'M HIT!", "SHOOT IT!"]
		say(lines[randi() % lines.size()] if hp > 1 else "I CAN'T TAKE MUCH MORE!", Color(1.0, 0.6, 0.55))

	func _die(from_dir: float) -> void:
		state = DEAD
		_dir = -from_dir if from_dir != 0.0 else _dir
		velocity = Vector2(from_dir * 120.0, -160.0)
		collision_mask = 1
		ev.on_medic_dead()

	func extract(x: float) -> void:
		state = EXTRACT
		_exit_x = x
		collision_mask = 1 | 16
		say("THANK YOU!", Color(0.7, 1.0, 0.75))

	# ---------------- תנועה ----------------
	func _physics_process(delta: float) -> void:
		_t += delta
		_hurt_t -= delta
		_iframe -= delta
		_say_cd -= delta
		_heart_pop -= delta
		if _drop_t > 0.0:
			_drop_t -= delta
			if _drop_t <= 0.0 and state != CLIMB:
				collision_mask = 1 | 16
		var p: Node2D = ev.player()
		if state == CLIMB:
			_climb(delta)
			_redraw()
			return
		if not is_on_floor():
			velocity.y += GRAVITY * delta
		match state:
			WAIT:
				velocity.x = move_toward(velocity.x, 0.0, 900.0 * delta)
				if p != null and not p.dead:
					var dx: float = p.global_position.x - global_position.x
					_dir = signf(dx) if dx != 0.0 else _dir
					if absf(dx) < 700.0 and not _called:
						_called = true
						say("OVER HERE! DON'T LEAVE ME!", Color(1.0, 0.92, 0.7))
					if (absf(dx) < JOIN_DIST and absf(p.global_position.y - global_position.y) < 200.0) or dx > 150.0:
						if dx > 400.0:   # השחקן כבר עבר אותה (טלפורט / נקודת ביקורת)
							_teleport(p)
						join()
			FOLLOW, HIDE:
				_follow(delta, p)
			EXTRACT:
				_ext_t += delta
				var gx := _exit_x - global_position.x
				_dir = signf(gx) if absf(gx) > 4.0 else _dir
				velocity.x = move_toward(velocity.x, SPRINT * _dir if absf(gx) > 10.0 else 0.0, 1400.0 * delta)
				if is_on_wall() and is_on_floor():
					velocity.y = JUMP
				if absf(gx) < 14.0 or _ext_t > 6.0:
					modulate.a = move_toward(modulate.a, 0.0, delta * 1.5)
					if modulate.a <= 0.0:
						queue_free()
						return
			DEAD:
				_dead_t += delta
				if is_on_floor():
					velocity.x = move_toward(velocity.x, 0.0, 700.0 * delta)
					_angle = lerp_angle(_angle, PI / 2.0 * -_dir, 7.0 * delta)
				else:
					_angle += -_dir * 5.0 * delta
				if _dead_t > 12.0:
					modulate.a = clampf(14.0 - _dead_t, 0.0, 1.0)
					if _dead_t > 14.0:
						queue_free()
						return
		var want_move := absf(velocity.x) > 40.0 and (state == FOLLOW or state == HIDE or state == EXTRACT)
		move_and_slide()
		_unstick(delta, want_move)
		global_position.x = clampf(global_position.x, 15.0, world_w - 15.0)
		if is_on_floor() and absf(velocity.x) > 20.0:
			_phase += delta * absf(velocity.x) * 0.075
		_redraw()

	func _redraw() -> void:
		if Art.on_screen(self, global_position):
			queue_redraw()

	func _follow(delta: float, p: Node2D) -> void:
		if p == null or p.dead or ev.main.clock_paused:
			velocity.x = move_toward(velocity.x, 0.0, 900.0 * delta)
			return
		var px: float = p.global_position.x
		if p.is_on_floor() or bool(p._climbing):
			_pl_y = p.global_position.y
		var target := px
		var near := false
		if ev.boss_hide():   # הבוס: מחכה לפני הזירה
			if state != HIDE:
				state = HIDE
				say("I'LL STAY DOWN HERE!", Color(1.0, 0.92, 0.7))
			target = ev.hide_x
			near = absf(target - global_position.x) < 14.0
			if absf(target - global_position.x) > 500.0 and not Art.on_screen(self, global_position, 40.0):
				global_position = Vector2(target, ev._ground_y(target) - 2.0)
				velocity = Vector2.ZERO
				return
		else:
			if state == HIDE:
				state = FOLLOW
			var side := signf(global_position.x - px)
			if side == 0.0:
				side = -1.0
			target = px + side * FOLLOW_DIST
			var adx := absf(px - global_position.x)
			near = adx <= FOLLOW_DIST + 25.0 and adx >= 24.0
			# קומות: השחקן מעליה -> סולם (או קפיצה גבוהה). מתחתיה -> יורדת דרך הקומה
			var dy := _pl_y - global_position.y
			if is_on_floor() and dy < -50.0 and p.is_on_floor():
				var l := _find_ladder(_pl_y)
				if l != null:
					target = l.global_position.x
					near = false
					if absf(target - global_position.x) < 9.0:
						_ladder = l
						state = CLIMB
						collision_mask = 0
						velocity = Vector2.ZERO
						return
				elif absf(px - global_position.x) < 170.0 and -dy < 270.0:
					velocity.y = -sqrt(2.0 * GRAVITY * (-dy + 34.0))
					velocity.x = signf(px - global_position.x) * 120.0
			elif dy > 60.0 and is_on_floor() and _drop_t <= 0.0 and absf(px - global_position.x) < 400.0:
				collision_mask = 1
				_drop_t = 0.35
				velocity.y = 60.0
			_stuck_check(delta, p)
		var dx := target - global_position.x
		var spd := SPRINT if absf(px - global_position.x) > 260.0 else WALK
		if near or absf(dx) < 8.0:
			velocity.x = move_toward(velocity.x, 0.0, 1400.0 * delta)
			if state == FOLLOW and absf(px - global_position.x) > 4.0:
				_dir = signf(px - global_position.x)
		else:
			_dir = signf(dx)
			velocity.x = move_toward(velocity.x, _dir * spd, 1500.0 * delta)
			if is_on_floor():
				if is_on_wall():   # מכשול: קופצת
					velocity.y = JUMP
				elif absf(velocity.x) > 60.0 and not _ground_ahead():   # בור: קופצת מעליו
					velocity.y = JUMP * 0.92

	func _ground_ahead() -> bool:
		var ss := get_world_2d().direct_space_state
		var a := global_position + Vector2(_dir * 30.0, -8.0)
		var q := PhysicsRayQueryParameters2D.create(a, a + Vector2(0, 90.0), collision_mask)
		return not ss.intersect_ray(q).is_empty()

	# סולם שמוביל לקומה של השחקן (התחתית בגובה שלה)
	func _find_ladder(top: float) -> Node2D:
		var best: Node2D = null
		var bd := 520.0
		for l in get_tree().get_nodes_in_group("ladders"):
			var l2 := l as Node2D
			if l2 == null or absf(float(l2.top_y()) - top) > 24.0 or absf(l2.global_position.y - global_position.y) > 40.0:
				continue
			var d := absf(l2.global_position.x - global_position.x)
			if d < bd:
				bd = d
				best = l2
		return best

	func _climb(delta: float) -> void:
		if _ladder == null or not is_instance_valid(_ladder):
			state = FOLLOW
			collision_mask = 1 | 16
			return
		var top: float = _ladder.top_y()
		global_position.x = move_toward(global_position.x, _ladder.global_position.x, 80.0 * delta)
		global_position.y -= CLIMB_SPEED * delta
		_phase += delta * 9.0
		if global_position.y <= top - 2.0:
			global_position.y = top - 3.0
			collision_mask = 1 | 16
			velocity = Vector2(_dir * 60.0, -140.0)
			state = FOLLOW
			_ladder = null

	# נתקעה / נשארה מאחור -> טלפורט לידך (רק כשהשחקן עומד על משהו)
	func _stuck_check(delta: float, p: Node2D) -> void:
		var d := global_position.distance_to(p.global_position)
		var far := absf(p.global_position.x - global_position.x) > FOLLOW_DIST + 110.0 or absf(_pl_y - global_position.y) > 70.0
		if not far:
			_stuck_t = 0.0
			_best_d = d
			return
		if d < _best_d - 30.0:
			_best_d = d
			_stuck_t = 0.0
		else:
			_stuck_t += delta
		if not (p.is_on_floor() and not bool(p._climbing)):
			return
		var off := not Art.on_screen(self, global_position, 30.0)
		if d > TP_FAR or global_position.y > ev.floor_y + 200.0 or (_stuck_t > STUCK_T and off) or _stuck_t > STUCK_FORCE:
			_teleport(p)

	func _teleport(p: Node2D) -> void:
		var side := -signf(p.velocity.x) if absf(p.velocity.x) > 30.0 else signf(global_position.x - p.global_position.x)
		if side == 0.0:
			side = -1.0
		var spot := p.global_position + Vector2(0, -2.0)
		for sx in [side * 60.0, -side * 60.0, side * 25.0]:   # מקום פנוי ליד השחקן, על פני הקרקע
			var gy := _ground_at(p.global_position.x + sx, p.global_position.y)
			var at := Vector2(p.global_position.x + sx, gy - 1.0)
			if gy < INF and not _blocked(at):
				spot = at
				break
		if Art.on_screen(self, global_position, 0.0):
			Particles.burst(get_parent(), global_position + Vector2(0, -20), "smoke", Vector2.ZERO, 6)
		global_position = spot
		velocity = Vector2.ZERO
		collision_mask = 1 | 16
		_stuck_t = 0.0
		_best_d = INF
		Particles.burst(get_parent(), spot + Vector2(0, -20), "smoke", Vector2.ZERO, 5)

	func _blocked(at: Vector2) -> bool:
		var q := PhysicsShapeQueryParameters2D.new()
		var r := RectangleShape2D.new()
		r.size = Vector2(12, 34)
		q.shape = r
		q.transform = Transform2D(0.0, at + Vector2(0, -24))
		q.collision_mask = 1
		return not get_world_2d().direct_space_state.intersect_shape(q, 1).is_empty()

	# פני הקרקע / הקומה מתחת לנקודה (INF = בור)
	func _ground_at(x: float, y: float) -> float:
		var q := PhysicsRayQueryParameters2D.create(Vector2(x, y - 90.0), Vector2(x, y + 60.0), 1 | 16)
		var hit := get_world_2d().direct_space_state.intersect_ray(q)
		return INF if hit.is_empty() else float(hit.position.y)

	# רוצה לזוז ולא זזה (נתקעה בתוך מדרון / פינה) -> דחיפה קטנה למעלה
	func _unstick(delta: float, moving: bool) -> void:
		if not moving or global_position.distance_to(_last_pos) > 0.6:
			_still_t = 0.0
		else:
			_still_t += delta
			if _still_t > 0.5:
				global_position.y -= 6.0
				velocity.y = minf(velocity.y, -200.0)
				_still_t = 0.2
		_last_pos = global_position

	# ---------------- ציור ----------------
	func _draw() -> void:
		DrawBatch.begin(self)
		_draw_b()
		DrawBatch.end(self)

	func _draw_b() -> void:
		if state == DEAD:
			var outer := Transform2D(_angle, Vector2(0, -8))
			DrawBatch.set_transform_matrix(self, outer * Transform2D(0.0, Vector2(_dir * SIZE, SIZE), 0.0, Vector2(0, 26.0 * SIZE)))
			_body()
			DrawBatch.set_transform_matrix(self, Transform2D.IDENTITY)
			return
		if is_on_floor():
			Art.ground_shadow(self, Vector2.ZERO, 12.0 * SIZE)
		DrawBatch.set_transform(self, Vector2.ZERO, 0.0, Vector2(_dir * SIZE, SIZE))
		_body()
		DrawBatch.set_transform_matrix(self, Transform2D.IDENTITY)
		if state == WAIT:
			_radio_waves()
		elif state != EXTRACT:
			_hearts()

	# "אני כאן": גלי רדיו מהקשר + חץ קטן
	func _radio_waves() -> void:
		var c := Vector2(-8.0 * _dir * SIZE, -76.0 * SIZE)
		for i in 3:
			var k := fmod(_t * 0.9 + float(i) / 3.0, 1.0)
			DrawBatch.arc(self, c, 5.0 + k * 16.0, -PI * 0.85, -PI * 0.15, 10, Color(1.0, 0.85, 0.3, 0.8 * (1.0 - k)), 2.0)
		var b := Vector2(0, -96.0 + sin(_t * 5.0) * 3.0)
		DrawBatch.colored_polygon(self, PackedVector2Array([b + Vector2(-8, -10), b + Vector2(8, -10), b]), Color(0, 0, 0, 0.6))
		DrawBatch.colored_polygon(self, PackedVector2Array([b + Vector2(-6, -9), b + Vector2(6, -9), b + Vector2(0, -2)]), Color(0.45, 1.0, 0.55))

	# לבבות + פס חיים מעל הראש
	func _hearts() -> void:
		var n := max_hp
		var hw := 9.0
		var gap := 2.0
		var total := float(n) * hw + float(n - 1) * gap
		var y := -70.0
		var x0 := -total * 0.5
		var frac := clampf(float(hp) / float(max_hp), 0.0, 1.0)
		DrawBatch.rect(self, Rect2(x0 - 2.0, y + 6.0, total + 4.0, 5.0), Color(0, 0, 0, 0.75))
		var bar := Color(0.95, 0.25, 0.2).lerp(Color(0.4, 0.95, 0.4), frac)
		DrawBatch.rect(self, Rect2(x0 - 1.0, y + 7.0, (total + 2.0) * frac, 3.0), bar)
		for i in n:
			var c := Vector2(x0 + float(i) * (hw + gap) + hw * 0.5, y)
			var full := i < hp
			var s := 0.32
			if i == hp and _heart_pop > 0.0:   # הלב שאבד: קופץ ודוהה
				s *= 1.0 + _heart_pop * 1.5
			_heart(c, s + 0.06, Color(0, 0, 0, 0.8))
			_heart(c, s, Color(0.92, 0.15, 0.18) if full else Color(0.25, 0.22, 0.24, 0.9))
		if _hurt_t > 0.0:
			DrawBatch.rect(self, Rect2(x0 - 2.0, y - 6.0, total + 4.0, 17.0), Color(1, 0.2, 0.2, _hurt_t * 1.2), false, 1.5)

	static var _heart_pts := PackedVector2Array()

	func _heart(c: Vector2, s: float, col: Color) -> void:
		if _heart_pts.is_empty():
			for i in 14:
				var t := TAU * float(i) / 14.0
				_heart_pts.append(Vector2(16.0 * pow(sin(t), 3), -(13.0 * cos(t) - 5.0 * cos(2.0 * t) - 2.0 * cos(3.0 * t) - cos(4.0 * t))) / 16.0)
		DrawBatch.colored_polygon(self, Transform2D(0.0, Vector2(s * 14.0, s * 14.0), 0.0, c) * _heart_pts, col)

	# החובשת: קסדה לבנה עם צלב, מעיל כתום, קשר על הגב עם אנטנה, מכנסיים זיתיים
	func _body() -> void:
		var flash := _hurt_t > 0.0 and int(_t * 30.0) % 2 == 0
		var p := _phase
		var running := (state == FOLLOW or state == HIDE or state == EXTRACT) and is_on_floor() and absf(velocity.x) > 20.0
		var crouch := state == HIDE and absf(velocity.x) < 20.0
		var climbing := state == CLIMB
		var lean := 6.0 if running else 0.0
		var breath := sin(_t * 2.2) * 0.5
		var hip := Vector2(0, -25.0 - (absf(sin(p)) * 1.6 if running else 0.0))
		if crouch:
			hip = Vector2(-3.0, -15.0)
		var sh := hip + Vector2(lean + 1.0, -16.5 + breath)
		if crouch:
			sh = hip + Vector2(6.0, -13.0)
		var head := sh + Vector2(2.2, -8.0)
		# רגליים
		var f1 := Vector2(2.0, 0.0)
		var f2 := Vector2(-3.0, 0.0)
		if running:
			f1 = Vector2(sin(p) * 10.0 + 2.0, -maxf(0.0, cos(p)) * 5.5)
			f2 = Vector2(sin(p + PI) * 10.0, -maxf(0.0, cos(p + PI)) * 5.5)
		elif climbing:
			f1 = Vector2(2.0, -6.0 - absf(sin(p)) * 7.0)
			f2 = Vector2(-1.0, -6.0 - absf(cos(p)) * 7.0)
		elif crouch:
			f1 = Vector2(6.0, 0.0)
			f2 = Vector2(-8.0, 0.0)
		elif not is_on_floor() and state != DEAD:
			f1 = Vector2(6.0, -9.0)
			f2 = Vector2(-5.0, -6.0)
		# ידיים
		var bs := sh + Vector2(-2.0, 1.5)
		var fs := sh + Vector2(2.0, 1.5)
		var bh := bs + Vector2(-2.0, 15.0)
		var fh := fs + Vector2(3.0, 15.0)
		if running:
			bh = bs + Vector2(-sin(p) * 10.0, 12.0)
			fh = fs + Vector2(sin(p) * 10.0 + 2.0, 11.0)
		elif climbing:
			bh = bs + Vector2(3.0, -12.0 - absf(cos(p)) * 4.0)
			fh = fs + Vector2(4.0, -12.0 - absf(sin(p)) * 4.0)
		elif state == WAIT:   # מחזיקה את מכשיר הקשר ליד הפה ומנופפת ביד השנייה
			fh = sh + Vector2(7.0, -1.5)
			bh = bs + Vector2(-4.0 + sin(_t * 7.0) * 3.0, -15.0)
		elif crouch:
			fh = fs + Vector2(9.0, 8.0)
			bh = bs + Vector2(6.0, 9.0)
		var skin := SKIN
		var jacket := JACKET
		var pants := PANTS
		if flash:
			skin = Color(1, 0.75, 0.7)
			jacket = Color(1, 0.55, 0.45)
			pants = Color(0.9, 0.5, 0.45)
		# קשר על הגב + אנטנה (מתנדנדת)
		var pack := PackedVector2Array([sh + Vector2(-10.0, -1.0), sh + Vector2(-3.0, -2.0), hip + Vector2(-2.0, -5.0), hip + Vector2(-9.5, -4.0)])
		Art.fill_shaded(self, pack, PACK, 0.2, 0.3, Art.OUTLINE, 1.0)
		var sway := sin(_t * (11.0 if running else 2.0)) * (3.0 if running else 1.0)
		var ant0 := sh + Vector2(-8.0, -1.5)
		var ant1 := ant0 + Vector2(-6.0 - lean * 0.6 + sway, -24.0)
		DrawBatch.line(self, ant0, ant1, Color(0.05, 0.05, 0.06), 1.4, true)
		var blink := 1.0 if fmod(_t, 1.0) < 0.5 else 0.35
		DrawBatch.circle(self, ant1, 1.6, Color(1.0, 0.2, 0.15, blink))
		DrawBatch.rect(self, Rect2(sh.x - 8.0, sh.y + 5.0, 4.0, 2.0), Color(0.5, 1.0, 0.5, 0.9))   # נורית
		_arm(bs, bh, Art.shade(skin, 0.15), Art.shade(jacket, 0.18), false)
		_leg(hip + Vector2(-1.5, 0), f2, Art.shade(pants, 0.2), BOOTS.darkened(0.2))
		_leg(hip + Vector2(1.5, 0), f1, pants, BOOTS)
		# מעיל
		var body := PackedVector2Array([
			sh + Vector2(-5.4, -0.4), sh + Vector2(5.0, 0.0), sh + Vector2(5.8, 4.0), hip + Vector2(4.6, -4.0),
			hip + Vector2(5.2, 2.0), hip + Vector2(-5.2, 2.0), hip + Vector2(-4.6, -4.0), sh + Vector2(-5.8, 3.8),
		])
		Art.fill_shaded(self, body, jacket, 0.15, 0.3, Art.OUTLINE, 1.0)
		# פס מחזיר אור + צלב אדום על החזה
		DrawBatch.line(self, sh.lerp(hip, 0.62) + Vector2(-5.0, 0.0), sh.lerp(hip, 0.62) + Vector2(5.0, 0.0), Color(0.92, 0.95, 0.9), 1.8)
		var cc := sh + Vector2(1.5, 5.0)
		DrawBatch.rect(self, Rect2(cc.x - 2.8, cc.y - 2.8, 5.6, 5.6), Color(0.98, 0.98, 0.96))
		DrawBatch.rect(self, Rect2(cc.x - 0.7, cc.y - 2.2, 1.4, 4.4), RED)
		DrawBatch.rect(self, Rect2(cc.x - 2.2, cc.y - 0.7, 4.4, 1.4), RED)
		DrawBatch.line(self, hip + Vector2(-5.0, -1.0), hip + Vector2(5.0, -1.0), Color("2a2a22"), 1.6, true)   # חגורה
		# צוואר + ראש + קסדה
		Art.limb(self, PackedVector2Array([sh + Vector2(1.0, 0.0), head + Vector2(-0.5, 4.0)]), 2.6, skin)
		Art.oval(self, head + Vector2(-5.0, 1.5), 2.6, 2.4, HAIR)   # פקעת שיער מאחור
		Art.oval_shaded(self, head, 5.0, 5.8, skin, 0.0, Art.OUTLINE, 0.9)
		var eye := head + Vector2(2.8, -0.2)
		DrawBatch.circle(self, eye, 0.9, Color("1a1010"))
		DrawBatch.line(self, eye + Vector2(-1.1, -1.7), eye + Vector2(1.4, -1.9), HAIR, 0.7, true)
		DrawBatch.line(self, head + Vector2(3.3, 3.2), head + Vector2(4.1, 3.0), Color("8a4a40"), 0.6, true)
		var hel := PackedVector2Array([head + Vector2(-6.4, -0.2), head + Vector2(-5.8, -4.6), head + Vector2(-2.0, -7.6), head + Vector2(2.6, -7.6),
			head + Vector2(6.0, -4.4), head + Vector2(6.8, -1.2), head + Vector2(-6.4, -1.2)])
		Art.fill_shaded(self, hel, HELMET if not flash else Color(1, 0.7, 0.7), 0.1, 0.25, Art.OUTLINE, 1.0)
		var hc := head + Vector2(0.4, -4.3)
		DrawBatch.rect(self, Rect2(hc.x - 0.75, hc.y - 2.3, 1.5, 4.6), RED)
		DrawBatch.rect(self, Rect2(hc.x - 2.3, hc.y - 0.75, 4.6, 1.5), RED)
		DrawBatch.line(self, head + Vector2(-5.0, 0.0), head + Vector2(-2.0, 5.0), Color(0.1, 0.1, 0.1), 0.7, true)   # רצועת סנטר
		_arm(fs, fh, skin, jacket, true)
		if state == WAIT:   # מכשיר הקשר ביד
			Art.fill(self, PackedVector2Array([fh + Vector2(-1.0, -7.0), fh + Vector2(2.2, -7.0), fh + Vector2(2.2, 1.5), fh + Vector2(-1.0, 1.5)]), Color(0.12, 0.12, 0.13), Art.OUTLINE, 0.6)
			DrawBatch.line(self, fh + Vector2(1.6, -7.0), fh + Vector2(2.4, -11.0), Color(0.05, 0.05, 0.06), 0.8, true)

	func _arm(shoulder: Vector2, hand: Vector2, skin: Color, sleeve: Color, armband: bool) -> void:
		var elbow := Art.joint(shoulder, hand, 8.0, 8.0, -1.0)
		var cuff := elbow.lerp(hand, 0.55)
		Art.limb(self, PackedVector2Array([cuff, hand]), 2.5, skin)
		Art.limb(self, PackedVector2Array([shoulder, elbow, cuff]), 3.5, sleeve)
		if armband:   # סרט זרוע לבן
			var m := shoulder.lerp(elbow, 0.55)
			DrawBatch.circle(self, m, 2.2, Color(0.97, 0.97, 0.95))
			DrawBatch.circle(self, m, 0.9, RED)
		Art.disc(self, hand, 1.6, skin, Art.OUTLINE, 0.7)

	func _leg(hip: Vector2, foot: Vector2, pants: Color, boots: Color) -> void:
		var ankle := foot + Vector2(0, -3.0)
		var knee := Art.joint(hip, ankle, 11.0, 10.8, 1.0)
		Art.limb(self, PackedVector2Array([hip, knee, ankle]), 4.0, pants)
		Art.limb(self, PackedVector2Array([knee.lerp(ankle, 0.45), ankle]), 4.4, boots)
		Art.fill(self, PackedVector2Array([foot + Vector2(-2.2, -3.2), foot + Vector2(1.8, -3.2), foot + Vector2(5.0, -1.0), foot + Vector2(5.0, 0.0), foot + Vector2(-2.6, 0.0)]), boots, Art.OUTLINE, 0.8)
