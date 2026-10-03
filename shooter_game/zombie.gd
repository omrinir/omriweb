extends CharacterBody2D
# ============================================================
#  זומבי. יש 3 סוגים (kind):
#    0 = WALKER  - זומבי רגיל
#    1 = RUNNER  - רזה ומהיר, מעט חיים
#    2 = BRUTE   - ענק, איטי, הרבה חיים ונושך חזק
#    3 = SPITTER - שומר מרחק ויורק חומצה
#    4 = SCREAMER - כשהוא רואה אותך הוא צורח ומזעיק את כל הזומבים מסביב
#    5 = BOSS    - ענק עם דלת של מכונית כמגן. שומר על היציאה מהשלב
#  * ירייה בראש (HEADSHOT) = מוות מיידי.
#  * 2 קליעים ברגליים = הרגל נתלשת והזומבי מקפץ על רגל אחת.
#  * זומבי שעובר ליד רגל שנפלה מרים אותה וזורק אותה על השחקן.
#  נקודת ה-(0,0) של הזומבי היא כפות הרגליים.
# ============================================================

const Art := preload("res://art.gd")
const BloodScript := preload("res://blood_drop.gd")
const LegScript := preload("res://severed_leg.gd")
const AcidScript := preload("res://acid.gd")
const FireScript := preload("res://fire.gd")
const PickupScript := preload("res://pickup.gd")
const DebrisScript := preload("res://debris.gd")

enum { WALKER, RUNNER, BRUTE, SPITTER, SCREAMER, BOSS }

## סוג הזומבי (main.gd בוחר באקראי)
@export_enum("Walker", "Runner", "Brute", "Spitter", "Screamer", "Boss") var kind := 0

# ---- נתוני כל סוג (אפשר לשנות) ----
const KINDS := [
	{   # WALKER
		"hp": 30, "walk": 45.0, "chase": 95.0, "damage": 1, "bite_delay": 0.8, "scale": 1.0, "width": 1.0, "duck": 0.25, "cover": 0.45,
		"skin": Color("86a06a"), "shirt": Color("4f6688"), "pants": Color("3d3a4c"), "shoe": Color("2c241e"),
	},
	{   # RUNNER
		"hp": 30, "walk": 70.0, "chase": 175.0, "damage": 1, "bite_delay": 0.6, "scale": 0.97, "width": 0.85, "duck": 0.4, "cover": 0.6,
		"skin": Color("aab7a6"), "shirt": Color("8c3434"), "pants": Color("33402f"), "shoe": Color(0, 0, 0, 0),
	},
	{   # BRUTE
		"hp": 30, "walk": 28.0, "chase": 62.0, "damage": 2, "bite_delay": 1.2, "scale": 1.25, "width": 1.35, "duck": 0.1, "cover": 0.25,
		"skin": Color("6c8450"), "shirt": Color("b9b29a"), "pants": Color("34466a"), "shoe": Color("1e1a16"),
	},
	{   # SPITTER
		"hp": 30, "walk": 40.0, "chase": 75.0, "damage": 1, "bite_delay": 0.9, "scale": 0.95, "width": 0.92, "duck": 0.2, "cover": 0.5,
		"skin": Color("a8b04a"), "shirt": Color("5a6a3a"), "pants": Color("3a3a30"), "shoe": Color("2a241e"),
	},
	{   # SCREAMER
		"hp": 30, "walk": 50.0, "chase": 130.0, "damage": 1, "bite_delay": 0.7, "scale": 1.08, "width": 0.78, "duck": 0.3, "cover": 0.3,
		"skin": Color("c8c2bc"), "shirt": Color("3a3036"), "pants": Color("2a2a2e"), "shoe": Color(0, 0, 0, 0),
	},
	{   # BOSS
		"hp": 400, "walk": 32.0, "chase": 70.0, "damage": 2, "bite_delay": 1.4, "scale": 1.75, "width": 1.6, "duck": 0.0, "cover": 0.0,
		"skin": Color("5e7444"), "shirt": Color("8a8270"), "pants": Color("2e3a52"), "shoe": Color("141210"),
	},
]

var chase_range := 520.0         # מאיזה מרחק הוא מתחיל לרדוף
var throw_range := 430.0         # מאיזה מרחק הוא זורק רגל
var jump_velocity := -560.0
var gravity := 1500.0
var corpse_time := 7.0           # כמה שניות הגופה נשארת

# ---- נזק מקליעים (לכל זומבי יש 30 נקודות חיים) ----
var leg_damage := Vector2i(7, 10)     # פגיעה ברגל: בין 7 ל-10
var body_damage := Vector2i(12, 15)   # פגיעה בגוף: בין 12 ל-15
var head_damage := 30                 # פגיעה בראש

