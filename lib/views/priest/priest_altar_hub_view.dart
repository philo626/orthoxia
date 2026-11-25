import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/services/storage_service.dart';
import '../../core/theme/app_palette.dart';
import '../../core/widgets/luxe_widgets.dart';
import '../../models/katameros_model.dart';
import '../../providers/church_mode_provider.dart';
import '../../providers/liturgy_provider.dart';
import '../liturgical/agpeya_view.dart';
import '../liturgical/church_sacraments_rites_view.dart';
import '../liturgical/fractions_library_view.dart';
import '../liturgical/katameros_view.dart';
import '../liturgical/raising_of_incense_view.dart';
import '../liturgical/tasbeha_pascha_view.dart';
import '../liturgies/liturgy_reader_view.dart';

/// Priest Sanctuary Hub («المذبح والطقوس» — Tab 1 of PriestNavigationShell):
/// Curated directly for the Altar & Liturgical Service:
///   0: الخولاجي والقِسَم (Euchologion: St. Basil, St. Gregory, St. Cyril + Raising of Incense + 39 Fractions)
///   1: الأسرار والخدمات (Lakkan, Pentecost Kneelings, Baptism, Matrimony, Unction, Funeral, Home Blessing)
///   2: التسبحة والبصخة (Complete Annual/Weekday/Kiahk Psalmody + Full 7-Day Holy Week Pascha)
///   3: الأجبية والقطمارس (Agpeya Hours + Quick Jump to Today's Katameros)
class PriestAltarHubView extends StatefulWidget {
  final ValueNotifier<int>? externalTabNotifier;
  const PriestAltarHubView({super.key, this.externalTabNotifier});

  @override
  State<PriestAltarHubView> createState() => _PriestAltarHubViewState();
}

