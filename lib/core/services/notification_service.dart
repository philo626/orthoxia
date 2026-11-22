import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'patron_saint_service.dart';
import 'storage_service.dart';

class DailyBibleVerse {
  final String text;
  final String reference;

  const DailyBibleVerse({required this.text, required this.reference});
}

/// Manages:
/// 1) 14-day rolling distinct Daily Bible Verse & Patron Saint notifications
/// 2) Real scheduled Agpeya Hour prayer alarms (strictly opt-in per hour)
/// 3) Optional gentle Family Prayer reminder
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  static const int _dailyVerseBaseId = 1100; // 1100..1113 (14 distinct days)
  static const int _patronSaintBaseId = 3100; // 3100..3113 (14 distinct days)
  static const int _familyPrayerNotificationId = 2001;
  static const String agpeyaAlarmsPrefsKey = 'agpeya_optional_alarms_v1';

  static const Map<String, ({int id, int hour, int minute, String title, String body})> agpeyaAlarmCatalog = {
    'prime': (
      id: 4001,
      hour: 6,
      minute: 0,
      title: 'وقت صلاة باكر',
      body: '«باكر يا رب تسمع صوتي، بالغداة أقف أمامك وتراني» — دقائق هادئة لبدء يومك مع الله.',
    ),
    'terce': (
      id: 4002,
      hour: 9,
      minute: 0,
      title: 'وقت صلاة الساعة الثالثة',
      body: 'تذكار حلول الروح القدس المعزي — ارفع قلبك بصلاة قصيرة وسط عملك.',
    ),
    'sext': (
      id: 4003,
      hour: 12,
      minute: 0,
      title: 'وقت صلاة الساعة السادسة',
      body: 'تذكار صلب رب المجد — استراحة روحية قصيرة في منتصف النهار.',
    ),
    'none': (
      id: 4004,
      hour: 15,
      minute: 0,
      title: 'وقت صلاة الساعة التاسعة',
      body: '«اذكرني يا رب متى جئت في ملكوتك» — لحظة هدوء وصلاة.',
    ),
    'vespers': (
      id: 4005,
      hour: 17,
      minute: 0,
      title: 'وقت صلاة الغروب',
      body: 'بداية المساء واليوم القبطي الجديد — اشكر الله على رعايته طوال النهار.',
    ),
    'compline': (
      id: 4006,
      hour: 21,
      minute: 0,
      title: 'وقت صلاة النوم',
      body: 'سلّم يومك وقلبك بين يدي الرب ليهبك ليلة هادئة وسلاماً.',
    ),
    'midnight': (
      id: 4007,
      hour: 23,
      minute: 30,
      title: 'وقت صلاة نصف الليل',
      body: '«في نصف الليل أقوم لأحمدك على أحكام عدلك» — سهر هادئ في محضر الرب.',
    ),
  };

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  static const List<DailyBibleVerse> dailyVerses = [
    DailyBibleVerse(
      text: '«اَلرَّبُّ رَاعِيَّ فَلاَ يُعْوِزُنِي شَيْءٌ. فِي مَرَاعٍ خُضْرٍ يُرْبِضُنِي. إِلَى مِيَاهِ الرَّاحَةِ يُورِدُنِي»',
      reference: 'مزمور ٢٣: ١-٢',
    ),
    DailyBibleVerse(
      text: '«تَعَالَوْا إِلَيَّ يَا جَمِيعَ الْمُتْعَبِينَ وَالثَّقِيلِي الأَحْمَالِ، وَأَنَا أُرِيحُكُمْ»',
      reference: 'متى ١١: ٢٨',
    ),
    DailyBibleVerse(
      text: '«لاَ تَخَفْ لأَنِّي مَعَكَ. لاَ تَتَلَفَّتْ لأَنِّي إِلهُكَ. قَدْ أَيَّدْتُكَ وَأَعَنْتُكَ»',
      reference: 'إشعياء ٤١: ١٠',
    ),
    DailyBibleVerse(
      text: '«أَسْتَطِيعُ كُلَّ شَيْءٍ فِي الْمَسِيحِ الَّذِي يُقَوِّينِي»',
      reference: 'فيلبي ٤: ١٣',
    ),
    DailyBibleVerse(
      text: '«اَلرَّبُّ نُورِي وَخَلاَصِي، مِمَّنْ أَخَافُ؟ الرَّبُّ حِصْنُ حَيَاتِي، مِمَّنْ أَرْتَعِبُ؟»',
      reference: 'مزمور ٢٧: ١',
    ),
    DailyBibleVerse(
      text: '«سَلاَماً أَتْرُكُ لَكُمْ. سَلاَمِي أُعْطِيكُمْ. لاَ تَضْطَرِبْ قُلُوبُكُمْ وَلاَ تَرْهَبْ»',
      reference: 'يوحنا ١٤: ٢٧',
    ),
    DailyBibleVerse(
      text: '«نَعْلَمُ أَنَّ كُلَّ الأَشْيَاءِ تَعْمَلُ مَعاً لِلْخَيْرِ لِلَّذِينَ يُحِبُّونَ اللهَ»',
      reference: 'رومية ٨: ٢٨',
    ),
    DailyBibleVerse(
      text: '«تَوَكَّلْ عَلَى الرَّبِّ بِكُلِّ قَلْبِكَ، وَعَلَى فَهْمِكَ لاَ تَعْتَمِدْ»',
      reference: 'أمثال ٣: ٥',
    ),
    DailyBibleVerse(
      text: '«أَلْقِ عَلَى الرَّبِّ هَمَّكَ فَهُوَ يَعُولُكَ. لاَ يَدَعُ الصِّدِّيقَ يَتَزَعْزَعُ إِلَى الأَبَدِ»',
      reference: 'مزمور ٥٥: ٢٢',
    ),
    DailyBibleVerse(
      text: '«اِفْرَحُوا فِي الرَّبِّ كُلَّ حِينٍ، وَأَقُولُ أَيْضاً: افْرَحُوا»',
      reference: 'فيلبي ٤: ٤',
    ),
    DailyBibleVerse(
      text: '«اَلرَّبُّ يُقَاتِلُ عَنْكُمْ وَأَنْتُمْ تَصْمُتُونَ»',
      reference: 'خروج ١٤: ١٤',
    ),
    DailyBibleVerse(
      text: '«لأَنَّهُ هكَذَا أَحَبَّ اللهُ الْعَالَمَ حَتَّى بَذَلَ ابْنَهُ الْوَحِيدَ، لِكَيْ لاَ يَهْلِكَ كُلُّ مَنْ يُؤْمِنُ بِهِ»',
      reference: 'يوحنا ٣: ١٦',
    ),
    DailyBibleVerse(
      text: '«سِرَاجٌ لِرِجْلِي كَلاَمُكَ وَنُورٌ لِسَبِيلِي»',
      reference: 'مزمور ١١٩: ١٠٥',
    ),
    DailyBibleVerse(
      text: '«تَكْفِيكَ نِعْمَتِي، لأَنَّ قُوَّتِي فِي الضَّعْفِ تُكْمَلُ»',
      reference: '٢ كورنثوس ١٢: ٩',
    ),
    DailyBibleVerse(
      text: '«مُلْقِينَ كُلَّ هَمِّكُمْ عَلَيْهِ، لأَنَّهُ هُوَ يَعْتَنِي بِكُمْ»',
      reference: '١ بطرس ٥: ٧',
    ),
    DailyBibleVerse(
      text: '«أَنَا هُوَ نُورُ الْعَالَمِ. مَنْ يَتْبَعْنِي فَلاَ يَمْشِي فِي الظُّلْمَةِ بَلْ يَكُونُ لَهُ نُورُ الْحَيَاةِ»',
      reference: 'يوحنا ٨: ١٢',
    ),
    DailyBibleVerse(
      text: '«اُطْلُبُوا أَوَّلاً مَلَكُوتَ اللهِ وَبِرَّهُ، وَهذِهِ كُلُّهَا تُزَادُ لَكُمْ»',
      reference: 'متى ٦: ٣٣',
    ),
    DailyBibleVerse(
      text: '«لاَ تَهْتَمُّوا بِشَيْءٍ، بَلْ فِي كُلِّ شَيْءٍ بِالصَّلاَةِ وَالدُّعَاءِ مَعَ الشُّكْرِ»',
      reference: 'فيلبي ٤: ٦',
    ),
    DailyBibleVerse(
      text: '«قَلْباً نَقِيّاً اخْلُقْ فِيَّ يَا اللهُ، وَرُوحاً مُسْتَقِيماً جَدِّدْ فِي دَاخِلِي»',
      reference: 'مزمور ٥١: ١٠',
    ),
    DailyBibleVerse(
      text: '«أَمَّا أَنَا وَبَيْتِي فَنَعْبُدُ الرَّبَّ»',
      reference: 'يشوع ٢٤: ١٥',
    ),
    DailyBibleVerse(
      text: '«لأَنَّهُ حَيْثُمَا اجْتَمَعَ اثْنَانِ أَوْ ثَلاَثَةٌ بِاسْمِي فَهُنَاكَ أَكُونُ فِي وَسْطِهِمْ»',
      reference: 'متى ١٨: ٢٠',
    ),
  ];

  static DailyBibleVerse getTodayVerse([DateTime? date]) {
    final now = date ?? DateTime.now();
    final dayOfYear = now.difference(DateTime(now.year, 1, 1)).inDays;
    return dailyVerses[dayOfYear % dailyVerses.length];
  }

  Future<void> init() async {
    if (_initialized) return;
    try {
      tz.initializeTimeZones();
      try {
        tz.setLocalLocation(tz.getLocation('Africa/Cairo'));
      } catch (_) {}

      const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosInit = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );
      const settings = InitializationSettings(android: androidInit, iOS: iosInit);
      await _plugin.initialize(settings);
      _initialized = true;
    } catch (e) {
      if (kDebugMode) debugPrint('NotificationService init skipped: $e');
    }
  }

  Future<bool> requestPermission() async {
    await init();
    try {
      final androidImpl = _plugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      if (androidImpl != null) {
        final granted = await androidImpl.requestNotificationsPermission();
        return granted ?? true;
      }
      final iosImpl = _plugin
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
      if (iosImpl != null) {
        final granted = await iosImpl.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        return granted ?? true;
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Schedules 14 distinct upcoming days of Daily Verse + Patron Saint quotes
  /// PLUS Family Prayer Reminder & all enabled Agpeya Hour alarms.
  Future<void> syncScheduledNotifications() async {
    await init();
    if (!_initialized) return;

    final storage = StorageService();
    final now = tz.TZDateTime.now(tz.local);

    // 1. Daily Verse + Patron Saint (14 rolling distinct days!)
    for (int d = 0; d < 14; d++) {
      await _plugin.cancel(_dailyVerseBaseId + d);
      await _plugin.cancel(_patronSaintBaseId + d);
    }

    if (storage.isDailyVerseNotificationEnabled()) {
      final saint = PatronSaintService.getSaintById(storage.getPatronSaintId());
      final vHour = storage.getDailyVerseHour();
      final vMin = storage.getDailyVerseMinute();

      for (int d = 0; d < 14; d++) {
        final targetDate = now.add(Duration(days: d));
        final verseAt = tz.TZDateTime(
          tz.local,
          targetDate.year,
          targetDate.month,
          targetDate.day,
          vHour,
          vMin,
        );
        if (verseAt.isAfter(now)) {
          final verse = getTodayVerse(targetDate);
          await _scheduleOneShot(
            id: _dailyVerseBaseId + d,
            scheduled: verseAt,
            channelId: 'orthodoxia_daily_verse',
            channelName: 'آية اليوم القبطية',
            channelDesc: 'إشعار يومي بآية من الكتاب المقدس',
            title: 'آية اليوم (${verse.reference})',
            body: verse.text,
          );
        }

        final saintAt = tz.TZDateTime(
          tz.local,
          targetDate.year,
          targetDate.month,
          targetDate.day,
          14,
          0,
        );
        if (saintAt.isAfter(now)) {
          final saintQuote = PatronSaintService.getDailyQuote(saint.id, targetDate);
          await _scheduleOneShot(
            id: _patronSaintBaseId + d,
            scheduled: saintAt,
            channelId: 'orthodoxia_patron_saint',
            channelName: 'رسالة شفيعك اليومي',
            channelDesc: 'أقوال وتعاليم شفيعك المختار يومياً',
            title: 'رسالة شفيعك: ${saint.shortName}',
            body: '«${saintQuote.quote}»',
          );
        }
      }
    }

    // 2. Optional Family Prayer Reminder
    if (storage.isFamilyPrayerReminderEnabled()) {
      await _scheduleDailyAt(
        id: _familyPrayerNotificationId,
        hour: storage.getFamilyPrayerHour(),
        minute: storage.getFamilyPrayerMinute(),
        channelId: 'orthodoxia_family_prayer',
        channelName: 'تذكير صلاة العائلة',
        channelDesc: 'تذكير لطيف واختياري لموعد صلاة العائلة',
        title: 'وقت صلاة العائلة',
        body: '«حيثما اجتمع اثنان أو ثلاثة باسمي فهناك أكون في وسطهم» — دقائق صلاة تملأ البيت سلاماً.',
      );
    } else {
      await _plugin.cancel(_familyPrayerNotificationId);
    }

    // 3. Real Agpeya Hour Alarms
    final prefs = await SharedPreferences.getInstance();
    final enabledHours = (prefs.getStringList(agpeyaAlarmsPrefsKey) ?? []).toSet();
    await syncAgpeyaAlarms(enabledHours);
  }

  /// Actually schedules or cancels real repeating daily OS notifications for each Agpeya hour!
  Future<void> syncAgpeyaAlarms(Set<String> enabledHourIds) async {
    await init();
    if (!_initialized) return;

    for (final entry in agpeyaAlarmCatalog.entries) {
      final slot = entry.value;
      if (enabledHourIds.contains(entry.key)) {
        await _scheduleDailyAt(
          id: slot.id,
          hour: slot.hour,
          minute: slot.minute,
          channelId: 'orthodoxia_agpeya_alarms',
          channelName: 'منبّه سواعي الأجبية',
          channelDesc: 'تذكير يومي بمواعيد صلوات السواعي المختارة',
          title: slot.title,
          body: slot.body,
        );
      } else {
        await _plugin.cancel(slot.id);
      }
    }
  }

  Future<void> _scheduleOneShot({
    required int id,
    required tz.TZDateTime scheduled,
    required String channelId,
    required String channelName,
    required String channelDesc,
    required String title,
    required String body,
  }) async {
    try {
      final details = NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          channelName,
          channelDescription: channelDesc,
          importance: Importance.high,
          priority: Priority.high,
          styleInformation: BigTextStyleInformation(body),
        ),
        iOS: const DarwinNotificationDetails(),
      );
      await _plugin.zonedSchedule(
        id,
        title,
        body,
        scheduled,
        details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (e) {
      if (kDebugMode) debugPrint('Schedule one-shot error: $e');
    }
  }

  Future<void> _scheduleDailyAt({
    required int id,
    required int hour,
    required int minute,
    required String channelId,
    required String channelName,
    required String channelDesc,
    required String title,
    required String body,
  }) async {
    try {
      final now = tz.TZDateTime.now(tz.local);
      var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
      if (scheduled.isBefore(now)) {
        scheduled = scheduled.add(const Duration(days: 1));
      }

      final details = NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          channelName,
          channelDescription: channelDesc,
          importance: Importance.high,
          priority: Priority.high,
          styleInformation: BigTextStyleInformation(body),
        ),
        iOS: const DarwinNotificationDetails(),
      );

      await _plugin.zonedSchedule(
        id,
        title,
        body,
        scheduled,
        details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (e) {
      if (kDebugMode) debugPrint('Schedule notification error: $e');
    }
  }

  Future<void> sendTestDailyVerseNow() async {
    await init();
    if (!_initialized) return;
    final verse = getTodayVerse();
    try {
      await _plugin.show(
        9999,
        'آية اليوم (${verse.reference})',
        verse.text,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'orthodoxia_daily_verse',
            'آية اليوم القبطية',
            importance: Importance.high,
            priority: Priority.high,
            styleInformation: BigTextStyleInformation(verse.text),
          ),
          iOS: const DarwinNotificationDetails(),
        ),
      );
    } catch (_) {}
  }
}
