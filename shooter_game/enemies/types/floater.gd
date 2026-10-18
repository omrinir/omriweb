extends "res://enemies/zombie_type.gd"
# ============================================================
#  FLOATER (שלב 49, "RIVER DELTA") - גופה של טובע שצפה בנהר שבועות: נפוחה מגז נהר, עור אפור-כחלחל עם ורידים סגולים,
#    חולצה קרועה שלא נסגרת על הבטן, אצות תלויות מהידיים. איטי וחזק. (השראה: ה-Bloater מ-The Last of Us, ו"פלוטרים" -
#    כינוי של צוללני משטרה לגופות שצפות.)
#  * כל פגיעה בבטן מנפחת אותו (SWELL_PER). בטן מלאה (swell >= 1) או מוות = מתפוצץ לענן גז רעיל (GasCloud):
#    בתוך הענן נפגעים כולם - אתה (נזק + סחרחורת) וגם זומבים אחרים (GAS_DMG_Z). פלוטרים חסינים לגז.
#  * הוא הולך לאמצע המקום שלך, וכשהוא צמוד אליך (SELF_R) - "מתנפח" (SELF_T, אזהרה: זוהר ירוק + גרגור) ומפוצץ את עצמו.
#  * בגאות (TideDirector, main meta "tide") הוא צף: מהיר פי TIDE_SPEED.
#  "THEY LEARN WHERE TO WALK - TOGETHER": פוצצת פלוטר מרחוק (יותר מ-FAR_D)? נספר (main meta "floater_far").
#    אחרי HIDE_LEARN כאלה - כל הפלוטרים הולכים מאחורי זומבים אחרים ("THEY HIDE BEHIND THE OTHERS"), כך שקשה לפוצץ אותם מוקדם.
#  בוס (chase_range > 600): "THE RIVER MOTHER" - ענקית, לא מתנפחת אלא נפגעת חזק יותר בבטן (BELLY_MULT).
#    יורקת בועות גז בקשת (GasBubble, SPIT_CD), מגהקת פלוטרים קטנים (BELCH_CD, עד BELCH_MAX), ומתחת לחצי חיים - גל גז
#    מסביבה (WAVE_CD, אזהרה WAVE_WARN). במוות - ענן ענק.
#  צלילים: "ft_gurgle" (גרגור), "ft_pop" (פיצוץ), "ft_spit" (יריקה), "ft_belch" (גיהוק).
#  לשנות: SWELL_PER, SELF_R, SELF_T, GAS_R, GAS_T, GAS_DMG_Z, FAR_D, HIDE_LEARN, TIDE_SPEED, SPIT_CD, BELCH_CD, WAVE_CD.
# ============================================================

const SOUNDS := {
	"ft_gurgle": [["S", 90, 60, 0.0, 0.8, 0.05, 3.0, 0.35, 1.0, 0.25], ["N", 0, 0, 0.0, 0.7, 0.1, 4.0, 0.2, 0.25, 0, 0.5]],
	"ft_pop": [["N", 0, 0, 0.0, 0.6, 0.0, 6.0, 0.9, 0.35, 0, 0.8], ["S", 120, 40, 0.0, 0.35, 0.0, 9.0, 0.7, 1.0, 0.05], ["C", 0, 0, 0.0, 0.05, 0.0, 30.0, 0.5, 1.0, 0]],
	"ft_spit": [["N", 0, 0, 0.0, 0.25, 0.0, 10.0, 0.4, 0.5, 0, 0.6], ["S", 300, 120, 0.0, 0.2, 0.0, 12.0, 0.3, 1.0, 0.1]],
	"ft_belch": [["S", 80, 55, 0.0, 0.9, 0.05, 2.5, 0.5, 1.0, 0.3], ["N", 0, 0, 0.0, 0.8, 0.05, 3.0, 0.3, 0.3, 0, 0.5]],
}

const SWELL_PER := 0.22       # כמה כל פגיעה בבטן מנפחת (5 פגיעות = פיצוץ)
const SELF_R := 66.0
const SELF_T := 0.9
const GAS_R := 105.0
const GAS_T := 4.0
const GAS_DMG_Z := 6
const FAR_D := 330.0
const HIDE_LEARN := 2
const HIDE_LOOK := 0.4
const TIDE_SPEED := 1.6
const BELLY_MULT := 1.35      # (בוס)
const SPIT_CD := Vector2(2.2, 3.2)
const BELCH_CD := 9.0
const BELCH_MAX := 3
const WAVE_CD := 7.0
const WAVE_WARN := 1.1
const WAVE_R := 175.0

