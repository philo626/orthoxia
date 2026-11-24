import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/services/coptic_calendar_service.dart';
import '../../core/theme/app_palette.dart';
import '../../core/widgets/luxe_widgets.dart';
import '../../models/katameros_model.dart';
import '../../providers/liturgy_provider.dart';
import '../home/spiritual_prescription_view.dart';
import '../liturgies/liturgy_reader_view.dart';
import '../prayer_rope/coptic_prayer_rope_view.dart';
import '../search/global_search_view.dart';
import '../synaxarium/synaxarium_daily_view.dart';
import 'agpeya_view.dart';
import 'church_sacraments_rites_view.dart';
import 'fractions_library_view.dart';
import 'katameros_view.dart';
import 'raising_of_incense_view.dart';
import 'remember_them_view.dart';
import 'tasbeha_pascha_view.dart';

/// Unified 4-Tab Worship Sanctuary («الصلوات والقداسات»):
/// Tab 0: القداسات (3 Liturgies + Daily Readings + Personal Prayer Companions)
/// Tab 1: الأجبية (All 8 canonical hours + Real Alarms directly embedded)
/// Tab 2: التسبحة والبصخة (Full Midnight Praise + 7-Day Pascha + All Feasts)
/// Tab 3: الطقوس والأسرار (8 Complete Church Rites & Sacraments)
class LiturgicalHubView extends StatefulWidget {
  final ValueNotifier<int>? externalTabNotifier;

  const LiturgicalHubView({super.key, this.externalTabNotifier});

  @override
  State<LiturgicalHubView> createState() => _LiturgicalHubViewState();
}

