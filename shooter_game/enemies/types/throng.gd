extends "res://enemies/zombie_type.gd"
# ============================================================
#  THRONG (שלב 61, "END OF THE WORLD") - ההמון של אושואיה: תושבים, דייגים, פועלי נמל, תיירים מהספינה - במעילי פוך
#    צבעוניים, כובעי גרב, מגפיים. כל אחד לבד הוא זומבי חלש (קליע-שניים). אבל הם לא לבד: הם "להקה" (School) - גוף אחד
#    של הרבה גופים, כמו להקת דגים. חוט ECHO זוהר מחבר עורף לעורף, העיניים פועמות יחד, והם צועדים באותו צעד בדיוק
#    (BEAT - אותו קצב לכל ההמונים בשלב: כל האזור צועד אל העיר בצעד אחד).
#  מה הם למדו, וממה: גוף אחד אפשר לירות. אלפי מתים שנורו לבד לימדו את הכוורת שהבודד מת - אז היא הפסיקה להזיז בודדים.
#    היא מזיזה גוף אחד שעשוי מהרבה. "THEY MOVE AS ONE NOW".
#  איך זה עובד (School - משותף לכל חברי הלהקה, הראשון שחי מעדכן אותו פעם בפריים):
#    MARCH   - העוגן (ax) של הלהקה מתקדם אליך בצעדים (MARCH_V, פועם עם BEAT). כל חבר רץ למקום שלו במבנה (GAP).
#              כשאתה למעלה (קומה) - כולם קופצים יחד על הקצב.
#    SURGE   - הראשון בטווח (SURGE_R) -> על הקצב הבא כל הלהקה מזנקת קדימה יחד עם ידיים מושטות (SURGE_V, SURGE_T).
#              נשיכה אחת ללהקה בכל BITE_CD (לא 8 נשיכות בבת אחת - הוגן).
#    FLINCH  - חבר נפגע: כל הלהקה נרתעת יחד צעד אחורה (כמו דגים).
#    SCATTER - פיצוץ, או SCATTER_DEATHS מתים בתוך SCATTER_WIN: הלהקה מתפזרת לכל הכיוונים בקפיצות (SCATTER_T),
#              ואז REGROUP - חוזרים למבנה. זה החלון לקצור אותם.
#  לומד (main meta "thr_broken" >= LEARN - כמה להקות פיזרת / חיסלת): "THEY FLANK NOW" - כשהלהקה מגיעה אליך (SPLIT_R) היא
#    מתפצלת כמו להקת דגים סביב טורף: החצי האחורי קופץ מעליך בקשת אחת מסונכרנת ונוחת מאחוריך (להקה חדשה), ושני החצאים
#    סוגרים עליך. נגד: לירות באוויר בזמן הקפיצה (הם תלויים באוויר יחד), רימון באמצע, או לסגת לפני שהם מגיעים.
#  השלב שם להקות (stage_61.gd SCHOOLS, spawn_school); זומבי בודד שנולד מהפיזור הרגיל מצטרף ללהקה קרובה (JOIN_R) או פותח אחת.
#  לשנות: GAP, MARCH_V, BEAT, SURGE_R, SURGE_V, SURGE_T, BITE_CD, SCATTER_T, REGROUP_T, SCATTER_DEATHS, SCATTER_WIN,
#    LEARN, SPLIT_R, SPLIT_T, MAX_SCHOOL, JOIN_R.
# ============================================================

const Registry := preload("res://enemies/zombie_registry.gd")

