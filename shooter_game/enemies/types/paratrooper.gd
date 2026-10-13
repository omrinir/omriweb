extends "res://enemies/zombie_type.gd"
# ============================================================
#  PARATROOPER (משלב 44, "THE DAM") - צנחן של אימפריית המתים: קסדה עגולה, רתמה, מצנח אדום עם הסמל, תת-מקלע.
#  "THEY LEARNED TO FLANK": קופץ ממטוס (s44_decor DropZone, meta "drop") ונוחת מאחוריך - בצד שאליו אתה לא מסתכל,
#    ומכוון את המצנח לשם בזמן הירידה. באוויר הוא פגיע (AIR_MULT).
#  "THEY LEARN TOGETHER - HALO": ירית צנחנים באוויר HALO_LEARN פעמים? מעכשיו הם בנפילה חופשית ופותחים מצנח רק נמוך (HALO_OPEN).
#  על הקרקע: צרורות קצרים (SMG_N) מטווח בינוני.
#  לשנות: DROP_H, CHUTE_V, FALL_V, HALO_OPEN, HALO_LEARN, AIR_MULT, SMG_N, SMG_CD.
# ============================================================

const E := preload("res://enemies/empire_kit.gd")

const SOUNDS := {
	"pa_chute": [["N", 0, 0, 0.0, 0.4, 0.0, 8.0, 0.4, 0.5, 0, 0.7], ["S", 300, 180, 0.0, 0.2, 0.0, 12.0, 0.1, 1.0, 0]],
	"pa_smg": [["N", 0, 0, 0.0, 0.05, 0.0, 50.0, 0.5, 0.7, 0, 0.4], ["S", 240, 120, 0.0, 0.04, 0.0, 50.0, 0.25, 1.0, 0]],
}

const DROP_H := 560.0
const CHUTE_V := 115.0
const FALL_V := 520.0
const HALO_OPEN := 130.0
const HALO_LEARN := 2
const AIR_MULT := 1.5
const DRIFT := 90.0
const SMG_N := 4
const SMG_CD := 2.4
const SMG_R := 380.0

var in_air := false
var chute := false
var halo := false
var air_hits := 0            # לבדיקות
var bursts := 0
var _started := false
var _cd := 1.0
var _left := 0
var _rate := 0.0
var _side := -1.0


func stats() -> Dictionary:
	return {"name": "PARATROOPER", "hp": 32, "walk": 46.0, "chase": 92.0, "damage": 1, "bite_delay": 0.8, "scale": 1.0, "width": 1.0,
		"duck": 0.3, "cover": 0.5, "skin": Color("7a8670"), "shirt": Color("5a5a44"), "pants": Color("5a5a44"), "shoe": Color("1a1816"), "points": 460}


func setup() -> void:
	z.add_to_group("empire")


func brain_overrides() -> Dictionary:
	return {"aggression": 0.7}


static func halo_learned(main: Node) -> bool:
	return main.has_meta("para_shot") and int(main.get_meta("para_shot")) >= HALO_LEARN


func on_damage(_amount: int, _hit_pos: Vector2, _dir: Vector2, src: Dictionary) -> bool:
	if in_air and str(src.get("source", "bullet")) == "bullet":
		air_hits += 1
		if air_hits == 1:   # נספר פעם אחת לכל צנחן
			var main: Node = z.get_parent()
			main.set_meta("para_shot", (int(main.get_meta("para_shot")) if main.has_meta("para_shot") else 0) + 1)
			if int(main.get_meta("para_shot")) == HALO_LEARN:
				z._popup("THEY LEARNED - HALO JUMPS", Color("ff8060"), 14, -80.0)
	return true


func damage_mult(_zone: String, _src: Dictionary) -> float:
	return AIR_MULT if in_air else 1.0


func _start(pl: Node) -> void:
	_started = true
	in_air = true
	halo = halo_learned(z.get_parent())
	chute = not halo
	z.global_position.y -= DROP_H
	z.velocity = Vector2.ZERO
	if pl != null:
		_side = -signf(pl._aim.x) if pl._aim.x != 0.0 else -1.0
	if chute:
		Sfx.play("pa_chute", z.global_position, -4.0, 0.1, 2)


