extends RefCounted
# ============================================================
#  קישוטים לשלב 39 ("THE STADIUM") - המרקנה בלילה של משחק. אזור חמישי, שלב 3.
#  קערת יציעים ענקית מלאה בקהל זומבים שקופץ, גג טבעת לבן עם שורות זרקורים, זיקוקים (סינליזדורס) ועשן אדום-ירוק,
#  דגלים ענקיים, שלטי לד סביב המגרש, מסלול ריצה ודשא. בסוף - השער והשוער.
#    stadium_sky   - (רקע) לילה, הילת זרקורים לבנה, עשן צבעוני שנסחף, זיקוקים
#    far_stands    - (רקע) היציע שממול: גג טבעת, זרקורים, אלפי צופים קופצים (נקודות), דגלים, להבות סינליזדור
#    mid_boards    - (רקע) שלטי לד סביב המגרש שמתחלפים, צלמים, ספסלים
#    TrackGround   - (עולם) מסלול ריצה אדום עם קווים לבנים -> דשא מפוספס (מ-grass_from)
#    Stand         - (עולם) יציע קרוב: מדרגות מושבים, קהל זומבים, מעבר עליון (הקומה = add_floor)
#    CrowdHype     - (עולם) "THE 12TH MAN": קאפו עם מגפון ותוף על המעבר, מד CROWD HYPE -> PITCH INVASION (אוהדים קופצים למסלול)
#    Floodlight    - (עולם, מלכודת) מגדל זרקור שסורק את המסלול: נכנסת לאור -> כל הזומבים יודעים איפה אתה
#    Goal          - (עולם) השער (רשת + קורות) מאחורי השוער
#    Obstacle      - (מוצק + מחסה) "ad_board" שלט פרסומת נייד / "bench" ספסל מחליפים / "cooler" ארגזי שתייה
#    StadiumFX     - (מסך) קונפטי ונייר, הילה
#  לשנות: CrowdHype (GAIN, KILL_GAIN, INVASION_FANS, CAPO_HP, DRUM_HP...), Floodlight.SPEED / SPAN / ALERT_R.
# ============================================================

const Art := preload("res://art.gd")
const Sfx := preload("res://sfx.gd")
const Kit := preload("res://effects/backdrop_kit.gd")
const Particles := preload("res://particles.gd")

const TEAM := [Color("e0d020"), Color("2a8a3a"), Color("e8e8e8"), Color("c02a2a"), Color("2a4ab0")]


static func _rng(s: int) -> RandomNumberGenerator:
	var r := RandomNumberGenerator.new()
	r.seed = s
	return r


static func _h(i: int, s: int) -> float:
	return fposmod(sin(float(i) * 127.1 + float(s) * 311.7) * 43758.5453, 1.0)


# ---- לילה עם הילת זרקורים ----
static func stadium_sky(ci: CanvasItem, v: Vector2, t: float) -> void:
	Kit.gradient_sky(ci, v, [Color("070a18"), Color("101a34"), Color("1e2a4a"), Color("3a4a6a")], 0.9)
	Art.glow(ci, Vector2(v.x * 0.5, v.y * 0.55), v.x * 0.6, Color(0.9, 0.95, 1.0, 0.12))
	for i in 5:   # עשן סינליזדורים שנסחף מעל
		var cx := fposmod(float(i) * 300.0 + t * 12.0, v.x + 400.0) - 200.0
		var c := Color(0.8, 0.2, 0.2, 0.12) if i % 2 == 0 else Color(0.2, 0.7, 0.3, 0.1)
		ci.draw_colored_polygon(Art.ellipse(Vector2(cx, v.y * (0.3 + 0.05 * float(i % 3))), 180.0, 40.0, 0.0, 14), c)
	var cyc := fposmod(t, 6.0)   # זיקוק
	if cyc < 1.2:
		var k := floori(t / 6.0)
		var c0 := Vector2(v.x * (0.2 + 0.6 * _h(k, 3)), v.y * (0.12 + 0.1 * _h(k, 4)))
		var col: Color = TEAM[k % TEAM.size()]
		for q in 14:
			var d := Vector2.from_angle(float(q) / 14.0 * TAU) * cyc * 60.0
			ci.draw_circle(c0 + d + Vector2(0, cyc * cyc * 10.0), 2.0, Color(col, 1.0 - cyc / 1.2))


