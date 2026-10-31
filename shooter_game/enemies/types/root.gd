extends "res://enemies/zombie_type.gd"
# ============================================================
#  ROOT (שלב 63, "THE HEART") - הבוס האחרון של המשחק. התרבית הראשונה של ECHO: לב-מוח ענק של פטרייה שגדל לתוך הקיר
#    הימני של חדר הלב, מהרצפה עד התקרה. קפלים של מוח, שתי חדרי לב שפועמים (U.beat), עורקים עבים שעולים לתקרה,
#    שורשים שנכנסים לרצפה, ופנים של "נבלעים" שנלחצים מבפנים לקרום. במרכז החזית: הליבה (CORE) - סדק אנכי עם שפתיים
#    של בשר, שנפתח וחושף אור ירוק-לבן. הליבה = נקודת התורפה (x CORE_MULT). הגוף ספוגי (x BODY_MULT).
#  מה הוא למד, וממה: הכל. כל אחד מארבעת השלבים הוא שיעור מאזור אחר במשחק (STORY.md "The story so far, as lessons"):
#    I   "WE WAIT" (Northeast)        - שורשים מתחת לרצפה: גבשושית זוהרת מתחתיך (אזהרה) ואז קוץ ענק. מחפש אותך.
#                                       לומד: קפצת מעל SPIKE_LEARN קוצים -> "IT LEARNED YOUR JUMP": קוץ כפול (שני על הנחיתה).
#    II  "YOUR MACHINES" (Southeast)  - שני תותחי פטרייה (PODS) צומחים מהחזית: מסתובבים (אזהרה), מרססים, ומתחממים
#                                       (פגיעים, הליבה נפתחת). הורסים את שניהם = הליבה נפתחת לגמרי (ואז הם צומחים שוב).
#                                       לומד: מתחבא מאחורי מחסה -> "IT LEARNED YOUR COVER": זורק רימוני נבגים מעל המחסה.
#    III "WE PLAN" (Southern Cone)    - מסמן 3 אזורים על הרצפה: איפה שאתה, לאן שאתה הולך, ולאן שאתה בורח (PlayerMemory)
#                                       ואז הם מתפרצים בזה אחר זה. קורא ל-HOLLOW מהשקים של הזירה (עד 3).
#                                       לומד: זוכר לאן ברחת בפעם הקודמת - האזור השלישי שם ("IT PLANNED FOR THAT").
#    IV  "WE ARE YOU" (Patagonia)     - החזית נפתחת לפנים ענקיות של HOLLOW (ברדס, חלל, שני סדקים). יורה עליך בנשק
#                                       שלך (stage_63 fav_cat), בגודל של בוס: BURSTS = מניפת צרורות, SHOTGUN = פיצוץ
#                                       רחב, AIM = לייזר ארוך וקרן, BLASTS = 3 רימוני נבגים. מחליף עם הנשק השני שלך.
#                                       לומד: אש רצופה על הליבה -> "IT HIDES LIKE YOU": הפנים נסגרות לרגע.
#  השיעורים מהדרך (PILGRIM שהגיעו הביתה, Decor.U.lessons): כל שיעור = עמיד יותר לנשק הזה (RESIST, עד RESIST_MIN).
#    בזירה עצמה PILGRIM ממשיכים לעוף אל הליבה - שיעור שמגיע = עמיד יותר + מתרפא (LEARN_HEAL). יורים בשקים!
#  הוגן: כל התקפה עם אזהרה ברורה. מעבר בין שלבים = 2.2 שניות בלתי פגיע + תחמושת (stage_63.drop_supply).
#    מקרוב (PULSE_R) - הדף: אזהרה (הגוף מתנפח) ואז גל שמעיף אותך אחורה. אין טעם להיצמד.
#  מוות: לא נעלם (corpse_time ענק) - stage_63.root_dead() -> הסוף (effects/s63_ending.gd) מדבר איתו.
#  ביצועים: לא זז (המיקום קבוע), כל הקוצים / התותחים / האזורים / הלייזר מצוירים כאן - draw call אחד.
#    הקליעים: EnemyShot (zombie.gd), רימונים: hollow.gd SporeLob (זז ב-_process).
#  לשנות: HP (stats), BODY_MULT, CORE_MULT, PHASE_AT, SPIKE_*, POD_*, ZONE_*, FACE_*, RESIST*, PULSE_*, ARENA_PG_T.
# ============================================================

const ZScript := preload("res://zombie.gd")
const Decor := preload("res://effects/s63_decor.gd")
const Hollow := preload("res://enemies/types/hollow.gd")
const U := Decor.U

const SOUNDS := {
	"root_roar": {"rev": 0.8, "drive": 2.2, "layers": [["V", 55, 42, 0.0, 2.2, 0.2, 1.0, 0.9, 1.0, 0.05, 0, [300, 700, 6]], ["V", 82, 60, 0.05, 2.1, 0.2, 1.0, 0.6, 1.0, 0.06, 0, [420, 900, 5]], ["N", 0, 0, 0.0, 2.0, 0.3, 1.2, 0.5, 0.08, 0], ["V", 130, 95, 0.1, 1.8, 0.3, 1.4, 0.3, 1.0, 0.04, 0, [600, 1300, 4]]]},
	"root_crack": {"rev": 0.3, "drive": 2.0, "layers": [["N", 0, 0, 0.0, 0.5, 0.0, 6.0, 0.8, 0.25, 0, 0.4], ["S", 70, 40, 0.0, 0.5, 0.0, 6.0, 0.7, 1.0, 0.05]]},
	"root_spike": {"rev": 0.3, "drive": 2.6, "layers": [["N", 0, 0, 0.0, 0.4, 0.0, 8.0, 1.0, 0.4, 0, 0.3], ["S", 110, 45, 0.0, 0.35, 0.0, 9.0, 0.9, 1.0, 0.05], ["N", 0, 0, 0.0, 0.05, 0.0, 80.0, 0.6, 1.0, 0]]},
	"root_spin": [["S", 120, 900, 0.0, 0.8, 0.6, 0.0, 0.16, 1.0, 0.0], ["N", 0, 0, 0.0, 0.8, 0.6, 0.0, 0.1, 0.4, 0, 0.3]],
	"root_vent": [["N", 0, 0, 0.0, 1.2, 0.05, 1.5, 0.5, 0.9, 0, 0.6]],
	"root_open": {"rev": 0.6, "layers": [["N", 0, 0, 0.0, 0.7, 0.1, 3.0, 0.5, 0.2, 0, 0.4], ["S", 180, 90, 0.0, 0.8, 0.1, 2.5, 0.4, 1.0, 0.05], ["S", 880, 1320, 0.1, 0.6, 0.1, 3.0, 0.08, 1.0, 0.02]]},
	"root_mark": [["S", 330, 330, 0.0, 0.25, 0.0, 6.0, 0.25, 0.5, 0], ["S", 247, 247, 0.12, 0.3, 0.0, 6.0, 0.2, 0.5, 0]],
	"root_beam": {"rev": 0.4, "drive": 2.0, "layers": [["S", 2200, 400, 0.0, 0.5, 0.0, 5.0, 0.4, 1.0, 0.1], ["N", 0, 0, 0.0, 0.5, 0.0, 6.0, 0.8, 0.8, 0, 0.3], ["S", 60, 30, 0.0, 0.6, 0.0, 4.0, 0.8, 1.0, 0]]},
	"root_pulse": {"rev": 0.5, "drive": 2.0, "layers": [["S", 50, 30, 0.0, 0.7, 0.0, 4.0, 1.1, 1.0, 0], ["N", 0, 0, 0.0, 0.6, 0.0, 5.0, 0.7, 0.15, 0, 0.3]]},
	"root_learn": {"rev": 0.8, "layers": [["V", 98, 98, 0.0, 1.2, 0.3, 1.6, 0.4, 1.0, 0.03, 0, [500, 900, 5]], ["V", 147, 147, 0.0, 1.2, 0.3, 1.6, 0.3, 1.0, 0.03, 0, [700, 1200, 4]], ["S", 660, 990, 0.2, 0.9, 0.1, 2.0, 0.1, 1.0, 0.02]]},
}

