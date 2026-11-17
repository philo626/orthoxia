import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';

class DynamicAgpeyaCard extends StatelessWidget {
  final VoidCallback onStartPrayer;

  const DynamicAgpeyaCard({super.key, required this.onStartPrayer});

  Map<String, String> _getCurrentHourDetails() {
    final now = DateTime.now();
    final hour = now.hour;

    if (hour >= 5 && hour < 11) {
      return {
        'name': 'صلاة باكر المباركة',
        'coptic': 'Ϯϣⲗⲏⲗ ⲛ̀ⲧⲉ ϩⲁⲛⲁⲧⲟⲟⲩⲉ',
        'subtitle': '«أيها النور الحقيقي الذي يضيء لكل إنسان آت إلى العالم»',
        'symbol': 'بداية النهار',
      };
    } else if (hour >= 11 && hour < 13) {
      return {
        'name': 'صلاة الساعة الثالثة',
        'coptic': 'Ϯϣⲗⲏⲗ ⲛ̀ⲧⲉ ϯⲁϫⲡ ϣⲟⲙⲧ',
        'subtitle': '«روحك القدوس يا رب... هذا لا تنزعه منا أيها الصالح»',
        'symbol': 'حلول الروح القدس',
      };
    } else if (hour >= 13 && hour < 15) {
      return {
        'name': 'صلاة الساعة السادسة',
        'coptic': 'Ϯϣⲗⲏⲗ ⲛ̀ⲧⲉ ϯⲁϫⲡ ⲥⲟ',
        'subtitle': '«يا من في اليوم السادس وفي وقت الساعة السادسة سمرت على الصليب»',
        'symbol': 'وقت الصلب',
      };
    } else if (hour >= 15 && hour < 17) {
      return {
        'name': 'صلاة الساعة التاسعة',
        'coptic': 'Ϯϣⲗⲏⲗ ⲛ̀ⲧⲉ ϯⲁϫⲡ ⲯⲓⲧ',
        'subtitle': '«يا من ذاق الموت بالجسد في وقت الساعة التاسعة من أجلنا»',
        'symbol': 'بذل الفادي',
      };
    } else if (hour >= 17 && hour < 20) {
      return {
        'name': 'صلاة الغروب',
        'coptic': 'Ϯϣⲗⲏⲗ ⲛ̀ⲧⲉ ⲣⲟⲩϩⲓ',
        'subtitle': '«نشكرك يا ملكنا ضابط الكل، لأنك جزت بنا هذا اليوم بسلام»',
        'symbol': 'المساء والشكر',
      };
    } else if (hour >= 20 && hour < 23) {
      return {
        'name': 'صلاة النوم',
        'coptic': 'Ϯϣⲗⲏⲗ ⲛ̀ⲧⲉ ⲡⲓⲕⲱⲧⲉ',
        'subtitle': '«هوذا أنا عتيد أن أقف أمام الديان العادل... لكن توبي يا نفسي»',
        'symbol': 'راحة وانسحاق',
      };
    } else {
      return {
        'name': 'صلاة نصف الليل',
        'coptic': 'Ϯϣⲗⲏⲗ ⲛ̀ⲧⲉ ⲧ̀ⲫⲁϣⲓ',
        'subtitle': '«ها هوذا العريس يأتي في نصف الليل، طوبى للعبد الذي يجده ساهراً»',
        'symbol': 'سهر الصلاة',
      };
    }
  }

  @override
  Widget build(BuildContext context) {
    final details = _getCurrentHourDetails();

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardNavy,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryGold.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.access_time_filled_rounded, size: 18, color: AppColors.primaryGold),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'الأجبية المقدسة - الصلاة الحالية',
                        style: GoogleFonts.cairo(
                          fontSize: 12,
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        details['name']!,
                        style: GoogleFonts.cairo(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textLight,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.surfaceNavy,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.primaryGold.withOpacity(0.3)),
                ),
                child: Text(
                  details['symbol']!,
                  style: GoogleFonts.cairo(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryGold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),
          Text(
            details['subtitle']!,
            style: GoogleFonts.cairo(
              fontSize: 13,
              color: AppColors.primaryGoldLight.withOpacity(0.9),
              fontStyle: FontStyle.italic,
              height: 1.4,
            ),
          ),

          const SizedBox(height: 16),

          ElevatedButton(
            onPressed: onStartPrayer,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.sacredBurgundy,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 44),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.play_arrow_rounded, size: 20),
                const SizedBox(width: 8),
                Text(
                  'ابدأ الصلاة الآن',
                  style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
