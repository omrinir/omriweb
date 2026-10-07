extends "res://enemies/zombie_type.gd"
# ============================================================
#  MIRAGE (שלב 17, "THE DRY RIVER") - "THEY LEARNED TO LIE".
#  זומבי מיובש מהשמש, עטוף בסמרטוטים בהירים וכיסוי ראש. הולך בתוך החום עם 2-3 העתקים (מיראז'ים).
#  הכלל (ככה מזהים את האמיתי): **רק לאמיתי יש צל** - צל ארוך וכהה שנופל על הקרקע (השמש מימין למעלה),
#    ואבק מתחת לרגליים. ההעתקים בלי צל, ורועדים קצת.
#   * העתק: קליע אחד מפוצץ אותו (בלי ניקוד, בלי דם, לא נספר כהריגה) - אבל חוזר תוך REGEN שניות,
#     אז אין טעם "לנקות" אותם: צריך למצוא את האמיתי. ההעתקים רצים קדימה וחוסמים קליעים.
#   * העתק שנוגע בך: נעלם, אבל אתה מסונוור מהחום (player.daze): חצי מהירות והכוונת רועדת.
#   * האמיתי (THEY LEARN): מחכה מאחורי ההעתקים במרחק שבו אתה בדרך כלל יורה (PlayerMemory.avg_distance),
#     וקופץ עליך (LUNGE) כשאתה טוען / מסונוור / כשנגמרו ההעתקים.
#     נפגע -> מתחלף במקום עם אחד ההעתקים (הבהוב, SWAP_CD) - צריך למצוא את הצל שוב.
#   * ההעתקים נוצרים רק כשאתה מתקרב (WAKE_DIST) - חוסך ביצועים. האמיתי מת -> כל ההעתקים שלו מתפוגגים.
#  בוס: enemies/types/mirage_king.gd (משתמש באותו קוד העתקים).
#  צלילים: "mr_pop" (העתק מתפוגג), "mr_hum" (זמזום חום כשנוצר העתק).
#  לשנות: COPIES, REGEN, HOLD, DAZE_T, SWAP_CD, LUNGE.
# ============================================================

const SOUNDS := {
	"mr_pop": [["W", 900, 1500, 0.0, 0.22, 0.0, 6.0, 0.35, 1.0, 0.0], ["N", 0, 0, 0.0, 0.18, 0.0, 9.0, 0.2, 0.6, 0]],
	"mr_hum": [["S", 180, 260, 0.0, 0.6, 0.15, 2.0, 0.25, 1.0, 0.05]],
}

const COPIES := [2, 2, 3]          # כמה העתקים (קל / רגיל / קשה)
const REGEN := 4.5                  # שניות עד שהעתק שהתפוצץ חוזר
const HOLD := Vector2(200.0, 420.0) # טווח המרחק שבו האמיתי מחכה מאחורי ההעתקים
const DAZE_T := 1.2                 # כמה זמן מסונוורים מנגיעה של העתק
const SWAP_CD := 5.0                # אחרי החלפת מקום - כמה זמן עד ההחלפה הבאה
const LUNGE := 1.7                  # מכפיל מהירות כשהוא קופץ עליך (אתה טוען / מסונוור)
const WAKE_DIST := 1150.0           # ההעתקים נוצרים כשאתה מתקרב
const SHADOW_COL := Color(0.16, 0.08, 0.02, 0.6)

static var _spawning_copy := false  # main._spawn_zombie -> setup() של העתק (לא מייצר העתקים משלו)

var is_copy := false
var master = null                    # העתק: הזומבי האמיתי
var copies: Array = []               # אמיתי: ההעתקים שלו
var _regen_t := 0.0
var _fade := 1.0                     # העתק: נכנס בהדרגה (0->1)
var _dust: Array = []                # אבק מהרגליים (רק לאמיתי): [מיקום מקומי, גיל]
var _dust_t := 0.0
var _seed := 0.0
var _spawned := false
var _swap_cd := 0.0


