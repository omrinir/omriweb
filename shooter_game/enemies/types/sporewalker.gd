extends "res://enemies/zombie_type.gd"
# ============================================================
#  SPOREWALKER (שלב 49, "RIVER DELTA") - זומבי שהלחות של הדלתא גידלה עליו פטריות: כובעי פטרייה על הכתפיים והראש,
#    פטריות מדף על הגב, קורים לבנים (מיצליום) על העור, ונבגים זוהרים שנושרים ממנו. (השראה: Cordyceps - הפטרייה שמשתלטת
#    על נמלים ב-The Last of Us / The Girl with All the Gifts.)
#  * כשאתה קרוב (PUFF_R) הוא מתנפח (PUFF_WIND, הפטריות זוהרות) ונושף ענן נבגים (SporeCloud): בתוך הענן אתה איטי
#    (slow_t) ומטושטש (daze "SPORES"). גם ירייה בו מקרוב (פחות מ-HIT_PUFF_D) משחררת נשיפה קטנה.
#  * כשהוא מת צומח מהגופה גבעול (Stalk). אם לא יורים בו (STALK_HP פגיעות) או שורפים אותו / מפוצצים (blastable) תוך
#    GROW_T שניות - הוא פורח: מקים עד RAISE_MAX גופות בטווח RAISE_R, ואם אין גופות - 1-2 רצים רעבים (kind 1).
#    הרוג אותו כשהוא בוער (קליעי אש / פיצוץ) = אין גבעול בכלל ("BURNED").
#  "THEY CHOOSE WHERE TO DIE": אחרי LEARN_CUT גבעולים שקטעת (main meta "spore_cut") - פטרייתי פצוע (מתחת ל-SEEK_HP)
#    הולך בכוונה למות ליד גופות (SEEK_R), והגבעולים שלהם גדלים מהר יותר (GROW_T_LEARNED).
#  צלילים: "sp_puff" (נשיפה), "sp_grow" (הגבעול צומח), "sp_bloom" (פריחה).
#  לשנות: PUFF_R, PUFF_CD, PUFF_WIND, CLOUD_R, CLOUD_T, SLOW_T, STALK_HP, GROW_T, RAISE_R, RAISE_MAX, LEARN_CUT, SEEK_HP.
# ============================================================

const SOUNDS := {
	"sp_puff": [["N", 0, 0, 0.0, 0.55, 0.02, 4.0, 0.55, 0.3, 0, 0.7], ["S", 200, 90, 0.0, 0.3, 0.0, 8.0, 0.2, 1.0, 0.1]],
	"sp_grow": [["S", 70, 140, 0.0, 0.9, 0.2, 2.0, 0.3, 1.0, 0.2], ["N", 0, 0, 0.0, 0.6, 0.1, 4.0, 0.15, 0.4, 0, 0.5]],
	"sp_bloom": [["N", 0, 0, 0.0, 0.8, 0.0, 4.0, 0.6, 0.35, 0, 0.6], ["S", 160, 420, 0.0, 0.5, 0.05, 5.0, 0.3, 1.0, 0.15], ["S", 90, 60, 0.0, 0.9, 0.1, 2.5, 0.3, 1.0, 0.2]],
}

const PUFF_R := 115.0
const PUFF_CD := Vector2(3.5, 5.0)
const PUFF_WIND := 0.55
const HIT_PUFF_D := 110.0
const CLOUD_R := 95.0
const CLOUD_T := 3.2
const SLOW_T := 1.4
const DAZE_T := 0.9
const STALK_HP := 3
const GROW_T := 4.5
const GROW_T_LEARNED := 3.0
const RAISE_R := 190.0
const RAISE_MAX := 2
const LEARN_CUT := 2
const SEEK_HP := 0.55
const SEEK_R := 380.0

enum { WALK, PUFF, SEEK }
var state := WALK
var puffs := 0                # לבדיקות
var seeks := 0
var burned := false
var _st := 0.0
var _cd := 1.5
var _hit_cd := 0.0
var _look := 0.0
var _target: Node = null


func stats() -> Dictionary:
	return {"name": "SPOREWALKER", "hp": 44, "walk": 34.0, "chase": 58.0, "damage": 1, "bite_delay": 0.9, "scale": 1.05, "width": 1.1,
		"duck": 0.0, "cover": 0.2, "skin": Color("8a9a78"), "shirt": Color("5a5040"), "pants": Color("3a3a30"), "shoe": Color("2a241c"), "points": 420}


