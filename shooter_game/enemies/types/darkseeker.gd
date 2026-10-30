extends "res://enemies/zombie_type.gd"
# ============================================================
#  DARKSEEKER (שלב 54, "LAST BRIDGE") - צייד לילה מהיר, קירח וכחוש, עור חיוור-אפור, עיניים שחורות ענקיות.
#  השראה: "I Am Legend" (ריצ'רד מתיסון) - היצורים של הלילה ששונאים אור, ובונים לעצמם עולם בחושך.
#  "THEY LEARNED TO KILL THE LIGHT":
#    אור  - באור (פנס גשר / פנס של השחקן / זיקוק) הוא מקבל x LIT_MULT נזק. פנס או זיקוק שמאירים אותו -> צווחה ונרתע (RECOIL_T)
#           ובורח מהאור. זיקוק קרוב (FLARE_R) = המום (FLARE_STUN). הוא לא נכנס לקונוס של פנס גשר - מחכה בקצה החושך.
#    SMASH  - פנס גשר בדרך אליך (או שמאיר אותך) -> זורק עליו בורג (WIND_T) ומנפץ אותו (street_lamp.gd shatter). SMASH_CD, עד SMASH_MAX.
#    CLIMB  - בחושך, כשאתה במרחק CLIMB_MIN..CLIMB_MAX: קופץ למעלה אל הקורה העליונה של מסבך הגשר (קבוצה "s54_truss"),
#             זוחל הפוך מתחתיה (CRAWL_V) עד שהוא מעליך, ונופל עליך (POUNCE: DMG + הדיפה). אור עליו שם = נופל המום.
#  לומד (main meta "ds_flash" = כמה שניות הפנס של השחקן דלק בשלב): אחרי FLASH_LEARN - כשהפנס מכוון אליו,
#         הוא מטפס מעליך ונוחת מאחוריך ("THEY COME FROM BEHIND").
#  לשנות: LIT_MULT, RECOIL_T, FLARE_*, SMASH_*, CLIMB_*, CRAWL_V, POUNCE_*, FLASH_LEARN.
# ============================================================

const SOUNDS := {
	"ds_shriek": {"drive": 2.6, "layers": [["V", 640, 420, 0.0, 0.45, 0.01, 5.0, 0.8, 1.0, 0.1, 0, [1500, 2600, 60]], ["N", 0, 0, 0.0, 0.35, 0.0, 8.0, 0.3, 0.8, 0, 0.6]]},
	"ds_hiss": [["N", 0, 0, 0.0, 0.5, 0.05, 4.0, 0.35, 0.95, 0, 0.9], ["S", 3200, 2800, 0.0, 0.4, 0.05, 5.0, 0.04, 1.0, 0.0]],
	"ds_throw": [["N", 0, 0, 0.0, 0.18, 0.02, 14.0, 0.35, 0.3, 0]],
	"ds_climb": [["N", 0, 0, 0.0, 0.08, 0.0, 30.0, 0.3, 0.6, 0, 0.5], ["S", 900, 700, 0.0, 0.06, 0.0, 40.0, 0.12, 1.0, 0.0]],
}

const LIT_MULT := 2.0
const RECOIL_T := 1.0
const FLARE_R := 210.0
const FLARE_STUN := 1.5
const SMASH_CD := 5.0
const SMASH_MAX := 2
const SMASH_R := 420.0
const WIND_T := 0.35
const ROCK_V := 760.0
const CLIMB_MIN := 200.0
const CLIMB_MAX := 560.0
const CLIMB_CD := 6.0
const CLIMB_T := 0.45
const CRAWL_V := 210.0
const POUNCE_DMG := 1
const FLASH_LEARN := 15.0
const BEHIND := 70.0

enum {GROUND, WIND, CLIMB, HANG, DROP}

# לבדיקות
var smashes := 0
var climbs := 0
var pounces := 0
var pounce_hits := 0
var recoils := 0
var flared := 0
var lit_hits := 0
var behind := 0

