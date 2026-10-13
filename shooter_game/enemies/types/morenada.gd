extends "res://enemies/zombie_type.gd"
# ============================================================
#  MORENADA (שלב 32, "DEVIL'S CARNIVAL") - רקדן מורנדה: תחפושת כבדה בצורת חבית עם חצאית מסולסלת כסופה,
#  מסכה שחורה עם עיניים בולטות ומקטרת, כתר נוצות, ומטרקה (רעשן מסתובב) ביד.
#  "THEY LEARNED TO SPIN": מתחיל להסתובב על הפעמה (WIND_T = הרעשן מתחיל) -> SPIN: מסתובב כמו סביבון אליך (SPIN_T),
#  היריות ניתזות ממנו (לא נפגע), פגיעה = נזק + הדף. אחרי זה DIZZY (DIZZY_T): עומד מסוחרר - פגיע כפול.
#  רימון / פיצוץ / אש פוגעים גם בזמן הסיבוב.
#  לשנות: SPIN_R, WIND_T, SPIN_T, SPIN_V, DIZZY_T, SPIN_CD.
# ============================================================

const SOUNDS := {
	"mr_rattle": [["C", 0, 0, 0.0, 1.8, 0.05, 0.0, 0.9, 1.0, 0], ["Q", 30, 30, 0.0, 1.8, 0.05, 0.0, 0.06, 0.3, 0]],
	"mr_ping": [["S", 2200, 1800, 0.0, 0.08, 0.0, 40.0, 0.25, 1.0, 0], ["N", 0, 0, 0.0, 0.03, 0.0, 100.0, 0.2, 1.0, 0, 0.5]],
}

const SPIN_R := 380.0
const WIND_T := 0.45
const SPIN_T := 2.0
const SPIN_V := 175.0
const DIZZY_T := 1.6
const SPIN_CD := 3.2

enum { WALK, WIND, SPIN, DIZZY }
var state := WALK
var spins := 0               # לבדיקות
var deflects := 0
var hits := 0
var _st := 0.0
var _cd := 1.5
var _hit_cd := 0.0
var _ang := 0.0
var _beat := -1


func stats() -> Dictionary:
	return {"name": "MORENADA", "hp": 44, "walk": 34.0, "chase": 62.0, "damage": 1, "bite_delay": 0.9, "scale": 1.12, "width": 1.35,
		"duck": 0.0, "cover": 0.0, "skin": Color("8a9474"), "shirt": Color("8aa0c0"), "pants": Color("2e2a3a"), "shoe": Color("2a2026"), "points": 520}


func can_bite() -> bool:
	return state == WALK


func on_damage(_amount: int, hit_pos: Vector2, dir: Vector2, src: Dictionary) -> bool:
	if state != SPIN:
		return true
	var s := str(src.get("source", "bullet"))
	if s in ["grenade", "explosion", "fire", "laser", "mech", "barrel"]:
		return true
	deflects += 1
	Sfx.play("mr_ping", hit_pos, -4.0, 0.2, 4)
	Particles.burst(z.get_parent(), hit_pos, "spark", Vector2(-dir.x, -0.5), 4)
	if deflects % 4 == 1:
		z._popup("DEFLECTED", Color("c0d0ff"), 12, -86.0)
	return false


func damage_mult(_zone: String, _src: Dictionary) -> float:
	return 2.0 if state == DIZZY else 1.0


func physics(pl: Node, delta: float) -> bool:
	_st -= delta
	_cd -= delta
	_hit_cd -= delta
	if z.dead:
		return false
	var has_pl: bool = pl != null and not pl.dead
	var dx: float = (pl.global_position.x - z.global_position.x) if has_pl else 0.0
	match state:
		WALK:
			var band: Node = preload("res://effects/s32_decor.gd").band()
			var on_beat := true
			if band != null:   # מתחיל רק על פעמה
				on_beat = band.beat_id != _beat
				_beat = band.beat_id
			if has_pl and _cd <= 0.0 and on_beat and absf(dx) < SPIN_R and absf(pl.global_position.y - z.global_position.y) < 60.0 and z.is_on_floor():
				state = WIND
				_st = WIND_T
				z._dir = signf(dx)
				Sfx.play("mr_rattle", z.global_position, -2.0, 0.05, 2)
				return _stay(delta)
			return false
		WIND:
			_ang += delta * 10.0
			if _st <= 0.0:
				state = SPIN
				_st = SPIN_T
				spins += 1
			return _stay(delta)
		SPIN:
			_ang += delta * 26.0
			if has_pl and absf(dx) > 10.0:
				z._dir = signf(dx)
			z.velocity.x = move_toward(z.velocity.x, z._dir * SPIN_V, 500.0 * delta)
			if z.is_on_wall() and z.is_on_floor():
				z.velocity.y = -360.0
			if has_pl and _hit_cd <= 0.0 and absf(dx) < 30.0 * z.sc and absf(pl.global_position.y - z.global_position.y) < 50.0:
				_hit_cd = 0.6
				hits += 1
				pl.hurt(1, Vector2(signf(dx) * 2.2, -1.0))
			_move(delta)
			if _st <= 0.0:
				state = DIZZY
				_st = DIZZY_T
				z._popup("DIZZY", Color("ffe080"), 13, -86.0)
			return true
		DIZZY:
			_ang += delta * maxf(_st, 0.0) * 6.0
			if _st <= 0.0:
				state = WALK
				_cd = SPIN_CD
			return _stay(delta)
	return false


func _stay(delta: float) -> bool:
	z.velocity.x = move_toward(z.velocity.x, 0.0, 700.0 * delta)
	_move(delta)
	return true


