extends "res://enemies/zombie_type.gd"
# ============================================================
#  BONECRAWLER (שלב 58, "WHALE GRAVEYARD") - שלושה-ארבעה מתים שהתמזגו בתוך כלוב צלעות של לווייתן, והולכים כמו נדל של עצם:
#    עמוד שדרה למעלה, צלעות מעוקלות מסביב, והידיים והרגליים של המתים בולטות מבין הצלעות כרגליים. ראש אחד מקדימה (מוביל),
#    ראש אחד מאחור, ובפנים - לב ECHO זוהר (הליבה) שמחזיק את כולם יחד.
#  מה הוא למד, וממה: ECHO גדל בכל דבר מת - גם במתים של מינים אחרים. הלווייתנים מתו כאן לפני מאה שנה, והנבגים מצאו בהם שריון
#    מוכן. הוא נולד מהפגרים (effects/s58_decor.gd EchoCarcass) וגם מסתובב בתחנה.
#    הצלעות (RIBS לכל קצה, RIB_HP כל אחת) חוסמות: פגיעה בקצה שובר את הצלע החיצונית (רק LEAK מהנזק עובר).
#    קצה בלי צלעות = הליבה חשופה מהצד הזה (x CORE_MULT). מלמעלה - עמוד השדרה (x SPINE_MULT). אש נכנסת בין הצלעות (x FIRE_MULT).
#    פיצוץ שובר צלע מכל קצה.
#  התקפה: REAR - מתרומם מקדימה והצלעות נפתחות כמו לסתות (REAR_T: הליבה חשופה מקדימה! חלון) ואז SNAP - זינוק קדימה (SNAP_DMG).
#  לומד (main meta "bc_cores" >= LEARN - כמה ליבות פוצצת): "IT TURNS ITS BONES TO YOU NOW" - תמיד מסובב אליך את הקצה עם
#    יותר צלעות (הולך אחורה אם צריך), ואחרי צרור נזק (CURL_DMG בתוך CURL_WIN) מתכרבל לכדור (CURL_T, x CURL_MULT) ומתגלגל.
#    נגד: לעבור לצד השני (גלגול / קפיצה מעליו), רימונים, לחכות ל-REAR.
#  לשנות: RIBS, RIB_HP, LEAK, CORE_MULT, SPINE_MULT, FIRE_MULT, REAR_R, REAR_T, SNAP_V, SNAP_DMG, RECOVER_T, LEARN,
#    CURL_DMG, CURL_WIN, CURL_T, CURL_MULT, CURL_CD, TURN_T.
# ============================================================

const SOUNDS := {
	"bc_crack": [["C", 0, 0, 0.0, 0.2, 0.0, 14.0, 0.8, 1.0, 0], ["N", 0, 0, 0.0, 0.25, 0.0, 10.0, 0.5, 0.45, 0, 0.2], ["S", 700, 260, 0.0, 0.18, 0.0, 12.0, 0.35, 1.0, 0]],
	"bc_click": [["C", 0, 0, 0.0, 0.06, 0.0, 50.0, 0.35, 1.0, 0], ["C", 0, 0, 0.09, 0.06, 0.0, 50.0, 0.3, 1.0, 0], ["C", 0, 0, 0.17, 0.06, 0.0, 50.0, 0.3, 1.0, 0]],
	"bc_hiss": {"rev": 0.25, "drive": 2.2, "layers": [["V", 110, 90, 0.0, 0.7, 0.05, 3.0, 0.6, 1.0, 0.05, 0, [380, 900, 18]], ["V", 170, 130, 0.0, 0.6, 0.05, 3.0, 0.4, 1.0, 0.06, 0, [500, 1200, 20]], ["N", 0, 0, 0.0, 0.6, 0.05, 3.0, 0.4, 0.5, 0, 0.3]]},
	"bc_snap": {"drive": 2.4, "layers": [["C", 0, 0, 0.0, 0.25, 0.0, 10.0, 0.9, 1.0, 0], ["N", 0, 0, 0.0, 0.3, 0.0, 8.0, 0.6, 0.25, 0], ["S", 90, 45, 0.0, 0.3, 0.0, 8.0, 0.5, 1.0, 0]]},
	"bc_curl": [["C", 0, 0, 0.0, 0.08, 0.0, 30.0, 0.5, 1.0, 0], ["C", 0, 0, 0.07, 0.08, 0.0, 30.0, 0.5, 1.0, 0], ["C", 0, 0, 0.14, 0.08, 0.0, 30.0, 0.5, 1.0, 0], ["N", 0, 0, 0.0, 0.35, 0.02, 5.0, 0.35, 0.2, 0]],
}

