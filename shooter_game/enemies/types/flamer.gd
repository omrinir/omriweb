extends "res://enemies/zombie_type.gd"
# ============================================================
#  FLAMER (משלב 42, "METRO BARRACKS") - להביור של אימפריית המתים: מסכת גז, מיכלי דלק על הגב, מטול להבות עם להבת פיילוט.
#  קרוב אליך (FLAME_R) -> הדלקת פיילוט (WIND) ואז ריסוס אש בקונוס SPRAY_T שניות: נזק, מצית זומבים, ומשאיר שלולית אש (FirePatch).
#  "THEY LEARN TOGETHER - CUT OFF": אתה בורח אחורה כשהוא מתקרב (kiting)? נספר לכל הלהביורים (main meta "flamer_kite").
#    אחרי KITE_LEARN בריחות - זורקים מיכל נפאלם מאחוריך, לכיוון שאליו אתה בורח ("CUT OFF!").
#  נקודת תורפה: הפיה בזמן ריסוס - ירייה בה = התפוצצות לאחור (BACKFIRE). גם פיצוץ ליד המיכלים.
#  לשנות: FLAME_R, SPRAY_T, WIND_T, CD, KITE_LEARN, NAPALM_CD, BACKFIRE_R.
# ============================================================

const E := preload("res://enemies/empire_kit.gd")
const D42 := preload("res://effects/s42_decor.gd")

const SOUNDS := {
	"fl_ignite": [["N", 0, 0, 0.0, 0.25, 0.0, 10.0, 0.35, 0.5, 0, 0.6], ["S", 140, 200, 0.0, 0.2, 0.0, 10.0, 0.15, 1.0, 0]],
	"fl_spray": [["N", 0, 0, 0.0, 1.4, 0.05, 1.5, 0.5, 0.35, 0, 0.8]],
	"mb_whoosh": [["N", 0, 0, 0.0, 0.5, 0.0, 6.0, 0.6, 0.3, 0, 0.6], ["S", 90, 60, 0.0, 0.4, 0.0, 8.0, 0.3, 1.0, 0.05]],
}

const FLAME_R := 170.0
const SPRAY_T := 1.4
const WIND_T := 0.4
const CD := 2.6
const TICK := 0.3
const KITE_LEARN := 2
const NAPALM_CD := 5.0
const BACKFIRE_R := 110.0

enum { ADVANCE, WIND, SPRAY }
var state := ADVANCE
var sprays := 0              # לבדיקות
var burns := 0
var napalms := 0
var backfired := false
var _st := 0.0
var _cd := 1.0
var _tick := 0.0
var _ncd := 2.0
var _samp := 0.0
var _last_d := -1.0
var _last_px := 0.0
var _retreat_t := 0.0
var _flick := 0.0


func stats() -> Dictionary:
	return {"name": "FLAMER", "hp": 40, "walk": 36.0, "chase": 64.0, "damage": 1, "bite_delay": 0.9, "scale": 1.05, "width": 1.1,
		"duck": 0.0, "cover": 0.2, "skin": Color("7a8670"), "shirt": Color("3e3a2e"), "pants": Color("3e3a2e"), "shoe": Color("1a1816"), "points": 560}


func setup() -> void:
	z.add_to_group("empire")
	z.set_meta("fireproof", true)   # לא נדלק מהאש של עצמו (FirePatch)


func brain_overrides() -> Dictionary:
	return {"aggression": 0.8}


func can_bite() -> bool:
	return state == ADVANCE


static func kite_count(main: Node) -> int:
	return int(main.get_meta("flamer_kite")) if main.has_meta("flamer_kite") else 0


func nozzle() -> Vector2:
	return z.global_position + Vector2(z._dir * 24.0, -26.0) * z.sc


func on_damage(_amount: int, hit_pos: Vector2, _dir: Vector2, src: Dictionary) -> bool:
	if backfired:
		return true
	var s := str(src.get("source", "bullet"))
	var at_nozzle: bool = state != ADVANCE and hit_pos.distance_to(nozzle()) < 12.0 * z.sc and (s == "bullet" or s == "melee")
	if at_nozzle or src.has("blast"):
		_backfire()
		return false   # הפיצוץ עצמו הורג אותו
	return true


func _backfire() -> void:
	if backfired or z == null or not is_instance_valid(z):
		return
	backfired = true
	z._popup("BACKFIRE!", Color("ff9040"), 16, -90.0)
	var c: Vector2 = z.global_position + Vector2(0, -30) * z.sc
	var fp := D42.FirePatch.new()
	fp.w = 120.0
	z.get_parent().add_child(fp)
	fp.global_position = Vector2(z.global_position.x, z.global_position.y)
	preload("res://explosion.gd").blast(z.get_parent(), c, BACKFIRE_R, BACKFIRE_R * 0.4, 60, 2, "barrel")
	if not z.dead:
		z.take_damage(0, c, Vector2.UP, true, {"source": "barrel", "fixed": 999})


