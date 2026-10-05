extends "res://environment/hazard.gd"
# ============================================================
#  שטח בוער (מבקבוק תבערה / חבית / זומבי INFECTOR...)
#  מצית זומבים שנכנסים אליו ופוגע בשחקן שעומד בתוכו.
#  width = רוחב, life = כמה שניות בוער
# ============================================================
const FireScript := preload("res://fire.gd")

var width := 110.0
var _flames := []


func setup(w: float, seconds: float) -> void:
	story_kind = "fire"
	width = w
	life = seconds
	rect = Rect2(-w * 0.5, -34.0, w, 36.0)
	zombie_burn = 3.0
	player_damage = 1
	tick = 0.6


func _ready() -> void:
	super._ready()
	var n := maxi(2, int(width / 28.0))
	for i in n:   # כמה להבות לאורך השטח
		var f = FireScript.new()
		f.width = randf_range(16.0, 26.0)
		f.height = randf_range(22.0, 34.0)
		f.life = life + randf_range(-0.4, 0.0)
		f.smoke = i % 2 == 0
		f.position = Vector2(-width * 0.5 + (float(i) + 0.5) * width / float(n), 0.0)
		add_child(f)
	z_index = 6
