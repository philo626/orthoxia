import 'dart:async';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../models/confession_models.dart';
import 'firebase_service.dart';
import 'notification_service.dart';
import 'security_guard_service.dart';
import 'storage_service.dart';

/// Complete Pastoral Confession, Dual-Code Trust & Priest Directory Service:
/// 1) Private Confession Code (`AB-XXXX`): Fixed code per priest — works IMMEDIATELY for
///    Abona's own confession children (via WhatsApp / church), WITHOUT listing publicly.
/// 2) Peer-Priest Single-Use Vouch Code (`KN-XXXX`): Verified priests issue unique 1-time
///    7-day codes to vouch for fellow priests -> instant Public Directory ✓ verification!
/// 3) Diocese/Admin Verification Queue (pending -> approved / needs_info)
/// 4) Open-Start-Time Confession Sessions + Atomic Deduplicated «هحضر» + Privacy-First Alerts
class ConfessionService {
  static final ConfessionService _instance = ConfessionService._internal();
  factory ConfessionService() => _instance;
  ConfessionService._internal();

  /// General invitation text when a congregation member invites their priest to join
  static const String priestInviteShareText =
      'يا قدس أبونا، يسعدنا انضمام قدسك لتطبيق أرثوذكسيا.\n'
      'التطبيق يضم واجهة خاصة للآباء الكهنة (الخولاجي بصلوات الكاهن السرية، رفع البخور، الـ ٣٩ قسمة، القطمارس، دفتر الافتقاد وأسماء المذبح، وتنظيم مواعيد الاعتراف بكود خاص لأولاد قدسك):\n'
      'https://github.com/philo626/orthoxia';

  /// Share text for Abona's PRIVATE fixed code (`AB-XXXX`) to his confession children
  static String buildConfessionChildrenShareText({
    required String priestFullName,
    required String church,
    required String privateCode,
  }) {
    final churchLine = church.trim().isNotEmpty ? ' ($church)' : '';
    return 'سلام ونعمة،\n'
        'لمتابعة مواعيد الاعتراف وتسجيل الحضور مع $priestFullName$churchLine على تطبيق أرثوذكسيا:\n'
        '١) افتح التطبيق واضغط «مواعيد أبونا»\n'
        '٢) اختر «ربط بكود أب اعترافي» وأدخل الكود الخاص:\n'
        '🔑 الكود: $privateCode\n\n'
        'رابط التطبيق: https://github.com/philo626/orthoxia';
  }

  /// Share text for a peer-priest vouch invite code (`KN-XXXX`) — works for 1 priest OR a church group (up to 15)
  static String buildPeerPriestVouchShareText({
    required String issuerName,
    required String inviteCode,
    int maxUses = 1,
  }) {
    final scopeLine = maxUses > 1
        ? 'الكود ده صالح لتوثيق لغاية $maxUses آباء كهنة (لمدة ٧ أيام) — كل أب كاهن في الكنيسة أو الإيبارشية يقدر يدخله ويتوثق علطول:'
        : 'بعد تسجيل الدخول كأب كاهن، قدسك تدخّل كود التزكية الخاص ده (صالح لاستخدام واحد لمدة ٧ أيام) عشان حساب قدسك يتوثّق علطول ويظهر في الدليل:';
    return 'سلام ونعمة يا آبائنا الأحباء،\n'
        'بدعو قدسكم للانضمام لبوابة الآباء الكهنة في تطبيق أرثوذكسيا (بتزكية من $issuerName).\n'
        'التطبيق فيه الخولاجي الكامل بصلوات الكاهن السرية، الـ ٣٩ قسمة، القطمارس والسنكسار، دفتر الافتقاد وأسماء المذبح، وتنظيم مواعيد الاعتراف بخصوصية تامة.\n\n'
        '$scopeLine\n'
        '✝️ كود التزكية: $inviteCode\n\n'
        'رابط تحميل التطبيق: https://github.com/philo626/orthoxia';
  }

