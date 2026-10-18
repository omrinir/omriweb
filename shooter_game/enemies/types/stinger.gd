extends "res://enemies/zombie_type.gd"
# ============================================================
#  STINGER (שלב 54, "LAST BRIDGE") - ערפד-זומבי קירח וחיוור במעיל ארוך, ורידים שחורים, גרון נפוח.
#  השראה: הסטריגוי של "The Strain" (גיירמו דל טורו וצ'אק הוגן - ספרים וקומיקס): הלסת נפתחת ויוצא ממנה עוקץ ארוך.
#    SWELL  - הגרון מתנפח וזוהר באדום (SWELL_T, קול גרגור) - האזהרה.
#    STING  - הלסת נפרדת ועוקץ בשרי נורה ישר אליך עד STING_R (EXT_T), נשאר HOLD_T וחוזר (RET_T).
#             פגיעה: DMG לב + שואב ממך: הוא מחלים HEAL, אתה מואט. רק פגיעה אחת לכל עקיצה.
#    העוקץ בחוץ = נקודת תורפה גדולה (StingBody, שכבה 4): ירייה בו = STING_DMG והוא נרתע (stagger) ומחזיר אותו.
#    מוות: תולעים לבנות (WORMS) זוחלות מהגופה אליך כמה שניות. נגיעה = הרעלה קטנה (POISON_HITS נגיעות = לב אחד) + האטה.
#          אש / פיצוץ / אור הפנס או הזיקוק הורגים אותן. גלגול מעליהן = נמעכות בלי רעל.
#  לומד (main meta "st_dodges"): אחרי DODGE_LEARN עקיצות שהתחמקת מהן - מזייף: מתנפח, משחרר (FAKE_T),
#         ויורה בהתנפחות השנייה, המהירה (SWELL2_T). "IT FEINTS NOW".
#  לשנות: STING_MIN, STING_R, SWELL_T, EXT_T, HOLD_T, RET_T, STING_CD, HEAL, STING_DMG, WORMS, WORM_*, POISON_HITS, DODGE_LEARN.
# ============================================================

const SOUNDS := {
	"st_gurgle": [["V", 120, 90, 0.0, 0.6, 0.1, 2.5, 0.5, 1.0, 0.12, 0, [300, 700, 10]], ["N", 0, 0, 0.0, 0.6, 0.1, 3.0, 0.2, 0.25, 0, 0.3]],
	"st_shoot": [["N", 0, 0, 0.0, 0.14, 0.0, 22.0, 0.55, 0.6, 0, 0.6], ["S", 500, 1500, 0.0, 0.12, 0.0, 20.0, 0.3, 1.0, 0.0]],
	"st_suck": [["V", 200, 140, 0.0, 0.45, 0.02, 4.0, 0.5, 1.0, 0.1, 0, [500, 900, 20]], ["N", 0, 0, 0.0, 0.4, 0.05, 5.0, 0.25, 0.3, 0, 0.4]],
	"st_shriek": {"drive": 2.4, "layers": [["V", 520, 380, 0.0, 0.5, 0.01, 4.0, 0.7, 1.0, 0.08, 0, [1300, 2200, 50]], ["N", 0, 0, 0.0, 0.4, 0.0, 6.0, 0.25, 0.7, 0, 0.5]]},
	"st_worm": [["N", 0, 0, 0.0, 0.25, 0.02, 10.0, 0.18, 0.15, 0, 0.1], ["B", 1.4, 1.4, 0.0, 0.2, 0.0, 9.0, 0.15, 1.0, 0, 0, 40.0]],
}

const STING_MIN := 70.0
const STING_R := 250.0
const SWELL_T := 0.6
const SWELL2_T := 0.28        # (למד) ההתנפחות האמיתית אחרי הזיוף
const FAKE_T := 0.5
const EXT_T := 0.12
const HOLD_T := 0.3
const RET_T := 0.24
const STING_CD := 2.4
const DMG := 1
const HEAL := 12
const STING_DMG := 28
const RECOIL_T := 0.8
const DODGE_LEARN := 2
const WORMS := 6
const WORM_LIFE := 6.0
const WORM_V := 52.0
const POISON_HITS := 3

