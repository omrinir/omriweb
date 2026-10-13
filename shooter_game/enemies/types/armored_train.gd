extends "res://enemies/stationary_boss.gd"
# ============================================================
#  ARMORED TRAIN (הבוס של שלב 42, "METRO BARRACKS") - בוס נייח: קטר משוריין של אימפריית המתים עומד ברציף האחרון.
#  לוחות שריון מסומררים, צריח עם תותח על הגג, חרכי מקלע, פנס חזית ענק, מגן-פרות. נהג זומבי בחלון התא = נקודת התורפה.
#  התקפות (stationary_boss.gd):
#    shell - פגז מהצריח בקשת (BLAST)
#    mg    - צרור MG_N כדורים מהחרכים. הפנס דולק ואתה באור -> מדויק. שברת את הפנס (LIGHT_HP) -> יורה עיוור (פיזור גדול).
#            "THEY LEARN": אחרי שהפנס נשבר הוא יורה זיקוקי תאורה (FLARE) לידך - כל עוד אתה ליד זיקוק בוער, הוא שוב מדויק.
#    troops - "ALL OUT!": הדלת נפתחת וקופצים TROOP_N רובאים (כל TROOP_CD, כשנשארו מעט חיילים בסביבה)
#    pound - צמוד אליו: פליטת קיטור
#  לשנות: SHELL_CD, MG_CD, MG_N, LIGHT_HP, FLARE_CD, FLARE_LIFE, FLARE_R, TROOP_CD, TROOP_N.
# ============================================================

const E := preload("res://enemies/empire_kit.gd")

const SOUNDS := {
	"tr_horn": {"drive": 1.6, "layers": [["S", 180, 180, 0.0, 1.0, 0.05, 1.5, 0.35, 1.0, 0.01], ["S", 226, 226, 0.0, 1.0, 0.05, 1.5, 0.3, 1.0, 0.01]]},
	"tr_steam": [["N", 0, 0, 0.0, 0.8, 0.02, 3.0, 0.6, 0.9, 0, 0.8]],
	"tr_cannon": {"drive": 1.8, "layers": [["N", 0, 0, 0.0, 0.6, 0.0, 4.0, 1.0, 0.12, 0], ["S", 80, 40, 0.0, 0.45, 0.0, 6.0, 0.7, 1.0, 0]]},
	"tr_flare": [["N", 0, 0, 0.0, 0.5, 0.0, 6.0, 0.3, 0.7, 0, 0.6], ["S", 600, 1200, 0.0, 0.3, 0.0, 8.0, 0.1, 1.0, 0]],
	"tr_glass": [["N", 0, 0, 0.0, 0.3, 0.0, 10.0, 0.5, 0.15, 0, 0.3], ["S", 3600, 2400, 0.0, 0.2, 0.0, 12.0, 0.15, 1.0, 0.2]],
}

const SHELL_CD := 3.8
const MG_CD := 2.4
const MG_N := 7
const MG_V := 720.0
const BLAST := 80.0
const LIGHT_HP := 3
const FLARE_CD := 6.0
const FLARE_LIFE := 6.0
const FLARE_R := 240.0
const TROOP_CD := 16.0
const TROOP_N := 2

var light_hp := LIGHT_HP
var flares := 0              # לבדיקות
var troops := 0
var blind_shots := 0
var lit_shots := 0
var _shell_cd := 2.2
var _mg_cd := 1.0
var _flare_cd := 1.0
var _troop_cd := 8.0
var _left := 0
var _rate := 0.0
var _door := 0.0
var _recoil := 0.0


class Flare extends Node2D:   # זיקוק תאורה: עף בקשת, נוחת ובוער
	const A := preload("res://art.gd")
	var velocity := Vector2.ZERO
	var life := FLARE_LIFE
	var landed := false
	var _t := 0.0

	func _ready() -> void:
		z_index = 8
		add_to_group("flares")

	func _physics_process(delta: float) -> void:
		_t += delta
		if not landed:
			velocity.y += 900.0 * delta
			var to := global_position + velocity * delta
			var hit := get_world_2d().direct_space_state.intersect_ray(PhysicsRayQueryParameters2D.create(global_position, to, 1 | 16))
			if not hit.is_empty() or _t > 4.0:
				landed = true
				global_position = to if hit.is_empty() else hit.position
			else:
				global_position = to
		else:
			life -= delta
			if life <= 0.0:
				queue_free()
				return
			if Engine.get_physics_frames() % 5 == 0:
				preload("res://particles.gd").burst(get_parent(), global_position + Vector2(0, -4), "smoke", Vector2.UP, 1)
		queue_redraw()

	func _draw() -> void:
		var k := clampf(life / 1.0, 0.0, 1.0)
		var fl := 0.85 + 0.15 * sin(_t * 40.0)
		A.glow(self, Vector2(0, -4), FLARE_R * 0.7 * fl, Color(1.0, 0.25, 0.2, 0.12 * k))
		A.glow(self, Vector2(0, -4), 14.0 * fl, Color(1.0, 0.6, 0.5, 0.9 * k))
		draw_rect(Rect2(-2, -6, 4, 6), Color("8a2a1a"))


