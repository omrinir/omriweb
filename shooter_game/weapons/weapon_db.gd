extends RefCounted
# ============================================================
#  WEAPON DATABASE - כל הנשקים במשחק מוגדרים כאן (ולא בתוך player.gd)
#
#  איך מוסיפים נשק חדש:
#    1. מוסיפים מילון חדש בסוף WEAPONS (ה-id = המיקום ברשימה).
#    2. אם צריך צליל חדש - מוסיפים אותו ל-weapons/weapon_sounds.gd.
#    3. אייקון בגלגל הנשקים: weapon_wheel.gd -> draw_weapon (לפי "icon").
#       הציור ביד של הדמות נבחר לפי "style" (player.gd -> _draw_rifle).
#    4. כדי שיופיע בשלב: levels/stage_N.gd -> weapon_offers().
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
#    unlock_level       - באיזה שלב הנשק מופיע לראשונה (משפיע על מחיר השדרוגים שלו)
#    category           - auto / shotgun / precision / explosive / other  (PlayerMemory משתמש בזה כדי "ללמוד" את השחקן)
# ============================================================

const WEAPONS := [
	{"name": "RIFLE", "unlock_level": 1, "color": Color("d8c070"), "damage": 1.0, "fire_rate": 0.7, "magazine_size": 8, "reload_time": 0.5,
		"range": 1800.0, "spread": 0.0, "recoil": 0.5, "bullet_speed": 2600.0, "knockback": 60.0, "projectile": "bullet",
		"ammo_type": "rifle", "ammo_start": 30, "ammo_box": 10, "ammo_max": 60, "sound": "rifle", "style": "rifle", "barrel": 25.0, "category": "precision"},
	{"name": "SHOTGUN", "unlock_level": 1, "color": Color("e07a3a"), "falloff": [9.0, 1.0, 420.0], "fire_rate": 1.0, "magazine_size": 6, "reload_time": 1.2,
		"range": 900.0, "spread": 0.16, "recoil": 2.2, "bullet_speed": 2400.0, "knockback": 150.0, "pellets": 6, "projectile": "bullet",
		"ammo_type": "shell", "ammo_start": 8, "ammo_box": 3, "ammo_max": 16, "sound": "shotgun", "sound_db": 2.0, "style": "shotgun", "barrel": 22.0, "category": "shotgun"},
	{"name": "BOW", "removed": true, "unlock_level": 1, "color": Color("8ac060"), "fixed_damage": [13, 19], "fire_rate": 0.8, "magazine_size": 0,
		"range": 3400.0, "spread": 0.0, "recoil": 0.0, "bullet_speed": 1150.0, "knockback": 40.0, "projectile": "arrow",
		"ammo_type": "arrow", "ammo_start": 12, "ammo_box": 4, "ammo_max": 20, "sound": "bow", "sound_db": -2.0, "style": "bow", "barrel": 20.0, "category": "precision"},
	{"name": "SNIPER", "unlock_level": 2, "color": Color("7ad0ff"), "damage": 1.0, "sniper": true, "fire_rate": 1.5, "magazine_size": 5, "reload_time": 1.1,
		"range": 6000.0, "spread": 0.0, "recoil": 0.7, "bullet_speed": 4200.0, "knockback": 120.0, "pierce": 3, "projectile": "bullet",
		"ammo_type": "sniper", "ammo_start": 5, "ammo_box": 2, "ammo_max": 10, "sound": "sniper", "sound_db": 1.0, "style": "sniper", "barrel": 35.0, "category": "precision"},
	{"name": "TASER", "unlock_level": 2, "color": Color("b080ff"), "fire_rate": 0.9, "magazine_size": 0, "recoil": 0.1, "projectile": "taser",
		"ammo_type": "battery", "ammo_start": 6, "ammo_box": 2, "ammo_max": 12, "sound": "taser", "sound_db": -2.0, "style": "taser", "barrel": 20.0, "category": "other"},
	# ---- שלב 5+ ----
	{"name": "PISTOL", "unlock_level": 5, "color": Color("c8c8d0"), "damage": 0.5, "fire_rate": 0.38, "magazine_size": 12, "reload_time": 0.5,
		"range": 1300.0, "spread": 0.025, "recoil": 0.1, "bullet_speed": 2400.0, "knockback": 40.0, "projectile": "bullet",
		"ammo_type": "9mm", "ammo_start": 36, "ammo_box": 12, "ammo_max": 96, "sound": "pistol", "style": "pistol", "barrel": 14.0, "category": "precision"},
	{"name": "SMG", "unlock_level": 5, "color": Color("f0d040"), "damage": 0.25, "head_mult": 0.4, "fire_rate": 0.13, "magazine_size": 30, "reload_time": 0.8,
		"range": 1100.0, "spread": 0.13, "recoil": 0.15, "kick": 0.025, "bullet_speed": 2300.0, "knockback": 22.0, "projectile": "bullet",
		"ammo_type": "9mm", "ammo_start": 90, "ammo_box": 24, "ammo_max": 150, "sound": "smg", "sound_db": -3.0, "style": "smg", "barrel": 17.0, "category": "auto"},
	{"name": "ASSAULT RIFLE", "unlock_level": 6, "color": Color("9ad070"), "damage": 0.45, "head_mult": 0.5, "fire_rate": 0.2, "magazine_size": 30, "reload_time": 0.9,
		"range": 2000.0, "spread": 0.05, "recoil": 0.25, "kick": 0.012, "bullet_speed": 2800.0, "knockback": 50.0, "projectile": "bullet",
		"ammo_type": "rifle", "ammo_start": 60, "ammo_box": 24, "ammo_max": 120, "sound": "ar", "sound_db": -1.0, "style": "ar", "barrel": 26.0, "category": "auto"},
	{"name": "MOLOTOV", "unlock_level": 6, "color": Color("ff8a30"), "fire_rate": 0.9, "magazine_size": 0, "recoil": 0.0, "bullet_speed": 640.0, "projectile": "molotov",
		"ammo_type": "bottle", "ammo_start": 3, "ammo_box": 1, "ammo_max": 6, "sound": "throw", "style": "bottle", "barrel": 10.0, "category": "explosive"},
	{"name": "GRENADE LAUNCHER", "unlock_level": 8, "color": Color("80b060"), "fire_rate": 1.1, "magazine_size": 4, "reload_time": 1.4, "recoil": 0.9,
		"bullet_speed": 950.0, "knockback": 0.0, "projectile": "launcher",
		"ammo_type": "40mm", "ammo_start": 6, "ammo_box": 2, "ammo_max": 12, "sound": "launcher", "style": "launcher", "barrel": 24.0, "category": "explosive"},
	{"name": "ASSAULT SHOTGUN", "unlock_level": 8, "color": Color("ff5a3a"), "falloff": [11.0, 2.0, 460.0], "fire_rate": 0.32, "magazine_size": 8, "reload_time": 1.3,
		"range": 950.0, "spread": 0.19, "recoil": 1.5, "bullet_speed": 2400.0, "knockback": 170.0, "pellets": 7, "projectile": "bullet",
		"ammo_type": "shell", "ammo_start": 16, "ammo_box": 6, "ammo_max": 40, "sound": "ashotgun", "style": "ashotgun", "barrel": 24.0, "category": "shotgun"},
	{"name": "ROCKET LAUNCHER", "unlock_level": 14, "color": Color("e05a30"), "damage": 1.0, "fire_rate": 0.95, "magazine_size": 2, "reload_time": 1.2, "recoil": 1.3,
		"bullet_speed": 640.0, "knockback": 0.0, "projectile": "rocket",
		"ammo_type": "rocket", "ammo_start": 4, "ammo_box": 2, "ammo_max": 10, "sound": "rocket", "style": "rocket", "barrel": 30.0, "category": "explosive"},
]

# מזהים נוחים
enum { RIFLE, SHOTGUN, BOW, SNIPER, TASER, PISTOL, SMG, ASSAULT_RIFLE, MOLOTOV, GRENADE_LAUNCHER, ASSAULT_SHOTGUN, ROCKET_LAUNCHER }


# נשק שהוסר מהמשחק ("removed": true) - נשאר ברשימה רק כדי שה-id של השאר לא ישתנו
static func removed(id: int) -> bool:
	return id < 0 or id >= WEAPONS.size() or bool(WEAPONS[id].get("removed", false))


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
