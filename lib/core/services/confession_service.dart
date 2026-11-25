import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../models/confession_models.dart';
import 'firebase_service.dart';
import 'notification_service.dart';
import 'security_guard_service.dart';
import 'storage_service.dart';

/// Complete Pastoral Confession & Priest Directory Service:
/// Implements all 4 flows from the Coptic Orthodox Platform Usage Blueprint:
/// 1) Role-Based Entry & Diocese Priest Verification (pending -> approved / needs_info)
/// 2) Priest Dashboard («خدمتي النهارده»): open-ended start-time confession days, optional cap, 1-tap close
/// 3) Private Father of Confession Directory + Ready Priest Invite Share Text
/// 4) Atomic Deduplicated «هحضر» Confirmation + Optional Waitlist + Privacy-First Lock-Screen Notifications
class ConfessionService {
  static final ConfessionService _instance = ConfessionService._internal();
  factory ConfessionService() => _instance;
  ConfessionService._internal();

  /// Exact public invitation text for inviting Abona (personal choice remains private!)
  static const String priestInviteShareText =
      'يا أبونا، يسعدنا انضمام قدسك لتطبيق أرثوذكسيا. '
      'تقدر تسجّل كأب كاهن وتضيف مواعيد خدمة الاعترافات للشعب وتقرأ الخولاجي والأجبية والقطمارس من هنا:\n'
      'https://github.com/philo626/orthoxia';

  final FirebaseService _firebase = FirebaseService();
  final StorageService _storage = StorageService();
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _notifSub;
  final Set<String> _alertedNotifIds = {};
  bool _initialNotifBatchLoaded = false;

  FirebaseFirestore? get _db =>
      _firebase.isFirebaseReady ? FirebaseFirestore.instance : null;

  String? get currentUid => _firebase.currentUser?.uid;

  // ===========================================================================
  // 1. PRIEST VERIFICATION & ADMIN REVIEW
  // ===========================================================================

