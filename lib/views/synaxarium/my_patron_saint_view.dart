import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/firebase_service.dart';
import '../../core/services/notification_service.dart';
import '../../core/services/patron_saint_service.dart';
import '../../core/services/speech_pronunciation_service.dart';
import '../../core/services/storage_service.dart';
import '../../core/widgets/blessing_poster_studio_sheet.dart';
import '../../core/widgets/coptic_cross.dart';
import '../../core/widgets/saint_icon_avatar.dart';

class MyPatronSaintView extends StatefulWidget {
  const MyPatronSaintView({super.key});

  @override
  State<MyPatronSaintView> createState() => _MyPatronSaintViewState();
}

class _MyPatronSaintViewState extends State<MyPatronSaintView> {
  final StorageService _storage = StorageService();
  late String _selectedSaintId;
  bool _loadingSynaxariumSaints = true;

  @override
  void initState() {
    super.initState();
    _selectedSaintId = _storage.getPatronSaintId();
    _initAllSaints();
  }

  Future<void> _initAllSaints() async {
    await PatronSaintService.ensureLoaded();
    if (mounted) {
      setState(() => _loadingSynaxariumSaints = false);
    }
  }

  Future<void> _chooseSaint(PatronSaintProfile saint) async {
    HapticFeedback.mediumImpact();
    setState(() => _selectedSaintId = saint.id);
    await _storage.setPatronSaintId(saint.id);
    await FirebaseService().syncPublicProfile(
      displayName: _storage.getUserName(),
      patronSaintId: saint.id,
    );
    await NotificationService().syncScheduledNotifications();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'تم اختيار «${saint.shortName}» شفيعاً شخصياً لك؛ ستظهر أقواله ورسائله لك يومياً.',
          style: GoogleFonts.cairo(fontSize: 12.5, color: AppColors.textLight),
        ),
        backgroundColor: AppColors.cardNavy,
      ),
    );
  }

  void _openSaintPickerSheet() {
    String searchQuery = '';
    String selectedCategory = 'الكل';
    bool gridMode = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          final allSaints = PatronSaintService.saints;
          final filtered = allSaints.where((s) {
            final matchCat = selectedCategory == 'الكل' || s.category == selectedCategory;
            final q = searchQuery.trim();
            final matchSearch = q.isEmpty ||
                s.name.contains(q) ||
                s.shortName.contains(q) ||
                s.title.contains(q) ||
                s.feastDate.contains(q);
            return matchCat && matchSearch;
          }).toList();

          return Container(
            height: MediaQuery.of(ctx).size.height * 0.88,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            decoration: const BoxDecoration(
              color: AppColors.deepNavy,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              border: Border(top: BorderSide(color: AppColors.hairline, width: 1.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 3.5,
                    decoration: BoxDecoration(
                      color: AppColors.primaryGold.withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const CopticCross(size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'معرض وموسوعة قديسي الكنيسة (${allSaints.length})',
                            style: GoogleFonts.amiri(
                              fontSize: 19,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryGoldLight,
                            ),
                          ),
                          Text(
                            'اختر شفيعك من بين كل القديسين والشهداء وآباء البرية',
                            style: GoogleFonts.cairo(fontSize: 11, color: AppColors.textMuted),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: gridMode ? 'عرض كقائمة' : 'عرض كمعرض أيقونات',
                      onPressed: () => setSheetState(() => gridMode = !gridMode),
                      icon: Icon(
                        gridMode ? Icons.view_list_rounded : Icons.grid_view_rounded,
                        color: AppColors.primaryGold,
                        size: 22,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Search Bar
                TextField(
                  onChanged: (v) => setSheetState(() => searchQuery = v),
                  style: GoogleFonts.cairo(color: AppColors.textLight, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'ابحث باسم القديس أو الشهيد أو تاريخ العيد...',
                    hintStyle: GoogleFonts.cairo(color: AppColors.textMuted, fontSize: 12),
                    prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primaryGold, size: 20),
                    filled: true,
                    fillColor: AppColors.cardNavy,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.hairline),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.hairline),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.primaryGold.withValues(alpha: 0.6)),
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // Category Chips
                SizedBox(
                  height: 36,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: PatronSaintService.categories.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 6),
                    itemBuilder: (_, cIdx) {
                      final cat = PatronSaintService.categories[cIdx];
                      final isSelCat = cat == selectedCategory;
                      return ChoiceChip(
                        label: Text(
                          cat,
                          style: GoogleFonts.cairo(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: isSelCat ? Colors.black : AppColors.textLight,
                          ),
                        ),
                        selected: isSelCat,
                        selectedColor: AppColors.primaryGold,
                        backgroundColor: AppColors.cardNavy,
                        showCheckmark: false,
                        side: BorderSide(
                          color: isSelCat ? AppColors.primaryGold : AppColors.hairline,
                        ),
                        onSelected: (_) => setSheetState(() => selectedCategory = cat),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: Text(
                    'نتائج البحث: ${filtered.length} قديس وشفيع',
                    style: GoogleFonts.cairo(fontSize: 11, color: AppColors.textMuted),
                  ),
                ),
                const SizedBox(height: 4),

                // Saints Gallery (Grid) OR Detailed List
                Expanded(
                  child: filtered.isEmpty
                      ? Center(
                          child: Text(
                            'لا يوجد قديس مطابق لبحثك، جرب كتابة الاسم بطريقة أخرى',
                            style: GoogleFonts.cairo(color: AppColors.textMuted, fontSize: 13),
                          ),
                        )
                      : gridMode
                          ? GridView.builder(
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                mainAxisSpacing: 10,
                                crossAxisSpacing: 10,
                                childAspectRatio: 0.72,
                              ),
                              itemCount: filtered.length,
                              itemBuilder: (c, idx) {
                                final s = filtered[idx];
                                final isSel = s.id == _selectedSaintId;
                                final imgUrl = PatronSaintService.getImageUrlForSaint(s);
                                return InkWell(
                                  borderRadius: BorderRadius.circular(14),
                                  onTap: () {
                                    Navigator.pop(ctx);
                                    _chooseSaint(s);
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.fromLTRB(8, 10, 8, 8),
                                    decoration: BoxDecoration(
                                      color: isSel
                                          ? AppColors.primaryGold.withValues(alpha: 0.14)
                                          : AppColors.cardNavy,
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                        color: isSel ? AppColors.primaryGold : AppColors.hairline,
                                        width: isSel ? 1.3 : 0.8,
                                      ),
                                    ),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        SaintIconAvatar(
                                          imageUrl: imgUrl,
                                          size: 62,
                                          shape: SaintAvatarShape.arch,
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          s.shortName,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          textAlign: TextAlign.center,
                                          style: GoogleFonts.cairo(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            height: 1.25,
                                            color: isSel
                                                ? AppColors.primaryGoldLight
                                                : AppColors.textLight,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            )
                          : ListView.separated(
                              itemCount: filtered.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 8),
                              itemBuilder: (c, idx) {
                                final s = filtered[idx];
                                final isSel = s.id == _selectedSaintId;
                                final imgUrl = PatronSaintService.getImageUrlForSaint(s);
                                return Material(
                                  type: MaterialType.transparency,
                                  child: ListTile(
                                    dense: true,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      side: BorderSide(
                                        color: isSel ? AppColors.primaryGold : AppColors.hairline,
                                        width: isSel ? 1.3 : 0.8,
                                      ),
                                    ),
                                    tileColor: isSel
                                        ? AppColors.primaryGold.withValues(alpha: 0.12)
                                        : AppColors.cardNavy,
                                    leading: SaintIconAvatar(
                                      imageUrl: imgUrl,
                                      size: 44,
                                      shape: SaintAvatarShape.circle,
                                    ),
                                    title: Text(
                                      s.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.cairo(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: isSel ? AppColors.primaryGoldLight : AppColors.textLight,
                                      ),
                                    ),
                                    subtitle: Text(
                                      '${s.category} • ${s.feastDate}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.cairo(fontSize: 11, color: AppColors.textMuted),
                                    ),
                                    trailing: Icon(
                                      isSel ? Icons.check_circle_rounded : Icons.chevron_left_rounded,
                                      color: isSel ? AppColors.primaryGold : AppColors.textMuted,
                                      size: 20,
                                    ),
                                    onTap: () {
                                      Navigator.pop(ctx);
                                      _chooseSaint(s);
                                    },
                                  ),
                                );
                              },
                            ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final saint = PatronSaintService.getSaintById(_selectedSaintId);
    final todayQuote = PatronSaintService.getDailyQuote(saint.id);
    final totalSaintsCount = PatronSaintService.saints.length;
    final saintImageUrl = PatronSaintService.getImageUrlForSaint(saint);

    return Scaffold(
      backgroundColor: AppColors.deepNavy,
      appBar: AppBar(
        backgroundColor: AppColors.deepNavy,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'شفيعي الشخصي',
          style: GoogleFonts.amiri(
            fontWeight: FontWeight.bold,
            fontSize: 22,
            color: AppColors.primaryGoldLight,
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: _openSaintPickerSheet,
            icon: const Icon(Icons.photo_library_outlined, color: AppColors.primaryGold, size: 17),
            label: Text(
              'القديسون ($totalSaintsCount)',
              style: GoogleFonts.cairo(
                color: AppColors.primaryGoldLight,
                fontWeight: FontWeight.w600,
                fontSize: 11.5,
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
        children: [
          // 1. Editorial Cathedral-Arch Portrait Banner
          Container(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
            decoration: BoxDecoration(
              color: AppColors.cardNavy,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: AppColors.primaryGold.withValues(alpha: 0.28),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                SaintIconAvatar(
                  imageUrl: saintImageUrl,
                  size: 116,
                  shape: SaintAvatarShape.arch,
                  saintName: saint.name,
                  saintTitle: saint.title,
                  enableFullViewer: true,
                ),
                const SizedBox(height: 6),
                Text(
                  'اضغط على الأيقونة لعرضها بالحجم الكامل',
                  style: GoogleFonts.cairo(fontSize: 10, color: AppColors.textMuted),
                ),
                const SizedBox(height: 10),
                Text(
                  saint.category,
                  style: GoogleFonts.cairo(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryGold,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  saint.name,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.amiri(
                    fontSize: 23,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textLight,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  saint.title,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.cairo(fontSize: 12, color: AppColors.textMuted, height: 1.5),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceNavy,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.hairline),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.calendar_today_outlined, size: 12, color: AppColors.primaryGold),
                      const SizedBox(width: 6),
                      Text(
                        'تذكار العيد: ${saint.feastDate}',
                        style: GoogleFonts.cairo(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryGoldLight,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _openSaintPickerSheet,
                    icon: const Icon(Icons.grid_view_rounded, size: 17, color: Colors.black),
                    label: Text(
                      _loadingSynaxariumSaints
                          ? 'فتح معرض القديسين...'
                          : 'تصفّح معرض كل قديسي الكنيسة ($totalSaintsCount قديس)',
                      style: GoogleFonts.cairo(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 12.5,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGold,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 300.ms),

          const SizedBox(height: 16),

          // 2. Today's Daily Message Card (Editorial Book Quote Style)
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.cardNavy,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.hairline),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const CopticCross(size: 16),
                    const SizedBox(width: 8),
                    Text(
                      'رسالة شفيعك اليوم',
                      style: GoogleFonts.cairo(
                        fontSize: 13.5,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryGoldLight,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'يتجدد يومياً',
                      style: GoogleFonts.cairo(fontSize: 10.5, color: AppColors.textMuted),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.only(right: 14),
                  decoration: const BoxDecoration(
                    border: Border(right: BorderSide(color: AppColors.primaryGold, width: 2.5)),
                  ),
                  child: Text(
                    '«${todayQuote.quote}»',
                    style: GoogleFonts.amiri(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      height: 1.7,
                      color: AppColors.textLight,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceNavy,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.hairline),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(top: 2),
                        child: Icon(Icons.auto_stories_outlined, size: 15, color: AppColors.primaryGold),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'تدريب اليوم: ${todayQuote.lesson}',
                          style: GoogleFonts.cairo(fontSize: 12.5, height: 1.55, color: AppColors.textLight),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  todayQuote.prayer,
                  style: GoogleFonts.amiri(
                    fontSize: 16.5,
                    height: 1.6,
                    color: AppColors.primaryGoldLight,
                  ),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.end,
                  children: [
                    SpeechPlayStopButton(
                      textToSpeak:
                          'رسالة شفيعك اليوم ${saint.name}: ${todayQuote.quote}. تدريب اليوم: ${todayQuote.lesson}. ${todayQuote.prayer}',
                      label: saint.shortName,
                      playText: 'استماع',
                      stopText: 'إيقاف الصوت',
                      compact: true,
                    ),
                    OutlinedButton.icon(
                      onPressed: () {
                        BlessingPosterStudioSheet.show(
                          context,
                          title: 'من أقوال ${saint.shortName}',
                          bodyText: todayQuote.quote,
                          reference: saint.name,
                          footerPrayer: todayQuote.prayer,
                        );
                      },
                      icon: const Icon(Icons.photo_camera_back_outlined, size: 15, color: AppColors.primaryGold),
                      label: Text('بطاقة مصورة', style: GoogleFonts.cairo(color: AppColors.primaryGoldLight, fontWeight: FontWeight.w600, fontSize: 12)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.hairline),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: () {
                        Clipboard.setData(ClipboardData(
                          text: '«${todayQuote.quote}»\n— ${saint.name}\n\n${todayQuote.prayer}',
                        ));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('تم نسخ قول شفيعك اليوم', style: GoogleFonts.cairo())),
                        );
                      },
                      icon: const Icon(Icons.copy_rounded, size: 15, color: AppColors.primaryGold),
                      label: Text('نسخ', style: GoogleFonts.cairo(color: AppColors.primaryGoldLight, fontSize: 12)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.hairline),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        SharePlus.instance.share(
                          ShareParams(
                            text: 'رسالة شفيعي اليوم (${saint.name}):\n\n«${todayQuote.quote}»\n\n${todayQuote.lesson}\n${todayQuote.prayer}\n\nمن تطبيق أرثوذكسيا',
                          ),
                        );
                      },
                      icon: const Icon(Icons.share_outlined, size: 15, color: Colors.black),
                      label: Text('مشاركة', style: GoogleFonts.cairo(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryGold,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // 3. Intercession Prayer (طلبة الشفاعة)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surfaceNavy,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.primaryGold.withValues(alpha: 0.25)),
            ),
            child: Row(
              children: [
                const CopticCross(size: 16),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    saint.intercessionPrayer,
                    style: GoogleFonts.amiri(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryGoldLight,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),

          if (saint.biography.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.cardNavy,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.hairline),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.menu_book_outlined, color: AppColors.primaryGold, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'سيرة القديس من السنكسار القبطي (${saint.feastDate})',
                          style: GoogleFonts.cairo(
                            fontSize: 13.5,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryGoldLight,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    saint.biography,
                    style: GoogleFonts.amiri(
                      fontSize: 17.5,
                      height: 1.85,
                      color: AppColors.textLight,
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 20),

          // 4. All Sayings of This Saint
          Text(
            'مختارات من أقوال وتعاليم ${saint.shortName}',
            style: GoogleFonts.amiri(
              fontSize: 19,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryGoldLight,
            ),
          ),
          const SizedBox(height: 10),
          ...saint.quotes.map((q) => Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.cardNavy,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.hairline),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '«${q.quote}»',
                      style: GoogleFonts.amiri(
                        fontSize: 17.5,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textLight,
                        height: 1.65,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      q.lesson,
                      style: GoogleFonts.cairo(fontSize: 12, color: AppColors.textMuted, height: 1.5),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}