class _PriestAltarHubViewState extends State<PriestAltarHubView>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;
  KatamerosDay? _katameros;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 4, vsync: this);
    widget.externalTabNotifier?.addListener(_syncExternal);
    _loadKatameros();
  }

  void _syncExternal() {
    final idx = widget.externalTabNotifier?.value ?? 0;
    if (idx >= 0 && idx < 4 && _tabCtrl.index != idx) {
      _tabCtrl.animateTo(idx);
    }
  }

  Future<void> _loadKatameros() async {
    try {
      final raw = await rootBundle.loadString('assets/data/katameros.json');
      if (mounted) {
        setState(() => _katameros = KatamerosDay.fromJson(jsonDecode(raw)));
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    widget.externalTabNotifier?.removeListener(_syncExternal);
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _openLiturgy(String id, String title) async {
    await StorageService().savePriestBookmark(
      bookKey: id,
      title: title,
      note: 'آخر موضع قراءة لقدسك في الكنيسة',
    );
    if (!mounted) return;
    final prov = context.read<LiturgyProvider>();
    await prov.loadLiturgies();
    prov.selectLiturgyById(id);
    if (!mounted) return;
    Navigator.push(context, luxeRoute(const LiturgyReaderView()));
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final churchMode = context.watch<ChurchModeProvider>();

    return Scaffold(
      backgroundColor: p.canvas,
      appBar: AppBar(
        backgroundColor: p.canvas,
        foregroundColor: p.ink,
        elevation: 0,
        title: Text(
          'المذبح والكتب الطقسية',
          style: GoogleFonts.amiri(
            fontWeight: FontWeight.bold,
            fontSize: 23,
            color: p.ink,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(left: 10),
            child: ActionChip(
              avatar: Icon(
                Icons.nights_stay_rounded,
                size: 16,
                color: churchMode.isChurchMode ? p.onAccent : p.gold,
              ),
              label: Text(
                churchMode.isChurchMode ? 'وضع المذبح ✓' : 'وضع المذبح',
                style: GoogleFonts.cairo(
                  fontSize: 11.5,
                  fontWeight: FontWeight.bold,
                  color: churchMode.isChurchMode ? p.onAccent : p.ink,
                ),
              ),
              backgroundColor: churchMode.isChurchMode ? p.gold : p.goldSoft,
              side: BorderSide(color: p.goldBorder),
              onPressed: () => churchMode.toggleChurchMode(),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabCtrl,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          indicatorColor: p.gold,
          labelColor: p.ink,
          unselectedLabelColor: p.inkMuted,
          labelStyle: GoogleFonts.cairo(fontSize: 12.5, fontWeight: FontWeight.bold),
          unselectedLabelStyle: GoogleFonts.cairo(fontSize: 12),
          tabs: const [
            Tab(text: 'الخولاجي والقِسَم'),
            Tab(text: 'الأسرار والخدمات'),
            Tab(text: 'التسبحة والبصخة'),
            Tab(text: 'الأجبية والقطمارس'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          _buildEuchologionTab(p),
          const ChurchSacramentsRitesView(),
          const TasbehaPaschaView(),
          _buildAgpeyaKatamerosTab(p),
        ],
      ),
    );
  }

  Widget _buildEuchologionTab(AppPalette p) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 36),
          children: [
            Text(
              'الخولاجي المقدس (مع صلوات الكاهن السرية)',
              style: GoogleFonts.amiri(fontSize: 21, fontWeight: FontWeight.bold, color: p.ink),
            ),
            const SizedBox(height: 10),
            _altarBookCard(
              p: p,
              title: 'القداس الباسيلي للقديس باسيليوس الكبير',
              subtitle: 'تقديم الحمل • قراءات القداس • القداس كامل بصلوات الكاهن السرية والأواشي',
              icon: Icons.church_rounded,
              badge: 'السنوي',
              onTap: () => _openLiturgy('liturgy_basil', 'القداس الباسيلي'),
            ),
            _altarBookCard(
              p: p,
              title: 'القداس الغريغوري للقديس غريغوريوس الثيؤلوغوس',
              subtitle: 'مخصّص للأعياد السيدية الكبرى (الميلاد • الغطاس • القيامة)',
              icon: Icons.auto_awesome_rounded,
              badge: 'الأعياد',
              onTap: () => _openLiturgy('liturgy_gregory', 'القداس الغريغوري'),
            ),
            _altarBookCard(
              p: p,
              title: 'القداس الكيرلسي (قداس مارمرقس الرسول)',
              subtitle: 'القداس السكندري الأصيل للأصوام وشهر كيهك والصوم الكبير',
              icon: Icons.menu_book_rounded,
              badge: 'الأصوام',
              onTap: () => _openLiturgy('liturgy_cyril', 'القداس الكيرلسي'),
            ),
            const SizedBox(height: 14),
            Text(
              'صلوات البخور والقِسَم والقطمارس',
              style: GoogleFonts.amiri(fontSize: 21, fontWeight: FontWeight.bold, color: p.ink),
            ),
            const SizedBox(height: 10),
            _altarBookCard(
              p: p,
              title: 'رفع بخور عشية وباكر',
              subtitle: 'أوشية الراقدين • المسافرين • المرضى • القرابين • أرباع الناقوس والإنجيل',
              icon: Icons.local_fire_department_rounded,
              badge: '٢٢ قسم',
              onTap: () => Navigator.push(context, luxeRoute(const RaisingOfIncenseView())),
            ),
            _altarBookCard(
              p: p,
              title: 'موسوعة صلوات القِسَم (٣٩ قسمة)',
              subtitle: 'قسمة سنوية • صيامي • كيهكية • عيد الميلاد • البصخة • القيامة • العنصرة',
              icon: Icons.format_list_bulleted_rounded,
              badge: '٣٩ قسمة',
              onTap: () => Navigator.push(context, luxeRoute(const FractionsLibraryView())),
            ),
            if (_katameros != null)
              _altarBookCard(
                p: p,
                title: 'القطمارس اليومي والسنكسار',
                subtitle: 'قراءات عشية وباكر والقداس كاملة لليوم القبطي الحالي',
                icon: Icons.auto_stories_rounded,
                badge: 'اليوم',
                onTap: () => Navigator.push(
                  context,
                  luxeRoute(KatamerosView(katameros: _katameros!)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAgpeyaKatamerosTab(AppPalette p) {
    return Column(
      children: [
        if (_katameros != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
            child: PressScale(
              scale: 0.985,
              onTap: () => Navigator.push(
                context,
                luxeRoute(KatamerosView(katameros: _katameros!)),
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                decoration: BoxDecoration(
                  color: p.goldSoft,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: p.goldBorder),
                ),
                child: Row(
                  children: [
                    Icon(Icons.auto_stories_rounded, color: p.gold, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'فتح القطمارس اليومي وقراءات القداس',
                        style: GoogleFonts.cairo(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: p.ink,
                        ),
                      ),
                    ),
                    Icon(Icons.chevron_left_rounded, color: p.gold),
                  ],
                ),
              ),
            ),
          ),
        const Expanded(child: AgpeyaView()),
      ],
    );
  }

  Widget _altarBookCard({
    required AppPalette p,
    required String title,
    required String subtitle,
    required IconData icon,
    required String badge,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: PressScale(
        scale: 0.985,
        onTap: onTap,
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
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: p.goldSoft,
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(color: p.goldBorder),
                ),
                child: Icon(icon, color: p.gold, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: GoogleFonts.amiri(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: p.ink,
                              height: 1.2,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: p.goldSoft,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            badge,
                            style: GoogleFonts.cairo(
                              fontSize: 10.5,
                              fontWeight: FontWeight.bold,
                              color: p.gold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: GoogleFonts.cairo(
                        fontSize: 11.5,
                        color: p.inkSecondary,
                        height: 1.4,
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
}
