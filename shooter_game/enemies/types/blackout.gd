extends "res://enemies/zombie_type.gd"
# ============================================================
#  BLACKOUT (שלב 26, "THE BUNKER") - טכנאי זומבי עם משקפי ראיית לילה ירוקים וחגורת כלים.
#    WALK  - כשהוא רואה אותך והקטע שלך מואר: רץ ללוח החשמל של הקטע (effects/s26_decor.gd FuseBox).
#    RUN   - רץ ללוח (RUN_K מהר).
#    PULL  - מוריד את הידית (PULL_T) -> הקטע חשוך (FuseBox.BLACKOUT_T). בחושך הוא רואה (המשקפיים זוהרים) ומסתער.
#  נגיעה בלוח מחזירה את החשמל. MAX_CUTS ניתוקים לכל היותר.
#  לשנות: SEEK_R, RUN_K, PULL_T, MAX_CUTS, DARK_SPEED.
# ============================================================

const SEEK_R := 900.0        # כמה רחוק הוא מוכן לרוץ ללוח
const RUN_K := 1.35
const PULL_T := 0.8
const MAX_CUTS := 2
const DARK_SPEED := 1.3      # מהר יותר בחושך

enum { WALK, RUN, PULL }
var state := WALK
var cuts := 0                # לבדיקות
var _box: Node = null
var _st := 0.0
var _look := 0.0


func stats() -> Dictionary:
	return {"name": "BLACKOUT", "hp": 32, "walk": 46.0, "chase": 104.0, "damage": 1, "bite_delay": 0.75, "scale": 1.0, "width": 0.92,
		"duck": 0.3, "cover": 0.4, "skin": Color("8a9a90"), "shirt": Color("3a4048"), "pants": Color("2a2e34"), "shoe": Color("1a1a1a"), "points": 450}


func can_bite() -> bool:
	return state == WALK


func _section_box(x: float) -> Node:
	for fb in z.get_tree().get_nodes_in_group("fuse_boxes"):
		if fb.section_has(x):
			return fb
	return null


func in_dark() -> bool:
	var fb := _section_box(z.global_position.x)
	return fb != null and not fb.powered


func logic(_pl: Node, _d: Vector2, _delta: float, speed: float) -> float:   # בחושך - מהר יותר
	return speed * (DARK_SPEED if in_dark() else 1.0)


func physics(pl: Node, delta: float) -> bool:
	_st -= delta
	_look -= delta
	if z.dead:
		return false
	var has_pl: bool = pl != null and not pl.dead
	match state:
		WALK:
			if has_pl and cuts < MAX_CUTS and _look <= 0.0 and z.is_on_floor():
				_look = 0.4
				var d: Vector2 = pl.global_position - z.global_position
				var sees: bool = (z.brain == null or z.brain.sees) or absf(d.x) < 420.0
				if sees and absf(d.x) < 700.0:
					var fb := _section_box(pl.global_position.x)
					if fb != null and fb.powered and absf(fb.global_position.x - z.global_position.x) < SEEK_R and absf(fb.global_position.y - z.global_position.y) < 40.0:
						_box = fb
						state = RUN
						_st = 4.0
						z._popup("!", Color("80ff80"), 16, -70.0)
			return false
		RUN:
			if _box == null or not is_instance_valid(_box) or not _box.powered or _st <= 0.0:
				state = WALK
				return false
			var dx: float = _box.global_position.x - z.global_position.x
			if absf(dx) < 10.0:
				state = PULL
				_st = PULL_T
				z._dir = 1.0
				return _move(delta, 0.0)
			z._dir = signf(dx)
			if z.is_on_wall() and z.is_on_floor():
				z.velocity.y = -440.0
			return _move(delta, signf(dx) * float(z.chase_speed) * RUN_K)
		PULL:
			if _st <= 0.0:
				if _box != null and is_instance_valid(_box) and _box.powered:
					_box.cut()
					cuts += 1
					Particles.burst(z.get_parent(), _box.global_position + Vector2(0, -80), "spark", Vector2.UP, 10)
				state = WALK
				z._alert_t = 6.0
			return _move(delta, 0.0)
	return false


