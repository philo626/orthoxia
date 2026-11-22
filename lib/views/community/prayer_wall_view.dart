import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/services/firebase_service.dart';
import '../../core/theme/app_palette.dart';
import '../../providers/prayer_wall_provider.dart';
import '../onboarding/auth_view.dart';

class PrayerWallView extends StatelessWidget {
  const PrayerWallView({super.key});

  String _relativeArabicTime(DateTime createdAt) {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inMinutes < 2) return 'الآن';
    if (diff.inMinutes < 60) return 'منذ ${diff.inMinutes} دقيقة';
    if (diff.inHours < 24) {
      return diff.inHours == 1 ? 'منذ ساعة' : 'منذ ${diff.inHours} ساعات';
    }
    if (diff.inDays == 1) return 'منذ يوم';
    if (diff.inDays < 7) return 'منذ ${diff.inDays} أيام';
    return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
  }

  void _showAddPrayerDialog(BuildContext context) {
    final p = context.palette;
    final firebase = FirebaseService();

    // Honest guard: Firestore Prayer Wall requires signed-in user
    if (firebase.isFirebaseReady && firebase.currentUser == null) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: p.surfaceElevated,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: p.border),
          ),
          title: Text(
            'تسجيل الدخول مطلوب للنشر',
            style: GoogleFonts.cairo(
              color: p.ink,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
          content: Text(
            'لحماية حائط الصلاة من الإزعاج، يُرجى تسجيل الدخول بحسابك أولاً (ويمكنك النشر بدون إظهار اسمك إذا أردت).',
            style: GoogleFonts.cairo(
              color: p.inkMuted,
              fontSize: 13,
              height: 1.55,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('إلغاء', style: GoogleFonts.cairo(color: p.inkMuted)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: p.accent,
                foregroundColor: p.onAccent,
              ),
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AuthView()),
                );
              },
              child: Text('تسجيل الدخول',
                  style: GoogleFonts.cairo(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      );
      return;
    }

    final titleCtrl = TextEditingController();
    final contentCtrl = TextEditingController();
    final authorCtrl = TextEditingController();
    bool isAnonymous = true;
    bool submitting = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) {
          return AlertDialog(
            backgroundColor: p.surfaceElevated,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(color: p.border),
            ),
            title: Text(
              'اطلب صلاة من الكنيسة',
              style: GoogleFonts.cairo(
                color: p.ink,
                fontWeight: FontWeight.w700,
                fontSize: 17,
              ),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleCtrl,
                    style: GoogleFonts.cairo(color: p.ink, fontSize: 13.5),
                    decoration: InputDecoration(
                      hintText: 'عنوان الطلبة (مثلاً: من أجل شفاء مريض)',
                      hintStyle:
                          GoogleFonts.cairo(color: p.inkSubtle, fontSize: 12.5),
                      filled: true,
                      fillColor: p.surfaceMuted,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: contentCtrl,
                    maxLines: 4,
                    style: GoogleFonts.cairo(color: p.ink, fontSize: 13.5),
                    decoration: InputDecoration(
                      hintText: 'اكتب تفاصيل الطلبة لتصلي الكنيسة معك...',
                      hintStyle:
                          GoogleFonts.cairo(color: p.inkSubtle, fontSize: 12.5),
                      filled: true,
                      fillColor: p.surfaceMuted,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    activeThumbColor: p.accent,
                    title: Text(
                      'نشر بدون اسم (للسرية)',
                      style: GoogleFonts.cairo(color: p.ink, fontSize: 13),
                    ),
                    value: isAnonymous,
                    onChanged: (val) => setState(() => isAnonymous = val),
                  ),
                  if (!isAnonymous) ...[
                    const SizedBox(height: 6),
                    TextField(
                      controller: authorCtrl,
                      style: GoogleFonts.cairo(color: p.ink, fontSize: 13.5),
                      decoration: InputDecoration(
                        hintText: 'اسمك الظاهر',
                        hintStyle: GoogleFonts.cairo(
                            color: p.inkSubtle, fontSize: 12.5),
                        filled: true,
                        fillColor: p.surfaceMuted,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: submitting ? null : () => Navigator.pop(ctx),
                child:
                    Text('إلغاء', style: GoogleFonts.cairo(color: p.inkMuted)),
              ),
              ElevatedButton(
                onPressed: submitting
                    ? null
                    : () async {
                        final t = titleCtrl.text.trim();
                        final c = contentCtrl.text.trim();
                        if (t.length < 3 || c.length < 5) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'يرجى كتابة عنوان وتفاصيل واضحة لطلبة الصلاة.',
                                style: GoogleFonts.cairo(fontSize: 12.5),
                              ),
                              backgroundColor: p.crimson,
                            ),
                          );
                          return;
                        }
                        setState(() => submitting = true);
                        final err = await Provider.of<PrayerWallProvider>(
                          context,
                          listen: false,
                        ).addRequest(
                          title: t,
                          content: c,
                          isAnonymous: isAnonymous,
                          authorName: authorCtrl.text.trim(),
                        );
                        if (!ctx.mounted) return;
                        Navigator.pop(ctx);
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              err ?? 'تم نشر طلبة صلاتك بنجاح. بركة الصلاة معك.',
                              style: GoogleFonts.cairo(fontSize: 12.5),
                            ),
                            backgroundColor: err != null ? p.crimson : p.success,
                          ),
                        );
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: p.accent,
                  foregroundColor: p.onAccent,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: Text(
                  submitting ? 'جارٍ النشر...' : 'نشر الطلبة',
                  style: GoogleFonts.cairo(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Consumer<PrayerWallProvider>(
      builder: (context, prayerProv, _) {
        final requests = prayerProv.requests;

        return Scaffold(
          backgroundColor: p.background,
          appBar: AppBar(
            backgroundColor: p.background,
            elevation: 0,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'حائط الصلاة المشترك',
                  style: GoogleFonts.amiri(
                    fontWeight: FontWeight.w700,
                    fontSize: 22,
                    color: p.ink,
                  ),
                ),
                Text(
                  prayerProv.isCloudSynced
                      ? 'متصل مباشرة بالكنيسة • اذكروا بعضكم بعضاً'
                      : 'صلّوا بعضكم لأجل بعض لكي تُشفَوا (يع ٥: ١٦)',
                  style: GoogleFonts.cairo(fontSize: 11, color: p.inkMuted),
                ),
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _showAddPrayerDialog(context),
            backgroundColor: p.accent,
            foregroundColor: p.onAccent,
            icon: const Icon(Icons.add_rounded),
            label: Text(
              'اطلب صلاة',
              style: GoogleFonts.cairo(fontWeight: FontWeight.w700),
            ),
          ),
          body: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 95),
            itemCount: requests.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final req = requests[index];
              final isMine = prayerProv.isOwnRequest(req);
              final displayName = req.isAnonymous || req.authorName.isEmpty
                  ? 'ابن للكنيسة'
                  : req.authorName;

              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: p.surfaceElevated,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: req.hasPrayed ? p.accent : p.border,
                    width: req.hasPrayed ? 1.2 : 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: p.accentSoft,
                          ),
                          child: Icon(
                            req.isAnonymous
                                ? Icons.shield_outlined
                                : Icons.person_outline_rounded,
                            size: 16,
                            color: p.accent,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            displayName,
                            style: GoogleFonts.cairo(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: p.accent,
                            ),
                          ),
                        ),
                        Text(
                          _relativeArabicTime(req.createdAt),
                          style: GoogleFonts.cairo(
                            fontSize: 11,
                            color: p.inkMuted,
                          ),
                        ),
                        if (isMine) ...[
                          const SizedBox(width: 6),
                          IconButton(
                            visualDensity: VisualDensity.compact,
                            icon: Icon(Icons.delete_outline_rounded,
                                size: 19, color: p.crimson),
                            tooltip: 'حذف طلبتي',
                            onPressed: () async {
                              HapticFeedback.mediumImpact();
                              await prayerProv.deleteRequest(req.id);
                            },
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      req.title,
                      style: GoogleFonts.cairo(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w700,
                        color: p.ink,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      req.content,
                      style: GoogleFonts.cairo(
                        fontSize: 13.5,
                        color: p.inkMuted,
                        height: 1.55,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Divider(color: p.border, height: 1),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${req.prayedCount} صلوا لأجل هذا الأمر',
                          style: GoogleFonts.cairo(
                            fontSize: 11.5,
                            color: p.inkMuted,
                          ),
                        ),
                        InkWell(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            prayerProv.togglePrayed(req.id);
                          },
                          borderRadius: BorderRadius.circular(11),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 13, vertical: 7),
                            decoration: BoxDecoration(
                              color: req.hasPrayed ? p.accent : p.accentSoft,
                              borderRadius: BorderRadius.circular(11),
                              border: Border.all(
                                color: p.accent.withValues(alpha: 0.45),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  req.hasPrayed
                                      ? Icons.volunteer_activism_rounded
                                      : Icons.favorite_border_rounded,
                                  size: 15,
                                  color: req.hasPrayed ? p.onAccent : p.accent,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  req.hasPrayed
                                      ? 'صليت بالفعل'
                                      : 'صليت لأجل هذا الأمر',
                                  style: GoogleFonts.cairo(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                    color:
                                        req.hasPrayed ? p.onAccent : p.accent,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}
