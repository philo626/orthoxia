import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/coptic_calendar_service.dart';
import '../../core/services/storage_service.dart';
import '../../core/widgets/luxe_widgets.dart';
import '../../models/hymn_model.dart';
import '../../models/katameros_model.dart';
import '../../providers/church_mode_provider.dart';
import '../../providers/liturgy_provider.dart';
import '../bible/scripture_tafseer_reading_view.dart';
import '../books/books_library_view.dart';
import '../community/trivia_game_view.dart';
import '../conscience/conscience_exam_view.dart';
import '../hymns/hymn_detail_view.dart';
import '../icons/christ_icons_gallery_view.dart';
import '../liturgical/agpeya_view.dart';
import '../liturgical/katameros_view.dart';
import '../liturgies/liturgy_reader_view.dart';
import '../prayer_rope/coptic_prayer_rope_view.dart';
import '../synaxarium/synaxarium_daily_view.dart';
import '../coptic_academy/coptic_academy_view.dart';
import '../onboarding/auth_view.dart';
import '../profile/privacy_policy_view.dart';
import '../search/global_search_view.dart';
import '../spiritual_tracker/spiritual_tracker_view.dart';

class HomeDashboardView extends StatefulWidget {
  final Function(int tabIndex) onNavigateTab;

  const HomeDashboardView({super.key, required this.onNavigateTab});

  @override
  State<HomeDashboardView> createState() => _HomeDashboardViewState();
}

class _HomeDashboardViewState extends State<HomeDashboardView> {
  KatamerosDay? _katameros;
  List<Hymn> _hymns = [];
  bool _isLoading = true;
  int _activeIconIndex = 0;
  int _verseIndex = 0;

  final PageController _iconCarouselController = PageController(viewportFraction: 0.88);
  Timer? _carouselTimer;

  static const List<Map<String, String>> _dailyVerses = [
    {
      'short': 'الله محبة',
      'full': '«اللهُ مَحَبَّةٌ، وَمَنْ يَثْبُتْ فِي الْمَحَبَّةِ يَثْبُتْ فِي اللهِ وَاللهُ فِيهِ» (١ يو ٤: ١٦)',
    },
    {
      'short': 'أنا هو نور العالم',
      'full': '«أَنَا هُوَ نُورُ الْعَالَمِ، مَنْ يَتْبَعْنِي فَلاَ يَمْشِي فِي الظُّلْمَةِ بَلْ يَكُونُ لَهُ نُورُ الْحَيَاةِ» (يو ٨: ١٢)',
    },
    {
      'short': 'أنا هو الراعي الصالح',
      'full': '«أَنَا هُوَ الرَّاعِي الصَّالِحُ، وَالرَّاعِي الصَّالِحُ يَبْذِلُ نَفْسَهُ عَنِ الْخِرَافِ» (يو ١٠: ١١)',
    },
  ];

