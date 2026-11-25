import 'package:cloud_firestore/cloud_firestore.dart';
export 'coptic_churches_catalog.dart';

enum PriestVerificationStatus { pending, approved, needsInfo }

class PriestProfile {
  final String priestUid;
  final String titlePrefix; // 'القس' | 'القمص'
  final String displayName;
  final String diocese;
  final String church;
  final PriestVerificationStatus verificationStatus;
  final String privateCode; // e.g. 'AB-4829' — fixed private code for Abona's own confession children
  final String vouchedByUid;
  final String vouchedByName;
  final String verificationNote;
  final String adminFeedback;
  final String phoneForVerification;
  final DateTime? updatedAt;

  const PriestProfile({
    required this.priestUid,
    required this.titlePrefix,
    required this.displayName,
    required this.diocese,
    required this.church,
    required this.verificationStatus,
    this.privateCode = '',
    this.vouchedByUid = '',
    this.vouchedByName = '',
    this.verificationNote = '',
    this.adminFeedback = '',
    this.phoneForVerification = '',
    this.updatedAt,
  });

  String get fullDisplayName {
    final name = displayName.trim();
    if (name.startsWith('أبونا') || name.startsWith('القس') || name.startsWith('القمص')) {
      return name;
    }
    return '${titlePrefix.isNotEmpty ? titlePrefix : 'القس'} $name';
  }

  bool get isVerifiedPublic => verificationStatus == PriestVerificationStatus.approved;

  static PriestVerificationStatus parseStatus(String? raw) {
    switch (raw) {
      case 'approved':
        return PriestVerificationStatus.approved;
      case 'needs_info':
        return PriestVerificationStatus.needsInfo;
      default:
        return PriestVerificationStatus.pending;
    }
  }

  static String statusToString(PriestVerificationStatus status) {
    switch (status) {
      case PriestVerificationStatus.approved:
        return 'approved';
      case PriestVerificationStatus.needsInfo:
        return 'needs_info';
      case PriestVerificationStatus.pending:
        return 'pending';
    }
  }

  factory PriestProfile.fromMap(String uid, Map<String, dynamic> data) {
    final ts = data['updatedAt'];
    return PriestProfile(
      priestUid: uid,
      titlePrefix: '${data['titlePrefix'] ?? 'القس'}',
      displayName: '${data['displayName'] ?? ''}',
      diocese: '${data['diocese'] ?? ''}',
      church: '${data['church'] ?? ''}',
      verificationStatus: parseStatus(data['verificationStatus']?.toString()),
      privateCode: '${data['privateCode'] ?? ''}',
      vouchedByUid: '${data['vouchedByUid'] ?? ''}',
      vouchedByName: '${data['vouchedByName'] ?? ''}',
      verificationNote: '${data['verificationNote'] ?? ''}',
      adminFeedback: '${data['adminFeedback'] ?? ''}',
      phoneForVerification: '${data['phoneForVerification'] ?? ''}',
      updatedAt: ts is Timestamp ? ts.toDate() : null,
    );
  }
}

/// Peer-priest vouch invite code (e.g. KN-7391) issued by an approved priest.
/// Supports BOTH single-priest (maxUses = 1) AND church/diocese group invites (maxUses = 3..15)!
class PriestVouchInvite {
  final String code;
  final String issuerUid;
  final String issuerName;
  final String issuerChurch;
  final bool used;
  final int maxUses;
  final int usedCount;
  final List<String> usedByUids;
  final List<String> usedByNames;
  final String usedByUid;
  final String usedByName;
  final DateTime? createdAt;
  final DateTime? expiresAt;

  const PriestVouchInvite({
    required this.code,
    required this.issuerUid,
    required this.issuerName,
    required this.issuerChurch,
    required this.used,
    this.maxUses = 1,
    this.usedCount = 0,
    this.usedByUids = const [],
    this.usedByNames = const [],
    this.usedByUid = '',
    this.usedByName = '',
    this.createdAt,
    this.expiresAt,
  });

