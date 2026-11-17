import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/firebase_service.dart';
import '../../core/services/notification_service.dart';
import '../../core/services/patron_saint_service.dart';
import '../../core/services/storage_service.dart';
import '../../core/widgets/coptic_cross.dart';

class MyPatronSaintView extends StatefulWidget {
  const MyPatronSaintView({super.key});

  @override
  State<MyPatronSaintView> createState() => _MyPatronSaintViewState();
}

class _MyPatronSaintViewState extends State<MyPatronSaintView> {
  final StorageService _storage = StorageService();
  late String _selectedSaintId;

  @override
  void initState() {
    super.initState();
    _selectedSaintId = _storage.getPatronSaintId();
  }

  Future<void> _chooseSaint(PatronSaintProfile saint) async {
    HapticFeedback.mediumImpact();
    setState(() => _selectedSaintId = saint.id);
    await _storage.setPatronSaintId(saint.id);
    await FirebaseService().syncPublicProfile(
      displayName: _storage.getUserName(),
      patronSaintId: saint.id,
    );
    await NotificationService().syncScheduledNotifications();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'تم اختيار «${saint.shortName}» شفيعاً شخصياً لك! ستظهر أقواله ورسائله لك يومياً ✝️',
          style: GoogleFonts.cairo(fontSize: 12.5),
        ),
        backgroundColor: AppColors.cardNavy,
      ),
    );
  }

  void _openSaintPickerSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(ctx).size.height * 0.78,
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 20),
        decoration: const BoxDecoration(
          color: Color(0xFF13151D),
          borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
          border: Border(top: BorderSide(color: AppColors.primaryGold, width: 1.5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.primaryGold.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'اختر قديسك وشفيعك الشخصي',
              textAlign: TextAlign.center,
              style: GoogleFonts.cairo(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryGoldLight,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'سيظهر لك يومياً قول وتعليم وصلوة خاصة من شفيعك المختار على الشاشة الرئيسية',
              textAlign: TextAlign.center,
              style: GoogleFonts.cairo(fontSize: 12, color: AppColors.textMuted),
            ),
            const SizedBox(height: 14),
            Expanded(
              child: ListView.separated(
                itemCount: PatronSaintService.saints.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (c, idx) {
                  final s = PatronSaintService.saints[idx];
                  final isSel = s.id == _selectedSaintId;
                  return Material(
                    type: MaterialType.transparency,
                    child: ListTile(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: BorderSide(
                          color: isSel
                              ? AppColors.primaryGold
                              : AppColors.primaryGold.withValues(alpha: 0.18),
                          width: isSel ? 1.5 : 0.8,
                        ),
                      ),
                      tileColor: isSel
                          ? AppColors.primaryGold.withValues(alpha: 0.14)
                          : AppColors.cardNavy,
                      leading: CircleAvatar(
                        backgroundColor: AppColors.primaryGold.withValues(alpha: 0.18),
                        child: Text(s.iconEmoji, style: const TextStyle(fontSize: 20)),
                      ),
                      title: Text(
                        s.name,
                        style: GoogleFonts.cairo(
                          fontSize: 13.5,
                          fontWeight: FontWeight.bold,
                          color: isSel ? AppColors.primaryGoldLight : Colors.white,
                        ),
                      ),
                      subtitle: Text(
                        s.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.cairo(fontSize: 11, color: AppColors.textMuted),
                      ),
                      trailing: isSel
                          ? const Icon(Icons.check_circle_rounded, color: AppColors.primaryGold)
                          : const Icon(Icons.radio_button_unchecked, color: AppColors.textMuted, size: 18),
                      onTap: () {
                        Navigator.pop(ctx);
                        _chooseSaint(s);
                      },
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
    final saint = PatronSaintService.getSaintById(_selectedSaintId);
    final todayQuote = PatronSaintService.getDailyQuote(saint.id);

    return Scaffold(
      backgroundColor: AppColors.deepNavy,
      appBar: AppBar(
        backgroundColor: AppColors.deepNavy,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'شفيعي الشخصي وأقواله اليومية',
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 16.5),
        ),
        actions: [
          TextButton.icon(
            onPressed: _openSaintPickerSheet,
            icon: const Icon(Icons.swap_horiz_rounded, color: AppColors.primaryGold, size: 18),
            label: Text(
              'تغيير الشفيع',
              style: GoogleFonts.cairo(
                color: AppColors.primaryGold,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 36),
        children: [
          // 1. Saint Hero Banner
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2B2012), Color(0xFF14151C)],
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.primaryGold, width: 1.4),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryGold.withValues(alpha: 0.16),
                  blurRadius: 18,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  width: 68,
                  height: 68,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primaryGold.withValues(alpha: 0.16),
                    border: Border.all(color: AppColors.primaryGold, width: 1.5),
                  ),
                  child: Text(saint.iconEmoji, style: const TextStyle(fontSize: 32)),
                ),
                const SizedBox(height: 12),
                Text(
                  saint.name,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.cairo(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryGoldLight,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  saint.title,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.cairo(fontSize: 12.5, color: Colors.white70),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primaryGold.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'تذكار العيد: ${saint.feastDate}',
                    style: GoogleFonts.cairo(
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryGold,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _openSaintPickerSheet,
                  icon: const Icon(Icons.auto_awesome_rounded, size: 16, color: AppColors.primaryGold),
                  label: Text(
                    'اختر شفيعاً آخر من الـ ١٢ قديساً',
                    style: GoogleFonts.cairo(color: AppColors.primaryGoldLight, fontSize: 12),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: AppColors.primaryGold.withValues(alpha: 0.45)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 350.ms).slideY(begin: 0.05, end: 0),

          const SizedBox(height: 18),

          // 2. Today's Daily Message Card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.cardNavy,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.primaryGold.withValues(alpha: 0.55), width: 1.2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const CopticCross(size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'رسالة وقول شفيعك لك اليوم',
                      style: GoogleFonts.cairo(
                        fontSize: 14.5,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryGold,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primaryGold.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'يتجدد يومياً',
                        style: GoogleFonts.cairo(fontSize: 10.5, color: AppColors.primaryGoldLight),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  '«${todayQuote.quote}»',
                  style: GoogleFonts.cairo(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    height: 1.65,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '💡 تدريب اليوم: ${todayQuote.lesson}',
                    style: GoogleFonts.cairo(fontSize: 12.5, height: 1.55, color: AppColors.textLight),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  '🙏 ${todayQuote.prayer}',
                  style: GoogleFonts.cairo(
                    fontSize: 12.5,
                    fontStyle: FontStyle.italic,
                    color: AppColors.primaryGoldLight,
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () {
                        Clipboard.setData(ClipboardData(
                          text: '«${todayQuote.quote}»\n— ${saint.name}\n\n${todayQuote.prayer}',
                        ));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('تم نسخ قول شفيعك اليوم', style: GoogleFonts.cairo())),
                        );
                      },
                      icon: const Icon(Icons.copy_rounded, size: 15, color: AppColors.primaryGold),
                      label: Text('نسخ', style: GoogleFonts.cairo(color: AppColors.primaryGold, fontSize: 12)),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: AppColors.primaryGold.withValues(alpha: 0.4)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: () {
                        SharePlus.instance.share(
                          ShareParams(
                            text: '✝ رسالة شفيعي اليوم (${saint.name}):\n\n«${todayQuote.quote}»\n\n💡 ${todayQuote.lesson}\n🙏 ${todayQuote.prayer}\n\nمن تطبيق أرثوذكسيا',
                          ),
                        );
                      },
                      icon: const Icon(Icons.share_rounded, size: 15, color: Colors.black),
                      label: Text('مشاركة', style: GoogleFonts.cairo(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryGold,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          // 3. Intercession Prayer (طلبة الشفاعة)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF1D1914),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.primaryGold.withValues(alpha: 0.35)),
            ),
            child: Row(
              children: [
                const CopticCross(size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    saint.intercessionPrayer,
                    style: GoogleFonts.cairo(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryGoldLight,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // 4. All Sayings of This Saint
          Text(
            'مختارات من أقوال وتعاليم ${saint.shortName}:',
            style: GoogleFonts.cairo(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryGoldLight,
            ),
          ),
          const SizedBox(height: 10),
          ...saint.quotes.map((q) => Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.cardNavy,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '«${q.quote}»',
                      style: GoogleFonts.cairo(
                        fontSize: 13.5,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      q.lesson,
                      style: GoogleFonts.cairo(fontSize: 12, color: AppColors.textMuted),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}