const DebrisScript := preload("res://debris.gd")
const Decor := preload("res://effects/s58_decor.gd")

const RIBS := 3                  # צלעות שריון בכל קצה
const RIB_HP := 20
const LEAK := 0.2
const CORE_MULT := 1.6
const SPINE_MULT := 0.35
const FIRE_MULT := 1.25
const REAR_R := 150.0
const REAR_T := 0.6
const SNAP_V := 380.0
const SNAP_T := 0.26
const SNAP_DMG := 2
const RECOVER_T := 0.55
const REAR_CD := Vector2(1.1, 1.9)
const LEARN := 2
const CURL_DMG := 32
const CURL_WIN := 1.0
const CURL_T := 1.6
const CURL_MULT := 0.2
const CURL_CD := 4.5
const TURN_T := 0.45
const RIB_X := [44.0, 32.0, 20.0]   # מיקום הצלעות מהמרכז (החיצונית ראשונה)
const HALF := 52.0

enum {CRAWL, REAR, SNAP, RECOVERY, CURL, TURN}
var state := CRAWL
# לבדיקות
var rib_hits := 0
var ribs_broken := 0
var core_hits := 0
var spine_hits := 0
var rears := 0
var snaps := 0
var snap_hits := 0
var curls := 0
var turns := 0
var backward_t := 0.0

var learned := false
var _rib := [[RIB_HP, RIB_HP, RIB_HP], [RIB_HP, RIB_HP, RIB_HP]]   # [קדמי, אחורי], החיצונית ראשונה
var _st := 0.0
var _cd := 1.0
var _hit := false
var _mult := 1.0
var _core_last := false
var _dmg_win := []               # [זמן, נזק]
var _curl_cd := 0.0
var _roll := 0.0
var _rear_k := 0.0               # 0 שטוח .. 1 מורם ופתוח
var _curl_k := 0.0
var _turn_to := 1.0
var _pop_t := 0.0
var _var := []                   # [עור2, עור3, ריר, ראש אחורי]


func stats() -> Dictionary:
	return {"name": "BONECRAWLER", "hp": 150, "walk": 38.0, "chase": 74.0, "damage": 2, "bite_delay": 1.0, "scale": 1.12, "width": 1.0,
		"duck": 0.0, "cover": 0.0, "skin": Color("8a9a84"), "shirt": Color("4a3a32"), "pants": Color("3a3632"), "shoe": Color("2a2420"),
		"points": 650, "ragdoll": false}


func brain_overrides() -> Dictionary:
	return {"aggression": 0.7}


func use_brain_movement() -> bool:
	return false


func can_bite() -> bool:
	return false


func _main() -> Node:
	return z.get_parent()


func _floor() -> float:
	var m := _main()
	var st = m.get("_stage") if m != null else null
	return float(st.floor_y) if st != null else 630.0


func setup() -> void:
	var m := _main()
	learned = m != null and int(m.get_meta("bc_cores", 0)) >= LEARN
	var r := RandomNumberGenerator.new()
	r.seed = z.get_instance_id() * 9 + 5
	var skins := [Color("9a8c7c"), Color("7a8a72"), Color("a49482"), Color("6e7a6a")]
	_var = [skins[r.randi() % skins.size()], skins[r.randi() % skins.size()], r.randf_range(0.4, 1.0), r.randf() < 0.7]
	z.set_meta("no_cover", true)
	_resize(Vector2(HALF * 2.0, 44.0))


func _resize(b: Vector2) -> void:
	var rs := z._shape.shape as RectangleShape2D
	rs.size = Vector2(b.x * z.wf * z.sc, b.y * z.sc)
	z._shape.position = Vector2(0.0, -b.y * 0.5 * z.sc)


func ribs_left(e: int) -> int:
	var n := 0
	for h in _rib[e]:
		if int(h) > 0:
			n += 1
	return n


func _outer(e: int) -> int:
	for i in RIBS:
		if int(_rib[e][i]) > 0:
			return i
	return -1


