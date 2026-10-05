extends "res://enemies/zombie_type.gd"
# ============================================================
#  DEVOURER (שלב 11, צפון-מזרח) - בולע זומבים אחרים וגדל.
#  צללית: שפוף ונפוח, בטן ענקית עם פה אנכי (שתי שורות שיניים), עור סגלגל-ירקרק עם ורידים.
#  התנהגות:
#    * כשיש זומבי "רגיל" קרוב (SEEK_RANGE) והשחקן לא ממש עליו - הולך אליו.
#    * צמוד אליו (REACH) -> הבטן נפתחת, לשונות תופסות את הזומבי ומושכות אותו פנימה (ABSORB_T).
#      הזומבי הנבלע מתכווץ ונעלם. ה-DEVOURER גדל: גוף גדול יותר, יותר חיים, יותר נזק, קצת יותר איטי.
#    * עד MAX_STACKS בליעות. כל בליעה = שלב גדילה (רואים את זה: גודל + ורידים זוהרים).
#  מענה של השחקן: לירות בו בזמן הבליעה (DISRUPT נזק) -> הבליעה נקטעת והזומבי השני משתחרר.
#  בוס (ליד היציאה): "THE GLUTTON" - מתחיל גדול, ובולע את הזומבים שמסביבו.
#  צלילים: "dv_open" (הבטן נפתחת), "dv_gulp" (בליעה), "dv_belch" (גדל).
#  לשנות: SEEK_RANGE, REACH, ABSORB_T, MAX_STACKS, GROW.
# ============================================================

const Registry := preload("res://enemies/zombie_registry.gd")

const SOUNDS := {
	"dv_open": [["N", 0, 0, 0.0, 0.5, 0.05, 4.0, 0.5, 0.2, 0], ["S", 90, 60, 0.0, 0.5, 0.05, 4.0, 0.4, 1.0, 0.3]],
	"dv_gulp": [["S", 160, 50, 0.0, 0.35, 0.0, 6.0, 0.8, 1.0, 0], ["N", 0, 0, 0.0, 0.3, 0.0, 8.0, 0.5, 0.25, 0]],
	"dv_belch": [["W", 70, 55, 0.0, 0.6, 0.05, 3.0, 0.45, 0.25, 0.5], ["N", 0, 0, 0.0, 0.5, 0.05, 4.0, 0.3, 0.15, 0]],
}

const SEEK_RANGE := 300.0
const REACH := 46.0
const ABSORB_T := 1.3
const MAX_STACKS := 3
const GROW := 0.14            # כמה גדל בכל בליעה
const DISRUPT := 14           # כמה נזק בזמן בליעה קוטע אותה
const EDIBLE := [0, 1, 2, 3, 4, 9, 14, 16]   # סוגים רגילים שאפשר לבלוע (+ SCOUT, SPLITJAW)

var stacks := 0
var absorbs := 0              # לבדיקות
var _prey: Node2D = null
var _abs_t := 0.0
var _abs_dmg := 0
var _cd := 1.5
var _grow_fx := 0.0
var _prey_from := Vector2.ZERO


func _boss() -> bool:
	return z != null and float(z.chase_range) > 600.0


func stats() -> Dictionary:
	if _boss():
		return {"name": "DEVOURER", "hp": 150, "walk": 30.0, "chase": 62.0, "damage": 2, "bite_delay": 1.2, "scale": 1.35, "width": 1.4,
			"duck": 0.0, "cover": 0.0, "skin": Color("8a9070"), "shirt": Color("5a3a4a"), "pants": Color("3a3030"), "shoe": Color("1a1616"),
			"points": 700, "boss": true, "boss_name": "THE GLUTTON"}
	return {"name": "DEVOURER", "hp": 42, "walk": 38.0, "chase": 78.0, "damage": 1, "bite_delay": 1.0, "scale": 1.05, "width": 1.25,
		"duck": 0.0, "cover": 0.1, "skin": Color("8a9878"), "shirt": Color("6a4a5a"), "pants": Color("3a3634"), "shoe": Color("1a1616"), "points": 380}


func brain_overrides() -> Dictionary:
	return {"aggression": 0.1}


func can_bite() -> bool:
	return _prey == null


func _edible(o: Node) -> bool:
	if o == z or o.dead or o.is_boss() or (not o.is_on_floor() and not o.dormant):   # גם זומבי ישן = ארוחה קלה
		return false
	if o.type_mod != null:
		return o.kind == Registry.SCOUT or o.kind == Registry.SPLITJAW
	return o.kind in EDIBLE


