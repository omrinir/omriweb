extends SceneTree
var n := 0
var m
var p
var wid := 0
const D := "/tmp/claude-0/-home-user-omriweb/4c84a69a-95cf-51ee-b2a6-c44008e8609a/scratchpad/"
func _initialize():
	m = load("res://main.tscn").instantiate()
	root.add_child(m)
func _process(_d):
	n += 1
	if n == 10:
		p = get_first_node_in_group("player")
		for z in get_nodes_in_group("zombies"): z.queue_free()
		p.slots = [{"id": 5, "ammo": 36}, {"id": 6, "ammo": 90}, {"id": 7, "ammo": 60}, {"id": 8, "ammo": 3}, {"id": 9, "ammo": 6}]
	if n >= 12 and n < 12 + 11 * 30:
		var k := (n - 12) / 30
		var f := (n - 12) % 30
		if f == 0:
			if k < 5: p.slots[k] = p.slots[k]
			var ids := [5, 6, 7, 8, 9, 10, 0, 1, 2, 3, 4]
			p.slots[0] = {"id": ids[k], "ammo": 40}
			p.select_slot(0)
			p._aim = Vector2(1, 0.15).normalized()
			wid = ids[k]
		if f == 1 or f == 8:
			p._cooldown = 0.0
			p._fire_test = true
		if f == 20:
			print("weapon ", root.get_node("Game").WEAPON_NAMES[wid], " ammo ", p.ammo, " mag ", p.mag)
	if n == 12 + 11 * 30:
		p.slots[0] = {"id": 6, "ammo": 90}
		p.select_slot(0)
		p.mag = 0
		p._cooldown = 0
		p._fire_test = true
	if n == 12 + 11 * 30 + 2:
		print("auto reload started: ", p.is_reloading())
	if n == 12 + 11 * 30 + 140:
		print("after reload mag ", p.mag, " ammo ", p.ammo, " hazards ", get_nodes_in_group("hazards").size())
		print("memory ", root.get_node("PlayerMemory").snapshot())
		quit()