const PHASE_AT := [1.0, 0.75, 0.5, 0.25]         # שלב I מתחיל ב-100%, II ב-75%...
const PHASE_NAME := ["", "LESSON OF THE NORTHEAST", "LESSON OF THE SOUTHEAST", "LESSON OF THE SOUTHERN CONE", "LESSON OF PATAGONIA"]
const PHASE_SUB := ["", "WE WAIT", "YOUR MACHINES", "WE PLAN", "WE ARE YOU"]
const BODY_MULT := 0.35
const CORE_MULT := 1.45
const LEG_NORM := 1.6                              # (מכה נמוכה ב"רגל" - כמו גוף)
const CORE_L := Vector2(-8.0, -250.0)              # הליבה (יחסית לחזית, לא הפוך)
const CORE_R := Vector2(52.0, 80.0)
const HIT_RECT := Rect2(-52.0, -405.0, 412.0, 405.0)
const TRANS_T := 2.2
const INTRO_T := 2.6
const RESIST_STEP := 0.1
const RESIST_MIN := 0.5
const LEARN_HEAL := 45
const PULSE_R := 160.0
const PULSE_TELL := 0.45
const PULSE_CD := 2.6
const ARENA_PG_T := [0.0, 13.0, 12.0, 11.0, 9.0]
# שלב I: קוצים
const SPIKE_TELL := 0.75
const SPIKE_UP := 0.42
const SPIKE_H := 175.0
const SPIKE_W := 30.0
const SPIKE_N := 4
const SPIKE_GAP := 0.62
const SPIKE_LEARN := 3
const OPEN_T := 2.6
# שלב II: תותחים
const POD_L := [Vector2(-46.0, -392.0), Vector2(-40.0, -150.0)]
const POD_HP := 120
const POD_R := 34.0
const POD_SPIN := 0.8
const POD_FIRE := 1.3
const POD_SHOTS := 11
const POD_HEAT := 1.7
const POD_REGROW := 7.0
const POD_SHOT_V := 720.0
const COVER_T := 1.2
# שלב III: תכנון
const ZONE_W := 64.0
const ZONE_TELL := 1.05
const ZONE_GAP := 0.28
const ZONE_H := 210.0
const CALL_T := 17.0
# שלב IV: הפנים
const FACE_TELL := {"auto": 0.7, "shotgun": 0.65, "precision": 1.1, "explosive": 0.7}
const HIDE_DMG := 150
const HIDE_T := 1.4
const BEAM_W := 22.0

enum {DORMANT, INTRO, IDLE, ATTACK, OPEN, TRANS}
var phase := 0
var state := DORMANT
var resist := {"auto": 1.0, "shotgun": 1.0, "precision": 1.0, "explosive": 1.0, "other": 1.0}
var core_k := 0.0                  # 0 סגור .. 1 פתוח
var face_k := 0.0                  # שלב IV: הפנים
var speak := 0.0                   # (הסוף) הליבה זוהרת כשהוא מדבר
var shattered := 0.0               # (הסוף: DESTROY)
var embrace := 0.0                 # (הסוף: JOIN) השורשים נשלחים אליך
var spikes := []                   # {x, t, tell, h, hit}
var zones := []                    # {x, t, tell, hit}
var pods := []                     # {hp, st, t, aim, left, shot_t, dead_t, flash}
# לבדיקות
var spikes_n := 0
var spike_hits := 0
var pod_shots := 0
var pods_killed := 0
var zones_n := 0
var face_shots := 0
var pulses := 0
var learned_jump := false
var learned_cover := false
var learned_plan := false
var learned_hide := false
var core_dmg := 0
var body_dmg := 0
var _st := 0.0
var _t := 0.0
var _volley := 0
var _vol_t := 0.0
var _open_t := 0.0
var _pulse_t := -1.0
var _pulse_cd := 0.0
var _pg_t := 6.0
var _call_t := 0.0
var _jumped := 0
var _cover_t := 0.0
var _lob_cd := 0.0
var _escape := 0.0                 # לאן ברחת (שלב III): -1 שמאלה / 1 ימינה
var _zone_px := 0.0
var _face_mode := "auto"
var _face_st := 0
var _face_t := 0.0
var _face_left := 0
var _face_aim := 0.0
var _beam_t := -1.0
var _beam_a := 0.0
var _hide_t := 0.0
var _dmg_win := []                 # [זמן, נזק] - שלב IV (מסתתר)
var _hit_zone := ""
var _hit_cat := "auto"
var _hit_pos := Vector2.ZERO
var _blast_frame := -1
var _resist_said := 0.0
var _ax0 := 8440.0
var _gx := 0.0                     # רצפה
var _gy := 630.0
var _folds := []                   # קפלי המוח (מחושב פעם אחת)
var _faces := []
var _veins := []
var _said := {}
var _pin := Vector2.ZERO


func stats() -> Dictionary:
	return {"name": "ROOT", "hp": 1200, "walk": 0.0, "chase": 0.0, "damage": 1, "bite_delay": 9.0, "scale": 10.87, "width": 1.0,
		"duck": 0.0, "cover": 0.0, "skin": Color("7a3438"), "shirt": Color("4a1c22"), "pants": Color("24090e"), "shoe": Color("101010"),
		"points": 20000, "boss": true, "boss_name": "THE ROOT", "ragdoll": false, "flesh": true}


func use_brain_movement() -> bool:
	return false


func can_bite() -> bool:
	return false


func can_groan() -> bool:
	return false


func death_sound() -> String:
	return "root_roar"


func _main() -> Node:
	return z.get_parent()


func _stage() -> Node:
	var m := _main()
	return m.get("_stage") if m != null else null


func setup() -> void:
	z.add_to_group("s63_root")
	z.add_to_group("blastable")
	z._dir = -1.0
	z.z_index = 1
	var rs := z._shape.shape as RectangleShape2D
	rs.size = HIT_RECT.size
	z._shape.position = HIT_RECT.get_center()
	_gy = z.global_position.y
	var st := _stage()
	if st != null:
		_ax0 = float(st.ARENA_X0)
		z.global_position.x = float(st.ROOT_X)   # (main.gd שם את הבוס ב-level_w - 480)
	var r := RandomNumberGenerator.new()
	r.seed = 6363
	# קפלי מוח: קווים מתפתלים על הגוף
	for i in 11:
		var y0 := -60.0 - float(i) * 52.0 + r.randf_range(-10.0, 10.0)
		var pts := []
		var x := -30.0 + absf(float(i) - 5.0) * 6.0 + r.randf_range(0.0, 20.0)
		while x < 560.0:
			pts.append(Vector2(x, y0 + sin(x * 0.03 + float(i)) * 16.0 + r.randf_range(-6.0, 6.0)))
			x += r.randf_range(40.0, 70.0)
		_folds.append(pts)
	for i in 6:
		_faces.append(Vector2(r.randf_range(60.0, 420.0), r.randf_range(-560.0, -90.0)))
	for i in 5:
		_veins.append([Vector2(r.randf_range(-20.0, 200.0), r.randf_range(-520.0, -80.0)), r.randf_range(0.0, TAU)])
	pods = [{"hp": POD_HP, "st": "off", "t": 0.0, "aim": PI, "left": 0, "shot_t": 0.0, "dead_t": 0.0, "flash": 0.0, "grow": 0.0},
		{"hp": POD_HP, "st": "off", "t": 0.0, "aim": PI, "left": 0, "shot_t": 0.0, "dead_t": 0.0, "flash": 0.0, "grow": 0.0}]
	# שיעורים שכבר הגיעו הביתה בדרך
	for c in Decor.U.lessons.keys():
		for i in int(Decor.U.lessons[c]):
			_harden(str(c))


func core_world() -> Vector2:
	return z.global_position + CORE_L


func face_x() -> float:
	return z.global_position.x


func _harden(cat: String) -> void:
	if not resist.has(cat):
		return
	resist[cat] = maxf(RESIST_MIN, float(resist[cat]) - RESIST_STEP)


# PILGRIM הגיע (stage_63.lesson_home)
func learn(cat: String) -> void:
	_harden(cat)
	if z.dead or phase == 0:
		return
	z.hp = mini(z.max_hp, z.hp + LEARN_HEAL)
	_text("IT LEARNED YOUR " + String(Decor.CAT_NAME.get(cat, "TRICKS")), Decor.CAT_COL.get(cat, Decor.ECHO), core_world() + Vector2(-120, -170), 20)
	Sfx.play("root_learn", core_world(), 0.0, 0.0, 1)


