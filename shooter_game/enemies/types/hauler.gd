extends "res://enemies/zombie_type.gd"
# ============================================================
#  HAULER (שלב 52, "RAIL YARD") - "הסבל". בהשראת "Gyo" של ג'וניצ'י איטו (מכונות ההליכה עם בלוני הגז שמובילות גופות).
#  גופה תפורה לשלד הליכה בעל 4 רגליים שהורכב מחלקי מסילה (קורות, בוכנות, גלגלי רכבת קטנים), ובלון גז על הגב
#    שצינורות גומי יוצאים ממנו אל הגב והפה של הגופה (נושפת גז ירקרק).
#  מהיר. RAM - נרתע לאחור עם שריקת קיטור (RAM_WIND) ומסתער בקו ישר (RAM_V). STOMP - כשאתה צמוד: מרים רגליים ומועך (לקפוץ).
#  שריון: יריות מלפנים פוגעות בשלד הברזל (x FRAME_MULT, ניצוצות). ראש הגופה (מלפנים, תלוי בגובה החזה) = נזק מלא.
#  בלון הגז (נקודת התורפה): מאחור, מלמעלה, או מלפנים בגובה (החלק העליון של הבלון בולט מעל הראש).
#    TANK_HP -> מתחיל לפלוט גז (VENT_T, שריקה) -> מתפוצץ (פוגע בזומבים מסביב!) -> השלד קורס (Wreck)
#    והגופה ממשיכה לזחול (CRAWL) עם מעט חיים. אם הורגים אותו כשהבלון שלם - הבלון נקרע ומתפוצץ אחרי שנייה (Rupture).
#  "THEY LEARN" (main meta "hauler_pops" >= 1): הבאים מנמיכים את הבלון אל תוך השלד (מלפנים כבר אי אפשר לפגוע בו),
#    מסתובבים אליך מהר (LEARN_TURN_T במקום TURN_T), ואחרי פגיעה בבלון - נסוגים עם הגב אל מחסה (COVER_R).
#  בוס (chase_range > 600): "THE ENGINE" - דוד קטר ענק על רגליים, עם קבינה, ארובה, פנס, ופנים של גופה ענקית על דלת התא.
#    גופות שרשראות על הצדדים ("נוסעים"):
#    STEAM   - פרץ קיטור מלפנים (STEAM_R), מכוון אליך (גם למעלה).
#    DROP    - מפיל 2 גופות שקמות (DROP_EVERY, עד DROP_MAX).
#    WHISTLE -> CHARGE - שריקה + הפנס נדלק (WHISTLE_T) ואז הסתערות לאורך המסילה (CHARGE_V). להתחמק: לטפס / להתגלגל.
#    VALVES  - אחרי כל הסתערות: 3 שסתומי לחץ נפתחים למעלה (VALVE_T). יריות בהם x VALVE_MULT, כל השאר x OPEN_MULT.
#              שסתום שנשבר (VALVE_HP) נשאר פתוח לתמיד. דוד סגור = שריון (x ARMOR_MULT, "CLANG").
#    מתחת ל-50% חיים, או אחרי 2 התחמקויות בגלגול ("IT READS YOUR ROLL") - הסתערות כפולה הלוך-חזור.
#  צלילים: "hl_hiss", "hl_clank", "hl_ram", "hl_stomp", "hl_vent", "en_whistle", "en_steam", "metal_ping", "train".
#  לשנות: TANK_HP, VENT_T, BLAST_R, BLAST_DMG, FRAME_MULT, RAM_R, RAM_WIND, RAM_V, RAM_T, RAM_DMG, STOMP_R, CD, TURN_T,
#    LEARN_TURN_T, CRAWL_HP, COVER_R, COVER_HOLD, SORTIE_T; בוס: STEAM_R, STEAM_T, DROP_EVERY, DROP_MAX, WHISTLE_T, CHARGE_V, CHARGE_EVERY, VALVE_T,
#    VALVE_HP, VALVE_MULT, ARMOR_MULT, OPEN_MULT, BOSS_HEAD_K.
# ============================================================

const PickupScript := preload("res://pickup.gd")
const SOUNDS := {
	"hl_hiss": [["N", 0, 0, 0.0, 0.5, 0.03, 4.0, 0.45, 1.0, 0, 0.55]],
	"hl_clank": [["S", 340, 220, 0.0, 0.09, 0.0, 30.0, 0.4, 1.0, 0], ["N", 0, 0, 0.0, 0.05, 0.0, 50.0, 0.3, 0.5, 0, 0.3]],
	"hl_ram": [["N", 0, 0, 0.0, 0.6, 0.05, 3.0, 0.6, 0.2, 0], ["S", 90, 60, 0.0, 0.6, 0.05, 3.0, 0.5, 1.0, 0.02], ["S", 2400, 2100, 0.0, 0.5, 0.02, 4.0, 0.12, 1.0, 0.01]],
	"hl_stomp": [["N", 0, 0, 0.0, 0.3, 0.0, 10.0, 0.9, 0.2, 0], ["S", 70, 35, 0.0, 0.3, 0.0, 10.0, 0.9, 1.0, 0], ["S", 900, 700, 0.0, 0.15, 0.0, 20.0, 0.2, 1.0, 0]],
	"hl_vent": [["N", 0, 0, 0.0, 0.9, 0.05, 1.5, 0.7, 1.0, 0, 0.35], ["S", 900, 1800, 0.0, 0.9, 0.05, 1.5, 0.12, 1.0, 0.05]],
	"en_whistle": [["W", 466, 470, 0.0, 1.0, 0.06, 1.0, 0.32, 0.4, 0.01], ["W", 587, 592, 0.0, 1.0, 0.06, 1.0, 0.28, 0.4, 0.01],
		["N", 0, 0, 0.0, 1.0, 0.06, 1.0, 0.15, 0.6, 0, 0.5]],
	"en_steam": [["N", 0, 0, 0.0, 0.8, 0.02, 2.0, 0.85, 1.0, 0, 0.3], ["N", 0, 0, 0.0, 0.8, 0.02, 2.0, 0.4, 0.3, 0]],
}

const Boom := preload("res://explosion.gd")

const BOX := Vector2(76.0, 64.0)      # אזור הפגיעה (יחידות ציור)
const TANK_HP := 40
const VENT_T := 0.8
const BLAST_R := 130.0
const BLAST_DMG := 60
const FRAME_MULT := 0.5
const RAM_R := Vector2(140.0, 430.0)
const RAM_WIND := 0.5
const RAM_V := 470.0
const RAM_T := 0.75
const RAM_DMG := 2
const STOMP_R := 74.0
const STOMP_WIND := 0.35
const STOMP_DMG := 1
const CD := Vector2(1.3, 2.3)
const TURN_T := 0.7
const LEARN_TURN_T := 0.15
const CRAWL_HP := 26
const COVER_R := 360.0
const COVER_HOLD := 3.0       # כמה זמן מחכה במחסה לפני שיוצא להסתער
const SORTIE_T := 2.5         # כמה זמן מחוץ למחסה עד שחוזר אליו
# בוס
const BOSS_BOX := Vector2(110.0, 70.0)
const STEAM_R := 280.0
const STEAM_WIND := 0.55
const STEAM_T := 0.7
const STEAM_DMG := 1
const DROP_EVERY := 7.0
const DROP_MAX := 6
const WHISTLE_T := 1.1
const CHARGE_V := 540.0
const CHARGE_MAX_T := 1.9
const CHARGE_DMG := 2
const CHARGE_EVERY := Vector2(5.0, 7.0)
const VALVE_T := 3.5
const VALVE_HP := 60
const VALVE_MULT := 2.5
const ARMOR_MULT := 0.3
const OPEN_MULT := 1.0
const BOSS_HEAD_K := 0.4       # "ראש" של בוס = x2 נזק ב-zombie.gd. כאן אין ראש אמיתי (חלק עליון של הדוד) - מתקנים
const VALVE_X := [-24.0, -4.0, 16.0]

enum { WALK, RAM_WIND_S, RAM, RECOVER, STOMP_WIND_S, VENT, CRAWL, STEAM_WIND_S, STEAM, WHISTLE, CHARGE, VALVES }
var state := WALK
# לבדיקות
var rams := 0
var ram_hits := 0
var stomps := 0
var stomp_hits := 0
var tank_hits := 0
var pops := 0
var frame_hits := 0
var corpse_hits := 0
var learned_turns := 0
var cover_backs := 0
var steams := 0
var steam_hits := 0
var drops := 0
var whistles := 0
var charges := 0
var charge_hits := 0
var double_charges := 0
var valve_hits := 0
var valves_broken := 0
var crushed := 0
var rolled_dodges := 0
var crawl := false
var tank_learned := false     # הבלון מונמך (נקבע בלידה לפי מה שהזומבים למדו)
var _tank := TANK_HP
var _leaks: Array = []        # חורים בבלון (מקומי)
var _st := 0.0
var _cd := 1.0
var _behind_t := 0.0
var _met := false
var _hit_done := false
var _hit_kind := "frame"
var _own_boom := 0.0
var _step_snd := 0.0
var _hint := 0
var _cover_x := NAN
var _cover_t := 0.0
var _in_cover := false
var _hold_t := 0.0
var _sortie_t := 0.0
var _gas := 0.0
var _rear := 0.0              # הרמת החזית (אנימציית RAM_WIND / STOMP)
# בוס
var _valves := [VALVE_HP, VALVE_HP, VALVE_HP]
var _valve_open := 0.0        # 0..1 אנימציה
var _drop_cd := 4.0
var _charge_cd := 3.0
var _dropped: Array = []
var _passengers := 6
var _steam_dir := Vector2.RIGHT
var _second := false
var _rolled := false
var _crushed_ids := {}
var _glare := 0.0
var _smoke_t := 0.0
var _armor_pop := 0


