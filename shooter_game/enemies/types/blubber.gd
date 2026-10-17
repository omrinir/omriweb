extends "res://enemies/zombie_type.gd"
# ============================================================
#  BLUBBER (שלב 57, "PENGUIN COAST") - מת שזחל לתוך עור של פיל ים זכר ענק ונתפר בו: גוף-שק ארוך ואפור-חום של שומן,
#    עור שמתקלף (כתמי נשירה), צלקות קרב ורודות, תפרים שחורים גסים. ראש פיל הים עם החדק המשתלשל הוא קסדה - מתחתיו, בפה
#    הפתוח של הפיל, הפנים החיוורות של המת עם עיניים אדומות. הידיים האנושיות יוצאות מהחזה כמו סנפירים ומושכות אותו.
#    הגב קרוע: בשר אדום חשוף, עמוד שדרה וצלעות - נקודת התורפה. כל אחד שונה: גוון עור, כתמים, צלקות, צלצל תקוע, אצות.
#  מה הוא למד, וממה: פילי הים על החוף שרדו כל דבר בזכות שכבת שומן ובטן שמחליקה על החלוקים - והמת למד ללבוש אותם.
#  איך הוא עובד:
#    SEEK    - מדדה אליך לאט (גלומפינג). אתה מאחוריו -> TURN (TURN_T, איטי - הגב חשוף x TURN_MULT).
#    BELLOW  - מתרומם, החדק מתנפח, שאגה עמוקה (BELLOW_T) - הסימן.
#    CHARGE  - מסתער על הבטן (CHARGE_V, עד CHARGE_T): פוגע = CHARGE_DMG והדיפה, מעיף זומבים אחרים, מפזר מושבות.
#              לקפוץ מעליו / להתגלגל. נכנס בקיר = נתקע (WALL_STUN).
#    WALLOW  - אחרי ההסתערות מתבוסס בחול (WALLOW_T) - פגיע מכל כיוון (x WALLOW_MULT), ואז מסתובב אליך (TURN).
#  שריון: מלפנים העור עבה - x FRONT_MULT (x CHARGE_FRONT בזמן הסתערות). מאחור (הבשר החשוף) x BACK_MULT. אש x FIRE_MULT.
#  מוות: מתפוצץ רטוב - דם, נתחי שומן, ושלולית שמן חלקה שנדלקת (effects/s57_decor.gd Slick), העור נשאר שטוח על החוף.
#  נגד: לחכות להסתערות, לקפוץ מעליה, ולירות לו בגב בזמן שהוא מתבוסס / מסתובב.
#  לומד (main meta "bl_dodges" >= LEARN_DODGES הסתערויות שהתחמקו מהן): "IT FAKES THE CHARGE" - זינוק מזויף קצר (LURCH_T)
#    שעוצר בבת אחת (אתה קופץ לחינם), ומיד אחריו ההסתערות האמיתית אחרי שאגה קצרה (FEINT_PAUSE).
#  לשנות: CHARGE_R, BELLOW_T, CHARGE_V, CHARGE_T, CHARGE_DMG, WALLOW_T, WALL_STUN, TURN_T, FRONT_MULT, CHARGE_FRONT,
#         BACK_MULT, WALLOW_MULT, TURN_MULT, FIRE_MULT, CHARGE_CD, LURCH_*, FEINT_PAUSE, LEARN_DODGES, SLICK_W.
# ============================================================

const Decor := preload("res://effects/s57_decor.gd")

