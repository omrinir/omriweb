extends "res://enemies/stationary_boss.gd"
# ============================================================
#  THE TOWER (הבוס של שלב 38, "MEGACITY CORE") - בוס נייח: מפעיל עגורן ענק שהתמזג עם עגורן הצריח של אתר בנייה.
#  יושב על פיגום גבוה, זרוע העגורן (ג'יב) מעל הזירה, עם עגלה, כבל, וו וקורת I תלויה. אפוד זוהר, קסדה צהובה, אקדח מסמרים.
#  התקפות (stationary_boss.gd):
#    nails - צרור NAIL_N מסמרים (מקדים אותך אחרי פספוסים)
#    drop  - העגלה נוסעת על הג'יב אל מעליך ומשחררת את הקורה (נופלת ומתפוצצת). קורה חדשה עולה אחרי BEAM_RELOAD
#    pound - עלית אליו: מכה
#  "THEY LEARN": סופר כמה זמן אתה עומד בכל מקום בזירה (BUCKET פיקסלים). אחרי LEARN_T שניות -> יודע את "המקום האהוב" שלך,
#    וכל קורה שנייה נופלת שם. הקסדה מגינה על הראש (x0.35) עד HAT_HP פגיעות בראש - ואז הראש פגיע.
#  לשנות: NAIL_CD, DROP_CD, NAIL_N, JIB, BUCKET, LEARN_T, HAT_HP.
# ============================================================

const SOUNDS := {
	"tw_nail": [["C", 0, 0, 0.0, 0.04, 0.0, 60.0, 0.6, 1.0, 0], ["N", 0, 0, 0.0, 0.06, 0.0, 40.0, 0.3, 0.7, 0, 0.5]],
	"tw_trolley": [["S", 220, 260, 0.0, 0.6, 0.05, 2.0, 0.12, 1.0, 0.04], ["N", 0, 0, 0.0, 0.6, 0.05, 2.0, 0.1, 0.4, 0, 0.6]],
	"tw_clang": [["S", 1800, 1750, 0.0, 0.3, 0.0, 8.0, 0.3, 1.0, 0.01], ["S", 2700, 2650, 0.0, 0.2, 0.0, 10.0, 0.15, 1.0, 0.01]],
	"tw_release": [["C", 0, 0, 0.0, 0.05, 0.0, 50.0, 0.6, 1.0, 0], ["S", 600, 200, 0.0, 0.3, 0.0, 8.0, 0.2, 1.0, 0]],
}

const NAIL_CD := 2.3
const DROP_CD := 3.6
const BEAM_RELOAD := 2.0
const NAIL_N := 4
const NAIL_V := 640.0
const JIB := 110.0           # אורך הג'יב (מקומי)
const BUCKET := 100.0
const LEARN_T := 10.0
const HAT_HP := 3

var hat := HAT_HP
var drops := 0               # לבדיקות
var fav_x := INF             # המקום האהוב שלך (עולם) - INF = עוד לא למד
var _nail_cd := 1.5
var _drop_cd := 3.0
var _left := 0
var _rate := 0.0
var _hook := 70.0            # מיקום העגלה על הג'יב (מקומי)
var _hook_to := 70.0
var _beam := true
var _beam_t := 0.0
var _heat := {}
var _sampled := 0.0
var _sample_t := 0.0
var _alt := false
var _last_sample := 0.0


func stats() -> Dictionary:
	return {"name": "THE TOWER", "hp": 360, "walk": 0.0, "chase": 0.0, "damage": 2, "bite_delay": 1.0, "scale": 2.4, "width": 1.6,
		"duck": 0.0, "cover": 0.0, "skin": Color("8a9478"), "shirt": Color("ff7a1a"), "pants": Color("2a3a5a"), "shoe": Color("3a2a1a"),
		"points": 2300, "boss": true, "boss_name": "THE TOWER - KNOCK OFF HIS HARD HAT"}


func eye() -> Vector2:   # אקדח המסמרים
	return z.global_position + Vector2(z._dir * 20.0 * z.wf, -40.0) * z.sc