enum {IDLE, SWELL, FAKE, EXTEND, HOLD, RETRACT}

# לבדיקות
var stings := 0
var sting_hits := 0
var weak_hits := 0
var dodges := 0
var feints := 0

var state := IDLE
var _t := 0.0
var _cd := 1.2
var _len := 0.0
var _reach := 0.0
var _hit := false
var _faked := false
var _aim_dir := 1.0
var _body: StaticBody2D = null
var _shape: CollisionShape2D = null
var _swell := 0.0


func stats() -> Dictionary:
	return {"name": "STINGER", "hp": 40, "walk": 40.0, "chase": 104.0, "damage": 1, "bite_delay": 0.9, "scale": 1.05, "width": 0.92,
		"duck": 0.15, "cover": 0.3, "skin": Color("c6c2be"), "shirt": Color("2a2a30"), "pants": Color("1e1e24"), "shoe": Color("141416"), "points": 450}


func brain_overrides() -> Dictionary:
	return {"aggression": 0.55, "keep_range": 170.0}


func learned() -> bool:
	var m: Node = z.get_parent()
	return m != null and int(m.get_meta("st_dodges", 0)) >= DODGE_LEARN


func setup() -> void:
	_body = StingBody.new()
	_body.owner_t = self
	_body.collision_layer = 0
	_body.collision_mask = 0
	_shape = CollisionShape2D.new()
	var rs := RectangleShape2D.new()
	rs.size = Vector2(20, 10)
	_shape.shape = rs
	_body.add_child(_shape)
	z.get_parent().add_child.call_deferred(_body)


func mouth() -> Vector2:
	return z.global_position + Vector2(float(z._dir) * 7.0 * z.wf, -50.0) * z.sc


func can_bite() -> bool:
	return state == IDLE


func logic(pl: Node, d: Vector2, _delta: float, speed: float) -> float:
	if state != IDLE:
		return 0.0
	return speed


func physics(pl: Node, delta: float) -> bool:
	_cd -= delta
	_swell = move_toward(_swell, 1.0 if state == SWELL or state == FAKE else 0.0, delta * (3.0 if state == SWELL else 5.0))
	if z.dead:
		_place_body()
		return false
	var has_pl: bool = pl != null and not pl.dead
	match state:
		IDLE:
			if has_pl and _cd <= 0.0 and z.is_on_floor() and z._stagger_t <= 0.0:
				var dd: Vector2 = pl.global_position - z.global_position
				if absf(dd.x) > STING_MIN and absf(dd.x) < STING_R - 20.0 and absf(dd.y) < 40.0:
					z._dir = signf(dd.x)
					_aim_dir = z._dir
					_faked = false
					if learned():
						state = FAKE
						_t = FAKE_T
					else:
						state = SWELL
						_t = SWELL_T
					Sfx.play("st_gurgle", z.global_position, 0.0, 0.1, 3)
		FAKE:   # מתנפח ומשחרר - בודק אם תתחמק לשווא
			z.velocity.x = 0.0
			_t -= delta
			if _t <= 0.0:
				feints += 1
				_faked = true
				state = SWELL
				_t = SWELL2_T
				_swell = 0.3
				if feints == 1:
					z._popup("IT FEINTS NOW", Color("ff8a7a"), 12, -86.0)
		SWELL:
			z.velocity.x = 0.0
			_t -= delta
			if has_pl:
				z._dir = signf(pl.global_position.x - z.global_position.x + 0.01)
				_aim_dir = z._dir
			if _t <= 0.0:
				state = EXTEND
				_t = EXT_T
				_hit = false
				stings += 1
				var dd2: float = absf(pl.global_position.x - z.global_position.x) if has_pl else STING_R
				_reach = clampf(dd2 + 40.0, 90.0, STING_R)
				Sfx.play("st_shoot", mouth(), 2.0, 0.1, 3)
		EXTEND:
			z.velocity.x = 0.0
			_t -= delta
			_len = _reach * clampf(1.0 - _t / EXT_T, 0.0, 1.0)
			_check_hit(pl)
			if _t <= 0.0:
				state = HOLD
				_t = HOLD_T
		HOLD:
			z.velocity.x = 0.0
			_t -= delta
			_len = _reach
			_check_hit(pl)
			if _t <= 0.0:
				_retract()
		RETRACT:
			z.velocity.x = 0.0
			_t -= delta
			_len = _reach * clampf(_t / RET_T, 0.0, 1.0)
			if _t <= 0.0:
				state = IDLE
				_len = 0.0
				_cd = STING_CD
	_place_body()
	return false


