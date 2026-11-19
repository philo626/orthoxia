import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_colors.dart';
import '../core/widgets/coptic_cross.dart';
import '../providers/audio_provider.dart';
import 'home/home_dashboard_view.dart';
import 'liturgical/liturgical_hub_view.dart';
import 'hymns/hymns_library_view.dart';
import 'ai_companion/ai_companion_view.dart';
import 'profile/profile_settings_view.dart';

class MainNavigationShell extends StatefulWidget {
  const MainNavigationShell({super.key});

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  int _currentIndex = 0;

  void _navigateToTab(int index) {
    HapticFeedback.selectionClick();
    setState(() => _currentIndex = index.clamp(0, 4));
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      HomeDashboardView(onNavigateTab: _navigateToTab),
      const AiCompanionView(),
      const HymnsLibraryView(),
      const LiturgicalHubView(),
      const ProfileSettingsView(),
    ];

    return Scaffold(
      extendBody: true,
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: Consumer<AudioProvider>(
        builder: (context, audioProv, _) {
          final isAudioPlaying = audioProv.isPlaying;
          return Container(
            decoration: BoxDecoration(
              color: AppColors.deepNavy.withValues(alpha: 0.97),
              border: const Border(
                top: BorderSide(
                  color: AppColors.hairline,
                  width: 0.9,
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.5),
                  blurRadius: 16,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: SizedBox(
                  height: 66,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildNavTab(
                        index: 0,
                        icon: Icons.home_outlined,
                        label: 'الرئيسية',
                      ),
                      _buildNavTab(
                        index: 1,
                        icon: Icons.auto_stories_outlined,
                        label: 'الهيئة الآبائية',
                      ),
                      // Center Refined Antique-Gold Coptic Medallion
                      GestureDetector(
                        onTap: () {
                          HapticFeedback.mediumImpact();
                          if (isAudioPlaying && _currentIndex == 2) {
                            audioProv.pause();
                          } else {
                            _navigateToTab(2);
                          }
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 240),
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _currentIndex == 2 ? AppColors.primaryGold : AppColors.cardNavy,
                            border: Border.all(
                              color: AppColors.primaryGold.withValues(alpha: 0.7),
                              width: 1.2,
                            ),
                          ),
                          child: Center(
                            child: isAudioPlaying
                                ? Icon(
                                    Icons.pause_rounded,
                                    color: _currentIndex == 2 ? const Color(0xFF1A140B) : AppColors.primaryGoldLight,
                                    size: 24,
                                  )
                                : CopticCross(
                                    size: 22,
                                    color: _currentIndex == 2 ? const Color(0xFF1A140B) : AppColors.primaryGoldLight,
                                  ),
                          ),
                        ),
                      ),
                      _buildNavTab(
                        index: 3,
                        icon: Icons.menu_book_outlined,
                        label: 'القداسات',
                      ),
                      _buildNavTab(
                        index: 4,
                        icon: Icons.person_outline_rounded,
                        label: 'حسابي',
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildNavTab({
    required int index,
    required IconData icon,
    required String label,
  }) {
    final selected = _currentIndex == index;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _navigateToTab(index),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Top gold indicator line on active tab (matches video bottom bar)
            AnimatedContainer(
              duration: const Duration(milliseconds: 240),
              width: selected ? 28 : 0,
              height: 2.5,
              margin: const EdgeInsets.only(bottom: 6),
              decoration: BoxDecoration(
                color: AppColors.primaryGold,
                borderRadius: BorderRadius.circular(2),
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color: AppColors.primaryGold.withValues(alpha: 0.6),
                          blurRadius: 8,
                        ),
                      ]
                    : null,
              ),
            ),
            Icon(
              icon,
              size: 22,
              color: selected ? AppColors.primaryGoldLight : AppColors.textMuted,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.cairo(
                fontSize: 10.5,
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                color: selected ? AppColors.primaryGoldLight : AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
