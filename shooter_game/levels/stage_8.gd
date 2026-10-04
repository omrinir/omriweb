extends "res://levels/stage_base.gd"
# ============================================================
#  STAGE 8 - "THEY ADAPT"
#  מעבדת מחקר תת-קרקעית נטושה. אור קר + אורות חירום אדומים, חדרי זכוכית,
#  תאי כליאה, מסופים, כימיקלים דולפים.
#  מסלולים: בכל קטע יש מסדרון עליון (רצפת מעבדה) - בטוח יותר ואיטי (סולמות),
#           ומסדרון תחתון עם דליפות, לוחות מחושמלים וצינורות כליאה - מסוכן, אבל עם
#           תחמושת ונשקים. "איזו דרך בטוחה יותר?"
#  זומבים: ADAPTOR, DODGER, TANK (הבוס), SIREN, HUNTER (+ SPITTER)
#  נשקים: ASSAULT SHOTGUN, GRENADE LAUNCHER
#  אפקטים: ניצוצות חשמל, אדים כימיים (ירוק), מסכים מהבהבים, אור חירום פועם, מיכלי נוזל
#  קישוטים: effects/s8_decor.gd. סכנות: environment/s8_*.gd + acid_pool
#  איך משנים: אורך קטע = SECTION, תוכן קטע = _section(), נבדקים שבורחים = specimens_left
# ============================================================

const WeaponDB := preload("res://weapons/weapon_db.gd")
const Decor := preload("res://effects/s8_decor.gd")
const BurstTube := preload("res://environment/s8_burst_tube.gd")
const ElectroFloor := preload("res://environment/s8_electro_floor.gd")
const AcidPool := preload("res://environment/acid_pool.gd")
const PickupScript := preload("res://pickup.gd")

const SOUNDS := {
	"s8_zap": [["Q", 70, 60, 0.0, 0.35, 0.0, 6.0, 0.35, 0.6, 0], ["C", 0, 0, 0.0, 0.35, 0.0, 5.0, 0.9, 1.0, 0], ["S", 3800, 3300, 0.0, 0.2, 0.0, 12.0, 0.1, 1.0, 0]],
	"s8_hum": [["Q", 120, 120, 0.0, 0.5, 0.05, 0.0, 0.18, 0.25, 0.02]],
}

const SECTION := 1500.0
var specimens_left := 3      # כמה "נבדקים" יכולים לברוח מצינורות שהתפוצצו


func zombie_weights() -> Dictionary:
	return {0: 0.18, 3: 0.08, Registry.ADAPTOR: 0.22, Registry.DODGER: 0.2, Registry.HUNTER: 0.1, Registry.SIREN: 0.06}


func generators() -> Array:
	return [["labprop", 3.0], ["crates", 1.0], ["container", 1.0], ["barrels", 1.0]]


# רהיט מעבדה מוצק (שולחן / מכולת דגימות / ארון שרתים) - גם מחסה לזומבים
func custom_gen(gname: String, x: float) -> float:
	if gname != "labprop":
		return 0.0
	var kinds := ["bench", "crate", "server"]
	var k: String = kinds[rng.randi() % kinds.size()]
	var sz := {"bench": Vector2(96, 34), "crate": Vector2(56, 48), "server": Vector2(44, 62)}[k] as Vector2
	var before: int = main.get_child_count()
	add_block(x, floor_y - sz.y, sz.x, sz.y, Color("3a444e"), true, 2)
	var brick: Node = main.get_child(before) if main.get_child_count() > before else null
	var po = Decor.PropOverlay.new()
	po.kind = k
	po.size = sz
	po.brick = brick
	po.seed_v = rng.randi()
	po.position = Vector2(x, floor_y - sz.y)
	main.add_child(po)
	var cm := CoverMark.new()
	cm.rect = Rect2(x, floor_y - sz.y, sz.x, sz.y)
	cm.brick = brick
	main.add_child(cm)
	return sz.x


func weapon_offers() -> Array:
	return [WeaponDB.ASSAULT_SHOTGUN, WeaponDB.GRENADE_LAUNCHER]


func boss_kind() -> int:
	return Registry.TANK


func music() -> String:
	return "res://music/level2_suspense.mp3"


func world_tint() -> Color:
	return Color(0.78, 0.88, 0.95)


func pits() -> int:
	return 0


func fog() -> bool:
	return false


