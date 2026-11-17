import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/spiritual_tracker_model.dart';
import '../theme/app_theme.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
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

  // User Name & Title
  String getUserName() {
    final name = (_prefs?.getString('user_name') ?? '').trim();
    if (name.isEmpty || name == 'زائر مبارك' || name == 'فادي عادل') {
      return 'مينا';
    }
    return name;
  }

  Future<void> setUserName(String name) async {
    await _prefs?.setString('user_name', name.trim());
  }

  String getUserTitle() {
    final title = _prefs?.getString('user_title') ?? '';
    return title.trim().isEmpty ? 'عضو بالكنيسة القبطية الأرثوذكسية' : title.trim();
  }

  Future<void> setUserTitle(String title) async {
    await _prefs?.setString('user_title', title.trim());
  }

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

  // Diocese & Church Selection Persistence
  String getDiocese() {
    final d = (_prefs?.getString('user_diocese') ?? '').trim();
    return d.isEmpty ? 'إيبارشية القاهرة والبطريركية' : d;
  }

  Future<void> setDiocese(String diocese) async {
    await _prefs?.setString('user_diocese', diocese.trim());
  }

  String getChurchName() {
    final c = (_prefs?.getString('user_church_name') ?? '').trim();
    return c.isEmpty ? 'كنيسة الشهيد العظيم مارجرجس' : c;
  }

  Future<void> setChurchName(String church) async {
    await _prefs?.setString('user_church_name', church.trim());
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

  // Spiritual Tracker Logs (100% locally encrypted on-device)
  List<SpiritualLog> getSpiritualLogs() {
    final raw = _prefs?.getString('spiritual_logs_encrypted') ?? '[]';
    try {
      final decrypted = _decryptLocal(raw);
      final list = jsonDecode(decrypted) as List;
      return list.map((item) => SpiritualLog.fromJson(item)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> saveSpiritualLogs(List<SpiritualLog> logs) async {
    final jsonStr = jsonEncode(logs.map((l) => l.toJson()).toList());
    await _prefs?.setString('spiritual_logs_encrypted', _encryptLocal(jsonStr));
  }

  // Local Symmetric Cipher for Private Confession Notes (100% offline, zero-cloud)
  static const String _localKey = 'OrthodoxConfessionKey_1743AM';

  String _encryptLocal(String plainText) {
    final bytes = utf8.encode(plainText);
    final keyBytes = utf8.encode(_localKey);
    final out = List<int>.generate(
      bytes.length,
      (i) => bytes[i] ^ keyBytes[i % keyBytes.length] ^ ((i * 31) & 0xFF),
    );
    return 'ENC_V1:${base64Encode(out)}';
  }

  String _decryptLocal(String stored) {
    if (!stored.startsWith('ENC_V1:')) return stored; // backwards compatible
    final encoded = stored.substring(7);
    final cipher = base64Decode(encoded);
    final keyBytes = utf8.encode(_localKey);
    final out = List<int>.generate(
      cipher.length,
      (i) => cipher[i] ^ keyBytes[i % keyBytes.length] ^ ((i * 31) & 0xFF),
    );
    return utf8.decode(out);
  }

  // Conscience Exam Questions & Notes
  List<ConscienceQuestion> getConscienceQuestions() {
    final raw = _prefs?.getString('conscience_exam_notes') ?? '';
    if (raw.isNotEmpty) {
      try {
        final decrypted = _decryptLocal(raw);
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
    await _prefs?.setString('conscience_exam_notes', _encryptLocal(jsonStr));
  }

  Future<void> clearConscienceNotes() async {
    await _prefs?.remove('conscience_exam_notes');
  }

  static final List<ConscienceQuestion> _defaultConscienceQuestions = [
    // علاقتي بالله
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

    // علاقتي بالقريب
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

    // نقاوة القلب والجسد
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
