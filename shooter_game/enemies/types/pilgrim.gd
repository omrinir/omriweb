extends "res://enemies/zombie_type.gd"
# ============================================================
#  PILGRIM (שלב 63, "THE HEART") - עולה רגל: גופה בגלימה עם ברדס ששטה שוכבת על הבטן, כמו טביעה הפוכה, על שתי
#    כנפיים של קרום בשר (כמו טריגון) שמתגלות בגל לאורכן. בידיים, מתחת לחזה, היא מחזיקה שק שיעור זוהר -
#    בצבע של הנשק שהשיעור עליו (Decor.CAT_COL: צהוב = BURSTS, כתום = SHOTGUN, תכלת = AIM, אדום = BLASTS).
#  איך הוא עף (חדש): לא רודף אותך - טס הביתה, ימינה, אל ה-ROOT. הכנפיים מכות בקצב של הלב (U.beat): בכל פעימה
#    זינוק קדימה (SURGE), ובין הפעימות הוא מאט - שם יורים בו. כשיורים לכיוונו - מחליף נתיב (VEER).
#    עובר מעליך = מפזר ענן נבגים (PUFF): הכוונת שלך רועדת.
#  נקודת תורפה (חדשה): השק. פגיעה בשק = "LESSON LOST" - מת מיד והשיעור אבד. הגלימה ספוגית (x ROBE_MULT).
#  מגיע הביתה (x רחוק לפניך / פה של עורק לפניך / חדר הלב; בזירה - הלב של ה-ROOT): stage_63.lesson_home() -
#    ה-ROOT לומד את הנשק הזה (עמיד יותר אליו), והמונה "LESSONS HOME" בפינה עולה.
#  מאיפה: פיות העורקים (stage_63 _wave), גופות של HOLLOW (hollow_dead), ובזירה ה-ROOT שולח אותם.
#  לומד (main meta "pg_lost" >= LEARN_LOST): "THEY PASS IT ON NOW" - נהרג בלי לפגוע בשק = זורק את השק קדימה
#    (LooseLesson): הוא נסחף הביתה לבד, או אל PILGRIM אחר (שק כפול). ירייה אחת בשק המעופף = אבד.
#  ביצועים: מיקום ישיר (בלי move_and_slide, collision_mask 0), ציור ב-draw call אחד, LooseLesson זז ב-_process.
#  לשנות: SPEED, SURGE, LANE, VEER*, ROBE_MULT, SAC_R, PUFF_*, HOME_AHEAD, LEARN_LOST.
# ============================================================

const Decor := preload("res://effects/s63_decor.gd")

const SOUNDS := {
	"pg_flap": [["N", 0, 0, 0.0, 0.3, 0.02, 9.0, 0.35, 0.12, 0, 0.1], ["S", 80, 60, 0.0, 0.25, 0.02, 10.0, 0.2, 1.0, 0]],
	"pg_moan": {"rev": 0.6, "layers": [["V", 180, 140, 0.0, 1.1, 0.2, 1.8, 0.22, 1.0, 0.04, 0, [500, 1300, 5]], ["N", 0, 0, 0.0, 0.9, 0.2, 2.0, 0.12, 0.15, 0, 0.1]]},
	"pg_pop": {"rev": 0.4, "drive": 1.6, "layers": [["N", 0, 0, 0.0, 0.2, 0.0, 16.0, 0.7, 0.5, 0, 0.3], ["S", 1760, 880, 0.0, 0.3, 0.0, 8.0, 0.25, 1.0, 0], ["S", 1320, 2640, 0.05, 0.3, 0.0, 9.0, 0.15, 1.0, 0]]},
	"pg_puff": [["N", 0, 0, 0.0, 0.5, 0.05, 5.0, 0.4, 0.4, 0, 0.6]],
	"pg_throw": [["N", 0, 0, 0.0, 0.2, 0.0, 12.0, 0.4, 0.3, 0], ["S", 600, 1200, 0.0, 0.25, 0.0, 8.0, 0.2, 1.0, 0]],
}

