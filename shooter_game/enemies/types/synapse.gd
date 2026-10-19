extends "res://enemies/zombie_type.gd"
# ============================================================
#  SYNAPSE (שלב 62, "THE HIVE MIND") - המעופף של השלב: קשרי עצב (נוירונים) מעופפים - גוף תא שקוף עם גרעין זוהר
#    ודנדריטים שמתפתלים. הם אף פעם לא לבד: זוג או שלישייה (קבוצה, make_group) שמחוברים בזרם חשמלי ביניהם.
#  מה הם למדו, וממה: הגיבור מתחמק מכל דבר שנזרק עליו - קפיצה, גלגול. אז הכוורת לא זורקת: היא מותחת קיר של זרם
#    לרוחב הדרך. "THEY LINK NOW": הקבוצה מסתובבת סביב מרכז משותף (המוט / המשולש מסתובב) והזרם בין הקשרים חותך דרכך.
#  תעופה חדשה: SACCADE - כמו עין: מרחפים קפואים (HOLD_T) ואז "קופצים" בבת אחת (SNAP_T) למקום חדש ליד הגיבור.
#  הזרם במחזור: REST (REST_T, כבוי - בטוח לעבור), CHARGE (CHARGE_T, ניצוצות מהבהבים - אזהרה), LIVE (LIVE_T, פוגע:
#    DMG + האטה. גם זומבים שנוגעים בו נצלים - DMG_Z "FRIED"). נגד: לירות בקשר אחד (NODE_HP, פיצוץ x BLAST_MULT) -
#    "LINK BROKEN". קשר שנשאר לבד = STRAY: עף אליך ומזנק בניצוץ מקרוב (STRAY_*).
#  לומד (main meta "syn_breaks" >= LEARN_BREAKS - כמה קישורים שברת): "THEY KEEP A SPARE NOW" - קבוצות חדשות מגיעות
#    עם קשר רזרבי (spare) שמרחף מאחור ומתחבר במקום מי שנפל (RELINK_T), והן נפרשות רחב יותר (x WIDE).
#  ביצועים: אין צמתים לזרם - המנהיג (הקשר הראשון החי בקבוצה) מצייר את הקישורים ב-draw call שלו. מיקום ישיר (בלי
#    move_and_slide, collision_mask 0) כמו BLOOM. הקבוצה = Dictionary משותף.
#  לשנות: NODE_HP, R, WIDE, HOVER, REST_T, CHARGE_T, LIVE_T, ROT_*, HOLD_T, SNAP_T, DMG, SLOW, HIT_CD, DMG_Z, STRAY_*,
#    RELINK_T, LEARN_BREAKS.
# ============================================================

const Decor := preload("res://effects/s62_decor.gd")
const Registry := preload("res://enemies/zombie_registry.gd")
const U := Decor.U

const SOUNDS := {
	"syn_charge": {"rev": 0.3, "layers": [["S", 220, 880, 0.0, 0.55, 0.05, 2.0, 0.18, 1.0, 0.0], ["N", 0, 0, 0.0, 0.55, 0.3, 2.0, 0.15, 1.0, 0, 0.6]]},
	"syn_live": {"drive": 2.0, "layers": [["Q", 60, 60, 0.0, 0.5, 0.0, 3.0, 0.25, 0.5, 0], ["C", 0, 0, 0.0, 0.5, 0.0, 3.0, 0.6, 1.0, 0], ["S", 3200, 2800, 0.0, 0.4, 0.0, 6.0, 0.06, 1.0, 0]]},
	"syn_zap": {"drive": 2.4, "layers": [["N", 0, 0, 0.0, 0.2, 0.0, 14.0, 0.8, 1.0, 0, 0.6], ["Q", 120, 60, 0.0, 0.25, 0.0, 10.0, 0.4, 0.4, 0], ["C", 0, 0, 0.0, 0.2, 0.0, 9.0, 0.6, 1.0, 0]]},
	"syn_snap": [["N", 0, 0, 0.0, 0.08, 0.0, 40.0, 0.25, 0.8, 0, 0.5], ["S", 1800, 900, 0.0, 0.06, 0.0, 50.0, 0.08, 1.0, 0]],
	"syn_break": {"drive": 1.8, "layers": [["C", 0, 0, 0.0, 0.3, 0.0, 8.0, 0.7, 1.0, 0], ["S", 1600, 200, 0.0, 0.35, 0.0, 7.0, 0.3, 1.0, 0], ["N", 0, 0, 0.0, 0.25, 0.0, 12.0, 0.4, 1.0, 0, 0.5]]},
	"syn_relink": {"rev": 0.3, "layers": [["S", 440, 1320, 0.0, 0.4, 0.02, 4.0, 0.2, 1.0, 0.0], ["S", 660, 1760, 0.1, 0.35, 0.02, 4.0, 0.15, 1.0, 0.0]]},
}