func _move(delta: float, vx: float) -> bool:
	z.velocity.x = move_toward(z.velocity.x, vx, 1100.0 * delta)
	if not z.is_on_floor():
		z.velocity.y += z.gravity * delta
	z.move_and_slide()
	return true


# ============================================================
#  ציור: סרבל אפור, חגורת כלים, משקפי ראיית לילה (זוהרים ירוק בחושך), צבת ביד
# ============================================================
func draw() -> bool:
	begin_draw()
	var sk := col(z.skin)
	var suit := col(z.shirt)
	var p: float = z._walk_phase
	var f: Array = feet(6.0 if state == RUN else 5.0, 3.0)
	var lean := 5.0 if state == RUN else 0.0
	var hip := Vector2(0, -22)
	var sh := Vector2(1.0 + lean, -37)
	var head := sh + Vector2(3.5, -8)
	z._leg(hip + Vector2(-2, 0), f[1], col(Art.shade(z.pants, 0.25)), sk, col(z.shoe))
	z._leg(hip + Vector2(2, 0), f[0], col(z.pants), sk, col(z.shoe))
	z._arm(sh + Vector2(-3, 1), sh + Vector2(-5.0 - sin(p) * 4.0, 14.0), Art.shade(sk, 0.25), Art.shade(suit, 0.3))
	Art.fill_shaded(z, PackedVector2Array([sh + Vector2(-6, -1), sh + Vector2(6, 0), hip + Vector2(5, 2), hip + Vector2(-5, 2)]), suit, 0.12, 0.4)
	DrawBatch.rect(z, Rect2(hip + Vector2(-6, -3), Vector2(13, 4)), col(Color("4a3a24")))   # חגורת כלים
	DrawBatch.rect(z, Rect2(hip + Vector2(-5, 0), Vector2(3, 5)), col(Color("5a4a30")))
	DrawBatch.rect(z, Rect2(hip + Vector2(2, 0), Vector2(3, 4)), col(Color("5a4a30")))
	DrawBatch.rect(z, Rect2(sh + Vector2(-3, 4), Vector2(5, 3)), col(Color("c8b030")))   # תג
	Art.oval_shaded(z, head, 5.4, 5.8, sk, 0.0)
	face(head, Vector2(INF, 0))
	# משקפי ראיית לילה
	DrawBatch.rect(z, Rect2(head + Vector2(-5, -6), Vector2(10, 2)), col(Color("1a1a1a")))   # רצועה
	DrawBatch.rect(z, Rect2(head + Vector2(1, -3.5), Vector2(6, 4)), col(Color("2a2e2a")))
	for ex in [2.5, 5.5]:
		var gc := head + Vector2(ex + 1.0, -1.5)
		DrawBatch.circle(z, gc, 1.6, Color(0.4, 1.0, 0.4) if not z.dead else Color(0.2, 0.25, 0.2))
	if not z.dead and in_dark():
		Art.glow(z, head + Vector2(5, -1.5), 12.0, Color(0.3, 1.0, 0.3, 0.6))
	var hand := sh + (Vector2(4, -14) if state == PULL and _st > PULL_T * 0.5 else (Vector2(8, 8) if state == PULL else Vector2(9.0 + sin(p) * 3.0, 13.0)))
	z._arm(sh + Vector2(3, 1), hand, sk, suit)
	DrawBatch.line(z, hand, hand + Vector2(6, -2), col(Color("c03020")), 2.0)   # צבת
	DrawBatch.line(z, hand + Vector2(6, -2), hand + Vector2(9, -4), col(Color("8a8e90")), 1.6)
	end_draw()
	return true