func stats() -> Dictionary:
	return {"name": "ARMORED TRAIN", "hp": 400, "walk": 0.0, "chase": 0.0, "damage": 2, "bite_delay": 1.0, "scale": 2.5, "width": 1.9,
		"duck": 0.0, "cover": 0.0, "skin": Color("7a8670"), "shirt": E.UNIFORM, "pants": E.UNIFORM, "shoe": Color("1a1816"),
		"points": 2800, "boss": true, "boss_name": "THE ARMORED TRAIN - SHOOT OUT THE LIGHT, THEN THE DRIVER"}


func setup() -> void:
	super.setup()
	z.add_to_group("empire")


func hit_size() -> Vector2:   # כל הקטר (לא רק המרכז)
	return Vector2(80.0 * z.wf * z.sc, 48.0 * z.sc)


func eye() -> Vector2:   # חרך המקלע
	return z.global_position + Vector2(z._dir * 26.0 * z.wf, -16.0) * z.sc


func muzzle() -> Vector2:   # התותח בצריח
	return z.global_position + Vector2(z._dir * 18.0 * z.wf, -44.0) * z.sc


func light_pos() -> Vector2:
	return z.global_position + Vector2(z._dir * 35.0 * z.wf, -27.0) * z.sc


func weak_rect() -> Rect2:   # חלון הנהג (כולל החזית בגובה החלון - שם הקליע פוגע באזור הפגיעה)
	return Rect2(14, -38, 32, 8)


func in_light(p: Vector2) -> bool:   # הפנס: בחזית, בגובה הפנס
	var l: Vector2 = (p - z.global_position) / z.sc
	l.x *= z._dir / maxf(float(z.wf), 0.1)
	return l.x > 28.0 and l.y > -31.5 and l.y < -22.0


func light_on() -> bool:
	return light_hp > 0


func on_damage(amount: int, hit_pos: Vector2, dir: Vector2, src: Dictionary) -> bool:
	var s := str(src.get("source", "bullet"))
	if light_on() and (s == "bullet" or s == "melee") and in_light(hit_pos):
		light_hp -= 1
		Sfx.play("tr_glass", hit_pos, -2.0, 0.1, 2)
		Particles.burst(z.get_parent(), hit_pos, "spark", -dir, 5)
		if light_hp <= 0:
			z._popup("LIGHT OUT - IT'S BLIND", Color("c0e0ff"), 15, -60.0 - 70.0 * z.sc)
		return false
	return super.on_damage(amount, hit_pos, dir, src)


# האם הוא "רואה" אותך טוב: הפנס דולק, או שאתה ליד זיקוק בוער
func lit(pl: Node) -> bool:
	if light_on():
		return true
	for f in z.get_tree().get_nodes_in_group("flares"):
		if f.landed and f.global_position.distance_to(pl.global_position) < FLARE_R:
			return true
	return false


