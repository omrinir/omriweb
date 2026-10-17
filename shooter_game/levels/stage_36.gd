extends "res://levels/stage_base.gd"
# ============================================================
#  STAGE 36 - "THE SUMMIT" (אזור רביעי - האנדים, שלב 9 ואחרון) - "THEY LEARNED TO WORSHIP"
#  מקדש אינקה בפסגה (effects/s36_decor.gd), סופת ברקים בשקיעה מעל ים עננים. טרסות אבן, אפצ'טות, מזבחות מנחות.
#  קומה שנייה: הטרסות (TERRACES) - חלקן עם אבנים רופפות (Crumble) באמצע.
#  מלכודות: Storm - ברקים ליד השחקן (עיגול זוהר = אזהרה). עומד גבוה על טרסה? הברק בוחר בך בדיוק.
#           Crumble - אבני טרסה רופפות שנופלות כשעומדים עליהן.
#  זומבים: MALLKI (מומיה עטופה שמתעטפת מחדש), GUARDIAN (מגן שלומד איפה אתה יורה), QUIPU (זוכר את הנשק שלך),
#          REVIVER, רגילים, רצים.
#  בוס נייח: APU (enemies/types/apu.gd) - רוח ההר: מקלע, סלעים, ברקים שלומדים לאן אתה בורח.
#  לשנות: TERRACES, TIER, CRUMBLE_ON, PHALANX, zombie_weights().
# ============================================================

const Decor := preload("res://effects/s36_decor.gd")
const PickupScript := preload("res://pickup.gd")

const SOUNDS := {
	"su_hum": [["S", 110, 120, 0.0, 1.0, 0.3, 1.0, 0.25, 1.0, 0.04], ["N", 0, 0, 0.0, 1.0, 0.3, 1.0, 0.15, 0.8, 0, 0.5]],
	"su_thunder": {"drive": 1.8, "layers": [["N", 0, 0, 0.0, 1.6, 0.0, 2.5, 1.0, 0.12, 0], ["N", 0, 0, 0.0, 0.12, 0.0, 30.0, 0.8, 0.9, 0, 0.3], ["S", 60, 35, 0.0, 1.2, 0.0, 3.0, 0.6, 1.0, 0]]},
	"su_rumble": [["N", 0, 0, 0.0, 0.7, 0.05, 2.0, 0.4, 0.1, 0], ["C", 0, 0, 0.2, 0.05, 0.0, 50.0, 0.3, 1.0, 0]],
	"su_fall": [["N", 0, 0, 0.0, 0.6, 0.0, 5.0, 0.8, 0.15, 0], ["S", 90, 50, 0.0, 0.5, 0.0, 6.0, 0.4, 1.0, 0]],
}

const TERRACES := [[0.12, 300.0], [0.36, 340.0], [0.6, 300.0], [0.82, 300.0]]
const TIER := 120.0
const CRUMBLE_ON := [1, 3]          # באילו טרסות יש אבנים רופפות באמצע
const PHALANX := [0.22, 0.47, 0.71]
const HARDER := [1.0, 1.15, 1.3]

var _terraces := []


func zombie_weights() -> Dictionary:
	return {Registry.MALLKI: 0.05, Registry.GUARDIAN: 0.06, Registry.QUIPU: 0.02, Registry.REVIVER: 0.03, 0: 0.5, 1: 0.34}


func zombie_density() -> float:
	return 1.0 * float(HARDER[clampi(Settings.difficulty, 0, 2)])


func generators() -> Array:
	return [["apacheta", 1.0], ["offering", 0.6], ["wall_stub", 1.0]]


func custom_gen(gname: String, x: float) -> float:
	if not gname in ["apacheta", "offering", "wall_stub"]:
		return 0.0
	var o := Decor.Obstacle.new()
	o.kind = gname
	o.seed_v = rng.randi()
	match gname:
		"apacheta":
			o.size = Vector2(rng.randf_range(50.0, 62.0), rng.randf_range(40.0, 50.0))
		"offering":
			o.size = Vector2(rng.randf_range(70.0, 84.0), rng.randf_range(34.0, 40.0))
		_:
			o.size = Vector2(rng.randf_range(80.0, 100.0), rng.randf_range(40.0, 52.0))
	o.position = Vector2(x, floor_y)
	main.add_child(o)
	reserve(Rect2(x, floor_y - o.size.y, o.size.x, o.size.y))
	return o.size.x


func boss_kind() -> int:
	return Registry.APU


