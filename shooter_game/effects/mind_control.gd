extends RefCounted
# ============================================================
#  MIND CONTROL - פריט מיוחד (progression/arsenal.gd -> SPECIALS "mind", שימוש אחד).
#  יורים קרן סגולה על זומבי -> 25 שניות (DURATION) אתה הזומבי:
#    A/D הליכה, SHIFT (או ג'ויסטיק עד הסוף בטלפון) ריצה, W/SPACE/JUMP קפיצה,
#    לחיצה / ג'ויסטיק הירי = שריטה (CLAW_DMG) לזומבים שלפניך.
#    C / לחצן ימני (בטלפון SKILL) = היכולת המיוחדת של אותו זומבי (effects/mind_abilities.gd: מערבולת, זינוק, ירי, יריקה, מכת קרקע, צרחה, פיצוץ).
#  הגיבור קפוא בטראנס סגול ולא נפגע. כל שאר הזומבים מזהים את הבוגד ומתנפלים עליו
#  (zombie.gd: mind_traitor / hurt()). בסוף הזמן (או אם הוא נהרג) - הזומבי קורס מת והשליטה חוזרת.
#  אי אפשר לשלוט בבוסים ובזומבים מיוחדים (can_control).
#  חלקים: fire() (הקרן), Session (השליטה), Beam / Aura / Trance / Hud (ציורים), draw_device() (המכשיר ביד / על הריצפה).
#  לשנות: DURATION, RANGE, CLAW_DMG, CLAW_CD, WALK_K, RUN_K, JUMP_V, TRAITOR_HP.
# ============================================================

const TouchAPI := preload("res://ui/touch_api.gd")   # שליטה במגע בטלפון (ui/touch_controls.gd)
const ZScript := preload("res://zombie.gd")
const Registry := preload("res://enemies/zombie_registry.gd")
const Art := preload("res://art.gd")
const Sfx := preload("res://sfx.gd")
const Particles := preload("res://particles.gd")
const MA := preload("res://effects/mind_abilities.gd")

const DURATION := 25.0
const RANGE := 760.0
const ASSIST := 0.2          # רדיאנים: כמה מותר לפספס ועדיין לתפוס זומבי
const COL := Color("b060ff")
const CLAW_DMG := 35
const CLAW_CD := 0.38
const CLAW_REACH := 58.0
const WALK_K := 1.25
const RUN_K := 1.9
const MIN_SPEED := 110.0
const JUMP_V := 560.0
const TRAITOR_HP := 100      # לפחות כמה חיים יש לזומבי בזמן השליטה
const NO_CONTROL := [Registry.HANGED, Registry.DRILLER, Registry.SWINGER, Registry.WALL_CRAWLER, Registry.IRONWING, Registry.KRAKEN,
	Registry.BLOODGATE, Registry.BROODMOTHER, Registry.MIRAGE_KING, Registry.STRANGER]   # זומבים מיוחדים שלא הגיוני לשלוט בהם


static func can_control(z: Node) -> bool:
	if z == null or z.dead or z.is_boss() or float(z.chase_range) > 600.0 or z.on_ceiling:
		return false
	if z.kind in [ZScript.HAND, ZScript.MECH, ZScript.JETPACK, ZScript.IMP, ZScript.RAT]:
		return false
	return not z.kind in NO_CONTROL


# יורים את הקרן. true = תפסנו זומבי (השימוש נגמר)
static func fire(pl: Node, from: Vector2, aim: Vector2) -> bool:
	var best: Node = null
	var q := PhysicsRayQueryParameters2D.create(from, from + aim * RANGE, 1 | 4)
	var hit: Dictionary = pl.get_world_2d().direct_space_state.intersect_ray(q)
	if hit and hit.collider != null and hit.collider.is_in_group("zombies"):
		best = hit.collider
	if best == null:   # עזרה בכיוון: הזומבי הכי קרוב לקו
		var best_a := ASSIST
		for z in pl.get_tree().get_nodes_in_group("zombies"):
			if z.dead:
				continue
			var to: Vector2 = z.global_position + Vector2(0.0, -30.0 * float(z.sc)) - from
			if to.length() > RANGE:
				continue
			var a := absf(aim.angle_to(to))
			if a < best_a:
				best_a = a
				best = z
	var end: Vector2 = from + aim * RANGE * 0.7
	if best != null:
		end = best.global_position + Vector2(0.0, -30.0 * float(best.sc))
	elif hit:
		end = hit.position
	var bm := Beam.new()
	bm.a = from
	bm.b = end
	pl.get_parent().add_child(bm)
	Sfx.play("zap", from, 0.0, 0.1)
	if best == null:
		pl._say("NO TARGET", Color(1, 1, 1, 0.75))
		return false
	if not can_control(best):
		pl._say("TOO STRONG TO CONTROL", COL)
		return false
	var s := Session.new()
	s.player = pl
	s.z = best
	pl.get_parent().add_child(s)
	return true


