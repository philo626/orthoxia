import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/services/confession_service.dart';
import '../../core/services/storage_service.dart';
import '../../core/theme/app_palette.dart';
import '../../core/widgets/coptic_cross.dart';
import '../../core/widgets/luxe_widgets.dart';
import '../../models/confession_models.dart';
import '../../models/katameros_model.dart';
import '../../providers/liturgy_provider.dart';
import '../liturgical/agpeya_view.dart';
import '../liturgical/church_sacraments_rites_view.dart';
import '../liturgical/fractions_library_view.dart';
import '../liturgical/katameros_view.dart';
import '../liturgical/raising_of_incense_view.dart';
import '../liturgies/liturgy_reader_view.dart';
import '../onboarding/auth_view.dart';

/// Priest Portal («لوحة أبونا · خدمتي النهارده» — Pages 01/04, 02/04 & 04/04):
/// - Handles Verification States cleanly:
///     1) First-time / needs_info -> Complete Diocese + Church + Submit/Resubmit
///     2) Pending -> Status tracker + Full Priestly Library usable immediately
///     3) Approved -> Full Confession Day Publisher + Live Attendee Lists + Privacy-First Notifications + Priestly Library
class PriestDashboardView extends StatefulWidget {
  const PriestDashboardView({super.key});

  @override
  State<PriestDashboardView> createState() => _PriestDashboardViewState();
}

class _PriestDashboardViewState extends State<PriestDashboardView> {
  final ConfessionService _service = ConfessionService();
  final StorageService _storage = StorageService();

