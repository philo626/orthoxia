import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/services/encryption_service.dart';
import '../../core/services/security_guard_service.dart';
import '../../core/services/storage_service.dart';
import '../../core/theme/app_palette.dart';
import '../../core/widgets/luxe_widgets.dart';
import '../../providers/spiritual_tracker_provider.dart';
import '../confession/confession_companion_guide_view.dart';

class ConscienceExamView extends StatefulWidget {
  const ConscienceExamView({super.key});

  @override
  State<ConscienceExamView> createState() => _ConscienceExamViewState();
}

class _ConscienceExamViewState extends State<ConscienceExamView> {
  String _selectedCategory = 'علاقتي بالله';
  bool _unlocked = false;
  bool _checkingLock = true;
  DeviceIntegrityStatus _deviceIntegrity = const DeviceIntegrityStatus();

  @override
  void initState() {
    super.initState();
    SecurityGuardService().setSecureScreen(true);
    _checkDeviceIntegrity();
    _checkBiometricGate();
  }

  @override
  void dispose() {
    SecurityGuardService().setSecureScreen(false);
    super.dispose();
  }

  Future<void> _checkDeviceIntegrity() async {
    final status = await SecurityGuardService().checkDeviceIntegrity();
    if (mounted) {
      setState(() => _deviceIntegrity = status);
    }
  }

  Future<void> _checkBiometricGate() async {
    if (!StorageService().isBiometricConfessionLockEnabled()) {
      if (mounted) {
        setState(() {
          _unlocked = true;
          _checkingLock = false;
        });
      }
      return;
    }
    final ok = await EncryptionService().authenticateForConfession();
    if (mounted) {
      setState(() {
        _unlocked = ok;
        _checkingLock = false;
      });
    }
  }

  final List<String> _categories = const [
    'علاقتي بالله',
    'علاقتي بالقريب',
    'نقاوة القلب والجسد',
  ];

