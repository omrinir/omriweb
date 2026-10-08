extends CharacterBody2D
const Sfx := preload("res://sfx.gd")   # אפקטים קוליים
# ============================================================
#  השחקן: דמות עם מעיל ארוך שחור וכובע שחור. נוצר ע"י main.gd.
#  נקודת ה-(0,0) של השחקן היא כפות הרגליים.
#  מקשים:  A/D הליכה | SHIFT ריצה | W/רווח קפיצה | S/CTRL כריעה
#          עכבר = כיוון | לחצן שמאלי = ירי / זריקה | T = רובה/רימון | K = מוות
# ============================================================

signal health_changed(health: int, max_health: int)
signal weapon_changed(weapon: int)
signal died

const Art := preload("res://art.gd")
const BulletScript := preload("res://bullet.gd")
const GrenadeScript := preload("res://grenade.gd")
const MolotovScript := preload("res://weapons/molotov.gd")
const RocketScript := preload("res://weapons/rocket.gd")
const DebrisScript := preload("res://debris.gd")
const PickupScript := preload("res://pickup.gd")
const TextScript := preload("res://zombie.gd")
const HeroAnim := preload("res://hero_anim.gd")       # אנימציות הדמות (SPRITE SHEET)
var HERO_TEX: Texture2D = preload("res://tex_load.gd").get_tex("res://sprites/hero.png")   # נטען בזמן ריצה (לא נשבר אם עוד לא יובא)
const SPRITE_SCALE := 0.44                             # גודל הדמות במשחק (52 פיקסלים = גובה הדמות)

enum { GUN, GRENADE }

# ---- תנועה (אפשר לשנות) ----
var walk_speed := 190.0
var run_speed := 320.0
var crouch_speed := 90.0
var jump_velocity := -620.0      # כמה חזק קופצים (שלילי = למעלה)
var gravity := 1500.0
var accel := 1800.0

# ---- נשק ----
var bullet_speed := 2600.0   # מהיר = פחות זמן לזומבי לזוז לפני הפגיעה
var fire_delay := 0.7            # שניות בין יריות
var grenade_speed := 620.0
var grenade_delay := 0.7
var recoil_push := 70.0          # כמה כל ירייה דוחפת אחורה על הריצפה
var air_recoil_push := 120.0     # כמה כל ירייה דוחפת באוויר (גם למעלה אם יורים למטה)
var air_control := 0.35          # שליטה בתנועה באוויר (קטן = הרתיעה מורגשת יותר)

# ---- חיים ----
var max_health := 5
var health := 5
var invuln_time := 0.8           # שניות שבהן אי אפשר להיפגע שוב

# ---- צבעים (סגנון מנגה: שחור עם קצוות לבנים) ----
var coat_color := Color("0d0d11")
var coat_lining := Color("44444e")
var rim_color := Color("e8e8f0")      # קווי האור הלבנים על המעיל
var pants_color := Color("111115")
var boot_color := Color("08080a")
var glove_color := Color("141418")
## כמה הדמות רזה (1 = רגיל, קטן יותר = רזה יותר)
@export_range(0.5, 1.0) var slim := 0.8
## false = הדמות לא מגיבה למקשים (בתפריט הראשי)
@export var controllable := true
## לאן הדמות מכוונת כשהיא לא נשלטת
var idle_aim := Vector2(-1.0, 0.25).normalized()
var _daze_t := 0.0     # MIRAGE (שלב 17): העתק נגע בך - מסונוור מהחום: איטי, והכוונת רועדת
var auto_walk := 0.0   # כשלא בשליטה (סצנה): כיוון ומהירות הליכה אוטומטית (-1..1)
var calm := false      # בסצנת סיפור: נשימה חלשה (בתקריב הנשימה הרגילה נראית כמו "עלייה")
var unarmed := false   # בסצנת סיפור: בלי נשק וידיים מצוירות - רק הספרייט (הידיים שלו)
## עיניים זוהרות בתוך הברדס (false = רק חושך, כמו בתמונה)
@export var glowing_eyes := false
var eye_color := Color("ff3030")

var world_w := 100000.0          # רוחב העולם (main.gd קובע)
var weapon := GUN
# ---- נשקים: 5 מקומות (גלגל נשקים = TAB, מקשים 1-5, G = לזרוק). לכל נשק תחמושת משלו ----
# הנשקים עצמם מוגדרים ב-weapons/weapon_db.gd (נזק, קצב, מחסנית, טעינה, פיזור...)
const WeaponDB := preload("res://weapons/weapon_db.gd")
const Arsenal := preload("res://progression/arsenal.gd")
const Upgrades := preload("res://progression/upgrade_db.gd")        # שדרוגים שנקנו בחנות (נשקים / יכולות / PERKS)
const AbilityRunnerScript := preload("res://abilities/ability_runner.gd")
var abilities: Node = null       # היכולות (C = הפעלה, 6-0 = בחירה)
var jetpack: RefCounted = null   # abilities/types/jetpack.gd כשהוא דולק
enum { RIFLE, SHOTGUN, BOW, SNIPER, TASER, PISTOL, SMG, ASSAULT_RIFLE, MOLOTOV, GRENADE_LAUNCHER, ASSAULT_SHOTGUN, ROCKET_LAUNCHER }
var slots := []                  # 5 מקומות: {"id", "ammo", "mag"} או null (ammo = הכל, mag = מה שבמחסנית)
var _reload_t := 0.0             # טוען (R / מחסנית ריקה). זומבים חכמים מנצלים את הרגע הזה!
var _reload_total := 1.0
var _mag_out := false            # באמצע טעינה: המחסנית בחוץ (לא מציירים אותה בנשק)
var _kick := 0.0                 # SMG: הקנה עולה מירייה לירייה
var _climbing := false           # על סולם (environment/ladder.gd)
var _drop_t := 0.0               # יורד דרך קומה (S + קפיצה, או S פעמיים מהר)
var _ladder_cd := 0.0            # רגע אחרי שעזבו סולם - לא נתפסים בו שוב מיד
const LADDER_SIDE := 110.0       # מהירות תזוזה הצידה על סולם (A/D)
const LADDER_LET_GO := 0.5       # כמה מהגוף מחוץ לסולם = עוזבים (0.5 = חצי)
var _s_was := false
var _s_tap_t := 9.0              # כמה זמן עבר מהלחיצה הקודמת על S
const DOUBLE_TAP := 0.3          # S פעמיים בתוך הזמן הזה = יורדים מהקומה
var cur_slot := 0
var wheel_open := false          # גלגל הנשקים פתוח: לא יורים
var gun: int:
	get:
		return slots[cur_slot].id if cur_slot < slots.size() and slots[cur_slot] != null else RIFLE
var _scoping := false            # צלף: לחצן ימני = כוונת, הזמן מאט
var _bolts := []                 # טייזר: [נקודות, זמן]
# ---- וו קרס (E) ----
var hook_range := 380.0
var _hook_state := 0             # 0 = אין, 1 = נזרק ופספס, 2 = תפוס
var _hook_pt := Vector2.ZERO
var _hook_len := 0.0
var _hook_t := 0.0
var _e_was := false
var in_water := false            # רכבת תחתית: מים עד הקרסול (subway.gd קובע)
var grabbed_by: Node = null      # יד מהביוב תופסת את הרגל
var _mash := 0
var _mash_last := 0
var dead := false

const W := 22.0
const BREATH_SPEED := 1.6        # מהירות הנשימה
const H_STAND := 52.0
const H_CROUCH := 34.0

var _shape: CollisionShape2D
var _crouching := false
var _crouch_k := 0.0             # 0 = עומד, 1 = כורע (לאנימציה חלקה)
var _cooldown := 0.0
var _melee_t := 0.0             # מכת קת: זמן האנימציה
const MELEE_TIME := 0.28
var melee_damage := 9
var _invuln := 0.0
var _walk_phase := 0.0
var _time := 0.0
var _idle_k := 0.0               # 0 = זז, 1 = עומד במקום (לאנימציית נשימה)
var _breath_was_up := false
var _mist := []                  # (לא בשימוש)
var _magic := []                 # חלקיקי קסם עדינים סביב הדמות: [מיקום בעולם, מהירות, גיל, חיים, גודל, צבע]
var _magic_t := 0.0
var _dust := []                  # אבק מהרגליים בריצה: [מיקום בעולם, מהירות, גיל, חיים, גודל]
var _base_xf := Transform2D.IDENTITY
var _aim := Vector2.RIGHT
var _muzzle_flash := 0.0
var _recoil := 0.0
var _dead_t := 0.0
var _push_t := 0.0
# ---- תחמושת ובוסטים ----
var ammo: int:                   # התחמושת של הנשק שביד
	get:
		return slots[cur_slot].ammo if cur_slot < slots.size() and slots[cur_slot] != null else 0
	set(v):
		if cur_slot < slots.size() and slots[cur_slot] != null:
			slots[cur_slot].ammo = clampi(v, 0, Upgrades.ammo_max(slots[cur_slot].id))
var mag: int:                    # כמה כדורים במחסנית של הנשק שביד
	get:
		if cur_slot >= slots.size() or slots[cur_slot] == null:
			return 0
		var s: Dictionary = slots[cur_slot]
		if not s.has("mag"):
			s["mag"] = mini(int(s.ammo), int(Upgrades.wval(s.id, "magazine_size", 0)))
		return mini(int(s.mag), int(s.ammo))
	set(v):
		if cur_slot < slots.size() and slots[cur_slot] != null:
			slots[cur_slot]["mag"] = maxi(v, 0)
var special := ""               # פריט נפץ שמחזיקים (progression/arsenal.gd -> SPECIALS): grenade / molotov / launcher / rocket
var special_uses := 0           # כמה שימושים נשארו. 0 = נזרק
var _draw_id := -1              # ציור: איזה נשק לצייר ביד (SPECIAL), -1 = הנשק הרגיל
var shield_hits := 0             # כמה פגיעות המגן עוד יספוג
var boosts := {}                 # סוג בוסט -> כמה שניות נשארו
var boost_time := 12.0           # כמה זמן בוסט נמשך
var _rt := 1.0                   # פיצוי על BULLET TIME: השחקן זז במהירות רגילה
var _laser_end := Vector2.ZERO
var _empty_t := 0.0
# ---- תנועה מתקדמת (SKILL) ----
var roll_speed := 430.0
var _roll_t := 0.0               # גלגול: לא נפגעים
var _roll_cd := 0.0
var _roll_dir := 1.0
var _slide_t := 0.0              # החלקה אחרי ריצה + כריעה
var _air_jumps := 1              # קפיצה כפולה
var _jump_was := false
var _crouch_was := false
var _q_was := false
var _running := false            # ריצה: לחיצה כפולה על A / D
var _tap_key := 0
var _tap_t := 0.0
var _a_was := false
var _d_was := false
var _step_t := 0.0               # צעדים (צליל)
var _dist := 0.0                 # כמה הלכנו (לקצב פריימי ההליכה / הריצה)
var _air_t := 0.0
var _land_t := 0.0
var _land_anim := 0.0   # אנימציית נחיתה (כריעה וקימה) - רק ויזואלי
var _flip_t := 0.0      # סלטה בקפיצה הכפולה
const FLIP_T := 0.4
var _hurt_t := 0.0
var _anim := "idle"
var _was_floor := true
var _dodge_slow := 0.0
var _fire_test := false   # לבדיקות אוטומטיות בלבד
# ---- מכשיר שאיבת כוח חיים ----
const DRAIN_TIME := 1.8          # כמה שניות לוקחת השאיבה
var _drain_target: Node = null
var _drain_t := 0.0
var _heal_flash := 0.0
var _device_tip := Vector2.ZERO   # קצה המכשיר (בקואורדינטות הציור)


func _ready() -> void:
	add_to_group("player")
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR   # הספרייט מוקטן - חלק ונקי
	collision_layer = 2   # שכבה 2 = שחקן
	collision_mask = 1 | 16   # מתנגש בעולם (1) ובקומות (16, one-way - S+קפיצה = ירידה)
	_shape = CollisionShape2D.new()
	_shape.shape = RectangleShape2D.new()
	add_child(_shape)
	_set_height(H_STAND)
	z_index = 4
	# תחמושת לפי קושי + שדרוגים
	slots = Game.weapon_slots.duplicate(true)
	var start: int = [40, 30, 22][Settings.difficulty]
	for s in slots:   # בתחילת כל שלב: לרובה יש לפחות את תחמושת ההתחלה
		if s != null and s.id == RIFLE:
			s.ammo = maxi(s.ammo, start)
	for i in slots.size():
		if slots[i] != null:
			cur_slot = i
			break
	for sl in slots:
		if sl != null:
			Game.mark_weapon_seen(int(sl.id))
	boost_time *= 1.0 + 0.3 * Upgrades.perk("long_boosts")
	abilities = AbilityRunnerScript.new()
	abilities.player = self
	add_child(abilities)


func _set_height(h: float) -> void:
	(_shape.shape as RectangleShape2D).size = Vector2(W, h)
	_shape.position = Vector2(0.0, -h / 2.0)


func _height() -> float:
	return H_CROUCH if _crouching else H_STAND


# עומד על קומה (one-way)?
func _on_platform() -> bool:
	for pl in get_tree().get_nodes_in_group("platforms"):
		var r: Rect2 = pl.world_rect()
		if absf(global_position.y - r.position.y) < 4.0 and global_position.x > r.position.x - 4.0 and global_position.x < r.end.x + 4.0:
			return true
	return false


