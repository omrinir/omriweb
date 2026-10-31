extends "res://enemies/zombie_type.gd"
# ============================================================
#  OFFICE (שלב 38, "MEGACITY CORE") - איש משרד זומבי: חליפה קרועה, עניבה, תג עובד, תיק מסמכים וסמארטפון.
#  "THEY LEARNED TO USE OUR PHONES": מחכה לרגע שאתה עסוק (טוען / זומבי אחר צמוד אליך / רחוק ממנו) ->
#    מוציא טלפון ומתקשר (CALL_T, צלצול + אייקון). השיחה הצליחה -> BACKUP: שני רצים מגיעים מאחוריך.
#    כל פגיעה בזמן השיחה = הטלפון נופל (השיחה נקטעת). עד MAX_CALLS שיחות. קרוב - מכה עם התיק.
#  לשנות: CALL_T, CALL_CD, MAX_CALLS, BACKUP_N.
# ============================================================

const SOUNDS := {
	"of_ring": [["Q", 1400, 1400, 0.0, 0.12, 0.0, 30.0, 0.15, 1.0, 0], ["Q", 1700, 1700, 0.13, 0.12, 0.0, 30.0, 0.15, 1.0, 0], ["Q", 1400, 1400, 0.4, 0.12, 0.0, 30.0, 0.15, 1.0, 0], ["Q", 1700, 1700, 0.53, 0.12, 0.0, 30.0, 0.15, 1.0, 0]],
	"of_drop": [["C", 0, 0, 0.0, 0.05, 0.0, 50.0, 0.5, 1.0, 0], ["S", 900, 300, 0.0, 0.15, 0.0, 20.0, 0.2, 1.0, 0]],
}

const CALL_T := 2.2
const CALL_CD := 5.0
const MAX_CALLS := 2
const BACKUP_N := 2

enum { WALK, CALL }
var state := WALK
var calls := 0               # לבדיקות
var cut_calls := 0
var _st := 0.0
var _cd := 2.0


func stats() -> Dictionary:
	return {"name": "OFFICE", "hp": 30, "walk": 42.0, "chase": 76.0, "damage": 1, "bite_delay": 0.8, "scale": 1.0, "width": 1.0,
		"duck": 0.3, "cover": 0.4, "skin": Color("8a9480"), "shirt": Color("2a2e3a"), "pants": Color("2a2e3a"), "shoe": Color("141418"), "points": 450}


func brain_overrides() -> Dictionary:
	return {"aggression": 0.4}


func can_bite() -> bool:
	return state == WALK


func on_damage(_amount: int, _hit_pos: Vector2, _dir: Vector2, _src: Dictionary) -> bool:
	if state == CALL:   # הטלפון נופל
		state = WALK
		cut_calls += 1
		_cd = CALL_CD
		Sfx.play("of_drop", z.global_position, -2.0, 0.1, 2)
		z._popup("CALL DROPPED", Color("c0e0ff"), 12, -80.0)
	return true


func _busy(pl: Node) -> bool:   # האם אתה עסוק עכשיו?
	if pl.is_reloading():
		return true
	if absf(pl.global_position.x - z.global_position.x) > 380.0:
		return true
	for o in z.get_tree().get_nodes_in_group("zombies"):
		if o != z and not o.dead and o.global_position.distance_to(pl.global_position) < 160.0:
			return true
	return false


func physics(pl: Node, delta: float) -> bool:
	_st -= delta
	_cd -= delta
	if z.dead or pl == null or pl.dead:
		return false
	match state:
		WALK:
			if calls < MAX_CALLS and _cd <= 0.0 and absf(pl.global_position.x - z.global_position.x) < 650.0 and absf(pl.global_position.y - z.global_position.y) < 120.0 and _busy(pl):
				state = CALL
				_st = CALL_T
				Sfx.play("of_ring", z.global_position, -2.0, 0.05, 2)
				return _stay(delta)
			return false
		CALL:
			if Engine.get_physics_frames() % 40 == 0:
				Sfx.play("of_ring", z.global_position, -6.0, 0.05, 2)
			if _st <= 0.0:
				state = WALK
				_cd = CALL_CD
				_backup(pl)
			return _stay(delta)
	return false


func _stay(delta: float) -> bool:
	z.velocity.x = move_toward(z.velocity.x, 0.0, 800.0 * delta)
	if not z.is_on_floor():
		z.velocity.y += z.gravity * delta
	z.move_and_slide()
	return true