func hook_pos() -> Vector2:
	return z.global_position + Vector2(z._dir * _hook * z.wf, -62.0) * z.sc


func weak_rect() -> Rect2:
	return Rect2(-3, -72, 18, 18)


func damage_mult(zone: String, src: Dictionary) -> float:
	var m := super.damage_mult(zone, src)
	var s := str(src.get("source", "bullet"))
	if (s == "bullet" or s == "melee") and in_weak(_last_hit) and hat > 0:   # הקסדה
		hat -= 1
		Sfx.play("tw_clang", _last_hit, 0.0, 0.1, 3)
		Particles.burst(z.get_parent(), _last_hit, "spark", Vector2.UP, 5)
		if hat == 0:
			z._popup("HARD HAT KNOCKED OFF!", Color("ffe040"), 15, -60.0 - 80.0 * z.sc)
			var h := Hat.new()
			z.get_parent().add_child(h)
			h.global_position = z.global_position + Vector2(z._dir * 7.0 * z.wf, -76.0) * z.sc
			h.vel = Vector2(-z._dir * 160.0, -260.0)
		return m * 0.35 / WEAK_MULT
	return m


func think(pl: Node, delta: float) -> void:
	_nail_cd -= delta
	_drop_cd -= delta
	_rate -= delta
	_sample_t -= delta
	if not _beam:
		_beam_t -= delta
		if _beam_t <= 0.0:
			_beam = true
	_hook = move_toward(_hook, _hook_to, 120.0 * delta)
	var dx: float = absf(pl.global_position.x - z.global_position.x)
	if _sample_t <= 0.0 and dx < 1300.0:   # מפת חום של איפה אתה עומד (זמן אמיתי - גם בזמן ההתקפות)
		var dt: float = clampf(float(z._time) - _last_sample, 0.0, 1.5) if _last_sample > 0.0 else 0.25
		_last_sample = float(z._time)
		_sample_t = 0.25
		var b := int(floor(pl.global_position.x / BUCKET))
		_heat[b] = float(_heat.get(b, 0.0)) + dt
		_sampled += dt
		if fav_x == INF and _sampled >= LEARN_T:
			var best := 0.0
			for k in _heat:
				if float(_heat[k]) > best:
					best = float(_heat[k])
					fav_x = (float(k) + 0.5) * BUCKET
			z._popup("IT KNOWS YOUR FAVORITE SPOT", Color("ffd070"), 15, -60.0 - 80.0 * z.sc)
		elif fav_x != INF and randf() < 0.1:   # מעדכן מדי פעם
			var best := 0.0
			for k in _heat:
				if float(_heat[k]) > best:
					best = float(_heat[k])
					fav_x = (float(k) + 0.5) * BUCKET
	if _left > 0:
		if _rate <= 0.0:
			_left -= 1
			_rate = 0.12
			fire_shot(eye(), aim_point(pl, NAIL_V), NAIL_V, 1, "nail", Color(0.8, 0.82, 0.86), 5.0)
			Sfx.play("tw_nail", eye(), -2.0, 0.1, 4)
		return
	if dx > 1200.0:
		return
	if _beam and _drop_cd <= 0.0:
		var tx: float = pl.global_position.x + pl.velocity.x * 0.5 * lead
		if fav_x != INF and _alt:
			tx = fav_x
		_alt = not _alt
		_hook_to = clampf((tx - z.global_position.x) * z._dir / (z.wf * z.sc), 30.0, JIB)
		set_meta("drop_x", tx)
		Sfx.play("tw_trolley", hook_pos(), -2.0, 0.05, 2)
		wind("drop", 1.0)
		return
	if _nail_cd <= 0.0:
		wind("nails", 0.5)


