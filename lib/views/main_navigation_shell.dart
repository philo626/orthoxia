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
              color: const Color(0xFF0C0C0E).withValues(alpha: 0.96),
              border: Border(
                top: BorderSide(
                  color: AppColors.primaryGold.withValues(alpha: 0.22),
                  width: 1,
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.7),
                  blurRadius: 24,
                  offset: const Offset(0, -6),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: SizedBox(
                  height: 68,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildNavTab(
                        index: 0,
                        icon: Icons.home_rounded,
                        label: 'الرئيسية',
                      ),
                      _buildNavTab(
                        index: 1,
                        icon: Icons.nightlight_round,
                        label: 'الهيئة الآبائية',
                      ),
                      // Center Raised Champagne-Gold Circle Button (as in Video Frames 03, 05, 10, 11)
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
                          duration: const Duration(milliseconds: 260),
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: AppColors.champagne,
                            border: Border.all(
                              color: AppColors.primaryGoldLight,
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primaryGold.withValues(alpha: 0.45),
                                blurRadius: 18,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: Center(
                            child: isAudioPlaying
                                ? const Icon(
                                    Icons.pause_rounded,
                                    color: Color(0xFF1E160B),
                                    size: 28,
                                  )
                                : const CopticCross(
                                    size: 26,
                                    color: Color(0xFF1E160B),
                                  ),
                          ),
                        ),
                      ),
                      _buildNavTab(
                        index: 3,
                        icon: Icons.menu_book_rounded,
                        label: 'القداسات والصلوات',
                      ),
                      _buildNavTab(
                        index: 4,
                        icon: Icons.person_outline_rounded,
                        label: 'الشخصية',
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
