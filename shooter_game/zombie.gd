extends CharacterBody2D
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
const DEATH_FLING := 0.5     # כמה רחוק הגופה עפה מהפגיעה האחרונה (1 = כמו פעם)
const BLOOD_AMOUNT := 0.5    # כמות הדם (1 = כמו פעם)
const LegScript := preload("res://severed_leg.gd")
const AcidScript := preload("res://acid.gd")
const FireScript := preload("res://fire.gd")
const PickupScript := preload("res://pickup.gd")
const DebrisScript := preload("res://debris.gd")
const Particles := preload("res://particles.gd")
const GrenadeScript := preload("res://grenade.gd")
const Boom := preload("res://explosion.gd")
const Brain := preload("res://ai/zombie_brain.gd")             # המוח (טקטיקה, תורות, איגוף) - ai/zombie_brain.gd
const Registry := preload("res://enemies/zombie_registry.gd")  # סוגי זומבים חדשים (20+) - enemies/types/*.gd
# סוגים שהמוח מזיז (לשאר יש לוגיקת תנועה משלהם)
const BRAIN_KINDS := [0, 1, 2, 4, 9, 14, 16]
const DOG_TEX := preload("res://sprites/dog.png")   # ספרייט כלב זומבי

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
var type_mod = null              # enemies/types/*.gd (סוגים 20+)
var _drop_t := 0.0               # יורד דרך קומה (one-way)
var _stagger_t := 0.0
var _decoy_id := 0               # איזה עותק רפאים בדקנו
var _decoy_fooled := true
var _mod_boss := false           # סוג חדש שהוא בוס (stats()["boss"])

var sc := 1.0      # גודל
var wf := 1.0      # רוחב
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
var _wounds: Array[Vector2] = []
# רגל ביד
var _carry: Node2D = null
var _pick_cd := 0.0
var _throw_cd := 0.0
var _throw_anim := 0.0
# אחרי המוות
var _spin := 0.0
var _rag: RefCounted = null      # גופה רכה (effects/ragdoll.gd). null = גופה "קשיחה" רגילה
var _last_hit := Vector2.ZERO    # איפה הפגיעה האחרונה (קובע איך הגופה נופלת)
var _last_boom := false
var _angle := 0.0
var _dead_t := 0.0
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
	else:
		k = KINDS[clampi(kind, 0, KINDS.size() - 1)]
	hp = k.hp + (100 * (mini(Game.level, 5) - 1) if is_boss() else 0)   # שלבים מאוחרים: הבוס לא "ספוג" יותר - הוא חכם יותר
	max_hp = hp
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


func _physics_process(delta: float) -> void:
	_time += delta
	_flash -= delta
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
		if kind != RAT and kind != HAND and kind != MECH and (type_mod == null or type_mod.can_groan()) and Art.on_screen(self, global_position):
			Sfx.play("growl" if kind == DOG or kind == HOUND else ("roar" if is_boss() else "groan"), global_position, 0.0 if not is_boss() else 3.0, 0.08, 3, _vp)
	# רחוק מאוד מהשחקן: הזומבי "ישן" (חוסך המון ביצועים)
	if player != null and absf(player.global_position.x - global_position.x) > 1400.0 and is_on_floor() and _carry == null:
		return
	if _drop_t > 0.0:   # ירד דרך קומה: חוזר להתנגש בקומות
		_drop_t -= delta
		if _drop_t <= 0.0:
			collision_mask |= 16
	# סוג חדש עם תנועה מיוחדת (מטפס / זוחל על קירות / קופץ...)
	if type_mod != null and type_mod.physics(player, delta):
		_maybe_redraw()
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
	if _cover_state != 0:
		target_speed = _cover_process(delta, player)
	elif player != null and not player.dead and (global_position.distance_to(player.global_position) < chase_range * (0.45 if Game.player_dark and not is_boss() else 1.0) or _alert_t > 0.0):   # בחושך רואים פחות
		_chasing = true
		var tp: Node = _target_for_brain(player)   # DECOY ECHO: אולי הולך אחרי עותק הרפאים
		_dir = signf(tp.global_position.x - global_position.x)
		if not _noticed:   # ראה את השחקן: זעקה
			_noticed = true
			Game.story.emit("notice", {"z": self})
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
		if brain != null:
			var bs: float = brain.steer(self, tp, d, delta, target_speed)
			if brain.steer_movement:
				target_speed = bs
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
			tp.hurt(damage + (1 if charging else 0), Vector2(_dir * (2.0 if charging else 1.0), 0.0))
			if brain != null:
				brain.on_bite(self)
			if type_mod != null:
				type_mod.on_bite(player)
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
		velocity.x = move_toward(velocity.x, _dir * target_speed * _speed_mul, 600.0 * delta)
	move_and_slide()

	# נתקע בקיר: קופץ (או מסתובב אם הוא סתם מטייל)
	if is_on_wall() and is_on_floor() and not _one_leg and kind != MECH:
		if _chasing or _cover_state == 1:
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
	_burn_t = maxf(_burn_t, t)
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


# DECOY ECHO (abilities/types/decoy.gd): זומבים שהמוח מזיז הולכים אחרי עותק הרפאים אם הוא קרוב.
# משלב 8 חלק מהם "מזהים" את הטריק (adaptation_level)
func _target_for_brain(player: Node) -> Node:
	if brain == null or not brain.steer_movement:
		return player
	var dc := get_tree().get_first_node_in_group("decoys")
	if dc == null or dc.dead or dc.global_position.distance_to(global_position) > 560.0:
		return player
	if dc.get_instance_id() != _decoy_id:
		_decoy_id = dc.get_instance_id()
		_decoy_fooled = randf() > float(brain.p.get("adaptation_level", 0.0)) * 0.35
	return dc if _decoy_fooled else player


# ---- קומות (one-way, שכבה 16): קפיצה למעלה לקומה / ירידה דרכה ----
func hop_up(height: float) -> void:
	if not is_on_floor() or dead:
		return
	velocity.y = -sqrt(2.0 * gravity * maxf(height, 40.0))
	velocity.x = _dir * maxf(absf(velocity.x), 60.0)


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
		_popup("NO EFFECT", Color("c0c0c8"), 14, -120.0)
		Sfx.play("shield", hit_pos)
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
	elif zone == "head" and float(src.get("head_mult", 1.0)) < 1.0:   # נשק אוטומטי: ירייה בראש לא הורגת מיד
		dmg = maxi(1, int(round(float(dmg) * float(src.head_mult))))
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
	Particles.burst(get_parent(), hit_pos, "hit", dir if dir != Vector2.ZERO else Vector2.UP, int(10.0 * BLOOD_AMOUNT))
	# PERFECT: פגיעה בדיוק במרכז הראש
	var perfect := false
	if zone == "head":
		var hc := global_position + Vector2(_dir * 4.0 * wf * sc, -50.0 * sc)
		perfect = hit_pos.distance_to(hc) < 6.0 * sc
		if perfect:
			dmg *= 2
	_last_info = {"zone": zone, "source": source, "perfect": perfect, "bullet": src.get("bullet", 0), "blast": src.get("blast", 0),
		"hidden": _cover_state == 2}
	Game.on_zombie_hit(_last_info)
	Sfx.play("headshot" if zone == "head" else "hit", hit_pos, -4.0, 0.15, 4)
	_last_hit = hit_pos
	_last_boom = explosive
	hp -= dmg
	Game.story.emit("zhit", {"z": self, "zone": zone, "source": source, "was_lying": was_lying})
	if hp > 0 and (source == "bullet" or source == "melee" or source == "taser"):
		_voice("zhit", 0.85, 3.0)
	_damage_number(dmg, zone)

	if zone == "head":
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
	if hp <= 0:
		_die(dir)
	else:
		if on_ceiling:   # נפגע על התקרה: נופל
			_drop_down()
		velocity.x += dir.x * (110.0 + (float(src.get("knockback", 0.0)) if not is_boss() else 0.0))   # הדיפה לפי הנשק
		# לפעמים הוא בורח ומתחבא מאחורי מכונית / מחסום (אם יש אחד קרוב)
		if _cover_state == 0 and not was_lying and not is_boss() and randf() < cover_chance:
			_try_cover(get_tree().get_first_node_in_group("player"))


