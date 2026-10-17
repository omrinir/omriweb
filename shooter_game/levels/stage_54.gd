extends "res://levels/stage_base.gd"
# ============================================================
#  STAGE 54 - "LAST BRIDGE" (אזור שישי - החרוט הדרומי, שלב 9 - סוף האזור) - "THEY LEARNED TO FOLLOW"
#  (הסיפור: המתים זזים דרומה בכוונה, ומישהו מוביל אותם - THE ARCHITECT. הגשר הישן מעל הריו נגרו, בין כרמן דה פטגונס
#   לוויֶדמה, הוא השער האחרון לפטגוניה. הצבא השאיר מטענים על הגשר ונעלם. הגיבור צריך לדרוך אותם, להגיע לגדה הדרומית,
#   להרוג את THE ARCHITECT - וכשהוא מת כל העדר שלו נופל, והגשר מתפוצץ מאחוריך.)
#  (effects/s54_decor.gd): לילה, ירח ענק ונמוך, זוהר קר בדרום, הרי פטגוניה, מגדל הכנסייה של פטגונס, הנהר עם העדר שחוצה
#  וסירות בוערות, המסבך של הצד השני. בעולם: מסבך הברזל של הגשר, פנסי גשר (חלקם מהבהבים), משאיות שיירה נטושות.
#  מבנה: הגדה הצפונית (TOWN_END) -> הגשר הארוך -> מחסום הצבא (GATE_X) -> הזירה בגדה הדרומית (BRIDGE_END).
#  מטענים (CHARGES): עומדים ליד כל אחד ARM_T שניות (Decor.ChargePoint). המחסום בכניסה לזירה נפתח רק כשכולם דרוכים.
#    חזרה מנקודת ביקורת: מטענים שמאחוריך כבר דרוכים.
#  קטע סיפור (STORY_X): כביש ישר ונקי לפני הזירה - בלי מכשולים / מלכודות / זומבים של השלב. הסצנה יכולה לקרוא ל-on_story_beat().
#  קומה שנייה: מסלולי שירות תלויים מתחת לקורה העליונה (GANTRIES) + המרפסת בעיר (BALCONY), עם סולמות ואספקה למעלה.
#  מלכודות: BrokenDeck (DECKS) - לוחות שנופלים לנהר (גם 3 זומבים מפילים), נשאר חור שזומבים נופלים בו.
#           RollingTruck (TRUCK_X) - יורים בבלם, מתגלגלת, דורסת ומתפוצצת. LiveCable (CABLES) - כבל קרוע שפורק קשת לכביש.
#  זומבים: SHEPHERD (רועה: מוביל "רבים", מותו מפיל את כולם), STINGER (עוקץ מהגרון, תולעים), DARKSEEKER (שונא אור, זוחל על המסבך).
#  בוס: THE ARCHITECT (enemies/types/shepherd.gd, מצב בוס). כשהוא מת: כל הזומבים נופלים, ואז BridgeCollapse.
#  לשנות: CHARGES, GATE_X, STORY_X, GANTRIES, TIER, DARK, DECKS, TRUCK_X, CABLES, STINGERS, LAMP_GAP, DARKNESS, zombie_weights().
# ============================================================

const Decor := preload("res://effects/s54_decor.gd")
const S11 := preload("res://effects/s11_decor.gd")
const PickupScript := preload("res://pickup.gd")
const Sfx := preload("res://sfx.gd")