const SOUNDS := {
	"bl_bellow": {"rev": 0.35, "drive": 3.0, "layers": [["V", 58, 50, 0.0, 1.0, 0.06, 1.6, 1.0, 1.0, 0.18, 0, [300, 620, 18]], ["V", 87, 76, 0.0, 1.0, 0.06, 1.6, 0.6, 1.0, 0.18, 0, [380, 800, 16]], ["N", 0, 0, 0.0, 0.9, 0.1, 2.0, 0.35, 0.12, 0]]},
	"bl_galump": [["N", 0, 0, 0.0, 0.12, 0.0, 30.0, 0.5, 0.12, 0], ["S", 70, 40, 0.0, 0.14, 0.0, 22.0, 0.6, 1.0, 0]],
	"bl_charge": {"rev": 0.2, "layers": [["N", 0, 0, 0.0, 1.2, 0.05, 1.6, 0.6, 0.2, 0, 0.03], ["S", 64, 48, 0.0, 1.0, 0.05, 2.0, 0.6, 1.0, 0.0], ["V", 70, 62, 0.0, 0.7, 0.05, 2.5, 0.5, 1.0, 0.2, 0, [320, 650, 16]]]},
	"bl_slap": {"rev": 0.2, "drive": 2.0, "layers": [["N", 0, 0, 0.0, 0.25, 0.0, 14.0, 1.0, 0.35, 0], ["S", 110, 50, 0.0, 0.25, 0.0, 12.0, 0.8, 1.0, 0]]},
	"bl_armor": [["S", 160, 90, 0.0, 0.1, 0.0, 30.0, 0.5, 1.0, 0], ["N", 0, 0, 0.0, 0.08, 0.0, 40.0, 0.35, 0.15, 0]],
	"bl_death": {"rev": 0.4, "drive": 2.4, "layers": [["N", 0, 0, 0.0, 0.9, 0.0, 4.0, 1.0, 0.25, 0], ["S", 70, 30, 0.0, 0.7, 0.0, 4.0, 1.0, 1.0, 0], ["V", 70, 40, 0.0, 1.3, 0.05, 1.8, 0.7, 1.0, 0.2, 0, [300, 600, 16]], ["N", 0, 0, 0.1, 0.6, 0.0, 6.0, 0.5, 0.6, 0, 0.2]]},
}

const CHARGE_R := 520.0
const BELLOW_T := 0.7
const CHARGE_V := 440.0
const CHARGE_T := 1.4
const CHARGE_DMG := 2
const CHARGE_PAST := 220.0        # ההסתערות נגמרת אחרי שעבר אותך בכך
const WALLOW_T := 1.6
const WALL_STUN := 2.4
const TURN_T := 0.6
const FRONT_MULT := 0.6
const CHARGE_FRONT := 0.3
const BACK_MULT := 1.8
const WALLOW_MULT := 1.5
const TURN_MULT := 1.8
const FIRE_MULT := 1.3
const CHARGE_CD := Vector2(2.0, 3.2)
const LURCH_T := 0.35
const LURCH_V := 300.0
const FEINT_PAUSE := 0.3
const LEARN_DODGES := 2
const SLICK_W := 170.0

enum {SEEK, BELLOW, LURCH, PAUSE, CHARGE, WALLOW, TURN}
var state := SEEK
# לבדיקות
var charges := 0
var charge_hits := 0
var bowled := 0
var dodges := 0
var wallows := 0
var turns := 0
var back_hits := 0
var front_hits := 0
var lurches := 0
var wall_stuns := 0

var learned := false
var _st := 0.0
var _cd := 1.5
var _hit := false
var _in_path := false
var _last_dir := Vector2.ZERO
var _turn_from := 1.0
var _flipped := false
var _var := []     # [עור, כתמים(seed), צלקות, גודל גב חשוף, צלצל, אצות, גודל חדק]
var _gal := 0.0
var _armor_t := 0.0
var _hurt_back := 0.0
var _engaged := false


func stats() -> Dictionary:
	return {"name": "BLUBBER", "hp": 70, "walk": 30.0, "chase": 58.0, "damage": 2, "bite_delay": 1.2, "scale": 1.15, "width": 1.5,
		"duck": 0.0, "cover": 0.0, "skin": Color("c8c0b0"), "shirt": Color("6e625a"), "pants": Color("5a5048"), "shoe": Color("4a423c"),
		"points": 460, "ragdoll": false}


func brain_overrides() -> Dictionary:
	return {"aggression": 0.8}


func use_brain_movement() -> bool:
	return false


func can_bite() -> bool:
	return false


func death_sound() -> String:
	return "bl_death"


func _main() -> Node:
	return z.get_parent()


func setup() -> void:
	var m := _main()
	learned = m != null and int(m.get_meta("bl_dodges", 0)) >= LEARN_DODGES
	var r := RandomNumberGenerator.new()
	r.seed = z.get_instance_id()
	var hides := [Color("7a6e64"), Color("8a7a6a"), Color("6a6460"), Color("857160")]
	_var = [hides[r.randi() % hides.size()], r.randi(), r.randi_range(2, 4), r.randf_range(0.8, 1.2), r.randf() < 0.4, r.randf() < 0.5, r.randf_range(0.85, 1.25)]
	_resize(Vector2(62.0, 48.0))


func _resize(b: Vector2) -> void:
	var rs := z._shape.shape as RectangleShape2D
	rs.size = Vector2(b.x * z.wf * z.sc * 0.84, b.y * z.sc)
	z._shape.position = Vector2(0.0, -b.y * 0.5 * z.sc)