func _text(t: String, c: Color, pos: Vector2, size := 18, life := 1.4) -> void:
	var p = ZScript.HitText.new()
	p.text = t
	p.color = c
	p.size = size
	if "life" in p:
		p.life = life
	_main().add_child(p)
	p.global_position = pos + Vector2(0.0, 70.0)   # (הטקסט עולה למעלה - שלא ייגמר מתחת ל-HUD)


func _cam(pl: Node, on: bool) -> void:
	var cam = pl.get_viewport().get_camera_2d()
	if cam == null or not ("frame_target" in cam):
		return
	if on:
		cam.frame_target = z
		cam.frame_half = 140.0
	elif cam.frame_target == z:
		cam.frame_target = null


func _shake(s: float, t: float) -> void:
	var cam: Camera2D = z.get_viewport().get_camera_2d()
	if cam != null and cam.has_method("shake"):
		cam.shake(s, t)


# ============================================================
#  לולאה
# ============================================================
func physics(pl: Node, delta: float) -> bool:
	_t += delta
	z.velocity = Vector2.ZERO
	if z.dead:
		return false
	var has: bool = pl != null and not pl.dead
	core_k = move_toward(core_k, 1.0 if _core_open() else 0.0, delta * (3.0 if _core_open() else 4.5))
	face_k = move_toward(face_k, 1.0 if phase == 4 and state != TRANS else (face_k if phase == 4 else 0.0), delta * 0.8)
	_tick_spikes(pl, has, delta)
	_tick_zones(pl, has, delta)
	if _beam_t >= 0.0:
		_beam_t += delta
		if _beam_t > 0.3:
			_beam_t = -1.0
	if state == DORMANT:
		if has and pl.global_position.x > _ax0 + 150.0:
			state = INTRO
			_st = INTRO_T
			_cam(pl, true)
			Sfx.play("root_roar", core_world(), 4.0, 0.0, 1)
			_shake(10.0, 1.0)
			_text("IT LEARNED YOU", Color("ff6a5a"), core_world() + Vector2(-300, -120), 30, 2.4)
			var known := ""
			for c in Decor.CATS:
				var n := int(Decor.U.lessons.get(c, 0))
				if n > 0:
					known += ("   " if known != "" else "") + String(Decor.CAT_NAME[c]) + " x" + str(n)
			if known != "":
				_text("IT ALREADY KNOWS:  " + known, Decor.ECHO, core_world() + Vector2(-300, -70), 16, 3.0)
			U.say(pl, "There you are. The first one. The ROOT.", Color("ffb0a0"))
		return true
	if not has:
		return true
	if state == INTRO:
		_st -= delta
		if _st <= 0.0:
			_begin_phase(1)
		return true
	if Engine.get_physics_frames() % 20 == 0:
		_cam(pl, true)
	# מעבר שלב (החיים ירדו מתחת לסף)
	if state != TRANS and phase < 4 and float(z.hp) <= float(z.max_hp) * float(PHASE_AT[phase]):
		z.hp = int(float(z.max_hp) * float(PHASE_AT[phase]))
		_start_trans()
	if state == TRANS:
		_st -= delta
		if _st <= 0.0:
			_begin_phase(phase + 1)
		return true
	_pulse(pl, delta)
	_pilgrims(delta)
	match phase:
		1:
			_phase1(pl, delta)
		2:
			_phase2(pl, delta)
		3:
			_phase3(pl, delta)
		4:
			_phase4(pl, delta)
	return true


func _core_open() -> bool:
	if z.dead:
		return speak > 0.3 and shattered <= 0.0
	if state == OPEN:
		return true
	if phase == 2:
		for p in pods:
			if str(p.st) == "heat" or str(p.st) == "dead":
				return true
	if phase == 4:
		return _hide_t <= 0.0 and state != TRANS
	return false


func _start_trans() -> void:
	state = TRANS
	_st = TRANS_T
	spikes.clear()
	zones.clear()
	_beam_t = -1.0
	for p in pods:
		p.st = "off" if str(p.st) != "dead" else "dead"
	Sfx.play("root_roar", core_world(), 3.0, 0.0, 1, 0.9)
	_shake(12.0, 1.2)
	var nx := phase + 1
	_text(PHASE_NAME[nx], Color("ffd0c0"), core_world() + Vector2(-320, -150), 20, 2.2)
	_text(PHASE_SUB[nx], Color("ff6a5a"), core_world() + Vector2(-320, -110), 30, 2.2)
	var st := _stage()
	if st != null and st.has_method("drop_supply"):
		st.drop_supply("health" if nx == 4 else "ammo")
	if Art.on_screen(z, core_world(), 0.0):
		Particles.burst(_main(), core_world(), "hit", Vector2.LEFT, int(16.0 * Quality.gore()))


func _begin_phase(n: int) -> void:
	phase = n
	state = IDLE
	_st = 0.9
	_volley = 0
	_vol_t = 0.0
	match n:
		1:
			_text(PHASE_NAME[1], Color("ffd0c0"), core_world() + Vector2(-320, -150), 20, 2.2)
			_text(PHASE_SUB[1], Color("ff6a5a"), core_world() + Vector2(-320, -110), 30, 2.2)
		2:
			for p in pods:
				p.hp = POD_HP
				p.st = "grow"
				p.t = 0.0
				p.grow = 0.0
			var pl := player()
			if pl != null:
				U.say(pl, "Guns. It grew guns. It learned that from me too.", Color("ffb0a0"))
		3:
			_call_t = 2.0
		4:
			_face_mode = _fav(0)
			_face_st = 0
			_face_t = 1.2
			var pl := player()
			if pl != null:
				U.say(pl, "That's my face. It's wearing my FACE.", Color("ffb0a0"))


func _fav(rank: int) -> String:
	var st := _stage()
	if st != null and st.has_method("fav_cat"):
		return str(st.fav_cat(rank))
	return "auto"


# הדף מקרוב
func _pulse(pl: Node, delta: float) -> void:
	_pulse_cd -= delta
	var near: bool = pl.global_position.x > face_x() - PULSE_R
	if _pulse_t < 0.0:
		if near and _pulse_cd <= 0.0:
			_pulse_t = 0.0
			Sfx.play("root_crack", core_world() + Vector2(0, 150), -2.0, 0.0, 1)
		return
	_pulse_t += delta
	if _pulse_t >= PULSE_TELL and _pulse_t - delta < PULSE_TELL:
		pulses += 1
		Sfx.play("root_pulse", core_world(), 2.0, 0.0, 1)
		_shake(7.0, 0.3)
		if pl.global_position.x > face_x() - PULSE_R - 30.0:
			pl.hurt(1, Vector2(-2.2, -0.6))
			pl.velocity.x = -620.0
			pl.velocity.y = -260.0
		for zz in z.get_tree().get_nodes_in_group("s63_hollows"):
			if not zz.dead and zz.global_position.x > face_x() - PULSE_R:
				zz.velocity.x = -500.0
	if _pulse_t > PULSE_TELL + 0.4:
		_pulse_t = -1.0
		_pulse_cd = PULSE_CD


# PILGRIM עפים אל הליבה
func _pilgrims(delta: float) -> void:
	_pg_t -= delta
	if _pg_t > 0.0:
		return
	_pg_t = float(ARENA_PG_T[phase]) * randf_range(0.85, 1.15)
	var st := _stage()
	if st == null or not st.has_method("spawn_pilgrim"):
		return
	var ms := []
	for m in z.get_tree().get_nodes_in_group("s63_mouths"):
		if m.global_position.x > _ax0:
			ms.append(m)
	if ms.is_empty():
		return
	var m = ms[randi() % ms.size()]
	var cat := _fav(0) if randf() < 0.6 else _fav(1)
	if st.spawn_pilgrim(m.global_position + Vector2(0, 30), cat, true) != null:
		m.pulse()
		if not _said.has("pg"):
			_said["pg"] = true
			var pl := player()
			if pl != null:
				U.say(pl, "They're feeding it lessons. Shoot the sacs before they reach the heart!", Color("c8ffb0"))


# ============================================================
#  שלב I: קוצים מתחת לרצפה
# ============================================================
func _phase1(pl: Node, delta: float) -> void:
	_attack_spikes(pl, delta, SPIKE_N, SPIKE_GAP)


