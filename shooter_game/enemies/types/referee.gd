extends "res://enemies/zombie_type.gd"
# ============================================================
#  REFEREE (שלב 39, "THE STADIUM") - שופט זומבי: חולצה שחורה, משרוקית, כרטיסים בכיס.
#  "THEY LEARNED THE RULES": סופר כל ירייה שלך שהוא רואה (zombie.gd on_player_fired -> on_shot), בטווח WATCH_R.
#    אחרי FOUL_N "עבירות" -> שורק (WHISTLE_T, ירייה בו קוטעת) ומרים כרטיס:
#      צהוב = הנשק שלך תקוע YELLOW_T שניות (player.jam_t). שני צהובים = אדום: תקוע RED_T.
#    בזמן התקיעה - רימונים / פריטים מיוחדים עדיין עובדים. שומר מרחק (KEEP).
#  לשנות: WATCH_R, FOUL_N, WHISTLE_T, YELLOW_T, RED_T, KEEP.
# ============================================================

const SOUNDS := {
	"rf_whistle": [["S", 3000, 3100, 0.0, 0.5, 0.02, 5.0, 0.2, 1.0, 0.08], ["S", 3000, 3100, 0.6, 0.25, 0.02, 8.0, 0.2, 1.0, 0.08]],
	"rf_card": [["S", 600, 900, 0.0, 0.15, 0.0, 15.0, 0.2, 1.0, 0]],
}

const WATCH_R := 650.0
const FOUL_N := 6
const WHISTLE_T := 0.8
const YELLOW_T := 1.6
const RED_T := 4.0
const KEEP := 230.0

enum { WATCH, WHISTLE, SHOW }
var state := WATCH
var fouls := 0
var yellows := 0             # לבדיקות
var reds := 0
var cut := 0
var _st := 0.0
var _card := ""


func stats() -> Dictionary:
	return {"name": "REFEREE", "hp": 28, "walk": 44.0, "chase": 80.0, "damage": 1, "bite_delay": 0.8, "scale": 1.0, "width": 1.0,
		"duck": 0.3, "cover": 0.3, "skin": Color("8a9480"), "shirt": Color("1a1a1e"), "pants": Color("1a1a1e"), "shoe": Color("1a1a1a"), "points": 500}


func brain_overrides() -> Dictionary:
	return {"aggression": 0.1}


func can_bite() -> bool:
	return state == WATCH


# zombie.gd (on_player_fired)
func on_shot(from: Vector2, _dir: Vector2) -> void:
	if z == null or z.dead or state != WATCH:
		return
	if from.distance_to(z.global_position) > WATCH_R:
		return
	fouls += 1
	if fouls >= FOUL_N:
		fouls = 0
		state = WHISTLE
		_st = WHISTLE_T
		Sfx.play("rf_whistle", z.global_position, 2.0, 0.05, 2)


func on_damage(_amount: int, _hit_pos: Vector2, _dir: Vector2, _src: Dictionary) -> bool:
	if state == WHISTLE:   # המשרוקית נפלה
		cut += 1
		state = WATCH
		fouls = int(FOUL_N * 0.5)
		z._popup("NO CALL", Color("e0e0e0"), 12, -80.0)
	return true


func physics(pl: Node, delta: float) -> bool:
	_st -= delta
	if z.dead or pl == null or pl.dead:
		return false
	var d: Vector2 = pl.global_position - z.global_position
	match state:
		WHISTLE:
			z._dir = signf(d.x) if absf(d.x) > 4.0 else z._dir
			if _st <= 0.0:
				_give_card(pl)
				state = SHOW
				_st = 1.2
			return _move(0.0, delta)
		SHOW:
			if _st <= 0.0:
				state = WATCH
			return _move(0.0, delta)
	if absf(d.x) < KEEP and absf(d.y) < 90.0:   # שומר מרחק
		z._dir = signf(d.x) if absf(d.x) > 4.0 else z._dir
		return _move(-z._dir * float(z.walk_speed) * 1.5, delta)
	return false


