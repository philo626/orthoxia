import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/spiritual_tracker_model.dart';
import '../theme/app_theme.dart';
import 'encryption_service.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  SharedPreferences? _prefs;
  final EncryptionService _encryption = EncryptionService();

  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
    await _encryption.init();
  }

  // Theme Preference
  AppThemeMode getThemeMode() {
    final modeStr = _prefs?.getString('theme_mode') ?? 'darkGold';
    switch (modeStr) {
      case 'amoledChurch':
        return AppThemeMode.amoledChurch;
      case 'lightParchment':
        return AppThemeMode.lightParchment;
      default:
        return AppThemeMode.darkGold;
    }
  }

  Future<void> setThemeMode(AppThemeMode mode) async {
    await _prefs?.setString('theme_mode', mode.name);
  }

  // Font Size Scale (1.0 default)
  double getFontSizeScale() {
    return _prefs?.getDouble('font_size_scale') ?? 1.0;
  }

  Future<void> setFontSizeScale(double scale) async {
    await _prefs?.setDouble('font_size_scale', scale);
  }

  // User Name & Title (user-entered, never hardcoded to a fake person!)
  String getUserName() {
    final name = (_prefs?.getString('user_name') ?? '').trim();
    if (name.isEmpty) {
      return 'صديق أرثوذكسيا';
    }
    return name;
  }

  bool hasCustomUserName() {
    final name = (_prefs?.getString('user_name') ?? '').trim();
    return name.isNotEmpty && name != 'صديق أرثوذكسيا';
  }

  Future<void> setUserName(String name) async {
    await _prefs?.setString('user_name', name.trim());
  }

  String getUserTitle() {
    final title = _prefs?.getString('user_title') ?? '';
    return title.trim().isEmpty ? 'أرثوذكسي في المسيح' : title.trim();
  }

  Future<void> setUserTitle(String title) async {
    await _prefs?.setString('user_title', title.trim());
  }

  // Personal Patron Saint (شفيعي الشخصي)
  String getPatronSaintId() {
    return _prefs?.getString('patron_saint_id') ?? 'virgin_mary';
  }

  Future<void> setPatronSaintId(String saintId) async {
    await _prefs?.setString('patron_saint_id', saintId);
  }

  // Daily Verse & Optional Family Prayer Notifications
  bool isNotificationPromptShown() => _prefs?.getBool('notif_prompt_shown') ?? false;
  Future<void> setNotificationPromptShown(bool val) async =>
      await _prefs?.setBool('notif_prompt_shown', val);

  bool isDailyVerseNotificationEnabled() =>
      _prefs?.getBool('daily_verse_notif_enabled') ?? false;
  Future<void> setDailyVerseNotificationEnabled(bool val) async =>
      await _prefs?.setBool('daily_verse_notif_enabled', val);

  int getDailyVerseHour() => _prefs?.getInt('daily_verse_hour') ?? 8;
  int getDailyVerseMinute() => _prefs?.getInt('daily_verse_minute') ?? 0;
  Future<void> setDailyVerseTime(int hour, int minute) async {
    await _prefs?.setInt('daily_verse_hour', hour);
    await _prefs?.setInt('daily_verse_minute', minute);
  }

  bool isFamilyPrayerReminderEnabled() =>
      _prefs?.getBool('family_prayer_notif_enabled') ?? false; // Strictly optional!
  Future<void> setFamilyPrayerReminderEnabled(bool val) async =>
      await _prefs?.setBool('family_prayer_notif_enabled', val);

  int getFamilyPrayerHour() => _prefs?.getInt('family_prayer_hour') ?? 21;
  int getFamilyPrayerMinute() => _prefs?.getInt('family_prayer_minute') ?? 0;
  Future<void> setFamilyPrayerTime(int hour, int minute) async {
    await _prefs?.setInt('family_prayer_hour', hour);
    await _prefs?.setInt('family_prayer_minute', minute);
  }

  // Biometric Lock for Confession Notes
  bool isBiometricConfessionLockEnabled() =>
      _prefs?.getBool('biometric_lock_confession') ?? true;
  Future<void> setBiometricConfessionLockEnabled(bool val) async =>
      await _prefs?.setBool('biometric_lock_confession', val);

  // Guest Mode & Auth V2
  bool isGuestMode() {
    return _prefs?.getBool('is_guest_mode') ?? true;
  }

  Future<void> setGuestMode(bool isGuest) async {
    await _prefs?.setBool('is_guest_mode', isGuest);
  }

  bool isAuthV2Completed() {
    return _prefs?.getBool('auth_v2_completed') ?? false;
  }

  Future<void> setAuthV2Completed(bool completed) async {
    await _prefs?.setBool('auth_v2_completed', completed);
  }

  String getUserEmail() {
    return _prefs?.getString('user_email') ?? '';
  }

  Future<void> setUserEmail(String email) async {
    await _prefs?.setString('user_email', email.trim());
  }

  String getUserPhone() {
    return _prefs?.getString('user_phone') ?? '';
  }

  Future<void> setUserPhone(String phone) async {
    await _prefs?.setString('user_phone', phone.trim());
  }

  Future<void> deleteAllUserData() async {
    await _prefs?.clear();
  }

  // Onboarding Done
  bool isOnboardingCompleted() {
    return _prefs?.getBool('onboarding_completed') ?? false;
  }

  Future<void> setOnboardingCompleted(bool completed) async {
    await _prefs?.setBool('onboarding_completed', completed);
  }

  // Gamification & Infinite Quiz Persistence
  int getTriviaScore() => _prefs?.getInt('trivia_score') ?? 120;
  Future<void> setTriviaScore(int val) async => await _prefs?.setInt('trivia_score', val);

  int getTriviaCoins() => _prefs?.getInt('trivia_coins') ?? 50;
  Future<void> setTriviaCoins(int val) async => await _prefs?.setInt('trivia_coins', val);

  int getTriviaStreak() => _prefs?.getInt('trivia_streak') ?? 3;
  Future<void> setTriviaStreak(int val) async => await _prefs?.setInt('trivia_streak', val);

  int getTotalQuestionsAnswered() => _prefs?.getInt('trivia_total_answered') ?? 0;
  Future<void> setTotalQuestionsAnswered(int val) async =>
      await _prefs?.setInt('trivia_total_answered', val);

  // Spiritual Tracker Logs (100% locally AES-256 encrypted on-device, ZERO cloud)
  List<SpiritualLog> getSpiritualLogs() {
    final raw = _prefs?.getString('spiritual_logs_encrypted') ?? '[]';
    try {
      final decrypted = _encryption.decryptAes256(raw);
      final list = jsonDecode(decrypted) as List;
      return list.map((item) => SpiritualLog.fromJson(item)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> saveSpiritualLogs(List<SpiritualLog> logs) async {
    final jsonStr = jsonEncode(logs.map((l) => l.toJson()).toList());
    await _prefs?.setString('spiritual_logs_encrypted', _encryption.encryptAes256(jsonStr));
  }

  // Conscience Exam Questions & Confession Notes (100% locally AES-256 encrypted, ZERO cloud)
  List<ConscienceQuestion> getConscienceQuestions() {
    final raw = _prefs?.getString('conscience_exam_notes') ?? '';
    if (raw.isNotEmpty) {
      try {
        final decrypted = _encryption.decryptAes256(raw);
        final list = jsonDecode(decrypted) as List;
        return list.map((i) => ConscienceQuestion.fromJson(i)).toList();
      } catch (e) {
        // Fallback to default
      }
    }
    return _defaultConscienceQuestions;
  }

  Future<void> saveConscienceQuestions(List<ConscienceQuestion> questions) async {
    final jsonStr = jsonEncode(questions.map((q) => q.toJson()).toList());
    await _prefs?.setString('conscience_exam_notes', _encryption.encryptAes256(jsonStr));
  }

  Future<void> clearConscienceNotes() async {
    await _prefs?.remove('conscience_exam_notes');
  }

  static final List<ConscienceQuestion> _defaultConscienceQuestions = [
    ConscienceQuestion(
      id: 'god_1',
      category: 'علاقتي بالله',
      title: 'الأمانة في الصلاة اليومية وقراءة الإنجيل',
      explanation: 'هل أبدأ يومي وأختمه بحديث قلبي مع الرب، أم تمضي الأيام في انشغال العالم؟',
    ),
    ConscienceQuestion(
      id: 'god_2',
      category: 'علاقتي بالله',
      title: 'الشكر والتسليم في أوقات الضيق',
      explanation: 'هل أتذمر عند حدوث التجارب، أم أشكر الله صانع الخيرات واثقاً في عنايته؟',
    ),
    ConscienceQuestion(
      id: 'god_3',
      category: 'علاقتي بالله',
      title: 'احترام بيت الله وسر التناول',
      explanation: 'هل أحضر القداسات بخشوع واستعداد ووقار أم بتكاسل وسرحان؟',
    ),
    ConscienceQuestion(
      id: 'others_1',
      category: 'علاقتي بالقريب',
      title: 'المحبة وعدم الإدانة',
      explanation: 'هل تسرعت في الحكم على الآخرين، أو تكلمت عن نقائصهم في غيابهم؟',
    ),
    ConscienceQuestion(
      id: 'others_2',
      category: 'علاقتي بالقريب',
      title: 'المسامحة ونزع مرارة الغضب',
      explanation: 'هل أحمل في قلبي حقداً أو غيظاً تجاه شخص أساء إليّ، رافضاً المصالحة؟',
    ),
    ConscienceQuestion(
      id: 'others_3',
      category: 'علاقتي بالقريب',
      title: 'العطاء وأعمال الرحمة',
      explanation: 'هل تفقدت المحتاجين وساعدت بالمال أو الوقت أو الكلمة المشجعة؟',
    ),
    ConscienceQuestion(
      id: 'self_1',
      category: 'نقاوة القلب والجسد',
      title: 'طهارة الفكر والنظر',
      explanation: 'هل سمحت لخيالات أو مشاهد غير نقية بالتسلل إلى قلبي وإفساد سلامي الداخلي؟',
    ),
    ConscienceQuestion(
      id: 'self_2',
      category: 'نقاوة القلب والجسد',
      title: 'الصدق والأمانة في المعاملات',
      explanation: 'هل نطقت بالكذب أو بالغت في الحديث أو قصرت في عملي ومسؤولياتي؟',
    ),
    ConscienceQuestion(
      id: 'self_3',
      category: 'نقاوة القلب والجسد',
      title: 'محاربة الكبرياء والغرور',
      explanation: 'هل نسبت الفضل لنفسي وتباهيت بإنجازاتي، أم قدمت المجد لله بكل اتضاع؟',
    ),
  ];
}
