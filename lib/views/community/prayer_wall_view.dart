import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/prayer_wall_provider.dart';

class PrayerWallView extends StatelessWidget {
  const PrayerWallView({super.key});

  void _showAddPrayerDialog(BuildContext context) {
    final titleCtrl = TextEditingController();
    final contentCtrl = TextEditingController();
    final authorCtrl = TextEditingController();
    bool isAnonymous = true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            backgroundColor: AppColors.cardNavy,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text(
              'اطلب صلاة من الكنيسة',
              style: GoogleFonts.cairo(
                color: AppColors.primaryGold,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleCtrl,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'عنوان طلبة الصلاة (مثلاً: من أجل شفاء مريض)',
                      hintStyle: TextStyle(color: AppColors.textMuted.withOpacity(0.7), fontSize: 13),
                      filled: true,
                      fillColor: AppColors.surfaceNavy,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: contentCtrl,
                    maxLines: 4,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'اكتب تفاصيل الطلبة لتصلي الكنيسة معك...',
                      hintStyle: TextStyle(color: AppColors.textMuted.withOpacity(0.7), fontSize: 13),
                      filled: true,
                      fillColor: AppColors.surfaceNavy,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    activeThumbColor: AppColors.primaryGold,
                    title: Text(
                      'نشر بدون اسم (فاعل خير للسرية)',
                      style: GoogleFonts.cairo(color: AppColors.textLight, fontSize: 13),
                    ),
                    value: isAnonymous,
                    onChanged: (val) => setState(() => isAnonymous = val),
                  ),
                  if (!isAnonymous) ...[
                    const SizedBox(height: 8),
                    TextField(
                      controller: authorCtrl,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'اسمك الظاهر',
                        hintStyle: TextStyle(color: AppColors.textMuted.withOpacity(0.7), fontSize: 13),
                        filled: true,
                        fillColor: AppColors.surfaceNavy,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text('إلغاء', style: GoogleFonts.cairo(color: AppColors.textMuted)),
              ),
              ElevatedButton(
                onPressed: () {
                  if (titleCtrl.text.trim().isNotEmpty && contentCtrl.text.trim().isNotEmpty) {
                    Provider.of<PrayerWallProvider>(context, listen: false).addRequest(
                      title: titleCtrl.text.trim(),
                      content: contentCtrl.text.trim(),
                      isAnonymous: isAnonymous,
                      authorName: authorCtrl.text.trim(),
                    );
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('تم نشر طلبة صلاتك بنجاح. بركة الصلاة معك.', style: GoogleFonts.cairo()),
                        backgroundColor: AppColors.successGreen,
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGold,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: Text('نشر الطلبة', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PrayerWallProvider>(
      builder: (context, prayerProv, _) {
        final requests = prayerProv.requests;

        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _showAddPrayerDialog(context),
            backgroundColor: AppColors.primaryGold,
            foregroundColor: Colors.black,
            icon: const Icon(Icons.add_rounded),
            label: Text(
              'اطلب صلاة',
              style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
            ),
          ),
          body: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
            itemCount: requests.length,
            separatorBuilder: (_, __) => const SizedBox(height: 14),
            itemBuilder: (context, index) {
              final req = requests[index];
              return Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.cardNavy,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: req.hasPrayed
                        ? AppColors.primaryGold.withOpacity(0.5)
                        : Colors.white.withOpacity(0.08),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Author & Time
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.sacredBurgundy.withOpacity(0.3),
                              ),
                              child: const Icon(Icons.person_rounded, size: 16, color: AppColors.primaryGold),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              req.authorName,
                              style: GoogleFonts.cairo(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryGoldLight,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          'منذ ساعات',
                          style: GoogleFonts.cairo(fontSize: 11, color: AppColors.textMuted),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Title & Content
                    Text(
                      req.title,
                      style: GoogleFonts.cairo(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textLight,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      req.content,
                      style: GoogleFonts.cairo(
                        fontSize: 14,
                        color: AppColors.textLight.withOpacity(0.85),
                        height: 1.5,
                      ),
                    ),

                    const SizedBox(height: 16),
                    Divider(color: Colors.white.withOpacity(0.08), height: 1),
                    const SizedBox(height: 12),

                    // Interactive "صليت لأجل هذا الأمر" Button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${req.prayedCount} شخصاً صلوا لأجل هذا الأمر',
                          style: GoogleFonts.cairo(
                            fontSize: 12,
                            color: AppColors.textMuted,
                          ),
                        ),
                        InkWell(
                          onTap: () => prayerProv.togglePrayed(req.id),
                          borderRadius: BorderRadius.circular(12),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: req.hasPrayed
                                  ? AppColors.primaryGold
                                  : AppColors.primaryGold.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.primaryGold.withOpacity(0.5)),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  req.hasPrayed
                                      ? Icons.volunteer_activism_rounded
                                      : Icons.favorite_border_rounded,
                                  size: 16,
                                  color: req.hasPrayed ? Colors.black : AppColors.primaryGold,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  req.hasPrayed ? 'صليت بالفعل' : 'صليت لأجل هذا الأمر',
                                  style: GoogleFonts.cairo(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: req.hasPrayed ? Colors.black : AppColors.primaryGold,
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
