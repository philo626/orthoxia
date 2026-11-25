import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/services/confession_service.dart';
import '../../core/services/coptic_calendar_service.dart';
import '../../core/services/coptic_fast_service.dart';
import '../../core/services/storage_service.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/coptic_cross.dart';
import '../../core/widgets/luxe_widgets.dart';
import '../../models/confession_models.dart';
import '../../models/katameros_model.dart';
import '../../providers/church_mode_provider.dart';
import '../../providers/liturgy_provider.dart';
import '../../providers/theme_provider.dart';
import '../liturgical/church_sacraments_rites_view.dart';
import '../liturgical/fractions_library_view.dart';
import '../liturgical/katameros_view.dart';
import '../liturgical/raising_of_incense_view.dart';
import '../liturgies/liturgy_reader_view.dart';
import '../profile/profile_settings_view.dart';
import '../search/global_search_view.dart';

/// Dedicated Sanctuary Home Screen for the Coptic Orthodox Priest («خدمتي اليوم»)
class PriestHomeDashboardView extends StatefulWidget {
  final void Function(int tab, {int? subTab}) onNavigateTab;

  const PriestHomeDashboardView({super.key, required this.onNavigateTab});

  @override
  State<PriestHomeDashboardView> createState() => _PriestHomeDashboardViewState();
}

