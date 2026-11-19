import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/coptic_calendar_service.dart';
import '../../core/services/coptic_fast_service.dart';
import '../../core/services/notification_service.dart';
import '../../core/services/patron_saint_service.dart';
import '../../core/services/storage_service.dart';
import '../../core/widgets/blessing_poster_studio_sheet.dart';
import '../../core/widgets/coptic_cross.dart';
import '../../core/widgets/luxe_widgets.dart';
import '../../core/widgets/saint_icon_avatar.dart';
import '../../models/katameros_model.dart';
import '../../providers/church_mode_provider.dart';
import '../../providers/liturgy_provider.dart';
import '../bible/bible_explorer_view.dart';
import '../books/books_library_view.dart';
import '../community/trivia_game_view.dart';
import '../conscience/conscience_exam_view.dart';
import '../coptic_academy/coptic_academy_view.dart';
import '../icons/christ_icons_gallery_view.dart';
import '../liturgical/agpeya_view.dart';
import '../liturgical/church_sacraments_rites_view.dart';
import '../liturgical/katameros_view.dart';
import '../liturgical/remember_them_view.dart';
import '../liturgical/tasbeha_pascha_view.dart';
import '../liturgies/liturgy_reader_view.dart';
import '../onboarding/auth_view.dart';
import '../prayer_rope/coptic_prayer_rope_view.dart';
import '../profile/privacy_policy_view.dart';
import '../search/global_search_view.dart';
import '../spiritual_tracker/spiritual_tracker_view.dart';
import '../synaxarium/my_patron_saint_view.dart';
import '../synaxarium/synaxarium_daily_view.dart';
import 'spiritual_prescription_view.dart';

class HomeDashboardView extends StatefulWidget {
  final Function(int tabIndex) onNavigateTab;

  const HomeDashboardView({super.key, required this.onNavigateTab});

  @override
  State<HomeDashboardView> createState() => _HomeDashboardViewState();
}

class _HomeDashboardViewState extends State<HomeDashboardView> {
  KatamerosDay? _katameros;
  bool _isLoading = true;
  int _activeIconIndex = 0;
  int _verseIndex = 0;

  final PageController _iconCarouselController = PageController(viewportFraction: 0.92);
  Timer? _carouselTimer;

  static const List<Map<String, String>> _dailyVerses = [
    {
      'text': 'اللهُ مَحَبَّةٌ، وَمَنْ يَثْبُتْ فِي الْمَحَبَّةِ يَثْبُتْ فِي اللهِ وَاللهُ فِيهِ.',
      'ref': '١ يوحنا ٤ : ١٦',
    },
    {
      'text': 'أَنَا هُوَ نُورُ الْعَالَمِ، مَنْ يَتْبَعْنِي فَلاَ يَمْشِي فِي الظُّلْمَةِ بَلْ يَكُونُ لَهُ نُورُ الْحَيَاةِ.',
      'ref': 'يوحنا ٨ : ١٢',
    },
    {
      'text': 'الرَّبُّ رَاعِيَّ فَلاَ يُعْوِزُنِي شَيْءٌ. فِي مَرَاعٍ خُضْرٍ يُرْبِضُنِي.',
      'ref': 'مزمور ٢٣ : ١ - ٢',
    },
    {
      'text': 'تَعَالَوْا إِلَيَّ يَا جَمِيعَ الْمُتْعَبِينَ وَالثَّقِيلِي الأَحْمَالِ، وَأَنَا أُرِيحُكُمْ.',
      'ref': 'متى ١١ : ٢٨',
    },
    {
      'text': 'سَلاَماً أَتْرُكُ لَكُمْ. سَلاَمِي أُعْطِيكُمْ. لاَ تَضْطَرِبْ قُلُوبُكُمْ وَلاَ تَرْهَبْ.',
      'ref': 'يوحنا ١٤ : ٢٧',
    },
  ];