var world_w := 100000.0          # רוחב העולם (main.gd קובע)
# רמת קושי (main.gd קובע): מהירות, וכמה הזומבים "חכמים" (מתכופפים / מתחבאים)
var speed_mult := 1.0
var smart_mult := 1.0
var hp := 3
var max_hp := 30
var dead := false
## זומבי ששוכב על הריצפה וקם כשהשחקן מתקרב (main.gd קובע)
var dormant := false
var wake_range := 230.0
const RISE_TIME := 0.9
var _rise_t := 0.0
var _lie_side := 1.0
# ---- התנהגויות מיוחדות ----
var _alert_t := 0.0              # שמע רעש / צרחה: רודף גם מרחוק
var _rush_t := 0.0               # מסתער (כשיורים על חבר שמתחבא)
var _burn_t := 0.0               # בוער (קליעי אש)
var _burn_acc := 0.0
var _fire: Node2D = null
var _spit_cd := 1.5
var _spit_anim := 0.0
var _screamed := false
var _scream_t := 0.0
var _slam_t := 0.0               # בוס: מכין מכה (המגן למטה!)
var _slam_cd := 0.0
var _charge_t := 0.0
var _charge_cd := 3.0
var _last_info := {}

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
# ---- התחמקות ומחסה ----
var duck_chance := 0.25          # הסיכוי להתכופף כשיורים לכיוונו
var cover_chance := 0.45         # הסיכוי לברוח למחסה כשהוא נפגע
var cover_search := 380.0        # כמה רחוק הוא מחפש מחסה
var _duck_t := 0.0
var _duck_cd := 0.0
var _crouch_k := 0.0
var _crouched_shape := false
var _cover_state := 0            # 0 = רגיל, 1 = רץ למחסה, 2 = מתחבא
var _cover_node: Node = null
var _cover_x := 0.0
var _cover_y := 0.0
var _cover_dir := 1.0
var _cover_t := 0.0
var _think_t := 0.0


func _ready() -> void:
	add_to_group("zombies")
	var k: Dictionary = KINDS[clampi(kind, 0, KINDS.size() - 1)]
	hp = k.hp + (100 * (Game.level - 1) if kind == BOSS else 0)
	max_hp = hp
	walk_speed = k.walk
	chase_speed = k.chase
	damage = k.damage
	bite_delay = k.bite_delay
	duck_chance = clampf(k.duck * smart_mult, 0.0, 0.9)
	cover_chance = clampf(k.cover * smart_mult, 0.0, 0.9)
	walk_speed *= speed_mult
	chase_speed *= speed_mult
	_think_t = randf_range(1.0, 3.0)
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
	if dormant:
		r.size = Vector2(18, 18) * sc
		_shape.position = Vector2(0.0, -9.0 * sc)
		_lie_side = -1.0 if randf() < 0.5 else 1.0
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
	# שוכב על הריצפה עד שהשחקן מתקרב
	if dormant:
		var wr: float = wake_range * (0.45 if player != null and player._crouching else 1.0)   # מתכופף = שקט
		if player != null and not player.dead and absf(player.global_position.x - global_position.x) < wr \
				and absf(player.global_position.y - global_position.y) < 120.0:
			_wake()
		return
	if _rise_t > 0.0:   # קם לאט
		_rise_t -= delta
		if Art.on_screen(self, global_position):
			queue_redraw()
		return
	# בוער מקליעי אש: נזק כל שנייה
	if _burn_t > 0.0:
		_burn_t -= delta
		_burn_acc += 7.0 * delta
		if _burn_acc >= 3.0:
			var d := int(_burn_acc)
			_burn_acc -= float(d)
			take_damage(d, global_position + Vector2(0, -30.0 * sc), Vector2.ZERO, true, {"source": "fire"})
			if dead:
				return
		if _burn_t <= 0.0 and is_instance_valid(_fire):
			_fire.queue_free()
	_alert_t -= delta
	_rush_t -= delta
	_spit_cd -= delta
	_spit_anim -= delta
	# רחוק מאוד מהשחקן: הזומבי "ישן" (חוסך המון ביצועים)
	if player != null and absf(player.global_position.x - global_position.x) > 1400.0 and is_on_floor() and _carry == null:
		return

	if not is_on_floor():
		velocity.y += gravity * delta

	# ---- התכופפות ----
	_duck_t -= delta
	_duck_cd -= delta
	var want_crouch := (_duck_t > 0.0 or _cover_state == 2) and not _one_leg
	_set_crouch(want_crouch)
	_crouch_k = move_toward(_crouch_k, 1.0 if want_crouch else 0.0, delta * 10.0)

	var target_speed := walk_speed
	_chasing = false
	if _cover_state != 0:
		target_speed = _cover_process(delta, player)
	elif player != null and not player.dead and (global_position.distance_to(player.global_position) < chase_range or _alert_t > 0.0):
		_chasing = true
		_dir = signf(player.global_position.x - global_position.x)
		if _dir == 0.0:
			_dir = 1.0
		target_speed = chase_speed
		if _rush_t > 0.0:
			target_speed *= 1.35
		var d: Vector2 = player.global_position - global_position
		match kind:
			SPITTER:
				target_speed = _spitter_logic(player, d)
			SCREAMER:
				if not _screamed and absf(d.x) < 520.0:
					_scream()
				if _scream_t > 0.0:
					_scream_t -= delta
					target_speed = 0.0
			BOSS:
				target_speed = _boss_logic(player, d, delta)
		# נשיכה
		if kind != BOSS and absf(d.x) < 16.0 + 10.0 * wf and absf(d.y) < 50.0 and _attack_t <= 0.0:
			_attack_t = bite_delay
			_bite_anim = 0.25
			player.hurt(damage, Vector2(_dir, 0.0))
		# לפעמים, כשהשחקן מכוון אליו מרחוק, הוא מתקדם ממחסה למחסה
		_think_t -= delta
		if _think_t <= 0.0:
			_think_t = randf_range(2.5, 4.5)
			var far := absf(d.x) > 240.0
			var aimed: bool = player._aim.dot((global_position - player.global_position).normalized()) > 0.85
			if far and aimed and kind != BOSS and randf() < cover_chance * 0.4:
				_try_cover(player)
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
		if _duck_t > 0.0:
			target_speed *= 0.3   # מתכופף = כמעט לא זז
		velocity.x = move_toward(velocity.x, _dir * target_speed * _speed_mul, 600.0 * delta)
	move_and_slide()

	# נתקע בקיר: קופץ (או מסתובב אם הוא סתם מטייל)
	if is_on_wall() and is_on_floor() and not _one_leg:
		if _chasing or _cover_state == 1:
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
	_maybe_redraw()