const SOUNDS := {
	"b54_creak": [["S", 150, 120, 0.0, 0.8, 0.05, 2.4, 0.4, 1.0, 0.35], ["N", 0, 0, 0.0, 0.7, 0.05, 3.0, 0.3, 0.25, 0], ["S", 95, 80, 0.3, 0.5, 0.05, 3.0, 0.3, 1.0, 0.4]],
	"b54_tick": [["Q", 1500, 1500, 0.0, 0.04, 0.0, 60.0, 0.12, 1.0, 0]],
	"b54_beep": [["Q", 1180, 1180, 0.0, 0.07, 0.0, 40.0, 0.16, 1.0, 0]],
	"b54_arm": [["Q", 880, 880, 0.0, 0.08, 0.0, 40.0, 0.2, 1.0, 0], ["Q", 1320, 1320, 0.1, 0.08, 0.0, 40.0, 0.2, 1.0, 0], ["Q", 1760, 1760, 0.2, 0.22, 0.0, 12.0, 0.22, 1.0, 0], ["C", 0, 0, 0.0, 0.05, 0.0, 60.0, 0.4, 1.0, 0]],
	"b54_buzz": [["Q", 100, 100, 0.0, 0.75, 0.05, 1.0, 0.18, 0.5, 0.02], ["N", 0, 0, 0.0, 0.75, 0.1, 1.5, 0.15, 0.9, 0, 0.5], ["C", 0, 0, 0.0, 0.75, 0.0, 1.0, 0.6, 1.0, 0]],
	"b54_zap": [["Q", 70, 60, 0.0, 0.35, 0.0, 6.0, 0.35, 0.6, 0], ["C", 0, 0, 0.0, 0.35, 0.0, 5.0, 0.9, 1.0, 0], ["S", 3800, 3000, 0.0, 0.2, 0.0, 14.0, 0.12, 1.0, 0], ["N", 0, 0, 0.0, 0.05, 0.0, 70.0, 0.8, 0.8, 0]],
	"b54_brake": [["N", 0, 0, 0.0, 0.7, 0.01, 3.5, 0.5, 0.92, 0, 0.6], ["S", 2400, 1800, 0.0, 0.5, 0.0, 5.0, 0.06, 1.0, 0.0]],
	"b54_crash": {"rev": 0.3, "drive": 2.4, "layers": [["N", 0, 0, 0.0, 1.2, 0.02, 2.4, 1.1, 0.05, 0], ["C", 0, 0, 0.0, 1.0, 0.0, 2.8, 0.9, 1.0, 0], ["S", 60, 30, 0.0, 0.8, 0.0, 3.5, 0.8, 1.0, 0], ["S", 700, 520, 0.0, 0.5, 0.0, 6.0, 0.15, 1.0, 0.05]]},
	"b54_rumble": {"rev": 0.4, "drive": 2.2, "layers": [["N", 0, 0, 0.0, 4.5, 0.2, 0.8, 1.0, 0.04, 0], ["S", 40, 26, 0.0, 4.5, 0.2, 0.8, 0.8, 1.0, 0.1], ["C", 0, 0, 0.0, 4.0, 0.3, 1.0, 0.5, 0.3, 0], ["S", 620, 380, 0.4, 2.5, 0.2, 1.2, 0.08, 1.0, 0.1]]},
	"b54_wind": {"rev": 0.3, "layers": [["N", 0, 0, 0.0, 3.0, 1.0, 0.6, 0.35, 0.12, 0, 0.2], ["N", 0, 0, 0.3, 2.4, 0.8, 0.8, 0.18, 0.5, 0, 0.6]]},
}

const TOWN_END := 1650.0                 # עמוד הכניסה לגשר
const BRIDGE_END := 9300.0               # הגדה הדרומית (זירת הבוס)
const TRUSS_X0 := 1760.0                 # תחילת המסבך (כפולה של Decor.PANEL)
const TRUSS_X1 := 9280.0
const GATE_X := 8800.0                   # מחסום הצבא בכניסה לזירה
const STORY_X := Vector2(6750.0, 8750.0) # קטע ישר ונקי לסצנת סיפור
const CHARGES := [2560.0, 4000.0, 5440.0, 6560.0]
const GANTRIES := [[1900.0, 2350.0], [3380.0, 3740.0], [4950.0, 5330.0], [5620.0, 5960.0]]
const BALCONY := Vector2(560.0, 920.0)
const TIER := 150.0
const DARK := [[3150.0, 3750.0], [5600.0, 6150.0]]   # קטעים בלי פנסים (DARKSEEKER)
const DECKS := [3110.0, 6330.0]
const TRUCK_X := 4300.0
const CABLES := [3240.0, 6090.0]
const STINGERS := [1250.0, 3420.0, 4750.0, 6200.0]
const LAMP_GAP := 460.0
const DARKNESS := 0.34
const MISSED_DX := 260.0                 # עברת מטען לא דרוך ביותר מזה -> "MISSED A CHARGE"
const HARDER := [1.0, 1.15, 1.3]

var charges := []                        # Decor.ChargePoint
var gate: Node = null                    # Decor.Roadblock
var hud: Node = null                     # Decor.ChargeHud
var fx: Node = null                      # Decor.BridgeFX
var collapse: Node = null                # Decor.BridgeCollapse (אחרי שהבוס מת)
var _trusses := []
var _gantry_nodes := []
var _cp_done := false
var _armed_n := 0
var _nagged := {}                        # מטענים שכבר אמרנו עליהם "MISSED"


