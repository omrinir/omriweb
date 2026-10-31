extends "res://enemies/zombie_type.gd"
# ============================================================
#  DAMBUILDER (שלב 59, "BLACK FOREST") - לוכד מת עטוף בעורות בונים (הבונים הם מכת היער בטיירה דל פואגו - הם
#    הרסו אותו לפני האש). גולגולת בונה על הראש עם שיני כתום ענקיות, זנב שטוח תלוי מאחור, גורר בולי עץ שרופים על הכתף.
#  מה הם למדו: "THEY BUILD COVER NOW". הגיבור התחבא מאחורי מכוניות, ארגזים וקירות בכל שלב - וכל מי שמת מול מחסה
#    נשף את מה שראה: מי שמאחורי קיר - חי. אז הם בונים קירות. כמו בונים.
#  מחזור:
#    SEEK     - אתה בטווח: בוחר נקודה בינך לבינו (BUILD_D ממך) ורץ אליה עם הבולים.
#    BUILD    - בונה סכר של בולים (Dam, BUILD_T) מולך - הקיר גדל (מחסה מוצק: עוצר כדורים, אותך ואת הזומבים).
#    COVER    - כפוף מאחורי הקיר (גוף קטן), וכל LOB_CD קם (WIND - הראש חשוף!) וזורק גחלת בקשת (Ember -> EmberPatch).
#    RELOCATE - הקיר נפל: לוקח בולים (LOGS) ובונה שוב, רחוק יותר. אין בולים / עקפת אותו -> FIGHT.
#    FIGHT    - נלחם מקרוב: מכת זנב (TAIL_*).
#  הקיר (Dam): DAM_HP. כדורים שוברים בולים (רסיסי עץ). אש (קליע אש / קו אש) - בוער (DAM_BURN_T) ונשרף מהר, ומצית זומבים
#    שליד הקיר (CHARRED שמח). פיצוץ = כמעט מפרק אותו (DAM_BLAST). מכשולים / בריכות / קווי אש - לא בונה עליהם.
#  "THEY LEARN" (main meta "db_broken" - כמה קירות שברת) >= LEARN: "IT BUILDS BETTER NOW" -
#    בולים רטובים מהבריכות (לא נשרפים), קיר גבוה יותר עם חרך (WET_HP), בונה ליד מחסה קיים (מכשול / גזע שנפל) ובולים לקיר נוסף.
#  צלילים: "db_chop", "db_knock", "db_lob", "db_crash", "db_slap", "db_chitter".
#  לשנות: BUILD_D, BUILD_T, LOB_CD, LOB_WIND, EMBER_DMG, DAM_HP, WET_HP, DAM_W, DAM_H, DAM_BURN_T, DAM_BLAST, LOGS, TAIL_R, TAIL_DMG, LEARN.
# ============================================================

const SOUNDS := {
	"db_chop": [["N", 0, 0, 0.0, 0.12, 0.0, 20.0, 0.6, 0.35, 0], ["S", 220, 120, 0.0, 0.1, 0.0, 22.0, 0.5, 1.0, 0], ["C", 0, 0, 0.0, 0.06, 0.0, 30.0, 0.5, 1.0, 0]],
	"db_knock": [["S", 380, 260, 0.0, 0.08, 0.0, 30.0, 0.5, 1.0, 0.1], ["N", 0, 0, 0.0, 0.06, 0.0, 40.0, 0.4, 0.4, 0]],
	"db_lob": [["N", 0, 0, 0.0, 0.3, 0.02, 7.0, 0.45, 0.4, 0.4, 0.2], ["C", 0, 0, 0.0, 0.3, 0.0, 8.0, 0.4, 1.0, 0]],
	"db_crash": {"drive": 2.0, "layers": [["C", 0, 0, 0.0, 0.5, 0.0, 6.0, 1.0, 1.0, 0], ["N", 0, 0, 0.0, 0.5, 0.0, 6.0, 0.8, 0.3, 0], ["S", 120, 50, 0.0, 0.4, 0.0, 7.0, 0.6, 1.0, 0], ["S", 300, 200, 0.05, 0.2, 0.0, 14.0, 0.3, 1.0, 0.1]]},
	"db_slap": [["N", 0, 0, 0.0, 0.12, 0.0, 22.0, 0.8, 0.3, 0], ["S", 140, 70, 0.0, 0.1, 0.0, 25.0, 0.6, 1.0, 0]],
	"db_chitter": {"drive": 1.8, "layers": [["V", 520, 640, 0.0, 0.08, 0.0, 20.0, 0.4, 1.0, 0.05, 0, [900, 2200, 40]], ["V", 560, 700, 0.1, 0.08, 0.0, 20.0, 0.35, 1.0, 0.05, 0, [900, 2200, 40]], ["V", 500, 620, 0.2, 0.1, 0.0, 18.0, 0.3, 1.0, 0.05, 0, [900, 2200, 40]]]},
}

const Decor := preload("res://effects/s59_decor.gd")
const CharredT := preload("res://enemies/types/charred.gd")
const DebrisScript := preload("res://debris.gd")