const SPEED := 185.0
const SURGE := 1.6                 # מהירות בפעימה (כפול SPEED), ובין פעימות SLACK
const SLACK := 0.45
const CATCH_UP := 270.0            # רחוק מאחוריך - ממהר (שיגיע הביתה)
const LANE := Vector2(190.0, 400.0)  # גובה מעל הרצפה
const WAVE_A := 16.0
const VEER := 80.0
const VEER_CD := 1.6
const VEER_CHANCE := 0.45
const ROBE_MULT := 0.7
const LEG_NORM := 1.5
const SAC_R := 10.0
const SAC_POS := Vector2(6.0, 12.0)  # מרכז השק יחסית למרכז הגוף (פונה ימינה)
const OFF := 20.0                  # z.global_position = מרכז הגוף + (0, OFF)
const PUFF_R := 80.0
const PUFF_T := 2.2
const HOME_AHEAD := 820.0
const LEARN_LOST := 3
const HP := 30

enum {RISE, FLY, HOME}
var state := RISE
var cat := "auto"
var carry := 1                     # כמה שיעורים בשק
var core := false                  # (זירה) טס אל הלב של ה-ROOT
var learned := false
var center := Vector2.ZERO
var veers := 0                     # לבדיקות
var puffs := 0
var passes := 0
var _from := Vector2.ZERO
var _lane := 300.0
var _lane_to := 300.0
var _t := 0.0
var _st := 0.0
var _veer_cd := 0.0
var _puffed := false
var _puff_t := -1.0
var _puff_x := 0.0
var _sac_hit := false
var _seed := 0.0
var _ground := 630.0
var _flap := 0.0
var _ready_ok := false


func stats() -> Dictionary:
	return {"name": "PILGRIM", "hp": HP, "walk": 0.0, "chase": 0.0, "damage": 0, "bite_delay": 9.0, "scale": 1.3, "width": 1.0,
		"duck": 0.0, "cover": 0.0, "skin": Color("8a8c80"), "shirt": Color("4a3a36"), "pants": Color("2a2020"), "shoe": Color("101010"),
		"points": 380, "ragdoll": false}


func use_brain_movement() -> bool:
	return false


func can_bite() -> bool:
	return false


func can_groan() -> bool:
	return false


func death_sound() -> String:
	return "pg_moan"


func _main() -> Node:
	return z.get_parent()


func _stage() -> Node:
	var m := _main()
	return m.get("_stage") if m != null else null


func setup() -> void:
	z.add_to_group("s63_pilgrims")
	_seed = float(z.get_instance_id() % 997) * 0.37
	_ground = z.global_position.y
	z._dir = 1.0
	z.collision_mask = 0   # לא נתקע בקירות / קומות (המיקום נקבע ישירות)
	var rs := z._shape.shape as RectangleShape2D
	rs.size = Vector2(62.0, 28.0) * z.sc
	z._shape.position = Vector2(0.0, -OFF * z.sc)
	var m := _main()
	learned = m != null and int(m.get_meta("pg_lost", 0)) >= LEARN_LOST
	center = z.global_position + Vector2(0.0, -300.0)
	_from = center


# stage_63.spawn_pilgrim: מאיפה (פה עורק / גופה), איזה שיעור, לאן
func launch(from: Vector2, c: String, to_core := false) -> void:
	cat = c
	core = to_core
	_from = from
	center = from
	_ground = 630.0
	var st := _stage()
	if st != null:
		_ground = float(st.floor_y)
	_lane = randf_range(LANE.x, LANE.y)
	_lane_to = _lane
	state = RISE
	_st = 0.0
	_ready_ok = true
	z.global_position = center + Vector2(0.0, OFF * z.sc)
	z.velocity = Vector2.ZERO
	Sfx.play("pg_moan", from, -6.0, 0.15, 2)


func sac_world() -> Vector2:
	var k := 1.0 + 0.15 * float(carry - 1)
	return center + Vector2(SAC_POS.x * z._dir, SAC_POS.y * k) * z.sc