func _boss() -> bool:
	return z != null and float(z.chase_range) > 600.0


func stats() -> Dictionary:
	if _boss():
		return {"name": "HAULER", "hp": 360, "walk": 40.0, "chase": 70.0, "damage": 2, "bite_delay": 1.2, "scale": 2.3, "width": 1.0,
			"duck": 0.0, "cover": 0.0, "skin": Color("b8b0a8"), "shirt": Color("2a2a30"), "pants": Color("2a2a30"), "shoe": Color("1a1a1a"),
			"points": 2600, "boss": true, "boss_name": "THE ENGINE", "metal": _hit_kind == "armor", "ragdoll": false}
	return {"name": "HAULER", "hp": 80, "walk": 60.0, "chase": 150.0, "damage": 1, "bite_delay": 1.0, "scale": 1.15, "width": 1.2,
		"duck": 0.0, "cover": 0.0, "skin": Color("8a8494"), "shirt": Color("4a4a50"), "pants": Color("3a3a40"), "shoe": Color("1a1a1a"),
		"points": 620, "metal": _hit_kind == "frame" and not crawl, "ragdoll": false}


func use_brain_movement() -> bool:
	return false


func can_bite() -> bool:
	return false


func can_groan() -> bool:
	return crawl


func setup() -> void:
	var m := _main()
	tank_learned = not _boss() and m != null and int(m.get_meta("hauler_pops", 0)) >= 1
	_resize(BOSS_BOX if _boss() else BOX)
	_gas = randf() * 3.0


func _resize(b: Vector2) -> void:
	var r := z._shape.shape as RectangleShape2D
	r.size = Vector2(b.x * z.wf * z.sc, b.y * z.sc)
	z._shape.position = Vector2(0.0, -b.y * 0.5 * z.sc)


func _main() -> Node:
	return z.get_parent()


func _learned() -> bool:
	var m := _main()
	return m != null and int(m.get_meta("hauler_pops", 0)) >= 1


func _tank_center() -> Vector2:   # מקומי (יחידות)
	return Vector2(-19.0, -42.0) if tank_learned else Vector2(-10.0, -50.0)


func _tank_global() -> Vector2:
	var c := _tank_center()
	return z.global_position + Vector2(c.x * z._dir * z.wf * z.sc, c.y * z.sc)


# ============================================================
#  תנועה
# ============================================================
func physics(pl: Node, delta: float) -> bool:
	_st -= delta
	_cd -= delta
	_own_boom -= delta
	_step_snd -= delta
	_gas += delta
	_glare = move_toward(_glare, 1.0 if state == WHISTLE or state == CHARGE else 0.0, delta * 3.0)
	if not z.is_on_floor():
		z.velocity.y += z.gravity * delta
	var has: bool = pl != null and not pl.dead
	var d: Vector2 = (pl.global_position - z.global_position) if has else Vector2.ZERO
	if _boss():
		_boss_physics(pl, has, d, delta)
		z.move_and_slide()
		return true
	_rear = move_toward(_rear, 1.0 if state == RAM_WIND_S or state == STOMP_WIND_S else 0.0, delta * 5.0)
	match state:
		WALK:
			_walk(pl, has, d, delta)
		RAM_WIND_S:
			z.velocity.x = move_toward(z.velocity.x, -z._dir * 40.0, 1600.0 * delta)
			if _st <= 0.0:
				state = RAM
				_st = RAM_T
				_hit_done = false
				rams += 1
				Sfx.play("hl_ram", z.global_position, 0.0, 0.1, 3)
		RAM:
			z.velocity.x = z._dir * RAM_V
			z._walk_phase += delta * 22.0
			if has and not _hit_done and absf(d.x) < BOX.x * 0.5 * z.wf * z.sc + 14.0 and absf(d.y + 20.0) < 60.0:
				_hit_done = true
				if pl._roll_t <= 0.0:
					ram_hits += 1
				pl.hurt(RAM_DMG, Vector2(z._dir * 2.2, -0.6))   # (בגלגול: PERFECT DODGE)
			if Engine.get_physics_frames() % 4 == 0 and Art.on_screen(z, z.global_position):
				Particles.burst(z.get_parent(), z.global_position + Vector2(-z._dir * 20.0, -2.0), "spark", Vector2(-z._dir, -0.5), 2)
			var wall: bool = z.is_on_wall() and _st < RAM_T - 0.1
			if _st <= 0.0 or wall or (has and signf(d.x) != z._dir and absf(d.x) > 120.0):
				if wall:
					Sfx.play("hl_clank", z.global_position, 2.0, 0.1, 2)
					Particles.burst(z.get_parent(), z.global_position + Vector2(z._dir * 34.0, -30.0), "spark", Vector2(-z._dir, -0.3), 6)
				state = RECOVER
				_st = 0.2 if _learned() else 0.65
		RECOVER:
			z.velocity.x = move_toward(z.velocity.x, 0.0, 1500.0 * delta)
			if _st <= 0.0:
				state = WALK
				_cd = randf_range(CD.x, CD.y)
				if _learned() and has and signf(d.x) != z._dir:   # למד: מסתובב מיד, לא נותן לך את הגב
					z._dir = signf(d.x)
					learned_turns += 1
					_tell()
		STOMP_WIND_S:
			z.velocity.x = move_toward(z.velocity.x, 0.0, 1500.0 * delta)
			if _st <= 0.0:
				stomps += 1
				Sfx.play("hl_stomp", z.global_position, 1.0, 0.1, 3)
				if Art.on_screen(z, z.global_position):
					Particles.burst(z.get_parent(), z.global_position + Vector2(z._dir * 24.0, -2.0), "smoke", Vector2.UP, 5)
					var cam: Camera2D = z.get_viewport().get_camera_2d()
					if cam != null and cam.has_method("shake"):
						cam.shake(5.0, 0.18)
				if has and absf(d.x) < STOMP_R * z.sc + 20.0 and absf(d.y) < 50.0 and pl.is_on_floor():
					if pl._roll_t <= 0.0:
						stomp_hits += 1
					pl.hurt(STOMP_DMG, Vector2(z._dir * 1.4, -0.8))
				state = RECOVER
				_st = 0.4
		VENT:
			z.velocity.x = move_toward(z.velocity.x, 0.0, 1200.0 * delta)
			if Engine.get_physics_frames() % 3 == 0 and Art.on_screen(z, z.global_position):
				Particles.burst(z.get_parent(), _tank_global(), "mist", Vector2(-z._dir, -0.6), 2)
			if _st <= 0.0:
				_pop()
		CRAWL:
			_crawl(pl, has, d, delta)
	if state == WALK and z.is_on_floor() and z.is_on_wall() and absf(z.velocity.x) < 30.0:
		z.velocity.y = -540.0
	z.move_and_slide()
	return true


func _walk(pl: Node, has: bool, d: Vector2, delta: float) -> void:
	if not has:
		z.velocity.x = move_toward(z.velocity.x, 0.0, 600.0 * delta)
		return
	if not _met and (absf(d.x) < z.chase_range or z._alert_t > 0.0):
		_met = true
		Sfx.play("hl_hiss", z.global_position, 0.0, 0.1, 2)
	if not _met:
		z.velocity.x = move_toward(z.velocity.x, 0.0, 600.0 * delta)
		return
	var want: float = signf(d.x) if absf(d.x) > 4.0 else z._dir
	if want != z._dir:   # השחקן מאחוריו: מסתובב באיחור (הגב והבלון חשופים)
		_behind_t += delta
		if _behind_t > (LEARN_TURN_T if _learned() else TURN_T):
			z._dir = want
			_behind_t = 0.0
			if _learned():
				learned_turns += 1
				_tell()
	else:
		_behind_t = 0.0
	var v := 0.0
	var facing: bool = want == z._dir
	var hiding := false
	_sortie_t -= delta
	if _learned() and _tank < TANK_HP * 0.6 and facing and _sortie_t <= 0.0:
		# למד: הבלון פגוע -> נסוג עם הגב אל מחסה (או סתם אחורה), פנים אליך
		_cover_t -= delta
		if _cover_t <= 0.0:
			_cover_t = 0.5
			_cover_x = _find_cover(pl)
		if not is_nan(_cover_x):
			hiding = true
			var gx: float = _cover_x + z._dir * (BOX.x * 0.5 * z.wf * z.sc + 4.0)
			var gd: float = gx - z.global_position.x
			if absf(gd) > 10.0 and not (z.is_on_wall() and absf(z.velocity.x) < 20.0):   # (נתקע בגב בקיר = הגיע)
				v = signf(gd) * float(z.walk_speed) * 1.6
			elif not _in_cover:
				_in_cover = true
				_hold_t = COVER_HOLD
				cover_backs += 1
				_tell()
			elif _hold_t <= 0.0:   # חיכה מספיק: יוצא להסתער ואז חוזר למחסה
				_sortie_t = SORTIE_T
		elif absf(d.x) < 300.0:
			hiding = true
			v = -z._dir * float(z.walk_speed) * 1.4
	elif absf(d.x) > 46.0:
		v = z._dir * float(z.chase_speed) * (1.0 if facing else 0.6)
	if not hiding:
		_in_cover = false
	_hold_t -= delta
	z.velocity.x = move_toward(z.velocity.x, v, 1100.0 * delta)
	z._walk_phase += delta * absf(z.velocity.x) / 16.0
	if absf(z.velocity.x) > 20.0 and _step_snd <= 0.0 and Art.on_screen(z, z.global_position):
		_step_snd = 0.32
		Sfx.play("hl_clank", z.global_position, -8.0, 0.2, 2)
	if facing and _cd <= 0.0 and z.is_on_floor():
		if absf(d.x) < STOMP_R * z.sc + 10.0 and absf(d.y) < 60.0:
			state = STOMP_WIND_S
			_st = STOMP_WIND
		elif not hiding and absf(d.x) > RAM_R.x and absf(d.x) < RAM_R.y and absf(d.y) < 50.0:   # מסתתר: לא מסתער
			state = RAM_WIND_S
			_st = RAM_WIND
			Sfx.play("hl_hiss", z.global_position, -2.0, 0.1, 2)


