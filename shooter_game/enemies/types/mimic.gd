extends "res://enemies/zombie_type.gd"
# ============================================================
#  MIMIC (שלב 12, צפון-מזרח) - נראית בדיוק כמו הניצולה (survivor.gd): אותם בגדים, שיער, ריצה,
#    אותה צעקה "HELP!". לא נוהמת. רצה אליך כמו ניצולה אמיתית...
#  באמצע הדרך (המרחק ירד לחצי ממה שהיה כשהיא ראתה אותך) - היא נעצרת ומתעוותת (MORPH_T):
#    הגוף נמתח וגדל, העור מאפיר, הלסת נקרעת לאורך הפנים עד החזה ומלאה שיניים,
#    הידיים מתארכות עם טפרים, העיניים זוהרות. ואז רודפת מהר ונושכת חזק (HUNT).
#  הוגן: יורים בה לפני השינוי = היא מתגלה ומשתנה מיד (וגם ניצולה אמיתית נפגעת מירי - צריך להחליט).
#    רמז קטן: כל כמה שניות הראש שלה "קופץ" בתנועה לא טבעית לשבריר שנייה.
#    HUNTER'S SIGHT (יכולת) מראה אותה כזומבי.
#  צלילים: "mm_morph" (עצמות נשברות + צווחה), "mm_shriek".
#  לשנות: MORPH_T, HALFWAY (0.5 = באמצע הדרך), RUN.
# ============================================================

const SOUNDS := {
	"mm_morph": [["C", 0, 0, 0.0, 0.9, 0.0, 2.0, 0.7, 1.0, 0], ["N", 0, 0, 0.0, 0.25, 0.0, 12.0, 0.6, 0.4, 0], ["N", 0, 0, 0.35, 0.2, 0.0, 12.0, 0.6, 0.4, 0], ["W", 300, 90, 0.2, 0.9, 0.05, 2.5, 0.35, 0.4, 0.6]],
	"mm_shriek": [["W", 1400, 700, 0.0, 0.6, 0.02, 3.0, 0.4, 0.55, 0.5], ["S", 2100, 900, 0.0, 0.5, 0.02, 4.0, 0.25, 1.0, 0.6], ["N", 0, 0, 0.0, 0.5, 0.02, 4.0, 0.3, 0.7, 0]],
}

const VARIANTS := [   # בדיוק כמו survivor.gd
	{"hair": Color("4a2a1a"), "top": Color("8a2f3c"), "pants": Color("34405a"), "skin": Color("e6b48e"), "boots": Color("2a1d16")},
	{"hair": Color("d0a24e"), "top": Color("2f5e50"), "pants": Color("2c2c33"), "skin": Color("f0c6a0"), "boots": Color("3a2a20")},
	{"hair": Color("161112"), "top": Color("5a4a80"), "pants": Color("4a3a2a"), "skin": Color("a8744e"), "boots": Color("1c1614")},
]
const NOTICE := 620.0
const HALFWAY := 0.5
const RUN := 170.0          # כמו הניצולה
const MORPH_T := 1.1

enum { IDLE, LURE, MORPH, HUNT }
var state := IDLE
var morphs := 0             # לבדיקות
var _v := -1
var _c: Dictionary
var _d0 := 0.0
var _st := 0.0
var _m := 0.0               # 0 = ילדה, 1 = מפלצת
var _phase := 0.0
var _twitch := 0.0
var _twitch_cd := 4.0


func stats() -> Dictionary:
	if _v < 0:
		_v = randi() % 3
		_c = VARIANTS[_v]
	return {"name": "MIMIC", "hp": 34, "walk": 60.0, "chase": 150.0, "damage": 2, "bite_delay": 0.7, "scale": 0.97, "width": 0.5,
		"duck": 0.0, "cover": 0.0, "skin": _c.skin, "shirt": _c.top, "pants": _c.pants, "shoe": _c.boots, "points": 400}


func brain_overrides() -> Dictionary:
	return {"aggression": 0.5}


func can_groan() -> bool:
	return state == HUNT


func can_bite() -> bool:
	return state == HUNT


func setup() -> void:
	z.skin = _c.skin   # בלי הגוון האקראי של זומבים - צבעים מדויקים של ניצולה
	z.shirt = _c.top


func on_damage(_amount: int, _hit_pos: Vector2, _dir: Vector2, _src: Dictionary) -> bool:
	if state == IDLE or state == LURE:   # נחשפה
		_start_morph()
	return true


