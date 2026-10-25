extends "res://enemies/zombie_type.gd"
const Parts := preload("res://characters/parts.gd")
const CharBones := preload("res://effects/char_bones.gd")
# ============================================================
#  CUSTOM CHARACTER - סוג זומבי שנבנה ב-CHARACTER MAKER (characters/maker.tscn) ונשמר בקובץ
#  characters/saved/<id>.tres (characters/character_preset.gd). מספר הסוג (kind) מ-1000.
#  מצויר בגוף הרגיל של zombie.gd (base_body() = true), ולכן כל הגור עובד כמו בזומבי רגיל:
#  ירייה בראש והראש עף, נקרע לשניים, מתפוצץ, נשרף עד העצמות, זוחל בלי רגליים, גופה רכה.
#  החלקים (שיער, כובע, פנים, בגדים, חפץ ביד) מצוירים מ-characters/parts.gd דרך הפונקציות draw_* למטה,
#  ש-zombie.gd קורא להן מתוך _draw_body / _cust_head.
# ============================================================

var preset: Resource = null
var big := false          # גוף רחב (כמו BRUTE): ידיים עבות, ראש רחב
var thin := false         # גוף צר (כמו RUNNER): צעדים ארוכים, ידיים מתנופפות בריצה
var sleeves := true       # חולצה עם שרוולים (לא גופייה / אוברול / בלי חולצה)
var torso := "walker"     # איזה גוף של zombie.gd מתחת לבגד (parts.gd torso_base)
var head_k := 1.0
var eye_col := Color(1.0, 0.85, 0.25, 0.8)
var hair_col := Color("3a3026")
var _st := {}
var _tone := Callable()


func bind(p: Resource) -> void:
	preset = p
	big = p.build == "big"
	thin = p.build == "skinny"
	torso = Parts.torso_base(p.top)
	sleeves = Parts.has_sleeves(p.top)
	head_k = p.head_size
	eye_col = Color(p.eye_color, 0.85)
	hair_col = p.hair_color
	_tone = tone
	_st = _make_stats()


func _make_stats() -> Dictionary:
	var p = preset
	var s := Vector2.ONE   # גודל / רוחב בסיסי לפי המבנה (כמו WALKER / RUNNER / BRUTE ב-zombie.gd KINDS)
	if big:
		s = Vector2(1.075, 1.35)
	elif thin:
		s = Vector2(0.97, 0.85)
	return {"name": p.name, "hp": p.hp, "walk": p.walk_speed, "chase": p.run_speed, "damage": p.damage, "bite_delay": p.bite_delay,
		"scale": s.x * p.height, "width": s.y * p.width, "duck": p.duck, "cover": p.cover,
		"skin": p.skin_color, "shirt": p.skin_color if p.top == "bare" else p.shirt_color, "pants": p.pants_color,
		"shoe": Color(p.shoe_color, 0.0) if p.barefoot else p.shoe_color,
		"points": p.points, "boss": p.boss, "ragdoll": true}


func stats() -> Dictionary:
	return _st


func base_body() -> bool:
	return true


func setup() -> void:
	var p = preset
	if p.variety:   # כל זומבי קצת שונה (כמו zombie.gd _vary), אבל נשאר הדמות שבנית
		var r := RandomNumberGenerator.new()
		r.seed = z.get_instance_id()
		z.skin = Art.shade(p.skin_color, r.randf_range(-0.07, 0.07))
		var sc: Color = p.shirt_color
		z.shirt = Color.from_hsv(fposmod(sc.h + r.randf_range(-0.04, 0.04), 1.0), clampf(sc.s * r.randf_range(0.85, 1.15), 0.0, 1.0), sc.v)
		z.pants = Art.shade(p.pants_color, r.randf_range(-0.04, 0.08))
		hair_col = Art.shade(p.hair_color, r.randf_range(-0.1, 0.1))
	else:
		z.skin = p.skin_color
		z.shirt = p.shirt_color
		z.pants = p.pants_color
		hair_col = p.hair_color
	if p.top == "bare":   # בלי חולצה: הגופה הרכה / הקרעים בצבע העור
		z.shirt = z.skin
	z.hair = hair_col
	z._bald = p.hair == "none"
	z._gore_arm = p.has_gore("bone_arm")
	z._det = [p.has_gore("rot"), p.has_gore("chest_stitches"), p.has_gore("flesh"), z._det[3], z._det[4], p.has_gore("cheek")]
	z._vp = clampf(z._vp * p.voice, 0.5, 1.6)
	z.chase_range = p.notice