# מספר הנזק שקופץ מעל הזומבי וצף למעלה
func _damage_number(dmg: int, zone: String) -> void:
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
	Game.on_leg_severed()
	_hop_t = 0.4
	var hip := global_position + Vector2(-_dir * 2.0 * wf, -22.0 * sc)
	_spray_blood(hip, dir, 14, 300.0)
	var leg = LegScript.new()
	get_parent().add_child(leg)
	leg.setup(hip + Vector2(0.0, 8.0 * sc), Vector2(dir.x * 160.0 + randf_range(-40.0, 40.0), -200.0), pants, skin, shoe, sc)
	_popup("LEG!", Color("ff8a5a"), 16, -40.0)


func _die(dir: Vector2) -> void:
	dead = true
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
		Game.on_zombie_killed(kind, _last_info)
		queue_free()
		return
	remove_from_group("zombies")
	if _carry != null and is_instance_valid(_carry):
		_carry.drop(Vector2(randf_range(-80.0, 80.0), -150.0))
	_carry = null
	collision_layer = 0   # קליעים כבר לא פוגעים בגופה
	var r := _shape.shape as RectangleShape2D
	r.size = Vector2(18, 18) * sc   # גופה = ריבוע קטן שמתגלגל
	_shape.position = Vector2(0.0, -9.0 * sc)
	velocity = (Vector2(dir.x, minf(dir.y, 0.0)).normalized() * randf_range(420.0, 620.0) / sqrt(sc * wf) + Vector2(0.0, -260.0)) * DEATH_FLING
	if kind == JETPACK:   # מתרסק בנקודה אקראית בתוך המסך שרואים
		var vp := get_viewport()
		var view := vp.get_canvas_transform().affine_inverse() * vp.get_visible_rect()
		var tx := randf_range(view.position.x + 120.0, view.end.x - 120.0)
		var vy0 := -randf_range(120.0, 260.0)
		var h := maxf(_ground_y - global_position.y, 10.0)
		var t_fall := (-vy0 + sqrt(vy0 * vy0 + 2.0 * 650.0 * h)) / 650.0
		velocity = Vector2(clampf((tx - global_position.x) / t_fall, -900.0, 900.0), vy0)
	_spin = randf_range(8.0, 14.0) * signf(velocity.x if velocity.x != 0.0 else 1.0)
	if _ragdoll_kind():   # זומבי אנושי: גופה רכה שנופלת לפי המכה
		_rag = RagdollScript.new()
		_rag.setup(self, velocity, dir, _last_hit if _last_hit != Vector2.ZERO else global_position + Vector2(0, -30) * sc, _last_boom)
	_spray_blood(global_position + Vector2(0, -30) * sc, dir, 14, 380.0)
	if is_instance_valid(_fire):
		_fire.queue_free()
	# ניקוד + בונוסים
	var bonuses: Array = Game.on_zombie_killed(kind, _last_info)
	for i in bonuses.size():
		var b: Array = bonuses[i]
		var txt: String = b[0] + (" +%d" % b[1] if int(b[1]) > 0 else "")
		_popup(txt, Color("ffd34a"), 15, -96.0 - float(i) * 17.0)
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
		_:
			if randf() < 0.1:
				_drop(PickupScript.AMMO)


func _drop(pk: int) -> void:
	var p = PickupScript.new()
	p.kind = pk
	p.boost = randi() % 5
	get_parent().add_child.call_deferred(p)
	p.setup.call_deferred(global_position + Vector2(0, -40), Vector2(randf_range(-120, 120), -280))


func _dead_process(delta: float) -> void:
	_dead_t += delta
	if _dead_t > corpse_time:
		if _rag != null:
			_rag.release()
		queue_free()
		return
	modulate.a = clampf(corpse_time - _dead_t, 0.0, 1.0)
	if _rag != null:   # גופה רכה: מדמה עד שהיא נרגעת, ואז רק מצוירת
		if _rag.step(delta) and Art.on_screen(self, global_position, 400.0):
			queue_redraw()
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
	if is_on_floor():
		velocity.x = move_toward(velocity.x, 0.0, 900.0 * delta)
		_spin = move_toward(_spin, 0.0, 30.0 * delta)
		var rest := PI / 2.0 if fposmod(_angle, TAU) < PI else PI * 1.5
		if kind == DOG or kind == HOUND:
			rest = 0.0   # כלב: נוחת על הבטן ומתמוטט (לא על הגב)
		_angle = lerp_angle(_angle, rest, 8.0 * delta)
	if is_on_wall():
		velocity.x *= -0.3
	_angle += _spin * delta
	_maybe_redraw()


func _spray_blood(pos: Vector2, dir: Vector2, n: int, power: float) -> void:
	for i in maxi(1, int(round(float(n) * BLOOD_AMOUNT))):
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
# אילו זומבים נופלים כגופה רכה (לא: חיות, יד, רובוט, ג'טפאק שמתרסק, נפוח שמתפוצץ, תותחן)
func _ragdoll_kind() -> bool:
	if kind in [RAT, HAND, MECH, DOG, HOUND, JETPACK, BLOATER, GUNNER]:
		return false
	return type_mod == null or bool(type_mod.stats().get("ragdoll", true))