func _ladder_at() -> Node:
	var c := global_position + Vector2(0.0, -14.0)
	for l in get_tree().get_nodes_in_group("ladders"):
		if l.world_rect().has_point(c):
			return l
	return null


# המלבן של הגוף בעולם (משמש לבדיקה אם רגל שנזרקה פגעה בשחקן)
func body_rect() -> Rect2:
	var h := _height()
	return Rect2(global_position + Vector2(-W / 2.0, -h), Vector2(W, h))


func _face() -> float:
	return 1.0 if _aim.x >= 0.0 else -1.0


# הכתף הקדמית (ממנה יוצא הנשק), בקואורדינטות מקומיות
func _front_shoulder() -> Vector2:
	var c := _crouch_k
	return Vector2((3.0 * c + 1.0) * _face(), -37.0 + 15.0 * c)


func _physics_process(delta: float) -> void:
	# BULLET TIME: העולם איטי, אבל השחקן ממשיך במהירות רגילה
	_rt = 1.0 / maxf(Engine.time_scale, 0.05)
	delta *= _rt
	_boosts_process(delta)
	_empty_t -= delta
	_roll_t -= delta
	_roll_cd -= delta
	_slide_t -= delta
	_daze_t = maxf(_daze_t - delta, 0.0)
	if _dodge_slow > 0.0:
		_dodge_slow -= delta
		if _dodge_slow <= 0.0 and not boosts.has(PickupScript.BULLET_TIME):
			Engine.time_scale = 1.0
	Game.player_move = "roll" if _roll_t > 0.0 else ("slide" if _slide_t > 0.0 else ("air" if not is_on_floor() else "ground"))
	_time += delta
	_cooldown -= delta
	_kick = move_toward(_kick, 0.0, delta * 0.5)
	if _reload_t > 0.0:
		var k0 := _reload_k()
		_reload_t -= delta
		_reload_events(k0, _reload_k())
		if _reload_t <= 0.0:
			_finish_reload()
	_melee_t = maxf(_melee_t - delta, 0.0)
	_invuln -= delta
	_muzzle_flash -= delta
	_recoil = move_toward(_recoil, 0.0, delta * 12.0)
	_push_t -= delta
	_heal_flash = move_toward(_heal_flash, 0.0, delta * 0.8)
	_hook_t -= delta
	if _hook_state == 1 and _hook_t < -0.15:
		_hook_state = 0
	for b in _bolts:
		b[1] -= delta
	_bolts = _bolts.filter(func(b): return b[1] > 0.0)

	if not is_on_floor():
		velocity.y += gravity * delta

	if _drain_target != null:
		_drain_process(delta)
		return

	if dead:
		_dead_t += delta
		velocity.x = move_toward(velocity.x, 0.0, accel * delta)
		_move()
		queue_redraw()
		return

	# כריעה
	var want_crouch := controllable and (Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_CTRL))
	# החלקה: רצים (SHIFT) ולוחצים כריעה
	if want_crouch and not _crouch_was and is_on_floor() and absf(velocity.x) > 250.0 and _slide_t <= 0.0:
		_slide_t = 0.55
		Sfx.play("roll", global_position)
		velocity.x = signf(velocity.x) * 470.0
	_crouch_was = want_crouch
	# S פעמיים מהר על קומה עליונה = נופלים דרכה לקומה שמתחת
	var s_now := controllable and Input.is_physical_key_pressed(KEY_S)
	_s_tap_t += delta
	if s_now and not _s_was:
		if _s_tap_t < DOUBLE_TAP and is_on_floor() and _on_platform() and grabbed_by == null:
			collision_mask &= ~16
			_drop_t = 0.25
			velocity.y = 80.0
			_s_tap_t = 9.0
		else:
			_s_tap_t = 0.0
	_s_was = s_now
	# גלגול התחמקות: SHIFT
	var q := controllable and Input.is_physical_key_pressed(KEY_SHIFT)
	if q and not _q_was and _roll_cd <= 0.0 and is_on_floor() and grabbed_by == null:
		_roll_t = 0.35
		_roll_cd = 0.9
		Sfx.play("roll", global_position)
		var dd := 0.0
		if Input.is_physical_key_pressed(KEY_A): dd -= 1.0
		if Input.is_physical_key_pressed(KEY_D): dd += 1.0
		_roll_dir = dd if dd != 0.0 else _face()
	_q_was = q
	want_crouch = want_crouch or _roll_t > 0.0 or _slide_t > 0.0
	if want_crouch and not _crouching:
		_crouching = true
		_set_height(H_CROUCH)
	elif not want_crouch and _crouching and _can_stand():
		_crouching = false
		_set_height(H_STAND)
	_crouch_k = move_toward(_crouch_k, 1.0 if _crouching else 0.0, delta * 8.0)

	# הליכה / ריצה
	var dir := 0.0
	if controllable and Input.is_physical_key_pressed(KEY_A):
		dir -= 1.0
	if controllable and Input.is_physical_key_pressed(KEY_D):
		dir += 1.0
	if not controllable:
		dir = auto_walk
	# ריצה: לחיצה כפולה מהירה על אותו כיוון. נגמרת כשעוזבים את המקש
	var ka := controllable and Input.is_physical_key_pressed(KEY_A)
	var kd := controllable and Input.is_physical_key_pressed(KEY_D)
	_tap_t -= delta
	for k in [[ka, _a_was, -1], [kd, _d_was, 1]]:
		if k[0] and not k[1]:
			_running = _tap_key == k[2] and _tap_t > 0.0
			_tap_key = k[2]
			_tap_t = 0.28
	_a_was = ka
	_d_was = kd
	if dir == 0.0 or (dir < 0.0 and not ka) or (dir > 0.0 and not kd):
		_running = false
	if grabbed_by != null:   # יד מהביוב: לוחצים A/D לסירוגין כדי להשתחרר
		if not is_instance_valid(grabbed_by) or grabbed_by.dead:
			grabbed_by = null
		else:
			var mk := 1 if Input.is_physical_key_pressed(KEY_A) else (2 if Input.is_physical_key_pressed(KEY_D) else 0)
			if mk != 0 and mk != _mash_last:
				_mash += 1
			_mash_last = mk
			dir = 0.0
			if _mash >= 8:
				grabbed_by.release_grab()
				grabbed_by = null
	var speed := walk_speed
	if _crouching:
		speed = crouch_speed
	elif _running:
		speed = run_speed
	if boosts.has(PickupScript.ADRENALINE):
		speed *= 1.4
	if _daze_t > 0.0:   # מסונוור: חצי מהירות
		speed *= 0.5
	if in_water and is_on_floor():   # מים מאטים
		speed *= 0.78
	var acc := accel if is_on_floor() else accel * air_control
	if _push_t > 0.0:   # רגע אחרי ירייה - הדחיפה גוברת על ההליכה
		acc *= 0.25
	if _roll_t > 0.0:
		velocity.x = _roll_dir * roll_speed
	elif _slide_t > 0.0:
		velocity.x = move_toward(velocity.x, 0.0, 500.0 * delta)
	elif _hook_state == 2 and not is_on_floor():   # מתנדנדים על החבל: A/D מוסיפים תנופה
		velocity.x += dir * 520.0 * delta
	else:
		velocity.x = move_toward(velocity.x, dir * speed, acc * delta)

	# ---- סולם: W / S = טיפוס, SPACE = קפיצה מהסולם ----
	if _drop_t > 0.0:
		_drop_t -= delta
		if _drop_t <= 0.0 and not _climbing:
			collision_mask |= 16
	_ladder_cd -= delta
	var lad := _ladder_at()
	var kw := controllable and Input.is_physical_key_pressed(KEY_W)
	var ks := controllable and Input.is_physical_key_pressed(KEY_S)
	if lad != null and not _climbing and grabbed_by == null and _hook_state != 2 and _ladder_cd <= 0.0 and (kw or (ks and _on_platform())):
		_climbing = true
		_jump_was = true
	if _climbing:
		var ksp := controllable and Input.is_physical_key_pressed(KEY_SPACE)
		# כמה מהגוף עוד על הסולם (A/D מזיזים הצידה - חצי בחוץ = עוזבים / קופצים)
		var inside := 0.0
		if lad != null:
			var lr: Rect2 = lad.world_rect()
			var x0 := global_position.x - W * 0.5
			var x1 := global_position.x + W * 0.5
			inside = maxf(0.0, minf(x1, lr.end.x) - maxf(x0, lr.position.x)) / W
		var jump_off: bool = ksp and not _jump_was
		if lad == null or jump_off or (inside <= LADDER_LET_GO and dir != 0.0):
			_climbing = false
			_ladder_cd = 0.35
			collision_mask |= 16
			if lad != null and (jump_off or kw or ksp):   # קפיצה מהסולם לכיוון שאליו זזים
				velocity.y = jump_velocity * (0.8 if dir == 0.0 else 0.85)
				velocity.x = dir * speed
				_air_jumps = 1
				_jump_was = true
			elif lad != null:   # רק עוזבים (נופלים) הצידה
				velocity = Vector2(dir * speed * 0.7, 0.0)
		else:
			collision_mask &= ~16
			var cdir := (-1.0 if kw else 0.0) + (1.0 if ks else 0.0)
			velocity = Vector2(dir * LADDER_SIDE, cdir * 170.0)
			if dir == 0.0:   # בלי A/D: מתיישר בעדינות למרכז הסולם
				global_position.x = move_toward(global_position.x, lad.global_position.x, 50.0 * delta)
			if kw and global_position.y <= lad.top_y() + 2.0:   # הגיע למעלה: עולה על הקומה
				global_position.y = lad.top_y()
				velocity.y = 0.0
				_climbing = false
				collision_mask |= 16
			elif ks and is_on_floor() and global_position.y >= lad.global_position.y - 2.0:
				_climbing = false
				collision_mask |= 16
			_jump_was = ksp
			_move()
			queue_redraw()
			return
	# קפיצה
	var jump := controllable and (Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_SPACE))
	# S + קפיצה על קומה = יורדים דרכה
	if jump and not _jump_was and _crouching and is_on_floor() and _on_platform():
		collision_mask &= ~16
		_drop_t = 0.25
		velocity.y = 80.0
		_jump_was = true
		jump = false
	if is_on_floor():
		_air_jumps = 1
	jump = jump and grabbed_by == null
	if jump and not _jump_was:
		if _hook_state == 2:   # עוזבים את החבל = זינוק
			_hook_state = 0
			velocity.y = minf(velocity.y, 0.0) - 330.0
			_air_jumps = 1
		elif is_on_floor() and not _crouching:
			velocity.y = jump_velocity
			Sfx.play("jump", global_position, -4.0)
			_jump_zoom(JUMP_ZOOM)
		elif not is_on_floor() and _air_jumps > 0:   # קפיצה כפולה
			_air_jumps -= 1
			velocity.y = jump_velocity * 0.85
			Sfx.play("whoosh", global_position, -2.0)
			_jump_zoom(DOUBLE_JUMP_ZOOM)
			_flip_t = FLIP_T
			preload("res://particles.gd").burst(get_parent(), global_position, "smoke", Vector2.DOWN, 6)
	_jump_was = jump

	# וו קרס: E זורק / משחרר
	var e := controllable and Input.is_physical_key_pressed(KEY_F)   # וו קרס: F
	if e and not _e_was and not dead:
		if _hook_state == 2:
			_hook_state = 0
		else:
			_throw_hook()
	_e_was = e
	if _hook_state == 2:
		_hook_process(delta)

	if jetpack != null and not dead and _drain_target == null:   # JETPACK: דחף / ריחוף
		jetpack.fly(delta)
	var fall_v := velocity.y
	_move()
	global_position.x = clampf(global_position.x, W, world_w - W)
	if fall_v > 120.0:
		_try_stomp()
	# קצב האנימציה
	_hurt_t -= delta
	_land_t -= delta
	_land_anim -= delta
	_flip_t -= delta
	if is_on_floor():
		_dist += absf(velocity.x) * delta
		_air_t = 0.0
	else:
		_air_t += delta
	# צלילי צעדים (מים ברכבת התחתית) ונחיתה
	if is_on_floor() and absf(velocity.x) > 40.0 and _roll_t <= 0.0 and _slide_t <= 0.0:
		_step_t -= delta * absf(velocity.x) / 190.0
		if _step_t <= 0.0:
			_step_t = 0.36
			Sfx.play("step_water" if in_water else "step", global_position, (-1.0 if _running else -5.0) if in_water else (-3.0 if _running else -7.0), 0.15, 3)
			if _running and not in_water and _dust.size() < 24:   # ריצה: אבק נבעט אחורה מכף הרגל
				var back := -signf(velocity.x)
				for i in 3:
					_dust.append([global_position + Vector2(back * randf_range(2.0, 8.0), -1.5), Vector2(back * randf_range(25.0, 70.0), randf_range(-28.0, -8.0)), 0.0, randf_range(0.35, 0.55), randf_range(2.0, 3.6)])
	if is_on_floor() and not _was_floor and fall_v > 120.0:
		_land_anim = 0.3 if fall_v > 250.0 else 0.16
		_flip_t = 0.0
	if is_on_floor() and not _was_floor and fall_v > 250.0:
		_land_t = 0.12   # פריים נחיתה
		Sfx.play("splash" if in_water else "land", global_position, -2.0)
	_was_floor = is_on_floor()

	if is_on_floor() and absf(velocity.x) > 10.0:
		_walk_phase += delta * absf(velocity.x) * 0.055
	else:
		_walk_phase = move_toward(_walk_phase, roundf(_walk_phase / PI) * PI, delta * 6.0)

	# עמידה במקום: נשימה + אדים יוצאים מהברדס בכל נשיפה
	var standing := is_on_floor() and absf(velocity.x) < 10.0 and not _crouching
	_idle_k = move_toward(_idle_k, 1.0 if standing else 0.0, delta * 3.0)
	var up := cos(_time * BREATH_SPEED) > 0.0
	_breath_was_up = up
	# חלקיקי קסם: עולים לאט מסביב לגוף ונשארים קצת מאחור כשהוא זז
	_magic_t -= delta
	while _magic_t <= 0.0 and not dead:
		_magic_t += 0.055
		var off := Vector2(randf_range(-11.0, 11.0), randf_range(-50.0, -6.0))
		var cols := [Color(0.6, 0.75, 1.0), Color(0.75, 0.6, 1.0), Color(0.55, 0.95, 0.95)]
		_magic.append([global_position + off, Vector2(randf_range(-6.0, 6.0), randf_range(-22.0, -10.0)), 0.0, randf_range(1.0, 1.8), randf_range(0.6, 1.3), cols[randi() % cols.size()]])
	for m in _magic:
		m[2] += delta
		m[1].x += sin(_time * 2.0 + m[4] * 9.0) * 10.0 * delta   # מתפתל קצת
		m[0] += m[1] * delta
	_magic = _magic.filter(func(m): return m[2] < m[3])
	for d in _dust:
		d[2] += delta
		d[1] *= 1.0 - 3.0 * delta
		d[0] += d[1] * delta
		d[4] += delta * 5.0   # מתפשט
	_dust = _dust.filter(func(d): return d[2] < d[3])

	# כיוון ויריה
	var sh := global_position + _front_shoulder()
	var to_mouse := get_global_mouse_position() - sh
	if not controllable:
		_aim = idle_aim
	elif to_mouse.length() > 4.0 and not _fire_test:
		_aim = to_mouse.normalized()
		if _daze_t > 0.0:   # מסונוור: הכוונת רועדת
			_aim = _aim.rotated(sin(_time * 7.0) * 0.16 + sin(_time * 11.3) * 0.07)
	var trigger := controllable and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and not get_tree().paused and not wheel_open
	# צלף: לחצן ימני = כוונת והזמן מאט
	var scope := controllable and weapon == GUN and gun == SNIPER and not wheel_open and Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT) and not get_tree().paused
	if scope != _scoping:
		_scoping = scope
		if scope:
			Engine.time_scale = 0.5
		elif not boosts.has(PickupScript.BULLET_TIME) and _dodge_slow <= 0.0:
			Engine.time_scale = 1.0
	if (trigger or _fire_test) and _cooldown <= 0.0:
		_fire()
	_fire_test = false
	_update_laser(sh)

	queue_redraw()


