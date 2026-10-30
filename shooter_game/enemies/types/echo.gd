extends "res://enemies/zombie_type.gd"
# ============================================================
#  ECHO (שלב 29, "MINE OF ECHOES") - כורה עיוור: קסדה עם פנס שבור, תחבושת על העיניים, עור חיוור.
#  לא רואה - שומע. מתעלם מכל מה שהוא לא שומע.
#    LISTEN - עומד, מטה את הראש ומקשיב.
#    SEEK   - הולך לאט למקום של הצליל האחרון.
#    RUSH   - שמע ירייה (SHOT_R) / ריצה (RUN_R) / הליכה קרובה (WALK_R) / פיצוץ -> מסתער למקום הצליל, צווח.
#    STRIKE - צמוד אליך: שורט (DAMAGE).
#  התגנבות: להתכופף (S) ולא לירות = הוא לא שומע אותך, גם אם אתה עובר לידו. ירייה אחת - והוא בא.
#  לשנות: SHOT_R, RUN_R, WALK_R, RUSH_V, SEEK_V, DAMAGE.
# ============================================================

const SOUNDS := {
	"ec_screech": [["V", 300, 180, 0.0, 0.5, 0.02, 3.0, 0.7, 1.0, 0.08, 0, [900, 1500, 40]], ["N", 0, 0, 0.0, 0.5, 0.02, 4.0, 0.2, 0.6, 0, 0.3]],
	"ec_click": [["C", 0, 0, 0.0, 0.06, 0.0, 60.0, 0.4, 1.0, 0], ["C", 0, 0, 0.12, 0.06, 0.0, 60.0, 0.35, 1.0, 0]],
}

const SHOT_R := 900.0
const RUN_R := 260.0
const WALK_R := 110.0
const RUSH_V := 175.0
const SEEK_V := 55.0
const DAMAGE := 1
const STRIKE_CD := 0.8

enum { LISTEN, SEEK, RUSH }
var state := LISTEN
var heard := 0               # לבדיקות
var strikes := 0
var _target := Vector2.ZERO
var _prev_flash := 0.0
var _strike_cd := 0.0
var _click := 2.0
var _alert0 := 0.0
var _tilt := 0.0
var _st := 0.0


func stats() -> Dictionary:
	return {"name": "ECHO", "hp": 40, "walk": 30.0, "chase": 175.0, "damage": 1, "bite_delay": 0.8, "scale": 1.05, "width": 0.92,
		"duck": 0.0, "cover": 0.0, "skin": Color("b8b8a8"), "shirt": Color("4a4238"), "pants": Color("3a3430"), "shoe": Color("2a2420"), "points": 450}


func can_bite() -> bool:
	return false


func can_groan() -> bool:
	return false


func _hear(pl: Node) -> bool:   # האם שמע אותך עכשיו
	var dx: float = absf(pl.global_position.x - z.global_position.x)
	var dy: float = absf(pl.global_position.y - z.global_position.y)
	var f: float = pl._muzzle_flash
	var shot: bool = f > _prev_flash + 0.001
	_prev_flash = f
	if shot and dx < SHOT_R and dy < 300.0:
		return true
	if dy > 120.0 or pl._crouching or not pl.is_on_floor():
		return false
	var spd: float = absf(pl.velocity.x)
	if spd > 150.0 and dx < RUN_R:
		return true
	return spd > 30.0 and dx < WALK_R


func on_damage(_amount: int, _hit_pos: Vector2, _dir: Vector2, _src: Dictionary) -> bool:
	var pl := player()
	if pl != null and state != RUSH:   # נפגע - יודע מאיפה
		_go(pl.global_position, true)
	return true


func _go(p: Vector2, rush: bool) -> void:
	_target = p
	if rush and state != RUSH:
		heard += 1
		Sfx.play("ec_screech", z.global_position, 0.0, 0.1, 2)
		z._popup("!", Color("ff6040"), 16, -72.0)
	state = RUSH if rush else SEEK
	_st = 5.0


