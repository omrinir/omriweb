extends "res://enemies/zombie_type.gd"
# ============================================================
#  SWARMER (שלב 16) - זומבי להקה: כפוף, רזה, רץ מהר ומפחיד על ארבע כמעט. מעט מאוד חיים (קליע אחד).
#  מגיעים בגלים גדולים (levels/stage_16.gd -> HordeDirector) ורצים ישר עליך.
#  מטפסים אחד על השני (כמו ב-World War Z):
#    * חסום (קיר / מכשול / זומבי שעומד לפניו / השחקן גבוה מעליו) -> קופץ על הגב של מי שלפניו.
#    * נוחת על גב של SWARMER אחר = עומד עליו ונסחב איתו. כך נבנות ערימות שמטפסות על קירות וקומות.
#    * מהגובה של הערימה (או מקומה) קופץ לקומה שמעליו אם השחקן שם.
#  קרוב לשחקן: זינוק קצר ונשיכה. השחקן מתחתיו: יורד דרך הקומה.
#  newborn = נולד מה-BROODMOTHER (enemies/types/broodmother.gd): נזרק באוויר, רטוב ומבריק.
#  לשנות: RUN, LEAP_H, HOP_V, POUNCE, BACK_H.
# ============================================================

const SOUNDS := {
	"sw_shriek": [["W", 980, 620, 0.0, 0.3, 0.02, 6.0, 0.32, 0.45, 0.07], ["N", 0, 0, 0.0, 0.3, 0.02, 7.0, 0.3, 0.6, 0]],
}

const RUN := Vector2(215.0, 300.0)      # מהירות ריצה (כל אחד אקראי בטווח)
const ACCEL := 1500.0
const LEAP_H := 150.0                    # כמה גבוה הוא קופץ לבד (קומה ראשונה = 120)
const HOP_V := 430.0                     # קפיצה קטנה על הגב של מי שלפניו
const POUNCE := Vector2(80.0, 170.0)     # טווח זינוק על השחקן
const BACK_H := 27.0                     # גובה הגב (מי שעומד עליו)
const BITE_R := 24.0

static var _members: Array = []          # כל ה-SWARMERS החיים (לטיפוס אחד על השני)
static var _members_frame := -1

var newborn := false
var on_back = null                       # על הגב של מי הוא עומד עכשיו
var climbs := 0                          # לבדיקות: כמה פעמים טיפס על אחר
var _speed := 250.0
var _hop_cd := 0.0
var _pounce_cd := 1.0
var _air_pose := 0.0
var _seed := 0.0
var _tick := 0


func stats() -> Dictionary:
	return {"name": "SWARMER", "hp": 6, "walk": 200.0, "chase": 260.0, "damage": 1, "bite_delay": 0.75, "scale": 0.92, "width": 0.95,
		"duck": 0.0, "cover": 0.0, "skin": Color("9aa39a"), "shirt": Color("3a3836"), "pants": Color("2c2a2a"), "shoe": Color("1a1616"),
		"points": 45, "ragdoll": false}


func brain_overrides() -> Dictionary:
	return {"aggression": 1.0}


func can_groan() -> bool:
	return randf() < 0.35   # הרבה מהם - לא כולם נוהמים


func setup() -> void:
	_speed = randf_range(RUN.x, RUN.y)
	_seed = randf() * 100.0
	_tick = randi() % 3
	_pounce_cd = randf_range(0.5, 2.0)
	z.corpse_time = 3.0          # המון גופות - נעלמות מהר
	z.dormant = false
	z._set_crouch(true)          # צורה נמוכה (כפוף): הראש ב-30 העליונים
	_members.append(z)


static func swarm() -> Array:   # מתעדכן פעם אחת בפריים (חוסך המון כשיש עשרות)
	var f := Engine.get_physics_frames()
	if f != _members_frame:
		_members_frame = f
		_members = _members.filter(func(s): return is_instance_valid(s) and not s.dead)
	return _members


# כמה SWARMERS ערים ליד נקודה (לגבול של HordeDirector)
static func count_near(x: float, r: float) -> int:
	var n := 0
	for s in swarm():
		if absf(s.global_position.x - x) < r:
			n += 1
	return n


func top_y() -> float:
	return z.global_position.y - BACK_H * z.sc


