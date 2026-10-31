extends "res://enemies/stationary_boss.gd"
# ============================================================
#  THE EMPEROR (הבוס האחרון של שלב 45, "THE RED PALACE") - קיסר המתים על כס המלכות בארמון פטרופוליס.
#  גלימה אדומה עם פרווה לבנה, כתר זהב עם הנחש העתיק, שרביט עם כדור זוהר. עומד מול הכס על במת המדרגות.
#  "THEY LEARNED YOUR TRICKS" - הסיכום של כל האימפריה:
#    bolts  - מניפה של BOLT_N כדורי אש מהשרביט, בגובה שכל הרובאים בשלב למדו מההתחמקויות שלך (empire_kit squad_aim_y).
#    guards - "GUARDS!": קורא ל-GUARD_N משמר (PRAETORIAN) כשיש פחות מ-GUARD_MAX. כל עוד המשמר קרוב לכס (GUARD_R) -
#             הוא מקבל רק GUARD_MULT נזק ("THE GUARD PROTECTS HIM"). תהרוג את המשמר!
#    crown  - (מתחת לחצי) זורק את הכתר כמו בומרנג - הולך אליך וחוזר. בלי הכתר - הראש חשוף: CROWNLESS_MULT נזק בראש.
#    decree - (מתחת לחצי) "FOR THE EMPIRE!": כל חיילי האימפריה מסתערים, המבולבלים חוזרים לקרב.
#    pound  - צמוד אליו: מכת שרביט
#  כשהוא מת: "THE EMPIRE FALLS" - כל חיילי האימפריה נשברים.
#  לשנות: BOLT_N, BOLT_SPREAD, BOLT_CD, GUARD_N, GUARD_MAX, GUARD_R, GUARD_MULT, CROWN_CD, CROWNLESS_MULT, DECREE_CD.
# ============================================================

const E := preload("res://enemies/empire_kit.gd")

const SOUNDS := {
	"em_bolt": [["S", 600, 200, 0.0, 0.35, 0.0, 6.0, 0.3, 1.0, 0.05], ["N", 0, 0, 0.0, 0.2, 0.0, 10.0, 0.15, 0.6, 0, 0.6]],
	"em_roar": {"drive": 1.8, "layers": [["V", 70, 55, 0.0, 1.2, 0.1, 1.2, 0.8, 1.0, 0.05, 0, [300, 700, 4]]]},
	"em_crown": [["S", 1400, 1500, 0.0, 0.6, 0.0, 3.0, 0.15, 1.0, 0.1]],
}

const BOLT_N := 3
const BOLT_SPREAD := 70.0
const BOLT_CD := 2.6
const BOLT_V := 520.0
const GUARD_N := 2
const GUARD_MAX := 3
const GUARD_CD := 14.0
const GUARD_R := 520.0
const GUARD_MULT := 0.5
const CROWN_CD := 7.0
const CROWNLESS_MULT := 2.5
const DECREE_CD := 12.0

var bolts := 0               # לבדיקות
var guards_called := 0
var crowns := 0
var decrees := 0
var guarded_hits := 0
var crowned := true
var _bolt_cd := 1.5
var _guard_cd := 3.0
var _crown_cd := 2.0
var _decree_cd := 2.0
var _told := false
var _phase2 := false


class Crown extends Node2D:   # הכתר-בומרנג
	const A := preload("res://art.gd")
	var boss = null
	var target := Vector2.ZERO
	var t := 0.0
	var start := Vector2.ZERO
	var _hit_out := false
	var _hit_back := false

	func _ready() -> void:
		z_index = 9

	func _physics_process(delta: float) -> void:
		t += delta
		if boss == null or not is_instance_valid(boss.z):
			queue_free()
			return
		var home: Vector2 = boss.z.global_position + Vector2(boss.z._dir * 4.0 * boss.z.wf, -56.0) * boss.z.sc
		var k := t / 0.9
		if k < 1.0:   # הולך
			global_position = start.lerp(target, sin(k * PI * 0.5)) + Vector2(0, -sin(k * PI) * 60.0)
		else:   # חוזר
			var k2 := clampf((t - 0.9) / 0.9, 0.0, 1.0)
			global_position = target.lerp(home, k2 * k2) + Vector2(0, -sin(k2 * PI) * 60.0)
			if k2 >= 1.0:
				boss._crown_back()
				queue_free()
				return
		var pl := get_tree().get_first_node_in_group("player")
		if pl != null and not pl.dead and pl.body_rect().grow(10.0).has_point(global_position):
			if (k < 1.0 and not _hit_out) or (k >= 1.0 and not _hit_back):
				if k < 1.0:
					_hit_out = true
				else:
					_hit_back = true
				pl.hurt(1, Vector2(signf(pl.global_position.x - global_position.x + 0.01), -0.6))
		queue_redraw()

	func _draw() -> void:
		DrawBatch.begin(self)
		_draw_b()
		DrawBatch.end(self)

	func _draw_b() -> void:
		var a := t * 14.0
		var pts := PackedVector2Array()
		for q in 10:
			var r := 12.0 if q % 2 == 0 else 7.0
			pts.append(Vector2.from_angle(a + float(q) / 10.0 * TAU) * r)
		DrawBatch.colored_polygon(self, pts, Color("e0b040"))
		DrawBatch.circle(self, Vector2.ZERO, 4.0, Color("c02020"))
		A.glow(self, Vector2.ZERO, 16.0, Color(1.0, 0.8, 0.3, 0.3))


