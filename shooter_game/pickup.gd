extends Node2D
# ============================================================
#  חפץ שאפשר לאסוף (עוברים עליו):
#    AMMO     - קופסת תחמושת (+12 קליעים)
#    GRENADE  - (ישן) = SPECIAL "grenade"
#    SUPPLY   - ארגז ציוד צבאי (3 קופסאות תחמושת)
#    SPECIAL  - פריט נפץ (special = grenade / molotov / launcher / rocket, progression/arsenal.gd -> SPECIALS)
#    BOOST    - כוח מיוחד לכמה שניות (boost = סוג הבוסט)
#    HEALTH   - ערכת עזרה ראשונה: +1 לב (נשארת על הרצפה אם הלבבות מלאים)
#  נופל עם קשת קטנה, מרחף ומהבהב לפני שהוא נעלם.
# ============================================================

const Art := preload("res://art.gd")

enum { AMMO, GRENADE, SUPPLY, BOOST, WEAPON, HEALTH, SPECIAL }
const Arsenal := preload("res://progression/arsenal.gd")
enum { ADRENALINE, PIERCING, BULLET_TIME, SHIELD, INCENDIARY, GOD }   # GOD = שיקוי GOD MODE (פריט מיוחד, לא נופל כבוסט)

const BOOST_NAMES := ["ADRENALINE", "PIERCING ROUNDS", "BULLET TIME", "SHIELD", "INCENDIARY", "GOD MODE"]
const BOOST_COLORS := [Color("ff4a3a"), Color("4aa8ff"), Color("b0b8c8"), Color("40e0e8"), Color("ff9a20"), Color("ff2a2a")]

var kind := AMMO
var boost := ADRENALINE
var special := "grenade"    # SPECIAL: איזה פריט
var weapon_id := 1          # WEAPON: איזה נשק (1 שוטגאן, 2 קשת, 3 צלף, 4 טייזר)
var ammo_amount := -1       # WEAPON: כמה תחמושת בפנים (-1 = רגיל)
var pick_delay := 0.0       # נשק שנזרק: אי אפשר להרים אותו מיד
var life := 25.0
var velocity := Vector2.ZERO
var gravity := 1100.0
var _resting := false
var _t := 0.0


func setup(pos: Vector2, vel := Vector2(0, -220)) -> void:
	global_position = pos
	velocity = vel
	add_to_group("pickups")
	z_index = 6


func _physics_process(delta: float) -> void:
	_t += delta
	life -= delta
	if life <= 0.0:
		queue_free()
		return
	if not _resting:
		velocity.y += gravity * delta
		var to := global_position + velocity * delta
		var q := PhysicsRayQueryParameters2D.create(global_position, to + Vector2(0, 8), 1 | 16)
		var hit := get_world_2d().direct_space_state.intersect_ray(q)
		if hit and hit.normal.y < -0.5:
			global_position = hit.position + Vector2(0, -8)
			velocity = Vector2.ZERO
			_resting = true
		else:
			global_position = to
	pick_delay -= delta
	var p := get_tree().get_first_node_in_group("player")
	if p != null and not p.dead and pick_delay <= 0.0 and p.global_position.distance_to(global_position + Vector2(0, 16)) < 28.0:
		if p.collect(self):
			queue_free()
			return
	if Art.on_screen(self, global_position):
		queue_redraw()


func label() -> String:
	match kind:
		AMMO: return "+AMMO"
		GRENADE: return "+GRENADES"
		SUPPLY: return "+AMMO x3"
		SPECIAL: return "+" + str(Arsenal.SPECIALS[special].name)
		WEAPON: return str(Game.WEAPON_NAMES[weapon_id]) + "!"
		HEALTH: return "+1 HEART"
		_: return BOOST_NAMES[boost]


func color() -> Color:
	match kind:
		AMMO: return Color("d8c070")
		GRENADE: return Color("8aa040")
		SPECIAL: return Arsenal.SPECIALS[special].color
		SUPPLY: return Color("a8b870")
		WEAPON: return Game.WEAPON_COLORS[weapon_id]
		HEALTH: return Color("ff5a5a")
		_: return BOOST_COLORS[boost]


