extends CharacterBody2D
const DrawBatch := preload("res://effects/draw_batch.gd")   # כל הציור של זומבי ב-draw call אחד
const Sfx := preload("res://sfx.gd")   # אפקטים קוליים
# ============================================================
#  זומבי. יש 3 סוגים (kind):
#    0 = WALKER  - זומבי רגיל
#    1 = RUNNER  - רזה ומהיר, מעט חיים
#    2 = BRUTE   - ענק, איטי, הרבה חיים ונושך חזק
#    3 = SPITTER - שומר מרחק ויורק חומצה
#    4 = SCREAMER - כשהוא רואה אותך הוא צורח ומזעיק את כל הזומבים מסביב
#    5 = BOSS    - ענק עם דלת של מכונית כמגן. שומר על היציאה מהשלב
#    6 = BLOATER - מתנפח מהרגע שהוא רואה אותך, רץ אליך ומתפוצץ
#    7 = CONDUCTOR - בוס הרכבת התחתית. שנאי על הגב = נקודת התורפה
#    8 = CRAWLER - זוחל על התקרה ונופל עליך
#    9 = COP     - שוטר עם מגן: יורים ברגליים או מאחור
#   10 = RAT     - חולדות בלהקה. כל פגיעה הורגת
#   11 = HAND    - יד מהביוב שתופסת את הרגל
#   12 = MECH    - זומבי בתוך רובוט על גלגלים עם מכונת ירייה (רק הנהג פגיע)
#   13 = HURLER  - ענק שמרים זומבי קטן וזורק אותו עליך
#   14 = IMP     - זומבי קטן ומהיר עם כידון
#   15 = DOG     - כלב זומבי מהיר (תמיד בזוג, כל אחד רץ בזמן אחר)
#   16 = DRUNK   - זומבי בחליפה קרועה עם אקדח, הולך כמו שיכור ומפספס הרבה
#   17 = GUNNER  - זומבי עם מקלע על חצובה ומגן פלדה מלפנים
#   18 = JETPACK - עף עם ג'טפאק (בקושי שולט בו) ויורה מלמעלה. מת = מתרסק ומתפוצץ
#   19 = HOUND   - בוס: כלב ענק עם שרשרת קוצים
#  * ירייה בראש (HEADSHOT) = מוות מיידי.
#  * 2 קליעים ברגליים = הרגל נתלשת והזומבי מקפץ על רגל אחת.
#  * זומבי שעובר ליד רגל שנפלה מרים אותה וזורק אותה על השחקן.
#  נקודת ה-(0,0) של הזומבי היא כפות הרגליים.
# ============================================================

const Art := preload("res://art.gd")
const BloodScript := preload("res://blood_drop.gd")
const RagdollScript := preload("res://effects/ragdoll.gd")   # גופה רכה
const HeadScript := preload("res://effects/flying_head.gd")   # ראש שעף (מוות "הולך בלי ראש")
const GibScript := preload("res://effects/gib.gd")             # חלקי גוף (מוות "מתפוצץ לחתיכות", רגליים של "פלג גוף זוחל")
const CharScript := preload("res://effects/char_bones.gd")     # מוות "נשרף עד העצמות"
const DEATH_FLING := 0.5     # כמה רחוק הגופה עפה מהפגיעה האחרונה (1 = כמו פעם)
const BLOOD_AMOUNT := 0.5    # כמות הדם (1 = כמו פעם)
const LegScript := preload("res://severed_leg.gd")
const AcidScript := preload("res://acid.gd")
const FireScript := preload("res://fire.gd")
const FlameFx := preload("res://effects/flame_fx.gd")
const PickupScript := preload("res://pickup.gd")
const SporeScript := preload("res://effects/spore_lesson.gd")   # פטגוניה: הנבגים מעבירים את השיעור (THEY LEARN)
const SPORE_FROM := 55              # מאיזה שלב רואים את הנבגים עוברים מהמת לחי הכי קרוב
const DebrisScript := preload("res://debris.gd")
const Particles := preload("res://particles.gd")
const FleshFx := preload("res://effects/flesh_fx.gd")
const Arsenal := preload("res://progression/arsenal.gd")
const GrenadeScript := preload("res://grenade.gd")
const Boom := preload("res://explosion.gd")
const Brain := preload("res://ai/zombie_brain.gd")             # המוח (טקטיקה, תורות, איגוף) - ai/zombie_brain.gd
const Registry := preload("res://enemies/zombie_registry.gd")  # סוגי זומבים חדשים (20+) - enemies/types/*.gd
const Parts := preload("res://characters/parts.gd")   # חלקים של דמויות מ-CHARACTER MAKER (cust)
# סוגים שהמוח מזיז (לשאר יש לוגיקת תנועה משלהם)
const BRAIN_KINDS := [0, 1, 2, 4, 9, 14, 16]
var DOG_TEX: Texture2D = preload("res://tex_load.gd").get_tex("res://sprites/dog.png")   # ספרייט כלב זומבי (נטען בזמן ריצה)

enum { WALKER, RUNNER, BRUTE, SPITTER, SCREAMER, BOSS, BLOATER, CONDUCTOR, CRAWLER, COP, RAT, HAND, MECH, HURLER, IMP, DOG, DRUNK, GUNNER, JETPACK, HOUND }

## סוג הזומבי (main.gd בוחר באקראי)
@export_enum("Walker", "Runner", "Brute", "Spitter", "Screamer", "Boss", "Bloater", "Conductor", "Crawler", "Cop", "Rat", "Hand", "Mech", "Hurler", "Imp", "Dog", "Drunk", "Gunner", "Jetpack", "Hound") var kind := 0

# ---- נתוני כל סוג (אפשר לשנות) ----
const KINDS := [
	{   # WALKER
		"hp": 30, "walk": 45.0, "chase": 95.0, "damage": 1, "bite_delay": 0.8, "scale": 1.0, "width": 1.0, "duck": 0.25, "cover": 0.45,
		"skin": Color("86a06a"), "shirt": Color("4f6688"), "pants": Color("3d3a4c"), "shoe": Color("2c241e"),
	},
	{   # RUNNER
		"hp": 30, "walk": 70.0, "chase": 175.0, "damage": 1, "bite_delay": 0.6, "scale": 0.97, "width": 0.85, "duck": 0.4, "cover": 0.6,
		"skin": Color("aab7a6"), "shirt": Color("8c3434"), "pants": Color("33402f"), "shoe": Color(0, 0, 0, 0),
	},
	{   # BRUTE
		"hp": 30, "walk": 28.0, "chase": 62.0, "damage": 2, "bite_delay": 1.2, "scale": 1.25, "width": 1.35, "duck": 0.1, "cover": 0.25,
		"skin": Color("6c8450"), "shirt": Color("b9b29a"), "pants": Color("34466a"), "shoe": Color("1e1a16"),
	},
	{   # SPITTER
		"hp": 30, "walk": 40.0, "chase": 75.0, "damage": 1, "bite_delay": 0.9, "scale": 0.95, "width": 0.92, "duck": 0.2, "cover": 0.5,
		"skin": Color("a8b04a"), "shirt": Color("5a6a3a"), "pants": Color("3a3a30"), "shoe": Color("2a241e"),
	},
	{   # SCREAMER
		"hp": 30, "walk": 50.0, "chase": 130.0, "damage": 1, "bite_delay": 0.7, "scale": 1.08, "width": 0.78, "duck": 0.3, "cover": 0.3,
		"skin": Color("c8c2bc"), "shirt": Color("3a3036"), "pants": Color("2a2a2e"), "shoe": Color(0, 0, 0, 0),
	},
	{   # BOSS
		"hp": 400, "walk": 32.0, "chase": 70.0, "damage": 2, "bite_delay": 1.4, "scale": 1.75, "width": 1.6, "duck": 0.0, "cover": 0.0,
		"skin": Color("5e7444"), "shirt": Color("8a8270"), "pants": Color("2e3a52"), "shoe": Color("141210"),
	},
	{   # BLOATER
		"hp": 20, "walk": 40.0, "chase": 120.0, "damage": 2, "bite_delay": 1.0, "scale": 1.0, "width": 1.1, "duck": 0.0, "cover": 0.0,
		"skin": Color("9aa860"), "shirt": Color("6a5a40"), "pants": Color("3a3428"), "shoe": Color("2a241e"),
	},
	{   # CONDUCTOR
		"hp": 500, "walk": 30.0, "chase": 75.0, "damage": 2, "bite_delay": 1.4, "scale": 1.8, "width": 1.6, "duck": 0.0, "cover": 0.0,
		"skin": Color("5a6a50"), "shirt": Color("26324e"), "pants": Color("1e2430"), "shoe": Color("141210"),
	},
	{   # CRAWLER
		"hp": 25, "walk": 60.0, "chase": 150.0, "damage": 1, "bite_delay": 0.7, "scale": 0.95, "width": 0.9, "duck": 0.0, "cover": 0.0,
		"skin": Color("9aa89a"), "shirt": Color("3a3a3a"), "pants": Color("2a2a2a"), "shoe": Color(0, 0, 0, 0),
	},
	{   # COP
		"hp": 40, "walk": 40.0, "chase": 85.0, "damage": 1, "bite_delay": 0.9, "scale": 1.05, "width": 1.05, "duck": 0.0, "cover": 0.2,
		"skin": Color("8aa070"), "shirt": Color("22324a"), "pants": Color("1a2232"), "shoe": Color("101010"),
	},
	{   # RAT
		"hp": 1, "walk": 60.0, "chase": 210.0, "damage": 1, "bite_delay": 1.2, "scale": 0.25, "width": 0.6, "duck": 0.0, "cover": 0.0,
		"skin": Color("4a3e36"), "shirt": Color("4a3e36"), "pants": Color("4a3e36"), "shoe": Color(0, 0, 0, 0),
	},
	{   # HAND
		"hp": 12, "walk": 0.0, "chase": 0.0, "damage": 1, "bite_delay": 2.0, "scale": 1.0, "width": 0.8, "duck": 0.0, "cover": 0.0,
		"skin": Color("7a8a60"), "shirt": Color("7a8a60"), "pants": Color("7a8a60"), "shoe": Color(0, 0, 0, 0),
	},
	{   # MECH
		"hp": 90, "walk": 35.0, "chase": 60.0, "damage": 1, "bite_delay": 1.0, "scale": 1.25, "width": 1.5, "duck": 0.0, "cover": 0.0,
		"skin": Color("8a9a70"), "shirt": Color("4a4a40"), "pants": Color("3a3a34"), "shoe": Color(0, 0, 0, 0),
	},
	{   # HURLER
		"hp": 120, "walk": 30.0, "chase": 70.0, "damage": 2, "bite_delay": 1.2, "scale": 1.5, "width": 1.45, "duck": 0.0, "cover": 0.1,
		"skin": Color("6a7a52"), "shirt": Color("5a3a2a"), "pants": Color("2a2a30"), "shoe": Color("1a1612"),
	},
	{   # IMP
		"hp": 15, "walk": 70.0, "chase": 185.0, "damage": 1, "bite_delay": 0.6, "scale": 0.62, "width": 0.85, "duck": 0.2, "cover": 0.0,
		"skin": Color("a0b080"), "shirt": Color("7a3030"), "pants": Color("3a3030"), "shoe": Color(0, 0, 0, 0),
	},
	{   # DOG
		"hp": 20, "walk": 80.0, "chase": 270.0, "damage": 1, "bite_delay": 0.7, "scale": 0.62, "width": 1.6, "duck": 0.0, "cover": 0.0,
		"skin": Color("5a4636"), "shirt": Color("5a4636"), "pants": Color("5a4636"), "shoe": Color(0, 0, 0, 0),
	},
	{   # DRUNK
		"hp": 30, "walk": 35.0, "chase": 70.0, "damage": 1, "bite_delay": 0.9, "scale": 1.0, "width": 1.0, "duck": 0.1, "cover": 0.2,
		"skin": Color("8a9a78"), "shirt": Color("2a2c34"), "pants": Color("24262c"), "shoe": Color("141414"),
	},
	{   # GUNNER
		"hp": 50, "walk": 0.0, "chase": 0.0, "damage": 1, "bite_delay": 1.0, "scale": 1.0, "width": 1.25, "duck": 0.0, "cover": 0.0,
		"skin": Color("7a8a62"), "shirt": Color("3a4a2a"), "pants": Color("2e3a24"), "shoe": Color("1a1a14"),
	},
	{   # JETPACK
		"hp": 25, "walk": 0.0, "chase": 0.0, "damage": 1, "bite_delay": 1.0, "scale": 0.95, "width": 0.95, "duck": 0.0, "cover": 0.0,
		"skin": Color("90a080"), "shirt": Color("5a5a62"), "pants": Color("34343a"), "shoe": Color("1a1a1a"),
	},
	{   # HOUND (בוס)
		"hp": 500, "walk": 60.0, "chase": 120.0, "damage": 2, "bite_delay": 1.0, "scale": 1.4, "width": 3.2, "duck": 0.0, "cover": 0.0,
		"skin": Color("4a3a2e"), "shirt": Color("4a3a2e"), "pants": Color("4a3a2e"), "shoe": Color(0, 0, 0, 0),
	},
]

var chase_range := 520.0         # מאיזה מרחק הוא מתחיל לרדוף
var possessed: Node = null       # MIND CONTROL (effects/mind_control.gd): השחקן שולט בו - הסשן מזיז אותו
static var mind_traitor: Node = null   # הזומבי שבשליטת השחקן כרגע: כל השאר מתנפלים עליו
var throw_range := 430.0         # מאיזה מרחק הוא זורק רגל
var jump_velocity := -560.0
var gravity := 1500.0
var corpse_time := 7.0           # כמה שניות הגופה נשארת

# ---- נזק מקליעים (לכל זומבי יש 30 נקודות חיים) ----
var leg_damage := Vector2i(7, 10)     # פגיעה ברגל: בין 7 ל-10
var body_damage := Vector2i(12, 15)   # פגיעה בגוף: בין 12 ל-15
var head_damage := 30                 # פגיעה בראש

var world_w := 100000.0          # רוחב העולם (main.gd קובע)
# רמת קושי (main.gd קובע): מהירות, וכמה הזומבים "חכמים" (מתכופפים / מתחבאים)
var speed_mult := 1.0
var smart_mult := 1.0
var hp := 3
var max_hp := 30
var dead := false
## זומבי ששוכב על הריצפה וקם כשהשחקן מתקרב (main.gd קובע)
var dormant := false
var wake_range := 230.0
const RISE_TIME := 0.9
var _rise_t := 0.0
var _lie_side := 1.0
# ---- התנהגויות מיוחדות ----
var _alert_t := 0.0              # שמע רעש / צרחה: רודף גם מרחוק
var _rush_t := 0.0               # מסתער (כשיורים על חבר שמתחבא)
var _burn_t := 0.0               # בוער (קליעי אש)
var _burn_acc := 0.0
var _fire: Node2D = null
var _spit_cd := 1.5
var _spit_anim := 0.0
var _screamed := false
var _scream_t := 0.0
var _slam_t := 0.0               # בוס: מכין מכה (המגן למטה!)
var _slam_cd := 0.0
var on_ceiling := false          # זוחל: הולך על התקרה (הפוך)
var _transformer := 3            # מוליך: כמה פגיעות בגב נשארו לשנאי
var _orb_cd := 3.0
var _train_cd := 4.0
var _windup_t := 0.0
var _charge_dir := 1.0
var _stun_t := 0.0
var _grab_state := 0             # יד: 0 = מחכה מתחת למים, 1 = תופסת, 2 = נסוגה
var _grab_t := 0.0
var _charge_t := 0.0
var _det := [false, false, false, 0.0, 0.0, false]   # פרטים: [ריקבון, תפרים, רצועת בשר, x, y, לחי קרועה]
# ---- שלב 3: רובוט / זורק / קטן ----
var _imp: Node = null            # זורק: הזומבי הקטן שהוא מחזיק
var _carrier: Node = null        # קטן: מי מחזיק אותו
var _thrown := false             # קטן: עף באוויר
var _spin_a := 0.0
var _hurl_cd := 2.0
var _hurl_wind := 0.0
var _gun_cd := 2.0               # רובוט: מכונת ירייה
var _aim_t := 0.0
var _burst := 0
var _burst_t := 0.0
var _gun_ang := 0.0
var _muzzle_t := 0.0
# ---- שלב 4 ----
var _hold_t := randf_range(0.0, 1.6)   # כלב: מחכה רגע לפני שהוא מסתער (כל כלב בזמן אחר)
var _ground_y := 0.0             # ג'טפאק: גובה הריצפה
var _tilt := 0.0
var _crashing := false
var _hstate := 0                 # בוס כלב: 0 מסתובב, 1 מתכופף, 2 זינוק, 3 מתנשף, 4 שרשרת
var _ht := 2.0
var _lunge_dir := 1.0
var _lunge_hit := false
var _cycle := 0
var _groan_t := randf_range(1.0, 6.0)   # צליל אנקה
var _voice_cd := 0.0             # זעקות: לא כל הזמן
var _vp := 1.0                   # גובה הקול של הזומבי הזה (כל זומבי נשמע קצת אחרת; גדול = עמוק)
var _noticed := false
var _close_yell := false
var _charge_cd := 3.0
var _swell := 0.0                # נפוח: כמה הוא התנפח (0..1)
var _fuse_t := -1.0              # נפוח: עומד להתפוצץ
const SWELL_TIME := 7.0
var _roar_cd := 3.0              # בוס: שואג ומרים את הדלת - חלון לירות בו מרחוק
var _last_info := {}
var brain = null                 # ai/zombie_brain.gd
var goal_x := INF                # INF = רגיל. אחרת: הולך לנקודה הזו ומתעלם מהשחקן (effects/s33_decor.gd Volcano)
var type_mod = null              # enemies/types/*.gd (סוגים 20+)
var cust = null                  # דמות מ-CHARACTER MAKER (characters/custom_character.gd, סוגים 1000+): הגוף הרגיל + חלקים
var _drop_t := 0.0               # יורד דרך קומה (one-way)
var _stagger_t := 0.0
# שלב 2: רוכב על גג רכבת הרפאים (subway.gd מזיז אותו), נזרק ממנה ונוחת ליד השחקן
var riding := false
var _crash_fly := false
# חולדה שנשכה: השחקן תופס אותה בזנב ומטיח ברצפה (player.gd - RAT SLAM). בינתיים הוא מצייר אותה ביד והיא מוסתרת
var held_by: Node = null
var _belly_up := false           # הוטחה: הגופה שוכבת על הגב
# שלב 2 (ניסוי): מטפסים על מכשולים במקום לקפוץ.  לשנות: CLIMB_LEVELS, CLIMB_SPEED
const CLIMB_LEVELS := [2]
const CLIMB_SPEED := 170.0
var climb_mode := false
var _climbing := false
var _climb_y := INF               # INF = מטפס על קיר עד הקצה. אחרת: עד הגובה הזה (קומה מעליו)
var _climb_time := 0.0
var _decoy_id := 0               # איזה עותק רפאים בדקנו
var _decoy_fooled := true
var _mod_boss := false           # סוג חדש שהוא בוס (stats()["boss"])

var sc := 1.0      # גודל
var wf := 1.0      # רוחב
var hair := Color("3a3026")   # צבע שיער (סוגים 0-19: שונה לכל זומבי - _vary)
var _bald := false
var _gore_arm := false        # עצם חשופה באמה הקדמית
var skin: Color
var shirt: Color
var pants: Color
var shoe: Color
var walk_speed := 45.0
var chase_speed := 95.0
var damage := 1
var bite_delay := 0.8

var _shape: CollisionShape2D
var _dir := 1.0
var _wander_t := 0.0
var _attack_t := 0.0
var _bite_anim := 0.0
var _flash := 0.0
var _walk_phase := 0.0
var _speed_mul := 1.0
var _chasing := false
var _time := 0.0
# פגיעות
var _leg_hits := 0
var _one_leg := false
var _hop_t := 0.0
var _headless := false
var _hw_t := 0.0                  # "הולך בלי ראש": כמה זמן הגוף עוד מדדה אחרי המוות
var _legless := false             # "פלג גוף זוחל": הרגליים נתלשו, זוחל על הידיים
var _char: RefCounted = null      # "נשרף עד העצמות" (effects/char_bones.gd)
var _gibbed := false              # "מתפוצץ לחתיכות": הגוף נעלם, נשארו חלקים
var _hw_age := 0.0
var _hw_spurt := 0.0
# תגובת פגיעה (לפי איפה הכדור פגע): ראש נזרק אחורה / מתקפל מכדור בבטן / קופץ על רגל אחת
const REACT_TIME := {"head": 0.28, "body": 0.38, "leg": 0.5}
var _react_t := 0.0              # כמה זמן נשאר לתגובה
var _react_zone := ""
var _react_push := 1.0           # עוצמה (נשק חזק = תגובה חזקה יותר)
var _react_dx := -1.0            # לאיזה כיוון הכדור דחף (במערכת של הזומבי: -1 = אחורה)
var _wounds: Array[Vector2] = []
# רגל ביד
var _carry: Node2D = null
var _pick_cd := 0.0
var _throw_cd := 0.0
var _throw_anim := 0.0
# אחרי המוות
var _spin := 0.0
var _rag: RefCounted = null      # גופה רכה (effects/ragdoll.gd). null = גופה "קשיחה" רגילה
var _splat_pending := false      # הגופה עפה מהירייה: צליל "שפריץ" כשהיא נוחתת (לא תמיד)
const SPLAT_CHANCE := 0.5
static var _splat_last := 0       # זמן הצליל האחרון (לא כמה ביחד במולטי-קיל)
var _last_hit := Vector2.ZERO    # איפה הפגיעה האחרונה (קובע איך הגופה נופלת)
var _last_boom := false
var _last_god := false            # הפגיעה האחרונה הייתה ב-GOD MODE (הגופה עפה GOD_PUSH רחוק יותר)
var _last_kb := -1.0             # knockback של הנשק שפגע אחרון (-1 = לא נשק). קובע כמה רחוק הגופה עפה
var _kb_shot := 0                # הירייה האחרונה שהדפה אותו (Game.shot_id)
var heavy_kill := false          # נהרג ממכה חזקה (שוטגאן מקרוב / צלף): הגופה עפה ולא מתקפלת במקום (effects/ragdoll.gd)
# ---- תחושת הריגה (gunfeel) ----
const KILL_FLING := Vector2(0.75, 1.75)   # מכפיל עיפת הגופה: [נשק חלש, נשק חזק] לפי knockback (SMG ~0.9, רובה ~1.2, שוטגאן/צלף ~1.7)
const HEAVY_KB := 150.0                   # knockback מזה ומעלה = מכה חזקה
const GOD_PUSH := 1.35                    # GOD MODE (src "god" מ-bullet.gd): כל פגיעה הודפת 35% חזק יותר (הדיפה, תגובה, עיפת הגופה)
const HITSTOP_HEAD := 0.045               # עצירת זמן קטנה בהריגה בראש (שניות אמיתיות)
const HITSTOP_HEAVY := 0.055              # ... בהריגה ממכה חזקה
const HITSTOP_BOSS := 0.28                # ... במוות של בוס
const HEAD_HEAVY := 1.6                   # נשק עם damage מעל זה: גם הראש מוכפל (x damage x HEAD_HEAVY_K), לא בבוס
const HEAD_HEAVY_K := 0.6
var _angle := 0.0
var _dead_t := 0.0
var _land_t := -1.0               # מתי הגופה נגעה בריצפה (כלב בועט / מקלען) - לפי _dead_t
# גופה ששוכבת בשקט לא מצוירת מחדש (הציור הקודם נשאר על המסך). עד עכשיו כל גופה צוירה מחדש כל 3-6 פריימים
# במשך 7 שניות (~1 ms כל ציור) - הריגה המונית = עשרות ציורים מיותרים בכל פריים. ראה _corpse_redraw
var _c_hash := -1                 # "טביעת האצבע" של הציור האחרון (DrawBatch.signature: כל הנקודות והצבעים)
var _c_same := 0                  # כמה ציורים ברצף יצאו זהים לקודם
var _c_angle := 0.0               # הזווית בציור האחרון
var _lod_dead := false            # גופה: הפרטים הזעירים כמו ברגע המוות (לא מתחלפים כשזומבים אחרים נכנסים / יוצאים מהמסך)
var _gburst := 0                  # מקלען מת: כמה יריות אחרונות כבר נשמעו
var _bled_on: Dictionary = {}
# ---- התחמקות ומחסה ----
var duck_chance := 0.25          # הסיכוי להתכופף כשיורים לכיוונו
var cover_chance := 0.45         # הסיכוי לברוח למחסה כשהוא נפגע
var cover_search := 380.0        # כמה רחוק הוא מחפש מחסה
var _duck_t := 0.0
var _duck_cd := 0.0
var _crouch_k := 0.0
var _crouched_shape := false
var _cover_state := 0            # 0 = רגיל, 1 = רץ למחסה, 2 = מתחבא
var _cover_node: Node = null
var _cover_x := 0.0
var _cover_y := 0.0
var _cover_dir := 1.0
var _cover_t := 0.0
var _think_t := 0.0


func _ready() -> void:
	add_to_group("zombies")
	if kind == DOG or kind == HOUND:   # ספרייט מוקטן - חלק בלי ריצוד
		texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	var k: Dictionary
	if kind >= Registry.FIRST and Registry.has(kind):   # סוג חדש: הנתונים מהמודול שלו
		type_mod = Registry.make(kind)
		type_mod.z = self
		k = type_mod.stats()
		_mod_boss = k.get("boss", false)
		if type_mod.base_body():
			cust = type_mod
	else:
		k = KINDS[clampi(kind, 0, KINDS.size() - 1)]
	hp = k.hp + (100 * (mini(Game.level, 5) - 1) if is_boss() else 0)   # שלבים מאוחרים: הבוס לא "ספוג" יותר - הוא חכם יותר
	if is_boss():
		hp = int(float(hp) * Game.harder())   # שלבים 1-57: בוס +25% חיים
	max_hp = hp
	climb_mode = Game.level in CLIMB_LEVELS
	walk_speed = k.walk
	chase_speed = k.chase
	damage = k.damage
	bite_delay = k.bite_delay
	duck_chance = clampf(k.duck * smart_mult, 0.0, 0.9)
	cover_chance = clampf(k.cover * smart_mult, 0.0, 0.9)
	walk_speed *= speed_mult
	chase_speed *= speed_mult
	_think_t = randf_range(1.0, 3.0)
	sc = k.scale
	wf = k.width
	_vp = clampf(randf_range(0.88, 1.12) / sqrt(maxf(float(k.scale), 0.3)), 0.7, 1.3)
	# כל הזומבים בגובה של הדמות הראשית, ורזים יותר
	if is_boss():
		sc *= 0.92
	elif kind == DOG:
		sc *= 0.88
	elif kind in [MECH, GUNNER, RAT, HAND]:
		sc *= 0.8 if kind == MECH else 0.9
	else:
		sc *= 0.88
		wf *= 0.84
		if kind == BRUTE or kind == HURLER:   # ענקים: גדולים, אבל לא ענקיים ליד הדמות
			sc *= 0.86
	var drng := RandomNumberGenerator.new()   # פרטים קבועים לכל זומבי (ריקבון, תפרים, קרעים)
	drng.seed = get_instance_id()
	_det = [drng.randf() < 0.5, drng.randf() < 0.4, drng.randf() < 0.5, drng.randf_range(-3.0, 3.0), drng.randf_range(-2.0, 4.0), drng.randf() < 0.35]
	var tint := randf_range(-0.08, 0.08)
	skin = Art.shade(k.skin, tint)
	shirt = Art.shade(k.shirt, randf_range(-0.1, 0.1))
	pants = k.pants
	shoe = k.shoe
	if type_mod == null:
		_vary(drng)
	collision_layer = 4   # שכבה 3 (ערך 4) = זומבים. הקליעים פוגעים בה
	collision_mask = 1 | 16   # מתנגש בעולם (1) ובקומות (16, one-way)
	_shape = CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = Vector2(38.0 * wf, 66.0 * sc)   # אזור פגיעה גדול מהציור - כדי שכל ירייה על הזומבי תיתפס
	_shape.shape = r
	_shape.position = Vector2(0.0, 33.0 * sc if on_ceiling else -33.0 * sc)
	add_child(_shape)
	if kind == DOG or kind == HOUND:   # אזור פגיעה בגודל הספרייט (כולל הראש)
		r.size = Vector2(70.0, 48.0) * (0.8 if kind == DOG else 2.0)
		_shape.position = Vector2(0.0, -r.size.y / 2.0)
	if kind == HAND:
		collision_layer = 0   # מתחת למים אי אפשר לפגוע בה
	if dormant:
		r.size = Vector2(52, 18) * sc   # שוכב: כל אורך הגוף
		_shape.position = Vector2(0.0, -9.0 * sc)
		_lie_side = -1.0 if randf() < 0.5 else 1.0
	_dir = -1.0 if randf() < 0.5 else 1.0
	_speed_mul = randf_range(0.85, 1.2)
	if kind == JETPACK:   # מתחיל באוויר
		_ground_y = position.y
		position.y -= 230.0
	_walk_phase = randf() * TAU
	_time = randf() * 10.0
	z_index = 3
	# המוח: כמה חכם הזומבי בשלב הזה (ai/intelligence_profile.gd)
	brain = Brain.new()
	var smart := smart_mult / maxf(Game.intelligence(), 0.01)   # רמת הקושי (בלי תוספת השלב)
	brain.setup(self, Game.level, smart, type_mod.brain_overrides() if type_mod != null else {})
	brain.steer_movement = type_mod.use_brain_movement() if type_mod != null else kind in BRAIN_KINDS
	if type_mod != null:
		type_mod.setup()


