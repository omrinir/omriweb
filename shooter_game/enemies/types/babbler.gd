extends "res://enemies/zombie_type.gd"
# ============================================================
#  BABBLER (שלב 53, "CAPITAL SIEGE") - שדרן רדיו מת (Pontypool Changes Everything / Cell של סטיבן קינג): חולצה לבנה
#    מלוכלכת, עניבה אדומה רפויה, כתפיות, אוזניות סביב הצוואר, והוא מחזיק מגפון סדוק עם סלוטייפ.
#    הוא חוזר על מילה אחת (WORDS - כל אחד מילה משלו) בבועה משוננת מעל הראש.
#  כל CD שניות: שואף אוויר (INHALE_T - הבועה גדלה, המילה רועדת ונהיית אדומה) ואז צועק: טבעת של המילה (WordRing)
#    מתפשטת ממנו החוצה (RING_V, עד RING_R).
#  הטבעת פוגעת אם היא מגיעה אליך כשאתה לא מאחורי מחסה (קרן מהמגפון אליך נחסמת = בטוח) ולא באמצע גלגול:
#    WORD-SICK ל-SICK_T שניות - הכוונת מתנדנדת חזק (player.daze) והטקסט על המסך משתבש (Scramble). קצר, בלי היפוך שליטה.
#  זומבים שהטבעת עוברת דרכם "שומעים" את המילה: מהירים יותר ל-HEARD_T שניות (drum_t של zombie.gd).
#  הנגד: לירות במגפון (MEGA_HITS פגיעות) -> SILENCED: הוא צורח ומסתער (CHARGE_MULT) בלי טבעות. או: מחסה / גלגול / מרחק.
#  "THEY LEARN": אחרי LEARN_DODGES טבעות שהתחמקת מהן - משנה קצב: הפסקות לא קבועות ושאיפות-סרק (FAKE_P)
#    ואחריהן צעקה מהירה ("IT LEARNED YOUR TIMING"). תמיד מעדיף לעמוד מאחורי זומבים אחרים (HIDE_R).
#  צלילים: "bb_inhale", "bb_shout", "bb_crack" (המגפון נשבר), "bb_squeal" (פידבק כשהוא מת).
#  לשנות: WORDS, RING_V, RING_R, SICK_T, INHALE_T, CD, LEARN_DODGES, FAKE_P, MEGA_HITS, CHARGE_MULT, HEARD_T, HIDE_R.
#  בדיקות: rings, sick, dodges, fakes, silenced, mega_hits, learned; main.get_meta("bb_heard").
# ============================================================

const FONT := preload("res://fonts/Bangers-Regular.ttf")
const SOUNDS := {
	"bb_inhale": [["N", 0, 0, 0.0, 0.55, 0.45, 2.0, 0.35, 0.5, 0, 0.2], ["V", 120, 160, 0.0, 0.55, 0.4, 2.0, 0.2, 1.0, 0.02, 0, [500, 1500, 20]]],
	"bb_shout": {"drive": 3.4, "rev": 0.3, "echo": [0.14, 0.3], "layers": [["V", 210, 170, 0.0, 0.5, 0.01, 2.6, 0.9, 1.0, 0.06, 0, [900, 1600, 60]], ["V", 300, 240, 0.12, 0.35, 0.01, 3.0, 0.5, 1.0, 0.08, 0, [1100, 2100, 70]], ["N", 0, 0, 0.0, 0.5, 0.0, 3.0, 0.25, 0.7, 0, 0.5], ["S", 1800, 1700, 0.0, 0.5, 0.02, 3.0, 0.08, 1.0, 0.02]]},
	"bb_crack": [["N", 0, 0, 0.0, 0.08, 0.0, 60.0, 0.8, 1.0, 0], ["S", 900, 300, 0.0, 0.12, 0.0, 30.0, 0.4, 1.0, 0], ["S", 2600, 2400, 0.0, 0.1, 0.0, 35.0, 0.2, 1.0, 0]],
	"bb_squeal": [["S", 2400, 3100, 0.0, 0.6, 0.05, 3.0, 0.12, 1.0, 0.03], ["S", 1200, 1550, 0.0, 0.6, 0.05, 3.0, 0.08, 1.0, 0.03]],
}

