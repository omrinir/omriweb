extends "res://enemies/zombie_type.gd"
# ============================================================
#  BONESIDE (שלב 61, "END OF THE WORLD") - זומבי שחצי ממנו עצם וחצי בשר, חצוי לאורך באמצע: מהקודקוד עד המפשעה עובר תפר
#    של בשר קרוע ודם. החצי הקדמי (הצד שפונה אליך: הפנים, החזה, היד המושטת) הוא שלד חשוף - גולגולת בלי שפתיים, כלוב צלעות
#    ריק, עצמות יד ורגל. החצי האחורי (העורף, הגב, היד שמאחור) הוא בשר חי ונפוח, עם שיער, אוזן וקרעי בגדים.
#  מה הוא למד, וממה: הנבגים נשאו אלפי מיתות של "כדור בבשר". הכוורת למדה שבשר זה מה שכדורים פוגעים בו. אז הוא נתן לצד
#    שנורה להירקב עד העצם - והוא שומר את צד העצם מולך. הוא בנוי בדיוק בצורה שבה ירו בו: מלפנים.
#  נזק:
#    צד העצם (פגיעה מלפנים): כדור בחזה עובר בין הצלעות (RIB_GAP - "THROUGH THE RIBS", ממשיך לזומבי שמאחוריו!), אחרת
#      סודק עצם (x BONE_MULT, בראש x SKULL_MULT). שברי עצם לבנים.
#    צד הבשר (מאחור): x FLESH_MULT, דם וקרעי בשר (FleshFx), פצעים שחושפים את העצם מתחת. אש אוכלת בשר (x FIRE_MULT).
#    פיצוץ: x1 (מנפץ את שניהם).
#  התקפות:
#    CLUB  - קרוב (CLUB_R): מסתובב עם הגב אליך ומניף את היד הבשרית הכבדה (CLUB_WIND) - ברגע הזה צד הבשר מולך (x OPEN_MULT).
#            ואז חובט בגב-יד (CLUB_DMG, הדיפה).
#    LUNGE - טווח בינוני (LUNGE_R): מתכופף עם כתף העצם קדימה (LUNGE_WIND) ומסתער (LUNGE_V). לא מסתובב באמצע - לקפוץ מעליו,
#            והוא עובר אותך עם הבשר אליך (RECOVER).
#    מסתובב אליך באיחור (TURN_DELAY): לקפוץ / להתגלגל מעליו ולירות בגב.
#  לומד (main meta "bs_flesh" >= LEARN - כמה פגיעות בבשר מאחור): "IT TURNS WITH YOU NOW" - מסתובב כמעט מיד (TURN_FAST),
#    מסתובב מתחתיך כשאתה קופץ מעליו, ועוצר את ההסתערות כשאתה קופץ. נגד: לחכות ל-CLUB (הוא חייב להראות את הבשר כדי להניף),
#    רימונים, אש.
#  מוות: נקרע לשניים לאורך התפר - ערימת עצמות וגוש בשר.
#  בוס (chase_range > 600): "THE FERRYMAN" - מעביר המתים של תעלת ביגל. ענק חצוי עם משוט מעבורת ביד העצם ופנס ECHO ירוק
#    על שרשרת. SWEEP - המשוט נמוך ורחב (B_SWEEP_*): לקפוץ. FERRY - פותח את כלוב הצלעות כמו דלתות (הלב חשוף! x HEART_MULT)
#    ומזנק לבלוע אותך (RIB_*): נתפסת - הוא סוחב אותך אל השער (FERRY_*), לוחץ. A/D או 3 פגיעות בלב = משתחררים.
#    SHED - מנער רסיסי עצם בקשת (SHED_*), כשאתה רחוק. TOLL - מצלצל בפנס: "ALL ABOARD" - להקת THRONG צועדת לזירה (TOLL_*).
#    לומד בקרב: אחרי BACK_LEARN פגיעות בגב - "IT TURNS WITH YOU NOW" (מסתובב מהר ומטאטא אחורה). וכל ROT_EVERY נזק לבשר -
#    "IT ROTS THE FLESH NOW": הבשר נרקב לעצם (ROT_MULT יורד) - נשאר רק הלב, כשהצלעות נפתחות.
#  לשנות: TURN_DELAY, TURN_FAST, RIB_GAP, BONE_MULT, SKULL_MULT, FLESH_MULT, FIRE_MULT, OPEN_MULT, LEARN, CLUB_*, LUNGE_*, CD;
#    בוס: B_ARMOR, HEART_MULT, ROT_EVERY, ROT_MULT, B_SWEEP_*, RIB_*, FERRY_*, SHED_*, TOLL_*, TURN_T, BACK_LEARN, ARENA_W.
# ============================================================

const SOUNDS := {
	"bs_chip": [["C", 0, 0, 0.0, 0.1, 0.0, 34.0, 0.5, 1.0, 0], ["S", 1700, 1100, 0.0, 0.05, 0.0, 45.0, 0.22, 1.0, 0], ["N", 0, 0, 0.0, 0.08, 0.0, 26.0, 0.25, 0.7, 0]],
	"bs_rib": [["S", 2600, 2900, 0.0, 0.12, 0.0, 22.0, 0.18, 1.0, 0], ["N", 0, 0, 0.0, 0.14, 0.0, 18.0, 0.22, 0.9, 0, 0.5]],
	"bs_squelch": {"drive": 2.0, "layers": [["N", 0, 0, 0.0, 0.2, 0.0, 12.0, 0.6, 0.25, 0, 0.1], ["B", 1.6, 1.2, 0.0, 0.22, 0.0, 10.0, 0.4, 1.0, 0, 0, 90.0]]},
	"bs_swing": [["N", 0, 0, 0.0, 0.3, 0.05, 7.0, 0.7, 0.3, 0, 0.1], ["S", 140, 70, 0.0, 0.25, 0.02, 8.0, 0.4, 1.0, 0]],
	"bs_rattle": [["C", 0, 0, 0.0, 0.05, 0.0, 50.0, 0.4, 1.0, 0], ["C", 0, 0, 0.07, 0.05, 0.0, 50.0, 0.35, 1.0, 0], ["C", 0, 0, 0.13, 0.05, 0.0, 50.0, 0.3, 1.0, 0], ["C", 0, 0, 0.2, 0.05, 0.0, 50.0, 0.25, 1.0, 0]],
	"bs_split": {"rev": 0.25, "drive": 2.4, "layers": [["N", 0, 0, 0.0, 0.4, 0.0, 7.0, 0.8, 0.3, 0, 0.1], ["C", 0, 0, 0.0, 0.3, 0.0, 12.0, 0.7, 1.0, 0], ["B", 1.2, 0.8, 0.05, 0.4, 0.0, 6.0, 0.5, 1.0, 0, 0, 80.0], ["C", 0, 0, 0.15, 0.2, 0.0, 20.0, 0.5, 1.0, 0]]},
	"fm_bellow": {"rev": 0.5, "drive": 2.8, "layers": [["V", 58, 44, 0.0, 1.9, 0.1, 1.0, 1.0, 1.0, 0.07, 0, [320, 680, 24]], ["V", 87, 66, 0.05, 1.8, 0.1, 1.0, 0.6, 1.0, 0.07, 0, [400, 820, 20]], ["N", 0, 0, 0.0, 1.6, 0.1, 1.4, 0.35, 0.12, 0]]},
	"fm_bell": {"rev": 0.6, "layers": [["S", 620, 618, 0.0, 2.2, 0.0, 1.2, 0.4, 1.0, 0], ["S", 1490, 1486, 0.0, 1.6, 0.0, 1.8, 0.22, 1.0, 0], ["S", 2410, 2400, 0.0, 1.0, 0.0, 2.6, 0.12, 1.0, 0], ["C", 0, 0, 0.0, 0.05, 0.0, 60.0, 0.4, 1.0, 0]]},
	"fm_creak": [["W", 70, 62, 0.0, 0.6, 0.05, 2.0, 0.3, 0.4, 0.06], ["N", 0, 0, 0.0, 0.5, 0.05, 3.0, 0.3, 0.2, 0, 0.3], ["C", 0, 0, 0.45, 0.08, 0.0, 30.0, 0.5, 1.0, 0]],
	"fm_heart": {"drive": 2.2, "layers": [["B", 1.0, 0.8, 0.0, 0.25, 0.0, 9.0, 0.7, 1.0, 0, 0, 60.0], ["S", 60, 40, 0.0, 0.25, 0.0, 9.0, 0.6, 1.0, 0]]},
}

const DebrisScript := preload("res://debris.gd")
const FleshFx := preload("res://effects/flesh_fx.gd")
const ThrongT := preload("res://enemies/types/throng.gd")
const Registry := preload("res://enemies/zombie_registry.gd")

const BONE := Color("e2d8c0")
const BONE_D := Color("a69a7e")
const BONE_S := Color("6e6450")
const MEAT := Color("8a2a26")
const MEAT_D := Color("561612")
const GORE := Color(0.45, 0.04, 0.04, 0.9)
const SPORE := Color(0.62, 1.0, 0.5)

