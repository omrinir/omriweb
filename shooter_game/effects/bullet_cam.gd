extends Node
const DrawBatch := preload("res://effects/draw_batch.gd")
const Sfx := preload("res://sfx.gd")
const Registry := preload("res://enemies/zombie_registry.gd")
# ============================================================
#  BULLET CAM - מצלמת קליע לצלף (SNIPER / ANTI-MATERIEL / RAILGUN).
#  יורים עם כוונת (לחצן ימני = הזמן מאט) ירייה שתהרוג זומבי -> לפעמים (1 או 2 פעמים בשלב, באקראי)
#  הזמן כמעט נעצר, המצלמה נכנסת בזום אל הקליע ועוקבת אחריו עד הפגיעה, מחזיקה רגע על ההריגה בהילוך איטי
#  וחוזרת לשחקן. נוצר ע"י main.gd. player.gd -> _fire קורא ל-consider() אחרי שהקליע נוצר.
#
#  חלקות (הכי חשוב): הכל בזמן אמיתי, לא לפי Engine.time_scale. המיקום והזום עוברים בעקומת S (smootherstep -
#  מהירות ותאוצה 0 בהתחלה ובסוף), הזום בלוגריתם (כל הכפלה של הזום מרגישה אותה דבר). המצלמה עוקבת אחרי המיקום
#  שמצויר על המסך (bullet.gd -> interp_pos, בין שני צעדי פיזיקה), לא אחרי המיקום של הפיזיקה - בלי רעד.
#  בפגיעה המצלמה לא נעצרת בבת אחת: קפיץ מרוסן (critically damped) שממשיך מהמהירות שלה ונרגע על ההריגה,
#  והזום יוצא כדי שהגוף שעף יישאר בתמונה (zombie.gd -> body_center). החזרה לשחקן ממשיכה מהמהירות הזו (_carry).
#  הקליע עצמו מצויר גדול, עם גלי אוויר (bullet.gd -> _draw_wake).
#  הזמן: נופל מיד בירייה, הקליע "זוחל" רגע לפני הפגיעה, ההריגה בהילוך איטי, וחוזר בהדרגה.
#
#  מתי: רק כשבטוח שהירייה תהרוג (zombie.gd -> lethal_hit). בוסים,
#  מגנים, שריון וסוגים שחוסמים פגיעות (UNSAFE) - לא. הזומבי קפוא עד הפגיעה (zombie.gd -> cam_hold: בזמן כמעט עצור
#  ההחלטות האקראיות שלו - קפיצת זיגזג, התכופפות - היו קורות פי 30 יותר), אבל המצלמה מראה רק ירייה שהייתה הורגת גם
#  בלי זה. לא מתחילה כשזומבי קרוב לשחקן או כשהשחקן באוויר. אם בכל זאת לא הרג: חוזרת מהר ולא נספר (פגע ולא הרג = הסוג הזה יוצא).
#  בזמן המצלמה: השחקן קפוא (player.gd), ה-HUD דועך (קבוצה cine_hide), פסים שחורים, המוזיקה עמומה (music_mood.gd),
#  גלגל הנשקים / עצירות פגיעה / רעידות לא פועלים. קליעים בודקים "מחוץ למסך" לפי המסך הרגיל (logic_view).
#  בדיקה: devtools/t_bullet_cam.gd
# ============================================================

