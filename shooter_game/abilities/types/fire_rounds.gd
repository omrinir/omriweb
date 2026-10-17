extends "res://abilities/ability_base.gd"
# ============================================================
#  INCENDIARY ROUNDS - לכמה שניות כל קליע מצית (במקום BLOOD HOOK).
#  משתמש בבוסט INCENDIARY (bullet.gd -> incendiary, zombie.gd -> ignite) - שורת הבוסטים ב-HUD
#  מראה את הזמן שנשאר. POWER: משך (+20% לרמה).
# ============================================================
const PickupScript := preload("res://pickup.gd")


func activate() -> bool:
	var d := duration()
	player.boosts[PickupScript.INCENDIARY] = maxf(float(player.boosts.get(PickupScript.INCENDIARY, 0.0)), d)
	Sfx.play("fire_whoosh", player.global_position, 0.0)
	Sfx.play("reload_done", player.global_position, 2.0)
	Particles.burst(player.get_parent(), player.global_position + player._front_shoulder(), "fire", Vector2.ZERO, 12)
	player._say("INCENDIARY ROUNDS", Color("ff8a20"))
	return true


func active() -> bool:
	return player != null and player.boosts.has(PickupScript.INCENDIARY)