  static const List<Map<String, String>> _heroBanners = [
    {
      'image': 'assets/images/christ_pantocrator.jpg',
      'title': 'أيها المسيح إلهنا ضابط الكل',
      'subtitle': 'كيرياليسون • يا رب ارحم',
    },
    {
      'image': 'assets/images/christ_good_shepherd.jpg',
      'title': 'الرب راعيّ فلا يعوزني شيء',
      'subtitle': 'المزمور الثالث والعشرون',
    },
    {
      'image': 'assets/images/christ_resurrection.jpg',
      'title': 'المسيح قام من بين الأموات',
      'subtitle': 'بالموت داس الموت',
    },
    {
      'image': 'assets/images/coptic_banner.jpg',
      'title': 'تراث الكنيسة القبطية الأرثوذكسية',
      'subtitle': 'الإيمان المسلّم مرة للقديسين',
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeAskNotificationPermission());
    _carouselTimer = Timer.periodic(const Duration(seconds: 8), (_) {
      if (!mounted || !_iconCarouselController.hasClients) return;
      final next = (_activeIconIndex + 1) % _heroBanners.length;
      _iconCarouselController.animateToPage(
        next,
        duration: const Duration(milliseconds: 650),
        curve: Curves.easeOutCubic,
      );
    });
  }