func _tell() -> void:
	var m := _main()
	if m != null and not m.has_meta("hl_told"):
		m.set_meta("hl_told", true)
		z._popup("THEY HIDE THE TANK", Color("e0c070"), 15, -92.0)
		var pl := player()
		if pl != null and pl.has_method("_say"):
			pl._say("THEY HIDE THE TANK NOW... GET ABOVE THEM", Color("e0c070"))


func _find_cover(pl: Node) -> float:
	var best := NAN
	var bd := COVER_R
	for c in z.get_tree().get_nodes_in_group("cover"):
		if not (c is Node2D):
			continue
		var cx: float = c.global_position.x
		var hw := 0.0
		if c.has_method("cover_rect"):   # Obstacle: המיקום הוא הקצה השמאלי
			var r: Rect2 = c.cover_rect()
			hw = r.size.x * 0.5
			cx = r.position.x + hw
		var dx: float = cx - z.global_position.x
		if absf(c.global_position.y - z.global_position.y) > 80.0 or absf(dx) > bd:
			continue
		if signf(dx) == signf(pl.global_position.x - z.global_position.x):   # רק מחסה מאחוריו (הצד הרחוק ממך)
			continue
		bd = absf(dx)
		best = cx - signf(dx) * hw   # הקצה הקרוב אליו
	return best


func _crawl(pl: Node, has: bool, d: Vector2, delta: float) -> void:
	if not has:
		z.velocity.x = move_toward(z.velocity.x, 0.0, 600.0 * delta)
		return
	z._dir = signf(d.x) if absf(d.x) > 4.0 else z._dir
	var v: float = z._dir * float(z.chase_speed) if absf(d.x) > 22.0 else 0.0
	z.velocity.x = move_toward(z.velocity.x, v, 800.0 * delta)
	z._walk_phase += delta * 5.0
	if absf(d.x) < 34.0 and absf(d.y) < 40.0 and _cd <= 0.0:
		_cd = 1.0
		z._bite_anim = 0.25
		pl.hurt(1, Vector2(z._dir, 0.0))


# ============================================================
#  נזק: בלון / ראש הגופה / שלד ברזל
# ============================================================
func on_damage(amount: int, hit_pos: Vector2, dir: Vector2, src: Dictionary) -> bool:
	if z.dead:
		return true
	var s := str(src.get("source", "bullet"))
	if s == "hauler_tank" and _own_boom > 0.0:   # הפיצוץ של עצמו
		return false
	if _boss():
		return _boss_damage(amount, hit_pos, dir, src, s)
	if crawl:
		_hit_kind = "corpse"
		return true
	if not (s == "bullet" or s == "melee"):
		_hit_kind = "blast"
		if src.has("blast") and _tank > 0 and state != VENT:   # פיצוץ קרוב: גם הבלון נפגע (תגובת שרשרת!)
			_tank_hit(22, _tank_global(), Vector2.UP)
		return true
	var lx: float = (hit_pos.x - z.global_position.x) * z._dir / (z.sc * z.wf)
	var ly: float = (hit_pos.y - z.global_position.y) / z.sc
	var behind: bool = dir.x * z._dir > 0.0
	var above: bool = dir.y > 0.45
	var tank := false
	if _tank > 0 or state == VENT:
		if tank_learned:   # מונמך מאחורי לוח: רק מאחור או מלמעלה
			tank = (behind and lx < -6.0 and ly > -54.0 and ly < -32.0) or (above and lx < 0.0)
		else:              # על הגב: מאחור, מלמעלה, או החלק העליון שבולט מעל הכול
			tank = (lx < 0.0 and ly < -42.0) or ly < -54.0
	if tank and state == VENT:   # כבר פורק: הכדור רק מנקב עוד חור (לא מפריע לפיצוץ)
		if Art.on_screen(z, hit_pos):
			Particles.burst(z.get_parent(), hit_pos, "mist", Vector2(-dir.x, -0.6), 2)
		return false
	if tank:
		_tank_hit(hit_damage(amount, hit_pos, src), hit_pos, dir)
		return false
	_hit_kind = "corpse" if lx > 14.0 and ly > -48.0 and ly < -26.0 else "frame"
	if _hit_kind == "frame":
		frame_hits += 1
		_hint += 1
		if Art.on_screen(z, hit_pos):
			Particles.burst(z.get_parent(), hit_pos, "spark", Vector2(-dir.x, -0.5), 3)
		if _hint % 7 == 0 and _hint <= 21 and tank_hits == 0:
			z._popup("SHOOT THE TANK!", Color("ffd34a"), 15, -84.0)
	else:
		corpse_hits += 1
	return true


func _tank_hit(dmg: int, pos: Vector2, dir: Vector2) -> void:
	tank_hits += 1
	_tank -= maxi(1, dmg)
	z._flash = 0.06
	var lp := Vector2((pos.x - z.global_position.x) * z._dir / (z.wf * z.sc), (pos.y - z.global_position.y) / z.sc)
	var c := _tank_center()
	if _leaks.size() < 4:
		_leaks.append(c + (lp - c).limit_length(8.0))
	Sfx.play("metal_ping", pos, -2.0, 0.15, 3)
	Sfx.play("hl_hiss", pos, -6.0, 0.15, 2)
	if Art.on_screen(z, pos):
		Particles.burst(z.get_parent(), pos, "mist", -dir if dir != Vector2.ZERO else Vector2.UP, 3)
		Particles.burst(z.get_parent(), pos, "spark", -dir if dir != Vector2.ZERO else Vector2.UP, 2)
	Game.on_zombie_hit({"source": "bullet", "zone": "tank"})
	if _tank <= 0:
		state = VENT
		_st = VENT_T
		Sfx.play("hl_vent", z.global_position, 2.0, 0.05, 3)
		z._popup("VENTING!", Color("c8e0a0"), 17, -88.0)
	elif tank_hits == 1:
		z._popup("TANK", Color("e0e070"), 13, -84.0)


# הבלון מתפוצץ: פוגע בכל מה שמסביב, השלד קורס, הגופה זוחלת הלאה
func _pop() -> void:
	pops += 1
	var m := _main()
	if m != null:
		var was := int(m.get_meta("hauler_pops", 0))
		m.set_meta("hauler_pops", was + 1)
	_own_boom = 0.3
	Boom.blast.call_deferred(z.get_parent(), _tank_global(), BLAST_R, 60.0, BLAST_DMG, 1, "hauler_tank")
	var w := Wreck.new()
	w.side = z._dir
	w.k = z.sc
	z.get_parent().add_child(w)
	w.global_position = z.global_position
	crawl = true
	state = CRAWL
	_cd = 0.8
	z.hp = mini(z.hp, CRAWL_HP)
	z.chase_speed = 58.0
	_resize(Vector2(50.0, 20.0))
	z._popup("FRAME DOWN", Color("ffb070"), 15, -60.0)
	z._drop(PickupScript.AMMO)   # השלד התפרק: ארגז תחמושת נופל ממנו (ריצה ויריות - לא להיתקע בלי כדורים)


func damage_mult(zone: String, _src: Dictionary) -> float:
	if _boss():
		var k := BOSS_HEAD_K if zone == "head" else 1.0
		match _hit_kind:
			"valve":
				return VALVE_MULT * k
			"stub":
				return 2.0 * k
			"open":
				return OPEN_MULT * k
			"face":
				return 0.8 * k
			"armor":
				return ARMOR_MULT * k
		return 1.0
	if crawl or _hit_kind != "frame":
		return 1.0
	return FRAME_MULT


func on_death() -> void:
	if _boss():
		for c in _dropped:   # הנוסעים נופלים יחד איתו
			if is_instance_valid(c) and not c.dead and c.dormant:
				c.take_damage(999, c.global_position + Vector2(0, -10), Vector2.UP, true, {"source": "hazard", "fixed": 999})
		var cam: Camera2D = z.get_viewport().get_camera_2d()
		if cam != null and cam.has_method("shake"):
			cam.shake(20.0, 0.8)
		Sfx.play("explosion", z.global_position, 6.0, 0.0, 1)
		for i in 3:   # הדוד מתפוצץ (רק אפקט - לא פוגע בשחקן)
			var fx = Boom.Explosion.new()
			fx.radius = 90.0 + float(i) * 20.0
			fx.on_ground = i != 1
			z.get_parent().add_child(fx)
			fx.global_position = z.global_position + Vector2((float(i) - 1.0) * 70.0, -40.0 * z.sc * float(i % 2 + 1) * 0.5)
		return
	if not crawl and (_tank > 0 or state == VENT):   # הבלון נקרע (או מת באמצע הפריקה): שורק ומתפוצץ אחרי רגע
		var r := Rupture.new()
		r.from_hauler = true
		z.get_parent().add_child(r)
		r.global_position = _tank_global()
		z._drop(PickupScript.AMMO)   # מת עם השלד שלם: גם הוא משאיר ארגז תחמושת