func _retract() -> void:
	state = RETRACT
	_t = RET_T
	if not _hit:   # התחמקת
		dodges += 1
		var m: Node = z.get_parent()
		m.set_meta("st_dodges", int(m.get_meta("st_dodges", 0)) + 1)


func tip() -> Vector2:
	return mouth() + Vector2(_aim_dir * _len, 0.0)


func _check_hit(pl: Node) -> void:
	if _hit or pl == null or pl.dead:
		return
	var r: Rect2 = pl.body_rect().grow(3.0)
	var a := mouth()
	var b := tip()
	var x0 := minf(a.x, b.x)
	var x1 := maxf(a.x, b.x)
	var hit: bool = r.position.y < a.y and r.end.y > a.y and x1 > r.position.x and x0 < r.end.x
	if not hit or pl._roll_t > 0.0:
		return
	_hit = true
	sting_hits += 1
	pl.hurt(DMG, Vector2(_aim_dir * 0.8, -0.3))
	pl.slow_t = maxf(pl.slow_t, 0.7)
	z.hp = mini(z.max_hp, z.hp + HEAL)
	Sfx.play("st_suck", z.global_position, 1.0, 0.1, 2)
	z._popup("DRAINED", Color("ff5a6a"), 13, -84.0)
	_reach = minf(_reach, absf(pl.global_position.x - mouth().x))   # נתקע בך ונשאב
	state = HOLD
	_t = HOLD_T + 0.15


func _place_body() -> void:
	if _body == null or not is_instance_valid(_body) or not _body.is_inside_tree():
		return
	var out: bool = not z.dead and (state == EXTEND or state == HOLD or state == RETRACT) and _len > 24.0
	if not out:
		if _body.collision_layer != 0:
			_body.collision_layer = 0
			_body.global_position = Vector2(-9999, -9999)
		return
	_body.collision_layer = 4
	var a := mouth() + Vector2(_aim_dir * 14.0, 0.0)
	var b := tip()
	_body.global_position = a.lerp(b, 0.5)
	(_shape.shape as RectangleShape2D).size = Vector2(maxf(absf(b.x - a.x), 10.0), 12.0)


# ירייה בעוקץ
func weak_hit(p: Vector2, d: Vector2) -> void:
	if z.dead or not (state == EXTEND or state == HOLD or state == RETRACT):
		return
	weak_hits += 1
	Particles.burst(z.get_parent(), p, "hit", -d, 8)
	z._popup("STINGER!", Color("ffb070"), 14, -90.0)
	Sfx.play("st_shriek", z.global_position, 0.0, 0.1, 2)
	if not _hit:
		_hit = true   # (לא נספר כהתחמקות)
	state = RETRACT
	_t = RET_T * 0.6
	z.take_damage(0, mouth(), d, false, {"source": "bullet", "fixed": STING_DMG})
	if not z.dead:
		z.stagger(RECOIL_T)


