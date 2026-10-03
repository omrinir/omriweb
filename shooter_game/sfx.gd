extends RefCounted
# ============================================================
#  אפקטים קוליים - בלי קבצי סאונד! כל צליל מסונתז בקוד (פעם אחת)
#  שימוש:  Sfx.play("rifle", global_position)
#  כל "מתכון" הוא רשימת שכבות. שכבה:
#  [סוג, תדר התחלה, תדר סוף, התחלה(שנ'), אורך, attack, דעיכה, עוצמה, פילטר(0-1), ויברטו]
#  סוגים: N = רעש, S = סינוס, W = מסור, Q = ריבוע, C = פצפוצים
#  דעיכה: מהירות דעיכה (גדול = קצר). 0 = נחלש בקו ישר עד הסוף
#  פילטר: 1 = בלי, קטן = עמום (בס)
# ============================================================

const RATE := 22050
static var volume_db := -4.0          # עוצמה כללית
static var _cache := {}
static var _active := {}
static var played := {}           # כמה פעמים כל צליל התנגן (לבדיקות)

const R := {
	"rifle": {"rev": 0.22, "drive": 2.6, "layers": [["N", 0, 0, 0.0, 0.006, 0.0, 500.0, 1.6, 1.0, 0], ["N", 0, 0, 0.0, 0.16, 0.0, 26.0, 1.2, 0.35, 0], ["S", 125, 42, 0.0, 0.12, 0.0, 26.0, 1.1, 1.0, 0], ["N", 0, 0, 0.07, 0.02, 0.0, 200.0, 0.35, 1.0, 0, 0.35], ["S", 3100, 3000, 0.07, 0.03, 0.0, 120.0, 0.12, 1.0, 0]]},
	"shotgun": {"rev": 0.35, "drive": 3.2, "layers": [["N", 0, 0, 0.0, 0.009, 0.0, 380.0, 1.8, 1.0, 0], ["N", 0, 0, 0.0, 0.38, 0.0, 12.0, 1.5, 0.22, 0], ["S", 82, 30, 0.0, 0.32, 0.0, 11.0, 1.4, 1.0, 0], ["N", 0, 0, 0.38, 0.035, 0.0, 140.0, 0.45, 1.0, 0, 0.4], ["S", 950, 900, 0.38, 0.04, 0.0, 90.0, 0.2, 1.0, 0], ["N", 0, 0, 0.5, 0.035, 0.0, 140.0, 0.5, 1.0, 0, 0.4], ["S", 720, 700, 0.5, 0.04, 0.0, 90.0, 0.22, 1.0, 0]]},
	"sniper": {"rev": 0.45, "drive": 3.0, "echo": [0.26, 0.35], "layers": [["N", 0, 0, 0.0, 0.005, 0.0, 700.0, 1.9, 1.0, 0], ["S", 1900, 600, 0.0, 0.025, 0.0, 140.0, 0.45, 1.0, 0], ["N", 0, 0, 0.0, 0.22, 0.0, 17.0, 1.3, 0.28, 0], ["S", 100, 32, 0.0, 0.22, 0.0, 14.0, 1.3, 1.0, 0], ["N", 0, 0, 0.6, 0.03, 0.0, 160.0, 0.4, 1.0, 0, 0.4], ["S", 1400, 1350, 0.6, 0.03, 0.0, 120.0, 0.15, 1.0, 0], ["N", 0, 0, 0.72, 0.03, 0.0, 160.0, 0.45, 1.0, 0, 0.4]]},
	"bow": {"rev": 0.12, "layers": [["N", 0, 0, 0.0, 0.015, 0.0, 300.0, 0.7, 0.5, 0], ["S", 112, 96, 0.0, 0.45, 0.0, 9.0, 0.55, 1.0, 0.01], ["W", 224, 192, 0.0, 0.3, 0.0, 14.0, 0.25, 0.3, 0], ["N", 0, 0, 0.02, 0.26, 0.05, 10.0, 0.4, 0.15, 0, 0.05]]},
	"taser": {"drive": 2.2, "layers": [["N", 0, 0, 0.0, 0.012, 0.0, 300.0, 1.0, 1.0, 0], ["Q", 85, 80, 0.0, 0.4, 0.0, 4.0, 0.25, 0.45, 0], ["C", 0, 0, 0.0, 0.4, 0.0, 3.0, 1.0, 1.0, 0], ["S", 4200, 3800, 0.0, 0.4, 0.0, 5.0, 0.08, 1.0, 0], ["N", 0, 0, 0.0, 0.4, 0.0, 5.0, 0.2, 0.9, 0, 0.3]]},
	"empty": [["Q", 1800, 1500, 0.0, 0.03, 0.0, 120.0, 0.35, 0.8, 0], ["N", 0, 0, 0.0, 0.02, 0.0, 150.0, 0.3, 1.0, 0]],
	"explosion": {"rev": 0.35, "drive": 2.5, "layers": [["N", 0, 0, 0.0, 0.012, 0.0, 250.0, 1.5, 1.0, 0], ["N", 0, 0, 0.0, 1.6, 0.0, 2.8, 1.3, 0.06, 0], ["S", 68, 24, 0.0, 1.1, 0.0, 3.2, 1.3, 1.0, 0], ["N", 0, 0, 0.0, 0.18, 0.0, 22.0, 0.9, 0.45, 0], ["C", 0, 0, 0.06, 1.2, 0.0, 2.5, 0.4, 1.0, 0]]},
	"throw": [["N", 0, 0, 0.0, 0.26, 0.08, 10.0, 0.45, 0.2, 0]],
	"clink": [["S", 900, 700, 0.0, 0.09, 0.0, 50.0, 0.35, 1.0, 0], ["S", 1370, 1300, 0.0, 0.07, 0.0, 60.0, 0.2, 1.0, 0]],
	"step": [["N", 0, 0, 0.0, 0.07, 0.0, 55.0, 0.5, 0.12, 0], ["S", 95, 60, 0.0, 0.06, 0.0, 50.0, 0.35, 1.0, 0]],
	"step_water": [["N", 0, 0, 0.0, 0.18, 0.005, 24.0, 0.55, 0.5, 0, 0.12], ["B", 1.0, 1.0, 0.0, 0.22, 0.0, 6.0, 0.35, 1.0, 0, 0, 70.0], ["S", 180, 90, 0.0, 0.1, 0.0, 30.0, 0.18, 1.0, 0]],
	"step_water2": [["N", 0, 0, 0.0, 0.15, 0.008, 28.0, 0.5, 0.55, 0, 0.15], ["B", 1.3, 1.3, 0.0, 0.2, 0.0, 7.0, 0.3, 1.0, 0, 0, 60.0], ["S", 200, 110, 0.0, 0.08, 0.0, 35.0, 0.15, 1.0, 0]],
	"step_water3": [["N", 0, 0, 0.0, 0.2, 0.004, 20.0, 0.5, 0.45, 0, 0.1], ["B", 0.8, 0.8, 0.0, 0.25, 0.0, 6.0, 0.35, 1.0, 0, 0, 80.0], ["S", 160, 80, 0.0, 0.1, 0.0, 30.0, 0.18, 1.0, 0]],
	"splash": [["N", 0, 0, 0.0, 0.4, 0.005, 9.0, 0.8, 0.45, 0, 0.08], ["B", 0.9, 0.9, 0.0, 0.45, 0.0, 4.0, 0.45, 1.0, 0, 0, 110.0], ["S", 120, 50, 0.0, 0.15, 0.0, 20.0, 0.4, 1.0, 0]],
	"jump": [["N", 0, 0, 0.0, 0.13, 0.02, 24.0, 0.35, 0.25, 0]],
	"land": [["N", 0, 0, 0.0, 0.09, 0.0, 45.0, 0.6, 0.1, 0], ["S", 105, 50, 0.0, 0.09, 0.0, 35.0, 0.6, 1.0, 0]],
	"roll": [["N", 0, 0, 0.0, 0.32, 0.05, 8.0, 0.35, 0.18, 0]],
	"melee": [["S", 170, 60, 0.0, 0.13, 0.0, 28.0, 0.9, 1.0, 0], ["N", 0, 0, 0.0, 0.08, 0.0, 45.0, 0.7, 0.3, 0]],
	"hit": [["N", 0, 0, 0.0, 0.11, 0.0, 34.0, 0.7, 0.25, 0], ["S", 300, 120, 0.0, 0.06, 0.0, 50.0, 0.3, 1.0, 0]],
	"headshot": [["N", 0, 0, 0.0, 0.17, 0.0, 24.0, 0.9, 0.4, 0], ["C", 0, 0, 0.0, 0.1, 0.0, 20.0, 0.5, 1.0, 0], ["S", 210, 70, 0.0, 0.1, 0.0, 30.0, 0.5, 1.0, 0]],
	"shield": [["S", 1400, 1200, 0.0, 0.12, 0.0, 30.0, 0.3, 1.0, 0], ["S", 2300, 2200, 0.0, 0.08, 0.0, 40.0, 0.15, 1.0, 0], ["N", 0, 0, 0.0, 0.03, 0.0, 100.0, 0.4, 1.0, 0]],
	"groan": {"drive": 2.6, "layers": [["V", 92, 76, 0.0, 1.2, 0.15, 1.8, 0.7, 1.0, 0.04, 0, [520, 880, 24]], ["N", 0, 0, 0.0, 1.2, 0.1, 2.5, 0.12, 0.12, 0]]},
	"groan2": {"drive": 2.6, "layers": [["V", 110, 85, 0.0, 1.0, 0.1, 2.2, 0.7, 1.0, 0.05, 0, [600, 950, 30]], ["N", 0, 0, 0.0, 1.0, 0.1, 3.0, 0.12, 0.12, 0]]},
	"zscream": {"drive": 2.6, "layers": [["V", 230, 150, 0.0, 0.95, 0.04, 2.0, 0.9, 1.0, 0.05, 0, [820, 1250, 42]], ["N", 0, 0, 0.0, 0.95, 0.02, 2.5, 0.14, 0.4, 0, 0.1]]},
	"zscream2": {"drive": 2.6, "layers": [["V", 320, 210, 0.0, 0.8, 0.03, 2.4, 0.85, 1.0, 0.06, 0, [950, 1550, 55]], ["N", 0, 0, 0.0, 0.8, 0.02, 3.0, 0.16, 0.5, 0, 0.15]]},
	"zscream3": {"drive": 2.6, "layers": [["V", 165, 115, 0.0, 1.1, 0.06, 1.8, 0.9, 1.0, 0.05, 0, [650, 1020, 35]], ["N", 0, 0, 0.0, 1.1, 0.03, 2.2, 0.22, 0.3, 0, 0.08]]},
	"zhit": {"drive": 2.6, "layers": [["V", 190, 120, 0.0, 0.3, 0.01, 9.0, 0.85, 1.0, 0.03, 0, [720, 1150, 50]], ["N", 0, 0, 0.0, 0.15, 0.0, 20.0, 0.25, 0.35, 0]]},
	"zhit2": {"drive": 2.6, "layers": [["V", 250, 160, 0.0, 0.26, 0.01, 10.0, 0.8, 1.0, 0.03, 0, [880, 1400, 60]], ["N", 0, 0, 0.0, 0.12, 0.0, 22.0, 0.25, 0.4, 0]]},
	"zhit3": {"drive": 2.6, "layers": [["V", 150, 100, 0.0, 0.32, 0.01, 8.0, 0.85, 1.0, 0.03, 0, [600, 980, 40]], ["N", 0, 0, 0.0, 0.15, 0.0, 18.0, 0.25, 0.3, 0]]},
	"zdeath": {"drive": 2.6, "layers": [["V", 210, 65, 0.0, 0.75, 0.02, 3.5, 0.85, 1.0, 0.05, 0, [700, 1100, 38]], ["B", 0.6, 0.6, 0.15, 0.5, 0.0, 5.0, 0.3, 1.0, 0, 0, 50.0]]},
	"hurt": [["W", 230, 150, 0.0, 0.22, 0.01, 10.0, 0.4, 0.25, 0], ["N", 0, 0, 0.0, 0.1, 0.0, 30.0, 0.3, 0.2, 0]],
	"glass": [["N", 0, 0, 0.0, 0.3, 0.0, 12.0, 0.6, 1.0, 0], ["S", 3200, 3150, 0.0, 0.4, 0.0, 9.0, 0.2, 1.0, 0], ["S", 4700, 4650, 0.02, 0.3, 0.0, 12.0, 0.15, 1.0, 0], ["C", 0, 0, 0.0, 0.25, 0.0, 8.0, 0.5, 1.0, 0]],
	"clang": [["S", 520, 515, 0.0, 0.8, 0.0, 5.0, 0.4, 1.0, 0], ["S", 1310, 1300, 0.0, 0.6, 0.0, 7.0, 0.25, 1.0, 0], ["S", 2150, 2140, 0.0, 0.4, 0.0, 10.0, 0.15, 1.0, 0], ["N", 0, 0, 0.0, 0.03, 0.0, 100.0, 0.5, 1.0, 0]],
	"zap": [["Q", 60, 60, 0.0, 0.3, 0.0, 6.0, 0.3, 0.6, 0], ["C", 0, 0, 0.0, 0.3, 0.0, 5.0, 0.8, 1.0, 0]],
	"train": [["N", 0, 0, 0.0, 2.4, 0.3, 0.0, 0.8, 0.05, 0], ["Q", 52, 48, 0.0, 2.4, 0.3, 0.0, 0.2, 0.1, 0], ["C", 0, 0, 0.0, 2.4, 0.2, 0.0, 0.15, 1.0, 0]],
	"horn": [["W", 311, 305, 0.0, 1.1, 0.05, 1.2, 0.3, 0.3, 0], ["W", 370, 362, 0.0, 1.1, 0.05, 1.2, 0.3, 0.3, 0]],
	"roar": [["W", 72, 52, 0.0, 1.4, 0.1, 1.6, 0.6, 0.1, 0.08], ["N", 0, 0, 0.0, 1.4, 0.1, 2.0, 0.35, 0.15, 0]],
	"scream": [["W", 600, 900, 0.0, 1.0, 0.05, 2.0, 0.35, 0.5, 0.05], ["N", 0, 0, 0.0, 1.0, 0.0, 2.0, 0.2, 0.6, 0]],
	"spit": [["N", 0, 0, 0.0, 0.2, 0.02, 15.0, 0.4, 0.4, 0], ["S", 400, 200, 0.0, 0.1, 0.0, 30.0, 0.2, 1.0, 0]],
	"splat": [["N", 0, 0, 0.0, 0.5, 0.0, 7.0, 0.8, 0.2, 0], ["S", 80, 40, 0.0, 0.3, 0.0, 9.0, 0.8, 1.0, 0]],
	"arrow_hit": [["S", 190, 120, 0.0, 0.08, 0.0, 40.0, 0.5, 1.0, 0], ["N", 0, 0, 0.0, 0.04, 0.0, 90.0, 0.5, 0.5, 0]],
	"ricochet": [["S", 2400, 1500, 0.0, 0.12, 0.0, 25.0, 0.12, 1.0, 0], ["N", 0, 0, 0.0, 0.03, 0.0, 100.0, 0.25, 1.0, 0]],
	"pickup": [["S", 880, 880, 0.0, 0.08, 0.0, 25.0, 0.3, 1.0, 0], ["S", 1320, 1320, 0.07, 0.14, 0.0, 18.0, 0.3, 1.0, 0]],
	"weapon": [["N", 0, 0, 0.0, 0.05, 0.0, 60.0, 0.45, 0.5, 0], ["S", 300, 280, 0.0, 0.05, 0.0, 60.0, 0.3, 1.0, 0], ["N", 0, 0, 0.12, 0.05, 0.0, 60.0, 0.5, 0.6, 0], ["S", 420, 400, 0.12, 0.05, 0.0, 60.0, 0.3, 1.0, 0]],
	"boost": [["S", 660, 1320, 0.0, 0.32, 0.0, 6.0, 0.3, 1.0, 0], ["S", 990, 1980, 0.0, 0.32, 0.0, 6.0, 0.18, 1.0, 0]],
	"heal": [["S", 523, 523, 0.0, 0.5, 0.0, 4.0, 0.22, 1.0, 0], ["S", 659, 659, 0.1, 0.45, 0.0, 4.0, 0.22, 1.0, 0], ["S", 784, 784, 0.2, 0.5, 0.0, 4.0, 0.22, 1.0, 0]],
	"beep": [["S", 1900, 1900, 0.0, 0.06, 0.0, 30.0, 0.3, 1.0, 0], ["S", 1900, 1900, 0.12, 0.06, 0.0, 30.0, 0.3, 1.0, 0], ["S", 2400, 2400, 0.24, 0.1, 0.0, 20.0, 0.35, 1.0, 0]],
	"servo": [["W", 140, 220, 0.0, 0.25, 0.02, 6.0, 0.25, 0.3, 0], ["N", 0, 0, 0.0, 0.25, 0.02, 8.0, 0.1, 0.5, 0, 0.2]],
	"ui": [["S", 1200, 1100, 0.0, 0.05, 0.0, 70.0, 0.25, 1.0, 0]],
	"whoosh": [["N", 0, 0, 0.0, 0.2, 0.05, 12.0, 0.3, 0.3, 0]],
	"hook": [["N", 0, 0, 0.0, 0.15, 0.02, 18.0, 0.3, 0.4, 0], ["S", 1600, 1400, 0.12, 0.05, 0.0, 60.0, 0.25, 1.0, 0]],
}