# ============================================================
#  בוס: THE ENGINE
# ============================================================
func _boss_physics(pl: Node, has: bool, d: Vector2, delta: float) -> void:
	_valve_open = move_toward(_valve_open, 1.0 if state == VALVES else 0.0, delta * 4.0)
	_smoke_t -= delta
	if _smoke_t <= 0.0 and Art.on_screen(z, z.global_position, 300.0):
		_smoke_t = 0.12 if state == CHARGE else 0.35
		Particles.burst(z.get_parent(), z.global_position + Vector2(z._dir * 26.0 * z.wf * z.sc, -82.0 * z.sc), "smoke", Vector2(-z._dir * 0.3, -1.0), 1)
	if has and not _met and absf(d.x) < 900.0:
		_met = true
		z._noticed = true
		Game.story.emit("boss", {"z": z})
		Sfx.play("en_whistle", z.global_position, 2.0, 0.0, 1)
		z._popup("THE ENGINE", Color("ffb050"), 22, -170.0)
	if not has or not _met:
		z.velocity.x = move_toward(z.velocity.x, 0.0, 800.0 * delta)
		return
	_drop_cd -= delta
	_charge_cd -= delta
	match state:
		WALK:
			var want: float = signf(d.x) if absf(d.x) > 6.0 else z._dir
			if want != z._dir:
				_behind_t += delta
				if _behind_t > 0.45:
					z._dir = want
					_behind_t = 0.0
			var v := 0.0
			if absf(d.x) > 230.0:
				v = z._dir * float(z.chase_speed)
			elif absf(d.x) < 120.0:
				v = -z._dir * float(z.walk_speed)
			z.velocity.x = move_toward(z.velocity.x, v, 400.0 * delta)
			z._walk_phase += delta * absf(z.velocity.x) / 22.0
			if absf(z.velocity.x) > 10.0 and _step_snd <= 0.0:
				_step_snd = 0.55
				Sfx.play("hl_stomp", z.global_position, -6.0, 0.15, 2)
			if _cd > 0.0:
				return
			if _drop_cd <= 0.0 and _alive_dropped() < DROP_MAX:
				_drop()
				_drop_cd = DROP_EVERY
				_cd = 0.8
			elif _charge_cd <= 0.0 or absf(d.x) > 560.0:
				_whistle(WHISTLE_T)
			elif absf(d.x) < STEAM_R + 30.0 and want == z._dir:
				state = STEAM_WIND_S
				_st = STEAM_WIND
				Sfx.play("hl_hiss", z.global_position, 0.0, 0.1, 2)
		STEAM_WIND_S:
			z.velocity.x = move_toward(z.velocity.x, 0.0, 800.0 * delta)
			_steam_dir = _aim_steam(pl)
			if _st <= 0.0:
				state = STEAM
				_st = STEAM_T
				_hit_done = false
				steams += 1
				Sfx.play("en_steam", z.global_position, 2.0, 0.05, 2)
		STEAM:
			z.velocity.x = move_toward(z.velocity.x, 0.0, 800.0 * delta)
			if Engine.get_physics_frames() % 3 == 0 and Art.on_screen(z, z.global_position):
				Particles.burst(z.get_parent(), _nozzle() + _steam_dir * 60.0, "mist", _steam_dir, 3)
			if not _hit_done and _in_steam(pl):
				_hit_done = true
				if pl._roll_t <= 0.0:
					steam_hits += 1
				pl.hurt(STEAM_DMG, Vector2(signf(_steam_dir.x) * 1.6, -0.5))
			if _st <= 0.0:
				state = WALK
				_cd = 0.9
		WHISTLE:
			z.velocity.x = move_toward(z.velocity.x, 0.0, 900.0 * delta)
			if _st > 0.25:
				z._dir = signf(d.x) if absf(d.x) > 6.0 else z._dir
			if Engine.get_physics_frames() % 6 == 0 and Art.on_screen(z, z.global_position):
				Particles.burst(z.get_parent(), z.global_position + Vector2(-z._dir * 40.0 * z.sc, -80.0 * z.sc), "mist", Vector2.UP, 2)
			if _st <= 0.0:
				state = CHARGE
				_st = CHARGE_MAX_T
				_hit_done = false
				_rolled = false
				_crushed_ids.clear()
				charges += 1
				Sfx.play("train", z.global_position, 2.0, 0.0, 1)
		CHARGE:
			z.velocity.x = z._dir * CHARGE_V
			z._walk_phase += delta * 24.0
			var half: float = BOSS_BOX.x * 0.5 * z.sc
			if absf(d.x) < half + 10.0 and d.y > -BOSS_BOX.y * z.sc - 10.0 and d.y < 20.0:
				if pl._roll_t > 0.0:
					if not _rolled:
						pl.hurt(CHARGE_DMG, Vector2(z._dir * 2.8, -0.9))   # PERFECT DODGE
					_rolled = true
				elif not _hit_done:
					_hit_done = true
					charge_hits += 1
					pl.hurt(CHARGE_DMG, Vector2(z._dir * 2.8, -0.9))
			_crush(half)
			if Engine.get_physics_frames() % 3 == 0 and Art.on_screen(z, z.global_position):
				Particles.burst(z.get_parent(), z.global_position + Vector2(-z._dir * half * 0.6, -4.0), "spark", Vector2(-z._dir, -0.4), 3)
			var wall: bool = z.is_on_wall() and _st < CHARGE_MAX_T - 0.15
			var passed: bool = signf(d.x) == -z._dir and absf(d.x) > 240.0
			if _st <= 0.0 or wall or passed:
				if wall:
					Sfx.play("hl_stomp", z.global_position, 4.0, 0.0, 1)
					var cam: Camera2D = z.get_viewport().get_camera_2d()
					if cam != null and cam.has_method("shake"):
						cam.shake(12.0, 0.4)
				_end_charge(d)
		VALVES:
			z.velocity.x = move_toward(z.velocity.x, 0.0, 900.0 * delta)
			if Engine.get_physics_frames() % 5 == 0 and Art.on_screen(z, z.global_position):
				for i in 3:
					if _valves[i] > 0:
						Particles.burst(z.get_parent(), _valve_global(i) + Vector2(0, -8), "mist", Vector2.UP, 1)
			if _st <= 0.0:
				state = WALK
				_cd = 0.6
				_charge_cd = randf_range(CHARGE_EVERY.x, CHARGE_EVERY.y)


func _whistle(t: float) -> void:
	state = WHISTLE
	_st = t
	whistles += 1
	Sfx.play("en_whistle", z.global_position, 3.0, 0.0, 1)
	if t >= WHISTLE_T:
		z._popup("WHISTLE!", Color("ffe080"), 16, -175.0)


func _end_charge(d: Vector2) -> void:
	if _rolled:
		rolled_dodges += 1
		if rolled_dodges == 2:
			z._popup("IT READS YOUR ROLL", Color("ffb050"), 15, -175.0)
	var double: bool = float(z.hp) < float(z.max_hp) * 0.5 or rolled_dodges >= 2
	if double and not _second:
		_second = true
		double_charges += 1
		z._dir = signf(d.x) if absf(d.x) > 6.0 else -z._dir
		_whistle(0.45)
		return
	_second = false
	state = VALVES
	_st = VALVE_T
	Sfx.play("hl_vent", z.global_position, 3.0, 0.0, 1)
	if charges <= 2:
		z._popup("VALVES OPEN - SHOOT THEM!", Color("ff7050"), 15, -180.0)


func _crush(half: float) -> void:
	# קירות לבנים / ארגזים לפניו: מתנפצים
	var front: Vector2 = z.global_position + Vector2(z._dir * (half + 10.0), -40.0)
	for b in z.get_tree().get_nodes_in_group("blastable"):
		if b.has_method("hit_by_blast") and b.has_method("blast_rect") and Rect2(front - Vector2(20, 60), Vector2(40, 100)).intersects(b.blast_rect()):
			b.hit_by_blast(front, 70.0)
	for o in z.get_tree().get_nodes_in_group("zombies"):
		if o == z or o.dead or _crushed_ids.has(o.get_instance_id()):
			continue
		var dx: float = (o.global_position.x - z.global_position.x) * z._dir
		if dx > -half and dx < half + 20.0 and absf(o.global_position.y - z.global_position.y) < 60.0:
			_crushed_ids[o.get_instance_id()] = true
			crushed += 1
			o.take_damage(80, o.global_position + Vector2(0, -30), Vector2(z._dir, -0.5), true, {"source": "hazard", "fixed": 80})


func _alive_dropped() -> int:
	var n := 0
	for c in _dropped:
		if is_instance_valid(c) and not c.dead:
			n += 1
	return n


