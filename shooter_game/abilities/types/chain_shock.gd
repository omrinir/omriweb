extends "res://abilities/ability_base.gd"
# ============================================================
#  CHAIN LIGHTNING - ברק מהמכשיר לזומבי הכי קרוב לכוונה (עד RANGE), וממנו קופץ לזומבים
#  הכי קרובים (עד JUMP פיקסלים בין קפיצה לקפיצה). כל פגיעה: נזק + שיתוק קצר + זומבי רטוב/מתכת לא משנה.
#  משתמש בברקים של SHOCK BLAST (dark_pulse.gd -> Zap). POWER: עוד קפיצות + נזק.
# ============================================================
const DarkPulse := preload("res://abilities/types/dark_pulse.gd")
const RANGE := 520.0
const JUMP := 230.0


func activate() -> bool:
	var sh: Vector2 = player.global_position + player._front_shoulder()
	var first: Node = null
	var best := 1e9
	for z in player.get_tree().get_nodes_in_group("zombies"):   # הראשון: קרוב לקו הכוונה
		if z.dead:
			continue
		var d: Vector2 = z.global_position + Vector2(0, -28) - sh
		if d.length() > RANGE or absf(d.angle_to(player._aim)) > 0.6:
			continue
		var score := d.length() * (1.0 + absf(d.angle_to(player._aim)) * 2.0)
		if score < best:
			best = score
			first = z
	if first == null:
		player._say("NO TARGET", Color(0.8, 0.7, 1.0))
		return false
	var hops := 6 + power
	var hit := [first]
	var cur: Node = first
	while hit.size() < hops:
		var nxt: Node = null
		var nd := JUMP
		for z in player.get_tree().get_nodes_in_group("zombies"):
			if z.dead or z in hit:
				continue
			var d: float = z.global_position.distance_to(cur.global_position)
			if d < nd:
				nd = d
				nxt = z
		if nxt == null:
			break
		hit.append(nxt)
		cur = nxt
	var prev := sh
	for z in hit:   # ברק אחד שעובר מזומבי לזומבי
		var p: Vector2 = z.global_position + Vector2(0, -28)
		var seg = DarkPulse.Zap.new()
		seg.from = prev
		seg.to = [p]
		player.get_parent().add_child(seg)
		prev = p
		z.stagger(0.7)
		z.take_damage(10 + 3 * power, p, (p - sh).normalized(), true, {"source": "ability"})
	Sfx.play("zap", sh, 6.0)
	Sfx.play("taser", sh, 0.0)
	return true
