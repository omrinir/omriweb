extends CanvasLayer
# ============================================================
#  UNLOCK BANNER - הרגע של "NEW WEAPON" / "NEW ABILITY" / "WEAPON MOD".
#  main.gd מוסיף אחד לכל שלב (קבוצה "unlock_banner") עם items = מה השלב נותן (progression/arsenal.gd -> rewards).
#   * בתחילת השלב (אחרי כותרת השלב): כרטיס לכל פריט - אייקון, שם, מה עושים איתו.
#   * כשאוספים נשק חדש / MOD: player.gd / arsenal.gd קוראים ל-picked_weapon / picked_mod -> כרטיס מיידי.
#  בזמן סצנת סיפור (group "story_scene") ממתינים.
#  לשנות: START_DELAY, SHOW_T.
# ============================================================
const Monologue := preload("res://ui/monologue.gd")
const AbilityDB := preload("res://abilities/ability_db.gd")
const WeaponDB := preload("res://weapons/weapon_db.gd")
const Sfx := preload("res://sfx.gd")

const START_DELAY := 5.0    # אחרי כותרת השלב (hud.gd _draw_intro = 5 שניות)
const SHOW_T := 3.6         # כמה זמן כל כרטיס
const PICK_T := 2.6         # כרטיס של איסוף

var items := []             # [{"kind": "weapon"/"ability"/"mod", "id": ...}]
var _queue := []            # כרטיסים שמחכים: {"kind", "id", "head", "name", "sub", "col", "t"}
var _cur := {}
var _k := 0.0               # כמה זמן הכרטיס הנוכחי על המסך
var _wait := START_DELAY
var _ui: Node2D
var _time := 0.0


func _ready() -> void:
	layer = 6
	add_to_group("unlock_banner")
	_ui = Node2D.new()
	add_child(_ui)
	_ui.draw.connect(_draw_card)
	for it in items:
		_queue.append(_card_for(it))


func _card_for(it: Dictionary) -> Dictionary:
	match str(it.kind):
		"weapon":
			var id := int(it.id)
			return {"kind": "weapon", "id": id, "head": "NEW WEAPON", "name": str(WeaponDB.val(id, "name", "?")),
				"sub": "IT'S WAITING AHEAD  -  WALK OVER IT", "col": WeaponDB.val(id, "color", Color.WHITE), "t": SHOW_T}
		"ability":
			var aid := str(it.id)
			var si: int = Game.ability_slots.find(aid)
			var how := ("READY - PRESS C   (KEY %d)" % ((si + 6) % 10)) if si >= 0 else "EQUIP IT: Q WHEEL -> ABILITIES"
			if AbilityDB.val(aid, "passive", false):
				how = "PASSIVE - ALWAYS ON"
			return {"kind": "ability", "id": aid, "head": "NEW ABILITY", "name": str(AbilityDB.val(aid, "name", "?")),
				"sub": str(AbilityDB.val(aid, "desc", "")), "hint": how, "col": AbilityDB.val(aid, "color", Color.WHITE), "t": SHOW_T + 1.2}
		_:
			return {"kind": "mod", "id": -1, "head": "WEAPON MOD", "name": "FREE UPGRADE",
				"sub": "PICK IT UP AHEAD: UPGRADES THE GUN IN YOUR HANDS", "col": Color("5ad0ff"), "t": SHOW_T}


# נאסף נשק חדש (gone = הנשק שהוחלף, "" = נכנס למקום פנוי)
func picked_weapon(id: int, gone: String) -> void:
	_push_now({"kind": "weapon", "id": id, "head": "NEW WEAPON", "name": str(WeaponDB.val(id, "name", "?")),
		"sub": ("SWAPPED OUT YOUR %s  (IT'S ON THE FLOOR)" % gone) if gone != "" else _weapon_line(id),
		"col": WeaponDB.val(id, "color", Color.WHITE), "t": PICK_T, "stamp": true})


func picked_mod(wid: int, track: String, lvl: int) -> void:
	var nm := track if wid < 0 else "%s  %s  LV %d" % [str(WeaponDB.val(wid, "name", "?")), track, lvl]
	_push_now({"kind": "mod", "id": wid, "head": "WEAPON MOD", "name": nm, "sub": "FREE UPGRADE - KEEP IT FOR THE WHOLE RUN",
		"col": Color("5ad0ff"), "t": PICK_T, "stamp": true})


func _weapon_line(id: int) -> String:
	var w: Dictionary = WeaponDB.get_def(id)
	var mag := int(w.get("magazine_size", 0))
	return "%s  ·  %s" % [str(w.get("category", "")).to_upper(), ("MAG %d" % mag) if mag > 0 else "NO RELOAD"]


func _push_now(c: Dictionary) -> void:
	if not _cur.is_empty() and not _cur.get("stamp", false):   # כרטיס של תחילת השלב שהופרע - חוזר אחר כך
		_queue.push_front(_cur)
	_cur = c
	_k = 0.0
	_wait = 0.0
	Sfx.play("streak_up", null, -1.0)


func _process(delta: float) -> void:
	_time += delta
	if not get_tree().get_nodes_in_group("story_scene").is_empty():   # סצנת סיפור: מחכים
		_ui.queue_redraw()
		return
	if _cur.is_empty():
		_wait -= delta
		if _wait <= 0.0 and not _queue.is_empty():
			_cur = _queue.pop_front()
			_k = 0.0
			Sfx.play("streak_up" if _cur.kind != "mod" else "pickup", null, -3.0)
	else:
		_k += delta
		if _k >= float(_cur.t):
			_cur = {}
			_wait = 0.35
	_ui.queue_redraw()