func _drop() -> void:
	var m := _main()
	if m == null or not m.has_method("_spawn_zombie"):
		return
	drops += 1
	_passengers = maxi(0, _passengers - 2)
	if _passengers == 0:
		_passengers = 4   # עוד גופות "עולות" מהקבינה
	for i in 2:
		var x: float = z.global_position.x - z._dir * (BOSS_BOX.x * 0.5 * z.sc + 20.0 + float(i) * 46.0)
		var c: Node = m._spawn_zombie(x, z.global_position.y, 0)
		if c == null:
			continue
		c.lie_down()
		c.wake_range = 260.0
		_dropped.append(c)
	Sfx.play("hl_clank", z.global_position, 2.0, 0.1, 2)
	z._popup("PASSENGERS", Color("c0a0a0"), 15, -170.0)


func _nozzle() -> Vector2:
	return z.global_position + Vector2(z._dir * 50.0 * z.wf * z.sc, -34.0 * z.sc)


func _aim_steam(pl: Node) -> Vector2:
	var to: Vector2 = pl.global_position + Vector2(0, -30) - _nozzle()
	var v := to.normalized()
	if v.x * z._dir < 0.35:   # רק קדימה
		v = Vector2(z._dir * 0.35, signf(v.y) * 0.94).normalized()
	return v


func _in_steam(pl: Node) -> bool:
	var p: Vector2 = pl.global_position + Vector2(0, -30) - _nozzle()
	var along := p.dot(_steam_dir)
	if along < 0.0 or along > STEAM_R:
		return false
	var side := absf(p.dot(Vector2(-_steam_dir.y, _steam_dir.x)))
	return side < 26.0 + along * 0.3


func _valve_global(i: int) -> Vector2:
	return z.global_position + Vector2(float(VALVE_X[i]) * z._dir * z.wf * z.sc, -64.0 * z.sc)


func _boss_damage(_amount: int, hit_pos: Vector2, dir: Vector2, src: Dictionary, s: String) -> bool:
	if not (s == "bullet" or s == "melee"):
		_hit_kind = "blast"
		return true
	var lx: float = (hit_pos.x - z.global_position.x) * z._dir / (z.sc * z.wf)
	var ly: float = (hit_pos.y - z.global_position.y) / z.sc
	# שסתומים (הפס העליון)
	if ly < -54.0:
		var vi := -1
		var best := INF
		for i in 3:
			if _valves[i] <= 0 or state != VALVES:
				continue
			var dd := absf(lx - float(VALVE_X[i]))
			if dd < best:
				best = dd
				vi = i
		if vi >= 0:
			valve_hits += 1
			_hit_kind = "valve"
			_valves[vi] -= hit_damage(_amount, hit_pos, src)
			Sfx.play("metal_ping", hit_pos, 0.0, 0.1, 3)
			if _valves[vi] <= 0:
				valves_broken += 1
				z._popup("VALVE %d/3" % valves_broken, Color("ff7050"), 20, -180.0)
				Sfx.play("hl_vent", hit_pos, 4.0, 0.0, 1)
				Particles.burst(z.get_parent(), hit_pos, "fire", Vector2.UP, 12)
				Particles.burst(z.get_parent(), hit_pos, "mist", Vector2.UP, 8)
			return true
		for i in 3:   # שסתום שבור: פתוח לתמיד
			if _valves[i] <= 0 and absf(lx - float(VALVE_X[i])) < 14.0:
				_hit_kind = "stub"
				return true
	if valves_broken >= 3 or state == VALVES:
		_hit_kind = "open"
	elif lx > 30.0 and ly > -48.0 and ly < -18.0:
		_hit_kind = "face"
	else:
		_hit_kind = "armor"
		_armor_pop += 1
		if Art.on_screen(z, hit_pos):
			Particles.burst(z.get_parent(), hit_pos, "spark", Vector2(-dir.x, -0.5), 3)
		if _armor_pop % 8 == 1:
			z._popup("CLANG", Color("d0d4dc"), 13, -160.0)
	return true


func wants_redraw() -> bool:
	return true


# ============================================================
#  ציור
# ============================================================
const STEEL := Color("5a6068")
const STEEL_D := Color("33373e")
const RUST := Color("7a4a2a")
const TANK := Color("8a8a3a")
const HOSE := Color("2a2622")
const GAS := Color(0.7, 0.85, 0.45)


func draw() -> bool:
	if _boss():
		return _draw_engine()
	if crawl:
		return _draw_crawler()
	begin_draw()
	var p: float = z._walk_phase
	_rr = _rear * 8.0
	_shk = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) if state == VENT else Vector2.ZERO
	var st := col(STEEL)
	var st_d := col(STEEL_D)
	var rust := col(RUST)
	var sk := col(z.skin)
	var sk_d := col(Art.shade(z.skin, 0.25))
	var moving: bool = absf(z.velocity.x) > 10.0
	# 4 רגליים: זוגות אלכסוניים מתחלפים. הרחוקות כהות ומאחור
	var hips := [-30.0, -13.0, 9.0, 26.0]
	var legs := []
	for i in 4:
		var ph := p + (PI if i % 2 == 1 else 0.0)
		var lift := maxf(0.0, cos(ph)) * 5.0 if moving else 0.0
		var fx: float = hips[i] + (sin(ph) * 7.0 if moving else 0.0)
		var foot := Vector2(fx, -lift)
		if state == STOMP_WIND_S and i >= 2:
			foot = Vector2(fx + 5.0, -16.0 * _rear)
		var hip := _L(Vector2(hips[i], -24.0))
		var knee := Art.joint(hip, foot, 13.0, 14.0, -1.0)
		legs.append([hip, knee, foot, i % 2 == 1])
	for L in legs:
		if L[3]:
			_rail_leg(L[0], L[1], L[2], st_d, true)
	# השלד: קורת מסילה חלודה עם ברגים
	var beam := PackedVector2Array([_L(Vector2(-35, -29)), _L(Vector2(31, -29)), _L(Vector2(31, -21)), _L(Vector2(-35, -21))])
	Art.fill_shaded(z, beam, rust, 0.15, 0.4)
	DrawBatch.line(z, _L(Vector2(-34, -25)), _L(Vector2(30, -25)), col(Art.shade(RUST, 0.45)), 1.0)
	for q in 7:
		DrawBatch.circle(z, _L(Vector2(-31.0 + float(q) * 10.0, -27.0)), 0.9, col(Color("c0a080")))
	# הגופה: שוכבת על הבטן לאורך השלד, רגליים מקופלות מאחור, קשורה ברצועות
	var pa := col(Art.shade(z.pants, 0.1))
	Art.limb(z, PackedVector2Array([_L(Vector2(-12, -34)), _L(Vector2(-22, -41)), _L(Vector2(-30, -36))]), 4.2, pa)
	Art.limb(z, PackedVector2Array([_L(Vector2(-10, -32)), _L(Vector2(-24, -36)), _L(Vector2(-33, -30))]), 4.4, col(z.pants))
	DrawBatch.circle(z, _L(Vector2(-31, -37)), 2.0, col(Color("1a1a1a")))   # כף רגל יחפה/נעל
	var belly := Art.ellipse(_L(Vector2(5, -30)), 12.0, 6.0, 0.0, 14)
	Art.fill_shaded(z, belly, sk_d, 0.1, 0.3)
	var torso := PackedVector2Array([_L(Vector2(-14, -40)), _L(Vector2(4, -44)), _L(Vector2(20, -42)), _L(Vector2(25, -37)), _L(Vector2(20, -31)),
		_L(Vector2(2, -29)), _L(Vector2(-14, -31))])
	Art.fill_shaded(z, torso, sk, 0.16, 0.34)
	# בגדים קרועים, כתמים, נקבים תפורים
	DrawBatch.colored_polygon(z, PackedVector2Array([_L(Vector2(-12, -40)), _L(Vector2(0, -43)), _L(Vector2(2, -38)), _L(Vector2(-6, -35)), _L(Vector2(-12, -36))]), col(Art.shade(z.shirt, 0.05)))
	Art.oval(z, _L(Vector2(10, -35)), 2.4, 1.4, col(Color("4a2a3a")), 0.2, Art.NONE)
	Art.oval(z, _L(Vector2(-4, -32)), 1.8, 1.1, col(Color("5a3a2a")), 0.0, Art.NONE)
	for q in 3:
		var bx := -6.0 + float(q) * 9.0
		DrawBatch.line(z, _L(Vector2(bx, -44)), _L(Vector2(bx + 2.0, -22)), col(Color("3a2a1a")), 1.8)   # רצועות לשלד
		DrawBatch.rect(z, Rect2(_L(Vector2(bx + 0.2, -38)), Vector2(1.8, 1.8)), col(Color("8a8070")))
	# יד אחורית משתלשלת
	_dangle(_L(Vector2(17, -33)), _L(Vector2(19 + sin(z._time * 3.0) * 2.0, -15)), sk_d)
	# הבלון על הגב + צינורות שננעצים בגוף ובפה
	var tc := _tank_center() + _shk - Vector2(0, _rr * 0.15)
	if tank_learned:   # מונמך מאחורי לוח שריון
		_draw_tank(tc)
		Art.fill_shaded(z, PackedVector2Array([_L(Vector2(-6, -54)), _L(Vector2(-2, -54)), _L(Vector2(-2, -30)), _L(Vector2(-6, -30))]), st, 0.2, 0.4)
		for q in 3:
			DrawBatch.circle(z, _L(Vector2(-4, -50.0 + float(q) * 8.0)), 0.8, col(Color("c0c0b8")))
	else:
		_draw_tank(tc)
	var head := _L(Vector2(30, -34)) + Vector2(0, sin(z._time * 2.0) * 0.6)
	var hose := col(HOSE)
	DrawBatch.polyline(z, PackedVector2Array([tc + Vector2(12, -3), _L(Vector2(12, -48)), _L(Vector2(24, -45)), head + Vector2(5, -1), head + Vector2(4, 3)]), hose, 2.2)
	DrawBatch.polyline(z, PackedVector2Array([tc + Vector2(10, 2), _L(Vector2(4, -46)), _L(Vector2(6, -42))]), hose, 2.0)
	DrawBatch.polyline(z, PackedVector2Array([tc + Vector2(-2, 7), _L(Vector2(-6, -43)), _L(Vector2(-6, -40))]), hose, 1.8)
	for c0 in [_L(Vector2(6, -42)), _L(Vector2(-6, -40))]:
		DrawBatch.rect(z, Rect2(c0 - Vector2(1.5, 1.0), Vector2(3.0, 2.0)), col(Color("9a9a90")))   # חבק מתכת
	# צוואר וראש: תלוי קדימה, פה פעור עם הצינור, עין מתה
	DrawBatch.line(z, _L(Vector2(22, -38)), head + Vector2(-3, -1), sk, 4.0)
	z._head(head, sk)
	face(head, Vector2(3.5, -0.5))
	DrawBatch.colored_polygon(z, PackedVector2Array([head + Vector2(1.5, 2), head + Vector2(5.5, 1.5), head + Vector2(5, 6.5), head + Vector2(2, 6.5)]), col(Color("1e0a0c")))
	DrawBatch.line(z, head + Vector2(3, 6), head + Vector2(3.5, 2.5), hose, 1.8)
	# גז ירקרק נושף מהפה
	var gp := fmod(_gas, 1.6)
	if gp < 0.9 and not z.dead:
		var k := gp / 0.9
		Art.oval(z, head + Vector2(7.0 + k * 8.0, 5.0 - k * 6.0), 2.0 + k * 4.0, 1.5 + k * 3.0, Color(GAS.r, GAS.g, GAS.b, 0.4 * (1.0 - k)), 0.0, Art.NONE)
	# יד קדמית משתלשלת (נגררת קדימה)
	_dangle(_L(Vector2(21, -32)), _L(Vector2(26 + sin(z._time * 3.0 + 1.3) * 2.5, -13)), sk)
	# רגליים קרובות + בוכנות
	for L in legs:
		if not L[3]:
			_rail_leg(L[0], L[1], L[2], st, false)
	if state == RAM_WIND_S and not z.dead:   # קיטור משתחרר מהשסתום
		var k2 := clampf(1.0 - _st / RAM_WIND, 0.0, 1.0)
		for q in 3:
			Art.oval(z, tc + Vector2(-6.0 - float(q) * 6.0 * k2, -12.0 - float(q) * 5.0), 3.0 + float(q) * 2.0, 2.0 + float(q), Color(0.95, 0.95, 0.95, 0.45 * (1.0 - float(q) / 3.0)), 0.0, Art.NONE)
	if state == RAM and not z.dead:
		for q in 3:
			DrawBatch.line(z, Vector2(-40.0 - float(q) * 5.0, -50.0 + float(q) * 14.0), Vector2(-56.0 - float(q) * 8.0, -50.0 + float(q) * 14.0), Color(1, 0.9, 0.8, 0.35), 1.4)
	end_draw()
	return true


