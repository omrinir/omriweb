extends "res://enemies/zombie_type.gd"
# ============================================================
#  MORTARMAN (משלב 44, "THE DAM") - צוות מרגמה של אימפריית המתים: קסדה, צינור מרגמה על הגב, תיק פצצות.
#  שומר מרחק (KEEP) ומתמקם (SETUP_T - פגיע, לא זז). מוצב: יורה פצצה בקשת גבוהה (שריקה + צל על הקרקע) כל FIRE_CD.
#    מתקרבים אליו (PACK_R)? מקפל ובורח.
#  "THEY LEARN YOUR HIDING SPOTS - TOGETHER": כל מחסה שהתכופפת מאחוריו יותר מ-HIDE_T נרשם (main meta "known_covers").
#    כשאתה ליד מחסה רשום - כל צוותי המרגמה כבר "מכוונים" אליו: יורים מיד ובזמן טיסה קצר (FAST_FLIGHT).
#  לשנות: KEEP, SETUP_T, FIRE_CD, FLIGHT, FAST_FLIGHT, BLAST, PACK_R, HIDE_T.
# ============================================================

const E := preload("res://enemies/empire_kit.gd")
const SB := preload("res://enemies/stationary_boss.gd")

const SOUNDS := {
	"mo_thump": [["S", 120, 60, 0.0, 0.2, 0.0, 15.0, 0.6, 1.0, 0], ["N", 0, 0, 0.0, 0.15, 0.0, 20.0, 0.3, 0.3, 0, 0.5]],
	"mo_whistle": [["S", 1600, 700, 0.0, 1.2, 0.0, 1.5, 0.12, 1.0, 0.01]],
}

const KEEP := 420.0
const RANGE := 900.0
const SETUP_T := 1.0
const FIRE_CD := 3.6
const FLIGHT := 1.7
const FAST_FLIGHT := 0.9
const BLAST := 75.0
const PACK_R := 230.0
const HIDE_T := 1.0

enum { MOVE, SETUP, SET }
var state := MOVE
var fired := 0               # לבדיקות
var fast := 0
var _st := 0.0
var _cd := 1.0
var _hide := 0.0


class MTracker extends RefCounted:   # (ל-Lob - בלי למידה של הרובאים)
	var z: Node = null
	func shot_result(_hit: bool) -> void:
		pass


func stats() -> Dictionary:
	return {"name": "MORTARMAN", "hp": 30, "walk": 40.0, "chase": 70.0, "damage": 1, "bite_delay": 1.0, "scale": 1.0, "width": 1.05,
		"duck": 0.3, "cover": 0.7, "skin": Color("7a8670"), "shirt": E.UNIFORM, "pants": E.UNIFORM, "shoe": Color("1a1816"), "points": 480}


func setup() -> void:
	z.add_to_group("empire")


func brain_overrides() -> Dictionary:
	return {"aggression": 0.05, "retreat_probability": 0.5}


func can_bite() -> bool:
	return state == MOVE


static func known(main: Node) -> Array:
	return main.get_meta("known_covers") if main.has_meta("known_covers") else []


# המחסה שהשחקן מתחבא מאחוריו עכשיו (או null)
static func cover_near(tree: SceneTree, pl: Node) -> Node:
	for c in tree.get_nodes_in_group("cover"):
		if c.has_method("cover_rect"):
			var r: Rect2 = c.cover_rect()
			if absf(r.get_center().x - pl.global_position.x) < r.size.x * 0.5 + 50.0 and absf(r.end.y - pl.global_position.y) < 30.0:
				return c
	return null


