extends "res://enemies/stationary_boss.gd"
# ============================================================
#  THE MARSHAL (הבוס של שלב 41, "THE PARADE") - בוס נייח: מרשל אימפריית המתים עומד על יציע הכבוד ומקבל את המצעד.
#  מעיל ארוך, כובע מצחייה ענק עם הסמל, אבנט אדום, מדליות, כותפות זהב. מגפון ביד אחת, אקדח ביד השנייה.
#  זכוכית משוריינת (GLASS_HP) לפניו - מגינה רק מהצד של המצעד (שמאל). שוברים אותה - או עוקפים אותו מאחור על היציע.
#  התקפות (stationary_boss.gd):
#    barrage - "ARTILLERY!": עשן אדום מסמן את המקום שלך, ואחרי MARK_T נוחתים פגזים מהשמיים סביב הסימון.
#              "THEY LEARN": התחמקת? המטח הבא רחב יותר (עד 5 פגזים) ומוזז לכיוון שאליו ברחת.
#    pistol  - צרור PISTOL_N כדורים
#    kneel   - "KNEEL!": קרוב אליו - צעקה במגפון שמסחררת ודוחפת
#    pound   - צמוד אליו: בעיטה
#  חצי חיים -> "GUARD!": קורא ל-GUARD_N שומרים (GUARDSMAN) ולכל חיילי האימפריה להסתער.
#  לשנות: GLASS_HP, BARRAGE_CD, MARK_T, SPREAD, PISTOL_CD, KNEEL_R, GUARD_N.
# ============================================================

const E := preload("res://enemies/empire_kit.gd")

const SOUNDS := {
	"ms_glass": [["N", 0, 0, 0.0, 0.08, 0.0, 40.0, 0.4, 0.2, 0, 0.3], ["S", 3200, 2800, 0.0, 0.08, 0.0, 40.0, 0.12, 1.0, 0]],
	"ms_shatter": [["N", 0, 0, 0.0, 0.6, 0.0, 6.0, 0.7, 0.15, 0, 0.3], ["S", 4000, 2500, 0.0, 0.4, 0.0, 8.0, 0.15, 1.0, 0.2]],
	"ms_whistle": [["S", 1800, 500, 0.0, 0.8, 0.0, 2.0, 0.18, 1.0, 0.01]],
	"ms_pistol": [["N", 0, 0, 0.0, 0.09, 0.0, 40.0, 0.7, 0.6, 0, 0.5], ["S", 260, 110, 0.0, 0.08, 0.0, 40.0, 0.35, 1.0, 0]],
	"ms_shout": {"drive": 2.0, "layers": [["V", 120, 90, 0.0, 0.8, 0.03, 3.0, 0.7, 1.0, 0.05, 0, [600, 1400, 3]]]},
}

const GLASS_HP := 6
const BARRAGE_CD := 4.6
const MARK_T := 1.6
const SPREAD := 75.0
const BLAST := 70.0
const PISTOL_CD := 2.4
const PISTOL_N := 3
const PISTOL_V := 640.0
const KNEEL_R := 260.0
const KNEEL_CD := 5.0
const GUARD_N := 2

var glass := GLASS_HP
var barrages := 0            # לבדיקות
var widths := []             # כמה פגזים בכל מטח
var dodged := 0
var outcomes := []           # לבדיקות: "HIT" / "DODGED" לכל מטח
var kneels := 0
var guards_called := false
var _n := 3                  # כמה פגזים במטח הבא
var _lean := 0.0             # הזזה לכיוון שאליו ברחת
var _bar_cd := 2.5
var _pis_cd := 1.5
var _kneel_cd := 2.0
var _left := 0
var _rate := 0.0
var _pending := 0
var _bar_hit := false
var _bar_x := 0.0
var _crack_t := 0.0


class Tracker extends RefCounted:   # פגז של מטח -> המרשל לומד אם התחמקת
	var z: Node = null
	var boss = null

	func shot_result(hit: bool) -> void:
		if boss != null:
			boss._barrage_result(hit)


