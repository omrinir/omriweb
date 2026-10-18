extends "res://enemies/stationary_boss.gd"
# ============================================================
#  ICE TITAN (הבוס של שלב 35, "SKULL GLACIER") - בוס נייח: ענק קפוא שקבור עד המותניים בקרחון.
#  ראש גולגולת עם כתר נטיפים, כלוב צלעות מקרח, ובתוכו לב כחול פועם = נקודת התורפה.
#  התקפות (stationary_boss.gd):
#    breath  - נשיפת כפור: מניפה של BREATH_N נטיפים (מקדים אותך אחרי פספוסים)
#    spikes  - מכה בקרח -> גל של קוצי קרח (IceSpikes) שרץ על הקרקע אליך: קופצים מעליו / עולים למדף
#    boulder - זורק גוש קרח בקשת (מתפוצץ). "למד" שאתה מתחבא -> 3 גושים מעל המחסה
#    pound   - צמוד אליו: מכת קרקע
#  "THEY LEARN": GUARD_HITS פגיעות בלב תוך GUARD_WIN שניות -> מכסה את הלב ביד (GUARD_T).
#    ההגנה יורדת רק כשהוא מתכונן להתקפה - יורים בלב בזמן ההכנה!
#  לשנות: BREATH_CD, SPIKE_CD, BOULDER_CD, BREATH_N, GUARD_HITS, GUARD_WIN, GUARD_T.
# ============================================================

const SOUNDS := {
	"it_breath": [["N", 0, 0, 0.0, 0.7, 0.1, 2.0, 0.6, 0.35, 0, 0.6], ["S", 900, 1300, 0.0, 0.6, 0.05, 3.0, 0.15, 1.0, 0.05]],
	"it_roar": {"drive": 1.6, "layers": [["V", 80, 60, 0.0, 1.2, 0.1, 1.0, 0.7, 1.0, 0.06, 0, [300, 700, 4]], ["N", 0, 0, 0.0, 1.0, 0.1, 1.5, 0.4, 0.25, 0, 0.4]]},
	"it_spike": [["N", 0, 0, 0.0, 0.18, 0.0, 15.0, 0.4, 0.6, 0, 0.6], ["S", 2200, 1200, 0.0, 0.12, 0.0, 25.0, 0.15, 1.0, 0]],
	"it_block": [["S", 2400, 2300, 0.0, 0.1, 0.0, 30.0, 0.3, 1.0, 0], ["C", 0, 0, 0.0, 0.05, 0.0, 60.0, 0.4, 1.0, 0]],
}

const BREATH_CD := 2.8
const SPIKE_CD := 6.0
const BOULDER_CD := 3.6
const BREATH_N := 5
const ICE_V := 470.0
const GUARD_HITS := 3
const GUARD_WIN := 5.0
const GUARD_T := 4.5

var guards := 0              # לבדיקות
var blocked := 0
var spike_waves := 0
var _breath_cd := 1.5
var _spike_cd := 4.0
var _boulder_cd := 2.5
var _guard_t := 0.0
var _heart_hits := []        # זמני הפגיעות האחרונות בלב
var _clock := 0.0


func stats() -> Dictionary:
	return {"name": "ICE TITAN", "hp": 300, "walk": 0.0, "chase": 0.0, "damage": 2, "bite_delay": 1.0, "scale": 3.0, "width": 1.7,
		"duck": 0.0, "cover": 0.0, "skin": Color("a8c4d8"), "shirt": Color("6a9ac0"), "pants": Color("3a5a7a"), "shoe": Color("2a3a4a"),
		"points": 2000, "boss": true, "boss_name": "THE ICE TITAN - SHOOT THE FROZEN HEART"}


func eye() -> Vector2:   # הפה
	return z.global_position + Vector2(z._dir * 12.0 * z.wf, -65.0) * z.sc


func hand() -> Vector2:
	return z.global_position + Vector2(z._dir * 4.0 * z.wf, -82.0) * z.sc