func _attack_spikes(pl: Node, delta: float, n: int, gap: float) -> void:
	match state:
		IDLE:
			_st -= delta
			if _st <= 0.0:
				state = ATTACK
				_volley = n
				_vol_t = 0.0
		ATTACK:
			_vol_t -= delta
			if _vol_t <= 0.0 and _volley > 0:
				_volley -= 1
				_vol_t = gap
				var lead := float(pl.velocity.x) * (0.3 if learned_jump else 0.15)
				_spike(pl.global_position.x + lead, SPIKE_TELL * (0.85 if learned_jump else 1.0))
				if learned_jump:   # שני על הנחיתה
					_spike(pl.global_position.x + lead, SPIKE_TELL + 0.38, true)
			if _volley <= 0 and spikes.is_empty():
				_open(OPEN_T)
		OPEN:
			_open_t -= delta
			if _open_t <= 0.0:
				state = IDLE
				_st = 0.8


func _open(t: float) -> void:
	state = OPEN
	_open_t = t
	Sfx.play("root_open", core_world(), 0.0, 0.0, 1)
	if not _said.has("open"):
		_said["open"] = true
		var pl := player()
		if pl != null:
			U.say(pl, "The core! It opened - hit the light!", Color("c8ffb0"))


func _spike(x: float, tell: float, second := false) -> void:
	x = clampf(x, _ax0 + 50.0, face_x() - 70.0)
	spikes.append({"x": x, "t": 0.0, "tell": tell, "h": 0.0, "hit": false, "dodge": false, "second": second})
	spikes_n += 1


func _tick_spikes(pl: Node, has: bool, delta: float) -> void:
	if spikes.is_empty():
		return
	var i := spikes.size() - 1
	while i >= 0:
		var s: Dictionary = spikes[i]
		var t0: float = s.t
		s.t = t0 + delta
		var tell: float = s.tell
		if t0 < tell and float(s.t) >= tell:
			Sfx.play("root_spike", Vector2(float(s.x), _gy), -1.0, 0.1, 3)
			if Art.on_screen(z, Vector2(float(s.x), _gy), 0.0):
				Particles.burst(_main(), Vector2(float(s.x), _gy - 6.0), "hit", Vector2.UP, int(6.0 * Quality.gore()) + 1)
		var k: float = float(s.t) - tell
		if k < 0.0:
			s.h = 0.0
		elif k < SPIKE_UP:
			s.h = SPIKE_H * minf(1.0, k / 0.09)
		else:
			s.h = SPIKE_H * maxf(0.0, 1.0 - (k - SPIKE_UP) / 0.25)
		if has and k >= 0.0 and k < SPIKE_UP and not bool(s.hit):
			var r := Rect2(float(s.x) - SPIKE_W, _gy - float(s.h), SPIKE_W * 2.0, float(s.h))
			if r.intersects(pl.body_rect()):
				s.hit = true
				spike_hits += 1
				pl.hurt(1, Vector2(signf(pl.global_position.x - float(s.x) + 0.01), -1.0))
				pl.velocity.y = -420.0
			elif not bool(s.dodge) and not pl.is_on_floor() and absf(pl.global_position.x - float(s.x)) < 70.0:
				s.dodge = true
				_jumped += 1
				if not learned_jump and _jumped >= SPIKE_LEARN:
					learned_jump = true
					_text("IT LEARNED YOUR JUMP", Color("ff8a7a"), Vector2(float(s.x), _gy - 230.0), 18)
					Sfx.play("root_learn", core_world(), -2.0, 0.0, 1)
		if k > SPIKE_UP + 0.3:
			spikes.remove_at(i)
		i -= 1


# ============================================================
#  שלב II: תותחי פטרייה
# ============================================================
func pod_world(i: int) -> Vector2:
	return z.global_position + POD_L[i]


func _phase2(pl: Node, delta: float) -> void:
	# קוץ מדי פעם (השיעור הקודם לא נשכח)
	_vol_t -= delta
	if _vol_t <= 0.0:
		_vol_t = randf_range(3.5, 5.0)
		_spike(pl.global_position.x, SPIKE_TELL)
	if state == OPEN:
		_open_t -= delta
		if _open_t <= 0.0:
			state = IDLE
	var active := -1
	for i in pods.size():
		var p: Dictionary = pods[i]
		p.flash = maxf(0.0, float(p.flash) - delta)
		p.t = float(p.t) + delta
		match str(p.st):
			"grow":
				p.grow = minf(1.0, float(p.grow) + delta / 1.2)
				if float(p.grow) >= 1.0:
					p.st = "off"
					p.t = randf_range(0.0, 0.6) + float(i) * 1.6
			"spin", "fire":
				active = i
		if str(p.st) == "dead":
			p.dead_t = float(p.dead_t) + delta
			if float(p.dead_t) > POD_REGROW and state != OPEN:
				p.hp = int(POD_HP * 0.7)
				p.st = "grow"
				p.grow = 0.0
				p.dead_t = 0.0
		elif str(p.st) == "heat":
			if float(p.t) > POD_HEAT:
				p.st = "off"
				p.t = 0.0
	# התותח הבא (אחד בכל פעם, לסירוגין)
	if active < 0 and state != OPEN:
		for i in pods.size():
			var p: Dictionary = pods[i]
			if str(p.st) == "off" and float(p.t) > 1.0:
				p.st = "spin"
				p.t = 0.0
				p.aim = (pl.global_position + Vector2(0, -30) - pod_world(i)).angle()
				Sfx.play("root_spin", pod_world(i), -2.0, 0.0, 2)
				break
	for i in pods.size():
		var p: Dictionary = pods[i]
		var st := str(p.st)
		if st == "spin" or st == "fire":
			var want: float = (pl.global_position + Vector2(0, -32) - pod_world(i)).angle()
			p.aim = lerp_angle(float(p.aim), want, delta * (2.2 if st == "spin" else 1.5))
		if st == "spin" and float(p.t) > POD_SPIN:
			p.st = "fire"
			p.t = 0.0
			p.left = POD_SHOTS
			p.shot_t = 0.0
		elif st == "fire":
			p.shot_t = float(p.shot_t) - delta
			if float(p.shot_t) <= 0.0 and int(p.left) > 0:
				p.shot_t = POD_FIRE / float(POD_SHOTS)
				p.left = int(p.left) - 1
				_pod_fire(i, float(p.aim))
			if int(p.left) <= 0:
				p.st = "heat"
				p.t = 0.0
				Sfx.play("root_vent", pod_world(i), -2.0, 0.0, 2)
	# מתחבא מאחורי מחסה? זורק מעליו
	_lob_cd -= delta
	if _hiding(pl):
		_cover_t += delta
		if _cover_t > COVER_T and _lob_cd <= 0.0:
			_lob_cd = 2.2
			if not learned_cover:
				learned_cover = true
				_text("IT LEARNED YOUR COVER", Color("ff8a7a"), pl.global_position + Vector2(0, -170), 18)
			_lob_at(pl.global_position.x)
	else:
		_cover_t = maxf(0.0, _cover_t - delta * 2.0)


func _pod_fire(i: int, a: float) -> void:
	pod_shots += 1
	var b = ZScript.EnemyShot.new()
	_main().add_child(b)
	var mz := pod_world(i) + Vector2.from_angle(a) * 52.0
	b.global_position = mz
	b.velocity = Vector2.from_angle(a + randf_range(-0.05, 0.05)) * POD_SHOT_V
	b.life = 2.0
	Sfx.play("rifle", mz, -9.0, 0.15, 3, 0.6)
	pods[i].flash = 0.06


func _hiding(pl: Node) -> bool:
	if not pl._crouching:
		return false
	var px: float = pl.global_position.x
	for c in z.get_tree().get_nodes_in_group("cover"):
		if not c.has_method("cover_rect"):
			continue
		var r: Rect2 = c.cover_rect()
		if r.position.x > px and r.position.x - px < 70.0:   # המחסה בינך לבינו
			return true
	return false


func _lob_at(x: float) -> void:
	var g = Hollow.SporeLob.new()
	_main().add_child(g)
	var from: Vector2 = z.global_position + Vector2(-40.0, -470.0)
	g.global_position = from
	g.ground = _gy
	g.land_x = x
	var tt := 1.1
	g.vel = Vector2((x - from.x) / tt, (_gy - 10.0 - from.y - 0.5 * Hollow.SporeLob.G * tt * tt) / tt)
	Sfx.play("ho_lob", from, 0.0, 0.1, 2, 0.7)