class Marker extends Node2D:   # עשן אדום שמסמן את המטח
	var boss = null
	var t := MARK_T
	var n := 3
	var lean := 0.0

	func _ready() -> void:
		z_index = 8

	func _physics_process(delta: float) -> void:
		t -= delta
		if Engine.get_physics_frames() % 6 == 0:
			preload("res://particles.gd").burst(get_parent(), global_position + Vector2(randf_range(-6, 6), -4), "smoke", Vector2(0, -1), 1)
		if t <= 0.0:
			if boss != null and is_instance_valid(boss.z) and not boss.z.dead:
				boss._drop_shells(global_position, n, lean)
			queue_free()
		queue_redraw()

	func _draw() -> void:
		var k := 1.0 - clampf(t / MARK_T, 0.0, 1.0)
		for q in 4:   # עמוד עשן אדום
			DrawBatch.circle(self, Vector2(sin(float(q) * 2.0 + t * 3.0) * 4.0, -8.0 - float(q) * 14.0 - k * 10.0), 8.0 + float(q) * 3.0, Color(0.9, 0.12, 0.08, 0.35 - float(q) * 0.06))
		DrawBatch.circle(self, Vector2.ZERO, 5.0, Color(1.0, 0.2, 0.1, 0.9))
		var w := SPREAD * float(int(float(n) / 2.0)) + BLAST * 0.6   # האזור שיופגז
		DrawBatch.line(self, Vector2(-w + lean, 2), Vector2(w + lean, 2), Color(1.0, 0.2, 0.1, 0.3 + 0.5 * k), 3.0)


func stats() -> Dictionary:
	return {"name": "THE MARSHAL", "hp": 360, "walk": 0.0, "chase": 0.0, "damage": 2, "bite_delay": 1.0, "scale": 2.3, "width": 1.15,
		"duck": 0.0, "cover": 0.0, "skin": Color("7e8a74"), "shirt": E.UNIFORM_D, "pants": E.UNIFORM_D, "shoe": Color("101010"),
		"points": 2800, "boss": true, "boss_name": "THE MARSHAL - BREAK THE GLASS OR FLANK HIM"}


func setup() -> void:
	super.setup()
	z.add_to_group("empire")


func eye() -> Vector2:   # האקדח
	return z.global_position + Vector2(z._dir * 16.0 * z.wf, -36.0) * z.sc


func weak_rect() -> Rect2:
	return Rect2(-2, -54, 13, 15)


func glass_x() -> float:   # הזכוכית: קבועה בצד שמאל של היציע (בעולם)
	return z.global_position.x - 26.0 * z.sc


func on_damage(amount: int, hit_pos: Vector2, dir: Vector2, src: Dictionary) -> bool:
	var s := str(src.get("source", "bullet"))
	var expl := src.has("blast")
	if glass > 0 and (s == "bullet" or s == "melee" or expl) and hit_pos.x < z.global_position.x + 4.0 * z.sc:
		glass -= 2 if expl else 1
		_crack_t = 0.12
		Sfx.play("ms_glass", hit_pos, -2.0, 0.2, 3)
		Particles.burst(z.get_parent(), Vector2(glass_x(), hit_pos.y), "spark", -dir, 3)
		if glass <= 0:
			glass = 0
			Sfx.play("ms_shatter", z.global_position, 2.0, 0.05, 2)
			Particles.burst(z.get_parent(), Vector2(glass_x(), z.global_position.y - 30.0 * z.sc), "spark", Vector2(-1, -0.4), 16)
			z._popup("THE GLASS SHATTERED", Color("c0e8ff"), 15, -60.0 - 70.0 * z.sc)
		elif glass == GLASS_HP - 1:
			z._popup("BULLETPROOF GLASS", Color("c0e8ff"), 13, -60.0 - 70.0 * z.sc)
		return false
	return super.on_damage(amount, hit_pos, dir, src)


func _call_guard() -> void:
	if guards_called or z == null or not is_instance_valid(z) or z.dead:
		return
	guards_called = true
	Sfx.play("ms_shout", z.global_position, 3.0, 0.05, 2)
	z._popup("GUARD! PROTECT THE MARSHAL!", Color("ff6040"), 16, -70.0 - 70.0 * z.sc)
	var main: Node = z.get_parent()
	var gy: float = float(main.get_meta("boss_ground_y")) if main.has_meta("boss_ground_y") else z.global_position.y
	for i in GUARD_N:
		var g: Node = main._spawn_zombie(z.global_position.x - 140.0 - float(i) * 70.0, gy, preload("res://enemies/zombie_registry.gd").GUARDSMAN)
		if g != null:
			g._alert_t = 10.0
	E.order(z, "charge", 1400.0)