const NODE_HP := 14
const NODE_BOX := 26.0
const OFF := 14.0                 # z.global_position = מרכז הקשר + (0, OFF)
const R := 96.0                   # חצי אורך המוט (זוג) / רדיוס המשולש
const WIDE := 1.4                 # (למד) נפרשים רחב יותר
const HOVER := 108.0              # מרכז הקבוצה מעל הרצפה (המוט חותך את הגובה של הגיבור)
const WAKE_R := 950.0
const REST_T := 1.4
const CHARGE_T := 0.55
const LIVE_T := 2.2
const ROT_REST := 0.6
const ROT_LIVE := 1.45
const HOLD_T := Vector2(0.9, 1.5)
const CREEP := 45.0               # (חי) המרכז זוחל אליך בזמן ההמתנה
const SNAP_T := 0.17
const DMG := 1
const SLOW := 0.6
const HIT_CD := 0.9
const DMG_Z := 30
const LINK_W := 7.0               # עובי הזרם (לפגיעה)
const BLAST_MULT := 2.0
const HEAD_NORM := 0.5
const LEG_NORM := 1.3
const STRAY_R := 82.0
const STRAY_TELL := 0.5
const STRAY_CD := 2.2
const STRAY_DMG := 1
const STRAY_V := 230.0
const RELINK_T := 0.8
const LEARN_BREAKS := 3

enum {REST, CHARGE, LIVE}
# לבדיקות
var link_hits := 0
var fried := 0
var snaps := 0
var zaps := 0
var zap_hits := 0
var relinks := 0

var g: Dictionary = {}            # הקבוצה המשותפת
var spare := false
var node := Vector2.ZERO          # מרכז הקשר בעולם
var _ground := 630.0
var _seed := 0.0
var _t := 0.0
var _st := 0.0
var _cd := 1.0
var _tell := -1.0
var _blast := false
var _zap := -1.0                  # הבזק ניצוץ (STRAY)
var _zap_to := Vector2.ZERO


func stats() -> Dictionary:
	return {"name": "SYNAPSE", "hp": NODE_HP, "walk": 60.0, "chase": 90.0, "damage": 1, "bite_delay": 1.0, "scale": 1.0, "width": 1.0,
		"duck": 0.0, "cover": 0.0, "skin": Color("d8c8a8"), "shirt": Color("8a6a58"), "pants": Color("4a3a30"), "shoe": Color("2a2018"),
		"points": 240, "ragdoll": false, "flesh": false}


func use_brain_movement() -> bool:
	return false


func can_bite() -> bool:
	return false


func can_groan() -> bool:
	return false


func death_sound() -> String:
	return "syn_break"


func _main() -> Node:
	return z.get_parent()


func setup() -> void:
	_ground = z.global_position.y
	_seed = float(z.get_instance_id() % 997) * 0.53
	z.hp = NODE_HP
	z.max_hp = NODE_HP
	z._dir = 1.0
	node = z.global_position + Vector2(0.0, -HOVER)
	z.global_position = node + Vector2(0.0, OFF)
	var rs := z._shape.shape as RectangleShape2D
	rs.size = Vector2(NODE_BOX, NODE_BOX)
	z._shape.position = Vector2(0.0, -OFF)
	z.collision_mask = 0