# רץ בכל פריים (גם כשהוא לא רודף אחרי השחקן): מחפש זומבי לבלוע, או בולע עכשיו
func physics(pl: Node, delta: float) -> bool:
	_cd -= delta
	_grow_fx = maxf(_grow_fx - delta, 0.0)
	if _prey != null:
		_absorb_tick(delta)
		_hold(delta, 0.0)
		return true
	if stacks >= MAX_STACKS or _cd > 0.0 or not z.is_on_floor():
		return false
	var best: Node2D = null
	var bd := SEEK_RANGE
	for o in z.get_tree().get_nodes_in_group("zombies"):
		if not _edible(o):
			continue
		var dist: float = o.global_position.distance_to(z.global_position)
		if dist < bd and absf(o.global_position.y - z.global_position.y) < 30.0:
			bd = dist
			best = o
	if best == null:
		return false
	if pl != null and not pl.dead and pl.global_position.distance_to(z.global_position) < minf(bd, 110.0):   # השחקן קרוב יותר מהטרף - נלחם בו
		return false
	z._dir = signf(best.global_position.x - z.global_position.x) if best.global_position.x != z.global_position.x else z._dir
	if bd < REACH:
		_start(best)
		_hold(delta, 0.0)
	else:
		_hold(delta, z.chase_speed * 0.85)
	return true


# תנועה ידנית (כשהוא בדרך לטרף / בולע)
func _hold(delta: float, speed: float) -> void:
	if not z.is_on_floor():
		z.velocity.y += z.gravity * delta
	z.velocity.x = move_toward(z.velocity.x, z._dir * speed, 600.0 * delta)
	z.move_and_slide()
	if z.is_on_floor():
		z._walk_phase += delta * absf(z.velocity.x) * 0.075 / z.sc


func _start(o: Node2D) -> void:
	_prey = o
	_abs_t = 0.0
	_abs_dmg = 0
	_prey_from = o.global_position
	o.stagger(ABSORB_T + 0.5)   # הנבלע לא תוקף ולא זז בעצמו
	Sfx.play("dv_open", z.global_position, 2.0, 0.1, 3)
	if Art.on_screen(z, z.global_position):
		z._popup("DEVOUR!", Color("c070ff"), 16, -95.0 * z.sc)


func _absorb_tick(delta: float) -> void:
	if not is_instance_valid(_prey) or _prey.dead:
		_prey = null
		return
	_abs_t += delta
	var k := clampf(_abs_t / ABSORB_T, 0.0, 1.0)
	var mouth: Vector2 = z.global_position + Vector2(z._dir * 10.0 * z.wf * z.sc, -4.0)
	_prey.global_position = _prey_from.lerp(mouth, k * k)
	_prey.velocity = Vector2.ZERO
	_prey.scale = Vector2.ONE * (1.0 - 0.85 * k * k)
	if k >= 1.0:
		_finish()


func _finish() -> void:
	var gain: int = maxi(int(_prey.hp), 15)
	var sd := director()
	if sd != null:
		sd.on_death(_prey)
	_prey.remove_from_group("zombies")
	_prey.queue_free()
	_prey = null
	stacks += 1
	absorbs += 1
	_cd = randf_range(2.0, 3.5)
	_grow(gain)
	Sfx.play("dv_gulp", z.global_position, 3.0, 0.1, 3)
	Sfx.play("dv_belch", z.global_position, 0.0, 0.1, 2)


# גדל: גוף, אזור פגיעה, חיים, נזק, מהירות
func _grow(gain: int) -> void:
	z.sc *= 1.0 + GROW
	z.wf *= 1.0 + GROW * 0.8
	var add := int(float(gain) * 0.7)
	z.max_hp += add
	z.hp += add
	if stacks == 2:
		z.damage += 1
	z.chase_speed *= 0.93
	z.walk_speed *= 0.93
	var r := z._shape.shape as RectangleShape2D
	r.size = Vector2(38.0 * z.wf, 66.0 * z.sc)
	z._shape.position = Vector2(0.0, -33.0 * z.sc)
	_grow_fx = 0.8
	if Art.on_screen(z, z.global_position):
		z._popup("GROWS x%d" % stacks, Color("c070ff"), 18, -100.0 * z.sc)
		var cam: Node = z.get_viewport().get_camera_2d()
		if cam != null and cam.has_method("shake"):
			cam.shake(5.0, 0.25)


# נפגע בזמן בליעה: מספיק נזק = הבליעה נקטעת
func on_damage(amount: int, _hit_pos: Vector2, _dir: Vector2, _src: Dictionary) -> bool:
	if _prey != null:
		_abs_dmg += maxi(amount, 8)
		if _abs_dmg >= DISRUPT:
			_release()
	return true


func _release() -> void:
	if is_instance_valid(_prey):
		_prey.scale = Vector2.ONE
		_prey._stagger_t = 0.4
	_prey = null
	_cd = 3.0
	Sfx.play("dv_gulp", z.global_position, -4.0, 0.3, 2)
	if Art.on_screen(z, z.global_position):
		z._popup("SPAT OUT", Color("ffd34a"), 15, -95.0 * z.sc)


func on_death() -> void:
	if _prey != null:
		_release()