func attack(name: String, pl: Node) -> void:
	match name:
		"pound":
			do_pound(pl)
		"nails":
			_nail_cd = NAIL_CD
			_left = NAIL_N
			_rate = 0.0
		"drop":
			_drop_cd = DROP_CD
			drops += 1
			_beam = false
			_beam_t = BEAM_RELOAD
			Sfx.play("tw_release", hook_pos(), 0.0, 0.05, 2)
			var tx: float = float(get_meta("drop_x")) if has_meta("drop_x") else pl.global_position.x
			var from := hook_pos() + Vector2(0, 30.0 * z.sc * 0.4)
			var fall: float = sqrt(maxf(2.0 * (pl.global_position.y - from.y) / 900.0, 0.2))
			fire_lob(from, Vector2(tx, pl.global_position.y), clampf(fall, 0.5, 1.2), 1, "beam", 60.0, Color(0.6, 0.2, 0.15), 10.0)


class Hat extends Node2D:   # הקסדה עפה
	var vel := Vector2.ZERO
	var _t := 0.0

	func _ready() -> void:
		z_index = 8

	func _process(delta: float) -> void:
		_t += delta
		vel.y += 900.0 * delta
		position += vel * delta
		rotation += 8.0 * delta
		if _t > 1.5:
			queue_free()
			return
		queue_redraw()

	func _draw() -> void:
		draw_colored_polygon(PackedVector2Array([Vector2(-14, 2), Vector2(-12, -8), Vector2(0, -14), Vector2(12, -8), Vector2(14, 2)]), Color("f0c820"))
		draw_rect(Rect2(-18, 0, 36, 4), Color("d0a810"))


