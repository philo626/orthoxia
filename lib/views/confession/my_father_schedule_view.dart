import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/services/confession_service.dart';
import '../../core/services/notification_service.dart';
import '../../core/services/storage_service.dart';
import '../../core/theme/app_palette.dart';
import '../../core/widgets/coptic_cross.dart';
import '../../core/widgets/luxe_widgets.dart';
import '../../models/confession_models.dart';
import '../conscience/conscience_exam_view.dart';
import '../onboarding/auth_view.dart';
import '../spiritual_tracker/communion_readiness_view.dart';
import 'confession_companion_guide_view.dart';
import 'fathers_directory_view.dart';

/// Playful Egyptian Arabic validator for two-part confession names («الاسم الثنائي»).
/// If the user enters only one name, responds with warm friendly banter & laugh emojis 😂!
class ConfessionNameValidator {
  static String? validateTwoPartName(String raw, {int attempt = 0}) {
    final cleaned = raw.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (cleaned.isEmpty) {
      return 'اكتب اسمك الثنائي يا جميل عشان قدس أبونا يعرف مين اللي جاي يعترف 😊';
    }
    final words = cleaned.split(' ').where((w) => w.length >= 2).toList();
    if (words.length < 2) {
      final first = words.isNotEmpty ? words.first : cleaned;
      final jokes = [
        'يا جدع اسمك «$first» مميز وحلو أوي والله 😂 بس في ١٠ «$first» غيرك في الكنيسة! اكتب اسمك الثنائي عشان قدس أبونا ميتلخبطش بينكم 😄',
        'هاهاها لا يا بطل اسم واحد مش هيمشي 😂 اكتب اسمك الثنائي عشان أبونا لو نادى «يا $first» هتلاقي نص الكنيسة قامت! 😅',
        'يا راجل يا طيب «$first» لوحده جامد بس كمّل الاسم التاني كمان 😂 عشان قدس أبونا يعرفك بالظبط ويدعيلك بالاسم!',
      ];
      return jokes[attempt % jokes.length];
    }
    return null;
  }
}

/// Member View: «مواعيد أبونا» (Page 04/04 — From «هحضر» to Abona's Notification):
/// - Shows Abona's published open-start-time confession days
/// - Atomic deduplicated «هحضر» confirmation (double-tap NEVER duplicates!)
/// - Clear states: متاح («هحضر») | اتسجّل حضورك (مع زر اعتذار) | أبونا قفل التسجيل | اكتمل العدد (مع قائمة الانتظار)
/// - Strict Privacy reassurance: Confession notes remain 100% locally on user's phone!
class MyFatherScheduleView extends StatefulWidget {
  const MyFatherScheduleView({super.key});

  @override
  State<MyFatherScheduleView> createState() => _MyFatherScheduleViewState();
}

class _MyFatherScheduleViewState extends State<MyFatherScheduleView> {
  final ConfessionService _service = ConfessionService();
  final StorageService _storage = StorageService();
  final Set<String> _busySessionIds = {};
  String _lastScheduledFollowUpKey = '';

