extends RefCounted
# ============================================================
#  WEAPON DATABASE - כל הנשקים במשחק מוגדרים כאן (ולא בתוך player.gd)
#
#  איך מוסיפים נשק חדש:
#    1. מוסיפים מילון חדש בסוף WEAPONS (ה-id = המיקום ברשימה).
#    2. אם צריך צליל חדש - מוסיפים אותו ל-weapons/weapon_sounds.gd.
#    3. אייקון בגלגל הנשקים: weapon_wheel.gd -> draw_weapon (לפי "icon").
#       הציור ביד של הדמות נבחר לפי "style" (player.gd -> _draw_rifle).
#    4. באיזה שלב הוא נכנס למשחק: "unlock_level" (progression/arsenal.gd מניח אותו בתחילת השלב הזה).
#
#  שדות (כולם אופציונליים חוץ מ-name):
#    name, color        - שם וצבע בממשק
#    damage             - מכפיל נזק. הנזק הבסיסי נקבע בזומבי לפי מקום הפגיעה
#                         (ראש / גוף / רגל), ואז מוכפל בזה. 1.0 = רובה רגיל
#    fixed_damage       - [min, max] נזק קבוע במקום אזורי פגיעה (חץ)
#    falloff            - [קרוב, רחוק, מרחק] נזק שיורד עם המרחק (שוטגאנים)
#    fire_rate          - שניות בין יריות
#    magazine_size      - כמה כדורים במחסנית. 0 = בלי טעינה (קשת, טייזר, בקבוקים)
#    reload_time        - שניות לטעינה (R, או אוטומטי כשהמחסנית ריקה)
#    range              - כמה פיקסלים הקליע עף לפני שהוא נעלם
#    spread             - פיזור בכל ירייה (רדיאנים, +/-)
#    recoil             - כמה הירייה דוחפת את הדמות אחורה (1 = רובה)
#    kick               - כמה הקנה "קופץ" למעלה מירייה לירייה (SMG)
#    bullet_speed       - מהירות הקליע
#    knockback          - כמה הזומבי נהדף מפגיעה
#    pellets            - כמה קליעים בכל ירייה (שוטגאן)
#    pierce             - דרך כמה זומבים הקליע עובר
#    projectile         - bullet / arrow / taser / molotov / launcher
#    ammo_type          - איזה סוג תחמושת (לתצוגה ולקופסאות)
#    ammo_start / ammo_box / ammo_max - כמה מקבלים כשמוצאים, מקופסה, ומקסימום
#    sound, sound_db    - צליל הירייה
#    style              - איך הנשק מצויר ביד (rifle / shotgun / bow / sniper / taser / pistol / smg / ar / bottle / launcher)
#    barrel             - אורך הקנה ביד (גם המקום של הבזק הלוע)
#    unlock_level       - באיזה שלב הנשק מופיע לראשונה (משפיע על מחיר השדרוגים שלו). טבלת ההתקדמות: progression/arsenal.gd
#    pitch / incendiary / gravity / scope / flame - ראו את נשקי ההתקדמות בסוף הרשימה
#    sound2, sound2_db  - שכבת צליל נוספת לירייה (בס לנשקים כבדים: boom_heavy / boom_50 / thud_auto / rail_zap / xbow_snap)
#    spin_up            - MINIGUN: שניות עד קצב אש מלא (player.gd -> _spin_update; מתחיל ב-SPIN_START מהקצב)
#    category           - auto / shotgun / precision / explosive / other  (PlayerMemory משתמש בזה כדי "ללמוד" את השחקן)
#
#  איזון (מעבר "gunfeel"): זומבי רגיל = 30 HP. גוף 12-15 x damage, ראש 30 (לא מוכפל ב-damage).
#    רובה 2 יריות בגוף · אקדח 3 מהירות · SMG ~7 · רובה סער 4 · צלף = ירייה אחת בגוף וחודר · שוטגאן מקרוב = ירייה אחת.
#    knockback קובע גם כמה רחוק הגופה עפה במוות (zombie.gd -> _die, KILL_FLING).
# ============================================================