func physics(pl: Node, delta: float) -> bool:
	_t += delta
	_veer_cd -= delta
	if z.dead:
		return false
	if not _ready_ok:   # (לא נשלח ע"י השלב - נשלח עכשיו עם שיעור רגיל)
		launch(z.global_position + Vector2(0, -260.0), "auto")
	var has: bool = pl != null and not pl.dead
	var px: float = pl.global_position.x if has else center.x
	var b: float = Decor.U.beat
	_flap = move_toward(_flap, b, delta * 6.0)
	if b > 0.95 and Engine.get_physics_frames() % 6 == 0 and Art.on_screen(z, center, 40.0):
		Sfx.play("pg_flap", center, -10.0, 0.15, 3)
	match state:
		RISE:   # יוצא מהפה / מהגופה אל הנתיב
			_st += delta
			var k := clampf(_st / 0.9, 0.0, 1.0)
			var tgt := Vector2(_from.x + 60.0 * k, _ground - _lane)
			center = _from.lerp(tgt, k * k * (3.0 - 2.0 * k))
			if k >= 1.0:
				state = FLY
		FLY:
			var sp := SPEED * lerpf(SLACK, SURGE, b)
			if core:
				sp *= 0.85
			elif has and center.x < px - 700.0:
				sp = CATCH_UP
			_lane = move_toward(_lane, _lane_to, delta * 180.0)
			var ty := _ground - _lane + sin(_t * 1.7 + _seed) * WAVE_A
			if core:
				var cw := _core_pos()
				var dv := cw - center
				var dl := dv.length()
				if dl < 36.0:
					_home()
					return true
				center += dv / maxf(dl, 1.0) * minf(sp * delta, dl)
				z._dir = signf(dv.x) if absf(dv.x) > 4.0 else z._dir
			else:
				z._dir = 1.0
				center.x += sp * delta
				center.y = move_toward(center.y, ty, delta * 140.0)
				if _reached_home(px, has):
					_home()
					return true
			# עובר מעליך: ענן נבגים
			if has and not _puffed and absf(center.x - px) < 40.0 and pl.global_position.y > center.y + 80.0:
				_puffed = true
				_puff_t = 0.0
				_puff_x = center.x
				puffs += 1
				Sfx.play("pg_puff", center, -4.0, 0.1, 2)
				if Art.on_screen(z, center):
					Particles.burst(_main(), center + Vector2(0, 14), "mist", Vector2.DOWN, 5)
	if _puff_t >= 0.0:
		_puff_t += delta
		if _puff_t > 0.45 and _puff_t - delta <= 0.45 and has:   # הענן נוחת
			if absf(pl.global_position.x - _puff_x) < PUFF_R and pl.global_position.y > center.y:
				pl.aim_sway(PUFF_T, "SPORES IN YOUR EYES")
		if _puff_t > 1.2:
			_puff_t = -1.0
	z.velocity = Vector2.ZERO
	z.global_position = center + Vector2(0.0, OFF * z.sc)
	return true


func _core_pos() -> Vector2:
	var st := _stage()
	if st != null and st.root != null and is_instance_valid(st.root) and st.root.type_mod != null:
		return st.root.type_mod.core_world()
	return Vector2(z.world_w - 400.0, _ground - 260.0)


func _reached_home(px: float, has: bool) -> bool:
	var st := _stage()
	var ax: float = float(st.ARENA_X0) if st != null else z.world_w - 1800.0
	if center.x > ax - 80.0:
		return true
	if not has:
		return false
	if center.x > px + HOME_AHEAD:
		return true
	if center.x > px + 450.0:   # נבלע בפה של עורק לפניך
		for m in z.get_tree().get_nodes_in_group("s63_mouths"):
			if absf(m.global_position.x - center.x) < 30.0:
				return true
	return false


func _home() -> void:
	state = HOME
	var st := _stage()
	if st != null and st.has_method("lesson_home"):
		for i in carry:
			st.lesson_home(cat, center)
	if Art.on_screen(z, center, 60.0):
		Particles.burst(_main(), center, "mist", Vector2.UP, 4)
	z.remove_from_group("zombies")
	z.queue_free()


