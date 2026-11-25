import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/services/confession_service.dart';
import '../../core/theme/app_palette.dart';
import '../../core/widgets/coptic_cross.dart';
import '../../models/confession_models.dart';

/// Authorized Church / Diocese Admin Panel («مراجعة صفة الكهنة» — Page 01/04):
/// Strictly protected by Firestore `admins/{uid}` zero-trust rules.
/// Allows authorized reviewers to Approve (تم التفعيل) or Request Info (مطلوب استكمال).
class AdminPriestReviewView extends StatefulWidget {
  const AdminPriestReviewView({super.key});

  @override
  State<AdminPriestReviewView> createState() => _AdminPriestReviewViewState();
}

class _AdminPriestReviewViewState extends State<AdminPriestReviewView> {
  final ConfessionService _service = ConfessionService();

  Future<void> _requestMoreInfo(PriestProfile priest) async {
    final p = context.palette;
    final ctrl = TextEditingController();
    final feedback = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: p.surface,
        title: Text(
          'طلب استكمال بيانات (${priest.fullDisplayName})',
          style: GoogleFonts.amiri(fontWeight: FontWeight.bold, fontSize: 20, color: p.ink),
        ),
        content: TextField(
          controller: ctrl,
          maxLines: 3,
          style: GoogleFonts.cairo(color: p.ink, fontSize: 13.5),
          decoration: const InputDecoration(
            hintText: 'اكتب المطلوب استكماله (مثلاً: اسم الكنيسة بالكامل أو رقم للتواصل)...',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('إلغاء', style: GoogleFonts.cairo(color: p.inkMuted)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: const Text('إرسال'),
          ),
        ],
      ),
    );
    if (feedback == null) return;
    final (_, msg) = await _service.adminReviewPriest(
      priestUid: priest.priestUid,
      newStatus: PriestVerificationStatus.needsInfo,
      feedback: feedback.isEmpty ? 'يُرجى مراجعة واستكمال بيانات الكنيسة والإيبارشية.' : feedback,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg, style: GoogleFonts.cairo())),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Scaffold(
      backgroundColor: p.canvas,
      appBar: AppBar(
        backgroundColor: p.canvas,
        foregroundColor: p.ink,
        elevation: 0,
        title: Text(
          'مراجعة وتفعيل صفة الكهنة',
          style: GoogleFonts.amiri(fontWeight: FontWeight.bold, fontSize: 22, color: p.ink),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 740),
          child: StreamBuilder<List<PriestProfile>>(
            stream: _service.watchAllPriestsForAdmin(),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator(color: p.accent, strokeWidth: 2));
              }
              final priests = snap.data ?? [];
              if (priests.isEmpty) {
                return Center(
                  child: Text(
                    'لا توجد طلبات تفعيل للآباء الكهنة حالياً.',
                    style: GoogleFonts.cairo(color: p.inkMuted),
                  ),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 36),
                itemCount: priests.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (_, idx) {
                  final pr = priests[idx];
                  final status = pr.verificationStatus;
                  final statusLabel = status == PriestVerificationStatus.approved
                      ? 'تم التفعيل'
                      : (status == PriestVerificationStatus.needsInfo
                          ? 'مطلوب استكمال'
                          : 'قيد المراجعة');
                  final statusColor = status == PriestVerificationStatus.approved
                      ? p.sage
                      : (status == PriestVerificationStatus.needsInfo ? p.danger : p.gold);

                  return Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: p.surface,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: p.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CopticCross(size: 16, color: p.accent),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                pr.fullDisplayName,
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
                                color: statusColor.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                statusLabel,
                                style: GoogleFonts.cairo(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: statusColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'الكنيسة: ${pr.church} • الإيبارشية: ${pr.diocese}',
                          style: GoogleFonts.cairo(fontSize: 12.5, color: p.inkSecondary),
                        ),
                        if (pr.phoneForVerification.isNotEmpty)
                          Text(
                            'هاتف التحقق: ${pr.phoneForVerification}',
                            style: GoogleFonts.cairo(fontSize: 12, color: p.inkMuted),
                          ),
                        if (pr.verificationNote.isNotEmpty)
                          Text(
                            'ملاحظة: ${pr.verificationNote}',
                            style: GoogleFonts.cairo(fontSize: 12, color: p.inkMuted),
                          ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            if (status != PriestVerificationStatus.approved)
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () async {
                                    final (_, msg) = await _service.adminReviewPriest(
                                      priestUid: pr.priestUid,
                                      newStatus: PriestVerificationStatus.approved,
                                    );
                                    if (!context.mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text(msg, style: GoogleFonts.cairo())),
                                    );
                                  },
                                  icon: const Icon(Icons.verified_rounded, size: 17),
                                  label: Text('تم التفعيل',
                                      style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
                                ),
                              ),
                            if (status != PriestVerificationStatus.approved)
                              const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => _requestMoreInfo(pr),
                                icon: Icon(Icons.edit_note_rounded, size: 17, color: p.accent),
                                label: Text(
                                  'مطلوب استكمال',
                                  style: GoogleFonts.cairo(
                                    fontWeight: FontWeight.bold,
                                    color: p.accent,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
