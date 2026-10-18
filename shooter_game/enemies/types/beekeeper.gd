extends "res://enemies/zombie_type.gd"
# ============================================================
#  BEEKEEPER (שלב 51, "THE RANCH") - כוורן מת בחליפה לבנה מרופטת וכובע רשת. הגוף שלו הפך לכוורת:
#  חלות דבש בחזה, דבורים זוחלות על העור, ותיבת כוורת ענקית קשורה לגב עם חלות שבולטות החוצה.
#    KEEP    - שומר מרחק (KEEP_R) ונותן לנחיל לעבוד.
#    RELEASE - פותח את הכוורת על הגב (RELEASE_T, אזהרה: זמזום חזק) ומשחרר נחיל (Swarm).
#  Swarm - ענן דבורים עם חיים (SWARM_HP): רודף אחריך, עוקץ (נזק לאורך זמן - STING_DMG כל STING_T).
#          עשן מפזר אותו: מדורת אסאדו (smoke_src), אש (fire_zone / זומבי בוער), פיצוץ, קליע אש. אפשר גם לירות בו.
#          מחסה עוצר אותו (הדבורים לא עוברות דרך חבילות חציר).
#  הכוורת על הגב: ירייה בה מאחור / מעל הראש (HIVE_HP) שוברת אותה - דבש נשפך (שלולית דביקה שמאטה) ונחיל זועם
#          אחד יוצא (מהיר יותר, ANGRY_MULT). אחרי זה הכוורן בלי נחילים - ומשתולל.
#  "THEY LEARN": הנחיל נתקע מאחורי המחסה שלך (BLOCK_LEARN שניות) -> מהנחיל הבא הם מקיפים: עולים מעל המחסה ובאים מהצד השני.
#  לשנות: KEEP_R, RELEASE_T, SWARM_CD, SWARM_HP, SWARM_V, SWARM_LIFE, STING_DMG, STING_T, HIVE_HP, ANGRY_MULT, BLOCK_LEARN, HONEY_T.
# ============================================================

const Decor := preload("res://effects/s51_decor.gd")

const SOUNDS := {
	"bk_buzz": [["S", 220, 232, 0.0, 0.7, 0.1, 1.2, 0.3, 1.0, 0.6], ["N", 0, 0, 0.0, 0.7, 0.1, 1.5, 0.12, 0.6, 0]],
	"bk_release": [["S", 180, 300, 0.0, 0.8, 0.2, 1.5, 0.45, 1.0, 0.8], ["N", 0, 0, 0.0, 0.8, 0.1, 2.0, 0.2, 0.5, 0]],
	"bk_crack": [["N", 0, 0, 0.0, 0.2, 0.0, 18.0, 0.8, 0.4, 0], ["S", 300, 120, 0.0, 0.15, 0.0, 20.0, 0.4, 1.0, 0]],
	"bk_splat": [["N", 0, 0, 0.0, 0.3, 0.0, 9.0, 0.6, 0.12, 0]],
}

const KEEP_R := Vector2(200.0, 330.0)
const RELEASE_T := 0.8
const RELEASE_R := 560.0
const SWARM_CD := 3.5
const SWARM_HP := 40
const SWARM_V := 150.0
const SWARM_LIFE := 15.0
const STING_DMG := 1
const STING_T := 1.1
const HIVE_HP := 32
const ANGRY_MULT := 1.4
const BLOCK_LEARN := 1.5
const HONEY_T := 16.0

enum { WALK, RELEASE }
var state := WALK
var hive_hp := HIVE_HP
var broken := false
var swarm: Node = null
var wide := false            # למד להקיף מחסה
var blocked_t := 0.0         # (הנחיל מדווח)
# לבדיקות
var releases := 0
var hive_hits := 0
var breaks := 0
var _st := 0.0
var _cd := 1.5
var _buzz := 0.0