# נחיתה על ראש זומבי: 20 נזק ומקפיץ אותך הצידה. פעם אחת לכל זומבי:
# נחיתה שנייה על אותו זומבי (אחרי STOMP_GRACE) = אתה נפגע ונזרק ממנו.
const STOMP_GRACE := 0.6   # שניות (זמן משחק) אחרי רמיסה שבהן נחיתה חוזרת על אותו ראש רק מקפיצה (לא נחשבת)


func _try_stomp() -> void:
	for z in get_tree().get_nodes_in_group("zombies"):
		if z.dead or z._lying():
			continue
		var top: float = z.global_position.y - 60.0 * z.sc
		if absf(z.global_position.x - global_position.x) < 18.0 * z.wf and absf(global_position.y - top) < 16.0:
			var dx: float = global_position.x - z.global_position.x
			var side: float = signf(dx) if absf(dx) > 2.0 else (signf(velocity.x) if absf(velocity.x) > 10.0 else _face())
			_push_t = 0.45   # הדחיפה הצידה גוברת על השליטה באוויר - יורדים מהראש שלו
			if z.has_meta("stomped"):
				velocity.y = jump_velocity * 0.55
				velocity.x = side * 240.0
				if _time - float(z.get_meta("stomped")) > STOMP_GRACE:   # פעם שנייה: הוא תופס אותך
					hurt(1, Vector2(side, -0.6))
					velocity.x = side * 260.0
					_say("NOT AGAIN!", Color("ff5a4a"))
					Game.story.emit("stomp_hurt", {})
				return
			z.set_meta("stomped", _time)
			z.take_damage(20, global_position, Vector2(_face(), 0.4), true, {"source": "stomp"})
			Sfx.play("land", global_position, 3.0)
			velocity.y = jump_velocity * 0.8
			velocity.x = side * maxf(absf(velocity.x), 200.0)
			_air_jumps = 1
			_say("STOMP", Color("ffd34a"))
			preload("res://particles.gd").burst(get_parent(), global_position, "hit", Vector2.UP, 12)
			return


func _move() -> void:
	velocity *= _rt
	move_and_slide()
	velocity /= _rt


# ============================================================
#  בוסטים, תחמושת, איסוף
# ============================================================
func _boosts_process(delta: float) -> void:
	for b in boosts.keys():
		boosts[b] -= delta
		if boosts[b] <= 0.0:
			boosts.erase(b)
			if b == PickupScript.BULLET_TIME:
				Engine.time_scale = 1.0


func activate_boost(b: int) -> void:
	if b == PickupScript.SHIELD:
		shield_hits += 2
		return
	boosts[b] = boost_time
	if b == PickupScript.BULLET_TIME:
		Engine.time_scale = 0.4


# pickup.gd קורא לזה כשעוברים על חפץ
func collect(p: Node) -> bool:
	if dead:
		return false
	match p.kind:
		PickupScript.AMMO:
			Game.story.emit("ammo", {"was_empty": weapon == GUN and ammo <= 0})
			_ammo_box(1)
			Sfx.play("pickup", null)
		PickupScript.GRENADE:   # (ישן) = רימונים
			take_special("grenade")
			return true
		PickupScript.SPECIAL:
			take_special(p.special)
			return true
		PickupScript.SUPPLY:
			_ammo_box(3)
			Sfx.play("pickup", null)
		PickupScript.BOOST:
			activate_boost(p.boost)
			Sfx.play("boost", null)
		PickupScript.WEAPON:
			return _take_weapon(p)
		PickupScript.HEALTH:   # +1 לב (מלא = משאירים על הרצפה)
			if health >= max_health:
				return false
			health = mini(health + 1, max_health)
			health_changed.emit(health, max_health)
			_heal_flash = 1.0
			Sfx.play("heal", null)
	_say(p.label(), p.color())
	return true


# MIRAGE: מסונוור מהחום ל-t שניות
func daze(t: float) -> void:
	if dead:
		return
	if _daze_t <= 0.0:
		_say("DAZED BY THE HEAT", Color(1.0, 0.85, 0.5))
	_daze_t = maxf(_daze_t, t)


func is_dazed() -> bool:
	return _daze_t > 0.0


func _say(text: String, col: Color) -> void:
	var t = TextScript.HitText.new()
	t.text = text
	t.color = col
	t.size = 16
	get_parent().add_child(t)
	t.global_position = global_position + Vector2(0, -74)


func has_boost(b: int) -> bool:
	return boosts.has(b)


# קו לייזר (שדרוג): עד הפגיעה הראשונה
func _update_laser(sh: Vector2) -> void:
	if (Upgrades.perk("laser_sight") == 0 and not _scoping) or not controllable:
		return
	var from := sh + _aim * 30.0
	var to := from + _aim * 650.0
	var q := PhysicsRayQueryParameters2D.create(from, to, 5)
	var hit := get_world_2d().direct_space_state.intersect_ray(q)
	_laser_end = hit.position if hit else to


func _can_stand() -> bool:
	var rect := RectangleShape2D.new()
	rect.size = Vector2(W - 2.0, H_STAND - 2.0)
	var q := PhysicsShapeQueryParameters2D.new()
	q.shape = rect
	q.transform = Transform2D(0.0, global_position + Vector2(0.0, -H_STAND / 2.0 - 1.0))
	q.collision_mask = 1
	q.exclude = [get_rid()]
	return get_world_2d().direct_space_state.intersect_shape(q, 1).is_empty()


func _fire() -> void:
	# ניצולה ממש קרובה? במקום לירות - מפעילים את המכשיר
	var s := _drain_candidate()
	if s != null:
		_start_drain(s)
		return
	var sh := global_position + _front_shoulder()
	if weapon == GUN and _try_melee():
		return
	if weapon == GUN:
		var w: Dictionary = Upgrades.weapon_def(gun)   # הנשק אחרי השדרוגים
		var msize: int = w.get("magazine_size", 0)
		if _reload_t > 0.0:
			return
		if ammo <= 0:
			_cooldown = 0.3
			Sfx.play("empty", global_position)
			if _empty_t <= 0.0:
				_empty_t = 1.0
				_say("NO AMMO", Color("ff6050"))
				Game.story.emit("no_ammo", {})
			return
		if msize > 0 and mag <= 0:   # מחסנית ריקה: טוענים
			reload()
			return
		ammo -= 1
		if msize > 0:
			mag -= 1
		var proj: String = w.get("projectile", "bullet")
		Sfx.play(w.get("sound", "rifle"), global_position, w.get("sound_db", 0.0))
		Game.on_shot()
		PlayerMemory.on_shot(gun)
		Game.make_noise(global_position, 380.0)   # יריות מעירות זומבים מסביב
		# שדרוג קצב אש (בחנות) משפיע על כל הנשקים
		_cooldown = float(w.fire_rate) * (0.5 if boosts.has(PickupScript.ADRENALINE) else 1.0)
		_muzzle_flash = 0.0 if proj == "arrow" or proj == "molotov" else 0.05
		_recoil = 1.0
		# רתיעה: הירייה דוחפת את הדמות הפוך לכיוון הקנה
		var rk: float = w.get("recoil", 1.0)
		if is_on_floor():
			velocity.x -= _aim.x * recoil_push * rk
		elif rk > 0.0:
			velocity -= _aim * air_recoil_push * minf(rk, 1.2)
			velocity.y = maxf(velocity.y, -700.0)
		_push_t = 0.12
		get_tree().call_group("zombies", "on_player_fired", sh, _aim)
		if proj == "bullet":
			_eject_casing(sh)
		match proj:
			"taser":
				_taser(sh)
				return
		# קליעים: רובה / שוטגאן / צלף / SMG / קשת...
		var kick: float = w.get("kick", 0.0)
		var aim := _aim.rotated(-_face() * _kick) if kick > 0.0 else _aim   # SMG: הקנה מטפס
		_kick = minf(_kick + kick, 0.22)
		var n: int = w.get("pellets", 1)
		var sp: float = w.get("spread", 0.0)
		for i in n:
			var b = BulletScript.new()
			get_parent().add_child(b)
			var spread := randf_range(-sp, sp)
			b.pierce = int(w.get("pierce", 0)) + (3 if boosts.has(PickupScript.PIERCING) else 0)
			b.incendiary = boosts.has(PickupScript.INCENDIARY)
			b.dmg_mult = w.get("damage", 1.0)
			b.head_mult = w.get("head_mult", 1.0)
			b.knockback = w.get("knockback", 60.0)
			b.weapon_id = gun
			b.shot = Game.shot_id   # כל הכדורים של אותה ירייה = ירייה אחת לדיוק
			b.sniper = w.get("sniper", false)
			var spd: float = w.get("bullet_speed", bullet_speed)
			if w.has("falloff"):
				b.falloff = w.falloff
				spd *= randf_range(0.85, 1.0)
			if proj == "arrow":   # חץ: עף בקשת
				b.arrow = true
				b.gravity = 900.0
			if w.has("fixed_damage"):
				b.fixed_damage = w.fixed_damage
			b.life_time = float(w.get("range", 1800.0)) / spd
			b.setup(sh + aim * 30.0, aim.rotated(spread) * spd, sh)
	else:
		_use_special(sh)


# ============================================================
#  SPECIAL ITEMS (progression/arsenal.gd -> SPECIALS): רימונים / מולוטוב / משגר רימונים / משגר טילים.
#  מוצאים בשלב, E = מחליף אליהם, ירייה = שימוש. אחרי השימוש האחרון - נזרקים וחוזרים לנשק.
# ============================================================
func take_special(kind: String) -> void:
	var info: Dictionary = Arsenal.SPECIALS[kind]
	var n: int = int(info.uses) + Upgrades.perk("grenade_pouch")
	if special == kind:
		special_uses += n
	else:
		special = kind   # מחליף את מה שהיה (הישן נזרק)
		special_uses = n
	Sfx.play("weapon", null)
	_say("+%s  x%d   (E)" % [info.name, special_uses], info.color)


func _special_weapon() -> int:   # איזה נשק מ-weapon_db מייצג את הפריט (לנתונים ולציור), -1 = רימון / אין
	return int(Arsenal.SPECIALS[special].weapon) if special != "" else -1


