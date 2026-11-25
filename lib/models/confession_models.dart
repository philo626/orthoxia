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
      verificationNote: '${data['verificationNote'] ?? ''}',
      adminFeedback: '${data['adminFeedback'] ?? ''}',
      phoneForVerification: '${data['phoneForVerification'] ?? ''}',
      updatedAt: ts is Timestamp ? ts.toDate() : null,
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