func stats() -> Dictionary:
	return {"name": "BEEKEEPER", "hp": 60, "walk": 36.0, "chase": 66.0, "damage": 1, "bite_delay": 0.9, "scale": 1.05, "width": 1.1,
		"duck": 0.0, "cover": 0.2, "skin": Color("8e9470"), "shirt": Color("cfc6a6"), "pants": Color("bdb496"), "shoe": Color("3a3024"),
		"points": 400}


func brain_overrides() -> Dictionary:
	return {"aggression": 0.35, "keep_range": 260.0}


func damage_mult(_zone: String, _src: Dictionary) -> float:
	return 1.0


# הכוורת על הגב: פגיעה מאחור (בגובה הגב) או מעל הראש
func on_damage(amount: int, hit_pos: Vector2, dir: Vector2, src: Dictionary) -> bool:
	if broken:
		return true
	var source := str(src.get("source", "bullet"))
	if not (source == "bullet" or source == "melee"):
		if source == "grenade" or source == "hazard":   # פיצוץ שובר את הכוורת מיד
			_break(dir)
		return true
	var ly: float = (hit_pos.y - z.global_position.y) / z.sc
	var lx: float = (hit_pos.x - z.global_position.x) * z._dir / z.sc
	var back: bool = dir.x * z._dir > 0.0 or lx < -6.0
	if ly < -58.0 or (back and ly < -24.0):
		var dmg := hit_damage(amount, Vector2(hit_pos.x, z.global_position.y - 32.0 * z.sc), src)
		hive_hp -= dmg
		hive_hits += 1
		z._flash = 0.08
		Sfx.play("bk_crack", hit_pos, -4.0, 0.15, 3)
		Particles.burst(z.get_parent(), hit_pos, "spark", -dir, 4)
		Game.on_zombie_hit({"source": source, "zone": "hive"})
		if hive_hp <= 0:
			_break(dir)
		return false
	return true


func _break(dir: Vector2) -> void:
	if broken:
		return
	broken = true
	breaks += 1
	state = WALK
	z._popup("HIVE BROKEN!", Color("ffc840"), 16, -96.0 * z.sc)
	Sfx.play("bk_crack", z.global_position, 4.0, 0.1, 2, 0.7)
	Sfx.play("bk_splat", z.global_position, 2.0)
	var hp := _hive_pos()
	for i in 3:
		Particles.burst(z.get_parent(), hp, "hit", Vector2(randf_range(-1, 1), -0.6), 3)
	var pd := HoneyPuddle.new()
	z.get_parent().add_child(pd)
	pd.global_position = Vector2(z.global_position.x - z._dir * 16.0, z.global_position.y)
	# נחיל זועם אחד (גם אם כבר יש נחיל באוויר)
	_spawn_swarm(true)
	z.chase_speed *= 1.3
	z.walk_speed *= 1.2


func _hive_pos() -> Vector2:
	return z.global_position + Vector2(-z._dir * 10.0 * z.wf, -44.0) * z.sc


func physics(pl: Node, delta: float) -> bool:
	_cd -= delta
	_st -= delta
	if z.dead:
		return false
	if swarm != null and not is_instance_valid(swarm):
		swarm = null
	match state:
		WALK:
			if broken or pl == null or pl.dead or swarm != null or _cd > 0.0:
				return false
			var d: Vector2 = pl.global_position - z.global_position
			if d.length() < RELEASE_R and (z.brain == null or z.brain.seen_t < 2.0 or d.length() < 260.0):
				state = RELEASE
				_st = RELEASE_T
				z._dir = signf(d.x) if d.x != 0.0 else z._dir
				Sfx.play("bk_release", z.global_position, 0.0, 0.1, 2)
			return false
		RELEASE:
			if broken:
				state = WALK
				return false
			if Engine.get_physics_frames() % 6 == 0 and Art.on_screen(z, z.global_position):
				Particles.burst(z.get_parent(), _hive_pos(), "smoke", Vector2(0, -1), 1)
			if _st <= 0.0:
				_spawn_swarm(false)
				state = WALK
				_cd = SWARM_CD
			z.velocity.x = move_toward(z.velocity.x, 0.0, 900.0 * delta)
			if not z.is_on_floor():
				z.velocity.y += z.gravity * delta
			z.move_and_slide()
			return true
	return false