func _start_morph() -> void:
	state = MORPH
	_st = MORPH_T
	morphs += 1
	Sfx.play("mm_morph", z.global_position, 3.0, 0.05, 2)
	var cam: Node = z.get_viewport().get_camera_2d()
	if cam != null and cam.has_method("shake") and Art.on_screen(z, z.global_position):
		cam.shake(5.0, 0.6)


func physics(pl: Node, delta: float) -> bool:
	_twitch = maxf(_twitch - delta, 0.0)
	_twitch_cd -= delta
	if _twitch_cd <= 0.0 and state != HUNT:
		_twitch_cd = randf_range(3.0, 6.0)
		_twitch = 0.09
	if not z.is_on_floor():
		z.velocity.y += z.gravity * delta
	match state:
		IDLE:
			z.velocity.x = 0.0
			if pl != null and not pl.dead and absf(pl.global_position.x - z.global_position.x) < NOTICE and absf(pl.global_position.y - z.global_position.y) < 200.0:
				state = LURE
				_d0 = absf(pl.global_position.x - z.global_position.x)
				z._popup("HELP!", Color("f4f0e8"), 16, -70.0)
		LURE:
			if pl == null or pl.dead:
				z.velocity.x = move_toward(z.velocity.x, 0.0, 800.0 * delta)
			else:
				var dx: float = pl.global_position.x - z.global_position.x
				z._dir = signf(dx) if dx != 0.0 else z._dir
				z.velocity.x = move_toward(z.velocity.x, RUN * z._dir, 1200.0 * delta)
				if z.is_on_wall() and z.is_on_floor():
					z.velocity.y = -560.0
				if absf(dx) <= maxf(_d0 * HALFWAY, 70.0):
					_start_morph()
		MORPH:
			z.velocity.x = move_toward(z.velocity.x, 0.0, 1000.0 * delta)
			_st -= delta
			_m = clampf(1.0 - _st / MORPH_T, 0.0, 1.0)
			if _st <= 0.0:
				state = HUNT
				_m = 1.0
				z.sc *= 1.3   # גבוהה ומאיימת
				z.wf = 1.0
				var r := z._shape.shape as RectangleShape2D
				r.size = Vector2(38.0 * z.wf, 66.0 * z.sc)
				z._shape.position = Vector2(0.0, -33.0 * z.sc)
				z.skin = Color("8a9088")
				Sfx.play("mm_shriek", z.global_position, 4.0, 0.05, 2)
				z._voice("zscream", 1.0, 4.0)
		HUNT:
			return false
	z.move_and_slide()
	if z.is_on_floor():
		_phase += delta * absf(z.velocity.x) * 0.075
	return true