# ============================================================
#  קבוצה: השלב קורא לזה (stage_62). n = כמה מקושרים (2 / 3). (למד) + spare
# ============================================================
static func make_group(m: Node, x: float, ground: float, n: int) -> Dictionary:
	var learned: bool = int(m.get_meta("syn_breaks", 0)) >= LEARN_BREAKS
	var gr := {"m": [], "spare": null, "c": Vector2(x, ground - HOVER), "from": Vector2(x, ground - HOVER), "to": Vector2(x, ground - HOVER),
		"ang": randf() * TAU, "spin": 1.0 if randf() < 0.5 else -1.0, "r": R * (WIDE if learned else 1.0), "state": REST, "t": REST_T * randf_range(0.5, 1.0),
		"hold": randf_range(HOLD_T.x, HOLD_T.y), "snap": -1.0, "hit_cd": 0.0, "learned": learned, "relink": 0.0, "awake": false, "ground": ground}
	for i in n + (1 if learned else 0):
		var w = m._spawn_zombie(x + float(i) * 30.0, ground, Registry.SYNAPSE)
		if w == null or w.type_mod == null:
			continue
		w.dormant = false
		w.type_mod.join(gr, i >= n)
	return gr


func join(gr: Dictionary, as_spare: bool) -> void:
	g = gr
	spare = as_spare
	if as_spare:
		g.spare = z
	else:
		(g.m as Array).append(z)
	node = (g.c as Vector2) + Vector2(0.0, -40.0 if as_spare else 0.0)
	z.global_position = node + Vector2(0.0, OFF)


func _members() -> Array:
	return g.m if not g.is_empty() else []


func _leader() -> bool:
	var ms := _members()
	return not ms.is_empty() and ms[0] == z


func linked() -> bool:
	return not spare and _members().size() >= 2


# היכן הקשר i צריך להיות (סביב מרכז הקבוצה)
func _slot(i: int, n: int) -> Vector2:
	var a: float = float(g.ang) + TAU * float(i) / float(n)
	var r: float = g.r
	if n == 2:
		a = float(g.ang) + PI * float(i)
	return (g.c as Vector2) + Vector2(cos(a), sin(a)) * r


# ============================================================
#  תנועה
# ============================================================
func physics(pl: Node, delta: float) -> bool:
	_t += delta
	_st -= delta
	_cd -= delta
	if _zap >= 0.0:
		_zap += delta
		if _zap > 0.25:
			_zap = -1.0
	if z.dead:
		return false
	var has: bool = pl != null and not pl.dead
	if g.is_empty() or (not spare and _members().size() < 2):
		_stray(pl, has, delta)
	elif spare:
		_spare_move(pl, has, delta)
	else:
		if _leader():
			_group_tick(pl, has, delta)
		var ms := _members()
		var i := ms.find(z)
		var want := _slot(i, ms.size())
		var k := 1.0 - exp(-(22.0 if float(g.snap) >= 0.0 else 9.0) * delta)
		node = node.lerp(want, k)
		node += Vector2(sin(_t * 7.0 + _seed), cos(_t * 6.0 + _seed)) * 0.25   # רעד קטן
	node.y = clampf(node.y, _ground - 520.0, _ground - 14.0)
	node.x = clampf(node.x, 30.0, z.world_w - 30.0)
	z.global_position = node + Vector2(0.0, OFF)
	z.velocity = Vector2.ZERO
	return true