func _move(delta: float) -> void:
	if not z.is_on_floor():
		z.velocity.y += z.gravity * delta
	z.move_and_slide()
	z.global_position.x = clampf(z.global_position.x, 30.0, float(z.world_w) - 30.0)


# ============================================================
#  ציור: חצאית-חבית כסופה עם פסים (מסתובבים בזמן SPIN), כתפיות גדולות, מסכה שחורה עם מקטרת, כתר נוצות
# ============================================================
func draw() -> bool:
	begin_draw()
	var sk := col(z.skin)
	var silver := col(z.shirt)
	var f: Array = feet(3.5, 1.5)
	var hip := Vector2(0, -18)
	var sh := Vector2(0, -40)
	var head := sh + Vector2(3, -9)
	var spinning: bool = state == SPIN and not z.dead
	if state == DIZZY:
		head += Vector2(sin(z._time * 7.0) * 2.5, 0)
	z._leg(hip + Vector2(-3, 4), f[1], col(z.pants), sk, col(z.shoe))
	z._leg(hip + Vector2(3, 4), f[0], col(z.pants), sk, col(z.shoe))
	# חצאית בצורת פעמון/חבית עם פסים
	var skirt := PackedVector2Array([sh + Vector2(-9, 4), sh + Vector2(9, 4), hip + Vector2(15, 8), hip + Vector2(-15, 8)])
	Art.fill_shaded(z, skirt, silver, 0.2, 0.4, Art.OUTLINE, 1.4)
	for q in 5:   # פסים זהובים (זזים כשמסתובב)
		var u := fposmod(float(q) / 5.0 + _ang * 0.08, 1.0)
		var tx := lerpf(-9.0, 9.0, u)
		var bx := lerpf(-15.0, 15.0, u)
		z.draw_line(sh + Vector2(tx, 5), hip + Vector2(bx, 7), col(Color("e0c040")), 1.6)
	for q in 3:   # סלסולים
		var yy := lerpf(sh.y + 10.0, hip.y + 6.0, float(q) / 2.0)
		var ww := lerpf(10.0, 15.0, float(q) / 2.0)
		z.draw_line(Vector2(-ww, yy), Vector2(ww, yy), col(Color("f0f0ff")), 1.2)
	for sgn in [-1.0, 1.0]:   # כתפיות ענקיות
		Art.oval_shaded(z, sh + Vector2(sgn * 10.0, 0), 6.0, 4.0, col(Color("e0c040")), 0.0)
	var hb := sh + Vector2(-14, 10)
	var hf := sh + Vector2(14, 4)
	if spinning or state == WIND:   # ידיים פרוסות + רעשן
		hb = sh + Vector2(-18, -2)
		hf = sh + Vector2(18, -4)
	z._arm(sh + Vector2(-9, 1), hb, Art.shade(sk, 0.25), Art.shade(silver, 0.3))
	z._arm(sh + Vector2(9, 1), hf, sk, silver)
	var ra := _ang * 2.0   # מטרקה
	var rc := hf + Vector2(2, -2)
	z.draw_line(rc, rc + Vector2(0, 8), col(Color("6a4a2a")), 2.0)
	z.draw_rect(Rect2(rc + Vector2.from_angle(ra) * 6.0 - Vector2(4, 3), Vector2(8, 6)), col(Color("c02a2a")))
	# מסכה שחורה עם עיניים בולטות ומקטרת, כתר נוצות
	Art.oval_shaded(z, head, 6.5, 7.0, col(Color("2a2226")), 0.0)
	if not z.dead:
		z.draw_circle(head + Vector2(-1.5, -1.5), 2.8, Color("f4f0e0"))
		z.draw_circle(head + Vector2(4.0, -1.5), 2.8, Color("f4f0e0"))
		z.draw_circle(head + Vector2(-1.0, -1.5), 1.2, Color(0.1, 0.1, 0.1))
		z.draw_circle(head + Vector2(4.5, -1.5), 1.2, Color(0.1, 0.1, 0.1))
		z.draw_colored_polygon(Art.ellipse(head + Vector2(2.5, 4.5), 3.0, 1.6, 0.0, 8), col(Color("c02a2a")))   # שפתיים אדומות
		z.draw_line(head + Vector2(5, 5), head + Vector2(12, 7), col(Color("6a4a2a")), 1.6)   # מקטרת
		z.draw_rect(Rect2(head + Vector2(11, 4), Vector2(3, 3)), col(Color("4a3020")))
	z.draw_rect(Rect2(head + Vector2(-6, -11), Vector2(12, 4)), col(Color("e0c040")))
	for q in 5:   # נוצות
		var fx := -5.0 + float(q) * 2.5
		z.draw_line(head + Vector2(fx, -11), head + Vector2(fx + float(q - 2) * 1.5, -22), col([Color("e03050"), Color("40c0f0"), Color("f0f0f0"), Color("e03050"), Color("40c0f0")][q]), 2.0)
	if spinning:   # קווי תנועה
		for q in 3:
			var a := _ang + float(q) * TAU / 3.0
			z.draw_arc(hip + Vector2(0, -6), 20.0, a, a + 1.2, 6, Color(1, 1, 1, 0.35), 1.5)
	if state == DIZZY:
		for k in 3:
			var a: float = z._time * 5.0 + float(k) * TAU / 3.0
			z.draw_circle(head + Vector2(cos(a) * 10.0, -26.0 + sin(a) * 2.5), 1.4, Color(1.0, 0.95, 0.5))
	end_draw()
	return true