func _draw() -> void:
	if life < 4.0 and int(life * 8.0) % 2 == 0:   # מהבהב לפני שנעלם
		return
	var bob := Vector2(0, sin(_t * 3.0) * 2.0 - 3.0)
	var col := color()
	Art.glow(self, bob, 16.0 + 2.0 * sin(_t * 5.0), Color(col, 0.45))
	match kind:
		AMMO:
			Art.fill_shaded(self, PackedVector2Array([bob + Vector2(-9, -6), bob + Vector2(9, -6), bob + Vector2(9, 6), bob + Vector2(-9, 6)]), Color("4a5a30"), 0.2, 0.3, Art.OUTLINE, 1.2)
			for i in 3:   # קליעים מבצבצים
				var x := -5.0 + float(i) * 5.0
				Art.fill(self, PackedVector2Array([bob + Vector2(x - 1.3, -6), bob + Vector2(x + 1.3, -6), bob + Vector2(x + 1.3, -10), bob + Vector2(x, -12), bob + Vector2(x - 1.3, -10)]), Color("c8903a"), Art.OUTLINE, 0.6)
			draw_rect(Rect2(bob + Vector2(-6, -1), Vector2(12, 3)), Color("d8c070"))
		GRENADE:
			Art.oval_shaded(self, bob, 6.0, 7.0, Color("6d8236"), 0.0, Art.OUTLINE, 1.3)
			Art.fill(self, PackedVector2Array([bob + Vector2(-2, -7), bob + Vector2(2, -7), bob + Vector2(2, -10), bob + Vector2(-2, -10)]), Color("9a9aa2"), Art.OUTLINE, 0.8)
		SUPPLY:   # ארגז ציוד צבאי (ירוק זית, פינות מתכת, ידיות, כוכב מרוסס)
			Art.fill_shaded(self, PackedVector2Array([bob + Vector2(-12, -8), bob + Vector2(12, -8), bob + Vector2(12, 8), bob + Vector2(-12, 8)]), Color("4e5a32"), 0.2, 0.35, Art.OUTLINE, 1.3)
			draw_rect(Rect2(bob + Vector2(-12, -8), Vector2(24, 3)), Color("3a4426"))   # מכסה
			draw_line(bob + Vector2(-12, -5), bob + Vector2(12, -5), Color("2a301a"), 1.0)
			for cx: float in [-12.0, 9.0]:   # פינות מתכת
				draw_rect(Rect2(bob + Vector2(cx, -8), Vector2(3, 3)), Color("8a8e86"))
				draw_rect(Rect2(bob + Vector2(cx, 5), Vector2(3, 3)), Color("8a8e86"))
			draw_rect(Rect2(bob + Vector2(-2, -6), Vector2(4, 3)), Color("b8b8a8"))   # תפס
			draw_line(bob + Vector2(-15, -2), bob + Vector2(-15, 3), Color("2a2a22"), 2.0)   # ידיות
			draw_line(bob + Vector2(15, -2), bob + Vector2(15, 3), Color("2a2a22"), 2.0)
			var star := PackedVector2Array()
			for i in 10:
				var a := -PI * 0.5 + float(i) * PI / 5.0
				star.append(bob + Vector2(0, 2) + Vector2.from_angle(a) * (4.0 if i % 2 == 0 else 1.7))
			draw_colored_polygon(star, Color(0.85, 0.82, 0.68, 0.9))
		HEALTH:   # ערכת עזרה ראשונה: קופסה לבנה עם צלב אדום
			Art.fill_shaded(self, PackedVector2Array([bob + Vector2(-10, -8), bob + Vector2(10, -8), bob + Vector2(10, 8), bob + Vector2(-10, 8)]), Color("f0ece4"), 0.15, 0.3, Art.OUTLINE, 1.3)
			draw_rect(Rect2(bob + Vector2(-2.5, -6), Vector2(5, 12)), Color("e02a2a"))
			draw_rect(Rect2(bob + Vector2(-6, -2.5), Vector2(12, 5)), Color("e02a2a"))
			draw_rect(Rect2(bob + Vector2(-4, -11), Vector2(8, 3)), Color("8a8a90"))   # ידית
		SPECIAL:   # פריט נפץ: רימון / בקבוק / המשגר עצמו
			var wid: int = int(Arsenal.SPECIALS[special].weapon)
			if special == "god":   # שיקוי אדום מבעבע
				draw_potion(self, bob, 1.0, _t)
			elif special == "mind":   # מכשיר MIND CONTROL
				preload("res://effects/mind_control.gd").draw_device(self, bob + Vector2(-8, 0), Vector2.RIGHT, _t, 1.5)
			elif special == "grenade":
				for i in 2:
					var gp := bob + Vector2(-5.0 + float(i) * 10.0, 0.0)
					Art.oval_shaded(self, gp, 5.0, 6.0, Color("6d8236"), 0.0, Art.OUTLINE, 1.2)
					Art.fill(self, PackedVector2Array([gp + Vector2(-1.6, -6), gp + Vector2(1.6, -6), gp + Vector2(1.6, -9), gp + Vector2(-1.6, -9)]), Color("9a9aa2"), Art.OUTLINE, 0.7)
			elif wid >= 0:
				load("res://weapon_wheel.gd").draw_weapon(self, bob, wid, 0.6)
		WEAPON:   # צללית של הנשק
			load("res://weapon_wheel.gd").draw_weapon(self, bob, weapon_id, 0.62)   # אותו ציור כמו בגלגל הנשקים
		BOOST:
			# יהלום זוהר עם סמל
			var d := PackedVector2Array([bob + Vector2(0, -11), bob + Vector2(9, 0), bob + Vector2(0, 11), bob + Vector2(-9, 0)])
			Art.fill_shaded(self, d, col, 0.3, 0.3, Art.OUTLINE, 1.4)
			_icon(bob, boost, Color(1, 1, 1, 0.95))