# כמה הגוף רכון קדימה (zombie.gd _draw_body)
func lean() -> float:
	var l: float = preset.hunch
	if thin and running():
		l += 4.0
	return l


func running() -> bool:
	return z._chasing or z._cover_state == 1 or z.goal_x < INF


# צבע של חלק: לבן כשנפגע, משחיר כשנשרף (כמו הגוף - effects/char_bones.gd)
func tone(c: Color) -> Color:
	if z == null or not is_instance_valid(z):
		return c
	if z._flash > 0.0:
		return Color(1.0, 1.0, 1.0, c.a)
	if z._char != null:
		return c.lerp(Color(CharBones.CHAR_COL, c.a), clampf(z._char.t / CharBones.CHAR_T * 1.3, 0.0, 1.0))
	return c


# ---- ציור (zombie.gd קורא להן; הטרנספורם כבר מסודר) ----
# מאחורי הגוף: תיק גב
func draw_back(sh: Vector2) -> void:
	Parts.back_gear(z, preset.extras, sh, preset.gear_color, _tone)


# מעל הגוף: הבגד והתוספות
func draw_torso(sh: Vector2, hip: Vector2, sk: Color, shirt_c: Color) -> void:
	Parts.torso_over(z, preset.top, preset.extras, preset.gore, sh, hip, sk, shirt_c, preset.gear_color, _tone, z._time, z._legless, preset.hat, z.lod())


# חפץ ביד הקדמית. d = כיוון הזרוע
func draw_hand(hand: Vector2, d: Vector2) -> void:
	Parts.item(z, preset.item, hand, d, _tone, z._time, z.lod())


# ראש: (0,0) = מרכז הראש (zombie.gd _cust_head מסדר את הטרנספורם)
func draw_hair_back() -> void:
	Parts.hair_back(z, preset.hair, hair_col, _tone, z._time, preset.hat)


func draw_hair_front() -> void:
	Parts.hair_front(z, preset.hair, hair_col, _tone, Parts.COVERS.has(preset.hat))


func draw_head_gear(lo: bool) -> void:
	if not Parts.COVERS.has(preset.hat):
		if preset.has_gore("head_wound"):   # פצע פתוח בראש
			Art.oval(z, Vector2(-1.0, -4.5), 2.2, 1.4, Color("7a0a0a"), 0.4, Art.NONE)
			Art.oval(z, Vector2(-0.8, -4.4), 1.0, 0.6, Color("2a0303"), 0.4, Art.NONE)
			DrawBatch.line(z, Vector2(-0.2, -3.4), Vector2(0.2, -1.2), Color(0.45, 0.03, 0.03, 0.8), 0.8, true)
		if preset.has_gore("scalp_stitches"):   # תפרים על הקרקפת
			DrawBatch.polyline(z, PackedVector2Array([Vector2(-5.0, -4.0), Vector2(-1.0, -6.5), Vector2(3.0, -6.8)]), Color("3a1a1a"), 1.0, true)
			for i in 4:
				var q := Vector2(-4.0 + float(i) * 2.2, -4.8 - float(i) * 0.6)
				DrawBatch.line(z, q + Vector2(-0.6, -1.0), q + Vector2(0.6, 1.0), Color("3a1a1a"), 0.8, true)
	Parts.face(z, preset.face, eye_col, _tone, lo)
	if preset.hat != "none":
		Parts.hat(z, preset.hat, preset.hat_color, eye_col, _tone, z._time, lo)


# הראש העף / הגופה הרכה (effects/flying_head.gd, effects/ragdoll.gd): שיער וכובע בלי האנימציה של החי
func draw_dead_head(ci: CanvasItem, back: bool) -> void:
	var same := func(c: Color) -> Color: return c
	if back:
		Parts.hair_back(ci, preset.hair, hair_col, same, 0.0, preset.hat)
		return
	Parts.hair_front(ci, preset.hair, hair_col, same, Parts.COVERS.has(preset.hat))
	if preset.face in ["gasmask", "surgical", "bandages", "clown", "eyepatch"]:   # (משקפיים עפים במכה)
		Parts.face(ci, preset.face, Color(0.2, 0.2, 0.2), same, true)
	if preset.hat != "none":
		Parts.hat(ci, preset.hat, preset.hat_color, Color(0.2, 0.2, 0.2), same, 0.0, true)