# ============================================================
#  הסשן: מחזיק את הזמן, מעביר את המצלמה, ומזיז את הזומבי לפי המקשים (drive נקרא מ-zombie.gd)
# ============================================================
class Session extends Node:
	var player: Node = null
	var z: Node = null
	var t := DURATION
	var claws := 0           # לבדיקות
	var kills := 0
	var _cam: Camera2D = null
	var _cam_pos := Vector2.ZERO
	var _claw_cd := 0.0
	var _jump_was := false
	var _abil_was := false
	var ability = null        # MA.Ability - היכולת של הזומבי הזה
	var _ended := false
	var _aura: Node2D = null
	var _trance: Node2D = null
	var _hud: CanvasLayer = null

	func _ready() -> void:
		ZScript.mind_traitor = z
		z.possessed = self
		if z.dormant:
			z._wake()
		z._rise_t = 0.0
		z._stagger_t = 0.0
		z._noticed = true
		z.hp = maxi(int(z.hp), TRAITOR_HP)
		var tm = z.type_mod   # זומבים שמתחבאים (GHILLIE / AMBUSHER) - יוצאים מהמחבוא
		if tm != null:
			if "_k" in tm:
				tm._k = 0.0
			if "_hide" in tm:
				tm._hide = 0.0
		ability = MA.Ability.new()
		ability.id = MA.ability_for(z)
		player.controllable = false
		player.mind_linked = true
		player._invuln = DURATION + 1.0
		player.velocity.x = 0.0
		_cam = player.get_viewport().get_camera_2d()
		if _cam != null and _cam.get_parent() == player:
			_cam_pos = _cam.position
			_cam.reparent(z)
			_cam.position = _cam_pos
		else:
			_cam = null
		_aura = Aura.new()
		_aura.sc = float(z.sc)
		z.add_child(_aura)
		_trance = Trance.new()
		player.add_child(_trance)
		_hud = CanvasLayer.new()
		_hud.layer = 20
		var h := Hud.new()
		h.session = self
		_hud.add_child(h)
		add_child(_hud)
		Sfx.play("boost", null, 2.0)
		z._popup("MIND CONTROL  -  " + str(ability.info().name), COL, 16, -80.0)
		Particles.burst(z.get_parent(), z.global_position + Vector2(0, -30.0 * float(z.sc)), "spark", Vector2.ZERO, 14)

	func _physics_process(delta: float) -> void:
		t -= delta
		if _ended:
			return
		if t <= 0.0 or not is_instance_valid(z) or z.dead or not is_instance_valid(player) or player.dead:
			_end()

	# הזומבי זז לפי המקשים (נקרא מ-zombie.gd במקום ה-AI שלו)
	func drive(zz: Node, delta: float) -> void:
		var dir := 0.0
		if Input.is_physical_key_pressed(KEY_A):
			dir -= 1.0
		if Input.is_physical_key_pressed(KEY_D):
			dir += 1.0
		var run: bool = Input.is_physical_key_pressed(KEY_SHIFT) or (TouchAPI.on() and TouchAPI.node().run)
		var spd := maxf(float(zz.chase_speed), MIN_SPEED) * (RUN_K if run else WALK_K)
		var by_ability: bool = ability.tick(zz, delta)   # מערבולת / זינוק: היכולת מזיזה אותו
		if not by_ability:
			if dir != 0.0:
				zz._dir = dir
			zz.velocity.x = move_toward(zz.velocity.x, dir * spd, 1500.0 * delta)
		if not zz.is_on_floor():
			zz.velocity.y += zz.gravity * delta
		var jump := Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_SPACE)
		if jump and not _jump_was and zz.is_on_floor() and not by_ability:
			zz.velocity.y = -JUMP_V
			Sfx.play("jump", zz.global_position, -4.0)
		_jump_was = jump
		zz.move_and_slide()
		zz.global_position.x = clampf(zz.global_position.x, 20.0, float(zz.world_w) - 20.0)
		if zz.is_on_floor():
			zz._walk_phase += delta * absf(zz.velocity.x) * 0.075 / float(zz.sc)
		# היכולת המיוחדת: C / לחצן ימני / SKILL
		var ab: bool = Input.is_physical_key_pressed(KEY_C) or (not TouchAPI.on() and Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT))
		if ab and not _abil_was and not zz.get_tree().paused:
			var aim := _aim_dir(zz)
			if absf(aim.x) > 0.2:
				zz._dir = signf(aim.x)
			ability.start(zz, aim)
		_abil_was = ab
		if zz.dead:   # פיצוץ עצמי
			return
		# שריטה
		_claw_cd -= delta
		var atk: bool = TouchAPI.node().fire if TouchAPI.on() else Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
		if atk and _claw_cd <= 0.0 and not zz.get_tree().paused:
			if TouchAPI.on():
				if TouchAPI.node().aiming and absf(TouchAPI.node().aim_dir.x) > 0.2:
					zz._dir = signf(TouchAPI.node().aim_dir.x)
			else:
				var mx: float = zz.get_global_mouse_position().x - zz.global_position.x
				if absf(mx) > 4.0:
					zz._dir = signf(mx)
			_claw(zz)

	# לאן מכוונים (ירי / יריקה): העכבר, או בטלפון הג'ויסטיק הימני (אחרת - קדימה)
	func _aim_dir(zz: Node) -> Vector2:
		var from: Vector2 = zz.global_position + Vector2(0.0, -36.0 * float(zz.sc))
		if TouchAPI.on():
			var t = TouchAPI.node()
			return t.aim_dir if t.aiming else Vector2(zz._dir, 0.0)
		var v: Vector2 = zz.get_global_mouse_position() - from
		return v.normalized() if v.length() > 4.0 else Vector2(zz._dir, 0.0)

	func _claw(zz: Node) -> void:
		_claw_cd = CLAW_CD
		claws += 1
		zz._bite_anim = 0.25
		Sfx.play("melee", zz.global_position, -2.0, 0.1)
		for o in zz.get_tree().get_nodes_in_group("zombies"):
			if o == zz or o.dead:
				continue
			var d: Vector2 = o.global_position - zz.global_position
			if d.x * float(zz._dir) > -8.0 and absf(d.x) < CLAW_REACH * float(zz.sc) + 10.0 * float(o.wf) and absf(d.y) < 60.0:
				o.take_damage(CLAW_DMG, o.global_position + Vector2(0.0, -30.0 * float(o.sc)), Vector2(zz._dir, -0.25), false, {"source": "mind", "fixed": CLAW_DMG})
				if o.dead:
					kills += 1

	func _end() -> void:
		if _ended:
			return
		_ended = true
		ZScript.mind_traitor = null
		if is_instance_valid(player):
			if _cam != null and is_instance_valid(_cam):
				_cam.reparent(player)
				_cam.position = _cam_pos
			player.controllable = true
			player.mind_linked = false
			player._invuln = 1.0
		if is_instance_valid(_trance):
			_trance.queue_free()
		if is_instance_valid(z):
			z.possessed = null
			if is_instance_valid(_aura):
				_aura.queue_free()
			if not z.dead:   # הזמן נגמר: הזומבי קורס מת
				z.hp = 0
				z._die(Vector2(0.0, -0.3))
		Sfx.play("whoosh", null, -2.0)
		queue_free()