  static const List<Map<String, String>> _heroBanners = [
    {
      'image': 'assets/images/christ_pantocrator.jpg',
      'title': 'أيها المسيح إلهنا ضابط الكل',
    },
    {
      'image': 'assets/images/christ_good_shepherd.jpg',
      'title': 'الرب راعيّ فلا يعوزني شيء',
    },
    {
      'image': 'assets/images/christ_resurrection.jpg',
      'title': 'المسيح قام من بين الأموات',
    },
    {
      'image': 'assets/images/coptic_banner.jpg',
      'title': 'تراث الكنيسة القبطية الأرثوذكسية',
    },
    {
      'image': 'assets/images/bible_cover.jpg',
      'title': 'كلامك مصباح لرجلي ونور لسبيلي',
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
    _carouselTimer = Timer.periodic(const Duration(seconds: 7), (_) {
      if (!mounted || !_iconCarouselController.hasClients) return;
      final next = (_activeIconIndex + 1) % _heroBanners.length;
      _iconCarouselController.animateToPage(
        next,
        duration: const Duration(milliseconds: 650),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  void dispose() {
    _carouselTimer?.cancel();
    _iconCarouselController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      await CopticCalendarService.ensureLectionaryLoaded();

      final katamerosRaw = await rootBundle.loadString('assets/data/katameros.json');
      _katameros = KatamerosDay.fromJson(jsonDecode(katamerosRaw));

      final hymnsRaw = await rootBundle.loadString('assets/data/hymns.json');
      final hymnsList = jsonDecode(hymnsRaw) as List;
      _hymns = hymnsList.take(30).map((e) => Hymn.fromJson(e)).toList();
    } catch (_) {
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _openLiturgy(BuildContext context, String id) async {
    final prov = context.read<LiturgyProvider>();
    await prov.loadLiturgies();
    prov.selectLiturgyById(id);
    if (!context.mounted) return;
    Navigator.push(context, luxeRoute(const LiturgyReaderView()));
  }

  void _openPersonalGuarded(BuildContext context, String label, Widget page) {
    if (StorageService().isGuestMode()) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.cardNavy,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: AppColors.primaryGold.withValues(alpha: 0.45)),
          ),
          title: Text(
            'قسم شخصي محمي ($label)',
            style: GoogleFonts.cairo(
              fontWeight: FontWeight.bold,
              color: AppColors.primaryGoldLight,
              fontSize: 15,
            ),
          ),
          content: Text(
            'أنت في «وضع الزائر». لحفظ وتشفير مذكرة الاعتراف وسجل الجهاد الروحي على جهازك، يُرجى تسجيل الدخول أولاً.',
            style: GoogleFonts.cairo(color: AppColors.textLight, fontSize: 13),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('لاحقاً', style: GoogleFonts.cairo(color: AppColors.textMuted)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGold,
                foregroundColor: Colors.black,
              ),
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.push(context, luxeRoute(const AuthView()));
              },
              child: Text('تسجيل الدخول', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
      return;
    }
    Navigator.push(context, luxeRoute(page));
  }

  void _showQuickMenuSheet(BuildContext context) {
    final churchMode = context.read<ChurchModeProvider>();
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF141417),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.primaryGold.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'القائمة السريعة والأدوات الروحية',
              style: GoogleFonts.cairo(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryGoldLight,
              ),
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.nightlight_round, color: AppColors.primaryGold),
              title: Text('وضع الكنيسة الذكي (خفوت الإضاءة)',
                  style: GoogleFonts.cairo(color: AppColors.textLight, fontSize: 14)),
              trailing: Switch(
                value: churchMode.isChurchMode,
                activeThumbColor: AppColors.primaryGold,
                onChanged: (_) {
                  churchMode.toggleChurchMode();
                  Navigator.pop(context);
                },
              ),
            ),
            ListTile(
              leading: const Icon(Icons.lock_outline_rounded, color: AppColors.primaryGold),
              title: Text('مذكرة الاعتراف الشخصية المشفرة',
                  style: GoogleFonts.cairo(color: AppColors.textLight, fontSize: 14)),
              onTap: () {
                Navigator.pop(context);
                _openPersonalGuarded(context, 'مذكرة الاعتراف', const ConscienceExamView());
              },
            ),
            ListTile(
              leading: const Icon(Icons.emoji_events_rounded, color: AppColors.primaryGold),
              title: Text('تحدي المسابقات الأرثوذكسية اللانهائي ♾️',
                  style: GoogleFonts.cairo(color: AppColors.textLight, fontSize: 14)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  luxeRoute(const TitledPage(title: 'المسابقات الأرثوذكسية', child: TriviaGameView())),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.insights_rounded, color: AppColors.primaryGold),
              title: Text('متتبع الجهاد الروحي اليومي (مشفر محلياً)',
                  style: GoogleFonts.cairo(color: AppColors.textLight, fontSize: 14)),
              onTap: () {
                Navigator.pop(context);
                _openPersonalGuarded(context, 'متتبع الجهاد الروحي', const SpiritualTrackerView());
              },
            ),
            ListTile(
              leading: const Icon(Icons.privacy_tip_outlined, color: AppColors.primaryGold),
              title: Text('سياسة الخصوصية وأمان البيانات (Google Play)',
                  style: GoogleFonts.cairo(color: AppColors.textLight, fontSize: 14)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, luxeRoute(const PrivacyPolicyView()));
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _katameros == null) {
      return const Scaffold(
        backgroundColor: AppColors.deepNavy,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primaryGold),
        ),
      );
    }