  Future<(bool, String)> submitOrUpdatePriestVerification({
    required String titlePrefix,
    required String displayName,
    required String diocese,
    required String church,
    String verificationNote = '',
    String phoneForVerification = '',
  }) async {
    final db = _db;
    final uid = currentUid;
    if (db == null || uid == null) {
      return (false, 'يُرجى تسجيل الدخول أولاً لإرسال طلب التفعيل.');
    }

    final safeName = SecurityGuardService.sanitizeText(displayName, maxLength: 80, allowNewlines: false);
    final safeDiocese = SecurityGuardService.sanitizeText(diocese, maxLength: 80, allowNewlines: false);
    final safeChurch = SecurityGuardService.sanitizeText(church, maxLength: 120, allowNewlines: false);
    final safeNote = SecurityGuardService.sanitizeText(verificationNote, maxLength: 300);
    final safePhone = SecurityGuardService.sanitizeText(phoneForVerification, maxLength: 30, allowNewlines: false);

    if (safeName.length < 2 || safeDiocese.length < 2 || safeChurch.length < 2) {
      return (false, 'من فضلك أكمل اسم قدسك والإيبارشية والكنيسة بشكل واضح.');
    }

    try {
      final ref = db.collection('priests').doc(uid);
      final existing = await ref.get();
      final currentStatus = existing.data()?['verificationStatus']?.toString();

      // If previously approved, preserve approved status; if needs_info or new, set pending
      final nextStatus = currentStatus == 'approved' ? 'approved' : 'pending';

      await ref.set({
        'priestUid': uid,
        'titlePrefix': titlePrefix == 'القمص' ? 'القمص' : 'القس',
        'displayName': safeName,
        'diocese': safeDiocese,
        'church': safeChurch,
        'verificationStatus': nextStatus,
        'verificationNote': safeNote,
        'phoneForVerification': safePhone,
        'adminFeedback': currentStatus == 'needs_info' ? '' : (existing.data()?['adminFeedback'] ?? ''),
        if (!existing.exists) 'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await _storage.setUserRole('priest');
      await _storage.setUserName('$titlePrefix $safeName');

      // Sync non-sensitive role marker to user profile
      try {
        await db.collection('users').doc(uid).set({
          'displayName': '$titlePrefix $safeName',
          'patronSaintId': _storage.getPatronSaintId(),
          'role': 'priest',
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } catch (_) {}

      return (
        true,
        nextStatus == 'approved'
            ? 'تم تحديث بيانات قدسك بنجاح.'
            : 'تم إرسال طلب تفعيل صفة الكاهن بنجاح. سيقوم المسؤول المفوّض بمراجعته قريباً.'
      );
    } catch (e) {
      if (kDebugMode) debugPrint('submitOrUpdatePriestVerification err: $e');
      return (false, 'تعذر إرسال الطلب حالياً. تأكد من الاتصال بالإنترنت وحاول مرة أخرى.');
    }
  }

  Stream<PriestProfile?> watchMyPriestProfile() {
    final db = _db;
    final uid = currentUid;
    if (db == null || uid == null) return Stream.value(null);
    return db.collection('priests').doc(uid).snapshots().map((snap) {
      if (!snap.exists || snap.data() == null) return null;
      return PriestProfile.fromMap(snap.id, snap.data()!);
    });
  }

  Future<PriestProfile?> getPriestByUid(String priestUid) async {
    final db = _db;
    if (db == null || priestUid.isEmpty) return null;
    try {
      final doc = await db.collection('priests').doc(priestUid).get();
      if (!doc.exists || doc.data() == null) return null;
      return PriestProfile.fromMap(doc.id, doc.data()!);
    } catch (_) {
      return null;
    }
  }

  /// Checks if the current signed-in user is registered in Firestore `admins/{uid}`
  Future<bool> isCurrentUserAdmin() async {
    final db = _db;
    final uid = currentUid;
    if (db == null || uid == null) return false;
    try {
      final doc = await db.collection('admins').doc(uid).get();
      return doc.exists;
    } catch (_) {
      return false;
    }
  }

  Stream<List<PriestProfile>> watchAllPriestsForAdmin() {
    final db = _db;
    if (db == null) return Stream.value(const []);
    return db.collection('priests').snapshots().map((snap) {
      final list = snap.docs.map((d) => PriestProfile.fromMap(d.id, d.data())).toList();
      list.sort((a, b) {
        // Pending first, then needsInfo, then approved
        int rank(PriestVerificationStatus s) =>
            s == PriestVerificationStatus.pending ? 0 : (s == PriestVerificationStatus.needsInfo ? 1 : 2);
        return rank(a.verificationStatus).compareTo(rank(b.verificationStatus));
      });
      return list;
    });
  }

  Future<(bool, String)> adminReviewPriest({
    required String priestUid,
    required PriestVerificationStatus newStatus,
    String feedback = '',
  }) async {
    final db = _db;
    if (db == null) return (false, 'لا يوجد اتصال.');
    try {
      await db.collection('priests').doc(priestUid).update({
        'verificationStatus': PriestProfile.statusToString(newStatus),
        'adminFeedback': SecurityGuardService.sanitizeText(feedback, maxLength: 300),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return (
        true,
        newStatus == PriestVerificationStatus.approved
            ? 'تم تفعيل حساب قدس أبونا وإظهاره في الدليل.'
            : 'تم إرسال ملاحظة استكمال البيانات لقدس أبونا.'
      );
    } catch (e) {
      return (false, 'تعذر تنفيذ الإجراء (تأكد من صلاحية المسؤول).');
    }
  }

  // ===========================================================================
  // 2. PUBLIC VERIFIED FATHERS DIRECTORY & PRIVATE SELECTION
  // ===========================================================================

  Stream<List<PriestProfile>> watchApprovedPriests() {
    final db = _db;
    if (db == null) return Stream.value(const []);
    return db
        .collection('priests')
        .where('verificationStatus', isEqualTo: 'approved')
        .snapshots()
        .map((snap) {
      final list = snap.docs.map((d) => PriestProfile.fromMap(d.id, d.data())).toList();
      list.sort((a, b) => a.fullDisplayName.compareTo(b.fullDisplayName));
      return list;
    });
  }

  Future<void> selectConfessionFather(PriestProfile priest) async {
    await _storage.setConfessionFather(
      uid: priest.priestUid,
      name: priest.fullDisplayName,
      church: priest.church,
      diocese: priest.diocese,
    );
    final db = _db;
    final uid = currentUid;
    if (db != null && uid != null) {
      try {
        await db.collection('users').doc(uid).set({
          'displayName': _storage.getUserName(),
          'patronSaintId': _storage.getPatronSaintId(),
          'role': _storage.getUserRole(),
          'confessionFatherUid': priest.priestUid,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } catch (_) {}
    }
  }

  // ===========================================================================
  // 3. PRIEST CONFESSION SESSIONS (OPEN START TIME, OPTIONAL CAP, INSTANT CLOSE)
  // ===========================================================================

  Future<(bool, String)> publishConfessionSession({
    required PriestProfile priest,
    required DateTime date,
    required String dayLabelAr,
    required String startTimeAr,
    int? maxAttendees,
    String locationNote = '',
  }) async {
    final db = _db;
    final uid = currentUid;
    if (db == null || uid == null) {
      return (false, 'يُرجى تسجيل الدخول والاتصال بالإنترنت أولاً.');
    }
    if (priest.verificationStatus != PriestVerificationStatus.approved) {
      return (false, 'نشر المواعيد للشعب يبدأ بعد التحقق من صفة الكاهن.');
    }

    final iso =
        '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

    try {
      await db.collection('confession_sessions').add({
        'priestUid': uid,
        'priestName': priest.fullDisplayName,
        'church': priest.church,
        'diocese': priest.diocese,
        'dateIso': iso,
        'dayLabelAr': SecurityGuardService.sanitizeText(dayLabelAr, maxLength: 60, allowNewlines: false),
        'startTimeAr': SecurityGuardService.sanitizeText(startTimeAr, maxLength: 40, allowNewlines: false),
        'locationNote': SecurityGuardService.sanitizeText(locationNote, maxLength: 120, allowNewlines: false),
        'maxAttendees': (maxAttendees != null && maxAttendees > 0) ? maxAttendees : null,
        'isOpen': true,
        'confirmedCount': 0,
        'waitlistCount': 0,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return (true, 'تم نشر الموعد للشعب بنجاح.');
    } catch (e) {
      if (kDebugMode) debugPrint('publishConfessionSession err: $e');
      return (false, 'تعذر نشر الموعد حالياً. تأكد من الاتصال بالإنترنت.');
    }
  }

  Future<bool> toggleSessionOpen(String sessionId, bool isOpen) async {
    final db = _db;
    if (db == null) return false;
    try {
      await db.collection('confession_sessions').doc(sessionId).update({
        'isOpen': isOpen,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> deleteSession(String sessionId) async {
    final db = _db;
    if (db == null) return false;
    try {
      await db.collection('confession_sessions').doc(sessionId).delete();
      return true;
    } catch (_) {
      return false;
    }
  }

  Stream<List<ConfessionSession>> watchPriestSessions(String priestUid) {
    final db = _db;
    if (db == null || priestUid.isEmpty) return Stream.value(const []);
    return db
        .collection('confession_sessions')
        .where('priestUid', isEqualTo: priestUid)
        .snapshots()
        .map((snap) {
      final list = snap.docs
          .map((d) => ConfessionSession.fromMap(d.id, d.data()))
          .toList();
      list.sort((a, b) => a.dateIso.compareTo(b.dateIso));
      return list;
    });
  }

  // ===========================================================================
  // 4. ATOMIC DEDUPLICATED «هحضر» REGISTRATION, WAITLIST & CANCELLATION
  // ===========================================================================

  Future<AttendanceActionResult> registerAttendance(
    ConfessionSession session, {
    bool allowWaitlist = false,
  }) async {
    final db = _db;
    final uid = currentUid;
    if (db == null || uid == null) {
      return const AttendanceActionResult(
        status: AttendanceActionStatus.notSignedIn,
        message: 'يُرجى تسجيل الدخول أولاً لتأكيد الحضور وإبلاغ قدس أبونا.',
      );
    }

    final attendeeName = SecurityGuardService.sanitizeText(
      _storage.getUserName(),
      maxLength: 60,
      allowNewlines: false,
    );
    final sessionRef = db.collection('confession_sessions').doc(session.id);
    final attendeeRef = sessionRef.collection('attendees').doc(uid);

    try {
      final result = await db.runTransaction<AttendanceActionResult>((tx) async {
        final sSnap = await tx.get(sessionRef);
        if (!sSnap.exists || sSnap.data() == null) {
          return const AttendanceActionResult(
            status: AttendanceActionStatus.sessionClosed,
            message: 'لم يعد هذا الموعد متاحاً.',
          );
        }
        final liveSession = ConfessionSession.fromMap(sSnap.id, sSnap.data()!);
        final aSnap = await tx.get(attendeeRef);
        final prevStatus = aSnap.exists ? '${aSnap.data()?['status'] ?? ''}' : '';

        // 1. Mathematical deduplication: tapping «هحضر» twice NEVER duplicates the name!
        if (prevStatus == 'confirmed') {
          return const AttendanceActionResult(
            status: AttendanceActionStatus.alreadyConfirmed,
            message: 'حضورك مسجّل بالفعل في قائمة قدس أبونا.',
          );
        }
        if (prevStatus == 'waitlist' && allowWaitlist) {
          return const AttendanceActionResult(
            status: AttendanceActionStatus.alreadyWaitlisted,
            message: 'أنت بالفعل في قائمة الانتظار لهذا اليوم.',
          );
        }

        // 2. Check if Abona closed registration
        if (!liveSession.isOpen) {
          return const AttendanceActionResult(
            status: AttendanceActionStatus.sessionClosed,
            message: 'أبونا قفل التسجيل لهذا اليوم. يمكنك اختيار يوم آخر.',
          );
        }

        // 3. Check optional daily limit
        if (liveSession.isFull) {
          if (!allowWaitlist) {
            return const AttendanceActionResult(
              status: AttendanceActionStatus.sessionFull,
              message: 'اكتمل العدد المحدد لهذا اليوم. يمكنك الانضمام لقائمة الانتظار أو اختيار يوم آخر.',
            );
          }
          tx.set(attendeeRef, {
            'attendeeUid': uid,
            'sessionId': session.id,
            'priestUid': liveSession.priestUid,
            'attendeeName': attendeeName.isEmpty ? 'ابن الكنيسة' : attendeeName,
            'status': 'waitlist',
            'dayLabelAr': liveSession.dayLabelAr,
            'startTimeAr': liveSession.startTimeAr,
            'updatedAt': FieldValue.serverTimestamp(),
          });
          tx.update(sessionRef, {
            'confirmedCount': liveSession.confirmedCount,
            'waitlistCount': liveSession.waitlistCount + 1,
            'updatedAt': FieldValue.serverTimestamp(),
          });
          return const AttendanceActionResult(
            status: AttendanceActionStatus.waitlisted,
            message: 'تمت إضافتك في قائمة الانتظار لهذا اليوم.',
          );
        }

        // 4. Open & space available -> Confirm attendance!
        final wasWaitlist = prevStatus == 'waitlist';
        tx.set(attendeeRef, {
          'attendeeUid': uid,
          'sessionId': session.id,
          'priestUid': liveSession.priestUid,
          'attendeeName': attendeeName.isEmpty ? 'ابن الكنيسة' : attendeeName,
          'status': 'confirmed',
          'dayLabelAr': liveSession.dayLabelAr,
          'startTimeAr': liveSession.startTimeAr,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        tx.update(sessionRef, {
          'confirmedCount': liveSession.confirmedCount + 1,
          'waitlistCount': wasWaitlist && liveSession.waitlistCount > 0
              ? liveSession.waitlistCount - 1
              : liveSession.waitlistCount,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        return const AttendanceActionResult(
          status: AttendanceActionStatus.confirmed,
          message: 'اتسجّل حضورك بنجاح وتم إبلاغ قدس أبونا.',
        );
      });

      // Emit ONE privacy-safe notification document for Abona (only on fresh confirmation/waitlist)
      if (result.status == AttendanceActionStatus.confirmed ||
          result.status == AttendanceActionStatus.waitlisted) {
        try {
          await db
              .collection('priest_notifications')
              .doc(session.priestUid)
              .collection('items')
              .add({
            'type': result.status == AttendanceActionStatus.waitlisted
                ? 'waitlist'
                : 'registered',
            'attendeeUid': uid,
            'attendeeName': attendeeName.isEmpty ? 'ابن الكنيسة' : attendeeName,
            'sessionId': session.id,
            'dayLabelAr': session.dayLabelAr,
            'startTimeAr': session.startTimeAr,
            'read': false,
            'createdAt': FieldValue.serverTimestamp(),
          });
        } catch (_) {}
      }

      return result;
    } catch (e) {
      if (kDebugMode) debugPrint('registerAttendance err: $e');
      return const AttendanceActionResult(
        status: AttendanceActionStatus.offlineError,
        message: 'تسجيل الحضور يحتاج اتصالاً بالإنترنت. حاول مرة أخرى.',
      );
    }
  }

  Future<AttendanceActionResult> cancelMyAttendance(ConfessionSession session) async {
    final db = _db;
    final uid = currentUid;
    if (db == null || uid == null) {
      return const AttendanceActionResult(
        status: AttendanceActionStatus.notSignedIn,
        message: 'يُرجى تسجيل الدخول أولاً.',
      );
    }

    final attendeeName = SecurityGuardService.sanitizeText(
      _storage.getUserName(),
      maxLength: 60,
      allowNewlines: false,
    );
    final sessionRef = db.collection('confession_sessions').doc(session.id);
    final attendeeRef = sessionRef.collection('attendees').doc(uid);

    try {
      await db.runTransaction((tx) async {
        final sSnap = await tx.get(sessionRef);
        final aSnap = await tx.get(attendeeRef);
        if (!sSnap.exists || !aSnap.exists) return;
        final live = ConfessionSession.fromMap(sSnap.id, sSnap.data()!);
        final prevStatus = '${aSnap.data()?['status'] ?? ''}';
        if (prevStatus == 'cancelled') return;

        tx.set(attendeeRef, {
          'attendeeUid': uid,
          'sessionId': session.id,
          'priestUid': live.priestUid,
          'attendeeName': attendeeName.isEmpty ? 'ابن الكنيسة' : attendeeName,
          'status': 'cancelled',
          'dayLabelAr': live.dayLabelAr,
          'startTimeAr': live.startTimeAr,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        tx.update(sessionRef, {
          'confirmedCount': prevStatus == 'confirmed' && live.confirmedCount > 0
              ? live.confirmedCount - 1
              : live.confirmedCount,
          'waitlistCount': prevStatus == 'waitlist' && live.waitlistCount > 0
              ? live.waitlistCount - 1
              : live.waitlistCount,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });

      // Notify Abona that the list updated
      try {
        await db
            .collection('priest_notifications')
            .doc(session.priestUid)
            .collection('items')
            .add({
          'type': 'cancelled',
          'attendeeUid': uid,
          'attendeeName': attendeeName.isEmpty ? 'ابن الكنيسة' : attendeeName,
          'sessionId': session.id,
          'dayLabelAr': session.dayLabelAr,
          'startTimeAr': session.startTimeAr,
          'read': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      } catch (_) {}

      return const AttendanceActionResult(
        status: AttendanceActionStatus.cancelled,
        message: 'تم تسجيل اعتذارك وتحديث القائمة عند قدس أبونا.',
      );
    } catch (_) {
      return const AttendanceActionResult(
        status: AttendanceActionStatus.offlineError,
        message: 'تعذر تحديث الموعد حالياً. تأكد من الاتصال بالإنترنت.',
      );
    }
  }

  Stream<ConfessionAttendee?> watchMyAttendance(String sessionId) {
    final db = _db;
    final uid = currentUid;
    if (db == null || uid == null || sessionId.isEmpty) return Stream.value(null);
    return db
        .collection('confession_sessions')
        .doc(sessionId)
        .collection('attendees')
        .doc(uid)
        .snapshots()
        .map((snap) {
      if (!snap.exists || snap.data() == null) return null;
      return ConfessionAttendee.fromMap(snap.id, snap.data()!);
    });
  }

  Stream<List<ConfessionAttendee>> watchSessionAttendeesForPriest(String sessionId) {
    final db = _db;
    if (db == null || sessionId.isEmpty) return Stream.value(const []);
    return db
        .collection('confession_sessions')
        .doc(sessionId)
        .collection('attendees')
        .snapshots()
        .map((snap) {
      final list = snap.docs
          .map((d) => ConfessionAttendee.fromMap(d.id, d.data()))
          .where((a) => a.status != 'cancelled')
          .toList();
      list.sort((a, b) {
        if (a.status != b.status) return a.status == 'confirmed' ? -1 : 1;
        return (a.updatedAt ?? DateTime(2000)).compareTo(b.updatedAt ?? DateTime(2000));
      });
      return list;
    });
  }

  // ===========================================================================
  // 5. PRIEST REAL-TIME PRIVACY-FIRST NOTIFICATIONS
  // ===========================================================================

  Stream<List<PriestNotificationItem>> watchPriestNotifications() {
    final db = _db;
    final uid = currentUid;
    if (db == null || uid == null) return Stream.value(const []);
    return db
        .collection('priest_notifications')
        .doc(uid)
        .collection('items')
        .orderBy('createdAt', descending: true)
        .limit(40)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => PriestNotificationItem.fromMap(d.id, d.data())).toList());
  }

  Future<void> markAllNotificationsRead() async {
    final db = _db;
    final uid = currentUid;
    if (db == null || uid == null) return;
    try {
      final unread = await db
          .collection('priest_notifications')
          .doc(uid)
          .collection('items')
          .where('read', isEqualTo: false)
          .get();
      for (final doc in unread.docs) {
        await doc.reference.update({'read': true});
      }
    } catch (_) {}
  }

  /// Starts real-time listener for Abona so new arrivals trigger the privacy-safe
  /// lock-screen alert: «يا أبونا، فيه تسجيل حضور جديد» (ZERO name leaked on lock screen!).
  void startPriestRealtimeAlertListener() {
    final db = _db;
    final uid = currentUid;
    if (db == null || uid == null || !_storage.isPriestRole()) return;

    _notifSub?.cancel();
    _initialNotifBatchLoaded = false;
    _notifSub = db
        .collection('priest_notifications')
        .doc(uid)
        .collection('items')
        .where('read', isEqualTo: false)
        .snapshots()
        .listen((snap) {
      if (!_initialNotifBatchLoaded) {
        for (final d in snap.docs) {
          _alertedNotifIds.add(d.id);
        }
        _initialNotifBatchLoaded = true;
        return;
      }
      for (final change in snap.docChanges) {
        if (change.type == DocumentChangeType.added &&
            !_alertedNotifIds.contains(change.doc.id)) {
          _alertedNotifIds.add(change.doc.id);
          final type = '${change.doc.data()?['type'] ?? 'registered'}';
          NotificationService().showPrivacySafePriestAlert(
            isCancellation: type == 'cancelled',
          );
        }
      }
    }, onError: (_) {});
  }

  void stopPriestRealtimeAlertListener() {
    _notifSub?.cancel();
    _notifSub = null;
  }
}