func _use_special(sh: Vector2) -> void:
	if special == "" or special_uses <= 0:
		weapon = GUN
		weapon_changed.emit(weapon)
		return
	var wid := _special_weapon()
	var w: Dictionary = WeaponDB.WEAPONS[wid] if wid >= 0 else {}
	PlayerMemory.on_explosive()
	Game.make_noise(global_position, 380.0)
	match special:
		"grenade":
			Game.story.emit("grenade", {})
			Sfx.play("throw", global_position)
			_cooldown = grenade_delay
			var g = GrenadeScript.new()
			get_parent().add_child(g)
			g.setup(sh + _aim * 14.0, _aim * grenade_speed + velocity * 0.3)
		"molotov":   # בקבוק תבערה: נשבר ומשאיר שטח בוער
			Sfx.play("throw", global_position)
			_cooldown = float(w.get("fire_rate", 0.9))
			var mo = MolotovScript.new()
			get_parent().add_child(mo)
			mo.setup(sh + _aim * 12.0, _aim * float(w.get("bullet_speed", 640.0)) + Vector2(0.0, -120.0) + velocity * 0.3)
		"launcher":   # משגר רימונים: מתפוצץ במגע
			Sfx.play(str(w.get("sound", "launcher")), global_position)
			_cooldown = float(w.get("fire_rate", 1.1))
			_muzzle_flash = 0.05
			_recoil = 1.0
			var gl = GrenadeScript.new()
			gl.impact = true
			gl.gravity = 650.0
			gl.radius = 110.0
			gl.damage = 45
			get_parent().add_child(gl)
			gl.setup(sh + _aim * float(w.get("barrel", 24.0)), _aim * float(w.get("bullet_speed", 950.0)))
		"rocket":   # משגר טילים: טיל אחד שמתפצל ל-3
			Sfx.play(str(w.get("sound", "rocket")), global_position)
			_cooldown = float(w.get("fire_rate", 1.0))
			_muzzle_flash = 0.05
			_recoil = 1.0
			if is_on_floor():
				velocity.x -= _aim.x * recoil_push * 1.3
			var rkt = RocketScript.new()
			get_parent().add_child(rkt)
			rkt.setup(sh + _aim * float(w.get("barrel", 30.0)), _aim * float(w.get("bullet_speed", 640.0)))
	special_uses -= 1
	if special_uses <= 0:   # נגמר: זורקים וחוזרים לנשק
		_say("%s  -  EMPTY" % Arsenal.SPECIALS[special].name, Color(1, 1, 1, 0.75))
		special = ""
		special_uses = 0
		weapon = GUN
		weapon_changed.emit(weapon)


# ============================================================
#  טעינה (R, או אוטומטית כשהמחסנית ריקה). זמן הטעינה ב-weapon_db.gd
# ============================================================
func reload() -> void:
	if weapon != GUN or _reload_t > 0.0 or dead:
		return
	var msize: int = Upgrades.wval(gun, "magazine_size", 0)
	if msize <= 0 or mag >= mini(msize, ammo):
		return
	_reload_total = float(Upgrades.wval(gun, "reload_time", 1.5)) * (0.6 if boosts.has(PickupScript.ADRENALINE) else 1.0)
	_reload_t = _reload_total
	_play_reload_sound()
	PlayerMemory.on_reload()
	Game.story.emit("reload", {})


# צליל הטעינה: קובץ אמיתי (sounds/reload.mp3, ~1 שנייה). להחלפה: לשים קובץ אחר באותו שם.
# נטען בזמן ריצה (לא preload) כדי שהמשחק ייפתח גם אם הקובץ חסר / עוד לא יובא ע"י העורך:
# קודם משאב מיובא, אחרת קריאת בתים ישירה של ה-MP3, ואם אין קובץ בכלל - צליל סינתטי.
const RELOAD_PATH := "res://sounds/reload.mp3"
static var _reload_stream: AudioStream = null
static var _reload_tried := false

static func _reload_sfx() -> AudioStream:
	if _reload_tried:
		return _reload_stream
	_reload_tried = true
	if ResourceLoader.exists(RELOAD_PATH):
		_reload_stream = load(RELOAD_PATH) as AudioStream
	if _reload_stream == null and FileAccess.file_exists(RELOAD_PATH):
		var mp3 := AudioStreamMP3.new()
		mp3.data = FileAccess.get_file_as_bytes(RELOAD_PATH)
		_reload_stream = mp3
	return _reload_stream

func _play_reload_sound() -> void:
	var st := _reload_sfx()
	if st == null:
		Sfx.play("reload", global_position)
		return
	var a := AudioStreamPlayer2D.new()
	a.stream = st
	a.bus = "SFX"
	a.volume_db = Sfx.volume_db - 2.0
	a.max_distance = 1500.0
	if st.get_length() > 0.0:   # טעינה קצרה: הצליל מהיר יותר כדי להיגמר בזמן
		a.pitch_scale = clampf(st.get_length() / maxf(_reload_total * 1.05, 0.1), 1.0, 1.6)
	add_child(a)
	a.play()
	a.finished.connect(a.queue_free)


func _finish_reload() -> void:
	mag = mini(int(Upgrades.wval(gun, "magazine_size", 0)), ammo)


# זום קטן של המצלמה בקפיצה (ויותר בקפיצה כפולה). 0 = לבטל
const JUMP_ZOOM := 0.085
const DOUBLE_JUMP_ZOOM := 0.16
func _jump_zoom(amount: float) -> void:
	var cam := get_viewport().get_camera_2d()
	if cam != null and cam.has_method("punch_zoom"):
		cam.punch_zoom(amount)


func is_reloading() -> bool:
	return _reload_t > 0.0


# רגע פגיע: טוען, נתפס, נפגע הרגע, או נוחת (זומבים חכמים מחכים לרגעים האלה)
func is_vulnerable() -> bool:
	return _reload_t > 0.0 or grabbed_by != null or _hurt_t > 0.0 or (_land_t > 0.0) or (ammo <= 0 and weapon == GUN)


# ============================================================
#  מקומות לנשקים
# ============================================================
func select_slot(i: int) -> void:
	if i < 0 or i >= slots.size() or slots[i] == null:
		return
	cur_slot = i
	weapon = GUN
	_reload_t = 0.0   # החלפת נשק מבטלת טעינה
	weapon_changed.emit(weapon)
	Sfx.play("weapon", null, -6.0)
	_say(Game.WEAPON_NAMES[gun], Game.WEAPON_COLORS[gun])


# קופסת תחמושת: כל נשק מקבל את הכמות שלו
func _ammo_box(mult: int) -> void:
	for s in slots:
		if s != null:
			var box := int(round(float(Game.AMMO_BOX[s.id] * mult) * (1.0 + 0.25 * Upgrades.perk("scavenger"))))
			s.ammo = mini(s.ammo + box, Upgrades.ammo_max(s.id))


# מוסיף תחמושת לנשק מסוים (למשל חץ שנאסף). false = אין את הנשק / מלא
func add_ammo(id: int, n: int) -> bool:
	for s in slots:
		if s != null and s.id == id and s.ammo < Upgrades.ammo_max(id):
			s.ammo += n
			return true
	return false


func _take_weapon(p: Node) -> bool:
	var amt: int = p.ammo_amount if p.ammo_amount >= 0 else Game.AMMO_START[p.weapon_id]
	for s in slots:   # כבר יש את הנשק: רק תחמושת
		if s != null and s.id == p.weapon_id:
			s.ammo = mini(s.ammo + amt, Upgrades.ammo_max(s.id))
			_say("+%d %s" % [amt, Game.WEAPON_NAMES[s.id]], p.color())
			Sfx.play("pickup", null)
			return true
	for i in slots.size():
		if slots[i] == null:
			slots[i] = {"id": p.weapon_id, "ammo": amt}
			Game.mark_weapon_seen(p.weapon_id)
			Game.story.emit("new_weapon", {"id": p.weapon_id})
			Sfx.play("weapon", null)
			select_slot(i)
			_say(p.label(), p.color())
			return true
	if _empty_t <= 0.0:
		_empty_t = 1.5
		_say("SLOTS FULL  -  G = DROP WEAPON", Color("ff6050"))
	return false


# זורק נשק לריצפה (מפנה מקום לנשק אחר)
func drop_weapon(i: int) -> void:
	if i < 0 or i >= slots.size() or slots[i] == null:
		return
	var count := 0
	for s in slots:
		if s != null:
			count += 1
	if count <= 1:
		_say("CAN'T DROP YOUR LAST WEAPON", Color("ff6050"))
		return
	var p = PickupScript.new()
	p.kind = PickupScript.WEAPON
	p.weapon_id = slots[i].id
	p.ammo_amount = slots[i].ammo
	p.pick_delay = 1.2
	p.life = 60.0
	get_parent().add_child(p)
	p.setup(global_position + Vector2(0.0, -30.0), Vector2(_face() * 170.0, -260.0))
	Sfx.play("throw", global_position)
	slots[i] = null
	if i == cur_slot:
		for j in slots.size():
			if slots[j] != null:
				select_slot(j)
				break


# ---- טייזר: ברק שקופץ מזומבי לזומבי (פי 3 במים) ----
func _taser(sh: Vector2) -> void:
	var from := sh + _aim * 30.0
	var pts := PackedVector2Array([from])
	var best: Node = null
	var bd := 330.0
	for z in get_tree().get_nodes_in_group("zombies"):
		if z.dead:
			continue
		var d: Vector2 = z.global_position + Vector2(0.0, -30.0 * z.sc) - from
		if d.length() < bd and absf(d.angle_to(_aim)) < 0.4:
			bd = d.length()
			best = z
	if best == null:   # אין מטרה: ניצוץ קצר באוויר
		pts.append(from + _aim.rotated(randf_range(-0.2, 0.2)) * 110.0)
		_bolts.append([pts, 0.12])
		return
	var hit := []
	var cur := from
	var z: Node = best
	for k in 4:
		hit.append(z)
		var zc: Vector2 = z.global_position + Vector2(0.0, -30.0 * z.sc)
		pts.append(zc)
		var wet: bool = in_water and z.is_on_floor()
		z.take_damage(int(round((24.0 if wet else 8.0) * float(Upgrades.wval(TASER, "damage", 1.0)))), zc, (zc - cur).normalized(), true, {"source": "taser", "shot": Game.shot_id})
		cur = zc
		var nxt: Node = null
		var nd := 150.0
		for o in get_tree().get_nodes_in_group("zombies"):
			if o.dead or o in hit:
				continue
			var od: float = (o.global_position + Vector2(0.0, -30.0 * o.sc)).distance_to(cur)
			if od < nd:
				nd = od
				nxt = o
		if nxt == null:
			break
		z = nxt
	_bolts.append([pts, 0.15])


# ---- וו קרס ----
func _throw_hook() -> void:
	var sh := global_position + _front_shoulder()
	var to := sh + _aim * hook_range
	var hit := get_world_2d().direct_space_state.intersect_ray(PhysicsRayQueryParameters2D.create(sh, to, 1))
	var pt := Vector2.INF
	if hit:
		pt = hit.position
	for lp in get_tree().get_nodes_in_group("lamps"):   # אפשר להיתפס גם בפנס
		var hp: Vector2 = lp.global_position + lp.head()
		if Geometry2D.get_closest_point_to_segment(hp, sh, to).distance_to(hp) < 16.0 and (pt == Vector2.INF or sh.distance_to(hp) < sh.distance_to(pt)):
			pt = hp
	_hook_t = 0.12
	Sfx.play("hook", global_position)
	if pt == Vector2.INF:
		_hook_state = 1
		_hook_pt = to
		return
	_hook_state = 2
	_hook_pt = pt
	_hook_len = maxf((global_position + Vector2(0.0, -30.0)).distance_to(pt) * 0.85, 50.0)
	if is_on_floor():
		velocity.y = -220.0   # קופץ מהריצפה אל החבל


func _hook_process(delta: float) -> void:
	var c := global_position + Vector2(0.0, -30.0)
	var r := c - _hook_pt
	var dist := r.length()
	if dist > hook_range * 1.5 or dist < 1.0:
		_hook_state = 0
		return
	_hook_len = maxf(_hook_len - 90.0 * delta, 45.0)   # מושך קצת למעלה
	if dist > _hook_len:
		var n := r / dist
		var vr := velocity.dot(n)
		if vr > 0.0:
			velocity -= n * vr
		global_position -= n * minf(dist - _hook_len, 400.0 * delta)


# יד מהביוב תפסה את הרגל
func grab(by: Node) -> void:
	grabbed_by = by
	_mash = 0
	Game.story.emit("grabbed", {"z": by})
	_mash_last = 0
	_hook_state = 0
	_say("SHAKE FREE!  A / D", Color("ff6050"))


# זומבי צמוד מלפנים? במקום לירות - מכה עם הקת
func _try_melee() -> bool:
	var face := _face()
	var target: Node = null
	var best := INF
	for z in get_tree().get_nodes_in_group("zombies"):
		if z.dead:
			continue
		var d: Vector2 = z.global_position - global_position
		var reach: float = 34.0 + 14.0 * z.wf * z.sc
		if d.x * face > -6.0 and absf(d.x) < reach and absf(d.y) < 45.0 and absf(d.x) < best:
			best = absf(d.x)
			target = z
	if target == null:
		return false
	_melee_t = MELEE_TIME
	_cooldown = 0.45
	var dir := Vector2(face, -0.2).normalized()
	var hp_pos: Vector2 = target.global_position + Vector2(-face * 8.0, -36.0 * target.sc)
	target.take_damage(melee_damage, hp_pos, dir, true, {"source": "melee"})
	Sfx.play("melee", global_position)
	if not target.dead and not target.is_boss():
		target.velocity.x += face * 220.0
	Game.make_noise(global_position, 120.0)
	var cam := get_viewport().get_camera_2d()
	if cam != null and cam.has_method("shake"):
		cam.shake(3.0, 0.12)
	return true