# ============================================================
#  ציור: הניצולה (העתק של survivor.gd -> _draw_woman), ובשינוי - המפלצת
# ============================================================
func draw() -> bool:
	var m := _m
	var size: float = z.sc
	var jit := Vector2.ZERO
	if state == MORPH:   # עוויתות
		jit = Vector2(randf_range(-1.5, 1.5), randf_range(-1.0, 1.0)) * (1.0 + 2.0 * m)
	if z.is_on_floor():
		Art.ground_shadow(z, Vector2.ZERO, 11.0 * size)
	var base := Transform2D(0.0, Vector2(z._dir * size / (1.0 + 0.3 * (1.0 if state == HUNT else 0.0)) * (1.0 + 0.3 * m), size / (1.0 + 0.3 * (1.0 if state == HUNT else 0.0)) * (1.0 + 0.3 * m)), 0.0, jit)
	z.draw_set_transform_matrix(base)
	var gray := Color("8a9088")
	var skin: Color = (_c.skin as Color).lerp(gray, m)
	var hair: Color = (_c.hair as Color).lerp(Color("2a2a26"), m * 0.7)
	var top: Color = (_c.top as Color).lerp((_c.top as Color).darkened(0.5), m)
	var pants: Color = (_c.pants as Color).lerp((_c.pants as Color).darkened(0.4), m)
	var boots: Color = _c.boots
	if z._flash > 0.0:
		skin = Color.WHITE
		top = Color.WHITE
	var p: float = _phase if state == LURE else z._walk_phase
	var running: bool = (state == LURE or (state == HUNT and absf(z.velocity.x) > 20.0)) and z.is_on_floor()
	var lean := (5.0 if running else 0.0) + 6.0 * m
	var breath := sin(z._time * 2.0) * 0.4
	var hip := Vector2(0, -24.0 - (absf(sin(p)) * 1.5 if running else 0.0))
	var sh := Vector2(lean + 1.0, -40.0 + hip.y + 24.0 - breath * 0.5)
	sh += Vector2(2.0, -6.0) * m   # הגו נמתח ונשמט קדימה
	var head := sh + Vector2(2.0 + 4.0 * m, -7.5 + 3.0 * m)
	if _twitch > 0.0:   # הרמז: קפיצה לא טבעית של הראש
		head += Vector2(2.5, -1.5)
	var f1 := Vector2(1.0, 0.0)
	var f2 := Vector2(-2.0, 0.0)
	if running:
		var st := 9.0 + 4.0 * m
		f1 = Vector2(sin(p) * st + 2.0, -maxf(0.0, cos(p)) * 5.0)
		f2 = Vector2(sin(p + PI) * st, -maxf(0.0, cos(p + PI)) * 5.0)
	elif not z.is_on_floor():
		f1 = Vector2(5.0, -8.0)
		f2 = Vector2(-4.0, -5.0)
	var bs := sh + Vector2(-2.0, 1.5)
	var fs := sh + Vector2(2.0, 1.5)
	var reach := 1.0 + 0.9 * m   # ידיים מתארכות
	var bh := bs + Vector2(-2.0, 15.0) * reach
	var fh := fs + Vector2(3.0, 15.0) * reach
	if running:
		bh = bs + Vector2(-sin(p) * 9.0, 12.0) * reach
		fh = fs + Vector2(sin(p) * 9.0 + 2.0, 11.0) * reach
	if state == MORPH:
		fh = fs + Vector2(10.0 + sin(z._time * 30.0) * 3.0, -6.0) * reach
		bh = bs + Vector2(-8.0, -4.0 + cos(z._time * 27.0) * 3.0) * reach
	elif state == HUNT:
		fh = fs + Vector2(16.0, 6.0 + sin(z._time * 8.0) * 3.0)
	# שיער ארוך מאחור
	var sway := sin(z._time * (12.0 if running else 2.0)) * (3.0 if running else 1.0)
	var tail := PackedVector2Array([head + Vector2(-5.0, -3.0), head + Vector2(-10.0 - lean, 3.0 + sway * 0.5), head + Vector2(-13.0 - lean * 1.6, 12.0 + sway + 8.0 * m)])
	Art.limb(z, tail, 4.5, hair)
	_arm(bs, bh, Art.shade(skin, 0.15), Art.shade(top, 0.15), m)
	_leg(hip + Vector2(-1.5, 0), f2, Art.shade(pants, 0.2), Art.shade(boots, 0.2))
	_leg(hip + Vector2(1.5, 0), f1, pants, boots)
	var body := PackedVector2Array([
		sh + Vector2(-6.5, -0.5), sh + Vector2(6.0, 0.0), sh + Vector2(6.8, 4.5), hip + Vector2(4.5, -7.0),
		hip + Vector2(6.0, 1.0), hip + Vector2(-6.0, 1.0), hip + Vector2(-4.5, -7.0), sh + Vector2(-7.0, 4.0),
	])
	Art.fill_shaded(z, body, top, 0.15, 0.3, Art.OUTLINE, 1.2)
	z.draw_line(hip + Vector2(-6.0, -1.0), hip + Vector2(6.0, -1.0), Art.shade(pants, 0.3), 2.0, true)
	if m > 0.05:   # צלעות / עמוד שדרה בולטים מבעד לחולצה הקרועה
		for i in 3:
			var y := sh.y + 4.0 + float(i) * 3.5
			z.draw_line(Vector2(sh.x - 4.0, y), Vector2(sh.x + 3.0, y + 1.0), Color(0.75, 0.75, 0.7, m * 0.8), 1.0)
	Art.limb(z, PackedVector2Array([sh + Vector2(1.0, 0.0), head + Vector2(-0.5, 4.0)]), 3.4 + m, skin)
	# ראש
	Art.oval(z, head + Vector2(-1.5, -1.5), 6.6, 6.8, hair)
	Art.oval_shaded(z, head, 5.6, 6.4 + 1.5 * m, skin, 0.0, Art.OUTLINE, 1.1)
	if m < 0.5:
		Art.fill(z, PackedVector2Array([head + Vector2(-6.0, -1.0), head + Vector2(-5.0, -6.0), head + Vector2(0.0, -7.5), head + Vector2(5.5, -5.0), head + Vector2(4.5, -3.0), head + Vector2(0.0, -4.0), head + Vector2(-3.0, 1.0)]), hair, Art.OUTLINE, 1.0)
	var eye := head + Vector2(3.0, -0.8)
	if m < 0.3:
		Art.oval(z, eye, 0.9, 1.2, Color("1a1010"), 0.0, Art.NONE)
		z.draw_line(eye + Vector2(-0.6, -1.3), eye + Vector2(1.6, -1.8), Color("1a1010"), 0.7, true)
		z.draw_line(head + Vector2(3.0, 3.4), head + Vector2(4.6, 3.2), Color("a8404a"), 1.1, true)
		z.draw_circle(head + Vector2(-1.0, 2.0), 0.7, Color("d8c070"))
	else:   # עיניים לבנות זוהרות
		Art.glow(z, eye, 4.0 * m, Color(1.0, 0.95, 0.85, 0.6 * m))
		z.draw_circle(eye, 1.3, Color(1.0, 1.0, 0.95))
	if m > 0.1:   # הלסת נקרעת לאורך הפנים עד החזה, שורות שיניים
		var top_p := head + Vector2(4.5, 1.0)
		var bot_p := sh + Vector2(6.0, 8.0 * m)
		var w := 3.5 * m
		var dirv := (bot_p - top_p).normalized()
		var nrm := Vector2(-dirv.y, dirv.x)
		var mid := top_p.lerp(bot_p, 0.5)
		Art.fill(z, PackedVector2Array([top_p, mid + nrm * w, bot_p, mid - nrm * w]), Color("3a040a"), Art.OUTLINE, 0.9)
		for i in 6:
			var u := 0.12 + float(i) * 0.15
			var c := top_p.lerp(bot_p, u)
			var wk := sin(u * PI) * w
			z.draw_colored_polygon(PackedVector2Array([c + nrm * wk, c + nrm * wk + dirv * 1.2, c + nrm * (wk - 2.2)]), Color(0.95, 0.92, 0.8, m))
			z.draw_colored_polygon(PackedVector2Array([c - nrm * wk, c - nrm * wk + dirv * 1.2, c - nrm * (wk - 2.2)]), Color(0.95, 0.92, 0.8, m))
	_arm(fs, fh, skin, top, m)
	z.draw_set_transform_matrix(Transform2D.IDENTITY)
	return true