const TURN_DELAY := 0.55          # מסתובב אליך באיחור (החלון לגב)
const TURN_FAST := 0.07           # (למד)
const RIB_GAP := 0.45             # סיכוי שכדור בחזה עובר בין הצלעות
const BONE_MULT := 0.25
const SKULL_MULT := 0.2
const FLESH_MULT := 1.35
const FIRE_MULT := 1.5
const OPEN_MULT := 1.2
const LEARN := 10
const CLUB_R := 72.0
const CLUB_WIND := 0.5
const CLUB_T := 0.18
const CLUB_DMG := 1
const LUNGE_R := Vector2(140.0, 270.0)
const LUNGE_WIND := 0.38
const LUNGE_V := 400.0
const LUNGE_T := 0.42
const LUNGE_DMG := 1
const RECOVER := 0.65
const CD := Vector2(0.6, 1.2)
# בוס
const B_ARMOR := 0.3              # צד העצם
const HEART_MULT := 2.4
const ROT_EVERY := 180            # כל כמה נזק (כשפוגעים בבשר) עוד שלב ריקבון
const ROT_MULT := [1.4, 1.15, 0.9, 0.7]
const B_SWEEP_R := 260.0
const B_SWEEP_WIND := 0.55
const B_SWEEP_T := 0.3
const B_SWEEP_DMG := 2
const RIB_R := Vector2(120.0, 330.0)
const RIB_WIND := 0.7
const RIB_V := 520.0
const RIB_T := 0.45
const FERRY_MAX := 3.2
const FERRY_SQUEEZE := 1.1
const FERRY_HEART := 3
const SHED_R := 380.0
const SHED_WIND := 0.6
const SHED_N := 5
const SHED_CD := 5.5
const TOLL_T := 1.3
const TOLL_CD := 15.0
const TOLL_N := 4
const TOLL_MAX := 2
const TURN_T := 0.75
const TURN_T_LEARN := 0.2
const BACK_LEARN := 10
const ARENA_W := 1150.0
const B_CD := Vector2(0.4, 0.95)

enum {WALK, CLUB_W, CLUB, LUNGE_W, LUNGE, RECOVERY, B_WALK, B_SWEEP_W, B_SWEEP, B_RIB_W, B_RIB, B_FERRY, B_SHED_W, B_TOLL, B_RECOVER}
enum {H_NONE, H_BONE, H_SKULL, H_FLESH, H_FIRE, H_BLAST, H_HEART}

var state := WALK
# לבדיקות
var bone_hits := 0
var rib_passes := 0
var flesh_hits := 0
var clubs := 0
var club_hits := 0
var lunges := 0
var lunge_hits := 0
var pivots := 0
var aborts := 0
var sweeps := 0
var sweep_hits := 0
var ribs := 0
var ferries := 0
var heart_hits := 0
var sheds := 0
var tolls := 0
var back_sweeps := 0
var rot := 0

var _st := 0.0
var _cd := 1.0
var _hit := false
var _turn := 0.0
var _kind := H_NONE
var _flesh_back := true
var _pop_t := 0.0
var _wounds := []                 # פצעים בצד הבשר [x, y]
var _var := []                    # [בגד, שיער, צלקת בעצם, שן חסרה]
# בוס
var _b_cd := 2.0
var _shed_cd := 3.0
var _toll_cd := 6.0
var _engaged := false
var _spawned: Array = []
var _back_n := 0
var _back_learn := false
var _rib_open := 0.0              # 0 סגור .. 1 פתוח
var _ferry_t := 0.0
var _squeeze_t := 0.0
var _heart_n := 0
var _ring := -1.0
var _ring_pos := Vector2.ZERO
var _rib_recover := false


func _boss() -> bool:
	return z != null and float(z.chase_range) > 600.0


func stats() -> Dictionary:
	var fl := _kind == H_FLESH or _kind == H_FIRE or _kind == H_BLAST or _kind == H_HEART
	if _boss():
		return {"name": "BONESIDE", "hp": 520, "walk": 40.0, "chase": 86.0, "damage": 2, "bite_delay": 1.0, "scale": 2.4, "width": 1.15,
			"duck": 0.0, "cover": 0.0, "skin": Color("8f9a84"), "shirt": Color("3a3430"), "pants": Color("2a2826"), "shoe": Color("1e1c1a"),
			"points": 3000, "boss": true, "boss_name": "THE FERRYMAN", "ragdoll": false, "flesh": fl}
	return {"name": "BONESIDE", "hp": 64, "walk": 40.0, "chase": 80.0, "damage": 1, "bite_delay": 0.9, "scale": 1.06, "width": 1.06,
		"duck": 0.0, "cover": 0.0, "skin": Color("8e9c86"), "shirt": Color("5a4e44"), "pants": Color("2e302e"), "shoe": Color("221e1a"),
		"points": 380, "ragdoll": false, "flesh": fl}


func brain_overrides() -> Dictionary:
	return {"aggression": 0.6}


func use_brain_movement() -> bool:
	return false


func can_bite() -> bool:
	return false


func _main() -> Node:
	return z.get_parent()


static func is_learned(m: Node) -> bool:
	return m != null and int(m.get_meta("bs_flesh", 0)) >= LEARN


func learned() -> bool:
	return is_learned(_main())


func setup() -> void:
	var r := RandomNumberGenerator.new()
	r.seed = z.get_instance_id() * 11 + 5
	var rags := [Color("5a4e44"), Color("3a4a5a"), Color("6a3a2e"), Color("4a5a3a"), Color("7a6a4a")]
	var hairs := [Color("2a2420"), Color("6a5a48"), Color("8a8478"), Color("3a2a1e")]
	_var = [rags[r.randi() % rags.size()], hairs[r.randi() % hairs.size()], r.randf() < 0.5, r.randi() % 4]
	z.shirt = _var[0]
	z.hair = _var[1]
	if _boss():
		state = B_WALK
		_resize(Vector2(34.0, 60.0))
		z.set_meta("no_cover", true)
	else:
		state = WALK
		_resize(Vector2(26.0, 57.0))


func _resize(b: Vector2) -> void:
	var rs := z._shape.shape as RectangleShape2D
	rs.size = Vector2(b.x * z.wf * z.sc, b.y * z.sc)
	z._shape.position = Vector2(0.0, -b.y * 0.5 * z.sc)


# מסתובב עם הגב אליך כדי להניף (צד הבשר מולך)
func _open() -> bool:
	return state == CLUB_W


# ============================================================
#  תנועה
# ============================================================
func physics(pl: Node, delta: float) -> bool:
	if z.dead:
		return false
	_st -= delta
	_cd -= delta
	_pop_t -= delta
	if not z.is_on_floor():
		z.velocity.y += z.gravity * delta
	var has: bool = pl != null and not pl.dead
	var d: Vector2 = (pl.global_position - z.global_position) if has else Vector2.ZERO
	if _boss():
		_boss_physics(pl, has, d, delta)
		z.move_and_slide()
		return true
	var lr := learned()
	if lr and has:
		_learn_said(pl, d)
	match state:
		WALK:
			if not has or absf(d.x) > 1300.0:
				z.velocity.x = move_toward(z.velocity.x, 0.0, 600.0 * delta)
			else:
				_face(pl, d, delta, lr)
				var mv: float = z._dir * z.chase_speed if absf(d.x) > CLUB_R * 0.6 else 0.0
				if signf(d.x) != z._dir:   # עוד לא הסתובב: עומד (זה החלון לגב)
					mv = 0.0
				z.velocity.x = move_toward(z.velocity.x, mv, 700.0 * delta)
				z._walk_phase += delta * absf(z.velocity.x) / 7.0
				if z.is_on_floor() and z.is_on_wall() and absf(z.velocity.x) < 30.0:
					z.velocity.y = -480.0
				var facing: bool = signf(d.x) == z._dir
				if _cd <= 0.0 and z.is_on_floor() and facing and absf(d.y) < 70.0:
					if absf(d.x) < CLUB_R:
						_start(CLUB_W, CLUB_WIND)
						Sfx.play("bs_squelch", z.global_position, -2.0, 0.1, 3)
					elif absf(d.x) > LUNGE_R.x and absf(d.x) < LUNGE_R.y:
						_start(LUNGE_W, LUNGE_WIND)
						Sfx.play("bs_rattle", z.global_position, -2.0, 0.1, 3)
		CLUB_W:
			z.velocity.x = move_toward(z.velocity.x, 0.0, 1200.0 * delta)
			if _st <= 0.0:
				_start(CLUB, CLUB_T)
				clubs += 1
				_hit = false
				if has and absf(d.x) > 4.0:
					z._dir = signf(d.x)
				z.velocity.x = z._dir * 150.0
				Sfx.play("bs_swing", z.global_position, 0.0, 0.1, 3)
		CLUB:
			z.velocity.x = move_toward(z.velocity.x, 0.0, 900.0 * delta)
			if has and not _hit:
				var r := Rect2(z.global_position.x + (0.0 if z._dir > 0.0 else -80.0), z.global_position.y - 60.0 * z.sc, 80.0, 60.0 * z.sc)
				if r.intersects(pl.body_rect()):
					_hit = true
					if pl._roll_t <= 0.0:
						club_hits += 1
						z._spray_blood(pl.global_position + Vector2(0, -30), Vector2(z._dir, -0.4), 5, 240.0)
					pl.hurt(CLUB_DMG, Vector2(z._dir * 1.6, -0.5))
			if _st <= 0.0:
				_start(RECOVERY, RECOVER * 0.7)
		LUNGE_W:
			z.velocity.x = move_toward(z.velocity.x, -z._dir * 20.0, 1200.0 * delta)
			if lr and has and _jumped(pl, d):
				_abort(d)
			elif _st <= 0.0:
				_start(LUNGE, LUNGE_T)
				lunges += 1
				_hit = false
				Sfx.play("bs_rattle", z.global_position, 0.0, 0.1, 3, 0.8)
		LUNGE:
			z.velocity.x = z._dir * LUNGE_V
			z._walk_phase += delta * 20.0
			if lr and has and _jumped(pl, d) and absf(d.x) < 120.0:
				_abort(d)
			elif has and not _hit:
				var me := Rect2(z.global_position + Vector2(-16.0 * z.sc, -58.0 * z.sc), Vector2(32.0 * z.sc, 58.0 * z.sc))
				if me.intersects(pl.body_rect()):
					_hit = true
					if pl._roll_t <= 0.0:
						lunge_hits += 1
					pl.hurt(LUNGE_DMG, Vector2(z._dir * 1.8, -0.6))
			if _st <= 0.0 or (z.is_on_wall() and _st < LUNGE_T - 0.1):
				_start(RECOVERY, RECOVER)
		RECOVERY:
			z.velocity.x = move_toward(z.velocity.x, 0.0, 900.0 * delta)
			if _st <= 0.0:
				state = WALK
				_cd = randf_range(CD.x, CD.y)
	z.move_and_slide()
	return true


