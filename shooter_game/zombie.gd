extends CharacterBody2D
# ============================================================
#  זומבי. יש 3 סוגים (kind):
#    0 = WALKER  - זומבי רגיל
#    1 = RUNNER  - רזה ומהיר, מעט חיים
#    2 = BRUTE   - ענק, איטי, הרבה חיים ונושך חזק
#  * ירייה בראש (HEADSHOT) = מוות מיידי.
#  * 2 קליעים ברגליים = הרגל נתלשת והזומבי מקפץ על רגל אחת.
#  * זומבי שעובר ליד רגל שנפלה מרים אותה וזורק אותה על השחקן.
#  נקודת ה-(0,0) של הזומבי היא כפות הרגליים.
# ============================================================

const Art := preload("res://art.gd")
const BloodScript := preload("res://blood_drop.gd")
const LegScript := preload("res://severed_leg.gd")

enum { WALKER, RUNNER, BRUTE }

## סוג הזומבי (main.gd בוחר באקראי)
@export_enum("Walker", "Runner", "Brute") var kind := 0

# ---- נתוני כל סוג (אפשר לשנות) ----
const KINDS := [
	{   # WALKER
		"hp": 3, "walk": 45.0, "chase": 95.0, "damage": 1, "bite_delay": 0.8, "scale": 1.0, "width": 1.0,
		"skin": Color("86a06a"), "shirt": Color("4f6688"), "pants": Color("3d3a4c"), "shoe": Color("2c241e"),
	},
	{   # RUNNER
		"hp": 2, "walk": 70.0, "chase": 175.0, "damage": 1, "bite_delay": 0.6, "scale": 0.97, "width": 0.85,
		"skin": Color("aab7a6"), "shirt": Color("8c3434"), "pants": Color("33402f"), "shoe": Color(0, 0, 0, 0),
	},
	{   # BRUTE
		"hp": 9, "walk": 28.0, "chase": 62.0, "damage": 2, "bite_delay": 1.2, "scale": 1.25, "width": 1.35,
		"skin": Color("6c8450"), "shirt": Color("b9b29a"), "pants": Color("34466a"), "shoe": Color("1e1a16"),
	},
]

var chase_range := 520.0         # מאיזה מרחק הוא מתחיל לרדוף
var throw_range := 430.0         # מאיזה מרחק הוא זורק רגל
var jump_velocity := -560.0
var gravity := 1500.0
var corpse_time := 7.0           # כמה שניות הגופה נשארת

var world_w := 100000.0          # רוחב העולם (main.gd קובע)
var hp := 3
var dead := false

var sc := 1.0      # גודל
var wf := 1.0      # רוחב
var skin: Color
var shirt: Color
var pants: Color
var shoe: Color
var walk_speed := 45.0
var chase_speed := 95.0
var damage := 1
var bite_delay := 0.8

var _shape: CollisionShape2D
var _dir := 1.0
var _wander_t := 0.0
var _attack_t := 0.0
var _bite_anim := 0.0
var _flash := 0.0
var _walk_phase := 0.0
var _speed_mul := 1.0
var _chasing := false
var _time := 0.0
# פגיעות
var _leg_hits := 0
var _one_leg := false
var _hop_t := 0.0
var _headless := false
var _wounds: Array[Vector2] = []
# רגל ביד
var _carry: Node2D = null
var _pick_cd := 0.0
var _throw_cd := 0.0
var _throw_anim := 0.0
# אחרי המוות
var _spin := 0.0
var _angle := 0.0
var _dead_t := 0.0
var _bled_on: Dictionary = {}


func _ready() -> void:
	add_to_group("zombies")
	var k: Dictionary = KINDS[clampi(kind, 0, KINDS.size() - 1)]
	hp = k.hp
	walk_speed = k.walk
	chase_speed = k.chase
	damage = k.damage
	bite_delay = k.bite_delay
	sc = k.scale
	wf = k.width
	var tint := randf_range(-0.08, 0.08)
	skin = Art.shade(k.skin, tint)
	shirt = Art.shade(k.shirt, randf_range(-0.1, 0.1))
	pants = k.pants
	shoe = k.shoe
	collision_layer = 4   # שכבה 3 (ערך 4) = זומבים. הקליעים פוגעים בה
	collision_mask = 1    # מתנגש רק בעולם
	_shape = CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = Vector2(20.0 * wf, 56.0 * sc)
	_shape.shape = r
	_shape.position = Vector2(0.0, -28.0 * sc)
	add_child(_shape)
	_dir = -1.0 if randf() < 0.5 else 1.0
	_speed_mul = randf_range(0.85, 1.2)
	_walk_phase = randf() * TAU
	_time = randf() * 10.0
	z_index = 3