var state := GROUND
var _t := 0.0
var _scd := 0.4
var _ccd := 0.6
var _smashed := 0
var _lamp: Node = null
var _recoil := 0.0
var _flee := 1.0
var _flares := {}
var _hang_y := 0.0
var _ground_y := 0.0
var _target_x := 0.0
var _mask := 0
var _lit_now := 0.0
var _lit_t := 0.0
var _behind_said := false
var _shield := 0.0


func stats() -> Dictionary:
	return {"name": "DARKSEEKER", "hp": 34, "walk": 70.0, "chase": 168.0, "damage": 1, "bite_delay": 0.6, "scale": 1.0, "width": 0.9,
		"duck": 0.3, "cover": 0.2, "skin": Color("b4b2b0"), "shirt": Color("8a8682"), "pants": Color("2a2826"), "shoe": Color("8a8682"), "points": 420}


func brain_overrides() -> Dictionary:
	return {"aggression": 0.8, "flank_probability": 0.5}


func learned() -> bool:
	var m: Node = z.get_parent()
	return m != null and float(m.get_meta("ds_flash", 0.0)) >= FLASH_LEARN


# ---- אור ----
# כמה מואר הנקודה: [פנס גשר 0/1, אור דינמי (פנס / זיקוק) 0..1]
static func light_at(tree: SceneTree, p: Vector2) -> Array:
	var lamp := 0.0
	for lp in tree.get_nodes_in_group("lamps"):
		if lp._broken or float(lp._on) < 0.5:
			continue
		var hp: Vector2 = lp.global_position + lp.head()
		if p.y < hp.y or p.y > lp.global_position.y + 10.0:
			continue
		var k: float = (p.y - hp.y) / maxf(float(lp.height), 1.0)
		if absf(p.x - hp.x) < lerpf(7.0, float(lp.cone_w), k) * 0.9:
			lamp = 1.0
			break
	var dyn := 0.0
	for n in tree.get_nodes_in_group("dyn_lights"):
		if not n.has_method("lights"):
			continue
		for l in n.lights():
			var r: float = float(l[1]) * 0.75
			var d: float = p.distance_to(l[0])
			if d < r and float(l[2]) > 0.3:
				dyn = maxf(dyn, float(l[2]) * (1.0 - d / r))
	return [lamp, dyn]


func _beam() -> Node:
	for n in z.get_tree().get_nodes_in_group("dyn_lights"):
		if n.get("ability") != null and n.ability != null and n.ability.get("on") == true:
			return n
	return null


func _truss_at(x: float) -> Node:
	for t in z.get_tree().get_nodes_in_group("s54_truss"):
		if x > float(t.x0) + 30.0 and x < float(t.x1) - 30.0:
			return t
	return null


func damage_mult(_zone: String, _src: Dictionary) -> float:
	if _lit_now > 0.25:
		lit_hits += 1
		return LIT_MULT
	return 1.0


func can_bite() -> bool:
	return state == GROUND and _recoil <= 0.0


func use_brain_movement() -> bool:
	return state == GROUND and _recoil <= 0.0


func logic(pl: Node, d: Vector2, _delta: float, speed: float) -> float:
	if state == WIND:
		return 0.0
	if _recoil > 0.0:   # בורח מהאור
		z._dir = _flee
		return z.chase_speed * 1.1
	if pl == null or pl.dead:
		return speed
	# לא נכנס לקונוס של פנס גשר (מחכה בקצה), אלא אם אתה ממש צמוד
	if _lit_now < 0.25 and absf(d.x) > 110.0:
		var ahead: Vector2 = z.global_position + Vector2(z._dir * 34.0, -30.0)
		var la: Array = light_at(z.get_tree(), ahead)
		if float(la[0]) > 0.5:
			return 0.0
	return speed