func on_death() -> void:
	_len = 0.0
	if _body != null and is_instance_valid(_body):
		_body.queue_free()
	# תולעים זוחלות מהגופה
	var m: Node = z.get_parent()
	for i in WORMS:
		var w := Worm.new()
		w.position = z.global_position + Vector2(randf_range(-10.0, 10.0), -4.0)
		w.vy = -randf_range(120.0, 220.0)
		w.vx = randf_range(-60.0, 60.0)
		w.ground_y = z.global_position.y
		w.delay = float(i) * 0.12
		m.add_child(w)
	Sfx.play("st_worm", z.global_position, 2.0, 0.1, 2)


class StingBody extends StaticBody2D:
	var owner_t = null

	func hit_by_bullet(p: Vector2, _n: Vector2, d: Vector2) -> void:
		if owner_t != null and owner_t.z != null and is_instance_valid(owner_t.z):
			owner_t.weak_hit(p, d)


# ============================================================
#  תולעת טפיל לבנה (מהגופה של STINGER): קופצת החוצה, זוחלת אליך על הריצפה, מתפתלת. WORM_LIFE שניות.
#  נגיעה = רעל (meta "worm_poison" על השחקן: POISON_HITS נגיעות = לב). גלגול = נמעכת. אש / פיצוץ / פנס / זיקוק = מתה.
# ============================================================
class Worm extends Node2D:
	static var spawned := 0         # לבדיקות
	static var touched := 0
	static var burned := 0
	static var lit_dead := 0
	static var squished := 0
	var vx := 0.0
	var vy := -160.0
	var ground_y := 630.0
	var delay := 0.0
	var _t := 0.0
	var _life := WORM_LIFE
	var _dir := 1.0
	var _dying := 0.0
	var _seed := 0.0

	func _ready() -> void:
		z_index = 3
		spawned += 1
		_seed = randf() * 10.0
		add_to_group("blastable")
		add_to_group("st_worms")
		visible = false

	func blast_rect() -> Rect2:
		return Rect2(global_position + Vector2(-8, -8), Vector2(16, 10))

	func hit_by_blast(_c: Vector2, _r: float) -> void:
		if _dying <= 0.0:
			burned += 1
			_die()

	func _die() -> void:
		_dying = 0.3
		remove_from_group("blastable")

	func _process(delta: float) -> void:
		if delay > 0.0:
			delay -= delta
			return
		visible = true
		_t += delta
		if _dying > 0.0:
			_dying -= delta
			modulate.a = _dying / 0.3
			if _dying <= 0.0:
				queue_free()
			queue_redraw()
			return
		_life -= delta
		if _life <= 0.0:
			_die()
			return
		var pl := get_tree().get_first_node_in_group("player")
		# באוויר: קופצת מהגופה
		if global_position.y < ground_y - 0.5 or vy < 0.0:
			vy += 900.0 * delta
			global_position += Vector2(vx, vy) * delta
			if global_position.y >= ground_y:
				global_position.y = ground_y
				vy = 0.0
		elif pl != null and not pl.dead:
			var dx: float = pl.global_position.x - global_position.x
			_dir = signf(dx) if absf(dx) > 2.0 else _dir
			var crawl: float = WORM_V * (0.6 + 0.4 * absf(sin(_t * 7.0 + _seed)))   # מתכווצת ונמתחת
			global_position.x += _dir * crawl * delta
			if absf(dx) < 12.0 and absf(pl.global_position.y - global_position.y) < 18.0:
				if pl._roll_t > 0.0:
					squished += 1
					Particles.burst(get_parent(), global_position + Vector2(0, -2), "hit", Vector2.UP, 3)
					queue_free()
					return
				touched += 1
				var n := int(pl.get_meta("worm_poison", 0)) + 1
				pl.set_meta("worm_poison", n)
				pl.slow_t = maxf(pl.slow_t, 0.6)
				if n % POISON_HITS == 0:
					pl.hurt(1, Vector2(0, -0.2))
					pl._say("POISONED", Color("c0ff90"))
				queue_free()
				return
		# אור / אש הורגים אותה
		if Engine.get_process_frames() % 6 == 0:
			if _burning():
				burned += 1
				_die()
			elif _lit():
				lit_dead += 1
				Particles.burst(get_parent(), global_position + Vector2(0, -3), "smoke", Vector2.UP, 2)
				_die()
		if Art.on_screen(self, global_position, 60.0):
			queue_redraw()

	func _lit() -> bool:
		for n in get_tree().get_nodes_in_group("dyn_lights"):
			if not n.has_method("lights"):
				continue
			for l in n.lights():
				if float(l[2]) > 0.35 and global_position.distance_to(l[0]) < float(l[1]) * 0.55:
					return true
		return false

	func _burning() -> bool:
		for h in get_tree().get_nodes_in_group("hazards"):
			if h.get("zombie_burn") != null and h.global_position.distance_to(global_position) < 70.0:
				return true
		for z in get_tree().get_nodes_in_group("zombies"):
			if float(z._burn_t) > 0.0 and z.global_position.distance_to(global_position) < 40.0:
				return true
		return false

	func _draw() -> void:
		var pts := PackedVector2Array()
		var n := 7
		for q in n:
			var u := float(q) / float(n - 1)
			var x := -_dir * u * 11.0
			var y := -2.0 + sin(_t * 12.0 + u * 6.0 + _seed) * 1.6 * (0.4 + u)
			pts.append(Vector2(x, y))
		DrawBatch.polyline(self, pts, Color(0.35, 0.05, 0.08, 0.6), 3.4)
		DrawBatch.polyline(self, pts, Color(0.95, 0.93, 0.86), 2.2)
		DrawBatch.circle(self, pts[0], 1.5, Color(0.9, 0.5, 0.5))