func _physics_process(delta: float) -> void:
	_time += delta
	_flash -= delta
	_attack_t -= delta
	_bite_anim -= delta
	_pick_cd -= delta
	_throw_cd -= delta
	_throw_anim -= delta
	if dead:
		_dead_process(delta)
		return

	var player := get_tree().get_first_node_in_group("player")
	# רחוק מאוד מהשחקן: הזומבי "ישן" (חוסך המון ביצועים)
	if player != null and absf(player.global_position.x - global_position.x) > 1400.0 and is_on_floor() and _carry == null:
		return

	if not is_on_floor():
		velocity.y += gravity * delta

	var target_speed := walk_speed
	_chasing = false
	if player != null and not player.dead and global_position.distance_to(player.global_position) < chase_range:
		_chasing = true
		_dir = signf(player.global_position.x - global_position.x)
		if _dir == 0.0:
			_dir = 1.0
		target_speed = chase_speed
		# נשיכה
		var d: Vector2 = player.global_position - global_position
		if absf(d.x) < 16.0 + 10.0 * wf and absf(d.y) < 50.0 and _attack_t <= 0.0:
			_attack_t = bite_delay
			_bite_anim = 0.25
			player.hurt(damage, Vector2(_dir, 0.0))
	else:
		_wander_t -= delta
		if _wander_t <= 0.0:
			_wander_t = randf_range(1.5, 4.0)
			_dir = -_dir if randf() < 0.5 else _dir

	_legs_process(player)

	if _one_leg:
		# קפיצות על רגל אחת
		if is_on_floor():
			velocity.x = move_toward(velocity.x, 0.0, 1400.0 * delta)
			_hop_t -= delta
			if _hop_t <= 0.0:
				_hop_t = randf_range(0.12, 0.3)
				velocity.y = -250.0 if not is_on_wall() else jump_velocity * 0.85
				velocity.x = _dir * maxf(target_speed * _speed_mul * 0.8, 70.0)
	else:
		velocity.x = move_toward(velocity.x, _dir * target_speed * _speed_mul, 600.0 * delta)
	move_and_slide()

	# נתקע בקיר: קופץ (או מסתובב אם הוא סתם מטייל)
	if is_on_wall() and is_on_floor() and not _one_leg:
		if _chasing:
			velocity.y = jump_velocity
		else:
			_dir = -_dir

	if global_position.x < 20.0:
		global_position.x = 20.0
		_dir = 1.0
	elif global_position.x > world_w - 20.0:
		global_position.x = world_w - 20.0
		_dir = -1.0

	if is_on_floor():
		_walk_phase += delta * absf(velocity.x) * 0.075 / sc
	if Art.on_screen(self, global_position):   # מציירים רק מה שרואים
		queue_redraw()


# ============================================================
#  רגליים שנפלו: להרים ולזרוק על השחקן
# ============================================================
func _legs_process(player: Node) -> void:
	if _carry != null and not is_instance_valid(_carry):
		_carry = null
	if _carry == null and _pick_cd <= 0.0 and _throw_anim <= 0.0:
		for l in get_tree().get_nodes_in_group("severed_legs"):
			if l.can_pickup() and absf(l.global_position.x - global_position.x) < 14.0 + 10.0 * wf \
					and absf(l.global_position.y - global_position.y) < 40.0 * sc:
				l.pick(self)
				_carry = l
				_throw_cd = randf_range(0.5, 1.1)
				break
	if _carry == null:
		return
	_carry.global_position = _hand_world()
	_carry.rotation = -PI / 2.0 + sin(_time * 6.0) * 0.3
	if player == null or player.dead or _throw_cd > 0.0:
		return
	var target: Vector2 = player.global_position + Vector2(0.0, -26.0)
	var dx := target.x - global_position.x
	if absf(dx) < throw_range and absf(dx) > 50.0 and absf(target.y - global_position.y) < 220.0:
		_dir = signf(dx)
		var from := _hand_world()
		var t := clampf(absf(target.x - from.x) / 430.0, 0.4, 1.0)
		var g: float = _carry.gravity
		var v := Vector2((target.x - from.x) / t, (target.y - from.y - 0.5 * g * t * t) / t)
		_carry.throw_at(from, v)
		_carry = null
		_throw_anim = 0.35
		_pick_cd = 1.2