# ---- הקרן הסגולה ----
class Beam extends Node2D:
	var a := Vector2.ZERO
	var b := Vector2.ZERO
	var life := 0.35

	func _ready() -> void:
		z_index = 9

	func _process(delta: float) -> void:
		life -= delta
		if life <= 0.0:
			queue_free()
			return
		queue_redraw()

	func _draw() -> void:
		var k := life / 0.35
		var n := (b - a).orthogonal().normalized()
		var pts := PackedVector2Array()
		for i in 13:
			var u := float(i) / 12.0
			pts.append(a.lerp(b, u) + n * sin(u * 18.0 + life * 40.0) * 5.0 * k)
		draw_polyline(pts, Color(COL, 0.35 * k), 9.0 * k, true)
		draw_polyline(pts, Color(0.92, 0.8, 1.0, 0.9 * k), 2.5, true)
		draw_circle(b, 12.0 * k, Color(COL, 0.4 * k))


# ---- הילה על הזומבי שבשליטה ----
class Aura extends Node2D:
	var sc := 1.0
	var _t := 0.0

	func _ready() -> void:
		show_behind_parent = true

	func _process(delta: float) -> void:
		_t += delta
		queue_redraw()

	func _draw() -> void:
		var c := Vector2(0.0, -28.0 * sc)
		var p := 0.5 + 0.5 * sin(_t * 6.0)
		draw_circle(c, (30.0 + 4.0 * p) * sc, Color(COL, 0.16))
		draw_arc(c, (34.0 + 3.0 * p) * sc, _t * 2.0, _t * 2.0 + PI * 1.3, 20, Color(COL, 0.6), 2.0, true)
		draw_arc(c + Vector2(0, -34.0 * sc), 6.0 * sc, 0.0, TAU, 12, Color(0.9, 0.75, 1.0, 0.8), 1.5, true)   # "קורונה" מעל הראש