var _rr := 0.0
var _shk := Vector2.ZERO


func _dangle(a: Vector2, b: Vector2, c: Color) -> void:   # יד רזה ומשתלשלת של הגופה
	var m := a.lerp(b, 0.5) + Vector2(1.5, 0.0)
	Art.limb(z, PackedVector2Array([a, m, b]), 2.6, c)
	DrawBatch.line(z, b, b + Vector2(1.5, 3.0), c, 1.2)
	DrawBatch.line(z, b, b + Vector2(-1.0, 3.2), c, 1.0)


func _L(v: Vector2) -> Vector2:   # נקודה על הגוף: רועד ב-VENT, החזית מתרוממת ב-RAM_WIND / STOMP
	return v + _shk + Vector2(0.0, -_rr * clampf((v.x + 34.0) / 64.0, 0.0, 1.0))


func _rail_leg(hip: Vector2, knee: Vector2, foot: Vector2, c: Color, far: bool) -> void:
	Art.limb(z, PackedVector2Array([hip, knee, foot]), 3.4 if not far else 3.0, c)
	DrawBatch.circle(z, knee, 2.4, col(Color("2a2a2e")))
	DrawBatch.circle(z, knee, 1.0, col(Color("9a9a90")))
	# בוכנה: מהשלד אל הברך
	var a := hip + Vector2(5, -2)
	DrawBatch.line(z, a, a.lerp(knee, 0.55), col(Color("1e1e22")), 2.6)
	DrawBatch.line(z, a.lerp(knee, 0.5), knee, col(Color("b0b4b8")), 1.0)
	# כף: גלגל רכבת קטן עם אוגן
	Art.disc(z, foot + Vector2(0, -3), 3.4, col(Color("3a3a3e")), Art.OUTLINE, 1.0)
	DrawBatch.circle(z, foot + Vector2(0, -3), 1.2, col(Color("8a8a80")))
	DrawBatch.line(z, foot + Vector2(-4, -0.5), foot + Vector2(4, -0.5), col(Color("1a1a1a")), 1.2)


func _draw_tank(c: Vector2) -> void:
	var tk := col(TANK)
	var cap := PackedVector2Array()
	for i in 9:
		var a := -PI / 2.0 + PI * float(i) / 8.0
		cap.append(c + Vector2(10.0 + cos(a) * 7.0, sin(a) * 8.5))
	for i in 9:
		var a := PI / 2.0 + PI * float(i) / 8.0
		cap.append(c + Vector2(-12.0 + cos(a) * 7.0, sin(a) * 8.5))
	Art.fill_shaded(z, cap, tk, 0.22, 0.34)
	DrawBatch.line(z, c + Vector2(-8, -8), c + Vector2(-8, 8), col(Art.shade(TANK, 0.35)), 1.0)
	DrawBatch.line(z, c + Vector2(6, -8), c + Vector2(6, 8), col(Art.shade(TANK, 0.35)), 1.0)
	DrawBatch.rect(z, Rect2(c + Vector2(-5, -2.5), Vector2(9, 4)), col(Color("8a2a20")))   # פס אדום
	DrawBatch.line(z, c + Vector2(-12, -6), c + Vector2(10, -6), Color(1, 1, 0.8, 0.25), 1.2)   # ברק
	# שסתום + מד לחץ (המחוג יורד כשפוגעים)
	DrawBatch.line(z, c + Vector2(2, -8), c + Vector2(2, -12), col(Color("2a2a2a")), 1.6)
	DrawBatch.arc(z, c + Vector2(2, -13), 2.8, 0.0, TAU, 10, col(Color("aa3a2a")), 1.2)
	Art.disc(z, c + Vector2(-9, -9), 3.0, col(Color("e0dcc8")), Art.OUTLINE, 0.8)
	var r := clampf(float(_tank) / float(TANK_HP), 0.0, 1.0)
	var na := lerpf(PI * 0.9, PI * 0.1, r) + PI
	DrawBatch.line(z, c + Vector2(-9, -9), c + Vector2(-9, -9) + Vector2.from_angle(na) * 2.4, col(Color("aa1a10")), 0.8)
	# חורים שפולטים גז
	for lp in _leaks:
		DrawBatch.circle(z, lp, 1.1, col(Color("1a1a10")))
		if not z.dead:
			var k := fmod(_gas * 2.0 + lp.x, 1.0)
			DrawBatch.circle(z, lp + Vector2(-k * 6.0, -k * 5.0), 1.2 + k * 2.6, Color(0.9, 0.95, 0.85, 0.45 * (1.0 - k)))   # (עיגול: אליפסה זעירה נכשלת בטריאנגולציה)
	if state == VENT and not z.dead:
		var k := clampf(1.0 - _st / VENT_T, 0.0, 1.0)
		Art.glow(z, c, 12.0 + k * 8.0, Color(1.0, 0.35, 0.15, 0.25 + 0.4 * k))
		for q in 4:
			var a := -PI / 2.0 + (float(q) - 1.5) * 0.5
			Art.oval(z, c + Vector2.from_angle(a) * (12.0 + k * 10.0), 3.0 + k * 3.0, 2.0 + k * 2.0, Color(0.95, 0.97, 0.9, 0.55), a, Art.NONE)


# הגופה בלי השלד: זוחלת, צינורות קרועים נגררים
func _draw_crawler() -> bool:
	begin_draw()
	var sk := col(z.skin)
	var sk_d := col(Art.shade(z.skin, 0.25))
	var p: float = z._walk_phase
	var head := Vector2(14, -10)
	DrawBatch.polyline(z, PackedVector2Array([Vector2(-6, -8), Vector2(-16, -5), Vector2(-26, -2), Vector2(-34, -1)]), col(HOSE), 2.0)
	DrawBatch.polyline(z, PackedVector2Array([Vector2(-2, -10), Vector2(-14, -9), Vector2(-24, -6)]), col(HOSE), 1.6)
	z._leg(Vector2(-6, -7), Vector2(-24, -2 + sin(p) * 1.0), col(z.pants), sk_d, col(z.shoe))
	z._arm(Vector2(8, -11), Vector2(20 + sin(p) * 6.0, -1), sk_d, sk_d)
	var body := Art.ellipse(Vector2(1, -9), 12.0, 6.0, 0.05, 14)
	Art.fill_shaded(z, body, sk, 0.14, 0.32)
	DrawBatch.line(z, Vector2(-4, -14), Vector2(4, -4), col(Color("3a2a1a")), 1.6)   # רצועה קרועה
	z._head(head, sk)
	face(head, Vector2(3.5, -0.5))
	z._arm(Vector2(9, -10), Vector2(22 + sin(p + PI) * 6.0, -1), sk, sk)
	end_draw()
	return true


