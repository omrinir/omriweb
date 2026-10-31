extends "res://enemies/zombie_type.gd"
# ============================================================
#  CINDER (שלב 33, "SULFUR CRATER") - זומבי של אפר: גוף אפור סדוק, גחלים כתומות זוהרות בפנים, עשן עולה ממנו.
#  "THEY LEARNED TO COME BACK": "הורגים" אותו -> מתפורר לערמת אפר (PILE) עם גחלת זוהרת (Core).
#    אחרי REFORM_T הוא קם מחדש עם כל החיים - אלא אם:
#      * יורים בגחלת (מטרה קטנה על הרצפה), או
#      * דורכים על הערמה (עוברים עליה), או
#      * פיצוץ / רימון.
#  גל האפר של ההר לא פוגע בו (ash_proof) - הוא אוהב אותו: בזמן הגל הוא מהיר יותר.
#  לשנות: ASH_HP, REFORM_T, CRUSH_R.
# ============================================================

const SOUNDS := {
	"cn_crumble": [["N", 0, 0, 0.0, 0.5, 0.02, 5.0, 0.6, 0.3, 0], ["C", 0, 0, 0.0, 0.4, 0.0, 6.0, 0.5, 1.0, 0]],
	"cn_reform": [["N", 0, 0, 0.0, 0.7, 0.4, 0.0, 0.4, 0.25, 0, 0.1], ["S", 90, 160, 0.0, 0.7, 0.4, 0.0, 0.3, 1.0, 0.05]],
	"cn_snuff": [["S", 900, 300, 0.0, 0.15, 0.0, 20.0, 0.25, 1.0, 0], ["N", 0, 0, 0.0, 0.2, 0.0, 15.0, 0.4, 0.6, 0, 0.4]],
}

const ASH_HP := 30
const REFORM_T := 4.0
const CRUSH_R := 18.0

enum { WALK, PILE, DYING }
var state := WALK
var ash := ASH_HP
var piles := 0               # לבדיקות
var reforms := 0
var snuffed := ""
var _st := 0.0
var _smoke := 0.0
var _core: StaticBody2D = null
var _layer := 4


func stats() -> Dictionary:
	return {"name": "CINDER", "hp": 9999, "walk": 40.0, "chase": 88.0, "damage": 1, "bite_delay": 0.75, "scale": 1.0, "width": 1.0,
		"duck": 0.0, "cover": 0.0, "skin": Color("5a5452"), "shirt": Color("3a3432"), "pants": Color("2e2a28"), "shoe": Color("2a2624"), "points": 450}


func ash_proof() -> bool:   # (effects/s33_decor.gd Volcano: גל האפר לא פוגע בו)
	return true


func setup() -> void:
	_layer = z.collision_layer


func can_bite() -> bool:
	return state == WALK


func on_damage(amount: int, hit_pos: Vector2, dir: Vector2, src: Dictionary) -> bool:
	if state == DYING:
		return true
	var s := str(src.get("source", "bullet"))
	var explosive: bool = s in ["grenade", "explosion", "dynamite", "rocket", "barrel", "mine", "artillery"]
	if state == PILE:
		if explosive:
			snuff("blast")
		return false
	var dmg := hit_damage(amount, hit_pos, src)   # כמו זומבי רגיל: ראש / גוף / רגל / שוטגאן
	var ly: float = (hit_pos.y - z.global_position.y) / z.sc
	ash -= dmg
	z._damage_number(dmg, "head" if ly < -42.0 else "body")
	z._flash = 0.1
	Particles.burst(z.get_parent(), hit_pos, "smoke", -dir, 2)
	Game.on_zombie_hit({"source": s, "zone": "head" if ly < -42.0 else "body"})
	if ash <= 0:
		if explosive:   # פיצוץ: מפזר את הגחלת מיד
			_collapse.call_deferred()
			snuff.call_deferred("blast")
		else:
			_collapse.call_deferred()
	return false


func _collapse() -> void:
	if z == null or not is_instance_valid(z) or z.dead or state != WALK:
		return
	state = PILE
	piles += 1
	_st = REFORM_T
	z.collision_layer = 0
	z.velocity = Vector2.ZERO
	Sfx.play("cn_crumble", z.global_position, 0.0, 0.1, 3)
	Particles.burst(z.get_parent(), z.global_position + Vector2(0, -30), "smoke", Vector2.UP, 10)
	z._popup("ASHES...", Color("c0b0a0"), 12, -60.0)
	_core = Core.new()
	_core.owner_t = self
	_core.collision_layer = 4
	_core.collision_mask = 0
	var cs := CollisionShape2D.new()
	var sh := CircleShape2D.new()
	sh.radius = 8.0
	cs.shape = sh
	_core.add_child(cs)
	z.get_parent().add_child(_core)
	_core.global_position = z.global_position + Vector2(0, -6)


# הגחלת כבתה (ירייה / דריכה / פיצוץ) -> מת באמת
func snuff(how: String) -> void:
	if state != PILE or z == null or not is_instance_valid(z) or z.dead:
		return
	snuffed = how
	state = DYING
	Sfx.play("cn_snuff", z.global_position, 0.0, 0.1, 3)
	Particles.burst(z.get_parent(), z.global_position + Vector2(0, -6), "fire", Vector2.UP, 8)
	_free_core()
	z.collision_layer = _layer
	z.hp = 1
	z.take_damage(5, z.global_position + Vector2(0, -10), Vector2.UP, false, {"source": "core", "fixed": 5})


func _free_core() -> void:
	if _core != null and is_instance_valid(_core):
		_core.queue_free()
	_core = null


