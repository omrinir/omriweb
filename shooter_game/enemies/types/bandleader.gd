extends "res://enemies/zombie_type.gd"
# ============================================================
#  BANDLEADER (שלב 32, "DEVIL'S CARNIVAL") - נגן הטובה של התזמורת: מעיל אדום עם קישוטי זהב, כובע מצחייה, טובה ענקית.
#  "THEY LEARNED TO KEEP TIME": כל עוד הוא חי - רקדני הדיאבלדה שקרובים אליו (DIABLO SYNC_R) בסנכרון עם הקצב.
#  נשאר מאחורי הלהקה (BACKOFF). כשאתה קרוב (BLAST_R): מנפח לחיים (WIND_T = אזהרה) ותוקע -
#    גל קול שהודף אותך חזק אחורה (BLAST) + נזק קטן.
#  הורגים אותו -> הרקדנים שסביבו מאבדים את הקצב (מסוחררים). להרוג אותו ראשון!
#  לשנות: BACKOFF, BLAST_R, WIND_T, BLAST_CD.
# ============================================================

const SOUNDS := {
	"bd_blast": {"drive": 3.0, "layers": [["W", 58, 54, 0.0, 0.9, 0.04, 2.0, 0.9, 0.15, 0.02], ["W", 87, 82, 0.0, 0.9, 0.04, 2.0, 0.5, 0.15, 0.02], ["N", 0, 0, 0.0, 0.5, 0.02, 5.0, 0.3, 0.1, 0]]},
}

const BACKOFF := 230.0
const BLAST_R := 300.0
const WIND_T := 0.6
const BLAST_CD := 4.2

enum { WALK, WIND, BLOW }
var state := WALK
var blasts := 0              # לבדיקות
var _st := 0.0
var _cd := 1.5
var _ring := 0.0


func stats() -> Dictionary:
	return {"name": "BANDLEADER", "hp": 38, "walk": 38.0, "chase": 72.0, "damage": 1, "bite_delay": 0.8, "scale": 1.05, "width": 1.15,
		"duck": 0.0, "cover": 0.3, "skin": Color("8a9474"), "shirt": Color("a01c22"), "pants": Color("1e1e2a"), "shoe": Color("1a1418"), "points": 520}


func setup() -> void:
	z.add_to_group("bandleaders")


func can_bite() -> bool:
	return state == WALK


func physics(pl: Node, delta: float) -> bool:
	_st -= delta
	_cd -= delta
	_ring -= delta
	if z.dead:
		return false
	var has_pl: bool = pl != null and not pl.dead
	var d := Vector2.ZERO
	if has_pl:
		d = pl.global_position - z.global_position
	match state:
		WALK:
			if has_pl and _cd <= 0.0 and absf(d.x) < BLAST_R and absf(d.y) < 80.0 and z.is_on_floor():
				state = WIND
				_st = WIND_T
				z._dir = signf(d.x) if absf(d.x) > 4.0 else z._dir
				return _stay(delta)
			if has_pl and absf(d.x) < BACKOFF and absf(d.y) < 90.0:   # נשאר מאחורי הלהקה
				z._dir = signf(d.x) if absf(d.x) > 4.0 else z._dir
				z.velocity.x = move_toward(z.velocity.x, -z._dir * float(z.walk_speed) * 1.5, 600.0 * delta)
				if not z.is_on_floor():
					z.velocity.y += z.gravity * delta
				elif z.is_on_wall():
					z.velocity.y = -380.0
				z.move_and_slide()
				return true
			return false
		WIND:
			if has_pl:
				z._dir = signf(d.x) if absf(d.x) > 4.0 else z._dir
			if _st <= 0.0:
				_blast(pl)
				state = BLOW
				_st = 0.5
			return _stay(delta)
		BLOW:
			if _st <= 0.0:
				state = WALK
			return _stay(delta)
	return false


func _stay(delta: float) -> bool:
	z.velocity.x = move_toward(z.velocity.x, 0.0, 800.0 * delta)
	if not z.is_on_floor():
		z.velocity.y += z.gravity * delta
	z.move_and_slide()
	return true


func _blast(pl: Node) -> void:
	blasts += 1
	_cd = BLAST_CD
	_ring = 0.5
	Sfx.play("bd_blast", z.global_position, 6.0, 0.05, 2)
	var mouth: Vector2 = z.global_position + Vector2(z._dir * 18.0, -44.0) * z.sc
	Particles.burst(z.get_parent(), mouth, "smoke", Vector2(z._dir, 0.0), 4)
	if pl != null and not pl.dead:
		var dx: float = pl.global_position.x - z.global_position.x
		if signf(dx) == z._dir and absf(dx) < BLAST_R and absf(pl.global_position.y - z.global_position.y) < 80.0:
			pl.hurt(1, Vector2(z._dir * 3.2, -1.0))
			pl.velocity.x = z._dir * 520.0   # הדף חזק גם בלי נזק
	var cam: Camera2D = z.get_viewport().get_camera_2d()
	if cam != null and cam.has_method("shake"):
		cam.shake(5.0, 0.25)