func zombie_weights() -> Dictionary:
	return {Registry.SHEPHERD: 0.02, Registry.STINGER: 0.05, Registry.DARKSEEKER: 0.05, 0: 0.55, 1: 0.33}


func zombie_density() -> float:
	return 1.0 * float(HARDER[clampi(Settings.difficulty, 0, 2)])


func generators() -> Array:
	return [["jersey", 1.0], ["ammo", 0.7], ["wreck", 0.5], ["convoy", 0.35]]   # (לא "crates" - השם הזה תפוס ב-main.gd)


func custom_gen(gname: String, x: float) -> float:
	if not gname in ["jersey", "ammo", "wreck", "convoy"]:
		return 0.0
	var sz := Vector2(90.0, 46.0)
	match gname:
		"ammo":
			sz = Vector2(rng.randf_range(66.0, 76.0), rng.randf_range(52.0, 58.0))
		"wreck":
			sz = Vector2(rng.randf_range(120.0, 134.0), rng.randf_range(54.0, 60.0))
		"convoy":
			sz = Vector2(rng.randf_range(180.0, 196.0), rng.randf_range(76.0, 82.0))
	if not free_x(x, 30.0) or not free_x(x + sz.x, 30.0):   # לא על מטען / מלכודת / סולם / קטע הסיפור / הזירה
		return 80.0
	var o := Decor.Obstacle.new()
	o.kind = gname
	o.size = sz
	o.seed_v = rng.randi()
	o.position = Vector2(x, floor_y)
	main.add_child(o)
	reserve(Rect2(x, floor_y - sz.y, sz.x, sz.y))
	return sz.x


func boss_kind() -> int:
	return Registry.SHEPHERD


func music() -> String:
	return "res://music/level1_total_war.mp3"


func world_tint() -> Color:
	return Color(0.82, 0.86, 1.0)


func dark_level() -> bool:
	return true


func fog() -> bool:
	return false


func pits() -> int:
	return 0


func build_background(layer: CanvasLayer) -> Node:
	Decor.U.boom_ms = -1
	Decor.U.roar_ms = -1
	var bg = Backdrop.new()
	bg.level_w = level_w
	bg.sky = func(ci: CanvasItem, v: Vector2, t: float):
		Decor.bridge_sky(ci, v, t)
	bg.add_layer(0.06, func(ci: CanvasItem, sc: float, v: Vector2, t: float):
		Decor.far_steppe(ci, sc, v, 556.0, t))
	bg.add_layer(0.28, func(ci: CanvasItem, sc: float, v: Vector2, t: float):
		Decor.mid_river(ci, sc, v, 612.0, t))
	bg.add_layer(0.6, func(ci: CanvasItem, sc: float, v: Vector2, t: float):
		Decor.near_truss(ci, sc, v, 636.0, t))
	bg.overlay = func(ci: CanvasItem, v: Vector2, _t: float):
		Kit.haze_band(ci, v, 420.0, 612.0, Color(0.36, 0.44, 0.62, 0.22))
	layer.add_child(bg)
	return bg