const SEE_R := 1000.0
const BUILD_D := 360.0            # כמה רחוק ממך הוא בונה
const MIN_D := 170.0              # אף פעם לא בונה קרוב מזה אליך
const BUILD_T := 1.6
const LOB_CD := Vector2(2.0, 2.8)
const LOB_WIND := 0.5
const EMBER_DMG := 1
const DAM_W := 34.0
const DAM_H := 50.0
const WET_H := 62.0
const DAM_HP := 90
const WET_HP := 120
const DAM_BURN_T := 4.0
const DAM_BURN_DPS := 18.0
const DAM_BLAST := 75
const LOGS := 2                   # כמה קירות נוספים יש לו
const TAIL_R := 44.0
const TAIL_WIND := 0.35
const TAIL_DMG := 1
const LEARN := 3

enum { SEEK, BUILD, COVER, WIND, RELOCATE, FIGHT, TAIL_W, TAIL }

# לבדיקות
var builds := 0
var walls_lost := 0
var lobs := 0
var lob_hits := 0
var embers_shot := 0
var slaps := 0
var slap_hits := 0
var wet_builds := 0

var state := SEEK
var dam: Node2D = null
var _spot := 0.0
var _st := 0.0
var _cd := 1.5
var _logs := LOGS
var _knock := 0.0
var _hit_done := false
var _seed := 0
var _met := false
var _learned := false
var _crouch := false
var _pelt := Color("6a4a30")
var _hat := true


func stats() -> Dictionary:
	return {"name": "DAMBUILDER", "hp": 40, "walk": 42.0, "chase": 80.0, "damage": 1, "bite_delay": 0.9, "scale": 1.04, "width": 1.15,
		"duck": 0.0, "cover": 0.0, "skin": Color("6a7a5a"), "shirt": _pelt, "pants": Color("3a3028"), "shoe": Color("2a2018"), "points": 450}


func use_brain_movement() -> bool:
	return false


func can_bite() -> bool:
	return state == FIGHT


func _main() -> Node:
	return z.get_parent()


func _stage() -> Node:
	var m := _main()
	return m.get("_stage") if m != null else null


static func is_learned(m: Node) -> bool:
	return m != null and int(m.get_meta("db_broken", 0)) >= LEARN


func setup() -> void:
	var r := RandomNumberGenerator.new()
	r.seed = z.get_instance_id() * 3 + 7
	_seed = r.randi()
	_pelt = [Color("6a4a30"), Color("5a3e28"), Color("7a5636"), Color("4a3422")][r.randi() % 4]
	_hat = r.randf() < 0.9
	_learned = is_learned(_main())
	if _learned:
		_logs = LOGS + 1


# ============================================================
#  תנועה
# ============================================================
func physics(pl: Node, delta: float) -> bool:
	_st -= delta
	_cd -= delta
	_knock = maxf(0.0, _knock - delta)
	if not z.is_on_floor():
		z.velocity.y += z.gravity * delta
	var has: bool = pl != null and not pl.dead
	var d: Vector2 = (pl.global_position - z.global_position) if has else Vector2(9999, 0)
	if not _met and has and (absf(d.x) < z.chase_range or z._alert_t > 0.0):
		_met = true
		z._noticed = true
		Sfx.play("db_chitter", z.global_position, -4.0, 0.1, 2)
	if dam != null and not is_instance_valid(dam):
		dam = null
	match state:
		SEEK:
			_seek(pl, has, d, delta)
		BUILD:
			z.velocity.x = move_toward(z.velocity.x, 0.0, 900.0 * delta)
			if has:
				z._dir = signf(d.x) if absf(d.x) > 4.0 else z._dir
			if dam == null:   # נשבר בזמן הבנייה
				_relocate(pl)
			elif _st <= 0.0:
				dam.progress = 1.0
				state = COVER
				_cd = randf_range(0.6, 1.2)
				_set_crouch(true)
			else:
				dam.progress = clampf(1.0 - _st / BUILD_T, 0.05, 1.0)
				if fmod(_st, 0.32) < delta:
					_knock = 0.12
					Sfx.play("db_knock" if randf() < 0.6 else "db_chop", z.global_position, -6.0, 0.2, 3)
		COVER:
			_cover(pl, has, d, delta)
		WIND:
			z.velocity.x = move_toward(z.velocity.x, 0.0, 900.0 * delta)
			if has:
				z._dir = signf(d.x) if absf(d.x) > 4.0 else z._dir
			if _st <= 0.0:
				if has:
					_lob(pl)
				state = COVER
				_cd = randf_range(LOB_CD.x, LOB_CD.y)
				_set_crouch(true)
		RELOCATE:
			_seek(pl, has, d, delta)
		FIGHT:
			_fight(pl, has, d, delta)
		TAIL_W:
			z.velocity.x = move_toward(z.velocity.x, 0.0, 900.0 * delta)
			if _st <= 0.0:
				state = TAIL
				_st = 0.2
				_hit_done = false
				slaps += 1
				Sfx.play("db_slap", z.global_position, 0.0, 0.1, 2)
		TAIL:
			if has and not _hit_done and absf(d.x) < TAIL_R + 14.0 and absf(d.y) < 50.0:
				_hit_done = true
				if pl._roll_t <= 0.0:
					slap_hits += 1
				pl.hurt(TAIL_DMG, Vector2(signf(d.x) * 1.4, -0.5))
			if _st <= 0.0:
				state = FIGHT
				_cd = randf_range(0.9, 1.4)
	z.move_and_slide()
	return true