# ---- היציע שממול ----
static func far_stands(ci: CanvasItem, sc: float, v: Vector2, y: float, t: float) -> void:
	var top := y - 250.0
	ci.draw_rect(Rect2(0, top, v.x, y - top), Color("1a1e2e"))
	# גג טבעת לבן עם זרקורים
	ci.draw_rect(Rect2(0, top - 30.0, v.x, 22.0), Color("c8ccd8"))
	ci.draw_rect(Rect2(0, top - 8.0, v.x, 8.0), Color("8a8e9a"))
	var lx := -fposmod(sc * 0.3, 40.0)
	while lx < v.x:
		ci.draw_rect(Rect2(lx, top - 6.0, 26.0, 5.0), Color(1.0, 1.0, 0.95))
		lx += 40.0
	Art.glow(ci, Vector2(v.x * 0.5, top), v.x * 0.5, Color(1, 1, 1, 0.1))
	# הקהל: שורות של נקודות צבעוניות שקופצות
	var rows := 14
	for r in rows:
		var ry := top + 12.0 + float(r) * ((y - top - 20.0) / float(rows))
		var step := 7.0
		var x := -fposmod(sc * 0.3, step)
		var i := int(floor(sc * 0.3 / step))
		while x < v.x:
			var hsh := _h(i * 31 + r, 5)
			var jump := maxf(sin(t * 7.0 + float(i) * 0.9 + float(r)), 0.0) * 2.5 if hsh > 0.4 else 0.0
			var c: Color = TEAM[int(hsh * 10.0) % TEAM.size()].darkened(0.35 + 0.02 * float(rows - r))
			ci.draw_rect(Rect2(x, ry - jump, 4.0, 4.0), c)
			x += step
			i += 1
	var period := 700.0
	var start := int(floor(sc * 0.3 / period)) - 1
	for k in range(start, start + int(ceil(v.x / period)) + 2):
		var fx := float(k) * period - sc * 0.3 + _h(k, 2) * 300.0
		var fy := top + 60.0 + _h(k, 6) * 80.0
		var fc: Color = TEAM[k % TEAM.size()]
		var w := sin(t * 2.0 + float(k)) * 6.0   # דגל ענק על הקהל
		ci.draw_colored_polygon(PackedVector2Array([Vector2(fx, fy), Vector2(fx + 120, fy + w), Vector2(fx + 118, fy + 50 - w), Vector2(fx - 2, fy + 50)]), Color(fc, 0.85))
		ci.draw_line(Vector2(fx + 10, fy + 25), Vector2(fx + 110, fy + 25), Color(1, 1, 1, 0.5), 3.0)
		var fl := Vector2(fx + 200.0, fy + 70.0)   # סינליזדור
		Art.glow(ci, fl, 30.0, Color(1.0, 0.3, 0.2, 0.5 + 0.2 * sin(t * 20.0 + float(k))))
		ci.draw_circle(fl, 3.0, Color(1.0, 0.85, 0.7))
	ci.draw_rect(Rect2(0, y - 6.0, v.x, v.y - y + 6.0), Color("2a3a2a"))


# ---- שלטי לד סביב המגרש ----
static func mid_boards(ci: CanvasItem, sc: float, v: Vector2, y: float, t: float) -> void:
	ci.draw_rect(Rect2(0, y - 34.0, v.x, 34.0), Color("101014"))
	var seg := 220.0
	var start := int(floor(sc / seg)) - 1
	for k in range(start, start + int(ceil(v.x / seg)) + 2):
		var x := float(k) * seg - sc
		var phase := int(t * 0.5 + float(k) * 0.3) % 3
		var c: Color = TEAM[(k + phase) % TEAM.size()]
		ci.draw_rect(Rect2(x + 2.0, y - 30.0, seg - 4.0, 24.0), c.darkened(0.45))
		var tx := fposmod(t * 80.0 + float(k) * 40.0, seg) - 40.0   # טקסט רץ
		for q in 4:
			ci.draw_rect(Rect2(x + tx + float(q) * 14.0, y - 24.0, 10.0, 12.0), Color(c.lightened(0.3), 0.9))
		if k % 3 == 1:   # צלם עם מצלמה
			var cx := x + 120.0
			ci.draw_rect(Rect2(cx, y - 64.0, 10.0, 30.0), Color("16161c"))
			ci.draw_circle(Vector2(cx + 5.0, y - 68.0), 5.0, Color("16161c"))
			ci.draw_rect(Rect2(cx + 8.0, y - 66.0, 18.0, 10.0), Color("16161c"))
			ci.draw_rect(Rect2(cx + 26.0, y - 64.0, 8.0, 6.0), Color("2a2a34"))
	ci.draw_rect(Rect2(0, y - 6.0, v.x, v.y - y + 6.0), Color("2a3a2a"))


# ---- מסלול ריצה ודשא ----
class TrackGround extends Node2D:
	var w := 1024.0
	var depth := 90.0
	var grass := false

	func _ready() -> void:
		z_index = 1

	func _draw() -> void:
		if grass:   # דשא מפוספס
			draw_rect(Rect2(0, 0, w, depth), Color("2a6a2a"))
			var x := 0.0
			var i := int(global_position.x / 80.0)
			while x < w:
				draw_rect(Rect2(x, 0, 80.0, depth), Color("327a32") if i % 2 == 0 else Color("2a6a2a"))
				x += 80.0
				i += 1
			draw_line(Vector2(0, 2), Vector2(w, 2), Color(0.95, 0.95, 0.95, 0.8), 2.0)
			for q in int(w / 12.0):
				draw_line(Vector2(float(q) * 12.0, 0), Vector2(float(q) * 12.0 + 2.0, -4.0), Color("3a8a3a"), 1.0)
			return
		draw_rect(Rect2(0, 0, w, depth), Color("a83a2a"))   # טרטן
		for q in 4:
			draw_line(Vector2(0, 4.0 + float(q) * 9.0), Vector2(w, 4.0 + float(q) * 9.0), Color(1, 1, 1, 0.55), 1.2)
		draw_rect(Rect2(0, 0, w, 2.0), Color("d0d0d0"))