func on_shot(from: Vector2, dir: Vector2) -> void:
	if z == null or z.dead or state != FLY or _veer_cd > 0.0 or randf() > VEER_CHANCE:
		return
	var rel := center - from
	if rel.dot(dir) < 0.0 or absf(rel.cross(dir)) > 70.0:
		return
	_veer_cd = VEER_CD
	veers += 1
	var up := 1.0 if (_lane_to < (LANE.x + LANE.y) * 0.5) else -1.0
	_lane_to = clampf(_lane_to + up * VEER, LANE.x - 20.0, LANE.y + 40.0)


func on_damage(_amount: int, hit_pos: Vector2, dir: Vector2, src: Dictionary) -> bool:
	if z.dead:
		return true
	var s := str(src.get("source", "bullet"))
	_sac_hit = false
	var sc := sac_world()
	if s == "bullet" or s == "melee" or s == "laser":
		var rel := sc - hit_pos
		if dir == Vector2.ZERO or s == "melee":
			_sac_hit = rel.length() < SAC_R * z.sc * 1.4
		else:
			var along := rel.dot(dir)
			_sac_hit = along > -SAC_R * z.sc and absf(rel.cross(dir)) < SAC_R * z.sc * (1.0 + 0.15 * float(carry - 1))
	elif s != "fire" and s != "taser" and s != "trap":
		_sac_hit = hit_pos.distance_to(sc) < 60.0   # פיצוץ קרוב - גם השק
	return true


func damage_mult(zone: String, _src: Dictionary) -> float:
	if _sac_hit:
		return 99.0
	return ROBE_MULT * (LEG_NORM if zone == "leg" else 1.0)


func on_death() -> void:
	var m := _main()
	var st := _stage()
	if _sac_hit:
		z._popup("LESSON LOST", Decor.CAT_COL.get(cat, Decor.ECHO), 15, -40.0)
		Sfx.play("pg_pop", center, 0.0, 0.1, 2)
		Particles.burst(m, sac_world(), "spark", Vector2.UP, 6)
		Particles.burst(m, sac_world(), "mist", Vector2.UP, 4)
		if st != null and st.has_method("lesson_lost"):
			st.lesson_lost(cat)
	elif learned and state == FLY:   # זורק את השק קדימה
		passes += 1
		var ll := LooseLesson.new()
		ll.cat = cat
		ll.carry = carry
		ll.ground = _ground
		m.add_child(ll)
		ll.global_position = sac_world()
		ll.vel = Vector2(220.0, -120.0)
		Sfx.play("pg_throw", center, 0.0, 0.1, 2)
		if m != null and not m.has_meta("pg_pass_said"):
			m.set_meta("pg_pass_said", true)
			z._popup("THEY PASS IT ON NOW", Decor.ECHO, 14, -60.0)
			var pl := player()
			if pl != null:
				Decor.U.say(pl, "It threw the lesson! Shoot the SAC, not the body.", Color("c8ffb0"))
	else:
		if st != null and st.has_method("lesson_lost"):
			st.lesson_lost(cat)
		Particles.burst(m, sac_world(), "mist", Vector2.UP, 3)
	Particles.burst(m, center, "hit", Vector2.DOWN, int(8.0 * Quality.gore()) + 2)
	z.collision_mask = 1 | 16
	z.velocity = Vector2(80.0, -60.0)


func wants_redraw() -> bool:
	return true