# תרמיל נחושת שעף מהרובה אחרי כל ירייה
func _eject_casing(sh: Vector2) -> void:
	var c = DebrisScript.new()
	get_parent().add_child(c)
	var up := Vector2(-_aim.x, -1.0).normalized()
	c.setup(sh + _aim * 14.0, Vector2(3.5, 1.6), Color("c8a040"), up * randf_range(140.0, 220.0) + velocity * 0.3)


func _unhandled_input(event: InputEvent) -> void:
	if not controllable or not (event is InputEventKey and event.pressed and not event.echo):
		return
	if event.physical_keycode == KEY_E and not dead:   # E = נשק / פריט נפץ (אם יש)
		if special == "" and weapon == GUN:
			if _empty_t <= 0.0:
				_empty_t = 1.0
				_say("NO SPECIAL ITEM", Color(1, 1, 1, 0.7))
		else:
			weapon = GRENADE if weapon == GUN else GUN
			weapon_changed.emit(weapon)
	elif event.physical_keycode >= KEY_1 and event.physical_keycode <= KEY_5 and not dead:
		select_slot(event.physical_keycode - KEY_1)
	elif event.physical_keycode == KEY_G and not dead and not wheel_open:
		drop_weapon(cur_slot)
	elif event.physical_keycode == KEY_R and not dead:   # R = טעינה
		reload()
	elif event.physical_keycode == KEY_K:
		_invuln = 0.0
		hurt(health, Vector2.ZERO)


# ============================================================
#  שאיבת כוח חיים מניצולה -> חיים מלאים
# ============================================================
func _drain_candidate() -> Node:
	var best: Node = null
	var best_d := INF
	for s in get_tree().get_nodes_in_group("survivors"):
		if s.can_drain(self):
			var d := absf(s.global_position.x - global_position.x)
			if d < best_d:
				best_d = d
				best = s
	return best


func _start_drain(s: Node) -> void:
	Game.story.emit("drain", {"s": s})
	_drain_target = s
	_drain_t = 0.0
	_cooldown = DRAIN_TIME
	s.start_drain()


func _drain_process(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, accel * delta)
	_move()
	_idle_k = move_toward(_idle_k, 0.0, delta * 3.0)
	if not is_instance_valid(_drain_target):
		_drain_target = null
		return
	var to: Vector2 = _drain_target.chest() - (global_position + _front_shoulder())
	if to.length() > 1.0:
		_aim = to.normalized()
	_drain_t += delta
	var k := clampf(_drain_t / DRAIN_TIME, 0.0, 1.0)
	_drain_target.set_drain(k)
	if k >= 1.0:
		_drain_target.finish_drain()
		_drain_target = null
		health = max_health
		health_changed.emit(health, max_health)
		_heal_flash = 1.0
		Sfx.play("heal", null)
		Game.on_drain()
		var siphon := Upgrades.perk("siphon")
		if siphon > 0:   # שדרוג: השאיבה נותנת גם מגן
			shield_hits += siphon + 1
		var p = preload("res://zombie.gd").HitText.new()
		p.text = "FULL LIFE"
		p.color = Color(0.45, 1.0, 0.75)
		p.size = 20
		p.pop = true
		get_parent().add_child(p)
		p.global_position = global_position + Vector2(0, -72)
	queue_redraw()


func is_draining() -> bool:
	return _drain_target != null


# נקרא ע"י זומבים, רגליים שנזרקות ורימונים
func hurt(amount: int, knock_dir: Vector2) -> void:
	if dead or _invuln > 0.0 or _drain_target != null:
		return
	if _roll_t > 0.0:   # בגלגול לא נפגעים. ברגע האחרון = הזמן מאט לרגע
		if _dodge_slow <= 0.0:
			_dodge_slow = 0.6
			Engine.time_scale = 0.45
			_say("PERFECT DODGE", Color("80d0ff"))
			Game.story.emit("perfect_dodge", {})
			Sfx.play("whoosh", null, 2.0)
			Game.on_style("dodge", 20)
		return
	if shield_hits > 0:   # המגן סופג את הפגיעה
		shield_hits -= 1
		_invuln = 0.5
		_heal_flash = 0.4
		_say("BLOCKED", Color("40e0e8"))
		Sfx.play("shield", global_position)
		return
	Game.on_player_hurt(amount)
	_hurt_t = 0.3
	Sfx.play("hurt", global_position, 0.0, 0.1, 2)
	preload("res://particles.gd").burst(get_parent(), global_position + Vector2(0, -30), "hit", Vector2(knock_dir.x, -0.3) if knock_dir != Vector2.ZERO else Vector2.ZERO, 14)
	_invuln = invuln_time
	if health - amount <= 0 and abilities != null and abilities.on_lethal_hit():   # LAST BREATH
		Game.story.emit("last_breath", {})
		health_changed.emit(health, max_health)
		return
	health = maxi(health - amount, 0)
	health_changed.emit(health, max_health)
	Game.story.emit("phurt", {"amount": amount})
	velocity += Vector2(knock_dir.x * 260.0, -180.0)
	if health <= 0:
		dead = true
		Engine.time_scale = 1.0
		boosts.clear()
		died.emit()


# ============================================================
#  ציור הדמות
#  מציירים תמיד כאילו הדמות פונה ימינה, ומשקפים לפי הצורך.
# ============================================================
func _draw() -> void:
	var face := _face()
	if dead:
		var k := clampf(_dead_t / 0.45, 0.0, 1.0)
		k = 1.0 - (1.0 - k) * (1.0 - k)
		var pool := clampf(_dead_t / 3.0, 0.0, 1.0)
		if pool > 0.0:   # שלולית דם
			Art.oval(self, Vector2(-face * 22.0, -1.0), 26.0 * pool, 3.0 * pool, Color("6a0a0a"), 0.0, Art.NONE)
		_base_xf = Transform2D(0.0, Vector2(face, 1.0), 0.0, Vector2.ZERO)
		draw_set_transform_matrix(_base_xf)
		_draw_hero(Vector2.RIGHT)
		draw_set_transform_matrix(Transform2D.IDENTITY)
		return

	var la := Vector2(_aim.x * face, _aim.y)   # כיוון הנשק במרחב המקומי (תמיד ימינה)
	if is_on_floor():
		Art.ground_shadow(self, Vector2.ZERO, 15.0)
	var blink := _invuln > 0.0 and int(_invuln * 16.0) % 2 == 0
	modulate = Color(1.0, 0.55, 0.55) if blink else Color.WHITE
	_base_xf = Transform2D(0.0, Vector2(face, 1.0), 0.0, Vector2.ZERO)
	if _roll_t > 0.0:   # גלגול: הגוף מסתובב סביב המרכז
		var ang := (1.0 - _roll_t / 0.35) * TAU * _roll_dir * face
		_base_xf = Transform2D(ang, Vector2(0, -16)) * Transform2D(0.0, Vector2(face, 1.0), 0.0, Vector2(0, 16))
	draw_set_transform_matrix(_base_xf)
	if jetpack != null:   # על הגב, מאחורי הגוף
		jetpack.draw_pack(self)
	_draw_hero(la)
	# קרן כוח החיים: מהניצולה אל המכשיר
	if _drain_target != null and is_instance_valid(_drain_target):
		var tgt: Vector2 = _drain_target.chest() - global_position
		tgt.x *= face
		_draw_beam(tgt, _device_tip, clampf(_drain_t / DRAIN_TIME, 0.0, 1.0))
	if shield_hits > 0:   # מגן: טבעת תכלת
		var sp := 0.7 + 0.3 * sin(_time * 6.0)
		draw_arc(Vector2(0, -27), 30.0, 0.0, TAU, 32, Color(0.25, 0.9, 0.95, 0.55 * sp), 2.0, true)
		draw_arc(Vector2(0, -27), 33.0, 0.0, TAU, 32, Color(0.25, 0.9, 0.95, 0.2 * sp), 4.0, true)
	if boosts.has(PickupScript.ADRENALINE):   # אדרנלין: קווי מהירות אדומים
		for i in 4:
			var y := -10.0 - float(i) * 11.0
			var ln := 10.0 + 8.0 * absf(sin(_time * 9.0 + float(i)))
			draw_line(Vector2(-14.0, y), Vector2(-14.0 - ln, y), Color(1.0, 0.3, 0.2, 0.55), 1.5, true)
	if _heal_flash > 0.0:   # הילה ירוקה אחרי שקיבלנו חיים
		Art.glow(self, Vector2(0, -28), 34.0 * (1.5 - _heal_flash * 0.5), Color(0.45, 1.0, 0.75, 0.6 * _heal_flash))
	if _melee_t > 0.0:   # קו תנועה של המכה
		var mk := 1.0 - _melee_t / MELEE_TIME
		draw_arc(Vector2(10, -24), 22.0, -0.9 + mk * 0.6, 0.5 + mk * 0.6, 10, Color(1, 1, 1, 0.5 * sin(mk * PI)), 3.0, true)
	draw_set_transform_matrix(Transform2D.IDENTITY)
	for d in _dust:   # אבק ריצה
		var dk: float = d[2] / d[3]
		draw_circle(d[0] - global_position, d[4], Color(0.62, 0.57, 0.5, 0.35 * (1.0 - dk)))
	if _daze_t > 0.0:   # מסונוור: נקודות אור מסתובבות מעל הראש
		for i in 3:
			var a := _time * 6.0 + float(i) * TAU / 3.0
			draw_circle(Vector2(cos(a) * 10.0, -60.0 + sin(a) * 3.0), 2.0, Color(1.0, 0.92, 0.6, minf(_daze_t * 2.0, 1.0)))
	# חלקיקי קסם (עדינים מאוד)
	for m in _magic:
		var k: float = m[2] / m[3]
		var a := 0.32 * minf(k * 5.0, 1.0) * (1.0 - k)
		var c: Color = m[5]
		var p: Vector2 = m[0] - global_position
		draw_circle(p, m[4] * 3.2, Color(c, a * 0.18))
		draw_circle(p, m[4], Color(c.lerp(Color.WHITE, 0.4), a))
	# לייזר (שדרוג)
	# קשת: קו נקודות שמראה לאן החץ יעוף
	if weapon == GUN and gun == BOW and controllable and _drain_target == null and not dead:
		var p0 := _front_shoulder() + _aim * 30.0
		var v := _aim * 1150.0
		for i in 14:
			var tt := 0.045 * float(i + 1)
			var pt := p0 + v * tt + Vector2(0.0, 450.0 * tt * tt)
			draw_circle(pt, 1.6, Color(0.6, 0.9, 0.5, 0.55 * (1.0 - float(i) / 14.0)))
	# טייזר: ברקים
	for b in _bolts:
		var pts: PackedVector2Array = b[0]
		for i in pts.size() - 1:
			var a := pts[i] - global_position
			var c := pts[i + 1] - global_position
			var line := PackedVector2Array([a])
			for j in range(1, 6):
				line.append(a.lerp(c, float(j) / 6.0) + Vector2(randf_range(-6, 6), randf_range(-6, 6)))
			line.append(c)
			draw_polyline(line, Color(0.75, 0.55, 1.0, 0.85), 3.0, true)
			draw_polyline(line, Color(1, 1, 1, 0.95), 1.0, true)
	# וו קרס: חבל
	if _hook_state != 0:
		var hand := _front_shoulder() + _aim * 12.0
		var end := _hook_pt - global_position
		if _hook_state == 1:   # פספוס: החבל נזרק וחוזר
			var tt := 0.12 - _hook_t
			end = hand.lerp(end, clampf(tt / 0.12 if tt < 0.12 else (0.27 - tt) / 0.15, 0.0, 1.0))
		draw_line(hand, end, Color("8a7a60"), 1.6, true)
		draw_circle(end, 2.5, Color("b0b0b8"))
	if (Upgrades.perk("laser_sight") > 0 or _scoping) and controllable and _drain_target == null and weapon == GUN:
		var from := _front_shoulder() + _aim * 30.0
		var to := _laser_end - global_position
		draw_line(from, to, Color(1.0, 0.1, 0.1, 0.35), 1.0, true)
		draw_circle(to, 2.0, Color(1.0, 0.2, 0.2, 0.9))


# הגוף מצויר צר יותר (רזה), הידיים והנשק ברוחב רגיל
func _slim(on: bool) -> void:
	draw_set_transform_matrix(_base_xf * Transform2D(0.0, Vector2(slim, 1.0), 0.0, Vector2.ZERO) if on else _base_xf)


# ============================================================
#  הדמות מה-SPRITE SHEET: בוחרים פריים לפי המצב, ומעליו ידיים + נשק שמכוון לעכבר
# ============================================================
func _hero_frame() -> Array:
	if dead:
		return ["death", mini(int(_dead_t * 7.0), 3)]
	if _melee_t > 0.0:
		return ["melee", clampi(int((1.0 - _melee_t / MELEE_TIME) * 3.0), 0, 2)]
	if _roll_t > 0.0:
		return ["crouch", 1]
	if _slide_t > 0.0:
		return ["slide", clampi(int((1.0 - _slide_t / 0.55) * 3.0), 0, 2)]
	if _hurt_t > 0.0:
		return ["hurt", clampi(int((0.3 - _hurt_t) / 0.1), 0, 2)]
	if _flip_t > 0.0:
		return ["jump", 3]   # מקופל בזמן הסלטה
	if not is_on_floor() and _air_t > 0.03:
		# המראה -> עולה -> שיא -> נופל (לפי המהירות האנכית)
		var vy := velocity.y
		if vy < -250.0:
			return ["jump", 1 if _air_t < 0.12 else 2]
		if vy < -70.0:
			return ["jump", 3]
		if vy < 110.0:
			return ["jump", 4]
		if vy < 380.0:
			return ["fall", 0]
		return ["fall", 3]   # נפילה ארוכה: רגליים למטה, מוכן לנחיתה
	if _land_anim > 0.0 and absf(velocity.x) < 30.0:
		return ["land", [2, 1, 4][clampi(int((1.0 - _land_anim / 0.3) * 3.0), 0, 2)]]
	if _land_anim > 0.0:
		return ["jump", 7]
	if _crouching:
		if absf(velocity.x) > 20.0:
			return ["crouch", [0, 4][int(_dist / 22.0) % 2]]
		return ["crouch", 1]
	if absf(velocity.x) > 30.0:
		var back := signf(velocity.x) != _face()   # הולך אחורה (מכוון לצד השני): הפריימים הפוך
		var an := "run" if _running else "walk"
		var nf: int = HeroAnim.FRAMES[an].size()
		var i := int(_dist / (17.0 if _running else 8.5)) % nf
		if back:
			i = nf - 1 - i
		return [an, i]
	return ["idle", int(_time * 6.0) % HeroAnim.FRAMES["idle"].size()]


