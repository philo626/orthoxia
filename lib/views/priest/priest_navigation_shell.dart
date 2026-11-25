import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/services/confession_service.dart';
import '../../core/theme/app_palette.dart';
import '../books/scripture_library_hub_view.dart';
import '../confession/priest_dashboard_view.dart';
import 'priest_altar_hub_view.dart';
import 'priest_home_dashboard_view.dart';
import 'priest_pastoral_care_view.dart';

/// Dedicated Coptic Orthodox Priest App Shell («أرثوذكسيا • بوابة الأب الكاهن»):
/// Launches automatically when a Priest signs in — replacing the congregation shell
/// with 5 sanctuary & pastoral tabs engineered specifically for priestly ministry:
///   0: خدمتي (Altar Dashboard, Today's Readings, Quick Liturgies, Next Confession)
///   1: المذبح (Full Euchologion/Khoulagy, Raising of Incense, 39 Fractions, Sacraments, Pascha, Agpeya)
///   2: الاعترافات (Private Code AB-XXXX, Confession Sessions, Live Attendee List, Peer-Priest Vouching)
///   3: الرعاية (Altar Commemoration Names, Encrypted Visitation Log, Sermon Prep Notebook)
///   4: المكتبة (Full Bible, 73 Audited Commentaries, 242 Visual Page-by-Page Patristic Books)
class PriestNavigationShell extends StatefulWidget {
  final int initialIndex;
  const PriestNavigationShell({super.key, this.initialIndex = 0});

  @override
  State<PriestNavigationShell> createState() => _PriestNavigationShellState();
}

class _PriestNavigationShellState extends State<PriestNavigationShell> {
  late int _currentIndex;
  final ValueNotifier<int> _altarSubTab = ValueNotifier<int>(0);
  final ValueNotifier<int> _pastoralSubTab = ValueNotifier<int>(0);
  final ValueNotifier<int> _librarySubTab = ValueNotifier<int>(0);

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex.clamp(0, 4);
    ConfessionService().startPriestRealtimeAlertListener();
  }

  @override
  void dispose() {
    ConfessionService().stopPriestRealtimeAlertListener();
    _altarSubTab.dispose();
    _pastoralSubTab.dispose();
    _librarySubTab.dispose();
    super.dispose();
  }

  void _navigateToTab(int index, {int? subTab}) {
    HapticFeedback.selectionClick();
    final clamped = index.clamp(0, 4);
    if (clamped == 1 && subTab != null) {
      _altarSubTab.value = subTab.clamp(0, 3);
    } else if (clamped == 3 && subTab != null) {
      _pastoralSubTab.value = subTab.clamp(0, 2);
    } else if (clamped == 4 && subTab != null) {
      _librarySubTab.value = subTab.clamp(0, 3);
    }
    setState(() => _currentIndex = clamped);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final screens = [
      PriestHomeDashboardView(
        onNavigateTab: (tab, {int? subTab}) => _navigateToTab(tab, subTab: subTab),
      ),
      PriestAltarHubView(externalTabNotifier: _altarSubTab),
      const PriestDashboardView(embeddedInShell: true),
      PriestPastoralCareView(externalTabNotifier: _pastoralSubTab),
      ScriptureLibraryHubView(externalTabNotifier: _librarySubTab),
    ];

    return Scaffold(
      backgroundColor: p.canvas,
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: p.surface,
          border: Border(
            top: BorderSide(color: p.goldBorder.withValues(alpha: 0.7), width: 1),
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
          child: Center(
            heightFactor: 1,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 680),
              child: SizedBox(
                height: 66,
                child: Row(
                  children: [
                    _navItem(
                      p: p,
                      index: 0,
                      icon: Icons.church_outlined,
                      activeIcon: Icons.church_rounded,
                      label: 'خدمتي',
                    ),
                    _navItem(
                      p: p,
                      index: 1,
                      icon: Icons.auto_stories_outlined,
                      activeIcon: Icons.auto_stories_rounded,
                      label: 'المذبح',
                    ),
                    _navItem(
                      p: p,
                      index: 2,
                      icon: Icons.event_available_outlined,
                      activeIcon: Icons.event_available_rounded,
                      label: 'الاعترافات',
                    ),
                    _navItem(
                      p: p,
                      index: 3,
                      icon: Icons.volunteer_activism_outlined,
                      activeIcon: Icons.volunteer_activism_rounded,
                      label: 'الرعاية',
                    ),
                    _navItem(
                      p: p,
                      index: 4,
                      icon: Icons.menu_book_outlined,
                      activeIcon: Icons.menu_book_rounded,
                      label: 'المكتبة',
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _navItem({
    required AppPalette p,
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
  }) {
    final selected = _currentIndex == index;
    final activeColor = p.gold;
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
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 4),
              decoration: BoxDecoration(
                color: selected ? p.goldSoft : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                border: selected ? Border.all(color: p.goldBorder, width: 0.9) : null,
              ),
              child: Icon(
                selected ? activeIcon : icon,
                size: 21,
                color: selected ? activeColor : p.inkMuted,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.cairo(
                fontSize: 10.8,
                fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                color: selected ? p.ink : p.inkMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
