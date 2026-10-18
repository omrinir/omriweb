extends "res://enemies/zombie_type.gd"
# ============================================================
#  BALSERO (שלב 31, "FLOATING ISLANDS") - שייט זומבי על סירת קנים (טוטורה) עם ראש פומה, מוט ארוך ביד,
#  ושני נוסעים זומבים בסירה. "THEY LEARNED TO SAIL": מעביר תגבורת.
#    ANCHOR - הסירה קשורה. אתה מתקרב (WAKE_R) -> SAIL
#    SAIL   - שט אליך במים. נתקע באי שלידך -> UNLOAD: הנוסעים קופצים לאי שלך
#    POLE   - אחרי הפריקה: נשאר בסירה ודוחף אותך עם המוט (POLE_R) - הדף חזרה למים
#  הסירה (BOAT_HP): יריות בחלק התחתון פוגעות בסירה. טובעת לפני הפריקה -> הנוסעים טובעים וחוזרים כ-DROWNED!
#  אחרי שהסירה טבעה - הוא זומבי רגיל במים.
#  לשנות: WAKE_R, SAIL_V, BOAT_HP, POLE_R, PASSENGERS.
# ============================================================

const SOUNDS := {
	"bl_crack": [["C", 0, 0, 0.0, 0.2, 0.0, 14.0, 0.8, 1.0, 0], ["N", 0, 0, 0.0, 0.3, 0.0, 10.0, 0.4, 0.4, 0]],
	"bl_pole": [["N", 0, 0, 0.0, 0.18, 0.04, 14.0, 0.4, 0.2, 0], ["S", 160, 90, 0.08, 0.1, 0.0, 30.0, 0.5, 1.0, 0]],
}

const WAKE_R := 900.0
const SAIL_V := 135.0
const BOAT_HP := 45
const POLE_R := 78.0
const POLE_CD := 1.6
const PASSENGERS := 2

enum { ANCHOR, SAIL, UNLOAD, POLE, SINK, FOOT }
var state := ANCHOR
var boat_hp := BOAT_HP
var unloaded := 0            # לבדיקות
var sunk := false
var pokes := 0
var _st := 0.0
var _cd := 0.0
var _poke := 0.0
var _bob := 0.0
var _aboard := PASSENGERS


func stats() -> Dictionary:
	return {"name": "BALSERO", "hp": 34, "walk": 40.0, "chase": 80.0, "damage": 1, "bite_delay": 0.8, "scale": 1.0, "width": 2.2,
		"duck": 0.0, "cover": 0.0, "skin": Color("8a9878"), "shirt": Color("6a4a8a"), "pants": Color("2e2a2a"), "shoe": Color("3a2a1a"), "points": 480}


func setup() -> void:
	z.set_meta("pit_hop", false)
	to_water.call_deferred()   # נולד רק במים פנויים


func _floor() -> float:
	return float(z.get_parent().get_meta("lake_floor", z.global_position.y))


func can_bite() -> bool:
	return state == FOOT


func can_groan() -> bool:
	return state == FOOT


func on_damage(amount: int, hit_pos: Vector2, _dir: Vector2, src: Dictionary) -> bool:
	if state == FOOT or state == SINK:
		return true
	var s := str(src.get("source", ""))
	var boat_hit: bool = hit_pos.y > z.global_position.y - 26.0 or s in ["grenade", "explosion", "dynamite", "fire", "laser"]
	if boat_hit:
		boat_hp -= hit_damage(amount, hit_pos, src)
		Particles.burst(z.get_parent(), hit_pos, "leaf", Vector2.UP, 3)
		Sfx.play("bl_crack", hit_pos, -6.0, 0.15, 3)
		if boat_hp <= 0:
			_sink.call_deferred()
		return s in ["grenade", "explosion", "laser"]   # פיצוץ פוגע גם בו
	return true


func damage_mult(_zone: String, _src: Dictionary) -> float:
	return 1.0