  /// Share text so ANY priest (even before verification) can invite multiple brother priests to try the app!
  static String buildPriestAppRecommendationText({
    required String senderPriestName,
    String church = '',
  }) {
    final churchSuffix = church.trim().isNotEmpty ? ' ($church)' : '';
    return 'سلام ونعمة يا آبائي الأحباء،\n'
        'حبيت أشارك معاكم تطبيق «أرثوذكسيا» — معمول فيه بوابة كاملة مخصوص لخدمتنا كآباء كهنة (الخولاجي الكامل بالصلوات السرية، رفع البخور، الـ ٣٩ قسمة، القطمارس، دفتر أسماء المذبح والافتقاد، وتنظيم مواعيد الاعتراف لأولادنا بكود خاص).\n'
        'أخوكم: $senderPriestName$churchSuffix\n\n'
        'رابط التطبيق: https://github.com/philo626/orthoxia';
  }

  final FirebaseService _firebase = FirebaseService();
  final StorageService _storage = StorageService();
  final Random _rng = Random.secure();
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _notifSub;
  final Set<String> _alertedNotifIds = {};
  bool _initialNotifBatchLoaded = false;

  FirebaseFirestore? get _db =>
      _firebase.isFirebaseReady ? FirebaseFirestore.instance : null;

  String? get currentUid => _firebase.currentUser?.uid;

  /// Generates a clean readable code without ambiguous characters (0/O/1/I)
  String _generateCode(String prefix, {int length = 4}) {
    const digits = '23456789ABCDEFGHJKLMNPQRSTUVWXYZ';
    final buf = StringBuffer('$prefix-');
    for (int i = 0; i < length; i++) {
      buf.write(digits[_rng.nextInt(digits.length)]);
    }
    return buf.toString();
  }

  /// Normalizes user-entered codes: handles spaces, lowercase, missing dash, Arabic digits
  static String normalizeCode(String raw, {required String defaultPrefix}) {
    var s = raw.trim().toUpperCase();
    // Convert Arabic-Indic digits ٠١٢٣٤٥٦٧٨٩ to Western digits
    const ar = '٠١٢٣٤٥٦٧٨٩';
    for (int i = 0; i < ar.length; i++) {
      s = s.replaceAll(ar[i], '$i');
    }
    s = s.replaceAll(RegExp(r'[\s_–—]+'), '-');
    if (s.isEmpty) return '';
    if (!s.contains('-')) {
      if (s.startsWith(defaultPrefix) && s.length > defaultPrefix.length) {
        s = '$defaultPrefix-${s.substring(defaultPrefix.length)}';
      } else if (s.length == 4) {
        s = '$defaultPrefix-$s';
      }
    }
    return s;
  }

  /// Ensures a priest always has a local private code even before going online
  Future<String> ensureLocalPrivateCode() async {
    final existing = _storage.getLocalPriestCode();
    if (existing.isNotEmpty) return existing;
    final fresh = _generateCode('AB');
    await _storage.setLocalPriestCode(fresh);
    return fresh;
  }

  // ===========================================================================
  // 1. PRIEST PROFILE, PRIVATE CODE & VERIFICATION
  // ===========================================================================