func _hand_world() -> Vector2:
	return global_position + Vector2(_dir * 9.0 * wf * sc, -55.0 * sc)


# ============================================================
#  פגיעות
# ============================================================
# נקרא מ-bullet.gd ומ-grenade.gd. hit_pos קובע איפה הפגיעה: ראש / גוף / רגליים
func take_damage(amount: int, hit_pos: Vector2, dir: Vector2) -> void:
	if dead:
		return
	_flash = 0.1
	var ly := (hit_pos.y - global_position.y) / sc
	if ly < -42.0:
		# ---- HEADSHOT ----
		_headless = true
		_spray_blood(global_position + Vector2(0.0, -50.0 * sc), Vector2(dir.x, -0.6), 22, 420.0)
		_popup("HEADSHOT!", Color("ffdd44"))
		hp = 0
		_die(dir)
		return
	if ly > -20.0 and not _one_leg:
		# ---- רגליים ----
		_leg_hits += 1
		_spray_blood(hit_pos, dir, 5, 220.0)
		if _leg_hits >= 2:
			_lose_leg(dir)
		return
	hp -= amount
	_spray_blood(hit_pos, dir, 6, 260.0)
	if _wounds.size() < 6:
		var lx := (hit_pos.x - global_position.x) * _dir / (sc * wf)
		_wounds.append(Vector2(clampf(lx, -6.0, 6.0), clampf(ly, -40.0, -22.0)))
	if hp <= 0:
		_die(dir)
	else:
		velocity.x += dir.x * 110.0


func _lose_leg(dir: Vector2) -> void:
	_one_leg = true
	_hop_t = 0.4
	var hip := global_position + Vector2(-_dir * 2.0 * wf, -22.0 * sc)
	_spray_blood(hip, dir, 14, 300.0)
	var leg = LegScript.new()
	get_parent().add_child(leg)
	leg.setup(hip + Vector2(0.0, 8.0 * sc), Vector2(dir.x * 160.0 + randf_range(-40.0, 40.0), -200.0), pants, skin, shoe, sc)
	_popup("LEG!", Color("ff8a5a"))


func _die(dir: Vector2) -> void:
	dead = true
	remove_from_group("zombies")
	if _carry != null and is_instance_valid(_carry):
		_carry.drop(Vector2(randf_range(-80.0, 80.0), -150.0))
	_carry = null
	collision_layer = 0   # קליעים כבר לא פוגעים בגופה
	var r := _shape.shape as RectangleShape2D
	r.size = Vector2(18, 18) * sc   # גופה = ריבוע קטן שמתגלגל
	_shape.position = Vector2(0.0, -9.0 * sc)
	velocity = Vector2(dir.x, minf(dir.y, 0.0)).normalized() * randf_range(420.0, 620.0) / sqrt(sc * wf) + Vector2(0.0, -260.0)
	_spin = randf_range(8.0, 14.0) * signf(velocity.x if velocity.x != 0.0 else 1.0)
	_spray_blood(global_position + Vector2(0, -30) * sc, dir, 14, 380.0)


func _dead_process(delta: float) -> void:
	_dead_t += delta
	if _dead_t > corpse_time:
		queue_free()
		return
	modulate.a = clampf(corpse_time - _dead_t, 0.0, 1.0)
	velocity.y += gravity * delta
	var impact_speed := velocity.length()
	move_and_slide()
	for i in get_slide_collision_count():
		var c := get_slide_collision(i)
		var col := c.get_collider()
		# התרסקות: כתם דם גדול על הלבנה
		if impact_speed > 200.0 and col != null and col.has_method("add_blood"):
			var key := col.get_instance_id()
			if _bled_on.get(key, 0.0) < _dead_t:
				_bled_on[key] = _dead_t + 0.15
				col.add_blood(c.get_position(), c.get_normal(), clampf(impact_speed / 200.0, 1.0, 3.0))
				_spray_blood(c.get_position(), c.get_normal(), 5, 160.0)
	if is_on_floor():
		velocity.x = move_toward(velocity.x, 0.0, 900.0 * delta)
		_spin = move_toward(_spin, 0.0, 30.0 * delta)
		var rest := PI / 2.0 if fposmod(_angle, TAU) < PI else PI * 1.5
		_angle = lerp_angle(_angle, rest, 8.0 * delta)
	if is_on_wall():
		velocity.x *= -0.3
	_angle += _spin * delta
	if Art.on_screen(self, global_position):
		queue_redraw()


