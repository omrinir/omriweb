extends "res://enemies/zombie_type.gd"
# ============================================================
#  CRUMBLER (שלב 14, צפון-מזרח) - דייג רקוב במעיל גשם צהוב קרוע. הבשר שלו מתפרק.
#  כל קליע תולש ממנו חלק - החלק הכי קרוב למקום הפגיעה: קרקפת, לסת, אוזן, כף יד, יד קדמית,
#    יד אחורית, בשר החזה (רואים צלעות), הבטן (מעיים משתלשלים), רגליים.
#  החלקים עפים באמת (Chunk: כבידה, מסתובבים, קופצים על הריצפה ונשארים לשכב).
#  השפעה: בלי רגל אחת = קופץ על רגל אחת. בלי שתי הרגליים = זוחל אליך (נמוך! קשה לפגוע).
#    בלי ידיים ובלי לסת - עדיין דוחף אותך עם הגוף. רימון = תולש 3 חלקים בבת אחת.
#  כשהוא מת - כל מה שנשאר עליו מתפרק לחתיכות.
#  צלילים: "crm_rip" (קריעה רטובה).
#  לשנות: PARTS (מיקום כל חלק לבחירה לפי מקום הפגיעה), CRAWL_SPEED.
# ============================================================

const SOUNDS := {
	"crm_rip": [["N", 0, 0, 0.0, 0.16, 0.0, 16.0, 0.75, 0.45, 0], ["S", 150, 60, 0.0, 0.14, 0.0, 18.0, 0.55, 1.0, 0], ["N", 0, 0, 0.03, 0.1, 0.0, 30.0, 0.3, 1.0, 0]],
}

# שם -> [מיקום מקומי (פונה ימינה, 0,0 = כפות רגליים), אזור]
const PARTS := {
	"scalp": [Vector2(3, -54), "head"],
	"jaw": [Vector2(7, -43), "head"],
	"ear": [Vector2(-1, -48), "head"],
	"hand_f": [Vector2(16, -33), "body"],
	"arm_f": [Vector2(9, -34), "body"],
	"arm_b": [Vector2(-5, -34), "body"],
	"chest": [Vector2(2, -33), "body"],
	"belly": [Vector2(1, -26), "body"],
	"leg_b": [Vector2(-3, -10), "leg"],
	"leg_f": [Vector2(3, -10), "leg"],
}
const CRAWL_SPEED := 46.0

var parts := {}            # מה עוד מחובר אליו
var lost := 0              # לבדיקות: כמה חלקים נתלשו
var crawling := false
var _bite_cd := 0.0


func stats() -> Dictionary:
	return {"name": "CRUMBLER", "hp": 44, "walk": 40.0, "chase": 82.0, "damage": 1, "bite_delay": 0.9, "scale": 1.0, "width": 0.95,
		"duck": 0.0, "cover": 0.0, "skin": Color("8f9c78"), "shirt": Color("d8a326"), "pants": Color("2e3a46"), "shoe": Color("1e1a16"),
		"points": 320, "ragdoll": false}


func brain_overrides() -> Dictionary:
	return {"aggression": 0.5}


func setup() -> void:
	for k in PARTS:
		parts[k] = true


func has(p: String) -> bool:
	return parts.has(p)


# ---- כל פגיעה תולשת חלק ----
func on_damage(_amount: int, hit_pos: Vector2, dir: Vector2, src: Dictionary) -> bool:
	var source: String = src.get("source", "bullet")
	var n := 3 if source in ["grenade", "barrel", "car", "boom"] or src.get("explosive", false) else 1
	var lp := Vector2((hit_pos.x - z.global_position.x) * z._dir / (z.sc * z.wf), (hit_pos.y - z.global_position.y) / z.sc)
	if crawling:   # זוחל: הכל נמוך
		lp.y = lp.y * 3.0 - 30.0
	var zone := "head" if lp.y < -42.0 else ("leg" if lp.y > -20.0 else "body")
	for i in n:
		_rip(_pick(lp, zone if i == 0 else ""), dir)
	return true


func _pick(lp: Vector2, zone: String) -> String:
	var best := ""
	var bd := INF
	for pass_i in 2:
		for k in parts:
			if pass_i == 0 and zone != "" and PARTS[k][1] != zone:
				continue
			if k == "arm_f" and has("hand_f"):   # קודם כף היד, ואז היד כולה
				continue
			var d: float = lp.distance_to(PARTS[k][0])
			if d < bd:
				bd = d
				best = k
		if best != "":
			return best
	return best