func brain_overrides() -> Dictionary:
	return {"aggression": 0.45, "flank_probability": -0.2}


static func learned(main: Node) -> bool:
	return main.has_meta("spore_cut") and int(main.get_meta("spore_cut")) >= LEARN_CUT


func can_bite() -> bool:
	return state == WALK


func on_damage(_amount: int, hit_pos: Vector2, _dir: Vector2, src: Dictionary) -> bool:
	if z.dead or _hit_cd > 0.0:
		return true
	var pl := player()
	if pl != null and str(src.get("source", "bullet")) in ["bullet", "melee"] and pl.global_position.distance_to(z.global_position) < HIT_PUFF_D:
		_hit_cd = 1.6
		_cloud(hit_pos, CLOUD_R * 0.6, CLOUD_T * 0.6)   # הפטריות מתפוצצות מהפגיעה
	return true


func logic(pl: Node, d: Vector2, delta: float, speed: float) -> float:
	_st -= delta
	_cd -= delta
	_hit_cd -= delta
	_look -= delta
	if pl == null or pl.dead:
		return speed
	var main: Node = z.get_parent()
	match state:
		WALK:
			if _cd <= 0.0 and absf(d.x) < PUFF_R and absf(d.y) < 70.0:
				state = PUFF
				_st = PUFF_WIND
				z._dir = signf(d.x) if d.x != 0.0 else z._dir
				return 0.0
			if _look <= 0.0 and learned(main) and float(z.hp) < float(z.max_hp) * SEEK_HP:
				_look = 0.5
				_target = _corpse_near()
				if _target != null:
					state = SEEK
					seeks += 1
					if not main.has_meta("spore_seek_said"):
						main.set_meta("spore_seek_said", true)
						z._popup("THEY CHOOSE WHERE TO DIE", Color("c8e090"), 14, -86.0 * z.sc)
			return speed
		PUFF:
			if _st <= 0.0:
				puffs += 1
				state = WALK
				_cd = randf_range(PUFF_CD.x, PUFF_CD.y)
				_cloud(z.global_position + Vector2(z._dir * 46.0, -26.0) * z.sc, CLOUD_R, CLOUD_T)
			return 0.0
		SEEK:
			if _target == null or not is_instance_valid(_target) or _target.is_queued_for_deletion():
				_target = null
				state = WALK
				return speed
			_target._dead_t = minf(float(_target._dead_t), 1.5)   # הגופה מחכה לו
			var dx: float = _target.global_position.x - z.global_position.x
			if absf(dx) < 16.0:   # הגיע - עומד ליד הגופות ונושף כשמתקרבים
				if _cd <= 0.0 and absf(d.x) < PUFF_R:
					state = PUFF
					_st = PUFF_WIND
				z._dir = signf(d.x) if d.x != 0.0 else z._dir
				return 0.0
			z._dir = signf(dx)
			return float(z.chase_speed) * 1.15
	return speed


func _corpse_near() -> Node:
	var best: Node = null
	var bd := SEEK_R
	for c in z.get_tree().get_nodes_in_group("corpses"):
		if not is_instance_valid(c) or c.has_meta("revived") or c.is_queued_for_deletion():
			continue
		if absf(c.global_position.y - z.global_position.y) > 40.0 or float(c._dead_t) > float(c.corpse_time) - 2.0:
			continue
		var dd: float = absf(c.global_position.x - z.global_position.x)
		if dd < bd:
			bd = dd
			best = c
	return best


func _cloud(at: Vector2, r: float, life: float) -> void:
	var g := SporeCloud.new()
	g.r = r
	g.life = life
	z.get_parent().add_child.call_deferred(g)
	g.position = at
	Sfx.play("sp_puff", at, -2.0, 0.12, 2)


func on_death() -> void:
	var src := str(z._last_info.get("source", "")) if z.get("_last_info") != null else ""
	if float(z._burn_t) > 0.0 or src in ["fire", "explosion", "grenade", "rocket", "molotov"]:
		burned = true
		Stalk.burned += 1
		z._popup("BURNED", Color("ffb060"), 13, -70.0)
		return
	if z.has_meta("revived"):
		return
	var s := Stalk.new()
	s.corpse = z
	s.grow_t = GROW_T_LEARNED if learned(z.get_parent()) else GROW_T
	z.get_parent().add_child.call_deferred(s)
	s.position = z.global_position