  bool get isExpired => expiresAt != null && DateTime.now().isAfter(expiresAt!);
  int get remainingUses => (maxUses - usedCount).clamp(0, maxUses);
  bool get isFullyUsed => used || usedCount >= maxUses;

  factory PriestVouchInvite.fromMap(String code, Map<String, dynamic> data) {
    final cTs = data['createdAt'];
    final eTs = data['expiresAt'];
    final legacyUsed = data['used'] == true;
    final parsedMax = (data['maxUses'] as num?)?.toInt() ?? 1;
    final parsedCount = (data['usedCount'] as num?)?.toInt() ?? (legacyUsed ? 1 : 0);
    final rawUids = (data['usedByUids'] as List?)?.map((e) => '$e').where((e) => e.isNotEmpty).toList() ?? [];
    final rawNames = (data['usedByNames'] as List?)?.map((e) => '$e').where((e) => e.isNotEmpty).toList() ?? [];
    final singleUid = '${data['usedByUid'] ?? ''}';
    final singleName = '${data['usedByName'] ?? ''}';
    if (rawUids.isEmpty && singleUid.isNotEmpty) rawUids.add(singleUid);
    if (rawNames.isEmpty && singleName.isNotEmpty) rawNames.add(singleName);

    return PriestVouchInvite(
      code: code,
      issuerUid: '${data['issuerUid'] ?? ''}',
      issuerName: '${data['issuerName'] ?? ''}',
      issuerChurch: '${data['issuerChurch'] ?? ''}',
      used: legacyUsed || parsedCount >= parsedMax,
      maxUses: parsedMax < 1 ? 1 : parsedMax,
      usedCount: parsedCount,
      usedByUids: rawUids,
      usedByNames: rawNames,
      usedByUid: singleUid,
      usedByName: singleName,
      createdAt: cTs is Timestamp ? cTs.toDate() : null,
      expiresAt: eTs is Timestamp ? eTs.toDate() : null,
    );
  }
}

class ConfessionSession {
  final String id;
  final String priestUid;
  final String priestName;
  final String church;
  final String diocese;
  final String dateIso; // yyyy-MM-dd
  final String dayLabelAr; // e.g. 'الجمعة ٢٧ نوفمبر'
  final String startTimeAr; // e.g. '٤:٠٠ مساءً'
  final String endTimeAr; // optional e.g. '٦:٠٠ مساءً' ('' = مفتوح بدون ساعة انتهاء)
  final String locationNote; // optional e.g. 'مكتب الاعتراف بالكنيسة'
  final String audienceGroup; // '' / 'عام للكل' | 'الشباب' | 'الأسر والمتزوجين' | 'كبار السن والمرضى' | 'إعدادي وثانوي'
  final int? maxAttendees; // null = عدد مفتوح
  final bool isOpen; // false = أبونا قفل التسجيل
  final bool isCancelled; // true = اعتذار / تأجيل طارئ من قدس أبونا
  final String cancelNotice; // رسالة الاعتذار الطارئ من أبونا
  final int currentServingNumber; // نظام الدور المباشر (اللي خلّصوا أو بيتخدموا دلوقتي)
  final int confirmedCount;
  final int waitlistCount;
  final DateTime? createdAt;

  const ConfessionSession({
    required this.id,
    required this.priestUid,
    required this.priestName,
    required this.church,
    required this.diocese,
    required this.dateIso,
    required this.dayLabelAr,
    required this.startTimeAr,
    this.endTimeAr = '',
    this.locationNote = '',
    this.audienceGroup = '',
    this.maxAttendees,
    required this.isOpen,
    this.isCancelled = false,
    this.cancelNotice = '',
    this.currentServingNumber = 0,
    required this.confirmedCount,
    required this.waitlistCount,
    this.createdAt,
  });