func physics(pl: Node, delta: float) -> bool:
	_cd -= delta
	_rate -= delta
	if z.dead:
		in_air = false
		return false
	if not _started and z.has_meta("drop"):
		_start(pl)
	if in_air:
		# מכוון את הנחיתה לצד שמאחוריך
		if pl != null and not pl.dead:
			var tx: float = pl.global_position.x + _side * 200.0
			z.velocity.x = move_toward(z.velocity.x, clampf(tx - z.global_position.x, -DRIFT, DRIFT), 200.0 * delta)
			z._dir = signf(pl.global_position.x - z.global_position.x + 0.01)
		if not chute:   # נפילה חופשית - בודקים כמה קרוב לקרקע
			z.velocity.y = FALL_V
			var q := PhysicsRayQueryParameters2D.create(z.global_position, z.global_position + Vector2(0, HALO_OPEN), 1 | 16)
			if not z.get_world_2d().direct_space_state.intersect_ray(q).is_empty():
				chute = true
				Sfx.play("pa_chute", z.global_position, -2.0, 0.1, 2)
		else:
			z.velocity.y = move_toward(z.velocity.y, CHUTE_V, 900.0 * delta)
		z.move_and_slide()
		if z.is_on_floor():
			in_air = false
			chute = false
			z._alert_t = 8.0
			Particles.burst(z.get_parent(), z.global_position, "smoke", Vector2.UP, 4)
		return true
	if pl == null or pl.dead or z.goal_x < INF:
		return false
	var d: Vector2 = pl.global_position - z.global_position
	if _left > 0:
		if _rate <= 0.0:
			_left -= 1
			_rate = 0.09
			var m: Vector2 = z.global_position + Vector2(z._dir * 16.0, -30.0) * z.sc
			E.fire(z, m, pl.global_position + Vector2(0, E.squad_aim_y(z.get_parent())) + Vector2(0, randf_range(-10, 10)), 600.0)
			Sfx.play("pa_smg", m, -5.0, 0.1, 4)
		z.velocity.x = move_toward(z.velocity.x, 0.0, 800.0 * delta)
		if not z.is_on_floor():
			z.velocity.y += z.gravity * delta
		z.move_and_slide()
		return true
	if _cd <= 0.0 and absf(d.x) < SMG_R and absf(d.y) < 100.0 and E.clear_shot(z, z.global_position + Vector2(0, -30), pl.global_position + Vector2(0, -24)):
		_cd = SMG_CD
		_left = SMG_N
		bursts += 1
		z._dir = signf(d.x)
	return false


# ============================================================
#  ציור: קסדת צנחן עגולה, רתמה, תת-מקלע קצר. באוויר: מצנח אדום עם הסמל וחוטים (או בנפילה חופשית - ידיים פרושות)
# ============================================================
func draw() -> bool:
	begin_draw()
	var falling := in_air and not chute
	var o: Dictionary = E.soldier(self, z, Vector2(10, -16) if falling else Vector2(11, 2), "helmet", Color("5a5a44"), Vector2(-10, -16) if falling else Vector2(999, 0))
	var sh: Vector2 = o.sh
	var hip: Vector2 = o.hip
	var hf: Vector2 = o.hf
	z.draw_line(sh + Vector2(-6, 0), hip + Vector2(-5, 2), col(Color("2a2a20")), 1.6)   # רתמה
	z.draw_line(sh + Vector2(6, 0), hip + Vector2(5, 2), col(Color("2a2a20")), 1.6)
	z.draw_rect(Rect2(hf + Vector2(-2, -2), Vector2(10, 3)), col(Color("1a1a1a")))   # SMG
	z.draw_rect(Rect2(hf + Vector2(2, 0), Vector2(2, 4)), col(Color("1a1a1a")))
	if not in_air:
		z.draw_rect(Rect2(sh + Vector2(-11, 2), Vector2(6, 12)), col(Color("4a4a38")))   # המצנח המקופל על הגב
	end_draw()
	if in_air and chute and not z.dead:   # המצנח (בעולם)
		var top: Vector2 = Vector2(0, -105) * z.sc
		var w: float = 44.0 * z.sc
		z.draw_colored_polygon(Art.ellipse(top, w * 0.5, 16.0 * z.sc, 0.0, 16), E.RED)
		z.draw_rect(Rect2(top + Vector2(-w * 0.5, 0), Vector2(w, 6.0)), E.RED_D)
		E.emblem(z, top + Vector2(0, -2), 6.0 * z.sc)
		for q in 4:
			var ax: float = -w * 0.5 + float(q) * w / 3.0
			z.draw_line(top + Vector2(ax, 4.0), Vector2(0, -38) * z.sc, Color(0.15, 0.15, 0.15, 0.8), 0.8)
	return true