func on_death() -> void:   # הרקדנים מאבדים את הקצב
	var D := preload("res://enemies/types/diablo.gd")
	var any := false
	for o in z.get_tree().get_nodes_in_group("zombies"):
		if o.dead or o.type_mod == null or not o.type_mod.has_method("lose_beat"):
			continue
		if o.global_position.distance_to(z.global_position) < D.SYNC_R and not _other_leader(o):
			o.type_mod.lose_beat()
			any = true
	if any:
		z._popup("THE MUSIC STOPS", Color("ffd080"), 14, -100.0)


func _other_leader(o: Node) -> bool:
	for b in z.get_tree().get_nodes_in_group("bandleaders"):
		if b != z and is_instance_valid(b) and not b.dead and b.global_position.distance_to(o.global_position) < preload("res://enemies/types/diablo.gd").SYNC_R:
			return true
	return false


# ============================================================
#  ציור: מעיל מצעדים אדום עם קישוטי זהב, כובע מצחייה, טובה (צינור עגול סביב הגוף + פעמון גדול)
# ============================================================
func draw() -> bool:
	begin_draw()
	var sk := col(z.skin)
	var coat := col(z.shirt)
	var gold := col(Color("e0b030"))
	var p: float = z._walk_phase
	var f: Array = feet(4.0, 2.0)
	var hip := Vector2(0, -22)
	var sh := Vector2(1, -38)
	var head := sh + Vector2(3.5, -8)
	var blowing: bool = state == WIND or state == BLOW
	z._leg(hip + Vector2(-2, 0), f[1], col(Art.shade(z.pants, 0.25)), sk, col(z.shoe))
	z._leg(hip + Vector2(2, 0), f[0], col(z.pants), sk, col(z.shoe))
	z.draw_line(hip + Vector2(-3, 2), f[1] + Vector2(0, -3), col(Color("e0b030")), 1.0)   # פס זהב במכנסיים
	z._arm(sh + Vector2(-3, 1), sh + Vector2(6, 10), Art.shade(sk, 0.25), Art.shade(coat, 0.3))
	Art.fill_shaded(z, PackedVector2Array([sh + Vector2(-8, -1), sh + Vector2(8, 0), hip + Vector2(8, 3), hip + Vector2(-8, 3)]), coat, 0.12, 0.4)
	for q in 3:   # קישוטי זהב
		z.draw_line(sh + Vector2(-5, 3.0 + float(q) * 5.0), sh + Vector2(5, 3.0 + float(q) * 5.0), gold, 1.4)
	z.draw_rect(Rect2(sh + Vector2(-10, -2), Vector2(5, 3)), gold)   # כותפת
	# הטובה: צינור עגול סביב הגוף + פעמון מעל הכתף
	z.draw_arc(sh + Vector2(-1, 10), 11.0, 0.0, TAU, 18, gold, 3.0)
	var bell := sh + Vector2(10, -18)
	z.draw_line(sh + Vector2(-8, 4), bell + Vector2(-4, 6), gold, 4.0)
	z.draw_colored_polygon(PackedVector2Array([bell + Vector2(-6, 6), bell + Vector2(-2, -6), bell + Vector2(8, -12), bell + Vector2(14, -4), bell + Vector2(4, 8)]), gold)
	z.draw_colored_polygon(Art.ellipse(bell + Vector2(10, -8), 3.5, 6.0, -0.7, 10), col(Color("6a4a10")))
	Art.oval_shaded(z, head, 5.2 + (1.0 if blowing else 0.0), 5.8, sk, 0.0)
	if blowing:   # לחיים נפוחות
		z.draw_circle(head + Vector2(4, 2), 3.0, col(Color("a8b48a")))
	z.draw_rect(Rect2(head + Vector2(-5.5, -8), Vector2(11, 5)), col(Color("1e1e2a")))   # כובע מצחייה
	z.draw_line(head + Vector2(4, -3.5), head + Vector2(10, -3), col(Color("1a1418")), 2.0)
	z.draw_rect(Rect2(head + Vector2(-1, -7.5), Vector2(3, 3)), gold)
	if not z.dead:
		z.draw_circle(head + Vector2(3.0, -0.5), 1.0, Color(0.85, 0.9, 0.5))
	z._arm(sh + Vector2(3, 1), sh + Vector2(8, 4), sk, coat)
	if _ring > 0.0:   # גל קול
		var k := 1.0 - _ring / 0.5
		for q in 3:
			z.draw_arc(bell + Vector2(10, -8), 10.0 + k * 60.0 + float(q) * 12.0, -0.7, 0.7, 10, Color(1.0, 0.9, 0.5, (1.0 - k) * 0.6), 2.0)
	elif blowing and _st > 0.0:   # אזהרה
		z.draw_circle(bell + Vector2(10, -8), 4.0 + sin(z._time * 30.0) * 1.5, Color(1.0, 0.9, 0.5, 0.5))
	end_draw()
	return true