# ---- פרופיילר (בדיקות ביצועים בלבד, כבוי במשחק): זמן לוגיקה / ציור לכל סוג זומבי ----
static var prof_on := false
static var prof := {}
var _bslot := randi() % 4
var _bs_ratio := -1.0
var _bs_dir := 1.0


func _physics_process(delta: float) -> void:
	if prof_on:
		var t0 := Time.get_ticks_usec()
		_physics_main(delta)
		var k := "logic:" + _prof_name()
		prof[k] = int(prof.get(k, 0)) + Time.get_ticks_usec() - t0
		return
	_physics_main(delta)


func _prof_name() -> String:
	return str(type_mod.stats().name) if type_mod != null else str(kind)


func _physics_main(delta: float) -> void:
	_time += delta
	_flash -= delta
	_react_t -= delta
	_voice_cd -= delta
	_attack_t -= delta
	_bite_anim -= delta
	_pick_cd -= delta
	_throw_cd -= delta
	_throw_anim -= delta
	if dead:
		if kind == JETPACK and _crashing:
			_jet_crash(delta)
			return
		_dead_process(delta)
		return
	if possessed != null and is_instance_valid(possessed):   # MIND CONTROL: השחקן מזיז אותו
		possessed.drive(self, delta)
		_maybe_redraw()
		return
	if riding:   # על גג הרכבת: subway.gd מזיז אותו
		_maybe_redraw()
		return
	if held_by != null:   # RAT SLAM: ביד של השחקן
		if is_instance_valid(held_by):
			return
		held_by = null
		visible = true
		collision_layer = 4
	if _legless:   # פלג גוף זוחל
		_crawl_logic(get_tree().get_first_node_in_group("player"), delta)
		return
	if _crash_fly:   # נזרק מהרכבת: מתגלגל באוויר עד הנחיתה
		_crash_fly_process(delta)
		return

	var player := get_tree().get_first_node_in_group("player")
	# שוכב על הריצפה עד שהשחקן מתקרב
	if dormant:
		var wr: float = wake_range * (0.45 if player != null and player._crouching else 1.0)   # מתכופף = שקט
		if player != null and not player.dead and absf(player.global_position.x - global_position.x) < wr \
				and absf(player.global_position.y - global_position.y) < 120.0:
			_wake()
		return
	if kind == HAND:
		_hand_logic(player, delta)
		return
	if on_ceiling:
		_ceiling_logic(player, delta)
		return
	if kind == IMP and (_carrier != null or _thrown):
		_imp_air(player, delta)
		return
	if kind == JETPACK:
		_jet_logic(player, delta)
		return
	if _stagger_t > 0.0:   # הדף (DARK PULSE): מתנדנד, לא תוקף
		_stagger_t -= delta
		if not is_on_floor():
			velocity.y += gravity * delta
		velocity.x = move_toward(velocity.x, 0.0, 500.0 * delta)
		move_and_slide()
		_maybe_redraw()
		return
	if _rise_t > 0.0:   # קם לאט
		_rise_t -= delta
		if Art.on_screen(self, global_position):
			queue_redraw()
		return
	# בוער מקליעי אש: נזק כל שנייה
	if _burn_t > 0.0:
		_burn_t -= delta
		_burn_acc += 7.0 * delta
		if Engine.get_physics_frames() % 12 == 0 and Art.on_screen(self, global_position):
			var bc := global_position + Vector2(randf_range(-6, 6), -randf_range(10, 45) * sc)
			Particles.burst(get_parent(), bc, "fire", Vector2.ZERO, 4)
			Particles.burst(get_parent(), bc, "smoke", Vector2.ZERO, 2)
		if _burn_acc >= 3.0:
			var d := int(_burn_acc)
			_burn_acc -= float(d)
			take_damage(d, global_position + Vector2(0, -30.0 * sc), Vector2.ZERO, true, {"source": "fire"})
			if dead:
				return
		if _burn_t <= 0.0 and is_instance_valid(_fire):
			_fire.queue_free()
	_alert_t -= delta
	_rush_t -= delta
	_spit_cd -= delta
	_spit_anim -= delta
	# אנקות / נהמות של כל זומבי שעל המסך (לא רק כשהוא רודף)
	_groan_t -= delta
	if _groan_t <= 0.0:
		_groan_t = randf_range(3.0, 7.0)
		if kind != RAT and kind != HAND and kind != MECH and (type_mod == null or type_mod.can_groan()):
			var nm := "growl" if kind == DOG or kind == HOUND else ("roar" if is_boss() else "groan")
			if Art.on_screen(self, global_position):
				Sfx.play(nm, global_position, 0.0 if not is_boss() else 3.0, 0.08, 3, _vp)
			elif randf() < 0.3 and Art.on_screen(self, global_position, 520.0):   # ממש מחוץ למסך: אנקה רחוקה מהצד שלו - שומעים לפני שרואים
				Sfx.play(nm, global_position, -4.0 if not is_boss() else -1.0, 0.08, 2, _vp * 0.94)
	# רחוק מאוד מהשחקן: הזומבי "ישן" (חוסך המון ביצועים)
	if player != null and absf(player.global_position.x - global_position.x) > 1400.0 and is_on_floor() and _carry == null and not _traitor_near():   # (ליד הזומבי של MIND CONTROL - ער)
		return
	if _drop_t > 0.0:   # ירד דרך קומה: חוזר להתנגש בקומות
		_drop_t -= delta
		if _drop_t <= 0.0:
			collision_mask |= 16
	# סוג חדש עם תנועה מיוחדת (מטפס / זוחל על קירות / קופץ...)
	if type_mod != null and type_mod.physics(player, delta):
		_maybe_redraw()
		return
	if _climbing:
		_climb_process(delta)
		return

	if not is_on_floor():
		velocity.y += gravity * delta

	# ---- התכופפות ----
	_duck_t -= delta
	_duck_cd -= delta
	var want_crouch := (_duck_t > 0.0 or _cover_state == 2) and not _one_leg
	_crouch_k = move_toward(_crouch_k, 1.0 if want_crouch else 0.0, delta * 10.0)
	_set_crouch(_crouch_k > 0.6)   # אזור הפגיעה יורד רק כשהציור באמת התכופף

	var target_speed := walk_speed
	_chasing = false
	if goal_x < INF:   # פקודה מבחוץ (שלב 33: לרוץ למחסה מגל האפר) - מתעלמים מהשחקן
		var gd := goal_x - global_position.x
		_dir = signf(gd) if absf(gd) > 6.0 else _dir
		target_speed = chase_speed * 1.25 if absf(gd) > 12.0 else 0.0
	elif _cover_state != 0:
		target_speed = _cover_process(delta, player)
	elif player != null and not player.dead and (global_position.distance_to(player.global_position) < chase_range * (0.45 if Game.player_dark and not is_boss() else 1.0) or _alert_t > 0.0 or _traitor_near()):   # בחושך רואים פחות
		_chasing = true
		var tp: Node = _target_for_brain(player)   # DECOY ECHO: אולי הולך אחרי עותק הרפאים
		_dir = signf(tp.global_position.x - global_position.x)
		if not _noticed:   # ראה את השחקן: זעקה
			_noticed = true
			Game.story.emit("boss" if is_boss() else "notice", {"z": self})
			_voice("zscream", 0.9, 3.0)
			if brain != null:   # משלב 5: מזעיק חברים
				brain.on_notice(self, player)
		if not _close_yell and global_position.distance_to(player.global_position) < 130.0:   # מתקרב
			_close_yell = true
			_voice("zscream", 0.8, 4.0)
		if _dir == 0.0:
			_dir = 1.0
		target_speed = chase_speed
		if _rush_t > 0.0:
			target_speed *= 1.35
		var d: Vector2 = tp.global_position - global_position
		# המוח: תורות התקפה, איגוף, המתנה, נסיגה, גבהים (ai/zombie_brain.gd)
		if brain != null and tp == player:   # (הבוגד של MIND CONTROL: הולכים אליו ישר)
			# ביצועים: המוח רץ כל פריים שני (30 פעמים בשנייה - מספיק להחלטות). בפריים שביניהם - אותו כיוון ואותו יחס מהירות.
			# המשחק איטי (quality.gd רמה 2+) וזומבי מחוץ למסך: כל פריים רביעי (אף אחד לא רואה אותו; על המסך - תמיד 30)
			var bdiv := 4 if Quality.level >= 2 and not Art.on_screen(self, global_position, 120.0) else 2
			if _bs_ratio < 0.0 or (Engine.get_physics_frames() + _bslot) % bdiv == 0:
				var bs: float = brain.steer(self, tp, d, delta * (1.0 if _bs_ratio < 0.0 else float(bdiv)), target_speed)
				_bs_ratio = bs / target_speed if target_speed > 0.01 else 1.0
				_bs_dir = _dir
				if brain.steer_movement:
					target_speed = bs
			elif brain.steer_movement:
				target_speed *= _bs_ratio
				_dir = _bs_dir
		if type_mod != null:
			target_speed = type_mod.logic(player, d, delta, target_speed)
		match kind:
			SPITTER:
				target_speed = _spitter_logic(player, d)
			SCREAMER:
				if not _screamed and absf(d.x) < 520.0:
					_scream()
				if _scream_t > 0.0:
					_scream_t -= delta
					target_speed = 0.0
			BOSS:
				target_speed = _boss_logic(player, d, delta)
			CONDUCTOR:
				target_speed = _conductor_logic(player, d, delta)
			MECH:
				target_speed = _mech_logic(player, d, delta)
			HURLER:
				target_speed = _hurler_logic(player, d, delta)
			DOG:
				target_speed = _dog_logic(player, d, delta)
			DRUNK:
				target_speed = _drunk_logic(player, d, delta)
			GUNNER:
				target_speed = _gunner_logic(player, d, delta)
			HOUND:
				target_speed = _hound_logic(player, d, delta)
			IMP:   # מחכה ליד הזורק (הוא "התחמושת" שלו), אלא אם השחקן ממש קרוב
				if absf(d.x) > 90.0 and _near_hurler():
					target_speed = 0.0
			BLOATER:
				target_speed = _bloater_logic(d, delta)
				if dead:
					return
		# נשיכה
		if kind != BOSS and kind != BLOATER and kind != MECH and kind != HOUND and kind != GUNNER and _charge_t <= 0.0 and absf(d.x) < 16.0 + 10.0 * wf and absf(d.y) < 50.0 and _attack_t <= 0.0 \
				and (type_mod == null or type_mod.can_bite()):
			_attack_t = bite_delay
			_bite_anim = 0.25
			var charging: bool = brain != null and brain.is_charging()
			# חולדה: הנשיכה פוגעת כרגיל, ואז השחקן תופס אותה בזנב ומטיח אותה ברצפה (player.gd - rat_slam)
			var slam: bool = kind == RAT and tp == player and player.has_method("rat_slam") and player.can_rat_slam()
			tp.hurt(damage + (1 if charging else 0), Vector2(_dir * (2.0 if charging else 1.0), 0.0))
			if brain != null:
				brain.on_bite(self)
			if type_mod != null:
				type_mod.on_bite(player)
			if slam:
				player.rat_slam(self)
		# לפעמים, כשהשחקן מכוון אליו מרחוק, הוא מתקדם ממחסה למחסה
		_think_t -= delta
		if _think_t <= 0.0:
			_think_t = randf_range(2.5, 4.5)
			var far := absf(d.x) > 240.0
			var aimed: bool = player._aim.dot((global_position - player.global_position).normalized()) > 0.85
			if far and aimed and not is_boss() and randf() < cover_chance * 0.4:
				_try_cover(player)
	else:
		_wander_t -= delta
		if _wander_t <= 0.0:
			_wander_t = randf_range(1.5, 4.0)
			_dir = -_dir if randf() < 0.5 else _dir

	_legs_process(player)

	if _one_leg:
		# קפיצות על רגל אחת
		if is_on_floor():
			velocity.x = move_toward(velocity.x, 0.0, 1400.0 * delta)
			_hop_t -= delta
			if _hop_t <= 0.0:
				_hop_t = randf_range(0.12, 0.3)
				velocity.y = -250.0 if not is_on_wall() else jump_velocity * 0.85
				velocity.x = _dir * maxf(target_speed * _speed_mul * 0.8, 70.0)
	else:
		if _duck_t > 0.0:
			target_speed *= 0.3   # מתכופף = כמעט לא זז
		if _react_t > 0.0 and _react_zone != "head":   # נפגע ברגל / בבטן: מאט לרגע
			target_speed *= 0.4 if _react_zone == "leg" else 0.6
		if has_meta("drum_t") and float(get_meta("drum_t")) > _time:   # DRUMMER (שלב 41): צועדים בקצב התוף - מהר יותר
			target_speed *= 1.3
		velocity.x = move_toward(velocity.x, _dir * target_speed * _speed_mul, 600.0 * delta)
	move_and_slide()

	# נתקע בקיר: קופץ (או מסתובב אם הוא סתם מטייל)
	if is_on_wall() and is_on_floor() and not _one_leg and kind != MECH:
		if _chasing or _cover_state == 1 or goal_x < INF:   # (גם בדרך לנקודה שקיבל פקודה ללכת אליה)
			if climb_mode:
				_start_climb(INF)
			else:
				velocity.y = jump_velocity
		else:
			_dir = -_dir

	if global_position.x < 20.0:
		global_position.x = 20.0
		_dir = 1.0
	elif global_position.x > world_w - 20.0:
		global_position.x = world_w - 20.0
		_dir = -1.0

	if is_on_floor():
		_walk_phase += delta * absf(velocity.x) * 0.075 / sc
	_maybe_redraw()


# ============================================================
#  התחמקות: התכופפות ומחסה מאחורי מכוניות / מחסומים / ארגזים
# ============================================================
# נקרא מ-player.gd בכל ירייה. לפעמים הזומבי מתכופף והקליע עובר מעליו
func on_player_fired(origin: Vector2, aim: Vector2) -> void:
	if dead:
		return
	if type_mod != null and type_mod.has_method("on_shot"):   # CAPOEIRA (שלב 37) רואה את הירייה ומתחמק
		type_mod.on_shot(origin, aim)
	# יורים על זומבי שמתחבא? החברים שלו מסביב מסתערים
	if _cover_state == 2:
		var to := global_position + Vector2(0.0, -20.0 * sc) - origin
		if aim.dot(to.normalized()) > 0.9:
			get_tree().call_group("zombies", "rush", global_position)
		return
	if _lying() or _one_leg or _duck_cd > 0.0:
		return
	var to_me := global_position + Vector2(0.0, -30.0 * sc) - origin
	if to_me.length() > 520.0 or to_me.length() < 60.0 or aim.dot(to_me.normalized()) < 0.93:
		return
	_duck_cd = 2.0
	if randf() < duck_chance:
		_duck_t = randf_range(0.6, 0.9)
		_set_crouch(true)


func _set_crouch(on: bool) -> void:
	if on == _crouched_shape or dead or _lying():
		return
	_crouched_shape = on
	var r := _shape.shape as RectangleShape2D
	r.size.y = (50.0 if on else 66.0) * sc
	_shape.position.y = -r.size.y / 2.0


# מחפש מחסה קרוב בצד הרחוק מהשחקן. אם אין - ממשיך להילחם
func _try_cover(player: Node) -> bool:
	if _one_leg or player == null or player.dead:
		return false
	var px: float = player.global_position.x
	var best_d := INF
	for c in get_tree().get_nodes_in_group("cover"):
		var r: Rect2 = c.cover_rect()
		if r.size.y < 24.0 or absf(r.end.y - global_position.y) > 12.0:
			continue
		var center := r.get_center().x
		var hx := r.end.x + 14.0 * wf if px < center else r.position.x - 14.0 * wf
		var d := absf(hx - global_position.x)
		if d > cover_search or d < 4.0:
			continue
		if (hx - px) * (global_position.x - px) < 0.0 or absf(hx - px) < 120.0:   # בלי לעבור ליד השחקן
			continue
		if not _spot_ok(hx):
			continue
		if d < best_d:
			best_d = d
			_cover_node = c
			_cover_x = hx
			_cover_y = global_position.y
	if best_d == INF:
		return false
	_cover_state = 1
	Game.story.emit("cover", {"z": self})
	_cover_dir = signf(_cover_x - global_position.x)
	_cover_t = 3.5   # אם לא הגיע תוך 3.5 שניות - מוותר
	_duck_t = 0.0
	return true


# האם יש ריצפה במקום ואין שם משהו אחר
func _spot_ok(x: float) -> bool:
	var space := get_world_2d().direct_space_state
	var gy := global_position.y
	var q := PhysicsRayQueryParameters2D.create(Vector2(x, gy - 50.0), Vector2(x, gy + 12.0), 1)
	var hit := space.intersect_ray(q)
	if hit.is_empty() or absf(hit.position.y - gy) > 8.0:
		return false
	var pq := PhysicsPointQueryParameters2D.new()
	pq.collision_mask = 1
	for yy in [20.0, 40.0]:
		pq.position = Vector2(x, gy - yy)
		if not space.intersect_point(pq, 1).is_empty():
			return false
	return true


func _cover_process(delta: float, player: Node) -> float:
	if not is_instance_valid(_cover_node) or player == null or player.dead or _one_leg:
		_end_cover()
		return walk_speed
	var cr: Rect2 = _cover_node.cover_rect()
	var cx := cr.get_center().x
	# השחקן עבר לצד שלו / קרוב מדי - המחסה לא עוזר, חוזר לתקוף
	if signf(player.global_position.x - cx) == signf(_cover_x - cx) or absf(player.global_position.x - global_position.x) < 70.0:
		_end_cover()
		return chase_speed
	_cover_t -= delta
	if _cover_state == 1:
		_chasing = true   # כדי שיקפוץ מעל מכשולים בדרך
		var dx := _cover_x - global_position.x
		var grounded := is_on_floor() and absf(global_position.y - _cover_y) < 10.0
		if grounded and absf(dx) < 14.0:
			_cover_state = 2
			_cover_t = randf_range(2.5, 4.5)
			velocity.x = 0.0
			return 0.0
		# עדיין על מכונית / ארגז: ממשיך באותו כיוון עד שהוא יורד לריצפה
		_dir = _cover_dir if absf(dx) < 14.0 else signf(dx)
		if _cover_t <= 0.0:
			_end_cover()
		return maxf(chase_speed * 1.25, 90.0)
	# מתחבא: מסתכל לכיוון השחקן ומחכה
	_dir = signf(player.global_position.x - global_position.x)
	if _cover_t <= 0.0:
		_end_cover()
	return 0.0


func _end_cover() -> void:
	_cover_state = 0
	_cover_node = null


# ============================================================
#  רעש, הסתערות, שריפה
# ============================================================
# Game.make_noise -> יריות ופיצוצים מעירים זומבים ששוכבים ומושכים זומבים מרחוק
func hear_noise(pos: Vector2, radius: float) -> void:
	if dead or global_position.distance_to(pos) > radius:
		return
	if dormant:
		_wake()
	_alert_t = maxf(_alert_t, 5.0)


func rush(from: Vector2) -> void:
	if dead or _lying() or _cover_state != 0 or is_boss() or global_position.distance_to(from) > 350.0:
		return
	if _rush_t <= 0.0 and Art.on_screen(self, global_position):
		_popup("!!", Color("ff6040"), 18, -78.0)
	_rush_t = 3.0


# קליעי אש: הזומבי בוער כמה שניות
func ignite(t: float) -> void:
	if dead:
		return
	var was := _burn_t
	_burn_t = maxf(_burn_t, t)
	if was > 0.5:   # כבר בוער (להביור / DRAGON'S BREATH מציתים עשרות פעמים בשנייה): רק מאריכים, בלי עוד חלקיקים
		return
	var c := global_position + Vector2(0, -30.0 * sc)
	Particles.burst(get_parent(), c, "fire", Vector2.ZERO, 16)
	Particles.burst(get_parent(), c, "smoke", Vector2.ZERO, 8)


# ---- SPITTER: שומר מרחק ויורק חומצה ----
func _spitter_logic(player: Node, d: Vector2) -> float:
	var dist := absf(d.x)
	if dist < 210.0:   # קרוב מדי - נסוג
		_dir = -signf(d.x)
		return walk_speed * 1.3
	if dist < 440.0:
		_dir = signf(d.x)
		if _spit_cd <= 0.0 and absf(d.y) < 160.0:
			_spit(player)
		return 0.0
	return chase_speed


func _spit(player: Node) -> void:
	_spit_cd = randf_range(2.2, 3.2)
	_spit_anim = 0.35
	var from := global_position + Vector2(_dir * 10.0, -48.0 * sc)
	var target: Vector2 = player.global_position + Vector2(0, -28)
	var t := clampf(absf(target.x - from.x) / 380.0, 0.5, 1.1)
	var g := 900.0
	var v := Vector2((target.x - from.x) / t, (target.y - from.y - 0.5 * g * t * t) / t)
	Sfx.play("spit", global_position)
	var a = AcidScript.new()
	get_parent().add_child(a)
	a.setup(from, v)


# ---- SCREAMER: צורח ומזעיק את כולם ----
func _scream() -> void:
	Sfx.play("scream", global_position, 2.0)
	_screamed = true
	_scream_t = 1.2
	_popup("SCREAM!", Color("e8e0ff"), 18, -84.0)
	Game.make_noise(global_position, 1100.0)
	var cam := get_viewport().get_camera_2d()
	if cam != null and cam.has_method("shake"):
		cam.shake(5.0, 0.6)


# ---- BOSS: מגן מדלת, מכה חזקה והסתערות ----
func _boss_logic(player: Node, d: Vector2, delta: float) -> float:
	_dir = signf(d.x) if d.x != 0.0 else _dir
	_slam_cd -= delta
	_charge_cd -= delta
	_roar_cd -= delta
	if _slam_t > 0.0:   # מרים את הדלת מעל הראש - עכשיו אפשר לפגוע בו!
		_slam_t -= delta
		if _slam_t <= 0.0:
			_slam_cd = 1.6
			var cam := get_viewport().get_camera_2d()
			if cam != null and cam.has_method("shake"):
				cam.shake(10.0, 0.35)
			for i in 8:
				var c = DebrisScript.new()
				get_parent().add_child(c)
				c.setup(global_position + Vector2(_dir * 40.0, -4), Vector2(4, 3), Color("4a4440"), Vector2(randf_range(-160, 160), -randf_range(120, 300)))
			if absf(d.x) < 95.0 and absf(d.y) < 90.0:
				player.hurt(damage, Vector2(_dir, 0.0))
				player.velocity += Vector2(_dir * 380.0, -260.0)
		return 0.0
	if _charge_t > 0.0:
		_charge_t -= delta
		if absf(d.x) < 50.0 and absf(d.y) < 80.0:
			player.hurt(damage, Vector2(_dir, 0.0))
			player.velocity += Vector2(_dir * 420.0, -200.0)
			_charge_t = 0.0
		return chase_speed * 2.6
	if absf(d.x) < 80.0 and _slam_cd <= 0.0:
		_slam_t = 1.3
		_boss_grenades()
		return 0.0
	if absf(d.x) > 160.0 and _roar_cd <= 0.0:   # שואג עם הדלת למעלה: אפשר לירות בו
		_slam_t = 2.4
		_roar_cd = randf_range(4.5, 6.0)
		_popup("ROAR!", Color("ffb040"), 20, -110.0)
		Sfx.play("roar", global_position, 3.0)
		_boss_grenades()
		return 0.0
	if absf(d.x) > 220.0 and _charge_cd <= 0.0:
		_charge_t = 1.1
		_charge_cd = randf_range(5.0, 7.0)
		_popup("CHARGE!", Color("ff5030"), 20, -110.0)
		Sfx.play("roar", global_position, 3.0)
		return chase_speed * 2.6
	return chase_speed


# הבוס מרים את המגן וזורק 2 רימונים למקומות אקראיים
func _boss_grenades() -> void:
	for i in 2:
		var g = GrenadeScript.new()
		g.source = "boss_grenade"
		g.fuse = 1.8
		get_parent().add_child(g)
		var dx := randf_range(150.0, 420.0) * (1.0 if randf() < 0.5 else -1.0)
		var t := randf_range(0.7, 1.0)   # זמן מעוף
		g.setup(global_position + Vector2(0.0, -110.0 * sc), Vector2(dx / t, -0.5 * g.gravity * t + 110.0 * sc / t))


# ---- BLOATER: מתנפח, רץ אל השחקן ומתפוצץ ----
func _bloater_logic(d: Vector2, delta: float) -> float:
	_swell = minf(_swell + delta / SWELL_TIME, 1.0)
	if _fuse_t >= 0.0:
		_fuse_t -= delta
		if _fuse_t <= 0.0:
			_bloat_pop()
		return 0.0
	if (absf(d.x) < 34.0 and absf(d.y) < 60.0) or _swell >= 1.0:
		_fuse_t = 0.45
		_popup("!!", Color("ff4030"), 22, -90.0)
		Game.story.emit("bloater", {"z": self})
		return 0.0
	return chase_speed * (1.0 + 0.4 * _swell)   # ככל שהוא נפוח יותר הוא מהיר יותר


# מתפוצץ ליד השחקן (בלי ניקוד)
func _bloat_pop() -> void:
	dead = true
	remove_from_group("zombies")
	if _carry != null and is_instance_valid(_carry):
		_carry.drop(Vector2(0.0, -150.0))
	_spray_blood(global_position + Vector2(0, -30) * sc, Vector2.UP, 18, 420.0)
	Sfx.play("splat", global_position, 2.0)
	Boom.blast(get_parent(), global_position + Vector2(0.0, -30.0 * sc), 110.0 + 30.0 * _swell, 50.0, 40, 2, "bloater")
	queue_free()


# זעקות / צעקות כאב (עם הפסקה בין צעקה לצעקה)
func _voice(name: String, chance: float, vol: float) -> void:
	if kind == DOG or kind == HOUND:   # כלבים: נביחות ויללות
		if _voice_cd > 0.0 or randf() > chance:
			return
		_voice_cd = randf_range(1.0, 2.0)
		Sfx.play("yelp" if name == "zhit" else "bark", global_position, vol + (4.0 if kind == HOUND else 0.0), 0.15, 3)
		return
	if kind == RAT or kind == HAND or is_boss() or _voice_cd > 0.0 or randf() > chance:
		return
	_voice_cd = randf_range(1.2, 2.2)
	Sfx.play(name, global_position, vol, 0.05, 3, _vp)


func is_boss() -> bool:
	return kind == BOSS or kind == CONDUCTOR or kind == HOUND or _mod_boss


# הדף מיכולת: לא זז ולא תוקף לרגע
func stagger(t: float) -> void:
	if not is_boss():
		_stagger_t = maxf(_stagger_t, t)


# FLARE (abilities/types/flare.gd, group "decoys"): זומבים שהמוח מזיז הולכים אחרי הזיקוק אם הוא קרוב.
# משלב 8 חלק מהם "מזהים" את הטריק (adaptation_level)
func _target_for_brain(player: Node) -> Node:
	if _traitor_near():   # MIND CONTROL: מתנפלים על הזומבי שבשליטת השחקן
		return mind_traitor
	if brain == null or not brain.steer_movement:
		return player
	var dc := get_tree().get_first_node_in_group("decoys")
	if dc == null or dc.dead or dc.global_position.distance_to(global_position) > 560.0:
		return player
	if dc.get_instance_id() != _decoy_id:
		_decoy_id = dc.get_instance_id()
		_decoy_fooled = randf() > float(brain.p.get("adaptation_level", 0.0)) * 0.35
	return dc if _decoy_fooled else player


# MIND CONTROL: יש זומבי בוגד קרוב (לא אני)
func _traitor_near() -> bool:
	return mind_traitor != null and mind_traitor != self and is_instance_valid(mind_traitor) and not mind_traitor.dead \
		and absf(mind_traitor.global_position.x - global_position.x) < 600.0 and absf(mind_traitor.global_position.y - global_position.y) < 200.0


# זומבי אחר נשך אותי (רק כשאני בשליטת השחקן - MIND CONTROL)
func hurt(amount: int, knock_dir: Vector2) -> void:
	if dead or possessed == null:
		return
	var n: int = amount * 8
	take_damage(n, global_position + Vector2(0.0, -30.0 * sc), knock_dir, false, {"source": "zombie", "fixed": n})


# ---- קומות (one-way, שכבה 16): קפיצה למעלה לקומה / ירידה דרכה ----
func hop_up(height: float) -> void:
	if not is_on_floor() or dead:
		return
	if climb_mode:   # מטפס למעלה במקום לקפוץ
		_start_climb(global_position.y - maxf(height, 40.0))
		return
	velocity.y = -sqrt(2.0 * gravity * maxf(height, 40.0))
	velocity.x = _dir * maxf(absf(velocity.x), 60.0)


# ---- טיפוס (שלב 2, ניסוי): נצמד לקיר ועולה לאט, ואז מושך את עצמו מעל הקצה ----
func _start_climb(to_y: float) -> void:
	if _climbing:
		return
	_climbing = true
	_climb_y = to_y
	_climb_time = 0.0
	_voice("groan", 0.5, -6.0)


