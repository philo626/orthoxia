import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../models/agpeya_model.dart';
import '../../providers/theme_provider.dart';
import 'widgets/floating_church_bar.dart';

class AgpeyaReaderView extends StatelessWidget {
  final AgpeyaHour hour;

  const AgpeyaReaderView({super.key, required this.hour});

  @override
  Widget build(BuildContext context) {
    final themeProv = Provider.of<ThemeProvider>(context);
    final fontScale = themeProv.fontScale;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Column(
          children: [
            Text(hour.nameAr, style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 18)),
            Text(
              hour.nameCoptic,
              style: GoogleFonts.cairo(fontSize: 12, color: AppColors.primaryGoldLight),
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          // Reader Content
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header Info Box
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.cardNavy,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.primaryGold.withOpacity(0.3)),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.wb_twilight_rounded, color: AppColors.primaryGold, size: 28),
                      const SizedBox(height: 8),
                      Text(
                        hour.theme,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.cairo(
                          fontSize: 14 * fontScale,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryGoldLight,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Sections loop
                for (var section in hour.sections) ...[
                  // Section Title
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 14),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.sacredBurgundy.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.primaryGold.withOpacity(0.3)),
                    ),
                    child: Text(
                      section.title,
                      style: GoogleFonts.cairo(
                        fontSize: 16 * fontScale,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryGold,
                      ),
                    ),
                  ),

                  // Section Text content
                  if (section.content != null) ...[
                    Text(
                      section.content!,
                      style: GoogleFonts.cairo(
                        fontSize: 16 * fontScale,
                        color: AppColors.textLight,
                        height: 1.8,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Psalms if any
                  if (section.psalms != null) ...[
                    for (var psalm in section.psalms!) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          psalm.title,
                          style: GoogleFonts.cairo(
                            fontSize: 15 * fontScale,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryGoldLight,
                          ),
                        ),
                      ),
                      Text(
                        psalm.text,
                        style: GoogleFonts.cairo(
                          fontSize: 15 * fontScale,
                          color: AppColors.textLight.withOpacity(0.95),
                          height: 1.8,
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],
                  ],
                ],

                const SizedBox(height: 40),
                Center(
                  child: Text(
                    'المجد للثالوث الأقدس دائماً وأبداً. آمين.',
                    style: GoogleFonts.cairo(
                      fontSize: 14 * fontScale,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryGold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Floating Church Bar (Brightness, AMOLED, Font Scale)
          const FloatingChurchBar(),
        ],
      ),
    );
  }
}
