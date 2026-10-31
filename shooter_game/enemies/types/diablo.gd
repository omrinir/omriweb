extends "res://enemies/zombie_type.gd"
# ============================================================
#  DIABLO (שלב 32, "DEVIL'S CARNIVAL") - רקדן דיאבלדה: מסכת שטן ענקית עם קרניים, עיניים בולטות ונחשים,
#  גלימה נוצצת, מגפיים לבנים עם דורבנות.
#  "THEY LEARNED TO DANCE": כשיש מנצח תזמורת (BANDLEADER / הבוס) קרוב (SYNC_R) - הם בסנכרון:
#    בכל פעמה של התזמורת (effects/s32_decor.gd Band) - קפיצה אליך (LEAP), בין פעמות - רוקעים במקום.
#    חצי מהלהקה קופצת מעליך ונוחתת מאחוריך (OVER) - מקיפים אותך. אפשר ללמוד את הקצב ולירות בין הפעמות.
#  בלי מנצח: הולכים רגיל. המנצח מת -> מסוחררים (DIZZY) - איבדו את הקצב.
#  המסכה (MASK_HP): חוסמת יריות בראש מלפנים. נשברת -> נשאר בלי מסכה (ראש פגיע).
#  לשנות: SYNC_R, LEAP_V, OVER_R, MASK_HP, DIZZY_T.
# ============================================================

const SOUNDS := {
	"dv_stomp": [["S", 90, 50, 0.0, 0.12, 0.0, 22.0, 0.6, 1.0, 0], ["N", 0, 0, 0.0, 0.05, 0.0, 60.0, 0.25, 0.3, 0], ["S", 2400, 2300, 0.0, 0.08, 0.0, 40.0, 0.06, 1.0, 0]],
	"dv_mask": [["S", 1200, 900, 0.0, 0.08, 0.0, 40.0, 0.3, 1.0, 0], ["C", 0, 0, 0.0, 0.08, 0.0, 50.0, 0.4, 1.0, 0]],
}

const SYNC_R := 650.0
const LEAP_V := Vector2(190.0, -300.0)
const OVER_R := 170.0
const MASK_HP := 30
const DIZZY_T := 2.2

enum { DANCE, DIZZY }
var state := DANCE
var mask := MASK_HP
var leaps := 0               # לבדיקות
var overs := 0
var dizzies := 0
var masks_broken := 0
var _beat := -1
var _st := 0.0
var _land := false
var _odd := false


func stats() -> Dictionary:
	return {"name": "DIABLO", "hp": 30, "walk": 42.0, "chase": 92.0, "damage": 1, "bite_delay": 0.75, "scale": 1.05, "width": 1.0,
		"duck": 0.0, "cover": 0.0, "skin": Color("8a9a74"), "shirt": Color("b0202a"), "pants": Color("f0eee0"), "shoe": Color("e8e4d8"), "points": 440}


func setup() -> void:
	_odd = (z.get_instance_id() / 7) % 2 == 1


static func leader_near(node: Node, r := SYNC_R) -> bool:
	for b in node.get_tree().get_nodes_in_group("bandleaders"):
		if is_instance_valid(b) and not b.dead and b.global_position.distance_to(node.global_position) < r:
			return true
	return false


func synced() -> bool:
	return state == DANCE and leader_near(z)


func lose_beat() -> void:   # המנצח מת
	if z.dead:
		return
	state = DIZZY
	_st = DIZZY_T
	dizzies += 1
	z._popup("LOST THE BEAT", Color("ffd080"), 12, -84.0)


func can_bite() -> bool:
	return state == DANCE