const SOUNDS := {
	"thr_step": [["N", 0, 0, 0.0, 0.12, 0.0, 30.0, 0.65, 0.12, 0], ["S", 85, 50, 0.0, 0.12, 0.0, 28.0, 0.55, 1.0, 0], ["N", 0, 0, 0.015, 0.1, 0.0, 34.0, 0.3, 0.3, 0, 0.2]],
	"thr_hum": {"rev": 0.4, "drive": 2.2, "layers": [["V", 110, 104, 0.0, 0.9, 0.08, 2.4, 0.5, 1.0, 0.03, 0, [480, 900, 18]], ["V", 165, 156, 0.0, 0.9, 0.08, 2.4, 0.4, 1.0, 0.03, 0, [560, 1000, 18]], ["V", 220, 208, 0.02, 0.85, 0.08, 2.4, 0.3, 1.0, 0.03, 0, [700, 1300, 22]]]},
	"thr_scatter": {"rev": 0.25, "drive": 2.4, "layers": [["V", 260, 420, 0.0, 0.5, 0.01, 4.0, 0.6, 1.0, 0.12, 0, [900, 1800, 50]], ["V", 300, 520, 0.03, 0.45, 0.01, 4.0, 0.45, 1.0, 0.14, 0, [1000, 2000, 55]], ["N", 0, 0, 0.0, 0.4, 0.0, 6.0, 0.4, 0.6, 0, 0.3]]},
	"thr_leap": [["N", 0, 0, 0.0, 0.45, 0.06, 4.0, 0.55, 0.3, 0, 0.25], ["S", 180, 320, 0.0, 0.4, 0.05, 5.0, 0.2, 1.0, 0]],
}

const GAP := 26.0
const MARCH_V := 84.0
const BEAT := 0.5
const SURGE_R := 150.0
const SURGE_V := 270.0
const SURGE_T := 0.42
const BITE_CD := 0.9
const SCATTER_T := 1.25
const REGROUP_T := 1.1
const SCATTER_DEATHS := 3
const SCATTER_WIN := 1.4
const LEARN := 2
const SPLIT_R := 250.0
const SPLIT_T := 0.72            # זמן התעופה בקפיצה מעליך
const MAX_SCHOOL := 12
const JOIN_R := 420.0
const MAXV := 175.0              # כמה מהר חבר רץ למקום שלו במבנה

enum {MARCH, SURGE, RECOIL, SCATTER, REGROUP, HOLD}

# לבדיקות (סטטי ללהקה - ראה School)
var bites := 0
var leaps := 0

var school: School = null
var slot := 0
var _first := true
var _airborne_leap := false
var _scatter_v := Vector2.ZERO
var _jump_cd := 0.0
var _var := []                   # [מעיל, כובע, פונפון, מכנס, סוג כובע, שיער לבן]


# ============================================================
#  הלהקה: מצב משותף לכל החברים. מתעדכנת פעם בפריים פיזיקה (ע"י החבר הראשון שחי)
# ============================================================
class School extends RefCounted:
	var members: Array = []
	var ax := 0.0
	var y := 630.0
	var dir := -1.0
	var state := 0
	var t := 0.0
	var frame := -1
	var flinch := 0.0
	var bite_cd := 0.0
	var deaths: Array = []
	var split_done := false
	var engaged := false
	var scatter_from := Vector2.ZERO
	var broken := false              # נספר כבר ב-"thr_broken"
	var main: Node = null
	var surge_k := 0.0
	var hold_t := 0.0
	# לבדיקות
	var surges := 0
	var scatters := 0
	var splits := 0
	var regroups := 0

	func alive() -> Array:
		var out := []
		for m in members:
			if is_instance_valid(m) and not m.dead:
				out.append(m)
		return out

	func size() -> int:
		return alive().size()

	# מקום במבנה (x) לחבר מספר k מתוך n, ממוין לפי x
	func slot_x(k: int, n: int) -> float:
		return ax + (float(k) - float(n - 1) * 0.5) * GAP


func stats() -> Dictionary:
	return {"name": "THRONG", "hp": 18, "walk": 50.0, "chase": 90.0, "damage": 1, "bite_delay": 0.9, "scale": 1.0, "width": 1.0,
		"duck": 0.0, "cover": 0.0, "skin": Color("8e9a92"), "shirt": Color("a83a2c"), "pants": Color("2e3444"), "shoe": Color("2a2420"),
		"points": 90}