func physics(pl: Node, delta: float) -> bool:
	_scd -= delta
	_ccd -= delta
	_recoil -= delta
	_shield -= delta
	if z.dead:
		return false
	var tree: SceneTree = z.get_tree()
	var m: Node = z.get_parent()
	var has_pl: bool = pl != null and not pl.dead
	# הפנס של השחקן דלק: סופרים (פעם אחת לפריים לכל השלב)
	var beam := _beam()
	if beam != null and int(m.get_meta("ds_flash_f", -1)) != Engine.get_physics_frames():
		m.set_meta("ds_flash_f", Engine.get_physics_frames())
		m.set_meta("ds_flash", float(m.get_meta("ds_flash", 0.0)) + delta)
	# כמה מואר עכשיו
	if Engine.get_physics_frames() % 3 == 0 or state != GROUND:
		var li: Array = light_at(tree, z.global_position + Vector2(0, -30.0))
		_lit_now = maxf(float(li[0]), float(li[1]))
		if float(li[1]) > 0.35 and _recoil <= -0.6 and state == GROUND:   # פנס / זיקוק עליו
			_recoil = RECOIL_T
			recoils += 1
			_shield = RECOIL_T
			_flee = signf(z.global_position.x - (pl.global_position.x if has_pl else z.global_position.x - z._dir))
			if _flee == 0.0:
				_flee = -float(z._dir)
			Sfx.play("ds_shriek", z.global_position, 0.0, 0.12, 3)
			z.stagger(0.25)
		for f in tree.get_nodes_in_group("decoys"):   # זיקוק קרוב = המום
			if f.get("life") != null and not _flares.has(f.get_instance_id()) and f.global_position.distance_to(z.global_position) < FLARE_R:
				_flares[f.get_instance_id()] = true
				flared += 1
				z.stagger(FLARE_STUN)
				_shield = FLARE_STUN
				z._popup("BLINDED", Color("ffb0a0"), 12, -80.0)
				Sfx.play("ds_shriek", z.global_position, 2.0, 0.1, 2)
				if state == HANG or state == CLIMB:
					_drop(false)
	match state:
		GROUND:
			if not has_pl or z._stagger_t > 0.0 or _recoil > 0.0 or not z.is_on_floor():
				return false
			var dd: Vector2 = pl.global_position - z.global_position
			# SMASH: פנס בדרך / שמאיר אותך
			if _smashed < SMASH_MAX and _scd <= 0.0:
				var lp := _lamp_to_smash(pl)
				if lp != null:
					_lamp = lp
					state = WIND
					_t = WIND_T
					z._dir = signf(lp.global_position.x - z.global_position.x + 0.01)
					Sfx.play("ds_hiss", z.global_position, -2.0, 0.1, 2)
					return false
			# CLIMB: בחושך, מהמרחק הנכון, מתחת למסבך
			var from_behind: bool = learned() and beam != null and _beam_on_me(beam)
			if _ccd <= 0.0 and _lit_now < 0.25 and absf(dd.y) < 60.0 and (from_behind or (absf(dd.x) > CLIMB_MIN and absf(dd.x) < CLIMB_MAX)):
				var tr := _truss_at(z.global_position.x)
				if tr != null and _truss_at(pl.global_position.x) != null:
					_start_climb(tr, pl, from_behind)
					return true
		WIND:
			z.velocity.x = 0.0
			_t -= delta
			if _t <= 0.0:
				_throw()
				state = GROUND
			return false
		CLIMB:
			_t -= delta
			var k: float = 1.0 - clampf(_t / CLIMB_T, 0.0, 1.0)
			z.global_position.y = lerpf(_ground_y, _hang_y, k * k * (3.0 - 2.0 * k))
			z.velocity = Vector2.ZERO
			if _t <= 0.0:
				state = HANG
			return true
		HANG:
			if not has_pl:
				_drop(false)
				return true
			var tx: float = pl.global_position.x + _target_x
			var ddx: float = tx - z.global_position.x
			z._dir = signf(ddx) if absf(ddx) > 2.0 else z._dir
			z.global_position.x += clampf(ddx, -CRAWL_V * delta, CRAWL_V * delta)
			z.global_position.y = _hang_y
			z.velocity = Vector2.ZERO
			z._walk_phase += delta * 9.0
			if Engine.get_physics_frames() % 14 == 0:
				Sfx.play("ds_climb", z.global_position, -8.0, 0.2, 2)
			if _truss_at(z.global_position.x) == null or _lit_now > 0.35:
				_drop(_lit_now <= 0.35)
			elif absf(ddx) < 18.0:
				_drop(true)
			return true
		DROP:
			z.velocity.y += 1500.0 * delta
			z.velocity.x = move_toward(z.velocity.x, 0.0, 200.0 * delta)
			z.move_and_slide()
			if has_pl and not _pounced and z.velocity.y > 0.0:
				var r: Rect2 = pl.body_rect().grow(6.0)
				if r.has_point(z.global_position + Vector2(0, -10.0)) and pl._roll_t <= 0.0:
					_pounced = true
					pounce_hits += 1
					pl.hurt(POUNCE_DMG, Vector2(z._dir * 1.4, -0.6))
					z._popup("POUNCE", Color("ff8a7a"), 13, -70.0)
			if z.is_on_floor():
				state = GROUND
				z.collision_mask = _mask
				Particles.burst(m, z.global_position, "smoke", Vector2.UP, 3)
				_ccd = CLIMB_CD
			return true
	return false