func _seek(pl: Node, has: bool, d: Vector2, delta: float) -> void:
	var v := 0.0
	if has and _met and absf(d.x) < SEE_R:
		if _spot == 0.0:
			_spot = _pick_spot(pl)
			if _spot == 0.0:   # אין איפה לבנות
				_to_fight()
				return
		var to: float = _spot - z.global_position.x
		z._dir = signf(to) if absf(to) > 4.0 else signf(d.x)
		if absf(to) < 10.0 and z.is_on_floor():
			_start_build(pl)
			return
		v = signf(to) * float(z.chase_speed) * 1.2
		if absf(d.x) < 120.0:   # תפסת אותו בדרך
			_to_fight()
			return
	elif has and _met:   # רחוק: מתקרב לאט
		z._dir = signf(d.x) if absf(d.x) > 4.0 else z._dir
		v = z._dir * float(z.walk_speed)
	z.velocity.x = move_toward(z.velocity.x, v, 800.0 * delta)
	z._walk_phase += delta * absf(z.velocity.x) / 13.0
	if z.is_on_floor() and z.is_on_wall() and absf(z.velocity.x) < 20.0:
		z.velocity.y = -500.0


# נקודה בינך לבינו, BUILD_D ממך. לא על מים / אש / מכשול / קיר אחר. למד: ליד מחסה קיים
func _pick_spot(pl: Node) -> float:
	var px: float = pl.global_position.x
	var side := signf(z.global_position.x - px)
	if side == 0.0:
		side = 1.0
	var cands: Array = []
	if _learned:   # ליד מחסה קיים (מכשול / גזע שנפל / קיר אחר) בצד שלו
		for c in z.get_tree().get_nodes_in_group("cover"):
			if not c.has_method("cover_rect") or c.is_in_group("db_dams"):
				continue
			var r: Rect2 = c.cover_rect()
			var cx := r.position.x - DAM_W * 0.5 - 6.0 if side > 0.0 else r.end.x + DAM_W * 0.5 + 6.0
			var dd := (cx - px) * side
			if dd > MIN_D + 40.0 and dd < BUILD_D + 260.0:
				cands.append(cx)
	cands.append(px + side * BUILD_D)
	cands.append(px + side * (BUILD_D + 120.0))
	cands.append(px + side * (BUILD_D - 100.0))
	for x in cands:
		if _spot_ok(float(x), px):
			return float(x)
	return 0.0


func _spot_ok(x: float, px: float) -> bool:
	if absf(x - px) < MIN_D or x < 60.0:
		return false
	var st := _stage()
	if st != null:
		if x > float(st.level_w) - 60.0:
			return false
		if st.has_method("in_water_at") and bool(st.in_water_at(Vector2(x, float(st.floor_y)))):
			return false
		if st.has_method("story_stretch"):
			var ss: Vector2 = st.story_stretch()
			if x > ss.x - 60.0 and x < ss.y + 60.0:
				return false
	var r := Rect2(x - DAM_W * 0.5 - 20.0, z.global_position.y - 70.0, DAM_W + 40.0, 70.0)
	for f in z.get_tree().get_nodes_in_group("hazards"):
		if f.has_method("world_rect") and f.world_rect().grow(20.0).intersects(r):
			return false
	for c in z.get_tree().get_nodes_in_group("cover"):
		if c.has_method("cover_rect") and c.cover_rect().intersects(r):
			return false
	return true


func _start_build(pl: Node) -> void:
	state = BUILD
	_st = BUILD_T
	z.velocity.x = 0.0
	builds += 1
	var dm := Dam.new()
	dm.owner_t = self
	dm.wet = _learned
	dm.face = signf(pl.global_position.x - _spot)
	dm.progress = 0.05
	_main().add_child(dm)
	dm.global_position = Vector2(_spot, z.global_position.y)
	dam = dm
	if _learned:
		wet_builds += 1
	# הוא עומד מאחורי הקיר (הצד הרחוק ממך)
	z.global_position.x = _spot - dm.face * (DAM_W * 0.5 + 16.0)
	Sfx.play("db_chitter", z.global_position, -2.0, 0.1, 2)
	var m := _main()
	if _learned and m != null and not m.has_meta("db_told_better"):
		m.set_meta("db_told_better", true)
		z._popup("IT BUILDS BETTER NOW", Color("ff9a4a"), 14, -96.0)
		if pl != null and pl.has_method("_say"):
			pl._say("Wet logs... fire won't take them. And it builds behind cover.", Color("f0c890"))