func _spray_blood(pos: Vector2, dir: Vector2, n: int, power: float) -> void:
	for i in n:
		var b = BloodScript.new()
		get_parent().add_child(b)
		var v := Vector2.from_angle(dir.angle() + randf_range(-0.8, 0.8)) * randf_range(power * 0.4, power)
		b.setup(pos, v + Vector2(0.0, -randf_range(40.0, 160.0)))


func _popup(text: String, col: Color) -> void:
	var p := HitText.new()
	p.text = text
	p.color = col
	get_parent().add_child(p)
	p.global_position = global_position + Vector2(0.0, -70.0 * sc)


# ============================================================
#  ציור. מציירים זומבי בגובה "רגיל" (56) שפונה ימינה,
#  ואז מגדילים / מרחיבים / משקפים לפי הסוג והכיוון.
# ============================================================
func _draw() -> void:
	var s := Vector2(_dir * wf * sc, sc)
	if not dead and is_on_floor():
		Art.ground_shadow(self, Vector2(0.0, 0.0), 14.0 * wf * sc)
	if dead:
		var outer := Transform2D(_angle, Vector2(0.0, -9.0 * sc))
		draw_set_transform_matrix(outer * Transform2D(0.0, s, 0.0, Vector2(0.0, 28.0 * sc)))
	else:
		draw_set_transform(Vector2.ZERO, 0.0, s)
	_draw_body()
	draw_set_transform_matrix(Transform2D.IDENTITY)


