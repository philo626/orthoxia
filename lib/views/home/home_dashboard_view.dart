import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/services/coptic_calendar_service.dart';
import '../../core/services/coptic_fast_service.dart';
import '../../core/services/notification_service.dart';
import '../../core/services/patron_saint_service.dart';
import '../../core/services/reading_state_service.dart';
import '../../core/services/storage_service.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/blessing_poster_studio_sheet.dart';
import '../../core/widgets/luxe_widgets.dart';
import '../../core/widgets/saint_icon_avatar.dart';
import '../../models/katameros_model.dart';
import '../../providers/bible_provider.dart';
import '../../providers/theme_provider.dart';
import '../bible/bible_reader_view.dart';
import '../community/prayer_wall_view.dart';
import '../community/trivia_game_view.dart';
import '../confession/fathers_directory_view.dart';
import '../confession/my_father_schedule_view.dart';
import '../conscience/conscience_exam_view.dart';
import '../coptic_academy/coptic_academy_view.dart';
import '../icons/christ_icons_gallery_view.dart';
import '../liturgical/fractions_library_view.dart';
import '../liturgical/katameros_view.dart';
import '../liturgical/raising_of_incense_view.dart';
import '../liturgical/remember_them_view.dart';
import '../onboarding/auth_view.dart';
import '../prayer_rope/coptic_prayer_rope_view.dart';
import '../priest/priest_navigation_shell.dart';
import '../profile/profile_settings_view.dart';
import '../search/global_search_view.dart';
import '../spiritual_tracker/communion_readiness_view.dart';
import '../spiritual_tracker/spiritual_tracker_view.dart';
import '../synaxarium/my_patron_saint_view.dart';
import '../synaxarium/synaxarium_daily_view.dart';
import '../treasures/church_history_view.dart';
import '../treasures/liturgical_encyclopedia_view.dart';
import '../treasures/madayeh_library_view.dart';
import '../treasures/patristic_sayings_view.dart';
import '../treasures/sermons_library_view.dart';
import '../treasures/service_notebook_view.dart';
import 'spiritual_prescription_view.dart';

class HomeDashboardView extends StatefulWidget {
  final void Function(int tabIndex, {int? subTab}) onNavigateTab;

  const HomeDashboardView({super.key, required this.onNavigateTab});

  @override
  State<HomeDashboardView> createState() => _HomeDashboardViewState();
}

class _HomeDashboardViewState extends State<HomeDashboardView> {
  KatamerosDay? _katameros;
  bool _isLoading = true;
  int _verseIndex = 0;

  static const List<Map<String, String>> _dailyVerses = [
    {
      'text': 'اللهُ مَحَبَّةٌ، وَمَنْ يَثْبُتْ فِي الْمَحَبَّةِ يَثْبُتْ فِي اللهِ وَاللهُ فِيهِ.',
      'ref': '١ يوحنا ٤ : ١٦',
    },
    {
      'text': 'أَنَا هُوَ نُورُ الْعَالَمِ، مَنْ يَتْبَعْنِي فَلاَ يَمْشِي فِي الظُّلْمَةِ بَلْ يَكُونُ لَهُ نُورُ الْحَيَاةِ.',
      'ref': 'يوحنا ٨ : ١٢',
    },
    {
      'text': 'الرَّبُّ رَاعِيَّ فَلاَ يُعْوِزُنِي شَيْءٌ. فِي مَرَاعٍ خُضْرٍ يُرْبِضُنِي.',
      'ref': 'مزمور ٢٣ : ١ - ٢',
    },
    {
      'text': 'تَعَالَوْا إِلَيَّ يَا جَمِيعَ الْمُتْعَبِينَ وَالثَّقِيلِي الأَحْمَالِ، وَأَنَا أُرِيحُكُمْ.',
      'ref': 'متى ١١ : ٢٨',
    },
    {
      'text': 'سَلاَماً أَتْرُكُ لَكُمْ. سَلاَمِي أُعْطِيكُمْ. لاَ تَضْطَرِبْ قُلُوبُكُمْ وَلاَ تَرْهَبْ.',
      'ref': 'يوحنا ١٤ : ٢٧',
    },
  ];