  bool get isUnlimited => maxAttendees == null || maxAttendees! <= 0;
  bool get isFull => !isUnlimited && confirmedCount >= maxAttendees!;
  bool get hasEndTime => endTimeAr.trim().isNotEmpty;

  /// Human-friendly Egyptian Arabic time window (e.g. «من ٤:٠٠ مساءً لغاية ٦:٠٠ مساءً»)
  String get timeRangeLabelAr => hasEndTime
      ? 'من $startTimeAr لغاية ${endTimeAr.trim()}'
      : 'ابتداءً من $startTimeAr';

  factory ConfessionSession.fromMap(String id, Map<String, dynamic> data) {
    final ts = data['createdAt'];
    final rawMax = data['maxAttendees'];
    return ConfessionSession(
      id: id,
      priestUid: '${data['priestUid'] ?? ''}',
      priestName: '${data['priestName'] ?? ''}',
      church: '${data['church'] ?? ''}',
      diocese: '${data['diocese'] ?? ''}',
      dateIso: '${data['dateIso'] ?? ''}',
      dayLabelAr: '${data['dayLabelAr'] ?? ''}',
      startTimeAr: '${data['startTimeAr'] ?? ''}',
      endTimeAr: '${data['endTimeAr'] ?? ''}',
      locationNote: '${data['locationNote'] ?? ''}',
      audienceGroup: '${data['audienceGroup'] ?? ''}',
      maxAttendees: rawMax is num && rawMax.toInt() > 0 ? rawMax.toInt() : null,
      isOpen: data['isOpen'] != false,
      isCancelled: data['isCancelled'] == true,
      cancelNotice: '${data['cancelNotice'] ?? ''}',
      currentServingNumber: (data['currentServingNumber'] as num?)?.toInt() ?? 0,
      confirmedCount: (data['confirmedCount'] as num?)?.toInt() ?? 0,
      waitlistCount: (data['waitlistCount'] as num?)?.toInt() ?? 0,
      createdAt: ts is Timestamp ? ts.toDate() : null,
    );
  }
}

class ConfessionAttendee {
  final String attendeeUid;
  final String sessionId;
  final String attendeeName;
  final List<String> companionNames; // أفراد الأسرة أو الأطفال المسجّلين مع نفس الموبايل
  final int queueNumber; // رقم الدور في اليوم (١، ٢، ٣...)
  final String status; // 'confirmed' | 'waitlist' | 'cancelled'
  final String dayLabelAr;
  final String startTimeAr;
  final bool confessed; // علامة صح ✓ حددها قدس أبونا بعد ما اعترف
  final int nextIntervalDays; // المدة اللي قدس أبونا حددها للرجوع للاعتراف (مثلاً 14 / 21 / 30 / 40 / 60 يوم)
  final String nextDateIso; // yyyy-MM-dd
  final String followUpNote; // كلمة تشجيع أو إرشاد اختياري من قدس أبونا
  final DateTime? confessedAt;
  final DateTime? updatedAt;

  const ConfessionAttendee({
    required this.attendeeUid,
    required this.sessionId,
    required this.attendeeName,
    this.companionNames = const [],
    this.queueNumber = 0,
    required this.status,
    required this.dayLabelAr,
    required this.startTimeAr,
    this.confessed = false,
    this.nextIntervalDays = 0,
    this.nextDateIso = '',
    this.followUpNote = '',
    this.confessedAt,
    this.updatedAt,
  });

  String get displayNameWithFamily =>
      companionNames.isEmpty || attendeeName.contains('(+')
          ? attendeeName
          : '$attendeeName (+ ${companionNames.join('، ')})';