  Future<(bool, String)> submitOrUpdatePriestVerification({
    required String titlePrefix,
    required String displayName,
    required String diocese,
    required String church,
    String verificationNote = '',
    String phoneForVerification = '',
  }) async {
    final safePrefix = titlePrefix == 'القمص' ? 'القمص' : 'القس';
    final safeName = SecurityGuardService.sanitizeText(displayName, maxLength: 80, allowNewlines: false);
    final safeDiocese = SecurityGuardService.sanitizeText(diocese, maxLength: 80, allowNewlines: false);
    final safeChurch = SecurityGuardService.sanitizeText(church, maxLength: 120, allowNewlines: false);
    final safeNote = SecurityGuardService.sanitizeText(verificationNote, maxLength: 300);
    final safePhone = SecurityGuardService.sanitizeText(phoneForVerification, maxLength: 30, allowNewlines: false);

    if (safeName.length < 2 || safeDiocese.length < 2 || safeChurch.length < 2) {
      return (false, 'من فضلك أكمل اسم قدسك والإيبارشية والكنيسة بشكل واضح.');
    }

    // Always persist locally so Abona's sanctuary header & tools personalize immediately
    await _storage.setUserRole('priest');
    await _storage.setPriestTitlePrefix(safePrefix);
    await _storage.setUserName(safeName);
    await _storage.setPriestChurch(safeChurch);
    await _storage.setPriestDiocese(safeDiocese);
    final localCode = await ensureLocalPrivateCode();

    final db = _db;
    final uid = currentUid;
    if (db == null || uid == null) {
      return (true, 'تم حفظ بيانات قدسك محلياً. يُرجى تسجيل الدخول لتفعيل كود الاعتراف والمواعيد السحابية.');
    }

    try {
      final ref = db.collection('priests').doc(uid);
      final existing = await ref.get();
      final existingData = existing.data();
      final currentStatus = existingData?['verificationStatus']?.toString();
      final nextStatus = currentStatus == 'approved' ? 'approved' : 'pending';

      // Reuse existing cloud privateCode if set; otherwise allocate a fresh unique AB-XXXX code
      var privateCode = '${existingData?['privateCode'] ?? ''}'.trim().toUpperCase();
      if (privateCode.isEmpty) {
        privateCode = localCode;
        for (int attempt = 0; attempt < 5; attempt++) {
          final codeDoc = await db.collection('priest_codes').doc(privateCode).get();
          if (!codeDoc.exists || codeDoc.data()?['priestUid'] == uid) {
            break;
          }
          privateCode = _generateCode('AB');
        }
      }
      await _storage.setLocalPriestCode(privateCode);

      final fullDisplay = (safeName.startsWith('أبونا') ||
              safeName.startsWith('القس') ||
              safeName.startsWith('القمص'))
          ? safeName
          : '$safePrefix $safeName';

      await ref.set({
        'priestUid': uid,
        'titlePrefix': safePrefix,
        'displayName': safeName,
        'diocese': safeDiocese,
        'church': safeChurch,
        'privateCode': privateCode,
        'verificationStatus': nextStatus,
        'verificationNote': safeNote,
        'phoneForVerification': safePhone,
        'adminFeedback': currentStatus == 'needs_info' ? '' : (existingData?['adminFeedback'] ?? ''),
        if (!existing.exists) 'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Publish private lookup card under priest_codes/{code} so children with the code can link immediately!
      try {
        await db.collection('priest_codes').doc(privateCode).set({
          'code': privateCode,
          'priestUid': uid,
          'titlePrefix': safePrefix,
          'displayName': safeName,
          'fullDisplayName': fullDisplay,
          'church': safeChurch,
          'diocese': safeDiocese,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } catch (e) {
        if (kDebugMode) debugPrint('priest_codes sync warning: $e');
      }

      // Sync non-sensitive role marker to user profile
      try {
        await db.collection('users').doc(uid).set({
          'displayName': fullDisplay,
          'patronSaintId': _storage.getPatronSaintId(),
          'role': 'priest',
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } catch (_) {}

      return (
        true,
        nextStatus == 'approved'
            ? 'تم حفظ وتحديث بيانات قدسك بنجاح.'
            : 'تم حفظ بيانات قدسك وتجهيز كود أولاد الاعتراف ($privateCode) فوراً! يمكنك نشر المواعيد لأولادك الآن، وللظهور في الدليل العام أدخل كود تزكية من كاهن موثّق أو انتظر المراجعة.'
      );
    } catch (e) {
      if (kDebugMode) debugPrint('submitOrUpdatePriestVerification err: $e');
      return (false, 'تعذر الحفظ على الخادم حالياً. تأكد من الاتصال بالإنترنت وتحديث قواعد Firebase.');
    }
  }

  /// Looks up ANY priest (private or verified) by his Private Code (e.g. AB-4829)
  Future<(PriestProfile?, String)> findPriestByPrivateCode(String rawCode) async {
    final normalized = normalizeCode(rawCode, defaultPrefix: 'AB');
    if (normalized.length < 6) {
      return (null, 'من فضلك أدخل الكود بشكل صحيح (مثال: AB-4829).');
    }
    final db = _db;
    if (db == null) {
      return (null, 'تعذر البحث بالكود بدون اتصال بالإنترنت.');
    }
    try {
      final doc = await db.collection('priest_codes').doc(normalized).get();
      if (!doc.exists || doc.data() == null) {
        return (null, 'لم نجد أب كاهن بهذا الكود ($normalized). تأكد من الكود الذي أرسله قدس أبونا.');
      }
      final data = doc.data()!;
      final priestUid = '${data['priestUid'] ?? ''}';
      if (priestUid.isEmpty) {
        return (null, 'الكود غير مكتمل، يُرجى مراجعة قدس أبونا.');
      }
      final profile = PriestProfile(
        priestUid: priestUid,
        titlePrefix: '${data['titlePrefix'] ?? 'القس'}',
        displayName: '${data['displayName'] ?? data['fullDisplayName'] ?? ''}',
        diocese: '${data['diocese'] ?? ''}',
        church: '${data['church'] ?? ''}',
        verificationStatus: PriestVerificationStatus.pending,
        privateCode: normalized,
      );
      return (profile, 'تم العثور على ${profile.fullDisplayName} بنجاح.');
    } catch (e) {
      if (kDebugMode) debugPrint('findPriestByPrivateCode err: $e');
      return (null, 'تعذر التحقق من الكود حالياً. تأكد من الاتصال بالإنترنت.');
    }
  }

  // ===========================================================================
  // 1b. PEER-PRIEST SINGLE-USE VOUCH CODES (`KN-XXXX`)
  // ===========================================================================

  /// Verified Priest (or Admin) generates a fresh 7-day code for 1 priest OR a church/diocese group (up to 15 priests!)
  Future<(PriestVouchInvite?, String)> generatePeerPriestInviteCode(
    PriestProfile issuer, {
    int maxUses = 1,
  }) async {
    final db = _db;
    final uid = currentUid;
    if (db == null || uid == null) {
      return (null, 'من فضلك سجّل دخول واتأكد إن النت شغال الأول.');
    }
    final isAdmin = await isCurrentUserAdmin();
    if (!issuer.isVerifiedPublic && !isAdmin) {
      return (null, 'إصدار أكواد التزكية متاح للآباء الكهنة الموثّقين بس.');
    }

    final clampedMax = maxUses.clamp(1, 15);

    try {
      String code = _generateCode('KN');
      for (int i = 0; i < 6; i++) {
        final existing = await db.collection('priest_invites').doc(code).get();
        if (!existing.exists) break;
        code = _generateCode('KN');
      }

      final now = DateTime.now();
      final expiresAt = now.add(const Duration(days: 7));
      await db.collection('priest_invites').doc(code).set({
        'code': code,
        'issuerUid': uid,
        'issuerName': issuer.fullDisplayName,
        'issuerChurch': issuer.church,
        'used': false,
        'maxUses': clampedMax,
        'usedCount': 0,
        'usedByUids': <String>[],
        'usedByNames': <String>[],
        'usedByUid': '',
        'usedByName': '',
        'createdAt': FieldValue.serverTimestamp(),
        'expiresAt': Timestamp.fromDate(expiresAt),
      });

      final invite = PriestVouchInvite(
        code: code,
        issuerUid: uid,
        issuerName: issuer.fullDisplayName,
        issuerChurch: issuer.church,
        used: false,
        maxUses: clampedMax,
        usedCount: 0,
        createdAt: now,
        expiresAt: expiresAt,
      );
      return (
        invite,
        clampedMax > 1
            ? 'اتجهّز كود تزكية جماعي ($code) شغال لـ $clampedMax آباء كهنة لمدة ٧ أيام!'
            : 'اتجهّز كود تزكية جديد ($code) شغال لأب كاهن واحد لمدة ٧ أيام.',
      );
    } catch (e) {
      if (kDebugMode) debugPrint('generatePeerPriestInviteCode err: $e');
      return (null, 'مش قادرين نطلّع كود التزكية دلوقتي. اتأكد من النت وحاول تاني.');
    }
  }

  Stream<List<PriestVouchInvite>> watchMyIssuedInvites() {
    final db = _db;
    final uid = currentUid;
    if (db == null || uid == null) return Stream.value(const []);
    return db
        .collection('priest_invites')
        .where('issuerUid', isEqualTo: uid)
        .snapshots()
        .map((snap) {
      final list = snap.docs
          .map((d) => PriestVouchInvite.fromMap(d.id, d.data()))
          .toList();
      list.sort((a, b) => (b.createdAt ?? DateTime(2000)).compareTo(a.createdAt ?? DateTime(2000)));
      return list;
    });
  }

  /// Fellow Priest redeems a single-use `KN-XXXX` code -> instant Public Directory ✓ verification & burns the code!
  Future<(bool, String)> redeemPeerPriestInviteCode(String rawCode) async {
    final db = _db;
    final uid = currentUid;
    if (db == null || uid == null) {
      return (false, 'يُرجى تسجيل الدخول أولاً.');
    }
    final normalized = normalizeCode(rawCode, defaultPrefix: 'KN');
    if (normalized.length < 6) {
      return (false, 'من فضلك أدخل كود التزكية بشكل صحيح (مثال: KN-7391).');
    }

    final inviteRef = db.collection('priest_invites').doc(normalized);
    final priestRef = db.collection('priests').doc(uid);

    try {
      final msg = await db.runTransaction<String>((tx) async {
        final inviteSnap = await tx.get(inviteRef);
        if (!inviteSnap.exists || inviteSnap.data() == null) {
          throw Exception('NOT_FOUND');
        }
        final inv = PriestVouchInvite.fromMap(inviteSnap.id, inviteSnap.data()!);
        if (inv.isFullyUsed) {
          throw Exception('ALREADY_USED');
        }
        if (inv.isExpired) {
          throw Exception('EXPIRED');
        }
        if (inv.issuerUid == uid) {
          throw Exception('SELF_VOUCH');
        }
        if (inv.usedByUids.contains(uid)) {
          throw Exception('ALREADY_REDEEMED_BY_ME');
        }

        final priestSnap = await tx.get(priestRef);
        if (!priestSnap.exists || priestSnap.data() == null) {
          throw Exception('NO_PROFILE');
        }
        final pData = priestSnap.data()!;
        final pProfile = PriestProfile.fromMap(uid, pData);

        final nextCount = inv.usedCount + 1;
        final isNowExhausted = nextCount >= inv.maxUses;
        final nextUids = [...inv.usedByUids, uid];
        final nextNames = [...inv.usedByNames, pProfile.fullDisplayName];

        // Atomically record redemption (single-use OR multi-use church group) AND approve the priest!
        final inviteRaw = inviteSnap.data()!;
        if (inviteRaw.containsKey('maxUses')) {
          tx.update(inviteRef, {
            'usedCount': nextCount,
            'used': isNowExhausted,
            'usedByUids': nextUids,
            'usedByNames': nextNames,
            'usedByUid': uid,
            'usedByName': pProfile.fullDisplayName,
            'usedAt': FieldValue.serverTimestamp(),
          });
        } else {
          tx.update(inviteRef, {
            'used': true,
            'usedByUid': uid,
            'usedByName': pProfile.fullDisplayName,
            'usedAt': FieldValue.serverTimestamp(),
          });
        }
        tx.update(priestRef, {
          'verificationStatus': 'approved',
          'vouchInviteCode': normalized,
          'vouchedByUid': inv.issuerUid,
          'vouchedByName': inv.issuerName,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        return 'ألف مبروك يا قدس أبونا! اتوثّق حساب قدسك علطول بتزكية ${inv.issuerName} ✓ وبقى ظاهر في الدليل العام.';
      });
      return (true, msg);
    } catch (e) {
      final s = e.toString();
      if (s.contains('NOT_FOUND')) {
        return (false, 'كود التزكية ($normalized) مش موجود. اتأكد من الكود اللي اتبعت لقدسك.');
      }
      if (s.contains('ALREADY_REDEEMED_BY_ME')) {
        return (false, 'قدسك استخدمت الكود ده قبل كده وحسابك متوثّق بالفعل.');
      }
      if (s.contains('ALREADY_USED')) {
        return (false, 'الكود ده خلصت عدد مرات استخدامه — اطلب كود جديد من الأب الكاهن.');
      }
      if (s.contains('EXPIRED')) {
        return (false, 'انتهت صلاحية كود التزكية (٧ أيام). يُرجى طلب كود جديد.');
      }
      if (s.contains('SELF_VOUCH')) {
        return (false, 'لا يمكن استخدام كود تزكية صادر من نفس الحساب.');
      }
      if (s.contains('NO_PROFILE')) {
        return (false, 'يرجى حفظ بيانات قدسك (الاسم والإيبارشية والكنيسة) أولاً ثم إدخال كود التزكية.');
      }
      if (kDebugMode) debugPrint('redeemPeerPriestInviteCode err: $e');
      return (false, 'تعذر تفعيل كود التزكية حالياً. تأكد من الاتصال بالإنترنت.');
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
  // 3. PRIEST CONFESSION SESSIONS (WORKS IMMEDIATELY VIA PRIVATE CODE & PUBLIC)
  // ===========================================================================

  Future<(bool, String)> publishConfessionSession({
    required PriestProfile priest,
    required DateTime date,
    required String dayLabelAr,
    required String startTimeAr,
    String endTimeAr = '',
    int? maxAttendees,
    String locationNote = '',
  }) async {
    final db = _db;
    final uid = currentUid;
    if (db == null || uid == null) {
      return (false, 'من فضلك سجّل دخول واتأكد من النت الأول.');
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
        'endTimeAr': SecurityGuardService.sanitizeText(endTimeAr, maxLength: 40, allowNewlines: false),
        'locationNote': SecurityGuardService.sanitizeText(locationNote, maxLength: 120, allowNewlines: false),
        'maxAttendees': (maxAttendees != null && maxAttendees > 0) ? maxAttendees : null,
        'isOpen': true,
        'confirmedCount': 0,
        'waitlistCount': 0,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return (
        true,
        priest.isVerifiedPublic
            ? 'اتنشر الميعاد بنجاح لأولاد قدسك.'
            : 'اتنشر الميعاد بنجاح لأولاد قدسك المرتبطين بكود (${priest.privateCode}).'
      );
    } catch (e) {
      if (kDebugMode) debugPrint('publishConfessionSession err: $e');
      return (false, 'مش قادرين ننشر الميعاد دلوقتي. اتأكد من النت وحاول تاني.');
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
    String? attendeeNameOverride,
  }) async {
    final db = _db;
    final uid = currentUid;
    if (db == null || uid == null) {
      return const AttendanceActionResult(
        status: AttendanceActionStatus.notSignedIn,
        message: 'من فضلك سجّل دخول الأول عشان نأكد حضورك ونبلّغ قدس أبونا.',
      );
    }

    final rawName = (attendeeNameOverride != null && attendeeNameOverride.trim().isNotEmpty)
        ? attendeeNameOverride.trim()
        : _storage.getUserName();
    final attendeeName = SecurityGuardService.sanitizeText(
      rawName,
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

        if (!liveSession.isOpen) {
          return const AttendanceActionResult(
            status: AttendanceActionStatus.sessionClosed,
            message: 'أبونا قفل التسجيل لهذا اليوم. يمكنك اختيار يوم آخر.',
          );
        }

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

  // ===========================================================================
  // 6. ALTAR PRAYER REQUESTS (CONGREGATION -> PRIEST'S PRIVATE ALTAR LIST)
  // ===========================================================================

  /// Congregation member sends a prayer name (sick / departed / traveler / distress / thanksgiving)
  /// directly to their confession father's private inbox (readable ONLY by Abouna).
  Future<(bool, String)> submitAltarPrayerRequest({
    required String priestUid,
    required String personName,
    required String category,
    String note = '',
  }) async {
    final db = _db;
    final uid = currentUid;
    if (db == null || uid == null) {
      return (false, 'من فضلك سجّل دخول الأول عشان نبعت الاسم لقدس أبونا.');
    }
    final safePerson = SecurityGuardService.sanitizeText(personName, maxLength: 80, allowNewlines: false);
    final safeNote = SecurityGuardService.sanitizeText(note, maxLength: 200);
    final senderName = SecurityGuardService.sanitizeText(
      _storage.hasCustomUserName() ? _storage.getUserName() : 'أحد أبناء الكنيسة',
      maxLength: 60,
      allowNewlines: false,
    );
    if (safePerson.length < 2) {
      return (false, 'اكتب الاسم اللي عايز قدس أبونا يذكره على المذبح.');
    }
    const allowedCats = {'sick', 'departed', 'travelers', 'distressed', 'thanksgiving'};
    final safeCat = allowedCats.contains(category) ? category : 'sick';

    try {
      await db
          .collection('priest_altar_requests')
          .doc(priestUid)
          .collection('items')
          .add({
        'senderUid': uid,
        'senderName': senderName.isEmpty ? 'ابن الكنيسة' : senderName,
        'personName': safePerson,
        'category': safeCat,
        'note': safeNote,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });
      return (true, 'اتبعَت الاسم لقدس أبونا بنجاح، وبضغطة واحدة هيضيفه قدسه على المذبح 🙏');
    } catch (e) {
      if (kDebugMode) debugPrint('submitAltarPrayerRequest err: $e');
      return (false, 'مش قادرين نبعت الطلبة دلوقتي. اتأكد من النت وحاول تاني.');
    }
  }

  /// Priest watches incoming pending altar requests from his children (private to Abouna only!)
  Stream<List<AltarPrayerRequest>> watchIncomingAltarRequests() {
    final db = _db;
    final uid = currentUid;
    if (db == null || uid == null) return Stream.value(const []);
    return db
        .collection('priest_altar_requests')
        .doc(uid)
        .collection('items')
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => AltarPrayerRequest.fromMap(d.id, d.data()))
            .where((r) => r.status == 'pending')
            .toList());
  }

  Future<void> dismissOrAcceptAltarRequest(String requestId, {bool delete = true}) async {
    final db = _db;
    final uid = currentUid;
    if (db == null || uid == null) return;
    try {
      final ref = db
          .collection('priest_altar_requests')
          .doc(uid)
          .collection('items')
          .doc(requestId);
      if (delete) {
        await ref.delete();
      } else {
        await ref.update({'status': 'added'});
      }
    } catch (_) {}
  }

  // ===========================================================================
  // 7. PRIEST CONFESSORS TABLE, CHECKMARK ✓ & NEXT-RETURN INTERVAL
  // ===========================================================================

  static String _isoFromDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  /// Priest checks off an attendee as Confessed ✓ and chooses when they should return (e.g. 14/21/30/40/60 days)
  Future<(bool, String)> markAttendeeConfessed({
    required ConfessionSession session,
    required ConfessionAttendee attendee,
    required int nextIntervalDays,
    String followUpNote = '',
  }) async {
    final db = _db;
    final uid = currentUid;
    if (db == null || uid == null) {
      return (false, 'من فضلك اتأكد من الاتصال بالإنترنت الأول.');
    }

    final today = DateTime.now();
    final todayIso = _isoFromDate(today);
    final nextDateIso = nextIntervalDays > 0
        ? _isoFromDate(today.add(Duration(days: nextIntervalDays)))
        : '';
    final safeNote = SecurityGuardService.sanitizeText(followUpNote, maxLength: 180);
    final safeName = SecurityGuardService.sanitizeText(attendee.attendeeName, maxLength: 80, allowNewlines: false);

    try {
      // 1. Update attendee row inside the session
      await db
          .collection('confession_sessions')
          .doc(session.id)
          .collection('attendees')
          .doc(attendee.attendeeUid)
          .update({
        'confessed': true,
        'nextIntervalDays': nextIntervalDays,
        'nextDateIso': nextDateIso,
        'followUpNote': safeNote,
        'confessedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // 2. Upsert into Abouna's Confessors Table (`priests/{uid}/confession_children/{attendeeUid}`)
      final childRef = db
          .collection('priests')
          .doc(uid)
          .collection('confession_children')
          .doc(attendee.attendeeUid);
      final existing = await childRef.get();
      final prevCount = (existing.data()?['confessedCount'] as num?)?.toInt() ?? 0;

      await childRef.set({
        'attendeeUid': attendee.attendeeUid,
        'fullName': safeName.isEmpty ? 'ابن الكنيسة' : safeName,
        'lastConfessionDateIso': todayIso,
        'nextIntervalDays': nextIntervalDays,
        'nextConfessionDateIso': nextDateIso,
        'followUpNote': safeNote,
        'confessedCount': prevCount + 1,
        'confessedInLastSession': true,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      final intervalText = nextIntervalDays > 0
          ? ' وهيظهرله إنه يرجع بعد ${PriestConfessorRecord.formatIntervalLabel(nextIntervalDays)}'
          : '';
      return (true, 'اتعلم صح ✓ لـ $safeName$intervalText');
    } catch (e) {
      if (kDebugMode) debugPrint('markAttendeeConfessed err: $e');
      return (false, 'مش قادرين نحفظ علامة الصح دلوقتي. اتأكد من النت وحاول تاني.');
    }
  }

  Future<void> unmarkAttendeeConfessed(String sessionId, String attendeeUid) async {
    final db = _db;
    if (db == null) return;
    try {
      await db
          .collection('confession_sessions')
          .doc(sessionId)
          .collection('attendees')
          .doc(attendeeUid)
          .update({
        'confessed': false,
        'nextIntervalDays': 0,
        'nextDateIso': '',
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {}
  }

  /// Adds a walk-in confessor OR logs a brand-new confession directly inside Abouna's Confessors Table
  Future<(bool, String)> upsertConfessorRecord({
    required String fullName,
    required int nextIntervalDays,
    String followUpNote = '',
    String? existingId,
    String attendeeUid = '',
    int prevCount = 0,
  }) async {
    final db = _db;
    final uid = currentUid;
    if (db == null || uid == null) {
      return (false, 'من فضلك اتأكد من الاتصال بالإنترنت الأول.');
    }
    final safeName = SecurityGuardService.sanitizeText(fullName, maxLength: 80, allowNewlines: false);
    if (safeName.length < 2) {
      return (false, 'من فضلك اكتب اسم المعترف بشكل واضح.');
    }
    final safeNote = SecurityGuardService.sanitizeText(followUpNote, maxLength: 180);
    final today = DateTime.now();
    final todayIso = _isoFromDate(today);
    final nextDateIso = nextIntervalDays > 0
        ? _isoFromDate(today.add(Duration(days: nextIntervalDays)))
        : '';

    try {
      final col = db.collection('priests').doc(uid).collection('confession_children');
      final docRef = (existingId != null && existingId.isNotEmpty) ? col.doc(existingId) : col.doc();
      await docRef.set({
        'attendeeUid': attendeeUid,
        'fullName': safeName,
        'lastConfessionDateIso': todayIso,
        'nextIntervalDays': nextIntervalDays,
        'nextConfessionDateIso': nextDateIso,
        'followUpNote': safeNote,
        'confessedCount': prevCount + 1,
        'confessedInLastSession': true,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      return (true, 'اتسجّل في جدول معترفين قدسك ✓ ($safeName)');
    } catch (e) {
      if (kDebugMode) debugPrint('upsertConfessorRecord err: $e');
      return (false, 'تعذر الحفظ حالياً. اتأكد من الاتصال بالإنترنت.');
    }
  }

  Future<void> deleteConfessorRecord(String recordId) async {
    final db = _db;
    final uid = currentUid;
    if (db == null || uid == null) return;
    try {
      await db.collection('priests').doc(uid).collection('confession_children').doc(recordId).delete();
    } catch (_) {}
  }

  /// Live stream of Abouna's full Confessors Table («جدول معترفين قدس أبونا»)
  Stream<List<PriestConfessorRecord>> watchMyConfessorsTable() {
    final db = _db;
    final uid = currentUid;
    if (db == null || uid == null) return Stream.value(const []);
    return db
        .collection('priests')
        .doc(uid)
        .collection('confession_children')
        .snapshots()
        .map((snap) {
      final list = snap.docs
          .map((d) => PriestConfessorRecord.fromMap(d.id, d.data()))
          .toList();
      list.sort((a, b) {
        if (a.isDueNow != b.isDueNow) return a.isDueNow ? -1 : 1;
        return (b.updatedAt ?? DateTime(2000)).compareTo(a.updatedAt ?? DateTime(2000));
      });
      return list;
    });
  }

  /// Congregation member watches ONLY their OWN confession follow-up date & blessing set by Abouna!
  Stream<PriestConfessorRecord?> watchMyFollowUpFromFather(String fatherUid) {
    final db = _db;
    final uid = currentUid;
    if (db == null || uid == null || fatherUid.isEmpty) return Stream.value(null);
    return db
        .collection('priests')
        .doc(fatherUid)
        .collection('confession_children')
        .doc(uid)
        .snapshots()
        .map((snap) {
      if (!snap.exists || snap.data() == null) return null;
      return PriestConfessorRecord.fromMap(snap.id, snap.data()!);
    });
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