# ---- יציע קרוב עם קהל + המעבר העליון ----
class Stand extends Node2D:
	var w := 420.0
	var tier := 130.0
	var _t := 0.0
	var angry := 0.0                # (CrowdHype) כמה הקהל מתלהב - קמים ומנופפים

	func _ready() -> void:
		z_index = -1

	func _process(delta: float) -> void:
		_t += delta
		if Engine.get_process_frames() % 3 == 0 and Art.on_screen(self, global_position + Vector2(w * 0.5, -tier), w):
			queue_redraw()

	func _draw() -> void:
		var S := preload("res://effects/s39_decor.gd")
		# מדרגות בטון עם כיסאות פלסטיק צבעוניים
		var rows := 6
		for rr in rows:   # מלמעלה למטה - כל שורה מכסה רק את הרגליים של השורה שמעליה
			var r := rows - 1 - rr
			var ry := -tier - 20.0 - float(r) * 22.0
			draw_rect(Rect2(-10, ry, w + 20, 22), Color("3a3a44").lightened(0.03 * float(r)))
			var x := 6.0
			var i := 0
			while x < w - 8.0:
				var c: Color = S.TEAM[(i + r) % 2 * 1 + (0 if r % 3 == 0 else 2)]
				draw_rect(Rect2(x, ry + 6, 10, 8), c.darkened(0.25))
				# צופה זומבי (לא בכל כיסא)
				if S._h(i * 7 + r, 3) < 0.6:
					var up := angry * (6.0 + 3.0 * sin(_t * 12.0 + float(i)))
					var bob := maxf(sin(_t * 6.0 + float(i) * 0.8 + float(r)), 0.0) * 2.0
					var sk := Color("7a8a70").darkened(S._h(i, r) * 0.3)
					var shirt: Color = S.TEAM[int(S._h(i, r + 9) * 10.0) % S.TEAM.size()]
					draw_rect(Rect2(x + 1, ry - 6 - bob - up * 0.4, 8, 10), shirt.darkened(0.2))
					draw_circle(Vector2(x + 5, ry - 9 - bob - up * 0.4), 3.5, sk)
					if angry > 0.2:   # ידיים למעלה
						draw_line(Vector2(x + 1, ry - 4 - bob), Vector2(x - 2, ry - 12 - up), sk, 1.5)
						draw_line(Vector2(x + 9, ry - 4 - bob), Vector2(x + 12, ry - 12 - up), sk, 1.5)
				x += 14.0
				i += 1
		# קיר היציע (מתחת למעבר) + שלט
		draw_rect(Rect2(-10, -tier, w + 20, tier), Color("2a2a34"))
		draw_rect(Rect2(20, -tier + 30, w - 40, 26), Color("1a1a22"))
		for q in 5:
			draw_rect(Rect2(30.0 + float(q) * (w - 60.0) / 5.0, -tier + 36, (w - 80.0) / 5.0, 14), S.TEAM[q].darkened(0.3))
		draw_rect(Rect2(w * 0.4, -70, 60, 70), Color("101016"))   # מנהרה
		draw_rect(Rect2(-10, -tier - 4, w + 20, 6), Color("8a8a94"))   # מעקה המעבר
		for q in int(w / 24.0) + 1:
			draw_line(Vector2(-8.0 + float(q) * 24.0, -tier - 4), Vector2(-8.0 + float(q) * 24.0, -tier - 18), Color("8a8a94"), 1.5)
		draw_line(Vector2(-10, -tier - 18), Vector2(w + 10, -tier - 18), Color("9a9aa4"), 2.0)


