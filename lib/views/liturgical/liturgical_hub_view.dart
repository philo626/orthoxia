import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/coptic_calendar_service.dart';
import '../../core/widgets/coptic_cross.dart';
import '../../core/widgets/luxe_widgets.dart';
import '../../models/katameros_model.dart';
import '../../providers/liturgy_provider.dart';
import '../bible/bible_explorer_view.dart';
import '../bible/scripture_tafseer_reading_view.dart';
import '../books/books_library_view.dart';
import '../hymns/hymns_library_view.dart';
import '../liturgies/liturgy_reader_view.dart';
import '../search/global_search_view.dart';
import 'agpeya_view.dart';
import 'katameros_view.dart';
import '../synaxarium/synaxarium_daily_view.dart';

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
    final copticToday = CopticCalendarService.fromGregorian(DateTime.now());

    final cards = <Map<String, dynamic>>[
      {
        'image': 'assets/images/thumb_basil.jpg',
        'title': 'القداس الباسيلي الكامل',
        'subtitle': 'من دورة وتقدمة الحمل حتى البركة الختامية • الخولاجي المقدس',
        'onTap': () => _openLiturgyById(context, 'liturgy_basil'),
      },
      {
        'image': 'assets/images/christ_pantocrator.jpg',
        'title': 'إنجيل اليوم والتفسير الآبائي',
        'subtitle': 'قراءة الإنجيل بالتشكيل الكامل مع درج التفاسير الآبائية المباشر',
        'onTap': () => Navigator.push(
              context,
              luxeRoute(const ScriptureTafseerReadingView(initialIndex: 0)),
            ),
      },
      {
        'image': 'assets/images/thumb_cyril.jpg',
        'title': 'القداس الغريغوري الكامل',
        'subtitle': 'قداس القديس غريغوريوس الثيؤلوغوس الموجه للابن الكلمة',
        'onTap': () => _openLiturgyById(context, 'liturgy_gregory'),
      },
      {
        'image': 'assets/images/thumb_katameros.jpg',
        'title': 'قطمارس قراءات الآحاد (القس أنطونيوس فكري)',
        'subtitle': 'قراءات آحاد الـ ١٣ شهراً قبطياً مع تأمل ورابط القراءات للقس أنطونيوس فكري',
        'onTap': () {
          if (_katameros != null) {
            Navigator.push(
              context,
              luxeRoute(KatamerosView(katameros: _katameros!, initialTabIndex: 0)),
            );
          }
        },
      },
      {
        'image': 'assets/images/thumb_synaxarium.jpg',
        'title': 'قطمارس الصوم الكبير وصوم يونان (دير مارمينا)',
        'subtitle': 'النبوات وقراءات باكر والقداس لأسابيع وآحاد الصوم الكبير وصوم يونان (٥٣ يوماً)',
        'onTap': () {
          if (_katameros != null) {
            Navigator.push(
              context,
              luxeRoute(KatamerosView(katameros: _katameros!, initialTabIndex: 1)),
            );
          }
        },
      },
      {
        'image': 'assets/images/thumb_synaxarium.jpg',
        'title': 'السنكسار القبطي اليومي والجامع (٣٦٦ يوماً)',
        'subtitle': 'تذكارات وسير قديسي وشهداء وأعياد الكنيسة القبطية بحسب التقويم السكندري لـ ١٣ شهراً',
        'onTap': () => Navigator.push(
              context,
              luxeRoute(const SynaxariumDailyView()),
            ),
      },
      {
        'image': 'assets/images/thumb_synaxarium.jpg',
        'title': 'القطمارس السنوي والسنكسار المُقسّم فئات',
        'subtitle': '${copticToday.formatted} • فئات السنكسار: الأعياد والملائكة • الرسل والبطاركة • الشهداء • الرهبان',
        'onTap': () {
          if (_katameros != null) {
            Navigator.push(
              context,
              luxeRoute(KatamerosView(katameros: _katameros!, initialTabIndex: 2)),
            );
          }
        },
      },
      {
        'image': 'assets/images/bible_cover.jpg',
        'title': 'إنجيل يوحنا والكتاب المقدس الكامل (٦٦ سفراً)',
        'subtitle': 'العهد القديم والعهد الجديد بالتشكيل الكامل مع البحث والتفسير الآبائي',
        'onTap': () => Navigator.push(context, luxeRoute(const BibleExplorerView())),
      },
      {
        'image': 'assets/images/thumb_gregory.jpg',
        'title': 'القداس الكيرلسي (المرقسي)',
        'subtitle': 'قداس القديس مارمرقس والقديس كيرلس عمود الدين والأواشي الكبرى',
        'onTap': () => _openLiturgyById(context, 'liturgy_cyril'),
      },
      {
        'image': 'assets/images/thumb_agpeya.jpg',
        'title': 'الأجبية المقدسة (صلوات السواعي)',
        'subtitle': 'باكر • الثالثة • السادسة • التاسعة • الغروب • النوم • الستار • نصف الليل',
        'onTap': () => Navigator.push(
              context,
              luxeRoute(const TitledPage(title: 'الأجبية المقدسة', child: AgpeyaView())),
            ),
      },
      {
        'image': 'assets/images/thumb_fathers.jpg',
        'title': 'مكتبة التفاسير والكتب الأرثوذكسية',
        'subtitle': 'تفاسير القمص تادرس يعقوب ملطي وكتب قداسة البابا شنودة الثالث والآباء',
        'onTap': () => Navigator.push(context, luxeRoute(const BooksLibraryView())),
      },
      {
        'image': 'assets/images/thumb_hymns.jpg',
        'title': 'مكتبة الألحان القبطية (٤٠٨ لحناً)',
        'subtitle': 'الألحان مسجلة بأصوات المعلم إبراهيم عياد والمرتلين مع الكلمات الثلاثية',
        'onTap': () => Navigator.push(
              context,
              luxeRoute(const TitledPage(title: 'الألحان والطقوس', child: HymnsLibraryView())),
            ),
      },
    ];

    return Scaffold(
      backgroundColor: AppColors.deepNavy,
      body: SafeArea(
        child: Column(
          children: [
            // Header matching Video Frame 05
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 10, 18, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.auto_awesome, color: AppColors.primaryGold, size: 15),
                      const SizedBox(width: 4),
                      Text(
                        copticToday.formatted,
                        style: GoogleFonts.cairo(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryGoldLight,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    'القداسات والقراءات',
                    style: GoogleFonts.cairo(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textLight,
                    ),
                  ),
                  Row(
                    children: [
                      LuxeCircleButton(
                        icon: Icons.search_rounded,
                        size: 36,
                        onTap: () => Navigator.push(context, luxeRoute(const GlobalSearchView())),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF231D14),
                          border: Border.all(
                            color: AppColors.primaryGold.withValues(alpha: 0.5),
                          ),
                        ),
                        child: const Center(child: CopticCross(size: 18)),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Vertical List of Illustrated Obsidian Cards (matches Video Frame 05)
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 95),
                itemCount: cards.length,
                itemBuilder: (context, idx) {
                  final c = cards[idx];
                  return ThumbListCard(
                    image: c['image'] as String,
                    title: c['title'] as String,
                    subtitle: c['subtitle'] as String,
                    onTap: c['onTap'] as VoidCallback,
                  ).animate().fadeIn(duration: 260.ms, delay: (idx * 40).ms);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