func physics(pl: Node, delta: float) -> bool:
	if z.dead:
		on_back = null
		return false
	_hop_cd -= delta
	_pounce_cd -= delta
	if z.global_position.y > 900.0:   # נפל מחוץ לעולם (נדחק מתחת לכביש)
		z.queue_free()
		return true
	var has_pl: bool = pl != null and not pl.dead
	var d: Vector2 = (pl.global_position - z.global_position) if has_pl else Vector2(z._dir * 300.0, 0.0)
	if absf(d.x) > 10.0:
		z._dir = signf(d.x)
	var dir: float = z._dir
	var grounded: bool = z.is_on_floor()
	# ---- עומד על גב של אחר ----
	if on_back != null:
		if not is_instance_valid(on_back) or on_back.dead or absf(on_back.global_position.x - z.global_position.x) > 17.0 * z.sc:
			on_back = null
		else:
			z.global_position.y = on_back.type_mod.top_y()
			z.velocity.y = 0.0
			grounded = true
	# ---- נוחת על גב של אחר ----
	if on_back == null and not grounded and z.velocity.y > 0.0:
		for s in swarm():
			if s == z or absf(s.global_position.x - z.global_position.x) > 16.0 or s.type_mod.on_back == z:
				continue
			var ty: float = s.type_mod.top_y()
			if absf(s.global_position.x - z.global_position.x) < 13.0 * z.sc and z.global_position.y <= ty + 6.0 and z.global_position.y + z.velocity.y * delta >= ty - 2.0:
				on_back = s
				climbs += 1
				z.global_position.y = ty
				z.velocity.y = 0.0
				grounded = true
				break
	# ---- תנועה ----
	if grounded:
		var want := dir * _speed * (0.25 if absf(d.x) < 14.0 else 1.0)
		z.velocity.x = move_toward(z.velocity.x, want, ACCEL * delta)
		_air_pose = maxf(_air_pose - delta * 6.0, 0.0)
		if has_pl and (Engine.get_physics_frames() + _tick) % 3 == 0:   # החלטות כל פריים שלישי
			_decide(pl, d, dir)
	else:
		z.velocity.y += z.gravity * delta
		z.velocity.x = move_toward(z.velocity.x, dir * _speed, 300.0 * delta)
		_air_pose = minf(_air_pose + delta * 8.0, 1.0)
	if on_back != null and z.velocity.y < 0.0:
		on_back = null
	z.move_and_slide()
	if on_back != null:
		z.global_position.y = on_back.type_mod.top_y()
	z._walk_phase += delta * absf(z.velocity.x) * 0.11 / z.sc
	# ---- נשיכה ----
	if has_pl and absf(d.x) < BITE_R * z.wf and absf(d.y) < 46.0 and z._attack_t <= 0.0:
		z._attack_t = z.bite_delay
		z._bite_anim = 0.25
		pl.hurt(z.damage, Vector2(dir, 0.0))
	return true


# החלטות כשהוא על משהו (רצפה / קומה / גב)
func _decide(pl: Node, d: Vector2, dir: float) -> void:
	# השחקן מעליו: קופץ לקומה אם מגיע, אחרת מטפס על החברים
	if d.y < -70.0 and absf(d.x) < 230.0 and _hop_cd <= 0.0:
		if -d.y <= LEAP_H + 15.0:
			_jump(-d.y + 35.0, d.x * 1.1)
			return
		if absf(d.x) < 70.0 and _climb_target(dir) != null:
			_hop(dir)
			return
	# השחקן מתחתיו (על קומה): יורד דרכה
	if d.y > 70.0 and z.is_on_floor() and on_back == null and absf(d.x) < 260.0:
		z.collision_mask &= ~16
		z._drop_t = 0.35
		return
	# חסום: קיר / מכשול / חבר שעומד לפניו -> טיפוס (לא כשהוא כבר צמוד לשחקן באותו גובה - אז נושך)
	var at_player := absf(d.x) < 60.0 and absf(d.y) < 40.0
	if _hop_cd <= 0.0 and not at_player and (z.is_on_wall() or _blocked(dir)):
		_hop(dir)
		return
	# זינוק על השחקן
	if _pounce_cd <= 0.0 and absf(d.x) > POUNCE.x and absf(d.x) < POUNCE.y and absf(d.y) < 40.0 and on_back == null:
		_pounce_cd = randf_range(1.6, 3.2)
		z.velocity = Vector2(dir * 430.0, -330.0)
		Sfx.play("sw_shriek", z.global_position, -6.0, 0.2, 3)