func _rip(p: String, dir: Vector2) -> void:
	if p == "" or not has(p):
		return
	parts.erase(p)
	lost += 1
	Game.story.emit("crumble", {"z": z})
	var with_hand := false
	if p == "arm_f" and has("hand_f"):
		parts.erase("hand_f")
		with_hand = true
	var lp: Vector2 = PARTS[p][0]
	var gp: Vector2 = z.global_position + Vector2(lp.x * z._dir * z.wf, lp.y) * z.sc
	if crawling:
		gp = z.global_position + Vector2(lp.x * z._dir, -8.0) * z.sc
	var ch := Chunk.new()
	ch.kind = p
	ch.with_hand = with_hand or p == "arm_b"
	ch.skin = z.skin
	ch.coat = z.shirt
	ch.pants = z.pants
	ch.shoe = z.shoe
	ch.sc = z.sc
	ch.face = z._dir
	z.get_parent().add_child(ch)
	ch.global_position = gp
	ch.velocity = Vector2(dir.x * randf_range(140.0, 260.0) + randf_range(-40.0, 40.0), -randf_range(160.0, 320.0))
	z._spray_blood(gp, Vector2(dir.x, -0.4), 6, 240.0)
	Sfx.play("crm_rip", gp, -4.0, 0.15, 3)
	if p == "jaw" or p == "scalp":
		z._popup("!", Color("ffb070"), 16, -70.0)
	# רגליים: אחת = קופץ, שתיים = זוחל
	if (p == "leg_f" or p == "leg_b") and not z.dead:
		if has("leg_f") or has("leg_b"):
			z._one_leg = true
			z._hop_t = 0.4
		else:
			_start_crawl()


func _start_crawl() -> void:
	Game.story.emit("crumble_crawl", {"z": z})
	crawling = true
	z._one_leg = false
	var r := z._shape.shape as RectangleShape2D
	r.size = Vector2(46.0, 24.0) * z.sc
	z._shape.position = Vector2(0.0, -12.0 * z.sc)
	z._popup("CRAWLING", Color("ffb070"), 14, -40.0)


func on_death() -> void:
	var d := Vector2(-z._dir, 0.0)
	for k in parts.keys():   # כל מה שנשאר מתפרק
		_rip(k, Vector2(randf_range(-1.0, 1.0), -0.5) if randf() < 0.5 else d)
	var ch := Chunk.new()   # הגוף עצמו
	ch.kind = "torso"
	ch.skin = z.skin
	ch.coat = z.shirt
	ch.pants = z.pants
	ch.shoe = z.shoe
	ch.sc = z.sc
	ch.face = z._dir
	z.get_parent().add_child(ch)
	ch.global_position = z.global_position + Vector2(0, -26.0 * z.sc)
	ch.velocity = Vector2(randf_range(-80.0, 80.0), -140.0)


func can_bite() -> bool:
	return not crawling


# זוחל: תנועה ונשיכה בעצמו
func physics(pl: Node, delta: float) -> bool:
	_bite_cd -= delta
	if not crawling or z.dead:
		return false
	if not z.is_on_floor():
		z.velocity.y += z.gravity * delta
	var spd := 0.0
	if pl != null and not pl.dead:
		var d: Vector2 = pl.global_position - z.global_position
		if absf(d.x) < 900.0:
			z._dir = signf(d.x) if d.x != 0.0 else z._dir
			spd = CRAWL_SPEED * (0.6 + 0.4 * absf(sin(z._time * 3.0)))   # משיכות
			if absf(d.x) < 26.0 * z.sc:
				spd = 0.0
				if absf(d.y) < 34.0 and _bite_cd <= 0.0:
					_bite_cd = 1.0
					pl.hurt(z.damage, Vector2(z._dir, 0.0))
	z.velocity.x = move_toward(z.velocity.x, z._dir * spd, 400.0 * delta)
	z.move_and_slide()
	z._walk_phase += absf(z.velocity.x) * delta * 0.12
	return true


# ============================================================
#  ציור
# ============================================================
func draw() -> bool:
	if z.dead:
		return true   # התפרק לחתיכות (Chunk)
	begin_draw()
	if crawling:
		_draw_crawl()
	else:
		_draw_stand()
	end_draw()
	return true