func _climb_process(delta: float) -> void:
	_climb_time += delta
	velocity = Vector2(_dir * 60.0, -CLIMB_SPEED * _speed_mul)   # נדחף לקיר ועולה
	move_and_slide()
	_walk_phase += delta * 11.0
	var done := global_position.y <= _climb_y if _climb_y < INF else (not is_on_wall() and _climb_time > 0.08)
	if done:
		_climbing = false
		velocity = Vector2(_dir * 150.0, -170.0)   # מושך את עצמו מעל הקצה
	elif _climb_time > 3.0 or is_on_ceiling():   # קיר גבוה מדי: נופל
		_climbing = false
		velocity = Vector2(-_dir * 60.0, 0.0)
	_maybe_redraw()


# ---- נזרק מגג הרכבת (subway.gd): מתגלגל באוויר, נוחת בבום, קם ורודף ----
func throw_off(vel: Vector2) -> void:
	riding = false
	_crash_fly = true
	velocity = vel
	_dir = signf(vel.x) if vel.x != 0.0 else _dir
	_voice("zscream", 1.0, 3.0)


func _crash_fly_process(delta: float) -> void:
	velocity.y += gravity * delta
	_spin_a += delta * 10.0   # (סיבוב אחד בערך עד הנחיתה)
	move_and_slide()
	if is_on_floor():
		_crash_fly = false
		_spin_a = 0.0
		velocity = Vector2.ZERO
		Sfx.play("land", global_position, 6.0, 0.05, 2, 0.6)
		Sfx.play("corpse_splat", global_position, 0.0, 0.1, 2)
		Particles.burst(get_parent(), global_position + Vector2(0, -4), "smoke", Vector2.UP, 14)
		Particles.burst(get_parent(), global_position + Vector2(0, -6), "drop", Vector2.UP, 12)
		var cam := get_viewport().get_camera_2d()
		if cam != null and cam.has_method("shake"):
			cam.shake(7.0, 0.3)
		_stagger_t = 0.45   # רגע של בלבול, ואז הסתערות
		_alert_t = 30.0
		_rush_t = 3.0
		var pl := get_tree().get_first_node_in_group("player")
		if pl != null:
			_dir = signf(pl.global_position.x - global_position.x)
	_maybe_redraw()


func drop_through() -> void:
	if not is_on_floor() or dead:
		return
	collision_mask &= ~16
	_drop_t = 0.3
	velocity.y = 60.0


# ============================================================
#  רגליים שנפלו: להרים ולזרוק על השחקן
# ============================================================
func _legs_process(player: Node) -> void:
	if kind >= CONDUCTOR:
		return
	if _carry != null and not is_instance_valid(_carry):
		_carry = null
	if _carry == null and _pick_cd <= 0.0 and _throw_anim <= 0.0:
		for l in get_tree().get_nodes_in_group("severed_legs"):
			if l.can_pickup() and absf(l.global_position.x - global_position.x) < 14.0 + 10.0 * wf \
					and absf(l.global_position.y - global_position.y) < 40.0 * sc:
				l.pick(self)
				_carry = l
				_throw_cd = randf_range(0.5, 1.1)
				break
	if _carry == null:
		return
	_carry.global_position = _hand_world()
	_carry.rotation = -PI / 2.0 + sin(_time * 6.0) * 0.3
	if player == null or player.dead or _throw_cd > 0.0:
		return
	var target: Vector2 = player.global_position + Vector2(0.0, -26.0)
	var dx := target.x - global_position.x
	if absf(dx) < throw_range and absf(dx) > 50.0 and absf(target.y - global_position.y) < 220.0:
		_dir = signf(dx)
		var from := _hand_world()
		var t := clampf(absf(target.x - from.x) / 430.0, 0.4, 1.0)
		var g: float = _carry.gravity
		var v := Vector2((target.x - from.x) / t, (target.y - from.y - 0.5 * g * t * t) / t)
		_carry.throw_at(from, v)
		_carry = null
		_throw_anim = 0.35
		_pick_cd = 1.2


func _hand_world() -> Vector2:
	return global_position + Vector2(_dir * 9.0 * wf * sc, -55.0 * sc)


# ============================================================
#  פגיעות
# ============================================================
# נקרא מ-bullet.gd ומ-grenade.gd. hit_pos קובע איפה הפגיעה: ראש / גוף / רגליים.
# explosive = true (רימון): amount הוא הנזק, בלי קשר למקום הפגיעה
func take_damage(amount: int, hit_pos: Vector2, dir: Vector2, explosive := false, src := {}) -> void:
	if dead:
		return
	if type_mod != null and not type_mod.on_damage(amount, hit_pos, dir, src):   # מגן / חסימה של סוג חדש
		return
	var source: String = src.get("source", "grenade" if explosive else "bullet")
	# מוליך: מלפנים אי אפשר לפגוע בו. השנאי בגב = נקודת התורפה
	if kind == CONDUCTOR and _transformer > 0:
		if source == "taser":
			_popup("ABSORBED", Color("a0c8ff"), 15, -120.0)
			return
		if dir.x * _dir > 0.0 and (source == "bullet" or source == "melee"):   # פגיעה בגב
			_transformer -= 1
			_flash = 0.1
			Particles.burst(get_parent(), global_position + Vector2(-_dir * 14.0 * wf, -45.0 * sc), "fire", -dir, 12)
			Game.on_zombie_hit({"source": source, "zone": "transformer"})
			if _transformer == 0:   # השנאי מתפוצץ: נשאר עם חצי כוח
				hp = int(hp * 0.5)
				_stun_t = 1.5
				_popup("OVERLOAD!", Color("80c0ff"), 26, -130.0)
				Particles.burst(get_parent(), global_position + Vector2(0.0, -45.0 * sc), "smoke", Vector2.UP, 16)
				var cam := get_viewport().get_camera_2d()
				if cam != null and cam.has_method("shake"):
					cam.shake(12.0, 0.4)
			else:
				_popup("TRANSFORMER %d/3" % (3 - _transformer), Color("80c0ff"), 17, -125.0)
			return
		if _time - float(get_meta("ne_t", -9.0)) > 0.3:   # לא ערימה של NO EFFECT אחד על השני (נשק אוטומטי)
			set_meta("ne_t", _time)
			_popup("NO EFFECT", Color("c0c0c8"), 14, -120.0)
		Sfx.play("shield", hit_pos)
		var ne: int = int(get_meta("no_eff", 0)) + 1   # רמז: שחקן שיורה מלפנים לא מבין למה זה לא עובד
		set_meta("no_eff", ne)
		if ne % 5 == 1 and ne <= 21:
			_popup("SHOOT HIS BACK!", Color("ffd34a"), 20, -150.0)
			var pl := get_tree().get_first_node_in_group("player")
			if ne == 1 and pl != null and pl.has_method("_say"):
				pl._say("His front is armored... get behind him!", Color("ffd34a"))
		return
	# שוטר: המגן חוסם מלפנים (חוץ מהרגליים)
	if kind == COP and (source == "bullet" or source == "melee") and dir.x * _dir < 0.0 and not _lying():
		var cly := (hit_pos.y - global_position.y) / sc
		if cly < (-12.0 if _crouched_shape else -20.0) or source == "melee":
			_popup("BLOCKED", Color("8ab0e0"), 14, -95.0)
			Sfx.play("shield", hit_pos, -3.0)
			for i in 3:
				var c = DebrisScript.new()
				get_parent().add_child(c)
				c.setup(hit_pos, Vector2(2, 2), Color("d0e0ff"), Vector2(-dir.x * randf_range(80, 200), -randf_range(40, 180)))
			Game.on_zombie_hit({"source": "bullet", "zone": "shield"})
			return
	if kind == BOSS and source == "boss_grenade":
		return
	# בוס: הדלת חוסמת קליעים מלפנים (חוץ מכשהוא מרים אותה למכה)
	if kind == BOSS and source == "melee":   # מכות לא עוזרות נגד הבוס
		_popup("BLOCKED", Color("c0c0c8"), 15, -120.0)
		return
	if kind == BOSS and source == "bullet" and _slam_t <= 0.0 and dir.x * _dir < 0.0:
		_popup("BLOCKED", Color("c0c0c8"), 15, -120.0)
		Sfx.play("shield", hit_pos)
		for i in 4:
			var c = DebrisScript.new()
			get_parent().add_child(c)
			c.setup(hit_pos, Vector2(2, 2), Color("ffd060"), Vector2(-dir.x * randf_range(80, 200), -randf_range(40, 200)))
		Game.on_zombie_hit({"source": "bullet", "zone": "shield"})
		return
	_flash = 0.1
	if src.get("incendiary", false):
		ignite(3.0)
	var ly := (hit_pos.y - global_position.y) / sc
	if on_ceiling:   # זוחל הפוך: הראש למטה
		ly = -ly
	var dmg := amount
	var zone := "body"
	var was_lying := _lying()
	if was_lying:
		_wake()
		_rise_t = minf(_rise_t, 0.4)
	var head_y := -30.0 if _crouched_shape else -42.0   # מתכופף = הראש נמוך יותר
	var leg_y := -12.0 if _crouched_shape else -20.0
	if not explosive and not was_lying:
		if ly < head_y:
			zone = "head"
			dmg = head_damage
		elif ly > leg_y:
			zone = "leg"
			dmg = randi_range(leg_damage.x, leg_damage.y)
		else:
			dmg = randi_range(body_damage.x, body_damage.y)
	elif not explosive:
		dmg = randi_range(body_damage.x, body_damage.y)
	if is_boss() and zone == "head":
		dmg = head_damage * 2
	if src.get("sniper", false):   # צלף
		dmg = dmg * 2 if zone == "head" else int(dmg * 1.5)
	if src.has("fixed"):   # שוטגאן (לפי מרחק) / חץ (13-19)
		dmg = int(src.fixed)
	elif src.has("dmg_mult") and zone != "head":   # נשק חלש/חזק יותר (weapons/weapon_db.gd). ירייה בראש נשארת קטלנית
		dmg = maxi(1, int(round(float(dmg) * float(src.dmg_mult))))
	elif zone == "head" and float(src.get("dmg_mult", 1.0)) > HEAD_HEAVY and not is_boss():   # נשק כבד (מגנום, אנטי-חומרי, רייל): ראש אף פעם לא חלש מגוף
		dmg = int(round(float(dmg) * float(src.dmg_mult) * HEAD_HEAVY_K))
	elif zone == "head" and float(src.get("head_mult", 1.0)) < 1.0:   # נשק אוטומטי: ירייה בראש לא הורגת מיד
		dmg = maxi(1, int(round(float(dmg) * float(src.head_mult))))
	if src.get("god", false):   # GOD MODE: נזק פי 4 (+300%)
		dmg *= 4
	if kind == GUNNER and dir.x * _dir < 0.0 and zone != "head" and not explosive and source != "taser":   # מגן הפלדה
		_popup("BLOCKED", Color("c0c8d0"), 14, -80.0)
		Sfx.play("shield", hit_pos, -2.0, 0.15, 3)
		Game.on_zombie_hit({"source": "bullet", "zone": "shield"})
		return
	if kind == MECH and zone != "head" and not explosive:   # שריון: רק הנהג פגיע באמת
		dmg = maxi(1, int(dmg * 0.3))
		Sfx.play("shield", hit_pos, -6.0, 0.15, 2)
	if type_mod != null:
		dmg = maxi(0, int(round(float(dmg) * type_mod.damage_mult(zone, src))))
	if has_meta("morale_t") and float(get_meta("morale_t")) > _time:   # FLAGBEARER (שלב 40): ליד הדגל הם לא נשברים
		dmg = maxi(1, int(round(float(dmg) * 0.6)))
	if src.has("weapon") and source == "bullet":
		if has_meta("resist_weapon") and int(src.weapon) == int(get_meta("resist_weapon")):   # QUIPU (שלב 36) "רשם" את הנשק הזה
			dmg = maxi(1, int(round(float(dmg) * 0.4)))
			if randf() < 0.25:
				_popup("RECORDED", Color("e0c060"), 11, -70.0)
		for q in get_tree().get_nodes_in_group("quipus"):   # QUIPU רושם באיזה נשק אתה משתמש
			if q.type_mod != null and q.type_mod.has_method("observe"):
				q.type_mod.observe(int(src.weapon), global_position)
	Particles.burst(get_parent(), hit_pos, "hit", dir if dir != Vector2.ZERO else Vector2.UP, int(10.0 * BLOOD_AMOUNT))
	# PERFECT: פגיעה בדיוק במרכז הראש
	var perfect := false
	if zone == "head":
		var hc := global_position + Vector2(_dir * 4.0 * wf * sc, -50.0 * sc)
		perfect = hit_pos.distance_to(hc) < 6.0 * sc
		if perfect:
			dmg *= 2
	_last_info = {"zone": zone, "source": source, "perfect": perfect, "bullet": src.get("bullet", 0), "blast": src.get("blast", 0), "shot": src.get("shot", 0),
		"hidden": _cover_state == 2}
	Game.on_zombie_hit(_last_info)
	# זומבי בתוך מכונה (DRILLER): פגיעה בפח = ניצוצות וצליל מתכת, בלי דם. רק חלון התא (ראש) פוגע בנהג
	var metal: bool = type_mod != null and bool(type_mod.stats().get("metal", false)) and zone != "head" and not explosive
	if metal:
		Sfx.play("metal_ping", hit_pos, -2.0, 0.18, 4)
		Particles.burst(get_parent(), hit_pos, "fire", Vector2(-dir.x, -0.6), 5)
	else:
		Sfx.play("headshot" if zone == "head" else "hit", hit_pos, -4.0, 0.15, 4)
	_last_hit = hit_pos
	_last_boom = explosive
	_last_kb = float(src.get("knockback", -1.0)) if source == "bullet" or source == "melee" else -1.0
	_last_god = bool(src.get("god", false))
	hp -= dmg
	Game.story.emit("zhit", {"z": self, "zone": zone, "source": source, "was_lying": was_lying})
	if hp > 0 and not metal and (source == "bullet" or source == "melee" or source == "taser"):
		_voice("zhit", 0.85, 3.0)
	_damage_number(dmg, zone)

	if metal or source == "fire":   # (בעירה: בלי ריסוס דם וחתיכות בכל נזק אש - חוסך המון חלקיקים)
		pass
	elif zone == "head":
		_spray_blood(global_position + Vector2(0.0, -50.0 * sc), Vector2(dir.x, -0.6), 12, 320.0)
		if hp <= 0:   # HEADSHOT: הראש מתפוצץ
			_headless = true
			_spray_blood(global_position + Vector2(0.0, -50.0 * sc), Vector2(dir.x, -0.6), 16, 420.0)
	elif zone == "leg":
		_spray_blood(hit_pos, dir, 5, 220.0)
		if not _one_leg and kind in [WALKER, RUNNER, BRUTE, SPITTER, SCREAMER, BLOATER, COP, IMP, DRUNK, HURLER, CRAWLER]:
			_leg_hits += 1
			if _leg_hits >= 2 and hp > 0:   # 2 פגיעות ברגליים = הרגל נתלשת
				_lose_leg(dir)
	else:
		_spray_blood(hit_pos, dir, 6, 260.0)
		if _wounds.size() < 6:
			var lx := (hit_pos.x - global_position.x) * _dir / (sc * wf)
			_wounds.append(Vector2(clampf(lx, -6.0, 6.0), clampf(ly, -40.0, -22.0)))
	# חתיכות בשר נתלשות (אפור + אדום) - effects/flesh_fx.gd
	if dmg > 0 and kind != MECH and not metal and source != "fire" and (type_mod == null or bool(type_mod.stats().get("flesh", true))):
		FleshFx.burst(get_parent(), hit_pos, dir, skin, zone, hp <= 0, explosive, hp <= 0 and death_load() >= DEATH_HEAVY - 1)
	if hp <= 0 and zone == "leg" and not explosive and _can_crawl() and (randf() < CRAWL_CHANCE or has_meta("force_crawl")):   # (force_crawl: devtools/t_tear.gd)
		_become_crawler(dir)   # לא מת: הרגליים נתלשו והוא ממשיך לזחול
		return
	if hp <= 0:
		_die(dir)
	else:
		if not explosive and not metal and source in ["bullet", "melee", "taser", "laser"]:
			_start_react(zone, dir, src)
		if on_ceiling:   # נפגע על התקרה: נופל
			_drop_down()
		var ksid: int = int(src.get("shot", 0))
		if ksid == 0 or ksid != _kb_shot:   # שוטגאן: רק הכדור הראשון של הירייה הודף (6 כדורים היו זורקים אותו מחוץ לטווח)
			_kb_shot = ksid
			velocity.x += dir.x * (110.0 + (float(src.get("knockback", 0.0)) if not is_boss() else 0.0)) * (GOD_PUSH if src.get("god", false) else 1.0)   # הדיפה לפי הנשק
		# לפעמים הוא בורח ומתחבא מאחורי מכונית / מחסום (אם יש אחד קרוב)
		if _cover_state == 0 and not was_lying and not is_boss() and randf() < cover_chance:
			_try_cover(get_tree().get_first_node_in_group("player"))


# תגובת פגיעה: מתחיל אנימציה קצרה לפי איפה הכדור פגע (ראש / בטן / רגל)
func _start_react(zone: String, dir: Vector2, src: Dictionary) -> void:
	if not REACT_TIME.has(zone):
		return
	if _react_t > 0.0 and _react_zone == "head" and zone != "head":   # ראש חזק יותר - לא נדרס ע"י כדור קטן אחריו
		return
	_react_zone = zone
	_react_t = REACT_TIME[zone]
	_react_dx = signf(dir.x * _dir) if dir.x != 0.0 else -1.0
	_react_push = clampf(0.8 + float(src.get("knockback", 60.0)) / 200.0, 0.8, 1.6) * (GOD_PUSH if src.get("god", false) else 1.0)
	if is_boss() or _big():   # בוס / ענק: בקושי זז
		_react_push *= 0.35 if is_boss() else 0.6


# 0..1: עולה מהר, נרגע לאט
func _react_k() -> float:
	if _react_t <= 0.0 or dead or _lying():
		return 0.0
	var a := 1.0 - _react_t / float(REACT_TIME[_react_zone])
	return clampf(a / 0.12, 0.0, 1.0) * (1.0 - a) * (1.0 - a)


# לסוגים שמציירים את עצמם (enemies/zombie_type.gd begin_draw): כל הגוף נוטה / קופץ
func react_tilt() -> float:
	var k := _react_k() * _react_push
	match _react_zone:
		"head":
			return _react_dx * 0.16 * k * _dir   # נזרק אחורה
		"body":
			return 0.22 * k * _dir   # מתקפל קדימה
	return 0.0


func react_hop() -> float:
	if _react_zone != "leg" or _react_k() <= 0.0:
		return 0.0
	var a := 1.0 - _react_t / float(REACT_TIME["leg"])
	return -absf(sin(a * PI * 3.0)) * 5.0 * (1.0 - a) * _react_push


# מספר הנזק שקופץ מעל הזומבי וצף למעלה
var _dmg_txt: Node2D = null       # מספר הנזק האחרון: כדורי שוטגאן מאותה ירייה מתחברים למספר אחד שגדל
var _dmg_shot := 0
var _dmg_val := 0

func _damage_number(dmg: int, zone: String) -> void:
	if not Quality.damage_numbers(zone):   # המשחק איטי: בלי מספרי נזק (quality.gd)
		return
	var sid: int = int(_last_info.get("shot", 0))
	if sid != 0 and sid == _dmg_shot and _dmg_txt != null and is_instance_valid(_dmg_txt) and _dmg_txt.t < 0.2:
		_dmg_val += dmg
		_dmg_txt.text = str(_dmg_val)
		_dmg_txt.size = mini(_dmg_txt.size + 2, 34)
		if zone == "head":
			_dmg_txt.color = Color("ff4a3a")
		_dmg_txt.t = 0.0
		return
	var col := Color.WHITE
	var size := 18
	match zone:
		"head":
			col = Color("ff4a3a")
			size = 26
		"leg":
			col = Color("ffb04a")
	var p := HitText.new()
	p.text = str(dmg)
	p.color = col
	p.size = size
	p.pop = true
	get_parent().add_child(p)
	p.global_position = global_position + Vector2(randf_range(-10.0, 10.0), -66.0 * sc)
	_dmg_txt = p
	_dmg_shot = sid
	_dmg_val = dmg


# שוכב על הריצפה כמו גופה עד שמתקרבים (לשלבים: אחרי spawn)
func lie_down() -> void:
	dormant = true
	var r := _shape.shape as RectangleShape2D
	r.size = Vector2(52, 18) * sc
	_shape.position = Vector2(0.0, -9.0 * sc)
	_lie_side = -1.0 if randf() < 0.5 else 1.0


func _wake() -> void:
	if not dormant:
		return
	_voice("zscream", 0.95, 3.0)   # קם מהריצפה: זעקה
	dormant = false
	Game.story.emit("wake", {"z": self})
	_rise_t = RISE_TIME
	var r := _shape.shape as RectangleShape2D
	r.size = Vector2(38.0 * wf, 66.0 * sc)   # אזור פגיעה גדול מהציור - כדי שכל ירייה על הזומבי תיתפס
	_shape.position = Vector2(0.0, -33.0 * sc)
	if Art.on_screen(self, global_position):
		_popup("!", Color("ff5040"), 22, -80.0)


func _lying() -> bool:
	return dormant or _rise_t > 0.0


func _lose_leg(dir: Vector2) -> void:
	_one_leg = true
	Game.story.emit("leg", {"z": self})
	Game.on_leg_severed()
	_hop_t = 0.4
	var hip := global_position + Vector2(-_dir * 2.0 * wf, -22.0 * sc)
	_spray_blood(hip, dir, 14, 300.0)
	var leg = LegScript.new()
	get_parent().add_child(leg)
	leg.setup(hip + Vector2(0.0, 8.0 * sc), Vector2(dir.x * 160.0 + randf_range(-40.0, 40.0), -200.0), pants, skin, shoe, sc)
	_popup("LEG!", Color("ff8a5a"), 16, -40.0)


# ---- תקציב מוות: הרבה הריגות ביחד (MULTI KILL) = אפקטים זולים יותר, כדי שהמשחק לא יאט ----
const DEATH_WINDOW := 1000          # ms
const DEATH_HEAVY := 3              # מההריגה ה-3 בתוך שנייה: בלי רגדול, פחות דם וחתיכות
const MAX_BLOOD := 90               # כמה טיפות דם (צמתים) יכולות להתקיים בבת אחת
static var _deaths: Array = []
var _lite := false                  # המוות הזה במצב "חסכוני"


static func death_load() -> int:   # כמה זומבים מתו בשנייה האחרונה
	var now := Time.get_ticks_msec()
	while not _deaths.is_empty() and now - int(_deaths[0]) > DEATH_WINDOW:
		_deaths.pop_front()
	return _deaths.size()


func _die(dir: Vector2) -> void:
	dead = true
	_c_same = 0
	_c_hash = -1
	_lod_dead = crowded()
	_lite = death_load() >= DEATH_HEAVY - 1
	_deaths.append(Time.get_ticks_msec())
	Game.story.emit("zkill", {"z": self, "zone": _last_info.get("zone", ""), "source": _last_info.get("source", "")})
	collision_mask |= 16
	var sd := get_tree().get_first_node_in_group("squad_director")
	if sd != null:
		sd.on_death(self)   # משחרר תור התקפה. מנהיג מת = בלבול
	if type_mod != null:
		type_mod.on_death()
	_carrier = null
	_thrown = false
	if _imp != null and is_instance_valid(_imp):   # זורק מת: הקטן נופל
		_imp._carrier = null
	_imp = null
	if kind == JETPACK:   # מאבד שליטה: גלגלונים באוויר ואז התרסקות
		_crashing = true
		Sfx.play("jet", global_position, 4.0)
	if kind == MECH:   # הרובוט מתפוצץ
		Boom.blast.call_deferred(get_parent(), global_position + Vector2(0.0, -30.0 * sc), 90.0, 50.0, 30, 1, "mech")
	Sfx.play(type_mod.death_sound() if type_mod != null else "zdeath", global_position, -6.0 if kind != RAT else -14.0, 0.06, 3, _vp)
	on_ceiling = false
	if kind == HAND:   # היד נעלמת בחזרה למים
		remove_from_group("zombies")
		var pl := get_tree().get_first_node_in_group("player")
		if pl != null and pl.grabbed_by == self:
			pl.grabbed_by = null
		_spray_blood(global_position + Vector2(0, -20), Vector2.UP, 10, 260.0)
		_last_info["pos"] = global_position + Vector2(0.0, -52.0 * sc)
		Game.on_zombie_killed(kind, _last_info)
		queue_free()
		return
	remove_from_group("zombies")
	if not is_boss() and not has_meta("revived"):
		add_to_group("corpses")   # REVIVER (enemies/types/reviver.gd) יכול להחזיר אותו לחיים
	if _carry != null and is_instance_valid(_carry):
		_carry.drop(Vector2(randf_range(-80.0, 80.0), -150.0))
	_carry = null
	collision_layer = 0   # קליעים כבר לא פוגעים בגופה
	var r := _shape.shape as RectangleShape2D
	r.size = Vector2(18, 18) * sc   # גופה = ריבוע קטן שמתגלגל
	_shape.position = Vector2(0.0, -9.0 * sc)
	var fl := 1.0   # נשק חזק = הגופה עפה רחוק יותר (KILL_FLING לפי knockback)
	if _last_kb >= 0.0 and not _last_boom:
		fl = lerpf(KILL_FLING.x, KILL_FLING.y, clampf(_last_kb / 220.0, 0.0, 1.0))
		heavy_kill = _last_kb >= HEAVY_KB
	if _last_god and not _last_boom:
		fl *= GOD_PUSH
	velocity = (Vector2(dir.x, minf(dir.y, 0.0)).normalized() * randf_range(420.0, 620.0) * fl / sqrt(sc * wf) + Vector2(0.0, -260.0 * minf(fl, 1.3))) * DEATH_FLING
	_kill_feel()
	if Game.level >= SPORE_FROM and not _lite and not is_boss() and Quality.level < 2:   # "THEY LEARN": השיעור עובר הלאה
		SporeScript.send(get_parent(), global_position + Vector2(0.0, -40.0 * sc), self)
	if kind == JETPACK:   # מתרסק בנקודה אקראית בתוך המסך שרואים
		var vp := get_viewport()
		var view := vp.get_canvas_transform().affine_inverse() * vp.get_visible_rect()
		var tx := randf_range(view.position.x + 120.0, view.end.x - 120.0)
		var vy0 := -randf_range(120.0, 260.0)
		var h := maxf(_ground_y - global_position.y, 10.0)
		var t_fall := (-vy0 + sqrt(vy0 * vy0 + 2.0 * 650.0 * h)) / 650.0
		velocity = Vector2(clampf((tx - global_position.x) / t_fall, -900.0, 900.0), vy0)
	_spin = randf_range(8.0, 14.0) * signf(velocity.x if velocity.x != 0.0 else 1.0)
	if kind == DOG or kind == HOUND:   # כלב: חצי סיבוב באוויר (לא גלגל), נוחת על הצד ובועט ברגליים
		_spin = randf_range(3.0, 5.0) * signf(velocity.x if velocity.x != 0.0 else 1.0)
	elif kind == GUNNER:   # מקלען: לא עף - נופל אחורה מאחורי השקים, המקלע נופל קדימה ויורה צרור אחרון
		velocity = Vector2.ZERO
		_spin = 0.0
		_angle = 0.0
	_splat_pending = kind != RAT and kind != JETPACK and kind != MECH and randf() < SPLAT_CHANCE
	if _legless:   # פלג גוף זוחל: נשאר שוכב על הבטן (בלי לקפוץ לעמידה)
		_angle = PI / 2.0 * _dir
		_spin = 0.0
		velocity = Vector2(velocity.x * 0.3, -60.0)
	# מוות מיוחד, כל אחד 20% כשהתנאי שלו מתקיים (אחד לכל היותר): פיצוץ / שוטגאן מקרוב -> חתיכות, אש -> עצמות,
	# כל הריגה -> נקרע לשניים, ירייה בראש -> הולך בלי ראש.
	# force_* (devtools/t_tear.gd, CHARACTER MAKER): בדיוק המוות הזה, בלי מוות מיוחד אקראי אחר במקומו
	var lucky := not (has_meta("force_burst") or has_meta("force_char") or has_meta("force_tear") or has_meta("force_hw"))
	var burst := _can_burst() and ((lucky and randf() < BURST_CHANCE) or has_meta("force_burst"))
	var burn := not burst and _can_char() and ((lucky and randf() < CHAR_CHANCE) or has_meta("force_char"))
	var tear := not burst and not burn and _can_tear() and ((lucky and randf() < TEAR_CHANCE) or has_meta("force_tear"))
	var hwalk := not burst and not burn and not tear and _can_headless_walk() and ((lucky and randf() < HEADLESS_WALK_CHANCE) or has_meta("force_hw"))
	if burst:
		_burst_into_chunks(dir)
	elif burn:
		_start_char()
	elif hwalk:
		_start_headless_walk(dir)
	elif _ragdoll_kind() and not _legless and (not _lite or tear):   # זומבי אנושי: גופה רכה שנופלת לפי המכה (במולטי-קיל: גופה פשוטה)
		_rag = RagdollScript.new()
		_rag.setup(self, velocity, dir, _last_hit if _last_hit != Vector2.ZERO else global_position + Vector2(0, -30) * sc, _last_boom, tear)
		if tear:
			_tear_fx(dir)
	_spray_blood(global_position + Vector2(0, -30) * sc, dir, 14, 380.0)
	if is_instance_valid(_fire):
		_fire.queue_free()
	# ניקוד + בונוסים
	_last_info["pos"] = global_position + Vector2(0.0, -52.0 * sc)   # לחותמת HEADSHOT של ui/kill_streak.gd
	var bonuses: Array = Game.on_zombie_killed(kind, _last_info)
	bonuses = bonuses.filter(func(b): return b[0] != "HEADSHOT")   # HEADSHOT מוצג בגדול ע"י ui/kill_streak.gd
	# שורה אחת בלבד (הבונוס הגדול + סך הכל), ורק כשהניקוד גדול (150+) או לפעמים (Game.show_pop)
	if not bonuses.is_empty():
		var top: Array = bonuses[0]
		var total := 0
		for b in bonuses:
			total += int(b[1])
			if int(b[1]) > int(top[1]):
				top = b
		var big := total >= 150 or (int(top[1]) == 0 and Game.combo >= 10)
		if Game.show_pop(big):
			var txt: String = str(top[0]) + (" +%d" % total if total > 0 else "")
			_popup(txt, Color("ffd34a"), 17 if big else 15, -96.0)
	# בוס מסוג חדש (enemies/types, למשל TANK בשלב 8): פותח את השער + שלל של בוס
	if _mod_boss:
		_drop(PickupScript.BOOST)
		_drop(PickupScript.SUPPLY)
		get_tree().call_group("level_exit", "on_boss_dead")
	# שלל: ענק = בוסט, בוס = הרבה, אחרים = לפעמים תחמושת
	match kind:
		BRUTE:
			_drop(PickupScript.BOOST)
		BOSS, CONDUCTOR, HOUND:
			_drop(PickupScript.BOOST)
			_drop(PickupScript.BOOST)
			_drop(PickupScript.SUPPLY)
			get_tree().call_group("level_exit", "on_boss_dead")
		BLOATER:   # נפוח שנהרג - מתפוצץ ופוגע בזומבים מסביב
			Boom.blast.call_deferred(get_parent(), global_position + Vector2(0.0, -30.0 * sc), 100.0 + 30.0 * _swell, 50.0, 40, 2, "bloater")
			hide()
		_:   # תחמושת דינמית: יותר כשנגמר לשחקן (progression/arsenal.gd)
			if randf() < Arsenal.ammo_drop_chance(get_tree().get_first_node_in_group("player")):
				_drop(PickupScript.AMMO)