func brain_overrides() -> Dictionary:
	return {"aggression": 0.9}


func use_brain_movement() -> bool:
	return false


func can_bite() -> bool:
	return false


func _main() -> Node:
	return z.get_parent()


static func is_learned(m: Node) -> bool:
	return m != null and int(m.get_meta("thr_broken", 0)) >= LEARN


func setup() -> void:
	var r := RandomNumberGenerator.new()
	r.seed = z.get_instance_id() * 7 + 3
	var coats := [Color("b0342a"), Color("d8702a"), Color("2c3a5a"), Color("3a5a3e"), Color("c09a30"), Color("6a2a4a"), Color("3a6a8a"), Color("8a8a84")]
	var hats := [Color("2a2a30"), Color("b0302a"), Color("e0d8c8"), Color("2c4a7a"), Color("c8a030")]
	var pants := [Color("2e3444"), Color("3a3a40"), Color("2a3a5a"), Color("4a4236")]
	_var = [coats[r.randi() % coats.size()], hats[r.randi() % hats.size()], hats[r.randi() % hats.size()], pants[r.randi() % pants.size()], r.randi() % 3, r.randf() < 0.25]
	z.shirt = _var[0]
	var rs := z._shape.shape as RectangleShape2D
	rs.size = Vector2(26.0 * z.wf * z.sc, 58.0 * z.sc)
	z._shape.position = Vector2(0.0, -29.0 * z.sc)
	z.set_meta("no_cover", true)


# להקה חדשה של n חברים סביב x (השלב קורא לזה). מחזיר את הלהקה
static func spawn_school(stage: Node, x: float, n: int, y := -1.0, face := -1.0) -> School:
	var s := School.new()
	s.main = stage.main
	s.ax = x
	s.dir = face
	s.y = stage.floor_y if y < 0.0 else y
	for i in n:
		var zx := s.slot_x(i, n)
		var zz = stage.spawn(Registry.THRONG, zx, y)
		if zz == null or zz.type_mod == null:
			continue
		zz.dormant = false
		zz._dir = face
		zz.type_mod._join(s)
	_register(stage.main, s)
	return s


static func _register(m: Node, s: School) -> void:
	if m == null:
		return
	var list: Array = m.get_meta("thr_schools", [])
	list.append(s)
	m.set_meta("thr_schools", list)


func _join(s: School) -> void:
	school = s
	if not s.members.has(z):
		s.members.append(z)


# זומבי בודד (פיזור רגיל / נפל מקונדור): מצטרף ללהקה קרובה, או פותח אחת חדשה
func _find_school() -> void:
	var m := _main()
	var best: School = null
	var bd := JOIN_R
	for s in m.get_meta("thr_schools", []):
		var sc0: School = s
		var n := sc0.size()
		if n <= 0 or n >= MAX_SCHOOL or sc0.state == SCATTER:
			continue
		var d := absf(sc0.ax - z.global_position.x)
		if d < bd:
			bd = d
			best = sc0
	if best == null:
		best = School.new()
		best.main = m
		best.ax = z.global_position.x
		best.y = z.global_position.y
		best.dir = z._dir
		_register(m, best)
	_join(best)