# המנהיג מריץ את הקבוצה: SACCADE (מחכה -> קופץ), סיבוב, מחזור הזרם, פגיעות
func _group_tick(pl: Node, has: bool, delta: float) -> void:
	var c: Vector2 = g.c
	var pp: Vector2 = pl.global_position if has else c
	if not bool(g.awake):
		if has and absf(pp.x - c.x) < WAKE_R and absf(pp.y - c.y) < 600.0:
			g.awake = true
		else:
			g.ang = float(g.ang) + 0.3 * delta
			g.c = c + Vector2(sin(_t * 0.5 + _seed) * 6.0, cos(_t * 0.7) * 4.0) * delta
			return
	# הזרם
	g.t = float(g.t) - delta
	var stt: int = g.state
	if float(g.relink) > 0.0:   # (spare) מתחבר מחדש - הזרם כבוי
		g.relink = float(g.relink) - delta
		stt = REST
		g.state = REST
		g.t = maxf(float(g.t), 0.3)
	elif float(g.t) <= 0.0:
		match stt:
			REST:
				g.state = CHARGE
				g.t = CHARGE_T
				Sfx.play("syn_charge", c, -4.0, 0.1, 2)
			CHARGE:
				g.state = LIVE
				g.t = LIVE_T
				Sfx.play("syn_live", c, -2.0, 0.1, 2)
			_:
				g.state = REST
				g.t = REST_T
	g.ang = float(g.ang) + float(g.spin) * (ROT_LIVE if int(g.state) == LIVE else ROT_REST) * delta
	# SACCADE
	if float(g.snap) >= 0.0:
		g.snap = float(g.snap) + delta
		var k := clampf(float(g.snap) / SNAP_T, 0.0, 1.0)
		k = 1.0 - pow(1.0 - k, 3.0)
		g.c = (g.from as Vector2).lerp(g.to, k)
		if float(g.snap) >= SNAP_T:
			g.snap = -1.0
			g.hold = randf_range(HOLD_T.x, HOLD_T.y)
	else:
		g.hold = float(g.hold) - delta
		if has and int(g.state) == LIVE:   # הזרם חי: המרכז זוחל אליך
			g.c = c + Vector2(clampf(pp.x - c.x, -CREEP * delta, CREEP * delta), 0.0)
		if g.hold <= 0.0 and has:
			g.from = c
			g.to = _pick_center(pl, c)
			g.snap = 0.0
			snaps += 1
			if Art.on_screen(z, c):
				Sfx.play("syn_snap", c, -6.0, 0.2, 3)
	# פגיעות: הזרם חי
	g.hit_cd = float(g.hit_cd) - delta
	if int(g.state) == LIVE:
		if has and float(g.hit_cd) <= 0.0:
			_check_hero(pl)
		if Engine.get_physics_frames() % 6 == 0:
			_fry()
	if Art.on_screen(z, c, 260.0) and int(g.state) != REST:
		z.queue_redraw()


# לאן לקפוץ: לפני הגיבור, בגובה שהמוט חותך אותו (אבל לא מתחת לרצפה)
func _pick_center(pl: Node, c: Vector2) -> Vector2:
	var pp: Vector2 = pl.global_position
	var side: float = signf(c.x - pp.x)
	if side == 0.0:
		side = 1.0
	var r: float = g.r
	var x := pp.x + side * randf_range(20.0, 140.0)
	if randf() < 0.25:   # לפעמים קופצים מעליך לצד השני
		x = pp.x - side * randf_range(40.0, 120.0)
	var y := pp.y - randf_range(40.0, 80.0)
	y = minf(y, float(g.ground) - r - 12.0)
	y = maxf(y, pp.y - 260.0)
	return Vector2(clampf(x, 60.0, z.world_w - 60.0), y)


func _links() -> Array:
	var ms := _members()
	var out := []
	if ms.size() == 2:
		out.append([ms[0], ms[1]])
	elif ms.size() >= 3:
		for i in ms.size():
			out.append([ms[i], ms[(i + 1) % ms.size()]])
	return out


func _seg_hits(a: Vector2, b: Vector2, r: Rect2) -> bool:
	for i in 9:
		if r.has_point(a.lerp(b, float(i) / 8.0)):
			return true
	return false


func _check_hero(pl: Node) -> void:
	var r: Rect2 = pl.body_rect().grow(LINK_W * 0.5)
	for l in _links():
		var a: Vector2 = l[0].type_mod.node
		var b: Vector2 = l[1].type_mod.node
		if _seg_hits(a, b, r):
			g.hit_cd = HIT_CD
			if pl._roll_t <= 0.0:
				link_hits += 1
				pl.slow_t = maxf(float(pl.slow_t), SLOW)
				Particles.burst(_main(), pl.global_position + Vector2(0, -30), "spark", Vector2.UP, 8)
			pl.hurt(DMG, Vector2(signf(pl.global_position.x - float(g.c.x) + 0.01) * 0.5, -0.4))
			Sfx.play("syn_zap", pl.global_position, 0.0, 0.1, 2)
			return