func physics(pl: Node, delta: float) -> bool:
	_st -= delta
	_cd -= delta
	if z.dead or pl == null or pl.dead:
		return false
	if z.goal_x < INF:
		state = MOVE
		return false
	var main: Node = z.get_parent()
	var d: Vector2 = pl.global_position - z.global_position
	# לומד מחסים
	if pl._crouching:
		_hide += delta
		if _hide > HIDE_T:
			_hide = -3.0
			var c := cover_near(z.get_tree(), pl)
			if c != null:
				var kc: Array = known(main)
				var cx: float = c.cover_rect().get_center().x
				var seen := false
				for k in kc:
					if absf(float(k) - cx) < 40.0:
						seen = true
				if not seen:
					kc.append(cx)
					main.set_meta("known_covers", kc)
					z._popup("TARGET REGISTERED", Color("ff8060"), 12, -80.0)
	else:
		_hide = maxf(_hide - delta, 0.0)
	match state:
		SETUP:
			if _st <= 0.0:
				state = SET
				_cd = 0.3
			return _stay(delta)
		SET:
			z._dir = signf(d.x) if absf(d.x) > 4.0 else z._dir
			if absf(d.x) < PACK_R or absf(d.x) > RANGE + 200.0:   # קרוב מדי / רחוק מדי: מקפל
				state = MOVE
				return _stay(delta)
			var at_known := false
			for k in known(main):
				if absf(float(k) - pl.global_position.x) < 90.0:
					at_known = true
			if _cd <= 0.0 or (at_known and _cd < FIRE_CD - 1.0):
				_fire(pl, at_known)
			return _stay(delta)
	# MOVE: מתרחק / מתקרב לטווח, ומתמקם
	if absf(d.x) < 1100.0 and absf(d.y) < 300.0:
		z._dir = signf(d.x) if absf(d.x) > 4.0 else z._dir
		if absf(d.x) < KEEP:
			z.velocity.x = move_toward(z.velocity.x, -z._dir * float(z.chase_speed), 600.0 * delta)
			if not z.is_on_floor():
				z.velocity.y += z.gravity * delta
			z.move_and_slide()
			return true
		if absf(d.x) < RANGE:
			state = SETUP
			_st = SETUP_T
			return _stay(delta)
	return false


func _fire(pl: Node, at_known: bool) -> void:
	_cd = FIRE_CD
	fired += 1
	if at_known:
		fast += 1
	var from: Vector2 = z.global_position + Vector2(z._dir * 10.0, -26.0)
	var tgt: Vector2 = pl.global_position
	var flight := FAST_FLIGHT if at_known else FLIGHT
	var l = SB.Lob.new()
	var tr := MTracker.new()
	tr.z = z
	l.owner_t = tr
	l.damage = 2
	l.kind = "shell"
	l.col = Color(1.0, 0.6, 0.2)
	l.r = 5.0
	l.blast_r = BLAST
	l.velocity = Vector2((tgt.x - from.x) / flight, (tgt.y - from.y) / flight - 0.5 * l.gravity * flight)
	z.get_parent().add_child(l)
	l.global_position = from
	Sfx.play("mo_thump", from, 0.0, 0.1, 3)
	Sfx.play("mo_whistle", tgt, -6.0, 0.05, 2)
	Particles.burst(z.get_parent(), from, "smoke", Vector2(0, -1), 4)


func _stay(delta: float) -> bool:
	z.velocity.x = move_toward(z.velocity.x, 0.0, 800.0 * delta)
	if not z.is_on_floor():
		z.velocity.y += z.gravity * delta
	z.move_and_slide()
	return true


# ============================================================
#  ציור: קסדה, תיק פצצות. בתנועה - הצינור על הגב. מוצב - כורע ליד מרגמה על חצובה (מכוונת גבוה), יד מכניסה פצצה
# ============================================================
func draw() -> bool:
	begin_draw()
	var set_up := state != MOVE
	var o: Dictionary = E.soldier(self, z, Vector2(12, -18) if set_up else Vector2(9, 6), "helmet", E.UNIFORM)
	var sh: Vector2 = o.sh
	var hip: Vector2 = o.hip
	DrawBatch.rect(z, Rect2(hip + Vector2(-10, -4), Vector2(7, 9)), col(Color("4a4a30")))   # תיק פצצות
	if set_up:
		var base := Vector2(16, -2)
		DrawBatch.line(z, base, base + Vector2(8, -26), col(Color("2a2a2a")), 3.5)   # הצינור
		DrawBatch.line(z, base + Vector2(4, -10), base + Vector2(-2, 0), col(Color("2a2a2a")), 1.2)   # חצובה
		DrawBatch.line(z, base + Vector2(4, -10), base + Vector2(10, 0), col(Color("2a2a2a")), 1.2)
		DrawBatch.rect(z, Rect2(base + Vector2(-5, -1), Vector2(10, 2)), col(Color("3a3a3a")))
		if state == SETUP and not z.dead:
			DrawBatch.string(z, ThemeDB.fallback_font, Vector2(-6, -60), "...", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(1, 1, 1, 0.7))
	else:
		DrawBatch.line(z, sh + Vector2(-10, -6), sh + Vector2(-4, 18), col(Color("2a2a2a")), 3.0)   # הצינור על הגב
	end_draw()
	return true