enum { WALK, SWELL, WAVE }
var state := WALK
var swell := 0.0              # 0..1 - כמה הבטן מלאה
var pops := 0                 # לבדיקות
var self_pops := 0
var hiding := false
var spits := 0
var belches := 0
var waves := 0
var _st := 0.0
var _look := 0.0
var _tx := INF
var _spit_cd := 2.0
var _belch_cd := 6.0
var _wave_cd := 3.0
var _kids := []
var _popped := false
var _gurgle := 0.0
var _belly_hit := false


func _boss() -> bool:
	return z != null and float(z.chase_range) > 600.0


func stats() -> Dictionary:
	if _boss():
		return {"name": "FLOATER", "hp": 320, "walk": 26.0, "chase": 42.0, "damage": 2, "bite_delay": 1.2, "scale": 2.05, "width": 1.5,
			"duck": 0.0, "cover": 0.0, "skin": Color("80947e"), "shirt": Color("3e4c4c"), "pants": Color("3a3e44"), "shoe": Color("3a3a3a"),
			"points": 1700, "boss": true, "boss_name": "THE RIVER MOTHER", "ragdoll": false}
	return {"name": "FLOATER", "hp": 70, "walk": 28.0, "chase": 50.0, "damage": 1, "bite_delay": 1.0, "scale": 1.25, "width": 1.5,
		"duck": 0.0, "cover": 0.0, "skin": Color("8a9c88"), "shirt": Color("4a5866"), "pants": Color("33383e"), "shoe": Color("2a2a2a"), "points": 480, "ragdoll": false}


func brain_overrides() -> Dictionary:
	return {"aggression": 0.6, "flank_probability": -0.3}


static func learned(main: Node) -> bool:
	return main.has_meta("floater_far") and int(main.get_meta("floater_far")) >= HIDE_LEARN


func _belly(hit_pos: Vector2) -> bool:
	var ly: float = (hit_pos.y - z.global_position.y) / z.sc
	return ly > -40.0 and ly < -10.0


func on_damage(_amount: int, hit_pos: Vector2, _dir: Vector2, src: Dictionary) -> bool:
	var s := str(src.get("source", "bullet"))
	_belly_hit = (s == "bullet" or s == "melee") and _belly(hit_pos)
	if z.dead or _boss():
		return true
	if (s == "bullet" or s == "melee") and _belly(hit_pos):
		swell += SWELL_PER
		Sfx.play("ft_gurgle", hit_pos, -6.0, 0.15, 2)
		if swell >= 1.0:
			_pop.call_deferred(true)
	return true


# בוס: הבטן היא נקודת התורפה (on_damage שומר איפה הפגיעה)
func damage_mult(_zone: String, _src: Dictionary) -> float:
	return BELLY_MULT if _boss() and _belly_hit else 1.0


func logic(pl: Node, d: Vector2, delta: float, speed: float) -> float:
	_st -= delta
	_look -= delta
	_gurgle -= delta
	if pl == null or pl.dead:
		return speed
	var main: Node = z.get_parent()
	var tide := float(main.get_meta("tide")) if main.has_meta("tide") else 0.0
	if tide > 0.5:
		speed *= TIDE_SPEED
	if _gurgle <= 0.0:
		_gurgle = randf_range(3.0, 6.0)
		if Art.on_screen(z, z.global_position):
			Sfx.play("ft_gurgle", z.global_position, -14.0, 0.2, 2)
	if _boss():
		return _boss_logic(pl, d, delta, speed)
	match state:
		WALK:
			if absf(d.x) < SELF_R * z.sc * 0.8 and absf(d.y) < 50.0 and z.is_on_floor():
				state = SWELL
				_st = SELF_T
				z._popup("!", Color("b0e070"), 18, -80.0 * z.sc)
				Sfx.play("ft_gurgle", z.global_position, 0.0, 0.1, 2)
				return 0.0
			if learned(main) and absf(d.x) > 200.0:
				if _look <= 0.0:
					_look = HIDE_LOOK
					_tx = _shield_x(pl)
					if _tx < INF and not hiding:
						hiding = true
						if not main.has_meta("floater_hide_said"):
							main.set_meta("floater_hide_said", true)
							z._popup("THEY HIDE BEHIND THE OTHERS", Color("b0e070"), 14, -90.0 * z.sc)
				if _tx < INF:
					var dx: float = _tx - z.global_position.x
					if absf(dx) < 10.0:
						z._dir = signf(d.x) if d.x != 0.0 else z._dir
						return 0.0
					z._dir = signf(dx)
					return float(z.chase_speed) * (TIDE_SPEED if tide > 0.5 else 1.0)
			else:
				hiding = false
				_tx = INF
			return speed
		SWELL:
			swell = minf(swell + delta / SELF_T * 0.6, 1.0)
			if _st <= 0.0:
				self_pops += 1
				_pop(false)
			return 0.0
	return speed