func _draw_hero(la: Vector2) -> void:
	var fi := _hero_frame()
	_anim = fi[0]
	var fr: Array = HeroAnim.FRAMES[fi[0]][fi[1]]
	var s := SPRITE_SCALE
	if HeroAnim.FLIP.has(fi[0]):   # פריים שמצויר בדף לכיוון השני
		draw_set_transform_matrix(_base_xf * Transform2D(0.0, Vector2(-1.0, 1.0), 0.0, Vector2.ZERO))
	var flip := _flip_t > 0.0
	if flip:   # סלטה קדימה סביב מרכז הגוף
		var k := 1.0 - _flip_t / FLIP_T
		var piv := Vector2(0.0, -24.0)
		draw_set_transform_matrix(_base_xf * Transform2D(0.0, piv) * Transform2D(TAU * (k * k * (3.0 - 2.0 * k)), Vector2.ZERO) * Transform2D(0.0, -piv))
	draw_texture_rect_region(HERO_TEX, Rect2(-float(fr[4]) * s, -float(fr[5]) * s, float(fr[2]) * s, float(fr[3]) * s), Rect2(fr[0], fr[1], fr[2], fr[3]))
	draw_set_transform_matrix(_base_xf)
	if dead or _melee_t > 0.0 or _roll_t > 0.0 or _slide_t > 0.0 or unarmed or flip:
		return
	# ידיים + נשק מעל הספרייט (מכוונים לעכבר)
	var c := _crouch_k
	var sh := Vector2(3.0 * c + 1.0, -37.0 + 15.0 * c)
	# הנשק והידיים קטנים יותר (מתאים לדמות הרזה מהספרייט), סביב הכתף
	var ws := 0.72
	draw_set_transform_matrix(_base_xf * Transform2D(0.0, Vector2(ws, ws), 0.0, sh * (1.0 - ws)))
	if _anim == "run":   # ריצה: הגוף בפריימים נוטה קדימה - הידיים איתו
		sh += Vector2(2.0, 7.0)
	elif _anim == "hurt":
		sh += Vector2(-2.0, 4.0)
	var hand := sh + la * 15.0 - la * 2.5 * _recoil
	if _drain_target != null:
		_draw_device(hand, la)
		_arm(sh, hand, false)
		draw_set_transform_matrix(_base_xf)
		return
	if weapon == GUN or _special_weapon() >= 0:   # נשק, או פריט שהוא נשק (מולוטוב / משגרים)
		var rp := _reload_pose(hand, la, sh) if weapon == GUN else {"la": la, "hand": hand, "support": hand + la * 9.0 + la.rotated(PI / 2.0) * 2.0, "held": ""}
		la = rp.la
		hand = rp.hand
		_arm(sh + Vector2(-3.0, 1.5), rp.support, true)
		_draw_id = _special_weapon() if weapon != GUN else -1
		_draw_rifle(hand, la)
		_draw_id = -1
		_draw_held(rp.support, la, rp.held)
	else:
		var g := hand + la * 3.0
		Art.disc(self, g, 4.3, Color("4a5a2c"))
		draw_line(g + Vector2(-1.5, -4.0), g + Vector2(2.5, -5.0), Color("9a9a9a"), 1.4, true)
	_arm(sh + Vector2(1.0, 1.5), hand, false)
	draw_set_transform_matrix(_base_xf)


func _draw_body(la: Vector2, limp: bool) -> void:
	var c := _crouch_k
	var speed_k := clampf(absf(velocity.x) / run_speed, 0.0, 1.0)
	var air := not is_on_floor() and not limp
	var p := _walk_phase
	# נשימה: החזה עולה ויורד, הראש נוטה קצת אחורה בשאיפה, והמשקל עובר מרגל לרגל
	var idle := 0.0 if limp else _idle_k * (0.2 if calm else 1.0)
	var br := sin(_time * BREATH_SPEED) * idle
	var sway := sin(_time * 0.55) * idle
	var breathe := sin(_time * 2.2) * 0.6 * (1.0 - speed_k) * (1.0 - idle)

	# שלד: ירכיים, כתפיים, ראש
	var hip := Vector2(sway * 0.9, -24.0 + 11.0 * c - absf(cos(p)) * 1.2 * speed_k)
	var sh := Vector2(3.0 * c + speed_k * 2.0 + sway * 0.5, -41.0 + 17.0 * c + breathe * 0.4 - absf(cos(p)) * 1.2 * speed_k - br * 2.0)
	var head := sh + Vector2(1.5 + br * 0.6, -8.5 - br * 0.6)

	# כפות רגליים
	var stride := 6.0 + 6.0 * speed_k
	var f_front: Vector2
	var f_back: Vector2
	if air:
		f_front = Vector2(6.0, -9.0)
		f_back = Vector2(-5.0, -5.0)
	elif c > 0.5:
		f_front = Vector2(7.0 + sin(p) * 3.0, 0.0)
		f_back = Vector2(-8.0 - sin(p) * 3.0, 0.0)
	else:
		f_front = Vector2(sin(p) * stride + 1.0, -maxf(0.0, cos(p)) * 5.0)
		f_back = Vector2(sin(p + PI) * stride - 1.0, -maxf(0.0, cos(p + PI)) * 5.0)
	if limp:
		f_front = Vector2(2.0, 0.0)
		f_back = Vector2(-2.0, 0.0)
	else:   # בעמידה: רגליים קצת פתוחות
		f_front.x += 3.0 * idle
		f_back.x -= 3.0 * idle

	# כמה המעיל מתנופף (ריצה / אוויר / רתיעה) + רפרוף של הרוח
	var flow := clampf(speed_k * 0.8 + (0.5 if air else 0.0) + _recoil * 0.25 + 0.15, 0.0, 1.0)
	if limp:
		flow = 0.0
	var wv := sin(_time * 7.0) * (0.6 + flow * 1.6)

	# ---- יד אחורית ----
	var bs := sh + Vector2(-2.0, 1.5)
	var fs := sh + Vector2(2.0, 1.5)
	var kick := la * -2.5 * _recoil
	var jab := 0.0
	if _melee_t > 0.0 and not limp:   # מכת קת: הקנה עולה למעלה והקת נדחפת קדימה
		var mk := 1.0 - _melee_t / MELEE_TIME
		jab = sin(mk * PI)
		la = la.rotated(-2.0 * jab)
		kick = Vector2(11.0 * jab, 5.0 * jab)
	var hand := fs + la * 15.0 + kick
	var back_hand: Vector2
	if limp:
		hand = fs + Vector2(4.0, 15.0)
		back_hand = bs + Vector2(-3.0, 15.0)
	elif weapon == GUN:
		back_hand = hand + la * 9.0 + la.rotated(PI / 2.0) * 2.0
	else:
		back_hand = bs + Vector2(-3.0 + sin(p) * 3.0, 15.0)
	_arm(bs, back_hand, true)
	_slim(true)

	# ---- זנב אחורי של המעיל (מתנופף מאחור) ----
	var bottom := -1.0
	var tail := PackedVector2Array([
		hip + Vector2(-2.0, -2.0),
		Vector2(hip.x - 3.0 - flow * 2.0, minf(-6.0 + wv, bottom)),
		Vector2(hip.x - 6.0 - flow * 7.0, minf(-1.0 + wv * 1.5, bottom)),
		Vector2(hip.x - 9.0 - flow * 10.0, minf(-6.0 - flow * 3.0 + wv, bottom)),
		Vector2(hip.x - 13.0 - flow * 16.0, minf(-3.0 - flow * 9.0 + wv * 2.0, bottom)),
		Vector2(hip.x - 12.0 - flow * 10.0, hip.y + 2.0 - flow * 4.0),
		hip + Vector2(-9.0, -3.0),
	])
	Art.fill(self, tail, coat_color, Art.OUTLINE, 1.4)
	# בטנה אפורה + קפלים
	Art.fill_shaded(self, PackedVector2Array([tail[0], tail[1], tail[2], Vector2(hip.x - 5.0 - flow * 4.0, hip.y + 6.0)]), coat_lining, 0.1, 0.4, Art.NONE)
	draw_line(Vector2(hip.x - 5.0 - flow * 5.0, hip.y + 8.0), Vector2(hip.x - 8.0 - flow * 9.0, -6.0 - flow * 2.0 + wv), Color(1, 1, 1, 0.12), 1.0, true)
	draw_line(Vector2(hip.x - 8.0 - flow * 6.0, hip.y + 4.0), Vector2(hip.x - 12.0 - flow * 13.0, -6.0 - flow * 7.0 + wv * 1.5), Color(1, 1, 1, 0.1), 1.0, true)
	draw_polyline(PackedVector2Array([tail[0], tail[1], tail[2]]), rim_color, 1.0, true)

	# ---- רגליים ----
	_leg(hip + Vector2(-1.5, 0.0), f_back, true)
	_leg(hip + Vector2(1.5, 0.0), f_front, false)

	# ---- גוף המעיל ----
	var torso := PackedVector2Array([
		sh + Vector2(-9.0, -1.0), sh + Vector2(7.0, -2.0), sh + Vector2(9.0 + br * 0.8, 4.0),
		hip + Vector2(8.5, -1.0), hip + Vector2(-8.5, -1.0), sh + Vector2(-10.0, 5.0),
	])
	Art.fill_shaded(self, torso, coat_color, 0.1, 0.3, Art.OUTLINE, 1.5)
	# הארה לבנה בצד הקדמי (כמו במנגה)
	draw_polyline(PackedVector2Array([sh + Vector2(7.5, -1.0), sh + Vector2(9.0, 4.0), hip + Vector2(8.0, -1.5)]), rim_color, 1.1, true)
	draw_polyline(PackedVector2Array([sh + Vector2(2.0, 0.0), hip + Vector2(3.0, -2.0)]), coat_lining, 1.0, true)   # פתח המעיל
	draw_polyline(PackedVector2Array([sh + Vector2(-5.0, 4.0), sh + Vector2(-3.0, 9.0), sh + Vector2(-5.0, 12.0)]), Color(1, 1, 1, 0.1), 1.0, true)
	draw_line(hip + Vector2(-8.5, -2.5), hip + Vector2(8.5, -2.5), Color("050507"), 2.4, true)   # חגורה

	# ---- הפאנל הקדמי של המעיל (עם חריץ שרואים דרכו את הרגליים) ----
	var front := PackedVector2Array([
		hip + Vector2(1.0, -2.0), hip + Vector2(8.5, -2.0),
		Vector2(hip.x + 10.5 - flow * 2.0, minf(-6.0 + wv * 0.5, bottom)),
		Vector2(hip.x + 6.0 - flow * 2.0, minf(-2.5 + wv * 0.4, bottom)),
		Vector2(hip.x + 3.0 - flow * 3.0, minf(-8.0 + wv * 0.3, bottom)),
		hip + Vector2(0.0, 6.0),
	])
	Art.fill_shaded(self, front, coat_color, 0.08, 0.3, Art.OUTLINE, 1.3)
	draw_polyline(PackedVector2Array([front[1], front[2]]), rim_color, 1.0, true)
	draw_line(hip + Vector2(4.0, 2.0), Vector2(hip.x + 6.0 - flow * 2.0, -6.0), Color(1, 1, 1, 0.1), 0.9, true)

	# ---- צווארון גבוה (אחורי) ----
	Art.fill(self, PackedVector2Array([sh + Vector2(-7.0, 1.0), sh + Vector2(-10.0, -10.0), sh + Vector2(-2.0, -3.0)]), coat_color, Art.OUTLINE, 1.2)
	draw_line(sh + Vector2(-9.5, -9.0), sh + Vector2(-3.0, -3.5), Color(1, 1, 1, 0.25), 0.9, true)

	# ---- ברדס: הפנים חבויות בחושך ----
	var hood := PackedVector2Array([
		sh + Vector2(-7.0, -1.0), head + Vector2(-8.0, 2.0), head + Vector2(-7.5, -5.0),
		head + Vector2(-3.0, -10.5), head + Vector2(-0.5, -12.0), head + Vector2(3.5, -9.5),
		head + Vector2(7.0, -4.0), head + Vector2(7.8, 3.0), sh + Vector2(6.0, -1.0),
	])
	Art.fill_shaded(self, hood, coat_color, 0.14, 0.25, Art.OUTLINE, 1.5)
	var face := PackedVector2Array([
		head + Vector2(0.5, -6.5), head + Vector2(4.5, -6.0), head + Vector2(6.8, -2.5),
		head + Vector2(6.6, 3.5), head + Vector2(3.0, 5.5), head + Vector2(0.0, 2.0),
	])
	Art.fill(self, face, Color("000000"), Art.NONE)
	# קצה לבן של הברדס
	draw_polyline(PackedVector2Array([head + Vector2(-0.5, -12.0), head + Vector2(3.5, -9.5), head + Vector2(7.0, -4.0), head + Vector2(7.8, 3.0)]), rim_color, 1.2, true)
	draw_polyline(PackedVector2Array([head + Vector2(0.5, -6.5), head + Vector2(0.0, 2.0), head + Vector2(3.0, 5.5)]), Color(1, 1, 1, 0.35), 0.8, true)
	draw_line(head + Vector2(-3.0, -9.5), head + Vector2(-6.5, -3.0), Color(1, 1, 1, 0.12), 1.0, true)
	if glowing_eyes:
		Art.glow(self, head + Vector2(5.0, -1.5), 2.6, Color(eye_color, 0.8))
		draw_line(head + Vector2(3.8, -1.6), head + Vector2(5.8, -1.3), eye_color, 1.0, true)

	# ---- צווארון גבוה (קדמי) ----
	Art.fill(self, PackedVector2Array([sh + Vector2(3.0, -1.0), sh + Vector2(10.0, -9.5), sh + Vector2(8.0, 2.0)]), coat_color, Art.OUTLINE, 1.2)
	draw_polyline(PackedVector2Array([sh + Vector2(3.5, -1.5), sh + Vector2(10.0, -9.5), sh + Vector2(8.0, 2.0)]), rim_color, 1.0, true)

	# ---- נשק + יד קדמית ----
	_slim(false)
	if limp:
		_arm(fs, hand, false)
		return
	if _drain_target != null:
		_draw_device(hand, la)
	elif weapon == GUN or _special_weapon() >= 0:
		var rp := _reload_pose(hand, la, fs) if weapon == GUN else {"la": la, "hand": hand, "support": hand, "held": ""}
		hand = rp.hand
		_draw_id = _special_weapon() if weapon != GUN else -1
		_draw_rifle(hand, rp.la)
		_draw_id = -1
		_draw_held(rp.support, rp.la, rp.held)
	else:
		var g := hand + la * 3.0
		Art.disc(self, g, 4.3, Color("4a5a2c"))
		draw_line(g + Vector2(-1.5, -4.0), g + Vector2(2.5, -5.0), Color("9a9a9a"), 1.4, true)
	_arm(fs, hand, false)