func stats() -> Dictionary:
	return {"name": "MIRAGE", "hp": 40, "walk": 55.0, "chase": 125.0, "damage": 1, "bite_delay": 0.75, "scale": 1.0, "width": 0.9,
		"duck": 0.1, "cover": 0.2, "skin": Color("c9b79c"), "shirt": Color("ddd0b4"), "pants": Color("8f7f68"), "shoe": Color("4a3a2a"),
		"points": 260}


func brain_overrides() -> Dictionary:
	return {"aggression": 0.9}


func setup() -> void:
	_seed = randf() * 100.0
	if _spawning_copy:
		is_copy = true
		_fade = 0.0
		z._mod_boss = false   # העתק של בוס הוא לא בוס (בר החיים ב-HUD רק לאמיתי)
		z.corpse_time = 0.1
		return
	_regen_t = 1.0


func _want_copies() -> int:
	return int(COPIES[clampi(Settings.difficulty, 0, 2)])


func _regen_time() -> float:
	return REGEN


func _spawn_copies(n: int) -> void:
	for i in n:
		_make_copy(z.global_position.x + (float(i) + 1.0) * randf_range(30.0, 55.0) * (1.0 if i % 2 == 0 else -1.0))


func _make_copy(x: float) -> void:
	if z.dead or not z.is_inside_tree():
		return
	var main: Node = z.get_parent()
	if main == null or not main.has_method("_spawn_zombie"):
		return
	_spawning_copy = true
	var c = main._spawn_zombie(x, z.global_position.y, z.kind)
	_spawning_copy = false
	if c == null:
		return
	c.global_position.y = z.global_position.y
	c.dormant = false
	c._dir = z._dir
	c.type_mod.master = z
	copies.append(c)
	Sfx.play("mr_hum", c.global_position, -10.0, 0.2, 2)


func _alive_copies() -> Array:
	copies = copies.filter(func(c): return c != null and is_instance_valid(c) and not c.is_queued_for_deletion())
	return copies


# ============================================================
#  העתק: מתפוגג
# ============================================================
func vanish() -> void:
	if not is_instance_valid(z) or z.is_queued_for_deletion():
		return
	Sfx.play("mr_pop", z.global_position, -2.0, 0.2, 4)
	var fx := Shimmer.new()
	fx.position = z.global_position
	fx.sc = z.sc
	fx.col = z.shirt
	z.get_parent().add_child(fx)
	z.remove_from_group("zombies")
	z.queue_free()


func on_damage(amount: int, _hit_pos: Vector2, _dir: Vector2, _src: Dictionary) -> bool:
	if is_copy:   # קליע עובר דרך אוויר רועד: רק "פופ"
		if not z.is_queued_for_deletion():
			z._popup("MIRAGE", Color(1.0, 0.95, 0.8, 0.8), 13, -70.0)
		vanish()
		return false
	if _swap_cd <= 0.0 and amount < z.hp:   # נפגע (ולא מת): מתחלף במקום עם העתק
		_swap_cd = SWAP_CD
		_swap_with_copy.call_deferred()
	return true


# מתחלף במקום עם אחד ההעתקים (הבהוב בשניהם)
func _swap_with_copy() -> void:
	var alive := _alive_copies()
	if alive.is_empty() or z.dead:
		return
	var c = alive[randi() % alive.size()]
	var a: Vector2 = z.global_position
	var b: Vector2 = c.global_position
	for p in [a, b]:
		var fx := Shimmer.new()
		fx.position = p
		fx.sc = z.sc
		fx.col = z.shirt
		z.get_parent().add_child(fx)
	z.global_position = b
	c.global_position = a
	var dd: float = c._dir
	c._dir = z._dir
	z._dir = dd
	Sfx.play("mr_hum", b, -2.0, 0.1, 2, 0.8)
	Sfx.play("mr_pop", a, -4.0, 0.1, 2, 0.7)


func can_bite() -> bool:
	return not is_copy


func on_death() -> void:
	if is_copy:
		return
	for c in _alive_copies():   # האמיתי מת: כל ההעתקים מתפוגגים
		c.type_mod.vanish()
	copies.clear()