# ============================================================
#  תנועה
# ============================================================
func physics(pl: Node, delta: float) -> bool:
	_st -= delta
	_cd -= delta
	_armor_t -= delta
	_hurt_back = maxf(0.0, _hurt_back - delta)
	if not z.is_on_floor():
		z.velocity.y += z.gravity * delta
	var has: bool = pl != null and not pl.dead
	var d: Vector2 = (pl.global_position - z.global_position) if has else Vector2.ZERO
	var met: bool = has and (_engaged or absf(d.x) < z.chase_range or z._alert_t > 0.0)
	if met and absf(d.x) < z.chase_range:
		_engaged = true   # ראה אותך: לא שוכח אחרי שהסתער רחוק
	if has and absf(d.x) > 1300.0:
		_engaged = false
	match state:
		SEEK:
			if not met:
				z.velocity.x = move_toward(z.velocity.x, 0.0, 400.0 * delta)
			else:
				if d.x * z._dir < -20.0:   # אתה מאחוריו: מסתובב לאט
					_start_turn()
				else:
					_gal += delta * 6.0
					z.velocity.x = move_toward(z.velocity.x, z._dir * z.chase_speed * (0.6 + 0.6 * maxf(0.0, sin(_gal))), 500.0 * delta)
					if fposmod(_gal, TAU) < 6.0 * delta and Art.on_screen(z, z.global_position):
						Sfx.play("bl_galump", z.global_position, -6.0, 0.15, 3)
					if _cd <= 0.0 and absf(d.x) < CHARGE_R and absf(d.y) < 90.0 and z.is_on_floor():
						state = BELLOW
						_st = BELLOW_T
						Sfx.play("bl_bellow", z.global_position, 2.0, 0.08, 2)
		BELLOW, PAUSE:
			z.velocity.x = move_toward(z.velocity.x, 0.0, 1200.0 * delta)
			if has and absf(d.x) > 10.0 and state == BELLOW and _st > BELLOW_T * 0.5:
				z._dir = signf(d.x)
			if _st <= 0.0:
				if state == BELLOW and learned and randf() < 0.6:
					state = LURCH
					lurches += 1
					_st = LURCH_T
					z.velocity.x = z._dir * LURCH_V
					Sfx.play("bl_charge", z.global_position, -2.0, 0.08, 2)
					var m := _main()
					if m != null and not m.has_meta("bl_said"):
						m.set_meta("bl_said", true)
						z._popup("IT FAKES THE CHARGE", Color("ff8a7a"), 12, -90.0)
				else:
					_start_charge(pl, d)
		LURCH:   # זינוק מזויף: נעצר בבת אחת
			if _st <= 0.0:
				z.velocity.x = 0.0
				state = PAUSE
				_st = FEINT_PAUSE
				Sfx.play("bl_bellow", z.global_position, 0.0, 0.08, 2, 1.25)
		CHARGE:
			z.velocity.x = move_toward(z.velocity.x, z._dir * CHARGE_V, 2400.0 * delta)
			_gal += delta * 16.0
			if Engine.get_physics_frames() % 4 == 0 and Art.on_screen(z, z.global_position):
				Particles.burst(_main(), z.global_position + Vector2(-z._dir * 30.0, -4.0), "smoke", Vector2(-z._dir, -0.6), 2)
			var me := Rect2(z.global_position + Vector2(-34.0 * z.sc, -40.0 * z.sc), Vector2(68.0 * z.sc, 40.0 * z.sc))
			if has and not _hit and me.intersects(pl.body_rect()):
				_hit = true
				if pl._roll_t <= 0.0:
					charge_hits += 1
				pl.hurt(CHARGE_DMG, Vector2(z._dir * 2.2, -0.6))
				Sfx.play("bl_slap", pl.global_position, 2.0, 0.1, 2)
			if Engine.get_physics_frames() % 3 == 0:
				for o in z.get_tree().get_nodes_in_group("zombies"):
					if o == z or o.dead or o.is_boss() or o.get_meta("bl_bowled", -1) == z.get_instance_id():
						continue
					if absf(o.global_position.x - z.global_position.x) < 46.0 * z.sc and absf(o.global_position.y - z.global_position.y) < 30.0:
						o.set_meta("bl_bowled", z.get_instance_id())
						bowled += 1
						o.stagger(0.9)
						o.velocity += Vector2(z._dir * 320.0, -220.0)
						if o._dir == z._dir:
							o._dir = -o._dir
				for c in z.get_tree().get_nodes_in_group("s57_colonies"):
					if absf(c.center().x - z.global_position.x) < 120.0 and c.huddled():
						c.scatter(z.global_position.x - z._dir * 50.0, true)
			var wall: bool = z.is_on_wall() and _st < CHARGE_T - 0.15
			var past: bool = has and (z.global_position.x - pl.global_position.x) * z._dir > CHARGE_PAST
			if _st <= 0.0 or wall or past:
				_end_charge(pl, wall)
		WALLOW:
			z.velocity.x = move_toward(z.velocity.x, 0.0, 1100.0 * delta)
			_gal += delta * 3.0
			if Engine.get_physics_frames() % 10 == 0 and Art.on_screen(z, z.global_position):
				Particles.burst(_main(), z.global_position + Vector2(randf_range(-30, 30), -6.0), "smoke", Vector2.UP, 2)
			if _st <= 0.0:
				_resize(Vector2(62.0, 48.0))
				_cd = randf_range(CHARGE_CD.x, CHARGE_CD.y)
				if has and d.x * z._dir < 0.0:
					_start_turn()
				else:
					state = SEEK
		TURN:
			z.velocity.x = move_toward(z.velocity.x, 0.0, 600.0 * delta)
			if not _flipped and _st <= TURN_T * 0.5:
				_flipped = true
				z._dir = -_turn_from
			if _st <= 0.0:
				state = SEEK
				_cd = maxf(_cd, 0.6)
	z.move_and_slide()
	return true