# ---- הקהל: "THE 12TH MAN" ----
#  בכל יציע קרוב עומד CAPO (מנהיג האוהדים) על המעבר העליון: מגפון ותוף ענק. מעל היציע - מד CROWD HYPE.
#  ההיפ עולה כשאתה נלחם ליד היציע (GAIN לשנייה), והרבה יותר כשאתה הורג זומבים לידו (KILL_GAIN - הרגת את הקבוצה שלהם).
#  100% = PITCH INVASION: היציע מתפרץ, אוהדים (זומבים רצים בחולצות הקבוצה) קופצים מעל המעקה למסלול ומסתערים,
#    ונורים זיקוקים בוערים לידך (שטח בוער קטן). אחר כך ההיפ מתאפס ועולה שוב לאט יותר (MAX_INVASIONS לכל יציע).
#  לירות ב-CAPO (CAPO_HP) = היציע משתתק לגמרי.
#  "THEY LEARN": אחרי שקאפו אחד מת - האחרים מתכופפים מאחורי התוף ברגע שאתה מכוון אליהם (התוף סופג, DRUM_HP).
#    שובר את התוף -> אין לו איפה להתחבא. או לעלות אליו מהצד / לירות מהר בלי לכוון עליו זמן רב.
#  לשנות: GAIN, KILL_GAIN, NEAR, INVASION_FANS, MAX_INVASIONS, MAX_FANS, CAPO_HP, DRUM_HP, COOLDOWN, AIM_COS.
class CrowdHype extends Node2D:
	const GAIN := 6.5
	const KILL_GAIN := 9.0
	const NEAR := 800.0
	const DECAY := 9.0
	const INVASION_FANS := [4, 6, 7]
	const MAX_INVASIONS := 3
	const MAX_FANS := 10            # אוהדים חיים מכל היציעים ביחד
	const CAPO_HP := 45
	const DRUM_HP := 70
	const COOLDOWN := 8.0
	const AIM_COS := 0.985          # כמה ישר צריך לכוון עליו כדי שיתכופף (~10 מעלות)
	const FLARES := 3
	const CAPO_SCALE := 1.4         # הקאפו והתוף גדולים מהקהל - שיהיה ברור במי לירות
	var stand: Node2D = null
	var w := 420.0
	var tier := 130.0
	var hype := 0.0
	var invasions := 0              # לבדיקות
	var fans_spawned := 0
	var ducks := 0
	var capo_hp := CAPO_HP
	var drum_hp := DRUM_HP
	var capo_dead := false
	var ducking := false
	var _cd := 0.0
	var _queue := 0
	var _spawn_t := 0.0
	var _banner := 0.0
	var _quiet := 0.0
	var _t := 0.0
	var _beat := 0.0
	var _beat_anim := 0.0
	var _hit := 0.0
	var _duck_t := 0.0
	var _told := false
	var _body: StaticBody2D = null

	func _ready() -> void:
		z_index = 1
		add_to_group("crowds")
		_body = CapoBody.new()
		_body.crowd = self
		_body.position = Vector2(w * 0.5 + 8.0 * CAPO_SCALE, -tier - 22.0 * CAPO_SCALE)
		add_child(_body)
		Game.story.connect(_on_story)

	func center() -> Vector2:
		return global_position + Vector2(w * 0.5, -tier)

	func learned() -> bool:   # כבר מת קאפו אחד בשלב הזה?
		var m := get_parent()
		return m != null and int(m.get_meta("capos_down", 0)) > 0

	func _on_story(ev: String, info: Dictionary) -> void:
		if ev != "zkill" or capo_dead or _cd > 0.0 or invasions >= MAX_INVASIONS:
			return
		var zz = info.get("z")
		if zz != null and is_instance_valid(zz) and absf(zz.global_position.x - center().x) < 700.0:
			hype = minf(hype + KILL_GAIN, 100.0)

	# ---- פגיעה בקאפו / בתוף ----
	func hit(amount: int, at: Vector2, src: Dictionary) -> void:
		if capo_dead:
			return
		var dmg := int(src.get("fixed", amount))
		var Sfx := preload("res://sfx.gd")
		if ducking and drum_hp > 0:   # התוף סופג
			drum_hp -= dmg
			Sfx.play("st_drum", at, -2.0, 0.2, 3)
			preload("res://particles.gd").burst(get_parent(), at, "spark", Vector2.UP, 3)
			if drum_hp <= 0:
				_text("THE DRUM IS BROKEN", Color("ffe060"))
			return
		capo_hp -= dmg
		_hit = 0.1
		preload("res://particles.gd").burst(get_parent(), at, "hit", Vector2.UP, 8)
		if capo_hp <= 0:
			_capo_die()

	func _capo_die() -> void:
		capo_dead = true
		ducking = false
		hype = 0.0
		_queue = 0
		_quiet = 3.0
		_body.collision_layer = 0
		var m := get_parent()
		m.set_meta("capos_down", int(m.get_meta("capos_down", 0)) + 1)
		var Sfx := preload("res://sfx.gd")
		Sfx.play("zdeath", center(), 0.0, 0.1, 2)
		Sfx.play("st_boo", center() + Vector2(0, -120), 0.0, 0.05, 2)
		preload("res://particles.gd").burst(m, center() + Vector2(8, -30), "hit", Vector2.UP, 18)
		_text("THE CAPO IS DOWN - THE STAND GOES QUIET", Color("e0e0e0"))
		Game.on_zombie_killed(0, {"pos": center() + Vector2(8, -50), "zone": "", "source": "capo"})

	func _text(s: String, col: Color) -> void:
		var p = preload("res://zombie.gd").HitText.new()
		p.text = s
		p.color = col
		p.size = 15
		get_parent().add_child(p)
		p.global_position = center() + Vector2(8, -70)

	func _physics_process(delta: float) -> void:
		_t += delta
		_hit -= delta
		_banner -= delta
		_quiet -= delta
		_beat_anim -= delta
		var pl := get_tree().get_first_node_in_group("player")
		if pl == null:
			return
		var c := center()
		if not capo_dead:
			# מתכופף מאחורי התוף כשמכוונים אליו (רק אחרי שלמדו)
			if learned() and drum_hp > 0 and not pl.dead:
				var from: Vector2 = pl.global_position + Vector2(0, -36)
				var to := c + Vector2(8, -24) * CAPO_SCALE - from
				if to.length() < 1000.0 and pl._aim.dot(to.normalized()) > AIM_COS:
					if _duck_t <= 0.0:
						ducks += 1
						preload("res://sfx.gd").play("st_drum", c, -4.0, 0.1, 2)
						if not _told:
							_told = true
							_text("HE HIDES BEHIND THE DRUM", Color("ffe060"))
					_duck_t = 0.6
			_duck_t -= delta
			ducking = _duck_t > 0.0
			# ההיפ
			var near: bool = not pl.dead and absf(pl.global_position.x - c.x) < NEAR and absf(pl.global_position.y - global_position.y) < 420.0
			if _cd > 0.0:
				_cd -= delta
			elif near and invasions < MAX_INVASIONS:
				hype = minf(hype + GAIN * (1.0 - 0.2 * float(invasions)) * delta, 100.0)
			else:
				hype = maxf(hype - DECAY * delta, 0.0)
			if hype >= 100.0:
				_invade(pl)
			# התוף: מהר יותר כשההיפ עולה
			_beat -= delta
			if hype > 20.0 and _beat <= 0.0:
				_beat = lerpf(0.75, 0.26, hype / 100.0)
				_beat_anim = 0.12
				if Art.on_screen(self, c, 300.0):
					preload("res://sfx.gd").play("st_drum", c, lerpf(-12.0, -3.0, hype / 100.0), 0.05, 3)
		# אוהדים שקופצים מעל המעקה
		if _queue > 0:
			_spawn_t -= delta
			if _spawn_t <= 0.0:
				_spawn_t = 0.22
				_queue -= 1
				_spawn_fan(pl)
		if stand != null:
			var want := 1.0 if _banner > 0.0 else (0.0 if capo_dead else hype / 100.0)
			stand.angry = move_toward(stand.angry, want, delta * 2.0)
		if Art.on_screen(self, c + Vector2(0, -80), w):
			queue_redraw()

	func _invade(pl: Node) -> void:
		invasions += 1
		hype = 0.0
		_cd = COOLDOWN
		_banner = 2.2
		var alive := get_tree().get_nodes_in_group("crowd_fans").size()
		_queue = maxi(0, mini(int(INVASION_FANS[mini(invasions - 1, INVASION_FANS.size() - 1)]), MAX_FANS - alive))
		_spawn_t = 0.35
		preload("res://sfx.gd").play("st_roar", center() + Vector2(0, -100), 4.0, 0.05, 2)
		if pl.has_method("_say") and not pl.dead:
			pl._say("THEY'RE COMING OVER THE WALL!", Color("ffb0a0"))
		for i in FLARES:   # זיקוקים בוערים לכיוון השחקן
			var f := Flare.new()
			var from := global_position + Vector2(randf_range(40.0, w - 40.0), -tier - 60.0 - randf() * 60.0)
			var tx: float = pl.global_position.x + randf_range(-140.0, 140.0)
			var fl := randf_range(0.8, 1.1)
			f.vel = Vector2((tx - from.x) / fl, (global_position.y - from.y) / fl - 0.5 * Flare.GRAV * fl)
			get_parent().add_child(f)
			f.global_position = from

	func _spawn_fan(pl: Node) -> void:
		var m := get_parent()
		if not m.has_method("_spawn_zombie"):
			return
		var S := preload("res://effects/s39_decor.gd")
		var x := global_position.x + randf_range(30.0, w - 30.0)
		var z = m._spawn_zombie(x, global_position.y - tier - 2.0, 1 if randf() < 0.75 else 0)
		z.add_to_group("crowd_fans")
		z.shirt = S.TEAM[randi() % S.TEAM.size()]
		z.dormant = false
		z._alert_t = 30.0
		z._rush_t = 3.0
		z.collision_mask &= ~16   # קופץ מעל המעקה ונופל דרך המעבר למטה, למסלול
		z._drop_t = 0.95
		z.velocity = Vector2(signf(pl.global_position.x - x) * 90.0, -140.0)
		fans_spawned += 1
		preload("res://particles.gd").burst(m, Vector2(x, global_position.y - tier - 10.0), "smoke", Vector2.UP, 3)

	func _draw() -> void:
		var F := preload("res://effects/flame_fx.gd")
		var S := preload("res://effects/s39_decor.gd")
		var font := ThemeDB.fallback_font
		var cx := w * 0.5
		var base := Vector2(cx, -tier)
		# זיקוקים אדומים ביציע כשההיפ גבוה / בפלישה
		var heat := 1.0 if _banner > 0.0 else (0.0 if capo_dead else clampf((hype - 55.0) / 45.0, 0.0, 1.0))
		if heat > 0.0:
			for q in 4:
				var fx := w * (0.15 + 0.23 * float(q))
				var fy := -tier - 50.0 - float(q % 2) * 40.0
				F.glow(self, Vector2(fx, fy), Vector2(26, 26), Color(1.0, 0.25, 0.1, 0.5 * heat))
				F.tongue(self, Vector2(fx, fy + 4.0), 3.0, 10.0 + 4.0 * sin(_t * 9.0 + float(q)), sin(_t * 5.0 + float(q)) * 2.0, F.PALETTE, heat)
				for k in 3:   # עשן אדום
					var kk := fmod(_t * 0.4 + float(k) / 3.0 + float(q) * 0.21, 1.0)
					F.glow(self, Vector2(fx + kk * 30.0, fy - 10.0 - kk * 80.0), Vector2(14, 12) * (1.0 + kk * 2.0), Color(0.7, 0.15, 0.12, 0.35 * (1.0 - kk) * heat))
		# התוף והקאפו (מוגדלים סביב נקודת הבסיס)
		draw_set_transform(base * (1.0 - CAPO_SCALE), 0.0, Vector2(CAPO_SCALE, CAPO_SCALE))
		var drum := base + Vector2(-16, 0)
		var shake := 1.5 if _beat_anim > 0.0 else 0.0
		if drum_hp > 0:
			draw_rect(Rect2(drum + Vector2(-13, -30 + shake), Vector2(26, 30 - shake)), Color("c02a2a"))
			draw_rect(Rect2(drum + Vector2(-13, -30 + shake), Vector2(26, 4)), Color("e8e8e8"))
			draw_rect(Rect2(drum + Vector2(-13, -4), Vector2(26, 4)), Color("e8e8e8"))
			for q in 4:
				draw_line(drum + Vector2(-13.0 + float(q) * 8.7, -26 + shake), drum + Vector2(-9.0 + float(q) * 8.7, -4), Color("e0d020"), 1.2)
		else:   # שבור
			draw_rect(Rect2(drum + Vector2(-13, -12), Vector2(26, 12)), Color("7a1a1a"))
			draw_line(drum + Vector2(-13, -12), drum + Vector2(-4, -20), Color("e8e8e8"), 2.0)
			draw_line(drum + Vector2(13, -12), drum + Vector2(5, -18), Color("e8e8e8"), 2.0)
		# הקאפו
		var cp := base + Vector2(8, 0)
		var sk := Color("7a8a70")
		var shirt := Color("e0d020")
		if _hit > 0.0:
			sk = Color.WHITE
			shirt = Color.WHITE
		if capo_dead:   # שוכב על המעבר
			draw_rect(Rect2(cp + Vector2(-6, -7), Vector2(26, 7)), shirt.darkened(0.3))
			draw_circle(cp + Vector2(23, -4), 4.5, sk.darkened(0.2))
			draw_rect(Rect2(cp + Vector2(-20, -4), Vector2(14, 4)), Color("2a2a34"))
		else:
			var duck := 18.0 if ducking else 0.0
			var bob := (maxf(sin(_t * 9.0), 0.0) * 4.0 * hype / 100.0) if not ducking else 0.0
			var hip := cp + Vector2(0, -16 + duck * 0.5 - bob)
			var sh := cp + Vector2(1, -32 + duck - bob)
			var head := sh + Vector2(2, -8)
			draw_line(hip + Vector2(-2, 0), cp + Vector2(-4, 0), Color("2a2a34"), 4.0)   # רגליים
			draw_line(hip + Vector2(2, 0), cp + Vector2(4, 0), Color("2a2a34"), 4.0)
			draw_colored_polygon(PackedVector2Array([sh + Vector2(-7, 0), sh + Vector2(7, 0), hip + Vector2(6, 0), hip + Vector2(-6, 0)]), shirt)
			draw_line(sh + Vector2(-7, 1), sh + Vector2(7, 1), Color("2a8a3a"), 2.0)
			draw_string(font, sh + Vector2(-4, 12), "12", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color("2a8a3a"))
			draw_circle(head, 5.0, sk)
			draw_circle(head + Vector2(2.5, -0.5), 1.1, Color(1.0, 0.85, 0.4))
			if not ducking:   # מגפון מורם אל המסלול + מקל תוף ביד השנייה
				var hand := sh + Vector2(10, -6 - (3.0 if _beat_anim > 0.0 else 0.0))
				draw_line(sh + Vector2(5, 2), hand, sk, 2.5)
				draw_colored_polygon(PackedVector2Array([hand + Vector2(0, -2), hand + Vector2(10, -6), hand + Vector2(10, 6), hand + Vector2(0, 2)]), Color("e8e8e8"))
				draw_line(sh + Vector2(-5, 2), drum + Vector2(4, -32 + (4.0 if _beat_anim > 0.0 else 0.0)), sk, 2.0)
				if hype > 20.0:   # גלי קול
					for q in 3:
						var r := 8.0 + fmod(_t * 30.0 + float(q) * 8.0, 24.0)
						draw_arc(hand + Vector2(10, 0), r, -0.6, 0.6, 8, Color(1, 1, 1, 0.5 * (1.0 - r / 32.0)), 1.5)
		draw_set_transform_matrix(Transform2D.IDENTITY)
		# מד ההיפ מעל היציע
		var mp := Vector2(cx - 90.0, -tier - 200.0)
		if capo_dead:
			if _quiet > 0.0:
				draw_string(font, mp + Vector2(0, -6), "QUIET", HORIZONTAL_ALIGNMENT_CENTER, 180, 16, Color(0.8, 0.8, 0.8, clampf(_quiet, 0.0, 1.0)))
		else:
			var k := hype / 100.0
			var col := Color("2ab04a").lerp(Color("e0d020"), clampf(k * 2.0, 0.0, 1.0)).lerp(Color("e02a2a"), clampf(k * 2.0 - 1.0, 0.0, 1.0))
			if k > 0.75:
				col = col.lightened(0.25 * maxf(sin(_t * 14.0), 0.0))
			draw_rect(Rect2(mp + Vector2(-3, -3), Vector2(186, 18)), Color(0, 0, 0, 0.65))
			draw_rect(Rect2(mp, Vector2(180.0 * k, 12)), col)
			draw_rect(Rect2(mp, Vector2(180, 12)), Color(1, 1, 1, 0.6), false, 1.5)
			var label := "CROWD HYPE" if _cd <= 0.0 else "CROWD HYPE  (%ds)" % int(ceil(_cd))
			draw_string(font, mp + Vector2(0, -8), label, HORIZONTAL_ALIGNMENT_CENTER, 180, 13, Color(1, 1, 1, 0.9))
		if _banner > 0.0:   # PITCH INVASION!
			var a := clampf(_banner, 0.0, 1.0)
			var sc := 1.0 + 0.08 * sin(_t * 16.0)
			draw_string_outline(font, Vector2(cx - 200, -tier - 230), "PITCH INVASION!", HORIZONTAL_ALIGNMENT_CENTER, 400, int(30 * sc), 6, Color(0, 0, 0, a))
			draw_string(font, Vector2(cx - 200, -tier - 230), "PITCH INVASION!", HORIZONTAL_ALIGNMENT_CENTER, 400, int(30 * sc), Color(1.0, 0.25, 0.15, a))