# ---- הגיבור בטראנס ----
class Trance extends Node2D:
	var _t := 0.0

	func _ready() -> void:
		z_index = 1

	func _process(delta: float) -> void:
		_t += delta
		queue_redraw()

	func _draw() -> void:
		var c := Vector2(0.0, -58.0)
		for i in 3:
			var r := 6.0 + float(i) * 5.0
			draw_arc(c, r, _t * (2.0 + float(i)), _t * (2.0 + float(i)) + PI, 14, Color(COL, 0.75 - float(i) * 0.2), 1.6, true)
		draw_circle(Vector2(0, -26), 26.0, Color(COL, 0.08))


# ---- טיימר ומסגרת סגולה על המסך ----
class Hud extends Node2D:
	var session = null

	func _process(_d: float) -> void:
		queue_redraw()

	func _draw() -> void:
		if session == null:
			return
		var vs := get_viewport().get_visible_rect().size
		var k := clampf(session.t / DURATION, 0.0, 1.0)
		var a := 0.25 + 0.1 * sin(Time.get_ticks_msec() * 0.008)
		for i in 4:   # מסגרת סגולה
			var w := 26.0 - float(i) * 6.0
			draw_rect(Rect2(Vector2.ZERO, vs), Color(COL, a * 0.35), false, w)
		var font := ThemeDB.fallback_font
		var txt := "MIND CONTROL  %.1f" % maxf(session.t, 0.0)
		var tw := font.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 22).x
		var y := 150.0
		draw_string(font, Vector2(vs.x * 0.5 - tw * 0.5 + 2, y + 2), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color(0, 0, 0, 0.6))
		draw_string(font, Vector2(vs.x * 0.5 - tw * 0.5, y), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color(0.9, 0.75, 1.0))
		draw_rect(Rect2(vs.x * 0.5 - 120.0, y + 10.0, 240.0, 6.0), Color(0, 0, 0, 0.5))
		draw_rect(Rect2(vs.x * 0.5 - 120.0, y + 10.0, 240.0 * k, 6.0), COL)
		var ab = session.ability
		if ab != null:   # היכולת + טעינה
			var label := ("SKILL: " if TouchAPI.on() else "C / RMB: ") + str(ab.info().name)
			var lw := font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 16).x
			var ready: bool = ab.ready_k() >= 1.0
			draw_string(font, Vector2(vs.x * 0.5 - lw * 0.5, y + 36.0), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(1.0, 0.85, 0.4) if ready else Color(1, 1, 1, 0.5))
			draw_rect(Rect2(vs.x * 0.5 - 60.0, y + 42.0, 120.0 * ab.ready_k(), 3.0), Color(1.0, 0.85, 0.4, 0.8))
		if not TouchAPI.on():
			var hint := "A/D move   SHIFT run   W jump   LMB claw"
			var hw := font.get_string_size(hint, HORIZONTAL_ALIGNMENT_LEFT, -1, 14).x
			draw_string(font, Vector2(vs.x * 0.5 - hw * 0.5, y + 62.0), hint, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(1, 1, 1, 0.7))


# ============================================================
#  המכשיר עצמו (ביד של הגיבור / על הריצפה): ידית, גוף כהה, סלילים סגולים זוהרים, צלחת בקצה
# ============================================================
static func draw_device(ci: CanvasItem, hand: Vector2, la: Vector2, t: float, s := 1.0) -> void:
	var tr := Transform2D(la.angle(), Vector2(s, s), 0.0, hand)
	var dark := Color("2a2630")
	Art.fill(ci, tr * PackedVector2Array([Vector2(-1, 1), Vector2(2, 1), Vector2(1, 6), Vector2(-2, 6)]), Color("1a1820"), Art.OUTLINE, 0.8)   # ידית
	Art.fill(ci, tr * PackedVector2Array([Vector2(-4, -3), Vector2(9, -3), Vector2(10, 2), Vector2(-4, 2)]), dark, Art.OUTLINE, 1.0)   # גוף
	var glow := 0.6 + 0.4 * sin(t * 8.0)
	for i in 3:   # סלילים
		var x := 0.0 + float(i) * 3.0
		ci.draw_line(tr * Vector2(x, -3.5), tr * Vector2(x, 2.5), Color(COL, glow), 1.4 * s)
	ci.draw_line(tr * Vector2(10, -0.5), tr * Vector2(13, -0.5), Color("4a4458"), 2.0 * s)   # קנה
	var tip := tr * Vector2(14, -0.5)
	ci.draw_arc(tip, 3.2 * s, la.angle() - 1.3, la.angle() + 1.3, 8, Color("8a84a0"), 1.3 * s, true)   # צלחת
	Art.glow(ci, tip, 4.0 * s, Color(COL, 0.5 * glow))