# זומבים שנכנסים לזרם - נצלים (גם הם לא יודעים לעבור דרכו)
func _fry() -> void:
	var ls := _links()
	if ls.is_empty():
		return
	var c: Vector2 = g.c
	for o in z.get_tree().get_nodes_in_group("zombies"):
		if o.dead or o.kind == z.kind or o.is_boss() or absf(o.global_position.x - c.x) > float(g.r) + 40.0:
			continue
		if float(o.get_meta("syn_fry", -9.0)) > float(o._time):
			continue
		var r := Rect2(o.global_position + Vector2(-12.0, -50.0 * float(o.sc)), Vector2(24.0, 50.0 * float(o.sc)))
		for l in ls:
			if _seg_hits(l[0].type_mod.node, l[1].type_mod.node, r):
				o.set_meta("syn_fry", float(o._time) + 1.0)
				fried += 1
				o._popup("FRIED", Decor.PULSE, 13, -70.0)
				o.take_damage(DMG_Z, o.global_position + Vector2(0, -30), Vector2.UP, true, {"source": "hazard", "fixed": DMG_Z})
				Particles.burst(_main(), o.global_position + Vector2(0, -30), "spark", Vector2.UP, 6)
				break


# הרזרבי: מרחף מאחורי הקבוצה (רחוק ממך), מחכה שמישהו ייפול
func _spare_move(pl: Node, has: bool, delta: float) -> void:
	var c: Vector2 = g.c
	var away: float = signf(c.x - pl.global_position.x) if has else 1.0
	if away == 0.0:
		away = 1.0
	var want := c + Vector2(away * (float(g.r) + 90.0), -70.0 + sin(_t * 1.3) * 10.0)
	node = node.lerp(want, 1.0 - exp(-4.0 * delta))


# קשר בודד: עף אליך ומזנק בניצוץ מקרוב
func _stray(pl: Node, has: bool, delta: float) -> void:
	if not has:
		return
	var tgt: Vector2 = pl.global_position + Vector2(0.0, -40.0)
	var d := tgt - node
	if _tell >= 0.0:
		_tell += delta
		node += Vector2(sin(_t * 50.0), cos(_t * 43.0)) * 0.8
		if _tell >= STRAY_TELL:
			_tell = -1.0
			_cd = STRAY_CD
			zaps += 1
			_zap = 0.0
			_zap_to = tgt
			Sfx.play("syn_zap", node, 0.0, 0.1, 2)
			if d.length() < STRAY_R * 1.25:
				if pl._roll_t <= 0.0:
					zap_hits += 1
				pl.hurt(STRAY_DMG, Vector2(signf(d.x) * 0.5, -0.3))
		return
	if d.length() > STRAY_R * 0.7:   # SACCADE קצר: עוצר, קופץ
		var k := fposmod(_t * 1.6 + _seed, 1.0)
		var v := STRAY_V * (3.2 if k < 0.2 else 0.25)
		node += d.normalized() * v * delta
	if _cd <= 0.0 and d.length() < STRAY_R:
		_tell = 0.0
		Sfx.play("syn_charge", node, -2.0, 0.1, 2)


# ============================================================
#  פגיעות / מוות
# ============================================================
func on_damage(_amount: int, _hit_pos: Vector2, _dir: Vector2, src: Dictionary) -> bool:
	if z.dead:
		return true
	var s := str(src.get("source", "bullet"))
	_blast = not (s == "bullet" or s == "melee" or s == "laser" or s == "taser" or s == "fire")
	if s == "hazard" and _members().has(z):   # (MAW / קשר עצב אחר) לא נפגע מהזרם של עצמו
		return true
	return true


func damage_mult(zone: String, _src: Dictionary) -> float:
	if _blast:
		_blast = false
		return BLAST_MULT
	if zone == "head":
		return HEAD_NORM
	if zone == "leg":
		return LEG_NORM
	return 1.0