# ============================================================
#  ציור: קירח, עור אפור-לבן עם ורידים שחורים, מעיל ארוך כהה וקרוע, עיניים אדומות עם שוליים כהים.
#  הגרון מתנפח וזוהר באדום (SWELL). כשעוקץ: הלסת התחתונה נשמטת ונפתחת לצדדים, והעוקץ (צינור בשרי ורוד-אדום
#  עם קוץ בקצה) יוצא ישר קדימה. אחרי שנפגע בעוקץ - מכסה את הפה ביד.
# ============================================================
func draw() -> bool:
	begin_draw()
	var sk := col(z.skin)
	var coat := col(z.shirt)
	var f: Array = feet(5.0, 2.4)
	var hip := Vector2(0, -26)
	var sh := Vector2(1.5, -45)
	var lunge := 0.0
	if state == EXTEND or state == HOLD:
		lunge = 3.0
	elif state == SWELL or state == FAKE:
		lunge = -1.5 * _swell
	sh.x += lunge
	var head := sh + Vector2(2.5, -8)
	var t: float = z._time
	# שולי המעיל הארוך מאחור
	var sway: float = clampf(sin(t * 2.2) * 1.4 + (-z.velocity.x * z._dir) * 0.025, -6.0, 6.0)   # (יותר מזה - המצולע מצטלב)
	Art.fill(z, PackedVector2Array([hip + Vector2(-7, -6), hip + Vector2(4, -4), hip + Vector2(3.0 + sway * 0.5, 15), hip + Vector2(-3.0 + sway, 17), hip + Vector2(-9.0 + sway, 15)]), col(Art.shade(z.shirt, 0.2)))
	z._leg(hip + Vector2(-2, 0), f[1], col(Art.shade(z.pants, 0.25)), sk, col(z.shoe))
	z._leg(hip + Vector2(2, 0), f[0], col(z.pants), sk, col(z.shoe))
	# יד אחורית
	_arm(sh + Vector2(-3, 1), sh + Vector2(-6.0 + sin(t * 2.0), 15.0), true)
	# גוף: מעיל ארוך, צווארון מורם
	var torso := PackedVector2Array([sh + Vector2(-7, -1), sh + Vector2(7, 0), hip + Vector2(6, 0), hip + Vector2(-7, -2)])
	Art.fill_shaded(z, torso, coat, 0.1, 0.35)
	DrawBatch.line(z, sh + Vector2(3, 1), hip + Vector2(3, -3), col(Art.shade(z.shirt, 0.45)), 1.0)
	for q in 3:
		DrawBatch.circle(z, sh.lerp(hip, 0.25 + float(q) * 0.22) + Vector2(4.5, -1), 0.8, col(Color("4a4a50")))
	DrawBatch.colored_polygon(z, PackedVector2Array([sh + Vector2(-1, 3), sh + Vector2(3, 2), sh + Vector2(1, 10)]), col(Color("d8d4cc")))   # חולצה מתחת
	DrawBatch.line(z, sh + Vector2(0, 6), sh + Vector2(1, 9), Color(0.9, 0.9, 0.85), 0.7)   # דם לבן
	# צווארון מורם
	Art.fill(z, PackedVector2Array([sh + Vector2(-7, 0), sh + Vector2(-6, -7), sh + Vector2(-2, -3), sh + Vector2(1, -2), sh + Vector2(6, 0)]), col(Art.shade(z.shirt, -0.08)), Art.OUTLINE, 0.9)
	# הגרון הנפוח
	var throat := sh + Vector2(3.0, -2.5)
	if _swell > 0.02:
		var r := 2.0 + 3.2 * _swell
		Art.oval(z, throat, r * 0.85, r, col(Color("c87a7a").lerp(Color("e04a4a"), _swell)), 0.0, Art.OUTLINE, 0.8)
		Art.glow(z, throat, 6.0 + 6.0 * _swell, Color(1.0, 0.25, 0.2, 0.35 * _swell))
	_head(head, sk)
	# העוקץ
	if _len > 1.0 and not z.dead:
		_draw_sting(head)
	# יד קדמית: מושטת קדימה, או מכסה את הפה כשנרתע
	var hf := sh + Vector2(7.0 + sin(t * 1.8), 14.0)
	if z._stagger_t > 0.0:
		hf = head + Vector2(5, 3)
	elif z._bite_anim > 0.0 or state == HOLD:
		hf = sh + Vector2(15, 1)
	_arm(sh + Vector2(4, 1), hf, false)
	end_draw()
	return true