func weak_rect() -> Rect2:
	return Rect2(-4, -45, 14, 14)


func guarding() -> bool:
	return _guard_t > 0.0 and winding == ""


func damage_mult(zone: String, src: Dictionary) -> float:
	var m := super.damage_mult(zone, src)
	var s := str(src.get("source", "bullet"))
	if (s == "bullet" or s == "melee") and in_weak(_last_hit):
		if guarding():   # היד מכסה את הלב
			blocked += 1
			Sfx.play("it_block", _last_hit, -4.0, 0.1, 3)
			Particles.burst(z.get_parent(), _last_hit, "spark", Vector2.UP, 4)
			return ARMOR_MULT * 0.4
		_heart_hits.append(_clock)
		while _heart_hits.size() > 0 and _clock - float(_heart_hits[0]) > GUARD_WIN:
			_heart_hits.pop_front()
		if _heart_hits.size() >= GUARD_HITS and _guard_t <= 0.0:
			_heart_hits.clear()
			_guard_t = GUARD_T
			guards += 1
			z._popup("IT LEARNED - GUARDS ITS HEART", Color("a0e0ff"), 15, -60.0 - 90.0 * z.sc)
		return m * 1.5   # הלב בגובה החזה (לא ראש) - מפצים
	return m


func think(pl: Node, delta: float) -> void:
	_clock += delta
	_breath_cd -= delta
	_spike_cd -= delta
	_boulder_cd -= delta
	_guard_t -= delta
	var dx: float = absf(pl.global_position.x - z.global_position.x)
	if dx > 1150.0:
		return
	var on_ground: bool = absf(pl.global_position.y - z.global_position.y) < 40.0
	if learned_lob and _boulder_cd <= 0.0 and (not _vis or randf() < 0.4):
		wind("boulder", 0.8)
		return
	if _spike_cd <= 0.0 and on_ground and dx > 160.0:
		wind("spikes", 0.9)
		return
	if _boulder_cd <= 0.0 and randf() < 0.5:
		wind("boulder", 0.8)
		return
	if _breath_cd <= 0.0:
		wind("breath", 0.7)


func wind(name: String, t: float) -> void:
	super.wind(name, t)
	if name == "spikes" or name == "boulder":
		Sfx.play("it_roar", eye(), 0.0, 0.05, 2)


func attack(name: String, pl: Node) -> void:
	match name:
		"pound":
			do_pound(pl)
		"breath":
			_breath_cd = BREATH_CD
			Sfx.play("it_breath", eye(), 2.0, 0.05, 2)
			Particles.burst(z.get_parent(), eye(), "snow", Vector2(z._dir, 0), 10)
			var base: float = (aim_point(pl, ICE_V) - eye()).angle()
			for q in BREATH_N:
				var a: float = base + (float(q) - float(BREATH_N - 1) * 0.5) * 0.07
				fire_shot(eye(), eye() + Vector2.from_angle(a) * 100.0, ICE_V * randf_range(0.9, 1.1), 1, "bolt", Color(0.75, 0.92, 1.0), 6.0)
		"spikes":
			_spike_cd = SPIKE_CD
			spike_waves += 1
			do_slam()
			var w := IceSpikes.new()
			w.owner_t = self
			w.dir = z._dir
			z.get_parent().add_child(w)
			w.global_position = z.global_position + Vector2(z._dir * 30.0 * z.sc, 0.0)
		"boulder":
			_boulder_cd = BOULDER_CD
			var n := 3 if learned_lob and not _vis else 1
			for q in n:
				var tx: float = pl.global_position.x + (float(q) - float(n - 1) * 0.5) * 80.0 + pl.velocity.x * 0.35 * lead
				fire_lob(hand(), Vector2(tx, pl.global_position.y), 1.15 + 0.1 * float(q), 1, "ice", 80.0, Color(0.7, 0.9, 1.0), 13.0)