# ============================================================
#  ציור: (0,0) של הזומבי = מרכז הגוף + (0, OFF). פונה ימינה, שוכב על הבטן: ראש מקדימה (ימין), גלימה נגררת מאחור,
#  שתי כנפי קרום (אחת מאחורי הגוף, אחת מלפניו) שמתגלות בגל, ידיים למטה מחזיקות את השק.
# ============================================================
func draw() -> bool:
	if z.dead:
		begin_draw(false)
		_draw_corpse()
		end_draw()
		return true
	var s := Vector2(z._dir * z.sc, z.sc)
	var tilt: float = clampf((center.y - (_ground - _lane)) * -0.004, -0.25, 0.25) * z._dir
	DrawBatch.set_transform_matrix(z, Transform2D(tilt, Vector2(0.0, -OFF * z.sc)) * Transform2D(0.0, s, 0.0, Vector2.ZERO))
	var tt := _t
	var rob := col(z.shirt)
	var rob_d := Art.shade(rob, -0.35)
	var flesh := col(Color("8a4a48"))
	var vein: Color = Decor.U.glow(Color(0.75, 1.0, 0.55, 0.6 + 0.3 * _flap))
	_wing(tt, -1.0, Color(flesh.r * 0.55, flesh.g * 0.5, flesh.b * 0.55, 1.0), vein)   # כנף אחורית
	# הגלימה הנגררת: רצועות קרועות שמתנופפות
	for q in 3:
		var y0 := -4.0 + float(q) * 4.0
		var w := sin(tt * 6.0 + float(q) * 1.3) * 4.0
		var w2 := sin(tt * 6.0 + float(q) * 1.3 + 1.2) * 6.0
		DrawBatch.colored_polygon(z, PackedVector2Array([Vector2(-16.0, y0 - 2.0), Vector2(-30.0, y0 + w), Vector2(-46.0 - float(q) * 4.0, y0 + w2),
			Vector2(-30.0, y0 + w + 3.0), Vector2(-16.0, y0 + 3.0)]), rob_d if q != 1 else rob)
	# גוף שוכב (גלימה)
	Art.fill_shaded(z, PackedVector2Array([Vector2(-24, -6), Vector2(2, -10), Vector2(16, -7), Vector2(19, 3), Vector2(4, 8), Vector2(-24, 7)]), rob, 0.15, 0.3)
	# רגליים יחפות נגררות מאחור
	Art.limb(z, PackedVector2Array([Vector2(-22, 2), Vector2(-32, 5), Vector2(-40, 4)]), 2.6, col(z.skin).darkened(0.25))
	Art.limb(z, PackedVector2Array([Vector2(-22, 5), Vector2(-31, 9), Vector2(-38, 10)]), 2.4, col(z.skin).darkened(0.35))
	DrawBatch.polyline(z, PackedVector2Array([Vector2(-20, -2), Vector2(-4, -5), Vector2(8, -3), Vector2(15, 0)]), vein, 1.2)
	# ידיים למטה מחזיקות את השק
	var sp := Vector2(SAC_POS.x, SAC_POS.y * (1.0 + 0.15 * float(carry - 1)))
	var sk := col(z.skin)
	Art.limb(z, PackedVector2Array([Vector2(10, 2), Vector2(12, 8), sp + Vector2(5, -3)]), 2.6, sk)
	Art.limb(z, PackedVector2Array([Vector2(0, 3), Vector2(-2, 9), sp + Vector2(-5, -3)]), 2.6, Art.shade(sk, -0.2))
	# השק: שיעור זוהר (צבע הנשק)
	var cc: Color = Decor.CAT_COL.get(cat, Decor.ECHO)
	var pr := SAC_R * (1.0 + 0.15 * float(carry - 1)) * (0.9 + 0.12 * sin(tt * 7.0))
	Art.glow(z, sp, pr * 2.2, Color(cc, 0.35))
	Art.oval(z, sp, pr, pr * 0.9, col(Color(cc.r * 0.6, cc.g * 0.6, cc.b * 0.6)), 0.0)
	Art.oval(z, sp + Vector2(-2.0, -2.0), pr * 0.55, pr * 0.5, Color(cc, 0.95), 0.0, Art.NONE)
	Art.oval(z, sp + Vector2(-3.5, -3.5), pr * 0.2, pr * 0.18, Color(1, 1, 1, 0.8), 0.0, Art.NONE)
	if carry > 1:
		DrawBatch.arc(z, sp, pr + 3.0, 0.0, TAU, 14, Color(cc, 0.7), 1.2)
	# ראש עם ברדס מקדימה, פנים למטה
	var hd := Vector2(21.0, -2.0)
	Art.oval(z, hd, 8.0, 7.0, rob, 0.0)
	DrawBatch.colored_polygon(z, PackedVector2Array([hd + Vector2(-6, -5), hd + Vector2(-14, -9), hd + Vector2(-4, -1)]), rob_d)
	Art.oval(z, hd + Vector2(3.0, 2.5), 4.0, 3.0, col(Color("080606")), 0.0, Art.NONE)
	DrawBatch.line(z, hd + Vector2(2.0, 2.6), hd + Vector2(5.4, 3.2), Color(0.7, 1.0, 0.5, 0.9), 1.0)
	_wing(tt, 1.0, Color(flesh, 0.96), vein)   # כנף קדמית
	end_draw()
	# ענן הנבגים שנופל
	if _puff_t >= 0.0:
		var k := _puff_t / 1.2
		var c := Vector2(_puff_x - z.global_position.x, 30.0 + 180.0 * k)
		var a := 0.45 * (1.0 - k)
		DrawBatch.circle(z, c, 30.0 + 40.0 * k, Color(0.6, 0.85, 0.45, a * 0.5))
		DrawBatch.circle(z, c + Vector2(-20.0, -8.0), 18.0 + 30.0 * k, Color(0.7, 0.95, 0.5, a * 0.4))
	return true