# ============================================================
#  ענן נבגים: איטי וזוהר. שחקן בתוכו = slow_t + daze ("SPORES"). לא מזיק לזומבים.
# ============================================================
class SporeCloud extends Node2D:
	const TICK := 0.5
	static var player_hits := 0     # לבדיקות
	var r := 88.0
	var life := 3.2
	var _t := 0.0
	var _tick := 0.1
	var _seed := 0.0

	func _ready() -> void:
		z_index = 8
		_seed = randf() * 10.0
		add_to_group("hazards")

	func world_rect() -> Rect2:
		return Rect2(global_position - Vector2(r, r * 0.7), Vector2(r * 2.0, r * 1.3))

	func danger_at(p: Vector2, margin := 0.0) -> bool:
		return world_rect().grow(margin).has_point(p)

	func _physics_process(delta: float) -> void:
		_t += delta
		_tick -= delta
		if _tick <= 0.0 and _t < life - 0.3:
			_tick = TICK
			var pl := get_tree().get_first_node_in_group("player")
			if pl != null and not pl.dead:
				var q: Vector2 = pl.global_position + Vector2(0, -26) - global_position
				if (q.x * q.x) / (r * r) + (q.y * q.y) / (r * r * 0.55) < 1.0:
					player_hits += 1
					pl.slow_t = maxf(float(pl.slow_t), SLOW_T)
					pl.daze(DAZE_T, "SPORES")
		if _t >= life:
			queue_free()
			return
		if Engine.get_physics_frames() % 2 == 0 and preload("res://art.gd").on_screen(self, global_position, r + 40.0):
			queue_redraw()

	func _draw() -> void:
		var k := _t / life
		var grow := minf(_t * 3.5, 1.0)
		var a := (1.0 - k) * minf(_t * 5.0, 1.0)
		for q in 11:
			var ang := float(q) * 2.4 + _seed
			var rr := r * (0.12 + 0.6 * fposmod(float(q) * 0.41, 1.0)) * grow
			var p := Vector2(cos(ang + _t * 0.5), sin(ang + _t * 0.4) * 0.5) * rr + Vector2(0, -_t * 6.0)
			var sz := r * (0.3 + 0.1 * float(q % 3)) * grow
			DrawBatch.circle(self, p, sz, Color(0.86, 0.82, 0.55, 0.16 * a))
			DrawBatch.circle(self, p + Vector2(-sz * 0.2, -sz * 0.25), sz * 0.5, Color(0.95, 0.92, 0.7, 0.12 * a))
		for q in 18:   # נבגים זוהרים
			var sp := Vector2(sin(float(q) * 2.7 + _t * 0.9) * r * 0.85, cos(float(q) * 1.9 + _t * 0.7) * r * 0.45 - _t * 8.0)
			DrawBatch.circle(self, sp, 1.2 + float(q % 2) * 0.6, Color(0.95, 1.0, 0.6, 0.7 * a))