func _draw_stand() -> void:
	var sk := col(z.skin)
	var coat := col(z.shirt)
	var p: float = z._walk_phase
	var f: Array = feet(4.5, 2.5)
	var hip := Vector2(-1.0, -22.0 + absf(sin(p)) * 1.2)
	var lean := 2.0 if not has("arm_f") and not has("arm_b") else 0.0   # בלי ידיים - מתנודד קדימה
	var sh := Vector2(1.0 + lean, -38.0)
	var head := sh + Vector2(3.0 + lean, -9.0)
	var blood := col(Color("6a0c0c"))
	# רגליים (או גדמים)
	if has("leg_b"):
		z._leg(hip + Vector2(-2, 0), f[1], col(Art.shade(z.pants, 0.25)), col(Art.shade(z.skin, 0.2)), col(z.shoe))
	else:
		Art.disc(z, hip + Vector2(-2, 3), 3.0, blood)
	if has("leg_f"):
		z._leg(hip + Vector2(2, 0), f[0] if has("leg_b") else Vector2(1, 0), col(z.pants), sk, col(z.shoe))
	else:
		Art.disc(z, hip + Vector2(2, 3), 3.0, blood)
	# יד אחורית
	if has("arm_b"):
		_limb_arm(sh + Vector2(-3, 1), sh + Vector2(13, 3) + Vector2(0, sin(p) * 2.0), col(Art.shade(z.skin, 0.25)), col(Art.shade(z.shirt, 0.3)), true)
	# גוף: מעיל גשם קרוע
	var body := PackedVector2Array([sh + Vector2(-7, -1), sh + Vector2(7, 0), hip + Vector2(7, 5), hip + Vector2(3, 3), hip + Vector2(0, 6), hip + Vector2(-4, 3), hip + Vector2(-7, 5)])
	Art.fill_shaded(z, body, coat, 0.15, 0.4)
	z.draw_line(sh + Vector2(-1, 1), hip + Vector2(-1, 2), col(Art.shade(z.shirt, 0.35)), 1.0)   # רוכסן
	if not has("chest"):   # בשר החזה נתלש: צלעות
		Art.oval(z, sh + Vector2(1, 7), 5.5, 5.0, col(Color("2a0808")), 0.0, Art.NONE)
		for i in 3:
			z.draw_arc(sh + Vector2(1, 4.5 + float(i) * 2.6), 4.2, 0.2, PI - 0.2, 6, col(Color("e8dcc0")), 1.2)
	if not has("belly"):   # בטן קרועה: מעיים משתלשלים
		Art.oval(z, hip + Vector2(1, -5), 4.5, 3.5, col(Color("2a0808")), 0.0, Art.NONE)
		var sw := sin(z._time * 4.0) * 2.0
		z.draw_polyline(PackedVector2Array([hip + Vector2(0, -5), hip + Vector2(3 + sw, 2), hip + Vector2(-1 + sw * 1.5, 8), hip + Vector2(2 + sw * 2.0, 13)]), col(Color("c06070")), 2.4, true)
	# צוואר + ראש
	Art.limb(z, PackedVector2Array([sh + Vector2(1, 0), head + Vector2(-1, 5)]), 4.0, Art.shade(sk, 0.15))
	Art.oval_shaded(z, head, 6.4, 6.8, sk, 0.0)
	if has("ear"):
		Art.oval(z, head + Vector2(-4.5, 0.5), 1.8, 2.6, col(Art.shade(z.skin, 0.2)), 0.0, Art.OUTLINE, 0.8)
	else:
		z.draw_circle(head + Vector2(-4.5, 0.5), 1.4, blood)
	if has("scalp"):   # שיער דליל רטוב
		Art.fill(z, PackedVector2Array([head + Vector2(-6, -2), head + Vector2(-3, -7), head + Vector2(3, -7.5), head + Vector2(6, -3), head + Vector2(1, -4)]), col(Color("3a3428")), Art.OUTLINE, 0.8)
	else:   # הקרקפת נתלשה: מוח חשוף
		Art.oval(z, head + Vector2(0, -4.5), 5.5, 3.0, col(Color("d88a96")), 0.0, Art.OUTLINE, 0.9)
		z.draw_arc(head + Vector2(0, -4.0), 4.0, PI + 0.4, TAU - 0.4, 6, col(Color("b06070")), 0.8)
	# עין זוהרת
	z.draw_circle(head + Vector2(3.0, -1.0), 1.3, Color(0.85, 0.95, 0.5) if z._flash <= 0.0 else Color.WHITE)
	if has("jaw"):
		Art.fill(z, PackedVector2Array([head + Vector2(0, 3), head + Vector2(7, 2.5), head + Vector2(6, 7), head + Vector2(1, 7.5)]), col(Art.shade(z.skin, 0.1)), Art.OUTLINE, 0.9)
		z.draw_line(head + Vector2(2, 4.5), head + Vector2(6.5, 4.2), col(Color("2a0a0a")), 1.0)
	else:   # בלי לסת: שיניים עליונות ולשון משתלשלת
		for i in 4:
			z.draw_rect(Rect2(head + Vector2(1.5 + float(i) * 1.5, 2.5), Vector2(1.0, 1.6)), col(Color("e8e0c0")))
		z.draw_polyline(PackedVector2Array([head + Vector2(3, 4), head + Vector2(4 + sin(z._time * 5.0), 8), head + Vector2(3.5, 11)]), col(Color("b84a5a")), 1.8, true)
		z.draw_circle(head + Vector2(4, 4.5), 2.0, blood)
	# יד קדמית
	if has("arm_f"):
		_limb_arm(sh + Vector2(3, 2), sh + Vector2(16, 5) + Vector2(0, sin(p + PI) * 2.0), sk, coat, has("hand_f"))
	else:
		Art.disc(z, sh + Vector2(3, 2), 2.6, blood)


