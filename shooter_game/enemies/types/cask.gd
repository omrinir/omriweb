extends "res://enemies/zombie_type.gd"
# ============================================================
#  CASK (שלב 46, "WINE VALLEY") - עובד יקב זומבי ענק שנתקע בתוך חבית יין: רק הראש, הידיים והרגליים בחוץ.
#    החבית = שריון: יריות בגוף פוגעות בעץ (BARREL_HP, רסיסי עץ ויין מטפטף). ראש ורגליים פגיעים תמיד. פיצוץ = נזק כפול לחבית.
#    החבית נשברת -> פרץ יין ("BARREL BROKEN"), והוא מהיר (FREE_SPEED) אבל שביר (FREE_MULT).
#  ROLL: כשאתה במרחק בינוני על אותה רצפה - מתכנס לתוך החבית (TUCK_T - אזהרה: הראש והגפיים נכנסים, החבית רועדת)
#    ומתגלגל אליך (ROLL_V). פגיעה = נזק + הדף. להתחמק: לקפוץ מעל. בזמן גלגול כל יריה בגוף פוגעת בחבית.
#  "THEY LEARN YOUR JUMP - TOGETHER": כל קפיצה מעל חבית מתגלגלת נספרת (main meta "cask_jumps").
#    אחרי JUMP_LEARN קפיצות כל החביות קופצות (BOUNCE) בדיוק כשהן מגיעות אליך ("THEY BOUNCE NOW") - אז לגלגל הצידה / לברוח.
#  צלילים: "ck_wood" (פגיעה בעץ), "ck_roll" (גלגול), "ck_break" (חבית נשברת).
#  לשנות: BARREL_HP, TUCK_T, ROLL_V, ROLL_T, ROLL_R, JUMP_LEARN, FREE_SPEED, FREE_MULT, CD.
# ============================================================

const SOUNDS := {
	"ck_wood": [["C", 0, 0, 0.0, 0.05, 0.0, 45.0, 0.4, 1.0, 0], ["S", 240, 180, 0.0, 0.08, 0.0, 30.0, 0.3, 1.0, 0.05]],
	"ck_roll": [["N", 0, 0, 0.0, 0.3, 0.0, 6.0, 0.25, 0.15, 0], ["S", 70, 60, 0.0, 0.3, 0.0, 6.0, 0.25, 1.0, 0.3]],
	"ck_break": [["C", 0, 0, 0.0, 0.08, 0.0, 30.0, 0.7, 1.0, 0], ["N", 0, 0, 0.0, 0.5, 0.0, 6.0, 0.6, 0.3, 0, 0.8], ["S", 160, 90, 0.0, 0.2, 0.0, 14.0, 0.4, 1.0, 0.1]],
}

const BARREL_HP := 90
const TUCK_T := 0.7
const ROLL_V := 400.0
const ROLL_T := 1.7
const ROLL_R := Vector2(110.0, 520.0)   # מאיזה מרחק הוא מתגלגל
const JUMP_LEARN := 2
const BOUNCE_V := -470.0
const FREE_SPEED := 1.7
const FREE_MULT := 1.35
const CD := Vector2(3.0, 4.5)

enum { WALK, TUCK, ROLL, UNTUCK }
var state := WALK
var barrel_hp := BARREL_HP
var rolls := 0               # לבדיקות
var roll_hits := 0
var bounces := 0
var absorbed := 0
var _st := 0.0
var _cd := 1.0
var _rot := 0.0
var _hit := false
var _jumped := false
var _bounced := false
var _crack := 0.0


func stats() -> Dictionary:
	return {"name": "CASK", "hp": 40, "walk": 30.0, "chase": 62.0, "damage": 1, "bite_delay": 0.9, "scale": 1.28, "width": 1.4,
		"duck": 0.0, "cover": 0.0, "skin": Color("8a9a7a"), "shirt": Color("6a4426"), "pants": Color("3a3a40"), "shoe": Color("2a1a14"), "points": 520}