func physics(pl: Node, delta: float) -> bool:
	_st -= delta
	_cd -= delta
	_poke -= delta
	_bob += delta
	if z.dead or state == FOOT:
		return false
	var has_pl: bool = pl != null and not pl.dead
	var dx: float = (pl.global_position.x - z.global_position.x) if has_pl else 0.0
	match state:
		ANCHOR:
			if has_pl and absf(dx) < WAKE_R:
				state = SAIL
				z._dir = signf(dx)
			z.velocity.x = 0.0
		SAIL:
			if has_pl and absf(dx) > 6.0:
				z._dir = signf(dx)
			z.velocity.x = move_toward(z.velocity.x, z._dir * SAIL_V, 300.0 * delta)
			if z.is_on_wall() and has_pl and absf(dx) < 700.0:   # נתקע באי - פורקים
				state = UNLOAD
				_st = 0.5
			elif has_pl and absf(dx) < 60.0 and _aboard > 0:   # אתה במים לידו - פורקים לידך
				state = UNLOAD
				_st = 0.5
		UNLOAD:
			z.velocity.x = 0.0
			if _st <= 0.0:
				_unload()
				state = POLE
		POLE:
			z.velocity.x = move_toward(z.velocity.x, 0.0, 300.0 * delta)
			if has_pl:
				z._dir = signf(dx) if absf(dx) > 4.0 else z._dir
				if absf(dx) > POLE_R + 140.0 and not z.is_on_wall():   # רודף בסירה
					z.velocity.x = move_toward(z.velocity.x, z._dir * SAIL_V * 0.7, 300.0 * delta)
				if _cd <= 0.0 and absf(dx) < POLE_R and absf(pl.global_position.y - z.global_position.y) < 70.0:
					_cd = POLE_CD
					_poke = 0.35
					pokes += 1
					Sfx.play("bl_pole", z.global_position, 0.0, 0.1, 2)
					pl.hurt(1, Vector2(z._dir * 2.6, -1.0))   # דוחף אותך חזרה למים
		SINK:
			z.velocity.x = 0.0
			if _st <= 0.0:
				state = FOOT
				z.wf = 1.0
				(z._shape.shape as RectangleShape2D).size.x = 38.0 * z.sc
				return false
	if not z.is_on_floor():
		z.velocity.y += z.gravity * delta
	z.move_and_slide()
	z.global_position.x = clampf(z.global_position.x, 30.0, float(z.world_w) - 30.0)
	if z.is_on_floor() and z.global_position.y < _floor() - 6.0:   # הסירה עלתה על יבשה (אי / ארגזים) -> חוזרת למים
		to_water()
	return true


# מוצא את המים הפנויים הקרובים ושם שם את הסירה
func to_water() -> void:
	var x0: float = z.global_position.x
	for k in 40:
		for sgn in [1.0, -1.0]:
			var x: float = x0 + float(sgn) * float(k) * 30.0
			if x < 60.0 or x > float(z.world_w) - 60.0:
				continue
			if _water_free(x):
				z.global_position = Vector2(x, _floor())
				z.velocity = Vector2.ZERO
				return


func _water_free(x: float) -> bool:
	for i in z.get_tree().get_nodes_in_group("islands"):
		if i.has_x(x, 56.0):
			return false
	for c in z.get_tree().get_nodes_in_group("lake_obstacles"):
		if not c.has_method("cover_rect"):
			continue
		var r: Rect2 = c.cover_rect()
		if x > r.position.x - 50.0 and x < r.end.x + 50.0 and r.end.y > _floor() - 4.0:
			return false
	return true


