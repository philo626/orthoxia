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
import 'my_father_schedule_view.dart';

/// Fathers Directory («دليل الآباء الكهنة — اختيار أب الاعتراف» — Page 03/04):
/// - Top Invite Banner: «مش لاقي أب اعترافك؟ ابعت لقدسه دعوة ينضم للتطبيق» + «مشاركة دعوة»
/// - Instant Search by Priest Name across ALL churches
/// - Optional Diocese & Church filters
/// - Clear Priest Cards (Name + Church + Diocese) so similar names are never confused
/// - Private choice saved cleanly with optional «أختار بعدين» skip
class FathersDirectoryView extends StatefulWidget {
  final bool isFirstTimeFlow;
  final VoidCallback? onCompletedOrSkipped;

  const FathersDirectoryView({
    super.key,
    this.isFirstTimeFlow = false,
    this.onCompletedOrSkipped,
  });

  @override
  State<FathersDirectoryView> createState() => _FathersDirectoryViewState();
}

class _FathersDirectoryViewState extends State<FathersDirectoryView> {
  final ConfessionService _service = ConfessionService();
  final StorageService _storage = StorageService();
  final TextEditingController _searchCtrl = TextEditingController();
  final TextEditingController _churchFilterCtrl = TextEditingController();
  final TextEditingController _codeCtrl = TextEditingController();

  String _selectedDiocese = 'كل الإيبارشيات';
  bool _showOptionalFilters = false;
  bool _lookingUpCode = false;

  @override
  void dispose() {
    _searchCtrl.dispose();
    _churchFilterCtrl.dispose();
    _codeCtrl.dispose();
    super.dispose();
  }