# ============================================================
#  שלב III: תכנון
# ============================================================
func _phase3(pl: Node, delta: float) -> void:
	_call_t -= delta
	if _call_t <= 0.0:
		_call_t = CALL_T
		var st := _stage()
		if st != null and st.has_method("wake_arena") and st.wake_arena(2) > 0:
			Sfx.play("root_roar", core_world(), -4.0, 0.0, 1, 1.2)
			if not _said.has("call"):
				_said["call"] = true
				_text("IT CALLS ITS CHILDREN", Color("ff8a7a"), core_world() + Vector2(-320, -60), 18)
	match state:
		IDLE:
			_st -= delta
			if _st <= 0.0:
				_plan(pl)
		ATTACK:
			if zones.is_empty():
				# לאן ברחת? (השיעור לפעם הבאה)
				var dx: float = pl.global_position.x - _zone_px
				if absf(dx) > 60.0:
					_escape = signf(dx)
				_open(2.3)
		OPEN:
			_open_t -= delta
			if _open_t <= 0.0:
				state = IDLE
				_st = 0.7


func _plan(pl: Node) -> void:
	state = ATTACK
	var px: float = pl.global_position.x
	_zone_px = px
	var v: float = pl.velocity.x
	var go := px + clampf(v, -320.0, 320.0) * 0.9
	if absf(go - px) < 110.0:
		go = px + (130.0 if randf() < 0.5 else -130.0)
	var back := px - signf(go - px) * 200.0
	if _escape != 0.0 and learned_plan:   # זוכר לאן ברחת
		back = px + _escape * 210.0
	elif _escape != 0.0 and randf() < 0.6:
		learned_plan = true
		back = px + _escape * 210.0
	var xs := [px, go, back]
	if PlayerMemory.retreat_dir != 0.0 and not learned_plan:
		xs[2] = px + signf(PlayerMemory.retreat_dir) * 210.0
	for i in 3:
		zones.append({"x": clampf(float(xs[i]), _ax0 + 50.0, face_x() - 70.0), "t": -float(i) * ZONE_GAP, "tell": ZONE_TELL, "hit": false, "said": false})
		zones_n += 1
	Sfx.play("root_mark", core_world(), -2.0, 0.0, 1)


func _tick_zones(pl: Node, has: bool, delta: float) -> void:
	if zones.is_empty():
		return
	var i := zones.size() - 1
	while i >= 0:
		var zn: Dictionary = zones[i]
		var t0: float = zn.t
		zn.t = t0 + delta
		var tell: float = zn.tell
		if t0 < tell and float(zn.t) >= tell:
			Sfx.play("root_spike", Vector2(float(zn.x), _gy), 0.0, 0.1, 3, 0.8)
			_shake(5.0, 0.2)
		var k: float = float(zn.t) - tell
		if has and k >= 0.0 and k < 0.4 and not bool(zn.hit):
			var r := Rect2(float(zn.x) - ZONE_W, _gy - ZONE_H, ZONE_W * 2.0, ZONE_H)
			if r.intersects(pl.body_rect()):
				zn.hit = true
				pl.hurt(1, Vector2(signf(pl.global_position.x - float(zn.x) + 0.01), -1.0))
				pl.velocity.y = -380.0
				if learned_plan and i == 2 and not _said.has("plan"):
					_said["plan"] = true
					_text("IT PLANNED FOR THAT", Color("ff8a7a"), pl.global_position + Vector2(0, -170), 18)
		if k > 0.75:
			zones.remove_at(i)
		i -= 1


# ============================================================
#  שלב IV: הפנים שלך
# ============================================================
func _phase4(pl: Node, delta: float) -> void:
	_hide_t -= delta
	# קוצים ואזורים ממשיכים (מהר יותר)
	_vol_t -= delta
	if _vol_t <= 0.0:
		_vol_t = randf_range(4.0, 5.5)
		if randf() < 0.5:
			_spike(pl.global_position.x, SPIKE_TELL * 0.9)
		else:
			_plan(pl)
			state = IDLE
	_call_t -= delta
	if _call_t <= 0.0:
		_call_t = CALL_T * 1.3
		var st := _stage()
		if st != null and st.has_method("wake_arena"):
			st.wake_arena(1)
	_face_t -= delta
	var face := core_world() + Vector2(-20.0, -10.0)
	match _face_st:
		0:   # מחכה
			if _face_t <= 0.0:
				_face_st = 1
				_face_t = float(FACE_TELL.get(_face_mode, 0.7))
				_face_aim = (pl.global_position + Vector2(0, -30) - face).angle()
				Sfx.play("ho_tell", face, 2.0, 0.0, 2, 0.5)
		1:   # אזהרה: הסדקים בוערים בצבע הנשק
			_face_aim = lerp_angle(_face_aim, (pl.global_position + Vector2(0, -30) - face).angle(), delta * (1.6 if _face_mode == "precision" else 3.0))
			if _face_t <= 0.0:
				_face_st = 2
				_face_left = {"auto": 3, "shotgun": 1, "precision": 1, "explosive": 3}.get(_face_mode, 1)
				_face_t = 0.0
		2:   # יורה
			if _face_t <= 0.0 and _face_left > 0:
				_face_left -= 1
				_face_fire(pl, face)
				_face_t = 0.42 if _face_mode == "auto" else 0.3
			if _face_left <= 0 and _face_t <= 0.0:
				_face_st = 0
				_face_t = randf_range(1.4, 2.0)
				var a := _fav(0)
				var b := _fav(1)
				_face_mode = b if _face_mode == a else a
	# אש רצופה על הליבה -> מסתתר
	var now := _t
	while not _dmg_win.is_empty() and now - float(_dmg_win[0][0]) > 1.2:
		_dmg_win.pop_front()


func _face_fire(pl: Node, face: Vector2) -> void:
	face_shots += 1
	var cc: Color = Decor.CAT_COL.get(_face_mode, Decor.ECHO)
	match _face_mode:
		"auto":   # מניפה של 4 + שורה מקבילה
			for j in 4:
				for row in 2:
					var b = ZScript.EnemyShot.new()
					_main().add_child(b)
					b.global_position = face + Vector2(0, float(row) * 14.0 - 7.0)
					b.velocity = Vector2.from_angle(_face_aim + (float(j) - 1.5) * 0.07) * 780.0
					b.life = 2.0
			Sfx.play("rifle", face, -2.0, 0.1, 2, 0.55)
		"shotgun":
			for j in 9:
				var b = ZScript.EnemyShot.new()
				_main().add_child(b)
				b.global_position = face
				b.velocity = Vector2.from_angle(_face_aim + lerpf(-0.36, 0.36, float(j) / 8.0)) * 760.0
				b.life = 0.8
			Sfx.play("shotgun", face, 0.0, 0.1, 2, 0.6)
			_shake(5.0, 0.2)
		"precision":   # קרן: מה שעל הקו נפגע (מלבד מי שמתגלגל)
			_beam_t = 0.0
			_beam_a = _face_aim
			Sfx.play("root_beam", face, 2.0, 0.0, 1)
			_shake(8.0, 0.25)
			var dir := Vector2.from_angle(_face_aim)
			var r: Rect2 = pl.body_rect().grow(BEAM_W * 0.5 - 4.0)
			var hit := false
			for q in 70:
				if r.has_point(face + dir * float(q) * 20.0):
					hit = true
					break
			if hit and float(pl._roll_t) <= 0.0:
				pl.hurt(1, Vector2(signf(dir.x), -0.4))
		"explosive":
			_lob_at(pl.global_position.x + float(pl.velocity.x) * 0.3 + randf_range(-120.0, 120.0))
	if Art.on_screen(z, face, 0.0):
		Particles.burst(_main(), face, "spark", Vector2.from_angle(_face_aim), 3)
	if face_shots == 1:
		_text("IT USES YOUR " + String(Decor.CAT_NAME.get(_face_mode, "GUN")) + " NOW", cc, core_world() + Vector2(-330, -140), 20)


# ============================================================
#  נזק
# ============================================================
func blast_rect() -> Rect2:
	return Rect2(z.global_position + HIT_RECT.position, HIT_RECT.size)