# יוצר את כל הצלילים מראש (main.gd קורא לזה)
static func warm_up() -> void:
	for k in R:
		_stream(k)


static func _stream(name: String) -> AudioStreamWAV:
	if _cache.has(name):
		return _cache[name]
	var rec = R[name]
	var fx: Dictionary = rec if rec is Dictionary else {}
	var layers: Array = rec.layers if rec is Dictionary else rec
	var total := 0.0
	for l in layers:
		total = maxf(total, float(l[3]) + float(l[4]))
	if fx.has("rev") or fx.has("echo"):
		total += 0.7   # זנב להד
	var n := int(total * RATE) + 1
	var buf := PackedFloat32Array()
	buf.resize(n)
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(name)
	for l in layers:
		_layer(buf, l, rng)
	var drive: float = fx.get("drive", 1.2)
	for i in n:
		buf[i] = tanh(buf[i] * drive) / maxf(tanh(drive), 0.6)
	if fx.has("echo"):   # הד (קיר רחוק)
		var dl := int(float(fx.echo[0]) * RATE)
		var fb := float(fx.echo[1])
		for i in range(dl, n):
			buf[i] += buf[i - dl] * fb
	if fx.has("rev"):
		_reverb(buf, float(fx.rev))
	var bytes := PackedByteArray()
	bytes.resize(n * 2)
	for i in n:
		bytes.encode_s16(i * 2, int(clampf(tanh(buf[i]), -1.0, 1.0) * 32000.0))
	var st := AudioStreamWAV.new()
	st.format = AudioStreamWAV.FORMAT_16_BITS
	st.mix_rate = RATE
	st.stereo = false
	st.data = bytes
	_cache[name] = st
	return st