func music() -> String:
	return "res://music/level1_total_war.mp3"


func world_tint() -> Color:
	return Color(0.9, 0.88, 1.0)


func fog() -> bool:
	return false


func pits() -> int:
	return 0


func build_background(layer: CanvasLayer) -> Node:
	var bg = Backdrop.new()
	bg.level_w = level_w
	bg.sky = func(ci: CanvasItem, v: Vector2, t: float):
		Decor.summit_sky(ci, v, t)
	bg.add_layer(0.05, func(ci: CanvasItem, sc: float, v: Vector2, t: float):
		Decor.cloud_sea(ci, sc, v, 540.0, t))
	bg.add_layer(0.25, func(ci: CanvasItem, sc: float, v: Vector2, t: float):
		Decor.mid_ruins(ci, sc, v, 620.0, t))
	bg.add_layer(0.6, func(ci: CanvasItem, sc: float, v: Vector2, t: float):
		Decor.near_rocks(ci, sc, v, 642.0, t))
	bg.overlay = func(ci: CanvasItem, v: Vector2, _t: float):   # ערפל סגלגל מאחורי הדמויות - צלליות כהות נקראות על המדרון הכהה
		Kit.haze_band(ci, v, 420.0, 612.0, Color(0.62, 0.55, 0.72, 0.24))
	layer.add_child(bg)
	return bg


func build_world() -> void:
	var x := 0.0
	while x < level_w:
		var g := Decor.SummitGround.new()
		g.w = minf(1024.0, level_w - x)
		g.depth = main.floor_thickness
		g.seed_v = rng.randi()
		add_world(g, Vector2(x, floor_y))
		x += 1024.0
	for i in TERRACES.size():   # טרסות אינקה: קומה + מדרגות (+ אבנים רופפות)
		var t: Array = TERRACES[i]
		var w: float = t[1]
		var dx := level_w * float(t[0])
		var tr := Decor.Terrace.new()
		tr.w = w
		tr.tier = TIER
		tr.seed_v = rng.randi()
		add_world(tr, Vector2(dx, floor_y))
		var fy := floor_y - TIER
		if i in CRUMBLE_ON:
			var cx := dx + w * 0.5 - 40.0
			var a = add_floor(dx - 6.0, fy, cx - dx + 6.0, "concrete", false, false)
			a.visible = false
			var c = add_floor(cx, fy, 80.0, "concrete", false, false)
			c.visible = false
			var b = add_floor(cx + 80.0, fy, dx + w + 6.0 - cx - 80.0, "concrete", false, false)
			b.visible = false
			var cr := Decor.Crumble.new()
			cr.w = 80.0
			cr.floor_node = c
			add_world(cr, Vector2(cx, fy))
		else:
			var pf = add_floor(dx - 6.0, fy, w + 12.0, "concrete", false, false)
			pf.visible = false
		add_ladder(dx + 8.0, fy)
		reserve(Rect2(dx - 10.0, fy, w + 20.0, TIER))
		_terraces.append([dx, dx + w])
		_pickup(PickupScript.AMMO if i % 2 == 0 else PickupScript.HEALTH, Vector2(dx + w * 0.75, fy - 30.0))
	var st := Decor.Storm.new()
	st.floor_y = floor_y
	st.quiet_from = level_w - 1500.0
	main.add_child(st)


func _pickup(kind: int, pos: Vector2) -> void:
	var p = PickupScript.new()
	p.kind = kind
	p.life = 100000.0
	main.add_child(p)
	p.setup(pos, Vector2.ZERO)


func build_effects() -> void:
	var fx := Decor.StormFX.new()
	fx.vp = vp
	screen_layer.add_child(fx)


# פלנקס: שני GUARDIAN מלפנים, QUIPU מאחור. מומיות על הטרסות
func extra_spawns() -> void:
	for f in PHALANX:
		var px := level_w * float(f)
		spawn(Registry.GUARDIAN, px - 30.0)
		spawn(Registry.GUARDIAN, px + 30.0)
		spawn(0, px + 90.0)
		spawn(Registry.QUIPU, px + 300.0)
	for i in _terraces.size():
		var s: Array = _terraces[i]
		spawn(Registry.MALLKI, lerpf(float(s[0]), float(s[1]), 0.3), floor_y - TIER)
		if i % 2 == 1:
			spawn(Registry.MALLKI, lerpf(float(s[0]), float(s[1]), 0.85), floor_y - TIER)
