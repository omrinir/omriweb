extends Node
# ============================================================
#  ABILITY RUNNER - בר POWERS אחד: כל היכולות שנפתחו + הפריט המיוחד שמחזיקים (רימונים, משגר, לייזר...).
#  נוצר ע"י player.gd.
#    C              = שימוש ב-POWER שנבחר (יכולת, או הפריט: נזרק / נורה לכיוון הכוונת)
#    E / גלגלת      = ה-POWER הבא / הקודם
#    6-0            = POWER 1-5 בבר,  Q (עמוד POWERS) = בחירה בגלגל
#  יכולת נכנסת לבר לבד כשמגיעים לשלב שלה (abilities/ability_db.gd -> unlock_level). אין מקומות ואין מאגר.
#  "item" = הפריט המיוחד (player.special). כשלוקחים פריט הוא נבחר, כשהוא נגמר חוזרים ליכולת הקודמת.
# ============================================================
const AbilityDB := preload("res://abilities/ability_db.gd")
const Upgrades := preload("res://progression/upgrade_db.gd")
const Sfx := preload("res://sfx.gd")
const ITEM := "item"

var player: Node = null
var cur_id := ""       # ה-POWER שנבחר (id של יכולת, או ITEM)
var _prev_id := ""     # מה היה נבחר לפני שלקחנו פריט
var _inst := {}        # id -> מופע של היכולת
var _cd := {}          # id -> כמה שניות נשארו
var _c_was := false
var _was_on := {}      # יכולות "cd_after": היו פעילות בפריים הקודם
var uses := 0          # לבדיקות


func _ready() -> void:
	var list := powers()
	for id in list:   # יכולת שנפתחה בשלב הזה = מוכנה ל-C מיד
		if id != ITEM and int(AbilityDB.val(id, "unlock_level", 1)) == Game.reached_level():
			cur_id = id
	if cur_id == "" and not list.is_empty():
		cur_id = list[0]
	for id in list:
		var a := _ability(id)
		if a != null:
			a.on_level_start()


# הבר: יכולות שנפתחו (לפי סדר הפתיחה) ואחריהן הפריט, אם יש
func powers() -> Array:
	var out := AbilityDB.unlocked(Game.reached_level())
	if player != null and player.special != "":
		out.append(ITEM)
	return out


# תאימות: ה-POWER במקום i בבר ("" = אין)
func slot(i: int) -> String:
	var list := powers()
	return str(list[i]) if i >= 0 and i < list.size() else ""


# המקום של ה-POWER הנבחר בבר
var cur: int:
	get:
		return powers().find(cur_id)


func select(i: int) -> void:
	select_id(slot(i))


func select_id(id: String) -> void:
	if id == "" or not id in powers():
		return
	cur_id = id
	Sfx.play("ui", null)
	player._say(power_name(id), power_color(id))


# dir = 1 הבא, -1 הקודם (מסתובב)
func cycle(dir: int) -> void:
	var list := powers()
	if list.is_empty():
		return
	var i := list.find(cur_id)
	select_id(str(list[posmod(i + dir, list.size())]))


func power_name(id: String) -> String:
	if id == ITEM:
		return str(player.Arsenal.SPECIALS[player.special].name) if player != null and player.special != "" else ""
	return str(AbilityDB.val(id, "name", ""))


func power_color(id: String) -> Color:
	if id == ITEM:
		return player.Arsenal.SPECIALS[player.special].color if player != null and player.special != "" else Color.WHITE
	return AbilityDB.val(id, "color", Color.WHITE)


# נקרא מ-player.take_special: הפריט נבחר כדי ש-C ישתמש בו מיד
func on_item_taken() -> void:
	if cur_id != ITEM:
		_prev_id = cur_id
	cur_id = ITEM


func cooldown_left(id: String) -> float:
	if id == ITEM:
		return 0.0
	return maxf(float(_cd.get(id, 0.0)), 0.0)


func cooldown_k(id: String) -> float:   # 0 = מוכן, 1 = הרגע הופעל
	if id == ITEM:
		return 0.0
	var total := Upgrades.ability_cooldown(id)
	return clampf(cooldown_left(id) / maxf(total, 0.01), 0.0, 1.0)


func is_active(id: String) -> bool:
	if id == ITEM:
		return false
	var a := _ability(id)
	return a != null and a.active()


func _ability(id: String) -> RefCounted:
	if id == "" or id == ITEM:
		return null
	if not _inst.has(id):
		var path := AbilityDB.script_path(id)
		if not ResourceLoader.exists(path):
			return null
		var a = load(path).new()
		a.id = id
		a.player = player
		a.power = Upgrades.ability_power(id)
		_inst[id] = a
	return _inst[id]


func use_current() -> bool:
	var id := cur_id
	if id == "" or player.dead:
		return false
	if id == ITEM:
		if not player.use_item():
			Sfx.play("empty", null, -6.0)
			return false
		uses += 1
		return true
	var a := _ability(id)
	if a != null and a.active() and AbilityDB.val(id, "cd_after", false) and a.has_method("stop"):   # C שוב = כיבוי
		a.stop()
		return true
	if cooldown_left(id) > 0.0:
		Sfx.play("empty", null, -6.0)
		return false
	if a == null or not a.activate():
		Sfx.play("empty", null, -6.0)
		return false
	if not AbilityDB.val(id, "cd_after", false):
		_cd[id] = Upgrades.ability_cooldown(id)
	uses += 1
	return true


# מכה קטלנית: יכולת פסיבית מצילה? (אין כרגע יכולות כאלה)
func on_lethal_hit() -> bool:
	for id in _inst:
		if _inst[id].on_lethal_hit():
			return true
	return false


func _process(delta: float) -> void:
	if player == null:
		return
	if cur_id == ITEM and player.special == "":   # הפריט נגמר: חוזרים ליכולת שהייתה
		var list := powers()
		cur_id = _prev_id if _prev_id in list else (str(list[0]) if not list.is_empty() else "")
	for id in _cd.keys():
		_cd[id] = float(_cd[id]) - delta
	for id in _inst:
		_inst[id].process(delta)
		if AbilityDB.val(id, "cd_after", false):   # נגמר האפקט -> מתחיל ה-cooldown
			var on: bool = _inst[id].active()
			if _was_on.get(id, false) and not on:
				var k: float = _inst[id].cooldown_scale() if _inst[id].has_method("cooldown_scale") else 1.0
				_cd[id] = Upgrades.ability_cooldown(id) * k
			_was_on[id] = on
	var c: bool = player.controllable and not player.wheel_open and not get_tree().paused and Input.is_physical_key_pressed(KEY_C)
	if c and not _c_was:
		use_current()
	_c_was = c


func _unhandled_input(event: InputEvent) -> void:
	if player == null or not player.controllable or player.dead or player.wheel_open:
		return
	if event is InputEventMouseButton and event.pressed:   # גלגלת = ה-POWER הבא / הקודם
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			cycle(1)
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
			cycle(-1)
		return
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	var k: int = event.physical_keycode
	if k == KEY_E:
		cycle(1)
	elif k >= KEY_6 and k <= KEY_9:
		select(k - KEY_6)
	elif k == KEY_0:
		select(4)