# איפה לעמוד: מאחורי הזומבי (לא פלוטר) הקרוב שנמצא בינו לבין השחקן
func _shield_x(pl: Node) -> float:
	var best := INF
	var bd := INF
	var px: float = pl.global_position.x
	for o in z.get_tree().get_nodes_in_group("zombies"):
		if o == z or o.dead or o.is_boss() or o.kind == z.kind:
			continue
		if absf(o.global_position.y - z.global_position.y) > 40.0:
			continue
		var dz: float = absf(o.global_position.x - z.global_position.x)
		if dz > 260.0 or absf(o.global_position.x - px) >= absf(z.global_position.x - px) + 20.0:
			continue
		if dz < bd:
			bd = dz
			best = o.global_position.x - signf(px - o.global_position.x) * 34.0 * z.sc
	return best


func _boss_logic(pl: Node, d: Vector2, delta: float, speed: float) -> float:
	_spit_cd -= delta
	_belch_cd -= delta
	_wave_cd -= delta
	if state == WAVE:
		if _st <= 0.0:
			state = WALK
			waves += 1
			_wave_cd = WAVE_CD
			_gas(z.global_position + Vector2(0, -20), WAVE_R, GAS_T * 0.8)
			Sfx.play("ft_pop", z.global_position, 4.0, 0.1, 2)
			var cam: Node = z.get_viewport().get_camera_2d()
			if cam != null and cam.has_method("shake"):
				cam.shake(8.0, 0.3)
		return 0.0
	if absf(d.x) > 760.0:
		return speed
	if float(z.hp) < float(z.max_hp) * 0.5 and _wave_cd <= 0.0:
		state = WAVE
		_st = WAVE_WARN
		z._popup("GAS WAVE!", Color("b0e070"), 16, -60.0 * z.sc)
		Sfx.play("ft_gurgle", z.global_position, 4.0, 0.1, 2)
		return 0.0
	if _belch_cd <= 0.0:
		_belch_cd = BELCH_CD
		_belch(pl)
	elif _spit_cd <= 0.0:
		_spit_cd = randf_range(SPIT_CD.x, SPIT_CD.y) * (0.75 if float(z.hp) < float(z.max_hp) * 0.5 else 1.0)
		_spit(pl)
	return speed


func _mouth() -> Vector2:
	return z.global_position + Vector2(z._dir * 7.0, -50.0) * z.sc


func _spit(pl: Node) -> void:
	spits += 1
	var from := _mouth()
	var target: Vector2 = pl.global_position + Vector2(clampf(float(pl.velocity.x) * 0.5, -120.0, 120.0), -10.0)
	var b := GasBubble.new()
	var ft := clampf(absf(target.x - from.x) / 420.0, 0.6, 1.3)
	b.velocity = Vector2((target.x - from.x) / ft, (target.y - from.y - 0.5 * b.gravity * ft * ft) / ft)
	z.get_parent().add_child(b)
	b.global_position = from
	Sfx.play("ft_spit", from, 0.0, 0.1, 2)