# ============================================================
#  ציור
# ============================================================
func draw() -> bool:
	begin_draw()
	var sk := col(z.skin)
	var shirt := col(z.shirt)
	var p: float = z._walk_phase
	var f: Array = feet(4.0, 2.0)
	var t: float = z._time
	var open := 0.0
	if _prey != null:
		open = clampf(_abs_t / 0.3, 0.0, 1.0)
	var swell := 1.0 + 0.04 * sin(t * 2.5) + 0.12 * _grow_fx
	var hip := Vector2(0.0, -20.0 + absf(sin(p)) * 1.0)
	var sh := Vector2(4.0, -38.0)
	var head := sh + Vector2(9.0, 1.0)   # ראש נמוך, קדימה
	z._leg(hip + Vector2(-3, 0), f[1], col(Art.shade(z.pants, 0.25)), col(Art.shade(z.skin, 0.2)), col(z.shoe))
	z._leg(hip + Vector2(3, 0), f[0], col(z.pants), sk, col(z.shoe))
	z._arm(sh + Vector2(-4, 3), sh + Vector2(-4.0 - sin(p) * 3.0, 18.0), col(Art.shade(z.skin, 0.25)), col(Art.shade(z.shirt, 0.3)))
	z._arm(sh + Vector2(3, 3), sh + Vector2(6.0, 18.0 + sin(p) * 2.0), col(Art.shade(z.skin, 0.1)), shirt)   # יד קדמית - מאחורי הבטן
	# בטן נפוחה
	var belly := (sh + hip) * 0.5 + Vector2(4.0, 2.0)
	Art.oval_shaded(z, belly, 13.0 * swell, 14.0 * swell, sk, 0.0)
	Art.fill(z, PackedVector2Array([sh + Vector2(-7, -3), sh + Vector2(7, -2), belly + Vector2(2, -10), belly + Vector2(-10, -6)]), shirt, Art.OUTLINE, 1.2)   # שאריות חולצה
	# ורידים (זוהרים יותר לפי כמה בלע)
	var vg := 0.25 + 0.2 * float(stacks) + 0.4 * _grow_fx
	for i in 3:
		var a := -0.6 + float(i) * 0.6
		var v0 := belly + Vector2(cos(a), sin(a)) * 4.0
		z.draw_polyline(PackedVector2Array([v0, v0 + Vector2(cos(a) * 6.0, sin(a) * 4.0 - 2.0), v0 + Vector2(cos(a) * 10.0, sin(a) * 9.0)]), Color(0.75, 0.35, 1.0, vg), 1.2)
	# הפה האנכי בבטן
	var mh := 11.0 * swell
	var mw := 2.5 + open * 7.0
	var mc := belly + Vector2(5.0, 1.0)
	Art.fill(z, PackedVector2Array([mc + Vector2(-1, -mh - 1.5), mc + Vector2(mw + 2.0, -mh * 0.4), mc + Vector2(mw + 2.0, mh * 0.4), mc + Vector2(-1, mh + 1.5), mc + Vector2(-mw * 0.6 - 2.0, 0)]), col(Color("7a2a3a")), Art.NONE)   # שפתיים
	Art.fill(z, PackedVector2Array([mc + Vector2(0, -mh), mc + Vector2(mw, -mh * 0.4), mc + Vector2(mw, mh * 0.4), mc + Vector2(0, mh), mc + Vector2(-mw * 0.6, 0)]), col(Color("2a0410")), Art.OUTLINE, 1.0)
	for i in 5:   # שיניים משני הצדדים
		var y := -mh * 0.75 + float(i) * mh * 0.38
		z.draw_colored_polygon(PackedVector2Array([mc + Vector2(-mw * 0.4, y - 1.2), mc + Vector2(-mw * 0.4, y + 1.2), mc + Vector2(-mw * 0.4 + 2.5, y)]), col(Color("e8dcc0")))
		z.draw_colored_polygon(PackedVector2Array([mc + Vector2(mw, y - 1.2), mc + Vector2(mw, y + 1.2), mc + Vector2(mw - 2.5, y)]), col(Color("e8dcc0")))
	if _prey != null and is_instance_valid(_prey):   # לשונות שתופסות את הנבלע
		var tp: Vector2 = z.to_local(_prey.global_position + Vector2(0.0, -24.0 * _prey.scale.y))
		tp = Vector2(tp.x * z._dir / (z.wf * z.sc), tp.y / z.sc)
		for i in 3:
			var off := Vector2(0.0, -5.0 + float(i) * 5.0)
			var mid := (mc + tp) * 0.5 + Vector2(0.0, sin(t * 12.0 + float(i)) * 4.0 - 6.0)
			var pts := PackedVector2Array()
			for q in 7:
				var u := float(q) / 6.0
				pts.append(mc.lerp(mid, u).lerp(mid.lerp(tp + off, u), u))
			z.draw_polyline(pts, col(Color("b04a6a")), 2.2 - float(i) * 0.4)
	# ראש קטן ושמוט
	Art.oval_shaded(z, head, 5.5, 5.8, sk, 0.1)
	z.draw_circle(head + Vector2(2.5, -1.0), 1.2, Color(0.85, 0.5, 1.0) if not z.dead else Color("2a2a2a"))
	z.draw_line(head + Vector2(1, 3), head + Vector2(5, 3.5), col(Color("2a0a10")), 1.2)
	end_draw()
	return true