# ============================================================
#  תנועה
# ============================================================
func physics(pl: Node, delta: float) -> bool:
	if z.dead:
		return false
	if _first:
		_first = false
		if school == null:
			_find_school()
	var s := school
	var fr := Engine.get_physics_frames()
	if s.frame != fr:
		s.frame = fr
		_tick_school(s, pl, delta)
	_jump_cd -= delta
	var has: bool = pl != null and not pl.dead
	if not z.is_on_floor():
		z.velocity.y += z.gravity * delta
	var gx: float = z.global_position.x
	match s.state:
		SCATTER:
			if z.is_on_floor() and _scatter_v != Vector2.ZERO:
				z.velocity.x = _scatter_v.x
				z.velocity.y = _scatter_v.y
				_scatter_v = Vector2.ZERO
			elif z.is_on_floor():
				z.velocity.x = move_toward(z.velocity.x, 0.0, 500.0 * delta)
			z._walk_phase += delta * 14.0
		_:
			if _airborne_leap:
				if z.is_on_floor() and z.velocity.y >= 0.0:
					_airborne_leap = false
					_land_dust()
			else:
				var al: Array = s.alive()
				var k := al.find(z)
				var tx := s.slot_x(maxi(k, 0), al.size())
				var want := clampf((tx - gx) * 6.0, -MAXV, MAXV)
				if s.state == SURGE:
					want = clampf((tx - gx) * 8.0, -SURGE_V * 1.3, SURGE_V * 1.3)
				var acc := 900.0 if z.is_on_floor() else 300.0
				z.velocity.x = move_toward(z.velocity.x, want, acc * delta)
				# נתקע במכשול: קופץ (כולם קופצים על אותו קצב)
				if z.is_on_floor() and z.is_on_wall() and absf(tx - gx) > 20.0 and _jump_cd <= 0.0:
					z.velocity.y = -560.0
					_jump_cd = 0.6
				# אתה על קומה מעליהם: קפיצה משותפת על הקצב
				if has and z.is_on_floor() and _on_beat() and _jump_cd <= 0.0 and absf(pl.global_position.x - gx) < 140.0 \
						and pl.global_position.y < z.global_position.y - 90.0 and pl.is_on_floor():
					z.velocity.y = -720.0
					_jump_cd = 1.2
			if s.state != HOLD:
				z._walk_phase = beat_t() * PI / BEAT
			if absf(z.velocity.x) > 12.0 and not _airborne_leap:
				z._dir = s.dir if s.state != REGROUP else signf(z.velocity.x)
			elif has and absf(pl.global_position.x - gx) > 8.0:
				z._dir = signf(pl.global_position.x - gx)
	# נשיכה: אחת ללהקה בכל BITE_CD
	if has and s.bite_cd <= 0.0 and s.state != SCATTER and absf(pl.global_position.x - gx) < 22.0 and absf(pl.global_position.y - z.global_position.y) < 50.0:
		s.bite_cd = BITE_CD
		bites += 1
		z._bite_anim = 0.25
		pl.hurt(z.damage + (1 if s.state == SURGE and s.size() >= 6 else 0), Vector2(z._dir * 1.2, 0.0))
	z.move_and_slide()
	if gx < 20.0 or gx > z.world_w - 20.0:
		z.global_position.x = clampf(gx, 20.0, z.world_w - 20.0)
	return true


# הקצב המשותף של כל ההמונים בשלב (אותו צעד לכולם): פאזה גלובלית
static func beat_t() -> float:
	return float(Engine.get_physics_frames()) / 60.0


func _on_beat() -> bool:
	var fr := Engine.get_physics_frames()
	var per := int(round(BEAT * 60.0))
	return fr % per == 0


func _land_dust() -> void:
	if Art.on_screen(z, z.global_position):
		Particles.burst(_main(), z.global_position + Vector2(0, -3), "smoke", Vector2.UP, 2)