func stats() -> Dictionary:
	return {"name": "THE EMPEROR", "hp": 400, "walk": 0.0, "chase": 0.0, "damage": 2, "bite_delay": 1.0, "scale": 2.6, "width": 1.4,
		"duck": 0.0, "cover": 0.0, "skin": Color("8a9480"), "shirt": Color("8a1414"), "pants": Color("5a0e0e"), "shoe": Color("1a1010"),
		"points": 5000, "boss": true, "boss_name": "THE EMPEROR - KILL HIS GUARD, THEN THE CROWN"}


func setup() -> void:
	super.setup()
	z.add_to_group("empire")


func eye() -> Vector2:   # השרביט
	return z.global_position + Vector2(z._dir * 16.0 * z.wf, -52.0) * z.sc


func weak_rect() -> Rect2:   # הראש
	return Rect2(-2, -54, 14, 15)


func guard_near() -> int:
	var n := 0
	for g in z.get_tree().get_nodes_in_group("praetorians"):
		if not g.dead and absf(g.global_position.x - z.global_position.x) < GUARD_R:
			n += 1
	return n


func damage_mult(zone: String, src: Dictionary) -> float:
	var m := super.damage_mult(zone, src)
	if not crowned and in_weak(_last_hit):
		m = CROWNLESS_MULT
	if guard_near() > 0:
		guarded_hits += 1
		m *= GUARD_MULT
		if not _told:
			_told = true
			z._popup("THE GUARD PROTECTS HIM", Color("ff8060"), 15, -60.0 - 70.0 * z.sc)
	return m


func on_death() -> void:
	super.on_death()
	z._popup("THE EMPIRE FALLS", Color("ffd040"), 24, -60.0 - 80.0 * z.sc)
	for o in z.get_tree().get_nodes_in_group("empire"):
		if o != z and not o.dead and o.type_mod != null and o.type_mod.has_method("on_order"):
			o.type_mod.on_order("broken", z)


func _crown_back() -> void:
	crowned = true
	Sfx.play("em_crown", z.global_position, -4.0, 0.1, 2)


func think(pl: Node, delta: float) -> void:
	_bolt_cd -= delta
	_guard_cd -= delta
	_crown_cd -= delta
	_decree_cd -= delta
	if not _phase2 and z.hp < z.max_hp / 2:
		_phase2 = true
		Sfx.play("em_roar", z.global_position, 4.0, 0.02, 2)
		z._popup("YOU WILL KNEEL!", Color("ff4030"), 18, -60.0 - 70.0 * z.sc)
	var dx: float = absf(pl.global_position.x - z.global_position.x)
	if dx > 1300.0:
		return
	if _guard_cd <= 0.0:
		var alive := 0
		for g in z.get_tree().get_nodes_in_group("praetorians"):
			if not g.dead:
				alive += 1
		_guard_cd = GUARD_CD if alive < GUARD_MAX else 4.0
		if alive < GUARD_MAX:
			wind("guards", 0.8)
			return
	if _phase2 and _decree_cd <= 0.0:
		wind("decree", 0.7)
		return
	if _phase2 and crowned and _crown_cd <= 0.0 and dx > 120.0:
		wind("crown", 0.6)
		return
	if _bolt_cd <= 0.0:
		wind("bolts", 0.6)