func _cover(pl: Node, has: bool, d: Vector2, delta: float) -> void:
	z.velocity.x = move_toward(z.velocity.x, 0.0, 900.0 * delta)
	if dam == null:
		_relocate(pl)
		return
	if not has:
		return
	z._dir = signf(d.x) if absf(d.x) > 4.0 else z._dir
	# עקפת את הקיר / צמוד אליו -> נלחם
	var same_side: bool = signf(pl.global_position.x - dam.global_position.x) == signf(z.global_position.x - dam.global_position.x)
	if same_side or absf(d.x) < 70.0:
		_to_fight()
		return
	if absf(d.x) > SEE_R + 200.0:   # ברחת רחוק - הולך אחריך ובונה שוב
		dam = null
		_relocate(pl)
		return
	if _cd <= 0.0:
		state = WIND
		_st = LOB_WIND
		_set_crouch(false)
		Sfx.play("db_chitter", z.global_position, -6.0, 0.15, 2)


func _relocate(pl: Node) -> void:
	_set_crouch(false)
	_spot = 0.0
	if _logs <= 0 or pl == null or pl.dead:
		_to_fight()
		return
	_logs -= 1
	state = RELOCATE


func _to_fight() -> void:
	_set_crouch(false)
	state = FIGHT
	_cd = 0.6


func _fight(pl: Node, has: bool, d: Vector2, delta: float) -> void:
	var v := 0.0
	if has:
		z._dir = signf(d.x) if absf(d.x) > 4.0 else z._dir
		if absf(d.x) > TAIL_R * 0.8:
			v = z._dir * float(z.chase_speed)
		if _cd <= 0.0 and absf(d.x) < TAIL_R and absf(d.y) < 50.0 and z.is_on_floor():
			state = TAIL_W
			_st = TAIL_WIND
		# בורח ובונה שוב אם יש לו בולים ואתה התרחקת
		if _logs > 0 and absf(d.x) > 420.0:
			_relocate(pl)
			return
	z.velocity.x = move_toward(z.velocity.x, v, 800.0 * delta)
	z._walk_phase += delta * absf(z.velocity.x) / 13.0
	if z.is_on_floor() and z.is_on_wall() and absf(z.velocity.x) < 20.0:
		z.velocity.y = -500.0


func _set_crouch(on: bool) -> void:
	if on == _crouch or z.dead:
		return
	_crouch = on
	z._set_crouch(on)
	var r := z._shape.shape as RectangleShape2D
	if on:   # כפוף מאחורי הקיר: גוף קטן
		r.size.y = 38.0 * z.sc
		z._shape.position.y = -r.size.y / 2.0


func _lob(pl: Node) -> void:
	lobs += 1
	var e := Ember.new()
	e.owner_t = self
	_main().add_child(e)
	var from: Vector2 = z.global_position + Vector2(z._dir * 6.0, -58.0 * z.sc)
	e.global_position = from
	var to: Vector2 = pl.global_position + Vector2(randf_range(-30, 30), -6.0) + (pl.velocity * 0.25 if pl.is_on_floor() else Vector2.ZERO)
	var tt := clampf(absf(to.x - from.x) / 420.0, 0.6, 1.25)
	e.vel = Vector2((to.x - from.x) / tt, (to.y - from.y - 0.5 * Ember.G * tt * tt) / tt)
	e.ground_y = pl.global_position.y if absf(pl.global_position.y - z.global_position.y) > 60.0 else z.global_position.y
	Sfx.play("db_lob", from, -2.0, 0.15, 2)


# הקיר שלו נפל
func dam_lost() -> void:
	walls_lost += 1
	dam = null
	var m := _main()
	if m != null:
		m.set_meta("db_broken", int(m.get_meta("db_broken", 0)) + 1)
	if not z.dead and (state == COVER or state == WIND or state == BUILD):
		_relocate(player())


func on_damage(_amount: int, _hit_pos: Vector2, _dir: Vector2, _src: Dictionary) -> bool:
	if state == BUILD and not z.dead:   # נבהל באמצע הבנייה - מסיים מהר יותר
		_st = maxf(0.0, _st - 0.2)
	return true


func on_death() -> void:
	if dam != null and is_instance_valid(dam):
		dam.owner_t = null
	if Art.on_screen(z, z.global_position) and _logs > 0:   # הבולים שהוא סחב נופלים
		for i in mini(_logs, 2):
			var dbr = DebrisScript.new()
			_main().add_child(dbr)
			dbr.setup(z.global_position + Vector2(0, -40), Vector2(randf_range(22, 30), 7), Color("3a2a1c"), Vector2(randf_range(-160, 160), -randf_range(120, 260)))


# ============================================================
#  ציור: לוכד בעורות בונים, גולגולת בונה על הראש, זנב שטוח, בולים על הכתף
# ============================================================
func wants_redraw() -> bool:
	return true