func _draw() -> void:
	if dead and _rag != null:
		_rag.draw(self)
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
	if not dead and not _lying() and is_on_floor():
		Art.ground_shadow(self, Vector2(0.0, 0.0), 14.0 * wf * sc)
	if dead:
		var outer := Transform2D(_angle, Vector2(0.0, -9.0 * sc))
		draw_set_transform_matrix(outer * Transform2D(0.0, s, 0.0, Vector2(0.0, 28.0 * sc)))
	elif _lying():
		# שוכב, או קם לאט (מסתובב מהשכיבה לעמידה)
		var k := 1.0 if dormant else clampf(_rise_t / RISE_TIME, 0.0, 1.0)
		k = k * k * (3.0 - 2.0 * k)
		var outer := Transform2D(PI / 2.0 * _lie_side * k, Vector2(0.0, lerpf(-28.0, -9.0, k) * sc))
		draw_set_transform_matrix(outer * Transform2D(0.0, s, 0.0, Vector2(0.0, 28.0 * sc)))
	elif kind == JETPACK:   # עף עקום
		draw_set_transform_matrix(Transform2D(_tilt, Vector2(0.0, -30.0 * sc)) * Transform2D(0.0, s, 0.0, Vector2(0.0, 30.0 * sc)))
	elif kind == IMP and _thrown:   # קטן שנזרק: מסתובב באוויר
		draw_set_transform_matrix(Transform2D(_spin_a, Vector2(0.0, -28.0 * sc)) * Transform2D(0.0, s, 0.0, Vector2(0.0, 28.0 * sc)))
	else:
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(s.x, -s.y) if on_ceiling else s)
	_draw_body()
	draw_set_transform_matrix(Transform2D.IDENTITY)


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
	var bob := absf(sin(p)) * 1.5
	var ck := 0.0 if dead or _lying() else _crouch_k   # התכופפות
	var hip := Vector2(0.0, -24.0 - bob * 0.5 + 11.0 * ck)
	var sh := Vector2(lean + 3.0 * ck, -41.0 - bob * 0.5 + (1.0 if _big() else 0.0) + 12.0 * ck)
	var head := sh + Vector2(2.5 + lean * 0.35, -9.0)
	if _big():
		head = sh + Vector2(3.5, -7.5)

	# כפות רגליים
	var stride := 7.0 if kind == RUNNER and _chasing else 5.0
	var lift := 4.0 if kind == RUNNER else 2.5
	var f1 := Vector2(sin(p) * stride + 1.0, -maxf(0.0, cos(p)) * lift)
	var f2 := Vector2(sin(p + PI) * stride - 1.0, -maxf(0.0, cos(p + PI)) * lift)
	if _one_leg:
		f1 = Vector2(1.5, -6.0) if air else Vector2(1.0, 0.0)
	elif air:
		f1 = Vector2(5.0, -7.0)
		f2 = Vector2(-4.0, -4.0)
	f1.x += 5.0 * ck
	f2.x -= 5.0 * ck

	# ---- יד אחורית ----
	var reach := sin(_time * 3.0) * 1.5
	var bs := sh + Vector2(-2.0, 2.0)
	var fs := sh + Vector2(2.5, 2.0)
	var back_hand := bs + Vector2(16.0, 1.0 - reach)
	var front_hand := fs + Vector2(17.0, 3.0 + reach)
	if (kind == RUNNER and _chasing) or _cover_state == 1:   # רץ (או בורח) - ידיים מתנופפות
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
	if kind == HURLER and (_imp != null or _hurl_wind > 0.0):   # מחזיק זומבי קטן מעל הראש
		front_hand = head + Vector2(7.0, -11.0)
		back_hand = head + Vector2(-6.0, -11.0)
	if dead or _lying():
		back_hand = bs + Vector2(-4.0, 15.0)
		front_hand = fs + Vector2(5.0, 15.0)
	_arm(bs, back_hand, Art.shade(sk, 0.2), Art.shade(sh_col, 0.2))

	# ---- רגליים ----
	if not _one_leg:
		_leg(hip + Vector2(-2.0, 0.0), f2, Art.shade(pa, 0.25), Art.shade(sk, 0.2), Art.shade(shoe_col, 0.2))
	_leg(hip + Vector2(2.0, 0.0), f1, pa, sk, shoe_col)
	if _one_leg:   # גדם
		Art.limb(self, PackedVector2Array([hip + Vector2(-2.0, 0.0), hip + Vector2(-3.0, 6.0)]), 7.0, Art.shade(pa, 0.25))
		var st := hip + Vector2(-3.0, 7.5)
		Art.fill(self, PackedVector2Array([st + Vector2(-4.0, -0.5), st + Vector2(-2.0, 2.5), st + Vector2(0.0, 1.0),
			st + Vector2(2.0, 3.0), st + Vector2(4.0, -0.5)]), Color("8a0d0d"), Art.OUTLINE, 1.0)
		Art.limb(self, PackedVector2Array([st + Vector2(0.5, 0.0), st + Vector2(0.5, 3.5)]), 1.6, Color("e8dcc4"), Art.NONE)   # עצם

	# ---- גוף ----
	match kind:
		BRUTE, BOSS, CONDUCTOR:
			_torso_brute(sh, hip, sk, sh_col, pa)
		RUNNER, SCREAMER:
			_torso_runner(sh, hip, sk, sh_col)
		_:
			_torso_walker(sh, hip, sk, sh_col)
	if kind == DRUNK and not dead:   # חליפה קרועה: חולצה לבנה ועניבה אדומה
		Art.fill(self, PackedVector2Array([sh + Vector2(-1, 1), sh + Vector2(5, 1), sh + Vector2(2, 12)]), Color(0.85, 0.82, 0.75), Art.NONE)
		draw_line(sh + Vector2(2, 2), sh + Vector2(1, 15), Color("8a1a1a"), 2.4)
		draw_line(sh + Vector2(-5, 8), sh + Vector2(-2, 14), Color(0, 0, 0, 0.5), 1.0)
		draw_line(sh + Vector2(6, 12), sh + Vector2(3, 18), Color(0, 0, 0, 0.5), 1.0)
	if kind == JETPACK:   # ג'טפאק על הגב + להבות
		var pk := sh + Vector2(-10.0, 7.0)
		var jc := Color.WHITE if _flash > 0.0 else Color("6a6e74")
		Art.fill_shaded(self, PackedVector2Array([pk + Vector2(-5, -10), pk + Vector2(4, -10), pk + Vector2(4, 12), pk + Vector2(-5, 12)]), jc, 0.2, 0.3, Art.OUTLINE, 1.2)
		draw_rect(Rect2(pk + Vector2(-4, -6), Vector2(7, 3)), Color("c8a020"))
		for nz in [-3.0, 2.0]:
			draw_rect(Rect2(pk + Vector2(nz - 1.5, 12), Vector2(3.5, 4)), Color("2a2a2e"))
			if not dead or _crashing:
				var fl := 7.0 + randf() * 9.0
				draw_colored_polygon(PackedVector2Array([pk + Vector2(nz - 2.0, 16), pk + Vector2(nz + 2.0, 16), pk + Vector2(nz, 16 + fl)]), Color(1.0, 0.5, 0.1, 0.9))
				draw_colored_polygon(PackedVector2Array([pk + Vector2(nz - 1.0, 16), pk + Vector2(nz + 1.0, 16), pk + Vector2(nz, 16 + fl * 0.55)]), Color(1.0, 0.95, 0.6))
	if kind == CONDUCTOR and not dead and _transformer > 0:   # שנאי על הגב
		var tb := sh + Vector2(-12.0, 4.0)
		Art.fill_shaded(self, PackedVector2Array([tb + Vector2(-6, -8), tb + Vector2(5, -8), tb + Vector2(5, 14), tb + Vector2(-6, 14)]), Color("3a4048"), 0.2, 0.3, Art.OUTLINE, 1.2)
		for i in 3:
			draw_line(tb + Vector2(-6, -4 + i * 6), tb + Vector2(5, -4 + i * 6), Color("20242a"), 1.0)
		draw_line(tb + Vector2(0, -8), sh + Vector2(2, -3), Color("1a1a1a"), 1.4, true)   # כבלים
		draw_line(tb + Vector2(4, -6), head + Vector2(-2, 2), Color("1a1a1a"), 1.2, true)
		var gl := 0.5 + 0.5 * sin(_time * 12.0)
		Art.glow(self, tb + Vector2(0, -10), 7.0, Color(0.5, 0.75, 1.0, 0.5 * gl))
		if randf() < 0.3:
			var sp := tb + Vector2(randf_range(-6, 5), -9)
			draw_line(sp, sp + Vector2(randf_range(-6, 6), -randf_range(3, 8)), Color(0.8, 0.9, 1.0), 1.0)
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
			draw_line(c + Vector2.from_angle(a) * r * 0.3, c + Vector2.from_angle(a + 0.4) * r * 0.85, Color(0.4, 0.15, 0.2, 0.6), 1.0, true)
		Art.glow(self, c, r * 1.4, Color(0.7, 1.0, 0.3, 0.12 + 0.2 * _swell))
	if kind in [WALKER, RUNNER, BRUTE, SPITTER, SCREAMER, BLOATER, CRAWLER, COP, DRUNK, HURLER, IMP, JETPACK, CONDUCTOR, BOSS] and not dead:
		_details(sh, hip, sk)
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
	_arm(fs, front_hand, sk, sh_col)
	if (kind == DRUNK or kind == JETPACK) and not dead:   # אקדח / תת-מקלע
		var gl := 7.0 if kind == DRUNK else 11.0
		draw_rect(Rect2(front_hand + Vector2(-1.0, -2.5), Vector2(gl, 3.2)), Color("1a1a1e"))
		draw_rect(Rect2(front_hand + Vector2(-1.0, 0.5), Vector2(2.5, 4.0)), Color("1a1a1e"))
		if _muzzle_t > 0.0:
			draw_circle(front_hand + Vector2(gl + 2.0, -1.0), 3.0, Color(1.0, 0.85, 0.4))
	if kind == IMP and not dead:   # כידון
		draw_line(front_hand + Vector2(-2.0, 1.0), front_hand + Vector2(3.0, 0.0), Color("3a2a1a"), 2.5)
		draw_colored_polygon(PackedVector2Array([front_hand + Vector2(3.0, -1.2), front_hand + Vector2(17.0, -0.5), front_hand + Vector2(3.0, 1.2)]), Color("c8ccd4"))
	if kind == COP and not dead:   # מגן משטרה שקוף
		var sx := sh.x + 12.0
		var shield := PackedVector2Array([Vector2(sx, sh.y - 12.0), Vector2(sx + 5.0, sh.y - 13.0), Vector2(sx + 5.0, hip.y + 8.0), Vector2(sx, hip.y + 9.0)])
		Art.fill(self, shield, Color(0.6, 0.75, 0.9, 0.45), Art.OUTLINE, 1.2)
		draw_line(Vector2(sx + 1.5, sh.y - 9.0), Vector2(sx + 1.5, hip.y + 4.0), Color(1, 1, 1, 0.35), 1.0)
		draw_rect(Rect2(sx, sh.y + 2.0, 5.0, 3.0), Color(0.9, 0.9, 0.95, 0.7))
	if kind == SCREAMER and _scream_t > 0.0:   # גלי קול
		for i in 3:
			var k := fmod(1.2 - _scream_t + float(i) * 0.3, 0.9) / 0.9
			draw_arc(head + Vector2(6, 2), 8.0 + k * 40.0, -0.9, 0.9, 12, Color(0.9, 0.9, 1.0, 0.7 * (1.0 - k)), 2.0, true)