func on_death() -> void:
	var m := _main()
	z.collision_mask = 1 | 16
	if g.is_empty():
		return
	var was_linked := linked()
	if spare:
		g.spare = null
		return
	(g.m as Array).erase(z)
	var at := node
	if Art.on_screen(z, at):
		Particles.burst(m, at, "spark", Vector2.UP, 10)
		Particles.burst(m, at, "hit", Vector2.UP, 5)
	if was_linked:
		z._popup("LINK BROKEN", Decor.PULSE, 14, -40.0)
		if m != null:
			m.set_meta("syn_breaks", int(m.get_meta("syn_breaks", 0)) + 1)
	elif not (g.m as Array).is_empty():
		return
	# (למד) הרזרבי נכנס במקום
	var sp = g.spare
	if sp != null and is_instance_valid(sp) and not sp.dead and sp.type_mod != null:
		g.spare = null
		sp.type_mod.spare = false
		(g.m as Array).append(sp)
		g.relink = RELINK_T
		sp.type_mod.relinks += 1
		Sfx.play("syn_relink", sp.global_position, 0.0, 0.1, 2)
		if m != null and not m.has_meta("syn_spare_said"):
			m.set_meta("syn_spare_said", true)
			sp._popup("THEY KEEP A SPARE NOW", Color("a8f0ff"), 13, -60.0)
		else:
			sp._popup("RELINKED", Color("a8f0ff"), 12, -50.0)
	elif (g.m as Array).size() == 1:
		var last = g.m[0]
		if is_instance_valid(last) and not last.dead:
			last.type_mod._cd = 0.8


func wants_redraw() -> bool:
	return true


# ============================================================
#  ציור: גוף תא עצב (סומה) שקוף-בשרי, גרעין זוהר, דנדריטים מתפתלים עם קצוות זוהרים, אקסון לכיוון השותף.
#  המנהיג מצייר גם את הזרם (עולם, בלי היפוך): כבוי = סיב עצב רפוי, טעינה = ניצוצות שרצים, חי = ברק כפול.
# ============================================================
func draw() -> bool:
	var pts := PackedVector2Array()
	var cols := PackedColorArray()
	DrawBatch.set_transform_matrix(z, Transform2D.IDENTITY)
	var c := Vector2(0.0, -OFF)
	var tt := _t
	if z.dead:
		U.oval(pts, cols, c, 9.0, 6.0, Color("3a2a22"), 10)
		U.oval(pts, cols, c, 3.0, 3.0, Color(0.2, 0.3, 0.32), 6)
		for q in 5:
			U.seg(pts, cols, c, c + Vector2.from_angle(float(q) * 1.25 + 0.3) * 12.0 + Vector2(0, 5.0), 1.6, Color("4a3428"))
		U.flush(z, pts, cols)
		return true
	var stt: int = int(g.state) if not g.is_empty() else REST
	var live := linked() and stt == LIVE
	var charge := linked() and stt == CHARGE
	var energy := 1.0 if live else (0.5 + 0.5 * sin(tt * 40.0) if charge else 0.15)
	if _tell >= 0.0:
		energy = 0.5 + 0.5 * sin(tt * 50.0)
	# הזרם (רק המנהיג)
	if _leader() and linked():
		for l in _links():
			var a: Vector2 = l[0].type_mod.node - z.global_position
			var b: Vector2 = l[1].type_mod.node - z.global_position
			_draw_link(pts, cols, a, b, stt, tt)
	# הדנדריטים
	var fl: bool = z._flash > 0.0
	for q in 6:
		var an := float(q) / 6.0 * TAU + sin(tt * 1.7 + float(q) * 1.3 + _seed) * 0.35
		var ln := 16.0 + U.h(q, int(_seed * 10.0)) * 9.0
		var mid := c + Vector2.from_angle(an) * ln * 0.55
		var tip := c + Vector2.from_angle(an + sin(tt * 2.3 + float(q)) * 0.4) * ln
		U.taper(pts, cols, c, mid, 4.4, 2.4, Color("8a6a58"), Color("a88a70"))
		U.taper(pts, cols, mid, tip, 2.4, 0.8, Color("a88a70"), Color("c8b090"))
		U.taper(pts, cols, mid, mid + Vector2.from_angle(an + 0.9) * ln * 0.35, 1.6, 0.6, Color("a88a70"), Color("c8b090"))
		U.oval(pts, cols, tip, 1.6, 1.6, Color(Decor.PULSE, 0.4 + 0.5 * energy), 6)
	# האקסון (זנב) - נגרר אחרי הקפיצה
	var tail := c + Vector2(-sin(tt * 1.1 + _seed) * 6.0, 20.0)
	U.taper(pts, cols, c + Vector2(0, 6.0), tail, 3.4, 0.8, Color("8a6a58"), Color("6a5040"))
	# גוף התא
	var body := Color("d8c0a0") if not fl else Color.WHITE
	U.oval(pts, cols, c, 11.0, 10.0, Color("5a3a30"), 14)
	U.oval(pts, cols, c, 9.8, 8.8, Color(body, 0.92), 14)
	U.oval(pts, cols, c + Vector2(-3.0, -3.5), 4.0, 2.4, Color(1, 1, 1, 0.3), 8)
	# הגרעין: זוהר לפי הזרם (חי = לבן-תכלת)
	var nc := Decor.PULSE.lerp(Color.WHITE, energy * 0.6)
	U.halo(pts, cols, c, 16.0 + 10.0 * energy, 16.0 + 10.0 * energy, Color(Decor.PULSE, 0.18 + 0.3 * energy), 12)
	U.oval(pts, cols, c, 4.6, 4.6, Color(0.1, 0.3, 0.4, 0.9), 10)
	U.oval(pts, cols, c, 3.2 + energy, 3.2 + energy, Color(nc, 0.95), 10)
	if spare:   # הרזרבי: טבעת המתנה
		U.halo(pts, cols, c, 22.0, 22.0, Color(0.7, 0.95, 1.0, 0.12 + 0.08 * sin(tt * 3.0)), 12)
	# ניצוץ של קשר בודד
	if _zap >= 0.0:
		_bolt(pts, cols, c, _zap_to - z.global_position, 1.0 - _zap / 0.25, tt, 2.2)
	U.flush(z, pts, cols)
	return true