func do_slam() -> void:
	Sfx.play("explosion", z.global_position, -6.0, 0.1, 2)
	Particles.burst(z.get_parent(), z.global_position + Vector2(z._dir * 30.0 * z.sc, 0), "snow", Vector2.UP, 16)
	var cam: Camera2D = z.get_viewport().get_camera_2d()
	if cam != null and cam.has_method("shake"):
		cam.shake(8.0, 0.3)


# ============================================================
#  גל קוצי קרח: סדק שרץ על הקרקע (V), ומאחוריו קוצים שעולים (RISE) ונשארים רגע (STAY).
#  פוגע בשחקן פעם אחת אם הוא על הקרקע מעל קוץ. גם זומבים נפגעים.
# ============================================================
class IceSpikes extends Node2D:
	const V := 540.0
	const LEN := 950.0
	const STEP := 24.0
	const RISE := 0.22
	const STAY := 0.55
	var owner_t = null
	var dir := 1.0
	var _front := 0.0
	var _t := 0.0
	var _spikes := []         # [x, born]
	var _hit := false

	func _ready() -> void:
		z_index = 3
		add_to_group("hazards")

	func world_rect() -> Rect2:
		var a := global_position.x + minf(0.0, dir * _front)
		return Rect2(Vector2(a, global_position.y - 60.0), Vector2(_front + 40.0, 60.0))

	func danger_at(p: Vector2, margin := 0.0) -> bool:
		return world_rect().grow(margin).has_point(p)

	func _physics_process(delta: float) -> void:
		_t += delta
		if _front < LEN:
			var nf := _front + V * delta
			while float(_spikes.size()) * STEP < nf:
				var sx := float(_spikes.size()) * STEP
				_spikes.append([sx, _t])
				if _spikes.size() % 3 == 0:
					preload("res://sfx.gd").play("it_spike", global_position + Vector2(dir * sx, 0), -6.0, 0.2, 3)
				var q := PhysicsRayQueryParameters2D.create(global_position + Vector2(dir * sx, -40.0), global_position + Vector2(dir * (sx + STEP), -40.0), 1)
				if not get_world_2d().direct_space_state.intersect_ray(q).is_empty():   # קיר / מכשול עוצר את הגל
					nf = LEN
					break
			_front = nf
		var pl := get_tree().get_first_node_in_group("player")
		for s in _spikes:
			var age: float = _t - float(s[1])
			if age < RISE * 0.5 or age > RISE + STAY:
				continue
			var wx: float = global_position.x + dir * float(s[0])
			if not _hit and pl != null and not pl.dead and absf(pl.global_position.x - wx) < STEP * 0.6 and pl.global_position.y > global_position.y - 30.0 and pl.global_position.y < global_position.y + 6.0:
				_hit = true
				pl.hurt(1, Vector2(dir * 0.6, -1.4))
				pl.velocity.y = -360.0
			if int(age * 60.0) % 10 == 0:
				for zz in get_tree().get_nodes_in_group("zombies"):
					if not zz.dead and not zz.is_boss() and absf(zz.global_position.x - wx) < STEP * 0.5 and absf(zz.global_position.y - global_position.y) < 20.0:
						zz.take_damage(10, zz.global_position + Vector2(0, -20), Vector2(0, -1), false, {"source": "ice", "fixed": 10})
		if _front >= LEN and _spikes.size() > 0 and _t - float(_spikes[_spikes.size() - 1][1]) > RISE + STAY + 0.4:
			queue_free()
			return
		queue_redraw()

	func _draw() -> void:
		for s in _spikes:
			var age: float = _t - float(s[1])
			var x: float = dir * float(s[0])
			if age < RISE + STAY + 0.4:   # הסדק
				DrawBatch.line(self, Vector2(x - 6, -1), Vector2(x + 6, 1), Color(0.3, 0.55, 0.85, 0.7), 2.0)
			var k := 0.0
			if age < RISE:
				k = age / RISE
			elif age < RISE + STAY:
				k = 1.0
			elif age < RISE + STAY + 0.4:
				k = 1.0 - (age - RISE - STAY) / 0.4
			if k <= 0.0:
				continue
			var h := (34.0 + fposmod(float(s[0]) * 0.37, 1.0) * 22.0) * k
			var p := PackedVector2Array([Vector2(x - 9, 0), Vector2(x + 2, -h), Vector2(x + 9, 0)])
			DrawBatch.colored_polygon(self, p, Color(0.75, 0.9, 1.0, 0.95))
			DrawBatch.colored_polygon(self, PackedVector2Array([Vector2(x + 2, -h), Vector2(x + 9, 0), Vector2(x + 3, 0)]), Color(0.45, 0.7, 0.92, 0.95))
			DrawBatch.line(self, Vector2(x - 4, -2), Vector2(x + 1, -h * 0.85), Color(1, 1, 1, 0.7), 1.2)