func _arm(shoulder: Vector2, hand: Vector2, back: bool) -> void:
	var elbow := Art.joint(shoulder, hand, 8.5, 8.5, -1.0)
	var col := Art.shade(coat_color, -0.05) if back else coat_color
	Art.limb(self, PackedVector2Array([shoulder, elbow, hand]), 4.6, col)
	if not back:   # הארה לבנה על השרוול
		draw_polyline(PackedVector2Array([shoulder + Vector2(0.0, -2.6), elbow + (elbow - shoulder).orthogonal().normalized() * 2.6]), Color(rim_color, 0.7), 0.9, true)
	# שרוול רחב ליד כף היד
	var d := (hand - elbow).normalized()
	var n := d.orthogonal()
	Art.fill(self, PackedVector2Array([hand - d * 4.5 + n * 3.6, hand - d * 1.0 + n * 3.2, hand - d * 1.0 - n * 3.2, hand - d * 4.5 - n * 3.6]), col, Art.OUTLINE, 1.0)
	Art.disc(self, hand, 2.5, glove_color)


func _leg(hip: Vector2, foot: Vector2, back: bool) -> void:
	var ankle := foot + Vector2(0.0, -3.5)
	var knee := Art.joint(hip, ankle, 11.5, 11.0, 1.0)
	var pants := Art.shade(pants_color, 0.25) if back else pants_color
	var boot := Art.shade(boot_color, 0.2) if back else boot_color
	Art.limb(self, PackedVector2Array([hip, knee, ankle]), 6.2, pants)
	# מגף גבוה עם שוליים משוננים
	var top := knee.lerp(ankle, 0.25)
	var d := (ankle - top).normalized()
	var n := d.orthogonal()
	Art.fill(self, PackedVector2Array([
		top + n * 4.2 - d * 1.5, top + n * 2.0 + d * 1.5, top - d * 0.5, top - n * 2.0 + d * 1.5, top - n * 4.2 - d * 1.5,
		ankle - n * 3.6, foot + Vector2(-3.8, 0.0), foot + Vector2(7.5, 0.0), foot + Vector2(7.5, -2.0),
		foot + Vector2(3.0, -4.0), ankle + n * 3.4,
	]), boot, Art.OUTLINE, 1.1)
	if not back:
		draw_polyline(PackedVector2Array([top + n * 4.0 - d * 1.2, ankle + n * 3.2, foot + Vector2(3.0, -4.0), foot + Vector2(7.5, -2.0)]), Color(rim_color, 0.6), 0.9, true)


# המכשיר: גוש מתכת עם ליבה זוהרת ושלושה שיניים
func _draw_device(hand: Vector2, la: Vector2) -> void:
	var n := la.rotated(PI / 2.0)
	var g := func(x: float, y: float) -> Vector2: return hand + la * x + n * y
	var k := clampf(_drain_t / DRAIN_TIME, 0.0, 1.0)
	var pulse := 0.6 + 0.4 * sin(_time * 25.0)
	Art.fill(self, PackedVector2Array([g.call(-4.0, -4.0), g.call(8.0, -5.0), g.call(10.0, 0.0), g.call(8.0, 5.0), g.call(-4.0, 4.0)]), Color("23262b"), Art.OUTLINE, 1.2)
	for y in [-3.5, 0.0, 3.5]:   # שיניים
		Art.limb(self, PackedVector2Array([g.call(9.0, y * 0.8), g.call(15.0, y)]), 1.4, Color("8a9098"), Art.OUTLINE)
	var core: Vector2 = g.call(3.0, 0.0)
	Art.glow(self, core, 8.0 + 6.0 * k, Color(0.45, 1.0, 0.85, 0.8 * pulse))
	Art.disc(self, core, 2.4, Color(0.75, 1.0, 0.95), Art.NONE)
	_device_tip = g.call(16.0, 0.0)


# קרן גלית + חלקיקים שזורמים מהיעד אל המכשיר
func _draw_beam(from: Vector2, to: Vector2, k: float) -> void:
	var col := Color(0.45, 1.0, 0.85)
	var d := to - from
	var n := d.orthogonal().normalized()
	var amp := 3.0 + 3.0 * sin(k * PI)
	for layer in 2:
		var pts := PackedVector2Array()
		for i in 17:
			var t := float(i) / 16.0
			var w := sin(t * 12.0 - _time * 20.0 + float(layer) * 2.0) * amp * sin(t * PI)
			pts.append(from + d * t + n * w)
		draw_polyline(pts, Color(col, 0.25 if layer == 0 else 0.7), 5.0 if layer == 0 else 1.6, true)
	for i in 10:   # חלקיקים של כוח חיים
		var t := fmod(float(i) / 10.0 + _time * 1.6, 1.0)
		var p := from + d * t + n * sin(t * 9.0 + float(i)) * amp
		draw_circle(p, 1.8 * (1.0 - t * 0.5), Color(0.8, 1.0, 0.95, 0.9))
	Art.glow(self, from, 10.0, Color(col, 0.6))


# ============================================================
#  אנימציית טעינה - לפי סוג הנשק:
#    "mag"      - המחסנית נופלת, היד לוקחת חדשה מהחגורה, מכניסה, ודורכת (רובה / SMG / רובה סער / צלף / אקדח / שוטגאן אוטומטי)
#    "shell"    - 3 כדורים אחד אחד לפתח הטעינה ואז משאבה (שוטגאן)
#    "launcher" - המשגר נפתח (הקנה למטה), 2 רימונים, נסגר
#    "rocket"   - היד לוקחת טיל מהגב ודוחפת אותו לקצה הצינור
#  k = התקדמות 0..1 (זמן הטעינה ב-weapon_db.gd -> reload_time)
# ============================================================
func _reload_k() -> float:
	return clampf(1.0 - _reload_t / maxf(_reload_total, 0.01), 0.0, 1.0)


func _reload_kind() -> String:
	match str(WeaponDB.val(gun, "style", "rifle")):
		"shotgun":
			return "shell"
		"launcher":
			return "launcher"
		"rocket":
			return "rocket"
	return "mag"


# אירועים חד-פעמיים לאורך הטעינה (מחסנית נופלת, תרמילים)
func _reload_events(k0: float, k1: float) -> void:
	var kind := _reload_kind()
	var fpos := global_position + Vector2(_face() * 8.0, -26.0)
	if kind == "mag" and k0 < 0.12 and k1 >= 0.12:
		var c = DebrisScript.new()
		get_parent().add_child(c)
		c.setup(fpos, Vector2(2.6, 6.0), Color("26262c"), Vector2(_face() * randf_range(10.0, 40.0), 30.0))
	elif kind == "launcher" and k0 < 0.12 and k1 >= 0.12:
		for i in 2:
			_eject_casing(global_position + Vector2(_face() * 2.0, -30.0))


func _reload_pose(hand: Vector2, la: Vector2, sh: Vector2) -> Dictionary:
	var rest_of := func(h: Vector2, l: Vector2) -> Vector2: return h + l * 9.0 + l.rotated(PI / 2.0) * 2.0
	_mag_out = false
	if _reload_t <= 0.0:
		return {"la": la, "hand": hand, "support": rest_of.call(hand, la), "held": ""}
	var k := _reload_k()
	var kind := _reload_kind()
	var into := smoothstep(0.0, 0.14, k) * (1.0 - smoothstep(0.86, 1.0, k))   # כניסה / יציאה מהתנוחה
	# הנשק עובר לתנוחת טעינה קבועה (לא משנה לאן כיוונת) וחוזר בסוף
	var pose_ang := 0.0
	var off := Vector2.ZERO
	match kind:
		"mag":
			pose_ang = -0.5
			off = Vector2(-3.0, -1.5) * into
		"shell":
			pose_ang = -0.3
			off = Vector2(-2.0, 0.0) * into
		"launcher":
			pose_ang = 0.6
			off = Vector2(-2.0, 2.0) * into
		"rocket":
			pose_ang = -0.1
			off = Vector2(-1.0, 0.0) * into
	var rot := wrapf(lerp_angle(la.angle(), pose_ang, into) - la.angle(), -PI, PI)
	# מכה קטנה כשהמחסנית ננעלת / כשדורכים
	var jolt := maxf(0.0, 1.0 - absf(k - 0.61) / 0.05) + maxf(0.0, 1.0 - absf(k - 0.78) / 0.05)
	var gla := la.rotated(rot - 0.08 * jolt)
	var gh := hand + off - gla * 1.5 * jolt
	var n := gla.rotated(PI / 2.0)
	var g := func(x: float, y: float) -> Vector2: return gh + gla * x + n * y
	var rest: Vector2 = rest_of.call(gh, gla)
	var belt := sh + Vector2(-1.0, 20.0)
	var sup := rest
	var held := ""
	var seg := func(a: Vector2, b: Vector2, k0: float, k1: float) -> Vector2: return a.lerp(b, smoothstep(k0, k1, k))
	match kind:
		"mag":
			var well: Vector2 = g.call(7.5, 7.0)
			var bolt: Vector2 = g.call(6.0, -2.5) if gun == PISTOL else g.call(1.0, -3.0)
			var racked := bolt - gla * 5.0
			_mag_out = k > 0.12 and k < 0.6
			if k < 0.12:
				sup = seg.call(rest, well, 0.0, 0.12)
			elif k < 0.34:
				sup = seg.call(well, belt, 0.12, 0.34)
			elif k < 0.4:
				sup = belt
			elif k < 0.6:
				sup = seg.call(belt, well, 0.4, 0.6)
			elif k < 0.72:
				sup = seg.call(well, bolt, 0.6, 0.72)
			elif k < 0.8:
				sup = seg.call(bolt, racked, 0.72, 0.8)
			else:
				sup = seg.call(racked, rest, 0.8, 0.95)
			if k >= 0.36 and k < 0.6:
				held = "mag"
		"shell":   # 3 כדורים, ואז משאבה
			var port: Vector2 = g.call(8.0, 3.5)
			if k < 0.12:
				sup = seg.call(rest, port, 0.0, 0.12)
			elif k < 0.78:
				var c := fmod((k - 0.12) / 0.22, 1.0)
				sup = port.lerp(belt, smoothstep(0.0, 0.4, c)) if c < 0.45 else belt.lerp(port, smoothstep(0.5, 1.0, c))
				if c >= 0.45:
					held = "shell"
			else:
				var pump: Vector2 = g.call(18.0, 2.4)
				var back: Vector2 = g.call(12.0, 2.4)
				if k < 0.84:
					sup = seg.call(port, pump, 0.78, 0.84)
				elif k < 0.9:
					sup = seg.call(pump, back, 0.84, 0.9)
				elif k < 0.95:
					sup = seg.call(back, pump, 0.9, 0.95)
				else:
					sup = pump.lerp(rest, smoothstep(0.95, 1.0, k))
		"launcher":   # נפתח, 2 רימונים, נסגר
			var breech: Vector2 = g.call(3.0, -2.5)
			if k < 0.15:
				sup = seg.call(rest, breech, 0.0, 0.15)
			elif k < 0.8:
				var c := fmod((k - 0.15) / 0.325, 1.0)
				sup = breech.lerp(belt, smoothstep(0.0, 0.4, c)) if c < 0.45 else belt.lerp(breech, smoothstep(0.5, 1.0, c))
				if c >= 0.45:
					held = "grenade"
			else:
				sup = seg.call(breech, rest, 0.8, 0.92)
		"rocket":   # טיל מהגב אל קצה הצינור
			var back := sh + Vector2(-12.0, -6.0)
			var front: Vector2 = g.call(44.0, -1.3)
			var tip: Vector2 = g.call(35.0, -1.3)
			if k < 0.3:
				sup = seg.call(rest, back, 0.05, 0.3)
			elif k < 0.38:
				sup = back
			elif k < 0.62:
				sup = seg.call(back, front, 0.38, 0.62)
			elif k < 0.76:
				sup = seg.call(front, tip, 0.62, 0.76)
			else:
				sup = seg.call(tip, rest, 0.78, 0.95)
			if k >= 0.34 and k < 0.76:
				held = "rocket"
	return {"la": gla, "hand": gh, "support": sup, "held": held}