func _belch(pl: Node) -> void:
	var alive := 0
	for k in _kids:
		if is_instance_valid(k) and not k.dead:
			alive += 1
	if alive >= BELCH_MAX:
		return
	var main: Node = z.get_parent()
	if not main.has_method("_spawn_zombie"):
		return
	var dir: float = signf(pl.global_position.x - z.global_position.x) if pl.global_position.x != z.global_position.x else z._dir
	var k = main._spawn_zombie(z.global_position.x + dir * 40.0 * z.sc, z.global_position.y, z.kind)
	if k == null:
		return
	k.set_meta("revived", true)   # לא יקום שוב / לא גבעול
	k._dir = dir
	k.velocity = Vector2(dir * 260.0, -320.0)
	k._alert_t = 8.0
	_kids.append(k)
	belches += 1
	Sfx.play("ft_belch", z.global_position, 4.0, 0.1, 2)
	z._popup("BLOOOARGH", Color("b0e070"), 14, -60.0 * z.sc)
	Particles.burst(main, _mouth(), "smoke", Vector2(dir, -0.3), 8)


func _pop(by_player: bool) -> void:
	if _popped:
		return
	_popped = true
	pops += 1
	if by_player and not _boss():
		var pl := player()
		if pl != null and pl.global_position.distance_to(z.global_position) > FAR_D:
			var main: Node = z.get_parent()
			main.set_meta("floater_far", int(main.get_meta("floater_far")) + 1 if main.has_meta("floater_far") else 1)
	if not z.dead:
		z.hp = 0
		z._die(Vector2(z._dir * -0.3, -0.4))


func on_death() -> void:
	if not _popped:
		_popped = true
		pops += 1
		var pl := player()
		if not _boss() and pl != null and pl.global_position.distance_to(z.global_position) > FAR_D:
			var main: Node = z.get_parent()
			main.set_meta("floater_far", int(main.get_meta("floater_far")) + 1 if main.has_meta("floater_far") else 1)
	swell = 1.0
	Sfx.play("ft_pop", z.global_position, 3.0 if _boss() else 0.0, 0.1, 2)
	Particles.burst(z.get_parent(), z.global_position + Vector2(0, -28.0 * z.sc), "hit", Vector2.UP, 16)
	_gas(z.global_position + Vector2(0, -18.0 * z.sc), GAS_R * (2.1 if _boss() else 1.0), GAS_T * (1.5 if _boss() else 1.0))
	var cam: Node = z.get_viewport().get_camera_2d()
	if cam != null and cam.has_method("shake") and Art.on_screen(z, z.global_position):
		cam.shake(5.0 if not _boss() else 12.0, 0.25)


func _gas(at: Vector2, r: float, life: float) -> void:
	var g := GasCloud.new()
	g.r = r
	g.life = life
	g.immune_kind = z.kind
	z.get_parent().add_child.call_deferred(g)
	g.position = at


# ============================================================
#  ענן גז רעיל: נשאר life שניות. שחקן בתוכו = נזק + סחרחורת (פעם ב-TICK), זומבים (לא פלוטרים) = GAS_DMG_Z.
# ============================================================
class GasCloud extends Node2D:
	const TICK := 0.8
	static var player_hits := 0     # לבדיקות
	static var zombie_hits := 0
	var r := 105.0
	var life := 4.0
	var immune_kind := -1
	var _t := 0.0
	var _tick := 0.15
	var _seed := 0.0

	func _ready() -> void:
		z_index = 8
		_seed = randf() * 10.0
		add_to_group("hazards")

	func world_rect() -> Rect2:
		return Rect2(global_position - Vector2(r, r * 0.8), Vector2(r * 2.0, r * 1.3))

	func danger_at(p: Vector2, margin := 0.0) -> bool:
		return world_rect().grow(margin).has_point(p)

	func _inside(p: Vector2) -> bool:
		var q := (p - global_position)
		return (q.x * q.x) / (r * r) + (q.y * q.y) / (r * r * 0.6) < 1.0

	func _physics_process(delta: float) -> void:
		_t += delta
		_tick -= delta
		if _tick <= 0.0 and _t < life - 0.4:
			_tick = TICK
			var pl := get_tree().get_first_node_in_group("player")
			if pl != null and not pl.dead and _inside(pl.global_position + Vector2(0, -26)):
				player_hits += 1
				pl.hurt(1, Vector2(signf(pl.global_position.x - global_position.x + 0.01) * 0.6, -0.3))
				pl.daze(0.7, "TOXIC GAS")
			for zz in get_tree().get_nodes_in_group("zombies"):
				if zz.dead or zz.is_boss() or zz.kind == immune_kind or not _inside(zz.global_position + Vector2(0, -20)):
					continue
				zombie_hits += 1
				zz.take_damage(6, zz.global_position + Vector2(0, -24), Vector2.UP, true, {"source": "hazard", "fixed": 6})
		if _t >= life:
			queue_free()
			return
		if Art.on_screen(self, global_position, r + 40.0) and Engine.get_physics_frames() % 2 == 0:
			queue_redraw()

	func _draw() -> void:
		DrawBatch.begin(self)
		_draw_b()
		DrawBatch.end(self)

	func _draw_b() -> void:
		var k := _t / life
		var grow := minf(_t * 3.0, 1.0)
		var a := (1.0 - k) * minf(_t * 4.0, 1.0)
		for q in 13:
			var ang := float(q) * 2.4 + _seed
			var rr := r * (0.15 + 0.6 * fposmod(float(q) * 0.37, 1.0)) * grow
			var p := Vector2(cos(ang + _t * 0.4), sin(ang + _t * 0.3) * 0.55) * rr + Vector2(0, -_t * 4.0)
			var sz := r * (0.32 + 0.12 * float(q % 3)) * grow
			DrawBatch.circle(self, p, sz, Color(0.55, 0.68, 0.22, 0.2 * a))
			DrawBatch.circle(self, p + Vector2(sz * 0.2, -sz * 0.2), sz * 0.55, Color(0.72, 0.8, 0.3, 0.16 * a))
		for q in 6:   # בועות קטנות
			var bp := Vector2(sin(float(q) * 3.1 + _t * 1.5) * r * 0.6, -fposmod(_t * 30.0 + float(q) * 17.0, r * 0.9) + r * 0.3)
			DrawBatch.arc(self, bp, 2.5 + float(q % 2), 0.0, TAU, 8, Color(0.85, 0.95, 0.5, 0.5 * a), 1.0)