func _start(s: int, t: float) -> void:
	state = s
	_st = t


# השחקן קפץ מעליו / לכיוונו (למד: קורא את הקפיצה)
func _jumped(pl: Node, d: Vector2) -> bool:
	return not pl.is_on_floor() and pl.velocity.y < -120.0 and absf(d.x) < 200.0


func _abort(d: Vector2) -> void:
	aborts += 1
	state = WALK
	_cd = 0.25
	z.velocity.x = 0.0
	if absf(d.x) > 4.0:
		z._dir = signf(d.x)


# מסתובב אליך באיחור (חלון לגב אחרי קפיצה / גלגול). למד: כמעט מיד, ומסתובב מתחתיך כשאתה באוויר מעליו
func _face(pl: Node, d: Vector2, delta: float, lr: bool) -> void:
	var tx := d.x
	if lr and not pl.is_on_floor() and absf(d.x) < 140.0 and d.y < -20.0:   # קורא לאן תנחת
		tx = d.x + pl.velocity.x * 0.35
		if signf(tx) != z._dir and absf(tx) > 4.0:
			z._dir = signf(tx)
			pivots += 1
			_turn = 0.0
			return
	if absf(tx) < 6.0:
		return
	if signf(tx) != z._dir:
		_turn += delta
		if _turn >= (TURN_FAST if lr else TURN_DELAY):
			z._dir = signf(tx)
			_turn = 0.0
			if lr:
				pivots += 1
	else:
		_turn = 0.0


func _learn_said(pl: Node, d: Vector2) -> void:
	var m := _main()
	if m == null or m.has_meta("bs_said") or absf(d.x) > 650.0 or not Art.on_screen(z, z.global_position, -40.0):
		return
	m.set_meta("bs_said", true)
	z._popup("IT TURNS WITH YOU NOW", Color("ff8a7a"), 14, -90.0)
	if pl.has_method("_say"):
		pl._say("It turns as I jump... wait for the swing - it shows the flesh to swing.", Color("ff8a7a"))


# ============================================================
#  נזק: צד עצם / צד בשר
# ============================================================
func on_damage(amount: int, hit_pos: Vector2, dir: Vector2, src: Dictionary) -> bool:
	if z.dead:
		return true
	var s := str(src.get("source", "bullet"))
	_kind = H_NONE
	if _boss():
		return _boss_damage(amount, hit_pos, dir, src, s)
	if s == "fire":
		_kind = H_FIRE
		return true
	if not (s == "bullet" or s == "melee"):
		if s != "hazard" and s != "zombie":
			_kind = H_BLAST
			_bone_dust(hit_pos, dir, 4)
		return true
	var front: bool = dir.x * z._dir < 0.0
	var ly: float = (hit_pos.y - z.global_position.y) / z.sc
	if not front or _open():
		_flesh(hit_pos, dir, ly, not front)
		return true
	# צד העצם
	if ly > -42.0 and ly < -18.0 and s == "bullet" and randf() < RIB_GAP:
		if _pass_ribs(hit_pos, dir, src):
			return false
	_kind = H_SKULL if ly < -42.0 else H_BONE
	_bone(hit_pos, dir)
	return true


# כדור עובר בין הצלעות: לא נוגע בו, וממשיך הלאה (הקליע חודר עוד זומבי)
func _pass_ribs(hit_pos: Vector2, dir: Vector2, src: Dictionary) -> bool:
	var b = instance_from_id(int(src.get("bullet", 0)))
	if b == null or not is_instance_valid(b) or b.get("pierce") == null:
		return false
	b.pierce = int(b.pierce) + 1
	rib_passes += 1
	if Art.on_screen(z, hit_pos):
		Sfx.play("bs_rib", hit_pos, -6.0, 0.2, 3)
		if randf() < 0.5:
			_bone_dust(hit_pos, dir, 1)
	if _pop_t <= 0.0:
		_pop_t = 0.8
		z._popup("THROUGH THE RIBS", Color("e8e0c8"), 11, -92.0)
	_bone_hint()
	return true


func _bone(hit_pos: Vector2, dir: Vector2) -> void:
	bone_hits += 1
	if Art.on_screen(z, hit_pos):
		Sfx.play("bs_chip", hit_pos, -3.0, 0.2, 4)
		_bone_dust(hit_pos, dir, 2)
	if _pop_t <= 0.0:
		_pop_t = 0.8
		z._popup("BONE", Color("e8e0c8"), 12, -95.0)
	_bone_hint()


func _bone_hint() -> void:
	var m := _main()
	if m == null:
		return
	var n := int(m.get_meta("bs_bone", 0)) + 1
	m.set_meta("bs_bone", n)
	if n == 5:
		var pl := player()
		if pl != null and pl.has_method("_say"):
			pl._say("Bullets go right through the bone... get behind it - hit the FLESH!", Color("e8e0c8"))


func _flesh(hit_pos: Vector2, dir: Vector2, ly: float, back: bool) -> void:
	_kind = H_FLESH
	_flesh_back = back
	flesh_hits += 1
	if _wounds.size() < 6:
		_wounds.append(Vector2(randf_range(-7.0, -2.0), clampf(ly, -48.0, -8.0)))
	if Art.on_screen(z, hit_pos):
		Sfx.play("bs_squelch", hit_pos, -4.0, 0.2, 3)
		z._spray_blood(hit_pos, Vector2(dir.x, -0.3), 4, 260.0)
	if back:
		var m := _main()
		if m != null:
			m.set_meta("bs_flesh", int(m.get_meta("bs_flesh", 0)) + 1)


func _bone_dust(at: Vector2, dir: Vector2, n: int) -> void:
	if not Art.on_screen(z, at):
		return
	for i in Quality.scaled(n, 1.0):
		var c = DebrisScript.new()
		_main().add_child(c)
		c.setup(at, Vector2(randf_range(1.5, 3.0), randf_range(1.5, 3.0)), BONE if i % 2 == 0 else BONE_D, Vector2(-dir.x * randf_range(60, 200), -randf_range(40, 180)))


func damage_mult(zone: String, _src: Dictionary) -> float:
	if _boss():
		return _boss_mult(zone)
	match _kind:
		H_BONE:
			return BONE_MULT
		H_SKULL:
			return SKULL_MULT
		H_FLESH:
			return FLESH_MULT if _flesh_back else OPEN_MULT
		H_FIRE:
			return FIRE_MULT
	return 1.0


# מוות: נקרע לשניים לאורך התפר
func on_death() -> void:
	if _boss():
		_boss_death()
		return
	var m := _main()
	Sfx.play("bs_split", z.global_position, 0.0, 0.1, 3)
	if not Art.on_screen(z, z.global_position):
		return
	var c0: Vector2 = z.global_position + Vector2(0, -30.0 * z.sc)
	for i in Quality.scaled(6, 1.0):   # עצמות עפות מצד העצם
		var c = DebrisScript.new()
		m.add_child(c)
		c.setup(c0 + Vector2(z._dir * randf_range(0, 8), randf_range(-20, 20)), Vector2(randf_range(2, 6), randf_range(1.5, 3.0)), BONE if i % 2 == 0 else BONE_D, Vector2(z._dir * randf_range(40, 220), -randf_range(120, 320)))
	FleshFx.burst(m, c0 + Vector2(-z._dir * 4.0, 0), Vector2(-z._dir, -0.5), z.skin, "body", true, false, z.death_load() >= 2)
	z._spray_blood(c0, Vector2(0, -1), 10, 320.0)


func wants_redraw() -> bool:
	return true


