import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/katameros_model.dart';
import 'share_verse_dialog.dart';

class MiniKatamerosCard extends StatelessWidget {
  final KatamerosDay katameros;
  final VoidCallback onOpenFullReadings;

  const MiniKatamerosCard({
    super.key,
    required this.katameros,
    required this.onOpenFullReadings,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.cardNavy,
            AppColors.surfaceNavy,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primaryGold.withOpacity(0.3), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Date & Season Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_rounded, size: 14, color: AppColors.primaryGold),
                      const SizedBox(width: 6),
                      Text(
                        katameros.dateCoptic,
                        style: GoogleFonts.cairo(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryGold,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    katameros.dateGregorian,
                    style: GoogleFonts.cairo(
                      fontSize: 12,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: katameros.fastingInfo.isFasting
                      ? AppColors.fastingPurple.withOpacity(0.2)
                      : AppColors.sacredBurgundy.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: katameros.fastingInfo.isFasting
                        ? AppColors.fastingPurple.withOpacity(0.5)
                        : AppColors.primaryGold.withOpacity(0.4),
                  ),
                ),
                child: Text(
                  katameros.fastingInfo.seasonName,
                  style: GoogleFonts.cairo(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryGoldLight,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
          Divider(color: Colors.white.withOpacity(0.08), height: 1),
          const SizedBox(height: 14),

          // Verse of the Day
          Text(
            'آية اليوم المختارة',
            style: GoogleFonts.cairo(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '«${katameros.verseOfTheDay.text}»',
            style: GoogleFonts.cairo(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppColors.textLight,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              katameros.verseOfTheDay.reference,
              style: GoogleFonts.cairo(
                fontSize: 12,
                color: AppColors.primaryGold,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Action Buttons: Share & View Full
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (_) => ShareVerseDialog(
                        verseText: katameros.verseOfTheDay.text,
                        reference: katameros.verseOfTheDay.reference,
                        copticText: katameros.verseOfTheDay.copticText,
                      ),
                    );
                  },
                  icon: const Icon(Icons.image_outlined, size: 16, color: AppColors.primaryGold),
                  label: Text(
                    'مشاركة كصورة',
                    style: GoogleFonts.cairo(fontSize: 13, color: AppColors.primaryGold),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: AppColors.primaryGold.withOpacity(0.4)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onOpenFullReadings,
                  icon: const Icon(Icons.auto_stories_rounded, size: 16),
                  label: Text(
                    'قراءات اليوم',
                    style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGold,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