# ============================================================
#  התחמקות: התכופפות ומחסה מאחורי מכוניות / מחסומים / ארגזים
# ============================================================
# נקרא מ-player.gd בכל ירייה. לפעמים הזומבי מתכופף והקליע עובר מעליו
func on_player_fired(origin: Vector2, aim: Vector2) -> void:
	if dead:
		return
	# יורים על זומבי שמתחבא? החברים שלו מסביב מסתערים
	if _cover_state == 2:
		var to := global_position + Vector2(0.0, -20.0 * sc) - origin
		if aim.dot(to.normalized()) > 0.9:
			get_tree().call_group("zombies", "rush", global_position)
		return
	if _lying() or _one_leg or _duck_cd > 0.0:
		return
	var to_me := global_position + Vector2(0.0, -30.0 * sc) - origin
	if to_me.length() > 520.0 or to_me.length() < 60.0 or aim.dot(to_me.normalized()) < 0.93:
		return
	_duck_cd = 2.0
	if randf() < duck_chance:
		_duck_t = randf_range(0.6, 0.9)
		_set_crouch(true)


func _set_crouch(on: bool) -> void:
	if on == _crouched_shape or dead or _lying():
		return
	_crouched_shape = on
	var r := _shape.shape as RectangleShape2D
	r.size.y = (42.0 if on else 56.0) * sc
	_shape.position.y = -r.size.y / 2.0


# מחפש מחסה קרוב בצד הרחוק מהשחקן. אם אין - ממשיך להילחם
func _try_cover(player: Node) -> bool:
	if _one_leg or player == null or player.dead:
		return false
	var px: float = player.global_position.x
	var best_d := INF
	for c in get_tree().get_nodes_in_group("cover"):
		var r: Rect2 = c.cover_rect()
		if r.size.y < 24.0 or absf(r.end.y - global_position.y) > 12.0:
			continue
		var center := r.get_center().x
		var hx := r.end.x + 14.0 * wf if px < center else r.position.x - 14.0 * wf
		var d := absf(hx - global_position.x)
		if d > cover_search or d < 4.0:
			continue
		if (hx - px) * (global_position.x - px) < 0.0 or absf(hx - px) < 120.0:   # בלי לעבור ליד השחקן
			continue
		if not _spot_ok(hx):
			continue
		if d < best_d:
			best_d = d
			_cover_node = c
			_cover_x = hx
			_cover_y = global_position.y
	if best_d == INF:
		return false
	_cover_state = 1
	_cover_dir = signf(_cover_x - global_position.x)
	_cover_t = 3.5   # אם לא הגיע תוך 3.5 שניות - מוותר
	_duck_t = 0.0
	return true


# האם יש ריצפה במקום ואין שם משהו אחר
func _spot_ok(x: float) -> bool:
	var space := get_world_2d().direct_space_state
	var gy := global_position.y
	var q := PhysicsRayQueryParameters2D.create(Vector2(x, gy - 50.0), Vector2(x, gy + 12.0), 1)
	var hit := space.intersect_ray(q)
	if hit.is_empty() or absf(hit.position.y - gy) > 8.0:
		return false
	var pq := PhysicsPointQueryParameters2D.new()
	pq.collision_mask = 1
	for yy in [20.0, 40.0]:
		pq.position = Vector2(x, gy - yy)
		if not space.intersect_point(pq, 1).is_empty():
			return false
	return true