func think(pl: Node, delta: float) -> void:
	_bar_cd -= delta
	_pis_cd -= delta
	_kneel_cd -= delta
	_rate -= delta
	_crack_t -= delta
	if not guards_called and float(z.hp) < float(z.max_hp) * 0.5:
		_call_guard()
		return
	if _left > 0:
		if _rate <= 0.0:
			_left -= 1
			_rate = 0.16
			fire_shot(eye(), aim_point(pl, PISTOL_V) + Vector2(randf_range(-6, 6), randf_range(-6, 6)), PISTOL_V, 1, "bolt", Color(1.0, 0.85, 0.4), 4.0)
			Sfx.play("ms_pistol", eye(), -2.0, 0.1, 3)
		return
	var d: Vector2 = pl.global_position - z.global_position
	if absf(d.x) > 1250.0:
		return
	if _kneel_cd <= 0.0 and absf(d.x) < KNEEL_R and absf(d.y) < 120.0:
		wind("kneel", 0.5)
		return
	if _bar_cd <= 0.0 and _pending <= 0 and absf(d.x) > 200.0:
		wind("barrage", 0.6)
		Sfx.play("ms_shout", z.global_position, 0.0, 0.05, 2)
		z._popup("ARTILLERY!", Color("ff6040"), 15, -60.0 - 70.0 * z.sc)
		return
	if _pis_cd <= 0.0:
		wind("pistol", 0.35)


func attack(name: String, pl: Node) -> void:
	match name:
		"pound":
			do_pound(pl)
		"pistol":
			_pis_cd = PISTOL_CD
			_left = PISTOL_N
			_rate = 0.0
		"kneel":
			_kneel_cd = KNEEL_CD
			kneels += 1
			Sfx.play("ms_shout", z.global_position, 3.0, 0.05, 2)
			z._popup("KNEEL!", Color("ffd040"), 18, -60.0 - 70.0 * z.sc)
			var d: Vector2 = pl.global_position - z.global_position
			if absf(d.x) < KNEEL_R and absf(d.y) < 120.0:
				pl.daze(0.8, "")
				pl.velocity = Vector2(signf(d.x + 0.01) * 520.0, -260.0)
		"barrage":
			_bar_cd = BARRAGE_CD
			barrages += 1
			widths.append(_n)
			_bar_x = pl.global_position.x
			var m := Marker.new()
			m.boss = self
			m.n = _n
			m.lean = _lean
			z.get_parent().add_child(m)
			m.global_position = pl.global_position
			_pending = _n


func _drop_shells(at: Vector2, n: int, lean: float) -> void:
	_bar_hit = false
	_pending = n
	Sfx.play("ms_whistle", at, 0.0, 0.05, 2)
	for i in n:
		var off := SPREAD * float(int(float(i + 1) / 2.0)) * (1.0 if i % 2 == 1 else -1.0)
		var tgt := at + Vector2(off + lean, 0.0)
		var from := tgt + Vector2(160.0, -900.0)
		var l: Node = fire_lob(from, tgt, 0.75 + 0.05 * float(i), 2, "shell", BLAST, Color(1.0, 0.6, 0.2), 7.0)
		var tr := Tracker.new()
		tr.z = z
		tr.boss = self
		l.owner_t = tr


func _barrage_result(hit: bool) -> void:
	if hit:
		_bar_hit = true
	_pending -= 1
	if _pending > 0 or z == null or not is_instance_valid(z) or z.dead:
		return
	outcomes.append("HIT" if _bar_hit else "DODGED")
	if _bar_hit:   # פגע: המטח הבא שוב צר ובמרכז
		_n = maxi(_n - 2, 3)
		_lean = 0.0
		return
	dodged += 1
	var pl := player()
	var moved := 0.0
	if pl != null:
		moved = pl.global_position.x - _bar_x
	_lean = clampf(moved * 0.5, -SPREAD * 1.5, SPREAD * 1.5)
	if _n < 5:
		_n += 2
		z._popup("HE LEARNED - WIDER BARRAGE", Color("ff8060"), 14, -60.0 - 70.0 * z.sc)