func attack(name: String, pl: Node) -> void:
	match name:
		"pound":
			do_pound(pl)
		"bolts":
			_bolt_cd = BOLT_CD * (0.7 if _phase2 else 1.0)
			bolts += 1
			Sfx.play("em_bolt", eye(), 0.0, 0.1, 2)
			var base: Vector2 = pl.global_position + Vector2(0, E.squad_aim_y(z.get_parent()))   # בגובה שהאימפריה למדה
			for i in BOLT_N:
				var off := (float(i) - float(BOLT_N - 1) * 0.5) * BOLT_SPREAD
				fire_shot(eye(), base + Vector2(0, off * 0.4) + Vector2(off, 0) * 0.3, BOLT_V, 1, "orb", Color(1.0, 0.35, 0.2), 7.0)
		"guards":
			guards_called += 1
			z._popup("GUARDS!", Color("ff4030"), 16, -60.0 - 70.0 * z.sc)
			Sfx.play("em_roar", z.global_position, 0.0, 0.05, 2)
			var main: Node = z.get_parent()
			var gy: float = float(main.get_meta("boss_ground_y")) if main.has_meta("boss_ground_y") else z.global_position.y
			for i in GUARD_N:
				var g: Node = main._spawn_zombie(z.global_position.x + z._dir * (300.0 + float(i) * 60.0), gy, preload("res://enemies/zombie_registry.gd").PRAETORIAN)
				if g != null:
					g._alert_t = 8.0
		"crown":
			_crown_cd = CROWN_CD
			crowns += 1
			crowned = false
			Sfx.play("em_crown", z.global_position, 0.0, 0.1, 2)
			var c := Crown.new()
			c.boss = self
			c.start = z.global_position + Vector2(z._dir * 4.0 * z.wf, -56.0) * z.sc
			c.target = pl.global_position + Vector2(0, -30)
			z.get_parent().add_child(c)
			c.global_position = c.start
		"decree":
			_decree_cd = DECREE_CD
			decrees += 1
			z._popup("FOR THE EMPIRE!", Color("ffd040"), 16, -60.0 - 70.0 * z.sc)
			E.order(z, "rally", 1600.0)
			E.order(z, "charge", 1600.0)


# ============================================================
#  ציור: הכס מאחור (גב גבוה אדום-זהב), גלימה אדומה ארוכה עם צווארון פרווה לבן, כתר (או בלעדיו), שרביט עם כדור זוהר
# ============================================================
func draw() -> bool:
	begin_draw()
	var k := wind_k()
	# הכס
	DrawBatch.rect(z, Rect2(Vector2(-16, -70), Vector2(26, 70)), col(Color("5a0e0e")))
	DrawBatch.rect(z, Rect2(Vector2(-18, -74), Vector2(30, 6)), col(Color("c8a040")))
	DrawBatch.rect(z, Rect2(Vector2(-18, -36), Vector2(30, 4)), col(Color("c8a040")))
	E.emblem(z, Vector2(-3, -60), 5.0)
	var o: Dictionary = E.soldier(self, z, Vector2(16, -4) if winding == "bolts" else Vector2(12, 4), "none", Color("8a1414"), Vector2(-4, -16) if winding == "guards" or winding == "decree" else Vector2(999, 0), 1.5)
	var head: Vector2 = o.head
	var sh: Vector2 = o.sh
	var hip: Vector2 = o.hip
	var hf: Vector2 = o.hf
	# גלימה ארוכה
	DrawBatch.colored_polygon(z, PackedVector2Array([sh + Vector2(-9, 0), hip + Vector2(-12, 22), hip + Vector2(10, 22), hip + Vector2(8, 4)]), col(Color("8a1414")))
	DrawBatch.colored_polygon(z, PackedVector2Array([sh + Vector2(-9, -2), sh + Vector2(9, -2), sh + Vector2(7, 4), sh + Vector2(-7, 4)]), col(Color("f0ece4")))   # פרווה
	for q in 4:
		DrawBatch.circle(z, sh + Vector2(-6.0 + float(q) * 4.0, 1), 0.6, col(Color("1a1a1a")))
	# כתר
	if crowned:
		DrawBatch.colored_polygon(z, PackedVector2Array([head + Vector2(-6, -4), head + Vector2(-6, -11), head + Vector2(-3, -7), head + Vector2(0, -13), head + Vector2(3, -7), head + Vector2(6, -12), head + Vector2(7, -4)]), col(Color("e0b040")))
		DrawBatch.circle(z, head + Vector2(0.5, -6), 1.4, Color(1.0, 0.2, 0.2))
	# שרביט
	DrawBatch.line(z, hf + Vector2(0, 10), hf + Vector2(0, -16), col(Color("c8a040")), 1.6)
	var orb := hf + Vector2(0, -18)
	DrawBatch.circle(z, orb, 3.0, col(Color("c02020")))
	if not z.dead:
		Art.glow(z, orb, 4.0 + 8.0 * (k if winding == "bolts" else 0.2), Color(1.0, 0.3, 0.2, 0.5))
	end_draw()
	if guard_near() > 0 and not z.dead:   # הילת המשמר
		DrawBatch.arc(z, Vector2(0, -40.0 * z.sc), 40.0 * z.sc, 0.0, TAU, 32, Color(1.0, 0.8, 0.3, 0.25), 3.0)
	return true