# ============================================================
#  בועת גז (בוס): עפה בקשת, ונוחתת לענן קטן. פוגעת ישר בשחקן = נזק + ענן.
# ============================================================
class GasBubble extends Node2D:
	static var hits := 0            # לבדיקות
	var velocity := Vector2.ZERO
	var gravity := 760.0
	var _t := 0.0
	var _done := false

	func _ready() -> void:
		z_index = 9

	func _physics_process(delta: float) -> void:
		_t += delta
		velocity.y += gravity * delta
		var to := global_position + velocity * delta
		var pl := get_tree().get_first_node_in_group("player")
		if pl != null and not pl.dead and pl.body_rect().grow(8.0).has_point(to):
			hits += 1
			pl.hurt(1, Vector2(signf(velocity.x) * 1.0, -0.4))
			_burst(to)
			return
		var hit := get_world_2d().direct_space_state.intersect_ray(PhysicsRayQueryParameters2D.create(global_position, to, 1))
		if not hit.is_empty() or _t > 3.0:
			_burst(hit.position if not hit.is_empty() else to)
			return
		global_position = to
		queue_redraw()

	func _burst(at: Vector2) -> void:
		if _done:
			return
		_done = true
		preload("res://sfx.gd").play("ft_pop", at, -4.0, 0.15, 2)
		var g := GasCloud.new()
		g.r = 70.0
		g.life = 2.6
		g.immune_kind = preload("res://enemies/zombie_registry.gd").FLOATER
		get_parent().add_child.call_deferred(g)
		g.position = at + Vector2(0, -10)
		queue_free()

	func _draw() -> void:
		DrawBatch.begin(self)
		_draw_b()
		DrawBatch.end(self)

	func _draw_b() -> void:
		var w := 1.0 + sin(_t * 18.0) * 0.08
		DrawBatch.colored_polygon(self, preload("res://art.gd").ellipse(Vector2.ZERO, 11.0 * w, 11.0 / w, 0.0, 14), Color(0.6, 0.75, 0.25, 0.55))
		DrawBatch.arc(self, Vector2.ZERO, 11.0, 0.0, TAU, 14, Color(0.85, 0.95, 0.5, 0.8), 1.5)
		DrawBatch.circle(self, Vector2(-4, -4), 3.0, Color(1, 1, 1, 0.6))
		DrawBatch.line(self, Vector2.ZERO, -velocity.normalized() * 22.0, Color(0.6, 0.75, 0.25, 0.3), 6.0)