# ביצועים: האנימציה של הגוף מצוירת מחדש כל פריים שני (התזוזה עצמה נשארת חלקה),
# וזומבים שלא על המסך לא מצוירים בכלל
# כשיש הרבה זומבים על המסך - כל פריים שלישי
var _redraw_tick := randi() % 3
static var _vis_frame := -1
static var _vis_count := 0
static var _vis_prev := 0


func _maybe_redraw() -> void:
	var fr := Engine.get_physics_frames()
	if fr != _vis_frame:   # סופרים כמה זומבים על המסך בכל פריים
		_vis_prev = _vis_count
		_vis_count = 0
		_vis_frame = fr
	if not Art.on_screen(self, global_position):
		return
	_vis_count += 1
	var every := 2 if _vis_prev <= 3 else 3
	_redraw_tick += 1
	if _redraw_tick % every == 0 or _flash > 0.0:
		queue_redraw()


func _big() -> bool:
	return kind == BRUTE or kind == BOSS


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
	draw_line(Transform2D(rot, c) * Vector2(-2, -18), Transform2D(rot, c) * Vector2(2, -9), Color(0.8, 0.85, 0.9, 0.35), 0.6, true)
	draw_line(Transform2D(rot, c) * Vector2(1, 2), Transform2D(rot, c) * Vector2(4, 2), Color("aaaaaa"), 1.2, true)   # ידית
	for i in 3:   # חלודה ופגיעות קליעים
		Art.oval(self, Transform2D(rot, c) * Vector2(-2.0 + float(i) * 2.0, 4.0 + float(i) * 4.0), 1.6, 1.0, Color(0.4, 0.2, 0.08, 0.7), 0.0, Art.NONE)


func _leg(hip: Vector2, foot: Vector2, pa: Color, sk: Color, shoe_col: Color) -> void:
	var ankle := foot + Vector2(0.0, -3.0)
	var knee := Art.joint(hip, ankle, 11.5, 11.5, 1.0)
	var mid := knee.lerp(ankle, 0.45)
	Art.limb(self, PackedVector2Array([hip, knee, mid]), 7.0, pa)
	Art.limb(self, PackedVector2Array([mid, ankle]), 5.2, sk)
	# שוליים קרועים של המכנס
	Art.fill(self, PackedVector2Array([mid + Vector2(-3.8, -1.0), mid + Vector2(3.8, -1.0), mid + Vector2(3.0, 2.0), mid + Vector2(1.0, 0.8), mid + Vector2(-1.0, 2.5), mid + Vector2(-3.0, 0.8)]), pa, Art.NONE)
	if shoe_col.a > 0.0:
		Art.fill(self, PackedVector2Array([foot + Vector2(-3.0, -4.5), foot + Vector2(3.0, -4.5), foot + Vector2(7.0, -1.5), foot + Vector2(7.0, 0.0), foot + Vector2(-3.5, 0.0)]), shoe_col, Art.OUTLINE, 1.0)
	else:   # יחף
		Art.fill(self, PackedVector2Array([foot + Vector2(-2.5, -4.0), foot + Vector2(2.5, -4.0), foot + Vector2(6.5, -1.2), foot + Vector2(6.5, 0.0), foot + Vector2(-3.0, 0.0)]), sk, Art.OUTLINE, 1.0)


func _arm(shoulder: Vector2, hand: Vector2, sk: Color, sleeve: Color) -> void:
	var w := 7.0 if _big() else (4.2 if kind == RUNNER or kind == SCREAMER else 5.2)
	var elbow := Art.joint(shoulder, hand, 9.0, 9.5, -1.0)
	if kind != WALKER:   # בלי שרוולים (גופייה)
		Art.limb(self, PackedVector2Array([shoulder, elbow, hand]), w, sk)
	else:
		var cuff := shoulder.lerp(elbow, 0.75)
		Art.limb(self, PackedVector2Array([cuff, elbow, hand]), w * 0.85, sk)
		Art.limb(self, PackedVector2Array([shoulder, cuff]), w + 1.0, sleeve)
	# כף יד עם אצבעות שמוטות
	var d := (hand - elbow).normalized()
	Art.disc(self, hand, w * 0.5 + 0.6, sk)
	for i in 3:
		var a := d.rotated(0.5 + float(i) * 0.35)
		draw_line(hand + d * 1.5, hand + d * 2.0 + a * 4.0, Art.OUTLINE, 1.6, true)
		draw_line(hand + d * 1.5, hand + d * 2.0 + a * 4.0, sk, 0.9, true)


func _torso_walker(sh: Vector2, hip: Vector2, sk: Color, shirt_c: Color) -> void:
	Art.limb(self, PackedVector2Array([sh + Vector2(1.0, 0.0), sh + Vector2(2.0, -5.0)]), 5.0, Art.shade(sk, 0.1))   # צוואר
	var body := PackedVector2Array([
		sh + Vector2(-8.5, -1.0), sh + Vector2(8.5, 0.0), hip + Vector2(8.0, -3.0), hip + Vector2(7.5, 3.5),
		hip + Vector2(4.5, 1.0), hip + Vector2(2.0, 4.5), hip + Vector2(-1.0, 1.5), hip + Vector2(-4.5, 4.0),
		hip + Vector2(-8.0, 0.5), sh + Vector2(-9.0, 6.0),
	])
	Art.fill_shaded(self, body, shirt_c, 0.15, 0.35, Art.OUTLINE, 1.4)
	# קרע בחולצה + צלעות
	Art.fill(self, PackedVector2Array([sh + Vector2(1.0, 7.0), sh + Vector2(6.0, 5.0), sh + Vector2(5.0, 12.0), sh + Vector2(2.0, 10.0)]), Art.shade(sk, 0.15), Art.NONE)
	draw_line(sh + Vector2(2.5, 7.5), sh + Vector2(5.3, 6.6), Art.shade(sk, 0.45), 0.8, true)
	draw_line(sh + Vector2(2.7, 9.3), sh + Vector2(5.2, 8.6), Art.shade(sk, 0.45), 0.8, true)
	Art.oval(self, sh + Vector2(-3.0, 11.0), 3.0, 4.0, Color(0.45, 0.04, 0.04, 0.55), 0.3, Art.NONE)   # כתם דם
	draw_polyline(PackedVector2Array([sh + Vector2(-6.0, 2.0), hip + Vector2(-5.0, -3.0)]), Color(0, 0, 0, 0.25), 1.0, true)
	draw_line(hip + Vector2(-8.0, -1.0), hip + Vector2(8.0, -2.0), Color("2a2218"), 2.0, true)   # חגורה


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
	Art.fill_shaded(self, top, shirt_c, 0.15, 0.35, Art.OUTLINE, 1.0)
	for i in 3:   # צלעות בולטות
		var y := hip.y - 6.5 + float(i) * 2.2
		draw_line(Vector2(hip.x + 0.5, y), Vector2(hip.x + 5.5, y - 0.8), Art.shade(sk, 0.4), 0.9, true)
	draw_line(hip + Vector2(-6.5, -1.0), hip + Vector2(6.5, -1.5), Art.shade(pants, 0.2), 2.5, true)


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