# ---- רקע: מכונות מעבדה ענקיות (3 שכבות) ----
func build_background(layer: CanvasLayer) -> Node:
	var bg = Backdrop.new()
	bg.level_w = level_w
	bg.sky = func(ci: CanvasItem, v: Vector2, t: float):
		Kit.gradient_sky(ci, v, [Color("0a0e14"), Color("121a24"), Color("18222e"), Color("0e141a")], 0.9)
		for i in 6:   # תקרה: צינורות וקורות
			ci.draw_rect(Rect2(0, 20 + i * 14, v.x, 4), Color(0.12, 0.15, 0.2, 0.8))
		var a := 0.08 + 0.06 * absf(sin(t * 2.4))
		ci.draw_rect(Rect2(Vector2.ZERO, v), Color(0.8, 0.05, 0.05, a * 0.4))   # חירום אדום עמום
	# 0.10: אולם מכונות רחוק - טורבינות/סלילים ענקיים מסתובבים
	bg.add_layer(0.10, func(ci: CanvasItem, sc: float, v: Vector2, t: float):
		var period := 700.0
		var start := int(floor(sc / period)) - 1
		for k in range(start, start + int(v.x / period) + 3):
			var x := float(k) * period - sc
			ci.draw_rect(Rect2(x + 60, 140, 200, 360), Color("141b24"))
			ci.draw_circle(Vector2(x + 160, 260), 70, Color("1a2430"))
			for s in 6:   # כנפי טורבינה
				var an := t * 0.6 + float(s) * TAU / 6.0
				ci.draw_line(Vector2(x + 160, 260), Vector2(x + 160, 260) + Vector2.from_angle(an) * 62.0, Color("26323f"), 6.0)
			ci.draw_circle(Vector2(x + 160, 260), 14, Color(0.3, 0.85, 1.0, 0.35 + 0.2 * sin(t * 3.0 + float(k))))
			ci.draw_rect(Rect2(x + 400, 220, 120, 300), Color("121820"))
			for j in 5:   # נורות לוח בקרה
				var on := int(t * 2.0 + float(j + k)) % 3 != 0
				ci.draw_circle(Vector2(x + 425 + j * 18, 250), 3, Color(1.0, 0.25, 0.2, 0.8) if on else Color(0.2, 0.8, 0.4, 0.5)))
	# 0.30: מיכלי נוזל עם בועות, תאי כליאה, אדים
	bg.add_layer(0.30, func(ci: CanvasItem, sc: float, v: Vector2, t: float):
		var period := 520.0
		var start := int(floor(sc / period)) - 1
		for k in range(start, start + int(v.x / period) + 3):
			var x := float(k) * period - sc
			var r := RandomNumberGenerator.new()
			r.seed = k * 131 + 7
			var tint := Color(0.3, 0.95, 0.55) if r.randf() < 0.6 else Color(0.35, 0.7, 1.0)
			ci.draw_rect(Rect2(x + 40, 260, 90, 260), Color("1c2630"))
			ci.draw_rect(Rect2(x + 48, 280, 74, 220), Color(tint, 0.25))
			for b in 6:
				var by := 500.0 - fmod(t * 40.0 + float(b) * 37.0 + float(k) * 13.0, 220.0)
				ci.draw_circle(Vector2(x + 60 + (b * 11) % 50, by), 2.5, Color(tint, 0.6))
			ci.draw_rect(Rect2(x + 30, 250, 110, 12), Color("2a3642"))
			Kit.smoke_column(ci, Vector2(x + 300, 520), t + float(k), 160.0, Color(0.5, 0.9, 0.6, 0.12), 30.0))
	# 0.60: צינורות וכבלים קרובים, שלטי אזהרה
	bg.add_layer(0.60, func(ci: CanvasItem, sc: float, v: Vector2, t: float):
		var period := 900.0
		var start := int(floor(sc / period)) - 1
		for k in range(start, start + 3):
			var x := float(k) * period - sc
			ci.draw_rect(Rect2(x + 100, 180, 22, 420), Color("10161c"))
			ci.draw_rect(Rect2(x + 600, 180, 22, 420), Color("10161c"))
			var pts := PackedVector2Array()
			for q in 9:
				var u := float(q) / 8.0
				pts.append(Vector2(x + 110 + u * 500.0, 200 + sin(u * PI) * 40.0 + sin(t + u * 4.0) * 2.0))
			ci.draw_polyline(pts, Color(0.06, 0.08, 0.1, 0.95), 3.0)
			if int(t * 3.0 + float(k)) % 4 == 0:   # ניצוץ בכבל
				ci.draw_circle(pts[4], 6, Color(0.6, 0.85, 1.0, 0.6))
		Kit.ground_fade(ci, v, 560.0))
	layer.add_child(bg)
	return bg