var _pounced := false


func _beam_on_me(beam: Node) -> bool:
	var o: Vector2 = beam.get("_origin")
	var dv: Vector2 = beam.get("_dir")
	var to: Vector2 = z.global_position + Vector2(0, -30.0) - o
	return to.length() < 700.0 and dv.dot(to.normalized()) > 0.7


func _lamp_to_smash(pl: Node) -> Node:
	var best: Node = null
	var bd := SMASH_R
	var px: float = pl.global_position.x
	for lp in z.get_tree().get_nodes_in_group("lamps"):
		if lp._broken:
			continue
		var lx: float = lp.global_position.x
		var dist: float = absf(lx - z.global_position.x)
		if dist > bd or dist < 30.0:
			continue
		# בדרך אליך (בין הזומבי לשחקן) או מאיר אותך
		var between: bool = (lx - z.global_position.x) * (px - lx) > 0.0
		var on_pl: bool = absf(px - lx) < float(lp.cone_w)
		if between or on_pl:
			bd = dist
			best = lp
	return best


func _throw() -> void:
	if _lamp == null or not is_instance_valid(_lamp) or _lamp._broken:
		return
	_scd = SMASH_CD
	var r := Rock.new()
	r.lamp = _lamp
	r.owner_t = self
	var hand: Vector2 = z.global_position + Vector2(z._dir * 8.0, -50.0) * z.sc
	r.position = hand
	var to: Vector2 = _lamp.global_position + _lamp.head()
	r.vel = (to - hand).normalized() * ROCK_V
	z.get_parent().add_child(r)
	Sfx.play("ds_throw", hand, 0.0, 0.1, 2)


func lamp_smashed() -> void:
	smashes += 1
	_smashed += 1
	var m: Node = z.get_parent()
	if not m.has_meta("ds_smash_said"):
		m.set_meta("ds_smash_said", true)
		z._popup("IT KILLED THE LIGHT", Color("ffb0a0"), 14, -84.0)
	Sfx.play("ds_hiss", z.global_position, 0.0, 0.1, 2)


