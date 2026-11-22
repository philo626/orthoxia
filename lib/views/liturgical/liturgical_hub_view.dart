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
import '../bible/bible_explorer_view.dart';
import '../books/books_library_view.dart';
import '../home/spiritual_prescription_view.dart';
import '../liturgies/liturgy_reader_view.dart';
import '../prayer_rope/coptic_prayer_rope_view.dart';
import '../search/global_search_view.dart';
import '../synaxarium/synaxarium_daily_view.dart';
import 'agpeya_view.dart';
import 'church_sacraments_rites_view.dart';
import 'katameros_view.dart';
import 'remember_them_view.dart';
import 'tasbeha_pascha_view.dart';

/// Organized Liturgical Sanctuary Hub («الصلوات والقداسات»):
/// Cleanly categorized into 4 calm sections instead of repetitive card dumps.
class LiturgicalHubView extends StatefulWidget {
  const LiturgicalHubView({super.key});

  @override
  State<LiturgicalHubView> createState() => _LiturgicalHubViewState();
}

class _LiturgicalHubViewState extends State<LiturgicalHubView> {
  KatamerosDay? _katameros;

  @override
  void initState() {
    super.initState();
    _loadKatameros();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LiturgyProvider>().loadLiturgies();
    });
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
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 36),
              children: [
                // Header
                Row(
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
                      tooltip: 'بحث',
                      onTap: () => Navigator.push(context, luxeRoute(const GlobalSearchView())),
                    ),
                  ],
                ),

                const SizedBox(height: 22),

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

                const SizedBox(height: 24),

                // SECTION 2: DAILY PRAYERS & READINGS
                _sectionHeading(p, 'صلوات وقراءات اليوم'),
                const SizedBox(height: 10),
                _groupedCard(p, [
                  _hubRow(
                    p: p,
                    icon: Icons.schedule_outlined,
                    title: 'الأجبية المقدسة (صلوات السواعي)',
                    subtitle: 'باكر • الثالثة • السادسة • التاسعة • الغروب • النوم • الستار • نصف الليل',
                    onTap: () => Navigator.push(
                      context,
                      luxeRoute(const TitledPage(title: 'الأجبية المقدسة', child: AgpeyaView())),
                    ),
                  ),
                  _hubRow(
                    p: p,
                    icon: Icons.menu_book_outlined,
                    title: 'الكتاب المقدس كاملاً (٧٣ سفراً)',
                    subtitle: 'ترجمة فانديك الكنسية المعتمدة مع متابعة الختم',
                    onTap: () => Navigator.push(context, luxeRoute(const BibleExplorerView())),
                  ),
                  _hubRow(
                    p: p,
                    icon: Icons.auto_stories_outlined,
                    title: 'القطمارس اليومي والآحاد والصوم الكبير',
                    subtitle: 'قراءات البولس والكاثوليكون والإبركسيس والإنجيل',
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
                    subtitle: 'يتجدد تلقائياً الساعة ٥ مساءً حسب توقيت عشية',
                    onTap: () => Navigator.push(context, luxeRoute(const SynaxariumDailyView())),
                    isLast: true,
                  ),
                ]),

                const SizedBox(height: 24),

                // SECTION 3: SACRAMENTS, TASBEHA & BOOKS
                _sectionHeading(p, 'التسبحة والأسرار والمكتبة'),
                const SizedBox(height: 10),
                _groupedCard(p, [
                  _hubRow(
                    p: p,
                    icon: Icons.church_outlined,
                    title: 'الطقوس والأسرار الكنسية واللقان والسجدة',
                    subtitle: 'اللقان • السجدة • الإكليل • مسحة المرضى • المعمودية',
                    onTap: () => Navigator.push(context, luxeRoute(const ChurchSacramentsRitesView())),
                  ),
                  _hubRow(
                    p: p,
                    icon: Icons.nights_stay_outlined,
                    title: 'التسبحة والإبصلمودية والبصخة والأعياد',
                    subtitle: 'الأربعة هوسات، الثيؤطوكيات، وحاسبة الأعياد القبطية',
                    onTap: () => Navigator.push(context, luxeRoute(const TasbehaPaschaView())),
                  ),
                  _hubRow(
                    p: p,
                    icon: Icons.local_library_outlined,
                    title: 'المكتبة الأرثوذكسية والتفاسير',
                    subtitle: 'كتب الآباء الأولين، البابا شنودة، وتفاسير ٧٣ سفراً',
                    onTap: () => Navigator.push(context, luxeRoute(const BooksLibraryView())),
                    isLast: true,
                  ),
                ]),

                const SizedBox(height: 24),

                // SECTION 4: PERSONAL PRAYER COMPANIONS
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
        height: 132,
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
                    stops: const [0.25, 1.0],
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
      child: Column(children: children),
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