func _head(c: Vector2, sk: Color) -> void:
	var tilt := sin(_time * 1.3) * 0.08
	match kind:
		RUNNER:   # שיער ארוך ופרוע מאחור
			for i in 6:
				var a := Vector2(-4.0 + float(i) * 1.2, -6.5 + float(i) * 0.4)
				var flow := Vector2(-12.0 - float(i), 3.0 + float(i) * 1.6 + sin(_time * 8.0 + float(i)) * 1.5)
				draw_line(c + a, c + a + flow, Color("2b2420"), 2.2, true)
		BRUTE:
			pass
		_:
			Art.oval(self, c + Vector2(-2.5, -2.5), 6.0, 5.5, Color("3a3026"), 0.2)
	var rx := 8.0 if _big() else 7.2
	var ry := 7.5 if _big() else 8.2
	Art.oval_shaded(self, c, rx, ry, sk, tilt, Art.OUTLINE, 1.4)
	Art.oval(self, c + Vector2(2.5, -0.5), 4.5, 3.0, Color(0.1, 0.0, 0.05, 0.22), 0.1, Art.NONE)   # עיניים שקועות
	draw_line(c + Vector2(-4.0, 2.0), c + Vector2(-1.0, 5.0), Color(0.3, 0.1, 0.3, 0.4), 0.7, true)   # ורידים
	draw_line(c + Vector2(-3.0, -3.0), c + Vector2(-5.0, 0.5), Color(0.3, 0.1, 0.3, 0.4), 0.7, true)
	# פרטים בפנים: סדקים בעור, עין מתה, שערות
	draw_line(c + Vector2(-1.0, -6.5), c + Vector2(1.5, -3.5), Color(0.15, 0.05, 0.05, 0.5), 0.6, true)
	draw_line(c + Vector2(1.5, -3.5), c + Vector2(0.5, -1.0), Color(0.15, 0.05, 0.05, 0.5), 0.6, true)
	draw_circle(c + Vector2(4.0, -1.0), 1.1, Color(0.85, 0.88, 0.75, 0.85))   # עין מתה (בלי אישון)
	draw_circle(c + Vector2(4.3, -1.0), 0.4, Color(0.3, 0.05, 0.05))
	if kind in [WALKER, SPITTER, DRUNK, IMP, CRAWLER, BLOATER]:
		for i in 4:   # שערות דלילות
			var hs := c + Vector2(-4.0 + float(i) * 1.8, -7.5 + absf(float(i) - 1.5) * 0.6)
			draw_line(hs, hs + Vector2(-2.0 - float(i) * 0.5, -2.5 + sin(_time * 3.0 + float(i)) * 0.6), Color("2a241e"), 0.8, true)
	if _det[5]:   # לחי קרועה: רואים שיניים
		Art.fill(self, PackedVector2Array([c + Vector2(-1.0, 1.0), c + Vector2(2.5, 0.5), c + Vector2(2.0, 4.0), c + Vector2(-1.5, 3.5)]), Color("5a1010"), Art.NONE)
		for i in 3:
			draw_line(c + Vector2(-0.5 + float(i) * 1.0, 1.4), c + Vector2(-0.5 + float(i) * 1.0, 2.6), Color("e0d8b0"), 0.6)
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
	Art.glow(self, eye, 5.0, eye_col)
	Art.disc(self, eye, 1.2, eye_col.lightened(0.5), Art.NONE)
	draw_line(c + Vector2(2.0, -4.0), c + Vector2(7.0, -3.2), Art.shade(sk, 0.45), 1.4, true)   # גבה
	Art.disc(self, c + Vector2(-2.5, 0.5), 1.8, Art.shade(sk, 0.15), Art.OUTLINE, 0.8)            # אוזן
	match kind:
		BRUTE, BOSS:   # קרחת עם תפרים
			draw_polyline(PackedVector2Array([c + Vector2(-5.0, -4.0), c + Vector2(-1.0, -6.5), c + Vector2(3.0, -6.8)]), Color("3a1a1a"), 1.0, true)
			for i in 4:
				var q := c + Vector2(-4.0 + float(i) * 2.2, -4.8 - float(i) * 0.6)
				draw_line(q + Vector2(-0.6, -1.0), q + Vector2(0.6, 1.0), Color("3a1a1a"), 0.8, true)
		CONDUCTOR, COP:   # כובע: מוליך (כחול עם פס זהב) / שוטר
			var cap := Color("1e2a44") if kind == CONDUCTOR else Color("161e2e")
			Art.fill(self, PackedVector2Array([c + Vector2(-6.0, -5.0), c + Vector2(-5.0, -10.5), c + Vector2(5.0, -10.5), c + Vector2(6.5, -5.0)]), cap, Art.OUTLINE, 1.0)
			Art.fill(self, PackedVector2Array([c + Vector2(4.0, -5.5), c + Vector2(10.0, -4.5), c + Vector2(9.0, -3.5), c + Vector2(4.0, -4.0)]), Color("0e0e12"), Art.OUTLINE, 0.8)
			draw_line(c + Vector2(-5.5, -6.5), c + Vector2(6.0, -6.5), Color("c8a030") if kind == CONDUCTOR else Color("8090a0"), 1.2)
		WALKER:
			draw_line(c + Vector2(-2.0, -7.5), c + Vector2(-4.0, -10.5), Color("3a3026"), 1.0, true)
			draw_line(c + Vector2(0.0, -8.0), c + Vector2(0.5, -11.0), Color("3a3026"), 1.0, true)
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


func _draw_rat() -> void:
	var f := _dir
	var ph := _walk_phase * 2.0
	draw_set_transform(Vector2.ZERO, _angle if dead else 0.0, Vector2(f, 1.0))
	var c := Color.WHITE if _flash > 0.0 else skin
	draw_line(Vector2(-7, -3), Vector2(-16, -5 + sin(_time * 8.0) * 2.0), Color("6a5048"), 1.2, true)   # זנב
	Art.oval(self, Vector2(0, -4), 7.5, 4.0, c, 0.0, Art.OUTLINE, 1.0)
	Art.oval(self, Vector2(7, -5), 3.6, 2.6, c, 0.2, Art.OUTLINE, 1.0)
	draw_circle(Vector2(7, -8), 1.4, Art.shade(c, 0.2))   # אוזן
	draw_circle(Vector2(9, -5.5), 0.8, Color("ff3020"))   # עין
	for i in 2:
		var lx := -3.0 + float(i) * 6.0
		draw_line(Vector2(lx, -1), Vector2(lx + sin(ph + float(i) * PI) * 2.0, 0.5), Color("2a201c"), 1.2)
	draw_set_transform_matrix(Transform2D.IDENTITY)