func draw() -> bool:
	begin_draw()
	var t: float = z._time
	var f: Array = feet(4.5, 2.4)
	var crouch := 0.0
	if _crouch and state == COVER:
		crouch = 1.0
	var wind := 0.0
	if state == WIND:
		wind = clampf(1.0 - _st / LOB_WIND, 0.0, 1.0)
	var hip := Vector2(-1, -24 + 8.0 * crouch)
	var sh := Vector2(3.0 + 6.0 * crouch, -42 + 14.0 * crouch)
	if state == BUILD:
		sh += Vector2(3.0, 3.0 + 4.0 * sin(t * 18.0))
	var head := sh + Vector2(2.5 + 2.0 * crouch, -7.0)
	var sk := col(z.skin)
	var pelt := col(_pelt)
	# זנב בונה שטוח (מאחור)
	var tail_a := 0.0
	if state == TAIL_W:
		tail_a = -1.2 * clampf(1.0 - _st / TAIL_WIND, 0.0, 1.0)
	elif state == TAIL:
		tail_a = 1.6
	var tb := hip + Vector2(-5, 2)
	var td := Vector2.from_angle(PI * 0.75 + tail_a * 0.6 + sin(t * 2.0) * 0.08)
	var tn := Vector2(-td.y, td.x)
	Art.fill(z, PackedVector2Array([tb - tn * 2.0, tb + td * 6.0 - tn * 5.0, tb + td * 17.0 - tn * 4.0, tb + td * 19.0, tb + td * 17.0 + tn * 4.0, tb + td * 6.0 + tn * 5.0, tb + tn * 2.0]), col(Color("3a2c22")), Art.OUTLINE, 1.0)
	for q in 3:   # קשקשים
		DrawBatch.line(z, tb + td * (8.0 + float(q) * 3.5) - tn * 3.0, tb + td * (8.0 + float(q) * 3.5) + tn * 3.0, col(Color("2a2018")), 0.7)
	# רגליים
	var pa := col(Color("3a3028"))
	if crouch > 0.0:
		f = [Vector2(6, 0), Vector2(-6, 0)]
	z._leg(hip + Vector2(-2, 0), f[1], col(Color("2e2620")), sk, col(z.shoe))
	z._leg(hip + Vector2(2, 0), f[0], pa, sk, col(z.shoe))
	# יד אחורית (מחזיקה את הבולים / פטיש אבן)
	var hb := sh + Vector2(-4.0, 13.0)
	if state == BUILD:
		hb = sh + Vector2(10.0, 6.0 + 6.0 * sin(t * 18.0))
	elif wind > 0.0:
		hb = sh + Vector2(-8.0, -6.0 * wind)
	z._arm(sh + Vector2(-3, 1), hb, col(Art.shade(z.skin, 0.2)), col(Art.shade(_pelt, 0.25)))
	# גוף: מעיל של עורות בונים תפורים
	var torso := PackedVector2Array([sh + Vector2(-8, -1), sh + Vector2(7, 0), hip + Vector2(8, 2), hip + Vector2(-9, 1)])
	Art.fill_shaded(z, torso, pelt, 0.14, 0.32)
	var r := RandomNumberGenerator.new()
	r.seed = _seed
	for q in 5:   # פרווה + תפרים
		var a := sh.lerp(hip, r.randf()) + Vector2(r.randf_range(-6.0, 6.0), 0)
		DrawBatch.line(z, a, a + Vector2(r.randf_range(-2.0, 2.0), 3.0), col(Art.shade(_pelt, 0.35)), 0.8)
	DrawBatch.line(z, sh + Vector2(0, 2), hip + Vector2(0, -1), col(Color("c8b090")), 0.6)
	DrawBatch.line(z, hip + Vector2(-8, -3), hip + Vector2(8, -2), col(Color("2a1e14")), 1.6)   # חגורה
	# בולים על הכתף (כשהוא סוחב)
	if (state == SEEK or state == RELOCATE) and _logs >= 0:
		for q in 2:
			var lc := sh + Vector2(-4.0, -5.0 - float(q) * 5.0)
			var ld := Vector2.from_angle(-0.25)
			DrawBatch.colored_polygon(z, PackedVector2Array([lc - ld * 16.0 + Vector2(0, -2.5), lc + ld * 14.0 + Vector2(0, -2.5), lc + ld * 14.0 + Vector2(0, 2.5), lc - ld * 16.0 + Vector2(0, 2.5)]), col(Color("2e2216") if not _learned else Color("22262a")))
			DrawBatch.circle(z, lc + ld * 14.0, 2.5, col(Color("6a4a30")))
	# ראש: פנים אפורות-ירקרקות, גולגולת בונה כקסדה
	var hr := 5.4
	Art.oval_shaded(z, head, hr, 6.0, sk, 0.0)
	face(head)
	if _hat:
		var hc := head + Vector2(0.5, -4.0)
		Art.fill(z, PackedVector2Array([hc + Vector2(-6, 2), hc + Vector2(-5, -3), hc + Vector2(1, -5), hc + Vector2(7, -3), hc + Vector2(10, 0), hc + Vector2(8, 2)]), col(Color("d8ccb0")), Art.OUTLINE, 0.9)
		DrawBatch.circle(z, hc + Vector2(4.5, -2.0), 1.0, Color(0.1, 0.06, 0.04))
		# שיני הבונה הכתומות
		DrawBatch.colored_polygon(z, PackedVector2Array([hc + Vector2(8, 1.5), hc + Vector2(10.5, 1.5), hc + Vector2(10, 6), hc + Vector2(8.3, 6)]), col(Color("e07a1a")))
		DrawBatch.line(z, hc + Vector2(9.2, 1.6), hc + Vector2(9.2, 6.0), col(Color("8a4a10")), 0.5)
		# פרוות הבונה נשפכת על הגב
		DrawBatch.colored_polygon(z, PackedVector2Array([hc + Vector2(-6, 1), hc + Vector2(-9, 8), hc + Vector2(-4, 10), hc + Vector2(-2, 3)]), col(Art.shade(_pelt, 0.1)))
	# יד קדמית
	var hf := sh + Vector2(6.0, 13.0)
	if state == BUILD:
		hf = sh + Vector2(13.0, 4.0 - 8.0 * maxf(0.0, sin(t * 18.0)))
	elif wind > 0.0:
		hf = sh + Vector2(-6.0, -14.0 * wind)
	elif state == COVER:
		hf = sh + Vector2(10.0, 2.0)
	z._arm(sh + Vector2(4, 1), hf, sk, pelt)
	if wind > 0.2:   # הגחלת ביד
		DrawBatch.circle(z, hf + Vector2(0, -2), 3.0, Color(1.0, 0.55, 0.15))
		Art.glow(z, hf + Vector2(0, -2), 7.0, Color(1.0, 0.5, 0.15, 0.6))
	if state == BUILD:   # פטיש אבן
		DrawBatch.colored_polygon(z, Art.ellipse(hf + Vector2(3, -1), 3.4, 2.4, 0.4, 8), col(Color("6a6460")))
	end_draw()
	return true


