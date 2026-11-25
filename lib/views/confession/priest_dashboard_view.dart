import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/services/confession_service.dart';
import '../../core/services/storage_service.dart';
import '../../core/theme/app_palette.dart';
import '../../core/widgets/coptic_cross.dart';
import '../../core/widgets/diocese_church_picker.dart';
import '../../core/widgets/luxe_widgets.dart';
import '../../core/widgets/priest_qr_poster_sheet.dart';
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
  final TextEditingController _redeemVouchCtrl = TextEditingController();

  String _titlePrefix = 'القس';
  String _selectedDiocese = CopticDiocesesCatalog.dioceses.first;
  String _selectedChurch =
      CopticDiocesesCatalog.churchesFor(CopticDiocesesCatalog.dioceses.first).first;
  bool _submittingForm = false;
  bool _redeemingVouch = false;
  bool _issuingInvite = false;
  bool _editingProfile = false;
  bool _prefilledFromProfile = false;
  String _localCode = '';
  String _confessorsQuery = '';
  String _confessorsFilter = 'all'; // 'all' | 'due' | 'done'

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
      if (CopticDiocesesCatalog.dioceses.contains(profile.diocese)) {
        _selectedDiocese = profile.diocese;
      }
      _selectedChurch = profile.church.isNotEmpty
          ? profile.church
          : CopticDiocesesCatalog.churchesFor(_selectedDiocese).first;
    } else {
      _titlePrefix = _storage.getPriestTitlePrefix();
      if (_storage.hasCustomUserName()) _nameCtrl.text = _storage.getUserName();
      final d = _storage.getPriestDiocese();
      if (CopticDiocesesCatalog.dioceses.contains(d)) _selectedDiocese = d;
      final savedC = _storage.getPriestChurch();
      _selectedChurch = savedC.isNotEmpty
          ? savedC
          : CopticDiocesesCatalog.churchesFor(_selectedDiocese).first;
    }
  }

  Future<void> _submitProfile() async {
    HapticFeedback.lightImpact();
    setState(() => _submittingForm = true);
    final (ok, msg) = await _service.submitOrUpdatePriestVerification(
      titlePrefix: _titlePrefix,
      displayName: _nameCtrl.text,
      diocese: _selectedDiocese,
      church: _selectedChurch,
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

  Future<void> _issuePeerInvite(PriestProfile priest, {int maxUses = 1}) async {
    HapticFeedback.mediumImpact();
    setState(() => _issuingInvite = true);
    final (invite, msg) = await _service.generatePeerPriestInviteCode(
      priest,
      maxUses: maxUses,
    );
    if (!mounted) return;
    setState(() => _issuingInvite = false);

    if (invite == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg, style: GoogleFonts.cairo())),
      );
      return;
    }

    final p = context.palette;
    final isGroup = invite.maxUses > 1;
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
                isGroup
                    ? 'كود تزكية جماعي (${invite.maxUses} آباء كهنة)'
                    : 'كود تزكية جديد لأب كاهن زميل',
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
              isGroup
                  ? 'الكود ده قدسك تقدر تبعته في جروب آباء الكنيسة أو الإيبارشية — شغال لغاية ${invite.maxUses} آباء كهنة (لمدة ٧ أيام)، وكل أب كاهن يدخّله بيتوثّق حسابه علطول:'
                  : 'الكود ده جديد ومخصّص لأب كاهن واحد (لمدة ٧ أيام). أول ما قدسه يدخّله بيتوثّق حسابه علطول ويتلغي الكود تلقائياً:',
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
                SnackBar(content: Text('اتنسخ كود التزكية (${invite.code})', style: GoogleFonts.cairo())),
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
                    maxUses: invite.maxUses,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.share_rounded, size: 17),
            label: Text(
              isGroup ? 'ابعته لجروب الآباء' : 'ابعته لقدسه على واتساب',
              style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _openGroupPeerInvitePicker(PriestProfile priest) {
    final p = context.palette;
    int selectedCount = 5;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Container(
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
                  decoration: BoxDecoration(color: p.border, borderRadius: BorderRadius.circular(4)),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'دعوة أكتر من أب كاهن بكود واحد',
                style: GoogleFonts.amiri(fontSize: 22, fontWeight: FontWeight.bold, color: p.ink),
              ),
              const SizedBox(height: 4),
              Text(
                'قدسك تختار عدد الآباء الكهنة اللي هيستخدموا الكود (مثلاً آباء كنيستك أو الإيبارشية)، وتبعت رسالة واحدة على واتساب للكل:',
                style: GoogleFonts.cairo(fontSize: 12.5, color: p.inkSecondary, height: 1.5),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [3, 5, 10, 15].map((cnt) {
                  final sel = selectedCount == cnt;
                  return ChoiceChip(
                    selected: sel,
                    selectedColor: p.gold,
                    backgroundColor: p.surfaceSubtle,
                    label: Text(
                      '$cnt آباء كهنة',
                      style: GoogleFonts.cairo(
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                        color: sel ? const Color(0xFF19130A) : p.ink,
                      ),
                    ),
                    onSelected: (_) => setSheet(() => selectedCount = cnt),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  _issuePeerInvite(priest, maxUses: selectedCount);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: p.sage,
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.groups_rounded, size: 20),
                label: Text(
                  'طلّع كود جماعي لـ $selectedCount آباء كهنة',
                  style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 13.5),
                ),
              ),
            ],
          ),
        ),
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
    TimeOfDay pickedTime = const TimeOfDay(hour: 16, minute: 0);
    bool hasEndTime = true;
    TimeOfDay pickedEndTime = const TimeOfDay(hour: 18, minute: 0); // لغاية الساعة ٦:٠٠ مساءً
    bool unlimited = true;
    final capCtrl = TextEditingController(text: '15');
    final locationCtrl = TextEditingController();
    bool publishing = false;

    const endPresets = <(String, TimeOfDay)>[
      ('٦:٠٠ م', TimeOfDay(hour: 18, minute: 0)),
      ('٧:٠٠ م', TimeOfDay(hour: 19, minute: 0)),
      ('٨:٠٠ م', TimeOfDay(hour: 20, minute: 0)),
      ('٩:٠٠ م', TimeOfDay(hour: 21, minute: 0)),
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
                    'فتح ميعاد اعترافات جديد',
                    style: GoogleFonts.amiri(fontSize: 23, fontWeight: FontWeight.bold, color: p.ink),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'قدسك تختار اليوم وساعة البداية، وتقدر تحدد «لغاية الساعة كام» (زي لغاية ٦ مساءً) أو تخليه مفتوح.',
                    style: GoogleFonts.cairo(fontSize: 12.5, color: p.inkSecondary, height: 1.5),
                  ),
                  const SizedBox(height: 14),
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
                            style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.bold, color: p.ink),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final t = await showTimePicker(context: ctx, initialTime: pickedTime);
                            if (t != null) setSheet(() => pickedTime = t);
                          },
                          icon: Icon(Icons.schedule_rounded, size: 17, color: p.accent),
                          label: Text(
                            'من ${_formatArTime(pickedTime)}',
                            style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.bold, color: p.ink),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // End-Time Toggle & Quick Presets (e.g. لغاية 6:00 مساءً)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: p.surfaceSubtle,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: hasEndTime ? p.goldBorder : p.border),
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
                                    hasEndTime
                                        ? 'لغاية الساعة: ${_formatArTime(pickedEndTime)}'
                                        : 'وقت الانتهاء: مفتوح (بدون ساعة محددة)',
                                    style: GoogleFonts.cairo(fontSize: 12.5, fontWeight: FontWeight.bold, color: p.ink),
                                  ),
                                  Text(
                                    hasEndTime
                                        ? 'هيظهر لأولادك «من ${_formatArTime(pickedTime)} لغاية ${_formatArTime(pickedEndTime)}»'
                                        : 'هيظهر لأولادك «ابتداءً من ${_formatArTime(pickedTime)}»',
                                    style: GoogleFonts.cairo(fontSize: 11, color: p.inkMuted),
                                  ),
                                ],
                              ),
                            ),
                            Switch(
                              value: hasEndTime,
                              activeThumbColor: p.gold,
                              onChanged: (v) => setSheet(() => hasEndTime = v),
                            ),
                          ],
                        ),
                        if (hasEndTime) ...[
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              ...endPresets.map((preset) {
                                final isSel = pickedEndTime.hour == preset.$2.hour &&
                                    pickedEndTime.minute == preset.$2.minute;
                                return ChoiceChip(
                                  visualDensity: VisualDensity.compact,
                                  selected: isSel,
                                  selectedColor: p.gold,
                                  backgroundColor: p.surface,
                                  label: Text(
                                    'لغاية ${preset.$1}',
                                    style: GoogleFonts.cairo(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.bold,
                                      color: isSel ? const Color(0xFF19130A) : p.ink,
                                    ),
                                  ),
                                  onSelected: (_) => setSheet(() => pickedEndTime = preset.$2),
                                );
                              }),
                              ActionChip(
                                visualDensity: VisualDensity.compact,
                                backgroundColor: p.surface,
                                side: BorderSide(color: p.goldBorder),
                                avatar: Icon(Icons.access_time_rounded, size: 15, color: p.accent),
                                label: Text(
                                  'ساعة تانية',
                                  style: GoogleFonts.cairo(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.bold,
                                    color: p.accent,
                                  ),
                                ),
                                onPressed: () async {
                                  final t = await showTimePicker(context: ctx, initialTime: pickedEndTime);
                                  if (t != null) setSheet(() => pickedEndTime = t);
                                },
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
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
                                        ? 'مفتوح للجميع وقدسك تقدر تقفل التسجيل في أي لحظة.'
                                        : 'لما العدد يكمل بيتفتح باب قائمة الانتظار لوحده.',
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
                              endTimeAr: hasEndTime ? _formatArTime(pickedEndTime) : '',
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
                      'نشر الميعاد دلوقتي',
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

                          // 3b. CARD B2: ABOUNA'S CONFESSORS TABLE («جدول معترفين قدس أبونا»)
                          _buildConfessorsTableCard(p),
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
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: code.isEmpty
                ? null
                : () => PriestQrPosterSheet.show(
                      context,
                      priestFullName: profile.fullDisplayName,
                      church: profile.church,
                      diocese: profile.diocese,
                      privateCode: code,
                    ),
            style: OutlinedButton.styleFrom(
              backgroundColor: p.surface,
              foregroundColor: p.ink,
              side: BorderSide(color: p.goldBorder),
              padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: Icon(Icons.qr_code_2_rounded, size: 19, color: p.gold),
            label: Text(
              'كارت QR Code جاهز للطباعة على باب المكتب',
              style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.bold),
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

  void _openMarkConfessedSheet({
    ConfessionSession? session,
    ConfessionAttendee? attendee,
    PriestConfessorRecord? existingRecord,
  }) {
    final p = context.palette;
    final isManualNew = session == null && existingRecord == null;
    final nameCtrl = TextEditingController(
      text: attendee?.attendeeName ?? existingRecord?.fullName ?? '',
    );
    final noteCtrl = TextEditingController(
      text: attendee?.followUpNote ?? existingRecord?.followUpNote ?? '',
    );
    int selectedDays = (attendee?.nextIntervalDays ?? existingRecord?.nextIntervalDays ?? 30);
    if (selectedDays < 0) selectedDays = 30;
    bool saving = false;

    const intervals = <(int, String)>[
      (14, 'أسبوعين (١٤ يوم)'),
      (21, '٣ أسابيع (٢١ يوم)'),
      (30, 'شهر (٣٠ يوم)'),
      (40, '٤٠ يوم'),
      (60, 'شهرين (٦٠ يوم)'),
      (0, 'بدون مدة محددة'),
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
                    isManualNew
                        ? 'إضافة معترف جديد لجدول قدسك ✓'
                        : 'تم الاعتراف لـ «${nameCtrl.text}» ✓',
                    style: GoogleFonts.amiri(fontSize: 22, fontWeight: FontWeight.bold, color: p.ink),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'اختار المدة اللي تحب قدسك يرجع فيها يعترف تاني — هتتضاف تلقائياً في جدول المعترفين وهيتبعتله تذكير على موبايله يومها:',
                    style: GoogleFonts.cairo(fontSize: 12, color: p.inkSecondary, height: 1.5),
                  ),
                  if (isManualNew) ...[
                    const SizedBox(height: 12),
                    TextField(
                      controller: nameCtrl,
                      autofocus: true,
                      style: GoogleFonts.cairo(color: p.ink, fontSize: 14.5),
                      decoration: const InputDecoration(
                        hintText: 'اسم المعترف الثنائي (مثال: مينا جرجس)',
                        prefixIcon: Icon(Icons.person_outline_rounded, size: 20),
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Text(
                    'يجيلي تاني بعد قد إيه؟',
                    style: GoogleFonts.cairo(fontSize: 12.5, fontWeight: FontWeight.bold, color: p.ink),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 7,
                    runSpacing: 7,
                    children: intervals.map((item) {
                      final sel = selectedDays == item.$1;
                      return ChoiceChip(
                        selected: sel,
                        selectedColor: p.gold,
                        backgroundColor: p.surfaceSubtle,
                        label: Text(
                          item.$2,
                          style: GoogleFonts.cairo(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: sel ? const Color(0xFF19130A) : p.ink,
                          ),
                        ),
                        onSelected: (_) => setSheet(() => selectedDays = item.$1),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: noteCtrl,
                    style: GoogleFonts.cairo(color: p.ink, fontSize: 13.5),
                    decoration: const InputDecoration(
                      hintText: 'كلمة تشجيع أو تدريب روحي للمعترف (اختياري)',
                      prefixIcon: Icon(Icons.favorite_outline_rounded, size: 19),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: saving
                        ? null
                        : () async {
                            setSheet(() => saving = true);
                            final messenger = ScaffoldMessenger.of(context);
                            bool ok = false;
                            String msg = '';
                            if (session != null && attendee != null) {
                              final res = await _service.markAttendeeConfessed(
                                session: session,
                                attendee: attendee,
                                nextIntervalDays: selectedDays,
                                followUpNote: noteCtrl.text.trim(),
                              );
                              ok = res.$1;
                              msg = res.$2;
                            } else {
                              final res = await _service.upsertConfessorRecord(
                                fullName: nameCtrl.text,
                                nextIntervalDays: selectedDays,
                                followUpNote: noteCtrl.text.trim(),
                                existingId: existingRecord?.id,
                                attendeeUid: existingRecord?.attendeeUid ?? '',
                                prevCount: existingRecord?.confessedCount ?? 0,
                              );
                              ok = res.$1;
                              msg = res.$2;
                            }
                            if (!ctx.mounted) return;
                            setSheet(() => saving = false);
                            if (ok) Navigator.pop(ctx);
                            messenger.showSnackBar(
                              SnackBar(content: Text(msg, style: GoogleFonts.cairo())),
                            );
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: p.sage,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    icon: saving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.check_circle_rounded, size: 20),
                    label: Text(
                      'تأكيد علامة الصح وحفظ المدة ✓',
                      style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 13.5),
                    ),
                  ),
                  if (session != null && attendee != null && attendee.confessed) ...[
                    const SizedBox(height: 6),
                    TextButton(
                      onPressed: () async {
                        await _service.unmarkAttendeeConfessed(session.id, attendee.attendeeUid);
                        if (ctx.mounted) Navigator.pop(ctx);
                      },
                      child: Text(
                        'إلغاء علامة الصح',
                        style: GoogleFonts.cairo(color: p.danger, fontSize: 12),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildConfessorsTableCard(AppPalette p) {
    return StreamBuilder<List<PriestConfessorRecord>>(
      stream: _service.watchMyConfessorsTable(),
      builder: (context, snap) {
        final all = snap.data ?? [];
        final dueCount = all.where((r) => r.isDueNow).length;
        final q = _confessorsQuery.trim();
        final filtered = all.where((r) {
          if (_confessorsFilter == 'due' && !r.isDueNow) return false;
          if (_confessorsFilter == 'done' && !r.confessedInLastSession) return false;
          if (q.isNotEmpty && !r.fullName.contains(q)) return false;
          return true;
        }).toList();

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: p.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: p.goldBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(Icons.fact_check_rounded, color: p.gold, size: 22),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'جدول معترفين قدس أبونا (${all.length})',
                          style: GoogleFonts.amiri(fontSize: 21, fontWeight: FontWeight.bold, color: p.ink),
                        ),
                        Text(
                          'اللي اعترف بيظهر جمبه علامة صح ✓ مع ميعاد رجوعه الجاي',
                          style: GoogleFonts.cairo(fontSize: 11, color: p.inkMuted),
                        ),
                      ],
                    ),
                  ),
                  FilledButton.tonalIcon(
                    onPressed: () => _openMarkConfessedSheet(),
                    style: FilledButton.styleFrom(
                      backgroundColor: p.goldSoft,
                      foregroundColor: p.gold,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    icon: const Icon(Icons.person_add_alt_1_rounded, size: 16),
                    label: Text('إضافة', style: GoogleFonts.cairo(fontSize: 11.5, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // Filter Chips + Search
              Row(
                children: [
                  _tableFilterChip(p, 'الكل (${all.length})', 'all'),
                  const SizedBox(width: 6),
                  _tableFilterChip(p, 'حان ميعادهم ($dueCount)', 'due'),
                  const SizedBox(width: 6),
                  _tableFilterChip(p, 'اعترفوا ✓', 'done'),
                ],
              ),
              if (all.length >= 4) ...[
                const SizedBox(height: 8),
                TextField(
                  onChanged: (v) => setState(() => _confessorsQuery = v),
                  style: GoogleFonts.cairo(color: p.ink, fontSize: 13),
                  decoration: const InputDecoration(
                    hintText: 'ابحث باسم المعترف...',
                    isDense: true,
                    prefixIcon: Icon(Icons.search_rounded, size: 18),
                  ),
                ),
              ],
              const SizedBox(height: 10),
              if (filtered.isEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: p.surfaceSubtle,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    all.isEmpty
                        ? 'أول ما قدسك تضغط علامة الصح ✓ جنب أي معترف في قائمة الحضور (أو تضغط «إضافة» فوق)، هينزل هنا في الجدول مع تاريخ آخر اعتراف وميعاد رجوعه.'
                        : 'مفيش معترفين مطابقين للفلتر ده دلوقتي.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.cairo(fontSize: 12, color: p.inkMuted, height: 1.5),
                  ),
                )
              else
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: p.border),
                  ),
                  child: Column(
                    children: [
                      // Table Header Row
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                        decoration: BoxDecoration(
                          color: p.goldSoft,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(13)),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 4,
                              child: Text(
                                'الاسم',
                                style: GoogleFonts.cairo(fontSize: 11.5, fontWeight: FontWeight.bold, color: p.ink),
                              ),
                            ),
                            Expanded(
                              flex: 3,
                              child: Text(
                                'آخر اعتراف / الجاي',
                                style: GoogleFonts.cairo(fontSize: 11.5, fontWeight: FontWeight.bold, color: p.ink),
                              ),
                            ),
                            Text(
                              'الحالة',
                              style: GoogleFonts.cairo(fontSize: 11.5, fontWeight: FontWeight.bold, color: p.ink),
                            ),
                          ],
                        ),
                      ),
                      ...List.generate(filtered.length, (i) {
                        final rec = filtered[i];
                        final due = rec.isDueNow;
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
                          decoration: BoxDecoration(
                            color: i.isOdd ? p.surfaceSubtle.withValues(alpha: 0.55) : p.surface,
                            border: Border(top: BorderSide(color: p.border.withValues(alpha: 0.7))),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 4,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      rec.fullName,
                                      style: GoogleFonts.cairo(
                                        fontSize: 12.8,
                                        fontWeight: FontWeight.bold,
                                        color: p.ink,
                                      ),
                                    ),
                                    if (rec.followUpNote.isNotEmpty)
                                      Text(
                                        rec.followUpNote,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.cairo(fontSize: 10.5, color: p.inkMuted),
                                      ),
                                  ],
                                ),
                              ),
                              Expanded(
                                flex: 3,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (rec.lastConfessionDateIso.isNotEmpty)
                                      Text(
                                        'آخر: ${PriestConfessorRecord.formatArabicDateShort(rec.lastConfessionDateIso)}',
                                        style: GoogleFonts.cairo(fontSize: 11, color: p.inkSecondary),
                                      ),
                                    if (rec.nextConfessionDateIso.isNotEmpty)
                                      Text(
                                        'الجاي: ${PriestConfessorRecord.formatArabicDateShort(rec.nextConfessionDateIso)}',
                                        style: GoogleFonts.cairo(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: due ? p.danger : p.accent,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  InkWell(
                                    borderRadius: BorderRadius.circular(10),
                                    onTap: () => _openMarkConfessedSheet(existingRecord: rec),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: (due ? p.gold : p.sage).withValues(alpha: 0.16),
                                        borderRadius: BorderRadius.circular(9),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            due ? Icons.schedule_rounded : Icons.check_circle_rounded,
                                            size: 14,
                                            color: due ? p.gold : p.sage,
                                          ),
                                          const SizedBox(width: 3),
                                          Text(
                                            due ? 'حان' : 'اعترف ✓',
                                            style: GoogleFonts.cairo(
                                              fontSize: 10.5,
                                              fontWeight: FontWeight.bold,
                                              color: due ? p.gold : p.sage,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    tooltip: 'حذف من الجدول',
                                    constraints: const BoxConstraints(),
                                    padding: const EdgeInsets.only(right: 4),
                                    icon: Icon(Icons.delete_outline_rounded, size: 17, color: p.inkMuted),
                                    onPressed: () => _service.deleteConfessorRecord(rec.id),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _tableFilterChip(AppPalette p, String label, String key) {
    final sel = _confessorsFilter == key;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _confessorsFilter = key),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: sel ? p.gold : p.surfaceSubtle,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: sel ? p.gold : p.border),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.cairo(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: sel ? const Color(0xFF19130A) : p.inkSecondary,
            ),
          ),
        ),
      ),
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
                      '${s.dayLabelAr} • ${s.timeRangeLabelAr}',
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
                      final isDone = att.confessed;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            // 1-Tap Checkmark ✓ Button for Abouna!
                            InkWell(
                              borderRadius: BorderRadius.circular(20),
                              onTap: () {
                                HapticFeedback.selectionClick();
                                _openMarkConfessedSheet(session: s, attendee: att);
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(2),
                                child: Icon(
                                  isDone
                                      ? Icons.check_circle_rounded
                                      : Icons.radio_button_unchecked_rounded,
                                  size: 23,
                                  color: isDone ? p.sage : p.gold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${i + 1}.',
                              style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.bold, color: p.inkMuted),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    att.attendeeName,
                                    style: GoogleFonts.cairo(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: p.ink,
                                    ),
                                  ),
                                  if (isDone && att.nextDateIso.isNotEmpty)
                                    Text(
                                      'اعترف ✓ • يرجع بعد ${PriestConfessorRecord.formatIntervalLabel(att.nextIntervalDays)} (${PriestConfessorRecord.formatArabicDateShort(att.nextDateIso)})',
                                      style: GoogleFonts.cairo(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w600,
                                        color: p.sage,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            InkWell(
                              borderRadius: BorderRadius.circular(8),
                              onTap: () => _openMarkConfessedSheet(session: s, attendee: att),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: isDone
                                      ? p.sage.withValues(alpha: 0.18)
                                      : (isWait ? p.gold : p.accent).withValues(alpha: 0.13),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  isDone
                                      ? 'اعترف ✓'
                                      : (isWait ? 'قائمة انتظار' : 'تأكيد صح ✓'),
                                  style: GoogleFonts.cairo(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.bold,
                                    color: isDone ? p.sage : (isWait ? p.gold : p.accent),
                                  ),
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
              'قدسك تقدر تدعو وتوثّق أب كاهن واحد أو مجموعة آباء كهنة مع بعض (جروب آباء الكنيسة أو الإيبارشية) بكود واحد شغال لغاية ١٥ أب كاهن لمدة ٧ أيام.',
              style: GoogleFonts.cairo(fontSize: 12, color: p.inkSecondary, height: 1.5),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _issuingInvite ? null : () => _issuePeerInvite(profile, maxUses: 1),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: p.sage,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
                    ),
                    icon: _issuingInvite
                        ? const SizedBox(
                            width: 15,
                            height: 15,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.person_add_alt_1_rounded, size: 18),
                    label: Text(
                      'دعوة أب كاهن',
                      style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 12.2),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _issuingInvite ? null : () => _openGroupPeerInvitePicker(profile),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: p.gold,
                      foregroundColor: const Color(0xFF19130A),
                      padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
                    ),
                    icon: const Icon(Icons.groups_rounded, size: 19),
                    label: Text(
                      'أكتر من أب كاهن',
                      style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 12.2),
                    ),
                  ),
                ),
              ],
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
                      'أكواد التزكية اللي قدسك طلّعتها (${invites.length}):',
                      style: GoogleFonts.cairo(fontSize: 11.5, fontWeight: FontWeight.bold, color: p.inkMuted),
                    ),
                    const SizedBox(height: 6),
                    ...invites.take(8).map((inv) {
                      final statusText = inv.isFullyUsed
                          ? (inv.usedByNames.isNotEmpty
                              ? 'استخدمه: ${inv.usedByNames.join('، ')}'
                              : 'اكتمل استخدامه ✓')
                          : (inv.isExpired
                              ? 'منتهي الصلاحية'
                              : (inv.maxUses > 1
                                  ? 'جماعي: استخدمه ${inv.usedCount} من ${inv.maxUses} آباء'
                                  : 'متاح لأب كاهن واحد'));
                      return Container(
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
                                statusText,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.cairo(
                                  fontSize: 11,
                                  color: inv.isFullyUsed
                                      ? p.sage
                                      : (inv.isExpired ? p.danger : p.inkSecondary),
                                ),
                              ),
                            ),
                            if (!inv.isFullyUsed && !inv.isExpired)
                              IconButton(
                                tooltip: 'مشاركة الكود مع الآباء',
                                visualDensity: VisualDensity.compact,
                                icon: Icon(Icons.share_rounded, size: 17, color: p.accent),
                                onPressed: () => SharePlus.instance.share(
                                  ShareParams(
                                    text: ConfessionService.buildPeerPriestVouchShareText(
                                      issuerName: profile.fullDisplayName,
                                      inviteCode: inv.code,
                                      maxUses: inv.maxUses,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    }),
                  ],
                );
              },
            ),
          ] else ...[
            Text(
              'كود قدسك الخاص (${profile.privateCode}) شغال حالياً لأولادك علطول. أما للظهور في الدليل العام، قدسك تدخّل كود تزكية من أي أب كاهن موثّق:',
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
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () {
              HapticFeedback.lightImpact();
              SharePlus.instance.share(
                ShareParams(
                  text: ConfessionService.buildPriestAppRecommendationText(
                    senderPriestName: profile.fullDisplayName,
                    church: profile.church,
                  ),
                ),
              );
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: p.accent,
              side: BorderSide(color: p.goldBorder),
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.send_rounded, size: 17),
            label: Text(
              'ابعت التطبيق لأكتر من أب كاهن (جروب آباء الكنيسة)',
              style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
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
          DioceseChurchSelector(
            selectedDiocese: _selectedDiocese,
            selectedChurch: _selectedChurch,
            onDioceseChanged: (d) => setState(() => _selectedDiocese = d),
            onChurchChanged: (c) => setState(() => _selectedChurch = c),
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