func _draw_hand() -> void:
	if _grab_state == 0:   # בועות על המים
		for i in 2:
			var k := fmod(_time * 0.8 + float(i) * 0.5, 1.0)
			draw_arc(Vector2(0, -3), 3.0 + 8.0 * k, PI, TAU, 10, Color(0.7, 0.85, 0.8, 0.5 * (1.0 - k)), 1.0)
		return
	var up := -34.0 if _grab_state == 1 else -34.0 * clampf(_grab_t / 3.5, 0.0, 1.0)
	var c := Color.WHITE if _flash > 0.0 else skin
	Art.limb(self, PackedVector2Array([Vector2(-3, 2), Vector2(-1, up * 0.5), Vector2(2, up)]), 5.0, c)
	Art.oval(self, Vector2(3, up - 2), 4.5, 3.5, c, 0.3, Art.OUTLINE, 1.0)   # כף יד
	for i in 4:   # אצבעות סביב הקרסול
		var a := -1.2 + float(i) * 0.5
		draw_line(Vector2(3, up - 2), Vector2(3, up - 2) + Vector2.from_angle(a) * 6.0, Art.shade(c, 0.15), 1.6, true)
	draw_arc(Vector2(-2, -3), 7.0, PI, TAU, 12, Color(0.7, 0.85, 0.8, 0.6), 1.2)   # טבעת מים


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