# אזור הפגיעה של הקאפו (קליעים פוגעים בשכבה 4)
class CapoBody extends StaticBody2D:
	var crowd: Node2D

	func _ready() -> void:
		collision_layer = 4
		collision_mask = 0
		var cs := CollisionShape2D.new()
		var sh := RectangleShape2D.new()
		sh.size = Vector2(20, 40) * CrowdHype.CAPO_SCALE
		cs.shape = sh
		add_child(cs)

	func take_damage(amount: int, hit_pos: Vector2, _dir: Vector2, _explosive := false, src := {}) -> void:
		crowd.hit(amount, hit_pos, src)


# זיקוק בוער שהקהל זורק: נוחת ומשאיר שטח בוער קטן
class Flare extends Node2D:
	const GRAV := 700.0
	var vel := Vector2.ZERO
	var _t := 0.0

	func _ready() -> void:
		z_index = 9

	func _physics_process(delta: float) -> void:
		_t += delta
		vel.y += GRAV * delta
		var to := global_position + vel * delta
		var hit := get_world_2d().direct_space_state.intersect_ray(PhysicsRayQueryParameters2D.create(global_position, to, 1))   # (נופל דרך המעבר העליון - נוחת במסלול)
		if not hit.is_empty() or _t > 3.0:
			var at: Vector2 = hit.position if not hit.is_empty() else to
			var fz = preload("res://environment/fire_zone.gd").new()
			fz.setup(60.0, 2.6)
			get_parent().add_child(fz)
			fz.global_position = at
			preload("res://sfx.gd").play("fire_whoosh", at, -6.0, 0.1, 2)
			queue_free()
			return
		global_position = to
		rotation = vel.angle()
		queue_redraw()

	func _draw() -> void:
		var F := preload("res://effects/flame_fx.gd")
		draw_line(Vector2(-6, 0), Vector2(5, 0), Color("c02a2a"), 3.0)
		F.glow(self, Vector2(6, 0), Vector2(12, 12), Color(1.0, 0.3, 0.15, 0.7))
		draw_circle(Vector2(6, 0), 2.5, Color(1.0, 0.85, 0.6))
		for k in 3:   # עשן אדום נגרר
			var kk := float(k) / 3.0
			F.glow(self, Vector2(-8.0 - kk * 20.0, 0), Vector2(5, 5) * (1.0 + kk), Color(0.8, 0.2, 0.15, 0.4 * (1.0 - kk)))


