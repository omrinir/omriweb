extends RefCounted
# ============================================================
#  MUSIC DB - איזו מוזיקה מתנגנת איפה (2026-10-20).
#    * כל אזור (9 שלבים) - שיר משלו (REGION). שלב 1 נשאר עם "Zombie Joyride".
#    * בוס קרוב (בר החיים שלו מופיע) - BOSS, ואחרי שהוא מת חוזרים לשיר של השלב (main.gd).
#    * תפריט ומפה - MENU (game_settings.gd -> menu_music).
#  קובץ שחסר בתיקייה music/ = נשאר מה שהיה קודם (השלב בוחר ב-stage_N.gd -> music()).
#  השמות והקרדיטים של השירים: music/CREDITS.txt
# ============================================================

const REGION := [
	"res://music/region1_amazon.ogg",
	"res://music/region2_northeast.ogg",
	"res://music/region3_plateau.ogg",
	"res://music/region4_andes.ogg",
	"res://music/region5_southeast.ogg",
	"res://music/region6_southern_cone.ogg",
	"res://music/region7_patagonia.ogg",
]
const BOSS := "res://music/boss.ogg"
const MENU := "res://music/menu.ogg"
const KEEP_LEVEL_1 := true   # שלב 1: "Zombie Joyride" (גם בסרטוני הפרומו)


static func exists(path: String) -> bool:
	return path != "" and (ResourceLoader.exists(path) or FileAccess.file_exists(path))


# השיר של השלב. stage_path = מה שהשלב ביקש ("" = השלב מנגן בעצמו, למשל התזמורת של שלב 32)
static func level_track(level: int, stage_path: String) -> String:
	if stage_path == "" or (level == 1 and KEEP_LEVEL_1):
		return stage_path
	var r := (level - 1) / 9
	if r >= 0 and r < REGION.size() and exists(REGION[r]):
		return REGION[r]
	return stage_path


# טוען מוזיקה בלופ. אם העורך עוד לא ייבא את הקובץ - קוראים אותו ישירות (OGG / MP3)
static func load_stream(path: String) -> AudioStream:
	var stream: AudioStream = null
	if OS.has_feature("mobile"):   # טלפון: גרסה קלה של המוזיקה (music/mobile/*.ogg 64k - רק בבניית אנדרואיד, כדי שה-APK יהיה קטן)
		var light := "res://music/mobile/" + path.get_file().get_basename() + ".ogg"
		if ResourceLoader.exists(light):
			path = light
	if ResourceLoader.exists(path):
		stream = load(path) as AudioStream
	if stream == null and FileAccess.file_exists(path):
		if path.ends_with(".ogg"):
			stream = AudioStreamOggVorbis.load_from_file(path)
		elif path.ends_with(".mp3"):
			var mp3 := AudioStreamMP3.new()
			mp3.data = FileAccess.get_file_as_bytes(path)
			stream = mp3
	if stream is AudioStreamMP3:
		(stream as AudioStreamMP3).loop = true
	elif stream is AudioStreamOggVorbis:
		(stream as AudioStreamOggVorbis).loop = true
	return stream