# ============================================================
#  בוס: THE FERRYMAN
# ============================================================
func _boss_physics(pl: Node, has: bool, d: Vector2, delta: float) -> void:
	_b_cd -= delta
	_shed_cd -= delta
	_toll_cd -= delta
	if _ring >= 0.0:
		_ring += delta
		if _ring > 0.5:
			_ring = -1.0
	var met: bool = has and (_engaged or absf(d.x) < z.chase_range or z._alert_t > 0.0)
	if met:
		_engaged = true
	var want_open := 1.0 if state in [B_RIB_W, B_RIB, B_FERRY] or (state == B_RECOVER and _st > 0.35 and ribs > 0 and _rib_recover) else 0.0
	_rib_open = move_toward(_rib_open, want_open, delta * (3.0 if want_open > 0.5 else 2.0))
	match state:
		B_WALK:
			if not met:
				z.velocity.x = move_toward(z.velocity.x, 0.0, 500.0 * delta)
				return
			_boss_turn(d, delta)
			var mv: float = z._dir * z.chase_speed if absf(d.x) > 150.0 else 0.0
			z.velocity.x = move_toward(z.velocity.x, mv, 500.0 * delta)
			z._walk_phase += delta * absf(z.velocity.x) / 12.0
			_keep_arena()
			if z.is_on_floor() and z.is_on_wall() and absf(z.velocity.x) < 30.0 and absf(d.x) > 150.0:
				z.velocity.y = -640.0
			if _b_cd <= 0.0 and z.is_on_floor():
				var facing: bool = signf(d.x) == z._dir
				if _toll_cd <= 0.0 and _alive_spawned() < TOLL_MAX * 2:
					_start(B_TOLL, TOLL_T)
					tolls += 1
					_toll_cd = TOLL_CD
					Sfx.play("fm_bell", z.global_position, 2.0, 0.0, 1)
				elif not facing:
					pass
				elif absf(d.x) < B_SWEEP_R * 0.75 and absf(d.y) < 90.0 and randf() < 0.6:
					_start(B_SWEEP_W, B_SWEEP_WIND)
				elif absf(d.x) > RIB_R.x and absf(d.x) < RIB_R.y and absf(d.y) < 90.0 and pl.grabbed_by == null:
					_start(B_RIB_W, RIB_WIND)
					Sfx.play("fm_creak", z.global_position, 4.0, 0.05, 1)
				elif absf(d.x) > SHED_R and _shed_cd <= 0.0:
					_start(B_SHED_W, SHED_WIND)
					_shed_cd = SHED_CD
					Sfx.play("bs_rattle", z.global_position, 4.0, 0.05, 1, 0.6)
				elif absf(d.x) < B_SWEEP_R and absf(d.y) < 90.0:
					_start(B_SWEEP_W, B_SWEEP_WIND)
		B_SWEEP_W:
			z.velocity.x = move_toward(z.velocity.x, 0.0, 1400.0 * delta)
			if _st <= 0.0:
				_start(B_SWEEP, B_SWEEP_T)
				sweeps += 1
				_hit = false
				z.velocity.x = z._dir * 140.0
				Sfx.play("bs_swing", z.global_position, 4.0, 0.1, 2, 0.6)
		B_SWEEP:
			z.velocity.x = move_toward(z.velocity.x, 0.0, 900.0 * delta)
			_sweep_hit(pl, has)
			if _st <= 0.0:
				_dust_ring()
				_rib_recover = false
				_start(B_RECOVER, 0.6)
		B_RIB_W:
			z.velocity.x = move_toward(z.velocity.x, -z._dir * 25.0, 1200.0 * delta)
			if has and absf(d.x) > 6.0 and _st > RIB_WIND * 0.4:
				z._dir = signf(d.x)
			if _st <= 0.0:
				_start(B_RIB, RIB_T)
				ribs += 1
				_hit = false
				Sfx.play("fm_bellow", z.global_position, 0.0, 0.1, 1, 1.3)
		B_RIB:
			z.velocity.x = z._dir * RIB_V
			z._walk_phase += delta * 18.0
			if has and not _hit and pl.grabbed_by == null:
				var me := Rect2(z.global_position + Vector2(z._dir * 10.0 - 40.0, -120.0), Vector2(80.0, 120.0))
				if me.intersects(pl.body_rect()):
					_hit = true
					if pl._roll_t <= 0.0 and not pl.god_mode():
						_ferry_start(pl)
						return
			var bx: float = z.global_position.x
			if _st <= 0.0 or z.is_on_wall() or (z._dir < 0.0 and bx < z.world_w - ARENA_W) or (z._dir > 0.0 and bx > z.world_w - 80.0):
				_rib_recover = true
				_start(B_RECOVER, 0.9)
		B_FERRY:
			_ferry(pl, has, delta)
		B_SHED_W:
			z.velocity.x = move_toward(z.velocity.x, 0.0, 1400.0 * delta)
			if has and absf(d.x) > 6.0:
				z._dir = signf(d.x)
			if _st <= 0.0:
				_shed(pl, has)
				_rib_recover = false
				_start(B_RECOVER, 0.5)
		B_TOLL:
			z.velocity.x = move_toward(z.velocity.x, 0.0, 1400.0 * delta)
			if _st < TOLL_T * 0.5 and _st + delta >= TOLL_T * 0.5:
				_summon(pl)
			if _st <= 0.0:
				_rib_recover = false
				_start(B_RECOVER, 0.2)
		B_RECOVER:
			z.velocity.x = move_toward(z.velocity.x, 0.0, 900.0 * delta)
			if _st <= 0.0:
				state = B_WALK
				_b_cd = randf_range(B_CD.x, B_CD.y)


# מסתובב לאט (TURN_T). למד: מהר, ומטאטא אחורה כשאתה מאחוריו
func _boss_turn(d: Vector2, delta: float) -> void:
	if absf(d.x) < 8.0 or signf(d.x) == z._dir:
		_turn = 0.0
		return
	_turn += delta
	if _back_learn and absf(d.x) < B_SWEEP_R * 0.9 and absf(d.y) < 90.0:
		if _turn >= TURN_T_LEARN:
			z._dir = signf(d.x)
			_turn = 0.0
			back_sweeps += 1
			_start(B_SWEEP_W, B_SWEEP_WIND * 0.55)
		return
	if _turn >= (TURN_T_LEARN if _back_learn else TURN_T):
		z._dir = signf(d.x)
		_turn = 0.0


func _keep_arena() -> void:
	var bx: float = z.global_position.x
	if bx < z.world_w - ARENA_W and z.velocity.x < 0.0:
		z.velocity.x = 0.0
	if bx > z.world_w - 70.0 and z.velocity.x > 0.0:
		z.velocity.x = 0.0


func _sweep_hit(pl: Node, has: bool) -> void:
	if not has or _hit:
		return
	var x0: float = z.global_position.x - z._dir * 20.0
	var x1: float = z.global_position.x + z._dir * B_SWEEP_R
	var r := Rect2(minf(x0, x1), z.global_position.y - 38.0, absf(x1 - x0), 38.0)
	if r.intersects(pl.body_rect()):
		_hit = true
		if pl._roll_t <= 0.0:
			sweep_hits += 1
		pl.hurt(B_SWEEP_DMG, Vector2(z._dir * 2.0, -0.9))


func _dust_ring() -> void:
	_ring = 0.0
	_ring_pos = z.global_position + Vector2(z._dir * B_SWEEP_R * 0.5, 0)
	if Art.on_screen(z, z.global_position):
		Particles.burst(_main(), _ring_pos + Vector2(0, -4), "smoke", Vector2(z._dir, -0.4), 6)


# ---- FERRY: נבלעת בכלוב הצלעות. הוא סוחב אותך אל השער ולוחץ ----
func _ferry_start(pl: Node) -> void:
	ferries += 1
	state = B_FERRY
	_ferry_t = 0.0
	_squeeze_t = 0.4
	_heart_n = 0
	pl.grab(z)
	Sfx.play("fm_creak", z.global_position, 6.0, 0.0, 1, 0.7)
	_shake(8.0, 0.3)
	var m := _main()
	if not m.has_meta("fm_ferry_said"):
		m.set_meta("fm_ferry_said", true)
		z._popup("ALL ABOARD", Color("ff8a7a"), 18, -150.0)
		if pl.has_method("_say"):
			pl._say("He's carrying me DOWN - shoot the HEART!", Color("ff8a7a"))


func _ferry(pl: Node, has: bool, delta: float) -> void:
	_ferry_t += delta
	if not has or pl.grabbed_by != z:
		_ferry_end(false)
		return
	var hold: Vector2 = z.global_position + Vector2(z._dir * 6.0 * z.sc, 0.0)
	pl.global_position.x = move_toward(pl.global_position.x, hold.x, 400.0 * delta)
	pl.velocity = Vector2.ZERO
	z._dir = 1.0   # הולך אל השער (סוף השלב)
	z.velocity.x = move_toward(z.velocity.x, 46.0, 300.0 * delta)
	z._walk_phase += delta * 4.0
	_keep_arena()
	_squeeze_t -= delta
	if _squeeze_t <= 0.0:
		_squeeze_t = FERRY_SQUEEZE
		pl.hurt(1, Vector2.ZERO)
		Sfx.play("fm_creak", z.global_position, 0.0, 0.1, 2, 0.9)
	if _ferry_t >= FERRY_MAX or _heart_n >= FERRY_HEART:
		pl.grabbed_by = null
		_ferry_end(_heart_n < FERRY_HEART)


func on_release() -> void:
	if state == B_FERRY:
		_ferry_end(false)


# שחרור: thrown = זרק אותך (נגמר הזמן), אחרת השתחררת (A/D או הלב)
func _ferry_end(thrown: bool) -> void:
	var pl := player()
	if pl != null and pl.grabbed_by == z:
		pl.grabbed_by = null
	if pl != null and thrown:
		pl.hurt(1, Vector2(-z._dir * 2.2, -1.0))
	elif pl != null:
		pl.velocity = Vector2(-z._dir * 260.0, -260.0)
	_rib_recover = true
	_start(B_RECOVER, 1.0)


func _shed(pl: Node, has: bool) -> void:
	sheds += 1
	var from: Vector2 = z.global_position + Vector2(z._dir * 18.0 * z.sc, -40.0 * z.sc)
	var to: Vector2 = (pl.global_position + Vector2(0, -24)) if has else from + Vector2(z._dir * 400.0, 80.0)
	var base: float = (to - from).angle()
	for i in SHED_N:
		var sd := BoneShard.new()
		sd.vel = Vector2.from_angle(base + (float(i) - float(SHED_N - 1) * 0.5) * 0.13) * 620.0 + Vector2(0, -60)
		sd.spin = randf_range(-14.0, 14.0)
		sd.ln = randf_range(10.0, 16.0)
		_main().add_child(sd)
		sd.global_position = from
	Sfx.play("bs_split", z.global_position, 2.0, 0.1, 2, 1.3)
	_shake(4.0, 0.2)