func _start_climb(tr: Node, pl: Node, from_behind: bool) -> void:
	climbs += 1
	state = CLIMB
	_t = CLIMB_T
	_pounced = false
	_ground_y = z.global_position.y
	_hang_y = float(tr.top_y) + 52.0 * z.sc
	_mask = z.collision_mask
	z.collision_mask = 0
	_target_x = 0.0
	if from_behind:   # נוחת מאחוריך
		var face: float = pl._face() if pl.has_method("_face") else 1.0
		_target_x = -face * BEHIND
		behind += 1
		if not _behind_said:
			_behind_said = true
			z._popup("THEY COME FROM BEHIND", Color("ffb0a0"), 13, -90.0)
	Sfx.play("ds_climb", z.global_position, 0.0, 0.1, 2)
	Sfx.play("ds_hiss", z.global_position, -4.0, 0.1, 2)


func _drop(pounce: bool) -> void:
	pounces += 1 if pounce else 0
	state = DROP
	if _mask != 0:
		z.collision_mask = _mask   # בלי זה הוא נופל דרך הכביש (נבדק: fell_out_of_world)
	z.velocity = Vector2(z._dir * (60.0 if pounce else 0.0), 40.0)
	if not pounce:
		z.stagger(0.8)
		_pounced = true
	if pounce:
		Sfx.play("ds_shriek", z.global_position, 1.0, 0.1, 2)


# ============================================================
#  הבורג שהוא זורק על הנורה
# ============================================================
class Rock extends Node2D:
	var lamp: Node = null
	var owner_t = null
	var vel := Vector2.ZERO
	var _t := 0.0

	func _process(delta: float) -> void:
		_t += delta
		if lamp == null or not is_instance_valid(lamp) or _t > 1.2:
			queue_free()
			return
		var to: Vector2 = lamp.global_position + lamp.head()
		var d := to - global_position
		if d.length() < 14.0 or lamp._broken:
			if not lamp._broken:
				lamp.shatter(vel.normalized())
				if owner_t != null and owner_t.z != null and is_instance_valid(owner_t.z):
					owner_t.lamp_smashed()
			queue_free()
			return
		vel = vel.lerp(d.normalized() * ROCK_V, clampf(delta * 6.0, 0.0, 1.0))
		global_position += vel * delta
		rotation += delta * 18.0
		queue_redraw()

	func _draw() -> void:
		DrawBatch.begin(self)
		_draw_b()
		DrawBatch.end(self)

	func _draw_b() -> void:
		DrawBatch.rect(self, Rect2(-3, -2, 6, 4), Color("4a4a50"))
		DrawBatch.rect(self, Rect2(-3, -2, 6, 1.2), Color("8a8a90"))