const WORDS := ["SOUTH", "HUNGRY", "HOME", "KILL", "OBEY", "SOON", "MOTHER", "OPEN", "SPREAD"]
const RING_V := 260.0
const RING_R := 420.0
const SICK_T := 1.5
const INHALE_T := 0.6
const QUICK_INHALE := 0.26
const SHOUT_T := 0.35
const CD := Vector2(3.5, 5.0)
const LEARNED_CD := Vector2(1.8, 5.6)
const LEARN_DODGES := 2
const FAKE_P := 0.4
const MEGA_HITS := 2
const MEGA_R := 8.0            # רדיוס הפגיעה במגפון (ביחידות ציור)
const CHARGE_MULT := 1.6
const HEARD_T := 3.0
const HIDE_R := 300.0

enum { IDLE, INHALE, SHOUT }
var state := IDLE
var word := "SOUTH"
var rings := 0
var sick := 0
var dodges := 0
var fakes := 0
var mega_hits := 0
var silenced := false
var learned := false
var _st := 0.0
var _inh_tot := INHALE_T
var _cd := 2.0
var _fake := false
var _quick := false
var _hide_x := INF
var _hide_cd := 0.0
var _crack := 0.0
var _shout_fx := 0.0
var _tie := Color("9a2a2a")


func stats() -> Dictionary:
	return {"name": "BABBLER", "hp": 40, "walk": 40.0, "chase": 74.0, "damage": 1, "bite_delay": 0.9, "scale": 1.0, "width": 0.95,
		"duck": 0.1, "cover": 0.1, "skin": Color("a8b0a0"), "shirt": Color("d8d4c4"), "pants": Color("2e2e36"), "shoe": Color("2a2020"), "points": 380}


func brain_overrides() -> Dictionary:
	return {"keep_range": 280.0, "aggression": 0.25}


func setup() -> void:
	var r := RandomNumberGenerator.new()
	r.seed = z.get_instance_id()
	word = WORDS[r.randi() % WORDS.size()]
	var ties := [Color("9a2a2a"), Color("2a4a8a"), Color("6a5a2a"), Color("4a2a5a")]
	_tie = ties[r.randi() % ties.size()]
	z.shirt = Art.shade(Color("d8d4c4"), r.randf_range(-0.12, 0.04))
	_cd = r.randf_range(1.0, 3.0)
	z.add_to_group("babblers")


func can_bite() -> bool:
	return true


func _main() -> Node:
	return z.get_parent()


func _bump(key: String) -> void:
	var m := _main()
	m.set_meta(key, int(m.get_meta(key, 0)) + 1)


# ============================================================
#  התנהגות
# ============================================================
func logic(pl: Node, d: Vector2, delta: float, speed: float) -> float:
	_cd -= delta
	_crack -= delta
	_shout_fx -= delta
	if pl == null:
		return speed
	if silenced:   # בלי מגפון: צורח ומסתער
		z._dir = signf(d.x) if absf(d.x) > 2.0 else z._dir
		return z.chase_speed * CHARGE_MULT
	match state:
		IDLE:
			var sp := speed
			_hide_cd -= delta
			if _hide_cd <= 0.0:
				_hide_cd = 0.6
				_hide_x = _cover_ally(pl)
			if _hide_x < INF and absf(d.x) > 120.0:
				var gx: float = _hide_x - z.global_position.x
				if absf(gx) > 8.0:
					z._dir = signf(gx)
					sp = z.chase_speed * 0.85
				else:
					z._dir = signf(d.x) if d.x != 0.0 else z._dir
					sp = 0.0
			if _cd <= 0.0 and absf(d.x) < RING_R * 0.9 and absf(d.y) < 260.0 and not pl.dead:
				state = INHALE
				_st = QUICK_INHALE if _quick else (randf_range(0.35, 0.8) if learned else INHALE_T)
				_quick = false
				_inh_tot = _st
				_fake = learned and randf() < FAKE_P
				Sfx.play("bb_inhale", z.global_position, -2.0, 0.1, 2)
				return 0.0
			return sp
		INHALE:
			z._dir = signf(d.x) if absf(d.x) > 2.0 else z._dir
			_st -= delta
			if _st <= 0.0:
				if _fake:   # שאיפת סרק: מחכה שתתגלגל סתם - ואז צועק מהר
					fakes += 1
					_fake = false
					_quick = true
					state = IDLE
					_cd = randf_range(0.35, 0.7)
				else:
					state = SHOUT
					_st = SHOUT_T
					_shout()
			return 0.0
		SHOUT:
			_st -= delta
			if _st <= 0.0:
				state = IDLE
				var cd := LEARNED_CD if learned else CD
				_cd = randf_range(cd.x, cd.y)
			return 0.0
	return speed