func build_world() -> void:
	# הקרקע: מרצפת בעיר, משטח הגשר, חצץ בגדה הדרומית
	var x := 0.0
	while x < level_w:
		var w := minf(1024.0, level_w - x)
		var g: Node2D
		if x < TOWN_END:
			w = minf(w, TOWN_END - x)
			g = Decor.BankGround.new()
		elif x < BRIDGE_END:
			w = minf(w, BRIDGE_END - x)
			g = Decor.BridgeDeck.new()
		else:
			g = Decor.SouthGround.new()
		g.w = w
		g.depth = main.floor_thickness
		g.seed_v = rng.randi()
		add_world(g, Vector2(x, floor_y))
		x += w
	# הגדה הצפונית: בתי פטגונס + מרפסת (קומה)
	var town := Decor.TownFront.new()
	town.w = 1500.0
	town.balcony = BALCONY - Vector2(60.0, 60.0)
	town.tier = TIER
	add_world(town, Vector2(60.0, floor_y))
	var bf = add_floor(BALCONY.x - 6.0, floor_y - TIER, BALCONY.y - BALCONY.x + 12.0, "concrete", false, false)
	bf.visible = false
	add_ladder(BALCONY.x + 20.0, floor_y - TIER)
	add_ladder(BALCONY.y - 44.0, floor_y - TIER)
	reserve(Rect2(BALCONY.x - 10.0, floor_y - 40.0, 60.0, 40.0))
	reserve(Rect2(BALCONY.y - 60.0, floor_y - 40.0, 60.0, 40.0))
	_pickup(PickupScript.AMMO, Vector2((BALCONY.x + BALCONY.y) * 0.5, floor_y - TIER - 30.0))
	add_world(Decor.BridgePortal.new(), Vector2(TOWN_END, floor_y))
	reserve(Rect2(TOWN_END - 160.0, floor_y - 40.0, 240.0, 40.0))
	# המסבך (קטעים של עד 6 לוחות)
	x = TRUSS_X0
	while x < TRUSS_X1:
		var tr := Decor.Truss.new()
		tr.w = minf(Decor.PANEL * 6.0, TRUSS_X1 - x)
		add_world(tr, Vector2(x, floor_y))
		_trusses.append(tr)
		x += tr.w
	# מסלולי שירות (קומה) + סולמות + אספקה למעלה
	for i in GANTRIES.size():
		var gx0: float = GANTRIES[i][0]
		var gx1: float = GANTRIES[i][1]
		var gn := Decor.Gantry.new()
		gn.w = gx1 - gx0
		gn.tier = TIER
		add_world(gn, Vector2(gx0, floor_y))
		_gantry_nodes.append(gn)
		var pf = add_floor(gx0, floor_y - TIER, gx1 - gx0, "steel", false, false)
		pf.visible = false
		add_ladder(gx0 + 20.0, floor_y - TIER)
		add_ladder(gx1 - 44.0, floor_y - TIER)
		reserve(Rect2(gx0 - 10.0, floor_y - 40.0, 60.0, 40.0))
		reserve(Rect2(gx1 - 60.0, floor_y - 40.0, 60.0, 40.0))
		_pickup(PickupScript.HEALTH if i % 2 == 0 else PickupScript.AMMO, Vector2(lerpf(gx0, gx1, 0.5), floor_y - TIER - 30.0))
		if i == 1:
			_pickup(PickupScript.GRENADE, Vector2(lerpf(gx0, gx1, 0.75), floor_y - TIER - 30.0))
	# קטעי קורה ש-DARKSEEKER זוחל מתחתם (לא מעל מסלולי השירות)
	var spans := [[TRUSS_X0 + 40.0, TRUSS_X1 - 40.0]]
	for gg in GANTRIES:
		var nxt := []
		for s in spans:
			var a: float = s[0]
			var b: float = s[1]
			var g0: float = float(gg[0]) - 60.0
			var g1: float = float(gg[1]) + 60.0
			if g1 <= a or g0 >= b:
				nxt.append([a, b])
				continue
			if g0 > a + 120.0:
				nxt.append([a, g0])
			if g1 < b - 120.0:
				nxt.append([g1, b])
		spans = nxt
	for s in spans:
		var cs := Decor.ClimbSpan.new()
		cs.x0 = s[0]
		cs.x1 = s[1]
		cs.top_y = floor_y - Decor.TRUSS_H
		main.add_child(cs)
	# פנסי גשר (חלקם מהבהבים כל הזמן), לא בקטעים החשוכים
	var lx := 320.0
	var li := 0
	while lx < level_w - 300.0:
		var skip := absf(lx - GATE_X) < 100.0 or absf(lx - TOWN_END) < 120.0
		for d in DARK:
			if lx > float(d[0]) - 60.0 and lx < float(d[1]) + 60.0:
				skip = true
		for c in CHARGES:
			if absf(lx - float(c)) < 70.0:
				skip = true
		if not skip:
			var lamp = Decor.FlickerLamp.new() if li % 3 == 1 else LampScript.new()
			lamp.light_color = Color(1.0, 0.78, 0.45) if lx < TOWN_END or lx > BRIDGE_END else Color(1.0, 0.74, 0.4)
			lamp.position = Vector2(lx, floor_y)
			main.add_child(lamp)
			li += 1
		lx += LAMP_GAP
	# מטענים
	for i in CHARGES.size():
		var cp := Decor.ChargePoint.new()
		cp.idx = i
		cp.stage = self
		add_world(cp, Vector2(float(CHARGES[i]), floor_y))
		charges.append(cp)
		reserve(Rect2(float(CHARGES[i]) - 110.0, floor_y - 40.0, 220.0, 40.0))
	# מלכודות
	for dx in DECKS:
		add_world(Decor.BrokenDeck.new(), Vector2(float(dx), floor_y))
		reserve(Rect2(float(dx) - 95.0, floor_y - 40.0, 190.0, 40.0))
	var tr2 := Decor.RollingTruck.new()
	add_world(tr2, Vector2(TRUCK_X, floor_y))
	reserve(Rect2(TRUCK_X - 110.0, floor_y - 40.0, tr2.ROLL_DIST + 260.0, 40.0))   # כל המסלול שלה
	for cx in CABLES:
		add_world(Decor.LiveCable.new(), Vector2(float(cx), floor_y))
		reserve(Rect2(float(cx) - 90.0, floor_y - 40.0, 180.0, 40.0))
	# קטע הסיפור: נקי לגמרי
	reserve(Rect2(STORY_X.x - 30.0, floor_y - 60.0, STORY_X.y - STORY_X.x + 60.0, 60.0))
	# מחסום הצבא + הזירה בגדה הדרומית
	gate = Decor.Roadblock.new()
	gate.need = CHARGES.size()
	add_world(gate, Vector2(GATE_X, floor_y))
	reserve(Rect2(GATE_X - 150.0, floor_y - 40.0, 300.0, 40.0))
	add_world(Decor.SouthBank.new(), Vector2(BRIDGE_END, floor_y))
	reserve(Rect2(GATE_X, floor_y - 40.0, level_w - GATE_X, 40.0))
	_pickup(PickupScript.HEALTH, Vector2(GATE_X + 120.0, floor_y - 30.0))
	_pickup(PickupScript.AMMO, Vector2(GATE_X + 190.0, floor_y - 30.0))