# כנף קרום (מפרש): מחוברת לגב ולזרוע, נמתחת אחורה ולמעלה כמו גלימה ברוח, וגל עובר לאורכה.
# side -1 = הכנף הרחוקה (מאחורי הגוף, כהה), 1 = הקרובה (מלפנים)
func _wing(tt: float, side: float, c: Color, vein: Color) -> void:
	var n := 7
	var lift_k := 0.6 + 0.7 * _flap
	var lead := PackedVector2Array()
	var trail := PackedVector2Array()
	var y0 := -6.0 if side < 0.0 else -3.0
	for i in n + 1:
		var k := float(i) / float(n)
		var ph := tt * 5.5 - k * 3.4 + (0.0 if side < 0.0 else 0.7)
		var wave := sin(ph) * (3.0 + 12.0 * k) * lift_k
		var up := (26.0 + 10.0 * _flap) * k * (1.1 if side < 0.0 else 0.85)
		lead.append(Vector2(lerpf(12.0, -58.0, k), y0 - 4.0 - up - wave))
		trail.append(Vector2(lerpf(-12.0, -66.0, k), y0 + 2.0 - up * 0.45 - wave * 0.8 + 6.0 * k))
	var pts := PackedVector2Array()
	var cols := PackedColorArray()
	for i in n:
		pts.append_array([lead[i], trail[i], trail[i + 1], lead[i], trail[i + 1], lead[i + 1]])
		var cc := Color(c, c.a * (1.0 - float(i) * 0.06))
		var cl := cc.lightened(0.12)
		cols.append_array([cl, cc, cc, cl, cc, cl])
	DrawBatch.tris(z, pts, cols)
	var mid := PackedVector2Array()
	for i in range(0, n + 1, 2):
		mid.append((lead[i] * 0.6 + trail[i] * 0.4))
	DrawBatch.polyline(z, mid, vein, 1.0)
	DrawBatch.polyline(z, lead, Color(c.r * 0.55, c.g * 0.45, c.b * 0.45, minf(c.a + 0.1, 1.0)), 1.6)
	for i in range(2, n + 1, 2):   # "אצבעות" של הכנף (כמו עטלף)
		DrawBatch.line(z, lead[0].lerp(Vector2(0, y0), 0.5), lead[i], Color(0.25, 0.1, 0.1, 0.5 * c.a), 1.0)


func _draw_corpse() -> void:
	var rob := col(z.shirt)
	Art.fill_shaded(z, PackedVector2Array([Vector2(-18, -14), Vector2(16, -14), Vector2(18, -4), Vector2(-18, -4)]), rob, 0.1, 0.3)
	Art.oval(z, Vector2(20, -10), 6.0, 5.0, rob, 0.0)
	DrawBatch.colored_polygon(z, PackedVector2Array([Vector2(-10, -12), Vector2(-30, -20), Vector2(-26, -6)]), Color(0.45, 0.25, 0.25, 0.7))


