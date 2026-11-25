import 'package:cloud_firestore/cloud_firestore.dart';

/// Official Coptic Orthodox Dioceses & Regions for Priest Directory Search/Filters
class CopticDiocesesCatalog {
  static const List<String> dioceses = [
    'القاهرة الكبرى',
    'الإسكندرية',
    'الجيزة',
    'شبرا الخيمة وتوابعها',
    'حلوان والمعصرة',
    'المعادي والبساتين ودار السلام',
    'مصر الجديدة وعين شمس والمطرية',
    'شبرا الشمالية',
    'شبرا الجنوبية',
    'شرق السكة الحديد',
    'القليوبية وبنها وقويسنا',
    'الشرقية والزقازيق ومنيا القمح',
    'العاشر من رمضان',
    'الدقهلية والمنصورة',
    'دمياط وكفر الشيخ والبراري',
    'الغربية وطنطا والمحلة الكبرى',
    'المنوفية وشبين الكوم',
    'البحيرة ومطروح والخمس مدن الغربية',
    'بورسعيد',
    'الإسماعيلية',
    'السويس',
    'الفيوم',
    'بني سويف وببا والفشن',
    'المنيا وأبوقرقاص ومغاغة وسمالوط ومطاي وملوي وديرمواس',
    'أسيوط وديروط والقوصية ومنفلوط وأبوتيج وأبنوب',
    'سوهاج وأخميم والبلينا وطما وطهطا وجرجا',
    'قنا ونجع حمادي ودشنا ونقادة وقوص',
    'الأقصر وإسنا وأرمنت',
    'أسوان وكوم أمبو وإدفو',
    'البحر الأحمر والغردقة',
    'الوادي الجديد',
    'شمال وجنوب سيناء',
    'إيبارشيات المهجر (أوروبا / أمريكا / كندا / أستراليا / الخليج)',
  ];
}

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

/// Single-use peer-priest vouch invite code (e.g. KN-7391) issued by an approved priest
class PriestVouchInvite {
  final String code;
  final String issuerUid;
  final String issuerName;
  final String issuerChurch;
  final bool used;
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
    this.usedByUid = '',
    this.usedByName = '',
    this.createdAt,
    this.expiresAt,
  });

  bool get isExpired => expiresAt != null && DateTime.now().isAfter(expiresAt!);

  factory PriestVouchInvite.fromMap(String code, Map<String, dynamic> data) {
    final cTs = data['createdAt'];
    final eTs = data['expiresAt'];
    return PriestVouchInvite(
      code: code,
      issuerUid: '${data['issuerUid'] ?? ''}',
      issuerName: '${data['issuerName'] ?? ''}',
      issuerChurch: '${data['issuerChurch'] ?? ''}',
      used: data['used'] == true,
      usedByUid: '${data['usedByUid'] ?? ''}',
      usedByName: '${data['usedByName'] ?? ''}',
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
  final String startTimeAr; // e.g. '٥:٠٠ مساءً'
  final String locationNote; // optional e.g. 'مكتب الاعتراف بالكنيسة'
  final int? maxAttendees; // null = عدد مفتوح
  final bool isOpen; // false = أبونا قفل التسجيل
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
    this.locationNote = '',
    this.maxAttendees,
    required this.isOpen,
    required this.confirmedCount,
    required this.waitlistCount,
    this.createdAt,
  });

  bool get isUnlimited => maxAttendees == null || maxAttendees! <= 0;
  bool get isFull => !isUnlimited && confirmedCount >= maxAttendees!;

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
      locationNote: '${data['locationNote'] ?? ''}',
      maxAttendees: rawMax is num && rawMax.toInt() > 0 ? rawMax.toInt() : null,
      isOpen: data['isOpen'] != false,
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
  final String status; // 'confirmed' | 'waitlist' | 'cancelled'
  final String dayLabelAr;
  final String startTimeAr;
  final DateTime? updatedAt;

  const ConfessionAttendee({
    required this.attendeeUid,
    required this.sessionId,
    required this.attendeeName,
    required this.status,
    required this.dayLabelAr,
    required this.startTimeAr,
    this.updatedAt,
  });

  factory ConfessionAttendee.fromMap(String uid, Map<String, dynamic> data) {
    final ts = data['updatedAt'];
    return ConfessionAttendee(
      attendeeUid: uid,
      sessionId: '${data['sessionId'] ?? ''}',
      attendeeName: '${data['attendeeName'] ?? ''}',
      status: '${data['status'] ?? 'confirmed'}',
      dayLabelAr: '${data['dayLabelAr'] ?? ''}',
      startTimeAr: '${data['startTimeAr'] ?? ''}',
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
  final String updatedAtIso;

  const VisitationEntry({
    required this.id,
    required this.personName,
    this.area = '',
    this.phone = '',
    this.tag = 'أسرة',
    this.note = '',
    this.visited = false,
    required this.updatedAtIso,
  });

  VisitationEntry copyWith({
    String? personName,
    String? area,
    String? phone,
    String? tag,
    String? note,
    bool? visited,
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