class _LiturgicalHubViewState extends State<LiturgicalHubView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  KatamerosDay? _katameros;

  @override
  void initState() {
    super.initState();
    final initial = (widget.externalTabNotifier?.value ?? 0).clamp(0, 3);
    _tabController = TabController(length: 4, vsync: this, initialIndex: initial);
    widget.externalTabNotifier?.addListener(_onExternalTabRequest);
    _loadKatameros();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LiturgyProvider>().loadLiturgies();
    });
  }

  void _onExternalTabRequest() {
    final target = (widget.externalTabNotifier?.value ?? 0).clamp(0, 3);
    if (_tabController.index != target) {
      _tabController.animateTo(target);
    }
  }

  @override
  void dispose() {
    widget.externalTabNotifier?.removeListener(_onExternalTabRequest);
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadKatameros() async {
    try {
      final raw = await rootBundle.loadString('assets/data/katameros.json');
      if (mounted) {
        setState(() {
          _katameros = KatamerosDay.fromJson(jsonDecode(raw));
        });
      }
    } catch (_) {}
  }

  void _openLiturgyById(BuildContext context, String id) async {
    final prov = context.read<LiturgyProvider>();
    await prov.loadLiturgies();
    prov.selectLiturgyById(id);
    if (!context.mounted) return;
    Navigator.push(context, luxeRoute(const LiturgyReaderView()));
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final copticToday = CopticCalendarService.todayLiturgical();

    return Scaffold(
      backgroundColor: p.canvas,
      body: SafeArea(
        child: Column(
          children: [
            // Clean Masthead
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'الصلوات والقداسات',
                          style: GoogleFonts.amiri(
                            fontSize: 27,
                            fontWeight: FontWeight.bold,
                            color: p.ink,
                            height: 1.15,
                          ),
                        ),
                        Text(
                          '${copticToday.formatted} • ${copticToday.seasonName}',
                          style: GoogleFonts.cairo(fontSize: 12, color: p.inkSecondary),
                        ),
                      ],
                    ),
                  ),
                  LuxeCircleButton(
                    icon: Icons.search_rounded,
                    size: 38,
                    tooltip: 'بحث شامل',
                    onTap: () => Navigator.push(context, luxeRoute(const GlobalSearchView())),
                  ),
                ],
              ),
            ),

            // 4-Tab Direct Worship Switcher (Everything 1 tap away!)
            Container(
              decoration: BoxDecoration(
                color: p.canvas,
                border: Border(bottom: BorderSide(color: p.border, width: 0.9)),
              ),
              child: TabBar(
                controller: _tabController,
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                indicatorColor: p.accent,
                indicatorWeight: 2.5,
                labelColor: p.accent,
                unselectedLabelColor: p.inkMuted,
                labelStyle: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.bold),
                unselectedLabelStyle: GoogleFonts.cairo(fontSize: 12.5, fontWeight: FontWeight.w600),
                padding: const EdgeInsets.symmetric(horizontal: 10),
                tabs: const [
                  Tab(text: 'القداسات والقراءات'),
                  Tab(text: 'الأجبية'),
                  Tab(text: 'التسبحة والبصخة'),
                  Tab(text: 'الطقوس والأسرار'),
                ],
              ),
            ),

            Expanded(
              child: TabBarView(
                controller: _tabController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildLiturgiesAndDailyTab(p),
                  const AgpeyaView(),
                  const TasbehaPaschaView(embedded: true),
                  const ChurchSacramentsRitesView(embedded: true),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLiturgiesAndDailyTab(AppPalette p) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 36),
          children: [
            // SECTION 1: THE THREE DIVINE LITURGIES (KHOLAGY)
            _sectionHeading(p, 'الخولاجي المقدس (القداسات الثلاثة)'),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _liturgyMiniCard(
                    p: p,
                    image: 'assets/images/thumb_basil.jpg',
                    title: 'الباسيلي',
                    subtitle: 'الأكثر استخداماً',
                    onTap: () => _openLiturgyById(context, 'liturgy_basil'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _liturgyMiniCard(
                    p: p,
                    image: 'assets/images/thumb_gregory.jpg',
                    title: 'الغريغوري',
                    subtitle: 'للأعياد السيدية',
                    onTap: () => _openLiturgyById(context, 'liturgy_gregory'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _liturgyMiniCard(
                    p: p,
                    image: 'assets/images/thumb_cyril.jpg',
                    title: 'الكيرلسي',
                    subtitle: 'قداس مارمرقس',
                    onTap: () => _openLiturgyById(context, 'liturgy_cyril'),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Companion Kholagy Services (Raising of Incense + 39 Seasonal Fractions)
            _groupedCard(p, [
              _hubRow(
                p: p,
                icon: Icons.local_fire_department_outlined,
                title: 'رفع بخور عشية وباكر كاملاً',
                subtitle: 'الشكر • أرباع الناقوس • الأواشي • أجيوس • الذكصولوجيات • التحاليل',
                onTap: () => Navigator.push(context, luxeRoute(const RaisingOfIncenseView())),
              ),
              _hubRow(
                p: p,
                icon: Icons.auto_awesome_outlined,
                title: 'صلوات القِسَم (٣٩ قسمة سنوية وموسمية)',
                subtitle: 'الميلاد • الغطاس • الصوم الكبير • الشعانين • القيامة • النيروز • العذراء',
                onTap: () => Navigator.push(context, luxeRoute(const FractionsLibraryView())),
                isLast: true,
              ),
            ]),

            const SizedBox(height: 22),

            // SECTION 2: DAILY READINGS
            _sectionHeading(p, 'قراءات الكنيسة اليوم'),
            const SizedBox(height: 10),
            _groupedCard(p, [
              _hubRow(
                p: p,
                icon: Icons.auto_stories_outlined,
                title: 'القطمارس اليومي والآحاد والصوم الكبير',
                subtitle: 'قراءات البولس والكاثوليكون والإبركسيس والمزمور والإنجيل',
                onTap: () {
                  if (_katameros != null) {
                    Navigator.push(context, luxeRoute(KatamerosView(katameros: _katameros!)));
                  }
                },
              ),
              _hubRow(
                p: p,
                icon: Icons.history_edu_outlined,
                title: 'السنكسار القبطي اليومي',
                subtitle: 'سير القديسين والشهداء (يتجدد تلقائياً بعد صلاة عشية)',
                onTap: () => Navigator.push(context, luxeRoute(const SynaxariumDailyView())),
                isLast: true,
              ),
            ]),

            const SizedBox(height: 22),

            // SECTION 3: PERSONAL PRAYER COMPANIONS
            _sectionHeading(p, 'خلوة الصلاة الخاصة'),
            const SizedBox(height: 10),
            _groupedCard(p, [
              _hubRow(
                p: p,
                icon: Icons.spa_outlined,
                title: 'خلوة ٥ دقائق',
                subtitle: 'آية وعد ومزمور وإرشاد آبائي حسب شعورك الآن',
                onTap: () => Navigator.push(context, luxeRoute(const SpiritualPrescriptionView())),
              ),
              _hubRow(
                p: p,
                icon: Icons.edit_note_rounded,
                title: 'دفتر «اذكرهم يا رب» في صلاتي',
                subtitle: 'أضف أسماء أسرتك والمرضى والراقدين ليُذكروا في صلاتك',
                onTap: () => Navigator.push(context, luxeRoute(const RememberThemView())),
              ),
              _hubRow(
                p: p,
                icon: Icons.radio_button_checked_rounded,
                title: 'المسبحة القبطية وعداد المطانيات',
                subtitle: 'صلاة يسوع السهمية بعداد هادئ',
                onTap: () => Navigator.push(context, luxeRoute(const CopticPrayerRopeView())),
                isLast: true,
              ),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeading(AppPalette p, String title) {
    return Text(
      title,
      style: GoogleFonts.amiri(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: p.ink,
      ),
    );
  }

  Widget _liturgyMiniCard({
    required AppPalette p,
    required String image,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return PressScale(
      scale: 0.97,
      onTap: onTap,
      child: Container(
        height: 136,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: p.border),
          boxShadow: [
            BoxShadow(
              color: p.shadow,
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(17),
          child: Stack(
            fit: StackFit.expand,
            children: [
              SafeAssetImage(image, fit: BoxFit.cover),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: const [0.22, 1.0],
                    colors: [
                      Colors.black.withValues(alpha: 0.1),
                      Colors.black.withValues(alpha: 0.84),
                    ],
                  ),
                ),
              ),
              Positioned(
                right: 10,
                left: 10,
                bottom: 10,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.amiri(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.cairo(
                        fontSize: 10,
                        color: const Color(0xFFEBD7AA),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _groupedCard(AppPalette p, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: p.border),
        boxShadow: p.isDark
            ? null
            : [
                BoxShadow(
                  color: p.shadow,
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
      ),
      child: Material(
        type: MaterialType.transparency,
        child: Column(children: children),
      ),
    );
  }

  Widget _hubRow({
    required AppPalette p,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isLast = false,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: p.goldSoft,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, size: 20, color: p.isDark ? p.gold : p.accent),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.cairo(
                          fontSize: 13.5,
                          fontWeight: FontWeight.bold,
                          color: p.ink,
                        ),
                      ),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.cairo(fontSize: 11, color: p.inkMuted),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_left_rounded, size: 19, color: p.inkMuted),
              ],
            ),
          ),
          if (!isLast)
            Padding(
              padding: const EdgeInsets.only(right: 66),
              child: Divider(color: p.border, height: 1),
            ),
        ],
      ),
    );
  }
}