const WEAPONS := [
	{"name": "RIFLE", "unlock_level": 1, "color": Color("d8c070"), "damage": 1.25, "fire_rate": 0.6, "magazine_size": 8, "reload_time": 0.5,
		"range": 1800.0, "spread": 0.0, "recoil": 0.5, "bullet_speed": 2600.0, "knockback": 85.0, "projectile": "bullet",
		"ammo_type": "rifle", "ammo_start": 30, "ammo_box": 10, "ammo_max": 60, "sound": "rifle", "style": "rifle", "barrel": 25.0, "category": "precision"},
	{"name": "SHOTGUN", "unlock_level": 2, "color": Color("e07a3a"), "falloff": [10.0, 2.0, 460.0], "fire_rate": 0.85, "magazine_size": 6, "reload_time": 1.2,
		"range": 900.0, "spread": 0.16, "recoil": 2.2, "bullet_speed": 2400.0, "knockback": 190.0, "pellets": 6, "projectile": "bullet",
		"ammo_type": "shell", "ammo_start": 8, "ammo_box": 3, "ammo_max": 16, "sound": "shotgun", "sound_db": 2.0, "style": "shotgun", "barrel": 22.0, "category": "shotgun"},
	{"name": "BOW", "removed": true, "unlock_level": 1, "color": Color("8ac060"), "fixed_damage": [13, 19], "fire_rate": 0.8, "magazine_size": 0,
		"range": 3400.0, "spread": 0.0, "recoil": 0.0, "bullet_speed": 1150.0, "knockback": 40.0, "projectile": "arrow",
		"ammo_type": "arrow", "ammo_start": 12, "ammo_box": 4, "ammo_max": 20, "sound": "bow", "sound_db": -2.0, "style": "bow", "barrel": 20.0, "category": "precision"},
	{"name": "SNIPER", "unlock_level": 9, "color": Color("7ad0ff"), "damage": 1.7, "sniper": true, "fire_rate": 1.25, "magazine_size": 5, "reload_time": 1.1,
		"range": 6000.0, "spread": 0.0, "recoil": 0.7, "bullet_speed": 4200.0, "knockback": 230.0, "pierce": 3, "projectile": "bullet",
		"ammo_type": "sniper", "ammo_start": 5, "ammo_box": 2, "ammo_max": 10, "sound": "sniper", "sound_db": 1.0, "style": "sniper", "barrel": 35.0, "category": "precision"},
	{"name": "TASER", "unlock_level": 14, "color": Color("b080ff"), "fire_rate": 0.9, "magazine_size": 0, "recoil": 0.1, "projectile": "taser",
		"ammo_type": "battery", "ammo_start": 6, "ammo_box": 2, "ammo_max": 12, "sound": "taser", "sound_db": -2.0, "style": "taser", "barrel": 20.0, "category": "other"},
	# ---- שלב 5+ ----
	{"name": "PISTOL", "unlock_level": 4, "color": Color("c8c8d0"), "damage": 0.8, "fire_rate": 0.3, "magazine_size": 12, "reload_time": 0.5,
		"range": 1300.0, "spread": 0.025, "recoil": 0.1, "bullet_speed": 2400.0, "knockback": 55.0, "projectile": "bullet",
		"ammo_type": "9mm", "ammo_start": 36, "ammo_box": 12, "ammo_max": 96, "sound": "pistol", "style": "pistol", "barrel": 14.0, "category": "precision"},
	{"name": "SMG", "unlock_level": 7, "color": Color("f0d040"), "damage": 0.33, "head_mult": 0.4, "fire_rate": 0.11, "magazine_size": 30, "reload_time": 0.8,
		"range": 1100.0, "spread": 0.1, "recoil": 0.15, "kick": 0.025, "bullet_speed": 2300.0, "knockback": 30.0, "projectile": "bullet",
		"ammo_type": "9mm", "ammo_start": 90, "ammo_box": 24, "ammo_max": 150, "sound": "smg", "sound_db": -3.0, "style": "smg", "barrel": 17.0, "category": "auto"},
	{"name": "ASSAULT RIFLE", "unlock_level": 12, "color": Color("9ad070"), "damage": 0.55, "head_mult": 0.5, "fire_rate": 0.17, "magazine_size": 30, "reload_time": 0.9,
		"range": 2000.0, "spread": 0.05, "recoil": 0.25, "kick": 0.012, "bullet_speed": 2800.0, "knockback": 60.0, "projectile": "bullet",
		"ammo_type": "rifle", "ammo_start": 60, "ammo_box": 24, "ammo_max": 120, "sound": "ar", "sound_db": -1.0, "style": "ar", "barrel": 26.0, "category": "auto"},
	{"name": "MOLOTOV", "special": true, "unlock_level": 7, "color": Color("ff8a30"), "fire_rate": 0.9, "magazine_size": 0, "recoil": 0.0, "bullet_speed": 640.0, "projectile": "molotov",
		"ammo_type": "bottle", "ammo_start": 3, "ammo_box": 1, "ammo_max": 6, "sound": "throw", "style": "bottle", "barrel": 10.0, "category": "explosive"},
	{"name": "GRENADE LAUNCHER", "special": true, "unlock_level": 8, "color": Color("80b060"), "fire_rate": 1.1, "magazine_size": 4, "reload_time": 1.4, "recoil": 0.9,
		"bullet_speed": 950.0, "knockback": 0.0, "projectile": "launcher",
		"ammo_type": "40mm", "ammo_start": 6, "ammo_box": 2, "ammo_max": 12, "sound": "launcher", "style": "launcher", "barrel": 24.0, "category": "explosive"},
	{"name": "ASSAULT SHOTGUN", "unlock_level": 19, "color": Color("ff5a3a"), "falloff": [11.0, 2.0, 460.0], "fire_rate": 0.32, "magazine_size": 8, "reload_time": 1.3,
		"range": 950.0, "spread": 0.19, "recoil": 1.5, "bullet_speed": 2400.0, "knockback": 200.0, "pellets": 7, "projectile": "bullet",
		"ammo_type": "shell", "ammo_start": 16, "ammo_box": 6, "ammo_max": 40, "sound": "ashotgun", "style": "ashotgun", "barrel": 24.0, "category": "shotgun"},
	{"name": "ROCKET LAUNCHER", "special": true, "unlock_level": 12, "color": Color("e05a30"), "damage": 1.0, "fire_rate": 0.95, "magazine_size": 2, "reload_time": 1.2, "recoil": 1.3,
		"bullet_speed": 640.0, "knockback": 0.0, "projectile": "rocket",
		"ammo_type": "rocket", "ammo_start": 4, "ammo_box": 2, "ammo_max": 10, "sound": "rocket", "style": "rocket", "barrel": 30.0, "category": "explosive"},
	# ---- נשקי ההתקדמות (מעבר "progression"): נכנסים לאורך כל 51 השלבים - progression/arsenal.gd -> REWARDS ----
	# איזון (מעבר "weapons"): כל נשק חדש חזק מהנשקים שכבר יש בשלב שלו, ולכל אחד תפקיד:
	#   REVOLVER = 2 יריות בגוף, חודר · DOUBLE BARREL = פרץ של 2 יריות מקרוב · LEVER-ACTION = ירייה אחת בגוף (75%), חודר 2
	#   CROSSBOW = ירייה אחת תמיד, חודר 4, שקט, חצים חוזרים · FLAMETHROWER = קהל מקרוב + בעירה · LMG = 80 כדורים, חודר
	#   DRAGON'S BREATH = שוטגאן משאבה + אש לכל הקהל · ANTI-MATERIEL = הורג כל דבר בשורה (חודר 8) · MARKSMAN = צלף מהיר
	#   MINIGUN = מסתובב ואז 20 כדורים בשנייה · RAILGUN = חוצה את כל המסך (חודר 20). טבלה: DEV_GUIDE.md (מעבר "weapons")
	# שדות חדשים: pitch = גובה צליל הירייה, incendiary = כל קליע מצית, gravity = כבידה לחץ, scope = כוונת RMB, flame = להבה (bullet.gd)
	{"name": "REVOLVER", "unlock_level": 10, "color": Color("d8b890"), "damage": 2.0, "fire_rate": 0.4, "magazine_size": 6, "reload_time": 1.3,
		"range": 1500.0, "spread": 0.012, "recoil": 0.7, "bullet_speed": 2700.0, "knockback": 150.0, "pierce": 1, "projectile": "bullet",
		"ammo_type": ".44", "ammo_start": 24, "ammo_box": 8, "ammo_max": 48, "sound": "pistol", "sound_db": 3.0, "pitch": 0.78, "sound2": "boom_heavy", "sound2_db": -2.0, "style": "revolver", "barrel": 17.0, "category": "precision"},
	{"name": "DOUBLE BARREL", "unlock_level": 16, "color": Color("c86a3a"), "falloff": [13.0, 2.0, 400.0], "fire_rate": 0.22, "magazine_size": 2, "reload_time": 1.1,
		"range": 850.0, "spread": 0.2, "recoil": 2.8, "bullet_speed": 2300.0, "knockback": 240.0, "pellets": 8, "projectile": "bullet",
		"ammo_type": "shell", "ammo_start": 12, "ammo_box": 4, "ammo_max": 28, "sound": "shotgun", "sound_db": 3.0, "pitch": 0.88, "sound2": "boom_heavy", "sound2_db": 1.0, "style": "dbarrel", "barrel": 23.0, "category": "shotgun"},
	{"name": "LEVER-ACTION", "unlock_level": 18, "color": Color("b8905a"), "damage": 2.4, "fire_rate": 0.5, "magazine_size": 7, "reload_time": 1.4,
		"range": 2200.0, "spread": 0.0, "recoil": 0.8, "bullet_speed": 3000.0, "knockback": 170.0, "pierce": 2, "projectile": "bullet",
		"ammo_type": ".45-70", "ammo_start": 21, "ammo_box": 7, "ammo_max": 42, "sound": "rifle", "sound_db": 1.5, "pitch": 0.86, "sound2": "boom_heavy", "sound2_db": -3.0, "style": "lever", "barrel": 28.0, "category": "precision"},
	{"name": "CROSSBOW", "unlock_level": 22, "color": Color("9ac070"), "fixed_damage": [38, 46], "fire_rate": 0.7, "magazine_size": 0,
		"range": 3200.0, "spread": 0.0, "recoil": 0.2, "bullet_speed": 1800.0, "gravity": 380.0, "knockback": 110.0, "pierce": 4, "projectile": "arrow",
		"ammo_type": "bolt", "ammo_start": 14, "ammo_box": 5, "ammo_max": 28, "sound": "bow", "sound_db": 1.0, "pitch": 0.8, "sound2": "xbow_snap", "sound2_db": 0.0, "style": "crossbow", "barrel": 22.0, "category": "precision"},
	{"name": "FLAMETHROWER", "unlock_level": 24, "color": Color("ff7a20"), "fixed_damage": [3, 5], "fire_rate": 0.06, "magazine_size": 0,
		"range": 480.0, "spread": 0.13, "recoil": 0.05, "bullet_speed": 900.0, "knockback": 12.0, "pellets": 2, "pierce": 2, "projectile": "flame", "incendiary": true,
		"ammo_type": "fuel", "ammo_start": 200, "ammo_box": 70, "ammo_max": 360, "sound": "flamer", "sound_db": -4.0, "style": "flamer", "barrel": 24.0, "category": "auto"},
	{"name": "LMG", "unlock_level": 27, "color": Color("8a9a6a"), "damage": 0.55, "head_mult": 0.5, "fire_rate": 0.085, "magazine_size": 80, "reload_time": 2.6,
		"range": 1800.0, "spread": 0.07, "recoil": 0.3, "kick": 0.01, "bullet_speed": 2700.0, "knockback": 65.0, "pierce": 1, "projectile": "bullet",
		"ammo_type": "7.62", "ammo_start": 160, "ammo_box": 40, "ammo_max": 320, "sound": "ar", "sound_db": 0.0, "pitch": 0.84, "sound2": "thud_auto", "sound2_db": -4.0, "style": "lmg", "barrel": 30.0, "category": "auto"},
	{"name": "DRAGON'S BREATH", "unlock_level": 30, "color": Color("ff9a3a"), "falloff": [13.0, 3.0, 520.0], "fire_rate": 0.55, "magazine_size": 6, "reload_time": 1.1,
		"range": 1000.0, "spread": 0.17, "recoil": 2.2, "bullet_speed": 2300.0, "knockback": 200.0, "pellets": 8, "projectile": "bullet", "incendiary": true,
		"ammo_type": "shell", "ammo_start": 14, "ammo_box": 5, "ammo_max": 30, "sound": "shotgun", "sound_db": 2.5, "pitch": 0.94, "sound2": "fire_whoosh", "sound2_db": -6.0, "style": "dbreath", "barrel": 22.0, "category": "shotgun"},
	{"name": "ANTI-MATERIEL", "unlock_level": 36, "color": Color("5ab0ff"), "damage": 3.5, "sniper": true, "scope": true, "fire_rate": 1.4, "magazine_size": 5, "reload_time": 1.6,
		"range": 7000.0, "spread": 0.0, "recoil": 1.4, "bullet_speed": 5000.0, "knockback": 320.0, "pierce": 8, "projectile": "bullet",
		"ammo_type": ".50", "ammo_start": 10, "ammo_box": 4, "ammo_max": 20, "sound": "sniper", "sound_db": 3.0, "pitch": 0.78, "sound2": "boom_50", "sound2_db": 1.0, "style": "hsniper", "barrel": 42.0, "category": "precision"},
	{"name": "MARKSMAN RIFLE", "unlock_level": 37, "color": Color("c0c890"), "damage": 1.7, "fire_rate": 0.24, "magazine_size": 12, "reload_time": 1.0,
		"range": 3000.0, "spread": 0.006, "recoil": 0.45, "bullet_speed": 3400.0, "knockback": 100.0, "pierce": 1, "projectile": "bullet",
		"ammo_type": "rifle", "ammo_start": 36, "ammo_box": 12, "ammo_max": 72, "sound": "rifle", "sound_db": -0.5, "pitch": 1.12, "sound2": "thud_auto", "sound2_db": -3.0, "style": "dmr", "barrel": 31.0, "category": "precision"},
	{"name": "MINIGUN", "unlock_level": 45, "color": Color("e0e0e8"), "damage": 0.55, "head_mult": 0.5, "fire_rate": 0.065, "magazine_size": 70, "reload_time": 3.0,
		"range": 1600.0, "spread": 0.09, "recoil": 0.2, "kick": 0.006, "bullet_speed": 2600.0, "knockback": 50.0, "pierce": 1, "projectile": "bullet", "spin_up": 0.4,
		"ammo_type": "minigun", "ammo_start": 140, "ammo_box": 35, "ammo_max": 140, "sound": "smg", "sound_db": -3.0, "pitch": 0.82, "sound2": "thud_auto", "sound2_db": -5.0, "style": "minigun", "barrel": 30.0, "category": "auto"},
	{"name": "RAILGUN", "unlock_level": 50, "color": Color("60d8ff"), "damage": 4.5, "sniper": true, "scope": true, "fire_rate": 0.9, "magazine_size": 4, "reload_time": 1.8,
		"range": 7000.0, "spread": 0.0, "recoil": 1.0, "bullet_speed": 7000.0, "knockback": 360.0, "pierce": 20, "projectile": "bullet",
		"ammo_type": "slug", "ammo_start": 12, "ammo_box": 4, "ammo_max": 24, "sound": "sniper", "sound_db": 2.0, "pitch": 1.45, "sound2": "rail_zap", "sound2_db": 0.0, "style": "rail", "barrel": 38.0, "category": "precision"},
]

