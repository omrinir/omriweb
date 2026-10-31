extends "res://enemies/zombie_type.gd"
# ============================================================
#  MALLKI (שלב 36, "THE SUMMIT") - מומיית אינקה: "צרור" ישוב עטוף בשכבות אריג (כמו הצרורות שנמצאו במקדשי ההרים),
#  עם ראש מזויף (פלסה קבסה) מאריג. מתנדנד קדימה בדילוגים קצרים.
#  כל ירייה קורעת את שכבת האריג החיצונית (WRAP_HP לשכבה) - הגוף מתחת לא נפגע עד שכל WRAPS השכבות יורדות.
#  כל שכבה שיורדת = יותר מהר. בלי שכבות: מומיה יבשה ומהירה (x1.3).
#  "THEY LEARNED TO HEAL": לא יורים בו REWRAP_T שניות -> אוסף את האריג ומתעטף מחדש בשכבה. לא להפסיק לירות!
#  אש שורפת את כל האריג בבת אחת (+ נזק). פיצוץ = 2 שכבות.
#  לשנות: WRAPS, WRAP_HP, REWRAP_T.
# ============================================================

const SOUNDS := {
	"mk_rip": [["N", 0, 0, 0.0, 0.18, 0.0, 14.0, 0.5, 0.35, 0, 0.7], ["N", 0, 0, 0.06, 0.12, 0.0, 18.0, 0.3, 0.5, 0, 0.6]],
	"mk_wrap": [["N", 0, 0, 0.0, 0.5, 0.1, 3.0, 0.25, 0.25, 0, 0.6], ["S", 300, 260, 0.0, 0.4, 0.1, 4.0, 0.1, 1.0, 0.05]],
	"mk_rattle": [["C", 0, 0, 0.0, 0.05, 0.0, 50.0, 0.4, 1.0, 0], ["C", 0, 0, 0.08, 0.05, 0.0, 50.0, 0.3, 1.0, 0], ["C", 0, 0, 0.15, 0.05, 0.0, 50.0, 0.3, 1.0, 0]],
}

const WRAPS := 4
const WRAP_HP := 13
const REWRAP_T := 3.0
const WRAP_COLS := [Color("b03a2a"), Color("d0a040"), Color("2a5a8a"), Color("c8b898")]

var wraps := WRAPS
var wrap_hp := WRAP_HP
var rips := 0                # לבדיקות
var rewraps := 0
var _calm := 0.0
var _wrap_anim := 0.0
var _hop := 0.0
var _base := Vector2.ZERO   # מהירויות בסיס (הליכה, רדיפה) - אחרי קושי


func stats() -> Dictionary:
	return {"name": "MALLKI", "hp": 26, "walk": 30.0, "chase": 52.0, "damage": 1, "bite_delay": 0.8, "scale": 1.0, "width": 1.2,
		"duck": 0.0, "cover": 0.0, "skin": Color("6a5440"), "shirt": Color("c8b898"), "pants": Color("4a3a2a"), "shoe": Color("4a3a2a"), "points": 480}


func setup() -> void:
	_base = Vector2(float(z.walk_speed), float(z.chase_speed))


func brain_overrides() -> Dictionary:
	return {"aggression": 0.8}


func on_damage(amount: int, hit_pos: Vector2, _dir: Vector2, src: Dictionary) -> bool:
	var s := str(src.get("source", "bullet"))
	_calm = 0.0
	if wraps <= 0:
		return true
	if s in ["fire", "flame", "molotov"]:   # אריג נשרף
		wraps = 0
		Particles.burst(z.get_parent(), z.global_position + Vector2(0, -26), "fire", Vector2.UP, 14)
		z._popup("THE CLOTH BURNS", Color("ffb060"), 13, -80.0)
		_speed()
		return true
	if s in ["grenade", "explosion", "dynamite", "mine", "barrel", "artillery", "boss_lob"]:
		_rip()
		_rip()
		return true
	wrap_hp -= maxi(hit_damage(amount, hit_pos, src), 1)
	Particles.burst(z.get_parent(), hit_pos, "leaf", Vector2.UP, 2)
	while wrap_hp <= 0 and wraps > 0:
		var over := -wrap_hp
		_rip()
		wrap_hp -= over
	return false