# ============================================================
#  הקיר: בולים שרופים + בוץ, עוצר כדורים / אותך / זומבים. כבוד ל"מחסה" (קבוצת cover)
# ============================================================
class Dam extends Node2D:
	const DrawBatch := preload("res://effects/draw_batch.gd")
	const Art := preload("res://art.gd")
	const Sfx := preload("res://sfx.gd")
	const Particles := preload("res://particles.gd")
	var owner_t = null
	var wet := false
	var face := 1.0                 # לאיזה צד הקיר פונה (אליך)
	var progress := 0.0
	var hp := DAM_HP
	var burn := 0.0
	var _body: StaticBody2D = null
	var _cs: CollisionShape2D = null
	var _rs: RectangleShape2D = null
	var _h := DAM_H
	var _t := 0.0
	var _shown := -1.0
	var _sized := -1.0
	var _done := false
	var _chips := 0

	class DamBody extends StaticBody2D:
		var dam = null
		func take_damage(a, p: Vector2, d: Vector2, _e := false, s := {}) -> void:
			if dam != null:
				dam.hit(a, p, d, s)

	func _ready() -> void:
		z_index = 2
		add_to_group("cover")
		add_to_group("blastable")
		add_to_group("db_dams")
		_h = WET_H if wet else DAM_H
		hp = WET_HP if wet else DAM_HP
		_body = DamBody.new()
		_body.dam = self
		_body.collision_layer = 1
		_body.collision_mask = 0
		_body.add_to_group("no_outline")
		_cs = CollisionShape2D.new()
		_rs = RectangleShape2D.new()
		_cs.shape = _rs
		_body.add_child(_cs)
		add_child(_body)
		_resize()

	func _resize() -> void:
		var hh := maxf(6.0, _h * progress)
		_rs.size = Vector2(DAM_W, hh)
		_cs.position = Vector2(0.0, -hh * 0.5)

	func cover_rect() -> Rect2:
		var hh := _h * progress
		return Rect2(global_position + Vector2(-DAM_W * 0.5, -hh), Vector2(DAM_W, hh))

	func blast_rect() -> Rect2:
		return cover_rect()

	func hit_by_blast(_c: Vector2, _r: float) -> void:
		damage(DAM_BLAST, global_position + Vector2(0, -_h * 0.5), Vector2.UP)

	func hit(_a, p: Vector2, d: Vector2, s: Dictionary) -> void:
		var dmg := 10
		if s.has("fixed"):
			dmg = int(s.fixed)
		elif s.has("dmg_mult"):
			dmg = maxi(3, int(round(10.0 * float(s.dmg_mult))))
		if s.get("sniper", false):
			dmg *= 2
		if s.get("incendiary", false) and not wet:
			ignite()
		Game.on_zombie_hit({"source": "bullet", "zone": "wall", "shot": s.get("shot", 0)})
		damage(dmg, p, d)

	func ignite() -> void:
		if wet:
			if burn <= 0.0 and Art.on_screen(self, global_position):
				Sfx.play("s59_hiss", global_position, -4.0, 0.1, 2)
				Particles.burst(get_parent(), global_position + Vector2(0, -_h * 0.5), "mist", Vector2.UP, 3)
			return
		if burn <= 0.0:
			Sfx.play("am_ignite", global_position, -2.0, 0.1, 2)
		burn = DAM_BURN_T

	func damage(dmg: int, p: Vector2, d: Vector2) -> void:
		if _done:
			return
		hp -= dmg
		_chips += 1
		if Art.on_screen(self, p):
			Sfx.play("db_chop", p, -8.0, 0.2, 3)
			if _chips % 2 == 0:
				var dbr = DebrisScript.new()
				get_parent().add_child(dbr)
				dbr.setup(p, Vector2(randf_range(3, 6), randf_range(2, 4)), Color("5a4430") if not wet else Color("3a3a3a"), Vector2(-d.x * randf_range(60, 180), -randf_range(60, 200)))
			Particles.burst(get_parent(), p, "spark" if burn > 0.0 else "smoke", -d, 1)
		_shown = -1.0
		if hp <= 0:
			collapse()

	func collapse() -> void:
		if _done:
			return
		_done = true
		Sfx.play("db_crash", global_position, 0.0, 0.1, 2)
		if Art.on_screen(self, global_position):
			for i in 4:
				var dbr = DebrisScript.new()
				get_parent().add_child(dbr)
				dbr.setup(global_position + Vector2(randf_range(-10, 10), -_h * progress * randf()), Vector2(randf_range(20, 30), randf_range(6, 8)), Color("3a2a1c") if not wet else Color("2a2e30"), Vector2(randf_range(-200, 200), -randf_range(100, 300)))
			Particles.burst(get_parent(), global_position + Vector2(0, -20), "smoke", Vector2.UP, 6)
			CharredT.Cinders.spray(get_parent(), global_position + Vector2(0, -20), Vector2.UP, 10, global_position.y, 0.8)
		var m := get_parent()
		if m != null and int(m.get_meta("db_wall_pop", 0)) < 3:
			m.set_meta("db_wall_pop", int(m.get_meta("db_wall_pop", 0)) + 1)
			var pl := get_tree().get_first_node_in_group("player")
			if pl != null and int(m.get_meta("db_wall_pop", 0)) == 1 and pl.has_method("_say"):
				pl._say("Wall's down. Now it's exposed.", Color("f0c890"))
		if owner_t != null and is_instance_valid(owner_t.z) and not owner_t.z.dead:
			owner_t.dam_lost()
		elif m != null:
			m.set_meta("db_broken", int(m.get_meta("db_broken", 0)) + 1)
		queue_free()

	func _process(delta: float) -> void:
		_t += delta
		if owner_t != null and not is_instance_valid(owner_t.z):
			owner_t = null
		if absf(_sized - progress) > 0.01:
			_sized = progress
			_resize()
		if burn > 0.0:
			burn -= delta
			if Engine.get_process_frames() % 6 == 0:
				damage(int(DAM_BURN_DPS * 0.1), global_position + Vector2(randf_range(-12, 12), -_h * progress * 0.6), Vector2.UP)
				for z in get_tree().get_nodes_in_group("zombies"):   # מצית את מי שעומד ליד (CHARRED שמח)
					if not z.dead and absf(z.global_position.x - global_position.x) < 60.0 and absf(z.global_position.y - global_position.y) < 40.0:
						z.ignite(2.0)
				if Art.on_screen(self, global_position):
					Particles.burst(get_parent(), global_position + Vector2(randf_range(-14, 14), -_h * progress), "fire", Vector2.UP, 2)
		if (burn > 0.0 or absf(_shown - progress) > 0.01 or Engine.get_process_frames() % 8 == 0) and Art.on_screen(self, global_position, 80.0):
			_shown = progress
			queue_redraw()

	func _draw() -> void:
		DrawBatch.begin(self)
		_draw_b()
		DrawBatch.end(self)

	func _draw_b() -> void:
		var hh := _h * progress
		var pts := PackedVector2Array()
		var cols := PackedColorArray()
		var dmg := 1.0 - float(hp) / float(WET_HP if wet else DAM_HP)
		var c0 := Color("2e2216") if not wet else Color("22282a")
		var c1 := Color("4a3624") if not wet else Color("343c3e")
		# בוץ בבסיס
		Decor.U.oval(pts, cols, Vector2(0, -2), DAM_W * 0.75, 6.0, Color("2a1e16"), 10)
		# בולים אופקיים (נערמים לפי ההתקדמות)
		var rows := int(ceil(hh / 11.0))
		for q in rows:
			var y := -6.0 - float(q) * 11.0
			if -y > hh + 4.0:
				break
			var off := (float(q % 2) - 0.5) * 6.0 + (dmg * 4.0 * sin(float(q) * 2.3))
			var lw := DAM_W * 0.62 + float(q % 3) * 2.0
			Decor.U.quad(pts, cols, Vector2(-lw + off, y - 5.0), Vector2(lw + off, y - 5.5), Vector2(lw + off, y + 5.0), Vector2(-lw + off, y + 5.0), c1, c1, c0, c0)
			Decor.U.oval(pts, cols, Vector2(lw + off, y), 3.0, 5.0, Color("7a5a3a") if not wet else Color("5a6060"), 8)
			Decor.U.oval(pts, cols, Vector2(lw + off, y), 1.4, 2.4, Color("3a2a1c"), 6)
			Decor.U.rect(pts, cols, Rect2(-lw + off, y - 1.0, lw * 1.6, 0.8), Color(1.0, 0.45, 0.1, 0.35 if not wet else 0.0))
		# יתדות + חרך (כשהוא רטוב / למד)
		for s in [-1.0, 1.0]:
			Decor.U.quad(pts, cols, Vector2(s * DAM_W * 0.55 - 2.0, 2.0), Vector2(s * DAM_W * 0.55 + 2.0, 2.0), Vector2(s * DAM_W * 0.5 + 1.0, -hh - 8.0), Vector2(s * DAM_W * 0.5 - 1.0, -hh - 6.0), Color("3a2a1c"), Color("3a2a1c"), Color("5a4430"), Color("5a4430"))
		if wet and progress > 0.9:
			Decor.U.rect(pts, cols, Rect2(-DAM_W * 0.45, -hh + 10.0, DAM_W * 0.9, 4.0), Color(0.02, 0.02, 0.02, 0.9))
			for q in 3:   # טיפות / ברק מים
				Decor.U.rect(pts, cols, Rect2(-DAM_W * 0.4 + float(q) * 10.0, -hh + 18.0 + float(q) * 9.0, 6.0, 1.0), Color(0.7, 0.8, 0.85, 0.5))
		if burn > 0.0:
			for q in 4:
				Decor.U.flame(pts, cols, Vector2(-DAM_W * 0.45 + float(q) * DAM_W * 0.3, -hh * (0.4 + 0.6 * float(q % 2))), 6.0, 14.0 + 8.0 * sin(_t * 9.0 + float(q)), sin(_t * 4.0 + float(q)) * 3.0, 0.95)
		Decor.U.flush(self, pts, cols)