# ============================================================
#  ציור: התורן מאחוריו, הג'יב מעל הזירה עם עגלה, כבל, וו וקורת I; משקולות בטון מאחור.
#  הענק: אפוד כתום זוהר עם פסים, קסדה צהובה, אקדח מסמרים ביד
# ============================================================
func draw() -> bool:
	begin_draw()
	var sk := col(z.skin)
	var vest := col(z.shirt)
	var k := wind_k()
	var steel := col(Color("e0b020"))
	var hip := Vector2(0, -22)
	var sh := Vector2(2, -48)
	var head := sh + Vector2(5, -12)
	# התורן (מסבכת צהובה)
	var mx := -12.0
	z.draw_line(Vector2(mx - 6, 0), Vector2(mx - 6, -112), steel, 2.0)
	z.draw_line(Vector2(mx + 6, 0), Vector2(mx + 6, -112), steel, 2.0)
	var yy := 0.0
	while yy > -108.0:
		z.draw_line(Vector2(mx - 6, yy), Vector2(mx + 6, yy - 10.0), steel, 1.2)
		z.draw_line(Vector2(mx - 6, yy - 10.0), Vector2(mx + 6, yy - 10.0), steel, 1.0)
		yy -= 10.0
	# הג'יב קדימה + נגד-ג'יב אחורה עם משקולות
	z.draw_line(Vector2(mx - 40, -112), Vector2(JIB + 6.0, -112), steel, 2.5)
	z.draw_line(Vector2(mx - 40, -104), Vector2(JIB + 6.0, -106), steel, 1.5)
	var jx := mx - 36.0
	while jx < JIB:
		z.draw_line(Vector2(jx, -104), Vector2(jx + 6.0, -112), steel, 1.0)
		jx += 8.0
	z.draw_line(Vector2(mx, -126), Vector2(JIB, -112), col(Color("8a8a8a")), 1.0)   # כבלי תמיכה
	z.draw_line(Vector2(mx, -126), Vector2(mx - 40, -112), col(Color("8a8a8a")), 1.0)
	z.draw_line(Vector2(mx - 6, -112), Vector2(mx, -126), steel, 1.5)
	z.draw_line(Vector2(mx + 6, -112), Vector2(mx, -126), steel, 1.5)
	z.draw_rect(Rect2(mx - 42, -110, 16, 14), col(Color("8a8680")))   # משקולות בטון
	z.draw_rect(Rect2(mx - 42, -110, 16, 14), Art.OUTLINE, false, 0.8)
	# עגלה, כבל, וו וקורה
	var hx := _hook
	z.draw_rect(Rect2(hx - 4, -110, 8, 4), col(Color("3a3a3a")))
	var hy := -66.0
	z.draw_line(Vector2(hx, -106), Vector2(hx, hy), col(Color("2a2a2a")), 0.8)
	z.draw_arc(Vector2(hx, hy + 2), 2.0, 0.0, PI * 1.5, 6, col(Color("c03020")), 1.2)
	if _beam:
		var sw := sin(z._time * (2.0 + 10.0 * k)) * (0.08 + 0.2 * k) if winding == "drop" else sin(z._time * 1.5) * 0.05
		var bc := Vector2(hx, hy + 6)
		var bd := Vector2.from_angle(sw)
		z.draw_line(Vector2(hx, hy + 3), bc - bd * 10.0, col(Color("2a2a2a")), 0.6)
		z.draw_line(Vector2(hx, hy + 3), bc + bd * 10.0, col(Color("2a2a2a")), 0.6)
		z.draw_line(bc - bd * 16.0, bc + bd * 16.0, col(Color("8a3a2a")), 4.0)   # קורת I
		z.draw_line(bc - bd * 16.0 + Vector2(0, -2), bc + bd * 16.0 + Vector2(0, -2), col(Color("6a2a1a")), 1.0)
	# הגוף
	z._arm(sh + Vector2(-8, 2), sh + Vector2(-14, -4 - 6.0 * k if winding == "drop" else 4.0), Art.shade(sk, 0.25), Art.shade(vest, 0.3))   # יד על הידיות
	z.draw_line(sh + Vector2(-14, -4), sh + Vector2(-18, 6), col(Color("3a3a3a")), 2.0)
	var torso := PackedVector2Array([sh + Vector2(-12, -3), sh + Vector2(12, -2), hip + Vector2(12, 2), hip + Vector2(-12, 2)])
	Art.fill_shaded(z, torso, vest, 0.12, 0.4)
	for q in 2:   # פסים זוהרים
		z.draw_line(sh + Vector2(-11, 8.0 + float(q) * 8.0), sh + Vector2(12, 8.0 + float(q) * 8.0), col(Color("e0e0e0")), 2.0)
	z.draw_rect(Rect2(hip + Vector2(-12, -2), Vector2(24, 26)), col(z.pants))
	Art.oval_shaded(z, head, 7.0, 7.5, sk, 0.0)
	if hat > 0:   # קסדה צהובה
		z.draw_colored_polygon(PackedVector2Array([head + Vector2(-8, -2), head + Vector2(-7, -8), head + Vector2(0, -11), head + Vector2(7, -8), head + Vector2(9, -2)]), col(Color("f0c820")))
		z.draw_rect(Rect2(head + Vector2(-9, -3), Vector2(20, 2.5)), col(Color("d0a810")))
		if hat < HAT_HP:   # שקעים
			z.draw_line(head + Vector2(-2, -8), head + Vector2(2, -5), col(Color("a08010")), 1.0)
	else:   # קרחת עם תפרים
		z.draw_line(head + Vector2(-4, -6), head + Vector2(3, -7), col(Color("4a2a1a")), 1.0)
	if not z.dead:
		z.draw_circle(head + Vector2(4.0, -1.0), 1.4, Color(1.0, 0.8, 0.35))
	z.draw_line(head + Vector2(1, 4), head + Vector2(6, 4.5), col(Color("2a1a10")), 1.4)
	# אקדח מסמרים
	var hf := sh + Vector2(17, 6)
	z._arm(sh + Vector2(9, 2), hf, sk, vest)
	z.draw_rect(Rect2(hf + Vector2(-3, -4), Vector2(12, 6)), col(Color("c02020")))
	z.draw_rect(Rect2(hf + Vector2(-1, 1), Vector2(4, 6)), col(Color("2a2a2a")))
	if _left > 0 and not z.dead:
		Art.glow(z, hf + Vector2(11, -1), 5.0, Color(1.0, 0.9, 0.6, 0.6))
	end_draw()
	return true