func _start_turn() -> void:
	state = TURN
	turns += 1
	_st = TURN_T
	_turn_from = z._dir
	_flipped = false


func _start_charge(pl: Node, d: Vector2) -> void:
	state = CHARGE
	charges += 1
	_st = CHARGE_T
	_hit = false
	_in_path = pl != null and d.x * z._dir > 0.0 and absf(d.y) < 90.0
	_resize(Vector2(70.0, 38.0))
	Sfx.play("bl_charge", z.global_position, 3.0, 0.08, 2)
	for o in z.get_tree().get_nodes_in_group("zombies"):
		if o.has_meta("bl_bowled") and o.get_meta("bl_bowled") == z.get_instance_id():
			o.remove_meta("bl_bowled")


func _end_charge(pl: Node, wall: bool) -> void:
	state = WALLOW
	wallows += 1
	_st = WALL_STUN if wall else WALLOW_T
	_resize(Vector2(70.0, 34.0))
	if wall:
		wall_stuns += 1
		Sfx.play("bl_slap", z.global_position, 4.0, 0.05, 2, 0.7)
		z._popup("STUCK!", Color("ffd34a"), 13, -70.0)
		var cam: Camera2D = z.get_viewport().get_camera_2d()
		if cam != null and cam.has_method("shake") and Art.on_screen(z, z.global_position):
			cam.shake(7.0, 0.25)
	# התחמקת (עברת אותו בלי שנפגעת) -> הם לומדים
	if _in_path and not _hit and pl != null and not pl.dead and (pl.global_position.x - z.global_position.x) * z._dir < 0.0:
		dodges += 1
		var m := _main()
		if m != null:
			m.set_meta("bl_dodges", int(m.get_meta("bl_dodges", 0)) + 1)


# ============================================================
#  נזק: חזית משוריינת, גב חשוף
# ============================================================
func on_damage(_amount: int, _hit_pos: Vector2, dir: Vector2, _src: Dictionary) -> bool:
	_last_dir = dir
	return true


func damage_mult(_zone: String, src: Dictionary) -> float:
	var s := str(src.get("source", "bullet"))
	if s == "fire":
		return FIRE_MULT
	if not (s == "bullet" or s == "melee"):
		return 1.0 if state != WALLOW else WALLOW_MULT
	var front: bool = _last_dir.x * z._dir < 0.0
	if state == TURN:
		back_hits += 1
		_hurt_back = 0.25
		return TURN_MULT
	if not front:
		back_hits += 1
		_hurt_back = 0.25
		return BACK_MULT
	if state == WALLOW:
		return WALLOW_MULT
	front_hits += 1
	if _armor_t <= 0.0:
		_armor_t = 0.35
		Sfx.play("bl_armor", z.global_position + Vector2(z._dir * 20.0, -30.0), -2.0, 0.15, 3)
		z._popup("THICK HIDE", Color("c8b8a0"), 11, -80.0)
		var m := _main()
		var pl := player()
		if m != null and pl != null and not m.has_meta("bl_hint") and front_hits >= 3:
			m.set_meta("bl_hint", true)
			pl._say("Its hide's too thick - get behind it!", Color("ffd34a"))
	return CHARGE_FRONT if state == CHARGE else FRONT_MULT