# ---- מצב הלהקה (פעם בפריים) ----
func _tick_school(s: School, pl: Node, delta: float) -> void:
	s.t += delta
	s.flinch = maxf(0.0, s.flinch - delta)
	s.bite_cd -= delta
	var al: Array = s.alive()
	if al.is_empty():
		return
	if Engine.get_physics_frames() % 6 == 0:   # ממוינים לפי x (המבנה לא מתהפך)
		al.sort_custom(func(a, b): return a.global_position.x < b.global_position.x)
		s.members = al
	var has: bool = pl != null and not pl.dead
	var px: float = pl.global_position.x if has else s.ax
	var dx := px - s.ax
	var half := float(al.size() - 1) * 0.5 * GAP
	if not s.engaged:
		if has and absf(dx) < 900.0 and absf(pl.global_position.y - s.y) < 400.0:
			s.engaged = true
			if Art.on_screen(al[0], al[0].global_position, 0.0):
				Sfx.play("thr_hum", al[0].global_position, -2.0, 0.05, 1)
		else:
			return
	# כל הלהקות על המסך צועדות על אותו קצב: צליל צעד אחד לכולן
	if _on_beat() and s.state in [MARCH, SURGE] and Art.on_screen(al[0], al[0].global_position, 40.0):
		var mm := _main()
		if int(mm.get_meta("thr_beat_fr", -1)) != Engine.get_physics_frames():
			mm.set_meta("thr_beat_fr", Engine.get_physics_frames())
			Sfx.play("thr_step", al[0].global_position, -6.0 + minf(float(al.size()), 10.0) * 0.5, 0.03, 2)
	match s.state:
		MARCH:
			if absf(dx) > 6.0:
				s.dir = signf(dx)
			var step := 0.35 + 1.3 * maxf(0.0, sin(beat_t() * TAU / BEAT))   # צעד-צעד
			var front_gap := absf(dx) - half
			var v := MARCH_V * step
			if front_gap < 30.0:
				v = 0.0
			s.ax += s.dir * v * delta
			if s.flinch > 0.0:
				s.ax -= s.dir * 60.0 * delta
			# פיצול (למד): החצי האחורי קופץ מעליך
			if has and is_learned(s.main) and not s.split_done and al.size() >= 4 and front_gap < SPLIT_R and front_gap > 40.0 \
					and absf(pl.global_position.y - s.y) < 60.0 and _on_beat():
				_split(s, al, pl)
			elif has and front_gap < SURGE_R and absf(pl.global_position.y - s.y) < 90.0 and _on_beat():
				s.state = SURGE
				s.t = 0.0
				s.surges += 1
				s.surge_k = 1.0
				Sfx.play("thr_hum", al[0].global_position, 0.0, 0.08, 2, 1.15)
		SURGE:
			s.ax += s.dir * SURGE_V * delta
			if s.t >= SURGE_T:
				s.state = RECOIL
				s.t = 0.0
		RECOIL:
			s.ax -= s.dir * 70.0 * delta
			s.surge_k = maxf(0.0, s.surge_k - delta * 3.0)
			if s.t >= 0.35:
				s.state = MARCH
				s.t = 0.0
		HOLD:
			s.hold_t -= delta
			if s.hold_t <= 0.0:
				s.state = MARCH
		SCATTER:
			if s.t >= SCATTER_T:
				s.state = REGROUP
				s.t = 0.0
				s.regroups += 1
				var cx := 0.0
				for m in al:
					cx += m.global_position.x
				s.ax = cx / float(al.size())
		REGROUP:
			var ok := true
			for i in al.size():
				if absf(al[i].global_position.x - s.slot_x(i, al.size())) > 24.0:
					ok = false
					break
			if ok or s.t > REGROUP_T * 2.0:
				s.state = MARCH
				s.t = 0.0
	if s.state != SURGE and s.state != RECOIL:
		s.surge_k = maxf(0.0, s.surge_k - delta * 3.0)
	s.ax = clampf(s.ax, 40.0 + half, al[0].world_w - 40.0 - half)