func physics(pl: Node, delta: float) -> bool:
	_st -= delta
	_cd -= delta
	_ncd -= delta
	_tick -= delta
	_flick += delta
	if z.dead or pl == null or pl.dead:
		return false
	var d: Vector2 = pl.global_position - z.global_position
	match state:
		WIND:
			if _st <= 0.0:
				state = SPRAY
				_st = SPRAY_T
				sprays += 1
				Sfx.play("fl_spray", nozzle(), 0.0, 0.05, 2)
			return _stay(delta)
		SPRAY:
			if _tick <= 0.0:
				_tick = TICK
				_burn(pl)
			if _st <= 0.0:
				state = ADVANCE
				_cd = CD
				var fp := D42.FirePatch.new()   # שלולית בקצה הקונוס
				fp.w = 80.0
				z.get_parent().add_child(fp)
				fp.global_position = Vector2(z.global_position.x + z._dir * FLAME_R * 0.75, z.global_position.y)
			return _stay(delta)
	if z.goal_x < INF:
		return false
	# לומד: בורח אחורה כשהוא מתקרב? (לפי התזוזה שלך בשנייה האחרונה)
	_samp -= delta
	_retreat_t -= delta
	if _samp <= 0.0:
		_samp = 1.0
		var dist := absf(d.x)
		var away: float = (pl.global_position.x - _last_px) * signf(d.x)
		if _last_d >= 0.0 and dist < 560.0 and away > 60.0 and absf(d.y) < 80.0:
			_retreat_t = 1.2
			var main: Node = z.get_parent()
			main.set_meta("flamer_kite", kite_count(main) + 1)
			if kite_count(main) == KITE_LEARN:
				z._popup("THEY LEARNED - YOU RUN", Color("ff8060"), 13, -90.0)
		_last_d = dist
		_last_px = pl.global_position.x
	if kite_count(z.get_parent()) >= KITE_LEARN and _ncd <= 0.0 and _retreat_t > 0.0 and absf(d.x) > FLAME_R and absf(d.x) < 460.0 and absf(d.y) < 80.0:
		_ncd = NAPALM_CD
		napalms += 1
		var fp := D42.FirePatch.new()   # מיכל נפאלם מאחוריך
		fp.w = 110.0
		fp.delay = 0.6
		z.get_parent().add_child(fp)
		fp.global_position = Vector2(pl.global_position.x + signf(d.x) * 120.0, pl.global_position.y)
		z._popup("CUT OFF!", Color("ff6040"), 15, -90.0)
	if _cd <= 0.0 and absf(d.x) < FLAME_R and absf(d.y) < 70.0:
		state = WIND
		_st = WIND_T
		z._dir = signf(d.x) if absf(d.x) > 4.0 else z._dir
		Sfx.play("fl_ignite", nozzle(), -2.0, 0.1, 2)
		return _stay(delta)
	return false


func _in_cone(p: Vector2, h := 50.0) -> bool:
	var l: Vector2 = p - nozzle()
	return signf(l.x) == z._dir and absf(l.x) < FLAME_R and absf(l.y) < h * 0.5 + absf(l.x) * 0.3


func _burn(pl: Node) -> void:
	if _in_cone(pl.global_position + Vector2(0, -24)):
		burns += 1
		pl.hurt(1, Vector2(z._dir * 1.2, -0.4))
	for o in z.get_tree().get_nodes_in_group("zombies"):
		if o != z and not o.dead and not o.is_in_group("empire") and not o.is_boss() and _in_cone(o.global_position + Vector2(0, -24)) and o.has_method("ignite"):
			o.ignite(3.0)
	Particles.burst(z.get_parent(), nozzle() + Vector2(z._dir * FLAME_R * 0.6, 0), "fire", Vector2(z._dir, 0), 3)


func _stay(delta: float) -> bool:
	z.velocity.x = move_toward(z.velocity.x, 0.0, 800.0 * delta)
	if not z.is_on_floor():
		z.velocity.y += z.gravity * delta
	z.move_and_slide()
	return true


# ============================================================
#  ציור: מסכת גז, שני מיכלי דלק על הגב, צינור, מטול עם פיה ולהבת פיילוט. בריסוס - לשון אש ארוכה (בעולם)
# ============================================================
func draw() -> bool:
	begin_draw()
	var o: Dictionary = E.soldier(self, z, Vector2(11, 4), "gasmask", Color("3e3a2e"), Vector2(7, 6))
	var sh: Vector2 = o.sh
	var hf: Vector2 = o.hf
	for q in 2:   # מיכלים
		var tx := -13.0 + float(q) * 5.0
		DrawBatch.rect(z, Rect2(sh + Vector2(tx, -3), Vector2(5, 22)), col(Color("6a2a1a") if q == 0 else Color("7a3420")))
		DrawBatch.circle(z, sh + Vector2(tx + 2.5, -3), 2.5, col(Color("6a2a1a")))
	var pts := PackedVector2Array()   # צינור
	for q in 6:
		var u := float(q) / 5.0
		pts.append((sh + Vector2(-8, 18)).lerp(hf + Vector2(-2, 2), u) + Vector2(0, sin(u * PI) * 6.0))
	DrawBatch.polyline(z, pts, col(Color("1a1a1a")), 1.5)
	DrawBatch.rect(z, Rect2(hf + Vector2(-4, -2), Vector2(16, 4)), col(Color("3a3a32")))   # המטול
	DrawBatch.rect(z, Rect2(hf + Vector2(12, -1.5), Vector2(4, 3)), col(Color("8a8a80")))
	if not z.dead:
		var pk := 1.0 if state == ADVANCE else 2.2
		Art.glow(z, hf + Vector2(17, 0), 2.5 * pk + sin(_flick * 30.0) * 0.6, Color(0.4, 0.6, 1.0, 0.8) if state == ADVANCE else Color(1.0, 0.7, 0.2, 0.9))
	end_draw()
	if state == SPRAY and not z.dead:   # לשון האש (בעולם)
		var n: Vector2 = nozzle() - z.global_position
		for q in 7:
			var u := float(q) / 6.0
			var fx := n + Vector2(z._dir * FLAME_R * u, sin(_flick * 20.0 + float(q)) * 4.0 * u)
			DrawBatch.circle(z, fx, 5.0 + 14.0 * u, Color(1.0, 0.75 - 0.4 * u, 0.15, 0.75 - 0.35 * u))
	return true
