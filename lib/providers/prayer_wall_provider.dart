import 'package:flutter/material.dart';
import '../models/prayer_request_model.dart';

class PrayerWallProvider with ChangeNotifier {
  final List<PrayerRequest> _requests = [
    PrayerRequest(
      id: 'req_1',
      authorName: 'مريم عادل',
      isAnonymous: false,
      title: 'صلاة من أجل شفاء والدتي',
      content: 'أطلب صلواتكم المباركة من أجل والدتي التي تمر بوعكة صحية وتنتظر إجراء جراحة، بشفاعة أم النور ومارمينا.',
      createdAt: DateTime.now().subtract(const Duration(hours: 3)),
      prayedCount: 38,
    ),
    PrayerRequest(
      id: 'req_2',
      authorName: '',
      isAnonymous: true,
      title: 'طلبة صلاة من أجل السلام الداخلي والتوبة',
      content: 'أجاهد ضد فتور روحي وضيق فكري، أرجوكم اذكروني في صلواتكم الخاصة لكي يجدد الرب روحه القدوس في قلبي.',
      createdAt: DateTime.now().subtract(const Duration(hours: 8)),
      prayedCount: 64,
    ),
    PrayerRequest(
      id: 'req_3',
      authorName: 'مينا كمال',
      isAnonymous: false,
      title: 'صلاة لطلبة الثانوية العامة والجامعات',
      content: 'نرفع قلوبنا من أجل أبنائنا وبناتنا الطلاب ليمنحهم الرب حكمة وفهماً وسلاماً في الامتحانات.',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      prayedCount: 112,
    ),
  ];

  List<PrayerRequest> get requests => _requests;

  void togglePrayed(String id) {
    final idx = _requests.indexWhere((r) => r.id == id);
    if (idx != -1) {
      if (_requests[idx].hasPrayed) {
        _requests[idx].hasPrayed = false;
        _requests[idx].prayedCount = (_requests[idx].prayedCount - 1).clamp(0, 999999);
      } else {
        _requests[idx].hasPrayed = true;
        _requests[idx].prayedCount += 1;
      }
      notifyListeners();
    }
  }

  void addRequest({
    required String title,
    required String content,
    required bool isAnonymous,
    String? authorName,
  }) {
    final newReq = PrayerRequest(
      id: 'req_${DateTime.now().millisecondsSinceEpoch}',
      authorName: isAnonymous ? '' : (authorName ?? 'خادم في المسيح'),
      isAnonymous: isAnonymous,
      title: title,
      content: content,
      createdAt: DateTime.now(),
      prayedCount: 1,
      hasPrayed: true,
    );
    _requests.insert(0, newReq);
    notifyListeners();
  }
}