# ---- גחלת שהוא זורק: אפשר לירות בה. זזה ב-_process ----
class Ember extends Node2D:
	const G := 900.0
	const DrawBatch := preload("res://effects/draw_batch.gd")
	const Sfx := preload("res://sfx.gd")
	const Particles := preload("res://particles.gd")
	var vel := Vector2.ZERO
	var ground_y := 630.0
	var owner_t = null
	var _done := false
	var _t := 0.0

	class Hit extends StaticBody2D:
		var e = null
		func take_damage(_a, _p: Vector2, _d: Vector2, _x := false, _s := {}) -> void:
			if e != null:
				e.shot()

	func _ready() -> void:
		z_index = 7
		var h := Hit.new()
		h.e = self
		h.collision_layer = 4
		h.collision_mask = 0
		h.add_to_group("no_outline")
		var cs := CollisionShape2D.new()
		var sh := RectangleShape2D.new()
		sh.size = Vector2(16, 16)
		cs.shape = sh
		h.add_child(cs)
		add_child(h)

	func shot() -> void:
		if _done:
			return
		_done = true
		if owner_t != null and is_instance_valid(owner_t.z):
			owner_t.embers_shot += 1
		Particles.burst(get_parent(), global_position, "spark", Vector2.UP, 6)
		Sfx.play("ch_chip", global_position, -2.0, 0.1, 2)
		queue_free()

	func _process(delta: float) -> void:
		if _done:
			return
		_t += delta
		vel.y += G * delta
		global_position += vel * delta
		if Engine.get_process_frames() % 4 == 0:
			Particles.burst(get_parent(), global_position, "fire", -vel.normalized(), 1)
		var pl := get_tree().get_first_node_in_group("player")
		if pl != null and not pl.dead and Rect2(global_position - Vector2(8, 8), Vector2(16, 16)).intersects(pl.body_rect()):
			_land(pl, true)
			return
		if global_position.y >= ground_y - 4.0 and vel.y > 0.0 or _t > 3.5:
			_land(pl, false)
			return
		queue_redraw()

	func _land(pl: Node, direct: bool) -> void:
		_done = true
		if direct and pl != null:
			if pl._roll_t <= 0.0 and owner_t != null and is_instance_valid(owner_t.z):
				owner_t.lob_hits += 1
			pl.hurt(EMBER_DMG, Vector2(signf(vel.x) * 0.8, -0.3))
		Sfx.play("s59_crackle", global_position, -4.0, 0.15, 3)
		Particles.burst(get_parent(), global_position, "fire", Vector2.UP, 4)
		var ep := CharredT.EmberPatch.new()
		ep.w = 54.0
		ep.life = 2.6
		get_parent().add_child(ep)
		ep.global_position = Vector2(global_position.x, ground_y)
		queue_free()

	func _draw() -> void:
		DrawBatch.begin(self)
		_draw_b()
		DrawBatch.end(self)

	func _draw_b() -> void:
		var pts := PackedVector2Array()
		var cols := PackedColorArray()
		Decor.U.blob(pts, cols, Vector2.ZERO, 12.0, 12.0, Color(1.0, 0.45, 0.1, 0.45), 10)
		Decor.U.oval(pts, cols, Vector2.ZERO, 4.5, 4.0, Color("3a1a0c"), 8)
		Decor.U.oval(pts, cols, Vector2.ZERO, 3.0, 2.6, Color(1.0, 0.6 + 0.2 * sin(_t * 20.0), 0.15), 8)
		Decor.U.flame(pts, cols, Vector2(0, 2), 4.0, 9.0, -vel.x * 0.01, 0.9)
		Decor.U.flush(self, pts, cols)
