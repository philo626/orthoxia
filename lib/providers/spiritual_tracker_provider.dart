import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/services/storage_service.dart';
import '../models/spiritual_tracker_model.dart';

class SpiritualTrackerProvider with ChangeNotifier {
  final StorageService _storage = StorageService();

  List<SpiritualLog> _logs = [];
  List<ConscienceQuestion> _conscienceQuestions = [];
  bool _isConscienceLocked = false;

  List<SpiritualLog> get logs => _logs;
  List<ConscienceQuestion> get conscienceQuestions => _conscienceQuestions;
  bool get isConscienceLocked => _isConscienceLocked;

  SpiritualTrackerProvider() {
    _loadData();
  }

  void _loadData() {
    _logs = _storage.getSpiritualLogs();
    _conscienceQuestions = _storage.getConscienceQuestions();
    notifyListeners();
  }

  SpiritualLog get todayLog {
    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final index = _logs.indexWhere((l) => l.date == todayStr);
    if (index != -1) {
      return _logs[index];
    } else {
      final newLog = SpiritualLog(date: todayStr);
      _logs.add(newLog);
      _storage.saveSpiritualLogs(_logs);
      return newLog;
    }
  }

  /// Returns REAL daily logs for the last 7 calendar days (oldest -> today).
  /// Days with no recorded activity honestly return 0 (ZERO fake/hardcoded data).
  List<SpiritualLog> get last7DaysLogs {
    final now = DateTime.now();
    final map = {for (final l in _logs) l.date: l};
    return List.generate(7, (idx) {
      final day = now.subtract(Duration(days: 6 - idx));
      final key = DateFormat('yyyy-MM-dd').format(day);
      return map[key] ?? SpiritualLog(date: key);
    });
  }

  /// Real consecutive active spiritual days ending today (or yesterday).
  int get activeStreakDays {
    final map = {for (final l in _logs) l.date: l};
    int streak = 0;
    final now = DateTime.now();
    for (int offset = 0; offset < 365; offset++) {
      final day = now.subtract(Duration(days: offset));
      final key = DateFormat('yyyy-MM-dd').format(day);
      final log = map[key];
      final hasActivity = log != null &&
          (log.agpeyaHoursCompleted > 0 ||
              log.bibleChaptersRead > 0 ||
              log.personalPrayerMinutes > 0 ||
              log.tookCommunion ||
              log.actsOfCharity);
      if (hasActivity) {
        streak++;
      } else if (offset > 0) {
        break;
      }
    }
    return streak;
  }

  void incrementBibleChapters() {
    todayLog.bibleChaptersRead += 1;
    _storage.saveSpiritualLogs(_logs);
    notifyListeners();
  }

  void incrementAgpeyaHours() {
    if (todayLog.agpeyaHoursCompleted < 7) {
      todayLog.agpeyaHoursCompleted += 1;
      _storage.saveSpiritualLogs(_logs);
      notifyListeners();
    }
  }

  void addPersonalPrayerMinutes(int minutes) {
    todayLog.personalPrayerMinutes += minutes;
    _storage.saveSpiritualLogs(_logs);
    notifyListeners();
  }

  void toggleCommunion() {
    todayLog.tookCommunion = !todayLog.tookCommunion;
    _storage.saveSpiritualLogs(_logs);
    notifyListeners();
  }

  void toggleCharity() {
    todayLog.actsOfCharity = !todayLog.actsOfCharity;
    _storage.saveSpiritualLogs(_logs);
    notifyListeners();
  }

  // Conscience methods
  void toggleQuestion(String id) {
    final idx = _conscienceQuestions.indexWhere((q) => q.id == id);
    if (idx != -1) {
      _conscienceQuestions[idx].isChecked =
          !_conscienceQuestions[idx].isChecked;
      _storage.saveConscienceQuestions(_conscienceQuestions);
      notifyListeners();
    }
  }

  void updateQuestionNote(String id, String note) {
    final idx = _conscienceQuestions.indexWhere((q) => q.id == id);
    if (idx != -1) {
      _conscienceQuestions[idx].personalNote = note;
      _storage.saveConscienceQuestions(_conscienceQuestions);
      notifyListeners();
    }
  }

  void clearConscienceNotes() {
    for (var q in _conscienceQuestions) {
      q.isChecked = false;
      q.personalNote = '';
    }
    _storage.clearConscienceNotes();
    notifyListeners();
  }

  void toggleLockConscience(bool locked) {
    _isConscienceLocked = locked;
    notifyListeners();
  }

  String get encouragingVerse {
    const verses = [
      '«لاَ تَشْمَتِي بِي يَا عَدُوَّتِي، إِذَا سَقَطْتُ أَقُومُ. إِذَا جَلَسْتُ فِي الظُّلْمَةِ فَالرَّبُّ نُورٌ لِي» (ميخا ٧: ٨)',
      '«تَعَالَوْا إِلَيَّ يَا جَمِيعَ الْمُتْعَبِينَ وَالثَّقِيلِي الأَحْمَالِ، وَأَنَا أُرِيحُكُمْ» (متى ١١: ٢٨)',
      '«إِنْ سَلَكْنَا فِي النُّورِ كَمَا هُوَ فِي النُّورِ، فَلَنَا شَرِكَةٌ بَعْضِنَا مَعَ بَعْضٍ» (١ يو ١: ٧)',
      '«أَسْتَطِيعُ كُلَّ شَيْءٍ فِي الْمَسِيحِ الَّذِي يُقَوِّينِي» (في ٤: ١٣)',
      '«لاَ تَخَفْ لأَنِّي مَعَكَ. لاَ تَتَلَفَّتْ لأَنِّي إِلَهُكَ. قَدْ أَيَّدْتُكَ وَأَعَنْتُكَ» (إش ٤١: ١٠)',
    ];
    return verses[DateTime.now().day % verses.length];
  }
}
