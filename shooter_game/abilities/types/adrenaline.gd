extends "res://abilities/ability_base.gd"
# ============================================================
#  ADRENALINE SHOT - מזרק אדרנלין לירך: +1 לב (אם חסר), ולכמה שניות בוסט ADRENALINE
#  (יורה פי 2 מהר, טוען מהר יותר, רץ מהר - player.gd). POWER: משך (+20% לרמה); רמה 3+ = +2 לבבות.
# ============================================================
const PickupScript := preload("res://pickup.gd")


func activate() -> bool:
	var d := duration()
	player.boosts[PickupScript.ADRENALINE] = maxf(float(player.boosts.get(PickupScript.ADRENALINE, 0.0)), d)
	var heal := 2 if power >= 3 else 1
	if player.health < player.max_health:
		player.health = mini(player.health + heal, player.max_health)
		player.health_changed.emit(player.health, player.max_health)
		player._heal_flash = 1.0
	Sfx.play("heal", player.global_position, 0.0)
	Sfx.play("boost", player.global_position, 2.0, 0.0, 2, 0.8)
	ring(player.global_position + Vector2(0, -26), 90.0, Color("ff4a6a"), 0.4)
	player._say("ADRENALINE!", Color("ff4a6a"))
	return true


func active() -> bool:
	return player != null and player.boosts.has(PickupScript.ADRENALINE)