# ---- מתי ----
const CHANCE := 0.4            # סיכוי לכל ירייה מתאימה. ירייה מתאימה שלא קיבלה מצלמה מעלה אותו ב-CHANCE_UP
const CHANCE_UP := 0.12
const GAP := 40.0              # שניות משחק לפחות בין שתי מצלמות קליע (שלא יבואו שתיהן ברצף)
const MIN_DIST := 150.0        # מרחק מהקנה לפגיעה (קרוב מזה אין מה לראות)
const MAX_DIST := 1500.0
const BAND := 2.0              # כמה פיקסלים הפגיעה יכולה לזוז (zombie.gd -> lethal_hit; הזומבי קפוא - כמעט מדויק)
const NEAR_ZOMBIE := Vector2(200.0, 140.0)   # זומבי ער קרוב מזה לשחקן = אין מצלמה (השחקן קפוא בזמן המצלמה)
# סוגים שאי אפשר לדעת מראש אם ירייה תהרוג: מגן / שריון / חוסמים או סופגים פגיעות לפי מצב / סופרים פגיעות.
# devtools/bullet_cam_types.py בונה את הרשימה מ-on_damage / damage_mult של כל סוג (להריץ אחרי סוגים חדשים)
const UNSAFE := [
	"angler", "apu", "armored_train", "ashmoth", "azufrero", "babbler", "balsero", "beekeeper", "behemoth", "biker",
	"blades", "blood_gate", "bloom", "blubber", "bombhead", "bonecrawler", "boneside", "cask", "charred", "cinder",
	"clinger", "clockwork", "coffin_breaker", "darkseeker", "diablo", "dish", "dono", "drowned", "drummer", "emperor",
	"encased", "executioner", "flagbearer", "flamer", "flenser", "floater", "frostbite", "general", "glider",
	"goalkeeper", "graffiti", "guardian", "hauler", "hazmat", "hollow", "hunter", "ice_titan", "ironarms", "loader",
	"mallki", "marshal", "mirage", "morenada", "murmur", "panel", "paratrooper", "pilgrim", "praetorian",
	"propagandist", "prototype", "pursuer", "red_zeppelin", "remnant", "retcher", "rider", "root", "sandblaster",
	"sealer", "seeper", "shearer", "shepherd", "shield_elite", "shielded", "specimen", "stacker", "stormtrooper",
	"straggler", "supay", "synapse", "tank", "tankette", "thawed", "tower", "tumbler", "vent", "waddler",
	"wall_crawler", "warden", "welder"
]

# ---- איך (כל הזמנים בשניות אמיתיות) ----
const ZOOM_IN := 2.4           # זום על הקליע (פי הזום הרגיל)
const LEAD := 0.17             # הקליע טס קצת מאחורי מרכז המסך (חלק מרוחב המסך): רואים לאן הוא טס. נעלם לקראת הפגיעה
const SCREEN_SPEED := 800.0    # כמה מהר העולם חולף על המסך בזמן המעקב (פיקסלים לשנייה) -> משך המעוף
const FLY_MIN := 0.8           # משך המעוף: מינימום / מקסימום
const FLY_MAX := 2.2
const TS_DROP := 0.03          # הזמן נעצר כמעט מיד בירייה (קבוע זמן)
const NEAR := 0.45             # רגע לפני הפגיעה הקליע מאט עוד (פי זה, ב-NEAR_PX האחרונים)
const NEAR_PX := 90.0
const LOCK_T := 0.55           # המצלמה מגיעה אל הקליע
const ZOOM_T := 0.65           # הזום נכנס
const HOLD_T := 0.8            # ההריגה בהילוך איטי
const HOLD_MISS := 0.35        # לא הרג (לא אמור לקרות): חוזרים מהר
const TS_HOLD := 0.13
const HOLD_ZOOM := 0.92        # בהריגה הזום יוצא טיפה - רואים את כל הדם
const HOLD_FIT := 0.56         # הגוף עף: הפגיעה והגוף נשארים בתוך החלק הזה של המסך (הזום יוצא בשביל זה, לא פחות מהרגיל)
const HOLD_PAD := 60.0
const W_HOLD := 8.0            # הקפיץ שעוצר את המצלמה על ההריגה
const W_ZOOM := 8.0            # הקפיץ של הזום בהריגה
const OUT_T := 0.75            # חוזרת לשחקן: OUT_T + OUT_PER לכל פיקסל מרחק
const OUT_PER := 0.0006
const OUT_MAX := 1.4
const TS_OUT := 0.3            # הזמן בסוף החזרה
const TAIL_T := 0.35           # המצלמה כבר רגילה והשחקן משוחרר: הזמן חוזר למהירות הרגילה
const BAR := 0.07              # פסים שחורים קולנועיים (חלק מגובה המסך)
const MUFFLE := 0.85           # כמה המוזיקה עמומה (music_mood.gd -> cine)

enum { OFF, LOCK, HOLD, OUT, TAIL }