func _rip() -> void:
	if wraps <= 0:
		return
	wraps -= 1
	rips += 1
	wrap_hp = WRAP_HP
	Sfx.play("mk_rip", z.global_position, -2.0, 0.15, 3)
	var cloth := Cloth.new()
	cloth.col = WRAP_COLS[clampi(wraps, 0, WRAP_COLS.size() - 1)]
	z.get_parent().add_child(cloth)
	cloth.global_position = z.global_position + Vector2(0, -26)
	cloth.vel = Vector2(randf_range(-90, 90), randf_range(-220, -140))
	if wraps == 0:
		z._popup("UNWRAPPED", Color("e0d0a0"), 13, -80.0)
		Sfx.play("mk_rattle", z.global_position, 0.0, 0.1, 2)
	_speed()


func _speed() -> void:
	var k := 1.0 + float(WRAPS - wraps) * 0.15
	z.walk_speed = _base.x * k
	z.chase_speed = _base.y * k


func damage_mult(_zone: String, _src: Dictionary) -> float:
	return 1.3 if wraps == 0 else 1.0


func physics(_pl: Node, delta: float) -> bool:
	_calm += delta
	_wrap_anim = maxf(_wrap_anim - delta, 0.0)
	_hop += delta
	if not z.dead and wraps < WRAPS and _calm > REWRAP_T:   # מתעטף מחדש
		_calm = 0.0
		wraps += 1
		wrap_hp = WRAP_HP
		rewraps += 1
		_wrap_anim = 0.6
		Sfx.play("mk_wrap", z.global_position, -2.0, 0.1, 2)
		z._popup("IT WRAPS ITSELF AGAIN", Color("e0c080"), 12, -80.0)
		_speed()
	return false


class Cloth extends Node2D:   # רצועת אריג שנקרעת ועפה
	var col := Color.RED
	var vel := Vector2.ZERO
	var _t := 0.0

	func _ready() -> void:
		z_index = 6

	func _process(delta: float) -> void:
		_t += delta
		vel.y += 500.0 * delta
		vel.x *= 1.0 - 1.2 * delta
		position += vel * delta
		rotation += 4.0 * delta
		if _t > 1.2:
			queue_free()
			return
		queue_redraw()

	func _draw() -> void:
		DrawBatch.begin(self)
		_draw_b()
		DrawBatch.end(self)

	func _draw_b() -> void:
		var a := clampf(1.5 - _t, 0.0, 1.0)
		var w := sin(_t * 14.0) * 3.0
		DrawBatch.polyline(self, PackedVector2Array([Vector2(-10, 0), Vector2(-4, w), Vector2(3, -w), Vector2(10, w * 0.5)]), Color(col, a), 4.0)


