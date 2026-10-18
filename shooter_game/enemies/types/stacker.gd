extends "res://enemies/zombie_type.gd"
# ============================================================
#  STACKER (שלב 53, "CAPITAL SIEGE") - מטפס של העדר: חשוף חזה, אפור-כחלחל, רתמת חבלים מוצלבת על החזה,
#    חבל עם קשרים שנגרר מאחור, אצבעות כפופות כמו ווים. (World War Z - פירמידות הזומבים על החומה / I Am a Hero)
#  כשאתה למעלה (מרפסת, גג של אוטובוס, שער) הם רצים אל מתחת לך וננעלים למגדל חי של 2-4 גופות (Tower):
#    הבסיס עומד פשוק ומחזיק, האמצעי כורע על הכתפיים, העליון מושיט ידיים. כשהמגדל גמור - העליון קופץ אליך,
#    וכל זומבי שמגיע לבסיס מטפס על המגדל ועולה לקומה שלך (סולם חי).
#  הנגד: לירות בבסיס (TOPPLE_HITS פגיעות) -> כל המגדל קורס כמו דומינו: הגופות עפות, נופלות (נזק נפילה לפי הגובה)
#    ומפילות זומבים שהן נוחתות עליהם. פיצוץ על כל אחד מהם / שמן בוער (OilDrum) = המגדל קורס מיד.
#  "THEY LEARN": אחרי LEARN_ARMOR מגדלים שהפלת - הבסיס מחזיק דלת של מכונית (חוסם קליעים מלפנים בגוף ובראש:
#    לירות ברגליים / פיצוץ / אש). אחרי LEARN_TWIN - בונים שני מגדלים ביחד.
#  בוס (chase_range > 600): "THE SIEGE TOWER" - גוש ענק של עשרות גופות מאוחות שהולך על רגליים של כולם עם איל ניגוח:
#    RAM - נשען אחורה (RAM_WIND) ומסתער: מנפץ מחסומים (ArenaBarricade, ואז המום STUN_BARRICADE), נתקע בקיר (STUN_WALL),
#    זורק אותך. SWAT - מכה מקרוב. כל 1/8 חיים (ובכל פיצוץ) גופה נושרת ממנו וקמה לתקוף (עד SHED_CAP).
#    נקודת התורפה: הפנים שבלב הגוש (CORE) - נחשפות יותר ויותר כשהגופות נושרות. כשהוא המום - נזק כפול.
#  צלילים: "st_lock" (ננעל במגדל), "st_topple" (המגדל קורס), "st_thud" (נחיתה), "st_ram" (הסתערות), "st_wind" (נשען אחורה).
#  לשנות: SEG, STACK_R, TOPPLE_HITS, IDLE_DISBAND, LIFE_MAX, FALL_DMG, DOMINO_DMG, LEARN_ARMOR, LEARN_TWIN,
#         RAM_R, RAM_WIND, RAM_V, RAM_MAX, STUN_BARRICADE, STUN_WALL, SWAT_R, SHED_CAP, CORE_MULT, BODY_MULT.
#  בדיקות: main.get_meta("st_built" / "st_topples" / "st_climbs" / "st_blocks" / "st_armored" / "st_twins") ו-boss: rams, smashes, sheds, core_hits.
# ============================================================

const PickupScript := preload("res://pickup.gd")
const SOUNDS := {
	"st_lock": [["N", 0, 0, 0.0, 0.12, 0.0, 30.0, 0.6, 0.15, 0], ["S", 120, 70, 0.0, 0.12, 0.0, 26.0, 0.6, 1.0, 0], ["V", 140, 110, 0.02, 0.25, 0.02, 8.0, 0.35, 1.0, 0.03, 0, [600, 950, 30]]],
	"st_topple": {"rev": 0.3, "drive": 2.4, "layers": [["S", 160, 120, 0.0, 0.5, 0.05, 4.0, 0.4, 1.0, 0.3], ["N", 0, 0, 0.35, 0.5, 0.0, 6.0, 0.9, 0.25, 0], ["S", 75, 35, 0.35, 0.45, 0.0, 7.0, 0.9, 1.0, 0], ["V", 260, 150, 0.0, 0.7, 0.03, 2.5, 0.6, 1.0, 0.06, 0, [800, 1250, 45]]]},
	"st_thud": [["N", 0, 0, 0.0, 0.16, 0.0, 22.0, 0.8, 0.12, 0], ["S", 90, 40, 0.0, 0.16, 0.0, 20.0, 0.8, 1.0, 0]],
	"st_ram": {"rev": 0.25, "drive": 2.8, "layers": [["N", 0, 0, 0.0, 0.5, 0.05, 5.0, 0.7, 0.3, 0], ["S", 60, 40, 0.0, 0.6, 0.05, 3.0, 0.9, 1.0, 0.05], ["W", 80, 55, 0.0, 0.8, 0.05, 2.2, 0.5, 0.15, 0.08]]},
	"st_wind": [["W", 55, 85, 0.0, 0.9, 0.2, 1.5, 0.6, 0.1, 0.1], ["N", 0, 0, 0.0, 0.9, 0.3, 2.0, 0.3, 0.12, 0]],
}

const SEG := 44.0              # כמה גובה (ביחידות ציור) כל גופה מוסיפה למגדל
const STACK_R := 420.0         # מאיזה מרחק הם מתאספים למגדל
const CHECK_T := 0.5
const CLIMB_T := 0.5           # כמה זמן לוקח לטפס למקום במגדל
const TOPPLE_HITS := 2         # פגיעות בבסיס שמפילות את המגדל
const LADDER_CD := 0.45        # כל כמה זמן זומבי מטפס על המגדל הגמור
const IDLE_DISBAND := 4.0      # השחקן ירד / התרחק כל כך הרבה זמן -> המגדל מתפרק
const LIFE_MAX := 28.0
const SHORT_BUILD_T := 5.5     # אם לא באים עוד - בונים מגדל נמוך יותר
const FALL_DMG := Vector2i(12, 14)   # נזק נפילה: בסיס + לכל קומה
const DOMINO_DMG := 10
const LEARN_ARMOR := 2
const LEARN_TWIN := 4
# ---- בוס ----
const RAM_R := Vector2(160.0, 600.0)
const RAM_WIND := 0.9
const RAM_V := 380.0
const RAM_MAX := 700.0
const RAM_DMG := 2
const STUN_BARRICADE := 1.6
const STUN_WALL := 1.0
const RECOVER_T := 0.8
const SWAT_R := 90.0
const SWAT_T := 0.5
const SHED_N := 8              # כמה פעמים הוא משיר גופה לאורך כל החיים
const SHED_CAP := 5
const CORE_MULT := 1.9
const CORE_STUN_MULT := 2.5
const BODY_MULT := 0.45
const BODY_BLAST_MULT := 0.8
const BOSS_BODIES := 22

enum { FREE, GATHER, CLIMB, TOWER, FLY }
var _shed_drops := 0
var ammo_drops := 0   # בדיקה: כמה ארגזי תחמושת הבוס הפיל
var state := FREE
var tower = null
var slot := -1
var armored := false
var base_hits := 0
var _check := 0.0
var _gather_t := 0.0
var _climb_t := 0.0
var _climb_from := Vector2.ZERO
var _air := 0.0
var _spin := 0.0
var _spin_v := 0.0
var _fall_h := 0
var _clang := 0.0
var _rope := Color("a08858")
var _pants := Color("3a3a40")
var _scar := false
var _strap := false

# בוס
enum { B_WALK, B_WIND, B_RAM, B_STUN, B_RECOVER, B_SWAT }
var bstate := B_WALK
var rams := 0
var smashes := 0
var ram_hits := 0
var wall_hits := 0
var sheds := 0
var core_hits := 0
var swats := 0
var _bt := 0.0
var _bcd := 2.0
var _swat_cd := 1.0
var _ram_d := 0.0
var _ram_dir := 1.0
var _ram_hit := false
var _core_hit := false
var _core_flash := 0.0
var _shed_alive: Array = []
var _blast_cd := 0.0
var _touch_cd := 0.0
var _bodies: Array = []        # [זווית, רדיוס, גודל, צד, גוון]


func _boss() -> bool:
	return z != null and float(z.chase_range) > 600.0