# ---- THE ENGINE: דוד קטר על 4 רגליים ----
func _draw_engine() -> bool:
	begin_draw()
	var p: float = z._walk_phase
	var iron := col(Color("2a2a30"))
	var brass := col(Color("8a6a3a"))
	var st := col(STEEL)
	var st_d := col(STEEL_D)
	var moving := absf(z.velocity.x) > 10.0
	# רגליים: ברך = גלגל הנעה עם חישורים, מוט חיבור בין הברכיים
	var hips := [-36.0, -16.0, 10.0, 30.0]
	var knees := []
	var feet := []
	for i in 4:
		var ph := p + (PI if i % 2 == 1 else 0.0)
		var lift := maxf(0.0, cos(ph)) * 4.0 if moving else 0.0
		var foot := Vector2(hips[i] + (sin(ph) * 6.0 if moving else 0.0), -lift)
		var hip := Vector2(hips[i], -30.0)
		knees.append(Art.joint(hip, foot, 15.0, 16.0, -1.0))
		feet.append(foot)
	for i in [1, 3]:
		_engine_leg(Vector2(hips[i], -30.0), knees[i], feet[i], st_d, p)
	# גופות בכלוב מאחורי הקבינה
	var cage := Rect2(Vector2(-66, -66), Vector2(16, 34))
	for q in mini(_passengers, 3):
		var hx := -62.0 + float(q) * 5.0
		Art.oval(z, Vector2(hx, -44.0 + float(q % 2) * 6.0), 3.0, 6.0, col(Color("8a8494")), 0.2, Art.OUTLINE)
		DrawBatch.circle(z, Vector2(hx + 1.0, -54.0 + float(q % 2) * 6.0), 2.4, col(Color("9a94a0")))
		DrawBatch.line(z, Vector2(hx + 2.0, -46.0), Vector2(hx - 6.0, -36.0 + float(q) * 2.0), col(Color("7a7484")), 1.4)   # יד מחוץ לסורגים
	for q in 5:
		DrawBatch.line(z, cage.position + Vector2(float(q) * 4.0, 0), cage.position + Vector2(float(q) * 4.0, cage.size.y), col(Color("1a1a1e")), 1.0)
	DrawBatch.rect(z, cage, col(Color("1a1a1e")), false, 1.2)
	# קבינה
	var cab := PackedVector2Array([Vector2(-50, -30), Vector2(-50, -74), Vector2(-46, -78), Vector2(-30, -78), Vector2(-30, -30)])
	Art.fill_shaded(z, cab, col(Color("5a2018")), 0.14, 0.36)
	DrawBatch.rect(z, Rect2(Vector2(-46, -70), Vector2(12, 12)), Color(1.0, 0.6, 0.25, 0.9))
	DrawBatch.circle(z, Vector2(-40, -63), 3.0, Color(0.12, 0.08, 0.08))   # נהג מת בחלון
	DrawBatch.rect(z, Rect2(Vector2(-42, -59), Vector2(5, 3)), Color(0.12, 0.08, 0.08))
	Art.glow(z, Vector2(-40, -64), 12.0, Color(1.0, 0.5, 0.2, 0.25))
	DrawBatch.line(z, Vector2(-38, -78), Vector2(-38, -84), brass, 2.0)   # משרוקית
	if state == WHISTLE:
		for q in 3:
			Art.oval(z, Vector2(-38.0 - float(q) * 3.0, -88.0 - float(q) * 5.0), 2.5 + float(q) * 2.0, 2.0 + float(q) * 1.5, Color(1, 1, 1, 0.5 - float(q) * 0.12), 0.0, Art.NONE)
	# דוד
	var boiler := PackedVector2Array()
	for i in 9:
		var a := -PI / 2.0 + PI * float(i) / 8.0
		boiler.append(Vector2(38.0 + cos(a) * 4.0, -46.0 + sin(a) * 16.0))
	for i in 9:
		var a := PI / 2.0 + PI * float(i) / 8.0
		boiler.append(Vector2(-32.0 + cos(a) * 3.0, -46.0 + sin(a) * 16.0))
	Art.fill_shaded(z, boiler, iron, 0.16, 0.4)
	for bx in [-22.0, -4.0, 16.0]:
		DrawBatch.line(z, Vector2(bx, -61.5), Vector2(bx, -30.5), brass, 2.0)
	for q in 12:
		DrawBatch.circle(z, Vector2(-30.0 + float(q) * 5.8, -59.0), 0.7, col(Color("6a6a70")))
	DrawBatch.line(z, Vector2(-30, -55), Vector2(36, -55), Color(1, 1, 1, 0.12), 2.0)   # ברק
	if state == VALVES or valves_broken >= 3:   # הדוד חם: סדקים זוהרים
		var a := 0.4 + 0.3 * sin(z._time * 12.0)
		DrawBatch.polyline(z, PackedVector2Array([Vector2(-10, -40), Vector2(-6, -36), Vector2(-8, -32)]), Color(1.0, 0.4, 0.1, a), 1.2)
		DrawBatch.polyline(z, PackedVector2Array([Vector2(8, -50), Vector2(12, -44), Vector2(10, -38)]), Color(1.0, 0.4, 0.1, a), 1.2)
	# גופות קשורות בשרשראות לצד הדוד
	for q in mini(_passengers, 3):
		var bx := -18.0 + float(q) * 17.0
		DrawBatch.line(z, Vector2(bx, -46), Vector2(bx + 2.0, -40), col(Color("4a4a4e")), 1.0)
		Art.fill_shaded(z, PackedVector2Array([Vector2(bx - 5, -40), Vector2(bx + 7, -40), Vector2(bx + 6, -33), Vector2(bx - 4, -33)]), col(Color("7a7484")), 0.1, 0.3)
		DrawBatch.circle(z, Vector2(bx + 9.0, -38.0), 2.6, col(Color("8a8494")))
		DrawBatch.line(z, Vector2(bx + 4, -34), Vector2(bx + 6, -25 + sin(z._time * 2.0 + float(q)) * 1.5), col(Color("7a7484")), 1.3)
	# ארובה
	Art.fill_shaded(z, PackedVector2Array([Vector2(22, -61), Vector2(30, -61), Vector2(32, -74), Vector2(35, -80), Vector2(17, -80), Vector2(20, -74)]), iron, 0.12, 0.4)
	DrawBatch.line(z, Vector2(17, -80), Vector2(35, -80), brass, 1.6)
	for q in 3:   # עשן
		var k := fmod(z._time * 0.7 + float(q) / 3.0, 1.0)
		Art.oval(z, Vector2(26.0 - k * 14.0, -84.0 - k * 30.0), 4.0 + k * 9.0, 3.0 + k * 6.0, Color(0.25, 0.24, 0.26, 0.5 * (1.0 - k)), 0.0, Art.NONE)
	# שסתומים
	for i in 3:
		var vx: float = VALVE_X[i]
		var up := _valve_open * 6.0
		if _valves[i] <= 0:   # שבור: גדם שפולט קיטור
			DrawBatch.polyline(z, PackedVector2Array([Vector2(vx - 3, -61), Vector2(vx - 1, -66), Vector2(vx + 1, -63), Vector2(vx + 3, -67), Vector2(vx + 4, -61)]), col(Color("3a3a3a")), 1.6)
			Art.glow(z, Vector2(vx, -64), 5.0, Color(1.0, 0.4, 0.1, 0.5))
			Art.oval(z, Vector2(vx, -71.0 - fmod(z._time * 3.0, 1.0) * 6.0), 2.5, 3.5, Color(1, 1, 1, 0.35), 0.0, Art.NONE)
			continue
		DrawBatch.line(z, Vector2(vx, -61), Vector2(vx, -63.0 - up), col(Color("3a3a3a")), 2.0)
		var wc := col(Color("c03020") if _valve_open > 0.1 else Color("8a6a3a"))
		DrawBatch.arc(z, Vector2(vx, -64.0 - up), 3.6, 0.0, TAU, 12, wc, 1.6)
		DrawBatch.line(z, Vector2(vx - 3.6, -64.0 - up), Vector2(vx + 3.6, -64.0 - up), wc, 1.0)
		if _valve_open > 0.1:
			Art.glow(z, Vector2(vx, -64.0 - up), 9.0 * _valve_open, Color(1.0, 0.3, 0.15, 0.45))
			for q in 2:
				var k := fmod(z._time * 2.5 + float(q) * 0.5 + float(i) * 0.3, 1.0)
				Art.oval(z, Vector2(vx, -70.0 - up - k * 14.0), 2.0 + k * 4.0, 2.5 + k * 4.0, Color(1, 1, 1, 0.5 * (1.0 - k) * _valve_open), 0.0, Art.NONE)
	# תא העשן מלפנים + פני גופה ענקית
	Art.disc(z, Vector2(40, -46), 14.0, col(Color("1e1e22")), Art.OUTLINE, 1.4)
	var fc := Vector2(42, -44)
	Art.oval(z, fc, 8.0, 10.0, col(z.skin), 0.0, Art.OUTLINE)
	Art.oval(z, fc + Vector2(-3.0, -3.0), 2.4, 1.8, col(Color("1a0a0a")), 0.0, Art.NONE)
	Art.oval(z, fc + Vector2(3.0, -3.0), 2.4, 1.8, col(Color("1a0a0a")), 0.0, Art.NONE)
	DrawBatch.circle(z, fc + Vector2(-3.0, -3.0), 0.9, Color(0.95, 0.9, 0.8))
	DrawBatch.circle(z, fc + Vector2(3.0, -3.0), 0.9, Color(0.95, 0.9, 0.8))
	var jaw := 3.0 + (2.0 if state == STEAM or state == STEAM_WIND_S or state == WHISTLE else 0.0)
	DrawBatch.colored_polygon(z, PackedVector2Array([fc + Vector2(-3.5, 2), fc + Vector2(3.5, 2), fc + Vector2(3, 3.0 + jaw), fc + Vector2(-3, 3.0 + jaw)]), col(Color("1e0808")))
	for q in 4:
		DrawBatch.line(z, fc + Vector2(-2.6 + float(q) * 1.7, 2.2), fc + Vector2(-2.6 + float(q) * 1.7, 3.2), col(Color("d8d0a8")), 0.7)
	DrawBatch.polyline(z, PackedVector2Array([fc + Vector2(-7, -6), fc + Vector2(-9, 0), fc + Vector2(-7, 6)]), col(Color("3a1a1a")), 0.8)   # תפרים
	# פנס
	Art.disc(z, Vector2(40, -64), 4.0, col(Color("3a3a3a")), Art.OUTLINE, 1.0)
	DrawBatch.circle(z, Vector2(41, -64), 2.6, Color(1.0, 0.95, 0.7).lerp(Color(0.5, 0.48, 0.4), 1.0 - _glare))
	if _glare > 0.02:
		Art.glow(z, Vector2(42, -64), 14.0 + 10.0 * _glare, Color(1.0, 0.95, 0.6, 0.55 * _glare))
		DrawBatch.colored_polygon(z, PackedVector2Array([Vector2(43, -66), Vector2(200, -84), Vector2(200, -36), Vector2(43, -62)]), Color(1.0, 0.95, 0.65, 0.12 * _glare))
	# פגוש פרות
	var cw := PackedVector2Array([Vector2(36, -30), Vector2(48, -30), Vector2(58, -3), Vector2(36, -3)])
	Art.fill_shaded(z, cw, col(Color("8a2018")), 0.15, 0.4)
	for q in 4:
		DrawBatch.line(z, Vector2(38.0 + float(q) * 4.0, -29), Vector2(40.0 + float(q) * 5.0, -4), col(Color("3a0a08")), 1.0)
	# רגליים קרובות
	for i in [0, 2]:
		_engine_leg(Vector2(hips[i], -30.0), knees[i], feet[i], st, p)
	DrawBatch.line(z, knees[0] + Vector2(cos(p) * 4.0, sin(p) * 4.0), knees[2] + Vector2(cos(p) * 4.0, sin(p) * 4.0), col(Color("b0b4b8")), 2.0)   # מוט חיבור
	# קיטור מלפנים
	if (state == STEAM or state == STEAM_WIND_S) and not z.dead:
		var ld := Vector2(_steam_dir.x * z._dir, _steam_dir.y)
		var n0 := Vector2(50, -34)
		var rng: float = STEAM_R / z.sc
		var k := 1.0 if state == STEAM else 0.25
		for q in 8:
			var f := float(q) / 7.0
			var wob := sin(z._time * 20.0 + float(q)) * 2.0
			Art.oval(z, n0 + ld * rng * f * k + Vector2(0, wob), 3.0 + f * 10.0 * k, 2.5 + f * 8.0 * k, Color(0.96, 0.97, 1.0, (0.55 - f * 0.3) * k + 0.1), ld.angle(), Art.NONE)
	if state == CHARGE and not z.dead:
		for q in 4:
			DrawBatch.line(z, Vector2(-58.0 - float(q) * 4.0, -70.0 + float(q) * 18.0), Vector2(-80.0 - float(q) * 8.0, -70.0 + float(q) * 18.0), Color(1, 0.9, 0.7, 0.35), 2.0)
	end_draw()
	return true


