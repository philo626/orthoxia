import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../providers/theme_provider.dart';

class FloatingChurchBar extends StatefulWidget {
  const FloatingChurchBar({super.key});

  @override
  State<FloatingChurchBar> createState() => _FloatingChurchBarState();
}

class _FloatingChurchBarState extends State<FloatingChurchBar> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final themeProv = Provider.of<ThemeProvider>(context);
    final isAmoled = themeProv.mode == AppThemeMode.amoledChurch;

    return Positioned(
      bottom: 24,
      left: 20,
      right: 20,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isAmoled ? AppColors.amoledCard : AppColors.cardNavy.withOpacity(0.95),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: AppColors.primaryGold.withOpacity(_isExpanded ? 0.6 : 0.3),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.4),
              blurRadius: 16,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Top Bar: Toggle expand & quick controls
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.church_rounded,
                      size: 20,
                      color: isAmoled ? AppColors.primaryGold : AppColors.primaryGoldLight,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'وضع الكنيسة الهادئ',
                      style: GoogleFonts.cairo(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryGold,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    // Font Size Minus
                    IconButton(
                      icon: const Icon(Icons.text_decrease_rounded, size: 18),
                      color: AppColors.textLight,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => themeProv.decreaseFontSize(),
                    ),
                    const SizedBox(width: 12),
                    // Font Size Plus
                    IconButton(
                      icon: const Icon(Icons.text_increase_rounded, size: 18),
                      color: AppColors.textLight,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => themeProv.increaseFontSize(),
                    ),
                    const SizedBox(width: 12),
                    // Expand / Collapse Chevron
                    IconButton(
                      icon: Icon(
                        _isExpanded ? Icons.keyboard_arrow_down_rounded : Icons.tune_rounded,
                        size: 20,
                        color: AppColors.primaryGold,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => setState(() => _isExpanded = !_isExpanded),
                    ),
                  ],
                ),
              ],
            ),

            // Expanded Settings
            if (_isExpanded) ...[
              const SizedBox(height: 12),
              Divider(color: Colors.white.withOpacity(0.1), height: 1),
              const SizedBox(height: 10),

              // Brightness Slider
              Row(
                children: [
                  const Icon(Icons.brightness_low_rounded, size: 18, color: AppColors.primaryGold),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Slider(
                      value: themeProv.screenBrightness,
                      min: 0.1,
                      max: 1.0,
                      activeColor: AppColors.primaryGold,
                      inactiveColor: Colors.white.withOpacity(0.2),
                      onChanged: (val) => themeProv.setBrightness(val),
                    ),
                  ),
                  const Icon(Icons.brightness_high_rounded, size: 18, color: AppColors.primaryGold),
                ],
              ),

              // AMOLED pure black toggle & Keep Awake toggle
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  // AMOLED Button
                  TextButton.icon(
                    onPressed: () {
                      if (isAmoled) {
                        themeProv.setThemeMode(AppThemeMode.darkGold);
                      } else {
                        themeProv.setThemeMode(AppThemeMode.amoledChurch);
                      }
                    },
                    icon: Icon(
                      isAmoled ? Icons.check_circle_rounded : Icons.circle_outlined,
                      size: 16,
                      color: AppColors.primaryGold,
                    ),
                    label: Text(
                      'سواد تام (AMOLED)',
                      style: GoogleFonts.cairo(fontSize: 12, color: AppColors.textLight),
                    ),
                  ),

                  // Keep Screen Awake
                  TextButton.icon(
                    onPressed: () => themeProv.toggleKeepAwake(),
                    icon: Icon(
                      themeProv.keepAwake ? Icons.lock_open_rounded : Icons.lock_clock_rounded,
                      size: 16,
                      color: AppColors.primaryGold,
                    ),
                    label: Text(
                      themeProv.keepAwake ? 'الشاشة نشطة' : 'تلقائي',
                      style: GoogleFonts.cairo(fontSize: 12, color: AppColors.textLight),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