func _alive_spawned() -> int:
	var n := 0
	for w in _spawned:
		if is_instance_valid(w) and not w.dead:
			n += 1
	return n


# TOLL: "ALL ABOARD" - להקת THRONG צועדת לזירה מהצד שמאחוריך
func _summon(pl: Node) -> void:
	var m := _main()
	var st = m.get("_stage") if m != null else null
	if st == null:
		return
	var side: float = -1.0
	if pl != null:
		side = -signf(z.global_position.x - pl.global_position.x)
	var x: float = clampf((pl.global_position.x if pl != null else z.global_position.x) + side * 420.0, z.world_w - ARENA_W + 60.0, z.world_w - 120.0)
	var s = ThrongT.spawn_school(st, x, TOLL_N, -1.0, -side)
	for mm in s.members:
		_spawned.append(mm)
		s.engaged = true
	if Art.on_screen(z, z.global_position):
		Particles.burst(m, Vector2(x, z.global_position.y - 10.0), "smoke", Vector2.UP, 8)
	if tolls == 1:
		z._popup("ALL ABOARD", Color("ff8a7a"), 18, -160.0)


func _shake(a: float, t: float) -> void:
	var cam: Camera2D = z.get_viewport().get_camera_2d()
	if cam != null and cam.has_method("shake"):
		cam.shake(a, t)


func _heart_open() -> bool:
	return _rib_open > 0.6


func _boss_damage(_amount: int, hit_pos: Vector2, dir: Vector2, src: Dictionary, s: String) -> bool:
	if s == "fire":
		_kind = H_FIRE
		return true
	if not (s == "bullet" or s == "melee"):
		if s != "hazard" and s != "zombie":
			_kind = H_BLAST
			_bone_dust(hit_pos, dir, 6)
		return true
	var front: bool = dir.x * z._dir < 0.0
	var ly: float = (hit_pos.y - z.global_position.y) / z.sc
	if state == B_FERRY or (front and _heart_open() and ly > -44.0 and ly < -20.0):   # הלב (בין הצלעות הפתוחות; בתוך הכלוב - כל ירייה)
		_kind = H_HEART
		heart_hits += 1
		if state == B_FERRY:
			_heart_n += 1
		Sfx.play("fm_heart", hit_pos, 0.0, 0.1, 3)
		if _pop_t <= 0.0:
			_pop_t = 0.6
			z._popup("HEART", Color("ffd34a"), 15, -150.0)
		return true
	if not front:
		_kind = H_FLESH
		flesh_hits += 1
		_back_n += 1
		if not _back_learn and _back_n >= BACK_LEARN:
			_back_learn = true
			z._popup("IT TURNS WITH YOU NOW", Color("ff8a7a"), 18, -150.0)
			var pl := player()
			if pl != null and pl.has_method("_say"):
				pl._say("He turns faster now... make him open the ribs.", Color("ff8a7a"))
		if _wounds.size() < 8:
			_wounds.append(Vector2(randf_range(-7.0, -2.0), clampf(ly, -50.0, -8.0)))
		if Art.on_screen(z, hit_pos):
			Sfx.play("bs_squelch", hit_pos, 0.0, 0.2, 3, 0.7)
		return true
	if ly > -44.0 and ly < -20.0 and s == "bullet" and randf() < RIB_GAP * 0.8 and _pass_ribs(hit_pos, dir, src):
		return false
	_kind = H_BONE
	bone_hits += 1
	if Art.on_screen(z, hit_pos):
		Sfx.play("bs_chip", hit_pos, 0.0, 0.2, 4, 0.7)
		_bone_dust(hit_pos, dir, 2)
	if _pop_t <= 0.0:
		_pop_t = 0.8
		z._popup("BONE", Color("e8e0c8"), 13, -150.0)
	return true


func _boss_mult(_zone: String) -> float:
	match _kind:
		H_HEART:
			return HEART_MULT
		H_FLESH, H_FIRE:
			_rot_check()
			var mlt: float = ROT_MULT[clampi(rot, 0, ROT_MULT.size() - 1)]
			return mlt * (1.0 if _kind == H_FLESH else 1.1)
		H_BLAST:
			return 0.85
	return B_ARMOR


# כל ROT_EVERY נזק: הבשר שפוגעים בו נרקב לעצם - עוד שלב ריקבון ("IT ROTS THE FLESH NOW")
func _rot_check() -> void:
	var hp_lost: int = z.max_hp - z.hp
	var stage_now := mini(hp_lost / ROT_EVERY, ROT_MULT.size() - 1)
	if stage_now > rot:
		rot = stage_now
		if rot == 1:
			z._popup("IT ROTS THE FLESH NOW", Color("ff8a7a"), 18, -150.0)
			var pl := player()
			if pl != null and pl.has_method("_say"):
				pl._say("The flesh is rotting to bone where I hit it... shoot the HEART when the ribs open!", Color("ff8a7a"))
		if Art.on_screen(z, z.global_position):
			Sfx.play("bs_rattle", z.global_position, 2.0, 0.0, 1, 0.5)
			_bone_dust(z.global_position + Vector2(-z._dir * 10.0 * z.sc, -40.0 * z.sc), Vector2(-z._dir, 0), 5)


func _boss_death() -> void:
	var pl := player()
	if pl != null and pl.grabbed_by == z:
		pl.grabbed_by = null
	for w in _spawned:
		if is_instance_valid(w) and not w.dead:
			w.take_damage(999, w.global_position + Vector2(0, -20), Vector2.UP, true, {"source": "hazard", "fixed": 999})
	_shake(16.0, 0.8)
	Sfx.play("fm_bellow", z.global_position, 2.0, 0.0, 1, 0.7)
	Sfx.play("bs_split", z.global_position, 4.0, 0.0, 1, 0.6)
	Sfx.play("fm_bell", z.global_position, 0.0, 0.0, 1, 0.8)
	var m := _main()
	var c0: Vector2 = z.global_position + Vector2(0, -110)
	for i in Quality.scaled(18, 1.0):
		var dbr = DebrisScript.new()
		m.add_child(dbr)
		dbr.setup(c0 + Vector2(randf_range(0, 40) * z._dir, randf_range(-40, 40)), Vector2(randf_range(4, 10), randf_range(2, 5)), BONE if i % 2 == 0 else BONE_D, Vector2(z._dir * randf_range(-80, 320), -randf_range(120, 420)))
	FleshFx.burst(m, c0 + Vector2(-z._dir * 20.0, 0), Vector2(-z._dir, -0.6), z.skin, "body", true, true)
	Particles.burst(m, z.global_position + Vector2(0, -80), "hit", Vector2.UP, int(34.0 * Quality.gore()))
	Particles.burst(m, z.global_position + Vector2(0, -90), "mist", Vector2.UP, 14)


# ============================================================
#  רסיס עצם (SHED): עף בקשת, פוגע בך (1). זז ב-_process (לא MOVERS)
# ============================================================
class BoneShard extends Node2D:
	var vel := Vector2.ZERO
	var spin := 0.0
	var ln := 12.0
	var life := 2.2
	var _a := 0.0
	var _done := false

	func _ready() -> void:
		z_index = 4

	func _process(delta: float) -> void:
		life -= delta
		if life <= 0.0:
			queue_free()
			return
		vel.y += 700.0 * delta
		global_position += vel * delta
		_a += spin * delta
		var pl := get_tree().get_first_node_in_group("player")
		if not _done and pl != null and not pl.dead and pl.body_rect().has_point(global_position):
			_done = true
			pl.hurt(1, Vector2(signf(vel.x), -0.3))
			queue_free()
			return
		var fy: float = 630.0
		var m := get_parent()
		if m != null and m.get("_stage") != null:
			fy = float(m._stage.floor_y)
		if global_position.y > fy - 2.0:
			queue_free()
			return
		queue_redraw()

	func _draw() -> void:
		DrawBatch.begin(self)
		_draw_b()
		DrawBatch.end(self)

	func _draw_b() -> void:
		var d := Vector2.from_angle(_a) * ln * 0.5
		DrawBatch.line(self, -d, d, Color("6e6450"), 4.0)
		DrawBatch.line(self, -d, d, Color("e2d8c0"), 2.4)
		DrawBatch.circle(self, d, 2.4, Color("e2d8c0"))
		DrawBatch.circle(self, -d, 2.0, Color("c8bca0"))