func _engine_leg(hip: Vector2, knee: Vector2, foot: Vector2, c: Color, p: float) -> void:
	Art.limb(z, PackedVector2Array([hip, knee, foot]), 5.0, c)
	# גלגל הנעה עם חישורים (מסתובב)
	Art.disc(z, knee, 7.0, col(Color("2a2a2e")), Art.OUTLINE, 1.2)
	DrawBatch.arc(z, knee, 6.0, 0.0, TAU, 14, col(Color("8a2018")), 1.4)
	for q in 4:
		var a := p + float(q) * PI / 4.0
		DrawBatch.line(z, knee - Vector2.from_angle(a) * 5.5, knee + Vector2.from_angle(a) * 5.5, col(Color("6a6a70")), 0.9)
	DrawBatch.circle(z, knee, 1.6, col(Color("b0a080")))
	Art.fill(z, PackedVector2Array([foot + Vector2(-7, 0), foot + Vector2(7, 0), foot + Vector2(5, -3), foot + Vector2(-5, -3)]), col(Color("3a3a3e")), Art.OUTLINE, 1.0)


# ============================================================
#  שלד קרוס שנשאר במקום (נעלם לאט)
# ============================================================
class Wreck extends Node2D:
	const Art := preload("res://art.gd")
	var side := 1.0
	var k := 1.0
	var _t := 0.0

	func _ready() -> void:
		z_index = 2

	func _process(delta: float) -> void:
		_t += delta
		if _t > 14.0:
			queue_free()
			return
		if Engine.get_process_frames() % 6 == 0 and Art.on_screen(self, global_position):
			queue_redraw()

	func _draw() -> void:
		DrawBatch.begin(self)
		_draw_b()
		DrawBatch.end(self)

	func _draw_b() -> void:
		var a := clampf((14.0 - _t) / 2.0, 0.0, 1.0)
		DrawBatch.set_transform(self, Vector2.ZERO, 0.0, Vector2(side * k, k))
		var rust := Color(0.42, 0.26, 0.15, a)
		var st := Color(0.25, 0.27, 0.3, a)
		# קורות שבורות על הרצפה
		DrawBatch.colored_polygon(self, PackedVector2Array([Vector2(-38, -10), Vector2(10, -16), Vector2(12, -9), Vector2(-36, -4)]), rust)
		DrawBatch.colored_polygon(self, PackedVector2Array([Vector2(8, -8), Vector2(34, -2), Vector2(33, 0), Vector2(7, -3)]), rust.darkened(0.2))
		# רגליים מפוזרות
		DrawBatch.line(self, Vector2(-30, -6), Vector2(-44, -1), st, 3.0)
		DrawBatch.line(self, Vector2(-12, -10), Vector2(-6, -24), st, 3.0)
		DrawBatch.line(self, Vector2(-6, -24), Vector2(4, -20), st, 3.0)
		DrawBatch.line(self, Vector2(20, -6), Vector2(36, -12), st, 3.0)
		# בלון קרוע
		DrawBatch.colored_polygon(self, PackedVector2Array([Vector2(-26, -12), Vector2(-14, -22), Vector2(-6, -18), Vector2(-10, -14), Vector2(-4, -10), Vector2(-20, -6)]), Color(0.4, 0.4, 0.18, a))
		DrawBatch.polyline(self, PackedVector2Array([Vector2(-14, -22), Vector2(-12, -16), Vector2(-6, -18)]), Color(0.1, 0.08, 0.06, a), 1.0)
		if _t < 6.0:   # עשן עולה מההריסה
			for q in 3:
				var f := fmod(_t * 0.6 + float(q) / 3.0, 1.0)
				var c := Vector2(-14.0 + float(q) * 6.0, -20.0 - f * 40.0)
				DrawBatch.circle(self, c, 4.0 + f * 8.0, Color(0.2, 0.2, 0.2, 0.35 * (1.0 - f) * (1.0 - _t / 6.0)))


# ============================================================
#  בלון שנקרע כשהזומבי מת: שורק רגע ומתפוצץ
# ============================================================
class Rupture extends Node2D:
	const Boom := preload("res://explosion.gd")
	const Sfx := preload("res://sfx.gd")
	var from_hauler := true
	var _t := 0.0
	const FUSE := 0.9

	func _ready() -> void:
		z_index = 8
		Sfx.play("hl_vent", global_position, 0.0, 0.05, 2)

	func _process(delta: float) -> void:
		_t += delta
		if _t >= FUSE:
			Boom.blast(get_parent(), global_position, 100.0, 50.0, 45, 1, "hauler_tank")
			queue_free()
			return
		queue_redraw()

	func _draw() -> void:
		DrawBatch.begin(self)
		_draw_b()
		DrawBatch.end(self)

	func _draw_b() -> void:
		var k := _t / FUSE
		DrawBatch.circle(self, Vector2.ZERO, 6.0 + k * 6.0, Color(1.0, 0.35, 0.1, 0.25 + 0.45 * k * (0.5 + 0.5 * sin(_t * 40.0))))
		for q in 5:
			var a := -PI / 2.0 + (float(q) - 2.0) * 0.45
			var r := 8.0 + k * 18.0
			DrawBatch.circle(self, Vector2.from_angle(a) * r, 3.0 + k * 4.0, Color(0.95, 0.97, 0.9, 0.5))