func _draw_card() -> void:
	if _cur.is_empty() or not get_tree().get_nodes_in_group("story_scene").is_empty():
		return
	var t := float(_cur.t)
	var a := clampf(_k / 0.25, 0.0, 1.0) * clampf((t - _k) / 0.4, 0.0, 1.0)
	var pop := 1.0 + 0.18 * maxf(0.0, 1.0 - _k / 0.22)   # קפיצה קטנה בכניסה
	var vs := _ui.get_viewport().get_visible_rect().size
	var col: Color = _cur.col
	var f := Monologue.font()
	var ci := _ui.get_canvas_item()
	var name_fs := int(34.0 * pop)
	var sub: String = str(_cur.sub)
	var hint: String = str(_cur.get("hint", ""))
	var nw := f.get_string_size(str(_cur.name), HORIZONTAL_ALIGNMENT_LEFT, -1, name_fs).x
	var fb := ThemeDB.fallback_font
	var sw := minf(maxf(fb.get_string_size(sub, HORIZONTAL_ALIGNMENT_LEFT, -1, 14).x, fb.get_string_size(hint, HORIZONTAL_ALIGNMENT_LEFT, -1, 14).x), 560.0)
	var bw := maxf(maxf(nw, sw), 220.0) + 160.0
	var two := fb.get_string_size(sub, HORIZONTAL_ALIGNMENT_LEFT, -1, 14).x > 560.0   # תיאור ארוך = שתי שורות
	var bh := 96.0 + (20.0 if hint != "" else 0.0) + (17.0 if two else 0.0)
	var y := vs.y * 0.6 + (1.0 - clampf(_k / 0.25, 0.0, 1.0)) * 24.0
	var r := Rect2(vs.x * 0.5 - bw * 0.5, y - bh * 0.5, bw, bh)
	# פס כהה רך מאחור + מסגרת בצבע הפריט
	_ui.draw_rect(Rect2(0, r.position.y - 10.0, vs.x, r.size.y + 20.0), Color(0, 0, 0, 0.22 * a))
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.05, 0.05, 0.07, 0.88 * a)
	sb.border_color = Color(col, a)
	sb.set_border_width_all(3)
	sb.set_corner_radius_all(12)
	_ui.draw_style_box(sb, r)
	var shine := fposmod(_k * 0.9, 1.6) - 0.3   # ברק שעובר על הכרטיס
	if shine > 0.0 and shine < 1.0:
		var sx := r.position.x + r.size.x * shine
		_ui.draw_colored_polygon(PackedVector2Array([Vector2(sx, r.position.y + 3), Vector2(sx + 26, r.position.y + 3), Vector2(sx + 6, r.end.y - 3), Vector2(sx - 20, r.end.y - 3)]), Color(1, 1, 1, 0.06 * a))
	# אייקון
	var ic := Vector2(r.position.x + 62.0, r.position.y + 50.0)
	_ui.draw_circle(ic, 40.0, Color(col, 0.12 * a))
	_ui.draw_circle(ic, 30.0 + 3.0 * sin(_time * 5.0), Color(col, 0.1 * a))
	match str(_cur.kind):
		"weapon":
			load("res://weapon_wheel.gd").draw_weapon(_ui, ic, int(_cur.id), 1.05, a)
		"ability":
			AbilityDB.draw_icon(_ui, ic, str(_cur.id), 1.9, a)
		_:
			if int(_cur.id) >= 0:
				load("res://weapon_wheel.gd").draw_weapon(_ui, ic + Vector2(0, 4), int(_cur.id), 0.8, a)
			_ui.draw_colored_polygon(PackedVector2Array([ic + Vector2(14, -6), ic + Vector2(14, -16), ic + Vector2(9, -16), ic + Vector2(18, -26), ic + Vector2(27, -16), ic + Vector2(22, -16), ic + Vector2(22, -6)]), Color(1.0, 0.83, 0.3, a))
	# טקסט
	var tx := r.position.x + 124.0
	var head: String = str(_cur.head)
	f.draw_string_outline(ci, Vector2(tx, r.position.y + 28.0), head, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, 5, Color(0, 0, 0, a))
	f.draw_string(ci, Vector2(tx, r.position.y + 28.0), head, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(1.0, 0.85, 0.35, a))
	f.draw_string_outline(ci, Vector2(tx, r.position.y + 62.0), str(_cur.name), HORIZONTAL_ALIGNMENT_LEFT, -1, name_fs, 7, Color(0, 0, 0, a))
	f.draw_string(ci, Vector2(tx, r.position.y + 62.0), str(_cur.name), HORIZONTAL_ALIGNMENT_LEFT, -1, name_fs, Color(col.lerp(Color.WHITE, 0.25), a))
	_ui.draw_multiline_string(fb, Vector2(tx, r.position.y + 84.0), sub, HORIZONTAL_ALIGNMENT_LEFT, 560.0, 14, 2, Color(0.88, 0.88, 0.92, 0.9 * a))
	if hint != "":
		_ui.draw_string(fb, Vector2(tx, r.position.y + 104.0 + (17.0 if two else 0.0)), hint, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(col.lerp(Color.WHITE, 0.4), a))