  Future<({String name, List<String> companions})?> _askTwoPartConfessionName() async {
    final p = context.palette;
    final initial = _storage.hasCustomUserName() ? _storage.getUserName().trim() : '';
    final ctrl = TextEditingController(text: initial);
    final companionCtrl = TextEditingController();
    final companions = <String>[];
    String? banterError;
    int jokeAttempt = 0;

    final result = await showModalBottomSheet<({String name, List<String> companions})>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) {
          void addCompanion() {
            final clean = companionCtrl.text.trim().replaceAll(RegExp(r'\s+'), ' ');
            if (clean.isEmpty || companions.length >= 5) return;
            setSheet(() {
              companions.add(clean);
              companionCtrl.clear();
            });
          }

          void submitBooking() {
            final err = ConfessionNameValidator.validateTwoPartName(
              ctrl.text,
              attempt: jokeAttempt,
            );
            if (err != null) {
              HapticFeedback.lightImpact();
              setSheet(() {
                banterError = err;
                jokeAttempt++;
              });
              return;
            }
            // If user typed a companion name and forgot to tap "+", include it automatically!
            final pendingComp = companionCtrl.text.trim().replaceAll(RegExp(r'\s+'), ' ');
            if (pendingComp.isNotEmpty && companions.length < 5) {
              companions.add(pendingComp);
            }
            Navigator.pop(ctx, (
              name: ctrl.text.trim().replaceAll(RegExp(r'\s+'), ' '),
              companions: List<String>.from(companions),
            ));
          }

          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
            child: SingleChildScrollView(
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 26),
                decoration: BoxDecoration(
                  color: p.surface,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  border: Border(top: BorderSide(color: p.border)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                            color: p.border, borderRadius: BorderRadius.circular(4)),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'اسمك الثنائي إيه يا جميل؟ 😊',
                      style: GoogleFonts.amiri(
                          fontSize: 23, fontWeight: FontWeight.bold, color: p.ink),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'اكتب اسمك الثنائي عشان يظهر لقدس أبونا في قائمة الحضور ويعرفك بسهولة.',
                      style: GoogleFonts.cairo(
                          fontSize: 12.5, color: p.inkSecondary, height: 1.5),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: ctrl,
                      autofocus: true,
                      textInputAction: TextInputAction.done,
                      style: GoogleFonts.cairo(
                          color: p.ink, fontSize: 15, fontWeight: FontWeight.w600),
                      decoration: const InputDecoration(
                        hintText: 'مثال: كيرلس فادي / مريم مينا',
                        prefixIcon: Icon(Icons.badge_outlined, size: 20),
                      ),
                      onSubmitted: (_) => submitBooking(),
                    ),
                    if (banterError != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: p.goldSoft,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: p.goldBorder, width: 1.3),
                        ),
                        child: Text(
                          banterError!,
                          style: GoogleFonts.cairo(
                            fontSize: 12.5,
                            fontWeight: FontWeight.bold,
                            color: p.ink,
                            height: 1.55,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 14),
                    // Feature #10: Optional Family / Kids Booking from one phone
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: p.surfaceSubtle,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: p.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.family_restroom_rounded, size: 17, color: p.gold),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'معايا أولادي أو حد من الأسرة (اختياري)',
                                  style: GoogleFonts.cairo(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: p.ink,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: companionCtrl,
                                  style: GoogleFonts.cairo(color: p.ink, fontSize: 13),
                                  decoration: const InputDecoration(
                                    isDense: true,
                                    hintText: 'مثال: ابني بيتر / زوجتي مريم',
                                  ),
                                  onSubmitted: (_) => addCompanion(),
                                ),
                              ),
                              const SizedBox(width: 8),
                              OutlinedButton.icon(
                                onPressed: companions.length >= 5 ? null : addCompanion,
                                icon: const Icon(Icons.add_rounded, size: 16),
                                label: Text('إضافة', style: GoogleFonts.cairo(fontSize: 12)),
                              ),
                            ],
                          ),
                          if (companions.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: [
                                for (int i = 0; i < companions.length; i++)
                                  Chip(
                                    label: Text(
                                      companions[i],
                                      style: GoogleFonts.cairo(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.bold,
                                          color: p.ink),
                                    ),
                                    deleteIcon: Icon(Icons.close_rounded,
                                        size: 15, color: p.danger),
                                    onDeleted: () =>
                                        setSheet(() => companions.removeAt(i)),
                                    backgroundColor: p.surface,
                                    side: BorderSide(color: p.goldBorder),
                                  ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: submitBooking,
                      icon: const Icon(Icons.check_circle_outline_rounded, size: 19),
                      label: Text(
                        companions.isEmpty
                            ? 'تمام، سجّل حضوري عند أبونا'
                            : 'تمام، سجّلنا سوا (${companions.length + 1} أفراد) عند أبونا',
                        style: GoogleFonts.cairo(
                            fontWeight: FontWeight.bold, fontSize: 13.5),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
    ctrl.dispose();
    companionCtrl.dispose();
    return result;
  }

  Future<void> _handleAttendTap(ConfessionSession session, {bool waitlist = false}) async {
    if (_busySessionIds.contains(session.id)) return;
    HapticFeedback.mediumImpact();

    if (_service.currentUid == null) {
      _promptSignIn();
      return;
    }

    // Ask & confirm user's two-part name (plus optional family/kids) with playful Egyptian banter!
    final booking = await _askTwoPartConfessionName();
    if (booking == null || booking.name.isEmpty || !mounted) return;
    await _storage.setUserName(booking.name);

    setState(() => _busySessionIds.add(session.id));
    final res = await _service.registerAttendance(
      session,
      allowWaitlist: waitlist,
      attendeeNameOverride: booking.name,
      companionNames: booking.companions,
    );
    if (!mounted) return;
    setState(() => _busySessionIds.remove(session.id));

    if (res.status == AttendanceActionStatus.sessionFull && !waitlist) {
      _showWaitlistPrompt(session);
      return;
    }

    // Smart Confession Reminder (1 hour before session + Conscience Exam nudge!)
    bool reminderSet = false;
    if (res.status == AttendanceActionStatus.confirmed) {
      reminderSet = await NotificationService().scheduleConfessionReminder(
        sessionId: session.id,
        fatherName: _storage.getConfessionFatherName(),
        dateIso: session.dateIso,
        startTimeAr: session.startTimeAr,
        dayLabelAr: session.dayLabelAr,
      );
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          reminderSet
              ? '${res.message} وهنفكّرك قبل الميعاد بساعة تراجع فحص الضمير 🙏'
              : res.message,
          style: GoogleFonts.cairo(),
        ),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  Future<void> _handleCancelTap(ConfessionSession session) async {
    if (_busySessionIds.contains(session.id)) return;
    final p = context.palette;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: p.surface,
        title: Text(
          'الاعتذار عن الموعد',
          style: GoogleFonts.amiri(fontWeight: FontWeight.bold, fontSize: 22, color: p.ink),
        ),
        content: Text(
          'هل تود الاعتذار عن حضور الاعتراف يوم ${session.dayLabelAr}؟ ستتحدث القائمة تلقائياً عند قدس أبونا.',
          style: GoogleFonts.cairo(fontSize: 13.5, color: p.inkSecondary, height: 1.55),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('تراجع', style: GoogleFonts.cairo(color: p.inkMuted)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('تأكيد الاعتذار', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _busySessionIds.add(session.id));
    final res = await _service.cancelMyAttendance(session);
    await NotificationService().cancelConfessionReminder(session.id);
    if (!mounted) return;
    setState(() => _busySessionIds.remove(session.id));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(res.message, style: GoogleFonts.cairo())),
    );
  }

  void _showWaitlistPrompt(ConfessionSession session) {
    final p = context.palette;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: p.surface,
        title: Text(
          'اكتمل العدد لهذا اليوم',
          style: GoogleFonts.amiri(fontWeight: FontWeight.bold, fontSize: 22, color: p.ink),
        ),
        content: Text(
          'وصل العدد المحدد ليوم ${session.dayLabelAr} للحد الأقصى. يمكنك الانضمام لقائمة الانتظار أو اختيار يوم آخر.',
          style: GoogleFonts.cairo(fontSize: 13.5, color: p.inkSecondary, height: 1.55),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('اختيار يوم تاني', style: GoogleFonts.cairo(color: p.inkMuted)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _handleAttendTap(session, waitlist: true);
            },
            child: Text('انضم لقائمة الانتظار', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _promptSignIn() {
    final p = context.palette;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: p.surface,
        title: Text(
          'تسجيل الدخول مطلوب',
          style: GoogleFonts.amiri(fontWeight: FontWeight.bold, fontSize: 22, color: p.ink),
        ),
        content: Text(
          'لتأكيد حضورك باسمك وإبلاغ قدس أبونا، يُرجى تسجيل الدخول أولاً.',
          style: GoogleFonts.cairo(fontSize: 13.5, color: p.inkSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('لاحقاً', style: GoogleFonts.cairo(color: p.inkMuted)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.push(context, luxeRoute(const AuthView()));
            },
            child: const Text('تسجيل الدخول'),
          ),
        ],
      ),
    );
  }

  void _showSendAltarRequestSheet(String fatherUid, String fatherName) {
    if (_service.currentUid == null) {
      _promptSignIn();
      return;
    }
    final p = context.palette;
    final nameCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    String selectedCat = 'sick';
    bool sending = false;

    const cats = <(String, String)>[
      ('sick', 'مريض'),
      ('departed', 'راقد (ترحيم)'),
      ('travelers', 'مسافر'),
      ('distressed', 'ضيقة / طلبة'),
      ('thanksgiving', 'شكر وفرح'),
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 26),
            decoration: BoxDecoration(
              color: p.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              border: Border(top: BorderSide(color: p.border)),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(color: p.border, borderRadius: BorderRadius.circular(4)),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'ابعت اسم للمذبح عند $fatherName',
                    style: GoogleFonts.amiri(fontSize: 22, fontWeight: FontWeight.bold, color: p.ink),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'الاسم بيوصل لقدس أبونا في سرية تامة، وبضغطة واحدة بينزل عند قدسه في قايمة «على المذبح» يذكره في الأواشي والقداس.',
                    style: GoogleFonts.cairo(fontSize: 12, color: p.inkSecondary, height: 1.5),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 7,
                    runSpacing: 7,
                    children: cats.map((c) {
                      final sel = selectedCat == c.$1;
                      return ChoiceChip(
                        selected: sel,
                        selectedColor: p.gold,
                        backgroundColor: p.surfaceSubtle,
                        label: Text(
                          c.$2,
                          style: GoogleFonts.cairo(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: sel ? const Color(0xFF19130A) : p.ink,
                          ),
                        ),
                        onSelected: (_) => setSheet(() => selectedCat = c.$1),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: nameCtrl,
                    autofocus: true,
                    style: GoogleFonts.cairo(color: p.ink, fontSize: 14.5),
                    decoration: const InputDecoration(
                      hintText: 'الاسم المراد ذكره على المذبح (مثال: مينا، أو المنتقل جرجس)',
                      prefixIcon: Icon(Icons.favorite_outline_rounded, size: 20),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: noteCtrl,
                    style: GoogleFonts.cairo(color: p.ink, fontSize: 13.5),
                    decoration: const InputDecoration(
                      hintText: 'ملاحظة قصيرة لقدس أبونا (اختياري — مثال: عملية جراحية / ذكرى الأربعين)',
                      prefixIcon: Icon(Icons.notes_rounded, size: 19),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: sending
                        ? null
                        : () async {
                            setSheet(() => sending = true);
                            final (ok, msg) = await _service.submitAltarPrayerRequest(
                              priestUid: fatherUid,
                              personName: nameCtrl.text,
                              category: selectedCat,
                              note: noteCtrl.text,
                            );
                            if (!ctx.mounted) return;
                            setSheet(() => sending = false);
                            if (ok) Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(msg, style: GoogleFonts.cairo())),
                            );
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: p.gold,
                      foregroundColor: const Color(0xFF19130A),
                    ),
                    icon: sending
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF19130A)),
                          )
                        : const Icon(Icons.send_rounded, size: 18),
                    label: Text(
                      'ابعت الاسم لقدس أبونا للمذبح',
                      style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showGreetFatherSheet(String fatherName) {
    final p = context.palette;
    final myName = _storage.hasCustomUserName() ? _storage.getUserName().trim() : '';
    final sig = myName.isNotEmpty ? '\nابنك / ابنتك: $myName' : '';
    final templates = <({String title, String emoji, String body})>[
      (
        title: 'تهنئة بعيد أو مناسبة حلوة',
        emoji: '✨',
        body:
            'سلام ونعمة يا قدس $fatherName، كل سنة وقدسك طيب وبخير دايماً! ربنا يديم كهنوتك ويبارك تعبك وخدمتك ويفرح قلبك دايماً. اذكرنا في صلوات قدسك.$sig',
      ),
      (
        title: 'تهنئة بعيد سيامة قدسك',
        emoji: '🕊️',
        body:
            'ألف مبروك عيد سيامة قدسك يا قدس $fatherName! عقبال سنين كتير مليانة نعمة وثمر في خدمة المذبح والكنيسة. بركة صلوات قدسك تكون معانا.$sig',
      ),
      (
        title: 'سلام واطمئنان وطلب صلاة',
        emoji: '🙏',
        body:
            'سلام ونعمة يا قدس $fatherName، حبيت أسلم على قدسك وأطمن على صحتك وأطلب صلواتك من أجلنا ومن أجل البيت كله.$sig',
      ),
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
        decoration: BoxDecoration(
          color: p.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(top: BorderSide(color: p.border)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: p.border, borderRadius: BorderRadius.circular(4)),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'ابعت تهنئة أو سلام لـ $fatherName',
              style: GoogleFonts.amiri(fontSize: 21, fontWeight: FontWeight.bold, color: p.ink),
            ),
            const SizedBox(height: 4),
            Text(
              'اختار رسالة جاهزة بالعامية المحترمة وابعتها لقدس أبونا على واتساب أو أي تطبيق:',
              style: GoogleFonts.cairo(fontSize: 12, color: p.inkMuted),
            ),
            const SizedBox(height: 12),
            ...templates.map(
              (tpl) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () async {
                    HapticFeedback.lightImpact();
                    Navigator.pop(ctx);
                    await SharePlus.instance.share(ShareParams(text: tpl.body));
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: p.surfaceSubtle,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: p.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(tpl.emoji, style: const TextStyle(fontSize: 15)),
                            const SizedBox(width: 6),
                            Text(
                              tpl.title,
                              style: GoogleFonts.cairo(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: p.ink,
                              ),
                            ),
                            const Spacer(),
                            Icon(Icons.share_rounded, size: 16, color: p.gold),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          tpl.body,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.cairo(fontSize: 11.5, color: p.inkSecondary, height: 1.45),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final fatherUid = _storage.getConfessionFatherUid();
    final fatherName = _storage.getConfessionFatherName();
    final fatherChurch = _storage.getConfessionFatherChurch();
    final fatherDiocese = _storage.getConfessionFatherDiocese();

    if (fatherUid.isEmpty) {
      return const FathersDirectoryView();
    }

    return Scaffold(
      backgroundColor: p.canvas,
      appBar: AppBar(
        backgroundColor: p.canvas,
        foregroundColor: p.ink,
        elevation: 0,
        title: Text(
          'مواعيد أبونا',
          style: GoogleFonts.amiri(fontWeight: FontWeight.bold, fontSize: 23, color: p.ink),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await Navigator.push(context, luxeRoute(const FathersDirectoryView()));
              if (mounted) setState(() {});
            },
            child: Text(
              'تغيير أبونا',
              style: GoogleFonts.cairo(fontSize: 12.5, fontWeight: FontWeight.bold, color: p.accent),
            ),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 36),
            children: [
              // 1. Selected Father Identity Card + 1-Tap Greeting/Congratulation Button
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: p.goldSoft,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: p.goldBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: p.surface,
                            border: Border.all(color: p.goldBorder),
                          ),
                          child: Center(child: CopticCross(size: 22, color: p.accent)),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                fatherName,
                                style: GoogleFonts.amiri(
                                  fontSize: 21,
                                  fontWeight: FontWeight.bold,
                                  color: p.ink,
                                ),
                              ),
                              if (fatherChurch.isNotEmpty)
                                Text(
                                  fatherChurch,
                                  style: GoogleFonts.cairo(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.bold,
                                    color: p.accent,
                                  ),
                                ),
                              if (fatherDiocese.isNotEmpty)
                                Text(
                                  'إيبارشية: $fatherDiocese',
                                  style: GoogleFonts.cairo(fontSize: 11.5, color: p.inkSecondary),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _showSendAltarRequestSheet(fatherUid, fatherName),
                            style: OutlinedButton.styleFrom(
                              backgroundColor: p.surface,
                              foregroundColor: p.ink,
                              side: BorderSide(color: p.goldBorder),
                              padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            icon: Icon(Icons.local_fire_department_rounded, size: 17, color: p.gold),
                            label: Text(
                              'ابعت اسم للمذبح',
                              style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _showGreetFatherSheet(fatherName),
                            style: OutlinedButton.styleFrom(
                              backgroundColor: p.surface,
                              foregroundColor: p.accent,
                              side: BorderSide(color: p.goldBorder),
                              padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            icon: const Icon(Icons.favorite_outline_rounded, size: 17),
                            label: Text(
                              'تهنئة وسلام لأبونا',
                              style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              // 1b. Abouna's Personal Return-to-Confession Schedule Card (if Abouna ticked ✓ & set interval!)
              StreamBuilder<PriestConfessorRecord?>(
                stream: _service.watchMyFollowUpFromFather(fatherUid),
                builder: (context, followSnap) {
                  final rec = followSnap.data;
                  if (rec == null || rec.lastConfessionDateIso.isEmpty) {
                    return const SizedBox.shrink();
                  }

                  // Silently sync local last confession date, active offline spiritual exercise & OS reminder
                  final syncKey =
                      '${rec.lastConfessionDateIso}_${rec.nextConfessionDateIso}_${rec.followUpNote}';
                  if (_lastScheduledFollowUpKey != syncKey) {
                    _lastScheduledFollowUpKey = syncKey;
                    _storage.setLastConfessionDateIso(rec.lastConfessionDateIso);
                    if (rec.followUpNote.trim().isNotEmpty) {
                      _storage.setActiveSpiritualExercise(rec.followUpNote.trim());
                    }
                    if (rec.nextConfessionDateIso.isNotEmpty) {
                      NotificationService().scheduleNextConfessionFollowUp(
                        fatherName: fatherName,
                        nextDateIso: rec.nextConfessionDateIso,
                        intervalDays: rec.nextIntervalDays,
                        followUpNote: rec.followUpNote,
                      );
                    }
                  }

                  final daysLeft = rec.daysUntilNext;
                  final isDue = rec.isDueNow;
                  final showCleanSlate =
                      rec.lastConfessionDateIso != _storage.getLastCleanedConfessionIso() &&
                          _storage.hasAnyConscienceNotes();

                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDue
                          ? p.goldSoft
                          : p.sage.withValues(alpha: p.isDark ? 0.16 : 0.09),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: isDue ? p.gold : p.sage,
                        width: 1.3,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              isDue ? Icons.notifications_active_rounded : Icons.verified_rounded,
                              color: isDue ? p.gold : p.sage,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                isDue
                                    ? 'حان ميعاد اعترافك الجديد مع $fatherName 🙏'
                                    : 'تم اعترافك مع $fatherName ✓',
                                style: GoogleFonts.cairo(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.bold,
                                  color: p.ink,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 5),
                        Text(
                          rec.nextConfessionDateIso.isNotEmpty
                              ? (isDue
                                  ? 'عدّت المدة اللي قدس أبونا حددها (${PriestConfessorRecord.formatIntervalLabel(rec.nextIntervalDays)}) — احجز يومك الجديد من المواعيد تحت.'
                                  : 'قدس أبونا حدّدلك تيجي تاني بعد ${PriestConfessorRecord.formatIntervalLabel(rec.nextIntervalDays)} (يوم ${PriestConfessorRecord.formatArabicDateShort(rec.nextConfessionDateIso)} — متبقي $daysLeft يوم) وهنفكّرك يومها تلقائياً.')
                              : 'آخر اعتراف مسجّل عند قدس أبونا يوم ${PriestConfessorRecord.formatArabicDateShort(rec.lastConfessionDateIso)}.',
                          style: GoogleFonts.cairo(
                            fontSize: 12,
                            color: p.inkSecondary,
                            height: 1.5,
                          ),
                        ),
                        if (rec.followUpNote.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: p.surface,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: p.border),
                            ),
                            child: Text(
                              'كلمة وتدريب من قدس أبونا: «${rec.followUpNote}»',
                              style: GoogleFonts.cairo(
                                fontSize: 11.8,
                                fontWeight: FontWeight.w600,
                                color: p.accent,
                              ),
                            ),
                          ),
                        ],
                        // Feature #6: Clean Slate Prompt after Confession (100% local on-device wipe!)
                        if (showCleanSlate) ...[
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                HapticFeedback.mediumImpact();
                                await _storage.clearConscienceNotes();
                                await _storage
                                    .setLastCleanedConfessionIso(rec.lastConfessionDateIso);
                                if (!context.mounted) return;
                                setState(() {});
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'تم مسح مسودة فحص الضمير القديمة — ربنا يديك بداية جديدة مليانة سلام ✨',
                                      style: GoogleFonts.cairo(),
                                    ),
                                  ),
                                );
                              },
                              icon: Icon(Icons.auto_awesome_rounded, size: 17, color: p.gold),
                              label: Text(
                                'امسح مسودة فحص الضمير القديمة وابدأ صفحة بيضا ✨',
                                style: GoogleFonts.cairo(
                                  fontSize: 11.8,
                                  fontWeight: FontWeight.bold,
                                  color: p.ink,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: p.goldBorder),
                                backgroundColor: p.surface,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),

              // Feature #7: 100% OFFLINE Spiritual Exercise Box from Abouna (daily check-in ✓)
              _buildOfflineSpiritualExerciseCard(p),

              // Features #8 & #9: 100% OFFLINE Confession Companion Strip (Before/After Prayers + Returning Guide)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    _buildOfflineCompanionPill(
                      p: p,
                      icon: Icons.favorite_outline_rounded,
                      label: 'قبل الاعتراف',
                      tab: 0,
                    ),
                    const SizedBox(width: 8),
                    _buildOfflineCompanionPill(
                      p: p,
                      icon: Icons.auto_awesome_rounded,
                      label: 'بعد الحل',
                      tab: 1,
                    ),
                    const SizedBox(width: 8),
                    _buildOfflineCompanionPill(
                      p: p,
                      icon: Icons.volunteer_activism_rounded,
                      label: 'راجع بعد غياب؟',
                      tab: 2,
                    ),
                  ],
                ),
              ),

              // 2. Calm Start-Time Explanation Note (Page 02/04)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: p.surfaceSubtle,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: p.border),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline_rounded, size: 18, color: p.accent),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'الساعة المكتوبة دي بداية استقبال قدس أبونا في الكنيسة؛ كل واحد بيدخل في دوره وياخد وقته براحته.',
                        style: GoogleFonts.cairo(fontSize: 11.5, color: p.inkSecondary, height: 1.5),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // 3. Live Published Confession Sessions Stream
              StreamBuilder<List<ConfessionSession>>(
                stream: _service.watchPriestSessions(fatherUid),
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                    );
                  }
                  final sessions = snap.data ?? [];
                  if (sessions.isEmpty) {
                    return Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: p.surface,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: p.border),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.event_available_outlined,
                              size: 42, color: p.inkMuted.withValues(alpha: 0.45)),
                          const SizedBox(height: 10),
                          Text(
                            'لا توجد مواعيد اعتراف منشورة حالياً',
                            style: GoogleFonts.amiri(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: p.ink,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'فور أن يفتح قدس أبونا موعداً جديداً للاعترافات سيظهر لك هنا تلقائياً.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.cairo(fontSize: 12.5, color: p.inkMuted),
                          ),
                        ],
                      ),
                    );
                  }

                  return Column(
                    children: sessions.map((s) => _buildSessionCard(p, s)).toList(),
                  );
                },
              ),

              const SizedBox(height: 18),

              // 4. Direct Link to Private On-Device Confession Notes (Page 04/04 privacy guarantee!)
              PressScale(
                scale: 0.985,
                onTap: () => Navigator.push(context, luxeRoute(const ConscienceExamView())),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: p.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: p.border),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: p.goldSoft,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.lock_outline_rounded, size: 20, color: p.accent),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'مذكرة الاعتراف وفحص الضمير',
                              style: GoogleFonts.cairo(
                                fontSize: 13.5,
                                fontWeight: FontWeight.bold,
                                color: p.ink,
                              ),
                            ),
                            Text(
                              'تُحفظ مشفّرة على موبايلك وحدك ولا تُرسل لأي جهة أبداً.',
                              style: GoogleFonts.cairo(fontSize: 11, color: p.inkMuted),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_left_rounded, size: 19, color: p.inkMuted),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              // 5. Communion & Confession Readiness Shortcut
              PressScale(
                scale: 0.985,
                onTap: () => Navigator.push(context, luxeRoute(const CommunionReadinessView())),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: p.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: p.goldBorder),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: p.goldSoft,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.church_rounded, size: 20, color: p.gold),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'الاستعداد للقداس والتناول والاعتراف',
                              style: GoogleFonts.cairo(
                                fontSize: 13.5,
                                fontWeight: FontWeight.bold,
                                color: p.ink,
                              ),
                            ),
                            Text(
                              'تابع تاريخ آخر اعتراف وتناول مع قائمة الاستعداد الهادية.',
                              style: GoogleFonts.cairo(fontSize: 11, color: p.inkMuted),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_left_rounded, size: 19, color: p.inkMuted),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOfflineCompanionPill({
    required AppPalette p,
    required IconData icon,
    required String label,
    required int tab,
  }) {
    return Expanded(
      child: PressScale(
        scale: 0.96,
        onTap: () => Navigator.push(
          context,
          luxeRoute(ConfessionCompanionGuideView(initialTab: tab)),
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          decoration: BoxDecoration(
            color: p.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: p.goldBorder),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: p.gold),
              const SizedBox(height: 4),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: GoogleFonts.cairo(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: p.ink,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOfflineSpiritualExerciseCard(AppPalette p) {
    final exercise = _storage.getActiveSpiritualExercise().trim();
    if (exercise.isEmpty) return const SizedBox.shrink();

    final now = DateTime.now();
    final todayIso =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final doneDays = _storage.getSpiritualExerciseDoneDays();
    final doneToday = doneDays.contains(todayIso);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: doneToday ? p.sage.withValues(alpha: p.isDark ? 0.16 : 0.09) : p.goldSoft,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: doneToday ? p.sage : p.goldBorder, width: 1.3),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                doneToday ? Icons.task_alt_rounded : Icons.spa_rounded,
                size: 19,
                color: doneToday ? p.sage : p.gold,
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  'صندوق التدريب الروحي من قدس أبونا',
                  style: GoogleFonts.cairo(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: p.ink,
                  ),
                ),
              ),
              if (doneDays.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: p.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: p.border),
                  ),
                  child: Text(
                    'واظبت ${doneDays.length} يوم',
                    style: GoogleFonts.cairo(
                      fontSize: 10.5,
                      fontWeight: FontWeight.bold,
                      color: p.sage,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '«$exercise»',
            style: GoogleFonts.amiri(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: p.ink,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () async {
                    HapticFeedback.lightImpact();
                    await _storage.toggleSpiritualExerciseDoneToday(todayIso);
                    if (mounted) setState(() {});
                  },
                  icon: Icon(
                    doneToday ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                    size: 18,
                  ),
                  label: Text(
                    doneToday ? 'عملت التدريب النهاردة ✓' : 'علّم إني عملت التدريب النهاردة',
                    style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: doneToday ? p.sage : p.accent,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              IconButton(
                tooltip: 'إخفاء التدريب',
                onPressed: () async {
                  await _storage.setActiveSpiritualExercise('');
                  if (mounted) setState(() {});
                },
                icon: Icon(Icons.close_rounded, size: 18, color: p.inkMuted),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSessionCard(AppPalette p, ConfessionSession session) {
    final isBusy = _busySessionIds.contains(session.id);

    return StreamBuilder<ConfessionAttendee?>(
      stream: _service.watchMyAttendance(session.id),
      builder: (context, attSnap) {
        final myAtt = attSnap.data;
        final myStatus = myAtt?.status ?? '';
        final isConfirmed = myStatus == 'confirmed';
        final isWaitlist = myStatus == 'waitlist';

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: session.isCancelled
                ? p.danger.withValues(alpha: p.isDark ? 0.12 : 0.06)
                : (isConfirmed ? p.sage.withValues(alpha: p.isDark ? 0.14 : 0.08) : p.surface),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: session.isCancelled
                  ? p.danger.withValues(alpha: 0.6)
                  : (isConfirmed ? p.sage : (isWaitlist ? p.gold : p.border)),
              width: session.isCancelled || isConfirmed || isWaitlist ? 1.4 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(
                    session.isCancelled ? Icons.event_busy_rounded : Icons.calendar_today_rounded,
                    size: 18,
                    color: session.isCancelled ? p.danger : p.accent,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      session.dayLabelAr,
                      style: GoogleFonts.amiri(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: p.ink,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: session.isCancelled || !session.isOpen
                          ? p.danger.withValues(alpha: 0.12)
                          : (session.isFull
                              ? p.goldSoft
                              : p.sage.withValues(alpha: 0.15)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      session.isCancelled
                          ? 'مُؤجَّل طارئاً'
                          : (!session.isOpen
                              ? 'التسجيل مغلق'
                              : (session.isFull
                                  ? 'اكتمل العدد'
                                  : (session.isUnlimited
                                      ? 'عدد مفتوح'
                                      : '${session.confirmedCount} / ${session.maxAttendees}'))),
                      style: GoogleFonts.cairo(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: session.isCancelled || !session.isOpen
                            ? p.danger
                            : (session.isFull ? p.gold : p.sage),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'ميعاد الاعتراف: ${session.timeRangeLabelAr}',
                style: GoogleFonts.cairo(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: p.inkSecondary,
                ),
              ),
              if (session.audienceGroup.isNotEmpty) ...[
                const SizedBox(height: 4),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 2),
                    decoration: BoxDecoration(
                      color: p.goldSoft,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: p.goldBorder),
                    ),
                    child: Text(
                      'فئة اليوم: ${session.audienceGroup}',
                      style: GoogleFonts.cairo(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: p.gold,
                      ),
                    ),
                  ),
                ),
              ],
              if (session.locationNote.isNotEmpty) ...[
                const SizedBox(height: 3),
                Text(
                  'المكان: ${session.locationNote}',
                  style: GoogleFonts.cairo(fontSize: 12, color: p.inkMuted),
                ),
              ],

              // Feature #2: Emergency Postpone / Apology Notice Banner from Abouna
              if (session.isCancelled) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: p.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: p.danger.withValues(alpha: 0.45)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.campaign_rounded, size: 17, color: p.danger),
                          const SizedBox(width: 6),
                          Text(
                            'اعتذار وتأجيل طارئ من قدس أبونا',
                            style: GoogleFonts.cairo(
                              fontSize: 12.2,
                              fontWeight: FontWeight.bold,
                              color: p.danger,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        session.cancelNotice.isNotEmpty
                            ? session.cancelNotice
                            : 'اعتذر قدس أبونا لظرف طارئ عن اعترافات اليوم، تقدر تختار يوم تاني من المواعيد.',
                        style: GoogleFonts.cairo(
                          fontSize: 12,
                          color: p.inkSecondary,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                // Feature #3: Live Anonymous Queue Banner when Confirmed!
                if (isConfirmed && myAtt != null && myAtt.queueNumber > 0) ...[
                  const SizedBox(height: 12),
                  _buildLiveQueueBanner(p, session, myAtt),
                ],
                if (isConfirmed && myAtt != null && myAtt.companionNames.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.family_restroom_rounded, size: 15, color: p.gold),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          'مسجّل معاك: ${myAtt.companionNames.join('، ')}',
                          style: GoogleFonts.cairo(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: p.inkSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 14),

                // Dynamic Action Area matching Page 04/04
                if (isConfirmed)
                  Row(
                    children: [
                      Icon(Icons.check_circle_rounded, color: p.sage, size: 20),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          myAtt?.confessed == true
                              ? 'الحمد لله اعترفت النهاردة ✓'
                              : 'اتسجّل حضورك في قائمة قدس أبونا',
                          style: GoogleFonts.cairo(
                            fontSize: 12.5,
                            fontWeight: FontWeight.bold,
                            color: p.sage,
                          ),
                        ),
                      ),
                      if (myAtt?.confessed != true)
                        TextButton(
                          onPressed: isBusy ? null : () => _handleCancelTap(session),
                          child: Text(
                            'الاعتذار عن الموعد',
                            style: GoogleFonts.cairo(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: p.danger,
                            ),
                          ),
                        ),
                    ],
                  )
                else if (isWaitlist)
                  Row(
                    children: [
                      Icon(Icons.hourglass_top_rounded, color: p.gold, size: 19),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'أنت مسجّل في قائمة الانتظار لهذا اليوم',
                          style: GoogleFonts.cairo(
                            fontSize: 12.5,
                            fontWeight: FontWeight.bold,
                            color: p.gold,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: isBusy ? null : () => _handleCancelTap(session),
                        child: Text(
                          'إلغاء',
                          style: GoogleFonts.cairo(fontSize: 12, color: p.danger),
                        ),
                      ),
                    ],
                  )
                else if (!session.isOpen)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                    decoration: BoxDecoration(
                      color: p.surfaceSubtle,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'أبونا قفل التسجيل لهذا اليوم • يمكنك اختيار يوم آخر.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.cairo(fontSize: 12, color: p.inkMuted),
                    ),
                  )
                else if (session.isFull)
                  OutlinedButton.icon(
                    onPressed: isBusy ? null : () => _handleAttendTap(session, waitlist: true),
                    icon: isBusy
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.playlist_add_rounded, size: 18),
                    label: Text(
                      'اكتمل العدد — انضم لقائمة الانتظار',
                      style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
                    ),
                  )
                else
                  ElevatedButton.icon(
                    onPressed: isBusy ? null : () => _handleAttendTap(session),
                    icon: isBusy
                        ? SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: p.onAccent),
                          )
                        : const Icon(Icons.check_rounded, size: 19),
                    label: Text(
                      'هحضر',
                      style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 14.5),
                    ),
                  ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildLiveQueueBanner(
    AppPalette p,
    ConfessionSession session,
    ConfessionAttendee myAtt,
  ) {
    if (myAtt.confessed) {
      return PressScale(
        scale: 0.985,
        onTap: () => Navigator.push(
          context,
          luxeRoute(const ConfessionCompanionGuideView(initialTab: 1)),
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: p.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: p.sage),
          ),
          child: Row(
            children: [
              Icon(Icons.auto_awesome_rounded, size: 19, color: p.sage),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'مبروك الحل والغفران ✨ اضغط هنا لقراءة صلاة الشكر بعد الحل (أوفلاين)',
                  style: GoogleFonts.cairo(
                    fontSize: 11.8,
                    fontWeight: FontWeight.bold,
                    color: p.ink,
                  ),
                ),
              ),
              Icon(Icons.chevron_left_rounded, size: 18, color: p.sage),
            ],
          ),
        ),
      );
    }

    final ahead = (myAtt.queueNumber - session.currentServingNumber - 1).clamp(0, 999);
    final isUpNext = ahead == 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isUpNext ? p.goldSoft : p.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isUpNext ? p.gold : p.border, width: isUpNext ? 1.3 : 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: isUpNext ? p.gold : p.accentSoft,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              'دور #${myAtt.queueNumber}',
              style: GoogleFonts.cairo(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isUpNext ? Colors.white : p.accent,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isUpNext
                      ? 'دورك اللي جاي يا جميل، استعد 🙏'
                      : 'فاضل قدامك $ahead بس (الدور المباشر)',
                  style: GoogleFonts.cairo(
                    fontSize: 12.2,
                    fontWeight: FontWeight.bold,
                    color: p.ink,
                  ),
                ),
                Text(
                  isUpNext
                      ? 'اقرأ صلاة قصيرة واطلب إرشاد الروح القدس.'
                      : 'اقعد صلي بهدوء في الكنيسة من غير قلق لحد ما دورك يقرب.',
                  style: GoogleFonts.cairo(fontSize: 11, color: p.inkMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