# ============================================================
#  תנועה
# ============================================================
func physics(pl: Node, delta: float) -> bool:
	if z.dead:
		return false
	_st -= delta
	_cd -= delta
	_curl_cd -= delta
	_pop_t -= delta
	if not z.is_on_floor():
		z.velocity.y += z.gravity * delta
	if z.global_position.y > _floor() + 6.0:   # (גוף רחב שנולד בתוך מכשול נדחף לתוך הקרקע) - קופץ החוצה
		z.global_position.y = _floor() - 2.0
		z.velocity.y = -380.0
	var has: bool = pl != null and not pl.dead
	var d: Vector2 = (pl.global_position - z.global_position) if has else Vector2.ZERO
	_rear_k = move_toward(_rear_k, 1.0 if state == REAR or state == SNAP else 0.0, delta * (3.0 if state == REAR else 2.0))
	_curl_k = move_toward(_curl_k, 1.0 if state == CURL else 0.0, delta * 4.0)
	match state:
		CRAWL:
			if not has or absf(d.x) > 1300.0:
				z.velocity.x = move_toward(z.velocity.x, 0.0, 500.0 * delta)
			else:
				var fdir: float = signf(d.x) if absf(d.x) > 6.0 else z._dir
				var head_to := fdir   # הכיוון שהראש פונה אליו
				var back := false
				if learned and ribs_left(0) < ribs_left(1):   # למד: הקצה החזק אליך - הולך אחורה
					head_to = -fdir
					back = true
				if head_to != z._dir:
					state = TURN
					_st = TURN_T
					_turn_to = head_to
					turns += 1
				else:
					var sp: float = z.chase_speed * (0.75 if back else 1.0)
					z.velocity.x = move_toward(z.velocity.x, fdir * sp if absf(d.x) > 50.0 else 0.0, 500.0 * delta)
					z._walk_phase += delta * absf(z.velocity.x) / 5.0
					if back:
						backward_t += delta
					if z.is_on_floor() and z.is_on_wall() and absf(z.velocity.x) < 25.0:
						z.velocity.y = -430.0
					if _cd <= 0.0 and z.is_on_floor() and absf(d.y) < 70.0 and absf(d.x) < REAR_R:
						if back:   # הסתובב לתקוף (חלון: הקצה השבור אליך)
							state = TURN
							_st = TURN_T * 0.6
							_turn_to = fdir
						else:
							state = REAR
							_st = REAR_T
							rears += 1
							Sfx.play("bc_hiss", z.global_position, 0.0, 0.1, 3)
		TURN:
			z.velocity.x = move_toward(z.velocity.x, 0.0, 800.0 * delta)
			z._walk_phase += delta * 9.0
			if _st <= 0.0:
				z._dir = _turn_to
				state = CRAWL
				if has and absf(d.x) < REAR_R and signf(d.x) == z._dir and _cd <= 0.0:
					state = REAR
					_st = REAR_T * 0.8
					rears += 1
					Sfx.play("bc_hiss", z.global_position, 0.0, 0.1, 3)
		REAR:
			z.velocity.x = move_toward(z.velocity.x, -z._dir * 20.0, 900.0 * delta)
			if _st <= 0.0:
				state = SNAP
				_st = SNAP_T
				snaps += 1
				_hit = false
				z.velocity.x = z._dir * SNAP_V
				Sfx.play("bc_snap", z.global_position, 2.0, 0.1, 3)
		SNAP:
			if has and not _hit:
				var x0: float = z.global_position.x + z._dir * 10.0
				var x1: float = z.global_position.x + z._dir * (HALF + 30.0) * z.sc
				var r := Rect2(minf(x0, x1), z.global_position.y - 54.0 * z.sc, absf(x1 - x0), 54.0 * z.sc)
				if r.intersects(pl.body_rect()):
					_hit = true
					if pl._roll_t <= 0.0:
						snap_hits += 1
						z._spray_blood(pl.global_position + Vector2(0, -30), Vector2(z._dir, -0.5), 8, 260.0)
					pl.hurt(SNAP_DMG, Vector2(z._dir * 1.5, -0.6))
			if _st <= 0.0:
				state = RECOVERY
				_st = RECOVER_T
		RECOVERY:
			z.velocity.x = move_toward(z.velocity.x, 0.0, 900.0 * delta)
			if _st <= 0.0:
				state = CRAWL
				_cd = randf_range(REAR_CD.x, REAR_CD.y)
		CURL:
			_roll += delta * z.velocity.x / 22.0
			if has:
				z.velocity.x = move_toward(z.velocity.x, signf(d.x) * 60.0, 300.0 * delta)
			if _st <= 0.0:
				state = CRAWL
				_curl_cd = CURL_CD
				_resize(Vector2(HALF * 2.0, 44.0))
				Sfx.play("bc_click", z.global_position, 0.0, 0.1, 3)
	z.move_and_slide()
	return true