func build_world() -> void:
	var x := 0.0
	while x < level_w:   # קיר מעבדה + אריחי רצפה
		var w = Decor.LabWall.new()
		w.seed_v = rng.randi()
		w.floor_y = floor_y
		w.position = Vector2(x, floor_y)
		main.add_child(w)
		var ft = Decor.FloorTiles.new()
		ft.seed_v = rng.randi()
		ft.position = Vector2(x, floor_y)
		main.add_child(ft)
		x += 1024.0
	var sx := 800.0
	var i := 0
	while sx < level_w - 1000.0:
		_section(sx, i)
		sx += SECTION
		i += 1


# קטע: מסדרון עליון בטוח (רצפת מעבדה) מעל מסדרון תחתון מסוכן עם פרס
func _section(sx: float, i: int) -> void:
	var cy := floor_y - FLOOR2
	var w := rng.randf_range(700.0, 950.0)
	add_floor(sx, cy, w, "lab", true, true)
	add_ladder(sx + 20.0, cy)
	add_ladder(sx + w - 20.0, cy)
	# למטה: דליפת כימיקלים + לוחות מחושמלים + צינור כליאה
	var lp = Decor.LeakPipe.new()
	lp.fall = FLOOR2 - 20.0
	lp.position = Vector2(sx + w * 0.3, cy + 20.0)
	main.add_child(lp)
	var pool = AcidPool.new()
	pool.setup(70.0, -1.0)
	add_hazard(pool, Vector2(sx + w * 0.3, floor_y))
	var ef = ElectroFloor.new()
	ef.width = 120.0
	ef.phase = float(i) * 1.3
	add_hazard(ef, Vector2(sx + w * 0.55, floor_y))
	var bt = BurstTube.new()
	bt.stage = self
	bt.release_kind = Registry.ADAPTOR if i % 2 == 0 else -1
	add_hazard(bt, Vector2(sx + w * 0.78, floor_y))
	reserve(Rect2(sx + w * 0.25, floor_y - FLOOR2, w * 0.6, FLOOR2))
	# הפרס במסלול המסוכן: תחמושת / רימונים
	var p = PickupScript.new()
	p.kind = PickupScript.AMMO if i % 2 == 0 else PickupScript.GRENADE
	p.life = 100000.0
	main.add_child(p)
	p.setup(Vector2(sx + w * 0.66, floor_y - 30.0), Vector2.ZERO)
	# מיכל נוזל גדול על הקיר העליון
	var lt = Decor.LiquidTank.new()
	lt.seed_v = rng.randi()
	lt.height = 120.0
	lt.radius = 30.0
	lt.position = Vector2(sx + w * 0.5, cy)
	main.add_child(lt)


func build_effects() -> void:
	screen_layer.add_child(Ambient.screen_particles("spores", vp))
	var ap = Decor.AlarmPulse.new()
	ap.vp = vp
	screen_layer.add_child(ap)
	var x := 500.0
	while x < level_w:
		var fl = Ambient.FlickerLight.new()
		fl.color = Color(0.75, 0.9, 1.0)
		add_world(fl, Vector2(x, floor_y - 300.0))
		var red = Ambient.FlickerLight.new()
		red.mode = "pulse"
		red.color = Color(1.0, 0.15, 0.1)
		red.radius = 60.0
		add_world(red, Vector2(x + 350.0, floor_y - FLOOR2 + 16.0))
		var se = Ambient.SparkEmitter.new()
		se.color = Color(0.6, 0.85, 1.0)
		add_world(se, Vector2(x + 200.0, floor_y - 240.0))
		x += rng.randf_range(600.0, 900.0)


func extra_spawns() -> void:
	var sx := 800.0
	var i := 0
	while sx < level_w - 1000.0:
		var cy := floor_y - FLOOR2
		spawn(Registry.DODGER if i % 2 == 0 else Registry.ADAPTOR, sx + 300.0, cy)
		if i % 2 == 1:
			spawn(Registry.HUNTER, sx + 600.0, floor_y)
		if i == 2:
			spawn(Registry.SIREN, sx + 450.0, cy)
		sx += SECTION
		i += 1


# סימון מחסה לרהיט מעבדה (zombie.gd -> _try_cover מחפש קבוצת "cover")
class CoverMark extends Node2D:
	var rect := Rect2()
	var brick: Node = null

	func _ready() -> void:
		add_to_group("cover")

	func cover_rect() -> Rect2:
		if brick == null or not is_instance_valid(brick):
			return Rect2()
		return rect