func think(pl: Node, delta: float) -> void:
	_shell_cd -= delta
	_mg_cd -= delta
	_flare_cd -= delta
	_troop_cd -= delta
	_rate -= delta
	_door = maxf(_door - delta, 0.0)
	_recoil = maxf(_recoil - delta * 3.0, 0.0)
	if _left > 0:
		if _rate <= 0.0:
			_left -= 1
			_rate = 0.09
			var tgt: Vector2
			if lit(pl):
				lit_shots += 1
				tgt = aim_point(pl, MG_V) + Vector2(randf_range(-6, 6), randf_range(-8, 8))
			else:   # עיוור: יורה לכיוון הכללי
				blind_shots += 1
				tgt = Vector2(pl.global_position.x + randf_range(-160, 160), pl.global_position.y - 24.0 + randf_range(-70, 50))
			fire_shot(eye(), tgt, MG_V, 1, "bolt", Color(1.0, 0.85, 0.4), 4.0)
			Sfx.play("mb_mg", eye(), -3.0, 0.1, 4)
		return
	var dx: float = absf(pl.global_position.x - z.global_position.x)
	if dx > 1300.0:
		return
	if _troop_cd <= 0.0:
		var near := 0
		for o in z.get_tree().get_nodes_in_group("empire"):
			if o != z and not o.dead and absf(o.global_position.x - z.global_position.x) < 900.0:
				near += 1
		_troop_cd = TROOP_CD if near < 3 else 4.0
		if near < 3:
			wind("troops", 0.8)
			Sfx.play("tr_horn", z.global_position, 2.0, 0.02, 2)
			return
	if not light_on() and _flare_cd <= 0.0:
		wind("flare", 0.5)
		return
	if _shell_cd <= 0.0 and dx > 220.0:
		wind("shell", 0.9)
		return
	if _mg_cd <= 0.0:
		wind("mg", 0.35)


func attack(name: String, pl: Node) -> void:
	match name:
		"pound":
			Sfx.play("tr_steam", z.global_position, 2.0, 0.05, 2)
			Particles.burst(z.get_parent(), z.global_position + Vector2(z._dir * 30.0 * z.sc, -10.0), "smoke", Vector2(z._dir, -0.2), 14)
			do_pound(pl)
		"mg":
			_mg_cd = MG_CD
			_left = MG_N
			_rate = 0.0
		"shell":
			_shell_cd = SHELL_CD
			_recoil = 1.0
			Sfx.play("tr_cannon", muzzle(), 4.0, 0.05, 2)
			Particles.burst(z.get_parent(), muzzle(), "smoke", Vector2(z._dir, -0.2), 8)
			var tgt := aim_point(pl, 700.0)
			var flight := clampf(absf(tgt.x - muzzle().x) / 650.0, 0.6, 1.5)
			fire_lob(muzzle(), Vector2(tgt.x, pl.global_position.y), flight, 2, "shell", BLAST, Color(1.0, 0.6, 0.2), 7.0)
		"flare":
			_flare_cd = FLARE_CD
			flares += 1
			if flares == 1:
				z._popup("IT LEARNED - FLARES", Color("ff8060"), 15, -60.0 - 70.0 * z.sc)
			Sfx.play("tr_flare", muzzle(), 0.0, 0.1, 2)
			var f := Flare.new()
			var tx: float = pl.global_position.x + randf_range(-60, 60)
			var t := 1.0
			f.velocity = Vector2((tx - muzzle().x) / t, (pl.global_position.y - 10.0 - muzzle().y) / t - 0.5 * 900.0 * t)
			z.get_parent().add_child(f)
			f.global_position = muzzle()
		"troops":
			_door = 1.2
			z._popup("ALL OUT!", Color("ff6040"), 15, -60.0 - 70.0 * z.sc)
			var main: Node = z.get_parent()
			var R := preload("res://enemies/zombie_registry.gd")
			for i in TROOP_N:
				var sx: float = z.global_position.x - z._dir * (10.0 + float(i) * 22.0) * z.sc
				var c: Node = main._spawn_zombie(sx, z.global_position.y, R.CONSCRIPT)
				if c != null:
					troops += 1
					c._alert_t = 8.0