# ============================================================
#  גבעול הפטרייה שצומח מהגופה. נכנס לשכבה 4 (קליעים נעצרים בו), ו-"blastable" (פיצוץ / מולוטוב שורפים אותו).
#  STALK_HP פגיעות = נקטע. אחרי grow_t שניות - פורח (קם / רצים).
# ============================================================
class Stalk extends Node2D:
	static var grown := 0           # לבדיקות
	static var cut := 0
	static var burned := 0
	static var blooms := 0
	static var raised := 0
	static var runners := 0
	var corpse: Node = null
	var grow_t := 4.5
	var hp := 3
	var _t := 0.0
	var _done := false
	var _body: StaticBody2D = null
	var _shape: CollisionShape2D = null
	var _flash := 0.0
	var _seed := 0.0

	class StalkBody extends StaticBody2D:
		var s = null
		func hit_by_bullet(p: Vector2, _n: Vector2, _d: Vector2) -> void:
			if s != null:
				s.shot(p)

	func _ready() -> void:
		z_index = 3
		_seed = randf() * 10.0
		grown += 1
		hp = 3
		add_to_group("blastable")
		_body = StalkBody.new()
		_body.s = self
		_body.collision_layer = 4
		_body.collision_mask = 0
		_shape = CollisionShape2D.new()
		var rs := RectangleShape2D.new()
		rs.size = Vector2(16, 40)
		_shape.shape = rs
		_shape.position = Vector2(0, -20)
		_body.add_child(_shape)
		add_child(_body)
		preload("res://sfx.gd").play("sp_grow", global_position, -4.0, 0.1, 2)

	func blast_rect() -> Rect2:
		return Rect2(global_position + Vector2(-12, -50), Vector2(24, 50))

	func hit_by_blast(_c: Vector2, _r: float) -> void:
		if _done:
			return
		burned += 1
		_end("BURNED", Color("ffb060"))

	func shot(p: Vector2) -> void:
		if _done:
			return
		hp -= 1
		_flash = 0.1
		preload("res://particles.gd").burst(get_parent(), p, "hit", Vector2.UP, 4)
		if hp <= 0:
			cut += 1
			_end("CUT", Color("c8e090"))

	func _end(msg: String, c: Color) -> void:
		_done = true
		var main := get_parent()
		main.set_meta("spore_cut", int(main.get_meta("spore_cut")) + 1 if main.has_meta("spore_cut") else 1)
		_popup(msg, c)
		preload("res://particles.gd").burst(main, global_position + Vector2(0, -20), "smoke", Vector2.UP, 6)
		queue_free()

	func _popup(text: String, c: Color) -> void:
		if corpse != null and is_instance_valid(corpse) and corpse.has_method("_popup"):
			corpse._popup(text, c, 13, -50.0)

	func _physics_process(delta: float) -> void:
		_t += delta
		_flash -= delta
		if corpse != null and is_instance_valid(corpse):
			if _t < 1.0:   # הגופה עוד נופלת - הגבעול צומח ממנה
				global_position = corpse.global_position
			corpse._dead_t = minf(float(corpse._dead_t), 1.0)   # הגופה לא נעלמת עד שהגבעול גמור
		if not _done and _t >= grow_t:
			_bloom()
			return
		if Engine.get_physics_frames() % 2 == 0 and preload("res://art.gd").on_screen(self, global_position, 80.0):
			queue_redraw()

	func _bloom() -> void:
		_done = true
		blooms += 1
		var main := get_parent()
		var Sf := preload("res://sfx.gd")
		Sf.play("sp_bloom", global_position, 2.0, 0.1, 2)
		var g := SporeCloud.new()
		g.r = 70.0
		g.life = 2.2
		main.add_child(g)
		g.position = global_position + Vector2(0, -40)
		var n := 0
		var R := preload("res://enemies/zombie_registry.gd")
		var Rv := preload("res://enemies/types/reviver.gd")
		var mx := RAISE_MAX + (1 if main.has_meta("spore_cut") and int(main.get_meta("spore_cut")) >= LEARN_CUT else 0)
		if main.has_method("_spawn_zombie"):
			for c in get_tree().get_nodes_in_group("corpses"):
				if n >= mx:
					break
				if c == corpse or not is_instance_valid(c) or c.has_meta("revived") or c.is_queued_for_deletion() or int(c.kind) == R.SPOREWALKER:
					continue
				if c.global_position.distance_to(global_position) > RAISE_R:
					continue
				var nz = main._spawn_zombie(c.global_position.x, c.global_position.y, Rv._kind_for(int(c.kind)))
				if nz == null:
					continue
				nz.set_meta("revived", true)
				nz._alert_t = 8.0
				nz.velocity = Vector2(0, -180.0)
				nz._popup("RISE!", Color("c8e090"), 14, -80.0)
				if c.get("_rag") != null:
					c._rag.release()
				c.remove_from_group("corpses")
				c.queue_free()
				n += 1
				raised += 1
			if n == 0:   # אין גופות - הגבעול "יולד" רצים רעבים
				var k := 1 + (1 if randf() < 0.5 else 0)
				for i in k:
					var dir := -1.0 if i == 0 else 1.0
					var nz = main._spawn_zombie(global_position.x + dir * 14.0, global_position.y, 1)
					if nz == null:
						continue
					nz.set_meta("revived", true)
					nz._alert_t = 10.0
					nz._dir = dir
					nz.velocity = Vector2(dir * 140.0, -260.0)
					runners += 1
				if corpse != null and is_instance_valid(corpse):
					corpse._popup("HUNGRY!", Color("c8e090"), 14, -60.0)
		queue_free()

	func _draw() -> void:
		var Ar := preload("res://art.gd")
		var k := clampf(_t / grow_t, 0.0, 1.0)
		var h := 8.0 + 36.0 * k
		var wob := sin(_t * 3.0 + _seed) * (1.0 + 3.0 * k)
		var stem := Color(0.84, 0.8, 0.62) if _flash <= 0.0 else Color.WHITE
		var tip := Vector2(wob, -h)
		# קורים / שורשים על הגופה
		for q in 5:
			var a := -2.6 + float(q) * 0.55
			DrawBatch.line(self, Vector2.ZERO, Vector2.from_angle(a) * Vector2(16.0, 6.0) + Vector2(0, 2), Color(0.9, 0.88, 0.75, 0.55), 1.0)
		Ar.limb(self, PackedVector2Array([Vector2(0, 0), Vector2(wob * 0.3 + 2.0, -h * 0.5), tip]), 3.0 + 2.0 * k, stem)
		for q in 3:   # גבעולים קטנים מהצד
			var bp := Vector2(wob * 0.3, -h * (0.35 + float(q) * 0.18))
			var bt := bp + Vector2((-1.0 if q % 2 == 0 else 1.0) * (5.0 + 4.0 * k), -6.0 * k)
			DrawBatch.line(self, bp, bt, stem, 1.4)
			DrawBatch.circle(self, bt, 1.6 + k, Color(0.75, 0.6, 0.35))
		# הפרח / הקפסולה בראש - מתנפחת ופועמת לקראת הפריחה
		var pulse := 0.5 + 0.5 * sin(_t * (4.0 + 14.0 * k))
		var pr := 4.0 + 6.0 * k + pulse * 1.5 * k
		Ar.glow(self, tip, pr * 2.6, Color(0.85, 0.95, 0.4, 0.15 + 0.25 * k * pulse))
		Ar.oval_shaded(self, tip, pr, pr * 1.2, Color(0.72, 0.52, 0.3) if _flash <= 0.0 else Color.WHITE, 0.0)
		for q in 5:   # כתמים זוהרים על הקפסולה
			var a := float(q) * 1.26 + _seed
			DrawBatch.circle(self, tip + Vector2(cos(a), sin(a) * 1.2) * pr * 0.55, 1.0 + 0.4 * k, Color(0.95, 1.0, 0.55, 0.5 + 0.5 * pulse))
		if k > 0.7:   # אזהרה: עומד לפרוח
			DrawBatch.arc(self, tip, pr + 4.0 + pulse * 3.0, 0.0, TAU, 18, Color(0.95, 1.0, 0.5, 0.6 * pulse), 1.5)
		# מד זמן מתחת
		DrawBatch.line(self, Vector2(-12, 6), Vector2(12, 6), Color(0, 0, 0, 0.4), 3.0)
		DrawBatch.line(self, Vector2(-12, 6), Vector2(-12.0 + 24.0 * k, 6), Color(0.85, 0.95, 0.4, 0.85), 2.0)


