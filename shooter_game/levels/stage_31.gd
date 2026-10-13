extends "res://levels/stage_base.gd"
# ============================================================
#  STAGE 31 - "FLOATING ISLANDS" (אזור רביעי - האנדים, שלב 4) - "THEY LEARNED TO SWIM"
#  אגם טיטיקקה בזריחה (effects/s31_decor.gd): איי הקנים של האורוס, בקתות קנים, מגדלי תצפית, תנורי חימר מעשנים,
#  סירות קנים עם ראש פומה, הקורדיירה ריאל המושלגת מעבר לאגם.
#  כל השלב הוא אגם רדוד: במים איטיים (in_water), על האיים (Island - מוצקים, ISL_H) בטוחים יותר.
#  מלכודת: RottenPatch - קנים רקובים על חלק מהאיים: עומדים עליהם רגע -> נשברים, נופלים למים.
#  זומבים: DROWNED (שוחה מתחת למים, בלתי פגיע שם, פורץ ונושך / מטפס על האי), BALSERO (סירת קנים עם תגבורת),
#          NETTER (רשת דייגים: תופס ומושך), רגילים, רצים.
#  בוס: MAMA QUCHA - DROWNED ענקית (enemies/types/drowned.gd, מצב בוס): גלים לאורך האגם. על האי = בטוח.
#  שני איי מקלט בזירת הבוס (BOSS_ISLES).
#  לשנות: ISLE_W, ISLE_GAP, BOATS_EVERY, BOSS_ISLES, zombie_weights().
# ============================================================

const Decor := preload("res://effects/s31_decor.gd")
const PickupScript := preload("res://pickup.gd")

const SOUNDS := {
	"s31_creak": [["C", 0, 0, 0.0, 0.25, 0.0, 10.0, 0.6, 1.0, 0], ["N", 0, 0, 0.0, 0.35, 0.0, 9.0, 0.5, 0.5, 0, 0.2], ["S", 260, 140, 0.0, 0.2, 0.0, 14.0, 0.2, 1.0, 0.1]],
}

const ISLE_W := Vector2(340.0, 560.0)
const ISLE_GAP := Vector2(230.0, 420.0)
const BOATS_EVERY := 3
const BOSS_ISLES := [[1150.0, 300.0], [700.0, 160.0]]   # [מרחק מסוף השלב, רוחב]
const HARDER := [1.0, 1.15, 1.3]

var _isles := []           # Island nodes
var _gaps := []            # [x0, x1] מים בין איים


func zombie_weights() -> Dictionary:
	return {Registry.DROWNED: 0.12, Registry.NETTER: 0.06, 0: 0.48, 1: 0.34}


func zombie_density() -> float:
	return 1.0 * float(HARDER[clampi(Settings.difficulty, 0, 2)])


func generators() -> Array:
	return [["moored_boat", 1.2], ["reed_bundles", 1.0], ["fish_crates", 0.7]]


func custom_gen(gname: String, x: float) -> float:
	if not gname in ["moored_boat", "reed_bundles", "fish_crates"]:
		return 0.0
	var o := Decor.Obstacle.new()
	o.kind = gname
	o.seed_v = rng.randi()
	match gname:
		"moored_boat":
			o.size = Vector2(rng.randf_range(96.0, 116.0), rng.randf_range(34.0, 40.0))
		"reed_bundles":
			o.size = Vector2(rng.randf_range(60.0, 76.0), rng.randf_range(36.0, 44.0))
		_:
			o.size = Vector2(rng.randf_range(54.0, 62.0), rng.randf_range(26.0, 30.0))
	o.position = Vector2(x, floor_y)
	main.add_child(o)
	reserve(Rect2(x, floor_y - o.size.y, o.size.x, o.size.y))
	return o.size.x


func boss_kind() -> int:
	return Registry.DROWNED


func music() -> String:
	return "res://music/level2_suspense.mp3"


func world_tint() -> Color:
	return Color(1.0, 0.97, 0.94)


func fog() -> bool:
	return false


func pits() -> int:
	return 0


func build_background(layer: CanvasLayer) -> Node:
	var bg = Backdrop.new()
	bg.level_w = level_w
	bg.sky = func(ci: CanvasItem, v: Vector2, t: float):
		Decor.titicaca_sky(ci, v, t)
	bg.add_layer(0.05, func(ci: CanvasItem, sc: float, v: Vector2, t: float):
		Decor.far_cordillera(ci, sc, v, 470.0, t))
	bg.add_layer(0.25, func(ci: CanvasItem, sc: float, v: Vector2, t: float):
		Decor.mid_islands(ci, sc, v, 560.0, t))
	bg.add_layer(0.55, func(ci: CanvasItem, sc: float, v: Vector2, t: float):
		Decor.near_reeds(ci, sc, v, 640.0, t))
	layer.add_child(bg)
	return bg