func on_death() -> void:
	var m := _main()
	var p: Vector2 = z.global_position
	var g := Quality.gore()
	Particles.burst(m, p + Vector2(0, -30), "hit", Vector2.UP, int(34.0 * g) + 6)
	Particles.burst(m, p + Vector2(0, -20), "hit", Vector2(-z._dir, -0.5), int(18.0 * g) + 4)
	Particles.burst(m, p + Vector2(0, -12), "drop", Vector2.UP, 10)
	var cam: Camera2D = z.get_viewport().get_camera_2d()
	if cam != null and cam.has_method("shake") and Art.on_screen(z, p):
		cam.shake(9.0, 0.35)
	Sfx.play("bl_slap", p, 4.0, 0.05, 2, 0.6)
	call_deferred("_after_death")


func _after_death() -> void:
	if not is_instance_valid(z):
		return
	z.velocity = Vector2(z.velocity.x * 0.12, minf(z.velocity.y, 0.0) * 0.2)
	z._spin = 0.0
	z._angle = 0.0
	var m := _main()
	if m == null or not z.is_on_floor() and z.global_position.y < 400.0:
		return
	var sl = Decor.Slick.new()
	sl.w = SLICK_W
	sl.life = 14.0
	sl.grow_t = 0.5
	sl.col = Color(0.2, 0.1, 0.06)
	m.add_child(sl)
	sl.global_position = Vector2(z.global_position.x, z.global_position.y - 1.0)


func wants_redraw() -> bool:
	return true


# ============================================================
#  ציור (פונה ימינה, 0 = על החול מתחת לבטן)
# ============================================================
func _body_pts(rise: float, hump: float, flat: float) -> Array:
	# קו השדרה מהזנב לצוואר + עובי -> מתאר סגור (עליון + תחתון)
	var spine := [Vector2(-38, -7), Vector2(-28, -11 - hump * 0.5), Vector2(-16, -16 - hump), Vector2(-3, -19 - hump * 0.6), Vector2(9, -21 - rise * 0.4), Vector2(18, -26 - rise * 0.8), Vector2(24, -33 - rise)]
	var thick := [4.0, 8.0, 12.5, 14.0, 13.0, 11.0, 9.0]
	var top := PackedVector2Array()
	var bot := PackedVector2Array()
	for k in spine.size():
		var a: Vector2 = spine[maxi(k - 1, 0)]
		var b: Vector2 = spine[mini(k + 1, spine.size() - 1)]
		var n := (b - a).normalized().orthogonal()   # (שמאלה מהכיוון = למעלה)
		var th: float = thick[k] * (1.0 + flat * 0.25)
		var sp: Vector2 = spine[k]
		var tp := sp + n * th * (1.0 - flat * 0.4)
		var bt := sp - n * th
		bt.y = minf(bt.y, 0.0)
		top.append(tp)
		bot.append(bt)
	return [spine, top, bot]