# פיצוץ שפגע בגוף הענק (רחוק מ"כפות הרגליים" - explosion.gd בודק רק אותן)
func hit_by_blast(center: Vector2, _r: float) -> void:
	if z.dead or phase == 0:
		return
	var zc: Vector2 = z.global_position + Vector2(0, -32)
	if center.distance_to(zc) < 100.0:   # (הלולאה של הזומבים תפגע בו בעצמה)
		return
	_blast_frame = Engine.get_physics_frames()
	z.take_damage(40, center, Vector2.RIGHT, true, {"source": "grenade", "blast": -1})


func on_damage(_amount: int, hit_pos: Vector2, dir: Vector2, src: Dictionary) -> bool:
	if z.dead:
		return true
	_hit_pos = hit_pos
	_hit_cat = Decor.cat_of_src(src)
	if state == DORMANT or state == INTRO or state == TRANS:
		if z._time - float(z.get_meta("ne_t", -9.0)) > 0.5:
			z.set_meta("ne_t", z._time)
			_text("..." if state != TRANS else "IT IS CHANGING", Color(0.8, 0.8, 0.8), hit_pos + Vector2(0, -20), 13)
		return false
	var s := str(src.get("source", "bullet"))
	var blast := not (s in ["bullet", "melee", "laser", "taser"])
	_hit_zone = "body"
	if blast:
		if int(src.get("blast", 0)) != -1 and _blast_frame == Engine.get_physics_frames():
			return false   # (כבר נפגע מהפיצוץ הזה)
		if core_k > 0.5 and hit_pos.distance_to(core_world()) < 150.0:
			_hit_zone = "core"
		return true
	# תותחים (שלב II)
	if phase == 2:
		for i in pods.size():
			var p: Dictionary = pods[i]
			var ps := str(p.st)
			if ps == "dead" or ps == "grow" and float(p.grow) < 0.5:
				continue
			if hit_pos.distance_to(pod_world(i)) < POD_R + 6.0:
				var d := hit_damage(_amount, hit_pos, src)
				if ps == "heat":
					d *= 2
				p.hp = int(p.hp) - d
				p.flash = 0.08
				Particles.burst(_main(), hit_pos, "hit", -dir, 3)
				Sfx.play("hit", hit_pos, -4.0, 0.15, 3)
				if int(p.hp) <= 0:
					_kill_pod(i)
				return false
	var rel := (hit_pos - core_world()) / CORE_R
	if core_k > 0.5 and rel.length() < 1.15:
		_hit_zone = "core"
	elif dir != Vector2.ZERO and core_k > 0.5:   # קליע שנכנס לליבה מזווית
		var c := core_world() - hit_pos
		if c.dot(dir) > 0.0 and absf(c.cross(dir.normalized())) < CORE_R.x * 0.9 and c.length() < 140.0:
			_hit_zone = "core"
	return true


func _kill_pod(i: int) -> void:
	var p: Dictionary = pods[i]
	p.st = "dead"
	p.dead_t = 0.0
	pods_killed += 1
	Sfx.play("root_crack", pod_world(i), 2.0, 0.0, 2)
	Particles.burst(_main(), pod_world(i), "hit", Vector2.LEFT, int(14.0 * Quality.gore()) + 2)
	Particles.burst(_main(), pod_world(i), "smoke", Vector2.UP, 5)
	_text("GUN DOWN", Color("ffd0a0"), pod_world(i) + Vector2(-40, -40), 16)
	var all := true
	for q in pods:
		all = all and str(q.st) == "dead"
	if all:
		_open(3.6)
		_text("THE MACHINES ARE BROKEN", Color("c8ffb0"), core_world() + Vector2(-330, -120), 18)


func damage_mult(zone: String, _src: Dictionary) -> float:
	var m := CORE_MULT if _hit_zone == "core" else BODY_MULT
	if zone == "leg" and _hit_zone != "core":
		m *= LEG_NORM
	var r := float(resist.get(_hit_cat, 1.0))
	if r < 0.99 and _t - _resist_said > 0.7:
		_resist_said = _t
		_text("RESISTED", Decor.CAT_COL.get(_hit_cat, Color.WHITE), _hit_pos + Vector2(-10, -24), 12)
	m *= r
	if _hit_zone == "core":
		core_dmg += 1
		if phase == 4:
			_dmg_win.append([_t, 14.0 * m])
			var tot := 0.0
			for e in _dmg_win:
				tot += float(e[1])
			if tot > HIDE_DMG and _hide_t <= 0.0:
				_hide_t = HIDE_T
				_dmg_win.clear()
				Sfx.play("root_crack", core_world(), 0.0, 0.0, 1)
				if not learned_hide:
					learned_hide = true
					_text("IT HIDES LIKE YOU", Color("ff8a7a"), core_world() + Vector2(-300, -120), 18)
	else:
		body_dmg += 1
	_hit_zone = ""
	return m


func on_death() -> void:
	z.corpse_time = 1.0e9
	_pin = z.global_position
	z.call_deferred("set_physics_process", false)   # לא עף ולא נופל: stage_63 קורא ל-tick_dead()
	spikes.clear()
	zones.clear()
	_beam_t = -1.0
	_shake(18.0, 1.6)
	var pl := player()
	if pl != null:
		_cam(pl, true)
	Particles.burst(_main(), core_world(), "hit", Vector2.LEFT, int(30.0 * Quality.gore()) + 4)
	Particles.burst(_main(), core_world(), "mist", Vector2.UP, 10)
	var st := _stage()
	if st != null and st.has_method("root_dead"):
		st.root_dead()


func wants_redraw() -> bool:
	return true


# (מת - stage_63 / הסוף) נשאר במקום ומצויר
func tick_dead(delta: float) -> void:
	_t += delta
	if _pin != Vector2.ZERO:
		z.global_position = _pin
	z.velocity = Vector2.ZERO
	z.queue_redraw()