# סמל קטן לכל בוסט (משמש גם את ה-HUD)
static func draw_boost_icon(ci: CanvasItem, c: Vector2, b: int, col: Color) -> void:
	match b:
		ADRENALINE:   # ברק
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(1, -6), c + Vector2(-3, 1), c + Vector2(0, 1), c + Vector2(-1, 6), c + Vector2(3, -1), c + Vector2(0, -1)]), col)
		PIERCING:     # חץ דרך קווים
			ci.draw_line(c + Vector2(-6, 0), c + Vector2(5, 0), col, 1.6, true)
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(6, 0), c + Vector2(2, -3), c + Vector2(2, 3)]), col)
			ci.draw_line(c + Vector2(-2, -4), c + Vector2(-2, 4), col, 1.0, true)
			ci.draw_line(c + Vector2(1, -4), c + Vector2(1, 4), col, 1.0, true)
		BULLET_TIME:  # שעון חול
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-4, -6), c + Vector2(4, -6), c + Vector2(0, 0)]), col)
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(0, 0), c + Vector2(4, 6), c + Vector2(-4, 6)]), col)
		SHIELD:       # מגן
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-5, -5), c + Vector2(5, -5), c + Vector2(5, 0), c + Vector2(0, 6), c + Vector2(-5, 0)]), col)
		INCENDIARY:   # להבה
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(0, -7), c + Vector2(4, 0), c + Vector2(3, 5), c + Vector2(-3, 5), c + Vector2(-4, 0), c + Vector2(-1, -2)]), col)
		GOD:          # שיקוי
			draw_potion(ci, c + Vector2(0, 1), 0.6, Time.get_ticks_msec() / 1000.0)


# שיקוי GOD MODE: בקבוק עגול עם נוזל אדום זוהר ובועות שעולות (s = גודל, t = זמן לאנימציה)
static func draw_potion(ci: CanvasItem, c: Vector2, s: float, t: float) -> void:
	var r := 7.5 * s
	var body := c + Vector2(0, 2.5 * s)
	ci.draw_circle(body, r * 2.1, Color(1.0, 0.1, 0.05, 0.12 + 0.05 * sin(t * 6.0)))   # זוהר
	ci.draw_rect(Rect2(c + Vector2(-2.2, -9.5) * s, Vector2(4.4, 6.0) * s), Color(0.75, 0.85, 0.9, 0.55))   # צוואר
	ci.draw_rect(Rect2(c + Vector2(-2.8, -12.0) * s, Vector2(5.6, 3.0) * s), Color("8a5a32"))              # פקק
	ci.draw_circle(body, r + 1.2 * s, Color(0.08, 0.02, 0.02))                                              # קו מתאר
	ci.draw_circle(body, r, Color("b0101a"))
	ci.draw_circle(body + Vector2(0, 1.5) * s, r * 0.8, Color("e0202a"))
	ci.draw_arc(body, r * 0.75, PI * 1.1, PI * 1.45, 6, Color(1, 1, 1, 0.55), 1.4 * s, true)               # ברק זכוכית
	for i in 4:   # בועות שעולות בתוך הבקבוק
		var ph := fposmod(t * 0.9 + float(i) * 0.27, 1.0)
		var bp := body + Vector2(sin(t * 3.0 + float(i) * 2.1) * 2.5, (4.0 - ph * 13.0)) * s
		ci.draw_circle(bp, (0.7 + 0.5 * float(i % 2)) * s, Color(1.0, 0.75, 0.7, 0.85 * (1.0 - ph)))
	var top := fposmod(t * 1.3, 1.0)   # בועה שיוצאת מהפקק
	ci.draw_circle(c + Vector2(sin(t * 4.0) * 1.5, -13.0 - top * 7.0) * s, 1.1 * s, Color(1.0, 0.3, 0.25, 0.7 * (1.0 - top)))


func _icon(c: Vector2, b: int, col: Color) -> void:
	draw_boost_icon(self, c, b, col)