# ============================================================
#  נזק: צלעות / ליבה / עמוד שדרה
# ============================================================
func on_damage(amount: int, hit_pos: Vector2, dir: Vector2, src: Dictionary) -> bool:
	if z.dead:
		return true
	var s := str(src.get("source", "bullet"))
	_mult = 1.0
	_core_last = false
	if state == CURL:
		_mult = CURL_MULT
		if _pop_t <= 0.0 and (s == "bullet" or s == "melee"):
			_pop_t = 0.8
			z._popup("CURLED", Color("e8dcc0"), 12, -60.0)
			Sfx.play("fl_chip", hit_pos, -4.0, 0.2, 3)
		_track(amount, src, hit_pos)
		return true
	if s == "fire":
		_mult = FIRE_MULT
		return true
	if not (s == "bullet" or s == "melee"):   # פיצוץ: שובר צלע מכל קצה
		if src.has("blast") or s in ["grenade", "barrel", "rocket", "launcher", "molotov", "hazard"]:
			for e in 2:
				var o := _outer(e)
				if o >= 0:
					_break_rib(e, o, hit_pos, -dir)
		_core_last = ribs_left(0) == 0 or ribs_left(1) == 0
		_track(amount, src, hit_pos)
		return true
	var lx: float = (hit_pos.x - z.global_position.x) * z._dir / (z.sc * z.wf)
	var ly: float = (hit_pos.y - z.global_position.y) / z.sc
	if ly < -40.0 and absf(lx) < HALF - 10.0:   # מלמעלה: עמוד השדרה
		spine_hits += 1
		_mult = SPINE_MULT
		_track(amount, src, hit_pos)
		return true
	var e := 0 if lx > 0.0 else 1
	if e == 0 and (state == REAR or state == SNAP):   # הצלעות פתוחות מקדימה - הליבה חשופה
		core_hits += 1
		_core_last = true
		_mult = CORE_MULT
		_track(amount, src, hit_pos)
		return true
	var o2 := _outer(e)
	if o2 < 0:   # הקצה פתוח: ישר לליבה
		core_hits += 1
		_core_last = true
		_mult = CORE_MULT
		_track(amount, src, hit_pos)
		return true
	var dmg := hit_damage(amount, hit_pos, src)
	rib_hits += 1
	_rib[e][o2] = int(_rib[e][o2]) - dmg
	Game.on_zombie_hit({"source": "bullet", "zone": "shield"})
	if Art.on_screen(z, hit_pos):
		Sfx.play("fl_chip", hit_pos, -3.0, 0.2, 4)
		var c = DebrisScript.new()
		_main().add_child(c)
		c.setup(hit_pos, Vector2(2, 2), Decor.BONE, Vector2(-dir.x * randf_range(60, 200), -randf_range(40, 180)))
	if int(_rib[e][o2]) <= 0:
		_break_rib(e, o2, hit_pos, -dir)
	_mult = LEAK
	_track(amount, src, hit_pos)
	return true


func _break_rib(e: int, i: int, at: Vector2, away: Vector2) -> void:
	if int(_rib[e][i]) <= -999:
		return
	_rib[e][i] = -999
	ribs_broken += 1
	Sfx.play("bc_crack", at, 2.0, 0.1, 3)
	if _pop_t <= 0.0:
		_pop_t = 0.4
		z._popup("RIB BROKEN" if ribs_left(e) > 0 else "CORE OPEN!", Color("ffd34a"), 13 if ribs_left(e) > 0 else 16, -66.0)
	var m := _main()
	if ribs_left(e) == 0 and not m.has_meta("bc_open_said"):
		m.set_meta("bc_open_said", true)
		var pl := player()
		if pl != null and pl.has_method("_say"):
			pl._say("The ribs are gone - SHOOT THE HEART", Color("b8ff9a"))
	if Art.on_screen(z, at):
		for k in Quality.scaled(5, 1.0):
			var c = DebrisScript.new()
			m.add_child(c)
			c.setup(at + Vector2(randf_range(-6, 6), randf_range(-14, 14)), Vector2(randf_range(3, 4), randf_range(6, 12)), Decor.BONE if k % 2 == 0 else Decor.BONE_D, Vector2(away.x * randf_range(60, 240), -randf_range(80, 260)))