# מה שהיד התומכת מחזיקה באמצע טעינה
func _draw_held(at: Vector2, la: Vector2, what: String) -> void:
	var n := la.rotated(PI / 2.0)
	match what:
		"mag":
			Art.fill(self, PackedVector2Array([at - la * 1.6 - n * 1.0, at + la * 1.6 - n * 1.0, at + la * 2.2 + n * 7.0, at - la * 1.2 + n * 7.0]), Color("3a3a44"), Art.OUTLINE, 0.9)
			draw_line(at + la * 1.6 - n * 1.0, at + la * 2.2 + n * 7.0, Color(rim_color, 0.8), 0.8, true)
			draw_line(at - la * 1.0 - n * 1.2, at + la * 1.0 - n * 1.2, Color("e0b848"), 1.2)
		"shell":
			Art.fill(self, PackedVector2Array([at - la * 1.4 - n * 3.0, at + la * 1.4 - n * 3.0, at + la * 1.4 + n * 1.0, at - la * 1.4 + n * 1.0]), Color("c03a2a"), Art.OUTLINE, 0.8)
			draw_line(at - la * 1.4 + n * 1.6, at + la * 1.4 + n * 1.6, Color("d8b048"), 1.4)
		"grenade":
			Art.disc(self, at + n * -1.0, 2.6, Color("5a6a3a"), Art.OUTLINE, 0.9)
			draw_line(at - la * 1.6 - n * 1.0, at + la * 1.6 - n * 1.0, Color("d8b048"), 0.9)
		"rocket":
			var b := at - n * 1.3
			Art.fill(self, PackedVector2Array([b - la * 8.0 - n * 2.4, b + la * 4.0 - n * 2.4, b + la * 4.0 + n * 2.4, b - la * 8.0 + n * 2.4]), Color("4a5a3a"), Art.OUTLINE, 0.9)
			draw_line(b - la * 7.0 - n * 1.6, b + la * 3.0 - n * 1.6, Color(1, 1, 1, 0.25), 0.8, true)
			Art.fill(self, PackedVector2Array([b + la * 4.0 - n * 2.4, b + la * 9.0, b + la * 4.0 + n * 2.4]), Color("c03a2a"), Art.OUTLINE, 0.9)


func _draw_rifle(hand: Vector2, la: Vector2) -> void:
	var dg: int = _draw_id if _draw_id >= 0 else gun   # SPECIAL ביד = מציירים את הנשק שלו
	var n := la.rotated(PI / 2.0)
	var g := func(x: float, y: float) -> Vector2: return hand + la * x + n * y
	var metal := Color("1d1d23")
	var wood := Color("4b2d1c")
	if dg == BOW:   # קשת: עץ מעוקל, מיתר וחץ דרוך
		var bow := PackedVector2Array()
		for k in 9:
			var a := -1.25 + 2.5 * float(k) / 8.0
			bow.append(g.call(3.0 + cos(a) * 6.0, sin(a) * 16.0))
		draw_polyline(bow, Color("6a4424"), 2.6, true)
		draw_polyline(bow, Color("9a6a3a"), 1.2, true)
		var pull := 3.0 if _cooldown <= 0.0 else 0.0
		draw_polyline(PackedVector2Array([bow[0], g.call(-pull, 0.0), bow[8]]), Color(0.9, 0.9, 0.85, 0.8), 0.8, true)
		if _cooldown <= 0.0 and ammo > 0:
			draw_line(g.call(-pull, 0.0), g.call(20.0, 0.0), Color("8a6a40"), 1.4, true)
			draw_colored_polygon(PackedVector2Array([g.call(20.0, -2.0), g.call(25.0, 0.0), g.call(20.0, 2.0)]), Color("b8b8c0"))
		return
	if dg == MOLOTOV:   # בקבוק עם סמרטוט בוער
		Art.fill(self, PackedVector2Array([g.call(-2.0, -3.0), g.call(7.0, -3.0), g.call(9.0, -1.5), g.call(14.0, -1.2), g.call(14.0, 1.2), g.call(9.0, 1.5), g.call(7.0, 3.0), g.call(-2.0, 3.0)]), Color(0.35, 0.55, 0.3, 0.9), Art.OUTLINE, 0.9)
		Art.fill(self, PackedVector2Array([g.call(-1.0, 0.4), g.call(6.0, 0.4), g.call(6.0, 2.6), g.call(-1.0, 2.6)]), Color(0.9, 0.55, 0.15, 0.8), Art.NONE)
		draw_line(g.call(14.0, 0.0), g.call(17.0, -1.5), Color("d8c8a0"), 1.6)
		if ammo > 0 or _draw_id >= 0:
			Art.glow(self, g.call(18.0, -2.5), 5.0 + sin(_time * 25.0), Color(1.0, 0.6, 0.15, 0.8))
		return
	if dg == ROCKET_LAUNCHER:   # משגר טילים: צינור ירוק על הכתף, ידית, כוונת, ראש נפץ אדום כשטעון
		Art.fill(self, PackedVector2Array([g.call(-14.0, -4.6), g.call(30.0, -4.6), g.call(30.0, 2.0), g.call(-14.0, 2.0)]), Color("4a5a3a"), Art.OUTLINE, 1.1)
		draw_line(g.call(-12.0, -3.4), g.call(28.0, -3.4), Color(1, 1, 1, 0.14), 1.0, true)
		Art.fill(self, PackedVector2Array([g.call(-17.0, -6.0), g.call(-13.0, -6.0), g.call(-13.0, 3.4), g.call(-17.0, 3.4)]), Color("2a2c26"), Art.OUTLINE, 0.9)
		Art.fill(self, PackedVector2Array([g.call(26.0, -5.6), g.call(31.0, -5.6), g.call(31.0, 3.0), g.call(26.0, 3.0)]), Color("2a2c26"), Art.OUTLINE, 0.9)
		Art.fill(self, PackedVector2Array([g.call(1.0, 2.0), g.call(4.5, 2.0), g.call(3.5, 8.0), g.call(0.0, 8.0)]), Color("1e1e22"), Art.OUTLINE, 0.9)
		Art.fill(self, PackedVector2Array([g.call(12.0, 2.0), g.call(15.0, 2.0), g.call(14.5, 6.5), g.call(11.5, 6.5)]), Color("1e1e22"), Art.OUTLINE, 0.9)
		Art.fill(self, PackedVector2Array([g.call(6.0, -4.6), g.call(12.0, -4.6), g.call(12.0, -8.0), g.call(6.0, -8.0)]), Color("1e1e22"), Art.OUTLINE, 0.9)
		if mag > 0 or _draw_id >= 0:
			Art.fill(self, PackedVector2Array([g.call(31.0, -4.0), g.call(37.0, -1.3), g.call(31.0, 1.4)]), Color("c03a2a"), Art.OUTLINE, 0.9)
		if _muzzle_flash > 0.0:   # להבה מאחור
			Art.glow(self, g.call(-20.0, -1.3), 12.0, Color(1.0, 0.7, 0.3, 0.9))
		return
	if dg == PISTOL:   # אקדח: קטן, ביד אחת
		Art.fill(self, PackedVector2Array([g.call(-1.0, -1.8), g.call(13.0, -1.8), g.call(13.0, 1.4), g.call(3.5, 1.4), g.call(2.5, 7.0), g.call(-1.5, 6.5), g.call(-1.0, 1.4)]), Color("1d1d23"), Art.OUTLINE, 1.0)
		draw_line(g.call(0.0, -1.0), g.call(12.0, -1.0), Color(1, 1, 1, 0.15), 0.8, true)
		if _muzzle_flash > 0.0:
			var pm: Vector2 = g.call(15.0, -0.2)
			Art.glow(self, pm, 7.0, Color(1.0, 0.75, 0.3, 0.9))
		return
	Art.fill(self, PackedVector2Array([g.call(-11.0, -0.5), g.call(-2.0, -1.6), g.call(-1.0, 2.2), g.call(-11.0, 4.2)]), wood, Art.OUTLINE, 1.0)
	Art.fill(self, PackedVector2Array([
		g.call(-2.0, -1.6), g.call(14.0, -1.6), g.call(14.0, 1.6), g.call(4.0, 1.6),
		g.call(2.6, 6.4), g.call(-0.6, 6.4), g.call(-1.0, 2.2),
	]), metal, Art.OUTLINE, 1.0)
	Art.fill(self, PackedVector2Array([g.call(5.0, 1.6), g.call(13.0, 1.6), g.call(12.0, 3.6), g.call(6.0, 3.6)]), wood, Art.OUTLINE, 0.9)   # ידית קדמית
	var style: String = WeaponDB.val(dg, "style", "rifle")
	var bl: float = WeaponDB.val(dg, "barrel", 25.0)   # אורך הקנה לפי הנשק
	var bw: float = {"shotgun": 3.4, "ashotgun": 3.8, "launcher": 5.0, "sniper": 1.8, "taser": 2.4, "pistol": 2.0, "smg": 2.2}.get(style, 2.0)
	Art.limb(self, PackedVector2Array([g.call(14.0, -0.4), g.call(bl, -0.4)]), bw, Color("2c2c34"), Art.OUTLINE)   # קנה
	match style:
		"shotgun", "ashotgun":   # שוטגאן: ידית משאבה (אוטומטי: תוף מחסנית)
			Art.fill(self, PackedVector2Array([g.call(15.0, 1.2), g.call(21.0, 1.2), g.call(21.0, 3.6), g.call(15.0, 3.6)]), Color("5a3a24"), Art.OUTLINE, 0.9)
			if style == "ashotgun" and not _mag_out:
				Art.disc(self, g.call(4.0, 6.0), 3.6, Color("3a3a42"), Art.OUTLINE, 0.9)
		"sniper":   # צלף: כוונת טלסקופית
			Art.fill(self, PackedVector2Array([g.call(0.0, -3.4), g.call(11.0, -3.4), g.call(11.0, -6.4), g.call(0.0, -6.4)]), Color("16161a"), Art.OUTLINE, 0.9)
			draw_circle(g.call(11.2, -4.9), 1.2, Color(0.5, 0.8, 1.0, 0.8))
		"taser":   # טייזר: סליל סגול זוהר
			for k in 3:
				draw_circle(g.call(16.0 + float(k) * 2.0, -0.4), 2.2, Color(0.7, 0.5, 1.0, 0.5 + 0.3 * sin(_time * 20.0 + float(k))))
			draw_circle(g.call(bl, -0.4), 1.8, Color(0.85, 0.75, 1.0))
		"smg":   # SMG: מחסנית ארוכה ישרה
			if not _mag_out:
				Art.fill(self, PackedVector2Array([g.call(6.0, 1.6), g.call(9.0, 1.6), g.call(9.0, 11.0), g.call(6.0, 11.0)]), Color("18181c"), Art.OUTLINE, 0.9)
		"ar":   # רובה סער: מחסנית מעוקלת + ידית נשיאה
			if not _mag_out:
				Art.fill(self, PackedVector2Array([g.call(5.0, 1.6), g.call(9.0, 1.6), g.call(11.0, 9.0), g.call(7.0, 10.0)]), Color("18181c"), Art.OUTLINE, 0.9)
			draw_line(g.call(18.0, -1.4), g.call(18.0, -4.0), Color("2c2c34"), 1.4)
		"launcher":   # משגר: קנה עבה ותוף
			Art.disc(self, g.call(6.0, 3.0), 4.6, Color("4a5a3a"), Art.OUTLINE, 0.9)
			Art.disc(self, g.call(6.0, 3.0), 1.4, Color("1a1a1a"), Art.NONE)
	Art.fill(self, PackedVector2Array([g.call(1.0, -1.6), g.call(9.0, -1.6), g.call(9.0, -3.8), g.call(1.0, -3.8)]), Color("101014"), Art.OUTLINE, 0.9)   # כוונת
	draw_line(g.call(-1.0, -1.0), g.call(13.0, -1.0), Color(1, 1, 1, 0.12), 0.8, true)
	if _muzzle_flash > 0.0:
		var m: Vector2 = g.call(bl + 3.0, -0.4)
		Art.glow(self, m, 9.0, Color(1.0, 0.75, 0.3, 0.9))
		Art.fill(self, PackedVector2Array([m + la * -2.0 + n * -2.5, m + la * 8.0, m + la * -2.0 + n * 2.5]), Color(1.0, 0.95, 0.7), Art.NONE)