    final userName = StorageService().getUserName();
    final copticToday = CopticCalendarService.fromGregorian(DateTime.now());
    final currentVerse = _dailyVerses[_verseIndex % _dailyVerses.length];

    return Scaffold(
      backgroundColor: AppColors.deepNavy,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(0, 6, 0, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Top Header Bar (matches Video Frame 03: Bell on right, "الرئيسية" center, Menu ☰ on left)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    LuxeCircleButton(
                      icon: Icons.notifications_none_rounded,
                      badge: true,
                      onTap: () {
                        if (_katameros != null) {
                          Navigator.push(
                            context,
                            luxeRoute(KatamerosView(katameros: _katameros!)),
                          );
                        }
                      },
                    ),
                    Text(
                      'الرئيسية',
                      style: GoogleFonts.cairo(
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textLight,
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        LuxeCircleButton(
                          icon: Icons.search_rounded,
                          onTap: () => Navigator.push(context, luxeRoute(const GlobalSearchView())),
                        ),
                        const SizedBox(width: 8),
                        LuxeCircleButton(
                          icon: Icons.menu_rounded,
                          onTap: () => _showQuickMenuSheet(context),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 6),

              // 2. Hero Christ Pantocrator Carousel with Peeking Cards + 5 Indicator Dots (Frame 03)
              SizedBox(
                height: 192,
                child: PageView.builder(
                  controller: _iconCarouselController,
                  itemCount: _heroBanners.length,
                  onPageChanged: (idx) => setState(() => _activeIconIndex = idx),
                  itemBuilder: (context, index) {
                    final banner = _heroBanners[index];
                    return GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        luxeRoute(const ChristIconsGalleryView()),
                      ),
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 6),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: AppColors.primaryGold.withValues(alpha: 0.5),
                            width: 1.3,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.65),
                              blurRadius: 18,
                              offset: const Offset(0, 8),
                            ),
                            BoxShadow(
                              color: AppColors.primaryGold.withValues(alpha: 0.14),
                              blurRadius: 18,
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(23),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              SafeAssetImage(
                                banner['image']!,
                                fit: BoxFit.cover,
                              ),
                              Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.transparent,
                                      Colors.black.withValues(alpha: 0.45),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 10),

              // 5 Carousel Indicator Dots (Frame 03)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_heroBanners.length, (i) {
                  final active = i == _activeIconIndex;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(horizontal: 3.5),
                    width: active ? 8 : 6,
                    height: active ? 8 : 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: active
                          ? AppColors.primaryGold
                          : Colors.white.withValues(alpha: 0.24),
                    ),
                  );
                }),
              ),

              const SizedBox(height: 12),

              // 3. User Greeting Row ("أهلاً بك يا مينا" + Circular Gold-Rimmed Christ Avatar — Frame 03)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 22),
                child: GestureDetector(
                  onTap: () => widget.onNavigateTab(4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.primaryGold, width: 1.6),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primaryGold.withValues(alpha: 0.3),
                              blurRadius: 10,
                            ),
                          ],
                          image: const DecorationImage(
                            image: AssetImage('assets/images/christ_pantocrator.jpg'),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'أهلاً بك يا $userName',
                              style: GoogleFonts.cairo(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textLight,
                              ),
                            ),
                            Text(
                              '${copticToday.formatted} • ${StorageService().getChurchName()} (${StorageService().getDiocese()})',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.cairo(
                                fontSize: 11,
                                color: AppColors.primaryGoldLight,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // 4. Verse of the Day Card ("آية اليوم" / "الله محبة" with < and > — matches Frame 03)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: PressScale(
                  scale: 0.98,
                  onTap: () => Navigator.push(
                    context,
                    luxeRoute(ScriptureTafseerReadingView(initialIndex: _verseIndex)),
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      gradient: AppColors.obsidianCard,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.5),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Right side in RTL: "آية اليوم" + "الله محبة >"
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'آية اليوم',
                                style: GoogleFonts.cairo(
                                  fontSize: 11.5,
                                  color: AppColors.textMuted,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.chevron_right_rounded,
                                    color: AppColors.primaryGoldLight,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 2),
                                  Flexible(
                                    child: Text(
                                      currentVerse['short']!,
                                      style: GoogleFonts.cairo(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textLight,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                currentVerse['full']!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.cairo(
                                  fontSize: 11,
                                  color: AppColors.primaryGoldLight.withValues(alpha: 0.85),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        // Left side in RTL: Circular < button to cycle verses
                        GestureDetector(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() {
                              _verseIndex = (_verseIndex + 1) % _dailyVerses.length;
                            });
                          },
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withValues(alpha: 0.06),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                            ),
                            child: const Icon(
                              Icons.chevron_left_rounded,
                              color: AppColors.textLight,
                              size: 22,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // 5. 2x3 Golden Squared-Icon Grid (exact 6 luxury tiles from Video Frame 03)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Expanded(
                          child: GoldIconTile(
                            icon: Icons.spatial_audio_off_rounded,
                            label: 'الألحان والطقوس',
                            onTap: () {
                              if (_hymns.isNotEmpty) {
                                Navigator.push(
                                  context,
                                  luxeRoute(
                                    HymnDetailView(
                                      hymn: _hymns.first,
                                      playlist: _hymns,
                                    ),
                                  ),
                                );
                              } else {
                                widget.onNavigateTab(2);
                              }
                            },
                          ),
                        ),
                        Expanded(
                          child: GoldIconTile(
                            icon: Icons.book_rounded,
                            label: 'الكتاب المقدس',
                            onTap: () => Navigator.push(
                              context,
                              luxeRoute(const ScriptureTafseerReadingView(initialIndex: 0)),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GoldIconTile(
                            icon: Icons.menu_book_rounded,
                            label: 'القطمارس والصلوات',
                            onTap: () {
                              if (_katameros != null) {
                                Navigator.push(
                                  context,
                                  luxeRoute(KatamerosView(katameros: _katameros!)),
                                );
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Expanded(
                          child: GoldIconTile(
                            icon: Icons.people_alt_rounded,
                            label: 'المساعد الآبائي',
                            onTap: () => widget.onNavigateTab(1),
                          ),
                        ),
                        Expanded(
                          child: GoldIconTile(
                            icon: Icons.music_note_rounded,
                            label: 'الألحان والقداس',
                            onTap: () => _openLiturgy(context, 'liturgy_basil'),
                          ),
                        ),
                        Expanded(
                          child: GoldIconTile(
                            icon: Icons.lightbulb_outline_rounded,
                            label: 'الأجبية والطقوس',
                            onTap: () => Navigator.push(
                              context,
                              luxeRoute(
                                const TitledPage(
                                  title: 'الأجبية المقدسة',
                                  child: AgpeyaView(),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Expanded(
                          child: GoldIconTile(
                            icon: Icons.radio_button_checked_rounded,
                            label: 'المسبحة القبطية',
                            onTap: () => Navigator.push(
                              context,
                              luxeRoute(const CopticPrayerRopeView()),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GoldIconTile(
                            icon: Icons.menu_book_rounded,
                            label: 'السنكسار القبطي',
                            onTap: () => Navigator.push(
                              context,
                              luxeRoute(const SynaxariumDailyView()),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GoldIconTile(
                            icon: Icons.translate_rounded,
                            label: 'أكاديمية القبطي',
                            onTap: () => Navigator.push(
                              context,
                              luxeRoute(const CopticAcademyView()),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 380.ms).slideY(begin: 0.06, end: 0),

              const SizedBox(height: 24),

              // 6. Illustrated Liturgies & Readings Cards (matches Video Frame 05)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'القداسات الإلهية والقراءات',
                          style: GoogleFonts.cairo(
                            fontSize: 15.5,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryGoldLight,
                          ),
                        ),
                        TextButton(
                          onPressed: () => widget.onNavigateTab(3),
                          child: Text(
                            'عرض الكل',
                            style: GoogleFonts.cairo(
                              fontSize: 12,
                              color: AppColors.primaryGold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ThumbListCard(
                      image: 'assets/images/thumb_basil.jpg',
                      title: 'القداس الباسيلي (دورة وتقدمة الحمل)',
                      subtitle:
                          'غسل الأيدي • اختيار الحمل • صلاة الشكر • أوشية الحمل • الأنافورا والقسمة',
                      onTap: () => _openLiturgy(context, 'liturgy_basil'),
                    ),
                    ThumbListCard(
                      image: 'assets/images/christ_pantocrator.jpg',
                      title: 'إنجيل اليوم والتفسير الآبائي',
                      subtitle:
                          'النص الإنجيلي المشكّل مع درج التفاسير الآبائية للقمص تادرس والبابا شنودة',
                      onTap: () => Navigator.push(
                        context,
                        luxeRoute(const ScriptureTafseerReadingView(initialIndex: 1)),
                      ),
                    ),
                    ThumbListCard(
                      image: 'assets/images/thumb_cyril.jpg',
                      title: 'القداس الغريغوري والقداس الكيرلسي',
                      subtitle:
                          'النصوص الكاملة من الخولاجي المقدس للقمص عبد المسيح صليب المسعودي',
                      onTap: () => _openLiturgy(context, 'liturgy_gregory'),
                    ),
                    ThumbListCard(
                      image: 'assets/images/thumb_fathers.jpg',
                      title: 'مكتبة التفاسير والكتب الأرثوذكسية',
                      subtitle:
                          'تفاسير الأسفار المقدسة وكتب الآباء الأولين والعقيدة الأرثوذكسية',
                      onTap: () => Navigator.push(context, luxeRoute(const BooksLibraryView())),
                    ),
                    ThumbListCard(
                      image: 'assets/images/thumb_synaxarium.jpg',
                      title: 'السنكسار القبطي اليومي والجامع (٣٦٦ يوماً)',
                      subtitle:
                          'تذكارات وسير الآباء القديسين والشهداء والأعياد لـ ١٣ شهراً قبطياً مع البحث الفوري',
                      onTap: () => Navigator.push(
                        context,
                        luxeRoute(const SynaxariumDailyView()),
                      ),
                    ),
                    ThumbListCard(
                      image: 'assets/images/thumb_agpeya.jpg',
                      title: 'المسبحة القبطية التفاعلية والمطانيات (٤١ حبة)',
                      subtitle:
                          'صلاة يسوع بالقبطي والمعرب والعربي مع عداد الحبات الذهبي والمطانيات',
                      onTap: () => Navigator.push(
                        context,
                        luxeRoute(const CopticPrayerRopeView()),
                      ),
                    ),
                    ThumbListCard(
                      image: 'assets/images/thumb_hymns.jpg',
                      title: 'تحدي المسابقات الأرثوذكسية اللانهائي ♾️',
                      subtitle:
                          'أسئلة لا نهائية في الكتاب المقدس والطقس والسنكسار مع الرتب الشماسية',
                      onTap: () => Navigator.push(
                        context,
                        luxeRoute(
                          const TitledPage(
                            title: 'المسابقات الأرثوذكسية',
                            child: TriviaGameView(),
                          ),
                        ),
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