func _cover_process(delta: float, player: Node) -> float:
	if not is_instance_valid(_cover_node) or player == null or player.dead or _one_leg:
		_end_cover()
		return walk_speed
	var cr: Rect2 = _cover_node.cover_rect()
	var cx := cr.get_center().x
	# השחקן עבר לצד שלו / קרוב מדי - המחסה לא עוזר, חוזר לתקוף
	if signf(player.global_position.x - cx) == signf(_cover_x - cx) or absf(player.global_position.x - global_position.x) < 70.0:
		_end_cover()
		return chase_speed
	_cover_t -= delta
	if _cover_state == 1:
		_chasing = true   # כדי שיקפוץ מעל מכשולים בדרך
		var dx := _cover_x - global_position.x
		var grounded := is_on_floor() and absf(global_position.y - _cover_y) < 10.0
		if grounded and absf(dx) < 14.0:
			_cover_state = 2
			_cover_t = randf_range(2.5, 4.5)
			velocity.x = 0.0
			return 0.0
		# עדיין על מכונית / ארגז: ממשיך באותו כיוון עד שהוא יורד לריצפה
		_dir = _cover_dir if absf(dx) < 14.0 else signf(dx)
		if _cover_t <= 0.0:
			_end_cover()
		return maxf(chase_speed * 1.25, 90.0)
	# מתחבא: מסתכל לכיוון השחקן ומחכה
	_dir = signf(player.global_position.x - global_position.x)
	if _cover_t <= 0.0:
		_end_cover()
	return 0.0


func _end_cover() -> void:
	_cover_state = 0
	_cover_node = null


# ============================================================
#  רעש, הסתערות, שריפה
# ============================================================
# Game.make_noise -> יריות ופיצוצים מעירים זומבים ששוכבים ומושכים זומבים מרחוק
func hear_noise(pos: Vector2, radius: float) -> void:
	if dead or global_position.distance_to(pos) > radius:
		return
	if dormant:
		_wake()
	_alert_t = maxf(_alert_t, 5.0)


func rush(from: Vector2) -> void:
	if dead or _lying() or _cover_state != 0 or kind == BOSS or global_position.distance_to(from) > 350.0:
		return
	if _rush_t <= 0.0 and Art.on_screen(self, global_position):
		_popup("!!", Color("ff6040"), 18, -78.0)
	_rush_t = 3.0


# קליעי אש: הזומבי בוער כמה שניות
func ignite(t: float) -> void:
	if dead:
		return
	_burn_t = maxf(_burn_t, t)
	if not is_instance_valid(_fire):
		_fire = FireScript.new()
		_fire.width = 16.0 * wf * sc
		_fire.height = 26.0 * sc
		_fire.smoke = false
		_fire.position = Vector2(0, -20.0 * sc)
		add_child(_fire)


# ---- SPITTER: שומר מרחק ויורק חומצה ----
func _spitter_logic(player: Node, d: Vector2) -> float:
	var dist := absf(d.x)
	if dist < 210.0:   # קרוב מדי - נסוג
		_dir = -signf(d.x)
		return walk_speed * 1.3
	if dist < 440.0:
		_dir = signf(d.x)
		if _spit_cd <= 0.0 and absf(d.y) < 160.0:
			_spit(player)
		return 0.0
	return chase_speed


func _spit(player: Node) -> void:
	_spit_cd = randf_range(2.2, 3.2)
	_spit_anim = 0.35
	var from := global_position + Vector2(_dir * 10.0, -48.0 * sc)
	var target: Vector2 = player.global_position + Vector2(0, -28)
	var t := clampf(absf(target.x - from.x) / 380.0, 0.5, 1.1)
	var g := 900.0
	var v := Vector2((target.x - from.x) / t, (target.y - from.y - 0.5 * g * t * t) / t)
	var a = AcidScript.new()
	get_parent().add_child(a)
	a.setup(from, v)


# ---- SCREAMER: צורח ומזעיק את כולם ----
func _scream() -> void:
	_screamed = true
	_scream_t = 1.2
	_popup("SCREAM!", Color("e8e0ff"), 18, -84.0)
	Game.make_noise(global_position, 1100.0)
	var cam := get_viewport().get_camera_2d()
	if cam != null and cam.has_method("shake"):
		cam.shake(5.0, 0.6)


# ---- BOSS: מגן מדלת, מכה חזקה והסתערות ----
func _boss_logic(player: Node, d: Vector2, delta: float) -> float:
	_dir = signf(d.x) if d.x != 0.0 else _dir
	_slam_cd -= delta
	_charge_cd -= delta
	if _slam_t > 0.0:   # מרים את הדלת מעל הראש - עכשיו אפשר לפגוע בו!
		_slam_t -= delta
		if _slam_t <= 0.0:
			_slam_cd = 1.6
			var cam := get_viewport().get_camera_2d()
			if cam != null and cam.has_method("shake"):
				cam.shake(10.0, 0.35)
			for i in 8:
				var c = DebrisScript.new()
				get_parent().add_child(c)
				c.setup(global_position + Vector2(_dir * 40.0, -4), Vector2(4, 3), Color("4a4440"), Vector2(randf_range(-160, 160), -randf_range(120, 300)))
			if absf(d.x) < 95.0 and absf(d.y) < 90.0:
				player.hurt(damage, Vector2(_dir, 0.0))
				player.velocity += Vector2(_dir * 380.0, -260.0)
		return 0.0
	if _charge_t > 0.0:
		_charge_t -= delta
		if absf(d.x) < 50.0 and absf(d.y) < 80.0:
			player.hurt(damage, Vector2(_dir, 0.0))
			player.velocity += Vector2(_dir * 420.0, -200.0)
			_charge_t = 0.0
		return chase_speed * 2.6
	if absf(d.x) < 80.0 and _slam_cd <= 0.0:
		_slam_t = 0.8
		return 0.0
	if absf(d.x) > 220.0 and _charge_cd <= 0.0:
		_charge_t = 1.1
		_charge_cd = randf_range(5.0, 7.0)
		_popup("CHARGE!", Color("ff5030"), 20, -110.0)
		return chase_speed * 2.6
	return chase_speed