# ---- מגדל זרקור שסורק ----
class Floodlight extends Node2D:
	const SPEED := 0.35
	const SPAN := 520.0
	const ALERT_R := 900.0
	const HEIGHT := 330.0
	var spotted := 0                # לבדיקות
	var _t := 0.0
	var _cd := 0.0
	var _phase := 0.0

	func _ready() -> void:
		z_index = -1
		_phase = randf() * TAU

	func beam_x() -> float:
		return global_position.x + sin(_t * SPEED * TAU * 0.25 + _phase) * SPAN

	func _physics_process(delta: float) -> void:
		_t += delta
		_cd -= delta
		var pl := get_tree().get_first_node_in_group("player")
		if _cd <= 0.0 and pl != null and not pl.dead and absf(pl.global_position.x - beam_x()) < 40.0 and pl.global_position.y > global_position.y - 260.0:
			_cd = 4.0
			spotted += 1
			preload("res://sfx.gd").play("st_spot", pl.global_position, 0.0, 0.05, 2)
			pl._say("THE LIGHT FOUND ME!", Color("fff4c0"))
			for zz in get_tree().get_nodes_in_group("zombies"):
				if not zz.dead and not zz.is_boss() and zz.global_position.distance_to(pl.global_position) < ALERT_R:
					zz._alert_t = maxf(float(zz._alert_t), 6.0)
					zz._rush_t = 2.0
					if zz.dormant:
						zz._wake()
		if Art.on_screen(self, Vector2(beam_x(), global_position.y - 100.0), SPAN):
			queue_redraw()

	func _draw() -> void:
		var top := Vector2(0, -HEIGHT)
		draw_line(Vector2(-8, 0), top + Vector2(-4, 10), Color("4a4a54"), 4.0)   # המגדל
		draw_line(Vector2(8, 0), top + Vector2(4, 10), Color("4a4a54"), 4.0)
		for q in 8:
			var y := -float(q) * HEIGHT / 8.0
			draw_line(Vector2(-7, y), Vector2(7, y - HEIGHT / 8.0), Color("4a4a54"), 1.0)
		draw_rect(Rect2(top + Vector2(-26, -14), Vector2(52, 20)), Color("2a2a34"))
		for q in 4:
			draw_circle(top + Vector2(-18.0 + float(q) * 12.0, -4.0), 4.5, Color(1.0, 1.0, 0.9))
		var bx := beam_x() - global_position.x
		var spot := _cd > 3.0
		draw_colored_polygon(PackedVector2Array([top + Vector2(-14, 0), top + Vector2(14, 0), Vector2(bx + 50.0, 0), Vector2(bx - 50.0, 0)]), Color(1.0, 0.98, 0.85, 0.12 if not spot else 0.25))
		draw_colored_polygon(Art.ellipse(Vector2(bx, -2), 52.0, 7.0, 0.0, 16), Color(1.0, 0.98, 0.85, 0.3 if not spot else 0.55))