static var inst: Node = null
static var test_force := false   # devtools/t_bullet_cam.gd: כל ירייה מתאימה (בלי הגרלה, בלי מכסה ובלי GAP)
static var _banned := {}         # סוגים שנפגעו ולא מתו (החישוב טעה בהם; נשאר עד סוף המשחק)

var main: Node
var count_max := 2               # 1 או 2 בשלב (מוגרל)
var shown := 0
var _chance := CHANCE
var _game_t := 0.0
var _last_t := -1000.0
var _phase := OFF
var _t := 0.0                    # מתחילת המצלמה
var _pt := 0.0                   # מתחילת השלב הנוכחי
var _rd := 0.0                   # הזמן האמיתי של הפריים
var _ts_set := 1.0               # מה שנקבע ל-Engine.time_scale בפריים הקודם
var _cam: Camera2D = null
var _pl: Node2D = null
var _b: Node2D = null            # הקליע
var _z: Node2D = null            # הזומבי
var _kind := -1
var _dir := Vector2.RIGHT
var _hit := Vector2.ZERO         # נקודת הפגיעה הצפויה
var _dist := 0.0
var _ts0 := 0.5
var _ts_fly := 0.05
var _ts_from := 0.0
var _z0 := 1.0
var _zin := 2.0
var _lead := 0.0
var _c0 := Vector2.ZERO
var _c := Vector2.ZERO
var _cv := Vector2.ZERO
var _lz := 0.0
var _lz_from := 0.0
var _c_from := Vector2.ZERO
var _v_from := Vector2.ZERO
var _lzv := 0.0                  # מהירות הזום (לוגריתם) בהריגה
var _lzv_from := 0.0
var _out_t := OUT_T
var _bp := Vector2.ZERO          # המיקום האחרון של הקליע (אם הוא נעלם)
var _impact := Vector2.ZERO
var _killed := false
var _hp0 := 0
var _w := 0.0                    # 0..1 כמה "קולנועי": פסים, HUD, מוזיקה
var _layer: CanvasLayer
var _ui: Node2D


func _ready() -> void:
	inst = self
	process_priority = -100   # ראשון בפריים: המצלמה והזמן נקבעים לפני שכל השאר מתעדכנים
	count_max = 1 if randf() < 0.5 else 2
	_layer = CanvasLayer.new()
	_layer.layer = 3
	add_child(_layer)
	_ui = Node2D.new()
	_layer.add_child(_ui)
	_ui.draw.connect(_draw_bars)


func _exit_tree() -> void:
	if inst == self:
		inst = null
	if _phase != OFF:
		_finish(1.0)


# ---- מבחוץ ----
# player.gd -> _fire: קליע צלף נוצר בזמן כוונת
static func consider(pl: Node2D, b: Node2D) -> void:
	if inst != null and is_instance_valid(inst):
		inst._consider(pl, b)


# השחקן קפוא (player.gd): מהירייה עד שהמצלמה חזרה אליו
static func holding() -> bool:
	return inst != null and inst._phase != OFF and inst._phase != TAIL


# bullet.gd: כמה הקליע הזה "בצילום" (0..1): מצויר גדול, עם גלי אוויר
static func bullet_look(b: Node) -> float:
	if inst == null or inst._phase == OFF or inst._b != b:
		return 0.0
	return inst._w


static func cam_time() -> float:   # שניות אמיתיות מתחילת המצלמה (האנימציה של גלי האוויר)
	return inst._t if inst != null else 0.0


# "המסך" לבדיקות משחק (bullet.gd: קליע נעלם 70 פיקסלים אחרי הקצה): בזמן מצלמת קליע - המסך הרגיל, לא הזום
static func logic_view(vp: Viewport) -> Rect2:
	if Engine.has_meta("logic_view"):
		return Engine.get_meta("logic_view")
	return vp.get_canvas_transform().affine_inverse() * vp.get_visible_rect()