class _PriestHomeDashboardViewState extends State<PriestHomeDashboardView> {
  final StorageService _storage = StorageService();
  final ConfessionService _confession = ConfessionService();
  KatamerosDay? _katameros;
  String _localCode = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final code = await _confession.ensureLocalPrivateCode();
    if (mounted) setState(() => _localCode = code);
    try {
      final raw = await rootBundle.loadString('assets/data/katameros.json');
      if (mounted) {
        setState(() => _katameros = KatamerosDay.fromJson(jsonDecode(raw)));
      }
    } catch (_) {}
  }

  String _priestGreetingName() {
    final raw = _storage.hasCustomUserName() ? _storage.getUserName() : '';
    final prefix = _storage.getPriestTitlePrefix();
    if (raw.isEmpty) return 'قدس أبونا';
    if (raw.startsWith('أبونا') || raw.startsWith('القس') || raw.startsWith('القمص')) {
      return raw;
    }
    return '$prefix $raw';
  }

  Future<void> _openLiturgy(String id, String title) async {
    await _storage.savePriestBookmark(
      bookKey: id,
      title: title,
      note: 'آخر موضع قراءة لقدسك في الكنيسة',
    );
    if (!mounted) return;
    final prov = context.read<LiturgyProvider>();
    await prov.loadLiturgies();
    prov.selectLiturgyById(id);
    if (!mounted) return;
    await Navigator.push(context, luxeRoute(const LiturgyReaderView()));
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final themeProv = context.watch<ThemeProvider>();
    final churchMode = context.watch<ChurchModeProvider>();
    final copticToday = CopticCalendarService.todayLiturgical();
    final fast = CopticFastService.getTodayFastStatus();
    final bookmark = _storage.getPriestBookmark();
    final churchName = _storage.getPriestChurch();
    final priestName = _priestGreetingName();

    return Scaffold(
      backgroundColor: p.canvas,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 10, 18, 36),
              children: [
                // 1. DIGNIFIED PRIESTLY MASTHEAD
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                      colors: p.isDark
                          ? const [Color(0xFF281F15), Color(0xFF1A1510)]
                          : const [Color(0xFF2D1C15), Color(0xFF1D130E)],
                    ),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: const Color(0xFFD8B46C).withValues(alpha: 0.45),
                      width: 1.1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: p.isDark ? 0.35 : 0.14),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFFE5C175).withValues(alpha: 0.16),
                              border: Border.all(
                                color: const Color(0xFFE5C175).withValues(alpha: 0.5),
                              ),
                            ),
                            child: const Center(
                              child: CopticCross(size: 22, color: Color(0xFFF3D591)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'سلام ونعمة يا $priestName',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.amiri(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFFFDF5E6),
                                    height: 1.15,
                                  ),
                                ),
                                Text(
                                  churchName.isNotEmpty
                                      ? churchName
                                      : '${copticToday.formatted} • ${copticToday.seasonName}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.cairo(
                                    fontSize: 11.5,
                                    color: const Color(0xFFD8C5A5),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            tooltip: 'بحث شامل',
                            onPressed: () => Navigator.push(
                              context,
                              luxeRoute(const GlobalSearchView()),
                            ),
                            icon: const Icon(Icons.search_rounded, color: Color(0xFFF3D591)),
                          ),
                          IconButton(
                            tooltip: 'الإعدادات والحساب',
                            onPressed: () async {
                              await Navigator.push(
                                context,
                                luxeRoute(const ProfileSettingsView()),
                              );
                              if (mounted) setState(() {});
                            },
                            icon: const Icon(Icons.tune_rounded, color: Color(0xFFF3D591)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _darkChip(
                            Icons.calendar_today_rounded,
                            '${copticToday.formatted} • ${copticToday.seasonName}',
                          ),
                          _darkChip(
                            Icons.spa_outlined,
                            !fast.isFastingToday
                                ? 'فطار'
                                : (fast.fishAllowed ? 'صوم بسمك' : 'صوم نباتي'),
                          ),
                          GestureDetector(
                            onTap: () => churchMode.toggleChurchMode(),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: churchMode.isChurchMode
                                    ? const Color(0xFFE5C175)
                                    : Colors.white.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: const Color(0xFFE5C175).withValues(alpha: 0.45),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.nights_stay_rounded,
                                    size: 14,
                                    color: churchMode.isChurchMode
                                        ? const Color(0xFF19130A)
                                        : const Color(0xFFF3D591),
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    churchMode.isChurchMode ? 'وضع المذبح مُفعّل' : 'وضع المذبح الصامت',
                                    style: GoogleFonts.cairo(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: churchMode.isChurchMode
                                          ? const Color(0xFF19130A)
                                          : const Color(0xFFF8EEDB),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () => themeProv.setThemeMode(
                              p.isDark ? AppThemeMode.lightParchment : AppThemeMode.darkGold,
                            ),
                            child: _darkChip(
                              p.isDark ? Icons.wb_sunny_outlined : Icons.dark_mode_outlined,
                              p.isDark ? 'نهاري' : 'ليلي',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // 2. RESUME ALTAR READING BOOKMARK (IF SAVED)
                if (bookmark != null && (bookmark['title']?.isNotEmpty ?? false)) ...[
                  PressScale(
                    scale: 0.985,
                    onTap: () => _openLiturgy(
                      bookmark['bookKey'] ?? 'liturgy_basil',
                      bookmark['title'] ?? 'القداس الباسيلي',
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: p.goldSoft,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: p.goldBorder),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.bookmark_added_rounded, color: p.gold, size: 22),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'أكمل من حيث توقفت: ${bookmark['title']}',
                                  style: GoogleFonts.cairo(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: p.ink,
                                  ),
                                ),
                                Text(
                                  'فتح فوري لآخر قداس أو صلاة قرأها قدسك',
                                  style: GoogleFonts.cairo(fontSize: 11, color: p.inkSecondary),
                                ),
                              ],
                            ),
                          ),
                          Icon(Icons.chevron_left_rounded, color: p.gold),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // 3. LIVE CONFESSION QUICK CARD + PRIVATE CODE SHARE
                StreamBuilder<PriestProfile?>(
                  stream: _confession.watchMyPriestProfile(),
                  builder: (context, snap) {
                    final prof = snap.data;
                    final displayCode = (prof?.privateCode.isNotEmpty ?? false)
                        ? prof!.privateCode
                        : _localCode;
                    final isVerified = prof?.isVerifiedPublic ?? false;

                    return Container(
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: p.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: p.goldBorder),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: p.goldSoft,
                                  borderRadius: BorderRadius.circular(11),
                                ),
                                child: Icon(Icons.qr_code_2_rounded, color: p.gold, size: 21),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          'كود أولاد اعتراف قدسك',
                                          style: GoogleFonts.cairo(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            color: p.ink,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        if (isVerified)
                                          Icon(Icons.verified_rounded, size: 16, color: p.sage),
                                      ],
                                    ),
                                    Text(
                                      'يبعته قدسك لأولاده فيدخلوا به على مواعيدك فوراً',
                                      style: GoogleFonts.cairo(fontSize: 11, color: p.inkMuted),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                                decoration: BoxDecoration(
                                  color: p.goldSoft,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: p.goldBorder),
                                ),
                                child: Text(
                                  displayCode.isNotEmpty ? displayCode : '—',
                                  style: GoogleFonts.cairo(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: p.ink,
                                    letterSpacing: 1.1,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () => widget.onNavigateTab(2),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: p.gold,
                                    foregroundColor: const Color(0xFF19130A),
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  icon: const Icon(Icons.event_available_rounded, size: 18),
                                  label: Text(
                                    'إدارة مواعيد الاعتراف',
                                    style: GoogleFonts.cairo(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              OutlinedButton.icon(
                                onPressed: displayCode.isEmpty
                                    ? null
                                    : () {
                                        HapticFeedback.lightImpact();
                                        SharePlus.instance.share(
                                          ShareParams(
                                            text: ConfessionService.buildConfessionChildrenShareText(
                                              priestFullName: prof?.fullDisplayName ?? priestName,
                                              church: prof?.church ?? churchName,
                                              privateCode: displayCode,
                                            ),
                                          ),
                                        );
                                      },
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: p.accent,
                                  side: BorderSide(color: p.goldBorder),
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                icon: const Icon(Icons.share_rounded, size: 17),
                                label: Text(
                                  'مشاركة الكود',
                                  style: GoogleFonts.cairo(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),

                const SizedBox(height: 20),

                // 4. SANCTUARY ALTAR TOOLS GRID (1-TAP TO EVERY PRIESTLY BOOK!)
                _sectionHeading(p, 'الخولاجي وأدوات المذبح السريعة', 'اضغط للفتح الفوري بصلوات الكاهن السرية'),
                const SizedBox(height: 10),

                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 1.85,
                  children: [
                    _sanctuaryTile(
                      p: p,
                      icon: Icons.church_rounded,
                      title: 'القداس الباسيلي',
                      sub: 'الخولاجي الكامل + الأواشي والسرية',
                      onTap: () => _openLiturgy('liturgy_basil', 'القداس الباسيلي'),
                    ),
                    _sanctuaryTile(
                      p: p,
                      icon: Icons.auto_awesome_rounded,
                      title: 'القداس الغريغوري',
                      sub: 'للأعياد السيدية الكبرى',
                      onTap: () => _openLiturgy('liturgy_gregory', 'القداس الغريغوري'),
                    ),
                    _sanctuaryTile(
                      p: p,
                      icon: Icons.menu_book_rounded,
                      title: 'القداس الكيرلسي',
                      sub: 'للأصوام وكيهك والصوم الكبير',
                      onTap: () => _openLiturgy('liturgy_cyril', 'القداس الكيرلسي'),
                    ),
                    _sanctuaryTile(
                      p: p,
                      icon: Icons.local_fire_department_rounded,
                      title: 'رفع بخور عشية وباكر',
                      sub: 'الخدمة الكاملة قبطي وعربي',
                      onTap: () => Navigator.push(context, luxeRoute(const RaisingOfIncenseView())),
                    ),
                    _sanctuaryTile(
                      p: p,
                      icon: Icons.format_list_bulleted_rounded,
                      title: 'صلوات القِسَم (٣٩)',
                      sub: 'قسمة كل عيد وموسم وصوم',
                      onTap: () => Navigator.push(context, luxeRoute(const FractionsLibraryView())),
                    ),
                    _sanctuaryTile(
                      p: p,
                      icon: Icons.volunteer_activism_rounded,
                      title: 'الأسرار والخدمات',
                      sub: 'المعمودية • الإكليل • القنديل • اللقان',
                      onTap: () => Navigator.push(context, luxeRoute(const ChurchSacramentsRitesView())),
                    ),
                  ],
                ),

                const SizedBox(height: 18),

                // 5. TODAY'S KATAMEROS & SYNAXARIUM CARD
                if (_katameros != null) ...[
                  PressScale(
                    scale: 0.985,
                    onTap: () => Navigator.push(
                      context,
                      luxeRoute(KatamerosView(katameros: _katameros!)),
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: p.surface,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: p.border),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: p.accentSoft,
                              borderRadius: BorderRadius.circular(13),
                            ),
                            child: Icon(Icons.auto_stories_rounded, color: p.accent, size: 22),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'قراءات اليوم • القطمارس والسنكسار',
                                  style: GoogleFonts.amiri(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: p.ink,
                                  ),
                                ),
                                Text(
                                  'إنجيل عشية وباكر، البولس والكاثوليكون والإبركسيس وإنجيل القداس',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.cairo(fontSize: 11.5, color: p.inkSecondary),
                                ),
                              ],
                            ),
                          ),
                          Icon(Icons.chevron_left_rounded, color: p.accent),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // 6. PASTORAL CARE SHORTCUTS (ALTAR NAMES • VISITATION • SERMON PREP)
                _sectionHeading(p, 'أدوات الرعاية الخاصة بقدسك', 'محفوظة ومشفرة على جهاز قدسك فقط بخصوصية كاملة'),
                const SizedBox(height: 10),

                Row(
                  children: [
                    Expanded(
                      child: _pastoralQuickCard(
                        p: p,
                        icon: Icons.favorite_outline_rounded,
                        title: 'على المذبح',
                        sub: 'المرضى والترحيم والأواشي',
                        onTap: () => widget.onNavigateTab(3, subTab: 0),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _pastoralQuickCard(
                        p: p,
                        icon: Icons.home_work_outlined,
                        title: 'دفتر الافتقاد',
                        sub: 'الأسر والمرضى والاتصال',
                        onTap: () => widget.onNavigateTab(3, subTab: 1),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _pastoralQuickCard(
                        p: p,
                        icon: Icons.edit_note_rounded,
                        title: 'تحضير العظات',
                        sub: 'كشكول عظات قدسك',
                        onTap: () => widget.onNavigateTab(3, subTab: 2),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _darkChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13.5, color: const Color(0xFFF3D591)),
          const SizedBox(width: 5),
          Text(
            label,
            style: GoogleFonts.cairo(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: const Color(0xFFF6ECDC),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeading(AppPalette p, String title, String sub) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.amiri(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: p.ink,
            height: 1.15,
          ),
        ),
        Text(
          sub,
          style: GoogleFonts.cairo(fontSize: 11.5, color: p.inkMuted),
        ),
      ],
    );
  }

  Widget _sanctuaryTile({
    required AppPalette p,
    required IconData icon,
    required String title,
    required String sub,
    required VoidCallback onTap,
  }) {
    return PressScale(
      scale: 0.97,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: p.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: p.border),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: p.goldSoft,
                borderRadius: BorderRadius.circular(11),
                border: Border.all(color: p.goldBorder.withValues(alpha: 0.6)),
              ),
              child: Icon(icon, size: 19, color: p.gold),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.cairo(
                      fontSize: 12.2,
                      fontWeight: FontWeight.bold,
                      color: p.ink,
                    ),
                  ),
                  Text(
                    sub,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.cairo(
                      fontSize: 9.8,
                      color: p.inkMuted,
                      height: 1.25,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pastoralQuickCard({
    required AppPalette p,
    required IconData icon,
    required String title,
    required String sub,
    required VoidCallback onTap,
  }) {
    return PressScale(
      scale: 0.96,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
        decoration: BoxDecoration(
          color: p.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: p.border),
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: p.goldSoft,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 20, color: p.gold),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: GoogleFonts.cairo(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: p.ink,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              sub,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: GoogleFonts.cairo(
                fontSize: 9.8,
                color: p.inkMuted,
                height: 1.25,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