func on_damage(amount: int, hit_pos: Vector2, dir: Vector2, src: Dictionary) -> bool:
	if mask <= 0:
		return true
	var s := str(src.get("source", "bullet"))
	var ly: float = (hit_pos.y - z.global_position.y) / z.sc
	if (s == "bullet" or s == "melee") and ly < -40.0 and dir.x * z._dir < 0.0:   # ראש מלפנים = המסכה
		mask -= hit_damage(amount, hit_pos, src)
		Sfx.play("dv_mask", hit_pos, -4.0, 0.15, 3)
		Particles.burst(z.get_parent(), hit_pos, "spark", -dir, 4)
		if mask <= 0:
			masks_broken += 1
			z._popup("MASK BROKEN", Color("ffd060"), 13, -90.0)
			for q in 4:
				var c = preload("res://debris.gd").new()
				z.get_parent().add_child(c)
				c.setup(hit_pos, Vector2(4, 3), [Color("c02a2a"), Color("e0c040")][q % 2], Vector2(randf_range(-160, 160), -randf_range(80, 220)))
		return false
	return true


func damage_mult(_zone: String, _src: Dictionary) -> float:
	return 1.6 if state == DIZZY else 1.0


func physics(pl: Node, delta: float) -> bool:
	_st -= delta
	if z.dead:
		return false
	if state == DIZZY:
		z.velocity.x = move_toward(z.velocity.x, 0.0, 600.0 * delta)
		_move(delta)
		if _st <= 0.0:
			state = DANCE
		return true
	var band: Node = preload("res://effects/s32_decor.gd").band()
	if pl == null or pl.dead or band == null or not synced():
		_beat = -1 if band == null else int(band.beat_id)
		return false
	var dx: float = pl.global_position.x - z.global_position.x
	if absf(dx) > 800.0:
		return false
	if _beat < 0:
		_beat = band.beat_id
	if z.is_on_floor() and _land:   # נחיתה = רקיעה
		_land = false
		if Art.on_screen(z, z.global_position):
			Sfx.play("dv_stomp", z.global_position, -6.0, 0.1, 3)
			Particles.burst(z.get_parent(), z.global_position, "smoke", Vector2.UP, 1)
	if band.beat_id != _beat:   # פעמה חדשה -> קפיצה
		_beat = band.beat_id
		if z.is_on_floor():
			z._dir = signf(dx) if absf(dx) > 4.0 else z._dir
			leaps += 1
			_land = true
			if _odd and absf(dx) < OVER_R and absf(pl.global_position.y - z.global_position.y) < 40.0:   # מעליך -> נוחת מאחוריך
				overs += 1
				z.velocity = Vector2(z._dir * maxf(absf(dx) * 1.6 + 120.0, 300.0), -470.0)
			else:
				z.velocity = Vector2(z._dir * LEAP_V.x * (0.6 if absf(dx) < 60.0 else 1.0), LEAP_V.y)
	elif z.is_on_floor():   # בין פעמות: רוקע במקום
		z.velocity.x = move_toward(z.velocity.x, 0.0, 900.0 * delta)
	_move(delta)
	return true


func _move(delta: float) -> void:
	if not z.is_on_floor():
		z.velocity.y += z.gravity * delta
	z.move_and_slide()
	z.global_position.x = clampf(z.global_position.x, 30.0, float(z.world_w) - 30.0)