# ---- נקרע לשניים: 20% מההריגות, בכל נשק (effects/ragdoll.gd split) ----
# לשנות: TEAR_CHANCE, TEAR_MAX_SIM / TEAR_MAX_LITE (כמה גופות מדומות לכל היותר כדי שעוד יקרע - ביצועים)
const TEAR_CHANCE := 0.2
const TEAR_MAX_SIM := 14
const TEAR_MAX_LITE := 4            # מולטי-קיל (הרבה הריגות בשנייה): רק אם יש פחות מזה גופות מדומות


func _can_tear() -> bool:
	if not _ragdoll_kind() or _legless or RagdollScript.active >= (TEAR_MAX_LITE if _lite else TEAR_MAX_SIM):
		return false
	return type_mod == null or not (type_mod.has_method("ragdoll_pose") or type_mod.has_method("draw_ragdoll"))   # פרופורציות אחרות


func _tear_fx(dir: Vector2) -> void:
	remove_from_group("corpses")   # חצי זומבי לא קם לתחייה
	var waist := global_position + Vector2(0.0, -24.0 * sc)
	FleshFx.burst(get_parent(), waist, dir, skin, "body", true, true)
	_spray_blood(waist, Vector2(dir.x, -0.6), 10, 420.0)
	Sfx.play("splat", global_position, 2.0, 0.12, 3)
	Sfx.play("corpse_splat", global_position, 0.0, 0.1, 3, 0.85)
	if Game.show_pop(false):
		_popup("TORN IN HALF!", Color("ff4a3a"), 16, -110.0)


# ---- הולך בלי ראש: 20% מההריגות בירייה בראש (רק סוגים 0-19 - לסוגים החדשים ציור משלהם) ----
# הראש עף ומתגלגל (effects/flying_head.gd), הגוף נהדף, ואז מדדה קדימה עם ידיים שמחפשות את הראש
# ומזרקת דם מהצוואר, עד שהברכיים נשברות והוא נופל (גופה רכה).
# לשנות: HEADLESS_WALK_CHANCE, HW_TIME, HW_SPEED, HW_SPURT
const HEADLESS_WALK_CHANCE := 0.2
const HW_TIME := Vector2(1.1, 1.8)
const HW_SPEED := 70.0
const HW_SPURT := 0.05


func _can_headless_walk() -> bool:
	if not _headless or (type_mod != null and cust == null) or is_boss() or not _ragdoll_kind() or _one_leg or _legless or not is_on_floor():
		return false
	if kind in [CRAWLER, IMP]:
		return false
	return RagdollScript.active < (TEAR_MAX_LITE if _lite else TEAR_MAX_SIM)


func _start_headless_walk(dir: Vector2) -> void:
	remove_from_group("corpses")
	_hw_t = randf_range(HW_TIME.x, HW_TIME.y)
	_hw_age = 0.0
	_hw_spurt = 0.0
	velocity = Vector2(signf(dir.x) * 140.0, 0.0)   # נהדף אחורה מהירייה
	_spin = 0.0
	_angle = 0.0
	if HeadScript.alive < HeadScript.MAX_ALIVE:
		var h = HeadScript.new()
		get_parent().add_child(h)
		var hx := signf(dir.x) if dir.x != 0.0 else -_dir
		h.setup(global_position + Vector2(_dir * 3.0 * wf * sc, -50.0 * sc), Vector2(hx * randf_range(150.0, 300.0), -randf_range(320.0, 460.0)), self)
	_spray_blood(global_position + Vector2(0.0, -46.0 * sc), Vector2(0.0, -1.0), 10, 380.0)


func _headless_walk(delta: float) -> void:
	_hw_t -= delta
	_hw_age += delta
	if not is_on_floor():
		velocity.y += gravity * delta
	if _hw_age < 0.25:   # רגע ההדיפה
		velocity.x = move_toward(velocity.x, 0.0, 500.0 * delta)
	else:   # מדדה קדימה בזיגזג
		var want := _dir * HW_SPEED * (0.7 + 0.3 * sin(_hw_age * 6.0))
		velocity.x = move_toward(velocity.x, want, 400.0 * delta)
	move_and_slide()
	_walk_phase += delta * (absf(velocity.x) * 0.075 / sc + 2.0)
	# מזרקת דם מהצוואר, נחלשת עם הזמן
	_hw_spurt -= delta
	if _hw_spurt <= 0.0:
		_hw_spurt = HW_SPURT
		var k := clampf(_hw_t / HW_TIME.y, 0.3, 1.0)
		_spray_blood(global_position + Vector2(_dir * 2.0 * wf * sc, -46.0 * sc), Vector2(sin(_hw_age * 9.0) * 0.4, -1.0), 1, 380.0 * k)
	var fell: bool = not is_on_floor() and velocity.y > 250.0   # נפל לבור / מקצה
	if _hw_t <= 0.0 or is_on_wall() or fell:   # הברכיים נשברות: גופה רכה
		_hw_t = 0.0
		Sfx.play("corpse_splat", global_position, -6.0, 0.1, 3, 0.9)
		_rag = RagdollScript.new()
		_rag.setup(self, Vector2(_dir * 60.0, 0.0), Vector2(_dir, 0.3), global_position + Vector2(0.0, -12.0 * sc), false)
	if Art.on_screen(self, global_position, 60.0):
		queue_redraw()


# ---- מתפוצץ לחתיכות: 20% מההריגות בפיצוץ או בשוטגאן/צלף מקרוב (מכה חזקה, עד BURST_CLOSE מהשחקן) ----
# הגוף נעלם: ראש (effects/flying_head.gd), 2 ידיים, 2 רגליים, בית חזה וגושי בשר עפים (effects/gib.gd), דם בכל מקום.
# לשנות: BURST_CHANCE, BURST_CLOSE, BURST_SPEED, BURST_MAX_LITE
const BURST_CHANCE := 0.2
const BURST_CLOSE := 170.0
const BURST_SPEED := Vector2(240.0, 520.0)


const BURST_MAX_LITE := 18          # מולטי-קיל: מתפוצץ רק אם יש פחות מזה חלקים באוויר

func _can_burst() -> bool:
	if not _ragdoll_kind() or is_boss() or not GibScript.can_spawn():
		return false
	if _lite and GibScript.alive >= BURST_MAX_LITE:   # מולטי-קיל: לכל היותר 2-3 פיצוצים בבת אחת (ביצועים)
		return false
	if _last_boom:
		return true
	var pl := get_tree().get_first_node_in_group("player")
	return heavy_kill and pl != null and global_position.distance_to(pl.global_position) < BURST_CLOSE


func _burst_into_chunks(dir: Vector2) -> void:
	_gibbed = true
	remove_from_group("corpses")
	hide()
	corpse_time = 0.3
	var c := global_position + Vector2(0.0, -30.0 * sc)
	var d := dir.normalized() if dir != Vector2.ZERO else Vector2(-_dir, 0.0)
	var fling := func(up: float) -> Vector2:
		return Vector2.from_angle(d.angle() + randf_range(-0.9, 0.9)) * randf_range(BURST_SPEED.x, BURST_SPEED.y) + Vector2(0.0, -randf_range(150.0, 380.0) * up)
	if not _headless and HeadScript.alive < HeadScript.MAX_ALIVE:
		var h = HeadScript.new()
		get_parent().add_child(h)
		h.setup(global_position + Vector2(0.0, -50.0 * sc), fling.call(1.4), self)
	var parts := [[GibScript.TORSO, shirt, -32.0], [GibScript.ARM, shirt, -38.0], [GibScript.ARM, shirt, -38.0]]
	if not _legless:
		parts.append([GibScript.LEG, pants, -14.0])
		if not _one_leg:
			parts.append([GibScript.LEG, pants, -14.0])
	for i in (1 if _lite else randi_range(3, 5)):
		parts.append([GibScript.MEAT, skin, -30.0])
	for pt in parts:
		if not GibScript.can_spawn():
			break
		var g = GibScript.new()
		get_parent().add_child(g)
		g.setup(pt[0], global_position + Vector2(randf_range(-5.0, 5.0), float(pt[2]) * sc), fling.call(1.0), self, pt[1])
	FleshFx.burst(get_parent(), c, d, skin, "body", true, true, _lite)
	if not _lite:
		FleshFx.burst(get_parent(), c + Vector2(0.0, -10.0 * sc), Vector2(-d.x, -1.0), skin, "head", true, true)
	_spray_blood(c, Vector2(d.x, -0.8), 6 if _lite else 18, 520.0)
	Sfx.play("splat", global_position, 4.0, 0.12, 3)
	Sfx.play("corpse_splat", global_position, 2.0, 0.1, 3, 0.8)
	if Game.show_pop(false):
		_popup("CHUNKS!", Color("ff4a3a"), 16, -110.0)


# ---- פלג גוף זוחל: 20% מההריגות בירייה ברגליים (סוגים 0-19) ----
# לא מת: שתי הרגליים נתלשות (effects/gib.gd), והוא ממשיך לזחול אליך על הידיים עם CRAWL_HP חיים - צריך לגמור אותו.
# לשנות: CRAWL_CHANCE, CRAWL_HP, CRAWL_SPEED
const CRAWL_CHANCE := 0.2
const CRAWL_HP := 12
const CRAWL_SPEED := 55.0


func _can_crawl() -> bool:
	return (type_mod == null or cust != null) and not is_boss() and not _legless and not dead and is_on_floor() and _ragdoll_kind() \
		and not kind in [CRAWLER, IMP, COP] and not on_ceiling and not dormant and _carry == null


func _become_crawler(dir: Vector2) -> void:
	_legless = true
	_one_leg = false
	hp = CRAWL_HP
	max_hp = maxi(max_hp, CRAWL_HP)
	_stagger_t = 0.0
	_duck_t = 0.0
	_cover_state = 0
	velocity = Vector2(dir.x * 60.0, 0.0)
	var r := _shape.shape as RectangleShape2D   # שוכב: אזור פגיעה נמוך וארוך
	r.size = Vector2(44.0 * sc, 20.0 * sc)
	_shape.position = Vector2(0.0, -10.0 * sc)
	_crouched_shape = true
	var hip := global_position + Vector2(0.0, -22.0 * sc)
	for i in 2:
		if GibScript.can_spawn():
			var g = GibScript.new()
			get_parent().add_child(g)
			g.setup(GibScript.LEG, hip + Vector2(float(i) * 4.0 - 2.0, 6.0 * sc), Vector2(dir.x * randf_range(120.0, 260.0) + randf_range(-60.0, 60.0), -randf_range(200.0, 330.0)), self, pants)
	_spray_blood(hip, Vector2(dir.x, -0.5), 14, 340.0)
	FleshFx.burst(get_parent(), hip, dir, skin, "leg", true, false)
	Sfx.play("splat", global_position, 0.0, 0.12, 3)
	_voice("zscream", 1.0, 4.0)
	Game.on_leg_severed()
	if Game.show_pop(false):
		_popup("NO LEGS!", Color("ff8a5a"), 15, -50.0)