func brain_overrides() -> Dictionary:
	return {"aggression": 0.5}


func has_barrel() -> bool:
	return barrel_hp > 0


func can_bite() -> bool:
	return state == WALK


static func learned(main: Node) -> bool:
	return main.has_meta("cask_jumps") and int(main.get_meta("cask_jumps")) >= JUMP_LEARN


func on_damage(amount: int, hit_pos: Vector2, dir: Vector2, src: Dictionary) -> bool:
	if not has_barrel() or z.dead:
		return true
	var s := str(src.get("source", "bullet"))
	if src.has("blast") or not (s == "bullet" or s == "melee"):
		if s != "fire":
			_hurt_barrel(maxi(amount, 20) * 2, hit_pos, dir)
		return true
	var ly: float = (hit_pos.y - z.global_position.y) / z.sc
	if state == WALK and (ly < -44.0 or ly > -9.0):   # ראש / רגליים בחוץ
		return true
	_hurt_barrel(hit_damage(amount, hit_pos, src), hit_pos, dir)
	return false


func _hurt_barrel(dmg: int, hit_pos: Vector2, dir: Vector2) -> void:
	absorbed += 1
	barrel_hp -= maxi(dmg, 1)
	_crack = 0.1
	z._flash = 0.05
	Sfx.play("ck_wood", hit_pos, -3.0, 0.15, 3)
	var D := preload("res://debris.gd")
	for i in 2:
		var c = D.new()
		z.get_parent().add_child(c)
		c.setup(hit_pos, Vector2(3, 1.5), Color("8a6034"), Vector2(-dir.x * randf_range(60, 180), -randf_range(60, 200)))
	if barrel_hp <= 0:
		_break_barrel()


func _break_barrel() -> void:
	barrel_hp = 0
	state = WALK
	Sfx.play("ck_break", z.global_position, 2.0, 0.1, 2)
	z._popup("BARREL BROKEN", Color("c06090"), 14, -80.0 * z.sc)
	z.chase_speed = float(z.chase_speed) * FREE_SPEED
	z.walk_speed = float(z.walk_speed) * FREE_SPEED
	var Decor := preload("res://effects/s46_decor.gd")
	var w = Decor.WineSpray.new()
	z.get_parent().add_child(w)
	w.global_position = z.global_position + Vector2(0, -30.0 * z.sc)
	var D := preload("res://debris.gd")
	for i in 7:
		var c = D.new()
		z.get_parent().add_child(c)
		c.setup(z.global_position + Vector2(randf_range(-14, 14), -30.0 * z.sc), Vector2(randf_range(4, 9), 2.5), Color("7a5430"), Vector2(randf_range(-240, 240), -randf_range(120, 340)))


func damage_mult(_zone: String, _src: Dictionary) -> float:
	return 1.0 if has_barrel() else FREE_MULT