func _draw_body() -> void:
	var white := _flash > 0.0
	var sk := Color.WHITE if white else skin
	var sh_col := Color.WHITE if white else shirt
	var pa := Color.WHITE if white else pants
	var shoe_col := Color.WHITE if white else shoe
	var p := _walk_phase
	var air := not is_on_floor() and not dead
	var lean := 0.0
	match kind:
		RUNNER:
			lean = 7.0 if _chasing else 3.0
		BRUTE:
			lean = 2.0
		_:
			lean = 3.0
	var bob := absf(sin(p)) * 1.5
	var hip := Vector2(0.0, -24.0 - bob * 0.5)
	var sh := Vector2(lean, -41.0 - bob * 0.5 + (1.0 if kind == BRUTE else 0.0))
	var head := sh + Vector2(2.5 + lean * 0.35, -9.0)
	if kind == BRUTE:
		head = sh + Vector2(3.5, -7.5)

	# כפות רגליים
	var stride := 7.0 if kind == RUNNER and _chasing else 5.0
	var lift := 4.0 if kind == RUNNER else 2.5
	var f1 := Vector2(sin(p) * stride + 1.0, -maxf(0.0, cos(p)) * lift)
	var f2 := Vector2(sin(p + PI) * stride - 1.0, -maxf(0.0, cos(p + PI)) * lift)
	if _one_leg:
		f1 = Vector2(1.5, -6.0) if air else Vector2(1.0, 0.0)
	elif air:
		f1 = Vector2(5.0, -7.0)
		f2 = Vector2(-4.0, -4.0)

	# ---- יד אחורית ----
	var reach := sin(_time * 3.0) * 1.5
	var bs := sh + Vector2(-2.0, 2.0)
	var fs := sh + Vector2(2.5, 2.0)
	var back_hand := bs + Vector2(16.0, 1.0 - reach)
	var front_hand := fs + Vector2(17.0, 3.0 + reach)
	if kind == RUNNER and _chasing:
		back_hand = bs + Vector2(-8.0 + sin(p) * 10.0, 12.0)
		front_hand = fs + Vector2(8.0 - sin(p) * 10.0, 10.0)
	if _bite_anim > 0.0:
		front_hand = fs + Vector2(18.0, -3.0)
		back_hand = bs + Vector2(18.0, -1.0)
	if _carry != null or _throw_anim > 0.0:
		var k := clampf(_throw_anim / 0.35, 0.0, 1.0)
		front_hand = fs + Vector2(4.0 + 14.0 * k, -16.0 + 18.0 * k)
	if dead:
		back_hand = bs + Vector2(-4.0, 15.0)
		front_hand = fs + Vector2(5.0, 15.0)
	_arm(bs, back_hand, Art.shade(sk, 0.2), Art.shade(sh_col, 0.2))

	# ---- רגליים ----
	if not _one_leg:
		_leg(hip + Vector2(-2.0, 0.0), f2, Art.shade(pa, 0.25), Art.shade(sk, 0.2), Art.shade(shoe_col, 0.2))
	_leg(hip + Vector2(2.0, 0.0), f1, pa, sk, shoe_col)
	if _one_leg:   # גדם
		Art.limb(self, PackedVector2Array([hip + Vector2(-2.0, 0.0), hip + Vector2(-3.0, 6.0)]), 7.0, Art.shade(pa, 0.25))
		var st := hip + Vector2(-3.0, 7.5)
		Art.fill(self, PackedVector2Array([st + Vector2(-4.0, -0.5), st + Vector2(-2.0, 2.5), st + Vector2(0.0, 1.0),
			st + Vector2(2.0, 3.0), st + Vector2(4.0, -0.5)]), Color("8a0d0d"), Art.OUTLINE, 1.0)
		Art.limb(self, PackedVector2Array([st + Vector2(0.5, 0.0), st + Vector2(0.5, 3.5)]), 1.6, Color("e8dcc4"), Art.NONE)   # עצם

	# ---- גוף ----
	match kind:
		BRUTE:
			_torso_brute(sh, hip, sk, sh_col, pa)
		RUNNER:
			_torso_runner(sh, hip, sk, sh_col)
		_:
			_torso_walker(sh, hip, sk, sh_col)
	for w in _wounds:
		Art.oval(self, w, 2.4, 1.8, Color("7a0a0a"), 0.0, Art.NONE)
		Art.oval(self, w + Vector2(0.3, 0.2), 1.1, 0.8, Color("2a0303"), 0.0, Art.NONE)

	# ---- ראש ----
	if _headless:
		Art.limb(self, PackedVector2Array([sh + Vector2(1.0, 0.0), sh + Vector2(2.0, -4.0)]), 5.0, Art.shade(sk, 0.1))
		Art.oval(self, sh + Vector2(2.0, -5.0), 3.2, 1.8, Color("8a0d0d"))
		Art.disc(self, sh + Vector2(2.0, -5.0), 1.1, Color("e8dcc4"), Art.NONE)
	else:
		_head(head, sk)

	# ---- יד קדמית ----
	_arm(fs, front_hand, sk, sh_col)


func _leg(hip: Vector2, foot: Vector2, pa: Color, sk: Color, shoe_col: Color) -> void:
	var ankle := foot + Vector2(0.0, -3.0)
	var knee := Art.joint(hip, ankle, 11.5, 11.5, 1.0)
	var mid := knee.lerp(ankle, 0.45)
	Art.limb(self, PackedVector2Array([hip, knee, mid]), 7.0, pa)
	Art.limb(self, PackedVector2Array([mid, ankle]), 5.2, sk)
	# שוליים קרועים של המכנס
	Art.fill(self, PackedVector2Array([mid + Vector2(-3.8, -1.0), mid + Vector2(3.8, -1.0), mid + Vector2(3.0, 2.0), mid + Vector2(1.0, 0.8), mid + Vector2(-1.0, 2.5), mid + Vector2(-3.0, 0.8)]), pa, Art.NONE)
	if shoe_col.a > 0.0:
		Art.fill(self, PackedVector2Array([foot + Vector2(-3.0, -4.5), foot + Vector2(3.0, -4.5), foot + Vector2(7.0, -1.5), foot + Vector2(7.0, 0.0), foot + Vector2(-3.5, 0.0)]), shoe_col, Art.OUTLINE, 1.0)
	else:   # יחף
		Art.fill(self, PackedVector2Array([foot + Vector2(-2.5, -4.0), foot + Vector2(2.5, -4.0), foot + Vector2(6.5, -1.2), foot + Vector2(6.5, 0.0), foot + Vector2(-3.0, 0.0)]), sk, Art.OUTLINE, 1.0)


