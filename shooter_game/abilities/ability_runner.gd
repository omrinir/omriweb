extends Node
# ============================================================
#  ABILITY RUNNER - היכולות שהדמות מחזיקה (5 מקומות, Game.ability_slots).
#  נוצר ע"י player.gd. C = הפעלת היכולת שנבחרה. בוחרים יכולת בגלגל (Q, עמוד ABILITIES)
#  או במקשים 6-0 (= מקומות 1-5 של היכולות).
#  יכולות שנפתחות (abilities/ability_db.gd -> unlock_level) נכנסות לבד למקום פנוי.
# ============================================================
const AbilityDB := preload("res://abilities/ability_db.gd")
const Upgrades := preload("res://progression/upgrade_db.gd")
const Sfx := preload("res://sfx.gd")

var player: Node = null
var cur := 0
var _inst := {}        # id -> מופע של היכולת
var _cd := {}          # id -> כמה שניות נשארו
var _c_was := false
var uses := 0          # לבדיקות


func _ready() -> void:
	_fill_slots()
	for i in 5:
		if slot(i) != "":
			cur = i
			break
	for id in _equipped():
		var a := _ability(id)
		if a != null:
			a.on_level_start()


# מכניס יכולות שנפתחו למקומות פנויים
func _fill_slots() -> void:
	while Game.ability_slots.size() < 5:
		Game.ability_slots.append(null)
	for id in AbilityDB.unlocked(Game.reached_level()):
		if id in Game.ability_slots:
			continue
		var placed := false
		for i in 5:
			if Game.ability_slots[i] == null:
				Game.ability_slots[i] = id
				placed = true
				break
		# המקומות מלאים: יכולת שנפתחה בשלב הזה מחליפה את הכי ישנה (בחנות אפשר לבחור אחרת)
		if not placed and int(AbilityDB.val(id, "unlock_level", 1)) == Game.reached_level():
			var oldest := 0
			for i in 5:
				if int(AbilityDB.val(str(Game.ability_slots[i]), "unlock_level", 99)) < int(AbilityDB.val(str(Game.ability_slots[oldest]), "unlock_level", 99)):
					oldest = i
			Game.ability_slots[oldest] = id


func slot(i: int) -> String:
	if i < 0 or i >= Game.ability_slots.size() or Game.ability_slots[i] == null:
		return ""
	return str(Game.ability_slots[i])


func _equipped() -> Array:
	var out := []
	for i in 5:
		if slot(i) != "":
			out.append(slot(i))
	return out


func _ability(id: String) -> RefCounted:
	if id == "":
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


func select(i: int) -> void:
	if slot(i) == "":
		return
	cur = i
	Sfx.play("ui", null)
	player._say(str(AbilityDB.val(slot(i), "name", "")), AbilityDB.val(slot(i), "color", Color.WHITE))


func cooldown_left(id: String) -> float:
	return maxf(float(_cd.get(id, 0.0)), 0.0)


func cooldown_k(id: String) -> float:   # 0 = מוכן, 1 = הרגע הופעל
	var total := Upgrades.ability_cooldown(id)
	return clampf(cooldown_left(id) / maxf(total, 0.01), 0.0, 1.0)


func is_active(id: String) -> bool:
	var a := _ability(id)
	return a != null and a.active()


func use_current() -> bool:
	var id := slot(cur)
	if id == "" or player.dead:
		return false
	if AbilityDB.val(id, "passive", false):
		player._say("PASSIVE", Color(1, 1, 1, 0.7))
		return false
	if cooldown_left(id) > 0.0:
		Sfx.play("empty", null, -6.0)
		return false
	var a := _ability(id)
	if a == null or not a.activate():
		Sfx.play("empty", null, -6.0)
		return false
	_cd[id] = Upgrades.ability_cooldown(id)
	uses += 1
	return true


# מכה קטלנית: יכולת פסיבית מצילה? (LAST BREATH)
func on_lethal_hit() -> bool:
	for id in _equipped():
		var a := _ability(id)
		if a != null and a.on_lethal_hit():
			return true
	return false


func _process(delta: float) -> void:
	if player == null:
		return
	for id in _cd.keys():
		_cd[id] = float(_cd[id]) - delta
	for id in _inst:
		_inst[id].process(delta)
	var c: bool = player.controllable and not player.wheel_open and not get_tree().paused and Input.is_physical_key_pressed(KEY_C)
	if c and not _c_was:
		use_current()
	_c_was = c


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo) or player == null or not player.controllable:
		return
	var k: int = event.physical_keycode
	if k >= KEY_6 and k <= KEY_9:
		select(k - KEY_6)
	elif k == KEY_0:
		select(4)