# הנוסעים קופצים: לאי שמולו (אם יש), אחרת למים לידו
func _unload() -> void:
	if _aboard <= 0:
		return
	var isl: Node = null   # האי שמולו (בכיוון השייט)
	var best := 120.0
	for i in z.get_tree().get_nodes_in_group("islands"):
		var x0: float = i.global_position.x
		var x1: float = x0 + float(i.w)
		var edge: float = x0 if z._dir > 0.0 else x1
		var dd: float = (edge - z.global_position.x) * z._dir
		if dd > -20.0 and dd < best:
			best = dd
			isl = i
	var main: Node = z.get_parent()
	for k in _aboard:
		var px: float = z.global_position.x + z._dir * (30.0 + float(k) * 26.0)
		var py := _floor()
		if isl != null:
			px = clampf(px, isl.global_position.x + 10.0, isl.global_position.x + float(isl.w) - 10.0)
			py = float(isl.top_y()) - 1.0
		var zz: Node = main._spawn_zombie(px, _floor(), [0, 1][k % 2])
		if zz != null:
			zz.position.y = py - 30.0
			zz.velocity = Vector2(z._dir * 120.0, -260.0)
			zz._alert_t = 8.0
		unloaded += 1
	_aboard = 0
	z._popup("BOARD!", Color("ffd080"), 14, -80.0)


# הסירה טובעת: הנוסעים שעוד בה טובעים - וחוזרים כ-DROWNED
func _sink() -> void:
	if sunk or z == null or not is_instance_valid(z) or z.dead:
		return
	sunk = true
	state = SINK
	_st = 0.6
	Sfx.play("bl_crack", z.global_position, 4.0, 0.05, 2)
	var S := preload("res://effects/s31_decor.gd")
	S.splash(z.get_parent(), Vector2(z.global_position.x, _floor() - 18.0), 12)
	Particles.burst(z.get_parent(), z.global_position + Vector2(0, -20), "leaf", Vector2.UP, 14)
	var R := preload("res://enemies/zombie_registry.gd")
	for k in _aboard:
		z.get_parent()._spawn_zombie(z.global_position.x + float(k * 2 - 1) * 26.0, _floor(), R.DROWNED)
	if _aboard > 0:
		z._popup("THEY DROWNED... AND CAME BACK", Color("a0e0d0"), 13, -80.0)
	else:
		z._popup("SUNK!", Color("ffd080"), 15, -80.0)
	_aboard = 0


func on_death() -> void:
	z.wf = 1.0
	if not sunk and _aboard > 0:   # מת בסירה: הנוסעים קופצים
		_unload()


# ============================================================
#  ציור: סירת קנים (ראש פומה בחרטום), השייט עם מוט, נוסעים יושבים
# ============================================================
func draw() -> bool:
	if z.dead or state == FOOT:
		return _draw_man(Vector2.ZERO, false)
	DrawBatch.set_transform(z, Vector2.ZERO, 0.0, Vector2(z._dir * z.sc, z.sc))
	var S := preload("res://effects/s31_decor.gd")
	var bob := sin(_bob * 2.2) * 1.5
	var sink := 0.0
	if state == SINK:
		sink = (1.0 - clampf(_st / 0.6, 0.0, 1.0)) * 20.0
	var wy := -S.WATER_Y + bob + sink
	var dmg := 1.0 - float(boat_hp) / float(BOAT_HP)
	var reed := col(Color("c0a050").lerp(Color("6a5430"), dmg * 0.7))
	var hull := PackedVector2Array([Vector2(-40, wy + 6), Vector2(36, wy + 6), Vector2(50, wy - 10), Vector2(44, wy - 8), Vector2(36, wy - 4), Vector2(-34, wy - 4), Vector2(-44, wy - 12), Vector2(-50, wy - 14)])
	Art.fill_shaded(z, hull, reed, 0.15, 0.4, Art.OUTLINE, 1.5)
	for q in 3:
		DrawBatch.line(z, Vector2(-34, wy - 1.0 + float(q) * 2.5), Vector2(36, wy - 1.0 + float(q) * 2.5), Color(0.35, 0.25, 0.1, 0.45), 1.0)
	if dmg > 0.4:   # חורים בסירה
		DrawBatch.circle(z, Vector2(-10, wy + 1), 3.0, Color(0.1, 0.1, 0.1, 0.7))
		DrawBatch.circle(z, Vector2(14, wy + 2), 2.5, Color(0.1, 0.1, 0.1, 0.7))
	var head := Vector2(52, wy - 24)   # ראש פומה
	DrawBatch.line(z, Vector2(46, wy - 9), head + Vector2(-3, 6), reed, 6.0)
	Art.fill(z, PackedVector2Array([head + Vector2(-8, 4), head + Vector2(-4, -6), head + Vector2(2, -8), head + Vector2(8, -4), head + Vector2(10, 2), head + Vector2(2, 6)]), reed, Art.OUTLINE, 1.2)
	DrawBatch.circle(z, head + Vector2(3, -3), 1.4, Color("2a1a0a"))
	for k in _aboard:   # נוסעים יושבים
		var px := -26.0 + float(k) * 16.0
		var pc := col(Color("7a8a6a"))
		Art.fill(z, PackedVector2Array([Vector2(px - 5, wy - 4), Vector2(px + 5, wy - 4), Vector2(px + 4, wy - 18), Vector2(px - 4, wy - 18)]), col([Color("8a3a2a"), Color("3a5a7a")][k % 2]), Art.OUTLINE, 1.0)
		Art.oval_shaded(z, Vector2(px + 1, wy - 23), 4.2, 4.6, pc, 0.0)
		DrawBatch.circle(z, Vector2(px + 3, wy - 23.5), 0.8, Color(0.9, 0.9, 0.5))
	_draw_man(Vector2(12, wy - 2), true)
	DrawBatch.set_transform_matrix(z, Transform2D.IDENTITY)
	return true