func _blocked(dir: float) -> bool:
	var s = _climb_target(dir)
	return s != null and absf(s.velocity.x) < 70.0


# החבר הקרוב לפניו (או ממש מתחתיו) שאפשר לטפס עליו
func _climb_target(dir: float):
	for s in swarm():
		if s == z or absf(s.global_position.x - z.global_position.x) > 26.0 or s.type_mod.on_back == z:
			continue
		var dx: float = (s.global_position.x - z.global_position.x) * dir
		if dx > -4.0 and dx < 22.0 * z.sc and absf(s.global_position.y - z.global_position.y) < 10.0:
			return s
	return null


func _hop(dir: float) -> void:
	_hop_cd = randf_range(0.25, 0.45)
	on_back = null
	z.velocity = Vector2(dir * 150.0, -HOP_V)


func _jump(h: float, vx: float) -> void:
	_hop_cd = 0.6
	on_back = null
	z.velocity = Vector2(clampf(vx, -420.0, 420.0), -sqrt(2.0 * z.gravity * clampf(h, 40.0, LEAP_H + 50.0)))


func on_death() -> void:
	on_back = null


# ============================================================
#  ציור: כפוף קדימה, גב עם חוליות בולטות, ראש נמוך ומושט, ידיים ארוכות שכמעט נוגעות ברצפה
# ============================================================
func draw() -> bool:
	begin_draw()
	var sk := col(z.skin)
	var sk2 := col(Art.shade(z.skin, 0.28))
	var rag := col(z.shirt)
	var p: float = z._walk_phase
	var air := _air_pose
	var bob := absf(sin(p)) * 2.0 * (1.0 - air)
	var hip := Vector2(-7.0, -25.0 - bob)
	var sh := Vector2(12.0, -27.0 - bob * 0.6 + sin(p * 2.0) * 0.8)
	var head := sh + Vector2(9.0, -3.0 + sin(z._time * 9.0 + _seed) * 0.8)
	var bite := clampf(z._bite_anim / 0.25, 0.0, 1.0)
	head += Vector2(4.0, 1.0) * bite
	# רגל אחורית (רחוקה)
	_leg(hip + Vector2(-1.0, 1.0), p + PI, sk2, true, air)
	# יד אחורית
	_arm(sh + Vector2(-2.0, 1.0), p + PI, sk2, air, bite)
	# גו: כפוף, עם צלעות וקרעים
	var belly := hip.lerp(sh, 0.5) + Vector2(0.0, 5.0)
	var torso := PackedVector2Array([hip + Vector2(-4.0, -3.0), hip.lerp(sh, 0.45) + Vector2(0.0, -7.5), sh + Vector2(2.0, -4.0),
		sh + Vector2(3.0, 3.0), belly + Vector2(2.0, 2.0), hip + Vector2(-2.0, 5.0)])
	Art.fill_shaded(z, torso, sk, 0.12, 0.45)
	var rags := PackedVector2Array([hip + Vector2(-4.0, -2.0), hip.lerp(sh, 0.4) + Vector2(0.0, -6.0), hip.lerp(sh, 0.62) + Vector2(1.0, 2.5),
		belly + Vector2(-2.0, 6.0), hip + Vector2(-1.0, 6.0)])
	Art.fill(z, rags, rag, Art.OUTLINE, 1.0)
	for i in 3:   # צלעות
		var c := hip.lerp(sh, 0.62 + float(i) * 0.1) + Vector2(0.0, 2.0)
		z.draw_line(c, c + Vector2(-1.0, 4.0), col(Art.shade(z.skin, 0.4)), 1.0)
	for i in 5:   # חוליות בגב
		var v := hip.lerp(sh, 0.1 + float(i) * 0.2) + Vector2(0.0, -6.5 - sin(float(i) * 1.3) * 0.8)
		z.draw_circle(v, 1.5, col(Art.shade(z.skin, -0.15)))
	# רגל קדמית
	_leg(hip + Vector2(1.0, 1.5), p, sk, false, air)
	# ראש: נמוך ומושט, לסת פתוחה, עיניים זוהרות
	var hd := PackedVector2Array([head + Vector2(-5.5, -1.5), head + Vector2(-2.0, -6.0), head + Vector2(4.0, -5.0),
		head + Vector2(7.0, -1.0), head + Vector2(6.0, 2.0), head + Vector2(-3.0, 4.0)])
	Art.fill_shaded(z, hd, sk, 0.0, 0.35)
	var jaw := 2.5 + 3.0 * bite + absf(sin(z._time * 7.0 + _seed)) * 1.2
	Art.fill(z, PackedVector2Array([head + Vector2(-1.0, 3.0), head + Vector2(6.5, 1.5), head + Vector2(5.0, 2.5 + jaw), head + Vector2(-1.0, 4.0 + jaw * 0.5)]),
		col(Art.shade(z.skin, 0.2)), Art.OUTLINE, 1.0)
	z.draw_colored_polygon(PackedVector2Array([head + Vector2(0.0, 3.2), head + Vector2(6.0, 1.8), head + Vector2(4.6, 2.2 + jaw * 0.8)]), Color(0.18, 0.02, 0.02))
	for t in 3:   # שיניים
		z.draw_line(head + Vector2(1.5 + float(t) * 1.6, 2.6), head + Vector2(1.5 + float(t) * 1.6, 3.8), Color(0.9, 0.88, 0.75), 0.8)
	var eye := head + Vector2(3.2, -2.2)
	Art.glow(z, eye, 4.0, Color(1.0, 0.45, 0.15, 0.7))
	z.draw_circle(eye, 1.1, Color(1.0, 0.85, 0.4))
	for h in 4:   # שיער דליל
		var hb := head + Vector2(-4.0 + float(h) * 2.0, -4.5)
		z.draw_line(hb, hb + Vector2(-4.0 - float(h), -1.0 + sin(z._time * 6.0 + float(h)) * 1.2), col(Color("2a2622")), 0.9)
	# יד קדמית
	_arm(sh + Vector2(1.0, 1.5), p, sk, air, bite)
	if newborn:   # רטוב מהלידה
		z.draw_line(hip + Vector2(0.0, -4.0), sh + Vector2(0.0, -4.0), Color(0.7, 0.95, 0.6, 0.45), 1.6)
	end_draw()
	return true