func _consider(pl: Node2D, b: Node2D) -> void:
	if _phase != OFF or pl.dead or get_tree().paused or Engine.has_meta("hitstop") or (main != null and main._finished):
		return
	if not test_force and (shown >= count_max or _game_t - _last_t < GAP):
		return
	if not get_tree().get_nodes_in_group("story_scene").is_empty():
		return
	var cam := get_viewport().get_camera_2d()
	if cam == null or not cam.has_method("cine_begin") or not pl.is_on_floor():   # (באוויר: היה נתקע באוויר כל המצלמה)
		return
	var shot := _predict(pl, b)
	if shot.is_empty():
		return
	for o in get_tree().get_nodes_in_group("zombies"):   # לא עוצרים את השחקן באמצע קרב
		var od: Vector2 = o.global_position - pl.global_position
		if absf(od.x) < NEAR_ZOMBIE.x and absf(od.y) < NEAR_ZOMBIE.y and not o.dead and o.get("dormant") != true:
			return
	if not test_force:
		if randf() >= _chance:
			_chance = minf(_chance + CHANCE_UP, 0.9)
			return
	_chance = CHANCE
	_start(pl, b, cam, shot)


# האם הקליע הזה יהרוג זומבי? (בלי לשנות כלום) {} = לא / לא בטוח
func _predict(pl: Node2D, b: Node2D) -> Dictionary:
	var v: Vector2 = b.velocity
	var spd := v.length()
	if spd < 100.0:
		return {}
	var d := v / spd
	var from: Vector2 = b._cast_from
	var view := logic_view(get_viewport()).grow(float(b.max_offscreen))
	if not view.has_point(b.global_position):
		return {}
	var to: Vector2 = b.global_position + d * minf(_ray_rect_exit(b.global_position, d, view), spd * float(b.life_time))
	var space := pl.get_world_2d().direct_space_state
	var ex: Array[RID] = []
	var hit := {}
	for i in 6:   # כמו bullet.gd: מתחילים בתוך קיר = מתעלמים ממנו
		var q := PhysicsRayQueryParameters2D.create(from, to, int(b.collision_mask), ex)
		q.hit_from_inside = true
		hit = space.intersect_ray(q)
		if hit.is_empty():
			return {}
		if hit.normal == Vector2.ZERO and not hit.collider.is_in_group("zombies"):
			ex.append(hit.rid)
			continue
		break
	var z = hit.collider
	if not z.is_in_group("zombies") or not z.has_method("lethal_hit") or z.dead or _banned.has(int(z.kind)):
		return {}
	if z.type_mod != null:
		if z.type_mod.has_method("on_shot") or UNSAFE.has(str(Registry.TYPES.get(int(z.kind), "")).get_file().get_basename()):
			return {}
	var zv: Vector2 = z.get_real_velocity()   # (velocity.y צובר כוח משיכה גם כשהוא עומד על משהו שלא נחשב רצפה)
	if not z.is_on_floor() and absf(zv.y) > 40.0:   # קופץ / נופל: אי אפשר לדעת
		return {}
	if z._duck_t > 0.0 or z._crouch_k > 0.0 or z._crouched_shape:   # מתכופף (אולי מהירייה הזו): הציור והגוף שנפגע לא תואמים
		return {}
	# הפגיעה: במלבן של עכשיו (הזומבי קפוא עד שהקליע מגיע - cam_hold)
	var r: Rect2 = z.hit_rect()
	var tin := _ray_rect_enter(from, d, r)
	if tin < 0.0:
		return {}
	var at := from + d * tin
	# ובלי המצלמה: הזומבי ממשיך לזוז בזמן שהקליע עף - גם שם הירייה צריכה לפגוע ולהרוג
	var shift := zv * (from.distance_to(at) / spd)
	var tin2 := _ray_rect_enter(from, d, Rect2(r.position + shift, r.size))
	if tin2 < 0.0:
		return {}
	var dist := b.global_position.distance_to(at)
	if dist < MIN_DIST or dist > MAX_DIST or not view.has_point(at):
		return {}
	var wq := PhysicsRayQueryParameters2D.create(b.global_position, at, 1)   # קיר באמצע (אחרי שהזומבי זז)?
	if not space.intersect_ray(wq).is_empty():
		return {}
	for lp in get_tree().get_nodes_in_group("lamps"):   # נורה של פנס רחוב עוצרת את הקליע
		if lp.hit_test(from, at):
			return {}
	var src := {"source": "bullet", "sniper": b.sniper, "dmg_mult": b.dmg_mult, "head_mult": b.head_mult, "weapon": b.weapon_id}
	if b.god:
		src["god"] = true
	if not z.lethal_hit(at, src, BAND) or not z.lethal_hit(from + d * tin2 - shift, src, BAND):
		return {}
	return {"z": z, "hit": at, "dir": d, "dist": dist}


