extends "res://enemies/zombie_type.gd"
# ============================================================
#  COMMANDER (שלב 9) - הזומבי הכי חכם מבין הרגילים. לא נלחם - מפקד.
#  צללית: גבוה וזקוף (היחיד שעומד ישר!), מעיל צבאי ארוך עם כותפות זהב,
#    כובע קצינים, סרט זרוע אדום, מכשיר קשר על הגב עם אנטנה ונורה מהבהבת.
#    כשהוא נותן פקודה - מרים יד עם זיקוק בצבע הפקודה.
#  תנועה: נשאר מאחורי החיילים שלו (~300 פיקסלים מהשחקן), נסוג כשמתקרבים אליו.
#  התקפה: מכת אלה חלשה, רק כשנלכד.
#  פקודות (director().command) לפי המצב + PlayerMemory:
#    מעט חברים בסביבה          -> HOLD + קורא לתגבורת מרחוק
#    השחקן טוען / פגיע           -> ATTACK (כולם פנימה)
#    השחקן אוהב רימונים / צפיפות -> RETREAT (ומתפזרים - כל אחד עוצר בזמן אחר)
#    השחקן "מחנה" במקום אחד      -> FLANK
#    השחקן מתקרב לצוואר בקבוק     -> AMBUSH (חור בכביש, סולם, אש על הכביש)
#    אחרת: השחקן מסתכל עליהם -> FLANK, השחקן מסתכל הצידה -> ATTACK
#  רשום כמנהיג (register_leader): הורגים אותו -> כל מי שסביבו מבולבל.
#  צלילים: שריקה ("cmd_whistle"), צעקת פקודה ("cmd_bark"), קשר ("cmd_radio").
#  איך משנים: RADIUS (טווח פקודה), SECS (כמה זמן כל פקודה), _cmd_cd (קצב).
# ============================================================

const S9Fx := preload("res://effects/s9_fx.gd")
const Brain := preload("res://ai/zombie_brain.gd")

const SOUNDS := {
	"cmd_whistle": [["S", 2900, 3150, 0.0, 0.22, 0.01, 3.0, 0.32, 1.0, 0.015], ["S", 3100, 2350, 0.26, 0.34, 0.01, 4.0, 0.32, 1.0, 0.02], ["N", 0, 0, 0.0, 0.6, 0.02, 5.0, 0.05, 1.0, 0, 0.6]],
	"cmd_bark": {"drive": 3.0, "layers": [["V", 140, 112, 0.0, 0.3, 0.01, 6.0, 1.0, 1.0, 0.03, 0, [650, 1100, 70]], ["V", 150, 98, 0.36, 0.42, 0.01, 4.5, 1.0, 1.0, 0.03, 0, [600, 980, 60]]]},
	"cmd_radio": [["C", 0, 0, 0.0, 0.55, 0.0, 3.0, 0.9, 1.0, 0], ["N", 0, 0, 0.0, 0.55, 0.0, 4.0, 0.22, 0.6, 0, 0.4], ["Q", 1250, 1250, 0.05, 0.06, 0.0, 30.0, 0.14, 0.5, 0], ["Q", 880, 880, 0.16, 0.08, 0.0, 30.0, 0.14, 0.5, 0]],
}

const RADIUS := 480.0
const SECS := {"ATTACK": 3.0, "RETREAT": 2.2, "FLANK": 4.5, "HOLD": 3.5, "AMBUSH": 6.0}
const CMD_COLORS := {"ATTACK": Color(1.0, 0.3, 0.2), "RETREAT": Color(0.92, 0.92, 1.0), "FLANK": Color(0.4, 0.75, 1.0), "HOLD": Color(1.0, 0.85, 0.3), "AMBUSH": Color(0.78, 0.45, 1.0)}

var history := []          # כל הפקודות שנתן (לבדיקות / דיבאג)
var last_reason := ""
var _cmd_cd := 2.0
var _cmd_anim := 0.0
var _flare := Color(1.0, 0.3, 0.2)
var _reinforce_cd := 0.0
var _swing := 0.0
var _led := 0.0