# ---- פיצול (THEY FLANK NOW): החצי האחורי קופץ מעליך בקשת אחת ונוחת מאחוריך כלהקה חדשה ----
func _split(s: School, al: Array, pl: Node) -> void:
	s.split_done = true
	s.splits += 1
	var px: float = pl.global_position.x
	var behind := s.dir   # הצד שמאחוריך (מנקודת המבט של הלהקה: מעבר לך)
	# האחוריים = הרחוקים ממך
	var by_d := al.duplicate()
	by_d.sort_custom(func(a, b): return absf(a.global_position.x - px) > absf(b.global_position.x - px))
	var n := al.size() / 2
	var ns := School.new()
	ns.main = s.main
	ns.dir = -behind
	ns.y = s.y
	ns.ax = px + behind * (70.0 + float(n - 1) * 0.5 * GAP)
	ns.split_done = true
	ns.engaged = true
	ns.state = HOLD
	ns.hold_t = SPLIT_T + 0.25
	_register(s.main, ns)
	for i in n:
		var m = by_d[i]
		s.members.erase(m)
		var tm = m.type_mod
		tm.school = ns
		ns.members.append(m)
		var tx: float = ns.ax + (float(i) - float(n - 1) * 0.5) * GAP
		var g: float = m.gravity
		m.velocity = Vector2((tx - m.global_position.x) / SPLIT_T, -g * SPLIT_T * 0.5)
		tm._airborne_leap = true
		tm.leaps += 1
		m._dir = behind
	s.state = HOLD
	s.hold_t = SPLIT_T + 0.15
	Sfx.play("thr_leap", pl.global_position, 2.0, 0.05, 2)
	var mm: Node = s.main
	if mm != null and not mm.has_meta("thr_flank_said"):
		mm.set_meta("thr_flank_said", true)
		z._popup("THEY FLANK NOW", Color("ff8a7a"), 15, -100.0)
		if pl.has_method("_say"):
			pl._say("They split around me... like a school of fish!", Color("ff8a7a"))


# הלהקה מתפזרת (פיצוץ / הרבה מתים מהר)
func _scatter(s: School, from: Vector2) -> void:
	if s.state == SCATTER:
		return
	s.state = SCATTER
	s.t = 0.0
	s.scatters += 1
	s.scatter_from = from
	var al: Array = s.alive()
	for m in al:
		var sd := signf(m.global_position.x - from.x)
		if sd == 0.0:
			sd = 1.0 if randf() < 0.5 else -1.0
		m.type_mod._scatter_v = Vector2(sd * randf_range(170.0, 300.0), -randf_range(240.0, 420.0))
		m.type_mod._airborne_leap = false
	if not al.is_empty():
		Sfx.play("thr_scatter", al[0].global_position, 0.0, 0.1, 2)
		if int(s.main.get_meta("thr_scatter_pop", 0)) < 2:
			s.main.set_meta("thr_scatter_pop", int(s.main.get_meta("thr_scatter_pop", 0)) + 1)
			z._popup("SCATTERED!", Color("ffd34a"), 15, -90.0)
	_count_broken(s)


# להקה שפוזרה / חוסלה: הספירה ל-"THEY FLANK NOW"
func _count_broken(s: School) -> void:
	if s.broken or s.main == null:
		return
	s.broken = true
	s.main.set_meta("thr_broken", int(s.main.get_meta("thr_broken", 0)) + 1)


func on_damage(_amount: int, hit_pos: Vector2, _dir: Vector2, src: Dictionary) -> bool:
	if z.dead or school == null:
		return true
	var s := str(src.get("source", "bullet"))
	if src.has("blast") or s == "grenade" or s == "rocket" or s == "explosion":
		_scatter(school, hit_pos)
	elif s == "bullet" or s == "melee":
		school.flinch = 0.22
	return true


func on_death() -> void:
	if school == null:
		return
	var s := school
	var ms := Time.get_ticks_msec()
	s.deaths.append(ms)
	while not s.deaths.is_empty() and ms - int(s.deaths[0]) > int(SCATTER_WIN * 1000.0):
		s.deaths.pop_front()
	var left := s.size()
	if left <= 0:
		_count_broken(s)
	elif s.deaths.size() >= SCATTER_DEATHS and left >= 2 and s.state != SCATTER:
		_scatter(s, z.global_position)


func wants_redraw() -> bool:
	return true