# ============================================================
#  ציור: צרור ישוב (חצי ביצה) עטוף בפסים צבעוניים, ראש מזויף מאריג עם פני נוצות;
#  כל שכבה שיורדת חושפת את הבאה. בלי שכבות: מומיה כפופה מצומקת עם שיער שחור ארוך
# ============================================================
func draw() -> bool:
	begin_draw()
	var sk := col(z.skin)
	var bob := absf(sin(_hop * 6.0)) * 3.0 if absf(z.velocity.x) > 5.0 else 0.0
	if wraps <= 0:   # מומיה חשופה
		var p: float = z._walk_phase
		var f: Array = feet(4.0, 2.0)
		var hip := Vector2(0, -20)
		var sh := Vector2(4, -33)
		var head := sh + Vector2(5, -6)
		z._leg(hip + Vector2(-2, 0), f[1], sk.darkened(0.2), sk, sk)
		z._leg(hip + Vector2(2, 0), f[0], sk, sk, sk)
		z._arm(sh + Vector2(-2, 1), sh + Vector2(-4.0 - sin(p) * 2.0, 14.0), sk.darkened(0.2), sk.darkened(0.2))
		Art.fill_shaded(z, PackedVector2Array([sh + Vector2(-6, -1), sh + Vector2(6, 0), hip + Vector2(5, 2), hip + Vector2(-5, 2)]), sk, 0.2, 0.45)
		for q in 4:   # צלעות
			DrawBatch.line(z, sh + Vector2(-4, 3.0 + float(q) * 3.0), sh + Vector2(4, 4.0 + float(q) * 3.0), sk.darkened(0.35), 1.0)
		Art.oval_shaded(z, head, 4.6, 5.4, sk, 0.0)
		DrawBatch.colored_polygon(z, PackedVector2Array([head + Vector2(-5, -3), head + Vector2(3, -6), head + Vector2(-2, 14), head + Vector2(-7, 12)]), col(Color("141010")))   # שיער ארוך
		if not z.dead:
			DrawBatch.circle(z, head + Vector2(2.5, -1.0), 1.2, Color(1.0, 0.8, 0.4))
		DrawBatch.line(z, head + Vector2(1, 3), head + Vector2(5, 3.5), col(Color("2a1a10")), 1.5)
		z._arm(sh + Vector2(2, 1), sh + Vector2(12, 4), sk, sk)
		end_draw()
		return true
	# הצרור
	var base := Vector2(0, -bob)
	var w := 13.0 + float(wraps) * 1.5
	var h := 34.0 + float(wraps) * 2.0
	var bundle := PackedVector2Array()
	for q in 15:
		var a := PI + float(q) / 14.0 * PI
		bundle.append(base + Vector2(cos(a) * w, sin(a) * h * 0.9))
	var outer: Color = WRAP_COLS[clampi(wraps - 1, 0, WRAP_COLS.size() - 1)]
	Art.fill_shaded(z, bundle, col(outer), 0.18, 0.45)
	for q in 5:   # פסי אריג / חבלים
		var yy := -4.0 - float(q) * h * 0.17 - bob
		var hw := w * sqrt(maxf(1.0 - pow((yy + bob) / (h * 0.9), 2.0), 0.0))
		DrawBatch.line(z, Vector2(-hw, yy), Vector2(hw, yy - 1.0), col(outer.darkened(0.35)), 1.4)
	if wraps >= 2:   # דוגמת טוקאפו (ריבועים)
		for q in 3:
			DrawBatch.rect(z, Rect2(-6.0 + float(q) * 5.0, -h * 0.45 - bob, 3.5, 3.5), col(Color("e0c060") if q % 2 == 0 else Color("1a1a1a")))
	# ראש מזויף מאריג
	var head := base + Vector2(3, -h * 0.9 - 5.0)
	Art.oval_shaded(z, head, 6.0, 6.5, col(Color("c8b898")), 0.0)
	DrawBatch.rect(z, Rect2(head + Vector2(-1, -2), Vector2(6, 2)), col(Color("6a4a2a")))
	if not z.dead:   # עיניים מבעד לאריג
		DrawBatch.circle(z, head + Vector2(2.5, 1.0), 1.4, Color(1.0, 0.8, 0.35))
	DrawBatch.line(z, head + Vector2(-5, -5), head + Vector2(-9, -11), col(Color("2a6a4a")), 2.0)   # נוצה
	DrawBatch.line(z, head + Vector2(-3, -6), head + Vector2(-4, -13), col(Color("e0b030")), 2.0)
	if _wrap_anim > 0.0:   # מתעטף: רצועה מסתובבת
		var a := _wrap_anim * 20.0
		DrawBatch.arc(z, base + Vector2(0, -h * 0.4), w + 3.0, a, a + 2.5, 8, col(WRAP_COLS[clampi(wraps - 1, 0, 3)]), 3.0)
	end_draw()
	return true
