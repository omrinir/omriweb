extends "res://abilities/ability_base.gd"
# ============================================================
#  LAST BREATH (פסיבי) - פעם בשלב: מכה שהייתה הורגת משאירה אותך עם לב אחד,
#  ואתה בלתי פגיע לרגע. POWER: עוד זמן בלתי פגיע; ברמה 3+ פעמיים בשלב.
# ============================================================
var charges := 1


func on_level_start() -> void:
	charges = 2 if power >= 3 else 1


func on_lethal_hit() -> bool:
	if charges <= 0:
		return false
	charges -= 1
	player.health = 1
	player._invuln = 2.0 + 0.4 * float(power)
	player._heal_flash = 1.0
	player._say("LAST BREATH", Color("e8e0c8"))
	Sfx.play("heal", player.global_position, 2.0)
	ring(player.global_position + Vector2(0, -26), 120.0, Color("e8e0c8"), 0.7)
	return true