# ============================================================
#  ציור: כחוש וקירח, צלעות ועמוד שדרה בולטים, עור אפור-חיוור עם כתמים, מכנס קרוע בלבד.
#  רץ שפוף, ידיים ארוכות עם טפרים. עיניים שחורות ענקיות עם נקודת אור לבנה, פה פעור עם שיניים.
#  מואר: מסתיר את העיניים ביד. תלוי על המסבך: הפוך, גפיים אוחזות בקורה.
# ============================================================
func draw() -> bool:
	if state == HANG or state == CLIMB:
		return _draw_hang()
	begin_draw()
	var sk := col(z.skin)
	var f: Array = feet(6.5, 3.0)
	var crouch: float = 0.0 if z.velocity.length() < 40.0 else 1.0
	var hip := Vector2(-1, -24.0 + 2.0 * crouch)
	var sh := Vector2(4.0 + 3.0 * crouch, -42.0 + 5.0 * crouch)
	var head := sh + Vector2(4.5, -5.0 + 1.5 * crouch)
	var t: float = z._time
	# רגליים: מכנס קרוע עד הברך, רגליים יחפות
	z._leg(hip + Vector2(-2, 0), f[1], col(Art.shade(z.pants, 0.25)), sk, sk.darkened(0.3))
	z._leg(hip + Vector2(2, 0), f[0], col(z.pants), sk, sk.darkened(0.2))
	for q in 2:   # השוק החשופה
		var fq: Vector2 = f[q]
		DrawBatch.line(z, hip.lerp(fq, 0.55), fq + Vector2(0, -2), col(sk.darkened(0.1 * float(q))), 2.2)
	# יד אחורית ארוכה
	var hb := sh + Vector2(-4.0 + sin(t * 9.0) * 4.0 * crouch, 20.0 - 4.0 * crouch)
	_arm(sh + Vector2(-2, 1), hb, true)
	# פלג גוף: צלעות, עמוד שדרה, בטן שקועה
	var torso := PackedVector2Array([sh + Vector2(-6, -1), sh + Vector2(6, 1), hip + Vector2(4, 0), hip + Vector2(-5, -1)])
	Art.fill_shaded(z, torso, sk, 0.12, 0.38)
	for q in 4:
		var u := 0.18 + float(q) * 0.15
		var a := sh.lerp(hip, u)
		DrawBatch.line(z, a + Vector2(-1, 0), a + Vector2(4.5, 1.2), col(Art.shade(z.skin, 0.35)), 0.8)
	for q in 5:   # עמוד שדרה
		DrawBatch.circle(z, sh.lerp(hip, 0.1 + float(q) * 0.18) + Vector2(-5.0, 0), 0.9, col(Art.shade(z.skin, -0.12)))
	DrawBatch.colored_polygon(z, Art.ellipse(sh.lerp(hip, 0.45) + Vector2(1, 0), 1.6, 2.4, 0.3, 8), Color(0.3, 0.12, 0.12, 0.35))   # כתם
	_head(head, sk)
	# יד קדמית: טפרים קדימה, או מסתירה את העיניים מהאור
	var hf := sh + Vector2(9.0 + sin(t * 9.0 + PI) * 4.0 * crouch, 16.0 - 5.0 * crouch)
	if _shield > 0.0 or (z._stagger_t > 0.0 and _lit_now > 0.25):
		hf = head + Vector2(4, -1)
	elif state == WIND:
		hf = sh + Vector2(-8, -12)
	elif z._bite_anim > 0.0:
		hf = sh + Vector2(17, 0)
	_arm(sh + Vector2(3, 1), hf, false)
	end_draw()
	return true


func _arm(s: Vector2, h: Vector2, back: bool) -> void:
	var c := col(Art.shade(z.skin, 0.25 if back else 0.0))
	var el := Art.joint(s, h, 12.0, 13.0, -1.0 if back else 1.0)
	Art.limb(z, PackedVector2Array([s, el, h]), 2.2, c)
	var dir := (h - el).normalized()
	for q in 3:   # טפרים
		DrawBatch.line(z, h, h + dir.rotated((float(q) - 1.0) * 0.45) * 4.0, col(Color("2a2420")), 0.9)


func _head(c: Vector2, sk: Color) -> void:
	Art.oval_shaded(z, c, 4.6, 5.2, sk, -0.1)
	DrawBatch.colored_polygon(z, PackedVector2Array([c + Vector2(-3.5, -1.5), c + Vector2(-6.0, -4.0), c + Vector2(-3.8, 1.0)]), col(Art.shade(z.skin, 0.2)))   # אוזן
	if z.dead:
		return
	# עיניים שחורות ענקיות עם נקודת אור
	DrawBatch.colored_polygon(z, Art.ellipse(c + Vector2(2.2, -1.2), 2.3, 2.0, 0.2, 10), col(Color("06060a")))
	DrawBatch.colored_polygon(z, Art.ellipse(c + Vector2(-1.8, -1.2), 1.6, 1.7, 0.0, 8), col(Color("06060a")))
	DrawBatch.circle(z, c + Vector2(2.9, -1.8), 0.6, Color(1, 1, 1, 0.95))
	DrawBatch.circle(z, c + Vector2(-1.4, -1.6), 0.45, Color(1, 1, 1, 0.8))
	# פה פעור עם שיניים
	var o: float = 1.6 if (z._bite_anim > 0.0 or state == WIND or _recoil > 0.0) else 0.6
	DrawBatch.colored_polygon(z, PackedVector2Array([c + Vector2(0.5, 2.0), c + Vector2(5.2, 1.5), c + Vector2(4.8, 3.2 + o), c + Vector2(0.8, 3.0 + o)]), col(Color("1a0608")))
	for q in 4:
		var x := 1.0 + float(q) * 1.1
		DrawBatch.line(z, c + Vector2(x, 2.0), c + Vector2(x + 0.2, 2.9), col(Color("e8e2cc")), 0.6)
		DrawBatch.line(z, c + Vector2(x, 3.0 + o), c + Vector2(x + 0.2, 2.2 + o), col(Color("e8e2cc")), 0.6)
	# ורידים על הקרקפת
	DrawBatch.polyline(z, PackedVector2Array([c + Vector2(-2, -4.5), c + Vector2(0, -2.8), c + Vector2(-0.5, -0.5)]), Color(0.3, 0.3, 0.4, 0.5), 0.6)