# שכבה אחת: [סוג, תדר, תדר סוף, התחלה, אורך, attack, דעיכה, עוצמה, low-pass, ויברטו, high-pass, נוסף]
# V = קול (מיתרי קול + פורמנטים [F1, F2, נהמה]), B = בועות מים (נוסף = כמה בשנייה)
static func _layer(buf: PackedFloat32Array, l: Array, rng: RandomNumberGenerator) -> void:
	var n := buf.size()
	var kind: String = l[0]
	var f0 := float(l[1])
	var f1 := float(l[2])
	var s0 := int(float(l[3]) * RATE)
	var ln := int(float(l[4]) * RATE)
	var att := float(l[5])
	var dec := float(l[6])
	var vol := float(l[7])
	var lp := float(l[8])
	var vib := float(l[9])
	var hp: float = l[10] if l.size() > 10 else 0.0
	var extra = l[11] if l.size() > 11 else null
	var ph := 0.0
	var y := 0.0
	var yl := 0.0
	# פורמנטים (מסננים רזוננטיים) לקול
	var bq := []
	var growl := 0.0
	if kind == "V":
		for k in 2:
			var w0 := TAU * float(extra[k]) / RATE
			var al := sin(w0) / (2.0 * 6.0)
			var a0 := 1.0 + al
			bq.append([al / a0, -al / a0, -2.0 * cos(w0) / a0, (1.0 - al) / a0, 0.0, 0.0, 0.0, 0.0])
		growl = float(extra[2])
	var bubbles := []
	for i in ln:
		var j := s0 + i
		if j >= n:
			break
		var t := float(i) / RATE
		var k := float(i) / float(ln)
		var env := exp(-t * dec) if dec > 0.0 else (1.0 - k)
		if att > 0.0 and t < att:
			env *= t / att
		var f := f0 * pow(f1 / f0, k) if f0 > 0.0 else 0.0
		if vib > 0.0:
			f *= 1.0 + vib * sin(TAU * 5.5 * t) + rng.randf_range(-vib, vib) * 0.3
		ph += f / RATE
		var v := 0.0
		match kind:
			"N": v = rng.randf_range(-1.0, 1.0)
			"S": v = sin(TAU * ph)
			"W": v = 2.0 * fposmod(ph, 1.0) - 1.0
			"Q": v = 1.0 if fposmod(ph, 1.0) < 0.5 else -1.0
			"C": v = rng.randf_range(-1.0, 1.0) if rng.randf() < 0.04 else 0.0
			"V":
				var src := (2.0 * fposmod(ph, 1.0) - 1.0) + rng.randf_range(-0.25, 0.25)
				src *= 0.55 + 0.45 * sin(TAU * growl * t)   # נהמה
				var out := src * 0.06
				for q in bq.size():
					var c: Array = bq[q]
					var o: float = c[0] * src + c[1] * c[5] - c[2] * c[6] - c[3] * c[7]
					c[5] = c[4]
					c[4] = src
					c[7] = c[6]
					c[6] = o
					out += o * (1.6 if q == 0 else 1.0)
				v = out
			"B":
				if rng.randf() < float(extra) / RATE:
					bubbles.append([0.0, rng.randf_range(350.0, 1100.0) * f0, 0.0])
				for bb in bubbles:
					bb[2] += 1.0 / RATE
					bb[0] += bb[1] * (1.0 + bb[2] * 28.0) / RATE
					v += sin(TAU * bb[0]) * exp(-bb[2] * 70.0)
				if i % 256 == 0:
					bubbles = bubbles.filter(func(bb): return bb[2] < 0.07)
		y += (v - y) * lp
		var o2 := y
		if hp > 0.0:   # high-pass: מוריד את הבס
			yl += (y - yl) * hp
			o2 = y - yl
		buf[j] += o2 * env * vol