  Future<void> _maybeAskNotificationPermission() async {
    final storage = StorageService();
    if (storage.isNotificationPromptShown()) return;
    await storage.setNotificationPromptShown(true);
    if (!mounted) return;

    bool wantDailyVerse = true;
    bool wantFamilyPrayer = false;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) => AlertDialog(
          backgroundColor: AppColors.cardNavy,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: AppColors.hairline),
          ),
          title: Row(
            children: [
              const Icon(Icons.notifications_none_rounded, color: AppColors.primaryGold, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'آية اليوم وتذكير الصلاة',
                  style: GoogleFonts.amiri(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: AppColors.primaryGoldLight,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'اختر التنبيهات الهادئة التي ترغب بتفعيلها:',
                style: GoogleFonts.cairo(fontSize: 13, color: AppColors.textLight),
              ),
              const SizedBox(height: 10),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                activeColor: AppColors.primaryGold,
                checkColor: Colors.black,
                value: wantDailyVerse,
                onChanged: (v) => setDlg(() => wantDailyVerse = v ?? false),
                title: Text('آية اليوم وقول شفيعك يومياً',
                    style: GoogleFonts.cairo(fontSize: 13, color: AppColors.textLight)),
                subtitle: Text('صباحاً الساعة ٨:٠٠ ص',
                    style: GoogleFonts.cairo(fontSize: 11, color: AppColors.textMuted)),
              ),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                activeColor: AppColors.primaryGold,
                checkColor: Colors.black,
                value: wantFamilyPrayer,
                onChanged: (v) => setDlg(() => wantFamilyPrayer = v ?? false),
                title: Text('تذكير صلاة العائلة (اختياري)',
                    style: GoogleFonts.cairo(fontSize: 13, color: AppColors.textLight)),
                subtitle: Text('تذكير هادئ الساعة ٩:٠٠ مساءً ويمكن تعديله في أي وقت',
                    style: GoogleFonts.cairo(fontSize: 11, color: AppColors.textMuted)),
              ),
            ],
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
                elevation: 0,
              ),
              onPressed: () async {
                Navigator.pop(ctx);
                if (wantDailyVerse || wantFamilyPrayer) {
                  await NotificationService().requestPermission();
                }
                await storage.setDailyVerseNotificationEnabled(wantDailyVerse);
                await storage.setFamilyPrayerReminderEnabled(wantFamilyPrayer);
                await NotificationService().syncScheduledNotifications();
              },
              child: Text('حفظ', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _carouselTimer?.cancel();
    _iconCarouselController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      await Future.wait([
        CopticCalendarService.ensureLectionaryLoaded(),
        PatronSaintService.ensureLoaded(),
      ]);
      final katamerosRaw = await rootBundle.loadString('assets/data/katameros.json');
      _katameros = KatamerosDay.fromJson(jsonDecode(katamerosRaw));
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
            borderRadius: BorderRadius.circular(18),
            side: const BorderSide(color: AppColors.hairline),
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
            'أنت في وضع الزائر. لحفظ وتشفير مذكرة الاعتراف وسجل الجهاد الروحي على جهازك، يُرجى تسجيل الدخول أولاً.',
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
                elevation: 0,
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
      backgroundColor: AppColors.deepNavy,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        side: BorderSide(color: AppColors.hairline),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 38,
              height: 3.5,
              decoration: BoxDecoration(
                color: AppColors.primaryGold.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'أدوات الخلوة والإعدادات',
              style: GoogleFonts.amiri(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryGoldLight,
              ),
            ),
            const SizedBox(height: 10),
            ListTile(
              leading: const Icon(Icons.nightlight_outlined, color: AppColors.primaryGold),
              title: Text('وضع الكنيسة (خفوت الإضاءة)',
                  style: GoogleFonts.cairo(color: AppColors.textLight, fontSize: 13.5)),
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
                  style: GoogleFonts.cairo(color: AppColors.textLight, fontSize: 13.5)),
              onTap: () {
                Navigator.pop(context);
                _openPersonalGuarded(context, 'مذكرة الاعتراف', const ConscienceExamView());
              },
            ),
            ListTile(
              leading: const Icon(Icons.insights_rounded, color: AppColors.primaryGold),
              title: Text('متتبع الجهاد الروحي اليومي',
                  style: GoogleFonts.cairo(color: AppColors.textLight, fontSize: 13.5)),
              onTap: () {
                Navigator.pop(context);
                _openPersonalGuarded(context, 'متتبع الجهاد الروحي', const SpiritualTrackerView());
              },
            ),
            ListTile(
              leading: const Icon(Icons.emoji_events_outlined, color: AppColors.primaryGold),
              title: Text('المسابقات الأرثوذكسية',
                  style: GoogleFonts.cairo(color: AppColors.textLight, fontSize: 13.5)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  luxeRoute(const TitledPage(title: 'المسابقات الأرثوذكسية', child: TriviaGameView())),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.privacy_tip_outlined, color: AppColors.primaryGold),
              title: Text('سياسة الخصوصية وأمان البيانات',
                  style: GoogleFonts.cairo(color: AppColors.textLight, fontSize: 13.5)),
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
          child: CircularProgressIndicator(color: AppColors.primaryGold, strokeWidth: 2),
        ),
      );
    }

    final copticToday = CopticCalendarService.todayLiturgical();
    final fast = CopticFastService.getTodayFastStatus();
    final currentVerse = _dailyVerses[_verseIndex % _dailyVerses.length];
    final saint = PatronSaintService.getSaintById(StorageService().getPatronSaintId());
    final dailyQuote = PatronSaintService.getDailyQuote(saint.id);
    final saintImgUrl = PatronSaintService.getImageUrlForSaint(saint);

    final practices = <Map<String, dynamic>>[
      {
        'title': 'خلوة الـ ٥ دقائق',
        'sub': 'آية ومزمور وإرشاد آبائي حسب حالتك',
        'icon': Icons.spa_outlined,
        'onTap': () => Navigator.push(context, luxeRoute(const SpiritualPrescriptionView())),
      },
      {
        'title': 'القطمارس اليومي',
        'sub': 'قراءات البولس والكاثوليكون والإنجيل',
        'icon': Icons.menu_book_outlined,
        'onTap': () => Navigator.push(context, luxeRoute(KatamerosView(katameros: _katameros!))),
      },
      {
        'title': 'المسبحة القبطية',
        'sub': 'صلاة يسوع وعداد الحبات والمطانيات',
        'icon': Icons.radio_button_checked_rounded,
        'onTap': () => Navigator.push(context, luxeRoute(const CopticPrayerRopeView())),
      },
      {
        'title': 'اذكرهم يا رب',
        'sub': 'قائمة أحبائك والمرضى والراقدين بالاسم',
        'icon': Icons.edit_note_rounded,
        'onTap': () => Navigator.push(context, luxeRoute(const RememberThemView())),
      },
      {
        'title': 'التسبحة والبصخة',
        'sub': 'الإبصلمودية وحاسبة الأعياد القبطية',
        'icon': Icons.auto_stories_outlined,
        'onTap': () => Navigator.push(context, luxeRoute(const TasbehaPaschaView())),
      },
      {
        'title': 'الطقوس والأسرار',
        'sub': 'اللقان والسجدة والإكليل والقنديل',
        'icon': Icons.church_outlined,
        'onTap': () => Navigator.push(context, luxeRoute(const ChurchSacramentsRitesView())),
      },
      {
        'title': 'المسابقات القبطية',
        'sub': 'أسئلة في الكتاب المقدس والطقس والسنكسار',
        'icon': Icons.emoji_events_outlined,
        'onTap': () => Navigator.push(
              context,
              luxeRoute(const TitledPage(title: 'المسابقات الأرثوذكسية', child: TriviaGameView())),
            ),
      },
    ];

    return Scaffold(
      backgroundColor: AppColors.deepNavy,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(0, 8, 0, 108),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Minimalist Editorial Masthead
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                child: Row(
                  children: [
                    const CopticCross(size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'أرثوذكسيا',
                            style: GoogleFonts.amiri(
                              fontSize: 23,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryGoldLight,
                              height: 1.1,
                            ),
                          ),
                          Text(
                            '${copticToday.formatted} • ${copticToday.seasonName}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.cairo(
                              fontSize: 11,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    LuxeCircleButton(
                      icon: Icons.search_rounded,
                      size: 38,
                      onTap: () => Navigator.push(context, luxeRoute(const GlobalSearchView())),
                    ),
                    const SizedBox(width: 8),
                    LuxeCircleButton(
                      icon: Icons.menu_rounded,
                      size: 38,
                      onTap: () => _showQuickMenuSheet(context),
                    ),
                  ],
                ),
              ),

              // 2. Sacred Iconography Editorial Hero
              SizedBox(
                height: 196,
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
                        margin: const EdgeInsets.symmetric(horizontal: 5),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppColors.primaryGold.withValues(alpha: 0.25),
                            width: 0.9,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(19),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              SafeAssetImage(banner['image']!, fit: BoxFit.cover),
                              Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    stops: const [0.35, 1.0],
                                    colors: [
                                      Colors.transparent,
                                      Colors.black.withValues(alpha: 0.82),
                                    ],
                                  ),
                                ),
                              ),
                              Positioned(
                                right: 16,
                                left: 16,
                                bottom: 14,
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            banner['title']!,
                                            style: GoogleFonts.amiri(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.textLight,
                                              height: 1.2,
                                            ),
                                          ),
                                          Text(
                                            banner['subtitle']!,
                                            style: GoogleFonts.cairo(
                                              fontSize: 11,
                                              color: AppColors.primaryGoldLight,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () => Navigator.push(
                                        context,
                                        luxeRoute(KatamerosView(katameros: _katameros!)),
                                      ),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withValues(alpha: 0.55),
                                          borderRadius: BorderRadius.circular(20),
                                          border: Border.all(
                                            color: AppColors.primaryGold.withValues(alpha: 0.45),
                                          ),
                                        ),
                                        child: Text(
                                          'قراءات اليوم',
                                          style: GoogleFonts.cairo(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.primaryGoldLight,
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
                  },
                ),
              ),

              const SizedBox(height: 10),

              // Minimalist hairline pagination indicator
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_heroBanners.length, (i) {
                  final active = i == _activeIconIndex;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 240),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: active ? 20 : 6,
                    height: 3,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(2),
                      color: active
                          ? AppColors.primaryGold
                          : Colors.white.withValues(alpha: 0.2),
                    ),
                  );
                }),
              ),

              const SizedBox(height: 18),

              // 3. Editorial Scripture of the Day Ribbon (Book-Quote Aesthetic)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(14, 14, 16, 14),
                  decoration: BoxDecoration(
                    color: AppColors.cardNavy,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.hairline),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Text(
                            'آية اليوم',
                            style: GoogleFonts.cairo(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primaryGold,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            currentVerse['ref']!,
                            style: GoogleFonts.cairo(fontSize: 11, color: AppColors.textMuted),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () {
                              BlessingPosterStudioSheet.show(
                                context,
                                title: 'آية اليوم',
                                bodyText: currentVerse['text']!,
                                reference: currentVerse['ref']!,
                              );
                            },
                            child: const Padding(
                              padding: EdgeInsets.all(4),
                              child: Icon(Icons.photo_camera_back_outlined,
                                  size: 17, color: AppColors.primaryGoldLight),
                            ),
                          ),
                          const SizedBox(width: 4),
                          GestureDetector(
                            onTap: () {
                              HapticFeedback.selectionClick();
                              setState(() => _verseIndex = (_verseIndex + 1) % _dailyVerses.length);
                            },
                            child: const Padding(
                              padding: EdgeInsets.all(4),
                              child: Icon(Icons.refresh_rounded,
                                  size: 17, color: AppColors.textMuted),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.only(right: 12),
                        decoration: const BoxDecoration(
                          border: Border(
                            right: BorderSide(color: AppColors.primaryGold, width: 2.2),
                          ),
                        ),
                        child: Text(
                          '«${currentVerse['text']!}»',
                          style: GoogleFonts.amiri(
                            fontSize: 19,
                            height: 1.65,
                            color: AppColors.textLight,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // 4. Core 8 Pillars Architectural Grid (2 rows × 4 calm tiles)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: GoldIconTile(
                            icon: Icons.church_outlined,
                            label: 'القداسات',
                            onTap: () => _openLiturgy(context, 'liturgy_basil'),
                          ),
                        ),
                        Expanded(
                          child: GoldIconTile(
                            icon: Icons.menu_book_outlined,
                            label: 'الكتاب المقدس',
                            onTap: () => Navigator.push(
                              context,
                              luxeRoute(const BibleExplorerView()),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GoldIconTile(
                            icon: Icons.schedule_outlined,
                            label: 'الأجبية',
                            onTap: () => Navigator.push(
                              context,
                              luxeRoute(
                                const TitledPage(title: 'الأجبية المقدسة', child: AgpeyaView()),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GoldIconTile(
                            icon: Icons.graphic_eq_rounded,
                            label: 'الألحان',
                            onTap: () => widget.onNavigateTab(2),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: GoldIconTile(
                            icon: Icons.auto_stories_outlined,
                            label: 'الكتب والتفاسير',
                            onTap: () => Navigator.push(
                              context,
                              luxeRoute(const BooksLibraryView()),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GoldIconTile(
                            icon: Icons.history_edu_outlined,
                            label: 'السنكسار',
                            onTap: () => Navigator.push(
                              context,
                              luxeRoute(const SynaxariumDailyView()),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GoldIconTile(
                            icon: Icons.portrait_outlined,
                            label: 'شفيعي',
                            onTap: () async {
                              await Navigator.push(context, luxeRoute(const MyPatronSaintView()));
                              if (mounted) setState(() {});
                            },
                          ),
                        ),
                        Expanded(
                          child: GoldIconTile(
                            icon: Icons.translate_rounded,
                            label: 'القبطي',
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
              ).animate().fadeIn(duration: 320.ms),

              const SizedBox(height: 22),

              // 5. Personal Patron Saint Portrait Card (Real Cathedral-Arch Icon Portrait!)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: () async {
                    await Navigator.push(context, luxeRoute(const MyPatronSaintView()));
                    if (mounted) setState(() {});
                  },
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.cardNavy,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: AppColors.primaryGold.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SaintIconAvatar(
                          imageUrl: saintImgUrl,
                          size: 64,
                          shape: SaintAvatarShape.arch,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      saint.shortName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.amiri(
                                        fontSize: 19,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primaryGoldLight,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    'شفيعي',
                                    style: GoogleFonts.cairo(
                                      fontSize: 10.5,
                                      color: AppColors.textMuted,
                                    ),
                                  ),
                                  const SizedBox(width: 2),
                                  const Icon(Icons.chevron_left_rounded,
                                      size: 16, color: AppColors.primaryGold),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '«${dailyQuote.quote}»',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.amiri(
                                  fontSize: 16,
                                  height: 1.5,
                                  color: AppColors.textLight,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'تصفّح معرض كل قديسي الكنيسة وأقوالهم اليومية',
                                style: GoogleFonts.cairo(
                                  fontSize: 10.5,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // 6. Calm Liturgical Fasting Status Strip (Zero emojis)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceNavy,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.hairline),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        fast.isFastingToday ? Icons.spa_outlined : Icons.wb_sunny_outlined,
                        color: AppColors.primaryGold,
                        size: 18,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              fast.title,
                              style: GoogleFonts.cairo(
                                fontSize: 12.5,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textLight,
                              ),
                            ),
                            Text(
                              '${fast.degree} • ${fast.abstinenceGuide}',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.cairo(
                                fontSize: 11,
                                color: AppColors.textMuted,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.cardNavy,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.hairline),
                        ),
                        child: Text(
                          !fast.isFastingToday
                              ? 'فطار'
                              : (fast.fishAllowed ? 'يُسمح بالسمك' : 'صوم نباتي'),
                          style: GoogleFonts.cairo(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryGoldLight,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 22),

              // 7. Compact Horizontal "خلوة اليوم والصلوات" Shelf
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'خلوة اليوم والطقوس',
                      style: GoogleFonts.amiri(
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryGoldLight,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => widget.onNavigateTab(3),
                      child: Text(
                        'عرض كل الصلوات',
                        style: GoogleFonts.cairo(fontSize: 11.5, color: AppColors.textMuted),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 118,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: practices.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (_, idx) {
                    final p = practices[idx];
                    return InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: p['onTap'] as VoidCallback,
                      child: Container(
                        width: 158,
                        padding: const EdgeInsets.all(13),
                        decoration: BoxDecoration(
                          color: AppColors.cardNavy,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.hairline),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Icon(p['icon'] as IconData, color: AppColors.primaryGold, size: 22),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  p['title'] as String,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.cairo(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textLight,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  p['sub'] as String,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.cairo(
                                    fontSize: 10.5,
                                    color: AppColors.textMuted,
                                    height: 1.3,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