const LampScript := preload("res://street_lamp.gd")


func _pickup(kind: int, pos: Vector2) -> void:
	var p = PickupScript.new()
	p.kind = kind
	p.life = 100000.0
	main.add_child(p)
	p.setup(pos, Vector2.ZERO)


func build_effects() -> void:
	var night = S11.NightOverlay.new()
	night.darkness = DARKNESS
	main.add_child(night)
	main.move_child(night, screen_layer.get_index())   # החושך מתחת לשכבת המסך (מונה המטענים, הרוח, ההבזק)
	fx = Decor.BridgeFX.new()
	fx.vp = vp
	screen_layer.add_child(fx)
	hud = Decor.ChargeHud.new()
	hud.vp = vp
	hud.need = CHARGES.size()
	screen_layer.add_child(hud)


# ליד כל מטען: רועה + הרבים שלו. בקטעים החשוכים ועל מסלולי השירות: DARKSEEKER. עוקצים פזורים. שניים שומרים בזירה.
func extra_spawns() -> void:
	for i in CHARGES.size():
		var cx: float = CHARGES[i]
		var last := i == CHARGES.size() - 1
		spawn(Registry.SHEPHERD, cx + (150.0 if last else 300.0))
		for o in ([60.0, 120.0, -130.0, 175.0] if last else [160.0, 220.0, 380.0, 440.0]):
			spawn(0 if rng.randf() < 0.65 else 1, cx + float(o))
	for d in DARK:
		spawn(Registry.DARKSEEKER, float(d[0]) + 200.0)
		spawn(Registry.DARKSEEKER, float(d[0]) + 430.0)
	for i in GANTRIES.size():
		if i != 2:
			spawn(Registry.DARKSEEKER, lerpf(float(GANTRIES[i][0]), float(GANTRIES[i][1]), 0.5), floor_y - TIER)
	for sx in STINGERS:
		spawn(Registry.STINGER, float(sx))
	spawn(0, GATE_X + 300.0)
	spawn(1, GATE_X + 420.0)


func _physics_process(_delta: float) -> void:
	if main == null:
		return
	var pl := get_tree().get_first_node_in_group("player") as Node2D
	if pl == null:
		return
	if not _cp_done:
		_cp_done = true
		if pl.global_position.x > 1500.0:   # התחלה מנקודת ביקורת: המטענים שמאחוריך כבר דרוכים
			for c in charges:
				if c.global_position.x < pl.global_position.x - 150.0:
					c.arm_now(true)
	elif Engine.get_physics_frames() % 12 == 0:   # עברת מטען בלי לדרוך - אומרים לך מיד (ולא רק במחסום, 6000 פיקסלים אחר כך)
		for c in charges:
			if not c.armed and not _nagged.has(c) and pl.global_position.x > c.global_position.x + MISSED_DX:
				_nagged[c] = true
				pl._say("MISSED A CHARGE - GO BACK", Color("ff6a4a"))
				Sfx.play("b54_beep", c.global_position, 2.0)
				if hud != null:
					hud.flash()