# זומבי אחר שעומד בינו לבינך (בטווח HIDE_R): הוא נעמד מאחוריו
func _cover_ally(pl: Node) -> float:
	var best := INF
	var bd := INF
	var side := signf(pl.global_position.x - z.global_position.x)
	for o in z.get_tree().get_nodes_in_group("zombies"):
		if o == z or o.dead or o.dormant or o.is_in_group("babblers") or absf(o.global_position.y - z.global_position.y) > 30.0:
			continue
		var ox: float = o.global_position.x
		if signf(pl.global_position.x - ox) != side or absf(pl.global_position.x - ox) < 90.0:
			continue
		var dd := absf(ox - z.global_position.x)
		if dd < HIDE_R and dd < bd:
			bd = dd
			best = ox - side * 34.0
	return best


func _mouth() -> Vector2:
	return z.global_position + Vector2(z._dir * 24.0 * z.wf, -48.0) * z.sc


func _shout() -> void:
	rings += 1
	_shout_fx = 0.35
	var r := WordRing.new()
	r.word = word
	r.src = self
	_main().add_child(r)
	r.global_position = _mouth()
	Sfx.play("bb_shout", z.global_position, 2.0, 0.08, 3, randf_range(0.9, 1.1) * z._vp)


func on_dodge(_how: String) -> void:
	dodges += 1
	_bump("bb_dodges")
	if dodges >= LEARN_DODGES and not learned:
		learned = true
		if z != null and is_instance_valid(z) and not z.dead:
			z._popup("IT LEARNED YOUR TIMING", Color("ffb070"), 12, -80.0)


func on_sick() -> void:
	sick += 1
	_bump("bb_sick")


# ============================================================
#  המגפון: נקודת פגיעה משלו
# ============================================================
func _mega_local() -> Vector2:
	return Vector2(19.0, -48.0)


func on_damage(_amount: int, hit_pos: Vector2, dir: Vector2, src: Dictionary) -> bool:
	if silenced:
		return true
	var s := str(src.get("source", "bullet"))
	if not (s == "bullet" or s == "melee"):
		return true
	var lp: Vector2 = (hit_pos - z.global_position) / z.sc
	lp.x *= z._dir / z.wf
	if lp.distance_to(_mega_local()) > MEGA_R:
		return true
	mega_hits += 1
	_crack = 0.15
	Sfx.play("bb_crack", hit_pos, 0.0, 0.12, 3)
	Particles.burst(_main(), hit_pos, "spark", Vector2(-dir.x, -0.5), 5)
	if mega_hits >= MEGA_HITS:
		_silence(dir)
	else:
		z._popup("CRACK", Color("e0e0d0"), 11, -66.0)
	return false


func _silence(dir: Vector2) -> void:
	silenced = true
	state = IDLE
	_bump("bb_silenced")
	z._popup("SILENCED", Color("80d0ff"), 15, -78.0)
	Sfx.play("zscream", z.global_position, 4.0, 0.08, 3, 1.15)
	z._rush_t = 6.0
	for i in 6:   # רסיסי פלסטיק
		var c = load("res://debris.gd").new()
		_main().add_child(c)
		c.setup(_mouth(), Vector2(3, 2), Color("e8d890") if i % 2 == 0 else Color("3a3a3a"), Vector2(-dir.x * randf_range(60, 200), -randf_range(80, 240)))


func on_death() -> void:
	Sfx.play("bb_squeal", z.global_position, -6.0, 0.1, 2)
	var l := Letters.new()
	l.word = word
	_main().add_child(l)
	l.global_position = z.global_position + Vector2(0, -72.0 * z.sc)