func is_boss() -> bool:
	return kind == BOSS


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
# נקרא מ-bullet.gd ומ-grenade.gd. hit_pos קובע איפה הפגיעה: ראש / גוף / רגליים.
# explosive = true (רימון): amount הוא הנזק, בלי קשר למקום הפגיעה
func take_damage(amount: int, hit_pos: Vector2, dir: Vector2, explosive := false, src := {}) -> void:
	if dead:
		return
	var source: String = src.get("source", "grenade" if explosive else "bullet")
	# בוס: הדלת חוסמת קליעים מלפנים (חוץ מכשהוא מרים אותה למכה)
	if kind == BOSS and source == "bullet" and _slam_t <= 0.0 and dir.x * _dir < 0.0:
		_popup("BLOCKED", Color("c0c0c8"), 15, -120.0)
		for i in 4:
			var c = DebrisScript.new()
			get_parent().add_child(c)
			c.setup(hit_pos, Vector2(2, 2), Color("ffd060"), Vector2(-dir.x * randf_range(80, 200), -randf_range(40, 200)))
		Game.on_zombie_hit({"source": "bullet", "zone": "shield"})
		return
	_flash = 0.1
	if src.get("incendiary", false):
		ignite(3.0)
	var ly := (hit_pos.y - global_position.y) / sc
	var dmg := amount
	var zone := "body"
	var was_lying := _lying()
	if was_lying:
		_wake()
		_rise_t = minf(_rise_t, 0.4)
	var head_y := -30.0 if _crouched_shape else -42.0   # מתכופף = הראש נמוך יותר
	var leg_y := -12.0 if _crouched_shape else -20.0
	if not explosive and not was_lying:
		if ly < head_y:
			zone = "head"
			dmg = head_damage
		elif ly > leg_y:
			zone = "leg"
			dmg = randi_range(leg_damage.x, leg_damage.y)
		else:
			dmg = randi_range(body_damage.x, body_damage.y)
	elif not explosive:
		dmg = randi_range(body_damage.x, body_damage.y)
	if kind == BOSS and zone == "head":
		dmg = head_damage * 2
	_last_info = {"zone": zone, "source": source, "bullet": src.get("bullet", 0), "blast": src.get("blast", 0),
		"hidden": _cover_state == 2}
	Game.on_zombie_hit(_last_info)
	hp -= dmg
	_damage_number(dmg, zone)

	if zone == "head":
		_spray_blood(global_position + Vector2(0.0, -50.0 * sc), Vector2(dir.x, -0.6), 12, 320.0)
		if hp <= 0:   # HEADSHOT: הראש מתפוצץ
			_headless = true
			_spray_blood(global_position + Vector2(0.0, -50.0 * sc), Vector2(dir.x, -0.6), 16, 420.0)
	elif zone == "leg":
		_spray_blood(hit_pos, dir, 5, 220.0)
		if not _one_leg and kind != BOSS:
			_leg_hits += 1
			if _leg_hits >= 2 and hp > 0:   # 2 פגיעות ברגליים = הרגל נתלשת
				_lose_leg(dir)
	else:
		_spray_blood(hit_pos, dir, 6, 260.0)
		if _wounds.size() < 6:
			var lx := (hit_pos.x - global_position.x) * _dir / (sc * wf)
			_wounds.append(Vector2(clampf(lx, -6.0, 6.0), clampf(ly, -40.0, -22.0)))
	if hp <= 0:
		_die(dir)
	else:
		velocity.x += dir.x * 110.0
		# לפעמים הוא בורח ומתחבא מאחורי מכונית / מחסום (אם יש אחד קרוב)
		if _cover_state == 0 and not was_lying and kind != BOSS and randf() < cover_chance:
			_try_cover(get_tree().get_first_node_in_group("player"))


# מספר הנזק שקופץ מעל הזומבי וצף למעלה
func _damage_number(dmg: int, zone: String) -> void:
	var col := Color.WHITE
	var size := 18
	match zone:
		"head":
			col = Color("ff4a3a")
			size = 26
		"leg":
			col = Color("ffb04a")
	var p := HitText.new()
	p.text = str(dmg)
	p.color = col
	p.size = size
	p.pop = true
	get_parent().add_child(p)
	p.global_position = global_position + Vector2(randf_range(-10.0, 10.0), -66.0 * sc)