func physics(pl: Node, delta: float) -> bool:
	_cd -= delta
	_st -= delta
	_crack -= delta
	if z.dead:
		return false
	var has_pl: bool = pl != null and not pl.dead
	match state:
		WALK:
			if not has_barrel() or not has_pl or not z.is_on_floor() or z.goal_x < INF:
				return false
			var d: Vector2 = pl.global_position - z.global_position
			if _cd <= 0.0 and absf(d.x) > ROLL_R.x and absf(d.x) < ROLL_R.y and absf(d.y) < 40.0 and _los(pl):
				state = TUCK
				_st = TUCK_T
				z._dir = signf(d.x)
				Sfx.play("groan", z.global_position, 2.0, 0.1, 2, 0.6)
				return _move(0.0, delta)
			return false
		TUCK:
			if _st <= 0.0:
				state = ROLL
				_st = ROLL_T
				_hit = false
				_jumped = false
				_bounced = false
				rolls += 1
				Sfx.play("ck_roll", z.global_position, 0.0, 0.1, 2)
			return _move(0.0, delta)
		ROLL:
			_rot += ROLL_V * delta / (18.0 * z.sc) * z._dir
			if Engine.get_physics_frames() % 18 == 0:
				Sfx.play("ck_roll", z.global_position, -6.0, 0.15, 2)
			if has_pl:
				var d2: Vector2 = pl.global_position - z.global_position
				var close: bool = absf(d2.x) < 26.0 * z.sc + 14.0
				# BOUNCE (למד): קופץ בדיוק כשהוא מגיע אליך
				if not _bounced and learned(z.get_parent()) and absf(d2.x) < 70.0 and signf(d2.x) == z._dir and z.is_on_floor():
					_bounced = true
					bounces += 1
					z.velocity.y = BOUNCE_V
					if bounces == 1:
						z._popup("THEY BOUNCE NOW", Color("ffb070"), 12, -60.0 * z.sc)
				if not _hit and close and absf(d2.y + 10.0) < 30.0 * z.sc + (30.0 if not z.is_on_floor() else 0.0):
					_hit = true
					roll_hits += 1
					pl.hurt(z.damage, Vector2(z._dir * 2.2, -1.0))
				# קפצת מעליו? כולם לומדים
				if not _jumped and not _hit and not pl.is_on_floor() and close and d2.y < -24.0 * z.sc:
					_jumped = true
					var mn: Node = z.get_parent()
					mn.set_meta("cask_jumps", (int(mn.get_meta("cask_jumps")) if mn.has_meta("cask_jumps") else 0) + 1)
			if _st <= 0.0 or (z.is_on_wall() and _st < ROLL_T - 0.15):
				if z.is_on_wall():
					Sfx.play("ck_wood", z.global_position, 0.0, 0.1, 2)
					var cam: Node = z.get_viewport().get_camera_2d()
					if cam != null and cam.has_method("shake") and Art.on_screen(z, z.global_position):
						cam.shake(4.0, 0.2)
				state = UNTUCK
				_st = 0.5
			return _move(z._dir * ROLL_V, delta, 2400.0)
		UNTUCK:
			_rot = lerp_angle(_rot, 0.0, minf(delta * 10.0, 1.0))
			if _st <= 0.0:
				_rot = 0.0
				state = WALK
				_cd = randf_range(CD.x, CD.y)
			return _move(0.0, delta)
	return false


func _move(vx: float, delta: float, acc := 900.0) -> bool:
	z.velocity.x = move_toward(z.velocity.x, vx, acc * delta)
	if not z.is_on_floor():
		z.velocity.y += z.gravity * delta
	z.move_and_slide()
	return true


func on_death() -> void:
	if has_barrel() and state != WALK:
		state = WALK