# ============================================================
#  ציור: חצוי לאורך. הצד הקדמי (פונה ימינה = אליך) עצם, הצד האחורי בשר. התפר באמצע: בשר קרוע ודם.
#  CLUB_W: מסתובב עם הגב אליך (מצויר הפוך - הבשר מולך) ומרים את היד הבשרית.
# ============================================================
func draw() -> bool:
	if _var.is_empty():
		return false
	if z.dead:
		_draw_dead()
		return true
	var turned := state == CLUB_W
	if turned:   # הגב אליך: מציירים הפוך
		var s := Vector2(-z._dir * z.wf * z.sc, z.sc)
		if z.is_on_floor():
			Art.ground_shadow(z, Vector2.ZERO, 14.0 * z.wf * z.sc)
		DrawBatch.set_transform_matrix(z, Transform2D(z.react_tilt(), Vector2(0.0, z.react_hop() * z.sc)) * Transform2D(0.0, s, 0.0, Vector2.ZERO))
	else:
		begin_draw()
	var tt: float = z._time
	var boss := _boss()
	var f: Array = feet(4.4 if not boss else 4.0, 2.4)
	var lean := 0.0
	var crouch := 0.0
	match state:
		CLUB_W:
			lean = -1.5
		CLUB:
			lean = 5.0
		LUNGE_W:
			lean = 4.0
			crouch = 4.0
		LUNGE:
			lean = 7.0
			crouch = 2.0
		B_SWEEP_W:
			lean = -3.0
			crouch = 2.0
		B_SWEEP:
			lean = 5.0
			crouch = 3.0
		B_RIB_W:
			lean = -2.0 - 2.0 * _rib_open
		B_RIB:
			lean = 8.0
			crouch = 2.0
		B_FERRY:
			lean = -2.0 + sin(tt * 6.0) * 0.6
		B_SHED_W:
			lean = -2.0 + sin(tt * 30.0) * 1.2
		B_TOLL:
			lean = -1.0
	var bob := absf(sin(z._walk_phase)) * 1.0
	var hip := Vector2(0, -22.0 + bob * 0.4 + crouch)
	var sh := Vector2(1.0 + lean, -40.0 + bob * 0.5 + crouch * 1.3)
	var head := sh + Vector2(2.5 + lean * 0.3, -10.0)
	var skin := col(z.skin)
	# ---- יד אחורית: בשר (נפוחה, שרירים חשופים). ב-CLUB_W מורמת לאחור, ב-CLUB חובטת קדימה ----
	var hb := sh + Vector2(-4.0, 15.0 + sin(z._walk_phase) * 1.2)
	match state:
		CLUB_W:
			var k := clampf(1.0 - _st / CLUB_WIND, 0.0, 1.0)
			hb = sh + Vector2(-8.0 - 6.0 * k, -6.0 - 10.0 * k)
		CLUB:
			hb = sh + Vector2(16.0, 2.0)
		B_TOLL:
			hb = sh + Vector2(-6.0, -16.0 + sin(tt * 14.0) * 2.0)
	if boss and state in [B_SWEEP_W, B_SWEEP]:
		hb = _oar_hand(sh) + Vector2(-8.0, 3.0)
	_flesh_arm(sh + Vector2(-3.0, 2.0), hb, skin)
	if boss and state == B_TOLL:
		_lantern(hb + Vector2(0, 2), tt, true)
	# ---- רגל אחורית: בשר (מכנס קרוע, שוק חשופה) ----
	var ft0: Vector2 = f[1]
	z._leg(hip + Vector2(-2.5, 0), ft0, col(Art.shade(z.pants, -0.1)), skin, col(z.shoe))
	Art.oval(z, (hip + ft0) * 0.5 + Vector2(-2.0, 2.0), 2.0, 3.6, col(MEAT), 0.2, Art.NONE)
	# ---- גוף: חצי אחורי בשר + בגדים קרועים, חצי קדמי כלוב צלעות ----
	_torso(sh, hip, skin, tt)
	# ---- ראש: עורף בשר עם שיער ואוזן, פנים - גולגולת ----
	_half_head(head, skin, tt)
	# ---- רגל קדמית: עצם (עצם ירך, פיקת ברך, שוקה, עצמות כף רגל) ----
	var ft1: Vector2 = f[0]
	_bone_leg(hip + Vector2(2.0, 0), ft1)
	# ---- יד קדמית: עצם, מושטת אליך ----
	var hf := sh + Vector2(13.0, 7.0 + sin(z._walk_phase + PI) * 1.2)
	match state:
		LUNGE_W, LUNGE:
			hf = sh + Vector2(6.0, 12.0)
		CLUB_W:
			hf = sh + Vector2(8.0, 12.0)
	if boss:
		hf = _oar_hand(sh)
		_oar(hf, tt)
	_bone_arm(sh + Vector2(3.0, 2.0), hf)
	if boss and state != B_TOLL:
		_lantern(hip + Vector2(6.0, 2.0), tt, false)
	# אזהרה
	if state in [CLUB_W, LUNGE_W, B_SWEEP_W, B_RIB_W, B_SHED_W, B_TOLL]:
		var wt := {CLUB_W: CLUB_WIND, LUNGE_W: LUNGE_WIND, B_SWEEP_W: B_SWEEP_WIND, B_RIB_W: RIB_WIND, B_SHED_W: SHED_WIND, B_TOLL: TOLL_T}
		var k2 := clampf(_st / float(wt[state]), 0.0, 1.0)
		DrawBatch.string(z, ThemeDB.fallback_font, head + Vector2(-2, -13 if not boss else -20), "!", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(1.0, 0.35, 0.2, k2))
	end_draw()
	if _ring >= 0.0:
		var kk := _ring / 0.5
		var c: Vector2 = _ring_pos - z.global_position
		DrawBatch.polyline(z, Art.ellipse(c, B_SWEEP_R * 0.6 * kk + 20.0, 10.0 * kk + 3.0, 0.0, 24), Color(0.85, 0.82, 0.7, 0.55 * (1.0 - kk)), 3.0)
	return true


# יד בשר: עבה ונפוחה, שריר חשוף אדום בפצעים, אצבעות נפוחות
func _flesh_arm(s0: Vector2, hand: Vector2, skin: Color) -> void:
	var elbow := Art.joint(s0, hand, 9.5, 10.0, -1.0)
	Art.limb(z, PackedVector2Array([s0, elbow, hand]), 6.4, skin, Art.OUTLINE, true, false)
	var m := s0.lerp(elbow, 0.5)
	Art.oval(z, m, 2.6, 1.8, col(MEAT), (elbow - s0).angle(), Art.NONE)
	DrawBatch.line(z, m + Vector2(-1.5, -0.5), m + Vector2(1.5, 0.6), col(MEAT_D), 0.7)
	Art.disc(z, hand, 3.8, skin)
	if not z.crowded():
		var d := (hand - elbow).normalized()
		for i in 3:
			var a := d.rotated(0.4 + float(i) * 0.4)
			DrawBatch.line(z, hand + d * 1.5, hand + d * 2.0 + a * 4.6, Art.OUTLINE, 2.2)
			DrawBatch.line(z, hand + d * 1.5, hand + d * 2.0 + a * 4.6, skin, 1.4)


# יד עצם: עצם זרוע, מרפק, שתי עצמות אמה, פרק ועצמות אצבעות
func _bone_arm(s0: Vector2, hand: Vector2) -> void:
	var elbow := Art.joint(s0, hand, 9.0, 9.5, -1.0)
	var bn := col(BONE)
	var bd := col(BONE_D)
	DrawBatch.line(z, s0, elbow, col(BONE_S), 3.4)
	DrawBatch.line(z, s0, elbow, bn, 2.2)
	DrawBatch.circle(z, s0, 2.6, bn)
	DrawBatch.circle(z, elbow, 1.9, bd)
	var d := (hand - elbow).normalized()
	var n := d.orthogonal() * 0.9
	DrawBatch.line(z, elbow + n, hand + n, bn, 1.4)
	DrawBatch.line(z, elbow - n, hand - n, bd, 1.2)
	DrawBatch.circle(z, hand, 1.6, bd)
	for i in 4:
		var a := d.rotated(-0.3 + float(i) * 0.28)
		DrawBatch.line(z, hand, hand + a * 5.4, bn, 0.9)
		DrawBatch.circle(z, hand + a * 2.8, 0.55, bd)


# רגל עצם: עצם ירך, פיקה, שוקה ושוקית, עצמות כף הרגל
func _bone_leg(hip: Vector2, foot: Vector2) -> void:
	var ankle := foot + Vector2(0.0, -3.0)
	var knee := Art.joint(hip, ankle, 11.5, 11.5, 1.0)
	var bn := col(BONE)
	var bd := col(BONE_D)
	DrawBatch.line(z, hip, knee, col(BONE_S), 3.6)
	DrawBatch.line(z, hip, knee, bn, 2.4)
	DrawBatch.circle(z, hip, 2.8, bd)
	DrawBatch.circle(z, knee + Vector2(1.2, 0.0), 1.9, bn)   # פיקה
	DrawBatch.line(z, knee + Vector2(0.6, 0.5), ankle + Vector2(0.6, 0), bn, 1.7)
	DrawBatch.line(z, knee + Vector2(-0.9, 0.5), ankle + Vector2(-0.9, 0), bd, 1.1)
	DrawBatch.circle(z, ankle, 1.5, bd)
	for i in 3:
		DrawBatch.line(z, ankle, foot + Vector2(3.0 + float(i) * 1.6, -0.4 + float(i) * 0.2), bn, 0.9)
	DrawBatch.line(z, ankle, foot + Vector2(-2.6, 0.0), bd, 1.4)   # עקב
	# שארית מכנס על הירך האחורית (התפר עובר גם ברגליים)
	DrawBatch.line(z, hip + Vector2(-2.2, 0.0), hip.lerp(knee, 0.5) + Vector2(-2.6, 0.0), col(Art.shade(z.pants, -0.05)), 2.2)