# ============================================================
#  הטבעת: המילה מתפשטת במעגל. פוגעת בך אם אין מחסה בדרך ואתה לא מתגלגל
# ============================================================
class WordRing extends Node2D:
	var word := ""
	var src = null
	var r := 6.0
	var _checked := false
	var _heard := {}
	var _spin := randf() * TAU

	func _ready() -> void:
		z_index = 25

	func _physics_process(delta: float) -> void:
		r += RING_V * delta
		if r > RING_R:
			queue_free()
			return
		var pl := get_tree().get_first_node_in_group("player")
		if pl != null and not _checked:
			var pc: Vector2 = pl.global_position + Vector2(0, -30)
			if r >= global_position.distance_to(pc):
				_checked = true
				_resolve(pl, pc)
		if Engine.get_physics_frames() % 3 == 0:
			for o in get_tree().get_nodes_in_group("zombies"):
				if o.dead or o.dormant or _heard.has(o.get_instance_id()) or o.is_in_group("babblers"):
					continue
				if global_position.distance_to(o.global_position + Vector2(0, -30)) < r:
					_heard[o.get_instance_id()] = true
					o.set_meta("drum_t", float(o._time) + HEARD_T)
					o._alert_t = maxf(float(o._alert_t), HEARD_T)
					var m := get_parent()
					m.set_meta("bb_heard", int(m.get_meta("bb_heard", 0)) + 1)
		if Art.on_screen(self, global_position, r + 40.0):
			queue_redraw()

	func _resolve(pl: Node, pc: Vector2) -> void:
		if pl.dead:
			return
		if pl._roll_t > 0.0:
			if src != null:
				src.on_dodge("roll")
			return
		var hit: Dictionary = get_world_2d().direct_space_state.intersect_ray(PhysicsRayQueryParameters2D.create(global_position, pc, 1))
		if not hit.is_empty():
			if src != null:
				src.on_dodge("cover")
			return
		if pl.has_method("aim_sway"):   # רק הכוונת רועדת (אם player.gd תומך)
			pl.aim_sway(SICK_T, "WORD-SICK")
		else:
			pl.daze(SICK_T, "WORD-SICK")
		Scramble.hit(get_parent(), word, SICK_T)
		Sfx.play("bb_shout", pl.global_position, -8.0, 0.2, 2, 0.6)
		if src != null:
			src.on_sick()

	func _draw() -> void:
		DrawBatch.begin(self)
		_draw_b()
		DrawBatch.end(self)

	func _draw_b() -> void:
		var a := clampf(1.0 - r / RING_R, 0.0, 1.0)
		var hot := Color(1.0, 0.32, 0.22)
		DrawBatch.arc(self, Vector2.ZERO, r, 0.0, TAU, 72, Color(hot, 0.5 * a), 3.0)
		DrawBatch.arc(self, Vector2.ZERO, r - 7.0, 0.0, TAU, 72, Color(1.0, 0.85, 0.6, 0.22 * a), 1.5)
		DrawBatch.arc(self, Vector2.ZERO, r + 5.0, 0.0, TAU, 72, Color(hot, 0.15 * a), 6.0)
		var n := clampi(int(TAU * r / 110.0), 3, 14)
		var fs := 17
		var w := FONT.get_string_size(word, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		var fr := Engine.get_physics_frames() / 3
		for k in n:
			var ang := float(k) / float(n) * TAU + _spin + r * 0.0015
			var jit := Vector2(float((fr * 7 + k * 13) % 5) - 2.0, float((fr * 11 + k * 5) % 5) - 2.0) * 0.8
			DrawBatch.set_transform(self, Vector2.from_angle(ang) * r + jit, ang + PI * 0.5, Vector2.ONE)
			DrawBatch.string_outline(self, FONT, Vector2(-w * 0.5, 6), word, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, 4, Color(0.05, 0.0, 0.0, 0.7 * a))
			DrawBatch.string(self, FONT, Vector2(-w * 0.5, 6), word, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(1.0, 0.9 - 0.4 * (1.0 - a), 0.7 - 0.4 * (1.0 - a), a))
		DrawBatch.set_transform(self, Vector2.ZERO, 0.0, Vector2.ONE)


# ============================================================
#  WORD-SICK על המסך: המילה בכל מקום, הטקסט משתבש, פסי רעש
# ============================================================
class Scramble extends CanvasLayer:
	var word := ""
	var t := 0.0
	var total := 1.0
	var _p: Node2D = null

	static func hit(m: Node, w: String, dur: float) -> void:
		for s in m.get_tree().get_nodes_in_group("s53_scramble"):
			s.word = w
			s.t = maxf(s.t, dur)
			s.total = maxf(s.total, dur)
			return
		var sc := Scramble.new()
		sc.word = w
		sc.t = dur
		sc.total = dur
		m.add_child(sc)

	func _ready() -> void:
		layer = 3
		add_to_group("s53_scramble")
		_p = Painter.new()
		_p.owner_s = self
		add_child(_p)

	func _process(delta: float) -> void:
		t -= delta
		if t <= -0.25:
			queue_free()
			return
		_p.queue_redraw()


class Painter extends Node2D:
	var owner_s = null

	func _scrambled(w: String, sd: int) -> String:
		var chars := w.split("")
		var out := ""
		var rr := RandomNumberGenerator.new()
		rr.seed = sd
		for i in chars.size():
			var j := rr.randi() % chars.size()
			out += chars[j] if rr.randf() < 0.5 else chars[i]
		return out

	func _draw() -> void:
		DrawBatch.begin(self)
		_draw_b()
		DrawBatch.end(self)

	func _draw_b() -> void:
		var vs := get_viewport_rect().size
		var k := clampf((owner_s.t + 0.25) / 0.45, 0.0, 1.0) * clampf((owner_s.total - owner_s.t) / 0.12 + 0.3, 0.0, 1.0)
		var fr := int(Time.get_ticks_msec() / 70)
		# קצוות אדומים פועמים
		var edge := Color(0.7, 0.05, 0.05, 0.22 * k)
		DrawBatch.rect(self, Rect2(0, 0, vs.x, 26), edge)
		DrawBatch.rect(self, Rect2(0, vs.y - 26, vs.x, 26), edge)
		DrawBatch.rect(self, Rect2(0, 0, 30, vs.y), edge)
		DrawBatch.rect(self, Rect2(vs.x - 30, 0, 30, vs.y), edge)
		# פסי רעש
		var rr := RandomNumberGenerator.new()
		rr.seed = fr
		for i in 5:
			var y := rr.randf() * vs.y
			DrawBatch.rect(self, Rect2(0, y, vs.x, rr.randf_range(2.0, 7.0)), Color(1, 1, 1, rr.randf_range(0.03, 0.09) * k))
		# המילה בכל מקום - עם אותיות מבולבלות
		for i in 14:
			var p := Vector2(rr.randf() * vs.x, rr.randf_range(40.0, vs.y - 40.0))
			if i < 4:   # מעל הטקסט של ה-HUD (פינות למעלה)
				p = Vector2(rr.randf_range(20.0, 300.0) if i % 2 == 0 else rr.randf_range(vs.x - 320.0, vs.x - 40.0), rr.randf_range(24.0, 90.0))
			var fs := rr.randi_range(18, 44)
			var txt: String = _scrambled(owner_s.word, fr * 31 + i)
			var c := Color(1.0, rr.randf_range(0.2, 0.6), rr.randf_range(0.15, 0.3), rr.randf_range(0.35, 0.8) * k)
			DrawBatch.set_transform(self, p, rr.randf_range(-0.25, 0.25), Vector2.ONE)
			DrawBatch.string_outline(self, FONT, Vector2.ZERO, txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, 5, Color(0, 0, 0, 0.6 * k))
			DrawBatch.string(self, FONT, Vector2.ZERO, txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, c)
		DrawBatch.set_transform(self, Vector2.ZERO, 0.0, Vector2.ONE)
		var big: String = owner_s.word
		var bw := FONT.get_string_size(big, HORIZONTAL_ALIGNMENT_LEFT, -1, 72).x
		var bp := Vector2(vs.x * 0.5 - bw * 0.5 + rr.randf_range(-6, 6), vs.y * 0.32 + rr.randf_range(-4, 4))
		DrawBatch.string_outline(self, FONT, bp, big, HORIZONTAL_ALIGNMENT_LEFT, -1, 72, 8, Color(0, 0, 0, 0.45 * k))
		DrawBatch.string(self, FONT, bp, big, HORIZONTAL_ALIGNMENT_LEFT, -1, 72, Color(1.0, 0.3, 0.2, 0.55 * k))


# ============================================================
#  במוות: האותיות של המילה מתפזרות
# ============================================================
class Letters extends Node2D:
	var word := ""
	var t := 0.0
	var _v: Array = []

	func _ready() -> void:
		z_index = 26
		for i in word.length():
			_v.append(Vector2(randf_range(-160, 160), randf_range(-260, -90)))

	func _process(delta: float) -> void:
		t += delta
		for i in _v.size():
			_v[i].y += 420.0 * delta
		if t > 1.3:
			queue_free()
		queue_redraw()

	func _draw() -> void:
		DrawBatch.begin(self)
		_draw_b()
		DrawBatch.end(self)

	func _draw_b() -> void:
		var a := clampf((1.3 - t) / 0.5, 0.0, 1.0)
		for i in word.length():
			var p: Vector2 = Vector2(float(i) * 11.0 - float(word.length()) * 5.5, 0) + _v[i] * t * 0.5
			DrawBatch.set_transform(self, p, t * (3.0 if i % 2 == 0 else -3.0), Vector2.ONE)
			DrawBatch.string_outline(self, FONT, Vector2(-5, 6), word[i], HORIZONTAL_ALIGNMENT_LEFT, -1, 18, 4, Color(0, 0, 0, 0.7 * a))
			DrawBatch.string(self, FONT, Vector2(-5, 6), word[i], HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(1.0, 0.75, 0.5, a))
		DrawBatch.set_transform(self, Vector2.ZERO, 0.0, Vector2.ONE)


# ============================================================
#  ציור: שדרן רדיו מת עם מגפון
# ============================================================
func draw() -> bool:
	begin_draw()
	var sk := col(z.skin)
	var dk := col(Art.shade(z.skin, 0.25))
	var sh_c := col(z.shirt)
	var pa := col(z.pants)
	var p: float = z._walk_phase
	var t: float = z._time
	var f: Array = feet(5.0, 2.5)
	var hip := Vector2(0, -22)
	var sh := Vector2(2, -39)
	var head := sh + Vector2(3, -9)
	var inh := 0.0
	if state == INHALE and not silenced:
		inh = clampf(1.0 - _st / maxf(_inh_tot, 0.01), 0.0, 1.0)
		sh += Vector2(-1.5, -1.0) * inh   # נשען אחורה, החזה מתנפח
		head += Vector2(-2.0, -1.0) * inh
	elif state == SHOUT or _shout_fx > 0.0:
		sh += Vector2(2.0, 0.5)
		head += Vector2(3.0, 0.5)
	if silenced:   # רץ כפוף קדימה
		sh += Vector2(4, 2)
		head = sh + Vector2(6, -6)
	# רגליים
	z._leg(hip + Vector2(-3, 0), f[1], col(Art.shade(z.pants, 0.25)), dk, col(z.shoe))
	# יד אחורית: מתעוותת / מסתערת
	var hb := sh + Vector2(-5.0 + sin(t * 9.0) * 1.5, 15.0)
	if silenced:
		hb = sh + Vector2(13, 2 + sin(p) * 2.0)
	elif inh > 0.0:
		hb = sh + Vector2(-8, 4)
	_arm2(sh + Vector2(-4, 1), hb, dk, col(Art.shade(z.shirt, 0.2)), 4.2)
	# גוף: חולצה לבנה מלוכלכת, כתפיות, עניבה רפויה
	var torso := PackedVector2Array([sh + Vector2(-7, -1), sh + Vector2(7, 0), sh + Vector2(6.5 + inh * 1.5, 10), hip + Vector2(6, 1), hip + Vector2(-6, 1), sh + Vector2(-8, 9)])
	Art.fill_shaded(z, torso, sh_c, 0.12, 0.3)
	for q in 3:   # כתמים
		DrawBatch.circle(z, sh + Vector2(-3.0 + float(q) * 3.5, 8.0 + float(q % 2) * 6.0), 1.4 + float(q % 2) * 0.6, col(Color(0.42, 0.08, 0.06, 0.55)))
	DrawBatch.line(z, sh + Vector2(-5, 0), hip + Vector2(-4, 0), col(Color("3a2a22")), 1.4)   # כתפיות
	DrawBatch.line(z, sh + Vector2(4, 0), hip + Vector2(4, 0), col(Color("3a2a22")), 1.4)
	var tie_sway := sin(t * 3.0 + p) * 1.5
	Art.fill(z, PackedVector2Array([sh + Vector2(1, 1), sh + Vector2(3, 1), sh + Vector2(3.5 + tie_sway, 14), sh + Vector2(1.8 + tie_sway, 16), sh + Vector2(0.5 + tie_sway, 13)]), col(_tie), Art.OUTLINE, 0.8)
	Art.fill(z, PackedVector2Array([hip + Vector2(-7, -1), hip + Vector2(7, -1), hip + Vector2(7, 4), hip + Vector2(-7, 4)]), pa, Art.OUTLINE, 1.0)
	z._leg(hip + Vector2(3, 0), f[0], pa, sk, col(z.shoe))
	# אוזניות סביב הצוואר (שדרן)
	var neck := sh + Vector2(1, -2)
	DrawBatch.arc(z, neck + Vector2(0, -1), 5.0, 0.2, PI - 0.2, 8, col(Color("2a2a30")), 1.6)
	Art.oval(z, neck + Vector2(5, 1), 2.0, 2.6, col(Color("3a3a42")), 0.0, Art.OUTLINE, 0.8)
	Art.oval(z, neck + Vector2(-5, 1), 2.0, 2.6, col(Color("3a3a42")), 0.0, Art.OUTLINE, 0.8)
	DrawBatch.line(z, neck + Vector2(-5, 3), hip + Vector2(-8, 2), col(Color("1a1a1e")), 0.8)   # כבל קרוע
	# ראש: שיער דליל, לסת שמוטה
	Art.oval_shaded(z, head, 5.4, 6.0, sk, 0.05)
	for q in 4:
		DrawBatch.line(z, head + Vector2(-4.0 + float(q) * 2.0, -5.0), head + Vector2(-5.5 + float(q) * 2.0, -7.5 - float(q % 2)), col(Color("4a4038")), 0.9)
	var jaw := 1.0 + inh * 1.5 + (2.5 if state == SHOUT or silenced else 0.0)
	face(head, Vector2(3.5, -0.8))
	DrawBatch.colored_polygon(z, PackedVector2Array([head + Vector2(1.5, 2.5), head + Vector2(5.4, 2.0), head + Vector2(5.0, 3.0 + jaw), head + Vector2(1.8, 3.0 + jaw * 0.8)]), col(Color("2a0808")))
	DrawBatch.line(z, head + Vector2(2.5, 2.0), head + Vector2(3.4, 4.0 + jaw), col(Color(0.6, 0.1, 0.1, 0.7)), 0.7)   # שפה סדוקה
	# יד קדמית + המגפון
	var mega := _mega_local()
	if silenced:
		var hf := sh + Vector2(15, 4 + sin(p + 1.5) * 2.0)
		_arm2(sh + Vector2(4, 1), hf, sk, sh_c, 4.4, true)
		DrawBatch.line(z, hf, hf + Vector2(4, 3), col(Color("e8d890")), 2.0)   # שבר של הידית
	else:
		var hf := mega + Vector2(-7.5, 5.5)
		_arm2(sh + Vector2(4, 1), hf, sk, sh_c, 4.4, true)
		_megaphone(mega, inh)
	end_draw()
	# בועה משוננת עם המילה (לא הפוכה)
	if not z.dead and not z._lying() and not silenced:
		_bubble(inh)
	return true


# יד עם מרפק מוגבל: בלי "כנף" כשהיד קרובה לכתף (z._arm מותח את המרפק החוצה). המרפק פונה למטה/אחורה (fwd = קדימה)
func _arm2(a: Vector2, b: Vector2, skin_c: Color, sleeve: Color, w := 4.6, fwd := false) -> void:
	var d := b - a
	var n := Vector2.ZERO
	if d.length() > 0.01:
		n = d.orthogonal().normalized()
		if n.y + (n.x if fwd else -n.x) * 0.5 < 0.0:
			n = -n
	var half := d.length() * 0.5
	var e := a + d * 0.5 + n * minf(sqrt(maxf(0.0, 90.0 - half * half)), 3.5)
	Art.limb(z, PackedVector2Array([a, e]), w + 0.6, sleeve)
	Art.limb(z, PackedVector2Array([e, b]), w, skin_c)
	Art.disc(z, b, w * 0.55, skin_c, Art.OUTLINE, 1.0)


func _megaphone(m: Vector2, inh: float) -> void:
	var body := col(Color("e8d890"))
	var shake := Vector2(sin(z._time * 60.0), cos(z._time * 47.0)) * 0.6 * inh
	m += shake
	var k := 1.3
	# ידית
	DrawBatch.line(z, m + Vector2(-7, 1) * k, m + Vector2(-6, 6) * k, col(Color("2a2a2e")), 2.6)
	# קונוס
	var cone := PackedVector2Array([m + Vector2(-9, -1.5) * k, m + Vector2(-9, 1.5) * k, m + Vector2(4, 5.5) * k, m + Vector2(4, -5.5) * k])
	Art.fill_shaded(z, cone, body, 0.25, 0.3, Art.OUTLINE, 1.1)
	DrawBatch.line(z, m + Vector2(-8, -1.2) * k, m + Vector2(3, -4.6) * k, col(Color(1, 1, 1, 0.35)), 1.0)   # ברק
	Art.oval(z, m + Vector2(4, 0) * k, 1.6 * k, 5.6 * k, col(Color("3a3428")), 0.0, Art.OUTLINE, 1.0)
	DrawBatch.line(z, m + Vector2(-4, -2.5) * k, m + Vector2(0, 3.5) * k, col(Color("2a2418")), 0.9)   # סדק
	DrawBatch.line(z, m + Vector2(-1, -3.5) * k, m + Vector2(1, -4.6) * k, col(Color("2a2418")), 0.8)
	DrawBatch.rect(z, Rect2(m + Vector2(-5, -3.3) * k, Vector2(3, 6.6) * k), col(Color(0.8, 0.8, 0.8, 0.55)))   # סלוטייפ
	DrawBatch.circle(z, m + Vector2(-9.5, 0) * k, 1.4, col(Color("c03020")))   # נורית אדומה
	if mega_hits > 0:   # נפגע פעם אחת - סדק גדול
		DrawBatch.line(z, m + Vector2(-8, 0) * k, m + Vector2(3, -4) * k, col(Color("1a1410")), 1.2)
	if _crack > 0.0:
		Art.glow(z, m, 9.0, Color(1, 1, 0.9, 0.7))
	if state == SHOUT and not z.dead:   # קווי קול
		for q in 3:
			var rr := 9.0 + float(q) * 4.5 + (SHOUT_T - _st) * 30.0
			DrawBatch.arc(z, m + Vector2(5, 0) * k, rr, -0.6, 0.6, 8, Color(1.0, 0.4, 0.25, 0.75 - float(q) * 0.18), 1.6)


func _bubble(inh: float) -> void:
	var t: float = z._time
	var c := Vector2(0, -78.0 * z.sc - 8.0 * inh)
	var fs := int(11.0 + 6.0 * inh)
	var w := FONT.get_string_size(word, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x + 12.0
	var h := float(fs) + 6.0
	var jag := PackedVector2Array()
	var n := 14
	for i in n:
		var a := float(i) / float(n) * TAU
		var rr := 1.0 + (0.22 if i % 2 == 0 else -0.05) + sin(t * 20.0 + float(i)) * 0.04 * (1.0 + inh * 3.0)
		jag.append(c + Vector2(cos(a) * w * 0.5, sin(a) * h * 0.62) * rr)
	var hot := inh > 0.0 or state == SHOUT
	Art.fill(z, jag, Color(1.0, 0.94, 0.86, 0.92) if not hot else Color(1.0, 0.82, 0.7, 0.95), Art.OUTLINE, 1.2)
	DrawBatch.colored_polygon(z, PackedVector2Array([c + Vector2(-3, h * 0.5), c + Vector2(4, h * 0.5), c + Vector2(z._dir * 6.0, h * 0.5 + 7.0)]), Color(1.0, 0.94, 0.86, 0.92))
	var jit := Vector2(sin(t * 50.0), cos(t * 43.0)) * 1.2 * inh
	var tc := Color(0.15, 0.05, 0.05).lerp(Color(0.85, 0.08, 0.05), inh)
	DrawBatch.string(z, FONT, c + Vector2(-w * 0.5 + 6.0, float(fs) * 0.36) + jit, word, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, tc)