# שומר מרחק כשהנחיל עובד. כוורת שבורה = מסתער
func logic(pl: Node, d: Vector2, _delta: float, speed: float) -> float:
	if broken or pl == null:
		return speed
	var dist := absf(d.x)
	if swarm != null and absf(d.y) < 80.0:
		if dist < KEEP_R.x:
			z._dir = -signf(d.x) if d.x != 0.0 else z._dir
			return speed * 0.8
		if dist < KEEP_R.y:
			z._dir = signf(d.x) if d.x != 0.0 else z._dir
			return 0.0
	return speed


func can_bite() -> bool:
	return state != RELEASE


func _spawn_swarm(angry: bool) -> void:
	releases += 1
	var s := Swarm.new()
	s.keeper = self
	s.owner_z = z
	s.angry = angry
	s.wide = wide
	s.position = _hive_pos()
	z.get_parent().add_child(s)
	if not angry or swarm == null or not is_instance_valid(swarm) or not swarm.alive():
		swarm = s
	if wide and not angry:
		z._popup("THE SWARM FLANKS", Color("ffd080"), 12, -90.0 * z.sc)


# הנחיל נתקע מאחורי מחסה -> לומד
func report_block(t: float) -> void:
	blocked_t += t
	if not wide and blocked_t >= BLOCK_LEARN:
		wide = true
		z._popup("THEY LEARN YOUR COVER", Color("ffd080"), 12, -90.0 * z.sc)
		if swarm != null and is_instance_valid(swarm):
			swarm.wide = true


func on_death() -> void:
	if swarm != null and is_instance_valid(swarm):
		swarm.orphan()