# ============================================================
#  ציור: מסכת שטן (קרניים, עיניים בולטות, ניבים, נחשים), גלימה עם נצנצים, חגורה, מגפיים לבנים
# ============================================================
func draw() -> bool:
	begin_draw()
	var sk := col(z.skin)
	var cape := col(z.shirt)
	var p: float = z._walk_phase
	var f: Array = feet(4.5, 2.5)
	var pl := preload("res://effects/s32_decor.gd").pulse() if state == DANCE else 0.0
	var hip := Vector2(0, -22 + pl * 1.5)
	var sh := Vector2(1, -37 + pl * 1.5)
	var head := sh + Vector2(3.5, -9)
	if state == DIZZY:
		head += Vector2(sin(z._time * 8.0) * 2.0, 0)
	z._leg(hip + Vector2(-2, 0), f[1], col(Art.shade(z.pants, 0.25)), sk, col(z.shoe))
	z._leg(hip + Vector2(2, 0), f[0], col(z.pants), sk, col(z.shoe))
	for ft in f:   # דורבנות
		DrawBatch.circle(z, ft + Vector2(-4, -2), 1.5, col(Color("e0c040")))
	var hb := sh + Vector2(-6.0 - sin(p) * 2.0, 15.0)
	var hf := sh + Vector2(10.0, -2.0 + sin(z._time * 9.0) * 3.0)   # יד מורמת בריקוד
	z._arm(sh + Vector2(-3, 1), hb, Art.shade(sk, 0.25), Art.shade(cape, 0.3))
	# גלימה עם נצנצים
	Art.fill_shaded(z, PackedVector2Array([sh + Vector2(-9, -1), sh + Vector2(8, 0), hip + Vector2(8, 4), hip + Vector2(-2, 12), hip + Vector2(-12, 8)]), cape, 0.12, 0.4)
	for q in 6:
		var sp := sh + Vector2(-6.0 + float(q % 3) * 5.0, 4.0 + float(q / 3) * 7.0)
		DrawBatch.circle(z, sp, 1.0, Color(1.0, 0.9, 0.4, 0.4 + 0.6 * absf(sin(z._time * 5.0 + float(q)))))
	DrawBatch.line(z, hip + Vector2(-7, -3), hip + Vector2(7, -3), col(Color("e0c040")), 2.0)   # חגורה
	if mask > 0 and not z.dead:   # מסכת השטן
		var m := head
		Art.fill_shaded(z, PackedVector2Array([m + Vector2(-8, 6), m + Vector2(-9, -4), m + Vector2(-4, -9), m + Vector2(4, -9), m + Vector2(9, -4), m + Vector2(9, 6), m + Vector2(3, 10), m + Vector2(-3, 10)]), col(Color("c8202a")), 0.15, 0.35, Art.OUTLINE, 1.2)
		for sgn in [-1.0, 1.0]:   # קרניים מתפתלות
			Art.fill(z, PackedVector2Array([m + Vector2(sgn * 4.0, -8), m + Vector2(sgn * 11.0, -16), m + Vector2(sgn * 9.0, -24), m + Vector2(sgn * 13.0, -28), m + Vector2(sgn * 14.0, -18), m + Vector2(sgn * 7.0, -7)]), col(Color("e0c040")), Art.OUTLINE, 1.0)
		DrawBatch.circle(z, m + Vector2(-3, -2), 3.2, Color("f4f0e0"))   # עיניים בולטות
		DrawBatch.circle(z, m + Vector2(5, -2), 3.2, Color("f4f0e0"))
		DrawBatch.circle(z, m + Vector2(-2.5, -2), 1.5, Color(0.9, 0.1, 0.05))
		DrawBatch.circle(z, m + Vector2(5.5, -2), 1.5, Color(0.9, 0.1, 0.05))
		DrawBatch.line(z, m + Vector2(-5, 5), m + Vector2(7, 5), col(Color("2a0a0a")), 2.0)
		for q in 3:   # ניבים
			DrawBatch.colored_polygon(z, PackedVector2Array([m + Vector2(-4.0 + float(q) * 4.0, 5), m + Vector2(-3.0 + float(q) * 4.0, 9), m + Vector2(-2.0 + float(q) * 4.0, 5)]), Color("f4f0e0"))
		DrawBatch.polyline(z, PackedVector2Array([m + Vector2(-6, -9), m + Vector2(-2, -13), m + Vector2(2, -10), m + Vector2(6, -14)]), col(Color("2a8a3a")), 2.0)   # נחש על הראש
	else:
		Art.oval_shaded(z, head, 5.2, 5.8, sk, 0.0)
		if not z.dead:
			DrawBatch.circle(z, head + Vector2(3.0, -0.5), 1.0, Color(0.85, 0.9, 0.5))
	z._arm(sh + Vector2(3, 1), hf, sk, cape)
	DrawBatch.colored_polygon(z, Art.ellipse(hf + Vector2(1, -2), 3.0, 4.5, 0.0, 8), col(Color("e8e0c8")))   # מטפחת לבנה ביד
	if state == DIZZY:
		for k in 3:
			var a: float = z._time * 5.0 + float(k) * TAU / 3.0
			DrawBatch.circle(z, head + Vector2(cos(a) * 9.0, -18.0 + sin(a) * 2.5), 1.3, Color(1.0, 0.95, 0.5))
	end_draw()
	return true