func stats() -> Dictionary:
	if _boss():
		return {"name": "STACKER", "hp": 300, "walk": 30.0, "chase": 52.0, "damage": 2, "bite_delay": 1.2, "scale": 2.3, "width": 1.1,
			"duck": 0.0, "cover": 0.0, "skin": Color("8a948c"), "shirt": Color("5a4038"), "pants": Color("3a3436"), "shoe": Color("2a2224"),
			"points": 2400, "boss": true, "boss_name": "THE SIEGE TOWER", "ragdoll": false}
	return {"name": "STACKER", "hp": 34, "walk": 52.0, "chase": 112.0, "damage": 1, "bite_delay": 0.8, "scale": 1.05, "width": 1.15,
		"duck": 0.05, "cover": 0.05, "skin": Color("8a98a4"), "shirt": Color("4a4a50"), "pants": Color("3a3a40"), "shoe": Color("2a2a2e"), "points": 280}


func brain_overrides() -> Dictionary:
	if _boss():
		return {"aggression": 1.0}
	return {"aggression": 0.75, "use_heights": 0.0}


func setup() -> void:
	var r := RandomNumberGenerator.new()
	r.seed = z.get_instance_id()
	if _boss():
		var sh := z._shape.shape as RectangleShape2D
		sh.size = Vector2(124.0, 168.0)
		z._shape.position = Vector2(0.0, -84.0)
		for i in BOSS_BODIES:
			_bodies.append([r.randf_range(-PI, PI), r.randf_range(0.45, 0.92), r.randf_range(0.8, 1.15), -1.0 if r.randf() < 0.5 else 1.0, r.randf_range(-0.12, 0.1)])
		# הגופות הנושרות ראשונות = החיצוניות (בסדר אקראי)
		_bodies.sort_custom(func(a, b): return a[1] > b[1])
		return
	z.add_to_group("stackers")
	var skins := [Color("8a98a4"), Color("94a09a"), Color("a0a4b0"), Color("7e8e96"), Color("a4a090")]
	z.skin = Art.shade(skins[r.randi() % skins.size()], r.randf_range(-0.06, 0.06))
	var ropes := [Color("a08858"), Color("b09a68"), Color("8a6a40"), Color("6a7a5a")]
	_rope = ropes[r.randi() % ropes.size()]
	var pants := [Color("3a3a40"), Color("4a4236"), Color("2e3a44"), Color("4a3a3a")]
	_pants = pants[r.randi() % pants.size()]
	_scar = r.randf() < 0.5
	_strap = r.randf() < 0.4
	_check = r.randf() * CHECK_T


func can_bite() -> bool:
	return not _boss() and (state == FREE)


func use_brain_movement() -> bool:
	return true


func _main() -> Node:
	return z.get_parent()


static func _bump(m: Node, key: String, n := 1) -> int:
	var v: int = int(m.get_meta(key, 0)) + n
	m.set_meta(key, v)
	return v


func _tower_ok() -> bool:
	return tower != null and is_instance_valid(tower) and not tower.toppled


func in_tower() -> bool:
	return (state == TOWER or state == CLIMB) and _tower_ok()


# OilDrum (s53_decor.gd) / כל דבר אחר שמפיל את המגדל
func topple(dir: Vector2, cause := "fire") -> void:
	if _boss():
		return
	if _tower_ok():
		tower.request_topple(signf(dir.x) if dir.x != 0.0 else 1.0, cause)


# ============================================================
#  תנועה
# ============================================================
func physics(pl: Node, delta: float) -> bool:
	if _boss():
		return _boss_physics(pl, delta)
	_clang -= delta
	match state:
		FREE:
			_check -= delta
			if _check <= 0.0:
				_check = CHECK_T
				_try_form(pl)
			return false
		GATHER:
			_gather_t += delta
			if not _tower_ok() or _gather_t > 7.0:
				_to_free()
				return false
			var gx: float = float(tower.base_x) - z.global_position.x
			if absf(gx) < 10.0 and z.is_on_floor():
				tower.arrive(z)
				return true
			z._dir = signf(gx) if absf(gx) > 1.0 else z._dir
			z.velocity.x = move_toward(z.velocity.x, z._dir * z.chase_speed * 1.1, 900.0 * delta)
			if not z.is_on_floor():
				z.velocity.y += z.gravity * delta
			z.move_and_slide()
			if z.is_on_wall() and z.is_on_floor():
				z.velocity.y = z.jump_velocity
			if z.is_on_floor():
				z._walk_phase += delta * absf(z.velocity.x) * 0.075 / z.sc
			return true
		CLIMB, TOWER:
			if not _tower_ok():
				_to_free()
				return false
			z.velocity = Vector2.ZERO
			return true
		FLY:
			return _fly(delta)
	return false


func _to_free() -> void:
	state = FREE
	tower = null
	slot = -1
	armored = false
	base_hits = 0
	_spin = 0.0


func _try_form(pl: Node) -> void:
	if pl == null or pl.dead or not z.is_on_floor() or z._lying():
		return
	var d: Vector2 = pl.global_position - z.global_position
	if d.y > -70.0 or absf(d.x) > 360.0 or not pl.is_on_floor():
		return
	var m := _main()
	# מגדל גמור קרוב: פשוט מטפסים עליו (המוח מביא אותי לבסיס)
	for t in z.get_tree().get_nodes_in_group("stack_towers"):
		if t.toppled or absf(float(t.ground_y) - z.global_position.y) > 30.0:
			continue
		var dx := absf(float(t.base_x) - z.global_position.x)
		if t.built and dx < 260.0:
			return
		if t.can_join() and dx < STACK_R:
			t.enlist(z)
			return
	var mates: Array = []
	for s in z.get_tree().get_nodes_in_group("stackers"):
		if s == z or s.dead or s.dormant or s.type_mod == null or s.type_mod.state != FREE:
			continue
		if s.global_position.distance_to(z.global_position) < STACK_R and absf(s.global_position.y - z.global_position.y) < 30.0:
			mates.append(s)
	if mates.is_empty():
		return
	mates.sort_custom(func(a, b): return a.global_position.distance_to(z.global_position) < b.global_position.distance_to(z.global_position))
	var h: float = -d.y
	var seg_px: float = SEG * z.sc
	var need := clampi(int((h - 62.0 * z.sc) / seg_px) + 1, 2, 4)
	var side := signf(d.x) if d.x != 0.0 else 1.0
	var bx := _base_spot(pl.global_position.x - side * 34.0, side)
	if bx == INF:
		return
	var learned: int = int(m.get_meta("st_topples", 0))
	var twin: bool = learned >= LEARN_TWIN and mates.size() + 1 >= 4
	var towers: Array = [_new_tower(bx, side, need, h, learned >= LEARN_ARMOR)]
	if twin:
		var bx2 := _base_spot(bx - side * 124.0, side)
		if bx2 != INF:
			towers.append(_new_tower(bx2, side, need, h, learned >= LEARN_ARMOR))
			_bump(m, "st_twins")
			if not m.has_meta("st_told_twin"):
				m.set_meta("st_told_twin", true)
				z._popup("TWO TOWERS", Color("ffb070"), 14, -90.0)
	var all: Array = [z] + mates
	for i in all.size():
		var t = towers[i % towers.size()]
		if t.can_join():
			t.enlist(all[i])


func _new_tower(bx: float, side: float, need: int, h: float, arm: bool) -> Node:
	var t := Tower.new()
	t.base_x = bx
	t.ground_y = z.global_position.y
	t.dir = side
	t.need = need
	t.h = h
	t.armored = arm
	_main().add_child(t)
	return t


# איפה הבסיס יכול לעמוד: לא בתוך קיר / אוטובוס (זז לכיוון שממנו באים)
func _base_spot(x: float, side: float) -> float:
	var space: PhysicsDirectSpaceState2D = z.get_world_2d().direct_space_state
	var gy: float = z.global_position.y
	for i in 24:
		var bx := x - side * float(i) * 18.0
		var free := true
		for yy in [-12.0, -50.0]:
			var q := PhysicsPointQueryParameters2D.new()
			q.position = Vector2(bx, gy + yy)
			q.collision_mask = 1
			if not space.intersect_point(q, 1).is_empty():
				free = false
				break
		if free:
			return bx
	return INF


func _fly(delta: float) -> bool:
	_air += delta
	z.velocity.y += z.gravity * delta
	z.velocity.x = move_toward(z.velocity.x, 0.0, 40.0 * delta)
	_spin += _spin_v * delta
	z.move_and_slide()
	if (z.is_on_floor() and _air > 0.12) or _air > 3.0:
		_land()
	return true