# ============================================================
#  נחיל הדבורים
# ============================================================
class Swarm extends Node2D:
	const R := 30.0
	var keeper = null
	var owner_z: Node = null
	var angry := false
	var wide := false
	var hp := SWARM_HP
	var life := SWARM_LIFE
	# לבדיקות
	var stings := 0
	var dispersed := ""
	var blocked := 0.0
	var _v := Vector2.ZERO
	var _t := 0.0
	var _sting := 0.0
	var _chk := 0.0
	var _buzz := 0.0
	var _climb := 0.0
	var _side := 0.0
	var _dying := -1.0
	var _body: StaticBody2D = null
	var _said := false

	class Cloud extends StaticBody2D:
		var s = null
		func take_damage(amount: int, hit_pos: Vector2, dir: Vector2, explosive := false, src := {}) -> void:
			if s != null:
				s.hurt_by(amount, hit_pos, dir, explosive, src)

	func _ready() -> void:
		z_index = 9
		add_to_group("blastable")
		add_to_group("swarms")
		if angry:
			hp = int(float(SWARM_HP) * 1.5)
			life = SWARM_LIFE * 1.3
		var b := Cloud.new()
		b.s = self
		b.collision_layer = 4
		b.collision_mask = 0
		var cs := CollisionShape2D.new()
		var sh := CircleShape2D.new()
		sh.radius = R * 0.8
		cs.shape = sh
		b.add_child(cs)
		add_child(b)
		_body = b
		_v = Vector2(0, -60)

	func alive() -> bool:
		return _dying < 0.0

	func blast_rect() -> Rect2:
		return Rect2(global_position - Vector2(R, R), Vector2(R, R) * 2.0)

	func hit_by_blast(_center: Vector2, _r: float) -> void:
		disperse("blast")

	func hurt_by(amount: int, hit_pos: Vector2, d: Vector2, explosive: bool, src: Dictionary) -> void:
		if not alive():
			return
		if explosive or src.get("incendiary", false) or str(src.get("source", "")) == "fire":
			disperse("fire")
			return
		var dmg := int(src.fixed) if src.has("fixed") else maxi(amount, 6)
		hp -= dmg
		Particles.burst(get_parent(), hit_pos, "spark", d, 3)
		if hp <= 0:
			disperse("shot")

	# הכוורן מת: הנחיל ממשיך עוד קצת ואז מתפזר
	func orphan() -> void:
		life = minf(life, 6.0)

	func disperse(why: String) -> void:
		if not alive():
			return
		dispersed = why
		_dying = 0.0
		if is_instance_valid(_body):
			_body.queue_free()
		remove_from_group("blastable")
		remove_from_group("swarms")
		var pl := get_tree().get_first_node_in_group("player")
		if pl != null and pl.has_method("_say") and pl.global_position.distance_to(global_position) < 500.0:
			pl._say("SMOKED OUT" if why == "smoke" else ("SWARM BURNED" if why == "fire" or why == "blast" else "SWARM DOWN"), Color("ffe080"))

	func _physics_process(delta: float) -> void:
		_t += delta
		if not alive():
			_dying += delta
			if _dying > 1.2:
				queue_free()
			queue_redraw()
			return
		life -= delta
		if life <= 0.0:
			disperse("time")
			return
		var pl := get_tree().get_first_node_in_group("player")
		# עשן / אש בסביבה = מתפזר
		_chk -= delta
		if _chk <= 0.0:
			_chk = 0.25
			if Decor.smoky(get_tree(), global_position):
				disperse("smoke")
				return
			for zz in get_tree().get_nodes_in_group("zombies"):
				if float(zz.get("_burn_t")) > 0.0 and zz.global_position.distance_to(global_position) < 90.0:
					disperse("fire")
					return
		if pl == null or pl.dead:
			_v = _v.move_toward(Vector2(0, -40), 200.0 * delta)
			global_position += _v * delta
			queue_redraw()
			return
		var tgt: Vector2 = pl.global_position + Vector2(0, -30)
		var speed := SWARM_V * (ANGRY_MULT if angry else 1.0)
		if wide and _side != 0.0 and absf(tgt.x - global_position.x) > 50.0:   # מקיף: בא מהצד השני / מלמעלה
			tgt += Vector2(_side * 70.0, -60.0)
		var want := (tgt - global_position).normalized() * speed + Vector2(sin(_t * 3.1) * 40.0, cos(_t * 2.3) * 30.0)
		if _climb > 0.0:
			_climb -= delta
			want = Vector2(want.x * 0.3, -speed)
		_v = _v.move_toward(want, 500.0 * delta)
		var step := _v * delta
		# מחסה עוצר את הדבורים (לא עוברות דרך קירות / חבילות)
		var space := get_world_2d().direct_space_state
		var hx := space.intersect_ray(PhysicsRayQueryParameters2D.create(global_position, global_position + Vector2(step.x + signf(step.x) * 8.0, 0), 1))
		if not hx.is_empty():
			step.x = 0.0
			_v.x *= -0.2
			blocked += delta
			if keeper != null and owner_z != null and is_instance_valid(owner_z) and not owner_z.dead:
				keeper.report_block(delta)
			if wide:   # למדו: עולים מעל המחסה ובאים מהצד השני
				_climb = 0.6
				_side = signf(pl.global_position.x - global_position.x)
		var hy := space.intersect_ray(PhysicsRayQueryParameters2D.create(global_position, global_position + Vector2(0, step.y + signf(step.y) * 8.0), 1))
		if not hy.is_empty():
			step.y = 0.0
			_v.y = 0.0
		global_position += step
		# עקיצות
		_sting -= delta
		if _sting <= 0.0 and pl.body_rect().grow(R * 0.5).has_point(global_position):
			_sting = STING_T * (0.75 if angry else 1.0)
			if pl._roll_t <= 0.0 and not pl.god_mode():
				stings += 1
				pl.hurt(STING_DMG, Vector2(signf(_v.x) * 0.3, 0.0))
				if not _said:
					_said = true
					pl._say("STUNG!  FIND SMOKE", Color("ffd040"))
		_buzz -= delta
		if _buzz <= 0.0:
			_buzz = 0.7
			if Art.on_screen(self, global_position):
				Sfx.play("bk_buzz", global_position, -6.0 if not angry else -2.0, 0.1, 3, 1.2 if angry else 1.0)
		if Art.on_screen(self, global_position):
			queue_redraw()

	func _draw() -> void:
		var a := 1.0 if alive() else maxf(0.0, 1.0 - _dying / 1.2)
		var spread := 1.0 if alive() else 1.0 + _dying * 3.0
		var n := int((22.0 if not angry else 30.0) * clampf(float(hp) / float(SWARM_HP), 0.35, 1.5))
		DrawBatch.circle(self, Vector2.ZERO, R * 0.9 * spread, Color(0.15, 0.12, 0.05, 0.12 * a))
		for i in n:
			var ph := _t * (4.0 + float(i % 5)) + float(i) * 2.39
			var rr := R * (0.25 + 0.75 * fposmod(float(i) * 0.618, 1.0)) * spread
			var p := Vector2(cos(ph) * rr, sin(ph * 1.3) * rr * 0.7)
			var body := Color(0.12, 0.09, 0.03, a) if i % 3 != 0 else Color(0.85, 0.65, 0.1, a)
			DrawBatch.circle(self, p, 1.6, body)
			if i % 2 == 0:   # כנפיים מהבהבות
				var w := 2.2 if int(_t * 30.0 + float(i)) % 2 == 0 else 1.2
				DrawBatch.line(self, p + Vector2(-w, -1.5), p + Vector2(w, -1.5), Color(1, 1, 1, 0.55 * a), 1.0)
		if angry and alive():
			DrawBatch.arc(self, Vector2.ZERO, R * 0.95, 0, TAU, 20, Color(1.0, 0.4, 0.1, 0.25), 1.5)