func stats() -> Dictionary:
	return {"name": "COMMANDER", "hp": 45, "walk": 50.0, "chase": 105.0, "damage": 1, "bite_delay": 1.0, "scale": 1.1, "width": 0.95,
		"duck": 0.5, "cover": 0.6, "skin": Color("8e958a"), "shirt": Color("4a4a30"), "pants": Color("2c2c22"), "shoe": Color("121210"), "points": 450}


func brain_overrides() -> Dictionary:
	return {"keep_range": 300.0, "aggression": -0.4, "communication": 1, "retreat_probability": 0.3, "awareness": 0.15}


func use_brain_movement() -> bool:
	return false   # המוח רק רואה - הוא זז לבד (מאחורי החיילים)


func setup() -> void:
	var dr := director()
	if dr != null:
		dr.register_leader(z, RADIUS, 0.25)


func logic(pl: Node, d: Vector2, delta: float, speed: float) -> float:
	_cmd_cd -= delta
	_cmd_anim -= delta
	_reinforce_cd -= delta
	_swing -= delta
	_led += delta * (9.0 if _cmd_anim > 0.0 else 2.5)
	# לא תופס "תור התקפה" - הוא לא תוקף
	if z.brain != null and z.brain.role == Brain.ATTACK:
		var dr := director()
		if dr != null:
			dr.release_slot(z)
		z.brain.role = Brain.HOLD
	if _cmd_cd <= 0.0 and z.brain != null and z.brain.tracking():
		var cmd := decide(pl)
		if cmd != "":
			issue(cmd)
	# תנועה: נשאר מאחורי החיילים
	var dist := absf(d.x)
	var face: float = signf(d.x) if d.x != 0.0 else z._dir
	var want := 300.0 if _allies_between(pl) > 0 else 380.0
	z._dir = face
	if dist < 60.0:   # נלכד: מכה עם האלה
		return speed * 0.4
	if dist < want - 70.0:
		z._dir = -face
		return speed * 0.85
	if dist > want + 70.0:
		return speed * 0.7
	return 0.0


# ---- ההחלטה: איזו פקודה מתאימה למצב ----
func decide(pl: Node) -> String:
	var allies := _allies(RADIUS)
	if allies.size() < 2:
		_call_reinforcements(pl)
		last_reason = "few allies"
		return "HOLD"
	if pl.is_vulnerable() or pl.is_reloading():
		last_reason = "player vulnerable"
		return "ATTACK"
	if PlayerMemory.explosives > 0.35 or _clustered(allies):
		last_reason = "explosives / clustering"
		return "RETREAT"
	if PlayerMemory.is_camping():
		last_reason = "player camping"
		return "FLANK"
	if _choke_ahead(pl):
		last_reason = "choke point ahead"
		return "AMBUSH"
	var squad_side := signf(z.global_position.x - pl.global_position.x)
	if pl._face() == squad_side:
		last_reason = "player faces squad"
		return "FLANK"
	last_reason = "player looks away"
	return "ATTACK"


func issue(cmd: String) -> void:
	var dr := director()
	if dr == null:
		return
	var allies := _allies(RADIUS)
	if cmd == "AMBUSH":   # מארב חדש: כל אחד מחכה מהצד שלו
		for o in allies:
			o.brain._ambush_side = 0.0
	dr.command(z, cmd, RADIUS, float(SECS[cmd]))
	if cmd == "RETREAT":   # מתפזרים: כל אחד מפסיק לסגת בזמן אחר
		for i in allies.size():
			allies[i].brain.command(Brain.RETREAT, 1.0 + 0.45 * float(i))
	history.append(cmd)
	_cmd_anim = 1.1
	_flare = CMD_COLORS[cmd]
	_cmd_cd = randf_range(2.2, 3.0) if cmd == "ATTACK" else randf_range(4.0, 5.5)
	Sfx.play("cmd_whistle", z.global_position, -2.0, 0.08, 2)
	Sfx.play("cmd_bark", z.global_position, 0.0, 0.1, 2)
	var fx := S9Fx.OrderLinks.new()
	fx.from_z = z
	fx.targets = allies
	fx.color = _flare
	z.get_parent().add_child(fx)
	fx.global_position = Vector2.ZERO