func imp_hold_pos() -> Vector2:
	return global_position + Vector2(_dir * 3.0, -62.0 * sc)


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
		draw_set_transform_matrix(Transform2D(_angle, Vector2(0.0, -14.0 * sc)) * Transform2D(0.0, Vector2(f * sc, sc), 0.0, Vector2(0.0, 14.0 * sc)))
	else:
		Art.ground_shadow(self, Vector2.ZERO, 28.0 * sc)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(f * sc, sc))
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
		draw_rect(Rect2(x, -16.5, 3.0, 2.0), W.call(Color("3a3a3e")))
		draw_rect(Rect2(-x - 3.0, -1.5, 3.0, 2.0), W.call(Color("3a3a3e")))
		x += 6.0
	for wx in [-18.0, -6.0, 6.0, 18.0]:   # גלגלי הנעה
		draw_circle(Vector2(wx, -8.0), 4.6, dark)
		draw_circle(Vector2(wx, -8.0), 2.0, steel)
		draw_line(Vector2(wx, -8.0), Vector2(wx, -8.0) + Vector2.from_angle(_walk_phase * 2.0) * 4.0, W.call(Color("8a8e94")), 1.0)
	# ---- מנוע + צינורות פליטה (מאחור) ----
	Art.fill_shaded(self, PackedVector2Array([Vector2(-30, -18), Vector2(-20, -18), Vector2(-20, -42), Vector2(-30, -40)]), dark, 0.15, 0.3, Art.OUTLINE, 1.2)
	for k in 3:
		draw_line(Vector2(-29, -22.0 - k * 6.0), Vector2(-21, -22.0 - k * 6.0), W.call(Color("4a4c50")), 1.5)
	for ex in [-28.0, -23.0]:
		draw_line(Vector2(ex, -40), Vector2(ex - 2.0, -60), W.call(Color("3a3a3c")), 3.0)
		draw_line(Vector2(ex - 3.5, -60), Vector2(ex - 0.5, -60), W.call(Color("1a1a1a")), 3.0)
		if not dead:
			for pf in 3:
				var age := fmod(_time * 1.2 + float(pf) * 0.33 + ex * 0.1, 1.0)
				draw_circle(Vector2(ex - 2.0 - age * 10.0, -62.0 - age * 22.0), 2.0 + age * 6.0, Color(0.15, 0.15, 0.15, 0.45 * (1.0 - age)))
			if randf() < 0.15:
				draw_circle(Vector2(ex - 2.0, -61.0), 2.2, Color(1.0, 0.55, 0.15, 0.9))
	# ---- גוף מרותך מפחים ----
	Art.fill_shaded(self, PackedVector2Array([Vector2(-22, -16), Vector2(26, -16), Vector2(24, -30), Vector2(16, -40), Vector2(-20, -42)]), steel, 0.18, 0.35, Art.OUTLINE, 1.6)
	Art.fill(self, PackedVector2Array([Vector2(-20, -18), Vector2(-4, -18), Vector2(-5, -32), Vector2(-19, -33)]), rust, Art.OUTLINE, 1.0)
	Art.fill(self, PackedVector2Array([Vector2(4, -18), Vector2(24, -18), Vector2(22, -30), Vector2(6, -31)]), plate, Art.OUTLINE, 1.0)
	for i in 8:   # ריתוכים
		draw_circle(Vector2(-4.5 + float(i % 2) * 0.6, -19.0 - float(i) * 1.7), 0.7, W.call(Color("b0a090")))
	for p in [Vector2(-18, -20), Vector2(-18, -31), Vector2(-6, -20), Vector2(22, -20), Vector2(8, -20), Vector2(20, -29)]:
		draw_circle(p, 1.0, W.call(Color("c8c8cc")))
	draw_rect(Rect2(10, -24, 14, 3), W.call(Color("c8a020")))   # פס אזהרה
	for i in 3:
		draw_line(Vector2(11.0 + i * 5.0, -21.0), Vector2(14.0 + i * 5.0, -24.0), Color(0, 0, 0, 0.8), 1.4)
	# מיכל "דלק זומבי" ירוק זוהר עם בועות
	Art.fill(self, PackedVector2Array([Vector2(-16, -34), Vector2(-6, -34), Vector2(-6, -24), Vector2(-16, -24)]), W.call(Color(0.25, 0.9, 0.3, 0.75)), Art.OUTLINE, 1.2)
	if not dead:
		Art.glow(self, Vector2(-11, -29), 9.0, Color(0.3, 1.0, 0.3, 0.25 + 0.15 * sin(_time * 5.0)))
		for bb in 3:
			var by := -25.0 - fmod(_time * 8.0 + float(bb) * 3.0, 9.0)
			draw_circle(Vector2(-13.0 + float(bb) * 2.5, by), 0.8, Color(0.8, 1.0, 0.8, 0.8))
	# פנס קדמי
	draw_circle(Vector2(25, -26), 2.4, W.call(Color("e8e0b0")))
	if not dead:
		Art.glow(self, Vector2(27, -26), 8.0, Color(1.0, 0.95, 0.7, 0.25))
	# ---- תא: כלוב + הזומבי (הנקודה הפגיעה) ----
	if not dead:
		var sk: Color = W.call(skin)
		var bob := sin(_time * 3.0) * 0.6
		# כבלים מהראש למכונה (הזומבי מחובר לרובוט)
		draw_line(Vector2(-8, -64 + bob), Vector2(-17, -42), W.call(Color("1a1a1a")), 1.6, true)
		draw_line(Vector2(-6, -66 + bob), Vector2(-20, -45), W.call(Color("8a2020")), 1.2, true)
		# גוף: חולצה קרועה וצלעות חשופות
		Art.fill(self, PackedVector2Array([Vector2(-11, -40), Vector2(5, -40), Vector2(5, -54 + bob), Vector2(-10, -55 + bob)]), W.call(shirt), Art.OUTLINE, 1.0)
		Art.fill(self, PackedVector2Array([Vector2(-3, -42), Vector2(4, -42), Vector2(4, -51 + bob), Vector2(-2, -52 + bob)]), W.call(Color("8a3a2a")), Art.NONE)
		for r in 3:
			draw_line(Vector2(-2, -44.0 - r * 2.6 + bob * 0.5), Vector2(4, -44.5 - r * 2.6 + bob * 0.5), W.call(Color("e0d8c0")), 0.9)
		# יד על ידית ההיגוי
		Art.limb(self, PackedVector2Array([Vector2(3, -52 + bob), Vector2(9, -46), Vector2(13, -42)]), 2.6, sk)
		draw_line(Vector2(13, -38), Vector2(15, -45), W.call(Color("2a2a2a")), 1.6)
		# ראש: נרקב, לסת פתוחה, שתל מתכת עם עין אדומה
		var hc := Vector2(-2.0, -61.0 + bob)
		Art.oval(self, hc, 7.0, 7.8, sk, 0.0, Art.OUTLINE, 1.2)
		Art.oval(self, hc + Vector2(-3.0, 2.0), 2.4, 1.6, W.call(Art.shade(skin, 0.35)), 0.3, Art.NONE)   # כתם ריקבון
		Art.fill(self, PackedVector2Array([hc + Vector2(-6, -6), hc + Vector2(2, -8), hc + Vector2(3, -3), hc + Vector2(-5, -1)]), W.call(Color("6a6e74")), Art.OUTLINE, 0.9)   # שתל מתכת
		draw_circle(hc + Vector2(-2, -4.5), 0.7, W.call(Color("c8c8cc")))
		Art.glow(self, hc + Vector2(3.5, -1.0), 5.0, Color(1.0, 0.15, 0.1, 0.8))
		draw_circle(hc + Vector2(3.5, -1.0), 1.3, Color(1.0, 0.45, 0.35))
		Art.fill(self, PackedVector2Array([hc + Vector2(1, 3), hc + Vector2(7, 2.5), hc + Vector2(6, 7.5 + absf(sin(_time * 6.0)) * 1.5), hc + Vector2(1, 6)]), W.call(Color("2a0808")), Art.OUTLINE, 0.8)   # לסת פתוחה
		for tth in 3:
			draw_line(hc + Vector2(2.0 + tth * 1.6, 3.0), hc + Vector2(2.3 + tth * 1.6, 4.4), W.call(Color("e8e0c8")), 0.8)
		# כלוב מגן
		for cx in [-14.0, 8.0]:
			draw_line(Vector2(cx, -40), Vector2(cx + 2.0, -70), W.call(Color("3a3c40")), 1.6)
		draw_arc(Vector2(-3, -70), 11.0, PI, TAU, 10, W.call(Color("3a3c40")), 1.6)
	draw_rect(Rect2(-20, -44, 34, 4), dark)   # שפת התא
	# אנטנה מהבהבת
	draw_line(Vector2(-18, -42), Vector2(-22, -74), dark, 1.2)
	draw_circle(Vector2(-22, -74), 1.8, Color(1.0, 0.15, 0.1, 0.4 + 0.6 * float(int(_time * 3.0) % 2)))
	draw_set_transform_matrix(Transform2D.IDENTITY)
	if dead:
		return
	# ---- זרוע הידראולית + גאטלינג מסתובב ----
	var base := Vector2(f * 12.0 * sc, -30.0 * sc)
	var piv := Vector2(f * 14.0 * wf, -34.0 * sc)
	draw_line(base, piv, Color("3a3c40"), 4.0)
	draw_line(base + Vector2(0, -2), piv + Vector2(0, -2), Color("9a9ea4"), 1.0)
	var dv := Vector2.from_angle(_gun_ang)
	var nv := dv.rotated(PI / 2.0)
	var L := 30.0 * sc
	draw_colored_polygon(PackedVector2Array([piv - nv * 5.0 - dv * 7.0, piv - nv * 5.0 + dv * 11.0, piv + nv * 5.0 + dv * 11.0, piv + nv * 5.0 - dv * 7.0]), Color("26282c"))
	draw_line(piv - nv * 5.0 + dv * 2.0, piv - nv * 5.0 + dv * 9.0, Color("c8a020"), 1.5)
	var spin := _time * (30.0 if _burst > 0 else 2.0)   # הקנים מסתובבים בירי
	for k in 3:
		var o := sin(spin + float(k) * TAU / 3.0) * 2.2
		draw_line(piv + dv * 10.0 + nv * o, piv + dv * L + nv * o, Color(0.12 + 0.05 * float(k), 0.12, 0.13), 1.6)
	draw_line(piv + dv * (L - 3.0) - nv * 3.0, piv + dv * (L - 3.0) + nv * 3.0, Color("44464a"), 2.5)
	# שרשרת תחמושת מהגוף לנשק
	var belt_a := Vector2(f * 2.0 * sc, -26.0 * sc)
	for i in 7:
		var tt := float(i) / 6.0
		var bp := belt_a.lerp(piv + nv * 4.0, tt) + Vector2(0, sin(tt * PI) * 6.0)
		draw_rect(Rect2(bp - Vector2(1.2, 1.2), Vector2(2.4, 2.4)), Color("c8903a"))
	var muzzle := piv + dv * L
	if _muzzle_t > 0.0:
		for i in 6:
			draw_line(muzzle, muzzle + dv.rotated(randf_range(-0.6, 0.6)) * randf_range(6.0, 16.0), Color(1.0, 0.85, 0.4), 2.0)
	if _aim_t > 0.0:   # לייזר אזהרה
		draw_line(muzzle, muzzle + dv * 520.0, Color(1.0, 0.1, 0.1, 0.35 + 0.35 * sin(_time * 30.0)), 1.2)
	if hp < max_hp * 0.4:   # עשן וניצוצות כשנפגע
		for i in 3:
			var age := fmod(_time * 0.8 + float(i) * 0.33, 1.0)
			draw_circle(Vector2(-f * 8.0, -44.0 * sc - age * 30.0), 4.0 + age * 8.0, Color(0.2, 0.2, 0.2, 0.45 * (1.0 - age)))
		if randf() < 0.2:
			var sp := Vector2(f * randf_range(-15.0, 15.0), -randf_range(20.0, 40.0) * sc)
			draw_line(sp, sp + Vector2(randf_range(-6, 6), -randf_range(3, 8)), Color(1.0, 0.85, 0.4), 1.2)


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
	if dead:
		base = Transform2D(_angle, Vector2(0.0, -20.0 * S)) * Transform2D(0.0, Vector2(f * S, S), 0.0, Vector2(0.0, 20.0 * S))
	else:
		Art.ground_shadow(self, Vector2.ZERO, 26.0 * S)
	draw_set_transform_matrix(base)
	var bob := absf(sin(ph)) * 2.0 if run and not dead else 0.0
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
					draw_colored_polygon(PackedVector2Array([p + Vector2.from_angle(sa + 0.4) * 2.0, p + Vector2.from_angle(sa) * 6.5, p + Vector2.from_angle(sa - 0.4) * 2.0]), Color("9a9aa2"))
		Art.oval(self, pts[-1], 5.5, 5.5, Color("3a3a40"), 0.0, Art.OUTLINE, 1.0)   # כדור קוצים בקצה
		for s2 in 6:
			var sa := float(s2) * TAU / 6.0
			draw_colored_polygon(PackedVector2Array([pts[-1] + Vector2.from_angle(sa + 0.35) * 4.0, pts[-1] + Vector2.from_angle(sa) * 10.0, pts[-1] + Vector2.from_angle(sa - 0.35) * 4.0]), Color("b0b0b8"))
	# ---- ספרייט הכלב (תמונה אחת + תנועה פרוצדורלית: דהירה, קפיצה, כריעה) ----
	var rot := 0.0
	var sq := Vector2.ONE
	if not dead:
		if not is_on_floor():
			rot = clampf(velocity.y / 1400.0, -0.3, 0.3)
		elif run:
			rot = sin(ph) * 0.06
			sq = Vector2(1.0 + sin(ph * 2.0) * 0.04, 1.0 - sin(ph * 2.0) * 0.04)
		else:
			sq = Vector2(1.0, 1.0 + sin(_time * 2.0) * 0.015)   # נשימה
		sq *= Vector2(1.0 + crouch * 0.06, 1.0 - crouch * 0.16)
		if _bite_anim > 0.0 or (hound and _hstate == 2):
			rot -= 0.08
	if dead:
		rot = 0.08 * dk
		bob = -15.0 * dk
	var bm := base * Transform2D(rot, sq, 0.0, Vector2(0.0, -bob))
	var mod := Color(4, 4, 4) if white else Color.WHITE
	var k := Vector2(76.0 / 186.0, 50.0 / 123.0)   # פיקסל בתמונה -> יחידה מקומית
	var amp := 0.0 if dead else clampf(absf(velocity.x) / 260.0, 0.0, 0.55)
	var air := not dead and not is_on_floor()
	# שוקיים נפרדות (צד ימין של התמונה) שמתנדנדות סביב הברך: [x0, חיתוך y, x1, ציר x, היסט פאזה, זווית באוויר]
	for lg in [[0.0, 84.0, 24.0, 12.0, PI * 0.5, 0.6], [24.0, 84.0, 60.0, 36.0, PI, 0.5], [90.0, 76.0, 150.0, 115.0, 0.0, -0.6]]:
		var src := Rect2(192.0 + lg[0], lg[1] - 2.0, lg[2] - lg[0], 125.0 - lg[1])
		var pv := Vector2(-36.0, -50.0) + Vector2(lg[3], lg[1]) * k
		var la: float = lg[5] if air else sin(ph + lg[4]) * amp
		if dead:
			la = (-1.35 if lg[0] > 80.0 else 1.35) * dk
		draw_set_transform_matrix(bm * Transform2D(la, pv) * Transform2D(0.0, -pv))
		draw_texture_rect_region(DOG_TEX, Rect2(Vector2(-36.0, -50.0) + Vector2(lg[0], lg[1] - 2.0) * k, src.size * k), src, mod)
	draw_set_transform_matrix(bm)
	draw_texture_rect_region(DOG_TEX, Rect2(-36, -50, 76, 50), Rect2(0, 0, 186, 123), mod)
	if hound:   # קולר קוצים
		Art.limb(self, PackedVector2Array([nk + Vector2(-3, -9), nk + Vector2(3, 9)]), 5.0, Color("2a2a2e"))
		for i in 5:
			var cp := nk.lerp(nk + Vector2(6, 18), float(i) / 4.0) + Vector2(-3, -9)
			draw_colored_polygon(PackedVector2Array([cp + Vector2(-1.5, 0), cp + Vector2(-6, -1), cp + Vector2(-1.5, 2)]), Color("b8b8c0"))
			draw_colored_polygon(PackedVector2Array([cp + Vector2(1.5, 0), cp + Vector2(6, 1), cp + Vector2(1.5, 2)]), Color("b8b8c0"))
	draw_set_transform_matrix(Transform2D.IDENTITY)