func physics(pl: Node, delta: float) -> bool:
	_strike_cd -= delta
	_click -= delta
	_st -= delta
	if z.dead:
		return false
	var has_pl: bool = pl != null and not pl.dead
	if has_pl and _hear(pl):
		_go(pl.global_position, true)
	if float(z._alert_t) > _alert0 + 1.0 and has_pl:   # פיצוץ / רעש (Game.make_noise)
		_go(pl.global_position, true)
	_alert0 = float(z._alert_t)
	if has_pl and state != LISTEN:   # צמוד אליך - שורט
		var d: Vector2 = pl.global_position - z.global_position
		if absf(d.x) < 30.0 * z.sc and absf(d.y) < 50.0 and _strike_cd <= 0.0:
			_strike_cd = STRIKE_CD
			strikes += 1
			z._dir = signf(d.x) if d.x != 0.0 else z._dir
			pl.hurt(DAMAGE, Vector2(z._dir * 1.2, -0.4))
	match state:
		LISTEN:
			_tilt = sin(z._time * 1.3) * 0.3
			if _click <= 0.0:   # קליקים (אקולוקציה)
				_click = randf_range(2.5, 4.0)
				if Art.on_screen(z, z.global_position):
					Sfx.play("ec_click", z.global_position, -6.0, 0.1, 2)
			return _move(delta, 0.0)
		SEEK, RUSH:
			var dx: float = _target.x - z.global_position.x
			if absf(dx) < 12.0 or _st <= 0.0:
				state = SEEK if state == RUSH else LISTEN   # הגיע ולא מוצא - מקשיב
				_st = 2.0
				return _move(delta, 0.0)
			z._dir = signf(dx)
			if z.is_on_wall() and z.is_on_floor():
				z.velocity.y = -430.0
			return _move(delta, signf(dx) * (RUSH_V if state == RUSH else SEEK_V))
	return true


func _move(delta: float, vx: float) -> bool:
	z.velocity.x = move_toward(z.velocity.x, vx, 900.0 * delta)
	if not z.is_on_floor():
		z.velocity.y += z.gravity * delta
	z.move_and_slide()
	return true


# ============================================================
#  ציור: קסדת כורה עם פנס שבור, תחבושת על העיניים, ידיים מושטות קדימה כשהוא מחפש; ")))" כשהוא שומע
# ============================================================
func draw() -> bool:
	begin_draw()
	var sk := col(z.skin)
	var shirt := col(z.shirt)
	var p: float = z._walk_phase
	var f: Array = feet(6.0 if state == RUSH else 4.0, 2.5)
	var hip := Vector2(0, -22)
	var lean := 6.0 if state == RUSH else 1.0
	var sh := Vector2(1.0 + lean, -37)
	var head := sh + Vector2(4.0, -8.0)
	z._leg(hip + Vector2(-2, 0), f[1], col(Art.shade(z.pants, 0.25)), sk, col(z.shoe))
	z._leg(hip + Vector2(2, 0), f[0], col(z.pants), sk, col(z.shoe))
	var reach := state != LISTEN
	z._arm(sh + Vector2(-3, 1), sh + (Vector2(12, -2) if reach else Vector2(-5.0 - sin(p) * 3.0, 14.0)), Art.shade(sk, 0.25), Art.shade(shirt, 0.3))
	Art.fill_shaded(z, PackedVector2Array([sh + Vector2(-6, -1), sh + Vector2(6, 0), hip + Vector2(5, 2), hip + Vector2(-5, 2)]), shirt, 0.12, 0.4)
	DrawBatch.line(z, sh + Vector2(-4, 4), hip + Vector2(4, -2), col(Color("8a7a40")), 1.4)   # כתפייה
	head += Vector2(_tilt * 3.0, absf(_tilt) * 1.5)   # מטה את הראש ומקשיב
	Art.oval_shaded(z, head, 5.4, 5.8, sk, 0.0)
	face(head, Vector2(INF, 0))
	DrawBatch.rect(z, Rect2(head + Vector2(-4, -2.5), Vector2(10, 3.2)), col(Color("d8d0b8")))   # תחבושת על העיניים
	DrawBatch.line(z, head + Vector2(0, -1.5), head + Vector2(3, -0.5), col(Color("8a3a2a")), 1.0)
	DrawBatch.line(z, head + Vector2(0, 3), head + Vector2(5, 3.5), col(Color("2a1a14")), 1.2)
	Art.fill(z, PackedVector2Array([head + Vector2(-6.5, -3), head + Vector2(-5, -8), head + Vector2(4, -8.5), head + Vector2(7, -3)]), col(Color("c8a030")), Art.OUTLINE, 1.0)   # קסדה
	DrawBatch.rect(z, Rect2(head + Vector2(4, -8), Vector2(3, 3)), col(Color("3a3a3a")))   # פנס שבור
	DrawBatch.line(z, head + Vector2(5, -7), head + Vector2(7, -5), col(Color("8a8a8a")), 0.8)
	z._arm(sh + Vector2(3, 1), sh + (Vector2(16, -3) if reach else Vector2(9.0 + sin(p) * 3.0, 13.0)), sk, shirt)
	if state == LISTEN and not z.dead and fmod(z._time, 3.0) < 1.0:   # מקשיב: גלי קול ליד האוזן
		for q in 3:
			DrawBatch.arc(z, head + Vector2(-6, 0), 4.0 + float(q) * 3.0, PI * 0.7, PI * 1.3, 6, Color(0.8, 0.85, 1.0, 0.5 - float(q) * 0.12), 1.0)
	end_draw()
	return true
