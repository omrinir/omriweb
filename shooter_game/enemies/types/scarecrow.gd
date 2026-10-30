extends "res://enemies/zombie_type.gd"
# ============================================================
#  SCARECROW (שלב 24, "BURNING FIELDS") - זומבי שמתחפש לדחליל: תלוי על עמוד בין דחלילים אמיתיים, לא זז, לא נוהם.
#    POSE  - "דחליל" על עמוד (effects/s24_decor.gd scarecrow_body). רמזים: הראש מסתובב אחריך, ואין עליו עורב.
#    DROP  - עברת אותו (WAKE_PASS) / עמדת לידו (WAKE_NEAR, NEAR_T) / ירית בו -> קופץ מהעמוד מאחוריך.
#    STALK - רץ אליך שפוף, מגל ביד.
#    SWING - מרים את המגל (SWING_WIND = אזהרה) ומכה בקשת (DAMAGE).
#    BACK  - קופץ אחורה, ושוב STALK.
#  התחמקות: לירות בדחלילים בלי עורב לפני שעוברים אותם, או לגלגל כשהמגל עולה.
#  לשנות: WAKE_PASS, WAKE_NEAR, SWING_WIND, SWING_R, DAMAGE, BACK_T.
# ============================================================

const Decor := preload("res://effects/s24_decor.gd")

const SOUNDS := {
	"sc_swish": [["N", 0, 0, 0.0, 0.22, 0.03, 12.0, 0.6, 0.6, 0, 0.3], ["S", 1500, 600, 0.0, 0.18, 0.02, 14.0, 0.1, 1.0, 0]],
}

const WAKE_PASS := 50.0      # כמה אחריו אתה צריך לעבור כדי שיקפוץ
const WAKE_NEAR := 60.0      # עומד לידו יותר מ-NEAR_T -> קופץ
const NEAR_T := 0.9
const SWING_WIND := 0.38
const SWING_R := 58.0
const DAMAGE := 2
const BACK_T := 0.45

enum { POSE, DROP, STALK, SWING, BACK }
var state := STALK
var swings := 0              # לבדיקות
var hits := 0
var woke := 0
var _st := 0.0
var _side := 0.0             # באיזה צד השחקן היה כשהוא "תלוי"
var _turn := 0.0             # סיבוב הראש
var _post: Node = null
var _hit := false
var _wake_t := -1.0
var _near_t := 0.0


func stats() -> Dictionary:
	return {"name": "SCARECROW", "hp": 32, "walk": 40.0, "chase": 122.0, "damage": 1, "bite_delay": 0.8, "scale": 1.05, "width": 0.9,
		"duck": 0.0, "cover": 0.0, "skin": Decor.BURLAP, "shirt": Color("5a3a6a"), "pants": Color("3a4a5a"), "shoe": Color("3a2a1a"), "points": 450}


func can_bite() -> bool:
	return false


func can_groan() -> bool:
	return state != POSE


func wants_redraw() -> bool:
	return state != POSE or Engine.get_physics_frames() % 6 == 0


# נקרא אחרי שהזומבי נוצר: עולה על עמוד (דחליל)
func setup() -> void:
	if z.chase_range > 600.0:
		return
	pose_on_post()


func pose_on_post() -> void:
	state = POSE
	z.dormant = false
	z.global_position.y -= Decor.POST_H
	z.velocity = Vector2.ZERO
	var p := Post.new()
	z.get_parent().add_child.call_deferred(p)
	p.position = z.global_position + Vector2(0, Decor.POST_H)
	_post = p


func on_damage(_amount: int, _hit_pos: Vector2, _dir: Vector2, _src: Dictionary) -> bool:
	if state == POSE:
		_wake.call_deferred()
	return true


func _wake() -> void:
	if z == null or not is_instance_valid(z) or z.dead or state != POSE:
		return
	state = DROP
	woke += 1
	var pl := player()
	var dir := 1.0
	if pl != null:
		dir = signf(pl.global_position.x - z.global_position.x) if pl.global_position.x != z.global_position.x else 1.0
	z._dir = dir
	z.velocity = Vector2(dir * 120.0, -260.0)
	Sfx.play("sc_swish", z.global_position, 0.0, 0.1, 2)
	Sfx.play("zscream", z.global_position, -2.0, 0.1, 2, 1.25)
	if _post != null and is_instance_valid(_post):
		_post.empty = true
		_post.queue_redraw()