# (למד) צרור נזק -> מתכרבל
func _track(amount: int, src: Dictionary, hit_pos: Vector2) -> void:
	if not learned or state == CURL or _curl_cd > 0.0:
		return
	var dmg := int(round(float(hit_damage(amount, hit_pos, src)) * _mult))
	var now: float = z._time
	_dmg_win.append([now, dmg])
	var sum := 0
	var i := 0
	while i < _dmg_win.size():
		if now - float(_dmg_win[i][0]) > CURL_WIN:
			_dmg_win.remove_at(i)
		else:
			sum += int(_dmg_win[i][1])
			i += 1
	if sum >= CURL_DMG and z.hp - dmg > 0:
		_dmg_win.clear()
		state = CURL
		_st = CURL_T
		curls += 1
		_resize(Vector2(60.0, 50.0))
		Sfx.play("bc_curl", z.global_position, 2.0, 0.1, 3)
		var m := _main()
		if not m.has_meta("bc_said"):
			m.set_meta("bc_said", true)
			z._popup("IT TURNS ITS BONES TO YOU NOW", Color("ff8a7a"), 13, -80.0)
			var pl := player()
			if pl != null and pl.has_method("_say"):
				pl._say("It curls up when I hurt it... get behind it", Color("ff8a7a"))


func damage_mult(_zone: String, _src: Dictionary) -> float:
	return _mult


func on_death() -> void:
	var m := _main()
	if (_core_last or core_hits > 0) and m != null:
		m.set_meta("bc_cores", int(m.get_meta("bc_cores", 0)) + 1)
	Sfx.play("bc_crack", z.global_position, 4.0, 0.05, 2, 0.7)
	Sfx.play("bc_hiss", z.global_position, 0.0, 0.05, 2, 0.6)
	if Art.on_screen(z, z.global_position):
		var c0: Vector2 = z.global_position + Vector2(0, -26.0 * z.sc)
		for k in Quality.scaled(10, 1.0):
			var dbr = DebrisScript.new()
			m.add_child(dbr)
			dbr.setup(c0 + Vector2(randf_range(-HALF, HALF) * z.sc, randf_range(-14, 10)), Vector2(randf_range(3, 4), randf_range(8, 16)), Decor.BONE if k % 2 == 0 else Decor.BONE_D, Vector2(randf_range(-240, 240), -randf_range(120, 360)))
		Particles.burst(m, c0, "hit", Vector2.UP, int(24.0 * Quality.gore()) + 4)
		Particles.burst(m, c0, "mist", Vector2.UP, 8)
		z._spray_blood(c0, Vector2(0, -1), 16, 380.0)


# ============================================================
#  ציור: כלוב צלעות של לווייתן עם עמוד שדרה, מתים מאוחים בפנים, ידיים ורגליים בולטות כרגליים, ראש מקדימה וראש מאחור,
#  ולב ECHO זוהר באמצע. REAR: הקדמה מתרוממת והצלעות נפתחות כמו לסתות. CURL: מתגלגל לכדור.
# ============================================================
func wants_redraw() -> bool:
	return true