# ---- ציור מקלען על חצובה ----
func _draw_gunner() -> void:
	var f := _dir
	var white := _flash > 0.0
	var sk: Color = Color.WHITE if white else skin
	var army: Color = Color.WHITE if white else shirt
	if dead:
		draw_set_transform_matrix(Transform2D(_angle, Vector2(0.0, -20.0 * sc)) * Transform2D(0.0, Vector2(f * sc, sc), 0.0, Vector2(0.0, 20.0 * sc)))
	else:
		Art.ground_shadow(self, Vector2.ZERO, 26.0 * sc)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(f * sc, sc))
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
	draw_line(hc + Vector2(2, 4), hc + Vector2(6, 4), Color(0.2, 0.05, 0.05), 1.2)
	# חצובה
	draw_line(Vector2(10, -32), Vector2(3, 0), Color("2a2a2e"), 1.8)
	draw_line(Vector2(10, -32), Vector2(19, 0), Color("2a2a2e"), 1.8)
	draw_set_transform_matrix(Transform2D.IDENTITY)
	if dead:
		return
	# מקלע + מגן פלדה (מסתובבים לכיוון השחקן)
	var piv := Vector2(f * 10.0 * wf, -34.0 * sc)
	var dv := Vector2.from_angle(_gun_ang)
	var nv := dv.rotated(PI / 2.0)
	draw_colored_polygon(PackedVector2Array([piv - nv * 4.0 - dv * 10.0, piv - nv * 4.0 + dv * 12.0, piv + nv * 4.0 + dv * 12.0, piv + nv * 4.0 - dv * 10.0]), Color("26282c"))
	draw_line(piv + dv * 12.0, piv + dv * 34.0, Color("3a3c40"), 4.0)
	for i in 4:
		draw_circle(piv + dv * (15.0 + float(i) * 4.5), 1.0, Color(0.08, 0.08, 0.1))
	draw_rect(Rect2(piv + nv * 4.0 - Vector2(4, 0), Vector2(8, 7)), Color("4a4a2e"))   # ארגז תחמושת
	var sp := piv + dv * 8.0
	var shield := PackedVector2Array([sp - nv * 18.0, sp - nv * 18.0 + dv * 3.0, sp + nv * 12.0 + dv * 3.0, sp + nv * 12.0])
	draw_colored_polygon(shield, Color.WHITE if white else Color("5d6168"))
	shield.append(shield[0])
	draw_polyline(shield, Color(0, 0, 0, 0.8), 1.2, true)
	draw_line(sp - nv * 10.0 + dv * 1.5, sp - nv * 6.0 + dv * 1.5, Color(0.05, 0.05, 0.05), 1.5)   # חריץ הצצה
	var muzzle := piv + dv * 34.0
	if _aim_t > 0.0:
		Art.glow(self, muzzle, 6.0, Color(1.0, 0.6, 0.2, 0.5 + 0.4 * sin(_time * 30.0)))
	if _muzzle_t > 0.0:
		for i in 5:
			draw_line(muzzle, muzzle + dv.rotated(randf_range(-0.6, 0.6)) * randf_range(6.0, 14.0), Color(1.0, 0.85, 0.4), 2.0)


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
	draw_polyline(hem, Color(0, 0, 0, 0.45), 0.9, true)
	if _det[1]:   # תפרים על החזה
		var a := sh + Vector2(-5.0, 4.0)
		var b := sh + Vector2(3.0, 9.0)
		draw_line(a, b, Color(0.12, 0.05, 0.05, 0.8), 0.8, true)
		for i in 4:
			var q := a.lerp(b, (float(i) + 0.5) / 4.0)
			draw_line(q + Vector2(-0.8, 1.0), q + Vector2(0.8, -1.0), Color(0.8, 0.75, 0.6, 0.8), 0.6, true)
	if _det[2]:   # רצועת בשר תלויה
		var t0 := mid + Vector2(5.0, 2.0)
		draw_colored_polygon(PackedVector2Array([t0, t0 + Vector2(2.0, 0.0), t0 + Vector2(1.5, 6.0 + sin(_time * 4.0)), t0 + Vector2(0.5, 5.0)]), Color("6a1414"))
	# צל בצד הגוף (נפח)
	draw_line(sh + Vector2(-6.5, 3.0), hip + Vector2(-6.0, -2.0), Color(0, 0, 0, 0.22), 2.0, true)


# ---- טקסט קופץ (HEADSHOT!) ----
class HitText extends Node2D:
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
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(k, k))
		var w := f.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
		var pos := Vector2(-w / 2.0, 0.0)
		draw_string_outline(f, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, 5, Color(0, 0, 0, 0.85))
		draw_string(f, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)


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
			draw_set_transform(Vector2(0, 4), 0.0, Vector2(1.0, 0.12))
			draw_circle(Vector2.ZERO, radius, Color(0.4, 0.7, 1.0, 0.18 * a))
			draw_set_transform_matrix(Transform2D.IDENTITY)
			for i in 5:
				var x0 := randf_range(-radius, radius)
				var pts := PackedVector2Array([Vector2(x0, 2)])
				for k in 4:
					pts.append(pts[-1] + Vector2(randf_range(4, 12) * signf(randf() - 0.5), randf_range(-8, 2)))
				draw_polyline(pts, Color(0.75, 0.9, 1.0, a), 1.4)
			return
		draw_circle(Vector2.ZERO, 12.0, Color(0.3, 0.6, 1.0, 0.25))
		draw_circle(Vector2.ZERO, 6.0, Color(0.7, 0.9, 1.0, 0.9))
		for i in 3:
			draw_line(Vector2.ZERO, Vector2.from_angle(randf() * TAU) * randf_range(8, 14), Color(0.85, 0.95, 1.0), 1.2)


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
		draw_line(Vector2(-20, 0), Vector2(0, 0), Color(1.0, 0.55, 0.2, 0.45), 2.0)
		draw_line(Vector2(-7, 0), Vector2(2, 0), Color(1.0, 0.9, 0.6), 2.2)