# ============================================================
#  ציור: חבית עץ (דפנות + חישוקי ברזל + כתמי יין), ראש מציץ למעלה, ידיים מהצדדים, רגליים למטה.
#  מתגלגל: רק החבית (עיגול מסתובב), בלי ראש וגפיים
# ============================================================
func draw() -> bool:
	var rolling := state == ROLL or (state == UNTUCK and _st > 0.25)
	if rolling and not z.dead:
		begin_draw(false)
		Art.ground_shadow(z, Vector2.ZERO, 16.0)
		var c := Vector2(0, -19)
		var r := 18.0
		Art.disc(z, c, r, col(Color("7a5430")), Art.OUTLINE, 1.3)
		DrawBatch.arc(z, c, r - 1.5, 0.0, TAU, 22, col(Color("3a3a40")), 2.4)
		DrawBatch.arc(z, c, r * 0.55, 0.0, TAU, 16, col(Color("3a3a40")), 1.6)
		for q in 6:   # דפנות שמסתובבות
			var a := _rot + float(q) * TAU / 6.0
			DrawBatch.line(z, c + Vector2.from_angle(a) * r * 0.58, c + Vector2.from_angle(a) * (r - 3.0), col(Color("4a3018")), 1.2)
		DrawBatch.circle(z, c + Vector2.from_angle(_rot) * r * 0.3, 2.0, col(Color("2a1a10")))   # פקק
		DrawBatch.circle(z, c + Vector2.from_angle(_rot + 2.0) * r * 0.8, 1.6, col(Color(0.45, 0.05, 0.25, 0.9)))
		for q in 3:   # קווי מהירות
			DrawBatch.line(z, c + Vector2(-r - 4.0 - float(q) * 6.0, -8.0 + float(q) * 8.0), c + Vector2(-r - 14.0 - float(q) * 6.0, -8.0 + float(q) * 8.0), Color(1, 1, 1, 0.25), 1.2)
		end_draw()
		return true
	begin_draw()
	var sk := col(z.skin)
	var p: float = z._walk_phase
	var f: Array = feet(3.5, 2.0)
	var tuck := 0.0
	if state == TUCK:
		tuck = 1.0 - clampf(_st / TUCK_T, 0.0, 1.0)
	elif state == UNTUCK:
		tuck = clampf(_st / 0.25, 0.0, 1.0)
	var shake := Vector2(sin(z._time * 60.0), 0) * 1.2 * tuck
	var hip := Vector2(0, -12)
	z._leg(hip + Vector2(-5, 0) + Vector2(0, -6.0 * tuck), f[1].lerp(Vector2(-4, -6), tuck), col(Art.shade(z.pants, 0.25)), sk, col(z.shoe))
	z._leg(hip + Vector2(5, 0) + Vector2(0, -6.0 * tuck), f[0].lerp(Vector2(4, -6), tuck), col(z.pants), sk, col(z.shoe))
	var top := Vector2(0, -46) + shake
	var bot := Vector2(0, -9) + shake
	var head := top + Vector2(2, -3.0 + 9.0 * tuck)
	# יד אחורית
	var hb := Vector2(-21.0 - sin(p) * 2.0, -17.0).lerp(Vector2(-14, -30), tuck) + shake
	if tuck < 0.9:
		z._arm(Vector2(-13, -36) + shake, hb, Art.shade(sk, 0.25), Art.shade(sk, 0.25))
	# ראש (מאחורי שפת החבית)
	if not z.dead or not z._headless:
		Art.oval_shaded(z, head, 5.6, 6.0, sk, 0.0)
		DrawBatch.colored_polygon(z, Art.ellipse(head + Vector2(-1, -4.5), 5.2, 2.2, -0.1, 10), col(Color("3a3028")))   # שיער דליל / כובע גרב
		if not z.dead:
			DrawBatch.circle(z, head + Vector2(3, -0.5), 1.1, Color(1.0, 0.4, 0.5))
		DrawBatch.line(z, head + Vector2(1, 3), head + Vector2(5, 2.5), col(Color("4a1a2a")), 1.2)
	if has_barrel():
		_barrel(top, bot)
	else:   # שאריות: חישוק תחתון + דפנות שבורות, בגדים מוכתמים ביין
		var torso := PackedVector2Array([Vector2(-8, -42), Vector2(8, -42), Vector2(9, -14), Vector2(-9, -14)])
		Art.fill_shaded(z, torso, col(z.shirt), 0.15, 0.35)
		for q in 4:
			DrawBatch.circle(z, Vector2(-5.0 + float(q) * 3.0, -30.0 + float(q % 2) * 6.0), 2.5, col(Color(0.4, 0.04, 0.2, 0.8)))
		for q in 5:
			var x := -12.0 + float(q) * 6.0
			Art.fill(z, PackedVector2Array([Vector2(x, -9), Vector2(x + 5, -9), Vector2(x + 4, -20.0 + float(q % 3) * 3.0), Vector2(x + 1, -24.0 + float(q % 2) * 4.0)]), col(Color("7a5430")), Art.OUTLINE, 0.8)
		DrawBatch.line(z, Vector2(-13, -11), Vector2(13, -11), col(Color("3a3a40")), 2.0)
	# יד קדמית
	var hf := Vector2(21.0 + sin(p) * 2.0, -17.0).lerp(Vector2(14, -30), tuck) + shake
	if z._bite_anim > 0.0:
		hf = Vector2(24, -34)
	if tuck < 0.9:
		z._arm(Vector2(13, -36) + shake, hf, sk, sk)
	end_draw()
	return true