func _wake() -> void:
	if not dormant:
		return
	dormant = false
	_rise_t = RISE_TIME
	var r := _shape.shape as RectangleShape2D
	r.size = Vector2(20.0 * wf, 56.0 * sc)
	_shape.position = Vector2(0.0, -28.0 * sc)
	if Art.on_screen(self, global_position):
		_popup("!", Color("ff5040"), 22, -80.0)


func _lying() -> bool:
	return dormant or _rise_t > 0.0


func _lose_leg(dir: Vector2) -> void:
	_one_leg = true
	Game.on_leg_severed()
	_hop_t = 0.4
	var hip := global_position + Vector2(-_dir * 2.0 * wf, -22.0 * sc)
	_spray_blood(hip, dir, 14, 300.0)
	var leg = LegScript.new()
	get_parent().add_child(leg)
	leg.setup(hip + Vector2(0.0, 8.0 * sc), Vector2(dir.x * 160.0 + randf_range(-40.0, 40.0), -200.0), pants, skin, shoe, sc)
	_popup("LEG!", Color("ff8a5a"), 16, -40.0)


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
	if is_instance_valid(_fire):
		_fire.queue_free()
	# ניקוד + בונוסים
	var bonuses: Array = Game.on_zombie_killed(kind, _last_info)
	for i in bonuses.size():
		var b: Array = bonuses[i]
		var txt: String = b[0] + (" +%d" % b[1] if int(b[1]) > 0 else "")
		_popup(txt, Color("ffd34a"), 15, -96.0 - float(i) * 17.0)
	# שלל: ענק = בוסט, בוס = הרבה, אחרים = לפעמים תחמושת
	match kind:
		BRUTE:
			_drop(PickupScript.BOOST)
		BOSS:
			_drop(PickupScript.BOOST)
			_drop(PickupScript.BOOST)
			_drop(PickupScript.SUPPLY)
			get_tree().call_group("level_exit", "on_boss_dead")
		_:
			if randf() < 0.1:
				_drop(PickupScript.AMMO)


func _drop(pk: int) -> void:
	var p = PickupScript.new()
	p.kind = pk
	p.boost = randi() % 5
	get_parent().add_child.call_deferred(p)
	p.setup.call_deferred(global_position + Vector2(0, -40), Vector2(randf_range(-120, 120), -280))


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
	_maybe_redraw()


func _spray_blood(pos: Vector2, dir: Vector2, n: int, power: float) -> void:
	for i in n:
		var b = BloodScript.new()
		get_parent().add_child(b)
		var v := Vector2.from_angle(dir.angle() + randf_range(-0.8, 0.8)) * randf_range(power * 0.4, power)
		b.setup(pos, v + Vector2(0.0, -randf_range(40.0, 160.0)))


func _popup(text: String, col: Color, size := 18, y := -80.0) -> void:
	var p := HitText.new()
	p.text = text
	p.color = col
	p.size = size
	get_parent().add_child(p)
	p.global_position = global_position + Vector2(0.0, y * sc)