func _land() -> void:
	state = FREE
	var spin_dir := signf(_spin_v) if _spin_v != 0.0 else 1.0
	_spin = 0.0
	_spin_v = 0.0
	var p: Vector2 = z.global_position
	Sfx.play("st_thud", p, 0.0, 0.12, 4)
	if Art.on_screen(z, p):
		Particles.burst(_main(), p + Vector2(0, -4), "smoke", Vector2.UP, 5)
	# דומינו: נוחת על זומבים אחרים
	for o in z.get_tree().get_nodes_in_group("zombies"):
		if o == z or o.dead or o.is_boss() or o.dormant:
			continue
		if absf(o.global_position.x - p.x) < 44.0 and absf(o.global_position.y - p.y) < 50.0:
			if o.type_mod != null and o.type_mod.has_method("in_tower") and o.type_mod.in_tower():
				o.type_mod.topple(Vector2(spin_dir, -0.3), "domino")
				continue
			o.take_damage(DOMINO_DMG, o.global_position + Vector2(0, -30), Vector2(spin_dir, -0.4), true, {"source": "topple", "fixed": DOMINO_DMG})
			if not o.dead:
				o.stagger(0.7)
	var n: int = FALL_DMG.x + FALL_DMG.y * _fall_h
	z.take_damage(n, p + Vector2(0, -30.0 * z.sc), Vector2(spin_dir, -0.3), true, {"source": "topple", "fixed": n})
	if not z.dead:
		z.lie_down()
		z.get_tree().create_timer(randf_range(1.0, 1.7)).timeout.connect(_get_up)


func _get_up() -> void:
	if z != null and is_instance_valid(z) and not z.dead and z.dormant:
		z._wake()


# ============================================================
#  נזק: הבסיס, דלת המכונית, פיצוצים
# ============================================================
func on_damage(_amount: int, hit_pos: Vector2, dir: Vector2, src: Dictionary) -> bool:
	if _boss():
		return _boss_on_damage(hit_pos, dir, src)
	if not in_tower():
		return true
	var s := str(src.get("source", "bullet"))
	if src.has("blast") or s == "grenade" or s == "rocket" or s == "explosion":
		tower.request_topple(signf(dir.x) if dir.x != 0.0 else tower.dir, "blast")
		return true
	if s == "fire":
		return true
	if slot != 0 or not (s == "bullet" or s == "melee"):
		return true
	var ly: float = (hit_pos.y - z.global_position.y) / z.sc
	if armored and dir.x * z._dir < 0.0 and ly < -18.0:   # דלת המכונית מלפנים
		_clang = 0.12
		var m := _main()
		var b := _bump(m, "st_blocks")
		Sfx.play("clang", hit_pos, -6.0, 0.15, 3)
		Particles.burst(m, hit_pos, "spark", Vector2(-dir.x, -0.4), 4)
		if b % 7 == 1:
			z._popup("SHOOT THE LEGS", Color("ffd34a"), 13, -70.0)
		return false
	base_hits += 2 if int(src.get("fixed", 0)) >= 10 else 1
	if base_hits >= TOPPLE_HITS:
		tower.request_topple(signf(dir.x) if dir.x != 0.0 else tower.dir, "base")
	return true


func on_death() -> void:
	if not _boss() and in_tower() and slot == 0:
		tower.request_topple(tower.dir, "base")


# ============================================================
#  המגדל: מחזיק את הגופות אחת על השנייה, מטפסים עליו, קורס
# ============================================================
class Tower extends Node2D:
	var base_x := 0.0
	var ground_y := 0.0
	var dir := 1.0
	var need := 3
	var h := 120.0
	var armored := false
	var built := false
	var toppled := false
	var members: Array = []
	var recruits: Array = []
	var climbs := 0
	var _life := 0.0
	var _idle := 0.0
	var _lcd := 0.0
	var _req := false
	var _req_dir := 1.0
	var _req_cause := ""

	func _ready() -> void:
		z_index = 2
		add_to_group("stack_towers")

	static func _inc(m: Node, key: String, n := 1) -> int:
		var v: int = int(m.get_meta(key, 0)) + n
		m.set_meta(key, v)
		return v

	func can_join() -> bool:
		return not built and not toppled and members.size() + recruits.size() < need

	func enlist(s: Node) -> void:
		recruits.append(s)
		s.type_mod.tower = self
		s.type_mod.state = GATHER
		s.type_mod._gather_t = 0.0

	func arrive(s: Node) -> void:
		recruits.erase(s)
		var tm = s.type_mod
		tm.slot = members.size()
		tm.state = CLIMB
		tm._climb_t = 0.0
		tm._climb_from = s.global_position
		tm.base_hits = 0
		tm.armored = armored and tm.slot == 0
		members.append(s)
		if tm.armored:
			var m := get_parent()
			_inc(m, "st_armored")
			if not m.has_meta("st_told_armor"):
				m.set_meta("st_told_armor", true)
				s._popup("THEY BRACE THE BASE", Color("ffb070"), 13, -90.0)

	func request_topple(d: float, cause: String) -> void:
		if toppled or _req:
			return
		_req = true
		_req_dir = d
		_req_cause = cause

	func _slot_y(i: int) -> float:
		var y := ground_y
		for j in i:
			y -= SEG * float(members[j].sc)
		return y

	func _physics_process(delta: float) -> void:
		if toppled:
			return
		_life += delta
		_lcd -= delta
		for r in recruits.duplicate():
			if not is_instance_valid(r) or r.dead or r.type_mod.tower != self:
				recruits.erase(r)
		for i in members.size():
			var m = members[i]
			if not is_instance_valid(m) or m.dead or m.type_mod.tower != self or m.dormant:
				request_topple(dir, "base" if i == 0 else "member")
				break
		if _req:
			_do_topple()
			return
		# המיקום של כל גופה
		var all_in := true
		for i in members.size():
			var m = members[i]
			var tm = m.type_mod
			var target := Vector2(base_x + sin(_life * 1.6 + float(i) * 1.3) * 1.2 * float(i) + (2.0 if i % 2 == 1 else 0.0) * dir, _slot_y(i))
			if tm.state == CLIMB:
				all_in = false
				tm._climb_t += delta
				var k := clampf(tm._climb_t / CLIMB_T, 0.0, 1.0)
				var p: Vector2 = tm._climb_from.lerp(target, k)
				p.y -= sin(k * PI) * 26.0
				m.global_position = p
				m._walk_phase += delta * 14.0
				if k >= 1.0:
					tm.state = TOWER
					Sfx.play("st_lock", target, -3.0, 0.12, 3)
			else:
				m.global_position = target
			m._dir = dir
		if not built and all_in and members.size() >= 2 and (members.size() >= need or (recruits.is_empty() and _life > SHORT_BUILD_T)):
			_complete()
		if not built and _life > 10.0:
			_disband()
			return
		var pl := get_tree().get_first_node_in_group("player")
		var above: bool = pl != null and not pl.dead and pl.global_position.y < ground_y - 50.0 and absf(pl.global_position.x - base_x) < 380.0
		_idle = 0.0 if above else _idle + delta
		if _idle > IDLE_DISBAND or _life > LIFE_MAX:
			_disband()
			return
		if built and pl != null:
			_ladder(pl)
		if Art.on_screen(self, Vector2(base_x, ground_y - 80.0), 160.0):
			queue_redraw()

	func _complete() -> void:
		built = true
		var m := get_parent()
		var n := _inc(m, "st_built")
		if not m.has_meta("st_told"):
			m.set_meta("st_told", true)
			members[members.size() - 1]._popup("THEY CLIMB EACH OTHER", Color("ffb070"), 14, -80.0)
		elif n % 3 == 0:
			members[members.size() - 1]._popup("TOWER!", Color("ffb070"), 12, -80.0)
		Sfx.play("st_lock", Vector2(base_x, ground_y - 60.0), 2.0, 0.1, 2, 0.8)
		# העליון קופץ ראשון לקומה שלך
		var pl := get_tree().get_first_node_in_group("player")
		if members.size() >= 3 and pl != null:
			var top = members.pop_back()
			var tm = top.type_mod
			tm._to_free()
			var dh: float = top.global_position.y - pl.global_position.y + 46.0
			top.velocity = Vector2(dir * 150.0, -sqrt(2.0 * float(top.gravity) * maxf(dh, 50.0)))
			top._alert_t = 4.0
			climbs += 1
			_inc(m, "st_climbs")

	func _ladder(pl: Node) -> void:
		if _lcd > 0.0 or Engine.get_physics_frames() % 4 != 0:
			return
		for o in get_tree().get_nodes_in_group("zombies"):
			if o.dead or o.dormant or o.is_boss() or not o.is_on_floor() or members.has(o) or recruits.has(o) or o.is_in_group("pursuers"):
				continue
			if absf(o.global_position.x - base_x) < 34.0 and absf(o.global_position.y - ground_y) < 16.0:
				var dh: float = ground_y - pl.global_position.y + 46.0
				o.velocity = Vector2(dir * 120.0, -sqrt(2.0 * float(o.gravity) * maxf(dh, 60.0)))
				o._alert_t = maxf(float(o._alert_t), 3.0)
				climbs += 1
				_inc(get_parent(), "st_climbs")
				_lcd = LADDER_CD
				Sfx.play("st_lock", o.global_position, -8.0, 0.2, 2, 1.2)
				return

	func _disband() -> void:
		toppled = true
		for m in members:
			if is_instance_valid(m) and not m.dead:
				m.type_mod._to_free()
				m.velocity = Vector2(randf_range(-80.0, 80.0), -120.0)
		for r in recruits:
			if is_instance_valid(r) and not r.dead:
				r.type_mod._to_free()
		members.clear()
		recruits.clear()
		queue_free()

	func _do_topple() -> void:
		toppled = true
		var m0 := get_parent()
		var n := 0
		if _req_cause != "member":
			n = _inc(m0, "st_topples")
		Sfx.play("st_topple", Vector2(base_x, ground_y - 60.0), 3.0, 0.1, 3)
		var cam: Camera2D = get_viewport().get_camera_2d()
		if cam != null and cam.has_method("shake") and Art.on_screen(self, Vector2(base_x, ground_y - 60.0)):
			cam.shake(6.0, 0.3)
		var top_y := ground_y
		for i in members.size():
			var m = members[i]
			if not is_instance_valid(m) or m.dead:
				continue
			var tm = m.type_mod
			tm.tower = null
			tm.slot = -1
			tm.armored = false
			tm.state = FLY
			tm._air = 0.0
			tm._fall_h = i
			tm._spin_v = _req_dir * (2.5 + float(i) * 1.6)
			m.velocity = Vector2(_req_dir * (60.0 + float(i) * 105.0) + randf_range(-25.0, 25.0), -110.0 - float(i) * 45.0)
			top_y = minf(top_y, m.global_position.y)
		if members.size() > 0 and is_instance_valid(members[0]):
			var txt := "TOPPLED!"
			if _req_cause == "fire":
				txt = "BURNED DOWN!"
			elif _req_cause == "blast":
				txt = "BLOWN APART!"
			elif _req_cause == "domino":
				txt = "DOMINO!"
			var hp := HitPop.new()
			hp.text = txt
			m0.add_child(hp)
			hp.global_position = Vector2(base_x, top_y - 70.0)
			Game.on_style("topple", 30)
		if n == LEARN_ARMOR and _req_cause != "member":
			var hp2 := HitPop.new()
			hp2.text = "THEY LEARN TO BRACE"
			hp2.col = Color("ffb070")
			hp2.size = 13
			m0.add_child(hp2)
			hp2.global_position = Vector2(base_x, top_y - 96.0)
		for r in recruits:
			if is_instance_valid(r) and not r.dead:
				r.type_mod._to_free()
		members.clear()
		recruits.clear()
		queue_free()

	# חבלים ובשר מאוחה בין הגופות (מאחורי הזומבים)
	func _draw() -> void:
		if members.size() < 2:
			return
		for i in members.size() - 1:
			var a = members[i]
			var b = members[i + 1]
			if not is_instance_valid(a) or not is_instance_valid(b):
				continue
			var s: float = a.sc
			var pa: Vector2 = a.global_position + Vector2(0, -38.0 * s)
			var pb: Vector2 = b.global_position + Vector2(0, -6.0 * s)
			for q in 3:
				var ox := (float(q) - 1.0) * 5.0 * s
				var mid := (pa + pb) * 0.5 + Vector2(ox * 1.6 + sin(_life * 2.0 + float(q)) * 1.5, 0)
				DrawBatch.polyline(self, PackedVector2Array([pa + Vector2(ox, 0), mid, pb + Vector2(ox * 0.6, 0)]), Color(0.36, 0.3, 0.3, 0.9), 3.4 - float(q) * 0.6)
				DrawBatch.polyline(self, PackedVector2Array([pa + Vector2(ox, 0), mid, pb + Vector2(ox * 0.6, 0)]), Color(0.55, 0.18, 0.16, 0.6), 1.2)
			# חבל שמחבר את הרתמות
			var r0: Vector2 = a.global_position + Vector2(-4.0 * a._dir, -24.0 * s)
			var r1: Vector2 = b.global_position + Vector2(-3.0 * b._dir, -24.0 * s)
			var rm := (r0 + r1) * 0.5 + Vector2(-8.0 * a._dir, 6.0)
			DrawBatch.polyline(self, PackedVector2Array([r0, rm, r1]), Color("8a7048"), 1.8)
			DrawBatch.circle(self, rm, 2.0, Color("6a5434"))