# ============================================================
#  התנהגות
# ============================================================
func physics(pl: Node, delta: float) -> bool:
	if is_copy:
		_fade = minf(_fade + delta * 1.5, 1.0)
		if master == null or not is_instance_valid(master) or master.dead:
			vanish()
			return true
		if pl != null and not pl.dead and pl.global_position.distance_to(z.global_position + Vector2(0.0, -10.0)) < 30.0 * z.sc:
			if pl.has_method("daze") and pl.get("_invuln") != null and float(pl._invuln) <= 0.0:
				pl.daze(DAZE_T)   # הגיע אליך: אוויר חם בפנים - מסונוור
			vanish()
			return true
		return false
	# אמיתי: ההעתקים נוצרים כשאתה מתקרב, וחוזרים כל REGEN שניות
	_swap_cd = maxf(_swap_cd - delta, 0.0)
	if pl != null and not z.dead and absf(pl.global_position.x - z.global_position.x) < WAKE_DIST:
		if not _spawned:
			_spawned = true
			_spawn_copies(_want_copies())
		_regen_t -= delta
		if _alive_copies().size() < _want_copies() and _regen_t <= 0.0:
			_regen_t = _regen_time()
			_make_copy(z.global_position.x - z._dir * randf_range(30.0, 70.0))
	return false


func logic(pl: Node, d: Vector2, delta: float, speed: float) -> float:
	_update_dust(delta)
	if is_copy:
		return speed * 1.25   # ההעתקים רצים קדימה (מושכים את האש ומסנוורים)
	var alive := _alive_copies()
	if pl == null:
		return speed
	var dist := absf(d.x)
	var adapt: float = z.brain.adapt_k() if z.brain != null else 0.0
	# THEY LEARN: מחכה בדיוק מחוץ למרחק שבו אתה בדרך כלל יורה
	var hold: float = clampf(lerpf(260.0, PlayerMemory.avg_distance + 50.0, clampf(0.4 + adapt, 0.0, 1.0)), HOLD.x, HOLD.y)
	var exposed: bool = (pl.has_method("is_reloading") and pl.is_reloading()) or (pl.has_method("is_dazed") and pl.is_dazed())
	if exposed and dist < 360.0:
		return speed * LUNGE   # אתה טוען / מסונוור: קופץ עליך
	if alive.is_empty() or dist > hold + 160.0:
		return speed * 1.15   # אין מגן: מסתער
	if dist < hold - 30.0:
		return -speed * 0.6   # נסוג אל מאחורי ההעתקים
	return 0.0


func _update_dust(delta: float) -> void:
	if is_copy:
		return
	for p in _dust:
		p[1] += delta
	_dust = _dust.filter(func(p): return p[1] < 0.6)
	if z.is_on_floor() and absf(z.velocity.x) > 20.0:
		_dust_t -= delta * absf(z.velocity.x) / 60.0
		if _dust_t <= 0.0:
			_dust_t = 0.35
			_dust.append([Vector2(randf_range(-6.0, 6.0), -1.0), 0.0])


# ============================================================
#  ציור: גבוה ורזה, עור מיובש סדוק, סמרטוטים בהירים שמתנפנפים, כיסוי ראש עם צעיף מעל הפה,
#  עיניים חיוורות-זוהרות. העתק: בלי צל, בלי אבק, רועד ושקוף קצת ברגליים.
# ============================================================
func draw() -> bool:
	var a := 1.0
	if is_copy:
		a = _fade * (0.88 + 0.06 * sin(z._time * 9.0 + _seed))
	else:   # צל ארוך על הקרקע + אבק (הסימן לאמיתי)
		if z.is_on_floor() and not z.dead:
			_cast_shadow()
		for p in _dust:
			var k: float = p[1] / 0.6
			z.draw_circle(p[0] + Vector2(-z._dir * k * 10.0, -k * 6.0), 2.5 + k * 5.0, Color(0.85, 0.75, 0.58, 0.45 * (1.0 - k)))
	z.modulate.a = a
	if is_copy:   # אוויר רועד: כל הגוף זז קצת הצידה בגלים
		var wob := sin(z._time * 11.0 + _seed) * 1.2
		var s := Vector2(z._dir * z.wf * z.sc, z.sc)
		z.draw_set_transform(Vector2(wob, 0.0), sin(z._time * 7.0 + _seed) * 0.02, s)
	else:
		begin_draw(false)
	_body()
	_extras()
	end_draw()
	return true