func _crawl_logic(player: Node, delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravity * delta
	var speed := 0.0
	if player != null and not player.dead:
		var d: Vector2 = player.global_position - global_position
		_dir = signf(d.x) if absf(d.x) > 4.0 else _dir
		speed = CRAWL_SPEED * _speed_mul * (0.35 + 0.65 * maxf(0.0, sin(_walk_phase)))   # משיכות: יד, עוד יד
		if absf(d.x) < 26.0 * sc and absf(d.y) < 40.0 and _attack_t <= 0.0:   # תופס את הקרסול ונושך
			_attack_t = bite_delay * 1.3
			_bite_anim = 0.3
			player.hurt(damage, Vector2(_dir, 0.0))
	velocity.x = move_toward(velocity.x, _dir * speed, 500.0 * delta)
	move_and_slide()
	_walk_phase += delta * 5.0
	if Engine.get_physics_frames() % 6 == 0 and randf() < 0.3:   # שובל דם מהמותן
		_spray_blood(global_position + Vector2(-_dir * 16.0 * sc, -6.0 * sc), Vector2(-_dir, -0.4), 1, 90.0)
	_maybe_redraw()


# ---- נשרף עד העצמות: 20% מההריגות באש (או זומבי בוער שנהרג) ----
# הגוף נשאר לעמוד ובוער ומשחיר, ואז נופל לערימת עצמות עם ענן אפר (effects/char_bones.gd).  לשנות: CHAR_CHANCE
const CHAR_CHANCE := 0.2


func _can_char() -> bool:
	if not _ragdoll_kind() or (type_mod != null and cust == null) or is_boss() or _legless or not is_on_floor():
		return false
	return str(_last_info.get("source", "")) == "fire" or _burn_t > 0.2


func _start_char() -> void:
	remove_from_group("corpses")
	_char = CharScript.new()
	_char.setup(self)
	_burn_t = 1.5   # להבות על הגוף בזמן שהוא משחיר (_draw_burning)
	velocity = Vector2.ZERO
	_spin = 0.0
	_angle = 0.0
	corpse_time = maxf(corpse_time, 5.0)
	_voice("zscream", 1.0, 4.0)


# תחושת הריגה: צליל "מכה" (ראש = פיצוח), ועצירת זמן קטנה בהריגה בראש / ממכה חזקה / בוס (shake_camera.gd -> hit_stop)
func _kill_feel() -> void:
	var boss := is_boss() or _mod_boss
	var src: String = _last_info.get("source", "")
	if not boss and src != "bullet" and src != "melee" and src != "stomp":
		return
	if not Art.on_screen(self, global_position, 60.0):
		return
	var head: bool = _last_info.get("zone", "") == "head"
	if head:
		Sfx.play("kill_crack", global_position, -2.0, 0.1, 3)
	else:
		Sfx.play("kill_punch", global_position, -4.0 + (3.0 if heavy_kill else 0.0), 0.12, 3)
	var t := HITSTOP_BOSS if boss else (HITSTOP_HEAVY if heavy_kill else (HITSTOP_HEAD if head else 0.0))
	if not boss and death_load() >= 2:   # הרבה הריגות ברצף (מיניגאן / רימון): בלי עצירות זמן - הרגיש כמו האטה של המשחק
		t = 0.0
	if t > 0.0:
		var cam := get_viewport().get_camera_2d()
		if cam != null and cam.has_method("hit_stop"):
			cam.hit_stop(t)


func _drop(pk: int) -> void:
	var p = PickupScript.new()
	p.kind = pk
	p.boost = randi() % 5
	get_parent().add_child.call_deferred(p)
	p.setup.call_deferred(global_position + Vector2(0, -40), Vector2(randf_range(-120, 120), -280))


func _dead_process(delta: float) -> void:
	_dead_t += delta
	if _hw_t > 0.0:
		_headless_walk(delta)
		return
	if _char != null and _dead_t <= corpse_time:   # נשרף: עומד במקום, משחיר, מתפרק לעצמות
		modulate.a = clampf(corpse_time - _dead_t, 0.0, 1.0)
		if (_char.step(delta) or _dead_t > corpse_time - 1.0) and Art.on_screen(self, global_position, 60.0):
			queue_redraw()
		return
	if _dead_t > corpse_time:
		if _rag != null:
			_rag.release()
		queue_free()
		return
	modulate.a = clampf(corpse_time - _dead_t, 0.0, 1.0)
	if kind == GUNNER and _gburst < GUNNER_BURST.size() and _dead_t >= GUNNER_BURST[_gburst]:   # האצבע נלחצת על ההדק בנפילה
		_gburst += 1
		Sfx.play("rifle", global_position + Vector2(_dir * 30.0, -40.0 * sc), -7.0, 0.15, 3)
	if _rag != null:   # גופה רכה: מדמה עד שהיא נרגעת, ואז רק מצוירת
		if _rag.step(delta) and Art.on_screen(self, global_position, 400.0) and _rag.moved():   # (זזה פחות מחצי פיקסל = לא מציירים)
			queue_redraw()
		if _splat_pending:
			_try_splat(_rag.on_ground())
		return
	velocity.y += gravity * delta
	var impact_speed := velocity.length()
	move_and_slide()
	for i in get_slide_collision_count():
		var c := get_slide_collision(i)
		var col := c.get_collider()
		# התרסקות: כתם דם גדול על הלבנה
		if impact_speed > 200.0 and col != null and col.has_method("add_blood"):
			var key := col.get_instance_id()
			if _bled_on.get(key, 0.0) < _dead_t:
				_bled_on[key] = _dead_t + 0.15
				col.add_blood(c.get_position(), c.get_normal(), clampf(impact_speed / 200.0, 1.0, 3.0))
				_spray_blood(c.get_position(), c.get_normal(), 5, 160.0)
	if _splat_pending:
		_try_splat(is_on_floor())
	if is_on_floor():
		velocity.x = move_toward(velocity.x, 0.0, 900.0 * delta)
		_spin = move_toward(_spin, 0.0, 30.0 * delta)
		var rest := PI / 2.0 if fposmod(_angle, TAU) < PI else PI * 1.5
		if kind == DOG or kind == HOUND or kind == GUNNER:
			rest = 0.0   # כלב: נוחת על הבטן ומתמוטט (לא על הגב). מקלען: נשאר במקום (הנפילה מצוירת)
		elif _belly_up:
			rest = PI   # חולדה שהוטחה: על הגב
		_angle = lerp_angle(_angle, rest, 8.0 * delta)
		if absf(angle_difference(_angle, rest)) < 0.002:   # כמעט שם: נעצרת בדיוק (בלי שינויים זעירים שמכריחים ציור מחדש)
			_angle = rest
		if _land_t < 0.0:
			_land_t = _dead_t
	if is_on_wall():
		velocity.x *= -0.3
	_angle += _spin * delta
	_corpse_redraw()


# גופה רגילה (לא רכה): מציירים מחדש רק כשמשהו בה משתנה. אחרי ששלושה ציורים ברצף יצאו זהים לגמרי
# (אותן נקודות ואותם צבעים - גם אנימציה של סוג מסוים נבדקת כך) והגופה לא הסתובבה מאז - הציור הקודם נשאר.
# ההזזה על הריצפה וההיעלמות (modulate) לא צריכות ציור מחדש
func _corpse_redraw() -> void:
	if _c_same >= 2 and _flash <= 0.0 and _react_t <= 0.0 and absf(angle_difference(_angle, _c_angle)) < 0.003:
		_count_visible()   # (עדיין נספרת כזומבי על המסך, כמו קודם: הקצב והפרטים של כל השאר לא משתנים)
		return
	_maybe_redraw()


# הגופה נחתה על הריצפה אחרי שהירייה העיפה אותה: אחד מ-3 צלילי "שפריץ" (אקראי)
func _try_splat(landed: bool) -> void:
	if _dead_t > 1.5:   # לא נחתה (נתקעה / נפלה לבור) - מוותרים
		_splat_pending = false
		return
	if not landed or _dead_t < 0.12:
		return
	_splat_pending = false
	var now := Time.get_ticks_msec()
	if now - _splat_last < 250 or not Art.on_screen(self, global_position, 200.0):
		return
	_splat_last = now
	Sfx.play("corpse_splat", global_position, -2.0, 0.1, 2)

func _spray_blood(pos: Vector2, dir: Vector2, n: int, power: float) -> void:
	var lite := _lite or death_load() >= DEATH_HEAVY - 1   # מולטי-קיל: שליש מהטיפות
	var cnt := maxi(1, int(round(float(n) * BLOOD_AMOUNT * (0.33 if lite else 1.0) * Quality.gore())))   # המשחק איטי: 35% פחות
	cnt = mini(cnt, int(MAX_BLOOD * Quality.gore()) - BloodScript.alive)
	for i in cnt:
		var b = BloodScript.new()
		get_parent().add_child(b)
		var v := Vector2.from_angle(dir.angle() + randf_range(-0.8, 0.8)) * randf_range(power * 0.4, power)
		b.setup(pos, v + Vector2(0.0, -randf_range(40.0, 160.0)))


func _popup(text: String, col: Color, size := 18, y := -80.0) -> void:
	var p := HitText.new()
	p.text = text
	p.color = col
	p.size = size
	get_parent().add_child(p)
	p.global_position = global_position + Vector2(0.0, y * sc)


# ============================================================
#  ציור. מציירים זומבי בגובה "רגיל" (56) שפונה ימינה,
#  ואז מגדילים / מרחיבים / משקפים לפי הסוג והכיוון.
# ============================================================
# מראה שונה לכל זומבי (סוגים 0-19, פעם אחת ב-_ready): גוון עור, חולצה / מכנס, שיער - שההמון לא ייראה משוכפל
const SKIN_MIX := [Color("8a9ea4"), Color("b8b47a"), Color("b0a492"), Color("74945a"), Color("a08a8a")]
const SHIRTS := [Color("4f6688"), Color("7a4a3a"), Color("6e3036"), Color("5a6448"), Color("8a7646"), Color("3e6a6a"), Color("6a6a74"), Color("9a8c74"), Color("4a3a5a")]
const PANTS_MIX := [Color("3d3a4c"), Color("34466a"), Color("4e4638"), Color("2e3a2e"), Color("4a4a50"), Color("5a5040")]
const HAIRS := [Color("5a4630"), Color("3a3026"), Color("6e5638"), Color("8a8880"), Color("94582c"), Color("a8986a")]
const VARY_SHIRT := [WALKER, BRUTE, BLOATER, HURLER, IMP, CRAWLER, SPITTER, RUNNER]   # (שוטר / מוליך / חליפה - צבע קבוע)


func _vary(r: RandomNumberGenerator) -> void:
	if kind == RAT or kind == DOG or kind == HOUND:   # חיות: רק גוון פרווה
		skin = Art.shade(skin, r.randf_range(-0.12, 0.1))
		return
	skin = skin.lerp(SKIN_MIX[r.randi() % SKIN_MIX.size()], r.randf_range(0.0, 0.4))
	if kind == WALKER or kind == HURLER:   # חולצה + מכנס מתוך פלטה
		shirt = Art.shade(SHIRTS[r.randi() % SHIRTS.size()], r.randf_range(-0.08, 0.08))
		pants = Art.shade(PANTS_MIX[r.randi() % PANTS_MIX.size()], r.randf_range(-0.06, 0.08))
	elif kind in VARY_SHIRT:   # אותו צבע בערך, גוון קצת אחר
		shirt = Color.from_hsv(fposmod(shirt.h + r.randf_range(-0.06, 0.06), 1.0), clampf(shirt.s * r.randf_range(0.75, 1.2), 0.0, 1.0), shirt.v)
		pants = Art.shade(pants, r.randf_range(-0.05, 0.12))
	else:
		pants = Art.shade(pants, r.randf_range(-0.03, 0.08))
	hair = HAIRS[r.randi() % HAIRS.size()]
	_bald = r.randf() < 0.22
	_gore_arm = r.randf() < 0.35


# אילו זומבים נופלים כגופה רכה (לא: חיות, יד, רובוט, ג'טפאק שמתרסק, נפוח שמתפוצץ, תותחן)
func _ragdoll_kind() -> bool:
	if kind in [RAT, HAND, MECH, DOG, HOUND, JETPACK, BLOATER, GUNNER]:
		return false
	return type_mod == null or bool(type_mod.stats().get("ragdoll", true))


func _draw() -> void:
	DrawBatch.begin(self)   # כל הצורות נאספות ונשלחות כ-draw call אחד (effects/draw_batch.gd, כמו רימון הכבידה)
	DrawBatch.sig_on = _plain_corpse()   # גופה: גם טקסטורות (כלב, הילה) נכנסות לטביעת האצבע (_corpse_sig)
	if prof_on:
		var t0 := Time.get_ticks_usec()
		var t1 := _time
		if _corpse_still_time():
			_time -= _dead_t
		_draw_main()
		_time = t1
		_corpse_sig()
		DrawBatch.end(self)
		var k := "draw:" + _prof_name()
		prof[k] = int(prof.get(k, 0)) + Time.get_ticks_usec() - t0
		prof["draws"] = int(prof.get("draws", 0)) + 1
		return
	var t := _time
	if _corpse_still_time():
		_time -= _dead_t   # גופה רגילה: הראש / הלסת / השיער לא ממשיכים לזוז אחרי המוות (הציור נעצר - _corpse_redraw)
	_draw_main()
	if _burn_t > 0.0 and (not dead or (_char != null and not _char.skeleton())) and not _lying():
		_draw_burning()
	_time = t
	_corpse_sig()
	DrawBatch.end(self)


# גופה רגילה מצוירת עם הזמן של רגע המוות (_time - _dead_t): תנועות "חיות" שתלויות ב-_time (ראש מתנודד, לסת, שיער,
# זוהר שפועם) נעצרות, וגופה ששוכבת בשקט מפסיקה להיות מצוירת מחדש. סוג שהגופה שלו אמורה להמשיך לזוז לפי _time
# (להבות, ניצוצות...) מחזיר true ב-corpse_anim() (enemies/zombie_type.gd). אנימציית מוות לפי _dead_t ממשיכה כרגיל
func _corpse_still_time() -> bool:
	return _plain_corpse() and (type_mod == null or not type_mod.corpse_anim())


# גופה רגילה (לא רכה / לא נשרפת / לא הולכת בלי ראש)
func _plain_corpse() -> bool:
	return dead and _rag == null and _hw_t <= 0.0 and _char == null


# גופה רגילה: האם הציור הזה זהה לקודם (ראה _corpse_redraw)
func _corpse_sig() -> void:
	DrawBatch.sig_on = false
	if not _plain_corpse():
		_c_same = 0
		return
	var h := DrawBatch.signature()
	_c_same = _c_same + 1 if h == _c_hash else 0
	_c_hash = h
	_c_angle = _angle


# בוער (בקבוק תבערה / שטח בוער): להבות אמיתיות על הגוף (effects/flame_fx.gd)
func _draw_burning() -> void:
	var tt := _time
	var k := clampf(_burn_t / 1.5, 0.0, 1.0)   # דועך בסוף
	var spots := [Vector2(-5.0, -16.0), Vector2(4.0, -30.0), Vector2(-2.0, -44.0), Vector2(5.0, -52.0)]
	for i in spots.size():
		var b: Vector2 = spots[i]
		var ph := float(i) * 1.9
		var h := (14.0 + 8.0 * FlameFx.wobble(tt * 1.1, ph)) * sc * k
		FlameFx.tongue(self, Vector2(b.x * wf * sc, b.y * sc), 5.5 * sc, h, sin(tt * 5.0 + ph) * 3.0 - velocity.x * 0.02, FlameFx.PALETTE, 0.9 * k, i % 2 == 0)
	FlameFx.glow(self, Vector2(0, -32.0 * sc), Vector2(30.0, 38.0) * sc, Color(1.0, 0.5, 0.15, 0.22 * k))


func _draw_main() -> void:
	if dead and _rag != null:
		_rag.draw(self)
		return
	if dead and _char != null and _char.skeleton():
		_char.draw(self)
		return
	if type_mod != null and type_mod.draw():   # סוג חדש מצייר את עצמו (enemies/types/*.gd)
		return
	if kind == RAT:
		_draw_rat()
		return
	if kind == HAND:
		_draw_hand()
		return
	if kind == MECH:
		_draw_mech()
		return
	if kind == DOG:
		_draw_canine(0.8, false)
		return
	if kind == HOUND:
		_draw_canine(2.0, true)
		return
	if kind == GUNNER:
		_draw_gunner()
		return
	var s := Vector2(_dir * wf * sc, sc)
	if (not dead or _hw_t > 0.0) and not _lying() and is_on_floor():
		Art.ground_shadow(self, Vector2(0.0, 0.0), 14.0 * wf * sc)
	if _legless and not dead:   # זוחל: הגוף שוכב על הבטן, הראש קדימה
		DrawBatch.set_transform_matrix(self, Transform2D(PI / 2.0 * _dir, Vector2(-_dir * 26.0 * sc, -7.0 * sc)) * Transform2D(0.0, s, 0.0, Vector2.ZERO))
	elif dead and _hw_t <= 0.0 and _char == null:
		var outer := Transform2D(_angle, Vector2(0.0, -9.0 * sc))
		DrawBatch.set_transform_matrix(self, outer * Transform2D(0.0, s, 0.0, Vector2(0.0, 28.0 * sc)))
	elif _lying():
		# שוכב, או קם לאט (מסתובב מהשכיבה לעמידה)
		var k := 1.0 if dormant else clampf(_rise_t / RISE_TIME, 0.0, 1.0)
		k = k * k * (3.0 - 2.0 * k)
		var outer := Transform2D(PI / 2.0 * _lie_side * k, Vector2(0.0, lerpf(-28.0, -9.0, k) * sc))
		DrawBatch.set_transform_matrix(self, outer * Transform2D(0.0, s, 0.0, Vector2(0.0, 28.0 * sc)))
	elif kind == JETPACK:   # עף עקום
		DrawBatch.set_transform_matrix(self, Transform2D(_tilt, Vector2(0.0, -30.0 * sc)) * Transform2D(0.0, s, 0.0, Vector2(0.0, 30.0 * sc)))
	elif kind == IMP and _carrier != null:   # קטן מוחזק ביד אחת: שוכב על הצד, המותן בכף היד, ראש קדימה, רגליים תלויות
		DrawBatch.set_transform_matrix(self, Transform2D(PI / 2.0 * _dir, Vector2.ZERO) * Transform2D(0.0, s, 0.0, Vector2(0.0, 25.0 * sc)))
	elif _crash_fly:   # נזרק מהרכבת: מתגלגל
		DrawBatch.set_transform_matrix(self, Transform2D(_spin_a * _dir, Vector2(0.0, -28.0 * sc)) * Transform2D(0.0, s, 0.0, Vector2(0.0, 28.0 * sc)))
	elif kind == IMP and _thrown:   # קטן שנזרק: מסתובב באוויר
		DrawBatch.set_transform_matrix(self, Transform2D(_spin_a, Vector2(0.0, -28.0 * sc)) * Transform2D(0.0, s, 0.0, Vector2(0.0, 28.0 * sc)))
	else:
		DrawBatch.set_transform(self, Vector2.ZERO, 0.0, Vector2(s.x, -s.y) if on_ceiling else s)
	_draw_body()
	DrawBatch.set_transform_matrix(self, Transform2D.IDENTITY)


func _draw_body() -> void:
	var white := _flash > 0.0
	var sk := Color.WHITE if white else skin
	var sh_col := Color.WHITE if white else shirt
	var pa := Color.WHITE if white else pants
	var shoe_col := Color.WHITE if white else shoe
	var p := _walk_phase
	var air := not is_on_floor() and not dead and not _lying()
	var lean := 0.0
	match kind:
		RUNNER:
			lean = 7.0 if _chasing else 3.0
		BRUTE:
			lean = 2.0
		DRUNK:   # מתנדנד כמו שיכור
			lean = 3.0 + sin(_time * 1.7) * 7.0
		_:
			lean = 3.0
	if cust != null:
		lean = cust.lean()
	if _climbing and not dead:   # מטפס: הגוף נשען אל הקיר
		lean = 8.0
	elif dead and (_hw_t > 0.0 or _char != null):   # בלי ראש / בוער: מתנדנד
		lean = 3.0 + sin(_time * (5.0 if _hw_t > 0.0 else 9.0)) * 6.0
	var bob := absf(sin(p)) * 1.5
	var ck := 0.0 if dead or _lying() else (0.45 if riding else _crouch_k)   # התכופפות (על גג הרכבת: חצי כפוף)
	var hip := Vector2(0.0, -24.0 - bob * 0.5 + 11.0 * ck)
	var sh := Vector2(lean + 3.0 * ck, -41.0 - bob * 0.5 + (1.0 if _big() else 0.0) + 12.0 * ck)
	# תגובת פגיעה
	var rk := _react_k() * _react_push
	var hop := react_hop()
	var thin: bool = kind == RUNNER or kind == SCREAMER or (cust != null and cust.thin)   # גוף צר: מתקפל פחות (אחרת הפוליגון של הגופייה מתהפך)
	if rk > 0.0 and _react_zone == "body":   # כדור בבטן: מתקפל קדימה
		if thin:
			sh.x += 3.0 * rk
		else:
			sh += Vector2(6.0 * rk, minf(6.0 * rk, maxf(0.0, hip.y - sh.y - 14.0)))   # (לא יותר מדי למטה - הגוף לא מתהפך)
		hip.x -= 2.0 * rk
	elif rk > 0.0 and _react_zone == "leg":   # כדור ברגל: נשען על הרגל השנייה
		sh.x -= 2.0 * rk
	hip.y += hop
	sh.y += hop
	var head := sh + Vector2(2.5 + lean * 0.35, -9.0)
	if _big():
		head = sh + Vector2(3.5, -7.5)
	if rk > 0.0 and _react_zone == "body" and thin:   # (הראש צונח קדימה במקום הכתפיים)
		head += Vector2(1.5, 3.0) * rk
	if rk > 0.0 and _react_zone == "head":   # ירייה בראש: הראש נזרק אחורה
		head += Vector2(_react_dx * 7.0, -2.0) * rk
		sh.x += _react_dx * 2.5 * rk

	# כפות רגליים
	var runner: bool = kind == RUNNER or (cust != null and cust.thin)   # (דמות רזה מ-CHARACTER MAKER רצה כמו RUNNER)
	var fast: bool = _chasing or (cust != null and goal_x < INF)   # (CHARACTER MAKER: RUN = רץ לנקודה)
	var stride := 7.0 if runner and fast else 5.0
	var lift := 4.0 if runner else 2.5
	var f1 := Vector2(sin(p) * stride + 1.0, -maxf(0.0, cos(p)) * lift)
	var f2 := Vector2(sin(p + PI) * stride - 1.0, -maxf(0.0, cos(p + PI)) * lift)
	if _one_leg:
		f1 = Vector2(1.5, -6.0) if air else Vector2(1.0, 0.0)
	elif air:
		f1 = Vector2(5.0, -7.0)
		f2 = Vector2(-4.0, -4.0)
	f1.x += 5.0 * ck
	f2.x -= 5.0 * ck
	if _climbing and not dead:   # מטפס: רגליים נדחפות בקיר לסירוגין
		f1 = Vector2(12.0, -12.0 + sin(p) * 6.0)
		f2 = Vector2(10.0, -4.0 - sin(p) * 6.0)
	elif riding and not dead:   # על הגג: עמידת גולש, רגליים פשוקות
		f1 = Vector2(9.0, 0.0)
		f2 = Vector2(-9.0, 0.0)
	if hop != 0.0 or (rk > 0.0 and _react_zone == "leg"):   # קופץ על רגל אחת: הרגל הפגועה באוויר
		f1 = Vector2(1.0, hop)
		if not _one_leg:
			f2 = Vector2(-4.0, -7.0 * minf(1.0, rk + 0.3) + hop)

	# ---- יד אחורית ----
	var reach := sin(_time * 3.0) * 1.5
	var bs := sh + Vector2(-2.0, 2.0)
	var fs := sh + Vector2(2.5, 2.0)
	var back_hand := bs + Vector2(16.0, 1.0 - reach)
	var front_hand := fs + Vector2(17.0, 3.0 + reach)
	if (runner and fast) or _cover_state == 1:   # רץ (או בורח) - ידיים מתנופפות
		back_hand = bs + Vector2(-8.0 + sin(p) * 10.0, 12.0)
		front_hand = fs + Vector2(8.0 - sin(p) * 10.0, 10.0)
	if ck > 0.5:   # מתכופף: ידיים מגינות על הראש
		front_hand = head + Vector2(4.0, -5.0)
		back_hand = head + Vector2(-3.0, -6.0)
	if _bite_anim > 0.0:
		front_hand = fs + Vector2(18.0, -3.0)
		back_hand = bs + Vector2(18.0, -1.0)
	if _carry != null or _throw_anim > 0.0:
		var k := clampf(_throw_anim / 0.35, 0.0, 1.0)
		front_hand = fs + Vector2(4.0 + 14.0 * k, -16.0 + 18.0 * k)
	if (kind == DRUNK or kind == JETPACK) and not dead:   # מכוון את הנשק קדימה
		front_hand = fs + Vector2(15.0, -3.0 + sin(_time * 2.3) * (3.0 if kind == DRUNK else 1.0))
	if kind == HURLER and (_imp != null or _hurl_wind > 0.0):   # מחזיק זומבי קטן ביד אחת (היד השנייה חופשית)
		front_hand = _hurl_hand()
	if rk > 0.0 and _react_zone == "body" and _carry == null and kind != HURLER:   # מחזיק את הבטן
		var belly := (sh + hip) * 0.5 + Vector2(7.0, 1.0)
		front_hand = front_hand.lerp(belly, minf(1.0, rk))
		back_hand = back_hand.lerp(belly + Vector2(-2.0, -3.0), minf(1.0, rk))
	if _climbing and not dead:   # מטפס: ידיים למעלה, נאחזות בקיר לסירוגין
		front_hand = fs + Vector2(17.0, -13.0 + sin(p) * 6.0)
		back_hand = bs + Vector2(17.0, -6.0 - sin(p) * 6.0)
	elif riding and not dead:   # על הגג: ידיים פרושות לשיווי משקל
		front_hand = fs + Vector2(17.0, -8.0 + sin(_time * 9.0) * 3.0)
		back_hand = bs + Vector2(-15.0, -6.0 - sin(_time * 9.0) * 3.0)
	if dead or _lying():
		back_hand = bs + Vector2(-4.0, 15.0)
		front_hand = fs + Vector2(5.0, 15.0)
	if _legless and not dead:   # זוחל: הידיים נמשכות קדימה (לכיוון הראש) ונועצות בריצפה לסירוגין
		front_hand = fs + Vector2(9.0 + maxf(0.0, cos(p)) * 4.0, -14.0 - sin(p) * 7.0)
		back_hand = bs + Vector2(8.0 + maxf(0.0, -cos(p)) * 4.0, -14.0 + sin(p) * 7.0)
	if dead and _char != null:   # בוער: מתפתל, ידיים מנפנפות
		front_hand = fs + Vector2(8.0 + sin(_time * 13.0) * 5.0, -12.0 + cos(_time * 11.0) * 6.0)
		back_hand = bs + Vector2(-6.0 + cos(_time * 12.0) * 5.0, -10.0 + sin(_time * 10.0) * 6.0)
	if dead and _hw_t > 0.0:   # בלי ראש: הידיים מגששות למעלה, איפה שהיה הראש
		front_hand = fs + Vector2(9.0 + sin(_time * 11.0) * 4.0, -13.0 + sin(_time * 7.0) * 5.0)
		back_hand = bs + Vector2(-5.0 + cos(_time * 9.0) * 5.0, -11.0 - sin(_time * 8.0) * 4.0)
	_arm(bs, back_hand, Art.shade(sk, 0.2), Art.shade(sh_col, 0.2))

	# ---- רגליים ----
	if _legless:   # גדמים קרועים במותן
		Art.limb(self, PackedVector2Array([hip + Vector2(-3.0, -1.0), hip + Vector2(-2.0, 4.0)]), 8.0, Art.shade(pa, 0.15))
		Art.fill(self, PackedVector2Array([hip + Vector2(-6.0, 3.5), hip + Vector2(-3.0, 7.0), hip + Vector2(-1.0, 5.0),
			hip + Vector2(1.5, 7.5), hip + Vector2(3.0, 3.5)]), Color("8a0d0d"), Art.OUTLINE, 1.0)
		Art.limb(self, PackedVector2Array([hip + Vector2(-1.5, 3.0), hip + Vector2(-1.0, 8.5)]), 1.6, Color("e8dcc4"), Art.NONE)   # עמוד שדרה
	elif not _one_leg:
		_leg(hip + Vector2(-2.0, 0.0), f2, Art.shade(pa, 0.25), Art.shade(sk, 0.2), Art.shade(shoe_col, 0.2))
	if not _legless:
		_leg(hip + Vector2(2.0, 0.0), f1, pa, sk, shoe_col)
	if _one_leg:   # גדם
		Art.limb(self, PackedVector2Array([hip + Vector2(-2.0, 0.0), hip + Vector2(-3.0, 6.0)]), 7.0, Art.shade(pa, 0.25))
		var st := hip + Vector2(-3.0, 7.5)
		Art.fill(self, PackedVector2Array([st + Vector2(-4.0, -0.5), st + Vector2(-2.0, 2.5), st + Vector2(0.0, 1.0),
			st + Vector2(2.0, 3.0), st + Vector2(4.0, -0.5)]), Color("8a0d0d"), Art.OUTLINE, 1.0)
		Art.limb(self, PackedVector2Array([st + Vector2(0.5, 0.0), st + Vector2(0.5, 3.5)]), 1.6, Color("e8dcc4"), Art.NONE)   # עצם

	# ---- גוף ----
	if cust != null:
		_cust_torso(sh, hip, sk, sh_col, pa)
	else:
		match kind:
			BRUTE, BOSS, CONDUCTOR:
				_torso_brute(sh, hip, sk, sh_col, pa)
			RUNNER, SCREAMER:
				_torso_runner(sh, hip, sk, sh_col)
			_:
				_torso_walker(sh, hip, sk, sh_col)
	if kind == DRUNK and not dead:   # חליפה קרועה: חולצה לבנה ועניבה אדומה
		Art.fill(self, PackedVector2Array([sh + Vector2(-1, 1), sh + Vector2(5, 1), sh + Vector2(2, 12)]), Color(0.85, 0.82, 0.75), Art.NONE)
		DrawBatch.line(self, sh + Vector2(2, 2), sh + Vector2(1, 15), Color("8a1a1a"), 2.4)
		DrawBatch.line(self, sh + Vector2(-5, 8), sh + Vector2(-2, 14), Color(0, 0, 0, 0.5), 1.0)
		DrawBatch.line(self, sh + Vector2(6, 12), sh + Vector2(3, 18), Color(0, 0, 0, 0.5), 1.0)
	if kind == JETPACK:   # ג'טפאק על הגב + להבות
		var pk := sh + Vector2(-10.0, 7.0)
		var jc := Color.WHITE if _flash > 0.0 else Color("6a6e74")
		Art.fill_shaded(self, PackedVector2Array([pk + Vector2(-5, -10), pk + Vector2(4, -10), pk + Vector2(4, 12), pk + Vector2(-5, 12)]), jc, 0.2, 0.3, Art.OUTLINE, 1.2)
		DrawBatch.rect(self, Rect2(pk + Vector2(-4, -6), Vector2(7, 3)), Color("c8a020"))
		for nz in [-3.0, 2.0]:
			DrawBatch.rect(self, Rect2(pk + Vector2(nz - 1.5, 12), Vector2(3.5, 4)), Color("2a2a2e"))
			if not dead or _crashing:
				var fl := 7.0 + randf() * 9.0
				DrawBatch.colored_polygon(self, PackedVector2Array([pk + Vector2(nz - 2.0, 16), pk + Vector2(nz + 2.0, 16), pk + Vector2(nz, 16 + fl)]), Color(1.0, 0.5, 0.1, 0.9))
				DrawBatch.colored_polygon(self, PackedVector2Array([pk + Vector2(nz - 1.0, 16), pk + Vector2(nz + 1.0, 16), pk + Vector2(nz, 16 + fl * 0.55)]), Color(1.0, 0.95, 0.6))
	if kind == CONDUCTOR and not dead and _transformer > 0:   # שנאי על הגב
		var tb := sh + Vector2(-12.0, 4.0)
		Art.fill_shaded(self, PackedVector2Array([tb + Vector2(-6, -8), tb + Vector2(5, -8), tb + Vector2(5, 14), tb + Vector2(-6, 14)]), Color("3a4048"), 0.2, 0.3, Art.OUTLINE, 1.2)
		for i in 3:
			DrawBatch.line(self, tb + Vector2(-6, -4 + i * 6), tb + Vector2(5, -4 + i * 6), Color("20242a"), 1.0)
		DrawBatch.line(self, tb + Vector2(0, -8), sh + Vector2(2, -3), Color("1a1a1a"), 1.4, true)   # כבלים
		DrawBatch.line(self, tb + Vector2(4, -6), head + Vector2(-2, 2), Color("1a1a1a"), 1.2, true)
		var gl := 0.5 + 0.5 * sin(_time * 12.0)
		Art.glow(self, tb + Vector2(0, -10), 7.0, Color(0.5, 0.75, 1.0, 0.5 * gl))
		Art.glow(self, tb + Vector2(0, 3), 13.0, Color(0.45, 0.7, 1.0, 0.18 + 0.14 * gl))   # נקודת התורפה זוהרת - רואים מה לירות
		if randf() < 0.3:
			var sp := tb + Vector2(randf_range(-6, 5), -9)
			DrawBatch.line(self, sp, sp + Vector2(randf_range(-6, 6), -randf_range(3, 8)), Color(0.8, 0.9, 1.0), 1.0)
	if kind == BLOATER and not dead:   # בטן נפוחה שפועמת
		var pulse := 1.0 + 0.06 * sin(_time * (6.0 + 14.0 * _swell))
		var r := (9.0 + 9.0 * _swell) * pulse
		var bc := Color("b8b060").lerp(Color("c86050"), _swell)
		if _fuse_t >= 0.0 and int(_time * 20.0) % 2 == 0:
			bc = Color("ff5040")
		var c := (sh + hip) * 0.5 + Vector2(3.0, 2.0)
		Art.oval(self, c, r * 0.9, r, bc, 0.0, Art.OUTLINE)
		for v in 3:   # ורידים
			var a := float(v) * 2.1 + 0.4
			DrawBatch.line(self, c + Vector2.from_angle(a) * r * 0.3, c + Vector2.from_angle(a + 0.4) * r * 0.85, Color(0.4, 0.15, 0.2, 0.6), 1.0, true)
		Art.glow(self, c, r * 1.4, Color(0.7, 1.0, 0.3, 0.12 + 0.2 * _swell))
	if (cust != null or kind in [WALKER, RUNNER, BRUTE, SPITTER, SCREAMER, BLOATER, CRAWLER, COP, DRUNK, HURLER, IMP, JETPACK, CONDUCTOR, BOSS]) and not dead:
		_details(sh, hip, sk)
	if cust != null:   # הבגד והתוספות (מעיל, סינר, אפוד...)
		cust.draw_torso(sh, hip, sk, sh_col)
	for w in _wounds:
		Art.oval(self, w, 2.4, 1.8, Color("7a0a0a"), 0.0, Art.NONE)
		Art.oval(self, w + Vector2(0.3, 0.2), 1.1, 0.8, Color("2a0303"), 0.0, Art.NONE)

	# ---- ראש ----
	if _headless:
		Art.limb(self, PackedVector2Array([sh + Vector2(1.0, 0.0), sh + Vector2(2.0, -4.0)]), 5.0, Art.shade(sk, 0.1))
		Art.oval(self, sh + Vector2(2.0, -5.0), 3.2, 1.8, Color("8a0d0d"))
		Art.disc(self, sh + Vector2(2.0, -5.0), 1.1, Color("e8dcc4"), Art.NONE)
	else:
		_head(head, sk)

	# ---- יד קדמית ----
	if kind == BOSS and not dead:
		_boss_arms(fs, head, sk, sh_col)
		return
	if kind == SCREAMER and _scream_t > 0.0:   # ידיים פתוחות לצדדים בזמן הצרחה
		front_hand = fs + Vector2(12.0, -10.0)
	_arm(fs, front_hand, sk, sh_col, _gore_arm and not dead)
	if cust != null and (not dead or _hw_t > 0.0 or _char != null):   # חפץ ביד (רק מראה - הוא עדיין נושך)
		cust.draw_hand(front_hand, (front_hand - fs).normalized())
	if (kind == DRUNK or kind == JETPACK) and not dead:   # אקדח / תת-מקלע
		var gl := 7.0 if kind == DRUNK else 11.0
		DrawBatch.rect(self, Rect2(front_hand + Vector2(-1.0, -2.5), Vector2(gl, 3.2)), Color("1a1a1e"))
		DrawBatch.rect(self, Rect2(front_hand + Vector2(-1.0, 0.5), Vector2(2.5, 4.0)), Color("1a1a1e"))
		if _muzzle_t > 0.0:
			DrawBatch.circle(self, front_hand + Vector2(gl + 2.0, -1.0), 3.0, Color(1.0, 0.85, 0.4))
	if kind == IMP and not dead:   # כידון
		DrawBatch.line(self, front_hand + Vector2(-2.0, 1.0), front_hand + Vector2(3.0, 0.0), Color("3a2a1a"), 2.5)
		DrawBatch.colored_polygon(self, PackedVector2Array([front_hand + Vector2(3.0, -1.2), front_hand + Vector2(17.0, -0.5), front_hand + Vector2(3.0, 1.2)]), Color("c8ccd4"))
	if kind == COP and not dead:   # מגן משטרה שקוף
		var sx := sh.x + 12.0
		var shield := PackedVector2Array([Vector2(sx, sh.y - 12.0), Vector2(sx + 5.0, sh.y - 13.0), Vector2(sx + 5.0, hip.y + 8.0), Vector2(sx, hip.y + 9.0)])
		Art.fill(self, shield, Color(0.6, 0.75, 0.9, 0.45), Art.OUTLINE, 1.2)
		DrawBatch.line(self, Vector2(sx + 1.5, sh.y - 9.0), Vector2(sx + 1.5, hip.y + 4.0), Color(1, 1, 1, 0.35), 1.0)
		DrawBatch.rect(self, Rect2(sx, sh.y + 2.0, 5.0, 3.0), Color(0.9, 0.9, 0.95, 0.7))
	if kind == SCREAMER and _scream_t > 0.0:   # גלי קול
		for i in 3:
			var k := fmod(1.2 - _scream_t + float(i) * 0.3, 0.9) / 0.9
			DrawBatch.arc(self, head + Vector2(6, 2), 8.0 + k * 40.0, -0.9, 0.9, 12, Color(0.9, 0.9, 1.0, 0.7 * (1.0 - k)), 2.0, true)


# ביצועים: האנימציה של הגוף מצוירת מחדש כל פריים שני (התזוזה עצמה נשארת חלקה),
# וזומבים שלא על המסך לא מצוירים בכלל
# כשיש הרבה זומבים על המסך - כל פריים שלישי
var _redraw_tick := randi() % 3
static var _vis_frame := -1
static var _vis_count := 0
static var _vis_prev := 0


# הרבה זומבים על המסך: מדלגים על פרטים זעירים בציור
static func crowded() -> bool:
	return _vis_prev > Quality.crowded_at()   # (המשחק איטי - quality.gd: גם עם פחות זומבים)


# אותו דבר לזומבי הזה: גופה נשארת עם הפרטים שהיו לה כשמתה (אחרת הציור שלה "משתנה" ולא נעצר - _corpse_redraw)
func lod() -> bool:
	return _lod_dead if dead else crowded()


# סופרים כמה זומבים על המסך בכל פריים. מחזיר: הזומבי הזה על המסך
func _count_visible() -> bool:
	var fr := Engine.get_physics_frames()
	if fr != _vis_frame:
		_vis_prev = _vis_count
		_vis_count = 0
		_vis_frame = fr
	if not Art.on_screen(self, global_position):
		return false
	_vis_count += 1
	return true


func _maybe_redraw() -> void:
	if not _count_visible():
		return
	if type_mod != null and _flash <= 0.0 and _react_t <= 0.0 and not type_mod.wants_redraw():   # סוג שעומד בלי לזוז (GHILLIE מתחבא) - הציור הקודם נשאר
		return
	var every := (2 if _vis_prev <= 3 else (3 if _vis_prev <= 10 else (4 if _vis_prev <= 20 else (5 if _vis_prev <= 32 else 6)))) + Quality.redraw_extra()   # הרבה זומבים על המסך: כל אחד מתעדכן פחות (חוסך ציור; התזוזה עצמה נשארת חלקה)
	_redraw_tick += 1
	if _redraw_tick % every == 0 or _flash > 0.0 or (_react_t > 0.0 and (_vis_prev <= 20 or _redraw_tick % 2 == 0)) or (_burn_t > 0.0 and _redraw_tick % 2 == 0):   # בוער: הלהבות זזות
		queue_redraw()


func _big() -> bool:
	return kind == BRUTE or kind == BOSS or (cust != null and cust.big)


# בוס: מחזיק דלת של מכונית כמגן. במכה הוא מרים אותה מעל הראש
func _boss_arms(fs: Vector2, head: Vector2, sk: Color, sh_col: Color) -> void:
	var up := _slam_t > 0.0
	var hand := fs + (Vector2(4.0, -24.0) if up else Vector2(14.0, 2.0))
	_arm(fs, hand, sk, sh_col)
	var c := hand + (Vector2(4.0, -6.0) if up else Vector2(6.0, -6.0))
	var rot := -1.2 if up else 0.0
	var door := Transform2D(rot, c) * PackedVector2Array([Vector2(-5, -24), Vector2(4, -26), Vector2(6, 18), Vector2(-4, 20)])
	Art.fill_shaded(self, door, Color("7a3a32"), 0.15, 0.4, Art.OUTLINE, 1.4)
	var win := Transform2D(rot, c) * PackedVector2Array([Vector2(-3, -21), Vector2(3, -22), Vector2(3.5, -6), Vector2(-3, -5)])
	Art.fill(self, win, Color("14181e"), Art.OUTLINE, 0.8)
	DrawBatch.line(self, Transform2D(rot, c) * Vector2(-2, -18), Transform2D(rot, c) * Vector2(2, -9), Color(0.8, 0.85, 0.9, 0.35), 0.6, true)
	DrawBatch.line(self, Transform2D(rot, c) * Vector2(1, 2), Transform2D(rot, c) * Vector2(4, 2), Color("aaaaaa"), 1.2, true)   # ידית
	for i in 3:   # חלודה ופגיעות קליעים
		Art.oval(self, Transform2D(rot, c) * Vector2(-2.0 + float(i) * 2.0, 4.0 + float(i) * 4.0), 1.6, 1.0, Color(0.4, 0.2, 0.08, 0.7), 0.0, Art.NONE)


func _leg(hip: Vector2, foot: Vector2, pa: Color, sk: Color, shoe_col: Color) -> void:
	var ankle := foot + Vector2(0.0, -3.0)
	var knee := Art.joint(hip, ankle, 11.5, 11.5, 1.0)
	var mid := knee.lerp(ankle, 0.45)
	Art.limb(self, PackedVector2Array([hip, knee, mid]), 7.0, pa, Art.OUTLINE, false, false)   # (הקצוות מוסתרים: גוף / שולי מכנס)
	Art.limb(self, PackedVector2Array([mid, ankle]), 5.2, sk, Art.OUTLINE, false, shoe_col.a <= 0.0)
	# שוליים קרועים של המכנס
	Art.fill(self, PackedVector2Array([mid + Vector2(-3.8, -1.0), mid + Vector2(3.8, -1.0), mid + Vector2(3.0, 2.0), mid + Vector2(1.0, 0.8), mid + Vector2(-1.0, 2.5), mid + Vector2(-3.0, 0.8)]), pa, Art.NONE)
	if shoe_col.a > 0.0:
		Art.fill(self, PackedVector2Array([foot + Vector2(-3.0, -4.5), foot + Vector2(3.0, -4.5), foot + Vector2(7.0, -1.5), foot + Vector2(7.0, 0.0), foot + Vector2(-3.5, 0.0)]), shoe_col, Art.OUTLINE, 1.0)
	else:   # יחף
		Art.fill(self, PackedVector2Array([foot + Vector2(-2.5, -4.0), foot + Vector2(2.5, -4.0), foot + Vector2(6.5, -1.2), foot + Vector2(6.5, 0.0), foot + Vector2(-3.0, 0.0)]), sk, Art.OUTLINE, 1.0)


func _arm(shoulder: Vector2, hand: Vector2, sk: Color, sleeve: Color, gore := false) -> void:
	var w := 7.0 if _big() else (4.2 if kind == RUNNER or kind == SCREAMER or (cust != null and cust.thin) else 5.2)
	var elbow := Art.joint(shoulder, hand, 9.0, 9.5, -1.0)
	if kind != WALKER and (cust == null or not cust.sleeves):   # בלי שרוולים (גופייה)
		Art.limb(self, PackedVector2Array([shoulder, elbow, hand]), w, sk, Art.OUTLINE, true, false)   # (כף היד מכסה את הקצה)
	else:
		var cuff := shoulder.lerp(elbow, 0.75)
		Art.limb(self, PackedVector2Array([cuff, elbow, hand]), w * 0.85, sk, Art.OUTLINE, false, false)
		Art.limb(self, PackedVector2Array([shoulder, cuff]), w + 1.0, sleeve)
	var d := (hand - elbow).normalized()
	if gore and not lod():   # בשר קרוע ועצם חשופה באמה
		var m := elbow.lerp(hand, 0.5)
		Art.oval(self, m, 3.4, w * 0.42, Color("6e0c0c"), d.angle(), Art.NONE)
		DrawBatch.line(self, m - d * 2.4, m + d * 2.6, Color("e8dcc4"), 1.4, true)
		DrawBatch.circle(self, m + d * 2.8, 0.95, Color("e8dcc4"))
	# כף יד עם אצבעות שמוטות
	Art.disc(self, hand, w * 0.5 + 0.6, sk)
	if lod():   # הרבה זומבים על המסך: בלי אצבעות (לא רואים אותן בגודל הזה)
		return
	for i in 3:
		var a := d.rotated(0.5 + float(i) * 0.35)
		DrawBatch.line(self, hand + d * 1.5, hand + d * 2.0 + a * 4.0, Art.OUTLINE, 1.6, true)
		DrawBatch.line(self, hand + d * 1.5, hand + d * 2.0 + a * 4.0, sk, 0.9, true)


func _torso_walker(sh: Vector2, hip: Vector2, sk: Color, shirt_c: Color) -> void:
	Art.limb(self, PackedVector2Array([sh + Vector2(1.0, 0.0), sh + Vector2(2.0, -5.0)]), 5.0, Art.shade(sk, 0.1))   # צוואר
	var body := PackedVector2Array([
		sh + Vector2(-8.5, -1.0), sh + Vector2(8.5, 0.0), hip + Vector2(8.0, -3.0), hip + Vector2(7.5, 3.5),
		hip + Vector2(4.5, 1.0), hip + Vector2(2.0, 4.5), hip + Vector2(-1.0, 1.5), hip + Vector2(-4.5, 4.0),
		hip + Vector2(-8.0, 0.5), sh + Vector2(-9.0, 6.0),
	])
	Art.fill_shaded(self, body, shirt_c, 0.15, 0.35, Art.OUTLINE, 1.4)
	# צווארון פתוח + כפתורים
	DrawBatch.polyline(self, PackedVector2Array([sh + Vector2(-4.0, -0.6), sh + Vector2(-0.5, 4.0), sh + Vector2(4.5, -0.4)]), Art.shade(shirt_c, 0.5), 1.2, true)
	DrawBatch.circle(self, sh + Vector2(-0.8, 6.0), 0.7, Art.shade(shirt_c, 0.55))
	DrawBatch.circle(self, hip + Vector2(-0.3, -6.5), 0.7, Art.shade(shirt_c, 0.55))
	# קרע בחולצה + צלעות
	Art.fill(self, PackedVector2Array([sh + Vector2(1.0, 7.0), sh + Vector2(6.0, 5.0), sh + Vector2(5.0, 12.0), sh + Vector2(2.0, 10.0)]), Art.shade(sk, 0.15), Art.NONE)
	DrawBatch.line(self, sh + Vector2(2.5, 7.5), sh + Vector2(5.3, 6.6), Art.shade(sk, 0.45), 0.8, true)
	DrawBatch.line(self, sh + Vector2(2.7, 9.3), sh + Vector2(5.2, 8.6), Art.shade(sk, 0.45), 0.8, true)
	Art.oval(self, sh + Vector2(-3.0, 11.0), 3.0, 4.0, Color(0.45, 0.04, 0.04, 0.55), 0.3, Art.NONE)   # כתם דם
	DrawBatch.polyline(self, PackedVector2Array([sh + Vector2(-6.0, 2.0), hip + Vector2(-5.0, -3.0)]), Color(0, 0, 0, 0.25), 1.0, true)
	DrawBatch.line(self, hip + Vector2(-8.0, -1.0), hip + Vector2(8.0, -2.0), Color("2a2218"), 2.0, true)   # חגורה


func _torso_runner(sh: Vector2, hip: Vector2, sk: Color, shirt_c: Color) -> void:
	Art.limb(self, PackedVector2Array([sh + Vector2(1.0, 0.0), sh + Vector2(2.5, -5.0)]), 4.0, Art.shade(sk, 0.1))
	var body := PackedVector2Array([
		sh + Vector2(-7.0, -1.0), sh + Vector2(7.0, 0.0), hip + Vector2(6.5, -2.0),
		hip + Vector2(-6.5, -1.0), sh + Vector2(-7.5, 5.0),
	])
	Art.fill_shaded(self, body, Art.shade(sk, 0.05), 0.15, 0.3, Art.OUTLINE, 1.3)   # גוף חשוף
	# גופייה קרועה
	var top := PackedVector2Array([
		sh + Vector2(-4.0, -0.5), sh + Vector2(-1.5, -0.5), sh + Vector2(1.0, 4.0), sh + Vector2(4.0, -0.3),
		sh + Vector2(6.5, 0.0), hip + Vector2(6.0, -8.0), hip + Vector2(3.0, -5.0), hip + Vector2(0.0, -9.0),
		hip + Vector2(-3.0, -6.0), hip + Vector2(-6.5, -8.0), sh + Vector2(-7.0, 4.0),
	])
	if sh.x - hip.x > 6.0 and Geometry2D.triangulate_polygon(top).is_empty():   # נטוי מאוד קדימה: השסע בצוואר חוצה את הצד -> בלי השסע (אחרת "triangulation failed")
		top.remove_at(2)
	Art.fill_shaded(self, top, shirt_c, 0.15, 0.35, Art.OUTLINE, 1.0)
	for i in 3:   # צלעות בולטות
		var y := hip.y - 6.5 + float(i) * 2.2
		DrawBatch.line(self, Vector2(hip.x + 0.5, y), Vector2(hip.x + 5.5, y - 0.8), Art.shade(sk, 0.4), 0.9, true)
	DrawBatch.line(self, hip + Vector2(-6.5, -1.0), hip + Vector2(6.5, -1.5), Art.shade(pants, 0.2), 2.5, true)


func _torso_brute(sh: Vector2, hip: Vector2, sk: Color, shirt_c: Color, pa: Color) -> void:
	Art.limb(self, PackedVector2Array([sh + Vector2(1.0, 0.0), sh + Vector2(2.5, -3.5)]), 7.0, Art.shade(sk, 0.1))
	# גופייה מלוכלכת עם בטן
	var body := PackedVector2Array([
		sh + Vector2(-9.0, -2.0), sh + Vector2(8.0, -1.0), sh + Vector2(10.0, 6.0), hip + Vector2(11.5, -6.0),
		hip + Vector2(10.0, 0.0), hip + Vector2(3.0, 3.0), hip + Vector2(-8.0, 2.0), sh + Vector2(-10.0, 7.0),
	])
	Art.fill_shaded(self, body, shirt_c, 0.1, 0.35, Art.OUTLINE, 1.5)
	Art.oval(self, hip + Vector2(5.0, -7.0), 4.0, 3.0, Color(0.4, 0.33, 0.2, 0.35), 0.0, Art.NONE)   # כתמים
	Art.oval(self, sh + Vector2(-2.0, 6.0), 3.0, 2.5, Color(0.45, 0.04, 0.04, 0.5), 0.0, Art.NONE)
	# אוברול עם כתפיות
	var bib := PackedVector2Array([
		sh + Vector2(-5.0, 6.0), sh + Vector2(7.0, 6.0), hip + Vector2(11.0, -4.0), hip + Vector2(10.0, 2.0),
		hip + Vector2(-8.0, 2.5), hip + Vector2(-8.0, -6.0),
	])
	Art.fill_shaded(self, bib, pa, 0.15, 0.35, Art.OUTLINE, 1.3)
	Art.limb(self, PackedVector2Array([sh + Vector2(-5.0, 6.5), sh + Vector2(-6.0, -1.5)]), 2.4, pa)
	Art.limb(self, PackedVector2Array([sh + Vector2(6.0, 6.5), sh + Vector2(5.0, -1.0)]), 2.4, pa)
	Art.disc(self, sh + Vector2(-5.0, 7.0), 1.2, Color("c0a050"), Art.OUTLINE, 0.6)
	Art.disc(self, sh + Vector2(6.0, 7.0), 1.2, Color("c0a050"), Art.OUTLINE, 0.6)
	Art.fill(self, PackedVector2Array([hip + Vector2(-1.0, -8.0), hip + Vector2(5.0, -8.0), hip + Vector2(5.0, -4.0), hip + Vector2(-1.0, -4.0)]), Art.shade(pa, 0.15), Art.OUTLINE, 0.7)   # כיס


# דמות מ-CHARACTER MAKER: הגוף של zombie.gd שמתחת לבגד (characters/parts.gd torso_base)
func _cust_torso(sh: Vector2, hip: Vector2, sk: Color, sh_col: Color, pa: Color) -> void:
	cust.draw_back(sh, hip)   # תיק גב, ציורים מאחורי הגוף
	match cust.torso:
		"brute":
			_torso_brute(sh, hip, sk, sh_col, pa)
		"runner":
			_torso_runner(sh, hip, sk, sh_col)
		"bare":
			Parts.torso_bare(self, sh, hip, sk, pa)
		_:
			_torso_walker(sh, hip, sk, sh_col)


# ראש של דמות מ-CHARACTER MAKER: אותו ראש של זומבי רגיל (פנים, לסת, עין זוהרת), בגודל head_size, וכל הראש נוטה ביחד
# (גם הכובע עף אחורה בירייה בראש). השיער / הפנים / הכובע מ-characters/parts.gd: (0,0) = מרכז הראש.
func _cust_head(c: Vector2, sk: Color, tilt: float) -> void:
	var base := DrawBatch.current_transform(self)
	var hk: float = cust.head_k
	var rx := 8.0 if _big() else 7.2
	var ry := 7.5 if _big() else 8.2
	var around := base * Transform2D(tilt, Vector2(hk, hk), 0.0, c) * Transform2D(0.0, -c)   # ציור רגיל (c + ...) מוגדל ונוטה סביב מרכז הראש
	var local := base * Transform2D(tilt, Vector2(hk * rx / 7.2, hk * ry / 8.2), 0.0, c)     # החלקים: (0,0) = מרכז הראש
	var lo := lod()
	DrawBatch.set_transform_matrix(self, local)
	cust.draw_hair_back()
	DrawBatch.set_transform_matrix(self, around)
	Art.oval_shaded(self, c, rx, ry, sk, 0.0, Art.OUTLINE, 1.4)
	DrawBatch.set_transform_matrix(self, local)
	cust.draw_hair_front()
	DrawBatch.set_transform_matrix(self, around)
	Art.oval(self, c + Vector2(2.5, -0.5), 4.5, 3.0, Color(0.1, 0.0, 0.05, 0.22), 0.1, Art.NONE)   # עיניים שקועות
	if not lo:
		_head_micro(c, sk)
	else:
		DrawBatch.circle(self, c + Vector2(4.0, -1.0), 1.1, Color(0.85, 0.88, 0.75, 0.85))
	_head_rest(c, sk, lo)
	DrawBatch.set_transform_matrix(self, local)
	cust.draw_head_gear(lo)
	DrawBatch.set_transform_matrix(self, base)


func _head(c: Vector2, sk: Color) -> void:
	var tilt := sin(_time * 1.3) * 0.08
	if _react_zone == "head":   # ירייה בראש: הפנים מסתובבות למעלה
		tilt += _react_dx * 0.7 * _react_k() * _react_push
	if cust != null:
		_cust_head(c, sk, tilt)
		return
	match kind:
		RUNNER:   # שיער ארוך ופרוע מאחור
			for i in 6:
				var a := Vector2(-4.0 + float(i) * 1.2, -6.5 + float(i) * 0.4)
				var flow := Vector2(-12.0 - float(i), 3.0 + float(i) * 1.6 + sin(_time * 8.0 + float(i)) * 1.5)
				DrawBatch.line(self, c + a, c + a + flow, hair, 2.2, true)
		BRUTE:
			pass
		_:
			if not _bald or kind >= 20:
				Art.oval(self, c + Vector2(-2.5, -2.5), 6.0, 5.5, hair, 0.2)
	var rx := 8.0 if _big() else 7.2
	var ry := 7.5 if _big() else 8.2
	Art.oval_shaded(self, c, rx, ry, sk, tilt, Art.OUTLINE, 1.4)
	if kind < 20 and not _bald and not _big() and kind != COP and kind != CONDUCTOR:   # שיער על הקודקוד (צבע שונה לכל זומבי), פרוע וקרוע
		DrawBatch.colored_polygon(self, PackedVector2Array([c + Vector2(-6.8, -2.0), c + Vector2(-5.6, -5.6), c + Vector2(-2.0, -7.9), c + Vector2(2.5, -7.8),
			c + Vector2(5.4, -5.8), c + Vector2(3.0, -6.0), c + Vector2(1.0, -4.9), c + Vector2(-1.0, -6.2), c + Vector2(-3.0, -4.6),
			c + Vector2(-4.6, -5.4), c + Vector2(-5.8, -1.4)]), hair)
		DrawBatch.line(self, c + Vector2(-4.2, -6.6), c + Vector2(0.5, -8.0), Color(1, 1, 1, 0.2), 1.0, true)   # ברק בשיער
	elif kind < 20 and _bald and not _big():   # קרחת: כתם ריקבון / שריטה על הקודקוד
		Art.oval(self, c + Vector2(-2.0, -5.0), 2.2, 1.4, Color(0.42, 0.06, 0.05, 0.75), 0.3, Art.NONE)
	Art.oval(self, c + Vector2(2.5, -0.5), 4.5, 3.0, Color(0.1, 0.0, 0.05, 0.22), 0.1, Art.NONE)   # עיניים שקועות
	var lo := lod()   # הרבה זומבים על המסך: בלי פרטים זעירים (ורידים, סדקים, שערות, שיניים)
	if not lo:
		_head_micro(c, sk)
	else:
		DrawBatch.circle(self, c + Vector2(4.0, -1.0), 1.1, Color(0.85, 0.88, 0.75, 0.85))
	_head_rest(c, sk, lo)


# פרטים זעירים בפנים (מדולגים כשיש המון זומבים על המסך)
func _head_micro(c: Vector2, sk: Color) -> void:
	DrawBatch.line(self, c + Vector2(-4.0, 2.0), c + Vector2(-1.0, 5.0), Color(0.3, 0.1, 0.3, 0.4), 0.7, true)   # ורידים
	DrawBatch.line(self, c + Vector2(-3.0, -3.0), c + Vector2(-5.0, 0.5), Color(0.3, 0.1, 0.3, 0.4), 0.7, true)
	# פרטים בפנים: סדקים בעור, עין מתה, שערות
	DrawBatch.line(self, c + Vector2(-1.0, -6.5), c + Vector2(1.5, -3.5), Color(0.15, 0.05, 0.05, 0.5), 0.6, true)
	DrawBatch.line(self, c + Vector2(1.5, -3.5), c + Vector2(0.5, -1.0), Color(0.15, 0.05, 0.05, 0.5), 0.6, true)
	DrawBatch.circle(self, c + Vector2(4.0, -1.0), 1.1, Color(0.85, 0.88, 0.75, 0.85))   # עין מתה (בלי אישון)
	DrawBatch.circle(self, c + Vector2(4.3, -1.0), 0.4, Color(0.3, 0.05, 0.05))
	if kind in [WALKER, SPITTER, DRUNK, IMP, CRAWLER, BLOATER]:
		for i in 4:   # שערות דלילות
			var hs := c + Vector2(-4.0 + float(i) * 1.8, -7.5 + absf(float(i) - 1.5) * 0.6)
			DrawBatch.line(self, hs, hs + Vector2(-2.0 - float(i) * 0.5, -2.5 + sin(_time * 3.0 + float(i)) * 0.6), hair, 0.8, true)


func _head_rest(c: Vector2, sk: Color, lo: bool) -> void:
	if _det[5]:   # לחי קרועה: רואים שיניים (גור - נשאר גם בציור המפושט)
		Art.fill(self, PackedVector2Array([c + Vector2(-1.0, 1.0), c + Vector2(2.5, 0.5), c + Vector2(2.0, 4.0), c + Vector2(-1.5, 3.5)]), Color("5a1010"), Art.NONE)
		for i in 3:
			DrawBatch.line(self, c + Vector2(-0.5 + float(i) * 1.0, 1.4), c + Vector2(-0.5 + float(i) * 1.0, 2.6), Color("e0d8b0"), 0.6)
	if kind == SPITTER:   # שק חומצה ירוק נפוח בגרון
		Art.oval(self, c + Vector2(2.0, 8.0), 5.5 + (1.5 if _spit_anim > 0.0 else 0.0), 4.5, Color("8ad040"), 0.0, Art.OUTLINE, 1.0)
		Art.glow(self, c + Vector2(2.0, 8.0), 8.0, Color(0.6, 1.0, 0.2, 0.4))
	# לסת פתוחה
	var jaw_open := 2.0 + sin(_time * 5.0) * 1.0 + (2.5 if _bite_anim > 0.0 else 0.0)
	if kind == SCREAMER and _scream_t > 0.0:
		jaw_open = 7.0
	if kind == SPITTER and _spit_anim > 0.0:
		jaw_open = 5.0
	Art.fill(self, PackedVector2Array([c + Vector2(1.5, 3.0), c + Vector2(7.5, 2.0), c + Vector2(7.0, 3.5 + jaw_open), c + Vector2(2.0, 5.0 + jaw_open)]), Color("2a0a0c"), Art.OUTLINE, 1.0)
	if not lo:
		for i in 3:   # שיניים
			var tx := 3.0 + float(i) * 1.6
			Art.fill(self, PackedVector2Array([c + Vector2(tx, 2.7), c + Vector2(tx + 1.2, 2.6), c + Vector2(tx + 0.6, 4.0)]), Color("e0d8b0"), Art.NONE)
	Art.fill(self, PackedVector2Array([c + Vector2(1.5, 5.0 + jaw_open * 0.5), c + Vector2(7.0, 3.5 + jaw_open), c + Vector2(6.0, 6.5 + jaw_open), c + Vector2(1.0, 7.5 + jaw_open * 0.6)]), Art.shade(sk, 0.1), Art.OUTLINE, 1.0)
	# עיניים: אחת זוהרת, אחת שקועה
	Art.oval(self, c + Vector2(0.5, -1.5), 1.6, 1.3, Color("1a0e0e"), 0.0, Art.NONE)
	var eye := c + Vector2(4.5, -1.8)
	Art.oval(self, eye, 2.2, 1.8, Color("1a0e0e"), 0.0, Art.NONE)
	var eye_col := Color(1.0, 0.85, 0.25, 0.8)
	if kind == BOSS:
		eye_col = Color(1.0, 0.15, 0.1, 0.9)
	elif kind == SPITTER:
		eye_col = Color(0.6, 1.0, 0.2, 0.8)
	elif cust != null:
		eye_col = cust.eye_col
	Art.glow(self, eye, 5.0, eye_col)
	Art.disc(self, eye, 1.2, eye_col.lightened(0.5), Art.NONE)
	DrawBatch.circle(self, c + Vector2(0.8, -1.4), 0.7, Color(eye_col.lightened(0.2), 0.55))   # העין השנייה: ניצוץ עמום (הפנים נקראות)
	if _det[0] and (kind < 20 or cust != null):   # ריר דם מהפה
		var lip := c + Vector2(3.0, 6.8 + jaw_open * 0.7)
		DrawBatch.line(self, lip, lip + Vector2(-0.4, 3.2), Color(0.5, 0.02, 0.02, 0.9), 1.2, true)
		DrawBatch.circle(self, lip + Vector2(-0.4, 3.4), 0.8, Color(0.55, 0.03, 0.03, 0.9))
	DrawBatch.line(self, c + Vector2(2.0, -4.0), c + Vector2(7.0, -3.2), Art.shade(sk, 0.45), 1.4, true)   # גבה
	if not lo:
		Art.disc(self, c + Vector2(-2.5, 0.5), 1.8, Art.shade(sk, 0.15), Art.OUTLINE, 0.8)            # אוזן
	match kind:
		BRUTE, BOSS:   # קרחת עם תפרים
			DrawBatch.polyline(self, PackedVector2Array([c + Vector2(-5.0, -4.0), c + Vector2(-1.0, -6.5), c + Vector2(3.0, -6.8)]), Color("3a1a1a"), 1.0, true)
			for i in 4:
				var q := c + Vector2(-4.0 + float(i) * 2.2, -4.8 - float(i) * 0.6)
				DrawBatch.line(self, q + Vector2(-0.6, -1.0), q + Vector2(0.6, 1.0), Color("3a1a1a"), 0.8, true)
		CONDUCTOR, COP:   # כובע: מוליך (כחול עם פס זהב) / שוטר
			var cap := Color("1e2a44") if kind == CONDUCTOR else Color("161e2e")
			Art.fill(self, PackedVector2Array([c + Vector2(-6.0, -5.0), c + Vector2(-5.0, -10.5), c + Vector2(5.0, -10.5), c + Vector2(6.5, -5.0)]), cap, Art.OUTLINE, 1.0)
			Art.fill(self, PackedVector2Array([c + Vector2(4.0, -5.5), c + Vector2(10.0, -4.5), c + Vector2(9.0, -3.5), c + Vector2(4.0, -4.0)]), Color("0e0e12"), Art.OUTLINE, 0.8)
			DrawBatch.line(self, c + Vector2(-5.5, -6.5), c + Vector2(6.0, -6.5), Color("c8a030") if kind == CONDUCTOR else Color("8090a0"), 1.2)
		WALKER:
			DrawBatch.line(self, c + Vector2(-2.0, -7.5), c + Vector2(-4.0, -10.5), hair, 1.0, true)
			DrawBatch.line(self, c + Vector2(0.0, -8.0), c + Vector2(0.5, -11.0), hair, 1.0, true)
			Art.oval(self, c + Vector2(-1.0, -4.5), 2.0, 1.3, Color("7a0a0a"), 0.4, Art.NONE)   # פצע בראש


# ============================================================
#  זומבים של הרכבת התחתית
# ============================================================
# ---- זוחל: הולך הפוך על התקרה, ונופל כשהשחקן מתחתיו ----
func _ceiling_logic(player: Node, delta: float) -> void:
	velocity = Vector2.ZERO
	if player != null and not player.dead:
		var dx: float = player.global_position.x - global_position.x
		if absf(dx) < chase_range:
			_chasing = true
			_dir = signf(dx) if dx != 0.0 else _dir
			if absf(dx) < 26.0:   # בדיוק מעל השחקן: נופל!
				_drop_down()
				return
			global_position.x += _dir * chase_speed * 0.8 * delta
			_walk_phase += delta * chase_speed * 0.06
	_maybe_redraw()


func _drop_down() -> void:
	if not on_ceiling:
		return
	Game.story.emit("ceiling_drop", {"z": self})
	on_ceiling = false
	_shape.position.y = -33.0 * sc
	global_position.y += 66.0 * sc
	velocity = Vector2(0.0, 120.0)
	_popup("!!", Color("ff5040"), 20, -80.0)


# ---- יד מהביוב: מחכה מתחת למים ותופסת את הרגל ----
func _hand_logic(player: Node, delta: float) -> void:
	collision_layer = 4 if _grab_state == 1 else 0
	match _grab_state:
		0:
			if player != null and not player.dead and player.grabbed_by == null and player.is_on_floor() and player._roll_t <= 0.0 \
					and absf(player.global_position.x - global_position.x) < 20.0 and absf(player.global_position.y - global_position.y) < 16.0:
				_grab_state = 1
				_grab_t = 0.0
				player.grab(self)
		1:
			_grab_t += delta
			if player == null or player.grabbed_by != self:
				release_grab()
			else:
				player.global_position.x = move_toward(player.global_position.x, global_position.x, 160.0 * delta)
				if _grab_t > 2.0:   # מחזיקה חזק: כואב
					_grab_t = 0.0
					player.hurt(damage, Vector2.ZERO)
		2:
			_grab_t -= delta
			if _grab_t <= 0.0:
				_grab_state = 0
	_maybe_redraw()


func release_grab() -> void:
	if type_mod != null:   # סוג חדש שתופס (GRABBER...): מטפל בעצמו
		type_mod.on_release()
		return
	_grab_state = 2
	_grab_t = 3.5
	collision_layer = 0


# ---- מוליך: כדורי חשמל, הסתערות "רכבת", ושנאי בגב ----
func _conductor_logic(player: Node, d: Vector2, delta: float) -> float:
	_orb_cd -= delta
	_train_cd -= delta
	if _stun_t > 0.0:   # מתנשף אחרי הסתערות: הגב חשוף
		_stun_t -= delta
		_dir = _charge_dir
		return 0.0
	if _charge_t > 0.0:
		_charge_t -= delta
		_dir = _charge_dir
		if absf(d.x) < 50.0 * wf and absf(d.y) < 90.0 and player._roll_t <= 0.0:
			player.hurt(damage, Vector2(_dir, 0.0))
			player.velocity += Vector2(_dir * 460.0, -240.0)
		if _charge_t <= 0.0 or is_on_wall():
			_charge_t = 0.0
			_stun_t = 1.8
		return chase_speed * 3.6
	if _windup_t > 0.0:
		_windup_t -= delta
		if _windup_t <= 0.0:
			_charge_t = 1.3
			_charge_dir = _dir
		return 0.0
	if _train_cd <= 0.0 and absf(d.x) > 60.0:
		_windup_t = 0.9
		_train_cd = randf_range(6.0, 8.0)
		_popup("ALL ABOARD!", Color("ff6040"), 22, -125.0)
		Sfx.play("horn", global_position, 4.0)
		Sfx.play("roar", global_position, 2.0)
		return 0.0
	if _orb_cd <= 0.0:
		_orb_cd = randf_range(3.0, 4.5)
		for i in 3:
			var o := Orb.new()
			get_parent().add_child(o)
			o.floor_y = global_position.y
			o.global_position = global_position + Vector2(_dir * 20.0, -100.0 * sc)
			o.velocity = Vector2(d.x * randf_range(0.5, 1.1) + randf_range(-60.0, 60.0), -randf_range(380.0, 520.0))
	return chase_speed if absf(d.x) > 110.0 else 0.0


const RAT_PINK := Color("b07a74")
const RAT_LEG := Color("2a201c")
const RAT_SORE := Color(0.55, 0.12, 0.12, 0.85)
const RAT_EYE := Color("ff5030")


func _draw_rat() -> void:
	var c := Color.WHITE if _flash > 0.0 else skin
	var pink := RAT_PINK if _flash <= 0.0 else Color.WHITE
	if dead and _belly_up:   # הוטחה ברצפה (RAT SLAM): על הגב, הרגליים באוויר ומפרכסות עוד רגע
		DrawBatch.set_transform(self, Vector2(0.0, -7.0), _angle, Vector2(_dir, 1.0))
		rat_shape(self, c, pink, sin(_time * 8.0) * 2.0, _dead_t * 40.0, true, clampf(1.0 - _dead_t, 0.0, 1.0))
	else:
		DrawBatch.set_transform(self, Vector2.ZERO, _angle if dead else 0.0, Vector2(_dir, 1.0))
		rat_shape(self, c, pink, sin(_time * 8.0) * 2.0, _walk_phase * 2.0)
	DrawBatch.set_transform_matrix(self, Transform2D.IDENTITY)


# החולדה בקואורדינטות שלה (פונה ימינה, הרגליים ב-y=0). גם player.gd מצייר איתה חולדה שהוא מחזיק בזנב (RAT SLAM):
# tail = false - בלי הזנב (הוא מצייר אותו עד היד). legs = כמה הרגליים זזות
static func rat_shape(ci: CanvasItem, c: Color, pink: Color, tw: float, ph: float, tail := true, legs := 1.0) -> void:
	if tail:
		DrawBatch.polyline(ci, PackedVector2Array([Vector2(-7, -3), Vector2(-12, -3.5 + tw * 0.4), Vector2(-17, -5 + tw)]), pink, 1.3)   # זנב ורוד
	for i in 2:
		var lx := -3.0 + float(i) * 6.0
		DrawBatch.line(ci, Vector2(lx, -1), Vector2(lx + sin(ph + float(i) * PI) * 2.0 * legs, 0.5), RAT_LEG, 1.4)
	Art.oval(ci, Vector2(0, -4), 7.5, 4.0, c, 0.0, Art.OUTLINE, 1.0)   # גוף
	DrawBatch.line(ci, Vector2(-5.0, -6.4), Vector2(3.0, -6.8), Art.shade(c, -0.25), 1.4)   # אור על הגב (נפח)
	DrawBatch.circle(ci, Vector2(-1.5, -3.4), 1.5, RAT_SORE)   # פצע פתוח (עור קרחת)
	Art.oval(ci, Vector2(7, -5), 3.6, 2.6, c, 0.2, Art.OUTLINE, 1.0)
	DrawBatch.circle(ci, Vector2(6.4, -8.0), 1.6, pink)   # אוזן ורודה
	DrawBatch.circle(ci, Vector2(8.8, -5.6), 1.1, RAT_EYE)   # עין אדומה


const HAND_SLEEVE := Color("5a5446")
const HAND_FLESH := Color("6e0c0c")
const HAND_BONE := Color("e8dcc4")


func _draw_hand() -> void:
	if _grab_state == 0:   # בועות על המים
		for i in 2:
			var k := fmod(_time * 0.8 + float(i) * 0.5, 1.0)
			DrawBatch.arc(self, Vector2(0, -3), 3.0 + 8.0 * k, PI, TAU, 10, Color(0.7, 0.85, 0.8, 0.5 * (1.0 - k)), 1.0)
		return
	var up := -34.0 if _grab_state == 1 else -34.0 * clampf(_grab_t / 3.5, 0.0, 1.0)
	var c := Color.WHITE if _flash > 0.0 else skin
	Art.limb(self, PackedVector2Array([Vector2(-3, 2), Vector2(-1, up * 0.5), Vector2(2, up)]), 5.0, c)
	# שרוול קרוע ורטוב + עצם / בשר חשוף באמה
	var cuff := up * 0.2
	DrawBatch.colored_polygon(self, PackedVector2Array([Vector2(-6.4, 2), Vector2(0.4, 2), Vector2(0.8, cuff), Vector2(-0.6, cuff + 2.0), Vector2(-2.6, cuff - 0.5), Vector2(-4.4, cuff + 1.8), Vector2(-5.8, cuff)]), HAND_SLEEVE if _flash <= 0.0 else c)
	Art.oval(self, Vector2(-1.0, up * 0.55), 1.8, 3.0, HAND_FLESH, 0.1, Art.NONE)
	DrawBatch.line(self, Vector2(-1.2, up * 0.45), Vector2(-0.6, up * 0.65), HAND_BONE, 1.2)
	var fc := Art.shade(c, 0.2)
	for i in 4:   # אצבעות סביב הקרסול
		var a := -1.2 + float(i) * 0.5
		DrawBatch.line(self, Vector2(3, up - 2), Vector2(3, up - 2) + Vector2.from_angle(a) * 6.0, fc, 1.9)
	Art.oval_shaded(self, Vector2(3, up - 2), 4.5, 3.5, c, 0.3, Art.OUTLINE, 1.0)   # כף יד
	DrawBatch.arc(self, Vector2(-2, -3), 7.0, PI, TAU, 12, Color(0.7, 0.85, 0.8, 0.6), 1.2)   # טבעת מים


# ============================================================
#  שלב 3 (THEY BUILD)
# ============================================================
# ---- קטן: מוחזק / עף אחרי שנזרק ----
func _imp_air(player: Node, delta: float) -> void:
	if _carrier != null:
		if not is_instance_valid(_carrier) or _carrier.dead:
			_carrier = null
			_thrown = true
			velocity = Vector2(0.0, -120.0)
		else:
			global_position = _carrier.imp_hold_pos()
			velocity = Vector2.ZERO
			_dir = _carrier._dir
			_walk_phase += delta * 9.0   # מפרפר ברגליים
			_maybe_redraw()
			return
	velocity.y += gravity * delta
	_spin_a += delta * 13.0 * (1.0 if velocity.x >= 0.0 else -1.0)
	move_and_slide()
	if player != null and not player.dead and player.body_rect().grow(4.0).has_point(global_position + Vector2(0.0, -16.0 * sc)):
		player.hurt(damage, Vector2(signf(velocity.x), 0.0))   # דקירה בכידון
		velocity = Vector2(-velocity.x * 0.3, -150.0)
	if is_on_floor() or is_on_wall():
		_thrown = false
		_spin_a = 0.0
		_attack_t = 0.3
	_maybe_redraw()


# HURLER: היד שמחזיקה את הקטן (בקואורדינטות של הגוף). מחזיק ביד אחת מושטת לפניו בגובה החזה,
# ולפני הזריקה היד (והקטן) נמשכים אחורה ולמעלה
const HURL_HOLD := Vector2(18.0, -35.0)
const HURL_BACK := Vector2(-6.0, -50.0)


func _hurl_hand() -> Vector2:
	var k := clampf(1.0 - _hurl_wind / 0.55, 0.0, 1.0) if _hurl_wind > 0.0 else 0.0
	return HURL_HOLD.lerp(HURL_BACK, k * k)


# איפה הקטן נמצא כשמחזיקים אותו: המותן שלו בכף היד (ראה הציור: הוא שוכב על הצד)
func imp_hold_pos() -> Vector2:
	var h := _hurl_hand()
	return global_position + Vector2(_dir * h.x * wf * sc, h.y * sc - 1.5)


# ---- זורק: אוסף זומבי קטן, מרים אותו וזורק עליך ----
func _hurler_logic(player: Node, d: Vector2, delta: float) -> float:
	_hurl_cd -= delta
	if _imp != null and (not is_instance_valid(_imp) or _imp.dead or _imp._carrier != self):
		_imp = null
	if _hurl_wind > 0.0:
		_hurl_wind -= delta
		if _hurl_wind <= 0.0 and _imp != null:
			_throw_imp(player)
		return 0.0
	if _imp == null:
		var best: Node = null
		var bd := 280.0
		for z in get_tree().get_nodes_in_group("zombies"):
			if z.kind == IMP and not z.dead and z._carrier == null and not z._thrown and z.is_on_floor():
				var dd: float = absf(z.global_position.x - global_position.x)
				if dd < bd:
					bd = dd
					best = z
		if best != null:
			if bd > 2.0:
				_dir = signf(best.global_position.x - global_position.x)
			if bd < 26.0:   # מרים
				best._carrier = self
				_imp = best
				_popup("!", Color("ffb040"), 18, -100.0)
				return 0.0
			return chase_speed * 1.2
		return chase_speed
	if absf(d.x) > 100.0 and absf(d.x) < 480.0 and _hurl_cd <= 0.0:
		_hurl_wind = 0.55   # מכין זריקה
		return 0.0
	if absf(d.x) < 130.0:   # קרוב מדי לזריקה: נסוג
		return -walk_speed * 1.5
	return chase_speed * 0.5


func _near_hurler() -> bool:
	for z in get_tree().get_nodes_in_group("zombies"):
		if z.kind == HURLER and not z.dead and absf(z.global_position.x - global_position.x) < 260.0:
			return true
	return false


func _throw_imp(player: Node) -> void:
	var imp: Node = _imp
	_imp = null
	_hurl_cd = randf_range(2.5, 4.0)
	_throw_anim = 0.35
	imp._carrier = null
	imp._thrown = true
	var start: Vector2 = imp.global_position
	var tgt: Vector2 = player.global_position
	var T := clampf(absf(tgt.x - start.x) / 430.0, 0.45, 1.0)
	tgt += player.velocity * T * clampf(0.3 + 0.2 * smart_mult, 0.0, 1.0)   # THEY LEARN: מכוון לאן שאתה הולך
	var g: float = imp.gravity
	imp.velocity = Vector2((tgt.x - start.x) / T, (tgt.y - start.y - 0.5 * g * T * T) / T)
	imp._dir = signf(imp.velocity.x) if imp.velocity.x != 0.0 else _dir
	Sfx.play("throw", global_position, 2.0)
	imp._voice_cd = 0.0
	imp._voice("zscream2", 1.0, 0.0)


# ---- רובוט: שומר מרחק, מכוון (לייזר אדום) ויורה צרורות ----
func mech_muzzle() -> Vector2:
	return global_position + Vector2(_dir * 14.0 * wf, -34.0 * sc) + Vector2.from_angle(_gun_ang) * 26.0 * sc


func _mech_logic(player: Node, d: Vector2, delta: float) -> float:
	_gun_cd -= delta
	_muzzle_t -= delta
	var tgt: Vector2 = player.global_position + Vector2(0.0, -28.0)
	var piv := global_position + Vector2(_dir * 14.0 * wf, -34.0 * sc)
	_gun_ang = lerp_angle(_gun_ang, (tgt - piv).angle(), minf(delta * 6.0, 1.0))
	if _burst > 0:
		_burst_t -= delta
		if _burst_t <= 0.0:
			_burst -= 1
			_burst_t = 0.1
			_mech_fire(player)
		return 0.0
	if _aim_t > 0.0:
		_aim_t -= delta
		if _aim_t <= 0.0:
			_burst = 4
			Sfx.play("servo", global_position, 0.0)
			_burst_t = 0.0
		return 0.0
	if _gun_cd <= 0.0 and absf(d.x) < 600.0:
		var q := PhysicsRayQueryParameters2D.create(mech_muzzle(), tgt, 1)
		if get_world_2d().direct_space_state.intersect_ray(q).is_empty():
			_aim_t = 0.7
			_gun_cd = randf_range(2.2, 3.2)
			Sfx.play("beep", global_position, 2.0, 0.0, 2)   # נעילה על מטרה
			return 0.0
	if absf(d.x) > 380.0:
		return chase_speed
	if absf(d.x) < 240.0:
		return -walk_speed   # נסוג אחורה
	return 0.0


func _mech_fire(player: Node) -> void:
	var muzzle := mech_muzzle()
	var tgt: Vector2 = player.global_position + Vector2(0.0, -28.0)
	tgt += player.velocity * (muzzle.distance_to(tgt) / 900.0) * clampf(0.3 * smart_mult, 0.0, 0.9)   # מנבא תנועה
	var b := EnemyShot.new()
	get_parent().add_child(b)
	b.global_position = muzzle
	b.velocity = (tgt - muzzle).normalized().rotated(randf_range(-0.05, 0.05)) * 900.0
	_muzzle_t = 0.05
	Sfx.play("rifle", muzzle, -5.0, 0.1, 4)


func _draw_mech() -> void:
	var f := _dir
	var white := _flash > 0.0
	var W := func(c: Color) -> Color: return Color.WHITE if white else c
	var rust: Color = W.call(Color("7a4a2a"))
	var steel: Color = W.call(Color("5d6168"))
	var plate: Color = W.call(Color("4a5a3a"))
	var dark: Color = W.call(Color("2a2c30"))
	if dead:
		DrawBatch.set_transform_matrix(self, Transform2D(_angle, Vector2(0.0, -14.0 * sc)) * Transform2D(0.0, Vector2(f * sc, sc), 0.0, Vector2(0.0, 14.0 * sc)))
	else:
		Art.ground_shadow(self, Vector2.ZERO, 28.0 * sc)
		DrawBatch.set_transform(self, Vector2.ZERO, 0.0, Vector2(f * sc, sc))
	# ---- זחלים ----
	var track := PackedVector2Array()
	for i in 9:
		track.append(Vector2(20.0, -8.0) + Vector2.from_angle(-PI / 2.0 + PI * float(i) / 8.0) * 8.0)
	for i in 9:
		track.append(Vector2(-20.0, -8.0) + Vector2.from_angle(PI / 2.0 + PI * float(i) / 8.0) * 8.0)
	Art.fill(self, track, W.call(Color("161618")), Art.OUTLINE, 1.4)
	var lk := fmod(_walk_phase * 6.0, 6.0)
	var x := -20.0 + lk
	while x < 20.0:   # חוליות הזחל זזות
		DrawBatch.rect(self, Rect2(x, -16.5, 3.0, 2.0), W.call(Color("3a3a3e")))
		DrawBatch.rect(self, Rect2(-x - 3.0, -1.5, 3.0, 2.0), W.call(Color("3a3a3e")))
		x += 6.0
	for wx in [-18.0, -6.0, 6.0, 18.0]:   # גלגלי הנעה
		DrawBatch.circle(self, Vector2(wx, -8.0), 4.6, dark)
		DrawBatch.circle(self, Vector2(wx, -8.0), 2.0, steel)
		DrawBatch.line(self, Vector2(wx, -8.0), Vector2(wx, -8.0) + Vector2.from_angle(_walk_phase * 2.0) * 4.0, W.call(Color("8a8e94")), 1.0)
	# ---- מנוע + צינורות פליטה (מאחור) ----
	Art.fill_shaded(self, PackedVector2Array([Vector2(-30, -18), Vector2(-20, -18), Vector2(-20, -42), Vector2(-30, -40)]), dark, 0.15, 0.3, Art.OUTLINE, 1.2)
	for k in 3:
		DrawBatch.line(self, Vector2(-29, -22.0 - k * 6.0), Vector2(-21, -22.0 - k * 6.0), W.call(Color("4a4c50")), 1.5)
	for ex in [-28.0, -23.0]:
		DrawBatch.line(self, Vector2(ex, -40), Vector2(ex - 2.0, -60), W.call(Color("3a3a3c")), 3.0)
		DrawBatch.line(self, Vector2(ex - 3.5, -60), Vector2(ex - 0.5, -60), W.call(Color("1a1a1a")), 3.0)
		if not dead:
			for pf in 3:
				var age := fmod(_time * 1.2 + float(pf) * 0.33 + ex * 0.1, 1.0)
				DrawBatch.circle(self, Vector2(ex - 2.0 - age * 10.0, -62.0 - age * 22.0), 2.0 + age * 6.0, Color(0.15, 0.15, 0.15, 0.45 * (1.0 - age)))
			if randf() < 0.15:
				DrawBatch.circle(self, Vector2(ex - 2.0, -61.0), 2.2, Color(1.0, 0.55, 0.15, 0.9))
	# ---- גוף מרותך מפחים ----
	Art.fill_shaded(self, PackedVector2Array([Vector2(-22, -16), Vector2(26, -16), Vector2(24, -30), Vector2(16, -40), Vector2(-20, -42)]), steel, 0.18, 0.35, Art.OUTLINE, 1.6)
	Art.fill(self, PackedVector2Array([Vector2(-20, -18), Vector2(-4, -18), Vector2(-5, -32), Vector2(-19, -33)]), rust, Art.OUTLINE, 1.0)
	Art.fill(self, PackedVector2Array([Vector2(4, -18), Vector2(24, -18), Vector2(22, -30), Vector2(6, -31)]), plate, Art.OUTLINE, 1.0)
	for i in 8:   # ריתוכים
		DrawBatch.circle(self, Vector2(-4.5 + float(i % 2) * 0.6, -19.0 - float(i) * 1.7), 0.7, W.call(Color("b0a090")))
	for p in [Vector2(-18, -20), Vector2(-18, -31), Vector2(-6, -20), Vector2(22, -20), Vector2(8, -20), Vector2(20, -29)]:
		DrawBatch.circle(self, p, 1.0, W.call(Color("c8c8cc")))
	DrawBatch.rect(self, Rect2(10, -24, 14, 3), W.call(Color("c8a020")))   # פס אזהרה
	for i in 3:
		DrawBatch.line(self, Vector2(11.0 + i * 5.0, -21.0), Vector2(14.0 + i * 5.0, -24.0), Color(0, 0, 0, 0.8), 1.4)
	# מיכל "דלק זומבי" ירוק זוהר עם בועות
	Art.fill(self, PackedVector2Array([Vector2(-16, -34), Vector2(-6, -34), Vector2(-6, -24), Vector2(-16, -24)]), W.call(Color(0.25, 0.9, 0.3, 0.75)), Art.OUTLINE, 1.2)
	if not dead:
		Art.glow(self, Vector2(-11, -29), 9.0, Color(0.3, 1.0, 0.3, 0.25 + 0.15 * sin(_time * 5.0)))
		for bb in 3:
			var by := -25.0 - fmod(_time * 8.0 + float(bb) * 3.0, 9.0)
			DrawBatch.circle(self, Vector2(-13.0 + float(bb) * 2.5, by), 0.8, Color(0.8, 1.0, 0.8, 0.8))
	# פנס קדמי
	DrawBatch.circle(self, Vector2(25, -26), 2.4, W.call(Color("e8e0b0")))
	if not dead:
		Art.glow(self, Vector2(27, -26), 8.0, Color(1.0, 0.95, 0.7, 0.25))
	# ---- תא: כלוב + הזומבי (הנקודה הפגיעה) ----
	if not dead:
		var sk: Color = W.call(skin)
		var bob := sin(_time * 3.0) * 0.6
		# כבלים מהראש למכונה (הזומבי מחובר לרובוט)
		DrawBatch.line(self, Vector2(-8, -64 + bob), Vector2(-17, -42), W.call(Color("1a1a1a")), 1.6, true)
		DrawBatch.line(self, Vector2(-6, -66 + bob), Vector2(-20, -45), W.call(Color("8a2020")), 1.2, true)
		# גוף: חולצה קרועה וצלעות חשופות
		Art.fill(self, PackedVector2Array([Vector2(-11, -40), Vector2(5, -40), Vector2(5, -54 + bob), Vector2(-10, -55 + bob)]), W.call(shirt), Art.OUTLINE, 1.0)
		Art.fill(self, PackedVector2Array([Vector2(-3, -42), Vector2(4, -42), Vector2(4, -51 + bob), Vector2(-2, -52 + bob)]), W.call(Color("8a3a2a")), Art.NONE)
		for r in 3:
			DrawBatch.line(self, Vector2(-2, -44.0 - r * 2.6 + bob * 0.5), Vector2(4, -44.5 - r * 2.6 + bob * 0.5), W.call(Color("e0d8c0")), 0.9)
		# יד על ידית ההיגוי
		Art.limb(self, PackedVector2Array([Vector2(3, -52 + bob), Vector2(9, -46), Vector2(13, -42)]), 2.6, sk)
		DrawBatch.line(self, Vector2(13, -38), Vector2(15, -45), W.call(Color("2a2a2a")), 1.6)
		# ראש: נרקב, לסת פתוחה, שתל מתכת עם עין אדומה
		var hc := Vector2(-2.0, -61.0 + bob)
		Art.oval(self, hc, 7.0, 7.8, sk, 0.0, Art.OUTLINE, 1.2)
		Art.oval(self, hc + Vector2(-3.0, 2.0), 2.4, 1.6, W.call(Art.shade(skin, 0.35)), 0.3, Art.NONE)   # כתם ריקבון
		Art.fill(self, PackedVector2Array([hc + Vector2(-6, -6), hc + Vector2(2, -8), hc + Vector2(3, -3), hc + Vector2(-5, -1)]), W.call(Color("6a6e74")), Art.OUTLINE, 0.9)   # שתל מתכת
		DrawBatch.circle(self, hc + Vector2(-2, -4.5), 0.7, W.call(Color("c8c8cc")))
		Art.glow(self, hc + Vector2(3.5, -1.0), 5.0, Color(1.0, 0.15, 0.1, 0.8))
		DrawBatch.circle(self, hc + Vector2(3.5, -1.0), 1.3, Color(1.0, 0.45, 0.35))
		Art.fill(self, PackedVector2Array([hc + Vector2(1, 3), hc + Vector2(7, 2.5), hc + Vector2(6, 7.5 + absf(sin(_time * 6.0)) * 1.5), hc + Vector2(1, 6)]), W.call(Color("2a0808")), Art.OUTLINE, 0.8)   # לסת פתוחה
		for tth in 3:
			DrawBatch.line(self, hc + Vector2(2.0 + tth * 1.6, 3.0), hc + Vector2(2.3 + tth * 1.6, 4.4), W.call(Color("e8e0c8")), 0.8)
		# כלוב מגן
		for cx in [-14.0, 8.0]:
			DrawBatch.line(self, Vector2(cx, -40), Vector2(cx + 2.0, -70), W.call(Color("3a3c40")), 1.6)
		DrawBatch.arc(self, Vector2(-3, -70), 11.0, PI, TAU, 10, W.call(Color("3a3c40")), 1.6)
	DrawBatch.rect(self, Rect2(-20, -44, 34, 4), dark)   # שפת התא
	# אנטנה מהבהבת
	DrawBatch.line(self, Vector2(-18, -42), Vector2(-22, -74), dark, 1.2)
	DrawBatch.circle(self, Vector2(-22, -74), 1.8, Color(1.0, 0.15, 0.1, 0.4 + 0.6 * float(int(_time * 3.0) % 2)))
	DrawBatch.set_transform_matrix(self, Transform2D.IDENTITY)
	if dead:
		return
	# ---- זרוע הידראולית + גאטלינג מסתובב ----
	var base := Vector2(f * 12.0 * sc, -30.0 * sc)
	var piv := Vector2(f * 14.0 * wf, -34.0 * sc)
	DrawBatch.line(self, base, piv, Color("3a3c40"), 4.0)
	DrawBatch.line(self, base + Vector2(0, -2), piv + Vector2(0, -2), Color("9a9ea4"), 1.0)
	var dv := Vector2.from_angle(_gun_ang)
	var nv := dv.rotated(PI / 2.0)
	var L := 30.0 * sc
	DrawBatch.colored_polygon(self, PackedVector2Array([piv - nv * 5.0 - dv * 7.0, piv - nv * 5.0 + dv * 11.0, piv + nv * 5.0 + dv * 11.0, piv + nv * 5.0 - dv * 7.0]), Color("26282c"))
	DrawBatch.line(self, piv - nv * 5.0 + dv * 2.0, piv - nv * 5.0 + dv * 9.0, Color("c8a020"), 1.5)
	var spin := _time * (30.0 if _burst > 0 else 2.0)   # הקנים מסתובבים בירי
	for k in 3:
		var o := sin(spin + float(k) * TAU / 3.0) * 2.2
		DrawBatch.line(self, piv + dv * 10.0 + nv * o, piv + dv * L + nv * o, Color(0.12 + 0.05 * float(k), 0.12, 0.13), 1.6)
	DrawBatch.line(self, piv + dv * (L - 3.0) - nv * 3.0, piv + dv * (L - 3.0) + nv * 3.0, Color("44464a"), 2.5)
	# שרשרת תחמושת מהגוף לנשק
	var belt_a := Vector2(f * 2.0 * sc, -26.0 * sc)
	for i in 7:
		var tt := float(i) / 6.0
		var bp := belt_a.lerp(piv + nv * 4.0, tt) + Vector2(0, sin(tt * PI) * 6.0)
		DrawBatch.rect(self, Rect2(bp - Vector2(1.2, 1.2), Vector2(2.4, 2.4)), Color("c8903a"))
	var muzzle := piv + dv * L
	if _muzzle_t > 0.0:
		for i in 6:
			DrawBatch.line(self, muzzle, muzzle + dv.rotated(randf_range(-0.6, 0.6)) * randf_range(6.0, 16.0), Color(1.0, 0.85, 0.4), 2.0)
	if _aim_t > 0.0:   # לייזר אזהרה
		DrawBatch.line(self, muzzle, muzzle + dv * 520.0, Color(1.0, 0.1, 0.1, 0.35 + 0.35 * sin(_time * 30.0)), 1.2)
	if hp < max_hp * 0.4:   # עשן וניצוצות כשנפגע
		for i in 3:
			var age := fmod(_time * 0.8 + float(i) * 0.33, 1.0)
			DrawBatch.circle(self, Vector2(-f * 8.0, -44.0 * sc - age * 30.0), 4.0 + age * 8.0, Color(0.2, 0.2, 0.2, 0.45 * (1.0 - age)))
		if randf() < 0.2:
			var sp := Vector2(f * randf_range(-15.0, 15.0), -randf_range(20.0, 40.0) * sc)
			DrawBatch.line(self, sp, sp + Vector2(randf_range(-6, 6), -randf_range(3, 8)), Color(1.0, 0.85, 0.4), 1.2)


# ============================================================
#  שלב 4 (THEY HUNT)
# ============================================================
# ---- כלב: מחכה רגע (כל כלב בזמן אחר), ואז רץ וקופץ עליך ----
func _dog_logic(player: Node, d: Vector2, delta: float) -> float:
	if _hold_t > 0.0:
		_hold_t -= delta
		return chase_speed * 0.12   # מתגנב לאט
	if is_on_floor() and absf(d.x) < 130.0 and absf(d.x) > 30.0 and _attack_t <= 0.0:   # זינוק
		velocity = Vector2(signf(d.x) * 380.0, -330.0)
		_attack_t = 0.9
		_bite_anim = 0.3
	return chase_speed


# ---- שיכור: מתנדנד ויורה באקדח, מפספס הרבה ----
func _drunk_logic(player: Node, d: Vector2, delta: float) -> float:
	_gun_cd -= delta
	_muzzle_t -= delta
	if _gun_cd <= 0.0 and absf(d.x) < 520.0:
		var muzzle := global_position + Vector2(_dir * 22.0 * wf, -38.0 * sc)
		var tgt: Vector2 = player.global_position + Vector2(0.0, -28.0)
		if get_world_2d().direct_space_state.intersect_ray(PhysicsRayQueryParameters2D.create(muzzle, tgt, 1)).is_empty():
			_gun_cd = randf_range(1.5, 2.8)
			var b := EnemyShot.new()
			get_parent().add_child(b)
			b.global_position = muzzle
			b.velocity = (tgt - muzzle).normalized().rotated(randf_range(-0.35, 0.35)) * 700.0
			_muzzle_t = 0.06
			Sfx.play("pistol", muzzle, -2.0, 0.12, 4)
			if randf() < 0.25:
				_popup("*HIC*", Color("d0c0a0"), 13, -78.0)
	return chase_speed * maxf(0.15, 0.55 + 0.55 * sin(_time * 1.3 + float(get_instance_id() % 7)))


# ---- מקלען: לא זז, מסתובב ויורה צרורות ארוכים ----
func _gunner_pivot() -> Vector2:
	return global_position + Vector2(_dir * 10.0 * wf, -34.0 * sc)


func _gunner_logic(player: Node, d: Vector2, delta: float) -> float:
	_gun_cd -= delta
	_muzzle_t -= delta
	var piv := _gunner_pivot()
	var tgt: Vector2 = player.global_position + Vector2(0.0, -26.0)
	_gun_ang = lerp_angle(_gun_ang, (tgt - piv).angle(), minf(delta * 4.0, 1.0))
	if _burst > 0:
		_burst_t -= delta
		if _burst_t <= 0.0:
			_burst -= 1
			_burst_t = 0.08
			var muzzle := piv + Vector2.from_angle(_gun_ang) * 34.0
			var b := EnemyShot.new()
			get_parent().add_child(b)
			b.global_position = muzzle
			b.velocity = Vector2.from_angle(_gun_ang).rotated(randf_range(-0.07, 0.07)) * 950.0
			_muzzle_t = 0.05
			Sfx.play("rifle", muzzle, -4.0, 0.1, 4)
		return 0.0
	if _aim_t > 0.0:
		_aim_t -= delta
		if _aim_t <= 0.0:
			_burst = 6
		return 0.0
	if _gun_cd <= 0.0 and absf(d.x) < 650.0:
		if get_world_2d().direct_space_state.intersect_ray(PhysicsRayQueryParameters2D.create(piv, tgt, 1)).is_empty():
			_aim_t = 0.5
			_gun_cd = randf_range(2.4, 3.4)
			Sfx.play("servo", global_position, 0.0)
	return 0.0


# ---- ג'טפאק: עף מעליך בלי שליטה טובה ויורה מלמעלה ----
func _jet_logic(player: Node, delta: float) -> void:
	_gun_cd -= delta
	_muzzle_t -= delta
	var tgt := global_position + Vector2(sin(_time * 0.5) * 60.0, sin(_time) * 20.0)
	var near: bool = player != null and not player.dead and absf(player.global_position.x - global_position.x) < 900.0
	if near:
		_chasing = true
		tgt = player.global_position + Vector2(sin(_time * 0.6 + float(get_instance_id() % 11)) * 170.0, -230.0 + sin(_time * 1.1) * 40.0)
		_dir = signf(player.global_position.x - global_position.x) if player.global_position.x != global_position.x else _dir
	var to_t := tgt - global_position
	velocity += to_t.normalized() * 300.0 * delta * clampf(to_t.length() / 120.0, 0.3, 1.0)
	velocity += Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * 600.0 * delta   # טלטולים
	if randf() < delta * 0.7:   # מאבד שליטה לרגע
		velocity += Vector2(randf_range(-170.0, 170.0), randf_range(-150.0, 110.0))
		Sfx.play("jet", global_position, -6.0, 0.2, 2)
	velocity *= 1.0 - 1.3 * delta
	global_position += velocity * delta
	global_position.y = clampf(global_position.y, _ground_y - 420.0, _ground_y - 70.0)
	_tilt = lerpf(_tilt, clampf(velocity.x * 0.004, -0.5, 0.5) * _dir + sin(_time * 7.0) * 0.1, minf(delta * 6.0, 1.0))
	if near and _gun_cd <= 0.0:
		var muzzle := global_position + Vector2(_dir * 18.0, -34.0 * sc)
		var aim: Vector2 = player.global_position + Vector2(0.0, -26.0)
		if get_world_2d().direct_space_state.intersect_ray(PhysicsRayQueryParameters2D.create(muzzle, aim, 1)).is_empty():
			_gun_cd = randf_range(1.3, 2.3)
			var b := EnemyShot.new()
			get_parent().add_child(b)
			b.global_position = muzzle
			b.velocity = (aim - muzzle).normalized().rotated(randf_range(-0.12, 0.12)) * 760.0
			_muzzle_t = 0.05
			Sfx.play("pistol", muzzle, -3.0, 0.12, 4)
	_maybe_redraw()


func _jet_crash(delta: float) -> void:
	velocity.y += 650.0 * delta
	_angle += 13.0 * delta * (1.0 if velocity.x >= 0.0 else -1.0)   # גלגלונים באוויר
	if Engine.get_physics_frames() % 3 == 0:
		Particles.burst(get_parent(), global_position + Vector2(0, -30), "smoke", Vector2.UP, 2)
		Particles.burst(get_parent(), global_position + Vector2(0, -30), "fire", Vector2.UP, 2)
	var to := global_position + velocity * delta
	var hit := get_world_2d().direct_space_state.intersect_ray(PhysicsRayQueryParameters2D.create(global_position, to, 1))
	if not hit.is_empty() or to.y >= _ground_y - 2.0:
		_crashing = false
		Boom.blast(get_parent(), global_position + Vector2(0, -16), 120.0, 60.0, 45, 2, "jet")   # פוגע בך ובזומבים
		queue_free()
		return
	global_position = to
	queue_redraw()


# ---- בוס כלב: מסתובב סביבך, מתכופף, מזנק מהר מאוד, ולפעמים מסובב שרשרת קוצים ----
func _hound_logic(player: Node, d: Vector2, delta: float) -> float:
	_ht -= delta
	match _hstate:
		0:
			if _ht <= 0.0:
				_cycle += 1
				if _cycle % 3 == 0 and absf(d.x) < 220.0:
					_hstate = 4
					_ht = 1.1
					Sfx.play("whoosh", global_position, 4.0)
				else:
					_hstate = 1
					_ht = 0.55
					_popup("GRRR", Color("ff5030"), 22, -100.0)
					Sfx.play("growl", global_position, 5.0)
				return 0.0
			if absf(d.x) < 190.0:
				return -chase_speed * 0.9   # שומר מרחק
			if absf(d.x) > 290.0:
				return chase_speed
			return chase_speed * 0.25 * sin(_time * 3.0)
		1:
			if _ht <= 0.0:
				_hstate = 2
				_ht = 1.0
				_lunge_dir = signf(d.x) if d.x != 0.0 else _dir
				_lunge_hit = false
				velocity = Vector2(_lunge_dir * chase_speed * 4.2, -340.0)
				Sfx.play("bark", global_position, 6.0)
			return 0.0
		2:
			_dir = _lunge_dir
			if not _lunge_hit and absf(d.x) < 80.0 and absf(d.y) < 90.0 and player._roll_t <= 0.0:
				_lunge_hit = true
				_bite_anim = 0.3
				player.hurt(damage, Vector2(_dir, 0.0))
				player.velocity += Vector2(_dir * 420.0, -220.0)
			if _ht <= 0.0 or is_on_wall() or (is_on_floor() and _ht < 0.7 and d.x * _lunge_dir < -170.0):
				_hstate = 3
				_ht = 0.9
			return chase_speed * 4.2
		3:   # מחליק ומתנשף: הזמן לירות בו
			_dir = _lunge_dir
			if _ht <= 0.0:
				_hstate = 0
				_ht = randf_range(1.2, 2.2)
			return 0.0
		4:   # שרשרת הקוצים מסתובבת
			if absf(d.x) < 150.0 and absf(d.y) < 120.0 and player._roll_t <= 0.0:
				player.hurt(1, Vector2(signf(d.x), 0.0))
			if _ht <= 0.0:
				_hstate = 0
				_ht = randf_range(1.0, 2.0)
			return 0.0
	return 0.0


# ---- ציור כלב (רגיל / בוס עם שרשרת קוצים) ----
func _draw_canine(S: float, hound: bool) -> void:
	var f := _dir
	var white := _flash > 0.0
	var run := absf(velocity.x) > 25.0
	var ph := _walk_phase * 1.6
	var crouch := 1.0 if (hound and _hstate == 1) else 0.0
	var base := Transform2D(0.0, Vector2(f * S, S), 0.0, Vector2.ZERO)
	var lt := minf(_dead_t - _land_t, 4.0) if dead and _land_t >= 0.0 else -1.0   # כמה זמן הגופה כבר על הריצפה (אחרי 4 שניות כבר לא זז)
	if dead:
		if lt >= 0.0:   # שלולית דם שמתפשטת מתחת לכלב
			var pk := clampf(lt / 2.0, 0.0, 1.0)
			DrawBatch.ellipse(self, Vector2(f * 6.0 * S, 0.5), (8.0 + 22.0 * pk) * S, (1.5 + 2.0 * pk) * S, Color(0.3, 0.02, 0.02, 0.55))
		base = Transform2D(_angle, Vector2(0.0, -20.0 * S)) * Transform2D(0.0, Vector2(f * S, S), 0.0, Vector2(0.0, 20.0 * S))
	else:
		Art.ground_shadow(self, Vector2.ZERO, 26.0 * S)
	DrawBatch.set_transform_matrix(self, base)
	var gal := clampf(absf(velocity.x) / 260.0, 0.0, 1.0) if run and not dead else 0.0   # דהירה: כמה מהר
	var bob := (maxf(0.0, sin(ph)) * 6.0 * gal + absf(sin(ph)) * 1.2) if run and not dead else 0.0   # רגע באוויר בכל צעד
	var nk := Vector2(23.0, -36.0)
	# מת על הריצפה: הגוף צונח לקרקע והרגליים נשמטות לצדדים
	var dk := clampf(1.0 - absf(wrapf(_angle, -PI, PI)) / 1.2, 0.0, 1.0) if dead and is_on_floor() else 0.0
	# ---- שרשרת קוצים (מאחורה) ----
	if hound and not dead:
		var pts := []
		if _hstate == 4:   # מסתובבת סביבו
			var a := _time * 14.0
			for i in 9:
				pts.append(nk + Vector2.from_angle(a - float(i) * 0.12) * (6.0 + float(i) * 6.0))
		else:   # נגררת על הריצפה
			for i in 9:
				var k := float(i) / 8.0
				pts.append(nk.lerp(Vector2(-58.0, -1.0), k) + Vector2(0.0, sin(k * PI) * 8.0 + sin(_time * 6.0 + k * 4.0) * 1.0))
		for i in pts.size():
			var p: Vector2 = pts[i]
			Art.oval(self, p, 3.4, 2.0, Color("4a4a50"), float(i % 2) * 1.2, Art.OUTLINE, 0.8)
			if i % 2 == 1:   # קוצים
				for s2 in 3:
					var sa := float(s2) * TAU / 3.0 + _time
					DrawBatch.colored_polygon(self, PackedVector2Array([p + Vector2.from_angle(sa + 0.4) * 2.0, p + Vector2.from_angle(sa) * 6.5, p + Vector2.from_angle(sa - 0.4) * 2.0]), Color("9a9aa2"))
		Art.oval(self, pts[-1], 5.5, 5.5, Color("3a3a40"), 0.0, Art.OUTLINE, 1.0)   # כדור קוצים בקצה
		for s2 in 6:
			var sa := float(s2) * TAU / 6.0
			DrawBatch.colored_polygon(self, PackedVector2Array([pts[-1] + Vector2.from_angle(sa + 0.35) * 4.0, pts[-1] + Vector2.from_angle(sa) * 10.0, pts[-1] + Vector2.from_angle(sa - 0.35) * 4.0]), Color("b0b0b8"))
	# ---- ספרייט הכלב (תמונה אחת + תנועה פרוצדורלית: דהירה, קפיצה, כריעה) ----
	var rot := 0.0
	var sq := Vector2.ONE
	if not dead:
		if not is_on_floor():
			rot = clampf(velocity.y / 1400.0, -0.3, 0.3)
		elif run:   # דהירה: הגוף מתמתח ומתכווץ ומתנדנד קדימה-אחורה
			rot = sin(ph + 0.6) * (0.05 + 0.09 * gal)
			sq = Vector2(1.0 + sin(ph) * 0.08 * gal, 1.0 - sin(ph) * 0.06 * gal)
		else:
			sq = Vector2(1.0, 1.0 + sin(_time * 2.0) * 0.015)   # נשימה
		sq *= Vector2(1.0 + crouch * 0.06, 1.0 - crouch * 0.16)
		if _bite_anim > 0.0 or (hound and _hstate == 2):
			rot -= 0.08
	var kick := 0.0   # מת: בעיטות ברגליים שדועכות + עווית אחרונה
	if dead:
		rot = 0.08 * dk
		bob = -15.0 * dk
		if lt >= 0.0:
			kick = exp(-lt * 1.2) + 0.8 * exp(-pow((lt - 1.9) / 0.15, 2.0))
			rot += sin(lt * 9.0) * 0.03 * kick
			sq = Vector2(1.0, 1.0 + sin(lt * 4.5) * 0.035 * exp(-lt * 0.6))   # נשימות אחרונות
	var bm := base * Transform2D(rot, sq, 0.0, Vector2(0.0, -bob))
	var mod := Color(4, 4, 4) if white else Color.WHITE
	var k := Vector2(76.0 / 186.0, 50.0 / 123.0)   # פיקסל בתמונה -> יחידה מקומית
	var amp := 0.0 if dead else clampf(absf(velocity.x) / 220.0, 0.0, 0.85)
	var air := not dead and not is_on_floor()
	# שוקיים נפרדות (צד ימין של התמונה) שמתנדנדות סביב הברך: [x0, חיתוך y, x1, ציר x, היסט פאזה, זווית באוויר]
	for lg in [[0.0, 84.0, 24.0, 12.0, 0.0, 0.6], [24.0, 84.0, 60.0, 36.0, 0.55, 0.5], [90.0, 76.0, 150.0, 115.0, PI, -0.6]]:   # דהירה: האחוריות כמעט יחד, הקדמיות הפוך
		var src := Rect2(192.0 + lg[0], lg[1] - 2.0, lg[2] - lg[0], 125.0 - lg[1])
		var pv := Vector2(-36.0, -50.0) + Vector2(lg[3], lg[1]) * k
		var la: float = lg[5] if air else sin(ph + lg[4]) * amp
		var lift := maxf(0.0, cos(ph + lg[4])) * 3.0 * amp if not air else 0.0   # הרגל מתרוממת כשהיא חוזרת קדימה
		if dead:
			la = (-1.35 if lg[0] > 80.0 else 1.35) * dk
			if lt < 0.0:   # באוויר: מפרפר
				la = sin(_dead_t * 22.0 + float(lg[4]) * 2.0) * 0.9
			else:
				la += sin(lt * 17.0 + float(lg[4]) * 2.3) * 0.55 * kick
		DrawBatch.set_transform_matrix(self, bm * Transform2D(la, pv + Vector2(0.0, -lift)) * Transform2D(0.0, -pv))
		DrawBatch.texture_rect_region(self, DOG_TEX, Rect2(Vector2(-36.0, -50.0) + Vector2(lg[0], lg[1] - 2.0) * k, src.size * k), src, mod)
	DrawBatch.set_transform_matrix(self, bm)
	DrawBatch.texture_rect_region(self, DOG_TEX, Rect2(-36, -50, 76, 50), Rect2(0, 0, 186, 123), mod)
	if hound:   # קולר קוצים
		Art.limb(self, PackedVector2Array([nk + Vector2(-3, -9), nk + Vector2(3, 9)]), 5.0, Color("2a2a2e"))
		for i in 5:
			var cp := nk.lerp(nk + Vector2(6, 18), float(i) / 4.0) + Vector2(-3, -9)
			DrawBatch.colored_polygon(self, PackedVector2Array([cp + Vector2(-1.5, 0), cp + Vector2(-6, -1), cp + Vector2(-1.5, 2)]), Color("b8b8c0"))
			DrawBatch.colored_polygon(self, PackedVector2Array([cp + Vector2(1.5, 0), cp + Vector2(6, 1), cp + Vector2(1.5, 2)]), Color("b8b8c0"))
	DrawBatch.set_transform_matrix(self, Transform2D.IDENTITY)


# ---- ציור מקלען על חצובה ----
const GUNNER_BURST := [0.16, 0.24, 0.33, 0.45]   # מקלען מת: מתי נשמעות היריות האחרונות (שניות אחרי המוות)

func _draw_gunner() -> void:
	if dead:
		_draw_gunner_dead()
		return
	var f := _dir
	var white := _flash > 0.0
	var sk: Color = Color.WHITE if white else skin
	var army: Color = Color.WHITE if white else shirt
	Art.ground_shadow(self, Vector2.ZERO, 26.0 * sc)
	DrawBatch.set_transform(self, Vector2.ZERO, 0.0, Vector2(f * sc, sc))
	# שקי חול
	for p in [Vector2(14, -5), Vector2(25, -5), Vector2(19, -13)]:
		Art.oval(self, p, 7.0, 5.0, Color("8a7a58"), 0.0, Art.OUTLINE, 1.0)
	# זומבי כורע מאחור
	Art.limb(self, PackedVector2Array([Vector2(-8, -18), Vector2(2, -10), Vector2(-4, 0)]), 6.0, Color.WHITE if white else pants)
	Art.fill(self, PackedVector2Array([Vector2(-12, -18), Vector2(2, -18), Vector2(3, -42), Vector2(-9, -44)]), army, Art.OUTLINE, 1.2)
	Art.limb(self, PackedVector2Array([Vector2(-2, -38), Vector2(6, -32), Vector2(12, -34)]), 4.0, sk)
	var hc := Vector2(-2, -51)
	Art.oval(self, hc, 7.0, 7.5, sk, 0.0, Art.OUTLINE, 1.2)
	Art.fill(self, PackedVector2Array([hc + Vector2(-8, -1), hc + Vector2(-6, -8), hc + Vector2(2, -10), hc + Vector2(8, -5), hc + Vector2(9, -1)]), Color.WHITE if white else Color("3a4a2e"), Art.OUTLINE, 1.0)   # קסדה
	Art.glow(self, hc + Vector2(4, 1), 3.5, Color(1.0, 0.2, 0.1, 0.7))
	DrawBatch.line(self, hc + Vector2(2, 4), hc + Vector2(6, 4), Color(0.2, 0.05, 0.05), 1.2)
	# חצובה
	DrawBatch.line(self, Vector2(10, -32), Vector2(3, 0), Color("2a2a2e"), 1.8)
	DrawBatch.line(self, Vector2(10, -32), Vector2(19, 0), Color("2a2a2e"), 1.8)
	DrawBatch.set_transform_matrix(self, Transform2D.IDENTITY)
	# מקלע + מגן פלדה (מסתובבים לכיוון השחקן)
	var piv := Vector2(f * 10.0 * wf, -34.0 * sc)
	var dv := Vector2.from_angle(_gun_ang)
	var nv := dv.rotated(PI / 2.0)
	DrawBatch.colored_polygon(self, PackedVector2Array([piv - nv * 4.0 - dv * 10.0, piv - nv * 4.0 + dv * 12.0, piv + nv * 4.0 + dv * 12.0, piv + nv * 4.0 - dv * 10.0]), Color("26282c"))
	DrawBatch.line(self, piv + dv * 12.0, piv + dv * 34.0, Color("3a3c40"), 4.0)
	for i in 4:
		DrawBatch.circle(self, piv + dv * (15.0 + float(i) * 4.5), 1.0, Color(0.08, 0.08, 0.1))
	DrawBatch.rect(self, Rect2(piv + nv * 4.0 - Vector2(4, 0), Vector2(8, 7)), Color("4a4a2e"))   # ארגז תחמושת
	var sp := piv + dv * 8.0
	var shield := PackedVector2Array([sp - nv * 18.0, sp - nv * 18.0 + dv * 3.0, sp + nv * 12.0 + dv * 3.0, sp + nv * 12.0])
	DrawBatch.colored_polygon(self, shield, Color.WHITE if white else Color("5d6168"))
	shield.append(shield[0])
	DrawBatch.polyline(self, shield, Color(0, 0, 0, 0.8), 1.2, true)
	DrawBatch.line(self, sp - nv * 10.0 + dv * 1.5, sp - nv * 6.0 + dv * 1.5, Color(0.05, 0.05, 0.05), 1.5)   # חריץ הצצה
	var muzzle := piv + dv * 34.0
	if _aim_t > 0.0:
		Art.glow(self, muzzle, 6.0, Color(1.0, 0.6, 0.2, 0.5 + 0.4 * sin(_time * 30.0)))
	if _muzzle_t > 0.0:
		for i in 5:
			DrawBatch.line(self, muzzle, muzzle + dv.rotated(randf_range(-0.6, 0.6)) * randf_range(6.0, 14.0), Color(1.0, 0.85, 0.4), 2.0)


# ---- מקלען מת: הגוף נזרק קדימה ונופל אחורה מאחורי השקים, הקסדה עפה, החצובה + המקלע נופלים קדימה
#      על השקים ויורים צרור אחרון לשמיים (GUNNER_BURST). השקים נשארים במקום. ----
func _draw_gunner_dead() -> void:
	var t := _dead_t
	var sk: Color = skin
	var army: Color = shirt
	var base := Transform2D(0.0, Vector2(_dir * sc, sc), 0.0, Vector2.ZERO)
	DrawBatch.set_transform_matrix(self, base)
	var pool := clampf((t - 0.6) / 2.2, 0.0, 1.0)   # שלולית דם מתחת לגוף
	if pool > 0.0:
		DrawBatch.ellipse(self, Vector2(-20.0, 0.5), 5.0 + 17.0 * pool, 2.0 + 1.6 * pool, Color(0.3, 0.02, 0.02, 0.6))
	for p in [Vector2(14, -5), Vector2(25, -5), Vector2(19, -13)]:   # שקי חול (לא זזים)
		Art.oval(self, p, 7.0, 5.0, Color("8a7a58"), 0.0, Art.OUTLINE, 1.0)
	# רגליים כורעות (נשארות), ואז הגוף: קפיצה קדימה מהפגיעה ונפילה אחורה סביב המותן
	var hip := Vector2(-6.0, -17.0)
	Art.limb(self, PackedVector2Array([Vector2(-8, -18), Vector2(2, -10), Vector2(-4, 0)]), 6.0, pants)
	var fall := _ease01((t - 0.1) / 0.5)
	var a := 0.18 * sin(clampf(t / 0.14, 0.0, 1.0) * PI) - 1.5 * fall + 0.1 * sin(clampf((t - 0.6) / 0.22, 0.0, 1.0) * PI)   # + קפיצה קטנה כשנוחת
	DrawBatch.set_transform_matrix(self, base * Transform2D(a, hip) * Transform2D(0.0, -hip))
	Art.fill(self, PackedVector2Array([Vector2(-12, -18), Vector2(2, -18), Vector2(3, -42), Vector2(-9, -44)]), army, Art.OUTLINE, 1.2)
	var arm := _ease01((t - 0.2) / 0.5)   # היד נשמטת
	Art.limb(self, PackedVector2Array([Vector2(-2, -38), Vector2(6, -32).lerp(Vector2(4, -26), arm), Vector2(12, -34).lerp(Vector2(10, -20), arm)]), 4.0, sk)
	var hc := Vector2(-2, -51)
	Art.oval(self, hc, 7.0, 7.5, sk, 0.0, Art.OUTLINE, 1.2)
	DrawBatch.line(self, hc + Vector2(2, 4), hc + Vector2(6, 5), Color(0.2, 0.05, 0.05), 1.2)
	if t < 0.25:
		Art.glow(self, hc + Vector2(4, 1), 3.5 * (1.0 - t / 0.25), Color(1.0, 0.2, 0.1, 0.7))   # העין כבה
	# הקסדה עפה מהראש ונוחתת מאחור
	var hm := Color("3a4a2e")
	var ht := t - 0.08
	DrawBatch.set_transform_matrix(self, base)
	var hp := Vector2(-2, -60)
	var hr := 0.0
	if ht > 0.0:
		var tl := minf(ht, 0.62)
		hp = Vector2(-2.0 - 70.0 * tl, -60.0 - 230.0 * tl + 0.5 * 760.0 * tl * tl)
		hp.y = minf(hp.y, -8.0)
		hr = -7.0 * tl
	else:
		DrawBatch.set_transform_matrix(self, base * Transform2D(a, hip) * Transform2D(0.0, -hip))
		hp = hc + Vector2(0, -9)
	Art.fill(self, PackedVector2Array([hp + Vector2(-8, 8).rotated(hr), hp + Vector2(-6, 1).rotated(hr), hp + Vector2(2, -1).rotated(hr), hp + Vector2(8, 4).rotated(hr), hp + Vector2(9, 8).rotated(hr)]), hm, Art.OUTLINE, 1.0)
	# חצובה + מקלע: מתהפכים קדימה סביב הרגל הקדמית של החצובה (19, 0), ומקפצים פעם אחת
	var tip := 1.25 * _ease01((t - 0.12) / 0.5) - 0.12 * sin(clampf((t - 0.62) / 0.2, 0.0, 1.0) * PI)
	var foot := Vector2(19, 0)
	DrawBatch.set_transform_matrix(self, base * Transform2D(tip, foot) * Transform2D(0.0, -foot))
	DrawBatch.line(self, Vector2(10, -32), Vector2(3, 0), Color("2a2a2e"), 1.8)
	DrawBatch.line(self, Vector2(10, -32), Vector2(19, 0), Color("2a2a2e"), 1.8)
	var piv := Vector2(10, -34)
	var dv := Vector2(cos(_gun_ang) * float(_dir), sin(_gun_ang)).normalized()   # הכיוון האחרון של הקנה (מקומי)
	dv = dv.lerp(Vector2(0.6, -0.8), _ease01(t / 0.3)).normalized()   # הקנה מתרומם לשמיים
	var nv := dv.rotated(PI / 2.0)
	DrawBatch.colored_polygon(self, PackedVector2Array([piv - nv * 4.0 - dv * 10.0, piv - nv * 4.0 + dv * 12.0, piv + nv * 4.0 + dv * 12.0, piv + nv * 4.0 - dv * 10.0]), Color("26282c"))
	DrawBatch.line(self, piv + dv * 12.0, piv + dv * 34.0, Color("3a3c40"), 4.0)
	var sp := piv + dv * 8.0
	DrawBatch.colored_polygon(self, PackedVector2Array([sp - nv * 18.0, sp - nv * 18.0 + dv * 3.0, sp + nv * 12.0 + dv * 3.0, sp + nv * 12.0]), Color("5d6168"))
	var muzzle := piv + dv * 34.0
	for bt in GUNNER_BURST:   # הבזקי הצרור האחרון + קו נותב
		var d := t - float(bt)
		if d >= 0.0 and d < 0.06:
			for i in 4:
				DrawBatch.line(self, muzzle, muzzle + dv.rotated(randf_range(-0.6, 0.6)) * randf_range(6.0, 14.0), Color(1.0, 0.85, 0.4), 2.0)
			DrawBatch.line(self, muzzle + dv * 20.0, muzzle + dv.rotated(randf_range(-0.08, 0.08)) * 160.0, Color(1.0, 0.9, 0.5, 0.7), 1.2)
	DrawBatch.set_transform_matrix(self, Transform2D.IDENTITY)


static func _ease01(x: float) -> float:
	var k := clampf(x, 0.0, 1.0)
	return k * k * (3.0 - 2.0 * k)


# ---- פרטים על הגוף: ריקבון, חולצה קרועה, תפרים, רצועת בשר תלויה ----
func _details(sh: Vector2, hip: Vector2, sk: Color) -> void:
	var mid := sh.lerp(hip, 0.5)
	if _det[0]:   # כתמי ריקבון
		var p := mid + Vector2(_det[3], _det[4])
		Art.oval(self, p, 2.6, 2.0, Color(0.25, 0.3, 0.12, 0.75), 0.4, Art.NONE)
		Art.oval(self, p + Vector2(0.5, 0.3), 1.2, 0.9, Color(0.35, 0.1, 0.08, 0.8), 0.0, Art.NONE)
	# שוליים קרועים של החולצה
	var hem := PackedVector2Array()
	for i in 7:
		hem.append(hip + Vector2(-7.0 + float(i) * 2.3, -1.5 + (2.0 if i % 2 == 0 else -0.5)))
	DrawBatch.polyline(self, hem, Color(0, 0, 0, 0.45), 0.9, true)
	if _det[1]:   # תפרים על החזה
		var a := sh + Vector2(-5.0, 4.0)
		var b := sh + Vector2(3.0, 9.0)
		DrawBatch.line(self, a, b, Color(0.12, 0.05, 0.05, 0.8), 0.8, true)
		for i in 4:
			var q := a.lerp(b, (float(i) + 0.5) / 4.0)
			DrawBatch.line(self, q + Vector2(-0.8, 1.0), q + Vector2(0.8, -1.0), Color(0.8, 0.75, 0.6, 0.8), 0.6, true)
	if _det[2]:   # רצועת בשר תלויה
		var t0 := mid + Vector2(5.0, 2.0)
		DrawBatch.colored_polygon(self, PackedVector2Array([t0, t0 + Vector2(2.0, 0.0), t0 + Vector2(1.5, 6.0 + sin(_time * 4.0)), t0 + Vector2(0.5, 5.0)]), Color("6a1414"))
	# צל בצד הגוף (נפח)
	DrawBatch.line(self, sh + Vector2(-6.5, 3.0), hip + Vector2(-6.0, -2.0), Color(0, 0, 0, 0.22), 2.0, true)


# ---- טקסט קופץ (HEADSHOT!) ----
class HitText extends Node2D:
	const FS := 32
	var text := ""
	var color := Color.WHITE
	var size := 18
	var pop := false       # מספר נזק: "קופץ" בהתחלה
	var life := 1.1
	var t := 0.0
	var _drift := 0.0

	func _ready() -> void:
		z_index = 30
		_drift = randf_range(-12.0, 12.0)

	func _process(delta: float) -> void:
		t += delta
		position += Vector2(_drift, -55.0 + t * 25.0) * delta   # צף למעלה ומאט
		modulate.a = clampf((life - t) / 0.4, 0.0, 1.0)
		if t > life:
			queue_free()
		queue_redraw()

	func _draw() -> void:
		var f := ThemeDB.fallback_font
		var k := 1.0
		if pop:
			k = 1.0 + 0.6 * clampf(1.0 - t / 0.15, 0.0, 1.0)
		# גודל פונט אחד קבוע (FS) ומגדילים בסקייל: כל גודל פונט חדש = רסטור אותיות מחדש = גמגום
		k *= float(size) / float(FS)
		DrawBatch.set_transform(self, Vector2.ZERO, 0.0, Vector2(k, k))
		var w := f.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, FS).x
		var pos := Vector2(-w / 2.0, 0.0)
		DrawBatch.string_outline(self, f, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, FS, 7, Color(0, 0, 0, 0.85))
		DrawBatch.string(self, f, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, FS, color)