# ============================================================
#  שיעור שנזרק (THEY PASS IT ON): נסחף הביתה, או אל PILGRIM אחר. ירייה אחת = אבד.
#  StaticBody2D בשכבה 4 (קליעים פוגעים בו - take_damage), זז ב-_process.
# ============================================================
class LooseLesson extends StaticBody2D:
	const DB := preload("res://effects/draw_batch.gd")
	const DecorL := preload("res://effects/s63_decor.gd")
	var cat := "auto"
	var carry := 1
	var ground := 630.0
	var vel := Vector2.ZERO
	var _t := 0.0
	var _target: Node = null
	var _done := false

	func _ready() -> void:
		z_index = 8
		collision_layer = 4
		collision_mask = 0
		add_to_group("no_outline")
		var cs := CollisionShape2D.new()
		var cr := CircleShape2D.new()
		cr.radius = 11.0
		cs.shape = cr
		add_child(cs)

	func take_damage(_amount: int, _hit_pos: Vector2, _dir: Vector2, _explosive := false, _src := {}) -> void:
		if _done:
			return
		_done = true
		var st = get_parent().get("_stage")
		if st != null and st.has_method("lesson_lost"):
			for i in carry:
				st.lesson_lost(cat)
		var t = preload("res://zombie.gd").HitText.new()
		t.text = "LESSON LOST"
		t.color = DecorL.CAT_COL.get(cat, DecorL.ECHO)
		t.size = 15
		get_parent().add_child(t)
		t.global_position = global_position + Vector2(0, -30)
		preload("res://sfx.gd").play("pg_pop", global_position, 0.0, 0.1, 2)
		preload("res://particles.gd").burst(get_parent(), global_position, "spark", Vector2.UP, 6)
		queue_free()

	func _process(delta: float) -> void:
		if _done:
			return
		_t += delta
		if _t < 0.5:   # נזרק קדימה
			vel = vel.move_toward(Vector2(120.0, 0.0), delta * 500.0)
		else:
			if _target == null or not is_instance_valid(_target) or _target.dead:
				_target = null
				for p in get_tree().get_nodes_in_group("s63_pilgrims"):
					if not p.dead and p.type_mod != null and p.type_mod.state == 1 and p.type_mod.center.x > global_position.x - 100.0 \
							and p.type_mod.center.distance_to(global_position) < 600.0:
						_target = p
						break
			if _target != null:   # אל PILGRIM אחר: שק כפול
				var tc: Vector2 = _target.type_mod.sac_world()
				var dv := tc - global_position
				if dv.length() < 18.0:
					_target.type_mod.carry += carry
					_target.type_mod.cat = cat if carry >= int(_target.type_mod.carry) - carry else _target.type_mod.cat
					queue_free()
					_done = true
					return
				vel = vel.move_toward(dv.normalized() * 260.0, delta * 600.0)
			else:   # הביתה (ימינה, למעלה)
				vel = vel.move_toward(Vector2(140.0, (ground - 330.0 - global_position.y) * 0.8), delta * 300.0)
				var pl := get_tree().get_first_node_in_group("player") as Node2D
				var st = get_parent().get("_stage")
				var ax: float = float(st.ARENA_X0) if st != null else 8400.0
				if (pl != null and global_position.x > pl.global_position.x + 820.0) or global_position.x > ax - 80.0:
					_done = true
					if st != null and st.has_method("lesson_home"):
						for i in carry:
							st.lesson_home(cat, global_position)
					queue_free()
					return
		global_position += vel * delta
		if _t > 25.0:
			queue_free()
			return
		queue_redraw()

	func _draw() -> void:
		DB.begin(self)
		_draw_b()
		DB.end(self)

	func _draw_b() -> void:
		var cc: Color = DecorL.CAT_COL.get(cat, DecorL.ECHO)
		var p := 0.5 + 0.5 * sin(_t * 9.0)
		DB.circle(self, Vector2.ZERO, 16.0 + 4.0 * p, Color(cc, 0.18))
		DB.circle(self, Vector2.ZERO, 9.0, Color(cc.r * 0.6, cc.g * 0.6, cc.b * 0.6))
		DB.circle(self, Vector2(-1.5, -1.5), 5.5, Color(cc, 0.95))
		DB.circle(self, Vector2(-3, -3), 2.0, Color(1, 1, 1, 0.8))
		DB.line(self, Vector2(-10, 0), Vector2(-22, -2.0 + 3.0 * p), Color(cc, 0.4), 2.0)
