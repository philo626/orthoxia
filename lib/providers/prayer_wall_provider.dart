import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/services/firebase_service.dart';
import '../core/services/storage_service.dart';
import '../models/prayer_request_model.dart';

class PrayerWallProvider with ChangeNotifier {
  static const _prayedIdsKey = 'prayer_wall_prayed_ids_v1';

  final FirebaseService _firebase = FirebaseService();
  StreamSubscription<List<PrayerRequest>>? _cloudSub;

  final List<PrayerRequest> _localFallbackRequests = [
    PrayerRequest(
      id: 'req_1',
      authorName: 'مريم عادل',
      isAnonymous: false,
      title: 'صلاة من أجل شفاء والدتي',
      content:
          'أطلب صلواتكم المباركة من أجل والدتي التي تمر بوعكة صحية وتنتظر إجراء جراحة، بشفاعة أم النور ومارمينا.',
      createdAt: DateTime.now().subtract(const Duration(hours: 3)),
      prayedCount: 38,
    ),
    PrayerRequest(
      id: 'req_2',
      authorName: '',
      isAnonymous: true,
      title: 'طلبة صلاة من أجل السلام الداخلي والتوبة',
      content:
          'أجاهد ضد فتور روحي وضيق فكري، أرجوكم اذكروني في صلواتكم الخاصة لكي يجدد الرب روحه القدوس في قلبي.',
      createdAt: DateTime.now().subtract(const Duration(hours: 8)),
      prayedCount: 64,
    ),
    PrayerRequest(
      id: 'req_3',
      authorName: 'مينا كمال',
      isAnonymous: false,
      title: 'صلاة لطلبة الثانوية العامة والجامعات',
      content:
          'نرفع قلوبنا من أجل أبنائنا وبناتنا الطلاب ليمنحهم الرب حكمة وفهماً وسلاماً في الامتحانات.',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      prayedCount: 112,
    ),
  ];

  List<PrayerRequest> _requests = [];
  final Set<String> _prayedIds = {};
  bool _hasCloudData = false;

  PrayerWallProvider() {
    _requests = List.of(_localFallbackRequests);
    _restorePrayedIds();
    _attachCloudStreamIfReady();
  }

  Future<void> _restorePrayedIds() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getStringList(_prayedIdsKey) ?? const [];
      _prayedIds.addAll(saved);
      for (final req in _requests) {
        if (_prayedIds.contains(req.id)) req.hasPrayed = true;
      }
      notifyListeners();
    } catch (_) {}
  }

  Future<void> _persistPrayedIds() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_prayedIdsKey, _prayedIds.toList());
    } catch (_) {}
  }

  void _attachCloudStreamIfReady() {
    final stream = _firebase.watchPrayerWall();
    if (stream == null) return;
    _cloudSub = stream.listen(
      (cloudItems) {
        _hasCloudData = true;
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

  bool get isCloudSynced => _firebase.isFirebaseReady && _hasCloudData;
  bool get isSignedIn => _firebase.currentUser != null;
  List<PrayerRequest> get requests => _requests;

  bool isOwnRequest(PrayerRequest req) {
    final uid = _firebase.currentUser?.uid;
    if (uid == null || uid.isEmpty) return false;
    return req.authorUid.isNotEmpty && req.authorUid == uid;
  }

  void togglePrayed(String id) {
    final idx = _requests.indexWhere((r) => r.id == id);
    if (idx != -1) {
      int delta;
      if (_requests[idx].hasPrayed) {
        _requests[idx].hasPrayed = false;
        _prayedIds.remove(id);
        _requests[idx].prayedCount =
            (_requests[idx].prayedCount - 1).clamp(0, 999999);
        delta = -1;
      } else {
        _requests[idx].hasPrayed = true;
        _prayedIds.add(id);
        _requests[idx].prayedCount += 1;
        delta = 1;
      }
      _persistPrayedIds();
      _firebase.incrementPrayedCountInCloud(id, delta);
      notifyListeners();
    }
  }

  /// Adds a prayer request. When Firebase is active, requires sign-in and
  /// returns an Arabic error message if posting fails (never fakes success!).
  Future<String?> addRequest({
    required String title,
    required String content,
    required bool isAnonymous,
    String? authorName,
  }) async {
    final resolvedAuthor = isAnonymous
        ? ''
        : ((authorName != null && authorName.trim().isNotEmpty)
            ? authorName.trim()
            : StorageService().getUserName());

    if (_firebase.isFirebaseReady) {
      final err = await _firebase.addPrayerRequestToCloud(
        title: title,
        content: content,
        isAnonymous: isAnonymous,
        authorName: resolvedAuthor,
      );
      if (err != null) return err;
      // Cloud stream will automatically update `_requests` with real doc ID
      return null;
    }

    // Offline-only local mode (unit tests or uninitialized Firebase)
    final newReq = PrayerRequest(
      id: 'req_${DateTime.now().millisecondsSinceEpoch}',
      authorName: resolvedAuthor,
      isAnonymous: isAnonymous,
      title: title.trim(),
      content: content.trim(),
      createdAt: DateTime.now(),
      prayedCount: 1,
      hasPrayed: true,
    );
    _requests.insert(0, newReq);
    notifyListeners();
    return null;
  }

  Future<bool> deleteRequest(String id) async {
    if (_firebase.isFirebaseReady && !id.startsWith('req_')) {
      final ok = await _firebase.deletePrayerRequestFromCloud(id);
      if (ok) {
        _requests.removeWhere((r) => r.id == id);
        notifyListeners();
      }
      return ok;
    }
    _requests.removeWhere((r) => r.id == id);
    notifyListeners();
    return true;
  }

  @override
  void dispose() {
    _cloudSub?.cancel();
    super.dispose();
  }
}