func draw() -> bool:
	if _var.is_empty():
		return false
	if z.dead:   # גופה: הכלוב שוכב שטוח על הקרקע (zombie.gd מגלגל את הגופה ל-90 מעלות - טוב לעומד, לא לזוחל)
		var a: float = fposmod(z._angle, TAU)
		a = a - PI * 0.5 if a < PI else a - PI * 1.5
		var s := Vector2(z._dir * z.wf * z.sc, z.sc)
		DrawBatch.set_transform_matrix(z, Transform2D(a, Vector2(0.0, -20.0 * z.sc)) * Transform2D(0.0, s, 0.0, Vector2(0.0, 27.0 * z.sc)))
	else:
		begin_draw()
	var tt: float = z._time
	if _curl_k > 0.5 and not z.dead:
		_draw_ball(tt)
		end_draw()
		return true
	# מתרומם מקדימה (סביב הקצה האחורי)
	if _rear_k > 0.01 and not z.dead:
		var s := Vector2(z._dir * z.wf * z.sc, z.sc)
		var piv := Vector2(-HALF + 6.0, -6.0)
		var base := Transform2D(z.react_tilt(), Vector2(0.0, z.react_hop() * z.sc)) * Transform2D(0.0, s, 0.0, Vector2.ZERO)
		DrawBatch.set_transform_matrix(z, base * Transform2D(-0.32 * _rear_k, piv) * Transform2D(0.0, -piv))
	var skin := col(z.skin)
	var s2 := col(_var[0])
	var s3 := col(_var[1])
	var core := _core_pos()
	var open := _rear_k
	# רגליים רחוקות (מאחורי הכלוב)
	_legs(true, skin, s2, s3)
	# הצלעות הרחוקות (כהות)
	_ribs(true, open)
	# הגופות המאוחות בפנים
	_bodies_inside(skin, s2, s3, tt)
	# הליבה
	var exposed := ribs_left(0) == 0 or ribs_left(1) == 0 or open > 0.5
	var pulse := 0.55 + 0.45 * sin(tt * (5.0 if exposed else 2.6))
	if z.dead:   # לב שהתפוצץ: כהה, בלי זוהר
		Art.oval(z, core, 7.5, 5.5, Color("2e3020"), 0.0, Art.NONE)
		Art.oval(z, core + Vector2(1.0, 0.5), 4.0, 2.6, Color("5a1010"), 0.0, Art.NONE)
	else:
		Art.glow(z, core, 12.0 + 6.0 * pulse + (8.0 if exposed else 0.0), Color(Decor.SPORE, 0.3 + (0.25 if exposed else 0.0)))
		Art.oval(z, core, 7.0, 6.0, col(Decor.SPORE_D), 0.0, Art.NONE)
		Art.oval(z, core + Vector2(-0.5, -0.5), 4.6 * (0.85 + 0.15 * pulse), 4.0 * (0.85 + 0.15 * pulse), Color(Decor.SPORE, 0.95), 0.0, Art.NONE)
	for q in 4:   # עורקים
		var a := float(q) * 1.57 + 0.4
		DrawBatch.line(z, core + Vector2(cos(a), sin(a)) * 5.0, core + Vector2(cos(a) * 12.0, sin(a) * 9.0), Color(Decor.SPORE_D, 0.8), 1.0)
	# עמוד השדרה למעלה
	var sp := PackedVector2Array()
	for i in 9:
		var x := -HALF + float(i) * (HALF * 2.0 / 8.0)
		sp.append(Vector2(x, _spine_y(x)))
	DrawBatch.polyline(z, sp, col(Decor.BONE_D), 5.0)
	DrawBatch.polyline(z, sp, col(Decor.BONE), 3.0)
	for i in 8:
		var x2 := -HALF + 6.0 + float(i) * 12.5
		var c := Vector2(x2, _spine_y(x2))
		DrawBatch.colored_polygon(z, PackedVector2Array([c + Vector2(-2.5, -1.0), c + Vector2(-1.0, -6.0), c + Vector2(1.0, -6.0), c + Vector2(2.5, -1.0)]), col(Decor.BONE))
	# הצלעות הקרובות
	_ribs(false, open)
	# רגליים קרובות
	_legs(false, skin, s2, s3)
	# ראש מקדימה (מוביל) + ראש אחורי
	var hf := Vector2(HALF + 2.0, -24.0 + sin(tt * 2.0) * 0.8)
	z._head(hf, skin)
	face(hf)
	if not z.dead:
		var ec := Color(1.0, 0.28, 0.15)
		DrawBatch.circle(z, hf + Vector2(3.5, -0.5), 1.0, ec)
	if _var[3]:
		var hb := Vector2(-HALF - 2.0, -22.0)
		Art.oval_shaded(z, hb, 5.0, 4.6, s3, 0.0)
		Art.oval(z, hb + Vector2(-2.6, 1.5), 1.8, 1.2, col(Color("2a0a0c")), 0.0, Art.NONE)
		if not z.dead:
			DrawBatch.circle(z, hb + Vector2(-2.8, -1.0), 0.9, Color(1.0, 0.3, 0.15))
	# ריר ECHO
	var sl: float = _var[2]
	for q in 3:
		var dp := Vector2(-30.0 + float(q) * 28.0, -9.0)
		DrawBatch.line(z, dp, dp + Vector2(0.5, 3.0 + 4.0 * sl * (0.5 + 0.5 * sin(tt * 1.5 + float(q)))), Color(0.6, 0.85, 0.45, 0.55), 1.0)
	if not z.dead and state == REAR:
		DrawBatch.string(z, ThemeDB.fallback_font, hf + Vector2(-2, -14), "!", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(1.0, 0.35, 0.2, clampf(_st / REAR_T, 0.0, 1.0)))
	end_draw()
	return true


