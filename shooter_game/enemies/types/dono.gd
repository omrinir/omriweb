extends "res://enemies/stationary_boss.gd"
# ============================================================
#  O DONO DO MORRO (הבוס של שלב 37, "FAVELA HEIGHTS") - בוס נייח: "בעל הגבעה". ענק בגופייה, שרשראות זהב,
#  משקפי שמש וכובע, עומד על הגג (לאז'ה) של הבית הכי גבוה מאחורי מעקה לבנים. רובה ביד ותיק רוג'אוס (זיקוקים).
#  התקפות (stationary_boss.gd):
#    burst  - צרור של BURST_N כדורים מהרובה (מקדים אותך אחרי פספוסים)
#    rojao  - 3 זיקוקים לשמיים שנוחתים עליך ומתפוצצים (מעל המחסה כשלמד שאתה מתחבא)
#    pound  - עלית אליו לגג: בעיטה שזורקת אותך
#  "THEY LEARN": DUCK_HITS פגיעות בראש תוך DUCK_WIN שניות -> מתכופף מאחורי המעקה (DUCK_T, לא פגיע) ויורה זיקוקים
#    "בעיוורון". כשהוא קם - יורה מיד צרור למקום האחרון שבו ראה אותך. ירי מהגג (מקרוב) עוקף את המעקה.
#  לשנות: BURST_CD, ROJAO_CD, BURST_N, DUCK_HITS, DUCK_WIN, DUCK_T.
# ============================================================

const SOUNDS := {
	"dn_ak": [["N", 0, 0, 0.0, 0.08, 0.0, 30.0, 0.7, 0.7, 0, 0.4], ["S", 180, 80, 0.0, 0.06, 0.0, 40.0, 0.4, 1.0, 0]],
	"dn_rojao": [["N", 0, 0, 0.0, 0.5, 0.0, 4.0, 0.35, 0.8, 0, 0.7], ["S", 600, 2200, 0.0, 0.5, 0.0, 4.0, 0.12, 1.0, 0]],
	"dn_laugh": {"drive": 1.4, "layers": [["V", 110, 100, 0.0, 0.18, 0.02, 10.0, 0.5, 1.0, 0.03, 0, [500, 1100, 4]], ["V", 105, 95, 0.25, 0.18, 0.02, 10.0, 0.5, 1.0, 0.03, 0, [500, 1100, 4]], ["V", 100, 90, 0.5, 0.2, 0.02, 9.0, 0.5, 1.0, 0.03, 0, [500, 1100, 4]]]},
}

const BURST_CD := 2.6
const ROJAO_CD := 4.5
const BURST_N := 5
const BULLET_V := 720.0
const DUCK_HITS := 3
const DUCK_WIN := 5.0
const DUCK_T := 2.6

var ducks := 0               # לבדיקות
var _burst_cd := 1.5
var _rojao_cd := 3.0
var _left := 0
var _rate := 0.0
var _duck := 0.0
var _head_hits := []
var _clock := 0.0
var _last_seen := Vector2.ZERO


func stats() -> Dictionary:
	return {"name": "O DONO", "hp": 360, "walk": 0.0, "chase": 0.0, "damage": 2, "bite_delay": 1.0, "scale": 2.5, "width": 1.5,
		"duck": 0.0, "cover": 0.0, "skin": Color("7a8a6a"), "shirt": Color("f0f0e8"), "pants": Color("2a3a6a"), "shoe": Color("e0e0e0"),
		"points": 2200, "boss": true, "boss_name": "O DONO DO MORRO - SHOOT HIM WHEN HE STANDS UP"}


func eye() -> Vector2:   # קנה הרובה
	return z.global_position + Vector2(z._dir * 22.0 * z.wf, -40.0) * z.sc


func weak_rect() -> Rect2:
	return Rect2(-2, -66, 16, 16)


func ducking() -> bool:
	return _duck > 0.0


func on_damage(amount: int, hit_pos: Vector2, dir: Vector2, src: Dictionary) -> bool:
	if ducking():   # מאחורי המעקה - רק מקרוב / פיצוץ
		var pl := player()
		var close: bool = pl != null and absf(pl.global_position.y - z.global_position.y) < 40.0
		var s := str(src.get("source", "bullet"))
		if not close and (s == "bullet" or s == "melee"):
			Particles.burst(z.get_parent(), hit_pos, "smoke", Vector2.UP, 2)
			return false
	return super.on_damage(amount, hit_pos, dir, src)