  factory ConfessionAttendee.fromMap(String uid, Map<String, dynamic> data) {
    final ts = data['updatedAt'];
    final cTs = data['confessedAt'];
    final rawComp = (data['companionNames'] as List?)
            ?.map((e) => '$e'.trim())
            .where((e) => e.isNotEmpty)
            .toList() ??
        const <String>[];
    return ConfessionAttendee(
      attendeeUid: uid,
      sessionId: '${data['sessionId'] ?? ''}',
      attendeeName: '${data['attendeeName'] ?? ''}',
      companionNames: rawComp,
      queueNumber: (data['queueNumber'] as num?)?.toInt() ?? 0,
      status: '${data['status'] ?? 'confirmed'}',
      dayLabelAr: '${data['dayLabelAr'] ?? ''}',
      startTimeAr: '${data['startTimeAr'] ?? ''}',
      confessed: data['confessed'] == true,
      nextIntervalDays: (data['nextIntervalDays'] as num?)?.toInt() ?? 0,
      nextDateIso: '${data['nextDateIso'] ?? ''}',
      followUpNote: '${data['followUpNote'] ?? ''}',
      confessedAt: cTs is Timestamp ? cTs.toDate() : null,
      updatedAt: ts is Timestamp ? ts.toDate() : null,
    );
  }
}

/// Entry inside Abouna's Confessors Directory Table («جدول معترفين قدس أبونا»)
/// Stored under `priests/{priestUid}/confession_children/{id}` (readable by Abouna + that child only).
class PriestConfessorRecord {
  final String id;
  final String attendeeUid;
  final String fullName;
  final String lastConfessionDateIso;
  final int nextIntervalDays;
  final String nextConfessionDateIso;
  final String followUpNote;
  final int confessedCount;
  final bool confessedInLastSession;
  final DateTime? updatedAt;

  const PriestConfessorRecord({
    required this.id,
    this.attendeeUid = '',
    required this.fullName,
    this.lastConfessionDateIso = '',
    this.nextIntervalDays = 0,
    this.nextConfessionDateIso = '',
    this.followUpNote = '',
    this.confessedCount = 1,
    this.confessedInLastSession = true,
    this.updatedAt,
  });

  /// Days remaining until the next return date Abouna specified (<= 0 means due now!)
  int? get daysUntilNext {
    if (nextConfessionDateIso.isEmpty) return null;
    final target = DateTime.tryParse(nextConfessionDateIso);
    if (target == null) return null;
    final now = DateTime.now();
    return DateTime(target.year, target.month, target.day)
        .difference(DateTime(now.year, now.month, now.day))
        .inDays;
  }

  bool get isDueNow {
    final d = daysUntilNext;
    return d != null && d <= 0;
  }

  static String formatIntervalLabel(int days) {
    if (days <= 0) return 'بدون مدة محددة';
    if (days == 7) return 'أسبوع (٧ أيام)';
    if (days == 14) return 'أسبوعين (١٤ يوم)';
    if (days == 21) return '٣ أسابيع (٢١ يوم)';
    if (days == 30) return 'شهر (٣٠ يوم)';
    if (days == 40) return '٤٠ يوم';
    if (days == 60) return 'شهرين (٦٠ يوم)';
    return '$days يوم';
  }

  static String formatArabicDateShort(String iso) {
    final dt = DateTime.tryParse(iso);
    if (dt == null) return iso;
    const months = [
      'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
      'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر',
    ];
    return '${dt.day} ${months[(dt.month - 1).clamp(0, 11)]}';
  }

  factory PriestConfessorRecord.fromMap(String id, Map<String, dynamic> d) {
    final ts = d['updatedAt'];
    return PriestConfessorRecord(
      id: id,
      attendeeUid: '${d['attendeeUid'] ?? ''}',
      fullName: '${d['fullName'] ?? ''}',
      lastConfessionDateIso: '${d['lastConfessionDateIso'] ?? ''}',
      nextIntervalDays: (d['nextIntervalDays'] as num?)?.toInt() ?? 0,
      nextConfessionDateIso: '${d['nextConfessionDateIso'] ?? ''}',
      followUpNote: '${d['followUpNote'] ?? ''}',
      confessedCount: (d['confessedCount'] as num?)?.toInt() ?? 1,
      confessedInLastSession: d['confessedInLastSession'] != false,
      updatedAt: ts is Timestamp ? ts.toDate() : null,
    );
  }
}