func _move(vx: float, delta: float) -> bool:
	z.velocity.x = move_toward(z.velocity.x, vx, 700.0 * delta)
	if not z.is_on_floor():
		z.velocity.y += z.gravity * delta
	elif z.is_on_wall() and vx != 0.0:
		z.velocity.y = -380.0
	z.move_and_slide()
	return true


func _give_card(pl: Node) -> void:
	Sfx.play("rf_card", z.global_position, 0.0, 0.05, 2)
	if yellows % 2 == 1:   # צהוב שני = אדום
		_card = "red"
		reds += 1
		yellows += 1
		pl.jam_t = maxf(float(pl.jam_t), RED_T)
		z._popup("RED CARD!", Color("ff3030"), 18, -90.0)
		pl._say("RED CARD?! MY GUN IS STUCK!", Color("ff4040"))
	else:
		_card = "yellow"
		yellows += 1
		pl.jam_t = maxf(float(pl.jam_t), YELLOW_T)
		z._popup("YELLOW CARD!", Color("ffe020"), 16, -90.0)


# ============================================================
#  ציור: חולצה שחורה עם צווארון, משרוקית על שרוך, מכנסיים קצרים שחורים, גרביים; מרים כרטיס צהוב/אדום
# ============================================================
func draw() -> bool:
	begin_draw()
	var sk := col(z.skin)
	var shirt := col(z.shirt)
	var p: float = z._walk_phase
	var f: Array = feet(4.5, 2.5)
	var hip := Vector2(0, -22)
	var sh := Vector2(1, -37)
	var head := sh + Vector2(3.5, -8)
	z._leg(hip + Vector2(-2, 0), f[1], col(Color("1a1a1e")), sk, col(z.shoe))
	z._leg(hip + Vector2(2, 0), f[0], col(Color("1a1a1e")), sk, col(z.shoe))
	z._arm(sh + Vector2(-3, 1), sh + Vector2(-6.0 - sin(p) * 2.0, 14.0), Art.shade(sk, 0.25), Art.shade(shirt, 0.3))
	Art.fill_shaded(z, PackedVector2Array([sh + Vector2(-8, -1), sh + Vector2(8, 0), hip + Vector2(7, -1), hip + Vector2(-7, -1)]), shirt, 0.12, 0.4)
	z.draw_line(sh + Vector2(-3, -1), sh + Vector2(1, 4), col(Color("e0e0e0")), 1.0)   # שרוך המשרוקית
	z.draw_line(sh + Vector2(5, -1), sh + Vector2(1, 4), col(Color("e0e0e0")), 1.0)
	z.draw_circle(sh + Vector2(1, 5), 1.5, col(Color("c0c4cc")))
	z.draw_rect(Rect2(sh + Vector2(-6, 4), Vector2(4, 5)), col(Color("e0d020")))   # כיס עם כרטיסים
	Art.oval_shaded(z, head, 5.2, 5.8, sk, 0.0)
	z.draw_colored_polygon(Art.ellipse(head + Vector2(-1, -4), 4.6, 2.4, 0.0, 10), col(Color("6a6a6a")))   # שיער אפור
	if not z.dead:
		z.draw_circle(head + Vector2(3.0, -0.5), 1.1, Color(1.0, 0.85, 0.4))
	var hf := sh + Vector2(10, 6)
	if state == WHISTLE:
		hf = head + Vector2(4, 3)
	elif state == SHOW:
		hf = sh + Vector2(8, -20)
	z._arm(sh + Vector2(3, 1), hf, sk, shirt)
	if state == WHISTLE:
		z.draw_rect(Rect2(hf + Vector2(0, -1), Vector2(4, 3)), col(Color("c0c4cc")))
	elif state == SHOW:
		z.draw_rect(Rect2(hf + Vector2(-3, -12), Vector2(7, 10)), Color("ffe020") if _card == "yellow" else Color("e02020"))
	end_draw()
	return true
