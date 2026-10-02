Shooter Game - משחק יריות ב-Godot 4
=====================================

איך פותחים:
1. מחלצים את קובץ ה-ZIP לתיקייה (לחיצה ימנית -> Extract All).
2. פותחים את Godot 4 (גרסה 4.2 ומעלה).
3. במסך הפתיחה לוחצים Import, בוחרים את הקובץ project.godot
   שבתוך התיקייה שחילצתם, ולוחצים Import & Edit.
4. לוחצים F5 (או על כפתור ה-Play למעלה מימין).

מקשים:
  A / D          הליכה
  SHIFT          ריצה
  W / רווח       קפיצה
  S / CTRL       כריעה
  עכבר           כיוון
  לחצן שמאלי     ירי / זריקת רימון
  T              החלפה בין רובה לרימון
  K              מוות (לבדיקה)
  R              התחלה מחדש (רמה חדשה)

הקבצים:
  main.gd / main.tscn     הסצנה הראשית - בונה רמה אקראית
  player.gd               השחקן
  zombie.gd / zombie.tscn זומבי
  brick.gd / brick.tscn   לבנה (נסדקת ונשברת)
  bullet.gd               קליע
  grenade.gd              רימון
  debris.gd               שברי לבנים
  blood_drop.gd           טיפות דם
  background.gd           רקע שקיעה
  leaves.gd               עלים נופלים
  shake_camera.gd         מצלמה שרועדת בפיצוצים
  hud.gd                  בר חיים ו-GAME OVER
