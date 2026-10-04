extends Control
# ============================================================
#  UPGRADE SHOP - החנות שאחרי כל שלב. קונים בגרוטאות (SCRAP).
#  3 לשוניות: WEAPONS / ABILITIES / PERKS. רשימה עם דפים (7 בכל דף) - מוכן ל-35 נשקים
#  ו-24 יכולות. בוחרים פריט משמאל, ומימין רואים את מסלולי השדרוג שלו עם כפתור BUY.
#  * נשק נפתח לשדרוג אחרי שמצאת אותו פעם אחת (Game.seen_weapons).
#  * יכולת נפתחת כשמגיעים לשלב שלה (abilities/ability_db.gd -> unlock_level).
#  הנתונים והמחירים: progression/upgrade_db.gd. כאן רק התצוגה.
#  signal closed - כשלוחצים BACK.
# ============================================================
signal closed

const ButtonScript := preload("res://menu_button.gd")
const Upgrades := preload("res://progression/upgrade_db.gd")
const WeaponDB := preload("res://weapons/weapon_db.gd")
const AbilityDB := preload("res://abilities/ability_db.gd")
const Sfx := preload("res://sfx.gd")

const PER_PAGE := 7
const TABS := ["WEAPONS", "ABILITIES", "PERKS"]
const TAB_COLS := [Color("d8a033"), Color("8a7aff"), Color("5ad08a")]

var _tab := 0
var _page := 0
var _sel := 0          # אינדקס בתוך הרשימה של הלשונית
var _flash := 0.0
var _btns: Control      # לשוניות + BACK (לא זזים)
var _content: Control   # הרשימה, הפאנל באמצע וכפתורי הקנייה - מחליקים יחד כשמחליפים לשונית
var _detail: Control    # מצייר את הפאנל באמצע
var _clip: Control
var _ci: CanvasItem     # על מה _txt מצייר כרגע
var _slide := 0.0       # היסט ההחלקה (פיקסלים). חיובי = נכנס מימין

const SLIDE_DIST := 420.0
var _built := false    # אחרי הבנייה הראשונה הלשוניות ו-BACK כבר לא עושים אנימציית כניסה


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	process_mode = Node.PROCESS_MODE_ALWAYS
	_btns = Control.new()
	_btns.set_anchors_preset(Control.PRESET_FULL_RECT)
	_btns.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_btns)
	var vp := get_viewport_rect().size
	_clip = Control.new()   # חותך את התוכן למסגרת בזמן ההחלקה
	_clip.position = Vector2(vp.x * 0.5 - 520.0, 90.0)
	_clip.size = Vector2(1040.0, 480.0)
	_clip.clip_contents = true
	_clip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_clip)
	_content = Control.new()
	_content.size = vp
	_content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_clip.add_child(_content)
	_detail = Control.new()
	_detail.size = vp
	_detail.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_detail.draw.connect(_draw_detail)
	_content.add_child(_detail)
	_ci = self
	_slide = SLIDE_DIST   # בפתיחה: נכנס מימין
	_rebuild()


func _reached() -> int:   # השלב הכי רחוק שהגעת אליו (אותו כלל כמו במשחק)
	return Game.reached_level()


# ---- הפריטים בלשונית: [מפתח, שם, נעול?, טקסט נעילה] ----
func _items() -> Array:
	var out := []
	match _tab:
		0:
			for id in WeaponDB.count():
				var seen: bool = id in Game.seen_weapons
				out.append({"kind": "w", "id": id, "name": str(WeaponDB.val(id, "name", "?")) if seen else "???", "locked": not seen,
					"why": "FIND IT FIRST (STAGE %d+)" % int(WeaponDB.val(id, "unlock_level", 1)), "color": WeaponDB.val(id, "color", Color.WHITE)})
		1:
			for a in AbilityDB.ABILITIES:
				var lock: bool = int(a.unlock_level) > _reached()
				out.append({"kind": "a", "id": a.id, "name": a.name if not lock else "???", "locked": lock,
					"why": "UNLOCKS AT STAGE %d" % int(a.unlock_level), "color": a.color})
		2:
			for p in Upgrades.PERKS:
				out.append({"kind": "p", "id": p.id, "name": p.name, "locked": false, "why": "", "color": Color("5ad08a")})
	return out