# ============================================================
#  ציור (פיקסלים, יחסית לחזית למטה; x חיובי = לתוך הקיר. בלי היפוך / סקייל)
# ============================================================
func draw() -> bool:
	DrawBatch.set_transform_matrix(z, Transform2D.IDENTITY)
	var tt := _t
	var b: float = Decor.U.beat
	var life: float = Decor.U.life
	var dead_k := 1.0 if z.dead else 0.0
	var pts := PackedVector2Array()
	var cols := PackedColorArray()
	# ---- הגוף: מסה של לב-מוח ----
	var sw := 1.0 + 0.022 * b * (1.0 - dead_k * 0.7) + (0.04 if _pulse_t >= 0.0 and _pulse_t < PULSE_TELL else 0.0)
	var cen := Vector2(260.0, -330.0)
	var outline := [Vector2(-20, 0), Vector2(-62, -30), Vector2(-48, -110), Vector2(-74, -190), Vector2(-62, -290), Vector2(-86, -380),
		Vector2(-56, -470), Vector2(-6, -560), Vector2(70, -650), Vector2(200, -720), Vector2(560, -740), Vector2(560, 0)]
	var poly := PackedVector2Array()
	var pc := PackedColorArray()
	var fl: Color = Decor.FLESH.lerp(Color("2a2222"), (1.0 - clampf(life, 0.0, 1.0)) * 0.6)
	for i in outline.size():
		var p: Vector2 = outline[i]
		p = cen + (p - cen) * sw
		p.x += sin(tt * 1.3 + float(i)) * 3.0
		poly.append(p)
		pc.append(fl.lerp(Decor.FLESH_D, clampf((p.x + 60.0) / 500.0, 0.0, 1.0) * 0.8))
	DrawBatch.polygon(z, poly, pc)
	# חדרי הלב: שתי בליטות שפועמות
	U.oval(pts, cols, Vector2(150, -470) + Vector2(0, -6) * b, 120.0 * sw, 130.0 * sw, Color("5a2228").lerp(Color("2a2222"), 1.0 - clampf(life, 0.0, 1.0)), 18)
	U.oval(pts, cols, Vector2(190, -170), 130.0 * sw, 110.0 * sw, Color("4e1c22").lerp(Color("262020"), 1.0 - clampf(life, 0.0, 1.0)), 18)
	U.oval(pts, cols, Vector2(120, -480), 60.0, 40.0, Color(1.0, 0.7, 0.7, 0.06 + 0.06 * b), 12)
	# קפלי מוח
	for fi in _folds.size():
		var f: Array = _folds[fi]
		for j in f.size() - 1:
			var a: Vector2 = f[j]
			var c: Vector2 = f[j + 1]
			a = cen + (a - cen) * sw
			c = cen + (c - cen) * sw
			U.seg(pts, cols, a, c, 9.0, Color(0.16, 0.04, 0.06, 0.55))
			U.seg(pts, cols, a + Vector2(0, -4), c + Vector2(0, -4), 3.0, Color(0.6, 0.3, 0.32, 0.35))
	# פנים של נבלעים שנלחצות מבפנים
	for fc in _faces:
		var p: Vector2 = fc
		var a := 0.12 + 0.1 * sin(tt * 0.8 + p.x)
		U.oval(pts, cols, p, 14.0, 18.0, Color(0.85, 0.6, 0.6, a), 10)
		U.oval(pts, cols, p + Vector2(-3, 2), 6.0, 8.0, Color(0.1, 0.02, 0.03, a * 1.6), 8)
	# עורקים לתקרה ושורשים לרצפה
	for k in 4:
		var x0 := 20.0 + float(k) * 120.0
		U.vein(pts, cols, Vector2(x0, -560.0 - float(k) * 30.0), Vector2(x0 + 40.0 * sin(float(k)), -1000.0), 26.0 - float(k) * 3.0, tt, z.global_position.x + x0, k, Decor.ROOTC)
	for k in 5:   # שורשים שנכנסים לרצפה (רובם מתחת לאדמה)
		var y0 := -14.0 - float(k) * 8.0
		var x1 := -110.0 - float(k) * 80.0
		var prev := Vector2(-30.0, y0)
		for q in range(1, 7):
			var u := float(q) / 6.0
			var p := Vector2(lerpf(-30.0, x1, u), lerpf(y0, 10.0, u * u) + sin(u * 6.0 + float(k)) * 4.0)
			U.seg(pts, cols, prev, p, (12.0 - float(k) * 1.5) * (1.0 - u * 0.6), Color("2a1410"))
			prev = p
		U.oval(pts, cols, Vector2(lerpf(-30.0, x1, 0.5), lerpf(y0, 10.0, 0.25) - 2.0), 3.0, 3.0, U.glow(Color(0.75, 1.0, 0.55, 0.3 + 0.4 * sin(tt * 3.0 + float(k)))), 6)
	for v in _veins:
		var p: Vector2 = v[0]
		var ph: float = v[1]
		var g := 0.5 + 0.5 * sin(tt * 3.0 + ph)
		U.oval(pts, cols, p, 7.0 + 3.0 * g, 6.0 + 2.0 * g, U.glow(Color(0.75, 1.0, 0.55, 0.3 + 0.4 * g * clampf(life, 0.0, 1.5))), 8)
	U.flush(z, pts, cols)
	pts.clear()
	cols.clear()
	# ---- הליבה ----
	var cw := CORE_L
	var ck := core_k if not z.dead else maxf(speak * 0.7, 0.0)
	var rc: Color = U.glow(Color(0.8, 1.0, 0.6))
	if shattered > 0.0:
		rc = Color(0.5, 0.5, 0.45)
	var halo := (0.15 + 0.35 * ck + 0.3 * speak) * clampf(life, 0.0, 1.5)
	Art.glow(z, cw, 120.0 + 40.0 * b, Color(rc, halo * 0.5))
	U.oval(pts, cols, cw, CORE_R.x + 14.0, CORE_R.y + 16.0, Color("2a0a10"), 18)
	if ck > 0.02 or shattered > 0.0:
		var ry := CORE_R.y * maxf(ck, shattered * 0.8)
		U.oval(pts, cols, cw, CORE_R.x * 0.95, ry, Color(rc.r * 0.5, rc.g * 0.6, rc.b * 0.4, 1.0), 18)
		U.oval(pts, cols, cw, CORE_R.x * 0.7, ry * 0.75, Color(rc, 0.95), 16)
		U.oval(pts, cols, cw + Vector2(-6, -8), CORE_R.x * 0.32, ry * 0.32, Color(1, 1, 1, 0.75 * clampf(life, 0.0, 1.0)), 12)
		for q in 5:   # ורידים בתוך הליבה
			var a := float(q) / 5.0 * TAU + tt * 0.4
			U.seg(pts, cols, cw, cw + Vector2(cos(a) * CORE_R.x * 0.7, sin(a) * ry * 0.7), 2.0, Color(0.3, 0.5, 0.2, 0.6))
		if shattered > 0.0:   # סדקים
			for q in 7:
				var a := float(q) * 0.9 + 0.3
				U.seg(pts, cols, cw, cw + Vector2(cos(a), sin(a)) * 90.0 * shattered, 4.0, Color(0.05, 0.03, 0.03, 0.9))
	# שפתיים של בשר (נסגרות על הליבה)
	var lip := CORE_R.y * (1.0 - ck) + 4.0
	for s: float in [-1.0, 1.0]:
		var top := cw + Vector2(0, -CORE_R.y - 10.0)
		var bot := cw + Vector2(0, CORE_R.y + 10.0)
		var mid := cw + Vector2(s * (CORE_R.x + 6.0), 0.0)
		var inner := cw + Vector2(s * (CORE_R.x * 0.92) * ck + s * 2.0, 0.0)
		U.quad(pts, cols, top, mid, bot, inner, Color("6a2a30"), Color("4a1a20"), Color("6a2a30"), Color("8a3a40"))
	U.seg(pts, cols, cw + Vector2(0, -lip * 0.6 - 30.0 * (1.0 - ck)), cw + Vector2(0, lip * 0.6 + 30.0 * (1.0 - ck)), 2.0 + 3.0 * (1.0 - ck), Color(0.08, 0.02, 0.03, 0.9))
	# ---- שלב IV: ברדס ופנים ----
	if face_k > 0.01:
		var hk := face_k
		var hc := Color(0.1, 0.09, 0.08, 0.92 * hk)
		var hood := [cw + Vector2(-20, -250), cw + Vector2(-96, -190), cw + Vector2(-120, -40), cw + Vector2(-96, 120), cw + Vector2(-50, 170),
			cw + Vector2(-70, 60), cw + Vector2(-74, -80), cw + Vector2(-40, -170), cw + Vector2(30, -200)]
		var hp := PackedVector2Array()
		for p in hood:
			hp.append(p)
		U.flush(z, pts, cols)
		pts.clear()
		cols.clear()
		DrawBatch.colored_polygon(z, hp, hc)
		var ec: Color = Decor.CAT_COL.get(_face_mode, Decor.ECHO) if _face_st == 1 else Color(0.7, 1.0, 0.5)
		var ea := hk * (0.7 + 0.3 * sin(tt * 6.0)) * (1.6 if _face_st == 1 else 1.0)
		if _hide_t > 0.0:
			ea *= 0.3
		U.seg(pts, cols, cw + Vector2(-50, -120), cw + Vector2(-16, -112), 7.0, Color(ec, minf(ea, 1.0)))
		U.seg(pts, cols, cw + Vector2(2, -110), cw + Vector2(30, -104), 6.0, Color(ec, minf(ea, 1.0)))
		Art.glow(z, cw + Vector2(-10, -112), 70.0, Color(ec, 0.25 * hk))
	# ---- שלב II: תותחים ----
	for i in pods.size():
		var p: Dictionary = pods[i]
		var ps := str(p.st)
		if phase != 2 or z.dead:
			break
		var pw: Vector2 = POD_L[i]
		if ps == "dead":
			U.oval(pts, cols, pw + Vector2(10, 0), 20.0, 16.0, Color("2a0e10"), 10)
			U.oval(pts, cols, pw + Vector2(6, 0), 10.0, 8.0, Color(0.5, 0.1, 0.1, 0.8), 8)
			continue
		var gk: float = clampf(float(p.grow), 0.0, 1.0) if ps == "grow" else 1.0
		var r := POD_R * gk
		var pcol := Color("7a3a3c") if float(p.flash) <= 0.0 else Color.WHITE
		if ps == "heat":
			pcol = pcol.lerp(Color("ff7a3a"), 0.5 + 0.3 * sin(tt * 20.0))
		U.oval(pts, cols, pw + Vector2(12, 0), r * 1.2, r, Color("4a1a1e"), 14)
		U.oval(pts, cols, pw, r, r * 0.9, pcol, 14)
		var hpk := clampf(float(p.hp) / float(POD_HP), 0.0, 1.0)
		if hpk < 0.6:
			U.seg(pts, cols, pw + Vector2(-10, -12), pw + Vector2(6, 8), 2.0, Color(0.1, 0.02, 0.02, 0.9))
		var ad := Vector2.from_angle(float(p.aim))
		U.seg(pts, cols, pw, pw + ad * 52.0 * gk, 13.0 * gk, Decor.BONE_D)
		U.seg(pts, cols, pw + ad * 12.0, pw + ad * 50.0 * gk, 8.0 * gk, Decor.BONE)
		if ps == "spin":
			var sk := clampf(float(p.t) / POD_SPIN, 0.0, 1.0)
			U.oval(pts, cols, pw + ad * 52.0, 4.0 + 8.0 * sk, 4.0 + 8.0 * sk, Color(1.0, 0.5, 0.3, 0.3 + 0.6 * sk), 10)
			for q in 3:
				var a := tt * 18.0 + float(q) * TAU / 3.0
				U.seg(pts, cols, pw + ad * 30.0, pw + ad * 30.0 + Vector2.from_angle(a) * 14.0, 2.0, Color(0.9, 0.8, 0.7, 0.6))
		elif ps == "fire" and float(p.flash) > 0.0:
			U.oval(pts, cols, pw + ad * 56.0, 12.0, 12.0, Color(1.0, 0.85, 0.5, 0.9), 10)
		elif ps == "heat":
			U.oval(pts, cols, pw + Vector2(0, -r - 10.0 - fmod(tt * 40.0, 30.0)), 10.0, 8.0, Color(0.9, 0.9, 0.9, 0.25), 8)
	# ---- הדף (אזהרה: טבעת) ----
	if _pulse_t >= 0.0:
		var k := _pulse_t / PULSE_TELL
		if k < 1.0:
			U.flush(z, pts, cols)
			pts.clear()
			cols.clear()
			DrawBatch.arc(z, Vector2(-60, -200), 60.0 + 40.0 * k, PI * 0.5, PI * 1.5, 16, Color(1.0, 0.4, 0.3, 0.3 + 0.5 * k), 4.0)
		else:
			var e := (_pulse_t - PULSE_TELL) / 0.4
			U.flush(z, pts, cols)
			pts.clear()
			cols.clear()
			DrawBatch.arc(z, Vector2(-60, -200), 60.0 + PULSE_R * 1.4 * e, PI * 0.5, PI * 1.5, 20, Color(1.0, 0.6, 0.5, 0.7 * (1.0 - e)), 8.0)
	# ---- קוצים ----
	var o: Vector2 = z.global_position
	for s in spikes:
		var sx: float = float(s.x) - o.x
		var k: float = float(s.t) - float(s.tell)
		if k < 0.0:   # אזהרה: גבשושית זוהרת + סדקים
			var tk := clampf(float(s.t) / float(s.tell), 0.0, 1.0)
			U.oval(pts, cols, Vector2(sx, -2.0), 36.0, 6.0 + 10.0 * tk, Color("3a1a14"), 12)
			U.oval(pts, cols, Vector2(sx, -4.0), 26.0 * tk, 4.0 + 5.0 * tk, U.glow(Color(0.75, 1.0, 0.55, 0.25 + 0.6 * tk * (0.6 + 0.4 * sin(tt * 30.0)))), 10)
			for q in 4:
				var a := -PI + float(q) * PI / 3.0
				U.seg(pts, cols, Vector2(sx, -2.0), Vector2(sx, -2.0) + Vector2(cos(a) * 40.0 * tk, sin(a) * 6.0 * tk - 2.0), 2.0, Color(0.08, 0.02, 0.02, 0.8))
		else:
			_spike_shape(pts, cols, sx, float(s.h), tt + sx)
	# ---- אזורי התכנון ----
	for zn in zones:
		var zx: float = float(zn.x) - o.x
		var k: float = float(zn.t) - float(zn.tell)
		if float(zn.t) < 0.0:
			continue
		if k < 0.0:
			var tk := clampf(float(zn.t) / float(zn.tell), 0.0, 1.0)
			U.oval(pts, cols, Vector2(zx, -3.0), ZONE_W, 8.0, Color(1.0, 0.2, 0.15, 0.18 + 0.3 * tk), 14)
			U.oval(pts, cols, Vector2(zx, -3.0), ZONE_W * tk, 8.0 * tk, Color(1.0, 0.35, 0.25, 0.4), 14)
			U.rect(pts, cols, Rect2(zx - ZONE_W, -ZONE_H, ZONE_W * 2.0, ZONE_H), Color(1.0, 0.2, 0.15, 0.05 + 0.08 * tk))
		elif k < 0.75:
			var h := ZONE_H * (minf(1.0, k / 0.08) if k < 0.4 else maxf(0.0, 1.0 - (k - 0.4) / 0.35))
			for q in 3:
				_spike_shape(pts, cols, zx + (float(q) - 1.0) * 34.0, h * (0.8 + 0.2 * float(q % 2)), tt + float(q))
	U.flush(z, pts, cols)
	# ---- קרן (AIM) / אזהרה ----
	if phase == 4 and _face_st == 1 and not z.dead:
		var face := CORE_L + Vector2(-20.0, -10.0)
		var dir := Vector2.from_angle(_face_aim)
		var cc: Color = Decor.CAT_COL.get(_face_mode, Decor.ECHO)
		var tk := 1.0 - clampf(_face_t / float(FACE_TELL.get(_face_mode, 0.7)), 0.0, 1.0)
		if _face_mode == "precision":
			DrawBatch.line(z, face, face + dir * 1400.0, Color(cc, 0.2 + 0.5 * tk * (0.6 + 0.4 * sin(tt * 30.0))), 2.0 + 3.0 * tk)
		elif _face_mode == "shotgun":
			DrawBatch.line(z, face, face + Vector2.from_angle(_face_aim - 0.36) * 520.0, Color(cc, 0.3 * tk), 2.0)
			DrawBatch.line(z, face, face + Vector2.from_angle(_face_aim + 0.36) * 520.0, Color(cc, 0.3 * tk), 2.0)
		DrawBatch.circle(z, face, 10.0 + 18.0 * tk, Color(cc, 0.3 + 0.4 * tk))
	if _beam_t >= 0.0:
		var face := CORE_L + Vector2(-20.0, -10.0)
		var dir := Vector2.from_angle(_beam_a)
		var a := 1.0 - _beam_t / 0.3
		DrawBatch.line(z, face, face + dir * 1400.0, Color(0.6, 0.9, 1.0, 0.5 * a), BEAM_W)
		DrawBatch.line(z, face, face + dir * 1400.0, Color(1, 1, 1, 0.9 * a), BEAM_W * 0.35)
	return true