func physics(pl: Node, delta: float) -> bool:
	_st -= delta
	_smoke -= delta
	if z.dead:
		return false
	if state == WALK:
		if _smoke <= 0.0 and Art.on_screen(z, z.global_position):
			_smoke = randf_range(0.5, 0.9)
			Particles.burst(z.get_parent(), z.global_position + Vector2(0, -50) * z.sc, "smoke", Vector2.UP, 1)
		return false
	if state == PILE:
		z.velocity.x = 0.0
		if not z.is_on_floor():
			z.velocity.y += z.gravity * delta
			z.move_and_slide()
		if pl != null and not pl.dead and pl.is_on_floor() and absf(pl.global_position.x - z.global_position.x) < CRUSH_R and absf(pl.global_position.y - z.global_position.y) < 12.0:
			snuff("stomp")
			return true
		if _st <= 0.0:   # קם מחדש
			_free_core()
			state = WALK
			ash = ASH_HP
			reforms += 1
			z.collision_layer = _layer
			z._alert_t = 6.0
			Sfx.play("cn_reform", z.global_position, 0.0, 0.1, 2)
			Particles.burst(z.get_parent(), z.global_position + Vector2(0, -20), "smoke", Vector2.UP, 12)
			z._popup("IT CAME BACK", Color("ff9050"), 13, -80.0)
			return false
		return true
	return true


func logic(_pl: Node, _d: Vector2, _delta: float, speed: float) -> float:
	var v: Node = preload("res://effects/s33_decor.gd").volcano()
	return speed * (1.4 if v != null and v.state == 2 else 1.0)   # בגל האפר - מהיר


func on_death() -> void:
	_free_core()


class Core extends StaticBody2D:   # הגחלת: קליע שפוגע בה (take_damage) מכבה אותה
	var owner_t = null

	func take_damage(_amount: int, _hit_pos: Vector2, _dir: Vector2, _explosive := false, _src := {}) -> void:
		if owner_t != null:
			owner_t.snuff("shot")


# ============================================================
#  ציור: גוף אפר סדוק עם סדקים זוהרים. PILE: ערמת אפר + גחלת פועמת (ככל שמתקרב לקום - חזקה יותר)
# ============================================================
func draw() -> bool:
	if state == PILE and not z.dead:
		DrawBatch.set_transform(z, Vector2.ZERO, 0.0, Vector2.ONE)
		var k := clampf(1.0 - _st / REFORM_T, 0.0, 1.0)
		DrawBatch.colored_polygon(z, PackedVector2Array([Vector2(-18, 0), Vector2(-10, -7), Vector2(-2, -10 - k * 6.0), Vector2(8, -8), Vector2(18, 0)]), Color("4a4442"))
		DrawBatch.colored_polygon(z, Art.ellipse(Vector2(0, -2), 16.0, 3.0, 0.0, 10), Color("3a3432"))
		var pulse := 0.6 + 0.4 * sin(z._time * (6.0 + k * 14.0))
		Art.glow(z, Vector2(0, -6), 18.0 + k * 10.0, Color(1.0, 0.45, 0.1, 0.25 * pulse + 0.15 * k))
		DrawBatch.circle(z, Vector2(0, -6), 4.5, Color(1.0, 0.5 + 0.3 * pulse, 0.15))
		DrawBatch.circle(z, Vector2(0, -6), 2.0, Color(1.0, 0.95, 0.6))
		return true
	begin_draw()
	var sk := col(z.skin)
	var p: float = z._walk_phase
	var f: Array = feet(4.5, 2.5)
	var hip := Vector2(0, -22)
	var sh := Vector2(1, -37)
	var head := sh + Vector2(3.5, -8)
	var crack := Color(1.0, 0.5 + 0.2 * sin(z._time * 5.0), 0.15)
	z._leg(hip + Vector2(-2, 0), f[1], col(Art.shade(z.pants, 0.25)), sk, col(z.shoe))
	z._leg(hip + Vector2(2, 0), f[0], col(z.pants), sk, col(z.shoe))
	z._arm(sh + Vector2(-3, 1), sh + Vector2(-5.0 - sin(p) * 2.0, 15.0), Art.shade(sk, 0.25), Art.shade(sk, 0.3))
	Art.fill_shaded(z, PackedVector2Array([sh + Vector2(-7, -1), sh + Vector2(7, 0), hip + Vector2(6, 2), hip + Vector2(-6, 2)]), sk, 0.1, 0.35)
	if not z.dead:   # סדקים זוהרים
		DrawBatch.polyline(z, PackedVector2Array([sh + Vector2(-3, 2), sh + Vector2(1, 7), sh + Vector2(-2, 12), hip + Vector2(1, -2)]), crack, 1.4)
		DrawBatch.polyline(z, PackedVector2Array([sh + Vector2(4, 3), sh + Vector2(2, 9)]), crack, 1.2)
		Art.glow(z, sh + Vector2(0, 8), 14.0, Color(1.0, 0.45, 0.1, 0.15))
	Art.oval_shaded(z, head, 5.2, 5.8, sk, 0.0)
	face(head, Vector2(3.0, -0.5))
	if not z.dead:
		DrawBatch.circle(z, head + Vector2(3.0, -0.5), 1.4, Color(1.0, 0.6, 0.2))
		DrawBatch.line(z, head + Vector2(-2, -4), head + Vector2(1, 0), crack, 1.0)
		DrawBatch.line(z, head + Vector2(1, 3), head + Vector2(5, 3.5), Color(1.0, 0.4, 0.1), 1.2)
	z._arm(sh + Vector2(3, 1), sh + Vector2(10.0 + sin(p) * 3.0, 12.0), sk, sk)
	end_draw()
	return true