# ============================================================
#  ציור: גלגלים ומוטות, גוף משוריין עם מסמרות, מגן-פרות, פנס ענק (קונוס אור), חלון הנהג עם פרצוף, צריח + תותח, דלת,
#  ארובה עם עשן, הסמל על הצד, דגל קטן
# ============================================================
func draw() -> bool:
	begin_draw()
	var armor := col(Color("4a4e44"))
	var dark := col(Color("2a2c26"))
	var k := wind_k()
	var tt: float = z._time
	# גלגלים + מוט מקשר
	for q in 4:
		var wx := -30.0 + float(q) * 17.0
		z.draw_circle(Vector2(wx, -6), 6.0, col(Color("1a1a18")))
		z.draw_circle(Vector2(wx, -6), 2.0, col(Color("6a6a60")))
	var rod := Vector2(cos(tt * 2.0), sin(tt * 2.0)) * 3.0 if winding != "" else Vector2(3, 0)
	z.draw_line(Vector2(-30, -6) + rod, Vector2(21, -6) + rod, col(Color("8a8a80")), 1.6)
	# מגן-פרות
	z.draw_colored_polygon(PackedVector2Array([Vector2(36, -12), Vector2(44, -1), Vector2(36, -1)]), dark)
	for q in 3:
		z.draw_line(Vector2(37.0 + float(q) * 2.0, -11.0 + float(q) * 3.0), Vector2(37.0 + float(q) * 2.0, -1.0), col(Color("5a5a50")), 0.8)
	# הגוף
	Art.fill_shaded(z, PackedVector2Array([Vector2(-40, -11), Vector2(37, -11), Vector2(38, -30), Vector2(30, -36), Vector2(-40, -36)]), armor, 0.14, 0.4)
	for q in 9:   # מסמרות
		z.draw_circle(Vector2(-36.0 + float(q) * 8.5, -13.0), 0.7, col(Color("7a7e70")))
		z.draw_circle(Vector2(-36.0 + float(q) * 8.5, -34.0), 0.7, col(Color("7a7e70")))
	E.emblem(z, Vector2(-14, -23), 6.5, col(Color(0.9, 0.88, 0.82)))
	z.draw_rect(Rect2(Vector2(22, -18), Vector2(8, 3)), col(Color("0a0a0a")))   # חרך מקלע
	if _left > 0 and not z.dead:
		Art.glow(z, Vector2(31, -16.5), 4.0, Color(1.0, 0.8, 0.3, 0.8))
	# הדלת (נפתחת)
	z.draw_rect(Rect2(Vector2(-34, -30), Vector2(10, 18)), dark if _door <= 0.0 else col(Color("0a0a0a")))
	# חלון הנהג + נהג
	z.draw_rect(Rect2(Vector2(14, -37), Vector2(13, 10)), col(Color("0e1012")))
	if not z.dead:
		Art.oval_shaded(z, Vector2(20, -31), 3.6, 4.0, col(z.skin), 0.0)
		z.draw_circle(Vector2(22, -32), 0.9, Color(1.0, 0.25, 0.2))
		z.draw_rect(Rect2(Vector2(16, -36.5), Vector2(8, 2)), col(E.UNIFORM_D))   # כובע
	z.draw_rect(Rect2(Vector2(13, -38), Vector2(15, 1.5)), dark)
	# צריח + תותח
	var rc := 3.0 * _recoil
	z.draw_rect(Rect2(Vector2(-2.0 - rc, -46), Vector2(28, 3.5)), dark)
	Art.fill_shaded(z, PackedVector2Array([Vector2(-18, -36), Vector2(4, -36), Vector2(6, -43), Vector2(-2, -49), Vector2(-14, -49), Vector2(-20, -43)]), armor.lightened(0.05), 0.15, 0.4)
	if winding == "shell" and not z.dead:
		Art.glow(z, Vector2(26.0 - rc, -44.5), 3.0 + 5.0 * k, Color(1.0, 0.6, 0.2, 0.25 + 0.4 * k))
	# ארובה
	z.draw_rect(Rect2(Vector2(-34, -44), Vector2(6, 8)), dark)
	if Engine.get_physics_frames() % 20 == 0 and not z.dead:
		Particles.burst(z.get_parent(), z.global_position + Vector2(z._dir * -31.0 * z.wf, -46.0) * z.sc, "smoke", Vector2(0, -1), 1)
	# הפנס
	z.draw_circle(Vector2(35, -27), 3.4, dark)
	if light_on() and not z.dead:
		z.draw_circle(Vector2(35, -27), 2.6, col(Color(1.0, 0.97, 0.8)))
	else:
		z.draw_circle(Vector2(35, -27), 2.6, col(Color("1a1a1a")))
		z.draw_line(Vector2(33.5, -28.5), Vector2(36.5, -25.5), col(Color("6a6a6a")), 0.6)
	end_draw()
	# קונוס האור (בעולם)
	if light_on() and not z.dead:
		var lp: Vector2 = light_pos() - z.global_position
		var far := Vector2(z._dir * 900.0, 40.0)
		z.draw_colored_polygon(PackedVector2Array([lp + Vector2(0, -4), lp + far + Vector2(0, -160), lp + far + Vector2(0, 60), lp + Vector2(0, 4)]), Color(1.0, 0.97, 0.8, 0.07))
		Art.glow(z, lp, 30.0, Color(1.0, 0.97, 0.8, 0.35))
	return true