# ============================================================
#  ציור: בטן ענקית ונפוחה, ראש קטן ששקוע בכתפיים, רגליים עבות וקצרות, עור של טובע + ורידים סגולים, אצות תלויות.
# ============================================================
func draw() -> bool:
	begin_draw()
	var sk := col(z.skin)
	var shirt := col(z.shirt)
	var t: float = z._time
	var p: float = z._walk_phase
	if z.dead:   # עור מרוקן ושטוח
		DrawBatch.colored_polygon(z, Art.ellipse(Vector2(0, -6), 20.0, 6.0, 0.0, 16), Art.shade(sk, 0.2))
		DrawBatch.colored_polygon(z, Art.ellipse(Vector2(-4, -9), 12.0, 3.0, 0.1, 12), shirt)
		Art.oval_shaded(z, Vector2(18, -8), 5.0, 4.5, sk, 0.0)
		for q in 3:
			DrawBatch.line(z, Vector2(-14.0 + float(q) * 10.0, -10.0), Vector2(-12.0 + float(q) * 9.0, -2.0), col(Color(0.35, 0.2, 0.35, 0.6)), 1.0)
		end_draw()
		return true
	var big := _boss()
	var bob := sin(p * 0.5) * 0.8
	var sw := clampf(swell, 0.0, 1.0)
	var pulse := (sin(t * 22.0) * 0.5 + 0.5) if state == SWELL or state == WAVE else 0.0
	var brx := 14.0 + sw * 4.5 + pulse * 1.5
	var bry := 15.0 + sw * 4.0 + pulse * 1.2
	var bc := Vector2(2.0, -27.0 + bob)
	var hip := Vector2(0, -13)
	var f: Array = feet(3.5, 2.0)
	# רגליים עבות וקצרות
	Art.limb(z, PackedVector2Array([hip + Vector2(-5, 0), f[1] + Vector2(-2, -3)]), 7.0, col(Art.shade(z.pants, 0.2)))
	Art.limb(z, PackedVector2Array([hip + Vector2(5, 0), f[0] + Vector2(2, -3)]), 7.0, col(z.pants))
	for ft in [f[1] + Vector2(-2, 0), f[0] + Vector2(2, 0)]:   # כפות יחפות ונפוחות
		Art.oval(z, ft + Vector2(1, -2), 4.5, 2.6, Art.shade(sk, 0.1))
	# יד אחורית
	var sh := Vector2(1.0, -43.0 + bob)
	var hb := Vector2(-brx - 1.0, -24.0 + bob + sin(p) * 1.5)
	Art.limb(z, PackedVector2Array([sh + Vector2(-6, 1), Vector2(-brx * 0.8, -36.0 + bob), hb]), 5.5, Art.shade(sk, 0.2))
	# הבטן
	if state == SWELL or state == WAVE or sw > 0.6:
		Art.glow(z, bc, brx * 1.8, Color(0.6, 0.85, 0.2, 0.18 + 0.2 * pulse))
	Art.oval_shaded(z, bc, brx, bry, sk, 0.0)
	DrawBatch.colored_polygon(z, Art.ellipse(bc + Vector2(-4, 5), brx * 0.55, bry * 0.4, 0.3, 12), col(Color(0.45, 0.5, 0.55, 0.35)))   # כתמים כחלחלים
	DrawBatch.colored_polygon(z, Art.ellipse(bc + Vector2(0, bry * 0.55), brx * 0.85, bry * 0.4, 0.0, 14), col(Color(0.25, 0.3, 0.22, 0.35)))   # תחתית כהה
	DrawBatch.colored_polygon(z, Art.ellipse(bc + Vector2(brx * 0.35, -bry * 0.1), brx * 0.25, bry * 0.18, 0.5, 10), col(Color(0.5, 0.42, 0.2, 0.4)))   # כתם ריקבון
	for q in 5:   # ורידים סגולים
		var a0 := -2.2 + float(q) * 0.9
		var v0 := bc + Vector2.from_angle(a0) * brx * 0.35
		var v1 := bc + Vector2.from_angle(a0 + 0.35) * brx * 0.85
		DrawBatch.polyline(z, PackedVector2Array([v0, v0.lerp(v1, 0.5) + Vector2(1.5, -1), v1]), col(Color(0.38, 0.22, 0.42, 0.7)), 1.0)
	DrawBatch.circle(z, bc + Vector2(3, 4), 1.4, col(Color(0.3, 0.25, 0.3)))   # טבור
	if sw > 0.4:   # עור מתוח - סדקים
		for q in int(sw * 4.0):
			var cp := bc + Vector2(-6.0 + float(q) * 5.0, -6.0 + float(q % 2) * 8.0)
			DrawBatch.line(z, cp, cp + Vector2(3, 2), col(Color(0.5, 0.15, 0.2, 0.8)), 1.0)
	# חולצה קרועה שלא נסגרת
	Art.fill(z, PackedVector2Array([sh + Vector2(-9, -1), sh + Vector2(-2, 0), bc + Vector2(-brx * 0.55, -bry * 0.2), bc + Vector2(-brx * 0.9, bry * 0.1), sh + Vector2(-11, 8)]), shirt, Art.OUTLINE, 0.9)
	Art.fill(z, PackedVector2Array([sh + Vector2(4, 0), sh + Vector2(10, 1), bc + Vector2(brx * 0.92, -bry * 0.25), bc + Vector2(brx * 0.6, -bry * 0.5)]), shirt, Art.OUTLINE, 0.9)
	# ראש קטן ששקוע בכתפיים
	var head := sh + Vector2(4.0, -5.0)
	Art.oval_shaded(z, head, 5.6, 5.0, Art.shade(sk, -0.05), 0.0)
	DrawBatch.circle(z, head + Vector2(2.5, -1.0), 1.5, Color(0.88, 0.92, 0.9))   # עין עכורה
	DrawBatch.circle(z, head + Vector2(-0.5, -1.2), 1.2, Color(0.82, 0.86, 0.84))
	DrawBatch.colored_polygon(z, Art.ellipse(head + Vector2(3.0, 2.6), 2.2, 1.3 + pulse, 0.0, 8), col(Color("2a1a22")))   # פה פתוח
	if Engine.get_process_frames() % 40 < 20:   # מים נוטפים מהפה
		DrawBatch.line(z, head + Vector2(3.5, 4.0), head + Vector2(3.8, 7.0 + fmod(t * 6.0, 4.0)), Color(0.5, 0.55, 0.45, 0.7), 1.0)
	# אצות על הראש והכתפיים
	for q in 4:
		var ap := head + Vector2(-5.0 + float(q) * 3.0, -4.0)
		DrawBatch.polyline(z, PackedVector2Array([ap, ap + Vector2(-2.0 + sin(t * 2.0 + float(q)) * 1.5, 5.0), ap + Vector2(-3.0, 10.0)]), col(Color("3a5a2a")), 1.4)
	if big:   # בוס: כתר של קנים ושקי גז בגב
		for q in 5:
			var rp := head + Vector2(-5.0 + float(q) * 2.6, -4.5)
			DrawBatch.line(z, rp, rp + Vector2(-1.0 + float(q) * 0.5, -7.0 - float(q % 2) * 3.0), col(Color("5a4a2a")), 1.4)
		for q in 3:
			var gp := bc + Vector2(-brx * 0.75, -bry * 0.55 + float(q) * 7.0)
			Art.oval(z, gp, 4.0 + float(q % 2), 3.5, Color(0.6, 0.7, 0.3, 0.9) if z._flash <= 0.0 else Color.WHITE)
			DrawBatch.circle(z, gp + Vector2(-1, -1), 1.0, Color(0.9, 1.0, 0.6, 0.6 + 0.4 * pulse))
	# יד קדמית (תלויה על הבטן, אצות מהאצבעות)
	var hf := Vector2(brx + 1.0, -22.0 + bob - sin(p) * 1.5)
	var el := Vector2(brx * 0.85, -36.0 + bob)
	if state == WAVE or state == SWELL:   # מחבק את הבטן
		hf = Vector2(brx * 0.7, -15.0 + bob)
		el = Vector2(brx * 0.95, -32.0 + bob)
	Art.limb(z, PackedVector2Array([sh + Vector2(6, 1), el, hf]), 5.5, sk)
	DrawBatch.polyline(z, PackedVector2Array([hf, hf + Vector2(sin(t * 2.0) * 1.5, 5.0), hf + Vector2(-1.0, 9.0)]), col(Color("3a5a2a")), 1.3)
	end_draw()
	return true
