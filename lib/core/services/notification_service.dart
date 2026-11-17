import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'patron_saint_service.dart';
import 'storage_service.dart';

class DailyBibleVerse {
  final String text;
  final String reference;

  const DailyBibleVerse({required this.text, required this.reference});
}

/// Manages Daily Orthodox Verse Notifications (like Orsozoxi) +
/// Optional, Gentle Family Prayer Reminders (never forced!).
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  static const int _dailyVerseNotificationId = 1001;
  static const int _familyPrayerNotificationId = 2001;
  static const int _patronSaintNotificationId = 3001;

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  static const List<DailyBibleVerse> dailyVerses = [
    DailyBibleVerse(
      text: '«اَلرَّبُّ رَاعِيَّ فَلاَ يُعْوِزُنِي شَيْءٌ. فِي مَرَاعٍ خُضْرٍ يُرْبِضُنِي. إِلَى مِيَاهِ الرَّاحَةِ يُورِدُنِي»',
      reference: 'مزمور ٢٣: ١-٢',
    ),
    DailyBibleVerse(
      text: '«تَعَالَوْا إِلَيَّ يَا جَمِيعَ الْمُتْعَبِينَ وَالثَّقِيلِي الأَحْمَالِ، وَأَنَا أُرِيحُكُمْ»',
      reference: 'متى ١١: ٢٨',
    ),
    DailyBibleVerse(
      text: '«لاَ تَخَفْ لأَنِّي مَعَكَ. لاَ تَتَلَفَّتْ لأَنِّي إِلهُكَ. قَدْ أَيَّدْتُكَ وَأَعَنْتُكَ»',
      reference: 'إشعياء ٤١: ١٠',
    ),
    DailyBibleVerse(
      text: '«أَسْتَطِيعُ كُلَّ شَيْءٍ فِي الْمَسِيحِ الَّذِي يُقَوِّينِي»',
      reference: 'فيلبي ٤: ١٣',
    ),
    DailyBibleVerse(
      text: '«اَلرَّبُّ نُورِي وَخَلاَصِي، مِمَّنْ أَخَافُ؟ الرَّبُّ حِصْنُ حَيَاتِي، مِمَّنْ أَرْتَعِبُ؟»',
      reference: 'مزمور ٢٧: ١',
    ),
    DailyBibleVerse(
      text: '«سَلاَمًا أَتْرُكُ لَكُمْ. سَلاَمِي أُعْطِيكُمْ. لاَ تَضْطَرِبْ قُلُوبُكُمْ وَلاَ تَرْهَبْ»',
      reference: 'يوحنا ١٤: ٢٧',
    ),
    DailyBibleVerse(
      text: '«نَعْلَمُ أَنَّ كُلَّ الأَشْيَاءِ تَعْمَلُ مَعًا لِلْخَيْرِ لِلَّذِينَ يُحِبُّونَ اللهَ»',
      reference: 'رومية ٨: ٢٨',
    ),
    DailyBibleVerse(
      text: '«تَوَكَّلْ عَلَى الرَّبِّ بِكُلِّ قَلْبِكَ، وَعَلَى فَهْمِكَ لاَ تَعْتَمِدْ»',
      reference: 'أمثال ٣: ٥',
    ),
    DailyBibleVerse(
      text: '«أَلْقِ عَلَى الرَّبِّ هَمَّكَ فَهُوَ يَعُولُكَ. لاَ يَدَعُ الصِّدِّيقَ يَتَزَعْزَعُ إِلَى الأَبَدِ»',
      reference: 'مزمور ٥٥: ٢٢',
    ),
    DailyBibleVerse(
      text: '«اِفْرَحُوا فِي الرَّبِّ كُلَّ حِينٍ، وَأَقُولُ أَيْضًا: افْرَحُوا»',
      reference: 'فيلبي ٤: ٤',
    ),
    DailyBibleVerse(
      text: '«اَلرَّبُّ يُقَاتِلُ عَنْكُمْ وَأَنْتُمْ تَصْمُتُونَ»',
      reference: 'خروج ١٤: ١٤',
    ),
    DailyBibleVerse(
      text: '«لأَنَّهُ هكَذَا أَحَبَّ اللهُ الْعَالَمَ حَتَّى بَذَلَ ابْنَهُ الْوَحِيدَ، لِكَيْ لاَ يَهْلِكَ كُلُّ مَنْ يُؤْمِنُ بِهِ»',
      reference: 'يوحنا ٣: ١٦',
    ),
    DailyBibleVerse(
      text: '«سِرَاجٌ لِرِجْلِي كَلاَمُكَ وَنُورٌ لِسَبِيلِي»',
      reference: 'مزمور ١١٩: ١٠٥',
    ),
    DailyBibleVerse(
      text: '«تَكْفِيكَ نِعْمَتِي، لأَنَّ قُوَّتِي فِي الضَّعْفِ تُكْمَلُ»',
      reference: '٢ كورنثوس ١٢: ٩',
    ),
    DailyBibleVerse(
      text: '«مَلْقِينَ كُلَّ هَمِّكُمْ عَلَيْهِ، لأَنَّهُ هُوَ يَعْتَنِي بِكُمْ»',
      reference: '١ بطرس ٥: ٧',
    ),
    DailyBibleVerse(
      text: '«أَنَا هُوَ نُورُ الْعَالَمِ. مَنْ يَتْبَعْنِي فَلاَ يَمْشِي فِي الظُّلْمَةِ بَلْ يَكُونُ لَهُ نُورُ الْحَيَاةِ»',
      reference: 'يوحنا ٨: ١٢',
    ),
    DailyBibleVerse(
      text: '«اُطْلُبُوا أَوَّلاً مَلَكُوتَ اللهِ وَبِرَّهُ، وَهذِهِ كُلُّهَا تُزَادُ لَكُمْ»',
      reference: 'متى ٦: ٣٣',
    ),
    DailyBibleVerse(
      text: '«لاَ تَهْتَمُّوا بِشَيْءٍ، بَلْ فِي كُلِّ شَيْءٍ بِالصَّلاَةِ وَالدُّعَاءِ مَعَ الشُّكْرِ، لِتُعْلَمْ طِلْبَاتُكُمْ لَدَى اللهِ»',
      reference: 'فيلبي ٤: ٦',
    ),
    DailyBibleVerse(
      text: '«قَلْبًا نَقِيًّا اخْلُقْ فِيَّ يَا اللهُ، وَرُوحًا مُسْتَقِيمًا جَدِّدْ فِي دَاخِلِي»',
      reference: 'مزمور ٥١: ١٠',
    ),
    DailyBibleVerse(
      text: '«أَمَّا أَنَا وَبَيْتِي فَنَعْبُدُ الرَّبَّ»',
      reference: 'يشوع ٢٤: ١٥',
    ),
    DailyBibleVerse(
      text: '«لأَنَّهُ حَيْثُمَا اجْتَمَعَ اثْنَانِ أَوْ ثَلاَثَةٌ بِاسْمِي فَهُنَاكَ أَكُونُ فِي وَسْطِهِمْ»',
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
      debugPrint('NotificationService init skipped: $e');
    }
  }

  /// Requests Android 13+ / iOS Notification Permission politely
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

  /// Schedules or cancels Daily Verse + Optional Family Prayer Reminder based on user preferences
  Future<void> syncScheduledNotifications() async {
    await init();
    if (!_initialized) return;

    final storage = StorageService();

    // 1. Daily Verse Notification (like Orsozoxi)
    if (storage.isDailyVerseNotificationEnabled()) {
      final verse = getTodayVerse();
      final saint = PatronSaintService.getSaintById(storage.getPatronSaintId());
      final saintQuote = PatronSaintService.getDailyQuote(saint.id);

      await _scheduleDailyAt(
        id: _dailyVerseNotificationId,
        hour: storage.getDailyVerseHour(),
        minute: storage.getDailyVerseMinute(),
        channelId: 'orthodoxia_daily_verse',
        channelName: 'آية اليوم القبطية',
        channelDesc: 'إشعار يومي بآية من الكتاب المقدس ورسالة روحية',
        title: '✝ آية اليوم لك (${verse.reference})',
        body: verse.text,
      );

      // Also gentle afternoon quote from user's chosen Patron Saint!
      await _scheduleDailyAt(
        id: _patronSaintNotificationId,
        hour: 14,
        minute: 0,
        channelId: 'orthodoxia_patron_saint',
        channelName: 'رسالة شفيعك اليومي',
        channelDesc: 'أقوال وتعاليم شفيعك المختار يومياً',
        title: '🕊 رسالة شفيعك: ${saint.shortName}',
        body: '«${saintQuote.quote}»',
      );
    } else {
      await _plugin.cancel(_dailyVerseNotificationId);
      await _plugin.cancel(_patronSaintNotificationId);
    }

    // 2. Optional Family Prayer Reminder (NEVER forced — strictly opt-in!)
    if (storage.isFamilyPrayerReminderEnabled()) {
      await _scheduleDailyAt(
        id: _familyPrayerNotificationId,
        hour: storage.getFamilyPrayerHour(),
        minute: storage.getFamilyPrayerMinute(),
        channelId: 'orthodoxia_family_prayer',
        channelName: 'تذكير صلاة العائلة (اختياري)',
        channelDesc: 'تذكير لطيف واختياري لموعد صلاة العائلة',
        title: '🙏 وقت صلاة العائلة (لو حابين نصلّي سوا)',
        body: '«حيثما اجتمع اثنان أو ثلاثة باسمي فهناك أكون في وسطهم» — دقيقتين صلاة مع العائلة تملأ البيت سلاماً.',
      );
    } else {
      await _plugin.cancel(_familyPrayerNotificationId);
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
      debugPrint('Schedule notification error: $e');
    }
  }

  /// Sends an immediate sample notification so user can preview Daily Verse right away
  Future<void> sendTestDailyVerseNow() async {
    await init();
    if (!_initialized) return;
    final verse = getTodayVerse();
    try {
      await _plugin.show(
        9999,
        '✝ آية اليوم (${verse.reference})',
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