func draw() -> bool:
	if _var.is_empty():
		return false
	var hide: Color = _var[0]
	var seed_v: int = _var[1]
	var tt: float = z._time
	if z.dead:
		_draw_dead(hide, seed_v)
		return true
	begin_draw()
	var rise := 4.0 + sin(_gal) * 3.0
	var hump := maxf(0.0, sin(_gal + 1.2)) * 4.0
	var flat := 0.0
	var prob := float(_var[6])
	var mouth := 0.25
	var tilt := 0.0
	match state:
		BELLOW, PAUSE:
			var k := clampf(1.0 - _st / (BELLOW_T if state == BELLOW else FEINT_PAUSE), 0.0, 1.0)
			rise = 9.0 + sin(k * PI) * 6.0
			prob *= 1.0 + 0.6 * sin(k * PI)
			mouth = 0.9
			tilt = -0.08
		LURCH:
			rise = 0.0
			flat = 0.6
		CHARGE:
			rise = -4.0 + sin(_gal) * 2.5
			hump = maxf(0.0, sin(_gal)) * 6.0
			flat = 0.8
			mouth = 0.6
		WALLOW:
			rise = -6.0 + sin(_gal * 2.0) * 2.0
			hump = 2.0
			flat = 1.0
			mouth = 0.4
		TURN:
			mouth = 0.3
	if state == TURN:   # מסתובב: מתכווץ ברוחב ונהפך
		var k2 := clampf(1.0 - _st / TURN_T, 0.0, 1.0)
		var sx := absf(cos(k2 * PI)) * 0.8 + 0.2
		var s := Vector2(z._dir * z.wf * z.sc * sx, z.sc)
		z.draw_set_transform_matrix(Transform2D(z.react_tilt(), Vector2.ZERO) * Transform2D(0.0, s, 0.0, Vector2.ZERO))
	elif tilt != 0.0:
		var s2 := Vector2(z._dir * z.wf * z.sc, z.sc)
		z.draw_set_transform_matrix(Transform2D(z.react_tilt() + tilt * z._dir, Vector2.ZERO) * Transform2D(0.0, s2, 0.0, Vector2.ZERO))
	var r := RandomNumberGenerator.new()
	r.seed = seed_v
	var B: Array = _body_pts(rise, hump, flat)
	var spine: Array = B[0]
	var top: PackedVector2Array = B[1]
	var bot: PackedVector2Array = B[2]
	var hd := col(hide)
	var light := col(Art.shade(hide, 0.22))
	var dark := col(Art.shade(hide, -0.3))
	# סנפירי זנב (מאחור)
	var tl: Vector2 = spine[0]
	var fl := sin(tt * 3.0 + _gal) * 2.0
	Art.fill(z, PackedVector2Array([tl, tl + Vector2(-10, -6 + fl), tl + Vector2(-13, -1 + fl), tl + Vector2(-9, 2)]), dark, Art.OUTLINE, 1.0)
	Art.fill(z, PackedVector2Array([tl + Vector2(0, 2), tl + Vector2(-9, 5 - fl), tl + Vector2(-12, 7 - fl), tl + Vector2(-6, 7)]), col(Art.shade(hide, -0.2)), Art.OUTLINE, 1.0)
	# יד אחורית (סנפיר אנושי)
	var chest: Vector2 = spine[4]
	var pull := sin(_gal * (1.0 if state != CHARGE else 1.0)) * 6.0
	_arm(chest + Vector2(-2, 4), chest + Vector2(6 - pull, 15.0 - chest.y * 0.0), true)
	# הגוף
	var poly := PackedVector2Array(top)
	for k in range(bot.size() - 1, -1, -1):
		poly.append(bot[k])
	Art.fill_shaded(z, poly, hd, 0.16, 0.32, Art.OUTLINE, 1.4)
	# בטן בהירה (חלוקים שרוטים)
	var belly := PackedVector2Array()
	for k in range(1, bot.size()):
		belly.append(bot[k])
	for k in range(bot.size() - 1, 0, -1):
		belly.append(bot[k].lerp(spine[k], 0.38))
	z.draw_colored_polygon(belly, col(Color(light.r, light.g * 0.98, light.b * 0.92, 0.85)))
	for q in 4:   # שריטות בבטן
		var bx: float = lerpf(-26.0, 14.0, float(q) / 3.0)
		z.draw_line(Vector2(bx, -2.5), Vector2(bx + 5.0, -4.0), col(Art.shade(hide, 0.35)), 0.7)
	# כתמי נשירה (עור שמתקלף)
	for q in 4:
		var k := r.randi_range(1, 5)
		var c: Vector2 = (spine[k] as Vector2).lerp(top[k], r.randf_range(0.1, 0.6)) + Vector2(r.randf_range(-4, 4), 0)
		Art.oval(z, c, r.randf_range(3.0, 5.5), r.randf_range(1.6, 3.0), col(Color(0.72, 0.62, 0.5, 0.75)), r.randf_range(-0.3, 0.3), Art.NONE)
		z.draw_arc(c, 3.5, 0.2, 2.6, 6, col(Color(0.9, 0.84, 0.74, 0.7)), 0.7)
	# צלקות קרב ורודות
	for q in int(_var[2]):
		var k := r.randi_range(2, 5)
		var c: Vector2 = (spine[k] as Vector2).lerp(bot[k], r.randf_range(0.1, 0.5))
		var a := r.randf_range(-0.6, 0.6)
		z.draw_line(c, c + Vector2(cos(a), sin(a)) * r.randf_range(5.0, 9.0), col(Color(0.85, 0.5, 0.5, 0.85)), 0.9)
	# הגב הקרוע: בשר חשוף, עמוד שדרה, צלעות (נקודת התורפה) - בוהק כשנפגע בגב
	var raw: float = _var[3]
	var g0: Vector2 = (spine[1] as Vector2).lerp(top[1], 0.55)
	var g1: Vector2 = (spine[3] as Vector2).lerp(top[3], 0.55)
	var gc := (g0 + g1) * 0.5
	var gl := g0.distance_to(g1) * 0.62 * raw
	var ga := (g1 - g0).angle()
	Art.oval(z, gc, gl, 4.6 * raw, col(Color("6a0e10")), ga, Art.OUTLINE, 1.0)
	Art.oval(z, gc + Vector2(0, -0.6), gl * 0.85, 3.2 * raw, col(Color("b02424")), ga, Art.NONE)
	for q in 4:   # צלעות
		var u := -0.7 + float(q) * 0.45
		var pc := gc + Vector2(cos(ga), sin(ga)) * gl * u
		z.draw_line(pc + Vector2(-1.0, -2.6), pc + Vector2(1.2, 2.4), col(Color("e8dcc0")), 1.0)
	for q in 5:   # חוליות
		var u := -0.8 + float(q) * 0.4
		Art.oval(z, gc + Vector2(cos(ga), sin(ga)) * gl * u + Vector2(0, -0.8), 1.2, 1.0, col(Color("f0e6d0")), 0.0, Art.NONE)
	if _hurt_back > 0.0 or state == TURN or state == WALLOW:
		Art.glow(z, gc, 12.0, Color(1.0, 0.3, 0.2, 0.35 if _hurt_back > 0.0 else 0.18))
	# תפרים גסים איפה שהעור נתפר סביב המת
	var st0: Vector2 = (spine[4] as Vector2).lerp(top[4], 0.2)
	for q in 4:
		var p := st0 + Vector2(-float(q) * 3.0, float(q) * 2.6)
		z.draw_line(p + Vector2(-1.3, -1.3), p + Vector2(1.3, 1.3), col(Color("1a1410")), 0.8)
		z.draw_line(p + Vector2(-1.3, 1.3), p + Vector2(1.3, -1.3), col(Color("1a1410")), 0.8)
	# צלצל תקוע / אצות
	if _var[4]:
		var hp0: Vector2 = (spine[2] as Vector2).lerp(top[2], 0.8)
		z.draw_line(hp0, hp0 + Vector2(-14, -14), col(Color("5a4a38")), 1.6)
		z.draw_line(hp0 + Vector2(-14, -14), hp0 + Vector2(-26, -10), Color(0.3, 0.26, 0.2, 0.7), 0.6)
		Art.oval(z, hp0, 2.0, 1.4, col(Color("7a1010")), 0.0, Art.NONE)
	if _var[5]:
		for q in 3:
			var kp: Vector2 = (spine[2 + q] as Vector2).lerp(top[2 + q], 0.9)
			z.draw_polyline(PackedVector2Array([kp, kp + Vector2(1.5, 4.0), kp + Vector2(-0.5, 8.0 + float(q)), kp + Vector2(1.0, 11.0)]), col(Color("5a6a2a")), 1.4)
	# ראש פיל הים (קסדה) + חדק משתלשל, ומתחתיו פני המת
	var nk: Vector2 = spine[6]
	var head := nk + Vector2(5.0, -2.0)
	Art.oval_shaded(z, head, 9.5, 8.0, hd, -0.2)
	# פני המת בתוך הפה של הפיל
	var face := head + Vector2(5.0, 5.0 + mouth * 2.0)
	Art.oval(z, face + Vector2(0, 1), 5.6, 4.4 + mouth * 1.5, col(Color("2a0c0c")), 0.0, Art.OUTLINE, 1.0)
	Art.oval(z, face, 4.2, 3.4, col(Art.shade(z.skin, -0.05)), 0.0, Art.NONE)
	var o := 1.0 + mouth * 2.5
	z.draw_colored_polygon(PackedVector2Array([face + Vector2(-1.0, 1.4), face + Vector2(3.4, 1.0), face + Vector2(3.0, 1.4 + o), face + Vector2(-0.6, 1.4 + o * 0.8)]), col(Color("3a0808")))
	z.draw_line(face + Vector2(-0.6, 1.6), face + Vector2(3.0, 1.3), col(Color("e0d8b0")), 0.7)
	z.draw_circle(face + Vector2(2.0, -1.0), 0.9, Color(1.0, 0.25, 0.15))
	z.draw_circle(face + Vector2(-1.0, -1.0), 0.7, Color(1.0, 0.25, 0.15, 0.8))
	Art.glow(z, face + Vector2(1.0, -1.0), 5.0, Color(1.0, 0.3, 0.15, 0.3))
	# שיניים של פיל הים (ניבים) מעל הפנים
	for q in 2:
		var tp := head + Vector2(1.5 + float(q) * 6.0, 4.0)
		z.draw_colored_polygon(PackedVector2Array([tp, tp + Vector2(1.6, 0), tp + Vector2(0.8, 3.2)]), col(Color("e8dcc0")))
	# עין פיל (מתה, מבריקה)
	Art.oval(z, head + Vector2(3.0, -3.5), 1.7, 1.4, col(Color("0c0a0a")), 0.0, Art.NONE)
	z.draw_circle(head + Vector2(3.5, -4.0), 0.5, Color(0.8, 0.85, 0.9, 0.8))
	# חדק משתלשל מעל הפה (מתנפח בשאגה)
	var pr0 := head + Vector2(6.0, -2.0)
	var sw := sin(tt * 4.0 + _gal) * 1.5
	var pts := PackedVector2Array([pr0, pr0 + Vector2(3.5 * prob, 0.2), pr0 + Vector2(5.8 * prob, 3.0 + sw), pr0 + Vector2(5.5 * prob, 6.5 * prob + sw)])
	Art.limb(z, pts, 3.0 * prob, col(Art.shade(hide, -0.05)))
	for q in 3:   # קמטים בחדק
		var wp: Vector2 = pts[1].lerp(pts[2], 0.3 + float(q) * 0.3)
		z.draw_line(wp + Vector2(-1.2, -0.6), wp + Vector2(1.2, 0.6), col(Art.shade(hide, -0.35)), 0.6)
	Art.oval(z, pts[3] + Vector2(-0.4, 0.8), 1.8 * prob, 1.3 * prob, col(Color("9a6a62")), 0.0, Art.OUTLINE, 0.8)   # קצה בשרני
	z.draw_circle(pts[3] + Vector2(-0.2, 1.3), 0.6, col(Color("2a1a18")))
	# יד קדמית (סנפיר אנושי) מושכת קדימה
	_arm(chest + Vector2(3, 3), chest + Vector2(14 + pull, 15.0), false)
	if state == BELLOW or state == PAUSE:
		var k3 := clampf(_st / BELLOW_T, 0.0, 1.0)
		z.draw_string(ThemeDB.fallback_font, head + Vector2(-2, -14), "!", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(1.0, 0.35, 0.2, 0.4 + k3 * 0.6))
	end_draw()
	return true