# ---- שלולית דבש: דביקה, מאטה ----
class HoneyPuddle extends Node2D:
	const W := 110.0
	var _t := 0.0

	func _ready() -> void:
		z_index = 2

	func _physics_process(delta: float) -> void:
		_t += delta
		if _t > HONEY_T:
			modulate.a = maxf(0.0, 1.0 - (_t - HONEY_T))
			if _t > HONEY_T + 1.0:
				queue_free()
				return
		if Engine.get_physics_frames() % 4 == 0:
			var pl := get_tree().get_first_node_in_group("player")
			if pl != null and pl.is_on_floor() and absf(pl.global_position.x - global_position.x) < W * 0.5 and absf(pl.global_position.y - global_position.y) < 10.0:
				pl.slow_t = maxf(pl.slow_t, 0.3)
		if Engine.get_physics_frames() % 10 == 0 and Art.on_screen(self, global_position):
			queue_redraw()

	func _draw() -> void:
		var k := minf(1.0, _t * 3.0)
		var w := W * 0.5 * k
		DrawBatch.colored_polygon(self, Art.ellipse(Vector2(0, -1), w, 4.0, 0.0, 16), Color(0.85, 0.55, 0.08, 0.85))
		DrawBatch.colored_polygon(self, Art.ellipse(Vector2(-w * 0.3, -2), w * 0.4, 1.6, 0.0, 10), Color(1.0, 0.85, 0.4, 0.7))
		for q in 3:
			DrawBatch.circle(self, Vector2(-w * 0.6 + float(q) * w * 0.55, -1.5), 2.0, Color(1.0, 0.8, 0.3, 0.6))


