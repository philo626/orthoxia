import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/services/confession_service.dart';
import '../../core/services/storage_service.dart';
import '../../core/theme/app_palette.dart';
import '../../core/widgets/coptic_cross.dart';
import '../../core/widgets/luxe_widgets.dart';
import '../../models/confession_models.dart';
import '../conscience/conscience_exam_view.dart';
import '../onboarding/auth_view.dart';
import 'fathers_directory_view.dart';

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

  Future<void> _handleAttendTap(ConfessionSession session, {bool waitlist = false}) async {
    if (_busySessionIds.contains(session.id)) return;
    HapticFeedback.mediumImpact();

    if (_service.currentUid == null) {
      _promptSignIn();
      return;
    }

    setState(() => _busySessionIds.add(session.id));
    final res = await _service.registerAttendance(session, allowWaitlist: waitlist);
    if (!mounted) return;
    setState(() => _busySessionIds.remove(session.id));

    if (res.status == AttendanceActionStatus.sessionFull && !waitlist) {
      _showWaitlistPrompt(session);
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(res.message, style: GoogleFonts.cairo()),
        duration: const Duration(seconds: 3),
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
              // 1. Selected Father Identity Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: p.goldSoft,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: p.goldBorder),
                ),
                child: Row(
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
              ),

              const SizedBox(height: 10),

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
                        'الساعة المكتوبة هي بداية استقبال قدس أبونا في الكنيسة؛ كل شخص يدخل في دوره ويأخذ الوقت الذي يحتاجه.',
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
            ],
          ),
        ),
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
            color: isConfirmed ? p.sage.withValues(alpha: p.isDark ? 0.14 : 0.08) : p.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isConfirmed ? p.sage : (isWaitlist ? p.gold : p.border),
              width: isConfirmed || isWaitlist ? 1.4 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(Icons.calendar_today_rounded, size: 18, color: p.accent),
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
                      color: !session.isOpen
                          ? p.danger.withValues(alpha: 0.12)
                          : (session.isFull
                              ? p.goldSoft
                              : p.sage.withValues(alpha: 0.15)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      !session.isOpen
                          ? 'التسجيل مغلق'
                          : (session.isFull
                              ? 'اكتمل العدد'
                              : (session.isUnlimited
                                  ? 'عدد مفتوح'
                                  : '${session.confirmedCount} / ${session.maxAttendees}')),
                      style: GoogleFonts.cairo(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: !session.isOpen
                            ? p.danger
                            : (session.isFull ? p.gold : p.sage),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'الاعترافات تبدأ ابتداءً من ${session.startTimeAr}',
                style: GoogleFonts.cairo(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: p.inkSecondary,
                ),
              ),
              if (session.locationNote.isNotEmpty) ...[
                const SizedBox(height: 3),
                Text(
                  'المكان: ${session.locationNote}',
                  style: GoogleFonts.cairo(fontSize: 12, color: p.inkMuted),
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
                        'اتسجّل حضورك في قائمة قدس أبونا',
                        style: GoogleFonts.cairo(
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                          color: p.sage,
                        ),
                      ),
                    ),
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
          ),
        );
      },
    );
  }
}