class PriestNotificationItem {
  final String id;
  final String type; // 'registered' | 'waitlist' | 'cancelled'
  final String attendeeUid;
  final String attendeeName;
  final String sessionId;
  final String dayLabelAr;
  final String startTimeAr;
  final bool read;
  final DateTime? createdAt;

  const PriestNotificationItem({
    required this.id,
    required this.type,
    required this.attendeeUid,
    required this.attendeeName,
    required this.sessionId,
    required this.dayLabelAr,
    required this.startTimeAr,
    required this.read,
    this.createdAt,
  });

  String get indoorDetailedMessage {
    if (type == 'cancelled') {
      return '$attendeeName اعتذر(ت) عن موعد الاعتراف يوم $dayLabelAr.';
    }
    if (type == 'waitlist') {
      return '$attendeeName انضمّ لقائمة الانتظار للاعتراف عند قدسك يوم $dayLabelAr.';
    }
    return '$attendeeName سجّل(ت) حضور للاعتراف عند قدسك يوم $dayLabelAr (ابتداءً من $startTimeAr).';
  }

  factory PriestNotificationItem.fromMap(String id, Map<String, dynamic> data) {
    final ts = data['createdAt'];
    return PriestNotificationItem(
      id: id,
      type: '${data['type'] ?? 'registered'}',
      attendeeUid: '${data['attendeeUid'] ?? ''}',
      attendeeName: '${data['attendeeName'] ?? ''}',
      sessionId: '${data['sessionId'] ?? ''}',
      dayLabelAr: '${data['dayLabelAr'] ?? ''}',
      startTimeAr: '${data['startTimeAr'] ?? ''}',
      read: data['read'] == true,
      createdAt: ts is Timestamp ? ts.toDate() : null,
    );
  }
}

enum AttendanceActionStatus {
  confirmed,
  alreadyConfirmed,
  waitlisted,
  alreadyWaitlisted,
  sessionClosed,
  sessionFull,
  cancelled,
  notSignedIn,
  offlineError,
}

class AttendanceActionResult {
  final AttendanceActionStatus status;
  final String message;

  const AttendanceActionResult({required this.status, required this.message});
}

// =============================================================================
// PRIEST PRIVATE ON-DEVICE PASTORAL CARE MODELS (100% AES-256 LOCAL ONLY)
// =============================================================================

/// Incoming Altar Prayer Request sent by a congregation member directly to their Priest
class AltarPrayerRequest {
  final String id;
  final String senderUid;
  final String senderName;
  final String personName;
  final String category; // 'sick' | 'departed' | 'travelers' | 'distressed' | 'thanksgiving'
  final String note;
  final String status; // 'pending' | 'added'
  final DateTime? createdAt;

  const AltarPrayerRequest({
    required this.id,
    required this.senderUid,
    required this.senderName,
    required this.personName,
    required this.category,
    this.note = '',
    this.status = 'pending',
    this.createdAt,
  });

  factory AltarPrayerRequest.fromMap(String id, Map<String, dynamic> data) {
    final ts = data['createdAt'];
    return AltarPrayerRequest(
      id: id,
      senderUid: '${data['senderUid'] ?? ''}',
      senderName: '${data['senderName'] ?? ''}',
      personName: '${data['personName'] ?? ''}',
      category: '${data['category'] ?? 'sick'}',
      note: '${data['note'] ?? ''}',
      status: '${data['status'] ?? 'pending'}',
      createdAt: ts is Timestamp ? ts.toDate() : null,
    );
  }
}

/// Altar Litany Commemoration Name (المرضى • الراقدين • المسافرين • ضيقات • شكر)
class AltarNameItem {
  final String id;
  final String name;
  final String category; // 'sick' | 'departed' | 'travelers' | 'distressed' | 'thanksgiving'
  final String note;
  final String createdAtIso;