# זומבים שיכולים לקבל פקודה (עם מוח שמזיז אותם) בטווח
func _allies(radius: float) -> Array:
	var out := []
	for o in z.get_tree().get_nodes_in_group("zombies"):
		if o == z or o.dead or o.brain == null or not o.brain.steer_movement:
			continue
		if o.global_position.distance_to(z.global_position) < radius:
			out.append(o)
	return out


# כמה חברים עומדים בין המפקד לשחקן (הוא מסתתר מאחוריהם)
func _allies_between(pl: Node) -> int:
	var px: float = pl.global_position.x
	var zx: float = z.global_position.x
	var n := 0
	for o in z.get_tree().get_nodes_in_group("zombies"):
		if o == z or o.dead:
			continue
		var ox: float = o.global_position.x
		if (ox - px) * (zx - ox) > 0.0 and absf(o.global_position.y - z.global_position.y) < 60.0:
			n += 1
	return n


# צפיפות: 3 זומבים או יותר באותו מקום = מטרה לרימון
func _clustered(allies: Array) -> bool:
	for a in allies:
		var n := 0
		for b in allies:
			if a != b and a.global_position.distance_to(b.global_position) < 60.0:
				n += 1
		if n >= 2:
			return true
	return false


# השחקן הולך לכיוון "צוואר בקבוק" (חור בכביש, סולם, אש) שנמצא בינו לבין החוליה
func _choke_ahead(pl: Node) -> bool:
	var vx: float = pl.velocity.x
	if absf(vx) < 60.0:
		return false
	var heading := signf(vx)
	var px: float = pl.global_position.x
	if signf(z.global_position.x - px) != heading:   # הולך הפוך מהחוליה
		return false
	var spots := []
	for c in z.get_tree().get_nodes_in_group("s9_choke"):
		spots.append((c as Node2D).global_position.x)
	for h in z.get_tree().get_nodes_in_group("hazards"):
		var r: Rect2 = h.world_rect()
		if r.size.x > 40.0 and absf(r.end.y - pl.global_position.y) < 30.0:
			spots.append(r.get_center().x)
	for cx in spots:
		var ahead: float = (float(cx) - px) * heading
		if ahead > 40.0 and ahead < 400.0 and (z.global_position.x - float(cx)) * heading > 0.0:
			return true
	return false


# תגבורת: כל הזומבים עד 900 פיקסלים "שומעים" את הקשר ומגיעים
func _call_reinforcements(_pl: Node) -> void:
	if _reinforce_cd > 0.0:
		return
	_reinforce_cd = 8.0
	var dr := director()
	var n := 0
	for o in z.get_tree().get_nodes_in_group("zombies"):
		if o == z or o.dead or o.brain == null:
			continue
		var dd: float = o.global_position.distance_to(z.global_position)
		if dd < 900.0:
			o.brain.hear_call(z.global_position, 0.3 + dd / 900.0)
			o._alert_t = maxf(o._alert_t, 6.0)
			n += 1
	Sfx.play("cmd_radio", z.global_position, -1.0, 0.1, 2)
	if dr != null:
		dr.calls_made += 1
		dr._signal(z.global_position + Vector2(0, -100.0 * z.sc), "REINFORCE", Color(1.0, 0.85, 0.3))


func on_bite(_player: Node) -> void:
	_swing = 0.3


func on_death() -> void:
	Sfx.play("cmd_radio", z.global_position, 2.0, 0.05, 2)
	z._popup("NO ORDERS", Color(0.7, 0.8, 1.0), 16, -110.0)
	z._drop(2)   # SUPPLY: פרס על הריגת המפקד