# ============================================================
#  ציור. מציירים זומבי בגובה "רגיל" (56) שפונה ימינה,
#  ואז מגדילים / מרחיבים / משקפים לפי הסוג והכיוון.
# ============================================================
func _draw() -> void:
	var s := Vector2(_dir * wf * sc, sc)
	if not dead and not _lying() and is_on_floor():
		Art.ground_shadow(self, Vector2(0.0, 0.0), 14.0 * wf * sc)
	if dead:
		var outer := Transform2D(_angle, Vector2(0.0, -9.0 * sc))
		draw_set_transform_matrix(outer * Transform2D(0.0, s, 0.0, Vector2(0.0, 28.0 * sc)))
	elif _lying():
		# שוכב, או קם לאט (מסתובב מהשכיבה לעמידה)
		var k := 1.0 if dormant else clampf(_rise_t / RISE_TIME, 0.0, 1.0)
		k = k * k * (3.0 - 2.0 * k)
		var outer := Transform2D(PI / 2.0 * _lie_side * k, Vector2(0.0, lerpf(-28.0, -9.0, k) * sc))
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
	var air := not is_on_floor() and not dead and not _lying()
	var lean := 0.0
	match kind:
		RUNNER:
			lean = 7.0 if _chasing else 3.0
		BRUTE:
			lean = 2.0
		_:
			lean = 3.0
	var bob := absf(sin(p)) * 1.5
	var ck := 0.0 if dead or _lying() else _crouch_k   # התכופפות
	var hip := Vector2(0.0, -24.0 - bob * 0.5 + 11.0 * ck)
	var sh := Vector2(lean + 3.0 * ck, -41.0 - bob * 0.5 + (1.0 if _big() else 0.0) + 12.0 * ck)
	var head := sh + Vector2(2.5 + lean * 0.35, -9.0)
	if _big():
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
	f1.x += 5.0 * ck
	f2.x -= 5.0 * ck

	# ---- יד אחורית ----
	var reach := sin(_time * 3.0) * 1.5
	var bs := sh + Vector2(-2.0, 2.0)
	var fs := sh + Vector2(2.5, 2.0)
	var back_hand := bs + Vector2(16.0, 1.0 - reach)
	var front_hand := fs + Vector2(17.0, 3.0 + reach)
	if (kind == RUNNER and _chasing) or _cover_state == 1:   # רץ (או בורח) - ידיים מתנופפות
		back_hand = bs + Vector2(-8.0 + sin(p) * 10.0, 12.0)
		front_hand = fs + Vector2(8.0 - sin(p) * 10.0, 10.0)
	if ck > 0.5:   # מתכופף: ידיים מגינות על הראש
		front_hand = head + Vector2(4.0, -5.0)
		back_hand = head + Vector2(-3.0, -6.0)
	if _bite_anim > 0.0:
		front_hand = fs + Vector2(18.0, -3.0)
		back_hand = bs + Vector2(18.0, -1.0)
	if _carry != null or _throw_anim > 0.0:
		var k := clampf(_throw_anim / 0.35, 0.0, 1.0)
		front_hand = fs + Vector2(4.0 + 14.0 * k, -16.0 + 18.0 * k)
	if dead or _lying():
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
		BRUTE, BOSS:
			_torso_brute(sh, hip, sk, sh_col, pa)
		RUNNER, SCREAMER:
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
	if kind == BOSS and not dead:
		_boss_arms(fs, head, sk, sh_col)
		return
	if kind == SCREAMER and _scream_t > 0.0:   # ידיים פתוחות לצדדים בזמן הצרחה
		front_hand = fs + Vector2(12.0, -10.0)
	_arm(fs, front_hand, sk, sh_col)
	if kind == SCREAMER and _scream_t > 0.0:   # גלי קול
		for i in 3:
			var k := fmod(1.2 - _scream_t + float(i) * 0.3, 0.9) / 0.9
			draw_arc(head + Vector2(6, 2), 8.0 + k * 40.0, -0.9, 0.9, 12, Color(0.9, 0.9, 1.0, 0.7 * (1.0 - k)), 2.0, true)


# ביצועים: האנימציה של הגוף מצוירת מחדש כל פריים שני (התזוזה עצמה נשארת חלקה),
# וזומבים שלא על המסך לא מצוירים בכלל
# כשיש הרבה זומבים על המסך - כל פריים שלישי
var _redraw_tick := randi() % 3
static var _vis_frame := -1
static var _vis_count := 0
static var _vis_prev := 0


func _maybe_redraw() -> void:
	var fr := Engine.get_physics_frames()
	if fr != _vis_frame:   # סופרים כמה זומבים על המסך בכל פריים
		_vis_prev = _vis_count
		_vis_count = 0
		_vis_frame = fr
	if not Art.on_screen(self, global_position):
		return
	_vis_count += 1
	var every := 2 if _vis_prev <= 3 else 3
	_redraw_tick += 1
	if _redraw_tick % every == 0 or _flash > 0.0:
		queue_redraw()


func _big() -> bool:
	return kind == BRUTE or kind == BOSS