# רגל רצה: ירך -> ברך -> קרסול -> כף (צעדים ארוכים, באוויר מקופלת)
func _leg(hip: Vector2, ph: float, c: Color, back: bool, air: float) -> void:
	var sw := sin(ph)
	var lift := maxf(0.0, cos(ph))
	var foot := Vector2(sw * 10.0 - 2.0, -lift * 6.0)
	foot = foot.lerp(Vector2(-9.0 if back else -4.0, -12.0), air)
	var knee := hip.lerp(foot, 0.5) + Vector2(6.0, -2.0).lerp(Vector2(8.0, -6.0), air)
	Art.limb(z, PackedVector2Array([hip, knee, foot + Vector2(0.0, -2.0)]), 3.2, c)
	Art.fill(z, PackedVector2Array([foot + Vector2(-2.0, -3.0), foot + Vector2(4.0, -2.0), foot + Vector2(4.5, 0.0), foot + Vector2(-2.0, 0.0)]),
		col(Art.shade(z.skin, 0.35 if back else 0.15)), Art.OUTLINE, 0.8)


# יד ארוכה: מתנדנדת ליד הרצפה, באוויר נשלחת קדימה עם טפרים
func _arm(s: Vector2, ph: float, c: Color, air: float, bite: float) -> void:
	var sw := sin(ph + PI)
	var hand := s + Vector2(8.0 + sw * 9.0, 24.0 - absf(sw) * 4.0)
	hand = hand.lerp(s + Vector2(20.0, -4.0), maxf(air, bite))
	var elbow := s.lerp(hand, 0.5) + Vector2(-3.0, 2.0)
	Art.limb(z, PackedVector2Array([s, elbow, hand]), 2.6, c)
	for f in 3:   # טפרים
		var a := -0.5 + float(f) * 0.45
		z.draw_line(hand, hand + Vector2.from_angle(a + (0.0 if air > 0.5 else 0.9)) * 4.5, col(Color("d8d0b0")), 0.9)