# ---- השער ----
class Goal extends Node2D:
	var w := 220.0
	var h := 150.0

	func _ready() -> void:
		z_index = -2

	func _draw() -> void:
		for q in int(w / 12.0) + 1:   # רשת
			draw_line(Vector2(float(q) * 12.0, -h), Vector2(float(q) * 12.0 + 20.0, 0), Color(1, 1, 1, 0.25), 1.0)
		for q in int(h / 12.0) + 1:
			draw_line(Vector2(0, -float(q) * 12.0), Vector2(w + 20.0, -float(q) * 12.0 + 6.0), Color(1, 1, 1, 0.25), 1.0)
		draw_rect(Rect2(-4, -h - 4, w + 8, 6), Color("f0f0f0"))   # משקוף
		draw_rect(Rect2(-4, -h, 6, h), Color("f0f0f0"))   # קורות
		draw_rect(Rect2(w - 2, -h, 6, h), Color("f0f0f0"))


# ---- מכשולים ----
class Obstacle extends Node2D:
	var kind := "ad_board"
	var size := Vector2(110, 40)
	var seed_v := 0

	func _ready() -> void:
		var body := StaticBody2D.new()
		body.collision_layer = 1
		body.add_to_group("no_outline")
		if size.y >= 30.0:
			add_to_group("cover")
		var cs := CollisionShape2D.new()
		var sh := RectangleShape2D.new()
		sh.size = size
		cs.shape = sh
		cs.position = Vector2(size.x * 0.5, -size.y * 0.5)
		body.add_child(cs)
		add_child(body)
		z_index = 1

	func cover_rect() -> Rect2:
		return Rect2(global_position + Vector2(0.0, -size.y), size)

	func _draw() -> void:
		var r := RandomNumberGenerator.new()
		r.seed = seed_v
		var w := size.x
		var h := size.y
		var S := preload("res://effects/s39_decor.gd")
		match kind:
			"ad_board":   # שלט פרסומת נייד (משולש)
				var c: Color = S.TEAM[r.randi() % S.TEAM.size()]
				Art.fill_shaded(self, PackedVector2Array([Vector2(0, 0), Vector2(w, 0), Vector2(w - 4, -h), Vector2(4, -h)]), c.darkened(0.2), 0.15, 0.35, Art.OUTLINE, 1.2)
				draw_rect(Rect2(10, -h * 0.65, w * 0.6, h * 0.3), Color(1, 1, 1, 0.8))
				draw_circle(Vector2(w * 0.82, -h * 0.5), h * 0.22, Color(1, 1, 1, 0.8))
			"bench":   # ספסל מחליפים עם גג פרספקס
				draw_rect(Rect2(4, -h * 0.35, w - 8, h * 0.12), Color("2a4ab0"))
				for q in 4:
					draw_rect(Rect2(10.0 + float(q) * (w - 20.0) / 4.0, -h * 0.55, (w - 30.0) / 4.0, h * 0.2), Color("2a4ab0").lightened(0.15))
				draw_line(Vector2(4, 0), Vector2(4, -h), Color("8a8a94"), 3.0)
				draw_line(Vector2(w - 4, 0), Vector2(w - 4, -h), Color("8a8a94"), 3.0)
				draw_colored_polygon(PackedVector2Array([Vector2(0, -h), Vector2(w, -h), Vector2(w - 6, -h + 8), Vector2(6, -h + 8)]), Color(0.7, 0.85, 1.0, 0.45))
			_:   # ארגזי שתייה
				for q in 2:
					Art.fill(self, PackedVector2Array([Vector2(2.0 + float(q) * w * 0.5, 0), Vector2(w * 0.5 - 2.0 + float(q) * w * 0.5, 0), Vector2(w * 0.5 - 2.0 + float(q) * w * 0.5, -h * (0.8 + 0.2 * float(q))), Vector2(2.0 + float(q) * w * 0.5, -h * (0.8 + 0.2 * float(q)))]), Color("e04020") if q == 0 else Color("2a8ad0"), Art.OUTLINE, 1.0)
					draw_rect(Rect2(6.0 + float(q) * w * 0.5, -h * 0.55, w * 0.5 - 12.0, 5), Color(1, 1, 1, 0.8))


# ---- קונפטי ונייר על המסך ----
class StadiumFX extends Node2D:
	var vp := Vector2(1280, 720)
	var floor_y := 630.0
	var _t := 0.0

	func _process(delta: float) -> void:
		_t += delta
		if Engine.get_process_frames() % 2 == 0:
			queue_redraw()

	func _draw() -> void:
		var S := preload("res://effects/s39_decor.gd")
		var gy: float = (get_viewport().get_canvas_transform() * Vector2(0, floor_y)).y
		for i in 26:
			var x := fposmod(float(i) * 89.0 + sin(_t + float(i)) * 30.0 + _t * 10.0, vp.x)
			var y := fposmod(float(i) * 53.0 + _t * (40.0 + float(i % 4) * 10.0), maxf(gy, 10.0))
			var c: Color = S.TEAM[i % S.TEAM.size()]
			draw_rect(Rect2(x, y, 4.0, 2.5), Color(c, 0.75))
		draw_rect(Rect2(0, 0, vp.x, vp.y), Color(0.9, 0.95, 1.0, 0.03))