# טקסט גדול שצף מעל המגדל
class HitPop extends Node2D:
	var text := ""
	var col := Color(1.0, 0.85, 0.4)
	var size := 18
	var t := 0.0

	func _ready() -> void:
		z_index = 30

	func _process(delta: float) -> void:
		t += delta
		position.y -= (40.0 - t * 20.0) * delta
		modulate.a = clampf((1.5 - t) / 0.4, 0.0, 1.0)
		if t > 1.5:
			queue_free()
		queue_redraw()

	func _draw() -> void:
		var f := ThemeDB.fallback_font
		var k := 1.0 + 0.5 * clampf(1.0 - t / 0.15, 0.0, 1.0)
		DrawBatch.set_transform(self, Vector2.ZERO, 0.0, Vector2(k, k))
		var w := f.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
		DrawBatch.string_outline(self, f, Vector2(-w / 2.0, 0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, 5, Color(0, 0, 0, 0.85))
		DrawBatch.string(self, f, Vector2(-w / 2.0, 0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, col)


# ============================================================
#  בוס: THE SIEGE TOWER
# ============================================================
func _exposure() -> float:
	return clampf(0.22 + 0.78 * float(sheds) / float(SHED_N), 0.0, 1.0)


func _boss_physics(pl: Node, delta: float) -> bool:
	_bt -= delta
	_bcd -= delta
	_swat_cd -= delta
	_blast_cd -= delta
	_touch_cd -= delta
	_core_flash -= delta
	_clang -= delta
	_shed_check()
	var has_pl: bool = pl != null and not pl.dead
	var d: Vector2 = pl.global_position - z.global_position if has_pl else Vector2(9999, 0)
	var vx := 0.0
	match bstate:
		B_WALK:
			if has_pl:
				z._dir = signf(d.x) if absf(d.x) > 6.0 else z._dir
				vx = z._dir * (z.chase_speed if absf(d.x) < 900.0 else z.walk_speed)
				if absf(d.x) < SWAT_R and absf(d.y) < 130.0:
					vx = 0.0
					if _swat_cd <= 0.0:
						bstate = B_SWAT
						_bt = SWAT_T
						_ram_hit = false
						Sfx.play("st_wind", z.global_position, -2.0, 0.1, 2, 1.4)
				elif _bcd <= 0.0 and ((absf(d.x) > RAM_R.x and absf(d.x) < RAM_R.y and absf(d.y) < 140.0) or (z.is_on_wall() and z.is_on_floor())):   # (נתקע במחסום -> מנגח אותו)
					bstate = B_WIND
					_bt = RAM_WIND
					_ram_dir = z._dir
					Sfx.play("st_wind", z.global_position, 3.0, 0.08, 2)
					Sfx.play("roar", z.global_position, 2.0, 0.08, 2, 0.7)
			_touch(pl)
		B_WIND:
			vx = -_ram_dir * 22.0   # נשען אחורה
			if Engine.get_physics_frames() % 6 == 0 and Art.on_screen(z, z.global_position):
				Particles.burst(_main(), z.global_position + Vector2(-_ram_dir * 30.0, -4.0), "smoke", Vector2(-_ram_dir, -0.6), 2)
			if _bt <= 0.0:
				bstate = B_RAM
				_ram_d = 0.0
				_ram_hit = false
				rams += 1
				Sfx.play("st_ram", z.global_position, 4.0, 0.08, 2)
		B_RAM:
			vx = _ram_dir * RAM_V
			_ram_d += RAM_V * delta
			if Engine.get_physics_frames() % 3 == 0 and Art.on_screen(z, z.global_position):
				Particles.burst(_main(), z.global_position + Vector2(-_ram_dir * 40.0, -4.0), "smoke", Vector2(-_ram_dir, -0.4), 2)
			var front: float = z.global_position.x + _ram_dir * 84.0
			for b in z.get_tree().get_nodes_in_group("s53_barricades"):
				if b.broken:
					continue
				var bc: Vector2 = b.center()
				if absf(bc.x - front) < 46.0 and absf(bc.y - (z.global_position.y - 30.0)) < 60.0:
					b.smash(_ram_dir)
					smashes += 1
					_stun(STUN_BARRICADE, "BARRICADE SMASHED")
					_shed(2)
					return _move(delta, 0.0)
			if has_pl and not _ram_hit:
				var rr := Rect2(Vector2(minf(z.global_position.x, front), z.global_position.y - 150.0), Vector2(absf(front - z.global_position.x), 150.0))
				if rr.intersects(pl.body_rect()):
					_ram_hit = true
					ram_hits += 1
					if pl._roll_t <= 0.0:
						pl.hurt(RAM_DMG, Vector2(_ram_dir * 2.0, -1.0))
						pl.velocity = Vector2(_ram_dir * 520.0, -380.0)
						pl._push_t = maxf(float(pl._push_t), 0.9)
						Sfx.play("throw", pl.global_position, 3.0)
						_shake(9.0)
					bstate = B_RECOVER
					_bt = RECOVER_T
			# זומבים בדרך עפים הצידה
			if Engine.get_physics_frames() % 3 == 0:
				for o in z.get_tree().get_nodes_in_group("zombies"):
					if o == z or o.dead or o.dormant:
						continue
					if absf(o.global_position.x - front) < 30.0 and absf(o.global_position.y - z.global_position.y) < 40.0:
						o.velocity = Vector2(_ram_dir * 300.0, -320.0)
						o.take_damage(14, o.global_position + Vector2(0, -30), Vector2(_ram_dir, -0.5), true, {"source": "topple", "fixed": 14})
			if _ram_d > 40.0 and z.is_on_wall():
				wall_hits += 1
				_stun(STUN_WALL, "")
				return _move(delta, 0.0)
			if _ram_d >= RAM_MAX:
				bstate = B_RECOVER
				_bt = RECOVER_T
		B_STUN:
			if Engine.get_physics_frames() % 10 == 0 and Art.on_screen(z, z.global_position):
				Particles.burst(_main(), z.global_position + Vector2(randf_range(-30, 30), -170.0), "spark", Vector2.UP, 1)
			if _bt <= 0.0:
				bstate = B_RECOVER
				_bt = RECOVER_T
		B_RECOVER:
			if _bt <= 0.0:
				bstate = B_WALK
				_bcd = randf_range(2.4, 3.8)
		B_SWAT:
			if not _ram_hit and _bt < 0.12:
				_ram_hit = true
				swats += 1
				Sfx.play("ex_whoosh", z.global_position, 2.0, 0.1, 2, 0.7)
				var x0: float = z.global_position.x + (0.0 if z._dir > 0.0 else -120.0)
				if has_pl and Rect2(Vector2(x0, z.global_position.y - 150.0), Vector2(120.0, 150.0)).intersects(pl.body_rect()):
					pl.hurt(1, Vector2(z._dir * 1.8, -0.8))
			if _bt <= 0.0:
				bstate = B_WALK
				_swat_cd = randf_range(1.2, 2.0)
	return _move(delta, vx)


func _touch(pl: Node) -> void:
	if pl == null or pl.dead or _touch_cd > 0.0:
		return
	var r := Rect2(z.global_position + Vector2(-56.0, -160.0), Vector2(112.0, 160.0))
	if r.intersects(pl.body_rect()):
		_touch_cd = 1.0
		pl.hurt(1, Vector2(z._dir * 1.5, -0.6))


func _stun(t: float, msg: String) -> void:
	bstate = B_STUN
	_bt = t
	z.velocity.x = -_ram_dir * 120.0
	Sfx.play("st_thud", z.global_position, 6.0, 0.05, 2, 0.6)
	Sfx.play("clang", z.global_position, 0.0, 0.1, 2, 0.7)
	_shake(12.0)
	if Art.on_screen(z, z.global_position):
		Particles.burst(_main(), z.global_position + Vector2(_ram_dir * 80.0, -60.0), "smoke", Vector2(-_ram_dir, -0.5), 10)
	if msg != "":
		z._popup(msg, Color("ffd060"), 16, -95.0)
	z._popup("CORE EXPOSED", Color("ff7050"), 14, -80.0)


func _move(delta: float, vx: float) -> bool:
	z.velocity.x = move_toward(z.velocity.x, vx, (2400.0 if bstate == B_RAM else 900.0) * delta)
	if not z.is_on_floor():
		z.velocity.y += z.gravity * delta
	z.move_and_slide()
	if z.is_on_floor():
		z._walk_phase += delta * absf(z.velocity.x) * 0.075 / z.sc * 2.2
	if z.global_position.x > z.world_w - 60.0:
		z.global_position.x = z.world_w - 60.0
	return true


func _shake(s: float) -> void:
	var cam: Camera2D = z.get_viewport().get_camera_2d()
	if cam != null and cam.has_method("shake") and Art.on_screen(z, z.global_position):
		cam.shake(s, 0.3)


# כל 1/8 חיים - גופה נושרת
func _shed_check() -> void:
	var step: float = float(z.max_hp) / float(SHED_N + 1)
	var due := int((float(z.max_hp) - float(z.hp)) / step)
	if due > sheds and sheds < SHED_N:
		_shed(1)


func _shed(n: int) -> void:
	for q in n:
		if sheds < SHED_N:
			sheds += 1
		_shed_alive = _shed_alive.filter(func(o): return is_instance_valid(o) and not o.dead)
		if _shed_alive.size() >= SHED_CAP:
			continue
		var m := _main()
		var x: float = z.global_position.x + randf_range(-60.0, 60.0)
		var o = m._spawn_zombie(clampf(x, 40.0, z.world_w - 80.0), z.global_position.y, 0 if randf() < 0.6 else 1)
		if o == null:
			continue
		o.lie_down()
		o._alert_t = 6.0
		_shed_alive.append(o)
		var tm = o
		z.get_tree().create_timer(randf_range(0.5, 1.0)).timeout.connect(func():
			if is_instance_valid(tm) and not tm.dead and tm.dormant:
				tm._wake())
		Particles.burst(m, Vector2(x, z.global_position.y - 90.0), "hit", Vector2(signf(x - z.global_position.x), -0.5), 12)
		Sfx.play("splat", Vector2(x, z.global_position.y), 2.0, 0.12, 3)
	if n > 0 and sheds % 2 == 0 and sheds < SHED_N:
		z._popup("IT SHEDS ITS DEAD", Color("ffb070"), 12, -100.0)
	_shed_drops += n
	if _shed_drops >= 2 and ammo_drops < 4:   # בין הגופות שנושרות - ארגז תחמושת (קרב ארוך)
		_shed_drops = 0
		ammo_drops += 1
		z._drop(PickupScript.AMMO)


# הפנים בלב הגוש = נקודת התורפה. ביחידות ציור (פונה ימינה)
func _core_local() -> Vector2:
	return Vector2(9.0, -46.0)


func _core_r() -> float:
	return 5.0 + 8.0 * _exposure()


func _boss_on_damage(hit_pos: Vector2, dir: Vector2, src: Dictionary) -> bool:
	var s := str(src.get("source", "bullet"))
	_core_hit = false
	if src.has("blast") or s == "grenade" or s == "rocket":
		if _blast_cd <= 0.0:
			_blast_cd = 1.0
			_shed(1)
		return true
	if not (s == "bullet" or s == "melee"):
		return true
	var lp: Vector2 = (hit_pos - z.global_position) / z.sc
	lp.x *= z._dir / z.wf
	if lp.distance_to(_core_local()) < _core_r() * 1.25:
		_core_hit = true
		core_hits += 1
		_core_flash = 0.12
		if core_hits % 12 == 1:
			z._popup("THE CORE!", Color("ff6a50"), 13, -110.0)
	elif randf() < 0.25:
		Particles.burst(_main(), hit_pos, "hit", -dir, 3)
	return true


func damage_mult(zone: String, src: Dictionary) -> float:
	if not _boss():
		return 1.0
	var k := 1.0
	if zone == "head" and not src.has("fixed"):
		k = 0.22   # (הראש של zombie.gd = החצי העליון של הגוש - לא באמת ראש)
	if src.has("blast"):
		return k * BODY_BLAST_MULT
	if _core_hit:
		_core_hit = false
		return k * (CORE_STUN_MULT if bstate == B_STUN else CORE_MULT)
	return k * BODY_MULT


# ============================================================
#  ציור
# ============================================================
func draw() -> bool:
	if _boss():
		_draw_boss()
		return true
	begin_draw(state == FREE or state == GATHER)
	if state == FLY and not z.dead:
		var s := Vector2(z._dir * z.wf * z.sc, z.sc)
		DrawBatch.set_transform_matrix(z, Transform2D(_spin, Vector2(0.0, -28.0 * z.sc)) * Transform2D(0.0, s, 0.0, Vector2(0.0, 28.0 * z.sc)))
	var sk := col(z.skin)
	var dk := col(Art.shade(z.skin, 0.28))
	var pa := col(_pants)
	var p: float = z._walk_phase
	var t: float = z._time
	# ---- תנוחה ----
	var hip := Vector2(0, -22)
	var sh := Vector2(5, -38)
	var f: Array = feet(6.0, 3.0)
	var hb := sh + Vector2(10, 8 + sin(p) * 2.0)     # יד אחורית
	var hf := sh + Vector2(15, 5 + sin(p + 1.5) * 2.0)   # יד קדמית
	var head := sh + Vector2(5, -7)
	var role := "run"
	if state == CLIMB:
		role = "climb"
	elif state == TOWER:
		if slot == 0:
			role = "base"
		elif tower != null and is_instance_valid(tower) and slot == tower.members.size() - 1 and tower.built:
			role = "top"
		elif tower != null and is_instance_valid(tower) and slot == tower.members.size() - 1:
			role = "top"
		else:
			role = "mid"
	elif state == FLY:
		role = "fly"
	match role:
		"climb":
			var k := sin(t * 14.0)
			f = [Vector2(5, -9 + k * 2.0), Vector2(-4, -5 - k * 2.0)]
			hip = Vector2(0, -20)
			sh = Vector2(2, -37)
			head = sh + Vector2(3, -8)
			hf = sh + Vector2(5, -17 + k * 3.0)
			hb = sh + Vector2(-3, -15 - k * 3.0)
		"base":   # בסיס: עומד פשוק, הראש למטה, הידיים מחזיקות את הקרסוליים של זה שמעליו
			f = [Vector2(10, 0), Vector2(-9, 0)]
			hip = Vector2(0, -20)
			sh = Vector2(1, -37)
			head = sh + Vector2(7, -3)
			hf = Vector2(4, -46 + sin(t * 3.0) * 0.6)
			hb = Vector2(-7, -45)
			if armored:
				hf = sh + Vector2(13, 8)
		"mid":   # אמצע: עומד על הכתפיים, מחזיק את זה שמעליו
			f = [Vector2(6, 0), Vector2(-6, 0)]
			hip = Vector2(0, -20)
			sh = Vector2(1, -37)
			head = sh + Vector2(6, -4)
			hf = Vector2(4, -46)
			hb = Vector2(-6, -45)
		"top":
			f = [Vector2(6, 0), Vector2(-6, 0)]
			hip = Vector2(0, -22)
			sh = Vector2(3, -40)
			head = sh + Vector2(3, -9)
			var cl := sin(t * 9.0)
			hf = sh + Vector2(12 + cl * 3.0, -20 - cl * 2.0)
			hb = sh + Vector2(5 - cl * 2.0, -23 + cl * 2.0)
		"fly":
			f = [Vector2(9, -10), Vector2(-9, -3)]
			hf = sh + Vector2(14, -8)
			hb = sh + Vector2(-13, -12)
			head = sh + Vector2(4, -8)
	var lean: float = (head.x - sh.x) * 0.1
	# ---- חבל שנגרר מאחור (מתנדנד) ----
	var r0 := hip + Vector2(-5, -2)
	var rope := PackedVector2Array([r0])
	for i in 5:
		var u := float(i + 1) / 5.0
		rope.append(r0 + Vector2(-5.0 - u * 9.0 + sin(t * 4.0 + u * 3.0 + p * 0.5) * 2.5 * u, u * 18.0 - u * u * 4.0))
	DrawBatch.polyline(z, rope, col(Art.shade(_rope, 0.25)), 1.6)
	for i in [2, 4]:
		DrawBatch.circle(z, rope[i], 1.5, col(Art.shade(_rope, 0.35)))
	# ---- רגל ויד אחוריות ----
	z._leg(hip + Vector2(-3, 0), f[1], col(Art.shade(_pants, 0.25)), dk, Color(0, 0, 0, 0))
	_arm2(sh + Vector2(-4, 1), hb, dk, dk, 4.4)
	_claws(hb, dk, role)
	# ---- גוף חשוף, צלעות, רתמת חבלים ----
	var torso := PackedVector2Array([sh + Vector2(-7, -1), sh + Vector2(7, 0), sh + Vector2(6, 10), hip + Vector2(6, 1), hip + Vector2(-6, 1), sh + Vector2(-8, 9)])
	Art.fill_shaded(z, torso, sk, 0.16, 0.34)
	var rib := col(Color(0.2, 0.24, 0.3, 0.45))
	for q in 4:
		DrawBatch.line(z, sh + Vector2(-3 + lean, 5.0 + float(q) * 2.6), sh + Vector2(4 + lean, 5.6 + float(q) * 2.6), rib, 0.9)
	DrawBatch.line(z, sh + Vector2(1, 2), hip + Vector2(1, -2), col(Color(0.25, 0.28, 0.34, 0.5)), 0.8)
	if z._det[1]:   # תפר
		DrawBatch.line(z, sh + Vector2(-5, 3), hip + Vector2(-3, -4), col(Color("4a2a2a")), 1.0)
	var rc := col(_rope)
	DrawBatch.line(z, sh + Vector2(-6, 0), hip + Vector2(5, -1), rc, 2.0)
	DrawBatch.line(z, sh + Vector2(6, 0), hip + Vector2(-5, -1), rc, 2.0)
	DrawBatch.line(z, hip + Vector2(-7, -2), hip + Vector2(7, -2), rc, 2.4)
	var knot := (sh + hip) * 0.5 + Vector2(0, 1)
	DrawBatch.circle(z, knot, 2.2, col(Art.shade(_rope, 0.2)))
	DrawBatch.circle(z, hip + Vector2(6, -2), 1.8, col(Color("6a6e74")))   # טבעת מתכת
	DrawBatch.arc(z, hip + Vector2(8, 1), 2.4, -1.0, 2.6, 6, col(Color("8a8e94")), 1.0)   # קרבינר
	# מכנסיים קרועים
	Art.fill(z, PackedVector2Array([hip + Vector2(-7, -1), hip + Vector2(7, -1), hip + Vector2(7, 5), hip + Vector2(-7, 5)]), pa, Art.OUTLINE, 1.0)
	# ---- רגל קדמית ----
	z._leg(hip + Vector2(3, 0), f[0], pa, sk, Color(0, 0, 0, 0))
	var carrier := role == "base" or role == "mid"
	if not carrier:
		_draw_head(head, role, rc, sk)
	# ---- יד קדמית ----
	if role == "base" and armored:
		_door(sh, hf)
	_arm2(sh + Vector2(4, 1), hf, sk, sk, 4.8, true)
	_claws(hf, sk, role)
	if carrier:
		_draw_head(head, role, rc, sk)
	if _clang > 0.0:
		Art.glow(z, sh + Vector2(14, 6), 10.0, Color(1, 1, 0.9, 0.6))
	end_draw()
	return true


# ראש קירח שקוע
func _draw_head(head: Vector2, role: String, rc: Color, sk: Color) -> void:
	Art.oval_shaded(z, head, 5.6, 6.0, sk, 0.1)
	DrawBatch.line(z, head + Vector2(-4, -3), head + Vector2(1, -5.5), col(Color(1, 1, 1, 0.12)), 1.4)   # ברק על הקרחת
	if _scar:
		DrawBatch.line(z, head + Vector2(-3, -4), head + Vector2(2, 0), col(Color("5a2a2a")), 1.0)
		for q in 3:
			DrawBatch.line(z, head + Vector2(-2.0 + float(q) * 1.6, -3.2 + float(q) * 1.1), head + Vector2(-1.0 + float(q) * 1.6, -4.4 + float(q) * 1.1), col(Color("5a2a2a")), 0.7)
	face(head, Vector2(3.5, -0.5) if role != "base" else Vector2(3.5, 0.5))
	if _strap:   # רצועת ראש
		DrawBatch.line(z, head + Vector2(-5.5, -1.5), head + Vector2(5.0, -2.5), rc, 1.6)


# יד עם מרפק מוגבל: בלי "כנף" כשהיד קרובה לכתף (z._arm מותח את המרפק החוצה). המרפק פונה למטה/אחורה (fwd = קדימה)
func _arm2(a: Vector2, b: Vector2, skin_c: Color, sleeve: Color, w := 4.6, fwd := false) -> void:
	var d := b - a
	var n := Vector2.ZERO
	if d.length() > 0.01:
		n = d.orthogonal().normalized()
		if n.y + (n.x if fwd else -n.x) * 0.5 < 0.0:
			n = -n
	var half := d.length() * 0.5
	var e := a + d * 0.5 + n * minf(sqrt(maxf(0.0, 90.0 - half * half)), 3.5)
	Art.limb(z, PackedVector2Array([a, e]), w + 0.6, sleeve)
	Art.limb(z, PackedVector2Array([e, b]), w, skin_c)
	Art.disc(z, b, w * 0.55, skin_c, Art.OUTLINE, 1.0)


# אצבעות כפופות כמו ווים
func _claws(h: Vector2, c: Color, role: String) -> void:
	var up := role in ["climb", "base", "mid", "top"]
	for q in 3:
		var a := (-1.9 if up else 0.2) + float(q) * 0.45
		var p1 := h + Vector2.from_angle(a) * 3.0
		var p2 := p1 + Vector2.from_angle(a + 1.3) * 2.0
		DrawBatch.polyline(z, PackedVector2Array([h, p1, p2]), c, 1.0)
		DrawBatch.line(z, p1, p2, col(Color("2a2420")), 0.7)


# דלת מכונית חלודה (הבסיס המשוריין)
func _door(sh: Vector2, hand: Vector2) -> void:
	var o := sh + Vector2(10, -10)
	var pts := PackedVector2Array([o, o + Vector2(7, 1), o + Vector2(8, 36), o + Vector2(1, 38), o + Vector2(-1, 20)])
	Art.fill_shaded(z, pts, col(Color("8a3a2a")), 0.15, 0.35, Art.OUTLINE, 1.2)
	Art.fill(z, PackedVector2Array([o + Vector2(1, 2), o + Vector2(6, 3), o + Vector2(6, 13), o + Vector2(0.5, 14)]), col(Color(0.45, 0.6, 0.7, 0.7)), Art.OUTLINE, 0.8)   # חלון
	DrawBatch.line(z, o + Vector2(2, 4), o + Vector2(5, 11), col(Color(1, 1, 1, 0.5)), 0.8)   # סדק בזכוכית
	DrawBatch.line(z, o + Vector2(5, 5), o + Vector2(2, 10), col(Color(1, 1, 1, 0.35)), 0.6)
	DrawBatch.rect(z, Rect2(o + Vector2(2, 20), Vector2(4, 1.4)), col(Color("c0c4c8")))   # ידית
	for q in 4:   # חלודה
		DrawBatch.circle(z, o + Vector2(2.0 + float(q % 2) * 3.0, 26.0 + float(q) * 2.5), 1.3, col(Color("5a2a1a")))
	for q in 3:   # חורי קליעים
		DrawBatch.circle(z, o + Vector2(3.0 + float(q) * 1.5, 16.0 + float(q) * 6.0), 0.9, col(Color("1a1414")))
	DrawBatch.circle(z, hand, 2.4, col(z.skin))


func _draw_boss() -> void:
	var s := Vector2(z._dir * z.wf * z.sc, z.sc)
	if not z.dead:
		Art.ground_shadow(z, Vector2.ZERO, 70.0)
	if z.dead:
		var outer := Transform2D(z._angle * 0.5, Vector2(0.0, -9.0 * z.sc))
		DrawBatch.set_transform_matrix(z, outer * Transform2D(0.0, s, 0.0, Vector2(0.0, 9.0 * z.sc)))
	else:
		var tilt := 0.0
		if bstate == B_WIND:
			tilt = -0.08 * clampf(1.0 - _bt / RAM_WIND, 0.0, 1.0)
		elif bstate == B_RAM:
			tilt = 0.1
		elif bstate == B_STUN:
			tilt = sin(z._time * 6.0) * 0.05
		DrawBatch.set_transform_matrix(z, Transform2D(tilt, Vector2.ZERO) * Transform2D(0.0, s, 0.0, Vector2.ZERO))
	var t: float = z._time
	var p: float = z._walk_phase
	var sk := col(z.skin)
	var dk := col(Art.shade(z.skin, 0.3))
	var c := Vector2(0, -44)
	# ---- רגליים של כולם (מרבה רגליים) ----
	for i in 7:
		var lx := -24.0 + float(i) * 8.0
		var ph := p * 1.3 + float(i) * 1.7
		var foot := Vector2(lx + sin(ph) * 4.5, -maxf(0.0, cos(ph)) * 2.5)
		var knee := Vector2(lx + 3.0 + sin(ph) * 2.0, -8.0)
		var lc := sk if i % 2 == 0 else dk
		Art.limb(z, PackedVector2Array([Vector2(lx, -16), knee, foot]), 3.0, lc)
		DrawBatch.line(z, foot, foot + Vector2(2.5, 0), col(Color("2a2224")), 1.6)
	# ---- הגוש ----
	var mass := PackedVector2Array()
	for i in 30:
		var a := float(i) / 30.0 * TAU
		var r := 1.0 + sin(a * 5.0 + 1.3) * 0.06 + sin(a * 9.0) * 0.04 + sin(t * 2.0 + a * 3.0) * 0.015
		mass.append(c + Vector2(cos(a) * 30.0, sin(a) * 37.0) * r)
	Art.fill_shaded(z, mass, sk, 0.14, 0.38, Art.OUTLINE, 1.0)
	# ---- הגופות המאוחות ----
	var gone := int(float(sheds) * float(BOSS_BODIES) / float(SHED_N))
	for i in _bodies.size():
		var b: Array = _bodies[i]
		var bp := c + Vector2(cos(float(b[0])) * 30.0, sin(float(b[0])) * 37.0) * float(b[1])
		if i < gone:   # נשרה: חור בשר אדום
			Art.oval(z, bp, 4.0, 3.2, col(Color("6a1a18")), float(b[0]), Art.NONE)
			Art.oval(z, bp + Vector2(0.6, 0.4), 2.4, 1.8, col(Color("9a2a24")), float(b[0]), Art.NONE)
			continue
		_fused_body(bp, float(b[0]), float(b[2]), float(b[3]), float(b[4]), t + float(i))
	# ---- הפנים בלב הגוש (CORE) ----
	_core_face(_core_local(), _exposure(), t)
	# ---- איל הניגוח ----
	var ram_off := 0.0
	if bstate == B_WIND:
		ram_off = -9.0 * clampf(1.0 - _bt / RAM_WIND, 0.0, 1.0)
	elif bstate == B_RAM:
		ram_off = 6.0
	_ram(Vector2(-6.0 + ram_off, -30.0), Vector2(46.0 + ram_off, -32.0))
	# ידיים שמחזיקות את האיל
	for q in 4:
		var ax := -2.0 + float(q) * 9.0
		var sp := c + Vector2(ax * 0.7, 6.0 + float(q % 2) * 4.0)
		_arm2(sp, Vector2(ax + ram_off, -31.0 + (1.5 if q % 2 == 0 else -1.5)), sk if q % 2 == 0 else dk, dk, 3.6)
	# ידיים שמנופפות למעלה
	for q in 5:
		var a2 := -PI * 0.5 + (float(q) - 2.0) * 0.38
		var root := c + Vector2(cos(a2) * 26.0, sin(a2) * 33.0)
		var reach := root + Vector2.from_angle(a2 + sin(t * 3.0 + float(q)) * 0.3) * (9.0 + float(q % 2) * 3.0)
		_arm2(root, reach, sk if q % 2 == 1 else dk, dk, 3.4, q >= 2)
		_claws(reach, dk, "top")
	if bstate == B_SWAT and not z.dead:   # יד ענקית מניפה
		var k := 1.0 - clampf(_bt / SWAT_T, 0.0, 1.0)
		var hand := c + Vector2(20.0 + 22.0 * k, -26.0 + 40.0 * k)
		Art.limb(z, PackedVector2Array([c + Vector2(18, -10), c + Vector2(30, -24 + 10.0 * k), hand]), 4.5, sk)
		Art.disc(z, hand, 4.0, sk)
		if k > 0.6:
			DrawBatch.arc(z, c + Vector2(18, -10), 36.0, -0.9, 0.9, 10, Color(1, 1, 1, 0.3), 3.0)
	if bstate == B_STUN and not z.dead:   # כוכבים מעל
		for q in 3:
			var a3 := t * 4.0 + float(q) * TAU / 3.0
			DrawBatch.circle(z, c + Vector2(cos(a3) * 16.0, -42.0 + sin(a3) * 4.0), 1.8, Color(1.0, 0.9, 0.4, 0.9))
	DrawBatch.set_transform_matrix(z, Transform2D.IDENTITY)


# גופה אחת שקועה בתוך הגוש: קרע של בגד, ראש עם פנים, יד שבולטת החוצה (או רגל - בתחתית)
const CLOTH := [Color("5a6a88"), Color("7a4a3a"), Color("6e3036"), Color("5a6448"), Color("8a7646"), Color("3e6a6a"), Color("9a9484"), Color("4a3a5a")]

func _fused_body(bp: Vector2, a: float, size: float, side: float, tint: float, t: float) -> void:
	var out := Vector2.from_angle(a)
	var tg := out.orthogonal()
	var skc := col(Art.shade(z.skin, tint - 0.06))
	var idx := int(absf(a) * 100.0) % CLOTH.size()
	# קרע בגד
	var cc := col(Art.shade(CLOTH[idx], 0.1))
	Art.fill(z, PackedVector2Array([bp - tg * 5.0 * size - out * 2.0, bp + tg * 4.5 * size - out * 2.5, bp + tg * 5.0 * size + out * 2.5 * size, bp - tg * 4.0 * size + out * 3.0 * size]), cc, Art.OUTLINE, 0.8)
	DrawBatch.line(z, bp - tg * 3.0 * size, bp + tg * 3.0 * size + out * 1.5, col(Art.shade(CLOTH[idx], 0.35)), 0.8)
	if out.y > 0.55:   # בתחתית: רגל תלויה
		var kn := bp + out * 6.0 * size + tg * side * 2.0
		var ft := kn + Vector2(side * 2.0, 6.0 * size + sin(t * 3.0) * 1.0)
		Art.limb(z, PackedVector2Array([bp, kn, ft]), 2.6 * size, skc)
		DrawBatch.line(z, ft, ft + Vector2(side * 3.0, 0), col(Color("2a2224")), 1.6)
		return
	# יד שבולטת החוצה (מרפק מוגבל)
	var hand := bp + out.rotated(side * 0.7) * 11.0 * size + Vector2(0, sin(t * 2.2) * 1.2)
	var elbow := bp + out.rotated(side * 0.3) * 6.0 * size
	Art.limb(z, PackedVector2Array([bp + out * 1.5, elbow, hand]), 2.3 * size, col(Art.shade(z.skin, tint + 0.08)))
	for q in 3:   # אצבעות
		var fa := out.rotated(side * 0.7).angle() + (float(q) - 1.0) * 0.45
		DrawBatch.line(z, hand, hand + Vector2.from_angle(fa) * 2.2 * size, col(Color("2a2420")), 0.8)
	# ראש עם פנים (מסתכל החוצה)
	var head := bp + out * 3.4 * size - tg * side * 1.5
	Art.oval_shaded(z, head, 3.5 * size, 3.9 * size, skc, a + PI * 0.5)
	var eye_a := head + out * 0.6 * size + tg * 1.3 * size
	var eye_b := head + out * 0.6 * size - tg * 1.3 * size
	Art.oval(z, eye_a, 0.9 * size, 0.7 * size, Color(0.1, 0.02, 0.02), a, Art.NONE)
	Art.oval(z, eye_b, 0.9 * size, 0.7 * size, Color(0.1, 0.02, 0.02), a, Art.NONE)
	if not z.dead and int(t * 2.0 + float(idx)) % 5 == 0:
		DrawBatch.circle(z, eye_a, 0.5 * size, Color(1.0, 0.55, 0.2))
		DrawBatch.circle(z, eye_b, 0.5 * size, Color(1.0, 0.55, 0.2))
	Art.oval(z, head + out * 2.2 * size, 1.1 * size, 0.7 * size, Color(0.18, 0.02, 0.04), a, Art.NONE)   # פה פתוח
	# תפר בשר בין הגופה לגוש
	DrawBatch.arc(z, bp, 5.0 * size, a + PI - 1.0, a + PI + 1.0, 6, col(Color(0.5, 0.12, 0.12, 0.7)), 1.0)


func _core_face(cp: Vector2, e: float, t: float) -> void:
	var r := _core_r()
	Art.oval(z, cp, r * 1.25, r * 1.35, col(Color("5a1214")), 0.0, Art.NONE)   # בשר חשוף
	for q in 6:   # סיבים
		var a := float(q) / 6.0 * TAU + 0.3
		DrawBatch.line(z, cp + Vector2.from_angle(a) * r * 1.05, cp + Vector2.from_angle(a) * r * 1.4, col(Color("8a2a24")), 1.0)
	var fc := Color(1, 1, 1) if _core_flash > 0.0 else Art.shade(Color("b0a090"), -0.05)
	Art.oval_shaded(z, cp, r, r * 1.12, fc, 0.0)
	var eye_c := Color(1.0, 0.85, 0.3) if bstate != B_STUN else Color(0.6, 0.8, 1.0)
	for sx in [-0.38, 0.38]:
		var ep := cp + Vector2(sx * r, -0.18 * r)
		Art.oval(z, ep, 0.24 * r, 0.18 * r, Color(0.05, 0.0, 0.02), 0.0, Art.NONE)
		if not z.dead:
			DrawBatch.circle(z, ep, 0.1 * r, eye_c)
	if not z.dead:
		Art.glow(z, cp + Vector2(0, -0.18 * r), r * 1.1, Color(1.0, 0.5, 0.2, 0.25 + 0.2 * e))
	var mo := 0.12 * r + (0.12 * r if bstate == B_WIND or bstate == B_RAM else 0.0) + sin(t * 5.0) * 0.03 * r
	DrawBatch.colored_polygon(z, PackedVector2Array([cp + Vector2(-0.4 * r, 0.32 * r), cp + Vector2(0.4 * r, 0.32 * r), cp + Vector2(0.3 * r, 0.42 * r + mo), cp + Vector2(-0.3 * r, 0.42 * r + mo)]), Color(0.12, 0.0, 0.03))
	for q in 5:
		var tx := -0.32 * r + float(q) * 0.16 * r
		DrawBatch.line(z, cp + Vector2(tx, 0.33 * r), cp + Vector2(tx, 0.4 * r), Color(0.85, 0.82, 0.7), 0.8)


func _ram(a: Vector2, b: Vector2) -> void:
	var d := (b - a).normalized()
	var n := d.orthogonal()
	var wood := col(Color("6a4a30"))
	Art.fill_shaded(z, PackedVector2Array([a - n * 3.2, b - n * 3.2, b + n * 3.2, a + n * 3.2]), wood, 0.15, 0.35, Art.OUTLINE, 1.0)
	for q in 3:   # טבעות ברזל
		var rp := a.lerp(b, 0.2 + float(q) * 0.27)
		DrawBatch.line(z, rp - n * 3.6, rp + n * 3.6, col(Color("3a3a40")), 1.8)
	DrawBatch.line(z, a + n * 1.2, b + n * 1.2, col(Color("8a6a48")), 0.6)
	# ראש ברזל קהה
	var h := PackedVector2Array([b - n * 4.6, b + d * 6.0 - n * 3.6, b + d * 7.5, b + d * 6.0 + n * 3.6, b + n * 4.6])
	Art.fill_shaded(z, h, col(Color("4a4c54")), 0.25, 0.3, Art.OUTLINE, 1.1)
	DrawBatch.circle(z, b + d * 3.0 - n * 2.0, 0.8, col(Color("8a8c94")))
	DrawBatch.circle(z, b + d * 3.0 + n * 2.0, 0.8, col(Color("8a8c94")))
	DrawBatch.line(z, b + d * 5.0 - n * 2.0, b + d * 7.0, col(Color(0.5, 0.05, 0.05, 0.8)), 1.0)   # דם