func _spine_y(x: float) -> float:
	var k := x / HALF
	return -44.0 + k * k * 8.0


func _core_pos() -> Vector2:
	return Vector2(2.0, -27.0)


# צלעות: לכל קצה RIBS צלעות שריון (שבורה = גדם), ושתיים קבועות באמצע. far = הצד הרחוק (כהה, מוסט)
func _ribs(far: bool, open: float) -> void:
	var bone := col(Decor.BONE if not far else Decor.BONE_S)
	var hi := col(Color(0.96, 0.93, 0.84) if not far else Decor.BONE_D)
	var off := Vector2(-3.0, -2.0) if far else Vector2.ZERO
	for e in 2:
		var sgn := 1.0 if e == 0 else -1.0
		for i in RIBS:
			var x: float = sgn * float(RIB_X[i])
			var top := Vector2(x, _spine_y(x) + 2.0) + off
			var hp: int = int(_rib[e][i])
			var spread := open * (1.0 if e == 0 else 0.0) * (1.0 - float(i) * 0.2)
			var bend := sgn * (6.0 + 8.0 * spread)
			var bottom := Vector2(x + sgn * 4.0 + sgn * 18.0 * spread, -10.0 - 10.0 * spread) + off
			if hp <= 0:   # גדם שבור
				var mid := top.lerp(bottom, 0.3) + Vector2(bend * 0.4, 0)
				DrawBatch.line(z, top, mid, bone, 3.0)
				DrawBatch.colored_polygon(z, PackedVector2Array([mid + Vector2(-1.5, 0), mid + Vector2(1.5, 0), mid + Vector2(0.3, 3.5)]), bone)
				continue
			var pts := PackedVector2Array()
			for q in 6:
				var k := float(q) / 5.0
				pts.append(top.lerp(bottom, k) + Vector2(bend * sin(k * PI), 0.0))
			DrawBatch.polyline(z, pts, col(Decor.BONE_S), 4.2)
			DrawBatch.polyline(z, pts, bone, 3.0)
			if not far:
				DrawBatch.line(z, pts[1] + Vector2(-0.6, 0), pts[3] + Vector2(-0.6, 0), hi, 0.8)
				if hp < RIB_HP:   # סדק
					var cp: Vector2 = pts[2]
					DrawBatch.line(z, cp + Vector2(-2, -1), cp + Vector2(2, 1.5), col(Decor.BONE_S), 0.8)
	for x2 in [-7.0, 7.0]:   # צלעות האמצע (מסגרת לליבה)
		var t2 := Vector2(x2, _spine_y(x2) + 2.0) + off
		var b2 := Vector2(x2 * 1.3, -11.0) + off
		var pts2 := PackedVector2Array()
		for q in 5:
			var k2 := float(q) / 4.0
			pts2.append(t2.lerp(b2, k2) + Vector2(signf(x2) * 5.0 * sin(k2 * PI), 0.0))
		DrawBatch.polyline(z, pts2, bone, 2.6)