# ---- המסלולים של פריט: [מפתח שמירה, שם, תיאור, בסיס, tier, מקס] ----
func _tracks(it: Dictionary) -> Array:
	var out := []
	match it.kind:
		"w":
			var tier := Upgrades.weapon_tier(it.id)
			for t in Upgrades.weapon_tracks(it.id):
				var d: Dictionary = Upgrades.WEAPON_TRACKS[t]
				out.append([Upgrades.weapon_key(it.id, t), d.name, d.desc, int(d.base), tier, Upgrades.MAX_LEVEL])
		"a":
			var tier: int = int(AbilityDB.val(it.id, "unlock_level", 1))
			var passive: bool = AbilityDB.val(it.id, "passive", false)
			for t in Upgrades.ABILITY_TRACKS:
				if passive and t == "cooldown":
					continue
				var d: Dictionary = Upgrades.ABILITY_TRACKS[t]
				var desc: String = d.desc
				var base: int = int(d.base)
				if t == "power":   # יכולת יכולה להגדיר תיאור/מחיר משלה (למשל JETPACK: זמן טיסה)
					desc = str(AbilityDB.val(it.id, "power_desc", desc))
					base = int(AbilityDB.val(it.id, "power_base", base))
				out.append([Upgrades.ability_key(it.id, t), d.name, desc, base, tier, Upgrades.MAX_LEVEL])
		"p":
			var p := Upgrades.perk_def(it.id)
			out.append([Upgrades.perk_key(it.id), p.name, p.desc, int(p.base), int(p.tier), int(p.max)])
	return out


func _btn(text: String, pos: Vector2, sz: Vector2, accent: Color, fs := 18, delay := 0.0, slides := true) -> Control:
	var b := ButtonScript.new()
	b.text = text
	b.font_size = fs
	b.accent = accent
	b.position = pos
	b.size = sz
	b.appear_delay = delay
	if slides:   # חלק מהתוכן: בלי אנימציית הכניסה של הכפתור עצמו - כל התוכן מחליק יחד
		b._appear = 1.0
		_content.add_child(b)
	else:
		if _built:
			b._appear = 1.0
		_btns.add_child(b)
	return b