func _draw_link(pts: PackedVector2Array, cols: PackedColorArray, a: Vector2, b: Vector2, stt: int, tt: float) -> void:
	var relink: bool = float(g.relink) > 0.0
	if stt == REST or relink:   # סיב עצב רפוי עם פולס איטי
		var sag := 18.0 if not relink else 10.0 + 8.0 * sin(tt * 30.0)
		U.nerve(pts, cols, a, b, sag, 2.2, fposmod(tt * 0.6, 1.0), Color(Decor.NERVE_D, 0.75), 12)
		return
	if stt == CHARGE:   # ניצוצות שרצים לאורך הסיב + קו מהבהב
		U.nerve(pts, cols, a, b, 8.0, 2.4, -1.0, Color(Decor.NERVE, 0.6), 12)
		for q in 4:
			var k := fposmod(tt * 2.4 + float(q) * 0.25, 1.0)
			var p := a.lerp(b, k) + Vector2(0.0, sin(k * PI) * 8.0)
			U.oval(pts, cols, p, 3.0, 3.0, Color(Decor.PULSE, 0.9), 6)
		if fposmod(tt * 14.0, 1.0) < 0.5:
			_bolt(pts, cols, a, b, 0.4, tt, 1.2)
		return
	# חי: ברק כפול + הילה
	var dirv := (b - a)
	var n := Vector2(-dirv.y, dirv.x).normalized()
	U.quad(pts, cols, a + n * 9.0, b + n * 9.0, b, a, Color(Decor.PULSE, 0.0), Color(Decor.PULSE, 0.0), Color(Decor.PULSE, 0.3), Color(Decor.PULSE, 0.3))
	U.quad(pts, cols, a, b, b - n * 9.0, a - n * 9.0, Color(Decor.PULSE, 0.3), Color(Decor.PULSE, 0.3), Color(Decor.PULSE, 0.0), Color(Decor.PULSE, 0.0))
	_bolt(pts, cols, a, b, 1.0, tt, 2.6)
	_bolt(pts, cols, a, b, 0.7, tt + 0.37, 1.4)


# ברק משונן מ-a ל-b (משתנה 20 פעם בשנייה)
func _bolt(pts: PackedVector2Array, cols: PackedColorArray, a: Vector2, b: Vector2, alpha: float, tt: float, w: float) -> void:
	var fr := int(tt * 20.0)
	var dv := b - a
	var n := Vector2(-dv.y, dv.x).normalized()
	var prev := a
	var segs := 9
	for i in range(1, segs + 1):
		var u := float(i) / float(segs)
		var off := 0.0 if i == segs else (U.h(i + fr * 13, int(_seed * 7.0)) - 0.5) * 16.0 * sin(u * PI)
		var p := a + dv * u + n * off
		U.seg(pts, cols, prev, p, w, Color(0.85, 0.97, 1.0, 0.95 * alpha))
		prev = p