# יד אנושית אפורה עם שרוול מעיל קרוע, כף פרושה על החול
func _arm(sh: Vector2, hand: Vector2, back: bool) -> void:
	hand.y = minf(hand.y, -1.5)
	var el := Art.joint(sh, hand, 9.0, 9.0, -1.0)
	var sk := col(Art.shade(Color("8a9488"), -0.18 if back else -0.05))
	Art.limb(z, PackedVector2Array([sh, el]), 4.4, col(Art.shade(z.shirt, -0.2 if back else 0.0)))
	Art.limb(z, PackedVector2Array([el, hand]), 3.2, sk)
	for f in 3:
		z.draw_line(hand, hand + Vector2(2.5 + float(f) * 0.6, -0.6 + float(f) * 0.9), sk, 1.0)


func _draw_dead(hide: Color, seed_v: int) -> void:
	var s := Vector2(z._dir * z.wf * z.sc, z.sc)
	z.draw_set_transform_matrix(Transform2D(0.0, s, 0.0, Vector2.ZERO))
	var r := RandomNumberGenerator.new()
	r.seed = seed_v
	# העור נשאר שטוח על החול, מרוקן, עם שלולית דם
	Art.oval(z, Vector2(0, -1), 46.0, 4.0, Color(0.4, 0.03, 0.03, 0.75), 0.0, Art.NONE)
	var pts := PackedVector2Array([Vector2(-44, -1), Vector2(-36, -6), Vector2(-18, -9), Vector2(0, -8), Vector2(16, -9), Vector2(28, -12), Vector2(36, -9), Vector2(40, -3), Vector2(30, 0), Vector2(-40, 0)])
	Art.fill_shaded(z, pts, col(Art.shade(hide, -0.08)), 0.12, 0.3, Art.OUTLINE, 1.2)
	Art.oval(z, Vector2(-10, -6), 13.0, 2.8, col(Color("8a1414")), 0.05, Art.NONE)
	for q in 4:
		z.draw_line(Vector2(-18 + q * 6, -7), Vector2(-17 + q * 6, -4), col(Color("e8dcc0")), 1.0)
	Art.limb(z, PackedVector2Array([Vector2(36, -8), Vector2(42, -5), Vector2(44, -1)]), 3.6, col(Art.shade(hide, -0.1)))
	Art.oval(z, Vector2(30, -9), 1.4, 1.1, Color(0.05, 0.04, 0.04), 0.0, Art.NONE)
	Art.limb(z, PackedVector2Array([Vector2(20, -3), Vector2(26, 0), Vector2(33, -1)]), 2.6, col(Art.shade(z.skin, -0.2)))
	end_draw()