func _arm(shoulder: Vector2, hand: Vector2, skin: Color, sleeve: Color, m: float) -> void:
	var l := 8.0 * (1.0 + 0.9 * m)
	var elbow := Art.joint(shoulder, hand, l, l, -1.0)
	var cuff := shoulder.lerp(elbow, 0.55 - 0.3 * m)
	Art.limb(z, PackedVector2Array([cuff, elbow, hand]), 3.4, skin)
	Art.limb(z, PackedVector2Array([shoulder, cuff]), 4.2, sleeve)
	Art.disc(z, hand, 2.0, skin, Art.OUTLINE, 0.9)
	if m > 0.3:   # טפרים
		var d := (hand - elbow).normalized()
		for i in 3:
			var a := d.rotated(-0.5 + float(i) * 0.5)
			z.draw_line(hand, hand + a * 6.0 * m, Color(0.9, 0.88, 0.8), 1.0, true)


func _leg(hip: Vector2, foot: Vector2, pants: Color, boots: Color) -> void:
	var ankle := foot + Vector2(0, -3.0)
	var knee := Art.joint(hip, ankle, 11.5, 11.0, 1.0)
	Art.limb(z, PackedVector2Array([hip, knee, ankle]), 5.2, pants)
	var top := knee.lerp(ankle, 0.35)
	Art.limb(z, PackedVector2Array([top, ankle]), 5.6, boots)
	Art.fill(z, PackedVector2Array([foot + Vector2(-2.5, -3.5), foot + Vector2(2.0, -3.5), foot + Vector2(6.0, -1.2), foot + Vector2(6.0, 0.0), foot + Vector2(-3.0, 0.0)]), boots, Art.OUTLINE, 0.9)