func _barrel(top: Vector2, bot: Vector2) -> void:
	var wcol := col(Color("7a5430"))
	var h := bot.y - top.y
	var pts := PackedVector2Array()   # צורת חבית: רחבה באמצע
	for i in 9:
		var u := float(i) / 8.0
		pts.append(Vector2(top.x + 13.0 + sin(u * PI) * 3.5, top.y + u * h))
	for i in range(8, -1, -1):
		var u := float(i) / 8.0
		pts.append(Vector2(top.x - 13.0 - sin(u * PI) * 3.5, top.y + u * h))
	Art.fill_shaded(z, pts, wcol, 0.18, 0.4)
	for q in 4:   # דפנות
		var x := -8.0 + float(q) * 5.5
		DrawBatch.line(z, Vector2(top.x + x, top.y + 1.0), Vector2(top.x + x * 1.2, bot.y - 1.0), col(Color("4a3018")), 0.9)
	for yy in [0.12, 0.5, 0.88]:   # חישוקי ברזל
		var y: float = top.y + h * float(yy)
		var wd := 13.0 + sin(float(yy) * PI) * 3.5
		DrawBatch.line(z, Vector2(top.x - wd, y), Vector2(top.x + wd, y), col(Color("2e2e34")), 2.6)
		DrawBatch.line(z, Vector2(top.x - wd, y - 1.0), Vector2(top.x + wd, y - 1.0), col(Color("6a6a74")), 0.8)
	DrawBatch.colored_polygon(z, Art.ellipse(top, 13.0, 3.0, 0.0, 14), col(Color("5a3a20")))   # שפה עליונה
	# כתמי יין ופגיעות
	var dmg := 1.0 - float(barrel_hp) / float(BARREL_HP)
	DrawBatch.line(z, top + Vector2(6, 6), top + Vector2(7, 22), col(Color(0.42, 0.04, 0.22, 0.85)), 2.0)
	DrawBatch.circle(z, top + Vector2(-4, 26), 3.0, col(Color(0.42, 0.04, 0.22, 0.6)))
	for q in int(dmg * 6.0):   # סדקים
		var c := top + Vector2(-9.0 + float(q * 7 % 18), 8.0 + float(q * 11 % 26))
		DrawBatch.line(z, c, c + Vector2(4, 3), col(Color("2a1a0e")), 1.2)
		DrawBatch.line(z, c + Vector2(4, 3), c + Vector2(2, 7), col(Color("2a1a0e")), 1.0)
	DrawBatch.string(z, ThemeDB.fallback_font, top + Vector2(-8, 22), "1946", HORIZONTAL_ALIGNMENT_LEFT, -1, 7, col(Color(0.15, 0.08, 0.04, 0.8)))
	if _crack > 0.0:
		Art.glow(z, top + Vector2(0, h * 0.5), 10.0, Color(1, 0.9, 0.7, 0.4))


# קו ראייה פשוט (בלי קירות באמצע) - המוח לא רץ כשהסוג שולט בתנועה בעצמו
func _los(pl: Node) -> bool:
	var a: Vector2 = z.global_position + Vector2(0, -52.0 * z.sc)
	var b: Vector2 = pl.global_position + Vector2(0, -38.0)
	return z.get_world_2d().direct_space_state.intersect_ray(PhysicsRayQueryParameters2D.create(a, b, 1)).is_empty()