# ============================================================
#  ציור
# ============================================================
func draw() -> bool:
	begin_draw()
	var sk := col(z.skin)
	var coat := col(z.shirt)
	var coat_d := col(Art.shade(z.shirt, 0.3))
	var gold := col(Color("c8a040"))
	var red := col(Color("b0201c"))
	var p: float = z._walk_phase
	var f: Array = feet(4.5, 2.5)
	var hip := Vector2(0.0, -24.0 + absf(sin(p)) * 0.8)
	var sh := Vector2(1.0, -42.0)
	var head := sh + Vector2(2.0, -8.5)
	# מכשיר קשר על הגב + אנטנה מתנדנדת
	var box := PackedVector2Array([sh + Vector2(-13, -2), sh + Vector2(-5, -3), sh + Vector2(-5, 13), sh + Vector2(-13, 12)])
	Art.fill_shaded(z, box, col(Color("3a3e30")), 0.15, 0.35)
	z.draw_rect(Rect2(sh + Vector2(-11.5, 2), Vector2(4, 2)), col(Color("1a1a14")))
	var sway := sin(z._time * 2.2) * 3.0
	var tip := sh + Vector2(-14.0 + sway, -30.0)
	z.draw_line(sh + Vector2(-11, -2), tip, col(Color("1c1c1c")), 1.2, true)
	var on := fmod(_led, 1.0) < 0.5
	if on:
		Art.glow(z, tip, 5.0, Color(1.0, 0.15, 0.1, 0.8))
	z.draw_circle(tip, 1.4, Color(1.0, 0.2, 0.15) if on else Color(0.3, 0.05, 0.05))
	# רגליים: מגפיים גבוהים
	z._leg(hip + Vector2(-1.5, 0), f[1], col(Art.shade(z.pants, 0.25)), col(Color("141410")), col(z.shoe))
	# יד אחורית עם סרט זרוע אדום
	var bh := sh + Vector2(-5.0, 17.0 + sin(p) * 2.0)
	z._arm(sh + Vector2(-3, 1), bh, coat_d, coat_d)
	var band := sh.lerp(bh, 0.3) + Vector2(-2.0, 0.0)
	Art.fill(z, PackedVector2Array([band + Vector2(-3, -2), band + Vector2(3, -2), band + Vector2(3, 2), band + Vector2(-3, 2)]), red, Art.OUTLINE, 0.8)
	z._leg(hip + Vector2(1.5, 0), f[0], col(z.pants), col(Color("141410")), col(z.shoe))
	# מעיל ארוך שמתנופף עד הברכיים
	var flap := sin(p) * 2.0
	var coat_pts := PackedVector2Array([sh + Vector2(-8, -1), sh + Vector2(8, 0), hip + Vector2(8, 2), hip + Vector2(10 + flap, 14), hip + Vector2(3, 15), hip + Vector2(-2, 12),
		hip + Vector2(-8, 15), hip + Vector2(-11 - flap, 13), hip + Vector2(-8, 1)])
	Art.fill_shaded(z, coat_pts, coat, 0.15, 0.35, Art.OUTLINE, 1.4)
	z.draw_line(sh + Vector2(2, 1), hip + Vector2(3, 14), coat_d, 1.0, true)   # פתח המעיל
	for i in 4:   # שתי שורות כפתורי פליז
		var by := sh.y + 4.0 + float(i) * 5.0
		z.draw_circle(Vector2(sh.x + 0.5, by), 0.9, gold)
		z.draw_circle(Vector2(sh.x + 4.5, by), 0.9, gold)
	z.draw_line(hip + Vector2(-8, -3), hip + Vector2(8, -3), col(Color("1e1a12")), 2.2, true)   # חגורה
	Art.fill(z, PackedVector2Array([hip + Vector2(1, -5), hip + Vector2(4, -5), hip + Vector2(4, -1), hip + Vector2(1, -1)]), gold, Art.OUTLINE, 0.6)
	# כותפות זהב
	for e in [Vector2(-6, -1), Vector2(6, 0)]:
		Art.fill(z, PackedVector2Array([sh + e + Vector2(-4, -1.5), sh + e + Vector2(4, -1.5), sh + e + Vector2(4.5, 1.5), sh + e + Vector2(-4.5, 1.5)]), gold, Art.OUTLINE, 0.7)
		for k in 3:
			z.draw_line(sh + e + Vector2(-3.0 + float(k) * 3.0, 1.5), sh + e + Vector2(-3.0 + float(k) * 3.0, 4.0), gold, 0.8)
	# ראש: פנים צנומות, צלקת, עין זוהרת אדומה, כובע קצינים
	Art.limb(z, PackedVector2Array([sh + Vector2(1, 0), sh + Vector2(2, -4)]), 4.5, Art.shade(sk, 0.1))
	Art.oval_shaded(z, head, 6.8, 7.8, sk, 0.0, Art.OUTLINE, 1.3)
	z.draw_line(head + Vector2(-1, -2), head + Vector2(3, 5), col(Color("4a1a1a")), 1.0, true)   # צלקת
	Art.fill(z, PackedVector2Array([head + Vector2(1.5, 3.5), head + Vector2(6.5, 3.0), head + Vector2(6.0, 5.5), head + Vector2(2.0, 6.0)]), col(Color("2a0a0c")), Art.OUTLINE, 0.8)
	var eye := head + Vector2(4.2, -1.0)
	Art.glow(z, eye, 4.5, Color(1.0, 0.2, 0.1, 0.8))
	z.draw_circle(eye, 1.1, Color(1.0, 0.55, 0.4))
	z.draw_line(head + Vector2(2, -3.5), head + Vector2(7, -3), col(Art.shade(z.skin, 0.45)), 1.3, true)
	var cap := col(Color("262a1c"))
	Art.fill(z, PackedVector2Array([head + Vector2(-7, -4), head + Vector2(-6, -9), head + Vector2(-2, -12.5), head + Vector2(6, -12), head + Vector2(7.5, -5)]), cap, Art.OUTLINE, 1.1)
	Art.fill(z, PackedVector2Array([head + Vector2(4, -5.5), head + Vector2(11, -4.5), head + Vector2(10, -3), head + Vector2(4, -3.8)]), col(Color("0e0e0a")), Art.OUTLINE, 0.8)
	z.draw_line(head + Vector2(-6.5, -6), head + Vector2(7, -6), red, 1.3)
	Art.disc(z, head + Vector2(2.5, -9.0), 1.5, gold, Art.OUTLINE, 0.6)   # סמל
	# יד קדמית: אלה / זיקוק מורם בזמן פקודה
	if _cmd_anim > 0.0 and not z.dead:
		var raise := clampf(_cmd_anim / 0.3, 0.0, 1.0) if _cmd_anim < 0.3 else 1.0
		var hand := sh.lerp(sh + Vector2(7.0, -22.0), raise) + Vector2(0, (1.0 - raise) * 14.0)
		z._arm(sh + Vector2(3, 1), hand, coat, coat)
		var fl := hand + Vector2(1.0, -8.0)
		z.draw_line(hand, fl, col(Color("3a2a20")), 2.4, true)
		Art.glow(z, fl, 12.0, Color(_flare, 0.85))
		z.draw_circle(fl, 2.4, _flare.lightened(0.5))
		for i in 4:   # ניצוצות
			var k := fmod(z._time * 3.0 + float(i) * 0.25, 1.0)
			z.draw_circle(fl + Vector2(sin(float(i) * 2.3 + z._time * 5.0) * 6.0 * k, -k * 12.0), 1.0 * (1.0 - k) + 0.3, Color(_flare.lightened(0.3), 1.0 - k))
	else:
		var swing := 1.0 if _swing > 0.0 else 0.0
		var hand := sh + Vector2(11.0 + swing * 5.0, 9.0 - swing * 12.0)
		z._arm(sh + Vector2(3, 1), hand, coat, coat)
		var dirv := Vector2(1.0, -0.6 - swing * 0.6).normalized()
		z.draw_line(hand - dirv * 3.0, hand + dirv * 12.0, col(Color("141414")), 2.2, true)   # אלה
		z.draw_circle(hand + dirv * 12.0, 1.4, gold)
	end_draw()
	return true