# ---- כדור חשמל של המוליך: קופץ על המים ומחשמל את השלולית ----
class Orb extends Node2D:
	var velocity := Vector2.ZERO
	var floor_y := 630.0
	var bounces := 0
	var zap_t := -1.0                  # > 0 = השלולית מחושמלת
	var radius := 120.0
	var _hurt := false

	func _ready() -> void:
		z_index = 9

	func _physics_process(delta: float) -> void:
		if zap_t >= 0.0:
			zap_t -= delta
			var p := get_tree().get_first_node_in_group("player")
			if p != null and not _hurt and p.global_position.y > floor_y - 6.0 and absf(p.global_position.x - global_position.x) < radius:
				_hurt = true
				p.hurt(1, Vector2.UP)
			if zap_t <= 0.0:
				queue_free()
			queue_redraw()
			return
		velocity.y += 900.0 * delta
		global_position += velocity * delta
		if global_position.y >= floor_y - 6.0 and velocity.y > 0.0:
			global_position.y = floor_y - 6.0
			bounces += 1
			if bounces >= 2:
				zap_t = 1.2
				preload("res://sfx.gd").play("zap", global_position, 0.0, 0.15, 3)
			else:
				velocity = Vector2(velocity.x * 0.7, -velocity.y * 0.5)
		queue_redraw()

	func _draw() -> void:
		if zap_t >= 0.0:   # מים מחושמלים
			var a := clampf(zap_t, 0.0, 1.0)
			DrawBatch.set_transform(self, Vector2(0, 4), 0.0, Vector2(1.0, 0.12))
			DrawBatch.circle(self, Vector2.ZERO, radius, Color(0.4, 0.7, 1.0, 0.18 * a))
			DrawBatch.set_transform_matrix(self, Transform2D.IDENTITY)
			for i in 5:
				var x0 := randf_range(-radius, radius)
				var pts := PackedVector2Array([Vector2(x0, 2)])
				for k in 4:
					pts.append(pts[-1] + Vector2(randf_range(4, 12) * signf(randf() - 0.5), randf_range(-8, 2)))
				DrawBatch.polyline(self, pts, Color(0.75, 0.9, 1.0, a), 1.4)
			return
		DrawBatch.circle(self, Vector2.ZERO, 12.0, Color(0.3, 0.6, 1.0, 0.25))
		DrawBatch.circle(self, Vector2.ZERO, 6.0, Color(0.7, 0.9, 1.0, 0.9))
		for i in 3:
			DrawBatch.line(self, Vector2.ZERO, Vector2.from_angle(randf() * TAU) * randf_range(8, 14), Color(0.85, 0.95, 1.0), 1.2)


# ---- כדור של רובוט זומבי ----
class EnemyShot extends Node2D:
	var velocity := Vector2.ZERO
	var life := 1.6

	func _ready() -> void:
		z_index = 9

	func _physics_process(delta: float) -> void:
		life -= delta
		if life <= 0.0:
			queue_free()
			return
		var to := global_position + velocity * delta
		if not get_world_2d().direct_space_state.intersect_ray(PhysicsRayQueryParameters2D.create(global_position, to, 1)).is_empty():
			queue_free()
			return
		var p := get_tree().get_first_node_in_group("player")
		if p != null and not p.dead:
			var r: Rect2 = p.body_rect()
			for i in 3:
				if r.has_point(global_position.lerp(to, float(i) / 2.0)):
					p.hurt(1, Vector2(signf(velocity.x), 0.0))
					queue_free()
					return
		global_position = to
		rotation = velocity.angle()
		queue_redraw()

	func _draw() -> void:
		DrawBatch.line(self, Vector2(-20, 0), Vector2(0, 0), Color(1.0, 0.55, 0.2, 0.45), 2.0)
		DrawBatch.line(self, Vector2(-7, 0), Vector2(2, 0), Color(1.0, 0.9, 0.6), 2.2)