func _rebuild() -> void:
	for c in _btns.get_children():
		c.queue_free()
	for c in _content.get_children():
		if c != _detail:
			c.queue_free()
	var vp := get_viewport_rect().size
	var x0 := vp.x * 0.5 - 520.0
	for i in TABS.size():   # לשוניות
		var b := _btn(TABS[i], Vector2(x0 + 30.0 + float(i) * 170.0, 150.0), Vector2(160, 40), TAB_COLS[i] if i == _tab else Color("4a4a52"), 18, 0.0, false)
		b.pressed.connect(_set_tab.bind(i))
	var items := _items()
	var pages := maxi(1, int(ceil(float(items.size()) / float(PER_PAGE))))
	_page = clampi(_page, 0, pages - 1)
	for k in PER_PAGE:   # רשימת הפריטים
		var i := _page * PER_PAGE + k
		if i >= items.size():
			break
		var it: Dictionary = items[i]
		var acc: Color = Color("4a4a52") if it.locked else (it.color if i == _sel else Color(it.color).darkened(0.45))
		var b := _btn(str(it.name), Vector2(x0 + 30.0, 205.0 + float(k) * 44.0), Vector2(300, 38), acc, 16)
		b.pressed.connect(_select.bind(i))
	if pages > 1:   # דפים
		_btn("<", Vector2(x0 + 30.0, 520.0), Vector2(60, 36), Color("5a5a62"), 18).pressed.connect(_set_page.bind(_page - 1))
		_btn(">", Vector2(x0 + 270.0, 520.0), Vector2(60, 36), Color("5a5a62"), 18).pressed.connect(_set_page.bind(_page + 1))
	# כפתורי קנייה
	if _sel < items.size() and not items[_sel].locked:
		var tr := _tracks(items[_sel])
		for j in tr.size():
			var t: Array = tr[j]
			var c := Upgrades.next_cost(t[0], t[3], t[4], t[5])
			var label := "MAX" if c < 0 else "BUY %d" % c
			var ok := c >= 0 and Game.scrap >= c
			var b := _btn(label, Vector2(x0 + 880.0, 262.0 + float(j) * 64.0), Vector2(140, 42), Color("d8a033") if ok else Color("4a4a52"), 16)
			if c >= 0:
				b.pressed.connect(_buy.bind(t))
	# יכולת: באיזה מקום (1-5) היא נמצאת. לוחצים = מציידים אותה במקום הזה
	if _tab == 1 and _sel < items.size() and not items[_sel].locked:
		var aid: String = items[_sel].id
		for k in 5:
			var here: bool = k < Game.ability_slots.size() and Game.ability_slots[k] == aid
			var b := _btn(str(k + 1), Vector2(x0 + 560.0 + float(k) * 52.0, 500.0), Vector2(46, 40), Color("8a7aff") if here else Color("4a4a52"), 18)
			b.pressed.connect(_equip.bind(aid, k))
	_btn("BACK", Vector2(vp.x * 0.5 - 100.0, 580.0), Vector2(200, 56), Color("b3121a"), 26, 0.0, false).pressed.connect(func(): closed.emit())
	_built = true


func _equip(aid: String, k: int) -> void:
	while Game.ability_slots.size() < 5:
		Game.ability_slots.append(null)
	for i in 5:
		if Game.ability_slots[i] == aid:
			Game.ability_slots[i] = null
	Game.ability_slots[k] = aid
	Game._save()
	Sfx.play("weapon", null, -4.0)
	_rebuild()


func _set_tab(i: int) -> void:
	if i == _tab:
		return
	_slide = SLIDE_DIST * signf(float(i - _tab))   # לשונית ימינה -> נכנס מימין, שמאלה -> משמאל
	_tab = i
	_page = 0
	_sel = 0
	Sfx.play("ui", null)
	_rebuild()


func _set_page(p: int) -> void:
	_page = p
	_sel = _page * PER_PAGE
	_rebuild()


func _select(i: int) -> void:
	_sel = i
	Sfx.play("ui", null)
	_rebuild()


func _buy(t: Array) -> void:
	if Upgrades.buy(t[0], t[3], t[4], t[5]):
		_flash = 1.0
		Sfx.play("pickup", null)
	else:
		Sfx.play("empty", null)
	_rebuild()


func _process(delta: float) -> void:
	_flash = maxf(_flash - delta * 2.0, 0.0)
	_slide = lerpf(_slide, 0.0, 1.0 - exp(-11.0 * delta))
	if absf(_slide) < 0.5:
		_slide = 0.0
	_content.position = Vector2(_slide, 0.0) - _clip.position
	_content.modulate.a = 1.0 - clampf(absf(_slide) / SLIDE_DIST, 0.0, 1.0) * 0.9
	queue_redraw()
	_detail.queue_redraw()


func _txt(pos: Vector2, t: String, size: int, col: Color, align := HORIZONTAL_ALIGNMENT_LEFT, width := -1.0) -> void:
	var f := ThemeDB.fallback_font
	_ci.draw_string_outline(f, pos, t, align, width, size, 4, Color(0, 0, 0, 0.75))
	_ci.draw_string(f, pos, t, align, width, size, col)