func _arm(shoulder: Vector2, hand: Vector2, sk: Color, sleeve: Color) -> void:
	var w := 7.0 if kind == BRUTE else (4.2 if kind == RUNNER else 5.2)
	var elbow := Art.joint(shoulder, hand, 9.0, 9.5, -1.0)
	if kind != WALKER:   # בלי שרוולים (גופייה)
		Art.limb(self, PackedVector2Array([shoulder, elbow, hand]), w, sk)
	else:
		var cuff := shoulder.lerp(elbow, 0.75)
		Art.limb(self, PackedVector2Array([cuff, elbow, hand]), w * 0.85, sk)
		Art.limb(self, PackedVector2Array([shoulder, cuff]), w + 1.0, sleeve)
	# כף יד עם אצבעות שמוטות
	var d := (hand - elbow).normalized()
	Art.disc(self, hand, w * 0.5 + 0.6, sk)
	for i in 3:
		var a := d.rotated(0.5 + float(i) * 0.35)
		draw_line(hand + d * 1.5, hand + d * 2.0 + a * 4.0, Art.OUTLINE, 1.6, true)
		draw_line(hand + d * 1.5, hand + d * 2.0 + a * 4.0, sk, 0.9, true)


func _torso_walker(sh: Vector2, hip: Vector2, sk: Color, shirt_c: Color) -> void:
	Art.limb(self, PackedVector2Array([sh + Vector2(1.0, 0.0), sh + Vector2(2.0, -5.0)]), 5.0, Art.shade(sk, 0.1))   # צוואר
	var body := PackedVector2Array([
		sh + Vector2(-8.5, -1.0), sh + Vector2(8.5, 0.0), hip + Vector2(8.0, -3.0), hip + Vector2(7.5, 3.5),
		hip + Vector2(4.5, 1.0), hip + Vector2(2.0, 4.5), hip + Vector2(-1.0, 1.5), hip + Vector2(-4.5, 4.0),
		hip + Vector2(-8.0, 0.5), sh + Vector2(-9.0, 6.0),
	])
	Art.fill_shaded(self, body, shirt_c, 0.15, 0.35, Art.OUTLINE, 1.4)
	# קרע בחולצה + צלעות
	Art.fill(self, PackedVector2Array([sh + Vector2(1.0, 7.0), sh + Vector2(6.0, 5.0), sh + Vector2(5.0, 12.0), sh + Vector2(2.0, 10.0)]), Art.shade(sk, 0.15), Art.NONE)
	draw_line(sh + Vector2(2.5, 7.5), sh + Vector2(5.3, 6.6), Art.shade(sk, 0.45), 0.8, true)
	draw_line(sh + Vector2(2.7, 9.3), sh + Vector2(5.2, 8.6), Art.shade(sk, 0.45), 0.8, true)
	Art.oval(self, sh + Vector2(-3.0, 11.0), 3.0, 4.0, Color(0.45, 0.04, 0.04, 0.55), 0.3, Art.NONE)   # כתם דם
	draw_polyline(PackedVector2Array([sh + Vector2(-6.0, 2.0), hip + Vector2(-5.0, -3.0)]), Color(0, 0, 0, 0.25), 1.0, true)
	draw_line(hip + Vector2(-8.0, -1.0), hip + Vector2(8.0, -2.0), Color("2a2218"), 2.0, true)   # חגורה


func _torso_runner(sh: Vector2, hip: Vector2, sk: Color, shirt_c: Color) -> void:
	Art.limb(self, PackedVector2Array([sh + Vector2(1.0, 0.0), sh + Vector2(2.5, -5.0)]), 4.0, Art.shade(sk, 0.1))
	var body := PackedVector2Array([
		sh + Vector2(-7.0, -1.0), sh + Vector2(7.0, 0.0), hip + Vector2(6.5, -2.0),
		hip + Vector2(-6.5, -1.0), sh + Vector2(-7.5, 5.0),
	])
	Art.fill_shaded(self, body, Art.shade(sk, 0.05), 0.15, 0.3, Art.OUTLINE, 1.3)   # גוף חשוף
	# גופייה קרועה
	var top := PackedVector2Array([
		sh + Vector2(-4.0, -0.5), sh + Vector2(-1.5, -0.5), sh + Vector2(1.0, 4.0), sh + Vector2(4.0, -0.3),
		sh + Vector2(6.5, 0.0), hip + Vector2(6.0, -8.0), hip + Vector2(3.0, -5.0), hip + Vector2(0.0, -9.0),
		hip + Vector2(-3.0, -6.0), hip + Vector2(-6.5, -8.0), sh + Vector2(-7.0, 4.0),
	])
	Art.fill_shaded(self, top, shirt_c, 0.15, 0.35, Art.OUTLINE, 1.0)
	for i in 3:   # צלעות בולטות
		var y := hip.y - 6.5 + float(i) * 2.2
		draw_line(Vector2(hip.x + 0.5, y), Vector2(hip.x + 5.5, y - 0.8), Art.shade(sk, 0.4), 0.9, true)
	draw_line(hip + Vector2(-6.5, -1.0), hip + Vector2(6.5, -1.5), Art.shade(pants, 0.2), 2.5, true)