# ============================================================
#  ציור: אזרח של אושואיה במעיל פוך צבעוני, כובע גרב (או ברדס), צעיף, מכנסיים כהים, מגפיים. כולם באותה תנוחה בדיוק
#  (אותו צעד, אותה הטיה) - וזה מה שמפחיד. עיניים ירוקות פועמות יחד, וחוט ECHO זוהר מהעורף לעורף של השכן.
# ============================================================
func draw() -> bool:
	if _var.is_empty():
		return false
	begin_draw()
	var s := school
	var surge := s.surge_k if s != null else 0.0
	var flinch := (s.flinch / 0.22) if s != null else 0.0
	var scat: bool = s != null and s.state == SCATTER and not z.dead
	var tt: float = z._time
	var skin := col(z.skin)
	var coat := col(_var[0])
	var coat_d := col(Art.shade(_var[0], -0.25))
	var pa := col(_var[3])
	var lean := surge * 6.0 - flinch * 4.0
	var ph: float = z._walk_phase
	var bob := absf(sin(ph)) * 1.2
	if _airborne_leap or not z.is_on_floor():
		bob = 0.0
	var hip := Vector2(0.0, -21.0 + bob * 0.4)
	var sh := Vector2(1.5 + lean, -39.0 + bob * 0.5)
	var head := sh + Vector2(2.0 + lean * 0.3, -9.5)
	# רגליים: צעד מסונכרן (או מקופלות באוויר)
	var f0 := Vector2(sin(ph) * 5.0 + 1.0, -maxf(0.0, cos(ph)) * 2.5)
	var f1 := Vector2(sin(ph + PI) * 5.0 - 1.0, -maxf(0.0, cos(ph + PI)) * 2.5)
	if not z.is_on_floor() and not z.dead:
		f0 = Vector2(6.0, -9.0)
		f1 = Vector2(-5.0, -6.0)
	z._leg(hip + Vector2(-2.0, 0), f1, col(Art.shade(_var[3], -0.15)), skin, col(z.shoe))
	# יד אחורית
	var reach := surge
	var hb := sh + Vector2(lerpf(-3.0, 14.0, reach), lerpf(17.0, 2.0, reach) + sin(ph) * 1.2)
	if scat:
		hb = sh + Vector2(-6.0, -12.0 + sin(tt * 18.0) * 3.0)
	z._arm(sh + Vector2(-3.0, 2.0), hb, skin, coat_d)
	z._leg(hip + Vector2(2.0, 0), f0, pa, skin, col(z.shoe))
	# מעיל פוך: גוף מרופד עם תפרים אופקיים
	var body := PackedVector2Array([sh + Vector2(-8.0, -1.5), sh + Vector2(8.5, -1.0), hip + Vector2(9.0, 3.0), hip + Vector2(-8.5, 3.5)])
	Art.fill_shaded(z, body, coat, 0.16, 0.3)
	if not z.crowded():
		for q in 4:
			var yy := sh.y + 4.0 + float(q) * 4.6
			DrawBatch.line(z, Vector2(sh.x - 7.0, yy), Vector2(sh.x + 7.5, yy + 0.6), coat_d, 0.9)
	DrawBatch.line(z, sh + Vector2(2.5, 0.0), hip + Vector2(3.0, 2.0), Color(0.1, 0.1, 0.1, 0.45), 1.0)   # רוכסן
	# קרע עם דם (ECHO בפנים)
	Art.oval(z, sh + Vector2(-2.0, 9.0), 2.4, 3.0, Color(0.45, 0.05, 0.05, 0.75), 0.2, Art.NONE)
	# צעיף
	DrawBatch.line(z, sh + Vector2(-5.0, -1.0), sh + Vector2(6.0, -1.5), col(_var[2]), 2.6)
	# ראש + כובע
	z._head(head, skin)
	face(head, Vector2(INF, INF))
	var hat := col(_var[1])
	match int(_var[4]):
		0:   # כובע גרב עם פונפון
			DrawBatch.colored_polygon(z, PackedVector2Array([head + Vector2(-7.0, -1.0), head + Vector2(6.0, -2.0), head + Vector2(4.5, -7.0), head + Vector2(-1.0, -9.5), head + Vector2(-6.0, -6.5)]), hat)
			DrawBatch.line(z, head + Vector2(-7.0, -1.4), head + Vector2(6.0, -2.4), col(Art.shade(_var[1], 0.2)), 2.0)
			DrawBatch.circle(z, head + Vector2(-2.0, -10.5), 2.4, col(_var[2]))
		1:   # ברדס של הפרקה (פרווה)
			DrawBatch.colored_polygon(z, PackedVector2Array([head + Vector2(-9.0, 4.0), head + Vector2(-9.0, -5.0), head + Vector2(-3.0, -10.0), head + Vector2(4.0, -9.0), head + Vector2(6.0, -6.0), head + Vector2(1.0, -6.0), head + Vector2(-4.0, -2.0), head + Vector2(-5.0, 5.0)]), coat_d)
			DrawBatch.polyline(z, PackedVector2Array([head + Vector2(6.0, -6.0), head + Vector2(3.0, -9.5), head + Vector2(-3.0, -10.5)]), col(Color("d8d0c0")), 1.8)
		_:   # כובע דייגים
			DrawBatch.colored_polygon(z, PackedVector2Array([head + Vector2(-8.0, -2.0), head + Vector2(8.0, -2.5), head + Vector2(5.0, -6.5), head + Vector2(-5.0, -6.5)]), hat)
			DrawBatch.line(z, head + Vector2(-9.0, -2.0), head + Vector2(9.0, -2.4), col(Art.shade(_var[1], -0.2)), 1.4)
	if _var[5]:   # שיער לבן מבצבץ
		DrawBatch.line(z, head + Vector2(-6.5, 0.0), head + Vector2(-7.5, 3.5), col(Color("d8d4cc")), 1.4)
	# עיניים ירוקות שפועמות יחד (אותו קצב לכל הלהקה)
	if not z.dead:
		var pulse := 0.55 + 0.45 * sin(beat_t() * TAU / BEAT)
		var ec := Color(0.55, 1.0, 0.5)
		if z.has_meta("s57_learned_t"):
			ec = ec.lerp(Color(1.0, 1.0, 0.8), clampf(1.0 - float(Time.get_ticks_msec() - int(z.get_meta("s57_learned_t"))) / 600.0, 0.0, 1.0))
		DrawBatch.circle(z, head + Vector2(3.6, -0.6), 1.0, ec)
		Art.glow(z, head + Vector2(3.6, -0.6), 3.0 + 2.0 * pulse, Color(ec, 0.35 * pulse + 0.1))
	# יד קדמית: מושטת קדימה (בזינוק - שתי הידיים)
	var hf := sh + Vector2(lerpf(4.0, 17.0, reach), lerpf(16.0, 0.0, reach) + sin(ph + PI) * 1.2)
	if scat:
		hf = sh + Vector2(8.0, -11.0 + cos(tt * 17.0) * 3.0)
	z._arm(sh + Vector2(3.0, 2.0), hf, skin, coat)
	end_draw()
	# חוט ECHO: מהעורף שלי לעורף של השכן (במבנה). בלי טרנספורם (מצויר אחרי end_draw)
	if not z.dead and s != null and s.state != SCATTER and not z.crowded():
		var al: Array = s.members
		var k := al.find(z)
		if k >= 0 and k + 1 < al.size():
			var nb = al[k + 1]
			if is_instance_valid(nb) and not nb.dead:
				var rel: Vector2 = nb.global_position - z.global_position
				if rel.length() < 90.0:
					var a := Vector2(-z._dir * 1.5 * z.sc, -45.0 * z.sc)
					var b := rel + Vector2(-nb._dir * 1.5 * nb.sc, -45.0 * nb.sc)
					var mid := (a + b) * 0.5 + Vector2(0, 5.0 + 2.0 * sin(z._time * 3.0))
					var pulse2 := 0.5 + 0.5 * sin(beat_t() * TAU / BEAT)
					DrawBatch.polyline(z, PackedVector2Array([a, mid, b]), Color(0.6, 1.0, 0.5, 0.18 + 0.2 * pulse2), 1.1)
	return true