# הד חדר (Schroeder): 4 מסנני comb ו-2 all-pass
static func _reverb(buf: PackedFloat32Array, wet: float) -> void:
	var n := buf.size()
	var dry := buf.duplicate()
	var out := PackedFloat32Array()
	out.resize(n)
	for d in [[557, 0.78], [593, 0.76], [641, 0.74], [677, 0.72]]:
		var dl: int = d[0]
		var fb: float = d[1]
		var line := PackedFloat32Array()
		line.resize(n)
		for i in n:
			var past := line[i - dl] if i >= dl else 0.0
			line[i] = dry[i] + past * fb
			out[i] += past * 0.25
	for d in [113, 37]:
		var dl: int = d
		var tmp := out.duplicate()
		for i in n:
			var past := out[i - dl] if i >= dl else 0.0
			var pin := tmp[i - dl] if i >= dl else 0.0
			out[i] = -0.5 * tmp[i] + pin + 0.5 * past
	for i in n:
		buf[i] = dry[i] + out[i] * wet


# מנגן צליל. pos = מיקום בעולם (צליל נחלש עם המרחק), null = צליל "על המסך"
static func play(name: String, pos: Variant = null, vol := 0.0, pitch_var := 0.08, max_same := 5) -> void:
	if not R.has(name):
		return
	var base := name
	var vars := [name]
	for k in [2, 3, 4]:   # גרסאות שונות של אותו צליל (step_water2...)
		if R.has(name + str(k)):
			vars.append(name + str(k))
	name = vars[randi() % vars.size()]
	played[base] = int(played.get(base, 0)) + 1
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return
	var host: Node = tree.current_scene if tree.current_scene != null else tree.root
	if int(_active.get(base, 0)) >= max_same:   # לא יותר מדי פעמים אותו צליל ביחד
		return
	var p: Node
	if pos is Vector2:
		var p2 := AudioStreamPlayer2D.new()
		p2.max_distance = 1500.0
		p2.attenuation = 1.2
		p2.global_position = pos
		p2.volume_db = volume_db + vol
		p2.pitch_scale = 1.0 + randf_range(-pitch_var, pitch_var)
		p2.stream = _stream(name)
		p = p2
	else:
		var p1 := AudioStreamPlayer.new()
		p1.volume_db = volume_db + vol
		p1.pitch_scale = 1.0 + randf_range(-pitch_var, pitch_var)
		p1.stream = _stream(name)
		p = p1
	_active[base] = int(_active.get(base, 0)) + 1
	p.finished.connect(func():
		_active[base] = maxi(int(_active.get(base, 1)) - 1, 0)
		p.queue_free())
	p.tree_exiting.connect(func(): if p.is_queued_for_deletion() == false: _active[base] = maxi(int(_active.get(base, 1)) - 1, 0))
	host.add_child(p)
	p.play()