# גוף חצוי: מאחור עור + סמרטוטי בגדים + פצעים, מלפנים חלל עם צלעות, חזה, עמוד שדרה. התפר האדום באמצע
func _torso(sh: Vector2, hip: Vector2, skin: Color, tt: float) -> void:
	var mid_t := Vector2(sh.x + 0.5, sh.y)
	var mid_b := Vector2(hip.x + 0.5, hip.y + 1.5)
	# חצי אחורי: בשר
	var back := PackedVector2Array([sh + Vector2(-8.5, -1.0), mid_t + Vector2(0.5, -1.2), mid_b, hip + Vector2(-8.0, 1.0)])
	Art.fill_shaded(z, back, skin, 0.12, 0.3)
	# סמרטוט חולצה על הגב
	var rag := col(_var[0])
	DrawBatch.colored_polygon(z, PackedVector2Array([sh + Vector2(-8.5, 0.0), mid_t + Vector2(-0.5, 0.5), mid_t + Vector2(-1.5, 9.0), sh + Vector2(-4.0, 12.0), sh + Vector2(-6.5, 8.0), sh + Vector2(-8.8, 13.0)]), rag)
	DrawBatch.line(z, hip + Vector2(-8.0, -1.0), mid_b + Vector2(-0.5, -2.5), col(Color("2a2218")), 2.0)   # חגורה
	for w: Vector2 in _wounds:   # פצעים: הבשר נקרע וחושף עצם
		var p := Vector2(w.x + sh.x * 0.3, w.y + 0.0)
		if p.y < sh.y - 4.0 or p.y > hip.y + 2.0:
			continue
		Art.oval(z, p, 2.4, 1.8, col(MEAT), 0.3, Art.NONE)
		DrawBatch.line(z, p + Vector2(-1.2, 0.2), p + Vector2(1.3, -0.2), col(BONE_D), 0.8)
	# חצי קדמי: חלל כהה, עמוד שדרה לאורך התפר, צלעות מעוקלות, עצם חזה
	var front := PackedVector2Array([mid_t + Vector2(0.5, -1.2), sh + Vector2(8.0, -0.5), hip + Vector2(6.5, -4.0), mid_b])
	DrawBatch.colored_polygon(z, front, col(Color("2a1414")))
	Art.oval(z, sh.lerp(hip, 0.35) + Vector2(3.5, 0.0), 3.0, 4.0, col(Color("4a1a1a")), 0.0, Art.NONE)   # ריאה רקובה
	for q in 6:   # חוליות לאורך התפר
		var p2 := mid_t.lerp(mid_b, float(q) / 5.0) + Vector2(1.2, 0)
		DrawBatch.circle(z, p2, 1.25, col(BONE_D))
	var bn := col(BONE)
	for q in 5:   # צלעות
		var k := float(q) / 4.0
		var a0 := mid_t.lerp(mid_b, 0.08 + k * 0.62) + Vector2(1.5, 0)
		var w0 := lerpf(7.5, 5.5, k)
		var pts := PackedVector2Array([a0, a0 + Vector2(w0 * 0.5, -1.4), a0 + Vector2(w0, 0.6), a0 + Vector2(w0 * 0.9, 2.6)])
		DrawBatch.polyline(z, pts, col(BONE_S), 2.3)
		DrawBatch.polyline(z, pts, bn, 1.4)
	DrawBatch.line(z, sh + Vector2(7.0, 1.0), sh.lerp(hip, 0.55) + Vector2(7.5, 0.0), bn, 1.8)   # עצם החזה
	DrawBatch.line(z, sh + Vector2(1.0, 0.0), sh + Vector2(8.5, -1.5), bn, 2.0)                   # עצם הבריח
	# אגן
	DrawBatch.colored_polygon(z, PackedVector2Array([mid_b + Vector2(0.5, -4.0), mid_b + Vector2(6.0, -5.0), mid_b + Vector2(7.0, -1.0), mid_b + Vector2(1.5, 1.5)]), col(BONE_D))
	# התפר: רצועת בשר קרוע ודם מהצוואר עד המפשעה
	var seam := PackedVector2Array()
	for q in 8:
		var k2 := float(q) / 7.0
		seam.append(mid_t.lerp(mid_b, k2) + Vector2(sin(k2 * 11.0 + float(_var[3])) * 0.8, 0))
	DrawBatch.polyline(z, seam, col(MEAT_D), 3.2)
	DrawBatch.polyline(z, seam, col(MEAT), 1.6)
	var drip := 2.0 + 2.0 * fposmod(tt * 0.6 + float(_var[3]) * 0.3, 1.0)
	DrawBatch.line(z, mid_b + Vector2(0.3, 0), mid_b + Vector2(0.3, drip), GORE, 1.1)
	# בוס: הלב בפנים (זוהר) + צלעות שנפתחות כמו דלתות
	if _boss():
		var hc := sh.lerp(hip, 0.4) + Vector2(4.0, 0.0)
		var beat := 0.5 + 0.5 * sin(tt * (5.0 + 4.0 * _rib_open))
		Art.glow(z, hc, 6.0 + 6.0 * _rib_open, Color(SPORE, 0.25 + 0.4 * _rib_open))
		Art.oval(z, hc, 3.0 + beat * 0.6, 3.6 + beat * 0.6, col(Color(0.62, 0.08, 0.1)), 0.3, Art.NONE)
		DrawBatch.circle(z, hc + Vector2(-0.6, -0.8), 1.2, Color(SPORE, 0.6 + 0.4 * beat))
		if _rib_open > 0.05:   # הצלעות הקדמיות נפתחות החוצה
			for q in 4:
				var k3 := float(q) / 3.0
				var a1 := mid_t.lerp(mid_b, 0.12 + k3 * 0.55) + Vector2(1.5, 0)
				var tip := a1 + Vector2(7.0, 1.0).rotated(-_rib_open * (0.9 + 0.2 * k3)) * (1.0 + 0.6 * _rib_open)
				DrawBatch.line(z, a1, tip, col(BONE_S), 2.6)
				DrawBatch.line(z, a1, tip, bn, 1.6)


# ראש חצוי: מאחור עור עם שיער, אוזן; מלפנים גולגולת - ארובה עם עין ירוקה, חור האף, שיניים בלי שפתיים. התפר באמצע
func _half_head(c: Vector2, skin: Color, tt: float) -> void:
	var tilt := sin(tt * 1.3) * 0.06
	# עורף בשר
	var bk := PackedVector2Array()
	for i in 9:
		var a := PI * 0.5 + float(i) / 8.0 * PI
		bk.append(c + Vector2(cos(a) * 7.2, sin(a) * 8.0).rotated(tilt))
	Art.fill_shaded(z, bk, skin, 0.12, 0.3)
	# שיער פרוע על חצי הקרקפת
	DrawBatch.colored_polygon(z, PackedVector2Array([c + Vector2(0.0, -8.2), c + Vector2(-4.5, -7.0), c + Vector2(-7.4, -3.0), c + Vector2(-7.0, 1.5), c + Vector2(-5.2, -2.0), c + Vector2(-2.0, -4.8), c + Vector2(0.0, -5.4)]), col(z.hair))
	DrawBatch.colored_polygon(z, PackedVector2Array([c + Vector2(-3.6, -0.5), c + Vector2(-1.8, -0.8), c + Vector2(-1.6, 2.6), c + Vector2(-3.5, 2.8)]), col(Art.shade(z.skin, -0.15)))   # אוזן
	# חצי גולגולת
	var fr := PackedVector2Array([c + Vector2(0.0, -8.2), c + Vector2(3.6, -7.4), c + Vector2(6.4, -4.6), c + Vector2(7.4, -1.0), c + Vector2(6.8, 2.4),
		c + Vector2(5.6, 3.4), c + Vector2(5.8, 6.8), c + Vector2(2.4, 7.6), c + Vector2(0.0, 7.0)])
	for i in fr.size():
		fr[i] = c + (fr[i] - c).rotated(tilt)
	Art.fill(z, fr, col(BONE), Art.OUTLINE, 1.1)
	DrawBatch.colored_polygon(z, PackedVector2Array([c + Vector2(0.6, -6.5), c + Vector2(4.0, -6.2), c + Vector2(5.4, -3.6), c + Vector2(1.0, -3.0)]), col(Color(0.96, 0.93, 0.85)))   # ברק
	Art.oval(z, c + Vector2(3.6, -1.0), 2.4, 2.2, col(Color("1a0c0c")), 0.0, Art.NONE)   # ארובה
	DrawBatch.colored_polygon(z, PackedVector2Array([c + Vector2(6.4, 0.6), c + Vector2(7.3, 1.6), c + Vector2(6.0, 2.4)]), col(Color("2a1a14")))   # חור האף
	DrawBatch.colored_polygon(z, PackedVector2Array([c + Vector2(1.5, 3.4), c + Vector2(6.2, 3.0), c + Vector2(6.0, 5.6 + (1.5 if z._bite_anim > 0.0 else 0.0)), c + Vector2(1.8, 5.8)]), col(Color("2a0c0c")))
	for q in 4:   # שיניים
		if q == int(_var[3]):
			continue
		var tx := 2.0 + float(q) * 1.1
		DrawBatch.line(z, c + Vector2(tx, 3.2), c + Vector2(tx, 4.6), col(Color("e8e0c4")), 0.8)
	DrawBatch.line(z, c + Vector2(2.0, 5.8), c + Vector2(6.0, 5.4), col(BONE_D), 1.2)   # לסת
	if _var[2]:
		DrawBatch.line(z, c + Vector2(2.0, -7.0), c + Vector2(4.5, -4.0), col(BONE_S), 0.6)   # סדק
	# התפר בראש
	DrawBatch.line(z, c + Vector2(0.0, -8.4).rotated(tilt), c + Vector2(0.0, 7.4).rotated(tilt), col(MEAT_D), 2.2)
	DrawBatch.line(z, c + Vector2(0.2, -8.0).rotated(tilt), c + Vector2(0.2, 7.0).rotated(tilt), col(MEAT), 0.9)
	if _boss():   # כובע ספן (על חצי הבשר), קצת עקום
		DrawBatch.colored_polygon(z, PackedVector2Array([c + Vector2(-8.5, -4.5), c + Vector2(2.5, -6.5), c + Vector2(1.5, -11.0), c + Vector2(-7.0, -10.0)]), col(Color("1e2230")))
		DrawBatch.line(z, c + Vector2(-9.5, -4.2), c + Vector2(5.5, -7.2), col(Color("101218")), 1.8)
		DrawBatch.line(z, c + Vector2(-6.0, -7.5), c + Vector2(1.5, -8.6), col(Color("b89a40")), 0.9)
	if not z.dead:
		var ec := Color(0.55, 1.0, 0.5)
		if z.has_meta("s57_learned_t"):
			ec = ec.lerp(Color(1.0, 1.0, 0.8), clampf(1.0 - float(Time.get_ticks_msec() - int(z.get_meta("s57_learned_t"))) / 600.0, 0.0, 1.0))
		DrawBatch.circle(z, c + Vector2(3.9, -1.0), 0.95, ec)
		Art.glow(z, c + Vector2(3.9, -1.0), 3.5 + (1.5 if learned() else 0.0), Color(ec, 0.4))