  Future<void> _lookupByPrivateCode() async {
    final raw = _codeCtrl.text.trim();
    if (raw.isEmpty) return;
    HapticFeedback.lightImpact();
    FocusScope.of(context).unfocus();
    setState(() => _lookingUpCode = true);
    final (priest, msg) = await _service.findPriestByPrivateCode(raw);
    if (!mounted) return;
    setState(() => _lookingUpCode = false);
    if (priest == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg, style: GoogleFonts.cairo())),
      );
      return;
    }
    _codeCtrl.clear();
    _openPriestCard(priest);
  }

  void _sharePriestInvite() {
    HapticFeedback.lightImpact();
    SharePlus.instance.share(
      ShareParams(text: ConfessionService.priestInviteShareText),
    );
  }

  void _openPriestCard(PriestProfile priest) {
    final p = context.palette;
    final alreadySelected = _storage.getConfessionFatherUid() == priest.priestUid;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
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
                  color: p.border,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: p.goldSoft,
                    border: Border.all(color: p.goldBorder),
                  ),
                  child: Center(child: CopticCross(size: 24, color: p.accent)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        priest.fullDisplayName,
                        style: GoogleFonts.amiri(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: p.ink,
                        ),
                      ),
                      Text(
                        priest.church,
                        style: GoogleFonts.cairo(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: p.accent,
                        ),
                      ),
                      Text(
                        'إيبارشية: ${priest.diocese}',
                        style: GoogleFonts.cairo(fontSize: 12, color: p.inkSecondary),
                      ),
                    ],
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
              child: Text(
                'باختيار قدسه، سيظهر لك اختصار «مواعيد أبونا» مباشرة على صفحتك الرئيسية. هذا الاختيار خاص بك تماماً ولا يظهر لأي شخص آخر.',
                style: GoogleFonts.cairo(fontSize: 12, color: p.inkSecondary, height: 1.55),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () async {
                HapticFeedback.mediumImpact();
                await _service.selectConfessionFather(priest);
                if (!ctx.mounted) return;
                Navigator.pop(ctx);
                if (widget.onCompletedOrSkipped != null) {
                  widget.onCompletedOrSkipped!();
                } else if (mounted) {
                  Navigator.pushReplacement(
                    context,
                    luxeRoute(const MyFatherScheduleView()),
                  );
                }
              },
              icon: Icon(alreadySelected ? Icons.check_circle_rounded : Icons.how_to_reg_rounded, size: 19),
              label: Text(
                alreadySelected ? 'مُختار حالياً — فتح مواعيد أبونا' : 'اختيار قدسه كأب اعترافي',
                style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 14),
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
    final currentFatherUid = _storage.getConfessionFatherUid();

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
              'اختيار أب الاعتراف',
              style: GoogleFonts.amiri(
                fontWeight: FontWeight.bold,
                fontSize: 22,
                color: p.ink,
                height: 1.15,
              ),
            ),
            Text(
              'ابحث بالاسم أو الكنيسة في دليل الآباء الكهنة المعتمدين',
              style: GoogleFonts.cairo(fontSize: 11, color: p.inkMuted),
            ),
          ],
        ),
        actions: [
          if (widget.isFirstTimeFlow)
            TextButton(
              onPressed: () {
                if (widget.onCompletedOrSkipped != null) {
                  widget.onCompletedOrSkipped!();
                } else {
                  Navigator.pop(context);
                }
              },
              child: Text(
                'أختار بعدين',
                style: GoogleFonts.cairo(
                  fontSize: 12.5,
                  fontWeight: FontWeight.bold,
                  color: p.accent,
                ),
              ),
            ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(
            children: [
              // 0. Quick Link by Abona's Private Code (AB-XXXX — works immediately!)
              Container(
                margin: const EdgeInsets.fromLTRB(16, 6, 16, 8),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: p.surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: p.goldBorder, width: 1.2),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.vpn_key_rounded, color: p.gold, size: 19),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'عندك كود أب اعترافك؟ (الربط السريع)',
                            style: GoogleFonts.cairo(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: p.ink,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'اكتب الكود اللي بعتهولك أبونا في الكنيسة أو على جروب الاعتراف عشان تتابع مواعيده فوراً:',
                      style: GoogleFonts.cairo(fontSize: 11, color: p.inkSecondary, height: 1.4),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _codeCtrl,
                            textCapitalization: TextCapitalization.characters,
                            onSubmitted: (_) => _lookupByPrivateCode(),
                            style: GoogleFonts.cairo(
                              color: p.ink,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                            decoration: const InputDecoration(
                              hintText: 'مثال: AB-4829',
                              isDense: true,
                              prefixIcon: Icon(Icons.qr_code_rounded, size: 19),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: _lookingUpCode ? null : _lookupByPrivateCode,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: p.gold,
                            foregroundColor: const Color(0xFF19130A),
                            minimumSize: const Size(0, 44),
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: _lookingUpCode
                              ? const SizedBox(
                                  width: 17,
                                  height: 17,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Color(0xFF19130A),
                                  ),
                                )
                              : Text(
                                  'ربط',
                                  style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // 1. Top Priest Invite Strip (Exact Page 03/04 UX)
              Container(
                margin: const EdgeInsets.fromLTRB(16, 2, 16, 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: p.goldSoft,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: p.goldBorder),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: p.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: p.goldBorder),
                      ),
                      child: Icon(Icons.mail_outline_rounded, color: p.accent, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'مش لاقي أب اعترافك؟',
                            style: GoogleFonts.cairo(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: p.ink,
                            ),
                          ),
                          Text(
                            'ابعت لقدسه دعوة ينضم للتطبيق ويضيف مواعيد الخدمة.',
                            style: GoogleFonts.cairo(
                              fontSize: 11.5,
                              color: p.inkSecondary,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _sharePriestInvite,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(0, 38),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                      ),
                      child: Text(
                        'مشاركة دعوة',
                        style: GoogleFonts.cairo(fontSize: 11.5, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),

              // 2. Search by Priest Name + Optional Diocese/Church Filters
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchCtrl,
                        onChanged: (_) => setState(() {}),
                        style: GoogleFonts.cairo(color: p.ink, fontSize: 13.5),
                        decoration: const InputDecoration(
                          hintText: 'ابحث باسم أبونا في كل الكنائس...',
                          prefixIcon: Icon(Icons.search_rounded, size: 20),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () => setState(() => _showOptionalFilters = !_showOptionalFilters),
                      child: Container(
                        height: 48,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: _showOptionalFilters ? p.accent : p.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: _showOptionalFilters ? p.accent : p.border,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.filter_list_rounded,
                              size: 18,
                              color: _showOptionalFilters ? p.onAccent : p.inkSecondary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'فلتر',
                              style: GoogleFonts.cairo(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: _showOptionalFilters ? p.onAccent : p.ink,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              if (_showOptionalFilters)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 2),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: p.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: p.border),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            isExpanded: true,
                            dropdownColor: p.surface,
                            value: _selectedDiocese,
                            items: [
                              'كل الإيبارشيات',
                              ...CopticDiocesesCatalog.dioceses,
                            ]
                                .map((d) => DropdownMenuItem(
                                      value: d,
                                      child: Text(
                                        d,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.cairo(fontSize: 12.5, color: p.ink),
                                      ),
                                    ))
                                .toList(),
                            onChanged: (v) {
                              if (v != null) setState(() => _selectedDiocese = v);
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _churchFilterCtrl,
                        onChanged: (_) => setState(() {}),
                        style: GoogleFonts.cairo(color: p.ink, fontSize: 13),
                        decoration: const InputDecoration(
                          hintText: 'تصفية باسم الكنيسة (اختياري)...',
                          prefixIcon: Icon(Icons.church_outlined, size: 19),
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 10),

              // 3. Live Directory of Verified Priests
              Expanded(
                child: StreamBuilder<List<PriestProfile>>(
                  stream: _service.watchApprovedPriests(),
                  builder: (context, snap) {
                    if (snap.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator(color: p.accent, strokeWidth: 2));
                    }

                    final all = snap.data ?? [];
                    final q = _searchCtrl.text.trim();
                    final churchQ = _churchFilterCtrl.text.trim();

                    final filtered = all.where((pr) {
                      if (_selectedDiocese != 'كل الإيبارشيات' && pr.diocese != _selectedDiocese) {
                        return false;
                      }
                      if (churchQ.isNotEmpty && !pr.church.contains(churchQ)) {
                        return false;
                      }
                      if (q.isNotEmpty &&
                          !pr.fullDisplayName.contains(q) &&
                          !pr.displayName.contains(q) &&
                          !pr.church.contains(q) &&
                          !pr.diocese.contains(q)) {
                        return false;
                      }
                      return true;
                    }).toList();

                    if (filtered.isEmpty) {
                      return SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            const SizedBox(height: 18),
                            Icon(Icons.church_outlined,
                                size: 48, color: p.inkMuted.withValues(alpha: 0.45)),
                            const SizedBox(height: 12),
                            Text(
                              all.isEmpty
                                  ? 'الدليل بانتظار انضمام الآباء الكهنة المعتمدين'
                                  : 'لم نجد أب كاهن مطابق لهذا البحث حالياً',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.amiri(
                                fontSize: 21,
                                fontWeight: FontWeight.bold,
                                color: p.ink,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'يمكنك مشاركة رابط الدعوة مع أب اعترافك الآن، أو الضغط على «أختار بعدين» والرجوع للدليل في أي وقت من صفحتك الرئيسية.',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.cairo(
                                fontSize: 13,
                                color: p.inkSecondary,
                                height: 1.55,
                              ),
                            ),
                            const SizedBox(height: 18),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                ElevatedButton.icon(
                                  onPressed: _sharePriestInvite,
                                  icon: const Icon(Icons.share_rounded, size: 17),
                                  label: Text('مشاركة دعوة لأبونا',
                                      style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
                                ),
                                if (widget.isFirstTimeFlow) ...[
                                  const SizedBox(width: 10),
                                  OutlinedButton(
                                    onPressed: () {
                                      if (widget.onCompletedOrSkipped != null) {
                                        widget.onCompletedOrSkipped!();
                                      } else {
                                        Navigator.pop(context);
                                      }
                                    },
                                    child: Text('أختار بعدين',
                                        style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 2, 16, 36),
                      itemCount: filtered.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (_, idx) {
                        final pr = filtered[idx];
                        final isSelected = pr.priestUid == currentFatherUid;
                        return PressScale(
                          scale: 0.985,
                          onTap: () => _openPriestCard(pr),
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: isSelected ? p.goldSoft : p.surface,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: isSelected ? p.accent : p.border,
                                width: isSelected ? 1.4 : 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: p.surfaceSubtle,
                                    border: Border.all(color: p.goldBorder),
                                  ),
                                  child: Center(child: CopticCross(size: 19, color: p.accent)),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              pr.fullDisplayName,
                                              style: GoogleFonts.amiri(
                                                fontSize: 19.5,
                                                fontWeight: FontWeight.bold,
                                                color: p.ink,
                                              ),
                                            ),
                                          ),
                                          if (isSelected)
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                  horizontal: 8, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: p.accent,
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: Text(
                                                'أب اعترافي',
                                                style: GoogleFonts.cairo(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                  color: p.onAccent,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                      Text(
                                        pr.church,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.cairo(
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w600,
                                          color: p.accent,
                                        ),
                                      ),
                                      Text(
                                        'إيبارشية: ${pr.diocese}',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.cairo(
                                          fontSize: 11.5,
                                          color: p.inkMuted,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(Icons.chevron_left_rounded, color: p.inkMuted, size: 20),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