  // Priest Registration / Edit Form Controllers
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _churchCtrl = TextEditingController();
  final TextEditingController _phoneCtrl = TextEditingController();
  final TextEditingController _noteCtrl = TextEditingController();
  String _titlePrefix = 'القس';
  String _selectedDiocese = CopticDiocesesCatalog.dioceses.first;
  bool _submittingForm = false;
  bool _editingProfile = false;
  bool _prefilledFromProfile = false;
  KatamerosDay? _katameros;

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
    _loadKatameros();
    _service.startPriestRealtimeAlertListener();
  }

  Future<void> _loadKatameros() async {
    try {
      final raw = await rootBundle.loadString('assets/data/katameros.json');
      if (mounted) {
        setState(() => _katameros = KatamerosDay.fromJson(jsonDecode(raw)));
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _churchCtrl.dispose();
    _phoneCtrl.dispose();
    _noteCtrl.dispose();
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
    } else if (_storage.hasCustomUserName()) {
      _nameCtrl.text = _storage.getUserName();
    }
  }

  Future<void> _submitVerification() async {
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
    if (!mounted) return;
    setState(() {
      _submittingForm = false;
      if (ok) _editingProfile = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg, style: GoogleFonts.cairo())),
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
                      decoration: BoxDecoration(
                        color: p.border,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'فتح تسجيل للاعترافات',
                    style: GoogleFonts.amiri(
                      fontSize: 23,
                      fontWeight: FontWeight.bold,
                      color: p.ink,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'قدسك تحب تبدأ أي يوم والساعة كام؟ وقت انتهاء الخدمة بيتحدد في الكنيسة وكل شخص ياخد وقته.',
                    style: GoogleFonts.cairo(fontSize: 12.5, color: p.inkSecondary, height: 1.5),
                  ),
                  const SizedBox(height: 16),

                  // Day & Start Time Pickers
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
                            style: GoogleFonts.cairo(
                              fontSize: 12.5,
                              fontWeight: FontWeight.bold,
                              color: p.ink,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final t = await showTimePicker(
                              context: ctx,
                              initialTime: pickedTime,
                            );
                            if (t != null) setSheet(() => pickedTime = t);
                          },
                          icon: Icon(Icons.schedule_rounded, size: 18, color: p.accent),
                          label: Text(
                            'من ${_formatArTime(pickedTime)}',
                            style: GoogleFonts.cairo(
                              fontSize: 12.5,
                              fontWeight: FontWeight.bold,
                              color: p.ink,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // Open Count (Default) vs Optional Daily Cap
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
                                    style: GoogleFonts.cairo(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: p.ink,
                                    ),
                                  ),
                                  Text(
                                    unlimited
                                        ? 'الوضع الطبيعي: مفتوح للجميع ويمكنك إيقاف التسجيل في أي وقت.'
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
                      hintText: 'ملاحظة أو مكان الاستقبال (اختياري — مثلاً: مكتب الكنيسة)',
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
                      'نشر الموعد للشعب',
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
                decoration: BoxDecoration(
                  color: p.border,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'إشعارات الحضور لقدسك',
              style: GoogleFonts.amiri(fontSize: 22, fontWeight: FontWeight.bold, color: p.ink),
            ),
            Text(
              'تظهر الأسماء والتفاصيل هنا داخل حساب قدسك فقط، بينما يظل إشعار شاشة القفل عاماً لحفظ الخصوصية.',
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
                            border: Border.all(
                              color: n.read ? p.border : p.goldBorder,
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                isCancel
                                    ? Icons.person_remove_outlined
                                    : Icons.how_to_reg_rounded,
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

  Future<void> _openLiturgyAndBookmark(String id, String title) async {
    await _storage.savePriestBookmark(
      bookKey: id,
      title: title,
      note: 'آخر موضع قراءة لقدسك في الكنيسة',
    );
    if (!mounted) return;
    final prov = context.read<LiturgyProvider>();
    await prov.loadLiturgies();
    prov.selectLiturgyById(id);
    if (!mounted) return;
    Navigator.push(context, luxeRoute(const LiturgyReaderView()));
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
          title: Text('لوحة أبونا • خدمتي النهارده',
              style: GoogleFonts.amiri(fontWeight: FontWeight.bold, fontSize: 22, color: p.ink)),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CopticCross(size: 40, color: p.accent),
                const SizedBox(height: 14),
                Text(
                  'أهلاً بيك يا قدس أبونا',
                  style: GoogleFonts.amiri(fontSize: 26, fontWeight: FontWeight.bold, color: p.ink),
                ),
                const SizedBox(height: 6),
                Text(
                  'التطبيق نوّر بوجود قدسك. يُرجى تسجيل الدخول بحساب قدسك أولاً لإرسال طلب التفعيل وفتح لوحة الخدمة.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.cairo(fontSize: 13.5, color: p.inkSecondary, height: 1.55),
                ),
                const SizedBox(height: 18),
                ElevatedButton(
                  onPressed: () => Navigator.push(context, luxeRoute(const AuthView())),
                  child: const Text('تسجيل الدخول كأب كاهن'),
                ),
              ],
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

        final isApproved = profile?.verificationStatus == PriestVerificationStatus.approved;
        final isNeedsInfo = profile?.verificationStatus == PriestVerificationStatus.needsInfo;
        final isPending = profile?.verificationStatus == PriestVerificationStatus.pending;

        return Scaffold(
          backgroundColor: p.canvas,
          appBar: AppBar(
            backgroundColor: p.canvas,
            foregroundColor: p.ink,
            elevation: 0,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'لوحة أبونا • خدمتي النهارده',
                  style: GoogleFonts.amiri(
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                    color: p.ink,
                    height: 1.15,
                  ),
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
              if (isApproved)
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
              ? Center(child: CircularProgressIndicator(color: p.accent, strokeWidth: 2))
              : Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 740),
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
                      children: [
                        // 1. Respectful Welcome / Verification State Card
                        if (profile == null || _editingProfile || isNeedsInfo)
                          _buildVerificationFormCard(p, profile, isNeedsInfo)
                        else if (isPending)
                          _buildPendingStatusCard(p, profile)
                        else if (isApproved)
                          _buildApprovedConfessionsManager(p, profile),

                        const SizedBox(height: 20),

                        // 2. Priestly Liturgical Library (ALWAYS available — even while waiting for verification!)
                        _buildPriestlyLibrarySection(p),
                      ],
                    ),
                  ),
                ),
        );
      },
    );
  }

  Widget _buildVerificationFormCard(
    AppPalette p,
    PriestProfile? existing,
    bool isNeedsInfo,
  ) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isNeedsInfo ? p.gold : p.border, width: isNeedsInfo ? 1.5 : 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              CopticCross(size: 20, color: p.accent),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isNeedsInfo
                          ? 'مطلوب استكمال بيانات قدسك'
                          : 'أهلاً بيك يا قدس أبونا',
                      style: GoogleFonts.amiri(
                        fontSize: 23,
                        fontWeight: FontWeight.bold,
                        color: p.ink,
                      ),
                    ),
                    Text(
                      isNeedsInfo
                          ? 'يرجى مراجعة الملاحظة وتحديث البيانات لإعادة الإرسال:'
                          : 'التطبيق نوّر بوجود قدسك. أكمل الإيبارشية والكنيسة لإرسال طلب التفعيل.',
                      style: GoogleFonts.cairo(fontSize: 12, color: p.inkSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),

          if (isNeedsInfo && (existing?.adminFeedback.isNotEmpty ?? false)) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: p.goldSoft,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: p.goldBorder),
              ),
              child: Text(
                'ملاحظة المسؤول المفوّض: ${existing!.adminFeedback}',
                style: GoogleFonts.cairo(
                  fontSize: 12.5,
                  fontWeight: FontWeight.bold,
                  color: p.ink,
                ),
              ),
            ),
          ],

          const SizedBox(height: 16),

          // Title prefix selector (القس / القمص)
          Row(
            children: ['القس', 'القمص'].map((prefix) {
              final sel = _titlePrefix == prefix;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(left: prefix == 'القس' ? 8 : 0),
                  child: ChoiceChip(
                    showCheckmark: false,
                    selected: sel,
                    selectedColor: p.accent,
                    backgroundColor: p.surfaceSubtle,
                    label: Center(
                      child: Text(
                        prefix,
                        style: GoogleFonts.cairo(
                          fontWeight: FontWeight.bold,
                          color: sel ? p.onAccent : p.ink,
                        ),
                      ),
                    ),
                    onSelected: (_) => setState(() => _titlePrefix = prefix),
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 12),

          TextField(
            controller: _nameCtrl,
            style: GoogleFonts.cairo(color: p.ink, fontSize: 14),
            decoration: const InputDecoration(
              hintText: 'اسم قدسك الكامل (مثال: بولس جرجس)',
              prefixIcon: Icon(Icons.person_outline_rounded, size: 20),
            ),
          ),

          const SizedBox(height: 12),

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

          const SizedBox(height: 12),

          TextField(
            controller: _churchCtrl,
            style: GoogleFonts.cairo(color: p.ink, fontSize: 14),
            decoration: const InputDecoration(
              hintText: 'اسم الكنيسة والمنطقة (مثال: كنيسة السيدة العذراء بمسرة)',
              prefixIcon: Icon(Icons.church_outlined, size: 20),
            ),
          ),

          const SizedBox(height: 12),

          TextField(
            controller: _phoneCtrl,
            keyboardType: TextInputType.phone,
            style: GoogleFonts.cairo(color: p.ink, fontSize: 14),
            decoration: const InputDecoration(
              hintText: 'رقم هاتف للتواصل مع الإيبارشية للتحقق (اختياري — غير معلن للشعب)',
              prefixIcon: Icon(Icons.phone_outlined, size: 20),
            ),
          ),

          const SizedBox(height: 12),

          TextField(
            controller: _noteCtrl,
            maxLines: 2,
            style: GoogleFonts.cairo(color: p.ink, fontSize: 13.5),
            decoration: const InputDecoration(
              hintText: 'ملاحظة إضافية لمراجعة الطلب (اختياري)',
            ),
          ),

          const SizedBox(height: 16),

          ElevatedButton.icon(
            onPressed: _submittingForm ? null : _submitVerification,
            icon: _submittingForm
                ? SizedBox(
                    width: 17,
                    height: 17,
                    child: CircularProgressIndicator(strokeWidth: 2, color: p.onAccent),
                  )
                : const Icon(Icons.verified_user_outlined, size: 19),
            label: Text(
              isNeedsInfo ? 'إعادة إرسال طلب التفعيل' : 'إرسال طلب تفعيل صفة الكاهن',
              style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingStatusCard(AppPalette p, PriestProfile profile) {
    return Container(
      padding: const EdgeInsets.all(18),
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
              Icon(Icons.hourglass_top_rounded, color: p.accent, size: 24),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'طلب التفعيل قيد المراجعة',
                      style: GoogleFonts.amiri(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: p.ink,
                      ),
                    ),
                    Text(
                      '${profile.fullDisplayName} • ${profile.church} (${profile.diocese})',
                      style: GoogleFonts.cairo(fontSize: 12, color: p.inkSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: p.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: p.border),
            ),
            child: Text(
              'أثناء انتظار التفعيل: يقدر قدسك قراءة جميع كتب المكتبة الكهنوتية بالأسفل ومتابعة حالة الطلب. نشر المواعيد والظهور في الدليل للشعب يبدأ فور التحقق من صفة الكاهن.',
              style: GoogleFonts.cairo(fontSize: 12.5, color: p.inkSecondary, height: 1.55),
            ),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => setState(() => _editingProfile = true),
              icon: Icon(Icons.edit_outlined, size: 16, color: p.accent),
              label: Text(
                'تعديل بيانات الطلب',
                style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.bold, color: p.accent),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildApprovedConfessionsManager(AppPalette p, PriestProfile profile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Hero CTA: Open Confession Attendance
        Container(
          padding: const EdgeInsets.all(18),
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
                  Icon(Icons.verified_rounded, color: p.sage, size: 22),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'حساب قدسك مفعّل وظاهر في الدليل',
                      style: GoogleFonts.cairo(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: p.sage,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'خدمة الاعترافات • يكفي اختيار اليوم وساعة البداية فقط',
                style: GoogleFonts.amiri(
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                  color: p.ink,
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () => _openPublishSessionSheet(profile),
                icon: const Icon(Icons.add_circle_outline_rounded, size: 20),
                label: Text(
                  'فتح تسجيل للاعترافات',
                  style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 14.5),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        Text(
          'مواعيد قدسك المنشورة وقائمة الحضور',
          style: GoogleFonts.amiri(fontSize: 21, fontWeight: FontWeight.bold, color: p.ink),
        ),
        const SizedBox(height: 8),

        StreamBuilder<List<ConfessionSession>>(
          stream: _service.watchPriestSessions(profile.priestUid),
          builder: (context, snap) {
            final sessions = snap.data ?? [];
            if (sessions.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: p.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: p.border),
                ),
                child: Text(
                  'لم ينشر قدسك مواعيد اعتراف بعد. اضغط «فتح تسجيل للاعترافات» بالأعلى ليظهر الموعد فوراً لأبنائك.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.cairo(fontSize: 12.5, color: p.inkMuted, height: 1.55),
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
              Icon(Icons.event_note_rounded, size: 19, color: p.accent),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${s.dayLabelAr} • ابتداءً من ${s.startTimeAr}',
                      style: GoogleFonts.cairo(
                        fontSize: 13.5,
                        fontWeight: FontWeight.bold,
                        color: p.ink,
                      ),
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
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _service.toggleSessionOpen(s.id, !s.isOpen),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: s.isOpen ? p.danger : p.sage,
                    side: BorderSide(color: s.isOpen ? p.danger : p.sage),
                  ),
                  icon: Icon(
                    s.isOpen ? Icons.lock_outline_rounded : Icons.lock_open_rounded,
                    size: 17,
                  ),
                  label: Text(
                    s.isOpen ? 'إيقاف تسجيل حضور جديد' : 'إعادة فتح التسجيل',
                    style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Live Attendee List («قائمة الحضور عند أبونا»)
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
                      style: GoogleFonts.cairo(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: p.accent,
                      ),
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
                              style: GoogleFonts.cairo(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: p.inkMuted,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                att.attendeeName,
                                style: GoogleFonts.cairo(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: p.ink,
                                ),
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

  Widget _buildPriestlyLibrarySection(AppPalette p) {
    final bookmark = _storage.getPriestBookmark();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'المكتبة الكهنوتية',
          style: GoogleFonts.amiri(fontSize: 22, fontWeight: FontWeight.bold, color: p.ink),
        ),
        Text(
          'الخولاجي بقداساته الثلاثة، رفع البخور، القِسَم، الأجبية، القطمارس، وكتب الخدمات',
          style: GoogleFonts.cairo(fontSize: 11.5, color: p.inkMuted),
        ),
        const SizedBox(height: 10),

        if (bookmark != null && (bookmark['title']?.isNotEmpty ?? false))
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: PressScale(
              scale: 0.985,
              onTap: () => _openLiturgyAndBookmark(
                bookmark['bookKey'] ?? 'liturgy_basil',
                bookmark['title'] ?? 'القداس الباسيلي',
              ),
              child: Container(
                padding: const EdgeInsets.all(13),
                decoration: BoxDecoration(
                  color: p.goldSoft,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: p.goldBorder),
                ),
                child: Row(
                  children: [
                    Icon(Icons.bookmark_added_rounded, color: p.accent, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'الرجوع للموضع المحفوظ: ${bookmark['title']}',
                        style: GoogleFonts.cairo(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: p.ink,
                        ),
                      ),
                    ),
                    Icon(Icons.chevron_left_rounded, color: p.accent, size: 19),
                  ],
                ),
              ),
            ),
          ),

        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 2.0,
          children: [
            _priestBookTile(
              p,
              Icons.church_outlined,
              'القداس الباسيلي',
              'مع صلوات الكاهن السرية',
              () => _openLiturgyAndBookmark('liturgy_basil', 'القداس الباسيلي'),
            ),
            _priestBookTile(
              p,
              Icons.church_outlined,
              'الغريغوري والكيرلسي',
              'للأعياد والأصوام',
              () => _openLiturgyAndBookmark('liturgy_gregory', 'القداس الغريغوري'),
            ),
            _priestBookTile(
              p,
              Icons.local_fire_department_outlined,
              'رفع بخور عشية وباكر',
              'الخدمة الكاملة قبطي وعربي',
              () => Navigator.push(context, luxeRoute(const RaisingOfIncenseView())),
            ),
            _priestBookTile(
              p,
              Icons.auto_awesome_outlined,
              'صلوات القِسَم (٣٩)',
              'كل المواسم والأعياد',
              () => Navigator.push(context, luxeRoute(const FractionsLibraryView())),
            ),
            _priestBookTile(
              p,
              Icons.schedule_outlined,
              'الأجبية المقدسة',
              'السواعي + صلوات أخرى',
              () => Navigator.push(
                context,
                luxeRoute(const TitledPage(title: 'الأجبية المقدسة', child: AgpeyaView())),
              ),
            ),
            _priestBookTile(
              p,
              Icons.auto_stories_outlined,
              'القطمارس اليومي',
              'قراءات عشية وباكر والقداس',
              () {
                if (_katameros != null) {
                  Navigator.push(context, luxeRoute(KatamerosView(katameros: _katameros!)));
                }
              },
            ),
            _priestBookTile(
              p,
              Icons.volunteer_activism_outlined,
              'كتب الخدمات والأسرار',
              'المعمودية • الإكليل • القنديل • اللقان',
              () => Navigator.push(context, luxeRoute(const ChurchSacramentsRitesView())),
            ),
          ],
        ),
      ],
    );
  }

  Widget _priestBookTile(
    AppPalette p,
    IconData icon,
    String title,
    String sub,
    VoidCallback onTap,
  ) {
    return PressScale(
      scale: 0.97,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: p.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: p.border),
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: p.goldSoft,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: p.accent),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.cairo(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: p.ink,
                    ),
                  ),
                  Text(
                    sub,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.cairo(fontSize: 9.8, color: p.inkMuted),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