# ---- בוס: משוט מעבורת ארוך (עץ בלוי, להב רחב), ופנס ECHO ירוק על שרשרת ----
func _oar_hand(sh: Vector2) -> Vector2:
	match state:
		B_SWEEP_W:
			var k := clampf(1.0 - _st / B_SWEEP_WIND, 0.0, 1.0)
			return sh + Vector2(-4.0 - 6.0 * k, -6.0 - 6.0 * k)
		B_SWEEP:
			var k2 := clampf(1.0 - _st / B_SWEEP_T, 0.0, 1.0)
			return sh + Vector2(lerpf(-8.0, 14.0, k2), lerpf(-10.0, 10.0, k2))
		B_TOLL:
			return sh + Vector2(10.0, 12.0)
		B_RIB_W, B_RIB, B_FERRY:
			return sh + Vector2(10.0, 14.0)
	return sh + Vector2(11.0, 10.0 + sin(z._walk_phase) * 0.8)


func _oar(hand: Vector2, tt: float) -> void:
	var ang := -1.35 + sin(tt * 0.9) * 0.03
	match state:
		B_SWEEP_W:
			ang = lerpf(-1.35, -2.4, clampf(1.0 - _st / B_SWEEP_WIND, 0.0, 1.0))
		B_SWEEP:
			ang = lerpf(-2.4, 0.75, clampf(1.0 - _st / B_SWEEP_T, 0.0, 1.0))
		B_RECOVER:
			ang = lerpf(-1.35, 0.6, clampf(_st / 0.6, 0.0, 1.0)) if not _rib_recover else -1.35
		B_TOLL:
			ang = -1.57
	var dv := Vector2(cos(ang), sin(ang))
	var tip := hand + dv * 40.0
	var butt := hand - dv * 26.0
	DrawBatch.line(z, butt, tip, col(Color("241a12")), 3.6)
	DrawBatch.line(z, butt, tip, col(Color("6a5238")), 2.2)
	var nv := dv.orthogonal()
	var b0 := tip
	var b1 := tip + dv * 16.0
	DrawBatch.colored_polygon(z, PackedVector2Array([b0 + nv * 1.5, b0 + dv * 4.0 + nv * 4.5, b1 + nv * 4.0, b1 + dv * 2.0, b1 - nv * 4.0, b0 + dv * 4.0 - nv * 4.5, b0 - nv * 1.5]), col(Color("5a4630")))
	DrawBatch.line(z, b0 + dv * 3.0, b1, col(Color("3a2c1e")), 0.8)
	Art.oval(z, b1 - dv * 4.0, 2.2, 1.4, col(Color(0.5, 0.06, 0.06, 0.8)), ang, Art.NONE)   # דם
	if state == B_TOLL:   # נעוץ בקרקע (המשוט נוגע ברצפה)
		DrawBatch.circle(z, butt, 2.0, col(Color("3a2c1e")))


func _lantern(at: Vector2, tt: float, raised: bool) -> void:
	var sway := sin(tt * (9.0 if raised else 2.0)) * (3.0 if raised else 1.5)
	var p := at + Vector2(sway, 9.0)
	DrawBatch.line(z, at, p + Vector2(0, -4.0), col(Color("3a3632")), 0.8)
	DrawBatch.colored_polygon(z, PackedVector2Array([p + Vector2(-3.0, -4.0), p + Vector2(3.0, -4.0), p + Vector2(2.4, 4.0), p + Vector2(-2.4, 4.0)]), col(Color("2a2a26")))
	var pulse := 0.6 + 0.4 * sin(tt * 3.0)
	DrawBatch.colored_polygon(z, PackedVector2Array([p + Vector2(-2.0, -2.6), p + Vector2(2.0, -2.6), p + Vector2(1.6, 3.0), p + Vector2(-1.6, 3.0)]), Color(0.6, 1.0, 0.45, 0.85 * pulse + 0.1))
	Art.glow(z, p, 9.0 + 4.0 * pulse, Color(0.55, 1.0, 0.45, 0.32))


# ============================================================
#  גופה: נקרע לשניים לאורך התפר - ערימת עצמות (צד העצם) וגוש בשר (צד הבשר) עם שלולית דם ביניהם
# ============================================================
func _draw_dead() -> void:
	var a: float = fposmod(z._angle, TAU)
	a = a - PI * 0.5 if a < PI else a - PI * 1.5
	var on_floor: bool = z.is_on_floor()
	var s := Vector2(z._dir * z.wf * z.sc, z.sc)
	DrawBatch.set_transform_matrix(z, Transform2D(a if not on_floor else 0.0, Vector2(0.0, -6.0 * z.sc)) * Transform2D(0.0, s, 0.0, Vector2(0.0, 6.0 * z.sc)))
	var sep := clampf(z._dead_t * 2.0, 0.0, 1.0) * 7.0
	var skin: Color = z.skin
	# שלולית דם
	Art.oval(z, Vector2(0.0, -0.5), 16.0 + sep, 2.0, Color(0.32, 0.03, 0.03, 0.75), 0.0, Art.NONE)
	# צד הבשר (מאחור): גוש גוף שמוטה עם סמרטוט, יד וחצי ראש עם שיער
	var fx := -6.0 - sep
	Art.oval(z, Vector2(fx, -4.0), 11.0, 4.6, skin, 0.05)
	DrawBatch.colored_polygon(z, PackedVector2Array([Vector2(fx - 9.0, -6.0), Vector2(fx + 4.0, -8.5), Vector2(fx + 6.0, -3.0), Vector2(fx - 6.0, -1.5)]), _var[0])
	Art.oval(z, Vector2(fx + 9.0, -4.0), 2.0, 4.0, MEAT, 0.0, Art.NONE)
	Art.oval(z, Vector2(fx - 13.0, -5.0), 5.0, 4.6, skin, 0.0)
	Art.oval(z, Vector2(fx - 14.5, -7.0), 4.0, 2.6, z.hair, 0.0, Art.NONE)
	Art.limb(z, PackedVector2Array([Vector2(fx - 2.0, -2.0), Vector2(fx - 8.0, -0.5), Vector2(fx - 14.0, -1.0)]), 4.6, skin)
	# צד העצם (מלפנים): גולגולת, צלעות מפוזרות, עצמות ארוכות
	var bx := 6.0 + sep
	var bn := BONE
	for q in 4:
		var p := Vector2(bx + float(q) * 3.2, -2.0)
		DrawBatch.polyline(z, PackedVector2Array([p, p + Vector2(2.5, -4.5), p + Vector2(5.0, -2.5)]), BONE_S, 2.2)
		DrawBatch.polyline(z, PackedVector2Array([p, p + Vector2(2.5, -4.5), p + Vector2(5.0, -2.5)]), bn, 1.3)
	DrawBatch.line(z, Vector2(bx - 2.0, -1.0), Vector2(bx + 18.0, -1.5), BONE_D, 1.6)   # עמוד שדרה
	DrawBatch.line(z, Vector2(bx + 6.0, -0.8), Vector2(bx + 22.0, 0.2), bn, 2.2)        # עצם ירך
	DrawBatch.circle(z, Vector2(bx + 22.0, 0.0), 1.6, BONE_D)
	DrawBatch.line(z, Vector2(bx + 2.0, -6.0), Vector2(bx + 14.0, -8.5), bn, 1.6)      # יד
	Art.oval(z, Vector2(bx + 25.0, -4.0), 4.6, 4.2, bn, 0.0)   # גולגולת
	Art.oval(z, Vector2(bx + 26.5, -4.6), 1.4, 1.3, Color("1a0c0c"), 0.0, Art.NONE)
	DrawBatch.line(z, Vector2(bx + 24.0, -1.0), Vector2(bx + 28.5, -1.4), Color("2a0c0c"), 1.2)
	# הקצוות הקרועים של התפר
	DrawBatch.line(z, Vector2(fx + 10.0, -7.0), Vector2(fx + 10.0, -1.0), MEAT_D, 2.0)
	DrawBatch.line(z, Vector2(bx - 3.0, -6.0), Vector2(bx - 3.0, -1.0), MEAT, 1.4)
	if _boss():
		DrawBatch.line(z, Vector2(bx + 30.0, -2.0), Vector2(bx + 64.0, -1.0), Color("6a5238"), 2.4)   # המשוט
		DrawBatch.colored_polygon(z, PackedVector2Array([Vector2(bx + 62.0, -4.0), Vector2(bx + 76.0, -4.5), Vector2(bx + 76.0, 2.0), Vector2(bx + 62.0, 1.5)]), Color("5a4630"))
	end_draw()
