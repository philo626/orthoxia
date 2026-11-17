import 'dart:async';
import 'package:flutter/material.dart';
import '../core/services/firebase_service.dart';
import '../core/services/storage_service.dart';
import '../models/prayer_request_model.dart';

class PrayerWallProvider with ChangeNotifier {
  final FirebaseService _firebase = FirebaseService();
  StreamSubscription<List<PrayerRequest>>? _cloudSub;

  final List<PrayerRequest> _localFallbackRequests = [
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

  List<PrayerRequest> _requests = [];
  final Set<String> _prayedIds = {};

  PrayerWallProvider() {
    _requests = List.of(_localFallbackRequests);
    _attachCloudStreamIfReady();
  }

  void _attachCloudStreamIfReady() {
    final stream = _firebase.watchPrayerWall();
    if (stream == null) return;
    _cloudSub = stream.listen(
      (cloudItems) {
        if (cloudItems.isNotEmpty) {
          for (final item in cloudItems) {
            if (_prayedIds.contains(item.id)) {
              item.hasPrayed = true;
            }
          }
          _requests = cloudItems;
          notifyListeners();
        }
      },
      onError: (_) {},
    );
  }

  bool get isCloudSynced => _firebase.isFirebaseReady;
  List<PrayerRequest> get requests => _requests;

  void togglePrayed(String id) {
    final idx = _requests.indexWhere((r) => r.id == id);
    if (idx != -1) {
      int delta;
      if (_requests[idx].hasPrayed) {
        _requests[idx].hasPrayed = false;
        _prayedIds.remove(id);
        _requests[idx].prayedCount = (_requests[idx].prayedCount - 1).clamp(0, 999999);
        delta = -1;
      } else {
        _requests[idx].hasPrayed = true;
        _prayedIds.add(id);
        _requests[idx].prayedCount += 1;
        delta = 1;
      }
      _firebase.incrementPrayedCountInCloud(id, delta);
      notifyListeners();
    }
  }

  void addRequest({
    required String title,
    required String content,
    required bool isAnonymous,
    String? authorName,
  }) {
    final resolvedAuthor = isAnonymous
        ? ''
        : ((authorName != null && authorName.trim().isNotEmpty)
            ? authorName.trim()
            : StorageService().getUserName());

    final newReq = PrayerRequest(
      id: 'req_${DateTime.now().millisecondsSinceEpoch}',
      authorName: resolvedAuthor,
      isAnonymous: isAnonymous,
      title: title,
      content: content,
      createdAt: DateTime.now(),
      prayedCount: 1,
      hasPrayed: true,
    );
    _requests.insert(0, newReq);
    _firebase.addPrayerRequestToCloud(
      title: title,
      content: content,
      isAnonymous: isAnonymous,
      authorName: resolvedAuthor,
    );
    notifyListeners();
  }

  @override
  void dispose() {
    _cloudSub?.cancel();
    super.dispose();
  }
}