# ============================================================
#  ציור: גבעת קרח שמכסה את הרגליים, גוף ענק כחול-אפור עם כפור, כלוב צלעות קרח עם לב כחול פועם,
#  ראש גולגולת עם כתר נטיפים ועיניים כחולות, ידיים ענקיות (אחת מכסה את הלב כשהוא "שומר")
# ============================================================
func draw() -> bool:
	begin_draw()
	var sk := col(z.skin)
	var k := wind_k()
	var hip := Vector2(0, -18)
	var sh := Vector2(2, -52)
	var head := sh + Vector2(6, -17)
	var heart := Vector2(3, -38)
	# יד אחורית (נשענת על הקרח)
	z._arm(sh + Vector2(-8, 2), Vector2(-20, -12), Art.shade(sk, 0.3), Art.shade(sk, 0.25))
	# גו
	var torso := PackedVector2Array([sh + Vector2(-15, -3), sh + Vector2(-4, -8), sh + Vector2(14, -5), sh + Vector2(18, 4), hip + Vector2(14, 2), hip + Vector2(-14, 2)])
	DrawBatch.rect(z, Rect2(sh + Vector2(1, -10), Vector2(9, 6)), Art.shade(sk, 0.2))   # צוואר
	Art.fill_shaded(z, torso, sk, 0.2, 0.45)
	for q in 5:   # כפור / גבישים על העור
		DrawBatch.colored_polygon(z, PackedVector2Array([sh + Vector2(-12.0 + float(q) * 5.0, 4.0 + float(q % 2) * 10.0), sh + Vector2(-10.0 + float(q) * 5.0, 1.0 + float(q % 2) * 10.0), sh + Vector2(-8.0 + float(q) * 5.0, 5.0 + float(q % 2) * 10.0)]), Color(0.9, 0.97, 1.0, 0.8))
	# הלב (מתחת לצלעות)
	if not z.dead:
		var pulse := 0.6 + 0.4 * sin(z._time * (5.0 + 6.0 * k))
		Art.glow(z, heart, 14.0 + 6.0 * pulse, Color(0.3, 0.7, 1.0, 0.35 * pulse))
		DrawBatch.colored_polygon(z, PackedVector2Array([heart + Vector2(0, 5), heart + Vector2(-5, -1), heart + Vector2(-3, -5), heart + Vector2(0, -3), heart + Vector2(3, -5), heart + Vector2(5, -1)]), Color(0.45, 0.8, 1.0).lightened(0.3 * pulse))
	for q in 4:   # צלעות קרח
		var yy := -46.0 + float(q) * 4.5
		DrawBatch.line(z, Vector2(-10, yy), Vector2(-3, yy - 1.5), Color(0.85, 0.95, 1.0, 0.9), 2.0)
		DrawBatch.line(z, Vector2(9, yy - 1.5), Vector2(16, yy), Color(0.85, 0.95, 1.0, 0.9), 2.0)
	DrawBatch.line(z, Vector2(3, -49), Vector2(3, -30), Color(0.85, 0.95, 1.0, 0.7), 1.5)   # עצם החזה
	# ראש גולגולת + כתר נטיפים
	Art.oval_shaded(z, head, 8.0, 8.5, col(Color("d8e4ec")), 0.0)
	DrawBatch.rect(z, Rect2(head + Vector2(-4, 5), Vector2(11, 6)), col(Color("d8e4ec")))   # לסת
	var jaw := 3.0 * k if winding == "breath" else 0.0
	for q in 4:
		DrawBatch.line(z, head + Vector2(-3.0 + float(q) * 3.0, 6.0 + jaw), head + Vector2(-3.0 + float(q) * 3.0, 9.0 + jaw), col(Color("7a8a9a")), 1.0)
	if not z.dead:
		for e in [Vector2(-1, -1), Vector2(5, -1)]:
			DrawBatch.colored_polygon(z, Art.ellipse(head + e, 2.4, 2.8, 0.0, 8), Color("10202e"))
			DrawBatch.circle(z, head + e, 1.2, Color(0.5, 0.9, 1.0))
	DrawBatch.colored_polygon(z, PackedVector2Array([head + Vector2(2, 3), head + Vector2(4, 3), head + Vector2(3, 0)]), Color("10202e"))
	for q in 5:   # כתר נטיפים
		var cx := -7.0 + float(q) * 3.6
		var hh := 6.0 + float((q * 7) % 5) * 1.6
		DrawBatch.colored_polygon(z, PackedVector2Array([head + Vector2(cx - 1.6, -6.5), head + Vector2(cx + 0.4, -6.5 - hh), head + Vector2(cx + 1.8, -6.5)]), Color(0.8, 0.94, 1.0, 0.95))
	if winding == "breath" and not z.dead:   # אדי כפור מהפה
		Art.glow(z, head + Vector2(10, 7), 6.0 + 8.0 * k, Color(0.85, 0.95, 1.0, 0.5 * k))
	# יד קדמית: מכסה את הלב / מורמת לזריקה / אגרופים למטה למכה
	var hf := sh + Vector2(18, 16)
	if winding == "boulder":
		hf = sh + Vector2(2, -30)
	elif winding == "spikes":
		hf = sh + Vector2(20, -20).lerp(Vector2(22, 34), k)
	elif guarding():
		hf = heart + Vector2(2, 0)
	z._arm(sh + Vector2(13, 3), hf, sk, Art.shade(sk, 0.1))
	DrawBatch.circle(z, hf, 5.0, sk)
	if guarding() and not z.dead:
		DrawBatch.circle(z, hf, 5.0, Color(0.85, 0.95, 1.0, 0.35))
	if winding == "boulder":   # גוש קרח ביד
		var bp := hf + Vector2(0, -6)
		var pts := PackedVector2Array()
		for q in 7:
			pts.append(bp + Vector2.from_angle(float(q) * TAU / 7.0) * (5.0 + float(q % 2) * 1.5) * (0.5 + 0.5 * k))
		DrawBatch.colored_polygon(z, pts, Color(0.78, 0.92, 1.0))
	# גבעת הקרח שקוברת אותו עד המותניים
	var mound := PackedVector2Array([Vector2(-34, 0), Vector2(-28, -12), Vector2(-16, -20), Vector2(-2, -16), Vector2(12, -21), Vector2(26, -13), Vector2(34, 0)])
	Art.fill_shaded(z, mound, col(Color("8cc4e8")), 0.25, 0.4, Art.OUTLINE, 1.2)
	DrawBatch.colored_polygon(z, PackedVector2Array([Vector2(-28, -12), Vector2(-16, -20), Vector2(-2, -16), Vector2(12, -21), Vector2(26, -13), Vector2(12, -17), Vector2(-2, -13), Vector2(-16, -17)]), Color("f0f6fc"))
	for q in 3:
		DrawBatch.line(z, Vector2(-22.0 + float(q) * 18.0, -10), Vector2(-18.0 + float(q) * 18.0, -2), Color(1, 1, 1, 0.4), 1.2)
	end_draw()
	return true