func _torso_brute(sh: Vector2, hip: Vector2, sk: Color, shirt_c: Color, pa: Color) -> void:
	Art.limb(self, PackedVector2Array([sh + Vector2(1.0, 0.0), sh + Vector2(2.5, -3.5)]), 7.0, Art.shade(sk, 0.1))
	# גופייה מלוכלכת עם בטן
	var body := PackedVector2Array([
		sh + Vector2(-9.0, -2.0), sh + Vector2(8.0, -1.0), sh + Vector2(10.0, 6.0), hip + Vector2(11.5, -6.0),
		hip + Vector2(10.0, 0.0), hip + Vector2(3.0, 3.0), hip + Vector2(-8.0, 2.0), sh + Vector2(-10.0, 7.0),
	])
	Art.fill_shaded(self, body, shirt_c, 0.1, 0.35, Art.OUTLINE, 1.5)
	Art.oval(self, hip + Vector2(5.0, -7.0), 4.0, 3.0, Color(0.4, 0.33, 0.2, 0.35), 0.0, Art.NONE)   # כתמים
	Art.oval(self, sh + Vector2(-2.0, 6.0), 3.0, 2.5, Color(0.45, 0.04, 0.04, 0.5), 0.0, Art.NONE)
	# אוברול עם כתפיות
	var bib := PackedVector2Array([
		sh + Vector2(-5.0, 6.0), sh + Vector2(7.0, 6.0), hip + Vector2(11.0, -4.0), hip + Vector2(10.0, 2.0),
		hip + Vector2(-8.0, 2.5), hip + Vector2(-8.0, -6.0),
	])
	Art.fill_shaded(self, bib, pa, 0.15, 0.35, Art.OUTLINE, 1.3)
	Art.limb(self, PackedVector2Array([sh + Vector2(-5.0, 6.5), sh + Vector2(-6.0, -1.5)]), 2.4, pa)
	Art.limb(self, PackedVector2Array([sh + Vector2(6.0, 6.5), sh + Vector2(5.0, -1.0)]), 2.4, pa)
	Art.disc(self, sh + Vector2(-5.0, 7.0), 1.2, Color("c0a050"), Art.OUTLINE, 0.6)
	Art.disc(self, sh + Vector2(6.0, 7.0), 1.2, Color("c0a050"), Art.OUTLINE, 0.6)
	Art.fill(self, PackedVector2Array([hip + Vector2(-1.0, -8.0), hip + Vector2(5.0, -8.0), hip + Vector2(5.0, -4.0), hip + Vector2(-1.0, -4.0)]), Art.shade(pa, 0.15), Art.OUTLINE, 0.7)   # כיס


