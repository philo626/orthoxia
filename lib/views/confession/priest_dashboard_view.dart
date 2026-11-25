import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/services/confession_service.dart';
import '../../core/services/storage_service.dart';
import '../../core/theme/app_palette.dart';
import '../../core/widgets/coptic_cross.dart';
import '../../core/widgets/luxe_widgets.dart';
import '../../models/confession_models.dart';
import '../onboarding/auth_view.dart';

/// Priest Confessions & Dual-Code Trust Center («إدارة الاعترافات والأكواد»):
/// Serves as Tab 2 of PriestNavigationShell (or standalone page):
///   1) Fixed Private Confession Code (`AB-XXXX`) -> works IMMEDIATELY for Abona's own children!
///   2) Open-Start-Time Confession Session Publisher + Live Attendee Lists + Privacy-First Inbox
///   3) Peer-Priest Single-Use Vouch Codes (`KN-XXXX`) -> verified priests vouch for fellow priests!
class PriestDashboardView extends StatefulWidget {
  final bool embeddedInShell;
  const PriestDashboardView({super.key, this.embeddedInShell = false});

  @override
  State<PriestDashboardView> createState() => _PriestDashboardViewState();
}

class _PriestDashboardViewState extends State<PriestDashboardView> {
  final ConfessionService _service = ConfessionService();
  final StorageService _storage = StorageService();

  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _churchCtrl = TextEditingController();
  final TextEditingController _phoneCtrl = TextEditingController();
  final TextEditingController _noteCtrl = TextEditingController();
  final TextEditingController _redeemVouchCtrl = TextEditingController();

  String _titlePrefix = 'القس';
  String _selectedDiocese = CopticDiocesesCatalog.dioceses.first;
  bool _submittingForm = false;
  bool _redeemingVouch = false;
  bool _issuingInvite = false;
  bool _editingProfile = false;
  bool _prefilledFromProfile = false;
  String _localCode = '';

  static const List<String> _arWeekdays = [
    'الاثنين',
    'الثلاثاء',
    'الأربعاء',
    'الخميس',
    'الجمعة',
    'السبت',
    'الأحد',
  ];
  static const List<String> _arMonths = [
    'يناير',
    'فبراير',
    'مارس',
    'أبريل',
    'مايو',
    'يونيو',
    'يوليو',
    'أغسطس',
    'سبتمبر',
    'أكتوبر',
    'نوفمبر',
    'ديسمبر',
  ];

  @override
  void initState() {
    super.initState();
    _initLocalCode();
    _service.startPriestRealtimeAlertListener();
  }

  Future<void> _initLocalCode() async {
    final code = await _service.ensureLocalPrivateCode();
    if (mounted) setState(() => _localCode = code);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _churchCtrl.dispose();
    _phoneCtrl.dispose();
    _noteCtrl.dispose();
    _redeemVouchCtrl.dispose();
    super.dispose();
  }

  String _formatArDate(DateTime d) {
    final wd = _arWeekdays[(d.weekday - 1).clamp(0, 6)];
    final mo = _arMonths[(d.month - 1).clamp(0, 11)];
    return '$wd ${d.day} $mo';
  }

  String _formatArTime(TimeOfDay t) {
    final isPm = t.hour >= 12;
    final h12 = t.hour == 0 ? 12 : (t.hour > 12 ? t.hour - 12 : t.hour);
    final minStr = t.minute.toString().padLeft(2, '0');
    return '$h12:$minStr ${isPm ? 'مساءً' : 'صباحاً'}';
  }

  void _prefillForm(PriestProfile? profile) {
    if (_prefilledFromProfile) return;
    _prefilledFromProfile = true;
    if (profile != null) {
      _titlePrefix = profile.titlePrefix == 'القمص' ? 'القمص' : 'القس';
      _nameCtrl.text = profile.displayName;
      _churchCtrl.text = profile.church;
      _phoneCtrl.text = profile.phoneForVerification;
      _noteCtrl.text = profile.verificationNote;
      if (CopticDiocesesCatalog.dioceses.contains(profile.diocese)) {
        _selectedDiocese = profile.diocese;
      }
    } else {
      _titlePrefix = _storage.getPriestTitlePrefix();
      if (_storage.hasCustomUserName()) _nameCtrl.text = _storage.getUserName();
      _churchCtrl.text = _storage.getPriestChurch();
      final d = _storage.getPriestDiocese();
      if (CopticDiocesesCatalog.dioceses.contains(d)) _selectedDiocese = d;
    }
  }