# תלוי הפוך מתחת לקורה העליונה: הגוף אופקי, הידיים והרגליים אוחזות למעלה
func _draw_hang() -> bool:
	var s := Vector2(z._dir * z.wf * z.sc, z.sc)
	DrawBatch.set_transform(z, Vector2(0, -52.0 * z.sc), 0.0, s)
	var sk := col(z.skin)
	var t: float = z._time
	var p: float = z._walk_phase
	var body := Vector2(0, 14)
	var grip := -14.0
	# גוף אופקי מתחת לקורה
	Art.fill_shaded(z, PackedVector2Array([body + Vector2(-12, -4), body + Vector2(10, -5), body + Vector2(9, 3), body + Vector2(-11, 3)]), sk, 0.12, 0.35)
	for q in 4:
		DrawBatch.line(z, body + Vector2(-6.0 + float(q) * 4.0, -3.0), body + Vector2(-5.0 + float(q) * 4.0, 2.0), col(Art.shade(z.skin, 0.35)), 0.7)
	# גפיים: ארבע ידיים/רגליים אוחזות בקורה (זוחל)
	var anchors := [Vector2(9, -4), Vector2(5, -4), Vector2(-7, -3), Vector2(-11, -3)]
	for q in 4:
		var a: Vector2 = body + anchors[q]
		var ph: float = p + float(q) * PI * 0.5
		var g := Vector2(a.x + sin(ph) * 5.0, grip - maxf(0.0, cos(ph)) * 2.0)
		var mid := a.lerp(g, 0.5) + Vector2(-3.0 if q < 2 else 3.0, 2.0)
		Art.limb(z, PackedVector2Array([a, mid, g]), 2.0, col(Art.shade(z.skin, 0.1 * float(q % 2))))
		DrawBatch.line(z, g, g + Vector2(2.5, -1.5), col(Color("2a2420")), 0.8)
	z._leg(body + Vector2(-11, 0), body + Vector2(-20, -10 + sin(p) * 2.0), col(z.pants), sk, sk.darkened(0.3))
	# הראש תלוי ומסתכל למטה אליך
	var hc := body + Vector2(14, 4)
	Art.oval_shaded(z, hc, 4.4, 5.0, sk, 0.4)
	DrawBatch.colored_polygon(z, Art.ellipse(hc + Vector2(1.5, 1.5), 2.0, 2.2, 0.3, 10), col(Color("06060a")))
	DrawBatch.circle(z, hc + Vector2(2.0, 2.2), 0.5, Color(1, 1, 1, 0.95))
	DrawBatch.colored_polygon(z, PackedVector2Array([hc + Vector2(-1, 3.0), hc + Vector2(3, 4.0), hc + Vector2(1.5, 6.0 + sin(t * 6.0))]), col(Color("1a0608")))
	DrawBatch.set_transform_matrix(z, Transform2D.IDENTITY)
	return true