# מזהים נוחים
enum { RIFLE, SHOTGUN, BOW, SNIPER, TASER, PISTOL, SMG, ASSAULT_RIFLE, MOLOTOV, GRENADE_LAUNCHER, ASSAULT_SHOTGUN, ROCKET_LAUNCHER,
	REVOLVER, DOUBLE_BARREL, LEVER_ACTION, CROSSBOW, FLAMETHROWER, LMG, DRAGONS_BREATH, ANTI_MATERIEL, MARKSMAN, MINIGUN, RAILGUN }


# נשק שהוסר מהמשחק ("removed": true) או שהוא SPECIAL ("special": true - מולוטוב / משגר רימונים / משגר טילים:
# פריט חד-פעמי שמוצאים בשלב, progression/arsenal.gd -> SPECIALS) - לא בגלגל, לא בחנות, לא בהתקדמות.
# נשארים ברשימה רק כדי שה-id של השאר לא ישתנו (והנתונים שלהם משמשים את ה-SPECIAL).
static func removed(id: int) -> bool:
	return id < 0 or id >= WEAPONS.size() or bool(WEAPONS[id].get("removed", false)) or bool(WEAPONS[id].get("special", false))


static func count() -> int:
	return WEAPONS.size()


static func get_def(id: int) -> Dictionary:
	return WEAPONS[clampi(id, 0, WEAPONS.size() - 1)]


# ערך של שדה, עם ברירת מחדל
static func val(id: int, field: String, default: Variant = null) -> Variant:
	return get_def(id).get(field, default)


# עמודה שלמה (למשל כל השמות) - game_state.gd בונה ממנה את WEAPON_NAMES וכו'
static func column(field: String, default: Variant = null) -> Array:
	var out := []
	for w in WEAPONS:
		out.append(w.get(field, default))
	return out