# ============ מטענים / מחסום ============
func on_charge_armed(_c: Node, quiet := false) -> void:
	_armed_n = 0
	for c in charges:
		if c.armed:
			_armed_n += 1
	if gate != null:
		gate.armed = _armed_n
	if hud != null:
		hud.armed = _armed_n
		hud.flash()
	var pl := get_tree().get_first_node_in_group("player") as Node2D
	if not quiet and pl != null:
		pl._say("CHARGE ARMED %d/%d" % [_armed_n, CHARGES.size()], Color("ff6a4a"))
	if _armed_n >= CHARGES.size() and gate != null and not gate.is_open:
		gate.set_open(true)
		if hud != null:
			hud.done_t = 0.0


func arm_all_charges() -> void:   # (סצנת סיפור / בדיקות)
	for c in charges:
		c.arm_now(true)


func armed_count() -> int:
	return _armed_n


# ============ THE ARCHITECT מת -> הגשר נופל ============
# נקרא מ-enemies/types/shepherd.gd (on_death של הבוס)
func on_architect_dead(_pos: Vector2) -> void:
	if collapse != null:
		return
	var pl := get_tree().get_first_node_in_group("player") as Node2D
	var px := pl.global_position.x if pl != null else BRIDGE_END + 200.0
	collapse = Decor.BridgeCollapse.new()
	collapse.x1 = clampf(px - 260.0, GATE_X - 300.0, TRUSS_X1)
	collapse.x0 = maxf(STORY_X.x - 400.0, collapse.x1 - 2600.0)
	collapse.floor_y = floor_y
	collapse.stage = self
	main.add_child(collapse)
	for c in charges:
		c.armed = true
		c.beep_fast(3.0)
	var bn := Decor.CollapseBanner.new()
	bn.vp = vp
	bn.delay = collapse.BEEP_T
	screen_layer.add_child(bn)


func collapse_started(_c: Node) -> void:
	if hud != null:
		hud.off = true
	for c in charges:   # המטענים הרחוקים מתפוצצים מחוץ למסך
		c.blown = true


# חלק מהגשר בין a ל-b נפל: המסבך, הפנסים, מסלולי השירות והמחסום נעלמים
func collapse_at(a: float, b: float) -> void:
	for tr in _trusses:
		if tr.global_position.x < b and tr.global_position.x + tr.w > a:
			tr.cut(a, b)
	for lp in get_tree().get_nodes_in_group("lamps"):
		if lp.global_position.x > a and lp.global_position.x < b:
			lp._broken = true
			lp._on = 0.0
			lp.visible = false
	for g in _gantry_nodes:
		if g.global_position.x + g.w * 0.5 > a and g.global_position.x + g.w * 0.5 < b:
			g.visible = false
	for c in charges:
		if c.global_position.x > a and c.global_position.x < b:
			c.visible = false
	if gate != null and gate.global_position.x > a and gate.global_position.x < b:
		gate.visible = false


# ============ קטע סיפור ============
# x של הקטע הנקי: STORY_X (6750..8750). שחקן שעומד במרכזו לא רואה מכשולים / מלכודות.
func story_stretch() -> Vector2:
	return STORY_X


# אירועים שסצנה יכולה להפעיל: "lamps_out" (כל הפנסים כבים לרגע), "herd_roar" (העדר בנהר מרים ידיים + רעם),
# "charges_beep" (המטענים מצפצפים מהר), "wind" (משב חזק), "arm_all" (דורך הכל), "collapse" (הגשר נופל - לבדיקות)
func on_story_beat(id: String) -> void:
	match id:
		"lamps_out":
			for lp in get_tree().get_nodes_in_group("lamps"):
				if not lp._broken:
					lp._flicker = 2.6
			Sfx.play("b54_buzz", null, 2.0)
		"herd_roar":
			Decor.U.roar_ms = Time.get_ticks_msec()
			Sfx.play("b54_rumble", null, 4.0)
			var cam := get_viewport().get_camera_2d()
			if cam != null and cam.has_method("shake"):
				cam.shake(10.0, 1.2)
		"charges_beep":
			for c in charges:
				if c.armed:
					c.beep_fast(2.5)
		"wind":
			if fx != null:
				fx.gust()
		"arm_all":
			arm_all_charges()
		"collapse":
			var pl := get_tree().get_first_node_in_group("player") as Node2D
			on_architect_dead(pl.global_position if pl != null else Vector2.ZERO)