func _draw() -> void:
	var vp := get_viewport_rect().size
	var x0 := vp.x * 0.5 - 520.0
	draw_rect(Rect2(x0, 90, 1040, 480), Color(0.05, 0.05, 0.07, 0.92))
	draw_rect(Rect2(x0, 90, 1040, 480), Color(TAB_COLS[_tab], 0.5), false, 2.0)
	_txt(Vector2(x0, 128), "UPGRADES", 34, Color("d8a033"), HORIZONTAL_ALIGNMENT_CENTER, 1040)
	_txt(Vector2(x0 + 700, 128), "SCRAP: %d" % Game.scrap, 22, Color(1, 1, 1).lerp(Color("ffd34a"), _flash), HORIZONTAL_ALIGNMENT_RIGHT, 320)


# הפאנל שזז עם הלשונית (רשימה/דפים, אייקון, שם, תיאור, מסלולי שדרוג)
func _draw_detail() -> void:
	_ci = _detail
	_draw_detail_body()
	_ci = self


func _draw_detail_body() -> void:
	var vp := get_viewport_rect().size
	var x0 := vp.x * 0.5 - 520.0
	var items := _items()
	var pages := maxi(1, int(ceil(float(items.size()) / float(PER_PAGE))))
	if pages > 1:
		_txt(Vector2(x0 + 100, 544), "PAGE %d / %d" % [_page + 1, pages], 14, Color(1, 1, 1, 0.6), HORIZONTAL_ALIGNMENT_CENTER, 160)
	if _sel >= items.size():
		return
	var it: Dictionary = items[_sel]
	var px := x0 + 360.0
	_ci.draw_rect(Rect2(px, 196, 660, 360), Color(1, 1, 1, 0.03))
	# אייקון + שם + תיאור
	var ic := Vector2(px + 60, 240)
	if it.locked:
		_txt(Vector2(px + 20, 250), "LOCKED", 24, Color(1, 1, 1, 0.5))
		_txt(Vector2(px + 20, 280), it.why, 16, Color(1, 0.7, 0.4, 0.8))
		return
	match it.kind:
		"w":
			load("res://weapon_wheel.gd").draw_weapon(_ci, ic, it.id, 1.2)
		"a":
			AbilityDB.draw_icon(_ci, ic, it.id, 1.6)
		"p":
			_ci.draw_circle(ic, 14, Color(0.35, 0.8, 0.5, 0.8))
	_txt(Vector2(px + 120, 230), str(it.name), 24, it.color)
	var desc := ""
	if it.kind == "a":
		desc = str(AbilityDB.val(it.id, "desc", ""))
	elif it.kind == "w":
		var w := Upgrades.weapon_def(it.id)
		desc = "DMG x%.2f   RATE %.2fs   MAG %d   RELOAD %.1fs" % [float(w.get("damage", 1.0)), float(w.fire_rate), int(w.get("magazine_size", 0)), float(w.get("reload_time", 0.0))]
	_txt(Vector2(px + 120, 254), desc, 13, Color(0.8, 0.78, 0.75), HORIZONTAL_ALIGNMENT_LEFT, 520)
	if it.kind == "a":
		_txt(Vector2(px + 20, 494), "EQUIP IN SLOT:", 15, Color(0.8, 0.78, 1.0))
	# מסלולים
	var tr := _tracks(it)
	for j in tr.size():
		var t: Array = tr[j]
		var y := 284.0 + float(j) * 64.0
		_txt(Vector2(px + 20, y), t[1], 18, Color.WHITE)
		_txt(Vector2(px + 20, y + 18), t[2], 12, Color(0.75, 0.72, 0.7))
		var lvl := Upgrades.level_of(t[0])
		for k in int(t[5]):
			var c := Vector2(px + 330 + float(k) * 22.0, y - 4.0)
			_ci.draw_circle(c, 7.0, Color(0, 0, 0, 0.6))
			_ci.draw_circle(c, 5.5, Color("d8a033") if k < lvl else Color(0.25, 0.22, 0.2))