# ============================================================
#  ציור: מעיל ארוך, אבנט אדום, מדליות, כותפות זהב, כובע ענק עם הסמל, מגפון ואקדח. זכוכית משוריינת (בעולם) עם סדקים.
# ============================================================
func draw() -> bool:
	begin_draw()
	var k := wind_k()
	var raise := winding == "kneel" or winding == "barrage"
	var aim := winding == "pistol" or _left > 0
	var o: Dictionary = E.soldier(self, z, Vector2(14, -2) if aim else Vector2(8, 6), "cap", E.UNIFORM_D, Vector2(6, -14) if raise else Vector2(999, 0), 2.0)
	var sh: Vector2 = o.sh
	var hip: Vector2 = o.hip
	var head: Vector2 = o.head
	var hf: Vector2 = o.hf
	var gold := col(E.BRASS)
	# שולי מעיל ארוכים
	DrawBatch.colored_polygon(z, PackedVector2Array([hip + Vector2(-8, 4), hip + Vector2(8, 4), hip + Vector2(10, 16), hip + Vector2(-10, 16)]), col(E.UNIFORM_D))
	DrawBatch.line(z, sh + Vector2(-7, 0), hip + Vector2(7, 2), col(E.RED), 2.6)   # אבנט
	for q in 3:   # מדליות
		DrawBatch.line(z, sh + Vector2(-4.0 + float(q) * 2.5, 2), sh + Vector2(-4.0 + float(q) * 2.5, 5), col(E.RED), 1.2)
		DrawBatch.circle(z, sh + Vector2(-4.0 + float(q) * 2.5, 6), 1.1, gold)
	DrawBatch.rect(z, Rect2(sh + Vector2(-9, -2), Vector2(6, 2.4)), gold)   # כותפות
	DrawBatch.rect(z, Rect2(sh + Vector2(4, -2), Vector2(6, 2.4)), gold)
	# כובע ענק (מעל כובע הקצין)
	DrawBatch.colored_polygon(z, PackedVector2Array([head + Vector2(-8, -4), head + Vector2(-7, -11), head + Vector2(8, -12), head + Vector2(9, -5)]), col(E.UNIFORM_D))
	DrawBatch.rect(z, Rect2(head + Vector2(-8, -6), Vector2(17, 2.4)), col(E.RED))
	DrawBatch.rect(z, Rect2(head + Vector2(2, -4), Vector2(10, 1.8)), col(Color("141414")))
	E.emblem(z, head + Vector2(0.5, -9), 2.4)
	DrawBatch.line(z, head + Vector2(-6, -5), head + Vector2(8, -5), gold, 0.8)
	# אקדח
	DrawBatch.rect(z, Rect2(hf + Vector2(0, -2), Vector2(8, 3)), col(Color("1a1a1a")))
	if winding == "pistol" and not z.dead:
		Art.glow(z, hf + Vector2(9, -0.5), 3.0 + 4.0 * k, Color(1.0, 0.85, 0.4, 0.3 + 0.5 * k))
	# מגפון ביד האחורית
	var mg := sh + (Vector2(6, -14) if raise else Vector2(-5, 15))
	DrawBatch.colored_polygon(z, PackedVector2Array([mg + Vector2(0, -1.5), mg + Vector2(0, 1.5), mg + Vector2(8, 4), mg + Vector2(8, -4)]), col(E.RED))
	end_draw()
	# הזכוכית המשוריינת (בעולם, קבועה)
	if glass > 0:
		var gx: float = glass_x() - z.global_position.x
		var top: float = -62.0 * z.sc
		var gc := Color(0.75, 0.9, 1.0, 0.22 + (0.25 if _crack_t > 0.0 else 0.0))
		DrawBatch.rect(z, Rect2(gx - 3.0, top, 6.0, -top - 4.0), gc)
		DrawBatch.line(z, Vector2(gx + 2.0, top + 6.0), Vector2(gx + 2.0, -10.0), Color(1, 1, 1, 0.35), 1.2)
		DrawBatch.rect(z, Rect2(gx - 4.0, -6.0, 8.0, 6.0), Color("2a2a2a"))
		var cracks := GLASS_HP - glass
		for q in cracks:   # סדקים
			var cy := top + 20.0 + float(q) * (-top - 40.0) / float(GLASS_HP)
			DrawBatch.line(z, Vector2(gx - 3.0, cy), Vector2(gx + 3.0, cy + 8.0), Color(1, 1, 1, 0.7), 1.0)
			DrawBatch.line(z, Vector2(gx + 3.0, cy), Vector2(gx - 2.0, cy + 6.0), Color(1, 1, 1, 0.5), 0.8)
	return true