func _arm(s: Vector2, h: Vector2, back: bool) -> void:
	var c := col(Art.shade(z.shirt, 0.25 if back else 0.0))
	var el := Art.joint(s, h, 13.0, 13.0, -1.0 if back else 1.0)
	Art.limb(z, PackedVector2Array([s, el, el.lerp(h, 0.7)]), 3.2, c)
	Art.limb(z, PackedVector2Array([el.lerp(h, 0.65), h]), 1.9, col(Art.shade(z.skin, 0.2 if back else 0.0)))
	var dir := (h - el).normalized()
	for q in 3:   # אצבעות ארוכות עם ציפורניים
		DrawBatch.line(z, h, h + dir.rotated((float(q) - 1.0) * 0.4) * 3.6, col(Color("2a2a26")), 0.8)


func _head(c: Vector2, sk: Color) -> void:
	var open: float = 1.0 if (state == EXTEND or state == HOLD) else (clampf(_t / RET_T, 0.0, 1.0) if state == RETRACT else 0.0)
	# קרקפת קירחה, ורידים שחורים, אוזניים מחודדות
	Art.oval_shaded(z, c, 4.8, 5.8, sk, 0.0)
	DrawBatch.colored_polygon(z, PackedVector2Array([c + Vector2(-3.5, -1), c + Vector2(-6.5, -3.5), c + Vector2(-4.0, 1.5)]), col(Art.shade(z.skin, 0.2)))
	if not z.dead:
		var vc := Color(0.12, 0.1, 0.14, 0.7)
		DrawBatch.polyline(z, PackedVector2Array([c + Vector2(-2, -5.5), c + Vector2(-0.5, -3), c + Vector2(-1.5, 0)]), vc, 0.6)
		DrawBatch.polyline(z, PackedVector2Array([c + Vector2(2, -5.6), c + Vector2(1.2, -3.4)]), vc, 0.6)
		# עיניים: אדומות עם שוליים כהים
		DrawBatch.colored_polygon(z, Art.ellipse(c + Vector2(2.4, -1.0), 1.9, 1.4, 0.0, 8), col(Color("3a0a10")))
		DrawBatch.circle(z, c + Vector2(2.6, -1.0), 0.9, Color(1.0, 0.25, 0.2))
		DrawBatch.colored_polygon(z, Art.ellipse(c + Vector2(-1.6, -1.0), 1.2, 1.1, 0.0, 8), col(Color("3a0a10")))
		DrawBatch.circle(z, c + Vector2(-1.4, -1.0), 0.6, Color(0.9, 0.2, 0.2, 0.8))
		Art.glow(z, c + Vector2(2.6, -1.0), 3.5, Color(1.0, 0.2, 0.15, 0.4))
	# לסת: נשמטת ונפרדת כשעוקץ
	var jaw := c + Vector2(1.5, 3.0)
	if open > 0.0:
		DrawBatch.colored_polygon(z, PackedVector2Array([jaw + Vector2(0, 0), jaw + Vector2(5.5, -0.5), jaw + Vector2(5.0, 1.5 + 4.5 * open), jaw + Vector2(0.5, 1.5 + 4.0 * open)]), col(Color("3a0610")))
		DrawBatch.line(z, jaw + Vector2(0.5, 1.5 + 4.0 * open), jaw + Vector2(5.0, 1.5 + 4.5 * open), col(sk.darkened(0.15)), 1.6)   # הלסת שנשמטה
		DrawBatch.line(z, jaw + Vector2(3, 0), jaw + Vector2(6.5, -2.0 - 2.0 * open), col(sk.darkened(0.2)), 1.0)   # הלחי נקרעת לצדדים
	else:
		DrawBatch.line(z, jaw + Vector2(0.5, 0.5), jaw + Vector2(4.5, 0.2), col(Color("2a0a10")), 1.0)
		DrawBatch.line(z, jaw + Vector2(0.4, 2.2), jaw + Vector2(4.2, 2.0), col(sk.darkened(0.25)), 0.8)


