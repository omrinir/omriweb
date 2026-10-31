extends "res://enemies/zombie_type.gd"
# ============================================================
#  LOADER (משלב 42, "METRO BARRACKS") - נושא התחמושת של אימפריית המתים: מסגרת גב עם ערימת ארגזי תחמושת מעל הראש.
#  "THEY LEARNED LOGISTICS": לא נלחם. מחפש מי צריך תחמושת:
#    קן מקלע ריק (MGNest, "NO AMMO!") -> רץ אליו וממלא מיד (במקום טעינה ארוכה).
#    רובאים בטווח SUPPLY_R -> כל SUPPLY_CD מחלק מחסניות: יורים פי 2 מהר יותר SUPPLY_T שניות (meta "supply_t", conscript.gd).
#    שומר מרחק ממך (KEEP) ומסתתר מאחורי חיילים.
#  ירייה בארגזים (מעל הראש) CRATE_HP פעמים -> הארגזים מתפוצצים: פיצוץ BLAST_R שפוגע גם בחיילים סביבו.
#  לשנות: SUPPLY_R, SUPPLY_CD, SUPPLY_T, KEEP, CRATE_HP, BLAST_R.
# ============================================================

const E := preload("res://enemies/empire_kit.gd")

const SOUNDS := {
	"ld_supply": [["C", 0, 0, 0.0, 0.05, 0.0, 40.0, 0.4, 1.0, 0], ["N", 0, 0, 0.05, 0.15, 0.0, 20.0, 0.25, 0.5, 0, 0.6]],
}

const SUPPLY_R := 260.0
const SUPPLY_CD := 5.0
const SUPPLY_T := 6.0
const KEEP := 300.0
const CRATE_HP := 2
const BLAST_R := 120.0

var crate_hp := CRATE_HP
var supplies := 0            # לבדיקות
var refills := 0
var _cd := 1.0
var _target: Node = null
var _scan := 0.0


func stats() -> Dictionary:
	return {"name": "LOADER", "hp": 30, "walk": 44.0, "chase": 88.0, "damage": 1, "bite_delay": 1.0, "scale": 1.0, "width": 1.05,
		"duck": 0.2, "cover": 0.6, "skin": Color("7a8670"), "shirt": E.UNIFORM, "pants": E.UNIFORM, "shoe": Color("1a1816"), "points": 460}


func setup() -> void:
	z.add_to_group("empire")


func brain_overrides() -> Dictionary:
	return {"aggression": 0.1, "retreat_probability": 0.4}


func can_bite() -> bool:
	return crate_hp <= 0


func on_damage(_amount: int, hit_pos: Vector2, dir: Vector2, src: Dictionary) -> bool:
	var s := str(src.get("source", "bullet"))
	if crate_hp > 0 and (s == "bullet" or s == "melee") and (hit_pos.y - z.global_position.y) / z.sc < -50.0:
		crate_hp -= 1
		Particles.burst(z.get_parent(), hit_pos, "spark", -dir, 4)
		if crate_hp <= 0:
			_boom.call_deferred()
		return false
	return true


func _boom() -> void:
	if z == null or not is_instance_valid(z):
		return
	var c: Vector2 = z.global_position + Vector2(0, -56.0) * z.sc
	z._popup("AMMO COOK-OFF!", Color("ffb040"), 15, -90.0)
	preload("res://explosion.gd").blast(z.get_parent(), c, BLAST_R, BLAST_R * 0.4, 50, 2, "barrel")


func physics(pl: Node, delta: float) -> bool:
	_cd -= delta
	_scan -= delta
	if z.dead or crate_hp <= 0:
		return false
	if z.goal_x < INF and _target == null:   # פקודת תנועה חיצונית (טנקים...) - קודם מצייתים
		return false
	# קן ריק? רצים אליו
	if _scan <= 0.0:
		_scan = 0.4
		if _target == null or not is_instance_valid(_target) or not _target.needs_ammo():
			_target = null
			var bd := 900.0
			for n in z.get_tree().get_nodes_in_group("mg_nests"):
				if n.needs_ammo() and absf(n.global_position.y - z.global_position.y) < 60.0:
					var dd: float = absf(n.global_position.x - z.global_position.x)
					if dd < bd:
						bd = dd
						_target = n
	if _target != null:
		var tx: float = _target.gun_spot() - _target.face * 24.0
		z.goal_x = tx
		if absf(z.global_position.x - tx) < 30.0:
			_target.refill(z)
			refills += 1
			Sfx.play("ld_supply", z.global_position, 0.0, 0.1, 2)
			_target = null
			z.goal_x = INF
		return false
	# מחלק מחסניות לרובאים
	if _cd <= 0.0:
		var n := 0
		for o in z.get_tree().get_nodes_in_group("empire"):
			if o != z and not o.dead and o.type_mod != null and o.type_mod.get("shots") != null and not o.is_boss() \
					and o.global_position.distance_to(z.global_position) < SUPPLY_R:
				o.set_meta("supply_t", float(o._time) + SUPPLY_T)
				n += 1
		if n > 0:
			_cd = SUPPLY_CD
			supplies += 1
			Sfx.play("ld_supply", z.global_position, -2.0, 0.1, 2)
			z._popup("AMMO UP!", Color("ffd060"), 12, -85.0)
		else:
			_cd = 1.0
	if pl == null or pl.dead:
		return false
	var d: Vector2 = pl.global_position - z.global_position
	if absf(d.x) < KEEP and absf(d.y) < 90.0:   # שומר מרחק
		z._dir = signf(d.x) if absf(d.x) > 4.0 else z._dir
		z.velocity.x = move_toward(z.velocity.x, -z._dir * float(z.chase_speed), 700.0 * delta)
		if not z.is_on_floor():
			z.velocity.y += z.gravity * delta
		z.move_and_slide()
		return true
	return false


# ============================================================
#  ציור: מסגרת גב עם 3 ארגזי תחמושת ירוקים מעל הראש (מסומנים), רצועות כתף, כובע קסדה
# ============================================================
func draw() -> bool:
	begin_draw()
	var o: Dictionary = E.soldier(self, z, Vector2(-2, -14), "helmet", E.UNIFORM, Vector2(-6, -14))
	var sh: Vector2 = o.sh
	var frame := col(Color("3a3020"))
	DrawBatch.line(z, sh + Vector2(-7, -2), sh + Vector2(-7, -34), frame, 2.0)   # מסגרת הגב
	DrawBatch.line(z, sh + Vector2(-1, -2), sh + Vector2(-1, -34), frame, 2.0)
	DrawBatch.line(z, sh + Vector2(-6, 0), sh + Vector2(4, 14), col(Color("2a2018")), 1.6)
	if crate_hp > 0:
		for q in 3:
			var cy := -24.0 - float(q) * 9.5
			var cx := -7.0 + (1.5 if q == 1 else 0.0)
			var r := Rect2(sh + Vector2(cx - 7.0, cy - 4.0), Vector2(14, 9))
			DrawBatch.rect(z, r, col(Color("4a5a30") if q != 1 else Color("54622e")))
			DrawBatch.rect(z, Rect2(r.position + Vector2(0, 3.5), Vector2(14, 1.5)), col(Color("2a3018")))
			DrawBatch.rect(z, Rect2(r.position + Vector2(5, 1), Vector2(4, 2)), col(Color("d8c060")))
		if crate_hp < CRATE_HP:
			Art.glow(z, sh + Vector2(-7, -40), 6.0, Color(1.0, 0.6, 0.2, 0.5))
	end_draw()
	return true