func _start(pl: Node2D, b: Node2D, cam: Camera2D, shot: Dictionary) -> void:
	_pl = pl
	_b = b
	_z = shot.z
	_kind = int(_z.kind)
	_dir = shot.dir
	_hit = shot.hit
	_dist = shot.dist
	_cam = cam
	_phase = LOCK
	_t = 0.0
	_pt = 0.0
	_killed = false
	_hp0 = int(_z.hp)
	_z.cam_hold = true
	shown += 1
	_last_t = _game_t
	_ts0 = Engine.time_scale
	_ts_set = _ts0
	_z0 = float(cam._base_zoom.x)
	_zin = _z0 * ZOOM_IN
	var vs := get_viewport().get_visible_rect().size
	_lead = LEAD * vs.x / _zin
	var spd: float = b.velocity.length()
	var fly := clampf(_dist * _zin / SCREEN_SPEED, FLY_MIN, FLY_MAX)
	var burst := spd * _ts0 * TS_DROP   # מה שהקליע עובר עד שהזמן נעצר
	_ts_fly = clampf((_dist - burst) / (spd * fly), 0.006, 0.25)
	cam.cine_begin()
	_c0 = cam.get_screen_center_position()
	_c = _c0
	_cv = Vector2.ZERO
	_lz = log(cam.zoom.x)
	_bp = b.global_position
	_w = 0.0
	Engine.set_meta("bullet_cam", true)
	Engine.set_meta("logic_view", cam.home_view())
	Sfx.play("whoosh", null, -3.0, 0.0, 2, 0.55)   # הזמן נעצר


func _process(delta: float) -> void:
	_game_t += delta
	if _phase == OFF:
		return
	_rd = clampf(delta / maxf(_ts_set, 0.0001), 0.0, 0.1)   # זמן אמיתי (delta של הפריים הזה = זמן אמיתי x מה שנקבע בפריים הקודם)
	_t += _rd
	_pt += _rd
	if _pl == null or not is_instance_valid(_pl) or _pl.dead or _cam == null or not is_instance_valid(_cam) \
			or (main != null and main._finished):
		_finish(1.0)
		return
	var ts := 1.0
	match _phase:
		LOCK:
			ts = _lock()
		HOLD:
			ts = _hold()
		OUT:
			ts = _out()
		TAIL:
			var k := _ss(0.0, TAIL_T, _pt)
			ts = lerpf(TS_OUT, _resume_ts(), k)
			if _pt >= TAIL_T:
				_finish(_resume_ts())
				return
	if _phase != TAIL and _phase != OFF:
		_cam.cine_set(_c, exp(_lz))
		Engine.set_meta("logic_view", _cam.home_view())
	_set_ts(ts)
	_apply_look()


# הקליע בדרך: המצלמה נכנסת אליו ועוקבת. מחזיר את הזמן
func _lock() -> float:
	var alive := is_instance_valid(_b)
	if alive:
		_bp = _b.interp_pos()
	var rem := (_hit - _bp).dot(_dir)   # כמה נשאר עד הפגיעה
	# פגיעה: הזומבי מת (מהקליע שלנו), או שהקליע עבר / נעצר בלי להרוג
	if is_instance_valid(_z) and _z.dead:
		_killed = true
		_impact = _z._last_hit if rem < 60.0 else _bp
		_to_hold()
		return _hold()
	if not is_instance_valid(_z) or not alive or rem < -40.0:
		_impact = _bp
		_to_hold()
		return _hold()
	var near := _ss(NEAR_PX, NEAR_PX * 0.28, rem)
	var ts := (_ts_fly + (_ts0 - _ts_fly) * exp(-_t / TS_DROP)) * lerpf(1.0, NEAR, near)
	# המטרה: הקליע + קצת קדימה (נכנס בהתחלה ונעלם לקראת הפגיעה)
	var f := _bp + _dir * _lead * _ss(0.0, 2.2 * _lead, rem) * _ss(0.0, LOCK_T, _t)
	f = _cam.clamp_center(f, _zin)
	_lz = lerpf(log(_z0), log(_zin), _sst(0.0, ZOOM_T, _t))
	var c: Vector2 = _cam.clamp_center(_c0.lerp(f, _sst(0.0, LOCK_T, _t)), exp(_lz))
	_cv = (c - _c) / maxf(_rd, 0.001)   # (בפגיעה הקפיץ ממשיך מהמהירות הזו)
	_c = c
	_w = _sst(0.0, 0.35, _t)
	return ts