func _draw_man(o: Vector2, in_boat: bool) -> bool:
	if not in_boat:
		begin_draw()
	var sk := col(z.skin)
	var vest := col(z.shirt)
	var p: float = z._walk_phase
	var hip := o + Vector2(0, -22)
	var sh := o + Vector2(1, -37)
	var head := sh + Vector2(3.5, -8)
	var f: Array = feet(4.0, 2.0) if not in_boat else [o + Vector2(4, 0), o + Vector2(-4, 0)]
	if not in_boat:
		f = [f[0] + o, f[1] + o]
	z._leg(hip + Vector2(-2, 0), f[1], col(Art.shade(z.pants, 0.25)), sk, col(z.shoe))
	z._leg(hip + Vector2(2, 0), f[0], col(z.pants), sk, col(z.shoe))
	var hb := sh + Vector2(-5.0 - sin(p) * 2.0, 15.0)
	var hf := sh + Vector2(9.0, 8.0)
	if in_boat and not sunk:   # מוט ארוך
		var reach := 26.0 if _poke > 0.0 else 0.0
		hb = sh + Vector2(2, 4)
		hf = sh + Vector2(10 + reach * 0.3, 6)
		var top := hb + Vector2(-14 + reach, -40)
		var tip := hf + Vector2(44 + reach, 26)
		DrawBatch.line(z, top, tip, col(Color("6a4a2a")), 2.4)
	z._arm(sh + Vector2(-3, 1), hb, Art.shade(sk, 0.25), Art.shade(vest, 0.3))
	Art.fill_shaded(z, PackedVector2Array([sh + Vector2(-7, -1), sh + Vector2(7, 0), hip + Vector2(6, 2), hip + Vector2(-6, 2)]), vest, 0.12, 0.4)
	DrawBatch.line(z, sh + Vector2(-4, 2), hip + Vector2(-3, 0), col(Color("e0c040")), 1.5)   # רקמה
	Art.oval_shaded(z, head, 5.2, 5.8, sk, 0.0)
	# כובע קש רחב
	DrawBatch.colored_polygon(z, Art.ellipse(head + Vector2(0, -4), 10.0, 2.4, 0.0, 12), col(Color("d8c080")))
	Art.fill(z, PackedVector2Array([head + Vector2(-5, -4), head + Vector2(-4, -10), head + Vector2(4, -10), head + Vector2(5, -4)]), col(Color("c8b070")), Art.OUTLINE, 1.0)
	DrawBatch.line(z, head + Vector2(-5, -5.5), head + Vector2(5, -5.5), col(Color("8a2a2a")), 1.4)
	if not z.dead:
		DrawBatch.circle(z, head + Vector2(3.0, -0.5), 1.0, Color(0.85, 0.9, 0.5))
	z._arm(sh + Vector2(3, 1), hf, sk, vest)
	if not in_boat:
		end_draw()
	return true