# ============================================================
#  ציור: גב שפוף מתחת לכוורת ענקית, חליפת כוורן מוכתמת, כובע רחב עם רשת שמשתלשלת, חלות בחזה, דבורים זוחלות.
#  RELEASE = המכסה של הכוורת נפתח ודבורים נשפכות. כוורת שבורה = קרשים שבורים ודבש נוטף.
# ============================================================
func draw() -> bool:
	begin_draw()
	var sk := col(z.skin)
	var suit := col(z.shirt)
	var p: float = z._walk_phase
	var f: Array = feet(4.5, 2.0)
	var hip := Vector2(0, -23)
	var sh := Vector2(5, -39)
	z._leg(hip + Vector2(-3, 0), f[1], col(Art.shade(z.pants, 0.25)), sk, col(z.shoe))
	z._leg(hip + Vector2(3, 0), f[0], col(z.pants), sk, col(z.shoe))
	var back_h: Vector2 = sh + Vector2(-4.0 + sin(p) * 4.0, 17.0)
	z._arm(sh + Vector2(-2, 2), back_h, col(Art.shade(z.skin, 0.25)), col(Art.shade(z.shirt, 0.25)))
	# הכוורת על הגב (מאחורי הגוף)
	_hive(Vector2(-13, -26))
	# גוף בחליפה עם חלות דבש בחזה
	var body := PackedVector2Array([sh + Vector2(-8, -1), sh + Vector2(8, 1), hip + Vector2(8, -2), hip + Vector2(6, 3), hip + Vector2(-6, 3), hip + Vector2(-9, -2)])
	Art.fill_shaded(z, body, suit, 0.15, 0.35)
	DrawBatch.line(z, sh + Vector2(1, 2), hip + Vector2(1, -3), col(Color("8a8270")), 1.0)   # רוכסן
	var comb := sh + Vector2(3, 8)
	for q in 5:   # חלות משושות שפורצות מהחזה
		var c := comb + Vector2(float(q % 3) * 3.6 - 2.0, float(q / 3) * 3.4 + float(q % 2) * 1.7)
		DrawBatch.colored_polygon(z, _hex(c, 2.0), col(Color("c88a20")))
		DrawBatch.circle(z, c, 0.8, Color(0.3, 0.18, 0.02))
	DrawBatch.line(z, sh + Vector2(-6, 10), sh + Vector2(-2, 14), Color(0.3, 0.2, 0.1, 0.5), 1.0)   # כתמים
	DrawBatch.rect(z, Rect2(hip + Vector2(-8, -5), Vector2(16, 3)), col(Color("6a5a40")))   # חגורה
	# ראש בכובע כוורן עם רשת
	var head: Vector2 = sh + Vector2(4.0, -8.0)
	z._head(head, sk)
	var hat := col(Color("e2dcc8"))
	Art.fill(z, PackedVector2Array([head + Vector2(-13, -4), head + Vector2(13, -5), head + Vector2(12, -7), head + Vector2(-12, -6)]), hat, Art.OUTLINE, 1.0)
	Art.fill(z, PackedVector2Array([head + Vector2(-6, -6), head + Vector2(6, -6.5), head + Vector2(4, -13), head + Vector2(-4, -13)]), hat, Art.OUTLINE, 1.0)
	var veil := PackedVector2Array([head + Vector2(-12, -5), head + Vector2(12, -6), head + Vector2(10, 8), head + Vector2(5, 6), head + Vector2(0, 9), head + Vector2(-5, 6), head + Vector2(-11, 8)])
	DrawBatch.colored_polygon(z, veil, Color(0.1, 0.1, 0.08, 0.35))   # רשת שקופה קרועה
	for q in 5:
		DrawBatch.line(z, head + Vector2(-10.0 + float(q) * 5.0, -5.0), head + Vector2(-10.0 + float(q) * 5.0, 7.0), Color(0.1, 0.1, 0.08, 0.35), 0.6)
	if not z.dead:
		DrawBatch.circle(z, head + Vector2(4.0, -1.0), 1.0, Color(1.0, 0.8, 0.2))
	# יד קדמית: מושטת, דבורים עליה
	var front_h: Vector2 = sh + Vector2(15.0, 5.0 + sin(z._time * 2.0) * 1.5)
	if state == RELEASE:
		front_h = sh + Vector2(6, -12)   # מצביע עליך / משחרר
	z._arm(sh + Vector2(2, 2), front_h, sk, suit)
	if not z.dead and Art.on_screen(z, z.global_position):   # דבורים זוחלות
		for q in 5:
			var a: float = z._time * (1.5 + float(q) * 0.3) + float(q) * 1.9
			var bp: Vector2 = sh + Vector2(-2.0 + cos(a) * 8.0, 10.0 + sin(a * 1.2) * 8.0)
			DrawBatch.circle(z, bp, 0.9, Color(0.12, 0.09, 0.03))
	end_draw()
	return true