func _to_hold() -> void:
	_release()
	_phase = HOLD
	_pt = 0.0
	_ts_from = _ts_set   # (המצלמה ממשיכה מהמהירות שלה - _cv - ונעצרת בקפיץ, לא בבת אחת)
	_lzv = 0.0           # (הזום כבר נכנס עד הסוף לפני הפגיעה)
	if not _killed:   # לא הרג: לא נספר. פגע ולא הרג = החישוב טעה בסוג הזה: לא יקבל עוד מצלמת קליע
		shown -= 1
		if is_instance_valid(_z) and int(_z.hp) < _hp0:
			_banned[_kind] = true


func _release() -> void:   # הזומבי ממשיך לזוז
	if _z != null and is_instance_valid(_z):
		_z.cam_hold = false


# ההריגה בהילוך איטי
func _hold() -> float:
	var focus := _impact
	var zl := log(_zin * HOLD_ZOOM)
	if is_instance_valid(_z):   # הגוף עף: המצלמה באמצע בין הפגיעה לגוף, והזום יוצא כדי שהשניים יישארו בתמונה
		var body: Vector2 = _z.body_center()
		var span := (body - _impact).abs() + Vector2(HOLD_PAD, HOLD_PAD)
		var fit := get_viewport().get_visible_rect().size * HOLD_FIT
		zl = minf(zl, log(minf(fit.x / span.x, fit.y / span.y)))
		focus = _impact.lerp(body, 0.5)
	zl = maxf(zl, log(_z0))
	focus = _cam.clamp_center(focus, exp(_lz))
	var n := maxi(1, ceili(_rd / 0.004))
	var h := _rd / float(n)
	for i in n:
		_cv += (W_HOLD * W_HOLD * (focus - _c) - 2.0 * W_HOLD * _cv) * h
		_c += _cv * h
		_lzv += (W_ZOOM * W_ZOOM * (zl - _lz) - 2.0 * W_ZOOM * _lzv) * h
		_lz += _lzv * h
	_w = 1.0
	var ts := lerpf(_ts_from, TS_HOLD, _ss(0.0, 0.45, _pt))
	if _pt >= (HOLD_T if _killed else HOLD_MISS):
		_phase = OUT
		_pt = 0.0
		_c_from = _c
		_v_from = _cv
		_lz_from = _lz
		_lzv_from = _lzv
		_out_t = minf(OUT_T + OUT_PER * _c.distance_to(_cam.home_center()), OUT_MAX)
		_ts_from = ts
	return ts


# חוזרת לשחקן: הזום יוצא קצת לפני שהתנועה נגמרת (התנועה המהירה קורית כשהזום כבר קטן).
# ממשיכה מהמהירות שהייתה לה בסוף ההריגה (_carry), בלי קפיצה
func _out() -> float:
	var e := _sst(0.0, _out_t, _pt)
	var zt := _out_t * 0.8
	_lz = maxf(lerpf(_lz_from, log(_z0), _sst(0.0, zt, _pt)) + _lzv_from * _carry(_pt, zt), log(_z0 * 0.97))
	var c := _c_from.lerp(_cam.home_center(), e) + _v_from * _carry(_pt, _out_t)
	var cc: Vector2 = _cam.clamp_center(c, exp(_lz))   # (הקפיץ של ההריגה אולי יצא קצת מגבולות השלב: חוזר אליהם בהדרגה, לא בקפיצה)
	_c = cc + (c - cc) * (1.0 - _sst(0.0, _out_t * 0.5, _pt))
	_w = 1.0 - e
	var ts := lerpf(_ts_from, TS_OUT, _ss(0.0, _out_t, _pt))
	if _pt >= _out_t:
		_cam.cine_end()
		Engine.remove_meta("logic_view")
		_phase = TAIL
		_pt = 0.0
		_w = 0.0
	return ts