  const AltarNameItem({
    required this.id,
    required this.name,
    required this.category,
    this.note = '',
    required this.createdAtIso,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'category': category,
        'note': note,
        'createdAtIso': createdAtIso,
      };

  factory AltarNameItem.fromJson(Map<String, dynamic> j) => AltarNameItem(
        id: '${j['id'] ?? ''}',
        name: '${j['name'] ?? ''}',
        category: '${j['category'] ?? 'sick'}',
        note: '${j['note'] ?? ''}',
        createdAtIso: '${j['createdAtIso'] ?? ''}',
      );
}

/// Private Pastoral Visitation Entry (دفتر الافتقاد — محلي مشفر 100%)
class VisitationEntry {
  final String id;
  final String personName;
  final String area;
  final String phone;
  final String tag; // 'مريض' | 'أسرة' | 'مسن' | 'شاب' | 'ضيقة'
  final String note;
  final bool visited;
  final bool plannedByMe; // «أنا هروح أفتقده» (في خطتي للافتقاد)
  final String updatedAtIso;

  const VisitationEntry({
    required this.id,
    required this.personName,
    this.area = '',
    this.phone = '',
    this.tag = 'أسرة',
    this.note = '',
    this.visited = false,
    this.plannedByMe = false,
    required this.updatedAtIso,
  });

  VisitationEntry copyWith({
    String? personName,
    String? area,
    String? phone,
    String? tag,
    String? note,
    bool? visited,
    bool? plannedByMe,
    String? updatedAtIso,
  }) =>
      VisitationEntry(
        id: id,
        personName: personName ?? this.personName,
        area: area ?? this.area,
        phone: phone ?? this.phone,
        tag: tag ?? this.tag,
        note: note ?? this.note,
        visited: visited ?? this.visited,
        plannedByMe: plannedByMe ?? this.plannedByMe,
        updatedAtIso: updatedAtIso ?? this.updatedAtIso,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'personName': personName,
        'area': area,
        'phone': phone,
        'tag': tag,
        'note': note,
        'visited': visited,
        'plannedByMe': plannedByMe,
        'updatedAtIso': updatedAtIso,
      };

  factory VisitationEntry.fromJson(Map<String, dynamic> j) => VisitationEntry(
        id: '${j['id'] ?? ''}',
        personName: '${j['personName'] ?? ''}',
        area: '${j['area'] ?? ''}',
        phone: '${j['phone'] ?? ''}',
        tag: '${j['tag'] ?? 'أسرة'}',
        note: '${j['note'] ?? ''}',
        visited: j['visited'] == true,
        plannedByMe: j['plannedByMe'] == true,
        updatedAtIso: '${j['updatedAtIso'] ?? ''}',
      );
}

/// Priest Sermon Preparation Note (تحضير العظات — محلي 100%)
class SermonNote {
  final String id;
  final String title;
  final String occasion;
  final String scriptureRef;
  final String points;
  final String patristicQuote;
  final String updatedAtIso;

  const SermonNote({
    required this.id,
    required this.title,
    this.occasion = '',
    this.scriptureRef = '',
    this.points = '',
    this.patristicQuote = '',
    required this.updatedAtIso,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'occasion': occasion,
        'scriptureRef': scriptureRef,
        'points': points,
        'patristicQuote': patristicQuote,
        'updatedAtIso': updatedAtIso,
      };

  factory SermonNote.fromJson(Map<String, dynamic> j) => SermonNote(
        id: '${j['id'] ?? ''}',
        title: '${j['title'] ?? ''}',
        occasion: '${j['occasion'] ?? ''}',
        scriptureRef: '${j['scriptureRef'] ?? ''}',
        points: '${j['points'] ?? ''}',
        patristicQuote: '${j['patristicQuote'] ?? ''}',
        updatedAtIso: '${j['updatedAtIso'] ?? ''}',
      );
}