func _backup(pl: Node) -> void:
	calls += 1
	z._popup("BACKUP CALLED", Color("ff8060"), 14, -80.0)
	pl._say("HE CALLED FRIENDS...", Color("ff8060"))
	var main: Node = z.get_parent()
	var side := signf(pl.global_position.x - z.global_position.x)   # מאחוריך
	if side == 0.0:
		side = 1.0
	var half: float = z.get_viewport_rect().size.x * 0.5 / 1.25
	for q in BACKUP_N:
		var x: float = clampf(pl.global_position.x + side * (half + 40.0 + float(q) * 50.0), 60.0, float(z.world_w) - 300.0)
		var nz: Node = main._spawn_zombie(x, pl.global_position.y if pl.is_on_floor() else z.global_position.y, 1)
		if nz != null:
			nz._alert_t = 8.0
			nz._rush_t = 2.0


# ============================================================
#  ציור: חליפה כהה, חולצה לבנה ועניבה אדומה רפויה, תג עובד, תיק מסמכים; בשיחה: טלפון זוהר באוזן + גלי צלצול
# ============================================================
func draw() -> bool:
	begin_draw()
	var sk := col(z.skin)
	var suit := col(z.shirt)
	var p: float = z._walk_phase
	var f: Array = feet(4.5, 2.5)
	var hip := Vector2(0, -22)
	var sh := Vector2(1, -37)
	var head := sh + Vector2(3.5, -8)
	z._leg(hip + Vector2(-2, 0), f[1], col(Art.shade(z.pants, 0.25)), sk, col(z.shoe))
	z._leg(hip + Vector2(2, 0), f[0], col(z.pants), sk, col(z.shoe))
	var hb := sh + Vector2(-5.0 - sin(p) * 2.0, 15.0)
	z._arm(sh + Vector2(-3, 1), hb, Art.shade(sk, 0.25), Art.shade(suit, 0.3))
	DrawBatch.rect(z, Rect2(hb + Vector2(-6, 0), Vector2(10, 8)), col(Color("5a3a22")))   # תיק
	DrawBatch.line(z, hb + Vector2(-2, 0), hb + Vector2(2, 0), col(Color("c8a060")), 1.2)
	Art.fill_shaded(z, PackedVector2Array([sh + Vector2(-8, -1), sh + Vector2(8, 0), hip + Vector2(7, 3), hip + Vector2(-7, 3)]), suit, 0.12, 0.4)
	DrawBatch.colored_polygon(z, PackedVector2Array([sh + Vector2(-1, -1), sh + Vector2(4, -1), sh + Vector2(2, 8)]), col(Color("e8e8e0")))   # חולצה
	DrawBatch.line(z, sh + Vector2(1.5, 0), sh + Vector2(3, 12), col(Color("b02020")), 2.0)   # עניבה
	DrawBatch.rect(z, Rect2(sh + Vector2(-6, 6), Vector2(4, 5)), col(Color("e0e0e0")))   # תג עובד
	Art.oval_shaded(z, head, 5.2, 5.8, sk, 0.0)
	face(head, Vector2(3.0, -0.5))
	DrawBatch.colored_polygon(z, Art.ellipse(head + Vector2(-0.5, -3.5), 5.0, 2.6, 0.0, 10), col(Color("2a2420")))   # שיער מסורק
	if not z.dead:
		DrawBatch.circle(z, head + Vector2(3.0, -0.5), 1.1, Color(1.0, 0.85, 0.4))
	var hf := head + Vector2(3, 2) if state == CALL else sh + Vector2(11, 7)
	z._arm(sh + Vector2(3, 1), hf, sk, suit)
	if state == CALL and not z.dead:   # הטלפון
		DrawBatch.rect(z, Rect2(hf + Vector2(-1, -5), Vector2(3, 7)), Color("1a1a1a"))
		Art.glow(z, hf, 6.0, Color(0.5, 0.8, 1.0, 0.5))
		var k := fposmod(z._time * 2.0, 1.0)
		for q in 2:
			DrawBatch.arc(z, hf + Vector2(4, -2), 4.0 + (k + float(q) * 0.5) * 8.0, -0.8, 0.8, 6, Color(0.6, 0.9, 1.0, 0.7 * (1.0 - k)), 1.2)
	end_draw()
	return true