func _extras() -> void:   # לבוס: כתר עצמות וכו'
	pass


# צל השמש: צללית של הגוף "מושכבת" על הקרקע ונמתחת שמאלה (השמש מימין למעלה).
# טרנספורם: נקודה בגובה y מעל הרגליים -> זזה שמאלה (0.85*y) ויורדת אל פס הקרקע (0.24*y)
func _cast_shadow() -> void:
	var sc: float = z.sc
	z.draw_set_transform_matrix(Transform2D(Vector2(z.wf * sc, 0.0), Vector2(0.85 * sc, -0.24 * sc), Vector2(0.0, 1.0)))
	var c := SHADOW_COL
	z.draw_colored_polygon(Art.ellipse(Vector2(0.0, -2.0), 9.0, 3.0, 0.0, 10), c)
	z.draw_line(Vector2(-3.0, 0.0), Vector2(-1.0, -25.0), c, 4.5)   # רגליים
	z.draw_line(Vector2(3.0, 0.0), Vector2(1.0, -25.0), c, 4.5)
	z.draw_colored_polygon(Art.ellipse(Vector2(0.0, -35.0), 8.0, 12.0, 0.0, 12), c)   # גוף
	z.draw_circle(Vector2(3.0, -52.0), 7.0, c)   # ראש
	z.draw_line(Vector2(-6.0, -40.0), Vector2(-9.0, -26.0), c, 3.5)   # ידיים
	z.draw_line(Vector2(6.0, -40.0), Vector2(10.0, -27.0), c, 3.5)
	z.draw_set_transform_matrix(Transform2D.IDENTITY)