# המהירות שהזמן חוזר אליה: כמו ש-player.gd היה קובע עכשיו
func _resume_ts() -> float:
	if _pl == null or not is_instance_valid(_pl) or _pl.dead:
		return 1.0
	if _pl._scoping:
		return 0.5
	if _pl.boosts.has(_pl.PickupScript.BULLET_TIME):
		return 0.4
	return 1.0


func _set_ts(ts: float) -> void:
	_ts_set = ts
	Engine.time_scale = ts


func _finish(ts: float) -> void:
	_release()
	_phase = OFF
	_w = 0.0
	if _cam != null and is_instance_valid(_cam):
		_cam.cine_end()
	_cam = null
	_b = null
	_z = null
	Engine.remove_meta("logic_view")
	Engine.remove_meta("bullet_cam")
	_ts_set = ts
	Engine.time_scale = ts
	_apply_look()


# פסים שחורים, HUD דועך, מוזיקה עמומה - לפי _w
func _apply_look() -> void:
	if is_inside_tree():
		for n in get_tree().get_nodes_in_group("cine_hide"):
			n.modulate.a = 1.0 - _w
		_ui.queue_redraw()
	if main != null and main.get("_mood") != null and is_instance_valid(main._mood):
		main._mood.cine = _w * MUFFLE
		main._mood._apply()


func _draw_bars() -> void:   # (UI: בלי batch, כמו hud.gd)
	if _w <= 0.001:
		return
	var vs := _ui.get_viewport_rect().size
	var h := vs.y * BAR * _w
	DrawBatch.rect(_ui, Rect2(0.0, 0.0, vs.x, h), Color.BLACK)
	DrawBatch.rect(_ui, Rect2(0.0, vs.y - h, vs.x, h), Color.BLACK)


# ---- עזרים ----
static func _ss(a: float, b: float, x: float) -> float:   # smoothstep (גם כש-a > b: יורד)
	var t := clampf((x - a) / (b - a), 0.0, 1.0)
	return t * t * (3.0 - 2.0 * t)


static func _sst(a: float, b: float, x: float) -> float:   # smootherstep: גם התאוצה 0 בקצוות
	var t := clampf((x - a) / (b - a), 0.0, 1.0)
	return t * t * t * (t * (t * 6.0 - 15.0) + 10.0)


# תנועה שממשיכה ונעלמת: v * _carry(t, T) מתחילה במהירות v, ובזמן T חוזרת ל-0 ונעצרת
static func _carry(t: float, T: float) -> float:
	if t >= T:
		return 0.0
	var k := 1.0 - t / T
	return t * k * k


# קרן מ-o בכיוון d: מתי נכנסת למלבן (-1 = לא נכנסת)
static func _ray_rect_enter(o: Vector2, d: Vector2, r: Rect2) -> float:
	var t0 := -INF
	var t1 := INF
	for i in 2:
		if absf(d[i]) < 0.000001:
			if o[i] < r.position[i] or o[i] > r.end[i]:
				return -1.0
			continue
		var a: float = (r.position[i] - o[i]) / d[i]
		var c: float = (r.end[i] - o[i]) / d[i]
		t0 = maxf(t0, minf(a, c))
		t1 = minf(t1, maxf(a, c))
	if t1 < maxf(t0, 0.0):
		return -1.0
	return maxf(t0, 0.0)


# קרן מ-o (בתוך המלבן) בכיוון d: מתי יוצאת ממנו
static func _ray_rect_exit(o: Vector2, d: Vector2, r: Rect2) -> float:
	var t := INF
	for i in 2:
		if d[i] > 0.000001:
			t = minf(t, (r.end[i] - o[i]) / d[i])
		elif d[i] < -0.000001:
			t = minf(t, (r.position[i] - o[i]) / d[i])
	return maxf(t, 0.0)