func build_world() -> void:
	main.set_meta("lake_floor", floor_y)
	main.add_child(LakeLogic.new())
	var x := 0.0
	while x < level_w:   # קרקעית + פני המים
		var g := Decor.LakeGround.new()
		g.w = minf(1024.0, level_w - x)
		g.depth = main.floor_thickness
		g.seed_v = rng.randi()
		add_world(g, Vector2(x, floor_y))
		var wf := Decor.WaterFront.new()
		wf.w = g.w
		add_world(wf, Vector2(x, floor_y))
		x += 1024.0
	# איים: האי הראשון = נקודת ההתחלה
	var ix := 0.0
	var i := 0
	var last_end := level_w - float(BOSS_ISLES[0][0]) - 260.0
	while ix < last_end:
		var w := 700.0 if i == 0 else rng.randf_range(ISLE_W.x, ISLE_W.y)
		w = minf(w, last_end - ix)
		if w < 200.0:
			break
		_isle(ix, w, i)
		var gap := rng.randf_range(ISLE_GAP.x, ISLE_GAP.y)
		_gaps.append([ix + w, ix + w + gap])
		ix += w + gap
		i += 1
	for b in BOSS_ISLES:   # איי מקלט בזירת הבוס
		_isle(level_w - float(b[0]), float(b[1]), 99)


func _isle(x: float, w: float, i: int) -> void:
	var isl := Decor.Island.new()
	isl.w = w
	isl.seed_v = rng.randi()
	isl.huts = 0 if i == 99 else (2 if w > 450.0 else 1)
	isl.stove = i % 3 == 0 and i != 99
	isl.rack = i % 3 == 1
	isl.tower = i % 4 == 2
	if i % 2 == 1 and i != 99:   # קנים רקובים באמצע
		var gx := w * rng.randf_range(0.35, 0.6)
		isl.gaps = [[gx, gx + 60.0]]
	add_world(isl, Vector2(x, floor_y))
	for g in isl.gaps:
		var rp := Decor.RottenPatch.new()
		rp.w = float(g[1]) - float(g[0])
		add_world(rp, Vector2(x + float(g[0]), floor_y))
	reserve(Rect2(x - 30.0, floor_y - Decor.ISL_H, w + 60.0, Decor.ISL_H))
	_isles.append(isl)
	if i > 0 and i != 99 and i % 2 == 0:
		_pickup(PickupScript.AMMO if i % 4 == 0 else PickupScript.HEALTH, Vector2(x + w * 0.7, floor_y - Decor.ISL_H - 30.0))


func _pickup(kind: int, pos: Vector2) -> void:
	var p = PickupScript.new()
	p.kind = kind
	p.life = 100000.0
	main.add_child(p)
	p.setup(pos, Vector2.ZERO)


func _isle_at(x: float) -> Node:
	for isl in _isles:
		if x > isl.position.x - 6.0 and x < isl.position.x + isl.w + 6.0:
			return isl
	return null


func build_effects() -> void:
	var fx := Decor.LakeFX.new()
	fx.vp = vp
	screen_layer.add_child(fx)


# זומבים שנולדו בתוך אי -> על האי. DROWNED בכל ערוץ מים, סירות, דייגים על איים
func extra_spawns() -> void:
	for zz in main.get_tree().get_nodes_in_group("zombies"):
		if zz.is_boss():
			continue
		var isl := _isle_at(zz.position.x)
		if isl != null:
			if zz.kind == Registry.DROWNED:   # טובע לא נולד על אי
				zz.position.x = isl.position.x - 40.0
			else:
				zz.position.y = floor_y - Decor.ISL_H - 1.0
	for k in _gaps.size():
		var g: Array = _gaps[k]
		if k == 0:
			continue
		spawn(Registry.DROWNED, lerpf(float(g[0]), float(g[1]), 0.5))
		if k % BOATS_EVERY == 1:
			spawn(Registry.BALSERO, lerpf(float(g[0]), float(g[1]), 0.3))
	for k in range(2, _isles.size(), 3):
		var isl: Node = _isles[k]
		if isl.huts > 0:
			var zz: Node = spawn(Registry.NETTER, isl.position.x + isl.w * 0.75, floor_y - Decor.ISL_H - 1.0)
			if zz != null:
				zz.velocity = Vector2.ZERO


# ---- השחקן במים? (פני האגם: איטי). גם צליל התזה כשקופצים למים ----
class LakeLogic extends Node:
	var _was := false

	func _physics_process(_delta: float) -> void:
		var pl := get_tree().get_first_node_in_group("player")
		if pl == null:
			return
		var fy: float = get_parent().get_meta("lake_floor", 0.0)
		var wet: bool = pl.global_position.y > fy - 8.0
		pl.in_water = wet
		if wet and not _was and pl.is_on_floor():
			preload("res://effects/s31_decor.gd").splash(get_parent(), Vector2(pl.global_position.x, fy - 18.0), 5)
		_was = wet