# ============================================================
#  ציור: גוף אנושי שמכוסה פטריות. כובעי פטרייה על הכתף והראש, פטריות מדף על הגב, קורים לבנים, נבגים זוהרים.
#  נשיפה (PUFF): ראש לאחור, ידיים פתוחות, הפטריות מתנפחות וזוהרות.
# ============================================================
func draw() -> bool:
	begin_draw()
	var sk := col(z.skin)
	var shirt := col(z.shirt)
	var pants := col(z.pants)
	var t: float = z._time
	var puff := state == PUFF
	var wk := clampf(1.0 - _st / PUFF_WIND, 0.0, 1.0) if puff else 0.0
	var cap := col(Color("b0703a"))
	var cap2 := col(Color("d8c8a0"))
	var myc := Color(0.92, 0.9, 0.8, 0.6)
	if z.dead:
		var hip0 := Vector2(-6, -6)
		Art.limb(z, PackedVector2Array([hip0, Vector2(-18, -4)]), 6.0, pants)
		Art.fill_shaded(z, PackedVector2Array([Vector2(-8, -12), Vector2(12, -12), Vector2(12, -2), Vector2(-8, -1)]), shirt, 0.15, 0.3)
		Art.oval_shaded(z, Vector2(18, -7), 6.5, 6.0, sk, 0.0)
		for q in 4:
			Art.oval(z, Vector2(-4.0 + float(q) * 6.0, -13.0), 3.5, 2.0, cap if q % 2 == 0 else cap2, 0.0)
		end_draw()
		return true
	var f: Array = feet(4.5, 2.2)
	var hip := Vector2(0, -24)
	var lean := 2.0 + (-3.0 * wk if puff else 0.0)
	var sh := Vector2(lean, -44.0)
	var hc := sh + Vector2(2.5 - 3.0 * wk, -10.0)
	z._leg(hip + Vector2(-3, 0), f[1], Art.shade(pants, 0.2), Art.shade(sk, 0.15), col(z.shoe))
	# יד אחורית
	var hb := sh + (Vector2(-14, -8) if puff else Vector2(-4.0 + sin(z._walk_phase) * 3.0, 18.0))
	z._arm(sh + Vector2(-5, 1), hb, Art.shade(sk, 0.15), shirt)
	z._leg(hip + Vector2(3, 0), f[0], pants, sk, col(z.shoe))
	z._torso_walker(sh, hip, sk, shirt)
	# קורים לבנים על הגוף
	for q in 4:
		var mp := sh + Vector2(-6.0 + float(q) * 3.5, 4.0 + float(q % 2) * 8.0)
		DrawBatch.polyline(z, PackedVector2Array([mp, mp + Vector2(2, 3), mp + Vector2(-1, 6)]), myc, 1.0)
	# פטריות מדף על הגב (נפתחות בזמן נשיפה)
	for q in 3:
		var bp := sh + Vector2(-8.5, 4.0 + float(q) * 6.0)
		var w := 6.0 + float(q % 2) * 1.5 + wk * 2.0
		Art.fill(z, PackedVector2Array([bp, bp + Vector2(-w, -1.5), bp + Vector2(-w + 1.0, 1.8), bp + Vector2(0, 2.5)]), cap if q != 1 else cap2, Art.OUTLINE, 0.9)
		DrawBatch.line(z, bp + Vector2(-w + 1.5, 0.5), bp + Vector2(-1, 1.0), col(Color("7a4a22")), 0.8)
	# הראש
	z._head(hc, sk)
	# פטריות על הראש - אשכול של כובעים על גבעולים
	var grow := 1.0 + wk * 0.35
	var heads := [[Vector2(-3, -7), 5.5, cap], [Vector2(2, -9), 4.0, cap2], [Vector2(-6, -3), 3.5, cap2], [Vector2(5, -6), 3.0, cap]]
	for m in heads:
		var base: Vector2 = hc + Vector2(m[0])
		var stem_top := base + Vector2(sin(t * 1.5 + base.x) * 0.6, -4.0 * grow)
		DrawBatch.line(z, base, stem_top, col(Color("e0d8c0")), 1.6)
		var r: float = float(m[1]) * grow
		Art.fill(z, PackedVector2Array([stem_top + Vector2(-r, 1), stem_top + Vector2(-r * 0.7, -r * 0.55), stem_top + Vector2(0, -r * 0.75), stem_top + Vector2(r * 0.7, -r * 0.55), stem_top + Vector2(r, 1)]), m[2], Art.OUTLINE, 1.0)
		DrawBatch.circle(z, stem_top + Vector2(-r * 0.3, -r * 0.35), 0.9, col(Color("f0e8d0")))
	# פטרייה גדולה על הכתף הקדמית
	var sp := sh + Vector2(6.0, 0.0)
	DrawBatch.line(z, sp, sp + Vector2(2, -5.0 * grow), col(Color("e0d8c0")), 2.2)
	var cr := 6.5 * grow
	Art.fill(z, PackedVector2Array([sp + Vector2(2 - cr, -4), sp + Vector2(2 - cr * 0.6, -4 - cr * 0.65), sp + Vector2(2, -4 - cr * 0.8), sp + Vector2(2 + cr * 0.6, -4 - cr * 0.65), sp + Vector2(2 + cr, -4)]), cap, Art.OUTLINE, 1.1)
	for q in 3:
		DrawBatch.circle(z, sp + Vector2(-1.0 + float(q) * 3.0, -7.0 * grow), 0.9, col(Color("f0e8d0")))
	# זוהר נבגים
	var gl := 0.12 + 0.1 * sin(t * 3.0) + wk * 0.35
	Art.glow(z, hc + Vector2(0, -8), 16.0 + wk * 14.0, Color(0.9, 1.0, 0.5, gl))
	if not z.crowded():
		for q in 5:   # נבגים שנושרים
			var fp := hc + Vector2(-8.0 + float(q) * 4.0, -6.0 + fmod(t * 9.0 + float(q) * 7.0, 34.0))
			DrawBatch.circle(z, fp, 0.9, Color(0.95, 1.0, 0.6, 0.6))
	# יד קדמית
	var hf := sh + (Vector2(16, -10) if puff else Vector2(9.0 - sin(z._walk_phase) * 3.0, 17.0))
	z._arm(sh + Vector2(5, 1), hf, sk, shirt)
	if puff:   # ענן קטן מהפה כבר מתחיל
		Art.glow(z, hc + Vector2(8, -2), 6.0 + wk * 8.0, Color(0.9, 0.9, 0.6, 0.4 * wk))
	end_draw()
	return true
