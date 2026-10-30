extends Node
# ============================================================
#  MUSIC MOOD - המוזיקה של השלב מגיבה לסכנה, בעדינות.
#  רגוע (אין זומבי ער ליד השחקן כמה שניות): המוזיקה קצת עמומה ושקטה יותר, כאילו מרחוק.
#  סכנה (זומבי ער קרוב / יורים / נפגעים): נפתחת מלאה - נשמעת בדיוק כמו קודם. נפתחת מהר, נרגעת לאט.
#  hush() = "השקט שלפני הסערה": אירוע עומד להתחיל (HOLD THE LINE / ESCAPE) - המוזיקה נסוגה כמעט לשקט.
#  hit()  = האירוע התחיל: המוזיקה חוזרת בבת אחת, מלאה.
#  cine   = 0..1 מבחוץ (effects/bullet_cam.gd - מצלמת קליע): המוזיקה עמומה ושקטה, כאילו בתוך הקליע.
#  ערוץ "LevelMusic" (נשלח ל-"Music", כך שעוצמת המוזיקה בהגדרות עדיין קובעת) עם מסנן + עוצמה.
#  מוזיקת התפריט ושלבים שמנגנים בעצמם לא עוברים כאן.
# ============================================================

const BUS := "LevelMusic"
const CALM_HZ := 3800.0      # רגוע: הגבוהים מעל זה נחתכים (עמום)
const OPEN_HZ := 20500.0     # פתוח = כמו בלי מסנן
const CALM_DB := -2.5
const HUSH_HZ := 650.0
const HUSH_DB := -17.0
const NEAR_X := 760.0        # זומבי ער בטווח הזה מהשחקן = סכנה
const NEAR_Y := 420.0
const HOLD := 3.0            # כמה שניות נשארת פתוחה אחרי הסכנה האחרונה
const OPEN_T := 0.35         # שניות מרגוע לפתוח
const CLOSE_T := 3.5         # שניות מפתוח לרגוע
const HUSH_IN := 1.1         # שניות עד השקט
const CINE_HZ := 700.0       # מצלמת קליע: עמום מאוד
const CINE_DB := -5.0
const HUSH_OUT := 0.6        # יצא מהאזור בלי שהאירוע התחיל: חוזרת בנחת

var main: Node
var _k := 0.0                # 0 רגוע .. 1 סכנה
var _hot := 0.0
var _scan := 0.0
var _hush := 0.0             # 0..1
var _hush_hold := 0.0
var _out_t := HUSH_OUT
var _bus := -1
var _lp: AudioEffectLowPassFilter = null
var _amp: AudioEffectAmplify = null
var _last := Vector3(-1.0, -1.0, -1.0)
var cine := 0.0              # מצלמת קליע (effects/bullet_cam.gd קובע כל פריים)


func _ready() -> void:
	_bus = AudioServer.get_bus_index(BUS)
	if _bus < 0:
		AudioServer.add_bus()
		_bus = AudioServer.bus_count - 1
		AudioServer.set_bus_name(_bus, BUS)
		AudioServer.set_bus_send(_bus, "Music")
		var lp := AudioEffectLowPassFilter.new()
		lp.db = AudioEffectFilter.FILTER_12DB
		AudioServer.add_bus_effect(_bus, lp)
		AudioServer.add_bus_effect(_bus, AudioEffectAmplify.new())
	_lp = AudioServer.get_bus_effect(_bus, 0) as AudioEffectLowPassFilter
	_amp = AudioServer.get_bus_effect(_bus, 1) as AudioEffectAmplify
	_apply()


func _process(delta: float) -> void:
	var p = main._player if main != null else null
	if p != null and is_instance_valid(p) and not p.dead and not main._finished:
		if p._recoil > 0.5 or p._hurt_t > 0.0:   # יורה / נפגע
			_hot = HOLD
		_scan -= delta
		if _scan <= 0.0:
			_scan = 0.25
			if _danger_near(p):
				_hot = HOLD
	else:   # מת / סוף השלב: נרגעת
		_hot = 0.0
	_hot -= delta
	var want := 1.0 if _hot > 0.0 else 0.0
	_k = move_toward(_k, want, delta / (OPEN_T if want > _k else CLOSE_T))
	_hush_hold -= delta
	var hw := 1.0 if _hush_hold > 0.0 else 0.0
	_hush = move_toward(_hush, hw, delta / (HUSH_IN if hw > _hush else _out_t))
	if _hush <= 0.0:
		_out_t = HUSH_OUT
	_apply()


# זומבי ער (לא שוכב, לא מוסתר במארב) קרוב לשחקן
func _danger_near(p: Node2D) -> bool:
	for z in get_tree().get_nodes_in_group("zombies"):
		if z.dead or z.dormant or not z.visible:
			continue
		var d: Vector2 = z.global_position - p.global_position
		if absf(d.x) < NEAR_X and absf(d.y) < NEAR_Y:
			return true
	return false


func _apply() -> void:
	if _lp == null or _amp == null:
		return
	var now := Vector3(_k, _hush, cine)
	if now.is_equal_approx(_last):
		return
	_last = now
	var hz := exp(lerpf(log(CALM_HZ), log(OPEN_HZ), _k))
	hz = exp(lerpf(log(hz), log(HUSH_HZ), _hush))
	_lp.cutoff_hz = exp(lerpf(log(hz), log(minf(hz, CINE_HZ)), cine))
	_amp.volume_db = lerpf(lerpf(CALM_DB, 0.0, _k), HUSH_DB, _hush) + CINE_DB * cine


# האירוע עוד רגע מתחיל (נקרא כל עוד השחקן באזור שלפניו; t = כמה זמן זה מחזיק בלי קריאה נוספת)
func hush(t := 0.15) -> void:
	_hush_hold = maxf(_hush_hold, t)


# האירוע התחיל: חוזרת מלאה בבת אחת (0.08 שנייה - בלי קליק), ונשארת פתוחה לפחות hot שניות
func hit(hot := 8.0) -> void:
	_hush_hold = 0.0
	_out_t = 0.08
	_k = 1.0
	_hot = maxf(_hot, hot)
	_apply()


# נשארת פתוחה (למשל כל עוד ההמון של ESCAPE רודף - הוא לא זומבים בקבוצה)
func hot(t := 1.0) -> void:
	_hot = maxf(_hot, t)