  @override
  void initState() {
    super.initState();
    _verseIndex = DateTime.now().day % _dailyVerses.length;
    _loadData();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeAskNotificationPermission());
  }

  Future<void> _loadData() async {
    try {
      await Future.wait([
        CopticCalendarService.ensureLectionaryLoaded(),
        PatronSaintService.ensureLoaded(),
        ReadingStateService().ensureLoaded(),
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

  /// Resolves the current canonical Agpeya hour & peaceful artwork by wall-clock time.
  ({String hourTitle, String subtitle, String imageAsset}) _currentLiturgicalMoment() {
    final h = DateTime.now().hour;
    if (h >= 5 && h < 9) {
      return (
        hourTitle: 'صلاة باكر',
        subtitle: 'ابدأ يومك بشكر ربنا ومزامير الصبح الحلوة',
        imageAsset: 'assets/images/christ_good_shepherd.jpg',
      );
    } else if (h >= 9 && h < 12) {
      return (
        hourTitle: 'صلاة الساعة الثالثة',
        subtitle: 'تذكار حلول الروح القدس على التلاميذ',
        imageAsset: 'assets/images/christ_pantocrator.jpg',
      );
    } else if (h >= 12 && h < 15) {
      return (
        hourTitle: 'صلاة الساعة السادسة',
        subtitle: 'تذكار صلب رب المجد في نص النهار',
        imageAsset: 'assets/images/christ_pantocrator.jpg',
      );
    } else if (h >= 15 && h < 17) {
      return (
        hourTitle: 'صلاة الساعة التاسعة',
        subtitle: 'وقفة صلاة هادية وتأمل آخر النهار',
        imageAsset: 'assets/images/christ_good_shepherd.jpg',
      );
    } else if (h >= 17 && h < 20) {
      return (
        hourTitle: 'صلاة الغروب',
        subtitle: 'بداية اليوم القبطي الجديد بعشية كلها سلام',
        imageAsset: 'assets/images/christ_resurrection.jpg',
      );
    } else if (h >= 20 && h < 23) {
      return (
        hourTitle: 'صلاة النوم',
        subtitle: 'اختم يومك بسلام وسلم كل حاجة في إيد ربنا',
        imageAsset: 'assets/images/christ_resurrection.jpg',
      );
    }
    return (
      hourTitle: 'صلاة نصف الليل',
      subtitle: 'سهرة هادية وتسبيح حلو مع الكنيسة',
      imageAsset: 'assets/images/christ_resurrection.jpg',
    );
  }

  String _timeGreeting() {
    final storage = StorageService();
    final hasName = storage.hasCustomUserName();
    final firstName = hasName ? storage.getUserName().split(' ').first : '';
    final h = DateTime.now().hour;
    final prefix = (h >= 5 && h < 12)
        ? 'صباح النور والنعمة'
        : (h >= 12 && h < 17)
            ? 'سلام ونعمة'
            : 'مساء الخير والبركة';
    return firstName.isNotEmpty ? '$prefix يا $firstName' : prefix;
  }

  Future<void> _maybeAskNotificationPermission() async {
    final storage = StorageService();
    if (storage.isNotificationPromptShown()) return;
    await storage.setNotificationPromptShown(true);
    if (!mounted) return;

    bool wantDailyVerse = true;
    bool wantFamilyPrayer = false;
    final p = context.palette;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) => AlertDialog(
          backgroundColor: p.surface,
          title: Text(
            'آية اليوم وتذكير الصلاة',
            style: GoogleFonts.amiri(
              fontWeight: FontWeight.bold,
              fontSize: 22,
              color: p.ink,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'اختر التنبيهات الهادئة التي تناسب يومك:',
                style: GoogleFonts.cairo(fontSize: 13, color: p.inkSecondary),
              ),
              const SizedBox(height: 10),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                activeColor: p.accent,
                checkColor: p.onAccent,
                value: wantDailyVerse,
                onChanged: (v) => setDlg(() => wantDailyVerse = v ?? false),
                title: Text(
                  'آية اليوم وقول شفيعك',
                  style: GoogleFonts.cairo(fontSize: 13.5, fontWeight: FontWeight.w600, color: p.ink),
                ),
                subtitle: Text(
                  'صباحاً الساعة ٨:٠٠ ص',
                  style: GoogleFonts.cairo(fontSize: 11.5, color: p.inkMuted),
                ),
              ),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                activeColor: p.accent,
                checkColor: p.onAccent,
                value: wantFamilyPrayer,
                onChanged: (v) => setDlg(() => wantFamilyPrayer = v ?? false),
                title: Text(
                  'تذكير صلاة العائلة',
                  style: GoogleFonts.cairo(fontSize: 13.5, fontWeight: FontWeight.w600, color: p.ink),
                ),
                subtitle: Text(
                  'مساءً الساعة ٩:٠٠ م (اختياري)',
                  style: GoogleFonts.cairo(fontSize: 11.5, color: p.inkMuted),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('لاحقاً', style: GoogleFonts.cairo(color: p.inkMuted)),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                if (wantDailyVerse || wantFamilyPrayer) {
                  await NotificationService().requestPermission();
                }
                await storage.setDailyVerseNotificationEnabled(wantDailyVerse);
                await storage.setFamilyPrayerReminderEnabled(wantFamilyPrayer);
                await NotificationService().syncScheduledNotifications();
              },
              child: const Text('حفظ'),
            ),
          ],
        ),
      ),
    );
  }

  void _openPersonalGuarded(BuildContext context, String label, Widget page) {
    if (StorageService().isGuestMode()) {
      final p = context.palette;
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: p.surface,
          title: Text(
            'قسم شخصي خاص ($label)',
            style: GoogleFonts.amiri(
              fontWeight: FontWeight.bold,
              color: p.ink,
              fontSize: 21,
            ),
          ),
          content: Text(
            'أنت تتصفح الآن كزائر. لحفظ مذكرة الاعتراف وسجل جهادك الروحي بخصوصية على جهازك، يُرجى تسجيل الدخول أولاً.',
            style: GoogleFonts.cairo(color: p.inkSecondary, fontSize: 13, height: 1.55),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('لاحقاً', style: GoogleFonts.cairo(color: p.inkMuted)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.push(context, luxeRoute(const AuthView()));
              },
              child: const Text('تسجيل الدخول'),
            ),
          ],
        ),
      );
      return;
    }
    Navigator.push(context, luxeRoute(page));
  }

  void _showFastingInfoSheet(BuildContext context, CopticFastStatus fast) {
    final p = context.palette;
    showModalBottomSheet(
      context: context,
      backgroundColor: p.surface,
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(22, 14, 22, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: p.border,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              fast.title,
              style: GoogleFonts.amiri(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: p.ink,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              fast.degree,
              style: GoogleFonts.cairo(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: p.accent,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              fast.abstinenceGuide,
              style: GoogleFonts.cairo(
                fontSize: 13.5,
                color: p.inkSecondary,
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final themeProv = context.watch<ThemeProvider>();

    if (_isLoading || _katameros == null) {
      return Scaffold(
        backgroundColor: p.canvas,
        body: Center(
          child: CircularProgressIndicator(color: p.accent, strokeWidth: 2),
        ),
      );
    }

    final copticToday = CopticCalendarService.todayLiturgical();
    final fast = CopticFastService.getTodayFastStatus();
    final moment = _currentLiturgicalMoment();
    final currentVerse = _dailyVerses[_verseIndex % _dailyVerses.length];
    final saint = PatronSaintService.getSaintById(StorageService().getPatronSaintId());
    final dailyQuote = PatronSaintService.getDailyQuote(saint.id);
    final saintImgUrl = PatronSaintService.getImageUrlForSaint(saint);

    // «كنوز كنيستنا» — Encyclopedic Coptic Treasures matching Orsozoxi's complete richness
    final churchTreasures = <({String title, String sub, IconData icon, VoidCallback onTap})>[
      (
        title: 'رفع بخور عشية وباكر',
        sub: 'الخدمة الكاملة قبطي وعربي',
        icon: Icons.local_fire_department_outlined,
        onTap: () => Navigator.push(context, luxeRoute(const RaisingOfIncenseView())),
      ),
      (
        title: 'صلوات القِسَم (٣٩)',
        sub: 'قسمة كل عيد وموسم وصوم',
        icon: Icons.auto_awesome_outlined,
        onTap: () => Navigator.push(context, luxeRoute(const FractionsLibraryView())),
      ),
      (
        title: 'الموسوعة الطقسية',
        sub: 'طقس وألحان ١٨ موسماً كنسياً',
        icon: Icons.menu_book_outlined,
        onTap: () => Navigator.push(context, luxeRoute(const LiturgicalEncyclopediaView())),
      ),
      (
        title: 'المدائح والتماجيد',
        sub: 'فهرس أبجدي للشهداء والقديسين',
        icon: Icons.library_music_outlined,
        onTap: () => Navigator.push(context, luxeRoute(const MadayehLibraryView())),
      ),
      (
        title: 'موسوعة أقوال الآباء',
        sub: 'أقوال مصنفة أوفلاين بدون إنترنت',
        icon: Icons.format_quote_rounded,
        onTap: () => Navigator.push(context, luxeRoute(const PatristicSayingsView())),
      ),
      (
        title: 'تاريخ الكنيسة والمجامع',
        sub: 'من مارمرقس ونيقية حتى اليوم',
        icon: Icons.account_balance_outlined,
        onTap: () => Navigator.push(context, luxeRoute(const ChurchHistoryView())),
      ),
      (
        title: 'كشكول الخدمة',
        sub: 'تحضير دروس مدارس الأحد والخدام',
        icon: Icons.note_alt_outlined,
        onTap: () => Navigator.push(context, luxeRoute(const ServiceNotebookView())),
      ),
      (
        title: 'الإبصلمودية الكيهكية',
        sub: 'تسبحة ٧ و ٤ وذكصولوجيات الأعياد',
        icon: Icons.nights_stay_outlined,
        onTap: () => widget.onNavigateTab(1, subTab: 2),
      ),
    ];

    // Clear 2-column directory — ZERO hidden horizontal scrolls, EVERY tool visible at a glance
    final directoryTools = <({String title, String sub, IconData icon, VoidCallback onTap})>[
      (
        title: 'الطقوس والأسرار',
        sub: 'اللقان • السجدة • الإكليل • القنديل',
        icon: Icons.church_outlined,
        onTap: () => widget.onNavigateTab(1, subTab: 3),
      ),
      (
        title: 'الألحان والمردات',
        sub: 'صوتيات حقيقية مع كلمات قبطي وعربي',
        icon: Icons.graphic_eq_rounded,
        onTap: () => widget.onNavigateTab(3),
      ),
      (
        title: 'المرشد الآبائي',
        sub: 'اسأل في العقيدة والكتاب والطقس',
        icon: Icons.forum_outlined,
        onTap: () => widget.onNavigateTab(4),
      ),
      (
        title: 'خلوة ٥ دقائق',
        sub: 'آية ومزمور وإرشاد لقلبك الآن',
        icon: Icons.spa_outlined,
        onTap: () => Navigator.push(context, luxeRoute(const SpiritualPrescriptionView())),
      ),
      (
        title: 'المسبحة القبطية',
        sub: 'صلاة يسوع وعداد المطانيات',
        icon: Icons.radio_button_checked_rounded,
        onTap: () => Navigator.push(context, luxeRoute(const CopticPrayerRopeView())),
      ),
      (
        title: 'الأكاديمية القبطية',
        sub: 'تعلّم الحروف القبطية بالنطق الصوتي',
        icon: Icons.translate_rounded,
        onTap: () => Navigator.push(context, luxeRoute(const CopticAcademyView())),
      ),
      (
        title: 'اذكرهم يا رب',
        sub: 'دفتر صلاتك لأحبائك بالاسم',
        icon: Icons.edit_note_rounded,
        onTap: () => Navigator.push(context, luxeRoute(const RememberThemView())),
      ),
      (
        title: 'حائط الصلاة',
        sub: 'اطلب صلاة وصلِّ مع إخوتك',
        icon: Icons.volunteer_activism_outlined,
        onTap: () => Navigator.push(context, luxeRoute(const PrayerWallView())),
      ),
      (
        title: 'مواعيد أبونا',
        sub: StorageService().getConfessionFatherName().isNotEmpty
            ? StorageService().getConfessionFatherName()
            : 'دليل الآباء الكهنة وتسجيل حضور الاعتراف',
        icon: Icons.event_available_outlined,
        onTap: () async {
          final hasFather = StorageService().getConfessionFatherUid().isNotEmpty;
          await Navigator.push(
            context,
            luxeRoute(hasFather ? const MyFatherScheduleView() : const FathersDirectoryView()),
          );
          if (mounted) setState(() {});
        },
      ),
      (
        title: 'مكتبة العظات الصوتية',
        sub: 'البابا شنودة • داود لمعي • بيشوي كامل (بالخلفية)',
        icon: Icons.headphones_rounded,
        onTap: () => Navigator.push(context, luxeRoute(const SermonsLibraryView())),
      ),
      (
        title: 'الاستعداد للقداس والتناول',
        sub: 'تابع آخر اعتراف وتناول وقائمة الاستعداد',
        icon: Icons.church_outlined,
        onTap: () => Navigator.push(context, luxeRoute(const CommunionReadinessView())),
      ),
      (
        title: 'مذكرة الاعتراف',
        sub: 'فحص ضمير خاص ومشفّر على جهازك',
        icon: Icons.lock_outline_rounded,
        onTap: () => _openPersonalGuarded(context, 'مذكرة الاعتراف', const ConscienceExamView()),
      ),
      (
        title: 'الجهاد الروحي',
        sub: 'تابع صلاتك وقراءاتك يومياً',
        icon: Icons.insights_outlined,
        onTap: () => _openPersonalGuarded(context, 'متتبع الجهاد الروحي', const SpiritualTrackerView()),
      ),
      (
        title: 'المسابقات أونلاين ومع أصحابك',
        sub: 'تلمذة الشمامسة • غرفة مع أصحابك • التحدي اليومي',
        icon: Icons.emoji_events_outlined,
        onTap: () => Navigator.push(
          context,
          luxeRoute(const TitledPage(title: 'المسابقات القبطية', child: TriviaGameView())),
        ),
      ),
      (
        title: 'حسابي والإعدادات',
        sub: 'المظهر • حجم الخط • المنبّهات',
        icon: Icons.tune_rounded,
        onTap: () async {
          await Navigator.push(context, luxeRoute(const ProfileSettingsView()));
          if (mounted) setState(() {});
        },
      ),
    ];

    return Scaffold(
      backgroundColor: p.canvas,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(0, 10, 0, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Personal Warm Masthead + Compact Date/Fast + Patron Avatar (Profile)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _timeGreeting(),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.amiri(
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold,
                                  color: p.ink,
                                  height: 1.15,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      '${copticToday.formatted} • ${copticToday.seasonName}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.cairo(
                                        fontSize: 12,
                                        color: p.inkSecondary,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  GestureDetector(
                                    onTap: () => _showFastingInfoSheet(context, fast),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: p.goldSoft,
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(color: p.goldBorder, width: 0.8),
                                      ),
                                      child: Text(
                                        !fast.isFastingToday
                                            ? 'فطار'
                                            : (fast.fishAllowed ? 'صوم بسمك' : 'صوم نباتي'),
                                        style: GoogleFonts.cairo(
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.bold,
                                          color: p.gold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        LuxeCircleButton(
                          icon: p.isDark ? Icons.wb_sunny_outlined : Icons.dark_mode_outlined,
                          size: 38,
                          tooltip: p.isDark ? 'الوضع النهاري' : 'الوضع الليلي',
                          onTap: () {
                            themeProv.setThemeMode(
                              p.isDark ? AppThemeMode.lightParchment : AppThemeMode.darkGold,
                            );
                          },
                        ),
                        const SizedBox(width: 8),
                        // 1-tap Profile & Settings Avatar right in the top corner
                        Tooltip(
                          message: 'حسابي والإعدادات',
                          child: GestureDetector(
                            onTap: () async {
                              HapticFeedback.selectionClick();
                              await Navigator.push(context, luxeRoute(const ProfileSettingsView()));
                              if (mounted) setState(() {});
                            },
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: p.accent, width: 1.4),
                              ),
                              child: SaintIconAvatar(
                                imageUrl: saintImgUrl,
                                size: 36,
                                shape: SaintAvatarShape.circle,
                                showBorder: false,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 1b. Prominent Instant Search Bar (1 tap to find ANYTHING in the app)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
                    child: PressScale(
                      scale: 0.985,
                      onTap: () => Navigator.push(context, luxeRoute(const GlobalSearchView())),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                        decoration: BoxDecoration(
                          color: p.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: p.border),
                          boxShadow: p.isDark
                              ? null
                              : [
                                  BoxShadow(
                                    color: p.shadow,
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.search_rounded, size: 20, color: p.accent),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'ابحث فوراً: قداس، أجبية، لحن، تفسير، كتاب، أو آية...',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.cairo(
                                  fontSize: 12.5,
                                  color: p.inkMuted,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // 1c. Role-Aware Portal Banner: Priest Dashboard («لوحة أبونا») OR Congregation «مواعيد أبونا»
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
                    child: Builder(
                      builder: (ctx) {
                        final st = StorageService();
                        final isPriest = st.isPriestRole();
                        final fatherName = st.getConfessionFatherName();
                        final fatherChurch = st.getConfessionFatherChurch();
                        final hasFather = st.getConfessionFatherUid().isNotEmpty;

                        return PressScale(
                          scale: 0.985,
                          onTap: () async {
                            if (isPriest) {
                              Navigator.of(context).pushAndRemoveUntil(
                                luxeRoute(const PriestNavigationShell()),
                                (_) => false,
                              );
                              return;
                            }
                            await Navigator.push(
                              context,
                              luxeRoute(
                                hasFather
                                    ? const MyFatherScheduleView()
                                    : const FathersDirectoryView(),
                              ),
                            );
                            if (mounted) setState(() {});
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
                            decoration: BoxDecoration(
                              color: isPriest ? p.goldSoft : p.surface,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: isPriest || hasFather ? p.goldBorder : p.border,
                                width: isPriest ? 1.3 : 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 42,
                                  height: 42,
                                  decoration: BoxDecoration(
                                    color: p.accentSoft,
                                    borderRadius: BorderRadius.circular(13),
                                  ),
                                  child: Icon(
                                    isPriest
                                        ? Icons.church_rounded
                                        : Icons.event_available_rounded,
                                    color: p.accent,
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        isPriest
                                            ? 'لوحة أبونا · خدمتي النهارده'
                                            : (hasFather
                                                ? 'مواعيد أبونا • $fatherName'
                                                : 'مواعيد أبونا · دليل الآباء الكهنة'),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.amiri(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: p.ink,
                                        ),
                                      ),
                                      Text(
                                        isPriest
                                            ? 'فتح مواعيد الاعتراف، قائمة الحاضرين، ومكتبة أبونا الليتورجية'
                                            : (hasFather
                                                ? (fatherChurch.isNotEmpty
                                                    ? '$fatherChurch • اضغط لتسجيل حضورك'
                                                    : 'تابع مواعيد قدسه وسجّل حضورك بخصوصية')
                                                : 'اختار أب اعترافك أو ابعت لقدسه دعوة ينضم للتطبيق'),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.cairo(
                                          fontSize: 11.5,
                                          color: p.inkSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(Icons.chevron_left_rounded, color: p.accent, size: 20),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  // 2. Live Liturgical "صلاة الآن" Sacred Hero Card
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: PressScale(
                      scale: 0.985,
                      onTap: () => widget.onNavigateTab(1, subTab: 1),
                      child: Container(
                        height: 186,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(22),
                          boxShadow: [
                            BoxShadow(
                              color: p.shadow.withValues(alpha: p.isDark ? 0.45 : 0.16),
                              blurRadius: 18,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(22),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              SafeAssetImage(moment.imageAsset, fit: BoxFit.cover),
                              Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    stops: const [0.18, 1.0],
                                    colors: [
                                      Colors.black.withValues(alpha: 0.12),
                                      Colors.black.withValues(alpha: 0.82),
                                    ],
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 12,
                                left: 12,
                                child: GestureDetector(
                                  onTap: () => Navigator.push(
                                    context,
                                    luxeRoute(const ChristIconsGalleryView()),
                                  ),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(alpha: 0.42),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: Colors.white.withValues(alpha: 0.22),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.collections_outlined, size: 13, color: Colors.white),
                                        const SizedBox(width: 5),
                                        Text(
                                          'الأيقونات',
                                          style: GoogleFonts.cairo(
                                            fontSize: 11,
                                            color: Colors.white,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                right: 18,
                                left: 18,
                                bottom: 16,
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            'حان وقت الصلاة',
                                            style: GoogleFonts.cairo(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: const Color(0xFFEBD6A8),
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            moment.hourTitle,
                                            style: GoogleFonts.amiri(
                                              fontSize: 24,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                              height: 1.15,
                                            ),
                                          ),
                                          Text(
                                            moment.subtitle,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: GoogleFonts.cairo(
                                              fontSize: 11.5,
                                              color: Colors.white.withValues(alpha: 0.85),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      child: Text(
                                        'ابدأ الآن',
                                        style: GoogleFonts.cairo(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: const Color(0xFF1F1A15),
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
                    ),
                  ),

                  const SizedBox(height: 12),

                  // 2a. Subtle "أكمل القراءة" Resume Card
                  ValueListenableBuilder<int>(
                    valueListenable: ReadingStateService().revisionNotifier,
                    builder: (context, _, _) {
                      final last = ReadingStateService().lastBible;
                      if (last == null) return const SizedBox.shrink();
                      final lastAbbrev = '${last['abbrev'] ?? ''}';
                      final lastName = '${last['name'] ?? ''}';
                      final lastChapter = (last['chapter'] as num?)?.toInt() ?? 1;
                      if (lastAbbrev.isEmpty || lastName.isEmpty) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                        child: PressScale(
                          scale: 0.985,
                          onTap: () async {
                            final bibleProv = context.read<BibleProvider>();
                            await bibleProv.loadBible();
                            final matched = bibleProv.allBooks
                                .where((b) => b.abbrev == lastAbbrev);
                            if (matched.isNotEmpty) {
                              bibleProv.setCurrentBookAndChapter(
                                matched.first,
                                lastChapter,
                              );
                              if (!context.mounted) return;
                              Navigator.push(
                                context,
                                luxeRoute(const BibleReaderView()),
                              );
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                            decoration: BoxDecoration(
                              color: p.surfaceElevated,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: p.accent.withValues(alpha: 0.35)),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: p.accentSoft,
                                    borderRadius: BorderRadius.circular(11),
                                  ),
                                  child: Icon(Icons.bookmark_added_rounded, size: 18, color: p.accent),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'أكمل القراءة من حيث توقفت',
                                        style: GoogleFonts.cairo(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: p.accent,
                                        ),
                                      ),
                                      Text(
                                        '$lastName — الأصحاح $lastChapter',
                                        style: GoogleFonts.amiri(
                                          fontSize: 16.5,
                                          fontWeight: FontWeight.w700,
                                          color: p.ink,
                                          height: 1.2,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(Icons.chevron_left_rounded, size: 20, color: p.inkSubtle),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                  // 2b. Clean Paired Daily Readings Pills (Katameros + Synaxarium)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        Expanded(
                          child: _quickDailyStrip(
                            p: p,
                            icon: Icons.auto_stories_outlined,
                            title: 'قراءات اليوم',
                            subtitle: 'القطمارس اليومي',
                            onTap: () => Navigator.push(
                              context,
                              luxeRoute(KatamerosView(katameros: _katameros!)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _quickDailyStrip(
                            p: p,
                            icon: Icons.history_edu_outlined,
                            title: 'سنكسار اليوم',
                            subtitle: CopticCalendarService.isAfterVespers()
                                ? 'قراءة الغد (بعد العشية)'
                                : copticToday.formatted,
                            onTap: () => Navigator.push(
                              context,
                              luxeRoute(const SynaxariumDailyView()),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  // 3. 4 Big Crystal-Clear Primary Entry Cards (Zero guesswork!)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _primaryHubCard(
                                p: p,
                                icon: Icons.church_outlined,
                                title: 'القداسات والأجبية',
                                subtitle: 'الباسيلي • الغريغوري • الكيرلسي',
                                onTap: () => widget.onNavigateTab(1, subTab: 0),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _primaryHubCard(
                                p: p,
                                icon: Icons.menu_book_outlined,
                                title: 'الكتاب المقدس',
                                subtitle: '٧٣ سفراً مع التفسير الفوري',
                                onTap: () => widget.onNavigateTab(2, subTab: 0),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: _primaryHubCard(
                                p: p,
                                icon: Icons.nights_stay_outlined,
                                title: 'التسبحة والبصخة',
                                subtitle: 'الإبصلمودية • البصخة • الأعياد',
                                onTap: () => widget.onNavigateTab(1, subTab: 2),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _primaryHubCard(
                                p: p,
                                icon: Icons.local_library_outlined,
                                title: 'التفاسير والكتب',
                                subtitle: 'تفاسير ٧٣ سفراً + ٩٨ كتاباً كاملاً',
                                onTap: () => widget.onNavigateTab(2, subTab: 1),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // 4. Book-Printed "آية اليوم" Editorial Card
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(16, 16, 18, 16),
                      decoration: BoxDecoration(
                        color: p.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: p.border),
                        boxShadow: p.isDark
                            ? null
                            : [
                                BoxShadow(
                                  color: p.shadow,
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Text(
                                'آية اليوم',
                                style: GoogleFonts.cairo(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: p.accent,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '• ${currentVerse['ref']!}',
                                style: GoogleFonts.cairo(fontSize: 11.5, color: p.inkMuted),
                              ),
                              const Spacer(),
                              GestureDetector(
                                onTap: () {
                                  BlessingPosterStudioSheet.show(
                                    context,
                                    title: 'آية اليوم',
                                    bodyText: currentVerse['text']!,
                                    reference: currentVerse['ref']!,
                                  );
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(4),
                                  child: Icon(
                                    Icons.ios_share_rounded,
                                    size: 18,
                                    color: p.inkSecondary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              GestureDetector(
                                onTap: () {
                                  HapticFeedback.selectionClick();
                                  setState(() => _verseIndex = (_verseIndex + 1) % _dailyVerses.length);
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(4),
                                  child: Icon(
                                    Icons.refresh_rounded,
                                    size: 18,
                                    color: p.inkMuted,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.only(right: 14),
                            decoration: BoxDecoration(
                              border: Border(
                                right: BorderSide(color: p.gold, width: 2.5),
                              ),
                            ),
                            child: Text(
                              '«${currentVerse['text']!}»',
                              style: GoogleFonts.amiri(
                                fontSize: 20,
                                height: 1.7,
                                color: p.ink,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // 5. Personal Patron Saint Companion Card
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: PressScale(
                      scale: 0.985,
                      onTap: () async {
                        await Navigator.push(context, luxeRoute(const MyPatronSaintView()));
                        if (mounted) setState(() {});
                      },
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: p.surface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: p.border),
                          boxShadow: p.isDark
                              ? null
                              : [
                                  BoxShadow(
                                    color: p.shadow,
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            SaintIconAvatar(
                              imageUrl: saintImgUrl,
                              size: 62,
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
                                            color: p.ink,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        'شفيعي',
                                        style: GoogleFonts.cairo(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: p.accent,
                                        ),
                                      ),
                                      Icon(
                                        Icons.chevron_left_rounded,
                                        size: 16,
                                        color: p.accent,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    '«${dailyQuote.quote}»',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.amiri(
                                      fontSize: 16,
                                      height: 1.5,
                                      color: p.inkSecondary,
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

                  const SizedBox(height: 22),

                  // 6a. «كنوز كنيستنا» — Complete Encyclopedic Coptic Treasures Grid
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      'كنوز كنيستنا والطقوس',
                      style: GoogleFonts.amiri(
                        fontSize: 21,
                        fontWeight: FontWeight.bold,
                        color: p.ink,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: churchTreasures.length,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: 2.05,
                      ),
                      itemBuilder: (_, idx) {
                        final item = churchTreasures[idx];
                        return PressScale(
                          scale: 0.97,
                          onTap: item.onTap,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: p.surface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: p.goldBorder),
                              boxShadow: p.isDark
                                  ? null
                                  : [
                                      BoxShadow(
                                        color: p.shadow,
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: p.goldSoft,
                                    borderRadius: BorderRadius.circular(11),
                                  ),
                                  child: Icon(
                                    item.icon,
                                    color: p.isDark ? p.gold : p.accent,
                                    size: 19,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        item.title,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.cairo(
                                          fontSize: 12.2,
                                          fontWeight: FontWeight.bold,
                                          color: p.ink,
                                          height: 1.2,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        item.sub,
                                        maxLines: 1,
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
                      },
                    ),
                  ),

                  const SizedBox(height: 22),

                  // 6b. Complete Scannable 2-Column Spiritual Directory (Everything visible in 1 glance!)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      'كل أدوات حياتك الروحية',
                      style: GoogleFonts.amiri(
                        fontSize: 21,
                        fontWeight: FontWeight.bold,
                        color: p.ink,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: directoryTools.length,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: 2.05,
                      ),
                      itemBuilder: (_, idx) {
                        final tool = directoryTools[idx];
                        return PressScale(
                          scale: 0.97,
                          onTap: tool.onTap,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: p.surface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: p.border),
                              boxShadow: p.isDark
                                  ? null
                                  : [
                                      BoxShadow(
                                        color: p.shadow,
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: p.goldSoft,
                                    borderRadius: BorderRadius.circular(11),
                                  ),
                                  child: Icon(
                                    tool.icon,
                                    color: p.isDark ? p.gold : p.accent,
                                    size: 19,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        tool.title,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.cairo(
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.bold,
                                          color: p.ink,
                                          height: 1.2,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        tool.sub,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.cairo(
                                          fontSize: 10,
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
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _primaryHubCard({
    required AppPalette p,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return PressScale(
      scale: 0.97,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: p.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: p.goldBorder),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: p.goldSoft,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 21, color: p.isDark ? p.gold : p.accent),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.amiri(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: p.ink,
                height: 1.15,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.cairo(
                fontSize: 10.5,
                color: p.inkSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _quickDailyStrip({
    required AppPalette p,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return PressScale(
      scale: 0.98,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
        decoration: BoxDecoration(
          color: p.surface,
          borderRadius: BorderRadius.circular(16),
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
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: p.goldSoft,
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(icon, size: 19, color: p.isDark ? p.gold : p.accent),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.cairo(
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                      color: p.ink,
                    ),
                  ),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.cairo(
                      fontSize: 10.5,
                      color: p.inkMuted,
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
}