func damage_mult(zone: String, src: Dictionary) -> float:
	var m := super.damage_mult(zone, src)
	var s := str(src.get("source", "bullet"))
	if (s == "bullet" or s == "melee") and in_weak(_last_hit) and not ducking():
		_head_hits.append(_clock)
		while _head_hits.size() > 0 and _clock - float(_head_hits[0]) > DUCK_WIN:
			_head_hits.pop_front()
		if _head_hits.size() >= DUCK_HITS:
			_head_hits.clear()
			_duck_down.call_deferred()
	return m


func _duck_down() -> void:
	if z == null or not is_instance_valid(z) or z.dead or ducking():
		return
	_duck = DUCK_T
	ducks += 1
	winding = ""
	_seq_reset()
	z._popup("IT LEARNED - HE DUCKS", Color("ffd070"), 15, -60.0 - 70.0 * z.sc)


func _seq_reset() -> void:
	_left = 0


func think(pl: Node, delta: float) -> void:
	_clock += delta
	_burst_cd -= delta
	_rojao_cd -= delta
	_rate -= delta
	if _vis:
		_last_seen = pl.global_position
	if _duck > 0.0:   # מתכופף: זורק זיקוקים בעיוורון, ובסוף קם ויורה
		_duck -= delta
		if _rojao_cd <= 0.0:
			_rojao_cd = ROJAO_CD * 0.6
			_rojao(_last_seen, 2)
		if _duck <= 0.0:
			_burst_cd = 0.0
			Sfx.play("dn_laugh", z.global_position, 2.0, 0.05, 2)
		return
	if _left > 0:   # צרור באמצע
		if _rate <= 0.0:
			_left -= 1
			_rate = 0.11
			fire_shot(eye(), aim_point(pl, BULLET_V) + Vector2(randf_range(-10, 10), randf_range(-8, 8)), BULLET_V, 1, "bolt", Color(1.0, 0.85, 0.3), 5.0)
			Sfx.play("dn_ak", eye(), -2.0, 0.1, 4)
		return
	var dx: float = absf(pl.global_position.x - z.global_position.x)
	if dx > 1200.0:
		return
	if _rojao_cd <= 0.0 and (learned_lob or randf() < 0.35):
		wind("rojao", 0.7)
		return
	if _burst_cd <= 0.0:
		wind("burst", 0.5)


func attack(name: String, pl: Node) -> void:
	match name:
		"pound":
			do_pound(pl)
		"burst":
			_burst_cd = BURST_CD
			_left = BURST_N
			_rate = 0.0
		"rojao":
			_rojao_cd = ROJAO_CD
			_rojao(pl.global_position + Vector2(pl.velocity.x * 0.4 * lead, 0.0), 3)


func _rojao(at: Vector2, n: int) -> void:
	Sfx.play("dn_rojao", z.global_position, 0.0, 0.05, 2)
	for q in n:
		var tx: float = at.x + (float(q) - float(n - 1) * 0.5) * 90.0
		fire_lob(z.global_position + Vector2(z._dir * -10.0, -60.0) * z.sc, Vector2(tx, at.y), 1.35 + 0.12 * float(q), 1, "rocket", 60.0, Color(1.0, 0.5, 0.2), 7.0)