func on_death() -> void:
	if state == POSE and _post != null and is_instance_valid(_post):
		_post.empty = true
		_post.queue_redraw()


func physics(pl: Node, delta: float) -> bool:
	_st -= delta
	if z.dead:
		return false
	var has_pl: bool = pl != null and not pl.dead
	match state:
		POSE:
			z.velocity = Vector2.ZERO
			if not has_pl:
				return true
			var d: Vector2 = pl.global_position - z.global_position
			_turn = move_toward(_turn, clampf(d.x / 200.0, -1.0, 1.0) * z._dir, delta * 1.5)   # הראש עוקב אחריך (לאט)
			if absf(d.x) < 500.0 and absf(d.y) < 140.0:
				if _side == 0.0:
					_side = signf(d.x)
				_near_t = _near_t + delta if absf(d.x) < WAKE_NEAR else 0.0
				if _wake_t < 0.0 and (_near_t > NEAR_T or (signf(d.x) != _side and absf(d.x) > WAKE_PASS)):
					_wake_t = 0.25   # רגע קטן אחרי שעברת
			else:
				_side = 0.0
			if _wake_t >= 0.0:
				_wake_t -= delta
				if _wake_t < 0.0:
					_wake()
			return true
		DROP:
			if z.is_on_floor() and z.velocity.y >= 0.0:
				state = STALK
			return _move(delta, z.velocity.x)
		STALK:
			if not has_pl:
				return _move(delta, 0.0)
			var d: Vector2 = pl.global_position - z.global_position
			z._dir = signf(d.x) if absf(d.x) > 4.0 else z._dir
			if absf(d.x) < SWING_R - 12.0 and absf(d.y) < 50.0:
				state = SWING
				_st = SWING_WIND
				_hit = false
				return _move(delta, 0.0)
			if z.is_on_wall() and z.is_on_floor():
				z.velocity.y = -430.0
			if d.y < -100.0 and absf(d.x) < 60.0 and z.is_on_floor():   # אתה למעלה: קופץ
				z.velocity.y = -560.0
			return _move(delta, z._dir * float(z.chase_speed))
		SWING:
			if _st <= 0.0 and not _hit:
				_hit = true
				swings += 1
				Sfx.play("sc_swish", z.global_position, 2.0, 0.1, 2)
				if has_pl:
					var d: Vector2 = pl.global_position - z.global_position
					if absf(d.x) < SWING_R * z.sc and absf(d.y) < 56.0 and (signf(d.x) == z._dir or absf(d.x) < 14.0):
						if pl._invuln <= 0.0:
							hits += 1
						pl.hurt(DAMAGE, Vector2(z._dir * 1.4, -0.8))
			if _st <= -0.15:
				state = BACK
				_st = BACK_T
				z.velocity = Vector2(-z._dir * 190.0, -200.0)
			return _move(delta, 0.0)
		BACK:
			if _st <= 0.0 and z.is_on_floor():
				state = STALK
			return _move(delta, z.velocity.x)
	return false


func _move(delta: float, vx: float) -> bool:
	if state == DROP or state == BACK:
		z.velocity.x = move_toward(z.velocity.x, 0.0, 200.0 * delta)
	else:
		z.velocity.x = move_toward(z.velocity.x, vx, 1100.0 * delta)
	if not z.is_on_floor():
		z.velocity.y += z.gravity * delta
	z.move_and_slide()
	return true