func _draw_sting(head: Vector2) -> void:
	var a := head + Vector2(5.5, 4.0)
	var l: float = _len / (z.sc * z.wf)
	var pts := PackedVector2Array()
	var n := 10
	var t: float = z._time
	for q in n + 1:
		var u := float(q) / float(n)
		var wob: float = sin(u * 9.0 + t * 30.0) * 1.2 * u * (1.0 if state == EXTEND else 0.4)
		pts.append(a + Vector2(u * l, wob))
	Art.limb(z, pts, 2.6, col(Color("c25a6a")))
	DrawBatch.polyline(z, pts, Color(1.0, 0.75, 0.8, 0.6), 0.8)
	for q in 4:   # טבעות שרירים
		var p: Vector2 = pts[2 + q * 2]
		DrawBatch.line(z, p + Vector2(0, -2.2), p + Vector2(0, 2.2), col(Color("8a2a3a")), 0.8)
	var e: Vector2 = pts[n]
	DrawBatch.colored_polygon(z, PackedVector2Array([e + Vector2(0, -2.8), e + Vector2(6, 0), e + Vector2(0, 2.8)]), col(Color("e8d8c0")))   # הקוץ
	if _hit and state == HOLD:
		Art.glow(z, e, 5.0, Color(1.0, 0.2, 0.25, 0.6))