func _limb_arm(s: Vector2, hand: Vector2, sk: Color, sleeve: Color, with_hand: bool) -> void:
	var el := s.lerp(hand, 0.5) + Vector2(0, 3)
	Art.limb(z, PackedVector2Array([s, el]), 4.6, sleeve)
	Art.limb(z, PackedVector2Array([el, hand]), 3.4, sk)
	if with_hand:
		Art.disc(z, hand + Vector2(1, 0), 2.4, sk)
		z.draw_line(hand + Vector2(2, -1), hand + Vector2(4.5, -1.5), sk, 1.0)
		z.draw_line(hand + Vector2(2, 1), hand + Vector2(4.5, 1.5), sk, 1.0)
	else:
		z.draw_circle(hand, 1.8, col(Color("6a0c0c")))


func _draw_crawl() -> void:
	var sk := col(z.skin)
	var coat := col(z.shirt)
	var pull := sin(z._walk_phase * 3.0)
	var hip := Vector2(-12.0, -6.0)
	var sh := Vector2(6.0, -9.0 - pull * 0.8)
	var head := sh + Vector2(8.0, -3.0)
	Art.fill_shaded(z, PackedVector2Array([hip + Vector2(-3, -4), sh + Vector2(1, -5), sh + Vector2(2, 3), hip + Vector2(-3, 4)]), coat, 0.15, 0.4)
	z.draw_circle(hip + Vector2(-3, 1), 3.0, col(Color("6a0c0c")))   # גדמים
	if not has("belly"):
		z.draw_polyline(PackedVector2Array([hip + Vector2(4, 3), hip + Vector2(-2, 6), hip + Vector2(-10, 5), hip + Vector2(-18, 6)]), col(Color("c06070")), 2.2, true)   # נגרר אחריו
	if has("arm_b"):
		_limb_arm(sh + Vector2(-1, 0), sh + Vector2(12 + pull * 4.0, 8), col(Art.shade(z.skin, 0.25)), col(Art.shade(z.shirt, 0.3)), true)
	Art.oval_shaded(z, head, 6.0, 6.2, sk, 0.0)
	z.draw_circle(head + Vector2(3.0, -1.0), 1.3, Color(0.85, 0.95, 0.5))
	if not has("scalp"):
		Art.oval(z, head + Vector2(-1, -4), 5.0, 2.6, col(Color("d88a96")), 0.0, Art.OUTLINE, 0.9)
	if has("jaw"):
		Art.fill(z, PackedVector2Array([head + Vector2(0, 3), head + Vector2(7, 2.5), head + Vector2(6, 6.5), head + Vector2(1, 7)]), col(Art.shade(z.skin, 0.1)), Art.OUTLINE, 0.9)
	if has("arm_f"):
		_limb_arm(sh + Vector2(2, 1), sh + Vector2(16 - pull * 4.0, 9), sk, coat, has("hand_f"))