func _body() -> void:
	var sk := col(z.skin)
	var sk2 := col(Art.shade(z.skin, 0.25))
	var rag := col(z.shirt)
	var rag2 := col(Art.shade(z.shirt, 0.22))
	var pa := col(z.pants)
	var p: float = z._walk_phase
	var f: Array = feet(6.0, 3.5)
	var hip := Vector2(-1.0, -25.0 + absf(sin(p)) * 1.2)
	var sh := Vector2(3.0, -43.0 + absf(sin(p)) * 0.8)
	var head := sh + Vector2(3.5, -9.0)
	var wind := sin(z._time * 3.0 + _seed) * 2.0
	# רגליים: מכנסיים דהויים קרועים מתחת לברך, רגליים יחפות מיובשות
	z._leg(hip + Vector2(-1.5, 0.0), f[1], Art.shade(pa, 0.2), sk2, Color(0, 0, 0, 0))
	z._leg(hip + Vector2(1.5, 0.0), f[0], pa, sk, Color(0, 0, 0, 0))
	# יד אחורית
	var bh := sh + Vector2(-5.0 + sin(p) * 6.0, 15.0)
	var fh := sh + Vector2(8.0 - sin(p) * 6.0, 14.0)
	if z._bite_anim > 0.0:
		bh = sh + Vector2(16.0, 0.0)
		fh = sh + Vector2(18.0, 3.0)
	z._arm(sh + Vector2(-2.0, 1.0), bh, sk2, rag2)
	# גוף: גלימת סמרטוטים ארוכה עם שוליים קרועים שמתנפנפים
	var robe := PackedVector2Array([sh + Vector2(-7.5, -1.0), sh + Vector2(6.5, 0.0), hip + Vector2(6.0, 4.0),
		hip + Vector2(5.0 - wind * 0.3, 11.0), hip + Vector2(1.0, 8.0), hip + Vector2(-2.5 - wind * 0.5, 12.5), hip + Vector2(-6.5 - wind, 9.0), hip + Vector2(-7.0, 2.0)])
	Art.fill_shaded(z, robe, rag, 0.12, 0.35, Art.OUTLINE, 1.2)
	z.draw_line(sh + Vector2(-1.0, 2.0), hip + Vector2(0.0, 4.0), col(Art.shade(z.shirt, 0.3)), 1.0)   # קפל
	z.draw_line(hip + Vector2(-6.5, 0.5), hip + Vector2(6.0, 1.5), col(Color("6a5238")), 1.6)   # חבל במותן
	for i in 3:   # טלאים וכתמי זיעה/חול
		Art.oval(z, sh.lerp(hip, 0.3 + 0.2 * float(i)) + Vector2(-2.0 + float(i) * 2.5, 2.0), 2.2, 1.4, Color(0.55, 0.45, 0.3, 0.25), 0.3, Art.NONE)
	# צוואר וראש עטוף
	Art.limb(z, PackedVector2Array([sh + Vector2(1.5, 0.0), head + Vector2(-0.5, 5.0)]), 3.0, sk2)
	var wrap := rag.lerp(col(Color("e8dcc0")), 0.3)
	Art.oval(z, head + Vector2(-1.5, -1.0), 8.0, 8.4, wrap, 0.1)   # כיסוי ראש
	Art.oval_shaded(z, head + Vector2(1.5, 0.5), 5.4, 5.6, sk, 0.0, Art.OUTLINE, 1.0)   # פנים
	z.draw_colored_polygon(PackedVector2Array([head + Vector2(-2.0, 1.5), head + Vector2(7.0, 1.0), head + Vector2(6.0, 6.5), head + Vector2(-1.0, 7.0)]), wrap)   # צעיף על הפה
	var tail := PackedVector2Array([head + Vector2(-7.0, -1.0), head + Vector2(-13.0 - wind, 4.0), head + Vector2(-16.0 - wind * 1.6, 10.0 + wind * 0.5)])
	Art.limb(z, tail, 2.6, wrap)   # קצה הצעיף מתנופף מאחור
	z.draw_line(head + Vector2(0.5, -1.5), head + Vector2(5.5, -1.5), col(Color("6a5238")), 1.0)   # קו כיסוי מעל העיניים
	for e in 2:   # עיניים חיוורות זוהרות
		var ep := head + Vector2(2.5 + float(e) * 2.8, 0.0)
		Art.glow(z, ep, 3.0, Color(0.9, 0.95, 1.0, 0.35))
		z.draw_circle(ep, 0.9, Color(0.95, 0.97, 1.0))
	z.draw_line(head + Vector2(3.0, -5.0), head + Vector2(4.5, -3.0), Color(0.3, 0.2, 0.1, 0.5), 0.6)   # סדק בעור
	# יד קדמית: אצבעות ארוכות ויבשות
	z._arm(sh + Vector2(2.0, 1.0), fh, sk, rag)
	for i in 3:
		z.draw_line(fh, fh + Vector2.from_angle(0.5 + float(i) * 0.4) * 3.5, sk2, 0.8)


# ============================================================
#  הבהוב ההיעלמות: גלי אוויר שקופים שמתפזרים (בלי דם)
# ============================================================
class Shimmer extends Node2D:
	var sc := 1.0
	var col := Color.WHITE
	var t := 0.0

	func _ready() -> void:
		z_index = 3

	func _process(delta: float) -> void:
		t += delta
		if t > 0.55:
			queue_free()
			return
		queue_redraw()

	func _draw() -> void:
		var k := t / 0.55
		for i in 5:
			var y := (-8.0 - float(i) * 10.0) * sc
			var w := (10.0 + k * 22.0) * sc
			var off := sin(t * 30.0 + float(i) * 1.7) * 4.0 * k
			draw_line(Vector2(-w + off, y), Vector2(w + off, y), Color(col, 0.55 * (1.0 - k)), 2.0)
		for i in 7:
			var a := float(i) / 7.0 * TAU
			draw_circle(Vector2(cos(a) * k * 20.0 * sc, -24.0 * sc + sin(a) * k * 26.0 * sc), 2.0 * (1.0 - k) + 0.5, Color(1.0, 0.98, 0.9, 0.6 * (1.0 - k)))