  void _confirmSelfDestruct() {
    final p = context.palette;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: p.surfaceElevated,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: p.border),
        ),
        title: Text(
          'محو سجل فحص الضمير',
          style: GoogleFonts.cairo(
            color: p.crimson,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          'هل أتممت الاعتراف وتريد محو جميع ملاحظاتك الشخصية من هذا الجهاز نهائياً لحفظ السرية التامة؟',
          style: GoogleFonts.cairo(color: p.inkMuted, height: 1.55),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('إلغاء', style: GoogleFonts.cairo(color: p.inkMuted)),
          ),
          ElevatedButton(
            onPressed: () {
              Provider.of<SpiritualTrackerProvider>(context, listen: false)
                  .clearConscienceNotes();
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'تم محو جميع ملاحظات الاعتراف بنجاح وبسرية تامة.',
                    style: GoogleFonts.cairo(),
                  ),
                  backgroundColor: p.success,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: p.crimson),
            child: Text('نعم، امح الملاحظات',
                style: GoogleFonts.cairo(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    if (_checkingLock || !_unlocked) {
      return Scaffold(
        backgroundColor: p.background,
        appBar: AppBar(
          backgroundColor: p.background,
          elevation: 0,
          title: Text(
            'مذكرة الاعتراف الخاصة',
            style: GoogleFonts.amiri(
              fontWeight: FontWeight.w700,
              fontSize: 22,
              color: p.ink,
            ),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: p.accentSoft,
                    border: Border.all(color: p.accent, width: 1.4),
                  ),
                  child: Icon(Icons.fingerprint_rounded,
                      size: 52, color: p.accent),
                ),
                const SizedBox(height: 18),
                Text(
                  'مذكرة الاعتراف محمية ومشفرة على جهازك فقط',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.cairo(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w700,
                    color: p.ink,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'ملاحظاتك خاصة تماماً ولا تُرفع لأي خادم خارجي إطلاقاً.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.cairo(fontSize: 12.5, color: p.inkMuted),
                ),
                const SizedBox(height: 22),
                ElevatedButton.icon(
                  onPressed: _checkBiometricGate,
                  icon: Icon(Icons.lock_open_rounded, color: p.onAccent),
                  label: Text(
                    'تأكيد الهوية وفتح المذكرة',
                    style: GoogleFonts.cairo(
                      color: p.onAccent,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: p.accent,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Consumer<SpiritualTrackerProvider>(
      builder: (context, trackerProv, _) {
        final allQuestions = trackerProv.conscienceQuestions;
        final filteredQuestions = allQuestions
            .where((q) => q.category == _selectedCategory)
            .toList();

        return Scaffold(
          backgroundColor: p.background,
          appBar: AppBar(
            backgroundColor: p.background,
            elevation: 0,
            title: Text(
              'فحص الضمير للاعتراف',
              style: GoogleFonts.amiri(
                fontWeight: FontWeight.w700,
                fontSize: 22,
                color: p.ink,
              ),
            ),
            actions: [
              IconButton(
                icon: Icon(Icons.menu_book_rounded, color: p.gold),
                tooltip: 'صلوات قبل وبعد الاعتراف (أوفلاين)',
                onPressed: () => Navigator.push(
                  context,
                  luxeRoute(const ConfessionCompanionGuideView(initialTab: 0)),
                ),
              ),
              IconButton(
                icon: Icon(Icons.delete_forever_rounded, color: p.crimson),
                tooltip: 'محو الملاحظات بعد الاعتراف',
                onPressed: _confirmSelfDestruct,
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: Column(
            children: [
              Container(
                margin: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                padding: const EdgeInsets.all(13),
                decoration: BoxDecoration(
                  color: p.accentSoft,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: p.accent.withValues(alpha: 0.35)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.verified_user_rounded,
                        color: p.accent, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'جميع ملاحظاتك مشفرة محلياً داخل شريحة أمان هاتفك مع منع التقاط الشاشة، ولا تُرفع لأي خادم.',
                        style: GoogleFonts.cairo(
                          fontSize: 12,
                          color: p.ink,
                          height: 1.45,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (_deviceIntegrity.hasRisk)
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: p.crimsonSoft,
                    borderRadius: BorderRadius.circular(12),
                    border:
                        Border.all(color: p.crimson.withValues(alpha: 0.45)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning_amber_rounded,
                          color: p.crimson, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'تنبيه أمان: يُنصح بمحو ملاحظات الاعتراف فور إتمام السر.',
                          style: GoogleFonts.cairo(
                            fontSize: 11.5,
                            color: p.crimson,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Row(
                  children: _categories.map((cat) {
                    final isSel = _selectedCategory == cat;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedCategory = cat),
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          padding: const EdgeInsets.symmetric(vertical: 9),
                          decoration: BoxDecoration(
                            color: isSel ? p.accent : p.surfaceElevated,
                            borderRadius: BorderRadius.circular(11),
                            border: Border.all(
                              color: isSel ? p.accent : p.border,
                            ),
                          ),
                          child: Text(
                            cat,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.cairo(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: isSel ? p.onAccent : p.ink,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.separated(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  itemCount: filteredQuestions.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final q = filteredQuestions[index];
                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: p.surfaceElevated,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: q.isChecked ? p.accent : p.border,
                          width: q.isChecked ? 1.4 : 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Checkbox(
                                value: q.isChecked,
                                activeColor: p.accent,
                                checkColor: p.onAccent,
                                onChanged: (_) =>
                                    trackerProv.toggleQuestion(q.id),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      q.title,
                                      style: GoogleFonts.cairo(
                                        fontSize: 14.5,
                                        fontWeight: FontWeight.w700,
                                        color: q.isChecked ? p.accent : p.ink,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      q.explanation,
                                      style: GoogleFonts.cairo(
                                        fontSize: 12.5,
                                        color: p.inkMuted,
                                        height: 1.45,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          if (q.isChecked) ...[
                            const SizedBox(height: 10),
                            TextFormField(
                              initialValue: q.personalNote,
                              onChanged: (val) =>
                                  trackerProv.updateQuestionNote(q.id, val),
                              style: GoogleFonts.cairo(
                                  color: p.ink, fontSize: 13),
                              decoration: InputDecoration(
                                hintText:
                                    'ملاحظة سرية خاصة لتذكرها مع أب الاعتراف...',
                                hintStyle: GoogleFonts.cairo(
                                    color: p.inkSubtle, fontSize: 12),
                                filled: true,
                                fillColor: p.surfaceMuted,
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 10),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(color: p.border),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: ElevatedButton.icon(
                  onPressed: _confirmSelfDestruct,
                  icon:
                      const Icon(Icons.check_circle_outline_rounded, size: 20),
                  label: Text(
                    'إتمام الاعتراف ومحو الملاحظات',
                    style: GoogleFonts.cairo(
                        fontSize: 13.5, fontWeight: FontWeight.w700),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: p.crimson,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