# ============================================================
#  ציור: כש"תלוי" = הדחליל של הקישוטים (אותו ציור בדיוק, רק הראש זז).
#  ער: שפוף, רגלי קש, מגל ביד הקדמית.
# ============================================================
func draw() -> bool:
	if state == POSE and not z.dead and z.possessed == null:
		DrawBatch.set_transform(z, Vector2.ZERO, 0.0, Vector2(z._dir * z.sc, z.sc))
		Decor.scarecrow_body(z, z._flash > 0.0, _turn, sin(z._time * 1.3) * 0.6)
		end_draw()
		return true
	begin_draw()
	var sk := col(Decor.BURLAP)
	var shirt := col(z.shirt)
	var straw := col(Decor.WHEAT)
	var p: float = z._walk_phase
	var f: Array = feet(6.0, 3.0)
	var hunch := 6.0 if state == STALK else 2.0
	var hip := Vector2(0, -19)
	var sh := Vector2(2.0 + hunch, -35.0 + hunch * 0.4)
	var head := sh + Vector2(4.0, -7.5)
	z._leg(hip + Vector2(-2, 0), f[1], col(Art.shade(z.pants, 0.25)), straw, col(z.shoe))
	z._leg(hip + Vector2(2, 0), f[0], col(z.pants), straw, col(z.shoe))
	z._arm(sh + Vector2(-3, 1), sh + Vector2(-8.0 - sin(p) * 4.0, 12.0), Art.shade(straw, 0.2), Art.shade(shirt, 0.3))
	Art.fill_shaded(z, PackedVector2Array([sh + Vector2(-7, -1), sh + Vector2(6, 0), hip + Vector2(5, 2), hip + Vector2(-6, 2)]), shirt, 0.12, 0.35)
	DrawBatch.rect(z, Rect2(sh + Vector2(-1, 6), Vector2(5, 5)), col(Color("8a5a2a")))
	for q in 3:
		DrawBatch.line(z, hip + Vector2(-4.0 + float(q) * 4.0, 2), hip + Vector2(-5.0 + float(q) * 5.0, 7), straw, 1.4)
	Art.oval_shaded(z, head, 6.2, 6.8, sk, 0.0)
	for ex in [1.5, 4.5]:
		DrawBatch.circle(z, head + Vector2(ex, -1.5), 1.3, col(Color("1a1414")))
		if not z.dead:
			DrawBatch.circle(z, head + Vector2(ex, -1.5), 0.6, Color(1.0, 0.4, 0.15))   # עיניים בוערות כשהוא ער
	DrawBatch.line(z, head + Vector2(0, 3), head + Vector2(6, 2), col(Color("3a2a1a")), 1.2)
	Art.fill(z, PackedVector2Array([head + Vector2(-11, -4), head + Vector2(11, -4), head + Vector2(6, -6), head + Vector2(4, -12), head + Vector2(-4, -12), head + Vector2(-6, -6)]), straw, Art.OUTLINE, 1.0)
	# יד קדמית + מגל
	var hand: Vector2
	var ang: float
	if state == SWING and _st > 0.0:
		hand = sh + Vector2(-2, -14)
		ang = -2.4
	elif state == SWING:
		hand = sh + Vector2(14, 6)
		ang = 0.6
	else:
		hand = sh + Vector2(10.0 + sin(p) * 2.0, 8.0)
		ang = -0.6
	z._arm(sh + Vector2(3, 1), hand, straw, shirt)
	var tip := hand + Vector2.from_angle(ang) * 11.0
	DrawBatch.line(z, hand, tip, col(Color("5a4028")), 2.2)   # ידית
	var blade := PackedVector2Array()
	for i in 9:
		var a := ang - 1.6 + float(i) * 0.33
		blade.append(tip + Vector2.from_angle(ang + 1.0) * 7.0 + Vector2.from_angle(a) * 8.0)
	DrawBatch.polyline(z, blade, col(Color("b8bcc0")), 2.0)
	if state == SWING and _st <= 0.0 and _st > -0.12:   # קשת של המכה
		DrawBatch.arc(z, sh + Vector2(6, 0), SWING_R * 0.7, -1.4, 0.9, 12, Color(1, 1, 1, 0.5), 2.0)
	end_draw()
	return true


# ---- העמוד שנשאר (עם הקורה). empty = הדחליל קפץ ממנו ----
class Post extends Node2D:
	var empty := false

	func _ready() -> void:
		z_index = -1

	func _draw() -> void:
		DrawBatch.begin(self)
		_draw_b()
		DrawBatch.end(self)

	func _draw_b() -> void:
		preload("res://effects/s24_decor.gd").scarecrow_post(self)
		if empty:   # קש שנשאר על הקורה
			for q in 4:
				DrawBatch.line(self, Vector2(-20.0 + float(q) * 12.0, -preload("res://effects/s24_decor.gd").POST_H - 38.0), Vector2(-22.0 + float(q) * 12.0, -preload("res://effects/s24_decor.gd").POST_H - 30.0), preload("res://effects/s24_decor.gd").WHEAT, 1.2)