func _spike_shape(pts: PackedVector2Array, cols: PackedColorArray, x: float, h: float, ph: float) -> void:
	if h < 2.0:
		return
	var bw := SPIKE_W
	var lean := sin(ph * 3.1) * 8.0
	var tip := Vector2(x + lean, -h)
	U.quad(pts, cols, Vector2(x - bw, 0), Vector2(x + bw, 0), Vector2(x + bw * 0.35 + lean * 0.6, -h * 0.55), Vector2(x - bw * 0.35 + lean * 0.6, -h * 0.55),
		Color("3a1a14"), Color("2a120e"), Color("5a2a22"), Color("4a2018"))
	U.tri(pts, cols, Vector2(x - bw * 0.35 + lean * 0.6, -h * 0.55), Vector2(x + bw * 0.35 + lean * 0.6, -h * 0.55), tip, Color("6a3028"))
	for q in 3:   # קוצים קטנים
		var yy := -h * (0.25 + 0.2 * float(q))
		var sd := 1.0 if q % 2 == 0 else -1.0
		var bx := x + sd * bw * (0.7 - 0.2 * float(q)) + lean * (0.3 + 0.2 * float(q))
		U.tri(pts, cols, Vector2(bx, yy - 6.0), Vector2(bx, yy + 6.0), Vector2(bx + sd * 14.0, yy - 10.0), Color("8a6a50"))
	U.seg(pts, cols, Vector2(x, -4.0), tip + Vector2(0, 10), 2.5, U.glow(Color(0.75, 1.0, 0.55, 0.55)))
	U.oval(pts, cols, Vector2(x, -2.0), bw + 14.0, 7.0, Color("2a0e0a"), 10)