# הגופות המאוחות: גוו אחד מקדימה, אחד מאחור, ואחד מכווץ באמצע מעל הליבה
func _bodies_inside(skin: Color, s2: Color, s3: Color, tt: float) -> void:
	var breathe := sin(tt * 2.2) * 0.8
	Art.oval(z, Vector2(28.0, -26.0), 15.0, 10.0 + breathe, s2, 0.1, Art.OUTLINE, 1.0)
	Art.oval(z, Vector2(-28.0, -25.0), 15.0, 10.0 - breathe, s3, -0.1, Art.OUTLINE, 1.0)
	Art.oval(z, Vector2(-2.0, -37.0), 12.0, 5.0, col(Art.shade(z.skin, -0.1)), 0.0, Art.OUTLINE, 1.0)
	# קרעים, תפרים ודם
	Art.oval(z, Vector2(22.0, -24.0), 3.0, 2.0, Color(0.45, 0.05, 0.05, 0.85), 0.3, Art.NONE)
	Art.oval(z, Vector2(-20.0, -30.0), 2.4, 1.6, Color(0.45, 0.05, 0.05, 0.8), 0.0, Art.NONE)
	for q in 3:
		var p := Vector2(-36.0 + float(q) * 5.0, -21.0)
		DrawBatch.line(z, p, p + Vector2(1.0, 2.0), col(Color("2a2020")), 0.7)
	# יד שנאחזת בצלע מבפנים
	DrawBatch.line(z, Vector2(12.0, -32.0), Vector2(17.0, -38.0), skin, 2.0)
	DrawBatch.circle(z, Vector2(17.0, -38.5), 1.6, skin)


# רגליים: ידיים ורגליים של המתים, מחליפות זו את זו כמו נדל
func _legs(far: bool, skin: Color, s2: Color, s3: Color) -> void:
	var ph: float = z._walk_phase
	var n := 6
	for i in n:
		if (i % 2 == 0) != far:
			continue
		var x := -40.0 + float(i) * 16.0
		var w := ph + float(i) * 1.1
		var root := Vector2(x, -14.0)
		var lift := maxf(0.0, sin(w)) * 4.0
		var foot := Vector2(x + cos(w) * 6.0 + (4.0 if i < 3 else -2.0), -lift)
		if _rear_k > 0.1 and i >= 4:   # רגליים קדמיות באוויר
			foot = Vector2(x + 8.0, -14.0 - 6.0 * _rear_k)
		if z.dead:   # גופה: הרגליים רפויות, מקופלות מתחת לכלוב
			foot = Vector2(x + (7.0 if i % 2 == 0 else -6.0), -6.0 - float(i % 3) * 2.0)
		var knee := root.lerp(foot, 0.5) + Vector2(0.0, -5.0 if i % 3 != 0 else -3.0)
		var c: Color = s2 if i < 3 else s3
		if far:
			c = Art.shade(c, -0.25)
		var arm := i % 3 == 1   # חלק ידיים (עם אצבעות) וחלק רגליים (עם נעל)
		Art.limb(z, PackedVector2Array([root, knee, foot]), 3.0 if arm else 3.6, col(c))
		if arm:
			for q in 3:
				DrawBatch.line(z, foot, foot + Vector2(-1.5 + float(q) * 1.6, 2.0), col(Art.shade(skin, -0.1)), 0.8)
		else:
			DrawBatch.colored_polygon(z, PackedVector2Array([foot + Vector2(-2.5, -2.5), foot + Vector2(3.5, -2.0), foot + Vector2(4.0, 0.5), foot + Vector2(-2.5, 0.5)]), col(z.shoe))


func _draw_ball(tt: float) -> void:
	var c := Vector2(0.0, -25.0)
	var r := 24.0
	Art.glow(z, c, 14.0, Color(Decor.SPORE, 0.18 + 0.1 * sin(tt * 6.0)))
	Art.oval(z, c, r - 2.0, r - 3.0, col(_var[0]), 0.0, Art.OUTLINE, 1.0)
	for i in 8:   # צלעות סביב (מתגלגלות)
		var a := _roll + float(i) * TAU / 8.0
		var p0 := c + Vector2(cos(a), sin(a)) * (r - 6.0)
		var p1 := c + Vector2(cos(a + 0.5), sin(a + 0.5)) * (r + 1.0)
		var p2 := c + Vector2(cos(a + 0.9), sin(a + 0.9)) * (r - 4.0)
		DrawBatch.polyline(z, PackedVector2Array([p0, p1, p2]), col(Decor.BONE_S), 4.2)
		DrawBatch.polyline(z, PackedVector2Array([p0, p1, p2]), col(Decor.BONE), 3.0)
	DrawBatch.arc(z, c, r + 1.5, _roll, _roll + PI * 1.3, 14, col(Decor.BONE_D), 3.0)
	if not z.dead:
		DrawBatch.circle(z, c + Vector2(cos(_roll * 0.5) * 6.0, sin(_roll * 0.5) * 4.0), 1.2, Color(1.0, 0.3, 0.15))
