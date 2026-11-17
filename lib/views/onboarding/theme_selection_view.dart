import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/storage_service.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/theme_provider.dart';
import '../main_navigation_shell.dart';

class ThemeSelectionView extends StatefulWidget {
  const ThemeSelectionView({super.key});

  @override
  State<ThemeSelectionView> createState() => _ThemeSelectionViewState();
}

class _ThemeSelectionViewState extends State<ThemeSelectionView> {
  final StorageService _storage = StorageService();
  AppThemeMode _selected = AppThemeMode.darkGold;

  void _finish() async {
    final themeProv = Provider.of<ThemeProvider>(context, listen: false);
    themeProv.setThemeMode(_selected);
    await _storage.setOnboardingCompleted(true);

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const MainNavigationShell()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.deepNavy,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 30),
              Center(
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primaryGold.withOpacity(0.15),
                  ),
                  child: const Icon(Icons.palette_outlined, size: 36, color: AppColors.primaryGold),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'اختر مظهر القراءة المفضل',
                textAlign: TextAlign.center,
                style: GoogleFonts.cairo(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryGold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'يمكنك تغيير هذا الخيار لاحقاً في أي وقت من الإعدادات',
                textAlign: TextAlign.center,
                style: GoogleFonts.cairo(
                  fontSize: 14,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 40),

              // Option 1: Dark Gold
              _buildThemeOption(
                title: 'الوضع الليلي الكنسي (الافتراضي)',
                subtitle: 'ألوان وقورة هادئة مريحة للعين في الكنيسة والصلوات',
                mode: AppThemeMode.darkGold,
                icon: Icons.dark_mode_rounded,
                color: AppColors.deepNavy,
                borderColor: AppColors.primaryGold,
              ),

              const SizedBox(height: 16),

              // Option 2: Light Parchment
              _buildThemeOption(
                title: 'الوضع النهاري (ورق البردي)',
                subtitle: 'إضاءة واضحة ومتباينة للقراءة والدراسة النهارية',
                mode: AppThemeMode.lightParchment,
                icon: Icons.light_mode_rounded,
                color: AppColors.parchmentBg,
                borderColor: AppColors.sacredBurgundy,
                isLight: true,
              ),

              const Spacer(),

              // Confirm Button
              ElevatedButton(
                onPressed: _finish,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGold,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: Text(
                  'دخول التطبيق',
                  style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThemeOption({
    required String title,
    required String subtitle,
    required AppThemeMode mode,
    required IconData icon,
    required Color color,
    required Color borderColor,
    bool isLight = false,
  }) {
    final isSelected = _selected == mode;
    return GestureDetector(
      onTap: () => setState(() => _selected = mode),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.cardNavy,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primaryGold : Colors.white.withOpacity(0.1),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(color: borderColor, width: 1.5),
              ),
              child: Icon(icon, color: isLight ? AppColors.sacredBurgundy : AppColors.primaryGold, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.cairo(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textLight,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: GoogleFonts.cairo(
                      fontSize: 12,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              isSelected ? Icons.check_circle_rounded : Icons.radio_button_off_rounded,
              color: isSelected ? AppColors.primaryGold : AppColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}
