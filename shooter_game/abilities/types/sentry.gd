extends "res://abilities/ability_base.gd"
# ============================================================
#  SENTRY GUN - טורט אוטומטי על חצובה ליד הרגליים. כל FIRE_GAP שניות יורה על הזומבי הכי קרוב
#  שהוא רואה (קרן בלי קירות) בטווח RANGE. קליעים רגילים (bullet.gd) - נזק DMG.
#  הזומבים לא תוקפים אותו - הם עדיין רוצים אותך. POWER: משך + נזק.
# ============================================================
const BulletScript := preload("res://bullet.gd")
const RANGE := 680.0
const FIRE_GAP := 0.13
const DMG := 0.5


func activate() -> bool:
	if not player.is_on_floor():
		player._say("NEED GROUND", Color(1, 0.6, 0.5))
		return false
	for t in player.get_tree().get_nodes_in_group("sentries"):
		t.life = minf(t.life, 0.3)   # רק טורט אחד
	var s := Turret.new()
	s.life = duration()
	s.dmg = DMG * (1.0 + 0.15 * float(power))
	s.face = player._face()
	player.get_parent().add_child(s)
	s.global_position = player.global_position + Vector2(player._face() * 26.0, 0.0)
	Sfx.play("servo", s.global_position, 2.0)
	Sfx.play("clink", s.global_position, 0.0)
	return true


func active() -> bool:   # טורט עומד ויורה (מסגרת זוהרת ב-HUD)
	return player != null and not player.get_tree().get_nodes_in_group("sentries").is_empty()


class Turret extends Node2D:
	const Art := preload("res://art.gd")
	const Sfx := preload("res://sfx.gd")
	const BulletScript := preload("res://bullet.gd")
	var life := 12.0
	var dmg := 0.5
	var face := 1.0
	var _aim := 0.0          # זווית הקנה
	var _gap := 0.4
	var _target: Node = null
	var _scan := 0.0
	var _flash := 0.0
	var _t := 0.0
	var _deploy := 0.0

	func _ready() -> void:
		add_to_group("sentries")
		z_index = 5
		_aim = 0.0 if face > 0.0 else PI

	func _physics_process(delta: float) -> void:
		_t += delta
		_deploy = minf(_deploy + delta * 3.0, 1.0)
		_flash -= delta
		life -= delta
		if life <= 0.0:
			Sfx.play("whoosh", global_position, -2.0)
			Particles_burst()
			queue_free()
			return
		var muzzle := global_position + Vector2(0, -24)
		_scan -= delta
		if _scan <= 0.0:   # מחפש מטרה 6 פעמים בשנייה (לא בכל פריים)
			_scan = 0.16
			_target = _find(muzzle)
		if _target != null and (not is_instance_valid(_target) or _target.dead):
			_target = null
		if _target != null:
			var tp: Vector2 = _target.global_position + Vector2(0, -30.0 * float(_target.sc))
			var want := (tp - muzzle).angle()
			_aim = lerp_angle(_aim, want, minf(1.0, delta * 14.0))
			_gap -= delta
			if _gap <= 0.0 and absf(angle_difference(_aim, want)) < 0.2 and _deploy >= 1.0:
				_gap = FIRE_GAP
				_shoot(muzzle)
		else:
			_aim = lerp_angle(_aim, (0.0 if face > 0.0 else PI) + sin(_t * 1.5) * 0.35, delta * 3.0)
		queue_redraw()

	func _find(from: Vector2) -> Node:
		var best: Node = null
		var bd := RANGE
		var space := get_world_2d().direct_space_state
		for z in get_tree().get_nodes_in_group("zombies"):
			if z.dead:
				continue
			var zp: Vector2 = z.global_position + Vector2(0, -30.0 * float(z.sc))
			var d := from.distance_to(zp)
			if d >= bd:
				continue
			var q := PhysicsRayQueryParameters2D.create(from, zp, 1)
			if space.intersect_ray(q):
				continue
			bd = d
			best = z
		return best

	func _shoot(muzzle: Vector2) -> void:
		var dir := Vector2.from_angle(_aim + randf_range(-0.04, 0.04))
		var b = BulletScript.new()
		get_parent().add_child(b)
		b.dmg_mult = dmg
		b.head_mult = 0.6
		b.knockback = 40.0
		b.weapon_id = 0
		b.shot = 0
		b.life_time = RANGE / 2500.0
		b.setup(muzzle + dir * 18.0, dir * 2500.0, muzzle)
		_flash = 0.05
		Sfx.play("smg", muzzle, -9.0, 0.1, 3, 1.15)

	func Particles_burst() -> void:
		preload("res://particles.gd").burst(get_parent(), global_position + Vector2(0, -20), "smoke", Vector2.UP, 8)

	func _draw() -> void:
		DrawBatch.begin(self)
		_draw_b()
		DrawBatch.end(self)

	func _draw_b() -> void:
		var k := clampf(life / 1.0, 0.0, 1.0)   # מהבהב בשנייה האחרונה
		if life < 1.0 and int(_t * 12.0) % 2 == 0:
			return
		var up := -24.0 * _deploy
		# חצובה
		for lx: float in [-14.0, 0.0, 14.0]:
			DrawBatch.line(self, Vector2(0, up + 8.0), Vector2(lx, 0), Color("2a2c26"), 2.4, true)
		Art.fill(self, PackedVector2Array([Vector2(-4, up + 4), Vector2(4, up + 4), Vector2(3, up + 12), Vector2(-3, up + 12)]), Color("3a3c34"), Art.OUTLINE, 1.0)
		# גוף + קנה מסתובב
		var d := Vector2.from_angle(_aim)
		var n := d.rotated(PI / 2.0)
		var c := Vector2(0, up)
		var flip := 1.0 if d.x >= 0.0 else -1.0
		var body := PackedVector2Array([c - d * 8.0 - n * 6.0 * flip, c + d * 8.0 - n * 6.0 * flip, c + d * 8.0 + n * 5.0 * flip, c - d * 8.0 + n * 5.0 * flip])
		Art.fill_shaded(self, body, Color("8a8a3a"), 0.25, 0.35, Art.OUTLINE, 1.2)
		Art.limb(self, PackedVector2Array([c + d * 8.0, c + d * 24.0]), 2.6, Color("26262c"), Art.OUTLINE)
		DrawBatch.rect(self, Rect2(c - d * 2.0 + n * 5.0 * flip - Vector2(3, 3), Vector2(6, 6)), Color("3a4a2a"))   # קופסת תחמושת
		var led := Color(1.0, 0.2, 0.15) if _target != null else Color(0.3, 1.0, 0.4)
		DrawBatch.circle(self, c - d * 4.0 - n * 3.0 * flip, 1.6, Color(led, 0.6 + 0.4 * sin(_t * 10.0)))
		if _target != null:   # קרן לייזר דקה למטרה
			DrawBatch.line(self, c + d * 24.0, c + d * 140.0, Color(1.0, 0.2, 0.15, 0.25 * k), 1.0, true)
		if _flash > 0.0:
			Art.glow(self, c + d * 28.0, 10.0, Color(1.0, 0.8, 0.35, 0.9))
