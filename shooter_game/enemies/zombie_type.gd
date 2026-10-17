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


# הנזק האמיתי של פגיעה, לפני on_damage. (קליעים שולחים amount = 0 - zombie.gd take_damage מחשב לפי מקום הפגיעה:
# ראש / גוף / רגל, "fixed" של שוטגאן/חץ, dmg_mult של הנשק). להשתמש בזה במגנים / שריונים / נקודות תורפה.
func hit_damage(amount: int, hit_pos: Vector2, src: Dictionary) -> int:
	if src.has("fixed"):
		return int(src.fixed)
	var s := str(src.get("source", "bullet"))
	if not (s == "bullet" or s == "melee"):
		return amount
	var ly: float = (hit_pos.y - z.global_position.y) / z.sc
	var dmg := 0
	if ly < -42.0:
		dmg = int(z.head_damage)
		if float(src.get("head_mult", 1.0)) < 1.0:
			dmg = maxi(1, int(round(float(dmg) * float(src.head_mult))))
	else:
		var r: Vector2i = z.leg_damage if ly > -20.0 else z.body_damage
		dmg = (r.x + r.y) / 2
		if src.has("dmg_mult"):
			dmg = maxi(1, int(round(float(dmg) * float(src.dmg_mult))))
	if src.get("sniper", false):
		dmg *= 2
	if src.get("god", false):
		dmg *= 4
	return maxi(dmg, amount)


# מכפיל נזק (שריון, נקודת תורפה...)
func damage_mult(_zone: String, _src: Dictionary) -> float:
	return 1.0


func on_death() -> void:
	pass


# השחקן השתחרר מתפיסה (player.grab(z) -> השחקן לוחץ A/D לסירוגין -> z.release_grab())
func on_release() -> void:
	pass


# false = הציור לא השתנה, לא צריך לצייר מחדש בפריים הזה (חוסך ביצועים לזומבי שעומד בלי לזוז)
func wants_redraw() -> bool:
	return true


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
	else:   # (תגובת פגיעה: כל הגוף נוטה / קופץ מסביב לרגליים - zombie.gd react_tilt)
		z.draw_set_transform_matrix(Transform2D(z.react_tilt(), Vector2(0.0, z.react_hop() * z.sc)) * Transform2D(0.0, s, 0.0, Vector2.ZERO))


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


# פנים של זומבי לראש פשוט (רדיוס ~5.5, פונה ימינה): ארובה שקועה, לסת פתוחה עם שיניים, ריקבון בלחי (לפי z._det),
# והילה עמומה סביב העין (eye = מיקום העין יחסית לראש; INF = בלי). לקרוא אחרי ציור הראש ולפני הכובע / העין
func face(head: Vector2, eye := Vector2(3.5, -0.5)) -> void:
	Art.oval(z, head + Vector2(2.8, -0.6), 2.3, 1.7, Color(0.12, 0.0, 0.04, 0.45), 0.0, Art.NONE)
	var o: float = 1.6 if z._bite_anim > 0.0 else 0.0
	z.draw_colored_polygon(PackedVector2Array([head + Vector2(1.2, 2.4), head + Vector2(5.2, 1.9), head + Vector2(4.8, 4.2 + o), head + Vector2(1.6, 4.2 + o * 0.7)]), col(Color("2a0a0c")))
	z.draw_line(head + Vector2(1.9, 2.6), head + Vector2(4.8, 2.2), col(Color("d8d0a8")), 0.8)
	if z._det[5]:
		Art.oval(z, head + Vector2(-1.2, 1.8), 1.5, 1.1, Color(0.42, 0.05, 0.05, 0.85), 0.0, Art.NONE)
	if eye.x < INF and not z.dead:
		Art.glow(z, head + eye, 3.0, Color(1.0, 0.45, 0.15, 0.45))


func player() -> Node:
	return z.get_tree().get_first_node_in_group("player")


func director() -> Node:
	return z.get_tree().get_first_node_in_group("squad_director")