func _hex(c: Vector2, r: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in 6:
		pts.append(c + Vector2.from_angle(float(i) * TAU / 6.0) * r)
	return pts


# תיבת כוורת (שתי קומות) קשורה לגב. (c = מרכז התחתית של התיבה)
func _hive(c: Vector2) -> void:
	const K := 1.4
	var wood := col(Color("ece4c8"))
	var wood2 := col(Color("e0b040"))
	if broken:   # שבורה: קרשים קרועים ודבש נוטף
		Art.fill(z, PackedVector2Array([c + K * Vector2(-9, 6), c + K * Vector2(9, 6), c + K * Vector2(10, -4), c + K * Vector2(4, -10), c + K * Vector2(0, -5), c + K * Vector2(-5, -12), c + K * Vector2(-10, -3)]), wood)
		for q in 3:
			var dx := -5.0 + float(q) * 5.0
			var drip := 4.0 + fmod(z._time * 3.0 + float(q), 6.0)
			DrawBatch.line(z, c + K * Vector2(dx, 4), c + K * Vector2(dx, 4.0 + drip), Color(0.9, 0.6, 0.1, 0.9), 1.6)
		DrawBatch.line(z, c + K * Vector2(-8, -2), c + K * Vector2(-14, -16), col(Color("a89a7a")), 1.6)   # קרש עף
		return
	var open := state == RELEASE
	Art.fill_shaded(z, PackedVector2Array([c + K * Vector2(-10, 8), c + K * Vector2(10, 8), c + K * Vector2(10, -6), c + K * Vector2(-10, -6)]), wood, 0.1, 0.3)
	Art.fill_shaded(z, PackedVector2Array([c + K * Vector2(-10, -6), c + K * Vector2(10, -6), c + K * Vector2(10, -20), c + K * Vector2(-10, -20)]), wood2, 0.1, 0.3)
	DrawBatch.line(z, c + K * Vector2(-10, 1), c + K * Vector2(10, 1), Color(0.3, 0.25, 0.15, 0.5), 1.0)
	DrawBatch.rect(z, Rect2(c + K * Vector2(-4, 5), Vector2(8, 2)), Color(0.1, 0.06, 0.02))   # פתח
	# חלות שבולטות מהצד
	for q in 3:
		DrawBatch.colored_polygon(z, _hex(c + K * Vector2(-11.0, -2.0 - float(q) * 4.0), 3.0), col(Color("d89a28")))
	# מכסה (נפתח ב-RELEASE)
	var lid := c + K * Vector2(-11, -20)
	var ang := -0.9 - sin(z._time * 30.0) * 0.1 if open else 0.0
	DrawBatch.line(z, lid, lid + Vector2.from_angle(ang) * 23.0, col(Color("6a6250")), 3.0)
	DrawBatch.line(z, c + K * Vector2(-2, -18), c + K * Vector2(14, -10), col(Color("4a3a24")), 1.4)   # רצועות
	DrawBatch.line(z, c + K * Vector2(-2, 6), c + K * Vector2(14, 0), col(Color("4a3a24")), 1.4)
	if open:
		for q in 8:
			var k := fmod(z._time * 2.0 + float(q) * 0.125, 1.0)
			DrawBatch.circle(z, c + K * Vector2(-2.0 + sin(float(q) * 2.0) * 6.0 * k, -20.0 - k * 18.0), 1.0, Color(0.12, 0.09, 0.03))