func _head(c: Vector2, sk: Color) -> void:
	var tilt := sin(_time * 1.3) * 0.08
	match kind:
		RUNNER:   # שיער ארוך ופרוע מאחור
			for i in 6:
				var a := Vector2(-4.0 + float(i) * 1.2, -6.5 + float(i) * 0.4)
				var flow := Vector2(-12.0 - float(i), 3.0 + float(i) * 1.6 + sin(_time * 8.0 + float(i)) * 1.5)
				draw_line(c + a, c + a + flow, Color("2b2420"), 2.2, true)
		BRUTE:
			pass
		_:
			Art.oval(self, c + Vector2(-2.5, -2.5), 6.0, 5.5, Color("3a3026"), 0.2)
	var rx := 8.0 if kind == BRUTE else 7.2
	var ry := 7.5 if kind == BRUTE else 8.2
	Art.oval_shaded(self, c, rx, ry, sk, tilt, Art.OUTLINE, 1.4)
	Art.oval(self, c + Vector2(2.5, -0.5), 4.5, 3.0, Color(0.1, 0.0, 0.05, 0.22), 0.1, Art.NONE)   # עיניים שקועות
	draw_line(c + Vector2(-4.0, 2.0), c + Vector2(-1.0, 5.0), Color(0.3, 0.1, 0.3, 0.4), 0.7, true)   # ורידים
	draw_line(c + Vector2(-3.0, -3.0), c + Vector2(-5.0, 0.5), Color(0.3, 0.1, 0.3, 0.4), 0.7, true)
	# לסת פתוחה
	var jaw_open := 2.0 + sin(_time * 5.0) * 1.0 + (2.5 if _bite_anim > 0.0 else 0.0)
	Art.fill(self, PackedVector2Array([c + Vector2(1.5, 3.0), c + Vector2(7.5, 2.0), c + Vector2(7.0, 3.5 + jaw_open), c + Vector2(2.0, 5.0 + jaw_open)]), Color("2a0a0c"), Art.OUTLINE, 1.0)
	for i in 3:   # שיניים
		var tx := 3.0 + float(i) * 1.6
		Art.fill(self, PackedVector2Array([c + Vector2(tx, 2.7), c + Vector2(tx + 1.2, 2.6), c + Vector2(tx + 0.6, 4.0)]), Color("e0d8b0"), Art.NONE)
	Art.fill(self, PackedVector2Array([c + Vector2(1.5, 5.0 + jaw_open * 0.5), c + Vector2(7.0, 3.5 + jaw_open), c + Vector2(6.0, 6.5 + jaw_open), c + Vector2(1.0, 7.5)]), Art.shade(sk, 0.1), Art.OUTLINE, 1.0)
	# עיניים: אחת זוהרת, אחת שקועה
	Art.oval(self, c + Vector2(0.5, -1.5), 1.6, 1.3, Color("1a0e0e"), 0.0, Art.NONE)
	var eye := c + Vector2(4.5, -1.8)
	Art.oval(self, eye, 2.2, 1.8, Color("1a0e0e"), 0.0, Art.NONE)
	Art.glow(self, eye, 5.0, Color(1.0, 0.85, 0.25, 0.8))
	Art.disc(self, eye, 1.2, Color("fff0a0"), Art.NONE)
	draw_line(c + Vector2(2.0, -4.0), c + Vector2(7.0, -3.2), Art.shade(sk, 0.45), 1.4, true)   # גבה
	Art.disc(self, c + Vector2(-2.5, 0.5), 1.8, Art.shade(sk, 0.15), Art.OUTLINE, 0.8)            # אוזן
	match kind:
		BRUTE:   # קרחת עם תפרים
			draw_polyline(PackedVector2Array([c + Vector2(-5.0, -4.0), c + Vector2(-1.0, -6.5), c + Vector2(3.0, -6.8)]), Color("3a1a1a"), 1.0, true)
			for i in 4:
				var q := c + Vector2(-4.0 + float(i) * 2.2, -4.8 - float(i) * 0.6)
				draw_line(q + Vector2(-0.6, -1.0), q + Vector2(0.6, 1.0), Color("3a1a1a"), 0.8, true)
		WALKER:
			draw_line(c + Vector2(-2.0, -7.5), c + Vector2(-4.0, -10.5), Color("3a3026"), 1.0, true)
			draw_line(c + Vector2(0.0, -8.0), c + Vector2(0.5, -11.0), Color("3a3026"), 1.0, true)
			Art.oval(self, c + Vector2(-1.0, -4.5), 2.0, 1.3, Color("7a0a0a"), 0.4, Art.NONE)   # פצע בראש


# ---- טקסט קופץ (HEADSHOT!) ----
class HitText extends Node2D:
	var text := ""
	var color := Color.WHITE
	var t := 0.0

	func _ready() -> void:
		z_index = 30

	func _process(delta: float) -> void:
		t += delta
		position.y -= 40.0 * delta
		modulate.a = clampf(1.5 - t, 0.0, 1.0)
		if t > 1.5:
			queue_free()
		queue_redraw()

	func _draw() -> void:
		var f := ThemeDB.fallback_font
		var sz := 18
		var w := f.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, sz).x
		var pos := Vector2(-w / 2.0, 0.0)
		draw_string_outline(f, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, sz, 4, Color(0, 0, 0, 0.8))
		draw_string(f, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, sz, color)