# ============================================================
#  ציור: גופייה לבנה, שרשראות זהב, כובע מצחייה ומשקפי שמש, רובה, תיק זיקוקים על הגב,
#  ומעקה לבנים לפניו (מתכופף = רק הכובע מבצבץ)
# ============================================================
func draw() -> bool:
	begin_draw()
	var sk := col(z.skin)
	var k := wind_k()
	var down := 0.0   # 0 = עומד, 1 = מתכופף מאחורי המעקה (מעבר מהיר)
	if _duck > 0.0:
		down = clampf(minf(_duck, DUCK_T - _duck) / 0.2, 0.0, 1.0)
	var dy := 36.0 * down
	var hip := Vector2(0, -24 + dy)
	var sh := Vector2(2, -48 + dy)
	var head := sh + Vector2(5, -10)
	var gold := Color("e0b030")
	# תיק זיקוקים
	DrawBatch.rect(z, Rect2(sh + Vector2(-16, -2), Vector2(9, 20)), col(Color("3a3a3a")))
	for q in 4:
		DrawBatch.line(z, sh + Vector2(-14.0 + float(q) * 2.0, -2), sh + Vector2(-15.0 + float(q) * 2.5, -12), col(Color("c8a060")), 1.2)
		DrawBatch.circle(z, sh + Vector2(-15.0 + float(q) * 2.5, -12), 1.2, col(Color("d03020")))
	z._arm(sh + Vector2(-6, 2), sh + Vector2(-9, 18), Art.shade(sk, 0.25), Art.shade(sk, 0.25))
	Art.fill_shaded(z, PackedVector2Array([sh + Vector2(-11, -2), sh + Vector2(11, -1), hip + Vector2(10, 3), hip + Vector2(-10, 3)]), col(z.shirt), 0.12, 0.4)   # גופייה
	DrawBatch.rect(z, Rect2(sh + Vector2(-11, -2), Vector2(4, 8)), sk)   # כתפיים חשופות
	DrawBatch.rect(z, Rect2(sh + Vector2(7, -1), Vector2(4, 8)), sk)
	for q in 3:   # שרשראות זהב
		DrawBatch.arc(z, sh + Vector2(1, 0), 5.0 + float(q) * 2.5, 0.3, PI - 0.3, 10, col(gold), 1.3)
	DrawBatch.circle(z, sh + Vector2(1, 9), 2.5, col(gold))   # מדליון
	Art.oval_shaded(z, head, 6.0, 6.5, sk, 0.0)
	DrawBatch.colored_polygon(z, Art.ellipse(head + Vector2(0, -4), 6.6, 3.4, 0.0, 12), col(Color("1a1a1a")))   # כובע
	DrawBatch.rect(z, Rect2(head + Vector2(2, -4), Vector2(9, 2)), col(Color("1a1a1a")))   # מצחייה
	DrawBatch.rect(z, Rect2(head + Vector2(0, -1.5), Vector2(8, 3)), col(Color("101010")))   # משקפי שמש
	DrawBatch.line(z, head + Vector2(0, -0.5), head + Vector2(8, -1.5), Color(1, 1, 1, 0.4), 1.0)
	DrawBatch.line(z, head + Vector2(2, 4), head + Vector2(6, 4.5), col(Color("2a1a10")), 1.4)
	# רובה
	var hf := sh + Vector2(16, 6) if winding != "rojao" else sh + Vector2(4, -16)
	var aim_up := 0.0 if winding != "burst" else -2.0 * k
	z._arm(sh + Vector2(8, 2), hf, sk, sk)
	DrawBatch.line(z, hf + Vector2(-8, 1), hf + Vector2(12, aim_up), col(Color("2a2a2a")), 3.0)   # קנה
	DrawBatch.rect(z, Rect2(hf + Vector2(-2, 1), Vector2(4, 6)), col(Color("4a3a2a")))   # מחסנית מעוקלת
	if _left > 0 and not z.dead:
		Art.glow(z, hf + Vector2(14, aim_up), 6.0, Color(1.0, 0.8, 0.3, 0.7))
	if winding == "rojao":   # זיקוק ביד
		DrawBatch.line(z, hf, hf + Vector2(0, -12), col(Color("c8a060")), 1.5)
		DrawBatch.circle(z, hf + Vector2(0, -13), 2.0, Color(1.0, 0.6, 0.2))
	# מעקה לבנים לפניו (על הגג)
	var wall := PackedVector2Array([Vector2(-20, 0), Vector2(20, 0), Vector2(20, -24), Vector2(-20, -24)])
	Art.fill_shaded(z, wall, col(Color("a0522d")), 0.15, 0.35, Art.OUTLINE, 1.0)
	for q in 3:
		DrawBatch.line(z, Vector2(-20, -6.0 - float(q) * 6.0), Vector2(20, -6.0 - float(q) * 6.0), col(Color("6a3a20")), 1.0)
		for b in 4:
			var bx := -20.0 + float(b) * 10.0 + (5.0 if q % 2 == 1 else 0.0)
			DrawBatch.line(z, Vector2(bx, -6.0 - float(q) * 6.0), Vector2(bx, -12.0 - float(q) * 6.0), col(Color("6a3a20")), 1.0)
	end_draw()
	return true