# בוס: מחזיק דלת של מכונית כמגן. במכה הוא מרים אותה מעל הראש
func _boss_arms(fs: Vector2, head: Vector2, sk: Color, sh_col: Color) -> void:
	var up := _slam_t > 0.0
	var hand := fs + (Vector2(4.0, -24.0) if up else Vector2(14.0, 2.0))
	_arm(fs, hand, sk, sh_col)
	var c := hand + (Vector2(4.0, -6.0) if up else Vector2(6.0, -6.0))
	var rot := -1.2 if up else 0.0
	var door := Transform2D(rot, c) * PackedVector2Array([Vector2(-5, -24), Vector2(4, -26), Vector2(6, 18), Vector2(-4, 20)])
	Art.fill_shaded(self, door, Color("7a3a32"), 0.15, 0.4, Art.OUTLINE, 1.4)
	var win := Transform2D(rot, c) * PackedVector2Array([Vector2(-3, -21), Vector2(3, -22), Vector2(3.5, -6), Vector2(-3, -5)])
	Art.fill(self, win, Color("14181e"), Art.OUTLINE, 0.8)
	draw_line(Transform2D(rot, c) * Vector2(-2, -18), Transform2D(rot, c) * Vector2(2, -9), Color(0.8, 0.85, 0.9, 0.35), 0.6, true)
	draw_line(Transform2D(rot, c) * Vector2(1, 2), Transform2D(rot, c) * Vector2(4, 2), Color("aaaaaa"), 1.2, true)   # ידית
	for i in 3:   # חלודה ופגיעות קליעים
		Art.oval(self, Transform2D(rot, c) * Vector2(-2.0 + float(i) * 2.0, 4.0 + float(i) * 4.0), 1.6, 1.0, Color(0.4, 0.2, 0.08, 0.7), 0.0, Art.NONE)


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
	var w := 7.0 if _big() else (4.2 if kind == RUNNER or kind == SCREAMER else 5.2)
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
	var rx := 8.0 if _big() else 7.2
	var ry := 7.5 if _big() else 8.2
	Art.oval_shaded(self, c, rx, ry, sk, tilt, Art.OUTLINE, 1.4)
	Art.oval(self, c + Vector2(2.5, -0.5), 4.5, 3.0, Color(0.1, 0.0, 0.05, 0.22), 0.1, Art.NONE)   # עיניים שקועות
	draw_line(c + Vector2(-4.0, 2.0), c + Vector2(-1.0, 5.0), Color(0.3, 0.1, 0.3, 0.4), 0.7, true)   # ורידים
	draw_line(c + Vector2(-3.0, -3.0), c + Vector2(-5.0, 0.5), Color(0.3, 0.1, 0.3, 0.4), 0.7, true)
	if kind == SPITTER:   # שק חומצה ירוק נפוח בגרון
		Art.oval(self, c + Vector2(2.0, 8.0), 5.5 + (1.5 if _spit_anim > 0.0 else 0.0), 4.5, Color("8ad040"), 0.0, Art.OUTLINE, 1.0)
		Art.glow(self, c + Vector2(2.0, 8.0), 8.0, Color(0.6, 1.0, 0.2, 0.4))
	# לסת פתוחה
	var jaw_open := 2.0 + sin(_time * 5.0) * 1.0 + (2.5 if _bite_anim > 0.0 else 0.0)
	if kind == SCREAMER and _scream_t > 0.0:
		jaw_open = 7.0
	if kind == SPITTER and _spit_anim > 0.0:
		jaw_open = 5.0
	Art.fill(self, PackedVector2Array([c + Vector2(1.5, 3.0), c + Vector2(7.5, 2.0), c + Vector2(7.0, 3.5 + jaw_open), c + Vector2(2.0, 5.0 + jaw_open)]), Color("2a0a0c"), Art.OUTLINE, 1.0)
	for i in 3:   # שיניים
		var tx := 3.0 + float(i) * 1.6
		Art.fill(self, PackedVector2Array([c + Vector2(tx, 2.7), c + Vector2(tx + 1.2, 2.6), c + Vector2(tx + 0.6, 4.0)]), Color("e0d8b0"), Art.NONE)
	Art.fill(self, PackedVector2Array([c + Vector2(1.5, 5.0 + jaw_open * 0.5), c + Vector2(7.0, 3.5 + jaw_open), c + Vector2(6.0, 6.5 + jaw_open), c + Vector2(1.0, 7.5 + jaw_open * 0.6)]), Art.shade(sk, 0.1), Art.OUTLINE, 1.0)
	# עיניים: אחת זוהרת, אחת שקועה
	Art.oval(self, c + Vector2(0.5, -1.5), 1.6, 1.3, Color("1a0e0e"), 0.0, Art.NONE)
	var eye := c + Vector2(4.5, -1.8)
	Art.oval(self, eye, 2.2, 1.8, Color("1a0e0e"), 0.0, Art.NONE)
	var eye_col := Color(1.0, 0.85, 0.25, 0.8)
	if kind == BOSS:
		eye_col = Color(1.0, 0.15, 0.1, 0.9)
	elif kind == SPITTER:
		eye_col = Color(0.6, 1.0, 0.2, 0.8)
	Art.glow(self, eye, 5.0, eye_col)
	Art.disc(self, eye, 1.2, eye_col.lightened(0.5), Art.NONE)
	draw_line(c + Vector2(2.0, -4.0), c + Vector2(7.0, -3.2), Art.shade(sk, 0.45), 1.4, true)   # גבה
	Art.disc(self, c + Vector2(-2.5, 0.5), 1.8, Art.shade(sk, 0.15), Art.OUTLINE, 0.8)            # אוזן
	match kind:
		BRUTE, BOSS:   # קרחת עם תפרים
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
	var size := 18
	var pop := false       # מספר נזק: "קופץ" בהתחלה
	var life := 1.1
	var t := 0.0
	var _drift := 0.0

	func _ready() -> void:
		z_index = 30
		_drift = randf_range(-12.0, 12.0)

	func _process(delta: float) -> void:
		t += delta
		position += Vector2(_drift, -55.0 + t * 25.0) * delta   # צף למעלה ומאט
		modulate.a = clampf((life - t) / 0.4, 0.0, 1.0)
		if t > life:
			queue_free()
		queue_redraw()

	func _draw() -> void:
		var f := ThemeDB.fallback_font
		var k := 1.0
		if pop:
			k = 1.0 + 0.6 * clampf(1.0 - t / 0.15, 0.0, 1.0)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(k, k))
		var w := f.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
		var pos := Vector2(-w / 2.0, 0.0)
		draw_string_outline(f, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, 5, Color(0, 0, 0, 0.85))
		draw_string(f, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)