# ============================================================
#  חתיכה שנתלשה: עפה, מסתובבת, קופצת על הריצפה ונשארת לשכב קצת
# ============================================================
class Chunk extends Node2D:
	var kind := "jaw"
	var with_hand := false
	var skin := Color.GRAY
	var coat := Color.YELLOW
	var pants := Color.BLACK
	var shoe := Color.BLACK
	var sc := 1.0
	var face := 1.0
	var velocity := Vector2.ZERO
	var spin := 0.0
	var life := 9.0
	var _rest := false

	func _ready() -> void:
		z_index = 4
		spin = randf_range(-10.0, 10.0)
		add_to_group("no_outline")

	func _physics_process(delta: float) -> void:
		life -= delta
		if life <= 0.0:
			queue_free()
			return
		if _rest:
			if life < 1.0:
				queue_redraw()
			return
		velocity.y += 1000.0 * delta
		var to := global_position + velocity * delta
		var hit := get_world_2d().direct_space_state.intersect_ray(PhysicsRayQueryParameters2D.create(global_position, to + Vector2(0, 3), 1 | 16))
		if hit and hit.normal != Vector2.ZERO:
			global_position = hit.position + hit.normal * 2.0
			velocity = velocity.bounce(hit.normal) * 0.3
			velocity.x *= 0.6
			spin *= 0.4
			if velocity.length() < 50.0:
				_rest = true
				rotation = snappedf(rotation, PI) + randf_range(-0.2, 0.2)   # נח על הצד
		else:
			global_position = to
			rotation += spin * delta
		queue_redraw()

	func _draw() -> void:
		var a := clampf(life, 0.0, 1.0)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(face * sc, sc))
		var blood := Color(0.42, 0.04, 0.04, a)
		var sk := Color(skin, a)
		var cl := Color(coat, a)
		var ol := Color(Art.OUTLINE, a)
		match kind:
			"scalp":
				draw_colored_polygon(PackedVector2Array([Vector2(-6, 1), Vector2(-4, -3), Vector2(3, -3.5), Vector2(6, 0), Vector2(0, 2)]), Color(0.23, 0.2, 0.16, a))
				draw_line(Vector2(-6, 1), Vector2(6, 0), blood, 1.6)
			"jaw":
				draw_colored_polygon(PackedVector2Array([Vector2(-4, -1), Vector2(4, -1.5), Vector2(3, 3), Vector2(-3, 3.5)]), sk)
				for i in 3:
					draw_rect(Rect2(Vector2(-2.5 + float(i) * 2.0, -2.5), Vector2(1.0, 1.5)), Color(0.9, 0.88, 0.75, a))
				draw_line(Vector2(-4, -1), Vector2(4, -1.5), blood, 1.2)
			"ear":
				draw_circle(Vector2.ZERO, 2.4, sk)
				draw_circle(Vector2(0.6, 0), 1.0, blood)
			"hand_f":
				draw_circle(Vector2.ZERO, 2.6, sk)
				for i in 3:
					draw_line(Vector2(1, -1.5 + float(i) * 1.5), Vector2(4.5, -2.0 + float(i) * 2.0), sk, 1.0)
				draw_circle(Vector2(-2.2, 0), 1.4, blood)
			"arm_f", "arm_b":
				draw_line(Vector2(-7, 0), Vector2(0, 1), ol, 6.4)
				draw_line(Vector2(-7, 0), Vector2(0, 1), cl, 4.6)
				draw_line(Vector2(0, 1), Vector2(7, 0), ol, 5.0)
				draw_line(Vector2(0, 1), Vector2(7, 0), sk, 3.4)
				if with_hand:
					draw_circle(Vector2(9, 0), 2.4, sk)
				draw_circle(Vector2(-7.5, 0), 2.2, blood)
			"chest":
				draw_colored_polygon(PackedVector2Array([Vector2(-5, -3), Vector2(5, -4), Vector2(6, 3), Vector2(-4, 4)]), cl)
				draw_colored_polygon(PackedVector2Array([Vector2(-3, 1), Vector2(4, 0), Vector2(4, 4), Vector2(-2, 4)]), Color(0.6, 0.25, 0.25, a))
			"belly":
				draw_polyline(PackedVector2Array([Vector2(-7, 0), Vector2(-3, -3), Vector2(1, 1), Vector2(5, -2), Vector2(8, 1)]), Color(0.75, 0.38, 0.44, a), 2.6, true)
			"leg_f", "leg_b":
				draw_line(Vector2(0, -10), Vector2(0, 4), ol, 6.6)
				draw_line(Vector2(0, -10), Vector2(0, 4), Color(pants, a), 4.8)
				draw_rect(Rect2(Vector2(-2, 3), Vector2(7, 3.5)), Color(shoe, a))
				draw_circle(Vector2(0, -10.5), 2.4, blood)
			"torso":
				draw_colored_polygon(PackedVector2Array([Vector2(-7, -9), Vector2(7, -8), Vector2(7, 9), Vector2(-7, 9)]), cl)
				draw_line(Vector2(-7, -9), Vector2(7, -8), blood, 2.0)
				draw_arc(Vector2(0, -2), 4.0, 0.2, PI - 0.2, 6, Color(0.9, 0.86, 0.75, a), 1.2)
		draw_set_transform_matrix(Transform2D.IDENTITY)

	const Art := preload("res://art.gd")
