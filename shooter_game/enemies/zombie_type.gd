extends RefCounted
# ============================================================
#  ZOMBIE TYPE - בסיס לכל סוג זומבי חדש (שלבים 5-9).
#
#  ****  איך מוסיפים זומבי חדש  ****
#   1. יוצרים קובץ ב-enemies/types/<name>.gd שמתחיל ב:
#        extends "res://enemies/zombie_type.gd"
#   2. מממשים stats() (חיים, מהירות, גודל, צבעים, ניקוד) ו-draw() (צללית ייחודית!).
#      אופציונלי: brain_overrides(), logic(), physics(), on_damage(), on_bite(), on_death().
#   3. רושמים אותו ב-enemies/zombie_registry.gd (מספר kind + נתיב לקובץ).
#   4. מוסיפים אותו לשלב: levels/stage_N.gd -> zombie_weights().
#   5. צלילים: מוסיפים ל-enemies/enemy_sounds.gd ומנגנים עם Sfx.play("שם", z.global_position)
#
#  "z" = הזומבי עצמו (zombie.gd, CharacterBody2D). אפשר לגשת לכל מה שיש לו:
#    z.velocity, z._dir (כיוון -1/1), z.hp, z.max_hp, z.sc (גודל), z.wf (רוחב), z.dead,
#    z._time, z._walk_phase, z._flash (>0 = נפגע עכשיו -> לצבוע לבן), z.brain (ai/zombie_brain.gd),
#    z.is_on_floor(), z.move_and_slide(), z._voice(name, chance, vol), z._popup(text, color, size, y)
#  ציור: נקודת (0,0) = כפות הרגליים, הזומבי פונה ימינה, גובה רגיל ~56.
#    begin_draw() מסדר היפוך/גודל/מוות, ואז אפשר להשתמש ב:
#    z._leg(hip, foot, pants, skin, shoe), z._arm(shoulder, hand, skin, sleeve), z._head(center, skin)
#    ו-Art (art.gd): fill, fill_shaded, limb, oval, disc, glow...
# ============================================================

const Art := preload("res://art.gd")
const Sfx := preload("res://sfx.gd")
const Particles := preload("res://particles.gd")

var z = null        # הזומבי (נקבע ע"י zombie.gd)


# חיים, מהירויות, גודל וצבעים - אותם שדות כמו KINDS ב-zombie.gd, ועוד:
#   "name": שם, "points": ניקוד, "boss": true = בוס (בר חיים ב-HUD)
func stats() -> Dictionary:
	return {"name": "ZOMBIE", "hp": 30, "walk": 45.0, "chase": 95.0, "damage": 1, "bite_delay": 0.8, "scale": 1.0, "width": 1.0,
		"duck": 0.2, "cover": 0.3, "skin": Color("7a9a6a"), "shirt": Color("4a4a50"), "pants": Color("2a2a30"), "shoe": Color("1a1a1a"), "points": 150}


# שינויים למוח (ai/zombie_brain.gd): למשל {"aggression": 0.2, "keep_range": 260.0, "ambusher": true}
func brain_overrides() -> Dictionary:
	return {}


# true = המוח מזיז את הזומבי (APPROACH/ATTACK/FLANK/HOLD...). false = logic() אחראי לתנועה
func use_brain_movement() -> bool:
	return true


# נקרא פעם אחת אחרי _ready של הזומבי
func setup() -> void:
	pass


# שליטה מלאה (מטפס על קירות, עף, זוחל על תקרה...). להחזיר true = zombie.gd לא יזיז אותו בעצמו
# (ואז צריך לקרוא בעצמך ל-z.move_and_slide())
func physics(_player: Node, _delta: float) -> bool:
	return false


# נקרא בכל פריים שהזומבי רודף, אחרי המוח. מחזיר מהירות (אפשר לשנות גם z._dir)
func logic(_player: Node, _d: Vector2, _delta: float, speed: float) -> float:
	return speed


# איזה צליל כשהוא מת (sfx.gd). למשל MIMIC = "fwail" (יללה נשית)
func death_sound() -> String:
	return "zdeath"


# האם הוא נוהם (מתחזים - לא, כדי לא להסגיר את עצמם)
func can_groan() -> bool:
	return true


# האם הוא נושך רגיל כשהוא קרוב
func can_bite() -> bool:
	return true


# נשך את השחקן (אפשר להוסיף אפקט: לתפוס, להפיל...)
func on_bite(_player: Node) -> void:
	pass


# נפגע. להחזיר false = הפגיעה נחסמה (מגן). zone: "head" / "body" / "leg"
func on_damage(_amount: int, _hit_pos: Vector2, _dir: Vector2, _src: Dictionary) -> bool:
	return true


# מכפיל נזק (שריון, נקודת תורפה...)
func damage_mult(_zone: String, _src: Dictionary) -> float:
	return 1.0


func on_death() -> void:
	pass


# השחקן השתחרר מתפיסה (player.grab(z) -> השחקן לוחץ A/D לסירוגין -> z.release_grab())
func on_release() -> void:
	pass


# ציור. להחזיר true = ציירנו בעצמנו. false = הציור הרגיל של zombie.gd
func draw() -> bool:
	return false


# ---- עזרים לציור ----
# מסדר את הטרנספורם: גודל, היפוך לפי כיוון, סיבוב כשמת, צל על הריצפה
func begin_draw(shadow := true) -> void:
	var s := Vector2(z._dir * z.wf * z.sc, z.sc)
	if shadow and not z.dead and not z._lying() and z.is_on_floor():
		Art.ground_shadow(z, Vector2.ZERO, 14.0 * z.wf * z.sc)
	if z.dead:
		var outer := Transform2D(z._angle, Vector2(0.0, -9.0 * z.sc))
		z.draw_set_transform_matrix(outer * Transform2D(0.0, s, 0.0, Vector2(0.0, 28.0 * z.sc)))
	elif z._lying():   # שוכב (z.lie_down()) או קם לאט
		var k: float = 1.0 if z.dormant else clampf(z._rise_t / z.RISE_TIME, 0.0, 1.0)
		k = k * k * (3.0 - 2.0 * k)
		var outer := Transform2D(PI / 2.0 * z._lie_side * k, Vector2(0.0, lerpf(-28.0, -9.0, k) * z.sc))
		z.draw_set_transform_matrix(outer * Transform2D(0.0, s, 0.0, Vector2(0.0, 28.0 * z.sc)))
	else:
		z.draw_set_transform(Vector2.ZERO, 0.0, s)


func end_draw() -> void:
	z.draw_set_transform_matrix(Transform2D.IDENTITY)


# צבע: לבן כשנפגע עכשיו
func col(c: Color) -> Color:
	return Color.WHITE if z._flash > 0.0 else c


# רגליים שהולכות (מחזיר [כף קדמית, כף אחורית])
func feet(stride := 5.0, lift := 2.5) -> Array:
	var p: float = z._walk_phase
	if not z.is_on_floor() and not z.dead:
		return [Vector2(5.0, -7.0), Vector2(-4.0, -4.0)]
	return [Vector2(sin(p) * stride + 1.0, -maxf(0.0, cos(p)) * lift), Vector2(sin(p + PI) * stride - 1.0, -maxf(0.0, cos(p + PI)) * lift)]


func player() -> Node:
	return z.get_tree().get_first_node_in_group("player")


func director() -> Node:
	return z.get_tree().get_first_node_in_group("squad_director")
