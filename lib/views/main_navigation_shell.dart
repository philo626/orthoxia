import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_palette.dart';
import '../providers/audio_provider.dart';
import 'ai_companion/ai_companion_view.dart';
import 'books/scripture_library_hub_view.dart';
import 'home/home_dashboard_view.dart';
import 'hymns/hymns_library_view.dart';
import 'liturgical/liturgical_hub_view.dart';

class MainNavigationShell extends StatefulWidget {
  const MainNavigationShell({super.key});

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  int _currentIndex = 0;
  final ValueNotifier<int> _liturgicalSubTab = ValueNotifier<int>(0);
  final ValueNotifier<int> _librarySubTab = ValueNotifier<int>(0);

  @override
  void dispose() {
    _liturgicalSubTab.dispose();
    _librarySubTab.dispose();
    super.dispose();
  }

  void _navigateToTab(int index, {int? subTab}) {
    HapticFeedback.selectionClick();
    final clamped = index.clamp(0, 4);
    if (clamped == 1 && subTab != null) {
      _liturgicalSubTab.value = subTab.clamp(0, 3);
    } else if (clamped == 2 && subTab != null) {
      _librarySubTab.value = subTab.clamp(0, 3);
    }
    setState(() => _currentIndex = clamped);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final screens = [
      HomeDashboardView(
        onNavigateTab: (tab, {int? subTab}) => _navigateToTab(tab, subTab: subTab),
      ),
      LiturgicalHubView(externalTabNotifier: _liturgicalSubTab),
      ScriptureLibraryHubView(externalTabNotifier: _librarySubTab),
      const HymnsLibraryView(),
      const AiCompanionView(),
    ];

    return Scaffold(
      backgroundColor: p.canvas,
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: Consumer<AudioProvider>(
        builder: (context, audioProv, _) {
          final isAudioPlaying = audioProv.isPlaying;
          return Container(
            decoration: BoxDecoration(
              color: p.surface,
              border: Border(
                top: BorderSide(color: p.border, width: 0.9),
              ),
              boxShadow: [
                BoxShadow(
                  color: p.shadow,
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
                  height: 64,
                  child: Row(
                    children: [
                      _buildNavTab(
                        p: p,
                        index: 0,
                        icon: Icons.home_outlined,
                        activeIcon: Icons.home_rounded,
                        label: 'الرئيسية',
                      ),
                      _buildNavTab(
                        p: p,
                        index: 1,
                        icon: Icons.church_outlined,
                        activeIcon: Icons.church_rounded,
                        label: 'الصلوات',
                      ),
                      _buildNavTab(
                        p: p,
                        index: 2,
                        icon: Icons.menu_book_outlined,
                        activeIcon: Icons.menu_book_rounded,
                        label: 'المكتبة',
                      ),
                      _buildNavTab(
                        p: p,
                        index: 3,
                        icon: Icons.music_note_outlined,
                        activeIcon: Icons.graphic_eq_rounded,
                        label: 'الألحان',
                        liveDot: isAudioPlaying,
                      ),
                      _buildNavTab(
                        p: p,
                        index: 4,
                        icon: Icons.forum_outlined,
                        activeIcon: Icons.forum_rounded,
                        label: 'المرشد',
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
    required AppPalette p,
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
    bool liveDot = false,
  }) {
    final selected = _currentIndex == index;
    final activeColor = p.accent;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _navigateToTab(index),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: selected
                    ? p.accent.withValues(alpha: p.isDark ? 0.16 : 0.1)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(
                    selected ? activeIcon : icon,
                    size: 22,
                    color: selected ? activeColor : p.inkMuted,
                  ),
                  if (liveDot)
                    Positioned(
                      top: -2,
                      left: -3,
                      child: Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: p.crimson,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.cairo(
                fontSize: 11,
                fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                color: selected ? activeColor : p.inkMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