  Future<void> _submitProfile() async {
    HapticFeedback.lightImpact();
    setState(() => _submittingForm = true);
    final (ok, msg) = await _service.submitOrUpdatePriestVerification(
      titlePrefix: _titlePrefix,
      displayName: _nameCtrl.text,
      diocese: _selectedDiocese,
      church: _churchCtrl.text,
      phoneForVerification: _phoneCtrl.text,
      verificationNote: _noteCtrl.text,
    );
    final refreshedCode = await _service.ensureLocalPrivateCode();
    if (!mounted) return;
    setState(() {
      _submittingForm = false;
      _localCode = refreshedCode;
      if (ok) _editingProfile = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg, style: GoogleFonts.cairo())),
    );
  }

  Future<void> _redeemVouchCode() async {
    final raw = _redeemVouchCtrl.text.trim();
    if (raw.isEmpty) return;
    HapticFeedback.mediumImpact();
    setState(() => _redeemingVouch = true);
    final (ok, msg) = await _service.redeemPeerPriestInviteCode(raw);
    if (!mounted) return;
    setState(() {
      _redeemingVouch = false;
      if (ok) _redeemVouchCtrl.clear();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg, style: GoogleFonts.cairo()), duration: const Duration(seconds: 4)),
    );
  }

  Future<void> _issuePeerInvite(PriestProfile priest) async {
    HapticFeedback.mediumImpact();
    setState(() => _issuingInvite = true);
    final (invite, msg) = await _service.generatePeerPriestInviteCode(priest);
    if (!mounted) return;
    setState(() => _issuingInvite = false);

    if (invite == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg, style: GoogleFonts.cairo())),
      );
      return;
    }

    final p = context.palette;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: p.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Row(
          children: [
            CopticCross(size: 18, color: p.gold),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'كود تزكية جديد لأب كاهن زميل',
                style: GoogleFonts.amiri(fontSize: 21, fontWeight: FontWeight.bold, color: p.ink),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'هذا الكود جديد ومخصّص لاستخدام واحد فقط (لمدة ٧ أيام). أول ما الكاهن الزميل يدخّله، بيتوثّق حسابه فوراً ويتلغي الكود تلقائياً:',
              style: GoogleFonts.cairo(fontSize: 12.5, color: p.inkSecondary, height: 1.55),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: p.goldSoft,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: p.goldBorder),
              ),
              child: Text(
                invite.code,
                textAlign: TextAlign.center,
                style: GoogleFonts.cairo(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: p.ink,
                  letterSpacing: 2.2,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: invite.code));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('تم نسخ كود التزكية (${invite.code})', style: GoogleFonts.cairo())),
              );
            },
            icon: Icon(Icons.copy_rounded, size: 17, color: p.accent),
            label: Text('نسخ الكود', style: GoogleFonts.cairo(color: p.accent, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              SharePlus.instance.share(
                ShareParams(
                  text: ConfessionService.buildPeerPriestVouchShareText(
                    issuerName: priest.fullDisplayName,
                    inviteCode: invite.code,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.share_rounded, size: 17),
            label: Text('إرسال لقدسه على واتساب', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showCodesExplainerSheet() {
    final p = context.palette;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
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
              'كيف يعمل نظام الأكواد ببساطة؟',
              style: GoogleFonts.amiri(fontSize: 23, fontWeight: FontWeight.bold, color: p.ink),
            ),
            const SizedBox(height: 12),
            _explainerRow(
              p,
              '١',
              'كود أولاد الاعتراف (مثال: AB-4829) — ثابت لقدسك',
              'يبعته قدسك لأولاده على جروب واتساب أو في الكنيسة. يدخلوا به على «مواعيد أبونا» فوراً من أول يوم، ولا يظهر حساب قدسك لأي غريب.',
            ),
            const SizedBox(height: 10),
            _explainerRow(
              p,
              '٢',
              'كود تزكية أب كاهن زميل (مثال: KN-7391) — لمرة واحدة',
              'لو أب كاهن موثّق عايز يوثّق كاهن زميل عشان يظهر في الدليل العام، يضغط «إصدار كود تزكية» فيطلع كود جديد لمرة واحدة بس ويتلغي فور الاستخدام.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _explainerRow(AppPalette p, String num, String title, String body) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: p.surfaceSubtle,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: p.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(color: p.gold, shape: BoxShape.circle),
            child: Center(
              child: Text(
                num,
                style: GoogleFonts.cairo(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF19130A),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.cairo(fontSize: 12.5, fontWeight: FontWeight.bold, color: p.ink),
                ),
                const SizedBox(height: 2),
                Text(
                  body,
                  style: GoogleFonts.cairo(fontSize: 11.8, color: p.inkSecondary, height: 1.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _openPublishSessionSheet(PriestProfile priest) {
    final p = context.palette;
    DateTime pickedDate = DateTime.now().add(const Duration(days: 1));
    TimeOfDay pickedTime = const TimeOfDay(hour: 17, minute: 0);
    bool unlimited = true;
    final capCtrl = TextEditingController(text: '15');
    final locationCtrl = TextEditingController();
    bool publishing = false;

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
                    'فتح تسجيل للاعترافات',
                    style: GoogleFonts.amiri(fontSize: 23, fontWeight: FontWeight.bold, color: p.ink),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'اختر اليوم وساعة البداية فقط — وقت الانتهاء يحدده قدسك في الكنيسة ولكل ابن وقته.',
                    style: GoogleFonts.cairo(fontSize: 12.5, color: p.inkSecondary, height: 1.5),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final d = await showDatePicker(
                              context: ctx,
                              initialDate: pickedDate,
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now().add(const Duration(days: 90)),
                            );
                            if (d != null) setSheet(() => pickedDate = d);
                          },
                          icon: Icon(Icons.calendar_today_rounded, size: 17, color: p.accent),
                          label: Text(
                            _formatArDate(pickedDate),
                            style: GoogleFonts.cairo(fontSize: 12.5, fontWeight: FontWeight.bold, color: p.ink),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final t = await showTimePicker(context: ctx, initialTime: pickedTime);
                            if (t != null) setSheet(() => pickedTime = t);
                          },
                          icon: Icon(Icons.schedule_rounded, size: 18, color: p.accent),
                          label: Text(
                            'من ${_formatArTime(pickedTime)}',
                            style: GoogleFonts.cairo(fontSize: 12.5, fontWeight: FontWeight.bold, color: p.ink),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
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
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'عدد الحاضرين: ${unlimited ? 'عدد مفتوح' : 'حد أقصى اختياري'}',
                                    style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.bold, color: p.ink),
                                  ),
                                  Text(
                                    unlimited
                                        ? 'مفتوح للجميع وتقدر تقفل التسجيل في أي لحظة.'
                                        : 'عند اكتمال العدد يفتح باب قائمة الانتظار تلقائياً.',
                                    style: GoogleFonts.cairo(fontSize: 11, color: p.inkMuted),
                                  ),
                                ],
                              ),
                            ),
                            Switch(
                              value: unlimited,
                              activeThumbColor: p.accent,
                              onChanged: (v) => setSheet(() => unlimited = v),
                            ),
                          ],
                        ),
                        if (!unlimited) ...[
                          const SizedBox(height: 8),
                          TextField(
                            controller: capCtrl,
                            keyboardType: TextInputType.number,
                            style: GoogleFonts.cairo(color: p.ink, fontSize: 14),
                            decoration: const InputDecoration(
                              hintText: 'الحد الأقصى لليوم (مثلاً ١٥ أو ٢٠)',
                              prefixIcon: Icon(Icons.people_outline_rounded, size: 19),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: locationCtrl,
                    style: GoogleFonts.cairo(color: p.ink, fontSize: 13.5),
                    decoration: const InputDecoration(
                      hintText: 'مكان الاستقبال أو ملاحظة (اختياري — مثلاً: مكتب الكنيسة)',
                      prefixIcon: Icon(Icons.place_outlined, size: 19),
                    ),
                  ),
                  const SizedBox(height: 18),
                  ElevatedButton.icon(
                    onPressed: publishing
                        ? null
                        : () async {
                            setSheet(() => publishing = true);
                            final maxCap = unlimited ? null : int.tryParse(capCtrl.text.trim());
                            final (ok, msg) = await _service.publishConfessionSession(
                              priest: priest,
                              date: pickedDate,
                              dayLabelAr: _formatArDate(pickedDate),
                              startTimeAr: _formatArTime(pickedTime),
                              maxAttendees: maxCap,
                              locationNote: locationCtrl.text.trim(),
                            );
                            if (!ctx.mounted) return;
                            setSheet(() => publishing = false);
                            if (ok) Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(msg, style: GoogleFonts.cairo())),
                            );
                          },
                    icon: publishing
                        ? SizedBox(
                            width: 17,
                            height: 17,
                            child: CircularProgressIndicator(strokeWidth: 2, color: p.onAccent),
                          )
                        : const Icon(Icons.campaign_outlined, size: 19),
                    label: Text(
                      'نشر الموعد الآن',
                      style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 14.5),
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

  void _openNotificationsSheet(List<PriestNotificationItem> items) {
    final p = context.palette;
    _service.markAllNotificationsRead();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(ctx).size.height * 0.7,
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 22),
        decoration: BoxDecoration(
          color: p.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(top: BorderSide(color: p.border)),
        ),
        child: Column(
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
              'إشعارات الحضور لقدسك',
              style: GoogleFonts.amiri(fontSize: 22, fontWeight: FontWeight.bold, color: p.ink),
            ),
            Text(
              'تظهر الأسماء هنا داخل حساب قدسك فقط، بينما إشعار شاشة القفل عام لحفظ الخصوصية.',
              style: GoogleFonts.cairo(fontSize: 11.5, color: p.inkMuted, height: 1.45),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: items.isEmpty
                  ? Center(
                      child: Text(
                        'لا توجد إشعارات حضور جديدة حالياً.',
                        style: GoogleFonts.cairo(color: p.inkMuted),
                      ),
                    )
                  : ListView.separated(
                      itemCount: items.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (_, idx) {
                        final n = items[idx];
                        final isCancel = n.type == 'cancelled';
                        return Container(
                          padding: const EdgeInsets.all(13),
                          decoration: BoxDecoration(
                            color: n.read ? p.surfaceSubtle : p.goldSoft,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: n.read ? p.border : p.goldBorder),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                isCancel ? Icons.person_remove_outlined : Icons.how_to_reg_rounded,
                                size: 20,
                                color: isCancel ? p.danger : p.sage,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  n.indoorDetailedMessage,
                                  style: GoogleFonts.cairo(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: p.ink,
                                    height: 1.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
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

    if (_service.currentUid == null) {
      return Scaffold(
        backgroundColor: p.canvas,
        appBar: AppBar(
          backgroundColor: p.canvas,
          foregroundColor: p.ink,
          elevation: 0,
          automaticallyImplyLeading: !widget.embeddedInShell,
          title: Text(
            'خدمة الاعترافات والأكواد',
            style: GoogleFonts.amiri(fontWeight: FontWeight.bold, fontSize: 23, color: p.ink),
          ),
          actions: [
            IconButton(
              tooltip: 'شرح نظام الأكواد',
              icon: Icon(Icons.help_outline_rounded, color: p.gold),
              onPressed: _showCodesExplainerSheet,
            ),
          ],
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 440),
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: p.surface,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: p.goldBorder),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CopticCross(size: 40, color: p.gold),
                  const SizedBox(height: 14),
                  Text(
                    'تفعيل مواعيد الاعتراف السحابية',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.amiri(fontSize: 25, fontWeight: FontWeight.bold, color: p.ink),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'أنت تتصفح حالياً كزائر. بتسجيل الدخول بحساب قدسك، سيُفعّل كود أولاد الاعتراف الخاص بك فوراً وتستقبل تسجيلات حضور أبنائك لحظة بلحظة.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.cairo(fontSize: 13, color: p.inkSecondary, height: 1.6),
                  ),
                  const SizedBox(height: 18),
                  ElevatedButton.icon(
                    onPressed: () => Navigator.push(context, luxeRoute(const AuthView())),
                    icon: const Icon(Icons.login_rounded, size: 19),
                    label: Text(
                      'تسجيل الدخول كأب كاهن',
                      style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return StreamBuilder<PriestProfile?>(
      stream: _service.watchMyPriestProfile(),
      builder: (context, profSnap) {
        final profile = profSnap.data;
        if (profSnap.connectionState != ConnectionState.waiting) {
          _prefillForm(profile);
        }

        final isApproved = profile?.isVerifiedPublic ?? false;
        final isNeedsInfo = profile?.verificationStatus == PriestVerificationStatus.needsInfo;

        return Scaffold(
          backgroundColor: p.canvas,
          appBar: AppBar(
            backgroundColor: p.canvas,
            foregroundColor: p.ink,
            elevation: 0,
            automaticallyImplyLeading: !widget.embeddedInShell,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'الاعترافات والأكواد',
                  style: GoogleFonts.amiri(fontWeight: FontWeight.bold, fontSize: 23, color: p.ink, height: 1.15),
                ),
                if (profile != null)
                  Text(
                    '${profile.fullDisplayName} • ${profile.church}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.cairo(fontSize: 11, color: p.inkMuted),
                  ),
              ],
            ),
            actions: [
              IconButton(
                tooltip: 'كيف يعمل نظام الأكواد؟',
                icon: Icon(Icons.help_outline_rounded, color: p.gold),
                onPressed: _showCodesExplainerSheet,
              ),
              if (profile != null)
                StreamBuilder<List<PriestNotificationItem>>(
                  stream: _service.watchPriestNotifications(),
                  builder: (_, nSnap) {
                    final list = nSnap.data ?? [];
                    final unreadCount = list.where((x) => !x.read).length;
                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        IconButton(
                          tooltip: 'إشعارات الحضور',
                          icon: Icon(Icons.notifications_outlined, color: p.ink),
                          onPressed: () => _openNotificationsSheet(list),
                        ),
                        if (unreadCount > 0)
                          Positioned(
                            top: 8,
                            left: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                              decoration: BoxDecoration(
                                color: p.crimson,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '$unreadCount',
                                style: GoogleFonts.cairo(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              const SizedBox(width: 4),
            ],
          ),
          body: profSnap.connectionState == ConnectionState.waiting
              ? Center(child: CircularProgressIndicator(color: p.gold, strokeWidth: 2))
              : Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 740),
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
                      children: [
                        // 1. Setup/Edit Priest Profile Card (shown first time or when editing)
                        if (profile == null || _editingProfile || isNeedsInfo) ...[
                          _buildProfileFormCard(p, profile, isNeedsInfo),
                          const SizedBox(height: 16),
                        ],

                        if (profile != null) ...[
                          // 2. CARD A: FIXED PRIVATE CODE FOR CONFESSION CHILDREN (WORKS IMMEDIATELY!)
                          _buildPrivateCodeCard(p, profile),
                          const SizedBox(height: 16),

                          // 3. CARD B: CONFESSION SESSIONS PUBLISHER & LIVE ATTENDEE LISTS
                          _buildConfessionsManager(p, profile),
                          const SizedBox(height: 18),

                          // 4. CARD C: PUBLIC DIRECTORY VERIFICATION & PEER-PRIEST VOUCHING
                          _buildPeerVouchAndVerificationCard(p, profile, isApproved),
                        ],
                      ],
                    ),
                  ),
                ),
        );
      },
    );
  }

  Widget _buildPrivateCodeCard(AppPalette p, PriestProfile profile) {
    final code = profile.privateCode.isNotEmpty ? profile.privateCode : _localCode;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: p.goldSoft,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: p.goldBorder, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: p.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: p.goldBorder),
                ),
                child: Icon(Icons.vpn_key_rounded, color: p.gold, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'كود أولاد اعتراف قدسك (ثابت ويعمل فوراً)',
                      style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.bold, color: p.ink),
                    ),
                    Text(
                      'ابعته لأولادك على جروب واتساب — يدخلوا به على مواعيد قدسك مباشرة',
                      style: GoogleFonts.cairo(fontSize: 11, color: p.inkSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: p.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: p.goldBorder),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    code.isNotEmpty ? code : 'جاري التوليد...',
                    style: GoogleFonts.cairo(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: p.ink,
                      letterSpacing: 2.0,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'نسخ الكود',
                  icon: Icon(Icons.copy_rounded, color: p.accent, size: 20),
                  onPressed: code.isEmpty
                      ? null
                      : () {
                          Clipboard.setData(ClipboardData(text: code));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('تم نسخ كود قدسك: $code', style: GoogleFonts.cairo())),
                          );
                        },
                ),
                ElevatedButton.icon(
                  onPressed: code.isEmpty
                      ? null
                      : () {
                          HapticFeedback.lightImpact();
                          SharePlus.instance.share(
                            ShareParams(
                              text: ConfessionService.buildConfessionChildrenShareText(
                                priestFullName: profile.fullDisplayName,
                                church: profile.church,
                                privateCode: code,
                              ),
                            ),
                          );
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: p.gold,
                    foregroundColor: const Color(0xFF19130A),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
                  ),
                  icon: const Icon(Icons.share_rounded, size: 17),
                  label: Text('مشاركة', style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfessionsManager(AppPalette p, PriestProfile profile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'مواعيد الاعتراف وقائمة الحضور',
                style: GoogleFonts.amiri(fontSize: 22, fontWeight: FontWeight.bold, color: p.ink),
              ),
            ),
            ElevatedButton.icon(
              onPressed: () => _openPublishSessionSheet(profile),
              style: ElevatedButton.styleFrom(
                backgroundColor: p.accent,
                foregroundColor: p.onAccent,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.add_circle_outline_rounded, size: 18),
              label: Text('فتح موعد جديد', style: GoogleFonts.cairo(fontSize: 12.5, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        const SizedBox(height: 10),
        StreamBuilder<List<ConfessionSession>>(
          stream: _service.watchPriestSessions(profile.priestUid),
          builder: (context, snap) {
            final sessions = snap.data ?? [];
            if (sessions.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: p.surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: p.border),
                ),
                child: Column(
                  children: [
                    Icon(Icons.event_available_outlined, size: 34, color: p.inkMuted),
                    const SizedBox(height: 8),
                    Text(
                      'لم ينشر قدسك مواعيد اعتراف بعد',
                      style: GoogleFonts.amiri(fontSize: 19, fontWeight: FontWeight.bold, color: p.ink),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'اضغط «فتح موعد جديد» بالأعلى واختر اليوم وساعة البداية ليظهر فوراً لأبنائك المرتبطين بكود قدسك.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.cairo(fontSize: 12, color: p.inkMuted, height: 1.5),
                    ),
                  ],
                ),
              );
            }
            return Column(
              children: sessions.map((s) => _buildPriestSessionCard(p, s)).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildPriestSessionCard(AppPalette p, ConfessionSession s) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: s.isOpen ? p.goldBorder : p.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.event_note_rounded, size: 19, color: p.gold),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${s.dayLabelAr} • ابتداءً من ${s.startTimeAr}',
                      style: GoogleFonts.cairo(fontSize: 13.5, fontWeight: FontWeight.bold, color: p.ink),
                    ),
                    Text(
                      s.isUnlimited
                          ? 'عدد مفتوح • المسجّلون: ${s.confirmedCount}'
                          : 'الحد الأقصى: ${s.maxAttendees} • المسجّلون: ${s.confirmedCount}${s.waitlistCount > 0 ? ' (انتظار: ${s.waitlistCount})' : ''}',
                      style: GoogleFonts.cairo(fontSize: 11.5, color: p.inkSecondary),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'حذف الموعد',
                icon: Icon(Icons.delete_outline_rounded, size: 19, color: p.inkMuted),
                onPressed: () => _service.deleteSession(s.id),
              ),
            ],
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () => _service.toggleSessionOpen(s.id, !s.isOpen),
            style: OutlinedButton.styleFrom(
              foregroundColor: s.isOpen ? p.danger : p.sage,
              side: BorderSide(color: s.isOpen ? p.danger : p.sage),
            ),
            icon: Icon(s.isOpen ? Icons.lock_outline_rounded : Icons.lock_open_rounded, size: 17),
            label: Text(
              s.isOpen ? 'إيقاف تسجيل حضور جديد' : 'إعادة فتح التسجيل',
              style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 10),
          StreamBuilder<List<ConfessionAttendee>>(
            stream: _service.watchSessionAttendeesForPriest(s.id),
            builder: (_, aSnap) {
              final attendees = aSnap.data ?? [];
              if (attendees.isEmpty) {
                return Text(
                  'لا يوجد حضور مسجّل لهذا اليوم بعد.',
                  style: GoogleFonts.cairo(fontSize: 11.5, color: p.inkMuted),
                );
              }
              return Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: p.surfaceSubtle,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: p.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'قائمة الحضور (${attendees.length}):',
                      style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.bold, color: p.accent),
                    ),
                    const SizedBox(height: 6),
                    ...List.generate(attendees.length, (i) {
                      final att = attendees[i];
                      final isWait = att.status == 'waitlist';
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: Row(
                          children: [
                            Text(
                              '${i + 1}.',
                              style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.bold, color: p.inkMuted),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                att.attendeeName,
                                style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.w600, color: p.ink),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: (isWait ? p.gold : p.sage).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                isWait ? 'قائمة انتظار' : 'حاضر',
                                style: GoogleFonts.cairo(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.bold,
                                  color: isWait ? p.gold : p.sage,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  /// Card C: Public Directory Trust & Peer-Priest Single-Use Vouch Codes (`KN-XXXX`)
  Widget _buildPeerVouchAndVerificationCard(
    AppPalette p,
    PriestProfile profile,
    bool isApproved,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isApproved ? p.sage.withValues(alpha: 0.45) : p.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                isApproved ? Icons.verified_rounded : Icons.verified_user_outlined,
                color: isApproved ? p.sage : p.gold,
                size: 22,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isApproved
                      ? 'حساب قدسك موثّق في الدليل العام ✓'
                      : 'التوثيق والظهور في الدليل العام (اختياري)',
                  style: GoogleFonts.amiri(fontSize: 19, fontWeight: FontWeight.bold, color: p.ink),
                ),
              ),
              TextButton(
                onPressed: () => setState(() => _editingProfile = !_editingProfile),
                child: Text(
                  'تعديل بياناتي',
                  style: GoogleFonts.cairo(fontSize: 11.5, fontWeight: FontWeight.bold, color: p.accent),
                ),
              ),
            ],
          ),
          if (isApproved) ...[
            if (profile.vouchedByName.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  'مُوثّق بتزكية: ${profile.vouchedByName}',
                  style: GoogleFonts.cairo(fontSize: 11.5, color: p.sage, fontWeight: FontWeight.w600),
                ),
              ),
            Text(
              'يمكن لقدسك تزكية الآباء الكهنة الزملاء لينضموا للدليل العام فوراً. كل ضغطة تُصدر كوداً جديداً مختلفاً يعمل لمرة واحدة فقط (٧ أيام).',
              style: GoogleFonts.cairo(fontSize: 12, color: p.inkSecondary, height: 1.5),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _issuingInvite ? null : () => _issuePeerInvite(profile),
              style: ElevatedButton.styleFrom(
                backgroundColor: p.sage,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
              ),
              icon: _issuingInvite
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.person_add_alt_1_rounded, size: 19),
              label: Text(
                'إصدار كود تزكية جديد لأب كاهن زميل',
                style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
            const SizedBox(height: 12),
            StreamBuilder<List<PriestVouchInvite>>(
              stream: _service.watchMyIssuedInvites(),
              builder: (_, snap) {
                final invites = snap.data ?? [];
                if (invites.isEmpty) return const SizedBox.shrink();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'أكواد التزكية التي أصدرها قدسك (${invites.length}):',
                      style: GoogleFonts.cairo(fontSize: 11.5, fontWeight: FontWeight.bold, color: p.inkMuted),
                    ),
                    const SizedBox(height: 6),
                    ...invites.take(5).map((inv) => Container(
                          margin: const EdgeInsets.only(bottom: 6),
                          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
                          decoration: BoxDecoration(
                            color: p.surfaceSubtle,
                            borderRadius: BorderRadius.circular(11),
                            border: Border.all(color: p.border),
                          ),
                          child: Row(
                            children: [
                              Text(
                                inv.code,
                                style: GoogleFonts.cairo(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: p.ink,
                                  letterSpacing: 1.1,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  inv.used
                                      ? 'استخدمه: ${inv.usedByName.isNotEmpty ? inv.usedByName : 'أب كاهن'}'
                                      : (inv.isExpired ? 'منتهي الصلاحية' : 'متاح للاستخدام مرة واحدة'),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.cairo(
                                    fontSize: 11,
                                    color: inv.used ? p.sage : (inv.isExpired ? p.danger : p.inkSecondary),
                                  ),
                                ),
                              ),
                              if (!inv.used && !inv.isExpired)
                                IconButton(
                                  visualDensity: VisualDensity.compact,
                                  icon: Icon(Icons.share_rounded, size: 17, color: p.accent),
                                  onPressed: () => SharePlus.instance.share(
                                    ShareParams(
                                      text: ConfessionService.buildPeerPriestVouchShareText(
                                        issuerName: profile.fullDisplayName,
                                        inviteCode: inv.code,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        )),
                  ],
                );
              },
            ),
          ] else ...[
            Text(
              'كود قدسك الخاص (${profile.privateCode}) شغال حالياً لأولادك فوراً. أما للظهور في الدليل العام لكل المستخدمين، أدخل كود تزكية لمرة واحدة من أي أب كاهن موثّق:',
              style: GoogleFonts.cairo(fontSize: 12, color: p.inkSecondary, height: 1.55),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _redeemVouchCtrl,
                    textCapitalization: TextCapitalization.characters,
                    style: GoogleFonts.cairo(color: p.ink, fontSize: 14, fontWeight: FontWeight.bold),
                    decoration: const InputDecoration(
                      hintText: 'كود التزكية (مثال: KN-7391)',
                      prefixIcon: Icon(Icons.verified_outlined, size: 19),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _redeemingVouch ? null : _redeemVouchCode,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: p.gold,
                    foregroundColor: const Color(0xFF19130A),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
                  ),
                  child: _redeemingVouch
                      ? const SizedBox(
                          width: 17,
                          height: 17,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF19130A)),
                        )
                      : Text('توثيق', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProfileFormCard(AppPalette p, PriestProfile? existing, bool isNeedsInfo) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isNeedsInfo ? p.gold : p.goldBorder, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              CopticCross(size: 20, color: p.gold),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      existing == null
                          ? 'تجهيز بطاقة قدسك وكود الاعتراف'
                          : (isNeedsInfo ? 'مطلوب استكمال بيانات قدسك' : 'تعديل بيانات قدسك'),
                      style: GoogleFonts.amiri(fontSize: 22, fontWeight: FontWeight.bold, color: p.ink),
                    ),
                    Text(
                      'بمجرد الحفظ يتجهّز كود أولاد الاعتراف الخاص بقدسك فوراً.',
                      style: GoogleFonts.cairo(fontSize: 11.5, color: p.inkSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (isNeedsInfo && (existing?.adminFeedback.isNotEmpty ?? false)) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(11),
              decoration: BoxDecoration(
                color: p.goldSoft,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: p.goldBorder),
              ),
              child: Text(
                'ملاحظة المراجعة: ${existing!.adminFeedback}',
                style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.bold, color: p.ink),
              ),
            ),
          ],
          const SizedBox(height: 14),
          Row(
            children: ['القس', 'القمص'].map((prefix) {
              final sel = _titlePrefix == prefix;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(left: prefix == 'القس' ? 8 : 0),
                  child: ChoiceChip(
                    showCheckmark: false,
                    selected: sel,
                    selectedColor: p.gold,
                    backgroundColor: p.surfaceSubtle,
                    label: Center(
                      child: Text(
                        prefix,
                        style: GoogleFonts.cairo(
                          fontWeight: FontWeight.bold,
                          color: sel ? const Color(0xFF19130A) : p.ink,
                        ),
                      ),
                    ),
                    onSelected: (_) => setState(() => _titlePrefix = prefix),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 11),
          TextField(
            controller: _nameCtrl,
            style: GoogleFonts.cairo(color: p.ink, fontSize: 14),
            decoration: const InputDecoration(
              hintText: 'اسم قدسك الكامل (مثال: بولس جرجس)',
              prefixIcon: Icon(Icons.person_outline_rounded, size: 20),
            ),
          ),
          const SizedBox(height: 11),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: p.surfaceSubtle,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: p.border),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                dropdownColor: p.surface,
                value: _selectedDiocese,
                items: CopticDiocesesCatalog.dioceses
                    .map((d) => DropdownMenuItem(
                          value: d,
                          child: Text(
                            d,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.cairo(fontSize: 13, color: p.ink),
                          ),
                        ))
                    .toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _selectedDiocese = v);
                },
              ),
            ),
          ),
          const SizedBox(height: 11),
          TextField(
            controller: _churchCtrl,
            style: GoogleFonts.cairo(color: p.ink, fontSize: 14),
            decoration: const InputDecoration(
              hintText: 'اسم الكنيسة والمنطقة (مثال: كنيسة السيدة العذراء بمسرة)',
              prefixIcon: Icon(Icons.church_outlined, size: 20),
            ),
          ),
          const SizedBox(height: 11),
          TextField(
            controller: _phoneCtrl,
            keyboardType: TextInputType.phone,
            style: GoogleFonts.cairo(color: p.ink, fontSize: 14),
            decoration: const InputDecoration(
              hintText: 'هاتف للتحقق مع الإيبارشية (اختياري — غير معلن للشعب)',
              prefixIcon: Icon(Icons.phone_outlined, size: 20),
            ),
          ),
          const SizedBox(height: 14),
          ElevatedButton.icon(
            onPressed: _submittingForm ? null : _submitProfile,
            style: ElevatedButton.styleFrom(
              backgroundColor: p.gold,
              foregroundColor: const Color(0xFF19130A),
            ),
            icon: _submittingForm
                ? const SizedBox(
                    width: 17,
                    height: 17,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF19130A)),
                  )
                : const Icon(Icons.check_circle_outline_rounded, size: 19),
            label: Text(
              existing == null ? 'حفظ وتجهيز كود أولاد الاعتراف فوراً' : 'حفظ التعديلات',
              style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
